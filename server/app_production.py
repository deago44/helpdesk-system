import os
import secrets
import mimetypes
from datetime import datetime, timedelta
from functools import wraps
import structlog
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration

from flask import Flask, request, jsonify, session, send_from_directory
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_wtf.csrf import CSRFProtect
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import boto3
from email_validator import validate_email, EmailNotValidError

# Initialize structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Initialize Sentry for error reporting
if os.getenv('SENTRY_DSN'):
    sentry_sdk.init(
        dsn=os.getenv('SENTRY_DSN'),
        integrations=[FlaskIntegration()],
        traces_sample_rate=0.1,
    )

app = Flask(__name__)

# Security Configuration
app.secret_key = os.getenv("FLASK_SECRET_KEY", "dev-change-me")
app.permanent_session_lifetime = timedelta(minutes=30)

# Secure session cookies
app.config.update(
    SESSION_COOKIE_SECURE=os.getenv('SESSION_COOKIE_SECURE', 'False').lower() == 'true',
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE='Lax',
    SESSION_COOKIE_NAME='helpdesk_session'
)

# CORS configuration - lock to specific domain in production
allowed_origins = os.getenv('CORS_ALLOWED_ORIGINS', 'http://localhost:5173').split(',')
CORS(app, supports_credentials=True, origins=allowed_origins)

# Rate limiting
limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["1000 per day", "100 per hour"]
)

# CSRF Protection
csrf = CSRFProtect(app)

# Database configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///tickets.db')
if DATABASE_URL.startswith('postgresql://'):
    import psycopg2
    from psycopg2.extras import RealDictCursor
    
    def get_db_connection():
        return psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
else:
    import sqlite3
    def get_db_connection():
        return sqlite3.connect("tickets.db")

# S3 Configuration for file storage
S3_BUCKET = os.getenv('S3_BUCKET')
S3_REGION = os.getenv('S3_REGION', 'us-east-1')
if S3_BUCKET:
    s3_client = boto3.client(
        's3',
        region_name=S3_REGION,
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY')
    )

# Email configuration
SMTP_SERVER = os.getenv('SMTP_SERVER')
SMTP_PORT = int(os.getenv('SMTP_PORT', '587'))
SMTP_USERNAME = os.getenv('SMTP_USERNAME')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD')
SMTP_FROM = os.getenv('SMTP_FROM', 'noreply@helpdesk.local')

