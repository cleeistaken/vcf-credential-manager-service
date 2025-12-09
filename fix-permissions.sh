#!/bin/bash
################################################################################
# VCF Credential Manager - Permission Fix Script
# 
# This script fixes common permission issues that may occur after installation.
# Run this if the service fails to start due to permission errors.
#
# Usage:
#   sudo ./fix-permissions.sh
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
APP_USER="vcfcredmgr"
APP_GROUP="vcfcredmgr"
SERVICE_NAME="vcf-credential-manager"

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
echo "  Permission Fix Script"
echo "=========================================="
echo ""

# Check if installation exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "Installation directory not found: $INSTALL_DIR"
    exit 1
fi

# Stop the service
log_info "Stopping service..."
systemctl stop "$SERVICE_NAME" 2>/dev/null || log_warning "Service not running"

# Fix logs directory
log_info "Fixing logs directory permissions..."
if [[ -d "$INSTALL_DIR/logs" ]]; then
    chown -R root:root "$INSTALL_DIR/logs"
    chmod 755 "$INSTALL_DIR/logs"
    chmod 644 "$INSTALL_DIR/logs"/*.log 2>/dev/null || true
    log_success "Logs directory fixed"
else
    log_warning "Logs directory not found, creating..."
    mkdir -p "$INSTALL_DIR/logs"
    chown root:root "$INSTALL_DIR/logs"
    chmod 755 "$INSTALL_DIR/logs"
fi

# Fix instance directory
log_info "Fixing instance directory permissions..."
if [[ -d "$INSTALL_DIR/instance" ]]; then
    chown -R root:root "$INSTALL_DIR/instance"
    chmod 755 "$INSTALL_DIR/instance"
    chmod 600 "$INSTALL_DIR/instance"/*.db 2>/dev/null || true
    log_success "Instance directory fixed"
else
    log_warning "Instance directory not found, creating..."
    mkdir -p "$INSTALL_DIR/instance"
    chown root:root "$INSTALL_DIR/instance"
    chmod 755 "$INSTALL_DIR/instance"
fi

# Fix SSL directory
log_info "Fixing SSL directory permissions..."
if [[ -d "$INSTALL_DIR/ssl" ]]; then
    chmod 644 "$INSTALL_DIR/ssl/cert.pem" 2>/dev/null || true
    chmod 600 "$INSTALL_DIR/ssl/key.pem" 2>/dev/null || true
    log_success "SSL directory fixed"
fi

# Fix application files ownership
# Since the service runs as root (for port 443), set root ownership
log_info "Fixing application files ownership to root..."
chown -R root:root "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

log_success "Application files ownership fixed"

# Start the service
log_info "Starting service..."
systemctl start "$SERVICE_NAME"

# Wait a moment for service to start
sleep 3

# Check service status
if systemctl is-active --quiet "$SERVICE_NAME"; then
    log_success "Service started successfully!"
    echo ""
    echo "Service Status:"
    systemctl status "$SERVICE_NAME" --no-pager -l
else
    log_error "Service failed to start. Check logs:"
    echo ""
    echo "  sudo journalctl -u $SERVICE_NAME -n 50"
    echo "  sudo tail -f $INSTALL_DIR/logs/gunicorn_error.log"
    exit 1
fi

echo ""
echo "=========================================="
log_success "Permission fix completed!"
echo "=========================================="
echo ""
echo "The service should now be running on https://localhost"
echo ""
echo "Useful commands:"
echo "  - Check status: sudo systemctl status $SERVICE_NAME"
echo "  - View logs: sudo journalctl -u $SERVICE_NAME -f"
echo "  - Application logs: sudo tail -f $INSTALL_DIR/logs/*.log"
echo ""

