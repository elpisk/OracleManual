#!/bin/bash
# [강사 전용] 장애 주입 공통 설정 — 랩 환경에 맞게 수정한다.
# 모든 fault_*.sh 가 이 파일을 source 한다.
export ORACLE_SID=${ORACLE_SID:-orcl}
export ORAENV_ASK=NO
# 데이터파일/컨트롤파일 기준 경로(기준배치)
export DBF=${DBF:-/u01/app/oracle/oradata/orcl}
# Fast Recovery Area(아카이브·오토백업·백업셋)
export FRA=${FRA:-/u01/app/oracle/fast_recovery_area/ORCL}
# 업무 스키마(검증 대상) — HR 샘플 스키마 사용(대표 표 EMPLOYEES.SALARY)
export BIZ_USER=${BIZ_USER:-HR}
# 실습 시작 전 반드시 복원 가능한 스냅숏을 떠 둔다.
export SNAP_TAKEN=${SNAP_TAKEN:-NO}

sq(){ sqlplus -s / as sysdba <<SQL
set head off feedback off pagesize 0 verify off trimspool on
$1
exit
SQL
}
# guard: 이 스크립트는 DB 를 '의도적으로' 손상시킨다. 되돌림은 VM/스토리지 스냅숏 복원뿐.
#  · DRYRUN=YES        → 대상만 확인하고 아무 것도 바꾸지 않고 종료(리허설 미리보기)
#  · 대화형 터미널      → SID 를 직접 타이핑해야 진행(사람 확인 게이트)
#  · 비대화형(자동화)   → SNAP_TAKEN=YES 와 CONFIRM_DESTROY=YES 를 모두 줘야 진행
guard(){
  local INFO
  INFO=$(sq "select 'instance='||instance_name||'  status='||status from v\$instance;" 2>/dev/null)
  local DBID
  DBID=$(sq "select dbid from v\$database;" 2>/dev/null)
  echo "############################################################"
  echo "##  경고: 이 스크립트는 [$ORACLE_SID] 를 의도적으로 손상시킨다."
  echo "##  $INFO  DBID=$DBID"
  echo "##  되돌리려면 실습 시작 상태의 VM/스토리지 스냅숏을 복원해야 한다."
  echo "##  (SNAP_TAKEN 은 '스스로 선언'일 뿐, 스냅숏 존재를 검증하지 못한다.)"
  echo "############################################################"
  if [ "${DRYRUN:-NO}" = "YES" ]; then echo "[DRYRUN] 확인만 하고 종료 — 변경 없음."; exit 0; fi
  if [ -t 0 ]; then
    printf ">> 복원 스냅숏을 이미 떴는가? 진행하려면 SID '%s' 를 그대로 입력(그 외 입력 시 중단): " "$ORACLE_SID"
    local ans; read -r ans
    if [ "$ans" != "$ORACLE_SID" ]; then echo "확인 불일치 — 중단."; exit 1; fi
  else
    if [ "$SNAP_TAKEN" != "YES" ] || [ "${CONFIRM_DESTROY:-NO}" != "YES" ]; then
      echo "!! 비대화형 실행은 SNAP_TAKEN=YES CONFIRM_DESTROY=YES 를 모두 줘야 한다(오작동 방지)."; exit 1
    fi
  fi
  echo "[확인됨] 장애 주입을 시작한다: $ORACLE_SID"
}
