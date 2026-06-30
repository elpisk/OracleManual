# Oracle Database 19c: SQL Workshop
## Chapter 22 — 고급 서브쿼리 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | 스칼라 서브쿼리 = 단일 행 단일 컬럼(스칼라 값) 반환 |
| 2 | ② | FROM 절의 서브쿼리는 인라인 뷰라고 한다 (스칼라 서브쿼리와 구분) |
| 3 | ② | 상관 서브쿼리는 외부 행마다 재실행되어 행 수만큼 서브쿼리가 반복됨 |
| 4 | ② | EXISTS는 서브쿼리가 한 행이라도 반환하면 TRUE — 실제 값은 무관 |
| 5 | ② | NOT IN + NULL → `x NOT IN (1, 2, NULL)` = `x <> 1 AND x <> 2 AND x <> NULL` → NULL 비교 항상 UNKNOWN |
| 6 | ② | 페어 비교: (col1, col2) 쌍 전체로 동시 비교 — 각 컬럼 개별 비교와 다른 결과 가능 |
| 7 | ③ | WITH 절 = CTE(Common Table Expression) |
| 8 | ② | 인라인 뷰는 FROM 절에 위치하는 서브쿼리 |
| 9 | ② | ROWNUM은 ORDER BY 이전에 부여되므로 인라인 뷰로 먼저 정렬 후 ROWNUM 적용 |
| 10 | ③ | Oracle 12c+에서 `FETCH FIRST N ROWS ONLY` 권장 |
| 11 | ② | ORA-01427: single-row subquery returns more than one row |
| 12 | ② | 비상관 서브쿼리는 외부 참조 없이 독립적으로 한 번만 실행됨 |
| 13 | ② | WITH 절 내 앞서 정의된 CTE를 이후 CTE에서 참조 가능 |
| 14 | ② | WITH TIES: 마지막 행과 동일 ORDER BY 값을 가진 행도 모두 포함 |
| 15 | ④ | OFFSET 10 ROWS = 앞 10행 건너뜀, FETCH NEXT 5 = 다음 5행 → 11~15번째 행 (①②③ 모두 설명이 옳음) |
| 16 | ② | EXISTS는 존재 여부만 검사 — 반환 값 무의미, SELECT 1이 의도를 명확히 표현 |
| 17 | ③ | CTE는 쿼리 실행 중 임시 존재, 외부 뷰(VIEW)로 저장되지 않음 |
| 18 | ② | 상관 UPDATE: SET 절의 서브쿼리가 외부 UPDATE 테이블 컬럼 참조 가능 |
| 19 | ② | CTE는 이름을 부여하여 같은 쿼리 내에서 여러 번 참조 가능 |
| 20 | ③ | NOT IN + NULL 포함 서브쿼리 → UNKNOWN 전파로 결과가 0건이 될 수 있음 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

`(SELECT MAX(salary) FROM employees)`는 단일 값(최고 급여)을 반환하는 비상관 스칼라 서브쿼리이다. WHERE 절에서 `=`로 비교하므로 가장 높은 급여를 받는 직원(King, 24000)이 조회된다.

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary = (SELECT MAX(salary) FROM employees);
-- 결과: King  24000
```

---

**[22번] 정답: ③**

"부하 직원이 없는 직원"이므로 서브쿼리가 행을 반환하지 않아야 한다 → `NOT EXISTS`.

```sql
SELECT last_name, department_id
FROM   employees e
WHERE  NOT EXISTS (SELECT 1 FROM employees s
                   WHERE s.manager_id = e.employee_id);
