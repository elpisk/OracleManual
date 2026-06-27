# Oracle Database 19c: SQL Workshop
## Chapter 8 — 서브쿼리를 활용한 쿼리 작성

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있습니다:

- 서브쿼리를 정의한다
- 서브쿼리가 해결할 수 있는 문제 유형을 설명한다
- 서브쿼리의 유형을 식별한다
- 단일행·다중행·다중열 서브쿼리를 작성한다

---

## 학습 목차

- 서브쿼리: 유형, 구문, 사용 지침
- 단일행 서브쿼리:
  - 서브쿼리에서 그룹 함수 사용
  - HAVING 절과 서브쿼리
- 다중행 서브쿼리: IN / ANY / ALL 연산자
- 다중열 서브쿼리
- 서브쿼리에서 NULL 값 처리

---

## 서브쿼리란?

**서브쿼리(Subquery)**: 다른 SELECT 문(메인 쿼리) 안에 포함된 SELECT 문.  
**내부 쿼리(Inner Query)** 또는 **중첩 쿼리(Nested Query)**라고도 한다.

### 서브쿼리가 필요한 경우

값을 모르는 조건이 있을 때 서브쿼리를 사용한다.

**예시:** "Davies보다 늦게 입사한 사원을 모두 조회하라"  
→ Davies의 입사일을 먼저 조회한 후, 그 날짜 이후 입사한 사원을 찾아야 한다.

---

## 서브쿼리 구문

```sql
SELECT select_list
FROM   table
WHERE  expr operator
       (SELECT select_list
        FROM   table);
```

- **내부 쿼리(서브쿼리)**: 메인 쿼리보다 **먼저 실행**된다
- 서브쿼리의 결과가 메인 쿼리의 조건에 사용된다

```sql
-- 예시: Davies보다 늦게 입사한 사원 조회
SELECT last_name, hire_date
FROM   employees
WHERE  hire_date > (SELECT hire_date
                    FROM   employees
                    WHERE  last_name = 'Davies');
```

---

## 서브쿼리 사용 규칙 및 지침

1. **서브쿼리는 괄호로 감싼다**
2. 가독성을 위해 비교 조건의 **오른쪽**에 서브쿼리를 배치한다  
   (단, 비교 연산자의 양쪽 모두 가능)
3. **단일행 서브쿼리**에는 단일행 비교 연산자(`=`, `>`, `<`, `>=`, `<=`, `<>`)를 사용한다
4. **다중행 서브쿼리**에는 다중행 비교 연산자(`IN`, `ANY`, `ALL`)를 사용한다

---

## 서브쿼리 유형

| 유형 | 반환 행 수 | 사용 연산자 |
|------|-----------|------------|
| 단일행 서브쿼리 | 1행 | `=`, `>`, `<`, `>=`, `<=`, `<>` |
| 다중행 서브쿼리 | 여러 행 | `IN`, `ANY`, `ALL` |
| 다중열 서브쿼리 | 여러 열 | `IN` (다중 열 비교) |

---

## 단일행 서브쿼리

단 하나의 행을 반환하는 서브쿼리. 단일행 비교 연산자를 사용한다.

```sql
-- Taylor와 같은 직무이면서 Taylor보다 급여가 높은 사원 조회
SELECT last_name, job_id, salary
FROM   employees
WHERE  job_id =  (SELECT job_id
                  FROM   employees
                  WHERE  last_name = 'Taylor')
AND    salary > (SELECT salary
                 FROM   employees
                 WHERE  last_name = 'Taylor');
```

---

## 서브쿼리에서 그룹 함수 사용

그룹 함수는 항상 단일 값을 반환하므로 단일행 서브쿼리로 사용할 수 있다.

```sql
-- 최소 급여를 받는 사원 조회
SELECT last_name, job_id, salary
FROM   employees
WHERE  salary = (SELECT MIN(salary)
                 FROM   employees);
```

---

## HAVING 절과 서브쿼리

서브쿼리는 HAVING 절에서도 사용할 수 있다.  
데이터베이스 서버는 서브쿼리를 먼저 실행한 후 결과를 HAVING 절에 반환한다.

```sql
-- 부서 50의 최소 급여보다 최소 급여가 높은 부서 조회
SELECT   department_id, MIN(salary)
FROM     employees
GROUP BY department_id
HAVING   MIN(salary) > (SELECT MIN(salary)
                        FROM   employees
                        WHERE  department_id = 50);
```

---

## 단일행 서브쿼리 오류 유형

### 오류 1: 단일행 연산자에 다중행 서브쿼리 사용

```sql
-- 오류: = 연산자에 여러 행을 반환하는 서브쿼리 사용
SELECT employee_id, last_name
FROM   employees
WHERE  salary = (SELECT   MIN(salary)    -- 여러 부서 최소 급여를 여러 행 반환
                 FROM     employees
                 GROUP BY department_id);
-- ORA-01427: single-row subquery returns more than one row
```

**해결:** `=` → `IN` 으로 변경 (다중행 연산자 사용)

### 오류 2: 서브쿼리 결과가 없음 (빈 결과)

```sql
-- 서브쿼리가 행을 반환하지 않으면 메인 쿼리도 결과 없음 (오류 아님)
SELECT last_name, job_id
FROM   employees
WHERE  job_id = (SELECT job_id
                 FROM   jobs
                 WHERE  job_title = 'Architect');
-- 'Architect' 직무가 없으므로 서브쿼리 결과 없음 → 메인 쿼리도 0행
```

---

## 다중행 서브쿼리

