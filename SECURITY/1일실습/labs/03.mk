@H2 실습 03  Secure Application Role로 역할 활성화 통제
@TBL
항목 | 내용
목표 | 지정한 PL/SQL 프로시저 안에서만 켜지는 응용 역할을 만들고, 정의자·호출자 권한 차이와 활성화 조건의 강도를 실측으로 비교한다
소요 | 30분
접속 | SYS, D03_SEC(검사 로직 소유자), D03_USER(업무 사용자, 로컬·TCP 두 경로)
변경 | 사용자 D03_SEC·D03_USER, 역할 D03_HR_ROLE(HR.EMPLOYEES 조회). 마지막 단계에서 모두 지움
@END

@H3 03.1  실습 전에 — 역할을 켜는 조건을 코드로 고정한다
@B `IDENTIFIED BY` 비밀번호 역할은 비밀번호를 아는 사람이면 어느 도구에서든 켤 수 있다. 응용 프로그램 안에 박힌 역할 비밀번호는 결국 새어 나간다.
@B Secure Application Role은 `CREATE ROLE r IDENTIFIED USING schema.proc`로 만든다. 지정한 프로시저 안에서 `DBMS_SESSION.SET_ROLE`을 부를 때만 켜진다.
@B 직접 `SET ROLE r`을 하면 ORA-28201이 난다.
@B 활성화 프로시저는 호출자 권한(`AUTHID CURRENT_USER`)이어야 한다. 정의자 권한 코드 안에서는 역할을 바꿀 수 없어서 ORA-06565가 난다. 역할은 호출한 세션의 것이기 때문이다.
@B 프로시저가 검사하는 재료는 대부분 `SYS_CONTEXT('USERENV', ...)`다. IP_ADDRESS, MODULE, PROXY_USER, AUTHENTICATION_METHOD, OS_USER, 응용 컨텍스트 값을 쓴다.
@B 재료마다 신뢰도가 다르다.
@B MODULE·CLIENT_INFO·CLIENT_IDENTIFIER는 클라이언트가 `DBMS_APPLICATION_INFO`나 드라이버 속성으로 마음대로 정한다. 단독 조건으로는 약하다.
@B IP_ADDRESS는 서버가 네트워크 연결에서 기록하는 값이다. bequeath 로컬 접속에서는 NULL이다(실습 [6]).
@B PROXY_USER, 인증 방식, 전역 응용 컨텍스트처럼 서버 쪽에서 정해지는 값과 묶으면 강해진다.
@B 부여된 응용 역할은 기본 역할이 아니다(`DBA_ROLE_PRIVS.DEFAULT_ROLE = NO`). 로그인 때 자동으로 켜지지 않는다.
@B 역할을 만든 계정(여기서는 SYS)에게도 역할이 부여된다. 정의는 `DBA_APPLICATION_ROLES`에서 SCHEMA·PACKAGE로 확인한다.
@B 통제의 실체는 프로시저 코드다. 이 프로시저를 고칠 수 있는 계정(소유자, CREATE ANY PROCEDURE 보유자)의 관리가 역할 자체만큼 중요하다.
@B `DBMS_SESSION.SET_ROLE`은 SET ROLE 문과 같다. 세션의 활성 역할을 통째로 바꾸므로, 이미 켜진 역할을 유지하려면 `'r1, r2'`처럼 함께 적는다.
@B 반영 시점이 다르다. 객체·시스템 권한 부여와 회수는 열린 세션에 즉시 반영된다. 역할 부여와 회수는 SET ROLE을 다시 하거나 새 세션을 열어야 반영된다(교안 3장).
@B 활성화 시도 자체를 남기려면 `ACTIONS EXECUTE ON d03_sec.enable_hr` 통합 감사 정책을 건다.(문서 기준, 실습에서는 측정하지 않음).
@CASE 보고 도구에서만 급여 조회 허용
급여 테이블 조회 역할을 응용 역할로 만들었다. 프로시저는 접속 IP가 응용 서버 대역이고 PROXY_USER가 풀 계정일 때만 역할을 켠다. 같은 사용자가 개인 PC의 SQL Developer로 접속하면 IP와 PROXY_USER 조건이 맞지 않아 역할이 켜지지 않는다. 실패는 RAISE_APPLICATION_ERROR 메시지로 남기고, 통합 감사로 EXECUTE를 기록한다.
@END

