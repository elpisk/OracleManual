# Oracle Database 19c: SQL Workshop
## Chapter 13 — 시퀀스, 동의어, 인덱스 생성 | SQL 실습 문제 모범답안

---

## Group 1. 시퀀스 생성 및 기본 사용 모범답안 (1~6번)

---

**[1번] 답**

```sql
CREATE SEQUENCE dept_deptid_seq
    START WITH   280
    INCREMENT BY 10
    MAXVALUE     9999
    NOCACHE
    NOCYCLE;
-- Sequence created.
```

---

**[2번] 답**

```sql
SELECT sequence_name, min_value, max_value,
       increment_by, cache_size, cycle_flag, last_number
FROM   user_sequences
WHERE  sequence_name = 'DEPT_DEPTID_SEQ';
```

예상 결과:
```
SEQUENCE_NAME    MIN_VALUE  MAX_VALUE  INCREMENT_BY  CACHE_SIZE  CYCLE_FLAG  LAST_NUMBER
---------------- ---------- ---------- ------------- ----------- ----------- -----------
DEPT_DEPTID_SEQ  1          9999       10            0           N           280
```

> `LAST_NUMBER`: 다음에 반환될 시퀀스 값 (NOCACHE이므로 현재 280)

---

**[3번] 답**

```sql
INSERT INTO departments (department_id, department_name, location_id)
VALUES (dept_deptid_seq.NEXTVAL, 'Support', 2500);
-- 1 row inserted. (department_id = 280)

SELECT dept_deptid_seq.CURRVAL FROM dual;
-- 280

SELECT department_id, department_name
FROM   departments
WHERE  department_name = 'Support';
-- 280  Support

ROLLBACK;
-- Rollback complete.
-- 단, 시퀀스 값 280은 소진됨 (다음 NEXTVAL = 290)
```

---

**[4번] 답**

```sql
SELECT dept_deptid_seq.NEXTVAL FROM dual;  -- 290 (ROLLBACK 후 다음 값)
SELECT dept_deptid_seq.NEXTVAL FROM dual;  -- 300
SELECT dept_deptid_seq.NEXTVAL FROM dual;  -- 310
SELECT dept_deptid_seq.CURRVAL FROM dual;  -- 310
```

**확인:** 세 번째 NEXTVAL 값(310)과 CURRVAL(310)이 동일하다.

> ROLLBACK이 시퀀스에 영향을 미치지 않음을 확인: 3번 문제에서 280을 ROLLBACK했지만 다음 값은 290부터 시작.

---

**[5번] 답**

```sql
CREATE SEQUENCE emp_id_seq
    START WITH 300
    INCREMENT BY 1
    MAXVALUE 9999
    NOCACHE
    NOCYCLE;

CREATE TABLE new_employees (
    emp_id   NUMBER DEFAULT emp_id_seq.NEXTVAL NOT NULL,
    emp_name VARCHAR2(50) NOT NULL,
    hire_date DATE DEFAULT SYSDATE
);

INSERT INTO new_employees (emp_name) VALUES ('Kim Chulsoo');
INSERT INTO new_employees (emp_name) VALUES ('Lee Younghee');
INSERT INTO new_employees (emp_name) VALUES ('Park Minjun');

SELECT * FROM new_employees;
```

예상 결과:
```
EMP_ID  EMP_NAME      HIRE_DATE
------- ------------- ----------
300     Kim Chulsoo   27-JUN-26
301     Lee Younghee  27-JUN-26
302     Park Minjun   27-JUN-26
```

---

**[6번] 답**

```sql
ALTER SEQUENCE dept_deptid_seq
    INCREMENT BY 20
    MAXVALUE 99999;
-- Sequence altered.

SELECT sequence_name, increment_by, max_value
FROM   user_sequences
WHERE  sequence_name = 'DEPT_DEPTID_SEQ';
-- DEPT_DEPTID_SEQ  20  99999

SELECT dept_deptid_seq.NEXTVAL FROM dual;  -- 330 (310 + 20)
SELECT dept_deptid_seq.NEXTVAL FROM dual;  -- 350
```

---

## Group 2. 동의어 생성 및 사용 모범답안 (7~12번)

