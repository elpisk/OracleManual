# Oracle Database 19c: SQL Workshop
## Chapter 19 — 고급 쿼리를 이용한 데이터 조작 | SQL 실습 문제

---

> **참고:** 이 실습은 HR 스키마가 설치된 Oracle 19c 환경에서 수행하세요.  
> 각 그룹 시작 전 필요한 테이블을 생성하는 준비 SQL이 포함되어 있습니다.

---

## Group 1: DEFAULT 키워드

**[준비]**
```sql
CREATE TABLE deptm3 AS SELECT * FROM departments WHERE 1=2;
ALTER TABLE deptm3 MODIFY manager_id DEFAULT 100;
```

---

**[1번]** deptm3 테이블에 manager_id를 명시하지 않고 아래 행을 삽입한 뒤, DEFAULT 값이 자동 적용됨을 확인하시오.

```sql
-- INSERT 수행
INSERT INTO deptm3 (department_id, department_name)
VALUES (300, 'Research');

-- 확인
SELECT department_id, department_name, manager_id
FROM   deptm3
WHERE  department_id = 300;
-- manager_id = 100 이어야 함
```

---

**[2번]** INSERT 시 DEFAULT 키워드를 명시적으로 사용하여 동일한 결과를 만드시오.

```sql
INSERT INTO deptm3 (department_id, department_name, manager_id)
VALUES (301, 'Innovation', DEFAULT);

SELECT department_id, department_name, manager_id
FROM   deptm3
WHERE  department_id = 301;
```

---

**[3번]** UPDATE 문에서 DEFAULT 키워드를 사용하여 department_id = 300의 manager_id를 DEFAULT 값으로 재설정하시오. (먼저 manager_id를 999로 변경 후 DEFAULT로 복원)

```sql
-- 임시 변경
UPDATE deptm3 SET manager_id = 999 WHERE department_id = 300;

-- DEFAULT로 복원
UPDATE deptm3 SET manager_id = DEFAULT WHERE department_id = 300;

-- 확인 (100이어야 함)
SELECT department_id, manager_id FROM deptm3 WHERE department_id = 300;

ROLLBACK;
```

---

## Group 2: Unconditional INSERT ALL

**[준비]**
```sql
CREATE TABLE sal_history  (empid NUMBER, hiredate DATE, sal NUMBER);
CREATE TABLE mgr_history  (empid NUMBER, mgr NUMBER, sal NUMBER);
```

---

**[4번]** employee_id > 200인 직원을 sal_history와 mgr_history에 동시에 삽입하시오.

```sql
INSERT ALL
    INTO sal_history VALUES (empid, hiredate, sal)
    INTO mgr_history VALUES (empid, mgr, sal)
SELECT employee_id empid, hire_date hiredate,
       salary sal, manager_id mgr
FROM   employees
WHERE  employee_id > 200;

-- 삽입 건수 확인
SELECT 'sal_history' tbl, COUNT(*) cnt FROM sal_history
UNION ALL
SELECT 'mgr_history', COUNT(*) FROM mgr_history;
```

---

**[5번]** sal_history와 mgr_history 데이터를 조회하여 내용을 확인하시오.

```sql
SELECT s.empid, s.hiredate, s.sal, m.mgr
FROM   sal_history s
JOIN   mgr_history m ON (s.empid = m.empid)
ORDER BY s.empid;
```

---

## Group 3: Conditional INSERT ALL

**[준비]**
```sql
CREATE TABLE emp_history (empid NUMBER, hiredate DATE, sal NUMBER);
CREATE TABLE emp_sales   (empid NUMBER, comm NUMBER, sal NUMBER);
```

---

