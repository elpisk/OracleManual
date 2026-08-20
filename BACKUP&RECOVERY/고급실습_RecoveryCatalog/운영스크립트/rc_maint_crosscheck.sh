#!/bin/bash
# =============================================================================
#  rc_maint_crosscheck.sh  —  안전장치를 갖춘 정기 정합성 점검·공간 회수
#  출처   : 고급 실습 04
#  사용법 : rc_maint_crosscheck.sh <ORACLE_SID>
#
#  이 실행기가 막는 사고
#    ① 보존 정책이 NONE 이라 아무것도 지워지지 않는 상태를 방치하는 것
#    ② NFS 가 끊긴 상태에서 CROSSCHECK 가 전량을 EXPIRED 로 만들고
#       DELETE EXPIRED 가 유효한 백업 기록을 지우는 것
#    ③ 정리 후 복구 경로가 끊긴 것을 모르고 넘어가는 것
#
#  종료 코드 : 0 정상 / 1 정리 후 복구 경로 이상 / 2 사전 점검 실패로 미수행
# =============================================================================
set -u

[ $# -lt 1 ] && { echo "usage: $0 <ORACLE_SID>"; exit 2; }

SID=$1
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=$SID
export PATH=$ORACLE_HOME/bin:$PATH

# ---- 환경에 맞게 수정할 값 ----
CATALOG="rcatowner/oracle_4U@rcat"
MAILTO="dba-team@example.com"
BKROOT=/backup
EXPIRED_ABORT_PCT=50          # EXPIRED 비율이 이 값 이상이면 중단
# --------------------------------

DBNAME=$(echo "$SID" | tr 'a-z' 'A-Z')
BKDIR=$BKROOT/$DBNAME
LOG=/home/oracle/rcadm/log/maint_${SID}_$(date +%Y%m%d_%H%M).log
mkdir -p "$(dirname "$LOG")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

# ---------------------------------------------------------------------------
# 안전장치 1 : 마운트와 쓰기 가능 여부
#   RMAN 은 "접근 불가"와 "파일 없음"을 구분하지 못한다.
# ---------------------------------------------------------------------------
if ! mountpoint -q "$BKROOT"; then
  log "[ABORT] $BKROOT is not a mountpoint - skipping crosscheck"
  mailx -s "[ABORT] maint skipped - not mounted ($SID)" "$MAILTO" < "$LOG"
  exit 2
fi
if [ ! -d "$BKDIR" ] || ! touch "$BKDIR/.mnt_$$" 2>/dev/null; then
  log "[ABORT] $BKDIR not writable - skipping crosscheck"
  mailx -s "[ABORT] maint skipped - path not writable ($SID)" "$MAILTO" < "$LOG"
  exit 2
fi
rm -f "$BKDIR/.mnt_$$"

# ---------------------------------------------------------------------------
# 안전장치 2 : 보존 정책 확인
# ---------------------------------------------------------------------------
POLICY=$(rman target / catalog $CATALOG 2>/dev/null << 'EOF' | grep 'RETENTION POLICY'
SHOW RETENTION POLICY;
EXIT
EOF
)
log "retention: $POLICY"
if echo "$POLICY" | grep -qi 'TO NONE'; then
  log "[ABORT] retention policy is NONE - nothing will ever become obsolete"
  mailx -s "[ABORT] retention policy NONE ($SID)" "$MAILTO" < "$LOG"
  exit 2
fi
if [ -z "$POLICY" ]; then
  log "[ABORT] cannot read retention policy - catalog unreachable?"
  mailx -s "[ABORT] cannot read retention policy ($SID)" "$MAILTO" < "$LOG"
  exit 2
fi

# ---------------------------------------------------------------------------
# 1단계 : 대조와 목록화 — 지우지 않는다
# ---------------------------------------------------------------------------
log "=== stage 1 : crosscheck and report ==="
rman target / catalog $CATALOG >> "$LOG" 2>&1 << 'EOF'
CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;
LIST EXPIRED BACKUP SUMMARY;
REPORT OBSOLETE;
EXIT
EOF

# ---------------------------------------------------------------------------
# 안전장치 3 : EXPIRED 비율 이상 감지
# ---------------------------------------------------------------------------
TOTAL=$(grep -c 'crosschecked backup piece' "$LOG" || true)
EXPCNT=$(grep -c "found to be 'EXPIRED'" "$LOG" || true)
log "crosschecked=$TOTAL expired=$EXPCNT"
if [ "${TOTAL:-0}" -gt 0 ]; then
  PCT=$(( EXPCNT * 100 / TOTAL ))
  if [ "$PCT" -ge "$EXPIRED_ABORT_PCT" ]; then
    log "[ABORT] EXPIRED ratio ${PCT}% (${EXPCNT}/${TOTAL}) - manual review required"
    log "        저장 장치 접근 문제일 가능성이 높다. DELETE 를 수행하지 않는다."
    mailx -s "[ABORT] abnormal EXPIRED ratio ${PCT}% ($SID)" "$MAILTO" < "$LOG"
    exit 2
  fi
fi

# ---------------------------------------------------------------------------
# 2단계 : 실제 삭제
#   DELETE EXPIRED   기록만 정리한다 (파일은 이미 없다)
#   DELETE OBSOLETE  기록과 파일을 함께 지운다 (공간이 회수된다)
# ---------------------------------------------------------------------------
log "=== stage 2 : delete ==="
rman target / catalog $CATALOG >> "$LOG" 2>&1 << 'EOF'
DELETE NOPROMPT EXPIRED BACKUP;
DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
DELETE NOPROMPT OBSOLETE;
EXIT
EOF

# ---------------------------------------------------------------------------
# 3단계 : 복구 가능성 재확인
# ---------------------------------------------------------------------------
log "=== stage 3 : verify restore path ==="
rman target / catalog $CATALOG >> "$LOG" 2>&1 << 'EOF'
RESTORE DATABASE PREVIEW SUMMARY;
RESTORE ARCHIVELOG ALL PREVIEW SUMMARY;
REPORT NEED BACKUP;
EXIT
EOF

if grep -qE 'RMAN-060(23|25|26)' "$LOG"; then
  log "[FATAL] restore path broken after cleanup"
  grep -E 'RMAN-060(23|25|26)' "$LOG" | head -10
  mailx -s "[FATAL] restore path broken after cleanup ($SID)" "$MAILTO" < "$LOG"
  exit 1
fi

df -h "$BKROOT" >> "$LOG"
log "[OK] maintenance completed for $SID"
find /home/oracle/rcadm/log -name "maint_${SID}_*.log" -mtime +90 -delete
exit 0
