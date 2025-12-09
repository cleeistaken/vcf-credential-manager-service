# VCF Credential Manager - Ubuntu Service Installation

This repository contains installation scripts to deploy the [VCF Credential Manager](https://github.com/cleeistaken/vcf-credential-manager) application as a systemd service on Ubuntu 24.04.

## Features

- ✅ **Automated Installation**: One-command setup of the entire application
- ✅ **Systemd Service**: Runs as a managed service with automatic restart
- ✅ **HTTPS on Port 443**: Production-ready HTTPS configuration
- ✅ **Pipenv Environment**: Proper Python virtual environment management
- ✅ **SSL Certificates**: Auto-generated self-signed certificates
- ✅ **Security Hardened**: Dedicated user, proper permissions, and security settings
- ✅ **Chroot Jail Ready**: Optional chroot isolation (commented out by default)
- ✅ **Easy Uninstall**: Complete removal script included

## Prerequisites

- Ubuntu 24.04 LTS (or compatible)
- Root or sudo access
- Internet connection for package downloads
- Minimum 2GB RAM
- 5GB free disk space

## Quick Start

### Installation

1. **Download the installation script:**

```bash
git clone <this-repository-url>
cd vcf-credential-manager-service
```

2. **Make the script executable:**

```bash
chmod +x install-vcf-credential-manager.sh
```

3. **Run the installation script:**

```bash
sudo ./install-vcf-credential-manager.sh
```

The script will:
- Install all required system dependencies
- Create a dedicated service user (`vcfcredmgr`)
- Clone the VCF Credential Manager repository to `/opt/vcf-credential-manager`
- Set up Python environment with pipenv
- Generate self-signed SSL certificates
- Configure the application to run on port 443
- Create and enable a systemd service
- Configure firewall rules
- Start the service automatically

4. **Access the application:**

Open your browser and navigate to:
```
https://localhost
```

**Default credentials:**
- Username: `admin`
- Password: `admin`

⚠️ **IMPORTANT:** Change the default password immediately after first login!

## Installation Details

### Directory Structure

```
/opt/vcf-credential-manager/          # Main application directory
├── app.py                            # Flask application
├── scripts/
│   ├── run_gunicorn_https_443.sh    # Custom startup script (port 443)
│   └── run_gunicorn_https.sh        # Original startup script
├── ssl/
│   ├── cert.pem                      # SSL certificate
│   └── key.pem                       # SSL private key
├── logs/                             # Application logs
│   ├── vcf_credentials.log
│   ├── gunicorn_access.log
│   └── gunicorn_error.log
├── instance/
│   └── vcf_credentials.db            # SQLite database
└── .venv/                            # Pipenv virtual environment

/opt/vcf-credential-manager-chroot/   # Chroot jail (optional, not used by default)
```

### Service Configuration

The application runs as a systemd service with the following characteristics:

- **Service Name:** `vcf-credential-manager.service`
- **User:** `root` (required for binding to port 443)
- **Working Directory:** `/opt/vcf-credential-manager`
- **Port:** 443 (HTTPS)
- **Auto-restart:** Enabled with 10-second delay
- **Logging:** Journald + file-based logs

### Security Features

1. **Dedicated User:** Application files owned by `vcfcredmgr` user
2. **SSL/TLS:** HTTPS only with self-signed certificates
3. **Firewall:** UFW rule for port 443
4. **Systemd Hardening:**
   - `PrivateTmp=true`
   - `ProtectSystem=strict`
   - `ProtectHome=true`
   - `NoNewPrivileges=false` (required for port 443)
5. **File Permissions:** Restricted access to sensitive files

## Managing the Service

### Check Service Status

```bash
sudo systemctl status vcf-credential-manager
```

### View Logs

**Systemd journal (real-time):**
```bash
sudo journalctl -u vcf-credential-manager -f
```

**Application logs:**
```bash
sudo tail -f /opt/vcf-credential-manager/logs/vcf_credentials.log
sudo tail -f /opt/vcf-credential-manager/logs/gunicorn_access.log
sudo tail -f /opt/vcf-credential-manager/logs/gunicorn_error.log
```

### Restart Service

```bash
sudo systemctl restart vcf-credential-manager
```

### Stop Service

```bash
sudo systemctl stop vcf-credential-manager
```

### Start Service

```bash
sudo systemctl start vcf-credential-manager
```

### Disable Service (prevent auto-start on boot)

```bash
sudo systemctl disable vcf-credential-manager
```

### Enable Service (auto-start on boot)

```bash
sudo systemctl enable vcf-credential-manager
```

## Updating the Application

To update the application to the latest version:

```bash
# Stop the service
sudo systemctl stop vcf-credential-manager

# Navigate to installation directory
cd /opt/vcf-credential-manager

# Pull latest changes
sudo -u vcfcredmgr git pull

# Update dependencies
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy

# Restart the service
sudo systemctl start vcf-credential-manager
```

## Using Custom SSL Certificates

To replace the self-signed certificates with your own:

1. **Copy your certificates:**

```bash
sudo cp your-certificate.pem /opt/vcf-credential-manager/ssl/cert.pem
sudo cp your-private-key.pem /opt/vcf-credential-manager/ssl/key.pem
```

2. **Set proper permissions:**

```bash
sudo chown vcfcredmgr:vcfcredmgr /opt/vcf-credential-manager/ssl/*.pem
sudo chmod 644 /opt/vcf-credential-manager/ssl/cert.pem
sudo chmod 600 /opt/vcf-credential-manager/ssl/key.pem
```

3. **Restart the service:**

```bash
sudo systemctl restart vcf-credential-manager
```

## Troubleshooting

### Service Won't Start

1. **Check the service status:**
```bash
sudo systemctl status vcf-credential-manager
```

2. **View detailed logs:**
```bash
sudo journalctl -u vcf-credential-manager -n 100 --no-pager
```

3. **Check if port 443 is already in use:**
```bash
sudo netstat -tlnp | grep :443
```

### Port 443 Permission Denied

The service needs to run as root or with `CAP_NET_BIND_SERVICE` capability to bind to port 443. The installation script configures this automatically.

### Database Errors

If you encounter database errors:

```bash
# Stop the service
sudo systemctl stop vcf-credential-manager

# Remove the database (WARNING: This deletes all data!)
sudo rm /opt/vcf-credential-manager/instance/vcf_credentials.db

# Reinitialize the database
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv run python3 -c 'from app import app, db; app.app_context().push(); db.create_all()'

# Restart the service
sudo systemctl start vcf-credential-manager
```

### SSL Certificate Errors

If you encounter SSL certificate errors:

```bash
# Regenerate certificates
sudo rm /opt/vcf-credential-manager/ssl/*.pem
cd /opt/vcf-credential-manager
sudo openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout ssl/key.pem -out ssl/cert.pem -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=vcf-credential-manager"

# Set permissions
sudo chown vcfcredmgr:vcfcredmgr ssl/*.pem
sudo chmod 644 ssl/cert.pem
sudo chmod 600 ssl/key.pem

# Restart service
sudo systemctl restart vcf-credential-manager
```

### Cannot Access from Remote Host

1. **Check firewall:**
```bash
sudo ufw status
sudo ufw allow 443/tcp
```

2. **Verify the service is listening on all interfaces:**
```bash
sudo netstat -tlnp | grep :443
```

The output should show `0.0.0.0:443` not `127.0.0.1:443`.

### Installation Error: "externally-managed-environment"

If you see this error during installation:

```
error: externally-managed-environment
× This environment is externally managed
```

**Solution:** The installation script has been updated to handle Ubuntu 24.04's PEP 668 restriction. Make sure you're using the latest version of the script.

The script now uses `pip3 install --break-system-packages pipenv` which is safe because:
- Pipenv creates isolated virtual environments
- It doesn't interfere with system packages
- The application runs in its own `.venv` directory

If you still encounter issues, you can manually install pipenv:

```bash
# Option 1: Use --break-system-packages (recommended)
sudo pip3 install --break-system-packages pipenv

# Option 2: Use system package (if available)
sudo apt-get install python3-pipenv

# Option 3: Install in user space
pip3 install --user pipenv
export PATH="$HOME/.local/bin:$PATH"
```

Then re-run the installation script.

## Uninstallation

To completely remove the VCF Credential Manager:

1. **Make the uninstall script executable:**

```bash
chmod +x uninstall-vcf-credential-manager.sh
```

2. **Run the uninstall script:**

```bash
sudo ./uninstall-vcf-credential-manager.sh
```

This will:
- Stop and disable the service
- Remove the systemd service file
- Delete all application files and directories
- Remove the application user and group
- Remove firewall rules
- Clean up chroot environment (if used)

⚠️ **WARNING:** This will delete all data including the database!

## Advanced Configuration

### Chroot Jail

The installation script includes code for setting up a chroot jail, but it's commented out by default due to complexity. To enable it:

1. Edit `install-vcf-credential-manager.sh`
2. Uncomment the chroot-related lines in the `main()` function:
   ```bash
   setup_chroot_jail
   create_chroot_wrapper
   ```
3. Modify the systemd service to use the chroot wrapper

**Note:** Chroot configuration requires additional testing and may need adjustments based on your specific environment.

### Changing the Port

To change from port 443 to another port:

1. **Edit the custom startup script:**
```bash
sudo nano /opt/vcf-credential-manager/scripts/run_gunicorn_https_443.sh
```

2. **Change the `--bind` parameter:**
```bash
--bind 0.0.0.0:8443 \
```

3. **Update firewall:**
```bash
sudo ufw allow 8443/tcp
sudo ufw delete allow 443/tcp
```

4. **Restart the service:**
```bash
sudo systemctl restart vcf-credential-manager
```

### Adjusting Worker Processes

To modify Gunicorn worker settings:

1. **Edit the Gunicorn config:**
```bash
sudo nano /opt/vcf-credential-manager/gunicorn_config.py
```

2. **Adjust workers and threads:**
```python
workers = 4  # Number of worker processes
threads = 2  # Threads per worker
```

3. **Restart the service:**
```bash
sudo systemctl restart vcf-credential-manager
```

## Application Usage

For detailed information on using the VCF Credential Manager application, refer to the [official documentation](https://github.com/cleeistaken/vcf-credential-manager).

### Quick Overview

1. **Login** with default credentials (admin/admin)
2. **Change password** immediately
3. **Add VCF environments** with connection details
4. **View credentials** for each environment
5. **Export credentials** to CSV or Excel
6. **Configure automatic syncing** for each environment

## Support

### Getting Help

- **Application Issues:** [VCF Credential Manager GitHub](https://github.com/cleeistaken/vcf-credential-manager)
- **Installation Issues:** Check the troubleshooting section above
- **Service Issues:** Review systemd logs with `journalctl`

### Reporting Issues

When reporting issues, include:

- Ubuntu version (`lsb_release -a`)
- Service status (`systemctl status vcf-credential-manager`)
- Recent logs (`journalctl -u vcf-credential-manager -n 50`)
- Error messages
- Steps to reproduce

## License

This installation script is provided as-is. The VCF Credential Manager application has its own license - see the [original repository](https://github.com/cleeistaken/vcf-credential-manager) for details.

## Credits

- **VCF Credential Manager:** [cleeistaken](https://github.com/cleeistaken/vcf-credential-manager)
- **Installation Scripts:** Created for automated Ubuntu deployment

---

**Made for VMware Cloud Foundation administrators** 🚀

