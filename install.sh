#!/bin/sh
uci set system.@system[0].zonename='Asia/Tehran'
uci set system.@system[0].timezone='<+0330>-3:30'
uci set system.@system[0].hostname=AGC-Global
uci commit system

echo "
 ____                  _____         _     
/ ___| _   _ _ __   __|_   _|__  ___| |__  
\___ \| | | | '_ \ / __|| |/ _ \/ __| '_ \ 
 ___) | |_| | | | | (__ | |  __/ (__| | | |
|____/ \__, |_| |_|\___||_|\___|\___|_| |_|
       |___/                               
" > /etc/banner
set -eu

LOG_FILE="/tmp/install_log.txt"
: > "$LOG_FILE"

log() {
  printf "%s\n" "$1" | tee -a "$LOG_FILE"
}

REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/package"
FILES_ZIP_URL="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/files.zip"

IPK_LIST=$(cat <<'EOF'
0-kmod-nls-base_5.15.167-1_mipsel_24kc.ipk
1-0-kmod-usb-core_5.15.167-1_mipsel_24kc.ipk
1-1kmod-usb-ehci_5.15.167-1_mipsel_24kc.ipk
1-liblua5.1.5_5.1.5-11_mipsel_24kc.ipk
2-kmod-usb2_5.15.167-1_mipsel_24kc.ipk
2-lua_5.1.5-11_mipsel_24kc.ipk
3-kmod-mii_5.15.167-1_mipsel_24kc.ipk
3-ucode-mod-lua_1_mipsel_24kc.ipk
4-kmod-usb-net_5.15.167-1_mipsel_24kc.ipk
4-liblucihttp-lua_2023-03-15-9b5b683f-1_mipsel_24kc.ipk
5-kmod-usb-net-cdc-ether_5.15.167-1_mipsel_24kc.ipk
5-libubus-lua_2023-06-05-f787c97b-1_mipsel_24kc.ipk
6-kmod-usb-serial_5.15.167-1_mipsel_24kc.ipk
6-luci-lib-jsonc_git-25.176.69269-6e21c0e_mipsel_24kc.ipk
7-kmod-usb-serial-wwan_5.15.167-1_mipsel_24kc.ipk
7-luci-lib-ip_git-25.176.69269-6e21c0e_mipsel_24kc.ipk
8-kmod-usb-serial-option_5.15.167-1_mipsel_24kc.ipk
8-luci-lib-nixio_git-25.176.69269-6e21c0e_mipsel_24kc.ipk
9-luci-lib-base_git-25.176.69269-6e21c0e_all.ipk
9-picocom_3.1-5_mipsel_24kc.ipk
10-luci-lua-runtime_git-25.176.69269-6e21c0e_mipsel_24kc.ipk
11-luci-compat_git-25.176.69269-6e21c0e_all.ipk
unzip_6.0-8_mipsel_24kc.ipk
EOF
)

FAILED_PKGS=""
log ">>> Downloading and installing packages..."
while IFS= read -r IPK; do  
  SRC="/tmp/$IPK"
  log "-> Downloading $IPK ..."
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$SRC" "$REPO_RAW_ROOT/$IPK" || { log "[WARN] Failed to download $IPK"; FAILED_PKGS="$FAILED_PKGS $IPK"; continue; }
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_ROOT/$IPK" -o "$SRC" || { log "[WARN] Failed to download $IPK"; FAILED_PKGS="$FAILED_PKGS $IPK"; continue; }
  else
    log "[ERROR] Neither wget nor curl found."
    break
  fi
  log "   Installing $IPK ..."
  if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
    log "   [OK] Installed $IPK"
  else
    log "[WARN] Failed to install $IPK"
    FAILED_PKGS="$FAILED_PKGS $IPK"
    continue
  fi
done <<EOF
$IPK_LIST
EOF

# مرحله دوم: تلاش مجدد برای پکیج‌های خطا داده
if [ -n "$FAILED_PKGS" ]; then
  log ">>> Retrying failed packages..."
  RETRY_FAILED=""
  for IPK in $FAILED_PKGS; do
    SRC="/tmp/$IPK"
    log "-> Retrying install $IPK ..."
    if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
      log "   [OK] Installed on retry: $IPK"
    else
      log "   [FAIL] Still failed: $IPK"
      RETRY_FAILED="$RETRY_FAILED $IPK"
    fi
  done
  FAILED_PKGS="$RETRY_FAILED"
fi

log ">>> Downloading and extracting files.zip..."
TMP_DIR="/tmp/files_extracted"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

if command -v wget >/dev/null 2>&1; then
  wget -qO /tmp/files.zip "$FILES_ZIP_URL" || log "[ERROR] Failed to download files.zip"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$FILES_ZIP_URL" -o /tmp/files.zip || log "[ERROR] Failed to download files.zip"
fi

if [ -f /tmp/files.zip ]; then
  unzip -oq /tmp/files.zip -d "$TMP_DIR" && log "[OK] Extraction completed."
  log ">>> Copying extracted files with comparison..."
  for dir in etc usr www_open; do
    if [ -d "$TMP_DIR/$dir" ]; then
      find "$TMP_DIR/$dir" -type f | while read -r src_file; do
        rel_path="${src_file#$TMP_DIR/}"
        dest_file="/$rel_path"
        if [ -f "$dest_file" ]; then
          cp -f "$src_file" "$dest_file" && log "[REPLACED] $rel_path"
        else
          mkdir -p "$(dirname "$dest_file")"
          cp "$src_file" "$dest_file" && log "[ADDED] $rel_path"
        fi
      done
    fi
  done
fi

log ">>> Setting execute permissions..."
[ -f /usr/bin/send_at.sh ] && chmod +x /usr/bin/send_at.sh
[ -f /usr/bin/update_apn.sh ] && chmod +x /usr/bin/update_apn.sh
[ -f /usr/share/synctechmodem/get_modem_info.sh ] && chmod +x /usr/share/synctechmodem/get_modem_info.sh
[ -f /www_open/cgi-bin/status_open.sh ] && chmod +x /www_open/cgi-bin/status_open.sh

LAN_IP="192.168.1.5"
if ! uci show network.lan | grep -q "list ipaddr='$LAN_IP'"; then
    uci add_list network.lan.ipaddr="$LAN_IP"
    uci commit network
    /etc/init.d/network restart
    echo "[OK] IP $LAN_IP Added to lan network."
else
    echo "[INFO] IP $LAN_IP has already been configured."
fi

log ">>> Configuring network interface 'wwan'..."
if uci get network.wwan >/dev/null 2>&1; then
    uci delete network.wwan
    log "[OK] Removed existing WWAN interface."
fi
uci set network.wwan=interface
uci set network.wwan.proto='dhcp'
uci set network.wwan.device='usb0'
uci set network.wwan.peerdns='0'
uci add_list network.wwan.dns='8.8.8.8'
uci add_list network.wwan.dns='1.1.1.1'
uci commit network
/etc/init.d/network restart
log "[OK] WWAN interface configured and applied."

log ">>> Updating firewall rules..."
LAN_SEC=$(uci show firewall | grep "firewall.@zone" | grep "name='lan'" | cut -d. -f2 | cut -d= -f1)
uci set firewall.${LAN_SEC}.input='ACCEPT'
uci set firewall.${LAN_SEC}.output='ACCEPT'
uci set firewall.${LAN_SEC}.forward='ACCEPT'
log "[OK] LAN zone set to ACCEPT."
WAN_SEC=$(uci show firewall | grep "firewall.@zone" | grep "name='wan'" | cut -d. -f2 | cut -d= -f1)
if ! uci get firewall.${WAN_SEC}.network 2>/dev/null | grep -qw 'wwan'; then
    uci add_list firewall.${WAN_SEC}.network='wwan'
    log "[OK] Added 'wwan' to WAN zone networks."
else
    log "[INFO] 'wwan' already exists in WAN zone."
fi
uci commit firewall
/etc/init.d/firewall restart
log "[OK] Firewall configuration applied."

FAILED_PKGS="$(echo "$FAILED_PKGS" | xargs)"
if [ -n "$FAILED_PKGS" ]; then
  log "[ERROR] Some packages failed after retry: $(echo $FAILED_PKGS)"
  log "[INFO] Skipping wwan2 / wifi-iface removal due to package install failure."
else
log "[OK] All packages installed successfully. Proceeding with wwan2 / wifi-iface removal..."

log ">>> Removing wifi-iface sections with network 'wwan2'..."
for section in $(uci show wireless | grep "=wifi-iface" | cut -d. -f2 | cut -d= -f1); do
    net_vals=$(uci get wireless.${section}.network 2>/dev/null || echo "")
    for n in $net_vals; do
        if [ "$n" = "wwan2" ]; then
            log "[OK] Deleting wireless.${section}"
            uci delete wireless.${section}
        fi
    done
done
uci commit wireless
/etc/init.d/network restart
log "[OK] Wireless updated."

log ">>> Checking network config for interface 'wwan2'..."
if uci get network.wwan2 >/dev/null 2>&1; then
    uci delete network.wwan2
    log "[OK] Deleted 'network.wwan2' section."
fi
for idx in $(uci show network | grep "=interface" | cut -d[ -f2 | cut -d] -f1); do
    name=$(uci get network.@interface[$idx].name 2>/dev/null || echo "")
    if [ "$name" = "wwan2" ]; then
        log "[OK] Removing network.@interface[$idx] because name='wwan2'"
        uci delete network.@interface[$idx]
    fi
done
uci commit network
/etc/init.d/network restart
fi

log ">>> Cleaning up downloaded files..."
rm -f /tmp/*.ipk /tmp/files.zip
rm -rf /tmp/files_extracted
log "[OK] Cleanup completed."

log ">>> Installation and configuration completed."
log ">>> Full log saved to $LOG_FILE"
log ">>> Reboot system...."
sleep 3
reboot
