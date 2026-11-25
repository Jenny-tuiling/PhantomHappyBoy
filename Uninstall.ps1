param([string]$GameRoot)
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
if(-not $GameRoot){$pick=New-Object Windows.Forms.FolderBrowserDialog;$pick.Description='选择安装多人完整包的 PBZ 游戏根目录';if($pick.ShowDialog() -ne 'OK'){return};$GameRoot=$pick.SelectedPath}
$GameRoot=[IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$mod=Join-Path $GameRoot 'platform\steam\ue4ss\Mods\PBZCoop'
$dest=Join-Path $GameRoot 'platform\steam'
$recordPath=Join-Path $mod 'PartySetup\full-install-record.json'
if(-not(Test-Path -LiteralPath $recordPath)){throw '没有找到本完整包安装记录。未更改文件。'}
if(Get-Process PBZ,'四人设备设置' -ErrorAction SilentlyContinue){throw '请先保存并退出游戏。'}
$record=Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json
$backup=[IO.Path]::GetFullPath($record.backup)
if(-not $backup.StartsWith($GameRoot+'\FourPlayerBackups\',[StringComparison]::OrdinalIgnoreCase)){throw '备份路径不匹配。'}
foreach($entry in $record.files){
    $target=Assert-SafePath $dest $entry.path
    $null=Assert-SafePath $backup $entry.path
    if($entry.existed -and (Get-FileHash -LiteralPath (Join-Path $backup $entry.path)).Hash -ne $entry.oldHash){throw '备份校验失败，未还原'}
    if(-not(Test-Path -LiteralPath $target) -or (Get-FileHash -LiteralPath $target).Hash -ne $entry.installedHash){throw ('文件安装后已改动，停止卸载以保留现状：'+$entry.path)}
    if(-not $target.StartsWith($dest+'\',[StringComparison]::OrdinalIgnoreCase)){throw '非法还原路径。'}
    if(-not ([IO.Path]::GetFullPath((Join-Path $backup $entry.path))).StartsWith($backup+'\',[StringComparison]::OrdinalIgnoreCase)){throw '非法备份路径'}
    if($entry.existed -and -not(Test-Path -LiteralPath (Join-Path $backup $entry.path))){throw '备份不完整，取消还原。'}
}
foreach($entry in $record.files){
    $target=Join-Path $dest $entry.path
    if($entry.existed){Copy-Item -LiteralPath (Join-Path $backup $entry.path) -Destination $target -Force}
    elseif(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target}
}
Remove-Item -LiteralPath $recordPath
$linkPath=Join-Path ([Environment]::GetFolderPath('Desktop')) '小朋友快乐玩mod - 多人设备设置.lnk'
if($record.shortcutCreated -and (Test-Path -LiteralPath $linkPath)){
    $shell=New-Object -ComObject WScript.Shell
    if($shell.CreateShortcut($linkPath).TargetPath -eq (Join-Path $mod 'PartySetup\四人设备设置.exe')){if($record.shortcutExisted){Copy-Item -LiteralPath (Join-Path $backup 'desktop-shortcut.lnk') -Destination $linkPath -Force}else{Remove-Item -LiteralPath $linkPath}}
}
'已还原安装前模组及配置。存档、皮肤和个人设备校准记录未删除。'
