# Oracle Database 19c: SQL Workshop
## Chapter 18 — 사용자 접근 제어 | SQL 실습 모범답안

---

## Group 1: 사용자 생성 & 시스템 권한

**[1번]**
```sql
CREATE USER test_user1 IDENTIFIED BY Oracle123;
CREATE USER test_user2 IDENTIFIED BY Oracle123;

SELECT username, account_status, created
FROM   dba_users
WHERE  username IN ('TEST_USER1', 'TEST_USER2');
-- TEST_USER1  OPEN  (오늘 날짜)
-- TEST_USER2  OPEN  (오늘 날짜)
```

---

**[2번]**
```sql
GRANT create session TO test_user1;

SELECT grantee, privilege
FROM   dba_sys_privs
WHERE  grantee = 'TEST_USER1';
-- TEST_USER1  CREATE SESSION
```

---

**[3번]**
```sql
GRANT create table, create sequence, create view
TO    test_user1;

SELECT grantee, privilege
FROM   dba_sys_privs
WHERE  grantee = 'TEST_USER1'
ORDER BY privilege;
-- TEST_USER1  CREATE SEQUENCE
-- TEST_USER1  CREATE SESSION
-- TEST_USER1  CREATE TABLE
-- TEST_USER1  CREATE VIEW
```

---

**[4번]**
```sql
-- test_user1 계정으로 실행
SELECT * FROM user_sys_privs;
-- USERNAME     PRIVILEGE        ADMIN_OPT
-- TEST_USER1   CREATE SEQUENCE  NO
-- TEST_USER1   CREATE SESSION   NO
-- TEST_USER1   CREATE TABLE     NO
-- TEST_USER1   CREATE VIEW      NO

CREATE TABLE test_user1.my_test (
    id   NUMBER PRIMARY KEY,
    name VARCHAR2(50)
);
-- Table created. (성공)
```

---

**[5번]**
```sql
-- DBA 계정으로
GRANT create session TO test_user2;

-- test_user2 계정으로 실행
CREATE TABLE test_user2.my_tbl (id NUMBER);
-- ORA-01031: insufficient privileges
-- → test_user2는 CREATE SESSION만 있고 CREATE TABLE이 없음
```

---

## Group 2: 롤(Role) 생성 & 관리

**[6번]**
```sql
CREATE ROLE read_only_role;
CREATE ROLE developer_role;

SELECT role FROM dba_roles
WHERE  role IN ('READ_ONLY_ROLE', 'DEVELOPER_ROLE');
-- DEVELOPER_ROLE
-- READ_ONLY_ROLE
```

---

**[7번]**
```sql
GRANT select ON hr.employees   TO read_only_role;
GRANT select ON hr.departments TO read_only_role;
GRANT select ON hr.locations   TO read_only_role;
GRANT select ON hr.jobs        TO read_only_role;

SELECT role, privilege, table_name
FROM   role_tab_privs
WHERE  role = 'READ_ONLY_ROLE'
ORDER BY table_name;
-- READ_ONLY_ROLE  SELECT  DEPARTMENTS
-- READ_ONLY_ROLE  SELECT  EMPLOYEES
-- READ_ONLY_ROLE  SELECT  JOBS
-- READ_ONLY_ROLE  SELECT  LOCATIONS
```

---

**[8번]**
```sql
GRANT create session, create table, create view,
      create sequence, create procedure
TO    developer_role;

SELECT role, privilege
FROM   role_sys_privs
WHERE  role = 'DEVELOPER_ROLE'
ORDER BY privilege;
-- DEVELOPER_ROLE  CREATE PROCEDURE
-- DEVELOPER_ROLE  CREATE SEQUENCE
-- DEVELOPER_ROLE  CREATE SESSION
-- DEVELOPER_ROLE  CREATE TABLE
-- DEVELOPER_ROLE  CREATE VIEW
```

---

**[9번]**
```sql
GRANT read_only_role  TO test_user1;
GRANT developer_role  TO test_user1;
GRANT read_only_role  TO test_user2;

SELECT grantee, granted_role, admin_option, default_role
FROM   dba_role_privs
WHERE  grantee IN ('TEST_USER1', 'TEST_USER2')
ORDER BY grantee, granted_role;
-- TEST_USER1  DEVELOPER_ROLE  NO  YES
-- TEST_USER1  READ_ONLY_ROLE  NO  YES
-- TEST_USER2  READ_ONLY_ROLE  NO  YES
```

---

