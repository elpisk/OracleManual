# Oracle Database 19c: SQL Workshop
## Chapter 17 — 서브쿼리를 이용한 데이터 조작 | SQL 실습 모범답안

---

## 실습 준비

```sql
CREATE TABLE empl7 AS SELECT * FROM employees;
CREATE TABLE dept7 AS SELECT * FROM departments;
CREATE TABLE empl7_history AS SELECT * FROM job_history;
CREATE TABLE loc7 AS SELECT * FROM locations;
```

---

## Group 1: INSERT INTO (서브쿼리) & INSERT INTO ... SELECT

**[1번]**
```sql
INSERT INTO (
    SELECT l.location_id, l.city, l.country_id
    FROM   loc7 l
    JOIN   countries c ON (l.country_id = c.country_id)
    JOIN   regions        USING (region_id)
    WHERE  region_name = 'Europe'
)
VALUES (3300, 'Cardiff', 'UK');

-- 확인
SELECT * FROM loc7 WHERE location_id = 3300;
-- location_id=3300, city='Cardiff', country_id='UK'
```

---

**[2번]**
```sql
INSERT INTO (
    SELECT l.location_id, l.city, l.country_id
    FROM   loc7 l
    JOIN   countries c ON (l.country_id = c.country_id)
    JOIN   regions        USING (region_id)
    WHERE  region_name = 'Europe'
    WITH CHECK OPTION
)
VALUES (9999, 'Sydney', 'AU');
-- ORA-01402: view WITH CHECK OPTION where-clause violation
```

**위반 이유:** `AU`(호주)는 `Europe` 지역이 아니므로 인라인 뷰의 WHERE 조건 위반.

---

**[3번]**
```sql
INSERT INTO empl7_history (employee_id, start_date, end_date, job_id, department_id)
SELECT employee_id, hire_date, SYSDATE, job_id, department_id
FROM   employees
WHERE  employee_id IN (100, 101, 176);

-- 확인
SELECT * FROM empl7_history WHERE employee_id IN (100, 101, 176);
-- 3행 삽입 확인
```

---

**[4번]**
```sql
CREATE TABLE sales_top_new AS SELECT * FROM empl7 WHERE 1=0;

INSERT INTO sales_top_new
SELECT *
FROM   empl7
WHERE  department_id = 80
AND    salary >= 10000;

-- 확인
SELECT COUNT(*) FROM sales_top_new;
```

---

**[5번]**
```sql
CREATE TABLE dept7_stats_new (
    department_id   NUMBER(4),
    department_name VARCHAR2(30),
    emp_count       NUMBER,
    avg_salary      NUMBER(10, 2)
);

INSERT INTO dept7_stats_new
SELECT d.department_id, d.department_name,
       COUNT(e.employee_id),
       ROUND(AVG(e.salary), 2)
FROM   dept7 d
LEFT JOIN empl7 e ON (d.department_id = e.department_id)
GROUP BY d.department_id, d.department_name;

-- 확인
SELECT * FROM dept7_stats_new ORDER BY department_id;
```

---

## Group 2: WITH CHECK OPTION (DML)

**[6번]**
```sql
INSERT INTO (
    SELECT location_id, city, country_id
    FROM   loc7
    WHERE  country_id = 'US'
    WITH CHECK OPTION
)
VALUES (9100, 'Dallas', 'US');

-- 확인
SELECT * FROM loc7 WHERE location_id = 9100;
-- 정상 삽입: country_id='US' 조건 만족
```

---

**[7번]**
```sql
INSERT INTO (
    SELECT location_id, city, country_id
    FROM   loc7
    WHERE  country_id = 'US'
    WITH CHECK OPTION
)
VALUES (9200, 'Toronto', 'CA');
-- ORA-01402: view WITH CHECK OPTION where-clause violation
```

오류 원인: `CA`(캐나다)는 `country_id = 'US'` 조건 위반.

