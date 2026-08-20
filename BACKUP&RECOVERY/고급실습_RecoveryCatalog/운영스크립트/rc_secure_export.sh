#!/bin/bash
# =============================================================================
#  rc_secure_export.sh  —  외부 반출용 암호화 백업 생성
#  출처   : 고급 실습 09
#  사용법 : rc_secure_export.sh <ORACLE_SID> <반출식별자> <보관일수>
#  예     : rc_secure_export.sh sales AUDIT_2025Q3 180
#
#  이중 모드(dual mode)로 만든다.
#    - 자사 지갑으로도 열린다
#    - 반출 비밀번호로도 열린다 → 상대방은 지갑 없이 복원 가능
#
#  절대 원칙
#    지갑 파일(*.p12, *.sso)을 백업과 같은 매체에 넣지 않는다.
#    넣는 순간 암호화의 의미가 사라진다.
#
#  종료 코드 : 0 정상 / 1 검증 실패 / 2 사전 점검 실패로 미수행
# =============================================================================
set -u

if [ $# -lt 3 ]; then
  echo "usage: $0 <ORACLE_SID> <label> <keep_days>"
  echo "  예 : $0 sales AUDIT_2025Q3 180"
  exit 2
fi

SID=$1
LABEL=$2
KEEPDAYS=$3
DBNAME=$(echo "$SID" | tr 'a-z' 'A-Z')

export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=$SID
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'

# ---- 환경에 맞게 수정할 값 ----
CATALOG="rcatowner/oracle_4U@rcat"
EXPORT_ROOT=/export
MAILTO="dba-team@example.com"
# --------------------------------

OUTDIR=$EXPORT_ROOT/$LABEL
LOG=/home/oracle/rcadm/log/export_${LABEL}_$(date +%Y%m%d).log
mkdir -p "$OUTDIR" "$(dirname "$LOG")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

# ---------------------------------------------------------------------------
# 사전 점검 1 : 카탈로그 접속 (KEEP 사용을 위해 필요)
# ---------------------------------------------------------------------------
if ! echo exit | rman target / catalog $CATALOG >/dev/null 2>&1; then
  log "[ABORT] recovery catalog required for KEEP option"
  mailx -s "[ABORT] secure export - catalog down ($SID)" "$MAILTO" < "$LOG"
  exit 2
fi

# ---------------------------------------------------------------------------
# 사전 점검 2 : 반출 경로가 FRA 밖인가 (ORA-19811 방지)
# ---------------------------------------------------------------------------
FRA=$(sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT NVL(value,'NONE') FROM v$parameter WHERE name='db_recovery_file_dest';
EXIT
EOF
)
FRA=$(echo "$FRA" | tr -d ' ')
if [ "$FRA" != "NONE" ] && [ -n "$FRA" ]; then
  case "$OUTDIR" in
    ${FRA}*) log "[ABORT] export path is inside FRA ($FRA) - KEEP not allowed"
             exit 2 ;;
  esac
fi

# ---------------------------------------------------------------------------
# 사전 점검 3 : 반출 경로에 지갑 파일이 없어야 한다
# ---------------------------------------------------------------------------
if find "$OUTDIR" \( -name '*.p12' -o -name '*.sso' -o -name '*wallet*' \) \
     2>/dev/null | grep -q .; then
  log "[ABORT] wallet file found in export directory - refusing"
  exit 2
fi

# ---------------------------------------------------------------------------
# 반출 비밀번호 생성 (건별 생성이 원칙. 재사용하지 않는다)
# ---------------------------------------------------------------------------
PW=$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)
echo
echo "=============================================================="
echo " 반출 비밀번호 : $PW"
echo " 이 값은 화면에만 표시된다. 로그에 남기지 않는다."
echo " 백업 매체와 다른 경로로 요청자에게 전달할 것."
echo "=============================================================="
echo

# ---------------------------------------------------------------------------
# 백업 수행 (이중 모드 + KEEP + 복원 지점)
# ---------------------------------------------------------------------------
log "=== secure export start : $DBNAME / $LABEL ==="
rman target / catalog $CATALOG >> "$LOG" 2>&1 << EOF
RUN {
  ALLOCATE CHANNEL c1 DEVICE TYPE DISK FORMAT '$OUTDIR/%d_${LABEL}_%U';
  SET ENCRYPTION ON IDENTIFIED BY "$PW";
  BACKUP AS COMPRESSED BACKUPSET DATABASE
    TAG 'EXPORT_${LABEL}'
    KEEP UNTIL TIME 'SYSDATE+${KEEPDAYS}'
    RESTORE POINT ${DBNAME}_${LABEL};
  RELEASE CHANNEL c1;
}
EXIT
EOF

