-- Initialize demo database with basic setup
-- This file is automatically executed when PostgreSQL container starts

-- Create demo user with necessary permissions (already created by POSTGRES_USER)
-- Grant additional permissions for demo purposes
GRANT ALL PRIVILEGES ON DATABASE demo TO demo;
GRANT ALL PRIVILEGES ON SCHEMA public TO demo;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO demo;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO demo;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO demo;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO demo;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO demo;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO demo;

-- Create a simple test to verify connection
CREATE TABLE IF NOT EXISTS connection_test (
    id SERIAL PRIMARY KEY,
    message TEXT DEFAULT 'pgschema demo database ready!',
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO connection_test (message) VALUES ('Database initialized successfully');

-- Display initialization message
\echo 'pgschema demo database initialized successfully!'
\echo 'Connection details:'
\echo '  Host: localhost'
\echo '  Port: 5432'
\echo '  Database: demo'
\echo '  User: demo'
\echo '  Password: demo'