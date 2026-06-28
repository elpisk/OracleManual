# Oracle Database 19c: SQL Workshop
## Chapter 18 — 사용자 접근 제어 | 연습문제 (50문제)

---

## 하(기초) — 20문제

**[1번]** Oracle 데이터베이스의 두 가지 권한 유형으로 올바른 것은?

① 읽기 권한 / 쓰기 권한  
② 시스템 권한 / 객체 권한  
③ DBA 권한 / 일반 권한  
④ 선택 권한 / 조작 권한

---

**[2번]** 시스템 권한의 설명으로 올바른 것은?

① 특정 테이블의 행을 조작하는 권한  
② 데이터베이스 내에서 특정 작업을 수행하는 권한  
③ 다른 사용자의 뷰를 조회하는 권한  
④ 특정 열만 수정하는 권한

---

**[3번]** 데이터베이스에 접속하기 위해 필요한 시스템 권한은?

① CREATE TABLE  
② CREATE VIEW  
③ CREATE SESSION  
④ CREATE SEQUENCE

---

**[4번]** DBA가 새 사용자를 생성하는 구문으로 올바른 것은?

① `ADD USER demo PASSWORD demo;`  
② `CREATE USER demo IDENTIFIED BY demo;`  
③ `INSERT USER demo WITH PASSWORD demo;`  
④ `GRANT USER demo IDENTIFIED BY demo;`

---

**[5번]** 다음 중 시스템 권한에 해당하지 않는 것은?

① CREATE TABLE  
② CREATE SESSION  
③ SELECT  
④ CREATE VIEW

---

**[6번]** 시스템 권한 부여 구문으로 올바른 것은?

① `GRANT create table FROM demo;`  
② `GRANT create table TO demo;`  
③ `ASSIGN create table TO demo;`  
④ `GIVE create table TO demo;`

---

**[7번]** 롤(Role)이란 무엇인가?

① 특정 테이블에 대한 접근 권한  
② 이름을 붙인 관련 권한의 집합  
③ 사용자 계정의 다른 이름  
④ 뷰와 동일한 개념

---

**[8번]** 롤을 생성하는 구문으로 올바른 것은?

① `ADD ROLE manager;`  
② `CREATE ROLE manager;`  
③ `DEFINE ROLE manager;`  
④ `MAKE ROLE manager;`

---

**[9번]** 사용자의 암호를 변경하는 구문으로 올바른 것은?

① `CHANGE USER demo PASSWORD employ;`  
② `UPDATE USER demo SET password = 'employ';`  
③ `ALTER USER demo IDENTIFIED BY employ;`  
④ `MODIFY USER demo PASSWORD employ;`

---

**[10번]** 객체 권한에 해당하는 것을 모두 고르시오.

① CREATE TABLE  
② SELECT, INSERT, UPDATE, DELETE  
③ CREATE SESSION  
④ CREATE ROLE

---

**[11번]** 다음 중 테이블에만 부여 가능하고 뷰에는 부여할 수 없는 객체 권한은?

① SELECT  
② INSERT  
③ INDEX  
④ UPDATE

---

**[12번]** 객체 권한 부여 구문으로 올바른 것은?

① `GRANT select FROM employees TO demo;`  
② `GRANT select ON employees TO demo;`  
③ `GRANT select FOR employees TO demo;`  
④ `ALLOW select ON employees TO demo;`

---

**[13번]** `WITH GRANT OPTION`의 설명으로 올바른 것은?

① 권한 부여 후 자동으로 COMMIT된다  
② 받은 권한을 다른 사용자에게 재부여할 수 있다  
③ 권한 회수를 막는다  
④ 롤에만 사용 가능하다

---

**[14번]** 모든 사용자에게 권한을 부여하는 키워드는?

① ALL  
② EVERYONE  
③ PUBLIC  
④ GLOBAL

---

**[15번]** 권한을 회수하는 구문으로 올바른 것은?

① `CANCEL select ON departments FROM demo;`  
② `REVOKE select ON departments FROM demo;`  
③ `REMOVE select ON departments FROM demo;`  
④ `DELETE select ON departments FROM demo;`

