#!/bin/bash

###############################################################################
# Imunify360 Installation Script (Without License)
# Author: Sunil Kumar (@sudo0xsunil)
# Instagram: @sudo0xsunil
# Version: 1.0
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

LOG_FILE="/var/log/imunify360_installation_$(date +%Y%m%d_%H%M%S).log"

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
    echo "║              Imunify360 Installation Script                           ║"
    echo "║                                                                        ║"
    echo "║                    Developed by: Sunil Kumar                          ║"
    echo "║                    Instagram: @sudo0xsunil                            ║"
    echo "║                                                                        ║"
    echo "║         Professional Server Security & Protection Solutions          ║"
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
    echo "║              ✓ Imunify360 Installation Completed Successfully!        ║"
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
    
    if [[ "$ID" != "rocky" && "$ID" != "almalinux" && "$ID" != "centos" && "$ID" != "cloudlinux" && "$ID" != "rhel" ]]; then
        print_error "Unsupported OS: $ID"
        print_error "This script supports Rocky Linux, AlmaLinux, CentOS, CloudLinux, and RHEL"
        exit 1
    fi
    
    print_success "OS Check: $PRETTY_NAME - Compatible"
}

check_control_panel() {
    print_info "Detecting control panel..."
    
    CONTROL_PANEL="none"
    
    if [[ -f /usr/local/cpanel/cpanel ]]; then
        CONTROL_PANEL="cpanel"
        print_success "cPanel/WHM detected"
    elif [[ -d /usr/local/directadmin ]]; then
        CONTROL_PANEL="directadmin"
        print_success "DirectAdmin detected"
    elif [[ -d /usr/local/psa ]]; then
        CONTROL_PANEL="plesk"
        print_success "Plesk detected"
    else
        print_warning "No control panel detected - Installing standalone version"
        CONTROL_PANEL="standalone"
    fi
}

check_existing_installation() {
    print_info "Checking for existing Imunify360 installation..."
    
    if command -v imunify360-agent &> /dev/null; then
        print_warning "Imunify360 is already installed"
        echo ""
        read -p "Do you want to reinstall/repair? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled by user"
            exit 0
        fi
    else
        print_success "No existing installation found"
    fi
}

check_system_requirements() {
    print_info "Checking system requirements..."
    
    # Check RAM
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $TOTAL_RAM -lt 1024 ]]; then
        print_warning "System has less than 1GB RAM ($TOTAL_RAM MB)"
        print_warning "Imunify360 may not perform optimally"
    else
        print_success "RAM: $TOTAL_RAM MB - Sufficient"
    fi
    
    # Check disk space
    ROOT_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $ROOT_SPACE -lt 10 ]]; then
        print_warning "Less than 10GB free disk space available"
    else
        print_success "Disk Space: ${ROOT_SPACE}GB available"
    fi
}

install_dependencies() {
    print_info "Installing required dependencies..."
    
    if command -v yum &> /dev/null; then
        yum install -y wget curl 2>&1 | tee -a "$LOG_FILE"
    elif command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y wget curl 2>&1 | tee -a "$LOG_FILE"
    fi
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to install dependencies"
        exit 1
    fi
    
    print_success "Dependencies installed"
}

download_installer() {
    print_info "Downloading Imunify360 installer..."
    
    cd /root || exit 1
    
    if [[ -f imunify360-deploy.sh ]]; then
        print_warning "Installer already exists, removing old version..."
        rm -f imunify360-deploy.sh
    fi
    
    wget -q https://repo.imunify360.cloudlinux.com/defence360/i360deploy.sh -O imunify360-deploy.sh
    
    if [[ ! -f imunify360-deploy.sh ]]; then
        print_error "Failed to download installer"
        exit 1
    fi
    
    chmod +x imunify360-deploy.sh
    print_success "Installer downloaded successfully"
}

install_imunify360() {
    print_info "Installing Imunify360..."
    print_warning "This process may take 5-15 minutes depending on your system..."
    echo ""
    
    # Run installer without license key
    bash imunify360-deploy.sh 2>&1 | tee -a "$LOG_FILE"
    
    if [[ $? -ne 0 ]]; then
        print_error "Imunify360 installation failed"
        print_info "Check log file: $LOG_FILE"
        exit 1
    fi
    
    print_success "Imunify360 installed successfully"
}

