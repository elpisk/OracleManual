# Oracle Database 19c: SQL Workshop
## Chapter 4 — 단일행 함수 | 연습문제 모범답안

---

# ★ 하 (기초) 모범답안

---

**[하-01] 답: ②**

단일행 함수는 쿼리의 각 행에 대해 실행되어 행마다 하나의 결과를 반환한다.  
① 다중행 함수(GROUP BY와 함께 사용하는 SUM, COUNT 등)의 설명  
③ 인수 없이 사용 가능한 함수도 있음 (예: SYSDATE)  
④ SELECT, WHERE, ORDER BY 절 모두에서 사용 가능

---

**[하-02] 답: ②**

`LOWER('ORACLE DATABASE')` → `oracle database`  
- 모든 대문자를 소문자로 변환한다.  
- UPPER는 대문자로, INITCAP은 단어 첫 글자만 대문자로 변환.

---

**[하-03] 답: ③**

`INITCAP('the soap opera')` → `The Soap Opera`  
- 각 단어의 **첫 번째 문자만** 대문자로 변환, 나머지는 소문자.  
- Oracle 전용 함수 (표준 SQL에 없음).

---

**[하-04] 답: ②**

`SUBSTR('HelloWorld', 1, 5)` → `Hello`  
- 위치 1(첫 번째 문자)부터 5글자를 추출.  
- Oracle에서 문자 위치는 **1부터** 시작한다 (0이 아님).

---

**[하-05] 답: ②**

`LENGTH('Oracle')` → `6`  
- O-r-a-c-l-e = 6글자

---

**[하-06] 답: ②**

`INSTR('CORPORATE FLOOR', 'OR')` → `2`  
- C**OR**PORATE FLOOR: 두 번째 문자에서 'OR'이 처음 등장.  
- INSTR은 첫 번째 검색 결과의 위치를 반환한다.

---

**[하-07] 답: ②**

`LPAD(salary, 10, '*')`는 salary 값 **왼쪽**에 `*`를 채워 전체 10자리를 만든다.  
- 예: salary=24000 → `*****24000` (24000은 5자리 → 왼쪽에 * 5개)  
- 오른쪽 채우기는 RPAD, 앞뒤 제거는 TRIM.

---

**[하-08] 답: ②**

`ROUND(45.926, 2)` → `45.93`  
- 소수 둘째 자리까지 반올림: 셋째 자리 6 ≥ 5이므로 올림 → `45.93`

---

**[하-09] 답: ②**

`ROUND(45.5, 0)` → `46`  
- 소수 첫째 자리 5 ≥ 5이므로 올림 → `46`

---

**[하-10] 답: ②**

`TRUNC(45.926, 2)` → `45.92`  
- 소수 둘째 자리에서 **잘라냄(절사)**: 세 번째 자리 이하 제거.  
- ROUND와 달리 반올림하지 않고 버린다.

---

**[하-11] 답: ②**

`MOD(17, 5)` → `2`  
- 17 ÷ 5 = 3 나머지 **2** (5×3=15, 17-15=2)

---

**[하-12] 답: ③**

Oracle의 기본 날짜 표시 형식: `DD-MON-RR`  
- 예: `17-JUN-03` (2003년 6월 17일)  
- RR: 두 자리 연도를 세기로 자동 판별하는 Oracle 형식

---

**[하-13] 답: ②**

`SYSDATE`는 Oracle 서버의 현재 날짜와 시간을 반환한다.  
- 세션 타임존 기준 날짜는 `CURRENT_DATE`  
- `SYSDATE`는 인수가 없으며 FROM dual과 함께 조회 가능

---

**[하-14] 답: ③**

Oracle에서 두 날짜를 빼면 **일 수(Days)**가 반환된다.  
- 예: `SYSDATE - hire_date` → 입사 후 경과 일수  
- 월 수를 구하려면 `MONTHS_BETWEEN` 함수 사용

---

**[하-15] 답: ②**

`CEIL(2.1)` → `3`  
- CEIL: 주어진 수 **이상의 가장 작은 정수** (올림)  
- CEIL(2.1) = 3, CEIL(2.0) = 2, CEIL(-2.1) = -2

---

**[하-16] 답: ③**

