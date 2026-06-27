# Oracle Database 19c: SQL Workshop
## Chapter 11 — 데이터 정의 언어(DDL) 소개 (Introduction to Data Definition Language)

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있다:
- 주요 데이터베이스 객체를 분류한다
- 테이블 구조를 검토한다
- 열에 사용할 수 있는 데이터 타입을 나열한다
- 간단한 테이블을 생성한다
- 테이블 생성 시 제약 조건이 어떻게 생성되는지 설명한다

---

## 1. 데이터베이스 객체

| 객체 | 설명 |
|------|------|
| **Table** (테이블) | 기본 저장 단위, 행으로 구성 |
| **View** (뷰) | 하나 이상의 테이블에서 데이터 하위 집합을 논리적으로 표현 |
| **Sequence** (시퀀스) | 숫자 값을 자동으로 생성 |
| **Index** (인덱스) | 일부 쿼리의 성능을 향상 |
| **Synonym** (동의어) | 객체에 대체 이름을 부여 |

---

## 2. 테이블 및 열 명명 규칙

테이블 이름과 열 이름은 다음 규칙을 따라야 한다:
- **문자로 시작**해야 한다
- **1~30자** 길이여야 한다
- **A~Z, a~z, 0~9, _, $, #** 문자만 포함할 수 있다
- 동일한 사용자가 소유한 다른 객체와 **이름이 중복되지 않아야** 한다
- Oracle **예약어**를 사용할 수 없다

---

## 3. CREATE TABLE 문

### 3-1. 필요 조건

- `CREATE TABLE` 권한
- 스토리지 공간

### 3-2. 기본 구문

```sql
CREATE TABLE [schema.]table
(column datatype [DEFAULT expr][, ...]);
```

지정해야 하는 항목:
- 테이블 이름
- 열 이름, 열 데이터 타입, 열 크기

### 3-3. 테이블 생성 예제

```sql
CREATE TABLE dept
(deptno      NUMBER(2),
 dname       VARCHAR2(14),
 loc         VARCHAR2(13),
 create_date DATE DEFAULT SYSDATE);

-- 테이블 구조 확인
DESCRIBE dept
```

### 3-4. DEFAULT 옵션

열에 기본값을 지정하려면 DEFAULT 옵션을 사용한다:

```sql
CREATE TABLE hire_dates
(id        NUMBER(8),
 hire_date DATE DEFAULT SYSDATE);
```

> - 리터럴 값, 표현식, SQL 함수는 합법적인 기본값
> - 다른 열 이름이나 의사열(pseudocolumn)은 불법적인 기본값
> - 기본 데이터 타입은 열 데이터 타입과 일치해야 함

---

## 4. 데이터 타입

### 4-1. 기본 데이터 타입

| 데이터 타입 | 설명 |
|-------------|------|
| `VARCHAR2(size)` | 가변 길이 문자 데이터 (최대 4000바이트) |
| `CHAR(size)` | 고정 길이 문자 데이터 (기본값 1, 최대 2000바이트) |
| `NUMBER(p, s)` | 가변 길이 숫자 데이터 (p: 전체 자릿수, s: 소수점 이하 자릿수) |
| `DATE` | 날짜 및 시간 값 |
| `LONG` | 가변 길이 문자 데이터 (최대 2GB) |
| `CLOB` | 최대 (4GB - 1) × DB_BLOCK_SIZE |
| `RAW`/`LONG RAW` | 원시 이진 데이터 |
| `BLOB` | 최대 (4GB - 1) × DB_BLOCK_SIZE (8TB~128TB) |
| `BFILE` | 외부 파일에 저장된 이진 데이터 (최대 4GB) |
| `ROWID` | 테이블에서 행의 고유 주소를 나타내는 base-64 숫자 시스템 |

### 4-2. 날짜/시간 데이터 타입

| 데이터 타입 | 설명 |
|-------------|------|
| `TIMESTAMP` | 소수 초를 포함한 날짜 |
| `INTERVAL YEAR TO MONTH` | 연도와 월 단위의 간격 |
| `INTERVAL DAY TO SECOND` | 일, 시간, 분, 초 단위의 간격 |

---

## 5. 제약 조건 (Constraints)

제약 조건은 테이블 수준에서 규칙을 적용한다. 데이터베이스의 일관성과 무결성을 보장한다.

### 5-1. 제약 조건 유형

