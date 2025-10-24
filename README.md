# Helpdesk Application

**Created by: Static Research Labs LLC**

A modern, production-ready helpdesk system built with React and Flask, designed for easy deployment and client delivery.

## Features

- **Complete Ticket Management** - Create, assign, and track support tickets
- **User Role System** - Admin, Tech, and User roles with appropriate permissions
- **File Attachments** - Upload files up to 10MB per ticket
- **Mobile Responsive** - Works perfectly on desktop, tablet, and mobile
- **Search & Filtering** - Find tickets quickly with status and priority filters
- **Ticket Status Sections** - Organized view with separate Open/Closed sections
- **Production Ready** - Security features, Docker deployment, and monitoring

## Technology Stack

- **Frontend**: React.js with Vite
- **Backend**: Flask (Python)
- **Database**: SQLite (dev) / PostgreSQL (production)
- **Deployment**: Docker & Docker Compose
- **Security**: CSRF protection, rate limiting, secure sessions

## Quick Start

### Prerequisites
- Docker and Docker Compose
- 2GB RAM minimum
- 10GB disk space

### Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/helpdesk.git
cd helpdesk

# Start the application
docker-compose up -d

# Access the application
open http://localhost:3000
```

### First Use
1. Open http://localhost:3000
2. Click "Create one here" to register
3. Create your first account
4. Start managing tickets!

## User Roles

### **User** (Default)
- Create and manage own tickets
- Upload attachments
- View ticket history

### **Tech**
- All User permissions
- Close tickets
- Assign tickets to users
- View all tickets

### **Admin**
- All Tech permissions
- User management
- System administration
- Access audit logs

## Project Structure

```
helpdesk/
├── server/                 # Flask backend
│   ├── app.py             # Main application
│   ├── requirements.txt   # Python dependencies
│   └── uploads/           # File storage
├── web/                   # React frontend
│   ├── src/               # Source code
│   ├── package.json       # Node dependencies
│   └── public/            # Static assets
├── nginx/                 # Web server config
├── scripts/               # Deployment scripts
├── docker-compose.yml     # Development setup
└── docker-compose.prod.yml # Production setup
```

## Development

### Backend Development
```bash
cd server
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate      # Windows
pip install -r requirements.txt
python app.py
```

### Frontend Development
```bash
cd web
npm install
npm run dev
```

## Production Deployment

### Docker Deployment
```bash
# Production deployment
docker-compose -f docker-compose.prod.yml up -d

# With SSL (optional)
./scripts/setup-ssl.sh yourdomain.com
```

### Manual Deployment
See `DEPLOYMENT_GUIDE.md` for detailed production deployment instructions.

## Documentation

- **[User Guide](CLIENT_GUIDE.md)** - End-user documentation
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - Technical deployment guide
- **[Security Guidelines](SECURITY_GUIDELINES.md)** - Security best practices
- **[API Documentation](server/app.py)** - Backend API endpoints

## Security Features

- **Secure password hashing** - Passwords are properly hashed and salted
- **Session management** - Secure sessions with timeout and proper cookies
- **CSRF protection** - Cross-site request forgery protection
- **Rate limiting** - Prevents abuse and brute force attacks
- **File upload validation** - Secure file handling with type validation
- **CORS configuration** - Proper cross-origin resource sharing setup
- **SQL injection protection** - Parameterized queries prevent SQL injection
- **Environment security** - Comprehensive `.gitignore` protects sensitive data
- **Security guidelines** - Complete documentation for handling secrets

## Monitoring

- Health check endpoints
- Structured logging
- Error reporting
- Performance monitoring
- Database backup/restore

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/helpdesk/issues)
- **Documentation**: See the docs folder
- **Contact**: [Your contact information]

## Acknowledgments

- Built with modern web technologies
- Designed for easy client delivery
- Production-ready from day one

---

**Ready to deploy!** This helpdesk system is designed to be easily deployed and delivered to clients.