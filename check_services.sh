#!/bin/bash

echo "📊 LLM Classroom 서비스 상태 확인"
echo "=================================="
echo ""

# 실행 중인 Python 서비스 확인
echo "🔍 실행 중인 Python 서비스:"
PYTHON_SERVICES=$(lsof -i :8000-8003 2>/dev/null | grep python3)
if [ -z "$PYTHON_SERVICES" ]; then
    echo "   ❌ 실행 중인 Python 서비스가 없습니다."
else
    echo "$PYTHON_SERVICES" | awk '{print "   ✅ 포트 " substr($9, index($9, ":")+1) ": PID " $2}'
fi
echo ""

# Cloudflare Tunnel 상태 확인
echo "🌐 Cloudflare Tunnel 상태:"
TUNNEL_STATUS=$(ps aux | grep cloudflared | grep -v grep)
if [ -z "$TUNNEL_STATUS" ]; then
    echo "   ❌ Cloudflare Tunnel이 실행되지 않았습니다."
else
    echo "   ✅ Cloudflare Tunnel 실행 중"
fi
echo ""

# 각 서비스 HTTP 응답 확인
echo "🌍 서비스 응답 확인:"

check_service() {
    local port=$1
    local name=$2
    local domain=$3
    
    # 로컬 접속 확인
    local local_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port 2>/dev/null)
    if [ "$local_status" = "200" ] || [ "$local_status" = "307" ] || [ "$local_status" = "404" ]; then
        echo "   ✅ $name (localhost:$port): HTTP $local_status"
    else
        echo "   ❌ $name (localhost:$port): HTTP $local_status 또는 연결 불가"
    fi
    
    # 외부 도메인 확인 (간단한 ping 테스트)
    if [ -n "$domain" ]; then
        local domain_status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://$domain 2>/dev/null)
        if [ "$domain_status" = "200" ] || [ "$domain_status" = "307" ] || [ "$domain_status" = "404" ]; then
            echo "   ✅ $name (https://$domain): HTTP $domain_status"
        else
            echo "   ⏳ $name (https://$domain): 확인 중... (DNS 전파 대기 중일 수 있음)"
        fi
    fi
    echo ""
}

check_service 8003 "Hub (서비스 허브)" "hub.llmclass.org"
check_service 8000 "Proto4 (Socratic AI)" "socratic.llmclass.org"
check_service 8001 "Proto1 (Strategic)" "strategic.llmclass.org"
check_service 8002 "Proto3 (Fire)" "fire.llmclass.org"

# 포트 사용 현황
echo "🔌 포트 사용 현황:"
lsof -i :8000-8099 2>/dev/null | grep LISTEN | awk '{print "   포트 " substr($9, index($9, ":")+1) ": " $1 " (PID " $2 ")"}'
echo ""

# 메모리 사용량
echo "💾 Python 프로세스 메모리 사용량:"
ps aux | grep python3 | grep -v grep | grep -E "(8000|8001|8002|8003)" | awk '{print "   PID " $2 ": " $4 "% 메모리, " $3 "% CPU - " $11}'
echo ""

# DNS 설정 확인 안내
echo "📝 DNS 설정 상태:"
echo "   Cloudflare에서 다음 CNAME 레코드들이 설정되어 있는지 확인하세요:"
echo "   • socratic → a2f0f49b-254f-4c76-a6bb-a6aa266dd3d9.cfargotunnel.com ✅"
echo "   • hub → a2f0f49b-254f-4c76-a6bb-a6aa266dd3d9.cfargotunnel.com"
echo "   • strategic → a2f0f49b-254f-4c76-a6bb-a6aa266dd3d9.cfargotunnel.com"
echo "   • fire → a2f0f49b-254f-4c76-a6bb-a6aa266dd3d9.cfargotunnel.com"
echo ""

echo "🔄 새로고침하려면 이 스크립트를 다시 실행하세요: ./check_services.sh"