**[6번]** 다음 조건으로 Conditional INSERT ALL을 실행하시오.
- 입사일이 2006년 1월 1일 이전이면 emp_history에 삽입
- 커미션이 NULL이 아니면 emp_sales에 삽입
- (두 조건을 모두 만족하는 직원은 양쪽에 모두 삽입)

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
```

---

**[7번]** emp_history와 emp_sales 양쪽에 모두 삽입된 직원(입사일 2006 이전 + 커미션 보유)을 조회하시오.

```sql
SELECT h.empid, h.hiredate, s.comm
FROM   emp_history h
JOIN   emp_sales s ON (h.empid = s.empid)
ORDER BY h.empid;
```

---

## Group 4: Conditional INSERT FIRST

**[준비]**
```sql
CREATE TABLE sal_low   (empid NUMBER, name VARCHAR2(50), sal NUMBER);
CREATE TABLE sal_mid   (empid NUMBER, name VARCHAR2(50), sal NUMBER);
CREATE TABLE sal_high  (empid NUMBER, name VARCHAR2(50), sal NUMBER);
```

---

**[8번]** 직원 급여를 세 구간으로 분류하여 각 테이블에 삽입하시오 (한 직원은 반드시 하나의 테이블에만 들어가야 함).
- salary < 5000 → sal_low
- salary BETWEEN 5000 AND 10000 → sal_mid
- 나머지 → sal_high

```sql
INSERT FIRST
    WHEN salary < 5000 THEN
        INTO sal_low VALUES (employee_id, last_name, salary)
    WHEN salary BETWEEN 5000 AND 10000 THEN
        INTO sal_mid VALUES (employee_id, last_name, salary)
    ELSE
        INTO sal_high VALUES (employee_id, last_name, salary)
SELECT employee_id, last_name, salary
FROM   employees;

SELECT 'sal_low'  tbl, COUNT(*) FROM sal_low
UNION ALL
SELECT 'sal_mid'  tbl, COUNT(*) FROM sal_mid
UNION ALL
SELECT 'sal_high' tbl, COUNT(*) FROM sal_high;
```

---

**[9번]** 세 테이블의 총 행 수가 employees 테이블의 전체 행 수와 같은지 확인하시오.

```sql
SELECT (SELECT COUNT(*) FROM sal_low) +
       (SELECT COUNT(*) FROM sal_mid) +
       (SELECT COUNT(*) FROM sal_high) AS total_inserted,
       (SELECT COUNT(*) FROM employees) AS employees_total
FROM dual;
-- 두 값이 같아야 함
```

---

**[10번]** sal_high에 삽입된 직원 중 급여가 가장 높은 상위 3명을 조회하시오.

```sql
SELECT empid, name, sal
FROM   sal_high
ORDER BY sal DESC
FETCH FIRST 3 ROWS ONLY;
```

---

## Group 5: Pivoting INSERT

**[준비]**
```sql
CREATE TABLE sales_source_data (
    employee_id NUMBER,
    week_id     NUMBER,
    sales_mon   NUMBER,
    sales_tue   NUMBER,
    sales_wed   NUMBER,
    sales_thur  NUMBER,
    sales_fri   NUMBER
);

INSERT INTO sales_source_data VALUES (176, 6, 2000, 3000, 4000, 5000, 6000);
INSERT INTO sales_source_data VALUES (177, 6, 1500, 2500, 3500, 4500, 5500);
INSERT INTO sales_source_data VALUES (178, 6, 1000, 2000, 3000, 4000, 5000);
COMMIT;

CREATE TABLE sales_info (
    employee_id NUMBER,
    week_id     NUMBER,
    sales       NUMBER
);
```

---

**[11번]** Pivoting INSERT를 사용하여 sales_source_data의 요일별 열을 sales_info 테이블에 행 단위로 변환하여 삽입하시오.

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
-- 3 소스 행 × 5 요일 = 15행 이어야 함
```

---

**[12번]** sales_info에서 직원별 주간 총 매출과 일 평균 매출을 구하시오.

```sql
SELECT employee_id,
       SUM(sales)   AS week_total,
       ROUND(AVG(sales), 2) AS day_avg
FROM   sales_info
GROUP BY employee_id
ORDER BY week_total DESC;
```

---

## Group 6: MERGE 문

