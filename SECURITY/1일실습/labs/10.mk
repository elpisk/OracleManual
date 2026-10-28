@H2 실습 10  FGA·통합 감사와 감사 기록 관리
@TBL
항목 | 내용
목표 | 값 조건 기반 FGA와 통합 감사 정책을 함께 걸고, 혼합 모드에서 두 기록이 어디에 남는지 확인한다. 감사 기록 보호 장치와 DBMS_AUDIT_MGMT 정리 절차를 기존 기록을 지우지 않는 방식으로 실행한다.
소요 | 50분
접속 | SYS, D10_SEC(AUDIT_ADMIN), D10_CLERK(업무 계정), D10_AUD(AUDIT_VIEWER)
변경 | 사용자 4개, FGA 정책 1개, 통합 감사 정책 1개, 아카이브 기준 시각(실습 중 설정 후 해제). 감사 기록은 남음
@END

@H3 10.1  실습 전에 — 감사는 남기는 것보다 읽고 지키고 비우는 것이 일이다
@B 19c의 기본 설치는 혼합 모드다. V$OPTION의 Unified Auditing이 FALSE이면 AUDIT_TRAIL 같은 기존 감사 파라미터와 통합 감사 정책이 함께 동작함. ORA_SECURECONFIG, ORA_LOGON_FAILURES 두 기본 정책이 켜져 있다.
@B FGA는 '어떤 값에 접근했는가'를 감사한다. audit_condition은 행마다 평가되고, audit_column에 적은 컬럼을 SELECT 목록이나 WHERE 절에서 참조할 때만 기록이 생긴다. 조건을 만족하는 행이 결과에 하나라도 섞이면 문장 하나가 기록 한 건이 된다.
@B 혼합 모드(19.3)의 FGA 기록은 FGA_LOG$(DBA_FGA_AUDIT_TRAIL)에 남고 UNIFIED_AUDIT_TRAIL에는 남지 않는다(원 교안 12장 실습 01). 문서 기준으로는 순수 통합 감사로 바꾸면 FGA 기록도 통합 감사 기록으로 간다.
@B 통합 감사 정책은 CREATE AUDIT POLICY로 정의하고 AUDIT POLICY ... BY 사용자로 켠다. 성공·실패를 모두 기록하는 것이 기본이다. 정책이 켜진 상태에서는 DROP할 수 없음(ORA-46361).
@B 감사 권한은 역할로 나뉜다.
@TBL
역할 | 할 수 있는 것
AUDIT_ADMIN | 통합 감사 정책 생성·활성화, DBMS_FGA, DBMS_AUDIT_MGMT 실행
AUDIT_VIEWER | UNIFIED_AUDIT_TRAIL, DBA_FGA_AUDIT_TRAIL 등 감사 기록 조회
@END
@B 통합 감사 기록은 AUDSYS.AUD$UNIFIED에 있고 SYS도 DML·DDL을 할 수 없다(ORA-46385). 그 시도 자체가 감사 기록으로 남는다. 기록을 지우는 정상 경로는 DBMS_AUDIT_MGMT뿐이다.
@B DBMS_AUDIT_MGMT 정리는 '아카이브 기준 시각'을 중심으로 돈다. 외부 보관을 마친 시각을 SET_LAST_ARCHIVE_TIMESTAMP로 알려 주면 CLEAN_AUDIT_TRAIL(use_last_arch_timestamp => TRUE)은 그보다 오래된 기록만 지운다. 정리 작업(CREATE_PURGE_JOB)은 이 과정을 스케줄러에 등록함.
@B 통합 감사 기록은 INIT_CLEANUP이 필요 없다. 호출하면 ORA-46250이 남. 반대로 AUD$·FGA_LOG$는 INIT_CLEANUP 없이 정리하면 ORA-46258이다. INIT_CLEANUP은 FGA_LOG$를 SYSAUX로 옮기기도 한다(원 교안 13장 실습 03). 이번 실습은 FGA_LOG$를 건드리지 않는다.
@B 감사 기록을 syslog로도 보내려면 UNIFIED_AUDIT_SYSTEMLOG(통합 감사)나 AUDIT_SYSLOG_LEVEL(기존 감사)을 쓴다. 둘 다 정적 파라미터라 재기동이 필요해 이번 실습에서는 다루지 않는다. 설정과 결과는 원 교안 13장 실습 04에 있다.
@NOTE 이 실습이 남기는 것
감사 기록은 실습 객체를 지워도 남는다. 사용자를 지운 뒤에도 D10_CLERK의 기록은 그대로 조회됨. 실습 9단계의 정리 실행은 가장 오래된 기록보다 하루 앞선 기준 시각을 써서 삭제 0건으로 끝난다.
@END

