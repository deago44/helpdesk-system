# Helpdesk System - Technical Deployment Guide

**Created by: Static Research Labs LLC**

## 🛠️ Technical Overview

This guide provides detailed technical information for deploying and maintaining the helpdesk system.

## 🏗️ Architecture

### System Components
- **Frontend**: React.js application (Vite build system)
- **Backend**: Flask Python API server
- **Database**: SQLite (development) / PostgreSQL (production)
- **Web Server**: Nginx (production)
- **Containerization**: Docker & Docker Compose

### Port Configuration
- **3000**: Frontend application
- **5000**: Backend API
- **5432**: PostgreSQL database
- **6379**: Redis cache (production)

## 🐳 Docker Deployment

### Quick Start
```bash
# Clone or extract the package
cd helpdesk-client-package

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### Production Deployment
```bash
# Use production configuration
docker-compose -f docker-compose.prod.yml up -d

# Setup SSL (optional)
./scripts/setup-ssl.sh yourdomain.com
```

## 📁 File Structure

```
helpdesk/
├── docker-compose.yml          # Development deployment
├── docker-compose.prod.yml     # Production deployment
├── server/                     # Backend application
│   ├── Dockerfile             # Backend container
│   ├── app.py                 # Main Flask application
│   ├── requirements.txt       # Python dependencies
│   └── uploads/              # File storage
├── web/                      # Frontend application
│   ├── Dockerfile           # Frontend container
│   ├── package.json         # Node.js dependencies
│   └── src/                # React source code
├── nginx/                   # Web server configuration
│   └── nginx.conf          # Nginx configuration
└── scripts/                # Deployment scripts
    ├── setup.sh           # Initial setup
    ├── backup.sh          # Database backup
    └── restore.sh         # Database restore
```

## 🔧 Configuration

### Environment Variables

#### Development (.env)
```bash
FLASK_SECRET_KEY=your-secret-key-here
DATABASE_URL=sqlite:///tickets.db
REDIS_URL=redis://redis:6379
CORS_ALLOWED_ORIGINS=http://localhost:3000
```

#### Production (.env.prod)
```bash
FLASK_SECRET_KEY=your-production-secret-key
DATABASE_URL=postgresql://user:pass@postgres:5432/helpdesk
REDIS_URL=redis://redis:6379
CORS_ALLOWED_ORIGINS=https://yourdomain.com
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
S3_BUCKET=your-s3-bucket
S3_REGION=us-east-1
SMTP_URL=smtp://user:pass@smtp.server:587
```

### Database Configuration

#### SQLite (Development)
- File-based database
- No additional setup required
- Data persists in `server/tickets.db`

#### PostgreSQL (Production)
- Containerized PostgreSQL
- Persistent volume storage
- Automatic backups
- Connection pooling

## 🚀 Deployment Options

### Option 1: Docker Compose (Recommended)

**Advantages:**
- Easy setup and maintenance
- Consistent environment
- Built-in service orchestration
- Easy scaling

**Setup:**
```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Start the application
docker-compose up -d
```

### Option 2: Manual Installation

**Prerequisites:**
- Python 3.11+
- Node.js 18+
- PostgreSQL 15+
- Nginx

**Backend Setup:**
```bash
cd server
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate      # Windows
pip install -r requirements.txt
python app.py
```

**Frontend Setup:**
```bash
cd web
npm install
npm run build
# Serve static files with Nginx
```

## 🔒 Security Configuration

### SSL/TLS Setup
```bash
# Generate SSL certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/private.key \
  -out nginx/ssl/certificate.crt

# Update Nginx configuration
cp nginx/nginx.prod.conf nginx/nginx.conf
```

### Security Headers
The application includes comprehensive security headers:
- Content Security Policy (CSP)
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Strict-Transport-Security
- X-XSS-Protection

### Authentication
- Session-based authentication
- Secure password hashing (Werkzeug)
- Session timeout (30 minutes)
- CSRF protection

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Application health
curl http://localhost:3000/health

# Database health
docker-compose exec api python -c "
import sqlite3
conn = sqlite3.connect('tickets.db')
print('Database OK')
conn.close()
"
```

### Logging
- Application logs: `docker-compose logs api`
- Web server logs: `docker-compose logs nginx`
- Database logs: `docker-compose logs postgres`

### Backup Procedures
```bash
# Create backup
./scripts/backup.sh

# Restore backup
./scripts/restore.sh backup-file.sql
```

## 🔄 Updates & Maintenance

### Application Updates
```bash
# Stop services
docker-compose down

# Pull latest images
docker-compose pull

# Start with new images
docker-compose up -d
```

### Database Migrations
```bash
# Run migrations (if using Alembic)
docker-compose exec api alembic upgrade head
```

### User Management
```bash
# Create admin user
docker-compose exec api python -c "
import sqlite3
conn = sqlite3.connect('tickets.db')
c = conn.cursor()
c.execute('UPDATE users SET role = ? WHERE username = ?', ('admin', 'username'))
conn.commit()
conn.close()
print('User updated to admin!')
"
```

## 🐛 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check logs
docker-compose logs

# Check port conflicts
netstat -tulpn | grep :3000
netstat -tulpn | grep :5000

# Restart services
docker-compose restart
```

**Database connection issues:**
```bash
# Check database status
docker-compose exec postgres pg_isready

# Reset database
docker-compose down
docker volume rm helpdesk_postgres_data
docker-compose up -d
```

**File upload issues:**
```bash
# Check upload directory permissions
ls -la server/uploads/

# Check disk space
df -h
```

**Performance issues:**
```bash
# Check resource usage
docker stats

# Check logs for errors
docker-compose logs api | grep ERROR
```

### Performance Optimization

**Database Optimization:**
- Regular VACUUM operations
- Index optimization
- Connection pooling

**Application Optimization:**
- Enable gzip compression
- Configure caching headers
- Optimize static file serving

**Infrastructure Optimization:**
- Use SSD storage
- Allocate sufficient RAM
- Configure swap space

## 📈 Scaling

### Horizontal Scaling
```bash
# Scale API instances
docker-compose up -d --scale api=3

# Use load balancer
# Configure Nginx upstream
```

### Vertical Scaling
- Increase container memory limits
- Add more CPU cores
- Use faster storage

## 🔐 Security Best Practices

### Production Security
1. **Change default secrets**
2. **Use strong passwords**
3. **Enable SSL/TLS**
4. **Configure firewall**
5. **Regular security updates**
6. **Monitor access logs**
7. **Implement backup encryption**

### Network Security
- Use reverse proxy (Nginx)
- Configure firewall rules
- Enable DDoS protection
- Use VPN for admin access

## 📞 Support & Maintenance

### Regular Maintenance Tasks
- **Daily**: Check application health
- **Weekly**: Review logs and performance
- **Monthly**: Update dependencies
- **Quarterly**: Security audit

### Emergency Procedures
1. **Service Down**: Check logs, restart services
2. **Data Loss**: Restore from backup
3. **Security Incident**: Isolate system, investigate
4. **Performance Issues**: Scale resources, optimize

### Contact Information
- **Technical Support**: [Your support contact]
- **Emergency Contact**: [Emergency contact]
- **Documentation**: See `CLIENT_GUIDE.md`

---

**Ready for production deployment!** Follow the Docker Compose setup for the easiest deployment experience.
