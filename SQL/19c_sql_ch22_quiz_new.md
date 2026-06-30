# Oracle Database 19c: SQL Workshop
## Chapter 22 — 고급 서브쿼리 | 연습문제 (50문제)

---

## 하(기초) — 20문제

**[1번]** 다음 중 스칼라 서브쿼리(Scalar Subquery)의 정의로 옳은 것은?

① 여러 행과 여러 컬럼을 반환하는 서브쿼리  
② 단일 행과 단일 컬럼(스칼라 값)을 반환하는 서브쿼리  
③ FROM 절에 위치하는 서브쿼리  
④ 외부 쿼리를 참조하지 않는 서브쿼리

---

**[2번]** 스칼라 서브쿼리를 사용할 수 없는 절은?

① SELECT 절  
② FROM 절  
③ WHERE 절  
④ ORDER BY 절

---

**[3번]** 상관 서브쿼리(Correlated Subquery)의 특징으로 옳은 것은?

① 한 번만 실행되며 결과가 캐시된다  
② 외부 쿼리의 각 행마다 한 번씩 재실행된다  
③ GROUP BY 절에서만 사용 가능하다  
④ 반드시 단일 행을 반환해야 한다

---

**[4번]** `EXISTS` 연산자에 대한 설명으로 옳은 것은?

① 서브쿼리가 반환하는 모든 값과 외부 값을 비교한다  
② 서브쿼리가 한 행이라도 반환하면 TRUE가 된다  
③ 서브쿼리의 반환 컬럼 수와 타입이 일치해야 한다  
④ `=` 연산자와 기능이 동일하다

---

**[5번]** `NOT EXISTS`가 `NOT IN`보다 안전한 이유는?

① 더 빠른 실행 속도  
② NULL 값을 가진 행이 서브쿼리에 있어도 결과가 올바르게 나온다  
③ 더 간단한 문법  
④ 인덱스를 자동으로 사용한다

---

**[6번]** 다중 컬럼 서브쿼리에서 페어 비교(Pairwise Comparison)란?

① 두 테이블을 JOIN하는 방식  
② 여러 컬럼을 하나의 쌍(pair)으로 묶어 동시에 비교하는 방식  
③ 두 서브쿼리의 결과를 UNION으로 합치는 방식  
④ 서브쿼리 결과를 두 번 비교하는 방식

---

**[7번]** `WITH` 절의 다른 명칭은?

① 인라인 뷰  
② 스칼라 서브쿼리  
③ 공통 테이블 표현식(CTE)  
④ 상관 서브쿼리

---

**[8번]** 인라인 뷰(Inline View)는 쿼리의 어느 절에 위치하는가?

① SELECT 절  
② FROM 절  
③ WHERE 절  
④ HAVING 절

---

**[9번]** ROWNUM을 이용한 TOP-N 쿼리에서 올바른 작성 방법은?

① `SELECT * FROM employees WHERE ROWNUM <= 5 ORDER BY salary DESC;`  
② `SELECT * FROM (SELECT * FROM employees ORDER BY salary DESC) WHERE ROWNUM <= 5;`  
③ `SELECT * FROM employees ORDER BY salary DESC ROWNUM <= 5;`  
④ `SELECT TOP 5 * FROM employees ORDER BY salary DESC;`

---

**[10번]** Oracle 12c 이상에서 TOP-N 쿼리를 작성하는 권장 방식은?

① `ROWNUM <= N`  
② `WHERE LEVEL <= N`  
③ `FETCH FIRST N ROWS ONLY`  
④ `LIMIT N`

---

**[11번]** 스칼라 서브쿼리가 2행 이상을 반환하면 어떤 오류가 발생하는가?

① ORA-00907: missing right parenthesis  
② ORA-01427: single-row subquery returns more than one row  
③ ORA-00936: missing expression  
④ ORA-01722: invalid number

---

**[12번]** 다음 중 비상관 서브쿼리(Non-Correlated Subquery)의 특징은?

① 외부 쿼리의 컬럼을 참조한다  
② 외부 쿼리와 독립적으로 한 번만 실행된다  
③ FROM 절에서만 사용된다  
④ HAVING 절에서 사용할 수 없다

---

**[13번]** `WITH` 절 내에서 앞서 정의된 CTE를 이후 CTE에서 참조할 수 있는가?

① 불가능하다  
② 가능하다  
③ 같은 SELECT 문 내에서만 가능하다  
④ Oracle 19c 이상에서만 가능하다

---

**[14번]** `FETCH FIRST 5 ROWS WITH TIES`의 의미는?

