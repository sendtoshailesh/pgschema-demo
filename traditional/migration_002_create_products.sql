-- Traditional Migration 002: Create Products Table
-- Date: 2024-01-16
-- Author: Developer B
-- Description: Product catalog table

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add constraint that was forgotten in initial version
ALTER TABLE products ADD CONSTRAINT products_price_positive CHECK (price >= 0);