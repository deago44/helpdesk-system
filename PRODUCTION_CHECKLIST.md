# Helpdesk Production Readiness — Go‑Live Checklist

**Created by: Static Research Labs LLC**

This is a pragmatic, copy‑runnable checklist. Paste into Cursor and use it to validate your deployment. Replace placeholders like `<yourdomain>` and `<api.yourdomain>`.

---

## 0) Fill these in first

```md
- PROD WEB ORIGIN: https://yourdomain.com
- PROD API ORIGIN: https://api.yourdomain.com
- CONTACTS/ON‑CALL: <name/phone>
- IMAGE TAGS TO DEPLOY: helpdesk-api:latest, helpdesk-web:latest
```

---

## 1) Secrets & Env (must exist in a vault)

- [ ] `FLASK_SECRET_KEY` (>=32 bytes, rotated)
- [ ] `DATABASE_URL` (Postgres, TLS if managed)
- [ ] `REDIS_URL`
- [ ] `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `S3_BUCKET` / `S3_REGION`
- [ ] `SMTP_URL` (or SendGrid/SES)
- [ ] `CORS_ALLOWED_ORIGINS` = `https://yourdomain.com`
- [ ] No secrets in `.env` committed to repo

---

## 2) Database & Storage

**Migrate DB**
```bash
alembic upgrade head
```

**Postgres perms (no SUPERUSER)**
```sql
-- run as admin
REVOKE ALL ON DATABASE yourdb FROM public;
GRANT CONNECT ON DATABASE yourdb TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
```

**S3 bucket**
- [ ] Public access blocked; no public ACLs
- [ ] Lifecycle rules set (logs/backups)
- [ ] Server‑side encryption enabled

---

## 3) Network & TLS (Nginx)

**Headers present**
```bash
curl -sI https://yourdomain.com | grep -E "Strict-Transport-Security|Content-Security-Policy|X-Content-Type-Options|X-Frame-Options"
```

**CSP example (tighten as needed)**
```nginx
add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self' https://api.yourdomain.com" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
```

---

## 4) App Security Knobs

**CORS really locked**
```bash
curl -sI -H "Origin:https://evil.test" https://api.yourdomain.com/api/me | grep -i access-control-allow-origin || true
# Expect: no wildcard and no echo of the Origin
```

**Cookie flags on session**
```bash
# Login and inspect Set-Cookie
curl -si -X POST https://api.yourdomain.com/api/login  -H "Content-Type: application/json"  -d '{"username":"admin","password":"***"}' | grep -i set-cookie
# Expect: Secure; HttpOnly; SameSite=Strict
```

**CSRF enforcement (expect 403 without token)**
```bash
curl -si -X POST https://api.yourdomain.com/api/tickets  -H "Content-Type: application/json"  -d '{}' | head -n 1
```

**Rate limiting (expect some 429s)**
```bash
for i in {1..50}; do  curl -s -o /dev/null -w "%{http_code}\n"   -H "Content-Type: application/json"   -X POST https://api.yourdomain.com/api/password/request   -d '{"username":"admin"}'; done | sort | uniq -c
```

---

## 5) Deploy / Cutover (compose)

```bash
# 1) Migrate first
alembic upgrade head

# 2) Infra up
docker compose -f docker-compose.prod.yml up -d postgres redis

# 3) API + Nginx
docker compose -f docker-compose.prod.yml up -d api nginx

# 4) Seed roles + admin (customize scripts)
python scripts/seed_rbac.py
python scripts/create_admin.py --username admin --password '***'
```

---

## 6) Post‑Deploy Validation (happy path)

**Create ticket**
```bash
# assuming cookie jar auth handled by your tooling; else use browser
curl -s -X POST https://api.yourdomain.com/api/tickets  -H "Content-Type: application/json"  -b cookiejar -c cookiejar  -d '{"title":"Prod smoke","description":"after deploy","priority":"High"}' | jq .
```

**List with filters**
```bash
curl -s https://api.yourdomain.com/api/tickets?status=Open\&priority=High -b cookiejar | jq .total
```

**Attachments store in S3 (not local)**
- [ ] Upload via UI → Verify object appears in S3 with correct `Content-Type`
- [ ] No `public-read` ACL applied

**Password reset**
- [ ] Request reset → email received
- [ ] Token single‑use and expires (manually test reuse → reject)

**Frontend sanity**
- [ ] No mixed content warnings in browser console
- [ ] `/admin` visible to admin only

