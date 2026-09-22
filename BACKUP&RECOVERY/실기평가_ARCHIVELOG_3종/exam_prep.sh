#!/bin/bash
#===============================================================================
# exam_prep.sh — ARCHIVELOG 실기평가 사전 준비 (감독자 실행)
#
#   만드는 것
#     $BK    응시자가 쓰는 Hot Backup (데이터파일 + 백업 구간 아카이브 + 바이너리 컨트롤파일 백업)
#            장애 스크립트가 필요할 때(RESETLOGS 뒤, CLEAR UNARCHIVED 뒤) 같은 형식으로 새로 받는다.
#     $SAFE  감독자 전용 복원점 (Cold) + $BK 의 사본. 장애 유발 스크립트가 절대 건드리지 않는다.
#            exam_reset.sh 가 이것으로 랩을 되돌린다. (RESETLOGS 뒤 새로 받은 Hot Backup 도 원래 것으로)
#            필요한 여유 공간 = 데이터파일 합계 × 3 (Hot Backup, Cold 복원점, Hot Backup 사본)
#     hr.exam_log     표식 테이블. 손실 보고의 근거.
#     hr.exam_orders  과제 2-2 에서 실수로 지워질 업무 테이블.
#     (exam_nobk, exam_new 테이블스페이스는 과제 1-2, 3-2 의 장애 스크립트가 그때 만든다)
#
#   경로는 v$ 뷰에서 읽는다. 아카이브 대상 1번의 파일도 $SAFE/arch 에 복사하므로
#   아카이브가 많이 쌓여 있으면 먼저 정리하고 실행한다 (운영가이드 1절).
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
if [ -z "$ARCH" ] || [ ! -d "$ARCH" ]; then
  echo "중단: LOG_ARCHIVE_DEST_1 의 위치를 읽지 못했다 ('$ARCH'). 아카이브 대상 1번이 디렉터리여야 한다."
  exit 1
fi
DFDIR=$(df_dir)
echo "=== [1] 상태 확인 : $ORACLE_SID / READ WRITE / ARCHIVELOG ==="
echo "  데이터파일 디렉터리 : $DFDIR   ($(datafiles | wc -l) 개)"
echo "  아카이브 대상 1번   : $ARCH    ($(ls "$ARCH" | wc -l) 개, $(du -sh "$ARCH" | cut -f1))"
echo "  리두 그룹           : $(q "select listagg(group#, ',') within group (order by group#) from v\$log;" | tr -d ' ')"
mkdir -p "$BK" "$SAFE" "$EX"

#--- 2. 이전 흔적 정리 ------------------------------------------------------------
echo "=== [2] 이전 평가의 흔적 정리 ==="
run_sql "begin execute immediate 'drop tablespace exam_new including contents and datafiles'; exception when others then null; end;
/
begin execute immediate 'drop tablespace exam_nobk including contents and datafiles'; exception when others then null; end;
/
begin execute immediate 'drop table hr.exam_log purge'; exception when others then null; end;
/
begin execute immediate 'drop table hr.exam_orders purge'; exception when others then null; end;
/" >/dev/null
rm -rf "${BK:?}"/*

#--- 3. 확인용 객체 ---------------------------------------------------------------
echo "=== [3] 확인용 테이블 hr.exam_log, 업무 테이블 hr.exam_orders ==="
run_sql "alter user hr quota unlimited on users;
create table hr.exam_log(step varchar2(10), memo varchar2(200), reg_time date, scn number) tablespace users;
create table hr.exam_orders(order_id number primary key, customer varchar2(30), amount number, order_time date) tablespace users;
insert into hr.exam_orders
  select level, 'CUST'||to_char(mod(level,50),'FM000'), round(dbms_random.value(10,500),2), sysdate - dbms_random.value(0,30)
  from dual connect by level <= 2000;
commit;
insert into hr.exam_log values ('BASE','hot backup 직전', sysdate, dbms_flashback.get_system_change_number);
commit;"
echo "  hr.exam_orders $(q 'select count(*) from hr.exam_orders;' | tr -d ' ') 행, hr.exam_log $(q 'select count(*) from hr.exam_log;' | tr -d ' ') 행"

#--- 4. Hot Backup ------------------------------------------------------------------
echo "=== [4] Hot Backup → $BK ==="
hot_backup control_exam.bkp
echo "  $BK : 데이터파일 $(ls "$BK"/*.dbf | wc -l) 개 / 아카이브 $(ls "$BK/arch" | wc -l) 개 / $(du -sh "$BK" | cut -f1)"

#--- 5. 감독자 복원점 (Cold) -------------------------------------------------------
echo "=== [5] 감독자 복원점 $SAFE (Cold) ==="
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
cp -p "$BK"/*.dbf "$BK/control_exam.bkp" "$BK/backup_info.txt" "$BK/manifest.txt" "$SAFE/bk/"
cp -rp "$BK/arch" "$SAFE/bk/arch"
echo "  파일 $(ls "$SAFE" | wc -l) 개 + 아카이브 $(ls "$SAFE/arch" | wc -l) 개 / $(du -sh "$SAFE" | cut -f1)  (장애 스크립트가 건드리지 않는다)"
run_sql "startup" >/dev/null

#--- 6. 기준선 ----------------------------------------------------------------------
echo "=== [6] 기준선 기록 → $EX/baseline.txt ==="
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
select step, memo, to_char(reg_time,'HH24:MI:SS') t, scn from hr.exam_log order by scn;" > "$EX/baseline.txt"
cat "$EX/baseline.txt"

echo
echo "준비 완료."
echo "  응시자용 백업 : $BK"
echo "  감독자 복원점 : $SAFE   (되돌리려면 exam_reset.sh)"
echo "  기준선        : $EX/baseline.txt"
