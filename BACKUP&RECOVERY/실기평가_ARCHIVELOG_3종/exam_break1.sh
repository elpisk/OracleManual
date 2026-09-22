#!/bin/bash
#===============================================================================
# exam_break1.sh — 시나리오 1 (데이터파일 계열, 8·9장) 장애 유발
#
#   사용법 :  ./exam_break1.sh 1|2|3
#
#     1 : 운영 중 USERS 데이터파일 유실 — 아카이브 생존 (무중단 완전 복구)
#     2 : 백업 없는 테이블스페이스(exam_nobk)의 데이터파일 유실
#     3 : 정상 종료 후 모든 데이터파일 유실 + 아카이브 한 개 결손 (온라인 리두에 남아 있음)
#
#   각 단계는 앞 단계를 복구해 데이터베이스가 OPEN 인 상태에서 실행한다.
#   $BK 의 데이터파일은 지우지 않는다.
#
# 주의 : 개인 실습 환경(ORCL) 에서만 실행한다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"
STEP="${1:-}"
need_open

case "$STEP" in
1)
  drop_nobk
  echo "=== [1-1] 백업 이후 업무 발생, 로그 스위치 몇 번 (아카이브가 만들어진다) ==="
  mark 'S1-1' '아카이브가 살아 있으면 이 행은 지킬 수 있다'
  switch_n 2
  mark 'S1-1b' '스위치 뒤의 입력 (현재 리두)'
  F=$(ts_file USERS)
  echo "=== USERS 데이터파일 삭제 ==="
  run_sql "alter system flush buffer_cache;" >/dev/null
  rm -f "$F"
  ls -l "$F" 2>&1 | sed 's/^/  /'
  echo "=== 증상 ==="
  qs "select count(*) from hr.exam_log;"
  echo
  echo "데이터베이스는 아직 OPEN 이다. 서비스를 내리지 않고 복구하라."
  ;;

2)
  echo "=== [1-2] 백업 이후 새 테이블스페이스 exam_nobk 추가 (백업에 없다) ==="
  drop_nobk
  DFDIR=$(df_dir)
  run_sql "create tablespace exam_nobk datafile '$DFDIR/exam_nobk01.dbf' size 10M reuse;
alter user hr quota unlimited on exam_nobk;
create table hr.exam_nobk_t(id number, memo varchar2(100)) tablespace exam_nobk;
insert into hr.exam_nobk_t select level, '백업이 없는 테이블스페이스의 행' from dual connect by level <= 300;
commit;" >/dev/null
  mark 'S1-2' 'exam_nobk 생성과 300행 입력 뒤'
  switch_n 2
  run_sql "insert into hr.exam_nobk_t select level+300, '스위치 뒤 입력' from dual connect by level <= 100;
commit;" >/dev/null
  echo "  hr.exam_nobk_t $(q 'select count(*) from hr.exam_nobk_t;' | tr -d ' ') 행 (백업본에는 이 테이블스페이스 자체가 없다)"
  F=$(ts_file EXAM_NOBK)
  echo "=== exam_nobk 데이터파일 삭제 ==="
  run_sql "alter system flush buffer_cache;" >/dev/null
  rm -f "$F"
  ls -l "$F" 2>&1 | sed 's/^/  /'
  echo "=== 증상 ==="
  qs "select count(*) from hr.exam_nobk_t;"
  echo
  echo "데이터베이스는 아직 OPEN 이다. 백업본에 없는 파일을 어떻게 되살릴지 판단하라."
  ;;

3)
  drop_nobk
  echo "=== [1-3] 업무 발생 → 아카이브 → 추가 업무 → 정상 종료 ==="
  mark 'S1-3a' '아카이브 되기 전 입력'
  run_sql "alter system archive log current;" >/dev/null
  SEQ=$(q 'select max(sequence#) from v$archived_log where dest_id = 1;' | tr -d '[:space:]')
  AF=$(q "select name from v\$archived_log where dest_id = 1 and sequence# = $SEQ and resetlogs_change# = (select resetlogs_change# from v\$database) and rownum = 1;" | tr -d '[:space:]')
  mark 'S1-3b' '아카이브 뒤 입력 (현재 리두에만 있다)'
  DFS=$(datafiles)
  run_sql "shutdown immediate" >/dev/null
  echo "  SHUTDOWN IMMEDIATE 완료"
  echo "=== 모든 데이터파일 삭제 + 아카이브 파일 한 개 삭제 ==="
  for f in $DFS; do rm -f "$f"; done
  rm -f "$AF"
  echo "  데이터파일 $(echo "$DFS" | wc -l) 개 삭제, 아카이브 디렉터리의 파일 한 개도 함께 사라졌다"
  echo "=== 재기동 시도 ==="
  run_sql "startup"
  echo
  echo "어느 아카이브가 없는지는 복구 과정에서 스스로 찾아야 한다."
  echo "없어진 아카이브의 내용이 아직 어딘가에 남아 있는지 판단하라."
  ;;

*)
  echo "사용법: $0 1|2|3"
  exit 1
  ;;
esac
