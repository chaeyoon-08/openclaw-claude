# PRD: OpenClaw Telegram AI Agent Gateway

## 1. 개요

OpenClaw NPM 패키지를 활용하여 Telegram 봇(`@openclaw_claude_da_bot`)과 Anthropic Claude API를 연결하는 AI 에이전트 게이트웨이. gcube 컨테이너 환경에서 `git clone → bash setup.sh → bash run.sh` 3단계로 배포가 완료되는 미니멀한 구조를 유지한다.

**핵심 설계 원칙**: 실제 게이트웨이, 채널 핸들러, 봇 통신은 모두 `openclaw` NPM 패키지가 담당한다. 이 repo는 설정 파일을 생성하는 셸 스크립트와, 에이전트 동작을 정의하는 bootstrap 파일만 포함한다.

---

## 2. 목표

- Telegram 봇을 통해 Claude AI와 대화할 수 있는 게이트웨이 제공
- Anthropic Claude API 단일 백엔드로 운영 (다른 모델 없음)
- `identity/` 폴더의 bootstrap 파일로 에이전트 성격(한국어 응답, DA Assistant 정체성) 정의
- `docs/` 폴더의 문서를 에이전트 workspace에 주입하여 문서 기반 Q&A 지원
- WebUI 접속 기능과 Telegram 채널을 함께 제공하는 구조 유지

---

## 3. 범위

### In Scope

| 항목 | 설명 |
|------|------|
| Claude API 단일 백엔드 | `anthropic/claude-sonnet-4-6` 고정 |
| WebUI 접속 기능 | gcube URL 접속 → Gateway Token 입력 → Connect |
| Telegram 전용 채널 | DM 페어링 방식 |
| 에이전트 Identity 관리 | `identity/AGENTS.md`, `identity/IDENTITY.md` → workspace 자동 복사 |
| Knowledge Base 주입 | `docs/*.md` → `~/.openclaw/workspace/` 자동 복사 |
| `.env.example` | `ANTHROPIC_API_KEY`, `TELEGRAM_BOT_TOKEN` 두 키만 요구 |
| `setup.sh` | openclaw 설치, 설정 파일 생성, identity/docs 파일 복사 |
| `run.sh` | 게이트웨이 백그라운드 실행, Telegram 페어링 안내 출력 |
| `README.md` | Telegram 전용 배포 가이드 |

### Out of Scope

| 항목 | 이유 |
|------|------|
| 다른 모델 지원 | Claude 단일 백엔드 정책 |
| 멀티 에이전트 구성 | 단일 에이전트(main)로 운영 |
| 커스텀 플러그인 개발 | openclaw 기본 Telegram 플러그인 사용 |
| CI/CD 파이프라인 | 수동 배포 (git clone 기반) |

---

## 4. 기술 스택

| 레이어 | 기술 |
|--------|------|
| 런타임 | Node.js (openclaw NPM 패키지) |
| AI 모델 | Anthropic Claude Sonnet 4.6 (`anthropic/claude-sonnet-4-6`) |
| 채널 | Telegram Bot API (openclaw 내장 플러그인) |
| 인프라 | gcube 컨테이너 (`coollabsio/openclaw:latest`) |
| 설정 관리 | `~/.openclaw/openclaw.json`, `auth-profiles.json` |
| 에이전트 정체성 | `identity/AGENTS.md`, `identity/IDENTITY.md` → workspace bootstrap |
| 스크립트 | Bash (`setup.sh`, `run.sh`) |

---

## 5. 아키텍처

