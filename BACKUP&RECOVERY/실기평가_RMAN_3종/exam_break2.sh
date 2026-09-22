#!/bin/bash
#===============================================================================
# exam_break2.sh — 시나리오 2 (spfile·컨트롤파일·불완전 복구, 15·16장) 장애 유발
#
#   사용법 :  ./exam_break2.sh 1|2|3
#
#     1 : spfile 유실 (pfile 도 없음) — 자동백업에서 spfile 복원
#     2 : 비정상 종료 + 컨트롤파일 전손 — 자동백업에서 컨트롤파일 복원, RESETLOGS
#     3 : 사용자 실수 (DROP TABLE ... PURGE) — 시점 기반 불완전 복구
#
#   앞 과제가 RESETLOGS 로 끝났다면 이 스크립트가 먼저 새 Level 0 를 받는다.
#   (운영 원칙 : RESETLOGS 직후 전체 백업)
#
# 주의 : 개인 실습 환경(ORCL) 에서만 실행한다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"
STEP="${1:-}"
need_open

case "$STEP" in
1)
  refresh_backup_if_resetlogs
  echo "=== [2-1] 업무 발생 → 정상 종료 → spfile 유실 ==="
  mark 'S2-1' 'spfile 이 사라져도 데이터는 그대로다'
  run_sql "shutdown immediate" >/dev/null
  echo "  SHUTDOWN IMMEDIATE 완료"
  echo "=== spfile 삭제 (pfile 이 있으면 함께 회수한다 — 문제를 숨기지 않기 위해) ==="
  mkdir -p "$SAFE/hidden"
  rm -f "$ORACLE_HOME/dbs/spfile${ORACLE_SID}.ora"
  [ -f "$ORACLE_HOME/dbs/init${ORACLE_SID}.ora" ] && mv -f "$ORACLE_HOME/dbs/init${ORACLE_SID}.ora" "$SAFE/hidden/"
  ls -l "$ORACLE_HOME/dbs/" | grep -i "${ORACLE_SID}" | sed 's/^/  /'
  echo "=== 재기동 시도 ==="
  run_sql "startup"
  echo
  echo "파라미터 파일 없이 인스턴스를 어떻게 띄우고, 자동백업을 어디서 찾을지 판단하라."
  ;;

2)
  refresh_backup_if_resetlogs
  echo "=== [2-2] 업무 발생 → 아카이브 → 추가 업무 → 비정상 종료 + 컨트롤파일 전손 ==="
  mark 'S2-2a' '아카이브 되기 전 입력'
  run_sql "alter system archive log current;" >/dev/null
  mark 'S2-2b' '아카이브 뒤 입력 (CURRENT 리두에만 있다)'
  CFS=$(controlfiles)
  run_sql "shutdown abort" >/dev/null
  echo "  SHUTDOWN ABORT"
  echo "=== 컨트롤파일 전부 삭제 ==="
  for f in $CFS; do rm -f "$f"; done
  echo "  컨트롤파일 $(echo "$CFS" | wc -l) 개 삭제"
  echo "=== 재기동 시도 ==="
  run_sql "startup"
  echo
  echo "컨트롤파일 자동백업으로 되돌린 뒤, 손실 없이 열 수 있는지 판단하라."
  ;;

3)
  refresh_backup_if_resetlogs
  echo "=== [2-3] 정상 업무 중 사용자 실수 ==="
  mark 'S2-3a' '실수 이전 입력 (지켜야 한다)'
  sleep 3
  T=$(date '+%Y-%m-%d %H:%M:%S')
  run_sql "drop table hr.exam_orders purge;" >/dev/null
  echo "  $T  hr.exam_orders 가 DROP ... PURGE 되었다 (사용자 신고 시각)"
  echo "incident_time=$T" > "$EX/incident.txt"
  sleep 3
  mark 'S2-3b' '실수 이후 입력 (복구하면 사라진다)'
  run_sql "alter system archive log current;" >/dev/null
  mark 'S2-3c' '아카이브 뒤 입력 (복구하면 사라진다)'
  echo "=== 증상 ==="
  qs "select count(*) from hr.exam_orders;"
  echo
  echo "데이터베이스는 정상 OPEN 이다. 테이블은 PURGE 로 지워져 휴지통에도 없다."
  echo "사용자 신고 시각은 $EX/incident.txt 에도 적혀 있다."
  ;;

*)
  echo "사용법: $0 1|2|3"
  exit 1
  ;;
esac
