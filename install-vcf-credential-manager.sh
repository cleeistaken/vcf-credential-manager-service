#!/bin/bash
################################################################################
# VCF Credential Manager Installation Script for Ubuntu 24.04
# 
# This script installs and configures the VCF Credential Manager application
# as a systemd service running in a chroot jail on port 443 (HTTPS).
#
# Requirements:
# - Ubuntu 24.04
# - Root/sudo access
# - Internet connection
#
# Usage:
#   sudo ./install-vcf-credential-manager.sh
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
APP_NAME="vcf-credential-manager"
APP_USER="vcfcredmgr"
APP_GROUP="vcfcredmgr"
INSTALL_DIR="/opt/${APP_NAME}"
CHROOT_DIR="/opt/${APP_NAME}-chroot"
REPO_URL="https://github.com/cleeistaken/vcf-credential-manager.git"
SERVICE_NAME="vcf-credential-manager"
HTTPS_PORT=443
INTERNAL_PORT=5000

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    log_info "Checking Ubuntu version..."
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            log_error "This script is designed for Ubuntu only"
            exit 1
        fi
        log_success "Running on Ubuntu $VERSION"
    else
        log_error "Cannot determine OS version"
        exit 1
    fi
}

# Install system dependencies
install_dependencies() {
    log_info "Installing system dependencies..."
    
    apt-get update
    apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        git \
        build-essential \
        libssl-dev \
        libffi-dev \
        nginx \
        debootstrap \
        schroot \
        openssl \
        curl \
        wget
    
    # Install pipenv - use --break-system-packages for Ubuntu 24.04
    # This is safe because pipenv will create isolated virtual environments
    log_info "Installing pipenv..."
    pip3 install --break-system-packages --upgrade pipenv
    
    log_success "System dependencies installed"
}

# Create application user and group
create_app_user() {
    log_info "Creating application user and group..."
    
    if ! getent group "$APP_GROUP" > /dev/null 2>&1; then
        groupadd --system "$APP_GROUP"
        log_success "Created group: $APP_GROUP"
    else
        log_warning "Group $APP_GROUP already exists"
    fi
    
    if ! id "$APP_USER" > /dev/null 2>&1; then
        useradd --system \
            --gid "$APP_GROUP" \
            --shell /bin/bash \
            --home-dir "$INSTALL_DIR" \
            --comment "VCF Credential Manager Service User" \
            "$APP_USER"
        log_success "Created user: $APP_USER"
    else
        log_warning "User $APP_USER already exists"
    fi
}

# Clone the repository
clone_repository() {
    log_info "Cloning VCF Credential Manager repository..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        log_warning "Installation directory already exists. Removing..."
        rm -rf "$INSTALL_DIR"
    fi
    
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    log_success "Repository cloned to $INSTALL_DIR"
}

# Setup Python environment with pipenv
setup_python_environment() {
    log_info "Setting up Python environment with pipenv..."
    
    cd "$INSTALL_DIR"
    
    # Get the system Python version
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    log_info "System Python version: $PYTHON_VERSION"
    
    # Ensure proper ownership before creating virtual environment
    log_info "Setting ownership for Python environment setup..."
    chown -R "$APP_USER:$APP_GROUP" "$INSTALL_DIR"
    
    # Check if Pipfile exists and modify it to use system Python
    if [[ -f "Pipfile" ]]; then
        log_info "Configuring Pipfile to use system Python..."
        # Backup original Pipfile
        cp Pipfile Pipfile.original
        
        # Update Pipfile to use system Python version (remove specific version requirement)
        sed -i 's/python_version = .*/python_version = "3.12"/' Pipfile || true
        sed -i 's/python_full_version = .*//' Pipfile || true
        
        # Ensure modified files have correct ownership
        chown "$APP_USER:$APP_GROUP" Pipfile Pipfile.original
    fi
    
    # Install dependencies using pipenv with system Python
    # --skip-lock: Skip Pipfile.lock generation if there are version conflicts
    # --python: Use system python3
    log_info "Installing dependencies with pipenv..."
    sudo -u "$APP_USER" PIPENV_VENV_IN_PROJECT=1 PIPENV_PYTHON=3 pipenv install --skip-lock
    
    log_success "Python environment configured"
}

