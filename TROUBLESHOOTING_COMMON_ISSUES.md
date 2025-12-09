# Common Installation Issues - Quick Fix Guide

This document covers the most common installation issues on Ubuntu 24.04 and their solutions.

---

## Issue 1: "externally-managed-environment" Error

### Error Message

```
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
```

### Cause

Ubuntu 24.04 implements PEP 668, which prevents installing Python packages system-wide using pip to protect the system Python environment.

### Solution (Automatic)

✅ **The latest version of the installation script fixes this automatically.**

The script now uses:
```bash
pip3 install --break-system-packages --upgrade pipenv
```

### Why This is Safe

- Pipenv only manages virtual environments
- Application dependencies are isolated in `.venv`
- No system packages are affected
- Standard practice for environment management tools

### Manual Fix

If you need to fix this manually:

```bash
# Install pipenv with the flag
sudo pip3 install --break-system-packages pipenv

# Verify installation
pipenv --version

# Re-run the installation script
sudo ./install-vcf-credential-manager.sh
```

### More Information

See [UBUNTU_24_NOTES.md](UBUNTU_24_NOTES.md) for detailed explanation.

---

## Issue 2: "Python X.X.X was not found" Error

### Error Message

```
Warning: Python 3.13.0 was not found on your system...
Neither 'pyenv' nor 'asdf' could be found to install Python.
You can specify specific versions of Python with:
pipenv --python path/to/python
```

### Cause

The application's `Pipfile` specifies a Python version (e.g., 3.13.0) that isn't available on Ubuntu 24.04. Ubuntu 24.04 ships with Python 3.12 by default.

### Solution (Automatic)

✅ **The latest version of the installation script fixes this automatically.**

The script now:
1. Detects your system Python version
2. Modifies the `Pipfile` to use Python 3.12
3. Uses `PIPENV_PYTHON=3` to use system Python
4. Uses `--skip-lock` to avoid version conflicts

### Manual Fix

If you encounter this error:

```bash
cd /opt/vcf-credential-manager

# Check your Python version
python3 --version
# Output: Python 3.12.x

# Modify Pipfile to use Python 3.12
sudo sed -i 's/python_version = .*/python_version = "3.12"/' Pipfile

# Remove any python_full_version line
sudo sed -i '/python_full_version/d' Pipfile

# Reinstall dependencies
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 PIPENV_PYTHON=3 pipenv install --skip-lock

# Restart the service
sudo systemctl restart vcf-credential-manager
```

### Alternative: Install Python 3.13

If you absolutely need Python 3.13 (usually not necessary):

```bash
# Add deadsnakes PPA
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt-get update

# Install Python 3.13
sudo apt-get install -y python3.13 python3.13-venv python3.13-dev

# Use it with the application
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv install --python 3.13
```

### More Information

See [UBUNTU_24_NOTES.md](UBUNTU_24_NOTES.md) for detailed explanation.

---

## Issue 3: "Failed creating virtual environment" / "destination is not write-able"

### Error Message

```
✘ Failed creating virtual environment
virtualenv: error: argument dest: the destination . is not write-able at /opt/vcf-credential-manager
```

### Cause

The directory ownership wasn't set correctly before pipenv tried to create the virtual environment.

### Solution (Automatic)

✅ **The latest version of the installation script fixes this automatically.**

The script now sets ownership before creating the virtual environment:
```bash
chown -R vcfcredmgr:vcfcredmgr /opt/vcf-credential-manager
```

### Manual Fix

If you encounter this error:

```bash
# Set proper ownership
sudo chown -R vcfcredmgr:vcfcredmgr /opt/vcf-credential-manager

# Navigate to the directory
cd /opt/vcf-credential-manager

# Retry creating the virtual environment
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 PIPENV_PYTHON=3 pipenv install --skip-lock

# Continue with the rest of the installation
sudo systemctl restart vcf-credential-manager
```

### Prevention

The installation script now ensures proper ownership at the right time in the installation sequence.

---

