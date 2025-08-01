from fastapi import FastAPI, Request, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import structlog
import logging
from datetime import datetime
import pytz
import os
import sys
from typing import Dict, Any

from .settings import settings
from .database import check_db_connection, init_database

# Configure structured logging
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

logger = structlog.get_logger()

# FastAPI app
app = FastAPI(
    title=settings.project_name,
    version=settings.build_version,
    description="Educational Platform API",
    docs_url="/api/docs" if settings.debug_mode else None,
    redoc_url="/api/redoc" if settings.debug_mode else None,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.debug_mode else [f"https://{settings.public_domain}"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = datetime.utcnow()
    
    # Get client IP (considering proxy headers)
    client_ip = request.headers.get("cf-connecting-ip") or \
                request.headers.get("x-forwarded-for", "").split(",")[0].strip() or \
                request.headers.get("x-real-ip") or \
                getattr(request.client, "host", "unknown")
    
    # Process request
    response = await call_next(request)
    
    # Log request
    process_time = (datetime.utcnow() - start_time).total_seconds()
    
    await logger.ainfo(
        "request_processed",
        method=request.method,
        url=str(request.url),
        client_ip=client_ip,
        status_code=response.status_code,
        process_time_seconds=process_time,
        user_agent=request.headers.get("user-agent", ""),
    )
    
    return response


def get_seoul_time() -> str:
    """Get current time in Seoul timezone"""
    seoul_tz = pytz.timezone(settings.tz)
    return datetime.now(seoul_tz).isoformat()


@app.get("/healthz")
async def health_check():
    """Health check endpoint - returns server status"""
    try:
        # Check database connection
        db_ok = await check_db_connection()
        
        status = "ok" if db_ok else "degraded"
        status_code = 200 if db_ok else 503
        
        response_data = {
            "status": status,
            "time": get_seoul_time(),
            "version": settings.build_version,
            "build_ts": settings.build_ts,
            "timezone": settings.tz,
            "database": "ok" if db_ok else "failed"
        }
        
        if not db_ok:
            raise HTTPException(status_code=503, detail=response_data)
            
        return response_data
    except HTTPException:
        raise
    except Exception as e:
        await logger.aerror("health_check_failed", error=str(e))
        raise HTTPException(status_code=503, detail="Service unavailable")


@app.get("/api/version")
async def get_version():
    """Get application version info"""
    return {
        "version": settings.build_version,
        "build_ts": settings.build_ts,
        "project": settings.project_name,
        "timezone": settings.tz
    }


@app.get("/api/healthz")
async def api_health_check():
    """API health check - same as /healthz but under /api namespace"""
    return await health_check()


# Echo endpoint (development only)
if settings.enable_echo_endpoint:
    @app.get("/api/echo")
    @app.post("/api/echo")
    @app.put("/api/echo")
    @app.delete("/api/echo")
    async def echo_request(request: Request):
        """Echo request details (development only)"""
        if not settings.debug_mode and not settings.enable_echo_endpoint:
            raise HTTPException(status_code=404, detail="Not found")
        
        # Get client info
        client_ip = request.headers.get("cf-connecting-ip") or \
                    request.headers.get("x-forwarded-for", "").split(",")[0].strip() or \
                    request.headers.get("x-real-ip") or \
                    getattr(request.client, "host", "unknown")
        
        # Get request body if present
        body = None
        if request.method in ["POST", "PUT", "PATCH"]:
            try:
                body = await request.body()
                body = body.decode("utf-8") if body else None
            except:
                body = "<binary_data>"
        
        return {
            "method": request.method,
            "url": str(request.url),
            "path": request.url.path,
            "query_params": dict(request.query_params),
            "headers": dict(request.headers),
            "client_ip": client_ip,
            "body": body,
            "timestamp": get_seoul_time()
        }


@app.on_event("startup")
async def startup_event():
    await logger.ainfo(
        "application_startup",
        version=settings.build_version,
        build_ts=settings.build_ts,
        debug_mode=settings.debug_mode,
        echo_endpoint=settings.enable_echo_endpoint
    )
    
    # Initialize database connection
    db_ok = await init_database()
    await logger.ainfo("database_startup_check", database_ok=db_ok)


@app.on_event("shutdown")
async def shutdown_event():
    await logger.ainfo("application_shutdown")


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    await logger.aerror(
        "unhandled_exception",
        error=str(exc),
        error_type=type(exc).__name__,
        path=request.url.path,
        method=request.method
    )
    
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "error_id": "global_exception"}
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.backend_port,
        log_level=settings.log_level,
        access_log=settings.uvicorn_access_log,
        reload=settings.debug_mode
    )