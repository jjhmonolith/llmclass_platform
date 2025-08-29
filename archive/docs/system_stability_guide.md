# 🛡️ LLM Classroom 서비스 안정성 보장 가이드

## 📋 목차
1. [문제 케이스 분석](#문제-케이스-분석)
2. [해결방안](#해결방안)
3. [구현 가이드](#구현-가이드)
4. [모니터링 및 알림](#모니터링-및-알림)

## 🚨 문제 케이스 분석

### 1. 맥미니 절전 모드
- **문제**: 맥이 슬립 모드로 들어가면 모든 서비스 중단
- **영향**: 외부 접속 불가, Cloudflare Tunnel 연결 끊김

### 2. 터미널 세션 종료
- **문제**: SSH 연결 끊김 또는 터미널 앱 종료시 프로세스 중단
- **영향**: 백그라운드 실행이 아닌 경우 서비스 중단

### 3. 시스템 재부팅
- **문제**: 정전, 시스템 업데이트, 예기치 않은 재시작
- **영향**: 수동으로 서비스를 다시 시작해야 함

### 4. 프로세스 크래시
- **문제**: Python 프로세스가 예외로 인해 종료
- **영향**: 해당 서비스만 중단, 다른 서비스는 계속 실행

### 5. 포트 충돌
- **문제**: 다른 프로그램이 같은 포트 사용
- **영향**: 서비스 시작 실패

## 🛠️ 해결방안

### 1. 절전 모드 비활성화
```bash
# 절전 모드 완전 비활성화
sudo pmset -a sleep 0
sudo pmset -a disksleep 0
sudo pmset -a displaysleep 0

# 전원 어댑터 연결시 절전 안함
sudo pmset -c sleep 0

# 시스템 설정 확인
pmset -g
```

### 2. LaunchDaemon 설정 (시스템 레벨 자동 시작)
각 서비스를 시스템 데몬으로 등록하여 자동 시작 및 재시작 보장

### 3. 프로세스 모니터링 (PM2 사용)
```bash
# PM2 설치
npm install -g pm2

# Python 앱을 PM2로 관리
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### 4. 헬스체크 및 자동 복구
정기적으로 서비스 상태를 확인하고 문제 발생시 자동 재시작

## 📝 구현 가이드

### Step 1: 절전 모드 비활성화
```bash
#!/bin/bash
# disable_sleep.sh

echo "🔧 맥미니 절전 모드 비활성화 중..."

# 모든 절전 기능 비활성화
sudo pmset -a sleep 0
sudo pmset -a hibernatemode 0
sudo pmset -a disksleep 0
sudo pmset -a displaysleep 0

# Wake on network access 활성화
sudo pmset -a womp 1

# 설정 확인
echo "✅ 현재 전원 설정:"
pmset -g

echo "💡 주의: 디스플레이는 꺼질 수 있지만 시스템은 계속 실행됩니다."
```

### Step 2: LaunchDaemon 파일 생성