#!/bin/bash

# Setup script for macOS auto-start services
# This script helps configure launchd services for the platform

set -e

USER_HOME="$HOME"
USERNAME="$(whoami)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHD_DIR="$USER_HOME/Library/LaunchAgents"

echo "🚀 LLM Class Platform Auto-Start Setup"
echo "======================================"
echo "User: $USERNAME"
echo "Home: $USER_HOME"
echo "Project: $PROJECT_DIR"
echo ""

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p "$LAUNCHD_DIR"
mkdir -p "$PROJECT_DIR/logs"

# Function to replace placeholders in files
replace_placeholders() {
    local file="$1"
    sed -i '' "s|YOUR_USERNAME|$USERNAME|g" "$file"
    sed -i '' "s|/Users/YOUR_USERNAME/Documents/llmclass_platform|$PROJECT_DIR|g" "$file"
}

# Setup Docker services
echo ""
echo "🐳 Setting up Docker services auto-start..."
DOCKER_SERVICE_FILE="$LAUNCHD_DIR/com.llmclass.platform.services.plist"

if [ -f "$DOCKER_SERVICE_FILE" ]; then
    echo "⚠️  Service file already exists: $DOCKER_SERVICE_FILE"
    echo -n "Replace it? (y/N): "
    read -r REPLACE
    if [ "$REPLACE" != "y" ] && [ "$REPLACE" != "Y" ]; then
        echo "Skipping Docker services setup"
    else
        cp "docker-services.plist.example" "$DOCKER_SERVICE_FILE"
        replace_placeholders "$DOCKER_SERVICE_FILE"
        echo "✅ Docker services configuration updated"
    fi
else
    cp "docker-services.plist.example" "$DOCKER_SERVICE_FILE"
    replace_placeholders "$DOCKER_SERVICE_FILE"
    echo "✅ Docker services configuration created"
fi

# Setup Watchdog
echo ""
echo "🐕 Setting up services watchdog..."
WATCHDOG_SERVICE_FILE="$LAUNCHD_DIR/com.llmclass.platform.watchdog.plist"

if [ -f "$WATCHDOG_SERVICE_FILE" ]; then
    echo "⚠️  Watchdog file already exists: $WATCHDOG_SERVICE_FILE"
    echo -n "Replace it? (y/N): "
    read -r REPLACE
    if [ "$REPLACE" != "y" ] && [ "$REPLACE" != "Y" ]; then
        echo "Skipping watchdog setup"
    else
        cp "docker-watchdog.plist.example" "$WATCHDOG_SERVICE_FILE"
        replace_placeholders "$WATCHDOG_SERVICE_FILE"
        echo "✅ Watchdog configuration updated"
    fi
else
    cp "docker-watchdog.plist.example" "$WATCHDOG_SERVICE_FILE"
    replace_placeholders "$WATCHDOG_SERVICE_FILE"
    echo "✅ Watchdog configuration created"
fi

# Setup Cloudflare Tunnel (if tunnel.yml exists)
echo ""
echo "🌐 Checking Cloudflare Tunnel configuration..."
TUNNEL_CONFIG="$PROJECT_DIR/cloudflared/tunnel.yml"
TUNNEL_SERVICE_FILE="$LAUNCHD_DIR/com.cloudflare.cloudflared.llmclass.plist"

if [ -f "$TUNNEL_CONFIG" ]; then
    echo "✅ Tunnel configuration found"
    
    if [ -f "$TUNNEL_SERVICE_FILE" ]; then
        echo "⚠️  Tunnel service file already exists"
        echo -n "Replace it? (y/N): "
        read -r REPLACE
        if [ "$REPLACE" = "y" ] || [ "$REPLACE" = "Y" ]; then
            cp "../cloudflared/launchd.plist.example" "$TUNNEL_SERVICE_FILE"
            replace_placeholders "$TUNNEL_SERVICE_FILE"
            echo "✅ Tunnel service configuration updated"
        fi
    else
        cp "../cloudflared/launchd.plist.example" "$TUNNEL_SERVICE_FILE"
        replace_placeholders "$TUNNEL_SERVICE_FILE"
        echo "✅ Tunnel service configuration created"
    fi
else
    echo "⚠️  No tunnel configuration found (cloudflared/tunnel.yml)"
    echo "   Run 'make tunnel-setup' first if you want Cloudflare Tunnel"
fi

# Check prerequisites
echo ""
echo "🔍 Checking prerequisites..."

# Check Docker
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker is installed"
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker is running"
    else
        echo "⚠️  Docker is not running - services will fail to start"
    fi
else
    echo "❌ Docker is not installed!"
    echo "   Install Docker Desktop before proceeding"
fi

# Check production environment
if [ -f "$PROJECT_DIR/.env.prod" ]; then
    echo "✅ Production environment file exists"
else
    echo "⚠️  Production environment file not found"
    echo "   Create .env.prod before starting services"
fi

# Load services
echo ""
echo "🔄 Loading services..."

# Function to load service
load_service() {
    local service_file="$1"
    local service_name="$2"
    
    if [ -f "$service_file" ]; then
        echo "Loading $service_name..."
        if launchctl load "$service_file" 2>/dev/null; then
            echo "✅ $service_name loaded successfully"
        else
            echo "⚠️  $service_name may already be loaded"
        fi
    fi
}

# Load Docker services
load_service "$DOCKER_SERVICE_FILE" "Docker services"

# Load Watchdog
load_service "$WATCHDOG_SERVICE_FILE" "Services watchdog"

# Load Cloudflare Tunnel (if exists)
if [ -f "$TUNNEL_SERVICE_FILE" ]; then
    load_service "$TUNNEL_SERVICE_FILE" "Cloudflare Tunnel"
fi

# Show status
echo ""
echo "📊 Service Status:"
launchctl list | grep -E "(llmclass|cloudflared)" || echo "No services found"

echo ""
echo "🎉 Auto-start setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Make sure Docker Desktop starts on login"
echo "2. Verify .env.prod configuration"
echo "3. Test services: make status ENV=prod"
echo "4. Reboot to test auto-start"
echo ""
echo "🔧 Management commands:"
echo "   # Check service status"
echo "   launchctl list | grep llmclass"
echo ""
echo "   # Start/stop services manually"
echo "   launchctl start com.llmclass.platform.services"
echo "   launchctl stop com.llmclass.platform.services"
echo ""
echo "   # View logs"
echo "   tail -f $PROJECT_DIR/logs/services.log"
echo "   tail -f $PROJECT_DIR/logs/watchdog.log"
echo ""
echo "   # Unload services (disable auto-start)"
echo "   launchctl unload $DOCKER_SERVICE_FILE"
echo "   launchctl unload $WATCHDOG_SERVICE_FILE"