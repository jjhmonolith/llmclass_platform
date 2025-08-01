import structlog
import logging
import sys
import uuid
from typing import Dict, Any
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

from .settings import settings


def configure_logging():
    """Configure structured logging with JSON output"""
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=getattr(logging, settings.log_level.upper())
    )

    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    return structlog.get_logger()


class RequestIDMiddleware(BaseHTTPMiddleware):
    """Middleware to add request ID to requests and responses"""
    
    async def dispatch(self, request: Request, call_next) -> Response:
        # Generate or get request ID
        request_id = request.headers.get("x-request-id") or str(uuid.uuid4())
        
        # Add to request state
        request.state.request_id = request_id
        
        # Process request
        response = await call_next(request)
        
        # Add to response headers
        response.headers["x-request-id"] = request_id
        
        return response


def get_client_ip(request: Request) -> str:
    """Extract client IP from request headers"""
    return (
        request.headers.get("cf-connecting-ip") or
        request.headers.get("x-forwarded-for", "").split(",")[0].strip() or
        request.headers.get("x-real-ip") or
        getattr(request.client, "host", "unknown")
    )


def get_request_logger(request: Request) -> structlog.BoundLogger:
    """Get logger bound with request context"""
    logger = structlog.get_logger()
    request_id = getattr(request.state, "request_id", "unknown")
    
    return logger.bind(
        request_id=request_id,
        method=request.method,
        path=request.url.path,
        client_ip=get_client_ip(request)
    )