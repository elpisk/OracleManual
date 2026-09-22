#!/bin/bash
#===============================================================================
# exam_reset.sh — 감독자 복원점으로 랩을 되돌린다 (ARCHIVELOG 실기평가)
#
#   시나리오 사이, 또는 응시자가 복구에 실패했을 때 실행한다.
#   $SAFE 는 exam_prep.sh 만 만들고 장애 유발 스크립트는 건드리지 않으므로
#   어떤 상태에서도 이 스크립트로 되돌아온다.
#
#   되돌리는 것
#     데이터파일·TEMP·컨트롤파일·리두 로그·spfile·패스워드 파일 (Cold 복원점)
#     아카이브 대상 1번 : 복원점 이후 생긴 아카이브(다른 인카네이션 포함)는 지우고,
#                        장애로 지워진 아카이브는 되살린다
#     $BK 의 데이터파일·컨트롤파일 백업·구간 아카이브 (장애 스크립트가 새로 받았어도 원래 것으로)
#     과제 1-2 / 3-2 가 만든 exam_nobk / exam_new 데이터파일
#
#   컨트롤파일까지 통째로 되돌리므로 별도의 복구 명령이 필요 없다.
#===============================================================================
set -u
. "$(dirname "$0")/exam_env.sh"

if [ ! -f "$SAFE/manifest.txt" ] || [ ! -f "$SAFE/system01.dbf" ]; then
  echo "중단: 복원점 $SAFE 가 없다. exam_prep.sh 를 먼저 실행할 것."
  exit 1
fi
ARCH=$(grep '^arch_dir=' "$SAFE/manifest.txt" | cut -d= -f2)

echo "=== 인스턴스 정지 ==="
run_sql "shutdown abort" >/dev/null 2>&1
# 만약 다른 인스턴스 이름으로 떠 있다면 (복제 실습 잔재) 건드리지 않는다

echo "=== 파일 복원 ($SAFE → 원위치) ==="
while IFS='|' read -r kind path; do
  case "$kind" in
    D|T|C|R) cp -p "$SAFE/$(basename "$path")" "$path" ;;
  esac
done < "$SAFE/manifest.txt"
cp -p "$SAFE/spfile${ORACLE_SID}.ora" "$SAFE/orapw${ORACLE_SID}" "$ORACLE_HOME/dbs/"
DFDIR=$(dirname "$(grep '^D|' "$SAFE/manifest.txt" | head -1 | cut -d'|' -f2)")
for f in "$DFDIR"/exam_nobk*.dbf "$DFDIR"/exam_new*.dbf; do
  [ -e "$f" ] || continue
  grep -q "^D|$f$" "$SAFE/manifest.txt" || rm -f "$f"     # 복원점에 없는 과제용 파일만 지운다
done
echo "  데이터파일 $(grep -c '^D|' "$SAFE/manifest.txt") 개, 컨트롤파일 $(grep -c '^C|' "$SAFE/manifest.txt") 개, 리두 멤버 $(grep -c '^R|' "$SAFE/manifest.txt") 개"

echo "=== 아카이브 정리 ($ARCH) ==="
removed=0; restored=0
for f in "$ARCH"/*; do
  [ -e "$f" ] || continue
  if ! grep -qx "$(basename "$f")" "$SAFE/arch_list.txt"; then rm -f "$f"; removed=$((removed+1)); fi
done
while read -r name; do
  [ -n "$name" ] || continue
  if [ ! -e "$ARCH/$name" ] && [ -e "$SAFE/arch/$name" ]; then cp -p "$SAFE/arch/$name" "$ARCH/"; restored=$((restored+1)); fi
done < "$SAFE/arch_list.txt"
echo "  복원점 이후 생긴 아카이브 $removed 개 삭제, 지워졌던 아카이브 $restored 개 복원"

echo "=== 응시자용 백업본 점검 ($BK) ==="
mkdir -p "$BK/arch"
if ! cmp -s "$BK/backup_info.txt" "$SAFE/bk/backup_info.txt"; then
  echo "  장애 스크립트가 새로 받은 Hot Backup 이다. 원래 Hot Backup 의 데이터파일로 되돌린다."
  cp -p "$SAFE"/bk/*.dbf "$BK/"
fi
cp -p "$SAFE/bk/control_exam.bkp" "$SAFE/bk/backup_info.txt" "$SAFE/bk/manifest.txt" "$BK/"
rm -f "$BK"/arch/*
cp -p "$SAFE"/bk/arch/* "$BK/arch/" 2>/dev/null
missing=0
while IFS='|' read -r kind path; do
  [ "$kind" = "D" ] || continue
  [ -e "$BK/$(basename "$path")" ] || missing=$((missing+1))
done < "$SAFE/manifest.txt"
if [ "$missing" -gt 0 ]; then
  echo "  $BK 에 데이터파일 $missing 개가 없어 사본에서 되살린다 (장애 스크립트는 여기를 지우지 않는다)."
  cp -p "$SAFE"/bk/*.dbf "$BK/"
fi
echo "  컨트롤파일 백업, 구간 아카이브 $(ls "$BK/arch" | wc -l) 개 원복"

echo "=== 기동 ==="
run_sql "startup"

echo "=== 확인 ==="
qs "select name, open_mode, log_mode, resetlogs_change# from v\$database;
select count(*) datafiles from v\$datafile;
select count(*) tempfiles from v\$tempfile;
select name from v\$controlfile;
select group#, sequence#, status from v\$log order by group#;
select max(sequence#) last_archived from v\$archived_log where dest_id = 1;
select count(*) exam_log_rows from hr.exam_log;
select count(*) exam_orders_rows from hr.exam_orders;"

echo
echo "복원 완료. 다음 시나리오를 시작할 수 있다."
