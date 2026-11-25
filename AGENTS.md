# PhantomHappyBoy — AI harness 安装与开发指引

先读 README.md、INSTALL.md、NOTICE.md。本仓库包含完整安装载荷，无需跳转其他仓库拼凑补丁。

## 用户要求安装时

1. 下载此仓库 main 分支的完整 ZIP，或使用完整 clone；不要只下载 src，不要再装 upstream latest。
2. 检查 Install.cmd、Install.ps1、payload/、payload-manifest.json 均在同一根目录。
3. 校验 manifest 内全部 649 项 SHA256，拒绝绝对路径与父级逃逸；可用 tools/verify_package.py。检查 payload 完整，不绕过安装器版本校验。
4. 保留用户存档；确认已正常退出游戏和设置页。旧多人版先按原包卸载，不强杀正常游戏。
5. 支持 Steam build 26367565；PBZ.exe SHA256 为 4415933CE33476F14C837ABB61A1B60AF8B78CD81783896501913A7AAC69E423。
6. 运行根目录 Install.cmd，选择含 platform、ProjectPBZ 的 PBZ 根目录；确认成功消息和桌面“小朋友快乐玩mod - 多人设备设置”快捷方式。
7. 接收电脑使用自己的手柄绑定和校准；本包未附带制作机的个人配置。不要把下载 ZIP 说成已经完成安装。

## 用户要求开发时

src/party-setup 为设置页源码，src/native-local 为本地 native 模块，src/mods 为本地新增或修改的 Lua。先读 docs/SOURCE.md 和 docs/source-map.json。
payload 是实际安装载荷；改 src 不会自动更新程序。保留来源说明，区分派生代码和新扩展，不把整个组合包改成统一原创许可。
任何游戏逻辑改动都须独立构建和验证；静态测试不等于游戏通关。当前版本不能声称解决了队友复活打断主机、穿行光标或全部切图问题。
不上传游戏本体、存档、设备绑定、校准、账号信息、日志或凭据。不要关闭防护软件。
