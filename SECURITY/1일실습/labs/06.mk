@H2 실습 06  Data Redaction으로 조회 결과 가리기
@TBL
항목 | 내용
목표 | 한 정책에 FULL·REGEXP·PARTIAL 리댁션을 묶고, 급여 컬럼만 역할 기반 정책 식으로 따로 통제한다. 리댁션이 막지 못하는 경로를 직접 확인한다.
소요 | 40분
접속 | SYS, D06_SEC(정책 관리자), D06_APP(일반 응용 계정), D06_PAY(급여 담당, D06_PAYROLL 역할)
변경 | 사용자 4개, 역할 1개, 리댁션 정책 1개, 이름 붙은 정책 식 1개. 마지막 단계에서 모두 지움
@END

@H3 06.1  실습 전에 — 리댁션은 결과를 바꿀 뿐 데이터 접근을 막지 않는다
@B Data Redaction은 질의 결과가 클라이언트로 나가기 직전에 컬럼 값을 바꾼다. 블록, 버퍼 캐시, 언두, 리두에는 원래 값이 그대로 있다. 권한이 있는 사용자는 실제 값으로 계산함.
@B 이 때문에 WHERE, ORDER BY, GROUP BY는 실제 값으로 평가된다. `WHERE salary > 7000`을 조건만 바꿔 가며 반복하면 가려진 값을 좁혀 갈 수 있다. 리댁션은 화면 노출을 줄이는 장치이고, 접근 통제는 VPD와 권한으로 따로 한다.
@B 테이블 하나에 정책은 하나만 만들 수 있다. 컬럼은 ALTER_POLICY의 ADD_COLUMN으로 늘린다. 정책의 expression은 모든 컬럼에 공통으로 적용된다.
@B 컬럼마다 다른 조건이 필요하면 이름 붙은 정책 식을 쓴다(12.2부터). CREATE_POLICY_EXPRESSION으로 식을 만들고 APPLY_POLICY_EXPR_TO_COL로 특정 컬럼에 붙인다.
@B 리댁션 유형은 출력 형태에 따라 고른다.
@TBL
유형 | 결과 | 적합한 데이터
FULL | 숫자 0, 문자 공백, 날짜 0001-01-01 | 급여처럼 값 전체를 숨길 때
PARTIAL | 고정 위치의 일부 문자만 치환 | 카드 번호, 고정 형식 날짜
REGEXP | 정규식 패턴 치환 | 주민번호, 전화번호, 이메일
RANDOM | 같은 형식의 임의 값 | 시험 데이터 노출
NULLIFY | NULL | 값 존재 자체를 숨길 때
@END
@B expression에는 SYS_CONTEXT로 읽는 세션 정보를 쓴다. 19.3에서 일반 사용자 함수를 넣으면 ORA-28088(unsupported PL/SQL function)로 거부됐다(원 교안 8장 실습 03). 역할 기반 조건 `SYS_CONTEXT('SYS_SESSION_ROLES', '역할') = 'FALSE'`는 SET ROLE로 역할이 꺼지면 바로 리댁션 대상이 됨.
@B FULL 리댁션의 숫자 0, 날짜 0001-01-01 같은 값은 REDACTION_VALUES_FOR_TYPE_FULL 뷰에 있다. UPDATE_FULL_REDACTION_VALUES로 바꿀 수 있지만 DB 전체 정책에 한꺼번에 적용된다.
@B 정책은 DISABLE_POLICY·ENABLE_POLICY로 끄고 켤 수 있다. 꺼진 동안의 조회는 원래 값을 돌려주므로, 정책 변경 호출을 감사 대상으로 둔다.
@B 리댁션은 조회 결과에만 작용한다. UPDATE·DELETE 권한이 있는 사용자는 가려진 값을 가진 행을 조건으로 찾아 그대로 바꿀 수 있다. 쓰기 권한은 리댁션과 별개로 최소화한다.
@B 리댁션된 컬럼을 CREATE TABLE AS SELECT나 INSERT ... SELECT로 옮기면 ORA-28081로 거부된다. 원래 값이 가려지지 않은 채 다른 테이블로 새는 것을 막는 장치다.
@B DBMS_REDACT는 PUBLIC에 실행 권한이 없다. 정책 관리자에게 EXECUTE를 따로 주고, 딕셔너리 뷰(REDACTION_COLUMNS 등)를 보려면 SELECT_CATALOG_ROLE 같은 조회 권한도 필요하다.
@NOTE 면제 경로
SYS와 EXEMPT REDACTION POLICY 보유자에게는 리댁션이 적용되지 않는다. 19c 기본 상태에서 이 권한은 EXP_FULL_DATABASE 역할에 들어 있어 Data Pump 내보내기 계정은 원래 값을 덤프에 담는다. 이 역할 부여 현황을 함께 점검한다.
@END

