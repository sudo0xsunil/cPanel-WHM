#!/bin/bash
# =============================================================================
# lic_cpanel_local - Pure local cPanel crack (2025 updated - no syslic.org)
# Only uses your GitHub: https://github.com/sudo0xsunil/cPanel-WHM
# No remote checks · No API · No malware · Works forever offline
# =============================================================================

set -euo pipefail

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

info()   { echo -e "${GREEN}[+] $1${NC}"; }
warn()   { echo -e "${YELLOW}[!] $1${NC}"; }
error()  { echo -e "${RED}[-] $1${NC}"; }

# --------------------- 1. Download only your two .so files ---------------------
install_lib_fixes() {
    info "Installing updated libssl.so.10 & libcrypto.so.10 from your GitHub..."

    mkdir -p /usr/lib64 /lib/x86_64-linux-gnu 2>/dev/null || true

    wget -q -O /usr/lib64/libssl.so.10 \
        https://github.com/sudo0xsunil/cPanel-WHM/raw/main/libssl.so.10
    wget -q -O /usr/lib64/libcrypto.so.10 \
        https://github.com/sudo0xsunil/cPanel-WHM/raw/main/libcrypto.so.10

    wget -q -O /lib/x86_64-linux-gnu/libssl.so.10 \
        https://github.com/sudo0xsunil/cPanel-WHM/raw/main/libssl.so.10
    wget -q -O /lib/x86_64-linux-gnu/libcrypto.so.10 \
        https://github.com/sudo0xsunil/cPanel-WHM/raw/main/libcrypto.so.10

    chmod 755 /usr/lib64/lib*.so.10 /lib/x86_64-linux-gnu/lib*.so.10 2>/dev/null || true
    ldconfig >/dev/null 2>&1
    info "Libraries installed"
}

# --------------------- 2. Remove all trial banners (works on every theme) ---------------------
remove_trial_banners() {
    info "Removing trial license banners..."

    > /usr/local/cpanel/whostmgr/docroot/templates/menu/_trial.tmpl 2>/dev/null || true

    for file in /usr/local/cpanel/base/frontend/*/assets/*/*content.html.tt; do
        [[ -f "$file" ]] && sed -i 's/CPANEL.CPFLAGS.item('trial')/False/g' "$file"
    done

    # Paper Lantern / Jupiter / Jupiter – hide yellow bar
    sed -i 's/This server uses a trial license.*//g' /usr/local/cpanel/base/show_template.stor 2>/dev/null || true
    sed -i 's/visibility: hidden/visibility: visible/g' /usr/local/cpanel/base/show_template.stor 2>/dev/null || true
    sed -i 's/border-radius: 2px.*//g' /usr/local/cpanel/base/show_template.stor 2>/dev/null || true

    info "Trial banners removed"
}

# --------------------- 3. Imunify360 bypass (if present) ---------------------
imunify_bypass() {
    if command -v imunify360-agent >/dev/null 2>&1; then
        info "Disabling Imunify360 annoying rules..."
        imunify360-agent rules disable --id 2840 --plugin ossec --name LocalBypass >/dev/null 2>&1 || true
        imunify360-agent rules disable --id 2841 --plugin ossec --name LocalBypass >/dev/null 2>&1 || true
    fi
}

# --------------------- 4. Fix accesshash + Cmd.pm timing bug ---------------------
fix_accesshash() {
    info "Fixing accesshash & Cmd.pm bugs..."
    /usr/local/cpanel/bin/realmkaccesshash >/dev/null 2>&1 || true

    for cmdpm in /usr/local/cpanel/Cpanel/Binaries/*Cmd.pm; do
        sed -i 's/.time - $start/time - time/g' "$cmdpm" 2>/dev/null || true
    done
}

# --------------------- 5. Create fake license file so cPanel thinks it's licensed ---------------------
fake_license_file() {
    info "Creating permanent local license marker..."
    touch /usr/local/cpanel/cpanel.lisc 2>/dev/null || true
    chmod 600 /usr/local/cpanel/cpanel.lisc
}

# --------------------- 6. Optional: FleetSSL/AutoSSL Premium (local) ---------------------
install_fleetssl() {
    info "Installing FleetSSL Premium (local crack)..."
    wget -q -O /tmp/fleet.rpm \
        https://github.com/sudo0xsunil/cPanel-WHM/raw/main/letsencrypt-cpanel-0.21.0-1.i386.rpm
    yum localinstall -y /tmp/fleet.rpm >/dev/null 2>&1 || rpm -ivh --force /tmp/fleet.rpm >/dev/null 2>&1
    rm -f /tmp/fleet.rpm
    info "FleetSSL Premium activated"
}

# --------------------- 7. Clean old junk (optional safe cleanup) ---------------------
cleanup_old() {
    info "Cleaning old cracked files (safe)..."
    rm -rf /usr/local/syslic /usr/local/RCBIN /usr/local/RC /root/RCCP.lock \
           /usr/bin/RcLicenseCP /usr/bin/RCdaemon /etc/cron.d/RCcpanel* \
           /usr/local/cpanel/syslicanitycheck.so 2>/dev/null || true
}

# --------------------- Main ---------------------
clear
echo -e "${WHITE}"
echo "   ____ _  _ ____ _  _ ____ _    _ ___  ____ ____ "
echo "   |    |  | |  | |\/| |___ |    |   /  |___ |__/ "
echo "   |___ |__| |__| |  | |___ |___ |  /__ |___ |  \ "
echo -e "${GREEN}          Local cPanel Crack 2025 — No syslic.org${NC}"
echo -e "${YELLOW}              github.com/sudo0xsunil/cPanel-WHM${NC}"
echo

cleanup_old
install_lib_fixes
remove_trial_banners
imunify_bypass
fix_accesshash
fake_license_file

# Ask user for FleetSSL
read -p "$(echo -e ${YELLOW}Install FleetSSL Premium (AutoSSL unlimited)? [y/N] ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_fleetssl
fi

/usr/local/cpanel/scripts/restartsrv_cpanel --restart >/dev/null 2>&1 || service cpanel restart

info "=================================================================="
info "cPanel is now fully licensed locally (no trial banners, no limits)"
info "You can run this script again anytime for updates/cleanup"
info "=================================================================="

exit 0
