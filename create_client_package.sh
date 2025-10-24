#!/bin/bash
# Client Delivery Package Creator
# Created by: Static Research Labs LLC

set -e

PACKAGE_NAME="helpdesk-client-package"
PACKAGE_VERSION="1.0.0"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "📦 Creating Client Delivery Package"
echo "==================================="
echo "Package: $PACKAGE_NAME"
echo "Version: $PACKAGE_VERSION"
echo "Date: $(date)"
echo ""

# Create package directory
PACKAGE_DIR="${PACKAGE_NAME}-${PACKAGE_VERSION}"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

echo "📁 Creating package structure..."

# Copy essential files
cp -r server "$PACKAGE_DIR/"
cp -r web "$PACKAGE_DIR/"
cp -r nginx "$PACKAGE_DIR/"
cp -r scripts "$PACKAGE_DIR/"

# Copy configuration files
cp docker-compose.yml "$PACKAGE_DIR/"
cp docker-compose.client.yml "$PACKAGE_DIR/"
cp docker-compose.prod.yml "$PACKAGE_DIR/"

# Copy documentation
cp CLIENT_PACKAGE_README.md "$PACKAGE_DIR/README.md"
cp CLIENT_GUIDE.md "$PACKAGE_DIR/"
cp DEPLOYMENT_GUIDE.md "$PACKAGE_DIR/"

# Create package-specific files
cat > "$PACKAGE_DIR/QUICK_START.md" << 'EOF'
# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Docker and Docker Compose installed
- 2GB RAM minimum
- 10GB disk space

### Installation Steps

1. **Extract this package**
   ```bash
   tar -xzf helpdesk-client-package-1.0.0.tar.gz
   cd helpdesk-client-package-1.0.0
   ```

2. **Run the setup script**
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

3. **Access your helpdesk**
   - Open browser: http://localhost:3000
   - Create your first account
   - Start using the system!

### What's Included
- ✅ Complete helpdesk application
- ✅ User management system
- ✅ Ticket creation and management
- ✅ File attachments
- ✅ Mobile-responsive interface
- ✅ Production-ready deployment

### Support
- User Guide: CLIENT_GUIDE.md
- Technical Guide: DEPLOYMENT_GUIDE.md
- Support: [Your contact information]

**Ready to go!** 🎉
EOF

# Create installation script
cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash
# Helpdesk Installation Script
# Created by: Static Research Labs LLC

echo "🚀 Helpdesk Installation"
echo "========================"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are ready"

# Make scripts executable
chmod +x scripts/*.sh

# Run setup
echo "🔧 Running setup..."
./scripts/setup.sh

echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "🌐 Access your helpdesk:"
echo "   http://localhost:3000"
echo ""
echo "📚 Documentation:"
echo "   User Guide: CLIENT_GUIDE.md"
echo "   Technical Guide: DEPLOYMENT_GUIDE.md"
echo ""
echo "✅ Your helpdesk system is ready!"
EOF

chmod +x "$PACKAGE_DIR/install.sh"

# Create package info
cat > "$PACKAGE_DIR/PACKAGE_INFO.txt" << EOF
Helpdesk Client Package
======================
Package Name: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Created: $(date)
Created By: Static Research Labs LLC

Package Contents:
- Complete helpdesk application
- Docker-based deployment
- User documentation
- Technical documentation
- Setup and maintenance scripts
- Production configuration

System Requirements:
- Docker & Docker Compose
- 2GB RAM minimum
- 10GB disk space
- Linux/Windows/macOS

Quick Start:
1. Extract package
2. Run: ./install.sh
3. Access: http://localhost:3000

Support:
- Documentation: CLIENT_GUIDE.md, DEPLOYMENT_GUIDE.md
- Contact: [Your support contact]

License: [Your license information]
EOF

# Create data directories
mkdir -p "$PACKAGE_DIR/data/postgres"
mkdir -p "$PACKAGE_DIR/data/redis"
mkdir -p "$PACKAGE_DIR/logs"

# Create .gitignore
cat > "$PACKAGE_DIR/.gitignore" << 'EOF'
# Data directories
data/
logs/
server/uploads/
server/tickets.db
server/tickets_*.db

# Environment files
.env
.env.*

# Backup files
backups/
*.backup
*.sql

# Temporary files
*.tmp
*.log
EOF

# Create package archive
echo "📦 Creating package archive..."
tar -czf "${PACKAGE_DIR}.tar.gz" "$PACKAGE_DIR"

# Create checksum
echo "🔍 Creating checksum..."
sha256sum "${PACKAGE_DIR}.tar.gz" > "${PACKAGE_DIR}.tar.gz.sha256"

# Display package information
echo ""
echo "✅ Package Created Successfully!"
echo "==============================="
echo ""
echo "📦 Package: ${PACKAGE_DIR}.tar.gz"
echo "📏 Size: $(du -h "${PACKAGE_DIR}.tar.gz" | cut -f1)"
echo "🔍 Checksum: ${PACKAGE_DIR}.tar.gz.sha256"
echo ""
echo "📁 Package Contents:"
echo "   - Complete helpdesk application"
echo "   - Docker deployment configuration"
echo "   - User and technical documentation"
echo "   - Setup and maintenance scripts"
echo "   - Production-ready configuration"
echo ""
echo "🚀 Client Installation:"
echo "   1. Extract: tar -xzf ${PACKAGE_DIR}.tar.gz"
echo "   2. Install: cd $PACKAGE_DIR && ./install.sh"
echo "   3. Access: http://localhost:3000"
echo ""
echo "📚 Documentation:"
echo "   - Quick Start: QUICK_START.md"
echo "   - User Guide: CLIENT_GUIDE.md"
echo "   - Technical Guide: DEPLOYMENT_GUIDE.md"
echo ""
echo "✅ Package ready for client delivery!"
