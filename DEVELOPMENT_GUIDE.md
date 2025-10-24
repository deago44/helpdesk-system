# Development Setup Guide

**Created by: Static Research Labs LLC**

This guide shows you how to run the helpdesk application for development and testing.

## Quick Start (Development)

### Prerequisites
- Python 3.8+ installed
- Node.js 16+ installed
- Git installed

### Option 1: Docker Development (Recommended)

1. **Navigate to the project folder:**
   ```bash
   cd "C:\Users\JAS Student\Documents\Helpdesk\helpdesk"
   ```

2. **Start the application:**
   ```bash
   docker-compose up -d
   ```

3. **Access the application:**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000

4. **Stop the application:**
   ```bash
   docker-compose down
   ```

### Option 2: Manual Development Setup

#### Backend Setup
1. **Navigate to server folder:**
   ```bash
   cd "C:\Users\JAS Student\Documents\Helpdesk\helpdesk\server"
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv .venv
   ```

3. **Activate virtual environment:**
   ```bash
   # Windows
   .venv\Scripts\activate
   
   # Linux/Mac
   source .venv/bin/activate
   ```

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

5. **Start the backend:**
   ```bash
   python app.py
   ```

#### Frontend Setup
1. **Open new terminal and navigate to web folder:**
   ```bash
   cd "C:\Users\JAS Student\Documents\Helpdesk\helpdesk\web"
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Start the frontend:**
   ```bash
   npm run dev
   ```

4. **Access the application:**
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:5000

## Development Workflow

### Making Changes
1. **Edit code** in your preferred editor
2. **Backend changes** - restart the Python server
3. **Frontend changes** - hot reload (automatic)
4. **Test changes** in the browser

### Database Management
- **Development database**: `server/tickets.db` (SQLite)
- **Reset database**: Delete `tickets.db` file and restart
- **View database**: Use SQLite browser or command line

### File Structure
```
helpdesk/
├── server/           # Backend development
│   ├── app.py       # Main Flask application
│   ├── uploads/     # File uploads (create if needed)
│   └── tickets.db   # SQLite database (auto-created)
├── web/             # Frontend development
│   ├── src/         # React source code
│   └── package.json # Node dependencies
└── docker-compose.yml # Docker development setup
```

## Common Development Tasks

### Create Admin User
1. **Start the application**
2. **Register a new account** via the web interface
3. **Promote to admin** using the database:
   ```bash
   cd server
   python -c "
   import sqlite3
   conn = sqlite3.connect('tickets.db')
   c = conn.cursor()
   c.execute('UPDATE users SET role = \"admin\" WHERE username = \"yourusername\"')
   conn.commit()
   conn.close()
   print('User promoted to admin')
   "
   ```

### Reset Application Data
1. **Stop the application**
2. **Delete database file**: `server/tickets.db`
3. **Delete uploads**: `server/uploads/*` (if any)
4. **Restart the application**

### View Logs
- **Docker logs**: `docker-compose logs -f`
- **Backend logs**: Check terminal running `python app.py`
- **Frontend logs**: Check terminal running `npm run dev`

## Production vs Development

### Development (what you're running)
- Uses SQLite database
- Debug mode enabled
- Hot reload for frontend
- Local file uploads
- Basic security settings

### Production (client packages)
- Uses PostgreSQL database
- Debug mode disabled
- Optimized builds
- S3 file storage
- Enhanced security features

## Troubleshooting

### Port Already in Use
- **Backend (5000)**: Kill process using port 5000
- **Frontend (5173)**: Kill process using port 5173
- **Docker**: Run `docker-compose down` first

### Database Issues
- Delete `server/tickets.db` and restart
- Check file permissions
- Ensure SQLite is working

### Frontend Not Loading
- Check if backend is running on port 5000
- Verify CORS settings
- Check browser console for errors

## Next Steps

1. **Start developing** using the Docker method
2. **Make your changes** to the code
3. **Test thoroughly** before creating client packages
4. **Create new client packages** when ready to deliver updates

---

**Development Environment**: Use `helpdesk/` folder
**Client Delivery**: Use `client-packages/` folder
