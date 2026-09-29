#!/bin/bash
# ============================================================================
# [강사 전용 · 비파괴]  실습 사전 점검 — 장애 주입 전에 먼저 돌린다.
# 실제 랩의 경로·모드·백업·공간·스키마·보조 디렉터리를 출력해
# _lab_env.sh 설정이 맞는지, 시나리오를 풀 수 있는 상태인지 확인한다.
# 아무것도 변경하지 않는다(SELECT/조회/파일 존재 확인만).
# ============================================================================
set -u; cd "$(dirname "$0")"; . ./_lab_env.sh
line(){ printf '%s\n' "------------------------------------------------------------"; }
chk(){ [ "$1" = 1 ] && echo "  [OK]  $2" || echo "  [!!]  $2"; }

echo "############  B&R 실습 사전 점검 (비파괴)  ############"
echo "설정값: ORACLE_SID=$ORACLE_SID  BIZ_USER=$BIZ_USER"
echo "        DBF=$DBF"
echo "        FRA=$FRA"
line

echo "[1] 인스턴스·모드"
sq "select 'open_mode='||open_mode||'  log_mode='||log_mode||'  dbid='||dbid
      ||'  flashback='||flashback_on from v\$database;"
line

echo "[2] 데이터파일 실제 경로 (DBF 설정과 대조)"
sq "select file#, name from v\$datafile order by file#;"
DBF_REAL=$(sq "select substr(name,1,instr(name,'/',-1)-1) from v\$datafile where file#=1;")
chk "$([ "$DBF_REAL" = "$DBF" ] && echo 1 || echo 0)" "DBF 설정=$DBF / 실제=$DBF_REAL  (다르면 _lab_env.sh 의 DBF 수정: 특히 fault_t2)"
line

echo "[3] 컨트롤파일 · 리두로그 · 현재 그룹"
sq "select value from v\$parameter where name='control_files';"
sq "select l.group#, l.status, m.member from v\$log l join v\$logfile m on l.group#=m.group# order by 1;"
line

echo "[4] FRA · 아카이브 대상 · 오토백업"
sq "select name, round(space_limit/1024/1024) mb_limit, round(space_used/1024/1024) mb_used
      from v\$recovery_file_dest;"
sq "select dest_id, status, destination from v\$archive_dest where status='VALID' and destination is not null;"
sq "select case when count(*)>0 then 'controlfile autobackup=ON 기록 있음' else '오토백업 기록 없음(설정 확인)' end
      from v\$backup_piece where autobackup_done='YES';"
line

echo "[5] 백업 요약 (최근)"
rman target / <<'RMAN' 2>/dev/null | sed -n '/List of/,$p' | head -25
list backup summary;
RMAN
line

echo "[6] 업무 스키마($BIZ_USER)"
sq "select case when count(*)>0 then '$BIZ_USER 존재' else '$BIZ_USER 없음(스키마 확인)' end from dba_users where username=upper('$BIZ_USER');"
sq "select segment_type, count(*), max(blocks) max_blocks
      from dba_segments where owner=upper('$BIZ_USER') group by segment_type order by 1;"
sq "select 'EMPLOYEES 건수='||count(*) from $BIZ_USER.employees;" 2>/dev/null
IDXBLK=$(sq "select nvl(max(blocks),0) from dba_extents where owner=upper('$BIZ_USER') and segment_type='INDEX';")
chk "$([ "${IDXBLK:-0}" -ge 2 ] 2>/dev/null && echo 1 || echo 0)" "인덱스 세그먼트 max_blocks=$IDXBLK  (개인1 인덱스 손상 분기용, <2 면 표 블록만 손상됨)"
line

echo "[7] 보조 디렉터리·공간 (RECOVER TABLE / TSPITR / Data Pump)"
for d in /u01/aux /backup2; do
  if [ -d "$d" ]; then echo "  [OK]  $d 존재  ($(df -h "$d" 2>/dev/null | awk 'NR==2{print $4" free"}'))";
  else echo "  [!!]  $d 없음 — mkdir -p $d (AUXILIARY DESTINATION/분산백업)"; fi
done
sq "select directory_name||' -> '||directory_path from dba_directories where directory_name in ('DP','DATA_PUMP_DIR');"
line

echo "[8] 스냅숏 도구 준비 여부(수동 확인)"
echo "  · 각 시나리오 시작 상태로 되돌릴 복원 수단(VM 스냅숏/스토리지 스냅)이 있는가?"
echo "  · fault_*.sh 는 SNAP_TAKEN=YES 가드가 걸려 있다. 스냅숏 확인 후에만 실행."
line
echo "점검 끝. [!!] 항목을 해소한 뒤 장애 주입을 시작한다."