---

**[16번]** `USER_TAB_PRIVS_RECD` 딕셔너리 뷰에 대한 설명으로 올바른 것은?

① 사용자가 소유한 객체에 부여한 권한  
② 사용자가 받은 객체 권한  
③ 롤에 부여된 테이블 권한  
④ 사용자에게 부여된 시스템 권한

---

**[17번]** 특정 열만 UPDATE 권한을 부여하는 구문으로 올바른 것은?

① `GRANT update ON departments TO demo;`  
② `GRANT update (department_name) ON departments TO demo;`  
③ `GRANT update[department_name] ON departments TO demo;`  
④ `GRANT column update ON departments TO demo;`

---

**[18번]** Oracle에서 사용 가능한 시스템 권한의 수는 대략 몇 개 이상인가?

① 10개  
② 50개  
③ 200개  
④ 1000개

---

**[19번]** `USER_ROLE_PRIVS` 딕셔너리 뷰에서 확인할 수 있는 정보는?

① 사용자가 받은 객체 권한  
② 현재 사용자에게 부여된 롤  
③ 롤에 부여된 시스템 권한  
④ 사용자가 소유한 테이블 목록

---

**[20번]** 시퀀스(SEQUENCE)에 부여할 수 있는 객체 권한은?

① SELECT, ALTER  
② SELECT, INSERT, UPDATE  
③ DELETE, INSERT  
④ INDEX, REFERENCES

---

## 중(응용) — 20문제

---

**[21번]** 다음 SQL의 실행 결과로 올바른 것은?

```sql
GRANT create session, create table, create sequence, create view
TO    demo;
```

① demo 사용자에게 4가지 시스템 권한 부여  
② demo 역할에 4가지 객체 권한 부여  
③ demo 사용자 계정 생성  
④ 오류 발생 (GRANT에 여러 권한 한 번에 불가)

---

**[22번]** 다음 시나리오에서 올바른 방법은?

**상황:** 개발팀 10명에게 CREATE TABLE, CREATE VIEW 권한을 부여해야 한다.

① 각 사용자에게 개별적으로 GRANT 10번 실행  
② `CREATE ROLE dev_role; GRANT create table, create view TO dev_role;` 후 10명에게 dev_role 부여  
③ `GRANT create table, create view TO PUBLIC;`으로 전체 부여  
④ 모든 사용자를 DBA 롤로 설정

---

**[23번]** 다음 SQL에서 발생하는 문제점은?

```sql
GRANT select
ON    employees
TO    demo
WITH GRANT OPTION;

-- demo 사용자가 실행:
GRANT select ON hr.employees TO alice;
```

`alice`의 권한 소스: hr → demo → alice

이후 hr이 demo의 권한을 REVOKE하면?

① alice의 권한은 그대로 유지됨  
② alice의 권한도 연쇄 회수됨  
③ demo의 권한만 회수됨, alice는 독립 유지  
④ REVOKE가 불가능함

---

**[24번]** `GRANT update (salary, commission_pct) ON employees TO demo;`의 의미는?

① employees 테이블 전체를 갱신하는 권한  
② demo가 employees의 salary와 commission_pct 열만 UPDATE 가능  
③ salary와 commission_pct 열을 SELECT 가능  
④ 해당 열을 DELETE 가능

---

**[25번]** 다음 중 `WITH GRANT OPTION`을 롤(Role)에 부여할 때 발생하는 제한은?

① 롤은 WITH GRANT OPTION을 사용할 수 없음  
② 롤은 WITH GRANT OPTION을 사용하면 오류 발생  
③ 롤에 WITH GRANT OPTION 부여 불가 (사용자에게만 가능)  
④ 제한 없음

---

**[26번]** 다음 SQL의 결과로 올바른 것은?

```sql
CREATE ROLE app_user;
GRANT select ON employees TO app_user;
GRANT select ON departments TO app_user;
GRANT app_user TO demo, alice, bob;
```

