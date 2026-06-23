# 存档玩具盒

《存档玩具盒》是一个 AI 情绪表达与电子解压工具。本仓库包含原生 SwiftUI iOS 客户端与 NestJS 后端。

## 快速开始

```bash
pnpm install
cp .env.example .env
docker compose up -d postgres   # 数据库在 localhost:5433
pnpm prisma:migrate
pnpm seed
pnpm dev:api
```

iOS 工程位于 `apps/ios/ArchiveToybox.xcodeproj`，用 Xcode 打开即可运行。

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

完整清单见 `docs/E2E-CHECKLIST.md`。

### 本地 Postgres 排错

若 `pnpm seed` 报 `permission denied for table User`，说明库表由系统用户创建、与 `.env` 中的 `archive_toybox` 账号不一致。任选其一：

1. 使用 Docker：`docker compose up -d postgres`（**localhost:5433**）后重新 `pnpm prisma:deploy && pnpm seed`
2. 临时改用本机用户连接，例如在 `.env` 中设置  
   `DATABASE_URL="postgresql://$(whoami)@localhost:5432/archive_toybox?schema=public"`

## 功能范围

- 玩具盒：电子木鱼、招财猫、好好吵架（模拟练习 / 吵架分析）、静心弹幕
- 好友：短 ID 搜索、好友申请、传功德
- 我的：账号、分析记录删除、隐私政策与用户协议

## API

本地 Base URL: `http://localhost:3000/v1`

开发期认证：请求头 `X-User-Id: demo-user`，或 `Authorization: Bearer <jwt>`。
