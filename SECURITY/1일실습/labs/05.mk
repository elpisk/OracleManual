@H2 실습 05  Application Context와 VPD로 행·컬럼 통제
@TBL
항목 | 내용
목표 | 로그온 시점에 신뢰 패키지로 세션 속성을 채우고, 그 값으로 행 수준·컬럼 수준 VPD 정책을 건다. 정책 오류를 트레이스로 진단한다.
소요 | 50분
접속 | SYS(준비·진단), D05_SEC(보안 관리자), D05_KIM(50번 부서 사원), D05_LEE(80번 부서 관리자)
변경 | 사용자 4개, 컨텍스트 D05_CTX, 로그온 트리거 2개, VPD 정책 2개. 마지막 단계에서 모두 지움
@END

@H3 05.1  실습 전에 — 정책 함수는 술어 문자열을 돌려줄 뿐이다
@B VPD는 SQL을 고쳐 쓰는 기능이다. 정책 함수가 돌려준 문자열이 대상 테이블 자리에 `WHERE (술어)`가 붙은 인라인 뷰로 들어간다. 사용자 문장에는 흔적이 남지 않음.
@B 정책 함수는 `(스키마, 객체)` 두 인자를 받고 VARCHAR2를 돌려준다. NULL이나 빈 문자열이면 필터가 없고, `1=2`면 행이 하나도 안 보인다.
@B 술어 안에서 사용자 구분 값을 직접 조회하면 문장마다 서브쿼리가 붙는다. 그래서 값은 로그온 때 한 번 Application Context에 넣고, 술어는 `SYS_CONTEXT(...)`만 참조하게 만든다.
@B 로컬 컨텍스트 값은 `CREATE CONTEXT ... USING`에 지정한 패키지 안에서만 바꿀 수 있다. 사용자가 `DBMS_SESSION.SET_CONTEXT`를 직접 부르면 ORA-01031이 나고, 이 제약이 위조를 막는 장치다.
@B 컨텍스트 값을 채우는 로그온 트리거는 ON DATABASE보다 ON 스키마.SCHEMA로 거는 편이 안전하다. 트리거가 예외를 내면 그 사용자의 접속이 실패하므로, 매핑 누락 같은 예외는 패키지 안에서 처리한다.
@B 정책 함수는 함수 소유자의 권한으로 실행된다. 함수가 읽는 객체 권한은 소유자(D05_SEC)에게 직접 있어야 하고, 조회하는 사용자에게는 필요 없다.
@B 한 테이블에 정책이 여럿이면 각 술어가 AND로 결합된다. 행 정책과 컬럼 정책을 따로 만들어 겹쳐 쓸 수 있고, 응용별로 나누려면 정책 그룹(CREATE_POLICY_GROUP)을 쓴다.
@B 정책 유형마다 정책 함수를 다시 부르는 시점이 다르다.
@TBL
정책 유형 | 함수 재평가 시점 | 쓰는 경우
DYNAMIC(기본) | 문장을 실행할 때마다 | 술어가 시각·외부 상태에 따라 바뀜
CONTEXT_SENSITIVE | 세션의 컨텍스트 값이 바뀔 때 | 술어가 SYS_CONTEXT에만 기대는 경우(이번 실습)
STATIC | 처음 파싱할 때 한 번 | 술어 문자열 자체가 고정됨
@END
@B statement_types에 INSERT를 넣으려면 19c에서는 update_check => TRUE가 함께 있어야 한다. 빠지면 ORA-28104가 남. update_check가 켜지면 변경 후 행이 술어를 벗어나는 INSERT·UPDATE는 ORA-28115로 막힌다.
@B 컬럼 수준 VPD(sec_relevant_cols)는 지정 컬럼을 참조하는 문장에만 정책을 적용한다.
@B 기본 동작은 행 자체를 걸러낸다. ALL_ROWS 옵션을 주면 행은 모두 보이고 해당 컬럼만 NULL로 바뀜. ALL_ROWS는 SELECT 전용이다.
@B 술어 문법 오류는 ADD_POLICY 때 드러나지 않는다. 조회 시점에 ORA-28113으로 나타나고, 원인 문장은 세션 트레이스 파일에 남는다. V$VPD_POLICY에서는 커서마다 실제로 붙은 술어를 볼 수 있다.
@NOTE 정책이 적용되지 않는 계정
SYS와 EXEMPT ACCESS POLICY 권한 보유자에게는 VPD가 적용되지 않는다. 데이터 소유자는 면제 대상이 아니다. 이번 실습의 술어 함수가 대상 사용자 외에는 NULL을 돌려주는 것은, 소유자와 다른 업무 계정이 영향을 받지 않게 하려는 설계다. EXEMPT ACCESS POLICY 보유자는 정기 점검 대상에 넣는다.
@END

