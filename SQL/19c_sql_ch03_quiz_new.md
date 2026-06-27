# Oracle Database 19c: SQL Workshop
## Chapter 3 — 데이터 제한 및 정렬 | 연습문제

> **사용 스키마:** HR (Human Resources)  
> **범위:** WHERE 절, 비교 연산자, BETWEEN/IN/LIKE/IS NULL, AND/OR/NOT, 연산자 우선순위, ORDER BY, FETCH FIRST, 대체 변수

---

# ★ 하 (기초) — 20문제

---

**[하-01]** WHERE 절의 위치로 올바른 것을 고르시오.

① SELECT 절 앞  
② FROM 절 앞  
③ FROM 절 바로 다음  
④ ORDER BY 절 다음

---

**[하-02]** 다음 SQL 문을 완성하시오. EMPLOYEES 테이블에서 부서 번호가 90인 사원만 조회하시오.

```sql
SELECT employee_id, last_name, department_id
FROM   employees
_____ department_id = 90;
```

---

**[하-03]** WHERE 절에서 문자 값을 비교할 때 올바른 것은?

① `WHERE last_name = King`  
② `WHERE last_name = "King"`  
③ `WHERE last_name = 'King'`  
④ `WHERE last_name = [King]`

---

**[하-04]** Oracle에서 "같지 않다"를 표현하는 비교 연산자는 무엇인가?

---

**[하-05]** `BETWEEN 2500 AND 3500` 조건은 경계값 2500과 3500을 포함하는가?

---

**[하-06]** 다음 SQL 문에서 조회되는 결과로 올바른 것은?

```sql
SELECT last_name
FROM   employees
WHERE  manager_id IN (100, 101, 201);
```

① manager_id가 100, 101, 201 모두인 사원  
② manager_id가 100, 101, 201 중 하나인 사원  
③ manager_id가 100에서 201 사이인 사원  
④ manager_id가 NULL인 사원

---

**[하-07]** LIKE 연산자에서 `%`와 `_`의 차이를 설명하시오.

---

**[하-08]** 관리자가 없는 사원(manager_id가 NULL)을 조회하는 조건으로 올바른 것은?

① `WHERE manager_id = NULL`  
② `WHERE manager_id IS NULL`  
③ `WHERE manager_id == NULL`  
④ `WHERE manager_id = 'NULL'`

---

**[하-09]** AND 연산자의 동작으로 올바른 것을 고르시오.

① 두 조건 중 하나가 TRUE이면 결과를 반환한다  
② 두 조건이 모두 TRUE이어야 결과를 반환한다  
③ 조건이 FALSE이면 결과를 반환한다  
④ 조건과 관계없이 모든 결과를 반환한다

---

**[하-10]** 다음 중 연산자 우선순위가 가장 높은 것은?

① AND  
② OR  
③ NOT  
④ 산술 연산자(+, -)

---

**[하-11]** ORDER BY 절에서 기본 정렬 순서는?

① DESC (내림차순)  
② ASC (오름차순)  
③ 입력 순서  
④ 알파벳 역순

---

**[하-12]** 다음 SQL 문에서 빈칸에 들어갈 내용은?

```sql
SELECT last_name, salary
FROM   employees
ORDER BY salary ____;
```

(월급이 높은 사원부터 낮은 순서로 정렬하고 싶다.)

---

**[하-13]** 다음 중 이름이 'S'로 시작하는 사원을 조회하는 조건으로 올바른 것은?

① `WHERE first_name LIKE 'S'`  
② `WHERE first_name LIKE 'S_'`  
③ `WHERE first_name LIKE 'S%'`  
④ `WHERE first_name LIKE '%S'`

---

**[하-14]** 다음 SQL 문에서 ORDER BY 3은 무엇을 기준으로 정렬하는가?

```sql
SELECT last_name, job_id, department_id, hire_date
FROM   employees
ORDER BY 3;
```

---

**[하-15]** Oracle에서 상위 5개 행만 반환하는 올바른 구문을 고르시오.

① `SELECT TOP 5 * FROM employees;`  
② `SELECT * FROM employees ROWNUM <= 5;`  
③ `SELECT * FROM employees FETCH FIRST 5 ROWS ONLY;`  
④ `SELECT * FROM employees LIMIT 5;`

---

**[하-16]** 다음 SQL 문의 실행 시 어떤 일이 발생하는가?

```sql
SELECT employee_id, last_name, salary
FROM   employees
WHERE  employee_id = &employee_num;
```

---

**[하-17]** NOT 연산자의 설명으로 올바른 것은?