```
┌──────────────────┐
│  Telegram User   │
│  (@openclaw_     │
│   claude_da_bot) │
└────────┬─────────┘
         │ Telegram Bot API
         ▼
┌────────────────────────────────────────────┐
│  gcube Container (coollabsio/openclaw)     │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  openclaw gateway (:8080)            │  │
│  │  • Telegram 채널 핸들러               │  │
│  │  • 디바이스 페어링 관리                │  │
│  │  • 메시지 라우팅                      │  │
│  └──────────────┬───────────────────────┘  │
│                 │                          │
│  ┌──────────────▼───────────────────────┐  │
│  │  ~/.openclaw/                        │  │
│  │  ├── openclaw.json  (게이트웨이 설정) │  │
│  │  ├── workspace/                      │  │
│  │  │   ├── AGENTS.md  (한국어 지시)    │  │
│  │  │   ├── IDENTITY.md (DA Assistant)  │  │
│  │  │   └── *.md       (KB 문서)        │  │
│  │  └── agents/main/agent/              │  │
│  │      └── auth-profiles.json (API 키) │  │
│  └──────────────────────────────────────┘  │
└────────────────────┬───────────────────────┘
                     │ HTTPS
                     ▼
            ┌─────────────────┐
            │  Anthropic API  │
            │  Claude Sonnet  │
            │  4.6            │
            └─────────────────┘
```

---

## 6. 배포 흐름

```
1. gcube 워크로드 생성
   • 이미지: coollabsio/openclaw:latest
   • 포트: 8080
   • 초기명령어: bash -c "apt-get update -qq && apt-get install -y nano vim && sleep infinity"

2. 컨테이너 터미널 접속

3. git clone → cd openclaw-claude

4. cp .env.example .env → nano .env
   • ANTHROPIC_API_KEY=sk-ant-...
   • TELEGRAM_BOT_TOKEN=123456:ABC...

5. bash setup.sh
   • openclaw NPM 전역 설치
   • ~/.openclaw/ 설정 파일 생성
   • identity/*.md → workspace 복사 (AGENTS.md, IDENTITY.md)
   • docs/*.md → workspace 복사 (Knowledge Base)

6. bash run.sh
   • 기존 프로세스 정리
   • openclaw gateway 백그라운드 실행
   • Telegram 페어링 안내 출력

7. Telegram 봇에 메시지 전송 → 페어링 코드 수신

8. openclaw pairing approve telegram [코드]

9. Telegram 봇과 대화 시작 (한국어, DA Assistant 톤)
```

---

## 7. 검증 방법

### 7-1. 기본 동작 검증

| 단계 | 방법 | 성공 기준 |
|------|------|----------|
| 게이트웨이 실행 | `bash run.sh` 후 프로세스 확인 | PID 출력, 로그에 에러 없음 |
| Telegram 연결 | 봇에 메시지 전송 | 페어링 코드 수신 |
| 페어링 승인 | `openclaw pairing approve telegram [코드]` | 승인 완료 메시지 |
| AI 응답 | 봇에 "안녕, 넌 뭘 할 수 있어?" 전송 | Claude 기반 한국어 응답 수신 |

### 7-2. 에이전트 Identity 검증

| 단계 | 방법 | 성공 기준 |
|------|------|----------|
| 한국어 응답 | 영어로 질문 전송 | 한국어로 답변 |
| 자기소개 | "자기소개해줘" 전송 | "DA Assistant" 이름, "담당자님" 호칭 사용 |
| 톤 | 일반 질문 전송 | 사무적이고 간결한 응답, 이모지 없음 |

### 7-3. 문서 기반 Q&A 검증

| 단계 | 방법 | 성공 기준 |
|------|------|----------|
| 문서 인식 | "어떤 문서가 있어?" 질문 | workspace 내 문서 목록 또는 내용 참조 |
| 사실 확인 | docs/test_report.md 내용에 대한 구체적 질문 | 문서 기반 정확한 답변 |
| 범위 외 질문 | 문서에 없는 내용 질문 | "해당 정보 없음" 또는 유사 응답 |

---

## 8. 완료 기준

- [x] `.env.example`에 `ANTHROPIC_API_KEY`와 `TELEGRAM_BOT_TOKEN`만 존재
- [x] `setup.sh`에서 Claude 전용 설정 생성
- [x] `setup.sh`에서 `identity/*.md`를 workspace에 자동 복사
- [x] `setup.sh`에서 `docs/*.md`를 workspace에 자동 복사
- [x] `run.sh`에서 게이트웨이 실행, WebUI 토큰 출력, Telegram 페어링 안내 출력
- [x] `README.md`가 WebUI + Telegram 배포 가이드로 작성됨
- [x] `identity/AGENTS.md`에 한국어 응답 지시 포함
- [x] `identity/IDENTITY.md`에 DA Assistant 정체성 정의