@H3 05.2  진행 순서
@TBL
단계 | 하는 일 | 확인할 것
[1] 준비 — 계정과 데이터 | 소유자·보안 관리자·사원 계정 생성, HR.EMPLOYEES 복사 | 50번 45명, 80번 34명
[2] 컨텍스트와 신뢰 패키지 | 매핑 테이블, CREATE CONTEXT USING, 값 설정 패키지 | 패키지가 컨텍스트의 유일한 쓰기 경로
[3] 로그온 트리거와 위조 시도 | 스키마 단위 AFTER LOGON 트리거, 직접 SET_CONTEXT 호출 | DEPT=50, 위조 시 ORA-01031
[4] 정책 함수와 행 수준 정책 | 술어 함수 작성, INSERT 포함 정책 등록 두 번 | update_check 없이 ORA-28104
[5] 사용자별 결과와 update_check | KIM·LEE 조회, 다른 부서 UPDATE·INSERT | KIM 50번만, 80번 UPDATE 0건, INSERT ORA-28115
[6] 컬럼 수준 정책 — 급여는 관리자만 | SALARY 컬럼에 ALL_ROWS 정책 추가 | KIM은 SALARY NULL, LEE는 값 보임
[7] 진단 — V$VPD_POLICY와 술어 오류 | 실제 술어 조회 후 함수를 틀린 컬럼명으로 교체 | ORA-28113
[8] 트레이스로 원인 찾기 | 세션 트레이스에서 정책 이름 검색 | RLS view 문장과 ORA-00904
[9] 술어 복구 | 함수를 원래대로 교체 후 재조회 | 45건
[10] 정리와 확인 | 정책·컨텍스트·사용자 삭제 | 모든 조회 0건
@END

@H3 05.3  실습 스크립트

@P [1] 준비 — 계정과 데이터
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d05_own IDENTIFIED BY d05_own QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d05_sec IDENTIFIED BY d05_sec QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d05_kim IDENTIFIED BY d05_kim;

User created.

SYS@orcl> CREATE USER d05_lee IDENTIFIED BY d05_lee;

User created.

SYS@orcl> GRANT CREATE SESSION TO d05_own, d05_sec, d05_kim, d05_lee;

Grant succeeded.

SYS@orcl> GRANT CREATE TABLE, CREATE PROCEDURE, CREATE ANY CONTEXT TO d05_sec;

Grant succeeded.

SYS@orcl> GRANT EXECUTE ON DBMS_RLS TO d05_sec;

Grant succeeded.

SYS@orcl> CREATE TABLE d05_own.emp AS
  2    SELECT employee_id, last_name, department_id, salary FROM hr.employees;

Table created.

SYS@orcl> GRANT SELECT, INSERT, UPDATE, DELETE ON d05_own.emp TO d05_kim, d05_lee;

Grant succeeded.

SYS@orcl> SELECT department_id, COUNT(*) cnt, SUM(salary) sum_sal
  2    FROM d05_own.emp WHERE department_id IN (50, 80) GROUP BY department_id ORDER BY 1;

DEPARTMENT_ID        CNT    SUM_SAL
------------- ---------- ----------
           50         45     156400
           80         34     304500

2 rows selected.

-- ★ 보안 관리자 D05_SEC는 정책·컨텍스트만 다룬다. 데이터는 D05_OWN 소유라 소유자와 정책 관리자가 분리됨.
--    두 부서의 행 수(45, 34)가 이후 정책 결과를 판단하는 기준이다.
@END