@H3 10.2  진행 순서
@TBL
단계 | 하는 일 | 확인할 것
[1] 감사 모드 확인과 준비 | 감사 모드·AUDIT_TRAIL 확인, 역할별 계정과 테이블 | Unified Auditing FALSE, audit_trail DB
[2] FGA 정책 | 급여 10,000 초과 행의 SALARY·COMMISSION_PCT 접근 감사 | AUDIT_ADMIN의 딕셔너리 조회 ORA-00942
[3] 업무 계정의 조회와 변경 | 감사 컬럼 참조 여부·조건 충족 여부가 다른 문장 5개 | 모든 문장 정상 실행
[4] FGA 기록 확인 | AUDIT_VIEWER로 건수 조회, SYS로 문장 확인, 통합 감사 쪽 확인 | 3건, UNIFIED_AUDIT_TRAIL 0건
[5] 통합 감사 정책 | UPDATE·DELETE 감사 정책을 D10_CLERK에 켜고, 권한 없는 DELETE 시도 | BY USER, 성공·실패 YES, DELETE는 ORA-01031
[6] 통합 감사 기록 확인 | AUDIT_VIEWER로 정책별 기록 조회 | UPDATE 0, DELETE 2004
[7] 정책 관리와 기록 보호 | 켜진 정책 DROP, NOAUDIT 후 DROP, SYS의 AUD$UNIFIED DELETE | ORA-46361, ORA-46385와 그 기록
[8] DBMS_AUDIT_MGMT — 정리 기준 시각 | 정리 설정 조회, 통합 감사 INIT_CLEANUP, 가장 오래된 기록보다 하루 앞선 기준 시각 설정 | ORA-46250, 기준 시각 1행
[9] 정리 실행과 결과 확인 | 기준 시각으로 CLEAN_AUDIT_TRAIL, 기준 시각 해제, 관리 호출 기록 조회 | 가장 오래된 기록 그대로, 건수는 증가
[10] 정리와 확인 | FGA 정책·사용자 삭제, 기본 정책 상태 확인 | 정책 0, 활성 정책은 기본 2개
@END

@H3 10.3  실습 스크립트

@P [1] 감사 모드 확인과 준비
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL parameter FOR a20
SYS@orcl> COL value FOR a10
SYS@orcl> SELECT parameter, value FROM v$option WHERE parameter = 'Unified Auditing';

PARAMETER            VALUE
-------------------- ----------
Unified Auditing     FALSE

1 row selected.

SYS@orcl> SHOW PARAMETER audit_trail

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
audit_trail                          string      DB
SYS@orcl> CREATE USER d10_own IDENTIFIED BY d10_own QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d10_sec IDENTIFIED BY d10_sec;

User created.

SYS@orcl> CREATE USER d10_clerk IDENTIFIED BY d10_clerk;

User created.

SYS@orcl> CREATE USER d10_aud IDENTIFIED BY d10_aud;

User created.

SYS@orcl> GRANT CREATE SESSION TO d10_own, d10_sec, d10_clerk, d10_aud;

Grant succeeded.

SYS@orcl> GRANT AUDIT_ADMIN TO d10_sec;

Grant succeeded.

SYS@orcl> GRANT AUDIT_VIEWER TO d10_aud;

Grant succeeded.

SYS@orcl> CREATE TABLE d10_own.emp AS
  2    SELECT employee_id, last_name, department_id, salary, commission_pct FROM hr.employees;

Table created.

SYS@orcl> GRANT SELECT, UPDATE ON d10_own.emp TO d10_clerk;

Grant succeeded.

-- ★ 혼합 모드다. D10_SEC에는 AUDIT_ADMIN, D10_AUD에는 AUDIT_VIEWER만 주었다. 정책을 만드는 계정과 기록을 읽는 계정을 분리함.
@END

