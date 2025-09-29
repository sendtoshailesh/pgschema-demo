# Traditional Migration Approach

This directory demonstrates the problems with traditional imperative database migrations.

## The Problem

Traditional migration tools require developers to write sequential migration files that describe **how** to change the database step-by-step, rather than declaring **what** the final state should be.

## Migration Files

1. **migration_001_create_users.sql** - Creates users table
2. **migration_002_create_products.sql** - Creates products table  
3. **migration_003_create_orders.sql** - Creates orders and order_items tables
4. **migration_004_add_reviews_BROKEN.sql** - ⚠️ **INTENTIONALLY BROKEN** migration

## The Disaster Scenario

Run the disaster simulation to see what happens when migrations fail:

```bash
cd traditional
./disaster.sh
```

## Problems Demonstrated

### 1. Manual Migration Writing
- Developers must write CREATE, ALTER, DROP statements for every change
- Easy to make syntax errors or forget constraints
- Complex dependency management between objects

### 2. Schema Drift
- Different environments may have different migration histories
- Failed migrations leave database in inconsistent state
- No easy way to compare actual schema with intended schema

### 3. Failed Migration Recovery
- Partial application of changes
- No automatic rollback mechanism
- Manual investigation and cleanup required
- Production downtime while fixing issues

### 4. Environment Inconsistencies
- Dev, staging, and prod can have different schema states
- Difficult to ensure all environments are synchronized
- Complex deployment orchestration required

## What the Broken Migration Shows

The `migration_004_add_reviews_BROKEN.sql` file contains intentional errors:

1. **Missing NOT NULL constraints** on required fields
2. **Index on non-existent column** (title)
3. **Foreign key to non-existent table** (categories)
4. **Syntax error in function** (missing $$ delimiter)
5. **Trigger on non-existent column** (updated_at)

When this migration runs:
- Some statements succeed (table creation)
- Others fail (indexes, constraints, functions)
- Database is left in inconsistent state
- Manual cleanup required

## Recovery Process (Traditional Way)

1. **Investigate** what succeeded vs failed
2. **Write rollback scripts** to undo partial changes
3. **Fix the broken migration** file
4. **Re-run migrations** in correct order
5. **Validate** database consistency
6. **Coordinate** across all environments

**Estimated time**: 2-4 hours  
**Risk**: High (production downtime)  
**Complexity**: Very high

## How pgschema Solves This

Instead of imperative migrations, pgschema uses a declarative approach:

1. **Declare desired state** in schema.sql
2. **Generate plan** showing exactly what will change
3. **Review changes** before applying
4. **Apply safely** with automatic rollback on failure
5. **Detect conflicts** with schema fingerprinting

See the main demo to learn how pgschema prevents these disasters!