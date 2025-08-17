#!/bin/sh
# نصب اتوماتیک - سازگار با POSIX sh و busybox ash

set -eu

REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main"
REPO_GIT="https://github.com/synctech-project/LTE-Modem.git"
TMP_DIR="/tmp/LTE-Modem"
PKG_SUBPATHS="package package/ packages pkg file/package release/package"

echof() {
  printf "%s\n" "$1"
}

echof ">>> شروع نصب خودکار (نسخه مقاوم)"
rm -rf "$TMP_DIR" 2>/dev/null || true

# تلاش با git clone
echof ">>> تلاش برای کلون مخزن با git..."
if command -v git >/dev/null 2>&1; then
  if git clone --depth 1 "$REPO_GIT" "$TMP_DIR" >/dev/null 2>&1; then
    echof ">>> کلون موفق."
  else
    echof "[هشدار] کلون مخزن با git شکست خورد؛ دانلود مستقیم فایل install.sh..."
    mkdir -p "$TMP_DIR"
    if command -v wget >/dev/null 2>&1; then
      wget -qO "$TMP_DIR/install.sh" "$REPO_RAW_ROOT/install.sh" || true
    elif command -v curl >/dev/null 2>&1; then
      curl -fsSL "$REPO_RAW_ROOT/install.sh" -o "$TMP_DIR/install.sh" || true
    fi
  fi
else
  echof "[هشدار] git نصب نیست؛ دانلود مستقیم..."
  mkdir -p "$TMP_DIR"
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$TMP_DIR/install.sh" "$REPO_RAW_ROOT/install.sh" || true
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_ROOT/install.sh" -o "$TMP_DIR/install.sh" || true
  fi
fi

# پیدا کردن پوشه package در TMP_DIR
PKG_DIR=""
for p in $PKG_SUBPATHS; do
  if [ -d "$TMP_DIR/$p" ]; then
    PKG_DIR="$TMP_DIR/$p"
    break
  fi
done

# اگر پوشه پیدا نشد، بررسی فایل‌های ipk در ریشه
if [ -z "$PKG_DIR" ]; then
  echof ">>> package پیدا نشد، بررسی .ipk در ریشه..."
  if ls "$TMP_DIR"/*.ipk >/dev/null 2>&1; then
    PKG_DIR="$TMP_DIR"
  else
    echof "[هشدار] .ipk یافت نشد. تلاش برای دانلود لیست از GitHub..."
    if command -v wget >/dev/null 2>&1; then
      wget -qO- "$REPO_RAW_ROOT/package/list.txt" > "$TMP_DIR/_pkg_list.txt" 2>/dev/null || true
    elif command -v curl >/dev/null 2>&1; then
      curl -fsSL "$REPO_RAW_ROOT/package/list.txt" -o "$TMP_DIR/_pkg_list.txt" 2>/dev/null || true
    fi
    if [ -s "$TMP_DIR/_pkg_list.txt" ]; then
      echof ">>> لیست package دریافت شد."
      PKG_DIR="$TMP_DIR"
    else
      echof "[خطا] منبع فایل‌های .ipk یافت نشد. مطمئن شو .ipk ها یا لیستِ نام آنها وجود دارد."
      exit 1
    fi
  fi
fi

echof ">>> مسیر package: $PKG_DIR"

# خواندن فایل‌های ipk از لیست یا دایرکتوری
PKG_FILES=""
if [ -f "$TMP_DIR/_pkg_list.txt" ]; then
  echof ">>> ترتیب نصب از _pkg_list.txt"
  PKG_FILES=$(grep -vE '^\s*(#|$)' "$TMP_DIR/_pkg_list.txt" | tr '\n' ' ')
else
  PKG_FILES=$(ls -1 "$PKG_DIR"/*.ipk 2>/dev/null | xargs -n1 basename | sort | tr '\n' ' ')
fi

if [ -z "$PKG_FILES" ]; then
  echof "[خطا] فایل .ipk برای نصب یافت نشد!"
  exit 1
fi

echof ">>> لیست پکیج‌ها:"
for f in $PKG_FILES; do
  echof " - $f"
done

# نصب هر ipk با opkg
if command -v opkg >/dev/null 2>&1; then
  for p in $PKG_FILES; do
    if [ -f "$PKG_DIR/$p" ]; then
      SRC="$PKG_DIR/$p"
    else
      SRC="$TMP_DIR/$p"
      echof ">>> دانلود $p از GitHub raw..."
      if command -v wget >/dev/null 2>&1; then
        wget -qO "$SRC" "$REPO_RAW_ROOT/package/$p" || {
          echof "[خطا] دانلود $p ناموفق."
          exit 1
        }
      elif command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_RAW_ROOT/package/$p" -o "$SRC" || {
          echof "[خطا] دانلود $p ناموفق."
          exit 1
        }
      else
        echof "[خطا] wget یا curl یافت نشد."
        exit 1
      fi
    fi
    echof ">>> نصب $p ..."
    opkg install --force-reinstall "$SRC" >/dev/null 2>&1 || {
      echof "[خطا] نصب $p با opkg با خطا مواجه شد."
      exit 1
    }
    echof "[موفق] نصب $p"
  done
else
  echof "[خطا] opkg نصب نیست!"
  exit 1
fi

# کپی فایل‌ها (ایمن)
safe_copy() {
  src="$1"
  dest="$2"
  if [ ! -d "$src" ]; then
    return 0
  fi
  mkdir -p "$dest"
  find "$src" -type f | while read -r f; do
    rel=$(echo "$f" | sed "s^$src/^^")
    destf="$dest/$rel"
    mkdir -p "$(dirname "$destf")"
    if [ -f "$destf" ]; then
      echof "[جایگزینی] $destf"
    else
      echof "[جدید] $destf"
    fi
    cp "$f" "$destf" || echof "[خطا] کپی $f به $destf ناموفق بود."
  done
}

echof ">>> کپی فایل‌های etc و usr (اگر باشند)"
safe_copy "$TMP_DIR/files/etc" "/etc"
safe_copy "$TMP_DIR/files/usr" "/usr"

if [ -d "$TMP_DIR/files/www-open" ]; then
  echof ">>> کپی www-open"
  cp -r "$TMP_DIR/files/www-open" "/" || echof "[خطا] کپی www-open ناموفق بود."
fi

# ست کردن مجوز اجرا (اگر باشد)
echof ">>> ست کردن مجوز اجرا برای اسکریپت‌ها"
[ -f /usr/bin/send_at.sh ] && chmod +x /usr/bin/send_at.sh && echof "[OK] send_at.sh اجرایی شد."
[ -f /usr/bin/update_apn.sh ] && chmod +x /usr/bin/update_apn.sh && echof "[OK] update_apn.sh اجرایی شد."
[ -f /usr/share/synctechmodem/get_modem_info.sh ] && chmod +x /usr/share/synctechmodem/get_modem_info.sh && echof "[OK] get_modem_info.sh اجرایی شد."
[ -f /www-open/cgi-bin/status_open.sh ] && chmod +x /www-open/cgi-bin/status_open.sh && echof "[OK] status_open.sh اجرایی شد."

# ری‌استارت سرویس وب و ریبوت اختیاری
if [ -x /etc/init.d/uhttpd ]; then
  echof ">>> ری‌استارت uhttpd..."
  /etc/init.d/uhttpd restart >/dev/null 2>&1 || echof "[هشدار] ری‌استارت uhttpd ناموفق بود."
fi

echof ">>> نصب با موفقیت انجام شد."
# ریبوت خودکار (اختیاری)
# reboot

exit 0
