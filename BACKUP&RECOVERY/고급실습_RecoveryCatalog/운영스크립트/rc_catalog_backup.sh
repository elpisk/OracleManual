#!/bin/bash
# =============================================================================
#  rc_catalog_backup.sh  —  Recovery Catalog 3중 보호
#  출처   : 고급 실습 05
#  사용법 : rc_catalog_backup.sh          (rcat 서버에서 실행)
#
#  보호 계층
#    1차  rcat 데이터베이스의 RMAN 백업   → DB 전체 복구 (30~60분)
#    2차  카탈로그 스키마 Data Pump 덤프  → 스키마만 복구 (약 11분)
#    3차  글로벌 스크립트 파일 추출       → 카탈로그 없이 백업 지속
#
#  절대 원칙
#    rcat 의 백업은 nocatalog 로 받는다.
#    자기 자신을 저장소로 쓰면 그것이 사라졌을 때 복구할 수 없다.
# =============================================================================
set -u

export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=rcat
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'

# ---- 환경에 맞게 수정할 값 ----
CATOWNER=rcatowner
SYSPW=oracle_4U
DUMPDIR_OBJ=dp_rcat                    # 디렉터리 객체 이름
DUMPDIR=/u03/dpdump_rcat               # 그 실제 경로
SCRIPTS="gs_daily_incr gs_weekly_full gs_archive_only gs_maint_obsolete gs_validate_full"
FALLBACK=/home/oracle/rcadm/fallback
REMOTE_HOSTS="oel7v9r1"                # 폴백 파일을 배포할 대상
DUMP_KEEP=14                           # 덤프 보관 세대
MAILTO="dba-team@example.com"
# --------------------------------

D=$(date +%Y%m%d)
LOG=/home/oracle/rcadm/log/rcat_protect_$D.log
mkdir -p "$(dirname "$LOG")" "$FALLBACK" "$DUMPDIR"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

log "=== 카탈로그 보호 작업 시작 ==="

# ---------------------------------------------------------------------------
# 사전 점검 : rcat 이 ARCHIVELOG 인가
#   NOARCHIVELOG 면 시점 복구가 불가능해 통합 이력을 잃을 수 있다.
# ---------------------------------------------------------------------------
LOGMODE=$(sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT log_mode FROM v$database;
EXIT
EOF
)
log "rcat log_mode = $LOGMODE"
if ! echo "$LOGMODE" | grep -q ARCHIVELOG; then
  log "[WARN] rcat is in NOARCHIVELOG mode - point-in-time recovery unavailable"
fi

# ---------------------------------------------------------------------------
# 1차 : rcat 데이터베이스 백업 (반드시 nocatalog)
# ---------------------------------------------------------------------------
log "--- 1차 : RMAN 백업 ---"
rman target / nocatalog >> "$LOG" 2>&1 << 'EOF'
BACKUP DATABASE PLUS ARCHIVELOG TAG 'RCAT_FULL' DELETE INPUT;
DELETE NOPROMPT OBSOLETE;
EOF

# ---------------------------------------------------------------------------
# 2차 : 카탈로그 스키마 논리 백업
#   flashback_time 을 지정하는 이유 : 카탈로그는 테이블 간 참조가 많다.
#   덤프 도중 백업 작업이 돌면 테이블별 시점이 어긋난다.
# ---------------------------------------------------------------------------
log "--- 2차 : 스키마 Data Pump ---"
expdp system/$SYSPW directory=$DUMPDIR_OBJ \
  dumpfile=${CATOWNER}_${D}.dmp logfile=${CATOWNER}_${D}.log \
  schemas=$CATOWNER flashback_time=systimestamp >> "$LOG" 2>&1

# ---------------------------------------------------------------------------
# 3차 : 글로벌 스크립트 추출과 배포
# ---------------------------------------------------------------------------
log "--- 3차 : 글로벌 스크립트 추출 ---"
for S in $SCRIPTS; do
  rman catalog ${CATOWNER}/${SYSPW}@rcat >> "$LOG" 2>&1 << EOF
PRINT GLOBAL SCRIPT $S TO FILE '$FALLBACK/$S.rman';
EXIT
EOF
done
CNT=$(ls -1 "$FALLBACK"/*.rman 2>/dev/null | wc -l)
log "exported $CNT scripts"

for H in $REMOTE_HOSTS; do
  scp -q "$FALLBACK"/*.rman oracle@${H}:${FALLBACK}/ >> "$LOG" 2>&1 \
    && log "distributed to $H" \
    || log "[WARN] distribution to $H failed"
done

# ---------------------------------------------------------------------------
# DBID 목록 갱신 (컨트롤파일 유실 시 필수)
# ---------------------------------------------------------------------------
log "--- DBID 목록 갱신 ---"
{
  echo "# generated $(date '+%Y-%m-%d %H:%M:%S')"
  sqlplus -s rc_report/${SYSPW}@rcat << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT RPAD(name,10) || ' DBID = ' || dbid FROM rc_database ORDER BY name;
EXIT
EOF
  sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT RPAD(name,10) || ' DBID = ' || dbid || '   (catalog db)' FROM v$database;
EXIT
EOF
} > /home/oracle/rcadm/DBID_LIST.txt
cat /home/oracle/rcadm/DBID_LIST.txt >> "$LOG"

# ---------------------------------------------------------------------------
# 판정
# ---------------------------------------------------------------------------
if grep -qE 'ORA-[0-9]{5}|RMAN-[0-9]{5}' "$LOG"; then
  log "[FAIL] errors detected"
  grep -E 'ORA-[0-9]{5}|RMAN-[0-9]{5}' "$LOG" | head -20
  mailx -s "[FAIL] catalog protection $D" "$MAILTO" < "$LOG"
  exit 1
fi

# ---------------------------------------------------------------------------
# 보관 세대 정리
# ---------------------------------------------------------------------------
ls -1t "$DUMPDIR"/${CATOWNER}_*.dmp 2>/dev/null | tail -n +$((DUMP_KEEP+1)) \
  | xargs -r rm -f

log "[OK] catalog protection completed"
exit 0

# =============================================================================
#  복구 시 참조 — 상세 절차는 dr_drill_runbook.md 와
#  고급 실습 05의 RUNBOOK_catalog_recovery.md 를 볼 것
#
#  스키마만 유실 (권장 경로, 약 11분)
#    impdp system/<pw> directory=dp_rcat \
#      dumpfile=rcatowner_<최신날짜>.dmp schemas=rcatowner
#    @?/rdbms/admin/utlrp.sql
#    → 각 대상 DB에서 RESYNC CATALOG
#
#  rcat DB 전체 유실 (약 40분)
#    rman target /
#    STARTUP NOMOUNT;
#    SET DBID <DBID_LIST.txt 의 rcat 값>;
#    RESTORE SPFILE FROM AUTOBACKUP;
#    SHUTDOWN IMMEDIATE; STARTUP NOMOUNT;
#    RESTORE CONTROLFILE FROM AUTOBACKUP;
#    ALTER DATABASE MOUNT; RESTORE DATABASE; RECOVER DATABASE;
#    ALTER DATABASE OPEN RESETLOGS;
#    → 각 대상 DB에서 RESYNC CATALOG
# =============================================================================
