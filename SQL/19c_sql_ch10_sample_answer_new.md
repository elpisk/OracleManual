# Oracle Database 19c: SQL Workshop
## Chapter 10 — DML 문을 사용한 테이블 관리 | SQL 실습 문제 모범답안

---

## Group 1. INSERT 문 모범답안 (1~6번)

---

**[1번] 답**

```sql
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (280, 'Research', 100, 1700);
```

---

**[2번] 답**

```sql
-- 암묵적 방법: 열 목록에서 manager_id, location_id 생략
INSERT INTO departments (department_id, department_name)
VALUES (290, 'Corporate Tax');
```

---

**[3번] 답**

```sql
-- 명시적 방법: NULL 키워드 사용
INSERT INTO departments
VALUES (300, 'Strategy', NULL, NULL);
-- 또는
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (300, 'Strategy', NULL, NULL);
```

---

**[4번] 답**

```sql
INSERT INTO employees (employee_id, first_name, last_name, email,
                       phone_number, hire_date, job_id, salary,
                       commission_pct, manager_id, department_id)
VALUES (207, 'James', 'Brown', 'JBROWN', '515.123.9999',
        CURRENT_DATE, 'IT_PROG', 7500, NULL, 103, 60);
```

---

**[5번] 답**

```sql
INSERT INTO employees (employee_id, first_name, last_name, email,
                       phone_number, hire_date, job_id, salary,
                       commission_pct, manager_id, department_id)
VALUES (208, 'Alice', 'Kim', 'AKIM', '515.123.8888',
        TO_DATE('15-JAN-2020', 'DD-MON-YYYY'),
        'SA_REP', 8500, 0.15, 145, 80);
```

---

**[6번] 답**

```sql
INSERT INTO copy_emp
SELECT * FROM employees
WHERE  job_id LIKE '%REP%';

-- 또는 더 구체적으로:
INSERT INTO copy_emp
SELECT * FROM employees
WHERE  job_id IN ('SA_REP', 'PU_CLERK', 'MK_REP');
```

> `job_id LIKE '%REP%'`에 해당하는 사원: SA_REP (30명), PU_MAN 등 포함 가능  
> HR 스키마 기준으로 약 32명 삽입됨

---

## Group 2. UPDATE 문 모범답안 (7~12번)

---

**[7번] 답**

```sql
UPDATE copy_emp
SET    salary = 25000
WHERE  employee_id = 100;
```

---

**[8번] 답**

```sql
UPDATE copy_emp
SET    salary = salary * 1.1
WHERE  department_id = 50;
```

> 부서 50 사원: 45명 → 45 rows updated

---

**[9번] 답**

```sql
UPDATE copy_emp
SET    (job_id, salary) = (SELECT job_id, salary
                            FROM   copy_emp
                            WHERE  employee_id = 205)
WHERE  employee_id = 200;
```

> employee_id=205(Higgins, AC_MGR, 12008)의 값으로 employee_id=200(Whalen)을 변경

---

**[10번] 답**

```sql
UPDATE copy_emp
SET    commission_pct = NULL
WHERE  employee_id = 115;
```

---

**[11번] 답**

```sql
UPDATE copy_emp
SET    department_id = (SELECT department_id
                        FROM   copy_emp
                        WHERE  employee_id = 100)
WHERE  job_id = 'IT_PROG';
```

> employee_id=100의 department_id=90이므로 IT_PROG 사원들의 부서가 90으로 변경됨

---

**[12번] 답**

```sql
UPDATE copy_emp
SET    salary = (SELECT AVG(salary) FROM copy_emp)
WHERE  salary < (SELECT AVG(salary) FROM copy_emp);
```

> ⚠️ Oracle에서 UPDATE와 서브쿼리가 같은 테이블을 참조할 때, 서브쿼리는 UPDATE 이전 시점의 데이터를 기준으로 계산됨

---

