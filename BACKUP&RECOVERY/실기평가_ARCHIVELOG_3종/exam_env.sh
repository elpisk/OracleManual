#!/bin/bash
#===============================================================================
# exam_env.sh — ARCHIVELOG 실기평가 공통 환경 (다른 스크립트가 source 한다)
#
#   경로는 고정하지 않는다. 데이터파일·컨트롤파일·리두·아카이브 위치는
#   실행 시점의 v$datafile / v$controlfile / v$logfile / v$archive_dest 에서 읽는다.
#   교안 기준 배치(/u01/app/oracle/oradata/orcl, /home/oracle/arch1)가 아니어도 동작한다.
#
#   바꿀 수 있는 값 (환경변수)
#     EXAM_SID   대상 SID                 기본 orcl
#     EXAM_BASE  백업 보관 상위 디렉터리  기본 /home/oracle/backup
#     EXAM_DIR   스크립트·기준선 디렉터리 기본 /home/oracle/exam
#===============================================================================
export ORACLE_HOME=${ORACLE_HOME:-/u01/app/oracle/product/19.3.0/dbhome_1}
export ORACLE_SID=${EXAM_SID:-orcl}
export PATH=$ORACLE_HOME/bin:/usr/local/bin:/usr/bin:/bin
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

BASE=${EXAM_BASE:-/home/oracle/backup}
BK=$BASE/exam_arch            # 응시자용 Hot Backup. 장애 스크립트는 여기의 데이터파일을 지우지 않는다.
SAFE=$BASE/_proctor_arch      # 감독자 복원점(Cold). exam_prep.sh 만 만들고 exam_reset.sh 만 쓴다.
EX=${EXAM_DIR:-/home/oracle/exam}

# 한 줄짜리 조회. 호출할 때 SQL 은 작은따옴표로 감싼다 (v$ 를 이스케이프하지 않아도 된다).
q() {
  # 인스턴스가 없거나 MOUNT 전이면 오류 문구 대신 빈 값을 돌려준다 (오류 문구가 경로로 쓰이는 사고 방지)
  printf '%s\n' "set feed off pages 0 head off lines 300 trimspool on" "whenever sqlerror continue" "$1" \
  | sqlplus -s / as sysdba | sed '/^$/d' \
  | awk '/ORA-0(1034|1507|1012|1219|0205)|SP2-|ERROR at line/ {bad=1} {l[NR]=$0} END {if (!bad) for (i=1;i<=NR;i++) print l[i]}'
}
# 화면에 보여 주는 조회 (헤더 포함)
qs() {
  printf '%s\n' "set lines 200 pages 200 feed off trimspool on" "col name for a60" "col member for a60" \
                "whenever sqlerror continue" "$1" | sqlplus -s / as sysdba
}
# 여러 문장 실행 (오류가 나도 계속)
run_sql() {
  printf '%s\n' "set feed off lines 200" "whenever sqlerror continue" "$1" | sqlplus -s / as sysdba
}

# 현재 상태를 사람이 읽을 수 있는 이름으로 돌려준다
db_state() {
  local st
  st=$(q 'select open_mode from v$database;' | tr -d '[:space:]')
  case "$st" in
    *ORA-01034*|*ORA-12560*|"") echo "인스턴스 정지" ;;
    *ORA-01507*)                echo "NOMOUNT (인스턴스만 기동)" ;;
    *MOUNTED*)                  echo "MOUNTED" ;;
    *READONLY*)                 echo "READ ONLY" ;;
    *READWRITE*)                echo "READ WRITE" ;;
    *)                          echo "$st" ;;
  esac
}

# 앞 케이스를 복구하지 않으면 다음 케이스를 주입할 수 없다
need_open() {
  local show; show=$(db_state)
  if [ "$show" != "READ WRITE" ]; then
    echo "=============================================================="
    echo " 중단 : 데이터베이스가 READ WRITE 가 아니다 (현재: $show)"
    echo
    echo " 앞 케이스의 복구가 끝나지 않았다."
    echo "   · 복구를 계속하려면 이 스크립트를 실행하지 말 것"
    echo "   · 포기하고 다음 케이스로 넘어가려면 감독관이 아래를 실행한 뒤"
    echo "     다시 이 스크립트를 실행한다"
    echo "       $EX/exam_reset.sh"
    echo "=============================================================="
    exit 1
  fi
}

need_archivelog() {
  local mode; mode=$(q 'select log_mode from v$database;' | tr -d '[:space:]')
  if [ "$mode" != "ARCHIVELOG" ]; then
    echo "중단: 현재 $mode 다. 이 평가는 ARCHIVELOG 전제이므로 먼저 전환할 것."
    exit 1
  fi
}

