# API 契约

Base URL: `http://localhost:3000/v1`

所有 JSON 字段使用 **snake_case**。开发期认证：`X-User-Id: demo-user` 或 `Authorization: Bearer user:demo-user`。

## 健康检查

- `GET /health` → `{ "status": "ok" }`

## 用户

- `GET /me` → `UserProfile`
- `POST /auth/register` → `{ user, token }`
- `POST /auth/login` → `{ user, token }`

### UserProfile

```json
{
  "id": "uuid",
  "short_id": "TOYABC123",
  "email": "user@example.com",
  "nickname": "昵称",
  "avatar_url": null,
  "total_merit": 0,
  "today_merit": 0,
  "today_fortune": 0,
  "meditation_minutes": 0
}
```

## 玩具盒

- `GET /toybox/home` → `{ "cards": ToyboxCard[] }`

### ToyboxCard

```json
{
  "key": "wooden_fish",
  "title": "电子木鱼",
  "description": "...",
  "action_label": "敲一下",
  "status_text": "今日功德 0",
  "total_merit": 0
}
```

`total_merit` 仅木鱼卡片返回。

## 功德

- `POST /merit/wooden-fish/tap` — 敲木鱼（幂等）
- `GET /merit/summary` → `MeritSummary`
- `POST /merit/transfer` — 传功德（幂等）

### 敲木鱼 / 摸猫 请求

```json
{
  "client_request_id": "uuid",
  "tapped_at": "2026-06-22T12:00:00Z"
}
```

### MeritTapResponse

```json
{
  "today_merit": 1,
  "total_merit": 10,
  "duplicate": false
}
```

### MeritTransferResponse

```json
{
  "from_balance": 9,
  "to_balance": 11,
  "duplicate": false
}
```

重复请求时 `duplicate: true`，`to_balance` 可能省略。

## 招财猫

- `POST /fortune/lucky-cat/tap` — 摸招财猫（幂等，请求体同上）
- `GET /fortune/summary` → `{ "today_fortune": 0 }`

### FortuneTapResponse

```json
{
  "today_fortune": 1,
  "duplicate": false
}
```

## 静心

- `GET /meditation/tracks` → `{ "tracks": MeditationTrack[] }`
- `POST /meditation/sessions` — body: `{ "track_id": "..." }`
- `PATCH /meditation/sessions/:id/progress` — body: `{ "duration_sec": 30 }`
- `POST /meditation/sessions/:id/finish` — body: `{ "duration_sec": 60, "mood_delta": { "calm": 1 } }`
- `GET /meditation/summary` → 今日分钟数、总次数、最近曲目

## 好好吵架

### 练习角色

- `GET /argument/practice/characters` → `{ "characters": PracticeCharacter[] }`
- `POST /argument/practice/characters` — 创建角色（name、relationship、opponent_style、identity_desc、personality_desc、voice_gender、voice_age）
- `GET /argument/practice/characters/:id` — 角色详情（含 `memory_summary`、过往练习次数）

### 模拟练习

- `POST /argument/practice/sessions` — 创建模拟练习  
  推荐 body：`character_id` + `what_happened` + `practice_goal`（可选 `relationship` 覆盖角色默认关系）  
  兼容旧版：无 `character_id` 时需传 `opponent_label`、`relationship`、`opponent_style` 等  
  body 可选：`opponent_identity_desc`、`opponent_personality_desc`（各最多 500 字）、`opponent_voice_gender`、`opponent_voice_age`  
  结束练习后会更新角色的 `memory_summary`，下次用同一角色开练时 AI 会读取
- `GET /argument/practice/sessions/:id` — 会话详情
- `POST /argument/practice/sessions/:id/messages` — 发送消息
- `POST /argument/practice/sessions/:id/finish` → `PracticeReview`
- `GET /argument/practice/sessions/:id/review` → `PracticeReview`

### PracticeReview

```json
{
  "scores": { "emotional_stability": 4, "...": 4 },
  "title": "边界守夜人",
  "summary": "复盘摘要",
  "highlights": ["做得好的点"],
  "suggestions": ["可改进点"],
  "best_quote": "用户本局最佳表达",
  "poster": { "title": "...", "subtitle": "...", "best_quote": "...", "highlights": [], "suggestions": [], "scores": {} }
}
```

- `POST /argument/analysis` — 创建分析（需 `privacy_acknowledged: true`）
- `GET /argument/analysis` → `{ "items": AnalysisListItem[] }`
- `GET /argument/analysis/:id` — 单条详情
- `DELETE /argument/analysis/:id` → `{ "deleted": true }`

## 好友

- `GET /friends/search?short_id=TOY...` → `{ "users": FriendUser[] }`
- `POST /friends/requests` — body: `{ "to_user_id": "..." }`
- `GET /friends/requests` → `{ "incoming": [], "outgoing": [] }`
- `POST /friends/requests/:id/accept` → `{ "status": "accepted" }`
- `POST /friends/requests/:id/reject` → `{ "status": "rejected" }`
- `GET /friends` → `{ "friends": FriendUser[] }`

## 合规

- `GET /legal/privacy-policy` → `LegalDocument`
- `GET /legal/terms` → `LegalDocument`
- `POST /compliance/privacy-ack` — body: `{ "doc_type": "privacy", "version": "2026-06-21" }`

完整 TypeScript 类型见 `packages/shared-types/index.ts`。
