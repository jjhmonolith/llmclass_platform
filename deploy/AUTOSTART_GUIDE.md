# macOS 자동 시작 설정 가이드

## 📖 개요

이 가이드는 Mac mini에서 LLM Class Platform을 부팅 시 자동으로 시작하도록 설정하는 방법을 설명합니다.

### 포함된 서비스
- **Docker Services**: 백엔드, 데이터베이스, 프록시 컨테이너
- **Services Watchdog**: 서비스 상태 모니터링 및 자동 복구
- **Cloudflare Tunnel**: 외부 도메인 연결 (선택사항)

---

## 🚀 빠른 설정

### 1. 자동 설정 스크립트 실행
```bash
cd deploy/launchd
./setup-autostart.sh
```

이 스크립트는 다음을 자동으로 수행합니다:
- launchd 서비스 파일 생성
- 사용자명과 경로 자동 설정
- 서비스 로드 및 활성화
- 전제 조건 확인

### 2. Docker Desktop 자동 시작 설정
Docker Desktop > Settings > General > "Start Docker Desktop when you log in" 체크

### 3. 재부팅 테스트
```bash
sudo reboot
# 재부팅 후 서비스 상태 확인
make status ENV=prod
```

---

## 🔧 수동 설정 (단계별)

### 1. 전제 조건 확인
```bash
# Docker가 설치되어 있는지 확인
docker --version

# 프로덕션 환경 파일 확인
ls -la .env.prod

# 로그 디렉토리 생성
mkdir -p ../logs
```

### 2. 서비스 파일 생성
```bash
# 사용자별 LaunchAgents 디렉토리로 복사
cp docker-services.plist.example ~/Library/LaunchAgents/com.llmclass.platform.services.plist
cp docker-watchdog.plist.example ~/Library/LaunchAgents/com.llmclass.platform.watchdog.plist

# Cloudflare Tunnel (선택사항)
cp ../cloudflared/launchd.plist.example ~/Library/LaunchAgents/com.cloudflare.cloudflared.llmclass.plist
```

### 3. 설정 파일 편집
각 파일에서 다음을 실제 값으로 변경:
- `YOUR_USERNAME` → 실제 사용자명
- 모든 경로를 실제 프로젝트 경로로 수정

### 4. 서비스 로드 및 시작
```bash
# 서비스 로드
launchctl load ~/Library/LaunchAgents/com.llmclass.platform.services.plist
launchctl load ~/Library/LaunchAgents/com.llmclass.platform.watchdog.plist

# 서비스 시작
launchctl start com.llmclass.platform.services
launchctl start com.llmclass.platform.watchdog

# 상태 확인
launchctl list | grep llmclass
```

---

## 📊 서비스 구성 상세

### Docker Services (com.llmclass.platform.services)
- **역할**: Docker Compose로 모든 컨테이너 시작
- **실행**: 부팅 시 자동 실행
- **재시작**: 실패 시 자동 재시작 (60초 간격)
- **로그**: `logs/services.log`, `logs/services.error.log`

### Services Watchdog (com.llmclass.platform.watchdog)
- **역할**: 5분마다 서비스 상태 점검 및 복구
- **기능**:
  - 컨테이너 상태 확인
  - 헬스체크 실행
  - 실패한 서비스 재시작
  - 로그 정리 (1000줄 유지)
- **로그**: `logs/watchdog.log`, `logs/watchdog.error.log`

### Cloudflare Tunnel (com.cloudflare.cloudflared.llmclass)
- **역할**: 외부 도메인으로 터널 연결
- **실행**: Cloudflare 설정 완료 시에만
- **로그**: `logs/cloudflared.log`, `logs/cloudflared.error.log`

---

## 🔍 모니터링 및 관리

### 서비스 상태 확인
```bash
# 로드된 서비스 목록
launchctl list | grep -E "(llmclass|cloudflared)"

# 특정 서비스 상세 정보
launchctl list com.llmclass.platform.services

# Docker 컨테이너 상태
make status ENV=prod
```

### 로그 확인
```bash
# 실시간 로그 모니터링
tail -f logs/services.log
tail -f logs/watchdog.log
tail -f logs/cloudflared.log

# 최근 로그 확인
tail -50 logs/services.log
```

### 수동 제어
```bash
# 서비스 중지
launchctl stop com.llmclass.platform.services
launchctl stop com.llmclass.platform.watchdog

# 서비스 시작
launchctl start com.llmclass.platform.services
launchctl start com.llmclass.platform.watchdog

# 서비스 재시작
launchctl stop com.llmclass.platform.services
launchctl start com.llmclass.platform.services
```

