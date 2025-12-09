# VCF Credential Manager - Deployment Checklist

Use this checklist to ensure a successful production deployment.

## Pre-Deployment

### System Requirements
- [ ] Ubuntu 24.04 LTS installed and updated
- [ ] Root/sudo access available
- [ ] Internet connection available
- [ ] Minimum 2GB RAM
- [ ] 5GB free disk space
- [ ] Port 443 not in use

### Network Planning
- [ ] Server IP address assigned
- [ ] DNS record created (if applicable)
- [ ] Firewall rules planned
- [ ] VCF systems accessible from server
- [ ] Network security approved

### SSL Certificates
- [ ] Decide: Self-signed or custom certificates
- [ ] If custom: Obtain certificate and private key
- [ ] Certificate files ready for installation
- [ ] Certificate expiration date noted

### Documentation Review
- [ ] Read QUICKSTART.md
- [ ] Review README.md
- [ ] Check INSTALLATION_NOTES.md
- [ ] Review ARCHITECTURE.md (optional)

## Installation Phase

### Download and Prepare
- [ ] Clone this repository
- [ ] Verify script permissions (`ls -l *.sh`)
- [ ] Review installation script (optional)
- [ ] Backup existing data (if reinstalling)

### Run Installation
- [ ] Execute: `sudo ./install-vcf-credential-manager.sh`
- [ ] Monitor installation output
- [ ] Note any warnings or errors
- [ ] Verify completion message

### Verify Installation
- [ ] Check service status: `sudo systemctl status vcf-credential-manager`
- [ ] Verify listening on port 443: `sudo netstat -tlnp | grep :443`
- [ ] Check firewall: `sudo ufw status | grep 443`
- [ ] Verify files exist: `ls -la /opt/vcf-credential-manager/`
- [ ] Check logs: `sudo journalctl -u vcf-credential-manager -n 20`

## Post-Installation Configuration

### SSL Certificates (if using custom)
- [ ] Stop service: `sudo systemctl stop vcf-credential-manager`
- [ ] Copy certificate: `sudo cp cert.pem /opt/vcf-credential-manager/ssl/`
- [ ] Copy private key: `sudo cp key.pem /opt/vcf-credential-manager/ssl/`
- [ ] Set permissions: `sudo chmod 644 cert.pem && sudo chmod 600 key.pem`
- [ ] Set ownership: `sudo chown vcfcredmgr:vcfcredmgr /opt/vcf-credential-manager/ssl/*.pem`
- [ ] Start service: `sudo systemctl start vcf-credential-manager`

### Initial Access
- [ ] Open browser to `https://server-ip`
- [ ] Accept SSL warning (if self-signed)
- [ ] Login with admin/admin
- [ ] Change admin password immediately
- [ ] Verify dashboard loads

### Application Configuration
- [ ] Add first VCF environment
- [ ] Test connection to VCF Installer
- [ ] Test connection to SDDC Manager
- [ ] Perform manual sync
- [ ] Verify credentials retrieved
- [ ] Test export functionality (CSV/Excel)
- [ ] Configure automatic sync schedule

## Security Hardening

### Password Security
- [ ] Admin password changed
- [ ] Strong password policy enforced
- [ ] Password documented securely

### Network Security
- [ ] Firewall rules configured
- [ ] Only necessary ports open
- [ ] IP whitelist configured (if needed)
- [ ] Network segmentation verified

### File Permissions
- [ ] Verify database permissions: `ls -l /opt/vcf-credential-manager/instance/vcf_credentials.db`
- [ ] Verify SSL key permissions: `ls -l /opt/vcf-credential-manager/ssl/key.pem`
- [ ] Verify log permissions: `ls -l /opt/vcf-credential-manager/logs/`

### SSL/TLS
- [ ] SSL certificate valid
- [ ] Strong cipher suites enabled
- [ ] TLS 1.2+ only
- [ ] Certificate expiration monitored

## Testing

### Functional Testing
- [ ] User login works
- [ ] Password change works
- [ ] Add environment works
- [ ] Edit environment works
- [ ] Delete environment works
- [ ] View credentials works
- [ ] Export to CSV works
- [ ] Export to Excel works
- [ ] Manual sync works
- [ ] Automatic sync works

### Service Testing
- [ ] Service starts: `sudo systemctl start vcf-credential-manager`
- [ ] Service stops: `sudo systemctl stop vcf-credential-manager`
- [ ] Service restarts: `sudo systemctl restart vcf-credential-manager`
- [ ] Auto-start on boot: `sudo systemctl is-enabled vcf-credential-manager`
- [ ] Auto-restart on crash (test by killing process)

### Network Testing
- [ ] Access from localhost works
- [ ] Access from remote host works
- [ ] HTTPS enforced (no HTTP access)
- [ ] Firewall blocks unauthorized access

### Performance Testing
- [ ] Response time acceptable
- [ ] Memory usage reasonable: `ps aux | grep gunicorn`
- [ ] CPU usage reasonable: `top -p $(pgrep -f gunicorn | head -1)`
- [ ] Disk usage acceptable: `df -h /opt/vcf-credential-manager`

### Stress Testing (optional)
- [ ] Multiple concurrent users
- [ ] Large number of credentials
- [ ] Multiple environments
- [ ] Frequent sync operations

## Monitoring Setup