if grep -qE 'ORA-19914|ORA-28365' "$LOG"; then
  log "[FATAL] wallet is not open - check v\$encryption_wallet"
  mailx -s "[FATAL] secure export failed - wallet closed ($SID)" "$MAILTO" < "$LOG"
  exit 1
fi
if grep -qE 'RMAN-[0-9]{5}|ORA-[0-9]{5}' "$LOG"; then
  log "[FATAL] backup failed"
  grep -E 'RMAN-[0-9]{5}|ORA-[0-9]{5}' "$LOG" | head -10
  mailx -s "[FATAL] secure export failed ($SID)" "$MAILTO" < "$LOG"
  exit 1
fi

# ---------------------------------------------------------------------------
# 검증 1 : 평문 노출이 없는가
#   아래 패턴은 각 조직의 민감 데이터 형태에 맞게 수정한다
# ---------------------------------------------------------------------------
log "--- verify : plaintext scan ---"
for f in "$OUTDIR"/*; do
  [ -f "$f" ] || continue
  case "$f" in *README*) continue ;; esac
  if strings "$f" | grep -qE '@[a-z]+\.(com|co\.kr)|[0-9]{3}-[0-9]{4}-[0-9]{4}'; then
    log "[FATAL] plaintext detected in $(basename "$f")"
    mailx -s "[FATAL] plaintext in export ($SID)" "$MAILTO" < "$LOG"
    exit 1
  fi
done
log "plaintext scan passed"

# ---------------------------------------------------------------------------
# 검증 2 : 반출 비밀번호로 복호화가 되는가
# ---------------------------------------------------------------------------
log "--- verify : decryption ---"
rman target / catalog $CATALOG >> "$LOG" 2>&1 << EOF
SET DECRYPTION IDENTIFIED BY "$PW";
RESTORE DATABASE VALIDATE FROM TAG 'EXPORT_${LABEL}';
EXIT
EOF

if grep -qE 'ORA-19913|ORA-19870' "$LOG"; then
  log "[FATAL] decryption verification failed"
  mailx -s "[FATAL] export decryption failed ($SID)" "$MAILTO" < "$LOG"
  exit 1
fi
log "decryption verification passed"

# ---------------------------------------------------------------------------
# 인수인계 문서 (비밀번호는 포함하지 않는다)
# ---------------------------------------------------------------------------
DBID=$(sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT dbid FROM v$database;
EXIT
EOF
)

cat > "$OUTDIR/README_${LABEL}.txt" << TXT
================================================================
 반출 백업 인수인계 문서
================================================================
 대상 DB       : $DBNAME
 DBID          : (별도 통보)
 생성 일시     : $(date '+%Y-%m-%d %H:%M:%S')
 태그          : EXPORT_${LABEL}
 복원 지점     : ${DBNAME}_${LABEL}
 보관 기한     : $(date -d "+${KEEPDAYS} days" '+%Y-%m-%d')
 암호화        : 이중 모드 (지갑 또는 비밀번호)
 압축          : 적용
 조각 수       : $(ls -1 "$OUTDIR" | grep -v README | wc -l)

 복원 절차 (수령 측)
 ----------------------------------------------------------------
 1) 최소 pfile 로 인스턴스 기동
    echo "db_name=<임의명>" > \$ORACLE_HOME/dbs/init<SID>.ora
    sqlplus / as sysdba
    SQL> STARTUP NOMOUNT;

 2) 컨트롤파일 복원
    rman target /
    RMAN> SET DBID <별도 통보>;
    RMAN> SET DECRYPTION IDENTIFIED BY '<별도 통보>';
    RMAN> RESTORE CONTROLFILE FROM '<컨트롤파일이 담긴 조각 경로>';
    RMAN> ALTER DATABASE MOUNT;

 3) 데이터베이스 복원
    RMAN> RUN {
            SET DECRYPTION IDENTIFIED BY '<별도 통보>';
            SET NEWNAME FOR DATABASE TO '<데이터경로>/%b';
            RESTORE DATABASE;
            SWITCH DATAFILE ALL;
            RECOVER DATABASE;
          }

 4) 오픈
    SQL> ALTER DATABASE OPEN RESETLOGS;

 주의
 ----------------------------------------------------------------
 - 비밀번호는 이 문서에 포함되지 않는다. 별도 경로로 통보된다.
 - 비밀번호를 분실하면 이 백업은 열 수 없다. 복구 수단이 없다.
 - 이 매체에는 암호화 지갑이 포함되어 있지 않다. 정상이다.
================================================================
TXT

log "[OK] export created at $OUTDIR"
ls -lh "$OUTDIR" | tee -a "$LOG"
echo
echo "반출 비밀번호를 다시 확인하려면 이 실행의 화면 출력을 참조한다."
echo "로그 파일에는 기록되지 않는다."
exit 0
