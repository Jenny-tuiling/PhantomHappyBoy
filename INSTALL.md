# 完整项目安装指南

本仓库 ZIP 本身已经包含安装载荷，下载后不用再找别的仓库或补丁。

1. 需要 Windows 和 Steam build **26367565**。请先正常启动过游戏。
2. 备份 `ProjectPBZ/Saved/SaveGames`，退出游戏与设置页。已有旧版先用它原来的 `Uninstall.cmd` 卸载。
3. 点击 Code → Download ZIP，完整解压，进入含 `Install.cmd`、`payload`、`payload-manifest.json` 的目录。
4. 双击 `Install.cmd`，选择包含 `platform` 与 `ProjectPBZ` 的游戏根目录。安装器校验游戏与全部载荷，备份旧文件，然后创建桌面快捷方式。
5. 从桌面打开设置页，显示器设为扩展显示，选人数、按 A 认领手柄、归中校准、选皮肤、检查并启动。

无需 GPT、Python 或编译器。`src/` 供开发者研究，普通玩家不用操作它。不要单独下载源码文件或运行旧仓库开发脚本。

若版本或哈希不匹配，停止安装并核对，不绕过校验，不关闭安全软件。修改过的载荷需要开发者重新构建和验证清单。

## 卸载

保留完整解压目录。若切换过底座，先在游戏关闭时切回安装时的本地底座，再退出设置页。运行本包 `Uninstall.cmd`，选同一游戏根目录。安装后改动过的文件会受到保护；保留现场及 `FourPlayerBackups`，不要强删备份、存档或整个模组目录。

## 校验

PowerShell 可读取 `payload-manifest.json` 并用 `Get-FileHash -Algorithm SHA256` 核对 649 项载荷。开发者还可运行 `python tools/verify_package.py`，它只读文件，不安装或启动游戏。

## 测试范围

本次仅整理仓库结构；运行文件与 2026.11.25 回退基线一致。已知问题见 README。新机器请使用自己的备份存档逐项验证。
