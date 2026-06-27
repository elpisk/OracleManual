# Oracle Database 19c: SQL Workshop
## Chapter 8 — 서브쿼리를 활용한 쿼리 작성 | 연습문제

> **사용 스키마:** HR (Human Resources)  
> **범위:** 서브쿼리 개념·구문·규칙, 단일행 서브쿼리, 그룹 함수 서브쿼리, HAVING + 서브쿼리, 다중행 서브쿼리(IN/ANY/ALL), 다중열 서브쿼리, NOT IN + NULL 주의

---

# ★ 하 (기초) — 20문제

---

**[하-01]** 서브쿼리에 대한 설명으로 올바른 것은?

① 항상 메인 쿼리보다 먼저 실행된다  
② 항상 메인 쿼리보다 나중에 실행된다  
③ 메인 쿼리와 동시에 실행된다  
④ 실행 순서는 옵티마이저가 임의로 결정한다

---

**[하-02]** 서브쿼리를 사용할 때 규칙으로 올바르지 않은 것은?

① 서브쿼리는 괄호로 감싸야 한다  
② 단일행 서브쿼리에는 단일행 연산자를 사용한다  
③ 서브쿼리는 반드시 비교 조건의 왼쪽에 배치해야 한다  
④ 다중행 서브쿼리에는 IN, ANY, ALL 연산자를 사용한다

---

**[하-03]** 단일행 서브쿼리에서 사용하는 연산자가 아닌 것은?

① `=`  
② `>`  
③ `IN`  
④ `<>`

---

**[하-04]** 다음 SQL 문의 실행 순서로 올바른 것은?

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees);
```

① 메인 쿼리 WHERE 조건 평가 → 서브쿼리 실행 → 결과 반환  
② 서브쿼리 실행 → 서브쿼리 결과를 메인 쿼리 WHERE 조건에 사용 → 결과 반환  
③ 서브쿼리와 메인 쿼리 동시 실행  
④ FROM 절 → 서브쿼리 → WHERE → 결과 반환

---

**[하-05]** 다음 SQL 문에서 서브쿼리가 반환하는 값으로 올바른 것은?

```sql
SELECT last_name
FROM   employees
WHERE  salary = (SELECT MIN(salary) FROM employees);
```

① 여러 행 (최소 급여는 여러 명이 받을 수 있음)  
② 단 하나의 숫자 값  
③ NULL  
④ 오류 발생

---

**[하-06]** 다중행 서브쿼리의 연산자로 올바르지 않은 것은?

① `IN`  
② `ANY`  
③ `ALL`  
④ `=` (단독)

---

**[하-07]** `< ANY` 의 의미는?

① 서브쿼리 결과의 모든 값보다 작음  
② 서브쿼리 결과 중 가장 큰 값보다 작음  
③ 서브쿼리 결과 중 가장 작은 값보다 작음  
④ 서브쿼리 결과에 포함되지 않음

---

**[하-08]** `< ALL` 의 의미는?

① 서브쿼리 결과 중 하나라도 크면 조건 만족  
② 서브쿼리 결과의 최대값보다 작음  
③ 서브쿼리 결과의 최소값보다 작음  
④ 서브쿼리 결과에 포함됨

---

**[하-09]** `= ANY` 와 동일한 의미의 연산자는?

① `ALL`  
② `NOT IN`  
③ `IN`  
④ `EXISTS`

---

**[하-10]** `<> ALL` 과 동일한 의미의 연산자는?

① `IN`  
② `NOT IN`  
③ `ANY`  
④ `EXISTS`

---

**[하-11]** 단일행 서브쿼리에 다중행을 반환하는 서브쿼리를 사용하면?

① 정상 실행, 첫 번째 행만 반환  
② ORA-01427: single-row subquery returns more than one row 오류  
③ 결과 없음  
④ 다중행 연산자로 자동 변환됨

---

**[하-12]** 서브쿼리 결과가 0행(빈 결과)일 때 메인 쿼리의 결과는?

```sql
SELECT last_name FROM employees
WHERE salary = (SELECT salary FROM employees WHERE last_name = 'XXX');
```

① ORA-01427 오류  
② 메인 쿼리도 0행 반환 (오류 없음)  
③ 전체 사원 목록 반환  
④ NULL 반환

---

**[하-13]** 서브쿼리에서 그룹 함수(AVG, MIN, MAX 등)를 사용할 수 있는 이유는?

① 그룹 함수는 다중행을 반환하기 때문에  
② 그룹 함수는 항상 단일 값을 반환하기 때문에  
③ 서브쿼리에서만 사용 가능한 특수 함수이기 때문에  
④ 메인 쿼리와 서브쿼리가 동시 실행되기 때문에

---

**[하-14]** 다음 SQL 문의 의미는?

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary > ANY (SELECT salary FROM employees WHERE department_id = 90);
```

