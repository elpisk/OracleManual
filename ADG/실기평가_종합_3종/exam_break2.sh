#!/bin/bash
#===============================================================================
# exam_break2.sh — 시나리오 2 [최상] 전환 · 재해 · 재구축 — 장애 주입
#
#   사용법 :  ./exam_break2.sh 1|2|3
#
#     1 : 계획 전환(boston 으로) 전에 숨은 장애물 두 개
#         → Broker 전송 차단 + boston 정적 등록 오타 (14장 · 16장)
#     2 : (boston 이 Primary 인 상태에서) 먼저 chicago Standby 가 조용히 죽고,
#         이어 boston 사이트 전체가 내려간다. 플래시백도 꺼져 있었다
#         → 손실을 동반한 Failover 판단 (16장 · 15장)
#     3 : 옛 Primary(boston) 되살리기 — Reinstate 가 될 것인가, 재구축인가
#         (주입 없음. 2 의 결과 위에서 진행한다 — 6장 · 16장)
#
#   주의 : 개인 실습 랩(chicago / boston)에서만 실행한다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"
STEP="${1:-}"

case "$STEP" in
1)
  need_ok chicago chicago
  echo "=== [2-1] 지난주 점검 작업의 흔적 (기록은 남지 않았다) ==="
  dg chicago "edit database 'boston' set property 'LogShipping'='OFF';" >/dev/null
  bo_ssh "$BO_ENV; sed -i 's/boston_DGMGRL/boston_DGMRGL/' \$ORACLE_HOME/network/admin/listener.ora && lsnrctl reload >/dev/null" \
    && echo "  (작업 완료)"
  mark 'S2-1a' '전환 계획 공지 직전 입력'
  echo
  echo "오늘 밤 chicago 서버 점검을 위해 boston 으로 계획 전환(Switchover)한다."
  echo "전환 전 점검을 먼저 하고, 안전하다고 판단되면 전환하라. 전환 뒤 업무가 boston 에서 도는지 확인하라."
  dg chicago "show configuration"
  ;;

2)
  need_ok boston boston
  echo "=== [2-2] boston 이 Primary 로 업무 중 ==="
  mark 'S2-2a' 'boston Primary 업무 1'
  switch_n 1
  sleep 5
  echo "=== (아무도 모르게) chicago Standby 인스턴스가 죽었다 ==="
  ch_sql "shutdown abort" >/dev/null
  echo "=== (아무도 모르게) boston 의 플래시백이 꺼졌다 — 공간 확보 작업 ==="
  q boston "alter database flashback off;" >/dev/null
  mark 'S2-2b' 'boston Primary 업무 2'
  switch_n 1
  sleep 3
  mark 'S2-2c' 'boston Primary 업무 3'
  sleep 3
  mark 'S2-2d' 'boston Primary 업무 4 — 사이트 장애 직전'
  echo "=== boston 사이트 전체 장애 ==="
  bo_sql "shutdown abort" >/dev/null
  echo "  boston SHUTDOWN ABORT"
  echo
  echo "Primary(boston)가 내려갔다. 업무를 가장 빨리, 그리고 정확한 손실 보고와 함께 재개하라."
  echo "업무팀의 입력 기록은 $EX/business.log 에 있다."
  ;;

3)
  need_ok chicago chicago
  mark 'S2-3a' 'Failover 뒤 chicago Primary 업무'
  switch_n 2
  echo "=== [2-3] 상태 ==="
  dg chicago "show configuration"
  echo
  echo "boston 서버는 복구되었다 (인스턴스는 내려가 있다). boston 을 Standby 로 되돌려"
  echo "구성을 보호 상태로 복원하라. 되살리는 방법은 스스로 판단한다."
  ;;

*)
  echo "사용법: $0 1|2|3"; exit 1 ;;
esac
