# Oracle Database 19c: SQL Workshop
## Chapter 13 — 시퀀스, 동의어, 인덱스 생성 | SQL 실습 문제

> **실습 환경:** Oracle HR 스키마  
> **실습 전 주의:** 생성한 시퀀스·동의어·인덱스는 실습 후 DROP으로 정리합니다.

---

## Group 1. 시퀀스 생성 및 기본 사용 (1~6번)

---

**[1번]** DEPARTMENTS 테이블 기본 키용 시퀀스를 생성하시오.

- 시퀀스 이름: `dept_deptid_seq`
- 시작 값: 280
- 증가량: 10
- 최대값: 9999
- NOCACHE, NOCYCLE

---

**[2번]** 생성한 `dept_deptid_seq`의 정보를 `USER_SEQUENCES` 뷰로 확인하시오.

```sql
SELECT sequence_name, min_value, max_value,
       increment_by, cache_size, cycle_flag, last_number
FROM   user_sequences
WHERE  sequence_name = 'DEPT_DEPTID_SEQ';
```

---

**[3번]** `dept_deptid_seq`를 사용하여 DEPARTMENTS 테이블에 새 부서를 삽입하시오.

```sql
INSERT INTO departments (department_id, department_name, location_id)
VALUES (dept_deptid_seq.NEXTVAL, 'Support', 2500);

-- 현재 시퀀스 값 확인
SELECT dept_deptid_seq.CURRVAL FROM dual;

-- 삽입 확인
SELECT department_id, department_name
FROM   departments
WHERE  department_name = 'Support';

ROLLBACK;
```

---

**[4번]** NEXTVAL을 세 번 연속 호출하고 각 값을 확인하시오.

```sql
SELECT dept_deptid_seq.NEXTVAL FROM dual;
SELECT dept_deptid_seq.NEXTVAL FROM dual;
SELECT dept_deptid_seq.NEXTVAL FROM dual;
SELECT dept_deptid_seq.CURRVAL FROM dual;
```

세 번째 호출 값과 CURRVAL 값이 같은지 확인하시오.

---

**[5번]** 직원 ID용 시퀀스를 생성하고 DEFAULT 값으로 사용하시오.

```sql
-- 1. 시퀀스 생성
CREATE SEQUENCE emp_id_seq
    START WITH 300
    INCREMENT BY 1
    MAXVALUE 9999
    NOCACHE
    NOCYCLE;

-- 2. 시퀀스를 DEFAULT로 사용하는 테이블 생성
CREATE TABLE new_employees (
    emp_id   NUMBER DEFAULT emp_id_seq.NEXTVAL NOT NULL,
    emp_name VARCHAR2(50) NOT NULL,
    hire_date DATE DEFAULT SYSDATE
);

-- 3. emp_id 없이 삽입 (자동 할당)
INSERT INTO new_employees (emp_name) VALUES ('Kim Chulsoo');
INSERT INTO new_employees (emp_name) VALUES ('Lee Younghee');
INSERT INTO new_employees (emp_name) VALUES ('Park Minjun');

-- 4. 결과 확인
SELECT * FROM new_employees;
```

---

**[6번]** `dept_deptid_seq` 시퀀스를 수정하고 확인하시오.

```sql
-- 1. 증가량을 20으로 변경, MAXVALUE를 99999로 변경
ALTER SEQUENCE dept_deptid_seq
    INCREMENT BY 20
    MAXVALUE 99999;

-- 2. 변경 확인
SELECT sequence_name, increment_by, max_value
FROM   user_sequences
WHERE  sequence_name = 'DEPT_DEPTID_SEQ';

-- 3. 수정 후 NEXTVAL 확인 (20씩 증가하는지 확인)
SELECT dept_deptid_seq.NEXTVAL FROM dual;
SELECT dept_deptid_seq.NEXTVAL FROM dual;
```

---

## Group 2. 동의어 생성 및 사용 (7~12번)

---

**[7번]** DEPARTMENTS 테이블의 단축 동의어를 생성하시오.

