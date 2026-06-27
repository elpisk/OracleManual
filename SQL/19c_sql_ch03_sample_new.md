# Oracle Database 19c: SQL Workshop
## Chapter 3 — 데이터 제한 및 정렬 | SQL 실습 문제 (sql_sample 참고형)

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources)  
> **범위:** WHERE 절, 비교 연산자, BETWEEN/IN/LIKE/IS NULL, AND/OR/NOT, ORDER BY, FETCH FIRST  
> **작성 방식:** 주어진 출력 결과를 보고 SQL 문을 직접 작성하시오.

---

## Group 1. WHERE 절 기본 조건 (1~6번)

---

**[1번]** EMPLOYEES 테이블에서 부서 번호가 90인 사원의 사번, 성(last_name), 직무코드(job_id), 부서번호를 조회하시오.

```
EMPLOYEE_ID LAST_NAME  JOB_ID     DEPARTMENT_ID
----------- ---------- ---------- -------------
        100 King       AD_PRES               90
        101 Kochhar    AD_VP                 90
        102 De Haan    AD_VP                 90
(3개 행)
```

---

**[2번]** 1번 결과에서 조건을 **급여가 3,000 이하**로 변경하여 last_name과 salary를 조회하시오.

```
LAST_NAME  SALARY
---------- ------
Olson        2100
Markle       2200
Philtanker   2200
Gee          2400
Landry       2400
Marlow       2500
...
(약 20여 개 행)
```

---

**[3번]** EMPLOYEES 테이블에서 last_name이 정확히 **'Abel'**인 사원의 모든 정보를 조회하시오.

```
EMPLOYEE_ID FIRST_NAME LAST_NAME EMAIL    ...  SALARY COMMISSION_PCT ... DEPARTMENT_ID
----------- ---------- --------- -------- ---  ------ -------------- --- -------------
        174 Ellen      Abel      EABEL    ...   11000            0.3 ...            80
(1개 행)
```

---

**[4번]** EMPLOYEES 테이블에서 입사일이 **'01-JAN-00' 이후**인 사원의 last_name과 hire_date를 조회하시오.  
(입사일 오름차순 정렬)

```
LAST_NAME  HIRE_DATE
---------- ---------
Landry     00/01/14
Marlow     00/01/27
...
(2000년 이후 입사자)
```

---

**[5번]** EMPLOYEES 테이블에서 **커미션율(commission_pct)이 NULL이 아닌** 사원의  
last_name, salary, commission_pct를 급여 내림차순으로 조회하시오.

```
LAST_NAME  SALARY COMMISSION_PCT
---------- ------ --------------
Russell     14000             .4
Partners    13500             .3
Errazuriz   12000             .3
Cambrault   11000             .3
...
(35개 행)
```

---

**[6번]** EMPLOYEES 테이블에서 **관리자가 없는** 사원(manager_id = NULL)의  
last_name과 manager_id를 조회하시오.

```
LAST_NAME MANAGER_ID
--------- ----------
King
(1개 행)
```

---

## Group 2. 범위·목록·패턴 조건 (7~12번)

---

**[7번]** EMPLOYEES 테이블에서 급여가 **2,500에서 3,500 사이**인 사원의  
last_name과 salary를 조회하시오. BETWEEN 연산자를 사용하시오.

```
LAST_NAME  SALARY
---------- ------
Marlow       2500
Olson        2100
...
(실제 2500~3500 구간의 사원들)
```

---

**[8번]** EMPLOYEES 테이블에서 manager_id가 **100, 101, 201 중 하나**인 사원의  
employee_id, last_name, salary, manager_id를 조회하시오. IN 연산자를 사용하시오.

```
EMPLOYEE_ID LAST_NAME   SALARY MANAGER_ID
----------- ----------- ------ ----------
        101 Kochhar      17000        100
        102 De Haan      17000        100
        108 Greenberg    12008        101
...
```

---

**[9번]** EMPLOYEES 테이블에서 first_name이 **'S'로 시작**하는 사원의  
first_name을 조회하시오. LIKE 연산자를 사용하시오.

```
FIRST_NAME
--------------------
Shanta
Shelli
Sigal
Steven
Steven
Shelley
Susan
(7개 행)
```

---

**[10번]** 9번에 이어, last_name의 **두 번째 문자가 'o'**인 사원의 last_name을 조회하시오.

```
LAST_NAME
----------
Doran
Fox
Fohrkam
Mourgos
Tobias
(5개 행)
```

---

**[11번]** EMPLOYEES 테이블에서 last_name에 **'a'가 포함**되는 사원의 last_name을 조회하고,  
last_name 알파벳 오름차순으로 정렬하시오.

```
LAST_NAME
----------
Abel
Ande
Banda
Bates
...
```

---

**[12번]** EMPLOYEES 테이블에서 job_id가 **'SA_REP'이 아닌** 사원 중  
last_name, job_id를 조회하시오. NOT 연산자를 사용하시오.