---

**[7번] 답**

```sql
CREATE SYNONYM dept FOR departments;
-- Synonym created.

SELECT department_id, department_name
FROM   dept
ORDER BY department_id;
```

예상 결과:
```
DEPARTMENT_ID  DEPARTMENT_NAME
-------------- ---------------
10             Administration
20             Marketing
30             Purchasing
...
```

---

**[8번] 답**

```sql
SELECT synonym_name, table_owner, table_name
FROM   user_synonyms
WHERE  synonym_name = 'DEPT';
```

예상 결과:
```
SYNONYM_NAME  TABLE_OWNER  TABLE_NAME
------------- ------------ -----------
DEPT          HR           DEPARTMENTS
```

---

**[9번] 답**

```sql
CREATE SYNONYM emp FOR employees;

-- SELECT
SELECT employee_id, last_name, salary
FROM   emp
WHERE  department_id = 80
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;
-- 정상 작동 (employees 테이블에서 조회)

-- UPDATE 가능 여부 확인
UPDATE emp
SET    salary = salary * 1.01
WHERE  employee_id = 100;
-- 1 row updated. (동의어를 통한 DML 가능)

SELECT salary FROM emp WHERE employee_id = 100;

ROLLBACK;
```

**결론:** 동의어를 통한 DML은 원본 테이블에 직접 작동하므로 **가능**하다.

---

**[10번] 답**

```sql
CREATE SYNONYM j FOR jobs;

SELECT e.employee_id, e.last_name, j.job_title, e.salary
FROM   emp e
JOIN   j   ON e.job_id = j.job_id
WHERE  e.department_id = 60;
```

예상 결과:
```
EMPLOYEE_ID  LAST_NAME   JOB_TITLE               SALARY
------------ ----------- ----------------------- -------
103          Hunold      Programmer              9000
104          Ernst       Programmer              6000
105          Austin      Programmer              4800
106          Pataballa   Programmer              4800
107          Lorentz     Programmer              4200
```

---

**[11번] 답**

```sql
CREATE SYNONYM ghost_syn FOR nonexistent_table;
-- Synonym created. (참조 객체 존재 여부 확인 안 함)

SELECT * FROM ghost_syn;
-- ORA-00942: table or view does not exist
```

**오류 원인:**
- 동의어 생성 시 참조 객체의 존재 여부를 Oracle은 검사하지 않는다
- 실제 사용 시점에 참조 객체가 없으면 오류 발생

```sql
SELECT * FROM user_synonyms WHERE synonym_name = 'GHOST_SYN';
-- GHOST_SYN  (현재사용자)  NONEXISTENT_TABLE
-- 동의어 자체는 존재함
```

---

**[12번] 답**

```sql
DROP SYNONYM dept;
DROP SYNONYM emp;
DROP SYNONYM j;
DROP SYNONYM ghost_syn;
-- Synonym dropped. (4회)

SELECT synonym_name FROM user_synonyms
WHERE  synonym_name IN ('DEPT','EMP','J','GHOST_SYN');
-- no rows selected
```

---

## Group 3. 인덱스 생성 및 관리 모범답안 (13~18번)

---

**[13번] 답**

```sql
CREATE INDEX emp_last_name_idx
ON employees (last_name);
-- Index created.

SELECT index_name, table_name, uniqueness
FROM   user_indexes
WHERE  table_name = 'EMPLOYEES'
AND    index_name = 'EMP_LAST_NAME_IDX';
```

예상 결과:
```
INDEX_NAME         TABLE_NAME  UNIQUENESS
------------------ ----------- ----------
EMP_LAST_NAME_IDX  EMPLOYEES   NONUNIQUE
```

---

**[14번] 답**

```sql
SELECT index_name, uniqueness, index_type
FROM   user_indexes
WHERE  table_name = 'EMPLOYEES'
ORDER BY index_name;
```