@P [2] 컨텍스트와 신뢰 패키지
@CODE
SQL> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE TABLE user_map (
  2    username  VARCHAR2(30) PRIMARY KEY,
  3    dept_id   NUMBER,
  4    is_mgr    CHAR(1));

Table created.

D05_SEC@orcl> INSERT INTO user_map VALUES ('D05_KIM', 50, 'N');

1 row created.

D05_SEC@orcl> INSERT INTO user_map VALUES ('D05_LEE', 80, 'Y');

1 row created.

D05_SEC@orcl> COMMIT;

Commit complete.

D05_SEC@orcl> CREATE CONTEXT d05_ctx USING d05_sec.ctx_pkg;

Context created.

D05_SEC@orcl> CREATE OR REPLACE PACKAGE ctx_pkg AS
  2    PROCEDURE set_user;
  3  END;
  4  /

Package created.

D05_SEC@orcl> CREATE OR REPLACE PACKAGE BODY ctx_pkg AS
  2    PROCEDURE set_user IS
  3      v_dept NUMBER;
  4      v_mgr  CHAR(1);
  5    BEGIN
  6      SELECT dept_id, is_mgr INTO v_dept, v_mgr
  7        FROM user_map WHERE username = SYS_CONTEXT('USERENV', 'SESSION_USER');
  8      DBMS_SESSION.SET_CONTEXT('D05_CTX', 'DEPT', v_dept);
  9      DBMS_SESSION.SET_CONTEXT('D05_CTX', 'MGR',  v_mgr);
 10    EXCEPTION
 11      WHEN NO_DATA_FOUND THEN NULL;
 12    END;
 13  END;
 14  /

Package body created.

-- ★ 컨텍스트를 패키지보다 먼저 만들었지만 오류가 없었다. USING 절에는 패키지 이름이 기록된다.
--    매핑에 없는 사용자는 NO_DATA_FOUND를 삼켜 값이 비게 둔다. 로그온 트리거가 예외를 내면 접속 자체가 막힌다.
@END

@P [3] 로그온 트리거와 위조 시도
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE OR REPLACE TRIGGER d05_sec.trg_logon_kim AFTER LOGON ON d05_kim.SCHEMA
  2  BEGIN d05_sec.ctx_pkg.set_user; END;
  3  /

Trigger created.

SYS@orcl> CREATE OR REPLACE TRIGGER d05_sec.trg_logon_lee AFTER LOGON ON d05_lee.SCHEMA
  2  BEGIN d05_sec.ctx_pkg.set_user; END;
  3  /

Trigger created.

SYS@orcl> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> COL dept FOR a6
D05_KIM@orcl> COL mgr FOR a4
D05_KIM@orcl> SELECT SYS_CONTEXT('D05_CTX', 'DEPT') dept, SYS_CONTEXT('D05_CTX', 'MGR') mgr FROM dual;

DEPT   MGR
------ ----
50     N

1 row selected.

D05_KIM@orcl> EXEC DBMS_SESSION.SET_CONTEXT('D05_CTX', 'DEPT', '80')
BEGIN DBMS_SESSION.SET_CONTEXT('D05_CTX', 'DEPT', '80'); END;

*
ERROR at line 1:
ORA-01031: insufficient privileges
ORA-06512: at "SYS.DBMS_SESSION", line 141
ORA-06512: at line 1


D05_KIM@orcl> SELECT SYS_CONTEXT('D05_CTX', 'DEPT') dept FROM dual;

DEPT
------
50

1 row selected.

-- ★ 트리거를 ON DATABASE가 아니라 ON d05_kim.SCHEMA로 걸어 다른 사용자 접속에는 영향이 없다.
--    직접 SET_CONTEXT는 ORA-01031. DBMS_SESSION은 PUBLIC 실행 권한이 있지만, 지정 패키지 밖에서의 쓰기를 커널이 거부한다.
--    위조 시도 뒤에도 DEPT는 50 그대로다.
@END

