#!/bin/bash
# ============================================================================
#  41_dbca.sh — RAC 데이터베이스 생성
#  oracle 계정으로 첫 번째 노드에서만 실행한다.
#
#    bash 41_dbca.sh create    DBCA 실행 (오래 걸린다 — nohup 권장)
#    bash 41_dbca.sh bg        백그라운드로 띄우고 즉시 반환
#    bash 41_dbca.sh watch     진행률 감시
#    bash 41_dbca.sh pdbstate  PDB 를 전 인스턴스에서 열고 상태 저장
#
#  비밀번호:  export RAC_SYS_PW='...'   (SYS / SYSTEM / PDBADMIN)
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
. "$CFG"
[ "$(id -un)" = "oracle" ] || { echo "oracle 계정으로 실행한다."; exit 1; }
LOG=/home/oracle/dbca_${DB_NAME}.log

build_cmd() {
  : "${RAC_SYS_PW:?환경 변수 RAC_SYS_PW 를 먼저 설정한다}"
  cat <<EOC
${ORA_HOME}/bin/dbca -silent -createDatabase \
  -templateName General_Purpose.dbc \
  -gdbName ${DB_NAME} -sid ${DB_NAME} \
  -sysPassword '${RAC_SYS_PW}' -systemPassword '${RAC_SYS_PW}' \
  -createAsContainerDatabase true -numberOfPDBs 1 -pdbName ${PDB_NAME} \
  -pdbAdminPassword '${RAC_SYS_PW}' \
  -databaseConfigType RAC -nodelist ${NODE1_NAME},${NODE2_NAME} \
  -storageType ASM -diskGroupName ${DG_DATA} -recoveryGroupName ${DG_FRA} \
  -useOMF true -characterSet ${DB_CHARSET} -nationalCharacterSet AL16UTF16 \
  -totalMemory ${DB_MEMORY_MB} -emConfiguration NONE \
  -redoLogFileSize ${REDO_MB} -sampleSchema false \
  -ignorePreReqs
EOC
}
# RAC 전용 인자는 둘이다.
#   -databaseConfigType RAC   클러스터 데이터베이스로 만든다
#   -nodelist                 인스턴스를 배치할 노드. 이 수만큼 리두 스레드와
#                             UNDO 테이블스페이스가 자동 생성된다

case "${1:-create}" in
  create)
    echo "=== DBCA 시작 — 오래 걸린다. 로그: $LOG ==="
    eval "$(build_cmd)" 2>&1 | tee "$LOG" | tail -30
    ;;
  bg)
    echo "=== DBCA 백그라운드 기동 ==="
    nohup bash -c "$(build_cmd)" > "$LOG" 2>&1 &
    echo "  pid=$!  로그: $LOG"
    echo "  진행 확인: bash 41_dbca.sh watch"
    ;;
  watch)
    # SSH 세션을 붙들고 기다리면 세션이 끊길 때 죽은 것처럼 보인다.
    # 폴링할 때마다 상태만 확인하는 편이 안전하다.
    for i in $(seq 0 90); do
      alive=$(pgrep -fc "dbca -silent" || true)
      prog=$(grep -oE '[0-9]+% complete' "$LOG" 2>/dev/null | tail -1)
      printf "[%3d분] 프로세스=%s  %s\n" "$i" "${alive:-0}" "${prog:-대기}"
      [ "${alive:-0}" = "0" ] && [ "$i" -gt 0 ] && break
      sleep 60
    done
    echo "=== 로그 꼬리 ==="
    tail -25 "$LOG" 2>/dev/null
    ;;
  pdbstate)
    # DBCA 직후에는 저장 상태가 없어 재기동하면 PDB 가 MOUNTED 로 남는다.
    # INSTANCES=ALL 을 빼면 접속한 인스턴스에만 적용되어 노드마다 상태가 달라진다.
    ${ORA_HOME}/bin/sqlplus -s / as sysdba <<EOS
set echo on lines 160 pages 60
whenever sqlerror continue
alter pluggable database ${PDB_NAME} open instances=all;
alter pluggable database ${PDB_NAME} save state instances=all;
col name for a12
select inst_id, name, open_mode from gv\$pdbs where name=upper('${PDB_NAME}') order by 1;
col con_name for a12
select con_name, instance_name, state from dba_pdb_saved_states;
exit
EOS
    ;;
  *) echo "사용법: bash 41_dbca.sh {create|bg|watch|pdbstate}"; exit 1 ;;
esac
