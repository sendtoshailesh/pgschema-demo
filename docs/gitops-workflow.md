# GitOps Workflow with pgschema

This document explains how pgschema integrates with modern GitOps practices to provide safe, automated database schema management.

## 🎯 Overview

The GitOps workflow with pgschema follows the **Plan-Review-Apply** pattern, similar to Terraform and other infrastructure-as-code tools. This ensures that all database changes are:

- **Reviewed** before being applied
- **Auditable** through version control
- **Repeatable** across environments
- **Safe** with automatic rollback on failure

## 🔄 Workflow Stages

### 1. Development Phase

Developers work on schema changes locally:

```bash
# 1. Dump current schema
pgschema dump > schema.sql

# 2. Edit schema to desired state
vim schema.sql

# 3. Test changes locally
pgschema plan --file schema.sql
pgschema apply --file schema.sql

# 4. Commit changes
git add schema.sql
git commit -m "Add product reviews feature"
git push origin feature/product-reviews
```

### 2. Pull Request Phase

When a PR is opened, GitHub Actions automatically:

1. **Generates Migration Plan**
   ```yaml
   - name: Generate Migration Plan
     run: |
       pgschema plan \
         --file schema.sql \
         --output-human plan.txt \
         --output-json plan.json
   ```

2. **Posts Plan as PR Comment**
   - Shows exactly what changes will be made
   - Includes SQL statements to be executed
   - Highlights potentially dangerous operations

3. **Runs Security Scans**
   - Checks for sensitive data in schema files
   - Validates SQL syntax
   - Analyzes performance impact

### 3. Review Process

Team members review the PR and migration plan:

- **Schema Changes**: Are the changes correct and necessary?
- **Migration Plan**: Does the plan match expectations?
- **Performance Impact**: Will changes affect production performance?
- **Safety**: Are there any dangerous operations?

### 4. Deployment Phase

After PR approval and merge:

1. **Automatic Deployment**
   ```yaml
   - name: Apply Schema Changes
     run: |
       pgschema apply --plan plan.json --auto-approve
   ```

2. **Verification**
   - Confirms schema was applied successfully
   - Runs basic validation queries
   - Creates deployment summary

3. **Rollback** (if needed)
   - Automatic rollback on failure
   - Manual rollback procedures available

## 🛡️ Safety Features

### Schema Fingerprinting

pgschema uses cryptographic fingerprinting to detect concurrent changes:

```bash
# Plan captures current schema fingerprint
pgschema plan --file schema.sql --output-json plan.json

# Apply verifies fingerprint hasn't changed
pgschema apply --plan plan.json
```

If the database schema changed between plan and apply:
```
Error: schema fingerprint mismatch detected
Expected: abc123...
Actual:   def456...

The database schema has changed since the plan was generated.
Please regenerate the plan and try again.
```

### Transaction Safety

pgschema automatically handles transactions:

- **Transactional operations**: Wrapped in single transaction with automatic rollback
- **Non-transactional operations**: Executed individually (e.g., `CREATE INDEX CONCURRENTLY`)
- **Mixed operations**: Properly separated and executed safely

### Concurrent Change Detection

Multiple developers can work safely:

1. Developer A creates plan for their changes
2. Developer B applies different changes
3. Developer A's apply fails with fingerprint mismatch
4. Developer A regenerates plan with current state
5. Changes are merged safely

## 📋 GitHub Actions Workflow

### Complete Workflow File

```yaml
name: Database Schema Management

on:
  pull_request:
    paths: ['schemas/**']
  push:
    branches: [main]
    paths: ['schemas/**']

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
          pgschema plan \
            --file schemas/schema.sql \
            --output-human plan.txt \
            --output-json plan.json
      - name: Comment PR
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('plan.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Migration Plan\n\`\`\`sql\n${plan}\n\`\`\``
            });

  apply:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Install pgschema
        run: go install github.com/pgschema/pgschema@latest
      - name: Apply Changes
        run: |
          pgschema apply \
            --file schemas/schema.sql \
            --auto-approve
```

### Workflow Features

1. **Plan Generation**: Automatic on every PR
2. **PR Comments**: Migration plans posted for review
3. **Security Scanning**: Validates schema files
4. **Performance Analysis**: Checks for expensive operations
5. **Automatic Application**: On merge to main branch
6. **Environment Protection**: Uses GitHub environments for production

## 🔧 Configuration Options

### Environment Variables

```bash
# Database connection
PGHOST=localhost
PGPORT=5432
PGDATABASE=myapp
PGUSER=deployer
PGPASSWORD=secure_password

