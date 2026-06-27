# Oracle Database 19c: SQL Workshop
## Chapter 7 — 다중 테이블 데이터 조회: JOIN | SQL 실습 문제 (sql_sample 참고형)

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources)  
> **범위:** Natural Join, USING 절, ON 절, Self-Join, Nonequijoin, LEFT/RIGHT/FULL OUTER JOIN, CROSS JOIN, 3방향 조인  
> **작성 방식:** 주어진 출력 결과를 보고 SQL 문을 직접 작성하시오.

---

## Group 1. Natural Join · USING 절 (1~6번)

---

**[1번]** EMPLOYEES와 DEPARTMENTS 테이블을 NATURAL JOIN으로 조인하여 department_id, department_name, location_id를 출력하시오.  
(고유한 조합만, 정렬 없음)

```
DEPARTMENT_ID DEPARTMENT_NAME    LOCATION_ID
------------- ------------------ -----------
           10 Administration            1700
           20 Marketing                 1800
           30 Purchasing                1700
           40 Human Resources           2400
           50 Shipping                  1500
           60 IT                        1400
           ...
(11개 행)
```

> 힌트: NATURAL JOIN은 두 테이블의 공통 열(department_id, manager_id 등) 모두 기준으로 조인한다.  
> EMPLOYEES에 없는 부서는 제외된다.

---

**[2번]** EMPLOYEES와 DEPARTMENTS를 USING(department_id)으로 조인하여 last_name, department_name을 출력하시오.  
(last_name 오름차순 정렬)

```
LAST_NAME  DEPARTMENT_NAME
---------- ------------------
Abel       Sales
Ande       Sales
Atkinson   Shipping
Austin     IT
Baer       Public Relations
...
(106개 행)
```

---

**[3번]** EMPLOYEES와 DEPARTMENTS, LOCATIONS를 USING 절로 연속 조인하여 last_name, department_name, city를 출력하시오.  
(ON 대신 USING 활용, city 오름차순 → last_name 오름차순)

```
LAST_NAME  DEPARTMENT_NAME     CITY
---------- ------------------- --------------------
Gietz      Accounting          Seattle
Higgins    Accounting          Seattle
...
King       Executive           Seattle
...
(106개 행)
```

---

**[4번]** EMPLOYEES와 DEPARTMENTS를 USING(department_id)으로 조인하되, department_id가 50 또는 80인 부서의 사원만 출력하시오.  
출력 열: last_name, department_id, department_name  
last_name 오름차순 정렬.

```
LAST_NAME  DEPARTMENT_ID DEPARTMENT_NAME
---------- ------------- ------------------
Abel                  80 Sales
Ande                  80 Sales
Atkinson              50 Shipping
...
```

---

**[5번]** LOCATIONS와 DEPARTMENTS를 USING(location_id)으로 조인하여 city별 부서 이름을 출력하시오.  
city 오름차순 → department_name 오름차순 정렬.

```
CITY                   DEPARTMENT_NAME
---------------------- ------------------
London                 Human Resources
Munich                 Executive (HR)
Oxford                 Finance
...
Seattle                Accounting
Seattle                Executive
...
```

---

**[6번]** EMPLOYEES와 JOBS를 USING(job_id)으로 조인하여 job_title별 최대 급여(max_salary)와 실제 최고 수령 급여를 비교하시오.  
출력 열: job_title, max_salary(jobs), MAX(salary)(employees)  
job_title 오름차순 정렬.

```
JOB_TITLE                   MAX_SAL  ACTUAL_MAX
--------------------------- -------- ----------
Accountant                    9000       8300
Accounting Manager            16000     12008
Administration Assistant      6000       4400
...
```

---

## Group 2. ON 절 조인 · 3방향 조인 (7~12번)

---

**[7번]** EMPLOYEES와 DEPARTMENTS를 ON 절로 조인하여 사원의 employee_id, last_name, department_id(employees), department_id(departments), location_id를 출력하시오.  
employee_id 오름차순 정렬, 처음 5행만 확인.

