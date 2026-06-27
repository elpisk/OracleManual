# Oracle Database 19c: SQL Workshop
## Chapter 8 — 서브쿼리를 활용한 쿼리 작성 | 연습문제 모범답안

---

# ★ 하 (기초) — 모범답안

**[하-01] 답: ①** 서브쿼리(내부 쿼리)는 항상 메인 쿼리(외부 쿼리)보다 먼저 실행된다.

**[하-02] 답: ③** 서브쿼리는 가독성을 위해 비교 조건의 오른쪽에 배치하는 것이 권장이지만, 반드시 오른쪽이어야 하는 규칙은 없다. 양쪽 모두 가능하다.

**[하-03] 답: ③** `IN`은 다중행 서브쿼리 연산자이다. 단일행 서브쿼리 연산자는 `=`, `>`, `<`, `>=`, `<=`, `<>` 이다.

**[하-04] 답: ②** 서브쿼리 실행 → 결과(AVG값)를 메인 쿼리 WHERE 조건에 사용 → 최종 결과 반환.

**[하-05] 답: ②** `MIN(salary)`는 그룹 함수로 항상 단일 값(숫자)을 반환한다. 단일행 서브쿼리로 사용 가능.

**[하-06] 답: ④** `=`(단독)는 단일행 연산자이다. 다중행 서브쿼리 연산자는 `IN`, `ANY`, `ALL` 이다.

**[하-07] 답: ②** `< ANY`는 서브쿼리 결과 중 하나라도 크면 조건 만족 → `< MAX(서브쿼리 결과)`와 동일.

**[하-08] 답: ③** `< ALL`은 서브쿼리 결과의 모든 값보다 작아야 함 → `< MIN(서브쿼리 결과)`와 동일.

**[하-09] 답: ③** `= ANY`는 목록의 어느 값과 같으면 됨 → `IN`과 동일.

**[하-10] 답: ②** `<> ALL`은 목록의 모든 값과 달라야 함 → `NOT IN`과 동일.  
단, NOT IN은 NULL이 있으면 항상 FALSE가 되므로 주의 필요.

**[하-11] 답: ②** 단일행 연산자(`=`)를 사용했는데 서브쿼리가 여러 행을 반환하면:  
**ORA-01427: single-row subquery returns more than one row** 오류 발생.

**[하-12] 답: ②** 서브쿼리 결과가 0행이면 메인 쿼리도 0행을 반환한다. 오류는 발생하지 않는다.

**[하-13] 답: ②** 그룹 함수(AVG, MIN, MAX 등)는 항상 단일 값을 반환하므로 단일행 서브쿼리로 사용 가능하다.

**[하-14] 답: ②** `> ANY` → 부서 90 중 하나라도 작으면 OK → `> MIN(부서 90 급여)`와 동일.  
부서 90 급여: 24000, 17000, 17000 → MIN=17000 → salary > 17000인 사원 반환.

**[하-15] 답: ②** `=` 연산자(단일행)인데 `GROUP BY department_id`로 인해 서브쿼리가 여러 행을 반환.  
→ ORA-01427 오류. `=` → `IN` 으로 변경해야 한다.

**[하-16] 답: ③** EMPLOYEES 테이블의 manager_id 열에 NULL이 포함되어 있다(King의 경우 manager_id = NULL).  
NOT IN 조건에서 NULL과의 비교는 항상 UNKNOWN(FALSE)이 되므로 **전체 결과가 0행**이 된다.

**[하-17] 답: ②** 다중열 서브쿼리 구문: `WHERE (col1, col2) IN (SELECT col1, col2 FROM ...)`.  
괄호 안에 여러 열을 나열하여 쌍(pair)으로 비교한다.

**[하-18] 답: ②** 서브쿼리 먼저 실행 → 결과를 HAVING 절에 반환 → 그룹 함수 조건으로 그룹 필터링.

**[하-19] 답: ②** NOT IN에서 서브쿼리 결과에 NULL이 하나라도 있으면:  
NULL과의 비교는 UNKNOWN → 모든 행이 조건을 만족하지 않아 **0행 반환**.  
해결: `WHERE mgr.manager_id IS NOT NULL` 조건 추가.

**[하-20] 답: ③** FROM 절에서 서브쿼리를 사용하면 **인라인 뷰(Inline View)**라고 한다.  
마치 가상 테이블처럼 동작하며, 반드시 별칭(alias)을 부여해야 한다.

---

