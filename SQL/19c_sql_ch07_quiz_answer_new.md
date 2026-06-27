# Oracle Database 19c: SQL Workshop
## Chapter 7 — 다중 테이블 데이터 조회: JOIN | 연습문제 모범답안

---

# ★ 하 (기초) — 모범답안

---

**[하-01] 답: ②**

여러 테이블에 분산 저장된 데이터를 하나의 결과 집합으로 결합하기 위해 JOIN을 사용한다.

---

**[하-02] 답: ①**

NATURAL JOIN은 두 테이블에서 이름이 같은 모든 열을 기준으로 자동으로 등가 조인을 수행한다.

---

**[하-03] 답: ②**

NATURAL JOIN은 두 테이블에서 이름이 같은 **모든** 열을 기준으로 자동 조인한다.  
EMPLOYEES와 DEPARTMENTS에서 같은 이름의 열: `department_id`, `manager_id` 등 여러 열이 모두 조인 기준이 된다.  
이 때문에 의도치 않은 결과가 나올 수 있어 USING 또는 ON 절을 권장한다.

---

**[하-04] 답: ②**

USING 절은 두 테이블에 같은 이름의 열이 여러 개 있지만, 그 중 특정 열 하나로만 조인하고 싶을 때 사용한다.

---

**[하-05] 답: ①**

`e.department_id` — USING 절에 사용된 열에는 테이블 별칭(접두사)을 붙일 수 없다.  
**ORA-25154: column part of USING clause cannot have qualifier**  
수정: `e.department_id` → `department_id`

---

**[하-06] 답: ④**

④가 잘못된 설명이다. ON 절은 사용자가 명시적으로 조인 조건을 지정해야 한다.  
"자동으로 동명 열을 모두 조인 기준으로 사용"하는 것은 NATURAL JOIN의 특성이다.

---

**[하-07] 답: ②**

INNER JOIN(기본 JOIN)은 조인 조건을 만족하는 행만 반환한다.  
조건에 맞지 않는 행은 결과에서 제외된다.

---

**[하-08] 답: ③**

Self-Join을 사용한다.  
EMPLOYEES 테이블을 `worker`와 `manager` 두 개의 별칭으로 참조하여 `worker.manager_id = manager.employee_id` 조건으로 조인한다.

---

**[하-09] 답: ②**

LEFT OUTER JOIN은 왼쪽 테이블(employees)의 모든 행을 반환한다.  
department_id가 NULL인 Grant 사원도 포함되며, 해당 행의 d.department_name은 NULL이 된다.

---

**[하-10] 답: ②**

RIGHT OUTER JOIN은 오른쪽 테이블(departments)의 모든 행을 반환한다.  
사원이 없는 부서 190도 포함되며, e.last_name은 NULL이 된다.

---

**[하-11] 답: ③**

FULL OUTER JOIN은 LEFT와 RIGHT OUTER JOIN의 결과를 합친 것으로, 양쪽 테이블에서 조인 조건을 만족하지 않는 행도 모두 포함한다.

---

**[하-12] 답: ④**

CROSS JOIN은 카테시안 곱을 생성한다.  
결과 행 수 = 107 × 27 = **2,889행**

---

**[하-13] 답: ②**

비등가 조인은 등호(=) 이외의 조건을 사용한다.  
대표적으로 `BETWEEN ... AND ...`를 사용하여 급여 범위에 해당하는 등급을 조회한다.

---

**[하-14] 답: ③**

같은 테이블(employees)을 `worker`와 `manager`라는 두 개의 별칭으로 참조하여 조인하는 **Self-Join**이다.

---

**[하-15] 답: ②**

NATURAL JOIN에서 조인 열에 테이블 별칭을 붙이면 **ORA-25155** 오류가 발생한다.  
(USING 절 사용 시 별칭을 붙이면 ORA-25154)

---

**[하-16] 답: ③**

FROM 절에 쉼표로 테이블을 나열하고 ON/USING 없이 사용하면 카테시안 곱이 발생한다:  
`FROM employees, departments` → 107 × 27 = 2,889행

---

**[하-17] 답: ③**

