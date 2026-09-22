#!/bin/bash
#===============================================================================
# exam_prep.sh — RMAN 실기평가 사전 준비 (감독자 실행)
#
#   만드는 것
#     $BK    RMAN 백업 (Level 0 + 아카이브 + 컨트롤파일 자동백업), Data Pump 덤프 ($BK/dpump)
#     $SAFE  감독자 전용 복원점 (Cold) + $BK 사본. exam_reset.sh 가 이것으로 되돌린다.
#     hr.exam_log     표식 테이블. 손실 보고의 근거.
#     hr.exam_orders  과제 2-3(불완전 복구)·3-2(Flashback) 에서 지워질 업무 테이블.
#     hr.exam_items   exam_tbs 테이블스페이스. 과제 1-3(새 위치)·3-1(블록 손상)·3-3(TRUNCATE) 대상.
#     $EX/rman_config_before.rman  평가 전 RMAN 영구 설정 (평가 뒤 되돌릴 때 실행)
#
#   RMAN 영구 설정 중 백업 위치(채널 FORMAT, 자동백업 FORMAT)만 $BK 로 바꾼다.
#   나머지(보존 정책·병렬도·암호화 등)는 응시자 환경의 값을 그대로 둔다.
#
# 주의 : 개인 실습 환경(ORCL) 에서만 실행한다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"

#--- 1. 상태 확인 ----------------------------------------------------------------
SHOW=$(db_state)
if [ "$SHOW" != "READ WRITE" ]; then
  echo "중단: 데이터베이스가 READ WRITE 가 아니다 (현재: $SHOW)."
  echo "     먼저 정상 기동한 뒤 다시 실행할 것. 아무것도 건드리지 않았다."
  exit 1
fi
need_archivelog
ARCH=$(arch_dir)
DFDIR=$(df_dir)
DBID=$(q 'select dbid from v$database;' | tr -d '[:space:]')
echo "=== [1] 상태 확인 : $ORACLE_SID / READ WRITE / ARCHIVELOG / DBID $DBID ==="
echo "  데이터파일 디렉터리 : $DFDIR   ($(datafiles | wc -l) 개)"
echo "  아카이브 대상 1번   : $ARCH    ($(ls "$ARCH" | wc -l) 개, $(du -sh "$ARCH" | cut -f1))"
echo "  새 위치(과제 1-3)   : $NEWLOC"
mkdir -p "$BK/dpump" "$SAFE" "$EX" "$NEWLOC"

