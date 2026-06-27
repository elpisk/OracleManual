# Oracle Database 19c: SQL Workshop
## Chapter 4 — 단일행 함수 | SQL 실습 문제 (sql_sample 참고형)

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources)  
> **범위:** 문자 함수(LOWER/UPPER/INITCAP/CONCAT/SUBSTR/LENGTH/INSTR/LPAD/RPAD/TRIM/REPLACE), 중첩 함수, 숫자 함수(ROUND/TRUNC/CEIL/FLOOR/MOD), 날짜 산술 및 날짜 함수(SYSDATE/MONTHS_BETWEEN/ADD_MONTHS/NEXT_DAY/LAST_DAY)  
> **작성 방식:** 주어진 출력 결과를 보고 SQL 문을 직접 작성하시오.

---

## Group 1. 대소문자 변환 함수 (1~5번)

---

**[1번]** EMPLOYEES 테이블에서 부서 90 사원의 last_name을 대문자, job_id를 소문자로 출력하시오.

```
LAST_NAME_UPPER JOB_LOWER
--------------- ----------
KING            ad_pres
KOCHHAR         ad_vp
DE HAAN         ad_vp
(3개 행)
```

---

**[2번]** EMPLOYEES 테이블에서 모든 사원의 first_name을 각 단어의 첫 글자만 대문자로 출력하시오.  
(단, first_name이 소문자로 저장되어 있다고 가정하고 INITCAP을 적용)

```
EMPLOYEE_ID FIRST_NAME         INITCAP_NAME
----------- ------------------ --------------------
        100 Steven             Steven
        101 Neena              Neena
        102 Lex                Lex
...
```

---

**[3번]** EMPLOYEES 테이블에서 last_name이 대소문자 구분 없이 **'higgins'**인 사원을 조회하시오.  
(LOWER 함수를 WHERE 절에 활용)

```
EMPLOYEE_ID LAST_NAME  DEPARTMENT_ID
----------- ---------- -------------
        205 Higgins              110
(1개 행)
```

---

**[4번]** EMPLOYEES 테이블에서 last_name을 소문자로 변환한 값이 `SUBSTR`로 첫 3글자를 추출할 때 **'kin'**으로 시작하는 사원을 조회하시오.

```
EMPLOYEE_ID LAST_NAME
----------- ----------
        100 King
(1개 행)
```

---

**[5번]** EMPLOYEES 테이블에서 job_id를 소문자로 변환한 값에 **'man'**이 포함된 사원의 last_name과 job_id를 조회하시오.

```
LAST_NAME   JOB_ID
----------- ----------
Hartstein   MK_MAN
Russell     SA_MAN
Partners    SA_MAN
Errazuriz   SA_MAN
Cambrault   SA_MAN
Zlotkey     SA_MAN
(6개 행)
```

---

## Group 2. 문자 조작 함수 (6~11번)

---

**[6번]** EMPLOYEES 테이블에서 first_name과 last_name을 연결하여 전체 이름을 출력하시오.  
(두 이름 사이에 공백 포함, CONCAT 함수 또는 `||` 사용)

```
FULL_NAME
------------------------------
Steven King
Neena Kochhar
Lex De Haan
...
(107개 행)
```

---

**[7번]** EMPLOYEES 테이블에서 last_name의 **처음 5글자**와 employee_id를 연결하여 ID 코드를 생성하시오.  
(형식: last_name 첫 5글자 + employee_id)

```
LAST_NAME  ID_CODE
---------- ----------
King       King_100
Kochhar    Kochh101
De Haan    De Ha102
...
```

---

**[8번]** EMPLOYEES 테이블에서 salary를 전체 10자리로 오른쪽 정렬하고, 빈 자리는 `*`로 채워 출력하시오.  
(LPAD 사용)

```
LAST_NAME  FORMATTED_SALARY
---------- --------------------
King       *****24000
Kochhar    *****17000
De Haan    *****17000
...
```

---

**[9번]** EMPLOYEES 테이블에서 job_id의 오른쪽에 `-`를 채워 전체 15자리로 출력하시오.  
(RPAD 사용)

```
LAST_NAME  FORMATTED_JOB
---------- ---------------
King       AD_PRES--------
Kochhar    AD_VP----------
...
```

---

**[10번]** EMPLOYEES 테이블에서 last_name의 **마지막 문자**가 `'n'`인 사원의 employee_id와 last_name을 조회하시오.  
(SUBSTR 음수 위치 사용)

