# Oracle Database 19c: SQL Workshop
## Chapter 9 — 집합 연산자 사용 (Using Set Operators)

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있다:
- 집합 연산자를 설명한다
- 집합 연산자를 사용하여 여러 쿼리를 단일 쿼리로 결합한다
- 반환되는 행의 순서를 제어한다

---

## 1. 집합 연산자란?

집합 연산자(Set Operator)는 두 개 이상의 SELECT 문의 결과를 하나로 합치는 연산자이다.  
수학의 집합 연산(합집합, 교집합, 차집합)과 동일한 개념이다.

| 연산자 | 의미 | 중복 처리 |
|--------|------|-----------|
| `UNION` | 두 쿼리의 합집합 | 중복 제거 |
| `UNION ALL` | 두 쿼리의 합집합 | 중복 포함 |
| `INTERSECT` | 두 쿼리의 교집합 | 중복 제거 |
| `MINUS` | 첫 쿼리 – 두 번째 쿼리 (차집합) | 중복 제거 |

---

## 2. 집합 연산자 사용 규칙

집합 연산자를 사용할 때 반드시 지켜야 하는 규칙이 있다.

1. **SELECT 목록의 열 개수가 일치**해야 한다
2. **대응되는 열의 데이터 타입이 호환**되어야 한다 (첫 번째 쿼리의 타입이 기준)
3. **괄호**를 사용하여 실행 순서를 변경할 수 있다
4. **ORDER BY 절**은 복합 쿼리 맨 끝에 한 번만 사용할 수 있다

### Oracle Server의 집합 연산자 동작 방식

- UNION ALL을 제외한 나머지 연산자는 **중복 행을 자동으로 제거**한다
- 결과의 **열 이름은 첫 번째 SELECT 쿼리**의 열 이름을 따른다
- UNION ALL을 제외하면 기본적으로 **첫 번째 열 기준 오름차순 정렬**된다

---

## 3. 이 단원에서 사용하는 테이블

- `employees`: 현재 재직 중인 사원 정보
- `retired_employees`: 과거에 재직했던 사원 정보 (교재용 가상 테이블)

> **참고:** `retired_employees`는 교재 예제를 위한 가상 테이블로, 실제 HR 스키마에는 존재하지 않는다.  
> 실습에서는 `JOB_HISTORY` 테이블을 활용하여 유사한 집합 연산을 실습한다.

---

## 4. UNION 연산자

**정의:** 두 쿼리의 결과를 모두 반환하되, **중복 행을 제거**한다.

```
집합 A + 집합 B  →  A ∪ B  (겹치는 부분은 하나만)
```

### 구문

```sql
SELECT column1, column2, ...
FROM   table1
UNION
SELECT column1, column2, ...
FROM   table2;
```

### 예제 — 현재 및 퇴직 사원의 직무 목록 (각 직무 한 번씩)

```sql
SELECT job_id
FROM   employees
UNION
SELECT job_id
FROM   retired_employees;
```

> - 두 테이블에서 모두 `job_id`를 가져온다
> - 동일한 `job_id`는 한 번만 출력된다

### HR 스키마 실습 예제 — 현재 직무 + 이전 직무 목록

```sql
-- 현재 직무(EMPLOYEES)와 과거 직무(JOB_HISTORY)를 합쳐 고유 직무 목록 조회
SELECT job_id
FROM   employees
UNION
SELECT job_id
FROM   job_history
ORDER BY job_id;
```

---

## 5. UNION ALL 연산자

**정의:** 두 쿼리의 결과를 모두 반환하되, **중복 행도 포함**한다.

```
집합 A + 집합 B  →  A ∪ B  (겹치는 부분도 모두 포함)
```

### 구문

```sql
SELECT column1, column2, ...
FROM   table1
UNION ALL
SELECT column1, column2, ...
FROM   table2;
```

### 예제 — 현재 및 퇴직 사원의 직무/부서 목록 (중복 포함)

```sql
SELECT job_id, department_id
FROM   employees
UNION ALL
SELECT job_id, department_id
FROM   retired_employees
ORDER BY job_id;
```

> - UNION ALL은 중복 행을 제거하지 않는다
> - 같은 `(job_id, department_id)` 조합이 양쪽에 있으면 모두 출력

### UNION vs UNION ALL 비교

| 항목 | UNION | UNION ALL |
|------|-------|-----------|
| 중복 제거 | O | X |
| 정렬 | 기본 오름차순 | 정렬 없음 |
| 성능 | 중복 제거 연산 필요 | 더 빠름 |
| 사용 목적 | 고유 결과 | 전체 결과 (중복 포함) |

---

## 6. INTERSECT 연산자

**정의:** 두 쿼리에 **공통으로 존재하는 행**만 반환한다 (교집합).

```
집합 A ∩ 집합 B  →  A와 B 모두에 속하는 행
```

### 구문

```sql
SELECT column1, column2, ...
FROM   table1
INTERSECT
SELECT column1, column2, ...
FROM   table2;
```

