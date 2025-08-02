#!/bin/bash

# 서비스 모니터링 및 자동 복구 스크립트
LOG_FILE="/Users/jjh_server/llmclass_platform/logs/monitor.log"
ALERT_LOG="/Users/jjh_server/llmclass_platform/logs/alerts.log"

# 로그 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 서비스 체크 함수
check_service() {
    local port=$1
    local name=$2
    local service_id=$3
    
    # HTTP 응답 확인
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health 2>/dev/null)
    
    if [ "$status" != "200" ]; then
        log "❌ $name (포트 $port) 응답 없음 (HTTP $status)"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $name 서비스 다운!" >> "$ALERT_LOG"
        
        # 서비스 재시작 시도
        log "🔄 $name 서비스 재시작 시도..."
        launchctl kickstart -k gui/$UID/com.llmclassroom.$service_id
        
        # 30초 대기 후 재확인
        sleep 30
        
        status_retry=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health 2>/dev/null)
        if [ "$status_retry" = "200" ]; then
            log "✅ $name 서비스 재시작 성공!"
        else
            log "🚨 $name 서비스 재시작 실패! 수동 확인 필요"
        fi
    else
        log "✅ $name (포트 $port) 정상"
    fi
}

# Cloudflare Tunnel 체크
check_tunnel() {
    if ! pgrep -f "cloudflared tunnel" > /dev/null; then
        log "❌ Cloudflare Tunnel 프로세스 없음"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: Cloudflare Tunnel 다운!" >> "$ALERT_LOG"
        
        # Tunnel 재시작
        log "🔄 Cloudflare Tunnel 재시작 시도..."
        launchctl kickstart -k gui/$UID/com.llmclassroom.cloudflared
    else
        log "✅ Cloudflare Tunnel 정상"
    fi
}

# 메인 모니터링 루프
log "🔍 서비스 모니터링 시작..."

while true; do
    log "===== 헬스체크 시작 ====="
    
    # 각 서비스 체크
    check_service 8003 "Student Hub" "hub"
    check_service 8000 "Proto4 (Socratic)" "proto4"
    check_service 8001 "Proto1 (Strategic)" "proto1"
    check_service 8002 "Proto3 (Fire)" "proto3"
    
    # Cloudflare Tunnel 체크
    check_tunnel
    
    log "===== 헬스체크 완료 ====="
    
    # 5분 대기
    sleep 300
done