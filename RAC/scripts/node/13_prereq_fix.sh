#!/bin/bash
# ============================================================================
#  13_prereq_fix.sh — runcluvfy 가 잡는 항목을 미리 해소한다.
#  실제 구축에서 걸렸던 다섯 가지를 그대로 처리한다.
#    PRVG-11550  cvuqdisk 패키지 없음
#    PRVG-13606  chronyd 가 외부 시간원과 동기화되지 않음
#    PRVG-1017   ntp.conf 존재
#    PRVG-2064   resolv.conf 에 네임서버 없음
#    PRVG-10048  네임서버가 노드 이름을 해석하지 못함
#    INS-13013   인벤토리 그룹이 설치 사용자 기본 그룹과 다름
#
#  두 노드 모두에서 실행한다. 재실행 안전.
#  사용법: sudo bash 13_prereq_fix.sh
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
. "$CFG"
[ "$(id -u)" -eq 0 ] || { echo "root 로 실행한다."; exit 1; }

echo "########## [1] cvuqdisk 설치 (PRVG-11550) ##########"
if rpm -q cvuqdisk >/dev/null 2>&1; then
  echo "  이미 설치됨: $(rpm -q cvuqdisk)"
else
  RPM=$(ls ${GRID_HOME}/cv/rpm/cvuqdisk*.rpm 2>/dev/null | head -1)
  [ -z "$RPM" ] && RPM=$(ls /tmp/cvuqdisk*.rpm 2>/dev/null | head -1)
  if [ -z "$RPM" ]; then
    echo "  !! cvuqdisk RPM 을 찾지 못했다."
    echo "     Grid 미디어를 푼 노드에서 ${GRID_HOME}/cv/rpm/ 의 RPM 을 /tmp 로 복사한 뒤 다시 실행한다."
  else
    export CVUQDISK_GRP=$INST_GROUP    # 지정하지 않으면 엉뚱한 그룹으로 설치되어 다시 걸린다
    rpm -iv "$RPM" 2>&1 | tail -2
    rpm -q cvuqdisk
  fi
fi

echo "########## [2] 시간 동기 — NTP 제거, CTSS 에 맡긴다 (PRVG-13606 / PRVG-1017) ##########"
# 폐쇄망이라 외부 NTP 에 닿지 않는다. 설정 파일이 남아 있으면 Oracle 이
# "NTP 를 쓰겠다는 뜻"으로 읽어 CTSS 를 활성 모드로 두지 않는다.
systemctl stop chronyd 2>/dev/null; systemctl disable chronyd 2>/dev/null
[ -f /etc/chrony.conf ] && mv -f /etc/chrony.conf /etc/chrony.conf.orig
systemctl stop ntpd 2>/dev/null;    systemctl disable ntpd 2>/dev/null
[ -f /etc/ntp.conf ] && mv -f /etc/ntp.conf /etc/ntp.conf.orig
echo "  chronyd=$(systemctl is-active chronyd 2>&1)  chrony.conf=$(ls /etc/chrony.conf 2>&1 | tail -1)"

echo "########## [3] 이름 해석 — dnsmasq (PRVG-2064 / PRVG-10048) ##########"
# cluvfy 는 "네임서버가 지정되어 있고 그 네임서버가 노드 이름을 풀 수 있을 것"을
# 동시에 요구한다. /etc/hosts 만으로는 앞을, 외부 DNS 로는 뒤를 만족하지 못한다.
# dnsmasq 로 /etc/hosts 를 DNS 로 서비스해 둘 다 만족시킨다.
if ! rpm -q dnsmasq >/dev/null 2>&1; then
  yum -y -q install dnsmasq 2>&1 | tail -2
fi
cat > /etc/dnsmasq.conf <<EOC
# RAC 랩 — /etc/hosts 를 DNS 로 서비스한다.
domain-needed
bogus-priv
local=/${DOMAIN}/
domain=${DOMAIN}
expand-hosts
listen-address=127.0.0.1
bind-interfaces
no-resolv
EOC
# expand-hosts : 짧은 이름에 domain 을 붙여 FQDN 으로도 응답한다
# no-resolv    : resolv.conf 를 상위 DNS 로 읽지 않는다. 빼면 자기 자신을 가리켜 무한 참조가 된다
systemctl enable dnsmasq >/dev/null 2>&1
systemctl restart dnsmasq
sleep 2
echo "  dnsmasq=$(systemctl is-active dnsmasq)"

chattr -i /etc/resolv.conf 2>/dev/null
cat > /etc/resolv.conf <<EOC
search ${DOMAIN}
nameserver 127.0.0.1
EOC
chattr +i /etc/resolv.conf 2>/dev/null   # NetworkManager 가 덮어쓰지 못하게 한다
cat /etc/resolv.conf

echo "  해석 확인:"
for h in $NODE1_NAME $NODE2_NAME ${NODE1_NAME}-vip ${NODE2_NAME}-vip $SCAN_NAME; do
  printf "    %-12s %s\n" "$h" "$(nslookup $h 2>/dev/null | awk '/^Address: /{print $2}' | tail -1)"
done

echo "########## [4] 인벤토리 그룹 (INS-13013) ##########"
# 설치 관리자는 "설치 사용자의 기본 그룹 == 인벤토리 그룹"을 요구한다.
for f in /etc/oraInst.loc ${INVENTORY}/oraInst.loc; do
  [ -f "$f" ] || continue
  cur=$(grep '^inst_group=' "$f" | cut -d= -f2)
  if [ "$cur" != "$INST_GROUP" ]; then
    sed -i "s/^inst_group=.*/inst_group=${INST_GROUP}/" "$f"
    echo "  $f : $cur -> $INST_GROUP"
  else
    echo "  $f : $cur (변경 없음)"
  fi
done
# 백업 파일을 인벤토리 안에 남기면 INS-32050 이 난다. 밖으로 옮긴다.
mkdir -p /root/rac_backup
find "$INVENTORY" -maxdepth 1 -name '*.orig' -o -maxdepth 1 -name '*.bak' 2>/dev/null \
  | while read -r f; do mv -f "$f" /root/rac_backup/ && echo "  백업 이동: $f -> /root/rac_backup/"; done
chown -R grid:${INST_GROUP} "$INVENTORY" 2>/dev/null
chgrp ${INST_GROUP} /etc/oraInst.loc 2>/dev/null; chmod 644 /etc/oraInst.loc 2>/dev/null
echo "  grid 기본그룹=$(id -gn grid)  oracle 기본그룹=$(id -gn oracle)"

echo "########## [5] 메모리 확인 (PRVF-7530) ##########"
MB=$(awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo)
echo "  MemTotal ${MB}MB"
if [ "$MB" -lt 8192 ]; then
  echo "  !! 8GB 미만이다. VM 을 정지하고 vmx 의 memsize 를 9216 으로 올린 뒤 재기동한다."
  echo "     8192 로는 하이퍼바이저 예약분 때문에 요구치에 아슬아슬하게 미달한다."
fi

echo "########## 완료 ##########"
echo "다음: bash 14_cluvfy.sh  (grid 계정, 한 노드에서만)"
