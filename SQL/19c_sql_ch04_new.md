# Oracle Database 19c: SQL Workshop
## Chapter 4 — 단일행 함수를 사용한 출력 커스터마이징

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있습니다:

- SQL에서 사용 가능한 다양한 함수 유형을 설명한다
- SELECT 문에서 문자, 숫자, 날짜 함수를 사용한다

---

## 학습 목차

- 단일행 SQL 함수
- 문자 함수
- 중첩 함수
- 숫자 함수
- Oracle 데이터베이스에서 날짜 작업
- 날짜 함수

---

## SQL 함수 개요

SQL 함수는 입력 인수를 받아 하나의 결과 값을 반환한다.

```
function_name[(arg1, arg2, ...)]  →  결과 값
```

### 함수의 두 가지 유형

| 유형 | 설명 |
|------|------|
| **단일행 함수 (Single-Row)** | 행마다 하나의 결과를 반환한다 |
| **다중행 함수 (Multiple-Row)** | 행의 집합에서 하나의 결과를 반환한다 |

---

## 단일행 함수 특성

단일행 함수는:
- 데이터 항목을 조작한다
- 인수를 받아 하나의 값을 반환한다
- 반환된 각 행에 대해 실행된다
- 행마다 하나의 결과를 반환한다
- 데이터 유형을 변환할 수 있다
- 중첩이 가능하다
- 열 또는 표현식을 인수로 받는다

### 단일행 함수의 분류

- **문자 함수 (Character)**: 문자열 처리
- **숫자 함수 (Number)**: 수치 연산
- **날짜 함수 (Date)**: 날짜 조작
- **변환 함수 (Conversion)**: 데이터 타입 변환
- **일반 함수 (General)**: NULL 처리 등

---

## 문자 함수

### 대소문자 변환 함수

| 함수 | 결과 |
|------|------|
| `LOWER('SQL Workshop')` | `sql workshop` |
| `UPPER('sql workshop')` | `SQL WORKSHOP` |
| `INITCAP('the soap')` | `The Soap` |

```sql
SELECT last_name, UPPER(last_name), job_id, LOWER(job_id)
FROM   employees
WHERE  department_id = 90;
```

### WHERE 절에서 대소문자 변환 함수 사용 (Oracle)

Oracle은 문자 값을 대소문자 구분하여 비교한다.  
LOWER 함수로 대소문자 구분 없이 검색할 수 있다:

```sql
-- 결과 없음 (대소문자 불일치)
SELECT employee_id, last_name, department_id
FROM   employees
WHERE  last_name = 'higgins';

-- LOWER 함수로 대소문자 구분 없이 검색
SELECT employee_id, last_name, department_id
FROM   employees
WHERE  LOWER(last_name) = 'higgins';
```

---

## 문자 조작 함수

| 함수 | 결과 | 설명 |
|------|------|------|
| `CONCAT('Hello', 'World')` | `HelloWorld` | 두 문자열 연결 |
| `SUBSTR('HelloWorld', 1, 5)` | `Hello` | 부분 문자열 추출 (위치 1부터 5글자) |
| `LENGTH('HelloWorld')` | `10` | 문자열 길이 |
| `INSTR('HelloWorld', 'W')` | `6` | 문자열 내 위치 검색 |
| `LPAD(24000, 10, '*')` | `*****24000` | 왼쪽 채우기 (전체 10자리) |
| `RPAD(24000, 10, '*')` | `24000*****` | 오른쪽 채우기 (전체 10자리) |
| `TRIM('H' FROM 'HelloWorld')` | `elloWorld` | 앞뒤 특정 문자 제거 |
| `REPLACE('JACK and JUE','J','BL')` | `BLACK and BLUE` | 문자열 치환 |

```sql
-- SUBSTR: job_id의 4번째 자리부터 끝까지가 'REP'인 사원
SELECT last_name, CONCAT('Job category is ', job_id) AS Job
FROM   employees
WHERE  SUBSTR(job_id, 4) = 'REP';

-- LENGTH, INSTR, SUBSTR 조합
SELECT employee_id,
       CONCAT(first_name, last_name)  AS NAME,
       LENGTH(last_name),
       INSTR(last_name, 'a')          AS "Contains 'a'?"
FROM   employees
WHERE  SUBSTR(last_name, -1, 1) = 'n';   -- 마지막 문자가 'n'
```

---

## 중첩 함수 (Nesting Functions)

단일행 함수는 여러 단계로 중첩할 수 있다.  
**가장 안쪽(깊은) 함수부터 바깥쪽 방향으로** 순서대로 평가된다.

```
F3(F2(F1(col, arg1), arg2), arg3)
  Step 1: F1(col, arg1)  → Result 1
  Step 2: F2(Result1, arg2) → Result 2
  Step 3: F3(Result2, arg3) → Result 3
```

### 중첩 함수 예제

```sql
-- 부서 60 사원의 last_name 앞 8글자 + '_US'를 대문자로 출력
SELECT last_name,
       UPPER(CONCAT(SUBSTR(last_name, 1, 8), '_US')) AS result
FROM   employees
WHERE  department_id = 60;

-- 결과 예:
-- Hunold  → HUNOLD_US
-- Ernst   → ERNST_US
-- Austin  → AUSTIN_US
-- Pataballa → PATABA_US  (8글자까지만 추출)
-- Lorentz → LORENTZ_US
```

---

## 숫자 함수

