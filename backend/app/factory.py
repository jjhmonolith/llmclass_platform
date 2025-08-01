from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from datetime import datetime
import structlog

from .core.settings import settings
from .core.logging import configure_logging, RequestIDMiddleware, get_request_logger
from .core.errors import global_exception_handler, http_exception_handler
from .api.routes_health import router as health_router
from .api.routes_dev import router as dev_router
from .database import init_database


def create_app() -> FastAPI:
    """Create and configure FastAPI application"""
    
    # Configure logging
    logger = configure_logging()
    
    # Create FastAPI app
    app = FastAPI(
        title=settings.project_name,
        version=settings.build_version,
        description="Educational Platform API - T1 Scaffolding",
        docs_url=settings.docs_url,
        redoc_url=settings.redoc_url,
        openapi_url="/api/openapi.json" if settings.docs_enabled else None
    )
    
    # Add request ID middleware
    app.add_middleware(RequestIDMiddleware)
    
    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.effective_cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Request logging middleware
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        start_time = datetime.utcnow()
        request_logger = get_request_logger(request)
        
        # Process request
        response = await call_next(request)
        
        # Log request
        process_time = (datetime.utcnow() - start_time).total_seconds()
        
        await request_logger.ainfo(
            "request_processed",
            status_code=response.status_code,
            process_time_seconds=process_time,
            user_agent=request.headers.get("user-agent", ""),
        )
        
        return response
    
    # Include routers
    app.include_router(health_router)
    app.include_router(dev_router)
    
    # Exception handlers
    app.add_exception_handler(Exception, global_exception_handler)
    app.add_exception_handler(Exception, http_exception_handler)
    
    # Startup event
    @app.on_event("startup")
    async def startup_event():
        await logger.ainfo(
            "application_startup",
            version=settings.build_version,
            build_ts=settings.build_ts,
            debug_mode=settings.debug_mode,
            docs_enabled=settings.docs_enabled
        )
        
        # Initialize database connection
        db_ok = await init_database()
        await logger.ainfo("database_startup_check", database_ok=db_ok)
    
    # Shutdown event
    @app.on_event("shutdown")
    async def shutdown_event():
        await logger.ainfo("application_shutdown")
    
    return app