# ★★ 중 (응용) — 모범답안

---

**[중-01] 답**

```sql
SELECT last_name, job_id, salary
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;
```

---

**[중-02] 답**

```sql
SELECT last_name, job_id, salary
FROM   employees
WHERE  job_id = (SELECT job_id
                 FROM   employees
                 WHERE  last_name = 'Abel')
AND    last_name <> 'Abel'
ORDER BY last_name;
```

---

**[중-03] 답**

```sql
SELECT last_name, job_id, salary
FROM   employees
WHERE  salary = (SELECT MIN(salary) FROM employees);
```

---

**[중-04] 답**

```sql
SELECT   department_id, MIN(salary)
FROM     employees
GROUP BY department_id
HAVING   MIN(salary) > (SELECT MIN(salary)
                        FROM   employees
                        WHERE  department_id = 90)
ORDER BY department_id;
```

> 부서 90의 최소 급여: 17000.  
> 이보다 최소 급여가 높은 부서만 출력된다.

---

**[중-05] 답**

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary < ANY (SELECT salary
                     FROM   employees
                     WHERE  job_id = 'IT_PROG')
AND    job_id <> 'IT_PROG'
ORDER BY last_name;
```

> IT_PROG 급여: 9000, 6000, 4800, 4800, 4200 → `< ANY` = `< 9000`  
> → salary < 9000이고 job_id ≠ 'IT_PROG'인 사원

---

**[중-06] 답**

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary < ALL (SELECT salary
                     FROM   employees
                     WHERE  job_id = 'IT_PROG')
AND    job_id <> 'IT_PROG'
ORDER BY salary DESC;
```

> `< ALL` = `< MIN(IT_PROG 급여)` = `< 4200`  
> → salary < 4200이고 job_id ≠ 'IT_PROG'인 사원

---

**[중-07] 답**

```sql
SELECT last_name, salary, department_id
FROM   employees
WHERE  salary < ANY (SELECT salary
                     FROM   employees
                     WHERE  department_id IN (50, 80))
AND    department_id NOT IN (50, 80)
ORDER BY salary DESC;
```

---

**[중-08] 답**

```sql
SELECT last_name, job_id, department_id
FROM   employees
WHERE  job_id IN (SELECT job_id
                  FROM   employees
                  WHERE  department_id IN (10, 20, 30))
AND    department_id NOT IN (10, 20, 30)
ORDER BY job_id, last_name;
```

---

**[중-09] 답**

```sql
SELECT first_name, department_id, salary
FROM   employees
WHERE  (salary, department_id) IN
       (SELECT MIN(salary), department_id
        FROM   employees
        GROUP BY department_id)
ORDER BY department_id;
```

> 다중열 서브쿼리: (salary, department_id) 쌍이 각 부서의 최솟값과 일치하는 행 반환.

---

**[중-10] 답**

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  employee_id IN (SELECT manager_id
                       FROM   employees
                       WHERE  manager_id IS NOT NULL)
ORDER BY employee_id;
```

---

**[중-11] 답**

```sql
SELECT last_name
FROM   employees
WHERE  employee_id NOT IN (SELECT manager_id
                           FROM   employees
                           WHERE  manager_id IS NOT NULL)
ORDER BY last_name;
```

> `WHERE manager_id IS NOT NULL` 이 없으면 NULL로 인해 0행 반환.

---

**[중-12] 답**

```sql
SELECT last_name, hire_date
FROM   employees
WHERE  hire_date > (SELECT hire_date
                    FROM   employees
                    WHERE  last_name = 'Davies')
ORDER BY hire_date;
```

---

**[중-13] 답**

```sql
SELECT   department_id, MAX(salary)
FROM     employees
GROUP BY department_id
HAVING   MAX(salary) > (SELECT AVG(salary) FROM employees)
ORDER BY department_id;
```

---

**[중-14] 답**

```sql
SELECT last_name, job_id, salary
FROM   employees
WHERE  salary > ALL (SELECT salary
                     FROM   employees
                     WHERE  department_id = 60)
AND    department_id <> 60
ORDER BY salary DESC;
```

> 부서 60 급여: 9000, 6000, 4800, 4800, 4200 → `> ALL` = `> MAX` = `> 9000`

---

**[중-15] 답**

```sql
SELECT employee_id, last_name, salary
FROM   employees
WHERE  department_id = 80
AND    salary > ANY (SELECT salary
                    FROM   employees
                    WHERE  department_id = 50)