① 부서 90의 모든 사원보다 급여가 높은 사원  
② 부서 90의 어느 한 사원보다 급여가 높은 사원 (부서 90 최솟값보다 높으면 됨)  
③ 부서 90 사원 급여 합계보다 급여가 높은 사원  
④ 부서 90의 평균 급여보다 높은 사원

---

**[하-15]** 다음 SQL 문에서 오류가 발생하는 이유는?

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  salary = (SELECT   MIN(salary)
                 FROM     employees
                 GROUP BY department_id);
```

① 서브쿼리에 GROUP BY를 사용할 수 없어서  
② `=` 연산자인데 서브쿼리가 여러 행을 반환하기 때문에  
③ MIN 함수를 서브쿼리에서 사용할 수 없어서  
④ 오류 없음 — 정상 실행

---

**[하-16]** 다음 SQL 문의 결과는?

```sql
SELECT emp.last_name
FROM   employees emp
WHERE  emp.employee_id NOT IN
       (SELECT mgr.manager_id
        FROM   employees mgr);
```

① 관리자가 아닌 모든 사원 목록  
② 관리자인 사원 목록  
③ 0행 반환 — manager_id에 NULL이 포함되어 있기 때문에  
④ ORA-01427 오류

---

**[하-17]** 다중열 서브쿼리의 구문으로 올바른 것은?

① `WHERE col1 = (SELECT col1, col2 FROM ...)`  
② `WHERE (col1, col2) IN (SELECT col1, col2 FROM ...)`  
③ `WHERE col1 IN (SELECT col1 FROM ...) AND col2 IN (SELECT col2 FROM ...)`  
④ `WHERE col1, col2 = (SELECT col1, col2 FROM ...)`

---

**[하-18]** 서브쿼리를 HAVING 절에서 사용할 때의 처리 순서는?

① 메인 쿼리 HAVING → 서브쿼리 실행 → 결과 반환  
② 서브쿼리 실행 → 결과를 HAVING 절에 반환 → 그룹 필터링  
③ 서브쿼리와 메인 쿼리 동시 실행  
④ FROM → 서브쿼리 → GROUP BY → HAVING

---

**[하-19]** 서브쿼리에서 NOT IN과 NULL의 관계로 올바른 것은?

① NULL이 있으면 NOT IN 조건이 항상 TRUE가 된다  
② 서브쿼리 결과에 NULL이 있으면 NOT IN은 항상 FALSE가 되어 0행 반환  
③ NULL은 자동으로 무시된다  
④ NULL이 있으면 오류가 발생한다

---

**[하-20]** 인라인 뷰(Inline View)로 서브쿼리를 사용하는 위치는?

① WHERE 절  
② HAVING 절  
③ FROM 절  
④ ORDER BY 절

---

# ★★ 중 (응용) — 20문제

---

**[중-01]** EMPLOYEES 테이블에서 전체 평균 급여보다 높은 급여를 받는 사원의 last_name, job_id, salary를 출력하시오.  
salary 내림차순 정렬.

---

**[중-02]** EMPLOYEES 테이블에서 Abel과 같은 직무(job_id)를 가진 사원의 last_name, job_id, salary를 출력하시오.  
(Abel 본인 제외, last_name 오름차순)

---

**[중-03]** EMPLOYEES 테이블에서 최소 급여를 받는 사원의 last_name, job_id, salary를 출력하시오.

---

**[중-04]** EMPLOYEES 테이블에서 부서 90(Executive)의 최소 급여보다 모든 부서에서 최소 급여가 높은 부서의 department_id와 최소 급여를 출력하시오.  
(HAVING + 서브쿼리 사용)

---

**[중-05]** EMPLOYEES 테이블에서 IT_PROG 직무의 사원 중 어느 한 명보다 급여가 낮은 사원을 출력하시오.  
(ANY 연산자, job_id ≠ 'IT_PROG', last_name 오름차순)

---

**[중-06]** EMPLOYEES 테이블에서 IT_PROG 직무의 모든 사원보다 급여가 낮은 사원을 출력하시오.  
(ALL 연산자, job_id ≠ 'IT_PROG', salary 내림차순)

---

**[중-07]** EMPLOYEES 테이블에서 부서 50이나 80에 속한 어느 사원의 급여보다 낮은 급여를 받는 사원(부서 50, 80 제외)을 출력하시오.  
(< ANY 사용)

---

**[중-08]** EMPLOYEES 테이블에서 부서 10, 20, 30에 근무하는 사원과 동일한 직무를 가진 다른 부서 사원을 출력하시오.  
(IN + 서브쿼리, 부서 10, 20, 30 제외)

---

**[중-09]** EMPLOYEES 테이블에서 각 부서의 최소 급여를 받는 사원을 출력하시오.  
(다중열 서브쿼리 사용)  
출력 열: first_name, department_id, salary

---

**[중-10]** EMPLOYEES 테이블에서 관리자인 사원의 목록을 출력하시오.  
(IN + 서브쿼리, manager_id IS NOT NULL 조건 포함)  
employee_id 오름차순 정렬.

---

**[중-11]** EMPLOYEES 테이블에서 관리자가 아닌 사원의 목록을 출력하시오.  
(NOT IN + 서브쿼리 — NULL 문제 처리 포함)  
last_name 오름차순 정렬.

---

**[중-12]** EMPLOYEES 테이블에서 Davies보다 나중에 입사한 모든 사원의 last_name과 hire_date를 출력하시오.  
hire_date 오름차순 정렬.

---

**[중-13]** EMPLOYEES 테이블에서 부서별 최대 급여가 전체 평균 급여보다 높은 부서를 출력하시오.  
(HAVING + 서브쿼리 사용)

---

**[중-14]** EMPLOYEES 테이블에서 부서 60의 어느 사원보다도 급여가 많은 사원을 출력하시오.  
(> ALL 사용, 부서 60 제외)  
salary 내림차순 정렬.

---

**[중-15]** EMPLOYEES 테이블에서 부서 번호가 50인 사원 중 어느 한 명보다 급여가 높은 부서 80의 사원을 출력하시오.  
(> ANY 사용)

---

**[중-16]** EMPLOYEES 테이블에서 부서별 평균 급여보다 자신의 급여가 높은 사원을 출력하시오.  
(FROM 절에 인라인 뷰 서브쿼리 활용)

---

**[중-17]** EMPLOYEES 테이블에서 King과 같은 부서에 근무하는 사원을 출력하시오.  
(King 본인 제외, last_name 오름차순)

---

**[중-18]** EMPLOYEES 테이블에서 commission_pct가 있는 사원 중 가장 낮은 급여보다 급여가 높은 사원(commission_pct 없음)을 출력하시오.

---

**[중-19]** EMPLOYEES 테이블에서 각 직무(job_id)별 평균 급여 중 최솟값을 구하시오.  
(그룹 함수 중첩이 아닌 서브쿼리 방식으로 작성)

---

**[중-20]** EMPLOYEES 테이블에서 부서 50에서 job_id와 salary가 모두 같은 조합이 부서 80에도 존재하는 사원을 출력하시오.  
(다중열 서브쿼리 사용)

---

# ★★★ 상 (심화) — 10문제

---

**[상-01]** 다음 SQL 문에서 오류를 찾고, 수정하시오.

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary > ALL (SELECT AVG(salary)
                     FROM   employees
                     WHERE  department_id = 50);
```

