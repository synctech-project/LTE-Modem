#!/bin/sh
uci set system.@system[0].zonename='Asia/Tehran'

uci set system.@system[0].timezone='<+0330>-3:30'

uci commit system

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
    wget -qO "$SRC" "$REPO_RAW_ROOT/$IPK" || {
      log "[WARN] Failed to download $IPK"
      continue
    }
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_ROOT/$IPK" -o "$SRC" || {
      log "[WARN] Failed to download $IPK"
      continue
    }
  else
    log "[ERROR] Neither wget nor curl found."
    break
  fi
  
  log "   Installing $IPK ..."
  if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
    log "   [OK] Installed $IPK"
  else
    log "[WARN] Failed to install $IPK"
    continue
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

log ">>> Setting execute permissions..."
[ -f /usr/bin/send_at.sh ] && chmod +x /usr/bin/send_at.sh && log "[OK] Executable: /usr/bin/send_at.sh"
[ -f /usr/bin/update_apn.sh ] && chmod +x /usr/bin/update_apn.sh && log "[OK] Executable: /usr/bin/update_apn.sh"
[ -f /usr/share/synctechmodem/get_modem_info.sh ] && chmod +x /usr/share/synctechmodem/get_modem_info.sh && log "[OK] Executable: get_modem_info.sh"
[ -f /www_open/cgi-bin/status_open.sh ] && chmod +x /www_open/cgi-bin/status_open.sh && log "[OK] Executable: status_open.sh"

if [ -x /etc/init.d/uhttpd ]; then
  log ">>> Restarting uhttpd ..."
  /etc/init.d/uhttpd restart >/dev/null 2>&1 && log "[OK] uhttpd restarted." || log "[WARN] Failed to restart uhttpd."
fi

log ">>> Configuring WWAN interface..."
# اگر wwan وجود دارد حذفش کن
if uci get network.wwan >/dev/null 2>&1; then
    uci delete network.wwan
    log "[OK] Removed existing WWAN interface."
fi
# ایجاد اینترفیس جدید wwan
uci set network.wwan=interface
uci set network.wwan.proto='dhcp'
uci set network.wwan.device='usb0'
uci set network.wwan.peerdns='0'
uci add_list network.wwan.dns='8.8.8.8'
uci add_list network.wwan.dns='1.1.1.1'
uci commit network
log "[OK] WWAN interface configured."

log ">>> Cleaning up downloaded files..."
rm -f /tmp/*.ipk /tmp/files.zip
log "[OK] Cleanup completed."

log ">>> Installation and configuration completed."
log ">>> Full log saved to $LOG_FILE"
exit 0