`FLOOR(9.9)` → `9`  
- FLOOR: 주어진 수 **이하의 가장 큰 정수** (내림)  
- FLOOR(9.9) = 9, FLOOR(9.0) = 9, FLOOR(-9.1) = -10

---

**[하-17] 답: ③**

`LAST_DAY('15-MAR-23')` → `31-MAR-23`  
- 2023년 3월의 마지막 날은 31일.  
- 2월은 28일(평년) 또는 29일(윤년).

---

**[하-18] 답: ③**

실행 순서: **SUBSTR → CONCAT → UPPER**  
- Step 1: `SUBSTR(last_name, 1, 5)` → last_name의 처음 5글자
- Step 2: `CONCAT(결과, '_KR')` → 5글자 + '_KR'
- Step 3: `UPPER(결과)` → 전체 대문자로 변환

---

**[하-19] 답: ②**

`ADD_MONTHS('31-JAN-23', 1)` → `28-FEB-23`  
- 1월 31일에 1개월을 추가하면 2월 31일인데, 2023년 2월은 28일까지 있으므로 **월말 자동 조정**: `28-FEB-23`

---

**[하-20] 답: ①**

`REPLACE('JACK and JUE', 'J', 'BL')` → `BLACK and BLUE`  
- 모든 'J'를 'BL'로 치환:
  - `JACK` → `BLACK`  
  - `JUE` → `BLUE`

---

# ★★ 중 (응용) 모범답안

---

**[중-01] 답**

```sql
SELECT LOWER(last_name)  AS last_name_lower,
       UPPER(first_name) AS first_name_upper
FROM   employees;
```

---

**[중-02] 답**

```sql
SELECT employee_id, last_name, department_id
FROM   employees
WHERE  LOWER(last_name) = 'higgins';
```

> Oracle은 문자 비교 시 대소문자를 구분한다.  
> `WHERE last_name = 'Higgins'`는 정확히 일치해야 하지만,  
> `WHERE LOWER(last_name) = 'higgins'`는 대소문자와 무관하게 검색된다.

---

**[중-03] 답**

```sql
SELECT last_name,
       CONCAT('Role: ', job_id) AS job_description
FROM   employees
WHERE  department_id = 60;
```

> 결과 예:
> - Hunold → `Role: IT_PROG`
> - Ernst  → `Role: IT_PROG`

---

**[중-04] 답**

```sql
SELECT last_name,
       SUBSTR(last_name, 1, 3) AS first_3
FROM   employees;
```

---

**[중-05] 답**

```sql
SELECT last_name,
       LENGTH(last_name) AS name_length
FROM   employees
WHERE  LENGTH(last_name) >= 6;
```

---

**[중-06] 답**

```sql
SELECT last_name,
       LPAD(salary, 10, '*') AS formatted_salary
FROM   employees;
```

> 예: salary=24000 → `*****24000` (왼쪽에 * 5개 추가)

---

**[중-07] 답**

```sql
SELECT ROUND(123.456, 1),   -- 123.5
       TRUNC(123.456, 1),   -- 123.4
       CEIL(123.4),         -- 124
       FLOOR(123.9)         -- 123
FROM   dual;
```

---

**[중-08] 답**

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  MOD(employee_id, 2) = 1;
```

> `MOD(employee_id, 2) = 1`: 2로 나눈 나머지가 1 → 홀수  
> 짝수는 `MOD(employee_id, 2) = 0`

---

**[중-09] 답**

```sql
SELECT last_name,
       salary,
       ROUND(salary, -2) AS rounded_salary
FROM   employees;
```

> `ROUND(salary, -2)`: 100의 자리 기준 반올림  
> - salary=24000 → 24000 (50 미만 → 그대로)  
> - salary=4400  → 4400  
> - salary=2500  → 2500  
> 십 단위 반올림은 `ROUND(salary, -1)` 사용

---

**[중-10] 답**

```sql
SELECT SYSDATE
FROM   dual;
```

---

**[중-11] 답**

```sql
SELECT last_name,
       ROUND((SYSDATE - hire_date) / 7, 2) AS weeks_worked
