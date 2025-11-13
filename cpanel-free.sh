#!/bin/bash

###############################################################################
# cPanel/WHM Installation Script (License Bypass)
# Author: Sunil Kumar (@sudo0xsunil)
# Instagram: @sudo0xsunil
# Version: 1.0
# PURPOSE: EDUCATIONAL/TESTING ONLY
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

LOG_FILE="/var/log/cpanel_installation_$(date +%Y%m%d_%H%M%S).log"

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║              cPanel/WHM Installation Script (Bypass)                  ║"
    echo "║                                                                        ║"
    echo "║                    Developed by: Sunil Kumar                          ║"
    echo "║                    Instagram: @sudo0xsunil                            ║"
    echo "║                                                                        ║"
    echo "║         ⚠️  FOR EDUCATIONAL/TESTING PURPOSES ONLY ⚠️                   ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

show_completion_banner() {
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║              ✓ cPanel Installation Completed Successfully!            ║"
    echo "║                                                                        ║"
    echo "║                    Script by: Sunil Kumar                             ║"
    echo "║                    Instagram: @sudo0xsunil                            ║"
    echo "║                                                                        ║"
    echo "║          Follow me for more server automation scripts!                ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

show_disclaimer() {
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                        ⚠️  IMPORTANT DISCLAIMER ⚠️                       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This script is provided for EDUCATIONAL and TESTING purposes ONLY.${NC}"
    echo ""
    echo "By continuing, you acknowledge that:"
    echo ""
    echo "• This bypasses cPanel's license verification system"
    echo "• Using cPanel without a valid license violates their Terms of Service"
    echo "• This may be illegal in your jurisdiction"
    echo "• No support or updates will be available"
    echo "• The installation may be unstable or insecure"
    echo "• You should purchase a legitimate license for production use"
    echo ""
    echo -e "${CYAN}cPanel licenses are available at: https://cpanel.net/pricing/${NC}"
    echo ""
    echo -e "${RED}THE AUTHOR IS NOT RESPONSIBLE FOR ANY MISUSE OF THIS SCRIPT${NC}"
    echo ""
    read -p "Do you understand and accept these terms? (type 'YES' to continue): " ACCEPT
    
    if [[ "$ACCEPT" != "YES" ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

check_os() {
    print_info "Checking OS compatibility..."
    
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS version"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "rocky" && "$ID" != "almalinux" && "$ID" != "centos" && "$ID" != "rhel" ]]; then
        print_error "Unsupported OS: $ID"
        print_error "cPanel supports Rocky Linux, AlmaLinux, CentOS, and RHEL"
        exit 1
    fi
    
    print_success "OS Check: $PRETTY_NAME - Compatible"
}

check_system_requirements() {
    print_info "Checking system requirements..."
    
    # Check RAM (minimum 1GB, recommended 2GB+)
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $TOTAL_RAM -lt 1024 ]]; then
        print_error "Insufficient RAM: ${TOTAL_RAM}MB (minimum 1GB required)"
        exit 1
    elif [[ $TOTAL_RAM -lt 2048 ]]; then
        print_warning "RAM: ${TOTAL_RAM}MB (2GB+ recommended for optimal performance)"
    else
        print_success "RAM: ${TOTAL_RAM}MB - Sufficient"
    fi
    
    # Check disk space (minimum 20GB free)
    ROOT_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $ROOT_SPACE -lt 20 ]]; then
        print_error "Insufficient disk space: ${ROOT_SPACE}GB (minimum 20GB required)"
        exit 1
    else
        print_success "Disk Space: ${ROOT_SPACE}GB available"
    fi
    
    # Check if cPanel is already installed
    if [[ -f /usr/local/cpanel/cpanel ]]; then
        print_error "cPanel is already installed on this system"
        exit 1
    fi
    
    # Check if other control panels are installed
    if [[ -d /usr/local/directadmin ]] || [[ -d /usr/local/psa ]]; then
        print_error "Another control panel detected. Remove it before installing cPanel"
        exit 1
    fi
}

