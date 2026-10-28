@H2 실습 02  프록시 인증과 실제 사용자 추적
@TBL
항목 | 내용
목표 | 중간 계정이 대상 사용자 세션을 대신 여는 프록시 인증을 구성하고, WITH ROLE 로 권한을 줄인 결과와 통합 감사의 실제 사용자 기록을 확인한다
소요 | 30분
접속 | SYS, D02_APP[D02_CLERK] 프록시 세션, D02_CLERK 직접 세션
변경 | 사용자 D02_OWNER·D02_APP·D02_CLERK, 역할 D02_R_READ·D02_R_WRITE, 감사 정책 D02_POL. 마지막 단계에서 모두 지움
@END

@H3 02.1  실습 전에 — 한 계정의 인증으로 다른 사용자의 세션을 연다
@B 응용 서버는 커넥션 풀 계정 하나로 접속한다. 그래도 권한 판정과 감사는 실제 업무 사용자 기준이어야 한다.
@B 프록시 인증에서는 중간 계정(D02_APP)이 자기 비밀번호로 인증한 뒤 대상 사용자(D02_CLERK)의 세션을 연다. 응용 서버는 대상 사용자의 비밀번호를 몰라도 된다.
@B 허용은 대상 사용자 쪽 속성이다.
@CODE
ALTER USER client GRANT CONNECT THROUGH proxy
  [WITH ROLE r1, r2 | WITH ROLE ALL EXCEPT r3 | WITH NO ROLES]
  [AUTHENTICATION REQUIRED];
@END
@B 확인은 `PROXY_USERS`(허용 관계와 FLAGS), `PROXY_ROLES`(WITH ROLE 목록)로 한다.
@B 허용 없이 `proxy[client]`로 접속하면 19.3에서는 ORA-28150이 아니라 ORA-01017이 난다(교안 1·2장 실측). 비밀번호 오류와 구분되지 않으므로 진단은 `PROXY_USERS` 조회가 먼저다.
@B WITH ROLE은 세션에서 켤 수 있는 역할만 제한한다. 나머지 역할을 `SET ROLE`로 켜려 하면 ORA-01924가 난다. 대상 사용자가 직접 받은 시스템·객체 권한은 그대로 남는다(Security Guide 프록시 계정 지침).
@B 세션 안에서는 `SESSION_USER`가 대상 사용자, `PROXY_USER`가 중간 계정이다. 통합 감사에는 `DBUSERNAME`과 `DBPROXY_USERNAME`으로 나뉘어 남는다.
@B SQL*Plus 문법은 `CONNECT proxy[client]/proxy_password`다. JDBC·OCI는 풀의 물리 연결 위에서 경량 프록시 세션을 여닫는다(문서 기준).
@B 권한 부족으로 실패한 DML은 화면에는 ORA-01031로 보인다. 통합 감사의 RETURN_CODE에는 2004로 남는다(실습 [7] 실측). 1031만 찾는 실패 감사 조회는 이 행을 놓친다.
@B 프록시 계정에는 CREATE SESSION만 주고 비밀번호를 강하게 둔다. 이 계정의 비밀번호가 곧 허용된 모든 대상 사용자의 세션 열쇠다.
@B `AUTHENTICATION REQUIRED`를 붙이면 프록시 계정이 대상 사용자의 비밀번호까지 제시해야 한다. 제시하지 않은 접속은 ORA-28150으로 거부된다(교안 2장 실습 03). 응용 서버가 사용자 비밀번호를 받는 구조에서만 쓴다.
@B 허용은 대상 사용자마다 따로 준다. 응용 서버 계정 하나에 CONNECT THROUGH가 수백 개 걸리면 `PROXY_USERS`가 곧 위임 목록이므로 정기 점검 대상이 된다.
@B 프록시 계정 자체에는 업무 권한을 주지 않는다. 실습에서 D02_APP의 권한은 CREATE SESSION뿐인데도 프록시 세션의 조회가 성공한다. 권한 판정은 대상 사용자 기준이다.
@B `SYS_CONTEXT('USERENV', 'PROXY_USER')`는 서버가 정하는 값이다. 응용 역할의 활성화 조건(실습 03)이나 VPD 정책 함수의 술어(실습 05)에 그대로 쓴다.

