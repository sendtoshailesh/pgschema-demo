# Transfer pgschema Demo to EC2

This guide helps you transfer the complete pgschema demo to your EC2 instance for GitHub publication.

## 📋 Pre-Transfer Checklist

### Local Preparation
- [ ] All demo files are complete and validated
- [ ] Scripts have proper permissions (executable)
- [ ] Documentation is finalized
- [ ] No sensitive data in files

### EC2 Preparation
- [ ] EC2 instance is running and accessible
- [ ] SSH key is available
- [ ] Git is installed on EC2
- [ ] GitHub CLI or SSH keys configured for GitHub access

## 📦 Content to Transfer

### Complete Directory Structure
```
demo/
├── README.md                    # Main project documentation
├── Makefile                     # Convenient commands
├── docker-compose.yml           # PostgreSQL setup
├── init.sql                     # Database initialization
├── demo.sh                      # Main interactive demo
├── test.sh                      # Comprehensive test suite
├── .env.example                 # Environment configuration
├── .gitignore                   # Git ignore rules
├── TESTING.md                   # Testing and validation guide
├── REVIEW.md                    # Implementation review
├── VALIDATION_REPORT.md         # Validation results
├── TRANSFER_TO_EC2.md          # This file
│
├── schemas/                     # Schema evolution examples
│   ├── v1_initial.sql          # MVP e-commerce schema
│   ├── v2_with_reviews.sql     # Add reviews feature
│   └── v3_advanced.sql         # Advanced PostgreSQL features
│
├── examples/                    # Advanced examples
│   ├── showcase_features.sql   # Comprehensive feature demo
│   ├── test_features.sh        # Feature validation tests
│   └── pr-template.md          # GitHub PR template
│
├── scripts/                     # Demo variations
│   ├── quick-demo.sh           # 5-minute condensed demo
│   ├── feature-showcase.sh     # PostgreSQL features deep-dive
│   ├── comparison-demo.sh      # Traditional vs pgschema
│   ├── simulate-gitops.sh      # GitOps workflow simulation
│   └── validate-demo.sh        # Validation script
│
├── traditional/                 # Traditional migration problems
│   ├── migration_001_create_users.sql
│   ├── migration_002_create_products.sql
│   ├── migration_003_create_orders.sql
│   ├── migration_004_add_reviews_BROKEN.sql
│   ├── disaster.sh             # Migration failure simulation
│   └── README.md               # Traditional approach explanation
│
├── .github/workflows/           # CI/CD integration
│   └── schema.yml              # Complete GitOps workflow
│
├── docs/                        # Comprehensive documentation
│   ├── advanced-features.md    # PostgreSQL feature guide
│   ├── gitops-workflow.md      # GitOps integration guide
│   └── troubleshooting.md      # Common issues and solutions
│
└── content/                     # Multi-platform content
    ├── medium-blog-post.md     # Complete Medium article
    ├── youtube-video-script.md # YouTube video script
    └── video-assets.md         # Video production assets
```

## 🚀 Transfer Methods

### Method 1: SCP (Secure Copy)
```bash
# From your local machine, copy the entire demo directory
scp -r -i /path/to/your-key.pem demo/ ec2-user@your-ec2-ip:~/pgschema-demo/

# Or if using a different user
scp -r -i /path/to/your-key.pem demo/ ubuntu@your-ec2-ip:~/pgschema-demo/
```

### Method 2: Rsync (Recommended for large transfers)
```bash
# More efficient for large directories, shows progress
rsync -avz -e "ssh -i /path/to/your-key.pem" demo/ ec2-user@your-ec2-ip:~/pgschema-demo/

# With progress and compression
rsync -avz --progress -e "ssh -i /path/to/your-key.pem" demo/ ec2-user@your-ec2-ip:~/pgschema-demo/
```

### Method 3: Tar and Transfer (For slow connections)
```bash
# Create compressed archive locally
tar -czf pgschema-demo.tar.gz demo/

# Transfer the archive
scp -i /path/to/your-key.pem pgschema-demo.tar.gz ec2-user@your-ec2-ip:~/

# SSH to EC2 and extract
ssh -i /path/to/your-key.pem ec2-user@your-ec2-ip
tar -xzf pgschema-demo.tar.gz
mv demo pgschema-demo
```

## 🔧 Post-Transfer Setup on EC2

### 1. Connect to EC2
```bash
ssh -i /path/to/your-key.pem ec2-user@your-ec2-ip
```

### 2. Verify Transfer
```bash
cd ~/pgschema-demo
ls -la
```

### 3. Set Proper Permissions
```bash
# Make all shell scripts executable
chmod +x demo.sh test.sh
chmod +x scripts/*.sh
chmod +x traditional/disaster.sh
chmod +x examples/test_features.sh

# Verify permissions
ls -la *.sh scripts/*.sh traditional/*.sh examples/*.sh
```

