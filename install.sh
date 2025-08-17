#!/bin/sh
# نصب خودکار HLK-7628N با گزارش دقیق

REPO_URL="https://github.com/synctech-project/LTE-Modem.git"
TMP_DIR="/tmp/LTE-Modem"

echo ">>> شروع عملیات نصب..."

# --- دانلود مخزن ---
echo ">>> دانلود مخزن از GitHub..."
rm -rf "$TMP_DIR"
git clone --depth 1 "$REPO_URL" "$TMP_DIR" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[خطا] دانلود مخزن از $REPO_URL انجام نشد!"
    exit 1
fi

# --- نصب پکیج‌ها ---
PKG_DIR="$TMP_DIR/package"
echo ">>> نصب پکیج‌ها..."
if [ -d "$PKG_DIR" ]; then
    cd "$PKG_DIR" || { echo "[خطا] دسترسی به پوشه package ممکن نیست."; exit 1; }
    PKG_LIST=$(ls -1 *.ipk 2>/dev/null | sort -V)
    if [ -z "$PKG_LIST" ]; then
        echo "[خطا] هیچ فایل .ipk در پوشه package پیدا نشد."
    else
        for pkg in $PKG_LIST; do
            echo "در حال نصب: $pkg"
            opkg install --force-reinstall "$PKG_DIR/$pkg" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "[خطا] نصب پکیج $pkg با مشکل مواجه شد."
                exit 1
            fi
        done
    fi
else
    echo "[خطا] پوشه package یافت نشد."
fi

# --- تابع کپی ایمن ---
safe_copy() {
    src="$1"
    dest="$2"
    if [ ! -d "$src" ]; then
        echo "[خطا] پوشه $src وجود ندارد."
        return 1
    fi
    mkdir -p "$dest"
    for file in $(find "$src" -type f); do
        rel_path="${file#$src/}"
        dest_file="$dest/$rel_path"
        mkdir -p "$(dirname "$dest_file")"
        if [ -f "$dest_file" ]; then
            echo "[جایگزینی] $dest_file"
        else
            echo "[جدید] $dest_file"
        fi
        cp "$file" "$dest_file" || echo "[خطا] کپی $file به $dest_file انجام نشد."
    done
}

# --- جایگذاری فایل‌ها ---
echo ">>> جایگذاری فایل‌ها..."
safe_copy "$TMP_DIR/files/etc" "/etc"
safe_copy "$TMP_DIR/files/usr" "/usr"

# پوشه www-open
if [ -d "$TMP_DIR/files/www-open" ]; then
    cp -r "$TMP_DIR/files/www-open" "/" && echo "[افزودن پوشه] /www-open"
else
    echo "[هشدار] پوشه www-open یافت نشد."
fi

# --- دادن مجوز به اسکریپت‌ها ---
echo ">>> تغییر مجوز اسکریپت‌ها..."
chmod +x /usr/bin/send_at.sh 2>/dev/null && echo "[OK] send_at.sh اجرایی شد."
chmod +x /usr/bin/update_apn.sh 2>/dev/null && echo "[OK] update_apn.sh اجرایی شد."
chmod +x /usr/share/synctechmodem/get_modem_info.sh 2>/dev/null && echo "[OK] get_modem_info.sh اجرایی شد."
chmod +x /www-open/cgi-bin/status_open.sh 2>/dev/null && echo "[OK] status_open.sh اجرایی شد."

# --- ری‌استارت uhttpd ---
echo ">>> ری‌استارت uhttpd..."
/etc/init.d/uhttpd restart >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[خطا] ری‌استارت uhttpd انجام نشد."
fi

# --- ریبوت ---
echo ">>> ریبوت دستگاه..."
reboot
