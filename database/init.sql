-- Database initialization script for EverShop
-- This script runs when the PostgreSQL container is first created
-- Note: PostgreSQL automatically creates user/database from environment variables
-- This script ensures the user exists with correct password and grants permissions

-- Create the evershop user if it doesn't exist (with correct password)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'evershop') THEN
        CREATE USER evershop WITH PASSWORD 'evershop_password_123';
        RAISE NOTICE 'Created user evershop';
    ELSE
        -- Update password if user exists (in case it was changed)
        ALTER USER evershop WITH PASSWORD 'evershop_password_123';
        RAISE NOTICE 'Updated password for user evershop';
    END IF;
END
$$;

-- Create the evershop database if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'evershop') THEN
        CREATE DATABASE evershop WITH OWNER evershop TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
        RAISE NOTICE 'Created database evershop';
    ELSE
        RAISE NOTICE 'Database evershop already exists';
    END IF;
END
$$;

-- Connect to evershop database and set up permissions
\c evershop

-- Enable extensions (required for EverShop)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set timezone
SET timezone = 'UTC';

-- Grant all privileges to the evershop user
GRANT ALL ON SCHEMA public TO evershop;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO evershop;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO evershop;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO evershop;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO evershop;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO evershop;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO evershop;

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'EverShop database initialized successfully with user: evershop, password: evershop_password_123';
END $$;
