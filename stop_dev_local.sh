#!/bin/bash

echo "🛑 LLM Classroom 로컬 개발 서버 종료"
echo "====================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# PID 파일로 종료
echo "📋 PID 파일 기반 종료 시도..."
for pid_file in logs/*.pid; do
    if [ -f "$pid_file" ]; then
        PID=$(cat "$pid_file")
        SERVICE=$(basename "$pid_file" .pid | tr '_' ' ')
        
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID
            echo -e "   ✅ $SERVICE (PID: $PID) ${GREEN}종료됨${NC}"
            rm "$pid_file"
        else
            echo -e "   ⚠️  $SERVICE (PID: $PID) ${YELLOW}이미 종료됨${NC}"
            rm "$pid_file"
        fi
    fi
done

# 포트 기반 종료 (백업)
echo ""
echo "🔍 포트 기반 프로세스 확인..."

kill_port() {
    local port=$1
    local name=$2
    
    PID=$(lsof -ti :$port)
    if [ ! -z "$PID" ]; then
        kill $PID 2>/dev/null
        echo -e "   ✅ $name (포트 $port) ${GREEN}종료됨${NC}"
    else
        echo -e "   ℹ️  $name (포트 $port) ${YELLOW}실행 중 아님${NC}"
    fi
}

kill_port 8003 "Student Hub"
kill_port 8000 "Proto4"
kill_port 8001 "Proto1"
kill_port 8002 "Proto3"

# Python 프로세스 정리
echo ""
echo "🧹 남은 Python 프로세스 정리..."
REMAINING=$(ps aux | grep -E "python.*main.py" | grep -v grep | wc -l)
if [ $REMAINING -gt 0 ]; then
    pkill -f "python.*main.py"
    echo -e "   ✅ ${GREEN}$REMAINING개 프로세스 정리됨${NC}"
else
    echo "   ℹ️  정리할 프로세스 없음"
fi

# 최종 확인
echo ""
echo "📊 최종 상태 확인:"
echo "================"

RUNNING=$(lsof -i :8000-8003 2>/dev/null | grep LISTEN | wc -l)
if [ $RUNNING -eq 0 ]; then
    echo -e "✅ ${GREEN}모든 개발 서버가 종료되었습니다.${NC}"
else
    echo -e "⚠️  ${YELLOW}아직 실행 중인 서비스가 있습니다:${NC}"
    lsof -i :8000-8003 | grep LISTEN
fi

echo ""
echo "🎯 개발 서버 종료 완료!"