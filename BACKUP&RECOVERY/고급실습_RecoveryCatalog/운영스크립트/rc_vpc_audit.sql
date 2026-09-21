-- =============================================================================
--  rc_vpc_audit.sql  —  Virtual Private Catalog 권한 현황 점검
--  출처   : 고급 실습 01
--  실행   : sqlplus / as sysdba @rc_vpc_audit.sql   (카탈로그 DB 에서)
--  용도   : 분기 감사 대응. 담당자별 담당 DB 와 등록 권한, 롤 이상 여부를 한 번에 본다
--
--  판독
--    - GRANTED_ROLE 이 RECOVERY_CATALOG_USER 가 아닌 VPC 사용자가 있으면
--      sqlplus / as sysdba @$ORACLE_HOME/rdbms/admin/dbmsrmanvpc.sql rcatowner 로 정리한다
--    - ADD_NEW_DB = Y 가 REGISTER DATABASE 권한이다. 설계 매트릭스와 대조한다
--    - 오라클 표준 형식의 보고서가 필요하면
--      sqlplus -s / as sysdba @$ORACLE_HOME/rdbms/admin/dbmsrmanvpc.sql -scan rcatowner
-- =============================================================================
SET LINESIZE 140 PAGESIZE 100
COLUMN vpc_user FORMAT A12
COLUMN granted_role FORMAT A24
COLUMN name FORMAT A8
COLUMN add_new_db FORMAT A10

PROMPT === VPC 사용자와 롤 ===
SELECT u.username AS vpc_user, u.created, u.account_status, r.granted_role
FROM   dba_users u LEFT JOIN dba_role_privs r ON r.grantee = u.username
WHERE  u.username LIKE 'VPC%'
ORDER  BY u.username;

PROMPT === 기본 카탈로그 등록 DB ===
SELECT dbid, name, resetlogs_time FROM rcatowner.rc_database ORDER BY name;

PROMPT === VPC 사용자별 담당 DB와 등록 권한 ===
SELECT u.filter_user AS vpc_user, r.name, u.add_new_db
FROM   rcatowner.vpc_users u
       LEFT JOIN rcatowner.vpc_databases d ON d.filter_user = u.filter_user
       LEFT JOIN rcatowner.rc_database r ON r.dbid = d.db_id
ORDER  BY u.filter_user, r.name;
