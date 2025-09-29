# Troubleshooting Guide

This guide helps you resolve common issues when running the pgschema demo.

## 🔧 Common Issues

### Database Connection Issues

#### PostgreSQL Container Not Starting
```bash
# Check if Docker is running
docker info

# Check container status
docker ps -a | grep pgschema-demo-db

# View container logs
docker-compose logs postgres

# Common solutions:
# 1. Port 5432 already in use
sudo lsof -i :5432  # Check what's using port 5432
docker-compose down  # Stop existing containers
docker-compose up -d  # Restart

# 2. Insufficient disk space
df -h  # Check disk space
docker system prune  # Clean up unused Docker resources

# 3. Permission issues
sudo chown -R $USER:$USER .  # Fix file permissions
```

#### Connection Refused Errors
```bash
# Wait for PostgreSQL to fully start
sleep 10
pg_isready -h localhost -p 5432 -U demo

# If still failing, check logs
docker-compose logs postgres | tail -20

# Reset database completely
make clean && make setup
```

#### Authentication Failures
```bash
# Verify environment variables
echo $PGHOST $PGPORT $PGDATABASE $PGUSER $PGPASSWORD

# Use .env file for consistency
cp .env.example .env
# Edit .env with correct values

# Test connection manually
psql -h localhost -p 5432 -U demo -d demo -c "SELECT 1;"
```

### pgschema Installation Issues

#### Go Not Installed or Wrong Version
```bash
# Check Go version (need 1.21+)
go version

# Install Go on macOS
brew install go

# Install Go on Ubuntu/Debian
sudo apt update
sudo apt install golang-go

# Install Go on CentOS/RHEL
sudo yum install golang

# Verify GOPATH and PATH
echo $GOPATH
echo $PATH | grep $(go env GOPATH)/bin
```

#### pgschema Command Not Found
```bash
# Install pgschema
go install github.com/pgschema/pgschema@latest

# Add Go bin to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH=$PATH:$(go env GOPATH)/bin

# Reload shell
source ~/.bashrc  # or source ~/.zshrc

# Verify installation
pgschema --version
```

#### Permission Denied on pgschema Binary
```bash
# Check binary location
which pgschema

# Fix permissions
chmod +x $(which pgschema)

# Or reinstall
go clean -cache
go install github.com/pgschema/pgschema@latest
```

### Demo Script Issues

#### Script Permission Denied
```bash
# Make all scripts executable
chmod +x demo.sh
chmod +x scripts/*.sh
chmod +x traditional/disaster.sh
chmod +x examples/test_features.sh

# Or use make commands which handle permissions
make demo
```

#### Script Fails with "Command Not Found"
```bash
# Check required commands are available
command -v docker || echo "Docker not found"
command -v docker-compose || echo "Docker Compose not found"
command -v go || echo "Go not found"
command -v pgschema || echo "pgschema not found"
command -v psql || echo "psql not found (install postgresql-client)"

# Install missing dependencies
# On macOS:
brew install docker docker-compose go postgresql

# On Ubuntu/Debian:
sudo apt update
sudo apt install docker.io docker-compose golang-go postgresql-client

# On CentOS/RHEL:
sudo yum install docker docker-compose golang postgresql
```

#### Demo Hangs or Freezes
```bash
# Check if waiting for user input
# Press Enter if demo is paused

# Check if database is responsive
pg_isready -h localhost -p 5432 -U demo

# Kill and restart if needed
pkill -f demo.sh
make clean && make setup
```

### Schema Application Issues

#### Schema File Not Found
```bash
# Check file exists
ls -la schemas/
ls -la examples/

# Use correct relative paths
pgschema apply --file schemas/v1_initial.sql --auto-approve
# Not: pgschema apply --file v1_initial.sql
```

#### SQL Syntax Errors
```bash
# Validate schema file syntax
pgschema plan --file schemas/v1_initial.sql --output-json /dev/null

# Check for common issues:
# 1. Missing semicolons
# 2. Incorrect quotes (use single quotes for strings)
# 3. Reserved keywords without quotes
# 4. Invalid PostgreSQL syntax

# Test SQL directly
psql -c "$(cat schemas/v1_initial.sql)"
```

#### Migration Plan Errors
```bash
# Check current database state
pgschema dump

# Reset to clean state if needed
psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# Apply schemas in order
pgschema apply --file schemas/v1_initial.sql --auto-approve
pgschema apply --file schemas/v2_with_reviews.sql --auto-approve
```

### Performance Issues

#### Slow Database Operations
```bash
# Check system resources
top
df -h

# Increase PostgreSQL memory (edit docker-compose.yml)
services:
  postgres:
    command: postgres -c shared_buffers=256MB -c max_connections=200

# Restart with new settings
docker-compose down
docker-compose up -d
```

