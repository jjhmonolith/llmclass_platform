#!/bin/bash

# Backend startup script for production
set -e

echo "Starting FastAPI backend..."

# Install dependencies if requirements.txt has changed
if [ -f "/app/requirements.txt" ]; then
    echo "Installing Python dependencies..."
    pip install --no-cache-dir -r requirements.txt
fi

# Set build timestamp if not provided
if [ -z "$BUILD_TS" ]; then
    export BUILD_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
fi

echo "Build version: $BUILD_VERSION"
echo "Build timestamp: $BUILD_TS"
echo "Log level: $LOG_LEVEL"
echo "Debug mode: $DEBUG_MODE"

# Start the application
if [ "$DEBUG_MODE" = "true" ]; then
    echo "Starting in development mode with hot reload..."
    exec uvicorn app.main:app \
        --host 0.0.0.0 \
        --port ${BACKEND_PORT:-8000} \
        --log-level ${LOG_LEVEL:-info} \
        --reload \
        --reload-dir /app
else
    echo "Starting in production mode with Gunicorn..."
    exec gunicorn app.main:app \
        -w 4 \
        -k uvicorn.workers.UvicornWorker \
        --bind 0.0.0.0:${BACKEND_PORT:-8000} \
        --log-level ${LOG_LEVEL:-info} \
        --access-logfile - \
        --error-logfile - \
        --preload \
        --timeout 120 \
        --keep-alive 5 \
        --max-requests 1000 \
        --max-requests-jitter 100
fi