ORDER BY salary DESC;
```

---

**[중-16] 답**

```sql
SELECT e.last_name, e.salary, e.department_id, d.avg_salary
FROM   employees e
JOIN   (SELECT department_id, ROUND(AVG(salary), 2) AS avg_salary
        FROM   employees
        GROUP BY department_id) d
ON     (e.department_id = d.department_id)
WHERE  e.salary > d.avg_salary
ORDER BY e.department_id, e.salary DESC;
```

---

**[중-17] 답**

```sql
SELECT last_name, department_id
FROM   employees
WHERE  department_id = (SELECT department_id
                        FROM   employees
                        WHERE  last_name = 'King'
                        AND    job_id = 'AD_PRES')
AND    last_name <> 'King'
ORDER BY last_name;
```

> King은 두 명이다(King AD_PRES, King 등). job_id='AD_PRES' 조건으로 특정.

---

**[중-18] 답**

```sql
SELECT last_name, salary, commission_pct
FROM   employees
WHERE  commission_pct IS NULL
AND    salary > (SELECT MIN(salary)
                 FROM   employees
                 WHERE  commission_pct IS NOT NULL)
ORDER BY salary DESC;
```

---

**[중-19] 답**

```sql
SELECT MIN(avg_salary) AS min_of_avg
FROM   (SELECT AVG(salary) AS avg_salary
        FROM   employees
        GROUP BY job_id);
```

> 서브쿼리(인라인 뷰)로 직무별 평균 급여를 계산한 후, 외부 쿼리에서 그 최솟값을 구한다.

---

**[중-20] 답**

```sql
SELECT last_name, job_id, salary, department_id
FROM   employees
WHERE  department_id = 50
AND    (job_id, salary) IN (SELECT job_id, salary
                            FROM   employees
                            WHERE  department_id = 80);
```

---

# ★★★ 상 (심화) — 모범답안

---

**[상-01] 답**

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary > ALL (SELECT AVG(salary)
                     FROM   employees
                     WHERE  department_id = 50);
```

**(1) 결과 설명:**

부서 50의 AVG(salary)는 단 하나의 값(그룹 함수 결과)이다. `ALL` 뒤의 서브쿼리가 **단일 값**만 반환하므로 `> ALL` 은 `> =` 과 동일하게 동작한다.  
부서 50의 평균 급여 ≈ 3,476 → salary > 3,476인 모든 사원 반환.

**(2) ALL 대신 ANY 사용 시:**

서브쿼리가 단일 행일 경우 `> ANY`와 `> ALL`은 동일한 결과를 반환한다.  
단, 서브쿼리가 여러 행을 반환할 때:
- `> ALL` → 모든 값보다 커야 함 (최대값보다 큰 조건)
- `> ANY` → 하나라도 작은 값이 있으면 OK (최소값보다 큰 조건)

→ `> ANY`가 훨씬 많은 행을 반환한다.

---

**[상-02] 답**

**(1) 0행인 이유:**

```sql
SELECT manager_id FROM employees;
```

이 서브쿼리 결과에 King의 `manager_id = NULL`이 포함된다.  
NOT IN 조건에서 NULL과의 비교는 UNKNOWN(FALSE)이 되어, **모든 행이 조건을 만족하지 않는다** → 0행 반환.

**(2) 수정:**

```sql
SELECT last_name
FROM   employees
WHERE  employee_id NOT IN (SELECT manager_id
                           FROM   employees
                           WHERE  manager_id IS NOT NULL);
```

---

**[상-03] 답**

```sql
SELECT last_name, salary, hire_date
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees)    -- 단일행 서브쿼리
AND    hire_date < (SELECT MAX(hire_date) FROM employees)  -- 단일행 서브쿼리
ORDER BY salary DESC;
```

---

**[상-04] 답**

**쿼리 결과 설명:**

각 부서에서 최소 급여를 받는 사원을 조회한다. `(salary, department_id)` 쌍이 부서별 `(MIN(salary), department_id)` 쌍과 일치하는 행만 반환한다.

**동일한 결과를 JOIN으로:**

```sql
SELECT e.first_name, e.department_id, e.salary
FROM   employees e
JOIN   (SELECT department_id, MIN(salary) AS min_sal
        FROM   employees
        GROUP BY department_id) m
ON     (e.department_id = m.department_id
        AND e.salary = m.min_sal)
ORDER BY e.department_id;
```

---

**[상-05] 답**