| 함수 | 결과 | 설명 |
|------|------|------|
| `ROUND(45.926, 2)` | `45.93` | 소수 둘째 자리로 반올림 |
| `ROUND(45.923, 0)` | `46` | 정수로 반올림 |
| `ROUND(45.923, -1)` | `50` | 10의 자리로 반올림 |
| `TRUNC(45.923, 2)` | `45.92` | 소수 둘째 자리에서 절사 |
| `TRUNC(45.923)` | `45` | 정수로 절사 |
| `TRUNC(45.923, -1)` | `40` | 10의 자리에서 절사 |
| `CEIL(2.83)` | `3` | 올림 (이상의 가장 작은 정수) |
| `FLOOR(2.83)` | `2` | 내림 (이하의 가장 큰 정수) |
| `MOD(1600, 300)` | `100` | 나머지 (1600 ÷ 300 = 5 나머지 100) |

### ROUND 함수 예제

```sql
SELECT ROUND(45.923, 2),   -- 45.92
       ROUND(45.923, 0),   -- 46
       ROUND(45.923, -1)   -- 50
FROM   dual;
```

### TRUNC 함수 예제 (Oracle)

```sql
SELECT TRUNC(45.923, 2),   -- 45.92
       TRUNC(45.923),      -- 45
       TRUNC(45.923, -1)   -- 40
FROM   dual;
```

### MOD 함수 예제

```sql
-- 사번이 짝수인 사원 조회
SELECT employee_id AS Even_Numbers, last_name
FROM   employees
WHERE  MOD(employee_id, 2) = 0;
```

---

## Oracle 데이터베이스에서 날짜 작업

- Oracle은 날짜를 내부 숫자 형식으로 저장한다: 세기, 연도, 월, 일, 시, 분, 초
- 기본 날짜 표시 형식: **DD-MON-RR**
- RR 형식: 두 자리 연도로 세기를 자동 판별

### RR 날짜 형식

| 현재 연도 | 지정 날짜 | RR 해석 결과 |
|----------|----------|------------|
| 1995년 | 27-OCT-95 | 1995년 |
| 1995년 | 27-OCT-17 | 2017년 |
| 2001년 | 27-OCT-17 | 2017년 |
| 2001년 | 27-OCT-95 | 1995년 |

### SYSDATE 함수

```sql
-- 현재 날짜와 시간 조회
SELECT SYSDATE
FROM   dual;

-- CURRENT_DATE: 세션의 현재 날짜
SELECT SESSIONTIMEZONE, CURRENT_DATE
FROM   dual;
```

---

## Oracle에서 날짜 산술

- 날짜에 숫자를 더하거나 빼면 날짜 값이 반환된다
- 두 날짜를 빼면 날짜 사이의 **일수(일)**가 반환된다
- 시간을 더할 때는 시간수를 24로 나눈다

```sql
-- 부서 90 사원들의 입사 후 경과 주수
SELECT last_name, (SYSDATE - hire_date) / 7 AS WEEKS
FROM   employees
WHERE  department_id = 90;
```

---

## Oracle 날짜 조작 함수

| 함수 | 결과 | 설명 |
|------|------|------|
| `MONTHS_BETWEEN('01-SEP-18', '11-JAN-17')` | `19.677...` | 두 날짜 사이의 월 수 |
| `ADD_MONTHS('31-JAN-16', 1)` | `29-FEB-16` | 날짜에 월 수 추가 |
| `NEXT_DAY('01-JUN-16', 'FRIDAY')` | 다음 금요일 | 다음 해당 요일의 날짜 |
| `LAST_DAY('01-APR-16')` | `30-APR-16` | 해당 달의 마지막 날 |
| `ROUND(SYSDATE, 'MONTH')` | 월 기준 반올림 | 15일 이후면 다음달 1일 |
| `TRUNC(SYSDATE, 'MONTH')` | 해당 달의 1일 | 날짜의 월 기준 절사 |
| `TRUNC(SYSDATE, 'YEAR')` | 해당 연도 1월 1일 | 날짜의 연도 기준 절사 |

```sql
-- 날짜 함수 예제 (2018-06-29 기준)
SELECT MONTHS_BETWEEN('01-SEP-18', '11-JAN-17'),   -- 19.677...
       ADD_MONTHS('31-JAN-16', 1),                  -- 29-FEB-16
       NEXT_DAY('01-JUN-16', 'FRIDAY'),             -- 다음 금요일
       LAST_DAY('01-APR-16')                        -- 30-APR-16
FROM   dual;

SELECT ROUND(SYSDATE, 'MONTH'),   -- 01-JUL-18 (29일 → 다음달)
       ROUND(SYSDATE, 'YEAR'),    -- 01-JAN-18 (6월 이전)
       TRUNC(SYSDATE, 'MONTH'),   -- 01-JUN-18
       TRUNC(SYSDATE, 'YEAR')     -- 01-JAN-18
FROM   dual;
```

---

## 단원 요약

이 단원에서 배운 내용:

| 분류 | 주요 함수 |
|------|---------|
| **대소문자 변환** | LOWER, UPPER, INITCAP |
| **문자 조작** | CONCAT, SUBSTR, LENGTH, INSTR, LPAD, RPAD, TRIM, REPLACE |
| **숫자** | ROUND, TRUNC, CEIL, FLOOR, MOD |
| **날짜** | SYSDATE, MONTHS_BETWEEN, ADD_MONTHS, NEXT_DAY, LAST_DAY |
| **날짜 반올림/절사** | ROUND(date, format), TRUNC(date, format) |

- 단일행 함수는 **중첩 가능** — 가장 안쪽부터 평가된다
- WHERE 절에서도 함수를 사용할 수 있다
- 날짜 산술: 날짜 ± 숫자 = 날짜, 날짜 - 날짜 = 일수

---

## Practice 4: 개요

이 실습에서 다루는 내용:

- SYSDATE를 표시하는 쿼리 작성
- 숫자, 문자, 날짜 함수를 사용하는 쿼리 작성
- 사원의 근속 연수 및 월수 계산
