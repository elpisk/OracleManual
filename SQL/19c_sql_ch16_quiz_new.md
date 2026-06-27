# Oracle Database 19c: SQL Workshop
## Chapter 16 — 서브쿼리를 이용한 데이터 조회 | 연습문제 50문제

---

## 하(기초) — 20문제

**[1번]** FROM 절에 서브쿼리를 사용하면 어떤 이름으로 불리는가?

① 스칼라 서브쿼리  
② 상관 서브쿼리  
③ 인라인 뷰(Inline View)  
④ 다중 행 서브쿼리

---

**[2번]** 다음 중 스칼라 서브쿼리(Scalar Subquery)의 정의로 올바른 것은?

① 여러 행과 여러 열을 반환하는 서브쿼리  
② 정확히 하나의 열 값(1행 1열)을 반환하는 서브쿼리  
③ FROM 절에서 사용되는 서브쿼리  
④ 외부 쿼리의 열을 참조하는 서브쿼리

---

**[3번]** 다음 중 스칼라 서브쿼리를 사용할 수 없는 절은?

① SELECT 절  
② WHERE 절  
③ GROUP BY 절  
④ ORDER BY 절

---

**[4번]** 다중 열 서브쿼리에서 쌍 비교(Pairwise)와 비쌍 비교(Nonpairwise)의 차이는?

① 쌍 비교는 단일 열, 비쌍 비교는 여러 열을 비교한다  
② 쌍 비교는 열을 묶어 동시에 비교하고, 비쌍 비교는 각 열을 독립적으로 비교한다  
③ 쌍 비교는 빠르고, 비쌍 비교는 느리다  
④ 차이가 없다

---

**[5번]** 다음 다중 열 서브쿼리에서 사용하는 비교 방식은?

```sql
WHERE (manager_id, department_id) IN (SELECT manager_id, department_id FROM employees WHERE ...)
```

① 비쌍 비교  
② 쌍 비교  
③ 스칼라 비교  
④ 상관 비교

---

**[6번]** 상관 서브쿼리(Correlated Subquery)의 특징으로 올바른 것은?

① 서브쿼리가 단 한 번만 실행된다  
② 외부 쿼리의 각 행에 대해 서브쿼리가 반복 실행된다  
③ 항상 단일 값을 반환한다  
④ FROM 절에만 사용할 수 있다

---

**[7번]** `EXISTS` 연산자는 어떤 경우에 TRUE를 반환하는가?

① 서브쿼리가 NULL을 반환할 때  
② 서브쿼리 결과 집합에 하나 이상의 행이 있을 때  
③ 서브쿼리 결과가 특정 값과 일치할 때  
④ 서브쿼리가 빈 집합을 반환할 때

---

**[8번]** `NOT EXISTS`가 유용한 경우는?

① 특정 값이 목록에 포함된 행을 찾을 때  
② 서브쿼리 결과에 없는 행을 찾을 때  
③ 집계 함수와 함께 사용할 때  
④ SELECT 절에서 단일 값을 계산할 때

---

**[9번]** WITH 절(CTE)의 주요 장점은?

① 영구 테이블을 생성하여 나중에도 사용할 수 있다  
② 동일한 서브쿼리 블록을 한 번 정의하고 재사용하여 가독성과 성능을 향상한다  
③ 인덱스를 자동으로 생성한다  
④ DML 작업에서만 사용 가능하다

---

**[10번]** WITH 절에서 정의한 결과는 어디에 저장되는가?

① 디스크의 영구 테이블  
② 사용자의 임시 테이블스페이스  
③ 메인 메모리(SGA)  
④ 리두 로그

---

**[11번]** 다음 중 EXISTS와 IN의 차이로 올바른 것은?

① EXISTS는 값 목록으로, IN은 행 존재 여부로 비교한다  
② EXISTS는 행 존재 여부로 비교하며 첫 행 발견 후 탐색을 중단한다  
③ IN이 항상 EXISTS보다 빠르다  
④ 두 연산자는 완전히 동일하다

