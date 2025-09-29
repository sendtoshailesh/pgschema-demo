#!/bin/bash

# Transfer pgschema Demo to EC2
# Uses the EC2 details from EC2_QUICK_REFERENCE.md

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# EC2 Configuration from EC2_QUICK_REFERENCE.md
EC2_KEY="../ai-security-key.pem"
EC2_USER="ubuntu"
EC2_HOST="18.215.244.56"
EC2_INSTANCE_ID="i-03fbaf1cb5414c674"
EC2_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}🚀 $1${NC}"
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

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if SSH key exists
    if [[ ! -f "$EC2_KEY" ]]; then
        print_error "SSH key not found: $EC2_KEY"
        exit 1
    fi
    print_success "SSH key found: $EC2_KEY"
    
    # Check SSH key permissions
    key_perms=$(stat -f "%A" "$EC2_KEY" 2>/dev/null || stat -c "%a" "$EC2_KEY" 2>/dev/null)
    if [[ "$key_perms" != "600" ]]; then
        print_info "Setting SSH key permissions to 600..."
        chmod 600 "$EC2_KEY"
    fi
    print_success "SSH key permissions correct"
    
    # Check if rsync is available (preferred method)
    if command -v rsync >/dev/null 2>&1; then
        TRANSFER_METHOD="rsync"
        print_success "Using rsync for transfer (recommended)"
    else
        TRANSFER_METHOD="scp"
        print_info "Using scp for transfer (rsync not available)"
    fi
    
    echo ""
}

# Test EC2 connection
test_connection() {
    print_header "Testing EC2 Connection"
    
    print_info "Testing SSH connection to $EC2_USER@$EC2_HOST..."
    
    if ssh -i "$EC2_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$EC2_USER@$EC2_HOST" "echo 'Connection successful'" >/dev/null 2>&1; then
        print_success "EC2 connection successful"
    else
        print_error "Cannot connect to EC2 instance"
        echo ""
        echo "Troubleshooting steps:"
        echo "1. Check if EC2 instance is running:"
        echo "   aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $EC2_REGION"
        echo ""
        echo "2. Start instance if stopped:"
        echo "   aws ec2 start-instances --instance-ids $EC2_INSTANCE_ID --region $EC2_REGION"
        echo ""
        echo "3. Check security group allows SSH (port 22) from your IP"
        echo ""
        exit 1
    fi
    
    echo ""
}

# Transfer files to EC2
transfer_files() {
    print_header "Transferring Files to EC2"
    
    print_info "Creating target directory on EC2..."
    ssh -i "$EC2_KEY" "$EC2_USER@$EC2_HOST" "mkdir -p ~/pgschema-demo"
    
    print_info "Transferring demo files..."
    
    if [[ "$TRANSFER_METHOD" == "rsync" ]]; then
        # Use rsync for efficient transfer with progress
        rsync -avz --progress \
            --exclude='.git' \
            --exclude='*.tar.gz' \
            --exclude='.DS_Store' \
            --exclude='node_modules' \
            -e "ssh -i $EC2_KEY" \
            ./ "$EC2_USER@$EC2_HOST:~/pgschema-demo/"
    else
        # Use scp as fallback
        scp -r -i "$EC2_KEY" \
            --exclude='.git' \
            ./ "$EC2_USER@$EC2_HOST:~/pgschema-demo/"
    fi
    
    print_success "Files transferred successfully"
    echo ""
}

# Set up permissions on EC2
setup_permissions() {
    print_header "Setting Up Permissions on EC2"
    
    print_info "Setting executable permissions on scripts..."
    
    ssh -i "$EC2_KEY" "$EC2_USER@$EC2_HOST" << 'EOF'
cd ~/pgschema-demo

# Make all shell scripts executable
chmod +x demo.sh test.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x traditional/disaster.sh 2>/dev/null || true
chmod +x examples/test_features.sh 2>/dev/null || true

echo "✅ Permissions set successfully"
EOF
    
    print_success "Permissions configured"
    echo ""
}