**[준비]**
```sql
CREATE TABLE copy_emp3 AS SELECT * FROM employees WHERE 1=2;
-- 일부 행만 미리 삽입 (employee_id 100~110)
INSERT INTO copy_emp3
SELECT * FROM employees WHERE employee_id BETWEEN 100 AND 110;
COMMIT;
```

---

**[13번]** employees 테이블을 소스로 copy_emp3를 동기화하는 MERGE 문을 작성하시오.
- 이미 존재하면: last_name, salary, department_id 업데이트
- 없으면: 새 행 삽입

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

-- copy_emp3 행 수가 employees와 같아야 함
SELECT COUNT(*) FROM copy_emp3;
```

---

**[14번]** MERGE 문에서 WHEN MATCHED THEN UPDATE 후 DELETE WHERE를 추가하여 커미션이 있는 직원 행을 삭제하시오.

```sql
MERGE INTO copy_emp3 c
USING (SELECT * FROM employees) e
ON    (c.employee_id = e.employee_id)
WHEN MATCHED THEN
    UPDATE SET c.salary = e.salary
    DELETE WHERE (e.commission_pct IS NOT NULL);

-- 커미션 있는 직원 수 확인
SELECT COUNT(*) FROM employees WHERE commission_pct IS NOT NULL;

-- copy_emp3에서 커미션 있던 직원 행이 삭제됐는지 확인
SELECT COUNT(*) FROM copy_emp3;

ROLLBACK;
```

---

**[15번]** 신규 부서(department_id = 999, department_name = 'Temp')와 기존 부서(department_id = 10)를 소스로 MERGE를 수행하시오.

```sql
-- 소스 테이블 생성
CREATE TABLE dept_update_src (
    department_id   NUMBER,
    department_name VARCHAR2(50),
    location_id     NUMBER
);
INSERT INTO dept_update_src VALUES (10, 'Admin Updated', 1700);
INSERT INTO dept_update_src VALUES (999, 'Temp Department', 1400);
COMMIT;

-- MERGE 실행
MERGE INTO departments d
USING dept_update_src s
ON    (d.department_id = s.department_id)
WHEN MATCHED THEN
    UPDATE SET d.department_name = s.department_name
WHEN NOT MATCHED THEN
    INSERT (department_id, department_name, location_id)
    VALUES (s.department_id, s.department_name, s.location_id);

-- 결과 확인
SELECT department_id, department_name, location_id
FROM   departments
WHERE  department_id IN (10, 999)
ORDER BY department_id;

ROLLBACK;
```

---

## Group 7: FLASHBACK TABLE

**[준비]**
```sql
CREATE TABLE emp3 AS SELECT * FROM employees;
COMMIT;
ALTER TABLE emp3 ENABLE ROW MOVEMENT;
```

---

**[16번]** emp3 테이블의 일부 데이터를 수정하고, FLASHBACK TABLE로 복구하시오.

```sql
-- 수정 전 상태 저장 (현재 타임스탬프)
SELECT SYSTIMESTAMP FROM DUAL;
-- 이 시각을 기록해 둠 (예: '26-JUN-26 10.30.00')

-- 데이터 변경
UPDATE emp3 SET salary = salary * 2 WHERE department_id = 90;
COMMIT;

-- 변경 확인
SELECT employee_id, last_name, salary FROM emp3 WHERE department_id = 90;

-- FLASHBACK TABLE로 복구 (위에서 기록한 시각 사용)
FLASHBACK TABLE emp3
TO TIMESTAMP TO_TIMESTAMP('2026-06-26 10:30:00', 'YYYY-MM-DD HH24:MI:SS');

-- 복구 확인 (원래 급여로 돌아와야 함)
SELECT employee_id, last_name, salary FROM emp3 WHERE department_id = 90;
```

---

**[17번]** emp3 테이블을 DROP하고 RECYCLEBIN에서 복구하시오.

```sql
-- 테이블 삭제
DROP TABLE emp3;

-- RECYCLEBIN 확인
SELECT original_name, operation, droptime
FROM   recyclebin
WHERE  original_name = 'EMP3';

