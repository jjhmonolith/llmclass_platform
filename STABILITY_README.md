# 🛡️ LLM Classroom 서비스 안정성 보장 시스템

## 🎯 목표
맥미니에서 LLM Classroom 서비스들이 24/7 안정적으로 실행되도록 보장

## 🚨 해결된 문제들

### 1. **절전 모드 문제** ✅
- 맥이 슬립 모드로 들어가면 서비스 중단
- **해결**: `pmset` 명령으로 절전 비활성화

### 2. **터미널 세션 종료** ✅
- SSH 연결 끊김시 프로세스 종료
- **해결**: LaunchAgent로 시스템 레벨 실행

### 3. **시스템 재부팅** ✅
- 재부팅 후 수동 시작 필요
- **해결**: RunAtLoad=true로 자동 시작

### 4. **프로세스 크래시** ✅
- 예외 발생시 서비스 중단
- **해결**: KeepAlive로 자동 재시작

### 5. **포트 충돌** ✅
- 다른 프로세스가 포트 점유
- **해결**: 모니터링 스크립트로 감지

## 📦 구성 요소

### 1. **LaunchAgent 설정** (`launchd/` 폴더)
- `com.llmclassroom.hub.plist` - Student Hub (8003)
- `com.llmclassroom.proto1.plist` - Proto1 (8001)
- `com.llmclassroom.proto3.plist` - Proto3 (8002)
- `com.llmclassroom.proto4.plist` - Proto4 (8000)
- `com.llmclassroom.cloudflared.plist` - Cloudflare Tunnel

### 2. **설정 스크립트**
- `setup_autostart.sh` - 자동 시작 설정
- `monitor_services.sh` - 서비스 모니터링

### 3. **로그 파일** (`logs/` 폴더)
- 각 서비스별 표준 출력/에러 로그
- 모니터링 로그 및 알림 로그

## 🚀 설치 방법

### 1단계: 절전 모드 비활성화
```bash
# 모든 절전 기능 비활성화
sudo pmset -a sleep 0
sudo pmset -a hibernatemode 0
sudo pmset -a disksleep 0
sudo pmset -a displaysleep 0

# Wake on network 활성화
sudo pmset -a womp 1
```

### 2단계: 자동 시작 설정
```bash
cd /Users/jjh_server/llmclass_platform
./setup_autostart.sh
```

### 3단계: 모니터링 활성화 (선택사항)
```bash
# 백그라운드에서 모니터링 실행
nohup ./monitor_services.sh > /dev/null 2>&1 &
```

## 📊 서비스 관리 명령어

### 상태 확인
```bash
# 모든 서비스 상태
launchctl list | grep com.llmclassroom

# 포트 확인
lsof -i :8000-8003
```

### 서비스 제어
```bash
# 특정 서비스 중지
launchctl unload ~/Library/LaunchAgents/com.llmclassroom.hub.plist

# 특정 서비스 시작
launchctl load ~/Library/LaunchAgents/com.llmclassroom.hub.plist

# 서비스 재시작
launchctl kickstart -k gui/$UID/com.llmclassroom.hub
```

### 로그 확인
```bash
# 실시간 로그 보기
tail -f logs/*.log

# 에러 로그만 보기
tail -f logs/*.error.log

# 알림 로그 확인
cat logs/alerts.log
```

## 🔧 문제 해결

### 서비스가 시작되지 않을 때
1. 로그 파일 확인: `logs/[서비스명].error.log`
2. 포트 충돌 확인: `lsof -i :[포트번호]`
3. Python 경로 확인: `which python3`
4. 의존성 확인: 각 프로젝트의 requirements.txt

### 자주 재시작되는 경우
1. ThrottleInterval 값 증가 (현재 30초)
2. 메모리 사용량 확인
3. API 키 등 환경변수 확인

## 📈 추가 개선 사항

### 1. 알림 시스템
- 이메일/Slack 알림 추가 가능
- Webhook 통합

### 2. 리소스 모니터링
- CPU/메모리 사용량 추적
- 디스크 공간 모니터링

### 3. 백업 시스템
- 로그 파일 자동 로테이션
- 설정 파일 백업

## ⚠️ 주의사항

1. **전원 설정**: 절전 비활성화시 전력 소비 증가
2. **보안**: 방화벽 설정 확인 필요
3. **업데이트**: macOS 업데이트시 설정 재확인
4. **리소스**: 충분한 메모리/CPU 확보

## 📞 지원

문제 발생시:
1. `logs/` 폴더의 로그 파일 확인
2. `./check_services.sh` 실행하여 상태 점검
3. GitHub Issues에 문제 보고