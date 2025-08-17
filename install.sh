#!/bin/sh
# install.sh نسخه نهایی — دانلود از GitHub، پیدا کردن package، و نصب ipk ها به ترتیب
set -eu

REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main"
REPO_GIT="https://github.com/synctech-project/LTE-Modem.git"
TMP_DIR="/tmp/LTE-Modem"
PKG_SUBPATHS="package package/ packages pkg file/package release/package"

echof() { printf "%s\n" "$1"; }

echof ">>> شروع نصب خودکار (نسخه مقاوم)"
rm -rf "$TMP_DIR" || true

# تلاش با git clone
echof ">>> تلاش برای کلون مخزن با git..."
if command -v git >/dev/null 2>&1; then
  if git clone --depth 1 "$REPO_GIT" "$TMP_DIR" >/dev/null 2>&1; then
    echof ">>> کلون موفق."
  else
    echof "[هشدار] کلون مخزن با git شکست خورد؛ تلاش برای دانلود مستقیم فایل install.sh..."
    mkdir -p "$TMP_DIR"
    # دانلود تنها install.sh به عنوان نقطه شروع
    if command -v wget >/dev/null 2>&1; then
      wget -qO "$TMP_DIR/install.sh" "$REPO_RAW_ROOT/install.sh" || true
    elif command -v curl >/dev/null 2>&1; then
      curl -fsSL "$REPO_RAW_ROOT/install.sh" -o "$TMP_DIR/install.sh" || true
    fi
  fi
else
  echof "[هشدار] git نصب نیست؛ تلاش برای دانلود مستقیم..."
  mkdir -p "$TMP_DIR"
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$TMP_DIR/install.sh" "$REPO_RAW_ROOT/install.sh" || true
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_ROOT/install.sh" -o "$TMP_DIR/install.sh" || true
  fi
fi

# پیدا کردن پوشه package داخل TMP_DIR
PKG_DIR=""
for p in $PKG_SUBPATHS; do
  if [ -d "$TMP_DIR/$p" ]; then
    PKG_DIR="$TMP_DIR/$p"
    break
  fi
done