---

## 🔧 트러블슈팅

### 일반적인 문제들

#### 1. 서비스가 시작되지 않음
```bash
# 서비스 상태 확인
launchctl list com.llmclass.platform.services

# 로그 확인
tail -50 logs/services.error.log

# Docker가 실행 중인지 확인
docker info

# 수동으로 서비스 시작 테스트
cd deploy && make up ENV=prod
```

#### 2. "Permission denied" 에러
```bash
# 스크립트 실행 권한 확인
ls -l launchd/watchdog.sh

# 권한 수정
chmod +x launchd/watchdog.sh
```

#### 3. 경로 관련 에러
```bash
# plist 파일의 경로가 올바른지 확인
grep -n "YOUR_USERNAME" ~/Library/LaunchAgents/com.llmclass.platform.services.plist

# 실제 경로로 수정 필요
```

#### 4. Docker 연결 실패
```bash
# Docker Desktop이 자동 시작되도록 설정
# Docker Desktop > Settings > General > "Start Docker Desktop when you log in"

# Docker 소켓 경로 확인
ls -la ~/.docker/run/docker.sock
```

### 로그 분석

**정상 실행 시 로그:**
```
[2025-08-01 09:00:00] 🐕 Watchdog check starting...
[2025-08-01 09:00:01] ✅ Docker is running
[2025-08-01 09:00:02] 📊 Service Status - Backend: running, DB: running, Proxy: running
[2025-08-01 09:00:03] ✅ All services are running
[2025-08-01 09:00:04] ✅ Backend health check passed
[2025-08-01 09:00:05] ✅ Database connectivity check passed
```

**문제 발생 시 로그:**
```
[2025-08-01 09:00:00] ❌ Docker is not running - cannot check services
[2025-08-01 09:00:00] ⚠️  Backend is not running
[2025-08-01 09:00:01] 🔄 Restarting services...
```

---

## 🔐 보안 고려사항

### 1. 사용자 권한
- 모든 서비스는 root가 아닌 사용자 권한으로 실행
- Docker 접근 권한은 사용자의 Docker 그룹 멤버십에 의존

### 2. 로그 보안
- 로그 파일은 사용자 홈 디렉토리에 저장
- 민감한 정보가 로그에 기록되지 않도록 주의

### 3. 네트워크 보안
- 모든 서비스는 localhost에서만 접근 가능
- Cloudflare Tunnel을 통해서만 외부 접근 허용

---

## 📈 성능 최적화

### 1. 시작 시간 최적화
```xml
<!-- 네트워크 준비까지 대기 -->
<key>NetworkState</key>
<true/>

<!-- 시작 간격 조정 -->
<key>StartInterval</key>
<integer>30</integer>
```

### 2. 리소스 사용 최적화
```xml
<!-- 백그라운드 프로세스로 실행 -->
<key>ProcessType</key>
<string>Background</string>

<!-- I/O 우선순위 낮춤 -->
<key>LowPriorityIO</key>
<true/>
```

### 3. 재시작 최적화
```xml
<!-- 재시작 간격 설정 -->
<key>ThrottleInterval</key>
<integer>60</integer>
```

---

## ✅ 설정 완료 체크리스트

- [ ] Docker Desktop 설치 및 자동 시작 설정
- [ ] 프로젝트 클론 및 .env.prod 설정
- [ ] launchd 서비스 파일 생성 및 편집
- [ ] 서비스 로드 및 시작
- [ ] 로그 디렉토리 생성 및 권한 설정
- [ ] Cloudflare Tunnel 설정 (선택사항)
- [ ] 서비스 상태 확인
- [ ] 재부팅 테스트
- [ ] 외부 접근 테스트 (도메인)
- [ ] 모니터링 설정 (로그 확인)

---

## 🆘 도움 받기

### 로그 파일 위치
- 서비스 로그: `deploy/logs/services.log`
- 워치독 로그: `deploy/logs/watchdog.log`
- 터널 로그: `deploy/logs/cloudflared.log`

### 유용한 명령어
```bash
# 모든 서비스 상태 한 번에 확인
launchctl list | grep -E "(llmclass|cloudflared)"

# 서비스 완전 제거
launchctl unload ~/Library/LaunchAgents/com.llmclass.platform.services.plist
rm ~/Library/LaunchAgents/com.llmclass.platform.services.plist

# 시스템 로그 확인
log show --predicate 'subsystem == "com.apple.launchd"' --last 1h
```