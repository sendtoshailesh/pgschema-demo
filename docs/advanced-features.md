# Advanced PostgreSQL Features in pgschema

This document showcases the comprehensive PostgreSQL feature support in pgschema, demonstrating capabilities that many traditional migration tools lack.

## 🎯 Overview

pgschema provides native support for advanced PostgreSQL features, allowing you to use the full power of PostgreSQL in your declarative schema definitions. Unlike many ORMs and migration tools that only support basic SQL, pgschema understands and manages complex PostgreSQL objects.

## 🔧 Supported Features

### Custom Types

**ENUM Types**
```sql
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');
CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high', 'urgent');
```

**Composite Types**
```sql
CREATE TYPE address AS (
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100)
);
```

### Custom Domains

**Email Validation Domain**
```sql
CREATE DOMAIN email_address AS VARCHAR(255) 
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
```

**Positive Money Domain**
```sql
CREATE DOMAIN money_amount AS NUMERIC(19,4) 
    CHECK (VALUE >= 0);
```

**Phone Number Domain**
```sql
CREATE DOMAIN phone_number AS VARCHAR(20)
    CHECK (VALUE ~ '^\+?[1-9]\d{1,14}$');
```

### Functions and Procedures

**Trigger Functions**
```sql
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (
        table_name, 
        operation, 
        old_data, 
        new_data, 
        changed_at, 
        changed_by
    ) VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END,
        NOW(),
        current_user
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
```

**Business Logic Functions**
```sql
CREATE OR REPLACE FUNCTION calculate_order_total(order_id_param INTEGER)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    total DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(quantity * unit_price), 0)
    INTO total
    FROM order_items
    WHERE order_id = order_id_param;
    
    RETURN total;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_user_order_count(user_id_param INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM orders
        WHERE user_id = user_id_param
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Triggers

**Automatic Timestamp Updates**
```sql
CREATE TRIGGER users_update_timestamp
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER products_update_timestamp
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();
```

**Audit Logging**
```sql
CREATE TRIGGER audit_users
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION audit_changes();

CREATE TRIGGER audit_orders
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION audit_changes();
```

### Views and Materialized Views

**Regular Views**
```sql
CREATE VIEW user_order_summary AS
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    COUNT(o.id) as order_count,
    COALESCE(SUM(o.total_amount), 0) as total_spent,
    MAX(o.created_at) as last_order_date
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.email, u.first_name, u.last_name;
```

**Materialized Views for Analytics**
```sql
CREATE MATERIALIZED VIEW product_stats AS
SELECT 
    p.id,
    p.name,
    p.price,
    c.name as category_name,
    COUNT(r.id) as review_count,
    AVG(r.rating) as avg_rating,
    COUNT(DISTINCT oi.order_id) as order_count,
    SUM(oi.quantity) as total_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN reviews r ON p.id = r.product_id
LEFT JOIN order_items oi ON p.id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'delivered'
GROUP BY p.id, p.name, p.price, c.name;

-- Index on materialized view
CREATE INDEX idx_product_stats_revenue ON product_stats(total_revenue DESC);
```

### Row-Level Security (RLS)

**Multi-Tenant Data Isolation**
```sql
-- Enable RLS on sensitive tables
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own orders
CREATE POLICY user_orders_policy ON orders
    FOR ALL TO app_user
    USING (user_id = current_setting('app.current_user_id')::INTEGER);

-- Policy: Users can only see their own reviews
CREATE POLICY user_reviews_policy ON reviews
    FOR ALL TO app_user
    USING (user_id = current_setting('app.current_user_id')::INTEGER);

-- Policy: Admin users can see everything
CREATE POLICY admin_orders_policy ON orders
    FOR ALL TO admin_user
    USING (true);
```

### Advanced Indexing

**GIN Indexes for JSONB**
```sql
CREATE INDEX idx_products_metadata_gin ON products USING GIN(metadata);
```

**Partial Indexes**
```sql
-- Index only high-rated reviews
CREATE INDEX idx_reviews_high_rating 
    ON reviews(product_id, created_at DESC) 
    WHERE rating >= 4;

-- Index only active products
CREATE INDEX idx_products_active 
    ON products(category_id, price DESC) 
    WHERE status = 'active';
```

**Functional Indexes**
```sql
-- Case-insensitive search
CREATE INDEX idx_products_name_lower 
    ON products(LOWER(name));