**[10번]**
```sql
-- test_user1 계정으로 실행
SELECT * FROM user_role_privs;
-- TEST_USER1  DEVELOPER_ROLE  NO  YES  NO
-- TEST_USER1  READ_ONLY_ROLE  NO  YES  NO

SELECT role, privilege, table_name, owner
FROM   role_tab_privs
WHERE  role IN (SELECT granted_role FROM user_role_privs);
-- READ_ONLY_ROLE  SELECT  DEPARTMENTS  HR
-- READ_ONLY_ROLE  SELECT  EMPLOYEES    HR
-- READ_ONLY_ROLE  SELECT  JOBS         HR
-- READ_ONLY_ROLE  SELECT  LOCATIONS    HR
```

---

## Group 3: 객체 권한

**[11번]**
```sql
-- HR 계정으로 실행
GRANT select ON employees TO test_user1;

SELECT grantee, privilege, table_name
FROM   user_tab_privs_made
WHERE  grantee = 'TEST_USER1';
-- TEST_USER1  SELECT  EMPLOYEES
```

---

**[12번]**
```sql
-- test_user1 계정으로 실행
SELECT * FROM user_tab_privs_recd;
-- HR  EMPLOYEES  TEST_USER1  SELECT  NO  NO

SELECT employee_id, last_name, salary
FROM   hr.employees
WHERE  ROWNUM <= 5;
-- 5행 조회 성공
```

---

**[13번]**
```sql
-- HR 계정으로 실행
GRANT update (department_name, location_id)
ON    departments
TO    test_user1;

SELECT grantee, privilege, table_name, column_name
FROM   user_col_privs_made
WHERE  grantee = 'TEST_USER1';
-- TEST_USER1  UPDATE  DEPARTMENTS  DEPARTMENT_NAME
-- TEST_USER1  UPDATE  DEPARTMENTS  LOCATION_ID
```

---

**[14번]**
```sql
-- test_user1 계정으로 실행

-- 허용된 열 수정 (성공)
UPDATE hr.departments
SET    department_name = 'Sales Updated'
WHERE  department_id = 80;
-- 1 row updated.

-- 허용되지 않은 열 수정 (오류)
UPDATE hr.departments
SET    manager_id = 100
WHERE  department_id = 80;
-- ORA-01031: insufficient privileges

ROLLBACK;
```

---

**[15번]**
```sql
-- HR 계정으로 실행
GRANT select ON jobs TO test_user1 WITH GRANT OPTION;

SELECT grantee, privilege, table_name, grantable
FROM   user_tab_privs_made
WHERE  grantee = 'TEST_USER1';
-- TEST_USER1  SELECT  EMPLOYEES  NO
-- TEST_USER1  SELECT  JOBS       YES   ← GRANTABLE = YES 확인
```

---

## Group 4: 권한 회수 (REVOKE)

**[16번]**
```sql
-- test_user1 계정으로 실행
GRANT select ON hr.jobs TO test_user2;

-- HR 계정으로: 부여된 권한 확인
SELECT grantee, privilege, table_name
FROM   user_tab_privs_made
WHERE  table_name = 'JOBS';
-- TEST_USER1  SELECT  JOBS
-- TEST_USER2  SELECT  JOBS  ← test_user1이 재부여

-- HR이 test_user1 권한 회수
REVOKE select ON jobs FROM test_user1;

-- 연쇄 회수 확인
SELECT grantee, privilege, table_name
FROM   dba_tab_privs
WHERE  table_name = 'JOBS' AND owner = 'HR';
-- no rows selected (test_user1, test_user2 모두 회수됨)
```

**연쇄 회수 원리:** test_user1은 `WITH GRANT OPTION`으로 받은 jobs SELECT를 test_user2에게 재부여. HR이 test_user1 권한 회수 시 test_user2의 권한도 자동 회수.

---

**[17번]**
```sql
-- HR 계정으로 실행
REVOKE update ON departments FROM test_user1;

SELECT grantee, privilege, table_name, column_name
FROM   user_col_privs_made
WHERE  grantee = 'TEST_USER1';
-- no rows selected (열 수준 UPDATE 권한 제거됨)
```

---

**[18번]**
```sql
-- DBA 계정으로 실행
REVOKE select ON hr.locations FROM read_only_role;

SELECT role, privilege, table_name
FROM   role_tab_privs
WHERE  role = 'READ_ONLY_ROLE';
-- READ_ONLY_ROLE  SELECT  DEPARTMENTS
-- READ_ONLY_ROLE  SELECT  EMPLOYEES
-- READ_ONLY_ROLE  SELECT  JOBS
-- (LOCATIONS 제거됨)

-- test_user2 계정에서 locations 조회 시도
SELECT * FROM hr.locations WHERE ROWNUM <= 3;
-- ORA-00942: table or view does not exist (또는 ORA-01031)
```

---