# Local uploads fallback
app.config['UPLOAD_FOLDER'] = os.path.abspath('./uploads')
app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024  # 10 MB
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def init_db():
    """Initialize database with proper schema"""
    conn = get_db_connection()
    c = conn.cursor()
    
    if DATABASE_URL.startswith('postgresql://'):
        # PostgreSQL schema
        c.execute('''CREATE TABLE IF NOT EXISTS users(
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(255) UNIQUE,
            password VARCHAR(255) NOT NULL,
            role VARCHAR(20) DEFAULT 'user',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS tickets(
            id SERIAL PRIMARY KEY,
            title VARCHAR(160) NOT NULL,
            description TEXT NOT NULL,
            status VARCHAR(20) DEFAULT 'Open',
            priority VARCHAR(20) DEFAULT 'Normal',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            assigned_to INTEGER,
            user_id INTEGER,
            FOREIGN KEY (assigned_to) REFERENCES users(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS audit_log(
            id SERIAL PRIMARY KEY,
            ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            actor_id INTEGER,
            action VARCHAR(50),
            entity VARCHAR(50),
            entity_id INTEGER,
            details TEXT
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS attachments(
            id SERIAL PRIMARY KEY,
            ticket_id INTEGER,
            filename VARCHAR(255),
            stored_path VARCHAR(500),
            s3_key VARCHAR(500),
            mime VARCHAR(100),
            size INTEGER,
            uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            uploader_id INTEGER
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS password_reset_tokens(
            id SERIAL PRIMARY KEY,
            user_id INTEGER,
            token VARCHAR(255) UNIQUE,
            expires_at TIMESTAMP,
            used BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
    else:
        # SQLite schema (fallback)
        c.execute('''CREATE TABLE IF NOT EXISTS users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE,
            password TEXT NOT NULL,
            role TEXT DEFAULT 'user',
            created_at TEXT,
            updated_at TEXT
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS tickets(
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
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS audit_log(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts TEXT,
            actor_id INTEGER,
            action TEXT,
            entity TEXT,
            entity_id INTEGER,
            details TEXT
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS attachments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticket_id INTEGER,
            filename TEXT,
            stored_path TEXT,
            s3_key TEXT,
            mime TEXT,
            size INTEGER,
            uploaded_at TEXT,
            uploader_id INTEGER
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS password_reset_tokens(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            token TEXT UNIQUE,
            expires_at TEXT,
            used BOOLEAN DEFAULT FALSE,
            created_at TEXT
        )''')
    
    conn.commit()
    conn.close()

def row_to_user(row):
    if not row: return None
    if DATABASE_URL.startswith('postgresql://'):
        return {"id": row['id'], "username": row['username'], "email": row.get('email'), 
                "password": row['password'], "role": row['role']}
    else:
        return {"id": row[0], "username": row[1], "email": row[2] if len(row) > 2 else None, 
                "password": row[2] if len(row) == 4 else row[3], "role": row[3] if len(row) == 4 else row[4]}

def row_to_ticket(row):
    if not row: return None
    if DATABASE_URL.startswith('postgresql://'):
        return {"id": row['id'], "title": row['title'], "description": row['description'], 
                "status": row['status'], "priority": row['priority'], "created_at": str(row['created_at']), 
                "updated_at": str(row['updated_at']), "assigned_to": row['assigned_to'], "user_id": row['user_id']}
    else:
        return {"id": row[0], "title": row[1], "description": row[2], "status": row[3],
                "priority": row[4], "created_at": row[5], "updated_at": row[6],
                "assigned_to": row[7], "user_id": row[8]}

def get_current_user():
    if "user_id" not in session: return None
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT * FROM users WHERE id=%s" if DATABASE_URL.startswith('postgresql://') else "SELECT * FROM users WHERE id=?", (session["user_id"],))
    u = row_to_user(c.fetchone())
    conn.close()
    return u

def json_error(msg, code=400):
    logger.error("API error", error=msg, code=code, user_id=session.get('user_id'))
    return jsonify({"error": msg}), code

def log_action(actor_id, action, entity, entity_id, details=""):
    conn = get_db_connection()
    c = conn.cursor()
    if DATABASE_URL.startswith('postgresql://'):
        c.execute("INSERT INTO audit_log(actor_id,action,entity,entity_id,details) VALUES(%s,%s,%s,%s,%s)",
                  (actor_id, action, entity, entity_id, details))
    else:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        c.execute("INSERT INTO audit_log(ts,actor_id,action,entity,entity_id,details) VALUES(?,?,?,?,?,?)",
                  (ts, actor_id, action, entity, entity_id, details))
    conn.commit()
    conn.close()

def send_email(to_email, subject, body):
    """Send email using SMTP or fallback to logging"""
    if not SMTP_SERVER:
        logger.info("Email would be sent", to=to_email, subject=subject)
        return
    
    try:
        import smtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart
        
        msg = MIMEMultipart()
        msg['From'] = SMTP_FROM
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))
        
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        if SMTP_USERNAME:
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
        server.send_message(msg)
        server.quit()
        logger.info("Email sent successfully", to=to_email, subject=subject)
    except Exception as e:
        logger.error("Failed to send email", error=str(e), to=to_email)

def upload_file_to_s3(file, key):
    """Upload file to S3 or return local path"""
    if S3_BUCKET:
        try:
            s3_client.upload_fileobj(file, S3_BUCKET, key)
            return f"s3://{S3_BUCKET}/{key}"
        except Exception as e:
            logger.error("S3 upload failed", error=str(e))
            raise
    
    # Fallback to local storage
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], key)
    file.save(filepath)
    return filepath

def get_file_url(s3_key_or_path):
    """Get URL for file (S3 signed URL or local path)"""
    if s3_key_or_path.startswith('s3://'):
        bucket, key = s3_key_or_path[5:].split('/', 1)
        return s3_client.generate_presigned_url('get_object', Params={'Bucket': bucket, 'Key': key}, ExpiresIn=3600)
    return s3_key_or_path

# Security decorators
def login_required_json(f):
    @wraps(f)
    def wrapped(*args, **kwargs):
        if not get_current_user():
            return json_error("auth_required", 401)
        return f(*args, **kwargs)
    return wrapped

def admin_required_json(f):
    @wraps(f)
    def wrapped(*args, **kwargs):
        u = get_current_user()
        if not u or u["role"] != "admin":
            return json_error("forbidden", 403)
        return f(*args, **kwargs)
    return wrapped

def is_admin_or_tech():
    u = get_current_user()
    return bool(u and u["role"] in ("admin", "tech"))

# API Routes with enhanced security
@app.post("/api/register")
@limiter.limit("5 per minute")
def api_register():
    data = request.get_json(force=True)
    username = (data.get("username") or "").strip()
    email = (data.get("email") or "").strip()
    password = data.get("password") or ""
    
    if not username or not password:
        return json_error("missing_fields", 400)
    
    # Validate email if provided
    if email:
        try:
            validate_email(email)
        except EmailNotValidError:
            return json_error("invalid_email", 400)
    
    conn = get_db_connection()
    c = conn.cursor()
    try:
        if DATABASE_URL.startswith('postgresql://'):
            c.execute("INSERT INTO users(username,email,password) VALUES(%s,%s,%s)",
                      (username, email or None, generate_password_hash(password)))
        else:
            c.execute("INSERT INTO users(username,email,password) VALUES(?,?,?)",
                      (username, email or None, generate_password_hash(password)))
        conn.commit()
        logger.info("User registered", username=username, email=email)
        return jsonify({"ok": True}), 201
    except Exception as e:
        if "unique" in str(e).lower():
            return json_error("username_taken", 409)
        raise
    finally:
        conn.close()

@app.post("/api/login")
@limiter.limit("10 per minute")
def api_login():
    data = request.get_json(force=True)
    username = (data.get("username") or "").strip()
    password = data.get("password") or ""
    
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT * FROM users WHERE username=%s" if DATABASE_URL.startswith('postgresql://') else "SELECT * FROM users WHERE username=?", (username,))
    user = row_to_user(c.fetchone())
    conn.close()
    
    if user and check_password_hash(user["password"], password):
        session.permanent = True
        session["user_id"] = user["id"]
        logger.info("User logged in", user_id=user["id"], username=username)
        return jsonify({"ok": True, "user": {"id": user["id"], "username": user["username"], "role": user["role"]}})
    
    logger.warning("Failed login attempt", username=username, ip=request.remote_addr)
    return json_error("invalid_credentials", 401)

@app.post("/api/password/request")
@limiter.limit("3 per minute")
def api_pwd_request():
    data = request.get_json(force=True)
    username = (data.get("username") or "").strip()
    if not username: 
        return json_error("missing_username", 400)
    
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT id, username, email FROM users WHERE username=%s" if DATABASE_URL.startswith('postgresql://') else "SELECT id, username, email FROM users WHERE username=?", (username,))
    row = c.fetchone()
    conn.close()
    
    if not row:
        # Don't reveal if user exists
        return jsonify({"ok": True})
    
    # Generate secure token
    token = secrets.token_urlsafe(32)
    expires_at = datetime.now() + timedelta(hours=1)
    
    conn = get_db_connection()
    c = conn.cursor()
    if DATABASE_URL.startswith('postgresql://'):
        c.execute("INSERT INTO password_reset_tokens(user_id, token, expires_at) VALUES(%s, %s, %s)",
                  (row['id'], token, expires_at))
    else:
        c.execute("INSERT INTO password_reset_tokens(user_id, token, expires_at) VALUES(?, ?, ?)",
                  (row[0], token, expires_at.strftime("%Y-%m-%d %H:%M:%S")))
    conn.commit()
    conn.close()
    
    # Send email
    reset_url = f"{os.getenv('FRONTEND_URL', 'http://localhost:5173')}/reset?token={token}"
    email_body = f"Click the following link to reset your password:\n\n{reset_url}\n\nThis link expires in 1 hour."
    send_email(row['email'] if DATABASE_URL.startswith('postgresql://') else row[2], "Password Reset Request", email_body)
    
    logger.info("Password reset requested", username=username)
    return jsonify({"ok": True})

@app.post("/api/password/reset")
@limiter.limit("5 per minute")
def api_pwd_reset():
    data = request.get_json(force=True)
    token = data.get("token")
    newpw = data.get("password")
    
    if not token or not newpw:
        return json_error("missing_fields", 400)
    
    conn = get_db_connection()
    c = conn.cursor()
    if DATABASE_URL.startswith('postgresql://'):
        c.execute("SELECT user_id FROM password_reset_tokens WHERE token=%s AND expires_at > NOW() AND used = FALSE", (token,))
    else:
        c.execute("SELECT user_id FROM password_reset_tokens WHERE token=? AND expires_at > ? AND used = 0", 
                  (token, datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
    
    row = c.fetchone()
    if not row:
        conn.close()
        return json_error("invalid_or_expired_token", 400)
    
    user_id = row['user_id'] if DATABASE_URL.startswith('postgresql://') else row[0]
    
    # Update password and mark token as used
    if DATABASE_URL.startswith('postgresql://'):
        c.execute("UPDATE users SET password=%s WHERE id=%s", (generate_password_hash(newpw), user_id))
        c.execute("UPDATE password_reset_tokens SET used=TRUE WHERE token=%s", (token,))
    else:
        c.execute("UPDATE users SET password=? WHERE id=?", (generate_password_hash(newpw), user_id))
        c.execute("UPDATE password_reset_tokens SET used=1 WHERE token=?", (token,))
    
    conn.commit()
    conn.close()
    
    logger.info("Password reset completed", user_id=user_id)
    return jsonify({"ok": True})

# Health check endpoint
@app.get("/health")
def health_check():
    try:
        conn = get_db_connection()
        c = conn.cursor()
        c.execute("SELECT 1")
        conn.close()
        return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})
    except Exception as e:
        logger.error("Health check failed", error=str(e))
        return jsonify({"status": "unhealthy", "error": str(e)}), 503

# Add all other routes from original app.py with similar security enhancements...
# (I'll continue with the remaining routes in the next part)

if __name__ == "__main__":
    init_db()
    app.run(debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true')