### Log Monitoring
- [ ] Know log locations:
  - [ ] `/opt/vcf-credential-manager/logs/vcf_credentials.log`
  - [ ] `/opt/vcf-credential-manager/logs/gunicorn_access.log`
  - [ ] `/opt/vcf-credential-manager/logs/gunicorn_error.log`
  - [ ] `journalctl -u vcf-credential-manager`
- [ ] Log rotation configured
- [ ] Log retention policy set

### Health Monitoring
- [ ] Service status check scheduled
- [ ] Resource usage monitoring enabled
- [ ] Disk space monitoring enabled
- [ ] Alert thresholds configured

### Application Monitoring
- [ ] Sync success/failure tracking
- [ ] User activity logging
- [ ] Error rate monitoring
- [ ] Performance metrics collected

## Backup Configuration

### Backup Plan
- [ ] Backup schedule defined
- [ ] Backup location configured
- [ ] Backup retention policy set
- [ ] Backup verification process defined

### What to Backup
- [ ] Database: `/opt/vcf-credential-manager/instance/vcf_credentials.db`
- [ ] SSL certs: `/opt/vcf-credential-manager/ssl/*.pem` (if custom)
- [ ] Configuration: `/opt/vcf-credential-manager/gunicorn_config.py`

### Backup Testing
- [ ] Perform initial backup
- [ ] Test restore procedure
- [ ] Document restore process
- [ ] Schedule regular backup tests

## Documentation

### Internal Documentation
- [ ] Server details documented
- [ ] Admin credentials stored securely
- [ ] Network configuration documented
- [ ] SSL certificate details recorded
- [ ] Backup procedures documented
- [ ] Troubleshooting notes created

### User Documentation
- [ ] Access URL shared with users
- [ ] User guide provided
- [ ] Support contact information shared
- [ ] Known issues documented

## Maintenance Planning

### Regular Maintenance
- [ ] Update schedule defined
- [ ] Maintenance window scheduled
- [ ] Backup before updates
- [ ] Update procedure documented

### Monitoring Schedule
- [ ] Daily: Service status check
- [ ] Weekly: Log review
- [ ] Monthly: Performance review
- [ ] Quarterly: Security audit

### Update Procedures
- [ ] Application update process defined
- [ ] System update process defined
- [ ] Rollback procedure documented
- [ ] Testing after updates planned

## Disaster Recovery

### Recovery Plan
- [ ] RTO (Recovery Time Objective) defined
- [ ] RPO (Recovery Point Objective) defined
- [ ] Recovery procedures documented
- [ ] Recovery testing scheduled

### Failure Scenarios
- [ ] Service failure recovery documented
- [ ] Database corruption recovery documented
- [ ] Server failure recovery documented
- [ ] Network failure recovery documented

## Sign-Off

### Technical Review
- [ ] Installation verified by: _________________ Date: _______
- [ ] Security review by: _________________ Date: _______
- [ ] Testing completed by: _________________ Date: _______

### Approval
- [ ] Deployment approved by: _________________ Date: _______
- [ ] Production ready: ☐ Yes ☐ No

### Handover
- [ ] Operations team trained
- [ ] Documentation provided
- [ ] Support procedures established
- [ ] Monitoring configured

## Post-Deployment

### Day 1
- [ ] Monitor service closely
- [ ] Review logs for errors
- [ ] Verify all functionality
- [ ] Address any issues immediately

### Week 1
- [ ] Daily log review
- [ ] User feedback collection
- [ ] Performance monitoring
- [ ] Issue tracking

### Month 1
- [ ] Weekly status review
- [ ] Performance optimization
- [ ] User training (if needed)
- [ ] Documentation updates

## Troubleshooting Quick Reference

### Service Won't Start
```bash
# Check status
sudo systemctl status vcf-credential-manager

# Check logs
sudo journalctl -u vcf-credential-manager -n 50

# Check port
sudo netstat -tlnp | grep :443
```

### Cannot Access Web Interface
```bash
# Check service
sudo systemctl status vcf-credential-manager

# Check firewall
sudo ufw status

# Check listening
sudo netstat -tlnp | grep :443
```

### Database Errors
```bash
# Stop service
sudo systemctl stop vcf-credential-manager

# Backup database
sudo cp /opt/vcf-credential-manager/instance/vcf_credentials.db ~/backup/

# Reset database
sudo rm /opt/vcf-credential-manager/instance/vcf_credentials.db

# Reinitialize
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv run python3 -c 'from app import app, db; app.app_context().push(); db.create_all()'

# Start service
sudo systemctl start vcf-credential-manager
```

## Contact Information

### Support Contacts
- **System Administrator:** _________________
- **Network Administrator:** _________________
- **Security Team:** _________________
- **Application Owner:** _________________

### Escalation Path
1. Level 1: _________________
2. Level 2: _________________
3. Level 3: _________________

---

## Deployment Summary

**Server:** _________________  
**IP Address:** _________________  
**URL:** https://_________________  
**Installation Date:** _________________  
**Installed By:** _________________  
**Version:** 1.0.0

**SSL Certificate:**
- Type: ☐ Self-signed ☐ Custom
- Expiration: _________________

**Backup:**
- Location: _________________
- Schedule: _________________
- Retention: _________________

**Monitoring:**
- Tool: _________________
- Alert Email: _________________

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

**Deployment Status:** ☐ In Progress ☐ Complete ☐ Failed

**Deployment Completed:** _______ / _______ / _______

**Signed:** _________________

