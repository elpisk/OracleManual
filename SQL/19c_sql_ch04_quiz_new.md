# Oracle Database 19c: SQL Workshop
## Chapter 4 — 단일행 함수 | 연습문제

> **사용 스키마:** HR (Human Resources)  
> **범위:** 단일행 함수 — 문자(LOWER/UPPER/INITCAP/CONCAT/SUBSTR/LENGTH/INSTR/LPAD/RPAD/TRIM/REPLACE), 중첩 함수, 숫자(ROUND/TRUNC/CEIL/FLOOR/MOD), 날짜(SYSDATE/날짜산술/MONTHS_BETWEEN/ADD_MONTHS/NEXT_DAY/LAST_DAY)

---

# ★ 하 (기초) — 20문제

---

**[하-01]** 단일행 함수(Single-Row Function)의 특성으로 올바른 것은?

① 여러 행을 처리하여 그룹당 하나의 결과를 반환한다  
② 쿼리의 각 행에 대해 실행되어 행마다 하나의 결과를 반환한다  
③ 항상 두 개 이상의 인수가 필요하다  
④ SELECT 절에서만 사용할 수 있다

---

**[하-02]** 다음 함수의 결과로 올바른 것은?

```sql
SELECT LOWER('ORACLE DATABASE')
FROM   dual;
```

① `ORACLE DATABASE`  
② `oracle database`  
③ `Oracle Database`  
④ `Oracle database`

---

**[하-03]** `INITCAP('the soap opera')` 의 실행 결과는?

① `THE SOAP OPERA`  
② `the soap opera`  
③ `The Soap Opera`  
④ `The soap opera`

---

**[하-04]** 다음 함수의 결과로 올바른 것은?

```sql
SELECT SUBSTR('HelloWorld', 1, 5)
FROM   dual;
```

① `HelloW`  
② `Hello`  
③ `World`  
④ `elloW`

---

**[하-05]** `LENGTH('Oracle')` 의 결과는?

① `5`  
② `6`  
③ `7`  
④ `8`

---

**[하-06]** `INSTR('CORPORATE FLOOR', 'OR')` 의 결과는?

① `1`  
② `2`  
③ `3`  
④ `5`

---

**[하-07]** `LPAD(salary, 10, '*')` 의 설명으로 올바른 것은?

① salary 값 오른쪽에 `*`를 채워 전체 10자리를 만든다  
② salary 값 왼쪽에 `*`를 채워 전체 10자리를 만든다  
③ salary 값 앞뒤에서 `*` 문자를 제거한다  
④ salary 값을 10자리 숫자로 변환한다

---

**[하-08]** `ROUND(45.926, 2)` 의 결과는?

① `45.92`  
② `45.93`  
③ `46.00`  
④ `45.90`

---

**[하-09]** `ROUND(45.5, 0)` 의 결과는?

① `45`  
② `46`  
③ `45.5`  
④ `44`

---

**[하-10]** `TRUNC(45.926, 2)` 의 결과는?

① `45.93`  
② `45.92`  
③ `46.00`  
④ `45.90`

---

**[하-11]** `MOD(17, 5)` 의 결과는?

① `3`  
② `2`  
③ `4`  
④ `1`

---

**[하-12]** Oracle의 기본 날짜 표시 형식은?

① `YYYY-MM-DD`  
② `MM/DD/YYYY`  
③ `DD-MON-RR`  
④ `DD/MM/YY`

---

**[하-13]** `SYSDATE` 함수에 대한 설명으로 올바른 것은?

① 세션의 타임존 기준 현재 날짜만 반환한다  
② Oracle 서버의 현재 날짜와 시간을 반환한다  
③ 사용자가 지정한 날짜를 반환한다  
④ 항상 UTC 기준 날짜와 시간을 반환한다

---

**[하-14]** Oracle에서 두 날짜를 빼면 어떤 결과가 반환되는가?

① 월 수  
② 시간 수  
③ 일 수  
④ 연 수

---

**[하-15]** `CEIL(2.1)` 의 결과는?

① `2`  
② `3`  
③ `2.1`  
④ `2.2`

---

**[하-16]** `FLOOR(9.9)` 의 결과는?

① `10`  
② `9.9`  
③ `9`  
④ `8`

---

**[하-17]** `LAST_DAY('15-MAR-23')` 의 결과는?

① `28-FEB-23`  
② `30-MAR-23`  
③ `31-MAR-23`  
④ `01-APR-23`

---

**[하-18]** 중첩 함수에서 `UPPER(CONCAT(SUBSTR(last_name, 1, 5), '_KR'))` 의 실행 순서로 올바른 것은?

① UPPER → CONCAT → SUBSTR  
② CONCAT → SUBSTR → UPPER  
③ SUBSTR → CONCAT → UPPER  
④ UPPER → SUBSTR → CONCAT

---

**[하-19]** `ADD_MONTHS('31-JAN-23', 1)` 의 결과는?

