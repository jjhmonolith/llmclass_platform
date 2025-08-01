from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
import structlog
from typing import Dict, Any

from .logging import get_request_logger


logger = structlog.get_logger()


async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Global exception handler for unhandled exceptions"""
    request_logger = get_request_logger(request)
    request_id = getattr(request.state, "request_id", "unknown")
    
    await request_logger.aerror(
        "unhandled_exception",
        error=str(exc),
        error_type=type(exc).__name__,
        request_id=request_id
    )
    
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "error_id": "global_exception",
            "request_id": request_id
        }
    )


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """Handler for HTTP exceptions"""
    request_logger = get_request_logger(request)
    request_id = getattr(request.state, "request_id", "unknown")
    
    # Log client errors (4xx) as warnings, server errors (5xx) as errors
    if exc.status_code >= 500:
        await request_logger.aerror(
            "http_exception",
            status_code=exc.status_code,
            detail=exc.detail,
            request_id=request_id
        )
    else:
        await request_logger.awarn(
            "http_exception",
            status_code=exc.status_code,
            detail=exc.detail,
            request_id=request_id
        )
    
    content = exc.detail
    if isinstance(content, str):
        content = {"detail": content}
    
    if isinstance(content, dict):
        content["request_id"] = request_id
    
    return JSONResponse(
        status_code=exc.status_code,
        content=content
    )


class APIError(HTTPException):
    """Custom API error with structured data"""
    
    def __init__(
        self,
        status_code: int,
        detail: str,
        error_code: str = None,
        extra_data: Dict[str, Any] = None
    ):
        self.error_code = error_code
        self.extra_data = extra_data or {}
        super().__init__(status_code=status_code, detail=detail)