# pgschema options
PGSCHEMA_LOCK_TIMEOUT=30s
PGSCHEMA_APPLICATION_NAME=github-actions
```

### GitHub Secrets

Store sensitive information in GitHub Secrets:

- `DB_HOST`: Database hostname
- `DB_PASSWORD`: Database password
- `DB_SSL_CERT`: SSL certificate (if required)

### Environment Protection

Use GitHub Environments for additional safety:

```yaml
environment: production
```

This enables:
- Required reviewers
- Deployment delays
- Environment-specific secrets

## 🚀 Multi-Environment Deployment

### Development → Staging → Production

```yaml
jobs:
  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    environment: staging
    steps:
      - name: Deploy to Staging
        run: |
          pgschema apply \
            --host ${{ secrets.STAGING_DB_HOST }} \
            --file schemas/schema.sql \
            --auto-approve

  deploy-production:
    if: github.ref == 'refs/heads/main'
    environment: production
    needs: [deploy-staging]
    steps:
      - name: Deploy to Production
        run: |
          pgschema apply \
            --host ${{ secrets.PROD_DB_HOST }} \
            --file schemas/schema.sql \
            --auto-approve
```

### Multi-Tenant Deployment

Deploy to multiple tenant databases:

```yaml
- name: Deploy to All Tenants
  run: |
    for tenant in tenant1 tenant2 tenant3; do
      echo "Deploying to $tenant..."
      pgschema apply \
        --host ${{ secrets.DB_HOST }} \
        --schema $tenant \
        --file schemas/schema.sql \
        --auto-approve
    done
```

## 📊 Monitoring and Alerting

### Deployment Notifications

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: |
      Schema deployment ${{ job.status }}
      Commit: ${{ github.sha }}
      Changes: ${{ steps.plan.outputs.summary }}
```

### Metrics Collection

```yaml
- name: Record Deployment Metrics
  run: |
    curl -X POST https://metrics.company.com/deployments \
      -d "service=database&status=success&duration=$SECONDS"
```

## 🛠️ Troubleshooting

### Common Issues

1. **Fingerprint Mismatch**
   ```
   Solution: Regenerate plan with current database state
   ```

2. **Lock Timeout**
   ```
   Solution: Increase lock timeout or retry during low-traffic period
   ```

3. **Permission Denied**
   ```
   Solution: Ensure database user has necessary privileges
   ```

### Rollback Procedures

1. **Automatic Rollback**: pgschema rolls back failed transactions automatically
2. **Manual Rollback**: Revert to previous schema file and deploy
3. **Point-in-Time Recovery**: Use database backup for major issues

### Debugging

Enable debug logging:

```yaml
- name: Apply with Debug
  run: |
    pgschema apply \
      --file schema.sql \
      --debug \
      --auto-approve
```

## 📚 Best Practices

### 1. Schema File Organization

```
schemas/
├── schema.sql              # Main schema file
├── migrations/
│   ├── 2024-01-15-add-reviews.sql
│   └── 2024-01-20-add-categories.sql
└── rollbacks/
    ├── 2024-01-15-rollback.sql
    └── 2024-01-20-rollback.sql
```

### 2. Commit Messages

Use conventional commits for schema changes:

```
feat(schema): add product reviews table
fix(schema): correct user email constraint
perf(schema): add index for order queries
```

### 3. PR Templates

Create PR template for schema changes:

```markdown
## Schema Changes

### What changed?
- [ ] Added new tables
- [ ] Modified existing tables
- [ ] Added indexes
- [ ] Added functions/triggers

### Impact Assessment
- [ ] Performance impact analyzed
- [ ] Backward compatibility confirmed
- [ ] Data migration plan (if needed)

### Testing
- [ ] Tested locally
- [ ] Reviewed migration plan
- [ ] Considered rollback procedure
```

### 4. Review Checklist

- ✅ Migration plan matches expectations
- ✅ No dangerous operations without justification
- ✅ Performance impact acceptable
- ✅ Backward compatibility maintained
- ✅ Rollback plan available

## 🎯 Benefits

### For Developers
- **Simplified workflow**: No manual migration writing
- **Local testing**: Easy to test changes locally
- **Version control**: Schema changes tracked in Git

### For Teams
- **Collaboration**: Clear review process for schema changes
- **Safety**: Multiple safety checks before deployment
- **Visibility**: All changes visible in PR comments

### For Operations
- **Automation**: Fully automated deployment pipeline
- **Reliability**: Consistent deployments across environments
- **Monitoring**: Built-in deployment tracking and alerting

This GitOps workflow with pgschema provides enterprise-grade database schema management that scales with your team and infrastructure.