FROM   employees
WHERE  department_id = 90;
```

> `(SYSDATE - hire_date)`: 경과 일수  
> `/ 7`: 일수를 7로 나누면 주 수  
> `ROUND(..., 2)`: 소수 둘째 자리까지 표시

---

**[중-12] 답**

```sql
SELECT last_name,
       hire_date,
       ADD_MONTHS(hire_date, 6) AS probation_end
FROM   employees;
```

---

**[중-13] 답**

```sql
SELECT last_name,
       hire_date,
       TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) AS months_worked
FROM   employees;
```

---

**[중-14] 답**

```sql
SELECT last_name,
       hire_date,
       LAST_DAY(hire_date) AS last_of_hire_month
FROM   employees;
```

---

**[중-15] 답**

```sql
SELECT last_name, job_id
FROM   employees
WHERE  SUBSTR(job_id, 4) = 'REP';
```

> 결과: SA_REP, MK_REP, PR_REP 등 job_id 4번째 자리부터 'REP'인 사원  
> `SUBSTR(job_id, 4)`: 4번째 문자부터 끝까지 추출

---

**[중-16] 답**

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  SUBSTR(last_name, -1, 1) = 'n';
```

> `SUBSTR(last_name, -1, 1)`: 마지막 문자 1개 추출  
> 음수 위치는 문자열 끝에서부터 역방향으로 계산

---

**[중-17] 답**

```sql
SELECT last_name,
       UPPER(CONCAT(SUBSTR(last_name, 1, 8), '_KR')) AS code_name
FROM   employees
WHERE  department_id = 60;
```

> 결과 예:
> - Hunold → `HUNOLD_KR`
> - Pataballa → `PATABA_KR` (8글자만 추출)

---

**[중-18] 답**

```sql
SELECT last_name,
       TRIM('H' FROM last_name) AS trimmed_name
FROM   employees
WHERE  last_name LIKE 'H%';
```

> `TRIM('H' FROM last_name)`: last_name 앞뒤에서 'H' 문자를 제거  
> - Higgins → `iggins`  
> - Hartstein → `artstein`  
> 단, TRIM은 앞뒤 양쪽의 지정 문자를 제거 (중간의 'H'는 제거 안 됨)

---

**[중-19] 답**

```sql
SELECT last_name,
       hire_date,
       NEXT_DAY(hire_date, 'FRIDAY') AS next_friday
FROM   employees;
```

> `NEXT_DAY(hire_date, 'FRIDAY')`: hire_date 이후 첫 번째 금요일 날짜 반환

---

**[중-20] 답**

```sql
SELECT last_name,
       salary + 0.5              AS test_value,
       TRUNC(salary + 0.5)      AS truncated,
       ROUND(salary + 0.5)      AS rounded
FROM   employees
WHERE  TRUNC(salary + 0.5) != ROUND(salary + 0.5);
```

> EMPLOYEES의 salary는 모두 정수이므로, `salary + 0.5`를 사용하면  
> ROUND(정수.5)는 올림, TRUNC(정수.5)는 내림으로 차이가 발생한다.

---

# ★★★ 상 (심화) 모범답안

---

**[상-01] 답**

```sql
-- (A) ROUND 결과
SELECT ROUND(45.5, 0), ROUND(46.5, 0), ROUND(47.5, 0)
FROM   dual;
-- 결과: 46, 47, 48

-- (B) TRUNC 결과
SELECT TRUNC(45.5, 0), TRUNC(46.5, 0), TRUNC(47.5, 0)
FROM   dual;
-- 결과: 45, 46, 47
```

> **(1) 각 결과:**
>
> | 함수 | 45.5 | 46.5 | 47.5 |
> |------|------|------|------|
> | ROUND | 46 | 47 | 48 |
> | TRUNC | 45 | 46 | 47 |
>
> **(2) 근본적 차이:**
> - `ROUND`: 지정 자릿수 다음 자리를 기준으로 **반올림** (≥5이면 올림)
> - `TRUNC`: 지정 자릿수 이하를 **모두 버림** (방향에 상관없이)
>
> 음수에서 차이가 더 명확:
> - `ROUND(-45.5, 0)` = -46 (반올림)
> - `TRUNC(-45.5, 0)` = -45 (절사 — 0 방향으로)

---

**[상-02] 답**

