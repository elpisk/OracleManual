# Oracle Database 19c: SQL Workshop
## Chapter 9 — 집합 연산자 사용 | SQL 실습 문제 (sql_sample 참고형)

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources)  
> **사용 테이블:** EMPLOYEES, JOB_HISTORY, DEPARTMENTS, LOCATIONS, JOBS  
> **범위:** UNION, UNION ALL, INTERSECT, MINUS, 열 일치, ORDER BY  
> **작성 방식:** 주어진 출력 결과를 보고 SQL 문을 직접 작성하시오.
>
> ※ 교재의 `retired_employees` 가상 테이블 대신 HR 스키마의 `JOB_HISTORY` 테이블을 활용한다.

---

## Group 1. UNION / UNION ALL (1~6번)

---

**[1번]** EMPLOYEES 테이블의 job_id와 JOB_HISTORY 테이블의 job_id를 합쳐 고유한 직무 목록을 출력하시오.  
(중복 제거, job_id 오름차순)

```
JOB_ID
-----------
AC_ACCOUNT
AC_MGR
AD_ASST
AD_PRES
AD_VP
FI_ACCOUNT
FI_MGR
HR_REP
IT_PROG
MK_MAN
MK_REP
PR_REP
PU_CLERK
PU_MAN
SA_MAN
SA_REP
SH_CLERK
ST_CLERK
ST_MAN
(19개 행)
```

---

**[2번]** EMPLOYEES의 job_id와 JOB_HISTORY의 job_id를 합쳐 **중복 포함** 전체 목록을 출력하시오.  
(job_id 오름차순)

```
JOB_ID
-----------
AC_ACCOUNT
AC_MGR
AD_ASST
AD_PRES
AD_VP
AD_VP
FI_ACCOUNT
FI_ACCOUNT
...
(117개 행, 중복 포함)
```

---

**[3번]** EMPLOYEES 테이블의 department_id와 DEPARTMENTS 테이블의 department_id를 UNION으로 합쳐 고유 부서 번호 목록을 출력하시오.  
(department_id 오름차순)

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
          120
          130
          140
          150
          160
          170
          180
          190
          200
          210
          220
          230
          240
          250
          260
          270
(27개 행)
```

---

**[4번]** EMPLOYEES 테이블에서 부서 20, 30, 40에 근무하는 사원의 last_name, department_id를 각각 조회하여 UNION ALL로 합치시오.  
(중복 포함 전체 출력, department_id 오름차순)

```
LAST_NAME        DEPARTMENT_ID
---------------- -------------
Hartstein                   20
Fay                         20
Raphaely                    30
Khoo                        30
Baida                       30
Tobias                      30
Himuro                      30
Colmenares                  30
Marvis                      40
(9개 행, 중복 포함)
```

---

**[5번]** 다음 두 집합을 UNION으로 결합하시오:
- 집합 A: EMPLOYEES에서 job_id가 'SA_REP'인 사원의 employee_id, last_name, salary
- 집합 B: EMPLOYEES에서 job_id가 'IT_PROG'인 사원의 employee_id, last_name, salary

(salary 내림차순)

```
EMPLOYEE_ID LAST_NAME        SALARY
----------- ---------------- ------
        150 Tucker            10000
        156 King               9000
        151 Bernstein          9500
...
(34개 행)
```

---

**[6번]** 다음 두 집합을 UNION으로 결합하여 현재와 과거의 직무-부서 조합을 고유하게 출력하시오:  
- EMPLOYEES: employee_id, job_id, department_id  
- JOB_HISTORY: employee_id, job_id, department_id  
(employee_id 오름차순)

```
EMPLOYEE_ID JOB_ID      DEPARTMENT_ID
----------- ----------- -------------
        100 AD_PRES                90
        101 AC_ACCOUNT             110
        101 AC_MGR                 110
        101 AD_VP                  90
...
```

---

## Group 2. INTERSECT (7~12번)

---

**[7번]** EMPLOYEES와 JOB_HISTORY 테이블에서 **공통으로 나타나는 employee_id**를 조회하시오.  
(즉, 직무 변경 이력이 있는 사원, employee_id 오름차순)

```
EMPLOYEE_ID
-----------
        101
        102
        114
        122
        176
        200
        201
        202
