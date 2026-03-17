#!/bin/bash
# ============================================================
# OpenClaw Telegram Agent - Run
# 게이트웨이 실행 + Telegram 페어링 안내
# ============================================================
set -e

CONFIG_DIR="$HOME/.openclaw"

# ── 설정 파일 확인 ─────────────────────────────────────────
if [ ! -f "$CONFIG_DIR/openclaw.json" ]; then
  echo "❌ 설정 파일이 없습니다. 먼저 setup.sh를 실행하세요."
  exit 1
fi

# ── API 키 로드 ────────────────────────────────────────────
if [ -f "$CONFIG_DIR/.env" ]; then
  export $(grep -v '^#' "$CONFIG_DIR/.env" | grep -v '^$' | xargs)
fi

# ── 게이트웨이 토큰 추출 ───────────────────────────────────
TOKEN=$(python3 -c "import json; d=json.load(open('$CONFIG_DIR/openclaw.json')); print(d['gateway']['auth']['token'])")

echo ""
echo "🦞 OpenClaw Telegram Agent"
echo "=============================="
echo ""

# ── 이미 실행 중인 gateway 정리 ────────────────────────────
echo "🔄 기존 gateway 정리 중..."
pkill -9 -f "openclaw" 2>/dev/null || true
sleep 3

# ── gateway 백그라운드 실행 ────────────────────────────────
echo "🚀 Gateway 시작 중..."
nohup openclaw gateway --port 8080 > "$CONFIG_DIR/gateway.log" 2>&1 &
GATEWAY_PID=$!
sleep 3

# ── 실행 확인 ──────────────────────────────────────────────
if ! ps -p $GATEWAY_PID > /dev/null 2>&1; then
  echo "❌ Gateway 실행 실패. 로그를 확인하세요:"
  cat "$CONFIG_DIR/gateway.log"
  exit 1
fi

echo "✅ Gateway 실행 중 (PID: $GATEWAY_PID)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 모델: anthropic/claude-sonnet-4-6"
echo "🌐 gcube URL로 접속 후 Overview 페이지에서:"
echo "   Gateway Token 필드에 아래 토큰 입력 후 Connect"
echo ""
echo "🔑 토큰: ${TOKEN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 다음 단계:"
echo ""
echo "  1) Telegram 봇에 아무 메시지 보내기"
echo "     → Pairing 코드 수신"
echo ""
echo "  2) Device 승인 (requestId 확인 후 승인)"
echo "     \$ openclaw devices list"
echo "     \$ openclaw devices approve <requestId>"
echo ""
echo "  3) Pairing 승인 (Telegram에서 받은 코드 입력)"
echo "     \$ openclaw pairing approve telegram <코드>"
echo ""
echo "  4) 대화 시작"
echo "     → Telegram에서 봇에게 메시지 보내기"
echo ""
echo "  5) 로그 확인 (문제 발생 시)"
echo "     \$ tail -f ~/.openclaw/gateway.log"
echo "     \$ tail -f /tmp/openclaw/openclaw-\$(date +%Y-%m-%d).log"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [종료]  \$ pkill -9 -f 'openclaw'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"