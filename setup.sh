#!/bin/bash
# ============================================================
# OpenClaw Telegram Agent - Setup
# 최초 1회 실행: 설정 파일 자동 생성
# ============================================================
set -e

echo ""
echo "🦞 OpenClaw Telegram Agent Setup"
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
if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "❌ ANTHROPIC_API_KEY가 설정되지 않았습니다."
  echo "   https://console.anthropic.com/ 에서 발급하세요."
  exit 1
fi
echo "✅ Anthropic API 키 감지됨"

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

# ── 모델 설정 ─────────────────────────────────────────────
MODEL="anthropic/claude-sonnet-4-5"
echo "📡 모델: Anthropic Claude Sonnet 4.5"

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
      "model": "anthropic/claude-sonnet-4-6",
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
      "dangerouslyAllowHostHeaderOriginFallback": true
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
    "anthropic:default": {
      "type": "api_key",
      "provider": "anthropic",
      "key": "${ANTHROPIC_API_KEY}"
    }
  },
  "usageStats": {}
}
JSONEOF
echo "✅ auth-profiles.json 생성 완료"

# ── .env 복사 ──────────────────────────────────────────────
cp .env "$CONFIG_DIR/.env"
echo "✅ .env 복사 완료"

# ── Workspace 디렉터리 생성 ────────────────────────────────
WORKSPACE_DIR="$CONFIG_DIR/workspace"
mkdir -p "$WORKSPACE_DIR"

# ── Identity 파일 복사 ─────────────────────────────────────
if [ -d "identity" ]; then
  IDENTITY_COUNT=$(ls identity/*.md 2>/dev/null | wc -l)
  if [ "$IDENTITY_COUNT" -gt 0 ]; then
    cp identity/*.md "$WORKSPACE_DIR/" 2>/dev/null || true
    echo "✅ Identity 파일 복사 완료 (${IDENTITY_COUNT}개)"
  else
    echo "ℹ️  identity/ 폴더에 .md 파일이 없습니다"
  fi
else
  echo "ℹ️  identity/ 폴더가 없습니다"
fi

# ── Knowledge Base 문서 복사 ───────────────────────────────
if [ -d "docs" ]; then
  DOCS_COUNT=$(ls docs/*.md 2>/dev/null | wc -l)
  if [ "$DOCS_COUNT" -gt 0 ]; then
    cp docs/*.md "$WORKSPACE_DIR/" 2>/dev/null || true
    echo "✅ Knowledge Base 문서 복사 완료 (${DOCS_COUNT}개)"
  else
    echo "ℹ️  docs/ 폴더에 .md 파일이 없습니다"
  fi
else
  echo "ℹ️  docs/ 폴더가 없습니다"
fi

echo ""
echo "✅ 설정 완료!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▶  다음 단계: bash run.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"