```
EMPLOYEE_ID LAST_NAME  E_DEPT_ID  D_DEPT_ID  LOCATION_ID
----------- ---------- ---------- ---------- -----------
        100 King               90         90        1700
        101 Kochhar            90         90        1700
        102 De Haan            90         90        1700
        103 Hunold             60         60        1400
        104 Ernst              60         60        1400
```

---

**[8번]** EMPLOYEES, DEPARTMENTS, LOCATIONS 테이블을 ON 절로 3방향 조인하여 employee_id, last_name, department_name, city를 출력하시오.  
department_name 오름차순 → last_name 오름차순 정렬.

```
EMPLOYEE_ID LAST_NAME  DEPARTMENT_NAME   CITY
----------- ---------- ----------------- --------------------
        205 Higgins    Accounting        Seattle
        206 Gietz      Accounting        Seattle
        100 King       Executive         Seattle
        101 Kochhar    Executive         Seattle
        102 De Haan    Executive         Seattle
        ...
```

---

**[9번]** EMPLOYEES와 DEPARTMENTS를 ON 절로 조인하되, manager_id가 149인 사원만 출력하시오.  
출력 열: employee_id, last_name, department_id(e), department_id(d), location_id

```
EMPLOYEE_ID LAST_NAME  E_DEPT  D_DEPT  LOCATION_ID
----------- ---------- ------- ------- -----------
        174 Abel             80      80        2500
        176 Taylor           80      80        2500
        200 Whalen           10      10        1700
        201 Hartstein        20      20        1800
```

---

**[10번]** EMPLOYEES와 DEPARTMENTS, LOCATIONS를 3방향 조인하여 IT 부서(department_id=60) 사원의 이름, 도시, 주소(street_address)를 출력하시오.

```
LAST_NAME  CITY    STREET_ADDRESS
---------- ------- ------------------------
Hunold     Southlake  2014 Jabberwocky Rd
Ernst      Southlake  2014 Jabberwocky Rd
Austin     Southlake  2014 Jabberwocky Rd
Pataballa  Southlake  2014 Jabberwocky Rd
Lorentz    Southlake  2014 Jabberwocky Rd
```

---

**[11번]** EMPLOYEES와 JOBS를 ON 절로 조인하여 last_name, job_title, salary, min_salary, max_salary를 출력하시오.  
salary가 max_salary의 90% 이상인 사원만 출력. salary 내림차순 정렬.

```
LAST_NAME  JOB_TITLE           SALARY  MIN_SAL  MAX_SAL
---------- ------------------- ------- -------- -------
King       President           24000    20080    40000
...
```

---

**[12번]** EMPLOYEES, DEPARTMENTS, LOCATIONS, COUNTRIES를 4방향 조인하여 나라별 사원 수를 출력하시오.  
country_name 오름차순 정렬.

```
COUNTRY_NAME           EMP_COUNT
---------------------- ---------
Canada                        2
Germany                        1
Singapore                      2
United Kingdom                 2
United States of America      99
```

---

## Group 3. Self-Join · Nonequijoin (13~18번)

---

**[13번]** EMPLOYEES 테이블을 Self-Join하여 모든 사원의 이름과 그 관리자 이름을 출력하시오.  
사원 이름 오름차순 정렬.

```
EMP        MGR
---------- ----------
Abel       Zlotkey
Ande       Errazuriz
Atkinson   Mourgos
Austin     Hunold
Baer       Kochhar
...
(106개 행)
```

---

**[14번]** EMPLOYEES 테이블을 Self-Join하여 관리자 이름(manager.last_name)별 부하 직원 수를 출력하시오.  
부하 직원 수 내림차순 정렬.

```
MANAGER     SUB_COUNT
----------- ---------
King               14
Cambrault           9
Russell             9
...
```

---

**[15번]** EMPLOYEES 테이블을 Self-Join하여 같은 부서에서 같은 직무(job_id)를 가진 사원 쌍을 출력하시오.  
조건: e1.employee_id < e2.employee_id (중복 방지), department_id = 80 한정.

```
EMP1       EMP2       JOB_ID     DEPARTMENT_ID
---------- ---------- ---------- -------------
Abel       Ande       SA_REP                80
Abel       Banda      SA_REP                80
...
```

---

