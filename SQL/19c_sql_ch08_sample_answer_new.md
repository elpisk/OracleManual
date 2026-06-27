# Oracle Database 19c: SQL Workshop
## Chapter 8 — 서브쿼리를 활용한 쿼리 작성 | SQL 실습 문제 모범답안

---

## Group 1. 단일행 서브쿼리 모범답안 (1~6번)

---

**[1번] 답**

```sql
SELECT last_name, hire_date
FROM   employees
WHERE  hire_date > (SELECT hire_date
                    FROM   employees
                    WHERE  last_name = 'Davies')
ORDER BY hire_date;
```

---

**[2번] 답**

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

**[3번] 답**

```sql
SELECT last_name, job_id, salary
FROM   employees
WHERE  salary = (SELECT MIN(salary) FROM employees);
```

---

**[4번] 답**

```sql
SELECT last_name, hire_date, salary
FROM   employees
WHERE  department_id = (SELECT department_id
                        FROM   employees
                        WHERE  last_name = 'Zlotkey')
AND    last_name <> 'Zlotkey'
ORDER BY hire_date;
```

---

**[5번] 답**

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;
```

---

**[6번] 답**

```sql
SELECT last_name, job_id, salary
FROM   employees
WHERE  job_id = (SELECT job_id
                 FROM   employees
                 WHERE  last_name = 'Taylor'
                 AND    job_id = 'SA_REP')
AND    salary > (SELECT salary
                 FROM   employees
                 WHERE  last_name = 'Taylor'
                 AND    job_id = 'SA_REP')
ORDER BY salary DESC;
```

> Taylor는 두 명일 수 있으므로 job_id 조건 추가로 특정.

---

## Group 2. 그룹 함수 서브쿼리 · HAVING 모범답안 (7~12번)

---

**[7번] 답**

```sql
SELECT   department_id, MIN(salary)
FROM     employees
GROUP BY department_id
HAVING   MIN(salary) > (SELECT MIN(salary)
                        FROM   employees
                        WHERE  department_id = 50)
ORDER BY department_id;
```

---

**[8번] 답**

```sql
SELECT   department_id, ROUND(AVG(salary)) AS avg_salary
FROM     employees
GROUP BY department_id
HAVING   AVG(salary) > (SELECT AVG(salary) FROM employees)
ORDER BY avg_salary DESC;
```

---

**[9번] 답**

```sql
SELECT   job_id, COUNT(*) AS emp_count
FROM     employees
GROUP BY job_id
HAVING   COUNT(*) > (SELECT COUNT(*)
                     FROM   employees
                     WHERE  department_id = 80)
ORDER BY job_id;
```

> 부서 80 사원 수: 34명. COUNT(*) > 34인 직무: SA_REP(30명)... 실제로는 SA_REP가 30명으로 미해당.  
> 실제 결과는 데이터에 따라 다를 수 있다. 위 쿼리가 정답 패턴.

---

**[10번] 답**

```sql
SELECT MIN(max_sal) AS min_of_max
FROM   (SELECT MAX(salary) AS max_sal
        FROM   employees
        GROUP BY department_id);
```

---

**[11번] 답**

```sql
SELECT   department_id, ROUND(AVG(salary)) AS avg_salary
FROM     employees
GROUP BY department_id
HAVING   AVG(salary) < (SELECT AVG(salary) FROM employees)
ORDER BY avg_salary;
```

---

**[12번] 답**

```sql
SELECT   job_id, SUM(salary) AS total_salary
FROM     employees
GROUP BY job_id
HAVING   SUM(salary) > (SELECT SUM(salary) FROM employees WHERE department_id = 80) / 2
ORDER BY total_salary DESC;
```

---

## Group 3. 다중행 서브쿼리 (IN / ANY / ALL) 모범답안 (13~18번)

---

**[13번] 답**

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  employee_id IN (SELECT manager_id
                       FROM   employees
                       WHERE  manager_id IS NOT NULL)
ORDER BY employee_id;
```

---

**[14번] 답**

```sql
SELECT last_name
FROM   employees
WHERE  employee_id NOT IN (SELECT manager_id
                           FROM   employees
                           WHERE  manager_id IS NOT NULL)
ORDER BY last_name;
```

> `WHERE manager_id IS NOT NULL` 없으면 NULL로 인해 0행 반환.

---

**[15번] 답**

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary < ANY (SELECT salary
                     FROM   employees
                     WHERE  job_id = 'IT_PROG')
AND    job_id <> 'IT_PROG'
ORDER BY salary DESC;
```

> `< ANY` = `< MAX(IT_PROG 급여)` = `< 9000`

---

**[16번] 답**

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

---

**[17번] 답**

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

**[18번] 답**

```sql
SELECT employee_id, last_name, salary
FROM   employees
WHERE  salary > ALL (SELECT salary
                     FROM   employees
                     WHERE  department_id = 90)
