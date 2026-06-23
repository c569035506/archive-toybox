# SkillOpt（本机）

基于 [microsoft/SkillOpt](https://github.com/microsoft/SkillOpt) 与 [harrylabsj/skillopt](https://github.com/harrylabsj/skillopt) 的 Cursor 集成。

## 已安装内容

| 组件 | 路径 |
|------|------|
| Cursor Agent Skill | `~/.cursor/skills/skillopt/` |
| Python 虚拟环境 | `tools/skillopt/.venv` |
| Microsoft 源码（含 SkillOpt-Sleep） | `tools/skillopt/SkillOpt-source/` |
| MCP（SkillOpt-Sleep） | `.cursor/mcp.json` |

## 用法

### 1. 优化某个 SKILL.md（Agent Skill）

在 Cursor 里说例如：「用 SkillOpt 优化这个 skill」，Agent 会加载 `~/.cursor/skills/skillopt/SKILL.md` 并按验证门控流程迭代。

手动初始化一次优化运行：

```bash
tools/skillopt/.venv/bin/python ~/.cursor/skills/skillopt/scripts/skillopt.py init \
  --skill path/to/SKILL.md \
  --out skillopt_runs/my-skill
```

### 2. SkillOpt-Sleep（夜间巩固技能）

在 Cursor 设置里启用 MCP 服务器 `skillopt-sleep`（读取项目 `.cursor/mcp.json`），然后可在对话中调用：

- `sleep_status` — 查看已运行轮次与待采纳提案
- `sleep_dry_run` — 预览一轮（不写入）
- `sleep_run` — 完整周期，暂存提案（默认不自动应用）
- `sleep_adopt` — 采纳暂存提案（会先备份）

默认 `backend: mock` 不消耗 API。无密钥自检：

```bash
tools/skillopt/.venv/bin/python -m skillopt_sleep.experiments.run_experiment \
  --persona researcher --assert-improves
```

### 3. 论文级训练（需 API 与数据集）

见 [SkillOpt 文档](https://microsoft.github.io/SkillOpt/docs/guideline.html)。

```bash
cd tools/skillopt/SkillOpt-source
../.venv/bin/python scripts/train.py --config configs/searchqa/default.yaml ...
```

## 参考

- [microsoft/SkillOpt](https://github.com/microsoft/SkillOpt) — 官方仓库与论文实现
- [SkillOpt-Sleep 说明](https://github.com/microsoft/SkillOpt/blob/main/docs/sleep/README.md)