```

`EXISTS`를 쓰면 부하 직원이 있는 관리자를 조회하게 된다.

---

**[23번] 정답: ②**

`NOT EXISTS (서브쿼리)`는 서브쿼리가 행을 반환하지 않을 때 TRUE이다. 즉, 해당 `department_id`로 `employees`에서 행이 없는 부서 = 직원이 한 명도 없는 부서.

```sql
-- 결과 예시
DEPARTMENT_ID  DEPARTMENT_NAME
-------------  ---------------
120            Treasury
130            Corporate Tax
140            Control And Credit
...
```

---

**[24번] 정답: ②**

- **쿼리 A**: ROWNUM이 ORDER BY 이전에 부여됨 → 정렬 전 임의의 5명에게 ROWNUM 1~5 부여 → 급여 상위 5명이 아님
- **쿼리 B**: 인라인 뷰에서 먼저 `ORDER BY salary DESC` 정렬 → 바깥에서 `ROWNUM <= 5` 적용 → 정확히 급여 상위 5명

---

**[25번] 정답: ①**

`WITH` 절에서는 앞서 정의된 CTE를 이후 CTE에서 참조할 수 있다. `top_depts`는 자신보다 앞에 정의된 `dept_stats`와 `emp_info` 모두 참조 가능하다.

---

**[26번] 정답: ②**

`(department_id, salary) IN (department_id, MIN(salary))` → 각 부서에서 급여가 해당 부서의 최솟값인 직원만 반환. 두 컬럼이 쌍으로 일치해야 하므로 "내 부서의 최저 급여를 받는 나" 조건이다.

---

**[27번] 정답: ②**

`department_id IS NULL`인 직원의 서브쿼리 조건 `department_id = e.department_id` → `NULL = NULL` = UNKNOWN → 서브쿼리 반환 행 없음 → 스칼라 서브쿼리가 NULL을 반환 → `dept_name` 컬럼이 NULL로 표시. 행 자체는 제외되지 않는다.

---

**[28번] 정답: ②**

`> ALL (서브쿼리)` → 서브쿼리의 **모든 값**보다 크다 = 최댓값보다 크다.

```sql
salary > ALL (SELECT salary FROM employees WHERE department_id = 50)
-- ≡
salary > (SELECT MAX(salary) FROM employees WHERE department_id = 50)
```

따라서 부서 50의 최고 급여(8900, Kaufling)보다 높은 직원들이 조회된다.

---

**[29번] 정답: ②**

`FETCH FIRST N ROWS WITH TIES`는 N번째 행과 동일한 ORDER BY 값을 가진 행도 모두 포함한다. ROWNUM 방식은 `ROWNUM <= N`을 초과하면 무조건 제외하므로 동점 처리가 안 된다.

---

**[30번] 정답: ②**

상관 서브쿼리는 외부 쿼리의 **각 행마다** 서브쿼리를 재실행한다. 외부 테이블에 100만 행이 있으면 서브쿼리도 최대 100만 번 실행된다. 비상관 서브쿼리는 한 번만 실행 후 결과를 재사용하므로 일반적으로 더 빠르다.

---

**[31번] 정답: ④**

①은 `FROM employees WHERE salary > 10000 ORDER BY salary DESC`로 완전히 동일.
②는 CTE를 인라인 뷰로 바꾼 것으로 역시 동일.
두 방식 모두 `employees`에서 salary > 10000인 행을 salary 내림차순으로 조회하므로 결과가 같다.

---

**[32번] 정답: ②**

스칼라 서브쿼리는 **단일 컬럼**만 반환할 수 있다. `SELECT department_name, location_id`는 2개 컬럼을 반환하므로 `ORA-00913: too many values` 또는 관련 오류 발생.

```sql
-- 수정: 컬럼을 분리하거나 JOIN으로 대체
SELECT e.last_name,
       (SELECT d.department_name FROM departments d WHERE d.department_id = e.department_id),
       (SELECT d.location_id FROM departments d WHERE d.department_id = e.department_id)
