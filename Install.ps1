param([string]$GameRoot,[switch]$ValidateOnly,[switch]$NoShortcut)
$ErrorActionPreference='Stop'
function Assert-SafePath([string]$Root,[string]$Relative){
    if([IO.Path]::IsPathRooted($Relative) -or $Relative.Contains(':')){throw '非法绝对路径'}
    $rootFull=[IO.Path]::GetFullPath($Root).TrimEnd('\')
    $full=[IO.Path]::GetFullPath((Join-Path $rootFull $Relative))
    if(-not $full.StartsWith($rootFull+'\',[StringComparison]::OrdinalIgnoreCase)){throw '路径越界'}
    $check=$full
    while($check){
        if(Test-Path -LiteralPath $check){if((Get-Item -LiteralPath $check -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw '不支持符号链接或目录联接'}}
        $parent=[IO.Path]::GetDirectoryName($check)
        if($parent -eq $check){break};$check=$parent
    }
    return $full
}

Add-Type -AssemblyName System.Windows.Forms
if(-not $GameRoot){
    $pick=New-Object Windows.Forms.FolderBrowserDialog
    $pick.Description='选择影之刃零 PBZ 游戏根目录（包含 platform 和 ProjectPBZ）'
    if($pick.ShowDialog() -ne 'OK'){return}
    $GameRoot=$pick.SelectedPath
}
$GameRoot=[IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$exe=Join-Path $GameRoot 'platform\steam\PBZ.exe'
$mod=Join-Path $GameRoot 'platform\steam\ue4ss\Mods\PBZCoop'
if(-not(Test-Path -LiteralPath $exe)){throw '所选位置不是支持的 PBZ 游戏根目录。'}
if((Get-FileHash -LiteralPath $exe).Hash -ne '4415933CE33476F14C837ABB61A1B60AF8B78CD81783896501913A7AAC69E423'){throw '游戏版本不匹配。本包只验证 Steam build 26367565；未安装任何文件。'}
$payload=Join-Path $PSScriptRoot 'payload'
$dest=Join-Path $GameRoot 'platform\steam'
$manifest=Get-Content (Join-Path $PSScriptRoot 'payload-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach($entry in $manifest){
    $path=Assert-SafePath $payload $entry.path
    $null=Assert-SafePath $dest $entry.path
    if(-not $path.StartsWith($payload+'\',[StringComparison]::OrdinalIgnoreCase)){throw '非法包内路径'}
    if((Get-FileHash -LiteralPath $path).Hash -ne $entry.sha256){throw "文件损坏：$($entry.path)"}
}
if($ValidateOnly){'PASS: game version and complete package checksums';return}
if(Get-Process PBZ,'四人设备设置' -ErrorAction SilentlyContinue){throw '请保存并退出游戏后安装。'}
if(Test-Path -LiteralPath (Join-Path $mod 'PartySetup\install-record.json')){throw '已安装四人版。请先运行原升级包 Uninstall.cmd 还原，再安装新版。'}
if(Test-Path -LiteralPath (Join-Path $mod 'PartySetup\full-install-record.json')){throw '本完整包已安装，请先卸载再更新。'}
$backup=Join-Path $GameRoot ('FourPlayerBackups\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$entries=@()
$paths=@($manifest | ForEach-Object {$_.path})
foreach($relative in $paths){
    $target=Join-Path $dest $relative
    $existed=Test-Path -LiteralPath $target
    if($existed){$saved=Join-Path $backup $relative;New-Item -ItemType Directory -Force (Split-Path -Parent $saved)|Out-Null;Copy-Item -LiteralPath $target -Destination $saved}
    $entries+=@{path=$relative;existed=$existed;oldHash=$(if($existed){(Get-FileHash -LiteralPath $target).Hash}else{$null})}
}
$linkPath=Join-Path ([Environment]::GetFolderPath('Desktop')) '小朋友快乐玩mod - 多人设备设置.lnk'
$linkExisted=Test-Path -LiteralPath $linkPath
if(-not $NoShortcut -and $linkExisted){Copy-Item -LiteralPath $linkPath -Destination (Join-Path $backup 'desktop-shortcut.lnk')}
$recordPath=Join-Path $mod 'PartySetup\full-install-record.json'
$utf8=New-Object Text.UTF8Encoding($false)
try{
    foreach($entry in $manifest){
        $target=Join-Path $dest $entry.path
        New-Item -ItemType Directory -Force (Split-Path -Parent $target)|Out-Null
        # Preserve an existing UE4SS configuration and existing bundled helper mods.
        if((Test-Path -LiteralPath $target) -and $entry.path -ne 'ue4ss/Mods/mods.txt' -and
          ($entry.path -eq 'ue4ss/UE4SS-settings.ini' -or $entry.path -eq 'ue4ss/MemberVariableLayout.ini' -or
           ($entry.path.StartsWith('ue4ss/Mods/') -and -not $entry.path.StartsWith('ue4ss/Mods/PBZCoop/') -and -not $entry.path.StartsWith('ue4ss/Mods/PBZWardrobe/') -and -not $entry.path.StartsWith('ue4ss/Mods/PBZPartyPower/')))){continue}
        Copy-Item -LiteralPath (Join-Path $payload $entry.path) -Destination $target -Force
    }
    $iniPath=Join-Path $mod 'PhantomPact.ini'
    $oldIni=Join-Path $backup 'ue4ss\Mods\PBZCoop\PhantomPact.ini'
    $ini=if(Test-Path -LiteralPath $oldIni){Get-Content -LiteralPath $oldIni -Raw}else{Get-Content -LiteralPath $iniPath -Raw}
    $modsPath=Join-Path $dest 'ue4ss\Mods\mods.txt'
    $oldMods=Join-Path $backup 'ue4ss\Mods\mods.txt'
    $mods=if(Test-Path -LiteralPath $oldMods){Get-Content -LiteralPath $oldMods -Raw}else{Get-Content -LiteralPath $modsPath -Raw}
    $mods=[regex]::Replace($mods,'(?m)^\s*(?:PBZCoop|PBZWardrobe|PBZPartyPower)\s*:.*(?:\r?\n|$)','')
    [IO.File]::WriteAllText($modsPath,"PBZCoop : 1`r`nPBZWardrobe : 1`r`nPBZPartyPower : 1`r`n"+$mods,$utf8)
    $values=@{Role='Off';LocalPlayers='1';Monitors='1';Joysticks='4';LocalInput='four_pads';OnlinePanel='On'}
    foreach($key in $values.Keys){
        $pattern='(?m)^'+$key+'\s*=.*$'
        $line=$key+' = '+$values[$key]
        if($ini -match $pattern){$ini=[regex]::Replace($ini,$pattern,$line)}else{$ini+="`r`n$line`r`n"}
    }
    [IO.File]::WriteAllText($iniPath,$ini,$utf8)
    [IO.File]::WriteAllText((Join-Path $mod 'PartySetup/game-path.txt'),$GameRoot,$utf8)
    foreach($entry in $entries){$entry.installedHash=(Get-FileHash -LiteralPath (Join-Path $dest $entry.path)).Hash}
    $record=@{gameRoot=$GameRoot;backup=$backup;files=$entries;shortcutCreated=(-not $NoShortcut);shortcutExisted=$linkExisted}
    [IO.File]::WriteAllText($recordPath,($record|ConvertTo-Json -Depth 5),$utf8)
    if(-not $NoShortcut){
    $shell=New-Object -ComObject WScript.Shell
    $link=$shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) '小朋友快乐玩mod - 多人设备设置.lnk'))
    $link.TargetPath=Join-Path $mod 'PartySetup\四人设备设置.exe'
    $link.WorkingDirectory=Join-Path $mod 'PartySetup'
    $link.IconLocation=$link.TargetPath+',0';$link.Save()
    if(-not(Test-Path -LiteralPath $linkPath)){throw '桌面快捷方式创建失败'}
    }
    '安装完成。默认单人；从桌面设置页开启多人开关、选择2/3/4人并完成绑定测试后启动。'
    '原文件备份：'+$backup
}catch{
    if(Test-Path -LiteralPath $recordPath){Remove-Item -LiteralPath $recordPath}
    if(-not $NoShortcut){
        if($linkExisted){Copy-Item -LiteralPath (Join-Path $backup 'desktop-shortcut.lnk') -Destination $linkPath -Force}
        elseif(Test-Path -LiteralPath $linkPath){Remove-Item -LiteralPath $linkPath}
    }
    foreach($entry in $entries){
        $target=Join-Path $dest $entry.path
        if($entry.existed){Copy-Item -LiteralPath (Join-Path $backup $entry.path) -Destination $target -Force}
        elseif(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target}
    }
    throw
}
