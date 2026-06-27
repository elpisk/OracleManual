# Oracle Database 19c: SQL Workshop
## Chapter 11 — 데이터 정의 언어(DDL) 소개 | SQL 실습 문제 모범답안

---

## Group 1. CREATE TABLE 기초 실습 모범답안 (1~6번)

---

**[1번] 답**

```sql
CREATE TABLE my_departments (
    dept_id   NUMBER(4)    PRIMARY KEY,
    dept_name VARCHAR2(30) NOT NULL,
    location  VARCHAR2(50) DEFAULT 'Seoul'
);
```

---

**[2번] 답**

```sql
CREATE TABLE my_employees (
    emp_id     NUMBER(6)    PRIMARY KEY,
    first_name VARCHAR2(20),
    last_name  VARCHAR2(25) NOT NULL,
    email      VARCHAR2(25) UNIQUE NOT NULL,
    hire_date  DATE         DEFAULT SYSDATE,
    salary     NUMBER(8,2)  CHECK (salary > 0),
    dept_id    NUMBER(4)    REFERENCES my_departments(dept_id)
);
```

> **참고:** `my_employees`는 `my_departments`를 참조하므로, `my_departments`를 먼저 생성해야 한다.

---

**[3번] 답**

```sql
DESCRIBE my_employees;
```

예상 출력:

```
 Name          Null?    Type
 ------------- -------- ---------------
 EMP_ID        NOT NULL NUMBER(6)
 FIRST_NAME             VARCHAR2(20)
 LAST_NAME     NOT NULL VARCHAR2(25)
 EMAIL         NOT NULL VARCHAR2(25)
 HIRE_DATE               DATE
 SALARY                  NUMBER(8,2)
 DEPT_ID                 NUMBER(4)
```

---

**[4번] 답**

```sql
CREATE TABLE projects (
    project_id   NUMBER(5)    CONSTRAINT proj_pk PRIMARY KEY,
    project_name VARCHAR2(50) CONSTRAINT proj_name_nn NOT NULL,
    budget       NUMBER(12,2) CONSTRAINT proj_budget_ck CHECK (budget >= 0),
    status       VARCHAR2(20) CONSTRAINT proj_status_ck CHECK (status IN ('PLANNING','ACTIVE','CLOSED')),
    start_date   DATE         DEFAULT SYSDATE
);
```

---

**[5번] 답**

```sql
CREATE TABLE dept80_copy AS
SELECT employee_id, last_name, salary, hire_date
FROM   employees
WHERE  department_id = 80;

-- 행 수 확인
SELECT COUNT(*) FROM dept80_copy;
-- 결과: 34 (부서 80 사원 수)
```

---

**[6번] 답**

```sql
CREATE TABLE empty_emp AS
SELECT * FROM employees WHERE 1=2;

-- 확인
SELECT COUNT(*) FROM empty_emp;
-- 결과: 0 (데이터 없음)

DESCRIBE empty_emp;
-- EMPLOYEES와 동일한 구조
```

> `WHERE 1=2`: 항상 거짓 → 데이터 없이 구조만 복사.  
> **주의:** NOT NULL 이외의 제약 조건(PK, UNIQUE, FK 등)은 복사되지 않는다.

---

## Group 2. 제약 조건 실습 모범답안 (7~12번)

---

**[7번] 답**

```sql
INSERT INTO my_departments VALUES (10, 'Sales', 'Busan');
INSERT INTO my_departments VALUES (20, 'HR', 'Seoul');

INSERT INTO my_departments VALUES (10, 'IT', 'Daejeon');
-- ORA-00001: unique constraint (USER.SYS_Cn) violated
```

**오류 원인:** `dept_id`가 PRIMARY KEY로 정의되어 있어 값이 고유해야 함.  
dept_id=10이 이미 존재하므로 중복 삽입 불가.

---

**[8번] 답**

```sql
INSERT INTO my_employees (emp_id, last_name, email, dept_id)
VALUES (1, 'Kim', 'SKIM', 99);
-- ORA-02291: integrity constraint violated - parent key not found
```

**오류 원인:** `dept_id=99`는 `my_departments` 테이블에 존재하지 않음.  
FOREIGN KEY 제약 조건에 의해 참조 무결성 위반.

---

**[9번] 답**

```sql
INSERT INTO my_departments VALUES (30, 'Finance', 'Seoul');
INSERT INTO my_employees (emp_id, last_name, email, salary, dept_id)
VALUES (1, 'Park', 'SPARK', 5000, 30);

UPDATE my_employees SET salary = -100 WHERE emp_id = 1;
-- ORA-02290: check constraint violated
```

