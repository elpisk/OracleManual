# Oracle Database 19c: SQL Workshop
## Chapter 7 — 다중 테이블 데이터 조회: JOIN | 연습문제

> **사용 스키마:** HR (Human Resources)  
> **범위:** Natural Join, USING 절, ON 절, Self-Join, Nonequijoin, LEFT/RIGHT/FULL OUTER JOIN, CROSS JOIN, 3방향 조인, 테이블 별칭

---

# ★ 하 (기초) — 20문제

---

**[하-01]** JOIN이 필요한 이유로 가장 적합한 것은?

① 한 테이블의 행 수를 늘리기 위해  
② 여러 테이블에 분산된 데이터를 하나의 결과로 결합하기 위해  
③ WHERE 절을 대체하기 위해  
④ 데이터를 정렬하기 위해

---

**[하-02]** NATURAL JOIN에 대한 설명으로 올바른 것은?

① 두 테이블에서 이름이 같은 모든 열을 기준으로 자동으로 등가 조인을 수행한다  
② 사용자가 지정한 열로만 조인한다  
③ 이름이 다른 열끼리 조인하는 데 사용된다  
④ NULL 행도 모두 반환한다

---

**[하-03]** 다음 SQL 문에서 조인에 사용되는 열은?

```sql
SELECT employee_id, department_id, department_name
FROM   employees
NATURAL JOIN departments;
```

① employee_id  
② department_id와 manager_id 등 이름이 같은 모든 열  
③ department_name  
④ location_id

---

**[하-04]** USING 절을 사용하는 경우로 적합한 것은?

① 이름이 다른 열끼리 조인할 때  
② 두 테이블에 같은 이름의 열이 여러 개 있지만 하나로만 조인하고 싶을 때  
③ NULL 값을 포함한 행을 모두 반환할 때  
④ Cartesian product를 생성할 때

---

**[하-05]** 다음 SQL 문의 오류는?

```sql
SELECT e.department_id, d.department_name
FROM   employees e
JOIN   departments d
USING  (department_id);
```

① `e.department_id` — USING 절에 사용된 열에 테이블 별칭 사용 불가 → ORA-25154  
② 구문 오류 — USING 절 다음에 ON 절이 없어서  
③ FROM 절 오류  
④ 오류 없음 — 올바른 SQL이다

---

**[하-06]** ON 절의 장점으로 올바르지 않은 것은?

① 이름이 다른 열끼리 조인 가능  
② 조인 조건과 검색 조건을 분리하여 가독성 향상  
③ 임의의 조건(BETWEEN, >, < 등) 사용 가능  
④ 자동으로 동명 열을 모두 조인 기준으로 사용

---

**[하-07]** INNER JOIN의 특성으로 올바른 것은?

① 양쪽 테이블의 모든 행을 반환한다  
② 조인 조건을 만족하는 행만 반환한다  
③ 왼쪽 테이블의 불일치 행을 NULL로 포함한다  
④ CROSS JOIN과 동일한 결과를 반환한다

---

**[하-08]** HR 스키마에서 EMPLOYEES 테이블을 자기 자신에 조인하여 사원과 관리자 이름을 조회할 때 사용하는 조인은?

① Natural Join  
② USING 절 조인  
③ Self-Join  
④ CROSS JOIN

---

**[하-09]** 다음 SQL 문에서 결과에 포함되는 행을 고르시오.

```sql
SELECT e.last_name, d.department_name
FROM   employees e
LEFT OUTER JOIN departments d
ON     (e.department_id = d.department_id);
```

① department_id가 있는 사원만  
② department_id가 없는 사원(Grant)도 포함, d.department_name = NULL  
③ 사원 없는 부서도 포함, e.last_name = NULL  
④ 양쪽 모두 불일치 행 포함

---

**[하-10]** RIGHT OUTER JOIN에서 반환하는 행은?

① 왼쪽 테이블(employees)의 모든 행  
② 오른쪽 테이블(departments)의 모든 행 포함, 사원 없는 부서도 NULL로 포함  
③ 조인 조건을 만족하는 행만  
④ 카테시안 곱

---

**[하-11]** FULL OUTER JOIN의 결과로 올바른 것은?