여러 행을 반환하는 서브쿼리. 반드시 다중행 연산자와 함께 사용한다.

| 연산자 | 의미 |
|--------|------|
| `IN` | 목록의 임의 값과 같음 |
| `ANY` | 서브쿼리 결과의 **하나라도** 조건을 만족하면 TRUE |
| `ALL` | 서브쿼리 결과의 **모두**에 대해 조건이 TRUE여야 함 |

---

## ANY 연산자 사용

```sql
-- IT_PROG 중 어떤 사원의 급여보다 낮은 사원 조회 (job_id <> 'IT_PROG')
-- IT_PROG 급여 목록: 9000, 6000, 4200
-- < ANY → 9000 미만인 사원 (가장 큰 값보다 작으면 됨)
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary < ANY (SELECT salary
                     FROM   employees
                     WHERE  job_id = 'IT_PROG')
AND    job_id <> 'IT_PROG';
```

> **`< ANY` 의미:** 서브쿼리 결과 중 하나라도 크면 조건 만족  
> → `< MAX(서브쿼리 결과)` 와 동일

---

## ALL 연산자 사용

```sql
-- IT_PROG의 모든 사원의 급여보다 낮은 사원 조회
-- IT_PROG 급여 목록: 9000, 6000, 4200
-- < ALL → 4200 미만인 사원 (가장 작은 값보다 작아야 함)
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary < ALL (SELECT salary
                     FROM   employees
                     WHERE  job_id = 'IT_PROG')
AND    job_id <> 'IT_PROG';
```

> **`< ALL` 의미:** 서브쿼리 결과 모두보다 작아야 함  
> → `< MIN(서브쿼리 결과)` 와 동일

---

## ANY vs ALL 비교

| 연산자 | 동작 | 동등 표현 |
|--------|------|----------|
| `< ANY` | 하나라도 크면 OK | `< MAX(...)` |
| `> ANY` | 하나라도 작으면 OK | `> MIN(...)` |
| `= ANY` | 하나라도 같으면 OK | `IN (...)` |
| `< ALL` | 모두보다 작아야 OK | `< MIN(...)` |
| `> ALL` | 모두보다 커야 OK | `> MAX(...)` |
| `<> ALL` | 모두와 달라야 OK | `NOT IN (...)` |

---

## 다중열 서브쿼리

서브쿼리가 여러 열을 반환하고, 메인 쿼리에서 여러 열을 동시에 비교한다.

```sql
-- 구문
SELECT column, column, ...
FROM   table
WHERE  (column1, column2, ...) IN
       (SELECT column1, column2, ...
        FROM   table
        WHERE  condition);
```

```sql
-- 각 부서에서 최소 급여를 받는 사원 조회
SELECT first_name, department_id, salary
FROM   employees
WHERE  (salary, department_id) IN
       (SELECT MIN(salary), department_id
        FROM   employees
        GROUP BY department_id)
ORDER BY department_id;
```

> 다중열 서브쿼리를 사용하면 여러 조건을 하나의 WHERE 절로 처리할 수 있다.

---

## 서브쿼리에서 NULL 값 주의

**NOT IN과 NULL**: NOT IN 연산자를 다중행 서브쿼리와 함께 사용할 때,  
서브쿼리 결과에 NULL이 하나라도 포함되면 **메인 쿼리는 아무 행도 반환하지 않는다**.

```sql
-- 문제: manager_id 목록에 NULL이 포함되어 결과 없음
SELECT emp.last_name
FROM   employees emp
WHERE  emp.employee_id NOT IN
       (SELECT mgr.manager_id
        FROM   employees mgr);
-- 결과: 0행 (manager_id가 NULL인 행이 있어서)
```

**해결책:** WHERE 절에 NULL 제외 조건 추가

```sql
SELECT emp.last_name
FROM   employees emp
WHERE  emp.employee_id NOT IN
       (SELECT mgr.manager_id
        FROM   employees mgr
        WHERE  mgr.manager_id IS NOT NULL);
```

---

## 서브쿼리 위치

서브쿼리는 SELECT 문의 다양한 절에 사용할 수 있다.

| 위치 | 예시 |
|------|------|
| WHERE 절 | `WHERE salary > (SELECT ...)` |
| HAVING 절 | `HAVING MIN(salary) > (SELECT ...)` |
| FROM 절 (인라인 뷰) | `FROM (SELECT ...) alias` |
| SELECT 절 (스칼라 서브쿼리) | `SELECT (SELECT ...), col FROM ...` |

---

## 단원 요약

| 내용 | 설명 |
|------|------|
| **서브쿼리** | 메인 쿼리 내에 포함된 SELECT, 먼저 실행됨 |
| **단일행** | 1행 반환, `=` `>` `<` `>=` `<=` `<>` 사용 |
| **다중행** | 여러 행 반환, `IN` `ANY` `ALL` 사용 |
| **다중열** | 여러 열 반환, `(col1, col2) IN (서브쿼리)` |
| **그룹 함수** | 서브쿼리에서 사용 가능 (항상 단일 값 반환) |
| **HAVING + 서브쿼리** | 그룹 조건에 서브쿼리 결과 활용 |
| **NOT IN + NULL** | 결과에 NULL 포함 시 메인 쿼리 0행 반환 — `IS NOT NULL` 필터 추가 |

---

## Practice 8: 개요

이 실습에서 다루는 내용:

- 알 수 없는 기준으로 값을 조회하는 서브쿼리 작성
- 하나의 데이터 집합에는 있지만 다른 집합에는 없는 값을 찾는 서브쿼리 사용