@H3 06.2  진행 순서
@TBL
단계 | 하는 일 | 확인할 것
[1] 준비 — 고객 테이블과 계정 | 소유자·정책 관리자·응용·급여 담당 계정, 역할, 고객 3행 | D06_PAY에 D06_PAYROLL 기본 역할
[2] 실행 권한과 첫 정책 | 권한 없이 ADD_POLICY, EXECUTE 부여 후 재시도 | PLS-00201 후 성공
[3] 컬럼 추가 — REGEXP·PARTIAL | SSN·PHONE·EMAIL은 REGEXP, CARD_NO·JOIN_DATE는 PARTIAL로 추가 | 딕셔너리 조회 ORA-00942 후 6개 컬럼
[4] 급여만 따로 — 이름 붙은 정책 식 | 역할 기반 정책 식 생성, SALARY 컬럼에 적용 | REDACTION_EXPRESSIONS에 식 1개
[5] 사용자별 결과 | D06_APP, D06_PAY 조회, SET ROLE NONE 후 재조회 | 급여만 차이, 역할을 끄면 0
[6] 리댁션의 한계 | 급여 조건 검색, 급여 정렬, CTAS | 조건·정렬은 실제 값, CTAS는 ORA-28081
[7] 면제 권한과 점검 | EXEMPT REDACTION POLICY 부여·회수, 권한 보유자 조회 | 면제 시 원래 값, 기본 보유자 EXP_FULL_DATABASE
[8] 정리와 확인 | 정책·정책 식·사용자·역할 삭제 | 정책 0, 정책 식 0, 사용자 0
@END

@H3 06.3  실습 스크립트

@P [1] 준비 — 고객 테이블과 계정
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d06_own IDENTIFIED BY d06_own QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d06_sec IDENTIFIED BY d06_sec;

User created.

SYS@orcl> CREATE USER d06_app IDENTIFIED BY d06_app QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d06_pay IDENTIFIED BY d06_pay;

User created.

SYS@orcl> CREATE ROLE d06_payroll;

Role created.

SYS@orcl> GRANT CREATE SESSION TO d06_own, d06_sec, d06_app, d06_pay;

Grant succeeded.

SYS@orcl> GRANT CREATE TABLE TO d06_app;

Grant succeeded.

SYS@orcl> GRANT d06_payroll TO d06_pay;

Grant succeeded.

SYS@orcl> CREATE TABLE d06_own.customers (
  2    id        NUMBER PRIMARY KEY,
  3    name      VARCHAR2(20),
  4    ssn       VARCHAR2(14),
  5    phone     VARCHAR2(13),
  6    email     VARCHAR2(40),
  7    card_no   VARCHAR2(19),
  8    salary    NUMBER,
  9    join_date DATE);

Table created.

SYS@orcl> INSERT INTO d06_own.customers VALUES (1, 'Kim', '900101-1234567', '010-1111-2222', 'kim.minsu@itwill.co.kr', '4518-1234-5678-9012', 5200, DATE '2019-03-02');

1 row created.

SYS@orcl> INSERT INTO d06_own.customers VALUES (2, 'Lee', '850515-2345678', '010-3333-4444', 'lee@example.com', '5321-9876-5432-1098', 7400, DATE '2016-07-15');

1 row created.

SYS@orcl> INSERT INTO d06_own.customers VALUES (3, 'Park', '920303-1567890', '010-5555-6666', 'park.j@itwill.co.kr', '3714-4963-5398-4310', 9100, DATE '2021-11-30');

1 row created.

SYS@orcl> COMMIT;

Commit complete.

SYS@orcl> GRANT SELECT ON d06_own.customers TO d06_app, d06_pay;