@H3 03.2  진행 순서
@TBL
단계 | 주제 | 하는 일 | 확인할 것
[1] | 준비 | 검사 소유자·업무 사용자, IDENTIFIED USING 역할 | DBA_APPLICATION_ROLES, DEFAULT_ROLE
[2] | 정의자 권한 프로시저 | AUTHID DEFINER로 생성 | 컴파일은 성공
[3] | 활성화 시도 | 직접 SET ROLE, 조건 불일치, 조건 일치 | ORA-28201, ORA-20001, ORA-06565
[4] | 호출자 권한으로 재작성 | AUTHID CURRENT_USER | VALID
[5] | 활성화 성공 | MODULE 설정 후 호출 | SESSION_ROLES, 107건
[6] | 조건 강화 | MODULE + IP_ADDRESS | 로컬은 거부, TCP는 허용
[7] | 원복 | 사용자·역할 삭제 | 0건
@END

@H3 03.3  실습 스크립트

@P [1] 계정과 응용 역할 준비
@CODE
-- ★ 역할이 가리키는 D03_SEC.ENABLE_HR 은 아직 없다. 역할 생성 시점에는 프로시저 존재를 검사하지 않는다.
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d03_sec IDENTIFIED BY Sec2026x;

User created.

SYS@orcl> GRANT CREATE SESSION, CREATE PROCEDURE TO d03_sec;

Grant succeeded.

SYS@orcl> CREATE USER d03_user IDENTIFIED BY User2026x;

User created.

SYS@orcl> GRANT CREATE SESSION TO d03_user;

Grant succeeded.

SYS@orcl> CREATE ROLE d03_hr_role IDENTIFIED USING d03_sec.enable_hr;

Role created.

SYS@orcl> GRANT SELECT ON hr.employees TO d03_hr_role;

Grant succeeded.

SYS@orcl> GRANT d03_hr_role TO d03_user;

Grant succeeded.

SYS@orcl> COL role FOR a12
SYS@orcl> COL schema FOR a8
SYS@orcl> COL package FOR a10
SYS@orcl> SELECT role, schema, package FROM dba_application_roles WHERE role = 'D03_HR_ROLE';

ROLE         SCHEMA   PACKAGE
------------ -------- ----------
D03_HR_ROLE  D03_SEC  ENABLE_HR

1 row selected.

SYS@orcl> COL grantee FOR a10
SYS@orcl> COL granted_role FOR a12
SYS@orcl> SELECT grantee, granted_role, default_role FROM dba_role_privs WHERE granted_role = 'D03_HR_ROLE';

GRANTEE    GRANTED_ROLE DEF
---------- ------------ ---
SYS        D03_HR_ROLE  NO
D03_USER   D03_HR_ROLE  NO

2 rows selected.
-- ★ 역할 부여 행이 두 개다. 역할을 만든 SYS 에게도 자동으로 부여됐다.
-- ★ 두 행 모두 DEFAULT_ROLE 이 NO 다. 응용 역할은 로그인 때 켜지지 않는다.
@END

@P [2] 정의자 권한으로 만든 활성화 프로시저
@CODE
-- ★ 일부러 정의자 권한으로 만든다. 컴파일 오류는 나지 않는다.
SQL> CONNECT d03_sec/Sec2026x
Connected.
D03_SEC@orcl> CREATE OR REPLACE PROCEDURE enable_hr
  2  AUTHID DEFINER
  3  AS
  4  BEGIN
  5    IF SYS_CONTEXT('USERENV', 'MODULE') = 'D03_HRAPP' THEN
  6      DBMS_SESSION.SET_ROLE('d03_hr_role');
  7    ELSE
  8      RAISE_APPLICATION_ERROR(-20001,
  9        'module ' || SYS_CONTEXT('USERENV', 'MODULE') || ' is not allowed');
 10    END IF;
 11  END;
 12  /

