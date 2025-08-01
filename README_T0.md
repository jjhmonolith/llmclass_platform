# LLM Class Platform - T0 인프라 부트스트랩 가이드

## 🎯 T0 단계 개요

T0는 교육용 통합 플랫폼의 **인프라 부트스트랩** 단계로, Mac mini에서 Docker Compose 기반의 기본 서비스를 구축하고 Cloudflare Tunnel을 통해 외부 접근을 가능하게 하는 것이 목표입니다.

**최종 목표**: `https://platform.llmclass.org`로 접근 가능한 안정적인 플랫폼 제공

---

## 🏗️ 아키텍처 구성

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloudflare Tunnel                         │
│                 platform.llmclass.org                       │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTPS (443)
┌─────────────────────▼───────────────────────────────────────┐
│                  Mac Mini                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │               Docker Compose                            │ │
│  │                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │ │
│  │  │   Nginx     │  │   FastAPI   │  │ PostgreSQL  │      │ │
│  │  │   Proxy     │  │   Backend   │  │  Database   │      │ │
│  │  │    :80      │  │   :8000     │  │   :5432     │      │ │
│  │  │             │  │             │  │             │      │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              macOS Auto-start                           │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │ │
│  │  │   Docker     │  │   Services   │  │  Cloudflare  │   │ │
│  │  │  Services    │  │  Watchdog    │  │   Tunnel     │   │ │
│  │  │  (launchd)   │  │  (launchd)   │  │  (launchd)   │   │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 구현 완료 항목

### ✅ T0-1: 프로젝트 구조 설계
```
llmclass_platform/
├── backend/                 # FastAPI 백엔드
│   ├── app/
│   │   ├── main.py         # 메인 애플리케이션
│   │   ├── models/         # 데이터베이스 모델
│   │   └── api/            # API 라우터
│   ├── requirements.txt    # Python 의존성
│   └── Dockerfile         # 백엔드 이미지
├── frontend/              # React SPA
│   └── public/
│       └── index.html     # 상태 대시보드
├── deploy/                # 배포 설정
│   ├── docker-compose.yml # 컨테이너 구성
│   ├── nginx/             # 프록시 설정
│   ├── cloudflared/       # 터널 설정
│   ├── launchd/           # 자동 시작 설정
│   ├── .env.dev           # 개발 환경
│   ├── .env.prod.example  # 프로덕션 템플릿
│   └── Makefile           # 관리 명령어
└── README_T0.md           # 이 문서
```

### ✅ T0-2: FastAPI 백엔드 구현
**핵심 엔드포인트**:
- `GET /healthz` - 헬스체크 (DB 연결 상태 포함)
- `GET /api/version` - 버전 정보
- `POST /api/echo` - 에코 테스트

**주요 기능**:
- 구조화 로깅 (JSON 형태)
- CORS 설정
- PostgreSQL 연결 풀
- 환경별 설정 분리

### ✅ T0-3: PostgreSQL 환경 설정
**환경 파일 구성**:
- `.env.dev`: 개발용 (포함됨)
- `.env.prod.example`: 프로덕션 템플릿
- 데이터베이스 자격증명 분리
- 보안 패스워드 설정

### ✅ T0-4: Docker Compose 구성
**서비스 구성**:
```yaml
services:
  db:        # PostgreSQL 15
  backend:   # FastAPI + Uvicorn
  proxy:     # Nginx 리버스 프록시
```

**주요 특징**:
- 헬스체크 구현
- 의존성 관리
- 볼륨 퍼시스턴스
- 네트워크 격리

### ✅ T0-5: Nginx 프록시 설정
**기능**:
- 프론트엔드 정적 파일 서빙
- API 요청 백엔드 프록시
- Cloudflare IP 처리
- 레이트 리미팅 (10req/sec)
- WebSocket 지원
- 캐싱 최적화

### ✅ T0-6: 프론트엔드 상태 대시보드
**실시간 모니터링**:
- 서버 상태 (CPU, 메모리, 디스크)
- 서비스 헬스체크
- 클라이언트 정보
- 30초 자동 갱신

