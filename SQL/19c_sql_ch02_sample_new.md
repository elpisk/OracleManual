# Oracle Database 19c: SQL Workshop
## Chapter 2 — SQL 실습 문제 (sql_sample 참고형)

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources)  
> **범위:** Chapter 2 — SELECT 문, 산술 표현식, NULL, 열 별칭, 연결 연산자, DISTINCT, DESCRIBE, dual  
> **작성 방식:** 주어진 출력 결과를 보고 SQL 문을 직접 작성하시오.

---

## Group 1. SELECT 기본 조회 (1~5번)

---

**[1번]** EMPLOYEES 테이블의 **모든 열**과 모든 행을 조회하시오.

```
EMPLOYEE_ID FIRST_NAME  LAST_NAME  EMAIL    PHONE_NUMBER         HIRE_DATE JOB_ID     SALARY COMMISSION_PCT MANAGER_ID DEPARTMENT_ID
----------- ----------- ---------- -------- -------------------- --------- ---------- ------ -------------- ---------- -------------
        100 Steven      King       SKING    515.123.4567         87/06/17  AD_PRES     24000                               90
        101 Neena       Kochhar    NKOCHHAR 515.123.4568         89/09/21  AD_VP       17000                         100    90
        102 Lex         De Haan    LDEHAAN  515.123.4569         93/01/13  AD_VP       17000                         100    90
        103 Alexander   Hunold     AHUNOLD  590.423.4567         90/01/03  IT_PROG      9000                         102    60
        104 Bruce       Ernst      BERNST   590.423.4568         91/05/21  IT_PROG      6000                         103    60
...
(107개 행)
```

---

**[2번]** 1번 결과에서 **사번(employee_id), 성(last_name), 직무코드(job_id), 월급(salary)** 4개 열만 조회하시오.

```
EMPLOYEE_ID LAST_NAME  JOB_ID         SALARY
----------- ---------- ---------- ----------
        100 King       AD_PRES         24000
        101 Kochhar    AD_VP           17000
        102 De Haan    AD_VP           17000
        103 Hunold     IT_PROG          9000
        104 Ernst      IT_PROG          6000
...
(107개 행)
```

---

**[3번]** 2번 결과에 **입사일(hire_date)** 열을 추가하여 조회하시오.

```
EMPLOYEE_ID LAST_NAME  JOB_ID     HIRE_DATE      SALARY
----------- ---------- ---------- --------- ----------
        100 King       AD_PRES    87/06/17       24000
        101 Kochhar    AD_VP      89/09/21       17000
        102 De Haan    AD_VP      93/01/13       17000
        103 Hunold     IT_PROG    90/01/03        9000
        104 Ernst      IT_PROG    91/05/21        6000
...
(107개 행)
```

---

**[4번]** DEPARTMENTS 테이블의 모든 열을 조회하시오.

```
DEPARTMENT_ID DEPARTMENT_NAME    MANAGER_ID LOCATION_ID
------------- ------------------ ---------- -----------
           10 Administration            200        1700
           20 Marketing                 201        1800
           30 Purchasing                114        1700
           40 Human Resources           203        2400
           50 Shipping                  121        1500
           60 IT                        103        1400
...
(27개 행)
```

---

**[5번]** JOBS 테이블에서 **직무코드(job_id), 직무명(job_title), 최저급여(min_salary), 최고급여(max_salary)** 를 조회하시오.

```
JOB_ID     JOB_TITLE                          MIN_SALARY MAX_SALARY
---------- ---------------------------------- ---------- ----------
AC_ACCOUNT Accountant                               4200       9000
AC_MGR     Accounting Manager                       8200      16000
AD_ASST    Administration Assistant                 3000       6000
AD_PRES    President                               20080      40000
AD_VP      Administration Vice President           15000      30000
FI_ACCOUNT Accountant                               4200       9000
...
(19개 행)
```

---

## Group 2. DESCRIBE 명령어 (6~7번)

---

**[6번]** EMPLOYEES 테이블의 **열 이름, 데이터 타입, NULL 허용 여부**를 확인하는 명령어를 작성하시오.  
아래 결과를 참고하여 **NOT NULL 제약이 있는 열**을 모두 나열하시오.

```
Name           Null?    Type
-------------- -------- -------------------
EMPLOYEE_ID    NOT NULL NUMBER(6)
FIRST_NAME              VARCHAR2(20)
LAST_NAME      NOT NULL VARCHAR2(25)
EMAIL          NOT NULL VARCHAR2(25)
PHONE_NUMBER            VARCHAR2(20)
HIRE_DATE      NOT NULL DATE
JOB_ID         NOT NULL VARCHAR2(10)
SALARY                  NUMBER(8,2)
COMMISSION_PCT          NUMBER(2,2)
MANAGER_ID              NUMBER(6)
DEPARTMENT_ID           NUMBER(4)
```

