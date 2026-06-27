# Oracle Database 19c: SQL Workshop
## Chapter 11 — 데이터 정의 언어(DDL) 소개 | SQL 실습 문제

> **실습 환경:** Oracle HR 스키마 (EMPLOYEES, DEPARTMENTS, JOBS, LOCATIONS, JOB_HISTORY 등)  
> **실습 전 주의:** 실습에서 생성한 테이블은 실습 후 `DROP TABLE` 로 정리합니다.

---

## Group 1. CREATE TABLE 기초 실습 (1~6번)

---

**[1번]** 다음 요건에 맞게 `my_departments` 테이블을 생성하시오.

| 열 이름 | 데이터 타입 | 조건 |
|---------|------------|------|
| dept_id | NUMBER(4) | 기본 키 |
| dept_name | VARCHAR2(30) | NOT NULL |
| location | VARCHAR2(50) | 기본값 'Seoul' |

---

**[2번]** 다음 요건에 맞게 `my_employees` 테이블을 생성하시오.

| 열 이름 | 데이터 타입 | 조건 |
|---------|------------|------|
| emp_id | NUMBER(6) | 기본 키 |
| first_name | VARCHAR2(20) | — |
| last_name | VARCHAR2(25) | NOT NULL |
| email | VARCHAR2(25) | UNIQUE, NOT NULL |
| hire_date | DATE | 기본값 SYSDATE |
| salary | NUMBER(8,2) | CHECK (salary > 0) |
| dept_id | NUMBER(4) | my_departments(dept_id) 참조 |

---

**[3번]** `my_employees` 테이블 생성 후 `DESCRIBE` 명령어로 구조를 확인하시오.

---

**[4번]** 다음 조건으로 `projects` 테이블을 생성하시오.  
- 모든 제약 조건에 명시적 이름을 부여한다 (`proj_pk`, `proj_name_nn`, `proj_budget_ck`, `proj_status_ck`)

| 열 이름 | 데이터 타입 | 조건 |
|---------|------------|------|
| project_id | NUMBER(5) | 기본 키 (proj_pk) |
| project_name | VARCHAR2(50) | NOT NULL (proj_name_nn) |
| budget | NUMBER(12,2) | CHECK (budget >= 0) — proj_budget_ck |
| status | VARCHAR2(20) | CHECK (status IN ('PLANNING','ACTIVE','CLOSED')) — proj_status_ck |
| start_date | DATE | 기본값 SYSDATE |

---

**[5번]** 다음 SQL로 `dept80_copy` 테이블을 생성하시오. 생성 후 행 수를 확인하시오.

```sql
-- 부서 80 사원의 사번, 이름, 급여, 입사일만 복사
CREATE TABLE dept80_copy AS
SELECT employee_id, last_name, salary, hire_date
FROM   employees
WHERE  department_id = 80;
```

---

**[6번]** `empty_emp` 테이블을 생성하되, EMPLOYEES 테이블과 동일한 구조(모든 열)이지만 **데이터는 없는** 빈 테이블로 생성하시오.

---

## Group 2. 제약 조건 실습 (7~12번)

---

**[7번]** `my_departments` 테이블에 데이터를 삽입하고 기본 키 중복 오류를 확인하시오.

```sql
-- 먼저 데이터 삽입
INSERT INTO my_departments VALUES (10, 'Sales', 'Busan');
INSERT INTO my_departments VALUES (20, 'HR', 'Seoul');

-- 다음 SQL 실행 — 어떤 오류가 발생하는가?
INSERT INTO my_departments VALUES (10, 'IT', 'Daejeon');
```

오류 메시지를 적고, 오류 원인을 설명하시오.

---

**[8번]** `my_employees` 테이블에서 FOREIGN KEY 제약 조건 위반을 확인하시오.

```sql
-- 다음 SQL 실행 — 어떤 오류가 발생하는가?
INSERT INTO my_employees (emp_id, last_name, email, dept_id)
VALUES (1, 'Kim', 'SKIM', 99);
-- dept_id=99는 my_departments에 없음
```

---

**[9번]** `my_employees` 테이블에서 CHECK 제약 조건 위반을 확인하시오.

```sql
-- 먼저 정상 삽입
INSERT INTO my_departments VALUES (30, 'Finance', 'Seoul');
INSERT INTO my_employees (emp_id, last_name, email, salary, dept_id)
VALUES (1, 'Park', 'SPARK', 5000, 30);

-- 다음 SQL 실행 — 어떤 오류가 발생하는가?
UPDATE my_employees SET salary = -100 WHERE emp_id = 1;
```