```
EMPLOYEE_ID LAST_NAME
----------- ----------
        103 Hunold
        127 Landman
        ...
(해당 조건의 사원)
```

---

**[11번]** EMPLOYEES 테이블에서 job_id 내에서 `'_'`(언더스코어)가 처음 나타나는 위치를 출력하시오.  
(INSTR 사용)

```
LAST_NAME  JOB_ID     UNDERSCORE_POS
---------- ---------- --------------
King       AD_PRES             3
Kochhar    AD_VP               3
...
```

---

## Group 3. 중첩 함수 (12~16번)

---

**[12번]** 부서 60 사원의 last_name 앞 8글자에 `'_US'`를 붙인 후 **전체를 대문자**로 변환하여 출력하시오.  
(UPPER, CONCAT, SUBSTR 중첩 사용)

```
LAST_NAME  RESULT
---------- -----------
Hunold     HUNOLD_US
Ernst      ERNST_US
Austin     AUSTIN_US
Pataballa  PATABALL_US
Lorentz    LORENTZ_US
(5개 행)
```

---

**[13번]** EMPLOYEES 테이블에서 last_name과 first_name을 결합한 이름에 INITCAP을 적용하여 출력하시오.  
(INITCAP, CONCAT, `||` 중첩 사용)

```
FORMATTED_NAME
--------------------
Steven King
Neena Kochhar
Lex De Haan
...
```

---

**[14번]** EMPLOYEES 테이블에서 salary를 반올림한 후(백 단위) LPAD로 전체 10자리, 빈 자리는 `0`으로 채워 출력하시오.  
(LPAD, ROUND 중첩 사용)

```
LAST_NAME  FORMATTED_ROUNDED_SALARY
---------- ------------------------
King       0000024000
Kochhar    0000017000
...
```

---

**[15번]** EMPLOYEES 테이블에서 last_name을 소문자로 변환한 후, 첫 번째 문자를 조회하시오.  
(SUBSTR, LOWER 중첩 사용)

```
LAST_NAME  FIRST_CHAR_LOWER
---------- ----------------
King       k
Kochhar    k
De Haan    d
...
```

---

**[16번]** EMPLOYEES 테이블에서 email 주소가 소문자인 사원의 이름과 이메일을 출력하시오.  
(Oracle EMPLOYEES 테이블의 email은 대문자로 저장되어 있으므로, LOWER 변환 후 표시하시오.)

```
LAST_NAME  EMAIL_LOWER
---------- -------------------
King       sking
Kochhar    nkochhar
...
```

---

## Group 4. 숫자 함수 (17~22번)

---

**[17번]** `dual` 테이블을 사용하여 ROUND 함수의 양수/음수 자릿수 동작을 확인하시오.

```sql
-- 아래 결과가 출력되도록 SQL을 작성하시오.
ROUND_2    ROUND_0    ROUND_NEG1    ROUND_NEG2
---------- ---------- ------------- -------------
    123.46        123           120           100
```

(입력값: 123.456)

---

**[18번]** `dual` 테이블을 사용하여 TRUNC 함수의 동작을 확인하시오.

```
TRUNC_2    TRUNC_0    TRUNC_NEG1
---------- ---------- ----------
    123.45        123        120
```

(입력값: 123.456)

---

**[19번]** EMPLOYEES 테이블에서 **사번이 짝수**인 사원의 employee_id와 last_name을 조회하시오.  
(MOD 함수 사용)

```
EMPLOYEE_ID LAST_NAME
----------- ----------
        102 De Haan
        104 Ernst
        106 Pataballa
        108 Greenberg
...
```

---

**[20번]** EMPLOYEES 테이블에서 salary를 **천 단위에서 반올림**한 값과 **천 단위에서 절사**한 값을 함께 출력하시오.

```
LAST_NAME  SALARY ROUNDED_1000 TRUNCATED_1000
---------- ------ ------------ --------------
King        24000        24000          24000
Kochhar     17000        17000          17000
De Haan     17000        17000          17000
...
Abel        11000        11000          11000
...
Marlow       2500         3000           2000
...
```

---

**[21번]** EMPLOYEES 테이블에서 salary를 12로 나눈 **월급의 일당**을 계산하여 소수 2자리까지 반올림하여 출력하시오.

```
LAST_NAME  SALARY DAILY_PAY
---------- ------ ----------
King        24000     657.53
Kochhar     17000     465.75
...
```

> 힌트: 일당 = salary / (365 / 12), 또는 salary * 12 / 365

---