Grant succeeded.

-- ★ 정책 관리자 D06_SEC에는 데이터 객체 권한이 없다. 리댁션 정책은 대상 테이블 SELECT 권한 없이 만들 수 있다.
@END

@P [2] 실행 권한과 첫 정책
@CODE
SQL> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> BEGIN
  2    DBMS_REDACT.ADD_POLICY(
  3      object_schema => 'D06_OWN',
  4      object_name   => 'CUSTOMERS',
  5      policy_name   => 'D06_CUST_RED',
  6      column_name   => 'SALARY',
  7      function_type => DBMS_REDACT.FULL,
  8      expression    => '1=1');
  9  END;
 10  /
    function_type => DBMS_REDACT.FULL,
                     *
ERROR at line 7:
ORA-06550: line 7, column 22:
PLS-00201: identifier 'DBMS_REDACT' must be declared
ORA-06550: line 2, column 3:
PL/SQL: Statement ignored


D06_SEC@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> GRANT EXECUTE ON DBMS_REDACT TO d06_sec;

Grant succeeded.

SYS@orcl> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> BEGIN
  2    DBMS_REDACT.ADD_POLICY(
  3      object_schema => 'D06_OWN',
  4      object_name   => 'CUSTOMERS',
  5      policy_name   => 'D06_CUST_RED',
  6      column_name   => 'SALARY',
  7      function_type => DBMS_REDACT.FULL,
  8      expression    => '1=1');
  9  END;
 10  /

PL/SQL procedure successfully completed.

-- ★ DBMS_REDACT는 PUBLIC 실행 권한이 없어 PLS-00201로 실패했다. EXECUTE ON DBMS_REDACT만 주자 다른 스키마 테이블에 정책이 만들어졌다.
--    expression '1=1'은 면제 사용자를 뺀 모든 세션에 리댁션을 적용한다.
@END

@P [3] 컬럼 추가 — REGEXP·PARTIAL
@CODE
SQL> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> BEGIN
  2    DBMS_REDACT.ALTER_POLICY(
  3      object_schema         => 'D06_OWN',
  4      object_name           => 'CUSTOMERS',
  5      policy_name           => 'D06_CUST_RED',
  6      action                => DBMS_REDACT.ADD_COLUMN,
  7      column_name           => 'SSN',
  8      function_type         => DBMS_REDACT.REGEXP,
  9      regexp_pattern        => '([0-9]{6})-([0-9])([0-9]{6})',
 10      regexp_replace_string => '\1-\2******');
 11    DBMS_REDACT.ALTER_POLICY(
 12      object_schema         => 'D06_OWN',
 13      object_name           => 'CUSTOMERS',
 14      policy_name           => 'D06_CUST_RED',
 15      action                => DBMS_REDACT.ADD_COLUMN,
 16      column_name           => 'PHONE',
 17      function_type         => DBMS_REDACT.REGEXP,
 18      regexp_pattern        => '([0-9]{3})-([0-9]{4})-([0-9]{4})',
 19      regexp_replace_string => '\1-****-\3');
 20    DBMS_REDACT.ALTER_POLICY(
 21      object_schema         => 'D06_OWN',
 22      object_name           => 'CUSTOMERS',
 23      policy_name           => 'D06_CUST_RED',
 24      action                => DBMS_REDACT.ADD_COLUMN,
 25      column_name           => 'EMAIL',
 26      function_type         => DBMS_REDACT.REGEXP,
 27      regexp_pattern        => DBMS_REDACT.RE_PATTERN_EMAIL_ADDRESS,
 28      regexp_replace_string => DBMS_REDACT.RE_REDACT_EMAIL_NAME);
 29    DBMS_REDACT.ALTER_POLICY(
 30      object_schema       => 'D06_OWN',
 31      object_name         => 'CUSTOMERS',
 32      policy_name         => 'D06_CUST_RED',
 33      action              => DBMS_REDACT.ADD_COLUMN,
 34      column_name         => 'CARD_NO',
 35      function_type       => DBMS_REDACT.PARTIAL,
 36      function_parameters => DBMS_REDACT.REDACT_CCN16_F12);
 37    DBMS_REDACT.ALTER_POLICY(
 38      object_schema       => 'D06_OWN',
 39      object_name         => 'CUSTOMERS',
 40      policy_name         => 'D06_CUST_RED',
 41      action              => DBMS_REDACT.ADD_COLUMN,
 42      column_name         => 'JOIN_DATE',
 43      function_type       => DBMS_REDACT.PARTIAL,
 44      function_parameters => 'm1d1Y');
 45  END;
 46  /

