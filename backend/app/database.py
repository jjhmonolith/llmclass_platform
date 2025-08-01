from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import SQLAlchemyError
import structlog
from typing import Generator

from .settings import settings

logger = structlog.get_logger()

# Database engine
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    pool_recycle=300,
    pool_size=5,
    max_overflow=10,
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


def get_db() -> Generator:
    """Dependency to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def check_db_connection() -> bool:
    """Check if database connection is working"""
    try:
        db = SessionLocal()
        # Simple query to test connection
        result = db.execute(text("SELECT 1"))
        db.close()
        return True
    except SQLAlchemyError as e:
        await logger.aerror("database_connection_failed", error=str(e))
        return False
    except Exception as e:
        await logger.aerror("database_check_unexpected_error", error=str(e))
        return False


async def init_database():
    """Initialize database (create tables if needed)"""
    try:
        # For now, just test the connection
        # In future tasks, we'll add: Base.metadata.create_all(bind=engine)
        connection_ok = await check_db_connection()
        if connection_ok:
            await logger.ainfo("database_initialized_successfully")
        else:
            await logger.aerror("database_initialization_failed")
        return connection_ok
    except Exception as e:
        await logger.aerror("database_init_error", error=str(e))
        return False