```sql
SELECT department_id, avg_salary, emp_count
FROM   (SELECT department_id,
               ROUND(AVG(salary), 2) AS avg_salary,
               COUNT(*)              AS emp_count
        FROM   employees
        GROUP BY department_id) dept_stats
WHERE  avg_salary >= 8000
ORDER BY avg_salary DESC;
```

> 인라인 뷰(`dept_stats`)에서 부서별 집계를 먼저 계산하고, 외부 WHERE로 필터링.

---

**[상-06] 답**

부서 90 급여: 24000, 17000, 17000

**(1) 동등 표현:**

- **(A) `< ANY`** → `< MAX(부서 90 급여)` → `salary < 24000`  
- **(B) `< ALL`** → `< MIN(부서 90 급여)` → `salary < 17000`

**(2) 결과 행 수 비교:**

| 쿼리 | 조건 | 결과 |
|------|------|------|
| (A) salary < 24000 | salary < 24,000인 사원 | 104행(King 제외) |
| (B) salary < 17000 | salary < 17,000인 사원 | 훨씬 적은 행 |

→ (A)가 (B)보다 훨씬 많은 행을 반환한다.

---

**[상-07] 답**

```sql
SELECT last_name,
       salary,
       (SELECT ROUND(AVG(salary), 2)
        FROM   employees e2
        WHERE  e2.department_id = e1.department_id) AS dept_avg
FROM   employees e1
ORDER BY salary DESC
FETCH FIRST 10 ROWS ONLY;
```

> SELECT 절의 **스칼라 서브쿼리**: 각 행마다 독립적으로 실행되며 단일 값 반환.  
> 상관 서브쿼리(Correlated Subquery): 외부 쿼리의 값(e1.department_id)을 참조.

---

**[상-08] 답**

```sql
SELECT last_name, job_id, salary
FROM   employees
WHERE  job_id IN (SELECT job_id
                  FROM   employees
                  WHERE  department_id IN (60, 90))
AND    department_id NOT IN (60, 90)
AND    salary < (SELECT MAX(salary)
                 FROM   jobs j
                 WHERE  j.job_id = employees.job_id)
ORDER BY last_name;
```

> 또는 JOBS 테이블의 max_salary와 비교:

```sql
SELECT e.last_name, e.job_id, e.salary
FROM   employees e
WHERE  e.job_id IN (SELECT job_id
                    FROM   employees
                    WHERE  department_id IN (60, 90))
AND    e.department_id NOT IN (60, 90)
AND    e.salary < (SELECT j.max_salary
                   FROM   jobs j
                   WHERE  j.job_id = e.job_id)
ORDER BY e.last_name;
```

---

**[상-09] 답**

```sql
SELECT last_name, salary
FROM   employees
WHERE  department_id IN
       (SELECT department_id
        FROM   departments
        WHERE  location_id =
               (SELECT location_id
                FROM   locations
                WHERE  city = 'Seattle'));
```

**(1) 가장 안쪽 서브쿼리:**

```sql
SELECT location_id FROM locations WHERE city = 'Seattle';
-- 결과: 1700 (Seattle의 location_id)
```

**(2) 두 번째 서브쿼리:**

```sql
SELECT department_id FROM departments WHERE location_id = 1700;
-- 결과: 10, 30, 90, 100, 110, ... (Seattle에 있는 부서들)
```

**(3) 메인 쿼리 최종 결과:**

Seattle에 있는 부서에 소속된 모든 사원의 last_name과 salary가 반환된다.  
(Administration, Purchasing, Executive, Finance, Accounting 등 부서 사원들)

---

**[상-10] 답**

```sql
SELECT last_name, salary, job_id
FROM   employees
WHERE  salary >= (SELECT lowest_sal
                  FROM   job_grades
                  WHERE  grade_level = 'E')
AND    salary <= (SELECT highest_sal
                  FROM   job_grades
                  WHERE  grade_level = 'E')
ORDER BY salary DESC;
```

> 또는 BETWEEN 조건으로:

```sql
SELECT last_name, salary, job_id
FROM   employees
WHERE  salary BETWEEN (SELECT lowest_sal FROM job_grades WHERE grade_level = 'E')
                  AND (SELECT highest_sal FROM job_grades WHERE grade_level = 'E')
ORDER BY salary DESC;
```

> E 등급: lowest_sal=15000, highest_sal=24999  
> → salary가 15000 이상 24999 이하인 사원 출력 (King 24000, Kochhar 17000, De Haan 17000 등)
