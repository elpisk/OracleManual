# Oracle Database 19c: SQL Workshop
## Chapter 5 — 변환 함수와 조건식 사용

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있습니다:

- SQL에서 사용 가능한 다양한 변환 함수 유형을 설명한다
- TO_CHAR, TO_NUMBER, TO_DATE 변환 함수를 사용한다
- SELECT 문에서 조건식을 적용한다

---

## 학습 목차

- 암시적 및 명시적 데이터 타입 변환
- TO_CHAR, TO_DATE, TO_NUMBER 함수 (Oracle)
- CAST() 함수
- 일반 함수: NVL / NVL2 / NULLIF / COALESCE
- 조건식: CASE / Searched CASE / DECODE
- JSON 함수 (개요)

---

## 변환 함수 개요

### 데이터 타입 변환의 두 가지 방식

| 방식 | 설명 |
|------|------|
| **암시적 변환 (Implicit)** | Oracle 서버가 자동으로 수행 |
| **명시적 변환 (Explicit)** | 사용자가 함수를 사용하여 직접 수행 |

### 암시적 변환 예시

```sql
-- 문자열 → 숫자로 자동 변환 (WHERE 비교 시)
SELECT first_name, last_name, department_id
FROM   employees
WHERE  department_id < CONCAT('9', '0');  -- '90' → 90으로 자동 변환

-- 숫자 → 문자열로 자동 변환 (INSTR 적용 시)
SELECT first_name, last_name, salary
FROM   employees
WHERE  INSTR(salary, '5') > 0;  -- salary(숫자) → 문자열로 자동 변환
```

---

## TO_CHAR 함수 — 날짜를 문자열로

```
TO_CHAR(date [, 'format_model'])
```

### 날짜 형식 모델 요소

| 요소 | 결과 |
|------|------|
| `YYYY` | 4자리 연도 숫자 (예: 2024) |
| `YEAR` | 연도 영문 표기 (예: TWENTY TWENTY-FOUR) |
| `MM` | 두 자리 월 (예: 06) |
| `MONTH` | 월 전체 이름 (예: JUNE) |
| `MON` | 월 3자리 약어 (예: JUN) |
| `DY` | 요일 3자리 약어 (예: MON) |
| `DAY` | 요일 전체 이름 (예: MONDAY) |
| `DD` | 두 자리 일 (예: 17) |
| `HH24:MI:SS` | 시:분:초 24시간 형식 (예: 15:45:32) |
| `"of"` | 리터럴 문자열 삽입 (큰따옴표) |
| `ddspth` | 서수 표기 (예: fourteenth) |
| `fm` 접두사 | 앞 공백·0 제거 |

### 날짜 TO_CHAR 예제

```sql
-- Higgins의 입사 월/연도 조회
SELECT employee_id, TO_CHAR(hire_date, 'MM/YY') AS Month_Hired
FROM   employees
WHERE  last_name = 'Higgins';
-- 결과: 06/02 (2002년 6월)

-- fm 접두사로 앞 공백/0 제거
SELECT last_name,
       TO_CHAR(hire_date, 'fmDD Month YYYY') AS HIREDATE
FROM   employees;
-- 결과: King → '17 June 1987'  (fm 없으면 '17 JUNE       1987')
```

---

## TO_CHAR 함수 — 숫자를 문자열로

```
TO_CHAR(number [, 'format_model'])
```

### 숫자 형식 모델 요소

| 요소 | 결과 |
|------|------|
| `9` | 숫자 자리 표현 (앞 0은 공백) |
| `0` | 숫자 자리 (앞 0 강제 표시) |
| `$` | 부동 달러 기호 |
| `L` | 부동 지역 통화 기호 |
| `.` | 소수점 |
| `,` | 천 단위 구분자 |

```sql
-- Ernst의 급여를 통화 형식으로 출력 (Ernst salary = 6000)
SELECT TO_CHAR(salary, '$99,999.00') AS SALARY
FROM   employees
WHERE  last_name = 'Ernst';
-- 결과: $6,000.00
```

---

## TO_NUMBER, TO_DATE 함수

### TO_NUMBER

```
TO_NUMBER(char [, 'format_model'])
```

문자열을 숫자 형식으로 변환한다.

