#!/bin/bash
# ============================================================================
#  20_gi_install.sh — Grid Infrastructure 무인 설치
#  grid 계정으로 첫 번째 노드에서만 실행한다.
#
#    bash 20_gi_install.sh unzip     Grid 미디어 압축 해제 (약 4분)
#    bash 20_gi_install.sh rsp       응답 파일 생성 (/tmp/gridsetup.rsp)
#    bash 20_gi_install.sh install    gridSetup.sh -silent 실행 (약 6분)
#    bash 20_gi_install.sh all        위 셋을 순서대로
#
#  비밀번호는 환경 변수에서 읽는다:  export RAC_ASM_PW='...'
# ============================================================================
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
. "$BASE/config.env"
[ "$(id -un)" = "grid" ] || { echo "grid 계정으로 실행한다."; exit 1; }

do_unzip() {
  [ -f "$GRID_ZIP" ] || { echo "미디어가 없다: $GRID_ZIP"; exit 1; }
  if [ -x "${GRID_HOME}/gridSetup.sh" ]; then
    echo "  이미 풀려 있다: ${GRID_HOME}/gridSetup.sh"; return
  fi
  echo "=== Grid 미디어 압축 해제 (2.9GB) ==="
  t0=$(date +%s)
  cd "$GRID_HOME" && unzip -q "$GRID_ZIP"
  echo "  소요 $(( ($(date +%s)-t0) / 60 ))분 $(( ($(date +%s)-t0) % 60 ))초"
  ls "$GRID_HOME" | head -10
}

do_rsp() {
  : "${RAC_ASM_PW:?환경 변수 RAC_ASM_PW 를 먼저 설정한다 (SYSASM/ASMSNMP 비밀번호)}"
  # 실제 인터페이스 이름을 찾는다. 응답 파일에 잘못된 이름을 적으면 설치가 실패한다.
  OCT3=$(echo "$PUB_SUBNET" | cut -d. -f1-3)
  PUBIF=$(ip -o -4 addr show | awk -v p="^${OCT3}\." '$4 ~ p {print $2}' | head -1)
  POCT3=$(echo "$PRIV_SUBNET" | cut -d. -f1-3)
  PRVIF=$(ip -o -4 addr show | awk -v p="^${POCT3}\." '$4 ~ p {print $2}' | head -1)
  [ -n "$PUBIF" ] && [ -n "$PRVIF" ] || { echo "인터페이스를 찾지 못했다. ip -o -4 addr show 확인."; exit 1; }
  echo "  공용 $PUBIF ($PUB_SUBNET) / 사설 $PRVIF ($PRIV_SUBNET)"

  CRS_PLAIN=$(echo "$DG_CRS_DISKS" | tr -d "'")
  # disksWithFailureGroupNames 는 "디스크,장애그룹" 쌍이다. 이름을 비워 자동 배정에 맡긴다.
  CRS_FG=$(echo "$CRS_PLAIN" | sed 's/,/,,/g'),

  sed -e "s|@INVENTORY@|$INVENTORY|g"       -e "s|@GRID_BASE@|$GRID_BASE|g" \
      -e "s|@SCAN_NAME@|$SCAN_NAME|g"       -e "s|@SCAN_PORT@|$SCAN_PORT|g" \
      -e "s|@CLUSTER_NAME@|$CLUSTER_NAME|g" -e "s|@NODE1_NAME@|$NODE1_NAME|g" \
      -e "s|@NODE2_NAME@|$NODE2_NAME|g"     -e "s|@PUBIF@|$PUBIF|g" \
      -e "s|@PRVIF@|$PRVIF|g"               -e "s|@PUB_SUBNET@|$PUB_SUBNET|g" \
      -e "s|@PRIV_SUBNET@|$PRIV_SUBNET|g"   -e "s|@DG_CRS@|$DG_CRS|g" \
      -e "s|@DG_CRS_REDUNDANCY@|$DG_CRS_REDUNDANCY|g" -e "s|@ASM_AU_SIZE@|$ASM_AU_SIZE|g" \
      -e "s|@CRS_DISKS_PLAIN@|$CRS_PLAIN|g" -e "s|@CRS_DISKS_FG@|$CRS_FG|g" \
      -e "s|@ASM_DISCOVERY@|$ASM_DISCOVERY|g" \
      "$BASE/templates/gridsetup.rsp.tmpl" > /tmp/gridsetup.rsp
  # 비밀번호는 마지막에 넣고 파일 권한을 좁힌다
  sed -i "s|@ASM_PW@|${RAC_ASM_PW}|g" /tmp/gridsetup.rsp
  chmod 600 /tmp/gridsetup.rsp
  echo "  생성: /tmp/gridsetup.rsp (비밀번호 줄은 아래에서 가린다)"
  grep -v '^#' /tmp/gridsetup.rsp | grep -v '^$' | sed 's/\(Password=\).*/\1********/'
}

do_install() {
  [ -f /tmp/gridsetup.rsp ] || { echo "응답 파일이 없다. 먼저 rsp 를 실행한다."; exit 1; }
  echo "=== gridSetup.sh -silent 시작 (약 6분) ==="
  t0=$(date +%s)
  cd "$GRID_HOME"
  ./gridSetup.sh -silent -responseFile /tmp/gridsetup.rsp -waitForCompletion 2>&1 | tail -40
  echo "  소요 $(( ($(date +%s)-t0) / 60 ))분"
  echo
  echo "!! 응답 파일에 비밀번호가 평문으로 들어 있다. 지운다."
  shred -u /tmp/gridsetup.rsp 2>/dev/null || rm -f /tmp/gridsetup.rsp
  echo
  echo "다음: root 계정으로 21_root_sh.sh — 반드시 ${NODE1_NAME} 먼저, 끝난 뒤 ${NODE2_NAME}"
}

case "${1:-all}" in
  unzip)   do_unzip ;;
  rsp)     do_rsp ;;
  install) do_install ;;
  all)     do_unzip; do_rsp; do_install ;;
  *) echo "사용법: bash 20_gi_install.sh {unzip|rsp|install|all}"; exit 1 ;;
esac
