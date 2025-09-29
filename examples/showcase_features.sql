--
-- pgschema Advanced PostgreSQL Features Showcase
-- This file demonstrates the comprehensive PostgreSQL feature support in pgschema
--

-- =============================================================================
-- CUSTOM TYPES AND DOMAINS
-- =============================================================================

-- ENUM types for better data modeling
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded');
CREATE TYPE user_role AS ENUM ('customer', 'admin', 'moderator');
CREATE TYPE product_status AS ENUM ('active', 'inactive', 'discontinued');

-- Custom domains with validation
CREATE DOMAIN email_address AS VARCHAR(255) 
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE DOMAIN phone_number AS VARCHAR(20)
    CHECK (VALUE ~ '^\+?[1-9]\d{1,14}$');

CREATE DOMAIN money_amount AS NUMERIC(19,4) 
    CHECK (VALUE >= 0);

CREATE DOMAIN percentage AS NUMERIC(5,2)
    CHECK (VALUE >= 0 AND VALUE <= 100);

-- Composite types for complex data structures
CREATE TYPE address AS (
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100)
);

-- =============================================================================
-- ENHANCED TABLES WITH ADVANCED FEATURES
-- =============================================================================

-- Users table with domains and JSONB
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email email_address NOT NULL UNIQUE,
    phone phone_number,
    role user_role DEFAULT 'customer',
    profile JSONB,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Categories with hierarchical structure
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id INTEGER REFERENCES categories(id),
    metadata JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Products with advanced features
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    short_description VARCHAR(500),
    sku VARCHAR(50) UNIQUE,
    price money_amount NOT NULL,
    compare_price money_amount,
    cost_price money_amount,
    category_id INTEGER REFERENCES categories(id),
    status product_status DEFAULT 'active',
    tags TEXT[],
    attributes JSONB DEFAULT '{}',
    images JSONB DEFAULT '[]',
    seo_data JSONB DEFAULT '{}',
    inventory_tracking BOOLEAN DEFAULT true,
    weight NUMERIC(8,3),
    dimensions JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Complex check constraints
    CONSTRAINT products_price_valid CHECK (price > 0),
    CONSTRAINT products_compare_price_valid CHECK (compare_price IS NULL OR compare_price >= price),
    CONSTRAINT products_weight_valid CHECK (weight IS NULL OR weight > 0)
);

-- Inventory with advanced tracking
CREATE TABLE IF NOT EXISTS inventory (
    product_id INTEGER PRIMARY KEY REFERENCES products(id),
    quantity_available INTEGER NOT NULL DEFAULT 0 CHECK (quantity_available >= 0),
    quantity_reserved INTEGER NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    quantity_incoming INTEGER NOT NULL DEFAULT 0 CHECK (quantity_incoming >= 0),
    reorder_level INTEGER DEFAULT 10,
    reorder_quantity INTEGER DEFAULT 50,
    last_restocked TIMESTAMP,
    last_updated TIMESTAMP DEFAULT NOW(),
    
    -- Computed columns using generated columns (PostgreSQL 12+)
    quantity_total INTEGER GENERATED ALWAYS AS (quantity_available + quantity_reserved + quantity_incoming) STORED
);

-- Orders with enhanced status tracking
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    user_id INTEGER NOT NULL REFERENCES users(id),
    status order_status DEFAULT 'pending',
    subtotal money_amount NOT NULL DEFAULT 0,
    tax_amount money_amount NOT NULL DEFAULT 0,
    shipping_amount money_amount NOT NULL DEFAULT 0,
    discount_amount money_amount NOT NULL DEFAULT 0,
    total_amount money_amount NOT NULL DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    billing_address JSONB,
    shipping_address JSONB,
    payment_data JSONB,
    notes TEXT,
    internal_notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    
    -- Complex check constraint
    CONSTRAINT orders_total_calculation CHECK (
        total_amount = subtotal + tax_amount + shipping_amount - discount_amount
    ),
    CONSTRAINT orders_status_dates CHECK (
        (status != 'shipped' OR shipped_at IS NOT NULL) AND
        (status != 'delivered' OR delivered_at IS NOT NULL)
    )
);

-- Order items with detailed tracking
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL, -- Snapshot of product name
    product_sku VARCHAR(50), -- Snapshot of SKU
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price money_amount NOT NULL CHECK (unit_price >= 0),
    total_price money_amount GENERATED ALWAYS AS (quantity * unit_price) STORED,
    product_data JSONB, -- Snapshot of product data at time of order
    UNIQUE(order_id, product_id)
);

-- Reviews with moderation features
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    order_id INTEGER REFERENCES orders(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    comment TEXT,
    is_verified BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT false,
    moderated_by INTEGER REFERENCES users(id),
    moderated_at TIMESTAMP,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(product_id, user_id)
);

