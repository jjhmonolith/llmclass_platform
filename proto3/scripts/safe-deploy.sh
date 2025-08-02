#!/bin/bash
# safe-deploy.sh - 안전한 배포 및 업데이트 스크립트

set -e  # 오류 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 프로젝트 경로
PROJECT_DIR="/home/ubuntu/llm_classroom_proto3"

echo -e "${BLUE}🔄 LLM Classroom Proto3 안전한 배포 시작...${NC}"
echo "================================================"

# 현재 디렉토리 확인
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ 프로젝트 디렉토리를 찾을 수 없습니다: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# 1. 백업 생성
echo -e "${BLUE}1. 설정 백업 중...${NC}"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backup_$BACKUP_DATE"
mkdir -p "$BACKUP_DIR"

# .env 백업
if [ -f .env ]; then
    cp .env "$BACKUP_DIR/.env.backup"
    echo -e "${GREEN}   ✅ .env 파일 백업 완료${NC}"
else
    echo -e "${YELLOW}   ⚠️  .env 파일이 없습니다${NC}"
fi

# 서비스 설정 백업
if [ -f /etc/systemd/system/llm-classroom.service ]; then
    sudo cp /etc/systemd/system/llm-classroom.service "$BACKUP_DIR/llm-classroom.service.backup"
    sudo chown ubuntu:ubuntu "$BACKUP_DIR/llm-classroom.service.backup"
    echo -e "${GREEN}   ✅ 서비스 설정 백업 완료${NC}"
fi

# 2. 현재 서비스 상태 확인
echo -e "${BLUE}2. 현재 서비스 상태 확인...${NC}"
if sudo systemctl is-active --quiet llm-classroom; then
    echo -e "${GREEN}   ✅ 서비스 실행 중${NC}"
    SERVICE_WAS_RUNNING=true
else
    echo -e "${YELLOW}   ⚠️  서비스 중지됨${NC}"
    SERVICE_WAS_RUNNING=false
fi

# 3. Git 상태 확인
echo -e "${BLUE}3. Git 상태 확인...${NC}"
if ! git status > /dev/null 2>&1; then
    echo -e "${RED}   ❌ Git 저장소가 아닙니다${NC}"
    exit 1
fi

# 변경사항이 있는지 확인
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}   ⚠️  로컬 변경사항이 있습니다. 백업 중...${NC}"
    git stash push -m "auto-backup-before-deploy-$BACKUP_DATE"
fi

# 4. 코드 업데이트
echo -e "${BLUE}4. 코드 업데이트 중...${NC}"
git fetch origin
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})

if [ $LOCAL = $REMOTE ]; then
    echo -e "${GREEN}   ✅ 이미 최신 버전입니다${NC}"
else
    echo -e "${YELLOW}   📥 새로운 업데이트 적용 중...${NC}"
    git pull origin main
    echo -e "${GREEN}   ✅ 코드 업데이트 완료${NC}"
fi

# 5. 환경변수 확인 및 복원
echo -e "${BLUE}5. 환경변수 확인...${NC}"
if [ ! -f .env ]; then
    if [ -f "$BACKUP_DIR/.env.backup" ]; then
        echo -e "${YELLOW}   ⚠️  .env 파일이 없습니다. 백업에서 복원합니다${NC}"
        cp "$BACKUP_DIR/.env.backup" .env
    elif [ -f .env.example ]; then
        echo -e "${YELLOW}   ⚠️  .env 파일이 없습니다. .env.example을 복사합니다${NC}"
        cp .env.example .env
        echo -e "${RED}   ❗ .env 파일에 실제 API 키를 설정해주세요!${NC}"
        read -p "   지금 설정하시겠습니까? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nano .env
        fi
    else
        echo -e "${RED}   ❌ .env 파일을 찾을 수 없습니다${NC}"
        echo "   수동으로 생성해주세요: nano .env"
        exit 1
    fi
fi

# API 키 확인
if ! grep -q "OPENAI_API_KEY=sk-" .env; then
    echo -e "${RED}   ❌ OPENAI_API_KEY가 올바르지 않습니다${NC}"
    echo "   .env 파일을 확인해주세요"
    exit 1
fi

echo -e "${GREEN}   ✅ 환경변수 설정 확인됨${NC}"

# 6. 가상환경 및 의존성 업데이트
echo -e "${BLUE}6. 가상환경 및 의존성 업데이트...${NC}"

