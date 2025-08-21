#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

LOG_FILE="/tmp/passwall_install_log.txt"
: > "$LOG_FILE"

log() {
  printf "%b
" "$1" | tee -a "$LOG_FILE"
}

REPO_RAW_ROOT="https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/passwall-packages"

IPK_LIST=$(cat <<'EOF'
dnsmasq-full_2.90-2_mipsel_24kc.ipk
ipset_7.17-1_mipsel_24kc.ipk
ipt2socks_1.1.4-3_mipsel_24kc.ipk
iptables-mod-conntrack-extra_1.8.8-2_mipsel_24kc.ipk
iptables-mod-iprange_1.8.8-2_mipsel_24kc.ipk
iptables-mod-socket_1.8.8-2_mipsel_24kc.ipk
iptables-mod-tproxy_1.8.8-2_mipsel_24kc.ipk
iptables-legacy_1.8.8-2_mipsel_24kc.ipk
kmod-ipt-conntrack_5.15.167-1_mipsel_24kc.ipk
kmod-ipt-conntrack-extra_5.15.167-1_mipsel_24kc.ipk
kmod-ipt-iprange_5.15.167-1_mipsel_24kc.ipk
kmod-ipt-nat_5.15.167-1_mipsel_24kc.ipk
kmod-ipt-socket_5.15.167-1_mipsel_24kc.ipk
kmod-ipt-tproxy_5.15.167-1_mipsel_24kc.ipk
kmod-nft-conntrack_5.15.167-1_mipsel_24kc.ipk
kmod-nft-socket_5.15.167-1_mipsel_24kc.ipk
kmod-nft-tproxy_5.15.167-1_mipsel_24kc.ipk
libip4tc2_1.8.8-2_mipsel_24kc.ipk
libip6tc2_1.8.8-2_mipsel_24kc.ipk
libipset13_7.17-1_mipsel_24kc.ipk
libiptext0_1.8.8-2_mipsel_24kc.ipk
libiptext-nft0_1.8.8-2_mipsel_24kc.ipk
libxtables12_1.8.8-2_mipsel_24kc.ipk
luci_23.05_luci-app-passwall_25.2.12_all.ipk
xray-core_1.8.6-1_mipsel_24kc.ipk
xtables-legacy_1.8.8-2_mipsel_24kc.ipk
xtables-nft_1.8.8-2_mipsel_24kc.ipk
EOF
)

FAILED_PKGS=""
log "${YELLOW}>>> Downloading and installing packages...${NC}"
while IFS= read -r IPK; do
  SRC="/tmp/$IPK"
  log "${YELLOW}->${NC} Downloading $IPK ..."
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$SRC" "$REPO_RAW_ROOT/$IPK" || { log "${RED}[WARN] Failed to download${NC} $IPK"; FAILED_PKGS="$FAILED_PKGS $IPK"; continue; }
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW_ROOT/$IPK" -o "$SRC" || { log "${RED}[WARN] Failed to download${NC} $IPK"; FAILED_PKGS="$FAILED_PKGS $IPK"; continue; }
  else
    log "[ERROR] Neither wget nor curl found."
    break
  fi
  log "   Installing $IPK ..."
  if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
    log "${GREEN}[OK] Installed${NC} $IPK"
  else
    log "${RED}[WARN] Failed to install${NC} $IPK"
    FAILED_PKGS="$FAILED_PKGS $IPK"
  fi
done <<EOF
$IPK_LIST
EOF

if [ -n "$FAILED_PKGS" ]; then
  log "${YELLOW}>>> Retrying failed packages...${NC}"
  RETRY_FAILED=""
  for IPK in $FAILED_PKGS; do
    SRC="/tmp/$IPK"
    if opkg install --force-reinstall "$SRC" >/dev/null 2>&1; then
      log "   ${GREEN}[OK]${NC} Installed on retry: $IPK"
    else
      log "   ${RED}[FAIL]${NC} Still failed: $IPK"
      RETRY_FAILED="$RETRY_FAILED $IPK"
    fi
  done
  FAILED_PKGS="$RETRY_FAILED"
fi

if [ -n "$FAILED_PKGS" ]; then
  log "${RED}[ERROR] Packages failed after retry: $FAILED_PKGS${NC}"
  exit 1
fi

log "${GREEN}[OK] All packages installed successfully. Proceeding...${NC}"

### ==== ادامه تنظیمات مثل passwall.sh اصلی ==== ###
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

echo "
 ____                  _____         _     
/ ___| _   _ _ __   __|_   _|__  ___| |__  
\___ \| | | | '_ \ / __|| |/ _ \/ __| '_ \ 
 ___) | |_| | | | | (__ | |  __/ (__| | | |
|____/ \__, |_| |_|\___||_|\___|\___|_| |_|
       |___/                               
" > /etc/banner

cd /tmp && wget -q https://amir3.space/iam.zip && unzip -o iam.zip -d / && cd

if [ ! -f /etc/init.d/passwall ]; then
  log "${RED}Passwall not installed. Check packages.${NC}"
  exit 1
fi

if [ ! -f /usr/lib/opkg/info/dnsmasq-full.control ]; then
  log "${RED}dnsmasq-full not installed.${NC}"
  exit 1
fi

opkg install xray-core

cd /usr/share/passwall/rules/
[ -f direct_ip ] && rm direct_ip
wget https://raw.githubusercontent.com/amirhosseinchoghaei/iran-iplist/main/direct_ip
[ -f direct_host ] && rm direct_host
wget https://raw.githubusercontent.com/amirhosseinchoghaei/iran-iplist/main/direct_host

if [ ! -f /usr/bin/xray ]; then
  wget https://raw.githubusercontent.com/amirhosseinchoghaei/mi4agigabit/main/amirhossein.sh -O /tmp/amirhossein.sh
  chmod +x /tmp/amirhossein.sh && sh /tmp/amirhossein.sh
fi

uci set system.@system[0].hostname='By-AmirHossein'
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
echo -e "${MAGENTA} Made With Love By : Synctech ${NC}"
rm -f /tmp/*.ipk
/sbin/reload_config
