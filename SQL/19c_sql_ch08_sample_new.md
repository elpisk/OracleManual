# Oracle Database 19c: SQL Workshop
## Chapter 8 — 서브쿼리를 활용한 쿼리 작성 | SQL 실습 문제 (sql_sample 참고형)

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources)  
> **범위:** 단일행 서브쿼리, 그룹 함수 서브쿼리, HAVING + 서브쿼리, 다중행(IN/ANY/ALL), 다중열, 인라인 뷰, NOT IN + NULL 처리  
> **작성 방식:** 주어진 출력 결과를 보고 SQL 문을 직접 작성하시오.

---

## Group 1. 단일행 서브쿼리 (1~6번)

---

**[1번]** EMPLOYEES 테이블에서 Davies보다 나중에 입사한 사원의 last_name과 hire_date를 출력하시오.  
(단일행 서브쿼리로 Davies의 hire_date 조회, hire_date 오름차순)

```
LAST_NAME  HIRE_DATE
---------- ----------
Livingston 24-APR-06
Grant      24-MAY-07
Johnson    07-JAN-08
(3개 행)
```

---

**[2번]** EMPLOYEES 테이블에서 Abel과 같은 job_id를 가진 사원(Abel 제외)의 last_name, job_id, salary를 출력하시오.  
(last_name 오름차순)

```
LAST_NAME  JOB_ID  SALARY
---------- ------- ------
Ande       SA_REP    6400
Banda      SA_REP    6200
Bates      SA_REP    7300
...
(29개 행)
```

---

**[3번]** EMPLOYEES 테이블에서 전체 최소 급여를 받는 사원의 last_name, job_id, salary를 출력하시오.

```
LAST_NAME  JOB_ID   SALARY
---------- -------- ------
Olson      ST_CLERK   2100
(1개 행)
```

---

**[4번]** EMPLOYEES 테이블에서 Zlotkey와 같은 부서에 근무하는 사원(Zlotkey 제외)의 last_name, hire_date, salary를 출력하시오.  
(hire_date 오름차순)

```
LAST_NAME   HIRE_DATE   SALARY
----------- ----------- ------
Tucker      30-JAN-05   10000
Bernstein   24-MAR-05    9500
Hall        20-AUG-05    9000
...
```

---

**[5번]** EMPLOYEES 테이블에서 전체 평균 급여보다 높은 급여를 받는 사원의 last_name, salary를 출력하시오.  
(salary 내림차순)

```
LAST_NAME  SALARY
---------- ------
King        24000
Kochhar     17000
De Haan     17000
...
(51개 행)
```

---

**[6번]** EMPLOYEES 테이블에서 Taylor와 직무가 같고 Taylor보다 급여가 많은 사원의 last_name, job_id, salary를 출력하시오.  
(job_id='SA_REP', salary>8600인 사원)

```
LAST_NAME  JOB_ID  SALARY
---------- ------- ------
Tucker     SA_REP   10000
Bernstein  SA_REP    9500
Hall       SA_REP    9000
Olsen      SA_REP    8000
...
```

---

## Group 2. 그룹 함수 서브쿼리 · HAVING (7~12번)

---

**[7번]** EMPLOYEES 테이블에서 부서 50의 최소 급여보다 최소 급여가 높은 부서의 department_id와 최소 급여를 출력하시오.  
(HAVING + 서브쿼리, 부서 번호 오름차순)

```
DEPARTMENT_ID MIN_SALARY
------------- ----------
           20       6000
           30       2500
           60       4800
           80       6100
           90      17000
          100       6900
          110       8300
```

---

**[8번]** EMPLOYEES 테이블에서 전체 평균 급여보다 높은 부서의 department_id와 평균 급여를 출력하시오.  
(HAVING + 서브쿼리, 평균 급여 내림차순)

```
DEPARTMENT_ID AVG_SALARY
------------- ----------
           90      19333
           20       9500
           80       8956
          110       8500
          100       8600
```

---

**[9번]** EMPLOYEES 테이블에서 직무별 사원 수가 부서 80의 사원 수보다 많은 직무를 출력하시오.  
(HAVING + 서브쿼리, job_id 오름차순)

```
JOB_ID      EMP_COUNT
----------- ---------
SA_REP             30
ST_CLERK           20
SH_CLERK           20
```

---

**[10번]** EMPLOYEES 테이블에서 각 부서 최대 급여의 최솟값을 구하시오.  
(서브쿼리를 FROM 절에 사용 — 인라인 뷰)

```
MIN_OF_MAX
----------
      6500
(1개 행)
```

---