@P [2] FGA 정책
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> BEGIN
  2    DBMS_FGA.ADD_POLICY(
  3      object_schema   => 'D10_OWN',
  4      object_name     => 'EMP',
  5      policy_name     => 'D10_SAL_FGA',
  6      audit_condition => 'SALARY > 10000',
  7      audit_column    => 'SALARY,COMMISSION_PCT',
  8      statement_types => 'SELECT,UPDATE',
  9      audit_trail     => DBMS_FGA.DB + DBMS_FGA.EXTENDED);
 10  END;
 11  /

PL/SQL procedure successfully completed.

D10_SEC@orcl> COL policy_name FOR a12
D10_SEC@orcl> COL policy_text FOR a16
D10_SEC@orcl> COL policy_column FOR a24
D10_SEC@orcl> SELECT policy_name, policy_text, policy_column, enabled, sel, upd, del FROM dba_audit_policies WHERE object_schema = 'D10_OWN';
SELECT policy_name, policy_text, policy_column, enabled, sel, upd, del FROM dba_audit_policies WHERE object_schema = 'D10_OWN'
                                                                            *
ERROR at line 1:
ORA-00942: table or view does not exist


D10_SEC@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL policy_name FOR a12
SYS@orcl> COL policy_text FOR a16
SYS@orcl> COL policy_column FOR a24
SYS@orcl> SELECT policy_name, policy_text, policy_column, enabled, sel, upd, del FROM dba_audit_policies WHERE object_schema = 'D10_OWN';

POLICY_NAME  POLICY_TEXT      POLICY_COLUMN            ENA SEL UPD DEL
------------ ---------------- ------------------------ --- --- --- ---
D10_SAL_FGA  SALARY > 10000   SALARY                   YES YES YES NO

1 row selected.

SYS@orcl> COL column_name FOR a16
SYS@orcl> SELECT policy_name, policy_column column_name FROM dba_audit_policy_columns WHERE object_schema = 'D10_OWN';

POLICY_NAME  COLUMN_NAME
------------ ----------------
D10_SAL_FGA  SALARY
D10_SAL_FGA  COMMISSION_PCT

2 rows selected.

-- ★ AUDIT_ADMIN만으로 DBMS_FGA.ADD_POLICY가 됐다. 그런데 같은 계정이 DBA_AUDIT_POLICIES를 조회하면 ORA-00942다. 정책 관리 권한과 딕셔너리 조회 권한은 따로 간다.
--    DBA_AUDIT_POLICIES의 POLICY_COLUMN에는 첫 컬럼(SALARY)만 보인다. 감사 컬럼 전체는 DBA_AUDIT_POLICY_COLUMNS에서 확인한다.
@END

@P [3] 업무 계정의 조회와 변경
@CODE
SQL> CONNECT d10_clerk/d10_clerk
Connected.
D10_CLERK@orcl> SELECT COUNT(*) FROM d10_own.emp WHERE department_id = 90;

  COUNT(*)
----------
         3

1 row selected.

D10_CLERK@orcl> SELECT last_name, salary FROM d10_own.emp WHERE department_id = 90 ORDER BY 1;

LAST_NAME                     SALARY
------------------------- ----------
De Haan                        17000
King                           24000
Kochhar                        17000

3 rows selected.

D10_CLERK@orcl> SELECT last_name, salary FROM d10_own.emp WHERE department_id = 50 AND ROWNUM <= 2 ORDER BY 1;

LAST_NAME                     SALARY
------------------------- ----------
Fripp                           8200
Weiss                           8000

2 rows selected.

D10_CLERK@orcl> SELECT COUNT(*) FROM d10_own.emp WHERE commission_pct > 0.3;

  COUNT(*)
----------
         4

1 row selected.

D10_CLERK@orcl> UPDATE d10_own.emp SET salary = salary * 1.1 WHERE employee_id = 101;

1 row updated.

D10_CLERK@orcl> ROLLBACK;

Rollback complete.

