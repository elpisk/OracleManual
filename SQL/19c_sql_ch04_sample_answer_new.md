# Oracle Database 19c: SQL Workshop
## Chapter 4 — 단일행 함수 | SQL 실습 문제 모범답안

---

## Group 1. 대소문자 변환 함수 모범답안 (1~5번)

---

**[1번] 답**

```sql
SELECT UPPER(last_name)  AS last_name_upper,
       LOWER(job_id)     AS job_lower
FROM   employees
WHERE  department_id = 90;
```

> - `UPPER(last_name)`: 성을 모두 대문자로 변환
> - `LOWER(job_id)`: 직무코드를 모두 소문자로 변환

---

**[2번] 답**

```sql
SELECT employee_id,
       first_name,
       INITCAP(first_name) AS initcap_name
FROM   employees;
```

> `INITCAP`: 각 단어의 첫 글자만 대문자, 나머지는 소문자로 변환  
> Oracle 전용 함수로 표준 SQL(MySQL, MSSQL)에는 없다.

---

**[3번] 답**

```sql
SELECT employee_id, last_name, department_id
FROM   employees
WHERE  LOWER(last_name) = 'higgins';
```

> Oracle은 문자 비교 시 **대소문자를 구분**한다.  
> `WHERE last_name = 'Higgins'`도 동일한 결과이지만,  
> 사용자 입력값의 대소문자를 알 수 없을 때 `LOWER` 함수가 유용하다.

---

**[4번] 답**

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  SUBSTR(LOWER(last_name), 1, 3) = 'kin';
```

> 1. `LOWER(last_name)`: 대소문자 구분 없이 처리
> 2. `SUBSTR(..., 1, 3)`: 첫 3글자 추출
> 3. `= 'kin'`: 'kin'과 일치하는 사원 (King → lower → king → substr → 'kin')

---

**[5번] 답**

```sql
SELECT last_name, job_id
FROM   employees
WHERE  INSTR(LOWER(job_id), 'man') > 0
ORDER BY job_id;
```

> `INSTR(LOWER(job_id), 'man') > 0`: job_id를 소문자로 변환 후 'man'의 위치가 1 이상이면 포함됨  
> 결과: MK_MAN, SA_MAN 직무의 사원들 (관리자급)

---

## Group 2. 문자 조작 함수 모범답안 (6~11번)

---

**[6번] 답**

```sql
SELECT first_name || ' ' || last_name AS full_name
FROM   employees;
```

또는:
```sql
SELECT CONCAT(CONCAT(first_name, ' '), last_name) AS full_name
FROM   employees;
```

> CONCAT은 인수를 2개만 받으므로 세 문자열 결합 시 중첩하거나 `||` 연산자가 더 편리하다.

---

**[7번] 답**

```sql
SELECT last_name,
       SUBSTR(last_name, 1, 5) || employee_id AS id_code
FROM   employees;
```

> - `SUBSTR(last_name, 1, 5)`: last_name의 첫 5글자
> - `|| employee_id`: 사번 연결 (숫자가 자동으로 문자로 변환됨)

---

**[8번] 답**

```sql
SELECT last_name,
       LPAD(salary, 10, '*') AS formatted_salary
FROM   employees;
```

> `LPAD(salary, 10, '*')`: salary를 전체 10자리로 만들되 왼쪽 빈 자리를 `*`로 채움  
> - 24000 (5자리) → `*****24000`
> - 2100 (4자리) → `******2100`

---

**[9번] 답**

```sql
SELECT last_name,
       RPAD(job_id, 15, '-') AS formatted_job
FROM   employees;
```

> `RPAD(job_id, 15, '-')`: job_id를 전체 15자리로 만들되 오른쪽 빈 자리를 `-`로 채움  
> - AD_PRES (7자리) → `AD_PRES--------` (- 8개)
> - AD_VP (5자리) → `AD_VP----------` (- 10개)

---

**[10번] 답**

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  SUBSTR(last_name, -1, 1) = 'n';
```

> `SUBSTR(last_name, -1, 1)`: 문자열 끝에서 1번째 위치, 1글자 → 마지막 문자  
> Oracle에서 음수 위치는 문자열 끝에서부터 역방향으로 계산한다.

---

**[11번] 답**

```sql
SELECT last_name,
       job_id,
       INSTR(job_id, '_') AS underscore_pos
FROM   employees;
```

> `INSTR(job_id, '_')`: job_id에서 `_`(언더스코어)가 처음 나타나는 위치 반환  
> - `AD_PRES` → 3 (`_`가 3번째)
> - `IT_PROG` → 3 (`_`가 3번째)
> - `SA_REP` → 3 (`_`가 3번째)

---

## Group 3. 중첩 함수 모범답안 (12~16번)

