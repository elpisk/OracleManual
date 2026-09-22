#!/bin/bash
#===============================================================================
# exam_break3.sh — 시나리오 3 (리두·컨트롤파일 복합, 11·12장) 장애 유발
#
#   사용법 :  ./exam_break3.sh 1|2|3
#
#     1 : 정상 종료 뒤 CURRENT 리두 그룹 전손 (아카이브 안 된 리두)
#     2 : 정기 Hot Backup → 테이블스페이스 추가(구조 변경) → 정상 종료 → 컨트롤파일 전손
#     3 : 정기 Hot Backup → 비정상 종료 + 데이터파일·컨트롤파일·리두 전손, 아카이브는 있음
#
#   대상 그룹 번호는 실행 시점의 v$log 에 따라 달라진다.
#   과제 3-2·3-3 은 장애를 내기 전에 새 Hot Backup 을 받는다. 앞 과제의 CLEAR UNARCHIVED /
#   RESETLOGS 로 이전 백업의 아카이브 사슬이 끊겨 있기 때문이다 (운영 원칙과 같다).
#
# 주의 : 개인 실습 환경(ORCL) 에서만 실행한다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"
STEP="${1:-}"
need_open
drop_nobk

case "$STEP" in
1)
  echo "=== [3-1] 업무 발생 (현재 리두에만 있다) → 정상 종료 → CURRENT 그룹 전손 ==="
  mark 'S3-1a' '아카이브 되기 전 입력'
  run_sql "alter system archive log current;" >/dev/null
  mark 'S3-1b' '아카이브 뒤 입력 (CURRENT 리두에만 있다)'
  G=$(q "select group# from v\$log where status = 'CURRENT';" | tr -d '[:space:]')
  MEMBERS=$(q "select member from v\$logfile where group# = $G;")
  run_sql "shutdown immediate" >/dev/null
  echo "  SHUTDOWN IMMEDIATE 완료"
  echo "=== 리두 그룹 한 개의 멤버 전부 삭제 ==="
  for f in $MEMBERS; do rm -f "$f"; done
  echo "  멤버 $(echo "$MEMBERS" | wc -l) 개 삭제 (어느 그룹인지는 조회로 확인하라)"
  echo "=== 재기동 시도 ==="
  run_sql "startup"
  echo
  echo "손상된 그룹이 CURRENT 인가, 종료는 정상이었는가. 두 질문에 먼저 답하라."
  ;;

2)
  echo "=== [3-2] 정기 Hot Backup (앞 과제의 CLEAR UNARCHIVED 로 이전 백업의 사슬이 끊겼다) ==="
  rm -f "$BK"/arch/*
  hot_backup control_exam.bkp
  echo "=== 백업 이후 구조 변경 : exam_new 테이블스페이스 추가 ==="
  DFDIR=$(df_dir)
  run_sql "begin execute immediate 'drop tablespace exam_new including contents and datafiles'; exception when others then null; end;
/
create tablespace exam_new datafile '$DFDIR/exam_new01.dbf' size 20M reuse;
alter user hr quota unlimited on exam_new;
create table hr.exam_new_t(id number, memo varchar2(100)) tablespace exam_new;
insert into hr.exam_new_t select level, 'hot backup 이후에 생긴 테이블스페이스의 행' from dual connect by level <= 500;
commit;" >/dev/null
  mark 'S3-2a' 'exam_new 생성과 500행 입력 뒤'
  run_sql "alter system archive log current;" >/dev/null
  mark 'S3-2b' '아카이브 뒤 입력 (CURRENT 리두에만 있다)'
  CFS=$(controlfiles)
  run_sql "shutdown immediate" >/dev/null
  echo "  SHUTDOWN IMMEDIATE 완료"
  echo "=== 컨트롤파일 전부 삭제 ==="
  for f in $CFS; do rm -f "$f"; done
  echo "  컨트롤파일 $(echo "$CFS" | wc -l) 개 삭제"
  echo "=== 재기동 시도 ==="
  run_sql "startup"
  echo
  echo "남은 것은 $BK/control_exam.bkp 뿐이다. 그 백업이 언제 것인지, 지금 구조와 같은지 확인하라."
  ;;

3)
  echo "=== [3-3] 정기 Hot Backup (앞 과제의 RESETLOGS 로 이전 백업의 사슬이 끊겼다) ==="
  rm -f "$BK"/arch/*
  hot_backup control_exam.bkp
  echo "=== 업무 발생 → 아카이브 → 추가 업무 → 비정상 종료 + DF·CF·RF 전손 ==="
  mark 'S3-3a' '아카이브 되기 전 입력'
  run_sql "alter system archive log current;" >/dev/null
  mark 'S3-3b' '아카이브 뒤 입력 (CURRENT 리두에만 있다)'
  ARCH=$(arch_dir); DFS=$(datafiles); CFS=$(controlfiles); RFS=$(redomembers)
  run_sql "shutdown abort" >/dev/null
  echo "  SHUTDOWN ABORT"
  echo "=== 데이터파일·컨트롤파일·리두 로그 전부 삭제 (아카이브는 남긴다) ==="
  for f in $DFS $CFS $RFS; do rm -f "$f"; done
  echo "  데이터파일 $(echo "$DFS" | wc -l), 컨트롤파일 $(echo "$CFS" | wc -l), 리두 멤버 $(echo "$RFS" | wc -l) 삭제"
  echo "  아카이브 $(ls "$ARCH" | wc -l) 개는 그대로다"
  echo "=== 재기동 시도 ==="
  run_sql "startup"
  echo
  echo "Hot Backup 과 아카이브로 어디까지 되살릴 수 있는지 판단하라."
  ;;

*)
  echo "사용법: $0 1|2|3"
  exit 1
  ;;
esac