```sql
CREATE SYNONYM dept FOR departments;

-- 동의어로 조회
SELECT department_id, department_name
FROM   dept
ORDER BY department_id;
```

---

**[8번]** 생성한 동의어 정보를 `USER_SYNONYMS` 뷰로 조회하시오.

```sql
SELECT synonym_name, table_owner, table_name
FROM   user_synonyms
WHERE  synonym_name = 'DEPT';
```

---

**[9번]** EMPLOYEES 테이블의 동의어를 생성하고 DML이 가능한지 확인하시오.

```sql
-- 1. 동의어 생성
CREATE SYNONYM emp FOR employees;

-- 2. 동의어로 SELECT
SELECT employee_id, last_name, salary
FROM   emp
WHERE  department_id = 80
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;

-- 3. 동의어로 UPDATE (DML 가능 여부 확인)
UPDATE emp
SET    salary = salary * 1.01
WHERE  employee_id = 100;
-- 확인 후 ROLLBACK

ROLLBACK;
```

---

**[10번]** JOBS 테이블의 긴 이름을 단축하는 동의어를 생성하고 JOIN에서 사용하시오.

```sql
-- 1. 동의어 생성
CREATE SYNONYM j FOR jobs;

-- 2. 동의어를 이용한 JOIN 쿼리
SELECT e.employee_id, e.last_name, j.job_title, e.salary
FROM   emp e
JOIN   j   ON e.job_id = j.job_id
WHERE  e.department_id = 60;
```

---

**[11번]** 동의어가 참조하는 테이블이 없을 때 어떻게 되는지 확인하시오.

```sql
-- 1. 존재하지 않는 테이블의 동의어 생성 (생성은 성공함)
CREATE SYNONYM ghost_syn FOR nonexistent_table;

-- 2. 사용 시도 (오류 발생)
SELECT * FROM ghost_syn;

-- 3. USER_SYNONYMS에서 확인 (존재함)
SELECT * FROM user_synonyms WHERE synonym_name = 'GHOST_SYN';
```

오류 메시지를 기록하고 원인을 설명하시오.

---

**[12번]** 동의어를 삭제하시오.

```sql
DROP SYNONYM dept;
DROP SYNONYM emp;
DROP SYNONYM j;
DROP SYNONYM ghost_syn;

-- 삭제 확인
SELECT synonym_name FROM user_synonyms
WHERE  synonym_name IN ('DEPT','EMP','J','GHOST_SYN');
-- 0 rows
```

---

## Group 3. 인덱스 생성 및 관리 (13~18번)

---

**[13번]** EMPLOYEES 테이블의 LAST_NAME 열에 인덱스를 생성하시오.

```sql
-- 인덱스 생성
CREATE INDEX emp_last_name_idx
ON employees (last_name);

-- 생성 확인
SELECT index_name, table_name, uniqueness
FROM   user_indexes
WHERE  table_name = 'EMPLOYEES'
AND    index_name = 'EMP_LAST_NAME_IDX';
```

---

**[14번]** USER_INDEXES와 USER_IND_COLUMNS를 조회하여 EMPLOYEES의 모든 인덱스 정보를 확인하시오.

```sql
-- 인덱스 기본 정보
SELECT index_name, uniqueness, index_type
FROM   user_indexes
WHERE  table_name = 'EMPLOYEES'
ORDER BY index_name;

-- 인덱스별 열 정보
SELECT i.index_name, c.column_name, i.uniqueness
FROM   user_indexes     i
JOIN   user_ind_columns c ON i.index_name = c.index_name
WHERE  i.table_name = 'EMPLOYEES'
ORDER BY i.index_name, c.column_position;
```

HR 스키마에서 EMPLOYEES 테이블에 몇 개의 인덱스가 자동/수동 생성되어 있는지 확인하시오.

---

**[15번]** 복합 인덱스를 생성하고 활용 쿼리를 실행하시오.