**[22번]** EMPLOYEES 테이블에서 급여의 **올림(CEIL)**과 **내림(FLOOR)** 값을 출력하시오.  
단, 연습을 위해 `salary / 1000 + 0.3`으로 가공된 값에 적용하시오.

```
LAST_NAME  TEST_VAL    CEIL_VAL  FLOOR_VAL
---------- ----------- --------- ---------
King           24.3         25        24
Kochhar        17.3         18        17
...
```

---

## Group 5. 날짜 산술 및 날짜 함수 (23~30번)

---

**[23번]** `dual` 테이블에서 현재 날짜(SYSDATE)를 조회하시오.

```
SYSDATE
--------
27-JUN-26   ← 실행 날짜에 따라 달라짐
```

---

**[24번]** EMPLOYEES 테이블에서 부서 90 사원들의 last_name과 입사 후 경과한 **일수**, **주수**, **연수**를 계산하여 출력하시오.  
(소수 1자리까지 ROUND 처리)

```
LAST_NAME  DAYS_WORKED  WEEKS_WORKED  YEARS_WORKED
---------- ------------ ------------- ------------
King           14260.0       2037.1         39.1
Kochhar        13429.0       1918.4         36.8
De Haan        12219.0       1745.6         33.5
(2026년 기준, 실행 날짜에 따라 달라짐)
```

---

**[25번]** EMPLOYEES 테이블에서 각 사원의 hire_date에 **12개월을 더한 날짜**(수습 완료일)를 출력하시오.  
(ADD_MONTHS 사용)

```
LAST_NAME  HIRE_DATE  PROBATION_END
---------- ---------- -------------
King       87/06/17   88/06/17
Kochhar    89/09/21   90/09/21
De Haan    93/01/13   94/01/13
...
```

---

**[26번]** EMPLOYEES 테이블에서 각 사원의 hire_date로부터 현재까지 경과한 **월 수**를 정수(TRUNC)로 계산하여 출력하시오.  
(MONTHS_BETWEEN 사용)

```
LAST_NAME  HIRE_DATE  MONTHS_WORKED
---------- ---------- -------------
King       87/06/17             468   ← 2026년 기준
Kochhar    89/09/21             441
De Haan    93/01/13             401
...
```

---

**[27번]** EMPLOYEES 테이블에서 hire_date 기준 해당 달의 **마지막 날짜**를 출력하시오.  
(LAST_DAY 사용)

```
LAST_NAME  HIRE_DATE  LAST_OF_MONTH
---------- ---------- -------------
King       87/06/17   87/06/30
Kochhar    89/09/21   89/09/30
De Haan    93/01/13   93/01/31
...
```

---

**[28번]** EMPLOYEES 테이블에서 hire_date 이후 첫 번째 **월요일** 날짜를 출력하시오.  
(NEXT_DAY 사용)

```
LAST_NAME  HIRE_DATE  NEXT_MONDAY
---------- ---------- -----------
King       87/06/17   87/06/22
Kochhar    89/09/21   89/09/25
...
```

---

**[29번]** EMPLOYEES 테이블에서 입사 후 경과 월수를 기준으로 다음 분류를 적용하여 출력하시오.

- 360개월(30년) 이상: '30년+'
- 240개월(20년) 이상: '20~30년'
- 120개월(10년) 이상: '10~20년'
- 나머지: '10년 미만'

출력 열: last_name, hire_date, 경과 월수, 분류  
(MONTHS_BETWEEN, TRUNC, CASE 활용)

```
LAST_NAME  HIRE_DATE  MONTHS_WORKED  GRADE
---------- ---------- -------------- ---------
King       87/06/17             468  30년+
Kochhar    89/09/21             441  30년+
De Haan    93/01/13             401  30년+
...
Landman    99/01/14             330  20~30년
...
```

---

**[30번]** 다음 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항:
- EMPLOYEES 테이블에서 2000년 이후 입사한 사원 (`hire_date >= '01-JAN-00'`)
- first_name과 last_name을 공백으로 결합하여 `full_name` 열 출력
- 급여를 백 단위에서 반올림한 값 출력
- 입사일 기준 수습 완료일(12개월 추가) 출력
- 입사 후 경과 월수(TRUNC) 출력
- 정렬: hire_date 오름차순

```
EMPLOYEE_ID FULL_NAME          SALARY ROUNDED_SALARY HIRE_DATE  PROBATION_END MONTHS_WORKED
----------- ------------------ ------ -------------- ---------- ------------- -------------
        178 Kimberely Grant      7000           7000 00/05/24   01/05/24              312
        ...
(2000년 이후 입사자 목록)
```
