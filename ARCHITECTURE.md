# VCF Credential Manager - Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                            │
│                    https://server-ip:443                        │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS (SSL/TLS)
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      Ubuntu 24.04 Server                        │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │              Systemd Service Manager                      │ │
│  │         (vcf-credential-manager.service)                  │ │
│  │                                                           │ │
│  │  - Auto-start on boot                                     │ │
│  │  - Auto-restart on failure                                │ │
│  │  - Health monitoring                                      │ │
│  │  - Log management                                         │ │
│  └─────────────────────────┬─────────────────────────────────┘ │
│                            │                                   │
│  ┌─────────────────────────▼─────────────────────────────────┐ │
│  │           Gunicorn WSGI Server (Port 443)                 │ │
│  │                                                           │ │
│  │  Workers: 4 processes                                     │ │
│  │  Threads: 2 per worker                                    │ │
│  │  SSL: cert.pem + key.pem                                  │ │
│  │  Binding: 0.0.0.0:443                                     │ │
│  └─────────────────────────┬─────────────────────────────────┘ │
│                            │                                   │
│  ┌─────────────────────────▼─────────────────────────────────┐ │
│  │              Flask Application (app.py)                   │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │              Web Interface                          │ │ │
│  │  │  - User authentication (Flask-Login)                │ │ │
│  │  │  - Environment management                           │ │ │
│  │  │  - Credential viewing                               │ │ │
│  │  │  - Export functionality                             │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │           Background Scheduler                      │ │ │
│  │  │  - APScheduler                                      │ │ │
│  │  │  - Automatic credential sync                        │ │ │
│  │  │  - Per-environment schedules                        │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │              VCF API Client                         │ │ │
│  │  │  - Connects to VCF Installer                        │ │ │
│  │  │  - Connects to SDDC Manager                         │ │ │
│  │  │  - Retrieves credentials                            │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └───────────────────────┬───────────────────────────────────┘ │
│                          │                                     │
│  ┌───────────────────────▼───────────────────────────────────┐ │
│  │          SQLAlchemy ORM + SQLite Database                 │ │
│  │                                                           │ │
│  │  Tables:                                                  │ │
│  │  - users (authentication)                                 │ │
│  │  - environments (VCF connections)                         │ │
│  │  - credentials (cached credentials)                       │ │
│  │                                                           │ │
│  │  File: /opt/vcf-credential-manager/instance/              │ │
│  │        vcf_credentials.db                                 │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                   File System                             │ │
│  │                                                           │ │
│  │  /opt/vcf-credential-manager/                             │ │
│  │  ├── app.py                    (Flask app)                │ │
│  │  ├── gunicorn_config.py        (Gunicorn config)          │ │
│  │  ├── scripts/                  (Startup scripts)          │ │
│  │  ├── ssl/                      (SSL certificates)         │ │
│  │  ├── logs/                     (Application logs)         │ │
│  │  ├── instance/                 (Database)                 │ │
│  │  ├── templates/                (HTML templates)           │ │
│  │  ├── static/                   (CSS, JS, images)          │ │
│  │  └── .venv/                    (Pipenv virtualenv)        │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ HTTPS API Calls
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    VCF Infrastructure                           │
│                                                                 │
│  ┌─────────────────────┐         ┌─────────────────────┐       │
│  │   VCF Installer     │         │   SDDC Manager      │       │
│  │   (Optional)        │         │   (Optional)        │       │
│  │                     │         │                     │       │
│  │  - Provides system  │         │  - Provides domain  │       │
│  │    credentials      │         │    credentials      │       │
│  └─────────────────────┘         └─────────────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Systemd Service Layer

**Purpose:** Service lifecycle management

**Responsibilities:**
- Start application on boot
- Restart on failure
- Monitor health
- Manage logs
- Control access permissions

**Configuration:** `/etc/systemd/system/vcf-credential-manager.service`

### 2. Gunicorn WSGI Server

**Purpose:** Production-grade HTTP server

**Features:**
- Multiple worker processes (parallelism)
- Thread-based workers (concurrency)
- SSL/TLS termination
- Request handling
- Load balancing across workers
- Graceful worker restarts

**Configuration:** `/opt/vcf-credential-manager/gunicorn_config.py`

### 3. Flask Application

**Purpose:** Web application framework

**Components:**

#### Web Interface
- HTML templates (Jinja2)
- CSS styling (Bootstrap)
- JavaScript (jQuery)
- User authentication
- Session management

#### Background Scheduler
- APScheduler for periodic tasks
- Per-environment sync schedules
- Automatic credential updates
- Error handling and retry logic

#### VCF API Client
- REST API calls to VCF systems
- SSL verification (configurable)
- Credential retrieval
- Error handling

### 4. Database Layer

