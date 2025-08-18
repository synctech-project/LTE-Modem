#!/bin/sh
uci set system.@system[0].zonename='Asia/Tehran'
uci set system.@system[0].timezone='<+0330>-3:30'
uci commit system

uci set system.@system[0].hostname='AGC-Global'
uci commit system
hostname 'AGC-Global'
if /etc/init.d/system restart >/dev/null 2>&1; then
    log "[OK] System service restarted and hostname applied."
else
    log "[WARN] Failed to restart system service. Hostname may require reboot to fully apply."
fi

# Set custom banner
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
: > "$LOG_FILE"   # clear log file

log() {
  printf "%s\n" "$1" | tee -a "$LOG_FILE"
}

REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/package"
FILES_ZIP_URL="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/files.zip"

IPK_LIST="
0-kmod-nls-base_5.15.167-1_mipsel_24kc.ipk
1-0-kmod-usb-core_5.15.167-1_mipsel_24kc.ipk
1-1kmod-usb-ehci_5.15.167-1_mipsel_24kc.ipk
1-liblua5.1.5_5.1.5-11_mipsel_24kc.ipk
10-luci-lua-runtime_git-25.176.69269-6e21c0e_mipsel_24kc.ipk
11-luci-compat_git-25.176.69269-6e21c0e_all.ipk
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
unzip_6.0-8_mipsel_24kc.ipk
"

log ">>> Downloading and installing packages..."
for IPK in $IPK_LIST; do
  SRC="/tmp/$IPK"
  log "-> Downloading $IPK ..."
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$SRC" "$REPO_RAW_ROOT/$IPK" || { log "[WARN] Failed to download $IPK"; continue; }
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_ROOT/$IPK" -o "$SRC" || { log "[WARN] Failed to download $IPK"; continue; }
  else
    log "[ERROR] Neither wget nor curl found."
    break
  fi

  log "   Installing $IPK ..."
  if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
    log "   [OK] Installed $IPK"
  else
    log "[WARN] Failed to install $IPK"
  fi
done

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
  if unzip -oq /tmp/files.zip -d "$TMP_DIR"; then
    log "[OK] Extraction completed."
  else
    log "[ERROR] Failed to unzip files.zip"
  fi

  log ">>> Copying extracted files with comparison..."
  for dir in etc usr www_open; do
    if [ -d "$TMP_DIR/$dir" ]; then
      find "$TMP_DIR/$dir" -type f | while read -r src_file; do
        rel_path="${src_file#$TMP_DIR/}"
        dest_file="/$rel_path"
        if [ -f "$dest_file" ]; then
          cp -f "$src_file" "$dest_file" && log "[REPLACED] $rel_path" || log "[ERROR] Failed to replace $rel_path"
        else
          mkdir -p "$(dirname "$dest_file")"
          cp "$src_file" "$dest_file" && log "[ADDED] $rel_path" || log "[ERROR] Failed to add $rel_path"
        fi
      done
    else
      log "[WARN] Directory $dir not found in extracted content"
    fi
  done
fi

log ">>> Updating or adding 'wwan' interface..."
NET_FILE="/etc/config/network"
if grep -q "config interface 'wwan'" "$NET_FILE"; then
    log "[INFO] Existing 'wwan' found - updating..."
    sed -i "/config interface 'wwan'/,/^config /{ /^config /!d }" "$NET_FILE"
else
    log "[INFO] No 'wwan' found - adding..."
fi

cat >> "$NET_FILE" <<'EOF'
config interface 'wwan'
    option proto 'dhcp'
    option device 'usb0'
    option peerdns '0'
    list dns '1.1.1.1'
    list dns '8.8.8.8'
EOF

if /etc/init.d/network restart >/dev/null 2>&1; then
    log "[OK] Network service restarted."
else
    log "[WARN] Failed to restart network service."
fi

log ">>> Setting execute permissions..."
[ -f /usr/bin/send_at.sh ] && chmod +x /usr/bin/send_at.sh && log "[OK] Executable: /usr/bin/send_at.sh"
[ -f /usr/bin/update_apn.sh ] && chmod +x /usr/bin/update_apn.sh && log "[OK] Executable: /usr/bin/update_apn.sh"
[ -f /usr/share/synctechmodem/get_modem_info.sh ] && chmod +x /usr/share/synctechmodem/get_modem_info.sh && log "[OK] Executable: get_modem_info.sh"
[ -f /www_open/cgi-bin/status_open.sh ] && chmod +x /www_open/cgi-bin/status_open.sh && log "[OK] Executable: status_open.sh"

if [ -x /etc/init.d/uhttpd ]; then
  log ">>> Restarting uhttpd ..."
  /etc/init.d/uhttpd restart >/dev/null 2>&1 && log "[OK] uhttpd restarted." || log "[WARN] Failed to restart uhttpd."
fi

log ">>> Updating firewall configuration..."

FW_FILE="/etc/config/firewall"

# Ensure LAN zone policies are all ACCEPT
if grep -q "config zone" "$FW_FILE" && grep -q "option name 'lan'" "$FW_FILE"; then
    log "[INFO] Updating LAN zone policies to ACCEPT..."
    sed -i "/config zone/,/config /{
        /option name 'lan'/,/config /{
            s/^\(\s*option input\s*\).*/\1'ACCEPT'/
            s/^\(\s*option output\s*\).*/\1'ACCEPT'/
            s/^\(\s*option forward\s*\).*/\1'ACCEPT'/
        }
    }" "$FW_FILE"
else
    log "[WARN] LAN zone not found, skipping policy update."
fi

# Ensure 'wwan' is in WAN zone networks list
if grep -q "option name 'wan'" "$FW_FILE"; then
    if ! awk '/option name .wan./,/^config /' "$FW_FILE" | grep -q "list network 'wwan'"; then
        log "[INFO] Adding 'wwan' to WAN zone networks..."
        sed -i "/option name 'wan'/,/^config /{
            /list network/ {
                /list network 'wan'/a\	list network 'wwan'
                b
            }
        }" "$FW_FILE"
    else
        log "[INFO] 'wwan' already exists in WAN zone."
    fi
else
    log "[WARN] WAN zone not found, skipping 'wwan' addition."
fi

# Commit and restart firewall
if /etc/init.d/firewall restart >/dev/null 2>&1; then
    log "[OK] Firewall service restarted."
else
    log "[WARN] Failed to restart firewall service."
fi

log ">>> Removing wifi-iface with network 'wwan2' if it exists..."
WL_FILE="/etc/config/wireless"

if grep -q "option network 'wwan2'" "$WL_FILE"; then
    log "[INFO] Found 'wwan2' interface in wireless config. Removing..."
    # حذف کل بلوکی که option network 'wwan2' دارد
    sed -i '/^config wifi-iface/,/^config /{H;/option network '\''wwan2'\''/h};${x;/wwan2/{s/^.*\n//;p;};d}' "$WL_FILE"

    # ریلود وایرلس
    if wifi reload >/dev/null 2>&1; then
        log "[OK] Wireless configuration reloaded."
    else
        log "[WARN] Failed to reload wireless configuration."
    fi
else
    log "[INFO] No 'wwan2' network interface found. Skipping."
fi

log ">>> Cleaning up downloaded files..."
rm -f /tmp/*.ipk /tmp/files.zip
log "[OK] Cleanup completed."

log ">>> Installation and configuration completed."
log ">>> Full log saved to $LOG_FILE"
exit 0