PL/SQL procedure successfully completed.

D06_SEC@orcl> COL column_name FOR a10
D06_SEC@orcl> COL function_type FOR a22
D06_SEC@orcl> COL function_parameters FOR a40
D06_SEC@orcl> SELECT column_name, function_type, function_parameters FROM redaction_columns
  2   WHERE object_owner = 'D06_OWN' ORDER BY column_name;
SELECT column_name, function_type, function_parameters FROM redaction_columns
                                                            *
ERROR at line 1:
ORA-00942: table or view does not exist


D06_SEC@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> GRANT SELECT_CATALOG_ROLE TO d06_sec;

Grant succeeded.

SYS@orcl> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> COL column_name FOR a10
D06_SEC@orcl> COL function_type FOR a22
D06_SEC@orcl> COL function_parameters FOR a40
D06_SEC@orcl> SELECT column_name, function_type, function_parameters FROM redaction_columns
  2   WHERE object_owner = 'D06_OWN' ORDER BY column_name;

COLUMN_NAM FUNCTION_TYPE          FUNCTION_PARAMETERS
---------- ---------------------- ----------------------------------------
CARD_NO    PARTIAL REDACTION      VVVVFVVVVFVVVVFVVVV,VVVV-VVVV-VVVV-VVVV,
                                  *,1,12

EMAIL      REGEXP REDACTION
JOIN_DATE  PARTIAL REDACTION      m1d1Y
PHONE      REGEXP REDACTION
SALARY     FULL REDACTION
SSN        REGEXP REDACTION

6 rows selected.

-- ★ REDACTION_COLUMNS 조회가 ORA-00942였다. 정책을 만드는 권한과 딕셔너리를 보는 권한은 별개다. SELECT_CATALOG_ROLE을 준 뒤 보였다.
--    CARD_NO에 쓴 REDACT_CCN16_F12는 '입력 형식,출력 형식,치환 문자,시작,끝' 다섯 항목 문자열 상수다.
--    REGEXP 컬럼은 FUNCTION_PARAMETERS가 비고, 패턴은 REGEXP_PATTERN 컬럼에 따로 저장된다.
@END

@P [4] 급여만 따로 — 이름 붙은 정책 식
@CODE
SQL> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> BEGIN
  2    DBMS_REDACT.CREATE_POLICY_EXPRESSION(
  3      policy_expression_name        => 'D06_NOT_PAYROLL',
  4      expression                    => 'SYS_CONTEXT(''SYS_SESSION_ROLES'', ''D06_PAYROLL'') = ''FALSE''',
  5      policy_expression_description => 'D06_PAYROLL role holders see salary');
  6    DBMS_REDACT.APPLY_POLICY_EXPR_TO_COL(
  7      object_schema          => 'D06_OWN',
  8      object_name            => 'CUSTOMERS',
  9      column_name            => 'SALARY',
 10      policy_expression_name => 'D06_NOT_PAYROLL');
 11  END;
 12  /

PL/SQL procedure successfully completed.

D06_SEC@orcl> COL policy_expression_name FOR a16
D06_SEC@orcl> COL expression FOR a60
D06_SEC@orcl> SELECT policy_expression_name, expression FROM redaction_expressions WHERE policy_expression_name LIKE 'D06%';

POLICY_EXPRESSIO EXPRESSION
---------------- ------------------------------------------------------------
D06_NOT_PAYROLL  SYS_CONTEXT('SYS_SESSION_ROLES', 'D06_PAYROLL') = 'FALSE'

1 row selected.

-- ★ SALARY만 정책 식 D06_NOT_PAYROLL을 따르고, 나머지 컬럼은 정책 기본 식 1=1을 그대로 따른다.
--    19.3에서는 EXECUTE ON DBMS_REDACT만으로 정책 식이 만들어졌다. 최신 RU(19.32 이후) 문서는 정책 식 서브프로그램에 CREATE ANY TABLE을 추가로 요구한다.
@END

