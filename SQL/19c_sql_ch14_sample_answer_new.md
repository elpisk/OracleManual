# Oracle Database 19c: SQL Workshop
## Chapter 14 — 뷰(View) 생성 | SQL 실습 모범답안

---

## Group 1: 단순 뷰 생성 & 조회

**[1번]**
```sql
CREATE VIEW emp_dept50_vu
AS SELECT employee_id, last_name, salary, hire_date
   FROM   employees
   WHERE  department_id = 50;
```

---

**[2번]**
```sql
SELECT *
FROM   emp_dept50_vu;
```

결과: 부서 50번 직원 45명의 employee_id, last_name, salary, hire_date 출력.

---

**[3번]**
```sql
DESCRIBE emp_dept50_vu;
```

또는 SQL Developer에서:
```sql
SELECT column_name, data_type, nullable
FROM   user_tab_columns
WHERE  table_name = 'EMP_DEPT50_VU'
ORDER BY column_id;
```

출력:
```
EMPLOYEE_ID   NUMBER(6,0)  NOT NULL
LAST_NAME     VARCHAR2(25) NOT NULL
SALARY        NUMBER(8,2)
HIRE_DATE     DATE         NOT NULL
```

---

**[4번]**
```sql
CREATE VIEW emp_annual_sal_vu
AS SELECT employee_id,
          last_name,
          salary * 12 annual_salary
   FROM   employees;
```

---

**[5번]**
```sql
CREATE OR REPLACE VIEW emp_dept50_vu
    (EMP_ID, NAME, MONTHLY_SAL, START_DATE)
AS SELECT employee_id, last_name, salary, hire_date
   FROM   employees
   WHERE  department_id = 50;
```

뷰 이름 뒤 괄호 안에 열 별칭을 서브쿼리 열 순서대로 나열.

---

**[6번]**
```sql
SELECT view_name
FROM   user_views
ORDER BY view_name;
```

---

## Group 2: 뷰 수정 & 복합 뷰

**[7번]**
```sql
CREATE OR REPLACE VIEW emp_dept50_vu
AS SELECT employee_id, last_name, salary, hire_date, department_id
   FROM   employees
   WHERE  department_id = 50;
```

---

**[8번]**
```sql
CREATE VIEW emp_dept_vu
AS SELECT e.employee_id,
          e.last_name,
          d.department_name,
          l.city
   FROM   employees   e
   JOIN   departments d USING (department_id)
   JOIN   locations   l USING (location_id);
```

---

**[9번]**
```sql
CREATE VIEW dept_sal_stats_vu
    (department_name, min_sal, max_sal, avg_sal)
AS SELECT d.department_name,
          MIN(e.salary),
          MAX(e.salary),
          AVG(e.salary)
   FROM   employees   e
   JOIN   departments d USING (department_id)
   GROUP BY d.department_name;
```

---

**[10번]**
```sql
CREATE VIEW job_avg_sal_vu
AS SELECT job_id, AVG(salary) avg_salary
   FROM   employees
   GROUP BY job_id
   HAVING AVG(salary) >= 8000;
```

---

**[11번]**
```sql
SELECT last_name, department_name
FROM   emp_dept_vu
WHERE  city = 'Seattle';
```

---

**[12번]**
```sql
SELECT text
FROM   user_views
WHERE  view_name = 'DEPT_SAL_STATS_VU';
```

`TEXT` 컬럼에 뷰를 정의한 서브쿼리 전체가 출력됨.

---

## Group 3: WITH CHECK OPTION & WITH READ ONLY

**[13번]**
```sql
CREATE OR REPLACE VIEW emp_dept20_ck_vu
AS SELECT *
   FROM   employees
   WHERE  department_id = 20
WITH CHECK OPTION CONSTRAINT empvu20_ck;
```

---

**[14번]**
```sql
INSERT INTO emp_dept20_ck_vu
    (employee_id, last_name, email, hire_date, job_id, department_id)
VALUES (500, 'TestUser', 'TESTUSER', SYSDATE, 'MK_REP', 30);
```

