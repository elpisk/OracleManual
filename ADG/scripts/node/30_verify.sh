#!/bin/bash
# ============================================================================
#  30_verify.sh — 동기화 검증
#    bash 30_verify.sh primary   Primary 에서 (전송 상태, 로그 스위치)
#    bash 30_verify.sh standby   Standby 에서 (적용 상태, 지연)
#    bash 30_verify.sh gap       적용 지연만 빠르게
# ============================================================================
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
. "$BASE/config.env"
export ORACLE_BASE=$ORA_BASE ORACLE_HOME=$ORA_HOME
export PATH=$ORACLE_HOME/bin:$PATH

case "${1:-standby}" in
primary)
  export ORACLE_SID=$PRI_SID
  sqlplus -s / as sysdba <<'EOS'
set lines 200 pages 100
col name for a12
prompt === 역할과 보호 모드 ===
select name, db_unique_name, database_role, open_mode,
       protection_mode, protection_level from v$database;
prompt === 전송 목적지 상태 (ERROR 열이 비어 있어야 한다) ===
col dest_name for a22
col destination for a14
col error for a34
select dest_id, dest_name, status, destination, error
  from v$archive_dest where dest_id in (1,2);
prompt === 로그 스위치를 일으켜 전송을 확인한다 ===
alter system switch logfile;
alter system switch logfile;
alter system archive log current;
select max(sequence#) as pri_max from v$archived_log where dest_id=1;
exit
EOS
  echo "이제 Standby 에서: bash 30_verify.sh standby"
  ;;

standby)
  export ORACLE_SID=$STB_SID
  sqlplus -s / as sysdba <<'EOS'
set lines 200 pages 100
col name for a12
prompt === 역할과 열림 모드 (READ ONLY WITH APPLY 여야 ADG 다) ===
select name, db_unique_name, database_role, open_mode from v$database;
prompt === 적용 프로세스 (MRP0 가 APPLYING_LOG 여야 한다) ===
select process, status, thread#, sequence#, block# from v$managed_standby
 where process in ('MRP0','RFS','ARCH') order by process, sequence#;
prompt === 적용 지연 ===
col name for a26
col value for a22
select name, value, unit from v$dataguard_stats
 where name in ('transport lag','apply lag','apply finish time');
prompt === 수신·적용된 마지막 시퀀스 ===
select thread#, max(sequence#) as received from v$archived_log group by thread#;
select thread#, max(sequence#) as applied  from v$archived_log
 where applied='YES' group by thread#;
prompt === 최근 오류 ===
col message for a92
select timestamp, message from v$dataguard_status
 where severity in ('Error','Fatal') and rownum <= 10 order by timestamp desc;
exit
EOS
  ;;

gap)
  export ORACLE_SID=$STB_SID
  sqlplus -s / as sysdba <<'EOS'
set lines 140 pages 40 feedback off
col name for a26
select name, value from v$dataguard_stats where name in ('transport lag','apply lag');
select process, status, sequence# from v$managed_standby where process='MRP0';
exit
EOS
  ;;
*) echo "사용법: bash 30_verify.sh {primary|standby|gap}"; exit 1 ;;
esac