오류가 있는 SQL:
```sql
SELECT UPPER(first_name), SUBSTR(last_name, 0, 3),
       LPAD(salary, 8, '0')
FROM   employees
WHERE  INITCAP(department_id) = 60;
```

오류 목록:

| 위치 | 오류 | 수정 |
|------|------|------|
| `SUBSTR(last_name, 0, 3)` | Oracle에서 시작 위치는 **1부터** (0은 1로 처리되지만 표준은 1) | `SUBSTR(last_name, 1, 3)` |
| `INITCAP(department_id)` | `INITCAP`은 **문자열 함수** — 숫자형 department_id에 사용 불가 | `department_id = 60` (함수 제거) |
| `INITCAP(...)= 60` | 함수 적용 시 문자 타입이 되므로 `= '60'`이 맞지만 이 비교 자체가 의미 없음 | `department_id = 60` |

수정된 SQL:
```sql
SELECT UPPER(first_name),
       SUBSTR(last_name, 1, 3),
       LPAD(salary, 8, '0')
FROM   employees
WHERE  department_id = 60;
```

---

**[상-03] 답**

```sql
SELECT employee_id,
       INITCAP(first_name || ' ' || last_name) AS full_name,
       LENGTH(first_name || ' ' || last_name)   AS name_length
FROM   employees
WHERE  LENGTH(first_name || ' ' || last_name) >= 15;
```

> **핵심 포인트:**
> - `first_name || ' ' || last_name`: 공백 포함 이름 결합
> - `INITCAP`: 각 단어 첫 글자 대문자 변환
> - `LENGTH(...)`: WHERE 절에서도 함수 사용 가능
> - CONCAT은 인수 2개만 지원하므로 세 문자열 결합에는 `||`가 편리

---

**[상-04] 답**

```sql
SELECT last_name,
       hire_date,
       TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) AS months_worked,
       CASE
           WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) >= 240 THEN '장기'
           WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) >= 120 THEN '중기'
           ELSE '단기'
       END AS tenure_grade
FROM   employees
ORDER BY hire_date;
```

> **분석:**
> - `MONTHS_BETWEEN(SYSDATE, hire_date)`: 현재부터 입사일까지의 월 수 (양수)
> - `TRUNC(...)`: 소수점 이하 버림 (완전한 월만 계산)
> - 2026년 기준, 1987년 입사자는 약 468개월 → '장기'
> - 2010년 이후 입사자는 약 192개월 미만 → '중기' 또는 '단기'

---

**[상-05] 답**

**(1) 부서 90 사원 출력 결과:**

| LAST_NAME | FORMATTED_SALARY | FORMATTED_JOB |
|-----------|------------------|---------------|
| King | `*****24000` | `AD_PRES-----` |
| Kochhar | `*****17000` | `AD_VP-------` |
| De Haan | `*****17000` | `AD_VP-------` |

- `LPAD(24000, 10, '*')`: 24000은 5자리 → 왼쪽에 * 5개 = `*****24000`
- `RPAD('AD_PRES', 12, '-')`: AD_PRES는 7자리 → 오른쪽에 - 5개 = `AD_PRES-----`
- `RPAD('AD_VP', 12, '-')`: AD_VP는 5자리 → 오른쪽에 - 7개 = `AD_VP-------`

**(2) LPAD vs RPAD 실무 활용:**

| 함수 | 특성 | 실무 예시 |
|------|------|----------|
| LPAD | **오른쪽 정렬** 효과 | 숫자 데이터 정렬, 코드 앞 0 채우기 (사번: LPAD(id,5,'0') → '00100') |
| RPAD | **왼쪽 정렬** 효과 | 텍스트 데이터 가독성, 보고서 열 폭 맞추기 |

---

**[상-06] 답**

| 항목 | `MONTHS_BETWEEN` | `date1 - date2` |
|------|------------------|-----------------|
| 반환 단위 | **월 수** (소수 포함) | **일 수** (소수 포함) |
| 반환 타입 | NUMBER | NUMBER |
| 경계 처리 | 날짜가 월말이면 정수 반환 | 항상 일수 |

**사용 시기:**

