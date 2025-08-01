#!/bin/bash

# Local Docker environment test script
# Usage: ./test-local.sh [--build] [--cleanup]

set -e

BUILD_FLAG=""
CLEANUP_FLAG=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD_FLAG="--build"
            shift
            ;;
        --cleanup)
            CLEANUP_FLAG="true"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--build] [--cleanup]"
            exit 1
            ;;
    esac
done

echo "🧪 Starting local Docker environment test"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running!"
    echo "📋 Please start Docker Desktop and try again"
    exit 1
fi

echo "✅ Docker is running"

# Cleanup if requested
if [ "$CLEANUP_FLAG" = "true" ]; then
    echo "🧹 Cleaning up existing containers and volumes..."
    docker compose --env-file .env.dev -f docker-compose.yml down -v || true
    docker system prune -f || true
fi

# Check environment
echo "🔍 Checking environment configuration..."
./env-check.sh dev

# Build images if requested
if [ "$BUILD_FLAG" = "--build" ]; then
    echo "🔨 Building Docker images..."
    docker compose --env-file .env.dev -f docker-compose.yml build
fi

# Start services
echo "🚀 Starting services..."
docker compose --env-file .env.dev -f docker-compose.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 10

# Check service status
echo "📊 Checking service status..."
docker compose --env-file .env.dev -f docker-compose.yml ps

# Wait for backend to be ready
echo "⏳ Waiting for backend to be ready..."
MAX_WAIT=60
COUNTER=0
until curl -sf http://localhost:8000/healthz > /dev/null 2>&1; do
    if [ $COUNTER -gt $MAX_WAIT ]; then
        echo "❌ Backend is not responding after ${MAX_WAIT} seconds"
        echo "📋 Check backend logs:"
        echo "   docker compose --env-file .env.dev -f docker-compose.yml logs backend"
        exit 1
    fi
    echo "Waiting for backend... ($COUNTER/$MAX_WAIT)"
    sleep 2
    COUNTER=$((COUNTER + 2))
done

echo "✅ Backend is ready"

# Wait for proxy to be ready
echo "⏳ Waiting for proxy to be ready..."
MAX_WAIT=30
COUNTER=0
until curl -sf http://localhost:8080/healthz > /dev/null 2>&1; do
    if [ $COUNTER -gt $MAX_WAIT ]; then
        echo "❌ Proxy is not responding after ${MAX_WAIT} seconds"
        echo "📋 Check proxy logs:"
        echo "   docker compose --env-file .env.dev -f docker-compose.yml logs proxy"
        exit 1
    fi
    echo "Waiting for proxy... ($COUNTER/$MAX_WAIT)"
    sleep 2
    COUNTER=$((COUNTER + 2))
done

echo "✅ Proxy is ready"

# Run endpoint tests
echo "🧪 Testing endpoints..."

# Test health endpoint through proxy
echo "Testing /healthz through proxy..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/healthz)
if echo "$HEALTH_RESPONSE" | grep -q '"status":"ok"'; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed: $HEALTH_RESPONSE"
fi

# Test version endpoint
echo "Testing /api/version..."
VERSION_RESPONSE=$(curl -s http://localhost:8080/api/version)
if echo "$VERSION_RESPONSE" | grep -q '"version"'; then
    echo "✅ Version endpoint passed"
else
    echo "❌ Version endpoint failed: $VERSION_RESPONSE"
fi

# Test echo endpoint (if enabled)
echo "Testing /api/echo..."
ECHO_RESPONSE=$(curl -s http://localhost:8080/api/echo)
if echo "$ECHO_RESPONSE" | grep -q '"method"'; then
    echo "✅ Echo endpoint passed (debug mode active)"
else
    echo "⚠️  Echo endpoint not available (expected in production)"
fi

# Test static files
echo "Testing static files..."
STATIC_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
if [ "$STATIC_RESPONSE" = "200" ]; then
    echo "✅ Static files served correctly"
else
    echo "❌ Static files failed: HTTP $STATIC_RESPONSE"
fi

# Test 404 page
echo "Testing 404 page..."
NOT_FOUND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/nonexistent)
if [ "$NOT_FOUND_RESPONSE" = "404" ]; then
    echo "✅ 404 handling works"
else
    echo "❌ 404 handling failed: HTTP $NOT_FOUND_RESPONSE"
fi

# Database connectivity test (through healthz)
echo "Testing database connectivity..."
DB_STATUS=$(echo "$HEALTH_RESPONSE" | grep -o '"database":"[^"]*"' | cut -d'"' -f4)
if [ "$DB_STATUS" = "ok" ]; then
    echo "✅ Database connection works"
else
    echo "❌ Database connection failed: $DB_STATUS"
fi

echo ""
echo "🎉 All tests completed!"
echo ""
echo "🌐 Access points:"
echo "   Main Dashboard: http://localhost:8080/"
echo "   Health Check:   http://localhost:8080/healthz"
echo "   API Version:    http://localhost:8080/api/version"
echo "   Dev Tools:      http://localhost:8080/dev.html"
if echo "$ECHO_RESPONSE" | grep -q '"method"'; then
    echo "   Echo Endpoint:  http://localhost:8080/api/echo"
fi
echo ""
echo "📊 Management commands:"
echo "   View logs:      docker compose --env-file .env.dev -f docker-compose.yml logs -f"
echo "   Stop services:  docker compose --env-file .env.dev -f docker-compose.yml down"
echo "   Service status: docker compose --env-file .env.dev -f docker-compose.yml ps"
echo ""

# Final service status
echo "📈 Final service status:"
docker compose --env-file .env.dev -f docker-compose.yml ps