# Oracle Database 19c: SQL Workshop
## Chapter 16 — 서브쿼리를 이용한 데이터 조회 | SQL 실습 모범답안

---

## Group 1: 인라인 뷰 (FROM 절 서브쿼리)

**[1번]**
```sql
SELECT department_name, city
FROM   departments
NATURAL JOIN (
    SELECT l.location_id, l.city, l.country_id
    FROM   locations l
    JOIN   countries c ON (l.country_id = c.country_id)
    JOIN   regions        USING (region_id)
    WHERE  region_name = 'Europe'
);
```

---

**[2번]**
```sql
SELECT d.department_name, cnt.emp_count
FROM   departments d
JOIN   (
    SELECT department_id, COUNT(*) emp_count
    FROM   employees
    GROUP BY department_id
) cnt ON (d.department_id = cnt.department_id)
WHERE  cnt.emp_count >= 5
ORDER BY cnt.emp_count DESC;
```

---

**[3번]**
```sql
SELECT last_name, salary, department_id
FROM   employees,
       (SELECT AVG(salary) avg_sal FROM employees)
WHERE  salary > avg_sal
ORDER BY salary DESC;
```

---

**[4번]**
```sql
SELECT e.department_id, mx.max_salary,
       e.employee_id, e.last_name
FROM   employees e
JOIN   (
    SELECT department_id, MAX(salary) max_salary
    FROM   employees
    GROUP BY department_id
) mx ON (e.department_id = mx.department_id
         AND e.salary = mx.max_salary)
ORDER BY e.department_id;
```

---

**[5번]**
```sql
SELECT job_id, avg_salary
FROM   (
    SELECT job_id, AVG(salary) avg_salary
    FROM   employees
    GROUP BY job_id
    ORDER BY avg_salary DESC
)
FETCH FIRST 3 ROWS ONLY;
```

---

## Group 2: 다중 열 서브쿼리 (쌍·비쌍 비교)

**[6번]** 쌍 비교(Pairwise)
```sql
-- 쌍 비교: (manager_id, department_id) 조합이 정확히 일치해야 함
SELECT employee_id, last_name, manager_id, department_id
FROM   employees
WHERE  (manager_id, department_id) IN (
    SELECT manager_id, department_id
    FROM   employees
    WHERE  employee_id IN (174, 141)
)
AND employee_id NOT IN (174, 141)
ORDER BY employee_id;
```

---

**[7번]** 비쌍 비교(Nonpairwise)
```sql
-- 비쌍 비교: manager_id, department_id를 독립적으로 비교 → 결과가 더 많을 수 있음
SELECT employee_id, last_name, manager_id, department_id
FROM   employees
WHERE  manager_id IN (
    SELECT manager_id FROM employees WHERE employee_id IN (174, 141)
)
AND department_id IN (
    SELECT department_id FROM employees WHERE employee_id IN (174, 141)
)
AND employee_id NOT IN (174, 141)
ORDER BY employee_id;
```

**결과 비교:**
- 쌍 비교: manager_id와 department_id가 **같은 행**에서 동시에 일치해야 함
- 비쌍 비교: 각 조건이 독립적이므로 **더 많은 행** 반환 가능

---

**[8번]**
```sql
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  (salary, department_id) IN (
    SELECT salary, department_id
    FROM   employees
    WHERE  employee_id IN (103, 107, 178)
)
AND employee_id NOT IN (103, 107, 178)
ORDER BY department_id, salary;
```

---

**[9번]**
```sql
SELECT employee_id, last_name, department_id, salary
FROM   employees
WHERE  (department_id, salary) IN (
    SELECT department_id, MIN(salary)
    FROM   employees
    GROUP BY department_id
)
ORDER BY department_id;
```

---

**[10번]**
```sql
SELECT employee_id, last_name, department_id, job_id
FROM   employees
WHERE  (department_id, job_id) IN (
    SELECT department_id, job_id
    FROM   employees
    WHERE  department_id IN (10, 20, 30)
)
AND department_id NOT IN (10, 20, 30)
ORDER BY department_id, job_id;
```

---

## Group 3: 스칼라 서브쿼리

**[11번]**
```sql
SELECT last_name,
       salary,
       (SELECT ROUND(AVG(salary), 2)
        FROM   employees ie
        WHERE  ie.department_id = oe.department_id) AS dept_avg_salary
FROM   employees oe
ORDER BY salary DESC;
```

