# Quick Start Guide

## Installation in 3 Steps

### 1. Clone this repository

```bash
git clone <this-repository-url>
cd vcf-credential-manager-service
```

### 2. Run the installation script

```bash
sudo ./install-vcf-credential-manager.sh
```

The script will automatically:
- ✅ Install all dependencies (Python, pipenv, nginx, etc.)
- ✅ Clone the VCF Credential Manager app
- ✅ Set up Python environment with pipenv
- ✅ Generate SSL certificates
- ✅ Configure systemd service
- ✅ Start the service on port 443

### 3. Access the application

Open your browser and go to:
```
https://localhost
```

**Login with default credentials:**
- Username: `admin`
- Password: `admin`

⚠️ **Change the password immediately after first login!**

---

## Common Commands

### Check if service is running
```bash
sudo systemctl status vcf-credential-manager
```

### View logs
```bash
sudo journalctl -u vcf-credential-manager -f
```

### Restart service
```bash
sudo systemctl restart vcf-credential-manager
```

### Stop service
```bash
sudo systemctl stop vcf-credential-manager
```

---

## Uninstall

To completely remove the application:

```bash
sudo ./uninstall-vcf-credential-manager.sh
```

---

## Troubleshooting

### Service won't start?
```bash
# Check the logs
sudo journalctl -u vcf-credential-manager -n 50

# Check if port 443 is in use
sudo netstat -tlnp | grep :443
```

### Can't access from another machine?
```bash
# Make sure firewall allows port 443
sudo ufw allow 443/tcp
sudo ufw status
```

### Need to reset the database?
```bash
sudo systemctl stop vcf-credential-manager
sudo rm /opt/vcf-credential-manager/instance/vcf_credentials.db
sudo systemctl start vcf-credential-manager
```

---

For detailed documentation, see [README.md](README.md)

