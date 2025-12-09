#!/bin/bash
################################################################################
# VCF Credential Manager - Service Type Fix Script
# 
# This script fixes the systemd service type issue that causes the service
# to hang with "Got notification message from PID" errors.
#
# Usage:
#   sudo ./fix-service-type.sh
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="/opt/vcf-credential-manager"
SERVICE_NAME="vcf-credential-manager"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
STARTUP_SCRIPT="$INSTALL_DIR/scripts/run_gunicorn_https_443.sh"

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
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "=========================================="
echo "  VCF Credential Manager"
echo "  Service Type Fix Script"
echo "=========================================="
echo ""

# Check if service file exists
if [[ ! -f "$SERVICE_FILE" ]]; then
    log_error "Service file not found: $SERVICE_FILE"
    exit 1
fi

# Stop the service
log_info "Stopping service..."
systemctl stop "$SERVICE_NAME" 2>/dev/null || log_warning "Service not running"

# Backup service file
log_info "Backing up service file..."
cp "$SERVICE_FILE" "${SERVICE_FILE}.backup"
log_success "Backup created: ${SERVICE_FILE}.backup"

# Fix service file
log_info "Updating service file..."
sed -i 's/^Type=notify/Type=exec/' "$SERVICE_FILE"

# Add PIDFile if not present
if ! grep -q "^PIDFile=" "$SERVICE_FILE"; then
    sed -i "/^ExecStart=/a PIDFile=${INSTALL_DIR}/gunicorn.pid" "$SERVICE_FILE"
    log_success "Added PIDFile configuration"
fi

log_success "Service file updated"

# Fix startup script
if [[ -f "$STARTUP_SCRIPT" ]]; then
    log_info "Updating startup script..."
    
    # Backup startup script
    cp "$STARTUP_SCRIPT" "${STARTUP_SCRIPT}.backup"
    
    # Check if already has exec
    if ! grep -q "^exec pipenv" "$STARTUP_SCRIPT"; then
        sed -i 's/^pipenv run gunicorn/exec pipenv run gunicorn/' "$STARTUP_SCRIPT"
        log_success "Added exec to startup script"
    fi
    
    # Check if already has --pid
    if ! grep -q "\-\-pid" "$STARTUP_SCRIPT"; then
        # Add --pid option before app:app
        sed -i 's/\(--keyfile ssl\/key.pem\)/\1 \\\n    --pid gunicorn.pid/' "$STARTUP_SCRIPT"
        log_success "Added PID file option to gunicorn"
    fi
    
    log_success "Startup script updated"
else
    log_warning "Startup script not found: $STARTUP_SCRIPT"
fi

# Reload systemd
log_info "Reloading systemd configuration..."
systemctl daemon-reload
log_success "Systemd configuration reloaded"

# Start the service
log_info "Starting service..."
systemctl start "$SERVICE_NAME"

# Wait a moment for service to start
sleep 5

# Check service status
if systemctl is-active --quiet "$SERVICE_NAME"; then
    log_success "Service started successfully!"
    echo ""
    echo "Service Status:"
    systemctl status "$SERVICE_NAME" --no-pager -l | head -20
else
    log_error "Service failed to start. Check logs:"
    echo ""
    echo "  sudo journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi

echo ""
echo "=========================================="
log_success "Service type fix completed!"
echo "=========================================="
echo ""
echo "The service should now be running without hanging."
echo ""
echo "Changes made:"
echo "  - Service Type changed from 'notify' to 'exec'"
echo "  - Added PID file configuration"
echo "  - Updated startup script to use 'exec'"
echo "  - Added --pid option to gunicorn"
echo ""
echo "Backups created:"
echo "  - ${SERVICE_FILE}.backup"
echo "  - ${STARTUP_SCRIPT}.backup"
echo ""
echo "Access the application at: https://localhost"
echo ""

