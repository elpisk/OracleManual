#!/bin/bash
#===============================================================================
# exam_env.sh — ADG 종합 실기평가 공통 함수 (직접 실행하지 않는다)
#
#   모든 스크립트는 chicago-srv 의 oracle 계정에서 실행한다.
#   boston-srv 의 OS 작업은 oracle 계정 SSH(암호 없는 키)로 한다.
#   데이터베이스 접속은 SYS 비밀번호로 TNS(chicago / boston)를 거친다.
#
#   바꿀 수 있는 값 (환경변수)
#     EXAM_SYS_PW      SYS 비밀번호 (필수)
#     EXAM_DIR         스크립트·기록 디렉터리   기본 /home/oracle/exam
#     EXAM_BOSTON_HOST Standby 호스트           기본 boston-srv
#===============================================================================
export ORACLE_HOME=${ORACLE_HOME:-/u01/app/oracle/product/19.3.0/dbhome_1}
export PATH=$ORACLE_HOME/bin:$PATH
EX=${EXAM_DIR:-/home/oracle/exam}
BOSTON_HOST=${EXAM_BOSTON_HOST:-boston-srv}
if [ -z "${EXAM_SYS_PW:-}" ]; then
  echo "중단: EXAM_SYS_PW (SYS 비밀번호) 를 export 한 뒤 실행할 것." ; exit 1
fi
PW=$EXAM_SYS_PW
mkdir -p "$EX"

# q <db> "<sql>"   값만 돌려준다 (머리글·피드백 없음)
q() {
  sqlplus -s -L "sys/${PW}@$1 as sysdba" <<EOS
set head off feed off pages 0 lines 300 trimspool on verify off
whenever sqlerror continue
$2
exit
EOS
}
# run <db> "<sql>"  출력을 그대로 보여 준다
run() {
  sqlplus -s -L "sys/${PW}@$1 as sysdba" <<EOS
set feed on lines 200 pages 100 trimspool on
$2
exit
EOS
}
dg()     { dgmgrl -silent "sys/${PW}@$1" "$2"; }
bo_ssh() { ssh -o BatchMode=yes -o ConnectTimeout=5 oracle@"${BOSTON_HOST}" "$@"; }
# bo_sql "<sql>"  boston 에서 OS 인증으로 (인스턴스가 내려가 있어도 쓸 수 있다)
BO_ENV='export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1 ORACLE_SID=boston; export PATH=$ORACLE_HOME/bin:$PATH'
bo_sql() { bo_ssh "$BO_ENV; sqlplus -s / as sysdba" <<EOS
set feed on lines 200 pages 100
$1
exit
EOS
}
# ch_sql "<sql>"  chicago 에서 OS 인증으로 (스크립트가 chicago-srv 에서 돈다)
ch_sql() { ORACLE_SID=chicago sqlplus -s / as sysdba <<EOS
set feed on lines 200 pages 100
$1
exit
EOS
}

role() { q "$1" "select database_role from v\$database;" 2>/dev/null | grep -Eo 'PRIMARY|PHYSICAL STANDBY|SNAPSHOT STANDBY' | head -1; }
primary_db() {
  for d in chicago boston; do [ "$(role $d)" = "PRIMARY" ] && { echo "$d"; return; }; done
}
other_db() { [ "$1" = chicago ] && echo boston || echo chicago; }

# mark <step> <memo>  — 현재 Primary 에 확인용 행 한 줄 + 업무 기록 파일에 한 줄
mark() {
  local p; p=$(primary_db)
  [ -z "$p" ] && { echo "  (Primary 가 없어 $1 을 기록하지 못했다)"; return; }
  q "$p" "insert into system.exam_log(step,memo,reg_time,scn)
          select '$1','$2',sysdate,current_scn from v\$database;
          commit;" >/dev/null
  echo "$(date '+%F %T')  $1  $2  (on $p)" >> "$EX/business.log"
  echo "  [업무] $(date '+%T')  $1  $2"
}

switch_n() { local p; p=$(primary_db); for i in $(seq 1 "$1"); do q "$p" "alter system archive log current;" >/dev/null; done; }

cfg_status() { dg "$1" "show configuration" 2>/dev/null | grep -Eo 'SUCCESS|WARNING|ERROR' | tail -1; }

# need_ok <접속할 DB> [<기대 Primary>]  — 앞 과제가 복구되어 구성이 정상인지 확인한다
need_ok() {
  local via=$1 want=${2:-}
  local st; st=$(cfg_status "$via")
  if [ "$st" != "SUCCESS" ]; then
    echo "중단: Broker 구성 상태 = ${st:-확인 불가}. SUCCESS 여야 한다. 앞 과제를 먼저 복구할 것."
    echo "      (방금 고쳤다면 판정 시차일 수 있다. 1분 뒤 다시 실행한다)"
    dg "$via" "show configuration"
    exit 1
  fi
  if [ -n "$want" ] && [ "$(primary_db)" != "$want" ]; then
    echo "중단: Primary 가 $want 이어야 이 과제를 주입할 수 있다. 지금 Primary: $(primary_db)"
    exit 1
  fi
}

# Primary 의 데이터 파일 디렉터리 (system01.dbf 가 있는 곳)
ch_dfdir() { dirname "$(q chicago "select name from v\$datafile where file#=1;" | tr -d '[:space:]')"; }