---

**[10번]** `my_employees` 테이블에서 UNIQUE 제약 조건 위반을 확인하시오.

```sql
-- 기존 데이터: emp_id=1, email='SPARK'

-- 다음 SQL 실행 — 어떤 오류가 발생하는가?
INSERT INTO my_employees (emp_id, last_name, email, dept_id)
VALUES (2, 'Lee', 'SPARK', 30);
-- email 'SPARK'이 이미 존재
```

---

**[11번]** ON DELETE CASCADE 동작을 확인하시오.

```sql
-- 1. cascade_parent 테이블 생성
CREATE TABLE cascade_parent (
    parent_id   NUMBER(5) PRIMARY KEY,
    parent_name VARCHAR2(30)
);

-- 2. cascade_child 테이블 생성 (ON DELETE CASCADE)
CREATE TABLE cascade_child (
    child_id  NUMBER(5) PRIMARY KEY,
    parent_id NUMBER(5),
    CONSTRAINT fk_cascade FOREIGN KEY (parent_id)
        REFERENCES cascade_parent(parent_id)
        ON DELETE CASCADE
);

-- 3. 데이터 삽입
INSERT INTO cascade_parent VALUES (1, 'Alpha');
INSERT INTO cascade_parent VALUES (2, 'Beta');
INSERT INTO cascade_child VALUES (101, 1);
INSERT INTO cascade_child VALUES (102, 1);
INSERT INTO cascade_child VALUES (103, 2);
COMMIT;
```

cascade_parent에서 parent_id=1을 삭제하고, cascade_child에서 어떤 행이 사라지는지 확인하시오.

---

**[12번]** ON DELETE SET NULL 동작을 확인하시오.

```sql
-- 1. setnull_child 테이블 생성 (ON DELETE SET NULL)
CREATE TABLE setnull_child (
    child_id  NUMBER(5) PRIMARY KEY,
    parent_id NUMBER(5),
    CONSTRAINT fk_setnull FOREIGN KEY (parent_id)
        REFERENCES cascade_parent(parent_id)
        ON DELETE SET NULL
);

-- 2. 데이터 삽입 (cascade_parent의 parent_id=2 참조)
INSERT INTO setnull_child VALUES (201, 2);
INSERT INTO setnull_child VALUES (202, 2);
COMMIT;
```

cascade_parent에서 parent_id=2를 삭제하고, setnull_child에서 어떤 변화가 생기는지 확인하시오.

---

## Group 3. ALTER TABLE 실습 (13~18번)

---

**[13번]** `dept80_copy` 테이블에 새 열을 추가하시오.

- 열 이름: `job_id`
- 데이터 타입: `VARCHAR2(10)`
- 기본값: `'UNKNOWN'`

추가 후 DESCRIBE 명령어로 확인하시오.

---

**[14번]** `dept80_copy` 테이블에서 `salary` 열의 데이터 타입을 `NUMBER(10, 2)`로 수정하시오.

---

**[15번]** `dept80_copy` 테이블에서 기존 `job_id` 열 추가 후 다음을 시도하시오.

```sql
-- 시도 1: VARCHAR2(10) → VARCHAR2(5)로 크기 축소 (데이터가 있다면 어떻게 되는가?)
ALTER TABLE dept80_copy
MODIFY (job_id VARCHAR2(5));
```

먼저 `UPDATE dept80_copy SET job_id = 'SA_REP';` 로 데이터를 채운 후 크기 축소를 시도하고 결과를 확인하시오.

---

**[16번]** `dept80_copy` 테이블에 `commission_pct` 열을 추가한 후 SET UNUSED로 표시하고, 최종적으로 DROP UNUSED COLUMNS로 제거하시오. 각 단계 후 DESCRIBE로 변화를 확인하시오.

---

**[17번]** `my_departments` 테이블에서 `location` 열을 삭제하시오. 삭제 후 DESCRIBE로 확인하시오.

---

**[18번]** `dept80_copy` 테이블의 `job_id` 열 이름을 `position_id`로 변경하시오.

---

## Group 4. 읽기 전용 테이블 및 DROP TABLE 실습 (19~24번)

---

**[19번]** `dept80_copy` 테이블을 읽기 전용으로 설정하고, DML 시도 시 오류를 확인하시오.