**오류 원인:** `CHECK (salary > 0)` 제약 조건에 의해 음수 salary 불가.

---

**[10번] 답**

```sql
INSERT INTO my_employees (emp_id, last_name, email, dept_id)
VALUES (2, 'Lee', 'SPARK', 30);
-- ORA-00001: unique constraint violated
```

**오류 원인:** `email` 열에 UNIQUE 제약 조건이 있어 'SPARK'가 이미 존재하므로 중복 불가.  
UNIQUE는 NULL은 허용하지만 같은 NULL이 여러 행에 있어도 위반으로 보지 않는다.

---

**[11번] 답**

```sql
-- parent_id=1 삭제
DELETE FROM cascade_parent WHERE parent_id = 1;
-- 1 row deleted.

-- cascade_child 확인
SELECT * FROM cascade_child;
```

예상 결과:
```
CHILD_ID  PARENT_ID
--------  ---------
103       2
```

**설명:** `ON DELETE CASCADE` 옵션으로 인해 parent_id=1을 참조하던 child_id 101, 102가 **자동으로 함께 삭제**됨.  
parent_id=2를 참조하는 child_id=103은 유지됨.

---

**[12번] 답**

```sql
-- parent_id=2 삭제
DELETE FROM cascade_parent WHERE parent_id = 2;
-- 1 row deleted.

-- setnull_child 확인
SELECT * FROM setnull_child;
```

예상 결과:
```
CHILD_ID  PARENT_ID
--------  ---------
201       (null)
202       (null)
```

**설명:** `ON DELETE SET NULL` 옵션으로 인해 parent_id=2를 참조하던 행들의 parent_id가 **NULL로 변경**됨.  
행 자체는 삭제되지 않고 유지됨.

> **비교 정리:**
> | 옵션 | 부모 삭제 시 자식 처리 |
> |------|----------------------|
> | 기본 (옵션 없음) | 오류 — 삭제 불가 |
> | ON DELETE CASCADE | 자식 행 자동 삭제 |
> | ON DELETE SET NULL | 자식 FK 값을 NULL로 변경 |

---

## Group 3. ALTER TABLE 실습 모범답안 (13~18번)

---

**[13번] 답**

```sql
ALTER TABLE dept80_copy
ADD (job_id VARCHAR2(10) DEFAULT 'UNKNOWN');

DESCRIBE dept80_copy;
```

예상 출력 (마지막에 job_id 추가됨):
```
 Name          Null?    Type
 ------------- -------- ---------------
 EMPLOYEE_ID            NUMBER(6)
 LAST_NAME              VARCHAR2(25)
 SALARY                 NUMBER(8,2)
 HIRE_DATE              DATE
 JOB_ID                 VARCHAR2(10)
```

---

**[14번] 답**

```sql
ALTER TABLE dept80_copy
MODIFY (salary NUMBER(10, 2));
```

> **성공 조건:** `NUMBER(8,2)` → `NUMBER(10,2)` — 크기 확장이므로 항상 성공.

---

**[15번] 답**

```sql
-- 데이터 채우기
UPDATE dept80_copy SET job_id = 'SA_REP';

-- VARCHAR2(5)로 축소 시도
ALTER TABLE dept80_copy
MODIFY (job_id VARCHAR2(5));
-- ORA-01441: cannot decrease column length because some value is too large
```

**설명:** `job_id`에 'SA_REP'(6자)가 저장되어 있어 VARCHAR2(5)로 줄이면 기존 데이터 손실 → 오류 발생.  
데이터를 먼저 삭제하거나 크기 이내의 데이터만 있을 때 축소 가능.

---

**[16번] 답**

```sql
-- 1단계: commission_pct 열 추가
ALTER TABLE dept80_copy
ADD (commission_pct NUMBER(4,2));

DESCRIBE dept80_copy;
-- commission_pct 열 확인됨

-- 2단계: SET UNUSED로 표시
ALTER TABLE dept80_copy
SET UNUSED (commission_pct);

DESCRIBE dept80_copy;
-- commission_pct가 보이지 않음 (미사용 상태)

-- 3단계: 실제 삭제
ALTER TABLE dept80_copy
DROP UNUSED COLUMNS;

DESCRIBE dept80_copy;
-- commission_pct가 완전히 제거됨
```

---

**[17번] 답**

