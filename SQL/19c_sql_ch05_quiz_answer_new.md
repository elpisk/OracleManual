# Oracle Database 19c: SQL Workshop
## Chapter 5 — 변환 함수와 조건식 | 연습문제 모범답안

---

# ★ 하 (기초) 모범답안

---

**[하-01] 답: ②**

암시적 변환은 **Oracle 서버가 자동으로** 필요한 타입으로 변환한다.  
예: `WHERE department_id < CONCAT('9','0')` → '90'(문자)이 90(숫자)으로 자동 변환

---

**[하-02] 답: ③**

`TO_CHAR(hire_date, 'YYYY')` → `1987`  
- YYYY: 4자리 연도 숫자 전체를 반환

---

**[하-03] 답: ②**

`MM`: 두 자리 월 숫자 반환 (예: 06, 12)  
- MONTH: 전체 이름 (JUNE), MON: 약어 (JUN), DAY: 요일 전체 이름

---

**[하-04] 답: ②**

`fm` 접두사는 **앞 공백과 앞의 0을 제거**하여 깔끔한 출력을 만든다.  
- fm 없음: `' 7 JUNE       1987'` (앞 공백, 뒤 공백 포함)  
- fm 있음: `'7 June 1987'` (공백 제거, 월 이름도 초기 대문자로)

---

**[하-05] 답: ②**

숫자 형식 `0`: 해당 자리에 0을 강제 표시한다.  
- `99,999.00`: 소수 2자리를 반드시 표시 (예: 6000 → `6,000.00`)  
- `9`: 숫자 없으면 공백, `0`: 숫자 없으면 0 표시

---

**[하-06] 답: ②**

`TO_NUMBER('$1,234', '$9,999')` → `1234`  
- 형식 모델을 지정하면 `$`와 `,`를 포함한 문자열도 숫자로 변환된다.

---

**[하-07] 답: ②**

`TO_DATE('25-DEC-23', 'DD-MON-RR')` → 2023년 12월 25일  
- RR 형식: 현재 연도 2001년 이후 기준, 00~49 → 2000년대  
- '23' → 2023년

---

**[하-08] 답: ②**

`NVL(commission_pct, 0)`: commission_pct가 **NULL이면 0을 반환**한다.  
- NULL이 아닌 경우: commission_pct 값 그대로 반환

---

**[하-09] 답: ②**

`NVL2(commission_pct, 'SAL+COMM', 'SAL')`:  
- commission_pct가 NULL이 아니면 → `'SAL+COMM'`  
- commission_pct가 NULL이면 → **`'SAL'`**

---

**[하-10] 답: ③**

`NULLIF(10, 10)` → **NULL**  
- NULLIF(a, b): a = b이면 NULL, a ≠ b이면 a를 반환  
- 두 값이 같으므로 NULL 반환

---

**[하-11] 답: ②**

`COALESCE(NULL, NULL, 100, 200)` → **100**  
- 첫 번째 NULL이 아닌 값을 반환: NULL → NULL → 100 → 반환

---

**[하-12] 답: ②**

CASE 표현식은 **IF-THEN-ELSE 논리를 SQL 문 내에서 구현**한다.  
- ANSI SQL 표준 (Oracle 전용 아님)  
- SELECT, WHERE, ORDER BY 절 모두 사용 가능

---

**[하-13] 답: ②**

job_id = 'IT_PROG', salary = 9000:  
- `WHEN 'IT_PROG' THEN 1.10 * salary` 조건 일치  
- 결과: `1.10 × 9000 = 9900`

---

**[하-14] 답: ②**

Searched CASE의 각 WHEN 절에는 **범위 비교를 포함한 모든 조건** 사용 가능:  
- `WHEN salary < 5000 THEN ...`  
- `WHEN dept_id BETWEEN 50 AND 80 THEN ...`  
- 일반 CASE: 등가 비교만 가능

---

**[하-15] 답: ③**

`DECODE(job_id, 'SA_REP', 1.20*salary, salary)`:  
- job_id = 'AD_PRES'는 'SA_REP'와 일치하지 않음  
- 기본값인 **`salary`** 반환

---

**[하-16] 답: ②**

- CASE: ANSI 표준, **범위 조건(BETWEEN, <, >)** 처리 가능  
- DECODE: Oracle 전용, **등가 비교(=)만** 가능  
- 실무에서는 CASE 사용 권장