① 조인 조건을 만족하는 행만 반환  
② LEFT OUTER JOIN 결과만 반환  
③ 양쪽 테이블의 불일치 행을 모두 포함 (불일치 측 열은 NULL)  
④ CROSS JOIN과 동일

---

**[하-12]** CROSS JOIN의 결과 행 수는?

```sql
-- EMPLOYEES 107행, DEPARTMENTS 27행
SELECT * FROM employees CROSS JOIN departments;
```

① 107  
② 27  
③ 134 (107 + 27)  
④ 2,889 (107 × 27)

---

**[하-13]** 비등가 조인(Nonequijoin)에서 주로 사용하는 조건 연산자는?

① = (등호)  
② BETWEEN ... AND ...  
③ IS NULL  
④ LIKE

---

**[하-14]** 다음 SQL 문에서 조인 유형은?

```sql
SELECT worker.last_name, manager.last_name
FROM   employees worker
JOIN   employees manager
ON     (worker.manager_id = manager.employee_id);
```

① Natural Join  
② USING 절 조인  
③ Self-Join  
④ CROSS JOIN

---

**[하-15]** NATURAL JOIN에서 조인 열에 테이블 별칭을 붙이면?

① 정상 실행된다  
② ORA-25155 오류 발생  
③ 자동으로 별칭이 무시된다  
④ INNER JOIN으로 동작한다

---

**[하-16]** 다음 중 카테시안 곱이 발생하는 경우는?

① `FROM employees e JOIN departments d ON (e.department_id = d.department_id)`  
② `FROM employees NATURAL JOIN departments`  
③ `FROM employees, departments` (ON/USING 없이 쉼표만 사용)  
④ `FROM employees JOIN departments USING (department_id)`

---

**[하-17]** 3방향 조인(Three-Way Join)의 구문으로 올바른 것은?

① `FROM a, b, c WHERE a.id = b.id AND b.id = c.id`  
② `FROM a JOIN b ON ... JOIN c ON ...`  
③ 두 가지 모두 가능하지만 ②가 ANSI 표준  
④ Oracle에서는 3방향 조인을 지원하지 않는다

---

**[하-18]** ON 절에서 추가 필터 조건을 넣는 방법으로 올바른 것은?

① ON 절에는 조인 조건만 넣을 수 있다  
② AND 절 또는 WHERE 절로 추가 조건을 넣을 수 있다  
③ HAVING 절을 사용해야 한다  
④ ORDER BY 절에 추가 조건을 넣는다

---

**[하-19]** EMPLOYEES와 DEPARTMENTS 테이블을 조인할 때, 사원이 없는 부서(부서 190 등)도 결과에 포함하려면 어떤 JOIN을 사용해야 하는가?

① INNER JOIN  
② LEFT OUTER JOIN  
③ RIGHT OUTER JOIN  
④ CROSS JOIN

---

**[하-20]** 다음 SQL 문의 결과 행 수는? (HR 스키마 기준, EMPLOYEES 107명 중 department_id=NULL인 사원 1명)

```sql
SELECT e.last_name, d.department_name
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id);
```

① 107  
② 106  
③ 108  
④ 27

---

# ★★ 중 (응용) — 20문제

---

**[중-01]** EMPLOYEES와 DEPARTMENTS 테이블을 department_id로 조인하여 사원의 last_name, department_name을 출력하시오.  
(USING 절 사용, last_name 오름차순 정렬)

---

**[중-02]** EMPLOYEES와 DEPARTMENTS 테이블을 ON 절로 조인하여 employee_id, last_name, department_id, location_id를 출력하시오.  
(department_id가 NULL인 사원 제외, employee_id 오름차순)

---

**[중-03]** EMPLOYEES와 JOBS 테이블을 NATURAL JOIN으로 조인하여 employee_id, first_name, job_id, job_title을 출력하시오.

---

**[중-04]** EMPLOYEES 테이블에서 Self-Join을 사용하여 사원 이름(worker.last_name)과 관리자 이름(manager.last_name)을 출력하시오.  
사원 이름 오름차순 정렬.

---

**[중-05]** EMPLOYEES와 JOB_GRADES 테이블을 비등가 조인(Nonequijoin)으로 조인하여 last_name, salary, grade_level을 출력하시오.  
salary 오름차순 정렬.

