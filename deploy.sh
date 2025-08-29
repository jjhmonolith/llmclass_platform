#!/bin/bash

# 🚀 LLM Classroom 통합 관리 시스템 배포 스크립트
# 기존 서비스를 안전하게 새 시스템으로 전환

echo "🔄 LLM Classroom 통합 시스템으로 전환 중..."
echo "================================================"

# 1. 현재 상태 백업
echo "1. 현재 실행 중인 서비스 PID 백업..."
ps aux | grep python | grep main.py | grep -v grep > backup_current_pids.txt
ps aux | grep cloudflared | grep config-llmclass | grep -v grep >> backup_current_pids.txt

# 2. 기존 서비스 안전 종료
echo "2. 기존 서비스 안전 종료 중..."
echo "   Proto4 종료..."
pkill -f "proto4/backend/main.py" 2>/dev/null || true

echo "   Proto1 종료..."
pkill -f "proto1/main.py" 2>/dev/null || true

echo "   Proto3 종료..."  
pkill -f "proto3/main.py" 2>/dev/null || true

echo "   Student Hub 종료..."
pkill -f "student/backend/main.py" 2>/dev/null || true

echo "   터널 종료..."
pkill -f "cloudflared.*config-llmclass" 2>/dev/null || true

# 3초 대기
echo "   프로세스 정리 대기 중... (3초)"
sleep 3

# 3. 새 통합 시스템으로 시작
echo "3. 통합 시스템으로 서비스 시작..."
./llmclass start

# 4. 상태 확인
echo "4. 서비스 상태 확인..."
sleep 5
./llmclass status

echo ""
echo "5. 헬스체크 실행..."
./llmclass health

echo ""
echo "✅ 전환 완료!"
echo ""
echo "이제 다음 명령어로 제어하세요:"
echo "  ./llmclass start    # 시작"
echo "  ./llmclass stop     # 종료"  
echo "  ./llmclass status   # 상태 확인"
echo "  ./llmclass health   # 헬스체크"