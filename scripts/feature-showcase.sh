#!/bin/bash

# PostgreSQL Feature Showcase Script
# Demonstrates specific PostgreSQL features supported by pgschema

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Database connection settings
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=demo
export PGUSER=demo
export PGPASSWORD=demo

print_header() {
    echo -e "${BLUE}🔧 $1${NC}"
    echo -e "${BLUE}$(echo "$1" | sed 's/./=/g')${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_feature() {
    echo -e "${PURPLE}🎯 $1${NC}"
}

show_sql() {
    echo -e "${YELLOW}SQL:${NC} $1"
    result=$(psql -t -c "$1" 2>/dev/null | xargs)
    echo -e "${GREEN}Result:${NC} $result"
    echo ""
}

pause() {
    echo ""
    read -p "Press Enter to continue..."
    echo ""
}

# Setup advanced schema
setup_schema() {
    print_header "Setting Up Advanced PostgreSQL Schema"
    
    print_info "Applying showcase_features.sql with advanced PostgreSQL features..."
    if pgschema apply --file examples/showcase_features.sql --auto-approve >/dev/null 2>&1; then
        print_success "Advanced schema applied successfully!"
    else
        print_info "Schema already applied or applying v3_advanced.sql as fallback..."
        pgschema apply --file schemas/v3_advanced.sql --auto-approve >/dev/null 2>&1
    fi
    echo ""
}

# Demonstrate custom types
demo_custom_types() {
    print_header "Custom Types and Domains"
    
    print_feature "ENUM Types"
    echo "PostgreSQL ENUM types provide type-safe constants:"
    show_sql "SELECT 'pending'::order_status, 'admin'::user_role;"
    
    print_feature "Custom Domains with Validation"
    echo "Domains add validation rules to base types:"
    show_sql "SELECT 'user@example.com'::email_address;"
    
    echo "Invalid email would be rejected:"
    echo -e "${YELLOW}SQL:${NC} SELECT 'invalid-email'::email_address;"
    if psql -t -c "SELECT 'invalid-email'::email_address;" 2>/dev/null; then
        echo -e "${RED}Unexpected: Should have failed${NC}"
    else
        echo -e "${GREEN}Result:${NC} ❌ Correctly rejected invalid email"
    fi
    echo ""
    
    print_feature "Money Domain"
    echo "Custom domain for monetary values with validation:"
    show_sql "SELECT '99.99'::money_amount, '0'::money_amount;"
    
    pause
}

# Demonstrate functions and procedures
demo_functions() {
    print_header "Functions and Procedures"
    
    print_feature "PL/pgSQL Functions"
    echo "Custom business logic functions:"
    show_sql "SELECT update_timestamp();"
    
    print_feature "Business Logic Functions"
    echo "Calculate order totals:"
    show_sql "SELECT calculate_order_total(1);"
    
    print_feature "Inventory Management"
    echo "Reserve inventory with business rules:"
    show_sql "SELECT reserve_inventory(1, 5);"
    
    # Show inventory state
    echo "Current inventory state:"
    show_sql "SELECT product_id, quantity_available, quantity_reserved FROM inventory WHERE product_id = 1;"
    
    pause
}

# Demonstrate triggers
demo_triggers() {
    print_header "Triggers and Automatic Updates"
    
    print_feature "Automatic Timestamp Updates"
    echo "Triggers automatically update timestamps on record changes:"
    
    # Insert a test user
    psql -c "INSERT INTO users (email, profile) VALUES ('trigger-test@example.com', '{\"test\": true}');" >/dev/null 2>&1
    
    echo "Initial timestamps:"
    show_sql "SELECT email, created_at, updated_at FROM users WHERE email = 'trigger-test@example.com';"
    
    sleep 1
    
    # Update the user
    psql -c "UPDATE users SET profile = '{\"test\": true, \"updated\": true}' WHERE email = 'trigger-test@example.com';" >/dev/null 2>&1
    
    echo "After update (notice updated_at changed):"
    show_sql "SELECT email, created_at, updated_at FROM users WHERE email = 'trigger-test@example.com';"
    
    print_feature "Audit Logging"
    echo "Audit triggers automatically log all changes:"
    show_sql "SELECT table_name, operation, changed_at FROM audit_log WHERE table_name = 'users' ORDER BY changed_at DESC LIMIT 2;"
    
    # Cleanup
    psql -c "DELETE FROM users WHERE email = 'trigger-test@example.com';" >/dev/null 2>&1
    
    pause
}

# Demonstrate materialized views
demo_materialized_views() {
    print_header "Materialized Views for Analytics"
    
    print_feature "Product Analytics View"
    echo "Materialized views provide fast access to aggregated data:"
    show_sql "SELECT name, review_count, avg_rating, total_sold FROM product_analytics LIMIT 3;"
    
    print_feature "Sales Analytics View"
    echo "Time-series analytics with materialized views:"
    show_sql "SELECT date, order_count, total_revenue FROM sales_analytics LIMIT 3;"
    
    print_feature "Materialized View Refresh"
    echo "Refreshing materialized views updates the cached data:"
    echo -e "${YELLOW}SQL:${NC} REFRESH MATERIALIZED VIEW product_analytics;"
    psql -c "REFRESH MATERIALIZED VIEW product_analytics;" >/dev/null 2>&1
    echo -e "${GREEN}Result:${NC} ✅ Materialized view refreshed"
    echo ""
    
    pause
}