① 정확히 5개의 행만 반환한다  
② 5번째 행과 같은 값을 가진 행도 함께 반환한다  
③ 5개 행을 반환하고 나머지를 삭제한다  
④ 5개 그룹을 반환한다

---

**[15번]** `OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY`의 의미는?

① 처음 5개 행을 반환한다  
② 처음 10개 행을 건너뛰고 다음 5개 행을 반환한다  
③ 10번째부터 15번째까지 행을 반환한다 (포함)  
④ ②와 ③ 모두 올바른 설명이다

---

**[16번]** EXISTS 서브쿼리 내에서 `SELECT *` 대신 `SELECT 1`을 쓰는 이유는?

① 더 빠른 실행 속도  
② 반환 값이 중요하지 않고 존재 여부만 확인하므로 명시적으로 표현  
③ 문법상 필수 요건  
④ NULL 방지

---

**[17번]** 다음 중 `WITH` 절의 장점이 아닌 것은?

① 동일 서브쿼리 반복 제거  
② 단계별 논리 분리로 디버깅 용이  
③ 외부 뷰(View)로 자동 저장  
④ 재귀 쿼리 작성 가능

---

**[18번]** 상관 UPDATE에 대한 설명으로 옳은 것은?

① UPDATE 문에서 서브쿼리를 사용할 수 없다  
② SET 절의 서브쿼리에서 외부 UPDATE 테이블을 참조할 수 있다  
③ 상관 UPDATE는 Oracle에서 지원하지 않는다  
④ 상관 UPDATE는 반드시 JOIN 방식으로 변환해야 한다

---

**[19번]** 인라인 뷰(Inline View)와 CTE(WITH 절)의 차이로 옳은 것은?

① 인라인 뷰는 재사용 가능하고 CTE는 불가능하다  
② CTE는 쿼리 내에서 이름을 부여하여 여러 번 참조할 수 있다  
③ 인라인 뷰는 DDL 문으로 저장된다  
④ 두 방식은 완전히 동일하다

---

**[20번]** 다음 중 `IN` 연산자와 `EXISTS` 연산자를 비교한 설명으로 옳은 것은?

① IN은 존재 여부만 검사하여 빠르다  
② EXISTS는 서브쿼리 결과 집합 전체를 메모리에 로드한다  
③ 서브쿼리에 NULL이 있으면 NOT IN의 결과는 항상 FALSE가 될 수 있다  
④ IN과 EXISTS는 항상 동일한 결과를 반환한다

---

## 중(응용) — 16문제

**[21번]** 다음 쿼리의 실행 결과로 옳은 것은?

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary = (SELECT MAX(salary) FROM employees);
```

① 모든 직원의 급여 조회  
② 가장 높은 급여를 받는 직원 조회  
③ 평균 급여를 받는 직원 조회  
④ ORA-01427 오류 발생

---

**[22번]** 다음 쿼리에서 빈칸에 들어갈 알맞은 연산자는?

```sql
SELECT last_name, department_id
FROM   employees e
WHERE  ______ (SELECT 1 FROM employees s
               WHERE s.manager_id = e.employee_id);
```

이 쿼리는 "부하 직원이 없는 직원"을 조회한다.

① IN  
② EXISTS  
③ NOT EXISTS  
④ NOT IN

---

**[23번]** 다음 쿼리의 결과로 옳은 것은?

```sql
SELECT department_id, department_name
FROM   departments d
WHERE  NOT EXISTS (SELECT 1 FROM employees e
                   WHERE e.department_id = d.department_id);
```

① 직원이 있는 모든 부서  
② 직원이 한 명도 없는 부서  
③ 가장 많은 직원이 있는 부서  
④ 부서 번호가 NULL인 직원

---

**[24번]** 다음 쿼리에서 `ROWNUM`을 바르게 사용한 것은?

```sql
-- A
SELECT * FROM employees WHERE ROWNUM <= 5 ORDER BY salary DESC;

-- B
SELECT * FROM (SELECT * FROM employees ORDER BY salary DESC)
WHERE ROWNUM <= 5;
```

① A만 올바르다  
② B만 올바르다 (급여 상위 5명 정확히 반환)  
③ A와 B 모두 동일한 결과를 반환한다  
④ A와 B 모두 오류가 발생한다

---

**[25번]** 다음 CTE 쿼리에서 `top_depts`가 참조할 수 있는 CTE는?

```sql
WITH
dept_stats AS (...),
emp_info   AS (...),
top_depts  AS (SELECT * FROM dept_stats WHERE ...)
SELECT * FROM top_depts;
```

① `dept_stats`와 `emp_info` 모두 참조 가능  
② `dept_stats`만 참조 가능  
③ 어떤 CTE도 참조 불가  
④ `emp_info`만 참조 가능

---

**[26번]** 다음 다중 컬럼 서브쿼리 결과로 옳은 것은?

```sql
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  (department_id, salary) IN
       (SELECT department_id, MIN(salary)
        FROM   employees GROUP BY department_id);