-- Audit log for compliance
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT,
    operation VARCHAR(10) NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by INTEGER REFERENCES users(id),
    changed_at TIMESTAMP DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255)
);

-- =============================================================================
-- FUNCTIONS AND PROCEDURES
-- =============================================================================

-- Automatic timestamp update function
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Audit logging function
CREATE OR REPLACE FUNCTION audit_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (
        table_name, 
        record_id,
        operation, 
        old_data, 
        new_data, 
        changed_at
    ) VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        TG_OP,
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END,
        NOW()
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Business logic functions
CREATE OR REPLACE FUNCTION calculate_order_total(order_id_param INTEGER)
RETURNS money_amount AS $$
DECLARE
    subtotal money_amount;
BEGIN
    SELECT COALESCE(SUM(quantity * unit_price), 0)
    INTO subtotal
    FROM order_items
    WHERE order_id = order_id_param;
    
    RETURN subtotal;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_product_rating(product_id_param INTEGER)
RETURNS VOID AS $$
DECLARE
    avg_rating NUMERIC(3,2);
    review_count INTEGER;
BEGIN
    SELECT AVG(rating), COUNT(*)
    INTO avg_rating, review_count
    FROM reviews
    WHERE product_id = product_id_param AND is_approved = true;
    
    UPDATE products
    SET attributes = COALESCE(attributes, '{}'::jsonb) || 
        jsonb_build_object(
            'avg_rating', avg_rating,
            'review_count', review_count
        )
    WHERE id = product_id_param;
END;
$$ LANGUAGE plpgsql;

