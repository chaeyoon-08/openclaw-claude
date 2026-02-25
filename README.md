# 🦞 openclaw-webui

OpenClaw 인터페이스 테스트 — Web UI (브라우저) + Telegram 봇 연동

---

## gcube 워크로드 설정

| 항목 | 값 |
|------|-----|
| 이미지 | `coollabsio/openclaw:latest` |
| 포트 | `8080` |
| 초기명령어 | `bash -c "apt-get update -qq && apt-get install -y nano vim locales locales-all && locale-gen ko_KR.UTF-8 && sleep infinity"` |

---

## 사전 준비

**Gemini API 키 발급** (무료, 신용카드 불필요)
- 발급: https://aistudio.google.com/apikey

**Telegram 봇 토큰 발급**
- Telegram에서 `@BotFather` 검색 (파란 체크 확인)
- `/newbot` 입력 → 봇 이름, 유저네임 설정
- 발급된 토큰 저장

---

## 실행 방법

**1. Clone**
```bash
git clone https://github.com/chaeyoon-08/openclaw-webui.git
cd openclaw-webui
```

**2. 환경변수 설정**
```bash
cp .env.example .env
nano .env
```
```
GEMINI_API_KEY=발급받은_Gemini_키
TELEGRAM_BOT_TOKEN=발급받은_Telegram_봇_토큰
```

**3. Setup (최초 1회)**
```bash
bash setup.sh
```

**4. 실행**
```bash
bash run.sh
```
- 터미널 출력 링크 클릭 → 브라우저 자동 로그인

**5. Telegram 봇 연동**
- 봇에게 메시지 전송 → pairing 코드 수신
- 터미널에서 승인:
```bash
openclaw pairing approve telegram [코드]
```

---

## 테스트 성공 기준

| 레이어 | 방법 | 성공 기준 |
|--------|------|----------|
| 1. 접속 확인 | run.sh 링크 클릭 | 채팅 UI 로드 |
| 2. AI 응답 확인 | `안녕, 넌 뭘 할 수 있어?` 입력 | AI 텍스트 응답 |
| 3. Telegram 확인 | 봇에게 메시지 전송 | AI 답장 수신 |

---

## 파일 구조

```
openclaw-webui/
├── README.md        ← 실행 방법 (이 파일)
├── setup.sh         ← 최초 1회: ~/.openclaw 설정 자동 생성
├── run.sh           ← gateway 실행 + 접속 링크 출력
├── .env.example     ← API 키 형식 가이드 (git 추적됨)
├── .env             ← 실제 API 키 (git 무시됨)
└── .gitignore
```

---

## 문제 해결

**gateway 실행 실패**
```bash
cat ~/.openclaw/gateway.log
```

**Telegram 봇 미응답**
```bash
openclaw pairing list
openclaw pairing approve telegram [코드]
```

**rate limit 에러**
- 1~2분 대기 후 재시도 (무료 플랜: 분당 10회 제한)