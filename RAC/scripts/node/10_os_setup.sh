#!/bin/bash
# ============================================================================
#  10_os_setup.sh — RAC 노드 OS 설정
#  사용법: sudo bash 10_os_setup.sh <노드번호 1|2>
#  재실행 안전 — 이미 되어 있는 항목은 건너뛴다.
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
[ -f "$CFG" ] || { echo "config.env 를 찾지 못했다: $CFG"; exit 1; }
. "$CFG"

N="${1:-}"
case "$N" in
  1) HOST=$NODE1_NAME; PUB=$NODE1_PUB; PRV=$NODE1_PRIV ;;
  2) HOST=$NODE2_NAME; PUB=$NODE2_PUB; PRV=$NODE2_PRIV ;;
  *) echo "사용법: sudo bash 10_os_setup.sh <1|2>"; exit 1 ;;
esac
[ "$(id -u)" -eq 0 ] || { echo "root 로 실행한다."; exit 1; }

echo "########## [1] 호스트명 ##########"
hostnamectl set-hostname ${HOST}.${DOMAIN}
hostname

echo "########## [2] 인터페이스 식별 ##########"
# 공용 NIC = 지금 공용 대역을 물고 있는 것.
# 이름 정렬로 고르면 ens160 이 ens33 보다 앞서 나와 뒤바뀐다 — 실제 주소로 판별한다.
OCT3=$(echo "$PUB_SUBNET" | cut -d. -f1-3)
PUBIF=$(ip -o -4 addr show | awk -v p="^${OCT3}\." '$4 ~ p {print $2}' | head -1)
if [ -z "$PUBIF" ]; then
  # 이미 고정 IP 로 바꾼 뒤 재실행하는 경우 ifcfg 에서 찾는다
  PUBIF=$(grep -l "IPADDR=${PUB}" /etc/sysconfig/network-scripts/ifcfg-* 2>/dev/null \
          | head -1 | sed 's/.*ifcfg-//')
fi
[ -n "$PUBIF" ] || { echo "공용 인터페이스를 찾지 못했다. ip -o -4 addr show 로 확인한다."; exit 1; }
PRVIF=$(ls /sys/class/net | grep -E '^(en|eth)' | grep -v "^${PUBIF}$" | head -1)
[ -n "$PRVIF" ] || { echo "사설 인터페이스가 없다. vmx 의 ethernet1 설정을 확인한다."; exit 1; }
echo "  공용 $PUBIF -> $PUB"
echo "  사설 $PRVIF -> $PRV"

echo "########## [3] 고정 IP ##########"
cat > /etc/sysconfig/network-scripts/ifcfg-${PUBIF} <<EOC
TYPE=Ethernet
BOOTPROTO=none
NAME=${PUBIF}
DEVICE=${PUBIF}
ONBOOT=yes
IPADDR=${PUB}
PREFIX=${PUB_PREFIX}
GATEWAY=${PUB_GATEWAY}
DEFROUTE=yes
IPV6INIT=no
EOC
cat > /etc/sysconfig/network-scripts/ifcfg-${PRVIF} <<EOC
TYPE=Ethernet
BOOTPROTO=none
NAME=${PRVIF}
DEVICE=${PRVIF}
ONBOOT=yes
IPADDR=${PRV}
PREFIX=${PUB_PREFIX}
DEFROUTE=no
IPV6INIT=no
EOC
echo "  ifcfg 작성 완료 (적용은 재부팅 또는 nmcli 로)"

echo "########## [4] /etc/hosts ##########"
cp -n /etc/hosts /etc/hosts.orig 2>/dev/null
cat > /etc/hosts <<EOC
127.0.0.1   localhost localhost.${DOMAIN}
::1         localhost localhost.${DOMAIN}

### Public
${NODE1_PUB}  ${NODE1_NAME}.${DOMAIN}  ${NODE1_NAME}
${NODE2_PUB}  ${NODE2_NAME}.${DOMAIN}  ${NODE2_NAME}

### Virtual IP
${NODE1_VIP}  ${NODE1_NAME}-vip.${DOMAIN}  ${NODE1_NAME}-vip
${NODE2_VIP}  ${NODE2_NAME}-vip.${DOMAIN}  ${NODE2_NAME}-vip

