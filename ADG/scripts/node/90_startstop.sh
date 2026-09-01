#!/bin/bash
# ============================================================================
#  90_startstop.sh — 랩 기동·정지 (실습 전후에 쓴다)
#    bash 90_startstop.sh up     Primary open, Standby mount+read only, MRP 기동
#    bash 90_startstop.sh down   MRP 정지, 양쪽 shutdown immediate
#    bash 90_startstop.sh mrp on|off
#  기동은 Primary → Standby 순서, 정지는 반대 순서다.
# ============================================================================
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
. "$BASE/config.env"
export ORACLE_BASE=$ORA_BASE ORACLE_HOME=$ORA_HOME
export PATH=$ORACLE_HOME/bin:$PATH

sq() { ORACLE_SID=$1 sqlplus -s / as sysdba <<EOS
set echo on
whenever sqlerror continue
$2
exit
EOS
}

case "${1:-}" in
up)
  ORACLE_SID=$PRI_SID lsnrctl start 2>&1 | tail -2
  sq "$PRI_SID" "startup"
  ORACLE_SID=$STB_SID lsnrctl start 2>&1 | tail -2
  sq "$STB_SID" "startup mount
alter database open read only;
alter database recover managed standby database using current logfile disconnect from session;"
  ;;
down)
  sq "$STB_SID" "alter database recover managed standby database cancel;
shutdown immediate"
  sq "$PRI_SID" "shutdown immediate"
  ;;
mrp)
  case "${2:-}" in
    on)  sq "$STB_SID" "alter database recover managed standby database using current logfile disconnect from session;" ;;
    off) sq "$STB_SID" "alter database recover managed standby database cancel;" ;;
    *) echo "사용법: bash 90_startstop.sh mrp {on|off}"; exit 1 ;;
  esac
  ;;
*) echo "사용법: bash 90_startstop.sh {up|down|mrp on|mrp off}"; exit 1 ;;
esac