① `01-MAR-23`  
② `28-FEB-23`  
③ `31-FEB-23` (오류 발생)  
④ `01-FEB-23`

---

**[하-20]** `REPLACE('JACK and JUE', 'J', 'BL')` 의 결과는?

① `BLACK and BLUE`  
② `JACK and BLUE`  
③ `BLACK and JUE`  
④ `BLack and BLue`

---

# ★★ 중 (응용) — 20문제

---

**[중-01]** EMPLOYEES 테이블에서 모든 사원의 last_name을 소문자로, first_name을 대문자로 출력하는 SQL 문을 작성하시오.

---

**[중-02]** EMPLOYEES 테이블에서 last_name이 정확히 'higgins'인 사원을 대소문자 구분 없이 조회하는 SQL 문을 작성하시오. (LOWER 함수 활용)

---

**[중-03]** EMPLOYEES 테이블에서 부서 60 사원의 last_name과 job_id를 조회하되, job_id 앞에 'Role: ' 문자열을 붙여서 출력하시오. (CONCAT 사용)

---

**[중-04]** EMPLOYEES 테이블에서 last_name의 첫 번째 문자부터 3글자를 추출하여 출력하시오. (SUBSTR 사용)

---

**[중-05]** EMPLOYEES 테이블에서 last_name의 길이(LENGTH)를 구하고, 길이가 6 이상인 사원의 last_name과 길이를 조회하시오.

---

**[중-06]** EMPLOYEES 테이블에서 salary를 오른쪽 정렬하여 전체 10자리, 빈 자리는 `*`로 채워 출력하시오. (LPAD 사용)

---

**[중-07]** `dual` 테이블을 사용하여 다음 숫자 함수 결과를 한 행으로 출력하시오.

- `ROUND(123.456, 1)`
- `TRUNC(123.456, 1)`
- `CEIL(123.4)`
- `FLOOR(123.9)`

---

**[중-08]** EMPLOYEES 테이블에서 employee_id가 홀수인 사원의 employee_id와 last_name을 조회하시오. (MOD 사용)

---

**[중-09]** EMPLOYEES 테이블에서 salary를 십 단위에서 반올림한 값을 출력하시오. (ROUND 사용, 음수 자릿수 활용)

---

**[중-10]** `dual` 테이블에서 현재 날짜(SYSDATE)를 조회하시오.

---

**[중-11]** EMPLOYEES 테이블에서 부서 90 사원들의 last_name과 입사 후 경과한 **주(Weeks) 수**를 계산하여 출력하시오.  
(소수 2자리까지만 표시 — ROUND 사용)

---

**[중-12]** EMPLOYEES 테이블에서 입사일(hire_date)에 6개월을 추가한 날짜를 조회하시오. (ADD_MONTHS 사용)  
출력 열: last_name, hire_date, ADD_MONTHS 결과

---

**[중-13]** EMPLOYEES 테이블에서 각 사원의 입사일부터 현재까지 경과한 **월 수**를 계산하여 정수(TRUNC)로 출력하시오. (MONTHS_BETWEEN 사용)

---

**[중-14]** EMPLOYEES 테이블에서 각 사원의 hire_date 기준 **해당 달의 마지막 날짜**를 출력하시오. (LAST_DAY 사용)

---

**[중-15]** EMPLOYEES 테이블에서 job_id의 4번째 문자부터 끝까지 추출하여, 추출 결과가 'REP'인 사원의 last_name과 job_id를 조회하시오.

---

**[중-16]** EMPLOYEES 테이블에서 last_name의 마지막 글자가 'n'인 사원의 employee_id와 last_name을 조회하시오.  
(힌트: `SUBSTR(last_name, -1, 1)` 활용)

---

**[중-17]** EMPLOYEES 테이블에서 부서 60 사원의 last_name 앞 8글자에 `'_KR'`을 붙인 후 전체를 대문자로 출력하시오.  
(중첩 함수 사용: UPPER, CONCAT, SUBSTR)

---

**[중-18]** EMPLOYEES 테이블에서 `TRIM('H' FROM last_name)` 을 적용하여 last_name이 'H'로 시작하는 사원의 이름에서 앞의 'H'를 제거한 결과를 출력하시오.  
출력 열: last_name, TRIM 적용 결과

---

**[중-19]** EMPLOYEES 테이블에서 hire_date가 속한 달의 다음 금요일 날짜를 구하시오. (NEXT_DAY 사용)

---

**[중-20]** EMPLOYEES 테이블에서 salary에서 소수점 이하를 모두 제거한 값(TRUNC)과 반올림한 값(ROUND)이 서로 다른 행을 찾으시오. (salary가 정수가 아닌 경우)  
힌트: EMPLOYEES의 salary는 정수이므로 `salary + 0.5`를 사용하여 연습하시오.

---

# ★★★ 상 (심화) — 10문제

---

**[상-01]** 다음 두 SQL 문의 결과를 비교하고 차이가 발생하는 이유를 설명하시오.

