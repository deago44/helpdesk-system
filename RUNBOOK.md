# Helpdesk Production Runbook

**Created by: Static Research Labs LLC**

## Emergency Contacts

- **Primary On-Call**: <name/phone>
- **Secondary On-Call**: <name/phone>
- **Escalation**: <manager/phone>
- **Infrastructure Team**: <team/phone>

## Quick Status Check

```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# Check health endpoints
curl -s https://yourdomain.com/healthz
curl -s https://api.yourdomain.com/healthz

# Check logs
docker-compose -f docker-compose.prod.yml logs -f --tail=100
```

## Common Alerts and Actions

### High Severity Alerts

#### 1. Application Down (5xx errors > 10%)
**Symptoms**: High error rate, users cannot access application
**Actions**:
1. Check service status: `docker-compose -f docker-compose.prod.yml ps`
2. Check logs: `docker-compose -f docker-compose.prod.yml logs -f api`
3. Check database connectivity: `curl -s https://api.yourdomain.com/healthz`
4. If database issue, check PostgreSQL: `docker-compose -f docker-compose.prod.yml logs postgres`
5. If persistent, consider rollback: `./scripts/rollback.sh previous`

#### 2. Database Connection Errors
**Symptoms**: Database connection timeouts, query failures
**Actions**:
1. Check PostgreSQL status: `docker-compose -f docker-compose.prod.yml logs postgres`
2. Check database connectivity: `docker-compose -f docker-compose.prod.yml exec postgres pg_isready`
3. Check disk space: `df -h`
4. Check memory usage: `free -h`
5. If disk full, clean up logs: `docker system prune -f`

#### 3. High Memory Usage
**Symptoms**: System memory usage > 90%
**Actions**:
1. Check memory usage: `free -h`
2. Check Docker memory usage: `docker stats`
3. Restart services if needed: `docker-compose -f docker-compose.prod.yml restart api`
4. Check for memory leaks in logs

### Medium Severity Alerts

#### 4. Rate Limiting Triggered (429 errors)
**Symptoms**: High rate of 429 responses
**Actions**:
1. Check if legitimate traffic: `docker-compose -f docker-compose.prod.yml logs api | grep 429`
2. Check Redis connectivity: `docker-compose -f docker-compose.prod.yml logs redis`
3. If Redis issue, restart Redis: `docker-compose -f docker-compose.prod.yml restart redis`
4. If legitimate traffic, consider adjusting rate limits

#### 5. File Upload Failures
**Symptoms**: Users cannot upload attachments
**Actions**:
1. Check S3 connectivity: `docker-compose -f docker-compose.prod.yml logs api | grep -i s3`
2. Check AWS credentials and permissions
3. Check S3 bucket status and permissions
4. Verify file size limits

#### 6. Email Delivery Issues
**Symptoms**: Password reset emails not sent
**Actions**:
1. Check SMTP configuration: `docker-compose -f docker-compose.prod.yml logs api | grep -i smtp`
2. Check SMTP server status
3. Verify email credentials and permissions
4. Check spam filters

### Low Severity Alerts

#### 7. High Response Times
**Symptoms**: p95 latency > 2 seconds
**Actions**:
1. Check system resources: `htop`
2. Check database query performance
3. Check slow queries in logs
4. Consider scaling if persistent

#### 8. Disk Space Warnings
**Symptoms**: Disk usage > 80%
**Actions**:
1. Check disk usage: `df -h`
2. Clean up old logs: `docker system prune -f`
3. Clean up old backups: `find ./backups -name "*.sql" -mtime +30 -delete`
4. Monitor and plan for disk expansion

## Deployment Procedures

### Standard Deployment
```bash
# 1. Run preflight checks
./scripts/preflight.sh https://api.yourdomain.com

# 2. Deploy
./scripts/deploy.sh v1.2.3

# 3. Validate deployment
./scripts/validate.sh https://api.yourdomain.com https://yourdomain.com
```

### Emergency Rollback
```bash
# 1. Rollback to previous version
./scripts/rollback.sh previous

# 2. Validate rollback
./scripts/validate.sh https://api.yourdomain.com https://yourdomain.com

# 3. Monitor for stability
docker-compose -f docker-compose.prod.yml logs -f api
```