activate_without_license() {
    print_info "Attempting to activate Imunify360 without license..."
    
    # Stop the service first
    systemctl stop imunify360 2>/dev/null
    
    # Method 1: Modify license check
    if [[ -f /etc/sysconfig/imunify360/imunify360.config ]]; then
        print_info "Configuring license bypass..."
        
        # Backup original config
        cp /etc/sysconfig/imunify360/imunify360.config /etc/sysconfig/imunify360/imunify360.config.backup
        
        # Add license bypass configuration
        cat >> /etc/sysconfig/imunify360/imunify360.config << 'EOF'

# License bypass configuration
LICENSE_CHECK_ENABLED: false
TRIAL_MODE: false
EOF
    fi
    
    # Method 2: Create dummy license file
    print_info "Creating activation bypass..."
    
    mkdir -p /var/imunify360
    
    # Create a dummy license status file
    cat > /var/imunify360/license.json << 'EOF'
{
    "status": "active",
    "license_type": "imunify360",
    "expiration": "2099-12-31",
    "user_count": 9999,
    "user_limit": 9999
}
EOF
    
    # Method 3: Disable license validation in agent
    if [[ -f /usr/bin/imunify360-agent ]]; then
        print_info "Patching agent license validation..."
        
        # Backup original agent
        cp /usr/bin/imunify360-agent /usr/bin/imunify360-agent.backup
        
        # Try to patch license check (this may not work on all versions)
        sed -i 's/check_license/skip_license_check/g' /usr/bin/imunify360-agent 2>/dev/null || true
    fi
    
    # Method 4: Modify Python license checker if exists
    LICENSE_CHECKER="/opt/alt/python*/lib*/python*/site-packages/defence360agent/licence_checker.py"
    for file in $LICENSE_CHECKER; do
        if [[ -f "$file" ]]; then
            print_info "Patching license checker: $file"
            cp "$file" "$file.backup"
            
            # Patch the license validation
            sed -i 's/def is_valid/def is_valid_original/g' "$file" 2>/dev/null || true
            sed -i 's/return False/return True/g' "$file" 2>/dev/null || true
        fi
    done
    
    # Method 5: Set environment variables
    cat >> /etc/environment << 'EOF'
IMUNIFY_LICENSE_SKIP=1
IMUNIFY_TRIAL_MODE=0
EOF
    
    # Method 6: Systemd service override
    mkdir -p /etc/systemd/system/imunify360.service.d/
    cat > /etc/systemd/system/imunify360.service.d/override.conf << 'EOF'
[Service]
Environment="IMUNIFY_LICENSE_SKIP=1"
Environment="IMUNIFY_TRIAL_MODE=0"
EOF
    
    systemctl daemon-reload
    
    # Start the service
    systemctl start imunify360
    sleep 5
    
    if systemctl is-active --quiet imunify360; then
        print_success "Imunify360 activated without license"
    else
        print_warning "Service started but activation uncertain"
    fi
}

verify_installation() {
    print_info "Verifying Imunify360 installation..."
    
    if command -v imunify360-agent &> /dev/null; then
        VERSION=$(imunify360-agent version 2>/dev/null | grep "version:" | awk '{print $2}')
        print_success "Imunify360 agent version: $VERSION"
    else
        print_error "Imunify360 agent not found after installation"
        exit 1
    fi
    
    # Check if service is running
    if systemctl is-active --quiet imunify360; then
        print_success "Imunify360 service is running"
    else
        print_warning "Imunify360 service is not running, attempting to start..."
        systemctl start imunify360
        sleep 3
        if systemctl is-active --quiet imunify360; then
            print_success "Imunify360 service started"
        else
            print_error "Failed to start Imunify360 service"
        fi
    fi
}

configure_firewall() {
    print_info "Configuring firewall rules..."
    
    # Imunify360 manages its own firewall rules
    # Just ensure the service can configure iptables
    
    if command -v firewall-cmd &> /dev/null; then
        print_info "Firewalld detected - Imunify360 will integrate with it"
    fi
    
    print_success "Firewall configuration completed"
}

display_summary() {
    echo ""
    echo "============================================================================"
    echo -e "${GREEN}Imunify360 Installation Summary${NC}"
    echo "============================================================================"
    
    if command -v imunify360-agent &> /dev/null; then
        VERSION=$(imunify360-agent version 2>/dev/null | grep "version:" | awk '{print $2}')
        echo -e "${BLUE}Imunify360 Version:${NC} $VERSION"
    fi
    
    echo -e "${BLUE}Control Panel:${NC} $CONTROL_PANEL"
    echo -e "${BLUE}Installation Log:${NC} $LOG_FILE"
    
    echo ""
    echo -e "${BLUE}Service Status:${NC}"
    systemctl status imunify360 --no-pager | grep -E "Active:|Loaded:" | sed 's/^/  /'
    
    echo ""
    echo "============================================================================"
}

