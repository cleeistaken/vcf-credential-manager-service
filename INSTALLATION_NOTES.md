# Installation Notes and Considerations

## Important Notes About This Installation

### Ubuntu 24.04 and PEP 668

Ubuntu 24.04 implements PEP 668, which prevents installing Python packages system-wide using pip to avoid conflicts with system packages. You may see this error:

```
error: externally-managed-environment
× This environment is externally managed
```

**How the script handles this:**

The installation script uses `pip3 install --break-system-packages pipenv` to install pipenv. This is safe because:

1. **Pipenv creates isolated environments**: All application dependencies are installed in a virtual environment (`.venv`)
2. **No system package conflicts**: The application's packages don't interfere with system Python packages
3. **Standard practice**: This is the recommended approach for tools like pipenv that manage virtual environments

**Alternative solutions:**

```bash
# Option 1: Use --break-system-packages (what the script does)
pip3 install --break-system-packages pipenv

# Option 2: Use system package (if available)
apt-get install python3-pipenv

# Option 3: Install in user space
pip3 install --user pipenv
```

The script uses Option 1 as it's the most reliable across different Ubuntu 24.04 configurations.

### Chroot Jail Implementation

The installation script includes code for setting up a chroot jail environment, but this functionality is **commented out by default** for the following reasons:

1. **Complexity**: Chroot jails require careful configuration of:
   - All necessary binaries and their dependencies
   - Python interpreter and all libraries
   - Shared libraries (libc, libssl, etc.)
   - Device nodes (/dev/null, /dev/urandom, etc.)
   - Proper mount points for /proc, /sys, /dev

2. **Pipenv Challenges**: Running pipenv inside a chroot is complex because:
   - Pipenv needs access to the Python environment
   - Virtual environments may have absolute paths
   - Package installation requires full Python toolchain
   - Dependencies may reference paths outside chroot

3. **Maintenance Overhead**: 
   - Updates require syncing files to chroot
   - Debugging is more difficult
   - Library updates need to be replicated

### Current Implementation

The script installs the application in a **standard directory** (`/opt/vcf-credential-manager`) with:

- ✅ Dedicated service user (`vcfcredmgr`)
- ✅ Restricted file permissions
- ✅ Systemd security hardening
- ✅ Proper capability management
- ✅ Protected directories

This provides a good security baseline without the complexity of chroot.

### If You Need Chroot

If you require chroot isolation, you have two options:

#### Option 1: Enable the Built-in Chroot Code

Uncomment these lines in `install-vcf-credential-manager.sh`:

```bash
# In the main() function, uncomment:
setup_chroot_jail
create_chroot_wrapper
```

Then modify the systemd service to use the chroot wrapper:

```bash
ExecStart=/opt/vcf-credential-manager/run_chroot.sh
```

**Note:** This may require additional debugging and adjustments.

#### Option 2: Use Container Technology

For better isolation, consider using:

- **Docker**: Containerize the application
- **Podman**: Rootless container alternative
- **systemd-nspawn**: Lightweight container solution

Example Docker approach:

```dockerfile
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y python3 python3-pip pipenv
COPY . /app
WORKDIR /app
RUN pipenv install --deploy
EXPOSE 443
CMD ["./scripts/run_gunicorn_https_443.sh"]
```

## Port 443 Considerations

### Why Root is Required

The service runs as `root` for the following reason:

- **Port 443 is privileged** (ports < 1024 require root or special capabilities)
- The service uses `CAP_NET_BIND_SERVICE` capability to bind to port 443
- After binding, Gunicorn drops privileges for worker processes

### Alternative Approaches

If you prefer not to run as root:

#### Option 1: Use a Different Port

Change to port 8443 or higher:

```bash
# Edit scripts/run_gunicorn_https_443.sh
--bind 0.0.0.0:8443 \
```

Then run as the `vcfcredmgr` user:

```bash
# In systemd service file
User=vcfcredmgr
Group=vcfcredmgr
```

#### Option 2: Use a Reverse Proxy

