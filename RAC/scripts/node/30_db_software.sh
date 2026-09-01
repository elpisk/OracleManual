#!/bin/bash
# ============================================================================
#  30_db_software.sh — RAC 용 데이터베이스 소프트웨어 설치 (SWONLY)
#  oracle 계정으로 첫 번째 노드에서만 실행한다. 두 번째 노드로는
#  설치 관리자가 직접 복사한다(CLUSTER_NODES 지정 덕분).
#
#    bash 30_db_software.sh unzip     미디어 압축 해제 (약 5분)
#    bash 30_db_software.sh rsp       응답 파일 생성
#    bash 30_db_software.sh install   runInstaller -silent (약 8분)
#    bash 30_db_software.sh profile   oracle 계정 .bash_profile 작성 (노드번호 인자)
#    bash 30_db_software.sh all
#
#  기존 단일 인스턴스 홈(dbhome_1)을 재사용하지 않고 새 홈을 만든다.
#  RAC 옵션이 링크되어 있지 않고 클러스터 노드 목록도 없기 때문이다.
# ============================================================================
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
. "$BASE/config.env"

do_unzip() {
  [ "$(id -un)" = "oracle" ] || { echo "oracle 계정으로 실행한다."; exit 1; }
  [ -f "$DB_ZIP" ] || { echo "미디어가 없다: $DB_ZIP"; exit 1; }
  if [ -x "${ORA_HOME}/runInstaller" ]; then echo "  이미 풀려 있다"; return; fi
  mkdir -p "$ORA_HOME"
  echo "=== DB 미디어 압축 해제 (3.1GB) ==="
  t0=$(date +%s)
  cd "$ORA_HOME" && unzip -q "$DB_ZIP"
  echo "  소요 $(( ($(date +%s)-t0) / 60 ))분"
}

do_rsp() {
  sed -e "s|@INST_GROUP@|$INST_GROUP|g" -e "s|@INVENTORY@|$INVENTORY|g" \
      -e "s|@ORA_HOME@|$ORA_HOME|g"     -e "s|@ORA_BASE@|$ORA_BASE|g" \
      -e "s|@NODE1_NAME@|$NODE1_NAME|g" -e "s|@NODE2_NAME@|$NODE2_NAME|g" \
      "$BASE/templates/db.rsp.tmpl" > /tmp/db.rsp
  chmod 644 /tmp/db.rsp
  echo "  생성: /tmp/db.rsp"
  grep -v '^#' /tmp/db.rsp | grep -v '^$'
}

do_install() {
  [ "$(id -un)" = "oracle" ] || { echo "oracle 계정으로 실행한다."; exit 1; }
  # 인벤토리 안에 남은 백업 파일이 있으면 INS-32050 이 난다. 먼저 확인한다.
  stray=$(find "$INVENTORY" -maxdepth 1 \( -name '*.orig' -o -name '*.bak' \) 2>/dev/null)
  if [ -n "$stray" ]; then
    echo "  !! 인벤토리 안에 백업 파일이 남아 있다. 설치 전에 옮겨야 한다(INS-32050):"
    echo "$stray" | sed 's/^/     /'
    echo "     sudo bash 13_prereq_fix.sh 를 다시 실행하면 정리된다."
    exit 1
  fi
  echo "=== runInstaller -silent (약 8분) ==="
  t0=$(date +%s)
  cd "$ORA_HOME"
  # -ignorePrereqFailure 는 swap 크기 같은 선택 요구 사항을 넘긴다.
  # 필수 요구 사항은 14_cluvfy.sh 에서 이미 통과시켰다.
  ./runInstaller -silent -responseFile /tmp/db.rsp -waitForCompletion \
                 -ignorePrereqFailure 2>&1 | tail -30
  echo "  소요 $(( ($(date +%s)-t0) / 60 ))분"
  echo
  echo "다음: 두 노드 모두에서 root 로"
  echo "  ${ORA_HOME}/root.sh"
  echo "(Grid 의 root.sh 와 달리 순서에 민감하지 않다)"
}

do_profile() {
  [ "$(id -u)" -eq 0 ] || { echo "root 로 실행한다."; exit 1; }
  N="${2:-}"
  case "$N" in 1|2) ;; *) echo "사용법: sudo bash 30_db_software.sh profile <1|2>"; exit 1 ;; esac
  cat > /home/oracle/.bash_profile <<EOC
[ -f /etc/bashrc ] && . /etc/bashrc
umask 022
export ORACLE_BASE=${ORA_BASE}
export ORACLE_HOME=${ORA_HOME}
export ORACLE_SID=${DB_SID_PREFIX}${N}
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib
EOC
  chown oracle:${INST_GROUP} /home/oracle/.bash_profile
  echo "  작성 완료 — ORACLE_SID=${DB_SID_PREFIX}${N}"
  # SID 를 잘못 두면 rac2 에서 접속했는데 racdb1 을 찾아 ORA-01034 가 난다
}

case "${1:-all}" in
  unzip)   do_unzip ;;
  rsp)     do_rsp ;;
  install) do_install ;;
  profile) do_profile "$@" ;;
  all)     do_unzip; do_rsp; do_install ;;
  *) echo "사용법: bash 30_db_software.sh {unzip|rsp|install|profile <1|2>|all}"; exit 1 ;;
esac
