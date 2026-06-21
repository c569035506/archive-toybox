# E2E 验收清单

## 环境准备

1. `docker compose up -d postgres`
2. `pnpm prisma:migrate && pnpm seed`
3. `pnpm dev:api`
4. Xcode 打开 `apps/ios/ArchiveToybox.xcodeproj` 运行

## 功能验收

- [ ] 敲木鱼：音效、震动、今日/总功德 +1，后端同步
- [ ] 摸招财猫：金币动画、今日招财值 +1，无迷信文案
- [ ] 模拟练习：创建 → 多轮对话 → 复盘雷达图 → 分享海报
- [ ] 吵架分析：隐私提示 → 粘贴记录 → 9 段报告 → 删除记录
- [ ] 静心弹幕：曲目列表 → 播放 → 弹幕 → 进度上报
- [ ] 好友：短 ID 搜索 → 申请 → 接受 → 传功德（幂等）
- [ ] 我的：隐私政策、用户协议、首次隐私同意

## TestFlight

1. 在 Xcode 中设置 Signing Team
2. Product → Archive → Distribute App → TestFlight
