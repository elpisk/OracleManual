#!/bin/bash
#===============================================================================
# exam_break3.sh — 시나리오 3 (블록 손상·Flashback·Data Pump, 16·18·19장) 장애 유발
#
#   사용법 :  ./exam_break3.sh 1|2|3
#
#     1 : hr.exam_items 의 데이터 블록 한 개 물리 손상 (dd) — Block Media Recovery
#     2 : 사용자 실수 두 건 — DROP TABLE (휴지통), 잘못된 UPDATE 커밋 — Flashback
#     3 : TRUNCATE TABLE — Flashback 으로 못 되돌린다, Data Pump 논리백업으로 복원
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
  echo "=== [3-1] hr.exam_items 데이터 블록 한 개를 물리적으로 손상시킨다 ==="
  mark 'S3-1' '블록 손상 직전'
  F=$(ts_file EXAM_TBS)
  FNO=$(ts_fileno EXAM_TBS)
  BLK=$(q "select dbms_rowid.rowid_block_number(rowid) from hr.exam_items where item_id = 2500;" | tr -d '[:space:]')
  run_sql "alter system checkpoint;
alter system flush buffer_cache;" >/dev/null
  dd if=/dev/zero of="$F" bs=8192 seek="$BLK" count=1 conv=notrunc 2>&1 | tail -1 | sed 's/^/  dd: /'
  run_sql "alter system flush buffer_cache;" >/dev/null
  echo "  파일 $FNO 의 블록 하나가 0 으로 덮였다 (어느 블록인지는 조회로 찾아라)"
  echo "=== 증상 (COUNT(*) 는 인덱스만 읽어 멀쩡해 보일 수 있다. 테이블 블록을 읽는 조회로 본다) ==="
  qs "select sum(price) from hr.exam_items;"
  echo
  echo "데이터베이스는 OPEN 이다. 파일 전체를 되돌리지 말고 손상된 블록만 고쳐라."
  ;;

2)
  echo "=== [3-2] 사용자 실수 두 건 ==="
  mark 'S3-2a' '실수 이전'
  sleep 3
  T1=$(date '+%Y-%m-%d %H:%M:%S')
  run_sql "drop table hr.exam_orders;" >/dev/null
  echo "  $T1  ① hr.exam_orders 를 DROP 했다 (PURGE 없음)"
  sleep 3
  T2=$(date '+%Y-%m-%d %H:%M:%S')
  run_sql "update hr.exam_items set price = 0, upd_time = sysdate;
commit;" >/dev/null
  echo "  $T2  ② hr.exam_items 전 행의 price 를 0 으로 바꾸고 커밋했다 (잘못된 일괄 작업)"
  {
    echo "drop_time=$T1"
    echo "update_time=$T2"
  } > "$EX/incident.txt"
  sleep 3
  mark 'S3-2b' '실수 이후 (다른 테이블의 정상 입력)'
  echo "=== 증상 ==="
  qs "select count(*) from hr.exam_orders;
select count(*) total, sum(case when price = 0 then 1 end) zero_price from hr.exam_items;"
  echo
  echo "데이터베이스는 정상 OPEN 이다. 백업을 쓰지 말고, 데이터베이스를 내리지도 말고 두 건을 되돌려라."
  echo "UNDO 보존 시간 안에 끝내야 한다 (SHOW PARAMETER undo_retention)."
  ;;

3)
  echo "=== [3-3] 논리백업 이후 입력 → TRUNCATE ==="
  mark 'S3-3a' 'TRUNCATE 이전 입력'
  run_sql "insert into hr.exam_items select 5000+level, 'ITEM-'||to_char(5000+level,'FM00000'), 50, sysdate from dual connect by level <= 200;
commit;" >/dev/null
  echo "  hr.exam_items 에 200 행 추가 (논리백업 이후의 입력) → $(q 'select count(*) from hr.exam_items;' | tr -d ' ') 행"
  sleep 3
  T=$(date '+%Y-%m-%d %H:%M:%S')
  run_sql "truncate table hr.exam_items;" >/dev/null
  echo "  $T  hr.exam_items 가 TRUNCATE 되었다"
  echo "truncate_time=$T" > "$EX/incident.txt"
  sleep 3
  mark 'S3-3b' 'TRUNCATE 이후'
  echo "=== 증상 ==="
  qs "select count(*) from hr.exam_items;"
  echo
  echo "데이터베이스는 정상 OPEN 이다. Flashback 이 통하는지 먼저 확인하고, 안 되면 다른 길을 찾아라."
  echo "논리백업 : $BK/dpump/hr_exam.dmp (디렉터리 객체 EXAM_DP)"
  ;;

*)
  echo "사용법: $0 1|2|3"
  exit 1
  ;;
esac