---

**[하-17] 답: ③**

`TO_CHAR(SYSDATE, 'HH24:MI:SS')` → 현재 시간을 24시간 형식으로 출력  
예: `15:30:22`

---

**[하-18] 답: ②**

`DY`: 요일 **3자리 약어** 반환 (MON, TUE, WED, THU, FRI, SAT, SUN)  
- DAY: 전체 이름 (MONDAY), DD: 숫자 일자, DY: 약어

---

**[하-19] 답: ②**

NVL 두 인수의 데이터 타입이 다르면 **오류 발생**.  
예: `NVL(commission_pct, 'None')` — commission_pct는 NUMBER, 'None'은 VARCHAR2 → 타입 불일치 오류

---

**[하-20] 답: ③**

salary = 12000:  
- `WHEN salary < 5000`: 거짓  
- `WHEN salary < 10000`: 거짓  
- `WHEN salary < 20000`: **참** → `'Good'` 반환

---

# ★★ 중 (응용) 모범답안

---

**[중-01] 답**

```sql
SELECT last_name,
       TO_CHAR(hire_date, 'fmDD Month YYYY') AS hire_date_fmt
FROM   employees;
```

> `fm`: 앞 공백·0 제거, Month는 첫 글자만 대문자  
> 예: King → `17 June 1987`

---

**[중-02] 답**

```sql
SELECT employee_id,
       TO_CHAR(hire_date, 'MM/YY') AS Month_Hired
FROM   employees
WHERE  last_name = 'Higgins';
```

> 결과: `06/02` (2002년 6월)

---

**[중-03] 답**

```sql
SELECT last_name,
       TO_CHAR(salary, '$99,999.00') AS formatted_salary
FROM   employees;
```

> - King(24000) → `$24,000.00`  
> - Ernst(6000) → ` $6,000.00` (앞 공백 포함, 9 형식은 공백)

---

**[중-04] 답**

```sql
SELECT last_name,
       salary,
       NVL(commission_pct, 0)  AS commission,
       (salary * 12) + (salary * 12 * NVL(commission_pct, 0)) AS annual_salary
FROM   employees;
```

> commission_pct = NULL → NVL로 0 대체  
> King(salary=24000, commission=NULL): 24000×12 + 0 = 288,000

---

**[중-05] 답**

```sql
SELECT last_name, salary, commission_pct,
       NVL2(commission_pct, 'SAL+COMM', 'SAL ONLY') AS income_type
FROM   employees;
```

---

**[중-06] 답**

```sql
SELECT first_name,
       LENGTH(first_name) AS fn_len,
       last_name,
       LENGTH(last_name)  AS ln_len,
       NULLIF(LENGTH(first_name), LENGTH(last_name)) AS result
FROM   employees;
```

> 이름 길이가 같으면 NULL 반환 (예: 'Lex De Haan' → LENGTH('Lex')=3, LENGTH('De Haan')=7 → 3 반환)

---

**[중-07] 답**

```sql
SELECT last_name, salary, commission_pct,
       COALESCE(salary + (salary * commission_pct),
                salary + 500) AS adjusted_salary
FROM   employees;
```

> commission_pct가 NULL이면 첫 표현식이 NULL → 두 번째 salary+500 사용

---

**[중-08] 답**

```sql
SELECT last_name,
       TO_CHAR(hire_date, 'DD-Mon-YYYY') AS hire_date_fmt
FROM   employees
WHERE  hire_date < TO_DATE('01 Jan, 10', 'DD Mon, RR');
```

> `TO_DATE('01 Jan, 10', 'DD Mon, RR')`: '10'은 RR 형식으로 2010년  
> 2010년 이전 입사자 전원 조회

---

**[중-09] 답**

```sql
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

**[중-10] 답**

```sql
SELECT last_name, job_id, salary,
       DECODE(job_id,
              'IT_PROG',  1.10 * salary,
              'ST_CLERK', 1.15 * salary,
              'SA_REP',   1.20 * salary,
              salary) AS REVISED_SALARY