-- ★ 문장별 예상: 90번 COUNT(*)는 감사 컬럼을 참조하지 않는다. 90번 급여 조회는 조건을 만족한다.
--    50번 급여 조회는 결과 행 급여가 모두 10,000 이하다. 커미션 조건 검색은 WHERE에서 감사 컬럼을 참조한다.
--    101번(급여 17,000) UPDATE는 조건을 만족한다. ROLLBACK을 해도 감사 기록은 남는다.
@END

@P [4] FGA 기록 확인
@CODE
SQL> CONNECT d10_aud/d10_aud
Connected.
D10_AUD@orcl> SELECT COUNT(*) FROM dba_fga_audit_trail
  2   WHERE policy_name = 'D10_SAL_FGA' AND timestamp > SYSDATE - 2/1440;

  COUNT(*)
----------
         3

1 row selected.

D10_AUD@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL db_user FOR a10
SYS@orcl> COL stmt FOR a8
SYS@orcl> COL sql_text FOR a72
SYS@orcl> SELECT db_user, statement_type stmt, sql_text FROM dba_fga_audit_trail
  2   WHERE policy_name = 'D10_SAL_FGA' AND timestamp >= (SELECT created FROM dba_users WHERE username = 'D10_OWN')
  3   ORDER BY timestamp, sql_text;

DB_USER    STMT     SQL_TEXT
---------- -------- ------------------------------------------------------------------------
D10_CLERK  SELECT   SELECT COUNT(*) FROM d10_own.emp WHERE commission_pct > 0.3
D10_CLERK  SELECT   SELECT last_name, salary FROM d10_own.emp WHERE department_id = 90 ORDER
                     BY 1

D10_CLERK  UPDATE   UPDATE d10_own.emp SET salary = salary * 1.1 WHERE employee_id = 101

3 rows selected.

SYS@orcl> SELECT COUNT(*) FROM unified_audit_trail WHERE fga_policy_name = 'D10_SAL_FGA';

  COUNT(*)
----------
         0

1 row selected.

-- ★ 기록은 3건이다. 90번 급여 조회, 커미션 조건 검색, UPDATE만 남았다.
--    COUNT(*)와 50번 조회는 기록되지 않았다. 감사 컬럼을 안 썼거나, 조건을 만족하는 행이 없었다.
--    AUDIT_VIEWER로 DBA_FGA_AUDIT_TRAIL을 읽을 수 있다. 같은 시각 UNIFIED_AUDIT_TRAIL에는 이 정책의 기록이 없다. 혼합 모드의 FGA 기록은 FGA_LOG$에만 있다.
@END

@P [5] 통합 감사 정책
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> CREATE AUDIT POLICY d10_emp_pol
  2    ACTIONS UPDATE ON d10_own.emp, DELETE ON d10_own.emp;

Audit policy created.

D10_SEC@orcl> AUDIT POLICY d10_emp_pol BY d10_clerk;

Audit succeeded.

D10_SEC@orcl> COL policy_name FOR a14
D10_SEC@orcl> COL entity_name FOR a12
D10_SEC@orcl> SELECT policy_name, enabled_option, entity_name, success, failure
  2    FROM audit_unified_enabled_policies WHERE policy_name = 'D10_EMP_POL';

POLICY_NAME    ENABLED_OPTION  ENTITY_NAME  SUC FAI
-------------- --------------- ------------ --- ---
D10_EMP_POL    BY USER         D10_CLERK    YES YES

1 row selected.

D10_SEC@orcl> CONNECT d10_clerk/d10_clerk
Connected.
D10_CLERK@orcl> UPDATE d10_own.emp SET salary = salary + 100 WHERE department_id = 90;

3 rows updated.

D10_CLERK@orcl> DELETE FROM d10_own.emp WHERE employee_id = 100;
DELETE FROM d10_own.emp WHERE employee_id = 100
                    *
ERROR at line 1:
ORA-01031: insufficient privileges


D10_CLERK@orcl> ROLLBACK;

Rollback complete.

-- ★ AUDIT_UNIFIED_ENABLED_POLICIES에서 정책이 사용자 단위로 켜졌고 성공·실패 모두 기록 대상임을 확인했다.
--    D10_CLERK에는 DELETE 권한이 없어 ORA-01031로 실패했다. 실패한 문장도 감사 대상이다.
@END

