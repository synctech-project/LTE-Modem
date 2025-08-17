#!/bin/sh
set -eu

REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/package"

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

echof ">>> شروع دانلود و نصب پکیج‌ها:"
for IPK in $IPK_LIST; do
  SRC="/tmp/$IPK"
  echof "-> دانلود $IPK ..."
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$SRC" "$REPO_RAW_ROOT/$IPK"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_ROOT/$IPK" -o "$SRC"
  else
    echof "[خطا] neither wget nor curl found."
    exit 1
  fi
  echof "   نصب $IPK ..."
  if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
    echof "   [موفق] نصب $IPK"
  else
    echof "   [خطا] نصب $IPK شکست خورد!"
    exit 1
  fi
done

echof ">>> بخش کپی فایل‌های پیکربندی (etc، usr، www-open)..."
safe_copy() {
  src="$1"
  dest="$2"
  if [ ! -d "$src" ]; then return 0; fi
  mkdir -p "$dest"
  find "$src" -type f | while read -r f; do
    rel="${f#$src/}"
    destf="$dest/$rel"
    mkdir -p "$(dirname "$destf")"
    cp "$f" "$destf" && echof "[کپی] $rel"
  done
}

safe_copy "/tmp/LTE-Modem/files/etc" "/etc"
safe_copy "/tmp/LTE-Modem/files/usr" "/usr"

if [ -d "/tmp/LTE-Modem/files/www-open" ]; then
  cp -r "/tmp/LTE-Modem/files/www-open" "/" || echof "[خطا] کپی www-open ناموفق بود."
fi

echof ">>> تنظیم دسترسی فایل‌های اجرایی (در صورت وجود)"
[ -f /usr/bin/send_at.sh ] && chmod +x /usr/bin/send_at.sh
[ -f /usr/bin/update_apn.sh ] && chmod +x /usr/bin/update_apn.sh
[ -f /usr/share/synctechmodem/get_modem_info.sh ] && chmod +x /usr/share/synctechmodem/get_modem_info.sh
[ -f /www-open/cgi-bin/status_open.sh ] && chmod +x /www-open/cgi-bin/status_open.sh

if [ -x /etc/init.d/uhttpd ]; then
  echof ">>> ریستارت وب‌سرور uhttpd ..."
  /etc/init.d/uhttpd restart >/dev/null 2>&1 || echof "[هشدار] ریستارت uhttpd ناموفق بود."
fi

echof "نصب و پیکربندی با موفقیت انجام شد!"
# reboot  # اگر لازم داری فعال کن
exit 0