```sql
-- MONTHS_BETWEEN: 근속 월수, 계약 기간처럼 "월" 단위가 의미 있을 때
SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) AS근속월수
FROM   employees;

-- 날짜 빼기: 남은 일수, 지연 일수처럼 "일" 단위가 의미 있을 때
SELECT TRUNC(SYSDATE - hire_date) AS근속일수
FROM   employees;
```

> `MONTHS_BETWEEN('01-MAR-23', '01-JAN-23')` = 2.0 (정확한 2개월)  
> `'01-MAR-23' - '01-JAN-23'` = 59 (2023년 1월+2월 = 31+28 일)  
> 같은 기간이지만 반환 단위가 다름에 주의.

---

**[상-07] 답**

```sql
SELECT employee_id,
       last_name,
       CONCAT(SUBSTR(LOWER(last_name), 1, 5),
              LPAD(employee_id, 4, '0'))  AS id_code
FROM   employees
WHERE  INSTR(LOWER(last_name), 'a') > 0
ORDER BY hire_date;
```

> **단계별 설명:**
> 1. `LOWER(last_name)`: 대소문자 구분 없이 처리
> 2. `INSTR(LOWER(last_name), 'a') > 0`: 소문자 'a'가 1개 이상 포함된 경우
> 3. `SUBSTR(LOWER(last_name), 1, 5)`: 소문자로 변환 후 앞 5글자
> 4. `LPAD(employee_id, 4, '0')`: 사번 4자리, 앞에 '0' 채우기
> 5. `CONCAT(...)`: 두 결과 결합

---

**[상-08] 답**

**(1) 실행 순서:**

```
UPPER(CONCAT(SUBSTR(last_name, 1, 8), '_US'))
           ↑
  Step 1: SUBSTR('Pataballa', 1, 8) → 'Pataball'   (8글자 추출)
  Step 2: CONCAT('Pataball', '_US') → 'Pataball_US'
  Step 3: UPPER('Pataball_US')      → 'PATABALL_US'
```

**(2) 최종 결과:** `PATABALL_US`

> 'Pataballa'는 9글자이므로 SUBSTR(1, 8)은 앞 8글자 'Pataball'을 반환.  
> 전체 이름(9글자)이 아닌 8글자만 취한 것이 핵심 포인트.

---

**[상-09] 답**

**(1) 두 식의 차이:**

```sql
(SYSDATE - hire_date) / 365    -- 일수 / 365 (단순 계산)
MONTHS_BETWEEN(...) / 12       -- 정확한 월 수 / 12
```

- **차이 원인:** 1년이 항상 365일이 아니다 (윤년: 366일).  
  `MONTHS_BETWEEN`은 실제 달력의 월 수를 계산하므로 더 정확.  
  날짜 빼기(`/365`)는 윤년을 고려하지 않아 약간의 오차 발생.
- 실무에서는 `MONTHS_BETWEEN / 12`가 더 정확한 연수 계산에 적합.

**(2) 부서 90 사원 근속 연수 예측 (2026년 기준):**

| 사원 | 입사일 | 경과 연수(2026년 기준) |
|------|--------|----------------------|
| King | 87-06-17 | 약 38.9년 |
| Kochhar | 89-09-21 | 약 36.7년 |
| De Haan | 93-01-13 | 약 33.4년 |

---

**[상-10] 답**

```sql
SELECT employee_id,
       last_name,
       hire_date,
       salary,
       ROUND(salary, -3)              AS rounded_salary,
       ADD_MONTHS(hire_date, 12)      AS probation_end
FROM   employees
WHERE  hire_date >= '01-JAN-00'
ORDER BY probation_end;
```

> **설명:**
> - `hire_date >= '01-JAN-00'`: 2000년 1월 1일 이후 입사자 (RR 형식: '00' → 2000년)
> - `ROUND(salary, -3)`: 천 단위에서 반올림 (음수 자릿수 지정)  
>   예: 4400 → 4000, 6200 → 6000, 8600 → 9000
> - `ADD_MONTHS(hire_date, 12)`: 입사일에 12개월 추가 → 수습 완료일
> - 원 질문의 "반올림 급여와 원래 급여의 차이" 추가 시:
>   `ABS(salary - ROUND(salary, -3)) AS diff` 열 추가 가능