-- 복구
FLASHBACK TABLE emp3 TO BEFORE DROP;

-- 복구 확인
SELECT COUNT(*) FROM emp3;
-- 107행이어야 함
```

---

## Group 8: Flashback Query & Flashback Version Query

**[준비]**
```sql
CREATE TABLE employees3 AS SELECT * FROM employees;
COMMIT;
```

---

**[18번]** Flashback Query로 특정 직원의 과거 급여를 조회하시오.

```sql
-- 현재 급여 확인
SELECT employee_id, last_name, salary FROM employees3 WHERE employee_id = 107;

-- 급여 변경
UPDATE employees3 SET salary = 9999 WHERE employee_id = 107;
COMMIT;

-- 1분 전 급여 조회 (변경 전 값)
SELECT salary
FROM   employees3
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '1' MINUTE)
WHERE  employee_id = 107;
-- 원래 급여가 표시되어야 함

ROLLBACK;
```

---

**[19번]** Flashback Version Query로 특정 직원의 급여 변경 이력을 조회하시오.

```sql
-- 여러 번 급여 변경
UPDATE employees3 SET salary = 3000 WHERE employee_id = 107; COMMIT;
UPDATE employees3 SET salary = 4000 WHERE employee_id = 107; COMMIT;
UPDATE employees3 SET salary = 5000 WHERE employee_id = 107; COMMIT;

-- 변경 이력 조회
SELECT versions_starttime "시작시각",
       versions_endtime   "종료시각",
       salary             "급여"
FROM   employees3
VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE
WHERE  employee_id = 107
ORDER BY versions_starttime;
-- 급여 변경 이력(3000, 4000, 5000)이 시간순으로 나타나야 함
```

---

**[20번]** Flashback Version Query의 SCN과 TIMESTAMP를 함께 조회하시오.

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
-- versions_operation: I(INSERT), U(Update), D(Delete)
```

---

## Group 9: 종합 실습

**[21번]** 다음 조건으로 직원을 4개 테이블에 분류하여 삽입하는 INSERT FIRST를 작성하시오.
- department_id = 90 → exec_team
- salary >= 10000 → high_earner
- hire_date < DATE '2003-01-01' → veteran
- 나머지 → general_staff

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

SELECT 'exec_team'     t, COUNT(*) FROM exec_team
UNION ALL SELECT 'high_earner',  COUNT(*) FROM high_earner
UNION ALL SELECT 'veteran',      COUNT(*) FROM veteran
UNION ALL SELECT 'general_staff',COUNT(*) FROM general_staff;
```

---

**[22번]** 다음 소스 데이터를 사용하여 departments 테이블에 MERGE를 적용하시오. 존재하는 부서는 위치만 업데이트하고, 없는 부서는 삽입하시오. 단, location_id가 9999인 소스 행은 삽입하지 마시오 (WHERE 필터 사용).

```sql
CREATE TABLE dept_changes (
    department_id   NUMBER,
    department_name VARCHAR2(50),
    location_id     NUMBER
);
INSERT INTO dept_changes VALUES (20,  'Marketing2', 1800);
INSERT INTO dept_changes VALUES (888, 'Test Dept', 1300);
INSERT INTO dept_changes VALUES (999, 'Skip Dept', 9999);
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

-- 결과 확인
SELECT department_id, department_name, location_id
FROM   departments
WHERE  department_id IN (20, 888, 999)
ORDER BY department_id;

ROLLBACK;
```

---

**[23번]** employees3 테이블에서 급여를 변경하고 AS OF TIMESTAMP로 과거 값을 이용하여 원상 복구하시오 (DML 실수 복구 시나리오).

```sql
-- 현재 시각 기록
SELECT SYSTIMESTAMP AS current_time FROM DUAL;

-- 실수로 여러 직원 급여를 1로 만든 경우
UPDATE employees3 SET salary = 1 WHERE department_id = 80;
COMMIT;

-- 현재 상태 (잘못된 데이터)
SELECT COUNT(*), SUM(salary) FROM employees3 WHERE department_id = 80;

