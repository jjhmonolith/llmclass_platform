#!/bin/bash

# Deployment script for mono-class-platform
# Usage: ./deploy.sh [dev|prod] [--rebuild]

set -e

ENV=${1:-dev}
REBUILD=${2}

echo "🚀 Deploying mono-class-platform in $ENV mode"

# Check environment
if [ ! -f ".env.$ENV" ]; then
    echo "❌ Environment file .env.$ENV not found!"
    
    if [ "$ENV" = "prod" ]; then
        echo "📋 Run 'make setup-prod' first"
    else
        echo "📋 Run 'make setup-dev' first"
    fi
    exit 1
fi

# Validate environment
echo "🔍 Validating environment configuration..."
./env-check.sh $ENV

# Build images if requested
if [ "$REBUILD" = "--rebuild" ]; then
    echo "🔨 Rebuilding Docker images..."
    docker compose --env-file .env.$ENV -f docker-compose.yml build --no-cache
else
    echo "🔨 Building Docker images..."
    docker compose --env-file .env.$ENV -f docker-compose.yml build
fi

# Stop existing services
echo "🛑 Stopping existing services..."
docker compose --env-file .env.$ENV -f docker-compose.yml down

# Start services
echo "🚀 Starting services..."
if [ "$ENV" = "dev" ]; then
    docker compose --env-file .env.$ENV -f docker-compose.yml -f docker-compose.dev.yml up -d
else
    docker compose --env-file .env.$ENV -f docker-compose.yml -f docker-compose.prod.yml up -d
fi

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 15

# Check service health
echo "🏥 Checking service health..."
docker compose --env-file .env.$ENV -f docker-compose.yml ps

# Test endpoints
echo "🧪 Testing endpoints..."
source .env.$ENV

# Test internal health
echo "Testing internal healthz..."
timeout 30 bash -c 'until curl -sf http://localhost:8000/healthz > /dev/null; do sleep 2; done' || {
    echo "❌ Backend healthz test failed"
    echo "📋 Check logs with: make logs-backend ENV=$ENV"
    exit 1
}

# Test proxy health
echo "Testing proxy healthz..."
timeout 30 bash -c "until curl -sf http://localhost:${PROXY_HTTP_PORT:-80}/healthz > /dev/null; do sleep 2; done" || {
    echo "❌ Proxy healthz test failed"
    echo "📋 Check logs with: make logs-proxy ENV=$ENV"
    exit 1
}

echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Services are running:"
echo "   Health: http://localhost:${PROXY_HTTP_PORT:-80}/healthz"
echo "   Status: http://localhost:${PROXY_HTTP_PORT:-80}/"
if [ "$DEBUG_MODE" = "true" ] || [ "$ENABLE_ECHO_ENDPOINT" = "true" ]; then
    echo "   Echo:   http://localhost:${PROXY_HTTP_PORT:-80}/api/echo (dev only)"
fi
echo ""
echo "📊 Monitor with:"
echo "   make status ENV=$ENV"
echo "   make logs ENV=$ENV"
echo ""

if [ "$ENV" = "prod" ]; then
    echo "🔗 Next steps for production:"
    echo "   1. Configure Cloudflare Tunnel"
    echo "   2. Test external access: https://$PUBLIC_DOMAIN/healthz"
    echo "   3. Set up monitoring and backups"
fi