# 파일 위치 (DB 가 MOUNT 이상일 때만 값이 나온다)
datafiles()    { q 'select name from v$datafile order by file#;'; }
datafile_list(){ q "select file#||'|'||name from v\$datafile order by file#;"; }   # file#|path
tempfiles()    { q 'select name from v$tempfile;'; }
controlfiles() { q 'select name from v$controlfile;'; }
redomembers()  { q 'select member from v$logfile order by group#, member;'; }
arch_dir()     { q "select destination from v\$archive_dest where dest_id = 1;" | tr -d '[:space:]'; }
df_dir()       { dirname "$(q 'select name from v$datafile where file# = 1;' | tr -d '[:space:]')"; }
# 테이블스페이스의 첫 데이터파일
ts_file()      { q "select name from v\$datafile where ts# = (select ts# from v\$tablespace where name = '$1') order by file# fetch first 1 rows only;" | tr -d '[:space:]'; }
ts_fileno()    { q "select file# from v\$datafile where ts# = (select ts# from v\$tablespace where name = '$1') order by file# fetch first 1 rows only;" | tr -d '[:space:]'; }

# 확인용 테이블에 표식 행을 넣는다   $1=태그  $2=메모
mark() {
  run_sql "insert into hr.exam_log values ('$1','$2', sysdate, dbms_flashback.get_system_change_number);
commit;
select to_char(sysdate,'HH24:MI:SS')||'  '||'$1'||'  rows_now='||(select count(*) from hr.exam_log) as marker from dual;" | sed '/^$/d; /MARKER/d; /^---/d; s/^/  표식 /'
}

switch_n() {   # 로그 스위치 n 회 (체크포인트 포함)
  local i
  for i in $(seq 1 "$1"); do
    run_sql "alter system switch logfile;
alter system checkpoint;" >/dev/null
  done
}

# 과제 1-2 가 만든 임시 테이블스페이스를 치운다 (다른 케이스가 시작할 때)
drop_nobk() {
  run_sql "begin execute immediate 'drop tablespace exam_nobk including contents and datafiles'; exception when others then null; end;
/" >/dev/null
}

#-------------------------------------------------------------------------------
# Hot Backup → $BK
#   데이터파일 전부 + 백업 구간에 생긴 아카이브($BK/arch) + 바이너리 컨트롤파일 백업
#   $1 = 컨트롤파일 백업 이름 (기본 control_exam.bkp)
#-------------------------------------------------------------------------------
hot_backup() {
  local cfname=${1:-control_exam.bkp} f seq_b seq_e
  mkdir -p "$BK/arch"
  seq_b=$(q "select sequence# from v\$log where status = 'CURRENT';" | tr -d '[:space:]')
  run_sql "alter database begin backup;" >/dev/null
  for f in $(datafiles); do cp -p "$f" "$BK/"; done
  run_sql "alter database end backup;
alter system archive log current;" >/dev/null
  seq_e=$(q 'select max(sequence#) from v$archived_log where dest_id = 1 and resetlogs_change# = (select resetlogs_change# from v$database);' | tr -d '[:space:]')
  # 백업 구간(BEGIN~END BACKUP 직후 ARCHIVE LOG CURRENT)의 아카이브를 백업과 함께 보관한다
  for f in $(q "select name from v\$archived_log where dest_id = 1 and deleted = 'NO' and sequence# between $seq_b and $seq_e and resetlogs_change# = (select resetlogs_change# from v\$database);"); do
    cp -p "$f" "$BK/arch/"
  done
  run_sql "alter database backup controlfile to '$BK/$cfname' reuse;" >/dev/null
  {
    echo "backup_time=$(date '+%Y-%m-%d %H:%M:%S')"
    echo "resetlogs_change=$(q 'select resetlogs_change# from v$database;' | tr -d '[:space:]')"
    echo "seq_begin=$seq_b"
    echo "seq_end=$seq_e"
  } > "$BK/backup_info.txt"
  datafile_list > "$BK/manifest.txt"
  echo "  데이터파일 $(ls "$BK"/*.dbf | wc -l) 개, 구간 아카이브 seq $seq_b~$seq_e ($(ls "$BK/arch" | wc -l) 개), $cfname"
}

# RESETLOGS 를 지난 뒤라면 백업을 새로 받는다 (운영 원칙: RESETLOGS 직후 전체 백업)
refresh_backup_if_resetlogs() {
  local now was
  now=$(q 'select resetlogs_change# from v$database;' | tr -d '[:space:]')
  was=$(grep '^resetlogs_change=' "$BK/backup_info.txt" 2>/dev/null | cut -d= -f2)
  if [ -n "$was" ] && [ "$now" != "$was" ]; then
    echo "=== 앞 과제에서 RESETLOGS 를 지났다 (resetlogs_change# $was → $now). 새 Hot Backup 을 받는다 ==="
    rm -f "$BK"/arch/*
    hot_backup control_exam.bkp
  fi
}