(10개 행)
```

---

**[8번]** EMPLOYEES와 JOB_HISTORY 양쪽 모두에 존재하는 **(employee_id, job_id)** 조합을 출력하시오.  
(현재 직무와 과거 직무가 동일한 경우, employee_id 오름차순)

```
EMPLOYEE_ID JOB_ID
----------- -----------
        176 SA_REP
(1개 행)
```

---

**[9번]** EMPLOYEES와 DEPARTMENTS 테이블에서 **공통으로 나타나는 department_id**를 조회하시오.  
(두 테이블 모두에 존재하는 부서 번호, 오름차순)

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
(11개 행)
```

---

**[10번]** EMPLOYEES 테이블에서 부서 50 또는 80에 근무하는 사원의 job_id와, JOB_HISTORY의 job_id가 **공통으로 나타나는** job_id를 조회하시오.  
(INTERSECT 사용, job_id 오름차순)

```
JOB_ID
-----------
SA_REP
SH_CLERK
ST_CLERK
(3개 행)
```

---

**[11번]** 다음 두 집합의 교집합을 구하시오:  
- 집합 A: EMPLOYEES에서 salary >= 8000인 사원의 employee_id  
- 집합 B: JOB_HISTORY에 이력이 있는 사원의 employee_id  
(employee_id 오름차순)

```
EMPLOYEE_ID
-----------
        101
        102
        114
        201
(4개 행)
```

---

**[12번]** EMPLOYEES와 JOB_HISTORY에서 **공통 department_id**를 조회하시오.  
(두 테이블 모두에 나타나는 부서 번호, 오름차순)

```
DEPARTMENT_ID
-------------
           20
           50
           60
           80
           90
          100
          110
(7개 행)
```

---

## Group 3. MINUS (13~18번)

---

**[13번]** EMPLOYEES에는 있지만 JOB_HISTORY에는 없는 **employee_id**를 조회하시오.  
(직무 변경 이력이 없는 사원, employee_id 오름차순)

```
EMPLOYEE_ID
-----------
        100
        103
        104
        107
        ...
(97개 행)
```

---

**[14번]** JOB_HISTORY에는 있지만 현재 EMPLOYEES에는 없는 **employee_id**를 조회하시오.  
(JOB_HISTORY 기준 employee_id 오름차순)

```
EMPLOYEE_ID
-----------
(결과 없음 — JOB_HISTORY의 모든 employee_id가 현재도 재직 중)
```

---

**[15번]** DEPARTMENTS에는 있지만 EMPLOYEES에는 소속 사원이 없는 **department_id**를 조회하시오.  
(빈 부서 번호, department_id 오름차순)

```
DEPARTMENT_ID
-------------
          120
          130
          140
          150
          160
          170
          180
          190
          200
          210
          220
          230
          240
          250
          260
          270
(16개 행)
```

---

**[16번]** EMPLOYEES에서 관리자 역할을 하는 사원(다른 사원의 manager_id로 등장)과 그렇지 않은 사원을 구분하여, **관리자가 아닌 사원의 employee_id**를 출력하시오.  
(MINUS 사용, IS NOT NULL 필터 포함, employee_id 오름차순)

```
EMPLOYEE_ID
-----------
        103
        104
        107
        109
        ...
(89개 행)
```

---

**[17번]** EMPLOYEES의 job_id 목록에서 JOB_HISTORY에 나타난 적 있는 job_id를 제거하여, **JOB_HISTORY에 한 번도 등장하지 않은 현직 job_id**를 출력하시오.  
(job_id 오름차순)

```
JOB_ID
-----------
AD_PRES
HR_REP
MK_REP
PR_REP
PU_MAN
SA_MAN
SH_CLERK
ST_MAN
(8개 행)
```

---

**[18번]** EMPLOYEES 부서 90의 사원 employee_id 집합에서 EMPLOYEES 부서 80의 manager_id 집합을 제거하여, **부서 90 사원 중 부서 80의 관리자가 아닌 사원의 employee_id**를 출력하시오.

```
EMPLOYEE_ID
-----------
        102
(1개 행)
```

