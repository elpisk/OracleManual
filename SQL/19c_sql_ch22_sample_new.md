# Oracle Database 19c: SQL Workshop
## Chapter 22 — 고급 서브쿼리 | SQL 실습 문제

---

> **참고:** 이 실습은 HR 스키마가 설치된 Oracle 19c 환경에서 수행하세요.

---

## Group 1: 스칼라 서브쿼리

**[1번]** `employees` 테이블에서 각 직원의 `employee_id`, `last_name`, `salary`와 함께 해당 직원이 속한 부서의 평균 급여(`dept_avg_sal`)를 조회하시오.

```sql
SELECT employee_id,
       last_name,
       salary,
       (SELECT ROUND(AVG(salary), 0)
        FROM   employees e2
        WHERE  e2.department_id = e1.department_id) AS dept_avg_sal
FROM   employees e1
ORDER BY department_id, salary DESC;
```

---

**[2번]** `employees` 테이블에서 전체 평균 급여보다 많이 받는 직원의 `last_name`, `salary`, `department_id`를 조회하고 급여 내림차순으로 정렬하시오.

```sql
SELECT last_name, salary, department_id
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;
```

---

**[3번]** `employees` 테이블에서 각 직원의 `last_name`과 `department_id`, `salary`를 조회하되, 결과를 해당 직원 부서의 평균 급여 기준으로 내림차순 정렬하시오.

```sql
SELECT last_name, department_id, salary
FROM   employees e1
ORDER BY (SELECT AVG(salary)
          FROM   employees e2
          WHERE  e2.department_id = e1.department_id) DESC,
         salary DESC;
```

---

**[4번]** `departments` 테이블에서 `department_id`, `department_name`과 함께 해당 부서의 직원 수를 스칼라 서브쿼리로 조회하시오. 직원이 없는 부서는 0으로 표시하시오.

```sql
SELECT department_id,
       department_name,
       (SELECT COUNT(*)
        FROM   employees e
        WHERE  e.department_id = d.department_id) AS emp_count
FROM   departments d
ORDER BY department_id;
```

---

**[5번]** `employees` 테이블에서 부서 평균 급여보다 높은 평균 급여를 가진 부서의 `department_id`와 평균 급여를 조회하시오. (스칼라 서브쿼리를 HAVING 절에 사용)

```sql
SELECT   department_id,
         ROUND(AVG(salary), 0) AS avg_sal
FROM     employees
GROUP BY department_id
HAVING   AVG(salary) > (SELECT AVG(salary) FROM employees)
ORDER BY avg_sal DESC;
```

---

## Group 2: 상관 서브쿼리

**[6번]** `employees` 테이블에서 자신이 속한 부서의 평균 급여보다 높은 급여를 받는 직원의 `last_name`, `salary`, `department_id`를 조회하시오.

```sql
SELECT last_name, salary, department_id
FROM   employees e_outer
WHERE  salary > (SELECT AVG(salary)
                 FROM   employees e_inner
                 WHERE  e_inner.department_id = e_outer.department_id)
ORDER BY department_id, salary DESC;
```

---

**[7번]** `employees` 테이블에서 자신이 속한 부서의 최고 급여와 동일한 급여를 받는 직원을 조회하시오. (`employee_id`, `last_name`, `salary`, `department_id`)

```sql
SELECT employee_id, last_name, salary, department_id
FROM   employees e
WHERE  salary = (SELECT MAX(salary)
                 FROM   employees m
                 WHERE  m.department_id = e.department_id)
ORDER BY department_id;
```

---

**[8번]** `employees` 테이블에서 자신이 속한 부서의 평균 급여보다 낮은 급여를 받는 직원의 `last_name`, `salary`, `department_id`와 해당 부서 평균 급여를 함께 조회하시오.

```sql
SELECT e.last_name,
       e.salary,
       e.department_id,
       (SELECT ROUND(AVG(salary), 0)
        FROM   employees d
        WHERE  d.department_id = e.department_id) AS dept_avg
FROM   employees e
WHERE  e.salary < (SELECT AVG(salary)
                   FROM   employees d
                   WHERE  d.department_id = e.department_id)
ORDER BY e.department_id, e.salary;
```

---

**[9번]** `employees` 테이블에서 부하 직원이 3명 이상인 관리자의 `employee_id`, `last_name`, `job_id`를 조회하시오.

```sql
SELECT employee_id, last_name, job_id
FROM   employees mgr
WHERE  (SELECT COUNT(*)
        FROM   employees sub
        WHERE  sub.manager_id = mgr.employee_id) >= 3
ORDER BY employee_id;
```