@P [6] 통합 감사 기록 확인
@CODE
SQL> CONNECT d10_aud/d10_aud
Connected.
D10_AUD@orcl> COL dbusername FOR a10
D10_AUD@orcl> COL action_name FOR a8
D10_AUD@orcl> COL sql_text FOR a62
D10_AUD@orcl> SELECT dbusername, action_name, return_code, sql_text
  2    FROM unified_audit_trail
  3   WHERE unified_audit_policies = 'D10_EMP_POL' AND event_timestamp > SYSTIMESTAMP - INTERVAL '2' MINUTE
  4   ORDER BY event_timestamp;

DBUSERNAME ACTION_N RETURN_CODE SQL_TEXT
---------- -------- ----------- --------------------------------------------------------------
D10_CLERK  UPDATE             0 UPDATE d10_own.emp SET salary = salary + 100 WHERE departmen
                                t_id = 90

D10_CLERK  DELETE          2004 DELETE FROM d10_own.emp WHERE employee_id = 100



2 rows selected.

-- ★ UPDATE는 RETURN_CODE 0, 권한 없는 DELETE는 2004로 남았다. 사용자 화면의 ORA-01031과 다른 번호다. 실패 시도를 찾는 조회는 RETURN_CODE <> 0으로 건다.
--    기록에는 SQL_TEXT가 그대로 있다. 정책 하나만 걸어도 누가 어떤 문장을 실행했는지 남는다.
@END

@P [7] 정책 관리와 기록 보호
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> DROP AUDIT POLICY d10_emp_pol;
DROP AUDIT POLICY d10_emp_pol
*
ERROR at line 1:
ORA-46361: Audit policy cannot be dropped as it is currently enabled.


D10_SEC@orcl> NOAUDIT POLICY d10_emp_pol BY d10_clerk;

Noaudit succeeded.

D10_SEC@orcl> DROP AUDIT POLICY d10_emp_pol;

Audit Policy dropped.

D10_SEC@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> DELETE FROM audsys.aud$unified WHERE 1 = 0;
DELETE FROM audsys.aud$unified WHERE 1 = 0
                   *
ERROR at line 1:
ORA-46385: DML and DDL operations are not allowed on table "AUDSYS"."AUD$UNIFIED".


SYS@orcl> COL dbusername FOR a10
SYS@orcl> COL action_name FOR a8
SYS@orcl> COL object_name FOR a12
SYS@orcl> SELECT dbusername, action_name, object_name, return_code FROM unified_audit_trail
  2   WHERE object_schema = 'AUDSYS' AND object_name = 'AUD$UNIFIED'
  3     AND event_timestamp >= (SELECT created FROM dba_users WHERE username = 'D10_OWN');

DBUSERNAME ACTION_N OBJECT_NAME  RETURN_CODE
---------- -------- ------------ -----------
SYS        DELETE   AUD$UNIFIED        46385

1 row selected.

-- ★ 켜진 정책은 ORA-46361로 DROP이 거부됐다. NOAUDIT은 AUDIT 때와 같은 BY 절로 해야 실제로 꺼진다.
--    SYS가 0건 조건으로 DELETE를 해도 ORA-46385로 막혔다. 실행 전에 거부되고, 그 시도가 RETURN_CODE 46385로 남았다.
@END

@P [8] DBMS_AUDIT_MGMT — 정리 기준 시각
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> COL parameter_name FOR a30
D10_SEC@orcl> COL parameter_value FOR a14
D10_SEC@orcl> COL audit_trail FOR a20
D10_SEC@orcl> SELECT parameter_name, parameter_value, audit_trail FROM dba_audit_mgmt_config_params
  2   WHERE audit_trail IN ('UNIFIED AUDIT TRAIL', 'FGA AUDIT TRAIL') ORDER BY 3, 1;

PARAMETER_NAME                 PARAMETER_VALU AUDIT_TRAIL
------------------------------ -------------- --------------------
DB AUDIT CLEAN BATCH SIZE      10000          FGA AUDIT TRAIL
DB AUDIT TABLESPACE            SYSTEM         FGA AUDIT TRAIL
AUDIT FILE MAX AGE             5              UNIFIED AUDIT TRAIL
AUDIT FILE MAX SIZE            10000          UNIFIED AUDIT TRAIL
AUDIT WRITE MODE               QUEUED WRITE M UNIFIED AUDIT TRAIL
                               ODE

