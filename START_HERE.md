# 🚀 VCF Credential Manager - Ubuntu Service Installation

> **Automated installation scripts to deploy [VCF Credential Manager](https://github.com/cleeistaken/vcf-credential-manager) as a production-ready systemd service on Ubuntu 24.04**

---

## ⚡ Quick Start (3 Steps)

### 1️⃣ Clone this repository
```bash
git clone <this-repository-url>
cd vcf-credential-manager-service
```

### 2️⃣ Run the installation script
```bash
sudo ./install-vcf-credential-manager.sh
```

### 3️⃣ Access the application
```
https://localhost
```

**Default credentials:**
- Username: `admin`
- Password: `admin`

⚠️ **Change the password immediately after first login!**

---

## 📚 Documentation

This project includes comprehensive documentation:

| Document | Description | When to Read |
|----------|-------------|--------------|
| **[INDEX.md](INDEX.md)** | Complete file index and navigation | Start here for overview |
| **[QUICKSTART.md](QUICKSTART.md)** | 3-step installation guide | Quick deployment |
| **[README.md](README.md)** | Complete user guide | Detailed instructions |
| **[INSTALLATION_NOTES.md](INSTALLATION_NOTES.md)** | Advanced configuration | Production deployment |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | System architecture | Technical understanding |
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | Project overview | Feature reference |
| **[TESTING.md](TESTING.md)** | Testing checklist | Verification |
| **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** | Production checklist | Enterprise deployment |

**Total Documentation:** 11 files, ~3,750 lines, covering everything from quick start to enterprise deployment.

---

## ✨ What This Does

The installation script automatically:

- ✅ Installs all dependencies (Python, pipenv, git, nginx, etc.)
- ✅ Creates dedicated service user (`vcfcredmgr`)
- ✅ Clones VCF Credential Manager from GitHub
- ✅ Sets up Python virtual environment with pipenv
- ✅ Generates SSL certificates (self-signed)
- ✅ Configures application to run on port 443 (HTTPS)
- ✅ Creates systemd service with auto-restart
- ✅ Configures firewall rules (UFW)
- ✅ Sets proper permissions and security
- ✅ Initializes database
- ✅ Starts the service automatically

**Installation Location:** `/opt/vcf-credential-manager`

---

## 🎯 Key Features

### 🔒 Security
- HTTPS only (port 443)
- Self-signed SSL certificates (replaceable)
- Dedicated service user
- Systemd security hardening
- Firewall configuration
- Capability-based permissions

### 🛠️ Production Ready
- Systemd service with auto-restart
- Gunicorn WSGI server (4 workers)
- Pipenv virtual environment
- Comprehensive logging
- Performance optimized

### 📖 Well Documented
- 11 documentation files
- Multiple reading paths
- Architecture diagrams
- Testing checklists
- Troubleshooting guides

### 🔧 Easy Maintenance
- Simple service management
- Clear log locations
- Update procedures
- Backup strategies
- Complete uninstall script

---

## 📋 Requirements

- **OS:** Ubuntu 24.04 LTS (or compatible)
- **Access:** Root or sudo privileges
- **Network:** Internet connection
- **Memory:** Minimum 2GB RAM
- **Disk:** 5GB free space
- **Port:** 443 must be available

---

## 🎓 Choose Your Path

### 🏃 Fast Track (5 minutes)
**Goal:** Get it running quickly

1. Read [QUICKSTART.md](QUICKSTART.md)
2. Run `sudo ./install-vcf-credential-manager.sh`
3. Access `https://localhost`

### 🚶 Standard Path (15 minutes)
**Goal:** Understand and deploy properly

1. Read [QUICKSTART.md](QUICKSTART.md)
2. Skim [README.md](README.md)
3. Run installation script
4. Configure environments
5. Test functionality

### 🏢 Enterprise Path (1-2 hours)
**Goal:** Production-ready deployment

1. Read [INDEX.md](INDEX.md) for overview
2. Read [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
3. Read [INSTALLATION_NOTES.md](INSTALLATION_NOTES.md)
4. Review [ARCHITECTURE.md](ARCHITECTURE.md)
5. Plan deployment (SSL, network, monitoring)
6. Run installation script
7. Customize configuration
8. Complete [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
9. Run tests from [TESTING.md](TESTING.md)
10. Set up monitoring and backups

---

## 🛠️ Service Management

### Check Status
```bash
sudo systemctl status vcf-credential-manager
```

### View Logs
```bash
# Real-time systemd logs
sudo journalctl -u vcf-credential-manager -f

# Application logs
sudo tail -f /opt/vcf-credential-manager/logs/vcf_credentials.log
```

### Restart Service
```bash
sudo systemctl restart vcf-credential-manager
```

### Stop Service
```bash
sudo systemctl stop vcf-credential-manager
```

---

## 🗑️ Uninstall

To completely remove the application:

```bash
sudo ./uninstall-vcf-credential-manager.sh
```

This removes:
- Systemd service
- All application files
- Service user and group
- Firewall rules
- Database (⚠️ all data will be lost!)

---

## 📊 What's Included

### Installation Scripts
- **install-vcf-credential-manager.sh** (14KB) - Main installation script
- **uninstall-vcf-credential-manager.sh** (5KB) - Complete removal script
- **vcf-credential-manager.service.template** (1.1KB) - Systemd service template

### Documentation Files
- **INDEX.md** - Complete navigation and index
- **QUICKSTART.md** - Quick start guide
- **README.md** - Complete user guide
- **PROJECT_SUMMARY.md** - Project overview
- **ARCHITECTURE.md** - Technical architecture
- **INSTALLATION_NOTES.md** - Advanced configuration
- **TESTING.md** - Testing checklist
- **DEPLOYMENT_CHECKLIST.md** - Production deployment checklist

---

## 🔍 Quick Troubleshooting

### Service won't start?
```bash
sudo journalctl -u vcf-credential-manager -n 50
```

### Port 443 already in use?
```bash
sudo netstat -tlnp | grep :443
```

### Can't access from remote host?
```bash
sudo ufw allow 443/tcp
sudo ufw status
```

### Need to reset database?
```bash
sudo systemctl stop vcf-credential-manager
sudo rm /opt/vcf-credential-manager/instance/vcf_credentials.db
sudo systemctl start vcf-credential-manager
```

**For more help:** See [README.md](README.md) troubleshooting section

---

## 🏗️ Architecture Overview

```
User Browser (HTTPS)
        ↓
Ubuntu 24.04 Server
        ↓
Systemd Service Manager
        ↓
Gunicorn WSGI Server (Port 443)
        ↓
Flask Application
        ↓
SQLite Database
        ↓
VCF Infrastructure (API calls)
```

**For detailed architecture:** See [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 🎯 Use Cases

### Lab Environment
- Quick deployment with self-signed certificates
- Single server installation
- SQLite database
- Manual credential retrieval

### Production Environment
- Custom SSL certificates
- Firewall restrictions
- Automated credential sync
- Regular backups
- Monitoring and alerting

### Enterprise Environment
- High availability (multiple servers)
- PostgreSQL database
- Load balancer
- Integration with monitoring systems
- Compliance and audit logging

---

## 📞 Support

### Documentation
- **This Repository:** All documentation files
- **Original App:** https://github.com/cleeistaken/vcf-credential-manager

### Logs
- **Systemd:** `journalctl -u vcf-credential-manager`
- **Application:** `/opt/vcf-credential-manager/logs/`

### Issues
- **VCF Credential Manager:** https://github.com/cleeistaken/vcf-credential-manager/issues

---

## 🔐 Security Notes

### Important Security Steps

1. **Change default password** immediately after first login
2. **Use custom SSL certificates** for production
3. **Configure firewall rules** to restrict access
4. **Enable SSL verification** for VCF connections
5. **Set up regular backups** of the database
6. **Monitor logs** for suspicious activity
7. **Keep system updated** with security patches

**For detailed security:** See [INSTALLATION_NOTES.md](INSTALLATION_NOTES.md) and [README.md](README.md)

---

## 📈 Project Statistics

- **Total Files:** 11
- **Total Lines:** ~3,750
- **Total Size:** ~100KB
- **Installation Time:** 5-10 minutes
- **Documentation Coverage:** Complete (beginner to enterprise)

---

## 🎉 What You Get

After installation, you'll have:

- ✅ **Production-ready service** running on port 443
- ✅ **Automatic credential retrieval** from VCF environments
- ✅ **Web interface** for managing environments
- ✅ **Export functionality** (CSV, Excel)
- ✅ **Scheduled syncing** with configurable intervals
- ✅ **Comprehensive logging** for troubleshooting
- ✅ **Auto-restart** on failure
- ✅ **Auto-start** on boot

---

## 🚀 Ready to Deploy?

### For Quick Start:
```bash
sudo ./install-vcf-credential-manager.sh
```

### For Detailed Planning:
1. Read [INDEX.md](INDEX.md)
2. Choose your deployment path
3. Follow the appropriate documentation

---

## 📝 License

This installation script is provided as-is. The VCF Credential Manager application has its own license - see the [original repository](https://github.com/cleeistaken/vcf-credential-manager) for details.

---

## ✨ Credits

- **VCF Credential Manager:** [cleeistaken](https://github.com/cleeistaken/vcf-credential-manager)
- **Installation Scripts:** Created for automated Ubuntu deployment

---

**Made for VMware Cloud Foundation administrators** 🚀

**Version:** 1.0.0  
**Last Updated:** December 2025

---

## 🗺️ Next Steps

1. **New Users:** Start with [QUICKSTART.md](QUICKSTART.md)
2. **Detailed Setup:** Read [README.md](README.md)
3. **Production:** Follow [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
4. **Troubleshooting:** Check [TESTING.md](TESTING.md)
5. **Architecture:** Review [ARCHITECTURE.md](ARCHITECTURE.md)

**Happy deploying!** 🎉

