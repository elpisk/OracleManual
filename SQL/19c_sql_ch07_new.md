# Oracle Database 19c: SQL Workshop
## Chapter 7 — 다중 테이블 데이터 조회: JOIN 사용

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있습니다:

- 등가 조인(equijoin)과 비등가 조인(nonequijoin)을 사용하여 둘 이상의 테이블에서 데이터를 조회하는 SELECT 문을 작성한다
- 셀프 조인(self-join)을 사용하여 테이블을 자기 자신에 조인한다
- OUTER JOIN을 사용하여 일반적으로 조인 조건을 충족하지 않는 데이터를 조회한다
- 두 개 이상의 테이블 모든 행의 카테시안 곱(Cartesian product)을 생성한다

---

## 학습 목차

- JOIN 유형과 구문
- Natural Join
- USING 절을 사용한 조인
- ON 절을 사용한 조인
- Self-Join
- Nonequijoin (비등가 조인)
- OUTER JOIN: LEFT / RIGHT / FULL
- Cartesian Product (CROSS JOIN)

---

## JOIN이 필요한 이유?

실무 데이터는 여러 테이블에 분산 저장된다. 예를 들어 사원 정보는 EMPLOYEES에, 직무 제목은 JOBS에 따로 보관된다.  
두 테이블의 데이터를 하나의 보고서로 결합하려면 **JOIN**을 사용해야 한다.

```sql
-- 테이블 구조 예시
EMPLOYEES: employee_id, first_name, last_name, job_id, department_id, salary ...
JOBS:       job_id, job_title, min_salary, max_salary
```

---

## JOIN 구문 (ANSI SQL 표준)

```sql
SELECT table1.column, table2.column
FROM   table1
[NATURAL JOIN table2]
  |
[JOIN table2 USING (column_name)]
  |
[JOIN table2 ON (table1.col = table2.col)]
  |
[LEFT|RIGHT|FULL OUTER JOIN table2 ON (table1.col = table2.col)]
  |
[CROSS JOIN table2];
```

---

## JOIN 종류

| JOIN 유형 | 구문 | 설명 |
|-----------|------|------|
| Natural Join | `NATURAL JOIN` | 같은 이름의 모든 열로 자동 조인 |
| USING 절 | `JOIN ... USING (col)` | 지정한 열로 등가 조인 |
| ON 절 | `JOIN ... ON (조건)` | 임의 조건으로 조인 |
| Self-Join | `JOIN ... ON (t1.col = t2.col)` | 같은 테이블을 자기 자신에 조인 |
| Nonequijoin | `JOIN ... ON (BETWEEN)` | 등호 이외의 조건으로 조인 |
| LEFT OUTER JOIN | `LEFT OUTER JOIN` | 왼쪽 테이블의 불일치 행 포함 |
| RIGHT OUTER JOIN | `RIGHT OUTER JOIN` | 오른쪽 테이블의 불일치 행 포함 |
| FULL OUTER JOIN | `FULL OUTER JOIN` | 양쪽 불일치 행 모두 포함 |
| CROSS JOIN | `CROSS JOIN` | 카테시안 곱 |

---

## Natural Join (자연 조인)

### 특징

- 두 테이블에서 **이름이 같은 모든 열**을 기준으로 자동으로 등가 조인을 수행한다
- 이름이 같지만 데이터 타입이 다른 열이 있으면 오류가 발생한다
- 조인에 사용된 열에 테이블 별칭(prefix)을 붙이면 오류 발생

```sql
-- employees와 jobs를 공통 열(job_id)로 자동 조인
SELECT employee_id, first_name, job_id, job_title
FROM   employees
NATURAL JOIN jobs;
```

> **주의:** NATURAL JOIN은 의도하지 않은 열까지 조인 기준이 될 수 있으므로,  
> 명시적 조건이 필요할 때는 USING 또는 ON 절을 사용하는 것이 안전하다.

---

## USING 절을 사용한 조인

### USING 절이 필요한 경우

- 여러 열이 같은 이름을 가지지만, 하나의 열로만 조인하고 싶을 때
- 데이터 타입이 일치하는 특정 열로만 조인하고 싶을 때