-- Inventory management function
CREATE OR REPLACE FUNCTION reserve_inventory(product_id_param INTEGER, quantity_param INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    available_qty INTEGER;
BEGIN
    -- Get current available quantity with row lock
    SELECT quantity_available INTO available_qty
    FROM inventory
    WHERE product_id = product_id_param
    FOR UPDATE;
    
    -- Check if enough inventory is available
    IF available_qty >= quantity_param THEN
        UPDATE inventory
        SET quantity_available = quantity_available - quantity_param,
            quantity_reserved = quantity_reserved + quantity_param,
            last_updated = NOW()
        WHERE product_id = product_id_param;
        
        RETURN true;
    ELSE
        RETURN false;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Automatic timestamp updates
CREATE TRIGGER users_update_timestamp
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER products_update_timestamp
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER orders_update_timestamp
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER reviews_update_timestamp
    BEFORE UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- Audit logging triggers
CREATE TRIGGER audit_users
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION audit_changes();

CREATE TRIGGER audit_orders
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION audit_changes();

CREATE TRIGGER audit_products
    AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW
    EXECUTE FUNCTION audit_changes();

-- Business logic triggers
CREATE TRIGGER update_product_rating_trigger
    AFTER INSERT OR UPDATE OR DELETE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_product_rating(COALESCE(NEW.product_id, OLD.product_id));

-- =============================================================================
-- VIEWS AND MATERIALIZED VIEWS
-- =============================================================================

-- User summary view
CREATE VIEW user_summary AS
SELECT 
    u.id,
    u.email,
    u.role,
    COUNT(DISTINCT o.id) as order_count,
    COALESCE(SUM(o.total_amount), 0) as total_spent,
    COUNT(DISTINCT r.id) as review_count,
    MAX(o.created_at) as last_order_date,
    u.created_at as registration_date
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
LEFT JOIN reviews r ON u.id = r.user_id
GROUP BY u.id, u.email, u.role, u.created_at;

-- Product analytics materialized view
CREATE MATERIALIZED VIEW product_analytics AS
SELECT 
    p.id,
    p.name,
    p.sku,
    p.price,
    p.status,
    c.name as category_name,
    COUNT(DISTINCT r.id) as review_count,
    AVG(r.rating) as avg_rating,
    COUNT(DISTINCT oi.order_id) as order_count,
    SUM(oi.quantity) as total_sold,
    SUM(oi.total_price) as total_revenue,
    i.quantity_available,
    i.quantity_reserved,
    p.created_at,
    p.updated_at
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN reviews r ON p.id = r.product_id AND r.is_approved = true
LEFT JOIN order_items oi ON p.id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.id AND o.status IN ('delivered', 'shipped')
LEFT JOIN inventory i ON p.id = i.product_id
GROUP BY p.id, p.name, p.sku, p.price, p.status, c.name, 
         i.quantity_available, i.quantity_reserved, p.created_at, p.updated_at;

-- Sales analytics materialized view
CREATE MATERIALIZED VIEW sales_analytics AS
SELECT 
    DATE_TRUNC('day', o.created_at) as date,
    COUNT(*) as order_count,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value,
    COUNT(DISTINCT o.user_id) as unique_customers
FROM orders o
WHERE o.status NOT IN ('cancelled', 'refunded')
GROUP BY DATE_TRUNC('day', o.created_at)
ORDER BY date;

-- =============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- =============================================================================

-- Enable RLS on sensitive tables
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Create roles
CREATE ROLE app_user;
CREATE ROLE admin_user;
CREATE ROLE moderator_user;

-- Policies for orders
CREATE POLICY user_orders_policy ON orders
    FOR ALL TO app_user
    USING (user_id = current_setting('app.current_user_id')::INTEGER);

CREATE POLICY admin_orders_policy ON orders
    FOR ALL TO admin_user
    USING (true);

-- Policies for reviews
CREATE POLICY user_reviews_policy ON reviews
    FOR ALL TO app_user
    USING (user_id = current_setting('app.current_user_id')::INTEGER);

CREATE POLICY moderator_reviews_policy ON reviews
    FOR ALL TO moderator_user
    USING (true);

-- Policies for audit log
CREATE POLICY admin_audit_policy ON audit_log
    FOR SELECT TO admin_user
    USING (true);

-- =============================================================================
-- ADVANCED INDEXING
-- =============================================================================

-- Basic indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- JSONB indexes
CREATE INDEX idx_users_profile_gin ON users USING GIN(profile);
CREATE INDEX idx_products_attributes_gin ON products USING GIN(attributes);
CREATE INDEX idx_products_tags_gin ON products USING GIN(tags);

-- Composite indexes
CREATE INDEX idx_products_category_status ON products(category_id, status);
CREATE INDEX idx_products_status_price ON products(status, price DESC);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_orders_status_created ON orders(status, created_at DESC);

-- Partial indexes
CREATE INDEX idx_products_active ON products(category_id, price DESC) 
    WHERE status = 'active';

CREATE INDEX idx_reviews_approved ON reviews(product_id, rating DESC) 
    WHERE is_approved = true;

CREATE INDEX idx_orders_pending ON orders(created_at DESC) 
    WHERE status = 'pending';

-- Functional indexes
CREATE INDEX idx_products_name_lower ON products(LOWER(name));
CREATE INDEX idx_users_email_domain ON users(SPLIT_PART(email, '@', 2));

-- Covering indexes (INCLUDE clause)
CREATE INDEX idx_products_category_covering ON products(category_id) 
    INCLUDE (name, price, status, created_at);

-- Text search indexes
CREATE INDEX idx_products_search ON products USING GIN(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- =============================================================================
-- CONSTRAINTS AND VALIDATION
-- =============================================================================

-- Additional check constraints
ALTER TABLE products ADD CONSTRAINT products_slug_format 
    CHECK (slug ~ '^[a-z0-9-]+$');

ALTER TABLE categories ADD CONSTRAINT categories_no_self_reference 
    CHECK (id != parent_id);

ALTER TABLE orders ADD CONSTRAINT orders_amounts_non_negative 
    CHECK (subtotal >= 0 AND tax_amount >= 0 AND shipping_amount >= 0 AND discount_amount >= 0);

-- Exclusion constraints (requires btree_gist extension)
-- CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Example: Prevent overlapping promotional periods
-- CREATE TABLE promotions (
--     id SERIAL PRIMARY KEY,
--     name VARCHAR(255) NOT NULL,
--     start_date DATE NOT NULL,
--     end_date DATE NOT NULL,
--     EXCLUDE USING gist (daterange(start_date, end_date, '[]') WITH &&)
-- );

-- =============================================================================
-- SAMPLE DATA FOR TESTING
-- =============================================================================

-- Insert sample categories
INSERT INTO categories (name, slug, description) VALUES
('Electronics', 'electronics', 'Electronic devices and gadgets'),
('Books', 'books', 'Books and literature'),
('Clothing', 'clothing', 'Apparel and accessories');

-- Insert sample users
INSERT INTO users (email, role, profile) VALUES
('john@example.com', 'customer', '{"first_name": "John", "last_name": "Doe"}'),
('admin@example.com', 'admin', '{"first_name": "Admin", "last_name": "User"}'),
('jane@example.com', 'customer', '{"first_name": "Jane", "last_name": "Smith"}');

-- Insert sample products
INSERT INTO products (name, slug, description, price, category_id, status, tags) VALUES
('Laptop Pro', 'laptop-pro', 'High-performance laptop', 1299.99, 1, 'active', ARRAY['electronics', 'computers']),
('Programming Book', 'programming-book', 'Learn to code', 49.99, 2, 'active', ARRAY['books', 'programming']),
('T-Shirt', 't-shirt', 'Comfortable cotton t-shirt', 19.99, 3, 'active', ARRAY['clothing', 'casual']);

-- Insert inventory
INSERT INTO inventory (product_id, quantity_available) VALUES
(1, 50),
(2, 100),
(3, 200);

-- Refresh materialized views
REFRESH MATERIALIZED VIEW product_analytics;
REFRESH MATERIALIZED VIEW sales_analytics;