① 두 조건이 모두 TRUE이어야 TRUE  
② 조건이 FALSE이면 TRUE를 반환  
③ 두 조건 중 하나가 TRUE이면 TRUE  
④ 항상 FALSE를 반환

---

**[하-18]** 다음 SQL 문에서 WHERE 절이 없으면 어떤 결과가 반환되는가?

```sql
SELECT employee_id, last_name
FROM   employees;
```

---

**[하-19]** 열 별칭으로 ORDER BY를 사용하는 아래 SQL 문에서 정렬 기준 열은?

```sql
SELECT employee_id, last_name, salary * 12 annsal
FROM   employees
ORDER BY annsal;
```

---

**[하-20]** BETWEEN A AND B에서 A와 B의 관계로 올바른 것은?

① A는 반드시 B보다 작아야 한다  
② A와 B는 동일해야 한다  
③ A가 B보다 커도 된다  
④ A와 B는 관계없다

---

# ★★ 중 (응용) — 20문제

---

**[중-01]** EMPLOYEES 테이블에서 급여가 10,000 이상인 사원의 last_name과 salary를 조회하는 SQL 문을 작성하시오.

---

**[중-02]** EMPLOYEES 테이블에서 last_name이 'Abel'인 사원의 모든 정보를 조회하는 SQL 문을 작성하시오.

---

**[중-03]** EMPLOYEES 테이블에서 급여가 2,500에서 3,500 사이인 사원의 last_name과 salary를 조회하시오. (BETWEEN 사용)

---

**[중-04]** EMPLOYEES 테이블에서 manager_id가 100, 101, 201 중 하나인 사원의 employee_id, last_name, salary, manager_id를 조회하시오. (IN 사용)

---

**[중-05]** EMPLOYEES 테이블에서 first_name이 'S'로 시작하는 사원의 first_name을 조회하시오. (LIKE 사용)

---

**[중-06]** EMPLOYEES 테이블에서 last_name의 두 번째 문자가 'o'인 사원의 last_name을 조회하시오.

---

**[중-07]** EMPLOYEES 테이블에서 manager_id가 NULL인 사원 (최상위 관리자)의 last_name과 manager_id를 조회하시오.

---

**[중-08]** EMPLOYEES 테이블에서 급여가 10,000 이상이고 직무 코드에 'MAN'이 포함된 사원의 employee_id, last_name, job_id, salary를 조회하시오. (AND 사용)

---

**[중-09]** EMPLOYEES 테이블에서 직무 코드가 'IT_PROG', 'ST_CLERK', 'SA_REP'가 아닌 사원의 last_name과 job_id를 조회하시오. (NOT IN 사용)

---

**[중-10]** 다음 두 SQL 문의 결과 차이를 설명하시오.

```sql
-- (A)
SELECT last_name, department_id, salary
FROM   employees
WHERE  department_id = 60
OR     department_id = 80
AND    salary > 10000;

-- (B)
SELECT last_name, department_id, salary
FROM   employees
WHERE  (department_id = 60
OR      department_id = 80)
AND    salary > 10000;
```

---

**[중-11]** EMPLOYEES 테이블에서 last_name, job_id, department_id, hire_date를 조회하되 입사일 기준 오름차순으로 정렬하시오.

---

**[중-12]** EMPLOYEES 테이블에서 department_id 내림차순, 같은 부서 내에서는 salary 내림차순으로 정렬하시오.  
출력 열: last_name, department_id, salary

---

**[중-13]** EMPLOYEES 테이블에서 commission_pct가 NULL이 아닌 사원의 last_name, salary, commission_pct를 조회하시오.

---

**[중-14]** EMPLOYEES 테이블에서 employee_id가 100에서 120 사이인 사원의 employee_id와 last_name을 조회하시오. (BETWEEN 사용)

---

**[중-15]** EMPLOYEES 테이블에서 입사일이 '01-JAN-99' 이후인 사원의 last_name과 hire_date를 조회하시오.

---

**[중-16]** EMPLOYEES 테이블에서 salary * 12를 연봉(annsal)으로 표시하고, 연봉 기준 내림차순으로 정렬하시오.  
출력 열: employee_id, last_name, annsal

---

