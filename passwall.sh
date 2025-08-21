#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo "Running as root..."
sleep 2
clear

uci set system.@system[0].zonename='Asia/Tehran'
uci set network.wan.peerdns="0"
uci set network.wan6.peerdns="0"
uci set network.wan.dns='1.1.1.1'
uci set network.wan6.dns='2001:4860:4860::8888'
uci set system.@system[0].timezone='<+0330>-3:30'
uci commit system
uci commit network
uci commit
/sbin/reload_config

SNNAP=$(grep -o SNAPSHOT /etc/openwrt_release | sed -n '1p')

if [ "$SNNAP" == "SNAPSHOT" ]; then
    echo -e "${YELLOW} SNAPSHOT Version Detected ! ${NC}"
    rm -f passwalls.sh && wget https://raw.githubusercontent.com/amirhosseinchoghaei/Passwall/main/passwalls.sh && chmod 777 passwalls.sh && sh passwalls.sh
    exit 1
else
    echo -e "${GREEN} Updating Packages ... ${NC}"
fi

opkg update

wget -O passwall.pub https://master.dl.sourceforge.net/project/openwrt-passwall-build/passwall.pub
opkg-key add passwall.pub
> /etc/opkg/customfeeds.conf
read release arch << EOF
$(. /etc/openwrt_release ; echo ${DISTRIB_RELEASE%.*} $DISTRIB_ARCH)
EOF
for feed in passwall_luci passwall_packages passwall2; do
    echo "src/gz $feed https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-$release/$arch/$feed" >> /etc/opkg/customfeeds.conf
done