## Group 3. DELETE / TRUNCATE 문 모범답안 (13~18번)

---

**[13번] 답**

```sql
DELETE FROM copy_emp
WHERE  employee_id = 207;
```

---

**[14번] 답**

```sql
DELETE FROM copy_emp
WHERE  department_id IS NULL;
```

> HR 스키마에서 department_id가 NULL인 사원: Grant(employee_id=178) 1명

---

**[15번] 답**

```sql
DELETE FROM copy_emp
WHERE  department_id IN (
    SELECT department_id
    FROM   departments
    WHERE  department_name LIKE '%Public%'
);
```

> 'Public Relations' 부서(department_id=70)에 해당하는 사원 삭제

---

**[16번] 답**

```sql
DELETE FROM copy_emp
WHERE  salary < (SELECT MAX(salary) FROM copy_emp)
AND    job_id = 'AD_VP';
```

> MAX salary = 24000(King). AD_VP 중 salary < 24000인 사원: Kochhar(17000), De Haan(17000) — 2명 삭제

---

**[17번] 답**

```sql
-- 삭제
DELETE FROM copy_emp;
-- 확인
SELECT COUNT(*) FROM copy_emp;  -- 0

-- 복원
ROLLBACK;
-- 재확인
SELECT COUNT(*) FROM copy_emp;  -- 원래 행 수(107행 등)
```

---

**[18번] 답**

```sql
TRUNCATE TABLE copy_emp;
-- 확인
SELECT COUNT(*) FROM copy_emp;  -- 0
-- ⚠️ ROLLBACK 불가 (DDL 문)
```

---

## Group 4. 트랜잭션 제어 모범답안 (19~24번)

---

**[19번] 답**

```sql
-- Step 1
INSERT INTO departments VALUES (310, 'Test Dept', NULL, 1700);
-- Step 2
SAVEPOINT sp1;
-- Step 3
INSERT INTO departments VALUES (320, 'Test Dept 2', NULL, 1700);
-- Step 4
ROLLBACK TO sp1;
-- Step 5
SELECT department_id, department_name
FROM   departments
WHERE  department_id IN (310, 320);

-- 결과: 310만 존재, 320은 취소됨
-- (단, COMMIT하지 않았으므로 다른 세션에서는 보이지 않음)
ROLLBACK;  -- 실습 후 정리
```

---

**[20번] 답**

```sql
-- Step 1
INSERT INTO departments VALUES (330, 'Alpha', NULL, 1700);
-- Step 2
SAVEPOINT sp_a;
-- Step 3
INSERT INTO departments VALUES (340, 'Beta', NULL, 1700);
-- Step 4
SAVEPOINT sp_b;
-- Step 5
UPDATE departments SET department_name='Alpha Updated' WHERE department_id=330;
-- Step 6 (sp_b 이후 = UPDATE 취소)
ROLLBACK TO sp_b;
-- Step 7
COMMIT;

-- 최종 확인
SELECT department_id, department_name
FROM   departments
WHERE  department_id IN (330, 340);
-- 330: Alpha, 340: Beta (UPDATE는 취소됨)

-- 정리
DELETE FROM departments WHERE department_id IN (330, 340);
COMMIT;
```

---

**[21번] 답**

```sql
-- Step 1: INSERT (COMMIT 전)
INSERT INTO departments VALUES (350, 'Gamma', NULL, 1700);

-- Step 2: 현재 세션에서 조회 (COMMIT 전에도 현재 세션에서 보임)
SELECT department_id, department_name FROM departments WHERE department_id = 350;
-- 350  Gamma  ← 보임

-- Step 3: COMMIT
COMMIT;

-- Step 4: COMMIT 후 확인 (모든 세션에서 보임)
SELECT department_id, department_name FROM departments WHERE department_id = 350;
-- 350  Gamma  ← 여전히 보임 (이제 영구 저장)

-- 정리
DELETE FROM departments WHERE department_id = 350;
COMMIT;
```