```
LAST_NAME  JOB_ID
---------- ----------
King       AD_PRES
Kochhar    AD_VP
De Haan    AD_VP
...
(107 - SA_REP 수만큼)
```

---

## Group 3. 논리 연산자 조합 (13~18번)

---

**[13번]** EMPLOYEES 테이블에서 급여가 **10,000 이상이고** 직무코드에 **'MAN'이 포함**된 사원을 조회하시오.  
AND 연산자를 사용하시오. 출력 열: employee_id, last_name, job_id, salary

```
EMPLOYEE_ID LAST_NAME   JOB_ID     SALARY
----------- ----------- ---------- ------
        145 Russell     SA_MAN      14000
        146 Partners    SA_MAN      13500
        147 Errazuriz   SA_MAN      12000
        148 Cambrault   SA_MAN      11000
        149 Zlotkey     SA_MAN      10500
        201 Hartstein   MK_MAN      13000
(6개 행)
```

---

**[14번]** 13번 조건에서 AND를 **OR로 변경**하여 결과 행 수가 어떻게 달라지는지 확인하시오.

```
EMPLOYEE_ID LAST_NAME   JOB_ID     SALARY
----------- ----------- ---------- ------
...
(AND보다 훨씬 많은 행 — 급여 10000 이상이거나 job_id에 'MAN'이 포함된 모든 사원)
```

---

**[15번]** EMPLOYEES 테이블에서 직무코드가 **'IT_PROG', 'ST_CLERK', 'SA_REP'가 아닌** 사원을 조회하시오.  
NOT IN 연산자를 사용하시오. 출력 열: last_name, job_id

```
LAST_NAME  JOB_ID
---------- ----------
King       AD_PRES
Kochhar    AD_VP
De Haan    AD_VP
Greenberg  FI_MGR
...
```

---

**[16번]** EMPLOYEES 테이블에서 아래 두 조건을 비교하시오.  
같은 SQL에서 두 버전을 실행하여 결과 차이를 확인하시오.

```sql
-- 버전 A
WHERE  department_id = 60
OR     department_id = 80
AND    salary > 10000;

-- 버전 B
WHERE  (department_id = 60
OR      department_id = 80)
AND    salary > 10000;
```

출력 열: last_name, department_id, salary

```
-- 버전 A 결과 (부서=60 전체 + 부서=80이고 급여>10000):
LAST_NAME   DEPARTMENT_ID SALARY
----------- ------------- ------
Hunold                 60   9000   ← 부서 60 전체 포함
Ernst                  60   6000
...
Russell                80  14000   ← 부서 80, 급여>10000만
...

-- 버전 B 결과 ((부서=60 또는 80)이고 급여>10000):
LAST_NAME   DEPARTMENT_ID SALARY
----------- ------------- ------
Hunold                 60   9000   ← 부서 60, 급여>10000만
Russell                80  14000
...
```

---

**[17번]** EMPLOYEES 테이블에서 부서가 50이고 급여가 3,500 이상인 사원 중  
last_name이 'S'로 시작하는 사원을 조회하시오.  
출력 열: last_name, department_id, salary  
정렬: salary 오름차순

```
LAST_NAME  DEPARTMENT_ID SALARY
---------- ------------- ------
Sarchand              50   4200
Stiles                50   3600
Seo                   50   2700
...
```

---

**[18번]** EMPLOYEES 테이블에서 아래 조건으로 조회하시오.

- 급여가 5,000 미만이거나 15,000 초과
- 또는 커미션율이 0.4 이상

출력 열: last_name, salary, commission_pct  
정렬: salary 내림차순

```
LAST_NAME  SALARY COMMISSION_PCT
---------- ------ --------------
Russell     14000             .4
King        24000
Kochhar     17000
De Haan     17000
...
```

---

## Group 4. ORDER BY 정렬 (19~24번)

---

**[19번]** EMPLOYEES 테이블에서 last_name, job_id, department_id, hire_date를 조회하되  
**입사일 오름차순**으로 정렬하시오.

```
LAST_NAME  JOB_ID     DEPARTMENT_ID HIRE_DATE
---------- ---------- ------------- ---------
Whalen     AD_ASST               10 87/09/17
Fay        MK_REP                20 97/08/17
Mavris     HR_REP                40 02/01/07
Higgins    AC_MGR               110 02/06/07
...
```

---

**[20번]** 19번에서 정렬 기준을 **입사일 내림차순**으로 변경하시오.

```
LAST_NAME  JOB_ID     DEPARTMENT_ID HIRE_DATE
---------- ---------- ------------- ---------
(가장 최근 입사자부터)
...
```

---

**[21번]** EMPLOYEES 테이블에서 employee_id, last_name, salary*12를 조회하고  
열 별칭 `annsal`로 표시한 뒤 **연봉 내림차순**으로 정렬하시오.

