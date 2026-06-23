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
- `POST /argument/practice/characters` — 创建角色
- `GET /argument/practice/characters/:id` — 角色详情（含 `memory_summary`、过往练习次数）

#### 创建角色请求

```json
{
  "name": "室友",
  "relationship": "合租",
  "opponent_style": "逃避",
  "identity_desc": "上班族，怕冲突",
  "personality_desc": "爱拖延、绕开正题",
  "voice_gender": "female",
  "voice_age": "middle"
}
```

`identity_desc`、`personality_desc` 可选，各最多 500 字。  
`voice_gender`：`male` | `female`（默认 `female`）  
`voice_age`：`child` | `youth` | `middle` | `elderly`（默认 `middle`）

#### PracticeCharacter

```json
{
  "id": "uuid",
  "name": "室友",
  "relationship": "合租",
  "opponent_style": "逃避",
  "identity_desc": "",
  "personality_desc": "爱拖延",
  "voice_gender": "female",
  "voice_age": "middle",
  "memory_summary": "上次练习后沉淀的长期记忆…",
  "session_count": 2,
  "created_at": "2026-06-23T06:00:00.000Z",
  "updated_at": "2026-06-23T06:30:00.000Z"
}
```

结束练习并复盘后，服务端会更新该角色的 `memory_summary`；下次用同一 `character_id` 开练时，对手 prompt 会注入此记忆。

### 模拟练习

- `POST /argument/practice/sessions` — 创建模拟练习  
  推荐 body：`character_id` + `what_happened` + `practice_goal`（可选 `relationship` 覆盖角色默认关系）  
  兼容旧版：无 `character_id` 时需传 `opponent_label`、`relationship`、`opponent_style` 等  
  body 可选：`opponent_identity_desc`、`opponent_personality_desc`（各最多 500 字）、`opponent_voice_gender`、`opponent_voice_age`  
  结束练习后会更新角色的 `memory_summary`，下次用同一角色开练时 AI 会读取
- `GET /argument/practice/sessions/:id` — 会话详情（含消息列表）
- `POST /argument/practice/sessions/:id/messages` — 发送消息 → `{ "message": PracticeMessage }`
- `POST /argument/practice/sessions/:id/finish` → `PracticeReview`
- `GET /argument/practice/sessions/:id/review` → `PracticeReview`

#### 创建练习会话（推荐）

```json
{
  "character_id": "uuid",
  "what_happened": "又不洗碗",
  "practice_goal": "表达边界",
  "relationship": "合租"
}
```

`relationship` 可省略，默认用角色上的关系。响应含 `session_id`、`opening_message`、`opponent_voice_gender`、`opponent_voice_age`。

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

## AI 与降级

| 环境变量 | 说明 |
|----------|------|
| `OPENAI_API_KEY` | OpenAI 或兼容端点密钥 |
| `OPENAI_BASE_URL` | 默认 `https://api.openai.com/v1` |
| `OPENAI_MODEL` | 默认 `gpt-4o-mini` |

未配置密钥或模型调用失败时，吵架练习（对手回复、复盘）与吵架分析会返回内置 **fallback** 内容，保证流程可测；生产环境应配置有效密钥。

## 常用脚本

| 命令 | 用途 |
|------|------|
| `pnpm prisma:migrate` | 开发中创建/应用迁移 |
| `pnpm prisma:deploy` | 生产或全新 Docker 库应用已有迁移 |
| `pnpm prisma:generate` | schema 变更后重新生成 Prisma Client |
| `pnpm seed` | 写入演示用户与曲目等种子数据 |
| `pnpm test:e2e` | API 冒烟（`scripts/e2e-smoke.sh`） |

完整 TypeScript 类型见 `packages/shared-types/index.ts`。
