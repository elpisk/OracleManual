# Oracle Database 19c: SQL Workshop
## Chapter 15 — 스키마 객체 관리 (Managing Schema Objects)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- 제약 조건을 추가, 삭제, 활성화, 비활성화, 지연 처리한다
- 임시 테이블(Global/Private)을 생성하고 사용한다
- 외부 테이블(External Table)을 생성하고 조회한다

---

## 1. 제약 조건 관리

### 1-1. 제약 조건 추가 (ALTER TABLE ... ADD CONSTRAINT)

`ALTER TABLE` 문으로 기존 테이블에 제약 조건을 추가한다.

```sql
-- 기본 구문
ALTER TABLE 테이블명
ADD [CONSTRAINT 제약조건명] 제약유형(열이름);

-- PRIMARY KEY 추가 (MODIFY 사용)
ALTER TABLE emp2
MODIFY employee_id PRIMARY KEY;

-- FOREIGN KEY 추가
ALTER TABLE emp2
ADD CONSTRAINT emp_mgr_fk
    FOREIGN KEY (manager_id)
    REFERENCES emp2(employee_id);

-- NOT NULL은 MODIFY 사용
ALTER TABLE emp2
MODIFY last_name NOT NULL;
```

### 1-2. 제약 조건 삭제

```sql
-- 이름으로 삭제
ALTER TABLE emp2
DROP CONSTRAINT emp_mgr_fk;

-- PRIMARY KEY + 연관 FK 함께 삭제
ALTER TABLE emp2
DROP PRIMARY KEY CASCADE;

-- ONLINE: 삭제 중에도 DML 허용
ALTER TABLE myemp2
DROP CONSTRAINT emp_name_pk ONLINE;
```

### 1-3. ON DELETE 절

외래 키 제약에 부모 행 삭제 시 자식 행 처리 방법을 지정한다.

```sql
-- ON DELETE CASCADE: 부모 삭제 시 자식 행도 함께 삭제
ALTER TABLE dept2
ADD CONSTRAINT dept_lc_fk
    FOREIGN KEY (location_id)
    REFERENCES locations(location_id)
    ON DELETE CASCADE;

-- ON DELETE SET NULL: 부모 삭제 시 자식의 FK 열을 NULL로 설정
ALTER TABLE emp2
ADD CONSTRAINT emp_dt_fk
    FOREIGN KEY (department_id)
    REFERENCES departments(department_id)
    ON DELETE SET NULL;
```

### 1-4. CASCADE CONSTRAINTS — 열 삭제 시 연쇄 제약 삭제

```sql
-- 단일 열 삭제 + 해당 열 관련 제약 조건 모두 삭제
ALTER TABLE emp2
DROP COLUMN employee_id CASCADE CONSTRAINTS;

-- 여러 열 삭제
ALTER TABLE test1
DROP (col1_pk, col2_fk, col1) CASCADE CONSTRAINTS;
```

`CASCADE CONSTRAINTS`가 삭제하는 것:
- 삭제하는 열에 정의된 PK/UK를 참조하는 모든 FK
- 삭제하는 열이 포함된 다중 열 제약 조건

### 1-5. 테이블·열·제약 조건 이름 변경

```sql
-- 테이블 이름 변경
ALTER TABLE marketing RENAME TO new_marketing;

-- 열 이름 변경
ALTER TABLE new_marketing
RENAME COLUMN team_id TO id;

-- 제약 조건 이름 변경
ALTER TABLE new_marketing
RENAME CONSTRAINT mktg_pk TO new_mktg_pk;
```

### 1-6. 제약 조건 비활성화 / 활성화

```sql
-- 비활성화 (단일)
ALTER TABLE emp2
DISABLE CONSTRAINT emp_dt_fk;

-- PK 비활성화 + 연관 FK 자동 비활성화
ALTER TABLE dept2
DISABLE PRIMARY KEY CASCADE;

-- 활성화
ALTER TABLE emp2
ENABLE CONSTRAINT emp_dt_fk;
```

