# API 契约

Base URL: `http://localhost:3000/v1`

## 认证

开发期：`X-User-Id: demo-user` 或 `Authorization: Bearer user:demo-user`

## 主要端点

- `GET /health` — 健康检查
- `GET /toybox/home` — 玩具盒卡片状态
- `POST /merit/wooden-fish/tap` — 敲木鱼
- `POST /fortune/lucky-cat/tap` — 摸招财猫
- `POST /argument/practice/sessions` — 创建模拟练习
- `POST /argument/analysis` — 吵架分析
- `GET /friends` — 好友列表
- `POST /merit/transfer` — 传功德
- `GET /meditation/tracks` — 静心曲目

完整设计见项目 README 与 Prisma schema。