```sql
-- 1. 읽기 전용 설정
ALTER TABLE dept80_copy READ ONLY;

-- 2. DML 시도 (어떤 오류가 발생하는가?)
UPDATE dept80_copy SET salary = 9999 WHERE ROWNUM = 1;

-- 3. 읽기/쓰기 모드로 복원
ALTER TABLE dept80_copy READ WRITE;

-- 4. DML 재시도 (성공하는가?)
UPDATE dept80_copy SET salary = 9999 WHERE ROWNUM = 1;
ROLLBACK;
```

---

**[20번]** 다음 SQL을 실행하고 USER_TABLES 딕셔너리 뷰로 테이블 생성을 확인하시오.

```sql
-- 테이블 목록 조회 (현재 사용자가 소유한 테이블)
SELECT table_name, status, read_only
FROM   user_tables
WHERE  table_name IN ('MY_DEPARTMENTS', 'MY_EMPLOYEES', 'DEPT80_COPY', 'PROJECTS');
```

---

**[21번]** `projects` 테이블을 DROP하고, Recycle Bin에서 확인한 후 FLASHBACK으로 복구하시오.

```sql
-- 1. 삭제 전 데이터 확인
INSERT INTO projects VALUES (1, 'Alpha Project', 1000000, 'ACTIVE', SYSDATE);
COMMIT;
SELECT * FROM projects;

-- 2. DROP
DROP TABLE projects;

-- 3. Recycle Bin 확인
SELECT object_name, original_name, type
FROM   recyclebin
WHERE  original_name = 'PROJECTS';

-- 4. FLASHBACK으로 복구
FLASHBACK TABLE projects TO BEFORE DROP;

-- 5. 복구 확인
SELECT * FROM projects;
```

---

**[22번]** `empty_emp` 테이블을 PURGE 옵션으로 삭제하고 Recycle Bin에 남지 않음을 확인하시오.

```sql
-- 1. PURGE로 삭제
DROP TABLE empty_emp PURGE;

-- 2. Recycle Bin 확인 (없어야 함)
SELECT object_name, original_name
FROM   recyclebin
WHERE  original_name = 'EMPTY_EMP';
```

---

**[23번]** USER_CONSTRAINTS 딕셔너리 뷰로 `my_employees` 테이블의 제약 조건을 조회하시오.

```sql
SELECT constraint_name, constraint_type, column_name, status
FROM   user_cons_columns
JOIN   user_constraints USING (constraint_name, table_name)
WHERE  table_name = 'MY_EMPLOYEES'
ORDER BY constraint_type;
```

constraint_type 컬럼의 값(P, U, R, C, N)의 의미를 설명하시오.

---

**[24번]** 다음 순서로 CREATE TABLE AS SELECT를 활용한 데이터 백업 및 복원 실습을 수행하시오.

```sql
-- 1. 급여 상위 10명 백업 테이블 생성
CREATE TABLE top_earners_backup AS
SELECT employee_id, last_name, salary, department_id
FROM   employees
ORDER BY salary DESC
FETCH FIRST 10 ROWS ONLY;

-- 2. 백업 확인
SELECT COUNT(*) FROM top_earners_backup;
SELECT * FROM top_earners_backup ORDER BY salary DESC;

-- 3. 원본 테이블과 비교
SELECT e.employee_id, e.last_name, e.salary, t.salary AS backup_salary
FROM   employees e
JOIN   top_earners_backup t ON e.employee_id = t.employee_id
ORDER BY e.salary DESC;
```

---

## Group 5. 종합 DDL 실습 (25~30번)

---

**[25번]** 다음 요건으로 온라인 쇼핑몰 데이터베이스 테이블 3개를 생성하시오.

**customers 테이블:**
| 열 | 타입 | 조건 |
|----|------|------|
| customer_id | NUMBER(6) | PK |
| customer_name | VARCHAR2(50) | NOT NULL |
| email | VARCHAR2(50) | UNIQUE, NOT NULL |
| join_date | DATE | DEFAULT SYSDATE |
| grade | VARCHAR2(10) | CHECK (grade IN ('BRONZE','SILVER','GOLD')) DEFAULT 'BRONZE' |

**products 테이블:**
| 열 | 타입 | 조건 |
|----|------|------|
| product_id | NUMBER(8) | PK |
| product_name | VARCHAR2(100) | NOT NULL |
| price | NUMBER(10,2) | CHECK (price > 0) |
| stock_qty | NUMBER(6) | DEFAULT 0, CHECK (stock_qty >= 0) |