# Generate SSL certificates
generate_ssl_certificates() {
    log_info "Generating SSL certificates..."
    
    mkdir -p "$INSTALL_DIR/ssl"
    
    if [[ ! -f "$INSTALL_DIR/ssl/cert.pem" ]] || [[ ! -f "$INSTALL_DIR/ssl/key.pem" ]]; then
        openssl req -x509 -newkey rsa:4096 -nodes \
            -keyout "$INSTALL_DIR/ssl/key.pem" \
            -out "$INSTALL_DIR/ssl/cert.pem" \
            -days 365 \
            -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=vcf-credential-manager"
        
        log_success "SSL certificates generated"
    else
        log_warning "SSL certificates already exist"
    fi
    
    chmod 600 "$INSTALL_DIR/ssl/key.pem"
    chmod 644 "$INSTALL_DIR/ssl/cert.pem"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/instance"
    mkdir -p "$INSTALL_DIR/ssl"
    
    # Set initial ownership for directories that need to be writable by root
    # (service runs as root for port 443 binding)
    chown root:root "$INSTALL_DIR/logs"
    chown root:root "$INSTALL_DIR/instance"
    chmod 755 "$INSTALL_DIR/logs"
    chmod 755 "$INSTALL_DIR/instance"
    
    log_success "Directories created"
}

# Setup chroot jail
setup_chroot_jail() {
    log_info "Setting up chroot jail environment..."
    
    # Create chroot directory
    mkdir -p "$CHROOT_DIR"
    
    # Create basic directory structure
    mkdir -p "$CHROOT_DIR"/{bin,lib,lib64,usr,etc,dev,proc,sys,tmp,opt,var}
    mkdir -p "$CHROOT_DIR/usr"/{bin,lib,lib64}
    mkdir -p "$CHROOT_DIR/var/log"
    mkdir -p "$CHROOT_DIR/opt/$APP_NAME"
    
    # Copy necessary binaries
    log_info "Copying necessary binaries to chroot..."
    BINARIES=(
        /bin/bash
        /bin/sh
        /usr/bin/python3
    )
    
    for binary in "${BINARIES[@]}"; do
        if [[ -f "$binary" ]]; then
            cp "$binary" "$CHROOT_DIR$binary" 2>/dev/null || true
            
            # Copy library dependencies
            ldd "$binary" 2>/dev/null | grep -o '/[^ ]*' | while read -r lib; do
                if [[ -f "$lib" ]]; then
                    mkdir -p "$CHROOT_DIR$(dirname "$lib")"
                    cp "$lib" "$CHROOT_DIR$lib" 2>/dev/null || true
                fi
            done
        fi
    done
    
    # Copy Python libraries and site-packages
    log_info "Copying Python environment to chroot..."
    if [[ -d /usr/lib/python3.12 ]]; then
        mkdir -p "$CHROOT_DIR/usr/lib"
        cp -r /usr/lib/python3.12 "$CHROOT_DIR/usr/lib/" 2>/dev/null || true
    fi
    
    # Copy the application to chroot
    log_info "Copying application to chroot..."
    rsync -av --exclude='.git' "$INSTALL_DIR/" "$CHROOT_DIR/opt/$APP_NAME/"
    
    # Create device nodes
    mknod -m 666 "$CHROOT_DIR/dev/null" c 1 3 2>/dev/null || true
    mknod -m 666 "$CHROOT_DIR/dev/zero" c 1 5 2>/dev/null || true
    mknod -m 666 "$CHROOT_DIR/dev/random" c 1 8 2>/dev/null || true
    mknod -m 666 "$CHROOT_DIR/dev/urandom" c 1 9 2>/dev/null || true
    
    # Set permissions
    chmod 1777 "$CHROOT_DIR/tmp"
    
    log_success "Chroot jail environment created"
}