@H3 02.2  진행 순서
@TBL
단계 | 주제 | 하는 일 | 확인할 것
[1] | 준비 | 소유자·테이블, 프록시·대상 계정, 역할 2개 | 역할은 대상 사용자에게만
[2] | 허용 없이 접속 | proxy[client] 접속 | ORA-01017
[3] | WITH ROLE 허용 | CONNECT THROUGH ... WITH ROLE d02_r_read | PROXY_USERS·PROXY_ROLES
[4] | 프록시 세션 | SESSION_USER·PROXY_USER, 역할, DML | ORA-01031, ORA-01924
[5] | 감사 정책 | SELECT·INSERT·UPDATE 감사 | BY USER / ALL USERS
[6] | 같은 작업 비교 | 프록시 세션과 직접 접속에서 같은 SQL | 직접 접속은 UPDATE 성공
[7] | 감사 조회 | DBUSERNAME·DBPROXY_USERNAME | RETURN_CODE 2004
[8] | 원복 | 정책·사용자·역할 삭제 | 0건
@END

@H3 02.3  실습 스크립트

@P [1] 계정·역할·테이블 준비
@CODE
-- ★ 응용 테이블 소유자는 접속 권한이 없다. 읽기·쓰기 역할은 대상 사용자 D02_CLERK 에게만 준다.
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d02_owner IDENTIFIED BY Owner2026x QUOTA 10M ON users;

User created.

SYS@orcl> CREATE TABLE d02_owner.pay (emp_id NUMBER, amount NUMBER) TABLESPACE users;

Table created.

SYS@orcl> INSERT INTO d02_owner.pay VALUES (100, 5000);

1 row created.

SYS@orcl> INSERT INTO d02_owner.pay VALUES (101, 4200);

1 row created.

SYS@orcl> COMMIT;

Commit complete.

SYS@orcl> CREATE USER d02_app IDENTIFIED BY App2026x;

User created.

SYS@orcl> CREATE USER d02_clerk IDENTIFIED BY Clerk2026x;

User created.

SYS@orcl> GRANT CREATE SESSION TO d02_app, d02_clerk;

Grant succeeded.

SYS@orcl> CREATE ROLE d02_r_read;

Role created.

SYS@orcl> CREATE ROLE d02_r_write;

Role created.

SYS@orcl> GRANT SELECT ON d02_owner.pay TO d02_r_read;

Grant succeeded.

SYS@orcl> GRANT INSERT, UPDATE ON d02_owner.pay TO d02_r_write;

Grant succeeded.

SYS@orcl> GRANT d02_r_read, d02_r_write TO d02_clerk;

Grant succeeded.
@END

@P [2] CONNECT THROUGH 없이 프록시 접속
@CODE
SQL> CONNECT d02_app[d02_clerk]/App2026x
ERROR:
ORA-01017: invalid username/password; logon denied
-- ★ CONNECT THROUGH 허용이 없을 때 19.3은 ORA-01017을 돌려준다. 프록시 관계의 존재 여부를 드러내지 않는다.
@END

@P [3] WITH ROLE 로 프록시 허용
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> ALTER USER d02_clerk GRANT CONNECT THROUGH d02_app WITH ROLE d02_r_read;

User altered.

SYS@orcl> COL proxy FOR a8
SYS@orcl> COL client FOR a10
SYS@orcl> COL role FOR a10
SYS@orcl> SELECT proxy, client, authentication, flags FROM proxy_users WHERE proxy = 'D02_APP';

PROXY    CLIENT     AUT FLAGS
-------- ---------- --- -----------------------------------
D02_APP  D02_CLERK  NO  PROXY MAY ACTIVATE ROLE

1 row selected.

SYS@orcl> SELECT proxy, client, role FROM proxy_roles WHERE proxy = 'D02_APP';

PROXY    CLIENT     ROLE
-------- ---------- ----------
D02_APP  D02_CLERK  D02_R_READ

