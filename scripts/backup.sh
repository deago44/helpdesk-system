#!/bin/bash
# Helpdesk Backup Script
# Created by: Static Research Labs LLC

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="helpdesk_backup_${TIMESTAMP}.sql"

echo "💾 Helpdesk Backup Script"
echo "========================="

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "📁 Creating backup directory: $BACKUP_DIR"

# Check if services are running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Services are not running. Please start the system first."
    echo "Run: docker-compose up -d"
    exit 1
fi

echo "✅ Services are running"

# Create database backup
echo "🗄️ Backing up database..."
docker-compose exec -T api python -c "
import sqlite3
import sys

try:
    conn = sqlite3.connect('tickets.db')
    
    # Get all data
    with open('/tmp/backup.sql', 'w') as f:
        for line in conn.iterdump():
            f.write('%s\n' % line)
    
    conn.close()
    print('Database backup completed successfully!')
except Exception as e:
    print(f'Database backup failed: {e}')
    sys.exit(1)
"

# Copy backup file
docker cp $(docker-compose ps -q api):/tmp/backup.sql "$BACKUP_DIR/$BACKUP_FILE"

echo "✅ Database backup saved to: $BACKUP_DIR/$BACKUP_FILE"

# Backup uploaded files
echo "📎 Backing up uploaded files..."
if [ -d "server/uploads" ] && [ "$(ls -A server/uploads)" ]; then
    tar -czf "$BACKUP_DIR/uploads_backup_${TIMESTAMP}.tar.gz" server/uploads/
    echo "✅ File uploads backed up to: $BACKUP_DIR/uploads_backup_${TIMESTAMP}.tar.gz"
else
    echo "ℹ️ No uploaded files to backup"
fi

# Create backup info file
cat > "$BACKUP_DIR/backup_info_${TIMESTAMP}.txt" << EOF
Helpdesk Backup Information
===========================
Backup Date: $(date)
Backup Files:
- Database: $BACKUP_FILE
- Files: uploads_backup_${TIMESTAMP}.tar.gz (if files exist)

System Information:
- Docker Compose Version: $(docker-compose --version)
- Backup Script Version: 1.0.0

To restore this backup:
1. Stop the system: docker-compose down
2. Restore database: ./scripts/restore.sh $BACKUP_FILE
3. Restore files: tar -xzf uploads_backup_${TIMESTAMP}.tar.gz
4. Start system: docker-compose up -d
EOF

echo "✅ Backup information saved to: $BACKUP_DIR/backup_info_${TIMESTAMP}.txt"

# Display backup summary
echo ""
echo "🎉 Backup Complete!"
echo "=================="
echo ""
echo "📁 Backup location: $BACKUP_DIR"
echo "🗄️ Database backup: $BACKUP_FILE"
if [ -f "$BACKUP_DIR/uploads_backup_${TIMESTAMP}.tar.gz" ]; then
    echo "📎 Files backup: uploads_backup_${TIMESTAMP}.tar.gz"
fi
echo "📋 Info file: backup_info_${TIMESTAMP}.txt"
echo ""
echo "💡 To restore this backup, run:"
echo "   ./scripts/restore.sh $BACKUP_FILE"
echo ""
echo "✅ Backup completed successfully!"