**[19번]**
```sql
-- DBA 계정으로 실행
REVOKE read_only_role FROM test_user2;

SELECT grantee, granted_role
FROM   dba_role_privs
WHERE  grantee = 'TEST_USER2';
-- no rows selected

-- test_user2 계정에서 실행 시 (read_only_role 제거됨)
SELECT * FROM hr.employees WHERE ROWNUM <= 3;
-- ORA-00942: table or view does not exist
```

---

**[20번]**
```sql
-- DBA 계정으로 실행
GRANT select ON hr.departments TO PUBLIC;

SELECT grantee, privilege, table_name, owner
FROM   dba_tab_privs
WHERE  table_name = 'DEPARTMENTS' AND owner = 'HR';
-- PUBLIC  SELECT  DEPARTMENTS  HR

-- test_user2 계정에서 실행 (PUBLIC 권한으로 조회 가능)
SELECT department_id, department_name FROM hr.departments WHERE ROWNUM <= 3;
-- 10  Administration
-- 20  Marketing
-- 30  Purchasing

-- PUBLIC 권한 회수
REVOKE select ON hr.departments FROM PUBLIC;
-- 이후 test_user2는 departments 조회 불가
```

---

## Group 5: 데이터 딕셔너리 & 종합 실습

**[21번]**
```sql
-- HR 계정으로 실행
SELECT username, privilege
FROM   user_sys_privs
ORDER BY privilege;
-- HR  CREATE PROCEDURE
-- HR  CREATE SEQUENCE
-- HR  CREATE SESSION
-- HR  CREATE TABLE
-- HR  CREATE TRIGGER
-- HR  CREATE TYPE
-- HR  CREATE VIEW
-- HR  UNLIMITED TABLESPACE
-- (HR 계정에 부여된 시스템 권한 목록)
```

---

**[22번]**
```sql
-- HR 계정으로 실행
SELECT grantee, privilege, table_name, grantable
FROM   user_tab_privs_made
ORDER BY grantee, table_name, privilege;
-- TEST_USER1  SELECT  EMPLOYEES    NO
-- (이전 실습에서 부여한 권한이 남아있는 경우 표시)
```

---

**[23번]**
```sql
-- test_user1 계정으로 실행

-- 테이블 수준 권한
SELECT owner, table_name, privilege, grantable
FROM   user_tab_privs_recd
ORDER BY owner, table_name;

-- 열 수준 권한
SELECT owner, table_name, column_name, privilege
FROM   user_col_privs_recd
ORDER BY table_name, column_name;
```

---

**[24번]**
```sql
-- DBA 계정으로 실행
SELECT 'DIRECT' AS grant_type, privilege
FROM   dba_sys_privs
WHERE  grantee = 'TEST_USER1'
UNION ALL
SELECT 'VIA ROLE: ' || rsp.role, rsp.privilege
FROM   dba_role_privs rp
JOIN   role_sys_privs rsp ON (rp.granted_role = rsp.role)
WHERE  rp.grantee = 'TEST_USER1'
ORDER BY 1, 2;

-- 결과 예시:
-- DIRECT                   CREATE SEQUENCE
-- DIRECT                   CREATE SESSION
-- DIRECT                   CREATE TABLE
-- DIRECT                   CREATE VIEW
-- VIA ROLE: DEVELOPER_ROLE CREATE PROCEDURE
-- VIA ROLE: DEVELOPER_ROLE CREATE SEQUENCE
-- ...
```

---

**[25번]**
```sql
-- DBA 계정으로 실행
ALTER USER test_user1 IDENTIFIED BY NewPass456;

-- 새 암호로 접속 확인 (SQL*Plus 또는 SQL Developer)
-- CONNECT test_user1/NewPass456

-- 접속 성공 후 확인
SELECT USER FROM DUAL;
-- TEST_USER1
```

---

**[26번]**
```sql
-- DBA 계정으로 실행

-- 롤 삭제 (자동으로 부여된 롤도 해제됨)
DROP ROLE read_only_role;
DROP ROLE developer_role;

-- 사용자 삭제 (CASCADE: 소유 객체 함께 삭제)
DROP USER test_user1 CASCADE;
DROP USER test_user2 CASCADE;

-- 정리 확인
SELECT username FROM dba_users
WHERE  username IN ('TEST_USER1', 'TEST_USER2');
-- no rows selected

SELECT role FROM dba_roles
WHERE  role IN ('READ_ONLY_ROLE', 'DEVELOPER_ROLE');
-- no rows selected
```

**CASCADE 옵션:** `DROP USER ... CASCADE`는 해당 사용자의 스키마에 있는 모든 객체(테이블, 뷰, 시퀀스 등)를 함께 삭제합니다.
