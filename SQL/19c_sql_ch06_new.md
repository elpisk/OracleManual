# Oracle Database 19c: SQL Workshop
## Chapter 6 — 그룹 함수를 사용한 집계 데이터 보고

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있습니다:

- 사용 가능한 그룹 함수를 식별한다
- 그룹 함수의 사용법을 설명한다
- GROUP BY 절을 사용하여 데이터를 그룹화한다
- HAVING 절을 사용하여 그룹화된 행을 포함하거나 제외한다

---

## 학습 목차

- 그룹 함수: 유형 및 구문
- AVG, SUM, MIN, MAX, COUNT 사용
- 그룹 함수에서 DISTINCT 키워드 사용
- 그룹 함수에서 NULL 값 처리
- 행 그룹화: GROUP BY 절
- HAVING 절
- 그룹 함수 중첩

---

## 그룹 함수란?

그룹 함수는 행의 집합(그룹)에 대해 연산하여 **그룹당 하나의 결과**를 반환한다.

```sql
-- 전체 EMPLOYEES 테이블의 최대 급여 (1개 결과)
SELECT MAX(salary)
FROM   employees;
```

### 단일행 함수 vs 그룹 함수

| 구분 | 단일행 함수 | 그룹 함수 |
|------|------------|----------|
| 입력 | 각 행 | 행의 집합(그룹) |
| 출력 | 행마다 1개 | 그룹마다 1개 |
| 예시 | UPPER, ROUND, TO_CHAR | COUNT, AVG, SUM |

---

## 그룹 함수 종류

| 함수 | 설명 |
|------|------|
| `AVG(col)` | 평균값 (NULL 무시) |
| `COUNT(*)` | 전체 행 수 (NULL 포함) |
| `COUNT(col)` | 비-NULL 행 수 |
| `MAX(col)` | 최대값 |
| `MIN(col)` | 최소값 |
| `SUM(col)` | 합계 |
| `LISTAGG(col, delim)` | 그룹 내 값을 문자열로 연결 |
| `STDDEV(col)` | 표준편차 |
| `VARIANCE(col)` | 분산 |

---

## 그룹 함수 기본 구문

```sql
SELECT   group_function(column), ...
FROM     table
[WHERE   condition];
```

---

## AVG, SUM, MAX, MIN 함수

숫자 데이터에 AVG와 SUM을 사용할 수 있다.

```sql
-- 직무에 'REP'가 포함된 사원들의 급여 통계
SELECT AVG(salary), MAX(salary),
       MIN(salary), SUM(salary)
FROM   employees
WHERE  job_id LIKE '%REP%';
```

MIN과 MAX는 숫자, 문자, 날짜 데이터 타입 모두 사용 가능하다.

```sql
-- 알파벳 순서 첫/마지막 이름, 최초/최근 입사일
SELECT MIN(last_name), MAX(last_name),
       MIN(hire_date), MAX(hire_date)
FROM   employees;
```

---

## COUNT 함수

```sql
-- COUNT(*): 전체 행 수 반환 (NULL 포함)
SELECT COUNT(*)
FROM   employees
WHERE  department_id = 50;
-- 결과: 45

-- COUNT(expr): NULL이 아닌 행 수만 반환
SELECT COUNT(commission_pct)
FROM   employees
WHERE  department_id = 50;
-- 결과: 5 (부서 50에서 commission_pct가 NULL이 아닌 사원 수)
```

---

## DISTINCT 키워드

`COUNT(DISTINCT expr)`: 중복을 제외한 비-NULL 값의 수를 반환한다.

```sql
-- EMPLOYEES 테이블에서 서로 다른 department_id의 수
SELECT COUNT(DISTINCT department_id)
FROM   employees;
-- 결과: 11 (NULL이 아닌 고유 부서 수)
```

---

## 그룹 함수와 NULL 값

그룹 함수는 열의 **NULL 값을 자동으로 무시**한다.

```sql
-- NULL을 무시하는 AVG (commission_pct가 있는 35명만 대상)
SELECT AVG(commission_pct)
FROM   employees;
-- 결과: 약 0.223... (35명의 평균)

-- NVL로 NULL을 0으로 대체하면 107명 전체 평균 계산
SELECT AVG(NVL(commission_pct, 0))
FROM   employees;
-- 결과: 약 0.073... (107명 기준 평균 — 훨씬 낮음)
```

> **중요:** `AVG(commission_pct)`와 `AVG(NVL(commission_pct, 0))`는 다른 결과를 반환한다.  
> 비즈니스 요구사항에 따라 어떤 방식을 사용할지 선택해야 한다.

---

## GROUP BY 절

행 그룹을 나누어 각 그룹에 대해 하나의 결과를 반환한다.

```sql
SELECT   column, group_function(column)
FROM     table
[WHERE   condition]
[GROUP BY group_by_expression]
[ORDER BY column];
```

### GROUP BY 사용 규칙

> **핵심 규칙:** SELECT 목록에서 그룹 함수가 아닌 모든 열은 반드시 **GROUP BY 절에 포함**해야 한다.

