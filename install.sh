#!/bin/sh
# نصب خودکار برای HLK-7628N

# مسیر دانلود موقت
TMP_DIR="/tmp/LTE-Modem"

# پاکسازی مسیر موقت قبلی
rm -rf $TMP_DIR
mkdir -p $TMP_DIR

echo ">>> دانلود مخزن از GitHub..."
wget -q -O /tmp/LTE-Modem.zip https://github.com/synctech-project/LTE-Modem/archive/refs/heads/main.zip
unzip -q /tmp/LTE-Modem.zip -d /tmp
mv /tmp/LTE-Modem-main $TMP_DIR

# ------------------------------------------------------
# 1. نصب بسته‌ها
echo ">>> نصب پکیج‌ها..."
PKG_DIR="$TMP_DIR/package"
cd "$PKG_DIR"

for pkg in $(ls -1 *.ipk | sort -V); do
    echo "Installing package: $pkg"
    opkg install --force-reinstall "$PKG_DIR/$pkg"
done

# ------------------------------------------------------
# 2. تابع کپی ایمن فایل‌ها (بدون حذف محتویات سیستمی)
safe_copy() {
    src="$1"
    dest="$2"
    mkdir -p "$dest"
    for file in $(find "$src" -type f); do
        rel_path="${file#$src/}"
        dest_file="$dest/$rel_path"
        mkdir -p "$(dirname "$dest_file")"
        cp "$file" "$dest_file"
        echo "Copied: $dest_file"
    done
}

echo ">>> جایگذاری فایل‌ها..."
# برای etc و usr (بدون حذف)
[ -d "$TMP_DIR/files/etc" ] && safe_copy "$TMP_DIR/files/etc" "/etc"
[ -d "$TMP_DIR/files/usr" ] && safe_copy "$TMP_DIR/files/usr" "/usr"

# برای www-open که جدید است
[ -d "$TMP_DIR/files/www-open" ] && cp -r "$TMP_DIR/files/www-open" "/"

# ------------------------------------------------------
# 3. دادن مجوز اجرایی به اسکریپت‌ها
echo ">>> تغییر مجوز اسکریپت‌ها..."
chmod +x /usr/bin/send_at.sh 2>/dev/null
chmod +x /usr/bin/update_apn.sh 2>/dev/null
chmod +x /usr/share/synctechmodem/get_modem_info.sh 2>/dev/null
chmod +x /www-open/cgi-bin/status_open.sh 2>/dev/null

# ------------------------------------------------------
# 4. ری‌استارت uhttpd
echo ">>> ری‌استارت uhttpd..."
/etc/init.d/uhttpd restart

# ------------------------------------------------------
# 5. ریبوت سیستم
echo ">>> Compated configuration (:"
