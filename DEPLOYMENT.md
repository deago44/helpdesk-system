# Helpdesk Deployment Guide

**Created by: Static Research Labs LLC**

This guide covers deploying the helpdesk application in production with all security, persistence, and operational features.

## Prerequisites

- Docker and Docker Compose
- PostgreSQL 15+
- Redis 7+
- Nginx or Caddy
- SSL certificates
- Domain name configured

## Quick Start with Docker Compose

1. **Clone and configure**:
   ```bash
   git clone <repository>
   cd helpdesk
   cp server/.env.example server/.env.production
   # Edit .env.production with your values
   ```

2. **Deploy**:
   ```bash
   docker-compose up -d
   ```

3. **Initialize database**:
   ```bash
   docker-compose exec web python -c "from app_production import init_db; init_db()"
   ```

4. **Seed initial data**:
   ```bash
   docker-compose exec web python seed_data.py
   ```

## Manual Deployment

### 1. Database Setup

```bash
# Install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# Create database and user
sudo -u postgres psql
CREATE DATABASE helpdesk;
CREATE USER helpdesk WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE helpdesk TO helpdesk;
\q
```

### 2. Application Setup

```bash
# Create application user
sudo useradd -m -s /bin/bash helpdesk
sudo mkdir -p /opt/helpdesk
sudo chown helpdesk:helpdesk /opt/helpdesk

# Clone application
sudo -u helpdesk git clone <repository> /opt/helpdesk

# Install Python dependencies
cd /opt/helpdesk/server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run database migrations
alembic upgrade head
```

### 3. Environment Configuration

```bash
# Copy and edit environment file
cp .env.example .env.production
# Edit with your production values
```

Key environment variables:
- `DATABASE_URL`: PostgreSQL connection string
- `FLASK_SECRET_KEY`: Secure random key
- `SESSION_COOKIE_SECURE`: Set to `True` for HTTPS
- `CORS_ALLOWED_ORIGINS`: Your domain(s)
- `S3_BUCKET`: For file uploads
- `SMTP_*`: Email configuration
- `SENTRY_DSN`: Error reporting

### 4. Systemd Service

```bash
# Copy service file
sudo cp helpdesk.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable helpdesk
sudo systemctl start helpdesk
```

### 5. Nginx Configuration

```bash
# Install Nginx
sudo apt install nginx

# Copy configuration
sudo cp nginx/nginx.conf /etc/nginx/sites-available/helpdesk
sudo ln -s /etc/nginx/sites-available/helpdesk /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Install SSL certificates (Let's Encrypt)
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### 6. Frontend Build

```bash
cd /opt/helpdesk/web
npm install
npm run build
sudo cp -r dist/* /var/www/html/
```

## Security Configuration

### 1. SSL/TLS
- Use Let's Encrypt for free SSL certificates
- Configure HSTS headers in Nginx
- Redirect HTTP to HTTPS

### 2. Database Security
- Use strong passwords
- Restrict database access to application server
- Enable SSL for database connections

### 3. File Uploads
- Configure S3 with proper IAM policies
- Use signed URLs for file access
- Implement virus scanning (optional)

### 4. Rate Limiting
- Configure Redis for distributed rate limiting
- Set appropriate limits for API endpoints
- Monitor for abuse

## Monitoring and Logging

### 1. Application Logs
```bash
# View application logs
sudo journalctl -u helpdesk -f

# Log rotation
sudo logrotate /etc/logrotate.d/helpdesk
```

### 2. Database Monitoring
```bash
# Monitor database performance
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
```

### 3. Error Reporting
- Configure Sentry for error tracking
- Set up alerts for critical errors
- Monitor application performance

## Backup and Recovery

### 1. Automated Backups
```bash
# Add to crontab
0 2 * * * /opt/helpdesk/server/backup.py
```

### 2. Database Backups
```bash
# Manual backup
pg_dump -h localhost -U helpdesk helpdesk > backup.sql

# Restore
psql -h localhost -U helpdesk helpdesk < backup.sql
```

### 3. File Backups
```bash
# Backup attachments
tar -czf attachments_backup.tar.gz uploads/

# Restore
tar -xzf attachments_backup.tar.gz
```

## Scaling Considerations

### 1. Database Scaling
- Use read replicas for read-heavy workloads
- Consider connection pooling (PgBouncer)
- Monitor query performance

### 2. Application Scaling
- Use multiple application instances behind load balancer
- Configure Redis for session storage
- Implement health checks

### 3. File Storage Scaling
- Use CDN for static assets
- Implement S3 lifecycle policies
- Consider multi-region storage

## Maintenance

### 1. Regular Updates
```bash
# Update dependencies
pip install -r requirements.txt --upgrade
npm update

# Database migrations
alembic upgrade head
```

### 2. Security Updates
- Keep system packages updated
- Monitor security advisories
- Regular security audits

### 3. Performance Optimization
- Monitor slow queries
- Optimize database indexes
- Cache frequently accessed data

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Check PostgreSQL service status
   - Verify connection string
   - Check firewall rules

2. **File Upload Issues**
   - Verify S3 credentials
   - Check file size limits
   - Monitor disk space

3. **Email Delivery Issues**
   - Verify SMTP credentials
   - Check spam filters
   - Monitor email logs

### Log Locations
- Application: `/var/log/helpdesk/`
- Nginx: `/var/log/nginx/`
- PostgreSQL: `/var/log/postgresql/`
- System: `journalctl -u helpdesk`

## Production Checklist

- [ ] SSL certificates installed and configured
- [ ] Database backups automated and tested
- [ ] Error reporting configured (Sentry)
- [ ] Rate limiting configured
- [ ] File uploads working with S3
- [ ] Email delivery working
- [ ] Monitoring and alerting set up
- [ ] Security headers configured
- [ ] Regular security updates scheduled
- [ ] Performance monitoring in place

## Support

For issues and questions:
1. Check logs for error messages
2. Review configuration files
3. Test individual components
4. Check system resources
5. Consult documentation