```sql
-- department_id 열 하나로 등가 조인
SELECT employee_id, last_name, location_id, department_id
FROM   employees
JOIN   departments
USING  (department_id);
```

### USING 절 주의사항

- USING 절에 명시된 열에는 테이블 별칭(e., d.)을 붙이면 오류 발생
- WHERE 절에서도 해당 열에 접두사(prefix) 사용 불가

```sql
-- 올바른 예 — USING 열에 별칭 없이 사용
SELECT l.city, d.department_name
FROM   locations l
JOIN   departments d
USING  (location_id)
WHERE  location_id = 1400;   -- 접두사 없이 사용
```

---

## ON 절을 사용한 조인

### ON 절의 장점

- 이름이 다른 열을 조인 기준으로 지정할 수 있다
- 조인 조건과 검색 조건을 분리하여 코드 가독성이 높다
- 임의의 조건(등호 외에도)을 사용할 수 있다

```sql
-- ON 절로 조인 조건 명시
SELECT e.employee_id, e.last_name, e.department_id,
       d.department_id, d.location_id
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id);
```

### 3방향 조인 (Three-Way Join)

세 개 이상의 테이블을 연속 JOIN으로 연결한다.

```sql
-- employees → departments → locations 3방향 조인
SELECT employee_id, city, department_name
FROM   employees e
JOIN   departments d
ON     d.department_id = e.department_id
JOIN   locations l
ON     d.location_id = l.location_id;
```

### 추가 조건 적용

AND 또는 WHERE 절로 조인 이외의 필터 조건을 추가한다.

```sql
-- 방법 1: AND 절 사용
SELECT e.employee_id, e.last_name, e.department_id,
       d.department_id, d.location_id
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id)
AND    e.manager_id = 149;

-- 방법 2: WHERE 절 사용 (동일한 결과)
SELECT e.employee_id, e.last_name, e.department_id,
       d.department_id, d.location_id
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id)
WHERE  e.manager_id = 149;
```

---

## Self-Join (셀프 조인)

동일한 테이블을 두 번 참조하여 같은 테이블 내의 행끼리 조인한다.  
EMPLOYEES 테이블에서 사원의 관리자 이름을 조회할 때 대표적으로 사용된다.

```
EMPLOYEES (WORKER 역할)     EMPLOYEES (MANAGER 역할)
MANAGER_ID  ──────────────▶ EMPLOYEE_ID
```

```sql
-- 사원과 그 관리자 이름을 함께 조회
SELECT worker.last_name  AS emp,
       manager.last_name AS mgr
FROM   employees worker
JOIN   employees manager
ON     (worker.manager_id = manager.employee_id);
```

> King은 manager_id가 NULL이므로 결과에 나타나지 않는다 (INNER JOIN 특성).

---

## Nonequijoin (비등가 조인)

등호(=) 이외의 조건으로 조인한다.  
대표 예시: 급여 범위로 등급을 조회할 때 `BETWEEN ... AND ...` 사용

```
JOB_GRADES 테이블:
GRADE_LEVEL | LOWEST_SAL | HIGHEST_SAL
------------+------------+------------
A           |       1000 |        2999
B           |       3000 |        5999
C           |       6000 |        9999
D           |      10000 |       14999
E           |      15000 |       24999
```

```sql
-- 사원 급여에 해당하는 급여 등급 조회
SELECT e.last_name, e.salary, j.grade_level
FROM   employees e
JOIN   job_grades j
ON     e.salary BETWEEN j.lowest_sal AND j.highest_sal;
```

---

## INNER JOIN vs OUTER JOIN

| 구분 | 설명 |
|------|------|
| **INNER JOIN** | 조인 조건을 만족하는 행만 반환 (기본값) |
| **LEFT OUTER JOIN** | 왼쪽 테이블의 모든 행 + 오른쪽 불일치 행은 NULL |
| **RIGHT OUTER JOIN** | 오른쪽 테이블의 모든 행 + 왼쪽 불일치 행은 NULL |
| **FULL OUTER JOIN** | 양쪽 테이블 모든 행 (불일치 시 해당 쪽 NULL) |