---

**[12번] 답**

```sql
SELECT last_name,
       UPPER(CONCAT(SUBSTR(last_name, 1, 8), '_US')) AS result
FROM   employees
WHERE  department_id = 60;
```

> **실행 순서 (안쪽 → 바깥쪽):**
> 1. `SUBSTR(last_name, 1, 8)` → 첫 8글자 추출
> 2. `CONCAT(..., '_US')` → '_US' 연결
> 3. `UPPER(...)` → 전체 대문자 변환
>
> Pataballa(9글자) → 'Pataball' → 'Pataball_US' → **'PATABALL_US'**

---

**[13번] 답**

```sql
SELECT INITCAP(first_name || ' ' || last_name) AS formatted_name
FROM   employees;
```

> INITCAP은 공백으로 분리된 각 단어의 첫 글자를 대문자로 변환한다.  
> 예: 'steven king' → 'Steven King'

---

**[14번] 답**

```sql
SELECT last_name,
       LPAD(ROUND(salary, -2), 10, '0') AS formatted_rounded_salary
FROM   employees;
```

> **실행 순서:**
> 1. `ROUND(salary, -2)`: 백 단위에서 반올림 (salary=24000 → 24000, 2500 → 3000)
> 2. `LPAD(..., 10, '0')`: 전체 10자리, 왼쪽 빈 자리 '0' 채우기

---

**[15번] 답**

```sql
SELECT last_name,
       SUBSTR(LOWER(last_name), 1, 1) AS first_char_lower
FROM   employees;
```

> **실행 순서:**
> 1. `LOWER(last_name)`: 전체 소문자로 변환
> 2. `SUBSTR(..., 1, 1)`: 첫 번째 문자 1글자 추출

---

**[16번] 답**

```sql
SELECT last_name,
       LOWER(email) AS email_lower
FROM   employees;
```

> EMPLOYEES 테이블의 email은 대문자로 저장되어 있다.  
> `LOWER(email)`로 변환하여 소문자 형태의 이메일 주소를 표시한다.  
> 예: SKING → sking, NKOCHHAR → nkochhar

---

## Group 4. 숫자 함수 모범답안 (17~22번)

---

**[17번] 답**

```sql
SELECT ROUND(123.456, 2)   AS round_2,
       ROUND(123.456, 0)   AS round_0,
       ROUND(123.456, -1)  AS round_neg1,
       ROUND(123.456, -2)  AS round_neg2
FROM   dual;
```

> 결과: 123.46 / 123 / 120 / 100
>
> | 자릿수 | 의미 | 123.456 결과 |
> |--------|------|------------|
> | 2 | 소수 둘째 자리 | 123.46 |
> | 0 | 정수 자리 | 123 |
> | -1 | 10의 자리 | 120 |
> | -2 | 100의 자리 | 100 |

---

**[18번] 답**

```sql
SELECT TRUNC(123.456, 2)   AS trunc_2,
       TRUNC(123.456, 0)   AS trunc_0,
       TRUNC(123.456, -1)  AS trunc_neg1
FROM   dual;
```

> 결과: 123.45 / 123 / 120  
> TRUNC는 반올림 없이 지정 자리 이하를 **버린다**.  
> - ROUND(123.456, 2) = 123.46 (셋째 자리 6을 반올림)  
> - TRUNC(123.456, 2) = 123.45 (셋째 자리 이하 버림)

---

**[19번] 답**

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  MOD(employee_id, 2) = 0
ORDER BY employee_id;
```

> `MOD(employee_id, 2) = 0`: 사번을 2로 나눈 나머지가 0 → 짝수  
> 홀수: `MOD(employee_id, 2) = 1`

---

**[20번] 답**

```sql
SELECT last_name,
       salary,
       ROUND(salary, -3) AS rounded_1000,
       TRUNC(salary, -3) AS truncated_1000
FROM   employees;
```

> `ROUND(salary, -3)`: 천 단위에서 반올림  
> `TRUNC(salary, -3)`: 천 단위에서 절사  
>
> 예: salary=2500 → ROUND=3000, TRUNC=2000  
>     salary=11000 → ROUND=11000, TRUNC=11000

---

**[21번] 답**

```sql
SELECT last_name,
       salary,
       ROUND(salary * 12 / 365, 2) AS daily_pay
FROM   employees;
```

> 연봉(salary * 12)을 365일로 나누면 일당이 된다.  
> King: 24000 × 12 / 365 = 288000 / 365 ≈ 789.04 (또는 salary / 365 × 12의 순서에 따라 소수점 차이 가능)  
>
> 대안: `ROUND(salary / 30, 2)` — 한 달을 30일로 간주하는 방식

---

**[22번] 답**

```sql
SELECT last_name,
       ROUND(salary / 1000 + 0.3, 1)   AS test_val,
       CEIL(salary / 1000 + 0.3)       AS ceil_val,
       FLOOR(salary / 1000 + 0.3)      AS floor_val