AND    department_id <> 90
ORDER BY salary DESC;
```

> 부서 90 최대 급여 = 24000 (King). salary > 24000인 사원이 없으므로 **0행 반환**.

---

## Group 4. 다중열 서브쿼리 · 인라인 뷰 모범답안 (19~24번)

---

**[19번] 답**

```sql
SELECT first_name, department_id, salary
FROM   employees
WHERE  (salary, department_id) IN
       (SELECT MIN(salary), department_id
        FROM   employees
        GROUP BY department_id)
ORDER BY department_id;
```

---

**[20번] 답**

```sql
SELECT last_name, job_id, hire_date
FROM   employees
WHERE  (job_id, hire_date) IN
       (SELECT job_id, MAX(hire_date)
        FROM   employees
        GROUP BY job_id)
ORDER BY job_id;
```

---

**[21번] 답**

```sql
SELECT department_id, avg_salary, emp_count
FROM   (SELECT department_id,
               ROUND(AVG(salary)) AS avg_salary,
               COUNT(*)           AS emp_count
        FROM   employees
        GROUP BY department_id
        ORDER BY avg_salary DESC)
WHERE  ROWNUM <= 5;
```

> ROWNUM은 ORDER BY 이후 인라인 뷰 안에서 적용해야 정확하다.  
> Oracle 12c 이상에서는 `FETCH FIRST 5 ROWS ONLY` 사용 가능.

---

**[22번] 답**

```sql
SELECT e.last_name, e.salary, e.department_id,
       d.dept_avg
FROM   employees e
JOIN   (SELECT department_id, ROUND(AVG(salary), 2) AS dept_avg
        FROM   employees
        GROUP BY department_id) d
ON     (e.department_id = d.department_id)
WHERE  e.salary > d.dept_avg
ORDER BY e.department_id, e.salary DESC;
```

---

**[23번] 답**

```sql
SELECT last_name, job_id, manager_id, department_id
FROM   employees
WHERE  department_id = 50
AND    (job_id, manager_id) IN
       (SELECT job_id, manager_id
        FROM   employees
        WHERE  department_id = 80);
```

---

**[24번] 답**

```sql
SELECT last_name, salary
FROM   (SELECT last_name, salary
        FROM   employees
        ORDER BY salary DESC)
WHERE  ROWNUM <= 5;
```

---

## Group 5. 종합 응용 모범답안 (25~30번)

---

**[25번] 답**

```sql
SELECT last_name, salary
FROM   employees
WHERE  department_id IN
       (SELECT department_id
        FROM   departments
        WHERE  location_id = 1700)
ORDER BY salary DESC;
```

---

**[26번] 답**

```sql
SELECT first_name, department_id, salary
FROM   employees
WHERE  (salary, department_id) IN
       (SELECT MIN(salary), department_id
        FROM   employees
        GROUP BY department_id)
AND    department_id IN
       (SELECT department_id
        FROM   employees
        GROUP BY department_id
        HAVING MIN(salary) >= (SELECT AVG(salary) FROM employees))
ORDER BY department_id;
```

---

**[27번] 답**

```sql
SELECT last_name, salary, department_id
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees)
AND    employee_id IN (SELECT manager_id
                       FROM   employees
                       WHERE  manager_id IS NOT NULL)
AND    department_id IS NOT NULL
ORDER BY salary DESC;
```

---

**[28번] 답**

```sql
SELECT e.last_name,
       e.salary,
       (SELECT ROUND(AVG(salary))
        FROM   employees e2
        WHERE  e2.department_id = e.department_id) AS dept_avg,
       e.salary - (SELECT ROUND(AVG(salary))
                   FROM   employees e2
                   WHERE  e2.department_id = e.department_id) AS diff
FROM   employees e
WHERE  e.department_id IS NOT NULL
ORDER BY diff DESC
FETCH FIRST 10 ROWS ONLY;
```

---

**[29번] 답**

```sql
SELECT last_name, salary, job_id
FROM   employees
WHERE  salary BETWEEN (SELECT lowest_sal
                       FROM   job_grades
                       WHERE  grade_level = 'E')
                  AND (SELECT highest_sal
                       FROM   job_grades
                       WHERE  grade_level = 'E')
ORDER BY salary DESC;
```

---

**[30번] 답**

```sql
SELECT e.last_name, e.salary, e.department_id, d.dept_avg
FROM   employees e
JOIN   (SELECT department_id, ROUND(AVG(salary)) AS dept_avg
        FROM   employees
        GROUP BY department_id
        HAVING AVG(salary) >= 8000) d
ON     (e.department_id = d.department_id)
WHERE  e.salary > d.dept_avg
ORDER BY e.salary DESC;
```

> **처리 순서:**
> 1. 인라인 뷰: 부서별 평균 계산 후 8,000 이상 필터링
> 2. JOIN: 사원과 해당 부서 평균 연결
> 3. WHERE e.salary > d.dept_avg: 부서 평균보다 높은 사원만 필터링
> 4. ORDER BY: salary 내림차순