### Database Migration
```bash
# 1. Backup current database
./scripts/backup.py

# 2. Run migrations
docker-compose -f docker-compose.prod.yml run --rm api alembic upgrade head

# 3. Validate migration
docker-compose -f docker-compose.prod.yml exec api python -c "from app_production import get_db_connection; conn = get_db_connection(); print('Migration successful')"
```

## Monitoring and Logging

### Key Metrics to Monitor
- Response time (p95 < 2s)
- Error rate (< 1%)
- Database connection pool usage
- Memory usage (< 80%)
- Disk usage (< 80%)
- Rate limiting triggers

### Log Locations
- Application logs: `docker-compose -f docker-compose.prod.yml logs api`
- Nginx logs: `docker-compose -f docker-compose.prod.yml logs nginx`
- Database logs: `docker-compose -f docker-compose.prod.yml logs postgres`
- System logs: `journalctl -u docker`

### Log Analysis Commands
```bash
# Check for errors in last hour
docker-compose -f docker-compose.prod.yml logs --since=1h api | grep -i error

# Check for slow requests
docker-compose -f docker-compose.prod.yml logs api | grep -E "rt=[0-9]+\.[0-9]+" | awk '{print $NF}' | sort -n

# Check for rate limiting
docker-compose -f docker-compose.prod.yml logs api | grep "429"
```

## Backup and Recovery

### Backup Procedures
```bash
# Daily automated backup (cron job)
0 2 * * * /opt/helpdesk/scripts/backup.py

# Manual backup
./scripts/backup.py

# Verify backup
ls -la backups/
```

### Recovery Procedures
```bash
# Database recovery
psql -h localhost -U helpdesk helpdesk < backups/helpdesk_backup_YYYYMMDD_HHMMSS.sql

# File recovery
tar -xzf backups/attachments_backup_YYYYMMDD_HHMMSS.tar.gz
```

## Security Incidents

### Suspected Security Breach
1. **Immediate Actions**:
   - Change all passwords and API keys
   - Review access logs for suspicious activity
   - Check for unauthorized data access
   - Notify security team

2. **Investigation**:
   - Review application logs
   - Check database access logs
   - Review user activity logs
   - Check for privilege escalation

3. **Recovery**:
   - Patch security vulnerabilities
   - Update security configurations
   - Review and update access controls
   - Conduct security audit

### DDoS Attack
1. **Immediate Actions**:
   - Enable rate limiting
   - Block malicious IPs
   - Scale up resources if needed
   - Notify infrastructure team

2. **Mitigation**:
   - Review traffic patterns
   - Implement additional rate limiting
   - Consider CDN for static assets
   - Monitor for continued attacks

## Maintenance Windows

### Weekly Maintenance
- Review logs for errors
- Check disk space and clean up
- Review security logs
- Update dependencies if needed

### Monthly Maintenance
- Review and rotate secrets
- Update SSL certificates
- Review backup procedures
- Conduct disaster recovery drill

### Quarterly Maintenance
- Security audit
- Performance review
- Capacity planning
- Documentation update

## Escalation Procedures

### Level 1 (On-Call Engineer)
- Handle common alerts and issues
- Perform standard maintenance
- Escalate complex issues to Level 2

### Level 2 (Senior Engineer)
- Handle complex technical issues
- Perform major deployments
- Escalate business-critical issues to Level 3

### Level 3 (Engineering Manager)
- Handle business-critical issues
- Make decisions on emergency procedures
- Coordinate with other teams

## Contact Information

- **Slack Channel**: #helpdesk-production
- **PagerDuty**: helpdesk-production
- **Email**: helpdesk-ops@company.com
- **Phone**: +1-555-HELPDESK

## Post-Incident Procedures

1. **Immediate Post-Incident**:
   - Document incident details
   - Identify root cause
   - Implement immediate fixes
   - Communicate status to stakeholders

2. **Follow-up Actions**:
   - Conduct post-incident review
   - Update runbook and procedures
   - Implement preventive measures
   - Schedule follow-up monitoring

3. **Documentation**:
   - Update incident log
   - Document lessons learned
   - Update monitoring and alerting
   - Review and update procedures
