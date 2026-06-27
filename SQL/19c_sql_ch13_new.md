# Oracle Database 19c: SQL Workshop
## Chapter 13 — 시퀀스, 동의어, 인덱스 생성 (Creating Sequences, Synonyms, and Indexes)

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있다:
- 시퀀스를 생성, 유지 관리, 사용한다
- 개인(private) 및 공용(public) 동의어를 생성한다
- 인덱스를 생성하고 유지 관리한다
- 딕셔너리 뷰로 시퀀스·동의어·인덱스 정보를 조회한다

---

## 1. 데이터베이스 객체 개요

| 객체 | 설명 |
|------|------|
| Table | 기본 저장 단위 — 행으로 구성 |
| View | 하나 이상의 테이블에서 데이터를 논리적으로 표현 |
| **Sequence** | 숫자 값을 자동으로 생성 |
| **Index** | 데이터 검색 쿼리의 성능을 향상 |
| **Synonym** | 객체에 대체 이름을 부여 |

---

## 2. 시퀀스 (Sequence)

### 2-1. 시퀀스의 특징

- 공유 가능한 객체(shareable object)
- 자동으로 고유한 번호를 생성
- 기본 키 값 생성에 활용
- 애플리케이션 코드 대체
- 캐시(cache)에 저장되면 접근 속도 향상

### 2-2. CREATE SEQUENCE 구문

```sql
CREATE SEQUENCE [schema.] sequence
[ START WITH     integer      ]
[ INCREMENT BY   integer      ]
[ MAXVALUE       integer | NOMAXVALUE ]
[ MINVALUE       integer | NOMINVALUE ]
[ CYCLE | NOCYCLE                     ]
[ CACHE          integer | NOCACHE   ]
[ ORDER | NOORDER                     ];
```

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `START WITH n` | 시작 값 | 1 |
| `INCREMENT BY n` | 증가량 (음수 가능) | 1 |
| `MAXVALUE n` | 최대값 | NOMAXVALUE (10²⁷) |
| `MINVALUE n` | 최소값 | NOMINVALUE (1) |
| `CYCLE` | 최대/최소값 도달 시 순환 | NOCYCLE |
| `CACHE n` | 메모리에 미리 생성할 값 개수 | 20 |
| `ORDER` | 순서 보장 (RAC 환경) | NOORDER |

### 2-3. 시퀀스 생성 예제

```sql
-- DEPARTMENTS 테이블 기본 키용 시퀀스 생성
CREATE SEQUENCE dept_deptid_seq
    START WITH   280
    INCREMENT BY 10
    MAXVALUE     9999
    NOCACHE
    NOCYCLE;
```

### 2-4. NEXTVAL & CURRVAL 의사열

| 의사열 | 설명 |
|--------|------|
| `seq.NEXTVAL` | 다음 값 반환 — 참조할 때마다 고유 값 반환 |
| `seq.CURRVAL` | 현재 값 반환 — NEXTVAL 이후에만 사용 가능 |

```sql
-- NEXTVAL로 새 부서 삽입
INSERT INTO departments (department_id, department_name, location_id)
VALUES (dept_deptid_seq.NEXTVAL, 'Support', 2500);

-- 현재 값 확인
SELECT dept_deptid_seq.CURRVAL
FROM   dual;
```

### 2-5. SQL 열 기본값으로 시퀀스 사용

시퀀스의 NEXTVAL/CURRVAL을 열의 DEFAULT 값으로 사용할 수 있다:

```sql
CREATE SEQUENCE id_seq START WITH 1;

CREATE TABLE emp (
    id   NUMBER DEFAULT id_seq.NEXTVAL NOT NULL,
    name VARCHAR2(10)
);

INSERT INTO emp (name) VALUES ('John');  -- id=1 자동 할당
INSERT INTO emp (name) VALUES ('Mark');  -- id=2 자동 할당
SELECT * FROM emp;
-- 1  John
-- 2  Mark
```

### 2-6. 캐시(Cache) 시퀀스 값

