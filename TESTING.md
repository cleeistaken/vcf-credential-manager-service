# Testing Checklist

Use this checklist to verify the installation was successful.

## Pre-Installation Tests

- [ ] Ubuntu 24.04 LTS is installed
- [ ] You have root/sudo access
- [ ] Internet connection is available
- [ ] At least 5GB free disk space
- [ ] Port 443 is not already in use

Check port 443:
```bash
sudo netstat -tlnp | grep :443
```

## Installation Tests

- [ ] Installation script runs without errors
- [ ] All dependencies are installed
- [ ] User `vcfcredmgr` is created
- [ ] Directory `/opt/vcf-credential-manager` exists
- [ ] Python virtual environment is created
- [ ] SSL certificates are generated
- [ ] Systemd service is created and enabled

Verify user:
```bash
id vcfcredmgr
```

Verify directory:
```bash
ls -la /opt/vcf-credential-manager
```

Verify SSL certificates:
```bash
ls -la /opt/vcf-credential-manager/ssl/
```

Verify service:
```bash
sudo systemctl status vcf-credential-manager
```

## Service Tests

- [ ] Service is running
- [ ] Service is enabled (auto-start on boot)
- [ ] Service restarts automatically after crash
- [ ] Logs are being written

Check service status:
```bash
sudo systemctl is-active vcf-credential-manager
sudo systemctl is-enabled vcf-credential-manager
```

Check logs:
```bash
sudo journalctl -u vcf-credential-manager -n 20
ls -la /opt/vcf-credential-manager/logs/
```

## Network Tests

- [ ] Application is listening on port 443
- [ ] Firewall rule is configured
- [ ] Can access from localhost
- [ ] Can access from remote host (if applicable)

Check listening port:
```bash
sudo netstat -tlnp | grep :443
```

Check firewall:
```bash
sudo ufw status | grep 443
```

Test localhost access:
```bash
curl -k https://localhost
```

## Application Tests

- [ ] Web interface loads
- [ ] Can login with default credentials (admin/admin)
- [ ] Can change password
- [ ] Can add a test environment
- [ ] Can test connection to VCF
- [ ] Can sync credentials
- [ ] Can view credentials
- [ ] Can export credentials
- [ ] Can delete environment

Access the web interface:
```
https://localhost
```

## Security Tests

- [ ] SSL/TLS is working (HTTPS only)
- [ ] Application files have correct ownership
- [ ] SSL private key has restricted permissions (600)
- [ ] Database file has restricted permissions (600)
- [ ] Service runs with appropriate privileges

Check file permissions:
```bash
ls -la /opt/vcf-credential-manager/ssl/key.pem
ls -la /opt/vcf-credential-manager/instance/vcf_credentials.db
```

Check SSL:
```bash
openssl s_client -connect localhost:443 -showcerts
```

## Performance Tests

- [ ] Application responds quickly
- [ ] No memory leaks over time
- [ ] CPU usage is reasonable
- [ ] Disk usage is reasonable

Monitor resources:
```bash
# Check memory usage
ps aux | grep gunicorn

# Monitor in real-time
top -p $(pgrep -f gunicorn | head -1)
```

## Restart Tests

- [ ] Service restarts cleanly
- [ ] Application works after restart
- [ ] Database persists after restart
- [ ] Logs continue after restart

Test restart:
```bash
sudo systemctl restart vcf-credential-manager
sleep 5
sudo systemctl status vcf-credential-manager
curl -k https://localhost
```

## Reboot Tests

- [ ] Service starts automatically after reboot
- [ ] Application is accessible after reboot
- [ ] All data persists after reboot

Test reboot:
```bash
sudo reboot
# After reboot:
sudo systemctl status vcf-credential-manager
curl -k https://localhost
```

## Update Tests

- [ ] Can pull latest code from git
- [ ] Can update dependencies
- [ ] Application works after update

Test update:
```bash
sudo systemctl stop vcf-credential-manager
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr git pull
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy
sudo systemctl start vcf-credential-manager
```

## Uninstallation Tests

- [ ] Uninstall script runs without errors
- [ ] Service is stopped and removed
- [ ] All files are removed
- [ ] User and group are removed
- [ ] Firewall rules are removed

Test uninstall:
```bash
sudo ./uninstall-vcf-credential-manager.sh
```

Verify cleanup:
```bash
# Should not exist
systemctl status vcf-credential-manager
ls /opt/vcf-credential-manager
id vcfcredmgr
```

## Common Issues and Solutions

### Issue: Service fails to start

**Check:**
```bash
sudo journalctl -u vcf-credential-manager -n 50
```

**Common causes:**
- Port 443 already in use
- Missing dependencies
- Database corruption
- Permission issues

### Issue: Cannot access from remote host

**Check:**
```bash
sudo ufw status
sudo netstat -tlnp | grep :443
```

**Solution:**
```bash
sudo ufw allow 443/tcp
```

### Issue: SSL certificate errors

**Regenerate certificates:**
```bash
cd /opt/vcf-credential-manager
sudo rm ssl/*.pem
sudo openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout ssl/key.pem -out ssl/cert.pem -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=vcf-credential-manager"
sudo chown vcfcredmgr:vcfcredmgr ssl/*.pem
sudo chmod 644 ssl/cert.pem
sudo chmod 600 ssl/key.pem
sudo systemctl restart vcf-credential-manager
```

### Issue: Database errors

**Reset database:**
```bash
sudo systemctl stop vcf-credential-manager
sudo rm /opt/vcf-credential-manager/instance/vcf_credentials.db
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv run python3 -c 'from app import app, db; app.app_context().push(); db.create_all()'
sudo systemctl start vcf-credential-manager
```

## Test Results

Record your test results:

| Test Category | Status | Notes |
|---------------|--------|-------|
| Pre-Installation | ⬜ Pass / ⬜ Fail | |
| Installation | ⬜ Pass / ⬜ Fail | |
| Service | ⬜ Pass / ⬜ Fail | |
| Network | ⬜ Pass / ⬜ Fail | |
| Application | ⬜ Pass / ⬜ Fail | |
| Security | ⬜ Pass / ⬜ Fail | |
| Performance | ⬜ Pass / ⬜ Fail | |
| Restart | ⬜ Pass / ⬜ Fail | |
| Reboot | ⬜ Pass / ⬜ Fail | |
| Update | ⬜ Pass / ⬜ Fail | |
| Uninstallation | ⬜ Pass / ⬜ Fail | |

---

**Testing Date:** _________________

**Tester:** _________________

**Ubuntu Version:** _________________

**Notes:** _________________