**결과:**
```
ORA-01402: view WITH CHECK OPTION where-clause violation
```

`department_id = 30`이 뷰의 WHERE 조건(`department_id = 20`)을 위반.

---

**[15번]**
```sql
INSERT INTO emp_dept20_ck_vu
    (employee_id, last_name, email, hire_date, job_id, department_id)
VALUES (501, 'GoodUser', 'GOODUSER', SYSDATE, 'MK_REP', 20);

-- 뷰 조회 (department_id = 20인 행만 보임)
SELECT employee_id, last_name, department_id
FROM   emp_dept20_ck_vu
WHERE  employee_id = 501;

-- 기반 테이블 조회
SELECT employee_id, last_name, department_id
FROM   employees
WHERE  employee_id = 501;

ROLLBACK;
```

결과: 뷰와 기반 테이블 모두에서 employee_id = 501 행이 조회됨.  
ROLLBACK 후 삽입 취소.

---

**[16번]**
```sql
CREATE OR REPLACE VIEW emp_dept10_ro_vu
    (employee_number, employee_name, job_title)
AS SELECT employee_id, last_name, job_id
   FROM   employees
   WHERE  department_id = 10
WITH READ ONLY;
```

---

**[17번]**
```sql
DELETE FROM emp_dept10_ro_vu WHERE employee_number = 200;
```

**결과:**
```
ORA-42399: cannot perform a DML operation on a read-only view
```

`WITH READ ONLY` 뷰에서는 DELETE/UPDATE/INSERT 모두 차단.

---

**[18번]**
```sql
-- 1. 뷰 생성
CREATE OR REPLACE VIEW emp_dept80_vu
AS SELECT *
   FROM   employees
   WHERE  department_id = 80;

-- 2. department_id = 90으로 삽입 (WITH CHECK OPTION 없음)
INSERT INTO emp_dept80_vu
    (employee_id, last_name, email, hire_date, job_id, department_id, salary)
VALUES (502, 'Ghost', 'GHOST', SYSDATE, 'SA_REP', 90, 5000);
-- 1 row created.

-- 3. 뷰 재조회 → 보이지 않음 (WHERE department_id = 80 조건 불만족)
SELECT employee_id, last_name, department_id
FROM   emp_dept80_vu
WHERE  employee_id = 502;
-- no rows selected

-- 4. 기반 테이블에서 확인 → 존재함
SELECT employee_id, last_name, department_id
FROM   employees
WHERE  employee_id = 502;
-- 502  Ghost  90 → 존재!

-- 5. 정리
ROLLBACK;
```

이것이 WITH CHECK OPTION 없을 때의 "사라지는 행" 현상.

---

## Group 4: DML 제한 사항

**[19번]**
```sql
CREATE OR REPLACE VIEW dept_sal_vu AS
SELECT department_id, MAX(salary) max_sal
FROM   employees GROUP BY department_id;

DELETE FROM dept_sal_vu WHERE department_id = 80;
```

**결과:**
```
ORA-01732: data manipulation operation not legal on this view
```

GROUP BY + 집계 함수 포함 뷰 → DELETE 불가.

---

**[20번]**
```sql
CREATE OR REPLACE VIEW emp_expr_vu AS
SELECT employee_id, last_name, salary * 12 annual_sal
FROM   employees;

INSERT INTO emp_expr_vu VALUES (600, 'Kim', 96000);
```

**결과:**
```
ORA-01733: virtual column not allowed here
```

`salary * 12`는 가상 열(표현식) → INSERT 불가.

---

