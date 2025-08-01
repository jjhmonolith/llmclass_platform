#!/bin/bash

# Environment configuration checker
# Usage: ./env-check.sh [dev|prod]

set -e

ENV_TYPE=${1:-dev}
ENV_FILE=".env.${ENV_TYPE}"

echo "🔍 Checking environment configuration for: $ENV_TYPE"
echo "📁 Environment file: $ENV_FILE"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Environment file $ENV_FILE not found!"
    
    if [ "$ENV_TYPE" = "prod" ]; then
        echo "📋 To create production config:"
        echo "   cp .env.prod.example .env.prod"
        echo "   # Then edit .env.prod with actual values"
    elif [ "$ENV_TYPE" = "dev" ]; then
        echo "📋 Development config should already exist at .env.dev"
        echo "   If missing, check the repository"
    fi
    exit 1
fi

echo "✅ Environment file found"

# Load environment variables
source "$ENV_FILE"

# Check required variables
REQUIRED_VARS=(
    "PROJECT_NAME"
    "PUBLIC_DOMAIN"
    "POSTGRES_DB"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
    "BUILD_VERSION"
)

echo "🔧 Checking required variables..."

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
        echo "❌ Missing: $var"
    else
        # Mask sensitive values
        if [[ "$var" == *"PASSWORD"* ]] || [[ "$var" == *"TOKEN"* ]]; then
            echo "✅ $var=***masked***"
        else
            echo "✅ $var=${!var}"
        fi
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "❌ Missing required variables: ${MISSING_VARS[*]}"
    exit 1
fi

# Production-specific checks
if [ "$ENV_TYPE" = "prod" ]; then
    echo "🔒 Production security checks..."
    
    # Check for default passwords
    if [ "$POSTGRES_PASSWORD" = "CHANGE_THIS_STRONG_PASSWORD_IN_PRODUCTION" ]; then
        echo "❌ Production database password is still default!"
        exit 1
    fi
    
    # Check debug mode is off
    if [ "$DEBUG_MODE" = "true" ]; then
        echo "⚠️  WARNING: DEBUG_MODE is enabled in production!"
    fi
    
    # Check echo endpoint is disabled
    if [ "$ENABLE_ECHO_ENDPOINT" = "true" ]; then
        echo "⚠️  WARNING: ECHO_ENDPOINT is enabled in production!"
    fi
    
    # Check tunnel configuration
    if [ -z "$TUNNEL_ID" ] || [ -z "$TUNNEL_TOKEN" ]; then
        echo "⚠️  WARNING: Cloudflare Tunnel not configured"
    fi
fi

echo "✅ Environment configuration check completed"
echo "🚀 Ready to deploy with $ENV_TYPE configuration"