```sql
ALTER TABLE my_departments
DROP (location);

DESCRIBE my_departments;
```

예상 출력:
```
 Name          Null?    Type
 ------------- -------- ---------------
 DEPT_ID       NOT NULL NUMBER(4)
 DEPT_NAME     NOT NULL VARCHAR2(30)
```

---

**[18번] 답**

```sql
ALTER TABLE dept80_copy
RENAME COLUMN job_id TO position_id;

DESCRIBE dept80_copy;
-- JOB_ID → POSITION_ID로 변경됨
```

---

## Group 4. 읽기 전용 테이블 및 DROP TABLE 실습 모범답안 (19~24번)

---

**[19번] 답**

```sql
-- 1. 읽기 전용 설정
ALTER TABLE dept80_copy READ ONLY;

-- 2. DML 시도
UPDATE dept80_copy SET salary = 9999 WHERE ROWNUM = 1;
-- ORA-12081: update operation not allowed on table "HR"."DEPT80_COPY"
```

**오류 원인:** READ ONLY 상태에서는 DML(INSERT/UPDATE/DELETE) 불가.

```sql
-- 3. 읽기/쓰기 모드 복원
ALTER TABLE dept80_copy READ WRITE;

-- 4. DML 재시도 (성공)
UPDATE dept80_copy SET salary = 9999 WHERE ROWNUM = 1;
-- 1 row updated.
ROLLBACK;
```

---

**[20번] 답**

```sql
SELECT table_name, status, read_only
FROM   user_tables
WHERE  table_name IN ('MY_DEPARTMENTS', 'MY_EMPLOYEES', 'DEPT80_COPY', 'PROJECTS');
```

예상 출력:
```
TABLE_NAME        STATUS  READ_ONLY
----------------- ------- ---------
MY_DEPARTMENTS    VALID   NO
MY_EMPLOYEES      VALID   NO
DEPT80_COPY       VALID   NO
PROJECTS          VALID   NO
```

> READ ONLY 상태 시 READ_ONLY 컬럼이 'YES'로 표시됨.

---

**[21번] 답**

```sql
-- 1. 데이터 삽입 및 확인
INSERT INTO projects VALUES (1, 'Alpha Project', 1000000, 'ACTIVE', SYSDATE);
COMMIT;
SELECT * FROM projects;

-- 2. DROP
DROP TABLE projects;

-- 3. Recycle Bin 확인
SELECT object_name, original_name, type
FROM   recyclebin
WHERE  original_name = 'PROJECTS';
-- BIN$xxxxx==$0  PROJECTS  TABLE

-- 4. FLASHBACK으로 복구
FLASHBACK TABLE projects TO BEFORE DROP;

-- 5. 복구 확인
SELECT * FROM projects;
-- 1  Alpha Project  1000000  ACTIVE  [날짜]
```

> **참고:** FLASHBACK TABLE은 Recycle Bin이 활성화된 환경에서만 사용 가능.

---

**[22번] 답**

```sql
-- PURGE로 삭제
DROP TABLE empty_emp PURGE;

-- Recycle Bin 확인
SELECT object_name, original_name
FROM   recyclebin
WHERE  original_name = 'EMPTY_EMP';
-- 0 rows selected. (Recycle Bin에 없음)
```

> **PURGE 옵션:** 테이블이 Recycle Bin을 거치지 않고 즉시 완전 삭제 → 복구 불가.

---

**[23번] 답**

```sql
SELECT c.constraint_name,
       c.constraint_type,
       c.status,
       cc.column_name,
       c.search_condition
FROM   user_constraints c
JOIN   user_cons_columns cc ON c.constraint_name = cc.constraint_name
                            AND c.table_name = cc.table_name
WHERE  c.table_name = 'MY_EMPLOYEES'
ORDER BY c.constraint_type, cc.position;
```

**constraint_type 값의 의미:**

| 값 | 의미 |
|----|------|
| `C` | CHECK 제약 조건 (NOT NULL 포함) |
| `P` | PRIMARY KEY |
| `R` | FOREIGN KEY (Referential integrity) |
| `U` | UNIQUE |

> MY_EMPLOYEES에는 P(emp_id), U(email), C(NOT NULL: last_name, email), C(salary > 0), R(dept_id → my_departments) 가 존재함.

---

**[24번] 답**

