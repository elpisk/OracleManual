# Oracle Database 19c: SQL Workshop
## Chapter 22 — 고급 서브쿼리 | SQL 실습 모범답안

---

## Group 1: 스칼라 서브쿼리

**[1번]** 각 직원 행마다 부서 평균 급여를 스칼라 서브쿼리로 조회

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

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   SALARY   DEPT_AVG_SAL
-----------  ----------  -------  ------------
200          Whalen        4400          4400
201          Hartstein    13000          9500
202          Fay           6000          9500
114          Raphaely     11000          4150
```

키포인트: `e2.department_id = e1.department_id`로 외부 행 참조 → 상관 스칼라 서브쿼리. 부서가 NULL인 직원은 서브쿼리 결과도 NULL.

---

**[2번]** 전체 평균 급여 초과 직원

```sql
SELECT last_name, salary, department_id
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;
```

**결과 예시:**
```
LAST_NAME   SALARY   DEPARTMENT_ID
----------  -------  -------------
King         24000              90
Kochhar      17000              90
De Haan      17000              90
...
```

키포인트: `(SELECT AVG(salary) FROM employees)`는 비상관 서브쿼리 — 한 번만 실행되어 6462 반환(근사값).

---

**[3번]** 부서 평균 급여 기준 정렬

```sql
SELECT last_name, department_id, salary
FROM   employees e1
ORDER BY (SELECT AVG(salary)
          FROM   employees e2
          WHERE  e2.department_id = e1.department_id) DESC,
         salary DESC;
```

키포인트: ORDER BY 절의 스칼라 서브쿼리 — 부서 평균 급여가 높은 부서 소속 직원이 먼저 나타남. 부서 90(평균 19333) 직원이 상단에 위치.

---

**[4번]** 부서별 직원 수 (없으면 0)

```sql
SELECT department_id,
       department_name,
       (SELECT COUNT(*)
        FROM   employees e
        WHERE  e.department_id = d.department_id) AS emp_count
FROM   departments d
ORDER BY department_id;
```

**결과 예시:**
```
DEPARTMENT_ID  DEPARTMENT_NAME    EMP_COUNT
-------------  -----------------  ---------
10             Administration             1
20             Marketing                  2
50             Shipping                  45
120            Treasury                   0
```

키포인트: `COUNT(*)`는 행이 없을 때 0을 반환 → `NVL` 불필요. NULL이 아닌 0으로 표시됨.

---

**[5번]** 전체 평균보다 높은 부서 평균 — HAVING 스칼라 서브쿼리

```sql
SELECT   department_id,
         ROUND(AVG(salary), 0) AS avg_sal
FROM     employees
GROUP BY department_id
HAVING   AVG(salary) > (SELECT AVG(salary) FROM employees)
ORDER BY avg_sal DESC;
```

**결과 예시:**
```
DEPARTMENT_ID  AVG_SAL
-------------  -------
90              19333
80              8956
20              9500
```

키포인트: `HAVING` 절의 서브쿼리는 그룹 집계 후 필터링. `WHERE`로는 집계 전 필터가 되어 의미가 다름.

---

## Group 2: 상관 서브쿼리

**[6번]** 부서 평균보다 높은 급여 직원

```sql
SELECT last_name, salary, department_id
FROM   employees e_outer
WHERE  salary > (SELECT AVG(salary)
                 FROM   employees e_inner
                 WHERE  e_inner.department_id = e_outer.department_id)
ORDER BY department_id, salary DESC;
```

**결과 예시:**
```
LAST_NAME    SALARY   DEPARTMENT_ID
-----------  -------  -------------
Hartstein     13000             20
Kaufling       8900             50
Weiss          8000             50
```

키포인트: 외부 행의 `department_id`마다 서브쿼리가 재실행됨 — 107명이라면 최대 107번 서브쿼리 실행.

---

**[7번]** 부서별 최고 급여 직원

```sql
SELECT employee_id, last_name, salary, department_id
FROM   employees e
WHERE  salary = (SELECT MAX(salary)
                 FROM   employees m
                 WHERE  m.department_id = e.department_id)
ORDER BY department_id;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   SALARY   DEPARTMENT_ID
-----------  ----------  -------  -------------
200          Whalen        4400             10
201          Hartstein    13000             20
149          Zlotkey      10500             80
```

키포인트: 동일 최고 급여를 받는 직원이 여러 명이면 모두 포함됨 (`=` 조건이므로 다중 행 가능).

---

**[8번]** 부서 평균 이하 급여 직원 + 부서 평균 함께 조회

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

키포인트: WHERE 절과 SELECT 절 모두 상관 서브쿼리 사용. 옵티마이저 캐싱으로 동일 department_id에 대한 중복 계산을 줄일 수 있음.

---

**[9번]** 부하 직원 3명 이상 관리자

```sql
SELECT employee_id, last_name, job_id
FROM   employees mgr
WHERE  (SELECT COUNT(*)
        FROM   employees sub
        WHERE  sub.manager_id = mgr.employee_id) >= 3
