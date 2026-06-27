# Oracle Database 19c: SQL Workshop
## Chapter 16 — 서브쿼리를 이용한 데이터 조회 (Retrieving Data by Using Subqueries)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- 다중 열 서브쿼리를 작성한다
- 스칼라 서브쿼리를 SQL 여러 위치에서 사용한다
- 상관 서브쿼리로 행별 처리 문제를 해결한다
- EXISTS / NOT EXISTS 연산자를 사용한다
- WITH 절(공통 테이블 표현식)을 사용한다

---

## 1. 서브쿼리를 소스(FROM 절)로 사용

FROM 절에 서브쿼리를 사용하면 인라인 뷰(Inline View)처럼 동작한다.

```sql
-- 유럽 지역 부서명과 도시 조회 (인라인 뷰)
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

- FROM 절의 서브쿼리는 **인라인 뷰(Inline View)**라고 한다
- 임시 결과 집합처럼 작동하며, 외부 쿼리에서 해당 결과를 다시 조회한다

---

## 2. 다중 열 서브쿼리 (Multiple-Column Subquery)

메인 쿼리의 각 행을 서브쿼리의 **여러 열**과 비교한다.

### 2-1. 쌍 비교 (Pairwise Comparison)

두 열을 묶어 동시에 비교:

```sql
-- employee_id 199 또는 174와 동일한 manager_id, department_id를 가진 직원
SELECT employee_id, manager_id, department_id
FROM   employees
WHERE  (manager_id, department_id) IN (
    SELECT manager_id, department_id
    FROM   employees
    WHERE  employee_id IN (174, 199)
)
AND employee_id NOT IN (174, 199);
```

- `(col1, col2) IN (subquery)` — 두 열을 함께 비교
- manager_id와 department_id **모두 일치**하는 행만 반환

### 2-2. 비쌍 비교 (Nonpairwise Comparison)

각 열을 별도의 서브쿼리로 독립 비교:

```sql
-- manager_id 조건과 department_id 조건을 각각 별도 서브쿼리로 비교
SELECT employee_id, manager_id, department_id
FROM   employees
WHERE  manager_id IN (
    SELECT manager_id FROM employees WHERE employee_id IN (174, 141)
)
AND department_id IN (
    SELECT department_id FROM employees WHERE employee_id IN (174, 141)
)
AND employee_id NOT IN (174, 141);
```

- 쌍 비교와 달리 각 조건을 **독립적으로** 평가
- 결과가 쌍 비교와 다를 수 있음 (교집합이 더 넓음)

---

## 3. 스칼라 서브쿼리 (Scalar Subquery)

**단 하나의 값(1행 1열)**을 반환하는 서브쿼리로, 단일 값이 올 수 있는 대부분의 위치에서 사용 가능하다.

### 3-1. 사용 가능한 위치

| 위치 | 가능 여부 |
|------|-----------|
| SELECT 절 | ✔ |
| WHERE 절 | ✔ |
| ORDER BY 절 | ✔ |
| CASE / DECODE 조건 | ✔ |
| UPDATE SET 절 | ✔ |
| GROUP BY 절 | ✘ |

### 3-2. CASE 식에서 스칼라 서브쿼리

```sql
-- 부서 위치에 따라 'Canada' 또는 'USA' 레이블 부여
SELECT employee_id, last_name,
       (CASE
            WHEN department_id = (
                SELECT department_id FROM departments
                WHERE  location_id = 1800
            ) THEN 'Canada'
            ELSE 'USA'
        END) AS location
FROM   employees;
```

### 3-3. SELECT 절에서 스칼라 서브쿼리

```sql
-- 각 부서의 직원 수를 SELECT 절에서 계산
SELECT department_id, department_name,
       (SELECT COUNT(*)
        FROM   employees e
        WHERE  e.department_id = d.department_id) AS emp_count