**[11번]** EMPLOYEES 테이블에서 부서별 평균 급여를 조회하되, 평균 급여가 전체 평균보다 낮은 부서만 출력하시오.  
(HAVING + 서브쿼리, 평균 급여 오름차순)

```
DEPARTMENT_ID AVG_SALARY
------------- ----------
           50       3476
           30       4150
           10       4400
           40       6500
           70      10000
```

---

**[12번]** EMPLOYEES 테이블에서 직무별 급여 합계가 부서 80 전체 급여 합계의 절반보다 큰 직무를 출력하시오.  
(HAVING + 서브쿼리, 급여 합계 내림차순)

```
JOB_ID      TOTAL_SALARY
----------- ------------
SA_REP        243500
ST_CLERK       55700
...
```

---

## Group 3. 다중행 서브쿼리 (IN / ANY / ALL) (13~18번)

---

**[13번]** EMPLOYEES 테이블에서 관리자인 사원(다른 사원의 manager_id에 존재하는)의 employee_id와 last_name을 출력하시오.  
(IN + 서브쿼리, NULL 처리 필수, employee_id 오름차순)

```
EMPLOYEE_ID LAST_NAME
----------- ----------
        100 King
        101 Kochhar
        102 De Haan
        103 Hunold
        ...
(18개 행)
```

---

**[14번]** EMPLOYEES 테이블에서 관리자가 아닌 사원(다른 사원의 manager_id에 없는)의 last_name을 출력하시오.  
(NOT IN + 서브쿼리, IS NOT NULL 필터 필수, last_name 오름차순)

```
LAST_NAME
----------
Austin
Baida
Banda
...
(89개 행)
```

---

**[15번]** EMPLOYEES 테이블에서 IT_PROG 직무의 어떤 사원보다도 급여가 낮은 사원을 출력하시오.  
(< ANY 사용, job_id ≠ 'IT_PROG', salary 내림차순)

```
EMPLOYEE_ID LAST_NAME  JOB_ID    SALARY
----------- ---------- --------- ------
...급여 < 9000인 사원들 (IT_PROG 제외)
```

---

**[16번]** EMPLOYEES 테이블에서 IT_PROG 직무의 모든 사원보다 급여가 낮은 사원을 출력하시오.  
(< ALL 사용, job_id ≠ 'IT_PROG', salary 내림차순)

```
EMPLOYEE_ID LAST_NAME  JOB_ID    SALARY
----------- ---------- --------- ------
...급여 < 4200인 사원들 (IT_PROG 제외)
```

---

**[17번]** EMPLOYEES 테이블에서 부서 10, 20, 30에 근무하는 사원의 job_id 목록에 포함되는 직무를 가진, 다른 부서 사원을 출력하시오.  
(IN + 서브쿼리, 해당 부서 제외, job_id 오름차순 → last_name 오름차순)

```
LAST_NAME  JOB_ID      DEPARTMENT_ID
---------- ----------- -------------
Higgins    AC_MGR                110
Gietz      AC_ACCOUNT            110
...
```

---

**[18번]** EMPLOYEES 테이블에서 부서 90의 모든 사원보다 급여가 많은 사원을 출력하시오.  
(> ALL 사용, 부서 90 제외, salary 내림차순)

```
EMPLOYEE_ID LAST_NAME  SALARY
----------- ---------- ------
(부서 90의 최대 급여 24000보다 높은 사원 → 없음 또는 0행)
```

> 힌트: 부서 90의 최대 급여는 King의 24000. 24000보다 높은 급여는 없으므로 0행.

---

## Group 4. 다중열 서브쿼리 · 인라인 뷰 (19~24번)

---

**[19번]** EMPLOYEES 테이블에서 각 부서에서 최소 급여를 받는 사원의 first_name, department_id, salary를 출력하시오.  
(다중열 서브쿼리 사용, department_id 오름차순)

```
FIRST_NAME DEPARTMENT_ID SALARY
---------- ------------- ------
Jennifer              10   4400
Pat                   20   6000
Den                   30   2500
Susan                 40   6500
TJ                    50   2100
...
(12개 행)
```

---

**[20번]** EMPLOYEES 테이블에서 각 직무(job_id)에서 가장 최근에 입사한 사원의 last_name, job_id, hire_date를 출력하시오.  
(다중열 서브쿼리 사용, job_id 오름차순)

```
LAST_NAME  JOB_ID      HIRE_DATE
---------- ----------- ----------
Gietz      AC_ACCOUNT  07-JUN-02
Higgins    AC_MGR      07-JUN-02
Whalen     AD_ASST     17-SEP-87
...
```

---

**[21번]** 인라인 뷰(FROM 절 서브쿼리)를 사용하여 부서별 평균 급여와 사원 수를 계산하고, 평균 급여 상위 5개 부서를 출력하시오.

