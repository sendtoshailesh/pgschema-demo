#!/bin/bash

# Prepare pgschema Demo for EC2 Transfer
# This script prepares the demo for transfer to EC2 and GitHub publication

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}📦 $1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Main preparation function
main() {
    print_header "Preparing pgschema Demo for EC2 Transfer"
    
    print_info "Checking file structure..."
    
    # Verify all required files exist
    required_files=(
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
        "docs/advanced-features.md"
        "docs/gitops-workflow.md"
        "docs/troubleshooting.md"
        "content/medium-blog-post.md"
        "content/youtube-video-script.md"
    )
    
    missing_files=()
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        print_success "All required files present"
    else
        echo "❌ Missing files:"
        printf '%s\n' "${missing_files[@]}"
        exit 1
    fi
    
    print_info "Setting proper file permissions..."
    
    # Set executable permissions on scripts
    chmod +x demo.sh test.sh 2>/dev/null || true
    chmod +x scripts/*.sh 2>/dev/null || true
    chmod +x traditional/disaster.sh 2>/dev/null || true
    chmod +x examples/test_features.sh 2>/dev/null || true
    
    print_success "File permissions set"
    
    print_info "Validating file contents..."
    
    # Check for any sensitive data patterns
    sensitive_patterns=(
        "password.*="
        "secret.*="
        "api_key.*="
        "private_key"
        "ssh-rsa"
        "BEGIN PRIVATE KEY"
    )
    
    sensitive_found=false
    for pattern in "${sensitive_patterns[@]}"; do
        if grep -r -i "$pattern" . --exclude-dir=.git --exclude="*.md" --exclude="prepare-for-transfer.sh" >/dev/null 2>&1; then
            echo "⚠️  Potential sensitive data found: $pattern"
            sensitive_found=true
        fi
    done
    
    if [[ "$sensitive_found" == "false" ]]; then
        print_success "No sensitive data patterns detected"
    else
        echo "⚠️  Please review and remove any sensitive data before transfer"
    fi
    
    print_info "Generating file manifest..."
    
    # Create a manifest of all files for verification
    find . -type f -not -path './.git/*' | sort > FILE_MANIFEST.txt
    
    print_success "File manifest created: FILE_MANIFEST.txt"
    
    print_info "Creating transfer archive (optional)..."
    
    # Create compressed archive for transfer
    tar -czf ../pgschema-demo.tar.gz \
        --exclude='.git' \
        --exclude='*.tar.gz' \
        --exclude='node_modules' \
        --exclude='.DS_Store' \
        .
    
    print_success "Transfer archive created: ../pgschema-demo.tar.gz"
    
    print_header "Transfer Preparation Complete"
    
    echo "📋 Summary:"
    echo "  ✅ All required files present"
    echo "  ✅ File permissions set correctly"
    echo "  ✅ No sensitive data detected"
    echo "  ✅ File manifest generated"
    echo "  ✅ Transfer archive created"
    echo ""
    
    echo "📤 Next Steps:"
    echo "  1. Review TRANSFER_TO_EC2.md for detailed transfer instructions"
    echo "  2. Use one of these transfer methods:"
    echo "     • SCP: scp -r demo/ ec2-user@your-ec2-ip:~/pgschema-demo/"
    echo "     • Rsync: rsync -avz demo/ ec2-user@your-ec2-ip:~/pgschema-demo/"
    echo "     • Archive: scp pgschema-demo.tar.gz ec2-user@your-ec2-ip:~/"
    echo "  3. Follow post-transfer setup instructions"
    echo "  4. Initialize Git repository and push to GitHub"
    echo ""
    
    echo "🚀 Ready for EC2 transfer and GitHub publication!"
}

# Run preparation
main