(1) 이 쿼리가 반환하는 결과를 설명하시오.  
(2) `ALL` 대신 `ANY`를 사용하면 결과가 어떻게 달라지는지 설명하시오.

---

**[상-02]** 다음 SQL 문의 문제점을 분석하고 수정하시오.

```sql
SELECT last_name
FROM   employees
WHERE  employee_id NOT IN (SELECT manager_id FROM employees);
```

(1) 왜 결과가 0행인지 설명하시오.  
(2) 올바르게 수정하시오.

---

**[상-03]** 단일행 서브쿼리와 다중행 서브쿼리를 모두 활용하여 다음 요구사항을 구현하시오.

요구사항: "평균 급여보다 높은 급여를 받고, 가장 늦게 입사한 사원보다 먼저 입사한 사원을 조회하라."  
출력 열: last_name, salary, hire_date  
salary 내림차순 정렬.

---

**[상-04]** 다음 쿼리가 어떤 결과를 반환하는지 설명하고, 동일한 결과를 JOIN으로도 작성하시오.

```sql
SELECT last_name, department_id, salary
FROM   employees
WHERE  (salary, department_id) IN
       (SELECT MIN(salary), department_id
        FROM   employees
        GROUP BY department_id);
```

---

**[상-05]** FROM 절 서브쿼리(인라인 뷰)를 사용하여 다음 결과를 출력하시오.

