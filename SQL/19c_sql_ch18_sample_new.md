# Oracle Database 19c: SQL Workshop
## Chapter 18 — 사용자 접근 제어 | SQL 실습 문제

---

> **참고:** 이 실습은 DBA 계정(SYS 또는 SYSTEM) 또는 DBA 역할을 가진 계정에서 진행해야 합니다.  
> Oracle Live SQL, Oracle 19c 실습 환경, 또는 HR 계정이 있는 환경에서 수행하세요.

---

## Group 1: 사용자 생성 & 시스템 권한

**[1번]** 다음 두 사용자를 생성하시오.

```sql
-- DBA 계정으로 실행
CREATE USER test_user1 IDENTIFIED BY Oracle123;
CREATE USER test_user2 IDENTIFIED BY Oracle123;

-- 생성 확인
SELECT username, account_status, created
FROM   dba_users
WHERE  username IN ('TEST_USER1', 'TEST_USER2');
```

---

**[2번]** `test_user1`에게 데이터베이스 접속 권한을 부여하시오.

```sql
GRANT create session TO test_user1;

-- 권한 확인
SELECT grantee, privilege
FROM   dba_sys_privs
WHERE  grantee = 'TEST_USER1';
```

---

**[3번]** `test_user1`에게 테이블, 시퀀스, 뷰 생성 권한을 한 번에 부여하시오.

```sql
GRANT create table, create sequence, create view
TO    test_user1;

-- 시스템 권한 확인
SELECT grantee, privilege
FROM   dba_sys_privs
WHERE  grantee = 'TEST_USER1'
ORDER BY privilege;
```

---

**[4번]** `test_user1` 계정으로 접속하여 테이블 생성을 시도하고, 현재 부여된 시스템 권한을 확인하시오.

```sql
-- test_user1 계정으로 실행
SELECT * FROM user_sys_privs;

-- 테이블 생성 시도
CREATE TABLE test_user1.my_test (
    id   NUMBER PRIMARY KEY,
    name VARCHAR2(50)
);
-- 성공 시: "Table created."
```

---

**[5번]** `test_user2`에게 접속 권한만 부여한 뒤, test_user2 계정에서 테이블 생성을 시도하여 오류를 확인하시오.

```sql
-- DBA 계정으로
GRANT create session TO test_user2;

-- test_user2 계정으로 접속 후 실행
CREATE TABLE test_user2.my_tbl (id NUMBER);
-- 예상 오류: ORA-01031: insufficient privileges
```

---

## Group 2: 롤(Role) 생성 & 관리

**[6번]** 다음 두 개의 롤을 생성하시오.

```sql
-- DBA 계정으로 실행
CREATE ROLE read_only_role;
CREATE ROLE developer_role;

-- 롤 확인
SELECT role FROM dba_roles WHERE role IN ('READ_ONLY_ROLE', 'DEVELOPER_ROLE');
```

---

**[7번]** `read_only_role`에 HR 스키마의 주요 테이블 조회 권한을 부여하시오.

```sql
GRANT select ON hr.employees   TO read_only_role;
GRANT select ON hr.departments TO read_only_role;
GRANT select ON hr.locations   TO read_only_role;
GRANT select ON hr.jobs        TO read_only_role;

-- 롤에 부여된 권한 확인
SELECT role, privilege, table_name
FROM   role_tab_privs
WHERE  role = 'READ_ONLY_ROLE'
ORDER BY table_name;
```

---

**[8번]** `developer_role`에 시스템 권한을 부여하시오.

```sql
GRANT create session, create table, create view,
      create sequence, create procedure
TO    developer_role;

-- 롤에 부여된 시스템 권한 확인
SELECT role, privilege
FROM   role_sys_privs
WHERE  role = 'DEVELOPER_ROLE'
ORDER BY privilege;
```

---

**[9번]** 사용자에게 롤을 부여하시오.

```sql
GRANT read_only_role  TO test_user1;
GRANT developer_role  TO test_user1;
GRANT read_only_role  TO test_user2;

-- 사용자의 롤 확인
SELECT grantee, granted_role, admin_option, default_role
FROM   dba_role_privs
WHERE  grantee IN ('TEST_USER1', 'TEST_USER2')
ORDER BY grantee, granted_role;
```