---

## Group 3: EXISTS / NOT EXISTS

**[10번]** `employees` 테이블에서 부하 직원을 한 명이라도 가진 관리자를 조회하시오. (`employee_id`, `last_name`, `job_id`)

```sql
SELECT employee_id, last_name, job_id
FROM   employees mgr
WHERE  EXISTS (SELECT 1
               FROM   employees sub
               WHERE  sub.manager_id = mgr.employee_id)
ORDER BY employee_id;
```

---

**[11번]** `departments` 테이블에서 직원이 한 명도 없는 부서를 조회하시오. (`department_id`, `department_name`)

```sql
SELECT department_id, department_name
FROM   departments d
WHERE  NOT EXISTS (SELECT 1
                   FROM   employees e
                   WHERE  e.department_id = d.department_id)
ORDER BY department_id;
```

---

**[12번]** `employees` 테이블에서 자신보다 급여가 높은 동료가 같은 부서에 있는 직원을 조회하시오. (`last_name`, `salary`, `department_id`)

```sql
SELECT last_name, salary, department_id
FROM   employees e
WHERE  EXISTS (SELECT 1
               FROM   employees higher
               WHERE  higher.department_id = e.department_id
               AND    higher.salary > e.salary)
ORDER BY department_id, salary;
```

---

**[13번]** `jobs` 테이블에서 현재 `employees` 테이블에 해당 직무를 가진 직원이 없는 `job_id`와 `job_title`을 조회하시오.

```sql
SELECT job_id, job_title
FROM   jobs j
WHERE  NOT EXISTS (SELECT 1
                   FROM   employees e
                   WHERE  e.job_id = j.job_id)
ORDER BY job_id;
```

---

## Group 4: 다중 컬럼 서브쿼리 & WITH 절

**[14번]** `employees` 테이블에서 각 부서별 최저 급여를 받는 직원을 페어 비교로 조회하시오. (`employee_id`, `last_name`, `salary`, `department_id`)

```sql
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  (department_id, salary) IN
       (SELECT department_id, MIN(salary)
        FROM   employees
        GROUP BY department_id)
ORDER BY department_id;
```

---

**[15번]** `employees` 테이블에서 각 직무(`job_id`)별 최고 급여를 받는 직원을 페어 비교로 조회하시오.

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  (job_id, salary) IN
       (SELECT job_id, MAX(salary)
        FROM   employees
        GROUP BY job_id)
ORDER BY job_id;
```

---

**[16번]** WITH 절을 사용하여 부서별 평균·최고·최저 급여를 CTE로 정의하고, 전체 평균 급여 이상인 부서만 `departments` 테이블과 조인하여 `department_name`과 함께 조회하시오.

```sql
WITH dept_stats AS (
    SELECT department_id,
           ROUND(AVG(salary), 0) AS avg_sal,
           MAX(salary)            AS max_sal,
           MIN(salary)            AS min_sal,
           COUNT(*)               AS headcount
    FROM   employees
    GROUP BY department_id
)
SELECT d.department_name,
       ds.avg_sal,
       ds.max_sal,
       ds.min_sal,
       ds.headcount
FROM   dept_stats  ds
JOIN   departments d ON ds.department_id = d.department_id
WHERE  ds.avg_sal >= (SELECT AVG(salary) FROM employees)
ORDER BY ds.avg_sal DESC;
```

---

**[17번]** WITH 절로 두 단계 CTE를 작성하시오.  
1단계: 부서별 급여 합계(`dept_total`) 계산  
2단계: 합계가 전체 부서 급여 합계 평균 이상인 부서 필터(`top_depts`)  
최종: `department_name`과 `total_sal` 조회

```sql
WITH
dept_total AS (
    SELECT department_id, SUM(salary) AS total_sal
    FROM   employees
    GROUP BY department_id
),
top_depts AS (
    SELECT department_id, total_sal
    FROM   dept_total
    WHERE  total_sal >= (SELECT AVG(total_sal) FROM dept_total)
)
SELECT d.department_name, td.total_sal
FROM   top_depts   td
JOIN   departments d ON td.department_id = d.department_id
ORDER BY td.total_sal DESC;
```

---

## Group 5: 인라인 뷰 & TOP-N

**[18번]** 인라인 뷰와 ROWNUM을 사용하여 급여 상위 5명을 조회하시오.

```sql
SELECT *
FROM  (SELECT employee_id, last_name, salary, department_id
       FROM   employees
       ORDER BY salary DESC)
