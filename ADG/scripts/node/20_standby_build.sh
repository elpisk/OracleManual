#!/bin/bash
# ============================================================================
#  20_standby_build.sh — Standby 생성
#
#    bash 20_standby_build.sh pwfile     Primary 의 패스워드 파일을 Standby 로 복사
#    bash 20_standby_build.sh nomount    최소 pfile 로 Standby 를 NOMOUNT 기동
#    bash 20_standby_build.sh duplicate  RMAN DUPLICATE 백그라운드 기동
#    bash 20_standby_build.sh watch      진행 감시
#    bash 20_standby_build.sh post       spfile 생성·파라미터 조정·Open Read Only + MRP
#
#  pwfile / duplicate / watch 는 Primary 에서, nomount / post 는 Standby 에서 실행한다.
#  비밀번호:  export ADG_SYS_PW='...'
# ============================================================================
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
. "$BASE/config.env"
export ORACLE_BASE=$ORA_BASE ORACLE_HOME=$ORA_HOME
export PATH=$ORACLE_HOME/bin:$PATH
RMANLOG=/home/oracle/dup_${STB_UNIQUE}.log
RMANCMD=/home/oracle/dup_${STB_UNIQUE}.rman

case "${1:-}" in

pwfile)
  # 패스워드 파일이 같아야 리두 전송 인증이 통과한다. 이름만 SID 에 맞춰 바꾼다.
  echo "=== 패스워드 파일 복사 (Primary -> Standby) ==="
  scp ${ORA_HOME}/dbs/orapw${PRI_SID} \
      oracle@${STB_HOST}:${ORA_HOME}/dbs/orapw${STB_SID}
  ssh oracle@${STB_HOST} "chmod 640 ${ORA_HOME}/dbs/orapw${STB_SID}; ls -l ${ORA_HOME}/dbs/orapw${STB_SID}"
  ;;

nomount)
  # DUPLICATE 는 보조(auxiliary) 인스턴스가 NOMOUNT 로 떠 있어야 시작한다.
  # 이 단계의 pfile 은 두 줄이면 충분하다. 나머지는 DUPLICATE 가 채운다.
  export ORACLE_SID=$STB_SID
  mkdir -p ${ORA_BASE}/admin/${STB_UNIQUE}/adump ${STB_DATA} ${STB_LOG} ${STB_CTL} ${FRA}
  cat > ${ORA_HOME}/dbs/init${STB_SID}.ora <<EOC
db_name=${DB_NAME}
enable_pluggable_database=true
EOC
  cat ${ORA_HOME}/dbs/init${STB_SID}.ora
  rm -f ${ORA_HOME}/dbs/spfile${STB_SID}.ora
  sqlplus -s / as sysdba <<EOS
set echo on
whenever sqlerror continue
startup pfile='${ORA_HOME}/dbs/init${STB_SID}.ora' nomount
select instance_name, status from v\$instance;
exit
EOS
  ;;

duplicate)
  : "${ADG_SYS_PW:?환경 변수 ADG_SYS_PW 를 먼저 설정한다}"
  export ORACLE_SID=$PRI_SID
  sed -e "s|@PRI_UNIQUE@|$PRI_UNIQUE|g" -e "s|@STB_UNIQUE@|$STB_UNIQUE|g" \
      -e "s|@DB_NAME@|$DB_NAME|g"       -e "s|@ORA_BASE@|$ORA_BASE|g" \
      -e "s|@PRI_DATA@|$PRI_DATA|g"     -e "s|@STB_DATA@|$STB_DATA|g" \
      -e "s|@STB_LOG@|$STB_LOG|g"       -e "s|@STB_CTL@|$STB_CTL|g" \
      -e "s|@MODE@|$TRANSPORT_MODE|g" \
      "$BASE/templates/dup_standby.rman.tmpl" > "$RMANCMD"
  echo "=== RMAN 접속 확인 ==="
  rman target "'sys/${ADG_SYS_PW}@${PRI_UNIQUE} as sysdba'" \
       auxiliary "'sys/${ADG_SYS_PW}@${STB_UNIQUE} as sysdba'" <<'EOS' 2>&1 | tail -8
exit
EOS
  echo "=== DUPLICATE 시작 — 10~25분. 로그: $RMANLOG ==="
  nohup rman target "'sys/${ADG_SYS_PW}@${PRI_UNIQUE} as sysdba'" \
        auxiliary "'sys/${ADG_SYS_PW}@${STB_UNIQUE} as sysdba'" \
        cmdfile="$RMANCMD" > "$RMANLOG" 2>&1 &
  echo "  pid=$!   진행 확인: bash 20_standby_build.sh watch"
  ;;

watch)
  for i in $(seq 0 40); do
    alive=$(pgrep -fc "$(basename $RMANCMD)" || true)
    printf "[+%02d분] 프로세스=%s | %s\n" "$i" "${alive:-0}" \
      "$(tail -2 "$RMANLOG" 2>/dev/null | tr '\n' ' ' | cut -c1-130)"
    [ "${alive:-0}" = "0" ] && [ "$i" -gt 0 ] && break
    sleep 60
  done
  echo "=== 로그 요약 ==="
  grep -nE 'RMAN-|ORA-|Finished Duplicate|Starting Duplicate' "$RMANLOG" | tail -30
  ;;

post)
  export ORACLE_SID=$STB_SID
  echo "########## [1] Standby 초기 상태 ##########"
  sqlplus -s / as sysdba <<'EOS'
set lines 160 pages 60
select name, db_unique_name, database_role, open_mode from v$database;
select process, status, sequence# from v$managed_standby;
exit
EOS
  echo "########## [2] spfile 생성 및 파라미터 조정 ##########"
  # DUPLICATE 는 메모리 파라미터로 기동한 상태다. spfile 로 굳힌다.
  sqlplus -s / as sysdba <<EOS
set echo on
whenever sqlerror continue
create spfile from memory;
shutdown immediate
startup mount
alter system set log_archive_dest_1 =
  'location=use_db_recovery_file_dest valid_for=(all_logfiles,all_roles) db_unique_name=${STB_UNIQUE}' scope=spfile;
alter system set log_archive_config = 'dg_config=(${PRI_UNIQUE},${STB_UNIQUE})' scope=both;
alter system set db_recovery_file_dest_size = ${FRA_SIZE} scope=spfile;
alter system set db_recovery_file_dest = '${FRA}' scope=spfile;
shutdown immediate
startup mount
exit
EOS
  echo "########## [3] Open Read Only + 실시간 적용 (Active Data Guard) ##########"
  # USING CURRENT LOGFILE 이 실시간 적용을 켠다. 이것이 없으면 아카이브가
  # 완성된 뒤에야 적용되어 지연이 생긴다.
  sqlplus -s / as sysdba <<'EOS'
set echo on
whenever sqlerror continue
alter database open read only;
alter database recover managed standby database using current logfile disconnect from session;
col name for a12
select name, open_mode, database_role from v$database;
select process, status, sequence# from v$managed_standby;
exit
EOS
  echo "다음: bash 30_verify.sh"
  ;;

*)
  echo "사용법: bash 20_standby_build.sh {pwfile|nomount|duplicate|watch|post}"; exit 1 ;;
esac