@P [4] 정책 함수와 행 수준 정책
@CODE
SQL> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE OR REPLACE FUNCTION row_pred (p_schema VARCHAR2, p_object VARCHAR2)
  2  RETURN VARCHAR2 AS
  3  BEGIN
  4    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('D05_KIM', 'D05_LEE') THEN
  5      RETURN 'department_id = SYS_CONTEXT(''D05_CTX'', ''DEPT'')';
  6    END IF;
  7    RETURN NULL;
  8  END;
  9  /

Function created.

D05_SEC@orcl> BEGIN
  2    DBMS_RLS.ADD_POLICY(
  3      object_schema   => 'D05_OWN',
  4      object_name     => 'EMP',
  5      policy_name     => 'D05_ROW_POL',
  6      function_schema => 'D05_SEC',
  7      policy_function => 'ROW_PRED',
  8      statement_types => 'SELECT,INSERT,UPDATE,DELETE',
  9      policy_type     => DBMS_RLS.CONTEXT_SENSITIVE);
 10  END;
 11  /
BEGIN
*
ERROR at line 1:
ORA-28104: input value for statement_types is not valid
ORA-06512: at "SYS.DBMS_RLS_INT", line 23
ORA-06512: at "SYS.DBMS_RLS", line 54
ORA-06512: at line 2


D05_SEC@orcl> BEGIN
  2    DBMS_RLS.ADD_POLICY(
  3      object_schema   => 'D05_OWN',
  4      object_name     => 'EMP',
  5      policy_name     => 'D05_ROW_POL',
  6      function_schema => 'D05_SEC',
  7      policy_function => 'ROW_PRED',
  8      statement_types => 'SELECT,INSERT,UPDATE,DELETE',
  9      update_check    => TRUE,
 10      policy_type     => DBMS_RLS.CONTEXT_SENSITIVE);
 11  END;
 12  /

PL/SQL procedure successfully completed.

-- ★ 첫 ADD_POLICY는 statement_types에 INSERT가 있는데 update_check가 없어 ORA-28104로 거부됐다.
--    두 번째 호출에서 update_check => TRUE를 넣자 등록됐다. 정책은 실패한 첫 호출에서 만들어지지 않았으므로 ORA-28101도 나지 않는다.
@END

@P [5] 사용자별 결과와 update_check
@CODE
SQL> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> SELECT department_id, COUNT(*) FROM d05_own.emp GROUP BY department_id;

DEPARTMENT_ID   COUNT(*)
------------- ----------
           50         45

1 row selected.

D05_KIM@orcl> UPDATE d05_own.emp SET salary = salary + 1 WHERE department_id = 80;

0 rows updated.

D05_KIM@orcl> INSERT INTO d05_own.emp VALUES (9001, 'Fake', 80, 1000);
INSERT INTO d05_own.emp VALUES (9001, 'Fake', 80, 1000)
                    *
ERROR at line 1:
ORA-28115: policy with check option violation


D05_KIM@orcl> INSERT INTO d05_own.emp VALUES (9002, 'Ok', 50, 1000);

1 row created.

D05_KIM@orcl> ROLLBACK;

Rollback complete.

D05_KIM@orcl> CONNECT d05_lee/d05_lee
Connected.
D05_LEE@orcl> SELECT department_id, COUNT(*) FROM d05_own.emp GROUP BY department_id;

DEPARTMENT_ID   COUNT(*)
------------- ----------
           80         34

1 row selected.

-- ★ KIM에게는 50번 45행, LEE에게는 80번 34행만 보인다. 같은 테이블, 같은 문장이다.
--    UPDATE ... WHERE department_id = 80은 오류 없이 0건이다. 술어가 대상 행을 먼저 걸러냈기 때문이다.
--    80번 부서 행 INSERT는 ORA-28115. 들어갈 행이 술어를 만족하지 않는다. 자기 부서(50) 행은 들어갔다.
@END

@P [6] 컬럼 수준 정책 — 급여는 관리자만
@CODE
SQL> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE OR REPLACE FUNCTION sal_pred (p_schema VARCHAR2, p_object VARCHAR2)
  2  RETURN VARCHAR2 AS
  3  BEGIN
  4    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('D05_KIM', 'D05_LEE') THEN
  5      RETURN 'SYS_CONTEXT(''D05_CTX'', ''MGR'') = ''Y''';
  6    END IF;
  7    RETURN NULL;
  8  END;
  9  /

