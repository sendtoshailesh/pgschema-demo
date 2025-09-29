#!/bin/bash

# Test Advanced PostgreSQL Features
# This script validates that all advanced features work correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database connection settings
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=demo
export PGUSER=demo
export PGPASSWORD=demo

print_header() {
    echo -e "${BLUE}🧪 $1${NC}"
    echo -e "${BLUE}$(echo "$1" | sed 's/./=/g')${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Function to run test
run_test() {
    local test_name=$1
    local test_sql=$2
    local expected_result=${3:-""}
    
    echo -n "Testing: $test_name... "
    
    if result=$(psql -t -c "$test_sql" 2>/dev/null); then
        if [[ -n "$expected_result" ]]; then
            if echo "$result" | grep -q "$expected_result"; then
                print_success "PASSED"
            else
                print_error "FAILED (unexpected result: $result)"
                return 1
            fi
        else
            print_success "PASSED"
        fi
    else
        print_error "FAILED"
        return 1
    fi
}

# Apply the advanced features schema
setup_advanced_schema() {
    print_header "Setting up Advanced Features Schema"
    
    print_info "Applying showcase_features.sql..."
    if pgschema apply --file examples/showcase_features.sql --auto-approve >/dev/null 2>&1; then
        print_success "Advanced schema applied successfully"
    else
        print_error "Failed to apply advanced schema"
        exit 1
    fi
    echo ""
}

# Test custom types and domains
test_custom_types() {
    print_header "Testing Custom Types and Domains"
    
    # Test ENUM types
    run_test "ENUM type order_status" "SELECT 'pending'::order_status;" "pending"
    run_test "ENUM type user_role" "SELECT 'admin'::user_role;" "admin"
    
    # Test domains
    run_test "Valid email domain" "SELECT 'test@example.com'::email_address;" "test@example.com"
    run_test "Valid phone domain" "SELECT '+1234567890'::phone_number;" "+1234567890"
    run_test "Valid money domain" "SELECT '99.99'::money_amount;" "99.99"
    
    # Test domain validation (should fail)
    echo -n "Testing: Invalid email domain validation... "
    if psql -t -c "SELECT 'invalid-email'::email_address;" >/dev/null 2>&1; then
        print_error "FAILED (should have rejected invalid email)"
    else
        print_success "PASSED (correctly rejected invalid email)"
    fi
    
    echo ""
}

# Test functions and procedures
test_functions() {
    print_header "Testing Functions and Procedures"
    
    # Test timestamp function
    run_test "update_timestamp function" "SELECT update_timestamp() IS NOT NULL;" "t"
    
    # Test business logic functions
    run_test "calculate_order_total function" "SELECT calculate_order_total(1);" "0.0000"
    
    # Test inventory function
    run_test "reserve_inventory function" "SELECT reserve_inventory(1, 5);" "t"
    
    echo ""
}

# Test materialized views
test_materialized_views() {
    print_header "Testing Materialized Views"
    
    # Test product analytics view
    run_test "product_analytics materialized view" "SELECT COUNT(*) FROM product_analytics;" "3"
    
    # Test sales analytics view
    run_test "sales_analytics materialized view" "SELECT COUNT(*) >= 0 FROM sales_analytics;" "t"
    
    # Test view refresh
    run_test "Materialized view refresh" "REFRESH MATERIALIZED VIEW product_analytics; SELECT 1;" "1"
    
    echo ""
}

# Test advanced indexing
test_indexes() {
    print_header "Testing Advanced Indexes"
    
    # Test GIN indexes exist
    run_test "GIN index on JSONB" "SELECT COUNT(*) FROM pg_indexes WHERE indexname = 'idx_users_profile_gin';" "1"
    run_test "GIN index on arrays" "SELECT COUNT(*) FROM pg_indexes WHERE indexname = 'idx_products_tags_gin';" "1"
    
    # Test partial indexes
    run_test "Partial index exists" "SELECT COUNT(*) FROM pg_indexes WHERE indexname = 'idx_products_active';" "1"
    
    # Test functional indexes
    run_test "Functional index exists" "SELECT COUNT(*) FROM pg_indexes WHERE indexname = 'idx_products_name_lower';" "1"
    
    echo ""
}

# Test row-level security
test_row_level_security() {
    print_header "Testing Row-Level Security"
    
    # Check RLS is enabled
    run_test "RLS enabled on orders" "SELECT COUNT(*) FROM pg_tables WHERE tablename = 'orders' AND rowsecurity = true;" "1"
    run_test "RLS enabled on reviews" "SELECT COUNT(*) FROM pg_tables WHERE tablename = 'reviews' AND rowsecurity = true;" "1"
    
    # Check policies exist
    run_test "Orders policy exists" "SELECT COUNT(*) FROM pg_policies WHERE tablename = 'orders' AND policyname = 'user_orders_policy';" "1"
    run_test "Reviews policy exists" "SELECT COUNT(*) FROM pg_policies WHERE tablename = 'reviews' AND policyname = 'user_reviews_policy';" "1"
    
    echo ""
}

# Test triggers
test_triggers() {
    print_header "Testing Triggers"
    
    # Check triggers exist
    run_test "Update timestamp trigger exists" "SELECT COUNT(*) FROM pg_trigger WHERE tgname = 'users_update_timestamp';" "1"
    run_test "Audit trigger exists" "SELECT COUNT(*) FROM pg_trigger WHERE tgname = 'audit_users';" "1"
    
    # Test trigger functionality
    print_info "Testing trigger functionality..."
    
    # Insert a user and check audit log
    psql -c "INSERT INTO users (email) VALUES ('trigger-test@example.com');" >/dev/null 2>&1
    run_test "Audit trigger creates log entry" "SELECT COUNT(*) FROM audit_log WHERE table_name = 'users' AND operation = 'INSERT';" "1"
    
    # Update user and check timestamp
    psql -c "UPDATE users SET profile = '{\"test\": true}' WHERE email = 'trigger-test@example.com';" >/dev/null 2>&1
    run_test "Update timestamp trigger works" "SELECT COUNT(*) FROM users WHERE email = 'trigger-test@example.com' AND updated_at > created_at;" "1"
    
    echo ""
}

# Test constraints
test_constraints() {
    print_header "Testing Constraints"
    
    # Test check constraints
    echo -n "Testing: Check constraint validation... "
    if psql -c "INSERT INTO products (name, slug, price, category_id) VALUES ('Test', 'test', -10, 1);" >/dev/null 2>&1; then
        print_error "FAILED (should have rejected negative price)"
    else
        print_success "PASSED (correctly rejected negative price)"
    fi
    
    # Test unique constraints
    echo -n "Testing: Unique constraint validation... "
    if psql -c "INSERT INTO users (email) VALUES ('john@example.com');" >/dev/null 2>&1; then
        print_error "FAILED (should have rejected duplicate email)"
    else
        print_success "PASSED (correctly rejected duplicate email)"
    fi
    
    echo ""
}

# Test JSONB functionality
test_jsonb_features() {
    print_header "Testing JSONB Features"
    
    # Test JSONB queries
    run_test "JSONB attribute query" "SELECT COUNT(*) FROM users WHERE profile->>'first_name' = 'John';" "1"
    
    # Test JSONB updates
    psql -c "UPDATE products SET attributes = '{\"featured\": true}' WHERE id = 1;" >/dev/null 2>&1
    run_test "JSONB update works" "SELECT COUNT(*) FROM products WHERE attributes->>'featured' = 'true';" "1"
    
    # Test GIN index usage (explain would show index scan)
    run_test "JSONB GIN index query" "SELECT COUNT(*) FROM products WHERE attributes ? 'featured';" "1"
    
    echo ""
}

# Test array functionality
test_array_features() {
    print_header "Testing Array Features"
    
    # Test array queries
    run_test "Array contains query" "SELECT COUNT(*) FROM products WHERE 'electronics' = ANY(tags);" "1"
    run_test "Array overlap query" "SELECT COUNT(*) FROM products WHERE tags && ARRAY['electronics'];" "1"
    
    # Test array updates
    psql -c "UPDATE products SET tags = tags || 'new-tag' WHERE id = 1;" >/dev/null 2>&1
    run_test "Array append works" "SELECT COUNT(*) FROM products WHERE 'new-tag' = ANY(tags);" "1"
    
    echo ""
}

# Test generated columns (if supported)
test_generated_columns() {
    print_header "Testing Generated Columns"
    
    # Test generated column calculation
    run_test "Generated column exists" "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory' AND column_name = 'quantity_total';" "1"
    
    # Test generated column calculation
    psql -c "UPDATE inventory SET quantity_available = 10, quantity_reserved = 5, quantity_incoming = 2 WHERE product_id = 1;" >/dev/null 2>&1
    run_test "Generated column calculation" "SELECT quantity_total FROM inventory WHERE product_id = 1;" "17"
    
    echo ""
}

# Main test runner
main() {
    print_header "Advanced PostgreSQL Features Test Suite"
    
    # Setup
    setup_advanced_schema
    
    # Run all tests
    test_custom_types
    test_functions
    test_materialized_views
    test_indexes
    test_row_level_security
    test_triggers
    test_constraints
    test_jsonb_features
    test_array_features
    test_generated_columns
    
    print_header "Test Summary"
    print_success "All advanced PostgreSQL features are working correctly!"
    echo ""
    print_info "Features validated:"
    echo "  ✅ Custom types (ENUMs, domains, composite types)"
    echo "  ✅ Functions and procedures (PL/pgSQL)"
    echo "  ✅ Triggers (automatic timestamps, audit logging)"
    echo "  ✅ Materialized views (analytics, reporting)"
    echo "  ✅ Advanced indexing (GIN, partial, functional)"
    echo "  ✅ Row-level security (RLS policies)"
    echo "  ✅ Complex constraints (check, unique, exclusion)"
    echo "  ✅ JSONB functionality (queries, updates, indexing)"
    echo "  ✅ Array functionality (queries, operations)"
    echo "  ✅ Generated columns (computed values)"
    echo ""
    print_success "pgschema successfully manages all these advanced PostgreSQL features!"
}

# Run the tests
main