① demo, alice, bob에게 employees와 departments SELECT 권한 부여  
② app_user 롤이 demo, alice, bob으로 이름이 변경됨  
③ demo만 권한을 받음  
④ 오류 발생 (롤에 SELECT 부여 불가)

---

**[27번]** 다음 딕셔너리 뷰와 설명이 올바르게 연결된 것은?

① `USER_SYS_PRIVS` — 사용자가 받은 객체 권한  
② `ROLE_TAB_PRIVS` — 롤에 부여된 테이블 권한  
③ `USER_TAB_PRIVS_MADE` — 사용자가 받은 열 수준 권한  
④ `USER_COL_PRIVS_RECD` — 사용자 소유 테이블에 부여한 권한

---

**[28번]** 다음 시나리오에서 올바른 해결책은?

**상황:** demo 사용자에게 departments 테이블의 department_name 열만 수정 가능하게 하고, 다른 열은 수정 불가하게 해야 한다.

① `GRANT update ON departments TO demo;`  
② `GRANT update (department_name) ON departments TO demo;`  
③ `GRANT select (department_name) ON departments TO demo;`  
④ `RESTRICT update ON departments TO demo;`

---

**[29번]** 다음 SQL은 어떤 사용자에게 권한을 부여하는가?

```sql
GRANT select ON employees TO PUBLIC;
```

① demo 사용자에게만  
② DBA 사용자들에게만  
③ 현재 데이터베이스의 모든 사용자에게  
④ PUBLIC이라는 이름의 사용자에게

---

**[30번]** 다음 REVOKE 구문의 결과는?

```sql
REVOKE select, insert
ON    departments
FROM  demo;
```

① demo가 이전에 가진 모든 권한 회수  
② demo의 departments에 대한 SELECT와 INSERT 권한만 회수  
③ demo 사용자 계정 삭제  
④ departments 테이블 삭제

---

**[31번]** `REFERENCES` 권한의 설명으로 올바른 것은?

① 다른 사용자의 테이블을 조회하는 권한  
② 다른 사용자의 테이블을 외래 키(FK) 참조 대상으로 사용하는 권한  
③ 테이블의 주석(COMMENT)을 추가하는 권한  
④ 뷰를 통해 데이터를 수정하는 권한

---

**[32번]** 시스템 권한과 객체 권한의 차이로 올바른 것은?

① 시스템 권한은 ON 절이 있고, 객체 권한은 없다  
② 시스템 권한은 ON 절이 없고, 객체 권한은 ON 절로 객체 지정  
③ 시스템 권한은 DBA만 부여 가능, 객체 권한은 누구나 부여 가능  
④ 시스템 권한과 객체 권한은 동일하다

---

**[33번]** 롤을 사용하는 가장 큰 장점은?

① 권한 부여 SQL이 더 길어진다  
② 여러 사용자에게 권한 집합을 일괄 관리하여 관리 복잡성 감소  
③ 롤을 사용하면 권한이 자동으로 증가한다  
④ 롤은 PUBLIC에만 부여 가능하다

---

**[34번]** 다음 SQL을 실행 가능한 사용자는?

```sql
CREATE USER newuser IDENTIFIED BY password123;
```

① 모든 사용자  
② CREATE SESSION 권한만 있는 사용자  
③ CREATE USER 시스템 권한이 있는 사용자 (DBA)  
④ 스키마 소유자만

---

**[35번]** 다음 중 `USER_COL_PRIVS_MADE` 뷰에서 확인할 수 있는 정보는?

① 사용자가 받은 열 수준 권한  
② 사용자가 **부여한** 열 수준 권한  
③ 사용자에게 부여된 롤  
④ 롤에 부여된 열 권한

---

**[36번]** 다음 SQL에서 alice에게 실제로 부여되는 권한은?

```sql
CREATE ROLE analyst;
GRANT select, insert ON employees TO analyst;
GRANT analyst TO alice;
```

① employees에 대한 SELECT와 INSERT  
② analyst 역할만  
③ 모든 시스템 권한  
④ 오류 발생

---