FROM   employees;
```

> 중-09의 CASE 표현식과 동일한 결과를 DECODE로 작성

---

**[중-11] 답**

```sql
SELECT last_name, salary,
       CASE
           WHEN salary < 5000  THEN 'Low'
           WHEN salary < 10000 THEN 'Medium'
           WHEN salary < 20000 THEN 'High'
           ELSE 'Top'
       END AS salary_grade
FROM   employees;
```

---

**[중-12] 답**

```sql
SELECT last_name,
       TO_CHAR(hire_date, 'fmDay, DD Month YYYY') AS hire_date_full
FROM   employees;
```

> King: `Wednesday, 17 June 1987` (입사 요일 포함)

---

**[중-13] 답**

```sql
SELECT last_name, salary,
       DECODE(TRUNC(salary / 2000, 0),
              0, 0.00,
              1, 0.09,
              2, 0.20,
              3, 0.30,
              4, 0.40,
              0.45) AS TAX_RATE
FROM   employees
WHERE  department_id = 80;
```

> `TRUNC(salary/2000, 0)`: 급여를 2000으로 나눈 몫의 정수  
> Russell(14000): 14000/2000=7.0 → 몫=7 → 기본값 0.45

---

**[중-14] 답**

```sql
SELECT last_name,
       NVL(TO_CHAR(manager_id), 'No Manager') AS manager_info
FROM   employees;
```

> manager_id는 NUMBER이므로 TO_CHAR로 문자 변환 후 NVL 적용  
> 또는: `COALESCE(TO_CHAR(manager_id), 'No Manager')`

---

**[중-15] 답**

```sql
SELECT TO_CHAR(SYSDATE, 'YYYY"년" MM"월" DD"일"') AS current_date_kr,
       TO_CHAR(SYSDATE, 'HH24"시" MI"분" SS"초"') AS current_time_kr
FROM   dual;
```

> 리터럴 문자열은 큰따옴표(`"`)로 감싼다.  
> 결과 예: `2026년 06월 27일`, `14시 30분 22초`

---

**[중-16] 답**

```sql
SELECT last_name,
       TO_CHAR(salary, 'L99,999') AS formatted_salary
FROM   employees;
```

> `L`: 세션의 지역 통화 기호를 사용 (한국: ₩, 미국: $, 유럽: €)

---

**[중-17] 답**

```sql
SELECT last_name, hire_date,
       CASE
           WHEN TO_CHAR(hire_date, 'YYYY') < '1987' THEN '원년 멤버'
           WHEN TO_CHAR(hire_date, 'YYYY') < '1990' THEN '90년대 이전'
           WHEN TO_CHAR(hire_date, 'YYYY') < '2000' THEN '90년대'
           ELSE '2000년대 이후'
       END AS member_type
FROM   employees;
```

---

**[중-18] 답**

```sql
SELECT COUNT(commission_pct)           AS has_commission,
       COUNT(*) - COUNT(commission_pct) AS no_commission
FROM   employees;
```

> `COUNT(열)`: NULL 제외 카운트 → commission_pct가 있는 사원 수  
> `COUNT(*) - COUNT(commission_pct)`: NULL인 사원 수  
> HR 스키마: 전체 107명 중 35명 commission 있음, 72명 없음

---

**[중-19] 답**

```sql
SELECT TO_DATE('2023-12-25', 'YYYY-MM-DD') AS christmas
FROM   dual;
```

---

**[중-20] 답**

```sql
SELECT last_name,
       salary,
       TO_CHAR(salary, '000,099,999') AS formatted_salary
FROM   employees;
```

> `0`: 빈 자리를 0으로 채움  
> King(24000) → `000,024,000`

---

# ★★★ 상 (심화) 모범답안

---

**[상-01] 답**

**(1) fm 접두사 차이:**

| 요소 | fm 없음 | fm 있음 |
|------|---------|---------|
| 앞 공백 | 있음 (9자리 고정 폭) | 없음 |
| 월 이름 뒤 공백 | 있음 (JUNE + 공백들) | 없음 |
| 앞 0 | 있음 | 없음 |

**(2) King hire_date = 17-JUN-87 기준 출력 예측:**

```
-- (A) fm 없음:
TO_CHAR(hire_date, 'DD Month YYYY')
→ '17 JUNE       1987'  (MONTH는 대문자, 9자리 고정 폭으로 뒤에 공백)

-- (B) fm 있음:
TO_CHAR(hire_date, 'fmDD Month YYYY')
→ '17 June 1987'  (공백 제거, 첫 글자만 대문자)
```