DB AUDIT TABLESPACE            SYSAUX         UNIFIED AUDIT TRAIL

6 rows selected.

D10_SEC@orcl> EXEC DBMS_AUDIT_MGMT.INIT_CLEANUP(DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED, 24)
BEGIN DBMS_AUDIT_MGMT.INIT_CLEANUP(DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED, 24); END;

*
ERROR at line 1:
ORA-46250: Invalid value for argument 'AUDIT_TRAIL_TYPE'
ORA-06512: at "AUDSYS.DBMS_AUDIT_MGMT", line 204
ORA-06512: at "AUDSYS.DBMS_AUDIT_MGMT", line 717
ORA-06512: at line 1


D10_SEC@orcl> COL oldest FOR a30
D10_SEC@orcl> SELECT COUNT(*) total, TO_CHAR(MIN(event_timestamp_utc), 'YYYY-MM-DD HH24:MI:SS') oldest FROM unified_audit_trail;

     TOTAL OLDEST
---------- ------------------------------
      2290 2026-07-29 06:06:31

1 row selected.

D10_SEC@orcl> DECLARE
  2    v_cut TIMESTAMP;
  3  BEGIN
  4    SELECT MIN(event_timestamp_utc) - INTERVAL '1' DAY INTO v_cut FROM unified_audit_trail;
  5    DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
  6      audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
  7      last_archive_time => v_cut);
  8  END;
  9  /

PL/SQL procedure successfully completed.

D10_SEC@orcl> COL last_archive_ts FOR a36
D10_SEC@orcl> SELECT audit_trail, last_archive_ts FROM dba_audit_mgmt_last_arch_ts;

AUDIT_TRAIL          LAST_ARCHIVE_TS
-------------------- ------------------------------------
UNIFIED AUDIT TRAIL  28-JUL-26 06.06.31.706784 AM +00:00

1 row selected.

-- ★ 통합 감사 기록은 SYSAUX에 있고, 이 버전의 쓰기 모드 설정값은 QUEUED WRITE MODE로 표시됐다. FGA 기록 테이블은 아직 SYSTEM에 있다.
--    통합 감사 기록에 INIT_CLEANUP을 부르자 ORA-46250이다. 초기화 없이 바로 정리할 수 있는 대상이다.
--    기준 시각은 가장 오래된 기록(2026-07-29 06:06:31 UTC)보다 하루 앞선 값이다. 이 시각보다 오래된 기록은 없다.
@END

@P [9] 정리 실행과 결과 확인
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> COL oldest FOR a30
D10_SEC@orcl> BEGIN
  2    DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
  3      audit_trail_type        => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
  4      use_last_arch_timestamp => TRUE);
  5  END;
  6  /

PL/SQL procedure successfully completed.

D10_SEC@orcl> SELECT COUNT(*) total, TO_CHAR(MIN(event_timestamp_utc), 'YYYY-MM-DD HH24:MI:SS') oldest FROM unified_audit_trail;

     TOTAL OLDEST
---------- ------------------------------
      2292 2026-07-29 06:06:31

1 row selected.

D10_SEC@orcl> EXEC DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP(DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED)

PL/SQL procedure successfully completed.

D10_SEC@orcl> SELECT COUNT(*) FROM dba_audit_mgmt_last_arch_ts;

  COUNT(*)
----------
         0

1 row selected.

D10_SEC@orcl> COL dbusername FOR a10
D10_SEC@orcl> COL action_name FOR a14
D10_SEC@orcl> COL object_name FOR a16
D10_SEC@orcl> COL sql_text FOR a50
D10_SEC@orcl> SELECT dbusername, action_name, object_name, SUBSTR(sql_text, 1, 50) sql_text FROM unified_audit_trail
  2   WHERE object_name = 'DBMS_AUDIT_MGMT' AND dbusername = 'D10_SEC'
  3     AND event_timestamp >= (SELECT created FROM dba_users WHERE username = 'D10_OWN')
  4   ORDER BY event_timestamp;

