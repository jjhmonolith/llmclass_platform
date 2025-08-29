# 🎓 LLM Classroom Platform

> AI 기반 소크라테스식, FIRE 프롬프트, 전략적 학습을 제공하는 통합 교육 플랫폼

## 🚀 빠른 시작

### 1. 모든 서비스 시작
```bash
./llmclass start
```

### 2. 상태 확인
```bash
./llmclass status
```

### 3. 서비스 중지
```bash
./llmclass stop
```

## 📍 서비스 접속

| 서비스 | 로컬 주소 | 외부 주소 | 설명 |
|-------|----------|-----------|------|
| **메인 허브** | http://localhost:8003 | https://hub.llmclass.org | 서비스 선택 허브 |
| **소크라테스** | http://localhost:8000 | https://socratic.llmclass.org | 대화식 학습 |
| **전략적 학습** | http://localhost:8001 | https://strategic.llmclass.org | 주제별 학습 |
| **FIRE 프롬프트** | http://localhost:8002 | https://fire.llmclass.org | 프롬프트 학습 |

## 🛠️ 전체 명령어

```bash
# 기본 제어
./llmclass start          # 모든 서비스 시작
./llmclass stop           # 모든 서비스 중지
./llmclass restart        # 모든 서비스 재시작
./llmclass status         # 서비스 상태 확인

# 모니터링
./llmclass health         # 헬스체크 (내부/외부 접속 테스트)
./llmclass logs           # 전체 로그 보기
./llmclass logs proto4    # 특정 서비스 로그 보기

# 터널 관리
./llmclass tunnel start   # 터널만 시작
./llmclass tunnel stop    # 터널만 중지

# 문제 해결
./llmclass doctor         # 자동 진단 및 수정

# 로컬 전용 모드
./llmclass start --local  # 터널 없이 로컬만
```

## ⚙️ 자동 시작 설정

```bash
# 시스템 부팅시 자동 시작 설정
./setup-autostart
```

## 📋 시스템 요구사항

- **Python 3.9+**
- **CloudFlare 계정** (외부 접속용)
- **macOS** (LaunchAgent 지원)

## 🔧 문제 해결

### 포트 충돌
```bash
./llmclass doctor
```

### 터널 연결 문제  
```bash
./llmclass tunnel restart
```

### 로그 확인
```bash
./llmclass logs [서비스명]
```

## 📁 프로젝트 구조

```
llmclass_platform/
├── llmclass              # 🎯 메인 제어 스크립트
├── setup-autostart       # 🚀 자동 시작 설정
├── proto1/               # 전략적 학습 (포트 8001)
├── proto3/               # FIRE 프롬프트 (포트 8002)
├── proto4/               # 소크라테스 (포트 8000)
├── student/              # 메인 허브 (포트 8003)
├── config/               # 설정 파일들
├── logs/                 # 로그 파일들
└── archive/              # 백업/아카이브
```

## 🔒 보안 주의사항

1. **API 키**: `.env` 파일에 OpenAI API 키 설정 필요
2. **CloudFlare**: 터널 자격증명은 `~/.cloudflared/`에 보관
3. **방화벽**: 로컬 네트워크에서만 직접 포트 접근 허용

---

## 📞 지원

- **버그 리포트**: GitHub Issues
- **문서**: `config/` 폴더 내 상세 가이드
- **로그**: `logs/` 폴더에서 디버그 정보 확인