### ✅ T0-7: 로컬 테스트 검증
**테스트 도구**:
- `test-local.sh`: 종합 테스트 스크립트
- `env-check.sh`: 환경 검증
- Makefile 통합 명령어

### ✅ T0-8: Cloudflare Tunnel 설정
**템플릿 제공**:
- `setup-tunnel.sh`: 터널 설정 자동화
- `manage-tunnel.sh`: 터널 관리
- 설정 가이드 문서
- launchd 자동 시작 지원

### ✅ T0-9: macOS 자동 시작 설정
**launchd 서비스**:
- Docker Services: 컨테이너 자동 시작
- Services Watchdog: 5분마다 상태 점검
- Cloudflare Tunnel: 터널 자동 연결
- `setup-autostart.sh`: 원클릭 설정

---

## 🚀 빠른 시작 가이드

### 1. 환경 준비
```bash
# 필수 소프트웨어 설치
- Docker Desktop (자동 시작 설정)
- Git
- jq, curl (macOS 기본 포함)

# 프로젝트 클론
git clone https://github.com/jjhmonolith/llmclass_platform.git
cd llmclass_platform/deploy
```

### 2. 환경 설정
```bash
# 프로덕션 환경 생성
make setup-prod

# .env.prod 파일 편집
nano .env.prod
# 변경 필요: POSTGRES_PASSWORD, TUNNEL_ID, TUNNEL_TOKEN
```

### 3. 서비스 시작
```bash
# 개발 환경
make up ENV=dev

# 프로덕션 환경
make up ENV=prod

# 상태 확인
make status
make health
```

### 4. 자동 시작 설정
```bash
# 자동 설정 스크립트 실행
make autostart-setup

# 재부팅 테스트
sudo reboot

# 부팅 후 확인
make status ENV=prod
```

---

## 🔧 관리 명령어

### 환경 관리
```bash
make setup-dev          # 개발 환경 설정
make setup-prod         # 프로덕션 환경 설정
```

### 서비스 관리
```bash
make up ENV=prod        # 서비스 시작
make down ENV=prod      # 서비스 중지
make restart ENV=prod   # 서비스 재시작
make logs ENV=prod      # 로그 확인
```

### 테스트 및 검증
```bash
make test-local         # 종합 테스트
make test-endpoints     # API 엔드포인트 테스트
make health            # 헬스체크
```

### Cloudflare Tunnel
```bash
make tunnel-setup      # 터널 설정
make tunnel-start      # 터널 시작
make tunnel-status     # 터널 상태
make tunnel-logs       # 터널 로그
```

### 자동 시작 관리
```bash
make autostart-setup   # 자동 시작 설정
make autostart-status  # 상태 확인
make autostart-logs    # 로그 확인
```

### 유지보수
```bash
make backup-db         # 데이터베이스 백업
make clean            # Docker 리소스 정리
```

---

## 📊 모니터링

### 1. 실시간 상태 확인
- **웹 대시보드**: `https://platform.llmclass.org`
- **로컬 접근**: `http://localhost` (포트 80)

### 2. 로그 위치
```
deploy/logs/
├── services.log        # Docker 서비스 로그
├── services.error.log  # 서비스 에러 로그
├── watchdog.log        # 워치독 로그
├── watchdog.error.log  # 워치독 에러 로그
├── cloudflared.log     # 터널 로그
└── cloudflared.error.log # 터널 에러 로그
```

### 3. 핵심 지표
- **가용성**: 서비스 업타임 99%+
- **응답시간**: API 응답 < 200ms
- **리소스**: CPU < 50%, 메모리 < 1GB
- **디스크**: 사용률 < 80%

---

## 🔐 보안 설정

### 1. 데이터베이스 보안
- 강력한 패스워드 설정
- 네트워크 격리 (Docker 내부망)
- 정기 백업

### 2. 웹 서비스 보안
- Cloudflare 통한 DDoS 보호
- 레이트 리미팅 설정
- HTTPS 강제 (Cloudflare SSL)

### 3. 시스템 보안
- 비-root 사용자로 실행
- 로그 접근 권한 제한
- 환경 변수 보안

---

## 🐛 트러블슈팅