## Issue 4: "logs/gunicorn_error.log isn't writable" / Permission Denied

### Error Message

```
Error: Error: 'logs/gunicorn_error.log' isn't writable [PermissionError(13, 'Permission denied')]
vcf-credential-manager.service: Main process exited, code=exited, status=1/FAILURE
```

### Cause

The systemd service runs as `root` (required to bind to port 443), but the logs and instance directories were owned by the `vcfcredmgr` user, preventing root from writing to them.

### Solution (Automatic)

✅ **The latest version of the installation script fixes this automatically.**

The script now:
1. Creates logs and instance directories with root ownership
2. Sets proper permissions (755) for these directories
3. Ensures the service can write logs and database files

### Manual Fix

If you encounter this error:

```bash
# Fix logs directory permissions
sudo chown -R root:root /opt/vcf-credential-manager/logs
sudo chmod 755 /opt/vcf-credential-manager/logs

# Fix instance directory permissions  
sudo chown -R root:root /opt/vcf-credential-manager/instance
sudo chmod 755 /opt/vcf-credential-manager/instance

# Restart the service
sudo systemctl restart vcf-credential-manager

# Verify it's running
sudo systemctl status vcf-credential-manager
```

### Why Root Ownership?

The service runs as root because:
- Port 443 is a privileged port (< 1024)
- Requires root or `CAP_NET_BIND_SERVICE` capability
- Gunicorn workers inherit the user context

Since the main process runs as root, it needs write access to logs and database directories.

---

## Issue 5: Service Won't Start

### Error Message

```
● vcf-credential-manager.service - VCF Credential Manager Service
     Loaded: loaded
     Active: failed (Result: exit-code)
```

### Diagnosis

Check the logs:

```bash
# Check service status
sudo systemctl status vcf-credential-manager

# View detailed logs
sudo journalctl -u vcf-credential-manager -n 100 --no-pager

# Check application logs
sudo tail -n 50 /opt/vcf-credential-manager/logs/gunicorn_error.log
```

### Common Causes and Solutions

#### Port 443 Already in Use

**Check:**
```bash
sudo netstat -tlnp | grep :443
```

**Solution:**
```bash
# Stop the conflicting service (e.g., nginx, apache)
sudo systemctl stop nginx
sudo systemctl stop apache2

# Or change the port in the startup script
sudo nano /opt/vcf-credential-manager/scripts/run_gunicorn_https_443.sh
# Change --bind 0.0.0.0:443 to --bind 0.0.0.0:8443

# Update firewall
sudo ufw allow 8443/tcp
```

#### Permission Issues

**Check:**
```bash
ls -la /opt/vcf-credential-manager/ssl/
ls -la /opt/vcf-credential-manager/instance/
```

**Solution:**
```bash
# Fix permissions
sudo chown -R vcfcredmgr:vcfcredmgr /opt/vcf-credential-manager
sudo chmod 600 /opt/vcf-credential-manager/ssl/key.pem
sudo chmod 644 /opt/vcf-credential-manager/ssl/cert.pem
```

#### Missing Dependencies

**Solution:**
```bash
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv install --skip-lock
sudo systemctl restart vcf-credential-manager
```

---

## Issue 6: Database Errors

### Error Message

```
sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) database is locked
```

### Solution

```bash
# Stop the service
sudo systemctl stop vcf-credential-manager

# Backup the database
sudo cp /opt/vcf-credential-manager/instance/vcf_credentials.db ~/backup/

# Remove the database (WARNING: This deletes all data!)
sudo rm /opt/vcf-credential-manager/instance/vcf_credentials.db

# Reinitialize the database
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv run python3 -c 'from app import app, db; app.app_context().push(); db.create_all()'

# Restart the service
sudo systemctl start vcf-credential-manager
```

---

## Issue 7: SSL Certificate Errors

### Error Message

```
ssl.SSLError: [SSL: CERTIFICATE_VERIFY_FAILED]
```

### Solution - Regenerate Certificates

