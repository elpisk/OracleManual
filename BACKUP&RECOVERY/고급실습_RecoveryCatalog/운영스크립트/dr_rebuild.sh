#!/bin/bash
# =============================================================================
#  dr_rebuild.sh  —  타 서버 재구축 보조 (카탈로그 기반 재해 복구)
#  출처   : 고급 실습 07
#  사용법 : dr_rebuild.sh <DB_NAME> <신규데이터경로> <신규아카이브경로>
#  예     : dr_rebuild.sh ORCL /u02/oradata/ORCL /u02/arch_orcl
#
#  이 스크립트는 정보 수집·구문 생성·최소 pfile 작성까지만 한다.
#  실제 RESTORE / RECOVER 는 사람이 내용을 확인한 뒤 실행한다.
#  재해 상황에서 자동 실행은 위험하다.
#
#  전제 : 대상 서버에 같은 버전의 ORACLE_HOME 이 설치되어 있을 것
#         백업 매체에 접근 가능할 것
#         Recovery Catalog 에 접속 가능할 것
# =============================================================================
set -u

if [ $# -lt 3 ]; then
  echo "usage: $0 <DB_NAME> <data_dir> <arch_dir>"
  echo "  예 : $0 ORCL /u02/oradata/ORCL /u02/arch_orcl"
  exit 2
fi

DBNAME=$(echo "$1" | tr 'a-z' 'A-Z')
DATADIR=$2
ARCHDIR=$3
SID=$(echo "$DBNAME" | tr 'A-Z' 'a-z')

export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=$SID
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'

# ---- 환경에 맞게 수정할 값 ----
RCUSER="rc_report/oracle_4U@rcat"
RCADMIN="rcatowner@rcat"
ADUMP=/u02/admin/$SID/adump
SGA=2G
# --------------------------------

WORK=/tmp/dr_$DBNAME
mkdir -p "$WORK" "$DATADIR" "$ARCHDIR" "$ADUMP"

echo "=============================================================="
echo " 재해 복구 준비 : $DBNAME"
echo " 데이터 경로    : $DATADIR"
echo " 아카이브 경로  : $ARCHDIR"
echo " 작업 디렉터리  : $WORK"
echo "=============================================================="

# ---------------------------------------------------------------------------
# 1. 카탈로그에서 정보 수집
# ---------------------------------------------------------------------------
echo
echo "### 1. DBID 와 데이터베이스 정보"
sqlplus -s $RCUSER << EOF | tee "$WORK/dbinfo.txt"
SET PAGESIZE 0 FEEDBACK OFF LINESIZE 200 HEADING OFF
SELECT 'DBID=' || dbid || ' DBINC_KEY=' || dbinc_key ||
       ' RESET=' || TO_CHAR(reset_time,'YYYY-MM-DD HH24:MI:SS')
FROM   rc_database WHERE name = '$DBNAME'
AND    dbinc_key = (SELECT MAX(dbinc_key) FROM rc_database WHERE name='$DBNAME');
EXIT
EOF

DBID=$(grep -o 'DBID=[0-9]*' "$WORK/dbinfo.txt" | head -1 | cut -d= -f2)
if [ -z "${DBID:-}" ]; then
  echo "[FATAL] DBID 를 찾을 수 없다. 카탈로그 접속과 DB 이름을 확인하라."
  exit 1
fi
echo "DBID = $DBID"

echo
echo "### 2. 데이터파일 구성"
sqlplus -s $RCUSER << EOF | tee "$WORK/datafiles.txt"
SET PAGESIZE 100 LINESIZE 200 FEEDBACK OFF
COLUMN name FORMAT A55
SELECT file#, tablespace_name, ROUND(bytes/1024/1024) AS mb, name
FROM   rc_datafile
WHERE  dbinc_key = (SELECT MAX(dbinc_key) FROM rc_database WHERE name='$DBNAME')
ORDER  BY file#;
EXIT
EOF

echo
echo "### 3. 리두 로그 구성 (RESETLOGS 후 이 구성으로 생성된다)"
sqlplus -s $RCUSER << EOF
SET PAGESIZE 50 LINESIZE 120 FEEDBACK OFF
SELECT group#, thread#, ROUND(bytes/1024/1024) AS mb, members
FROM   rc_redo_log
WHERE  dbinc_key = (SELECT MAX(dbinc_key) FROM rc_database WHERE name='$DBNAME')
ORDER  BY group#;
EXIT
EOF

echo
echo "### 4. 복구 가능 종점 (데이터 손실 산정 — 즉시 업무 담당자에게 통보)"
sqlplus -s $RCUSER << EOF | tee "$WORK/rpo.txt"
SET PAGESIZE 0 FEEDBACK OFF LINESIZE 200 HEADING OFF
SELECT '백업된 마지막 아카이브 : seq=' || MAX(sequence#) ||
       '  시각=' || TO_CHAR(MAX(next_time),'YYYY-MM-DD HH24:MI:SS') ||
       '  SCN=' || MAX(next_change#)
FROM   rc_archived_log a
WHERE  a.db_name = '$DBNAME'
AND    EXISTS (SELECT 1 FROM rc_backup_redolog b
               WHERE b.dbinc_key = a.dbinc_key AND b.sequence# = a.sequence#);
EXIT
EOF

echo
echo "### 5. 백업 조각 위치 (매체 준비)"
sqlplus -s $RCUSER << EOF
SET PAGESIZE 50 LINESIZE 160 FEEDBACK OFF
COLUMN directory FORMAT A60
SELECT SUBSTR(handle, 1, INSTR(handle,'/',-1)) AS directory, COUNT(*) AS pieces
FROM   rc_backup_piece WHERE db_name = '$DBNAME' AND status = 'A'
GROUP  BY SUBSTR(handle, 1, INSTR(handle,'/',-1));
EXIT
EOF

# ---------------------------------------------------------------------------
# 2. SET NEWNAME 구문 생성
# ---------------------------------------------------------------------------
echo
echo "### 6. SET NEWNAME 구문 생성"
sqlplus -s $RCUSER << EOF > "$WORK/set_newname.txt"
SET PAGESIZE 0 FEEDBACK OFF LINESIZE 200 HEADING OFF TRIMSPOOL ON
SELECT '  SET NEWNAME FOR DATAFILE ' || file# || ' TO ''$DATADIR/' ||
       SUBSTR(name, INSTR(name,'/',-1)+1) || ''';'
FROM   rc_datafile
WHERE  dbinc_key = (SELECT MAX(dbinc_key) FROM rc_database WHERE name='$DBNAME')
ORDER  BY file#;
EXIT
EOF
grep -v '^\s*$' "$WORK/set_newname.txt"

# ---------------------------------------------------------------------------
# 3. 복원 스크립트 생성
# ---------------------------------------------------------------------------
{
  echo "# 자동 생성됨 : $(date '+%Y-%m-%d %H:%M:%S')"
  echo "# 실행 전 경로와 파일 목록을 반드시 확인할 것"
  echo "RUN {"
  echo "  ALLOCATE CHANNEL c1 DEVICE TYPE DISK;"
  echo "  ALLOCATE CHANNEL c2 DEVICE TYPE DISK;"
  grep -v '^\s*$' "$WORK/set_newname.txt"
  echo "  RESTORE DATABASE;"
  echo "  SWITCH DATAFILE ALL;"
  echo "  RECOVER DATABASE;"
  echo "  RELEASE CHANNEL c1;"
  echo "  RELEASE CHANNEL c2;"
  echo "}"
} > "$WORK/restore.rman"

echo
echo "### 7. 복원 스크립트 : $WORK/restore.rman"
cat "$WORK/restore.rman"

# ---------------------------------------------------------------------------
# 4. 최소 pfile 생성
# ---------------------------------------------------------------------------
cat > "$ORACLE_HOME/dbs/init${SID}.ora" << EOF
db_name=$SID
sga_target=$SGA
db_block_size=8192
compatible=19.0.0
control_files='$DATADIR/control01.ctl'
audit_file_dest='$ADUMP'
diagnostic_dest='/u01/app/oracle'
EOF

echo
echo "### 8. 최소 pfile 생성됨 : $ORACLE_HOME/dbs/init${SID}.ora"
cat "$ORACLE_HOME/dbs/init${SID}.ora"

# ---------------------------------------------------------------------------
# 5. 수동 수행 안내
# ---------------------------------------------------------------------------
cat << EOF

==============================================================
 다음 단계를 순서대로 수동 수행한다
==============================================================

[1] NOMOUNT 기동
    export ORACLE_SID=$SID
    sqlplus / as sysdba
    SQL> STARTUP NOMOUNT PFILE='\$ORACLE_HOME/dbs/init${SID}.ora';

[2] spfile 복원
    rman target / catalog $RCADMIN
    RMAN> SET DBID $DBID;                 -- 카탈로그 접속 시 생략 가능
    RMAN> RESTORE SPFILE TO '/tmp/spfile_${SID}.ora' FROM AUTOBACKUP;

[3] spfile 경로 수정 후 재기동  ★ 이 단계를 건너뛰면 MOUNT 부터 실패한다
    SQL> CREATE PFILE='/tmp/init_${SID}.ora'
         FROM SPFILE='/tmp/spfile_${SID}.ora';
    -- 아래 경로들을 대상 서버 기준으로 치환한다
    --   control_files / db_recovery_file_dest / audit_file_dest
    --   log_archive_dest_1  →  location=$ARCHDIR
    SQL> SHUTDOWN IMMEDIATE
    SQL> CREATE SPFILE FROM PFILE='/tmp/init_${SID}.ora';
    SQL> STARTUP NOMOUNT;

[4] 컨트롤파일 복원과 MOUNT
    rman target / catalog $RCADMIN
    RMAN> RESTORE CONTROLFILE;
    RMAN> ALTER DATABASE MOUNT;
    RMAN> REPORT SCHEMA;                  -- 원본 경로가 보이는 것이 정상

[5] 경로 변경 복원
    RMAN> @$WORK/restore.rman
    -- RMAN-06054 (아카이브 없음)는 예상된 결과다. 손실 구간을 뜻한다

[6] 오픈
    SQL> ALTER DATABASE OPEN RESETLOGS;

[7] 정상화  ★ 여기까지가 복구다
    RMAN> RESYNC CATALOG;
    RMAN> LIST INCARNATION OF DATABASE;
    RMAN> BACKUP DATABASE PLUS ARCHIVELOG;    -- 새 인카네이션 기준선
    -- 리스너 / tnsnames / 애플리케이션 접속 정보 전환

==============================================================
 손실 범위 (업무 담당자 통보용)
==============================================================
$(cat "$WORK/rpo.txt")

==============================================================
EOF

exit 0