---

**[12번]**
```sql
SELECT employee_id, last_name, salary,
       CASE
           WHEN salary > (SELECT AVG(salary) FROM employees ie
                          WHERE  ie.department_id = oe.department_id)
               THEN 'Above Average'
           WHEN salary < (SELECT AVG(salary) FROM employees ie
                          WHERE  ie.department_id = oe.department_id)
               THEN 'Below Average'
           ELSE 'Average'
       END AS salary_category
FROM   employees oe
ORDER BY salary_category, last_name;
```

---

**[13번]**
```sql
SELECT employee_id, last_name, department_id
FROM   employees oe
ORDER BY (
    SELECT COUNT(*)
    FROM   employees ie
    WHERE  ie.department_id = oe.department_id
) DESC, department_id;
```

---

**[14번]**
```sql
SELECT d.department_id, d.department_name,
       (SELECT e.last_name
        FROM   employees e
        WHERE  e.department_id = d.department_id
        AND    e.hire_date = (SELECT MAX(hire_date)
                              FROM   employees
                              WHERE  department_id = d.department_id)
        AND    ROWNUM = 1
       ) AS latest_hire_name
FROM   departments d
ORDER BY d.department_id;
```

---

**[15번]**
```sql
SELECT employee_id, last_name, department_id, salary
FROM   employees oe
WHERE  salary >= 1.5 * (
    SELECT AVG(salary)
    FROM   employees ie
    WHERE  ie.department_id = oe.department_id
)
ORDER BY salary DESC;
```

---

## Group 4: 상관 서브쿼리 & EXISTS

**[16번]**
```sql
SELECT last_name, department_id, salary
FROM   employees outer_e
WHERE  salary > (
    SELECT AVG(salary)
    FROM   employees inner_e
    WHERE  inner_e.department_id = outer_e.department_id
)
ORDER BY department_id, salary DESC;
```

---

**[17번]**
```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees e1
WHERE  salary > (
    SELECT AVG(salary)
    FROM   employees e2
    WHERE  e2.job_id = e1.job_id
)
ORDER BY job_id, salary DESC;
```

---

**[18번]**
```sql
SELECT employee_id, last_name, job_id, department_id
FROM   employees mgr
WHERE  EXISTS (
    SELECT NULL
    FROM   employees sub
    WHERE  sub.manager_id = mgr.employee_id
)
ORDER BY employee_id;
```

---

**[19번]**
```sql
SELECT department_id, department_name
FROM   departments d
WHERE  NOT EXISTS (
    SELECT NULL
    FROM   employees e
    WHERE  e.department_id = d.department_id
)
ORDER BY department_id;
```

---

**[20번]**
```sql
SELECT employee_id, last_name, job_id
FROM   employees e
WHERE  EXISTS (
    SELECT NULL
    FROM   job_history jh
    WHERE  jh.employee_id = e.employee_id
)
ORDER BY employee_id;
```

---

**[21번]**
```sql
SELECT employee_id, last_name, hire_date
FROM   employees e
WHERE  NOT EXISTS (
    SELECT NULL
    FROM   job_history jh
    WHERE  jh.employee_id = e.employee_id
)
ORDER BY hire_date DESC;
```

---

## Group 5: WITH 절 & 재귀 WITH

**[22번]**
```sql
WITH dept_avg AS (
    SELECT d.department_name,
           AVG(e.salary) avg_salary
    FROM   departments d
    JOIN   employees e ON (d.department_id = e.department_id)
    GROUP BY d.department_name
)
SELECT department_name,
       ROUND(avg_salary, 2) AS avg_salary
FROM   dept_avg
WHERE  avg_salary >= 10000
ORDER BY avg_salary DESC;
```

---

**[23번]**
```sql
WITH
dept_stats AS (
    SELECT department_id,
           COUNT(*)      emp_count,
           AVG(salary)   avg_sal
    FROM   employees
    GROUP BY department_id
),
top_depts AS (
    SELECT department_id
    FROM   dept_stats
    WHERE  emp_count >= 5
)
SELECT e.last_name, e.salary, e.department_id
FROM   employees e
WHERE  e.department_id IN (SELECT department_id FROM top_depts)
ORDER BY e.salary DESC;
```