**[37번]** 다음 SQL에서 REVOKE 후 bob이 여전히 가지는 권한은?

```sql
GRANT select ON departments TO demo WITH GRANT OPTION;
-- demo 실행:
GRANT select ON hr.departments TO bob;
-- hr 실행:
REVOKE select ON departments FROM demo;
```

① SELECT 권한 유지 (WITH GRANT OPTION으로 보호됨)  
② SELECT 권한 연쇄 회수됨  
③ bob은 처음부터 권한이 없었음  
④ REVOKE가 WITH GRANT OPTION으로 차단됨

---

**[38번]** `GRANT ALL ON employees TO demo;`의 의미는?

① demo에게 모든 시스템 권한 부여  
② demo에게 employees 테이블에 적용 가능한 모든 객체 권한 부여  
③ 모든 사용자에게 employees 조회 권한  
④ employees 테이블 소유권 이전

---

**[39번]** Oracle에서 스키마(Schema)의 올바른 설명은?

① 데이터베이스 전체의 구조 설계도  
② 특정 사용자가 소유한 데이터베이스 객체의 집합 (사용자와 동일 이름)  
③ 테이블과 뷰만 포함하는 집합  
④ DBA 전용 네임스페이스

---

**[40번]** 다음 중 `CASCADE CONSTRAINTS`를 REVOKE 시 사용하는 경우는?

① 시스템 권한 회수 시 모든 사용자에게 연쇄 적용  
② REFERENCES 권한 회수 시 해당 권한으로 생성된 FK 제약을 함께 삭제  
③ 롤의 권한 회수 시 모든 롤 멤버에 연쇄 적용  
④ DELETE 권한 회수 시 기존 데이터 삭제

---

## 상(심화) — 10문제

---

**[41번]** 다음 시나리오의 권한 구조를 분석하시오.

```sql
-- HR 스키마:
GRANT select ON employees TO alice WITH GRANT OPTION;
-- alice:
GRANT select ON hr.employees TO bob WITH GRANT OPTION;
-- bob:
GRANT select ON hr.employees TO carol;
-- HR:
REVOKE select ON employees FROM alice;
```

최종적으로 alice, bob, carol의 권한 상태는?

① alice만 회수, bob·carol은 유지  
② alice·bob·carol 모두 회수됨  
③ alice·bob은 회수, carol은 유지  
④ 회수 불가 (WITH GRANT OPTION으로 보호)

---

**[42번]** 다음 중 롤(Role)과 직접 권한 부여(Direct Grant)를 비교한 설명으로 올바른 것은?

① 롤을 통한 권한은 저장 프로시저에서 항상 활성화된다  
② 저장 프로시저·함수는 직접 부여된 권한만 사용 가능, 롤을 통한 권한은 기본적으로 비활성화  
③ 롤을 통한 권한과 직접 부여 권한은 완전히 동일하다  
④ 저장 프로시저에서는 롤을 통한 권한만 사용 가능하다

---

**[43번]** 다음 SQL 실행 시 발생하는 상황을 설명하시오.

```sql
-- demo 사용자가 실행:
GRANT select ON hr.employees TO alice;
```

demo 사용자는 hr.employees에 대한 SELECT 권한을 `WITH GRANT OPTION` 없이 받은 상태.

① 성공 — demo는 받은 권한을 항상 타인에게 부여 가능  
② 실패 — ORA-01031: insufficient privileges  
③ 성공 — SELECT 권한은 기본적으로 재부여 가능  
④ 실패 — ORA-00942: table or view does not exist

---

**[44번]** 다음 시나리오에서 발생하는 문제를 설명하시오.

**상황:**
1. DBA가 `GRANT create table TO demo;` 실행
2. demo가 테이블 생성: `CREATE TABLE demo.test_tbl ...;`
3. DBA가 `REVOKE create table FROM demo;` 실행

demo의 테이블(demo.test_tbl)은 어떻게 되는가?

① 테이블 자동 삭제  
② 테이블은 그대로 유지됨 (기존 객체는 영향 없음)  
③ 테이블의 데이터만 삭제, 구조는 유지  
④ demo 사용자 계정 삭제