# اگر پوشه package پیدا نشد، بررسی اینکه آیا فایل‌های ipk به صورت فایل تکی در repo هستند
if [ -z "$PKG_DIR" ]; then
  echof ">>> پوشه package پیدا نشد در کلون. بررسی فایل‌های .ipk در ریشه..."
  if ls "$TMP_DIR"/*.ipk >/dev/null 2>&1; then
    PKG_DIR="$TMP_DIR"
  else
    echof "[هشدار] فایل .ipk در مخزن پیدا نشد. تلاش برای دانلود از مسیر raw در GitHub..."
    # اگر نام فایل‌ها مشخص نیست، ما نیاز به لیست از تو داریم؛ اما تلاش کنیم لیست common را دانلود کنیم:
    # این بخش تلاش می‌کند فایل index را از repo بگیرد که لیست پکیج‌ها را تعریف کند (در صورت وجود)
    if command -v wget >/dev/null 2>&1; then
      wget -qO- "$REPO_RAW_ROOT/package/list.txt" > "$TMP_DIR/_pkg_list.txt" 2>/dev/null || true
    elif command -v curl >/dev/null 2>&1; then
      curl -fsSL "$REPO_RAW_ROOT/package/list.txt" -o "$TMP_DIR/_pkg_list.txt" 2>/dev/null || true
    fi
    if [ -s "$TMP_DIR/_pkg_list.txt" ]; then
      echof ">>> لیست پکیج از package/list.txt دریافت شد."
(ادامه اسکریپت و بخش‌های تکمیلی)

ادامه و تکمیل install.sh:
```bash
      PKG_DIR="$TMP_DIR"
    else
      echof "[خطا] هیچ منبعی برای پیدا کردن فایل‌های .ipk یافت نشد. لطفاً مطمئن شو فایل‌های .ipk داخل پوشه package در ریشه‌ی repo آپلود شده‌اند یا فایل package/list.txt را با نام فایل‌ها قرار بدهی."
      exit 1
    fi
  fi
fi

echof ">>> مسیر package استفاده‌شده: ${PKG_DIR}"

# لیست فایل‌های ipk به ترتیب نام (نسخه) — اگر فایل لیست موجود باشد، از آن استفاده کن
PKG_FILES=""
if [ -f "$TMP_DIR/_pkg_list.txt" ]; then
  echof ">>> خواندن ترتیب نصب از _pkg_list.txt"
  # حذف خطوط خالی و کامنت
  PKG_FILES=$(grep -vE '^\s*(#|$)' "$TMP_DIR/_pkg_list.txt" | tr '
' ' ')
else
  # از لیست فایل‌های موجود در PKG_DIR استفاده کن
  PKG_FILES=$(ls -1 "$PKG_DIR"/*.ipk 2>/dev/null | xargs -n1 basename | sort -V || true)
fi

if [ -z "$PKG_FILES" ]; then
  echof "[خطا] فایل .ipk برای نصب پیدا نشد در $PK(پایان اسکریپت)
```bash
if [ -z "$PKG_FILES" ]; then
  echof "[خطا] فایل .ipk برای نصب پیدا نشد در $PKG_DIR"
  exit 1
fi

echof ">>> لیست پکیج‌ها برای نصب:"
for f in $PKG_FILES; do echof " - $f"; done

# نصب هر پکیج به ترتیب
if command -v opkg >/dev/null 2>&1; then
  for p in $PKG_FILES; do
    # اگر PKG_DIR مسیر محلی است، استفاده از فایل محلی؛ در غیر این صورت تلاش برای دانلود raw
    if [ -f "$PKG_DIR/$p" ]; then
      SRC="$PKG_DIR/$p"
    else
      # تلاش برای دانلود از raw github
      SRC="$TMP_DIR/$p"
      echof ">>> دانلود $p از GitHub raw..."
      if command -v wget >/dev/null 2>&1; then
        wget -qO "$SRC" "$REPO_RAW_ROOT/package/$p" || {
          echof "[خطا] دانلود $p از $REPO_RAW_ROOT/package/$p انجام نشد."
          exit 1
        }
      elif command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_RAW_ROOT/package/$p" -o "$SRC" || {
          echof "[خطا] دانلود $p از $REPO_RAW_ROOT/package/$p انجام نشد."
          exit 1
        }
      else
        echof "[خطا] wget یا curl نصب نیست؛ نمی‌توان فایل‌ها را دانلود کرد."
        exit 1
      fi
    fi

    echof ">>> نصب $p ..."
    opkg install --force-reinstall "$SRC" >/dev/null 2(پایان نهایی اسکریپت — ادامه)
```bash
    2>&1 || {
      echof "[خطا] نصب $p با opkg با خطا مواجه شد."
      exit 1
    }
    echof "[موفق] نصب $p"
  done
else
  echof "[خطا] opkg نصب نیست؛ امکان نصب .ipk وجود ندارد."
  exit 1
fi

# کپی ایمن فایل‌های repo به مقصد (/etc و /usr و www-open)
safe_copy() {
  src="$1"
  dest="$2"
  if [ ! -d "$src" ]; then
    return 0
  fi
  mkdir -p "$dest"
  find "$src" -type f | while read -r f; do
    rel="${f#$src/}"
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

echof ">>> کپی فایل‌های etc و usr (در صورت وجود)"
safe_copy "$TMP_DIR/files/etc" "/etc"
safe_copy "$TMP_DIR/files/usr" "/usr"

if [ -d "$TMP_DIR/files/www-open" ]; then
  echof ">>> کپی www-open"
  cp -r "$TMP_DIR/files/www-open" "/" || echof "[خطا] کپی www-open ناموفق بود."
fi

# ست کردن مجوزها (اگر اسکریپت‌ها وجود داشته باشند)
echof ">>> ست کردن مجوز اسکریپت‌ها (در صورت وجود)"
[ -f /usr/bin/send_at.sh ] && chmod +x /usr/bin/send_at.sh && echof "[OK] send_at.sh اجرایی شد."
[ -f /usr/bin/update_apn.sh ] && chmod +x /usr/bin/update_apn.sh && echof "[OK] update_apn.sh اجر(پایان اسکریپت — خطوط نهایی)
```bash
.sh اجرایی شد."
[ -f /usr/share/synctechmodem/get_modem_info.sh ] && chmod +x /usr/share/synctechmodem/get_modem_info.sh && echof "[OK] get_modem_info.sh اجرایی شد."
[ -f /www-open/cgi-bin/status_open.sh ] && chmod +x /www-open/cgi-bin/status_open.sh && echof "[OK] status_open.sh اجرایی شد."

# ری‌استارت سرویس وب و ریبوت اختیاری
if [ -x /etc/init.d/uhttpd ]; then
  echof ">>> ری‌استارت uhttpd..."
  /etc/init.d/uhttpd restart >/dev/null 2>&1 || echof "[هشدار] ری‌استارت uhttpd ناموفق بود."
fi

echof ">>> نصب با موفقیت به پایان رسید. در صورت نیاز دستگاه را ریبوت می‌کنم."
# اگر می‌خواهی خودکار ریبوت شود، خط بعد را فعال کن:
# reboot
exit 0