예상 결과 (HR 기본 스키마 + EMP_LAST_NAME_IDX 추가 후):
```
INDEX_NAME           UNIQUENESS  INDEX_TYPE
-------------------- ----------- ----------
EMP_DEPARTMENT_IX    NONUNIQUE   NORMAL     (자동: FK)
EMP_EMAIL_UK         UNIQUE      NORMAL     (자동: UNIQUE)
EMP_EMP_ID_PK        UNIQUE      NORMAL     (자동: PK)
EMP_JOB_IX           NONUNIQUE   NORMAL     (자동: FK)
EMP_LAST_NAME_IDX    NONUNIQUE   NORMAL     (수동)
EMP_MANAGER_IX       NONUNIQUE   NORMAL     (자동: FK)
EMP_NAME_IX          NONUNIQUE   NORMAL     (자동)
```

**자동 생성:** PK(EMP_EMP_ID_PK), UK(EMP_EMAIL_UK)  
**HR 스키마 추가 인덱스:** FK에 대한 성능 인덱스 (DEPARTMENT_IX, JOB_IX, MANAGER_IX, NAME_IX)  
**수동 생성:** EMP_LAST_NAME_IDX

---

**[15번] 답**

```sql
CREATE INDEX emp_dept_job_idx
ON employees (department_id, job_id);
-- Index created.

SELECT employee_id, last_name, salary
FROM   employees
WHERE  department_id = 80
AND    job_id = 'SA_REP';
-- 30 rows (부서 80 SA_REP 사원들)

SELECT index_name, column_name, column_position
FROM   user_ind_columns
WHERE  index_name = 'EMP_DEPT_JOB_IDX';
```

예상 결과:
```
INDEX_NAME        COLUMN_NAME    COLUMN_POSITION
----------------- -------------- ---------------
EMP_DEPT_JOB_IDX  DEPARTMENT_ID  1
EMP_DEPT_JOB_IDX  JOB_ID         2
```

---

**[16번] 답**

```sql
CREATE INDEX emp_upper_last_idx
ON employees (UPPER(last_name));
-- Index created.

SELECT index_name, index_type
FROM   user_indexes
WHERE  index_name = 'EMP_UPPER_LAST_IDX';
-- EMP_UPPER_LAST_IDX  FUNCTION-BASED NORMAL

-- 함수 기반 인덱스 활용 (UPPER 사용 → 인덱스 사용 가능)
SELECT employee_id, last_name
FROM   employees
WHERE  UPPER(last_name) = 'KING';
-- 1 row: 100  King

-- 일반 검색 (UPPER 미사용 → emp_upper_last_idx 미활용)
SELECT employee_id, last_name
FROM   employees
WHERE  last_name = 'King';
-- 1 row: 100  King (EMP_NAME_IX 등 다른 인덱스 활용 가능)
```

---

**[17번] 답**

```sql
CREATE TABLE prod_orders (
    order_id    NUMBER(10)
        PRIMARY KEY USING INDEX
        (CREATE INDEX prod_ord_pk_idx ON prod_orders(order_id)),
    product_name VARCHAR2(100) NOT NULL,
    qty         NUMBER(5) DEFAULT 1
);
-- Table created.

SELECT index_name, table_name, uniqueness
FROM   user_indexes
WHERE  table_name = 'PROD_ORDERS';
```

예상 결과:
```
INDEX_NAME       TABLE_NAME   UNIQUENESS
---------------- ------------ ----------
PROD_ORD_PK_IDX  PROD_ORDERS  UNIQUE
```

> Oracle 자동 생성 이름(`SYS_C0...`) 대신 `PROD_ORD_PK_IDX`로 명명됨.

```sql
DROP TABLE prod_orders;
```

---

**[18번] 답**

```sql
DROP INDEX emp_last_name_idx;
DROP INDEX emp_dept_job_idx;
DROP INDEX emp_upper_last_idx;
-- Index dropped. (3회)

SELECT index_name FROM user_indexes
WHERE  index_name IN ('EMP_LAST_NAME_IDX','EMP_DEPT_JOB_IDX','EMP_UPPER_LAST_IDX');
-- no rows selected
```

---

## Group 4. 딕셔너리 뷰 종합 조회 모범답안 (19~24번)

---

**[19번] 답**

```sql
SELECT sequence_name, min_value, max_value, increment_by,
       cycle_flag, order_flag, cache_size, last_number
FROM   user_sequences
ORDER BY sequence_name;
```