```sql
SELECT TO_NUMBER('12,345.67', '99,999.99') FROM dual;
-- 결과: 12345.67
```

### TO_DATE

```
TO_DATE(char [, 'format_model'])
```

문자열을 날짜 형식으로 변환한다.

```sql
-- 2010년 이전 입사 사원 조회 (RR 형식 활용)
SELECT last_name, TO_CHAR(hire_date, 'DD-Mon-YYYY')
FROM   employees
WHERE  hire_date < TO_DATE('01 Jan, 10', 'DD Mon, RR');
-- '10'은 RR 형식으로 2010년 해석
```

---

## CAST() 함수

```
CAST(input_value AS destination_type)
```

한 데이터 타입을 다른 타입으로 변환한다.

```sql
-- 문자 결합 결과를 숫자로 명시적 변환
SELECT first_name, last_name, department_id
FROM   employees
WHERE  department_id < CAST(CONCAT('9', '0') AS DECIMAL(2,0));

-- 숫자를 문자열로 변환 후 INSTR 사용
SELECT first_name, last_name, salary
FROM   employees
WHERE  INSTR(CAST(salary AS VARCHAR2(30)), '5') > 0;
```

---

## 일반 함수 — NULL 처리

| 함수 | 설명 |
|------|------|
| `NVL(expr1, expr2)` | expr1이 NULL이면 expr2 반환 |
| `NVL2(expr1, expr2, expr3)` | expr1이 NULL이 아니면 expr2, NULL이면 expr3 |
| `NULLIF(expr1, expr2)` | expr1 = expr2이면 NULL, 다르면 expr1 |
| `COALESCE(e1, e2, ..., en)` | 첫 번째 NULL이 아닌 값 반환 |

---

## NVL 함수

```sql
-- commission_pct가 NULL인 경우 0으로 대체
SELECT last_name, salary, NVL(commission_pct, 0),
       (salary * 12) + (salary * 12 * NVL(commission_pct, 0)) AS AN_SAL
FROM   employees;
```

> NVL의 두 표현식은 **데이터 타입이 일치**해야 한다.  
> `NVL(hire_date, '01-JAN-97')` — 날짜 타입  
> `NVL(job_id, 'No Job Yet')` — 문자 타입  
> `NVL(commission_pct, 0)` — 숫자 타입

---

## NVL2 함수

```sql
-- commission_pct가 있으면 'SAL+COMM', 없으면 'SAL' 표시
SELECT last_name, salary, commission_pct,
       NVL2(commission_pct, 'SAL+COMM', 'SAL') AS income
FROM   employees
WHERE  department_id IN (50, 80);
```

---

## NULLIF 함수

```sql
-- first_name과 last_name의 길이가 같으면 NULL, 다르면 first_name 길이 반환
SELECT first_name, LENGTH(first_name) AS expr1,
       last_name,  LENGTH(last_name)  AS expr2,
       NULLIF(LENGTH(first_name), LENGTH(last_name)) AS Result
FROM   employees;
```

> `NULLIF(a, b)`: a = b이면 NULL, a ≠ b이면 a 반환

---

## COALESCE 함수

NVL/IFNULL과 달리 **여러 개의 대체값**을 지정할 수 있다.

```sql
-- commission이 있으면 salary+commission, 없으면 salary+2000
SELECT last_name, salary, commission_pct,
       COALESCE((salary + (commission_pct * salary)), salary + 2000) AS New_Salary
FROM   employees;
```

> 첫 번째 NULL이 아닌 값을 반환한다.  
> 모두 NULL이면 NULL을 반환한다.

---

## 조건식 (Conditional Expressions)

SQL SELECT 문 안에서 **IF-THEN-ELSE 논리**를 구현하는 방법:

- **CASE 표현식** (ANSI 표준)
- **Searched CASE 표현식** (ANSI 표준)
- **DECODE 함수** (Oracle 전용)

---

## CASE 표현식

```sql
CASE expr
    WHEN comparison_expr1 THEN return_expr1
    [WHEN comparison_expr2 THEN return_expr2]
    [ELSE else_expr]
END
```

