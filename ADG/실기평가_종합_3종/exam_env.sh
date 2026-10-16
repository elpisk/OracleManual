#!/bin/bash
#===============================================================================
# exam_env.sh — ADG 종합 실기평가 공통 함수 (직접 실행하지 않는다)
#
#   모든 스크립트는 chicago-srv 의 감독관 계정 examadm 으로 돈다.
#   응시자(oracle)는 sudo -u examadm 으로 장애 주입 스크립트를 실행만 할 수 있고,
#   /home/examadm 은 700 이라 스크립트 내용과 감독관 기록을 읽지 못한다.
#   데이터베이스·OS 작업은 모두 oracle 계정 SSH(암호 없는 키)로 양쪽 서버에서 한다.
#
#   설정 파일 $EX/exam.conf (examadm 만 읽는다, 600)
#     EXAM_SYS_PW=<SYS 비밀번호>      (필수)
#     ORACLE_HOME=...                 기본 /u01/app/oracle/product/19.3.0/dbhome_1
#     CHICAGO_HOST=...                기본 chicago-srv
#     BOSTON_HOST=...                 기본 boston-srv
#===============================================================================
EX=${EXAM_DIR:-/home/examadm/exam}   # 스크립트·감독관 기록 (examadm 전용). sudo 가 환경을 지우므로 응시자는 바꿀 수 없다
PUB=${EXAM_PUB:-/exam/pub}           # 응시자가 읽는 기록 (business.log, baseline.txt, ticket_*)
if [ "$(id -un)" != "examadm" ]; then
  echo "중단: examadm 계정으로 실행해야 한다 (응시자는 sudo -u examadm <스크립트>)." ; exit 1
fi
[ -r "$EX/exam.conf" ] && . "$EX/exam.conf"
OH=${ORACLE_HOME:-/u01/app/oracle/product/19.3.0/dbhome_1}
CHICAGO_HOST=${CHICAGO_HOST:-chicago-srv}
BOSTON_HOST=${BOSTON_HOST:-boston-srv}
if [ -z "${EXAM_SYS_PW:-}" ]; then
  echo "중단: $EX/exam.conf 에 EXAM_SYS_PW 가 없다 (운영가이드 1-4)." ; exit 1
fi
PW=$EXAM_SYS_PW
umask 022
mkdir -p "$EX/state" "$EX/proctor" || exit 1
[ -d "$PUB" ] && [ -w "$PUB" ] || { echo "중단: $PUB 가 없거나 쓸 수 없다 (운영가이드 1-3)." ; exit 1; }

ENV_CH="export ORACLE_HOME=$OH ORACLE_SID=chicago PATH=$OH/bin:\$PATH"
ENV_BO="export ORACLE_HOME=$OH ORACLE_SID=boston PATH=$OH/bin:\$PATH"
SSHOPT="-o BatchMode=yes -o ConnectTimeout=5"
ch_ssh() { ssh $SSHOPT oracle@"${CHICAGO_HOST}" "$@"; }
bo_ssh() { ssh $SSHOPT oracle@"${BOSTON_HOST}" "$@"; }

# q <db> "<sql>"   chicago-srv 의 oracle 로 TNS 접속, 값만 돌려준다 (머리글·피드백 없음)
q() {
  ch_ssh "$ENV_CH; sqlplus -s -L 'sys/${PW}@$1 as sysdba'" <<EOS
set head off feed off pages 0 lines 300 trimspool on verify off
whenever sqlerror continue
$2
exit
EOS
}
# dg <db> "<명령>"  DGMGRL 한 줄 (명령 안에는 작은따옴표만 쓴다)
dg() { ch_ssh "$ENV_CH; dgmgrl -silent 'sys/${PW}@$1' \"$2\""; }
# bo_sql "<sql>"  boston 에서 OS 인증으로 (인스턴스가 내려가 있어도 쓸 수 있다)
bo_sql() { bo_ssh "$ENV_BO; sqlplus -s / as sysdba" <<EOS
set feed on lines 200 pages 100
$1
exit
EOS
}
# ch_sql "<sql>"  chicago 에서 OS 인증으로
ch_sql() { ch_ssh "$ENV_CH; sqlplus -s / as sysdba" <<EOS
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
  echo "$(date '+%F %T')  $1  $2  (on $p)" >> "$PUB/business.log"
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
