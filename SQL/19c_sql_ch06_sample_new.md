# Oracle Database 19c: SQL Workshop
## Chapter 6 — 그룹 함수 | SQL 실습 문제 (sql_sample 참고형)

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources)  
> **범위:** COUNT/AVG/SUM/MIN/MAX, DISTINCT, NULL 처리, GROUP BY, 다중 열 GROUP BY, HAVING, 그룹 함수 중첩, LISTAGG  
> **작성 방식:** 주어진 출력 결과를 보고 SQL 문을 직접 작성하시오.

---

## Group 1. 그룹 함수 기본 (1~6번)

---

**[1번]** EMPLOYEES 테이블에서 전체 사원의 최대 급여, 최소 급여, 평균 급여(정수), 급여 합계를 출력하시오.

```
MAX_SALARY MIN_SALARY AVG_SALARY SUM_SALARY
---------- ---------- ---------- ----------
     24000       2100       6462     691416
(1개 행)
```

---

**[2번]** EMPLOYEES 테이블에서 전체 사원 수와 commission_pct가 있는 사원 수를 함께 출력하시오.

```
TOTAL_COUNT WITH_COMM_COUNT
----------- ---------------
        107              35
(1개 행)
```

---

**[3번]** EMPLOYEES 테이블에서 알파벳 순서 첫 번째와 마지막 last_name, 최초 입사일과 최근 입사일을 출력하시오.

```
FIRST_NAME LAST_NAME  EARLIEST_HIRE LATEST_HIRE
---------- ---------- ------------- -----------
Abel       Zlotkey    87/06/17      08/04/21
(1개 행)
```

---

**[4번]** EMPLOYEES 테이블에서 직무에 'REP'가 포함된 사원들의 급여 통계를 출력하시오.

```
AVG_SAL    MAX_SAL    MIN_SAL    SUM_SAL
---------- ---------- ---------- ----------
  8272.727      11500       6000     272000
(1개 행)
```

> `WHERE job_id LIKE '%REP%'` 조건 사용

---

**[5번]** EMPLOYEES 테이블에서 서로 다른 department_id의 수(NULL 제외)와 서로 다른 job_id의 수를 출력하시오.

```
UNIQUE_DEPTS UNIQUE_JOBS
------------ -----------
          11          19
(1개 행)
```

---

**[6번]** EMPLOYEES 테이블에서 commission_pct를 그냥 평균 낸 값과 NVL로 0을 대체한 후 평균 낸 값을 비교하시오.

```
AVG_COMM_EXCL_NULL   AVG_COMM_INCL_NULL
-------------------- --------------------
              .2229                .07285
(1개 행)
```

> 힌트: `ROUND(..., 4)` 적용

---

## Group 2. GROUP BY 단일 열 (7~12번)

---

**[7번]** EMPLOYEES 테이블에서 부서별 사원 수를 출력하시오.  
부서 번호 오름차순 정렬, NULL 부서 포함.

```
DEPARTMENT_ID  EMP_COUNT
-------------  ---------
                       1
           10          1
           20          2
           30          6
           40          1
           50         45
           60          5
           70          1
           80         34
           90          3
          100          6
          110          2
(12개 행)
```

---

**[8번]** EMPLOYEES 테이블에서 부서별 평균 급여를 출력하시오.  
평균 급여 내림차순 정렬.

```
DEPARTMENT_ID  AVG_SALARY
-------------  ----------
           90       19333
          100       8600.3
           80       8955.9
           20        9500
           10        4400
           30        4150
           ...
(12개 행)
```

---

**[9번]** EMPLOYEES 테이블에서 직무별 사원 수를 출력하시오.  
사원 수 내림차순 → 직무 오름차순 정렬.

```
JOB_ID      EMP_COUNT
----------  ---------
ST_CLERK           20
SA_REP             30
...
(19개 행)
```

---

**[10번]** EMPLOYEES 테이블에서 manager_id별 부하 직원 수를 출력하시오.  
(manager_id가 NULL인 행 제외, 부하 직원 수 내림차순 정렬)

```
MANAGER_ID  SUBORDINATE_COUNT
----------  -----------------
       100                 14
       101                  5
       ...
```

---

**[11번]** EMPLOYEES 테이블에서 입사 연도별 사원 수를 출력하시오.  
(`TO_CHAR(hire_date, 'YYYY')` 활용, 연도 오름차순 정렬)

```
HIRE_YEAR  EMP_COUNT
---------  ---------
1987               1
1989               2
1990               2
...
```