# Demonstrate advanced indexing
demo_indexing() {
    print_header "Advanced Indexing Strategies"
    
    print_feature "GIN Indexes for JSONB"
    echo "GIN indexes enable fast JSONB queries:"
    show_sql "SELECT COUNT(*) FROM users WHERE profile ? 'first_name';"
    
    print_feature "Partial Indexes"
    echo "Partial indexes only index rows matching a condition:"
    show_sql "SELECT indexname FROM pg_indexes WHERE indexname LIKE '%_active' LIMIT 2;"
    
    print_feature "Functional Indexes"
    echo "Functional indexes enable case-insensitive searches:"
    show_sql "SELECT name FROM products WHERE LOWER(name) LIKE '%laptop%';"
    
    print_feature "Array Indexes and Queries"
    echo "Array operations with GIN indexes:"
    show_sql "SELECT name, tags FROM products WHERE tags && ARRAY['electronics'] LIMIT 2;"
    
    pause
}

# Demonstrate row-level security
demo_row_level_security() {
    print_header "Row-Level Security (RLS)"
    
    print_feature "RLS Policies"
    echo "Row-level security policies control data access:"
    show_sql "SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE rowsecurity = true LIMIT 3;"
    
    print_feature "Policy Details"
    echo "View configured RLS policies:"
    show_sql "SELECT tablename, policyname FROM pg_policies LIMIT 3;"
    
    print_info "RLS policies would restrict data access based on current user context"
    echo "Example: Users can only see their own orders and reviews"
    echo ""
    
    pause
}

# Demonstrate JSONB features
demo_jsonb() {
    print_header "JSONB Features"
    
    print_feature "JSONB Queries"
    echo "Query JSON data with PostgreSQL's JSONB operators:"
    show_sql "SELECT email, profile->>'first_name' as first_name FROM users WHERE profile ? 'first_name' LIMIT 2;"
    
    print_feature "JSONB Updates"
    echo "Update JSON data in place:"
    psql -c "UPDATE products SET attributes = '{\"featured\": true, \"color\": \"blue\"}' WHERE id = 1;" >/dev/null 2>&1
    show_sql "SELECT name, attributes FROM products WHERE id = 1;"
    
    print_feature "JSONB Indexing"
    echo "GIN indexes make JSONB queries fast:"
    show_sql "SELECT COUNT(*) FROM products WHERE attributes ? 'featured';"
    
    pause
}

# Demonstrate constraints
demo_constraints() {
    print_header "Advanced Constraints"
    
    print_feature "Check Constraints"
    echo "Complex business rules enforced at database level:"
    
    echo "Valid product price:"
    echo -e "${YELLOW}SQL:${NC} INSERT INTO products (name, slug, price, category_id) VALUES ('Test Product', 'test-product', 29.99, 1);"
    if psql -c "INSERT INTO products (name, slug, price, category_id) VALUES ('Test Product', 'test-product', 29.99, 1);" >/dev/null 2>&1; then
        echo -e "${GREEN}Result:${NC} ✅ Valid product inserted"
        psql -c "DELETE FROM products WHERE slug = 'test-product';" >/dev/null 2>&1
    else
        echo -e "${RED}Result:${NC} ❌ Insertion failed"
    fi
    echo ""
    
    echo "Invalid product price (negative):"
    echo -e "${YELLOW}SQL:${NC} INSERT INTO products (name, slug, price, category_id) VALUES ('Invalid Product', 'invalid-product', -10.00, 1);"
    if psql -c "INSERT INTO products (name, slug, price, category_id) VALUES ('Invalid Product', 'invalid-product', -10.00, 1);" >/dev/null 2>&1; then
        echo -e "${RED}Result:${NC} ❌ Should have been rejected"
    else
        echo -e "${GREEN}Result:${NC} ✅ Correctly rejected negative price"
    fi
    echo ""
    
    print_feature "Unique Constraints"
    echo "Prevent duplicate data:"
    show_sql "SELECT COUNT(*) as unique_emails FROM (SELECT DISTINCT email FROM users) t;"
    
    pause
}

# Demonstrate generated columns
demo_generated_columns() {
    print_header "Generated Columns"
    
    print_feature "Computed Values"
    echo "Generated columns automatically calculate values:"
    
    # Update inventory to show generated column
    psql -c "UPDATE inventory SET quantity_available = 15, quantity_reserved = 8, quantity_incoming = 3 WHERE product_id = 1;" >/dev/null 2>&1
    
    show_sql "SELECT product_id, quantity_available, quantity_reserved, quantity_incoming, quantity_total FROM inventory WHERE product_id = 1;"
    
    echo "The quantity_total column is automatically calculated as:"
    echo "quantity_available + quantity_reserved + quantity_incoming"
    echo ""
    
    pause
}

# Main demonstration
main() {
    clear
    
    print_header "PostgreSQL Feature Showcase with pgschema"
    echo "This demonstration shows the comprehensive PostgreSQL feature support in pgschema."
    echo "Unlike many ORMs and migration tools, pgschema understands and manages"
    echo "advanced PostgreSQL objects natively."
    echo ""
    
    pause
    
    setup_schema
    demo_custom_types
    demo_functions
    demo_triggers
    demo_materialized_views
    demo_indexing
    demo_row_level_security
    demo_jsonb
    demo_constraints
    demo_generated_columns
    
    # Conclusion
    print_header "Feature Showcase Complete"
    
    print_success "pgschema supports all these advanced PostgreSQL features!"
    echo ""
    echo "Key advantages:"
    echo "  ✅ Native PostgreSQL feature support"
    echo "  ✅ Declarative schema management"
    echo "  ✅ Automatic dependency resolution"
    echo "  ✅ Production-ready patterns"
    echo "  ✅ Developer-friendly workflow"
    echo ""
    
    print_info "This comprehensive feature support makes pgschema ideal for teams"
    echo "that want to leverage PostgreSQL's full capabilities while maintaining"
    echo "a clean, declarative schema management workflow."
    echo ""
    
    print_success "Try pgschema with your PostgreSQL database today!"
}

main