FROM   departments d;
```

---

## 4. 상관 서브쿼리 (Correlated Subquery)

외부 쿼리의 각 행에 대해 내부 서브쿼리가 **반복 실행**된다.

### 4-1. 처리 흐름

```
1. 외부 쿼리에서 후보 행(candidate row) 가져오기
2. 후보 행의 값을 사용하여 내부 서브쿼리 실행
3. 내부 서브쿼리 결과로 후보 행 포함/제외 결정
4. 외부 쿼리의 다음 행으로 반복
```

### 4-2. 상관 서브쿼리 구문

```sql
SELECT column1, column2
FROM   table1 outer_alias
WHERE  column1 operator (
    SELECT column1
    FROM   table2
    WHERE  expr = outer_alias.expr   -- 외부 쿼리 컬럼 참조
);
```

### 4-3. 예제 1 — 부서 평균 급여보다 많이 받는 직원

```sql
SELECT last_name, salary, department_id
FROM   employees outer_table
WHERE  salary > (
    SELECT AVG(salary)
    FROM   employees inner_table
    WHERE  inner_table.department_id = outer_table.department_id
);
```

- 외부 쿼리의 각 직원 행에 대해 **같은 부서의 평균 급여** 계산
- 평균 급여를 초과하는 직원만 반환

### 4-4. 예제 2 — 부서별 최고 급여 직원

```sql
SELECT department_id, employee_id, salary
FROM   employees e
WHERE  salary = (
    SELECT MAX(DISTINCT salary)
    FROM   employees
    WHERE  e.department_id = department_id
);
```

---

## 5. EXISTS / NOT EXISTS 연산자

서브쿼리 결과 집합에 행이 **존재하는지** 여부를 검사한다.

### 5-1. EXISTS

```sql
-- 관리자인 직원 조회 (하나 이상의 직원이 자신을 상관으로 가지는 직원)
SELECT employee_id, last_name, job_id, department_id
FROM   employees outer
WHERE  EXISTS (
    SELECT NULL
    FROM   employees
    WHERE  manager_id = outer.employee_id
);
```

- 서브쿼리에 행이 존재하면 → **TRUE** → 해당 행 포함
- 행이 발견되는 순간 내부 서브쿼리 탐색 중단 (효율적)
- `SELECT NULL` — 반환 값은 중요하지 않으므로 NULL 사용

### 5-2. NOT EXISTS

```sql
-- 직원이 없는 부서 조회
SELECT department_id, department_name
FROM   departments d
WHERE  NOT EXISTS (
    SELECT NULL
    FROM   employees
    WHERE  department_id = d.department_id
);
```

- 서브쿼리에 행이 **없으면** → **TRUE** → 해당 행 포함
- `NOT IN`과 달리 NULL 값에 안전 (NULL이 있어도 정상 동작)

### 5-3. EXISTS vs IN 비교

| 특징 | EXISTS | IN |
|------|--------|----|
| 검사 방식 | 행 존재 여부 (TRUE/FALSE) | 값 목록 포함 여부 |
| NULL 처리 | 안전 | NULL 포함 시 주의 필요 |
| 성능 (대용량) | 일반적으로 빠름 (첫 행 발견 후 중단) | 전체 목록 생성 후 비교 |
| 용도 | 상관 서브쿼리와 주로 사용 | 비상관 서브쿼리에 적합 |

---

## 6. WITH 절 (공통 테이블 표현식, CTE)

### 6-1. WITH 절 개요

복잡한 쿼리에서 **동일한 서브쿼리 블록을 여러 번** 사용할 때, 한 번 정의하고 재사용할 수 있다.

```sql
WITH 이름 AS (
    서브쿼리
)
SELECT ...
FROM   이름
...;
```

- 결과를 사용자의 임시 테이블스페이스에 저장
- 같은 블록을 반복 실행할 필요 없어 **성능 향상**
- 가독성 향상 (복잡한 쿼리를 논리 단위로 분리)

### 6-2. WITH 절 예제

```sql
-- 부서별 직원 수를 구하고 각 직원의 급여/직원수 계산
WITH cnt_dept AS (
    SELECT department_id, COUNT(*) num_emp
    FROM   employees
    GROUP BY department_id
)
SELECT e.employee_id,
       e.salary / c.num_emp AS sal_per_headcount
FROM   employees e
JOIN   cnt_dept  c ON (e.department_id = c.department_id);
```

### 6-3. 여러 CTE 정의

```sql
WITH
dept_avg AS (
    SELECT department_id, AVG(salary) avg_sal
    FROM   employees GROUP BY department_id
),
high_dept AS (
    SELECT department_id
    FROM   dept_avg
    WHERE  avg_sal > 8000
)
SELECT e.employee_id, e.last_name, e.salary
FROM   employees e
JOIN   high_dept h ON (e.department_id = h.department_id)
ORDER BY e.salary DESC;
```

---

## 7. 재귀 WITH 절 (Recursive WITH)

계층 구조 데이터(조직도, 그래프 등)를 순환 쿼리로 처리한다.

```sql
-- 항공편 경유 경로 탐색
WITH reachable_from (source, destin, total_time) AS (
    -- 앵커(Anchor): 직항 편
    SELECT source, destin, flight_time
    FROM   flights
    UNION ALL
    -- 재귀(Recursive): 연결 경유 편
    SELECT incoming.source, outgoing.destin,
           incoming.total_time + outgoing.flight_time
    FROM   reachable_from incoming
    JOIN   flights outgoing ON (incoming.destin = outgoing.source)
)
SELECT source, destin, total_time
FROM   reachable_from;
```

- **앵커 멤버**: 재귀의 시작점 (기본 케이스)
- **재귀 멤버**: CTE 이름을 참조하여 반복 확장
- `UNION ALL`로 앵커와 재귀 멤버를 연결
- ANSI 표준 호환

---

## 8. 단원 요약

| 주제 | 핵심 내용 |
|------|-----------|
| 인라인 뷰 | FROM 절에 서브쿼리 → 인라인 뷰(임시 결과 집합) |
| 다중 열 서브쿼리 | `(col1, col2) IN (subquery)` — 쌍 vs 비쌍 비교 |
| 스칼라 서브쿼리 | 단일 값 반환, SELECT/WHERE/CASE/SET 등에서 사용 |
| 상관 서브쿼리 | 외부 쿼리 열 참조, 행마다 반복 실행 |
| EXISTS | 서브쿼리에 행 존재 시 TRUE, NULL 안전, 빠름 |
| NOT EXISTS | 서브쿼리에 행 없을 때 TRUE, `NOT IN`보다 NULL 안전 |
| WITH 절 | 재사용 CTE 정의 → 가독성·성능 향상 |
| 재귀 WITH | UNION ALL로 앵커+재귀 → 계층·그래프 탐색 |