FROM   employees e;
-- 또는 JOIN 방식 권장
```

---

**[33번] 정답: ①**

3페이지 = 앞 2페이지(10행)를 건너뜀 → `OFFSET 10 ROWS`, 그 다음 5행 → `FETCH NEXT 5 ROWS ONLY`.

| 페이지 | OFFSET | FETCH |
|--------|--------|-------|
| 1 | 0 | 5 |
| 2 | 5 | 5 |
| 3 | 10 | 5 |

---

**[34번] 정답: ②**

`NOT IN` 서브쿼리 결과에 NULL이 하나라도 있으면 `x NOT IN (..., NULL)` 조건에서 NULL과의 비교가 UNKNOWN이 되어 **전체 조건이 FALSE**가 된다 → 0건 반환. `NOT EXISTS`는 이 문제를 피할 수 있다.

---

**[35번] 정답: ②**

`HAVING` 절의 서브쿼리 `(SELECT AVG(salary) FROM employees)`는 전체 평균 급여를 **단일 스칼라 값**으로 반환한다. 이 값과 각 부서의 `AVG(salary)`를 비교하여 전체 평균보다 높은 부서만 필터링한다.

---

**[36번] 정답: ④**

Oracle은 표준 SQL의 `WITH RECURSIVE` 키워드를 지원하지 않는다. Oracle에서는 전통적으로 `CONNECT BY PRIOR`를 사용한다. Oracle 11g+ 에서 CTE 내에 `SEARCH` 및 `CYCLE` 절을 쓸 수 있지만 `RECURSIVE` 키워드는 사용하지 않는다.

---

## 상(심화) 모범답안

---

**[37번] 정답: ②**

페어 비교(A)는 `(dept=10, sal=4400)` 쌍이 모두 일치해야 한다.
비페어 비교(B)는 `dept IN (10, 20, ...)` AND `sal IN (4400, 6000, ...)` 각각 독립 비교 → 부서 20 직원이지만 급여가 우연히 부서 10의 최저 급여(4400)와 같다면 B에서는 포함되고 A에서는 제외된다.

```sql
-- 예시: (dept=20, sal=4400)이 있다면
-- A: (20, 4400)이 서브쿼리 쌍에 있어야 포함 → (20, MIN(sal of dept 20)) = (20, 6000) → 불일치 → 제외
-- B: dept=20 ∈ 모든 dept ✓, sal=4400 ∈ MIN 값들 ✓ → 잘못 포함
```

---

**[38번] 정답: ②**

Oracle 옵티마이저는 **Scalar Subquery Caching** 기능으로 동일한 입력값에 대해 스칼라 서브쿼리 결과를 해시 캐시에 저장하여 재실행을 방지한다. 예를 들어 같은 `department_id`가 반복되면 두 번째부터는 캐시에서 반환한다. 따라서 JOIN이 항상 빠른 것은 아니다.

---

**[39번] 정답: ②**

두 스칼라 서브쿼리가 모두 `departments` 테이블에 접근하므로 행마다 최대 2번 스캔이 발생한다. 최적화 방법:

```sql
-- 방법 1: JOIN으로 대체 (한 번만 스캔)
SELECT e.employee_id, e.last_name, d.department_name, d.location_id
FROM   employees e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- 방법 2: CTE로 통합
WITH dept_info AS (SELECT department_id, department_name, location_id FROM departments)
SELECT e.employee_id, e.last_name, d.department_name, d.location_id
FROM   employees e
LEFT JOIN dept_info d ON e.department_id = d.department_id;
```

---

**[40번] 정답: ②**

`employees.manager_id` 컬럼에는 최상위 관리자(King)의 경우 NULL이 존재한다.

```sql
SELECT manager_id FROM employees;
-- 결과: 100, 101, 102, ..., NULL (King의 manager_id)
```

`NOT IN (100, 101, ..., NULL)` → 내부적으로 `x <> NULL` 조건이 포함 → UNKNOWN → 전체 WHERE 조건 FALSE → **0건** 반환.

해결 방법:
```sql
-- 방법 1: NOT EXISTS로 대체
WHERE NOT EXISTS (SELECT 1 FROM employees m WHERE m.manager_id = e.employee_id)

-- 방법 2: NOT IN + NULL 제외
WHERE manager_id NOT IN (SELECT manager_id FROM employees WHERE manager_id IS NOT NULL)
```

---

**[41번] 정답: ②**

Oracle은 CTE에 대해 두 가지 실행 방식을 선택한다:
- **Inline 방식**: CTE를 참조 시점마다 펼쳐서 실행 (두 번 참조 → 두 번 실행)
- **Materialize 방식**: 임시 결과를 메모리/디스크에 저장 후 재사용

`/*+ MATERIALIZE */` 또는 `/*+ INLINE */` 힌트로 제어 가능. 옵티마이저가 자동 판단할 때는 참조 횟수, 결과 크기 등을 고려한다.

---

**[42번] 정답: ②**

분석 함수(Analytic Function)는 WHERE 절에서 직접 사용할 수 없다. WHERE 절은 분석 함수 적용 전 단계이기 때문이다.

`ORA-30483: window functions are not allowed here` 또는 유사한 오류가 발생한다.

---

**[43번] 정답: ②**

분석 함수 결과를 WHERE 조건으로 사용하려면 인라인 뷰나 CTE로 감싸야 한다:

```sql
-- 인라인 뷰 방식
SELECT employee_id, last_name
FROM  (SELECT employee_id, last_name, salary,
              RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rnk
       FROM   employees)
WHERE  rnk = 1;

