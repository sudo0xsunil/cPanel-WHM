#!/bin/bash

###############################################################################
# CloudLinux Shared OS Pro Installation Script
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

LOG_FILE="/var/log/cloudlinux_installation_$(date +%Y%m%d_%H%M%S).log"

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
    echo "║          CloudLinux Shared OS Pro Installation Script                 ║"
    echo "║                                                                        ║"
    echo "║                    Developed by: Sunil Kumar                          ║"
    echo "║                    Instagram: @sudo0xsunil                            ║"
    echo "║                                                                        ║"
    echo "║         Professional Server Management & Automation Solutions         ║"
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
    echo "║              ✓ CloudLinux Installation Completed Successfully!        ║"
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
    
    if [[ "$ID" != "rocky" && "$ID" != "almalinux" && "$ID" != "centos" ]]; then
        print_error "Unsupported OS: $ID"
        print_error "This script supports Rocky Linux, AlmaLinux, and CentOS only"
        exit 1
    fi
    
    if [[ ! "$VERSION_ID" =~ ^9\. ]]; then
        print_error "Unsupported version: $VERSION_ID"
        print_error "This script supports version 9.x only"
        exit 1
    fi
    
    print_success "OS Check: $PRETTY_NAME - Compatible"
}

check_cpanel() {
    print_info "Checking for cPanel installation..."
    
    if [[ ! -f /usr/local/cpanel/cpanel ]]; then
        print_warning "cPanel not detected. CloudLinux works best with cPanel."
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled by user"
            exit 0
        fi
    else
        print_success "cPanel detected"
    fi
}

create_backup() {
    print_info "Creating backup of system files..."
    
    BACKUP_DIR="/root/cloudlinux_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    [[ -f /etc/redhat-release ]] && cp /etc/redhat-release "$BACKUP_DIR/"
    [[ -f /etc/os-release ]] && cp /etc/os-release "$BACKUP_DIR/"
    [[ -f /etc/default/grub ]] && cp /etc/default/grub "$BACKUP_DIR/"
    
    print_success "Backup created at: $BACKUP_DIR"
}

download_cldeploy() {
    print_info "Downloading CloudLinux deployment script..."
    
    cd /root || exit 1
    
    if [[ -f cldeploy ]]; then
        print_warning "cldeploy already exists, removing old version..."
        rm -f cldeploy
    fi
    
    wget -q https://repo.cloudlinux.com/cloudlinux/sources/cln/cldeploy
    
    if [[ ! -f cldeploy ]]; then
        print_error "Failed to download cldeploy script"
        exit 1
    fi
    
    chmod +x cldeploy
    print_success "cldeploy script downloaded successfully"
}

convert_to_cloudlinux() {
    print_info "Converting system to CloudLinux..."
    print_warning "This process may take 10-20 minutes..."
    
    if [[ -n "$ACTIVATION_KEY" ]]; then
        print_info "Using activation key for conversion..."
        sh cldeploy -k "$ACTIVATION_KEY" -y 2>&1 | tee -a "$LOG_FILE"
    else
        print_info "Converting without license registration..."
        sh cldeploy -i --skip-registration --unregistered-core-packages -y 2>&1 | tee -a "$LOG_FILE"
    fi
    
    if [[ $? -ne 0 ]]; then
        print_error "CloudLinux conversion failed"
        print_info "Check log file: $LOG_FILE"
        exit 1
    fi
    
    print_success "System converted to CloudLinux"
}

install_lve_components() {
    print_info "Installing LVE components..."
    
    yum clean all
    yum makecache
    
    print_info "Installing lve, lve-utils, lve-stats, kmod-lve, liblve, pam_lve..."
    yum install -y lve lve-utils lve-stats kmod-lve liblve pam_lve 2>&1 | tee -a "$LOG_FILE"
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to install LVE components"
        exit 1
    fi
    
    print_success "LVE components installed successfully"
}

install_lve_manager() {
    print_info "Installing CloudLinux LVE Manager..."
    
    yum install -y lvemanager 2>&1 | tee -a "$LOG_FILE"
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to install LVE Manager"
        exit 1
    fi
    
    print_success "LVE Manager installed successfully"
}

set_default_kernel() {
    print_info "Configuring boot kernel..."
    
    LATEST_KERNEL=$(grubby --info=ALL | grep -E "^kernel=" | grep -v "rescue" | grep -v "lts" | head -1 | cut -d'"' -f2)
    
    if [[ -z "$LATEST_KERNEL" ]]; then
        print_warning "Could not determine latest CloudLinux kernel"
        print_info "Using default boot configuration"
        return
    fi
    
    print_info "Setting default kernel: $LATEST_KERNEL"
    grubby --set-default="$LATEST_KERNEL"
    
    DEFAULT_KERNEL=$(grubby --default-kernel)
    print_success "Default kernel set to: $DEFAULT_KERNEL"
}

