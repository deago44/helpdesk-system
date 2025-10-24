#!/bin/bash
# Helpdesk Restore Script
# Created by: Static Research Labs LLC

set -e

if [ $# -eq 0 ]; then
    echo "❌ Please provide a backup file to restore"
    echo "Usage: ./scripts/restore.sh <backup_file.sql>"
    echo ""
    echo "Available backups:"
    ls -la backups/*.sql 2>/dev/null || echo "No backups found in ./backups/"
    exit 1
fi

BACKUP_FILE="$1"
BACKUP_DIR="./backups"

echo "🔄 Helpdesk Restore Script"
echo "=========================="

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    # Try in backups directory
    if [ -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
        BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
    else
        echo "❌ Backup file not found: $BACKUP_FILE"
        echo "Available backups:"
        ls -la backups/*.sql 2>/dev/null || echo "No backups found in ./backups/"
        exit 1
    fi
fi

echo "📁 Restoring from: $BACKUP_FILE"

# Confirm restore
echo "⚠️ WARNING: This will replace your current database!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "❌ Restore cancelled"
    exit 1
fi

# Stop services
echo "🛑 Stopping services..."
docker-compose down

# Wait for services to stop
sleep 5

# Create backup of current database (just in case)
echo "💾 Creating safety backup of current database..."
if [ -f "server/tickets.db" ]; then
    cp server/tickets.db "server/tickets_backup_$(date +%Y%m%d_%H%M%S).db"
    echo "✅ Current database backed up"
fi

# Start services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Restore database
echo "🗄️ Restoring database..."
docker cp "$BACKUP_FILE" $(docker-compose ps -q api):/tmp/restore.sql

docker-compose exec -T api python -c "
import sqlite3
import os

try:
    # Remove existing database
    if os.path.exists('tickets.db'):
        os.remove('tickets.db')
    
    # Create new database and restore
    conn = sqlite3.connect('tickets.db')
    
    with open('/tmp/restore.sql', 'r') as f:
        sql_script = f.read()
    
    # Execute the SQL script
    conn.executescript(sql_script)
    conn.close()
    
    print('Database restored successfully!')
except Exception as e:
    print(f'Database restore failed: {e}')
    exit(1)
"

echo "✅ Database restored"

# Check if there are uploaded files to restore
UPLOADS_BACKUP=$(echo "$BACKUP_FILE" | sed 's/\.sql$/.tar.gz/' | sed 's/helpdesk_backup/uploads_backup/')
if [ -f "$UPLOADS_BACKUP" ]; then
    echo "📎 Restoring uploaded files..."
    tar -xzf "$UPLOADS_BACKUP" -C ./
    echo "✅ Uploaded files restored"
else
    echo "ℹ️ No uploaded files backup found"
fi

# Verify restore
echo "🔍 Verifying restore..."
docker-compose exec -T api python -c "
import sqlite3

try:
    conn = sqlite3.connect('tickets.db')
    c = conn.cursor()
    
    # Check if tables exist
    c.execute('SELECT name FROM sqlite_master WHERE type=\"table\"')
    tables = c.fetchall()
    
    print(f'Tables found: {len(tables)}')
    for table in tables:
        c.execute(f'SELECT COUNT(*) FROM {table[0]}')
        count = c.fetchone()[0]
        print(f'  {table[0]}: {count} records')
    
    conn.close()
    print('Database verification completed!')
except Exception as e:
    print(f'Database verification failed: {e}')
    exit(1)
"

echo ""
echo "🎉 Restore Complete!"
echo "==================="
echo ""
echo "✅ Database restored from: $BACKUP_FILE"
if [ -f "$UPLOADS_BACKUP" ]; then
    echo "✅ Files restored from: $UPLOADS_BACKUP"
fi
echo ""
echo "🌐 Your helpdesk system is ready:"
echo "   Frontend: http://localhost:3000"
echo "   API:      http://localhost:5000"
echo ""
echo "✅ Restore completed successfully!"