-- CTE 방식
WITH ranked AS (
    SELECT employee_id, last_name,
           RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rnk
    FROM   employees
)
SELECT employee_id, last_name FROM ranked WHERE rnk = 1;
```

---

**[44번] 정답: ④**

①: `EXISTS (서브쿼리)`로 location_id = 1700인 부서 소속 직원을 삭제하는 상관 DELETE — 올바른 상관 DELETE.

③: `salary > (SELECT AVG(...))`는 상관 서브쿼리는 아니지만 서브쿼리를 사용한 DELETE로 유효하다.

단, `manager_id > AVG(department_id)`는 의미상 이상하지만 문법적으로는 동작한다. ①이 정통 상관 DELETE이고 ③도 서브쿼리를 사용하는 DELETE이므로 ④가 정답.

---

**[45번] 정답: ③**

성능은 단일 절대 답이 없으며 다음 요인에 따라 달라진다:

| 요인 | EXISTS 유리 | IN 유리 |
|------|------------|---------|
| 외부 테이블 크기 | 클 때 | 작을 때 |
| 서브쿼리 결과 크기 | 클 때 (첫 행 발견 즉시 중단) | 작을 때 |
| 인덱스 존재 | `department_id`에 인덱스 있으면 둘 다 유사 | |
| 옵티마이저 변환 | Oracle은 IN을 EXISTS로 자동 변환하기도 함 | |

실무에서는 실행 계획(EXPLAIN PLAN)으로 직접 확인해야 한다.

---

**[46번] 정답: ①**

`LATERAL` 키워드를 사용하면 FROM 절의 인라인 뷰가 **같은 FROM 절 앞에 있는 테이블의 컬럼**을 참조할 수 있다. 일반 인라인 뷰는 외부 쿼리 컬럼을 참조하면 오류가 발생하지만 LATERAL을 붙이면 상관 서브쿼리처럼 동작한다.

```sql
-- LATERAL 없이는 e.department_id 참조 불가 (오류)
-- LATERAL 있으면 외부 e 테이블의 department_id를 참조 가능
SELECT e.last_name, e.salary, d.avg_sal
FROM   employees e,
       LATERAL (SELECT ROUND(AVG(salary),0) AS avg_sal
                FROM   employees
                WHERE  department_id = e.department_id) d;
```

---

**[47번] 정답: ①**

2페이지(페이지당 5행) = 앞 5행(1페이지) 건너뜀 → `OFFSET 5 ROWS`, 다음 5행 → `FETCH NEXT 5 ROWS`.

동점 처리를 보장하려면 `WITH TIES` 사용.

```sql
SELECT employee_id, last_name, salary
FROM   employees
ORDER BY salary DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS WITH TIES;
```

---

**[48번] 정답: ①**

`LEFT JOIN`은 왼쪽 테이블(`employees`)의 모든 행을 유지한다. `departments`에 일치하는 행이 없으면 NULL로 채운다. 따라서 CTE `emp_dept`의 행 수 = `employees` 테이블의 행 수(107명).

---

**[49번] 정답: ②**

Oracle 전통 계층 쿼리: `CONNECT BY PRIOR employee_id = manager_id` (또는 역방향). Oracle 11g+에서는 재귀 CTE도 지원하지만 `WITH RECURSIVE` 키워드 없이 사용한다.

```sql
-- 전통 방식
SELECT employee_id, last_name, LEVEL
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

---

**[50번] 정답: ④**

모든 최적화 방법이 유효하다:

- **가**: `departments.department_id` 인덱스 → 스칼라 서브쿼리의 WHERE 조건 빠르게 조회
- **나**: 스칼라 서브쿼리 → LEFT JOIN 대체 → departments 반복 스캔 제거
- **다**: WHERE의 상관 서브쿼리(COUNT)를 CTE로 분리 → 재사용 및 Materialize 가능
- **라**: `manager_id` 인덱스 → `WHERE m.manager_id = e.employee_id` 조건 빠르게 처리

```sql
-- 최적화 예시: 모두 적용
WITH mgr_count AS (
    SELECT manager_id, COUNT(*) AS sub_cnt
    FROM   employees
    GROUP BY manager_id
    HAVING COUNT(*) > 3
)
SELECT e.employee_id, e.last_name, d.department_name
FROM   employees e
JOIN   mgr_count mc ON mc.manager_id = e.employee_id
LEFT JOIN departments d ON d.department_id = e.department_id;
```
