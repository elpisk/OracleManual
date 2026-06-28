# Oracle Database 19c: SQL Workshop
## Chapter 19 — 고급 쿼리를 이용한 데이터 조작 | SQL 실습 모범답안

---

## Group 1: DEFAULT 키워드

**[1번]**
```sql
INSERT INTO deptm3 (department_id, department_name)
VALUES (300, 'Research');

SELECT department_id, department_name, manager_id
FROM   deptm3
WHERE  department_id = 300;
-- DEPARTMENT_ID  DEPARTMENT_NAME  MANAGER_ID
-- 300            Research         100
-- → manager_id를 지정하지 않았지만 DEFAULT 값 100이 자동 삽입됨
```

---

**[2번]**
```sql
INSERT INTO deptm3 (department_id, department_name, manager_id)
VALUES (301, 'Innovation', DEFAULT);

SELECT department_id, department_name, manager_id
FROM   deptm3
WHERE  department_id = 301;
-- DEPARTMENT_ID  DEPARTMENT_NAME  MANAGER_ID
-- 301            Innovation       100
-- → DEFAULT 키워드로 명시적으로 100 삽입
```

**DEFAULT 키워드 차이:** 1번은 열 목록에서 manager_id를 생략, 2번은 VALUES에 DEFAULT를 명시. 결과는 동일하며 두 방법 모두 DEFAULT 값 100을 삽입함.

---

**[3번]**
```sql
-- 임시 변경
UPDATE deptm3 SET manager_id = 999 WHERE department_id = 300;

SELECT manager_id FROM deptm3 WHERE department_id = 300;
-- 999

-- DEFAULT로 복원
UPDATE deptm3 SET manager_id = DEFAULT WHERE department_id = 300;

SELECT department_id, manager_id FROM deptm3 WHERE department_id = 300;
-- 300  100  ← DEFAULT 값으로 복원됨

ROLLBACK;
```

---

## Group 2: Unconditional INSERT ALL

**[4번]**
```sql
INSERT ALL
    INTO sal_history VALUES (empid, hiredate, sal)
    INTO mgr_history VALUES (empid, mgr, sal)
SELECT employee_id empid, hire_date hiredate,
       salary sal, manager_id mgr
FROM   employees
WHERE  employee_id > 200;

-- 삽입 건수 확인 (employee_id > 200인 직원: 7명)
SELECT 'sal_history' tbl, COUNT(*) cnt FROM sal_history
UNION ALL
SELECT 'mgr_history', COUNT(*) FROM mgr_history;
-- sal_history  7
-- mgr_history  7
-- → 소스 7행 × 2 INTO 절 = 각 테이블에 7행씩 삽입
```

---

**[5번]**
```sql
SELECT s.empid, s.hiredate, s.sal, m.mgr
FROM   sal_history s
JOIN   mgr_history m ON (s.empid = m.empid)
ORDER BY s.empid;
-- EMPID  HIREDATE    SAL    MGR
-- 201    17-FEB-04   13000  100
-- 202    17-AUG-02   6000   201
-- ...
-- 양 테이블 모두 동일한 직원 7명이 저장됨을 확인
```

---

## Group 3: Conditional INSERT ALL

**[6번]**
```sql
INSERT ALL
    WHEN hiredate < DATE '2006-01-01' THEN
        INTO emp_history VALUES (empid, hiredate, sal)
    WHEN comm IS NOT NULL THEN
        INTO emp_sales VALUES (empid, comm, sal)
SELECT employee_id empid, hire_date hiredate,
       salary sal, commission_pct comm
FROM   employees;

SELECT 'emp_history' tbl, COUNT(*) FROM emp_history
UNION ALL
SELECT 'emp_sales', COUNT(*) FROM emp_sales;
-- emp_history  (2006년 이전 입사 직원 수)
-- emp_sales    (커미션 보유 직원 수)
-- 두 조건을 모두 만족하는 직원은 양쪽에 모두 삽입됨
```

---

**[7번]**
```sql
SELECT h.empid, h.hiredate, s.comm
FROM   emp_history h
JOIN   emp_sales s ON (h.empid = s.empid)
ORDER BY h.empid;
-- 2006년 이전 입사 + 커미션 보유 직원만 조회됨
-- INSERT ALL의 중복 삽입 동작 확인
```

---

## Group 4: Conditional INSERT FIRST