---

## 7) Monitoring & Alerts (minimum viable)

- [ ] `/healthz` on Nginx returns 200
- [ ] `/api/healthz` checks DB + Redis
- [ ] Error reporting (Sentry or equivalent) wired, DSN set
- [ ] p95 latency by route in logs/metrics
- [ ] Alerts on: 5xx rate spike, 429 surge, login failures spike
- [ ] Backups: nightly DB dump; alert on failure; restore tested monthly

---

## 8) Rollback Plan (write it, test it)

```bash
# Scale API to 0 (keep Nginx up to show maintenance)
docker compose -f docker-compose.prod.yml scale api=0

# Redeploy last known good tag
docker pull helpdesk-api:last_good
docker compose -f docker-compose.prod.yml up -d api

# If migration failure and safe to reverse:
alembic downgrade -1
```

- [ ] Validation repeated after rollback
- [ ] Incident notes captured

---

## 9) DR Drill (quarterly)

- [ ] Restore latest DB backup to fresh Postgres
- [ ] Point staging stack to it (read‑only creds)
- [ ] Sample 10 tickets for parity with prod

---

## 10) Operational Docs (checked into repo)

- [ ] `RUNBOOK.md` (alerts → actions, escalation)
- [ ] `SECURITY.md` (threats, patch cadence, secret rotation)
- [ ] `BACKUPS.md` (RPO/RTO, restore steps)
- [ ] `RELEASING.md` (versioning, promotion, rollback)
- [ ] `INFRA.md` (diagram, ports, CSP/CORS policies)

---

## Optional: quick preflight script (bash)

> Save as `scripts/preflight.sh`, `chmod +x`, run with your API domain.

```bash
#!/usr/bin/env bash
set -euo pipefail
API=${1:-https://api.yourdomain.com}

echo "[Headers]"
curl -sI $API | grep -E "Strict-Transport-Security|Content-Security-Policy|X-Content-Type-Options|X-Frame-Options" || true

echo "[CORS negative test]"
curl -sI -H "Origin:https://evil.test" $API/api/me | grep -i access-control-allow-origin || echo "OK (no ACAO)"

echo "[Rate limit probe (password reset)]"
for i in {1..40}; do
  curl -s -o /dev/null -w "%{http_code}\n"     -H "Content-Type: application/json"     -X POST $API/api/password/request     -d '{"username":"admin"}'
done | sort | uniq -c
```

---

### Pass/Fail Gate

- [ ] All checks above pass exactly as written
- [ ] Sign‑off recorded with timestamp and image tags

**If anything fails:** stop traffic, fix, retest. No "we'll patch later."

---

## Quick Commands Reference

### Pre-flight Checks
```bash
# Run preflight validation
./scripts/preflight.sh https://api.yourdomain.com

# Check security headers
curl -sI https://yourdomain.com | grep -E "Strict-Transport-Security|Content-Security-Policy"

# Test rate limiting
for i in {1..10}; do curl -s -w "%{http_code}\n" -X POST https://api.yourdomain.com/api/password/request -d '{"username":"test"}'; done
```

### Deployment
```bash
# Deploy to production
./scripts/deploy.sh v1.2.3

# Validate deployment
./scripts/validate.sh https://api.yourdomain.com https://yourdomain.com

# Check service status
docker-compose -f docker-compose.prod.yml ps
```

### Rollback
```bash
# Emergency rollback
./scripts/rollback.sh previous

# Validate rollback
./scripts/validate.sh https://api.yourdomain.com https://yourdomain.com
```

### Monitoring
```bash
# Check health
curl -s https://api.yourdomain.com/healthz

# Check logs
docker-compose -f docker-compose.prod.yml logs -f api

# Check metrics
docker stats
```

---

## Emergency Contacts

- **Primary On-Call**: <name/phone>
- **Secondary On-Call**: <name/phone>
- **Infrastructure Team**: <team/phone>
- **Security Team**: <team/phone>
- **Management**: <manager/phone>

---

## Sign-off

- [ ] **Technical Lead**: _________________ Date: _________
- [ ] **Security Team**: _________________ Date: _________
- [ ] **Operations Team**: _________________ Date: _________
- [ ] **Product Owner**: _________________ Date: _________

**Deployment Approved**: ✅ / ❌
**Go-Live Date**: _________
**Rollback Plan**: Confirmed and tested
