#!/bin/bash

# Docker Services Watchdog Script
# Monitors and restarts Docker services if they fail

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/logs/watchdog.log"
ENV_FILE="$PROJECT_DIR/.env.prod"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "🐕 Watchdog check starting..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log "❌ Docker is not running - cannot check services"
    exit 1
fi

log "✅ Docker is running"

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    log "❌ Environment file not found: $ENV_FILE"
    exit 1
fi

# Change to project directory
cd "$PROJECT_DIR"

# Get service status
SERVICE_STATUS=$(docker compose --env-file .env.prod -f docker-compose.yml ps --format json 2>/dev/null || echo "[]")

# Check if services are running
BACKEND_RUNNING=$(echo "$SERVICE_STATUS" | jq -r '.[] | select(.Service == "backend") | .State' 2>/dev/null || echo "")
DB_RUNNING=$(echo "$SERVICE_STATUS" | jq -r '.[] | select(.Service == "db") | .State' 2>/dev/null || echo "")
PROXY_RUNNING=$(echo "$SERVICE_STATUS" | jq -r '.[] | select(.Service == "proxy") | .State' 2>/dev/null || echo "")

log "📊 Service Status - Backend: $BACKEND_RUNNING, DB: $DB_RUNNING, Proxy: $PROXY_RUNNING"

# Check if any critical services are down
RESTART_NEEDED=false

if [ "$DB_RUNNING" != "running" ]; then
    log "⚠️  Database is not running"
    RESTART_NEEDED=true
fi

if [ "$BACKEND_RUNNING" != "running" ]; then
    log "⚠️  Backend is not running"
    RESTART_NEEDED=true
fi

if [ "$PROXY_RUNNING" != "running" ]; then
    log "⚠️  Proxy is not running"
    RESTART_NEEDED=true
fi

# Restart services if needed
if [ "$RESTART_NEEDED" = true ]; then
    log "🔄 Restarting services..."
    
    # Try to restart services
    if docker compose --env-file .env.prod -f docker-compose.yml up -d >> "$LOG_FILE" 2>&1; then
        log "✅ Services restarted successfully"
    else
        log "❌ Failed to restart services"
        exit 1
    fi
    
    # Wait for services to start
    sleep 15
else
    log "✅ All services are running"
fi

# Health check
log "🏥 Performing health checks..."

# Check backend health
HEALTH_CHECK=$(curl -s -m 10 http://localhost:8000/healthz 2>/dev/null || echo "failed")
if echo "$HEALTH_CHECK" | grep -q '"status":"ok"'; then
    log "✅ Backend health check passed"
else
    log "❌ Backend health check failed: $HEALTH_CHECK"
    
    # Try to restart backend if health check fails
    log "🔄 Restarting backend due to health check failure..."
    docker compose --env-file .env.prod -f docker-compose.yml restart backend >> "$LOG_FILE" 2>&1
fi

# Check database connectivity (through backend)
if echo "$HEALTH_CHECK" | grep -q '"database":"ok"'; then
    log "✅ Database connectivity check passed"
else
    log "❌ Database connectivity check failed"
fi

# Check proxy health (if available)
PROXY_CHECK=$(curl -s -m 5 -I http://localhost:80/ 2>/dev/null | head -1 || echo "failed")
if echo "$PROXY_CHECK" | grep -q "200 OK"; then
    log "✅ Proxy health check passed"
else
    log "❌ Proxy health check failed: $PROXY_CHECK"
fi

# Cleanup old logs (keep last 1000 lines)
if [ -f "$LOG_FILE" ]; then
    LINES=$(wc -l < "$LOG_FILE")
    if [ "$LINES" -gt 1000 ]; then
        tail -1000 "$LOG_FILE" > "$LOG_FILE.tmp"
        mv "$LOG_FILE.tmp" "$LOG_FILE"
        log "🧹 Cleaned up old log entries"
    fi
fi

log "🐕 Watchdog check completed"

# Exit cleanly
exit 0