-- Email domain extraction
CREATE INDEX idx_users_email_domain 
    ON users(SPLIT_PART(email, '@', 2));
```

**Multi-Column Indexes**
```sql
-- Composite index for common query patterns
CREATE INDEX idx_orders_user_status_date 
    ON orders(user_id, status, created_at DESC);

-- Covering index
CREATE INDEX idx_products_category_covering 
    ON products(category_id) 
    INCLUDE (name, price, created_at);
```

### Constraints

**Complex Check Constraints**
```sql
-- Ensure order total matches sum of line items
ALTER TABLE orders ADD CONSTRAINT orders_total_matches_items
    CHECK (
        total_amount = (
            SELECT COALESCE(SUM(quantity * unit_price), 0)
            FROM order_items
            WHERE order_id = orders.id
        )
    );

-- Ensure review rating is valid
ALTER TABLE reviews ADD CONSTRAINT reviews_valid_rating
    CHECK (rating >= 1 AND rating <= 5);

-- Ensure product price is reasonable
ALTER TABLE products ADD CONSTRAINT products_reasonable_price
    CHECK (price >= 0 AND price <= 999999.99);
```

**Exclusion Constraints**
```sql
-- Prevent overlapping time periods (example for booking system)
CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    resource_id INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    EXCLUDE USING gist (
        resource_id WITH =,
        tsrange(start_time, end_time) WITH &&
    )
);
```

### Partitioning

**Range Partitioning by Date**
```sql
-- Partition orders by month
CREATE TABLE orders_partitioned (
    LIKE orders INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE orders_2024_01 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE orders_2024_03 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
```

**Hash Partitioning**
```sql
-- Partition by user_id hash for load distribution
CREATE TABLE user_activities (
    id BIGSERIAL,
    user_id INTEGER NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
) PARTITION BY HASH (user_id);

-- Create hash partitions
CREATE TABLE user_activities_0 PARTITION OF user_activities
    FOR VALUES WITH (modulus 4, remainder 0);

CREATE TABLE user_activities_1 PARTITION OF user_activities
    FOR VALUES WITH (modulus 4, remainder 1);

CREATE TABLE user_activities_2 PARTITION OF user_activities
    FOR VALUES WITH (modulus 4, remainder 2);

CREATE TABLE user_activities_3 PARTITION OF user_activities
    FOR VALUES WITH (modulus 4, remainder 3);
```

## 🧪 Testing Advanced Features

### Verify Custom Types
```sql
-- Test ENUM type
SELECT 'pending'::order_status;

-- Test domain validation
SELECT 'invalid-email'::email_address;  -- Should fail
SELECT 'valid@example.com'::email_address;  -- Should succeed
```

### Test Functions
```sql
-- Test timestamp function
SELECT update_timestamp();

-- Test business logic function
INSERT INTO orders (user_id, total_amount) VALUES (1, 100.00);
SELECT calculate_order_total(currval('orders_id_seq'));
```

### Test Materialized Views
```sql
-- Refresh materialized view
REFRESH MATERIALIZED VIEW product_stats;

-- Query materialized view
SELECT * FROM product_stats ORDER BY total_revenue DESC LIMIT 10;
```

### Test Row-Level Security
```sql
-- Set user context
SET app.current_user_id = '1';

-- Should only see orders for user 1
SELECT * FROM orders;
```

## 🚀 Benefits of pgschema's Advanced Feature Support

### 1. **Complete PostgreSQL Coverage**
- No need to write custom migration scripts for advanced features
- Declarative management of complex database objects
- Automatic dependency resolution

### 2. **Production-Ready Patterns**
- Row-level security for multi-tenant applications
- Materialized views for analytics performance
- Partitioning for large-scale data management

### 3. **Developer Productivity**
- Single source of truth for all database objects
- Version control friendly schema definitions
- Easy to understand and maintain

### 4. **Enterprise Features**
- Audit logging and compliance support
- Advanced security with RLS policies
- Performance optimization with specialized indexes

## 📚 Learn More

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgschema Advanced Features Guide](https://www.pgschema.com/advanced)
- [PostgreSQL Performance Tips](https://wiki.postgresql.org/wiki/Performance_Optimization)

This comprehensive feature support makes pgschema the ideal choice for teams that want to leverage PostgreSQL's full capabilities while maintaining a clean, declarative schema management workflow.