---

**[상-02] 답**

오류가 있는 SQL:
```sql
SELECT last_name, NVL(commission_pct, 'None'),        -- 오류 1
       TO_CHAR(hire_date, 'DD-MON-YYYY'),             -- 정상
       TO_NUMBER(salary, 'XXXXXX')                    -- 오류 2
FROM   employees;
```

오류 수정:

| 오류 | 원인 | 수정 |
|------|------|------|
| `NVL(commission_pct, 'None')` | commission_pct(NUMBER)와 'None'(VARCHAR2) 타입 불일치 | `NVL(TO_CHAR(commission_pct), 'None')` |
| `TO_NUMBER(salary, 'XXXXXX')` | salary는 이미 NUMBER 타입 + 'XXXXXX'는 16진수 형식(부적절) | `TO_CHAR(salary, '999,999')` 또는 형식 제거 |

수정된 SQL:
```sql
SELECT last_name,
       NVL(TO_CHAR(commission_pct), 'None') AS commission,
       TO_CHAR(hire_date, 'DD-MON-YYYY')   AS hire_date,
       TO_CHAR(salary, '$999,999')          AS salary
FROM   employees;
```

---

**[상-03] 답**

```sql
SELECT last_name,
       hire_date,
       TO_CHAR(hire_date, 'fmDD Month YYYY')   AS hire_date_fmt,
       NVL2(commission_pct,
            salary * 12 * (1 + commission_pct),
            salary * 12)                        AS annual_salary,
       TO_CHAR(NVL2(commission_pct,
                    salary * 12 * (1 + commission_pct),
                    salary * 12), '$999,999')   AS annual_salary_fmt
FROM   employees
ORDER BY annual_salary DESC;
```

---

**[상-04] 답**

**(1) 동일한 결과 여부:**  
일반적으로 **동일한 결과**를 반환한다. DECODE는 CASE 표현식의 Oracle 단축형으로 설계되었다.

**(2) NULL 처리 차이:**

```sql
-- CASE (NULL 처리 주의)
CASE job_id
    WHEN NULL THEN 'null job'  -- 절대 일치하지 않음 (NULL = NULL은 FALSE)
    ELSE salary
END

-- DECODE (NULL 처리 특이)
DECODE(job_id, NULL, 'null job', salary)  -- NULL과 NULL을 같다고 처리!
```

> DECODE는 내부적으로 NULL = NULL을 TRUE로 처리한다.  
> CASE는 `WHEN NULL`이 절대 일치하지 않으므로, NULL 처리 시 `WHEN job_id IS NULL` 형태로 작성해야 한다.

---

**[상-05] 답**

| 함수 | 인수 수 | 특징 |
|------|---------|------|
| `NVL(a, b)` | 2개 | expr1이 NULL이면 expr2 반환 |
| `COALESCE(a, b, ..., n)` | 여러 개 | 첫 번째 NULL이 아닌 값 반환 |

**주어진 상황에 적합한 함수:** `COALESCE`

```sql
-- 예시 테이블에 mobile, email 열이 있다고 가정
SELECT employee_id,
       COALESCE(mobile, email, '연락처 없음') AS contact
FROM   employees;
```

> NVL은 인수 2개만 지원하므로 3단계 대체를 위해서는 `NVL(NVL(mobile, email), '연락처 없음')` 형태로 중첩해야 한다. COALESCE가 더 간결하고 명확하다.

---

**[상-06] 답**

```sql
SELECT first_name || ' ' || last_name      AS full_name,
       TO_CHAR(hire_date, 'fmDD Month YYYY') AS hire_date_fmt,
       CASE
           WHEN TO_CHAR(hire_date, 'MM') IN ('01','02','03') THEN 'Q1'
           WHEN TO_CHAR(hire_date, 'MM') IN ('04','05','06') THEN 'Q2'
           WHEN TO_CHAR(hire_date, 'MM') IN ('07','08','09') THEN 'Q3'
           ELSE 'Q4'
       END                                 AS hire_quarter,
       TO_CHAR(salary, '$999,999')         AS salary_fmt
FROM   employees
ORDER BY hire_date;
```

---

**[상-07] 답**

