#!/bin/bash
# ============================================================================
#  21_root_sh.sh — Grid 홈의 root.sh 실행
#
#  !! 반드시 첫 번째 노드에서 완료된 뒤 두 번째 노드에서 실행한다.
#     첫 노드의 root.sh 가 OCR 과 보팅 파일을 초기화하고 +CRS 를 만든다.
#     동시에 실행하면 이 초기화가 충돌한다.
#
#  사용법: sudo bash 21_root_sh.sh
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
. "$CFG"
[ "$(id -u)" -eq 0 ] || { echo "root 로 실행한다."; exit 1; }

ME=$(hostname -s)
if [ "$ME" != "$NODE1_NAME" ]; then
  echo "이 노드는 $ME 다."
  echo "$NODE1_NAME 의 root.sh 가 이미 성공했는지 확인했는가? (Succeeded 메시지)"
  printf "계속하려면 yes 를 입력한다: "
  read -r ans
  [ "$ans" = "yes" ] || { echo "중단한다."; exit 1; }
fi

LOG=/tmp/rootsh_${ME}_$(date +%H%M%S).log
echo "=== ${GRID_HOME}/root.sh 실행 — ${NODE1_NAME} 은 약 6분, 두 번째 노드는 약 2분 ==="
t0=$(date +%s)
"${GRID_HOME}/root.sh" 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
echo "  소요 $(( ($(date +%s)-t0) / 60 ))분  로그: $LOG"

if grep -q "Succeeded" "$LOG"; then
  echo "  root.sh 성공"
  if [ "$ME" = "$NODE1_NAME" ]; then
    echo
    echo "보팅 파일 확인:"
    su - grid -c "${GRID_HOME}/bin/crsctl query css votedisk" 2>&1
    echo
    echo "이제 ${NODE2_NAME} 에서 같은 스크립트를 실행한다."
  else
    echo
    echo "두 노드 모두 완료. 20_gi_install.sh 를 실행한 노드에서 grid 계정으로:"
    echo "  ${GRID_HOME}/gridSetup.sh -executeConfigTools -responseFile <응답파일> -silent"
    echo "그다음 bash 50_postcheck.sh"
  fi
else
  echo "  !! root.sh 가 성공 메시지를 남기지 않았다. 로그를 확인한다: $LOG"
  exit ${rc:-1}
fi
