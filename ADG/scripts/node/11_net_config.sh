#!/bin/bash
# ============================================================================
#  11_net_config.sh — Oracle Net 구성
#  tnsnames.ora 는 양쪽 동일, listener.ora 는 서버마다 다르다.
#
#    bash 11_net_config.sh primary    Primary 서버에서
#    bash 11_net_config.sh standby    Standby 서버에서
#    bash 11_net_config.sh verify     TNS 연결 확인 (Primary 에서)
#
#  Standby 리스너의 정적 등록이 특히 중요하다. RMAN DUPLICATE 는 Standby 가
#  NOMOUNT 인 상태에서 접속하는데, 동적 등록은 인스턴스가 열려야 이루어진다.
# ============================================================================
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
. "$BASE/config.env"
export ORACLE_BASE=$ORA_BASE ORACLE_HOME=$ORA_HOME
export PATH=$ORACLE_HOME/bin:$PATH
ADMIN=$ORA_HOME/network/admin
T=$BASE/templates

subst() {
  sed -e "s|@PRI_HOST@|$PRI_HOST|g"       -e "s|@STB_HOST@|$STB_HOST|g" \
      -e "s|@PRI_UNIQUE@|$PRI_UNIQUE|g"   -e "s|@STB_UNIQUE@|$STB_UNIQUE|g" \
      -e "s|@PRI_UNIQUE_UC@|$(echo $PRI_UNIQUE | tr a-z A-Z)|g" \
      -e "s|@STB_UNIQUE_UC@|$(echo $STB_UNIQUE | tr a-z A-Z)|g" \
      -e "s|@PRI_SID@|$PRI_SID|g"         -e "s|@STB_SID@|$STB_SID|g" \
      -e "s|@ORA_HOME@|$ORA_HOME|g"       -e "s|@ORA_BASE@|$ORA_BASE|g" \
      -e "s|@DOMAIN@|$DOMAIN|g"           -e "s|@PORT@|$LISTENER_PORT|g" "$1"
}

deploy() {
  local role=$1 sid=$2 lsnr=$3
  mkdir -p "$ADMIN"
  for f in tnsnames.ora listener.ora; do
    [ -f "$ADMIN/$f" ] && cp -n "$ADMIN/$f" "$ADMIN/$f.orig"
  done
  subst "$T/tnsnames.ora.tmpl" > "$ADMIN/tnsnames.ora"
  subst "$T/$lsnr"             > "$ADMIN/listener.ora"
  echo "  배포: $ADMIN/tnsnames.ora ($(grep -c . "$ADMIN/tnsnames.ora") 줄)"
  echo "  배포: $ADMIN/listener.ora ($(grep -c . "$ADMIN/listener.ora") 줄)"
  export ORACLE_SID=$sid
  lsnrctl stop >/dev/null 2>&1
  lsnrctl start 2>&1 | tail -12
}

case "${1:-}" in
  primary) deploy primary "$PRI_SID" listener_primary.ora.tmpl ;;
  standby) deploy standby "$STB_SID" listener_standby.ora.tmpl ;;
  verify)
    export ORACLE_SID=$PRI_SID
    for s in "$PRI_UNIQUE" "$STB_UNIQUE"; do
      printf "  tnsping %-10s " "$s"
      tnsping "$s" 2>&1 | tail -1
    done
    echo "  두 항목 모두 OK 여야 다음 단계로 간다."
    ;;
  *) echo "사용법: bash 11_net_config.sh {primary|standby|verify}"; exit 1 ;;
esac
