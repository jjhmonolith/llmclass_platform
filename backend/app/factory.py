from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.openapi.docs import get_swagger_ui_html, get_redoc_html
from fastapi.openapi.utils import get_openapi
from datetime import datetime
import structlog

from .core.settings import settings
from .core.logging import configure_logging, RequestIDMiddleware, get_request_logger
from .core.errors import global_exception_handler, http_exception_handler
from .core.docs_auth import get_docs_dependency
from .api.routes_health import router as health_router
from .api.routes_dev import router as dev_router
from .database import init_database


def create_app() -> FastAPI:
    """Create and configure FastAPI application"""
    
    # Configure logging
    logger = configure_logging()
    
    # Create FastAPI app with conditional docs
    app = FastAPI(
        title=settings.project_name,
        version=settings.build_version,
        description="Educational Platform API - T1 Scaffolding",
        docs_url=None,  # We'll handle this manually
        redoc_url=None,  # We'll handle this manually
        openapi_url=None  # We'll handle this manually
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
    
    # Custom OpenAPI documentation endpoints with optional auth
    if settings.docs_enabled:
        docs_dependency = get_docs_dependency()
        
        @app.get("/api/docs", include_in_schema=False)
        async def custom_swagger_ui_html(credentials=docs_dependency):
            return get_swagger_ui_html(
                openapi_url="/api/openapi.json",
                title=f"{app.title} - Swagger UI",
            )
        
        @app.get("/api/redoc", include_in_schema=False)
        async def redoc_html(credentials=docs_dependency):
            return get_redoc_html(
                openapi_url="/api/openapi.json",
                title=f"{app.title} - ReDoc",
            )
        
        @app.get("/api/openapi.json", include_in_schema=False)
        async def get_open_api_endpoint(credentials=docs_dependency):
            return get_openapi(
                title=app.title,
                version=app.version,
                description=app.description,
                routes=app.routes,
            )
    
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