---

**[7번]** DEPARTMENTS 테이블의 구조를 확인하시오.  
아래 결과를 보고 **NULL 값을 허용하는 열**을 모두 나열하시오.

```
Name            Null?    Type
--------------- -------- -------------------
DEPARTMENT_ID   NOT NULL NUMBER(4)
DEPARTMENT_NAME NOT NULL VARCHAR2(30)
MANAGER_ID               NUMBER(6)
LOCATION_ID              NUMBER(4)
```

---

## Group 3. 산술 표현식 (8~12번)

---

**[8번]** EMPLOYEES 테이블에서 성(last_name), 월급(salary), **월급에 300을 더한 값**을 조회하시오.  
세 번째 열에 별칭을 지정하지 **않았을 때** 열 머리글이 어떻게 표시되는지 확인하시오.

```
LAST_NAME  SALARY SALARY+300
---------- ------ ----------
King        24000      24300
Kochhar     17000      17300
De Haan     17000      17300
Hunold       9000       9300
Ernst        6000       6300
...
(107개 행)
```

---

**[9번]** 8번 결과에서 세 번째 열을 **연봉(salary × 12)** 으로 변경하시오.

```
LAST_NAME  SALARY SALARY*12
---------- ------ ---------
King        24000    288000
Kochhar     17000    204000
De Haan     17000    204000
Hunold       9000    108000
Ernst        6000     72000
...
(107개 행)
```

---

**[10번]** EMPLOYEES 테이블에서 성(last_name), 월급(salary), 아래 두 가지 계산 결과를 **같은 쿼리**에서 조회하시오.

- `12 * salary + 100`
- `12 * (salary + 100)`

두 결과가 다른 이유를 설명하시오.

```
LAST_NAME  SALARY 12*SALARY+100 12*(SALARY+100)
---------- ------ ------------- ---------------
King        24000        288100          289200
Kochhar     17000        204100          205200
De Haan     17000        204100          205200
Hunold       9000        108100          109200
Ernst        6000         72100           73200
...
(107개 행)
```

---

**[11번]** EMPLOYEES 테이블에서 성(last_name), 월급(salary), **월급을 일급으로 환산**한 값 (`salary / 30`)을 조회하시오.

```
LAST_NAME  SALARY SALARY/30
---------- ------ ---------
King        24000       800
Kochhar     17000    566.667
De Haan     17000    566.667
Hunold       9000       300
Ernst        6000       200
...
(107개 행)
```

---

**[12번]** EMPLOYEES 테이블에서 성(last_name), 사번(employee_id), **사번에 10을 곱하고 100을 뺀 값**을 조회하시오.

```
LAST_NAME  EMPLOYEE_ID EMPLOYEE_ID*10-100
---------- ----------- ------------------
King               100                900
Kochhar            101                910
De Haan            102                920
Hunold             103                930
Ernst              104                940
...
(107개 행)
```

---

## Group 4. NULL 값 (13~15번)

---

**[13번]** EMPLOYEES 테이블에서 성(last_name), 월급(salary), 커미션율(commission_pct),  
**연간 커미션(`12 * salary * commission_pct`)** 을 조회하시오.  
커미션율이 NULL인 사원의 연간 커미션 열에 어떤 값이 출력되는지 확인하시오.

```
LAST_NAME  SALARY COMMISSION_PCT 12*SALARY*COMMISSION_PCT
---------- ------ -------------- ------------------------
King        24000                
Kochhar     17000                
De Haan     17000                
Hunold       9000                
Ernst        6000                
...
Russell     14000            0.4                  67200
Partners    13500            0.3                  48600
Errazuriz   12000            0.3                  43200
...
(107개 행)
```

---

**[14번]** 13번 결과와 비교하기 위해, 동일한 테이블에서 아래 두 열을 함께 조회하시오.  
두 결과의 차이를 설명하시오.

- `salary * 0` (월급에 0을 곱한 값)
- `salary + NULL` (월급에 NULL을 더한 값)

```
LAST_NAME  SALARY SALARY*0 SALARY+NULL
---------- ------ -------- -----------
King        24000        0            
Kochhar     17000        0            
De Haan     17000        0            
Hunold       9000        0            
Ernst        6000        0            
...
(107개 행)
```

---

**[15번]** dual 테이블을 사용하여 다음 세 가지 NULL 관련 산술을 확인하시오.

