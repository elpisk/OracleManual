#!/bin/bash
#===============================================================================
# exam_break3.sh — 시나리오 3 [상] Active Data Guard 운영 지원 — 장애 주입
#
#   사용법 :  sudo -u examadm /home/examadm/exam/exam_break3.sh 1|2|3
#
#     1 : 리포트팀 문의 — 방금 넣은 주문이 Standby 에 안 보이고 ORA-03172
#         → Broker DelayMins (9장 · 14장)
#     2 : 야간 점검표가 '경고' — Standby 리스너 정지 (15장)
#     3 : Snapshot Standby 시험 운용 중 Primary 업무 발생
#         (응시자가 먼저 boston 을 Snapshot Standby 로 바꾼 뒤 실행한다 — 11장)
#
#   주의 : 개인 실습 랩(chicago / boston)에서만 실행한다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"
STEP="${1:-}"

case "$STEP" in
1)
  need_ok chicago chicago
  dg chicago "edit database 'boston' set property 'DelayMins'='10';" >/dev/null
  sleep 5
  mark 'S3-1a' '주문 접수 — 리포트에 나와야 한다'
  switch_n 1
  cat > "$PUB/ticket_S3-1.txt" <<TXT
[리포트팀 문의 $(date '+%F %T')]
방금 접수된 주문(exam_log 의 S3-1a)이 boston 리포트 화면에 나오지 않습니다.
리포트 세션은 신선도 보장을 위해 접속 직후
  ALTER SESSION SET STANDBY_MAX_DATA_DELAY=60;
을 실행하는데, 오늘 오후부터 조회할 때마다 오류가 납니다. 리포트 계정은 SYSTEM 입니다.
TXT
  echo "  리포트팀 문의가 $PUB/ticket_S3-1.txt 로 도착했다."
  cat "$PUB/ticket_S3-1.txt"
  ;;

2)
  need_ok chicago chicago
  bo_ssh "$ENV_BO; lsnrctl stop >/dev/null" && echo "=== [3-2] (아무도 모르게) boston 리스너가 내려갔다 ==="
  mark 'S3-2a' '야간 배치 1'
  switch_n 2
  mark 'S3-2b' '야간 배치 2'
  echo "  60초 기다린다 ..."; sleep 60
  echo "[야간 점검표 $(date '+%T')] 상태: 경고 — 원인 미상" | tee "$PUB/ticket_S3-2.txt"
  echo
  echo "점검표가 경고를 냈다. 원인을 층별로 좁혀 고치고, 보호가 없던 구간을 보고하라."
  ;;

3)
  if [ "$(role boston)" != "SNAPSHOT STANDBY" ]; then
    echo "중단: boston 이 SNAPSHOT STANDBY 가 아니다. 과제 3-3.2 의 전환을 먼저 할 것."
    exit 1
  fi
  echo "=== [3-3] Snapshot 시험 중 Primary 의 정상 업무 ==="
  q chicago "begin execute immediate 'drop table system.exam_snap_src purge'; exception when others then null; end;
/
create table system.exam_snap_src as select level id, 'Snapshot 중 Primary 입력' memo from dual connect by level <= 300;" >/dev/null
  mark 'S3-3a' 'Snapshot 시험 중 Primary 입력 1 (exam_snap_src 300행)'
  switch_n 2
  mark 'S3-3b' 'Snapshot 시험 중 Primary 입력 2'
  switch_n 1
  echo
  echo "Primary 업무가 쌓였다. 시험을 마치고 boston 을 원래 역할로 되돌린 뒤, 이 행들까지 따라왔는지 확인하라."
  ;;

*)
  echo "사용법: $0 1|2|3"; exit 1 ;;
esac
