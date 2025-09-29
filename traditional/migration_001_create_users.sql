-- Traditional Migration 001: Create Users Table
-- Date: 2024-01-15
-- Author: Developer A
-- Description: Initial user management table

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);