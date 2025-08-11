#!/bin/bash

echo "🔄 LLM Classroom Proto4 무중단 업데이트"
echo "====================================="

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 설정
BACKUP_DIR="/Users/jjh_server/llmclass_platform/backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
PROTO4_PATH="/Users/jjh_server/llmclass_platform/proto4"

# 로그 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "logs/update_${TIMESTAMP}.log"
}

# 에러 처리
set -e
trap 'log "❌ 업데이트 실패! 롤백을 진행합니다."; rollback; exit 1' ERR

# 롤백 함수
rollback() {
    log "🔄 롤백 시작..."
    if [ -d "$BACKUP_DIR/proto4_${TIMESTAMP}" ]; then
        rm -rf "$PROTO4_PATH"
        mv "$BACKUP_DIR/proto4_${TIMESTAMP}" "$PROTO4_PATH"
        log "✅ 롤백 완료"
        restart_services
    else
        log "❌ 백업을 찾을 수 없습니다!"
    fi
}

# 서비스 재시작 함수
restart_services() {
    log "🔄 Proto4 서비스 재시작..."
    
    # LaunchAgent 사용 중인지 확인
    if launchctl list | grep com.llmclassroom.proto4 > /dev/null 2>&1; then
        launchctl kickstart -k gui/$UID/com.llmclassroom.proto4
        log "✅ LaunchAgent로 Proto4 재시작"
    else
        # 수동 재시작
        pkill -f "proto4.*main.py" 2>/dev/null || true
        cd "$PROTO4_PATH/backend"
        python3 main.py &
        log "✅ 수동으로 Proto4 재시작"
    fi
    
    # 서비스 시작 대기
    sleep 5
    
    # 헬스체크
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        log "✅ Proto4 서비스 정상 작동 확인"
    else
        log "❌ Proto4 서비스 시작 실패"
        return 1
    fi
}

# 메인 업데이트 로직
main() {
    log "🚀 Proto4 업데이트 시작"
    
    # 1. 사용자 활동 확인
    log "👥 사용자 활동 확인 중..."
    
    CONNECTIONS=$(netstat -an | grep ":8000" | grep ESTABLISHED | wc -l)
    if [ $CONNECTIONS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  현재 $CONNECTIONS명이 Proto4를 사용 중입니다.${NC}"
        echo "계속하시겠습니까? (y/N): "
        read -r CONFIRM
        if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
            log "업데이트 취소됨"
            exit 0
        fi
    fi
    
    # 2. 백업 생성
    log "💾 현재 버전 백업 중..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$PROTO4_PATH" "$BACKUP_DIR/proto4_${TIMESTAMP}"
    log "✅ 백업 완료: $BACKUP_DIR/proto4_${TIMESTAMP}"
    
    # 3. 현재 서비스 중지
    log "🛑 Proto4 서비스 중지 중..."
    if launchctl list | grep com.llmclassroom.proto4 > /dev/null 2>&1; then
        launchctl stop com.llmclassroom.proto4
    fi
    pkill -f "proto4.*main.py" 2>/dev/null || true
    
    # 프로세스 완전 종료 대기
    sleep 3
    
    # 4. Git에서 최신 버전 가져오기
    log "📥 GitHub에서 최신 Proto4 가져오는 중..."
    
    cd /Users/jjh_server/llmclass_platform
    
    # 현재 브랜치 확인
    CURRENT_BRANCH=$(git branch --show-current)
    log "현재 브랜치: $CURRENT_BRANCH"
    
    # 변경사항 stash (있는 경우)
    if ! git diff --quiet; then
        git stash push -m "Auto-stash before proto4 update ${TIMESTAMP}"
        log "로컬 변경사항 임시 저장됨"
    fi
    
    # 최신 변경사항 가져오기
    git fetch origin
    git pull origin $CURRENT_BRANCH
    
    log "✅ 최신 코드 업데이트 완료"
    
    # 5. 의존성 업데이트
    log "📦 의존성 업데이트 중..."
    cd "$PROTO4_PATH"
    if [ -f "backend/requirements.txt" ]; then
        python3 -m pip install -r backend/requirements.txt --upgrade
        log "✅ 의존성 업데이트 완료"
    fi
    
    # 6. 서비스 재시작
    restart_services
    
    # 7. 업데이트 검증
    log "🔍 업데이트 검증 중..."
    
    # API 응답 테스트
    sleep 5
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null)
    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "307" ]; then
        log "✅ HTTP 응답 정상: $HTTP_STATUS"
    else
        log "❌ HTTP 응답 오류: $HTTP_STATUS"
        return 1
    fi
    
    # 외부 접속 테스트
    if curl -s https://socratic.llmclass.org > /dev/null 2>&1; then
        log "✅ 외부 접속 정상"
    else
        log "⚠️  외부 접속 확인 불가 (Cloudflare 지연 가능)"
    fi
    
    # 8. 성공 완료
    log "🎉 Proto4 업데이트 완료!"
    
    # 백업 정리 (7일 이상 된 백업 삭제)
    find "$BACKUP_DIR" -name "proto4_*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
    
    echo ""
    echo -e "${GREEN}✅ Proto4 업데이트 성공!${NC}"
    echo ""
    echo "📊 테스트 URL:"
    echo "  • http://localhost:8000"
    echo "  • https://socratic.llmclass.org"
    echo ""
    echo "📝 업데이트 로그: logs/update_${TIMESTAMP}.log"
    echo "💾 백업 위치: $BACKUP_DIR/proto4_${TIMESTAMP}"
}

# 스크립트 실행
if [ "$1" = "--force" ]; then
    log "강제 업데이트 모드"
else
    echo "Proto4 업데이트를 시작하기 전에 사용자 활동을 확인하는 것을 권장합니다."
    echo "사용자 활동 확인: ./check_user_activity.sh"
    echo ""
    echo "업데이트를 계속하시겠습니까? (y/N): "
    read -r CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        echo "업데이트 취소됨"
        exit 0
    fi
fi

# 로그 디렉토리 생성
mkdir -p logs

# 메인 함수 실행
main

log "업데이트 프로세스 완료"