1 row selected.
-- ★ FLAGS 'PROXY MAY ACTIVATE ROLE': 프록시 세션은 WITH ROLE 목록의 역할만 켤 수 있다.
-- ★ AUTHENTICATION 이 NO 이므로 대상 사용자의 비밀번호는 묻지 않는다.
@END

@P [4] 프록시 세션에서 보이는 것
@CODE
-- ★ D02_APP 의 비밀번호로 D02_CLERK 세션이 열린다. 프롬프트도 대상 사용자로 바뀐다.
SQL> CONNECT d02_app[d02_clerk]/App2026x
Connected.
D02_CLERK@orcl> COL session_user FOR a10
D02_CLERK@orcl> COL proxy_user FOR a10
D02_CLERK@orcl> COL ident FOR a10
D02_CLERK@orcl> SELECT SYS_CONTEXT('USERENV', 'SESSION_USER') session_user,
  2         SYS_CONTEXT('USERENV', 'PROXY_USER') proxy_user,
  3         SYS_CONTEXT('USERENV', 'AUTHENTICATED_IDENTITY') ident
  4    FROM dual;

SESSION_US PROXY_USER IDENT
---------- ---------- ----------
D02_CLERK  D02_APP    D02_CLERK

1 row selected.

D02_CLERK@orcl> COL role FOR a12
D02_CLERK@orcl> SELECT role FROM session_roles;

ROLE
------------
D02_R_READ

1 row selected.

D02_CLERK@orcl> SELECT * FROM d02_owner.pay;

    EMP_ID     AMOUNT
---------- ----------
       100       5000
       101       4200

2 rows selected.

D02_CLERK@orcl> INSERT INTO d02_owner.pay VALUES (102, 3900);
INSERT INTO d02_owner.pay VALUES (102, 3900)
                      *
ERROR at line 1:
ORA-01031: insufficient privileges


D02_CLERK@orcl> SET ROLE d02_r_write;
SET ROLE d02_r_write
*
ERROR at line 1:
ORA-01924: role 'D02_R_WRITE' not granted or does not exist
-- ★ AUTHENTICATED_IDENTITY 는 D02_CLERK 로 나온다. 프록시 계정은 PROXY_USER 로 따로 보인다.
-- ★ SESSION_ROLES 에는 D02_R_READ 만 있다. 쓰기 역할은 받았어도 켜지지 않았다.
-- ★ INSERT 는 ORA-01031, 쓰기 역할을 켜려는 SET ROLE 은 ORA-01924 다.
@END

@P [5] 통합 감사 정책
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE AUDIT POLICY d02_pol
  2    ACTIONS SELECT ON d02_owner.pay, INSERT ON d02_owner.pay, UPDATE ON d02_owner.pay;

Audit policy created.

SYS@orcl> AUDIT POLICY d02_pol;

Audit succeeded.

SYS@orcl> COL policy_name FOR a10
SYS@orcl> COL entity_name FOR a10
SYS@orcl> SELECT policy_name, enabled_option, entity_name, success, failure
  2    FROM audit_unified_enabled_policies WHERE policy_name = 'D02_POL';

POLICY_NAM ENABLED_OPTION  ENTITY_NAM SUC FAI
---------- --------------- ---------- --- ---
D02_POL    BY USER         ALL USERS  YES YES

1 row selected.
-- ★ BY 절 없이 켰으므로 ENABLED_OPTION 은 BY USER, ENTITY_NAME 은 ALL USERS 다. 정책은 이후 세션의 대상 작업부터 기록한다.
@END

@P [6] 프록시와 직접 접속에서 같은 작업
@CODE
SQL> CONNECT d02_app[d02_clerk]/App2026x
Connected.
D02_CLERK@orcl> SELECT COUNT(*) FROM d02_owner.pay;

  COUNT(*)
----------
         2

1 row selected.

D02_CLERK@orcl> UPDATE d02_owner.pay SET amount = amount WHERE emp_id = 100;
UPDATE d02_owner.pay SET amount = amount WHERE emp_id = 100
                 *
ERROR at line 1:
ORA-01031: insufficient privileges


D02_CLERK@orcl> CONNECT d02_clerk/Clerk2026x
Connected.
D02_CLERK@orcl> SELECT COUNT(*) FROM d02_owner.pay;

  COUNT(*)
