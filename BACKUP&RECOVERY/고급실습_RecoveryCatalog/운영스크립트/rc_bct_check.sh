#!/bin/bash
# =============================================================================
#  rc_bct_check.sh  —  Block Change Tracking 상태 점검
#  출처   : 고급 실습 08
#  실행   : rc_bct_check.sh <SID>   (oracle 계정, 기동 후·야간 백업 전)
#  종료값 : 0 정상 / 1 경고 / 2 파일을 열 수 없음(즉시 조치)
#
#  변경 추적 파일이 없어져도 기동은 된다(OPEN 때 조용히 재생성).
#  대신 추적 정보가 초기화되어 다음 증분 한 번은 전체 블록을 읽는다.
#  열린 인스턴스에서 파일이 없어지면 종료·체크포인트 때 비정상 종료된다.
# =============================================================================
SID=$1
# ---- 환경에 맞게 수정할 값 ----
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
# -------------------------------
export ORACLE_SID=$SID
export PATH=$ORACLE_HOME/bin:$PATH
ALERT=$ORACLE_BASE/diag/rdbms/${SID}/${SID}/trace/alert_${SID}.log
[ -z "$ORACLE_BASE" ] && ALERT=/u01/app/oracle/diag/rdbms/${SID}/${SID}/trace/alert_${SID}.log
RC=0

# 1) 상태와 파일
LINE=$(sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT status || ' ' || NVL(filename,'-') FROM v$block_change_tracking;
EXIT
EOF
)
if echo "$LINE" | grep -q 'ORA-19755'; then
  BCT=$(echo "$LINE" | grep 'ORA-19750' | awk -F"'" '{print $2}')
  echo "[FAIL] change tracking 파일을 열 수 없다 (ORA-19755) : $BCT"
  echo "       종료·체크포인트 때 인스턴스가 비정상 종료될 수 있다. 즉시 DISABLE 후 재설정한다"
  RC=2
else
  STATUS=$(echo $LINE | awk '{print $1}'); BCT=$(echo $LINE | awk '{print $2}')
  echo "status=$STATUS file=$BCT"
  [ "$STATUS" != "ENABLED" ] && { echo "[WARN] change tracking 이 꺼져 있다"; RC=1; }
fi

# 2) CTWR 프로세스
pgrep -f ora_ctwr_${SID} > /dev/null || { echo "[WARN] ora_ctwr_${SID} 프로세스 없음"; RC=1; }

# 3) 마지막 기동 때 파일이 재생성되었는데 그 뒤 추적을 쓴 증분이 아직 없으면 경고
#    (재생성되면 추적 정보가 초기화되어 다음 증분 한 번은 전체 블록을 읽는다)
LAST=$(grep -n 'Starting ORACLE instance' $ALERT | tail -1 | cut -d: -f1)
if [ -n "$LAST" ] && tail -n +$LAST $ALERT | grep -q 'Recreating the file'; then
  USED=$(sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT NVL(MAX(b.used_change_tracking) KEEP (DENSE_RANK LAST ORDER BY b.completion_time),'NONE')
FROM   v$backup_datafile b, v$instance i
WHERE  b.incremental_level = 1 AND b.completion_time > i.startup_time;
EXIT
EOF
)
  if [ "$(echo $USED)" != "YES" ]; then
    echo "[WARN] 마지막 기동 때 change tracking 파일이 재생성되었다 (추적 정보 초기화)"
    echo "       다음 증분 백업 한 번은 전체 블록을 읽는다 (백업 창 초과 가능)"; RC=1
  fi
fi

# 4) 최근 증분이 실제로 추적 정보를 썼는지
sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 20 FEEDBACK OFF
COLUMN used_change_tracking FORMAT A5 HEADING 'USED'
SELECT TO_CHAR(MAX(completion_time),'MM-DD HH24:MI') AS last_incr, used_change_tracking,
       COUNT(*) AS files, ROUND(SUM(blocks_read)/SUM(datafile_blocks)*100,1) AS pct_read
FROM   v$backup_datafile WHERE incremental_level = 1
AND    completion_time = (SELECT MAX(completion_time) FROM v$backup_datafile WHERE incremental_level = 1)
GROUP  BY used_change_tracking;
EXIT
EOF
[ $RC -eq 0 ] && echo "[OK] BCT check passed"
exit $RC