```
EMPLOYEE_ID LAST_NAME  ANNSAL
----------- ---------- ------
        100 King       288000
        101 Kochhar    204000
        102 De Haan    204000
        145 Russell    168000
...
```

---

**[22번]** EMPLOYEES 테이블에서 last_name, department_id, salary를 조회하되  
**부서 번호 오름차순**, 같은 부서 내에서는 **급여 내림차순**으로 정렬하시오.

```
LAST_NAME  DEPARTMENT_ID SALARY
---------- ------------- ------
Whalen                10   4400
Hartstein             20  13000
Fay                   20   6000
Raphaely              30  11000
Khoo                  30   3100
...
```

---

**[23번]** EMPLOYEES 테이블에서 SELECT 절의 **세 번째 열 위치(숫자 위치)**로 정렬하시오.  
출력 열: last_name, job_id, department_id, hire_date

```
LAST_NAME  JOB_ID     DEPARTMENT_ID HIRE_DATE
---------- ---------- ------------- ---------
Whalen     AD_ASST               10 87/09/17
Fay        MK_REP                20 97/08/17
...
(department_id 오름차순)
```

---

**[24번]** EMPLOYEES 테이블에서 커미션이 있는 사원만 대상으로  
last_name, salary, commission_pct를 조회하되  
**커미션율 내림차순, 같은 커미션율 내에서는 급여 내림차순**으로 정렬하시오.

```
LAST_NAME  SALARY COMMISSION_PCT
---------- ------ --------------
Russell     14000             .4
Zlotkey     10500             .2
...
```

---

## Group 5. FETCH FIRST & WHERE + ORDER BY 종합 (25~30번)

---

**[25번]** EMPLOYEES 테이블에서 employee_id 오름차순으로 정렬한 후 **처음 5명**만 조회하시오.  
출력 열: employee_id, first_name, last_name

```
EMPLOYEE_ID FIRST_NAME  LAST_NAME
----------- ----------- ---------
        100 Steven      King
        101 Neena       Kochhar
        102 Lex         De Haan
        103 Alexander   Hunold
        104 Bruce       Ernst
(5개 행)
```

---

**[26번]** 25번에 이어, **6번째부터 5명**을 추가로 조회하시오. (OFFSET 사용)

```
EMPLOYEE_ID FIRST_NAME  LAST_NAME
----------- ----------- ---------
        105 David       Austin
        106 Valli       Pataballa
        107 Diana       Lorentz
        108 Nancy       Greenberg
        109 Daniel      Faviet
(5개 행)
```

---

**[27번]** EMPLOYEES 테이블에서 **급여가 높은 순서로 상위 3명**의 사원을 조회하시오.  
출력 열: employee_id, last_name, salary

```
EMPLOYEE_ID LAST_NAME  SALARY
----------- ---------- ------
        100 King        24000
        101 Kochhar     17000
        102 De Haan     17000
(3개 행)
```

---

**[28번]** EMPLOYEES 테이블에서 부서 80에 속하고, 급여가 10,000 이상인 사원을  
급여 내림차순으로 조회한 뒤 **상위 3명**만 반환하시오.  
출력 열: employee_id, last_name, salary, department_id

```
EMPLOYEE_ID LAST_NAME  SALARY DEPARTMENT_ID
----------- ---------- ------ -------------
        145 Russell     14000            80
        146 Partners    13500            80
        147 Errazuriz   12000            80
(3개 행)
```

---

**[29번]** EMPLOYEES 테이블에서 아래 조건을 모두 만족하는 사원을 조회하시오.

- 직무코드가 'SA_REP'
- 급여가 8,000 이상

출력 열: employee_id, last_name, job_id, salary  
정렬: salary 내림차순  
제한: 상위 5명

```
EMPLOYEE_ID LAST_NAME  JOB_ID     SALARY
----------- ---------- ---------- ------
        174 Abel       SA_REP      11000
        176 Taylor     SA_REP      8600
        162 Vishney    SA_REP      10500
        163 Greene     SA_REP      9500
        168 Ozer       SA_REP      11500
```

---

**[30번]** 아래 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항:
- EMPLOYEES 테이블
- 부서 번호가 50, 60, 80 중 하나
- 급여가 5,000 이상
- last_name이 'A'에서 'M' 사이 (알파벳 순서상 'A' 이상, 'N' 미만)
- 출력 열: employee_id, last_name, department_id, job_id, salary
- 정렬: 부서 오름차순, 같은 부서 내 last_name 오름차순

```
EMPLOYEE_ID LAST_NAME   DEPARTMENT_ID JOB_ID     SALARY
----------- ----------- ------------- ---------- ------
        103 Hunold                 60 IT_PROG      9000
        104 Ernst                  60 IT_PROG      6000
        145 Abel                   80 SA_REP      11000
        174 Abel                   80 SA_REP      11000
        ...
```