@P [5] 사용자별 결과
@CODE
SQL> CONNECT d06_app/d06_app
Connected.
D06_APP@orcl> ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

Session altered.

D06_APP@orcl> COL name FOR a8
D06_APP@orcl> COL ssn FOR a14
D06_APP@orcl> COL phone FOR a13
D06_APP@orcl> COL email FOR a22
D06_APP@orcl> COL card_no FOR a19
D06_APP@orcl> SELECT name, ssn, phone, email, card_no, salary, join_date FROM d06_own.customers ORDER BY id;

NAME     SSN            PHONE         EMAIL                  CARD_NO                 SALARY JOIN_DATE
-------- -------------- ------------- ---------------------- ------------------- ---------- ----------
Kim      900101-1****** 010-****-2222 xxxx@itwill.co.kr      ****-****-****-9012          0 2019-01-01
Lee      850515-2****** 010-****-4444 xxxx@example.com       ****-****-****-1098          0 2016-01-01
Park     920303-1****** 010-****-6666 xxxx@itwill.co.kr      ****-****-****-4310          0 2021-01-01

3 rows selected.

D06_APP@orcl> CONNECT d06_pay/d06_pay
Connected.
D06_PAY@orcl> ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

Session altered.

D06_PAY@orcl> COL name FOR a8
D06_PAY@orcl> COL ssn FOR a14
D06_PAY@orcl> COL phone FOR a13
D06_PAY@orcl> COL email FOR a22
D06_PAY@orcl> COL card_no FOR a19
D06_PAY@orcl> SELECT name, ssn, phone, email, card_no, salary, join_date FROM d06_own.customers ORDER BY id;

NAME     SSN            PHONE         EMAIL                  CARD_NO                 SALARY JOIN_DATE
-------- -------------- ------------- ---------------------- ------------------- ---------- ----------
Kim      900101-1****** 010-****-2222 xxxx@itwill.co.kr      ****-****-****-9012       5200 2019-01-01
Lee      850515-2****** 010-****-4444 xxxx@example.com       ****-****-****-1098       7400 2016-01-01
Park     920303-1****** 010-****-6666 xxxx@itwill.co.kr      ****-****-****-4310       9100 2021-01-01

3 rows selected.

D06_PAY@orcl> SET ROLE NONE;

Role set.

D06_PAY@orcl> SELECT name, salary FROM d06_own.customers ORDER BY id;

NAME         SALARY
-------- ----------
Kim               0
Lee               0
Park              0

3 rows selected.

-- ★ 두 사용자 모두 주민번호 뒷자리, 전화 가운데 자리, 이메일 이름, 카드 앞 12자리가 가려졌다. 입사일은 연도만 남고 1월 1일이 됐다.
--    급여는 D06_PAY에게만 보였다. 같은 세션에서 SET ROLE NONE을 하자 바로 0으로 바뀌었다. 역할 조건은 문장 실행 때마다 평가된다.
@END

@P [6] 리댁션의 한계
@CODE
SQL> CONNECT d06_app/d06_app
Connected.
D06_APP@orcl> SELECT name, salary FROM d06_own.customers WHERE salary > 7000 ORDER BY id;

NAME                     SALARY
-------------------- ----------
Lee                           0
Park                          0

2 rows selected.

D06_APP@orcl> SELECT name FROM d06_own.customers ORDER BY salary DESC;

NAME
--------------------
Park
Lee
Kim

3 rows selected.

D06_APP@orcl> CREATE TABLE cust_copy AS SELECT * FROM d06_own.customers;
CREATE TABLE cust_copy AS SELECT * FROM d06_own.customers
                                 *
ERROR at line 1:
ORA-28081: Insufficient privileges - the command references a redacted object.


D06_APP@orcl> CREATE TABLE cust_copy AS SELECT id, name FROM d06_own.customers;

Table created.

D06_APP@orcl> SELECT COUNT(*) FROM cust_copy;

  COUNT(*)
----------
         3

1 row selected.

