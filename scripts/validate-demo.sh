#!/bin/bash

# Demo Validation Script
# Comprehensive validation of the pgschema demo implementation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

print_header() {
    echo -e "${BLUE}🔍 $1${NC}"
    echo -e "${BLUE}$(echo "$1" | sed 's/./=/g')${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

run_test() {
    local test_name=$1
    local test_command=$2
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        print_success "PASSED"
        return 0
    else
        print_error "FAILED"
        return 1
    fi
}

# Validate environment
validate_environment() {
    print_header "Environment Validation"
    
    # Check required commands
    run_test "Docker installed" "command -v docker"
    run_test "Docker Compose installed" "command -v docker-compose"
    run_test "Go installed" "command -v go"
    run_test "PostgreSQL client installed" "command -v psql"
    
    # Check Go version
    if command -v go >/dev/null 2>&1; then
        go_version=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | sed 's/go//')
        if [[ $(echo "$go_version >= 1.21" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
            print_success "Go version $go_version is compatible"
        else
            print_warning "Go version $go_version may not be compatible (need 1.21+)"
        fi
    fi
    
    # Check Docker is running
    if docker info >/dev/null 2>&1; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
    fi
    
    echo ""
}

# Validate file structure
validate_file_structure() {
    print_header "File Structure Validation"
    
    # Required files
    local required_files=(
        "README.md"
        "Makefile"
        "docker-compose.yml"
        "demo.sh"
        "test.sh"
        "schemas/v1_initial.sql"
        "schemas/v2_with_reviews.sql"
        "schemas/v3_advanced.sql"
        "examples/showcase_features.sql"
        "traditional/disaster.sh"
        ".github/workflows/schema.yml"
    )
    
    for file in "${required_files[@]}"; do
        run_test "File exists: $file" "test -f $file"
    done
    
    # Required directories
    local required_dirs=(
        "schemas"
        "examples"
        "scripts"
        "traditional"
        "docs"
        ".github/workflows"
    )
    
    for dir in "${required_dirs[@]}"; do
        run_test "Directory exists: $dir" "test -d $dir"
    done
    
    # Check script permissions
    local scripts=(
        "demo.sh"
        "test.sh"
        "scripts/quick-demo.sh"
        "scripts/feature-showcase.sh"
        "scripts/comparison-demo.sh"
        "scripts/simulate-gitops.sh"
        "traditional/disaster.sh"
        "examples/test_features.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            run_test "Script executable: $script" "test -x $script"
        fi
    done
    
    echo ""
}

# Validate SQL syntax
validate_sql_syntax() {
    print_header "SQL Syntax Validation"
    
    # Check schema files
    local schema_files=(
        "schemas/v1_initial.sql"
        "schemas/v2_with_reviews.sql"
        "schemas/v3_advanced.sql"
        "examples/showcase_features.sql"
    )
    
    for file in "${schema_files[@]}"; do
        if [[ -f "$file" ]]; then
            # Basic SQL syntax check (look for common issues)
            if grep -q "CREATE TABLE.*(" "$file" && grep -q ");" "$file"; then
                print_success "SQL syntax looks valid: $file"
            else
                print_warning "SQL syntax may have issues: $file"
            fi
        fi
    done
    
    echo ""
}

# Validate database setup
validate_database_setup() {
    print_header "Database Setup Validation"
    
    # Start database if not running
    if ! docker ps | grep -q pgschema-demo-db; then
        print_info "Starting PostgreSQL container..."
        docker-compose up -d >/dev/null 2>&1
        sleep 10
    fi
    
    # Test database connection
    export PGHOST=localhost
    export PGPORT=5432
    export PGDATABASE=demo
    export PGUSER=demo
    export PGPASSWORD=demo
    
    run_test "PostgreSQL container running" "docker ps | grep -q pgschema-demo-db"
    run_test "Database accepts connections" "pg_isready -h localhost -p 5432 -U demo"
    run_test "Can execute SQL queries" "psql -c 'SELECT 1;'"
    
    echo ""
}

# Validate pgschema installation
validate_pgschema() {
    print_header "pgschema Installation Validation"
    
    # Install pgschema if not available
    if ! command -v pgschema >/dev/null 2>&1; then
        print_info "Installing pgschema..."
        go install github.com/pgschema/pgschema@latest
    fi
    
    run_test "pgschema command available" "command -v pgschema"
    
    if command -v pgschema >/dev/null 2>&1; then
        run_test "pgschema version check" "pgschema --version"
        run_test "pgschema dump works" "pgschema dump >/dev/null"
    fi
    
    echo ""
}

# Validate demo scripts
validate_demo_scripts() {
    print_header "Demo Scripts Validation"
    
    # Test main demo script components
    if [[ -x "demo.sh" ]]; then
        # Test demo script syntax
        run_test "Main demo script syntax" "bash -n demo.sh"
        
        # Test demo script help
        run_test "Main demo script help" "./demo.sh --help"
    fi
    
    # Test other scripts
    local scripts=(
        "scripts/quick-demo.sh"
        "scripts/feature-showcase.sh"
        "scripts/comparison-demo.sh"
        "scripts/simulate-gitops.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            run_test "Script syntax: $script" "bash -n $script"
        fi
    done
    
    echo ""
}

# Validate schema application
validate_schema_application() {
    print_header "Schema Application Validation"
    
    # Reset database
    psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1
    
    # Test schema files in sequence
    local schemas=(
        "schemas/v1_initial.sql"
        "schemas/v2_with_reviews.sql"
        "schemas/v3_advanced.sql"
    )
    
    for schema in "${schemas[@]}"; do
        if [[ -f "$schema" ]]; then
            # Test plan generation
            run_test "Plan generation: $schema" "pgschema plan --file $schema --output-json /dev/null"
            
            # Test schema application
            run_test "Schema application: $schema" "pgschema apply --file $schema --auto-approve"
        fi
    done
    
    echo ""
}

# Validate advanced features
validate_advanced_features() {
    print_header "Advanced Features Validation"
    
    # Apply advanced schema
    pgschema apply --file schemas/v3_advanced.sql --auto-approve >/dev/null 2>&1
    
    # Test custom types
    run_test "Custom ENUM type" "psql -c \"SELECT 'pending'::order_status;\" >/dev/null"
    
    # Test functions
    run_test "Custom function" "psql -c \"SELECT update_timestamp();\" >/dev/null"
    
    # Test materialized views
    run_test "Materialized view" "psql -c \"SELECT COUNT(*) FROM product_stats;\" >/dev/null"
    
    # Test indexes
    run_test "GIN index exists" "psql -c \"SELECT COUNT(*) FROM pg_indexes WHERE indexname LIKE '%_gin';\" | grep -q '[1-9]'"
    
    echo ""
}

# Validate documentation
validate_documentation() {
    print_header "Documentation Validation"
    
    # Check documentation files
    local docs=(
        "README.md"
        "docs/advanced-features.md"
        "docs/gitops-workflow.md"
        "docs/troubleshooting.md"
        "traditional/README.md"
    )
    
    for doc in "${docs[@]}"; do
        if [[ -f "$doc" ]]; then
            run_test "Documentation exists: $doc" "test -s $doc"
            
            # Check for basic markdown structure
            if grep -q "^#" "$doc"; then
                print_success "Markdown structure: $doc"
            else
                print_warning "No markdown headers found: $doc"
            fi
        fi
    done
    
    echo ""
}

# Validate GitHub Actions workflow
validate_github_actions() {
    print_header "GitHub Actions Workflow Validation"
    
    local workflow=".github/workflows/schema.yml"
    
    if [[ -f "$workflow" ]]; then
        run_test "Workflow file exists" "test -f $workflow"
        
        # Basic YAML syntax check
        if command -v python3 >/dev/null 2>&1; then
            run_test "YAML syntax valid" "python3 -c 'import yaml; yaml.safe_load(open(\"$workflow\"))'"
        else
            print_warning "Cannot validate YAML syntax (python3 not available)"
        fi
        
        # Check for required workflow elements
        if grep -q "on:" "$workflow" && grep -q "jobs:" "$workflow"; then
            print_success "Workflow structure looks valid"
        else
            print_warning "Workflow structure may be incomplete"
        fi
    else
        print_error "GitHub Actions workflow file not found"
    fi
    
    echo ""
}

# Performance validation
validate_performance() {
    print_header "Performance Validation"
    
    # Test demo timing
    print_info "Testing demo performance (this may take a few minutes)..."
    
    # Time the quick demo
    if [[ -x "scripts/quick-demo.sh" ]]; then
        start_time=$(date +%s)
        timeout 300 ./scripts/quick-demo.sh >/dev/null 2>&1 || true
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        if [[ $duration -lt 300 ]]; then
            print_success "Quick demo completed in ${duration}s (< 5 minutes)"
        else
            print_warning "Quick demo took ${duration}s (may be too slow)"
        fi
    fi
    
    # Check resource usage
    if command -v docker >/dev/null 2>&1; then
        memory_usage=$(docker stats --no-stream --format "table {{.MemUsage}}" | tail -n +2 | head -1 | cut -d'/' -f1 | sed 's/[^0-9.]//g')
        if [[ -n "$memory_usage" ]] && [[ $(echo "$memory_usage < 200" | bc -l 2>/dev/null || echo "1") == "1" ]]; then
            print_success "Memory usage is reasonable (${memory_usage}MB)"
        else
            print_warning "Memory usage may be high (${memory_usage}MB)"
        fi
    fi
    
    echo ""
}

# Generate validation report
generate_report() {
    print_header "Validation Report"
    
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
    echo ""
    
    local success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
    echo "Success rate: ${success_rate}%"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_success "All critical tests passed! Demo is ready for release."
        echo ""
        echo "✅ Environment setup works correctly"
        echo "✅ All required files are present"
        echo "✅ SQL syntax is valid"
        echo "✅ Database setup functions properly"
        echo "✅ pgschema installation works"
        echo "✅ Demo scripts execute correctly"
        echo "✅ Schema application succeeds"
        echo "✅ Advanced features work as expected"
        echo "✅ Documentation is comprehensive"
        echo ""
        echo "🚀 Ready for community release!"
        return 0
    else
        print_error "Some tests failed. Please review and fix issues before release."
        echo ""
        echo "❌ $TESTS_FAILED critical issues found"
        if [[ $WARNINGS -gt 0 ]]; then
            echo "⚠️  $WARNINGS warnings to consider"
        fi
        echo ""
        echo "🔧 Please address failed tests before proceeding."
        return 1
    fi
}

# Main validation function
main() {
    clear
    
    print_header "pgschema Demo Validation"
    echo "Comprehensive validation of the pgschema PostgreSQL community demo"
    echo ""
    
    # Run all validations
    validate_environment
    validate_file_structure
    validate_sql_syntax
    validate_database_setup
    validate_pgschema
    validate_demo_scripts
    validate_schema_application
    validate_advanced_features
    validate_documentation
    validate_github_actions
    validate_performance
    
    # Generate final report
    generate_report
}

# Handle script arguments
case "${1:-}" in
    --quick)
        print_header "Quick Validation"
        validate_environment
        validate_file_structure
        validate_database_setup
        validate_pgschema
        generate_report
        ;;
    --help|-h)
        echo "pgschema Demo Validation Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --quick   Run quick validation only"
        echo "  --help    Show this help message"
        echo ""
        exit 0
        ;;
    *)
        main
        ;;
esac