- `ENABLE` 시 기존 데이터가 제약 조건을 모두 만족해야 함
- PK/UK `ENABLE` 시 UNIQUE 인덱스 자동 생성

### 1-7. 제약 조건 상태 (4가지)

| 상태 | 설명 |
|------|------|
| `ENABLE VALIDATE` | 활성화, 기존·신규 데이터 모두 검사 (기본값) |
| `ENABLE NOVALIDATE` | 활성화, 신규 DML만 검사 (기존 데이터 예외) |
| `DISABLE VALIDATE` | 비활성화, DML 불가, 기존 데이터는 유효 |
| `DISABLE NOVALIDATE` | 비활성화, DML 가능, 검사 없음 |

```sql
-- ENABLE NOVALIDATE: 기존 위반 데이터를 그대로 두고 새 위반만 차단
ALTER TABLE dept2
ENABLE NOVALIDATE PRIMARY KEY;
```

### 1-8. 지연 제약 조건 (Deferrable Constraints)

트랜잭션 내에서 제약 검사 시점을 COMMIT 전까지 늦출 수 있다.

```sql
-- 제약 정의 시 지연 가능 지정
ALTER TABLE dept2
ADD CONSTRAINT dept2_id_pk PRIMARY KEY (department_id)
DEFERRABLE INITIALLY DEFERRED;

-- 특정 제약 조건의 검사 시점 변경
SET CONSTRAINTS dept2_id_pk IMMEDIATE;

-- 세션의 모든 제약 조건 검사 시점 변경
ALTER SESSION SET CONSTRAINTS = IMMEDIATE;
```

| 속성 | 설명 |
|------|------|
| `DEFERRABLE` | 지연 가능 상태로 선언 |
| `NOT DEFERRABLE` | 지연 불가 (기본값) |
| `INITIALLY DEFERRED` | 기본적으로 COMMIT 시점에 검사 |
| `INITIALLY IMMEDIATE` | 기본적으로 각 문장 실행 후 즉시 검사 |

---

## 2. DROP TABLE ... PURGE

```sql
-- 휴지통 거치지 않고 즉시 영구 삭제
DROP TABLE emp_new_sal PURGE;
```

- `PURGE` 없이 DROP하면 테이블이 휴지통(Recycle Bin)으로 이동
- `PURGE`를 사용하면 복구 불가능하게 즉시 삭제 + 공간 반환

---

## 3. 임시 테이블 (Temporary Tables)

### 3-1. 임시 테이블의 특징

- 데이터가 트랜잭션 또는 세션 기간 동안만 존재
- 세션마다 데이터는 독립적(private)
- **Global Temporary Table (GTT)** 과 **Private Temporary Table (PTT)** 두 종류

### 3-2. 글로벌 임시 테이블 (Global Temporary Table)

```sql
-- 트랜잭션 기반: COMMIT 시 데이터 삭제
CREATE GLOBAL TEMPORARY TABLE cart
    (n NUMBER, d DATE)
ON COMMIT DELETE ROWS;

-- 세션 기반: 세션 종료 시 데이터 삭제
CREATE GLOBAL TEMPORARY TABLE emp_details
ON COMMIT PRESERVE ROWS;
```

### 3-3. 프라이빗 임시 테이블 (Private Temporary Table)

```sql
-- 트랜잭션 기반: COMMIT 시 테이블 정의도 삭제
CREATE PRIVATE TEMPORARY TABLE ORA$PTT_sales_trans
    (time_id DATE, amt_sold NUMBER(8,2))
ON COMMIT DROP DEFINITION;

-- 세션 기반: 세션 종료 시 테이블 정의 삭제
CREATE PRIVATE TEMPORARY TABLE ORA$PTT_sales_sess
    (time_id DATE, amt_sold NUMBER(8,2))
ON COMMIT PRESERVE DEFINITION;
```

### 3-4. GTT vs PTT 비교