---

**[12번]** 재귀 WITH 절에서 앵커(Anchor) 멤버의 역할은?

① 재귀 반복을 종료하는 조건이다  
② 재귀의 시작점(기본 케이스)을 정의한다  
③ 외부 쿼리와 연결하는 역할을 한다  
④ GROUP BY 집계를 수행한다

---

**[13번]** 다음 중 `SELECT NULL`을 EXISTS 서브쿼리에서 사용하는 이유는?

① NULL을 반환해야 EXISTS가 동작하기 때문  
② EXISTS는 반환 값이 아닌 행 존재 여부만 확인하므로 어떤 값이든 무관하다  
③ NULL이 가장 빠르게 처리되기 때문  
④ SELECT *보다 효율적이기 때문

---

**[14번]** 상관 서브쿼리에서 외부 쿼리 테이블을 참조할 때 사용하는 것은?

① 테이블 이름을 그대로 사용한다  
② 외부 쿼리 테이블의 별칭(alias)을 사용한다  
③ 스키마 이름을 사용한다  
④ 상관 서브쿼리에서는 외부 테이블을 참조할 수 없다

---

**[15번]** 다음 중 인라인 뷰(Inline View)에 대한 설명으로 올바른 것은?

① 인라인 뷰는 USER_VIEWS에 저장된다  
② 인라인 뷰는 FROM 절에 서브쿼리로 정의되며 해당 쿼리 내에서만 유효하다  
③ 인라인 뷰는 WITH READ ONLY를 적용할 수 없다  
④ 인라인 뷰에는 GROUP BY를 사용할 수 없다

---

**[16번]** 다중 열 서브쿼리의 비교 연산자로 올바른 것은?

① `=` 만 사용 가능하다  
② `IN`, `NOT IN`, `=`, `<>` 등을 사용할 수 있다  
③ `>`, `<` 만 사용 가능하다  
④ `BETWEEN` 만 사용 가능하다

---

**[17번]** 다음 WITH 절 구문에서 `cnt_dept`는 무엇인가?

```sql
WITH cnt_dept AS (SELECT department_id, COUNT(*) num_emp FROM employees GROUP BY department_id)
SELECT * FROM cnt_dept;
```

① 영구적으로 저장된 테이블  
② 해당 쿼리 내에서만 사용 가능한 임시 결과 집합의 이름  
③ 뷰 이름  
④ 인덱스 이름

---

**[18번]** 재귀 WITH 절에서 `UNION ALL`이 필요한 이유는?

① 중복을 제거하기 위해  
② 앵커 멤버와 재귀 멤버의 결과를 결합하기 위해  
③ 집계 함수를 사용하기 위해  
④ UNION ALL 없이도 재귀 WITH가 동작한다

---

**[19번]** 스칼라 서브쿼리가 0건을 반환하면 어떻게 되는가?

① 오류가 발생한다  
② NULL을 반환한다  
③ 0을 반환한다  
④ 빈 문자열을 반환한다

---

**[20번]** 다음 중 NOT EXISTS가 NOT IN보다 유리한 경우는?

① 서브쿼리가 단일 값만 반환할 때  
② 서브쿼리 결과에 NULL 값이 포함될 수 있을 때  
③ 성능이 항상 동일하기 때문에 차이가 없다  
④ NOT IN이 항상 더 좋다

---

## 중(응용) — 20문제

**[21번]** 다음 쌍 비교와 비쌍 비교의 결과 차이를 분석하시오.

데이터:
- employee_id 174: manager_id=148, department_id=80
- employee_id 141: manager_id=124, department_id=50

```sql
-- 쌍 비교
WHERE (manager_id, department_id) IN
    (SELECT manager_id, department_id FROM employees WHERE employee_id IN (174, 141))

-- 비쌍 비교
WHERE manager_id IN (SELECT manager_id FROM employees WHERE employee_id IN (174, 141))
AND   department_id IN (SELECT department_id FROM employees WHERE employee_id IN (174, 141))
```

