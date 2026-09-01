#!/bin/bash
# ============================================================================
#  50_postcheck.sh — 최종 구성 확인
#  가이드의 "C. 최종 구성 체크리스트" 를 그대로 실행한다.
#  어느 노드에서든 root 로 실행한다.
#
#  사용법: sudo bash 50_postcheck.sh
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
. "$CFG"
G="su - grid -c"
O="su - oracle -c"
pass=0; fail=0
chk() { # chk "설명" "기대문자열" "명령"
  out=$(eval "$3" 2>&1)
  if echo "$out" | grep -q "$2"; then printf "  OK   %s\n" "$1"; pass=$((pass+1))
  else printf "  FAIL %s\n" "$1"; echo "$out" | head -4 | sed 's/^/         /'; fail=$((fail+1)); fi
}

echo "========== Clusterware =========="
chk "두 노드 CRS online"        "$NODE2_NAME" "$G '${GRID_HOME}/bin/crsctl check cluster -all'"
chk "노드 멤버십 Active"        "Active"      "$G '${GRID_HOME}/bin/olsnodes -s'"
chk "보팅 파일 3개"             "Located 3"   "$G '${GRID_HOME}/bin/crsctl query css votedisk'"
chk "OCR 무결성"                "succeeded"   "$G '${GRID_HOME}/bin/ocrcheck'"
chk "CTSS Active mode"          "Active mode" "$G '${GRID_HOME}/bin/crsctl check ctss'"
chk "인터페이스 용도 지정"      "cluster_interconnect" "$G '${GRID_HOME}/bin/oifcfg getif'"

echo "========== ASM =========="
chk "디스크그룹 3개 MOUNTED"    "$DG_FRA" \
    "$G '${GRID_HOME}/bin/asmcmd lsdg' "
chk "ASM 인스턴스 기동"         "Started"     "$G '${GRID_HOME}/bin/crsctl status resource ora.asm -t'"

echo "========== 데이터베이스 =========="
chk "두 인스턴스 Open"          "$DB_SID_PREFIX"2 "$O 'srvctl status database -d ${DB_NAME} -v'"
chk "Type=RAC"                  "Type: RAC"   "$O 'srvctl config database -d ${DB_NAME}'"

SQLCHK() { $O "sqlplus -s / as sysdba <<'EOS'
set head off feed off pages 0 lines 200
$1
exit
EOS"; }
chk "GV\$INSTANCE 2행"          "2"  "SQLCHK 'select count(*) from gv\$instance;'"
chk "스레드 2개 OPEN"           "2"  "SQLCHK \"select count(*) from v\\$thread where status='OPEN';\""
chk "UNDO 테이블스페이스 2개"   "2"  "SQLCHK \"select count(*) from dba_tablespaces where contents='UNDO';\""
chk "PDB 양쪽 READ WRITE"       "2"  "SQLCHK \"select count(*) from gv\\$pdbs where name=upper('${PDB_NAME}') and open_mode='READ WRITE';\""
chk "PDB 저장 상태 2건"         "2"  "SQLCHK 'select count(*) from dba_pdb_saved_states;'"

echo "========== SCAN 재지시 =========="
echo "  (아래는 수동 확인 — RAC_SYS_PW 가 설정되어 있어야 한다)"
if [ -n "${RAC_SYS_PW:-}" ]; then
  for i in 1 2 3 4 5 6; do
    r=$($O "sqlplus -s system/${RAC_SYS_PW}@${SCAN_NAME}:${SCAN_PORT}/${PDB_NAME} <<'EOS'
set head off feed off pages 0
select instance_name from v\$instance;
exit
EOS" 2>&1 | tr -d ' \n')
    printf "    접속 %d -> %s\n" "$i" "$r"
  done
  echo "  두 인스턴스로 번갈아 붙어야 정상이다."
else
  echo "    export RAC_SYS_PW='...' 후 다시 실행하면 확인한다."
fi

echo
echo "========== 통과 $pass / 실패 $fail =========="
[ $fail -eq 0 ] || exit 1