---

**[10번]** `test_user1` 계정으로 롤을 통해 부여된 권한을 확인하시오.

```sql
-- test_user1 계정으로 실행
SELECT * FROM user_role_privs;

-- 롤을 통해 받은 테이블 권한 확인 (롤 이름으로 조회)
SELECT role, privilege, table_name, owner
FROM   role_tab_privs
WHERE  role IN (SELECT granted_role FROM user_role_privs);
```

---

## Group 3: 객체 권한

**[11번]** HR 계정에서 `test_user1`에게 employees 테이블 조회 권한을 부여하시오.

```sql
-- HR 계정으로 실행
GRANT select ON employees TO test_user1;

-- 부여한 권한 확인
SELECT grantee, privilege, table_name
FROM   user_tab_privs_made
WHERE  grantee = 'TEST_USER1';
```

---

**[12번]** `test_user1` 계정에서 받은 객체 권한을 확인하고, HR.EMPLOYEES를 조회하시오.

```sql
-- test_user1 계정으로 실행
SELECT * FROM user_tab_privs_recd;

-- HR.EMPLOYEES 조회 (권한 확인)
SELECT employee_id, last_name, salary
FROM   hr.employees
WHERE  ROWNUM <= 5;
```

---

**[13번]** HR 계정에서 `test_user1`에게 departments 테이블의 특정 열만 수정 권한을 부여하시오.

```sql
-- HR 계정으로 실행
GRANT update (department_name, location_id)
ON    departments
TO    test_user1;

-- 열 수준 권한 확인
SELECT grantee, privilege, table_name, column_name
FROM   user_col_privs_made
WHERE  grantee = 'TEST_USER1';
```

---

**[14번]** `test_user1` 계정에서 허용된 열과 허용되지 않은 열에 대한 UPDATE를 시도하시오.

```sql
-- test_user1 계정으로 실행

-- 허용된 열 수정 (성공)
UPDATE hr.departments
SET    department_name = 'Sales Updated'
WHERE  department_id = 80;

-- 허용되지 않은 열 수정 (오류 예상)
UPDATE hr.departments
SET    manager_id = 100
WHERE  department_id = 80;
-- ORA-01031: insufficient privileges

ROLLBACK;
```

---

**[15번]** HR 계정에서 `test_user1`에게 `WITH GRANT OPTION`으로 jobs 조회 권한을 부여하시오.

```sql
-- HR 계정으로 실행
GRANT select ON jobs TO test_user1 WITH GRANT OPTION;

-- 확인
SELECT grantee, privilege, table_name, grantable
FROM   user_tab_privs_made
WHERE  grantee = 'TEST_USER1';
-- GRANTABLE = 'YES' 확인
```

---

## Group 4: 권한 회수 (REVOKE)

**[16번]** `test_user1`이 `test_user2`에게 jobs 조회 권한을 재부여한 후, HR이 `test_user1`의 권한을 회수하여 연쇄 회수를 확인하시오.

```sql
-- test_user1 계정으로 실행
GRANT select ON hr.jobs TO test_user2;

-- HR 계정으로: test_user2의 권한 확인
SELECT grantee, privilege, table_name
FROM   user_tab_privs_made
WHERE  table_name = 'JOBS';

-- HR이 test_user1의 권한 회수
REVOKE select ON jobs FROM test_user1;

-- 연쇄 회수 확인: test_user2도 권한 사라짐
SELECT grantee, privilege, table_name
FROM   dba_tab_privs
WHERE  table_name = 'JOBS' AND owner = 'HR';
```

---

**[17번]** `test_user1`에게 부여된 departments UPDATE(열 수준) 권한을 회수하시오.

```sql
-- HR 계정으로 실행
REVOKE update ON departments FROM test_user1;

-- 확인
SELECT grantee, privilege, table_name, column_name
FROM   user_col_privs_made
WHERE  grantee = 'TEST_USER1';
-- no rows selected
```

---