**[8번]**
```sql
INSERT FIRST
    WHEN salary < 5000 THEN
        INTO sal_low VALUES (employee_id, last_name, salary)
    WHEN salary BETWEEN 5000 AND 10000 THEN
        INTO sal_mid VALUES (employee_id, last_name, salary)
    ELSE
        INTO sal_high VALUES (employee_id, last_name, salary)
SELECT employee_id, last_name, salary FROM employees;

SELECT 'sal_low'  tbl, COUNT(*) FROM sal_low
UNION ALL
SELECT 'sal_mid'  tbl, COUNT(*) FROM sal_mid
UNION ALL
SELECT 'sal_high' tbl, COUNT(*) FROM sal_high;
-- 세 테이블 행 수 합계 = 107 (employees 전체)
```

---

**[9번]**
```sql
SELECT (SELECT COUNT(*) FROM sal_low) +
       (SELECT COUNT(*) FROM sal_mid) +
       (SELECT COUNT(*) FROM sal_high) AS total_inserted,
       (SELECT COUNT(*) FROM employees) AS employees_total
FROM dual;
-- TOTAL_INSERTED  EMPLOYEES_TOTAL
-- 107             107
-- → INSERT FIRST는 한 직원을 하나의 테이블에만 삽입하므로 총합 = 원본 행 수
```

---

**[10번]**
```sql
SELECT empid, name, sal
FROM   sal_high
ORDER BY sal DESC
FETCH FIRST 3 ROWS ONLY;
-- 급여 > 10000인 직원 중 최고 급여 3명 출력
-- EMPID  NAME           SAL
-- 100    King           24000
-- 101    Kochhar        17000
-- 102    De Haan        17000
```

---

## Group 5: Pivoting INSERT

**[11번]**
```sql
INSERT ALL
    INTO sales_info VALUES (employee_id, week_id, sales_mon)
    INTO sales_info VALUES (employee_id, week_id, sales_tue)
    INTO sales_info VALUES (employee_id, week_id, sales_wed)
    INTO sales_info VALUES (employee_id, week_id, sales_thur)
    INTO sales_info VALUES (employee_id, week_id, sales_fri)
SELECT employee_id, week_id,
       sales_mon, sales_tue, sales_wed, sales_thur, sales_fri
FROM   sales_source_data;

SELECT COUNT(*) FROM sales_info;
-- 15
-- 소스 3행 × 5 요일 = 15행 삽입 완료
```

---

**[12번]**
```sql
SELECT employee_id,
       SUM(sales)              AS week_total,
       ROUND(AVG(sales), 2)   AS day_avg
FROM   sales_info
GROUP BY employee_id
ORDER BY week_total DESC;
-- EMPLOYEE_ID  WEEK_TOTAL  DAY_AVG
-- 176          20000       4000
-- 177          17500       3500
-- 178          15000       3000
```

---

## Group 6: MERGE 문

**[13번]**
```sql
MERGE INTO copy_emp3 c
USING (SELECT * FROM employees) e
ON    (c.employee_id = e.employee_id)
WHEN MATCHED THEN
    UPDATE SET
        c.last_name     = e.last_name,
        c.salary        = e.salary,
        c.department_id = e.department_id
WHEN NOT MATCHED THEN
    INSERT (employee_id, first_name, last_name, email,
            phone_number, hire_date, job_id, salary,
            commission_pct, manager_id, department_id)
    VALUES (e.employee_id, e.first_name, e.last_name, e.email,
            e.phone_number, e.hire_date, e.job_id, e.salary,
            e.commission_pct, e.manager_id, e.department_id);

SELECT COUNT(*) FROM copy_emp3;
-- 107
-- 기존 11행(100~110) 업데이트 + 나머지 96행 삽입 = 107행
```

---

**[14번]**
```sql
MERGE INTO copy_emp3 c
USING (SELECT * FROM employees) e
ON    (c.employee_id = e.employee_id)
WHEN MATCHED THEN
    UPDATE SET c.salary = e.salary
    DELETE WHERE (e.commission_pct IS NOT NULL);

-- 커미션 있는 직원 수
SELECT COUNT(*) FROM employees WHERE commission_pct IS NOT NULL;
-- 35

-- copy_emp3 잔여 행 수 (커미션 있는 직원 35명 삭제됨)
SELECT COUNT(*) FROM copy_emp3;
-- 107 - 35 = 72

ROLLBACK;
-- copy_emp3 원상 복구됨
```