HR 스키마 기본 시퀀스:
```
SEQUENCE_NAME    MIN  MAX           INCR  CYCLE  ORDER  CACHE  LAST_NUM
---------------- ---- ------------- ----- ------ ------ ------ --------
DEPARTMENTS_SEQ  1    9.99999E+26   10    N      N      20     280
EMPLOYEES_SEQ    1    9.99999E+26   1     N      N      20     207
LOCATIONS_SEQ    1    9.99999E+26   100   N      N      20     3300
```

실습에서 추가로 생성한 `DEPT_DEPTID_SEQ`, `EMP_ID_SEQ`도 표시됨.

---

**[20번] 답**

```sql
SELECT synonym_name, table_owner, table_name, db_link
FROM   user_synonyms
ORDER BY synonym_name;
```

**`DB_LINK` 컬럼의 의미:**  
원격 데이터베이스에 있는 객체를 참조할 때 사용하는 데이터베이스 링크 이름.  
예: `CREATE SYNONYM remote_emp FOR hr.employees@prod_db;` → `DB_LINK = 'PROD_DB'`  
로컬 객체 참조 시에는 NULL.

---

**[21번] 답**

```sql
SELECT i.table_name, i.index_name, i.uniqueness, i.index_type,
       c.column_name, c.column_position
FROM   user_indexes     i
JOIN   user_ind_columns c ON i.index_name = c.index_name
ORDER BY i.table_name, i.index_name, c.column_position;
```

예상 출력 구조 (일부):
```
TABLE_NAME   INDEX_NAME         UNIQUENESS  INDEX_TYPE  COLUMN_NAME    POS
------------ ------------------- ---------- ----------- -------------- ---
DEPARTMENTS  DEPT_ID_PK          UNIQUE      NORMAL      DEPARTMENT_ID  1
DEPARTMENTS  DEPT_LOCATION_IX    NONUNIQUE   NORMAL      LOCATION_ID    1
EMPLOYEES    EMP_DEPARTMENT_IX   NONUNIQUE   NORMAL      DEPARTMENT_ID  1
EMPLOYEES    EMP_EMAIL_UK        UNIQUE       NORMAL      EMAIL          1
EMPLOYEES    EMP_EMP_ID_PK       UNIQUE       NORMAL      EMPLOYEE_ID    1
...
```

---

**[22번] 답**

```sql
SELECT c.constraint_name, c.constraint_type,
       i.index_name, i.uniqueness
FROM   user_constraints c
JOIN   user_indexes     i ON c.constraint_name = i.index_name
WHERE  c.table_name = 'EMPLOYEES';
```

예상 결과:
```
CONSTRAINT_NAME   CONSTRAINT_TYPE  INDEX_NAME       UNIQUENESS
----------------- ---------------- ---------------- ----------
EMP_EMP_ID_PK     P                EMP_EMP_ID_PK    UNIQUE
EMP_EMAIL_UK      U                EMP_EMAIL_UK     UNIQUE
```

**분석:** PRIMARY KEY(`P`)와 UNIQUE(`U`) 제약 조건은 자동으로 UNIQUE 인덱스가 생성되며, **제약 조건 이름 = 인덱스 이름**으로 연결됨.

---

**[23번] 답**

```sql
SELECT table_name, comments FROM dictionary WHERE table_name LIKE '%SEQUENCE%';
-- USER_SEQUENCES, ALL_SEQUENCES, DBA_SEQUENCES

SELECT table_name, comments FROM dictionary WHERE table_name LIKE '%SYNONYM%';
-- USER_SYNONYMS, ALL_SYNONYMS, DBA_SYNONYMS

SELECT table_name, comments FROM dictionary WHERE table_name LIKE '%INDEX%';
-- USER_INDEXES, USER_IND_COLUMNS, USER_IND_EXPRESSIONS
-- ALL_INDEXES, ALL_IND_COLUMNS, DBA_INDEXES 등
```

---

**[24번] 답**

```sql
SELECT object_type, COUNT(*) AS cnt
FROM   user_objects
WHERE  object_type IN ('SEQUENCE', 'SYNONYM', 'INDEX')
GROUP BY object_type
ORDER BY object_type;
```