- 시퀀스 값을 메모리에 미리 생성하여 더 빠르게 접근
- **갭(Gap) 발생 가능 상황:**
  - 롤백(ROLLBACK) 발생
  - 시스템 크래시
  - 같은 시퀀스를 다른 테이블에서 사용

> 시퀀스 값에 갭이 생겨도 NOCYCLE 시퀀스는 고유성을 보장한다.

### 2-7. 시퀀스 수정 (ALTER SEQUENCE)

```sql
ALTER SEQUENCE dept_deptid_seq
    INCREMENT BY 20
    MAXVALUE     999999
    NOCACHE
    NOCYCLE;
```

**수정 지침:**
- 소유자이거나 ALTER 권한이 있어야 함
- 이후에 생성되는 시퀀스 번호에만 영향
- 시작값을 변경하려면 DROP 후 재생성 필요

### 2-8. 시퀀스 삭제

```sql
DROP SEQUENCE dept_deptid_seq;
```

### 2-9. 시퀀스 정보 조회 — USER_SEQUENCES

```sql
DESCRIBE user_sequences;

SELECT sequence_name, min_value, max_value,
       increment_by, last_number
FROM   user_sequences;
```

주요 컬럼:
- `SEQUENCE_NAME`: 시퀀스 이름
- `MIN_VALUE`: 최소값
- `MAX_VALUE`: 최대값
- `INCREMENT_BY`: 증가량
- `LAST_NUMBER`: 다음에 생성될 시퀀스 값 (CACHE 사용 시 캐시된 블록의 끝값)

---

## 3. 동의어 (Synonym)

### 3-1. 동의어의 특징

- 데이터베이스 객체의 **대체 이름**
- 데이터 딕셔너리에 정의만 저장 (별도 스토리지 불필요)
- 기본 객체의 위치와 정체를 숨길 수 있다
- 다른 사용자의 테이블 참조를 단순화

### 3-2. 동의어 생성

```sql
-- 구문
CREATE [PUBLIC] SYNONYM synonym
FOR object;

-- 예제: departments 테이블의 단축 이름
CREATE SYNONYM dept
FOR departments;

-- 다른 사용자 테이블에 동의어 (스키마.객체 형식)
CREATE SYNONYM emp
FOR hr.employees;

-- 공용 동의어 (모든 사용자 접근 가능 — DBA 권한 필요)
CREATE PUBLIC SYNONYM pub_employees
FOR hr.employees;
```

### 3-3. 동의어 사용

```sql
-- 동의어로 테이블 접근
SELECT * FROM dept;          -- departments 대신 사용
SELECT * FROM emp;           -- hr.employees 대신 사용
```

### 3-4. 동의어 삭제

```sql
DROP SYNONYM dept;
DROP PUBLIC SYNONYM pub_employees;  -- PUBLIC 동의어 삭제
```

### 3-5. 동의어 정보 조회 — USER_SYNONYMS

```sql
DESCRIBE user_synonyms;
SELECT * FROM user_synonyms;
```

---

## 4. 인덱스 (Index)

### 4-1. 인덱스의 특징

- 스키마 객체
- Oracle Server가 포인터(pointer)를 사용해 행 검색 속도 향상
- 디스크 I/O 감소
- 인덱스가 걸린 테이블에 종속
- Oracle Server가 자동으로 사용·관리

### 4-2. 인덱스 생성 방식

**자동 생성:**
- PRIMARY KEY 또는 UNIQUE 제약 조건 정의 시 Oracle이 자동으로 UNIQUE 인덱스 생성

**수동 생성:**
- 쿼리 속도 향상을 위해 특정 열에 직접 생성

### 4-3. 인덱스 생성 (CREATE INDEX)

```sql
-- 기본 구문
CREATE [UNIQUE] INDEX index
ON table (column [, column] ...);

-- 예제: EMPLOYEES의 LAST_NAME 열 인덱스
CREATE INDEX emp_last_name_idx
ON employees (last_name);

-- 복합 인덱스 (여러 열)
CREATE INDEX emp_name_idx
ON employees (last_name, first_name);
```

