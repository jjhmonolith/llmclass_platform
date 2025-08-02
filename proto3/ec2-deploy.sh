#!/bin/bash

# EC2 배포 및 재시작 스크립트

echo "🚀 LLM Classroom Proto3 EC2 배포 시작..."

# 1. 코드 업데이트
echo "📥 코드 업데이트 중..."
git pull origin main

# 2. 환경변수 확인
if [ ! -f .env ]; then
    echo "❌ .env 파일이 없습니다. 생성해주세요:"
    echo "OPENAI_API_KEY=your_api_key_here" > .env.example
    echo "cp .env.example .env 후 API 키를 설정하세요."
    exit 1
fi

# 3. 의존성 설치
echo "📦 의존성 설치 중..."
source venv/bin/activate
pip install -r requirements.txt

# 4. 서비스 파일 업데이트
echo "🔧 서비스 파일 업데이트 중..."
sudo cp llm-classroom.service /etc/systemd/system/
sudo systemctl daemon-reload

# 5. 서비스 재시작
echo "🔄 서비스 재시작 중..."
sudo systemctl restart llm-classroom
sleep 3

# 6. 상태 확인
echo "📊 서비스 상태 확인 중..."
sudo systemctl status llm-classroom --no-pager -l

# 7. 환경변수 확인
echo "🔍 환경변수 확인 중..."
if sudo systemctl show llm-classroom --property=Environment | grep -q "OPENAI_API_KEY"; then
    echo "✅ OPENAI_API_KEY 환경변수가 설정되었습니다."
else
    echo "❌ OPENAI_API_KEY 환경변수가 설정되지 않았습니다."
    echo "sudo systemctl edit llm-classroom 으로 수동 설정이 필요할 수 있습니다."
fi

# 8. API 테스트
echo "🧪 API 테스트 중..."
sleep 5
curl -s http://localhost:8080/api/health | python3 -m json.tool || echo "❌ API 테스트 실패"

echo "✅ 배포 완료!"
echo "📝 로그 확인: sudo journalctl -u llm-classroom -f"
echo "🌐 서비스 접속: http://your-ec2-ip"