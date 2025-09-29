-- Traditional Migration 004: Add Product Reviews (BROKEN!)
-- Date: 2024-01-18
-- Author: Developer C
-- Description: Add product review functionality
-- WARNING: This migration has intentional errors to demonstrate failure scenarios

-- This migration will fail due to various issues:

-- 1. Missing NOT NULL constraint on required fields
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),  -- Missing NOT NULL
    user_id INTEGER REFERENCES users(id),        -- Missing NOT NULL
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),  -- Missing NOT NULL
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 2. Trying to create an index on a column that doesn't exist yet
CREATE INDEX idx_reviews_title ON reviews(title);  -- title column doesn't exist!

-- 3. Adding a constraint that references a non-existent table
ALTER TABLE reviews ADD CONSTRAINT fk_reviews_category 
    FOREIGN KEY (category_id) REFERENCES categories(id);  -- categories table doesn't exist!

-- 4. Syntax error in function creation
CREATE OR REPLACE FUNCTION update_review_timestamp()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$ LANGUAGE plpgsql;  -- Missing $$ delimiter

-- 5. Creating trigger on non-existent column
CREATE TRIGGER reviews_update_timestamp
    BEFORE UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_review_timestamp();  -- updated_at column doesn't exist!

-- If this migration partially succeeds, the database will be in an inconsistent state
-- Some objects created, others failed, no easy way to rollback