```sql
-- 복합 인덱스 생성
CREATE INDEX emp_dept_job_idx
ON employees (department_id, job_id);

-- 인덱스 활용 쿼리 (선두 열 포함)
SELECT employee_id, last_name, salary
FROM   employees
WHERE  department_id = 80
AND    job_id = 'SA_REP';

-- 인덱스 정보 확인
SELECT index_name, column_name, column_position
FROM   user_ind_columns
WHERE  index_name = 'EMP_DEPT_JOB_IDX';
```

---

**[16번]** 함수 기반 인덱스를 생성하고 효과를 확인하시오.

```sql
-- 1. 대소문자 무관 검색용 함수 기반 인덱스
CREATE INDEX emp_upper_last_idx
ON employees (UPPER(last_name));

-- 2. 인덱스 확인
SELECT index_name, index_type
FROM   user_indexes
WHERE  index_name = 'EMP_UPPER_LAST_IDX';

-- 3. 함수 기반 인덱스를 활용하는 쿼리
SELECT employee_id, last_name
FROM   employees
WHERE  UPPER(last_name) = 'KING';

-- 4. 활용 안 되는 쿼리 (일반 인덱스 필요)
SELECT employee_id, last_name
FROM   employees
WHERE  last_name = 'King';
```

---

**[17번]** CREATE TABLE 문에서 인덱스 이름을 직접 지정하는 방법을 실습하시오.

```sql
-- 1. 테이블 생성 시 인덱스 이름 지정
CREATE TABLE prod_orders (
    order_id    NUMBER(10)
        PRIMARY KEY USING INDEX
        (CREATE INDEX prod_ord_pk_idx ON prod_orders(order_id)),
    product_name VARCHAR2(100) NOT NULL,
    qty         NUMBER(5) DEFAULT 1
);

-- 2. 인덱스 이름 확인
SELECT index_name, table_name, uniqueness
FROM   user_indexes
WHERE  table_name = 'PROD_ORDERS';

-- 3. 테이블 정리
DROP TABLE prod_orders;
```

---

**[18번]** 인덱스를 삭제하고 정리하시오.

```sql
DROP INDEX emp_last_name_idx;
DROP INDEX emp_dept_job_idx;
DROP INDEX emp_upper_last_idx;

-- 삭제 확인
SELECT index_name FROM user_indexes
WHERE  index_name IN ('EMP_LAST_NAME_IDX','EMP_DEPT_JOB_IDX','EMP_UPPER_LAST_IDX');
-- 0 rows
```

---

## Group 4. 딕셔너리 뷰 종합 조회 (19~24번)

---

**[19번]** USER_SEQUENCES 뷰로 현재 스키마의 모든 시퀀스를 조회하시오.

```sql
SELECT sequence_name,
       min_value,
       max_value,
       increment_by,
       cycle_flag,
       order_flag,
       cache_size,
       last_number
FROM   user_sequences
ORDER BY sequence_name;
```

---

**[20번]** USER_SYNONYMS 뷰로 현재 스키마의 모든 동의어를 조회하시오.

```sql
SELECT synonym_name, table_owner, table_name, db_link
FROM   user_synonyms
ORDER BY synonym_name;
```

`DB_LINK` 컬럼이 있는 경우 어떤 의미인지 설명하시오.

---

**[21번]** USER_INDEXES와 USER_IND_COLUMNS를 JOIN하여 HR 스키마의 모든 인덱스와 해당 열을 조회하시오.

```sql
SELECT i.table_name,
       i.index_name,
       i.uniqueness,
       i.index_type,
       c.column_name,
       c.column_position
FROM   user_indexes     i
JOIN   user_ind_columns c ON i.index_name = c.index_name
ORDER BY i.table_name, i.index_name, c.column_position;
```

---

**[22번]** EMPLOYEES 테이블에 자동 생성된 인덱스와 수동 생성 인덱스를 구분하시오.

자동 생성 인덱스의 특징을 확인하려면 `USER_CONSTRAINTS`와 `USER_INDEXES`를 비교하시오.

