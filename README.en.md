# EasyEDA Plugin Suite

[简体中文](README.md) | English

This is the top-level public Git repository for the EasyEDA AI toolchain. It does not duplicate lower-level sources. Instead, Git submodules pin exact commits of two complete plugins: the AgentDock EasyEDA AI plugin and the Enhanced API plugin installed on the EasyEDA Pro side. The AI plugin recursively pins five Skills and one PCB MCP, so one recursive clone produces the complete, traceable, and reproducible development tree.

## Layout

```text
easyeda-plugin-suite
└─ plugins
   ├─ easyeda-ai-plugin                 AgentDock plugin parent
   │  ├─ skills/easyeda-api             independent public Skill repository
   │  ├─ skills/easyeda-eprj3           independent public Skill repository
   │  ├─ skills/easyeda-pcb-layout-routing    independent public Skill repository
   │  ├─ skills/easyeda-pro-format-skill      independent public Skill repository
   │  ├─ skills/easyeda-schematic-net-fanout  independent public Skill repository
   │  └─ mcp/easyeda-pcb                independent public MCP repository
   └─ easyeda-api-plugin                Gateway, Protocol, Runtime, and Bridge
```

| Direct submodule | Version | Public repository | Responsibility |
| --- | ---: | --- | --- |
| `plugins/easyeda-ai-plugin` | 3.0.0 | [`easyeda-ai-plugin`](https://github.com/A-m-o-r-F-a-t-i/easyeda-ai-plugin) | Aggregates five Skills (PCB Skill 6.0.0, API Skill 2.4.0) and PCB MCP 3.0.0; MCP-first common-operation wrappers, direct bulk editing, component/footprint/pin-net orientations and board/local SVG; the model owns design and analysis timing |
| `plugins/easyeda-api-plugin` | 1.1.5 | [`easyeda-api-plugin`](https://github.com/A-m-o-r-F-a-t-i/easyeda-api-plugin) | Maintains the Enhanced API Gateway, Protocol v2, shared runtime, and local Bridge |

Every repository is public and can be cloned recursively without private-repository credentials.

## Full clone

```powershell
git clone --recurse-submodules https://github.com/A-m-o-r-F-a-t-i/easyeda-plugin-suite.git
cd easyeda-plugin-suite
```

Initialize all levels after a non-recursive clone:

```powershell
git submodule sync --recursive
git submodule update --init --recursive
```

## Verification

Structural verification checks both direct submodules, the six nested AI-plugin submodules, required files, and version consistency:

```powershell
pwsh ./scripts/verify.ps1
```

Full verification also runs all AI-plugin Skill/MCP tests, requires **zero known production-dependency vulnerabilities** for both the Gateway and Bridge, and then runs the API plugin Protocol, Runtime, Gateway, and Bridge tests plus extension packaging. The historical Gateway development toolchain may still report dev-only advisories, but they are not treated as deployed runtime exposure:

```powershell
pwsh ./scripts/verify.ps1 -Full
```

## Update rules

Restore every commit pinned by this repository:

```powershell
pwsh ./scripts/update-submodules.ps1
```

Move the two direct plugin parents to their remote `main` branches:

```powershell
pwsh ./scripts/update-submodules.ps1 -Remote
git diff --submodule=log
pwsh ./scripts/verify.ps1 -Full
git add plugins
git commit -m "chore: update EasyEDA plugin parents"
```

When a Skill or MCP changes, commit and push its independent repository first, update and commit its gitlink in `easyeda-ai-plugin`, and only then update the `plugins/easyeda-ai-plugin` pointer here. Do not modify a nested submodule from the suite and record only a dirty working-tree state.

## Local workflow

Normal development should happen in the two plugin parent repositories. This suite is primarily for complete checkout, version orchestration, reproducible delivery, and cross-plugin acceptance. Build the AgentDock package with `plugins/easyeda-ai-plugin/scripts/build-plugin.ps1`. Build the EasyEDA extension from `plugins/easyeda-api-plugin` with `npm run package:extension`.

## Licensing

The suite does not impose one blanket open-source license on every member. Each plugin and submodule retains its own license, third-party notices, and upstream attribution. Public visibility does not alter MIT, Apache-2.0, or other third-party rights contained in the components.