### 4-4. CREATE TABLE과 함께 인덱스 생성

테이블 생성 시 PRIMARY KEY 인덱스를 직접 명명할 수 있다:

```sql
CREATE TABLE new_emp (
    employee_id NUMBER(6)
        PRIMARY KEY USING INDEX
        (CREATE INDEX emp_id_idx ON new_emp(employee_id)),
    first_name  VARCHAR2(20),
    last_name   VARCHAR2(25)
);

-- 인덱스 확인
SELECT index_name, table_name
FROM   user_indexes
WHERE  table_name = 'NEW_EMP';
```

### 4-5. 함수 기반 인덱스 (Function-Based Index)

표현식(함수)을 기반으로 인덱스를 생성한다:

```sql
-- 대소문자 무시 검색을 위한 함수 기반 인덱스
CREATE INDEX upper_dept_name_idx
ON dept2 (UPPER(department_name));

-- 인덱스 활용 쿼리
SELECT *
FROM   dept2
WHERE  UPPER(department_name) = 'SALES';
```

### 4-6. 같은 열 집합에 여러 인덱스 생성

다음 조건이 다를 때 같은 열 집합에 여러 인덱스를 생성할 수 있다:
- 인덱스 유형이 다를 때 (B-tree vs BITMAP)
- 파티셔닝이 다를 때
- 고유성(UNIQUE/NONUNIQUE) 속성이 다를 때

```sql
-- 1. 첫 번째 인덱스 생성
CREATE INDEX emp_id_name_ix1
ON employees (employee_id, first_name);

-- 2. 기존 인덱스 INVISIBLE 처리
ALTER INDEX emp_id_name_ix1 INVISIBLE;

-- 3. 다른 타입의 인덱스 생성 (BITMAP)
CREATE BITMAP INDEX emp_id_name_ix2
ON employees (employee_id, first_name);
```

### 4-7. 인덱스 삭제 (DROP INDEX)

```sql
-- 기본 삭제
DROP INDEX emp_last_name_idx;

-- 소유자이거나 DROP ANY INDEX 권한 필요
```

> DROP INDEX는 인덱스를 데이터 딕셔너리에서 제거한다. 인덱스 삭제 시 관련 테이블 데이터는 영향받지 않는다.

### 4-8. 인덱스 정보 조회

```sql
-- USER_INDEXES: 인덱스 기본 정보
DESCRIBE user_indexes;

SELECT index_name, table_name, uniqueness
FROM   user_indexes
WHERE  table_name = 'EMPLOYEES';

-- USER_IND_COLUMNS: 인덱스가 걸린 열 정보
DESCRIBE user_ind_columns;

SELECT index_name, column_name, table_name
FROM   user_ind_columns
WHERE  index_name = 'EMP_LAST_NAME_IDX';
```

### 4-9. 인덱스 생성 기준

**인덱스가 유용한 경우:**
- 열에 광범위한 값의 범위가 있을 때
- 열에 NULL이 많을 때 (NULL 포함 검색)
- WHERE 절이나 JOIN 조건에서 열이 자주 사용될 때
- 테이블이 크고 쿼리가 행의 2~4% 미만을 조회할 것으로 예상될 때

**인덱스가 불필요한 경우:**
- 테이블이 작을 때
- 쿼리가 테이블 행의 대부분을 조회할 때
- 열이 WHERE 절에 자주 사용되지 않을 때

---

## 5. 딕셔너리 뷰 요약

| 뷰 이름 | 제공 정보 |
|---------|-----------|
| `USER_SEQUENCES` | 시퀀스 정의 (시작값, 증가량, 최대/최소, 캐시) |
| `USER_SYNONYMS` | 동의어 정의 (대상 테이블/객체) |
| `USER_INDEXES` | 인덱스 기본 정보 (이름, 테이블, 고유성) |
| `USER_IND_COLUMNS` | 인덱스가 적용된 열 정보 |