**[21번]**
```sql
CREATE OR REPLACE VIEW emp_simple_vu AS
SELECT employee_id, last_name, salary, department_id
FROM   employees WHERE department_id IN (10, 20, 30);

-- UPDATE 시도 (단순 뷰, 표현식 없음)
UPDATE emp_simple_vu SET salary = 7000 WHERE employee_id = 200;
-- 결과: 1 row updated ✔

-- DELETE 시도
DELETE FROM emp_simple_vu WHERE employee_id = 200;
-- 결과: 1 row deleted ✔

-- INSERT 시도 (email, hire_date, job_id 등 필수 열 누락 → 오류)
INSERT INTO emp_simple_vu (employee_id, last_name, email, hire_date, job_id, department_id)
VALUES (601, 'Test', 'TEST', SYSDATE, 'AD_ASST', 10);
-- 결과: employees 테이블의 NOT NULL 열이 모두 충족되면 삽입 성공
-- 위 예에서는 email, hire_date, job_id 포함 → 성공 가능

ROLLBACK;
```

단순 뷰 + 실제 열만 포함 → UPDATE, DELETE, INSERT 모두 가능.

---

**[22번]**
```sql
CREATE OR REPLACE VIEW distinct_dept_vu AS
SELECT DISTINCT department_id FROM employees;

DELETE FROM distinct_dept_vu WHERE department_id = 80;
```

**결과:**
```
ORA-01732: data manipulation operation not legal on this view
```

DISTINCT 포함 뷰 → DML 불가.

---

**[23번]**
```sql
CREATE OR REPLACE VIEW top10_emp_vu AS
SELECT employee_id, last_name, salary
FROM   employees WHERE ROWNUM <= 10;

UPDATE top10_emp_vu SET salary = 9999 WHERE employee_id = 100;
```

**결과:**
```
ORA-01732: data manipulation operation not legal on this view
```

ROWNUM 포함 뷰 → DML 불가.

---

**[24번]**
```sql
CREATE OR REPLACE VIEW emp_dept_join_vu AS
SELECT e.employee_id, e.last_name, d.department_name
FROM   employees e JOIN departments d USING (department_id);

-- UPDATE (key-preserved 테이블: employees 측)
UPDATE emp_dept_join_vu SET last_name = 'NewName' WHERE employee_id = 100;
-- 결과: key-preserved인 경우 성공할 수 있음 (Oracle이 내부적으로 판단)

-- DELETE
DELETE FROM emp_dept_join_vu WHERE employee_id = 100;
-- 결과: ORA-01732 — 어느 테이블에서 삭제할지 모호하므로 실패
```

**참고:** JOIN 뷰에서 key-preserved 테이블 열의 UPDATE는 허용될 수 있지만,  
DELETE는 항상 불가. 안전을 위해 JOIN 뷰에서는 DML을 피하는 것이 좋음.

---

## Group 5: 뷰 삭제 & 종합

**[25번]**
```sql
-- 삭제 전 확인
SELECT view_name FROM user_views WHERE view_name = 'EMP_DEPT50_VU';

-- 뷰 삭제
DROP VIEW emp_dept50_vu;

-- 삭제 후 확인
SELECT view_name FROM user_views WHERE view_name = 'EMP_DEPT50_VU';
-- no rows selected
```

---

**[26번]**
```sql
-- 1. 임시 테이블 생성
CREATE TABLE temp_emp AS SELECT employee_id, last_name FROM employees WHERE 1=0;

-- 2. 뷰 생성
CREATE VIEW temp_emp_vu AS SELECT * FROM temp_emp;

-- 3. STATUS 확인 (VALID)
SELECT object_name, status FROM user_objects WHERE object_name = 'TEMP_EMP_VU';
-- TEMP_EMP_VU  VALID

-- 4. 기반 테이블 삭제
DROP TABLE temp_emp;

-- 5. STATUS 재확인 (INVALID)
SELECT object_name, status FROM user_objects WHERE object_name = 'TEMP_EMP_VU';
-- TEMP_EMP_VU  INVALID

-- 6. 뷰 조회 시도
SELECT * FROM temp_emp_vu;
-- ORA-04063: view "HR.TEMP_EMP_VU" has errors

-- 정리
DROP VIEW temp_emp_vu;
```