WHERE  ROWNUM <= 5;
```

---

**[19번]** `FETCH FIRST`를 사용하여 급여 상위 5명을 조회하시오. (동점 포함)

```sql
SELECT employee_id, last_name, salary, department_id
FROM   employees
ORDER BY salary DESC
FETCH FIRST 5 ROWS WITH TIES;
```

---

**[20번]** `OFFSET`과 `FETCH NEXT`를 사용하여 급여 순위 6~10번째 직원을 조회하시오.

```sql
SELECT employee_id, last_name, salary
FROM   employees
ORDER BY salary DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
```

---

**[21번]** 인라인 뷰를 사용하여 부서별 평균 급여가 높은 상위 3개 부서와 해당 부서명을 조회하시오.

```sql
SELECT *
FROM  (SELECT d.department_name,
              ROUND(AVG(e.salary), 0) AS avg_sal
       FROM   employees e
       JOIN   departments d ON e.department_id = d.department_id
       GROUP BY d.department_name
       ORDER BY avg_sal DESC)
WHERE  ROWNUM <= 3;
```

---

## Group 6: 종합 실습

**[22번]** `employees` 테이블에서 자신의 관리자보다 급여가 높은 직원을 조회하시오. (`employee_id`, `last_name`, `salary`, 관리자 `last_name`, 관리자 `salary`)

```sql
SELECT e.employee_id,
       e.last_name      AS emp_name,
       e.salary         AS emp_sal,
       m.last_name      AS mgr_name,
       m.salary         AS mgr_sal
FROM   employees e
JOIN   employees m ON e.manager_id = m.employee_id
WHERE  e.salary > m.salary
ORDER BY e.salary DESC;
```

---

**[23번]** WITH 절과 분석 함수를 결합하여 각 부서에서 급여 순위 1위 직원을 조회하시오.

```sql
WITH ranked AS (
    SELECT employee_id,
           last_name,
           salary,
           department_id,
           RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rnk
    FROM   employees
)
SELECT employee_id, last_name, salary, department_id
FROM   ranked
WHERE  rnk = 1
ORDER BY department_id;
```

---

**[24번]** NOT EXISTS를 사용하여, `departments` 테이블에 있지만 `employees`에 해당 부서 직원이 없는 부서 수를 조회하시오.

```sql
SELECT COUNT(*) AS empty_dept_count
FROM   departments d
WHERE  NOT EXISTS (SELECT 1
                   FROM   employees e
                   WHERE  e.department_id = d.department_id);
```

---

**[25번]** WITH 절로 전체 급여 통계(평균, 최고, 최저, 표준편차)를 CTE로 정의하고, 급여가 `평균 ± 표준편차` 범위를 벗어나는 직원(`outlier`)을 조회하시오.

```sql
WITH sal_stats AS (
    SELECT AVG(salary)    AS avg_sal,
           STDDEV(salary) AS std_sal
    FROM   employees
)
SELECT e.employee_id,
       e.last_name,
       e.salary,
       ROUND(s.avg_sal, 0)         AS avg_sal,
       ROUND(s.avg_sal - s.std_sal, 0) AS lower_bound,
       ROUND(s.avg_sal + s.std_sal, 0) AS upper_bound
FROM   employees e
CROSS JOIN sal_stats s
WHERE  e.salary < s.avg_sal - s.std_sal
OR     e.salary > s.avg_sal + s.std_sal
ORDER BY e.salary DESC;
```

---

**[26번]** 스칼라 서브쿼리, EXISTS, WITH 절을 모두 활용하여 다음을 한 번의 쿼리로 조회하시오.
- 조건: 부하 직원이 있는 관리자
- 출력: `employee_id`, `last_name`, `salary`, 해당 부서 직원 수(`dept_cnt`), 부서 평균 급여(`dept_avg`)

```sql
WITH mgr_list AS (
    SELECT DISTINCT manager_id
    FROM   employees
    WHERE  manager_id IS NOT NULL
)
SELECT e.employee_id,
       e.last_name,
       e.salary,
       (SELECT COUNT(*)
        FROM   employees sub
        WHERE  sub.department_id = e.department_id) AS dept_cnt,
       (SELECT ROUND(AVG(salary), 0)
        FROM   employees sub
        WHERE  sub.department_id = e.department_id) AS dept_avg
FROM   employees e
WHERE  e.employee_id IN (SELECT manager_id FROM mgr_list)
ORDER BY e.salary DESC;
```