Run the app on port 5000 and use nginx as a reverse proxy:

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /opt/vcf-credential-manager/ssl/cert.pem;
    ssl_certificate_key /opt/vcf-credential-manager/ssl/key.pem;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Then run the app on port 5000 as `vcfcredmgr` user.

#### Option 3: Use setcap

Grant the capability to the Python binary:

```bash
sudo setcap 'cap_net_bind_service=+ep' /usr/bin/python3
```

Then run as `vcfcredmgr` user. **Warning:** This affects all Python programs.

## SSL Certificate Considerations

### Self-Signed Certificates

The installation script generates self-signed certificates by default:

**Pros:**
- ✅ Quick setup
- ✅ No cost
- ✅ Works immediately

**Cons:**
- ❌ Browser warnings
- ❌ Not trusted by default
- ❌ Not suitable for production

### Production Certificates

For production, use certificates from a trusted CA:

#### Option 1: Let's Encrypt (Free)

```bash
# Install certbot
sudo apt-get install certbot

# Get certificate
sudo certbot certonly --standalone -d your-domain.com

# Copy to application
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem \
    /opt/vcf-credential-manager/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem \
    /opt/vcf-credential-manager/ssl/key.pem

# Set permissions
sudo chown vcfcredmgr:vcfcredmgr /opt/vcf-credential-manager/ssl/*.pem
sudo chmod 644 /opt/vcf-credential-manager/ssl/cert.pem
sudo chmod 600 /opt/vcf-credential-manager/ssl/key.pem

# Restart service
sudo systemctl restart vcf-credential-manager
```

#### Option 2: Commercial CA

Purchase a certificate from a commercial CA and install it similarly.

#### Option 3: Internal CA

If you have an internal CA, generate and sign a certificate:

```bash
# Generate CSR
openssl req -new -newkey rsa:4096 -nodes \
    -keyout /opt/vcf-credential-manager/ssl/key.pem \
    -out /tmp/vcf-credential-manager.csr \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=vcf-credential-manager"

# Sign with your CA (process varies)
# ...

# Install signed certificate
sudo cp signed-cert.pem /opt/vcf-credential-manager/ssl/cert.pem
```

## Database Considerations

### SQLite (Default)

The application uses SQLite by default:

**Pros:**
- ✅ No additional setup
- ✅ Simple deployment
- ✅ Good for small/medium deployments

**Cons:**
- ❌ Limited concurrency
- ❌ No network access
- ❌ Single file (backup concerns)

### Migrating to PostgreSQL/MySQL

For larger deployments, consider a dedicated database:

1. **Install PostgreSQL:**

```bash
sudo apt-get install postgresql postgresql-contrib
sudo -u postgres createdb vcf_credentials
sudo -u postgres createuser vcfcredmgr
```

2. **Update application configuration:**

Edit `app.py` to use PostgreSQL connection string:

```python
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://vcfcredmgr:password@localhost/vcf_credentials'
```

3. **Update Pipfile:**

```bash
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr pipenv install psycopg2-binary
```

4. **Initialize database:**

```bash
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv run python3 -c \
    'from app import app, db; app.app_context().push(); db.create_all()'
```

## Performance Considerations

### Gunicorn Workers

The default configuration uses:

```python
workers = 4
threads = 2
worker_class = 'gthread'
```

**Adjust based on your system:**

- **Small VM (2 cores, 4GB RAM):** `workers = 2, threads = 2`
- **Medium VM (4 cores, 8GB RAM):** `workers = 4, threads = 2` (default)
- **Large VM (8 cores, 16GB RAM):** `workers = 8, threads = 4`

Formula: `workers = (2 x CPU cores) + 1`

### Monitoring

Consider adding monitoring:

```bash
# Install monitoring tools
sudo apt-get install prometheus-node-exporter

# Monitor with systemd
systemctl status vcf-credential-manager
```

### Log Rotation

The application logs can grow large. Configure log rotation:

```bash
sudo nano /etc/logrotate.d/vcf-credential-manager
```