**핵심 학습:** 기반 테이블 삭제 시 뷰는 INVALID 상태로 남음.

---

**[27번]**
```sql
-- 1. 존재하지 않는 테이블 기반 뷰 생성 (FORCE)
CREATE FORCE VIEW ghost_vu AS
SELECT id, name FROM ghost_table;
-- Warning: View created with compilation errors.

-- 2. STATUS 확인 (INVALID)
SELECT object_name, status FROM user_objects WHERE object_name = 'GHOST_VU';
-- GHOST_VU  INVALID

-- 3. 기반 테이블 생성
CREATE TABLE ghost_table (id NUMBER, name VARCHAR2(50));

-- 4. STATUS 재확인 (자동 변경 여부 — Oracle 버전에 따라 다름)
SELECT object_name, status FROM user_objects WHERE object_name = 'GHOST_VU';
-- 일부 버전: 여전히 INVALID → ALTER VIEW ghost_vu COMPILE; 실행 필요

ALTER VIEW ghost_vu COMPILE;
SELECT object_name, status FROM user_objects WHERE object_name = 'GHOST_VU';
-- GHOST_VU  VALID

-- 정리
DROP VIEW ghost_vu;
DROP TABLE ghost_table;
```

---

**[28번]**
```sql
-- 1. 급여 5000 초과 직원 뷰
CREATE VIEW high_sal_vu
AS SELECT employee_id, last_name, salary, department_id
   FROM   employees
   WHERE  salary > 5000;

-- 2. high_sal_vu 기반 부서 80번 뷰
CREATE VIEW dept80_high_sal_vu
AS SELECT *
   FROM   high_sal_vu
   WHERE  department_id = 80;

-- 3. 조회
SELECT employee_id, last_name, salary
FROM   dept80_high_sal_vu
ORDER BY salary DESC;
```

결과: 부서 80번이면서 급여 5000 초과인 직원 목록 출력.

---

**[29번]**
```sql
CREATE OR REPLACE VIEW emp_summary_vu
AS SELECT e.employee_id,
          e.first_name || ' ' || e.last_name AS full_name,
          d.department_name,
          j.job_title,
          e.salary * 12                       AS annual_salary
   FROM   employees   e
   JOIN   departments d USING (department_id)
   JOIN   jobs        j USING (job_id)
   WHERE  e.salary * 12 >= 50000
WITH READ ONLY;

-- 조회 (부서명 정렬)
SELECT employee_id, full_name, department_name, job_title,
       TO_CHAR(annual_salary, '$999,999') annual_salary
FROM   emp_summary_vu
ORDER BY department_name;
```

`WITH READ ONLY`로 DML 차단. 연봉 5만 이상 직원의 종합 정보 표시.

---

**[30번]**
```sql
DROP VIEW emp_dept50_vu;
DROP VIEW emp_annual_sal_vu;
DROP VIEW emp_dept_vu;
DROP VIEW dept_sal_stats_vu;
DROP VIEW job_avg_sal_vu;
DROP VIEW emp_dept20_ck_vu;
DROP VIEW emp_dept10_ro_vu;
DROP VIEW emp_dept80_vu;
DROP VIEW dept_sal_vu;
DROP VIEW emp_expr_vu;
DROP VIEW emp_simple_vu;
DROP VIEW distinct_dept_vu;
DROP VIEW top10_emp_vu;
DROP VIEW emp_dept_join_vu;
DROP VIEW high_sal_vu;
DROP VIEW dept80_high_sal_vu;
DROP VIEW emp_summary_vu;

-- 정리 확인
SELECT view_name FROM user_views
WHERE  view_name LIKE 'EMP%'
    OR view_name LIKE 'DEPT%'
    OR view_name LIKE 'JOB%'
    OR view_name LIKE 'DISTINCT%'
    OR view_name LIKE 'TOP%'
ORDER BY view_name;
-- no rows selected
```

모든 실습 뷰 삭제 완료.
