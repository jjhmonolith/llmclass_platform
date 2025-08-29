# 🖥️ 로컬 개발환경 가이드

## 📋 개요
다른 컴퓨터에서 LLM Classroom을 로컬 개발용으로 실행하는 가이드입니다.
**Cloudflare Tunnel 없이** localhost에서만 접속 가능합니다.

## 🚀 빠른 시작

### 1. 저장소 클론
```bash
git clone https://github.com/jjhmonolith/llmclass_platform.git
cd llmclass_platform
```

### 2. Python 의존성 설치
```bash
# 각 프로젝트별로 설치
cd student && pip install -r requirements.txt && cd ..
cd proto1 && pip install -r requirements.txt && cd ..
cd proto3 && pip install -r requirements.txt && cd ..
cd proto4 && pip install -r backend/requirements.txt && cd ..
```

### 3. 환경변수 설정
```bash
# .env 파일 생성 (필요한 경우)
echo "OPENAI_API_KEY=your-api-key-here" > .env
```

### 4. 개발 서버 시작
```bash
./start_dev_local.sh
```

### 5. 개발 서버 종료
```bash
./stop_dev_local.sh
# 또는 Ctrl+C
```

## 📍 접속 주소
- **Student Hub**: http://localhost:8003
- **Proto4 (Socratic)**: http://localhost:8000
- **Proto1 (Strategic)**: http://localhost:8001
- **Proto3 (Fire)**: http://localhost:8002

## 🔧 스크립트 설명

### `start_dev_local.sh`
- 모든 서비스를 localhost에서 시작
- 포트 충돌 검사
- 의존성 확인
- 실시간 로그 저장
- Ctrl+C로 종료 가능

### `stop_dev_local.sh`
- 실행 중인 모든 서비스 종료
- PID 파일 정리
- 포트 해제 확인

## 📊 개발중 유용한 명령어

### 로그 확인
```bash
# 실시간 로그 보기
tail -f logs/*.log

# 특정 서비스 로그
tail -f logs/Student_Hub.log
tail -f logs/Proto4_Socratic.log
```

### 프로세스 확인
```bash
# 실행 중인 서비스 확인
ps aux | grep 'python.*main.py'

# 포트 사용 확인
lsof -i :8000-8003
```

### 개별 서비스 실행
```bash
# Student Hub만 실행
cd student/backend && python3 main.py

# Proto4만 실행
cd proto4/backend && python3 main.py
```

## ⚠️ 주의사항

1. **로컬 전용**: 외부에서 접속 불가 (localhost only)
2. **API 키**: OpenAI API 키 필요
3. **Python 버전**: Python 3.9+ 권장
4. **포트 충돌**: 8000-8003 포트가 비어있어야 함

## 🆚 프로덕션 vs 개발 환경

| 구분 | 프로덕션 (맥미니) | 개발 (로컬) |
|------|------------------|------------|
| 시작 스크립트 | `start_all_services.sh` | `start_dev_local.sh` |
| 자동 시작 | LaunchAgent (O) | 수동 실행 (X) |
| 외부 접속 | Cloudflare Tunnel (O) | localhost only (X) |
| 프로세스 관리 | 자동 재시작 | 수동 관리 |
| 로그 위치 | 시스템 로그 | `logs/` 폴더 |

## 🐛 문제 해결

### 포트 충돌
```bash
# 포트 사용 중인 프로세스 확인
lsof -i :8000

# 강제 종료
kill -9 $(lsof -ti :8000)
```

### 의존성 오류
```bash
# 가상환경 사용 권장
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate  # Windows

pip install -r requirements.txt
```

### Permission Denied
```bash
chmod +x start_dev_local.sh
chmod +x stop_dev_local.sh
```