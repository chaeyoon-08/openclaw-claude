#!/bin/bash
# ============================================================
# OpenClaw WebUI - Setup
# 최초 1회 실행: 설정 파일 자동 생성
# ============================================================
set -e

echo ""
echo "🦞 OpenClaw WebUI Setup"
echo "=============================="
echo ""

# ── .env 파일 확인 ─────────────────────────────────────────
if [ ! -f ".env" ]; then
  echo "❌ .env 파일이 없습니다."
  echo "   cp .env.example .env 후 API 키를 채워주세요."
  exit 1
fi

# ── .env 로드 ──────────────────────────────────────────────
export $(grep -v '^#' .env | grep -v '^$' | xargs)

# ── API 키 확인 ────────────────────────────────────────────
if [ -z "$GEMINI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "❌ GEMINI_API_KEY 또는 ANTHROPIC_API_KEY가 설정되지 않았습니다."
  echo "   무료 키 발급: https://aistudio.google.com/apikey"
  exit 1
fi

# ── openclaw 설치 확인 ─────────────────────────────────────
if ! command -v openclaw &> /dev/null; then
  echo "📦 OpenClaw 설치 중..."
  npm install -g openclaw@latest
else
  echo "✅ OpenClaw 이미 설치됨: $(openclaw --version)"
fi

# ── 설정 디렉토리 생성 ─────────────────────────────────────
CONFIG_DIR="$HOME/.openclaw"
AGENT_DIR="$CONFIG_DIR/agents/main/agent"
SESSION_DIR="$CONFIG_DIR/agents/main/sessions"
mkdir -p "$CONFIG_DIR" "$AGENT_DIR" "$SESSION_DIR"

# ── 모델 설정 (Gemini 우선, 없으면 Anthropic) ──────────────
if [ -n "$GEMINI_API_KEY" ]; then
  MODEL="google/gemini-2.5-flash"
  PROVIDER="google"
  API_KEY="$GEMINI_API_KEY"
  echo "📡 모델: Google Gemini 2.5 Flash (무료)"
else
  MODEL="anthropic/claude-sonnet-4-5"
  PROVIDER="anthropic"
  API_KEY="$ANTHROPIC_API_KEY"
  echo "📡 모델: Anthropic Claude Sonnet 4.5"
fi

# ── 게이트웨이 토큰 생성 ───────────────────────────────────
GATEWAY_TOKEN=$(openssl rand -hex 24 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d '-')

# ── Telegram 토큰 확인 ─────────────────────────────────────
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
  echo "❌ TELEGRAM_BOT_TOKEN이 설정되지 않았습니다."
  exit 1
fi
echo "📱 Telegram 봇 토큰 감지됨"

# ── openclaw.json 생성 ─────────────────────────────────────
echo "⚙️  openclaw.json 내용 추가 중..."
cat > "$CONFIG_DIR/openclaw.json" << JSONEOF
{
  "meta": {
    "lastTouchedVersion": "2026.2.23"
  },
  "agents": {
    "defaults": {
      "model": "${MODEL}",
      "memorySearch": {
        "enabled": false
      }
    }
  },
  "gateway": {
    "port": 8080,
    "mode": "local",
    "bind": "lan",
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true,
      "allowInsecureAuth": true
    },
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "pairing"
    }
  },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true
      }
    }
  }
}
JSONEOF
echo "✅ openclaw.json 생성 완료"

# ── auth-profiles.json 생성 ────────────────────────────────
cat > "$AGENT_DIR/auth-profiles.json" << JSONEOF
{
  "version": 1,
  "profiles": {
    "${PROVIDER}:default": {
      "type": "api_key",
      "provider": "${PROVIDER}",
      "key": "${API_KEY}"
    }
  },
  "usageStats": {}
}
JSONEOF
echo "✅ auth-profiles.json 생성 완료"

# ── .env 복사 ──────────────────────────────────────────────
cp .env "$CONFIG_DIR/.env"
echo "✅ .env 복사 완료"

echo ""
echo "✅ 설정 완료!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▶  다음 단계: bash run.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"