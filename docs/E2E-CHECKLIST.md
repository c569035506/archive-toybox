# E2E 验收清单

## 环境准备

### 后端

```bash
pnpm install
cp .env.example .env
docker compose up -d postgres          # localhost:5433，勿与本机 Postgres 5432 混用
pnpm prisma:deploy && pnpm seed        # 全新库；开发中改 schema 用 pnpm prisma:migrate
pnpm prisma:generate                   # schema 变更后若 API 报模型不存在，执行一次
pnpm dev:api
pnpm test:e2e                          # 25 项 API 冒烟，应全部通过
```

可选：在 `.env` 配置 `OPENAI_API_KEY` 后，吵架练习/分析会走真实模型；未配置时使用内置 fallback，e2e 仍可跑通。

### iOS

1. Xcode 打开 `apps/ios/ArchiveToybox.xcodeproj`
2. 模拟器：默认连 `http://localhost:3000/v1`（见 `.env` 的 `IOS_API_BASE_URL`）
3. 真机：将 API 地址改为 Mac 局域网 IP，且 Mac 防火墙允许 3000 端口
4. 语音练习需授权：**麦克风**、**语音识别**（`Info.plist` 已声明用途）

### 自动化

```bash
# API 冒烟
pnpm test:e2e

# iOS UI（模拟器 + 本地 API）
cd apps/ios
xcodebuild -scheme ArchiveToybox \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ArchiveToyboxUITests test
```

---

## 功能验收

### 玩具盒

- [ ] **敲木鱼**：音效、震动、今日/总功德 +1，后端同步
- [ ] **摸招财猫**：金币动画、今日招财值 +1，无迷信文案

### 好好吵架 · 角色库

- [ ] 进入「模拟练习」→ 角色库列表（空态有「创建角色」）
- [ ] **创建角色**：姓名、关系、风格、身份/性格描述（可选）、男/女声、幼/青/中/老年
- [ ] 保存后进入「本场场景」：发生了什么、练习目标
- [ ] 列表展示角色与历史练习次数；下拉刷新

### 好好吵架 · 文字练习

- [ ] 选角色 → 填场景 → 开始练习
- [ ] 多轮文字对话（用户发送、AI 以对手身份回复）
- [ ] **结束并生成复盘**：雷达图六维、亮点/建议、本局最佳表达
- [ ] **生成分享海报** → 预览 → 返回

### 好好吵架 · 语音练习

- [ ] 练习页切换到语音模式（或从设置进入语音练习）
- [ ] 按住/点麦克风说话，松手或连续模式下停稳约 2.5 秒自动发送
- [ ] 「说完了」手动发送累积内容
- [ ] AI 回复 TTS 播放；连续对话中可打断对方
- [ ] 暂停/继续连续对话；可调语速；可重播上一句 AI
- [ ] 对话记录自动滚动

### 好好吵架 · 跨场次记忆

- [ ] 用**同一角色**完成第一场并结束复盘
- [ ] 第二场相同角色开练，对手开场/回应应体现上一场沉淀（`memory_summary`）
- [ ] （可选）`GET /argument/practice/characters/:id` 可见 `memory_summary` 非空

### 好好吵架 · 吵架分析

- [ ] 隐私提示 → 粘贴记录 → 勾选隐私确认 → 9 段报告
- [ ] 分析记录列表 → 删除单条

### 静心弹幕

- [ ] 曲目列表 → 播放 → 弹幕开关 → 进度上报 → 结束收听

### 好友

- [ ] 短 ID 搜索（种子用户如 `TOYBOX002`）→ 申请 → 接受 → 传功德（幂等）

### 我的

- [ ] 隐私政策、用户协议、首次隐私同意

---

## 排错

| 现象 | 处理 |
|------|------|
| `pnpm seed` 报 `permission denied for table User` | 连错库：确认 `.env` 为 `localhost:5433`，或改用 Docker 重建 `docker compose down -v && up -d postgres` |
| `pnpm prisma:deploy` 报 P3005 | 库非空且未 baseline：用 `docker compose down -v` 清卷后重跑 deploy + seed |
| API 角色接口 500 | 执行 `pnpm prisma:generate` 后重启 `pnpm dev:api`（勿用旧 `dist` 进程） |
| 端口 3000 占用 | `lsof -i :3000` → `kill <PID>` → 再 `pnpm dev:api` |
| 模拟器连不上 API | 确认 `pnpm dev:api` 在跑；检查 `IOS_API_BASE_URL` |
| 语音无反应 | 系统设置中给 App 开麦克风与语音识别；模拟器部分机型语音识别受限，可换真机 |

---

## TestFlight

1. 在 Xcode 中设置 Signing Team
2. 将 `IOS_API_BASE_URL` 指向可公网访问的 API（或 TestFlight 专用环境）
3. Product → Archive → Distribute App → TestFlight
