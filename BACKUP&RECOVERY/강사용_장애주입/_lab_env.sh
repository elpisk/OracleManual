#!/bin/bash
# [강사 전용] 장애 주입 공통 설정 — 랩 환경에 맞게 수정한다.
# 모든 fault_*.sh 가 이 파일을 source 한다.
export ORACLE_SID=${ORACLE_SID:-orcl}
export ORAENV_ASK=NO
# 데이터파일/컨트롤파일 기준 경로(기준배치)
export DBF=${DBF:-/u01/app/oracle/oradata/orcl}
# Fast Recovery Area(아카이브·오토백업·백업셋)
export FRA=${FRA:-/u01/app/oracle/fast_recovery_area/ORCL}
# 업무 스키마(검증 대상)
export BIZ_USER=${BIZ_USER:-SQLT}
# 실습 시작 전 반드시 복원 가능한 스냅숏을 떠 둔다.
export SNAP_TAKEN=${SNAP_TAKEN:-NO}

sq(){ sqlplus -s / as sysdba <<SQL
set head off feedback off pagesize 0 verify off trimspool on
$1
exit
SQL
}
guard(){
  if [ "$SNAP_TAKEN" != "YES" ]; then
    echo "!! SNAP_TAKEN=YES 로 실행하라(스냅숏 확인). 예: SNAP_TAKEN=YES ./fault_xx.sh"; exit 1
  fi
}