두 가지 방식 모두 사용 가능하지만, ANSI SQL 표준은 ② 방식(`JOIN ... ON ...`)이다.  
쉼표 방식은 구형 Oracle 구문으로 호환은 되지만 ANSI 표준이 아니다.

---

**[하-18] 답: ②**

AND 절 또는 WHERE 절로 조인 이외의 추가 필터 조건을 넣을 수 있다.  
두 방식 모두 동일한 결과를 반환한다.

---

**[하-19] 답: ③**

사원이 없는 부서를 포함하려면 오른쪽 테이블(departments)의 모든 행을 포함하는 **RIGHT OUTER JOIN**을 사용한다.  
또는 departments를 왼쪽에 놓고 LEFT OUTER JOIN을 사용해도 동일한 결과.

---

**[하-20] 답: ②**

INNER JOIN(기본 JOIN)은 조인 조건을 만족하는 행만 반환한다.  
department_id = NULL인 Grant 사원은 어떤 부서와도 일치하지 않으므로 제외되어 **106행** 반환.

---

# ★★ 중 (응용) — 모범답안

---

**[중-01] 답**

```sql
SELECT last_name, department_name
FROM   employees
JOIN   departments
USING  (department_id)
ORDER BY last_name;
```

---

**[중-02] 답**

```sql
SELECT e.employee_id, e.last_name, e.department_id, d.location_id
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id)
ORDER BY e.employee_id;
```

> ON 절 조인은 department_id가 NULL인 사원을 자동으로 제외한다 (INNER JOIN 기본 동작).

---

**[중-03] 답**

```sql
SELECT employee_id, first_name, job_id, job_title
FROM   employees
NATURAL JOIN jobs;
```

> NATURAL JOIN: employees와 jobs의 공통 열인 job_id로 자동 조인.

---

**[중-04] 답**

```sql
SELECT worker.last_name  AS emp,
       manager.last_name AS mgr
FROM   employees worker
JOIN   employees manager
ON     (worker.manager_id = manager.employee_id)
ORDER BY worker.last_name;
```

---

**[중-05] 답**

```sql
SELECT e.last_name, e.salary, j.grade_level
FROM   employees e
JOIN   job_grades j
ON     e.salary BETWEEN j.lowest_sal AND j.highest_sal
ORDER BY e.salary;
```

---

**[중-06] 답**

```sql
SELECT e.last_name, d.department_name
FROM   employees e
LEFT OUTER JOIN departments d
ON     (e.department_id = d.department_id);
```

> department_id = NULL인 Grant 사원도 포함, d.department_name = NULL로 출력.

---

**[중-07] 답**

```sql
SELECT e.last_name, d.department_id, d.department_name
FROM   employees e
RIGHT OUTER JOIN departments d
ON     (e.department_id = d.department_id)
ORDER BY d.department_id;
```

---

**[중-08] 답**

```sql
SELECT e.last_name, d.department_id, d.department_name
FROM   employees e
FULL OUTER JOIN departments d
ON     (e.department_id = d.department_id);
```

---

**[중-09] 답**

```sql
SELECT e.employee_id, e.last_name, d.department_name, l.city
FROM   employees e
JOIN   departments d ON (e.department_id = d.department_id)
JOIN   locations l   ON (d.location_id = l.location_id);
```

---

**[중-10] 답**

```sql
SELECT e.last_name, e.department_id, d.department_name, e.salary
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id)
WHERE  e.department_id IN (50, 80)
ORDER BY e.salary DESC;
```

---

**[중-11] 답**

```sql
SELECT worker.last_name AS emp, manager.last_name AS mgr
FROM   employees worker
JOIN   employees manager
ON     (worker.manager_id = manager.employee_id)
WHERE  manager.employee_id = 100;
```

---

**[중-12] 답**

```sql
SELECT   j.job_title, COUNT(*) AS emp_count, ROUND(AVG(e.salary)) AS avg_salary
FROM     employees e
JOIN     jobs j ON (e.job_id = j.job_id)
GROUP BY j.job_title
ORDER BY avg_salary DESC;
```

---

**[중-13] 답**

```sql
SELECT e.last_name, d.department_name
FROM   employees e
JOIN   departments d ON (e.department_id = d.department_id)
JOIN   locations l   ON (d.location_id = l.location_id)
WHERE  l.location_id = 1500;
```