```sql
-- 1. 급여 상위 10명 백업 테이블 생성
CREATE TABLE top_earners_backup AS
SELECT employee_id, last_name, salary, department_id
FROM   employees
ORDER BY salary DESC
FETCH FIRST 10 ROWS ONLY;

-- 2. 확인
SELECT COUNT(*) FROM top_earners_backup;
-- 10

SELECT * FROM top_earners_backup ORDER BY salary DESC;
-- 상위 10명 (King 24000, Kochhar 17000, De Haan 17000 ...)

-- 3. 원본 비교
SELECT e.employee_id, e.last_name, e.salary, t.salary AS backup_salary
FROM   employees e
JOIN   top_earners_backup t ON e.employee_id = t.employee_id
ORDER BY e.salary DESC;
-- salary와 backup_salary가 일치함 (데이터 정확히 복사됨)
```

---

## Group 5. 종합 DDL 실습 모범답안 (25~30번)

---

**[25번] 답**

```sql
-- 1. customers 테이블
CREATE TABLE customers (
    customer_id   NUMBER(6)    PRIMARY KEY,
    customer_name VARCHAR2(50) NOT NULL,
    email         VARCHAR2(50) UNIQUE NOT NULL,
    join_date     DATE         DEFAULT SYSDATE,
    grade         VARCHAR2(10) DEFAULT 'BRONZE'
                               CHECK (grade IN ('BRONZE','SILVER','GOLD'))
);

-- 2. products 테이블
CREATE TABLE products (
    product_id   NUMBER(8)    PRIMARY KEY,
    product_name VARCHAR2(100) NOT NULL,
    price        NUMBER(10,2) CHECK (price > 0),
    stock_qty    NUMBER(6)    DEFAULT 0 CHECK (stock_qty >= 0)
);

-- 3. orders 테이블 (FK: customers, products 먼저 생성 후 실행)
CREATE TABLE orders (
    order_id    NUMBER(10)   PRIMARY KEY,
    customer_id NUMBER(6)    REFERENCES customers(customer_id),
    product_id  NUMBER(8)    REFERENCES products(product_id),
    order_date  DATE         DEFAULT SYSDATE,
    quantity    NUMBER(4)    CHECK (quantity > 0),
    total_price NUMBER(12,2)
);
```

---

**[26번] 답**

```sql
-- 데이터 삽입
INSERT INTO customers (customer_id, customer_name, email)
VALUES (1, '김철수', 'chulsoo@email.com');

INSERT INTO customers (customer_id, customer_name, email, grade)
VALUES (2, '이영희', 'younghee@email.com', 'GOLD');

INSERT INTO products VALUES (1001, 'Oracle DB 교재', 45000, 100);
INSERT INTO products VALUES (1002, 'USB 허브', 29000, 50);

INSERT INTO orders VALUES (1, 1, 1001, SYSDATE, 2, 90000);
INSERT INTO orders VALUES (2, 2, 1002, SYSDATE, 1, 29000);
COMMIT;
```

**제약 조건 위반 확인:**

```sql
-- A) grade = 'PLATINUM' → CHECK 위반
INSERT INTO customers (customer_id, customer_name, email, grade)
VALUES (3, '박민준', 'mj@email.com', 'PLATINUM');
-- ORA-02290: check constraint violated
-- 원인: grade CHECK 조건은 'BRONZE','SILVER','GOLD'만 허용

-- B) quantity = -1 → CHECK 위반
INSERT INTO orders VALUES (3, 1, 1001, SYSDATE, -1, -45000);
-- ORA-02290: check constraint violated
-- 원인: quantity CHECK (quantity > 0) 조건 위반
```

---

**[27번] 답**

```sql
-- 1. category 열 추가
ALTER TABLE products
ADD (category VARCHAR2(30) DEFAULT 'GENERAL');

-- 2. product_name 크기 확장
ALTER TABLE products
MODIFY (product_name VARCHAR2(200));

-- 3. stock_qty 기본값 확인 (이미 DEFAULT 0 → 재설정)
ALTER TABLE products
MODIFY (stock_qty NUMBER(6) DEFAULT 0);

-- 4. 구조 확인
DESCRIBE products;
```

예상 출력:
```
 Name          Null?    Type
 ------------- -------- ---------------
 PRODUCT_ID    NOT NULL NUMBER(8)
 PRODUCT_NAME  NOT NULL VARCHAR2(200)
 PRICE                  NUMBER(10,2)
 STOCK_QTY              NUMBER(6)
 CATEGORY               VARCHAR2(30)
```

---

**[28번] 답**

