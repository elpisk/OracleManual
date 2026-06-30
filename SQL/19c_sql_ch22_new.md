# Oracle Database 19c: SQL Workshop
## Chapter 22 — 고급 서브쿼리 (Advanced Subqueries)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- 스칼라 서브쿼리를 SELECT, WHERE, ORDER BY, HAVING 절에서 활용한다
- 상관 서브쿼리(Correlated Subquery)의 실행 원리를 이해하고 작성한다
- EXISTS / NOT EXISTS를 사용하여 행 존재 여부를 검사한다
- 다중 컬럼 서브쿼리로 여러 조건을 동시에 비교한다
- WITH 절(CTE)로 서브쿼리를 재사용하고 가독성을 높인다
- 인라인 뷰와 TOP-N 쿼리를 결합하여 순위 기반 결과를 추출한다

---

## 1. 서브쿼리 분류 복습

| 분류 기준 | 유형 | 설명 |
|-----------|------|------|
| 결과 행 수 | 단일 행 | 비교 연산자 `=`, `>`, `<` 등과 사용 |
| | 다중 행 | `IN`, `ANY`, `ALL`, `EXISTS`와 사용 |
| | 다중 컬럼 | `(col1, col2) IN (서브쿼리)` |
| 외부 참조 여부 | 비상관 서브쿼리 | 독립적으로 실행, 한 번만 평가 |
| | 상관 서브쿼리 | 외부 쿼리의 행을 참조, 행마다 재평가 |
| 위치 | 인라인 뷰 | FROM 절의 서브쿼리 |
| | 스칼라 서브쿼리 | SELECT·WHERE·ORDER BY 절의 단일 값 반환 |
| | 중첩 서브쿼리 | WHERE·HAVING 절의 필터 |

---

## 2. 스칼라 서브쿼리

단일 행·단일 컬럼(스칼라 값)을 반환하는 서브쿼리로, 표현식이 허용되는 거의 모든 위치에 사용 가능하다.

### 2-1. SELECT 절의 스칼라 서브쿼리

```sql
-- 각 직원의 급여와 자신이 속한 부서 평균 급여를 함께 조회
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
EMPLOYEE_ID  LAST_NAME   SALARY  DEPT_AVG_SAL
-----------  ----------  ------  ------------
200          Whalen       4400          4400
201          Hartstein   13000         9500
202          Fay          6000         9500
...
```

### 2-2. WHERE 절의 스칼라 서브쿼리

```sql
-- 전체 평균 급여보다 많이 받는 직원 조회
SELECT last_name, salary, department_id
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;
```

### 2-3. ORDER BY 절의 스칼라 서브쿼리

```sql
-- 부서 평균 급여 기준으로 직원 정렬
SELECT last_name, department_id, salary
FROM   employees e1
ORDER BY (SELECT AVG(salary)
          FROM   employees e2
          WHERE  e2.department_id = e1.department_id) DESC,
         salary DESC;
```

### 2-4. HAVING 절의 스칼라 서브쿼리

```sql
-- 전체 평균 급여보다 높은 평균 급여를 가진 부서 조회
SELECT   department_id, AVG(salary) AS avg_sal
FROM     employees
GROUP BY department_id
HAVING   AVG(salary) > (SELECT AVG(salary) FROM employees)
ORDER BY avg_sal DESC;
```

---

## 3. 상관 서브쿼리 (Correlated Subquery)

외부 쿼리의 현재 행 값을 서브쿼리 내부에서 참조하는 서브쿼리이다. 외부 쿼리의 **행마다 한 번씩** 재실행된다.

### 3-1. 실행 원리

```
외부 쿼리 행 → 서브쿼리에 외부 값 전달 → 서브쿼리 실행 → 결과로 외부 조건 평가 → 다음 행 반복
```

### 3-2. 같은 부서 평균보다 많이 받는 직원

```sql
-- 비상관 서브쿼리로는 부서별 비교가 어렵다 → 상관 서브쿼리 필요
SELECT last_name, salary, department_id
FROM   employees e_outer
WHERE  salary > (SELECT AVG(salary)
                 FROM   employees e_inner
                 WHERE  e_inner.department_id = e_outer.department_id)
ORDER BY department_id, salary DESC;
```

### 3-3. 부하 직원이 있는 관리자 조회

```sql
SELECT employee_id, last_name, job_id
FROM   employees mgr
WHERE  EXISTS (SELECT 1
               FROM   employees sub
               WHERE  sub.manager_id = mgr.employee_id);
```

### 3-4. 상관 UPDATE

```sql
-- 각 직원의 salary를 부서 평균으로 업데이트 (실행 예시 — 롤백 권장)
UPDATE employees e1
SET    salary = (SELECT AVG(salary)
                 FROM   employees e2
                 WHERE  e2.department_id = e1.department_id)
WHERE  department_id = 50;
ROLLBACK;
```

---

## 4. EXISTS / NOT EXISTS

EXISTS는 서브쿼리가 **한 행이라도** 반환하면 TRUE가 된다. 실제 값이 아닌 **존재 여부**만 검사하므로 `SELECT 1` 또는 `SELECT *` 모두 사용 가능하며, 대규모 테이블에서 IN보다 성능이 우수한 경우가 많다.

### 4-1. EXISTS vs IN 비교

| 항목 | IN | EXISTS |
|------|-----|--------|
| 평가 방식 | 결과 집합 전체와 비교 | 첫 행 발견 시 즉시 TRUE |
| NULL 처리 | 서브쿼리에 NULL이 있으면 NOT IN 결과 오류 가능 | NOT EXISTS는 NULL에 안전 |
| 대용량 외부 테이블 | 느릴 수 있음 | 빠름 |
| 대용량 서브쿼리 | 빠름 | 느릴 수 있음 |