---

**[24번]**
```sql
WITH
dept_totals AS (
    SELECT department_id,
           SUM(salary) dept_total_sal
    FROM   employees
    GROUP BY department_id
),
grand_total AS (
    SELECT SUM(salary) grand_sal
    FROM   employees
)
SELECT dt.department_id,
       dt.dept_total_sal,
       ROUND(dt.dept_total_sal / gt.grand_sal * 100, 2) AS pct_of_total
FROM   dept_totals dt, grand_total gt
ORDER BY pct_of_total DESC;
```

---

**[25번]**
```sql
WITH
top_earner AS (
    SELECT employee_id, last_name, department_id, salary
    FROM   employees
    WHERE  salary = (SELECT MAX(salary) FROM employees)
)
SELECT t.employee_id, t.last_name, t.salary,
       d.department_name, l.city
FROM   top_earner    t
JOIN   departments   d ON (d.department_id = t.department_id)
JOIN   locations     l ON (l.location_id   = d.location_id);
```

---

**[26번]**
```sql
WITH
sal_groups AS (
    SELECT employee_id,
           salary,
           CASE
               WHEN salary >= 10000 THEN 'High'
               WHEN salary >=  5000 THEN 'Mid'
               ELSE 'Low'
           END AS salary_group
    FROM   employees
)
SELECT salary_group,
       COUNT(*)              AS emp_count,
       ROUND(AVG(salary), 2) AS avg_salary
FROM   sal_groups
GROUP BY salary_group
ORDER BY avg_salary DESC;
```

---

**[27번]**
```sql
WITH org_tree (employee_id, last_name, manager_id, lvl) AS (
    -- 앵커 멤버: 최상위 관리자
    SELECT employee_id, last_name, manager_id, 1 AS lvl
    FROM   employees
    WHERE  manager_id IS NULL
    UNION ALL
    -- 재귀 멤버: 상위 직원의 부하 직원
    SELECT e.employee_id, e.last_name, e.manager_id, ot.lvl + 1
    FROM   employees e
    JOIN   org_tree  ot ON (e.manager_id = ot.employee_id)
)
SELECT employee_id, last_name, manager_id, lvl
FROM   org_tree
ORDER BY lvl, manager_id NULLS FIRST, employee_id;
```

---

**[28번]**
```sql
WITH org_tree (employee_id, last_name, manager_id, lvl) AS (
    SELECT employee_id, last_name, manager_id, 1 AS lvl
    FROM   employees
    WHERE  manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.last_name, e.manager_id, ot.lvl + 1
    FROM   employees e
    JOIN   org_tree  ot ON (e.manager_id = ot.employee_id)
)
SELECT employee_id,
       LPAD(' ', (lvl - 1) * 3, ' ') || last_name AS org_chart,
       lvl
FROM   org_tree
ORDER BY lvl, manager_id NULLS FIRST, employee_id;
```

---

**[29번]**
```sql
WITH dept_avg AS (
    SELECT department_id,
           AVG(salary) avg_salary
    FROM   employees
    GROUP BY department_id
)
SELECT e.employee_id, e.last_name, e.department_id,
       e.salary,
       ROUND(da.avg_salary, 2) AS dept_avg_salary
FROM   employees e
JOIN   dept_avg da ON (e.department_id = da.department_id)
WHERE  e.salary > da.avg_salary * 1.2
ORDER BY e.salary DESC;
```

---

**[30번]**
```sql
WITH dept_max AS (
    SELECT department_id, MAX(salary) max_sal
    FROM   employees
    GROUP BY department_id
)
SELECT e.employee_id, e.last_name, e.department_id, e.salary
FROM   employees e
JOIN   dept_max dm ON (e.department_id = dm.department_id
                       AND e.salary = dm.max_sal)
WHERE  EXISTS (
    SELECT NULL
    FROM   employees sub
    WHERE  sub.manager_id = e.employee_id
)
ORDER BY e.salary DESC;
```

**풀이 포인트:**
- `dept_max` CTE: 부서별 최고 급여 집계
- `JOIN dept_max`: 각 부서의 최고 급여자 필터링
- `EXISTS`: 해당 직원이 다른 직원의 관리자인지 확인
- 세 가지 기법(WITH, 인라인 조인, EXISTS)의 조합으로 단일 쿼리 완성
