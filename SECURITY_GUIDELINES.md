# Security Guidelines for Helpdesk Application

**Created by: Static Research Labs LLC**

## Sensitive Information Protection

This document outlines how to properly handle sensitive information in the helpdesk application.

### **NEVER COMMIT THESE FILES**

The following files contain or may contain sensitive information and are automatically excluded from Git:

#### **Environment Files**
- `.env` - Contains actual secrets
- `.env.local` - Local development secrets
- `.env.production` - Production secrets
- `.env.staging` - Staging environment secrets
- `.env.*` - Any environment-specific files

#### **Database Files**
- `server/tickets.db` - Contains user data and tickets
- `server/tickets_*.db` - Any database files
- `*.db`, `*.sqlite`, `*.sqlite3` - Database files

#### **Configuration Files**
- `config.json` - May contain API keys
- `secrets.json` - Contains secrets
- `credentials.json` - Contains credentials
- `*.key`, `*.pem`, `*.p12`, `*.pfx` - Certificate files

#### **Upload Directories**
- `server/uploads/` - Contains user-uploaded files
- `uploads/`, `files/`, `attachments/` - File storage

#### **Backup Files**
- `backups/` - Database backups
- `*.backup`, `*.sql`, `*.dump` - Backup files

#### **Log Files**
- `logs/` - May contain sensitive information
- `*.log` - Log files

### **SAFE TO COMMIT**

These files are safe to commit as they contain only templates or examples:

- `env.example` - Environment variable template
- `server/.env.example` - Server environment template
- `server/.env.development` - Development template (no real secrets)
- `server/.env.production` - Production template (no real secrets)
- `web/.env.example` - Frontend environment template

### Security Best Practices

#### **1. Environment Variables**
```bash
# Copy the template
cp env.example .env

# Edit with your actual values
nano .env
```

#### **2. Secret Key Generation**
```python
# Generate a secure secret key
import secrets
print(secrets.token_hex(32))
```

#### **3. Database Security**
- Use strong passwords
- Enable SSL/TLS for production
- Regular backups with encryption
- Access control and user permissions

#### **4. File Upload Security**
- Validate file types
- Scan for malware
- Store outside web root
- Use signed URLs for access

#### **5. Production Deployment**
- Use HTTPS only
- Enable security headers
- Regular security updates
- Monitor for vulnerabilities

### Security Checklist

Before deploying to production:

- [ ] Change all default passwords
- [ ] Generate new secret keys
- [ ] Configure HTTPS/TLS
- [ ] Enable security headers
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Test security features
- [ ] Review access controls

### If Secrets Are Accidentally Committed

If sensitive information is accidentally committed:

1. **Immediately rotate secrets**:
   - Change passwords
   - Generate new API keys
   - Update certificates

2. **Remove from Git history**:
   ```bash
   # Remove file from history
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch .env' \
     --prune-empty --tag-name-filter cat -- --all
   
   # Force push to remote
   git push origin --force --all
   ```

3. **Update .gitignore**:
   - Ensure sensitive files are excluded
   - Test with `git check-ignore <file>`

### Security Contact

For security issues or questions:
- **Email**: [Your security email]
- **Issues**: [GitHub Issues](https://github.com/yourusername/helpdesk/issues)

### Regular Security Maintenance

- **Monthly**: Review access logs
- **Quarterly**: Update dependencies
- **Annually**: Security audit
- **As needed**: Rotate secrets

---

**Remember**: Security is everyone's responsibility. When in doubt, ask before committing sensitive information.
