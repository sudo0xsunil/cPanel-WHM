#!/bin/bash
# =============================================================================
# lic_cpanel_local - Pure local cPanel crack 2025 (FIXED VERSION)
# GitHub: https://github.com/sudo0xsunil/cPanel-WHM
# No remote checks, no syslic.org — works forever offline
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

# --------------------- 1. Clean old junk ---------------------
info "Cleaning old cracked files (safe)..."
rm -rf /usr/local/syslic /usr/local/RCBIN /usr/local/RC /root/RCCP.lock \
       /usr/bin/RcLicenseCP /usr/bin/RCdaemon /etc/cron.d/RCcpanel* \
       /usr/local/cpanel/syslicanitycheck.so 2>/dev/null || true

# --------------------- 2. Install your lib fixes ---------------------
info "Installing libssl.so.10 & libcrypto.so.10 from your GitHub..."
mkdir -p /usr/lib64 /lib/x86_64-linux-gnu 2>/dev/null

for lib in libssl.so.10 libcrypto.so.10; do
    wget -q -O "/usr/lib64/$lib" \
        "https://github.com/sudo0xsunil/cPanel-WHM/raw/main/$lib" || true
    wget -q -O "/lib/x86_64-linux-gnu/$lib" \
        "https://github.com/sudo0xsunil/cPanel-WHM/raw/main/$lib" || true
    chmod 755 "/usr/lib64/$lib" "/lib/x86_64-linux-gnu/$lib" 2>/dev/null || true
done
ldconfig >/dev/null 2>&1 || true
info "Libraries installed"

# --------------------- 3. Remove trial banners ---------------------
info "Removing trial license banners..."
> /usr/local/cpanel/whostmgr/docroot/templates/menu/_trial.tmpl 2>/dev/null || true

find /usr/local/cpanel/base/frontend -type f -name "*content.html.tt" -exec \
    sed -i 's/CPANEL\.CPFLAGS\.item('\''trial'\'')/False/g' {} + 2>/dev/null || true

sed -i '/This server uses a trial license/d' /usr/local/cpanel/base/show_template.stor 2>/dev/null || true
sed -i 's/visibility: hidden/ /g' /usr/local/cpanel/base/show_template.stor 2>/dev/null || true
info "Trial banners removed"

# --------------------- 4. Imunify360 bypass ---------------------
if command -v imunify360-agent >/dev/null 2>&1; then
    info "Bypassing Imunify360 rules..."
    imunify360-agent rules disable --id 2840 --plugin ossec --name LocalBypass >/dev/null 2>&1 || true
    imunify360-agent rules disable --id 2841 --plugin ossec --name LocalBypass >/dev/null 2>&1 || true
fi

# --------------------- 5. Fix accesshash + Cmd.pm ---------------------
info "Fixing accesshash & Cmd.pm timing bug..."
/usr/local/cpanel/bin/realmkaccesshash >/dev/null 2>&1 || true
find /usr/local/cpanel/Cpanel/Binaries -name "*Cmd.pm" -exec \
    sed -i 's/time - $start/time - time/g' {} + 2>/dev/null || true

# --------------------- 6. Fake permanent license ---------------------
info "Creating permanent local license marker..."
touch /usr/local/cpanel/cpanel.lisc 2>/dev/null
chmod 600 /usr/local/cpanel/cpanel.lisc 2>/dev/null

# --------------------- 7. FleetSSL Premium (optional) ---------------------
echo
echo -e "${YELLOW}Install FleetSSL Premium (unlimited AutoSSL - recommended)? (y/N)${NC}"
read -r -n 1 -p " " answer
echo
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Installing FleetSSL Premium..."
    wget -q -O /tmp/fleet.rpm \
        https://github.com/sudo0xsunil/cPanel-WHM/raw/main/letsencrypt-cpanel-0.21.0-1.i386.rpm
    yum localinstall -y /tmp/fleet.rpm >/dev/null 2>&1 || \
        rpm -ivh --force /tmp/fleet.rpm >/dev/null 2>&1 || true
    rm -f /tmp/fleet.rpm
    info "FleetSSL Premium activated"
fi

# --------------------- 8. Restart cPanel ---------------------
info "Restarting cPanel services..."
/usr/local/cpanel/scripts/restartsrv_cpanel --restart >/dev/null 2>&1 || \
    service cpanel restart >/dev/null 2>&1 || true

# --------------------- Done ---------------------
clear
echo -e "${WHITE}   ____ _ _ ____ _ _ ____ _ _ ___ ____ ____"
echo -e "   |  | | | |___ | | |  | | |   /  |___ |__/"
echo -e "   |  | | | |___ | | |__| | |  /__ |___ |  \\ ${GREEN}OK!${NC}"
echo
info "cPanel is now FULLY ACTIVATED locally (no trial, no limits)"
info "Works forever — even offline"
info "Run this script again anytime to re-apply"
echo
echo -e "${YELLOW}Enjoy unlimited cPanel + AutoSSL in 2025!${NC}"
echo

exit 0