**Purpose:** Data persistence

**Technology:** SQLite (default)

**Schema:**

```sql
-- Users table
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username VARCHAR(80) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Environments table
CREATE TABLE environments (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    installer_host VARCHAR(255),
    installer_username VARCHAR(100),
    installer_password VARCHAR(255),
    installer_ssl_verify BOOLEAN,
    sddc_host VARCHAR(255),
    sddc_username VARCHAR(100),
    sddc_password VARCHAR(255),
    sddc_ssl_verify BOOLEAN,
    sync_enabled BOOLEAN,
    sync_interval INTEGER,
    last_sync DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Credentials table
CREATE TABLE credentials (
    id INTEGER PRIMARY KEY,
    environment_id INTEGER,
    resource_name VARCHAR(255),
    resource_type VARCHAR(100),
    username VARCHAR(255),
    password VARCHAR(255),
    account_type VARCHAR(100),
    domain VARCHAR(100),
    retrieved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (environment_id) REFERENCES environments(id)
);
```

### 5. File System

**Directory Structure:**

```
/opt/vcf-credential-manager/
├── app.py                          # Main Flask application
├── gunicorn_config.py              # Gunicorn configuration
├── requirements.txt                # Python dependencies
├── Pipfile                         # Pipenv configuration
├── Pipfile.lock                    # Locked dependencies
│
├── scripts/
│   ├── run_gunicorn_https.sh      # Original startup script
│   └── run_gunicorn_https_443.sh  # Custom script (port 443)
│
├── ssl/
│   ├── cert.pem                    # SSL certificate
│   └── key.pem                     # SSL private key
│
├── logs/
│   ├── vcf_credentials.log         # Application log
│   ├── vcf_credentials_errors.log  # Error log
│   ├── gunicorn_access.log         # HTTP access log
│   └── gunicorn_error.log          # Gunicorn error log
│
├── instance/
│   └── vcf_credentials.db          # SQLite database
│
├── templates/                      # Jinja2 HTML templates
│   ├── base.html
│   ├── login.html
│   ├── index.html
│   ├── add_environment.html
│   ├── edit_environment.html
│   ├── view_credentials.html
│   └── change_password.html
│
├── static/                         # Static assets
│   ├── css/
│   ├── js/
│   └── images/
│
├── web/                            # Web modules
│   ├── __init__.py
│   ├── routes.py
│   ├── models.py
│   └── utils.py
│
└── .venv/                          # Pipenv virtual environment
    ├── bin/
    ├── lib/
    └── ...
```

## Data Flow

### User Login Flow

```
1. User → Browser → https://server:443/login
2. Gunicorn → Flask → Login route
3. Flask → Verify credentials → Database
4. Database → Return user → Flask
5. Flask → Create session → Set cookie
6. Flask → Redirect to dashboard
7. Browser → Display dashboard
```

### Credential Sync Flow

```
1. Scheduler → Trigger sync job
2. Flask → Check environment config → Database
3. Flask → Connect to VCF Installer → HTTPS API
4. VCF Installer → Return credentials → Flask
5. Flask → Connect to SDDC Manager → HTTPS API
6. SDDC Manager → Return credentials → Flask
7. Flask → Store credentials → Database
8. Flask → Update last_sync timestamp → Database
9. Flask → Log sync result → Log file
```

### Credential View Flow

```
1. User → Click "View" → Browser
2. Browser → Request /view/<env_id> → Gunicorn
3. Gunicorn → Flask → View route
4. Flask → Query credentials → Database
5. Database → Return credentials → Flask
6. Flask → Render template → HTML
7. Gunicorn → Send response → Browser
8. Browser → Display credentials table
```

## Security Architecture

### Authentication Layer

```
┌─────────────────────────────────────────────────────────────┐
│                    User Authentication                      │
│                                                             │
│  1. User enters username/password                           │
│  2. Flask-Login validates credentials                       │
│  3. Password hash verified (PBKDF2-SHA256)                  │
│  4. Session created with secure cookie                      │
│  5. Session stored server-side                              │
│  6. Cookie sent to browser (HttpOnly, Secure)               │
└─────────────────────────────────────────────────────────────┘
```

### Network Security

