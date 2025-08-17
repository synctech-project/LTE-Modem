#!/bin/sh
set -eu

REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/package"
FILES_ZIP_URL="https://github.com/synctech-project/LTE-Modem/raw/main/files.zip"

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
4-libuclitttp-lua_2023-03-15-9b5b683f-1_mipsel_24kc.ipk
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
    wget -qO "$SRC" "$REPO_RAW_ROOT/$IPK" || { echo "[ERROR] Download failed: $IPK"; exit 1; }
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_ROOT/$IPK" -o "$SRC" || { echo "[ERROR] Download failed: $IPK"; exit 1; }
  else
    echo "[ERROR] Neither wget nor curl found."
    exit 1
  fi
  echof "   Installing $IPK ..."
  if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
    echof "   [OK] Installed $IPK"
  else
    echo "[ERROR] Failed to install $IPK"
    exit 1
  fi
done

# New section: Download and extract 'files.zip'
echof ">>> Downloading files.zip..."
FILES_ZIP="/tmp/files.zip"
if command -v wget >/dev/null 2>&1; then
  wget -qO "$FILES_ZIP" "$FILES_ZIP_URL" || { echo "[ERROR] Download files.zip failed"; exit 1; }
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$FILES_ZIP_URL" -o "$FILES_ZIP" || { echo "[ERROR] Download files.zip failed"; exit 1; }
fi

echof ">>> Extracting files.zip..."
mkdir -p /tmp/files_extracted
if unzip -o "$FILES_ZIP" -d /tmp/files_extracted >/dev/null 2>&1; then
  echof "Extraction done."
else
  echo "[ERROR] Failed to extract files.zip"
  exit 1
fi

# Copy extracted folders to proper locations
echof ">>> Copying extracted files to system..."
for DIR in /tmp/files_extracted/*; do
  if [ -d "$DIR" ]; then
    BASEDIR="/$(basename "$DIR")"
    mkdir -p "$BASEDIR"
    cp -rf "$DIR"/* "$BASEDIR"/ || { echo "[ERROR] Failed to copy $DIR"; exit 1; }
    echof "Copied: $DIR -> $BASEDIR"
  fi
done

# Set executable permission for specific scripts
echof ">>> Setting executable permissions..."
chmod +x /usr/bin/send_at.sh 2>/dev/null || echo "[WARN] send_at.sh not found"
chmod +x /usr/bin/update_apn.sh 2>/dev/null || echo "[WARN] update_apn.sh not found"
chmod +x /usr/share/synctechmodem/get_modem_info.sh 2>/dev/null || echo "[WARN] get_modem_info.sh not found"
chmod +x /www-open/cgi-bin/status_open.sh 2>/dev/null || echo "[WARN] status_open.sh not found"

# Restart uhttpd
echof ">>> Restarting uhttpd..."
if /etc/init.d/uhttpd restart >/dev/null 2>&1; then
  echof "uhttpd restarted."
else
  echo "[ERROR] Failed to restart uhttpd"
fi

echof "Installation and configuration completed successfully!"
exit 0