---

**[15번]**
```sql
CREATE TABLE dept_update_src (
    department_id   NUMBER,
    department_name VARCHAR2(50),
    location_id     NUMBER
);
INSERT INTO dept_update_src VALUES (10, 'Admin Updated', 1700);
INSERT INTO dept_update_src VALUES (999, 'Temp Department', 1400);
COMMIT;

MERGE INTO departments d
USING dept_update_src s
ON    (d.department_id = s.department_id)
WHEN MATCHED THEN
    UPDATE SET d.department_name = s.department_name
WHEN NOT MATCHED THEN
    INSERT (department_id, department_name, location_id)
    VALUES (s.department_id, s.department_name, s.location_id);

SELECT department_id, department_name, location_id
FROM   departments
WHERE  department_id IN (10, 999)
ORDER BY department_id;
-- 10   Admin Updated       1700   ← 이름 변경됨
-- 999  Temp Department     1400   ← 새 행 삽입됨

ROLLBACK;
```

---

## Group 7: FLASHBACK TABLE

**[16번]**
```sql
-- 기록한 시각으로 복구 (예: 2026-06-26 10:30:00)
UPDATE emp3 SET salary = salary * 2 WHERE department_id = 90;
COMMIT;

SELECT employee_id, last_name, salary FROM emp3 WHERE department_id = 90;
-- 급여가 2배로 변경된 상태

FLASHBACK TABLE emp3
TO TIMESTAMP TO_TIMESTAMP('2026-06-26 10:30:00', 'YYYY-MM-DD HH24:MI:SS');

SELECT employee_id, last_name, salary FROM emp3 WHERE department_id = 90;
-- 원래 급여로 복구됨
-- King: 24000, Kochhar: 17000, De Haan: 17000
```

**핵심:** ENABLE ROW MOVEMENT가 활성화되어 있어야 TIMESTAMP 기반 복구가 가능함.

---

**[17번]**
```sql
DROP TABLE emp3;

SELECT original_name, operation, droptime
FROM   recyclebin
WHERE  original_name = 'EMP3';
-- EMP3  DROP  (삭제 시각)

FLASHBACK TABLE emp3 TO BEFORE DROP;

SELECT COUNT(*) FROM emp3;
-- 107
-- 테이블이 RECYCLEBIN에서 원래 이름으로 복구됨
```

---

## Group 8: Flashback Query & Flashback Version Query

**[18번]**
```sql
-- 현재 급여
SELECT employee_id, last_name, salary FROM employees3 WHERE employee_id = 107;
-- 107  Lorentz  4200

UPDATE employees3 SET salary = 9999 WHERE employee_id = 107;
COMMIT;

-- 변경 후
SELECT salary FROM employees3 WHERE employee_id = 107;
-- 9999

-- 1분 전 데이터 조회
SELECT salary
FROM   employees3
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '1' MINUTE)
WHERE  employee_id = 107;
-- 4200  ← 변경 전 급여가 조회됨

ROLLBACK;
```

---

**[19번]**
```sql
UPDATE employees3 SET salary = 3000 WHERE employee_id = 107; COMMIT;
UPDATE employees3 SET salary = 4000 WHERE employee_id = 107; COMMIT;
UPDATE employees3 SET salary = 5000 WHERE employee_id = 107; COMMIT;

SELECT versions_starttime "시작시각",
       versions_endtime   "종료시각",
       salary             "급여"
FROM   employees3
VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE
WHERE  employee_id = 107
ORDER BY versions_starttime;

-- 시작시각                종료시각                급여
-- 26-JUN-26 09.00.00.0   26-JUN-26 09.01.00.0   4200 (원본)
-- 26-JUN-26 09.01.00.0   26-JUN-26 09.02.00.0   3000 (1차 변경)
-- 26-JUN-26 09.02.00.0   26-JUN-26 09.03.00.0   4000 (2차 변경)
-- 26-JUN-26 09.03.00.0   (null: 현재 버전)       5000 (최신)
```

---

**[20번]**
```sql
SELECT versions_startscn  "시작SCN",
       versions_endscn    "종료SCN",
       versions_starttime "시작시각",
       versions_endtime   "종료시각",
       versions_operation "작업",
       salary
FROM   employees3
VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE
WHERE  employee_id = 107
ORDER BY versions_startscn NULLS FIRST;

-- 시작SCN  종료SCN  시작시각  종료시각  작업  급여
-- (null)   1000     (null)    시각1     (null) 4200  ← 원본(INSERT)
-- 1000     2000     시각1     시각2     U      3000  ← UPDATE
-- 2000     3000     시각2     시각3     U      4000  ← UPDATE
-- 3000     (null)   시각3     (null)    U      5000  ← 현재 버전
-- versions_operation: I=INSERT, U=UPDATE, D=DELETE
```