실습 전 HR 기본 스키마 예상 결과:
```
OBJECT_TYPE  CNT
------------ ---
INDEX        19
SEQUENCE     3
SYNONYM      0
```

실습 중 추가 객체가 있다면 해당 수가 증가한다.

---

## Group 5. 종합 실습 모범답안 (25~30번)

---

**[25번] 답**

```sql
CREATE SEQUENCE order_id_seq
    START WITH 1000 INCREMENT BY 1 MAXVALUE 9999999 CACHE 20 NOCYCLE;

CREATE TABLE my_orders (
    order_id      NUMBER DEFAULT order_id_seq.NEXTVAL PRIMARY KEY,
    customer_name VARCHAR2(100) NOT NULL,
    product_name  VARCHAR2(100) NOT NULL,
    qty           NUMBER(5)    DEFAULT 1 CHECK (qty > 0),
    order_date    DATE         DEFAULT SYSDATE,
    status        VARCHAR2(20) DEFAULT 'PENDING'
                               CHECK (status IN ('PENDING','SHIPPED','CANCELLED'))
);

CREATE INDEX my_ord_status_idx ON my_orders(status);
CREATE INDEX my_ord_date_idx   ON my_orders(order_date);
CREATE SYNONYM mo FOR my_orders;

INSERT INTO mo (customer_name, product_name, qty)
VALUES ('김철수', 'Oracle 교재', 2);
INSERT INTO mo (customer_name, product_name, qty, status)
VALUES ('이영희', 'USB 허브', 1, 'SHIPPED');
INSERT INTO mo (customer_name, product_name)
VALUES ('박민준', '마우스');
COMMIT;

SELECT order_id, customer_name, product_name, qty, status, order_date
FROM   mo ORDER BY order_id;
```

예상 결과:
```
ORDER_ID  CUSTOMER_NAME  PRODUCT_NAME  QTY  STATUS   ORDER_DATE
--------- -------------- ------------- ---- -------- ----------
1000      김철수          Oracle 교재    2    PENDING  28-JUN-26
1001      이영희          USB 허브       1    SHIPPED  28-JUN-26
1002      박민준          마우스          1    PENDING  28-JUN-26
```

---

**[26번] 답**

```sql
SELECT sequence_name, last_number, increment_by, cache_size
FROM   user_sequences WHERE sequence_name = 'ORDER_ID_SEQ';
-- ORDER_ID_SEQ  1020  1  20 (캐시 블록 끝: 1000~1019 사용, 다음은 1020)

SELECT index_name, uniqueness FROM user_indexes WHERE table_name = 'MY_ORDERS';
-- MY_ORDERS에 자동 생성된 PK 인덱스 + 수동 생성 2개

SELECT synonym_name, table_name FROM user_synonyms WHERE synonym_name = 'MO';
-- MO  MY_ORDERS
```

---

**[27번] 답**

```sql
-- 현재 NEXTVAL 호출 (예: 1003)
SELECT order_id_seq.NEXTVAL FROM dual;  -- 1003

-- 3건 INSERT
INSERT INTO mo (customer_name, product_name) VALUES ('테스트1', '상품A');  -- 1004
INSERT INTO mo (customer_name, product_name) VALUES ('테스트2', '상품B');  -- 1005
INSERT INTO mo (customer_name, product_name) VALUES ('테스트3', '상품C');  -- 1006
SELECT order_id_seq.CURRVAL FROM dual;  -- 1006

ROLLBACK;  -- INSERT 3건 취소

SELECT order_id_seq.NEXTVAL FROM dual;  -- 1007 (갭 발생!)

SELECT order_id FROM mo ORDER BY order_id;
-- 1000, 1001, 1002 (1003~1006은 갭)
```

**갭 발생 이유:**  
ROLLBACK은 DML(INSERT)을 취소하지만, 시퀀스는 별도의 독립 트랜잭션으로 관리된다. NEXTVAL 호출로 소비된 시퀀스 값은 ROLLBACK되지 않는다. 이는 Oracle의 의도적인 설계로, 시퀀스의 고유성과 성능을 보장하기 위함이다.

