#!/bin/bash

echo "🚀 모든 LLM Classroom 서비스 시작 중..."
echo ""

# 기존 프로세스 확인 및 정리
echo "🔍 기존 프로세스 확인 중..."
EXISTING_PROCESSES=$(lsof -i :8000-8003 2>/dev/null | grep python3 | wc -l)
if [ $EXISTING_PROCESSES -gt 0 ]; then
    echo "⚠️  기존 Python 서비스가 실행 중입니다. 종료 후 다시 시작하세요."
    echo "   종료 방법: 각 터미널에서 Ctrl+C 또는 다음 명령어 실행:"
    echo "   sudo lsof -ti :8000-8003 | xargs kill -9"
    echo ""
fi

# Hub - Service Selector (포트 8003)
echo "🎯 Hub (서비스 허브) 시작 중... (포트 8003)"
cd /Users/jjh_server/llmclass_platform/llm_classroom_hub/backend
python3 main.py &
HUB_PID=$!
echo "✅ Hub 시작됨 (PID: $HUB_PID)"

# 잠시 대기
sleep 2

# Proto4 - Socratic AI (포트 8000)
echo "📚 Proto4 (Socratic AI) 시작 중... (포트 8000)"
cd /Users/jjh_server/llmclass_platform/llm_classroom_proto4/backend
python3 main.py &
PROTO4_PID=$!
echo "✅ Proto4 시작됨 (PID: $PROTO4_PID)"

# 잠시 대기
sleep 2

# Proto1 - Strategic Learning (포트 8001)
echo "📖 Proto1 (Strategic Learning) 시작 중... (포트 8001)"
cd /Users/jjh_server/llmclass_platform/llm_classroom_proto1
python3 main.py &
PROTO1_PID=$!
echo "✅ Proto1 시작됨 (PID: $PROTO1_PID)"

# 잠시 대기
sleep 2

# Proto3 - Fire (RTCF) (포트 8002)
echo "🔥 Proto3 (Fire - RTCF) 시작 중... (포트 8002)"
cd /Users/jjh_server/llmclass_platform/llm_classroom_proto3
python3 main.py &
PROTO3_PID=$!
echo "✅ Proto3 시작됨 (PID: $PROTO3_PID)"

# 잠시 대기 (모든 서버 시작 대기)
sleep 3

# Cloudflare Tunnel 시작
echo "🌐 Cloudflare Tunnel 시작 중..."
cloudflared tunnel run a2f0f49b-254f-4c76-a6bb-a6aa266dd3d9 &
TUNNEL_PID=$!
echo "✅ Cloudflare Tunnel 시작됨 (PID: $TUNNEL_PID)"

echo ""
echo "🎉 모든 서비스가 시작되었습니다!"
echo ""
echo "📍 로컬 접속 주소:"
echo "   • Hub (서비스 허브):     http://localhost:8003"
echo "   • Proto4 (Socratic AI): http://localhost:8000"
echo "   • Proto1 (Strategic):   http://localhost:8001"
echo "   • Proto3 (Fire):        http://localhost:8002"
echo ""
echo "🌍 외부 접속 주소:"
echo "   • Hub (서비스 허브):     https://hub.llmclass.org"
echo "   • Proto4 (Socratic AI): https://socratic.llmclass.org"
echo "   • Proto1 (Strategic):   https://strategic.llmclass.org"
echo "   • Proto3 (Fire):        https://fire.llmclass.org"
echo ""
echo "📊 서비스 상태 확인: ./check_services.sh"
echo "⚠️  모든 서비스를 중지하려면 이 터미널에서 Ctrl+C를 누르세요"
echo ""

# PID 파일에 저장 (나중에 종료용)
echo $HUB_PID > /tmp/llm_classroom_hub.pid
echo $PROTO4_PID > /tmp/llm_classroom_proto4.pid
echo $PROTO1_PID > /tmp/llm_classroom_proto1.pid
echo $PROTO3_PID > /tmp/llm_classroom_proto3.pid
echo $TUNNEL_PID > /tmp/llm_classroom_tunnel.pid

# 모든 서비스가 정상 시작되었는지 확인
echo "🔍 서비스 시작 확인 중..."
sleep 5

# 각 서비스 상태 체크
check_service() {
    local port=$1
    local name=$2
    local status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port 2>/dev/null)
    if [ "$status" = "200" ] || [ "$status" = "307" ] || [ "$status" = "404" ]; then
        echo "✅ $name (포트 $port): 정상"
    else
        echo "❌ $name (포트 $port): 오류 (HTTP $status)"
    fi
}

check_service 8003 "Hub (서비스 허브)"
check_service 8000 "Proto4 (Socratic)"
check_service 8001 "Proto1 (Strategic)"
check_service 8002 "Proto3 (Fire)"

echo ""
echo "📝 DNS 설정 확인:"
echo "   Cloudflare에서 다음 CNAME 레코드들을 추가하세요:"
echo "   • hub → a2f0f49b-254f-4c76-a6bb-a6aa266dd3d9.cfargotunnel.com"
echo "   • strategic → a2f0f49b-254f-4c76-a6bb-a6aa266dd3d9.cfargotunnel.com"
echo "   • fire → a2f0f49b-254f-4c76-a6bb-a6aa266dd3d9.cfargotunnel.com"
echo ""

# 무한 대기 (사용자가 Ctrl+C로 종료할 때까지)
trap 'echo ""; echo "🛑 모든 서비스 종료 중..."; kill $HUB_PID $PROTO4_PID $PROTO1_PID $PROTO3_PID $TUNNEL_PID 2>/dev/null; echo "✅ 모든 서비스가 종료되었습니다."; exit' INT
wait