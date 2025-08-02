#!/bin/bash

echo "🚀 LLM Classroom 자동 시작 설정 스크립트"
echo "========================================="

# 로그 디렉토리 생성
echo "📁 로그 디렉토리 생성 중..."
mkdir -p /Users/jjh_server/llmclass_platform/logs

# LaunchDaemon 디렉토리 확인
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS_DIR"

# Proto1, Proto3도 나중에 추가할 수 있도록 템플릿 생성
echo "📝 LaunchAgent 파일 생성 중..."

# 기존 서비스 중지 (있는 경우)
echo "🛑 기존 서비스 중지 중..."
launchctl unload "$LAUNCH_AGENTS_DIR/com.llmclassroom.hub.plist" 2>/dev/null
launchctl unload "$LAUNCH_AGENTS_DIR/com.llmclassroom.proto4.plist" 2>/dev/null
launchctl unload "$LAUNCH_AGENTS_DIR/com.llmclassroom.cloudflared.plist" 2>/dev/null

# plist 파일 복사
echo "📋 설정 파일 복사 중..."
cp launchd/com.llmclassroom.hub.plist "$LAUNCH_AGENTS_DIR/"
cp launchd/com.llmclassroom.proto4.plist "$LAUNCH_AGENTS_DIR/"
cp launchd/com.llmclassroom.cloudflared.plist "$LAUNCH_AGENTS_DIR/"

# Proto1과 Proto3 plist 생성
cat > "$LAUNCH_AGENTS_DIR/com.llmclassroom.proto1.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.llmclassroom.proto1</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/Users/jjh_server/llmclass_platform/proto1/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/jjh_server/llmclass_platform/proto1</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/jjh_server/llmclass_platform/logs/proto1.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/jjh_server/llmclass_platform/logs/proto1.error.log</string>
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
EOF

cat > "$LAUNCH_AGENTS_DIR/com.llmclassroom.proto3.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.llmclassroom.proto3</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/Users/jjh_server/llmclass_platform/proto3/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/jjh_server/llmclass_platform/proto3</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/jjh_server/llmclass_platform/logs/proto3.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/jjh_server/llmclass_platform/logs/proto3.error.log</string>
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
EOF

# 서비스 로드
echo "🔄 서비스 로드 중..."
launchctl load "$LAUNCH_AGENTS_DIR/com.llmclassroom.hub.plist"
launchctl load "$LAUNCH_AGENTS_DIR/com.llmclassroom.proto1.plist"
launchctl load "$LAUNCH_AGENTS_DIR/com.llmclassroom.proto3.plist"
launchctl load "$LAUNCH_AGENTS_DIR/com.llmclassroom.proto4.plist"
launchctl load "$LAUNCH_AGENTS_DIR/com.llmclassroom.cloudflared.plist"

# 상태 확인
echo ""
echo "✅ 서비스 상태 확인:"
echo "-------------------"
launchctl list | grep com.llmclassroom

echo ""
echo "📊 포트 확인 (잠시 후):"
sleep 5
lsof -i :8000-8003 | grep LISTEN

echo ""
echo "✅ 자동 시작 설정 완료!"
echo ""
echo "📝 유용한 명령어:"
echo "  • 서비스 상태 확인: launchctl list | grep com.llmclassroom"
echo "  • 서비스 중지: launchctl unload ~/Library/LaunchAgents/com.llmclassroom.*.plist"
echo "  • 서비스 시작: launchctl load ~/Library/LaunchAgents/com.llmclassroom.*.plist"
echo "  • 로그 확인: tail -f logs/*.log"
echo ""
echo "🔧 절전 모드 비활성화를 원하시면 다음 명령을 실행하세요:"
echo "  sudo pmset -a sleep 0"