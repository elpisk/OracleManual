# Oracle Database 19c: SQL Workshop
## Chapter 23 — 계층 쿼리 | SQL 실습 문제

---

> **참고:** 이 실습은 HR 스키마가 설치된 Oracle 19c 환경에서 수행하세요.

---

## Group 1: CONNECT BY 기본

**[1번]** `employees` 테이블에서 전체 조직도를 LEVEL과 함께 조회하시오. King(100)을 루트로 시작하며 `employee_id`, `last_name`, `manager_id`, `LEVEL`을 출력하고 LEVEL, employee_id 순으로 정렬하시오.

```sql
SELECT LEVEL,
       employee_id,
       last_name,
       manager_id
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER BY LEVEL, employee_id;
```

---

**[2번]** `employees` 테이블에서 `LPAD`를 사용하여 들여쓰기가 된 조직도를 출력하시오. (LEVEL당 2칸 들여쓰기, 형제 노드는 `last_name` 알파벳 순 정렬)

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS org_chart,
       employee_id,
       salary
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

---

**[3번]** De Haan(employee_id=102) 아래 모든 직원을 Top-Down으로 조회하시오. (`employee_id`, `last_name`, `LEVEL`)

```sql
SELECT LEVEL,
       employee_id,
       last_name
FROM   employees
START WITH employee_id = 102
CONNECT BY PRIOR employee_id = manager_id
ORDER BY LEVEL, employee_id;
```

---

**[4번]** `employees` 테이블에서 King의 직속 부하(LEVEL=2) 직원만 조회하시오.

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  LEVEL = 2
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER BY salary DESC;
```

---

**[5번]** `employees` 테이블에서 계층 쿼리 결과 중 LEVEL이 3 이하인 직원만 들여쓰기와 함께 조회하시오.

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*3) || last_name AS name,
       job_id
FROM   employees
WHERE  LEVEL <= 3
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

---

## Group 2: Bottom-Up & SYS_CONNECT_BY_PATH

**[6번]** Hunold(employee_id=103)에서 시작하여 루트(King)까지 Bottom-Up으로 관리자 체인을 조회하시오. (`employee_id`, `last_name`, `LEVEL`)

```sql
SELECT LEVEL,
       employee_id,
       last_name,
       manager_id
FROM   employees
START WITH employee_id = 103
CONNECT BY PRIOR manager_id = employee_id
ORDER BY LEVEL;
```

---

**[7번]** Faviet(employee_id=109)의 루트까지 Bottom-Up 경로를 `SYS_CONNECT_BY_PATH`로 조회하시오.

```sql
SELECT LEVEL,
       employee_id,
       last_name,
       SYS_CONNECT_BY_PATH(last_name, ' → ') AS full_path
FROM   employees
START WITH employee_id = 109
CONNECT BY PRIOR manager_id = employee_id
ORDER BY LEVEL;
```

---

**[8번]** 전체 조직도에서 각 직원의 루트(King)부터 현재까지의 경로를 `SYS_CONNECT_BY_PATH`로 출력하시오. 형제 노드는 `last_name` 알파벳 순 정렬하시오.

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       SYS_CONNECT_BY_PATH(last_name, ' / ') AS path
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

---

**[9번]** 급여 상위 3명의 직원 각각에 대해 루트까지의 관리자 체인을 조회하시오. (FETCH FIRST + Bottom-Up 활용)

```sql
SELECT h.start_emp_id,
       h.last_name,
       h.LEVEL,
       SYS_CONNECT_BY_PATH(h.last_name, ' → ') AS chain
FROM (
    SELECT employee_id AS start_emp_id,
           last_name,
           LEVEL,
           CONNECT_BY_ROOT employee_id AS root_start
    FROM   employees
    START WITH employee_id IN (
        SELECT employee_id FROM employees
        ORDER BY salary DESC
        FETCH FIRST 3 ROWS ONLY
    )
    CONNECT BY PRIOR manager_id = employee_id
) h
ORDER BY h.start_emp_id, h.LEVEL;
```

---

## Group 3: CONNECT_BY_ISLEAF & CONNECT_BY_ROOT

**[10번]** `employees` 테이블에서 자식이 없는 최하위 직원(잎 노드)만 조회하시오. (`employee_id`, `last_name`, `job_id`, `salary` — 급여 내림차순)

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  CONNECT_BY_ISLEAF = 1
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER BY salary DESC;
```

---

**[11번]** `employees` 테이블에서 각 직원의 잎 노드 여부(`is_leaf`)와 루트 관리자 이름(`root_mgr`)을 함께 조회하시오.

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       CONNECT_BY_ISLEAF                AS is_leaf,
       CONNECT_BY_ROOT last_name        AS root_mgr,
       CONNECT_BY_ROOT employee_id      AS root_id
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

---

**[12번]** 잎 노드 직원의 급여 평균과 전체 직원 급여 평균을 비교하시오.

```sql
WITH leaf_emps AS (
    SELECT salary
    FROM   employees
    WHERE  CONNECT_BY_ISLEAF = 1
    START WITH manager_id IS NULL
    CONNECT BY PRIOR employee_id = manager_id
)
SELECT ROUND(AVG(l.salary), 0)         AS leaf_avg_sal,
       ROUND((SELECT AVG(salary) FROM employees), 0) AS total_avg_sal
FROM   leaf_emps l;
```

---

## Group 4: 가지치기 (WHERE vs CONNECT BY)

**[13번]** `WHERE` 절을 사용하여 `IT_PROG` 직무를 가진 직원을 제외하되, 그 하위 직원은 유지하여 조회하시오.

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS name,
       job_id