쌍 비교가 반환하는 manager_id, department_id 조합은?

① (148, 80) 또는 (124, 50) 중 하나에 정확히 일치하는 행  
② manager_id가 148 또는 124 이고, department_id가 80 또는 50인 모든 조합  
③ manager_id와 department_id가 각각 다른 기준으로 비교된다  
④ 두 방법의 결과는 항상 동일하다

---

**[22번]** 다음 상관 서브쿼리를 분석하시오.

```sql
SELECT last_name, salary, department_id
FROM   employees outer_table
WHERE  salary > (
    SELECT AVG(salary)
    FROM   employees inner_table
    WHERE  inner_table.department_id = outer_table.department_id
);
```

이 쿼리가 올바르게 동작하려면 내부 서브쿼리는 몇 번 실행되는가?

① 1번  
② EMPLOYEES 테이블의 행 수만큼 실행  
③ 부서 수만큼 실행  
④ 10번 (기본값)

---

**[23번]** 다음 EXISTS 쿼리가 반환하는 결과는?

```sql
SELECT employee_id, last_name
FROM   employees outer
WHERE  EXISTS (
    SELECT NULL FROM employees
    WHERE  manager_id = outer.employee_id
);
```

① 관리자가 없는 직원 목록  
② 부하 직원이 없는 직원 목록  
③ 한 명 이상의 부하 직원을 가진 직원 목록  
④ 모든 직원 목록

---

**[24번]** 다음 쿼리에서 스칼라 서브쿼리가 2행을 반환하면 어떻게 되는가?

```sql
SELECT employee_id, last_name,
       (SELECT department_name FROM departments
        WHERE department_id = e.department_id) AS dept_name
FROM   employees e;
```

① 두 행이 모두 반환된다  
② ORA-01427: single-row subquery returns more than one row 오류  
③ 첫 번째 행만 반환된다  
④ NULL이 반환된다

---

**[25번]** 다음 WITH 절 쿼리의 실행 결과를 분석하시오.

```sql
WITH dept_avg AS (
    SELECT department_id, AVG(salary) avg_sal
    FROM   employees
    GROUP BY department_id
)
SELECT e.last_name, e.salary, d.avg_sal
FROM   employees e
JOIN   dept_avg  d ON (e.department_id = d.department_id)
WHERE  e.salary > d.avg_sal;
```

① 모든 직원의 평균 급여와 자신의 급여를 보여준다  
② 각 직원이 소속 부서 평균 급여보다 많이 받는 경우만 출력한다  
③ 급여가 전체 평균보다 높은 직원만 출력한다  
④ 급여가 없는 직원을 출력한다

---

**[26번]** 다음 NOT EXISTS 쿼리가 반환하는 결과는?

```sql
SELECT department_id, department_name
FROM   departments d
WHERE  NOT EXISTS (
    SELECT NULL FROM employees
    WHERE  department_id = d.department_id
);
```

① 직원이 있는 모든 부서  
② 직원이 한 명도 없는 부서  
③ 모든 부서  
④ 부서가 없는 직원

---

**[27번]** 다음 인라인 뷰 쿼리를 분석하시오.

```sql
SELECT department_name, city
FROM   departments
NATURAL JOIN (
    SELECT l.location_id, l.city, l.country_id
    FROM   locations l JOIN countries c ON (l.country_id = c.country_id)
    JOIN   regions USING (region_id)
    WHERE  region_name = 'Europe'
);
```

인라인 뷰가 하는 역할은?

① 유럽 지역의 location_id, city, country_id 필터링  
② 모든 location 정보 반환  
③ departments 테이블만 조회  
④ 인라인 뷰는 WHERE 절에서만 사용 가능하다

---

