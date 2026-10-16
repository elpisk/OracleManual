#!/bin/bash
#===============================================================================
# exam_prep.sh — ADG 종합 실기평가 준비 (감독자가 시험 전에 한 번)
#
#   하는 일
#     ① 기준 상태 점검 — 16장을 마친 상태여야 한다
#        chicago PRIMARY / boston PHYSICAL STANDBY · READ ONLY WITH APPLY
#        Broker 구성 SUCCESS, FSFO Disabled, 양쪽 FLASHBACK_ON=YES
#     ② 확인용 테이블 system.exam_log 생성 (CDB 루트)
#     ③ boston 의 비밀번호 파일과 listener.ora 를 감독자 사본으로 보관
#        ($EX/proctor — examadm 전용이라 응시자는 볼 수 없다)
#     ④ 기준선 기록 ($PUB/baseline.txt)
#
#   실행 :  [examadm@chicago-srv ~]$ /home/examadm/exam/exam_prep.sh
#
#   이 스크립트가 끝나면 두 VM 을 정지하고 스냅샷 exam-base 를 뜬다 (운영가이드 1-5).
#   시나리오 사이의 복원은 그 스냅샷으로 한다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"

echo "=== ① 기준 상태 점검 ==="
fail=0
chk() { if [ "$2" = "$3" ]; then echo "  OK    $1 = $2"; else echo "  FAIL  $1 = '$2' (기대 '$3')"; fail=1; fi; }
chk "chicago 역할"      "$(role chicago)" "PRIMARY"
chk "boston 역할"       "$(role boston)"  "PHYSICAL STANDBY"
chk "boston OPEN_MODE"  "$(q boston "select open_mode from v\$database;" | sed 's/^ *//;s/ *$//')" "READ ONLY WITH APPLY"
chk "chicago FLASHBACK" "$(q chicago "select flashback_on from v\$database;" | tr -d '[:space:]')" "YES"
chk "boston FLASHBACK"  "$(q boston  "select flashback_on from v\$database;" | tr -d '[:space:]')" "YES"
chk "Broker 구성"       "$(cfg_status chicago)" "SUCCESS"
dg chicago "show configuration" | grep -q "Fast-Start Failover: *Disabled" && echo "  OK    FSFO Disabled" || { echo "  FAIL  FSFO 가 켜져 있다 (14·16장 정리 순서로 끈다)"; fail=1; }
ch_ssh true && echo "  OK    examadm → oracle@chicago-srv SSH" || { echo "  FAIL  examadm → oracle@chicago-srv 암호 없는 SSH 가 안 된다 (운영가이드 1-3)"; fail=1; }
bo_ssh true && echo "  OK    examadm → oracle@boston-srv SSH"  || { echo "  FAIL  examadm → oracle@boston-srv 암호 없는 SSH 가 안 된다 (운영가이드 1-3)"; fail=1; }
ch_ssh "ssh -o BatchMode=yes -o ConnectTimeout=5 oracle@${BOSTON_HOST} true" && echo "  OK    oracle@chicago → boston SSH (응시자 scp 용)" || { echo "  FAIL  oracle 의 chicago → boston 암호 없는 SSH 가 안 된다 (운영가이드 1-3)"; fail=1; }
[ $fail -eq 0 ] || { echo "중단: 기준 상태가 아니다. 위 FAIL 항목을 정리한 뒤 다시 실행한다."; exit 1; }

echo "=== ② 확인용 테이블 ==="
q chicago "begin execute immediate 'drop table system.exam_log purge'; exception when others then null; end;
/
begin execute immediate 'drop tablespace exam_ts including contents and datafiles'; exception when others then null; end;
/
create table system.exam_log (step varchar2(20), memo varchar2(200), reg_time date, scn number);" >/dev/null
: > "$PUB/business.log"
mark 'BASE' '시험 시작 기준선'
switch_n 2

echo "=== ③ 감독자 사본 (boston) ==="
scp -q $SSHOPT oracle@"$BOSTON_HOST":"$OH/dbs/orapwboston" "$EX/proctor/orapwboston" &&
scp -q $SSHOPT oracle@"$BOSTON_HOST":"$OH/network/admin/listener.ora" "$EX/proctor/listener.ora.boston" &&
chmod 600 "$EX/proctor/"* && ls -l "$EX/proctor"

echo "=== ④ 기준선 ==="
{
  echo "작성 시각 $(date '+%F %T')"
  q chicago "select 'chicago '||database_role||' '||open_mode||' resetlogs_change#='||resetlogs_change#||' current_scn='||current_scn from v\$database;
select 'chicago thread 1 current seq='||sequence# from v\$log where status='CURRENT';"
  q boston  "select 'boston  '||database_role||' '||open_mode||' flashback='||flashback_on from v\$database;
select 'boston  MRP0 '||status||' seq='||sequence# from v\$managed_standby where process='MRP0';"
  q chicago "select 'exam_log rows='||count(*) from system.exam_log;"
} | tee "$PUB/baseline.txt"

echo
echo "준비 완료. 이제 boston → chicago 순으로 데이터베이스를 내리고 두 VM 을 끈 뒤"
echo "스냅샷 exam-base 를 뜬다 (운영가이드 1-5). 시나리오 사이에는 그 스냅샷으로 되돌린다."
