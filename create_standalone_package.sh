#!/bin/bash
# Create Standalone Client Package
# Created by: Static Research Labs LLC

set -e

PACKAGE_NAME="helpdesk-standalone"
PACKAGE_VERSION="1.0.0"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ZIP_NAME="${PACKAGE_NAME}-${PACKAGE_VERSION}.zip"

echo "📦 Creating Standalone Client Package"
echo "===================================="
echo "Package: $PACKAGE_NAME"
echo "Version: $PACKAGE_VERSION"
echo "Output: $ZIP_NAME"
echo ""

# Create temporary package directory
TEMP_DIR="temp_package_$$"
mkdir -p "$TEMP_DIR"

echo "📁 Copying application files..."

# Copy essential directories
cp -r server "$TEMP_DIR/"
cp -r web "$TEMP_DIR/"
cp -r nginx "$TEMP_DIR/"
cp -r scripts "$TEMP_DIR/"

# Copy configuration files
cp docker-compose.yml "$TEMP_DIR/"
cp docker-compose.client.yml "$TEMP_DIR/"
cp docker-compose.prod.yml "$TEMP_DIR/"

# Copy documentation
cp CLIENT_PACKAGE_README.md "$TEMP_DIR/README.md"
cp CLIENT_GUIDE.md "$TEMP_DIR/"
cp DEPLOYMENT_GUIDE.md "$TEMP_DIR/"

echo "📝 Creating installation files..."

# Create main installation script
cat > "$TEMP_DIR/INSTALL.bat" << 'EOF'
@echo off
echo.
echo ========================================
echo    Helpdesk System Installation
echo ========================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not installed!
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)

REM Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker Compose is not installed!
    echo Please install Docker Compose or update Docker Desktop
    echo.
    pause
    exit /b 1
)

echo Docker and Docker Compose are ready!
echo.

REM Create necessary directories
echo Creating directories...
if not exist "data" mkdir data
if not exist "data\postgres" mkdir data\postgres
if not exist "data\redis" mkdir data\redis
if not exist "server\uploads" mkdir server\uploads
if not exist "logs" mkdir logs

REM Create environment file
echo Creating environment configuration...
if not exist ".env" (
    echo # Helpdesk Environment Configuration > .env
    echo FLASK_SECRET_KEY=dev-secret-key-change-in-production >> .env
    echo DATABASE_URL=sqlite:///tickets.db >> .env
    echo CORS_ALLOWED_ORIGINS=http://localhost:3000 >> .env
    echo UPLOAD_FOLDER=./uploads >> .env
    echo MAX_CONTENT_LENGTH=10485760 >> .env
    echo Environment file created!
)

REM Start services
echo.
echo Starting helpdesk services...
docker-compose up -d

REM Wait for services
echo Waiting for services to start...
timeout /t 15 /nobreak >nul

REM Check if services are running
docker-compose ps | findstr "Up" >nul
if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo    Installation Complete!
    echo ========================================
    echo.
    echo Your helpdesk system is now running!
    echo.
    echo Access your helpdesk:
    echo   Frontend: http://localhost:3000
    echo   API:      http://localhost:5000
    echo.
    echo Next steps:
    echo   1. Open http://localhost:3000 in your browser
    echo   2. Create your first account
    echo   3. Start using the helpdesk system!
    echo.
    echo Documentation:
    echo   User Guide: CLIENT_GUIDE.md
    echo   Technical Guide: DEPLOYMENT_GUIDE.md
    echo.
    echo Management commands:
    echo   Stop system:  docker-compose down
    echo   Restart:      docker-compose restart
    echo   View logs:    docker-compose logs -f
    echo.
    echo Press any key to open the helpdesk in your browser...
    pause >nul
    start http://localhost:3000
) else (
    echo.
    echo ERROR: Services failed to start!
    echo Check the logs with: docker-compose logs
    echo.
    pause
    exit /b 1
)
EOF

# Create Linux/Mac installation script
cat > "$TEMP_DIR/install.sh" << 'EOF'
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

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p data/postgres
mkdir -p data/redis
mkdir -p server/uploads
mkdir -p logs

# Create environment file
echo "📝 Creating environment configuration..."
if [ ! -f .env ]; then
    cat > .env << 'ENVEOF'
# Helpdesk Environment Configuration
FLASK_SECRET_KEY=dev-secret-key-change-in-production
DATABASE_URL=sqlite:///tickets.db
CORS_ALLOWED_ORIGINS=http://localhost:3000
UPLOAD_FOLDER=./uploads
MAX_CONTENT_LENGTH=10485760
ENVEOF
    echo "✅ Environment file created"
fi