---

**[22번] 답**

```sql
-- Step 1: UPDATE
UPDATE copy_emp SET salary = 99999 WHERE employee_id = 100;
-- Step 2: INSERT
INSERT INTO departments VALUES (360, 'Delta', NULL, 1700);
-- Step 3: SELECT로 확인 (현재 세션)
SELECT salary FROM copy_emp WHERE employee_id = 100;  -- 99999
SELECT department_id FROM departments WHERE department_id = 360;  -- 360

-- Step 4: ROLLBACK
ROLLBACK;

-- Step 5: 재확인
SELECT salary FROM copy_emp WHERE employee_id = 100;  -- 24000 (복원)
SELECT department_id FROM departments WHERE department_id = 360;  -- no rows (복원)
```

---

**[23번] 답**

```sql
-- Step 1: salary 업데이트
UPDATE copy_emp SET salary = 5000 WHERE department_id = 10;
-- Step 2: SAVEPOINT
SAVEPOINT after_update;
-- Step 3: DELETE
DELETE FROM copy_emp WHERE department_id = 10;
-- Step 4: 확인 (0행)
SELECT employee_id, salary FROM copy_emp WHERE department_id = 10;  -- 0 rows
-- Step 5: ROLLBACK TO after_update (DELETE 취소)
ROLLBACK TO after_update;
-- Step 6: 재확인 (UPDATE는 유지)
SELECT employee_id, last_name, salary FROM copy_emp WHERE department_id = 10;
-- 200  Whalen  5000  ← salary=5000, DELETE 취소됨

ROLLBACK;  -- 실습 후 정리
```

---

**[24번] 답**

```sql
-- Step 1: UPDATE
UPDATE copy_emp SET salary = 99999 WHERE employee_id = 100;
-- Step 2: 확인
SELECT salary FROM copy_emp WHERE employee_id = 100;  -- 99999

-- Step 3: DDL 실행 → 자동 커밋 (Step 1의 UPDATE도 함께 커밋됨)
CREATE TABLE temp_test (id NUMBER);

-- Step 4: ROLLBACK (이미 커밋됨 — 효과 없음)
ROLLBACK;

-- Step 5: 재확인
SELECT salary FROM copy_emp WHERE employee_id = 100;
-- 99999 (DDL 자동 커밋으로 인해 ROLLBACK 불가)

-- 정리
UPDATE copy_emp SET salary = 24000 WHERE employee_id = 100;
COMMIT;
DROP TABLE temp_test;
```

---

## Group 5. 종합 응용 모범답안 (25~30번)

---

**[25번] 답**

```sql
-- Step 1: 재생성
TRUNCATE TABLE copy_emp;
INSERT INTO copy_emp SELECT * FROM employees;

-- Step 2: 삭제
DELETE FROM copy_emp WHERE salary < 6000;
-- N rows deleted.

-- Step 3: 삭제 확인
SELECT COUNT(*) FROM employees WHERE salary < 6000;

-- Step 4: ROLLBACK
ROLLBACK;
SELECT COUNT(*) FROM copy_emp;  -- 107행 복원
```

---

**[26번] 답**

```sql
-- Step 1: INSERT
INSERT INTO copy_emp (employee_id, first_name, last_name, email,
                      phone_number, hire_date, job_id, salary,
                      commission_pct, manager_id, department_id)
VALUES (209, 'Tom', 'Lee', 'TLEE', '515.000.1111',
        TO_DATE('2024-01-15', 'YYYY-MM-DD'),
        'ST_CLERK', 3200, NULL, 121, 50);

-- Step 2: 부서 50 평균 급여 확인
SELECT ROUND(AVG(salary)) AS avg_salary
FROM   copy_emp
WHERE  department_id = 50;

-- Step 3: COMMIT
COMMIT;
```

---

**[27번] 답**

