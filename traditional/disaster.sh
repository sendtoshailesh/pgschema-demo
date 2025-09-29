#!/bin/bash

# Traditional Migration Disaster Simulation
# This script demonstrates what happens when traditional migrations fail

set -e

echo "🚨 TRADITIONAL MIGRATION DISASTER SIMULATION 🚨"
echo "================================================"
echo ""
echo "This demonstrates the problems with traditional imperative migrations:"
echo "- Manual migration writing"
echo "- Schema drift between environments"
echo "- Failed migrations leaving database in broken state"
echo "- Complex rollback procedures"
echo ""

# Database connection settings
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=demo
export PGUSER=demo
export PGPASSWORD=demo

# Function to run SQL and show output
run_migration() {
    local migration_file=$1
    local migration_name=$(basename "$migration_file" .sql)
    
    echo "📝 Running: $migration_name"
    echo "----------------------------------------"
    
    if psql -f "$migration_file" 2>&1; then
        echo "✅ $migration_name completed successfully"
    else
        echo "❌ $migration_name FAILED!"
        echo ""
        echo "💥 DISASTER: Migration failed and database is now in inconsistent state!"
        echo ""
        echo "Problems:"
        echo "- Some tables created, others missing"
        echo "- Partial schema changes applied"
        echo "- No automatic rollback"
        echo "- Manual cleanup required"
        echo "- Production downtime while fixing"
        echo ""
        return 1
    fi
    echo ""
}

# Function to show database state
show_database_state() {
    echo "📊 Current Database State:"
    echo "----------------------------------------"
    
    echo "Tables:"
    psql -c "\dt" 2>/dev/null || echo "Error querying tables"
    
    echo ""
    echo "Indexes:"
    psql -c "\di" 2>/dev/null || echo "Error querying indexes"
    
    echo ""
    echo "Functions:"
    psql -c "\df" 2>/dev/null || echo "Error querying functions"
    
    echo ""
}

# Clean database first
echo "🧹 Cleaning database..."
psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1

echo "🏁 Starting traditional migration sequence..."
echo ""

# Run successful migrations first
run_migration "migration_001_create_users.sql"
run_migration "migration_002_create_products.sql"
run_migration "migration_003_create_orders.sql"

echo "✅ First 3 migrations completed successfully"
echo ""
echo "📊 Database state after successful migrations:"
show_database_state

echo "⚠️  Now attempting problematic migration 004..."
echo ""

# This will fail and demonstrate the disaster
if ! run_migration "migration_004_add_reviews_BROKEN.sql"; then
    echo ""
    echo "💀 MIGRATION DISASTER OCCURRED!"
    echo ""
    echo "📊 Database state after failed migration:"
    show_database_state
    
    echo "🔍 What went wrong:"
    echo "- reviews table was created but with missing constraints"
    echo "- Some indexes failed to create"
    echo "- Function creation failed due to syntax error"
    echo "- Trigger creation failed"
    echo "- Database is now in inconsistent state"
    echo ""
    
    echo "🛠️  Traditional recovery process would require:"
    echo "1. Manual investigation of what succeeded/failed"
    echo "2. Writing custom rollback scripts"
    echo "3. Fixing the broken migration"
    echo "4. Re-running migrations"
    echo "5. Validating database consistency"
    echo "6. Coordinating across multiple environments"
    echo ""
    
    echo "⏰ Estimated recovery time: 2-4 hours"
    echo "💸 Cost of downtime: $$$$$"
    echo ""
    
    echo "🎯 This is exactly what pgschema prevents!"
    echo "   - Declarative approach avoids migration sequencing issues"
    echo "   - Plan-review-apply workflow catches errors before execution"
    echo "   - Transaction-aware execution with automatic rollback"
    echo "   - Schema fingerprinting prevents concurrent changes"
    echo ""
fi

echo "🏁 Disaster simulation complete!"
echo ""
echo "Next: See how pgschema solves these problems..."