#--- 2. 이전 흔적 정리 ------------------------------------------------------------
echo "=== [2] 이전 평가의 흔적 정리 ==="
run_rman "DELETE NOPROMPT BACKUP TAG 'EXAM_L0';
DELETE NOPROMPT BACKUP TAG 'EXAM_L1';
DELETE NOPROMPT BACKUP TAG 'EXAM_ARC';" >/dev/null 2>&1
run_sql "begin execute immediate 'drop tablespace exam_tbs including contents and datafiles'; exception when others then null; end;
/
begin execute immediate 'drop table hr.exam_log purge'; exception when others then null; end;
/
begin execute immediate 'drop table hr.exam_orders purge'; exception when others then null; end;
/
begin execute immediate 'drop user exam_stg cascade'; exception when others then null; end;
/
begin execute immediate 'drop directory exam_dp'; exception when others then null; end;
/
purge dba_recyclebin;" >/dev/null
rm -rf "${BK:?}"/* ; mkdir -p "$BK/dpump"
rm -f "$NEWLOC"/exam_tbs01.dbf
# 리포지터리와 디스크를 맞춘다. 실습이 남긴 EXPIRED 항목이 있으면 과제 1-1 의 CROSSCHECK 결과가 흐려진다.
run_rman "CROSSCHECK BACKUP;
DELETE NOPROMPT EXPIRED BACKUP;
CROSSCHECK ARCHIVELOG ALL;
DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;" | grep -E '^Crosschecked|^Deleted|RMAN-' | sed 's/^/  /'

#--- 3. RMAN 영구 설정 : 현재 값 보관 → 백업 위치만 $BK 로 ----------------------------
echo "=== [3] RMAN 영구 설정 ==="
run_rman "SHOW ALL;" > "$EX/rman_config_before.txt"
grep '^CONFIGURE' "$EX/rman_config_before.txt" | grep -v '# default' > "$EX/rman_config_before.rman"
echo "EXIT;" >> "$EX/rman_config_before.rman"
run_rman "CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$BK/cf_%F';
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '$BK/%d_%T_%s_%p.bkp';
CONFIGURE DEVICE TYPE DISK PARALLELISM 2 BACKUP TYPE TO BACKUPSET;" | grep -E 'RMAN-|ORA-|new RMAN' | sed 's/^/  /'
echo "  평가 전 설정 보관 : $EX/rman_config_before.rman (평가 뒤 rman target / @이파일 로 되돌린다)"

#--- 4. 확인용 객체 ---------------------------------------------------------------
echo "=== [4] hr.exam_log, hr.exam_orders, exam_tbs / hr.exam_items ==="
run_sql "alter user hr quota unlimited on users;
create table hr.exam_log(step varchar2(10), memo varchar2(200), reg_time date, scn number) tablespace users;
create table hr.exam_orders(order_id number primary key, customer varchar2(30), amount number, order_time date) tablespace users;
insert into hr.exam_orders
  select level, 'CUST'||to_char(mod(level,50),'FM000'), round(dbms_random.value(10,500),2), sysdate - dbms_random.value(0,30)
  from dual connect by level <= 2000;
commit;
create tablespace exam_tbs datafile '$DFDIR/exam_tbs01.dbf' size 20M reuse;
alter user hr quota unlimited on exam_tbs;
create table hr.exam_items(item_id number primary key, name varchar2(40), price number, upd_time date) tablespace exam_tbs;
insert into hr.exam_items
  select level, 'ITEM-'||to_char(level,'FM00000'), round(dbms_random.value(1,1000),2), sysdate
  from dual connect by level <= 5000;
commit;
insert into hr.exam_log values ('BASE','논리백업·Level 0 직전', sysdate, dbms_flashback.get_system_change_number);
commit;"
echo "  hr.exam_orders $(q 'select count(*) from hr.exam_orders;' | tr -d ' ') 행, hr.exam_items $(q 'select count(*) from hr.exam_items;' | tr -d ' ') 행 (exam_tbs), hr.exam_log $(q 'select count(*) from hr.exam_log;' | tr -d ' ') 행"

#--- 5. 야간 논리백업 (Data Pump) --------------------------------------------------------
echo "=== [5] Data Pump 논리백업 → $BK/dpump/hr_exam.dmp ==="
run_sql "create directory exam_dp as '$BK/dpump';
grant read, write on directory exam_dp to hr;" >/dev/null
{
  echo "directory=exam_dp"
  echo "dumpfile=hr_exam.dmp"
  echo "logfile=hr_exam_exp.log"
  echo "schemas=hr"
  echo "include=TABLE:\"IN ('EXAM_ORDERS','EXAM_ITEMS','EXAM_LOG')\""
  echo "reuse_dumpfiles=y"
} > "$EX/hr_exam_exp.par"
expdp "$DP_CONN" parfile="$EX/hr_exam_exp.par" 2>&1 | grep -E 'exported|successfully|ORA-|UDE-' | sed 's/^/  /'

#--- 6. RMAN Level 0 + 아카이브 (자동백업 포함) --------------------------------------------
echo "=== [6] RMAN Level 0 백업 ==="
run_sql "alter system archive log current;" >/dev/null
run_rman "BACKUP INCREMENTAL LEVEL 0 DATABASE TAG 'EXAM_L0' PLUS ARCHIVELOG TAG 'EXAM_ARC';" \
  | grep -E 'Starting|Finished|piece handle|RMAN-|ORA-' | sed 's/^/  /'
{
  echo "backup_time=$(date '+%Y-%m-%d %H:%M:%S')"
  echo "dbid=$DBID"
  echo "resetlogs_change=$(q 'select resetlogs_change# from v$database;' | tr -d '[:space:]')"
} > "$EX/backup_info.txt"
echo "  $BK : $(ls "$BK" | grep -vc dpump) 개 파일 / $(du -sh "$BK" | cut -f1)"

#--- 7. 감독자 복원점 (Cold) -------------------------------------------------------
echo "=== [7] 감독자 복원점 $SAFE (Cold) ==="
run_sql "insert into hr.exam_log values ('SAFE','감독자 복원점 직전', sysdate, dbms_flashback.get_system_change_number);
commit;" >/dev/null
rm -rf "${SAFE:?}"/*
mkdir -p "$SAFE/arch" "$SAFE/bk"
{
  for f in $(datafiles);    do echo "D|$f"; done
  for f in $(tempfiles);    do echo "T|$f"; done
  for f in $(controlfiles); do echo "C|$f"; done
  for f in $(redomembers);  do echo "R|$f"; done
} > "$SAFE/manifest.txt"
echo "arch_dir=$ARCH" >> "$SAFE/manifest.txt"
run_sql "shutdown immediate" >/dev/null
while IFS='|' read -r kind path; do
  case "$kind" in D|T|C|R) cp -p "$path" "$SAFE/" ;; esac
done < "$SAFE/manifest.txt"
cp -p "$ORACLE_HOME/dbs/spfile${ORACLE_SID}.ora" "$ORACLE_HOME/dbs/orapw${ORACLE_SID}" "$SAFE/"
cp -p "$ARCH"/* "$SAFE/arch/" 2>/dev/null
ls "$ARCH" > "$SAFE/arch_list.txt"
cp -rp "$BK"/. "$SAFE/bk/"
cp -p "$EX/backup_info.txt" "$SAFE/"
echo "  파일 $(ls "$SAFE" | wc -l) 개 + 아카이브 $(ls "$SAFE/arch" | wc -l) 개 + 백업 사본 / $(du -sh "$SAFE" | cut -f1)  (장애 스크립트가 건드리지 않는다)"
run_sql "startup" >/dev/null

#--- 8. 기준선 ----------------------------------------------------------------------
echo "=== [8] 기준선 기록 → $EX/baseline.txt ==="
qs "select name, dbid, log_mode, open_mode, resetlogs_change#, checkpoint_change# from v\$database;
select file#, name, bytes/1024/1024 mb, status from v\$datafile order by file#;
select file#, name from v\$tempfile;
select name from v\$controlfile;
select group#, sequence#, status, bytes/1024/1024 mb from v\$log order by group#;
select group#, member from v\$logfile order by group#, member;
col destination for a40
select dest_id, destination, status from v\$archive_dest where dest_id <= 2;
select max(sequence#) last_archived from v\$archived_log where dest_id = 1;
col step for a8
col memo for a40
select step, memo, to_char(reg_time,'HH24:MI:SS') t, scn from hr.exam_log order by scn;
show parameter undo_retention" > "$EX/baseline.txt"
run_rman "LIST BACKUP SUMMARY;
SHOW ALL;" >> "$EX/baseline.txt"
cat "$EX/baseline.txt"

echo
echo "준비 완료."
echo "  백업·덤프      : $BK   (DBID $DBID — 응시자에게 알려 주지 않는다. 스스로 찾게 한다)"
echo "  감독자 복원점  : $SAFE   (되돌리려면 exam_reset.sh)"
echo "  기준선         : $EX/baseline.txt"
echo "  평가 전 RMAN 설정 : $EX/rman_config_before.rman"