---

**[중-06]** EMPLOYEES 테이블에서 LEFT OUTER JOIN을 사용하여 모든 사원(department_id=NULL 포함)의 last_name과 department_name을 출력하시오.

---

**[중-07]** EMPLOYEES와 DEPARTMENTS 테이블을 RIGHT OUTER JOIN으로 조인하여 사원이 없는 부서도 포함하여 출력하시오.  
출력 열: last_name, department_id, department_name  
department_id 오름차순 정렬.

---

**[중-08]** EMPLOYEES와 DEPARTMENTS 테이블을 FULL OUTER JOIN으로 조인하여 양쪽 불일치 행을 모두 포함하여 출력하시오.

---

**[중-09]** EMPLOYEES, DEPARTMENTS, LOCATIONS 테이블을 3방향 조인으로 연결하여 employee_id, last_name, department_name, city를 출력하시오.  
(ON 절 사용)

---

**[중-10]** EMPLOYEES와 DEPARTMENTS를 조인하되, 부서 50과 80 사원만 출력하시오.  
출력 열: last_name, department_id, department_name, salary  
salary 내림차순 정렬.

---

**[중-11]** EMPLOYEES 테이블에서 Self-Join을 사용하여 manager_id가 100인 관리자 아래에 있는 사원의 이름과 관리자 이름을 출력하시오.

---

**[중-12]** EMPLOYEES와 JOBS를 ON 절로 조인하여 직무 제목(job_title)별 사원 수와 평균 급여를 출력하시오.  
평균 급여 내림차순 정렬.

---

**[중-13]** EMPLOYEES와 DEPARTMENTS를 조인하여 Seattle(시애틀, location_id=1500)에 있는 사원들의 last_name과 department_name을 출력하시오.

---

**[중-14]** EMPLOYEES와 DEPARTMENTS를 ON 절로 조인하고, manager_id=149인 사원만 필터링하여 employee_id, last_name, department_id, location_id를 출력하시오.

---

**[중-15]** EMPLOYEES와 JOB_GRADES를 비등가 조인으로 연결하되, 급여 등급이 'D' 이상인 사원만 출력하시오.  
출력 열: last_name, salary, grade_level  
salary 내림차순 정렬.

---

**[중-16]** EMPLOYEES, DEPARTMENTS, LOCATIONS를 3방향 조인으로 연결하여 'Americas' 지역에 속한 사원을 조회하시오.  
(LOCATIONS의 country_id = 'US' 조건 사용)

---

**[중-17]** EMPLOYEES와 DEPARTMENTS를 조인하여 부서별 최대 급여와 최소 급여를 출력하시오.  
(GROUP BY department_name 적용, 최대 급여 내림차순)

---

**[중-18]** EMPLOYEES 테이블을 Self-Join하여 같은 부서에 근무하는 사원 쌍(pair)을 출력하시오.  
조건: e1.employee_id < e2.employee_id (중복 제거), department_id = 50 한정

---

**[중-19]** EMPLOYEES와 DEPARTMENTS를 USING 절로 조인하여 city별 사원 수를 출력하시오.  
(LOCATIONS 테이블도 조인 필요, city 오름차순)

---

**[중-20]** EMPLOYEES와 JOBS를 ON 절로 조인하여 salary가 해당 직무의 max_salary와 같은 사원을 출력하시오.  
출력 열: last_name, job_id, salary, max_salary

---

# ★★★ 상 (심화) — 10문제

---

**[상-01]** 다음 SQL 문의 문제점을 분석하고 수정하시오.

```sql
SELECT e.department_id, d.department_name, COUNT(*) AS cnt
FROM   employees e
JOIN   departments d
USING  (department_id)
WHERE  e.department_id IN (50, 80)
GROUP BY e.department_id, d.department_name;
```

(1) 오류가 발생하는 이유를 설명하시오.  
(2) 올바르게 수정된 SQL을 작성하시오.

---

**[상-02]** 다음 각 JOIN 유형의 차이를 예시 SQL과 함께 설명하시오.

(1) INNER JOIN vs LEFT OUTER JOIN  
(2) LEFT OUTER JOIN vs FULL OUTER JOIN  
(3) CROSS JOIN vs INNER JOIN