**[28번]** 다음 중 상관 서브쿼리로 각 부서에서 가장 높은 급여를 받는 직원을 찾는 올바른 쿼리는?

① `WHERE salary = (SELECT MAX(salary) FROM employees)`  
② `WHERE salary = (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id)`  
③ `WHERE salary IN (SELECT MAX(salary) FROM employees GROUP BY department_id)`  
④ ②와 ③ 모두 가능하다 (결과가 동일)

---

**[29번]** 재귀 WITH 절이 일반 WITH 절과 다른 점은?

① 임시 저장 방식이 다르다  
② CTE 내부에서 자기 자신을 참조하여 반복 처리한다  
③ DML에만 사용할 수 있다  
④ SELECT 절에서는 사용할 수 없다

---

**[30번]** 다음 중 스칼라 서브쿼리를 CASE 문에서 올바르게 사용한 예는?

① `CASE WHEN (SELECT COUNT(*) FROM employees) > 100 THEN 'Big' ELSE 'Small' END`  
② `CASE WHEN employee_id IN (SELECT employee_id FROM managers) THEN 'Mgr' ELSE 'Emp' END`  
③ `CASE department_id WHEN (SELECT MIN(department_id) FROM departments) THEN 'First' END`  
④ 위 모두 올바르다

---

**[31번]** 다음 WITH 절에서 두 CTE를 순서대로 정의할 때 올바른 구문은?

① `WITH a AS (...), b AS (...) SELECT ...`  
② `WITH a AS (...) WITH b AS (...) SELECT ...`  
③ `WITH a AS (...); WITH b AS (...) SELECT ...`  
④ `CTE a AS (...), b AS (...) SELECT ...`

---

**[32번]** 다음 쌍 비교 서브쿼리에서 NULL 처리 방식은?

```sql
WHERE (manager_id, department_id) IN (SELECT manager_id, department_id FROM ...)
```

NULL이 포함된 행의 처리 결과는?

① NULL = NULL → TRUE로 처리된다  
② NULL이 포함된 열은 비교에서 제외된다  
③ `(NULL, 80) IN (NULL, 80)` → 결과는 UNKNOWN (FALSE처럼 동작) — 행 제외  
④ NULL은 자동으로 0으로 변환된다

---

**[33번]** 다음 쿼리에서 EXISTS와 NOT IN을 비교하시오.

```sql
-- A: NOT IN 사용
SELECT department_id FROM departments
WHERE department_id NOT IN (SELECT department_id FROM employees WHERE department_id IS NOT NULL);

-- B: NOT EXISTS 사용
SELECT department_id FROM departments d
WHERE NOT EXISTS (SELECT NULL FROM employees WHERE department_id = d.department_id);
```

`employees.department_id`에 NULL 값이 있다면?

① A와 B 모두 동일한 결과를 반환한다  
② A는 0건 반환(NOT IN + NULL 문제), B는 올바른 결과 반환  
③ B는 0건 반환, A는 올바른 결과 반환  
④ 두 쿼리 모두 오류 발생

---

**[34번]** 다음 중 상관 서브쿼리 성능을 향상시키는 방법으로 올바른 것은?

① 상관 서브쿼리는 성능 개선이 불가능하다  
② 내부 서브쿼리에서 참조하는 열에 인덱스를 생성한다  
③ 상관 서브쿼리를 항상 JOIN으로 변환한다  
④ WITH 절을 사용하면 항상 상관 서브쿼리보다 빠르다

---

**[35번]** 다음 스칼라 서브쿼리를 SELECT 절에서 UPDATE SET 절로 이동한 예로 올바른 것은?

```sql
-- SELECT에서:
SELECT employee_id, (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id) max_sal
FROM employees e;
```

UPDATE SET 절로 변환:

