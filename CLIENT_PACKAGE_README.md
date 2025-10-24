# Helpdesk Application - Client Delivery Package

## 📦 Package Contents

This package contains a complete, production-ready helpdesk application that can be deployed on any server with Docker support.

### 🚀 Quick Start (Recommended)

**Prerequisites:**
- Docker and Docker Compose installed
- 2GB RAM minimum
- 10GB disk space

**Deployment Steps:**
1. Extract this package to your server
2. Run: `docker-compose up -d`
3. Access: `http://your-server-ip:3000`
4. Create admin account and start using!

### 📁 Package Structure

```
helpdesk-client-package/
├── docker-compose.yml          # Main deployment configuration
├── docker-compose.prod.yml     # Production deployment
├── README.md                   # This file
├── CLIENT_GUIDE.md            # User guide for end users
├── DEPLOYMENT_GUIDE.md        # Technical deployment guide
├── server/                    # Backend application
│   ├── Dockerfile            # Backend container
│   ├── app.py               # Main application
│   ├── requirements.txt     # Python dependencies
│   └── uploads/            # File storage directory
├── web/                     # Frontend application
│   ├── Dockerfile          # Frontend container
│   ├── package.json        # Node.js dependencies
│   └── src/               # React source code
├── nginx/                  # Web server configuration
│   └── nginx.conf         # Nginx configuration
├── scripts/               # Deployment scripts
│   ├── setup.sh          # Initial setup script
│   ├── backup.sh         # Backup script
│   └── restore.sh        # Restore script
└── data/                 # Persistent data storage
    ├── postgres/         # Database files
    └── redis/           # Cache files
```

### 🔧 Deployment Options

#### Option 1: Development/Testing (Quick Start)
```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

#### Option 2: Production Deployment
```bash
# Production deployment with SSL
docker-compose -f docker-compose.prod.yml up -d

# Setup SSL certificates (optional)
./scripts/setup-ssl.sh yourdomain.com
```

### 🌐 Access Points

- **Main Application**: `http://your-server:3000`
- **API Documentation**: `http://your-server:3000/api/docs`
- **Health Check**: `http://your-server:3000/health`

### 👥 User Management

#### Creating Admin Users
```bash
# Access the container
docker-compose exec api python -c "
import sqlite3
conn = sqlite3.connect('tickets.db')
c = conn.cursor()
c.execute('UPDATE users SET role = ? WHERE username = ?', ('admin', 'your_username'))
conn.commit()
conn.close()
print('User updated to admin!')
"
```

#### Default Login
- Create a new account through the web interface
- Use the script above to promote to admin if needed

### 📊 Features Included

✅ **Complete Helpdesk System**
- Ticket creation and management
- User roles (Admin, Tech, User)
- File attachments
- Ticket status tracking
- Search and filtering
- Responsive web interface

✅ **Production Ready**
- Docker containerization
- Database persistence
- File upload handling
- Security features
- Error handling
- Logging

✅ **Easy Maintenance**
- Automated backups
- Health monitoring
- Update procedures
- Troubleshooting guides

### 🔒 Security Features

- Secure session management
- Password hashing
- File upload validation
- SQL injection protection
- CORS configuration
- Rate limiting

### 📈 Monitoring & Maintenance

#### Health Checks
```bash
# Check application health
curl http://your-server:3000/health

# Check database
docker-compose exec api python -c "import sqlite3; conn = sqlite3.connect('tickets.db'); print('DB OK')"
```

#### Backups
```bash
# Create backup
./scripts/backup.sh

# Restore backup
./scripts/restore.sh backup-file.sql
```

#### Updates
```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

### 🆘 Support & Troubleshooting

#### Common Issues

**Application won't start:**
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

**Database issues:**
```bash
# Reset database
docker-compose down
docker volume rm helpdesk_postgres_data
docker-compose up -d
```

**Port conflicts:**
- Edit `docker-compose.yml` to change ports
- Default ports: 3000 (web), 5000 (api), 5432 (db)

#### Getting Help

1. Check the logs: `docker-compose logs -f`
2. Review the troubleshooting section in `DEPLOYMENT_GUIDE.md`
3. Contact support with error messages and system details

### 📋 System Requirements

**Minimum:**
- 2GB RAM
- 2 CPU cores
- 10GB disk space
- Docker & Docker Compose

**Recommended:**
- 4GB RAM
- 4 CPU cores
- 50GB disk space
- Ubuntu 20.04+ or CentOS 8+

### 🔄 Updates & Maintenance

The application is designed for easy updates:

1. **Stop services**: `docker-compose down`
2. **Pull updates**: `docker-compose pull`
3. **Start services**: `docker-compose up -d`
4. **Verify**: Check health endpoint

### 📞 Support Information

- **Package Version**: 1.0.0
- **Created**: $(date)
- **Support Contact**: [Your contact information]
- **Documentation**: See `CLIENT_GUIDE.md` and `DEPLOYMENT_GUIDE.md`

---

**Ready to deploy!** Follow the Quick Start guide above to get your helpdesk system running in minutes.
