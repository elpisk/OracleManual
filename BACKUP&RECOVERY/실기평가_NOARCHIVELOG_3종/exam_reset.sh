#!/bin/bash
#===============================================================================
# exam_reset.sh — 감독자 복원점으로 랩을 되돌린다
#
#   시나리오 사이, 또는 응시자가 복구에 실패했을 때 실행한다.
#   $SAFE 는 exam_prep.sh 만 만들고 장애 유발 스크립트는 건드리지 않으므로
#   어떤 상태에서도 이 스크립트로 되돌아온다.
#
#   컨트롤파일까지 통째로 되돌리므로 별도의 복구 명령이 필요 없다.
#===============================================================================
set -u
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=orcl
export PATH=$ORACLE_HOME/bin:/usr/local/bin:/usr/bin:/bin

D1=/u01/app/oracle/oradata/orcl
D2=/u02/oradata/orcl
SAFE=/home/oracle/backup/_proctor
BK=/home/oracle/backup/exam_nolog

if [ ! -f "$SAFE/system01.dbf" ]; then
  echo "중단: 복원점 $SAFE 가 없다. exam_prep.sh 를 먼저 실행할 것."
  exit 1
fi

echo "=== 인스턴스 정지 ==="
sqlplus -s / as sysdba <<'EOS'
set feed off
whenever sqlerror continue
shutdown abort
EOS

echo "=== 파일 복원 ==="
cp -p "$SAFE"/*.dbf "$D1"/
cp -p "$SAFE"/control01.ctl "$SAFE"/control02.ctl "$D1"/
cp -p "$SAFE"/control03.ctl "$D2"/
cp -p "$SAFE"/redo01.log "$SAFE"/redo03.log "$SAFE"/redo04.log "$D1"/
cp -p "$SAFE"/redo01b.log "$SAFE"/redo03b.log "$SAFE"/redo04b.log "$D2"/
cp -p "$SAFE"/spfileorcl.ora "$SAFE"/orapworcl "$ORACLE_HOME/dbs/"
chown oracle:dba "$D1"/* "$D2"/*.ctl "$D2"/*.log 2>/dev/null

echo "=== 응시자용 백업본도 원래대로 ==="
mkdir -p "$BK"
rm -rf "${BK:?}"/*
cp -p "$SAFE"/* "$BK"/

echo "=== 기동 ==="
sqlplus -s / as sysdba <<'EOS'
set feed off
startup
EOS

echo "=== TEMP 재생성 (컨트롤파일을 되돌렸으므로 필요할 수 있다) ==="
sqlplus -s / as sysdba <<EOS
set feed off
whenever sqlerror continue
alter tablespace temp add tempfile '$D1/temp01.dbf' size 200M reuse;
EOS

echo "=== 확인 ==="
sqlplus -s / as sysdba <<'EOS'
set lines 200 pages 100 feed off
col name for a50
select name, open_mode, log_mode from v$database;
select count(*) datafiles from v$datafile;
select count(*) tempfiles from v$tempfile;
select name from v$controlfile;
select group#, sequence#, status from v$log order by group#;
select count(*) exam_log_rows from hr.exam_log;
EOS

echo
echo "복원 완료. 다음 시나리오를 시작할 수 있다."