---

**[8번]**
```sql
UPDATE (
    SELECT employee_id, salary, department_id
    FROM   empl7
    WHERE  department_id = 80
    WITH CHECK OPTION
)
SET department_id = 90
WHERE employee_id = 145;
-- ORA-01402: view WITH CHECK OPTION where-clause violation
```

`WITH CHECK OPTION`: `department_id = 80` 조건이 위반되는 방향으로의 UPDATE 차단.

---

**[9번]**
```sql
UPDATE (
    SELECT l.location_id, l.city, l.country_id
    FROM   loc7 l
    JOIN   countries c ON (l.country_id = c.country_id)
    JOIN   regions        USING (region_id)
    WHERE  region_name = 'Europe'
    WITH CHECK OPTION
)
SET    city = 'London Updated'
WHERE  city = 'London';

-- 확인
SELECT location_id, city, country_id
FROM   loc7
WHERE  city = 'London Updated';
```

---

**[10번]**
```sql
-- A: WITH CHECK OPTION 없음 → 삽입 성공
INSERT INTO (SELECT location_id, city, country_id FROM loc7 WHERE country_id = 'UK')
VALUES (8001, 'Glasgow', 'UK');

-- B: WITH CHECK OPTION 있음 → 'UK' 조건 만족하므로 삽입 성공
INSERT INTO (SELECT location_id, city, country_id FROM loc7 WHERE country_id = 'UK' WITH CHECK OPTION)
VALUES (8002, 'Glasgow', 'UK');

-- 확인
SELECT * FROM loc7 WHERE location_id IN (8001, 8002);
-- 두 행 모두 삽입됨 (country_id='UK'이므로 조건 만족)
```

---

## Group 3: 상관 UPDATE

**[11번]**
```sql
ALTER TABLE empl7 ADD dept_name VARCHAR2(30);

UPDATE empl7 e
SET    dept_name = (
    SELECT department_name
    FROM   departments d
    WHERE  d.department_id = e.department_id
);

-- 확인
SELECT employee_id, last_name, department_id, dept_name
FROM   empl7
WHERE  ROWNUM <= 10;
```

---

**[12번]**
```sql
UPDATE empl7 e
SET    salary = (
    SELECT AVG(salary)
    FROM   empl7
    WHERE  department_id = e.department_id
);

-- 갱신 건수 확인
-- SQL%ROWCOUNT: 107행 (empl7 전체 행)
SELECT COUNT(*) FROM empl7;  -- 갱신 후 전체 행 수 확인
```

---

**[13번]**
```sql
UPDATE empl7 e
SET    salary = (
    SELECT j.max_salary * 0.9
    FROM   jobs j
    WHERE  j.job_id = e.job_id
)
WHERE department_id = 80;

-- 확인
SELECT employee_id, last_name, salary, job_id
FROM   empl7
WHERE  department_id = 80
ORDER BY salary DESC;
```

---

**[14번]**
```sql
ALTER TABLE empl7 ADD mgr_salary NUMBER(8, 2);

UPDATE empl7 e
SET    mgr_salary = (
    SELECT salary
    FROM   empl7
    WHERE  employee_id = e.manager_id
);

-- 확인: 최상위 관리자는 mgr_salary = NULL
SELECT employee_id, last_name, manager_id, salary, mgr_salary
FROM   empl7
WHERE  manager_id IS NULL;  -- mgr_salary = NULL 확인
```

---

**[15번]**
```sql
UPDATE (
    SELECT e.salary, mx.max_sal
    FROM   empl7 e
    JOIN   (
        SELECT department_id, MAX(salary) max_sal
        FROM   empl7
        GROUP BY department_id
    ) mx ON (e.department_id = mx.department_id)
)
SET salary = max_sal;

-- 확인
SELECT department_id, salary
FROM   empl7
WHERE  ROWNUM <= 10
ORDER BY department_id;
```