configure_grub() {
    print_info "Checking GRUB configuration for LVE compatibility..."
    
    if grep -q "systemd.unified_cgroup_hierarchy=1" /etc/default/grub; then
        print_warning "Found incompatible cgroup setting in GRUB"
        print_info "Removing systemd.unified_cgroup_hierarchy=1..."
        
        cp /etc/default/grub /etc/default/grub.backup
        
        sed -i 's/systemd\.unified_cgroup_hierarchy=1//g' /etc/default/grub
        
        if [[ -d /sys/firmware/efi ]]; then
            print_info "System uses UEFI, updating grub2-efi.cfg..."
            grub2-mkconfig -o /boot/efi/EFI/rocky/grub.cfg 2>&1 | tee -a "$LOG_FILE"
        else
            print_info "System uses BIOS, updating grub2.cfg..."
            grub2-mkconfig -o /boot/grub2/grub.cfg 2>&1 | tee -a "$LOG_FILE"
        fi
        
        print_success "GRUB configuration updated"
    else
        print_success "GRUB configuration is compatible"
    fi
}

display_summary() {
    echo ""
    echo "============================================================================"
    echo -e "${GREEN}CloudLinux Shared OS Pro Installation Summary${NC}"
    echo "============================================================================"
    
    if [[ -f /etc/redhat-release ]]; then
        CL_VERSION=$(cat /etc/redhat-release)
        echo -e "${BLUE}OS Version:${NC} $CL_VERSION"
    fi
    
    echo ""
    echo -e "${BLUE}Installed Components:${NC}"
    rpm -qa | grep -E "^lve|^cloudlinux-release|^lvemanager|^kmod-lve" | sort | sed 's/^/  - /'
    
    echo ""
    echo -e "${BLUE}Installation Log:${NC} $LOG_FILE"
    echo -e "${BLUE}Backup Directory:${NC} $BACKUP_DIR"
    
    echo ""
    echo "============================================================================"
}

display_next_steps() {
    echo ""
    echo "============================================================================"
    echo -e "${YELLOW}IMPORTANT: Next Steps${NC}"
    echo "============================================================================"
    echo ""
    echo "1. REBOOT THE SERVER to load the CloudLinux kernel:"
    echo -e "   ${GREEN}reboot${NC}"
    echo ""
    echo "2. After reboot, verify LVE is working:"
    echo -e "   ${GREEN}lvectl start${NC}"
    echo -e "   ${GREEN}lvectl list${NC}"
    echo ""
    echo "3. If you need to activate your license later:"
    echo -e "   ${GREEN}rhnreg_ks --activationkey=YOUR-LICENSE-KEY${NC}"
    echo ""
    echo "4. Access CloudLinux LVE Manager in WHM:"
    echo "   - Login to WHM"
    echo "   - Look for 'CloudLinux LVE Manager' in the sidebar"
    echo ""
    echo "5. Optional: Enable CageFS for additional security:"
    echo -e "   ${GREEN}/usr/sbin/cagefsctl --init${NC}"
    echo -e "   ${GREEN}/usr/sbin/cagefsctl --enable-all${NC}"
    echo ""
    echo "============================================================================"
    echo ""
}

prompt_reboot() {
    echo ""
    read -p "Would you like to reboot now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Rebooting system in 5 seconds..."
        sleep 5
        reboot
    else
        print_warning "Please remember to reboot manually to complete the installation"
    fi
}

main() {
    show_banner
    
    check_root
    check_os
    check_cpanel
    
    echo ""
    echo "You can install CloudLinux with or without an activation key."
    echo "If you don't have one yet, you can activate the license later."
    echo ""
    read -p "Do you have a CloudLinux activation key? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -n "Enter your activation key: "
        read ACTIVATION_KEY
        print_info "Will use activation key for installation"
    else
        ACTIVATION_KEY=""
        print_info "Will install without license (can be activated later)"
    fi
    
    echo ""
    print_warning "This will convert your system to CloudLinux OS."
    read -p "Continue with installation? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled by user"
        exit 0
    fi
    
    echo ""
    print_info "Starting CloudLinux installation..."
    echo ""
    
    create_backup
    download_cldeploy
    convert_to_cloudlinux
    install_lve_components
    install_lve_manager
    set_default_kernel
    configure_grub
    
    display_summary
    display_next_steps
    
    show_completion_banner
    
    prompt_reboot
}

main "$@"
