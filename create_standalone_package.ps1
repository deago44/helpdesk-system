# Create Standalone Client Package - PowerShell Version
# Created by: Static Research Labs LLC

$PACKAGE_NAME = "helpdesk-standalone"
$PACKAGE_VERSION = "1.0.0"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$ZIP_NAME = "${PACKAGE_NAME}-${PACKAGE_VERSION}.zip"

Write-Host "📦 Creating Standalone Client Package" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "Package: $PACKAGE_NAME" -ForegroundColor Yellow
Write-Host "Version: $PACKAGE_VERSION" -ForegroundColor Yellow
Write-Host "Output: $ZIP_NAME" -ForegroundColor Yellow
Write-Host ""

# Create temporary package directory
$TEMP_DIR = "temp_package_$(Get-Random)"
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

Write-Host "📁 Copying application files..." -ForegroundColor Cyan

# Copy essential directories
Copy-Item -Path "server" -Destination "$TEMP_DIR\server" -Recurse -Force
Copy-Item -Path "web" -Destination "$TEMP_DIR\web" -Recurse -Force
Copy-Item -Path "nginx" -Destination "$TEMP_DIR\nginx" -Recurse -Force
Copy-Item -Path "scripts" -Destination "$TEMP_DIR\scripts" -Recurse -Force

# Copy configuration files
Copy-Item -Path "docker-compose.yml" -Destination "$TEMP_DIR\" -Force
Copy-Item -Path "docker-compose.client.yml" -Destination "$TEMP_DIR\" -Force
Copy-Item -Path "docker-compose.prod.yml" -Destination "$TEMP_DIR\" -Force

# Copy documentation
Copy-Item -Path "CLIENT_PACKAGE_README.md" -Destination "$TEMP_DIR\README.md" -Force
Copy-Item -Path "CLIENT_GUIDE.md" -Destination "$TEMP_DIR\" -Force
Copy-Item -Path "DEPLOYMENT_GUIDE.md" -Destination "$TEMP_DIR\" -Force

Write-Host "📝 Creating installation files..." -ForegroundColor Cyan

# Create Windows installation script
$INSTALL_BAT = @"
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
"@

Set-Content -Path "$TEMP_DIR\INSTALL.bat" -Value $INSTALL_BAT

# Create Linux/Mac installation script
$INSTALL_SH = @"
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
"@

Set-Content -Path "$TEMP_DIR\install.sh" -Value $INSTALL_SH

# Create quick start guide
$QUICK_START = @"
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
"@

Set-Content -Path "$TEMP_DIR\QUICK_START.txt" -Value $QUICK_START

# Create package info
$PACKAGE_INFO = @"
HELPDESK CLIENT PACKAGE
======================
Package Name: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Created: $(Get-Date)
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
"@

Set-Content -Path "$TEMP_DIR\PACKAGE_INFO.txt" -Value $PACKAGE_INFO

# Create .gitignore
$GITIGNORE = @"
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
"@

Set-Content -Path "$TEMP_DIR\.gitignore" -Value $GITIGNORE

# Create data directories
New-Item -ItemType Directory -Path "$TEMP_DIR\data\postgres" -Force | Out-Null
New-Item -ItemType Directory -Path "$TEMP_DIR\data\redis" -Force | Out-Null
New-Item -ItemType Directory -Path "$TEMP_DIR\logs" -Force | Out-Null

Write-Host "📦 Creating zip package..." -ForegroundColor Cyan

# Create zip file
Compress-Archive -Path "$TEMP_DIR\*" -DestinationPath $ZIP_NAME -Force

# Clean up
Remove-Item -Path $TEMP_DIR -Recurse -Force

# Get file size
$SIZE = (Get-Item $ZIP_NAME).Length
$SIZE_MB = [math]::Round($SIZE / 1MB, 2)

Write-Host ""
Write-Host "✅ Standalone Package Created!" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Package: $ZIP_NAME" -ForegroundColor Yellow
Write-Host "📏 Size: $SIZE_MB MB" -ForegroundColor Yellow
Write-Host ""
Write-Host "📁 Package Contents:" -ForegroundColor Cyan
Write-Host "   - Complete helpdesk application"
Write-Host "   - Docker deployment configuration"
Write-Host "   - Installation scripts (Windows + Linux/Mac)"
Write-Host "   - User and technical documentation"
Write-Host "   - Quick start guide"
Write-Host ""
Write-Host "🚀 Client Installation:" -ForegroundColor Cyan
Write-Host "   Windows: Extract zip → Double-click INSTALL.bat"
Write-Host "   Linux/Mac: Extract zip → Run ./install.sh"
Write-Host "   Manual: Extract zip → Run docker-compose up -d"
Write-Host ""
Write-Host "📚 Documentation Included:" -ForegroundColor Cyan
Write-Host "   - QUICK_START.txt (simple instructions)"
Write-Host "   - CLIENT_GUIDE.md (user guide)"
Write-Host "   - DEPLOYMENT_GUIDE.md (technical guide)"
Write-Host "   - README.md (overview)"
Write-Host ""
Write-Host "🎯 Ready for Client Delivery!" -ForegroundColor Green
Write-Host "   You can now copy and send this zip file to any client."
Write-Host "   They can extract it and run the installation script."
Write-Host ""
Write-Host "✅ Package ready for distribution!" -ForegroundColor Green