```sql
-- Step 1: SA_REP salary < 7000 → 7000으로 업데이트
UPDATE copy_emp
SET    salary = 7000
WHERE  job_id = 'SA_REP'
AND    salary < 7000;

-- Step 2: SAVEPOINT
SAVEPOINT after_sa_update;

-- Step 3: IT_PROG salary < 5000 → 5000으로 업데이트
UPDATE copy_emp
SET    salary = 5000
WHERE  job_id = 'IT_PROG'
AND    salary < 5000;

-- Step 4: 확인
SELECT job_id, MIN(salary), MAX(salary)
FROM   copy_emp
WHERE  job_id IN ('SA_REP', 'IT_PROG')
GROUP BY job_id;

-- Step 5: COMMIT
COMMIT;
```

---

**[28번] 답**

```sql
-- Step 1: 고아 사원 확인
SELECT employee_id, department_id
FROM   copy_emp
WHERE  department_id NOT IN (
    SELECT department_id FROM departments WHERE department_id IS NOT NULL)
OR     department_id IS NULL;

-- Step 2: department_id를 NULL로 업데이트
UPDATE copy_emp
SET    department_id = NULL
WHERE  department_id NOT IN (
    SELECT department_id FROM departments WHERE department_id IS NOT NULL)
AND    department_id IS NOT NULL;

-- Step 3: COMMIT
COMMIT;
```

---

**[29번] 답**

```sql
-- Step 1: 새 부서 삽입
INSERT INTO departments VALUES (370, 'New Division', 100, 1700);

-- Step 2: SAVEPOINT
SAVEPOINT dept_added;

-- Step 3: 부서 60 사원을 370으로 이동
UPDATE copy_emp
SET    department_id = 370
WHERE  department_id = 60;

-- Step 4: 확인
SELECT COUNT(*) FROM copy_emp WHERE department_id = 370;

-- Step 5: 사원 이동 취소
ROLLBACK TO dept_added;

-- Step 6: 부서 370 존재 확인 (INSERT는 sp 이전 → 유지)
SELECT department_id, department_name
FROM   departments
WHERE  department_id = 370;
-- 370  New Division  ← 유지됨

-- Step 7: COMMIT
COMMIT;

-- 정리
DELETE FROM departments WHERE department_id = 370;
COMMIT;
```

---

**[30번] 답**

```sql
-- Step 1: 대상 사원 확인
SELECT employee_id, salary, manager_id
FROM   copy_emp
WHERE  salary < (SELECT AVG(salary) FROM copy_emp)
AND    manager_id IS NULL;

-- Step 2: 평균 급여로 업데이트
UPDATE copy_emp
SET    salary = (SELECT AVG(salary) FROM copy_emp)
WHERE  salary < (SELECT AVG(salary) FROM copy_emp)
AND    manager_id IS NULL;

-- Step 3: SAVEPOINT
SAVEPOINT avg_update_done;

-- Step 4: commission_pct IS NOT NULL인 사원 수 확인
SELECT COUNT(*) FROM copy_emp WHERE commission_pct IS NOT NULL;

-- Step 5: commission_pct 있는 사원 5% 추가 인상
UPDATE copy_emp
SET    salary = salary * 1.05
WHERE  commission_pct IS NOT NULL;

-- Step 6: 최종 확인
SELECT employee_id, salary, commission_pct
FROM   copy_emp
WHERE  commission_pct IS NOT NULL
ORDER BY salary DESC;

-- Step 7: COMMIT
COMMIT;
```

> **처리 흐름 정리:**
> 1. 전체 평균보다 낮은 급여 + manager_id NULL인 사원을 평균 급여로 업데이트
> 2. SAVEPOINT: 이 시점 이후를 ROLLBACK할 수 있는 지점 설정
> 3. commission_pct 보유 사원(판매직 등)의 급여를 5% 추가 인상
> 4. 전체 COMMIT으로 두 변경 모두 영구 저장
