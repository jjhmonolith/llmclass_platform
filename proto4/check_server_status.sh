#!/bin/bash

echo "🔍 Proto4 서버 상태 체크 중..."
echo ""

# 스크립트 실행 디렉토리 확인
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BACKEND_DIR="${SCRIPT_DIR}/backend"

echo "📁 프로젝트 디렉토리: ${SCRIPT_DIR}"
echo "📁 백엔드 디렉토리: ${BACKEND_DIR}"
echo ""

# 1. 디렉토리 구조 확인
echo "📂 디렉토리 구조 확인:"
if [ -d "${BACKEND_DIR}" ]; then
    echo "  ✅ backend 디렉토리 존재"
    if [ -f "${BACKEND_DIR}/main.py" ]; then
        echo "  ✅ main.py 파일 존재"
    else
        echo "  ❌ main.py 파일 없음"
    fi
else
    echo "  ❌ backend 디렉토리 없음"
fi

if [ -d "${SCRIPT_DIR}/frontend" ]; then
    echo "  ✅ frontend 디렉토리 존재"
    if [ -f "${SCRIPT_DIR}/frontend/index.html" ]; then
        echo "  ✅ index.html 파일 존재"
    else
        echo "  ❌ index.html 파일 없음"
    fi
else
    echo "  ❌ frontend 디렉토리 없음"
fi

echo ""

# 2. 포트 8000 사용 중인 프로세스 확인
echo "🔌 포트 8000 상태 확인:"
PORT_USAGE=$(lsof -i :8000 2>/dev/null)
if [ -n "$PORT_USAGE" ]; then
    echo "  ⚠️  포트 8000이 사용 중입니다:"
    echo "$PORT_USAGE" | while read line; do
        echo "    $line"
    done
else
    echo "  ✅ 포트 8000이 사용 가능합니다"
fi

echo ""

# 3. Proto4 관련 프로세스 확인
echo "🔄 Proto4 프로세스 확인:"
PROTO4_PROCESSES=$(ps aux | grep -E "python.*main.py|uvicorn" | grep -v grep)
if [ -n "$PROTO4_PROCESSES" ]; then
    echo "  📡 실행 중인 Proto4 프로세스:"
    echo "$PROTO4_PROCESSES" | while read line; do
        echo "    $line"
    done
    
    # 프로세스가 올바른 디렉토리에서 실행되는지 확인
    echo ""
    echo "  📍 프로세스 작업 디렉토리 확인:"
    ps aux | grep -E "python.*main.py|uvicorn" | grep -v grep | awk '{print $2}' | while read pid; do
        if [ -n "$pid" ]; then
            CWD=$(lsof -p $pid 2>/dev/null | grep cwd | awk '{print $9}')
            if [ -n "$CWD" ]; then
                echo "    PID $pid: $CWD"
                if [[ "$CWD" == *"$BACKEND_DIR"* ]]; then
                    echo "      ✅ 올바른 디렉토리에서 실행 중"
                else
                    echo "      ❌ 잘못된 디렉토리에서 실행 중"
                fi
            fi
        fi
    done
else
    echo "  ✅ Proto4 프로세스가 실행되지 않음"
fi

echo ""

# 4. 로컬 서버 응답 테스트
echo "🌐 로컬 서버 응답 테스트:"
HTTP_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/proto4_response.txt http://localhost:8000 2>/dev/null)
if [ "$HTTP_RESPONSE" = "200" ]; then
    echo "  ✅ 서버가 정상 응답 중 (HTTP 200)"
    # 응답 내용에서 에러 메시지 확인
    if grep -q "Static files not found" /tmp/proto4_response.txt; then
        echo "  ❌ 정적 파일 에러 발생"
    else
        echo "  ✅ 정적 파일 정상 로드"
    fi
elif [ "$HTTP_RESPONSE" = "000" ]; then
    echo "  ❌ 서버에 연결할 수 없음 (서버 미실행)"
else
    echo "  ⚠️  서버 응답 이상 (HTTP $HTTP_RESPONSE)"
fi

# 임시 파일 정리
rm -f /tmp/proto4_response.txt

echo ""

# 5. 권장 조치사항
echo "📋 권장 조치사항:"
if [ -z "$PROTO4_PROCESSES" ]; then
    echo "  🚀 서버 시작: ./start_server.sh"
elif grep -q "Static files not found" /tmp/proto4_response.txt 2>/dev/null; then
    echo "  🔄 서버 재시작 필요:"
    echo "    1. 기존 프로세스 종료: ps aux | grep python | grep main.py"
    echo "    2. 올바른 디렉토리에서 재시작: cd ${SCRIPT_DIR} && ./start_server.sh"
else
    echo "  ✅ 모든 상태가 정상입니다"
fi

echo ""
echo "🎯 검사 완료!"