### Install packages from GitHub Repo ###
REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/passwall-packages"
LOG_FILE="/tmp/passwall_install_log.txt"
: > "$LOG_FILE"
log() { printf "%b
" "$1" | tee -a "$LOG_FILE"; }

IPK_LIST=$(cat <<'EOF'
dnsmasq-full_2.90-2_mipsel_24kc.ipk
unzip_6.0-8_mipsel_24kc.ipk
luci-app-passwall_2.25.12_all.ipk
ipset_7.17-1_mipsel_24kc.ipk
ipt2socks_1.1.3-1_mipsel_24kc.ipk
iptables_1.8.8-2_mipsel_24kc.ipk
iptables-legacy_1.8.8-2_mipsel_24kc.ipk
iptables-mod-conntrack-extra_1.8.8-2_mipsel_24kc.ipk
iptables-mod-iprange_1.8.8-2_mipsel_24kc.ipk
iptables-mod-socket_1.8.8-2_mipsel_24kc.ipk
iptables-mod-tproxy_1.8.8-2_mipsel_24kc.ipk
iptables-zz-legacy_1.8.8-2_mipsel_24kc.ipk
xtables-legacy_1.8.8-2_mipsel_24kc.ipk
xtables-nft_1.8.8-2_mipsel_24kc.ipk
libiptext-nft_1.8.8-2_mipsel_24kc.ipk
libiptext0_1.8.8-2_mipsel_24kc.ipk
libip6tc2_1.8.8-2_mipsel_24kc.ipk
libip4tc2_1.8.8-2_mipsel_24kc.ipk
libxtables12_1.8.8-2_mipsel_24kc.ipk
kmod-ipt-nat_5.15.167-1_mipsel_24kc.ipk
kmod-nft-socket_5.15.167-1_mipsel_24kc.ipk
kmod-nft-tproxy_5.15.167-1_mipsel_24kc.ipk
kmod-nf-socket_5.15.167-1_mipsel_24kc.ipk
kmod-nf-tproxy_5.15.167-1_mipsel_24kc.ipk
kmod-ipt-socket_5.15.167-1_mipsel_24kc.ipk
kmod-ipt-tproxy_5.15.167-1_mipsel_24kc.ipk
kmod-ipt-conntrack-extra_5.15.167-1_mipsel_24kc.ipk
kmod-ipt-iprange_5.15.167-1_mipsel_24kc.ipk
kmod-nf-conntrack_5.15.167-1_mipsel_24kc.ipk
kmod-nf-conntrack-extra_5.15.167-1_mipsel_24kc.ipk
kmod-nf-compat_5.15.167-1_mipsel_24kc.ipk
xray-core_1.8.8-1_mipsel_24kc.ipk
EOF
)

FAILED_PKGS=""
opkg remove dnsmasq

for IPK in $IPK_LIST; do
    SRC="/tmp/$IPK"
    log "${YELLOW}->${NC} Downloading $IPK ..."
    if command -v wget >/dev/null 2>&1; then
        wget -qO "$SRC" "$REPO_RAW_ROOT/$IPK" || { log "${RED}[WARN] Failed to download${NC} $IPK"; FAILED_PKGS="$FAILED_PKGS $IPK"; continue; }
    else
        curl -fsSL "$REPO_RAW_ROOT/$IPK" -o "$SRC" || { log "${RED}[WARN] Failed to download${NC} $IPK"; FAILED_PKGS="$FAILED_PKGS $IPK"; continue; }
    fi
    log "   Installing $IPK ..."
    if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
        log "${GREEN}[OK] Installed${NC} $IPK"
    else
        log "${RED}[WARN] Failed to install${NC} $IPK"
        FAILED_PKGS="$FAILED_PKGS $IPK"
    fi
done

rm -f /tmp/*.ipk

if [ -n "$FAILED_PKGS" ]; then
    log "${RED}Some packages failed to install:${NC} $FAILED_PKGS"
fi

>/etc/banner
echo "
 ____                  _____         _
/ ___| _   _ _ __   __|_   _|__  ___| |__
\___ \| | | | '_ \ / __|| |/ _ \/ __| '_ \
 ___) | |_| | | | | (__ | |  __/ (__| | | |
|____/ \__, |_| |_|\___||_|\___|\___|_| |_|
       |___/
" >> /etc/banner

cd /tmp
wget -q https://amir3.space/iam.zip
unzip -o iam.zip -d /
cd

RESULT=$(ls /etc/init.d/passwall 2>/dev/null)
if [ "$RESULT" == "/etc/init.d/passwall" ]; then
    echo -e "${GREEN} Passwall Installed successfully ! ${NC}"
else
    echo -e "${RED} Can not Download Packages ... Check your internet Connection . ${NC}"
    exit 1
fi

DNS=$(ls /usr/lib/opkg/info/dnsmasq-full.control 2>/dev/null)
if [ "$DNS" == "/usr/lib/opkg/info/dnsmasq-full.control" ]; then
    echo -e "${GREEN} dnsmaq-full Installed successfully ! ${NC}"
else
    echo -e "${RED} Package : dnsmasq-full not installed ! (Bad internet connection .) ${NC}"
    exit 1
fi

opkg install xray-core

cd /usr/share/passwall/rules/
[ -f direct_ip ] && rm direct_ip || echo "Stage 1 Passed"
wget https://raw.githubusercontent.com/amirhosseinchoghaei/iran-iplist/main/direct_ip
sleep 3

[ -f direct_host ] && rm direct_host || echo "Stage 2 Passed"
wget https://raw.githubusercontent.com/amirhosseinchoghaei/iran-iplist/main/direct_host

RESULT=$(ls direct_ip 2>/dev/null)
if [ "$RESULT" == "direct_ip" ]; then
    echo -e "${GREEN}IRAN IP BYPASS Successfull !${NC}"
else
    echo -e "${RED}INTERNET CONNECTION ERROR!! Try Again ${NC}"
fi
sleep 5

RESULT=$(ls /usr/bin/xray 2>/dev/null)
if [ "$RESULT" == "/usr/bin/xray" ]; then
    echo -e "${GREEN} Xray OK ! ${NC}"
else
    echo -e "${YELLOW} Installing Xray On Temp Space ! ${NC}"
    rm -f amirhossein.sh && wget https://raw.githubusercontent.com/amirhosseinchoghaei/mi4agigabit/main/amirhossein.sh && chmod 777 amirhossein.sh && sh amirhossein.sh
fi

uci set system.@system[0].zonename='Asia/Tehran'
uci set system.@system[0].timezone='<+0330>-3:30'
uci commit system
uci set system.@system[0].hostname=AGC-Global
uci commit system

uci set passwall.@global[0].tcp_proxy_mode='global'
uci set passwall.@global[0].udp_proxy_mode='global'
uci set passwall.@global_forwarding[0].tcp_no_redir_ports='disable'
uci set passwall.@global_forwarding[0].udp_no_redir_ports='disable'
uci set passwall.@global_forwarding[0].udp_redir_ports='1:65535'
uci set passwall.@global_forwarding[0].tcp_redir_ports='1:65535'
uci set passwall.@global[0].remote_dns='8.8.4.4'
uci set passwall.@global[0].dns_mode='udp'
uci set passwall.@global[0].udp_node='tcp'
uci set passwall.@global[0].chn_list='0'
uci set passwall.@global[0].tcp_proxy_mode='proxy'
uci set passwall.@global[0].udp_proxy_mode='proxy'
uci commit passwall

uci set dhcp.@dnsmasq[0].rebind_domain='www.ebanksepah.ir
my.irancell.ir'
uci commit

echo -e "${YELLOW}** Installation Completed ** ${NC}"
echo -e "${MAGENTA} Made With Love By : AmirHossein ${NC}"

rm passwallx.sh 2> /dev/null
/sbin/reload_config
