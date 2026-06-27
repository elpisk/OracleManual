# Oracle Database 19c: SQL Workshop
## Chapter 9 — 집합 연산자 사용 | SQL 실습 문제 모범답안

---

## Group 1. UNION / UNION ALL 모범답안 (1~6번)

---

**[1번] 답**

```sql
SELECT job_id
FROM   employees
UNION
SELECT job_id
FROM   job_history
ORDER BY job_id;
```

---

**[2번] 답**

```sql
SELECT job_id
FROM   employees
UNION ALL
SELECT job_id
FROM   job_history
ORDER BY job_id;
```

---

**[3번] 답**

```sql
SELECT department_id
FROM   employees
WHERE  department_id IS NOT NULL
UNION
SELECT department_id
FROM   departments
ORDER BY department_id;
```

> EMPLOYEES의 NULL 부서 사원은 IS NOT NULL로 제외. UNION이 중복을 자동 제거하므로 고유 부서 번호만 반환.

---

**[4번] 답**

```sql
SELECT last_name, department_id
FROM   employees
WHERE  department_id = 20
UNION ALL
SELECT last_name, department_id
FROM   employees
WHERE  department_id = 30
UNION ALL
SELECT last_name, department_id
FROM   employees
WHERE  department_id = 40
ORDER BY department_id;
```

---

**[5번] 답**

```sql
SELECT employee_id, last_name, salary
FROM   employees
WHERE  job_id = 'SA_REP'
UNION
SELECT employee_id, last_name, salary
FROM   employees
WHERE  job_id = 'IT_PROG'
ORDER BY salary DESC;
```

---

**[6번] 답**

```sql
SELECT employee_id, job_id, department_id
FROM   employees
WHERE  department_id IS NOT NULL
UNION
SELECT employee_id, job_id, department_id
FROM   job_history
ORDER BY employee_id;
```

---

## Group 2. INTERSECT 모범답안 (7~12번)

---

**[7번] 답**

```sql
SELECT employee_id
FROM   employees
INTERSECT
SELECT employee_id
FROM   job_history
ORDER BY employee_id;
```

---

**[8번] 답**

```sql
SELECT employee_id, job_id
FROM   employees
INTERSECT
SELECT employee_id, job_id
FROM   job_history
ORDER BY employee_id;
```

> 현재 직무와 과거에 수행한 적 있는 직무가 동일한 사원. 결과: employee_id 176, SA_REP.

---

**[9번] 답**

```sql
SELECT department_id
FROM   employees
WHERE  department_id IS NOT NULL
INTERSECT
SELECT department_id
FROM   departments
ORDER BY department_id;
```

---

**[10번] 답**

```sql
SELECT job_id
FROM   employees
WHERE  department_id IN (50, 80)
INTERSECT
SELECT job_id
FROM   job_history
ORDER BY job_id;
```

---

**[11번] 답**

```sql
SELECT employee_id
FROM   employees
WHERE  salary >= 8000
INTERSECT
SELECT employee_id
FROM   job_history
ORDER BY employee_id;
```

---

**[12번] 답**

```sql
SELECT department_id
FROM   employees
WHERE  department_id IS NOT NULL
INTERSECT
SELECT department_id
FROM   job_history
ORDER BY department_id;
```

---

## Group 3. MINUS 모범답안 (13~18번)

---

**[13번] 답**

```sql
SELECT employee_id
FROM   employees
MINUS
SELECT employee_id
FROM   job_history
ORDER BY employee_id;
```

---

**[14번] 답**

```sql
SELECT employee_id
FROM   job_history
MINUS
SELECT employee_id
FROM   employees
ORDER BY employee_id;
```

> HR 스키마에서는 JOB_HISTORY의 모든 employee_id가 현재 EMPLOYEES에도 존재하므로 결과는 0행.

---

**[15번] 답**

```sql
SELECT department_id
FROM   departments
MINUS
SELECT department_id
FROM   employees
WHERE  department_id IS NOT NULL
ORDER BY department_id;
```

---

**[16번] 답**

```sql
SELECT employee_id
FROM   employees
MINUS
SELECT manager_id
FROM   employees
WHERE  manager_id IS NOT NULL
ORDER BY employee_id;
```

> IS NOT NULL 필터 없이 사용하면 NULL로 인해 NOT IN처럼 0행이 반환될 수 있다.  
> MINUS는 NULL을 자동 제외하므로 IS NOT NULL 없이도 결과는 동일하지만, 명시하는 것이 안전하다.

---

**[17번] 답**

```sql
SELECT job_id
FROM   employees
MINUS
SELECT job_id
FROM   job_history
ORDER BY job_id;
```

---

**[18번] 답**

```sql
SELECT employee_id
FROM   employees
WHERE  department_id = 90
MINUS
SELECT manager_id
FROM   employees
WHERE  department_id = 80
AND    manager_id IS NOT NULL
ORDER BY employee_id;
```

> 부서 90 사원: 100(King), 101(Kochhar), 102(De Haan)  
> 부서 80 manager_id: 100, 101, 145, 146, ...  
> MINUS 결과: 102(De Haan) — 부서 80 사원의 관리자가 아닌 부서 90 사원