DBUSERNAME ACTION_NAME    OBJECT_NAME      SQL_TEXT
---------- -------------- ---------------- --------------------------------------------------
D10_SEC    EXECUTE        DBMS_AUDIT_MGMT  BEGIN DBMS_AUDIT_MGMT.INIT_CLEANUP(DBMS_AUDIT_MGMT


D10_SEC    EXECUTE        DBMS_AUDIT_MGMT  DECLARE
                                             v_cut TIMESTAMP;
                                           BEGIN
                                             SELECT MIN(even

D10_SEC    EXECUTE        DBMS_AUDIT_MGMT  BEGIN
                                             DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
                                               aud

D10_SEC    EXECUTE        DBMS_AUDIT_MGMT  BEGIN DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP



4 rows selected.

-- ★ 정리 후에도 가장 오래된 기록은 그대로다. 지워진 것이 없다. 건수는 오히려 늘었다. 정리 호출 자체가 기록되기 때문이다.
--    DBMS_AUDIT_MGMT 실행은 감사 정책이 없어도 항상 기록된다. D10_SEC의 호출 네 건(INIT_CLEANUP 실패 포함)이 모두 보인다.
--    실무에서는 외부 보관을 마친 시각을 기준으로 주고, 정리 작업으로 주기 실행한다. CLEAR_LAST_ARCHIVE_TIMESTAMP로 기준 시각을 지워 원래 상태로 돌렸다.
@END

@P [10] 정리와 확인
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> SELECT COUNT(*) FROM dba_fga_audit_trail WHERE policy_name = 'D10_SAL_FGA' AND timestamp >= (SELECT created FROM dba_users WHERE username = 'D10_OWN');

  COUNT(*)
----------
         4

1 row selected.

SYS@orcl> EXEC DBMS_FGA.DROP_POLICY('D10_OWN', 'EMP', 'D10_SAL_FGA')

PL/SQL procedure successfully completed.

SYS@orcl> DROP USER d10_clerk CASCADE;

User dropped.

SYS@orcl> DROP USER d10_aud CASCADE;

User dropped.

SYS@orcl> DROP USER d10_sec CASCADE;

User dropped.

SYS@orcl> DROP USER d10_own CASCADE;

User dropped.

SYS@orcl> SELECT COUNT(*) FROM dba_audit_policies WHERE object_schema = 'D10_OWN';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM audit_unified_policies WHERE policy_name = 'D10_EMP_POL';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> COL policy_name FOR a20
SYS@orcl> COL entity_name FOR a10
SYS@orcl> SELECT policy_name, entity_name FROM audit_unified_enabled_policies ORDER BY 1;

POLICY_NAME          ENTITY_NAM
-------------------- ----------
ORA_LOGON_FAILURES   ALL USERS
ORA_SECURECONFIG     ALL USERS

2 rows selected.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'D10%';

  COUNT(*)
----------
         0

1 row selected.

-- ★ FGA 기록 4건은 정책과 사용자를 지운 뒤에도 남는다. 3단계 3건에 5단계의 90번 부서 UPDATE가 더해졌다.
--    활성 통합 감사 정책은 실습 전과 같은 ORA_SECURECONFIG, ORA_LOGON_FAILURES 두 개다.
@END

@H3 10.4  정리와 확인 포인트
@B 혼합 모드에서 FGA 기록은 FGA_LOG$, 통합 감사 정책 기록은 UNIFIED_AUDIT_TRAIL에 따로 남는다. 조회·수집 경로를 둘 다 만든다.
@B FGA는 감사 컬럼 참조와 행 조건을 모두 만족할 때만 기록한다. ROLLBACK해도 기록은 남는다.
@B 통합 감사의 권한 실패 기록은 RETURN_CODE 2004로 남는다. 실패 탐지 조회는 RETURN_CODE <> 0으로 건다.
@B AUD$UNIFIED는 SYS도 직접 지울 수 없고, 시도는 기록된다. 삭제는 DBMS_AUDIT_MGMT 기준 시각과 정리 작업으로만 한다.
@B 정리 기준 시각은 외부 보관이 끝난 시각이어야 한다. 보관 확인 없이 기준 시각을 앞당기면 되돌릴 수 없는 삭제가 일어난다.