# Make scripts executable
chmod +x scripts/*.sh

# Start services
echo "🐳 Starting helpdesk services..."
docker-compose up -d

# Wait for services
echo "⏳ Waiting for services to start..."
sleep 15

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "🎉 Installation Complete!"
    echo "========================"
    echo ""
    echo "🌐 Access your helpdesk:"
    echo "   Frontend: http://localhost:3000"
    echo "   API:      http://localhost:5000"
    echo ""
    echo "📚 Documentation:"
    echo "   User Guide: CLIENT_GUIDE.md"
    echo "   Technical Guide: DEPLOYMENT_GUIDE.md"
    echo ""
    echo "🛠️ Management commands:"
    echo "   Stop system:  docker-compose down"
    echo "   Restart:      docker-compose restart"
    echo "   View logs:    docker-compose logs -f"
    echo ""
    echo "✅ Your helpdesk system is ready!"
    
    # Try to open browser (Linux/Mac)
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:3000
    elif command -v open &> /dev/null; then
        open http://localhost:3000
    fi
else
    echo ""
    echo "❌ Services failed to start!"
    echo "Check the logs with: docker-compose logs"
    exit 1
fi
EOF

chmod +x "$TEMP_DIR/install.sh"

# Create quick start guide
cat > "$TEMP_DIR/QUICK_START.txt" << 'EOF'
HELPDESK SYSTEM - QUICK START GUIDE
===================================

SYSTEM REQUIREMENTS:
- Docker Desktop (Windows/Mac) or Docker + Docker Compose (Linux)
- 2GB RAM minimum
- 10GB disk space
- Internet connection for initial setup

INSTALLATION:

Windows:
1. Double-click INSTALL.bat
2. Follow the prompts
3. System will open automatically in your browser

Linux/Mac:
1. Open terminal in this directory
2. Run: chmod +x install.sh && ./install.sh
3. System will open automatically in your browser

MANUAL INSTALLATION:
1. Open terminal/command prompt in this directory
2. Run: docker-compose up -d
3. Open browser to: http://localhost:3000

ACCESS:
- Frontend: http://localhost:3000
- API: http://localhost:5000

FIRST USE:
1. Open http://localhost:3000
2. Click "Create one here" to register
3. Create your first account
4. Start using the helpdesk!

MANAGEMENT:
- Stop: docker-compose down
- Restart: docker-compose restart
- Logs: docker-compose logs -f
- Update: docker-compose pull && docker-compose up -d

SUPPORT:
- User Guide: CLIENT_GUIDE.md
- Technical Guide: DEPLOYMENT_GUIDE.md
- Package Info: README.md

TROUBLESHOOTING:
- If services won't start: Check Docker is running
- If port conflicts: Edit docker-compose.yml ports
- If database issues: Delete data/ folder and restart

Ready to go! 🚀
EOF

# Create package info
cat > "$TEMP_DIR/PACKAGE_INFO.txt" << EOF
HELPDESK CLIENT PACKAGE
======================
Package Name: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Created: $(date)
Created By: Static Research Labs LLC

CONTENTS:
- Complete helpdesk application (React + Flask)
- Docker-based deployment
- User and technical documentation
- Automated installation scripts
- Production-ready configuration

SYSTEM REQUIREMENTS:
- Docker & Docker Compose
- 2GB RAM minimum
- 10GB disk space
- Windows 10+, macOS 10.14+, or Linux

INSTALLATION:
Windows: Double-click INSTALL.bat
Linux/Mac: Run ./install.sh
Manual: docker-compose up -d

ACCESS:
Frontend: http://localhost:3000
API: http://localhost:5000

FEATURES:
✅ Complete ticket management system
✅ User roles (User/Tech/Admin)
✅ File attachments (up to 10MB)
✅ Mobile-responsive interface
✅ Search and filtering
✅ Production security features
✅ Easy backup/restore

SUPPORT:
- Documentation included
- Installation scripts provided
- Troubleshooting guides included

LICENSE: [Your license information]
EOF

# Create .gitignore
cat > "$TEMP_DIR/.gitignore" << 'EOF'
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

# Create data directories
mkdir -p "$TEMP_DIR/data/postgres"
mkdir -p "$TEMP_DIR/data/redis"
mkdir -p "$TEMP_DIR/logs"

echo "📦 Creating zip package..."

# Create zip file
if command -v zip &> /dev/null; then
    zip -r "$ZIP_NAME" "$TEMP_DIR"/* -x "*.DS_Store" "*.git*"
elif command -v 7z &> /dev/null; then
    7z a "$ZIP_NAME" "$TEMP_DIR"/*
else
    echo "❌ No zip utility found. Please install zip or 7z"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"

# Get file size
if command -v ls &> /dev/null; then
    SIZE=$(ls -lh "$ZIP_NAME" | awk '{print $5}')
elif command -v dir &> /dev/null; then
    SIZE=$(dir "$ZIP_NAME" | findstr "$ZIP_NAME")
fi

echo ""
echo "✅ Standalone Package Created!"
echo "=============================="
echo ""
echo "📦 Package: $ZIP_NAME"
echo "📏 Size: $SIZE"
echo ""
echo "📁 Package Contents:"
echo "   - Complete helpdesk application"
echo "   - Docker deployment configuration"
echo "   - Installation scripts (Windows + Linux/Mac)"
echo "   - User and technical documentation"
echo "   - Quick start guide"
echo ""
echo "🚀 Client Installation:"
echo "   Windows: Extract zip → Double-click INSTALL.bat"
echo "   Linux/Mac: Extract zip → Run ./install.sh"
echo "   Manual: Extract zip → Run docker-compose up -d"
echo ""
echo "📚 Documentation Included:"
echo "   - QUICK_START.txt (simple instructions)"
echo "   - CLIENT_GUIDE.md (user guide)"
echo "   - DEPLOYMENT_GUIDE.md (technical guide)"
echo "   - README.md (overview)"
echo ""
echo "🎯 Ready for Client Delivery!"
echo "   You can now copy and send this zip file to any client."
echo "   They can extract it and run the installation script."
echo ""
echo "✅ Package ready for distribution!"