**orders 테이블:**
| 열 | 타입 | 조건 |
|----|------|------|
| order_id | NUMBER(10) | PK |
| customer_id | NUMBER(6) | FK → customers(customer_id) |
| product_id | NUMBER(8) | FK → products(product_id) |
| order_date | DATE | DEFAULT SYSDATE |
| quantity | NUMBER(4) | CHECK (quantity > 0) |
| total_price | NUMBER(12,2) | — |

---

**[26번]** 25번에서 생성한 테이블에 테스트 데이터를 삽입하고 제약 조건이 올바르게 작동하는지 확인하시오.

```sql
-- 고객 데이터 삽입
INSERT INTO customers (customer_id, customer_name, email) VALUES (1, '김철수', 'chulsoo@email.com');
INSERT INTO customers (customer_id, customer_name, email, grade) VALUES (2, '이영희', 'younghee@email.com', 'GOLD');

-- 상품 데이터 삽입
INSERT INTO products VALUES (1001, 'Oracle DB 교재', 45000, 100);
INSERT INTO products VALUES (1002, 'USB 허브', 29000, 50);

-- 주문 데이터 삽입
INSERT INTO orders VALUES (1, 1, 1001, SYSDATE, 2, 90000);
INSERT INTO orders VALUES (2, 2, 1002, SYSDATE, 1, 29000);
COMMIT;

-- 제약 조건 위반 시도:
-- A) 잘못된 grade 값 삽입
INSERT INTO customers (customer_id, customer_name, email, grade) VALUES (3, '박민준', 'mj@email.com', 'PLATINUM');

-- B) 음수 수량 주문
INSERT INTO orders VALUES (3, 1, 1001, SYSDATE, -1, -45000);
```

각 오류의 원인을 설명하시오.

---

**[27번]** `products` 테이블에 다음 변경을 수행하시오.

1. `category` 열 추가 (`VARCHAR2(30)`, 기본값 `'GENERAL'`)
2. `product_name` 열의 크기를 `VARCHAR2(200)`으로 확장
3. `stock_qty` 열에 기본값이 없는 경우 기본값을 `0`으로 설정하는 MODIFY 수행
4. DESCRIBE로 최종 구조 확인

---

**[28번]** HR 스키마의 EMPLOYEES 테이블을 분석하고 제약 조건 정보를 조회하시오.

```sql
-- EMPLOYEES 테이블의 모든 제약 조건 조회
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

결과를 분석하여 EMPLOYEES 테이블에 정의된 제약 조건의 종류와 수를 정리하시오.

---

**[29번]** 서브쿼리를 사용한 복잡한 테이블 생성 실습을 수행하시오.

```sql
-- 부서별 급여 요약 테이블 생성
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
```

1. 위 SQL로 테이블을 생성하고 결과를 조회하시오.
2. `dept_salary_summary`에 `budget_ratio` 열(`NUMBER(5,2)`)을 추가하시오.
3. `UPDATE dept_salary_summary SET budget_ratio = ROUND(total_salary / (SELECT SUM(salary) FROM employees) * 100, 2);`

---

**[30번]** 실습 정리: 이번 실습에서 생성한 모든 테이블을 안전하게 삭제하시오.

삭제 순서에 주의한다 (FK 참조 관계가 있는 경우 자식 테이블부터 삭제).

```sql
-- FK 참조 관계 확인 후 올바른 순서로 DROP
-- 힌트: orders → customers, products (자식 먼저)
--       cascade_child, setnull_child → cascade_parent

-- 1단계: 자식 테이블 삭제
DROP TABLE orders;
DROP TABLE cascade_child;
DROP TABLE setnull_child;

-- 2단계: 나머지 테이블 삭제
DROP TABLE customers;
DROP TABLE products;
DROP TABLE cascade_parent;
DROP TABLE my_employees;
DROP TABLE my_departments;
DROP TABLE dept80_copy;
DROP TABLE top_earners_backup;
DROP TABLE dept_salary_summary;
DROP TABLE projects;  -- FLASHBACK으로 복구한 경우

-- 확인
SELECT table_name FROM user_tables
WHERE  table_name IN ('MY_DEPARTMENTS','MY_EMPLOYEES','DEPT80_COPY',
                      'PROJECTS','CUSTOMERS','PRODUCTS','ORDERS',
                      'CASCADE_PARENT','CASCADE_CHILD','SETNULL_CHILD',
                      'TOP_EARNERS_BACKUP','DEPT_SALARY_SUMMARY');
-- 결과: 0 rows (모두 삭제됨)
```