FROM   employees
WHERE  job_id != 'IT_PROG'
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

---

**[14번]** `CONNECT BY` 절 조건을 사용하여 `IT_PROG` 직무 가지(해당 직원 + 모든 하위 직원)를 완전히 제거하여 조회하시오.

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS name,
       job_id
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND job_id != 'IT_PROG'
ORDER SIBLINGS BY last_name;
```

---

**[15번]** `CONNECT BY` 절에서 `LEVEL <= 2` 조건을 사용하여 King의 직속 부하까지만(2레벨) 탐색을 중단하고 조회하시오.

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS name,
       employee_id,
       manager_id
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND LEVEL <= 2
ORDER SIBLINGS BY last_name;
```

---

## Group 5: ORDER SIBLINGS BY & 집계

**[16번]** 전체 조직도를 급여 내림차순으로 형제 정렬하여 조회하시오. (계층 구조 유지)

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS name,
       salary
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY salary DESC;
```

---

**[17번]** King 기준 조직도를 `last_name` 알파벳 순으로 형제 정렬하여 출력하시오.

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*3) || last_name AS name,
       job_id,
       salary
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name ASC;
```

---

**[18번]** `CONNECT_BY_ROOT`를 사용하여 루트 관리자별 총 부하 직원 수와 평균 급여를 조회하시오.

```sql
SELECT CONNECT_BY_ROOT last_name    AS top_mgr,
       COUNT(*) - 1                  AS total_sub,
       ROUND(AVG(salary), 0)         AS avg_sal,
       MAX(salary)                   AS max_sal
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
GROUP BY CONNECT_BY_ROOT last_name, CONNECT_BY_ROOT employee_id
ORDER BY total_sub DESC;
```

---

**[19번]** 계층 쿼리를 인라인 뷰로 감싸서 부서별 평균 계층 레벨을 조회하시오.

```sql
SELECT department_id,
       ROUND(AVG(hier_level), 2) AS avg_level,
       MAX(hier_level)            AS max_level,
       COUNT(*)                   AS emp_cnt
FROM  (SELECT department_id,
              LEVEL AS hier_level
       FROM   employees
       START WITH manager_id IS NULL
       CONNECT BY PRIOR employee_id = manager_id)
WHERE  department_id IS NOT NULL
GROUP BY department_id
ORDER BY avg_level DESC;
```

---

## Group 6: 종합 실습

**[20번]** 각 직원에 대해 다음 정보를 한 번의 계층 쿼리로 출력하시오.
- `employee_id`, `last_name`, `LEVEL`, 들여쓰기 이름, `CONNECT_BY_ISLEAF`, `CONNECT_BY_ROOT last_name`, 루트~현재 경로

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name    AS indented_name,
       employee_id,
       CONNECT_BY_ISLEAF                      AS is_leaf,
       CONNECT_BY_ROOT last_name              AS root_mgr,
       SYS_CONNECT_BY_PATH(last_name, ' / ')  AS full_path
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

---

**[21번]** Greenberg(108) 서브트리 내 직원만 조회하고 잎 노드 여부와 경로를 함께 출력하시오.

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name    AS name,
       CONNECT_BY_ISLEAF                      AS is_leaf,
       SYS_CONNECT_BY_PATH(last_name, ' → ')  AS path
FROM   employees
START WITH employee_id = 108
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

---

**[22번]** 계층 쿼리와 WITH 절을 결합하여 각 LEVEL별 직원 수와 평균 급여를 조회하시오.

```sql
WITH org AS (
    SELECT LEVEL AS lvl,
           employee_id,
           salary
    FROM   employees
    START WITH manager_id IS NULL
    CONNECT BY PRIOR employee_id = manager_id
)
SELECT lvl,
       COUNT(*)            AS emp_count,
       ROUND(AVG(salary), 0) AS avg_sal,
       MIN(salary)          AS min_sal,
       MAX(salary)          AS max_sal
FROM   org
GROUP BY lvl
ORDER BY lvl;
```

---

**[23번]** 각 관리자(비잎 노드)와 그의 직속 부하 수, 직속 부하 평균 급여를 조회하시오.

```sql
SELECT m.employee_id   AS mgr_id,
       m.last_name     AS mgr_name,
       COUNT(e.employee_id)        AS direct_reports,
       ROUND(AVG(e.salary), 0)     AS avg_sub_salary
FROM   employees m
JOIN   employees e ON e.manager_id = m.employee_id
GROUP BY m.employee_id, m.last_name
ORDER BY direct_reports DESC, mgr_id;
```

---

**[24번]** 계층 쿼리로 전체 조직도를 조회하되, 급여가 10000 이상인 직원은 `*` 표시를 붙여 구분하시오.

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2)
       || last_name
       || CASE WHEN salary >= 10000 THEN ' *' ELSE '' END AS name,
       salary,
       CONNECT_BY_ISLEAF AS is_leaf
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

---

**[25번]** 특정 직원(Austin, employee_id=105)의 동료(같은 관리자를 가진 형제 노드)를 조회하시오.

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  manager_id = (SELECT manager_id
                     FROM   employees
                     WHERE  employee_id = 105)
AND    employee_id != 105
ORDER BY last_name;
```

---

**[26번]** 계층 쿼리를 사용하여 각 직원의 계층 경로와 King으로부터의 거리(LEVEL-1)를 함께 조회하시오. LEVEL이 3인 직원만 필터링하시오.

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       LEVEL - 1                             AS distance_from_root,
       SYS_CONNECT_BY_PATH(last_name, ' / ') AS path
FROM   employees
WHERE  LEVEL = 3
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```