---

**[12번]** EMPLOYEES 테이블에서 부서별 최소 입사일과 최대 입사일을 출력하시오.  
부서 번호 오름차순 정렬.

```
DEPARTMENT_ID  EARLIEST_HIRE  LATEST_HIRE
-------------  -------------  -----------
           10  87/09/17       87/09/17
           20  87/02/17       96/02/17
           30  94/08/07       99/12/07
           ...
```

---

## Group 3. HAVING 절 (13~18번)

---

**[13번]** EMPLOYEES 테이블에서 최대 급여가 10,000을 초과하는 부서만 출력하시오.

```
DEPARTMENT_ID  MAX_SALARY
-------------  ----------
           20       13000
           80       14000
           90       24000
          100       12008
          110       12008
```

---

**[14번]** EMPLOYEES 테이블에서 사원 수가 5명 이상인 부서의 부서 번호와 사원 수를 출력하시오.  
사원 수 내림차순 정렬.

```
DEPARTMENT_ID  EMP_COUNT
-------------  ---------
           50         45
           80         34
          100          6
           30          6
           60          5
```

---

**[15번]** EMPLOYEES 테이블에서 'REP'가 포함되지 않는 직무 중 급여 합계가 13,000을 초과하는 직무를 출력하시오.  
급여 합계 오름차순 정렬.

```
JOB_ID      PAYROLL
----------  -------
AC_ACCOUNT    8300
PU_CLERK     13900
ST_CLERK     55700
...
```

---

**[16번]** EMPLOYEES 테이블에서 부서별 평균 급여가 8,000 이상인 부서만 출력하시오.  
평균 급여 내림차순 정렬.

```
DEPARTMENT_ID  AVG_SALARY
-------------  ----------
           90       19333
           20        9500
           80        8956
          110        8500
          100        8600
```

---

**[17번]** EMPLOYEES 테이블에서 최소 급여가 5,000 이상인 부서를 출력하시오.  
부서 번호 오름차순 정렬.

```
DEPARTMENT_ID  MIN_SALARY
-------------  ----------
           60        4800
           80        6100
           90       17000
          100        6900
          110        8300
```

> 힌트: HAVING MIN(salary) >= 5000

---

**[18번]** EMPLOYEES 테이블에서 직무별 사원 수가 3명 이상인 직무를 출력하시오.  
사원 수 내림차순, 직무 오름차순 정렬.

```
JOB_ID      EMP_COUNT
----------  ---------
ST_CLERK          20
SA_REP            30
ST_MAN             5
IT_PROG            5
...
```

---

## Group 4. 다중 열 GROUP BY (19~24번)

---

**[19번]** EMPLOYEES 테이블에서 부서별, 직무별 사원 수를 출력하시오.  
부서 번호 > 40 조건, 부서 번호 오름차순 → 직무 오름차순 정렬.

```
DEPARTMENT_ID  JOB_ID      EMP_COUNT
-------------  ----------  ---------
           50  SH_CLERK           20
           50  ST_CLERK           20
           50  ST_MAN              5
           60  IT_PROG             5
           80  SA_MAN              5
           80  SA_REP             29
           ...
```

---

**[20번]** EMPLOYEES 테이블에서 부서별, 직무별 급여 합계를 출력하시오.  
부서 번호 오름차순 → 급여 합계 내림차순 정렬.

```
DEPARTMENT_ID  JOB_ID      TOTAL_SALARY
-------------  ----------  ------------
           10  AD_ASST             4400
           20  MK_MAN             13000
           20  MK_REP              6000
           30  PU_MAN             11000
           30  PU_CLERK           13900
           ...
```

---

**[21번]** EMPLOYEES 테이블에서 입사 연도별, 부서별 사원 수를 출력하시오.  
(`TO_CHAR(hire_date, 'YYYY')` 활용, 연도 오름차순 → 부서 번호 오름차순)

```
HIRE_YEAR  DEPARTMENT_ID  EMP_COUNT
---------  -------------  ---------
1987                  20          1
1987                  90          1
1989                  60          1
1989                  90          1
...
```

---

**[22번]** EMPLOYEES 테이블에서 부서별, 관리자별 사원 수를 출력하시오.  
manager_id가 NULL인 행 제외, 부서 번호 오름차순 → manager_id 오름차순 정렬.

```
DEPARTMENT_ID  MANAGER_ID  EMP_COUNT
-------------  ----------  ---------
           10         101          1
           20         100          1
           20         201          1
           30         100          1
           30         114          5
           ...
```