요구사항: "부서별 평균 급여와 사원 수를 인라인 뷰로 계산한 후, 평균 급여가 8,000 이상인 부서의 정보만 출력하라."  
출력 열: department_id, avg_salary, emp_count  
avg_salary 내림차순 정렬.

---

**[상-06]** 다음 두 쿼리의 결과 차이를 분석하고 설명하시오.

```sql
-- (A)
SELECT last_name, salary
FROM   employees
WHERE  salary < ANY (SELECT salary FROM employees WHERE department_id = 90);

-- (B)
SELECT last_name, salary
FROM   employees
WHERE  salary < ALL (SELECT salary FROM employees WHERE department_id = 90);
```

부서 90의 급여: King=24000, Kochhar=17000, De Haan=17000  
(1) 각 쿼리의 실제 조건을 동등 표현으로 바꾸시오.  
(2) 각 쿼리의 결과 행 수를 비교하시오.

---

**[상-07]** EMPLOYEES 테이블에서 SELECT 절에 스칼라 서브쿼리를 사용하여 각 사원의 부서 평균 급여를 함께 출력하시오.

출력 열: last_name, salary, 부서 평균 급여(DEPT_AVG)  
salary 내림차순 정렬, 처음 10행만.

---

**[상-08]** 서브쿼리를 사용하여 다음 비즈니스 요구사항을 구현하시오.

요구사항: "부서 60이나 90의 사원과 직무가 동일하면서, 해당 직무의 최대 급여보다 적게 받는 사원을 조회하라."  
(IN + 서브쿼리, 부서 60, 90 제외)  
출력 열: last_name, job_id, salary  
last_name 오름차순 정렬.

---

**[상-09]** 다음 서브쿼리 체인(중첩 서브쿼리)을 분석하고, 각 단계에서 무엇을 반환하는지 설명하시오.

```sql
SELECT last_name, salary
FROM   employees
WHERE  department_id IN
       (SELECT department_id
        FROM   departments
        WHERE  location_id =
               (SELECT location_id
                FROM   locations
                WHERE  city = 'Seattle'));
```

(1) 가장 안쪽 서브쿼리의 결과를 설명하시오.  
(2) 두 번째 서브쿼리의 결과를 설명하시오.  
(3) 메인 쿼리의 최종 결과를 설명하시오.

---

**[상-10]** 다음 요구사항을 서브쿼리만으로(JOIN 없이) 구현하시오.

요구사항: "급여 등급(JOB_GRADES)이 'E' 등급인 사원의 last_name, salary, job_id를 출력하라."  
(JOB_GRADES: grade_level='E' → lowest_sal=15000, highest_sal=24999)  
(힌트: WHERE salary BETWEEN을 서브쿼리로 표현)  
salary 내림차순 정렬.