부서별 MAX 계산이 인라인 뷰에서 한 번만 수행됨 → 상관 UPDATE 대비 성능 개선.

---

## Group 4: 상관 DELETE

**[16번]**
```sql
-- 삭제 전 건수 확인
SELECT COUNT(*)
FROM   empl7 e
WHERE EXISTS (SELECT NULL FROM empl7_history WHERE employee_id = e.employee_id);

-- 삭제 실행
DELETE FROM empl7 e
WHERE EXISTS (
    SELECT NULL
    FROM   empl7_history eh
    WHERE  eh.employee_id = e.employee_id
);

-- 삭제 건수 확인 후 롤백
ROLLBACK;
```

---

**[17번]**
```sql
-- 삭제될 건수 사전 확인
SELECT COUNT(*)
FROM   empl7 e
WHERE NOT EXISTS (SELECT NULL FROM empl7_history WHERE employee_id = e.employee_id);

-- 삭제 실행
DELETE FROM empl7 e
WHERE NOT EXISTS (
    SELECT NULL
    FROM   empl7_history eh
    WHERE  eh.employee_id = e.employee_id
);

ROLLBACK;
```

---

**[18번]**
```sql
-- 삭제 전 건수 확인
SELECT COUNT(*)
FROM   dept7 d
WHERE NOT EXISTS (SELECT NULL FROM empl7 e WHERE e.department_id = d.department_id);

-- 삭제 실행
DELETE FROM dept7 d
WHERE NOT EXISTS (
    SELECT NULL
    FROM   empl7 e
    WHERE  e.department_id = d.department_id
);

-- 삭제 건수 확인 후 롤백
ROLLBACK;
```

---

**[19번]**
```sql
-- 방식 A: NOT IN (department_id IS NOT NULL 조건으로 NULL 처리)
DELETE FROM dept7 d
WHERE department_id NOT IN (
    SELECT DISTINCT department_id FROM empl7 WHERE department_id IS NOT NULL
);
-- 삭제 건수 확인
ROLLBACK;

-- 방식 B: NOT EXISTS
DELETE FROM dept7 d
WHERE NOT EXISTS (
    SELECT NULL FROM empl7 e WHERE e.department_id = d.department_id
);
-- 삭제 건수 확인
ROLLBACK;
```

두 방식의 삭제 건수 비교:
- `IS NOT NULL` 조건으로 NULL을 제거한 A와 B는 동일한 결과를 반환.
- A에서 `IS NOT NULL` 미적용 시 NULL로 인해 더 많거나 적은 결과가 나올 수 있음.

---

**[20번]**
```sql
-- 삭제될 건수 확인
SELECT COUNT(*)
FROM   empl7 e
WHERE  salary < (
    SELECT AVG(salary) FROM empl7 WHERE job_id = e.job_id
);

-- 삭제 실행
DELETE FROM empl7 e
WHERE salary < (
    SELECT AVG(salary)
    FROM   empl7
    WHERE  job_id = e.job_id
);

ROLLBACK;
```

---

## Group 5: 종합 DML 실습

**[21번]**
```sql
-- 1. 테이블 생성
CREATE TABLE empl7_archive_new AS SELECT * FROM empl7 WHERE 1=0;

-- 2. 급여 12,000 이상 직원 복사
INSERT INTO empl7_archive_new
SELECT * FROM empl7 WHERE salary >= 12000;

-- 3. empl7에서 복사된 직원 급여 10% 인상
UPDATE empl7 e
SET    salary = salary * 1.1
WHERE  salary >= 12000;

-- 4. 결과 확인 후 COMMIT
SELECT employee_id, last_name, salary FROM empl7 WHERE salary >= 13200 ORDER BY salary DESC;
COMMIT;
```

---