```sql
-- 부서별 평균 급여
SELECT   department_id, AVG(salary)
FROM     employees
GROUP BY department_id;
```

---

## 다중 열 GROUP BY

```sql
-- 부서 40 초과의 부서에서 직무별 급여 합계
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id > 40
GROUP BY department_id, job_id
ORDER BY department_id;
```

---

## 잘못된 쿼리 패턴

### 오류 1: GROUP BY 없이 그룹 함수와 일반 열 혼용

```sql
-- 오류: department_id가 GROUP BY에 없음
SELECT department_id, COUNT(last_name)
FROM   employees;
-- ORA-00937: not a single-group group function
```

### 오류 2: SELECT 절의 열이 GROUP BY에 없음

```sql
-- 오류: job_id가 GROUP BY에 없음
SELECT department_id, job_id, COUNT(last_name)
FROM   employees
GROUP BY department_id;
-- ORA-00979: not a GROUP BY expression
```

### 오류 3: WHERE 절에 그룹 함수 사용 시도

```sql
-- 오류: WHERE 절에서 그룹 함수 사용 불가
SELECT   department_id, AVG(salary)
FROM     employees
WHERE    AVG(salary) > 8000    -- 오류!
GROUP BY department_id;
-- ORA-00934: group function is not allowed here
```

> 그룹 함수로 그룹을 제한하려면 **HAVING 절**을 사용해야 한다.

---

## HAVING 절

HAVING 절을 사용하여 그룹 함수 기준으로 그룹을 필터링한다.

### 처리 순서

1. 행을 그룹화한다 (GROUP BY)
2. 그룹 함수를 적용한다
3. HAVING 조건과 일치하는 그룹만 표시한다

```sql
SELECT    column, group_function
FROM      table
[WHERE    condition]
[GROUP BY group_by_expression]
[HAVING   group_condition]
[ORDER BY column];
```

---

## HAVING 절 예제

```sql
-- 최대 급여가 10,000 초과인 부서
SELECT   department_id, MAX(salary)
FROM     employees
GROUP BY department_id
HAVING   MAX(salary) > 10000;

-- 'REP'가 없는 직무 중 급여 합계가 13,000 초과인 직무
SELECT   job_id, SUM(salary) AS PAYROLL
FROM     employees
WHERE    job_id NOT LIKE '%REP%'
GROUP BY job_id
HAVING   SUM(salary) > 13000
ORDER BY SUM(salary);
```

---

## WHERE vs HAVING 비교

| 항목 | WHERE | HAVING |
|------|-------|--------|
| 적용 대상 | 개별 행 | 그룹 |
| 그룹 함수 사용 | 불가 | 가능 |
| 처리 시점 | GROUP BY 이전 | GROUP BY 이후 |
| 예시 | `WHERE salary > 5000` | `HAVING AVG(salary) > 5000` |

---

## SQL 처리 순서 (SELECT 문)

```
FROM     → 테이블 지정
WHERE    → 행 필터링 (그룹 함수 사용 불가)
GROUP BY → 그룹화
HAVING   → 그룹 필터링 (그룹 함수 사용 가능)
SELECT   → 열 선택 및 표현식 계산
ORDER BY → 정렬
```

---

## 그룹 함수 중첩

Oracle에서 그룹 함수는 **2단계까지** 중첩할 수 있다.

```sql
-- 부서별 평균 급여 중 최대값
SELECT   MAX(AVG(salary))
FROM     employees
GROUP BY department_id;
```

> 이 쿼리는:
> 1. `AVG(salary)`: 각 부서의 평균 급여 계산
> 2. `MAX(...)`: 그 중 최대값 1개 반환

---

## LISTAGG 함수 (Oracle)

그룹 내의 값을 지정한 구분자로 연결하여 하나의 문자열로 반환한다.

```sql
-- 부서 20의 사원 이름을 쉼표로 연결
SELECT department_id,
       LISTAGG(last_name, ', ')
           WITHIN GROUP (ORDER BY last_name) AS employees_list
FROM   employees
WHERE  department_id = 20
GROUP BY department_id;
-- 결과: 20 | Fay, Hartstein
```

---

## 단원 요약

이 단원에서 배운 내용:

| 내용 | 설명 |
|------|------|
| **그룹 함수** | COUNT, AVG, SUM, MIN, MAX — 그룹당 1개 결과 |
| **NULL 처리** | 그룹 함수는 NULL 자동 무시, NVL로 포함 가능 |
| **GROUP BY** | SELECT의 비-집계 열은 반드시 GROUP BY에 포함 |
| **HAVING** | 그룹 함수 기준 그룹 필터링, WHERE로는 불가 |
| **중첩** | MAX(AVG(salary)) — 2단계까지 |

전체 SELECT 구문:
```sql
SELECT    column, group_function(column)
FROM      table
[WHERE    condition]
[GROUP BY group_by_expression]
[HAVING   group_condition]
[ORDER BY column];
```

---

## Practice 6: 개요

이 실습에서 다루는 내용:

- 그룹 함수를 사용하는 쿼리 작성
- 하나 이상의 결과를 얻기 위해 행 그룹화
- HAVING 절을 사용하여 그룹 제한
