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

#--- 앞 케이스를 복구하지 않으면 다음 케이스를 주입할 수 없다 -------------------
# 각 단계는 시작할 때 hr.exam_log 에 표식 행을 넣으므로 DB 가 OPEN 이어야 한다.
STATE=$(sqlplus -s / as sysdba <<'EOS' | tr -d '[:space:]'
set feed off pages 0 head off
select open_mode from v$database;
EOS
)
# 사람이 읽을 수 있는 상태 이름으로 바꾼다
case "$STATE" in
  *ORA-01034*|*ORA-12560*|"") SHOW="인스턴스 정지" ;;
  *ORA-01507*)                SHOW="NOMOUNT (인스턴스만 기동)" ;;
  *MOUNTED*)                  SHOW="MOUNTED" ;;
  *READONLY*)                 SHOW="READ ONLY" ;;
  *)                          SHOW="$STATE" ;;
esac
if [ "$STATE" != "READWRITE" ]; then
  echo "=============================================================="
  echo " 중단 : 데이터베이스가 READ WRITE 가 아니다 (현재: $SHOW)"
  echo
  echo " 앞 케이스의 복구가 끝나지 않았다."
  echo "   · 복구를 계속하려면 이 스크립트를 실행하지 말 것"
  echo "   · 포기하고 다음 케이스로 넘어가려면 감독관이 아래를 실행한 뒤"
  echo "     다시 이 스크립트를 실행한다"
  echo "       /home/oracle/exam/exam_reset.sh"
  echo "=============================================================="
  exit 1
fi


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
