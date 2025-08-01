#!/bin/bash

# Nginx configuration test script
# Usage: ./test-nginx.sh [dev|prod]

set -e

ENV=${1:-dev}
NGINX_CONF="nginx.conf"

if [ "$ENV" = "dev" ]; then
    NGINX_CONF="nginx.dev.conf"
fi

echo "🧪 Testing Nginx configuration: $NGINX_CONF"

# Test configuration syntax
echo "📋 Testing configuration syntax..."
docker run --rm -v "$(pwd)/nginx:/etc/nginx/conf.d:ro" nginx:1.25-alpine nginx -t -c /etc/nginx/conf.d/$NGINX_CONF

echo "✅ Nginx configuration syntax is valid"

# Additional checks
echo "🔍 Additional configuration checks..."

# Check if required files exist
REQUIRED_FILES=(
    "nginx/$NGINX_CONF"
    "nginx/mime.types"
    "../frontend/public/index.html"
    "../frontend/public/404.html"
    "../frontend/public/50x.html"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "❌ Missing required files:"
    printf '   %s\n' "${MISSING_FILES[@]}"
    exit 1
fi

echo "✅ All required files present"

# Check configuration specifics
echo "🔧 Checking configuration specifics..."

# Check upstream configuration
if grep -q "upstream backend" "nginx/$NGINX_CONF"; then
    echo "✅ Backend upstream configured"
else
    echo "❌ Backend upstream not found"
    exit 1
fi

# Check API proxy
if grep -q "location /api/" "nginx/$NGINX_CONF"; then
    echo "✅ API proxy location configured"
else
    echo "❌ API proxy location not found"
    exit 1
fi

# Check static file serving
if grep -q "root /usr/share/nginx/html" "nginx/$NGINX_CONF"; then
    echo "✅ Static file serving configured"
else
    echo "❌ Static file serving not configured"
    exit 1
fi

# Check healthz endpoint
if grep -q "location /healthz" "nginx/$NGINX_CONF"; then
    echo "✅ Health check endpoint configured"
else
    echo "❌ Health check endpoint not found"
    exit 1
fi

echo "✅ All configuration checks passed"
echo "🚀 Nginx configuration is ready for $ENV environment"