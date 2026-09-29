#!/bin/bash
# ============================================================================
# [강사 전용 · 학생 노출 금지]  조별 2 (최상급) — 재해복구 경진
# 서버 전체 상실 + DBID 미상 + 분산 백업 + 한 TS 의 논리 오염(TSPITR) + 스키마 이관.
# 준비(강사): 이 스크립트는 '새 호스트' 가정을 만든다.
#  1) 한 테이블스페이스에 국소 논리 오염을 심고 그 직전 SCN 을 강사만 보관(TSPITR 목표)
#  2) 백업을 두 위치로 분산(FRA + /backup2) → 학생은 양쪽을 CATALOG 해야 함
#  3) DBID 를 학생 자료에서 제거(오토백업/카탈로그에서 직접 확보하게)
#  4) 원본 인스턴스를 접근 불가로 만든다(SPFILE/컨트롤파일/데이터파일 이동)
# 학생 안내(구두): "운영 서버가 소실됐다. 새 호스트와 백업만으로 RTO 안에 복구하고,
#                  지정 스키마를 대상 환경으로 이관하라. 팀별 시간·정확도로 경진."
# ============================================================================
set -u; cd "$(dirname "$0")"; . ./_lab_env.sh; guard
BACKUP2=${BACKUP2:-/backup2}; mkdir -p "$BACKUP2"

# 1) USERS 에 마커 준비(없으면 생성·시드) → 정상 시점 SCN 확보 → 그 뒤 국소 오염
sq "alter user ${BIZ_USER} quota unlimited on users;
begin execute immediate 'create table ${BIZ_USER}.dr_marker(id number, ts timestamp) tablespace users';
exception when others then null; end;
/
merge into ${BIZ_USER}.dr_marker t using (select level id from dual connect by level<=200) s
  on (t.id=s.id) when not matched then insert(id,ts) values(s.id,systimestamp);
commit;"
sq "alter system checkpoint; alter system switch logfile; alter system archive log current;"
# 정상 상태 L0 백업(주어질 백업이 깨끗한 마커를 포함하도록) → 그 직후를 TSPITR 목표로
rman target / <<'RMAN'
backup database plus archivelog;
RMAN
TSPITR_SCN=$(sq "select current_scn from v\$database;")   # USERS 오염 직전(정상) 시점
sq "update ${BIZ_USER}.dr_marker set id=id*-1 where id<=50; commit;
    alter system switch logfile; alter system archive log current;"
echo "[주입·비공개] TSPITR 목표 SCN ≈ $TSPITR_SCN  (USERS 오염 직전, 학생 비공개)"

# 2) 최신 백업 일부를 두 번째 위치로 분산(양쪽 CATALOG 유도)
for h in $(sq "select handle from v\$backup_piece where status='A' order by completion_time desc fetch first 3 rows only;"); do
  [ -f "$h" ] && mv "$h" "$BACKUP2"/ && echo "[주입] 백업 분산: $h -> $BACKUP2/"
done

# 3) DBID 확보용으로 오토백업만 남기고 학생 배포자료에는 DBID 미기재(문서에서 처리)
DBID=$(sq "select dbid from v\$database;")
echo "[참고·강사] 정답 DBID = $DBID  (학생은 오토백업/카탈로그에서 직접 확보)"

# 4) 원본 인스턴스 소실 시뮬레이션
sq "shutdown abort"
for c in $(sq "select value from v\$parameter where name='control_files';" 2>/dev/null | tr ',' ' '); do mv "$c" "$c.gone" 2>/dev/null; done
mkdir -p "$DBF/_gone"; mv "$DBF"/*.dbf "$DBF/_gone"/ 2>/dev/null
mv "$ORACLE_HOME/dbs/spfile$ORACLE_SID.ora" "$ORACLE_HOME/dbs/spfile$ORACLE_SID.ora.gone" 2>/dev/null

echo "[완료] 원본 접근 불가. 백업은 $FRA 와 $BACKUP2 에 분산. DBID 미제공. USERS 는 TSPITR 대상."
echo "       모범: (오토백업/카탈로그)DBID 확보 → RESTORE SPFILE/CONTROLFILE →"
echo "             CATALOG START WITH '$FRA','$BACKUP2' → RESTORE/RECOVER → OPEN RESETLOGS →"
echo "             USERS TSPITR(UNTIL SCN) → expdp/impdp REMAP_SCHEMA+VERSION → RTO 기록."
