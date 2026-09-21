-- =============================================================================
--  rc_vpc_setup.sql  —  Virtual Private Catalog 담당자 계정 생성
--  출처   : 고급 실습 01
--  실행   : sqlplus / as sysdba @rc_vpc_setup.sql <VPC사용자> <비밀번호>   (카탈로그 DB 에서)
--  용도   : 신규 DBA 에게 담당 DB 범위만 보이는 카탈로그 계정을 만든다
--  전제   : 기본 카탈로그가 VPD 모델이어야 한다
--           sqlplus / as sysdba @$ORACLE_HOME/rdbms/admin/dbmsrmanvpc.sql -vpd rcatowner
--           RMAN> UPGRADE CATALOG;  (두 번)
--           켜지 않은 채 GRANT CATALOG 를 하면 RMAN-07543 이 난다
--
--  주의
--    - VPC 사용자에게 RECOVERY_CATALOG_OWNER 롤을 주지 않는다 (접속마다 RMAN-07540)
--    - 범위 부여(GRANT CATALOG FOR DATABASE)는 RMAN 명령이라 이 스크립트 밖에서 한다
--    - 19c 에서는 부여 즉시 보인다. CREATE VIRTUAL CATALOG 는 12.1 미만 클라이언트용
-- =============================================================================
SET VERIFY OFF
DEFINE vpc_user  = &1
DEFINE vpc_pass  = &2

CREATE USER &vpc_user IDENTIFIED BY &vpc_pass
  DEFAULT TABLESPACE rcat_data
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON rcat_data;

GRANT CREATE SESSION, RECOVERY_CATALOG_USER TO &vpc_user;

PROMPT
PROMPT === 다음 단계를 수동으로 수행한다 ===
PROMPT 1) rman catalog rcatowner@rcat
PROMPT    RMAN> GRANT CATALOG FOR DATABASE <db> TO &vpc_user;
PROMPT    (새 DB 등록 권한이 필요하면) RMAN> GRANT REGISTER DATABASE TO &vpc_user;
PROMPT 2) 12.1 미만 RMAN 클라이언트가 접속한다면 그 사용자로
PROMPT    RMAN> CREATE VIRTUAL CATALOG;
PROMPT 3) 확인 : sqlplus / as sysdba @rc_vpc_audit.sql
PROMPT
UNDEFINE vpc_user vpc_pass