**[중-17]** 다음 SQL 문에서 잘못된 부분을 찾아 수정하시오.

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary BETWEEN 3500 AND 2500;
```

---

**[중-18]** EMPLOYEES 테이블에서 급여가 10,000 이상이거나 직무 코드에 'MAN'이 포함된 사원을 조회하시오. (OR 사용)  
출력 열: employee_id, last_name, job_id, salary

---

**[중-19]** Oracle에서 employee_id 기준 오름차순으로 정렬한 후 상위 10명만 조회하는 SQL 문을 작성하시오.  
출력 열: employee_id, first_name, last_name

---

**[중-20]** DEPARTMENTS 테이블에서 manager_id가 NULL인 부서의 department_id와 department_name을 조회하시오.

---

# ★★★ 상 (심화) — 10문제

---

**[상-01]** 다음 두 SQL 문의 결과가 다른 이유를 연산자 우선순위 관점에서 설명하고, 각각 어떤 사원이 조회되는지 분석하시오.

```sql
-- (A)
SELECT last_name, job_id, salary
FROM   employees
WHERE  job_id = 'SA_REP'
OR     job_id = 'AD_VP'
AND    salary > 15000;

-- (B)
SELECT last_name, job_id, salary
FROM   employees
WHERE  (job_id = 'SA_REP'
OR      job_id = 'AD_VP')
AND    salary > 15000;
```

---

**[상-02]** 다음 SQL 문에는 오류가 있다. 모든 오류를 찾아 수정하시오.

```sql
SELCT last_name, salary
FROM  employees
WERE  salary BETWEEN 5000 TO 10000
   OR last_name LIKE "%king%"
ORDERBY salary;
```

---

**[상-03]** EMPLOYEES 테이블에서 다음 조건을 모두 만족하는 사원을 조회하시오.

- 부서 번호가 50 또는 80
- 급여가 5,000 이상
- last_name이 'A'로 시작
- commission_pct가 NULL이 아님

출력 열: employee_id, last_name, salary, department_id, commission_pct  
정렬: salary 내림차순

---

**[상-04]** 다음 SQL 문을 분석하여 물음에 답하시오.

```sql
SELECT last_name, department_id, salary
FROM   employees
WHERE  department_id IN (60, 80, 90)
AND    salary NOT BETWEEN 5000 AND 12000
ORDER BY department_id, salary DESC;
```

(1) 이 SQL이 조회하는 사원의 조건을 한국어로 설명하시오.  
(2) HR 스키마 데이터 기준으로 어떤 사원들이 포함될지 예측하시오.  
(Steven King: dept=90, salary=24000 / Neena Kochhar: dept=90, salary=17000 / IT_PROG 사원: dept=60, salary 4200~9000)

---

**[상-05]** ORDER BY 절에서 열 위치 번호(예: `ORDER BY 3`)와 열 이름/별칭을 사용하는 방식의 **장단점**을 비교하고, 실무에서 권장되는 방식과 그 이유를 설명하시오.

---

**[상-06]** EMPLOYEES 테이블에서 아래 조건에 해당하는 사원을 조회하시오.

- 직무 코드가 'SA_REP'이거나 'SA_MAN'
- 급여가 8,000 이상
- department_id 기준 오름차순, 같은 부서 내 salary 내림차순 정렬
- 상위 5명만 반환

출력 열: employee_id, last_name, job_id, salary, department_id

---

**[상-07]** 다음 SQL 문에서 WHERE 절의 각 조건이 평가되는 순서를 연산자 우선순위에 따라 분석하시오.

```sql
SELECT last_name, department_id, salary, commission_pct
FROM   employees
WHERE  department_id = 80
AND    salary > 10000
OR     commission_pct IS NOT NULL
AND    salary BETWEEN 6000 AND 9000;
```

(1) 연산자 우선순위에 따른 조건 평가 순서를 단계별로 설명하시오.  
(2) 괄호를 사용하여 의도를 명확히 한 버전으로 다시 작성하시오.

---

**[상-08]** EMPLOYEES 테이블에서 대체 변수를 활용하여 사용자가 직무 코드를 입력하면 해당 직무의 사원 목록(last_name, salary, hire_date)을 급여 내림차순으로 보여주는 유연한 SQL 문을 작성하시오.  
(Oracle 대체 변수 사용)

---

**[상-09]** 아래 두 SQL 문의 결과 행 수를 비교하고 차이가 발생하는 이유를 설명하시오.

```sql
-- (A)
SELECT last_name, salary
FROM   employees
WHERE  salary > 5000
AND    salary < 10000;

-- (B)
SELECT last_name, salary
FROM   employees
WHERE  salary BETWEEN 5001 AND 9999;
```

---

**[상-10]** 다음 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항:
- EMPLOYEES 테이블에서 조회
- 부서 번호가 50, 60, 80 중 하나이거나, 부서가 없는(NULL) 사원
- 급여가 5,000 이상
- 직무 코드가 'ST_CLERK'이 아님
- 출력 열: employee_id, last_name, department_id, job_id, salary, commission_pct
- 부서 오름차순(NULL은 마지막), 같은 부서 내 급여 내림차순 정렬