Procedure created.

D03_SEC@orcl> GRANT EXECUTE ON enable_hr TO d03_user;

Grant succeeded.
@END

@P [3] 역할을 켜려는 시도들
@CODE
SQL> CONNECT d03_user/User2026x
Connected.
D03_USER@orcl> SELECT COUNT(*) FROM hr.employees;
SELECT COUNT(*) FROM hr.employees
                        *
ERROR at line 1:
ORA-00942: table or view does not exist


D03_USER@orcl> SET ROLE d03_hr_role;
SET ROLE d03_hr_role
*
ERROR at line 1:
ORA-28201: invalid command to enable secure application role 'D03_HR_ROLE'


D03_USER@orcl> EXEC d03_sec.enable_hr
BEGIN d03_sec.enable_hr; END;

*
ERROR at line 1:
ORA-20001: module SQL*Plus is not allowed
ORA-06512: at "D03_SEC.ENABLE_HR", line 8
ORA-06512: at line 1


D03_USER@orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('D03_HRAPP', NULL)

PL/SQL procedure successfully completed.

D03_USER@orcl> EXEC d03_sec.enable_hr
BEGIN d03_sec.enable_hr; END;

*
ERROR at line 1:
ORA-06565: cannot execute SET ROLE from within stored procedure
ORA-06512: at "SYS.DBMS_SESSION", line 183
ORA-06512: at "D03_SEC.ENABLE_HR", line 6
ORA-06512: at line 1
-- ★ 직접 SET ROLE 은 ORA-28201로 거부된다.
-- ★ MODULE 기본값은 'SQL*Plus' 라서 프로시저가 ORA-20001을 던진다.
-- ★ MODULE 을 맞추면 조건은 통과하지만 정의자 권한이라 ORA-06565가 난다. 오류 스택의 DBMS_SESSION 줄이 SET_ROLE 지점이다.
@END

@P [4] AUTHID CURRENT_USER 로 다시 만들기
@CODE
SQL> CONNECT d03_sec/Sec2026x
Connected.
D03_SEC@orcl> CREATE OR REPLACE PROCEDURE enable_hr
  2  AUTHID CURRENT_USER
  3  AS
  4  BEGIN
  5    IF SYS_CONTEXT('USERENV', 'MODULE') = 'D03_HRAPP' THEN
  6      DBMS_SESSION.SET_ROLE('d03_hr_role');
  7    ELSE
  8      RAISE_APPLICATION_ERROR(-20001,
  9        'module ' || SYS_CONTEXT('USERENV', 'MODULE') || ' is not allowed');
 10    END IF;
 11  END;
 12  /

Procedure created.

D03_SEC@orcl> COL object_name FOR a12
D03_SEC@orcl> SELECT object_name, status FROM user_objects WHERE object_name = 'ENABLE_HR';

OBJECT_NAME  STATUS
------------ -------
ENABLE_HR    VALID

1 row selected.
-- ★ AUTHID 한 단어만 바뀌었다.
@END

@P [5] 조건을 맞춘 활성화
@CODE
SQL> CONNECT d03_user/User2026x
Connected.
D03_USER@orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('D03_HRAPP', NULL)

PL/SQL procedure successfully completed.

D03_USER@orcl> EXEC d03_sec.enable_hr

PL/SQL procedure successfully completed.

D03_USER@orcl> COL role FOR a12
D03_USER@orcl> SELECT role FROM session_roles;

ROLE
------------
D03_HR_ROLE

1 row selected.

D03_USER@orcl> SELECT COUNT(*) FROM hr.employees;

  COUNT(*)
----------
       107

1 row selected.
-- ★ 역할이 켜지고 HR.EMPLOYEES 107건이 조회된다.
-- ★ 다만 MODULE 은 사용자가 직접 정한 값이다. 이 조건은 사실상 아무나 통과한다.
@END

