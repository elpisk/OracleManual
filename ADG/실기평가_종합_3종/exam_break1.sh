#!/bin/bash
#===============================================================================
# exam_break1.sh — 시나리오 1 [최상] 멈춘 Standby 되살리기 — 장애 주입
#
#   사용법 :  ./exam_break1.sh 1|2|3
#
#     1 : Standby 의 파일 관리가 MANUAL 로 바뀐 채 Primary 에 테이블스페이스 추가
#         → UNNAMED 파일, Redo Apply 정지 (8장 · 13장)
#     2 : Standby 비밀번호 파일이 다른 비밀번호로 다시 만들어진 뒤 재기동
#         → 리두 전송 인증 실패 (3장 · 15장)
#     3 : Standby 호스트 장애 중 Primary 의 아카이브 두 개가 지워짐
#         → FAL 로 메울 수 없는 갭 (7장 · 15장 · 16장)
#
#   앞 과제가 복구되어 Broker 구성이 SUCCESS 일 때만 다음 과제를 주입한다.
#   주의 : 개인 실습 랩(chicago / boston)에서만 실행한다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"
STEP="${1:-}"

case "$STEP" in
1)
  need_ok chicago chicago
  echo "=== [1-1] 운영자가 Standby 설정을 바꿨다 (기록은 남기지 않았다) ==="
  dg chicago "edit database 'boston' set property 'StandbyFileManagement'='MANUAL';" >/dev/null
  echo "=== 업무팀이 Primary 에 테이블스페이스를 추가했다 ==="
  mark 'S1-1a' '테이블스페이스 추가 전 입력'
  DFDIR=$(ch_dfdir)
  q chicago "create tablespace exam_ts datafile '$DFDIR/exam_ts01.dbf' size 20M;
create table system.exam_ts_t (id number, memo varchar2(100)) tablespace exam_ts;
insert into system.exam_ts_t select level, '새 테이블스페이스의 업무 행' from dual connect by level <= 500;
commit;" >/dev/null
  echo "  exam_ts 생성, system.exam_ts_t 500행"
  mark 'S1-1b' '테이블스페이스 추가 뒤 입력'
  switch_n 1
  echo "  45초 기다린다 ..."; sleep 45
  echo "=== 증상 ==="
  dg chicago "show configuration"
  echo
  echo "Primary 는 정상이다. Standby 가 어떤 상태인지 진단하고, 데이터까지 되살려라."
  ;;

2)
  need_ok chicago chicago
  echo "=== [1-2] 운영자가 boston 의 비밀번호 파일을 '정리' 했다 ==="
  bo_ssh "$BO_ENV; cd \$ORACLE_HOME/dbs && orapwd file=orapwboston password='Exam#Wrong1' format=12.2 force=y" \
    && echo "  orapwboston 이 다른 비밀번호로 다시 만들어졌다"
  echo "=== 정기 점검으로 boston 인스턴스를 재기동했다 ==="
  bo_sql "shutdown immediate
startup" >/dev/null
  echo "  boston 재기동 완료"
  mark 'S1-2a' '재기동 직후 입력'
  switch_n 2
  mark 'S1-2b' '로그 전환 뒤 입력'
  echo "  60초 기다린다 ..."; sleep 60
  echo "=== 증상 ==="
  dg chicago "show configuration"
  echo
  echo "두 인스턴스 모두 떠 있다. 리두가 가고 있는지, 안 간다면 왜인지 밝히고 되살려라."
  ;;

3)
  need_ok chicago chicago
  echo "=== [1-3] boston 호스트 장애 (인스턴스가 비정상 종료되었다) ==="
  bo_sql "shutdown abort" >/dev/null
  echo "  boston SHUTDOWN ABORT"
  N0=$(q chicago "select sequence# from v\$log where status='CURRENT' and thread#=1;" | tr -d '[:space:]')
  mark 'S1-3a' 'Standby 장애 중 입력 1'
  switch_n 1
  mark 'S1-3b' 'Standby 장애 중 입력 2'
  switch_n 1
  mark 'S1-3c' 'Standby 장애 중 입력 3'
  switch_n 1
  mark 'S1-3d' 'Standby 장애 중 입력 4'
  switch_n 2
  echo "=== 야간 아카이브 정리 작업이 아카이브 두 개를 지웠다 ==="
  for s in $N0 $((N0+1)); do
    F=$(q chicago "select name from v\$archived_log where dest_id=1 and thread#=1 and sequence#=$s
                   and resetlogs_change#=(select resetlogs_change# from v\$database) and rownum=1;" | tr -d '[:space:]')
    [ -n "$F" ] && rm -f "$F" && echo "  삭제: $F"
  done
  echo "$N0 $((N0+1))" > "$EX/.s13_deleted"          # 감독자 확인용 (채점 시 대조)
  echo "  온라인 리두에 남아 있는지 :"
  q chicago "select '    group '||group#||' seq '||sequence#||' '||status from v\$log order by group#;"
  echo "=== boston 호스트 복구 — 인스턴스를 다시 올린다 ==="
  bo_sql "startup" >/dev/null
  echo "  60초 기다린다 ..."; sleep 60
  echo "=== 증상 ==="
  dg chicago "show configuration"
  echo
  echo "boston 은 다시 떴다. 따라잡을 수 있는지 판단하고, 못 한다면 Standby 를 살려라."
  echo "(Standby 를 버리고 다시 만드는 것은 마지막 수단이다. 시간과 손실을 비교해 정한다)"
  ;;

*)
  echo "사용법: $0 1|2|3"; exit 1 ;;
esac