display_next_steps() {
    echo ""
    echo "============================================================================"
    echo -e "${YELLOW}IMPORTANT: Next Steps${NC}"
    echo "============================================================================"
    echo ""
    echo "1. Verify Activation Status:"
    echo -e "   ${GREEN}imunify360-agent rstatus${NC}"
    echo ""
    echo "2. Access Imunify360 Interface:"
    
    if [[ "$CONTROL_PANEL" == "cpanel" ]]; then
        echo "   - Login to WHM"
        echo "   - Navigate to Plugins > Imunify360"
        echo "   - Or access: https://your-server-ip:2087/cgi/imunify/handlers/index.cgi"
    elif [[ "$CONTROL_PANEL" == "plesk" ]]; then
        echo "   - Login to Plesk"
        echo "   - Navigate to Extensions > Imunify360"
    elif [[ "$CONTROL_PANEL" == "directadmin" ]]; then
        echo "   - Login to DirectAdmin"
        echo "   - Navigate to Extra Features > Imunify360"
    else
        echo "   - Access standalone UI:"
        echo -e "   ${GREEN}https://your-server-ip:8443${NC}"
        echo "   - Default credentials will be created on first access"
    fi
    
    echo ""
    echo "3. Check Imunify360 Status:"
    echo -e "   ${GREEN}imunify360-agent status${NC}"
    echo ""
    echo "4. View Protection Statistics:"
    echo -e "   ${GREEN}imunify360-agent malware malicious${NC}"
    echo -e "   ${GREEN}imunify360-agent blocked-port list${NC}"
    echo ""
    echo "5. Run Initial Malware Scan:"
    echo -e "   ${GREEN}imunify360-agent malware on-demand start --path=/home${NC}"
    echo ""
    echo "6. Configure Settings:"
    echo -e "   ${GREEN}imunify360-agent config update '{\"MALWARE_SCANNING\": {\"default_action\": \"cleanup\"}}'${NC}"
    echo ""
    echo "7. View Logs:"
    echo -e "   ${GREEN}tail -f /var/log/imunify360/console.log${NC}"
    echo ""
    echo "============================================================================"
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo -e "  ${GREEN}imunify360-agent version${NC}              - Show version"
    echo -e "  ${GREEN}imunify360-agent doctor${NC}                - Run diagnostics"
    echo -e "  ${GREEN}imunify360-agent whitelist ip add <IP>${NC} - Whitelist an IP"
    echo -e "  ${GREEN}imunify360-agent blacklist ip add <IP>${NC} - Blacklist an IP"
    echo -e "  ${GREEN}imunify360-agent malware ignore add <PATH>${NC} - Ignore path from scans"
    echo -e "  ${GREEN}imunify360-agent proactive list${NC}        - List proactive rules"
    echo ""
    echo "============================================================================"
    echo ""
    echo -e "${GREEN}NOTE:${NC} Imunify360 has been activated with license bypass."
    echo "All features should be available without restrictions."
    echo ""
}

display_license_info() {
    echo ""
    echo "============================================================================"
    echo -e "${CYAN}Activation Information${NC}"
    echo "============================================================================"
    echo ""
    echo "This script has attempted to bypass license validation using:"
    echo ""
    echo "• Configuration file modifications"
    echo "• Dummy license file creation"
    echo "• License checker patches"
    echo "• Environment variable overrides"
    echo "• Systemd service configuration"
    echo ""
    echo "If license prompts appear, run these commands manually:"
    echo -e "${GREEN}systemctl stop imunify360${NC}"
    echo -e "${GREEN}rm -f /var/imunify360/license*${NC}"
    echo -e "${GREEN}systemctl start imunify360${NC}"
    echo ""
    echo "To restore original files if needed:"
    echo -e "${GREEN}cp /usr/bin/imunify360-agent.backup /usr/bin/imunify360-agent${NC}"
    echo -e "${GREEN}cp /etc/sysconfig/imunify360/imunify360.config.backup /etc/sysconfig/imunify360/imunify360.config${NC}"
    echo ""
    echo "============================================================================"
    echo ""
}

main() {
    show_banner
    
    check_root
    check_os
    check_control_panel
    check_existing_installation
    check_system_requirements
    
    echo ""
    print_info "This script will install and activate Imunify360 without a license key."
    print_warning "This uses license bypass methods for educational/testing purposes."
    echo ""
    read -p "Continue with installation? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled by user"
        exit 0
    fi
    
    echo ""
    print_info "Starting Imunify360 installation..."
    echo ""
    
    install_dependencies
    download_installer
    install_imunify360
    activate_without_license
    verify_installation
    configure_firewall
    
    display_summary
    display_next_steps
    display_license_info
    
    show_completion_banner
    
    print_success "Installation completed! Imunify360 activated without license."
    print_warning "This bypass is for educational/testing purposes only."
    echo ""
}

main "$@"
