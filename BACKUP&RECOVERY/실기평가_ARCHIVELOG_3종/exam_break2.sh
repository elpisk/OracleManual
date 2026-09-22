#!/bin/bash
#===============================================================================
# exam_break2.sh — 시나리오 2 (불완전 복구, 10장) 장애 유발
#
#   사용법 :  ./exam_break2.sh 1|2|3
#
#     1 : 필요한 아카이브 결손 + 리두 소진 → Cancel 기반
#     2 : 사용자 실수 (DROP TABLE ... PURGE) → Time 기반
#     3 : 전체 손실 (DF·CF·RF·아카이브 전부) — Hot Backup 만 남음
#
#   앞 과제가 RESETLOGS 로 끝났다면 이 스크립트가 먼저 새 Hot Backup 을 받는다.
#   (운영 원칙 : RESETLOGS 직후 전체 백업. 이전 백업은 이 평가에서 쓰지 않는다.)
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
  refresh_backup_if_resetlogs
  echo "=== [2-1] 업무 발생 → 아카이브 → 추가 업무 → 아카이브 → 그 아카이브가 사라지고 리두도 덮인다 ==="
  mark 'S2-1a' '결손 이전 입력 (지킬 수 있다)'
  run_sql "alter system archive log current;" >/dev/null
  mark 'S2-1b' '결손 구간의 입력 (지킬 수 없다)'
  run_sql "alter system archive log current;" >/dev/null
  SEQ=$(q 'select max(sequence#) from v$archived_log where dest_id = 1;' | tr -d '[:space:]')
  AF=$(q "select name from v\$archived_log where dest_id = 1 and sequence# = $SEQ and resetlogs_change# = (select resetlogs_change# from v\$database) and rownum = 1;" | tr -d '[:space:]')
  rm -f "$AF"
  mark 'S2-1c' '결손 뒤의 입력 (지킬 수 없다)'
  # 결손 시퀀스를 담은 온라인 리두 그룹이 덮일 때까지 스위치한다
  n=0
  while [ "$(q "select count(*) from v\$log where sequence# = $SEQ;" | tr -d '[:space:]')" != "0" ] && [ $n -lt 12 ]; do
    switch_n 1; n=$((n+1))
  done
  echo "  로그 스위치 $n 회 — 결손 시퀀스는 온라인 리두에도 남아 있지 않다"
  qs "select group#, sequence#, status from v\$log order by group#;"
  F=$(ts_file USERS)
  echo "=== USERS 데이터파일 삭제 ==="
  run_sql "alter system flush buffer_cache;" >/dev/null
  rm -f "$F"
  echo "=== 증상 ==="
  qs "select count(*) from hr.exam_log;"
  echo
  echo "데이터베이스는 아직 OPEN 이다. 완전 복구가 되는지 먼저 시도해 보고, 안 되면 왜 안 되는지 밝혀라."
  ;;

2)
  refresh_backup_if_resetlogs
  echo "=== [2-2] 정상 업무 중 사용자 실수 ==="
  mark 'S2-2a' '실수 이전 입력 (지켜야 한다)'
  sleep 3
  T=$(q "select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') from dual;" | tr -d '[:space:]' | sed 's/\(..........\)/\1 /')
  run_sql "drop table hr.exam_orders purge;" >/dev/null
  echo "  $T  hr.exam_orders 가 DROP ... PURGE 되었다 (사용자 신고 시각)"
  echo "incident_time=$T" > "$EX/incident.txt"
  sleep 3
  mark 'S2-2b' '실수 이후 입력 (복구하면 사라진다)'
  run_sql "alter system archive log current;" >/dev/null
  mark 'S2-2c' '아카이브 뒤 입력 (복구하면 사라진다)'
  echo "=== 증상 ==="
  qs "select count(*) from hr.exam_orders;"
  echo
  echo "데이터베이스는 정상 OPEN 이다. 테이블은 PURGE 로 지워져 휴지통에도 없다."
  echo "사용자 신고 시각은 $EX/incident.txt 에도 적혀 있다."
  ;;

3)
  refresh_backup_if_resetlogs
  echo "=== [2-3] 업무 발생 → 아카이브 → 추가 업무 → 디스크 전체 손실 ==="
  mark 'S2-3a' '아카이브 되기 전 입력'
  run_sql "alter system archive log current;" >/dev/null
  mark 'S2-3b' '아카이브 뒤 입력'
  ARCH=$(arch_dir); DFS=$(datafiles); TFS=$(tempfiles); CFS=$(controlfiles); RFS=$(redomembers)
  run_sql "shutdown abort" >/dev/null
  echo "  SHUTDOWN ABORT"
  echo "=== 데이터파일·TEMP·컨트롤파일·리두 로그·아카이브 전부 삭제 ==="
  for f in $DFS $TFS $CFS $RFS; do rm -f "$f"; done
  rm -f "$ARCH"/*
  echo "  데이터파일 $(echo "$DFS" | wc -l), 컨트롤파일 $(echo "$CFS" | wc -l), 리두 멤버 $(echo "$RFS" | wc -l), 아카이브 디렉터리 비움 ($(ls "$ARCH" | wc -l) 개 남음)"
  echo "=== 재기동 시도 ==="
  run_sql "startup"
  echo
  echo "남은 것은 $BK 의 Hot Backup 뿐이다. 무엇까지 되살릴 수 있는지 판단하라."
  ;;

*)
  echo "사용법: $0 1|2|3"
  exit 1
  ;;
esac
