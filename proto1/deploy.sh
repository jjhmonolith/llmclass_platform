#!/bin/bash

# LLM Classroom AWS 배포 스크립트
echo "🚀 LLM Classroom AWS 배포를 시작합니다..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 환경 설정 확인
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env 파일이 없습니다. .env.example을 참고하여 .env 파일을 생성해주세요.${NC}"
    exit 1
fi

# 의존성 설치
echo -e "${YELLOW}📦 의존성을 설치합니다...${NC}"
pip install -r requirements.txt

# 환경 변수 로드
source .env

# 애플리케이션 시작
echo -e "${GREEN}🎯 애플리케이션을 시작합니다...${NC}"
echo -e "${YELLOW}서버 주소: http://0.0.0.0:${APP_PORT:-8000}${NC}"

# 프로덕션 모드로 uvicorn 실행
uvicorn main:app \
    --host ${APP_HOST:-0.0.0.0} \
    --port ${APP_PORT:-8000} \
    --workers 1 \
    --log-level info \
    --access-log