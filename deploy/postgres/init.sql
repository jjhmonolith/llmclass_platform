-- PostgreSQL initialization script
-- This script runs when the database container starts for the first time

-- Create additional extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set timezone to Korea
SET timezone = 'Asia/Seoul';

-- Create database if it doesn't exist (handled by POSTGRES_DB env var)
-- Additional setup can be added here in future tasks

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'Database initialized at %', NOW();
END $$;