```

① 모든 부서의 최고 급여 직원  
② 각 부서에서 최저 급여를 받는 직원  
③ 전체 최저 급여 직원 한 명  
④ 각 부서에서 평균 급여를 받는 직원

---

**[27번]** 스칼라 서브쿼리가 NULL을 반환할 때 결과는?

```sql
SELECT last_name,
       (SELECT department_name FROM departments
        WHERE department_id = e.department_id) AS dept_name
FROM   employees e
WHERE  department_id IS NULL;
```

① ORA-01427 오류 발생  
② dept_name 컬럼이 NULL로 표시  
③ 해당 행이 결과에서 제외  
④ 빈 문자열('')이 표시

---

**[28번]** 다음 쿼리의 실행 결과로 옳은 것은?

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  salary > ALL (SELECT salary FROM employees
                     WHERE department_id = 50);
```

① 부서 50의 평균 급여보다 높은 직원  
② 부서 50의 최고 급여보다 높은 직원  
③ 부서 50의 최저 급여보다 높은 직원  
④ 부서 50에 속하지 않는 직원

---

**[29번]** `FETCH FIRST`와 `ROWNUM` 중 동점(동일 값) 처리가 가능한 것은?

① ROWNUM만 가능  
② FETCH FIRST ROWS WITH TIES만 가능  
③ 둘 다 가능  
④ 둘 다 불가능

---

**[30번]** 상관 서브쿼리가 비상관 서브쿼리보다 느릴 수 있는 이유는?

① 더 복잡한 SQL 파싱이 필요하기 때문  
② 외부 쿼리의 각 행마다 서브쿼리를 반복 실행하기 때문  
③ 항상 FULL TABLE SCAN을 수행하기 때문  
④ 인덱스를 사용할 수 없기 때문

---

**[31번]** 다음 CTE와 동일한 결과를 반환하는 인라인 뷰 쿼리로 옳은 것은?

```sql
WITH high_sal AS (
    SELECT employee_id, last_name, salary
    FROM   employees WHERE salary > 10000
)
SELECT * FROM high_sal ORDER BY salary DESC;
```

① `SELECT * FROM employees WHERE salary > 10000 ORDER BY salary DESC;`  
② `SELECT * FROM (SELECT employee_id, last_name, salary FROM employees WHERE salary > 10000) ORDER BY salary DESC;`  
③ `SELECT * FROM employees ORDER BY salary DESC WHERE salary > 10000;`  
④ ①과 ②는 동일한 결과를 반환한다

---

**[32번]** 다음 쿼리에서 오류가 발생하는 이유는?

```sql
SELECT last_name,
       (SELECT department_name, location_id
        FROM   departments
        WHERE  department_id = e.department_id) AS info
FROM   employees e;
```

① WHERE 절 오류  
② 스칼라 서브쿼리가 2개 컬럼을 반환하여 오류  
③ 상관 서브쿼리를 SELECT 절에서 사용할 수 없음  
④ 별칭(AS info)을 서브쿼리에 붙일 수 없음

---

**[33번]** 페이지네이션 쿼리에서 3페이지(페이지당 5행)를 조회하는 올바른 FETCH 구문은?

① `OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY`  
② `OFFSET 15 ROWS FETCH NEXT 5 ROWS ONLY`  
③ `FETCH FIRST 15 ROWS ONLY`  
④ `OFFSET 3 ROWS FETCH NEXT 5 ROWS ONLY`

---

**[34번]** 다음 중 EXISTS를 IN으로 대체했을 때 다른 결과가 나올 수 있는 상황은?

① 서브쿼리 결과에 NULL이 없는 경우  
② 서브쿼리 결과에 NULL이 포함된 경우 NOT IN 사용 시  
③ 서브쿼리가 단일 행을 반환하는 경우  
④ 외부 테이블이 작은 경우

---

**[35번]** 다음 쿼리에서 `HAVING` 절의 서브쿼리 역할은?

```sql
SELECT   department_id, AVG(salary)
FROM     employees
GROUP BY department_id
HAVING   AVG(salary) > (SELECT AVG(salary) FROM employees);
```