### 4-2. EXISTS 예제

```sql
-- 부하 직원을 한 명이라도 가진 관리자
SELECT e.employee_id, e.last_name, e.job_id
FROM   employees e
WHERE  EXISTS (SELECT 1
               FROM   employees s
               WHERE  s.manager_id = e.employee_id)
ORDER BY e.employee_id;
```

### 4-3. NOT EXISTS 예제

```sql
-- 직원이 한 명도 없는 부서
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
...
```

---

## 5. 다중 컬럼 서브쿼리

여러 컬럼 값을 동시에 비교하는 서브쿼리이다. 각 컬럼을 개별 비교하는 것과 달리 **쌍(pair)으로** 비교한다.

### 5-1. 페어 비교 (Pairwise Comparison)

```sql
-- 부서별 최저 급여를 받는 직원 (부서+급여 쌍으로 비교)
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  (department_id, salary) IN
       (SELECT department_id, MIN(salary)
        FROM   employees
        GROUP BY department_id)
ORDER BY department_id;
```

### 5-2. 비페어 비교 (Non-Pairwise Comparison)

```sql
-- 어떤 부서의 최저 급여이기도 하고 어떤 부서의 평균 부서 번호이기도 한 직원
-- (각각 독립적인 서브쿼리로 비교)
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  salary IN (SELECT MIN(salary)
                  FROM   employees
                  GROUP BY department_id)
AND    department_id IN (SELECT department_id
                         FROM   employees
                         GROUP BY department_id
                         HAVING COUNT(*) > 3)
ORDER BY salary;
```

---

## 6. WITH 절 (Common Table Expressions)

복잡한 쿼리를 명명된 서브쿼리 블록으로 분리하여 **재사용성**과 **가독성**을 높인다. Oracle에서는 `WITH` 절이 인라인 뷰보다 옵티마이저에게 힌트를 더 잘 전달하기도 한다.

### 6-1. 구문

```sql
WITH cte_name1 AS (
    SELECT ...
),
cte_name2 AS (
    SELECT ... FROM cte_name1 ...
)
SELECT ...
FROM   cte_name1
JOIN   cte_name2 ON ...;
```

### 6-2. 부서 평균 급여 CTE 활용

```sql
WITH dept_avg AS (
    SELECT department_id,
           ROUND(AVG(salary), 0) AS avg_sal,
           COUNT(*)               AS headcount
    FROM   employees
    GROUP BY department_id
),
company_avg AS (
    SELECT ROUND(AVG(salary), 0) AS company_avg_sal
    FROM   employees
)
SELECT e.last_name,
       e.salary,
       e.department_id,
       da.avg_sal    AS dept_avg,
       ca.company_avg_sal
FROM   employees  e
JOIN   dept_avg   da ON e.department_id = da.department_id
CROSS JOIN company_avg ca
WHERE  e.salary > da.avg_sal
ORDER BY e.department_id, e.salary DESC;
```

### 6-3. 다단계 CTE

```sql
WITH
-- 1단계: 부서별 집계
dept_stats AS (
    SELECT department_id,
           COUNT(*)        AS cnt,
           SUM(salary)     AS total_sal,
           MAX(salary)     AS max_sal,
           MIN(salary)     AS min_sal
    FROM   employees
    GROUP BY department_id
),
-- 2단계: 상위 급여 부서 필터
top_depts AS (
    SELECT department_id, total_sal
    FROM   dept_stats
    WHERE  total_sal > (SELECT AVG(total_sal) FROM dept_stats)
)
SELECT d.department_name, td.total_sal, ds.cnt
FROM   top_depts  td
JOIN   departments d  ON td.department_id = d.department_id
JOIN   dept_stats  ds ON td.department_id = ds.department_id
ORDER BY td.total_sal DESC;
```

---

## 7. 인라인 뷰와 TOP-N 쿼리

FROM 절에 위치한 서브쿼리를 **인라인 뷰(Inline View)**라 한다. 이를 활용하여 TOP-N 쿼리를 작성한다.

### 7-1. ROWNUM 기반 TOP-N (전통 방식)

```sql
-- 급여 상위 5명
SELECT *
FROM  (SELECT employee_id, last_name, salary
       FROM   employees
       ORDER BY salary DESC)
WHERE  ROWNUM <= 5;
```

> **주의:** ROWNUM은 ORDER BY 이전에 부여되므로 반드시 인라인 뷰로 감싸야 한다.

### 7-2. FETCH FIRST (Oracle 12c+)

```sql
-- 급여 상위 5명 (동점 포함 시 TIES)
SELECT employee_id, last_name, salary
FROM   employees
ORDER BY salary DESC
FETCH FIRST 5 ROWS WITH TIES;

-- 6~10번째 직원 (페이지네이션)
SELECT employee_id, last_name, salary
FROM   employees
ORDER BY salary DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
```

### 7-3. 부서별 급여 1위 직원

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

## 8. 서브쿼리 vs JOIN — 선택 기준

| 상황 | 권장 방식 |
|------|-----------|
| 존재 여부만 확인 | `EXISTS` |
| 부모 테이블 컬럼 필요 없음 | `IN` 또는 `EXISTS` |
| 부모·자식 모두 컬럼 필요 | `JOIN` |
| 재사용 서브쿼리 | `WITH` 절 |
| 집계 후 필터 | `HAVING` + 서브쿼리 |
| 순위·페이지네이션 | 인라인 뷰 + `FETCH FIRST` |