```
/opt/vcf-credential-manager/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    missingok
    create 0640 vcfcredmgr vcfcredmgr
    sharedscripts
    postrotate
        systemctl reload vcf-credential-manager > /dev/null 2>&1 || true
    endscript
}
```

## Network Considerations

### Firewall

The script configures UFW, but you may need additional rules:

```bash
# Allow from specific network only
sudo ufw delete allow 443/tcp
sudo ufw allow from 192.168.1.0/24 to any port 443

# Allow from multiple networks
sudo ufw allow from 10.0.0.0/8 to any port 443
sudo ufw allow from 172.16.0.0/12 to any port 443
```

### Load Balancing

For high availability, deploy multiple instances:

```
                    ┌─────────────┐
                    │   HAProxy   │
                    │  (Port 443) │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐        ┌────▼────┐       ┌────▼────┐
   │ App #1  │        │ App #2  │       │ App #3  │
   │Port 5001│        │Port 5002│       │Port 5003│
   └─────────┘        └─────────┘       └─────────┘
```

### DNS

For production, configure proper DNS:

```bash
# Add A record
vcf-credentials.example.com  A  192.168.1.100

# Or CNAME
vcf-credentials.example.com  CNAME  server.example.com
```

## Backup Strategy

### What to Backup

1. **Database:** `/opt/vcf-credential-manager/instance/vcf_credentials.db`
2. **SSL Certificates:** `/opt/vcf-credential-manager/ssl/*.pem` (if custom)
3. **Configuration:** `/opt/vcf-credential-manager/gunicorn_config.py`
4. **Logs:** `/opt/vcf-credential-manager/logs/*.log` (optional)

### Backup Script

```bash
#!/bin/bash
BACKUP_DIR="/backup/vcf-credential-manager"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup database
cp /opt/vcf-credential-manager/instance/vcf_credentials.db \
   "$BACKUP_DIR/vcf_credentials_$DATE.db"

# Backup SSL certs
tar -czf "$BACKUP_DIR/ssl_$DATE.tar.gz" \
   /opt/vcf-credential-manager/ssl/

# Keep last 30 days
find "$BACKUP_DIR" -mtime +30 -delete
```

### Automated Backups

Add to crontab:

```bash
# Backup daily at 2 AM
0 2 * * * /usr/local/bin/backup-vcf-credentials.sh
```

## Security Hardening

### Additional Systemd Hardening

Edit `/etc/systemd/system/vcf-credential-manager.service`:

```ini
[Service]
# Additional security options
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM
```

**Note:** Test thoroughly as these may break functionality.

### AppArmor Profile

Create an AppArmor profile for additional isolation:

```bash
sudo nano /etc/apparmor.d/opt.vcf-credential-manager
```

```
#include <tunables/global>

/opt/vcf-credential-manager/scripts/run_gunicorn_https_443.sh {
  #include <abstractions/base>
  #include <abstractions/python>

  /opt/vcf-credential-manager/** r,
  /opt/vcf-credential-manager/logs/** rw,
  /opt/vcf-credential-manager/instance/** rw,
  
  capability net_bind_service,
}
```

## Troubleshooting Tips

### Enable Debug Logging

Edit `app.py`:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Test Without Systemd

```bash
sudo systemctl stop vcf-credential-manager
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv run python3 app.py
```

### Check Dependencies

```bash
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv check
```

### Verify Pipenv Environment

```bash
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv --venv
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv graph
```

## Summary

This installation provides a **production-ready** deployment with:

- ✅ Automated installation
- ✅ Systemd service management
- ✅ HTTPS on port 443
- ✅ Security hardening
- ✅ Proper logging
- ✅ Easy maintenance

The chroot functionality is available but optional. For most use cases, the standard installation provides adequate security.

For questions or issues, refer to:
- **README.md** - Complete documentation
- **TESTING.md** - Testing procedures
- **PROJECT_SUMMARY.md** - Overview

---

**Last Updated:** December 2025