---

## Group 4. 열 일치 · ORDER BY (19~24번)

---

**[19번]** 다음 두 집합을 UNION으로 결합하되, 열 개수와 타입을 맞추시오:
- 집합 A: EMPLOYEES에서 employee_id, last_name, hire_date (DATE 타입)
- 집합 B: JOB_HISTORY에서 employee_id, job_id, start_date (DATE 타입)

(employee_id 오름차순)

```
EMPLOYEE_ID LAST_NAME/JOB_ID    HIRE_DATE
----------- ------------------- ----------
        100 King                 17-JUN-87
        101 Kochhar              21-SEP-89
        101 AC_ACCOUNT           28-OCT-97
        101 AC_MGR               28-OCT-97
...
```

---

**[20번]** 다음 두 집합을 UNION으로 결합하여 location_id와 관련 정보를 출력하시오:
- 집합 A: DEPARTMENTS에서 location_id, department_name "Name", `TO_CHAR(NULL)` "City"
- 집합 B: LOCATIONS에서 location_id, `TO_CHAR(NULL)` "Name", city

(location_id 오름차순)

```
LOCATION_ID NAME                           CITY
----------- ------------------------------ --------
       1000                                Roma
       1100                                Venice
       1200                                Tokyo
       1300                                Hiroshima
       1400                                Southlake
       1500                                South San Francisco
       1600                                South Brunswick
       1700 Accounting
       1700 Administration
       1700 Benefits
       ...
```

---

**[21번]** EMPLOYEES의 job_id와 JOBS 테이블의 job_id를 UNION으로 결합하되, 두 번째 열로 각각 'EMPLOYEE' / 'MASTER'라는 구분 레이블을 추가하시오.  
(job_id 오름차순)

```
JOB_ID       SOURCE
----------- --------
AC_ACCOUNT   EMPLOYEE
AC_ACCOUNT   MASTER
AC_MGR       EMPLOYEE
AC_MGR       MASTER
...
```

---

**[22번]** 다음 세 집합을 UNION ALL로 결합하고 salary 내림차순으로 정렬하시오:
- EMPLOYEES에서 부서 90 사원의 employee_id, last_name, salary
- EMPLOYEES에서 부서 80 관리자(job_id='SA_MAN')의 employee_id, last_name, salary
- EMPLOYEES에서 부서 100 사원의 employee_id, last_name, salary

```
EMPLOYEE_ID LAST_NAME        SALARY
----------- ---------------- ------
        100 King              24000
        101 Kochhar           17000
        102 De Haan           17000
        145 Russell           14000
        146 Partners          13500
        ...
```

---

**[23번]** EMPLOYEES와 JOB_HISTORY에서 job_id를 UNION으로 합치되, 결과를 **두 번째 열의 내림차순**으로 정렬하시오.  
(단, 두 번째 열로 각각 현재 재직자 수/이력 수를 COUNT로 추가)

힌트:
```sql
SELECT job_id, COUNT(*) AS cnt FROM employees GROUP BY job_id
UNION
SELECT job_id, COUNT(*) AS cnt FROM job_history GROUP BY job_id
ORDER BY 2 DESC;
```

```
JOB_ID       CNT
----------- ----
SA_REP        30
ST_CLERK      20
SH_CLERK      20
...
```

---

**[24번]** UNION을 사용하여 다음 두 집합을 결합하고, 열 이름을 'EMP_ID', 'POSITION', 'DEPT' 형식으로 출력하시오:
- EMPLOYEES에서 employee_id, job_id, department_id (department_id IS NOT NULL인 사원)
- JOB_HISTORY에서 employee_id, job_id, department_id

(employee_id 오름차순)

```
EMP_ID POSITION    DEPT
------ ----------- ----
   100 AD_PRES       90
   101 AC_ACCOUNT   110
   101 AC_MGR       110
   101 AD_VP         90
   102 IT_PROG       60
   102 AD_VP         90
...
```

---

## Group 5. 종합 응용 (25~30번)

---

**[25번]** 다음 요구사항을 집합 연산자로 구현하시오:

