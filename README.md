# 嘉立创插件集合

简体中文 | [English](README.en.md)

这是嘉立创 EDA AI 工具链的最上层公开 Git 仓库。它不复制下层源码，而是通过 Git submodule 固定两个完整插件的具体提交：AgentDock 嘉立创 AI 插件，以及安装在嘉立创 EDA 专业版一侧的 Enhanced API 插件。AI 插件内部继续递归固定 5 个 Skill 与 1 个 PCB MCP，因此一次递归克隆即可得到完整、可追踪、可复现的开发树。

## 结构

```text
easyeda-plugin-suite
└─ plugins
   ├─ easyeda-ai-plugin                 AgentDock 插件父仓库
   │  ├─ skills/easyeda-api             独立 Skill 公开仓库
   │  ├─ skills/easyeda-eprj3           独立 Skill 公开仓库
   │  ├─ skills/easyeda-pcb-layout-routing    独立 Skill 公开仓库
   │  ├─ skills/easyeda-pro-format-skill      独立 Skill 公开仓库
   │  ├─ skills/easyeda-schematic-net-fanout  独立 Skill 公开仓库
   │  └─ mcp/easyeda-pcb                独立 MCP 公开仓库
   └─ easyeda-api-plugin                Gateway、Protocol、Runtime、Bridge
```

| 直接子模块 | 当前版本 | 公开仓库 | 作用 |
| --- | ---: | --- | --- |
| `plugins/easyeda-ai-plugin` | 2.9.1 | [`easyeda-ai-plugin`](https://github.com/A-m-o-r-F-a-t-i/easyeda-ai-plugin) | 聚合 5 个 Skill（PCB Skill 5.5.1）与 PCB MCP 2.5.0；新板框以原点为中心，小型板可一次完成最多 100 个展开布局操作，每轮跨对象焊盘重叠清零后才允许继续 |
| `plugins/easyeda-api-plugin` | 1.1.5 | [`easyeda-api-plugin`](https://github.com/A-m-o-r-F-a-t-i/easyeda-api-plugin) | 管理 Enhanced API Gateway、Protocol v2、共享运行时和本机 Bridge |

所有仓库均为公开仓库，可直接递归克隆，无需 GitHub 私有仓库访问权限。

## 完整克隆

```powershell
git clone --recurse-submodules https://github.com/A-m-o-r-F-a-t-i/easyeda-plugin-suite.git
cd easyeda-plugin-suite
```

普通克隆后补齐全部层级：

```powershell
git submodule sync --recursive
git submodule update --init --recursive
```

## 验证

结构验证会检查两个直接 submodule、AI 插件内部 6 个递归 submodule、必要文件和版本一致性：

```powershell
pwsh ./scripts/verify.ps1
```

全量验证还会执行 AI 插件的全部 Skill/MCP 测试，强制检查 Gateway 与 Bridge 的**生产依赖为零已知漏洞**，并运行 API 插件的 Protocol、Runtime、Gateway、Bridge 测试和扩展打包。Gateway 的历史开发工具链可能仍显示仅开发依赖告警，但不会被误报为已部署运行时风险：

```powershell
pwsh ./scripts/verify.ps1 -Full
```

## 更新规则

恢复到本仓库已固定的所有提交：

```powershell
pwsh ./scripts/update-submodules.ps1
```

更新两个直接插件父仓库到各自远端 `main`：

```powershell
pwsh ./scripts/update-submodules.ps1 -Remote
git diff --submodule=log
pwsh ./scripts/verify.ps1 -Full
git add plugins
git commit -m "chore: update EasyEDA plugin parents"
```

单个 Skill 或 MCP 更新时，应先在其独立仓库提交和推送，再在 `easyeda-ai-plugin` 中更新并提交对应 gitlink，最后回到本仓库更新 `plugins/easyeda-ai-plugin` 指针。不要在最上层仓库中直接修改嵌套 submodule 后只提交一个脏工作树状态。

## 本地工作位置

建议日常分别在两个插件父仓库中开发；本仓库主要用于完整检出、版本编排、交付复现和跨插件验收。构建 AgentDock 插件时进入 `plugins/easyeda-ai-plugin` 执行其 `scripts/build-plugin.ps1`。构建嘉立创扩展时进入 `plugins/easyeda-api-plugin` 执行 `npm run package:extension`。

## 许可证

该总仓库不为所有成员声明统一开源许可证。每个插件和子模块保留自己的许可证、第三方声明和上游归属；公开可见性不会改变 MIT、Apache-2.0 或其他第三方材料的原始权利。