FROM   employees;
```

> King: salary/1000 + 0.3 = 24.3 → CEIL=25, FLOOR=24  
> CEIL: 이상의 **최소 정수** (항상 올림)  
> FLOOR: 이하의 **최대 정수** (항상 내림)

---

## Group 5. 날짜 산술 및 날짜 함수 모범답안 (23~30번)

---

**[23번] 답**

```sql
SELECT SYSDATE
FROM   dual;
```

> SYSDATE: Oracle 서버의 현재 날짜와 시간 반환  
> 날짜 형식은 NLS_DATE_FORMAT 설정에 따라 다르게 표시될 수 있다.

---

**[24번] 답**

```sql
SELECT last_name,
       ROUND(SYSDATE - hire_date, 1)        AS days_worked,
       ROUND((SYSDATE - hire_date) / 7, 1)  AS weeks_worked,
       ROUND((SYSDATE - hire_date) / 365, 1) AS years_worked
FROM   employees
WHERE  department_id = 90;
```

> - `SYSDATE - hire_date`: 경과 일수 (숫자 반환)
> - `/ 7`: 일수 ÷ 7 = 주수
> - `/ 365`: 일수 ÷ 365 = 연수 (윤년 미고려 근사치)

---

**[25번] 답**

```sql
SELECT last_name,
       hire_date,
       ADD_MONTHS(hire_date, 12) AS probation_end
FROM   employees;
```

> `ADD_MONTHS(date, n)`: 날짜에 n개월 추가  
> 월말 처리: 1월 31일 + 1개월 = 2월 28일(또는 29일) — 자동 조정

---

**[26번] 답**

```sql
SELECT last_name,
       hire_date,
       TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) AS months_worked
FROM   employees;
```

> `MONTHS_BETWEEN(최신날짜, 과거날짜)`: 두 날짜 사이의 월 수를 소수로 반환  
> `TRUNC(...)`: 소수점 이하 버림 → 완료된 월 수만 표시  
> 주의: 순서가 바뀌면 음수가 반환됨

---

**[27번] 답**

```sql
SELECT last_name,
       hire_date,
       LAST_DAY(hire_date) AS last_of_month
FROM   employees;
```

> `LAST_DAY(date)`: 해당 날짜가 속한 달의 마지막 날 반환  
> - 2월: 28일(평년) 또는 29일(윤년) 자동 처리

---

**[28번] 답**

```sql
SELECT last_name,
       hire_date,
       NEXT_DAY(hire_date, 'MONDAY') AS next_monday
FROM   employees;
```

> `NEXT_DAY(date, '요일명')`: 지정 날짜 이후 처음 오는 해당 요일의 날짜 반환  
> 요일 이름은 세션의 NLS 언어 설정에 따라 다를 수 있음.  
> 한국어 세션: `NEXT_DAY(hire_date, '월요일')` 또는 숫자(2=월요일) 사용 가능

---

**[29번] 답**

```sql
SELECT last_name,
       hire_date,
       TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) AS months_worked,
       CASE
           WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) >= 360 THEN '30년+'
           WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) >= 240 THEN '20~30년'
           WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) >= 120 THEN '10~20년'
           ELSE '10년 미만'
       END AS grade
FROM   employees
ORDER BY hire_date;
```

> CASE 표현식은 Chapter 4 범위를 약간 벗어나지만 실무에서 자주 활용된다.  
> MONTHS_BETWEEN 서브쿼리 없이 반복 사용하는 것이 단순하다.

---

**[30번] 답**

```sql
SELECT employee_id,
       first_name || ' ' || last_name           AS full_name,
       salary,
       ROUND(salary, -2)                        AS rounded_salary,
       hire_date,
       ADD_MONTHS(hire_date, 12)                AS probation_end,
       TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) AS months_worked
FROM   employees
WHERE  hire_date >= '01-JAN-00'
ORDER BY hire_date;
```

> **조건별 설명:**
>
> | 열 | 사용 함수 | 설명 |
> |----|----------|------|
> | full_name | `||` | 성명 결합 |
> | rounded_salary | ROUND(-2) | 백 단위 반올림 |
> | probation_end | ADD_MONTHS(12) | 수습 완료일 |
> | months_worked | MONTHS_BETWEEN + TRUNC | 정수 근속 월수 |
>
> `hire_date >= '01-JAN-00'`: RR 형식 — '00'은 2000년으로 해석됨  
> (현재(2001년 이후)에서 00~49는 2000~2049년으로 해석)
