#!/bin/bash
###############################################################################
# LiteSpeed Enterprise Installation Script for cPanel/WHM (Full Activation)
# Author: Adapted for Educational Purposes
# Version: 1.1
# PURPOSE: EDUCATIONAL/TESTING ONLY - Uses Official License or Trial
###############################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
LOG_FILE="/var/log/litespeed_installation_$(date +%Y%m%d_%H%M%S).log"

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
    echo "║     LiteSpeed Enterprise Installation Script for cPanel/WHM            ║"
    echo "║                              (Full Activation)                        ║"
    echo "║                                                                        ║"
    echo "║                     For Educational/Testing Purposes Only              ║"
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
    echo "║               ✓ LiteSpeed Installation Completed Successfully!         ║"
    echo "║                                                                        ║"
    echo "║                   License Activated for Testing/Production             ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

show_disclaimer() {
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                           ⚠️ IMPORTANT DISCLAIMER ⚠️                  ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This script installs LiteSpeed Enterprise using your provided license key or falls back to the official 15-day trial.${NC}"
    echo ""
    echo "By continuing, you acknowledge that:"
    echo ""
    echo "• Enter a valid license key for full, unlimited activation"
    echo "• Trial is limited to 15 days per IP; for longer testing/production, purchase a license"
    echo "• Ensure your server meets prerequisites (cPanel installed, root access, >2GB RAM)"
    echo "• Backup your server before running"
    echo "• No support provided; for issues, contact LiteSpeed support"
    echo ""
    echo -e "${CYAN}LiteSpeed licenses available at: https://store.litespeedtech.com/store${NC}"
    echo ""
    echo -e "${RED}THE AUTHOR IS NOT RESPONSIBLE FOR ANY MISUSE OR ISSUES${NC}"
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

check_cpanel() {
    print_info "Checking if cPanel/WHM is installed..."
    if [[ ! -f /usr/local/cpanel/cpanel ]]; then
        print_error "cPanel/WHM not detected. Please install cPanel first."
        exit 1
    fi
    print_success "cPanel/WHM detected"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
   
    # Check RAM (LiteSpeed requires >2GB for full features)
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $TOTAL_RAM -lt 2048 ]]; then
        print_error "Insufficient RAM: ${TOTAL_RAM}MB (LiteSpeed requires >2GB)"
        exit 1
    else
        print_success "RAM: ${TOTAL_RAM}MB - Sufficient"
    fi
   
    # Check if LiteSpeed is already installed
    if [[ -d /usr/local/lsws ]]; then
        print_error "LiteSpeed appears to be already installed. Remove it before reinstalling."
        exit 1
    fi
   
    # Disable mod_ruid2 (incompatible with LiteSpeed)
    print_info "Disabling mod_ruid2..."
    /usr/local/cpanel/scripts/update_local_rpm_versions --edit target_settings.ruid2 --value none 2>/dev/null
    print_success "mod_ruid2 disabled"
}

prepare_system() {
    print_info "Preparing system..."
   
    # Update system
    yum update -y 2>&1 | tee -a "$LOG_FILE"
   
    # Install dependencies
    yum install -y curl wget python3 2>&1 | tee -a "$LOG_FILE"
   
    print_success "System prepared"
}

