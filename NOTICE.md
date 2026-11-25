# 感谢、来源与权利说明

PhantomHappyBoy 是“小朋友快乐玩mod”的独立分享与扩展维护仓库，研发测试中，面向非商业个人研究与朋友试玩。

## 感谢 PhantomPact 原作者与贡献者

基础合作流程来自 **yhsharaf/PhantomPact v1.7.3**：
https://github.com/yhsharaf/PhantomPact

原双人合作和游戏流程为本项目提供了基础。基于它修改的文件仍属于派生维护内容，不能因仓库改名而称为完全原创。本地设置页、2/3/4 人输入与设备管理、校准、AI 状态保持、召回、皮肤接入及相关修正由本扩展维护。

原维护分支及历史：https://github.com/Jenny-tuiling/PhantomPact/tree/cn/four-player-local

## 感谢运行依赖与其他组件

- **UE4SS-RE / RE-UE4SS** 及其贡献者：https://github.com/UE4SS-RE/RE-UE4SS 。许可见 `payload/ue4ss/LICENSE` 与 `原作者说明/UE4SS-LICENSE.txt`；各组件以自己的许可为准。
- **rxi/json.lua**：https://github.com/rxi/json.lua 。MIT 文本保留在对应 Lua 文件顶部。
- **PhantomPact 原始安装和本地合作说明**：`原作者说明/`。
- **魂主角外观**：调用使用者自己游戏里的资源，不附带原游戏角色模型。
- **辰辰、小宝、猪八戒、枫枫**：本项目接入的模型数据，保留数据中现有来源记录；本说明不替第三方内容增授许可。

## 范围

`src/`：本地维护源码与测试，部分文件基于上游代码修改。`docs/source-map.json` 记录 Lua 文件与 1.7.3 快照的逐文件对照。未找到原始 native 源码的精确快照时，native 文件按“基于上游维护”说明，不推断纯原创。

`payload/`：完整运行载荷，包括上游底座、扩展及必需依赖；不得整体认作本项目原创。提供它是为了安装时不再混装或下载错版本。

本地 1.7.3 下载快照没有仓库根 LICENSE。这里如实保留该事实，未声称上游已授予无限再分发权。非商业、研发中、署名或 fork 都不替代适用许可。已有许可按原文保留，不凭空增加统一许可证。

本项目与 S-GAME、上游作者无隶属或官方背书关系。游戏本体、存档、商标与角色权利属于各自权利人。