| 제약 조건 | 설명 |
|-----------|------|
| `NOT NULL` | 해당 열에 NULL 값 불허 |
| `UNIQUE` | 열의 모든 값이 고유해야 함 |
| `PRIMARY KEY` | 행을 고유하게 식별 (NOT NULL + UNIQUE) |
| `FOREIGN KEY` | 참조 무결성 유지 |
| `CHECK` | 각 행이 만족해야 하는 조건 정의 |

### 5-2. 제약 조건 지침

- 제약 조건에 이름을 직접 지정하거나, 지정하지 않으면 Oracle이 `SYS_Cn` 형식으로 자동 생성
- 테이블 생성 시 또는 생성 후에 추가 가능
- **열 수준(Column Level)** 또는 **테이블 수준(Table Level)**에서 정의 가능
- 데이터 딕셔너리에서 조회 가능

### 5-3. 제약 조건 구문

```sql
-- 열 수준 제약 조건
CREATE TABLE [schema.]table (
    column datatype [DEFAULT expr] [CONSTRAINT constraint_name] constraint_type,
    ...
    [CONSTRAINT constraint_name] constraint_type (column, ...)
);
```

### 5-4. NOT NULL 제약 조건

해당 열에 NULL 값을 허용하지 않는다:

```sql
CREATE TABLE employees (
    employee_id NUMBER(6),
    last_name   VARCHAR2(25) CONSTRAINT emp_last_name_nn NOT NULL,
    hire_date   DATE         NOT NULL,
    ...
);
```

### 5-5. UNIQUE 제약 조건

열 내의 모든 값이 고유해야 한다 (NULL은 허용):

```sql
-- 테이블 수준에서 정의
CREATE TABLE employees (
    employee_id    NUMBER(6),
    last_name      VARCHAR2(25) NOT NULL,
    email          VARCHAR2(25),
    ...
    CONSTRAINT emp_email_uk UNIQUE(email)
);
```

### 5-6. PRIMARY KEY 제약 조건

- 행을 고유하게 식별
- NULL 불허 + 고유해야 함
- 테이블당 하나만 존재 가능

```sql
-- 열 수준
CREATE TABLE employees (
    employee_id NUMBER(6) CONSTRAINT emp_emp_id_pk PRIMARY KEY,
    first_name  VARCHAR2(20),
    ...
);

-- 테이블 수준
CREATE TABLE employees (
    employee_id NUMBER(6),
    first_name  VARCHAR2(20),
    ...
    CONSTRAINT emp_emp_id_pk PRIMARY KEY (employee_id)
);
```

### 5-7. FOREIGN KEY 제약 조건

참조 무결성을 유지한다. 자식 테이블의 열이 부모 테이블의 기본 키를 참조한다:

```sql
CREATE TABLE employees (
    employee_id    NUMBER(6),
    last_name      VARCHAR2(25) NOT NULL,
    ...
    department_id  NUMBER(4),
    CONSTRAINT emp_dept_fk FOREIGN KEY (department_id)
        REFERENCES departments(department_id),
    CONSTRAINT emp_email_uk UNIQUE(email)
);
```

**FOREIGN KEY 키워드:**

| 키워드 | 설명 |
|--------|------|
| `FOREIGN KEY` | 자식 테이블의 열을 테이블 제약 수준에서 정의 |
| `REFERENCES` | 부모 테이블과 열을 식별 |
| `ON DELETE CASCADE` | 부모 테이블의 행 삭제 시 자식 행도 자동 삭제 |
| `ON DELETE SET NULL` | 부모 테이블의 행 삭제 시 자식 FK 값을 NULL로 변환 |

### 5-8. CHECK 제약 조건

각 행이 만족해야 하는 조건을 정의한다:

```sql
-- 급여가 0보다 커야 함
..., salary NUMBER(2)
    CONSTRAINT emp_salary_min CHECK (salary > 0), ...
```

> - 다른 테이블의 열을 참조할 수 없다
> - SYSDATE, USER 같은 의사열도 사용 불가

### 5-9. 종합 CREATE TABLE 예제

```sql
CREATE TABLE teach_emp (
    empno    NUMBER(5)    PRIMARY KEY,
    ename    VARCHAR2(15) NOT NULL,
    job      VARCHAR2(10),
    mgr      NUMBER(5),
    hiredate DATE         DEFAULT (SYSDATE),
    photo    BLOB,
    sal      NUMBER(7,2),
    deptno   NUMBER(3)    NOT NULL,
    CONSTRAINT admin_dept_fkey FOREIGN KEY (deptno)
        REFERENCES departments(department_id)
);
```

