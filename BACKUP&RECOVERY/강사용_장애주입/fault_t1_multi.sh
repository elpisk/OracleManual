#!/bin/bash
# ============================================================================
# [강사 전용 · 학생 노출 금지]  조별 1 (최상급)
# 다중 동시 장애 + 손상 백업 + 아카이브 갭 + SYSTEM 블록 손상.
#  1) 미반영 트랜잭션 생성(불완전복구 대상)
#  2) CURRENT 리두로그 전 멤버 삭제
#  3) 모든 컨트롤파일 삭제
#  4) 필요한 아카이브 1개 삭제(복구 갭 → 여기까지만 복구 가능)
#  5) 최신 백업피스 1개 손상(최신 복원 실패 → 이전 백업/CROSSCHECK 유도)
#  6) SYSTEM 데이터파일 블록 손상(오픈 후 발견)
#  7) SHUTDOWN ABORT
# 학생 안내(구두): "야간 배치 중 스토리지 사고로 기동 실패가 보고되었다. 복구하라."
# ============================================================================
set -u; cd "$(dirname "$0")"; . ./_lab_env.sh; guard

# 1) 미반영 트랜잭션(불완전복구로만 일부 손실될 데이터)
sq "alter user ${BIZ_USER} quota unlimited on users;
    begin execute immediate 'drop table ${BIZ_USER}.dr_marker purge'; exception when others then null; end;
    create table ${BIZ_USER}.dr_marker(id number, ts timestamp) tablespace users;
begin for i in 1..200 loop insert into ${BIZ_USER}.dr_marker values(i,systimestamp); end loop; commit; end;
/
alter system switch logfile;"

# 2) CURRENT 리두 그룹 전 멤버 삭제
CUR=$(sq "select group# from v\$log where status='CURRENT';")
for m in $(sq "select member from v\$logfile where group#=$CUR;"); do rm -f "$m"; echo "[주입] rm redo $m"; done

# 3) 모든 컨트롤파일 삭제
for c in $(sq "select value from v\$parameter where name='control_files';" | tr ',' ' '); do rm -f "$c"; echo "[주입] rm ctl $c"; done

# 4) 아카이브 갭 — 최근 아카이브 1개 삭제
GAP=$(sq "select name from v\$archived_log where name is not null order by sequence# desc fetch first 1 rows only;")
[ -f "$GAP" ] && { rm -f "$GAP"; echo "[주입] 아카이브 갭: $GAP 삭제"; }

# 5) 최신 백업피스 1개 손상(최신 세트 복원 실패 유도)
BP=$(sq "select handle from v\$backup_piece where status='A' order by completion_time desc fetch first 1 rows only;")
[ -f "$BP" ] && { dd if=/dev/zero of="$BP" bs=1M seek=1 count=1 conv=notrunc 2>/dev/null; echo "[주입] 백업피스 손상: $BP"; }

# 6) SYSTEM 데이터파일 블록 손상(오픈 후 VALIDATE 로 발견)
SYS=$(sq "select name from v\$datafile where file#=1;")
dd if=/dev/zero of="$SYS" bs=8192 seek=900 count=1 conv=notrunc 2>/dev/null; echo "[주입] SYSTEM 블록 손상"

# 7) 인스턴스 강제 종료
sq "shutdown abort"
echo "[완료] STARTUP 시 컨트롤파일 부재로 실패. 최신 백업 손상·아카이브 갭·SYSTEM 손상이 함께 있다."
echo "       모범: RESTORE CONTROLFILE FROM AUTOBACKUP → CROSSCHECK/VALIDATE 로 손상 백업 배제 →"
echo "             갭 직전까지 RECOVER → OPEN RESETLOGS → SYSTEM 블록 BMR → 재백업."
