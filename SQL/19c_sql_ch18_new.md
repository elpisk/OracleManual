# Oracle Database 19c: SQL Workshop
## Chapter 18 — 사용자 접근 제어 (Controlling User Access)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- 시스템 권한과 객체 권한을 구분한다
- 테이블에 권한을 부여한다
- 롤(Role)을 생성하고 권한을 할당한다
- 권한과 롤의 차이를 설명한다
- 부여한 권한을 회수한다

---

## 1. 사용자 접근 제어 개요

Oracle 데이터베이스는 두 가지 수준의 보안으로 사용자 접근을 제어한다.

| 보안 수준 | 설명 |
|-----------|------|
| 시스템 보안(System Security) | 데이터베이스 시스템 수준 — 사용자명/암호, 시스템 권한 |
| 데이터 보안(Data Security) | 객체 수준 — 객체 권한, 스키마 |

**스키마(Schema)**: 테이블, 뷰, 시퀀스 등 객체의 집합 (사용자와 동일한 이름)

---

## 2. 권한의 종류

### 2-1. 시스템 권한 (System Privileges)

데이터베이스 내에서 **특정 작업**을 수행하는 권한 (200개 이상).

| 권한 | 설명 |
|------|------|
| `CREATE SESSION` | 데이터베이스에 접속 |
| `CREATE TABLE` | 테이블 생성 |
| `CREATE SEQUENCE` | 시퀀스 생성 |
| `CREATE VIEW` | 뷰 생성 |
| `CREATE PROCEDURE` | 프로시저 생성 |
| `CREATE USER` | 사용자 생성 (DBA) |
| `DROP TABLE` | 테이블 삭제 (DBA) |

DBA는 사용자 생성·삭제, 테이블 삭제, 백업 등 고수준 시스템 권한을 보유한다.

### 2-2. 객체 권한 (Object Privileges)

데이터베이스 **객체의 내용**을 조작하는 권한.

| 권한 | 테이블 | 뷰 | 시퀀스 |
|------|--------|-----|--------|
| `ALTER` | ✔ | — | ✔ |
| `DELETE` | ✔ | ✔ | — |
| `INDEX` | ✔ | — | — |
| `INSERT` | ✔ | ✔ | — |
| `REFERENCES` | ✔ | — | — |
| `SELECT` | ✔ | ✔ | ✔ |
| `UPDATE` | ✔ | ✔ | — |

---

## 3. 사용자 생성 (CREATE USER)

DBA가 새 사용자를 생성한다.

```sql
-- 구문
CREATE USER user_name
IDENTIFIED BY password;

-- 예제
CREATE USER demo
IDENTIFIED BY demo;
```

---

## 4. 시스템 권한 부여 (GRANT — 시스템 권한)

### 4-1. GRANT 구문

```sql
GRANT privilege [, privilege ...]
TO    user [, user | role | PUBLIC ...];
```

### 4-2. 예제

```sql
-- 개발자에게 기본 시스템 권한 부여
GRANT create session, create table, create sequence, create view
TO    demo;
```

- `PUBLIC`: 데이터베이스의 **모든 사용자**에게 권한 부여
- 여러 권한을 쉼표로 구분하여 한 번에 부여 가능

---

## 5. 롤 (Role)

### 5-1. 롤이란?

롤(Role)은 권한의 집합에 이름을 붙인 것이다. 사용자에게 개별 권한을 일일이 부여하는 대신 롤을 부여하면 관리가 편리하다.

```
권한 없이: 각 사용자에게 권한 개별 부여 → 복잡
롤 사용:   권한 → 롤 → 사용자 부여 → 단순
```

### 5-2. 롤 생성

```sql
CREATE ROLE manager;
```

### 5-3. 롤에 권한 부여

```sql
GRANT create table, create view
TO    manager;
```

### 5-4. 사용자에게 롤 부여

```sql
GRANT manager TO alice;
```

### 5-5. 롤의 장점

| 항목 | 설명 |
|------|------|
| 관리 단순화 | 롤 1개로 다수 사용자에게 동일 권한 부여 |
| 일괄 수정 | 롤의 권한 변경 → 모든 부여 사용자에 자동 적용 |
| 활성화/비활성화 | 세션 중 롤을 동적으로 활성화/비활성화 가능 |

---

## 6. 사용자 암호 변경 (ALTER USER)

DBA가 초기 암호를 설정한 후, 사용자가 직접 변경할 수 있다.

```sql
ALTER USER demo
IDENTIFIED BY new_password;
```