---

**[28번] 답**

```sql
-- 1. LAST_NAME 인덱스 활용 쿼리
EXPLAIN PLAN FOR
SELECT * FROM employees WHERE last_name = 'King';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- 실행 계획: INDEX RANGE SCAN (EMP_NAME_IX 또는 EMP_LAST_NAME_IDX)

-- 2. UPPER 함수로 인덱스 미활용
EXPLAIN PLAN FOR
SELECT * FROM employees WHERE UPPER(last_name) = 'KING';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- 실행 계획: TABLE ACCESS FULL (인덱스 미활용)

-- 3. 함수 기반 인덱스 생성 후
CREATE INDEX emp_ul_idx ON employees(UPPER(last_name));

EXPLAIN PLAN FOR
SELECT * FROM employees WHERE UPPER(last_name) = 'KING';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- 실행 계획: INDEX RANGE SCAN (EMP_UL_IDX 활용!)

DROP INDEX emp_ul_idx;
```

**핵심 학습:** WHERE 절에서 열에 함수를 적용하면 일반 인덱스를 사용할 수 없다. 이 경우 함수 기반 인덱스를 생성해야 한다.

---

**[29번] 답**

```sql
CREATE INDEX emp_dept_ix1 ON employees(department_id, salary);

ALTER INDEX emp_dept_ix1 INVISIBLE;

SELECT index_name, visibility, status
FROM   user_indexes WHERE index_name = 'EMP_DEPT_IX1';
-- EMP_DEPT_IX1  INVISIBLE  VALID

CREATE INDEX emp_sal_dept_ix2 ON employees(salary, department_id);

SELECT i.index_name, i.visibility, c.column_name, c.column_position
FROM   user_indexes i
JOIN   user_ind_columns c ON i.index_name = c.index_name
WHERE  i.index_name IN ('EMP_DEPT_IX1','EMP_SAL_DEPT_IX2')
ORDER BY i.index_name, c.column_position;
```

예상 결과:
```
INDEX_NAME         VISIBILITY  COLUMN_NAME    POSITION
------------------ ----------- -------------- --------
EMP_DEPT_IX1       INVISIBLE   DEPARTMENT_ID  1
EMP_DEPT_IX1       INVISIBLE   SALARY         2
EMP_SAL_DEPT_IX2   VISIBLE     SALARY         1
EMP_SAL_DEPT_IX2   VISIBLE     DEPARTMENT_ID  2
```

두 인덱스는 같은 열(DEPARTMENT_ID, SALARY)로 구성되지만 **순서가 다름**.  
`emp_dept_ix1`: WHERE department_id = ? 에 효과적  
`emp_sal_dept_ix2`: WHERE salary = ? 에 효과적

```sql
ALTER INDEX emp_dept_ix1 VISIBLE;
DROP INDEX emp_dept_ix1;
DROP INDEX emp_sal_dept_ix2;
```

---

**[30번] 답**

```sql
DROP SYNONYM mo;
DROP INDEX my_ord_status_idx;
DROP INDEX my_ord_date_idx;
DROP TABLE my_orders PURGE;
DROP TABLE new_employees PURGE;
DROP SEQUENCE order_id_seq;
DROP SEQUENCE emp_id_seq;
DROP SEQUENCE dept_deptid_seq;

SELECT object_name, object_type FROM user_objects
WHERE  object_name IN (
    'MO','MY_ORDERS','NEW_EMPLOYEES',
    'ORDER_ID_SEQ','EMP_ID_SEQ','DEPT_DEPTID_SEQ',
    'MY_ORD_STATUS_IDX','MY_ORD_DATE_IDX'
);
-- no rows selected
```

> **DROP 순서 주의:**  
> - `DROP INDEX`는 `DROP TABLE` 전에 수행 (DROP TABLE 시 해당 테이블 인덱스도 자동 삭제되지만 명시적으로 먼저 삭제해도 무방)  
> - `DROP TABLE PURGE`: Recycle Bin 없이 즉시 완전 삭제  
> - 시퀀스는 어떤 순서로 삭제해도 무관