prompt_config() {
    echo ""
    print_info "Configuring LiteSpeed settings..."
    echo ""
   
    # Prompt for admin email
    read -p "Enter admin email (default: root@localhost): " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-"root@localhost"}
   
    # Generate random admin password
    ADMIN_PASS=$(openssl rand -base64 12)
    echo -e "${YELLOW}Generated Admin Password: ${CYAN}${ADMIN_PASS}${NC}"
    echo "Save this password securely for LiteSpeed WebAdmin Console access."
    echo ""
   
    # Prompt for license serial
    read -p "Enter LiteSpeed Enterprise serial number for full activation (leave blank for 15-day trial): " SERIAL_NO
    if [[ -z "$SERIAL_NO" ]]; then
        TRIAL_MODE=1
        print_warning "No serial provided. Installing with 15-day trial license."
        echo -e "${YELLOW}For unlimited access over months, purchase at https://store.litespeedtech.com/store${NC}"
    else
        TRIAL_MODE=0
        print_success "Full license serial provided."
    fi
   
    # Confirm direct replacement
    read -p "Do you want to fully activate LiteSpeed (replace Apache directly)? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        PORT_OFFSET=0
        AUTO_SWITCH=1
        print_warning "LiteSpeed will replace Apache directly. Ensure backups are in place!"
    else
        PORT_OFFSET=1000
        AUTO_SWITCH=0
        print_info "LiteSpeed will run in parallel with Apache."
    fi
}

create_lsws_options() {
    local admin_user="admin"
   
    cat > /root/lsws.options << EOF
php_suexec="2"
port_offset="${PORT_OFFSET}"
admin_user="${admin_user}"
admin_pass="${ADMIN_PASS}"
admin_email="${ADMIN_EMAIL}"
easyapache_integration="1"
auto_switch_to_lsws="${AUTO_SWITCH}"
deploy_lscwp="0"
cpanel_plugin_autoinstall="1"
serial_no="${SERIAL_NO:-TRIAL}"
EOF
   
    print_success "lsws.options created at /root/lsws.options"
}

