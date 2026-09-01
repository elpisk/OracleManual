#!/bin/bash
# ============================================================================
#  12_dg_params.sh — Primary 의 Data Guard 파라미터 설정
#  Primary 서버에서 oracle 계정으로 실행한다.
#
#  사용법: bash 12_dg_params.sh
# ============================================================================
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
. "$BASE/config.env"
export ORACLE_BASE=$ORA_BASE ORACLE_HOME=$ORA_HOME ORACLE_SID=$PRI_SID
export PATH=$ORACLE_HOME/bin:$PATH
SQL="sqlplus -s / as sysdba"

echo "########## [1] FRA 설정 (재기동 필요) ##########"
$SQL <<EOS
set echo on
whenever sqlerror continue
alter system set db_recovery_file_dest_size = ${FRA_SIZE} scope=spfile;
alter system set db_recovery_file_dest = '${FRA}' scope=spfile;
shutdown immediate
startup
exit
EOS

echo "########## [2] Data Guard 파라미터 ##########"
# dest_1 은 로컬 아카이브, dest_2 가 Standby 로의 전송이다.
# valid_for 절이 역할이 바뀌었을 때 어느 목적지를 쓸지 결정한다.
$SQL <<EOS
set echo on
whenever sqlerror continue
alter system set log_archive_config = 'dg_config=(${PRI_UNIQUE},${STB_UNIQUE})' scope=both;
alter system set fal_server = '${STB_UNIQUE}' scope=both;
alter system set fal_client = '${PRI_UNIQUE}' scope=both;
alter system set standby_file_management = 'AUTO' scope=both;
alter system set log_archive_dest_1 =
  'location=use_db_recovery_file_dest valid_for=(all_logfiles,all_roles) db_unique_name=${PRI_UNIQUE}' scope=both;
alter system set log_archive_dest_2 =
  'service=${STB_UNIQUE} ${TRANSPORT_MODE} valid_for=(online_logfiles,primary_role) db_unique_name=${STB_UNIQUE}' scope=both;
alter system set log_archive_dest_state_2 = enable scope=both;
exit
EOS

echo "########## [3] 확인 ##########"
$SQL <<'EOS'
set lines 300 pages 300
col name for a30
col value for a72
select name, value from v$parameter
 where name in ('db_name','db_unique_name','log_archive_config',
                'log_archive_dest_1','log_archive_dest_2',
                'log_archive_dest_state_1','log_archive_dest_state_2',
                'fal_server','fal_client','standby_file_management',
                'remote_login_passwordfile')
 order by name;
exit
EOS

echo "########## 완료 ##########"
echo "다음: bash 20_standby_build.sh pwfile"