#### Demo Takes Too Long
```bash
# Use quick demo for faster experience
./scripts/quick-demo.sh

# Or run in auto mode
./demo.sh --auto

# Skip interactive pauses
export DEMO_AUTO_CONTINUE=true
./demo.sh
```

## 🐛 Debugging Tips

### Enable Debug Mode
```bash
# Enable pgschema debug output
pgschema --debug plan --file schemas/v1_initial.sql

# Enable verbose Docker output
docker-compose up -d --verbose

# Enable shell debug mode
bash -x demo.sh
```

### Check Logs
```bash
# PostgreSQL logs
docker-compose logs postgres

# System logs (Linux)
journalctl -u docker

# macOS logs
log show --predicate 'process == "Docker"' --last 1h
```

### Verify Environment
```bash
# Run environment check
make status

# Or manual checks
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker-compose --version)"
echo "Go: $(go version)"
echo "pgschema: $(pgschema --version 2>/dev/null || echo 'not installed')"
echo "PostgreSQL client: $(psql --version)"
```

## 🔍 Advanced Troubleshooting

### Network Issues
```bash
# Check Docker network
docker network ls
docker network inspect pgschema-demo_default

# Test network connectivity
docker run --rm --network pgschema-demo_default postgres:17 \
  pg_isready -h postgres -p 5432 -U demo
```

### Resource Constraints
```bash
# Check Docker resource limits
docker stats

# Increase Docker memory/CPU limits in Docker Desktop
# Or use docker-compose resource limits:
services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
```

### File System Issues
```bash
# Check file permissions
ls -la schemas/
ls -la scripts/

# Fix ownership issues
sudo chown -R $USER:$USER .

# Check for special characters in filenames
find . -name "*[^a-zA-Z0-9._-]*"
```

## 📞 Getting Help

If you're still having issues:

### Community Support
- **Discord**: [Join our community](https://discord.gg/rvgZCYuJG4)
- **GitHub Issues**: [Report bugs](https://github.com/pgschema/pgschema/issues)
- **Stack Overflow**: Tag questions with `pgschema`

### Information to Include
When asking for help, please include:

```bash
# System information
uname -a
docker --version
docker-compose --version
go version
pgschema --version

# Error messages
# Copy the exact error message you're seeing

# Steps to reproduce
# What commands did you run?
# What did you expect to happen?
# What actually happened?

# Environment details
env | grep PG
docker ps
docker-compose logs postgres | tail -20
```

### Quick Diagnostic Script
```bash
#!/bin/bash
# diagnostic.sh - Collect system information

echo "=== pgschema Demo Diagnostics ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Working Directory: $(pwd)"
echo ""

echo "=== System Information ==="
uname -a
echo ""

echo "=== Docker Information ==="
docker --version
docker-compose --version
docker ps
echo ""

echo "=== Go Information ==="
go version
echo "GOPATH: $GOPATH"
echo "PATH: $PATH"
echo ""

echo "=== pgschema Information ==="
pgschema --version 2>/dev/null || echo "pgschema not found"
which pgschema 2>/dev/null || echo "pgschema not in PATH"
echo ""

echo "=== PostgreSQL Client ==="
psql --version 2>/dev/null || echo "psql not found"
pg_isready -h localhost -p 5432 -U demo 2>/dev/null || echo "Database not ready"
echo ""

echo "=== Environment Variables ==="
env | grep PG | sort
echo ""

echo "=== File Permissions ==="
ls -la demo.sh 2>/dev/null || echo "demo.sh not found"
ls -la schemas/ 2>/dev/null || echo "schemas/ not found"
ls -la scripts/ 2>/dev/null || echo "scripts/ not found"
echo ""

echo "=== Docker Logs (last 10 lines) ==="
docker-compose logs postgres 2>/dev/null | tail -10 || echo "No Docker logs available"
```

Run this script and include the output when asking for help:
```bash
chmod +x diagnostic.sh
./diagnostic.sh > diagnostic-output.txt
```

## ✅ Verification Checklist

Before running the demo, verify:

- [ ] Docker is installed and running
- [ ] Docker Compose is installed (version 1.25+)
- [ ] Go is installed (version 1.21+)
- [ ] pgschema is installed and in PATH
- [ ] PostgreSQL client tools are available
- [ ] Port 5432 is available
- [ ] Demo scripts are executable
- [ ] Database container starts successfully
- [ ] Can connect to database with psql

Run the verification:
```bash
make test
```

This comprehensive troubleshooting guide should help resolve most issues you might encounter while running the pgschema demo.