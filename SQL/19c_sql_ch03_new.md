# Oracle Database 19c: SQL Workshop
## Chapter 3 — 데이터 제한 및 정렬

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있습니다:

- 쿼리로 검색되는 행을 제한한다
- 쿼리로 검색되는 행을 정렬한다

---

## 학습 목차

- WHERE 절을 사용한 행 제한
  - 비교 연산자: =, <=, BETWEEN, IN, LIKE, NULL 조건
  - 논리 조건: AND, OR, NOT 연산자
- 표현식의 연산자 우선순위
- ORDER BY 절을 사용한 행 정렬
- SQL 행 제한 절
- Oracle 대체 변수
- 변수에 값 할당

---

## WHERE 절로 행 제한

### 행 선택으로 행 제한

SELECT 문은 기본적으로 테이블의 모든 행을 반환한다.  
특정 행만 조회하려면 **WHERE 절**을 사용한다.

```sql
SELECT  *|{[DISTINCT] column [alias],...}
FROM    table
[WHERE  logical expression(s)];
```

- WHERE 절은 FROM 절 다음에 위치한다
- 논리 표현식이 TRUE인 행만 반환한다

---

## WHERE 절 사용

```sql
SELECT employee_id, last_name, job_id, department_id
FROM   employees
WHERE  department_id = 90;
```

결과: 부서 번호가 90인 사원만 조회 (King, Kochhar, De Haan)

---

## 문자 문자열과 날짜

- 문자 문자열과 날짜 값은 **단일 따옴표(`'`)**로 감싼다
- 문자 값은 **대소문자를 구분**한다
- 날짜 값은 **형식에 민감**하다
- Oracle의 기본 날짜 표시 형식: `DD-MON-RR`

```sql
-- 문자 조건 (대소문자 구분)
SELECT last_name, job_id, department_id
FROM   employees
WHERE  last_name = 'Whalen';

-- Oracle 날짜 형식
SELECT last_name, hire_date
FROM   employees
WHERE  hire_date = '17-OCT-11';
```

---

## 비교 연산자

| 연산자 | 의미 |
|--------|------|
| `=` | 같다 |
| `>` | 보다 크다 |
| `>=` | 보다 크거나 같다 |
| `<` | 보다 작다 |
| `<=` | 보다 작거나 같다 |
| `<>` | 같지 않다 |
| `BETWEEN...AND...` | 두 값 사이 (경계값 포함) |
| `IN(set)` | 목록의 값과 일치 |
| `LIKE` | 문자 패턴과 일치 |
| `IS NULL` | NULL 값이다 |

```sql
-- 월급이 3000 이하인 사원
SELECT last_name, salary
FROM   employees
WHERE  salary <= 3000;

-- 성이 'Abel'인 사원
SELECT *
FROM   employees
WHERE  last_name = 'Abel';
```

---

## BETWEEN...AND 연산자