```sql
-- 직무에 따른 급여 인상률 적용
SELECT last_name, job_id, salary,
       CASE job_id
           WHEN 'IT_PROG'  THEN 1.10 * salary
           WHEN 'ST_CLERK' THEN 1.15 * salary
           WHEN 'SA_REP'   THEN 1.20 * salary
           ELSE salary
       END AS REVISED_SALARY
FROM   employees;
```

---

## Searched CASE 표현식

범위나 복잡한 조건 비교에 적합하다.

```sql
CASE
    WHEN condition1 THEN return_expr1
    WHEN condition2 THEN return_expr2
    ELSE default_expr
END
```

```sql
-- 급여 범위에 따른 등급 부여
SELECT last_name, salary,
       CASE
           WHEN salary < 5000  THEN 'Low'
           WHEN salary < 10000 THEN 'Medium'
           WHEN salary < 20000 THEN 'Good'
           ELSE 'Excellent'
       END AS qualified_salary
FROM   employees;
```

---

## DECODE 함수 (Oracle 전용)

CASE 표현식 또는 IF-THEN-ELSE 논리와 동일한 작업을 수행한다.

```sql
DECODE(col|expression, search1, result1
       [, search2, result2, ...]
       [, default])
```

```sql
-- 직무에 따른 급여 인상 (CASE와 동일한 결과)
SELECT last_name, job_id, salary,
       DECODE(job_id,
              'IT_PROG',  1.10 * salary,
              'ST_CLERK', 1.15 * salary,
              'SA_REP',   1.20 * salary,
              salary) AS REVISED_SALARY
FROM   employees;

-- 급여 구간에 따른 세율 적용 (부서 80)
SELECT last_name, salary,
       DECODE(TRUNC(salary / 2000, 0),
              0, 0.00,
              1, 0.09,
              2, 0.20,
              3, 0.30,
              4, 0.40,
              5, 0.42,
              6, 0.44,
              0.45) AS TAX_RATE
FROM   employees
WHERE  department_id = 80;
```

---

## CASE vs DECODE 비교

| 항목 | CASE | DECODE |
|------|------|--------|
| 표준 | ANSI SQL (표준) | Oracle 전용 |
| 조건 방식 | 등가 비교 + 범위 비교 | 등가 비교만 |
| Searched | 지원 (WHEN condition) | 미지원 |
| NULL 처리 | `WHEN NULL` 불가 — IS NULL 사용 | 내부적으로 NULL = NULL 비교 지원 |
| 권장 | 실무 권장 | Oracle 레거시 코드에서 사용 |

---

## JSON 함수 (개요)

Oracle 12c 이상에서 JSON 데이터를 SQL로 처리하는 함수를 제공한다.

```sql
-- JSON_QUERY: JSON 값 조회
SELECT JSON_QUERY('{"a":100, "b":200, "c":300}', '$') AS value
FROM   dual;
-- 결과: {"a":100,"b":200,"c":300}

-- JSON_VALUE: 특정 키의 값 추출
SELECT JSON_VALUE('{"a":100}', '$.a') AS value
FROM   dual;
-- 결과: 100
```

---

## 단원 요약

이 단원에서 배운 내용:

| 분류 | 내용 |
|------|------|
| **변환 함수** | TO_CHAR(날짜/숫자→문자), TO_DATE(문자→날짜), TO_NUMBER(문자→숫자) |
| **TO_CHAR 날짜 형식** | YYYY/MM/DD, MONTH, MON, DY, HH24:MI:SS, fm 접두사 |
| **TO_CHAR 숫자 형식** | 9, 0, $, L, ., , |
| **NULL 처리 함수** | NVL, NVL2, NULLIF, COALESCE |
| **조건식** | CASE (ANSI 표준), Searched CASE, DECODE (Oracle 전용) |

- `TO_CHAR`로 날짜/숫자를 원하는 형식의 문자열로 변환한다
- `NVL`은 NULL을 대체값으로, `COALESCE`는 여러 대체값 중 첫 번째 비-NULL 값을 반환한다
- `CASE`는 ANSI 표준이며 범위 조건도 처리 가능, `DECODE`는 Oracle 전용 등가 비교

---

## Practice 5: 개요

이 실습에서 다루는 내용:

- TO_CHAR, TO_DATE 등 날짜 함수를 사용하는 쿼리 작성
- CASE, Searched CASE, DECODE 등 조건식을 사용하는 쿼리 작성