---

**[중-14] 답**

```sql
SELECT e.employee_id, e.last_name, e.department_id, d.location_id
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id)
WHERE  e.manager_id = 149;
```

---

**[중-15] 답**

```sql
SELECT e.last_name, e.salary, j.grade_level
FROM   employees e
JOIN   job_grades j
ON     e.salary BETWEEN j.lowest_sal AND j.highest_sal
WHERE  j.grade_level >= 'D'
ORDER BY e.salary DESC;
```

---

**[중-16] 답**

```sql
SELECT e.last_name, d.department_name, l.city
FROM   employees e
JOIN   departments d ON (e.department_id = d.department_id)
JOIN   locations l   ON (d.location_id = l.location_id)
WHERE  l.country_id = 'US';
```

---

**[중-17] 답**

```sql
SELECT   d.department_name,
         MAX(e.salary) AS max_salary,
         MIN(e.salary) AS min_salary
FROM     employees e
JOIN     departments d ON (e.department_id = d.department_id)
GROUP BY d.department_name
ORDER BY max_salary DESC;
```

---

**[중-18] 답**

```sql
SELECT e1.last_name AS emp1, e2.last_name AS emp2, e1.department_id
FROM   employees e1
JOIN   employees e2
ON     (e1.department_id = e2.department_id
        AND e1.employee_id < e2.employee_id)
WHERE  e1.department_id = 50
ORDER BY e1.last_name, e2.last_name;
```

> `e1.employee_id < e2.employee_id`: 중복 쌍 방지 (A-B와 B-A가 동시에 나오지 않게)

---

**[중-19] 답**

```sql
SELECT   l.city, COUNT(*) AS emp_count
FROM     employees e
JOIN     departments d USING (department_id)
JOIN     locations l   USING (location_id)
GROUP BY l.city
ORDER BY l.city;
```

---

**[중-20] 답**

```sql
SELECT e.last_name, e.job_id, e.salary, j.max_salary
FROM   employees e
JOIN   jobs j ON (e.job_id = j.job_id)
WHERE  e.salary = j.max_salary;
```

---

# ★★★ 상 (심화) — 모범답안

---

**[상-01] 답**

**(1) 오류 원인:**

```sql
WHERE  e.department_id IN (50, 80)  -- 오류!
```

USING 절로 조인 시 `department_id` 열에는 테이블 별칭(e.)을 붙일 수 없다.  
→ **ORA-25154: column part of USING clause cannot have qualifier**

**(2) 수정된 SQL:**

```sql
-- 방법 1: 별칭 제거
SELECT   department_id, d.department_name, COUNT(*) AS cnt
FROM     employees e
JOIN     departments d
USING    (department_id)
WHERE    department_id IN (50, 80)
GROUP BY department_id, d.department_name;

-- 방법 2: ON 절로 변경 (별칭 사용 가능)
SELECT   e.department_id, d.department_name, COUNT(*) AS cnt
FROM     employees e
JOIN     departments d
ON       (e.department_id = d.department_id)
WHERE    e.department_id IN (50, 80)
GROUP BY e.department_id, d.department_name;
```

---

**[상-02] 답**

**(1) INNER JOIN vs LEFT OUTER JOIN**

```sql
-- INNER JOIN: 조인 조건을 만족하는 행만 반환
SELECT e.last_name, d.department_name
FROM   employees e JOIN departments d
ON     (e.department_id = d.department_id);
-- Grant(department_id=NULL) 제외 → 106행

-- LEFT OUTER JOIN: 왼쪽 테이블 모든 행 반환
SELECT e.last_name, d.department_name
FROM   employees e LEFT OUTER JOIN departments d
ON     (e.department_id = d.department_id);
-- Grant 포함 → 107행, Grant의 department_name = NULL
```

**(2) LEFT OUTER JOIN vs FULL OUTER JOIN**

```sql
-- LEFT OUTER JOIN: 왼쪽(employees) 불일치 행 포함
-- Grant(dept=NULL)만 추가 → 107행

-- FULL OUTER JOIN: 양쪽 불일치 행 모두 포함
-- Grant + 사원 없는 부서(190 등) 모두 추가 → 107 + 16(사원 없는 부서 수) = 123행(가정)
```