① `UPDATE employees SET salary = (SELECT MAX(salary) FROM employees WHERE department_id = employee_id);`  
② `UPDATE employees e SET salary = (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id);`  
③ `UPDATE employees SET salary = (SELECT MAX(salary) FROM employees);`  
④ 스칼라 서브쿼리는 UPDATE SET 절에서 사용할 수 없다

---

**[36번]** WITH 절의 결과가 동일 쿼리 내에서 여러 번 참조될 때의 이점은?

① 쿼리가 더 복잡해진다  
② 정의된 결과 집합을 임시 저장소에서 재사용하여 반복 계산을 방지한다  
③ WITH 절 결과는 매번 새로 계산된다  
④ 인덱스가 자동으로 생성된다

---

**[37번]** 다음 상관 서브쿼리와 동등한 JOIN 쿼리를 고르시오.

```sql
SELECT last_name FROM employees e
WHERE  EXISTS (SELECT NULL FROM departments d WHERE d.department_id = e.department_id AND d.location_id = 1700);
```

① `SELECT e.last_name FROM employees e JOIN departments d ON ... WHERE d.location_id = 1700`  
② `SELECT last_name FROM employees WHERE department_id IN (SELECT department_id FROM departments WHERE location_id = 1700)`  
③ ①과 ② 모두 동등한 결과를 낼 수 있다  
④ EXISTS는 JOIN으로 변환 불가능하다

---

**[38번]** 다음 재귀 WITH 절에서 무한 루프를 방지하는 방법은?

① 재귀 WITH는 자동으로 종료된다  
② 재귀 멤버의 WHERE 조건이 점차 거짓이 되도록 설계한다  
③ ROWNUM을 사용한다  
④ GROUP BY를 추가한다

---

**[39번]** 다음 중 인라인 뷰와 WITH 절의 공통점은?

① 둘 다 영구 객체를 생성한다  
② 둘 다 임시 결과 집합을 정의하며 해당 쿼리 내에서만 유효하다  
③ 둘 다 DML에서만 사용 가능하다  
④ 둘 다 GROUP BY를 포함할 수 없다

---

**[40번]** 다음 다중 열 서브쿼리 쌍 비교에서 WHERE 조건 결과를 분석하시오.

```sql
-- employees에 manager_id=148, department_id=80인 직원이 존재
-- 또한 manager_id=148, department_id=50인 직원도 존재

WHERE (manager_id, department_id) IN (
    SELECT manager_id, department_id FROM employees WHERE employee_id = 174
    -- employee 174: manager_id=148, department_id=80
)
```

① manager_id=148이거나 department_id=80인 모든 직원  
② manager_id=148이고 department_id=80인 직원만 (쌍이 정확히 일치)  
③ manager_id=148인 직원과 department_id=80인 직원의 합집합  
④ 항상 빈 결과 반환

---

## 상(심화) — 10문제

**[41번]** 다음 쿼리를 분석하고 결과를 예측하시오.

```sql
WITH
sal_stats AS (
    SELECT department_id,
           AVG(salary) avg_sal,
           MAX(salary) max_sal,
           MIN(salary) min_sal
    FROM   employees
    GROUP BY department_id
),
above_avg AS (
    SELECT e.employee_id, e.last_name, e.salary, e.department_id
    FROM   employees e
    JOIN   sal_stats s ON (e.department_id = s.department_id)
    WHERE  e.salary > s.avg_sal
)
SELECT a.employee_id, a.last_name, a.salary,
       s.avg_sal, s.max_sal
FROM   above_avg a
JOIN   sal_stats s ON (a.department_id = s.department_id)
ORDER BY a.salary DESC;
```

이 쿼리의 결과는?

① 부서 평균보다 높은 급여를 받는 직원과 해당 부서의 평균·최대 급여  
② 전체 평균보다 높은 급여를 받는 직원  
③ 급여가 가장 높은 직원 1명  
④ 오류 발생 (CTE를 두 번 참조 불가)

---

**[42번]** 다음 시나리오에서 NOT IN과 NOT EXISTS의 차이를 분석하시오.