Function created.

D05_SEC@orcl> BEGIN
  2    DBMS_RLS.ADD_POLICY(
  3      object_schema         => 'D05_OWN',
  4      object_name           => 'EMP',
  5      policy_name           => 'D05_SAL_POL',
  6      function_schema       => 'D05_SEC',
  7      policy_function       => 'SAL_PRED',
  8      statement_types       => 'SELECT',
  9      sec_relevant_cols     => 'SALARY',
 10      sec_relevant_cols_opt => DBMS_RLS.ALL_ROWS,
 11      policy_type           => DBMS_RLS.CONTEXT_SENSITIVE);
 12  END;
 13  /

PL/SQL procedure successfully completed.

D05_SEC@orcl> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> SELECT employee_id, last_name, salary FROM d05_own.emp WHERE employee_id BETWEEN 120 AND 124 ORDER BY 1;

EMPLOYEE_ID LAST_NAME                     SALARY
----------- ------------------------- ----------
        120 Weiss
        121 Fripp
        122 Kaufling
        123 Vollman
        124 Mourgos

5 rows selected.

D05_KIM@orcl> SELECT COUNT(*), COUNT(salary) FROM d05_own.emp;

  COUNT(*) COUNT(SALARY)
---------- -------------
        45             0

1 row selected.

D05_KIM@orcl> CONNECT d05_lee/d05_lee
Connected.
D05_LEE@orcl> SELECT employee_id, last_name, salary FROM d05_own.emp WHERE employee_id BETWEEN 145 AND 149 ORDER BY 1;

EMPLOYEE_ID LAST_NAME                     SALARY
----------- ------------------------- ----------
        145 Russell                        14000
        146 Partners                       13500
        147 Errazuriz                      12000
        148 Cambrault                      11000
        149 Zlotkey                        10500

5 rows selected.

-- ★ KIM은 행은 보지만 SALARY가 비었다. COUNT(*)는 45, COUNT(salary)는 0이다. ALL_ROWS라서 행 수는 줄지 않음.
--    LEE는 MGR=Y라 급여가 보인다. 두 정책이 AND로 겹쳐, LEE도 여전히 80번 부서 행만 본다.
--    ALL_ROWS 없이 기본값으로 걸면 SALARY를 참조한 문장에서 행 자체가 사라진다(원 교안 7장 실습 04).
@END

@P [7] 진단 — V$VPD_POLICY와 술어 오류
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL policy FOR a12
SYS@orcl> COL predicate FOR a50
SYS@orcl> SELECT DISTINCT policy, predicate FROM v$vpd_policy WHERE object_owner = 'D05_OWN' ORDER BY 1;

POLICY       PREDICATE
------------ --------------------------------------------------
D05_ROW_POL  department_id = SYS_CONTEXT('D05_CTX', 'DEPT')
D05_SAL_POL  SYS_CONTEXT('D05_CTX', 'MGR') = 'Y'

2 rows selected.

SYS@orcl> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE OR REPLACE FUNCTION row_pred (p_schema VARCHAR2, p_object VARCHAR2)
  2  RETURN VARCHAR2 AS
  3  BEGIN
  4    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('D05_KIM', 'D05_LEE') THEN
  5      RETURN 'dept_no = SYS_CONTEXT(''D05_CTX'', ''DEPT'')';
  6    END IF;
  7    RETURN NULL;
  8  END;
  9  /

Function created.

D05_SEC@orcl> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> SELECT COUNT(*) FROM d05_own.emp;
SELECT COUNT(*) FROM d05_own.emp
                             *
ERROR at line 1:
ORA-28113: policy predicate has error

-- ★ V$VPD_POLICY에는 공유 풀 커서에 실제로 붙은 술어가 남는다. 함수 코드를 보지 않고도 정책 결과를 확인할 수 있다.
--    함수는 잘 컴파일됐지만, 돌려주는 술어의 컬럼명(dept_no)이 틀렸다. 조회 시점에 ORA-28113이 남.
@END