```
DEPARTMENT_ID AVG_SALARY EMP_COUNT
------------- ---------- ---------
           90      19333         3
           20       9500         2
          110       8500         2
          100       8601         6
           80       8956        34
```

---

**[22번]** 인라인 뷰를 사용하여 각 사원의 급여와 부서 평균 급여를 비교하여, 부서 평균보다 급여가 높은 사원을 출력하시오.  
(department_id 오름차순 → salary 내림차순)

```
LAST_NAME   SALARY  DEPT_ID  DEPT_AVG
----------- ------- -------- --------
Whalen         4400      10    4400.00
Hartstein     13000      20    9500.00
...
```

---

**[23번]** EMPLOYEES 테이블에서 부서 50에서 job_id와 manager_id 조합이 부서 80의 어떤 사원과 동일한 사원을 출력하시오.  
(다중열 서브쿼리, (job_id, manager_id) 기준)

```
LAST_NAME  JOB_ID  MANAGER_ID DEPARTMENT_ID
---------- ------- ---------- -------------
...부서 50 사원 중 부서 80과 동일한 (job_id, manager_id) 쌍을 가진 사원
```

---

**[24번]** 인라인 뷰와 ROWNUM을 활용하여 급여 순위 상위 5명(급여 내림차순)의 last_name과 salary를 출력하시오.

```
LAST_NAME  SALARY
---------- ------
King        24000
Kochhar     17000
De Haan     17000
Hartstein   13000
Higgins     12008
(5개 행)
```

---

## Group 5. 종합 응용 (25~30번)

---

**[25번]** EMPLOYEES 테이블에서 Seattle(location_id=1700)에 있는 부서에 근무하는 사원의 last_name과 salary를 출력하시오.  
(중첩 서브쿼리 사용: employees → departments → locations)  
salary 내림차순 정렬.

```
LAST_NAME  SALARY
---------- ------
King        24000
Kochhar     17000
De Haan     17000
...
```

---

**[26번]** EMPLOYEES 테이블에서 각 부서의 최소 급여를 받는 사원 중, 최소 급여가 전체 평균 급여보다 낮은 부서는 제외하고 출력하시오.  
(다중열 서브쿼리 + HAVING 조합 또는 서브쿼리 중첩)  
department_id 오름차순.

```
FIRST_NAME  DEPARTMENT_ID SALARY
----------- ------------- ------
Pat                    20   6000
Den                    30   2500
Susan                  40   6500
...
```

---

**[27번]** 다음 조건을 모두 만족하는 사원을 출력하시오.
- 전체 평균 급여보다 높은 급여
- 관리자인 사원 (다른 사원의 manager_id에 존재)
- 부서가 있는 사원

출력 열: last_name, salary, department_id  
salary 내림차순.

```
LAST_NAME  SALARY  DEPARTMENT_ID
---------- ------- -------------
King        24000             90
Kochhar     17000             90
...
```

---

**[28번]** EMPLOYEES 테이블에서 SELECT 절에 스칼라 서브쿼리를 사용하여 각 사원의 부서 평균 급여와 본인 급여의 차이를 출력하시오.  
(department_id가 없는 사원 제외, 차이 내림차순 정렬, 상위 10행)

```
LAST_NAME  SALARY  DEPT_AVG  DIFF
---------- ------- --------- -----
King        24000     19333   4667
...
```

---

**[29번]** EMPLOYEES 테이블에서 급여 등급 'E'(salary 15000 이상 24999 이하)에 해당하는 사원을 서브쿼리로 조회하시오.  
(JOB_GRADES의 lowest_sal, highest_sal을 서브쿼리로 조회하여 BETWEEN 적용)

```
LAST_NAME  SALARY  JOB_ID
---------- ------- ----------
King        24000  AD_PRES
Kochhar     17000  AD_VP
De Haan     17000  AD_VP
Hartstein   13000  MK_MAN
...
```

---

**[30번]** 다음 종합 요구사항을 하나의 SQL로 작성하시오.

요구사항:
- 부서별 평균 급여를 인라인 뷰로 계산
- 인라인 뷰의 평균 급여가 8,000 이상인 부서만 선택
- 해당 부서에 속한 사원 중 부서 평균보다 급여가 높은 사원 조회
- 출력 열: last_name, salary, department_id, 부서 평균 급여(dept_avg)
- salary 내림차순 정렬

```
LAST_NAME  SALARY  DEPT_ID  DEPT_AVG
---------- ------- ------- ---------
King        24000       90     19333
Kochhar     17000       90     19333
De Haan     17000       90     19333
Hartstein   13000       20      9500
Russell     14000       80      8956
Partners    13500       80      8956
...
```