**[16번]** EMPLOYEES와 JOB_GRADES 테이블을 비등가 조인(Nonequijoin)으로 연결하여 last_name, salary, grade_level을 출력하시오.  
grade_level 오름차순 → salary 오름차순 정렬.

```
LAST_NAME  SALARY  GRADE_LEVEL
---------- ------- -----------
Olson        2100  A
Philtanker   2200  A
Marlow       2500  A
...
Higgins     12008  E
King        24000  E
```

---

**[17번]** EMPLOYEES와 JOB_GRADES를 비등가 조인하되, 급여 등급이 'C' 또는 'D'인 사원만 출력하시오.  
부서별, 등급별 사원 수를 집계하시오.

```
DEPARTMENT_ID GRADE_LEVEL EMP_COUNT
------------- ----------- ---------
           50 C                  22
           50 D                   3
           60 C                   4
           80 C                   5
           80 D                  22
           ...
```

---

**[18번]** EMPLOYEES를 Self-Join하여 관리자 계층(사원 → 직속 관리자 → 관리자의 관리자)을 2단계로 출력하시오.  
조건: 관리자의 관리자(mgr2)가 있는 경우만 포함, 사원 이름 오름차순.

```
EMP        DIRECT_MGR  MANAGER_OF_MGR
---------- ----------- --------------
Abel       Zlotkey     Russell
Ande       Errazuriz   Russell
...
```

---

## Group 4. OUTER JOIN (19~24번)

---

**[19번]** EMPLOYEES와 DEPARTMENTS를 LEFT OUTER JOIN으로 연결하여 모든 사원(부서 없는 사원 포함)의 last_name과 department_name을 출력하시오.  
last_name 오름차순 정렬, department_name이 NULL인 행이 포함되는지 확인.

```
LAST_NAME  DEPARTMENT_NAME
---------- ------------------
Abel       Sales
...
Grant      (null)
...
(107개 행)
```

---

**[20번]** EMPLOYEES와 DEPARTMENTS를 RIGHT OUTER JOIN으로 연결하여 사원이 없는 부서도 포함하여 출력하시오.  
출력 열: last_name, department_id, department_name  
department_id 오름차순 정렬.

```
LAST_NAME  DEPARTMENT_ID DEPARTMENT_NAME
---------- ------------- ------------------
Whalen                10 Administration
Hartstein             20 Marketing
...
(null)               190 Contracting
...
```

---

**[21번]** EMPLOYEES와 DEPARTMENTS를 FULL OUTER JOIN으로 연결하여 불일치 행만 출력하시오.  
(WHERE e.last_name IS NULL OR d.department_name IS NULL)

```
LAST_NAME  DEPARTMENT_ID DEPARTMENT_NAME
---------- ------------- ------------------
Grant      (null)        (null)
(null)               190 Contracting
...
```

---

**[22번]** EMPLOYEES와 DEPARTMENTS를 LEFT OUTER JOIN으로 연결하고, 부서 이름이 'Sales'인 경우만 ON 절에 추가 조건으로 넣어 출력하시오.  
(WHERE가 아닌 ON 절에 조건 추가, 모든 사원 107명 출력)

```
LAST_NAME  DEPARTMENT_NAME
---------- ---------------
Abel       Sales
Ande       Sales
...
King       (null)
Kochhar    (null)
...
(107개 행)
```

---

**[23번]** EMPLOYEES와 DEPARTMENTS를 RIGHT OUTER JOIN으로 연결하여 부서별 사원 수를 출력하시오.  
사원이 없는 부서도 포함(0으로 표시), department_name 오름차순 정렬.

```
DEPARTMENT_NAME     EMP_COUNT
------------------- ---------
Accounting                  2
Administration              1
Benefits                    0
Construction                0
Contracting                 0
Executive                   3
...
(27개 행)
```

---

**[24번]** EMPLOYEES, DEPARTMENTS, LOCATIONS를 연속 OUTER JOIN으로 연결하여 부서가 없는 사원(Grant)도 포함한 all 사원의 last_name, department_name, city를 출력하시오.  
last_name 오름차순 정렬.