① 각 부서의 급여 합계를 계산  
② 전체 평균 급여를 스칼라 값으로 반환하여 HAVING 조건과 비교  
③ 서브쿼리 결과를 JOIN으로 연결  
④ 부서별로 서브쿼리를 반복 실행

---

**[36번]** 다음 중 WITH 절에서 재귀 쿼리(Recursive CTE)를 작성할 때 필요한 키워드는?

① `WITH RECURSIVE`  
② `WITH ... CONNECT BY`  
③`WITH ... CYCLE DETECTION`  
④ Oracle에서는 `CONNECT BY`만 사용하며 재귀 CTE 키워드는 별도 없음

---

## 상(심화) — 14문제

**[37번]** 다음 두 쿼리의 결과 차이를 올바르게 설명한 것은?

```sql
-- 쿼리 A: 페어 비교
SELECT employee_id FROM employees
WHERE  (department_id, salary) IN
       (SELECT department_id, MIN(salary) FROM employees GROUP BY department_id);

-- 쿼리 B: 비페어 비교
SELECT employee_id FROM employees
WHERE  department_id IN (SELECT department_id FROM employees GROUP BY department_id)
AND    salary        IN (SELECT MIN(salary) FROM employees GROUP BY department_id);
```

① A와 B는 항상 동일한 결과를 반환한다  
② B는 의도치 않게 다른 부서의 최저 급여와도 일치하는 행을 반환할 수 있다  
③ A에서 ORA-01427 오류가 발생한다  
④ B가 항상 더 적은 행을 반환한다

---

**[38번]** 스칼라 서브쿼리 대신 JOIN으로 변환했을 때 성능이 항상 좋아진다고 볼 수 없는 이유는?

① JOIN은 인덱스를 사용할 수 없다  
② 스칼라 서브쿼리는 옵티마이저가 결과를 캐시(Scalar Subquery Caching)할 수 있다  
③ JOIN은 항상 FULL TABLE SCAN을 수행한다  
④ 스칼라 서브쿼리는 PARALLEL 쿼리를 지원하지 않는다

---

**[39번]** 다음 쿼리에서 성능 문제가 발생할 수 있는 원인과 해결 방법은?

```sql
SELECT e.employee_id, e.last_name,
       (SELECT d.department_name FROM departments d
        WHERE d.department_id = e.department_id) AS dept_name,
       (SELECT d.location_id FROM departments d
        WHERE d.department_id = e.department_id) AS loc_id
FROM   employees e;
```

① 오류가 발생하므로 수정 필요 없음  
② departments를 두 번 스캔 → JOIN으로 대체하거나 단일 CTE로 통합하여 해결  
③ 스칼라 서브쿼리는 자동으로 최적화되어 문제 없음  
④ SELECT 절에 서브쿼리가 2개이면 항상 ORA 오류 발생

---

**[40번]** 다음 중 아래 NOT IN 쿼리가 예상치 못하게 0건을 반환하는 이유는?

```sql
SELECT employee_id FROM employees
WHERE  manager_id NOT IN (SELECT manager_id FROM employees);
```

① `manager_id`에 NULL이 없어야 하는데 있기 때문  
② `manager_id`가 NULL인 행이 서브쿼리 결과에 포함되어 NOT IN이 항상 FALSE가 되기 때문  
③ 서브쿼리가 빈 집합을 반환하기 때문  
④ NOT IN은 자기 참조 테이블에서 사용 불가

---

**[41번]** 다음 WITH 절에서 `sales_rank`가 `dept_sales`를 참조하는 것처럼, 두 번 이상 참조되는 CTE는 Oracle에서 어떻게 처리되는가?

```sql
WITH dept_sales AS (
    SELECT department_id, SUM(salary) AS total
    FROM   employees GROUP BY department_id
),
top_half AS (SELECT * FROM dept_sales WHERE total > (SELECT AVG(total) FROM dept_sales))
SELECT * FROM top_half;
```

① `dept_sales`는 항상 두 번 실행된다  
② Oracle 옵티마이저가 inline 또는 materialize 힌트에 따라 한 번만 실행할 수 있다  
③ 오류가 발생한다  
④ CTE 내에서 자신을 참조하므로 무한 루프가 발생한다

---

**[42번]** 다음 쿼리의 실행 결과로 옳은 것은?

```sql
SELECT employee_id, last_name, salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rnk
FROM   employees
WHERE  RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) = 1;
```

① 각 부서의 급여 1위 직원  
② ORA-30483 또는 ORA-00904 오류 발생 — 분석 함수를 WHERE 절에 직접 사용 불가  
③ 급여가 가장 높은 한 명  
④ 정상 실행된다

---

**[43번]** 위 [42번] 쿼리를 올바르게 수정한 방법은?

