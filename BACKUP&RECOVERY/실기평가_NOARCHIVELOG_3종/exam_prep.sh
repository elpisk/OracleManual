#!/bin/bash
#===============================================================================
# exam_prep.sh — 실기평가 사전 준비 (감독자 실행)
#
#   백업을 두 벌 만든다.
#     $BK   응시자가 쓰는 Cold Backup. 시나리오 2 에서 일부가 사라진다.
#     $SAFE 감독자 전용 복원점. 장애 유발 스크립트가 절대 건드리지 않는다.
#           exam_reset.sh 가 이것으로 랩을 되돌린다.
#
#   시나리오 2 의 함정 : trace 백업을 exam_tbs 생성 '전' 에 받는다.
#   재실행해도 함정이 성립하도록 trace 를 받기 전에 exam_tbs 를 먼저 지운다.
#
# 주의 : 개인 실습 환경(ORCL) 에서만 실행한다.
#===============================================================================
set -u
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=orcl
export PATH=$ORACLE_HOME/bin:/usr/local/bin:/usr/bin:/bin

D1=/u01/app/oracle/oradata/orcl
D2=/u02/oradata/orcl
BK=/home/oracle/backup/exam_nolog
SAFE=/home/oracle/backup/_proctor
EX=/home/oracle/exam

#--- 0. 아무것도 지우기 전에 데이터베이스가 정상인지 먼저 확인한다 --------------
STATE=$(sqlplus -s / as sysdba <<'EOS' | tr -d '[:space:]'
set feed off pages 0 head off
select open_mode from v$database;
EOS
)
# 사람이 읽을 수 있는 상태 이름으로 바꾼다
case "$STATE" in
  *ORA-01034*|*ORA-12560*|"") SHOW="인스턴스 정지" ;;
  *ORA-01507*)                SHOW="NOMOUNT (인스턴스만 기동)" ;;
  *MOUNTED*)                  SHOW="MOUNTED" ;;
  *READONLY*)                 SHOW="READ ONLY" ;;
  *)                          SHOW="$STATE" ;;
esac
case "$STATE" in
  READWRITE) : ;;
  *) echo "중단: 데이터베이스가 READ WRITE 가 아니다 (현재: $SHOW)."
     echo "     먼저 정상 기동한 뒤 다시 실행할 것. 백업은 건드리지 않았다."
     exit 1 ;;
esac

MODE=$(sqlplus -s / as sysdba <<'EOS' | tr -d '[:space:]'
set feed off pages 0 head off
select log_mode from v$database;
EOS
)
if [ "$MODE" != "NOARCHIVELOG" ]; then
  echo "중단: 현재 $MODE 다. 이 평가는 NOARCHIVELOG 전제이므로 먼저 전환할 것."
  exit 1
fi
echo "=== [1] 상태 확인 : ORCL / READ WRITE / $MODE ==="

mkdir -p "$BK" "$SAFE" "$EX"
rm -rf "${BK:?}"/*

#--- 2. 확인용 테이블 ----------------------------------------------------------
echo "=== [2] 확인용 테이블 hr.exam_log ==="
sqlplus -s / as sysdba <<'EOS'
set feed off
whenever sqlerror continue
begin execute immediate 'drop table hr.exam_log purge'; exception when others then null; end;
/
create table hr.exam_log(step varchar2(10), memo varchar2(200), reg_time date)
  tablespace users;
insert into hr.exam_log values ('BASE','cold backup 직전', sysdate);
commit;
EOS

#--- 3. trace 를 받기 전에 exam_tbs 를 먼저 없앤다 (함정 성립 조건) -------------
echo "=== [3] trace 이전 정리 — exam_tbs 제거 ==="
sqlplus -s / as sysdba <<'EOS'
set feed off
whenever sqlerror continue
begin execute immediate 'drop tablespace exam_tbs including contents and datafiles';
exception when others then null; end;
/
EOS

#--- 4. trace 백업 (구조 변경 '전' 시점) ---------------------------------------
echo "=== [4] trace 백업 ==="
sqlplus -s / as sysdba <<EOS
set feed off
alter database backup controlfile to trace as '$BK/cf_exam.sql' reuse;
EOS
echo -n "  trace 안의 데이터파일 수 : "
sed -n '/^CREATE CONTROLFILE.*NORESETLOGS/,/^;/p' "$BK/cf_exam.sql" | grep -c 'dbf'

#--- 5. trace 이후 데이터파일 추가 (시나리오 2 의 함정) ------------------------
echo "=== [5] trace 이후 exam_tbs 추가 ==="
sqlplus -s / as sysdba <<EOS
set feed off
create tablespace exam_tbs datafile '$D1/exam_tbs01.dbf' size 20M;
create table hr.exam_t2(id number, memo varchar2(200)) tablespace exam_tbs;
insert into hr.exam_t2 values (1,'trace 이후에 생긴 테이블스페이스');
commit;
EOS
echo -n "  실제 데이터파일 수 : "
ls "$D1"/*.dbf | grep -v temp | wc -l

#--- 6. Cold Backup 두 벌 -------------------------------------------------------
echo "=== [6] Cold Backup ==="
sqlplus -s / as sysdba <<'EOS'
set feed off
shutdown immediate
EOS
cp -p "$D1"/*.dbf "$D1"/*.ctl "$D1"/*.log "$BK"/
cp -p "$D2"/*.ctl "$D2"/*.log "$BK"/
cp -p "$ORACLE_HOME/dbs/spfileorcl.ora" "$ORACLE_HOME/dbs/orapworcl" "$BK"/
rm -f "$BK"/temp*.dbf
rm -rf "${SAFE:?}"/*
cp -p "$BK"/* "$SAFE"/
echo "  응시자용 $BK   : $(ls "$BK" | wc -l) 개 / $(du -sh "$BK" | cut -f1)"
echo "  감독자용 $SAFE : $(ls "$SAFE" | wc -l) 개 (장애 스크립트가 건드리지 않는다)"

sqlplus -s / as sysdba <<'EOS'
set feed off
startup
EOS

#--- 7. 기준선 ------------------------------------------------------------------
echo "=== [7] 기준선 기록 ==="
sqlplus -s / as sysdba <<EOS > "$EX/baseline.txt"
set lines 200 pages 200 feed off
col name for a50
col member for a46
select name, log_mode, open_mode, checkpoint_change# from v\$database;
select file#, name, bytes/1024/1024 mb, status from v\$datafile order by file#;
select file#, name from v\$tempfile;
select name from v\$controlfile;
select group#, sequence#, status, bytes/1024/1024 mb from v\$log order by group#;
select group#, member from v\$logfile order by group#, member;
select min(first_change#) as min_first_change from v\$log where status <> 'UNUSED';
select count(*) exam_log_rows from hr.exam_log;
EOS
cat "$EX/baseline.txt"

echo
echo "준비 완료."
echo "  응시자용 백업 : $BK"
echo "  감독자 복원점 : $SAFE   (되돌리려면 exam_reset.sh)"
echo "  기준선        : $EX/baseline.txt"
