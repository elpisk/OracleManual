#!/bin/bash
#===============================================================================
# exam_break3.sh — 시나리오 3 (리두 로그 계열) 장애 유발
#
#   사용법 :  ./exam_break3.sh 1|2|3
#
#     1 : INACTIVE 그룹의 멤버 한 개 유실 (데이터베이스 OPEN 유지)
#     2 : INACTIVE 그룹 전손 + 정상 종료
#     3 : CURRENT  그룹 전손 + SHUTDOWN ABORT
#
#   대상 그룹은 실행 시점의 v$log 상태를 보고 스크립트가 스스로 고른다.
#   따라서 시험 때마다 그룹 번호가 달라진다. 번호를 외워 온 답안은 통하지 않는다.
#
# 주의 : 개인 실습 환경(ORCL) 에서만 실행한다.
#===============================================================================
set -u
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=orcl
export PATH=$ORACLE_HOME/bin:/usr/local/bin:/usr/bin:/bin
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

pick() {   # $1 = INACTIVE | CURRENT   -> 그룹 번호를 표준출력으로
  sqlplus -s / as sysdba <<EOS | tr -d ' \n'
set feed off pages 0 head off
select min(group#) from v\$log where status='$1';
EOS
}

members() { # $1 = 그룹 번호 -> 멤버 경로 목록
  sqlplus -s / as sysdba <<EOS | sed '/^$/d'
set feed off pages 0 head off lines 200
select member from v\$logfile where group# = $1;
EOS
}

case "$STEP" in
1)
  echo "=== [3-1] INACTIVE 그룹의 멤버 한 개 유실 ==="
  mark 'S3-1' '멤버 하나가 사라져도 서비스는 계속되는가'
  G=$(pick INACTIVE)
  echo "  대상 그룹 : $G"
  M=$(members "$G" | grep '/fra/' | head -1)   # 다중화 사본(b멤버) 쪽을 지운다
  echo "  삭제할 멤버 : $M"
  rm -f "$M"
  sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
alter system switch logfile;
alter system switch logfile;
alter system checkpoint;
EOS
  echo "=== 증상 ==="
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
col member for a46
select group#, member, status from v$logfile order by group#, member;
select group#, sequence#, status from v$log order by group#;
EOS
  echo
  echo "데이터베이스는 OPEN 을 유지한다."
  ;;

2)
  echo "=== [3-2] INACTIVE 그룹 전손 + 정상 종료 ==="
  mark 'S3-2' '그룹이 통째로 사라졌지만 정상 종료였다'
  G=$(pick INACTIVE)
  echo "  대상 그룹 : $G"
  members "$G" > /tmp/_g2.txt          # 종료 전에 목록을 확보해 둔다
  sed 's/^/  멤버: /' /tmp/_g2.txt
  sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
shutdown immediate
EOS
  while read -r M; do [ -n "$M" ] && rm -f "$M"; done < /tmp/_g2.txt
  echo "  삭제 완료 (그룹 $G 의 멤버 전부)"
  echo "=== 재기동 시도 ==="
  sqlplus -s / as sysdba <<'EOS'
set lines 200 feed off
whenever sqlerror continue
startup
select status from v$instance;
EOS
  ;;

3)
  echo "=== [3-3] CURRENT 그룹 전손 + SHUTDOWN ABORT ==="
  mark 'S3-3' '커밋했지만 데이터파일에 아직 없는 변경'
  echo "  체크포인트를 한 번 찍어 여기까지는 데이터파일에 반영시킨다"
  sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
alter system checkpoint;
EOS
  mark 'S3-3x' '이 행은 CURRENT 리두에만 있다'
  G=$(pick CURRENT)
  echo "  대상 그룹(CURRENT) : $G"
  members "$G" > /tmp/_g3.txt
  sed 's/^/  멤버: /' /tmp/_g3.txt
  sqlplus -s / as sysdba <<'EOS' >/dev/null
set feed off
shutdown abort
EOS
  while read -r M; do [ -n "$M" ] && rm -f "$M"; done < /tmp/_g3.txt
  echo "  삭제 완료"
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