install_litespeed() {
    print_info "Installing LiteSpeed Enterprise..."
    print_warning "This process may take 10-20 minutes. Do not interrupt."
    echo ""
   
    if [[ $TRIAL_MODE -eq 1 ]]; then
        bash <(curl https://get.litespeed.sh) TRIAL < /root/lsws.options 2>&1 | tee -a "$LOG_FILE"
    else
        bash <(curl https://get.litespeed.sh) < /root/lsws.options 2>&1 | tee -a "$LOG_FILE"
    fi
   
    if [[ $? -ne 0 ]]; then
        print_error "LiteSpeed installation failed. Check log: $LOG_FILE"
        exit 1
    fi
   
    print_success "LiteSpeed installed successfully"
   
    # Clean up
    rm -f /root/lsws.options
}

configure_litespeed() {
    print_info "Configuring LiteSpeed..."
   
    # Restart/Start services
    if [[ $AUTO_SWITCH -eq 1 ]]; then
        print_info "Restarting LiteSpeed (active as main server)..."
        /usr/local/lsws/bin/lswsctrl restart 2>&1 | tee -a "$LOG_FILE"
    else
        print_info "Starting LiteSpeed in parallel mode..."
        /usr/local/lsws/bin/lswsctrl start 2>&1 | tee -a "$LOG_FILE"
    fi
   
    # Re-register license if full
    if [[ $TRIAL_MODE -eq 0 ]]; then
        print_info "Re-registering full license..."
        /usr/local/lsws/bin/lshttpd -r 2>&1 | tee -a "$LOG_FILE"
        /usr/local/lsws/bin/lswsctrl restart 2>&1 | tee -a "$LOG_FILE"
    fi
   
    print_success "LiteSpeed configured"
}

display_summary() {
    echo ""
    echo "============================================================================"
    echo -e "${GREEN}LiteSpeed Installation Summary${NC}"
    echo "============================================================================"
   
    # LiteSpeed version
    if [[ -f /usr/local/lsws/admin/misc/lshttpd ]]; then
        LS_VERSION=$(/usr/local/lsws/admin/misc/lshttpd -v 2>&1 | head -n1 | awk '{print $3}')
        echo -e "${BLUE}LiteSpeed Version:${NC} $LS_VERSION"
    fi
   
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "${BLUE}Server IP:${NC} $SERVER_IP"
   
    if [[ $PORT_OFFSET -eq 0 ]]; then
        echo -e "${BLUE}Web Port:${NC} 80 (HTTP), 443 (HTTPS) - LiteSpeed Active"
    else
        echo -e "${BLUE}Web Port:${NC} 80/443 (Apache), ${PORT_OFFSET}80/${PORT_OFFSET}443 (LiteSpeed)"
    fi
   
    echo -e "${BLUE}WebAdmin Console:${NC} https://${SERVER_IP}:7080"
    echo -e "${BLUE}Admin Username:${NC} admin"
    echo -e "${BLUE}Admin Password:${NC} ${ADMIN_PASS}"
    echo -e "${BLUE}Admin Email:${NC} ${ADMIN_EMAIL}"
   
    if [[ $TRIAL_MODE -eq 1 ]]; then
        echo -e "${YELLOW}License Type:${NC} 15-Day Trial"
    else
        echo -e "${GREEN}License Type:${NC} Full Enterprise"
    fi
   
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
   
    echo -e "${GREEN}WHM LiteSpeed Manager:${NC}"
    echo -e " URL: ${CYAN}https://$SERVER_IP:2087${NC} → Plugins → LiteSpeed Manager"
    echo -e " Username: ${CYAN}root${NC}"
    echo -e " Password: [Your root password]"
    echo ""
   
    echo -e "${GREEN}LiteSpeed WebAdmin Console:${NC}"
    echo -e " URL: ${CYAN}https://$SERVER_IP:7080${NC}"
    echo -e " Username: ${CYAN}admin${NC}"
    echo -e " Password: ${CYAN}${ADMIN_PASS}${NC}"
    echo ""
   
    if [[ $PORT_OFFSET -ne 0 ]]; then
        echo -e "${YELLOW}To fully activate (replace Apache):${NC}"
        echo "1. Edit /usr/local/lsws/conf/httpd_config.conf: Set listener ports to 80/443"
        echo "2. Run: /usr/local/lsws/bin/lswsctrl restart"
        echo "3. In WHM: Service Manager → Stop Apache"
        echo ""
    fi
   
    echo "============================================================================"
}

display_next_steps() {
    echo ""
    echo "============================================================================"
    echo -e "${YELLOW}Next Steps${NC}"
    echo "============================================================================"
    echo ""
    echo "1. Access WHM → Plugins → LiteSpeed Manager to configure"
    echo ""
    echo "2. Test sites: Visit domains to verify LiteSpeed serving"
    echo ""
    if [[ $TRIAL_MODE -eq 1 ]]; then
        echo "3. Trial expires in 15 days. For months-long testing/full features:"
        echo "   - Purchase license: https://store.litespeedtech.com/store"
        echo "   - Rerun script with serial number for upgrade"
    else
        echo "3. Full license activated - enjoy unlimited use!"
    fi
    echo ""
    echo "4. Useful commands:"
    echo -e " ${GREEN}/usr/local/lsws/bin/lswsctrl status${NC} - Check status"
    echo -e " ${GREEN}/usr/local/lsws/bin/lswsctrl restart${NC} - Restart"
    echo -e " ${GREEN}/usr/local/lsws/bin/lshttpd -r${NC} - Re-register license"
    echo ""
    echo "============================================================================"
}

main() {
    show_banner
    show_disclaimer
   
    check_root
    check_cpanel
    check_prerequisites
   
    echo ""
    print_warning "This will install LiteSpeed Enterprise (full if serial provided, else trial)."
    print_warning "Ensure ports 80, 443, 7080 are open in firewall."
    echo ""
    read -p "Continue? (y/n): " -n 1 -r
    echo
   
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
   
    echo ""
    print_info "Starting LiteSpeed installation..."
    echo ""
   
    prepare_system
    prompt_config
    create_lsws_options
    install_litespeed
    configure_litespeed
   
    display_summary
    display_access_info
    display_next_steps
   
    show_completion_banner
   
    if [[ $TRIAL_MODE -eq 1 ]]; then
        print_warning "Trial mode active. For full long-term testing, obtain a license key and rerun."
    else
        print_success "Full activation complete!"
    fi
    echo ""
}
main "$@"
