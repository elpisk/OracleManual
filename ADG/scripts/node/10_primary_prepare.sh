#!/bin/bash
# ============================================================================
#  10_primary_prepare.sh — Primary 준비
#    ARCHIVELOG 전환 + FORCE LOGGING + Standby Redo Log 생성
#  Primary 서버에서 oracle 계정으로 실행한다.
#
#  사용법: bash 10_primary_prepare.sh
# ============================================================================
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
. "$BASE/config.env"
export ORACLE_BASE=$ORA_BASE ORACLE_HOME=$ORA_HOME ORACLE_SID=$PRI_SID
export PATH=$ORACLE_HOME/bin:$PATH
SQL="sqlplus -s / as sysdba"

echo "########## [1] 현재 상태 ##########"
$SQL <<'EOS'
set lines 160 pages 60
col name for a12
select name, db_unique_name, database_role, open_mode, log_mode, force_logging
  from v$database;
exit
EOS

echo "########## [2] ARCHIVELOG + FORCE LOGGING ##########"
# Data Guard 의 전제 조건이다. 둘 다 없으면 리두가 온전히 남지 않는다.
$SQL <<'EOS'
set echo on
whenever sqlerror continue
shutdown immediate
startup mount
alter database archivelog;
alter database force logging;
alter database open;
select name, force_logging, log_mode, open_mode from v$database;
exit
EOS

echo "########## [3] Standby Redo Log ##########"
# 온라인 리두 그룹 수 + 1 개를 같은 크기로 만든다.
# 실시간 적용(real-time apply)의 조건이며, 역할 전환 뒤 Primary 가 될 때도 쓰인다.
SRLSQL=""
g=$SRL_START_GROUP
i=0
while [ $i -lt $SRL_COUNT ]; do
  sep=","
  [ $((i+1)) -eq $SRL_COUNT ] && sep=";"
  SRLSQL="${SRLSQL}  group ${g} ('${PRI_DATA}/stdbyredo0${g}.log') size ${SRL_SIZE} reuse${sep}
"
  g=$((g+1)); i=$((i+1))
done
$SQL <<EOS
set echo on
whenever sqlerror continue
alter database add standby logfile thread 1
${SRLSQL}
col member for a58
select group#, member, type from v\$logfile order by group#;
exit
EOS

echo "########## 완료 ##########"
echo "다음: bash 11_net_config.sh  (Oracle Net 파일 배포)"
