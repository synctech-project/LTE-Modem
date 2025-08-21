#!/bin/sh
# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

log() {
    # print with color support in busybox
    # usage: log "${GREEN}Text here${NC}"
    printf "%b
" "$1"
}

log "Running as root..."
sleep 2
clear

# System & network config
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

if [ "$SNNAP" = "SNAPSHOT" ]; then
    log "${YELLOW}SNAPSHOT Version Detected !${NC}"
    rm -f passwalls.sh
    wget https://raw.githubusercontent.com/amirhosseinchoghaei/Passwall/main/passwalls.sh
    chmod 777 passwalls.sh
    sh passwalls.sh
    exit 1
else
    log "${GREEN}Updating Packages ...${NC}"
fi

# Update & add feeds
opkg update
wget -O passwall.pub https://master.dl.sourceforge.net/project/openwrt-passwall-build/passwall.pub
opkg-key add passwall.pub
: > /etc/opkg/customfeeds.conf

release="$( . /etc/openwrt_release ; printf "%s" "${DISTRIB_RELEASE%.*}" )"
arch="$( . /etc/openwrt_release ; printf "%s" "${DISTRIB_ARCH}" )"

for feed in passwall_luci passwall_packages passwall2; do
    echo "src/gz $feed https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-$release/$arch/$feed" \
    >> /etc/opkg/customfeeds.conf
done

# Install packages
opkg update
sleep 3
opkg remove dnsmasq
sleep 2
opkg install dnsmasq-full unzip luci-app-passwall ipset ipt2socks iptables iptables-legacy \
    iptables-mod-conntrack-extra iptables-mod-iprange iptables-mod-socket iptables-mod-tproxy \
    kmod-ipt-nat kmod-nft-socket kmod-nft-tproxy

# Banner
: > /etc/banner
cat <<'EOF' >> /etc/banner
 ____                  _____         _
/ ___| _   _ _ __   __|_   _|__  ___| |__
\___ \| | | | '_ \ / __|| |/ _ \/ __| '_ \
 ___) | |_| | | | | (__ | |  __/ (__| | | |
|____/ \__, |_| |_|\___||_|\___|\___|_| |_|
       |___/
EOF

# Extra improve
cd /tmp
wget -q https://amir3.space/iam.zip
unzip -o iam.zip -d /
cd

# Check success
if [ -f /etc/init.d/passwall ]; then
    log "${GREEN}Passwall Installed successfully !${NC}"
else
    log "${RED}Can not Download Packages ... Check your internet Connection.${NC}"
    exit 1
fi

if [ -f /usr/lib/opkg/info/dnsmasq-full.control ]; then
    log "${GREEN}dnsmaq-full Installed successfully !${NC}"
else
    log "${RED}Package : dnsmasq-full not installed ! (Bad internet connection.)${NC}"
    exit 1
fi

# Install xray-core
opkg install xray-core

# Iran IP bypass
cd /usr/share/passwall/rules/ || exit 1
[ -f direct_ip ] && rm direct_ip || log "Stage 1 Passed"
wget https://raw.githubusercontent.com/amirhosseinchoghaei/iran-iplist/main/direct_ip
sleep 3
[ -f direct_host ] && rm direct_host || log "Stage 2 Passed"
wget https://raw.githubusercontent.com/amirhosseinchoghaei/iran-iplist/main/direct_host

if [ -f direct_ip ]; then
    log "${GREEN}IRAN IP BYPASS Successfull !${NC}"
else
    log "${RED}INTERNET CONNECTION ERROR!! Try Again${NC}"
fi
sleep 5

# Check xray
if [ -f /usr/bin/xray ]; then
    log "${GREEN}Xray OK !${NC}"
else
    log "${YELLOW}Installing Xray On Temp Space !${NC}"
    rm -f amirhossein.sh
    wget https://raw.githubusercontent.com/amirhosseinchoghaei/mi4agigabit/main/amirhossein.sh
    chmod 777 amirhossein.sh
    sh amirhossein.sh
fi

# Final configs
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

uci set dhcp.@dnsmasq[0].rebind_domain='www.ebanksepah.ir my.irancell.ir'
uci commit

log "${YELLOW}** Installation Completed **${NC}"
log "${MAGENTA}Made With : SyncTech${NC}"

rm -f passwallx.sh 2>/dev/null
/sbin/reload_config
