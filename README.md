# 存档玩具盒

《存档玩具盒》是一个 AI 情绪表达与电子解压工具。本仓库包含原生 SwiftUI iOS 客户端与 NestJS 后端。

## 快速开始

```bash
pnpm install
cp .env.example .env
docker compose up -d postgres
pnpm prisma:migrate
pnpm seed
pnpm dev:api
```

iOS 工程位于 `apps/ios/ArchiveToybox.xcodeproj`，用 Xcode 打开即可运行。

## 功能范围

- 玩具盒：电子木鱼、招财猫、好好吵架（模拟练习 / 吵架分析）、静心弹幕
- 好友：短 ID 搜索、好友申请、传功德
- 我的：账号、分析记录删除、隐私政策与用户协议

## API

本地 Base URL: `http://localhost:3000/v1`

开发期认证：请求头 `X-User-Id: demo-user`，或 `Authorization: Bearer <jwt>`。