### INNER JOIN 예시 — 일치하는 행만

```sql
-- department_id가 일치하는 사원만 반환
-- department_id=NULL인 Grant 사원, 사원 없는 부서 190은 제외
SELECT e.last_name, e.department_id, d.department_name
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id);
```

---

## LEFT OUTER JOIN

왼쪽 테이블(employees)의 모든 행을 반환하고, 조인 조건을 만족하지 않는 오른쪽 열은 NULL로 채운다.

```sql
SELECT e.last_name, e.department_id, d.department_name
FROM   employees e
LEFT OUTER JOIN departments d
ON     (e.department_id = d.department_id);
-- Grant(department_id=NULL)도 결과에 포함, d.department_name = NULL
```

---

## RIGHT OUTER JOIN

오른쪽 테이블(departments)의 모든 행을 반환하고, 조인 조건을 만족하지 않는 왼쪽 열은 NULL로 채운다.

```sql
SELECT e.last_name, d.department_id, d.department_name
FROM   employees e
RIGHT OUTER JOIN departments d
ON     (e.department_id = d.department_id);
-- 사원이 없는 부서 190도 결과에 포함, e.last_name = NULL
```

---

## FULL OUTER JOIN

LEFT OUTER JOIN과 RIGHT OUTER JOIN의 결과를 모두 포함한다.  
양쪽 테이블에서 일치하지 않는 행도 모두 반환한다.

```sql
SELECT e.last_name, d.department_id, d.department_name
FROM   employees e
FULL OUTER JOIN departments d
ON     (e.department_id = d.department_id);
-- Grant(dept NULL) + 부서 190(사원 없음) 모두 포함
```

---

## Cartesian Product (카테시안 곱) — CROSS JOIN

- 한 테이블의 모든 행을 다른 테이블의 모든 행에 조인한다
- 결과 행 수 = 테이블1 행 수 × 테이블2 행 수
- 일반적으로 실수로 발생하며 의미 없는 데이터가 대부분이다

```sql
-- CROSS JOIN으로 명시적 카테시안 곱 생성
SELECT last_name, department_name
FROM   employees
CROSS JOIN departments;
-- 결과: 107 × 27 = 2,889행
```

> **주의:** ON/USING/NATURAL JOIN 없이 FROM 절에 두 테이블을 쉼표로 나열해도 카테시안 곱이 발생한다.  
> 항상 조인 조건을 명시해야 한다.

---

## 테이블 별칭(Alias) 사용 지침

| 상황 | 규칙 |
|------|------|
| ON 절 조인 | 열에 테이블 별칭(e., d.) 사용 가능 |
| USING 절 조인 | 조인에 사용된 열에 테이블 별칭 사용 불가 |
| NATURAL JOIN | 조인에 사용된 열에 테이블 별칭 사용 불가 |
| 모든 경우 | 별칭은 쿼리 전체에서 일관성 있게 사용 |

---

## 단원 요약

| 조인 유형 | 구문 키워드 | 주요 특징 |
|-----------|------------|----------|
| Natural Join | `NATURAL JOIN` | 동명 열 자동 조인, 별칭 금지 |
| USING | `JOIN ... USING (col)` | 특정 열 지정 등가 조인 |
| ON | `JOIN ... ON (조건)` | 임의 조건, 가독성 우수 |
| Self-Join | `JOIN ... ON (t1.col = t2.col)` | 자기 참조, 별칭 필수 |
| Nonequijoin | `JOIN ... ON (BETWEEN)` | 범위 조건 조인 |
| LEFT OUTER | `LEFT OUTER JOIN` | 왼쪽 전체 반환 |
| RIGHT OUTER | `RIGHT OUTER JOIN` | 오른쪽 전체 반환 |
| FULL OUTER | `FULL OUTER JOIN` | 양쪽 전체 반환 |
| CROSS JOIN | `CROSS JOIN` | 카테시안 곱 |

---

## Practice 7: 개요

이 실습에서 다루는 내용:

- 등가 조인(equijoin)을 사용한 테이블 조인
- OUTER JOIN 및 Self-Join 수행
- 추가 조건 적용