**(3) CROSS JOIN vs INNER JOIN**

```sql
-- CROSS JOIN: 카테시안 곱 (107 × 27 = 2,889행)
SELECT e.last_name, d.department_name
FROM   employees CROSS JOIN departments;

-- INNER JOIN: 조건 만족 행만 (106행)
SELECT e.last_name, d.department_name
FROM   employees e JOIN departments d
ON     (e.department_id = d.department_id);
```

CROSS JOIN은 조인 조건 없이 모든 행의 조합을 반환하며, 일반적으로 의미 없는 데이터가 대부분이다.

---

**[상-03] 답**

```sql
SELECT e.last_name, d.department_name, l.city, c.country_name
FROM   employees e
JOIN   departments d ON (e.department_id = d.department_id)
JOIN   locations l   ON (d.location_id = l.location_id)
JOIN   countries c   ON (l.country_id = c.country_id)
ORDER BY c.country_name, e.last_name;
```

---

**[상-04] 답**

```sql
-- 인라인 뷰를 사용한 방법
SELECT e.last_name, e.salary, e.department_id, dept_avg.avg_salary
FROM   employees e
JOIN   (SELECT department_id, ROUND(AVG(salary), 2) AS avg_salary
        FROM   employees
        GROUP BY department_id) dept_avg
ON     (e.department_id = dept_avg.department_id)
WHERE  e.salary > dept_avg.avg_salary
ORDER BY e.department_id, e.salary DESC;
```

> **핵심:** 서브쿼리(인라인 뷰)로 부서별 평균 급여를 먼저 계산한 후, 원본 테이블과 조인하여 조건 비교.

---

**[상-05] 답**

**NATURAL JOIN과 ON 절 조인의 결과 차이:**

HR 스키마에서 EMPLOYEES와 DEPARTMENTS 두 테이블을 NATURAL JOIN하면:

```sql
-- NATURAL JOIN이 사용하는 공통 열 확인
-- EMPLOYEES  와 DEPARTMENTS의 공통 열: department_id, manager_id
-- → 두 열 모두 조인 기준이 됨
SELECT * FROM employees NATURAL JOIN departments;
```

**문제:** `manager_id` 열이 양쪽에 모두 있다.  
- EMPLOYEES.manager_id: 해당 사원의 관리자 ID  
- DEPARTMENTS.manager_id: 해당 부서의 관리자 ID  

두 값이 같아야 하는 조건이 추가되어 **훨씬 적은 결과**가 반환된다.

```sql
-- ON 절 사용: department_id만 기준으로 명시적 조인
SELECT e.employee_id, e.last_name, d.department_name
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id);
-- manager_id 조건 없음 → 더 많은 결과 반환
```

**결론:** EMPLOYEES와 DEPARTMENTS처럼 여러 공통 열이 있을 때 NATURAL JOIN은 위험하다.  
명시적인 ON 또는 USING 절 사용을 권장한다.

---

**[상-06] 답**

```sql
SELECT e.last_name, e.department_id, d.department_name
FROM   employees e
FULL OUTER JOIN departments d
ON     (e.department_id = d.department_id)
WHERE  e.last_name IS NULL OR d.department_name IS NULL;
```

**(1) 반환 행의 의미:**

- `e.last_name IS NULL`: 사원이 없는 부서 (FULL OUTER JOIN에서 오른쪽만 존재하는 행)
- `d.department_name IS NULL`: 부서가 없는 사원 (FULL OUTER JOIN에서 왼쪽만 존재하는 행)

즉, 이 쿼리는 **양쪽 테이블에서 불일치하는 행만** 추출하는 것이다.

**(2) 예상 결과 (HR 스키마):**

- `e.last_name IS NULL` → 사원 없는 부서들 (부서 190 포함)
- `d.department_name IS NULL` → Grant 사원 (department_id = NULL)

결과: 부서 없는 사원 1명 + 사원 없는 부서 n개 = 약 17행 예상

---

**[상-07] 답**

**(1) 결과 행 수 비교:**

**(A) WHERE 절에 d.department_name = 'Sales':**

```sql
LEFT OUTER JOIN departments d ON (...)
WHERE  d.department_name = 'Sales';
```

