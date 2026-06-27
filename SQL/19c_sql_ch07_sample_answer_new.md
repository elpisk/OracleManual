# Oracle Database 19c: SQL Workshop
## Chapter 7 — 다중 테이블 데이터 조회: JOIN | SQL 실습 문제 모범답안

---

## Group 1. Natural Join · USING 절 모범답안 (1~6번)

---

**[1번] 답**

```sql
SELECT department_id, department_name, location_id
FROM   employees
NATURAL JOIN departments;
```

> NATURAL JOIN은 employees와 departments의 공통 열(department_id, manager_id 등)을 모두 기준으로 조인한다.  
> manager_id 조건도 추가되므로 결과가 11개 행으로 제한될 수 있다.

---

**[2번] 답**

```sql
SELECT last_name, department_name
FROM   employees
JOIN   departments
USING  (department_id)
ORDER BY last_name;
```

> USING 절에 사용된 `department_id`에는 테이블 별칭(e., d.)을 붙이면 ORA-25154 오류 발생.

---

**[3번] 답**

```sql
SELECT last_name, department_name, city
FROM   employees
JOIN   departments USING (department_id)
JOIN   locations   USING (location_id)
ORDER BY city, last_name;
```

---

**[4번] 답**

```sql
SELECT last_name, department_id, department_name
FROM   employees
JOIN   departments
USING  (department_id)
WHERE  department_id IN (50, 80)
ORDER BY last_name;
```

> USING 절 사용 시 WHERE에서도 `department_id`에 접두사 없이 사용한다.

---

**[5번] 답**

```sql
SELECT l.city, d.department_name
FROM   locations l
JOIN   departments d
USING  (location_id)
ORDER BY l.city, d.department_name;
```

---

**[6번] 답**

```sql
SELECT   j.job_title,
         j.max_salary        AS max_sal,
         MAX(e.salary)       AS actual_max
FROM     employees e
JOIN     jobs j USING (job_id)
GROUP BY j.job_title, j.max_salary
ORDER BY j.job_title;
```

---

## Group 2. ON 절 조인 · 3방향 조인 모범답안 (7~12번)

---

**[7번] 답**

```sql
SELECT e.employee_id,
       e.last_name,
       e.department_id  AS e_dept_id,
       d.department_id  AS d_dept_id,
       d.location_id
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id)
ORDER BY e.employee_id;
```

> ON 절 조인에서는 양쪽 테이블의 department_id를 별도로 출력할 수 있다.  
> USING 절 사용 시에는 department_id가 하나의 열로 병합되어 이렇게 출력하기 어렵다.

---

**[8번] 답**

```sql
SELECT e.employee_id, e.last_name, d.department_name, l.city
FROM   employees e
JOIN   departments d ON (e.department_id = d.department_id)
JOIN   locations l   ON (d.location_id = l.location_id)
ORDER BY d.department_name, e.last_name;
```

---

**[9번] 답**

```sql
SELECT e.employee_id,
       e.last_name,
       e.department_id AS e_dept,
       d.department_id AS d_dept,
       d.location_id
FROM   employees e
JOIN   departments d
ON     (e.department_id = d.department_id)
WHERE  e.manager_id = 149;
```

---

**[10번] 답**

```sql
SELECT e.last_name, l.city, l.street_address
FROM   employees e
JOIN   departments d ON (e.department_id = d.department_id)
JOIN   locations l   ON (d.location_id = l.location_id)
WHERE  e.department_id = 60;
```

---

**[11번] 답**

```sql
SELECT e.last_name, j.job_title, e.salary, j.min_salary, j.max_salary
FROM   employees e
JOIN   jobs j ON (e.job_id = j.job_id)
WHERE  e.salary >= j.max_salary * 0.9
ORDER BY e.salary DESC;
```

---

**[12번] 답**

```sql
SELECT   c.country_name, COUNT(*) AS emp_count
FROM     employees e
JOIN     departments d  ON (e.department_id = d.department_id)
JOIN     locations l    ON (d.location_id = l.location_id)
JOIN     countries c    ON (l.country_id = c.country_id)
GROUP BY c.country_name
ORDER BY c.country_name;
```

---

## Group 3. Self-Join · Nonequijoin 모범답안 (13~18번)