① `HAVING RANK() = 1`로 변경  
② 인라인 뷰 또는 CTE로 감싸서 외부에서 `WHERE rnk = 1`로 필터링  
③ `ORDER BY` 절에 RANK 조건 추가  
④ `CONNECT BY` 절로 변환

---

**[44번]** 다음 중 상관 DELETE 쿼리로 옳은 것은?

① `DELETE FROM employees WHERE EXISTS (SELECT 1 FROM departments WHERE department_id = employees.department_id AND location_id = 1700);`  
② `DELETE FROM employees WHERE IN (SELECT 1 FROM departments);`  
③ `DELETE FROM employees WHERE department_id > (SELECT AVG(department_id) FROM employees);`  
④ ①과 ③ 모두 올바른 상관 DELETE이다

---

**[45번]** 다음 두 쿼리 중 더 높은 성능이 기대되는 것과 그 이유는?

```sql
-- 쿼리 A: EXISTS
SELECT e.employee_id FROM employees e
WHERE  EXISTS (SELECT 1 FROM departments d WHERE d.department_id = e.department_id
               AND d.location_id = 1700);

-- 쿼리 B: IN
SELECT e.employee_id FROM employees e
WHERE  e.department_id IN (SELECT department_id FROM departments WHERE location_id = 1700);
```

① A가 빠름 — EXISTS는 첫 행 발견 시 즉시 중단  
② B가 빠름 — IN은 서브쿼리를 한 번만 실행하며 결과 집합이 작음  
③ 결과 집합 크기와 인덱스 상태에 따라 다르다  
④ 두 쿼리는 항상 동일한 실행 계획을 가진다

---

**[46번]** 아래 쿼리에서 `LATERAL` 키워드를 사용하는 목적은?

```sql
SELECT e.last_name, e.salary, d.avg_sal
FROM   employees e,
       LATERAL (SELECT ROUND(AVG(salary),0) AS avg_sal
                FROM   employees
                WHERE  department_id = e.department_id) d;
```

① 인라인 뷰가 외부 쿼리(`e`)의 컬럼을 참조할 수 있도록 허용  
② FROM 절에서 여러 서브쿼리를 병렬 실행  
③ 서브쿼리 결과를 수직으로 연결(UNION)  
④ 서브쿼리에 인덱스 힌트를 부여

---

**[47번]** 다음 OFFSET/FETCH 쿼리에서 동점 처리를 보장하면서 페이지당 5행씩 2페이지를 조회하는 올바른 구문은?

① `OFFSET 5 ROWS FETCH NEXT 5 ROWS WITH TIES`  
② `OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY`  
③ `FETCH FIRST 5 ROWS WITH TIES OFFSET 5`  
④ `SKIP 5 FETCH NEXT 5 ROWS WITH TIES`

---

**[48번]** 다음 쿼리의 결과 행 수에 대한 설명으로 옳은 것은?

```sql
WITH emp_dept AS (
    SELECT e.employee_id, e.last_name, d.department_name
    FROM   employees e
    LEFT JOIN departments d ON e.department_id = d.department_id
)
SELECT COUNT(*) FROM emp_dept;
```

① `employees` 테이블의 행 수와 같다  
② `departments` 테이블의 행 수와 같다  
③ JOIN 일치 행 수만 반환  
④ LEFT JOIN이므로 employees와 departments 행 수의 합

---

**[49번]** 재귀 CTE를 사용하여 계층 구조(EMPLOYEES의 관리자 체인)를 조회하려 한다. Oracle에서 이를 대체하는 전통 방식은?

① `GROUP BY ROLLUP`  
② `CONNECT BY PRIOR`  
③ `PIVOT`  
④ `MODEL` 절

---

**[50번]** 다음 중 아래 쿼리에서 성능을 최적화하기 위해 고려할 수 있는 방법을 모두 고른 것은?

```sql
SELECT e.employee_id,
       e.last_name,
       (SELECT d.department_name FROM departments d
        WHERE d.department_id = e.department_id) AS dept_name
FROM   employees e
WHERE  (SELECT COUNT(*) FROM employees m
        WHERE m.manager_id = e.employee_id) > 3;
```

가. `departments.department_id`에 인덱스 추가  
나. 스칼라 서브쿼리를 LEFT JOIN으로 대체  
다. WHERE의 상관 서브쿼리를 CTE로 분리 후 JOIN  
라. `manager_id`에 인덱스 추가

① 가, 나  
② 나, 다  
③ 가, 나, 라  
④ 가, 나, 다, 라 모두 유효한 최적화 방법
