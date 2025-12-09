# VCF Credential Manager Service - Project Summary

## Overview

This project provides automated installation scripts to deploy the [VCF Credential Manager](https://github.com/cleeistaken/vcf-credential-manager) application as a production-ready systemd service on Ubuntu 24.04.

## What This Project Provides

### 1. Installation Script (`install-vcf-credential-manager.sh`)

A comprehensive bash script that automates the entire installation process:

**Features:**
- ✅ Checks system requirements (Ubuntu 24.04, root access)
- ✅ Installs all dependencies (Python, pipenv, git, nginx, etc.)
- ✅ Creates dedicated service user (`vcfcredmgr`)
- ✅ Clones the VCF Credential Manager repository
- ✅ Sets up Python virtual environment with pipenv
- ✅ Generates self-signed SSL certificates
- ✅ Configures application to run on port 443 (HTTPS)
- ✅ Creates systemd service with auto-restart
- ✅ Configures firewall rules
- ✅ Sets proper file permissions and security
- ✅ Initializes database
- ✅ Starts the service automatically

**Installation Location:** `/opt/vcf-credential-manager`

### 2. Uninstallation Script (`uninstall-vcf-credential-manager.sh`)

A complete removal script that cleans up everything:

**Features:**
- ✅ Stops and disables the service
- ✅ Removes systemd service file
- ✅ Deletes all application files
- ✅ Removes service user and group
- ✅ Cleans up firewall rules
- ✅ Unmounts chroot filesystems (if used)
- ✅ Confirmation prompt to prevent accidents

### 3. Documentation

Comprehensive documentation for users and administrators:

- **README.md** - Complete guide with installation, configuration, troubleshooting
- **QUICKSTART.md** - Get started in 3 steps
- **TESTING.md** - Comprehensive testing checklist
- **PROJECT_SUMMARY.md** - This file

### 4. Service Configuration

- **vcf-credential-manager.service.template** - Systemd service template

## Key Features

### Security

1. **HTTPS Only** - Self-signed SSL certificates (replaceable with custom certs)
2. **Dedicated User** - Application runs under `vcfcredmgr` user
3. **File Permissions** - Restricted access to sensitive files
4. **Systemd Hardening** - PrivateTmp, ProtectSystem, ProtectHome
5. **Firewall Configuration** - UFW rule for port 443
6. **Capability-based** - Uses `CAP_NET_BIND_SERVICE` for port 443

### Reliability

1. **Auto-restart** - Service restarts automatically on failure
2. **Boot Persistence** - Starts automatically on system boot
3. **Logging** - Comprehensive logging to journald and files
4. **Health Monitoring** - Systemd monitors service health
5. **Graceful Shutdown** - Proper cleanup on stop

### Production Ready

1. **Port 443** - Standard HTTPS port
2. **Gunicorn** - Production WSGI server
3. **Pipenv** - Proper dependency management
4. **Multiple Workers** - Configured for performance
5. **Log Rotation** - Automatic log management

## Installation Requirements

### System Requirements

- **OS:** Ubuntu 24.04 LTS (or compatible)
- **Access:** Root or sudo privileges
- **Network:** Internet connection for package downloads
- **Memory:** Minimum 2GB RAM
- **Disk:** 5GB free space

### Software Dependencies (Auto-installed)

- Python 3.12+
- pip and pipenv
- Git
- OpenSSL
- Nginx
- Build tools (gcc, make, etc.)

## Directory Structure

```
/opt/vcf-credential-manager/          # Main application
├── app.py                            # Flask application
├── gunicorn_config.py                # Gunicorn configuration
├── scripts/
│   ├── run_gunicorn_https.sh        # Original startup script
│   └── run_gunicorn_https_443.sh    # Custom script for port 443
├── ssl/
│   ├── cert.pem                      # SSL certificate
│   └── key.pem                       # SSL private key
├── logs/
│   ├── vcf_credentials.log          # Application logs
│   ├── gunicorn_access.log          # HTTP access logs
│   └── gunicorn_error.log           # Error logs
├── instance/
│   └── vcf_credentials.db            # SQLite database
├── templates/                        # HTML templates
├── static/                           # CSS, JS, images
├── web/                              # Web modules
└── .venv/                            # Pipenv virtual environment

/etc/systemd/system/
└── vcf-credential-manager.service    # Systemd service file
```

## Service Management

### Systemd Commands

```bash
# Status
sudo systemctl status vcf-credential-manager

# Start
sudo systemctl start vcf-credential-manager

# Stop
sudo systemctl stop vcf-credential-manager

# Restart
sudo systemctl restart vcf-credential-manager

# Enable (auto-start on boot)
sudo systemctl enable vcf-credential-manager

# Disable
sudo systemctl disable vcf-credential-manager

# View logs
sudo journalctl -u vcf-credential-manager -f
```

### Application Logs

```bash
# All logs
tail -f /opt/vcf-credential-manager/logs/*.log

# Application log
tail -f /opt/vcf-credential-manager/logs/vcf_credentials.log

# Access log
tail -f /opt/vcf-credential-manager/logs/gunicorn_access.log

# Error log
tail -f /opt/vcf-credential-manager/logs/gunicorn_error.log
```

## Network Configuration

- **Port:** 443 (HTTPS)
- **Binding:** 0.0.0.0 (all interfaces)
- **Protocol:** HTTPS only
- **Firewall:** UFW rule configured

## Application Access

- **URL:** `https://localhost` or `https://<server-ip>`
- **Default Username:** `admin`
- **Default Password:** `admin`

⚠️ **Change the default password immediately after first login!**

## Customization Options

### Custom SSL Certificates

Replace the self-signed certificates:

```bash
sudo cp your-cert.pem /opt/vcf-credential-manager/ssl/cert.pem
sudo cp your-key.pem /opt/vcf-credential-manager/ssl/key.pem
sudo chown vcfcredmgr:vcfcredmgr /opt/vcf-credential-manager/ssl/*.pem
sudo chmod 644 /opt/vcf-credential-manager/ssl/cert.pem
sudo chmod 600 /opt/vcf-credential-manager/ssl/key.pem
sudo systemctl restart vcf-credential-manager
```

### Change Port

Edit `/opt/vcf-credential-manager/scripts/run_gunicorn_https_443.sh`:

```bash
--bind 0.0.0.0:8443 \
```

Update firewall and restart service.

### Adjust Workers

Edit `/opt/vcf-credential-manager/gunicorn_config.py`:

```python
workers = 4  # Number of worker processes
threads = 2  # Threads per worker
```

Restart service to apply changes.

## Chroot Jail (Optional)

The installation script includes code for chroot jail setup, but it's commented out by default due to complexity. The chroot functionality:

- Creates isolated filesystem at `/opt/vcf-credential-manager-chroot`
- Copies necessary binaries and libraries
- Mounts /proc, /sys, /dev
- Runs application in isolated environment

To enable, uncomment the chroot-related lines in the installation script.

## Troubleshooting

### Common Issues

1. **Port 443 already in use** - Check with `netstat -tlnp | grep :443`
2. **Service won't start** - Check logs with `journalctl -u vcf-credential-manager -n 50`
3. **Permission denied** - Verify service runs as root for port 443
4. **Database errors** - Reset database (see TESTING.md)
5. **SSL errors** - Regenerate certificates (see README.md)

### Debug Mode

To run in debug mode:

```bash
sudo systemctl stop vcf-credential-manager
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv run python3 app.py
```

## Maintenance

### Backup

Backup important files:

```bash
# Database
sudo cp /opt/vcf-credential-manager/instance/vcf_credentials.db ~/backup/

# SSL certificates (if custom)
sudo cp /opt/vcf-credential-manager/ssl/*.pem ~/backup/

# Configuration
sudo cp /opt/vcf-credential-manager/gunicorn_config.py ~/backup/
```

### Updates

Update the application:

```bash
sudo systemctl stop vcf-credential-manager
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr git pull
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy
sudo systemctl start vcf-credential-manager
```

### Monitoring

Monitor service health:

```bash
# Service status
watch -n 5 'systemctl status vcf-credential-manager'

# Resource usage
top -p $(pgrep -f gunicorn | head -1)

# Disk usage
du -sh /opt/vcf-credential-manager/*

# Log size
du -sh /opt/vcf-credential-manager/logs/*
```

## Performance Tuning

### Gunicorn Workers

Formula: `(2 x CPU cores) + 1`

For 4 cores: `workers = 9`

### Database Optimization

For production use, consider migrating from SQLite to PostgreSQL or MySQL.

### Caching

Consider adding Redis for session caching and credential caching.

### Load Balancing

For high availability, deploy multiple instances behind a load balancer.

## Security Hardening

### Additional Recommendations

1. **Use custom SSL certificates** from a trusted CA
2. **Enable SSL verification** for VCF connections
3. **Change default admin password** immediately
4. **Restrict network access** with firewall rules
5. **Enable audit logging** for compliance
6. **Regular backups** of database
7. **Keep system updated** with security patches
8. **Monitor logs** for suspicious activity

### Firewall Configuration

```bash
# Allow only from specific IP
sudo ufw allow from 192.168.1.0/24 to any port 443

# Deny all other access
sudo ufw default deny incoming
```

## Support and Resources

### Documentation

- **README.md** - Comprehensive guide
- **QUICKSTART.md** - Quick start guide
- **TESTING.md** - Testing checklist
- **Original App Docs** - https://github.com/cleeistaken/vcf-credential-manager

### Logs

- **Systemd Journal:** `journalctl -u vcf-credential-manager`
- **Application Logs:** `/opt/vcf-credential-manager/logs/`

### Community

- **VCF Credential Manager Issues:** https://github.com/cleeistaken/vcf-credential-manager/issues

## Version History

### v1.0.0 (Initial Release)

- Automated installation script
- Systemd service configuration
- HTTPS on port 443
- Pipenv environment management
- SSL certificate generation
- Comprehensive documentation
- Uninstallation script
- Testing checklist

## License

This installation script is provided as-is. The VCF Credential Manager application has its own license.

## Credits

- **VCF Credential Manager:** [cleeistaken](https://github.com/cleeistaken/vcf-credential-manager)
- **Installation Scripts:** Created for automated Ubuntu deployment

---

**For VMware Cloud Foundation administrators** 🚀

**Installation Time:** ~5-10 minutes  
**Difficulty:** Easy (automated)  
**Maintenance:** Low