### 1. 서비스 시작 실패
```bash
# Docker 상태 확인
docker info

# 환경 파일 검증
./env-check.sh prod

# 볼륨 초기화
make down-volumes ENV=prod
make up ENV=prod
```

### 2. 데이터베이스 연결 실패
```bash
# 패스워드 불일치 시 볼륨 재생성
docker compose down -v
docker compose up -d

# 연결 테스트
make shell-db ENV=prod
```

### 3. 자동 시작 문제
```bash
# 서비스 상태 확인
launchctl list | grep llmclass

# 로그 확인
tail -f logs/services.log
tail -f logs/watchdog.log

# 서비스 재로드
launchctl unload ~/Library/LaunchAgents/com.llmclass.platform.services.plist
launchctl load ~/Library/LaunchAgents/com.llmclass.platform.services.plist
```

### 4. Cloudflare Tunnel 문제
```bash
# 터널 상태 확인
make tunnel-status

# 수동 터널 테스트
cd cloudflared
./manage-tunnel.sh start --debug
```

---

## 📈 성능 최적화

### 1. Docker 최적화
- Multi-stage 빌드
- 이미지 레이어 최적화
- 헬스체크 간격 조정

### 2. Nginx 최적화
- 압축 활성화
- 정적 파일 캐싱
- 연결 풀링

### 3. 데이터베이스 최적화
- 연결 풀 설정
- 쿼리 최적화
- 정기 VACUUM

---

## 🔄 백업 및 복구

### 1. 데이터베이스 백업
```bash
# 자동 백업
make backup-db ENV=prod

# 수동 백업
docker compose exec db pg_dump -U appuser -d llmclass > backup.sql
```

### 2. 설정 파일 백업
```bash
# 중요 설정 파일들
deploy/.env.prod
deploy/cloudflared/tunnel.yml
~/Library/LaunchAgents/com.llmclass.platform.*.plist
```

### 3. 복구 절차
```bash
# 서비스 중지
make down ENV=prod

# 데이터 복원
docker compose exec -T db psql -U appuser -d llmclass < backup.sql

# 서비스 재시작
make up ENV=prod
```

---

## 📝 다음 단계 (T1+)

### T1: 사용자 인증 시스템
- OAuth2/JWT 인증
- 사용자 등급 관리
- 세션 관리

### T2: 교육 콘텐츠 관리
- 강의 업로드 시스템
- 진도 추적
- 평가 시스템

### T3: 실시간 학습 환경
- WebRTC 화상 수업
- 채팅 시스템
- 화면 공유

---

## 🆘 지원 및 문의

### 문서
- **이 가이드**: T0 인프라 부트스트랩
- **자동 시작 가이드**: `deploy/AUTOSTART_GUIDE.md`
- **Makefile 도움말**: `make help`

### 로그 및 모니터링
- 실시간 대시보드: https://platform.llmclass.org
- 로그 위치: `deploy/logs/`
- 시스템 상태: `make health ENV=prod`

### 문제 해결
1. 로그 확인: `make autostart-logs`
2. 서비스 상태: `make status ENV=prod`
3. 헬스체크: `make test-endpoints ENV=prod`
4. 시스템 재시작: `sudo reboot`

---

## 📊 T0 단계 완료 체크리스트

- [x] **T0-1**: 프로젝트 구조 설계 및 생성
- [x] **T0-2**: FastAPI 백엔드 스켈레톤 구현
- [x] **T0-3**: PostgreSQL 환경 설정
- [x] **T0-4**: Docker Compose 구성
- [x] **T0-5**: Nginx 프록시 설정
- [x] **T0-6**: 프론트엔드 상태 페이지
- [x] **T0-7**: 로컬 Docker 테스트
- [x] **T0-8**: Cloudflare Tunnel 템플릿
- [x] **T0-9**: 자동 시작 설정
- [x] **T0-10**: 문서화 및 Makefile

---

**🎉 T0 인프라 부트스트랩 완료!**

이제 안정적이고 확장 가능한 기반 인프라가 준비되었습니다. T1 단계에서는 사용자 인증과 기본 교육 기능을 구현할 예정입니다.