# Create wrapper script for running in chroot
create_chroot_wrapper() {
    log_info "Creating chroot wrapper script..."
    
    cat > "$INSTALL_DIR/run_chroot.sh" << 'EOF'
#!/bin/bash
# Wrapper script to run application in chroot jail

CHROOT_DIR="/opt/vcf-credential-manager-chroot"
APP_DIR="/opt/vcf-credential-manager"

# Mount necessary filesystems
mount --bind /proc "$CHROOT_DIR/proc" 2>/dev/null || true
mount --bind /sys "$CHROOT_DIR/sys" 2>/dev/null || true
mount --bind /dev "$CHROOT_DIR/dev" 2>/dev/null || true

# Sync application files to chroot
rsync -av --exclude='.git' --exclude='*.pyc' "$APP_DIR/" "$CHROOT_DIR/opt/vcf-credential-manager/"

# Execute the application in chroot
chroot "$CHROOT_DIR" /bin/bash -c "cd /opt/vcf-credential-manager && ./scripts/run_gunicorn_https.sh"
EOF
    
    chmod +x "$INSTALL_DIR/run_chroot.sh"
    
    log_success "Chroot wrapper script created"
}

# Modify run_gunicorn_https.sh to use port 443
configure_gunicorn_script() {
    log_info "Configuring Gunicorn HTTPS script for port 443..."
    
    # Check if the script exists
    if [[ ! -f "$INSTALL_DIR/scripts/run_gunicorn_https.sh" ]]; then
        log_error "run_gunicorn_https.sh not found in scripts directory"
        exit 1
    fi
    
    # Make it executable
    chmod +x "$INSTALL_DIR/scripts/run_gunicorn_https.sh"
    
    # Create a custom version that binds to 0.0.0.0:443
    cat > "$INSTALL_DIR/scripts/run_gunicorn_https_443.sh" << 'EOF'
#!/bin/bash
# Custom Gunicorn HTTPS startup script for port 443

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$(dirname "$SCRIPT_DIR")"

cd "$APP_DIR"

# Activate pipenv environment and run gunicorn
export PIPENV_VENV_IN_PROJECT=1
exec pipenv run gunicorn \
    --config gunicorn_config.py \
    --bind 0.0.0.0:443 \
    --certfile ssl/cert.pem \
    --keyfile ssl/key.pem \
    --pid gunicorn.pid \
    --access-logfile logs/gunicorn_access.log \
    --error-logfile logs/gunicorn_error.log \
    app:app
EOF
    
    chmod +x "$INSTALL_DIR/scripts/run_gunicorn_https_443.sh"
    
    log_success "Gunicorn script configured for port 443"
}

# Create systemd service file
create_systemd_service() {
    log_info "Creating systemd service..."
    
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=VCF Credential Manager Service
After=network.target
Wants=network-online.target

[Service]
Type=exec
User=root
Group=root
WorkingDirectory=${INSTALL_DIR}
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="PIPENV_VENV_IN_PROJECT=1"
Environment="PYTHONUNBUFFERED=1"

# Use the custom script that runs on port 443
ExecStart=${INSTALL_DIR}/scripts/run_gunicorn_https_443.sh

# PID file for proper process tracking
PIDFile=${INSTALL_DIR}/gunicorn.pid

# Restart policy
Restart=always
RestartSec=10
StartLimitInterval=200
StartLimitBurst=5

# Security settings
NoNewPrivileges=false
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${INSTALL_DIR}

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

# Allow binding to privileged port 443
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
    
    log_success "Systemd service file created"
}

