#!/bin/bash
# =============================================================================
#  rc_restore_validate.sh  —  복구 가능성 상시 검증 (L1~L3)
#  출처   : 고급 실습 10
#  사용법 : rc_restore_validate.sh <ORACLE_SID> [레벨:1|2|3]
#  예     : rc_restore_validate.sh orcl 2
#
#  검증 단계
#    L1 메타 검증  복원 경로가 존재하는가      RESTORE PREVIEW        매일
#    L2 읽기 검증  백업 파일이 읽히는가        RESTORE ... VALIDATE   매일
#    L3 논리 검증  블록이 온전한가             VALIDATE CHECK LOGICAL 주간
#
#  각 단계가 놓치는 것
#    L1 통과해도 파일이 손상되었을 수 있다
#    L2 통과해도 블록 내부가 깨졌을 수 있다 (CHECK LOGICAL 없이는)
#    L3 통과해도 실제로 열리지 않을 수 있다 → 분기 훈련(L4)이 필요하다
#
#  종료 코드 : 0 통과 / 1 검증 실패
# =============================================================================
set -u

[ $# -lt 1 ] && { echo "usage: $0 <ORACLE_SID> [1|2|3]"; exit 2; }

SID=$1
LEVEL=${2:-2}

export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=$SID
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'

# ---- 환경에 맞게 수정할 값 ----
CATALOG="rcatowner/oracle_4U@rcat"
MAILTO="dba-team@example.com"
VDIR=/home/oracle/rcadm/verify
# --------------------------------

D=$(date +%Y%m%d_%H%M)
LOG=$VDIR/verify_${SID}_L${LEVEL}_${D}.log
mkdir -p "$VDIR"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

log "=== $SID L$LEVEL 복구 가능성 검증 시작 ==="

# ---------------------------------------------------------------------------
# L1 : 메타 검증 — 복원 경로가 존재하는가
# ---------------------------------------------------------------------------
log "--- L1 : metadata ---"
rman target / catalog $CATALOG >> "$LOG" 2>&1 << 'EOF'
REPORT NEED BACKUP;
REPORT UNRECOVERABLE;
RESTORE DATABASE PREVIEW SUMMARY;
RESTORE ARCHIVELOG ALL PREVIEW SUMMARY;
RESTORE SPFILE PREVIEW;
EXIT
EOF

if grep -qE 'RMAN-060(23|25|26)' "$LOG"; then
  log "[CRIT] L1 실패 : 복원 경로 결손"
  grep -E 'RMAN-060(23|25|26)' "$LOG" | head -10 | tee -a "$LOG"
  log "       원인 후보 : 아카이브 미백업 상태에서 삭제 / 백업 세대 부족"
  log "       조치      : CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES"
  mailx -s "[CRIT] L1 restore path broken ($SID)" "$MAILTO" < "$LOG"
  exit 1
fi

# REPORT UNRECOVERABLE 결과 확인 (NOLOGGING 작업으로 복구 불가해진 파일)
if grep -A5 'need backup due to unrecoverable' "$LOG" | grep -qE '^[0-9]+ '; then
  log "[WARN] L1 : NOLOGGING 으로 복구 불가한 파일이 있다. 즉시 백업 필요"
  mailx -s "[WARN] unrecoverable datafiles ($SID)" "$MAILTO" < "$LOG"
fi

log "[OK] L1 통과"
[ "$LEVEL" = "1" ] && { find "$VDIR" -name 'verify_*.log' -mtime +90 -delete; exit 0; }

# ---------------------------------------------------------------------------
# L2 : 읽기 검증 — 백업 파일이 실제로 읽히는가
#   파일을 만들지 않으므로 운영 중 안전하게 수행할 수 있다
# ---------------------------------------------------------------------------
log "--- L2 : readability ---"
rman target / catalog $CATALOG >> "$LOG" 2>&1 << 'EOF'
RESTORE DATABASE VALIDATE;
RESTORE ARCHIVELOG ALL VALIDATE;
RESTORE SPFILE VALIDATE FROM AUTOBACKUP;
EXIT
EOF

if grep -qE 'ORA-19870|ORA-19501|ORA-19505|RMAN-06172' "$LOG"; then
  log "[CRIT] L2 실패 : 백업 조각을 읽을 수 없다"
  grep -E 'ORA-19870|ORA-19501|ORA-19505|RMAN-06172' "$LOG" | head -10
  log "       조치 : CROSSCHECK 후 EXPIRED 확인. 매체 접근 상태 점검"
  mailx -s "[CRIT] L2 backup unreadable ($SID)" "$MAILTO" < "$LOG"
  exit 1
fi

log "[OK] L2 통과"
[ "$LEVEL" = "2" ] && { find "$VDIR" -name 'verify_*.log' -mtime +90 -delete; exit 0; }

# ---------------------------------------------------------------------------
# L3 : 논리 검증 — 블록이 온전한가
#   데이터파일 전체를 읽으므로 부하가 있다. 주간 야간 수행을 권장한다.
#   MAXCORRUPT 를 설정한 환경에서는 이 단계가 필수다.
# ---------------------------------------------------------------------------
log "--- L3 : logical (block) ---"
rman target / catalog $CATALOG >> "$LOG" 2>&1 << 'EOF'
BACKUP VALIDATE CHECK LOGICAL DATABASE ARCHIVELOG ALL;
EXIT
EOF

CORRUPT=$(sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT COUNT(*) FROM v$database_block_corruption;
EXIT
EOF
)
CORRUPT=$(echo "$CORRUPT" | tr -d ' ')

if [ "${CORRUPT:-0}" -gt 0 ]; then
  log "[CRIT] L3 실패 : 손상 블록 ${CORRUPT}건"
  sqlplus -s / as sysdba >> "$LOG" << 'EOF'
SET LINESIZE 140
SELECT file#, block#, blocks, corruption_change#, corruption_type
FROM   v$database_block_corruption ORDER BY file#, block#;
SELECT DISTINCT e.owner, e.segment_name, e.segment_type
FROM   dba_extents e, v$database_block_corruption c
WHERE  e.file_id = c.file#
AND    c.block# BETWEEN e.block_id AND e.block_id + e.blocks - 1;
EXIT
EOF
  log "       조치 : RMAN> RECOVER CORRUPTION LIST;"
  mailx -s "[CRIT] L3 block corruption ${CORRUPT} ($SID)" "$MAILTO" < "$LOG"
  exit 1
fi

log "[OK] L3 통과 - 손상 블록 없음"
find "$VDIR" -name 'verify_*.log' -mtime +90 -delete
exit 0

# =============================================================================
#  크론 등록 예시
#    # L1+L2 매일 06시
#    0  6 * * * /home/oracle/rcadm/rc_restore_validate.sh orcl  2
#    20 6 * * * /home/oracle/rcadm/rc_restore_validate.sh sales 2
#    # L3 주간 (토요일 야간)
#    0 22 * * 6 /home/oracle/rcadm/rc_restore_validate.sh orcl  3
#    0 23 * * 6 /home/oracle/rcadm/rc_restore_validate.sh sales 3
#
#  L4(실복원 훈련)는 자동화하지 않는다. dr_drill_runbook.md 참조.
# =============================================================================
