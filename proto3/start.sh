#!/bin/bash

# LLM Classroom Proto3 시작 스크립트

echo "🚀 LLM Classroom Proto3 시작 중..."

# 환경변수 확인
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ 오류: OPENAI_API_KEY 환경변수가 설정되지 않았습니다."
    echo "다음 명령어로 설정하세요:"
    echo "export OPENAI_API_KEY=your_api_key_here"
    exit 1
fi

# 의존성 설치 확인
echo "📦 의존성 확인 중..."
pip install -r requirements.txt

# 포트 확인 및 정리
PORT=${PORT:-8080}
echo "🔍 포트 $PORT 사용 중인 프로세스 확인..."
EXISTING_PID=$(lsof -ti:$PORT)
if [ ! -z "$EXISTING_PID" ]; then
    echo "⚠️  포트 $PORT에서 실행 중인 프로세스 ($EXISTING_PID) 종료 중..."
    kill -9 $EXISTING_PID
    sleep 2
fi

# 서버 시작
echo "🌟 FastAPI 서버 시작 (포트: $PORT)..."
echo "📍 접속 주소: http://localhost:$PORT"
echo "💡 종료하려면 Ctrl+C를 누르세요."
echo ""

# 프로덕션 환경에서는 gunicorn 사용
if [ "$ENV" = "production" ]; then
    echo "🏭 프로덕션 모드로 실행 중..."
    gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:$PORT
else
    echo "🔧 개발 모드로 실행 중..."
    python main.py
fi