```
LAST_NAME  DEPARTMENT_NAME  CITY
---------- ---------------- --------------------
Abel       Sales            Oxford
...
Grant      (null)           (null)
...
(107개 행)
```

---

## Group 5. 종합 응용 (25~30번)

---

**[25번]** EMPLOYEES와 DEPARTMENTS, LOCATIONS를 조인하여 부서별 사원 수와 평균 급여(정수), 도시 이름을 출력하시오.  
부서 번호 오름차순 정렬.

```
DEPT_ID DEPARTMENT_NAME    CITY             EMP_COUNT AVG_SALARY
------- ------------------ ---------------- --------- ----------
     10 Administration     Seattle                  1       4400
     20 Marketing          Toronto                  2       9500
     30 Purchasing         Seattle                  6       4150
     40 Human Resources    London                   1       6500
     50 Shipping           South San Francisco     45       3476
     ...
```

---

**[26번]** EMPLOYEES와 JOB_GRADES를 비등가 조인하고, DEPARTMENTS를 ON 절로 조인하여 부서별, 급여 등급별 사원 수를 출력하시오.  
부서 번호 오름차순 → 등급 오름차순 정렬.

```
DEPARTMENT_NAME   GRADE_LEVEL EMP_COUNT
----------------- ----------- ---------
Accounting        E                   2
Executive         E                   3
Finance           C                   2
Finance           D                   3
Finance           E                   1
IT                C                   5
Marketing         D                   1
Marketing         E                   1
...
```

---

**[27번]** EMPLOYEES 테이블에서 Self-Join으로 관리자 정보를 조회하되, 부서 이름(DEPARTMENTS)도 함께 출력하시오.  
출력 열: 사원이름, 관리자이름, 부서이름, 사원급여  
부서이름 오름차순 → 사원이름 오름차순 정렬.

```
EMP        MGR        DEPARTMENT_NAME    SALARY
---------- ---------- ------------------ -------
Gietz      Higgins    Accounting           8300
Higgins    Kochhar    Accounting          12008
...
```

---

**[28번]** EMPLOYEES와 DEPARTMENTS를 LEFT OUTER JOIN으로 연결하고, 부서별 급여 합계(사원 없는 부서는 0)를 출력하시오.  
급여 합계 내림차순 정렬.

```
DEPARTMENT_NAME     TOTAL_SALARY
------------------- ------------
Sales                     304900
Shipping                  156400
Finance                    51608
...
Benefits                        0
Construction                    0
...
(27개 행)
```

---

**[29번]** EMPLOYEES와 DEPARTMENTS, LOCATIONS, COUNTRIES를 4방향 조인하여 사원별 근무 국가와 급여 등급을 함께 출력하시오.  
(JOB_GRADES도 조인 — 5방향)  
출력 열: last_name, country_name, grade_level, salary  
country_name 오름차순 → grade_level 오름차순 → salary 오름차순 정렬.

```
LAST_NAME  COUNTRY_NAME               GRADE_LEVEL SALARY
---------- -------------------------- ----------- ------
Feeney     Canada                     C             6000
Mikkileni  Canada                     C             6000
...
Weiss      United States of America   C             8000
...
King       United States of America   E            24000
```

---

**[30번]** 다음 종합 보고서를 하나의 SQL 문으로 작성하시오.

요구사항:
- EMPLOYEES, DEPARTMENTS, LOCATIONS를 조인 (INNER JOIN)
- 도시(city)별, 부서별 집계
- 출력 열: city, department_name, 사원 수, 최대 급여, 최소 급여, 평균 급여(정수)
- 사원 수가 2명 이상인 그룹만 포함
- city 오름차순 → 사원 수 내림차순 정렬

```
CITY              DEPARTMENT_NAME    EMP_COUNT MAX_SAL MIN_SAL AVG_SAL
----------------- ------------------ --------- ------- ------- -------
Oxford            Sales                     34   14000    6100    8956
Seattle           Accounting                 2   12008    8300   10154
Seattle           Executive                  3   24000   17000   19333
Seattle           Finance                    6   12008    6900    8600
Seattle           Human Resources            1    6500    6500    6500
Seattle           IT                         0       -       -       -
South San Francisco Shipping                45    8200    2100    3476
...
```