- `100 + NULL`
- `NULL * 0`
- `NULL + NULL`

```
100+NULL NULL*0 NULL+NULL
-------- ------ ---------
                          
(1개 행, 세 열 모두 NULL)
```

---

## Group 5. 열 별칭 (16~20번)

---

**[16번]** 9번 쿼리(salary * 12)에 **`AS annual_sal`** 별칭을 추가하시오.  
열 머리글이 어떻게 변경되는지 확인하시오.

```
LAST_NAME  SALARY ANNUAL_SAL
---------- ------ ----------
King        24000     288000
Kochhar     17000     204000
De Haan     17000     204000
Hunold       9000     108000
Ernst        6000      72000
...
(107개 행)
```

---

**[17번]** 16번 쿼리에서 `AS`를 **제거하고** `annual_sal` 만 남기시오.  
결과가 동일한지 확인하시오.

```
LAST_NAME  SALARY ANNUAL_SAL
---------- ------ ----------
King        24000     288000
Kochhar     17000     204000
...
(107개 행, 16번과 동일)
```

---

**[18번]** EMPLOYEES 테이블에서 아래 열 머리글이 **정확히** 표시되도록 SQL을 작성하시오.  
(공백 포함, 한글, 대소문자 정확히 일치해야 함)

```
Employee Name        Annual Salary     커미션율
-------------------- ----------------- --------
King                        288000           
Kochhar                     204000           
De Haan                     204000           
Hunold                      108000           
Ernst                        72000           
...
Russell                     168000        0.4
...
(107개 행)
```

---

**[19번]** EMPLOYEES 테이블에서 아래와 같이 **세 가지 별칭 형식**을 혼합하여 조회하시오.

```
name       월급   ANNUAL_SAL DAILY_SAL
---------- ------ ---------- ---------
King        24000     288000       800
Kochhar     17000     204000    566.667
De Haan     17000     204000    566.667
Hunold       9000     108000       300
Ernst        6000      72000       200
...
```

- `last_name AS name` → 열 머리글: `NAME`
- `salary AS "월급"` → 열 머리글: `월급`
- `salary * 12 annual_sal` → 열 머리글: `ANNUAL_SAL`
- `salary / 30 daily_sal` → 열 머리글: `DAILY_SAL`

---

**[20번]** JOBS 테이블에서 아래 출력 결과가 나오도록 SQL을 작성하시오.  
`max_salary - min_salary`를 계산하여 **`급여범위`** 별칭으로 표시하시오.

```
직무코드   직무명                             최저급여   최고급여   급여범위
---------- ---------------------------------- ---------- ---------- ----------
AC_ACCOUNT Accountant                               4200       9000       4800
AC_MGR     Accounting Manager                       8200      16000       7800
AD_ASST    Administration Assistant                 3000       6000       3000
AD_PRES    President                               20080      40000      19920
AD_VP      Administration Vice President           15000      30000      15000
...
(19개 행)
```

---

## Group 6. 연결 연산자와 리터럴 (21~25번)

---

**[21번]** EMPLOYEES 테이블에서 `last_name`과 `job_id`를 `||` 연산자로 연결하여  
**`Employees`** 별칭으로 조회하시오. (사이에 아무것도 넣지 않음)

```
Employees
------------------
KingAD_PRES
KochharAD_VP
De HaanAD_VP
HunoldIT_PROG
ErnstIT_PROG
...
(107개 행)
```

---

**[22번]** 21번 결과에서 `last_name`과 `job_id` 사이에 **` is a `** 를 추가하시오.  
별칭은 **`Employee Details`** 로 지정하시오.

```
Employee Details
---------------------------
King is a AD_PRES
Kochhar is a AD_VP
De Haan is a AD_VP
Hunold is a IT_PROG
Ernst is a IT_PROG
...
(107개 행)
```

---

**[23번]** EMPLOYEES 테이블에서 아래 형식으로 출력되도록 SQL을 작성하시오.

```
사원 정보
--------------------------------------------
사번: 100  이름: Steven King  부서: 90
사번: 101  이름: Neena Kochhar  부서: 90
사번: 102  이름: Lex De Haan  부서: 90
사번: 103  이름: Alexander Hunold  부서: 60
사번: 104  이름: Bruce Ernst  부서: 60
...
(107개 행)
```

---

**[24번]** DEPARTMENTS 테이블에서 `q''` 대체 따옴표 연산자를 사용하여  
아래 형식으로 출력되도록 SQL을 작성하시오.