@P [6] MODULE 만으로는 약하다 — 접속 주소 추가
@CODE
-- ★ 조건에 IP_ADDRESS 를 더한다. 서버가 기록하는 값이라 클라이언트가 바꿀 수 없다.
SQL> CONNECT d03_sec/Sec2026x
Connected.
D03_SEC@orcl> CREATE OR REPLACE PROCEDURE enable_hr
  2  AUTHID CURRENT_USER
  3  AS
  4    v_ip VARCHAR2(40) := SYS_CONTEXT('USERENV', 'IP_ADDRESS');
  5  BEGIN
  6    IF SYS_CONTEXT('USERENV', 'MODULE') = 'D03_HRAPP'
  7       AND v_ip = '172.16.225.50' THEN
  8      DBMS_SESSION.SET_ROLE('d03_hr_role');
  9    ELSE
 10      RAISE_APPLICATION_ERROR(-20001,
 11        'denied: module=' || SYS_CONTEXT('USERENV', 'MODULE') || ', ip=' || NVL(v_ip, '(none)'));
 12    END IF;
 13  END;
 14  /

Procedure created.

D03_SEC@orcl> CONNECT d03_user/User2026x
Connected.
D03_USER@orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('D03_HRAPP', NULL)

PL/SQL procedure successfully completed.

D03_USER@orcl> EXEC d03_sec.enable_hr
BEGIN d03_sec.enable_hr; END;

*
ERROR at line 1:
ORA-20001: denied: module=D03_HRAPP, ip=(none)
ORA-06512: at "D03_SEC.ENABLE_HR", line 10
ORA-06512: at line 1


D03_USER@orcl> CONNECT d03_user/User2026x@//172.16.225.50:1521/orcl
Connected.
D03_USER@//172.16.225.50:1521/orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('D03_HRAPP', NULL)

PL/SQL procedure successfully completed.

D03_USER@//172.16.225.50:1521/orcl> EXEC d03_sec.enable_hr

PL/SQL procedure successfully completed.

D03_USER@//172.16.225.50:1521/orcl> COL role FOR a12
D03_USER@//172.16.225.50:1521/orcl> SELECT role FROM session_roles;

ROLE
------------
D03_HR_ROLE

1 row selected.
-- ★ bequeath 로컬 접속은 IP_ADDRESS 가 NULL 이라 거부된다.
-- ★ 리스너를 거친 TCP 접속은 172.16.225.50 으로 기록돼 역할이 켜진다.
@END

@P [7] 원복
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> DROP USER d03_user CASCADE;

User dropped.

SYS@orcl> DROP USER d03_sec CASCADE;

User dropped.

SYS@orcl> DROP ROLE d03_hr_role;

Role dropped.

SYS@orcl> SELECT COUNT(*) AS d03_users FROM dba_users WHERE username LIKE 'D03%';

 D03_USERS
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) AS d03_roles FROM dba_roles WHERE role LIKE 'D03%';

 D03_ROLES
----------
         0

1 row selected.
-- ★ 역할을 지우면 부여 관계도 함께 사라진다.
@END

@H3 03.4  정리와 확인 포인트
@B 응용 역할의 세 가지 오류를 구분한다. 직접 SET ROLE은 ORA-28201, 정의자 권한 프로시저는 ORA-06565, 조건 불일치는 프로시저가 정한 사용자 오류다.
@B 활성화 조건에는 클라이언트가 정하는 값과 서버가 정하는 값을 섞는다. MODULE 단독 조건은 문서상 통제일 뿐이다.
@B 응용 역할은 기본 역할이 아니므로, 응용 프로그램이 접속 직후 활성화 프로시저를 부르는 흐름을 표준으로 둔다.
@B 역할 생성자에게 남는 부여(SYS 행)는 필요 없으면 회수한다.
@B 프로시저 소유 스키마에는 접속 권한을 최소화하고 코드 변경을 감사한다.