```sql
-- (A)
SELECT ROUND(45.5, 0), ROUND(46.5, 0), ROUND(47.5, 0)
FROM   dual;

-- (B)
SELECT TRUNC(45.5, 0), TRUNC(46.5, 0), TRUNC(47.5, 0)
FROM   dual;
```

(1) 각 결과를 예측하시오.  
(2) ROUND와 TRUNC의 근본적인 차이를 설명하시오.

---

**[상-02]** 다음 SQL 문에서 오류를 모두 찾아 수정하시오.

```sql
SELECT UPPER(first_name), SUBSTR(last_name, 0, 3),
       LPAD(salary, 8, '0')
FROM   employees
WHERE  INITCAP(department_id) = 60;
```

---

**[상-03]** EMPLOYEES 테이블에서 다음 조건을 모두 만족하는 결과를 출력하시오.

- 사원 이름(first_name + ' ' + last_name)을 하나의 열로 표시 (CONCAT 또는 `||` 사용)
- 이름 전체를 INITCAP으로 변환
- 이름 길이가 15자 이상인 사원만 조회
- 출력: 사번, 변환된 이름, 이름 길이

---

**[상-04]** EMPLOYEES 테이블에서 다음을 계산하는 SQL 문을 작성하시오.

- 각 사원의 입사일(hire_date)로부터 현재까지 **경과한 월 수**를 소수점 이하 버림으로 계산
- 월 수를 기준으로 근속 기간 분류:
  - 240개월(20년) 이상: '장기'
  - 120개월(10년) 이상: '중기'
  - 나머지: '단기'
- 출력: last_name, hire_date, 경과 월 수, 분류

> 분류 조건은 CASE 없이 논리적으로 생각하고, 가능하다면 CASE를 활용하시오.

---

**[상-05]** 다음 SQL 문의 실행 결과를 분석하시오.

```sql
SELECT last_name,
       LPAD(salary, 10, '*')    AS formatted_salary,
       RPAD(job_id, 12, '-')    AS formatted_job
FROM   employees
WHERE  department_id = 90;
```

(1) 부서 90 사원 3명(King: salary=24000/job_id=AD_PRES, Kochhar: 17000/AD_VP, De Haan: 17000/AD_VP)의 출력 결과를 구체적으로 예측하시오.  
(2) LPAD와 RPAD의 차이를 실무 활용 관점에서 설명하시오.

---

**[상-06]** `MONTHS_BETWEEN` 함수와 날짜 빼기 연산(`date1 - date2`)의 차이를 설명하고, 각각 언제 사용하면 적합한지 예를 들어 설명하시오.

---

**[상-07]** EMPLOYEES 테이블에서 아래 요구사항을 만족하는 SQL 문을 작성하시오.

요구사항:
- last_name에서 소문자 'a'가 포함된 사원 조회 (대소문자 구분 없이 — LOWER 활용)
- 사원의 last_name 앞 5글자 + 사원번호 4자리(LPAD로 앞에 '0' 채우기)를 결합하여 ID 코드를 생성
- 출력 열: employee_id, last_name, 생성한 ID 코드
- 입사일 오름차순 정렬

---

**[상-08]** 다음 중첩 함수의 실행 결과를 단계별로 분석하시오. (EMPLOYEES 테이블의 last_name = 'Pataballa' 사원 기준)

```sql
SELECT UPPER(CONCAT(SUBSTR(last_name, 1, 8), '_US'))
FROM   employees
WHERE  last_name = 'Pataballa';
```

(1) 각 함수가 실행되는 순서를 단계별로 나열하시오.  
(2) 최종 결과 값을 예측하시오.

---

**[상-09]** EMPLOYEES 테이블에서 다음 조건을 분석하고 결과를 예측하시오.

```sql
SELECT last_name,
       ROUND((SYSDATE - hire_date) / 365, 1) AS years,
       TRUNC(MONTHS_BETWEEN(SYSDATE, hire_date)) AS months
FROM   employees
WHERE  department_id = 90
ORDER BY hire_date;
```

(1) `(SYSDATE - hire_date) / 365`와 `MONTHS_BETWEEN(SYSDATE, hire_date) / 12` 는 근사적으로 같은 값인가? 차이가 발생한다면 그 이유를 설명하시오.  
(2) 부서 90 사원 3명(King: 87-06-17, Kochhar: 89-09-21, De Haan: 93-01-13 입사)의 근속 연수를 대략적으로 예측하시오. (현재 2026년 기준)

---

**[상-10]** 다음 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항:
- EMPLOYEES 테이블에서 조회
- 2000년 이후 입사 사원 (hire_date >= '01-JAN-00')
- 급여(salary)를 천 단위에서 반올림한 값 계산
- 반올림 급여와 원래 급여의 차이를 절대값으로 계산 (ABS 또는 ROUND 활용)
- 입사일에 12개월을 추가한 날짜(수습 완료일) 계산
- 출력 열: employee_id, last_name, hire_date, salary, 반올림급여, 수습완료일
- 정렬: 수습완료일 오름차순
