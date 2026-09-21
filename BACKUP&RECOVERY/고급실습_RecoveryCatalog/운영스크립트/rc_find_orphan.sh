#!/bin/bash
# =============================================================================
#  rc_find_orphan.sh  —  백업 경로에 있으나 카탈로그에 없는 파일 탐지
#  출처   : 고급 실습 04
#  사용법 : rc_find_orphan.sh <DB이름 대문자>      예) rc_find_orphan.sh ORCL
#  전제   : rc_report 계정(고급 실습 02) — RC_* 뷰 SELECT + EXEMPT ACCESS POLICY
#
#  판독
#    "카탈로그에 없는 파일"   → CATALOG START WITH 로 등록하거나 판단 후 삭제
#    "파일이 없는 카탈로그 기록" → CROSSCHECK 후 DELETE EXPIRED (rc_maint_crosscheck.sh)
#  주의
#    - rc_backup_piece 에는 db_name 열이 없다. rc_database 에서 db_key 를 구해 거른다.
#    - 다른 디렉터리에 등록된 조각이 "파일 없음" 으로 잡히지 않도록 경로(handle)도 거른다.
# =============================================================================
DBNAME=$1
[ -z "$DBNAME" ] && { echo "usage: $0 <DBNAME>"; exit 2; }
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH

# ---- 환경에 맞게 수정할 값 ----
REPORT_USER="rc_report/oracle_4U@rcat"
BKROOT=/backup
# --------------------------------

# 카탈로그에 등록된 조각 목록 (이 경로 아래 것만)
sqlplus -s $REPORT_USER << EOF | sort > /tmp/in_catalog.$$
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT handle FROM rc_backup_piece
WHERE  db_key = (SELECT db_key FROM rc_database WHERE name = UPPER('$DBNAME'))
AND    status = 'A' AND handle LIKE '$BKROOT/$DBNAME/%';
EXIT
EOF

# 실제 파일 목록
find $BKROOT/$DBNAME -type f | sort > /tmp/on_disk.$$

echo "=== 카탈로그에 없는 파일 ==="
comm -13 /tmp/in_catalog.$$ /tmp/on_disk.$$

echo "=== 파일이 없는 카탈로그 기록 ==="
comm -23 /tmp/in_catalog.$$ /tmp/on_disk.$$

rm -f /tmp/in_catalog.$$ /tmp/on_disk.$$