BETWEEN 연산자로 값의 범위를 기반으로 행을 조회할 수 있다.  
**경계값 양쪽 모두 포함**된다.

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary BETWEEN 2500 AND 3500;
```

- 하한값(lower limit): 2500
- 상한값(upper limit): 3500

---

## IN 연산자

IN 연산자로 목록의 값 중 하나와 일치하는 행을 조회한다.

```sql
SELECT employee_id, last_name, salary, manager_id
FROM   employees
WHERE  manager_id IN (100, 101, 201);
```

---

## LIKE 연산자 — 패턴 일치

LIKE 연산자로 유효한 문자열 패턴에 대한 와일드카드 검색을 수행할 수 있다.

| 와일드카드 | 의미 |
|-----------|------|
| `%` | 0개 이상의 문자 |
| `_` | 1개의 문자 |

```sql
-- 이름이 'S'로 시작하는 사원
SELECT first_name
FROM   employees
WHERE  first_name LIKE 'S%';
```

### 와일드카드 조합

두 와일드카드를 리터럴 문자와 함께 결합할 수 있다:

```sql
-- 성의 두 번째 문자가 'o'인 사원
SELECT last_name
FROM   employees
WHERE  last_name LIKE '_o%';
```

- `ESCAPE` 식별자로 `%`와 `_` 문자 자체를 검색할 수 있다:

```sql
SELECT last_name
FROM   employees
WHERE  last_name LIKE 'SA\_R%' ESCAPE '\';
```

---

## IS NULL 조건

IS NULL 연산자로 열의 NULL 값을 테스트한다.

```sql
-- 관리자가 없는 사원 (최상위 관리자)
SELECT last_name, manager_id
FROM   employees
WHERE  manager_id IS NULL;
```

결과: Steven King (manager_id가 NULL — 회사의 최상위 직급)

---

## 논리 연산자

논리 연산자로 여러 조건을 기반으로 결과를 필터링하거나 결과를 반전시킬 수 있다.

| 연산자 | 의미 |
|--------|------|
| `AND` | 두 조건이 모두 TRUE이면 TRUE 반환 |
| `OR` | 두 조건 중 하나라도 TRUE이면 TRUE 반환 |
| `NOT` | 조건이 FALSE이면 TRUE 반환 |

---

## AND 연산자

AND는 두 조건이 모두 TRUE이어야 한다:

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary >= 10000
AND    job_id LIKE '%MAN%';
```

결과: 월급이 10,000 이상이고 직무 코드에 'MAN'이 포함된 사원

---

## OR 연산자

OR는 두 조건 중 하나라도 TRUE이면 된다:

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary >= 10000
OR     job_id LIKE '%MAN%';
```

결과: 월급이 10,000 이상이거나 직무 코드에 'MAN'이 포함된 사원

---

## NOT 연산자

NOT은 조건을 부정한다:

```sql
SELECT last_name, job_id
FROM   employees
WHERE  job_id NOT IN ('IT_PROG', 'ST_CLERK', 'SA_REP');
```

결과: IT_PROG, ST_CLERK, SA_REP를 제외한 모든 직무의 사원

---

## 연산자 우선순위

| 순서 | 연산자 |
|------|--------|
| 1 | 산술 연산자 |
| 2 | 연결 연산자 |
| 3 | 비교 조건 |
| 4 | IS [NOT] NULL, LIKE, [NOT] IN |
| 5 | [NOT] BETWEEN |
| 6 | 같지 않다 (<>) |
| 7 | NOT 논리 연산자 |
| 8 | AND 논리 연산자 |
| 9 | OR 논리 연산자 |

**괄호를 사용하여 우선순위를 재정의할 수 있다.**

### 우선순위 예제

```sql
-- (1) AND가 OR보다 먼저 실행됨
-- 부서=80이고 급여>10000인 사원, 또는 부서=60인 사원
SELECT last_name, department_id, salary
FROM   employees
WHERE  department_id = 60
OR     department_id = 80
AND    salary > 10000;

-- (2) 괄호로 OR를 먼저 실행
-- (부서=60 또는 부서=80)이고 급여>10000인 사원
SELECT last_name, department_id, salary
FROM   employees
WHERE  (department_id = 60
OR      department_id = 80)
AND     salary > 10000;
```

---

## ORDER BY 절

ORDER BY 절로 검색된 행을 정렬할 수 있다:

- `ASC`: 오름차순 정렬 (기본값)
- `DESC`: 내림차순 정렬

```sql
-- 입사일 기준 오름차순 정렬 (기본값)
SELECT last_name, job_id, department_id, hire_date
FROM   employees
ORDER BY hire_date;
```

### 정렬 옵션

```sql
-- 1. 내림차순 정렬
SELECT last_name, job_id, department_id, hire_date
FROM   employees
ORDER BY department_id DESC;

-- 2. 열 별칭으로 정렬
SELECT employee_id, last_name, salary * 12 annsal
FROM   employees
ORDER BY annsal;

-- 3. 열의 숫자 위치로 정렬 (3번째 열 기준)
SELECT last_name, job_id, department_id, hire_date
FROM   employees
ORDER BY 3;

