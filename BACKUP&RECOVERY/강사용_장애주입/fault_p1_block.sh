#!/bin/bash
# ============================================================================
# [강사 전용 · 학생 노출 금지]  개인 1 (최상급)
# 은폐형 블록 손상 — 파일은 ONLINE·정상으로 보이나 특정 조회만 실패.
#  · 업무 표 데이터 블록 다수 물리 오손(ORA-01578) + 인덱스 블록 오손
#  · BMR 에 필요한 아카이브 1개를 비표준 경로로 이동(즉시 못 찾게)
# 학생 안내(구두): "일부 조회가 간헐적으로 실패한다는 신고가 들어왔다. 조사·복구하라."
# ============================================================================
set -u; cd "$(dirname "$0")"; . ./_lab_env.sh; guard

# 0) 대상 표/인덱스의 '실제 데이터 블록' 위치 파악(dba_extents 기준 → 작은 표에서도 확실)
read TBL_FILE TBL_REL <<<"$(sq "
select e.file_id||' '||(e.block_id+2)
  from dba_extents e
 where e.owner='$BIZ_USER' and e.segment_type='TABLE' and e.blocks>=4
 order by e.blocks desc fetch first 1 rows only;")"
read IDX_FILE IDX_REL <<<"$(sq "
select e.file_id||' '||(e.block_id+2)
  from dba_extents e
 where e.owner='$BIZ_USER' and e.segment_type='INDEX' and e.blocks>=2
 order by e.blocks desc fetch first 1 rows only;")"
TBL_DBF=$(sq "select name from v\$datafile where file#=$TBL_FILE;")
IDX_DBF=$(sq "select name from v\$datafile where file#=$IDX_FILE;")

if [ -z "$TBL_REL" ] || [ -z "$TBL_DBF" ]; then echo "!! $BIZ_USER 표 세그먼트를 못 찾음. BIZ_USER 확인."; exit 1; fi
echo "[주입] 표 파일#$TBL_FILE 블록$TBL_REL~  인덱스 파일#$IDX_FILE 블록$IDX_REL  (실 세그먼트 블록)"

# 1) 데이터 블록 다수 오손(연속 3블록) — dd 로 8K 블록을 0으로
for off in 0 1 2; do
  dd if=/dev/zero of="$TBL_DBF" bs=8192 seek=$((TBL_REL+off)) count=1 conv=notrunc 2>/dev/null
done
# 2) 인덱스 블록 1개 오손(전략 분기 유도: 인덱스는 REBUILD 가 정답)
if [ -n "$IDX_REL" ] && [ -n "$IDX_DBF" ]; then
  dd if=/dev/zero of="$IDX_DBF" bs=8192 seek=$IDX_REL count=1 conv=notrunc 2>/dev/null
else
  echo "[주의] $BIZ_USER 인덱스 세그먼트가 작아 건너뜀 — 표 블록만 손상(전략 분기 유지하려면 큰 인덱스 필요)."
fi

# 3) 캐시에 안 남도록 flush (재조회 시 물리 읽기→오류 표면화)
sq "alter system flush buffer_cache;"

# 4) BMR 에 필요할 최근 아카이브 1개를 비표준 경로로 이동(학생이 CATALOG 하도록)
ARC=$(sq "select name from v\$archived_log where name is not null and standby_dest='NO'
          order by first_time desc fetch first 1 rows only;")
if [ -n "$ARC" ] && [ -f "$ARC" ]; then
  mkdir -p /tmp/misplaced_arch; mv "$ARC" /tmp/misplaced_arch/ 2>/dev/null
  echo "[주입] 아카이브 이동: $ARC -> /tmp/misplaced_arch/  (RMAN CATALOG 필요)"
fi

echo "[완료] v\$datafile 은 ONLINE 로 보인다. 손상은 VALIDATE/조회로만 드러난다."
echo "       모범 복구: VALIDATE DATABASE → v\$database_block_corruption 판독 →"
echo "                 표 블록은 RECOVER ... BLOCK(아카이브 CATALOG 후), 인덱스는 REBUILD."
