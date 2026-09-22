#!/bin/bash
#===============================================================================
# exam_env.sh — RMAN 실기평가 공통 환경 (다른 스크립트가 source 한다)
#
#   경로는 고정하지 않는다. 데이터파일·컨트롤파일·리두·아카이브 위치는
#   실행 시점의 v$datafile / v$controlfile / v$logfile / v$archive_dest 에서 읽는다.
#
#   바꿀 수 있는 값 (환경변수)
#     EXAM_SID      대상 SID                      기본 orcl
#     EXAM_BASE     백업 보관 상위 디렉터리       기본 /home/oracle/backup
#     EXAM_DIR      스크립트·기준선 디렉터리      기본 /home/oracle/exam
#     EXAM_NEWLOC   과제 1-3 의 새 데이터파일 위치 기본 /u02/oradata/orcl
#     EXAM_DP_CONN  Data Pump 접속 문자열          기본 system/oracle_4U
#===============================================================================
export ORACLE_HOME=${ORACLE_HOME:-/u01/app/oracle/product/19.3.0/dbhome_1}
export ORACLE_SID=${EXAM_SID:-orcl}
export PATH=$ORACLE_HOME/bin:/usr/local/bin:/usr/bin:/bin
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

BASE=${EXAM_BASE:-/home/oracle/backup}
BK=$BASE/exam_rman            # RMAN 백업 조각·자동백업·Data Pump 덤프. 장애 스크립트는 여기서 조각 하나만 지운다(과제 1-1).
SAFE=$BASE/_proctor_rman      # 감독자 복원점(Cold). exam_prep.sh 만 만들고 exam_reset.sh 만 쓴다.
EX=${EXAM_DIR:-/home/oracle/exam}
NEWLOC=${EXAM_NEWLOC:-/u02/oradata/orcl}
DP_CONN=${EXAM_DP_CONN:-system/oracle_4U}

q() {
  # 인스턴스가 없거나 MOUNT 전이면 오류 문구 대신 빈 값을 돌려준다 (오류 문구가 경로로 쓰이는 사고 방지)
  printf '%s\n' "set feed off pages 0 head off lines 300 trimspool on" "whenever sqlerror continue" "$1" \
  | sqlplus -s / as sysdba | sed '/^$/d' \
  | awk '/ORA-0(1034|1507|1012|1219|0205)|SP2-|ERROR at line/ {bad=1} {l[NR]=$0} END {if (!bad) for (i=1;i<=NR;i++) print l[i]}'
}
qs() {
  printf '%s\n' "set lines 200 pages 200 feed off trimspool on" "col name for a60" "col member for a60" \
                "whenever sqlerror continue" "$1" | sqlplus -s / as sysdba
}
run_sql() {
  printf '%s\n' "set feed off lines 200" "whenever sqlerror continue" "$1" | sqlplus -s / as sysdba
}
run_rman() {   # 표준 출력에 그대로 보인다
  printf '%s\n' "$1" | rman target / 
}

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

datafiles()    { q 'select name from v$datafile order by file#;'; }
tempfiles()    { q 'select name from v$tempfile;'; }
controlfiles() { q 'select name from v$controlfile;'; }
redomembers()  { q 'select member from v$logfile order by group#, member;'; }
arch_dir()     { q "select destination from v\$archive_dest where dest_id = 1;" | tr -d '[:space:]'; }
df_dir()       { dirname "$(q 'select name from v$datafile where file# = 1;' | tr -d '[:space:]')"; }
ts_file()      { q "select name from v\$datafile where ts# = (select ts# from v\$tablespace where name = '$1') order by file# fetch first 1 rows only;" | tr -d '[:space:]'; }
ts_fileno()    { q "select file# from v\$datafile where ts# = (select ts# from v\$tablespace where name = '$1') order by file# fetch first 1 rows only;" | tr -d '[:space:]'; }

mark() {
  run_sql "insert into hr.exam_log values ('$1','$2', sysdate, dbms_flashback.get_system_change_number);
commit;
select to_char(sysdate,'HH24:MI:SS')||'  '||'$1'||'  rows_now='||(select count(*) from hr.exam_log) as marker from dual;" | sed '/^$/d; /MARKER/d; /^---/d; s/^/  표식 /'
}
switch_n() {
  local i
  for i in $(seq 1 "$1"); do
    run_sql "alter system switch logfile;
alter system checkpoint;" >/dev/null
  done
}

# RESETLOGS 를 지난 뒤라면 Level 0 를 새로 받는다 (운영 원칙: RESETLOGS 직후 전체 백업)
refresh_backup_if_resetlogs() {
  local now was
  now=$(q 'select resetlogs_change# from v$database;' | tr -d '[:space:]')
  was=$(grep '^resetlogs_change=' "$EX/backup_info.txt" 2>/dev/null | cut -d= -f2)
  if [ -n "$was" ] && [ "$now" != "$was" ]; then
    echo "=== 앞 과제에서 RESETLOGS 를 지났다 (resetlogs_change# $was → $now). 새 Level 0 백업을 받는다 ==="
    run_rman "BACKUP INCREMENTAL LEVEL 0 DATABASE TAG 'EXAM_L0' PLUS ARCHIVELOG TAG 'EXAM_ARC';" | grep -E 'Starting|Finished|RMAN-|ORA-' | sed 's/^/  /'
    sed -i "s/^resetlogs_change=.*/resetlogs_change=$now/" "$EX/backup_info.txt"
  fi
}