### Private Interconnect
${NODE1_PRIV}  ${NODE1_NAME}-priv.${DOMAIN}  ${NODE1_NAME}-priv
${NODE2_PRIV}  ${NODE2_NAME}-priv.${DOMAIN}  ${NODE2_NAME}-priv

### SCAN
${SCAN_IP}  ${SCAN_NAME}.${DOMAIN}  ${SCAN_NAME}
EOC
echo "  $(grep -c . /etc/hosts) 줄"

echo "########## [5] 방화벽 · SELinux · 불필요 서비스 ##########"
for s in firewalld libvirtd avahi-daemon; do
  systemctl stop $s 2>/dev/null; systemctl disable $s 2>/dev/null
done
setenforce 0 2>/dev/null
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
echo "  firewalld=$(systemctl is-active firewalld 2>&1) $(grep ^SELINUX= /etc/selinux/config)"
# avahi 는 169.254.0.0/16 을 쓴다 — GI 의 HAIP 대역과 겹쳐 충돌할 수 있다

echo "########## [6] 그룹과 사용자 ##########"
IFS='|' read -ra GS <<< "$GROUPS_SPEC"
for g in "${GS[@]}"; do
  set -- $g
  getent group $2 >/dev/null || groupadd -g $1 $2
done
usermod -g oinstall -G dba,oper,asmdba,backupdba,dgdba,kmdba,racdba oracle
usermod -g oinstall -G asmadmin,asmdba,asmoper,dba              grid
id oracle; id grid
# 기본 그룹이 oinstall 이어야 한다. 인벤토리 그룹과 다르면 INS-13013 이 난다.

echo "########## [7] 디렉터리 ##########"
mkdir -p "$GRID_HOME" "$GRID_BASE" "$ORA_BASE" "$INVENTORY"
chown -R oracle:oinstall "$ORA_BASE"
chown -R grid:oinstall   "$(dirname "$GRID_HOME")" "$GRID_BASE" "$INVENTORY"
chown    grid:oinstall   /u01/app /u01
chmod -R 775 /u01
ls -ld "$GRID_HOME" "$GRID_BASE" "$ORA_BASE" "$INVENTORY"

echo "########## [8] 커널 파라미터 ##########"
grep -q "^# RAC lab" /etc/sysctl.conf || cat >> /etc/sysctl.conf <<'EOC'

# RAC lab
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
EOC
sysctl -p >/dev/null 2>&1
# rp_filter 2(느슨) 가 중요하다. 1(엄격)이면 인터커넥트 패킷이 커널에서 버려질 수 있다.
echo "  file-max=$(sysctl -n fs.file-max) rp_filter=$(sysctl -n net.ipv4.conf.all.rp_filter)"

echo "########## [9] 리소스 한도 ##########"
grep -q "^# RAC lab" /etc/security/limits.conf || cat >> /etc/security/limits.conf <<'EOC'

# RAC lab
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft nproc 16384
oracle hard nproc 16384
oracle soft stack 10240
oracle hard stack 32768
oracle soft memlock 134217728
oracle hard memlock 134217728
grid soft nofile 1024
grid hard nofile 65536
grid soft nproc 16384
grid hard nproc 16384
grid soft stack 10240
grid hard stack 32768
grid soft memlock 134217728
grid hard memlock 134217728
EOC
echo "  limits.conf 반영"

echo "########## [10] grid 계정 환경 변수 ##########"
cat > /home/grid/.bash_profile <<EOC
[ -f /etc/bashrc ] && . /etc/bashrc
umask 022
export ORACLE_BASE=${GRID_BASE}
export ORACLE_HOME=${GRID_HOME}
export ORACLE_SID=+ASM${N}
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib
EOC
chown grid:oinstall /home/grid/.bash_profile
echo "  작성 완료"

echo "########## 완료 ##########"
echo "hostname=$(hostname)  pub=$PUBIF/$PUB  priv=$PRVIF/$PRV"
echo
echo "IP 를 적용하려면 재부팅한다. 두 노드를 동시에 만지지 않는다 —"
echo "링크드 클론은 DHCP 임대를 물려받아 같은 주소를 잡는 일이 있다."
echo "한 노드가 자리를 잡은 뒤 다음 노드를 처리한다."