-- ★ 급여가 0으로 보이는데도 salary > 7000 조건이 Lee, Park 두 행을 정확히 골랐다. ORDER BY salary DESC도 실제 급여 순서(Park, Lee, Kim)다.
--    전체 컬럼 CTAS는 ORA-28081로 막혔다. 리댁션 컬럼을 뺀 CTAS는 성공했다.
--    가려진 값을 추론으로 알아내는 것을 막아야 하면 리댁션 대신 VPD 컬럼 정책이나 권한 회수가 필요하다.
@END

@P [7] 면제 권한과 점검
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> GRANT EXEMPT REDACTION POLICY TO d06_app;

Grant succeeded.

SYS@orcl> CONNECT d06_app/d06_app
Connected.
D06_APP@orcl> COL ssn FOR a14
D06_APP@orcl> SELECT name, ssn, salary FROM d06_own.customers ORDER BY id;

NAME                 SSN                SALARY
-------------------- -------------- ----------
Kim                  900101-1234567       5200
Lee                  850515-2345678       7400
Park                 920303-1567890       9100

3 rows selected.

D06_APP@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> REVOKE EXEMPT REDACTION POLICY FROM d06_app;

Revoke succeeded.

SYS@orcl> COL grantee FOR a24
SYS@orcl> COL privilege FOR a24
SYS@orcl> SELECT grantee, privilege FROM dba_sys_privs WHERE privilege = 'EXEMPT REDACTION POLICY' ORDER BY 1;

GRANTEE                  PRIVILEGE
------------------------ ------------------------
EXP_FULL_DATABASE        EXEMPT REDACTION POLICY

1 row selected.

SYS@orcl> COL policy_name FOR a14
SYS@orcl> COL expression FOR a10
SYS@orcl> SELECT object_name, policy_name, expression, enable FROM redaction_policies WHERE object_owner = 'D06_OWN';

OBJECT_NAME
------------------------------------------------------------------------------------------------------------------------
POLICY_NAME    EXPRESSION ENA
-------------- ---------- ---
CUSTOMERS
D06_CUST_RED   1=1        YES


1 row selected.

-- ★ 면제 권한을 받자 정책은 그대로인데 원래 값이 모두 보였다. 정책 수정 없이 권한 하나로 우회된다.
--    기본 상태에서 이 권한을 가진 것은 EXP_FULL_DATABASE 역할 하나다. 내보내기 계정 관리가 곧 리댁션 관리다.
@END

@P [8] 정리와 확인
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_REDACT.DROP_POLICY('D06_OWN', 'CUSTOMERS', 'D06_CUST_RED');
  3    DBMS_REDACT.DROP_POLICY_EXPRESSION('D06_NOT_PAYROLL');
  4  END;
  5  /

PL/SQL procedure successfully completed.

SYS@orcl> DROP USER d06_app CASCADE;

User dropped.

SYS@orcl> DROP USER d06_pay CASCADE;

User dropped.

SYS@orcl> DROP USER d06_sec CASCADE;

User dropped.

SYS@orcl> DROP USER d06_own CASCADE;

User dropped.

SYS@orcl> DROP ROLE d06_payroll;

Role dropped.

SYS@orcl> SELECT COUNT(*) FROM redaction_policies;

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM redaction_expressions;

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'D06%';

  COUNT(*)
----------
         0

1 row selected.

-- ★ 정책 식은 정책을 지운 뒤 따로 DROP_POLICY_EXPRESSION 한다. 특정 스키마에 속하지 않아 DROP USER로 지워지지 않는다.
@END

@H3 06.4  정리와 확인 포인트
@B 리댁션은 출력만 바꾼다. WHERE·ORDER BY는 실제 값으로 동작해 반복 질의로 값을 추론할 수 있다.
@B 컬럼마다 다른 조건은 이름 붙은 정책 식으로 준다. 역할 조건은 SET ROLE에 즉시 반응한다.
@B CTAS·INSERT SELECT로 리댁션 컬럼을 옮기면 ORA-28081이 난다. 응용 배치가 이 오류로 멈추지 않는지 반영 전에 점검한다.
@B 정책 관리자에게는 EXECUTE ON DBMS_REDACT와 딕셔너리 조회 권한을 함께 준다.
@B EXEMPT REDACTION POLICY와 EXP_FULL_DATABASE 보유자는 리댁션 밖에 있다. 정기 권한 점검 목록에 넣는다.