---

**[상-03]** EMPLOYEES, DEPARTMENTS, LOCATIONS, COUNTRIES 테이블을 4방향 조인으로 연결하여 사원이 근무하는 국가 이름(country_name)을 출력하시오.  
출력 열: last_name, department_name, city, country_name  
country_name 오름차순 → last_name 오름차순 정렬

---

**[상-04]** 다음 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항: "부서별로 해당 부서의 평균 급여보다 높은 급여를 받는 사원을 조회한다."

출력 열: e.last_name, e.salary, e.department_id, 부서 평균 급여  
(힌트: 인라인 뷰 또는 Self-Join + GROUP BY 조합)

---

**[상-05]** NATURAL JOIN과 ON 절 조인의 결과가 다를 수 있는 이유를 설명하고, 예시를 들어 논하시오.

HR 스키마에서 `employees NATURAL JOIN departments`와  
`employees e JOIN departments d ON (e.department_id = d.department_id)`  
의 결과가 다른 이유와 어떤 열이 문제가 되는지 분석하시오.

---

**[상-06]** 다음 SQL 문을 분석하여 결과를 예측하시오.

```sql
SELECT e.last_name, e.department_id, d.department_name
FROM   employees e
FULL OUTER JOIN departments d
ON     (e.department_id = d.department_id)
WHERE  e.last_name IS NULL OR d.department_name IS NULL;
```

(1) 이 쿼리가 반환하는 행의 의미를 설명하시오.  
(2) HR 스키마 기준으로 예상되는 결과를 서술하시오.

---

**[상-07]** 다음 두 쿼리의 결과 차이를 설명하시오.

```sql
-- (A)
SELECT e.last_name, d.department_name
FROM   employees e
LEFT OUTER JOIN departments d
ON     (e.department_id = d.department_id)
WHERE  d.department_name = 'Sales';

-- (B)
SELECT e.last_name, d.department_name
FROM   employees e
LEFT OUTER JOIN departments d
ON     (e.department_id = d.department_id
        AND d.department_name = 'Sales');
```

(1) 두 쿼리의 결과 행 수를 비교하시오.  
(2) 어떤 경우에 (B) 방식을 사용하는지 설명하시오.

---

**[상-08]** EMPLOYEES 테이블을 Self-Join하여 관리자 계층 구조를 2단계로 출력하시오.

요구사항:
- 사원(worker), 직속 관리자(mgr1), 관리자의 관리자(mgr2) 이름을 출력
- 관리자의 관리자가 없는 경우는 제외
- 사원 이름 오름차순 정렬

---

**[상-09]** 다음 비즈니스 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항: "각 사원의 급여 등급(JOB_GRADES)을 조회하되, 부서 이름(DEPARTMENTS)과 직무 제목(JOBS)도 함께 표시하라. 급여 등급 C 이상인 사원만 포함하며, 부서별로 몇 명인지 카운트하라."

출력 열: department_name, grade_level, 사원 수  
정렬: department_name 오름차순 → grade_level 오름차순

---

**[상-10]** 다음 쿼리의 성능 관점에서 올바른 JOIN 방식을 선택하고 이유를 설명하시오.

시나리오: 107명의 사원과 27개 부서가 있다. 부서가 없는 사원(1명)을 포함하여, 사원별 부서 이름과 위치를 조회해야 한다. 사원이 없는 부서는 결과에 포함하지 않는다.

아래 세 가지 방법 중 가장 적합한 것을 선택하고 이유를 설명하시오:
```sql
-- 방법 1
SELECT e.last_name, d.department_name, l.city
FROM   employees e
LEFT OUTER JOIN departments d ON (e.department_id = d.department_id)
JOIN   locations l ON (d.location_id = l.location_id);

-- 방법 2
SELECT e.last_name, d.department_name, l.city
FROM   employees e
LEFT OUTER JOIN departments d ON (e.department_id = d.department_id)
LEFT OUTER JOIN locations l ON (d.location_id = l.location_id);

-- 방법 3
SELECT e.last_name, d.department_name, l.city
FROM   employees e
JOIN   departments d ON (e.department_id = d.department_id)
JOIN   locations l ON (d.location_id = l.location_id);
```
