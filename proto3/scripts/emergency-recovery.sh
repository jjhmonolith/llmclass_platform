#!/bin/bash
# emergency-recovery.sh - 긴급 복구 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}🚨 LLM Classroom Proto3 긴급 복구 모드${NC}"
echo "================================================"

PROJECT_DIR="/home/ubuntu/llm_classroom_proto3"
cd "$PROJECT_DIR"

# 1. 모든 관련 프로세스 종료
echo -e "${BLUE}1. 모든 프로세스 강제 종료...${NC}"
sudo systemctl stop llm-classroom 2>/dev/null || true
sudo pkill -f gunicorn 2>/dev/null || true
sudo pkill -f uvicorn 2>/dev/null || true
sudo pkill -f "python.*main.py" 2>/dev/null || true

# 포트 8080 사용 프로세스 강제 종료
if sudo lsof -i :8080 > /dev/null 2>&1; then
    echo -e "${YELLOW}   포트 8080 사용 프로세스 강제 종료 중...${NC}"
    sudo lsof -ti :8080 | xargs -r sudo kill -9
fi

sleep 3
echo -e "${GREEN}   ✅ 프로세스 정리 완료${NC}"

# 2. 로그 백업
echo -e "${BLUE}2. 오류 로그 백업 중...${NC}"
CRASH_LOG="crash-log-$(date +%Y%m%d-%H%M%S).log"
sudo journalctl -u llm-classroom --no-pager > "$CRASH_LOG"
echo -e "${GREEN}   ✅ 로그 저장: $CRASH_LOG${NC}"

# 3. 환경 상태 점검
echo -e "${BLUE}3. 환경 상태 점검...${NC}"

# 디스크 공간 확인
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 90 ]; then
    echo -e "${RED}   ❌ 디스크 공간 부족: ${disk_usage}%${NC}"
    echo "   로그 파일 정리를 권장합니다"
else
    echo -e "${GREEN}   ✅ 디스크 공간: ${disk_usage}%${NC}"
fi

# 메모리 확인
memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ "$memory_usage" -gt 90 ]; then
    echo -e "${YELLOW}   ⚠️  메모리 사용량: ${memory_usage}%${NC}"
else
    echo -e "${GREEN}   ✅ 메모리 사용량: ${memory_usage}%${NC}"
fi

# 4. 가상환경 재구성
echo -e "${BLUE}4. 가상환경 재구성...${NC}"

# 기존 가상환경 백업 및 재생성
if [ -d "venv" ]; then
    mv venv "venv-backup-$(date +%Y%m%d-%H%M%S)"
fi

python3 -m venv venv
source venv/bin/activate

# 의존성 재설치
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${GREEN}   ✅ 가상환경 재구성 완료${NC}"

# 5. 설정 파일 검증
echo -e "${BLUE}5. 설정 파일 검증...${NC}"

# .env 파일 확인
if [ ! -f .env ]; then
    echo -e "${RED}   ❌ .env 파일이 없습니다${NC}"
    
    # 백업에서 복원 시도
    latest_backup=$(find . -name ".env.backup*" -type f | sort | tail -1)
    if [ -n "$latest_backup" ]; then
        cp "$latest_backup" .env
        echo -e "${YELLOW}   ⚠️  백업에서 .env 복원: $latest_backup${NC}"
    else
        echo "OPENAI_API_KEY=sk-proj-YOUR_API_KEY_HERE" > .env
        echo -e "${RED}   ❗ .env 템플릿을 생성했습니다. API 키를 설정하세요!${NC}"
        echo "   nano .env"
        exit 1
    fi
fi

# API 키 형식 확인
if ! grep -q "OPENAI_API_KEY=sk-" .env; then
    echo -e "${RED}   ❌ OPENAI_API_KEY 형식이 올바르지 않습니다${NC}"
    echo "   .env 파일을 확인하세요: nano .env"
    exit 1
fi

echo -e "${GREEN}   ✅ 설정 파일 검증 완료${NC}"

# 6. 수동 테스트 모드
echo -e "${BLUE}6. 수동 테스트 모드 시작...${NC}"
echo -e "${YELLOW}   Python 서버를 수동으로 실행합니다${NC}"
echo -e "${YELLOW}   정상 작동 확인 후 Ctrl+C로 종료하세요${NC}"
echo ""

read -p "수동 테스트를 시작하시겠습니까? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}   테스트 서버 시작 중...${NC}"
    echo "   접속 주소: http://localhost:8080"
    echo "   종료: Ctrl+C"
    echo ""
    
    # 환경변수 로드 및 서버 실행
    export $(cat .env | xargs)
    python main.py
    
    echo ""
    echo -e "${GREEN}수동 테스트 완료!${NC}"
fi

# 7. 서비스 복구
echo -e "${BLUE}7. 서비스 모드로 복구...${NC}"

# 서비스 파일 확인/수정
if [ -f llm-classroom.service ]; then
    sudo cp llm-classroom.service /etc/systemd/system/
    sudo systemctl daemon-reload
fi

# 서비스 시작
sudo systemctl enable llm-classroom
sudo systemctl start llm-classroom

sleep 5

# 상태 확인
if sudo systemctl is-active --quiet llm-classroom; then
    echo -e "${GREEN}   ✅ 서비스 복구 성공!${NC}"
else
    echo -e "${RED}   ❌ 서비스 복구 실패${NC}"
    echo "   로그 확인: sudo journalctl -u llm-classroom -n 20"
    exit 1
fi

# 8. 최종 검증
echo -e "${BLUE}8. 최종 검증...${NC}"

# API 테스트
sleep 3
if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ API 정상 작동${NC}"
else
    echo -e "${RED}   ❌ API 접근 실패${NC}"
fi

# 9. 복구 완료
echo "================================================"
echo -e "${GREEN}🎉 긴급 복구 완료!${NC}"
echo ""
echo "📊 복구 정보:"
echo "   - 서비스 상태: $(sudo systemctl is-active llm-classroom)"
echo "   - 포트 상태: $(sudo lsof -i :8080 > /dev/null 2>&1 && echo "사용 중" || echo "미사용")"
echo "   - 로그 백업: $CRASH_LOG"
echo ""
echo "🔍 권장 사항:"
echo "   1. 브라우저에서 접속 테스트"
echo "   2. 로그 모니터링: sudo journalctl -u llm-classroom -f"
echo "   3. 정기 백업 설정 확인"
echo ""
echo "📞 추가 지원이 필요한 경우:"
echo "   - 오류 로그: $CRASH_LOG"
echo "   - 문제 해결 가이드: cat TROUBLESHOOTING.md"