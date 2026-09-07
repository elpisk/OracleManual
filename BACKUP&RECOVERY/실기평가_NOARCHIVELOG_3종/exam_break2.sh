#!/bin/bash
#===============================================================================
# exam_break2.sh — 시나리오 2 (컨트롤파일 계열) 장애 유발
#
#   사용법 :  ./exam_break2.sh 1|2|3
#
#     1 : 컨트롤파일 한 개만 유실 (사본 생존)
#     2 : 컨트롤파일 전손 — Binary 백업본 있음
#     3 : 컨트롤파일 전손 — Binary 백업본 없음, trace 만 있음
#         trace 는 exam_tbs 를 만들기 '전' 에 받은 것이라 목록이 어긋나 있다
#
# 주의 : 개인 실습 환경(ORCL) 에서만 실행한다.
#===============================================================================
set -u
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=orcl
export PATH=$ORACLE_HOME/bin:/usr/local/bin:/usr/bin:/bin
D1=/u01/app/oracle/oradata/orcl
D2=/u02/oradata/orcl
BK=/home/oracle/backup/exam_nolog
HID=/home/oracle/backup/_proctor/hidden
STEP="${1:-}"

mark() {
  sqlplus -s / as sysdba <<EOS
set feed off
insert into hr.exam_log values ('$1','$2', sysdate);
commit;
EOS
}

case "$STEP" in
1)
  echo "=== [2-1] 컨트롤파일 한 개 유실 ==="
  mark 'S2-1' '사본이 남아 있을 때'
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
col name for a52
select name from v$controlfile;
EOS
  sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
shutdown immediate
EOS
  rm -f "$D1/control02.ctl"
  echo "  삭제: $D1/control02.ctl"
  echo "=== 재기동 시도 ==="
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
whenever sqlerror continue
startup
select status from v$instance;
EOS
  ;;

2)
  echo "=== [2-2] 컨트롤파일 전손 — Binary 백업본 있음 ==="
  mark 'S2-2' 'Binary 백업본으로 되돌릴 때'
  echo "  먼저 Binary 백업을 하나 받아 둔다(운영에서 정기적으로 받는 그 백업이다)"
  sqlplus -s / as sysdba <<EOS
set feed off
alter database backup controlfile to '$BK/control_bin.bkp' reuse;
EOS
  ls -l "$BK/control_bin.bkp" | sed 's/^/  /'
  echo "  백업 이후 업무가 더 발생한다"
  mark 'S2-2b' 'Binary 백업 이후에 들어온 행'
  sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
shutdown abort
EOS
  rm -f "$D1"/control0*.ctl "$D2"/control0*.ctl
  echo "  삭제: 컨트롤파일 3개 전부"
  echo "=== 재기동 시도 ==="
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
whenever sqlerror continue
startup
select status from v$instance;
EOS
  ;;

3)
  echo "=== [2-3] 컨트롤파일 전손 — Binary 백업본 없음 ==="
  mark 'S2-3' 'trace 만 남았을 때'
  sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
shutdown immediate
EOS
  rm -f "$D1"/control0*.ctl "$D2"/control0*.ctl
  # 응시자에게는 보이지 않게 치운다. 감독자 복원점($SAFE)은 건드리지 않는다.
  mkdir -p "$HID"
  mv -f "$BK"/control_bin.bkp "$HID"/ 2>/dev/null
  mv -f "$BK"/control0*.ctl "$HID"/ 2>/dev/null
  echo "  제거: 컨트롤파일 3개 + 응시자용 백업의 컨트롤파일 사본 전부"
  echo "  남은 것: $BK/cf_exam.sql (trace)"
  ls -l "$BK/cf_exam.sql" | sed 's/^/  /'
  echo
  echo "  참고 - trace 안의 데이터파일 줄 수"
  sed -n '/^CREATE CONTROLFILE.*NORESETLOGS/,/^;/p' "$BK/cf_exam.sql" | grep -c 'dbf' | sed 's/^/    /'
  echo "  참고 - 실제 데이터파일 개수"
  ls "$D1"/*.dbf | grep -v temp | wc -l | sed 's/^/    /'
  echo "=== 재기동 시도 ==="
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
whenever sqlerror continue
startup
select status from v$instance;
EOS
  ;;

*)
  echo "사용법: $0 1|2|3"
  exit 1
  ;;
esac
