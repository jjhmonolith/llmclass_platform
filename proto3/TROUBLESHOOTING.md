# 🔧 LLM Classroom Proto3 - 문제 해결 가이드

## 🚨 AI 응답 미작동 시 체크리스트

### 1. OpenAI API 키 확인

#### 증상
- "AI 응답 오류: AI 응답 생성에 실패했습니다." 메시지
- 500 Internal Server Error
- "Connection error" 로그

#### 해결 방법

```bash
# 1. 환경변수 파일 확인
cat /home/ubuntu/llm_classroom_proto3/.env

# 2. .env 파일이 없거나 API 키가 없다면 생성
nano /home/ubuntu/llm_classroom_proto3/.env
```

`.env` 파일 내용:
```
OPENAI_API_KEY=sk-proj-실제_API_키_입력
```

```bash
# 3. 서비스 재시작
sudo systemctl restart llm-classroom

# 4. 환경변수 로드 확인
sudo systemctl show llm-classroom --property=Environment | grep OPENAI_API_KEY
```

### 2. 네트워크 연결 문제

#### 증상
- "openai.APIConnectionError: Connection error"
- 타임아웃 오류

#### 해결 방법

```bash
# 1. 네트워크 연결 테스트
cd /home/ubuntu/llm_classroom_proto3
./check-network.sh

# 2. DNS 확인
nslookup api.openai.com

# 3. OpenAI API 직접 테스트
curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
```

### 3. 502 Bad Gateway 오류

#### 증상
- 브라우저에서 502 오류
- Nginx 오류 로그

#### 해결 방법

```bash
# 1. 서비스 상태 확인
sudo systemctl status llm-classroom

# 2. 포트 확인
sudo lsof -i :8080

# 3. 로그 확인
sudo journalctl -u llm-classroom -n 100

# 4. Nginx 재시작
sudo systemctl restart nginx
```

### 4. 가상환경 및 의존성 문제

#### 증상
- "Failed to locate executable" 오류
- ModuleNotFoundError

#### 해결 방법

```bash
cd /home/ubuntu/llm_classroom_proto3

# 1. 가상환경 재생성
python3 -m venv venv
source venv/bin/activate

# 2. 의존성 재설치
pip install --upgrade pip
pip install -r requirements.txt

# 3. gunicorn 확인
pip install gunicorn
which gunicorn
```

### 5. 포트 충돌 문제

#### 증상
- "Address already in use" 오류
- 서비스 시작 실패

#### 해결 방법

```bash
# 1. 포트 사용 프로세스 확인
sudo lsof -i :8080

# 2. 프로세스 종료 (PID는 실제 값으로 교체)
sudo kill -9 <PID>

# 3. 서비스 재시작
sudo systemctl restart llm-classroom
```

## 🚀 빠른 진단 스크립트

```bash
#!/bin/bash
# quick-diagnose.sh

echo "🔍 LLM Classroom 빠른 진단 시작..."

# 1. 서비스 상태
echo "1. 서비스 상태:"
sudo systemctl is-active llm-classroom

# 2. 환경변수
echo "2. OPENAI_API_KEY 설정:"
if [ -f /home/ubuntu/llm_classroom_proto3/.env ]; then
    grep -q "OPENAI_API_KEY" /home/ubuntu/llm_classroom_proto3/.env && echo "✅ 설정됨" || echo "❌ 미설정"
else
    echo "❌ .env 파일 없음"
fi

# 3. 포트 상태
echo "3. 포트 8080 상태:"
sudo lsof -i :8080 > /dev/null 2>&1 && echo "✅ 사용 중" || echo "❌ 미사용"

# 4. API 테스트
echo "4. API 헬스체크:"
curl -s http://localhost:8080/api/health > /dev/null 2>&1 && echo "✅ 정상" || echo "❌ 실패"

# 5. 최근 오류
echo "5. 최근 오류 로그:"
sudo journalctl -u llm-classroom -n 10 --no-pager | grep -E "ERROR|CRITICAL|Failed" || echo "오류 없음"
```

## 📦 업데이트 배포 시 주의사항

### 배포 전 체크리스트

1. **환경변수 백업**
   ```bash
   # 배포 전 .env 백업
   cp /home/ubuntu/llm_classroom_proto3/.env /home/ubuntu/.env.backup
   ```

2. **서비스 설정 백업**
   ```bash
   # 커스텀 서비스 설정 백업
   sudo cp /etc/systemd/system/llm-classroom.service /home/ubuntu/llm-classroom.service.backup
   ```

### 안전한 배포 절차

```bash
#!/bin/bash
# safe-deploy.sh

echo "🔄 안전한 배포 시작..."

# 1. 백업
echo "1. 설정 백업 중..."
[ -f .env ] && cp .env .env.backup.$(date +%Y%m%d)

# 2. 코드 업데이트
echo "2. 코드 업데이트 중..."
git pull origin main

# 3. 환경변수 복원
echo "3. 환경변수 확인..."
if [ ! -f .env ] && [ -f .env.backup.* ]; then
    echo "⚠️  .env 파일이 없습니다. 백업에서 복원합니다."
    cp $(ls -t .env.backup.* | head -1) .env
fi

# 4. 의존성 업데이트
echo "4. 의존성 업데이트 중..."
source venv/bin/activate
pip install -r requirements.txt

# 5. 서비스 재시작
echo "5. 서비스 재시작 중..."
sudo systemctl restart llm-classroom

# 6. 상태 확인
echo "6. 서비스 상태 확인..."
sleep 3
sudo systemctl status llm-classroom --no-pager

# 7. API 테스트
echo "7. API 테스트..."
sleep 2
curl -s http://localhost:8080/api/health | python3 -m json.tool

echo "✅ 배포 완료!"
```

### .gitignore 확인

`.gitignore`에 다음 항목들이 포함되어 있는지 확인:
```
.env
*.backup
*.backup.*
llm-classroom.log
__pycache__/
*.pyc
venv/
```

## 🆘 긴급 복구 절차

서비스가 완전히 망가진 경우:

```bash
#!/bin/bash
# emergency-recovery.sh

echo "🚨 긴급 복구 시작..."

# 1. 모든 프로세스 종료
sudo systemctl stop llm-classroom
sudo pkill -f gunicorn
sudo pkill -f uvicorn

# 2. 로그 백업
sudo journalctl -u llm-classroom > ~/llm-classroom-crash-$(date +%Y%m%d-%H%M%S).log

# 3. 클린 재시작
cd /home/ubuntu/llm_classroom_proto3
source venv/bin/activate

# 4. 수동 테스트
echo "수동 테스트 모드로 실행 (Ctrl+C로 종료)..."
python main.py

# 정상 작동 확인 후
# 5. 서비스로 재시작
# sudo systemctl start llm-classroom
```

## 📞 추가 지원

문제가 지속되는 경우:
1. 로그 파일 수집: `sudo journalctl -u llm-classroom > debug.log`
2. GitHub Issues에 보고: https://github.com/jjhmonolith/llm_classroom_proto3/issues
3. 로그와 함께 다음 정보 제공:
   - 오류 발생 시각
   - 수행한 작업
   - 오류 메시지 전문