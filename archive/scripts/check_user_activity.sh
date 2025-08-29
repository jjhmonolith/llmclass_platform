#!/bin/bash

echo "👥 LLM Classroom 사용자 활동 모니터링"
echo "====================================="

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 현재 시간
echo "🕐 확인 시간: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 네트워크 연결 확인
echo "🌐 현재 네트워크 연결 상태:"
echo "=========================="

check_connections() {
    local port=$1
    local service=$2
    
    # 현재 연결된 클라이언트 수 확인
    CONNECTIONS=$(netstat -an | grep ":$port" | grep ESTABLISHED | wc -l)
    LISTENING=$(lsof -i :$port | grep LISTEN | wc -l)
    
    if [ $LISTENING -gt 0 ]; then
        if [ $CONNECTIONS -gt 0 ]; then
            echo -e "✅ $service (포트 $port): ${GREEN}$CONNECTIONS명 사용 중${NC}"
        else
            echo -e "⚪ $service (포트 $port): ${YELLOW}서비스 실행 중, 사용자 없음${NC}"
        fi
        
        # 연결된 IP 주소 표시 (있는 경우)
        if [ $CONNECTIONS -gt 0 ]; then
            echo "   연결된 클라이언트:"
            netstat -an | grep ":$port" | grep ESTABLISHED | awk '{print "     " $5}' | sed 's/:.*$//' | sort | uniq -c
        fi
    else
        echo -e "❌ $service (포트 $port): ${RED}서비스 중단${NC}"
    fi
}

check_connections 8003 "Student Hub"
check_connections 8000 "Proto4 (Socratic)"
check_connections 8001 "Proto1 (Strategic)"
check_connections 8002 "Proto3 (Fire)"

echo ""

# 2. 최근 HTTP 요청 확인 (로그 기반)
echo "📊 최근 HTTP 활동 (로그 기반):"
echo "============================"

check_recent_activity() {
    local log_file=$1
    local service=$2
    
    if [ -f "$log_file" ]; then
        # 최근 5분간의 HTTP 요청 확인
        RECENT_REQUESTS=$(grep "$(date '+%Y-%m-%d %H:%M')\|$(date -d '1 minute ago' '+%Y-%m-%d %H:%M')\|$(date -d '2 minutes ago' '+%Y-%m-%d %H:%M')\|$(date -d '3 minutes ago' '+%Y-%m-%d %H:%M')\|$(date -d '4 minutes ago' '+%Y-%m-%d %H:%M')" "$log_file" 2>/dev/null | grep -E "GET|POST" | wc -l)
        
        if [ $RECENT_REQUESTS -gt 0 ]; then
            echo -e "🔥 $service: ${GREEN}$RECENT_REQUESTS개 요청 (최근 5분)${NC}"
            # 마지막 요청 시간 표시
            LAST_REQUEST=$(grep -E "GET|POST" "$log_file" 2>/dev/null | tail -1 | cut -d' ' -f1-2)
            if [ ! -z "$LAST_REQUEST" ]; then
                echo "   마지막 요청: $LAST_REQUEST"
            fi
        else
            echo -e "⚪ $service: ${YELLOW}최근 5분간 요청 없음${NC}"
        fi
    else
        echo -e "❓ $service: ${YELLOW}로그 파일 없음${NC}"
    fi
}

# 로그 파일 경로들 확인
check_recent_activity "logs/Student_Hub.log" "Student Hub"
check_recent_activity "logs/Proto4_Socratic.log" "Proto4 (Socratic)"
check_recent_activity "logs/Proto1_Strategic.log" "Proto1 (Strategic)"
check_recent_activity "logs/Proto3_Fire.log" "Proto3 (Fire)"

echo ""

# 3. Cloudflare Analytics (외부 접속 확인)
echo "🌍 외부 접속 추정 (Cloudflare 터널):"
echo "=================================="

if pgrep -f "cloudflared tunnel" > /dev/null; then
    echo -e "✅ ${GREEN}Cloudflare Tunnel 실행 중${NC}"
    echo "   외부 도메인을 통한 접속 가능:"
    echo "   • https://hub.llmclass.org"
    echo "   • https://socratic.llmclass.org"
    echo "   • https://strategic.llmclass.org"
    echo "   • https://fire.llmclass.org"
else
    echo -e "❌ ${RED}Cloudflare Tunnel 중단${NC}"
    echo "   외부 접속 불가 (localhost만 가능)"
fi

echo ""

# 4. 프로세스 리소스 사용량
echo "📈 서비스 리소스 사용량:"
echo "======================"

echo "PID     CPU%  MEM%  서비스"
echo "------------------------"
ps aux | grep -E "python.*main.py" | grep -v grep | while read line; do
    PID=$(echo $line | awk '{print $2}')
    CPU=$(echo $line | awk '{print $3}')
    MEM=$(echo $line | awk '{print $4}')
    COMMAND=$(echo $line | awk '{print $11}')
    
    # 포트별로 서비스 이름 추정
    PORT_INFO=$(lsof -p $PID 2>/dev/null | grep LISTEN | awk '{print $9}' | cut -d: -f2)
    case $PORT_INFO in
        8000) SERVICE="Proto4 (Socratic)" ;;
        8001) SERVICE="Proto1 (Strategic)" ;;
        8002) SERVICE="Proto3 (Fire)" ;;
        8003) SERVICE="Student Hub" ;;
        *) SERVICE="Unknown" ;;
    esac
    
    printf "%-6s %5s %5s  %s\n" "$PID" "$CPU" "$MEM" "$SERVICE"
done

echo ""

# 5. 업데이트 안전성 평가
echo "🔒 업데이트 안전성 평가:"
echo "======================"

TOTAL_CONNECTIONS=$(netstat -an | grep -E ":800[0-3]" | grep ESTABLISHED | wc -l)
RECENT_ACTIVITY=$(find logs -name "*.log" -mmin -5 2>/dev/null | xargs grep -l "GET\|POST" 2>/dev/null | wc -l)

if [ $TOTAL_CONNECTIONS -eq 0 ] && [ $RECENT_ACTIVITY -eq 0 ]; then
    echo -e "✅ ${GREEN}업데이트 안전함${NC}"
    echo "   • 현재 활성 사용자 없음"
    echo "   • 최근 5분간 활동 없음"
elif [ $TOTAL_CONNECTIONS -gt 0 ]; then
    echo -e "⚠️  ${YELLOW}주의 필요${NC}"
    echo "   • 현재 $TOTAL_CONNECTIONS명 연결 중"
    echo "   • 업데이트 전 사용자에게 알림 권장"
else
    echo -e "🟡 ${BLUE}판단 필요${NC}"
    echo "   • 최근 활동 감지됨"
    echo "   • 잠시 대기 후 재확인 권장"
fi

echo ""
echo "💡 추천 행동:"
echo "============"
echo "1. 이 스크립트를 5-10분 간격으로 여러 번 실행"
echo "2. 연속으로 '사용자 없음' 상태 확인"
echo "3. 오프피크 시간 (새벽 2-6시) 업데이트 권장"
echo "4. 업데이트 중 모니터링: watch -n 5 './check_user_activity.sh'"
echo ""