---

**[45번]** 다음 권한 부여 구문에서 오류가 발생하는 것은?

① `GRANT select ON employees TO PUBLIC;`  
② `GRANT create table TO PUBLIC;`  
③ `GRANT select ON employees TO demo WITH GRANT OPTION WITH ADMIN OPTION;`  
④ `GRANT update (salary) ON employees TO demo;`

---

**[46번]** 다음 중 `GRANT ... WITH ADMIN OPTION`과 `GRANT ... WITH GRANT OPTION`의 차이로 올바른 것은?

① 둘 다 동일하다  
② WITH ADMIN OPTION: 시스템 권한·롤 재부여 가능 / WITH GRANT OPTION: 객체 권한 재부여 가능  
③ WITH GRANT OPTION: 시스템 권한 전용 / WITH ADMIN OPTION: 객체 권한 전용  
④ WITH ADMIN OPTION은 REVOKE 시 연쇄 회수 발생, WITH GRANT OPTION은 연쇄 없음

---

**[47번]** 다음 상황에서 가장 안전한 권한 설계는?

**요구사항:**
- 회계팀: employees의 salary 조회·수정만 허용
- 인사팀: employees 전체 조회 허용
- 일반 사용자: employees 조회 불가

① 모든 팀에 SELECT ON employees 부여 후 제한  
② `GRANT select (salary), update (salary) ON employees TO acct_role;` `GRANT select ON employees TO hr_role;` 이후 각 팀원에게 해당 롤 부여  
③ `GRANT ALL ON employees TO PUBLIC;` 후 필요 없는 권한 REVOKE  
④ 뷰를 생성하여 열 수준 접근 제어 구현 (롤 없이)

---

**[48번]** 다음 SQL의 실행 순서와 결과를 분석하시오.

```sql
-- 1단계
CREATE USER alice IDENTIFIED BY pass1;
CREATE USER bob IDENTIFIED BY pass2;

-- 2단계
CREATE ROLE reader;
GRANT select ON hr.employees TO reader;
GRANT select ON hr.departments TO reader;

-- 3단계
GRANT reader TO alice, bob;

-- 4단계
GRANT reader TO bob WITH ADMIN OPTION;

-- 5단계
REVOKE reader FROM alice;
```

5단계 후 alice와 bob의 권한 상태는?

① alice·bob 모두 reader 롤 유지  
② alice: reader 회수됨 / bob: reader 유지 (WITH ADMIN OPTION 있어도 REVOKE는 각 사용자 독립)  
③ alice·bob 모두 reader 회수됨  
④ bob의 WITH ADMIN OPTION으로 회수 불가

---

**[49번]** 다음 SQL 실행 후 `USER_TAB_PRIVS_MADE`와 `USER_TAB_PRIVS_RECD`에서 확인되는 내용은?

```sql
-- HR 스키마에서 실행
GRANT select ON employees TO demo;
GRANT insert ON departments TO demo;

-- demo 스키마에서 실행
GRANT select ON demo.my_table TO alice;
```

HR의 `USER_TAB_PRIVS_MADE`에서 확인되는 것:

① demo가 alice에게 부여한 my_table SELECT 권한  
② HR이 demo에게 부여한 employees SELECT, departments INSERT  
③ demo가 받은 모든 권한  
④ HR이 받은 모든 권한

---

**[50번]** 다음 중 Oracle 데이터베이스 보안 모범 사례(Best Practice)로 올바르지 않은 것은?

① 최소 권한 원칙(Principle of Least Privilege): 필요한 최소한의 권한만 부여  
② 롤 기반 접근 제어(RBAC): 직접 권한 부여 대신 롤 사용  
③ PUBLIC에 DML 권한 부여: 모든 사용자가 모든 테이블에 접근 가능하도록 설정  
④ 정기적인 권한 감사: USER_SYS_PRIVS, USER_TAB_PRIVS_RECD 등 딕셔너리 뷰로 권한 검토