# 가상환경 확인/생성
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}   📦 가상환경 생성 중...${NC}"
    python3 -m venv venv
fi

# 가상환경 활성화 및 의존성 설치
source venv/bin/activate
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1

# 필수 패키지 확인
if ! pip list | grep -q gunicorn; then
    echo -e "${YELLOW}   📦 gunicorn 설치 중...${NC}"
    pip install gunicorn
fi

echo -e "${GREEN}   ✅ 의존성 업데이트 완료${NC}"

# 7. 서비스 설정 업데이트
echo -e "${BLUE}7. 서비스 설정 업데이트...${NC}"
if [ -f llm-classroom.service ]; then
    sudo cp llm-classroom.service /etc/systemd/system/
    sudo systemctl daemon-reload
    echo -e "${GREEN}   ✅ 서비스 설정 업데이트 완료${NC}"
fi

# 8. 서비스 재시작
echo -e "${BLUE}8. 서비스 재시작...${NC}"

# 기존 프로세스 정리
if sudo lsof -i :8080 > /dev/null 2>&1; then
    echo -e "${YELLOW}   🧹 기존 프로세스 정리 중...${NC}"
    sudo systemctl stop llm-classroom 2>/dev/null || true
    sleep 2
    
    # 강제 종료가 필요한 경우
    if sudo lsof -i :8080 > /dev/null 2>&1; then
        sudo pkill -f gunicorn || true
        sudo pkill -f uvicorn || true
        sleep 2
    fi
fi

# 서비스 시작
sudo systemctl start llm-classroom
sleep 3

# 9. 상태 확인
echo -e "${BLUE}9. 서비스 상태 확인...${NC}"

# 서비스 상태
if sudo systemctl is-active --quiet llm-classroom; then
    echo -e "${GREEN}   ✅ 서비스 실행 중${NC}"
else
    echo -e "${RED}   ❌ 서비스 시작 실패${NC}"
    echo "   로그 확인: sudo journalctl -u llm-classroom -n 20"
    exit 1
fi

# 포트 확인
sleep 2
if sudo lsof -i :8080 > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ 포트 8080 정상 사용 중${NC}"
else
    echo -e "${RED}   ❌ 포트 8080이 사용되지 않습니다${NC}"
fi

# 10. API 테스트
echo -e "${BLUE}10. API 기능 테스트...${NC}"
sleep 3

# 헬스체크
if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ 헬스체크 통과${NC}"
else
    echo -e "${RED}   ❌ 헬스체크 실패${NC}"
fi

# OneShot API 테스트
if curl -s -X POST http://localhost:8080/api/test-oneshot > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ OneShot API 테스트 통과${NC}"
else
    echo -e "${YELLOW}   ⚠️  OneShot API 테스트 실패 (네트워크 이슈일 수 있음)${NC}"
fi

# 11. Nginx 확인
echo -e "${BLUE}11. Nginx 상태 확인...${NC}"
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}   ✅ Nginx 실행 중${NC}"
else
    echo -e "${YELLOW}   ⚠️  Nginx 중지됨. 재시작 중...${NC}"
    sudo systemctl start nginx
fi

# 12. 정리
echo -e "${BLUE}12. 배포 완료!${NC}"
echo "================================================"
echo -e "${GREEN}✅ 배포가 성공적으로 완료되었습니다!${NC}"
echo ""
echo "📊 배포 정보:"
echo "   - 백업 위치: $PROJECT_DIR/$BACKUP_DIR"
echo "   - 서비스 상태: $(sudo systemctl is-active llm-classroom)"
echo "   - 실행 중인 워커: $(sudo lsof -i :8080 | grep -c LISTEN || echo 0)"
echo ""
echo "🔗 접속 정보:"
echo "   - 로컬: http://localhost:8080"
echo "   - 외부: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'YOUR-EC2-IP')"
echo ""
echo "📌 유용한 명령어:"
echo "   - 로그 확인: sudo journalctl -u llm-classroom -f"
echo "   - 상태 확인: ./scripts/quick-diagnose.sh"
echo "   - 문제 해결: cat TROUBLESHOOTING.md"

# 오래된 백업 정리 (7일 이상)
find . -name "backup_*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

echo ""
echo -e "${GREEN}🎉 Happy Coding!${NC}"