### 4. Install Dependencies (if needed)
```bash
# Update system
sudo yum update -y  # Amazon Linux
# or
sudo apt update && sudo apt upgrade -y  # Ubuntu

# Install Docker (if not already installed)
sudo yum install -y docker  # Amazon Linux
# or
sudo apt install -y docker.io  # Ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Go (if needed for pgschema)
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### 5. Test the Demo
```bash
# Quick validation
./scripts/validate-demo.sh --quick

# Or run a quick demo test
make setup
make test
```

## 📤 GitHub Repository Setup

### 1. Initialize Git Repository
```bash
cd ~/pgschema-demo
git init
```

### 2. Configure Git (if not already done)
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. Add GitHub Remote
```bash
# Create repository on GitHub first, then:
git remote add origin https://github.com/yourusername/pgschema-demo.git

# Or using SSH (if SSH keys are configured)
git remote add origin git@github.com:yourusername/pgschema-demo.git
```

### 4. Initial Commit and Push
```bash
# Add all files
git add .

# Create initial commit
git commit -m "feat: add comprehensive pgschema PostgreSQL community demo

- Complete interactive demo with 4-act narrative
- Traditional migration disaster simulation
- Advanced PostgreSQL features showcase
- GitOps workflow integration
- Multi-platform content (GitHub, Medium, YouTube)
- Comprehensive documentation and troubleshooting
- Production-ready CI/CD workflows
- Multiple demo variations (5-15 minutes)

Ready for PostgreSQL community release."

# Push to GitHub
git push -u origin main
```

## 📋 Pre-Publication Checklist

### Content Verification
- [ ] All files transferred successfully
- [ ] Scripts have proper permissions
- [ ] No sensitive data in repository
- [ ] README.md is comprehensive and accurate
- [ ] All links in documentation work correctly

### Repository Setup
- [ ] Repository is public (for community access)
- [ ] Repository description is clear and compelling
- [ ] Topics/tags are added for discoverability
- [ ] License file is included (MIT recommended)
- [ ] GitHub Pages enabled (if desired)

### Community Preparation
- [ ] Discord/community channels ready for support
- [ ] Issue templates configured
- [ ] Contributing guidelines added
- [ ] Code of conduct included
- [ ] Security policy defined

## 🎯 Recommended Repository Settings

### Repository Description
```
Comprehensive PostgreSQL schema management demo showcasing pgschema's declarative approach. Stop writing database migrations - start declaring your desired schema state.
```

### Topics/Tags
```
postgresql, database, schema-management, migrations, devops, gitops, infrastructure-as-code, pgschema, declarative, demo
```

### Repository Features
- [ ] Issues enabled
- [ ] Wiki enabled (for extended documentation)
- [ ] Discussions enabled (for community Q&A)
- [ ] Projects enabled (for roadmap tracking)

## 🚀 Post-Publication Actions

### 1. Community Announcement
- Share on PostgreSQL Reddit
- Post in PostgreSQL Discord/Slack communities
- Tweet with relevant hashtags
- Share in LinkedIn PostgreSQL groups

### 2. Content Publication
- Publish Medium blog post with link to repository
- Record and publish YouTube video
- Submit to PostgreSQL conferences
- Share in developer newsletters

### 3. Monitoring and Engagement
- Monitor GitHub issues and discussions
- Respond to community feedback
- Track analytics and engagement metrics
- Plan improvements based on feedback

## 🔍 Troubleshooting Transfer Issues

### Permission Denied
```bash
# Check SSH key permissions
chmod 600 /path/to/your-key.pem

# Verify EC2 security group allows SSH (port 22)
```

### Large File Transfer Issues
```bash
# Use compression and resume capability
rsync -avz --partial --progress -e "ssh -i /path/to/your-key.pem" demo/ ec2-user@your-ec2-ip:~/pgschema-demo/
```

### Connection Timeout
```bash
# Add connection keep-alive
ssh -o ServerAliveInterval=60 -i /path/to/your-key.pem ec2-user@your-ec2-ip
```

## 📞 Support

If you encounter issues during transfer or setup:

1. **Check EC2 Status**: Ensure instance is running and accessible
2. **Verify Security Groups**: SSH (port 22) should be allowed
3. **Check Key Permissions**: SSH key should have 600 permissions
4. **Test Connection**: Try basic SSH connection first
5. **Monitor Transfer**: Use rsync with --progress for large transfers

---

**Ready to transform PostgreSQL schema management for the community!** 🚀

This transfer guide ensures smooth deployment of the pgschema demo to your EC2 instance for GitHub publication.