```sql
SELECT last_name, salary, commission_pct,
       NULLIF(ROUND(salary/1000), TRUNC(salary/1000)) AS result
FROM   employees WHERE department_id = 80;
```

**(1) NULL 반환 조건:**  
`ROUND(salary/1000)` = `TRUNC(salary/1000)` 일 때 NULL 반환  
즉, salary/1000의 소수 첫째 자리가 **0.5 미만**인 경우 (ROUND와 TRUNC 결과가 같음)

**(2) 부서 80 사원 분석:**  
부서 80의 salary는 모두 정수이므로 salary/1000의 소수 부분이 존재한다.  
예: 6100/1000 = 6.1 → ROUND(6.1)=6, TRUNC(6.1)=6 → **같음 → NULL**  
예: 6500/1000 = 6.5 → ROUND(6.5)=7, TRUNC(6.5)=6 → **다름 → 7**  
부서 80에 6500, 8500 등 500으로 끝나는 급여 사원이 있으면 값이 반환되고, 나머지는 NULL.

---

**[상-08] 답**

```sql
SELECT first_name || ' ' || last_name AS full_name,
       TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')) -
       TO_NUMBER(TO_CHAR(hire_date, 'YYYY'))  AS years_of_service,
       TO_CHAR(
           salary * CASE
               WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) -
                    TO_NUMBER(TO_CHAR(hire_date,'YYYY')) >= 30 THEN 0.30
               WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) -
                    TO_NUMBER(TO_CHAR(hire_date,'YYYY')) >= 20 THEN 0.20
               WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) -
                    TO_NUMBER(TO_CHAR(hire_date,'YYYY')) >= 10 THEN 0.10
               ELSE 0.05
           END,
       '$99,999.00') AS bonus
FROM   employees
ORDER BY years_of_service DESC;
```

---

**[상-09] 답**

```sql
-- 부서 90 사원 분석
-- King: hire_date=87-06-17 → TO_CHAR(hire_date,'YYYY')='1987' → '원년 멤버'
-- Kochhar: 89-09-21 → '1989' → '초기 멤버'
-- De Haan: 93-01-13 → '1993' → '일반 멤버' (기본값)
```

예상 결과:

```
LAST_NAME  HIRE_YEAR  MEMBER_TYPE
---------  ---------  ----------
King       1987       원년 멤버
Kochhar    1989       초기 멤버
De Haan    1993       일반 멤버
```

> DECODE는 첫 번째 일치 값을 반환하고, 일치 없으면 기본값('일반 멤버') 반환

---

**[상-10] 답**

```sql
SELECT employee_id,
       last_name,
       TO_CHAR(
           NVL2(commission_pct,
                (salary * 12) + (salary * 12 * commission_pct),
                (salary * 12) + 1000),
           '$999,999') AS total_comp_formatted,
       CASE
           WHEN NVL2(commission_pct,
                     (salary * 12) + (salary * 12 * commission_pct),
                     (salary * 12) + 1000) < 50000    THEN 'Grade A'
           WHEN NVL2(commission_pct,
                     (salary * 12) + (salary * 12 * commission_pct),
                     (salary * 12) + 1000) < 100000   THEN 'Grade B'
           WHEN NVL2(commission_pct,
                     (salary * 12) + (salary * 12 * commission_pct),
                     (salary * 12) + 1000) < 200000   THEN 'Grade C'
           ELSE 'Grade D'
       END AS grade
FROM   employees
ORDER BY NVL2(commission_pct,
              (salary * 12) + (salary * 12 * commission_pct),
              (salary * 12) + 1000) DESC;
```

> **개선 버전 (서브쿼리 활용 — 중복 제거):**
> ```sql
> SELECT employee_id, last_name,
>        TO_CHAR(total_comp, '$999,999') AS total_comp_formatted,
>        CASE
>            WHEN total_comp < 50000  THEN 'Grade A'
>            WHEN total_comp < 100000 THEN 'Grade B'
>            WHEN total_comp < 200000 THEN 'Grade C'
>            ELSE 'Grade D'
>        END AS grade
> FROM (
>     SELECT employee_id, last_name,
>            NVL2(commission_pct,
>                 (salary*12)+(salary*12*commission_pct),
>                 (salary*12)+1000) AS total_comp
>     FROM   employees
> )
> ORDER BY total_comp DESC;
> ```