ORDER BY employee_id;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   JOB_ID
-----------  ----------  ----------
100          King        AD_PRES
101          Kochhar     AD_VP
108          Greenberg   FI_MGR
```

키포인트: 상관 서브쿼리에서 COUNT는 행이 없으면 0 반환 → 0 >= 3은 FALSE → 해당 직원 제외.

---

## Group 3: EXISTS / NOT EXISTS

**[10번]** 부하 직원이 있는 관리자

```sql
SELECT employee_id, last_name, job_id
FROM   employees mgr
WHERE  EXISTS (SELECT 1
               FROM   employees sub
               WHERE  sub.manager_id = mgr.employee_id)
ORDER BY employee_id;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   JOB_ID
-----------  ----------  ----------
100          King        AD_PRES
101          Kochhar     AD_VP
102          De Haan     IT_PROG
...
(18명)
```

키포인트: `SELECT 1` — 반환 값은 무관, 행 존재 여부만 검사. 첫 행 발견 즉시 TRUE → 효율적.

---

**[11번]** 직원 없는 부서

```sql
SELECT department_id, department_name
FROM   departments d
WHERE  NOT EXISTS (SELECT 1
                   FROM   employees e
                   WHERE  e.department_id = d.department_id)
ORDER BY department_id;
```

**결과 예시:**
```
DEPARTMENT_ID  DEPARTMENT_NAME
-------------  ---------------
120            Treasury
130            Corporate Tax
140            Control And Credit
150            Shareholder Services
160            Benefits
170            Manufacturing
180            Construction
190            Contracting
200            Operations
210            IT Support
220            NOC
230            IT Helpdesk
240            Government Sales
250            Retail Sales
260            Recruiting
270            Payroll
(16개 부서)
```

키포인트: HR 스키마의 27개 부서 중 11개에만 직원이 있음.

---

**[12번]** 같은 부서에 자신보다 높은 급여 동료가 있는 직원

```sql
SELECT last_name, salary, department_id
FROM   employees e
WHERE  EXISTS (SELECT 1
               FROM   employees higher
               WHERE  higher.department_id = e.department_id
               AND    higher.salary > e.salary)
ORDER BY department_id, salary;
```

키포인트: 부서 내 최고 급여 직원은 조건을 만족하는 동료가 없으므로 제외됨 → 최고 급여자 이하의 직원만 조회.

---

**[13번]** 직원이 없는 직무

```sql
SELECT job_id, job_title
FROM   jobs j
WHERE  NOT EXISTS (SELECT 1
                   FROM   employees e
                   WHERE  e.job_id = j.job_id)
ORDER BY job_id;
```

**결과 예시:**
```
JOB_ID    JOB_TITLE
--------  -------------------------
AC_ACCOUNT  Public Accountant
AD_ASST   Administration Assistant
...
```

키포인트: `NOT IN (SELECT job_id FROM employees)` 대신 `NOT EXISTS` 사용 — employees.job_id에 NULL이 없어도 습관적으로 NOT EXISTS를 권장.

---

## Group 4: 다중 컬럼 서브쿼리 & WITH 절

**[14번]** 부서별 최저 급여 직원 (페어 비교)

```sql
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  (department_id, salary) IN
       (SELECT department_id, MIN(salary)
        FROM   employees
        GROUP BY department_id)
ORDER BY department_id;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME    SALARY   DEPARTMENT_ID
-----------  -----------  -------  -------------
200          Whalen         4400             10
202          Fay            6000             20
137          Ladwig         3600             50
```

키포인트: `(dept=50, sal=3600)` 쌍이 서브쿼리 결과에 있어야 포함. 비페어 비교와 달리 다른 부서의 최저 급여와 혼동 없음.

---

**[15번]** 직무별 최고 급여 직원 (페어 비교)

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  (job_id, salary) IN
       (SELECT job_id, MAX(salary)
        FROM   employees
        GROUP BY job_id)
ORDER BY job_id;
```

키포인트: 동일 직무에서 최고 급여가 같은 직원이 여러 명이면 모두 포함.

---

**[16번]** WITH + 부서 통계 → 전체 평균 이상 부서 조회

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

**결과 예시:**
```
DEPARTMENT_NAME  AVG_SAL  MAX_SAL  MIN_SAL  HEADCOUNT
---------------  -------  -------  -------  ---------
Executive          19333    24000    17000          3
Sales               8956    14000     6100         34
Finance             8600    12008     6900          6
Marketing           9500    13000     6000          2
```

키포인트: CTE `dept_stats`를 한 번 정의 후 WHERE 절 서브쿼리 안에서도 재참조 가능.

---

**[17번]** 2단계 CTE — 급여 합계 → 평균 이상 필터

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

**결과 예시:**
```
DEPARTMENT_NAME  TOTAL_SAL
---------------  ---------
Sales             304500
Shipping          156400
Executive          58000
```

키포인트: `top_depts`에서 `dept_total`을 두 번 참조 (FROM과 서브쿼리). Oracle이 Materialize하면 한 번만 스캔.

---

## Group 5: 인라인 뷰 & TOP-N

**[18번]** ROWNUM 방식 급여 상위 5명