```
┌─────────────────────────────────────────────────────────────┐
│                     Network Security                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Firewall (UFW)                                     │   │
│  │  - Allow port 443 only                              │   │
│  │  - Block all other ports                            │   │
│  │  - Optional: IP whitelist                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  SSL/TLS Layer                                      │   │
│  │  - TLS 1.2+ only                                    │   │
│  │  - Strong cipher suites                             │   │
│  │  - Certificate validation                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Application Layer                                  │   │
│  │  - Session-based auth                               │   │
│  │  - CSRF protection                                  │   │
│  │  - Input validation                                 │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### File System Security

```
┌─────────────────────────────────────────────────────────────┐
│                  File System Permissions                    │
│                                                             │
│  /opt/vcf-credential-manager/                               │
│  ├── Owner: vcfcredmgr:vcfcredmgr                           │
│  ├── Permissions: 755 (directories), 644 (files)            │
│  │                                                           │
│  ├── ssl/key.pem                                            │
│  │   └── Permissions: 600 (read/write owner only)          │
│  │                                                           │
│  ├── instance/vcf_credentials.db                            │
│  │   └── Permissions: 600 (read/write owner only)          │
│  │                                                           │
│  └── logs/                                                  │
│      └── Permissions: 640 (owner read/write, group read)    │
└─────────────────────────────────────────────────────────────┘
```

### Systemd Security

```
┌─────────────────────────────────────────────────────────────┐
│                   Systemd Hardening                         │
│                                                             │
│  - PrivateTmp=true          (Isolated /tmp)                 │
│  - ProtectSystem=strict     (Read-only system files)        │
│  - ProtectHome=true         (No access to home dirs)        │
│  - NoNewPrivileges=false    (Required for port 443)         │
│  - ReadWritePaths=          (Limited write access)          │
│    - /opt/vcf-credential-manager/logs                       │
│    - /opt/vcf-credential-manager/instance                   │
│  - AmbientCapabilities=     (Minimal capabilities)          │
│    - CAP_NET_BIND_SERVICE   (Bind to port 443)              │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Topology

### Single Server Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                     Single Server                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  VCF Credential Manager                             │   │
│  │  - All components on one server                     │   │
│  │  - SQLite database                                  │   │
│  │  - Good for: Small/medium deployments               │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### High Availability Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                  Load Balancer (HAProxy)                    │
│                      Port 443                               │
└────────────┬─────────────────────────┬──────────────────────┘
             │                         │
    ┌────────▼────────┐       ┌────────▼────────┐
    │   Server 1      │       │   Server 2      │
    │   Port 5001     │       │   Port 5002     │
    └────────┬────────┘       └────────┬────────┘
             │                         │
             └────────┬────────────────┘
                      │
             ┌────────▼────────┐
             │   PostgreSQL    │
             │   Database      │
             └─────────────────┘
```

## Monitoring and Logging

### Log Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      Application                            │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Python Logging                                     │   │
│  │  - DEBUG, INFO, WARNING, ERROR, CRITICAL            │   │
│  └──────────────┬──────────────────────────────────────┘   │
│                 │                                           │
│        ┌────────┴────────┐                                  │
│        │                 │                                  │
│  ┌─────▼─────┐    ┌──────▼──────┐                          │
│  │ File Log  │    │   Systemd   │                          │
│  │           │    │   Journal   │                          │
│  │ *.log     │    │  journalctl │                          │
│  └───────────┘    └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

### Monitoring Points

1. **Service Health:** `systemctl status vcf-credential-manager`
2. **Resource Usage:** `top`, `htop`, `ps`
3. **Network:** `netstat`, `ss`
4. **Logs:** `journalctl`, log files
5. **Database:** File size, query performance
6. **Disk Space:** `df -h`

## Performance Characteristics

### Capacity

- **Concurrent Users:** 50-100 (default config)
- **Environments:** Unlimited (database limited)
- **Credentials:** Thousands per environment
- **Sync Frequency:** Configurable (minutes)

### Resource Usage

- **Memory:** ~200-500 MB (base + workers)
- **CPU:** Low (idle), Medium (during sync)
- **Disk:** ~100 MB (app) + database size
- **Network:** Minimal (API calls only)

### Scalability

**Vertical Scaling:**
- Increase workers/threads
- Add more CPU/RAM
- Upgrade to PostgreSQL

**Horizontal Scaling:**
- Multiple app servers
- Load balancer
- Shared database

## Backup and Recovery

### Backup Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Backup Components                        │
│                                                             │
│  1. Database                                                │
│     └── /opt/vcf-credential-manager/instance/*.db           │
│                                                             │
│  2. SSL Certificates (if custom)                            │
│     └── /opt/vcf-credential-manager/ssl/*.pem               │
│                                                             │
│  3. Configuration                                           │
│     └── /opt/vcf-credential-manager/gunicorn_config.py      │
│                                                             │
│  4. Logs (optional)                                         │
│     └── /opt/vcf-credential-manager/logs/*.log              │
└─────────────────────────────────────────────────────────────┘
```

### Recovery Process

```
1. Stop service
2. Restore database file
3. Restore SSL certificates
4. Restore configuration
5. Set proper permissions
6. Start service
7. Verify functionality
```

---

**Architecture Version:** 1.0  
**Last Updated:** December 2025

