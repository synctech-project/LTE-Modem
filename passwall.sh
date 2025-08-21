#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[*] Running Passwall offline installer...${NC}"
sleep 1
clear

# تنظیمات اولیه سیستم و شبکه
uci set system.@system[0].zonename='Asia/Tehran'
uci set system.@system[0].timezone='<+0330>-3:30'
uci set system.@system[0].hostname=Passwall-Offline
uci set network.wan.peerdns="0"
uci set network.wan6.peerdns="0"
uci set network.wan.dns='1.1.1.1'
uci set network.wan6.dns='2001:4860:4860::8888'
uci commit system
uci commit network
/sbin/reload_config

# مسیر اصلی مخزن IPK آفلاین
REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/passwall-packages"

# لیست دقیق IPKها بر اساس فایل‌های موجود در passwall-packages
IPK_LIST="
dnsmasq-full_2.86-14_mipsel_24kc.ipk
unzip_6.0-8_mipsel_24kc.ipk
luci-app-passwall_git-25.176.69269-6e21c0e_all.ipk
ipset_7.15-1_mipsel_24kc.ipk
ipt2socks_git-25.176.69269-6e21c0e_mipsel_24kc.ipk
iptables_1.8.8-2_mipsel_24kc.ipk
iptables-legacy_1.8.8-2_mipsel_24kc.ipk
iptables-mod-conntrack-extra_1.8.8-2_mipsel_24kc.ipk
iptables-mod-iprange_1.8.8-2_mipsel_24kc.ipk
iptables-mod-socket_1.8.8-2_mipsel_24kc.ipk
iptables-mod-tproxy_1.8.8-2_mipsel_24kc.ipk
kmod-ipt-nat_5.15.167-1_mipsel_24kc.ipk
kmod-nft-socket_5.15.167-1_mipsel_24kc.ipk
kmod-nft-tproxy_5.15.167-1_mipsel_24kc.ipk
"

FAILED_PKGS=""

echo -e "${YELLOW}>>> Downloading and installing Passwall packages...${NC}"

for IPK in $IPK_LIST; do
    SRC="/tmp/$IPK"
    echo -e "${YELLOW}-->${NC} Downloading $IPK ..."
    if wget -qO "$SRC" "$REPO_RAW_ROOT/$IPK"; then
        if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
            echo -e "${GREEN}[OK] Installed${NC} $IPK"
        else
            echo -e "${RED}[FAIL] Failed to install${NC} $IPK"
            FAILED_PKGS="$FAILED_PKGS $IPK"
        fi
    else
        echo -e "${RED}[FAIL] Failed to download${NC} $IPK"
        FAILED_PKGS="$FAILED_PKGS $IPK"
    fi
done

# گزارش خطاها
if [ -n "$FAILED_PKGS" ]; then
    echo -e "${YELLOW}>>> These packages failed:${NC} $FAILED_PKGS"
else
    echo -e "${GREEN}All packages installed successfully.${NC}"
fi

# پاکسازی
rm -f /tmp/*.ipk

# بررسی نصب Passwall
if [ -f "/etc/init.d/passwall" ]; then
    echo -e "${GREEN}Passwall installed successfully!${NC}"
else
    echo -e "${RED}Passwall not installed!${NC}"
fi