# Verify transfer
verify_transfer() {
    print_header "Verifying Transfer"
    
    print_info "Checking transferred files..."
    
    ssh -i "$EC2_KEY" "$EC2_USER@$EC2_HOST" << 'EOF'
cd ~/pgschema-demo

echo "📁 Directory structure:"
ls -la

echo ""
echo "📋 Key files check:"
required_files=(
    "README.md"
    "Makefile"
    "docker-compose.yml"
    "demo.sh"
    "test.sh"
    "schemas/v1_initial.sql"
    "schemas/v2_with_reviews.sql"
    "schemas/v3_advanced.sql"
    ".github/workflows/schema.yml"
    "content/medium-blog-post.md"
    "content/youtube-video-script.md"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        missing_files+=("$file")
    else
        echo "✅ $file"
    fi
done

if [[ ${#missing_files[@]} -eq 0 ]]; then
    echo ""
    echo "✅ All required files present"
else
    echo ""
    echo "❌ Missing files:"
    printf '%s\n' "${missing_files[@]}"
    exit 1
fi

echo ""
echo "🔧 Executable scripts:"
ls -la *.sh scripts/*.sh traditional/*.sh examples/*.sh 2>/dev/null | grep '^-rwx'
EOF
    
    print_success "Transfer verification complete"
    echo ""
}

# Provide next steps
show_next_steps() {
    print_header "Next Steps for GitHub Publication"
    
    echo "🎯 Connect to EC2 and set up Git repository:"
    echo ""
    echo "1. SSH to EC2:"
    echo "   ssh -i $EC2_KEY $EC2_USER@$EC2_HOST"
    echo ""
    echo "2. Navigate to demo directory:"
    echo "   cd ~/pgschema-demo"
    echo ""
    echo "3. Initialize Git repository:"
    echo "   git init"
    echo "   git config --global user.name \"Your Name\""
    echo "   git config --global user.email \"your.email@example.com\""
    echo ""
    echo "4. Create GitHub repository (on GitHub.com):"
    echo "   - Repository name: pgschema-demo"
    echo "   - Description: Comprehensive PostgreSQL schema management demo showcasing pgschema's declarative approach"
    echo "   - Public repository"
    echo "   - Add topics: postgresql, database, schema-management, migrations, devops, gitops"
    echo ""
    echo "5. Add remote and push:"
    echo "   git remote add origin https://github.com/yourusername/pgschema-demo.git"
    echo "   git add ."
    echo "   git commit -m \"feat: add comprehensive pgschema PostgreSQL community demo\""
    echo "   git push -u origin main"
    echo ""
    echo "6. Optional - Test the demo on EC2:"
    echo "   # Install dependencies if needed"
    echo "   sudo apt update"
    echo "   sudo apt install -y docker.io docker-compose"
    echo "   "
    echo "   # Run quick validation"
    echo "   ./scripts/validate-demo.sh --quick"
    echo ""
    
    print_success "Ready for GitHub publication! 🚀"
}

# Main execution
main() {
    print_header "pgschema Demo Transfer to EC2"
    echo "Transferring to: $EC2_USER@$EC2_HOST"
    echo "Using key: $EC2_KEY"
    echo ""
    
    check_prerequisites
    test_connection
    transfer_files
    setup_permissions
    verify_transfer
    show_next_steps
    
    print_header "Transfer Complete!"
    print_success "pgschema demo successfully transferred to EC2"
    print_info "Follow the next steps above to publish to GitHub"
}

# Handle script arguments
case "${1:-}" in
    --test-connection)
        check_prerequisites
        test_connection
        ;;
    --help|-h)
        echo "pgschema Demo EC2 Transfer Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --test-connection  Test EC2 connection only"
        echo "  --help            Show this help message"
        echo ""
        echo "EC2 Details:"
        echo "  Host: $EC2_HOST"
        echo "  User: $EC2_USER"
        echo "  Key:  $EC2_KEY"
        echo ""
        exit 0
        ;;
    *)
        main
        ;;
esac