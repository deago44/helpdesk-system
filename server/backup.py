#!/usr/bin/env python3
"""
Backup script for helpdesk database and attachments
"""
import os
import sys
import subprocess
import datetime
import shutil
from pathlib import Path

def backup_database():
    """Backup PostgreSQL database"""
    db_url = os.getenv('DATABASE_URL')
    if not db_url or not db_url.startswith('postgresql://'):
        print("No PostgreSQL database configured for backup")
        return None
    
    # Parse database URL
    # Format: postgresql://user:password@host:port/database
    parts = db_url.replace('postgresql://', '').split('/')
    if len(parts) < 2:
        print("Invalid database URL format")
        return None
    
    db_name = parts[1]
    auth_host = parts[0]
    
    if '@' in auth_host:
        auth, host = auth_host.split('@')
        if ':' in auth:
            user, password = auth.split(':')
        else:
            user = auth
            password = ''
        
        if ':' in host:
            host, port = host.split(':')
        else:
            port = '5432'
    else:
        user = 'helpdesk'
        password = ''
        host = 'localhost'
        port = '5432'
    
    # Create backup filename
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_filename = f"helpdesk_backup_{timestamp}.sql"
    backup_path = Path('backups') / backup_filename
    
    # Ensure backup directory exists
    backup_path.parent.mkdir(exist_ok=True)
    
    # Set password environment variable
    env = os.environ.copy()
    if password:
        env['PGPASSWORD'] = password
    
    # Run pg_dump
    cmd = [
        'pg_dump',
        '-h', host,
        '-p', port,
        '-U', user,
        '-d', db_name,
        '-f', str(backup_path)
    ]
    
    try:
        subprocess.run(cmd, env=env, check=True)
        print(f"Database backup created: {backup_path}")
        return backup_path
    except subprocess.CalledProcessError as e:
        print(f"Database backup failed: {e}")
        return None

def backup_attachments():
    """Backup local attachments"""
    uploads_dir = Path('uploads')
    if not uploads_dir.exists():
        print("No uploads directory found")
        return None
    
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_filename = f"attachments_backup_{timestamp}.tar.gz"
    backup_path = Path('backups') / backup_filename
    
    # Ensure backup directory exists
    backup_path.parent.mkdir(exist_ok=True)
    
    try:
        subprocess.run([
            'tar', '-czf', str(backup_path), '-C', str(uploads_dir.parent), 'uploads'
        ], check=True)
        print(f"Attachments backup created: {backup_path}")
        return backup_path
    except subprocess.CalledProcessError as e:
        print(f"Attachments backup failed: {e}")
        return None

def cleanup_old_backups(keep_days=30):
    """Clean up old backup files"""
    backups_dir = Path('backups')
    if not backups_dir.exists():
        return
    
    cutoff_date = datetime.datetime.now() - datetime.timedelta(days=keep_days)
    
    for backup_file in backups_dir.glob('*.sql'):
        if backup_file.stat().st_mtime < cutoff_date.timestamp():
            backup_file.unlink()
            print(f"Removed old backup: {backup_file}")
    
    for backup_file in backups_dir.glob('*.tar.gz'):
        if backup_file.stat().st_mtime < cutoff_date.timestamp():
            backup_file.unlink()
            print(f"Removed old backup: {backup_file}")

def upload_to_s3(backup_path):
    """Upload backup to S3"""
    s3_bucket = os.getenv('S3_BACKUP_BUCKET')
    if not s3_bucket:
        print("No S3 backup bucket configured")
        return False
    
    try:
        import boto3
        
        s3_client = boto3.client('s3')
        s3_key = f"backups/{backup_path.name}"
        
        s3_client.upload_file(str(backup_path), s3_bucket, s3_key)
        print(f"Backup uploaded to S3: s3://{s3_bucket}/{s3_key}")
        return True
    except Exception as e:
        print(f"S3 upload failed: {e}")
        return False

def main():
    """Main backup function"""
    print("Helpdesk Backup Script")
    print("=" * 30)
    
    # Create backups
    db_backup = backup_database()
    attachments_backup = backup_attachments()
    
    # Upload to S3 if configured
    if db_backup and os.getenv('S3_BACKUP_BUCKET'):
        upload_to_s3(db_backup)
    
    if attachments_backup and os.getenv('S3_BACKUP_BUCKET'):
        upload_to_s3(attachments_backup)
    
    # Clean up old backups
    cleanup_old_backups()
    
    print("Backup completed!")

if __name__ == "__main__":
    main()
