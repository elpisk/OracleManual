# Oracle Database 19c: SQL Workshop
## Chapter 12 — 데이터 딕셔너리 뷰 소개 (Introduction to Data Dictionary Views)

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있다:
- 데이터 딕셔너리 뷰를 사용하여 객체 정보를 조회한다
- 다양한 데이터 딕셔너리 뷰를 쿼리한다

---

## 1. 데이터 딕셔너리란?

Oracle 데이터베이스는 모든 객체(테이블, 뷰, 인덱스, 제약 조건 등)에 대한 메타데이터를 내부적으로 관리한다. 이 메타데이터가 저장된 곳이 **데이터 딕셔너리(Data Dictionary)**이다.

### 1-1. 데이터 딕셔너리의 구성

```
Oracle Server
├── 비즈니스 데이터 테이블
│   ├── EMPLOYEES
│   ├── DEPARTMENTS
│   ├── LOCATIONS
│   └── JOB_HISTORY ...
│
└── 데이터 딕셔너리 뷰
    ├── DICTIONARY
    ├── USER_OBJECTS
    ├── USER_TABLES
    ├── USER_TAB_COLUMNS
    └── ...
```

데이터 딕셔너리는 두 계층으로 구성된다:
- **베이스 테이블(Base Tables):** Oracle이 내부적으로 관리하는 암호화된 테이블
- **사용자 접근 가능 뷰(User-Accessible Views):** 사용자가 쿼리할 수 있는 뷰

---

## 2. 데이터 딕셔너리 뷰 접두사

뷰 이름에 붙는 접두사로 접근 범위를 구분한다:

| 접두사 | 목적 |
|--------|------|
| `USER_` | 자신이 소유한 객체만 조회 (자신의 스키마) |
| `ALL_`  | 접근 권한이 있는 모든 객체 조회 |
| `DBA_`  | 모든 사용자의 스키마 조회 (DBA 전용) |
| `V$`    | 성능 관련 동적 데이터 조회 |

---

## 3. DICTIONARY 뷰

`DICTIONARY` 뷰는 모든 데이터 딕셔너리 뷰의 이름과 설명을 포함한다.

```sql
-- 데이터 딕셔너리 뷰 구조 확인
DESCRIBE DICTIONARY

-- 특정 뷰 검색
SELECT *
FROM   dictionary
WHERE  table_name = 'USER_OBJECTS';

-- 이름에 'TABLE'이 포함된 뷰 검색
SELECT table_name, comments
FROM   dictionary
WHERE  table_name LIKE '%TABLE%'
ORDER BY table_name;
```

---

## 4. USER_OBJECTS / ALL_OBJECTS 뷰

### 4-1. USER_OBJECTS

자신이 소유한 모든 객체 목록을 조회한다:

```sql
SELECT object_name, object_type, created, status
FROM   user_objects
ORDER BY object_type;
```

제공 정보:
- 객체 이름(`OBJECT_NAME`)
- 객체 유형(`OBJECT_TYPE`): TABLE, VIEW, INDEX, SEQUENCE 등
- 생성일(`CREATED`)
- 최종 수정일(`LAST_DDL_TIME`)
- 상태(`STATUS`): VALID 또는 INVALID

```sql
-- 특정 유형의 객체만 조회
SELECT object_name, created
FROM   user_objects
WHERE  object_type = 'TABLE';

-- 오늘 생성된 객체 조회
SELECT object_name, object_type
FROM   user_objects
WHERE  created >= TRUNC(SYSDATE);
```

### 4-2. ALL_OBJECTS

접근 권한이 있는 모든 사용자의 객체를 조회한다:

```sql
SELECT owner, object_name, object_type
FROM   all_objects
WHERE  object_type = 'TABLE'
ORDER BY owner, object_name;
```

---

## 5. 테이블 정보 조회 — USER_TABLES

`USER_TABLES` 뷰는 자신이 소유한 테이블의 상세 정보를 제공한다:

```sql
-- 구조 확인
DESCRIBE user_tables

-- 테이블 목록 조회
SELECT table_name
FROM   user_tables;

-- 상세 정보 조회
SELECT table_name, num_rows, blocks, avg_row_len, status
FROM   user_tables
ORDER BY table_name;
```

주요 컬럼:
- `TABLE_NAME`: 테이블 이름
- `NUM_ROWS`: 행 수 (통계 분석 후 갱신됨)
- `BLOCKS`: 사용 중인 블록 수
- `STATUS`: VALID / INVALID
- `READ_ONLY`: YES / NO

---

## 6. 열 정보 조회 — USER_TAB_COLUMNS

`USER_TAB_COLUMNS` 뷰는 테이블의 각 열에 대한 정보를 제공한다:

```sql
-- 구조 확인
DESCRIBE user_tab_columns

-- EMPLOYEES 테이블의 열 정보 조회
SELECT column_name, data_type, data_length,
       data_precision, data_scale, nullable
FROM   user_tab_columns
WHERE  table_name = 'EMPLOYEES';
```

주요 컬럼:
- `COLUMN_NAME`: 열 이름
- `DATA_TYPE`: 데이터 타입 (VARCHAR2, NUMBER, DATE 등)
- `DATA_LENGTH`: 최대 길이(바이트)
- `DATA_PRECISION`: NUMBER 타입의 전체 자릿수
- `DATA_SCALE`: NUMBER 타입의 소수점 이하 자릿수
- `NULLABLE`: Y(NULL 허용) / N(NULL 불허)
- `DATA_DEFAULT`: 기본값

---

## 7. 제약 조건 정보 조회