---

## Group 4. 열 일치 · ORDER BY 모범답안 (19~24번)

---

**[19번] 답**

```sql
SELECT employee_id, last_name, hire_date
FROM   employees
UNION
SELECT employee_id, job_id, start_date
FROM   job_history
ORDER BY employee_id;
```

> `hire_date`와 `start_date` 모두 DATE 타입이므로 타입 변환 없이 사용 가능.  
> 열 이름은 첫 번째 쿼리 기준: EMPLOYEE_ID, LAST_NAME, HIRE_DATE.

---

**[20번] 답**

```sql
SELECT location_id, department_name "Name", TO_CHAR(NULL) "City"
FROM   departments
UNION
SELECT location_id, TO_CHAR(NULL) "Name", city
FROM   locations
ORDER BY location_id;
```

> DEPARTMENTS에는 city 열이 없으므로 `TO_CHAR(NULL)`로 자리를 맞춤.  
> LOCATIONS에는 department_name 열이 없으므로 마찬가지로 처리.

---

**[21번] 답**

```sql
SELECT job_id, 'EMPLOYEE' AS "SOURCE"
FROM   employees
UNION
SELECT job_id, 'MASTER'
FROM   jobs
ORDER BY job_id;
```

---

**[22번] 답**

```sql
SELECT employee_id, last_name, salary
FROM   employees
WHERE  department_id = 90
UNION ALL
SELECT employee_id, last_name, salary
FROM   employees
WHERE  job_id = 'SA_MAN'
UNION ALL
SELECT employee_id, last_name, salary
FROM   employees
WHERE  department_id = 100
ORDER BY salary DESC;
```

---

**[23번] 답**

```sql
SELECT job_id, COUNT(*) AS cnt
FROM   employees
GROUP BY job_id
UNION
SELECT job_id, COUNT(*) AS cnt
FROM   job_history
GROUP BY job_id
ORDER BY 2 DESC;
```

---

**[24번] 답**

```sql
SELECT employee_id AS "EMP_ID", job_id AS "POSITION", department_id AS "DEPT"
FROM   employees
WHERE  department_id IS NOT NULL
UNION
SELECT employee_id, job_id, department_id
FROM   job_history
ORDER BY employee_id;
```

> 별칭은 첫 번째 SELECT에만 지정하면 전체 결과에 적용된다.

---

## Group 5. 종합 응용 모범답안 (25~30번)

---

**[25번] 답**

```sql
SELECT employee_id
FROM   employees
WHERE  salary > 10000
MINUS
SELECT employee_id
FROM   job_history
ORDER BY employee_id;
```

---

**[26번] 답**

```sql
SELECT employee_id
FROM   job_history
INTERSECT
SELECT employee_id
FROM   employees
WHERE  salary >= 10000
ORDER BY employee_id;
```

---

**[27번] 답**

```sql
SELECT 'MGR' AS group_label, last_name, job_id, salary
FROM   employees
WHERE  job_id LIKE '%_MAN' OR job_id LIKE '%_MGR'
UNION ALL
SELECT 'EXEC', last_name, job_id, salary
FROM   employees
WHERE  job_id IN ('AD_PRES', 'AD_VP')
UNION ALL
SELECT 'PROF', last_name, job_id, salary
FROM   employees
WHERE  job_id IN ('IT_PROG', 'FI_ACCOUNT', 'HR_REP')
ORDER BY salary DESC;
```

---

**[28번] 답**

```sql
SELECT employee_id
FROM   employees
WHERE  (salary, department_id) IN
       (SELECT MAX(salary), department_id
        FROM   employees
        GROUP BY department_id)
INTERSECT
SELECT employee_id
FROM   job_history
ORDER BY employee_id;
```

---

**[29번] 답**

```sql
SELECT d.department_id, d.department_name
FROM   departments d
WHERE  d.department_id IN (
    SELECT department_id FROM departments
    MINUS
    SELECT department_id FROM employees WHERE department_id IS NOT NULL
)
ORDER BY d.department_id;
```

또는:

```sql
SELECT d.department_id, d.department_name
FROM   departments d
WHERE  NOT EXISTS (SELECT 1 FROM employees e WHERE e.department_id = d.department_id)
ORDER BY d.department_id;
```

---

**[30번] 답**

```sql
(SELECT employee_id, job_id, department_id
 FROM   employees
 WHERE  department_id IS NOT NULL
 UNION
 SELECT employee_id, job_id, department_id
 FROM   job_history)
MINUS
SELECT employee_id, job_id, department_id
FROM   employees
WHERE  salary < 5000
ORDER BY employee_id;
```

> **처리 순서:**
> 1. 괄호 내부 UNION: EMPLOYEES + JOB_HISTORY 합집합 (중복 제거)
> 2. MINUS: salary < 5000인 사원의 레코드 제거
> 3. ORDER BY: employee_id 오름차순

> **주의:** MINUS는 (employee_id, job_id, department_id) 세 열이 모두 일치하는 행만 제거한다.  
> 따라서 저급여 사원의 JOB_HISTORY 이력은 제거될 수도 있다.