**[22번]**
```sql
SAVEPOINT start_point;

-- 1단계: 부서 90번 직원 급여 5% 인상
UPDATE empl7 SET salary = salary * 1.05 WHERE department_id = 90;

SAVEPOINT after_update;

-- 2단계: 직원 없는 부서 삭제
DELETE FROM dept7 d
WHERE NOT EXISTS (SELECT NULL FROM empl7 e WHERE e.department_id = d.department_id);

-- 3단계: 2단계(DELETE)만 취소
ROLLBACK TO after_update;

-- 4단계: 최종 확인
SELECT COUNT(*) FROM dept7;  -- 원래 부서 수 (27)
SELECT salary FROM empl7 WHERE department_id = 90 AND employee_id = 100;  -- 5% 인상 유지
```

---

**[23번]**
```sql
UPDATE empl7 e
SET    salary = (
    SELECT AVG(salary) * 0.9
    FROM   empl7
    WHERE  department_id = e.department_id
)
WHERE  salary < (
    SELECT AVG(salary) * 0.7
    FROM   empl7
    WHERE  department_id = e.department_id
);

-- 갱신 건수 확인
SELECT COUNT(*) updated_count FROM empl7
WHERE salary = (
    SELECT ROUND(AVG(salary) * 0.9, 2)
    FROM   empl7
    WHERE  department_id = empl7.department_id
);
```

---

**[24번]**
```sql
ALTER TABLE empl7 ADD team_leader_new VARCHAR2(25);

UPDATE empl7 e
SET    team_leader_new = (
    SELECT last_name
    FROM   empl7
    WHERE  department_id = e.department_id
    AND    salary = (SELECT MAX(salary) FROM empl7 WHERE department_id = e.department_id)
    AND    ROWNUM = 1
);

-- 팀 리더 자신 확인 (최고 급여자의 team_leader_new가 자신의 last_name인지)
SELECT employee_id, last_name, salary, department_id, team_leader_new
FROM   empl7
WHERE  department_id = 80
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;
```

---

**[25번]**
```sql
-- Step 1: 테이블 생성 및 데이터 복사
CREATE TABLE empl7_vip_new AS SELECT * FROM empl7 WHERE 1=0;
ALTER TABLE empl7_vip_new ADD dept_name_x VARCHAR2(30);

INSERT INTO empl7_vip_new (employee_id, first_name, last_name, email,
    phone_number, hire_date, job_id, salary, commission_pct,
    manager_id, department_id)
SELECT employee_id, first_name, last_name, email,
    phone_number, hire_date, job_id, salary, commission_pct,
    manager_id, department_id
FROM empl7 WHERE salary >= 15000;

-- Step 2: 부서명 채우기 (상관 UPDATE)
UPDATE empl7_vip_new v
SET    dept_name_x = (
    SELECT department_name
    FROM   departments d
    WHERE  d.department_id = v.department_id
);

-- Step 3: 직무 이력 없는 직원 삭제
DELETE FROM empl7_vip_new v
WHERE NOT EXISTS (
    SELECT NULL
    FROM   empl7_history eh
    WHERE  eh.employee_id = v.employee_id
);

-- Step 4: 최종 출력 후 COMMIT
SELECT employee_id, last_name, salary, dept_name_x
FROM   empl7_vip_new
ORDER BY salary DESC;

COMMIT;
```

---

**[26번]**
```sql
DROP TABLE empl7 PURGE;
DROP TABLE dept7 PURGE;
DROP TABLE empl7_history PURGE;
DROP TABLE loc7 PURGE;
DROP TABLE sales_top_new PURGE;
DROP TABLE dept7_stats_new PURGE;
DROP TABLE empl7_archive_new PURGE;
DROP TABLE empl7_vip_new PURGE;

-- 정리 확인
SELECT table_name FROM user_tables
WHERE  table_name LIKE 'EMPL7%' OR table_name LIKE 'DEPT7%'
    OR table_name LIKE 'LOC7%' OR table_name LIKE 'SALES_TOP%';
-- no rows selected
```