---

## Group 9: 종합 실습

**[21번]**
```sql
CREATE TABLE exec_team     (empid NUMBER, name VARCHAR2(50), sal NUMBER, dept NUMBER);
CREATE TABLE high_earner   (empid NUMBER, name VARCHAR2(50), sal NUMBER, dept NUMBER);
CREATE TABLE veteran       (empid NUMBER, name VARCHAR2(50), hiredate DATE, dept NUMBER);
CREATE TABLE general_staff (empid NUMBER, name VARCHAR2(50), sal NUMBER, dept NUMBER);

INSERT FIRST
    WHEN department_id = 90 THEN
        INTO exec_team VALUES (employee_id, last_name, salary, department_id)
    WHEN salary >= 10000 THEN
        INTO high_earner VALUES (employee_id, last_name, salary, department_id)
    WHEN hire_date < DATE '2003-01-01' THEN
        INTO veteran VALUES (employee_id, last_name, hire_date, department_id)
    ELSE
        INTO general_staff VALUES (employee_id, last_name, salary, department_id)
SELECT employee_id, last_name, salary, hire_date, department_id
FROM   employees;

SELECT 'exec_team'      t, COUNT(*) cnt FROM exec_team
UNION ALL SELECT 'high_earner',   COUNT(*) FROM high_earner
UNION ALL SELECT 'veteran',       COUNT(*) FROM veteran
UNION ALL SELECT 'general_staff', COUNT(*) FROM general_staff;

-- exec_team:     3  (department_id = 90인 임원)
-- high_earner:   (salary ≥ 10000이면서 dept ≠ 90인 직원)
-- veteran:       (2003년 이전 입사, salary < 10000, dept ≠ 90)
-- general_staff: 나머지
-- 합계 = 107
```

**핵심:** INSERT FIRST는 조건 우선순위를 가지므로, 임원(dept=90)이면 salary와 상관없이 exec_team에만 들어간다.

---

**[22번]**
```sql
CREATE TABLE dept_changes (
    department_id   NUMBER,
    department_name VARCHAR2(50),
    location_id     NUMBER
);
INSERT INTO dept_changes VALUES (20,  'Marketing2', 1800);
INSERT INTO dept_changes VALUES (888, 'Test Dept',  1300);
INSERT INTO dept_changes VALUES (999, 'Skip Dept',  9999);
COMMIT;

MERGE INTO departments d
USING dept_changes s
ON    (d.department_id = s.department_id)
WHEN MATCHED THEN
    UPDATE SET d.location_id = s.location_id
WHEN NOT MATCHED THEN
    INSERT (department_id, department_name, location_id)
    VALUES (s.department_id, s.department_name, s.location_id)
    WHERE  s.location_id != 9999;

SELECT department_id, department_name, location_id
FROM   departments
WHERE  department_id IN (20, 888, 999)
ORDER BY department_id;
-- 20   Marketing2   1800   ← location_id만 업데이트됨
-- 888  Test Dept    1300   ← 새 행 삽입됨
-- (999 없음)               ← WHERE 필터로 삽입 제외됨

ROLLBACK;
```

---

**[23번]**
```sql
-- 실수 시뮬레이션: department_id = 80 직원 급여를 1로 변경
SELECT SYSTIMESTAMP AS ts FROM DUAL;

UPDATE employees3 SET salary = 1 WHERE department_id = 80;
COMMIT;

-- 잘못된 현재 상태
SELECT COUNT(*), SUM(salary) FROM employees3 WHERE department_id = 80;
-- n명  n (모두 1로 바뀜)

-- 5분 전 데이터로 복구
UPDATE employees3 e3
SET    salary = (
    SELECT salary
    FROM   employees3
    AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '5' MINUTE)
    WHERE  employee_id = e3.employee_id
)
WHERE department_id = 80;
COMMIT;

-- 복구 확인
SELECT COUNT(*), SUM(salary) FROM employees3 WHERE department_id = 80;
-- 원래 합계로 복구됨
```