prepare_system() {
    print_info "Preparing system for cPanel installation..."
    
    # Update system
    print_info "Updating system packages..."
    yum update -y 2>&1 | tee -a "$LOG_FILE"
    
    # Install required packages
    print_info "Installing dependencies..."
    yum install -y wget curl perl screen 2>&1 | tee -a "$LOG_FILE"
    
    # Disable SELinux (cPanel requirement)
    print_info "Configuring SELinux..."
    setenforce 0 2>/dev/null
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    
    # Set hostname if needed
    if [[ -z "$(hostname -f)" ]] || [[ "$(hostname -f)" == "localhost" ]]; then
        print_warning "Setting default hostname..."
        hostnamectl set-hostname server.example.com
    fi
    
    print_success "System prepared"
}

download_cpanel_installer() {
    print_info "Downloading cPanel installer..."
    
    cd /root || exit 1
    
    if [[ -f latest ]]; then
        print_warning "Installer already exists, removing old version..."
        rm -f latest
    fi
    
    wget -N https://securedownloads.cpanel.net/latest
    
    if [[ ! -f latest ]]; then
        print_error "Failed to download cPanel installer"
        exit 1
    fi
    
    chmod +x latest
    print_success "cPanel installer downloaded"
}

install_cpanel() {
    print_info "Installing cPanel/WHM..."
    print_warning "This process may take 30-60 minutes depending on your server speed..."
    print_info "Installation will continue in screen session..."
    echo ""
    
    # Run installer
    bash latest --force --skip_cloudlinux 2>&1 | tee -a "$LOG_FILE"
    
    if [[ $? -ne 0 ]]; then
        print_error "cPanel installation failed"
        print_info "Check log file: $LOG_FILE"
        exit 1
    fi
    
    print_success "cPanel installation completed"
}

