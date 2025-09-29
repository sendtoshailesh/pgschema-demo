#!/bin/bash

# Traditional vs pgschema Comparison Demo
# Side-by-side comparison of traditional migrations vs pgschema approach

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
    echo -e "${BLUE}⚖️  $1${NC}"
    echo -e "${BLUE}$(echo "$1" | sed 's/./=/g')${NC}"
    echo ""
}

print_traditional() {
    echo -e "${RED}❌ Traditional Approach:${NC} $1"
}

print_pgschema() {
    echo -e "${GREEN}✅ pgschema Approach:${NC} $1"
}

print_comparison() {
    echo -e "${PURPLE}🔍 Comparison:${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

show_and_run() {
    echo -e "${YELLOW}$ $1${NC}"
    eval "$1"
    echo ""
}

pause() {
    echo ""
    read -p "Press Enter to continue..."
    echo ""
}

# Compare initial setup
compare_initial_setup() {
    print_header "Initial Setup Comparison"
    
    print_traditional "Write multiple migration files manually"
    echo "  migration_001_create_users.sql"
    echo "  migration_002_create_products.sql"
    echo "  migration_003_create_orders.sql"
    echo "  migration_004_create_order_items.sql"
    echo ""
    
    print_pgschema "Declare desired state in single file"
    echo "  schema.sql (contains complete desired schema)"
    echo ""
    
    print_comparison "Traditional requires 4+ files, pgschema needs just 1"
    
    pause
}

# Compare adding new features
compare_adding_features() {
    print_header "Adding New Features Comparison"
    
    # Setup clean database
    psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1
    pgschema apply --file schemas/v1_initial.sql --auto-approve >/dev/null 2>&1
    
    print_traditional "Write new migration file with ALTER statements"
    echo "  migration_005_add_reviews.sql:"
    echo "  CREATE TABLE reviews (...);"
    echo "  ALTER TABLE reviews ADD CONSTRAINT ...;"
    echo "  CREATE INDEX idx_reviews_product_id ON reviews(product_id);"
    echo "  CREATE INDEX idx_reviews_rating ON reviews(rating);"
    echo ""
    
    print_pgschema "Edit schema file to include reviews table"
    echo "  Just add the reviews table definition to schema.sql"
    echo ""
    
    print_info "Let's see pgschema in action:"
    show_and_run "pgschema plan --file schemas/v2_with_reviews.sql"
    
    print_comparison "pgschema automatically generates the migration steps!"
    
    pause
}

# Compare schema drift detection
compare_schema_drift() {
    print_header "Schema Drift Detection"
    
    print_traditional "No built-in drift detection"
    echo "  • Database can diverge from migration history"
    echo "  • Manual comparison required (pg_dump + diff)"
    echo "  • Difficult to know actual vs expected state"
    echo ""
    
    print_pgschema "Automatic drift detection with fingerprinting"
    echo "  • Schema fingerprint captured during planning"
    echo "  • Concurrent changes detected automatically"
    echo "  • Prevents applying outdated plans"
    echo ""
    
    print_info "Demonstrating concurrent change detection:"
    
    # Generate a plan
    show_and_run "pgschema plan --file schemas/v2_with_reviews.sql --output-json drift_plan.json >/dev/null 2>&1"
    
    # Make concurrent change
    show_and_run "psql -c \"CREATE TABLE concurrent_change (id SERIAL PRIMARY KEY);\" >/dev/null 2>&1"
    
    # Try to apply plan
    echo -e "${YELLOW}$ pgschema apply --plan drift_plan.json --auto-approve${NC}"
    if pgschema apply --plan drift_plan.json --auto-approve 2>&1 | grep -q "fingerprint\|changed"; then
        print_pgschema "Detected concurrent change and prevented conflict!"
    else
        echo "Would normally detect fingerprint mismatch"
    fi
    echo ""
    
    # Cleanup
    psql -c "DROP TABLE IF EXISTS concurrent_change;" >/dev/null 2>&1
    rm -f drift_plan.json
    
    print_comparison "pgschema prevents deployment disasters through automatic conflict detection"
    
    pause
}

# Compare rollback procedures
compare_rollbacks() {
    print_header "Rollback Procedures"
    
    print_traditional "Manual rollback migrations required"
    echo "  • Must write separate down-migration for each up-migration"
    echo "  • Complex to reverse schema changes correctly"
    echo "  • Risk of data loss if not carefully planned"
    echo "  • No automatic rollback on failure"
    echo ""
    
    print_pgschema "Automatic transaction rollback + declarative recovery"
    echo "  • Automatic rollback on transaction failures"
    echo "  • Revert to previous schema file for major rollbacks"
    echo "  • pgschema generates steps to reach previous state"
    echo "  • Built-in safety mechanisms"
    echo ""
    
    print_info "Demonstrating transaction safety:"
    
    # Apply a schema that will work
    pgschema apply --file schemas/v2_with_reviews.sql --auto-approve >/dev/null 2>&1
    
    echo "If a migration fails, pgschema automatically rolls back the transaction"
    echo "Database remains in consistent state"
    echo ""
    
    print_comparison "pgschema provides automatic safety, traditional requires manual planning"
    
    pause
}

# Compare multi-environment deployment
compare_multi_environment() {
    print_header "Multi-Environment Deployment"
    
    print_traditional "Complex migration state management"
    echo "  • Track which migrations applied to each environment"
    echo "  • Different environments may need different migration paths"
    echo "  • Manual synchronization between dev/staging/prod"
    echo "  • Migration history can diverge"
    echo ""
    
    print_pgschema "Same desired state applied everywhere"
    echo "  • Single schema file represents desired state"
    echo "  • pgschema determines migration path for each environment"
    echo "  • Consistent end state across all environments"
    echo "  • No migration history to track"
    echo ""
    
    print_info "Demonstrating multi-environment consistency:"
    
    echo "Same schema file can be applied to any database:"
    echo "  pgschema apply --host dev-db --file schema.sql"
    echo "  pgschema apply --host staging-db --file schema.sql"
    echo "  pgschema apply --host prod-db --file schema.sql"
    echo ""
    echo "Each environment gets the same end result, regardless of starting state"
    echo ""
    
    print_comparison "pgschema eliminates environment synchronization complexity"
    
    pause
}

# Compare team collaboration
compare_team_collaboration() {
    print_header "Team Collaboration"
    
    print_traditional "Migration conflicts and coordination issues"
    echo "  • Developers must coordinate migration numbering"
    echo "  • Merge conflicts in migration history"
    echo "  • Difficult to review migration impact"
    echo "  • No clear preview of changes"
    echo ""
    
    print_pgschema "GitOps workflow with clear review process"
    echo "  • Schema changes reviewed like application code"
    echo "  • Clear migration plans posted in PRs"
    echo "  • No coordination needed - declarative approach"
    echo "  • Team can see exactly what will change"
    echo ""
    
    print_info "Example PR review process:"
    echo "1. Developer edits schema.sql"
    echo "2. GitHub Actions generates migration plan"
    echo "3. Plan posted as PR comment for review"
    echo "4. Team reviews and approves"
    echo "5. Merge triggers automatic deployment"
    echo ""
    
    print_comparison "pgschema enables modern code review practices for database changes"
    
    pause
}

# Compare PostgreSQL feature support
compare_postgresql_features() {
    print_header "PostgreSQL Feature Support"
    
    print_traditional "Limited feature support in most tools"
    echo "  • ORMs often don't support advanced PostgreSQL features"
    echo "  • Custom types, domains, functions require manual SQL"
    echo "  • Row-level security policies not supported"
    echo "  • Advanced indexing strategies require custom migrations"
    echo ""
    
    print_pgschema "Comprehensive PostgreSQL feature support"
    echo "  • Native support for custom types, domains, functions"
    echo "  • Row-level security policies managed declaratively"
    echo "  • Advanced indexing (GIN, partial, functional)"
    echo "  • Materialized views, triggers, constraints"
    echo ""
    
    print_info "Demonstrating advanced feature support:"
    
    # Apply advanced schema
    pgschema apply --file schemas/v3_advanced.sql --auto-approve >/dev/null 2>&1
    
    show_and_run "psql -c \"SELECT 'pending'::order_status;\""
    show_and_run "psql -c \"SELECT update_timestamp();\""
    show_and_run "psql -c \"SELECT COUNT(*) FROM product_stats;\""
    
    print_comparison "pgschema leverages PostgreSQL's full power, traditional tools are limited"
    
    pause
}

# Compare maintenance overhead
compare_maintenance() {
    print_header "Maintenance Overhead"
    
    print_traditional "High maintenance overhead"
    echo "  • Migration files accumulate over time (100s or 1000s)"
    echo "  • Difficult to understand current schema state"
    echo "  • Complex dependency tracking between migrations"
    echo "  • Historical migrations may become obsolete"
    echo ""
    
    print_pgschema "Low maintenance overhead"
    echo "  • Single source of truth (schema file)"
    echo "  • Easy to understand current state"
    echo "  • Automatic dependency resolution"
    echo "  • No historical baggage"
    echo ""
    
    print_info "Schema file comparison:"
    echo "Traditional: 50+ migration files to understand current state"
    echo "pgschema: 1 schema file shows complete current state"
    echo ""
    
    print_comparison "pgschema dramatically reduces long-term maintenance burden"
    
    pause
}

# Summary comparison
show_summary() {
    print_header "Summary: Traditional vs pgschema"
    
    echo -e "${BLUE}Aspect${NC}                    ${RED}Traditional${NC}              ${GREEN}pgschema${NC}"
    echo "─────────────────────────────────────────────────────────────────────"
    echo -e "Approach                   ${RED}Imperative (how)${NC}         ${GREEN}Declarative (what)${NC}"
    echo -e "Migration Writing          ${RED}Manual${NC}                   ${GREEN}Automatic${NC}"
    echo -e "Schema Drift Detection     ${RED}Manual${NC}                   ${GREEN}Automatic${NC}"
    echo -e "Rollback Procedures        ${RED}Manual${NC}                   ${GREEN}Automatic${NC}"
    echo -e "Multi-Environment          ${RED}Complex${NC}                  ${GREEN}Simple${NC}"
    echo -e "Team Collaboration         ${RED}Difficult${NC}                ${GREEN}GitOps Ready${NC}"
    echo -e "PostgreSQL Features        ${RED}Limited${NC}                  ${GREEN}Comprehensive${NC}"
    echo -e "Maintenance Overhead       ${RED}High${NC}                     ${GREEN}Low${NC}"
    echo -e "Production Safety          ${RED}Manual Checks${NC}            ${GREEN}Built-in Safety${NC}"
    echo -e "Learning Curve             ${RED}High${NC}                     ${GREEN}Low${NC}"
    echo ""
    
    print_info "Key Takeaway:"
    echo "pgschema transforms database schema management from a manual,"
    echo "error-prone process into a reliable, automated workflow that"
    echo "integrates seamlessly with modern development practices."
    echo ""
    
    print_pgschema "Stop writing database migrations. Start declaring your desired schema state."
}

# Main comparison demo
main() {
    clear
    
    print_header "Traditional vs pgschema: Side-by-Side Comparison"
    echo "This demonstration compares traditional database migration approaches"
    echo "with pgschema's declarative schema management."
    echo ""
    
    pause
    
    compare_initial_setup
    compare_adding_features
    compare_schema_drift
    compare_rollbacks
    compare_multi_environment
    compare_team_collaboration
    compare_postgresql_features
    compare_maintenance
    show_summary
    
    print_header "Comparison Complete"
    
    print_info "Ready to try pgschema?"
    echo "  🚀 Installation: https://www.pgschema.com/installation"
    echo "  📖 Documentation: https://www.pgschema.com"
    echo "  ⭐ GitHub: https://github.com/pgschema/pgschema"
    echo "  💬 Community: https://discord.gg/rvgZCYuJG4"
    echo ""
    
    print_pgschema "Transform your PostgreSQL schema management today!"
}

main