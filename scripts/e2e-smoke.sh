#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3000/v1}"
USER_HEADER="${USER_HEADER:-demo-user}"
PASS=0
FAIL=0

pass() { echo "✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL + 1)); }

request() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local extra_headers=("${@:4}")
  local headers=(-H "Content-Type: application/json" -H "X-User-Id: ${USER_HEADER}" -H "Authorization: Bearer user:${USER_HEADER}")
  if ((${#extra_headers[@]})); then headers+=("${extra_headers[@]}"); fi
  if [[ -n "$body" ]]; then
    curl -sS -X "$method" "${headers[@]}" -d "$body" "${BASE_URL}${path}"
  else
    curl -sS -X "$method" "${headers[@]}" "${BASE_URL}${path}"
  fi
}

echo "=== Archive Toybox E2E Smoke ==="
echo "Base URL: ${BASE_URL}"

health=$(curl -sS "${BASE_URL%/v1}/v1/health" 2>/dev/null || curl -sS "http://localhost:3000/v1/health" 2>/dev/null || true)
if ! echo "$health" | rg -q '"status":"ok"'; then
  echo "❌ API 未就绪。请先启动：docker compose up -d postgres && pnpm seed && pnpm dev:api"
  exit 1
fi
pass "health"

home=$(request GET "/toybox/home")
echo "$home" | rg -q 'wooden_fish' && pass "toybox/home cards" || fail "toybox/home cards"

profile=$(request GET "/me")
echo "$profile" | rg -q '"short_id"' && pass "me profile" || fail "me profile ($profile)"
echo "$profile" | rg -q '"total_merit"' && pass "me profile merit fields" || fail "me profile merit fields ($profile)"

tap_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
tap=$(request POST "/merit/wooden-fish/tap" "{\"client_request_id\":\"${tap_id}\",\"tapped_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}")
echo "$tap" | rg -q 'today_merit' && pass "merit/wooden-fish/tap" || fail "merit/wooden-fish/tap"
tap_dup=$(request POST "/merit/wooden-fish/tap" "{\"client_request_id\":\"${tap_id}\",\"tapped_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}")
echo "$tap_dup" | rg -q '"duplicate":true' && pass "merit tap idempotent" || fail "merit tap idempotent"

fortune_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
fortune=$(request POST "/fortune/lucky-cat/tap" "{\"client_request_id\":\"${fortune_id}\",\"tapped_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}")
echo "$fortune" | rg -q 'today_fortune' && pass "fortune/lucky-cat/tap" || fail "fortune/lucky-cat/tap"

tracks=$(request GET "/meditation/tracks")
echo "$tracks" | rg -q 'great-compassion-demo' && pass "meditation/tracks" || fail "meditation/tracks"
session=$(request POST "/meditation/sessions" '{"track_id":"great-compassion-demo"}')
session_id=$(echo "$session" | python3 -c 'import sys,json; print(json.load(sys.stdin)["session_id"])')
request PATCH "/meditation/sessions/${session_id}/progress" '{"duration_sec":15}' >/dev/null && pass "meditation progress" || fail "meditation progress"
request POST "/meditation/sessions/${session_id}/finish" '{"duration_sec":30,"mood_delta":{"calm":1}}' >/dev/null && pass "meditation finish" || fail "meditation finish"

practice=$(request POST "/argument/practice/characters" '{"name":"室友","relationship":"合租","opponent_style":"逃避","personality_desc":"爱拖延、怕冲突"}')
character_id=$(echo "$practice" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
pass "argument practice character create"
updated=$(request PATCH "/argument/practice/characters/${character_id}" '{"name":"室友（已改）","relationship":"合租","opponent_style":"直面","personality_desc":"更直接"}')
echo "$updated" | rg -q '室友（已改）' && pass "argument practice character update" || fail "argument practice character update ($updated)"
practice=$(request POST "/argument/practice/sessions" "{\"character_id\":\"${character_id}\",\"what_happened\":\"不洗碗\",\"practice_goal\":\"表达边界\"}")
practice_id=$(echo "$practice" | python3 -c 'import sys,json; print(json.load(sys.stdin)["session_id"])')
pass "argument practice create"
msg=$(request POST "/argument/practice/sessions/${practice_id}/messages" '{"content":"我们能不能轮流洗碗？"}')
echo "$msg" | rg -q '"role":"assistant"' && pass "argument practice message" || fail "argument practice message"
review=$(request POST "/argument/practice/sessions/${practice_id}/finish" '{}')
echo "$review" | rg -q 'emotional_stability' && pass "argument practice review" || fail "argument practice review"
echo "$review" | rg -q '"highlights"' && pass "argument practice review highlights" || fail "argument practice review highlights ($review)"
echo "$review" | rg -q '"suggestions"' && pass "argument practice review suggestions" || fail "argument practice review suggestions ($review)"
request DELETE "/argument/practice/characters/${character_id}" >/dev/null && pass "argument practice character delete" || fail "argument practice character delete"

analysis=$(request POST "/argument/analysis" '{"chat_text":"A: 你怎么又这样\nB: 你才是","self_side":"A","relationship":"情侣","analysis_goal":"看清升级点","privacy_acknowledged":true}')
analysis_id=$(echo "$analysis" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
echo "$analysis" | rg -q 'one_liner' && pass "argument analysis create" || fail "argument analysis create"
request DELETE "/argument/analysis/${analysis_id}" >/dev/null && pass "argument analysis delete" || fail "argument analysis delete"

search=$(request GET "/friends/search?short_id=TOYBOX002")
echo "$search" | rg -q 'TOYBOX002' && pass "friends search" || fail "friends search"
friend_id=$(echo "$search" | python3 -c 'import sys,json; print(json.load(sys.stdin)["users"][0]["id"])')
friends=$(request GET "/friends")
if echo "$friends" | rg -q "$friend_id"; then
  pass "friends request accept"
else
  req=$(request POST "/friends/requests" "{\"to_user_id\":\"${friend_id}\"}")
  request_id=$(echo "$req" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("request_id",""))')
  if [[ -n "$request_id" ]]; then
    curl -sS -X POST -H "Content-Type: application/json" -H "X-User-Id: demo-friend" -H "Authorization: Bearer user:demo-friend" -d '{}' "${BASE_URL}/friends/requests/${request_id}/accept" >/dev/null
    pass "friends request accept"
  else
    fail "friends request accept ($req)"
  fi
fi

for i in 1 2 3; do
  seed_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
  request POST "/merit/wooden-fish/tap" "{\"client_request_id\":\"${seed_id}\",\"tapped_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >/dev/null || true
done

transfer_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
transfer=$(request POST "/merit/transfer" "{\"to_user_id\":\"${friend_id}\",\"amount\":1,\"client_request_id\":\"${transfer_id}\",\"message\":\"辛苦了\"}")
echo "$transfer" | rg -q 'from_balance' && pass "merit transfer" || fail "merit transfer ($transfer)"
transfer_dup=$(request POST "/merit/transfer" "{\"to_user_id\":\"${friend_id}\",\"amount\":1,\"client_request_id\":\"${transfer_id}\",\"message\":\"辛苦了\"}")
echo "$transfer_dup" | rg -q '"duplicate":true' && pass "merit transfer idempotent" || fail "merit transfer idempotent ($transfer_dup)"

privacy=$(curl -sS "${BASE_URL}/legal/privacy-policy")
echo "$privacy" | rg -q '隐私政策' && pass "legal/privacy-policy" || fail "legal/privacy-policy"
terms=$(curl -sS "${BASE_URL}/legal/terms")
echo "$terms" | rg -q '用户协议' && pass "legal/terms" || fail "legal/terms"
request POST "/compliance/privacy-ack" '{"doc_type":"privacy","version":"2026-06-21"}' >/dev/null && pass "compliance/privacy-ack" || fail "compliance/privacy-ack"

echo ""
echo "=== Summary: ${PASS} passed, ${FAIL} failed ==="
[[ "$FAIL" -eq 0 ]]