----------
         2

1 row selected.

D02_CLERK@orcl> UPDATE d02_owner.pay SET amount = amount WHERE emp_id = 100;

1 row updated.

D02_CLERK@orcl> ROLLBACK;

Rollback complete.
-- ★ 같은 사용자 D02_CLERK 인데 프록시 세션의 UPDATE 는 실패하고 직접 접속의 UPDATE 는 성공한다. 권한 차이는 접속 경로에서 나온다.
@END

@P [7] 감사 기록에서 실제 사용자 찾기
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> EXEC DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL

PL/SQL procedure successfully completed.

SYS@orcl> COL t FOR a8
SYS@orcl> COL dbusername FOR a10
SYS@orcl> COL dbproxy_username FOR a10
SYS@orcl> COL action_name FOR a7
SYS@orcl> SELECT TO_CHAR(event_timestamp, 'HH24:MI:SS') t, dbusername, dbproxy_username,
  2         action_name, return_code
  3    FROM unified_audit_trail
  4   WHERE unified_audit_policies LIKE '%D02_POL%'
  5   ORDER BY event_timestamp, action_name;

T        DBUSERNAME DBPROXY_US ACTION_ RETURN_CODE
-------- ---------- ---------- ------- -----------
08:46:30 D02_CLERK  D02_APP    SELECT            0
08:46:30 D02_CLERK  D02_APP    UPDATE         2004
08:46:30 D02_CLERK             SELECT            0
08:46:30 D02_CLERK             UPDATE            0
08:47:34 D02_CLERK  D02_APP    SELECT            0
08:47:34 D02_CLERK  D02_APP    UPDATE         2004
08:47:34 D02_CLERK             SELECT            0
08:47:34 D02_CLERK             UPDATE            0

8 rows selected.
-- ★ DBPROXY_USERNAME 이 채워진 두 행이 프록시 세션의 작업이다.
-- ★ 프록시 세션의 UPDATE 는 화면에서 ORA-01031이었지만 RETURN_CODE 는 2004 로 남았다.
-- ★ 직접 접속 행은 DBPROXY_USERNAME 이 비어 있다.
@END

@P [8] 원복
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> NOAUDIT POLICY d02_pol;

Noaudit succeeded.

SYS@orcl> DROP AUDIT POLICY d02_pol;

Audit Policy dropped.

SYS@orcl> DROP USER d02_app CASCADE;

User dropped.

SYS@orcl> DROP USER d02_clerk CASCADE;

User dropped.

SYS@orcl> DROP USER d02_owner CASCADE;

User dropped.

SYS@orcl> DROP ROLE d02_r_read;

Role dropped.

SYS@orcl> DROP ROLE d02_r_write;

Role dropped.

SYS@orcl> SELECT COUNT(*) AS d02_users FROM dba_users WHERE username LIKE 'D02%';

 D02_USERS
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) AS d02_roles FROM dba_roles WHERE role LIKE 'D02%';

 D02_ROLES
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) AS d02_pols FROM audit_unified_policies WHERE policy_name = 'D02_POL';

  D02_POLS
----------
         0

1 row selected.
-- ★ NOAUDIT 후 DROP 해야 정책이 지워진다. 사용자·역할·정책 모두 0건이다.
@END

@H3 02.4  정리와 확인 포인트
@B 프록시 세션의 권한은 대상 사용자의 직접 권한에 WITH ROLE 역할을 더한 범위다. 줄일 수 있는 쪽은 역할뿐이므로 민감 권한은 역할로만 준다.
@B 감사에서 실제 사용자는 DBUSERNAME, 경유한 풀 계정은 DBPROXY_USERNAME이다. 둘을 함께 조회 조건으로 쓴다.
@B 프록시 접속의 ORA-01017은 비밀번호보다 PROXY_USERS를 먼저 확인한다.
@B 권한 위반 감사를 조회할 때는 RETURN_CODE 1031과 2004를 함께 본다.
@B 프록시 허용을 회수하려면 `ALTER USER client REVOKE CONNECT THROUGH proxy`를 쓴다. 프록시 계정을 지우지 않아도 해당 대상 사용자만 끊긴다.