**[18번]** 롤에서 특정 권한을 회수하고 그 효과를 확인하시오.

```sql
-- DBA 계정으로 실행

-- read_only_role에서 locations 조회 권한 회수
REVOKE select ON hr.locations FROM read_only_role;

-- 롤에 남은 권한 확인
SELECT role, privilege, table_name
FROM   role_tab_privs
WHERE  role = 'READ_ONLY_ROLE';

-- test_user2가 locations를 조회할 수 없음을 확인
-- (test_user2는 read_only_role만 보유)
```

---

**[19번]** `test_user2`에서 `read_only_role`을 회수하시오.

```sql
-- DBA 계정으로 실행
REVOKE read_only_role FROM test_user2;

-- 확인
SELECT grantee, granted_role
FROM   dba_role_privs
WHERE  grantee = 'TEST_USER2';
-- no rows selected

-- test_user2가 HR.EMPLOYEES 조회 불가 확인
-- (test_user2 계정에서 실행 시 ORA-00942)
```

---

**[20번]** PUBLIC에 부여된 권한과 그 영향을 확인하시오.

```sql
-- DBA 계정으로 실행
GRANT select ON hr.departments TO PUBLIC;

-- PUBLIC 권한 확인
SELECT grantee, privilege, table_name, owner
FROM   dba_tab_privs
WHERE  table_name = 'DEPARTMENTS' AND owner = 'HR';
-- GRANTEE = 'PUBLIC' 행 확인

-- 모든 사용자가 조회 가능한지 test_user2로 확인
-- test_user2 계정에서 실행:
SELECT department_id, department_name FROM hr.departments WHERE ROWNUM <= 3;

-- PUBLIC 권한 회수
REVOKE select ON hr.departments FROM PUBLIC;
```

---

## Group 5: 데이터 딕셔너리 & 종합 실습

**[21번]** 현재 사용자(HR)에게 부여된 시스템 권한을 조회하시오.

```sql
-- HR 계정으로 실행
SELECT username, privilege
FROM   user_sys_privs
ORDER BY privilege;
```

---

**[22번]** 현재 사용자(HR)가 다른 사용자에게 부여한 객체 권한 전체 목록을 조회하시오.

```sql
-- HR 계정으로 실행
SELECT grantee, privilege, table_name, grantable
FROM   user_tab_privs_made
ORDER BY grantee, table_name, privilege;
```

---

**[23번]** 현재 사용자가 받은 객체 권한과 열 수준 권한을 모두 조회하시오.

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

**[24번]** 롤 계층 구조를 포함한 사용자의 유효 권한을 분석하시오.

```sql
-- DBA 계정으로 test_user1의 모든 권한 분석

-- 1. 직접 부여된 시스템 권한
SELECT 'DIRECT' AS grant_type, privilege
FROM   dba_sys_privs WHERE grantee = 'TEST_USER1'
UNION ALL
-- 2. 롤을 통한 시스템 권한
SELECT 'VIA ROLE: ' || rsp.role, rsp.privilege
FROM   dba_role_privs rp
JOIN   role_sys_privs rsp ON (rp.granted_role = rsp.role)
WHERE  rp.grantee = 'TEST_USER1'
ORDER BY 1, 2;
```

---

**[25번]** 사용자 암호 변경 후 접속을 확인하시오.

```sql
-- DBA 계정으로 실행
ALTER USER test_user1 IDENTIFIED BY NewPass456;

-- 변경된 암호로 재접속 (Oracle SQL*Plus 또는 SQL Developer에서)
-- CONNECT test_user1/NewPass456

-- 접속 성공 후 확인
SELECT USER FROM DUAL;  -- TEST_USER1 출력
```

---

**[26번]** 실습 정리: 생성한 사용자, 롤을 삭제하시오.

```sql
-- DBA 계정으로 실행

-- 권한 회수 (필요 시)
REVOKE select ON hr.employees   FROM test_user1;
REVOKE select ON hr.departments FROM test_user1;

-- 롤 삭제
DROP ROLE read_only_role;
DROP ROLE developer_role;

-- 사용자 삭제 (CASCADE: 소유 객체도 함께 삭제)
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

---
