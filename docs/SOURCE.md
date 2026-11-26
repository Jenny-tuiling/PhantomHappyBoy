# 源码结构与构建范围

当前为 2026.11.26 单人修复测试版，基于 2026.11.25 回退基线，源码和实际安装载荷同步更新。改动与验证范围见 [UPDATE-2026.11.26.md](UPDATE-2026.11.26.md)。

| 位置 | 内容与来源 |
|---|---|
| src/party-setup | 本地维护的 C# 设置页、A 键认领、校准、AI/恢复/增强/底座 UI 及测试 |
| src/native-local | 本地 native 输入与会话模块、路由、AI 保持、恢复组合键及测试；基于上游维护，不宣称全部纯原创 |
| src/mods | 本地新增或修改的 Lua 扩展；逐文件关系见 source-map.json |
| payload | 完整安装依赖及编译产物；保留上游底座与原许可 |
| 原作者说明 | 上游安装/本地合作说明及 UE4SS 许可 |
| docs/baseline | 对应基线的验证与游戏测试记录 |

`src/mods` 是维护覆盖层，不是脱离 payload 可单独启动的完整游戏。与原始 1.7.3 完全相同的 Lua 不在 src 中重复存放，仍在 payload 作为必需依赖。

## 设置页

Windows 自带的 .NET Framework 4.x 编译器可用时：

```powershell
python src/party-setup/build_setup.py --output build/四人设备设置.exe --test
```

这只生成隔离的 build 产物，不覆盖游戏目录或 payload。需要 Python 的是开发构建，普通安装不需要。

## Native 本地模块

在 Visual Studio x64 Native Tools 开发者命令行，仓库根目录运行：

```bat
mkdir build
cd build
cl /nologo /std:c++20 /O2 /MT /EHsc /W3 /utf-8 /LD ..\src\native-local\main_dll.cpp /Fe:main.dll /link /NOLOGO user32.lib
```

本次使用 Visual Studio 2022 Build Tools 的 x64 编译器重新编译本地模块，并运行 native 自动测试。不同工具链生成的二进制字节不保证一致。`single_input.hpp` 由 `party_input.hpp` 在其命名空间内引入，复用同一校准变换；未启用单人会话时沿用原多人路径。

## 一致性

安装入口未改；649 项 payload 中受修复影响的程序、脚本和清单已同步更新。tools/verify_package.py 验证完整性；source-provenance.json 记录当前70项源码文件哈希。源码构建后需要另外验证再更新载荷和 manifest；不能直接混入另一个版本 DLL。
