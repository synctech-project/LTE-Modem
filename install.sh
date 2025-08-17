#!/bin/sh
set -eu

REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/package"
FILES_ZIP_URL="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/files.zip"

echof() { printf "%s\n" "$1"; }

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
"

echof ">>> Downloading and installing packages..."
for IPK in $IPK_LIST; do
  SRC="/tmp/$IPK"
  echof "-> Downloading $IPK ..."
  
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$SRC" "$REPO_RAW_ROOT/$IPK" || {
      echo "[WARN] Failed to download $IPK"
      continue
    }
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_ROOT/$IPK" -o "$SRC" || {
      echo "[WARN] Failed to download $IPK"
      continue
    }
  else
    echo "[ERROR] Neither wget nor curl found."
    break
  fi
  
  echof "   Installing $IPK ..."
  if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
    echof "   [OK] Installed $IPK"
  else
    echo "[WARN] Failed to install $IPK"
    continue
  fi
done

echof ">>> Downloading and extracting files.zip..."
TMP_DIR="/tmp/files_extracted"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

if command -v wget >/dev/null 2>&1; then
  wget -qO /tmp/files.zip "$FILES_ZIP_URL" || {
    echo "[ERROR] Failed to download files.zip"
  }
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$FILES_ZIP_URL" -o /tmp/files.zip || {
    echo "[ERROR] Failed to download files.zip"
  }
fi

if [ -f /tmp/files.zip ]; then
  unzip -oq /tmp/files.zip -d "$TMP_DIR" || echo "[ERROR] Failed to unzip files.zip"
  
  echof ">>> Copying extracted files..."
  for dir in etc usr www-open; do
    if [ -d "$TMP_DIR/$dir" ]; then
      cp -rf "$TMP_DIR/$dir" / || echo "[WARN] Failed to copy $dir"
    fi
  done
fi

echof ">>> Setting execute permissions..."
[ -f /usr/bin/send_at.sh ] && chmod +x /usr/bin/send_at.sh
[ -f /usr/bin/update_apn.sh ] && chmod +x /usr/bin/update_apn.sh
[ -f /usr/share/synctechmodem/get_modem_info.sh ] && chmod +x /usr/share/synctechmodem/get_modem_info.sh
[ -f /www-open/cgi-bin/status_open.sh ] && chmod +x /www-open/cgi-bin/status_open.sh

if [ -x /etc/init.d/uhttpd ]; then
  echof ">>> Restarting uhttpd ..."
  /etc/init.d/uhttpd restart >/dev/null 2>&1 || echof "[WARN] Failed to restart uhttpd."
fi

echof "Installation and configuration completed."
exit 0