```sql
-- departments 테이블에 department_id: 10,20,30,...
-- employees 테이블에 department_id: 10,20,NULL

-- 쿼리 A: NOT IN
SELECT department_id FROM departments
WHERE  department_id NOT IN (SELECT department_id FROM employees);

-- 쿼리 B: NOT EXISTS
SELECT department_id FROM departments d
WHERE  NOT EXISTS (SELECT NULL FROM employees WHERE department_id = d.department_id);
```

employees.department_id에 NULL이 포함되어 있을 때의 결과는?

① A: 정상 동작, B: 0건 반환  
② A: 0건 반환, B: 정상 동작하여 직원 없는 부서 반환  
③ A와 B 모두 0건 반환  
④ A와 B 모두 동일 결과 반환

---

**[43번]** 다음 재귀 WITH 절의 동작을 분석하시오.

```sql
WITH emp_hier (employee_id, last_name, manager_id, level_n) AS (
    -- 앵커: 최상위 관리자 (manager_id IS NULL)
    SELECT employee_id, last_name, manager_id, 1
    FROM   employees
    WHERE  manager_id IS NULL
    UNION ALL
    -- 재귀: 부하 직원
    SELECT e.employee_id, e.last_name, e.manager_id, h.level_n + 1
    FROM   employees    e
    JOIN   emp_hier     h ON (e.manager_id = h.employee_id)
)
SELECT level_n, employee_id, last_name
FROM   emp_hier
ORDER BY level_n, employee_id;
```

① 최상위 관리자만 출력  
② 최상위 관리자부터 모든 계층의 직원을 level_n과 함께 출력  
③ 부하 직원만 출력  
④ 오류 발생 (employees 테이블을 두 번 참조)

---

**[44번]** 다음 쿼리에서 스칼라 서브쿼리가 두 개 사용될 때의 성능 영향을 분석하시오.

```sql
SELECT e.employee_id, e.last_name, e.salary,
       (SELECT AVG(salary) FROM employees WHERE department_id = e.department_id) avg_sal,
       (SELECT COUNT(*)    FROM employees WHERE department_id = e.department_id) cnt
FROM   employees e;
```

① employees의 각 행마다 두 개의 서브쿼리가 실행 → 총 107 × 2 = 214번 실행  
② 두 서브쿼리는 병렬로 실행된다  
③ 스칼라 서브쿼리는 캐싱되므로 실행 횟수가 줄어들 수 있다  
④ ①과 ③ 모두 맞다 (캐싱 동작에 따라 달라짐)

---

**[45번]** 다음 비쌍 비교와 쌍 비교의 결과 차이를 구체적 예로 분석하시오.

```sql
-- 데이터:
-- emp174: manager_id=148, dept_id=80
-- emp141: manager_id=124, dept_id=50
-- emp999: manager_id=148, dept_id=50  (관리자 148인데 부서는 50)

-- 쌍 비교
WHERE (manager_id, dept_id) IN ((148,80),(124,50))

-- 비쌍 비교
WHERE manager_id IN (148,124) AND dept_id IN (80,50)
```

emp999(manager_id=148, dept_id=50)는?

① 쌍 비교 포함, 비쌍 비교 포함  
② 쌍 비교 제외 (148,50 조합 없음), 비쌍 비교 포함 (148∈ 목록, 50∈ 목록)  
③ 쌍 비교 포함, 비쌍 비교 제외  
④ 두 방법 모두 제외

---

**[46번]** 다음 상관 서브쿼리를 WITH 절로 변환했을 때의 이점을 분석하시오.

```sql
-- 상관 서브쿼리 버전
SELECT last_name, salary, department_id
FROM   employees e
WHERE  salary > (SELECT AVG(salary) FROM employees WHERE department_id = e.department_id);

-- WITH 절 버전
WITH dept_avg AS (SELECT department_id, AVG(salary) avg_sal FROM employees GROUP BY department_id)
SELECT e.last_name, e.salary, e.department_id
FROM   employees e JOIN dept_avg d ON (e.department_id = d.department_id)
WHERE  e.salary > d.avg_sal;
```