```sql
SELECT *
FROM  (SELECT employee_id, last_name, salary, department_id
       FROM   employees
       ORDER BY salary DESC)
WHERE  ROWNUM <= 5;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   SALARY   DEPARTMENT_ID
-----------  ----------  -------  -------------
100          King         24000             90
101          Kochhar      17000             90
102          De Haan      17000             90
145          Russell      14000             80
146          Partners     13500             80
```

키포인트: 인라인 뷰에서 먼저 ORDER BY 후 ROWNUM 적용. King(24000)이 1위.

---

**[19번]** FETCH FIRST WITH TIES — 동점 포함

```sql
SELECT employee_id, last_name, salary, department_id
FROM   employees
ORDER BY salary DESC
FETCH FIRST 5 ROWS WITH TIES;
```

키포인트: 5번째 급여(13500)와 같은 직원이 여러 명이면 모두 포함 → 5개보다 많은 행이 반환될 수 있음.

---

**[20번]** 페이지네이션 — 6~10번째

```sql
SELECT employee_id, last_name, salary
FROM   employees
ORDER BY salary DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   SALARY
-----------  ----------  -------
146          Partners     13500
147          Errazuriz    12000
...
```

키포인트: OFFSET 5 = 앞 5행(급여 상위 1~5위) 건너뜀. 6~10위 반환.

---

**[21번]** 부서별 평균 급여 상위 3개 부서

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

**결과 예시:**
```
DEPARTMENT_NAME  AVG_SAL
---------------  -------
Executive          19333
Marketing           9500
Sales               8956
```

키포인트: 인라인 뷰 내에서 JOIN + GROUP BY + ORDER BY 수행 후 ROWNUM 적용.

---

## Group 6: 종합 실습

**[22번]** 관리자보다 급여가 높은 직원

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

**결과 예시:**
```
EMPLOYEE_ID  EMP_NAME    EMP_SAL  MGR_NAME  MGR_SAL
-----------  ----------  -------  --------  -------
(HR 스키마에서는 일반적으로 관리자가 항상 더 높은 급여를 받으므로 결과 없음 — 확인 목적)
```

키포인트: 자기 참조 조인(Self Join). `manager_id IS NULL`인 최상위 관리자(King)는 결과에서 제외됨.

---

**[23번]** WITH + 분석 함수 — 부서별 급여 1위

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

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   SALARY   DEPARTMENT_ID
-----------  ----------  -------  -------------
200          Whalen        4400             10
201          Hartstein    13000             20
114          Raphaely     11000             30
```

키포인트: 분석 함수를 WHERE에서 직접 사용할 수 없으므로 CTE(또는 인라인 뷰)로 감싸야 함.

---

**[24번]** 직원 없는 부서 수

```sql
SELECT COUNT(*) AS empty_dept_count
FROM   departments d
WHERE  NOT EXISTS (SELECT 1
                   FROM   employees e
                   WHERE  e.department_id = d.department_id);
```

**결과:**
```
EMPTY_DEPT_COUNT
----------------
              16
```

키포인트: HR 스키마 27개 부서 중 16개에 직원 없음.

---

**[25번]** 급여 이상치(Outlier) 탐지 — 평균 ± 표준편차 범위 이탈

```sql
WITH sal_stats AS (
    SELECT AVG(salary)    AS avg_sal,
           STDDEV(salary) AS std_sal
    FROM   employees
)
SELECT e.employee_id,
       e.last_name,
       e.salary,
       ROUND(s.avg_sal, 0)               AS avg_sal,
       ROUND(s.avg_sal - s.std_sal, 0)   AS lower_bound,
       ROUND(s.avg_sal + s.std_sal, 0)   AS upper_bound
FROM   employees e
CROSS JOIN sal_stats s
WHERE  e.salary < s.avg_sal - s.std_sal
OR     e.salary > s.avg_sal + s.std_sal
ORDER BY e.salary DESC;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   SALARY   AVG_SAL  LOWER_BOUND  UPPER_BOUND
-----------  ----------  -------  -------  -----------  -----------
100          King         24000     6462         2246        10677
101          Kochhar      17000     6462         2246        10677
102          De Haan      17000     6462         2246        10677
```

키포인트: `CROSS JOIN sal_stats` — CTE 단일 행을 모든 직원 행과 결합. 평균(6462) + 표준편차(4215) = 상한 10677. 상한 초과 또는 하한 미달인 직원이 이상치.

---

**[26번]** 종합: 스칼라 서브쿼리 + WITH + IN — 관리자 정보 조회

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

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   SALARY   DEPT_CNT  DEPT_AVG
-----------  ----------  -------  --------  --------
100          King         24000          3     19333
101          Kochhar      17000          3     19333
108          Greenberg    12008          6      8600
```

키포인트:
- `mgr_list` CTE: `DISTINCT manager_id`로 중복 제거
- `IN (SELECT manager_id FROM mgr_list)`: 관리자인 직원만 필터
- 스칼라 서브쿼리 2개: 부서 직원 수·평균 급여 계산
- `IS NOT NULL` 조건: 최상위 관리자의 NULL manager_id 제외
