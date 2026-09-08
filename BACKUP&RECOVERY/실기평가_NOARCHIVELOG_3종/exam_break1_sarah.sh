#!/bin/bash
#===============================================================================
# exam_break1.sh — 시나리오 1 (데이터파일 계열) 장애 유발
#
#   사용법 :  ./exam_break1.sh 1|2|3|4
#
#     1 : USERS 데이터파일 유실 — 로그 스위치 없음 (리두 생존)
#     2 : USERS 데이터파일 유실 — 로그 스위치 다수 (리두 소진)
#     3 : UNDO 데이터파일 유실
#     4 : TEMP 파일 유실
#
#   각 단계는 앞 단계를 복구해 데이터베이스가 OPEN 인 상태에서 실행한다.
#
# 주의 : 개인 실습 환경(ORCL) 에서만 실행한다.
#===============================================================================
set -u
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=orcl
export PATH=$ORACLE_HOME/bin:/usr/local/bin:/usr/bin:/bin
D1=/u01/app/oracle/oradata/orcl
STEP="${1:-}"

#--- 앞 케이스를 복구하지 않으면 다음 케이스를 주입할 수 없다 -------------------
# 각 단계는 시작할 때 hr.exam_log 에 표식 행을 넣으므로 DB 가 OPEN 이어야 한다.
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
if [ "$STATE" != "READWRITE" ]; then
  echo "=============================================================="
  echo " 중단 : 데이터베이스가 READ WRITE 가 아니다 (현재: $SHOW)"
  echo
  echo " 앞 케이스의 복구가 끝나지 않았다."
  echo "   · 복구를 계속하려면 이 스크립트를 실행하지 말 것"
  echo "   · 포기하고 다음 케이스로 넘어가려면 감독관이 아래를 실행한 뒤"
  echo "     다시 이 스크립트를 실행한다"
  echo "       /home/oracle/exam/exam_reset.sh"
  echo "=============================================================="
  exit 1
fi


mark() {   # $1=태그  $2=메모
  sqlplus -s / as sysdba <<EOS
set feed off
insert into hr.exam_log values ('$1','$2', sysdate);
commit;
select count(*) as rows_now from hr.exam_log;
EOS
}

case "$STEP" in
1)
  echo "=== [1-1] 백업 이후 업무 발생 (로그 스위치 없음) ==="
  mark 'S1-1' '리두가 살아 있으면 이 행은 지킬 수 있다'
  echo "=== 데이터파일 삭제 ==="
  rm -f "$D1/users01.dbf"
  ls -l "$D1/users01.dbf" 2>&1 | sed 's/^/  /'
  sqlplus -s / as sysdba <<'EOS'
set feed off
alter system flush buffer_cache;
EOS
  echo "=== 증상 ==="
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
whenever sqlerror continue
select count(*) from hr.exam_log;
EOS
  echo
  echo "데이터베이스는 아직 OPEN 이다. 로그 스위치는 일으키지 않았다."
  ;;

2)
  echo "=== [1-2] 백업 이후 업무 발생 + 리두를 소진시킨다 ==="
  mark 'S1-2' '리두가 덮이면 이 행은 지킬 수 없다'
  echo "  로그 스위치 12회 (그룹 3개를 네 바퀴 돌려 백업 시점 리두를 덮는다)"
  for i in $(seq 1 12); do
    sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
alter system switch logfile;
alter system checkpoint;
EOS
  done
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
select group#, sequence#, status, first_change# from v$log order by group#;
EOS
  echo "=== 데이터파일 삭제 ==="
  rm -f "$D1/users01.dbf"
  sqlplus -s / as sysdba <<'EOS'
set feed off
alter system flush buffer_cache;
EOS
  echo "=== 증상 ==="
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
whenever sqlerror continue
select count(*) from hr.exam_log;
EOS
  ;;

3)
  echo "=== [1-3] UNDO 데이터파일 유실 ==="
  mark 'S1-3' 'UNDO 가 사라지면 무엇을 택해야 하는가'
  sqlplus -s / as sysdba <<'EOS'
set feed off
-- 되돌리지 않은 트랜잭션을 하나 남긴다
insert into hr.exam_log values ('S1-3x','커밋하지 않은 변경', sysdate);
EOS
  echo "  (커밋하지 않은 트랜잭션을 남긴 채 진행한다)"
  sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
shutdown abort
EOS
  rm -f "$D1/undotbs01.dbf"
  ls -l "$D1/undotbs01.dbf" 2>&1 | sed 's/^/  /'
  echo "=== 재기동 시도 ==="
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
whenever sqlerror continue
startup
EOS
  ;;

4)
  echo "=== [1-4] TEMP 파일 유실 ==="
  mark 'S1-4' 'TEMP 는 다른 파일과 무엇이 다른가'
  sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
shutdown immediate
EOS
  rm -f "$D1"/temp*.dbf
  ls -l "$D1"/temp*.dbf 2>&1 | sed 's/^/  /'
  echo "=== 재기동 ==="
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
whenever sqlerror continue
startup
select name, open_mode from v$database;
EOS
  echo
  echo "정렬을 강제해 증상을 확인해 보라."
  ;;

*)
  echo "사용법: $0 1|2|3|4"
  exit 1
  ;;
esac