WITH 절 버전의 이점은?

① 상관 서브쿼리: 107번 실행, WITH 절: 부서 개수(27번)만 실행하여 효율적  
② 상관 서브쿼리가 WITH 절보다 항상 빠르다  
③ 두 버전의 성능은 동일하다  
④ WITH 절은 집계 함수를 사용할 수 없다

---

**[47번]** 다음 쿼리에서 EXISTS 내부의 `SELECT NULL` 대신 `SELECT 1` 또는 `SELECT *`를 사용하면?

```sql
SELECT employee_id FROM employees e
WHERE  EXISTS (SELECT NULL FROM departments WHERE department_id = e.department_id);
```

① `SELECT 1` 또는 `SELECT *`를 사용하면 결과가 달라진다  
② `SELECT NULL`, `SELECT 1`, `SELECT *` 모두 동일한 결과를 반환한다 (EXISTS는 행 존재 여부만 확인)  
③ `SELECT *`는 더 많은 메모리를 사용하여 성능이 저하된다  
④ `SELECT NULL`만 올바른 문법이다

---

**[48번]** 다음 복잡한 WITH 절 쿼리를 분석하시오.

```sql
WITH
regional_depts AS (
    SELECT d.department_id, d.department_name, r.region_name
    FROM   departments d
    JOIN   locations   l USING (location_id)
    JOIN   countries   c USING (country_id)
    JOIN   regions     r USING (region_id)
),
emp_stats AS (
    SELECT department_id,
           COUNT(*) emp_cnt, AVG(salary) avg_sal
    FROM   employees
    GROUP BY department_id
),
combined AS (
    SELECT rd.department_name, rd.region_name,
           es.emp_cnt, es.avg_sal
    FROM   regional_depts rd
    JOIN   emp_stats      es USING (department_id)
)
SELECT region_name, COUNT(*) dept_cnt,
       SUM(emp_cnt) total_emp, AVG(avg_sal) regional_avg
FROM   combined
GROUP BY region_name
ORDER BY regional_avg DESC;
```

이 쿼리가 최종적으로 반환하는 것은?

① 직원별 부서 정보  
② 지역별 부서 수, 총 직원 수, 평균 급여  
③ 부서별 직원 수와 평균 급여  
④ 오류 발생 (CTE를 3개 이상 정의 불가)

---

**[49번]** 다음 중 스칼라 서브쿼리와 상관 서브쿼리의 차이를 올바르게 설명한 것은?

① 스칼라 서브쿼리는 항상 상관(외부 쿼리 참조)이다  
② 스칼라 서브쿼리는 반환 형태(1행 1열)에 관한 것이고, 상관 서브쿼리는 실행 방식(외부 쿼리 참조 반복 실행)에 관한 것이다  
③ 상관 서브쿼리는 항상 스칼라 서브쿼리이다  
④ 두 개념은 상호 배타적이다 (둘 다 될 수 없다)

---

**[50번]** 다음 재귀 WITH 절에서 무한 루프가 발생할 수 있는 상황은?

```sql
WITH reachable (src, dst, hops) AS (
    SELECT source, destination, 1 FROM routes
    UNION ALL
    SELECT r.src, f.destination, r.hops + 1
    FROM   reachable r JOIN routes f ON (r.dst = f.source)
)
SELECT * FROM reachable;
```

① 항상 안전하다  
② `routes` 테이블에 순환 경로(A→B→A)가 있으면 무한 루프 발생 가능  
③ UNION ALL이 있으면 무한 루프가 방지된다  
④ 재귀 멤버에 WHERE가 없으면 항상 무한 루프

---

*[Chapter 16 연습문제 끝 — 50문제]*
