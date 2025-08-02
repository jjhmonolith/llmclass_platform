#!/bin/bash

echo "🚀 LLM Classroom 로컬 개발 서버 시작"
echo "====================================="
echo "⚠️  주의: 이 스크립트는 로컬 개발용입니다."
echo "    Cloudflare Tunnel 없이 localhost에서만 접속 가능합니다."
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 기존 프로세스 확인 및 정리
echo "🔍 기존 프로세스 확인 중..."
EXISTING_PROCESSES=$(lsof -i :8000-8003 2>/dev/null | grep LISTEN | wc -l)
if [ $EXISTING_PROCESSES -gt 0 ]; then
    echo -e "${YELLOW}⚠️  기존 Python 서비스가 실행 중입니다.${NC}"
    echo "   포트 사용 현황:"
    lsof -i :8000-8003 2>/dev/null | grep LISTEN
    echo ""
    echo "   종료하려면 Ctrl+C를 누르고 다음 명령어를 실행하세요:"
    echo "   pkill -f 'python.*main.py'"
    exit 1
fi

# 프로젝트 루트 디렉토리 찾기
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Python 환경 확인
echo "🐍 Python 환경 확인 중..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3가 설치되어 있지 않습니다.${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1)
echo "   ✅ $PYTHON_VERSION"

# 의존성 확인
echo ""
echo "📦 의존성 확인 중..."
check_dependencies() {
    local project=$1
    local path=$2
    
    if [ -f "$path/requirements.txt" ]; then
        echo -n "   $project: "
        if python3 -m pip show fastapi &> /dev/null; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${YELLOW}⚠️  의존성 설치 필요${NC}"
            echo "      실행: cd $path && pip install -r requirements.txt"
        fi
    fi
}

check_dependencies "Student Hub" "student"
check_dependencies "Proto1" "proto1"
check_dependencies "Proto3" "proto3"
check_dependencies "Proto4" "proto4/backend"

# 서비스 시작 함수
start_service() {
    local name=$1
    local port=$2
    local path=$3
    local main_file=$4
    
    echo ""
    echo "🚀 $name 시작 중... (포트 $port)"
    
    cd "$SCRIPT_DIR/$path"
    python3 $main_file > "$SCRIPT_DIR/logs/${name// /_}.log" 2>&1 &
    local PID=$!
    
    # 프로세스 시작 확인
    sleep 2
    if ps -p $PID > /dev/null; then
        echo -e "   ${GREEN}✅ $name 시작됨 (PID: $PID)${NC}"
        echo $PID > "$SCRIPT_DIR/logs/${name// /_}.pid"
    else
        echo -e "   ${RED}❌ $name 시작 실패${NC}"
        echo "   로그 확인: tail -f logs/${name// /_}.log"
    fi
}

# 로그 디렉토리 생성
mkdir -p logs

# 각 서비스 시작
echo ""
echo "📋 서비스 시작 순서:"
echo "   1. Student Hub (포트 8003)"
echo "   2. Proto4 - Socratic (포트 8000)"
echo "   3. Proto1 - Strategic (포트 8001)"
echo "   4. Proto3 - Fire (포트 8002)"

# Student Hub
start_service "Student Hub" 8003 "student/backend" "main.py"

# Proto4
start_service "Proto4 Socratic" 8000 "proto4/backend" "main.py"

# Proto1
start_service "Proto1 Strategic" 8001 "proto1" "main.py"

# Proto3
start_service "Proto3 Fire" 8002 "proto3" "main.py"

# 서비스 시작 대기
echo ""
echo "⏳ 서비스 시작 대기 중..."
sleep 3

# 상태 확인
echo ""
echo "📊 서비스 상태 확인:"
echo "=================="

check_port() {
    local port=$1
    local name=$2
    
    if lsof -i :$port | grep LISTEN > /dev/null 2>&1; then
        echo -e "✅ $name (localhost:$port): ${GREEN}실행 중${NC}"
    else
        echo -e "❌ $name (localhost:$port): ${RED}미실행${NC}"
    fi
}

check_port 8003 "Student Hub"
check_port 8000 "Proto4 (Socratic)"
check_port 8001 "Proto1 (Strategic)"
check_port 8002 "Proto3 (Fire)"

# 사용 안내
echo ""
echo "🎉 로컬 개발 서버 시작 완료!"
echo ""
echo "📍 로컬 접속 주소:"
echo "   • Student Hub: http://localhost:8003"
echo "   • Proto4 (Socratic): http://localhost:8000"
echo "   • Proto1 (Strategic): http://localhost:8001"
echo "   • Proto3 (Fire): http://localhost:8002"
echo ""
echo "📝 유용한 명령어:"
echo "   • 로그 보기: tail -f logs/*.log"
echo "   • 상태 확인: ps aux | grep 'python.*main.py'"
echo "   • 모두 종료: ./stop_dev_local.sh"
echo ""
echo -e "${YELLOW}⚠️  이 서버는 localhost에서만 접속 가능합니다.${NC}"
echo "   외부 접속이 필요하면 맥미니에서 실행하세요."
echo ""

# Ctrl+C 처리
trap 'echo ""; echo "🛑 개발 서버 종료 중..."; pkill -P $$; exit' INT

# 프로세스 유지
echo "💡 종료하려면 Ctrl+C를 누르세요."
wait