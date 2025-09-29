#!/bin/bash

# pgschema Demo Test Suite
# Automated tests to validate demo functionality

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

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print colored output
print_test_header() {
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

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        print_success "PASSED"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_error "FAILED"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test database connection
test_database_connection() {
    print_test_header "Database Connection Tests"
    
    run_test "PostgreSQL container is running" "docker ps | grep -q pgschema-demo-db"
    run_test "Database accepts connections" "pg_isready -h localhost -p 5432 -U demo"
    run_test "Can execute SQL queries" "psql -c 'SELECT 1;'"
    
    echo ""
}

# Test schema files validity
test_schema_files() {
    print_test_header "Schema File Validation Tests"
    
    # Reset database for clean testing
    psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1
    
    run_test "v1_initial.sql is valid" "pgschema apply --file schemas/v1_initial.sql --auto-approve"
    
    # Reset for next test
    psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1
    
    run_test "v2_with_reviews.sql is valid" "pgschema apply --file schemas/v2_with_reviews.sql --auto-approve"
    
    # Reset for next test
    psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1
    
    run_test "v3_advanced.sql is valid" "pgschema apply --file schemas/v3_advanced.sql --auto-approve"
    
    echo ""
}

# Test pgschema workflow
test_pgschema_workflow() {
    print_test_header "pgschema Workflow Tests"
    
    # Reset database
    psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1
    
    # Test dump command
    run_test "pgschema dump works" "pgschema dump >/dev/null"
    
    # Test plan command
    run_test "pgschema plan works" "pgschema plan --file schemas/v1_initial.sql --output-json /dev/null"
    
    # Test apply command
    run_test "pgschema apply works" "pgschema apply --file schemas/v1_initial.sql --auto-approve"
    
    # Test plan with existing schema
    run_test "pgschema plan with changes" "pgschema plan --file schemas/v2_with_reviews.sql --output-json /dev/null"
    
    # Test apply with changes
    run_test "pgschema apply with changes" "pgschema apply --file schemas/v2_with_reviews.sql --auto-approve"
    
    echo ""
}

# Test PostgreSQL features
test_postgresql_features() {
    print_test_header "PostgreSQL Features Tests"
    
    # Apply advanced schema
    pgschema apply --file schemas/v3_advanced.sql --auto-approve >/dev/null 2>&1
    
    # Test custom types
    run_test "Custom ENUM type works" "psql -c \"SELECT 'pending'::order_status;\""
    
    # Test custom domains
    run_test "Custom domain works" "psql -c \"SELECT 'test@example.com'::email_address;\""
    
    # Test functions
    run_test "Custom function works" "psql -c \"SELECT update_timestamp();\""
    
    # Test materialized views
    run_test "Materialized view works" "psql -c \"SELECT COUNT(*) FROM product_stats;\""
    
    # Test row-level security
    run_test "RLS is enabled" "psql -c \"SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE tablename = 'orders' AND rowsecurity = true;\""
    
    # Test indexes
    run_test "GIN index exists" "psql -c \"SELECT indexname FROM pg_indexes WHERE indexname = 'idx_products_metadata_gin';\""
    
    echo ""
}

# Test traditional migration failure
test_traditional_migration_failure() {
    print_test_header "Traditional Migration Failure Tests"
    
    # Reset database
    psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1
    
    # Apply successful migrations
    psql -f traditional/migration_001_create_users.sql >/dev/null 2>&1
    psql -f traditional/migration_002_create_products.sql >/dev/null 2>&1
    psql -f traditional/migration_003_create_orders.sql >/dev/null 2>&1
    
    # Test that broken migration fails
    run_test "Broken migration fails as expected" "! psql -f traditional/migration_004_add_reviews_BROKEN.sql >/dev/null 2>&1"
    
    # Test that database is in inconsistent state
    run_test "Database has partial changes" "psql -c \"SELECT COUNT(*) FROM pg_tables WHERE tablename = 'reviews';\" | grep -q '1'"
    
    echo ""
}

# Test concurrent change detection
test_concurrent_change_detection() {
    print_test_header "Concurrent Change Detection Tests"
    
    # Reset database and apply base schema
    psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1
    pgschema apply --file schemas/v2_with_reviews.sql --auto-approve >/dev/null 2>&1
    
    # Generate a plan
    pgschema plan --file schemas/v3_advanced.sql --output-json test_plan.json >/dev/null 2>&1
    
    # Make concurrent change
    psql -c "CREATE TABLE concurrent_test (id SERIAL PRIMARY KEY);" >/dev/null 2>&1
    
    # Test that apply detects concurrent change
    run_test "Concurrent change detection works" "! pgschema apply --plan test_plan.json --auto-approve >/dev/null 2>&1"
    
    # Cleanup
    rm -f test_plan.json
    psql -c "DROP TABLE IF EXISTS concurrent_test;" >/dev/null 2>&1
    
    echo ""
}

# Test demo script components
test_demo_script() {
    print_test_header "Demo Script Component Tests"
    
    run_test "Demo script is executable" "test -x demo.sh"
    run_test "Traditional disaster script is executable" "test -x traditional/disaster.sh"
    run_test "Docker compose file exists" "test -f docker-compose.yml"
    run_test "All schema files exist" "test -f schemas/v1_initial.sql && test -f schemas/v2_with_reviews.sql && test -f schemas/v3_advanced.sql"
    
    echo ""
}

# Test cleanup
test_cleanup() {
    print_test_header "Cleanup Tests"
    
    # Test that we can reset the database
    run_test "Database reset works" "psql -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'"
    
    # Test that database is empty after reset
    run_test "Database is empty after reset" "test \$(psql -t -c \"SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';\") -eq 1"  # Only connection_test table
    
    echo ""
}

# Main test runner
main() {
    echo -e "${BLUE}🧪 pgschema Demo Test Suite${NC}"
    echo -e "${BLUE}============================${NC}"
    echo ""
    
    # Check prerequisites
    if ! command -v pgschema >/dev/null 2>&1; then
        print_error "pgschema is not installed. Please run 'make install-pgschema' first."
        exit 1
    fi
    
    if ! docker ps | grep -q pgschema-demo-db; then
        print_error "PostgreSQL container is not running. Please run 'make start' first."
        exit 1
    fi
    
    # Run all tests
    test_database_connection
    test_schema_files
    test_pgschema_workflow
    test_postgresql_features
    test_traditional_migration_failure
    test_concurrent_change_detection
    test_demo_script
    test_cleanup
    
    # Print summary
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo -e "${BLUE}===============${NC}"
    echo ""
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "All tests passed! 🎉"
        echo ""
        echo "The demo is ready to run:"
        echo "  ./demo.sh          # Interactive demo"
        echo "  ./demo.sh --auto   # Automated demo"
        echo "  ./demo.sh --fast   # Fast automated demo"
        exit 0
    else
        print_error "Some tests failed. Please check the output above."
        exit 1
    fi
}

# Run tests
main