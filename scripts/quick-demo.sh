#!/bin/bash

# Quick pgschema Demo (5 minutes)
# Condensed version for time-constrained presentations

set -e

# Colors for output
GREEN='\033[0;32m'
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
    echo -e "${BLUE}🎬 $1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${CYAN}💡 $1${NC}"
}

show_and_run() {
    echo -e "${PURPLE}$ $1${NC}"
    eval "$1"
    echo ""
}

pause_short() {
    sleep 2
}

main() {
    clear
    
    print_header "pgschema Quick Demo (5 minutes)"
    echo "Stop writing database migrations. Start declaring your desired schema state."
    echo ""
    
    # Setup
    print_info "Setting up clean database..."
    show_and_run 'psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1'
    pause_short
    
    # Act 1: The Problem (30 seconds)
    print_header "The Problem: Traditional Migrations Fail"
    echo "Traditional approach requires writing sequential migration files:"
    echo "  migration_001.sql → migration_002.sql → migration_003.sql"
    echo ""
    echo "Problems:"
    echo "  ❌ Manual migration writing"
    echo "  ❌ Schema drift between environments"
    echo "  ❌ Failed migrations leave database broken"
    echo ""
    pause_short
    
    # Act 2: The Solution (2 minutes)
    print_header "The Solution: pgschema Declarative Approach"
    
    print_info "Step 1: Apply initial schema"
    show_and_run "pgschema apply --file schemas/v1_initial.sql --auto-approve"
    
    print_info "Step 2: See what we created"
    show_and_run "pgschema dump | head -15"
    
    print_info "Step 3: Add reviews feature - just edit the desired state"
    show_and_run "pgschema plan --file schemas/v2_with_reviews.sql"
    
    print_success "pgschema automatically figured out what changes are needed!"
    pause_short
    
    print_info "Step 4: Apply changes safely"
    show_and_run "pgschema apply --file schemas/v2_with_reviews.sql --auto-approve"
    
    # Act 3: Advanced Features (1.5 minutes)
    print_header "Advanced PostgreSQL Features"
    echo "pgschema supports advanced PostgreSQL features:"
    echo "  ✅ Custom types, domains, functions"
    echo "  ✅ Triggers, materialized views, RLS"
    echo "  ✅ Advanced indexing strategies"
    echo ""
    
    print_info "Adding advanced features..."
    show_and_run "pgschema plan --file schemas/v3_advanced.sql | head -10"
    show_and_run "pgschema apply --file schemas/v3_advanced.sql --auto-approve >/dev/null 2>&1"
    
    print_info "Testing advanced features:"
    show_and_run "psql -c \"SELECT 'pending'::order_status;\""
    show_and_run "psql -c \"SELECT update_timestamp();\""
    
    # Act 4: Production Workflow (1 minute)
    print_header "Production GitOps Workflow"
    echo "pgschema integrates with modern DevOps:"
    echo "  🔄 Plan generation in CI (Pull Requests)"
    echo "  👥 Team review process"
    echo "  🚀 Automatic deployment in CD"
    echo "  🛡️  Safety features (fingerprinting, rollbacks)"
    echo ""
    
    print_info "Concurrent change detection demo:"
    show_and_run "pgschema plan --file schemas/v3_advanced.sql --output-json plan.json >/dev/null 2>&1"
    show_and_run "psql -c \"CREATE TABLE concurrent_test (id SERIAL);\" >/dev/null 2>&1"
    
    echo -e "${PURPLE}$ pgschema apply --plan plan.json --auto-approve${NC}"
    if pgschema apply --plan plan.json --auto-approve 2>&1 | grep -q "fingerprint"; then
        print_success "pgschema detected concurrent change and prevented conflict!"
    else
        echo "Plan would normally fail due to concurrent changes"
    fi
    
    # Cleanup
    show_and_run "psql -c \"DROP TABLE IF EXISTS concurrent_test;\" >/dev/null 2>&1"
    show_and_run "rm -f plan.json"
    
    # Conclusion
    print_header "Key Benefits"
    echo "✅ Declarative - declare what you want, not how to get there"
    echo "✅ Safe - plan-review-apply prevents disasters"
    echo "✅ PostgreSQL native - full feature support"
    echo "✅ DevOps ready - GitOps integration"
    echo "✅ Multi-environment - same schema anywhere"
    echo ""
    
    print_success "Demo complete! Try pgschema on your next project."
    echo ""
    echo "🔗 Links:"
    echo "  ⭐ GitHub: https://github.com/pgschema/pgschema"
    echo "  📖 Docs: https://www.pgschema.com"
    echo "  💬 Discord: https://discord.gg/rvgZCYuJG4"
}

main