#!/bin/bash
# ============================================================================
#  14_cluvfy.sh — 설치 전 점검
#  grid 계정으로 한 노드에서만 실행한다.
#  실패 항목을 남긴 채 gridSetup.sh 로 넘어가지 않는다.
#  설치 도중 실패를 되돌리는 비용이 여기서 통과시키는 비용보다 훨씬 크다.
#
#  사용법: bash 14_cluvfy.sh
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
. "$CFG"
[ "$(id -un)" = "grid" ] || { echo "grid 계정으로 실행한다."; exit 1; }
[ -x "${GRID_HOME}/runcluvfy.sh" ] || {
  echo "Grid 미디어가 풀려 있지 않다: ${GRID_HOME}/runcluvfy.sh"
  echo "먼저 20_gi_install.sh unzip 을 실행한다."; exit 1; }

LOG=/tmp/cluvfy_$(date +%H%M%S).log
cd "$GRID_HOME"
./runcluvfy.sh stage -pre crsinst -n ${NODE1_NAME},${NODE2_NAME} 2>&1 | tee "$LOG"

echo
echo "=============================================================="
echo " 실패 항목 요약"
echo "=============================================================="
if grep -qE '\.\.\.FAILED|PRV[FGE]-[0-9]+' "$LOG"; then
  grep -E '\.\.\.FAILED' "$LOG" | sed 's/^/  /'
  echo "  --- 코드 ---"
  grep -oE '(PRV[FGE]|INS)-[0-9]+[^"]{0,90}' "$LOG" | sort -u | sed 's/^/  /'
  echo
  echo "  대부분은 13_prereq_fix.sh 로 해소된다. 다시 실행한 뒤 재점검한다."
  echo "  전체 로그: $LOG"
  exit 1
else
  echo "  없음 — 다음 단계로 넘어간다."
  echo "  전체 로그: $LOG"
fi
