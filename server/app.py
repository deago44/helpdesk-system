import os
import sqlite3
import secrets
import mimetypes
from datetime import datetime, timedelta
from functools import wraps

from flask import Flask, request, jsonify, session, send_from_directory
from flask_cors import CORS
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "dev-change-me")
app.permanent_session_lifetime = timedelta(minutes=30)
CORS(app, supports_credentials=True)

app.config['UPLOAD_FOLDER'] = os.path.abspath('./uploads')
app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024  # 10 MB
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def db():
    return sqlite3.connect("tickets.db")

def init_db():
    conn = db(); c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'user'
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
        mime TEXT,
        size INTEGER,
        uploaded_at TEXT,
        uploader_id INTEGER
    )''')
    conn.commit(); conn.close()

def row_to_user(row):
    if not row: return None
    return {"id": row[0], "username": row[1], "password": row[2], "role": row[3]}

def row_to_ticket(row):
    if not row: return None
    return {"id": row[0], "title": row[1], "description": row[2], "status": row[3],
            "priority": row[4], "created_at": row[5], "updated_at": row[6],
            "assigned_to": row[7], "user_id": row[8]}

def get_current_user():
    if "user_id" not in session: return None
    conn = db(); c = conn.cursor()
    c.execute("SELECT * FROM users WHERE id=?", (session["user_id"],))
    u = row_to_user(c.fetchone()); conn.close(); return u

def json_error(msg, code=400):
    return jsonify({"error": msg}), code

def log_action(actor_id, action, entity, entity_id, details=""):
    conn = db(); c = conn.cursor()
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    c.execute("INSERT INTO audit_log(ts,actor_id,action,entity,entity_id,details) VALUES(?,?,?,?,?,?)",
              (ts, actor_id, action, entity, entity_id, details))
    conn.commit(); conn.close()

def signer():
    return URLSafeTimedSerializer(app.secret_key, salt="pwd-reset")

ALLOWED_EXTS = {"png","jpg","jpeg","pdf","txt","log","csv","mp4"}
def allowed_file(name):
    return "." in name and name.rsplit(".",1)[1].lower() in ALLOWED_EXTS

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

@app.post("/api/register")
def api_register():
    data = request.get_json(force=True)
    username = (data.get("username") or "").strip()
    password = data.get("password") or ""
    if not username or not password:
        return json_error("missing_fields", 400)
    conn = db(); c = conn.cursor()
    try:
        c.execute("INSERT INTO users(username,password) VALUES(?,?)",
                  (username, generate_password_hash(password)))
        conn.commit()
        return jsonify({"ok": True}), 201
    except sqlite3.IntegrityError:
        return json_error("username_taken", 409)
    finally:
        conn.close()

@app.post("/api/login")
def api_login():
    data = request.get_json(force=True)
    username = (data.get("username") or "").strip()
    password = data.get("password") or ""
    conn = db(); c = conn.cursor()
    c.execute("SELECT * FROM users WHERE username=?", (username,))
    user = row_to_user(c.fetchone()); conn.close()
    if user and check_password_hash(user["password"], password):
        session.permanent = True
        session["user_id"] = user["id"]
        return jsonify({"ok": True, "user": {"id": user["id"], "username": user["username"], "role": user["role"]}})
    return json_error("invalid_credentials", 401)

@app.post("/api/logout")
def api_logout():
    session.pop("user_id", None)
    return jsonify({"ok": True})

@app.get("/api/me")
def api_me():
    u = get_current_user()
    if not u: return jsonify({"user": None})
    return jsonify({"user": {"id": u["id"], "username": u["username"], "role": u["role"]}})

@app.get("/api/users")
@admin_required_json
def api_users_list():
    conn = db(); c = conn.cursor()
    c.execute("SELECT id, username, role FROM users ORDER BY id ASC")
    items = [{"id":r[0], "username":r[1], "role":r[2]} for r in c.fetchall()]
    conn.close()
    return jsonify(items)

@app.put("/api/users/<int:user_id>/role")
@admin_required_json
def api_users_role(user_id):
    data = request.get_json(force=True)
    role = (data.get("role") or "").strip()
    if role not in ("user","tech","admin"):
        return json_error("bad_role", 400)
    conn = db(); c = conn.cursor()
    c.execute("UPDATE users SET role=? WHERE id=?", (role, user_id))
    if c.rowcount == 0:
        conn.close(); return json_error("not_found", 404)
    conn.commit(); conn.close()
    log_action(get_current_user()["id"], "set_role", "user", user_id, role)
    return jsonify({"ok": True})

@app.get("/api/tickets")
@login_required_json
def api_list_tickets():
    u = get_current_user()
    status = (request.args.get("status") or "").strip()
    priority = (request.args.get("priority") or "").strip()
    page = max(int(request.args.get("page", 1)), 1)
    size = min(max(int(request.args.get("size", 20)), 1), 100)
    offset = (page - 1) * size

    base = "SELECT id,title,description,status,priority,created_at,updated_at,assigned_to,user_id FROM tickets"
    where, params = [], []

    if not is_admin_or_tech():
        where.append("user_id=?"); params.append(u["id"])
    if status and status in ("Open","Closed"):
        where.append("status=?"); params.append(status)
    if priority and priority in ("Low","Normal","High"):
        where.append("priority=?"); params.append(priority)

    where_sql = (" WHERE " + " AND ".join(where)) if where else ""
    order = " ORDER BY id DESC"
    limit = " LIMIT ? OFFSET ?"
    params_count = tuple(params)
    params += [size, offset]

    conn = db(); c = conn.cursor()
    c.execute(f"SELECT COUNT(*) FROM tickets{where_sql}", params_count)
    total = c.fetchone()[0]

    c.execute(base + where_sql + order + limit, tuple(params))
    rows = [row_to_ticket(r) for r in c.fetchall()]
    conn.close()
    return jsonify({"items": rows, "page": page, "size": size, "total": total})

@app.post("/api/tickets")
@login_required_json
def api_create_ticket():
    u = get_current_user()
    data = request.get_json(force=True)
    title = (data.get("title") or "").strip()
    description = (data.get("description") or "").strip()
    priority = (data.get("priority") or "Normal").strip()
    if not title or not description:
        return json_error("missing_fields", 400)
    if len(title) > 160: return json_error("title_too_long", 400)
    if len(description) > 10000: return json_error("description_too_long", 400)
    if priority not in ("Low","Normal","High"): return json_error("bad_priority", 400)
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    conn = db(); c = conn.cursor()
    c.execute('INSERT INTO tickets(title,description,priority,created_at,updated_at,user_id) VALUES(?,?,?,?,?,?)',
              (title, description, priority, now, now, u["id"]))
    conn.commit()
    ticket_id = c.lastrowid
    c.execute('SELECT id,title,description,status,priority,created_at,updated_at,assigned_to,user_id FROM tickets WHERE id=?', (ticket_id,))
    created = row_to_ticket(c.fetchone())
    conn.close()
    log_action(u["id"], "create", "ticket", ticket_id, f"title={title}")
    return jsonify(created), 201

@app.get("/api/tickets/<int:ticket_id>")
@login_required_json
def api_get_ticket(ticket_id):
    u = get_current_user()
    conn = db(); c = conn.cursor()
    c.execute('SELECT id,title,description,status,priority,created_at,updated_at,assigned_to,user_id FROM tickets WHERE id=?', (ticket_id,))
    t = row_to_ticket(c.fetchone())
    conn.close()
    if not t: return json_error("not_found", 404)
    if not is_admin_or_tech() and t["user_id"] != u["id"]:
        return json_error("forbidden", 403)
    return jsonify(t)

@app.put("/api/tickets/<int:ticket_id>")
@login_required_json
def api_update_ticket(ticket_id):
    u = get_current_user()
    data = request.get_json(force=True)
    conn = db(); c = conn.cursor()
    c.execute('SELECT id,title,description,status,priority,created_at,updated_at,assigned_to,user_id FROM tickets WHERE id=?', (ticket_id,))
    t = row_to_ticket(c.fetchone())
    if not t:
        conn.close(); return json_error("not_found", 404)
    if not is_admin_or_tech() and t["user_id"] != u["id"]:
        conn.close(); return json_error("forbidden", 403)

    title = (data.get("title", t["title"]) or "").strip()
    description = (data.get("description", t["description"]) or "").strip()
    priority = (data.get("priority", t["priority"]) or "").strip()
    status = data.get("status", t["status"] if not is_admin_or_tech() else data.get("status", t["status"]))
    if len(title) == 0 or len(title) > 160: 
        conn.close(); return json_error("bad_title", 400)
    if len(description) == 0 or len(description) > 10000:
        conn.close(); return json_error("bad_description", 400)
    if priority not in ("Low","Normal","High"):
        conn.close(); return json_error("bad_priority", 400)
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    c.execute('UPDATE tickets SET title=?, description=?, priority=?, status=?, updated_at=? WHERE id=?',
              (title, description, priority, status, now, ticket_id))
    conn.commit()
    c.execute('SELECT id,title,description,status,priority,created_at,updated_at,assigned_to,user_id FROM tickets WHERE id=?', (ticket_id,))
    updated = row_to_ticket(c.fetchone()); conn.close()
    log_action(u["id"], "update", "ticket", ticket_id, "")
    return jsonify(updated)

@app.delete("/api/tickets/<int:ticket_id>")
@login_required_json
def api_delete_ticket(ticket_id):
    u = get_current_user()
    conn = db(); c = conn.cursor()
    c.execute('SELECT user_id FROM tickets WHERE id=?', (ticket_id,))
    row = c.fetchone()
    if not row:
        conn.close(); return json_error("not_found", 404)
    owner_id = row[0]
    if not is_admin_or_tech() and owner_id != u["id"]:
        conn.close(); return json_error("forbidden", 403)
    c.execute('DELETE FROM tickets WHERE id=?', (ticket_id,))
    conn.commit(); conn.close()
    log_action(u["id"], "delete", "ticket", ticket_id, "")
    return jsonify({"ok": True})

@app.put("/api/tickets/<int:ticket_id>/assign")
@login_required_json
def api_assign(ticket_id):
    if not is_admin_or_tech(): return json_error("forbidden", 403)
    data = request.get_json(force=True)
    user_id = data.get("user_id")
    if not user_id: return json_error("missing_user_id", 400)
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    conn = db(); c = conn.cursor()
    c.execute('UPDATE tickets SET assigned_to=?, updated_at=? WHERE id=?', (user_id, now, ticket_id))
    if c.rowcount == 0: conn.close(); return json_error("not_found", 404)
    conn.commit(); conn.close()
    log_action(get_current_user()["id"], "assign", "ticket", ticket_id, f"to={user_id}")
    return jsonify({"ok": True})

@app.put("/api/tickets/<int:ticket_id>/close")
@login_required_json
def api_close(ticket_id):
    if not is_admin_or_tech(): return json_error("forbidden", 403)
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    conn = db(); c = conn.cursor()
    c.execute('UPDATE tickets SET status="Closed", updated_at=? WHERE id=?', (now, ticket_id))
    if c.rowcount == 0: conn.close(); return json_error("not_found", 404)
    conn.commit(); conn.close()
    log_action(get_current_user()["id"], "close", "ticket", ticket_id, "")
    return jsonify({"ok": True})

@app.post("/api/password/request")
def api_pwd_request():
    data = request.get_json(force=True)
    username = (data.get("username") or "").strip()
    if not username: return json_error("missing_username", 400)
    conn = db(); c = conn.cursor()
    c.execute('SELECT id, username FROM users WHERE username=?', (username,))
    row = c.fetchone(); conn.close()
    if not row:
        return jsonify({"ok": True})
    token = URLSafeTimedSerializer(app.secret_key, salt="pwd-reset").dumps({"uid": row[0], "u": row[1]})
    return jsonify({"ok": True, "token": token})

@app.post("/api/password/reset")
def api_pwd_reset():
    data = request.get_json(force=True)
    token = data.get("token"); newpw = data.get("password")
    if not token or not newpw: return json_error("missing_fields", 400)
    try:
        payload = URLSafeTimedSerializer(app.secret_key, salt="pwd-reset").loads(token, max_age=60*30)
        uid = payload["uid"]
    except SignatureExpired:
        return json_error("token_expired", 400)
    except BadSignature:
        return json_error("bad_token", 400)
    conn = db(); c = conn.cursor()
    c.execute('UPDATE users SET password=? WHERE id=?', (generate_password_hash(newpw), uid))
    conn.commit(); conn.close()
    return jsonify({"ok": True})

@app.post("/api/tickets/<int:ticket_id>/attachments")
@login_required_json
def api_attach(ticket_id):
    u = get_current_user()
    if 'file' not in request.files: return json_error("missing_file", 400)
    f = request.files['file']
    if f.filename == '': return json_error("empty_filename", 400)
    if not allowed_file(f.filename): return json_error("ext_not_allowed", 400)
    conn = db(); c = conn.cursor()
    c.execute('SELECT user_id FROM tickets WHERE id=?', (ticket_id,))
    row = c.fetchone()
    if not row:
        conn.close(); return json_error("not_found", 404)
    owner_id = row[0]
    if not is_admin_or_tech() and owner_id != u["id"]:
        conn.close(); return json_error("forbidden", 403)
    safe = secure_filename(f.filename)
    rid = secrets.token_hex(8)
    stored = f"{rid}_{safe}"
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], stored)
    f.save(filepath)
    size = os.path.getsize(filepath)
    mime = mimetypes.guess_type(filepath)[0] or "application/octet-stream"
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    c.execute('INSERT INTO attachments(ticket_id,filename,stored_path,mime,size,uploaded_at,uploader_id) VALUES(?,?,?,?,?,?,?)',
              (ticket_id, safe, stored, mime, size, now, u["id"]))
    conn.commit(); conn.close()
    log_action(u["id"], "attach", "ticket", ticket_id, safe)
    return jsonify({"ok": True, "filename": safe, "size": size, "mime": mime})

@app.get("/api/tickets/<int:ticket_id>/attachments")
@login_required_json
def api_list_attachments(ticket_id):
    u = get_current_user()
    conn = db(); c = conn.cursor()
    c.execute('SELECT user_id FROM tickets WHERE id=?', (ticket_id,))
    row = c.fetchone()
    if not row: conn.close(); return json_error("not_found", 404)
    if not is_admin_or_tech() and row[0] != u["id"]:
        conn.close(); return json_error("forbidden", 403)
    c.execute('SELECT id,filename,stored_path,mime,size,uploaded_at,uploader_id FROM attachments WHERE ticket_id=? ORDER BY id DESC', (ticket_id,))
    items = [{"id":r[0], "filename":r[1], "path":r[2], "mime":r[3], "size":r[4],
              "uploaded_at":r[5], "uploader_id":r[6]} for r in c.fetchall()]
    conn.close()
    return jsonify(items)

@app.get("/uploads/<path:name>")
@login_required_json
def serve_upload(name):
    if ".." in name or name.startswith("/"):
        return json_error("forbidden", 403)
    return send_from_directory(app.config['UPLOAD_FOLDER'], name)

@app.get("/api/audit")
@login_required_json
def api_audit_list():
    if not is_admin_or_tech(): return json_error("forbidden", 403)
    page = max(int(request.args.get("page", 1)), 1)
    size = min(max(int(request.args.get("size", 20)), 1), 100)
    offset = (page - 1) * size
    conn = db(); c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM audit_log")
    total = c.fetchone()[0]
    c.execute('SELECT id,ts,actor_id,action,entity,entity_id,details FROM audit_log ORDER BY id DESC LIMIT ? OFFSET ?', (size, offset))
    items = [{"id":r[0],"ts":r[1],"actor_id":r[2],"action":r[3],"entity":r[4],
              "entity_id":r[5],"details":r[6]} for r in c.fetchall()]
    conn.close()
    return jsonify({"items": items, "page": page, "size": size, "total": total})

@app.get("/")
def root():
    return "<h3>Helpdesk API online. Use /api/* endpoints.</h3>"

if __name__ == "__main__":
    init_db()
    app.run(debug=True)