**핵심:** AS OF TIMESTAMP를 서브쿼리로 사용하여 현재 테이블을 과거 데이터로 UPDATE하는 패턴.

---

**[24번]**
```sql
CREATE TABLE test_all   (empid NUMBER, name VARCHAR2(50), salary NUMBER);
CREATE TABLE test_first (empid NUMBER, name VARCHAR2(50), salary NUMBER);

-- INSERT ALL: 두 조건 모두 만족하는 직원은 중복 삽입
INSERT ALL
    WHEN salary > 5000 THEN
        INTO test_all VALUES (employee_id, last_name, salary)
    WHEN department_id = 80 THEN
        INTO test_all VALUES (employee_id, last_name, salary)
SELECT employee_id, last_name, salary, department_id FROM employees;

SELECT COUNT(*) FROM test_all;
-- salary > 5000인 직원 수 + department_id = 80인 직원 수 - (salary > 5000이면서 dept=80인 직원이 중복으로 포함)

-- INSERT FIRST: 첫 번째 조건에 해당하는 테이블에만 삽입
INSERT FIRST
    WHEN salary > 5000 THEN
        INTO test_first VALUES (employee_id, last_name, salary)
    WHEN department_id = 80 THEN
        INTO test_first VALUES (employee_id, last_name, salary)
SELECT employee_id, last_name, salary, department_id FROM employees;

SELECT COUNT(*) FROM test_first;
-- salary > 5000이면 무조건 test_first에 삽입, dept=80 조건은 평가 안 함

SELECT 'test_all'   t, COUNT(*) FROM test_all
UNION ALL
SELECT 'test_first' t, COUNT(*) FROM test_first;
-- test_all이 더 많음 (중복 삽입 발생)
```

---

**[25번]**
```sql
-- 1단계
CREATE TABLE dept_backup AS SELECT * FROM departments;
COMMIT;
SELECT SYSTIMESTAMP FROM DUAL;

-- 2단계: 실수로 전체 삭제
DELETE FROM dept_backup;
COMMIT;

-- 3단계: 삭제 전 데이터 확인
SELECT COUNT(*)
FROM   dept_backup
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '2' MINUTE);
-- 27

-- 4단계: 복구
INSERT INTO dept_backup
SELECT *
FROM   dept_backup
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '2' MINUTE);
COMMIT;

-- 5단계: 확인
SELECT COUNT(*) FROM dept_backup;
-- 27  ← 원래 행 수로 복구 완료

DROP TABLE dept_backup;
```

**핵심 패턴:** `INSERT INTO table SELECT * FROM table AS OF TIMESTAMP ...` — 삭제된 데이터를 Flashback Query로 복원하는 표준 패턴.

---

**[26번]**
```sql
CREATE TABLE recycle_test1 AS SELECT * FROM employees WHERE ROWNUM <= 10;
CREATE TABLE recycle_test2 AS SELECT * FROM employees WHERE ROWNUM <= 5;
COMMIT;

DROP TABLE recycle_test1;
DROP TABLE recycle_test2;

-- RECYCLEBIN 확인
SELECT object_name, original_name, operation, droptime, space
FROM   recyclebin
ORDER BY droptime DESC;
-- BIN$...$0  RECYCLE_TEST1  DROP  ...
-- BIN$...$0  RECYCLE_TEST2  DROP  ...

-- recycle_test1 복구
FLASHBACK TABLE recycle_test1 TO BEFORE DROP;

SELECT COUNT(*) FROM recycle_test1;
-- 10

-- recycle_test2 영구 삭제
PURGE TABLE recycle_test2;

SELECT original_name FROM recyclebin
WHERE  original_name IN ('RECYCLE_TEST1', 'RECYCLE_TEST2');
-- no rows selected (PURGE로 완전 제거됨)

-- 정리
DROP TABLE recycle_test1 PURGE;
-- PURGE 옵션: RECYCLEBIN으로 이동하지 않고 즉시 영구 삭제
```

**PURGE 옵션 정리:**
| 명령 | 설명 |
|------|------|
| `DROP TABLE t` | RECYCLEBIN으로 이동 (복구 가능) |
| `DROP TABLE t PURGE` | 즉시 영구 삭제 (복구 불가) |
| `PURGE TABLE t` | RECYCLEBIN의 특정 테이블 영구 삭제 |
| `PURGE RECYCLEBIN` | RECYCLEBIN 전체 비우기 |
