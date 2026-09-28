#!/bin/bash
# ============================================================================
# [강사 전용 · 학생 노출 금지]  개인 2 (최상급)
# 은폐형 논리 오류 — 잘못된 커밋이 정상 트랜잭션 사이에 묻혀 있다.
#  · 대량 오변경 DML 커밋 후, 그 위로 정상 트랜잭션을 계속 쌓아 시점 특정을 방해
#  · Flashback Database OFF, UNDO_RETENTION 축소, recyclebin PURGE → 손쉬운 되돌리기 봉쇄
# 정답 경로: LogMiner 로 오염 트랜잭션·SCN 특정 → RMAN RECOVER TABLE ... UNTIL SCN
#            (보조 인스턴스) 로 표만 시점 복구 → 이후 정상 변경 재조정.
# 학생 안내(구두): "청구 금액이 이상하다는 신고. 원인 시점을 규명하고 표를 복원하라."
# ============================================================================
set -u; cd "$(dirname "$0")"; . ./_lab_env.sh; guard
T=${BIZ_USER}.MEDICAL_CLAIMS

# 0) 되돌리기 봉쇄 환경
sq "alter system set undo_retention=120 scope=both;
    begin execute immediate 'alter database flashback off'; exception when others then null; end;
    purge dba_recyclebin;"

# 1) 정상 트랜잭션(전) — 배경 소음
sq "update $T set total_amt=total_amt where rownum<=50; commit;"

# 2) *** 오염 트랜잭션 *** — 사고. 커밋 시점 SCN 을 로그로만 남긴다(학생엔 비공개)
BAD_SCN=$(sq "update $T set total_amt=total_amt*7 where hosp_id in (select hosp_id from $T where rownum<=1);
              commit;
              select current_scn from v\$database;")
echo "[주입·비공개] 오염 커밋 SCN ≈ $BAD_SCN  (학생에게 알리지 말 것)"

# 3) 정상 트랜잭션(후) — 오염 위에 정당한 변경을 계속 쌓아 시점 특정 난이도 상승
for i in 1 2 3 4 5; do
  sq "update $T set receipt_date=receipt_date where rownum<=30; commit;
      insert into $T select * from $T where rownum<=5; commit;"
  sleep 2
done
# 4) 로그 스위치로 REDO 를 아카이브에 넘겨 LogMiner 대상 확보
sq "alter system switch logfile; alter system archive log current;"

echo "[완료] 표는 조회되나 일부 금액이 7배로 왜곡. Flashback 경로는 막혀 있다."
echo "       모범: LogMiner(v\$logmnr_contents)로 오염 트랜잭션 식별 →"
echo "             RMAN RECOVER TABLE $T UNTIL SCN <직전> AUXILIARY DESTINATION ... →"
echo "             REMAP 로 스테이징 후 정상 후행 변경과 재조정."