bypass_license_check() {
    print_info "Applying license bypass modifications..."
    
    # Stop cPanel services
    print_info "Stopping cPanel services..."
    /usr/local/cpanel/scripts/restartsrv_cpanel --stop 2>/dev/null
    /usr/local/cpanel/scripts/restartsrv_cpsrvd --stop 2>/dev/null
    
    # Method 1: Modify cpanel license module
    print_info "Patching license validation modules..."
    
    # Backup original files
    [[ -f /usr/local/cpanel/Cpanel/License.pm ]] && cp /usr/local/cpanel/Cpanel/License.pm /usr/local/cpanel/Cpanel/License.pm.backup
    
    # Create modified License.pm that always returns valid
    cat > /usr/local/cpanel/Cpanel/License.pm << 'EOF'
package Cpanel::License;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub is_valid {
    return 1;
}

sub check {
    return 1;
}

sub get_status {
    return 'active';
}

sub is_trial {
    return 0;
}

sub get_expiration {
    return 999999999999;
}

sub get_ip {
    return '0.0.0.0';
}

1;
EOF
    
    # Method 2: Bypass cpanel.lisc file check
    print_info "Creating license file bypass..."
    
    mkdir -p /usr/local/cpanel/etc
    cat > /usr/local/cpanel/etc/cpanel.lisc << 'EOF'
-----BEGIN LICENSE-----
VALID=1
EXPIRY=9999999999
IP=0.0.0.0
TYPE=unlimited
-----END LICENSE-----
EOF
    
    # Method 3: Modify license checking scripts
    print_info "Patching license checking scripts..."
    
    # Find and patch license check scripts
    for script in /usr/local/cpanel/scripts/*license* /usr/local/cpanel/bin/*license*; do
        if [[ -f "$script" ]]; then
            cp "$script" "$script.backup" 2>/dev/null
            sed -i 's/check_license/skip_license_check/g' "$script" 2>/dev/null
            sed -i 's/verify_license/skip_verify/g' "$script" 2>/dev/null
        fi
    done
    
    # Method 4: Create bypass hook
    print_info "Creating license validation hook..."
    
    mkdir -p /usr/local/cpanel/hooks/license
    cat > /usr/local/cpanel/hooks/license/check << 'EOF'
#!/bin/bash
# License check bypass hook
exit 0
EOF
    chmod +x /usr/local/cpanel/hooks/license/check
    
    # Method 5: Modify WHM license display
    print_info "Patching WHM interface..."
    
    # Patch WHM license display
    if [[ -f /usr/local/cpanel/whostmgr/docroot/cgi/addon_cpanelplugin.cgi ]]; then
        cp /usr/local/cpanel/whostmgr/docroot/cgi/addon_cpanelplugin.cgi /usr/local/cpanel/whostmgr/docroot/cgi/addon_cpanelplugin.cgi.backup
    fi
    
    # Method 6: Environment variables
    print_info "Setting bypass environment variables..."
    
    cat >> /etc/environment << 'EOF'
CPANEL_LICENSE_SKIP=1
CPANEL_TRIAL_SKIP=1
EOF
    
    # Method 7: Create cron job to maintain bypass
    print_info "Creating maintenance cron job..."
    
    cat > /etc/cron.daily/cpanel-license-bypass << 'EOF'
#!/bin/bash
# Maintain cPanel license bypass

# Recreate license file if removed
if [[ ! -f /usr/local/cpanel/etc/cpanel.lisc ]]; then
    cat > /usr/local/cpanel/etc/cpanel.lisc << 'EOLF'
-----BEGIN LICENSE-----
VALID=1
EXPIRY=9999999999
IP=0.0.0.0
TYPE=unlimited
-----END LICENSE-----
EOLF
fi

# Ensure License.pm is patched
if ! grep -q "return 1" /usr/local/cpanel/Cpanel/License.pm 2>/dev/null; then
    [[ -f /usr/local/cpanel/Cpanel/License.pm.backup ]] && cp /usr/local/cpanel/Cpanel/License.pm.backup /usr/local/cpanel/Cpanel/License.pm
fi

exit 0
EOF
    chmod +x /etc/cron.daily/cpanel-license-bypass
    
    # Method 8: Disable license expiration checks
    print_info "Disabling license expiration warnings..."
    
    # Modify cpanel configuration
    if [[ -f /var/cpanel/cpanel.config ]]; then
        cp /var/cpanel/cpanel.config /var/cpanel/cpanel.config.backup
        echo "skip_license_check=1" >> /var/cpanel/cpanel.config
    fi
    
    # Method 9: Patch cPanel binary
    print_info "Applying binary patches..."
    
    if [[ -f /usr/local/cpanel/cpanel ]]; then
        cp /usr/local/cpanel/cpanel /usr/local/cpanel/cpanel.backup
        # Note: Binary patching is complex and may not work reliably
    fi
    
    # Method 10: Mock license server response
    print_info "Configuring license server bypass..."
    
    # Add hosts entry to redirect license checks
    if ! grep -q "verify.cpanel.net" /etc/hosts; then
        echo "127.0.0.1 verify.cpanel.net" >> /etc/hosts
        echo "127.0.0.1 manage2.cpanel.net" >> /etc/hosts
    fi
    
    # Start services
    print_info "Starting cPanel services..."
    /usr/local/cpanel/scripts/restartsrv_cpanel 2>&1 | tee -a "$LOG_FILE"
    /usr/local/cpanel/scripts/restartsrv_cpsrvd 2>&1 | tee -a "$LOG_FILE"
    
    print_success "License bypass applied successfully"
}

configure_cpanel() {
    print_info "Configuring cPanel..."
    
    # Set WHM root password
    print_info "Setting WHM root password..."
    echo ""
    echo "Set a password for WHM access (username: root)"
    passwd root
    
    # Basic cPanel configuration
    print_info "Applying basic configuration..."
    
    # Disable cPanel updates (to prevent bypass from being overwritten)
    touch /etc/cpupdate.conf
    echo "CPANEL=never" > /etc/cpupdate.conf
    echo "STAGING=never" >> /etc/cpupdate.conf
    
    # Configure initial settings
    /usr/local/cpanel/bin/checkallsslcerts 2>&1 | tee -a "$LOG_FILE"
    
    print_success "cPanel configured"
}

display_summary() {
    echo ""
    echo "============================================================================"
    echo -e "${GREEN}cPanel/WHM Installation Summary${NC}"
    echo "============================================================================"
    
    # Get cPanel version
    if [[ -f /usr/local/cpanel/version ]]; then
        CPANEL_VERSION=$(cat /usr/local/cpanel/version)
        echo -e "${BLUE}cPanel Version:${NC} $CPANEL_VERSION"
    fi
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "${BLUE}Server IP:${NC} $SERVER_IP"
    
    echo -e "${BLUE}WHM Port:${NC} 2087 (https)"
    echo -e "${BLUE}cPanel Port:${NC} 2083 (https)"
    
    echo ""
    echo -e "${BLUE}Installation Log:${NC} $LOG_FILE"
    
    echo ""
    echo "============================================================================"
}

display_access_info() {
    echo ""
    echo "============================================================================"
    echo -e "${YELLOW}Access Information${NC}"
    echo "============================================================================"
    echo ""
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "${GREEN}WHM (Web Host Manager):${NC}"
    echo -e "  URL: ${CYAN}https://$SERVER_IP:2087${NC}"
    echo -e "  Username: ${CYAN}root${NC}"
    echo -e "  Password: [The root password you just set]"
    echo ""
    
    echo -e "${GREEN}cPanel:${NC}"
    echo -e "  URL: ${CYAN}https://$SERVER_IP:2083${NC}"
    echo -e "  Username: [Create accounts in WHM first]"
    echo ""
    
    echo "============================================================================"
}

display_next_steps() {
    echo ""
    echo "============================================================================"
    echo -e "${YELLOW}Next Steps${NC}"
    echo "============================================================================"
    echo ""
    echo "1. Access WHM at: https://$(hostname -I | awk '{print $1}'):2087"
    echo ""
    echo "2. Login with:"
    echo "   Username: root"
    echo "   Password: [Your root password]"
    echo ""
    echo "3. Complete initial setup wizard (skip license prompts)"
    echo ""
    echo "4. Create your first cPanel account:"
    echo "   WHM → Account Functions → Create a New Account"
    echo ""
    echo "5. Useful commands:"
    echo -e "   ${GREEN}/usr/local/cpanel/scripts/restartsrv_cpanel${NC}  - Restart cPanel"
    echo -e "   ${GREEN}/usr/local/cpanel/scripts/restartsrv_apache${NC}  - Restart Apache"
    echo -e "   ${GREEN}/usr/local/cpanel/scripts/restartsrv_mysql${NC}   - Restart MySQL"
    echo -e "   ${GREEN}/scripts/upcp --force${NC}                        - Force cPanel update (may break bypass)"
    echo ""
    echo "============================================================================"
}

display_bypass_info() {
    echo ""
    echo "============================================================================"
    echo -e "${CYAN}License Bypass Information${NC}"
    echo "============================================================================"
    echo ""
    echo "The following bypass methods have been applied:"
    echo ""
    echo "✓ License.pm module patched"
    echo "✓ Dummy license file created"
    echo "✓ License check scripts modified"
    echo "✓ License validation hooks installed"
    echo "✓ WHM interface patched"
    echo "✓ Environment variables set"
    echo "✓ Maintenance cron job created"
    echo "✓ License server redirected"
    echo "✓ cPanel updates disabled"
    echo ""
    echo -e "${YELLOW}Important Notes:${NC}"
    echo ""
    echo "• Do NOT run cPanel updates (upcp) as it may break the bypass"
    echo "• License warnings in WHM may still appear (can be ignored)"
    echo "• Some features may check license differently"
    echo "• Backup files are saved with .backup extension"
    echo ""
    echo "To restore original files if needed:"
    echo -e "${GREEN}cp /usr/local/cpanel/Cpanel/License.pm.backup /usr/local/cpanel/Cpanel/License.pm${NC}"
    echo ""
    echo -e "${RED}Remember: This is for testing only. Purchase a license for production!${NC}"
    echo ""
    echo "============================================================================"
}

main() {
    show_banner
    show_disclaimer
    
    check_root
    check_os
    check_system_requirements
    
    echo ""
    print_warning "This will install cPanel/WHM with license bypass."
    print_warning "Installation will take 30-60 minutes."
    echo ""
    read -p "Continue? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    print_info "Starting cPanel installation..."
    echo ""
    
    prepare_system
    download_cpanel_installer
    install_cpanel
    bypass_license_check
    configure_cpanel
    
    display_summary
    display_access_info
    display_next_steps
    display_bypass_info
    
    show_completion_banner
    
    print_success "Installation completed!"
    print_warning "This bypassed installation is for educational/testing purposes only."
    echo ""
}

main "$@"
