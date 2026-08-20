#!/bin/bash
# =============================================================================
#  rc_backup_framework.sh  —  글로벌 Stored Script 기반 백업 실행기
#  출처   : 고급 실습 03
#  사용법 : rc_backup_framework.sh <ORACLE_SID> <글로벌스크립트명> [태그접두어]
#  예     : rc_backup_framework.sh orcl gs_daily_incr ORCL
#
#  이 스크립트가 서버에 배포하는 유일한 파일이다.
#  백업 절차 자체는 Recovery Catalog 의 글로벌 스크립트에 있다.
#
#  종료 코드 : 0 정상 / 1 실패 또는 폴백 수행 / 2 사전 점검 실패로 미수행
# =============================================================================
set -u

if [ $# -lt 2 ]; then
  echo "usage: $0 <ORACLE_SID> <global_script> [tag_prefix]"
  exit 2
fi

SID=$1
SCRIPT=$2
PREFIX=${3:-$(echo "$1" | tr 'a-z' 'A-Z')}

export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=$SID
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'

# ---- 환경에 맞게 수정할 값 ----
CATALOG="rcatowner/oracle_4U@rcat"     # 운영에서는 외부 비밀번호 저장소 사용 권장
MAILTO="dba-team@example.com"
BASE=/home/oracle/rcadm
BKROOT=/backup
# --------------------------------

DBNAME=$(echo "$SID" | tr 'a-z' 'A-Z')
D=$(date +%Y%m%d_%H%M)
LOGDIR=$BASE/log
LOG=$LOGDIR/${SID}_${SCRIPT}_${D}.log
mkdir -p "$LOGDIR"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

# ---------------------------------------------------------------------------
# 사전 점검 1 : 인스턴스 기동 여부
# ---------------------------------------------------------------------------
if ! ps -ef | grep -q "[o]ra_pmon_${SID}"; then
  log "[FATAL] instance $SID is not running"
  mailx -s "[FATAL] backup abort - $SID down" "$MAILTO" < "$LOG"
  exit 2
fi

# ---------------------------------------------------------------------------
# 사전 점검 2 : 백업 경로 존재 (ORA-19504 / ORA-27040 재발 방지)
# ---------------------------------------------------------------------------
if [ ! -d "$BKROOT/$DBNAME" ]; then
  log "[FATAL] backup directory $BKROOT/$DBNAME not found"
  mailx -s "[FATAL] backup abort - path missing $DBNAME" "$MAILTO" < "$LOG"
  exit 2
fi
if ! touch "$BKROOT/$DBNAME/.wtest_$$" 2>/dev/null; then
  log "[FATAL] $BKROOT/$DBNAME is not writable"
  mailx -s "[FATAL] backup abort - path not writable $DBNAME" "$MAILTO" < "$LOG"
  exit 2
fi
rm -f "$BKROOT/$DBNAME/.wtest_$$"

# ---------------------------------------------------------------------------
# 사전 점검 3 : 여유 공간
# ---------------------------------------------------------------------------
USEPCT=$(df -P "$BKROOT" | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$USEPCT" -ge 90 ]; then
  log "[FATAL] $BKROOT usage ${USEPCT}% - refusing to start"
  mailx -s "[FATAL] backup abort - disk ${USEPCT}% ($SID)" "$MAILTO" < "$LOG"
  exit 2
elif [ "$USEPCT" -ge 80 ]; then
  log "[WARN] $BKROOT usage ${USEPCT}%"
fi

# ---------------------------------------------------------------------------
# 사전 점검 4 : 카탈로그 접속. 실패 시 폴백 (RMAN-06171 대비)
# ---------------------------------------------------------------------------
if ! echo "exit" | rman target / catalog $CATALOG > /tmp/cat_$$.log 2>&1; then
  log "[WARN] recovery catalog unreachable - entering fallback mode"
  cat /tmp/cat_$$.log >> "$LOG"
  rm -f /tmp/cat_$$.log
  FB="$BASE/fallback/${SCRIPT}_${DBNAME}.rman"
  if [ -f "$FB" ]; then
    rman target / nocatalog @"$FB" >> "$LOG" 2>&1
    log "[INFO] fallback executed - RESYNC CATALOG required after recovery"
    mailx -s "[WARN] backup ran in fallback mode - $SID" "$MAILTO" < "$LOG"
    exit 1
  fi
  log "[FATAL] catalog down and no fallback script at $FB"
  mailx -s "[FATAL] catalog down, no fallback - $SID" "$MAILTO" < "$LOG"
  exit 2
fi
rm -f /tmp/cat_$$.log

# ---------------------------------------------------------------------------
# 실행
# ---------------------------------------------------------------------------
log "=== $SID / $SCRIPT / prefix=$PREFIX ==="

rman target / catalog $CATALOG >> "$LOG" 2>&1 << EOF
RUN { EXECUTE GLOBAL SCRIPT $SCRIPT USING '$PREFIX'; }
EXIT
EOF

# ---------------------------------------------------------------------------
# 판정 — 종료 코드가 아니라 로그 내용으로 한다
# ---------------------------------------------------------------------------
if grep -qE 'RMAN-[0-9]{5}|ORA-[0-9]{5}' "$LOG"; then
  log "[FAIL] errors found"
  grep -E 'RMAN-[0-9]{5}|ORA-[0-9]{5}' "$LOG" | head -20
  mailx -s "[FAIL] RMAN backup $SID / $SCRIPT" "$MAILTO" < "$LOG"
  exit 1
fi

case "$SCRIPT" in
  *backup*|*incr*|*full*|*archive*)
    if ! grep -q 'Finished backup' "$LOG"; then
      log "[FAIL] no completion marker"
      mailx -s "[FAIL] RMAN backup incomplete $SID / $SCRIPT" "$MAILTO" < "$LOG"
      exit 1
    fi ;;
esac

log "[OK] $SID / $SCRIPT completed"
find "$LOGDIR" -name "${SID}_*.log" -mtime +60 -delete
exit 0
