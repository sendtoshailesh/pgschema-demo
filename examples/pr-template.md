# Pull Request Template for Schema Changes

Use this template when creating pull requests that modify database schemas.

## 📋 Schema Changes Summary

### What changed?
- [ ] Added new tables
- [ ] Modified existing tables  
- [ ] Added/modified indexes
- [ ] Added/modified functions or triggers
- [ ] Added/modified views or materialized views
- [ ] Added/modified constraints
- [ ] Added/modified custom types or domains
- [ ] Other: _______________

### Files Modified
- [ ] `schemas/v1_initial.sql`
- [ ] `schemas/v2_with_reviews.sql`
- [ ] `schemas/v3_advanced.sql`
- [ ] `examples/showcase_features.sql`
- [ ] Other: _______________

## 🎯 Purpose

**Why are these changes needed?**

<!-- Describe the business requirement or technical need -->

**What problem does this solve?**

<!-- Explain the problem being addressed -->

## 📊 Impact Assessment

### Performance Impact
- [ ] No performance impact expected
- [ ] Minor performance impact (< 1 second operations)
- [ ] Moderate performance impact (1-10 second operations)
- [ ] Major performance impact (> 10 second operations)
- [ ] Performance impact unknown - needs analysis

**Details:**
<!-- Describe any performance considerations -->

### Backward Compatibility
- [ ] Fully backward compatible
- [ ] Backward compatible with minor considerations
- [ ] Breaking changes - migration required
- [ ] Breaking changes - application updates required

**Details:**
<!-- Describe compatibility considerations -->

### Data Migration
- [ ] No data migration required
- [ ] Automatic data migration (handled by pgschema)
- [ ] Manual data migration required
- [ ] Data migration script provided

**Migration Plan:**
<!-- Describe data migration approach if needed -->

## 🧪 Testing

### Local Testing
- [ ] Applied schema changes locally
- [ ] Verified pgschema plan output
- [ ] Tested application functionality
- [ ] Ran automated tests

### Migration Plan Review
- [ ] Reviewed generated migration plan
- [ ] Confirmed SQL statements are correct
- [ ] Verified dependency ordering
- [ ] Checked for dangerous operations

### Rollback Plan
- [ ] Rollback procedure identified
- [ ] Rollback tested locally
- [ ] Data backup strategy confirmed
- [ ] Rollback automation available

## 🔒 Security Considerations

- [ ] No sensitive data in schema files
- [ ] Row-level security policies reviewed
- [ ] Access permissions appropriate
- [ ] Audit logging considerations addressed

## 📝 Additional Notes

### Dependencies
<!-- List any dependencies on other PRs, deployments, or changes -->

### Deployment Timing
- [ ] Can be deployed anytime
- [ ] Should be deployed during low-traffic period
- [ ] Requires maintenance window
- [ ] Coordinate with application deployment

### Documentation Updates
- [ ] No documentation updates needed
- [ ] API documentation updated
- [ ] Database documentation updated
- [ ] Runbook/procedures updated

## ✅ Pre-merge Checklist

- [ ] Migration plan reviewed and approved
- [ ] Performance impact acceptable
- [ ] Security implications considered
- [ ] Rollback plan available
- [ ] Tests passing
- [ ] Documentation updated (if needed)

## 🤝 Reviewers

**Required Reviewers:**
- [ ] Database Administrator
- [ ] Senior Developer
- [ ] DevOps Engineer (for production changes)

**Optional Reviewers:**
- [ ] Product Owner (for feature changes)
- [ ] Security Team (for security-related changes)

---

## 📋 Migration Plan Preview

<!-- The GitHub Actions workflow will automatically add the migration plan here -->

**Note:** The migration plan will be automatically generated and posted as a comment when this PR is created.

## 🚀 Deployment Instructions

1. **Review the migration plan** posted by the GitHub Actions bot
2. **Verify the changes** match your expectations
3. **Approve the PR** if everything looks correct
4. **Merge the PR** to trigger automatic deployment

The schema changes will be automatically applied to the database after merge.

---

**Questions or concerns?** Tag @database-team or @devops-team for assistance.