-- Flashback Query로 과거 급여 확인
SELECT employee_id, salary
FROM   employees3
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '5' MINUTE)
WHERE  department_id = 80;

-- 과거 데이터로 복구 (UPDATE ... AS OF 패턴)
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
```

---

**[24번]** 다음 시나리오에서 INSERT ALL과 INSERT FIRST의 차이를 직접 확인하시오.

```sql
CREATE TABLE test_all   (empid NUMBER, name VARCHAR2(50), salary NUMBER);
CREATE TABLE test_first (empid NUMBER, name VARCHAR2(50), salary NUMBER);

-- 조건: salary > 5000이거나 department_id = 80인 직원

-- INSERT ALL 사용
INSERT ALL
    WHEN salary > 5000 THEN
        INTO test_all VALUES (employee_id, last_name, salary)
    WHEN department_id = 80 THEN
        INTO test_all VALUES (employee_id, last_name, salary)
SELECT employee_id, last_name, salary, department_id FROM employees;

-- 결과 확인 (두 조건 모두 만족하는 직원은 중복 삽입)
SELECT COUNT(*) FROM test_all;

-- INSERT FIRST 사용
INSERT FIRST
    WHEN salary > 5000 THEN
        INTO test_first VALUES (employee_id, last_name, salary)
    WHEN department_id = 80 THEN
        INTO test_first VALUES (employee_id, last_name, salary)
SELECT employee_id, last_name, salary, department_id FROM employees;

-- 결과 비교 (중복 없음)
SELECT COUNT(*) FROM test_first;

-- 두 테이블 행 수 비교
SELECT 'test_all'   t, COUNT(*) FROM test_all
UNION ALL
SELECT 'test_first' t, COUNT(*) FROM test_first;
```

---

**[25번]** 아래 시나리오를 순서대로 실행하여 전체 복구 흐름을 실습하시오.

```sql
-- 1단계: 테이블 생성 및 현재 시각 기록
CREATE TABLE dept_backup AS SELECT * FROM departments;
COMMIT;
SELECT SYSTIMESTAMP FROM DUAL;  -- 이 시각을 메모

-- 2단계: 실수로 departments 데이터 삭제
DELETE FROM dept_backup;
COMMIT;

-- 3단계: Flashback Query로 삭제 전 데이터 확인
SELECT COUNT(*)
FROM   dept_backup
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '2' MINUTE);

-- 4단계: 삭제된 데이터를 과거 데이터로 복구
INSERT INTO dept_backup
SELECT *
FROM   dept_backup
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '2' MINUTE);
COMMIT;

-- 5단계: 복구 확인
SELECT COUNT(*) FROM dept_backup;
-- 원래 행 수(27행)와 같아야 함

-- 정리
DROP TABLE dept_backup;
```

---

**[26번]** RECYCLEBIN 조회 및 관리 실습을 수행하시오.

```sql
-- 실습용 테이블 생성
CREATE TABLE recycle_test1 AS SELECT * FROM employees WHERE ROWNUM <= 10;
CREATE TABLE recycle_test2 AS SELECT * FROM employees WHERE ROWNUM <= 5;
COMMIT;

-- 테이블 삭제 (RECYCLEBIN으로 이동)
DROP TABLE recycle_test1;
DROP TABLE recycle_test2;

-- RECYCLEBIN 확인
SELECT object_name, original_name, operation, droptime, space
FROM   recyclebin
ORDER BY droptime DESC;

-- 하나만 복구
FLASHBACK TABLE recycle_test1 TO BEFORE DROP;

-- 복구 확인
SELECT COUNT(*) FROM recycle_test1;

-- 나머지 정리 (RECYCLEBIN에서 영구 삭제)
PURGE TABLE recycle_test2;

-- 최종 RECYCLEBIN 확인
SELECT original_name FROM recyclebin
WHERE  original_name IN ('RECYCLE_TEST1', 'RECYCLE_TEST2');

-- 정리
DROP TABLE recycle_test1 PURGE;
```
