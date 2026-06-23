# 存档玩具盒

《存档玩具盒》是一个 AI 情绪表达与电子解压工具。本仓库包含原生 SwiftUI iOS 客户端与 NestJS 后端。

## 快速开始

```bash
pnpm install
cp .env.example .env
docker compose up -d postgres   # 数据库在 localhost:5433
pnpm prisma:deploy              # 首次或清库后；日常改 schema 用 pnpm prisma:migrate
pnpm seed
pnpm dev:api
```

iOS 工程位于 `apps/ios/ArchiveToybox.xcodeproj`，用 Xcode 打开即可运行。

### 环境变量（`.env`）

| 变量 | 说明 |
|------|------|
| `DATABASE_URL` | 默认 `localhost:5433`（Docker），避免与本机 Postgres 5432 冲突 |
| `PORT` | API 端口，默认 `3000` |
| `OPENAI_API_KEY` | 可选；未配置时吵架练习/分析使用 fallback |
| `IOS_API_BASE_URL` | iOS 客户端默认 API 根路径 |

## E2E 验收

API 冒烟（需先 `pnpm dev:api`）：

```bash
pnpm test:e2e
```

iOS UI 验收（模拟器 + 本地 API）：

```bash
cd apps/ios
xcodebuild -scheme ArchiveToybox \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ArchiveToyboxUITests test
```

完整清单见 [`docs/E2E-CHECKLIST.md`](docs/E2E-CHECKLIST.md)。API 契约见 [`docs/API.md`](docs/API.md)。

### 本地 Postgres 排错

若 `pnpm seed` 报 `permission denied for table User`，说明连到了本机 Postgres（表属系统用户），与 `.env` 的 `archive_toybox` 账号不一致。任选其一：

1. 使用 Docker：`docker compose up -d postgres`（**localhost:5433**）后 `pnpm prisma:deploy && pnpm seed`
2. 临时改用本机用户：`DATABASE_URL="postgresql://$(whoami)@localhost:5432/archive_toybox?schema=public"`

改 schema 后若 API 报 Prisma 模型不存在：`pnpm prisma:generate` 并重启 `pnpm dev:api`。

## 功能范围

- **玩具盒**：电子木鱼、招财猫、好好吵架（角色库 / 文字·语音模拟练习 / 吵架分析）、静心弹幕
- **好友**：短 ID 搜索、好友申请、传功德
- **我的**：账号、分析记录删除、隐私政策与用户协议

### 好好吵架（近期）

- **角色库**：可复用对手（关系、风格、身份/性格、声线），跨场次 `memory_summary`
- **文字练习**：多轮对话 → 六维复盘 → 分享海报
- **语音练习**：语音识别输入、TTS 播放、连续对话与打断

## API

本地 Base URL: `http://localhost:3000/v1`

开发期认证：请求头 `X-User-Id: demo-user`，或 `Authorization: Bearer user:demo-user`。

## 文档

| 文档 | 内容 |
|------|------|
| [`docs/API.md`](docs/API.md) | REST 契约与 JSON 示例 |
| [`docs/E2E-CHECKLIST.md`](docs/E2E-CHECKLIST.md) | 手工 + 自动化验收清单 |
| [`tools/skillopt/README.md`](tools/skillopt/README.md) | 可选：SkillOpt 优化 Agent Skills |
