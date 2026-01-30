-- Database initialization script for EverShop
-- This script runs when the PostgreSQL container is first created

-- Create additional databases if needed
-- CREATE DATABASE evershop_test;

-- Create additional users if needed
-- CREATE USER evershop_user WITH PASSWORD 'evershop_password';
-- GRANT ALL PRIVILEGES ON DATABASE postgres TO evershop_user;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set timezone
SET timezone = 'UTC';

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'EverShop database initialized successfully';
END $$;