---

**[13번] 답**

```sql
SELECT worker.last_name  AS emp,
       manager.last_name AS mgr
FROM   employees worker
JOIN   employees manager
ON     (worker.manager_id = manager.employee_id)
ORDER BY worker.last_name;
```

> INNER JOIN 사용 시 manager_id = NULL인 King은 결과에서 제외된다 → 106행.

---

**[14번] 답**

```sql
SELECT   manager.last_name AS manager, COUNT(*) AS sub_count
FROM     employees worker
JOIN     employees manager
ON       (worker.manager_id = manager.employee_id)
GROUP BY manager.last_name
ORDER BY sub_count DESC;
```

---

**[15번] 답**

```sql
SELECT e1.last_name AS emp1, e2.last_name AS emp2,
       e1.job_id, e1.department_id
FROM   employees e1
JOIN   employees e2
ON     (e1.department_id = e2.department_id
        AND e1.job_id = e2.job_id
        AND e1.employee_id < e2.employee_id)
WHERE  e1.department_id = 80
ORDER BY e1.last_name, e2.last_name;
```

---

**[16번] 답**

```sql
SELECT e.last_name, e.salary, j.grade_level
FROM   employees e
JOIN   job_grades j
ON     e.salary BETWEEN j.lowest_sal AND j.highest_sal
ORDER BY j.grade_level, e.salary;
```

---

**[17번] 답**

```sql
SELECT   e.department_id, j.grade_level, COUNT(*) AS emp_count
FROM     employees e
JOIN     job_grades j
ON       e.salary BETWEEN j.lowest_sal AND j.highest_sal
WHERE    j.grade_level IN ('C', 'D')
GROUP BY e.department_id, j.grade_level
ORDER BY e.department_id, j.grade_level;
```

---

**[18번] 답**

```sql
SELECT worker.last_name  AS emp,
       mgr1.last_name    AS direct_mgr,
       mgr2.last_name    AS manager_of_mgr
FROM   employees worker
JOIN   employees mgr1 ON (worker.manager_id = mgr1.employee_id)
JOIN   employees mgr2 ON (mgr1.manager_id   = mgr2.employee_id)
ORDER BY worker.last_name;
```

> 3번의 Self-Join:
> - worker.manager_id = mgr1.employee_id (직속 관리자)
> - mgr1.manager_id = mgr2.employee_id (관리자의 관리자)
> - 모두 INNER JOIN이므로 mgr2가 없는 경우 제외

---

## Group 4. OUTER JOIN 모범답안 (19~24번)

---

**[19번] 답**

```sql
SELECT e.last_name, d.department_name
FROM   employees e
LEFT OUTER JOIN departments d
ON     (e.department_id = d.department_id)
ORDER BY e.last_name;
```

> Grant(department_id=NULL)도 포함 → 107행, department_name=NULL로 출력.

---

**[20번] 답**

```sql
SELECT e.last_name, d.department_id, d.department_name
FROM   employees e
RIGHT OUTER JOIN departments d
ON     (e.department_id = d.department_id)
ORDER BY d.department_id;
```

> 사원이 없는 부서(190 등)도 포함, e.last_name=NULL로 출력.

---

**[21번] 답**

```sql
SELECT e.last_name, e.department_id, d.department_name
FROM   employees e
FULL OUTER JOIN departments d
ON     (e.department_id = d.department_id)
WHERE  e.last_name IS NULL OR d.department_name IS NULL;
```

> 불일치 행만 추출:
> - `e.last_name IS NULL`: 사원이 없는 부서
> - `d.department_name IS NULL`: 부서가 없는 사원(Grant)

---

**[22번] 답**

```sql
SELECT e.last_name, d.department_name
FROM   employees e
LEFT OUTER JOIN departments d
ON     (e.department_id = d.department_id
        AND d.department_name = 'Sales');
```

> ON 절에 추가 조건을 넣으면 LEFT OUTER JOIN의 효과가 유지된다.  
> WHERE 절에 넣으면 d.department_name = NULL인 행(Sales가 아닌 사원)이 제외되어 107행이 아닌 34행만 반환.

---

**[23번] 답**