```sql
-- 제약 조건 이름과 인덱스 이름 비교
SELECT c.constraint_name,
       c.constraint_type,
       i.index_name,
       i.uniqueness
FROM   user_constraints c
JOIN   user_indexes     i ON c.constraint_name = i.index_name
WHERE  c.table_name = 'EMPLOYEES';
```

---

**[23번]** DICTIONARY 뷰에서 시퀀스·동의어·인덱스 관련 딕셔너리 뷰를 검색하시오.

```sql
-- 시퀀스 관련
SELECT table_name, comments FROM dictionary
WHERE  table_name LIKE '%SEQUENCE%';

-- 동의어 관련
SELECT table_name, comments FROM dictionary
WHERE  table_name LIKE '%SYNONYM%';

-- 인덱스 관련
SELECT table_name, comments FROM dictionary
WHERE  table_name LIKE '%INDEX%';
```

---

**[24번]** USER_OBJECTS 뷰에서 SEQUENCE, SYNONYM, INDEX 유형 객체를 조회하시오.

```sql
SELECT object_type, COUNT(*) AS cnt
FROM   user_objects
WHERE  object_type IN ('SEQUENCE', 'SYNONYM', 'INDEX')
GROUP BY object_type
ORDER BY object_type;
```

---

## Group 5. 종합 실습 (25~30번)

---

**[25번]** 미니 주문 시스템을 위한 시퀀스, 동의어, 인덱스를 함께 설계하시오.

```sql
-- 1. 주문 ID 시퀀스 생성
CREATE SEQUENCE order_id_seq
    START WITH 1000
    INCREMENT BY 1
    MAXVALUE 9999999
    CACHE 20
    NOCYCLE;

-- 2. 주문 테이블 생성
CREATE TABLE my_orders (
    order_id    NUMBER DEFAULT order_id_seq.NEXTVAL PRIMARY KEY,
    customer_name VARCHAR2(100) NOT NULL,
    product_name  VARCHAR2(100) NOT NULL,
    qty           NUMBER(5)    DEFAULT 1 CHECK (qty > 0),
    order_date    DATE         DEFAULT SYSDATE,
    status        VARCHAR2(20) DEFAULT 'PENDING'
                               CHECK (status IN ('PENDING','SHIPPED','CANCELLED'))
);

-- 3. 인덱스 생성
CREATE INDEX my_ord_status_idx ON my_orders(status);
CREATE INDEX my_ord_date_idx   ON my_orders(order_date);

-- 4. 동의어 생성
CREATE SYNONYM mo FOR my_orders;

-- 5. 데이터 삽입 (시퀀스 자동 사용)
INSERT INTO mo (customer_name, product_name, qty)
VALUES ('김철수', 'Oracle 교재', 2);

INSERT INTO mo (customer_name, product_name, qty, status)
VALUES ('이영희', 'USB 허브', 1, 'SHIPPED');

INSERT INTO mo (customer_name, product_name)
VALUES ('박민준', '마우스');

COMMIT;

-- 6. 조회
SELECT order_id, customer_name, product_name, qty, status, order_date
FROM   mo
ORDER BY order_id;
```

---

**[26번]** 25번에서 생성한 시스템의 딕셔너리 뷰 조회를 수행하시오.

```sql
-- 시퀀스 정보
SELECT sequence_name, last_number, increment_by, cache_size
FROM   user_sequences
WHERE  sequence_name = 'ORDER_ID_SEQ';

-- 인덱스 정보
SELECT index_name, uniqueness
FROM   user_indexes
WHERE  table_name = 'MY_ORDERS'
ORDER BY index_name;

-- 동의어 정보
SELECT synonym_name, table_name
FROM   user_synonyms
WHERE  synonym_name = 'MO';
```

---

**[27번]** 시퀀스의 갭(gap) 발생을 직접 확인하시오.