---

## 7. 객체 권한 부여 (GRANT — 객체 권한)

### 7-1. 구문

```sql
GRANT  object_priv [(columns)] | ALL
ON     object
TO     {user | role | PUBLIC}
[WITH GRANT OPTION];
```

- `ALL`: 해당 객체에 적용 가능한 모든 권한 부여
- `(columns)`: INSERT, UPDATE, REFERENCES에서 특정 열만 권한 부여
- `WITH GRANT OPTION`: 받은 권한을 다른 사용자에게 재부여 가능

### 7-2. 예제 — 조회 권한 부여

```sql
-- demo 사용자에게 EMPLOYEES 테이블 조회 권한
GRANT select
ON    employees
TO    demo;
```

### 7-3. 예제 — 열 수준 권한 부여

```sql
-- 특정 열만 UPDATE 권한 부여
GRANT update (department_name, location_id)
ON    departments
TO    demo, manager;
```

### 7-4. WITH GRANT OPTION — 권한 위임

```sql
-- demo가 받은 권한을 다른 사용자에게 재부여 가능
GRANT select, insert
ON    departments
TO    demo
WITH GRANT OPTION;
```

### 7-5. PUBLIC — 전체 사용자에게 부여

```sql
-- 모든 사용자가 DEPARTMENTS 조회 가능
GRANT select
ON    departments
TO    PUBLIC;
```

---

## 8. 부여된 권한 확인 (Data Dictionary Views)

| 뷰 이름 | 설명 |
|---------|------|
| `ROLE_SYS_PRIVS` | 롤에 부여된 시스템 권한 |
| `ROLE_TAB_PRIVS` | 롤에 부여된 테이블 권한 |
| `USER_ROLE_PRIVS` | 사용자에게 부여된 롤 |
| `USER_SYS_PRIVS` | 사용자에게 부여된 시스템 권한 |
| `USER_TAB_PRIVS_MADE` | 사용자 소유 객체에 부여한 객체 권한 |
| `USER_TAB_PRIVS_RECD` | 사용자가 받은 객체 권한 |
| `USER_COL_PRIVS_MADE` | 사용자 객체 열에 부여한 권한 |
| `USER_COL_PRIVS_RECD` | 사용자가 받은 열 수준 권한 |

```sql
-- 사용자가 받은 객체 권한 조회
SELECT * FROM user_tab_privs_recd;

-- 사용자에게 부여된 롤 조회
SELECT * FROM user_role_privs;

-- 시스템 권한 조회
SELECT * FROM user_sys_privs;
```

---

## 9. 권한 회수 (REVOKE)

### 9-1. 구문

```sql
REVOKE {privilege [, privilege ...] | ALL}
ON     object
FROM   {user [, user ...] | role | PUBLIC}
[CASCADE CONSTRAINTS];
```

### 9-2. 예제

```sql
-- demo의 SELECT, INSERT 권한 회수
REVOKE select, insert
ON    departments
FROM  demo;
```

### 9-3. REVOKE 연쇄 효과

- `WITH GRANT OPTION`으로 부여한 권한도 연쇄적으로 회수
- A가 B에게 `WITH GRANT OPTION`으로 부여 → B가 C에게 재부여
- A가 B의 권한 REVOKE → C의 권한도 자동 회수

### 9-4. CASCADE CONSTRAINTS

```sql
REVOKE references
ON    employees
FROM  demo
CASCADE CONSTRAINTS;
```

`REFERENCES` 권한 회수 시 해당 권한으로 생성된 참조 제약(FK)도 함께 삭제.

---

## 10. 단원 요약

| 주제 | 핵심 내용 |
|------|-----------|
| 시스템 권한 | 데이터베이스 작업 권한 / GRANT ... TO / CREATE USER (DBA) |
| 객체 권한 | 객체 조작 권한 / GRANT ... ON ... TO / 열 수준 권한 가능 |
| 롤 | 권한 집합 / CREATE ROLE / 관리 단순화 |
| ALTER USER | 사용자 암호 변경 |
| WITH GRANT OPTION | 받은 권한을 타인에게 재부여 가능 |
| PUBLIC | 모든 사용자에게 권한 부여 |
| Data Dictionary | USER_SYS_PRIVS, USER_TAB_PRIVS_RECD, USER_ROLE_PRIVS 등 |
| REVOKE | 권한 회수 / WITH GRANT OPTION 연쇄 회수 / CASCADE CONSTRAINTS |
