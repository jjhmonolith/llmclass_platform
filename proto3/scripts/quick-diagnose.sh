#!/bin/bash
# quick-diagnose.sh - LLM Classroom 빠른 진단 도구

echo "🔍 LLM Classroom 빠른 진단 시작..."
echo "=================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 1. 서비스 상태
echo -n "1. 서비스 상태: "
if sudo systemctl is-active --quiet llm-classroom; then
    echo -e "${GREEN}✅ 실행 중${NC}"
else
    echo -e "${RED}❌ 중지됨${NC}"
    echo "   → sudo systemctl start llm-classroom"
fi

# 2. 환경변수
echo -n "2. OPENAI_API_KEY: "
if [ -f /home/ubuntu/llm_classroom_proto3/.env ]; then
    if grep -q "OPENAI_API_KEY" /home/ubuntu/llm_classroom_proto3/.env; then
        echo -e "${GREEN}✅ 설정됨${NC}"
    else
        echo -e "${RED}❌ 미설정${NC}"
        echo "   → nano /home/ubuntu/llm_classroom_proto3/.env"
    fi
else
    echo -e "${RED}❌ .env 파일 없음${NC}"
    echo "   → cp .env.example .env && nano .env"
fi

# 3. 포트 상태
echo -n "3. 포트 8080: "
if sudo lsof -i :8080 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 사용 중${NC}"
    sudo lsof -i :8080 | grep LISTEN | head -1
else
    echo -e "${RED}❌ 미사용${NC}"
    echo "   → 서비스가 실행되지 않았을 수 있습니다"
fi

# 4. API 테스트
echo -n "4. API 헬스체크: "
if response=$(curl -s -w "\n%{http_code}" http://localhost:8080/api/health 2>/dev/null); then
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 정상 (HTTP $http_code)${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTP $http_code${NC}"
    fi
else
    echo -e "${RED}❌ 연결 실패${NC}"
fi

# 5. Nginx 상태
echo -n "5. Nginx 상태: "
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ 실행 중${NC}"
else
    echo -e "${RED}❌ 중지됨${NC}"
    echo "   → sudo systemctl start nginx"
fi

# 6. 가상환경 체크
echo -n "6. Python 가상환경: "
if [ -d /home/ubuntu/llm_classroom_proto3/venv ]; then
    echo -e "${GREEN}✅ 존재함${NC}"
    echo -n "   gunicorn: "
    if [ -f /home/ubuntu/llm_classroom_proto3/venv/bin/gunicorn ]; then
        echo -e "${GREEN}✅ 설치됨${NC}"
    else
        echo -e "${RED}❌ 미설치${NC}"
    fi
else
    echo -e "${RED}❌ venv 없음${NC}"
fi

# 7. 디스크 공간
echo -n "7. 디스크 여유 공간: "
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -lt 80 ]; then
    echo -e "${GREEN}✅ ${disk_usage}% 사용${NC}"
else
    echo -e "${YELLOW}⚠️  ${disk_usage}% 사용 (정리 필요)${NC}"
fi

# 8. 최근 오류
echo "8. 최근 오류 (5줄):"
echo "----------------------------------"
sudo journalctl -u llm-classroom -n 5 --no-pager | grep -E "ERROR|CRITICAL|Failed" || echo "   오류 없음"

echo "=================================="
echo "진단 완료!"
echo ""
echo "📌 추가 명령어:"
echo "   로그 확인: sudo journalctl -u llm-classroom -f"
echo "   서비스 재시작: sudo systemctl restart llm-classroom"
echo "   수동 테스트: cd /home/ubuntu/llm_classroom_proto3 && source venv/bin/activate && python main.py"