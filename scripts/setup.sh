#!/bin/bash
# Helpdesk Setup Script
# Created by: Static Research Labs LLC

set -e

echo "🚀 Helpdesk System Setup"
echo "========================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p data/postgres
mkdir -p data/redis
mkdir -p server/uploads
mkdir -p logs

# Set permissions
chmod 755 data/postgres
chmod 755 data/redis
chmod 755 server/uploads
chmod 755 logs

echo "✅ Directories created"

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating environment file..."
    cat > .env << EOF
# Helpdesk Environment Configuration
FLASK_SECRET_KEY=$(openssl rand -hex 32)
DATABASE_URL=sqlite:///tickets.db
CORS_ALLOWED_ORIGINS=http://localhost:3000
UPLOAD_FOLDER=./uploads
MAX_CONTENT_LENGTH=10485760
EOF
    echo "✅ Environment file created"
else
    echo "✅ Environment file already exists"
fi

# Start services
echo "🐳 Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Services are running"
else
    echo "❌ Some services failed to start"
    echo "Check logs with: docker-compose logs"
    exit 1
fi

# Initialize database
echo "🗄️ Initializing database..."
docker-compose exec -T api python -c "
import sqlite3
import os

# Create database and tables
conn = sqlite3.connect('tickets.db')
c = conn.cursor()

# Create users table
c.execute('''
    CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'user'
    )
''')

# Create tickets table
c.execute('''
    CREATE TABLE IF NOT EXISTS tickets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT DEFAULT 'Open',
        priority TEXT DEFAULT 'Normal',
        created_at TEXT,
        updated_at TEXT,
        assigned_to INTEGER,
        user_id INTEGER,
        FOREIGN KEY (assigned_to) REFERENCES users(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
    )
''')

# Create audit_log table
c.execute('''
    CREATE TABLE IF NOT EXISTS audit_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts TEXT,
        actor_id INTEGER,
        action TEXT,
        resource_type TEXT,
        resource_id INTEGER,
        details TEXT
    )
''')

conn.commit()
conn.close()
print('Database initialized successfully!')
"

echo "✅ Database initialized"

# Display access information
echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "🌐 Access your helpdesk system:"
echo "   Frontend: http://localhost:3000"
echo "   API:      http://localhost:5000"
echo ""
echo "👤 Next steps:"
echo "   1. Open http://localhost:3000 in your browser"
echo "   2. Create your first account"
echo "   3. Start using the helpdesk system!"
echo ""
echo "📚 Documentation:"
echo "   User Guide: CLIENT_GUIDE.md"
echo "   Technical Guide: DEPLOYMENT_GUIDE.md"
echo ""
echo "🛠️ Management commands:"
echo "   View logs:    docker-compose logs -f"
echo "   Stop system:  docker-compose down"
echo "   Restart:      docker-compose restart"
echo "   Update:       docker-compose pull && docker-compose up -d"
echo ""
echo "✅ Your helpdesk system is ready to use!"