```sql
-- 1. 현재 시퀀스 값 확인
SELECT order_id_seq.NEXTVAL FROM dual;  -- 현재값 기록

-- 2. 3건 INSERT 후 ROLLBACK (갭 발생)
INSERT INTO mo (customer_name, product_name) VALUES ('테스트1', '상품A');
INSERT INTO mo (customer_name, product_name) VALUES ('테스트2', '상품B');
INSERT INTO mo (customer_name, product_name) VALUES ('테스트3', '상품C');
SELECT order_id_seq.CURRVAL FROM dual;  -- 값 기록
ROLLBACK;  -- INSERT 취소

-- 3. 롤백 후 NEXTVAL 확인 (갭 발생 여부)
SELECT order_id_seq.NEXTVAL FROM dual;
-- 결과: ROLLBACK 전 CURRVAL + 1 (갭 발생!)

-- 4. 실제 데이터 확인
SELECT order_id FROM mo ORDER BY order_id;
```

갭이 발생한 이유를 설명하시오.

---

**[28번]** 인덱스 활용 여부를 실행 계획으로 확인하시오.

```sql
-- 1. 인덱스 활용 가능 쿼리 실행 계획
EXPLAIN PLAN FOR
SELECT * FROM employees WHERE last_name = 'King';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- 2. 대소문자 변환으로 인덱스 미활용 예
EXPLAIN PLAN FOR
SELECT * FROM employees WHERE UPPER(last_name) = 'KING';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- 3. 함수 기반 인덱스 생성 후 재확인
CREATE INDEX emp_ul_idx ON employees(UPPER(last_name));

EXPLAIN PLAN FOR
SELECT * FROM employees WHERE UPPER(last_name) = 'KING';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

DROP INDEX emp_ul_idx;
```

---

**[29번]** 같은 열 집합에 여러 인덱스 생성을 실습하시오.

```sql
-- 1. 첫 번째 인덱스 생성
CREATE INDEX emp_dept_ix1 ON employees(department_id, salary);

-- 2. INVISIBLE로 전환
ALTER INDEX emp_dept_ix1 INVISIBLE;

-- 3. 상태 확인
SELECT index_name, visibility, status
FROM   user_indexes
WHERE  index_name = 'EMP_DEPT_IX1';

-- 4. 두 번째 인덱스 생성 (다른 순서)
CREATE INDEX emp_sal_dept_ix2 ON employees(salary, department_id);

-- 5. 두 인덱스 정보 비교
SELECT i.index_name, i.visibility, c.column_name, c.column_position
FROM   user_indexes     i
JOIN   user_ind_columns c ON i.index_name = c.index_name
WHERE  i.index_name IN ('EMP_DEPT_IX1', 'EMP_SAL_DEPT_IX2')
ORDER BY i.index_name, c.column_position;

-- 6. ix1 다시 VISIBLE로 변경
ALTER INDEX emp_dept_ix1 VISIBLE;

-- 정리
DROP INDEX emp_dept_ix1;
DROP INDEX emp_sal_dept_ix2;
```

---

**[30번]** 실습 정리 — 생성한 모든 객체를 삭제하시오.

```sql
-- 동의어 삭제
DROP SYNONYM mo;

-- 인덱스 삭제
DROP INDEX my_ord_status_idx;
DROP INDEX my_ord_date_idx;

-- 테이블 삭제
DROP TABLE my_orders PURGE;
DROP TABLE new_employees PURGE;

-- 시퀀스 삭제
DROP SEQUENCE order_id_seq;
DROP SEQUENCE emp_id_seq;
DROP SEQUENCE dept_deptid_seq;

-- 확인
SELECT object_name, object_type
FROM   user_objects
WHERE  object_name IN (
    'MO', 'MY_ORDERS', 'NEW_EMPLOYEES',
    'ORDER_ID_SEQ', 'EMP_ID_SEQ', 'DEPT_DEPTID_SEQ',
    'MY_ORD_STATUS_IDX', 'MY_ORD_DATE_IDX'
);
-- 0 rows (모두 삭제됨)
```