LEFT OUTER JOIN으로 107명 반환 후, WHERE 조건으로 'Sales' 부서 이외 행(d.department_name이 NULL이거나 'Sales'가 아닌 행) 제거.  
→ 결과: 'Sales' 부서(부서 80) 사원 34명만 반환  
(Grant 사원도 d.department_name = NULL이므로 WHERE 조건에서 제외됨)

**(B) ON 절에 AND d.department_name = 'Sales':**

```sql
LEFT OUTER JOIN departments d ON (e.department_id = d.department_id
                                  AND d.department_name = 'Sales');
```

Sales 부서 이외의 사원은 조인 조건을 만족하지 않으므로 d.* 열이 NULL로 채워진 채 LEFT OUTER JOIN으로 모두 포함.  
→ 결과: 107명 전체 반환 (Sales 부서 34명은 department_name='Sales', 나머지는 NULL)

**(2) (B) 방식 사용 시점:**

왼쪽 테이블의 모든 행을 유지하면서, 오른쪽 테이블에서 특정 조건에 맞는 행만 조인하고 싶을 때 사용한다.  
WHERE 절에 조건을 넣으면 OUTER JOIN의 효과가 사라지므로 주의해야 한다.

---

**[상-08] 답**

```sql
SELECT worker.last_name   AS emp,
       mgr1.last_name     AS direct_manager,
       mgr2.last_name     AS manager_of_manager
FROM   employees worker
JOIN   employees mgr1  ON (worker.manager_id = mgr1.employee_id)
JOIN   employees mgr2  ON (mgr1.manager_id   = mgr2.employee_id)
ORDER BY worker.last_name;
```

> 3번의 Self-Join:
> - worker: 사원 본인
> - mgr1: 직속 관리자 (worker.manager_id = mgr1.employee_id)
> - mgr2: 관리자의 관리자 (mgr1.manager_id = mgr2.employee_id)
>
> INNER JOIN 사용 시 mgr2가 없는 경우(mgr1.manager_id = NULL)는 제외된다.

---

**[상-09] 답**

```sql
SELECT   d.department_name, j.grade_level, COUNT(*) AS emp_count
FROM     employees e
JOIN     departments d  ON (e.department_id = d.department_id)
JOIN     jobs jb        ON (e.job_id = jb.job_id)
JOIN     job_grades j   ON (e.salary BETWEEN j.lowest_sal AND j.highest_sal)
WHERE    j.grade_level >= 'C'
GROUP BY d.department_name, j.grade_level
ORDER BY d.department_name, j.grade_level;
```

> - `jobs` 테이블: job_title 조회용  
> - `job_grades` 테이블: salary 범위로 비등가 조인 (grade_level 조회)  
> - `WHERE j.grade_level >= 'C'`: 문자 비교로 C, D, E 등급 필터링

---

**[상-10] 답**

**가장 적합한 방법: 방법 2**

```sql
SELECT e.last_name, d.department_name, l.city
FROM   employees e
LEFT OUTER JOIN departments d ON (e.department_id = d.department_id)
LEFT OUTER JOIN locations l   ON (d.location_id = l.location_id);
```

**이유 분석:**

| 방법 | 결과 | 적합성 |
|------|------|--------|
| 방법 1 (LEFT + INNER) | Grant 사원은 departments에서 NULL이므로 locations의 INNER JOIN에서 제외 → 106행 | 부적합 |
| 방법 2 (LEFT + LEFT) | Grant 사원 포함 107명, dept/location이 NULL인 경우 NULL 처리 | ✅ 적합 |
| 방법 3 (INNER + INNER) | department_id=NULL인 사원 제외 → 106행 | 부적합 |

**요구사항 재확인:** "부서가 없는 사원(1명)을 포함"  
→ departments 조인에서 LEFT OUTER JOIN 필요  
→ locations도 LEFT OUTER JOIN 사용 (departments 결과가 NULL인 행을 보존하기 위해)

방법 1처럼 첫 번째는 LEFT이지만 두 번째가 INNER JOIN이면, 첫 번째 LEFT JOIN 결과에서 d.location_id = NULL인 행이 두 번째 INNER JOIN에서 제외된다.