### 예제 — 현재 및 퇴직 사원 공통 manager_id/department_id

```sql
SELECT  manager_id, department_id
FROM    employees
INTERSECT
SELECT  manager_id, department_id
FROM    retired_employees;
```

> - 두 테이블 모두에 존재하는 `(manager_id, department_id)` 조합만 반환

### HR 스키마 실습 예제

```sql
-- 현재 직무(EMPLOYEES)이면서 이전에도 동일 직무를 맡은 사원의 employee_id, job_id
SELECT employee_id, job_id
FROM   employees
INTERSECT
SELECT employee_id, job_id
FROM   job_history;
```

---

## 7. MINUS 연산자

**정의:** 첫 번째 쿼리 결과에서 두 번째 쿼리 결과에 있는 행을 **제거**한 나머지를 반환한다 (차집합).

```
집합 A - 집합 B  →  A에 있지만 B에는 없는 행
```

### 구문

```sql
SELECT column1, column2, ...
FROM   table1
MINUS
SELECT column1, column2, ...
FROM   table2;
```

### 예제 — 영업부에서 퇴직 사원을 관리한 적이 없는 manager_id/job_id

```sql
SELECT manager_id, job_id
FROM   employees
WHERE  department_id = 80
MINUS
SELECT manager_id, job_id
FROM   retired_employees
WHERE  department_id = 80;
```

> - 영업부(80) 현직 사원의 `(manager_id, job_id)` 에서
> - 영업부(80) 퇴직 사원의 `(manager_id, job_id)` 를 제거

### HR 스키마 실습 예제

```sql
-- 현재 재직 중이지만 JOB_HISTORY에 이력이 없는 사원 (처음부터 현직무)
SELECT employee_id
FROM   employees
MINUS
SELECT employee_id
FROM   job_history;
```

---

## 8. SELECT 문 열 개수/타입 일치시키기

두 SELECT 문의 열 개수나 데이터 타입이 다를 경우, 더미(dummy) 값으로 맞춰야 한다.

### Oracle — `TO_CHAR(NULL)` / `TO_DATE(NULL)` 사용

```sql
SELECT location_id, department_name "Department",
       TO_CHAR(NULL) "Warehouse location"
FROM   departments
UNION
SELECT location_id, TO_CHAR(NULL) "Department",
       state_province
FROM   locations;
```

> - `departments`에는 `state_province`가 없으므로 `TO_CHAR(NULL)`로 열 자리를 맞춤
> - `locations`에는 `department_name`이 없으므로 마찬가지로 처리

### 예제 — 직원 이름, 직무, 입사일 (현직/퇴직 통합)

```sql
SELECT  first_name, job_id, hire_date "HIRE_DATE"
FROM    employees
UNION
SELECT  first_name, job_id, TO_DATE(NULL) "HIRE_DATE"
FROM    retired_employees;
```

> - `retired_employees`에 `hire_date`가 없으면 `TO_DATE(NULL)`로 열 자리를 채움

---

## 9. ORDER BY 절 사용 규칙

집합 연산자에서 `ORDER BY`를 사용할 때 반드시 지켜야 하는 규칙이다.

1. **ORDER BY는 복합 쿼리 맨 끝에 한 번만** 사용할 수 있다
2. **개별 컴포넌트 쿼리에는 ORDER BY를 사용할 수 없다**
3. **ORDER BY는 첫 번째 SELECT 쿼리의 열만 인식**한다
4. 기본적으로 첫 번째 SELECT 쿼리의 첫 번째 열을 기준으로 오름차순 정렬한다
5. **열 위치 번호**(`ORDER BY 2`)로 정렬 기준을 지정할 수 있다

### 예제 — job_id 기준 정렬

```sql
SELECT employee_id, job_id
FROM   employees
UNION
SELECT employee_id, job_id
FROM   retired_employees
ORDER BY 2;        -- 두 번째 열(job_id) 기준 정렬
-- 또는
ORDER BY job_id;   -- 첫 번째 쿼리의 열 이름 사용
```

---

## 10. 집합 연산자 요약 비교표

| 연산자 | 포함 범위 | 중복 처리 | 정렬 |
|--------|-----------|-----------|------|
| UNION | A + B | 제거 | 기본 오름차순 |
| UNION ALL | A + B | 유지 | 없음 |
| INTERSECT | A ∩ B | 제거 | 기본 오름차순 |
| MINUS | A - B | 제거 | 기본 오름차순 |

---

## 단원 요약

| 항목 | 핵심 내용 |
|------|-----------|
| UNION | 중복 제거한 합집합 |
| UNION ALL | 중복 포함한 합집합 (가장 빠름) |
| INTERSECT | 두 쿼리 공통 행 (교집합) |
| MINUS | 첫 쿼리 전용 행 (차집합) |
| 열 일치 | 개수/타입 일치 필수, NULL 변환으로 맞춤 |
| ORDER BY | 복합 쿼리 끝에 한 번만, 첫 쿼리 열 기준 |