### 5-10. 제약 조건 위반 예시

```sql
-- FOREIGN KEY 위반: department_id 55는 존재하지 않음
UPDATE employees
SET    department_id = 55
WHERE  department_id = 110;
-- ORA-02291: integrity constraint violated - parent key not found

-- PRIMARY KEY 참조 삭제 불가
DELETE FROM departments
WHERE  department_id = 60;
-- ORA-02292: integrity constraint violated - child record found
```

---

## 6. 서브쿼리를 사용한 테이블 생성

CREATE TABLE 문과 AS subquery 옵션을 결합하여 테이블을 생성하고 행을 삽입한다:

```sql
CREATE TABLE table
[(column, column...)]
AS subquery;
```

```sql
-- 부서 80 사원 정보로 새 테이블 생성
CREATE TABLE dept80
AS
SELECT employee_id, last_name, salary*12 ANNSAL, hire_date
FROM   employees
WHERE  department_id = 80;

-- 구조 확인
DESCRIBE dept80;
```

> - 지정한 열 개수와 서브쿼리 열 개수가 일치해야 한다
> - 제약 조건(NOT NULL 제외)은 복사되지 않는다
> - 데이터는 복사된다 (WHERE 절로 필터 가능)

---

## 7. ALTER TABLE 문

기존 테이블을 수정할 때 사용한다.

**ALTER TABLE로 수행할 수 있는 작업:**
- 새 열 추가
- 기존 열 정의 수정
- 새 열에 기본값 정의
- 열 삭제
- 열 이름 변경
- 테이블을 읽기 전용 상태로 변경

### 7-1. 열 추가 (ADD)

```sql
ALTER TABLE dept80
ADD (job_id VARCHAR2(9));
-- 새 열은 마지막 열이 됨
```

### 7-2. 열 수정 (MODIFY)

```sql
ALTER TABLE dept80
MODIFY (last_name VARCHAR2(30));
-- 열의 데이터 타입, 크기, 기본값 변경 가능
```

> - 기본값 변경은 이후 삽입되는 행에만 영향
> - 기존 데이터와 호환되어야 함

### 7-3. 열 삭제 (DROP)

```sql
ALTER TABLE dept80
DROP (job_id);
```

### 7-4. SET UNUSED 옵션

열을 즉시 삭제하지 않고 미사용으로 표시한다 (대형 테이블에서 성능 이점):

```sql
-- 열을 미사용으로 표시
ALTER TABLE dept80
SET UNUSED (job_id);
-- 또는
ALTER TABLE dept80
SET UNUSED COLUMN job_id;

-- 미사용 열 실제 삭제 (별도로 실행)
ALTER TABLE dept80
DROP UNUSED COLUMNS;
```

> - `ONLINE` 키워드: 열을 UNUSED로 표시하는 동안 DML 작업 허용

### 7-5. 읽기 전용 테이블

```sql
-- 읽기 전용 모드 (DDL, DML 변경 불가)
ALTER TABLE employees READ ONLY;

-- 테이블 유지 보수 작업 수행 ...

-- 읽기/쓰기 모드로 복원
ALTER TABLE employees READ WRITE;
```

---

## 8. DROP TABLE 문

테이블을 삭제한다:

```sql
DROP TABLE dept80;
```

**동작:**
- 테이블을 **휴지통(Recycle Bin)**으로 이동
- `PURGE` 절을 지정하면 테이블과 모든 데이터를 즉시 완전히 제거
- 종속 객체를 무효화하고 테이블의 객체 권한 제거

```sql
-- 즉시 완전 삭제 (Recycle Bin에 남기지 않음)
DROP TABLE dept80 PURGE;
```

---

## 9. DDL 문 요약

| DDL 문 | 기능 |
|--------|------|
| `CREATE TABLE` | 새 테이블 생성 |
| `ALTER TABLE ADD` | 열 추가 |
| `ALTER TABLE MODIFY` | 열 정의 수정 |
| `ALTER TABLE DROP` | 열 삭제 |
| `ALTER TABLE SET UNUSED` | 열을 미사용으로 표시 |
| `ALTER TABLE READ ONLY/WRITE` | 읽기 전용/읽기·쓰기 모드 전환 |
| `DROP TABLE` | 테이블 삭제 (Recycle Bin으로 이동) |
| `DROP TABLE ... PURGE` | 테이블 즉시 완전 삭제 |
