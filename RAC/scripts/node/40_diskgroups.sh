#!/bin/bash
# ============================================================================
#  40_diskgroups.sh — +DATA / +FRA 디스크그룹 생성
#  GI 설치에서는 +CRS 만 만들어진다. DBCA 전에 두 개를 더 만든다.
#
#    첫 번째 노드에서 grid 계정으로:  bash 40_diskgroups.sh create
#    두 번째 노드에서 grid 계정으로:  bash 40_diskgroups.sh mount
#    확인:                            bash 40_diskgroups.sh check
#
#  CREATE DISKGROUP 은 실행한 ASM 인스턴스에만 마운트한다.
#  다른 노드에서는 ALTER DISKGROUP ... MOUNT 를 해 줘야 한다.
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
. "$CFG"
[ "$(id -un)" = "grid" ] || { echo "grid 계정으로 실행한다."; exit 1; }
SQL="${GRID_HOME}/bin/sqlplus -s / as sysasm"

do_check() {
  $SQL <<'EOS'
set lines 160 pages 60 feedback on
col path for a26
col name for a10
prompt --- 디스크 후보 (CANDIDATE 여야 디스크그룹에 넣을 수 있다) ---
select path, header_status, total_mb from v$asm_disk order by path;
prompt --- 디스크그룹 (양 노드) ---
select inst_id, name, state, type, total_mb, free_mb
  from gv$asm_diskgroup order by name, inst_id;
exit
EOS
}

do_create() {
  echo "=== 생성 전 상태 ==="
  do_check
  echo "=== +${DG_DATA} / +${DG_FRA} 생성 ==="
  $SQL <<EOS
set echo on
whenever sqlerror continue
create diskgroup ${DG_DATA} external redundancy
  disk ${DG_DATA_DISKS}
  attribute 'compatible.asm'='${ASM_COMPATIBLE}','compatible.rdbms'='${ASM_COMPATIBLE}';
create diskgroup ${DG_FRA} external redundancy
  disk ${DG_FRA_DISKS}
  attribute 'compatible.asm'='${ASM_COMPATIBLE}','compatible.rdbms'='${ASM_COMPATIBLE}';
exit
EOS
  echo
  echo "이제 다른 노드에서:  bash 40_diskgroups.sh mount"
}

do_mount() {
  echo "=== 이 노드에서 마운트 ==="
  $SQL <<EOS
set echo on
whenever sqlerror continue
alter diskgroup ${DG_DATA} mount;
alter diskgroup ${DG_FRA} mount;
exit
EOS
  do_check
  echo
  echo "이후 기동·정지는 Clusterware 자원으로 다룬다:"
  echo "  srvctl start|stop diskgroup -diskgroup ${DG_DATA}"
}

case "${1:-check}" in
  create) do_create ;;
  mount)  do_mount ;;
  check)  do_check ;;
  *) echo "사용법: bash 40_diskgroups.sh {create|mount|check}"; exit 1 ;;
esac