@P [8] 트레이스로 원인 찾기
@CODE
[oracle@oel7v9 ~]$ cd /u01/app/oracle/diag/rdbms/orcl/orcl/trace
[oracle@oel7v9 trace]$ grep -l 'D05_ROW_POL' $(ls -t *.trc | head -30) | head -1
orcl_ora_2271.trc
[oracle@oel7v9 trace]$ grep -h -A2 -B1 'dept_no' $(grep -l 'D05_ROW_POL' $(ls -t *.trc | head -30) | head -1) | head -12
RLS view  :
SELECT  "EMPLOYEE_ID","LAST_NAME","DEPARTMENT_ID","SALARY" FROM "D05_OWN"."EMP"   "EMP" WHERE (dept_no = SYS_CONTEXT('D05_CTX', 'DEPT'))
ORA-00904: "DEPT_NO": invalid identifier
-------------------------------------------------------------

-- ★ ORA-28113이 나면 서버 프로세스가 트레이스를 쓴다. 정책 이름으로 찾으면 술어가 붙은 최종 문장(RLS view)과 실제 원인 ORA-00904가 함께 나온다.
--    사용자에게 보이는 오류는 ORA-28113 하나뿐이라, 원인 확인은 DBA 몫이다.
@END

@P [9] 술어 복구
@CODE
SQL> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE OR REPLACE FUNCTION row_pred (p_schema VARCHAR2, p_object VARCHAR2)
  2  RETURN VARCHAR2 AS
  3  BEGIN
  4    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('D05_KIM', 'D05_LEE') THEN
  5      RETURN 'department_id = SYS_CONTEXT(''D05_CTX'', ''DEPT'')';
  6    END IF;
  7    RETURN NULL;
  8  END;
  9  /

Function created.

D05_SEC@orcl> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> SELECT COUNT(*) FROM d05_own.emp;

  COUNT(*)
----------
        45

1 row selected.

-- ★ 정책을 다시 등록하지 않아도 된다. 정책은 함수 이름만 가리키므로 함수만 고치면 다음 파싱부터 바로 반영됨.
@END

@P [10] 정리와 확인
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_RLS.DROP_POLICY('D05_OWN', 'EMP', 'D05_SAL_POL');
  3    DBMS_RLS.DROP_POLICY('D05_OWN', 'EMP', 'D05_ROW_POL');
  4  END;
  5  /

PL/SQL procedure successfully completed.

SYS@orcl> DROP CONTEXT d05_ctx;

Context dropped.

SYS@orcl> DROP USER d05_kim CASCADE;

User dropped.

SYS@orcl> DROP USER d05_lee CASCADE;

User dropped.

SYS@orcl> DROP USER d05_sec CASCADE;

User dropped.

SYS@orcl> DROP USER d05_own CASCADE;

User dropped.

SYS@orcl> SELECT COUNT(*) FROM dba_policies WHERE object_owner = 'D05_OWN';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_context WHERE namespace = 'D05_CTX';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'D05%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_triggers WHERE owner = 'D05_SEC';

  COUNT(*)
----------
         0

1 row selected.

-- ★ 컨텍스트는 스키마 객체가 아니어서 DROP USER CASCADE로 지워지지 않는다. 따로 DROP CONTEXT 해야 한다.
--    트리거는 소유자 D05_SEC와 함께 지워졌다.
@END

@H3 05.4  정리와 확인 포인트
@B 컨텍스트는 신뢰 패키지로만 바뀐다. 위조 시도는 ORA-01031이고 값은 유지됐다.
@B INSERT를 포함하는 정책은 update_check => TRUE가 필수다(없으면 ORA-28104). 술어를 벗어나는 변경은 ORA-28115로 막힌다.
@B 범위 밖 UPDATE·DELETE는 오류 없이 0건으로 끝난다. 응용 프로그램이 처리 건수를 확인하지 않으면 실패를 알아채지 못함.
@B ALL_ROWS 컬럼 정책은 행 수를 유지하고 값만 NULL로 만든다. 집계나 보고서가 NULL을 0으로 오해하지 않는지 확인한다.
@B 술어 오류는 조회 시점에 ORA-28113으로 드러난다. 원인은 트레이스의 RLS view 문장에서 찾고, 운영 반영 전에는 대상 계정으로 실제 조회를 한 번 돌려 본다.