```bash
# Stop service
sudo systemctl stop vcf-credential-manager

# Remove old certificates
sudo rm /opt/vcf-credential-manager/ssl/*.pem

# Generate new certificates
cd /opt/vcf-credential-manager
sudo openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout ssl/key.pem -out ssl/cert.pem -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=vcf-credential-manager"

# Set permissions
sudo chown vcfcredmgr:vcfcredmgr ssl/*.pem
sudo chmod 644 ssl/cert.pem
sudo chmod 600 ssl/key.pem

# Restart service
sudo systemctl start vcf-credential-manager
```

---

## Issue 8: Cannot Access from Remote Host

### Symptoms

- Can access from localhost: ✅
- Cannot access from remote host: ❌

### Diagnosis

```bash
# Check if service is listening on all interfaces
sudo netstat -tlnp | grep :443
# Should show: 0.0.0.0:443 (not 127.0.0.1:443)

# Check firewall
sudo ufw status | grep 443
```

### Solution

```bash
# Allow port 443 through firewall
sudo ufw allow 443/tcp

# Verify firewall status
sudo ufw status

# Check if service is binding to all interfaces
grep "bind" /opt/vcf-credential-manager/scripts/run_gunicorn_https_443.sh
# Should show: --bind 0.0.0.0:443
```

---

## Issue 9: Pipenv Installation Fails

### Error Message

```
Command 'pipenv' not found
```

### Solution

```bash
# Check if pipenv is installed
which pipenv

# If not found, install it
sudo pip3 install --break-system-packages pipenv

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
pipenv --version
```

---

## Quick Diagnostic Commands

### Check Everything

```bash
# Service status
sudo systemctl status vcf-credential-manager

# Recent logs
sudo journalctl -u vcf-credential-manager -n 50

# Port status
sudo netstat -tlnp | grep :443

# Firewall status
sudo ufw status

# File permissions
ls -la /opt/vcf-credential-manager/ssl/
ls -la /opt/vcf-credential-manager/instance/

# Python environment
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr pipenv --venv
sudo -u vcfcredmgr pipenv run python --version

# Disk space
df -h /opt/vcf-credential-manager

# Memory usage
free -h
```

### Test the Application

```bash
# Test from localhost
curl -k https://localhost

# Test from remote (replace with your server IP)
curl -k https://192.168.1.100

# Check SSL certificate
openssl s_client -connect localhost:443 -showcerts
```

---

## Getting More Help

### Documentation

1. **[README.md](README.md)** - Complete user guide
2. **[UBUNTU_24_NOTES.md](UBUNTU_24_NOTES.md)** - Ubuntu 24.04 specific issues
3. **[TESTING.md](TESTING.md)** - Comprehensive testing checklist
4. **[INSTALLATION_NOTES.md](INSTALLATION_NOTES.md)** - Advanced configuration

### Logs

```bash
# Systemd logs
sudo journalctl -u vcf-credential-manager -f

# Application logs
sudo tail -f /opt/vcf-credential-manager/logs/vcf_credentials.log
sudo tail -f /opt/vcf-credential-manager/logs/gunicorn_access.log
sudo tail -f /opt/vcf-credential-manager/logs/gunicorn_error.log
```

### Community

- **VCF Credential Manager Issues**: https://github.com/cleeistaken/vcf-credential-manager/issues

---

## Prevention Tips

### Before Installation

- [ ] Ensure Ubuntu 24.04 is fully updated: `sudo apt-get update && sudo apt-get upgrade`
- [ ] Check port 443 is available: `sudo netstat -tlnp | grep :443`
- [ ] Verify sufficient disk space: `df -h`
- [ ] Ensure internet connectivity: `ping -c 3 google.com`

### After Installation

- [ ] Change default admin password immediately
- [ ] Set up regular backups of the database
- [ ] Monitor logs regularly
- [ ] Keep system updated
- [ ] Document any custom configurations

---

**Last Updated:** December 2025  
**Version:** 1.0.1