---

**[23번]** EMPLOYEES 테이블에서 부서별, 직무별 평균 급여를 출력하시오.  
부서 80과 60만 대상, 평균 급여 내림차순 정렬.

```
DEPARTMENT_ID  JOB_ID      AVG_SALARY
-------------  ----------  ----------
           60  IT_PROG           5760
           80  SA_MAN           12200
           80  SA_REP        8396.552
```

---

**[24번]** EMPLOYEES 테이블에서 부서별, 직무별 그룹 중 사원 수가 2명 이상인 그룹만 출력하시오.  
부서 번호 오름차순 → 사원 수 내림차순.

```
DEPARTMENT_ID  JOB_ID      EMP_COUNT
-------------  ----------  ---------
           30  PU_CLERK             5
           50  SH_CLERK            20
           50  ST_CLERK            20
           50  ST_MAN               5
           60  IT_PROG              5
           80  SA_MAN               5
           80  SA_REP              29
          100  FI_ACCOUNT           6
```

---

## Group 5. 그룹 함수 중첩 & 종합 응용 (25~30번)

---

**[25번]** EMPLOYEES 테이블에서 부서별 평균 급여 중 최대값을 출력하시오.  
(그룹 함수 중첩 사용)

```
MAX_OF_AVG_SALARY
-----------------
            19333
(1개 행)
```

---

**[26번]** EMPLOYEES 테이블에서 부서별 평균 급여 중 최솟값을 출력하시오.

```
MIN_OF_AVG_SALARY
-----------------
             3475
(1개 행)
```

---

**[27번]** EMPLOYEES 테이블에서 부서 20의 사원 이름(last_name)을 쉼표와 공백(`, `)으로 연결하여 하나의 문자열로 출력하시오.  
(LISTAGG 함수 사용, 알파벳 순 정렬)

```
DEPARTMENT_ID  EMPLOYEES_LIST
-------------  ---------------------------
           20  Fay, Hartstein
(1개 행)
```

---

**[28번]** EMPLOYEES 테이블에서 부서별 사원 이름 목록을 LISTAGG로 출력하시오.  
부서 번호 50과 60만 대상, 알파벳 순 정렬.

```
DEPARTMENT_ID  EMPLOYEES_LIST
-------------  ------------------------------------------------
           50  Alana, Alex, Anthony, Britney, ...
           60  Alexander, Bruce, David, Diana, Valli
(2개 행)
```

---

**[29번]** 다음 조건을 모두 만족하는 보고서를 출력하시오.

- 부서 번호가 20, 50, 60, 80, 90 중 하나
- 각 부서의 급여 합계가 50,000 이상
- 출력 열: department_id, 사원 수, 평균 급여(정수 반올림), 최대 급여, 최소 급여, 급여 합계
- 평균 급여 내림차순 정렬

```
DEPT  EMP_COUNT  AVG_SAL  MAX_SAL  MIN_SAL  SUM_SAL
----  ---------  -------  -------  -------  -------
  90          3    19333    24000    17000    58000
  80         34     8956    14000     6100   304900
  60          5     5760     9000     4800    28800
  50         45     3476     8200     2100   156400
```

---

**[30번]** EMPLOYEES 테이블에서 다음 종합 보고서를 출력하시오.

조건:
- salary > 2000인 사원만 대상
- 부서별, 직무별 그룹화
- 그룹의 급여 합계가 5,000 이상인 그룹만 포함
- 출력 열: department_id, job_id, 사원 수, 급여 합계, 평균 급여(정수)
- 부서 번호 오름차순 → 급여 합계 내림차순 정렬

```
DEPT  JOB_ID      CNT  SUM_SAL  AVG_SAL
----  ----------  ---  -------  -------
  10  AD_ASST       1     4400     4400
  20  MK_MAN        1    13000    13000
  20  MK_REP        1     6000     6000
  30  PU_CLERK      5    13900     2780
  30  PU_MAN        1    11000    11000
  50  SH_CLERK     20    64300     3215
  50  ST_CLERK      1     2500     2500
  50  ST_MAN        5    36400     7280
  60  IT_PROG       5    28800     5760
  80  SA_MAN        5    61000    12200
  80  SA_REP       29   243900     8410
  90  AD_PRES       1    24000    24000
  90  AD_VP         2    34000    17000
 100  FI_ACCOUNT    6    51608     8601
 110  AC_ACCOUNT    1     8300     8300
 110  AC_MGR        1    12008    12008
```