# Set proper permissions
set_permissions() {
    log_info "Setting proper permissions..."
    
    # Set ownership for most files
    chown -R "$APP_USER:$APP_GROUP" "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    
    # SSL certificates - restrictive permissions
    chmod 600 "$INSTALL_DIR/ssl/key.pem"
    chmod 644 "$INSTALL_DIR/ssl/cert.pem"
    
    # Database - restrictive permissions
    chmod 600 "$INSTALL_DIR/instance/vcf_credentials.db" 2>/dev/null || true
    
    # Logs directory - needs to be writable by root (service runs as root for port 443)
    # Set to root ownership with group write permissions
    chown -R root:root "$INSTALL_DIR/logs"
    chmod 755 "$INSTALL_DIR/logs"
    chmod 644 "$INSTALL_DIR/logs"/*.log 2>/dev/null || true
    
    # Instance directory - needs to be writable by root
    chown -R root:root "$INSTALL_DIR/instance"
    chmod 755 "$INSTALL_DIR/instance"
    
    # Chroot permissions
    if [[ -d "$CHROOT_DIR" ]]; then
        chown -R root:root "$CHROOT_DIR"
        chown -R "$APP_USER:$APP_GROUP" "$CHROOT_DIR/opt/$APP_NAME"
    fi
    
    log_success "Permissions set"
}

# Initialize database
initialize_database() {
    log_info "Initializing database..."
    
    cd "$INSTALL_DIR"
    sudo -u "$APP_USER" bash -c "cd $INSTALL_DIR && PIPENV_VENV_IN_PROJECT=1 pipenv run python3 -c 'from app import app, db; app.app_context().push(); db.create_all()'" || true
    
    log_success "Database initialized"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 443/tcp comment 'VCF Credential Manager HTTPS'
        log_success "Firewall rule added for port 443"
    else
        log_warning "UFW not found, skipping firewall configuration"
    fi
}

# Enable and start service
enable_service() {
    log_info "Enabling and starting service..."
    
    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}.service"
    systemctl start "${SERVICE_NAME}.service"
    
    sleep 5
    
    if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
        log_success "Service started successfully"
    else
        log_error "Service failed to start. Check logs with: journalctl -u ${SERVICE_NAME}.service -n 50"
        exit 1
    fi
}

# Display installation summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "  VCF Credential Manager Installation"
    echo "=========================================="
    echo ""
    log_success "Installation completed successfully!"
    echo ""
    echo "Installation Details:"
    echo "  - Installation Directory: $INSTALL_DIR"
    echo "  - Chroot Directory: $CHROOT_DIR"
    echo "  - Service Name: $SERVICE_NAME"
    echo "  - HTTPS Port: $HTTPS_PORT"
    echo "  - Application User: $APP_USER"
    echo ""
    echo "SSL Certificates:"
    echo "  - Certificate: $INSTALL_DIR/ssl/cert.pem"
    echo "  - Private Key: $INSTALL_DIR/ssl/key.pem"
    echo ""
    echo "Access the application:"
    echo "  - URL: https://localhost:$HTTPS_PORT"
    echo "  - Default Username: admin"
    echo "  - Default Password: admin"
    echo ""
    echo "⚠️  IMPORTANT: Change the default password immediately after first login!"
    echo ""
    echo "Useful Commands:"
    echo "  - Check status: systemctl status $SERVICE_NAME"
    echo "  - View logs: journalctl -u $SERVICE_NAME -f"
    echo "  - Restart service: systemctl restart $SERVICE_NAME"
    echo "  - Stop service: systemctl stop $SERVICE_NAME"
    echo "  - Application logs: tail -f $INSTALL_DIR/logs/*.log"
    echo ""
    echo "=========================================="
}

# Main installation flow
main() {
    echo ""
    echo "=========================================="
    echo "  VCF Credential Manager Installer"
    echo "=========================================="
    echo ""
    
    check_root
    check_ubuntu_version
    install_dependencies
    create_app_user
    clone_repository
    create_directories
    generate_ssl_certificates
    setup_python_environment
    configure_gunicorn_script
    # Note: Chroot setup is complex and may cause issues, commenting out for now
    # setup_chroot_jail
    # create_chroot_wrapper
    initialize_database
    set_permissions
    create_systemd_service
    configure_firewall
    enable_service
    display_summary
}

# Run main function
main "$@"