"현재 EMPLOYEES에서 salary > 10000인 사원의 employee_id 목록에서 JOB_HISTORY에 이력이 있는 employee_id를 제거하여, 고연봉이면서 직무 변경이 없었던 사원의 employee_id를 출력하시오."

(employee_id 오름차순)

```
EMPLOYEE_ID
-----------
        100
        108
        145
        146
        168
        174
(6개 행)
```

---

**[26번]** INTERSECT와 MINUS를 조합하여 다음을 구현하시오:

"JOB_HISTORY에 이력이 있는 사원 중, 현재 EMPLOYEES에서 salary >= 10000인 사원의 employee_id를 출력하시오."

힌트: (JOB_HISTORY employee_id INTERSECT salary>=10000인 EMPLOYEES employee_id)

```
EMPLOYEE_ID
-----------
        101
        102
        201
(3개 행)
```

---

**[27번]** 다음 세 가지 직무 그룹을 UNION ALL로 통합하고, 각 그룹에 구분 레이블을 붙여 salary 내림차순으로 출력하시오:

- 그룹 'MGR': job_id가 '_MAN' 또는 '_MGR'로 끝나는 사원 (LIKE 사용)
- 그룹 'EXEC': job_id IN ('AD_PRES', 'AD_VP')
- 그룹 'PROF': job_id IN ('IT_PROG', 'FI_ACCOUNT', 'HR_REP')

출력 열: group_label, last_name, job_id, salary

```
GROUP_LABEL LAST_NAME    JOB_ID   SALARY
----------- ------------ -------- ------
EXEC        King         AD_PRES   24000
EXEC        Kochhar      AD_VP     17000
EXEC        De Haan      AD_VP     17000
MGR         Hartstein    MK_MAN    13000
...
```

---

**[28번]** 다음 요구사항을 구현하시오:

"EMPLOYEES 테이블에서 부서별 최대 급여를 받는 사원의 employee_id 집합과, JOB_HISTORY에 이력이 있는 사원의 employee_id 집합의 교집합을 구하시오."  
(부서별 최대 급여 사원이면서 직무 변경 이력이 있는 사원, employee_id 오름차순)

힌트: 부서별 MAX(salary) 서브쿼리 활용

```
EMPLOYEE_ID
-----------
        101
        114
        201
(3개 행)
```

---

**[29번]** 다음 SQL을 완성하여, DEPARTMENTS에는 있지만 EMPLOYEES에 소속 사원이 없는 부서의 **department_id와 department_name**을 출력하시오.  
(MINUS 후 DEPARTMENTS에서 JOIN 또는 서브쿼리)

```
DEPARTMENT_ID DEPARTMENT_NAME
------------- ---------------
          120 Treasury
          130 Corporate Tax
          140 Control And Credit
          150 Shareholder Services
          160 Benefits
          170 Manufacturing
          180 Construction
          190 Contracting
          200 Operations
          210 IT Support
          220 NOC
          230 IT Helpdesk
          240 Government Sales
          250 Retail Sales
          260 Recruiting
          270 Payroll
(16개 행)
```

---

**[30번]** 다음 종합 요구사항을 하나의 SQL로 작성하시오:

요구사항:
- EMPLOYEES와 JOB_HISTORY의 모든 (employee_id, job_id, department_id) 조합을 UNION으로 합침
- 단, 현재 EMPLOYEES에서 salary < 5000인 사원의 employee_id는 MINUS로 제거
- 최종 결과를 employee_id 오름차순으로 정렬
- 출력 열: employee_id, job_id, department_id

```
EMPLOYEE_ID JOB_ID       DEPARTMENT_ID
----------- ------------ -------------
        100 AD_PRES                 90
        101 AC_ACCOUNT             110
        101 AC_MGR                 110
        101 AD_VP                   90
        102 AD_VP                   90
        102 IT_PROG                 60
        ...
(고연봉 사원 및 이들의 JOB_HISTORY 이력 포함)
```

> 힌트:
> ```sql
> (SELECT employee_id, job_id, department_id FROM employees
>  UNION
>  SELECT employee_id, job_id, department_id FROM job_history)
> MINUS
> SELECT employee_id, job_id, department_id FROM employees
> WHERE  salary < 5000;
> ```
