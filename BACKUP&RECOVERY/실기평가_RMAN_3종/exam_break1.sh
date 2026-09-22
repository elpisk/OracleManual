#!/bin/bash
#===============================================================================
# exam_break1.sh — 시나리오 1 (RMAN 백업 체계와 데이터파일 복구, 13~15장) 장애 유발
#
#   사용법 :  ./exam_break1.sh 1|2|3
#
#     1 : 백업 조각 한 개 소실 (관리자 실수) — 백업 체계 점검과 증분 백업
#     2 : 운영 중 USERS 데이터파일 유실 — RESTORE/RECOVER DATAFILE (무중단)
#     3 : exam_tbs 데이터파일 유실, 원래 디렉터리는 못 씀 — 새 위치로 복구 (SET NEWNAME)
#
#   각 단계는 앞 단계를 복구해 데이터베이스가 OPEN 인 상태에서 실행한다.
#
# 주의 : 개인 실습 환경(ORCL) 에서만 실행한다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"
STEP="${1:-}"
need_open

case "$STEP" in
1)
  echo "=== [1-1] 백업 이후 업무 발생, 로그 스위치 (아카이브가 쌓인다) ==="
  mark 'S1-1' 'Level 0 이후의 입력'
  run_sql "insert into hr.exam_orders select 2000+level, 'NEWCUST', 100, sysdate from dual connect by level <= 100;
commit;" >/dev/null
  switch_n 3
  # 아카이브 백업 세트의 조각 하나를 지운다 (관리자 실수)
  H=$(q "select p.handle from v\$backup_piece p join v\$backup_set s on p.set_stamp = s.set_stamp and p.set_count = s.set_count
         where p.tag = 'EXAM_ARC' and s.backup_type = 'L' and p.status = 'A' order by p.completion_time fetch first 1 rows only;" | tr -d '[:space:]')
  echo "=== 백업 디렉터리의 파일 한 개가 사라졌다 ==="
  rm -f "$H"
  echo "  $BK 에 $(ls "$BK" | grep -vc dpump) 개 파일이 남아 있다 (무엇이 사라졌는지는 RMAN 으로 찾아라)"
  echo
  echo "데이터베이스는 정상이다. 백업 체계가 지금 복구에 쓸 수 있는 상태인지 점검하고 보강하라."
  ;;

2)
  echo "=== [1-2] 백업 이후 업무 발생 + 로그 스위치 ==="
  mark 'S1-2' '아카이브가 살아 있으면 이 행은 지킬 수 있다'
  switch_n 2
  mark 'S1-2b' '스위치 뒤의 입력 (현재 리두)'
  F=$(ts_file USERS)
  echo "=== USERS 데이터파일 삭제 ==="
  run_sql "alter system flush buffer_cache;" >/dev/null
  rm -f "$F"
  ls -l "$F" 2>&1 | sed 's/^/  /'
  echo "=== 증상 ==="
  qs "select count(*) from hr.exam_log;"
  echo
  echo "데이터베이스는 아직 OPEN 이다. 서비스를 내리지 않고 RMAN 으로 복구하라."
  ;;

3)
  echo "=== [1-3] 백업 이후 업무 발생 + 로그 스위치 ==="
  mark 'S1-3' 'exam_items 변경 전'
  run_sql "update hr.exam_items set price = price + 1, upd_time = sysdate where mod(item_id, 10) = 0;
commit;" >/dev/null
  switch_n 2
  F=$(ts_file EXAM_TBS)
  mkdir -p "$NEWLOC"
  echo "=== exam_tbs 데이터파일 삭제 — 그 디렉터리는 디스크 장애로 더 쓸 수 없다고 가정한다 ==="
  run_sql "alter system flush buffer_cache;" >/dev/null
  rm -f "$F"
  ls -l "$F" 2>&1 | sed 's/^/  /'
  echo "  새 위치 : $NEWLOC  (이미 만들어져 있다)"
  echo "=== 증상 ==="
  qs "select count(*) from hr.exam_items;"
  echo
  echo "데이터베이스는 아직 OPEN 이다. 원래 위치가 아닌 $NEWLOC 으로 복구하라."
  ;;

*)
  echo "사용법: $0 1|2|3"
  exit 1
  ;;
esac
