#!/bin/bash

# pgschema PostgreSQL Community Demo
# Interactive demonstration script showing pgschema's capabilities

set -e

# Configuration
DEMO_PAUSE_DURATION=${DEMO_PAUSE_DURATION:-3}
DEMO_SHOW_COMMANDS=${DEMO_SHOW_COMMANDS:-true}
DEMO_AUTO_CONTINUE=${DEMO_AUTO_CONTINUE:-false}

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

# Function to print colored output
print_header() {
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}$(echo "$1" | sed 's/./=/g')${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Function to pause for user input
pause() {
    if [[ "$DEMO_AUTO_CONTINUE" == "true" ]]; then
        sleep $DEMO_PAUSE_DURATION
    else
        echo ""
        read -p "Press Enter to continue..."
    fi
    echo ""
}

# Function to show command and execute
show_and_run() {
    local command=$1
    local description=${2:-""}
    
    if [[ -n "$description" ]]; then
        print_info "$description"
    fi
    
    if [[ "$DEMO_SHOW_COMMANDS" == "true" ]]; then
        echo -e "${PURPLE}$ $command${NC}"
    fi
    
    eval "$command"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    print_header "🔍 Checking Prerequisites"
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is required but not installed"
        exit 1
    fi
    print_success "Docker is installed"
    
    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        print_error "Docker Compose is required but not installed"
        exit 1
    fi
    print_success "Docker Compose is installed"
    
    # Check Go
    if ! command -v go >/dev/null 2>&1; then
        print_error "Go is required but not installed"
        exit 1
    fi
    print_success "Go is installed"
    
    # Check pgschema
    if ! command -v pgschema >/dev/null 2>&1; then
        print_warning "pgschema not found, installing..."
        go install github.com/pgschema/pgschema@latest
        if command -v pgschema >/dev/null 2>&1; then
            print_success "pgschema installed successfully"
        else
            print_error "Failed to install pgschema"
            exit 1
        fi
    else
        print_success "pgschema is installed"
    fi
    
    # Show versions
    echo ""
    print_info "Versions:"
    echo "  Docker: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
    echo "  Docker Compose: $(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)"
    echo "  Go: $(go version | cut -d' ' -f3)"
    echo "  pgschema: $(pgschema --version 2>/dev/null || echo 'unknown')"
    
    pause
}

# Function to setup environment
setup_environment() {
    print_header "🚀 Setting Up Demo Environment"
    
    print_info "Starting PostgreSQL database..."
    show_and_run "docker-compose up -d" "Starting PostgreSQL container"
    
    print_info "Waiting for database to be ready..."
    sleep 5
    
    # Test connection
    if pg_isready -h localhost -p 5432 -U demo >/dev/null 2>&1; then
        print_success "Database is ready!"
    else
        print_error "Database is not ready. Please check Docker logs."
        exit 1
    fi
    
    pause
}

# Act 1: The Problem - Traditional Migration Disaster
act1_traditional_disaster() {
    print_header "🎬 ACT 1: The Problem - Traditional Migration Disaster"
    
    echo "Let's see what happens with traditional imperative migrations..."
    echo ""
    
    print_info "Traditional approach requires writing sequential migration files:"
    echo "  migration_001_create_users.sql"
    echo "  migration_002_create_products.sql" 
    echo "  migration_003_create_orders.sql"
    echo "  migration_004_add_reviews.sql  ← This one will fail!"
    echo ""
    
    pause
    
    print_info "Running traditional migration disaster simulation..."
    cd traditional
    ./disaster.sh
    cd ..
    
    print_warning "As you can see, traditional migrations can fail catastrophically!"
    echo ""
    echo "Problems with traditional approach:"
    echo "  ❌ Manual migration writing for every change"
    echo "  ❌ Schema drift between environments"
    echo "  ❌ No visibility into what will change"
    echo "  ❌ Failed migrations leave database in broken state"
    echo "  ❌ Complex rollback procedures"
    echo ""
    
    pause
}

# Act 2: The Solution - pgschema to the Rescue
act2_pgschema_solution() {
    print_header "🎬 ACT 2: The Solution - pgschema to the Rescue"
    
    echo "Now let's see how pgschema solves these problems with a declarative approach!"
    echo ""
    
    # Clean database first
    print_info "Cleaning database to start fresh..."
    show_and_run 'psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"' "Resetting database"
    
    print_info "Step 1: Dump current schema (empty database)"
    show_and_run "pgschema dump" "Dumping current schema state"
    
    print_info "Step 2: Apply initial schema declaratively"
    show_and_run "pgschema apply --file schemas/v1_initial.sql --auto-approve" "Applying initial e-commerce schema"
    
    print_success "Schema applied successfully! Let's see what we created:"
    show_and_run "pgschema dump" "Showing current schema"
    
    pause
    
    print_info "Step 3: Add reviews feature by editing desired state"
    echo "Instead of writing migration steps, we just declare what we want:"
    echo ""
    echo "We want to add a reviews table. Let's see what pgschema will do:"
    
    show_and_run "pgschema plan --file schemas/v2_with_reviews.sql" "Generating migration plan"
    
    print_info "pgschema automatically figured out what changes are needed!"
    echo "Key benefits:"
    echo "  ✅ Clear preview of exactly what will change"
    echo "  ✅ Automatic dependency management"
    echo "  ✅ Safe transaction handling"
    echo ""
    
    pause
    
    print_info "Step 4: Apply the changes safely"
    show_and_run "pgschema apply --file schemas/v2_with_reviews.sql" "Applying reviews feature"
    
    print_success "Changes applied successfully!"
    show_and_run "pgschema dump" "Showing updated schema"
    
    pause
}

# Act 3: Advanced Features - PostgreSQL Superpowers
act3_advanced_features() {
    print_header "🎬 ACT 3: Advanced Features - PostgreSQL Superpowers"
    
    echo "pgschema supports advanced PostgreSQL features that many migration tools don't:"
    echo "  • Custom types and domains"
    echo "  • Functions and triggers"
    echo "  • Row-level security policies"
    echo "  • Materialized views"
    echo "  • Advanced indexing strategies"
    echo ""
    
    pause
    
    print_info "Let's add advanced PostgreSQL features to our schema:"
    show_and_run "pgschema plan --file schemas/v3_advanced.sql" "Planning advanced features"
    
    print_info "Look at all the advanced PostgreSQL features pgschema handles:"
    echo "  ✅ Custom ENUM types (order_status)"
    echo "  ✅ Custom domains (email_address)"
    echo "  ✅ Functions and triggers (automatic timestamps)"
    echo "  ✅ Materialized views (product_stats)"
    echo "  ✅ Row-level security policies"
    echo "  ✅ Advanced indexes (GIN, partial, functional)"
    echo ""
    
    pause
    
    print_info "Applying advanced features..."
    show_and_run "pgschema apply --file schemas/v3_advanced.sql" "Applying advanced PostgreSQL features"
    
    print_success "Advanced features applied successfully!"
    
    print_info "Let's verify some of the advanced features work:"
    show_and_run "psql -c \"SELECT 'pending'::order_status;\"" "Testing custom ENUM type"
    show_and_run "psql -c \"SELECT update_timestamp();\"" "Testing custom function"
    show_and_run "psql -c \"SELECT COUNT(*) FROM product_stats;\"" "Testing materialized view"
    
    pause
}

# Act 4: Production Workflow - GitOps Integration
act4_production_workflow() {
    print_header "🎬 ACT 4: Production Workflow - GitOps Integration"
    
    echo "pgschema integrates seamlessly with modern DevOps practices:"
    echo "  • Plan generation in CI (Pull Requests)"
    echo "  • Review process for schema changes"
    echo "  • Automatic deployment in CD (after merge)"
    echo "  • Multi-environment consistency"
    echo "  • Safety features (fingerprinting, rollbacks)"
    echo ""
    
    pause
    
    print_info "Example GitHub Actions workflow:"
    echo ""
    cat << 'EOF'
# .github/workflows/schema.yml
name: Database Schema Management

on:
  pull_request:
    paths: ['schema.sql']
  push:
    branches: [main]
    paths: ['schema.sql']

jobs:
  plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install pgschema
        run: go install github.com/pgschema/pgschema@latest
      - name: Generate Plan
        run: |
          pgschema plan --file schema.sql --output-human plan.txt
      - name: Comment PR with Plan
        # Posts migration plan as PR comment for review
EOF
    echo ""
    
    pause
    
    print_info "Demonstrating safety features - concurrent change detection:"
    
    # Generate a plan
    show_and_run "pgschema plan --file schemas/v3_advanced.sql --output-json plan.json" "Generating plan with fingerprint"
    
    # Simulate concurrent change
    print_info "Simulating concurrent database change..."
    show_and_run "psql -c \"CREATE TABLE concurrent_change (id SERIAL PRIMARY KEY);\"" "Making concurrent change"
    
    # Try to apply the plan - should detect concurrent change
    print_info "Trying to apply plan after concurrent change..."
    if pgschema apply --plan plan.json --auto-approve 2>&1; then
        print_warning "Plan applied (unexpected)"
    else
        print_success "pgschema detected concurrent change and prevented conflict!"
        echo "This prevents deployment disasters in production environments."
    fi
    
    # Clean up
    show_and_run "psql -c \"DROP TABLE concurrent_change;\"" "Cleaning up test table"
    
    pause
}

# Demo conclusion
demo_conclusion() {
    print_header "🎯 Demo Conclusion"
    
    echo "You've seen how pgschema transforms PostgreSQL schema management:"
    echo ""
    
    print_success "Key Benefits:"
    echo "  ✅ Declarative approach - declare what you want, not how to get there"
    echo "  ✅ Safety first - plan-review-apply workflow prevents disasters"
    echo "  ✅ PostgreSQL native - full support for advanced features"
    echo "  ✅ DevOps ready - built-in GitOps integration"
    echo "  ✅ Multi-environment - apply same schema anywhere"
    echo ""
    
    print_info "Next Steps:"
    echo "  ⭐ Star the pgschema repository: https://github.com/pgschema/pgschema"
    echo "  🚀 Try pgschema on your next project: https://www.pgschema.com/installation"
    echo "  💬 Join the community: https://discord.gg/rvgZCYuJG4"
    echo "  📖 Read the docs: https://www.pgschema.com"
    echo ""
    
    print_success "Thank you for watching the pgschema demo!"
    echo ""
    echo "Stop writing database migrations. Start declaring your desired schema state."
    echo ""
}

# Main demo flow
main() {
    clear
    
    print_header "🎬 pgschema PostgreSQL Community Demo"
    echo "Stop writing database migrations. Start declaring your desired schema state."
    echo ""
    echo "This 10-minute demo will show you:"
    echo "  🚨 Problems with traditional migrations"
    echo "  ✨ How pgschema solves them"
    echo "  🚀 Advanced PostgreSQL features"
    echo "  🔄 Production GitOps workflow"
    echo ""
    
    pause
    
    check_prerequisites
    setup_environment
    act1_traditional_disaster
    act2_pgschema_solution
    act3_advanced_features
    act4_production_workflow
    demo_conclusion
}

# Handle script arguments
case "${1:-}" in
    --auto)
        DEMO_AUTO_CONTINUE=true
        DEMO_PAUSE_DURATION=2
        ;;
    --fast)
        DEMO_AUTO_CONTINUE=true
        DEMO_PAUSE_DURATION=1
        ;;
    --help|-h)
        echo "pgschema Demo Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --auto    Run demo automatically with pauses"
        echo "  --fast    Run demo automatically with short pauses"
        echo "  --help    Show this help message"
        echo ""
        exit 0
        ;;
esac

# Run the demo
main