```
부서 및 매니저 정보
-------------------------------------------
Administration Department's Manager: 200
Marketing Department's Manager: 201
Purchasing Department's Manager: 114
Human Resources Department's Manager: 203
Shipping Department's Manager: 121
IT Department's Manager: 103
...
(27개 행)
```

---

**[25번]** 24번 쿼리를 확장하여 아래 형식으로 출력되도록 SQL을 작성하시오.  
`q''` 연산자를 사용하며, 위치 ID(location_id)도 함께 포함하시오.

```
부서 정보
-------------------------------------------------------------
Administration Department's Manager: 200, Location: 1700
Marketing Department's Manager: 201, Location: 1800
Purchasing Department's Manager: 114, Location: 1700
Human Resources Department's Manager: 203, Location: 2400
Shipping Department's Manager: 121, Location: 1500
...
(27개 행)
```

---

## Group 7. DISTINCT (26~28번)

---

**[26번]** EMPLOYEES 테이블에서 **중복을 포함한** 직무코드(job_id)를 조회하는 SQL과,  
**중복을 제거한** 직무코드를 조회하는 SQL을 각각 작성하고 결과 행 수를 비교하시오.

```
-- 중복 포함 (107개 행)
JOB_ID
----------
AD_PRES
AD_VP
AD_VP
IT_PROG
IT_PROG
...

-- 중복 제거 (19개 행)
JOB_ID
----------
AC_ACCOUNT
AC_MGR
AD_ASST
AD_PRES
AD_VP
FI_ACCOUNT
FI_MGR
HR_REP
IT_PROG
...
```

---

**[27번]** EMPLOYEES 테이블에서 **중복 없이** `department_id`를 조회하시오.  
NULL 값도 포함되는지 확인하시오.

```
DEPARTMENT_ID
-------------
           10
           20
           30
           40
           50
           60
           70
           80
           90
          100
          110
             
(12개 행 — NULL 포함)
```

---

**[28번]** EMPLOYEES 테이블에서 **`job_id`와 `department_id` 두 열의 조합**이 중복되지 않도록 조회하시오.  
단일 열 DISTINCT와 결과 행 수를 비교하시오.

```
JOB_ID         DEPARTMENT_ID
----------     -------------
AC_ACCOUNT               100
AC_MGR                   100
AD_ASST                   10
AD_PRES                   90
AD_VP                     90
FI_ACCOUNT               100
FI_MGR                   100
HR_REP                    40
IT_PROG                   60
MK_MAN                    20
MK_REP                    20
PR_REP                    70
PU_CLERK                  30
PU_MAN                    30
SA_MAN                    80
SA_REP                    80
SH_CLERK                  50
ST_CLERK                  50
ST_MAN                    50
(19개 행)
```

---

## Group 8. dual 테이블과 종합 (29~30번)

---

**[29번]** `dual` 테이블을 사용하여 아래 세 가지 표현식을 **한 번의 쿼리**로 조회하시오.

```
현재날짜   계산결과1 계산결과2
---------- --------- ---------
26/06/27       36525      1200
```

- 첫 번째 열: 오늘 날짜 (SYSDATE), 별칭 `현재날짜`
- 두 번째 열: `100 * 365 + 25` (윤년 100년 일수), 별칭 `계산결과1`
- 세 번째 열: `(200 + 100) * 4`, 별칭 `계산결과2`

---

**[30번]** EMPLOYEES 테이블에서 아래 결과를 출력하는 SQL 문을 작성하시오.  
(Chapter 2에서 배운 모든 기법 활용: 특정 열 선택, 산술 표현식, 열 별칭, 연결 연산자, 리터럴 문자열)

```
사번   성명                  직무정보                            기본급  연봉      일급
------ --------------------- ----------------------------------- ------- --------- ---------
   100 Steven King           Steven King 의 직무: AD_PRES         24000    288000       800
   101 Neena Kochhar         Neena Kochhar 의 직무: AD_VP          17000    204000  566.667
   102 Lex De Haan           Lex De Haan 의 직무: AD_VP            17000    204000  566.667
   103 Alexander Hunold      Alexander Hunold 의 직무: IT_PROG      9000    108000       300
   104 Bruce Ernst           Bruce Ernst 의 직무: IT_PROG           6000     72000       200
...
(107개 행)
```

- `employee_id` → 별칭 `사번`
- `first_name || ' ' || last_name` → 별칭 `성명`
- `first_name || ' ' || last_name || ' 의 직무: ' || job_id` → 별칭 `직무정보`
- `salary` → 별칭 `기본급`
- `salary * 12` → 별칭 `연봉`
- `salary / 30` → 별칭 `일급`