```sql
SELECT c.constraint_name,
       c.constraint_type,
       c.status,
       cc.column_name,
       c.search_condition
FROM   user_constraints c
JOIN   user_cons_columns cc ON c.constraint_name = cc.constraint_name
                            AND c.table_name = cc.table_name
WHERE  c.table_name = 'EMPLOYEES'
ORDER BY c.constraint_type, cc.position;
```

**예상 결과 분석 (HR 스키마 기준):**

| 제약 조건 유형 | 예시 이름 | 열 | 설명 |
|--------------|-----------|-----|------|
| P (PRIMARY KEY) | EMP_EMP_ID_PK | EMPLOYEE_ID | 기본 키 |
| R (FOREIGN KEY) | EMP_DEPT_FK | DEPARTMENT_ID | DEPARTMENTS 참조 |
| R (FOREIGN KEY) | EMP_JOB_FK | JOB_ID | JOBS 참조 |
| R (FOREIGN KEY) | EMP_MANAGER_FK | MANAGER_ID | EMPLOYEES 자기 참조 |
| C (CHECK/NOT NULL) | EMP_LAST_NAME_NN | LAST_NAME | NOT NULL |
| C (CHECK/NOT NULL) | EMP_EMAIL_NN | EMAIL | NOT NULL |
| C (CHECK/NOT NULL) | EMP_HIRE_DATE_NN | HIRE_DATE | NOT NULL |
| C (CHECK/NOT NULL) | EMP_JOB_NN | JOB_ID | NOT NULL |
| C (CHECK/NOT NULL) | EMP_SALARY_MIN | SALARY | CHECK(salary > 0) |
| U (UNIQUE) | EMP_EMAIL_UK | EMAIL | 고유 이메일 |

**정리:** PRIMARY KEY 1개, FOREIGN KEY 3개, NOT NULL/CHECK 5개 이상, UNIQUE 1개.

---

**[29번] 답**

```sql
-- 1. 테이블 생성
CREATE TABLE dept_salary_summary AS
SELECT d.department_id,
       d.department_name,
       COUNT(e.employee_id)  AS emp_count,
       MIN(e.salary)         AS min_salary,
       MAX(e.salary)         AS max_salary,
       ROUND(AVG(e.salary))  AS avg_salary,
       SUM(e.salary)         AS total_salary
FROM   departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
ORDER BY d.department_id;

-- 결과 조회
SELECT * FROM dept_salary_summary ORDER BY department_id;

-- 2. budget_ratio 열 추가
ALTER TABLE dept_salary_summary
ADD (budget_ratio NUMBER(5,2));

-- 3. 업데이트
UPDATE dept_salary_summary
SET    budget_ratio = ROUND(total_salary / (SELECT SUM(salary) FROM employees) * 100, 2);

COMMIT;

-- 확인
SELECT department_id, department_name, emp_count, avg_salary, budget_ratio
FROM   dept_salary_summary
ORDER BY budget_ratio DESC NULLS LAST;
```

> 전체 급여 합계 대비 각 부서의 급여 비중(%)을 budget_ratio로 계산.

---

**[30번] 답**

```sql
-- FK 참조 관계가 있으므로 자식 테이블부터 삭제

-- 1단계: 자식 테이블
DROP TABLE orders;
DROP TABLE cascade_child;
DROP TABLE setnull_child;

-- 2단계: 나머지 테이블
DROP TABLE customers;
DROP TABLE products;
DROP TABLE cascade_parent;
DROP TABLE my_employees;
DROP TABLE my_departments;
DROP TABLE dept80_copy;
DROP TABLE top_earners_backup;
DROP TABLE dept_salary_summary;
DROP TABLE projects;

-- 확인
SELECT table_name FROM user_tables
WHERE  table_name IN ('MY_DEPARTMENTS','MY_EMPLOYEES','DEPT80_COPY',
                      'PROJECTS','CUSTOMERS','PRODUCTS','ORDERS',
                      'CASCADE_PARENT','CASCADE_CHILD','SETNULL_CHILD',
                      'TOP_EARNERS_BACKUP','DEPT_SALARY_SUMMARY');
-- no rows selected (모두 삭제 완료)
```

> **핵심 규칙:** FOREIGN KEY 참조 관계가 있을 때는 반드시 **자식 테이블을 먼저 삭제**해야 한다.  
> 또는 `DROP TABLE ... CASCADE CONSTRAINTS` 옵션으로 참조 제약 조건까지 함께 삭제할 수 있다.