```sql
SELECT   d.department_name, COUNT(e.employee_id) AS emp_count
FROM     employees e
RIGHT OUTER JOIN departments d
ON       (e.department_id = d.department_id)
GROUP BY d.department_name
ORDER BY d.department_name;
```

> `COUNT(e.employee_id)`: NULL이 아닌 employee_id만 카운트 → 사원 없는 부서는 0으로 출력.  
> `COUNT(*)` 사용 시 사원 없는 부서도 1로 카운트되므로 주의.

---

**[24번] 답**

```sql
SELECT e.last_name, d.department_name, l.city
FROM   employees e
LEFT OUTER JOIN departments d ON (e.department_id = d.department_id)
LEFT OUTER JOIN locations l   ON (d.location_id = l.location_id)
ORDER BY e.last_name;
```

> 첫 번째 LEFT OUTER JOIN으로 Grant(dept=NULL)를 포함한다.  
> 두 번째도 LEFT OUTER JOIN을 사용해야 d.location_id=NULL인 Grant 행이 유지된다.  
> 두 번째를 INNER JOIN으로 하면 Grant가 제외된다.

---

## Group 5. 종합 응용 모범답안 (25~30번)

---

**[25번] 답**

```sql
SELECT   e.department_id  AS dept_id,
         d.department_name,
         l.city,
         COUNT(*)              AS emp_count,
         ROUND(AVG(e.salary))  AS avg_salary
FROM     employees e
JOIN     departments d ON (e.department_id = d.department_id)
JOIN     locations l   ON (d.location_id = l.location_id)
GROUP BY e.department_id, d.department_name, l.city
ORDER BY e.department_id;
```

---

**[26번] 답**

```sql
SELECT   d.department_name, j.grade_level, COUNT(*) AS emp_count
FROM     employees e
JOIN     departments d  ON (e.department_id = d.department_id)
JOIN     job_grades j   ON (e.salary BETWEEN j.lowest_sal AND j.highest_sal)
GROUP BY d.department_name, j.grade_level
ORDER BY d.department_name, j.grade_level;
```

---

**[27번] 답**

```sql
SELECT worker.last_name        AS emp,
       manager.last_name       AS mgr,
       d.department_name,
       worker.salary
FROM   employees worker
JOIN   employees manager ON (worker.manager_id = manager.employee_id)
JOIN   departments d     ON (worker.department_id = d.department_id)
ORDER BY d.department_name, worker.last_name;
```

---

**[28번] 답**

```sql
SELECT   d.department_name,
         NVL(SUM(e.salary), 0) AS total_salary
FROM     employees e
RIGHT OUTER JOIN departments d
ON       (e.department_id = d.department_id)
GROUP BY d.department_name
ORDER BY total_salary DESC;
```

> `NVL(SUM(e.salary), 0)`: 사원 없는 부서는 SUM = NULL이므로 NVL로 0 처리.

---

**[29번] 답**

```sql
SELECT e.last_name, c.country_name, j.grade_level, e.salary
FROM   employees e
JOIN   departments d  ON (e.department_id = d.department_id)
JOIN   locations l    ON (d.location_id = l.location_id)
JOIN   countries c    ON (l.country_id = c.country_id)
JOIN   job_grades j   ON (e.salary BETWEEN j.lowest_sal AND j.highest_sal)
ORDER BY c.country_name, j.grade_level, e.salary;
```

---

**[30번] 답**

```sql
SELECT   l.city,
         d.department_name,
         COUNT(*)              AS emp_count,
         MAX(e.salary)         AS max_sal,
         MIN(e.salary)         AS min_sal,
         ROUND(AVG(e.salary))  AS avg_sal
FROM     employees e
JOIN     departments d ON (e.department_id = d.department_id)
JOIN     locations l   ON (d.location_id = l.location_id)
GROUP BY l.city, d.department_name
HAVING   COUNT(*) >= 2
ORDER BY l.city, emp_count DESC;
```

> **쿼리 처리 순서:**
> 1. FROM + 3-way JOIN: 테이블 결합
> 2. GROUP BY l.city, d.department_name: 도시·부서별 그룹화
> 3. HAVING COUNT(*) >= 2: 사원 2명 미만 그룹 제외
> 4. SELECT: 집계값 계산
> 5. ORDER BY: 정렬