| 특징 | 글로벌(GTT) | 프라이빗(PTT) |
|------|------------|--------------|
| 명명 규칙 | 일반 테이블과 동일 | `ORA$PTT_` 접두사 필수 |
| 테이블 정의 가시성 | 모든 세션 | 생성한 세션만 |
| 테이블 정의 저장 위치 | 디스크(딕셔너리) | 메모리 |
| COMMIT 행동 | DELETE ROWS / PRESERVE ROWS | DROP DEFINITION / PRESERVE DEFINITION |

---

## 4. 외부 테이블 (External Tables)

### 4-1. 외부 테이블이란?

데이터베이스 외부(파일 시스템)에 있는 파일을 Oracle 테이블처럼 조회할 수 있는 기능이다.
- 데이터는 데이터베이스 외부 파일에 저장
- 테이블 정의만 딕셔너리에 저장
- **읽기 전용**: DML 불가 (SELECT만 가능)

### 4-2. DIRECTORY 객체 생성

```sql
-- 외부 파일이 위치한 OS 디렉토리를 가리키는 DIRECTORY 객체 생성
CREATE OR REPLACE DIRECTORY emp_dir
AS '/path/to/emp_dir';

-- 사용자에게 읽기 권한 부여
GRANT READ ON DIRECTORY emp_dir TO ora_21;
```

### 4-3. 외부 테이블 생성 — ORACLE_LOADER

플랫 파일(CSV, 고정 길이 등) 읽기:

```sql
CREATE TABLE oldemp
    (fname CHAR(25), lname CHAR(25))
ORGANIZATION EXTERNAL
(
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY emp_dir
    ACCESS PARAMETERS
    (
        RECORDS DELIMITED BY NEWLINE
        FIELDS (
            fname POSITION (1:20)  CHAR,
            lname POSITION (22:41) CHAR
        )
    )
    LOCATION ('emp.dat')
);
```

### 4-4. 외부 테이블 생성 — ORACLE_DATAPUMP

Oracle 독점 바이너리 형식으로 내보내기/가져오기:

```sql
CREATE TABLE emp_ext
    (employee_id, first_name, last_name)
ORGANIZATION EXTERNAL
(
    TYPE ORACLE_DATAPUMP
    DEFAULT DIRECTORY emp_dir
    LOCATION ('emp1.exp', 'emp2.exp')
)
PARALLEL
AS SELECT employee_id, first_name, last_name
   FROM   employees;
```

### 4-5. 외부 테이블 조회

```sql
SELECT * FROM oldemp;
```

외부 테이블은 일반 테이블처럼 SELECT에 사용 가능하다.

---

## 5. 단원 요약

| 주제 | 핵심 내용 |
|------|-----------|
| 제약 추가 | `ALTER TABLE ADD CONSTRAINT` — FK, NOT NULL(MODIFY) |
| 제약 삭제 | `DROP CONSTRAINT`, `DROP PRIMARY KEY CASCADE`, `ONLINE` |
| ON DELETE | `CASCADE`(자식 삭제) / `SET NULL`(자식 FK를 NULL) |
| CASCADE CONSTRAINTS | 열 삭제 시 관련 제약 조건 함께 삭제 |
| 이름 변경 | `RENAME TO` / `RENAME COLUMN` / `RENAME CONSTRAINT` |
| DISABLE/ENABLE | 제약 비활성화·활성화 — `CASCADE` 옵션 |
| 제약 상태 | ENABLE/DISABLE × VALIDATE/NOVALIDATE 4가지 조합 |
| 지연 제약 | `DEFERRABLE INITIALLY DEFERRED/IMMEDIATE` |
| DROP PURGE | `DROP TABLE … PURGE` — 휴지통 없이 즉시 삭제 |
| GTT | `CREATE GLOBAL TEMPORARY TABLE` — 딕셔너리 저장 |
| PTT | `CREATE PRIVATE TEMPORARY TABLE ORA$PTT_…` — 메모리 저장 |
| 외부 테이블 | `ORGANIZATION EXTERNAL` — 파일 시스템 데이터 읽기, SELECT만 가능 |