-- 4. 여러 열로 정렬 (부서 오름차순, 급여 내림차순)
SELECT last_name, department_id, salary
FROM   employees
ORDER BY department_id, salary DESC;
```

---

## SQL 행 제한 절 (Oracle)

행 제한 절을 사용하여 쿼리가 반환하는 행 수를 제한할 수 있다.  
**Top-N 보고서** 구현에 활용된다.

### 구문 (Oracle)

```sql
SELECT   ...
FROM     ...
[WHERE   ...]
[ORDER BY ...]
[OFFSET  offset { ROW | ROWS }]
[FETCH { FIRST | NEXT } [{ row_count | percent PERCENT }]
 { ROW | ROWS } { ONLY | WITH TIES }]
```

### 예제

```sql
-- 상위 5명의 사원 (employee_id 오름차순)
SELECT employee_id, first_name
FROM   employees
ORDER BY employee_id
FETCH FIRST 5 ROWS ONLY;

-- 6번째부터 5명 건너뛰기 (OFFSET)
SELECT employee_id, first_name
FROM   employees
ORDER BY employee_id
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
```

---

## Oracle 대체 변수 (Substitution Variables)

대체 변수를 사용하면 다양한 값으로 유연하게 쿼리를 실행할 수 있다.

- 단일 앰퍼샌드(`&`): 실행할 때마다 값 입력 요청
- 이중 앰퍼샌드(`&&`): 처음 한 번 값을 저장하고 재사용

### 단일 앰퍼샌드 대체 변수

```sql
-- 실행 시 사원 번호 입력 창이 표시됨
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  employee_id = &employee_num;
```

### 문자·날짜 값과 대체 변수

```sql
-- 문자/날짜 값은 단일 따옴표로 감싼다
SELECT last_name, department_id, salary * 12
FROM   employees
WHERE  job_id = '&job_title';
```

### 열 이름, 표현식, 텍스트 지정

```sql
-- 열 이름, 조건, 정렬 기준도 변수로 지정 가능
SELECT employee_id, last_name, job_id, &column_name
FROM   employees
WHERE  &condition
ORDER BY &order_column;
```

### 이중 앰퍼샌드 대체 변수

```sql
-- &&로 한 번 입력한 값을 여러 곳에서 재사용
SELECT employee_id, last_name, job_id, &&column_name
FROM   employees
ORDER BY &column_name;
```

---

## 변수에 값 할당 — DEFINE / UNDEFINE

```sql
-- 변수 정의
DEFINE employee_num = 200

-- 정의된 변수 사용
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  employee_id = &employee_num;

-- 변수 삭제
UNDEFINE employee_num
```

## VERIFY 명령어

대체 변수를 실제 값으로 대체하기 전후를 표시할 수 있다:

```sql
SET VERIFY ON
SELECT employee_id, last_name, salary
FROM   employees
WHERE  employee_id = &employee_num;
```

---

## 단원 요약

이 단원에서 배운 내용:

- **WHERE 절**: 조건에 맞는 행만 필터링
- **비교 연산자**: `=`, `>`, `>=`, `<`, `<=`, `<>`, `BETWEEN...AND`, `IN`, `LIKE`, `IS NULL`
- **논리 연산자**: `AND`, `OR`, `NOT`
- **연산자 우선순위**: 산술 > 연결 > 비교 > IS NULL/LIKE/IN > BETWEEN > NOT > AND > OR
- **ORDER BY 절**: 결과 정렬 (ASC/DESC, 별칭, 위치, 다중 열)
- **행 제한 절**: FETCH FIRST N ROWS ONLY (Oracle)
- **대체 변수**: `&`, `&&`, DEFINE, VERIFY (Oracle)

---

## Practice 3: 개요

이 실습에서 다루는 내용:

- 데이터를 선택하고 표시되는 행의 순서를 변경한다
- WHERE 절을 사용하여 행을 제한한다
- ORDER BY 절을 사용하여 행을 정렬한다
- 대체 변수를 사용하여 SQL SELECT 문에 유연성을 추가한다