### 7-1. USER_CONSTRAINTS

제약 조건의 정의 정보를 조회한다:

```sql
-- 구조 확인
DESCRIBE user_constraints

-- EMPLOYEES 테이블의 제약 조건 조회
SELECT constraint_name, constraint_type,
       search_condition, r_constraint_name,
       delete_rule, status
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES';
```

`CONSTRAINT_TYPE` 값의 의미:

| 값 | 의미 |
|----|------|
| `C` | CHECK 제약 조건 (NOT NULL 포함) |
| `P` | PRIMARY KEY |
| `U` | UNIQUE |
| `R` | FOREIGN KEY (Referential Integrity) |

주요 컬럼:
- `CONSTRAINT_NAME`: 제약 조건 이름
- `CONSTRAINT_TYPE`: 유형 (C/P/U/R)
- `SEARCH_CONDITION`: CHECK 제약 조건의 조건식
- `R_CONSTRAINT_NAME`: 참조되는 부모 제약 조건 이름 (FK)
- `DELETE_RULE`: CASCADE / SET NULL / NO ACTION
- `STATUS`: ENABLED / DISABLED

### 7-2. USER_CONS_COLUMNS

제약 조건이 정의된 **열 정보**를 조회한다:

```sql
-- 구조 확인
DESCRIBE user_cons_columns

-- EMPLOYEES 테이블의 제약 조건 열 정보
SELECT constraint_name, column_name
FROM   user_cons_columns
WHERE  table_name = 'EMPLOYEES';
```

### 7-3. 두 뷰 조인으로 완전한 정보 조회

```sql
SELECT c.constraint_name,
       c.constraint_type,
       c.status,
       cc.column_name,
       c.search_condition
FROM   user_constraints  c
JOIN   user_cons_columns cc
    ON c.constraint_name = cc.constraint_name
   AND c.table_name      = cc.table_name
WHERE  c.table_name = 'EMPLOYEES'
ORDER BY c.constraint_type, cc.position;
```

---

## 8. 테이블 및 열에 주석 추가

### 8-1. 주석 추가 (COMMENT ON)

`COMMENT` 문을 사용하여 테이블 또는 열에 설명을 추가한다:

```sql
-- 테이블에 주석 추가
COMMENT ON TABLE employees
IS 'Employee Information';

-- 열에 주석 추가
COMMENT ON COLUMN employees.first_name
IS 'First name of the employee';

COMMENT ON COLUMN employees.employee_id
IS 'Primary key of employees table';
```

### 8-2. 주석 조회 뷰

| 뷰 이름 | 설명 |
|---------|------|
| `USER_TAB_COMMENTS` | 자신이 소유한 테이블/뷰의 주석 |
| `ALL_TAB_COMMENTS` | 접근 가능한 모든 테이블/뷰의 주석 |
| `USER_COL_COMMENTS` | 자신이 소유한 테이블의 열 주석 |
| `ALL_COL_COMMENTS` | 접근 가능한 모든 테이블의 열 주석 |

```sql
-- 테이블 주석 조회
SELECT table_name, table_type, comments
FROM   user_tab_comments
WHERE  table_name = 'EMPLOYEES';

-- 열 주석 조회
SELECT column_name, comments
FROM   user_col_comments
WHERE  table_name = 'EMPLOYEES';
```

### 8-3. 주석 삭제

빈 문자열을 입력하면 주석이 삭제된다:

```sql
COMMENT ON TABLE employees IS '';
COMMENT ON COLUMN employees.first_name IS '';
```

---

## 9. 주요 데이터 딕셔너리 뷰 요약

| 뷰 | 제공 정보 |
|----|-----------|
| `DICTIONARY` | 모든 딕셔너리 뷰의 이름과 설명 |
| `USER_OBJECTS` | 자신이 소유한 모든 객체 |
| `ALL_OBJECTS` | 접근 가능한 모든 객체 |
| `USER_TABLES` | 자신이 소유한 테이블 |
| `USER_TAB_COLUMNS` | 테이블 열 정보 |
| `USER_CONSTRAINTS` | 제약 조건 정의 |
| `USER_CONS_COLUMNS` | 제약 조건이 적용된 열 |
| `USER_TAB_COMMENTS` | 테이블 주석 |
| `USER_COL_COMMENTS` | 열 주석 |

---

## 10. 실전 활용 예제

```sql
-- 1. 내 스키마의 모든 테이블 이름 조회
SELECT table_name FROM user_tables ORDER BY table_name;

-- 2. 특정 테이블의 열 정보 전체 조회
SELECT column_name, data_type, nullable, data_default
FROM   user_tab_columns
WHERE  table_name = 'DEPARTMENTS'
ORDER BY column_id;

-- 3. FK가 있는 테이블과 참조 테이블 조회
SELECT c.table_name       AS 자식_테이블,
       cc.column_name     AS FK_열,
       c.r_constraint_name AS 참조_PK
FROM   user_constraints  c
JOIN   user_cons_columns cc ON c.constraint_name = cc.constraint_name
WHERE  c.constraint_type = 'R'
ORDER BY c.table_name;

-- 4. NULL 허용 열이 있는 테이블 조회
SELECT table_name, column_name
FROM   user_tab_columns
WHERE  nullable = 'Y'
ORDER BY table_name, column_id;

-- 5. 오늘 생성/수정된 객체 조회
SELECT object_name, object_type, last_ddl_time
FROM   user_objects
WHERE  TRUNC(last_ddl_time) = TRUNC(SYSDATE)
ORDER BY last_ddl_time DESC;
```
