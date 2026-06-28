# Oracle Database 19c: SQL Workshop
## Appendix F — 계층적 데이터 조회 | SQL 실습 문제

---

> **참고:** 이 실습은 HR 스키마가 설치된 Oracle 19c 환경에서 수행하세요.

---

## Group 1: 기본 계층 쿼리

**[1번]** EMPLOYEES 테이블에서 King(manager_id IS NULL)을 루트로 하여 모든 직원을 하향식으로 조회하시오.

```sql
SELECT LEVEL, employee_id, last_name, manager_id
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

**[2번]** Kochhar(last_name='Kochhar')를 루트로 하여 그 부서장 아래 모든 직원을 조회하시오.

```sql
SELECT LEVEL, employee_id, last_name, job_id
FROM   employees
START  WITH last_name = 'Kochhar'
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

**[3번]** Gietz(employee_id=206)에서 최상위 관리자(King)까지 상향식으로 조회하시오.

```sql
SELECT employee_id, last_name, manager_id
FROM   employees
START  WITH employee_id = 206
CONNECT BY PRIOR manager_id = employee_id;
```

---

**[4번]** 모든 직원의 LEVEL과 last_name, manager_id를 조회하시오. 동일 레벨 내에서는 last_name 알파벳 순으로 정렬하시오.

```sql
SELECT LEVEL,
       last_name,
       employee_id,
       manager_id
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

**[5번]** 다음 정보를 같이 출력하시오: LEVEL, employee_id, last_name, manager의 last_name.

```sql
SELECT LEVEL,
       e.employee_id,
       e.last_name,
       m.last_name AS manager_name
FROM   employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
START  WITH e.manager_id IS NULL
CONNECT BY PRIOR e.employee_id = e.manager_id
ORDER  SIBLINGS BY e.last_name;
```

---

## Group 2: LEVEL과 들여쓰기

**[6번]** LEVEL과 LPAD를 사용하여 계층 조직도를 시각화하시오.

```sql
COLUMN org_chart FORMAT A35
SELECT LPAD(last_name,
            LENGTH(last_name) + (LEVEL * 2) - 2,
            ' ')            AS org_chart,
       LEVEL,
       employee_id,
       salary
FROM   employees
START  WITH first_name = 'Steven' AND last_name = 'King'
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

**[7번]** 밑줄('_')을 채우기 문자로 사용한 조직도를 출력하시오.

```sql
COLUMN org_chart FORMAT A35
SELECT LPAD(last_name,
            LENGTH(last_name) + (LEVEL * 2) - 2,
            '_')            AS org_chart,
       job_id
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

**[8번]** 레벨이 3 이하인 직원만 조회하시오 (전체 조직의 상위 3단계만).

```sql
SELECT LEVEL,
       LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, ' ') AS name,
       employee_id,
       salary
FROM   employees
WHERE  LEVEL <= 3
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

**[9번]** 리프 노드(부하 직원이 없는 직원)만 조회하시오.

```sql
SELECT LEVEL, employee_id, last_name, salary
FROM   employees
WHERE  CONNECT_BY_ISLEAF = 1
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  BY last_name;
```

---

## Group 3: 가지 제거 (Pruning)

**[10번]** WHERE 절로 Higgins만 제거하고 나머지는 그대로 조회하시오.

```sql
SELECT LEVEL,
       LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, ' ') AS name
FROM   employees
WHERE  last_name != 'Higgins'
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
-- 주의: Gietz(Higgins의 부하)는 그대로 남음
```

---

**[11번]** CONNECT BY 조건으로 Higgins와 그 하위 가지를 완전히 제거하시오.

```sql
SELECT LEVEL,
       LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, ' ') AS name
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND last_name != 'Higgins'
ORDER  SIBLINGS BY last_name;
-- 주의: Higgins와 Gietz 모두 제거됨
```

---

**[12번]** IT 부서(department_id=60)에 속한 직원들의 하위 트리를 완전히 제거하시오.

```sql
SELECT LEVEL, employee_id, last_name, department_id
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND department_id != 60
ORDER  SIBLINGS BY last_name;
```

---

## Group 4: SYS_CONNECT_BY_PATH & CONNECT_BY_ROOT

**[13번]** 각 직원의 루트에서 현재까지 경로(슬래시 구분)를 출력하시오.

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       SYS_CONNECT_BY_PATH(last_name, '/') AS path
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

**[14번]** 각 직원의 최상위 관리자(루트) 이름을 함께 출력하시오.

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       CONNECT_BY_ROOT last_name AS root_mgr
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

**[15번]** 하이픈('-')으로 구분한 직책(job_id) 경로를 출력하시오.

```sql
SELECT employee_id,
       last_name,
       SYS_CONNECT_BY_PATH(job_id, '-') AS job_path
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

## Group 5: 종합 실습

**[16번]** 각 직원의 계층 정보를 종합하여 보고서를 작성하시오 (계층도, 경로, 루트, 리프 여부 포함).

```sql
SELECT LEVEL                                               AS lvl,
       LPAD(e.last_name,
            LENGTH(e.last_name)+(LEVEL*2)-2, ' ')         AS hierarchy,
       e.employee_id,
       e.salary,
       CONNECT_BY_ROOT e.last_name                        AS root_mgr,
       SYS_CONNECT_BY_PATH(e.last_name, ' > ')            AS full_path,
       CONNECT_BY_ISLEAF                                  AS is_leaf
FROM   employees e
START  WITH e.manager_id IS NULL
CONNECT BY PRIOR e.employee_id = e.manager_id
ORDER  SIBLINGS BY e.last_name;
```

---

**[17번]** 특정 직원(Zlotkey, employee_id=149)과 그의 모든 부하 직원의 급여 합계를 조회하시오.

```sql
SELECT SUM(salary) AS team_total,
       COUNT(*)    AS team_size,
       ROUND(AVG(salary)) AS team_avg
FROM (
    SELECT salary
    FROM   employees
    START  WITH employee_id = 149
    CONNECT BY PRIOR employee_id = manager_id
);
```

---

**[18번]** 각 관리자 레벨별 평균 급여를 조회하시오.

```sql
SELECT LEVEL,
       COUNT(*)          AS headcount,
       ROUND(AVG(salary)) AS avg_salary,
       SUM(salary)       AS total_salary
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
GROUP  BY LEVEL
ORDER  BY LEVEL;
```

---

**[19번]** LEVEL이 가장 깊은(리프) 직원들과 그들의 전체 경로를 출력하시오.

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       SYS_CONNECT_BY_PATH(last_name, ' → ') AS path
FROM   employees
WHERE  CONNECT_BY_ISLEAF = 1
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  BY LEVEL DESC, last_name;
```

---

**[20번]** 전체 조직의 최대 깊이와, 각 최상위 부서장별 부하 직원 수를 조회하시오.

```sql
-- 전체 최대 깊이
SELECT MAX(LEVEL) AS max_depth
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;

-- 각 최상위 부서장의 팀 규모
SELECT CONNECT_BY_ROOT employee_id   AS root_emp_id,
       CONNECT_BY_ROOT last_name     AS root_name,
       COUNT(*) - 1                  AS subordinates
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
GROUP  BY CONNECT_BY_ROOT employee_id, CONNECT_BY_ROOT last_name
ORDER  BY subordinates DESC;
```

---

**[21번]** 특정 직원(Kochhar, employee_id=101)의 조직 내 위치를 최상위부터 그 직원까지의 경로로 출력하시오.

```sql
-- 하향식으로 Kochhar까지의 경로 (인라인 뷰 활용)
SELECT level_path
FROM (
    SELECT SYS_CONNECT_BY_PATH(last_name, ' > ') AS level_path,
           employee_id
    FROM   employees
    START  WITH manager_id IS NULL
    CONNECT BY PRIOR employee_id = manager_id
)
WHERE employee_id = 101;
```

---

**[22번]** 부서별 계층 구조를 출력하시오. department_id가 같은 직원들을 묶어 계층 조직도와 함께 표시하시오.

```sql
SELECT LEVEL,
       e.department_id,
       d.department_name,
       LPAD(e.last_name, LENGTH(e.last_name)+(LEVEL*2)-2, ' ') AS hierarchy,
       e.salary
FROM   employees e
JOIN   departments d ON e.department_id = d.department_id
WHERE  e.department_id IN (20, 50, 80, 90)
START  WITH e.manager_id IS NULL
CONNECT BY PRIOR e.employee_id = e.manager_id
ORDER  SIBLINGS BY e.last_name;
```

---

**[23번]** 급여가 평균보다 높은 직원만 필터링한 계층 구조를 출력하시오.

```sql
SELECT LEVEL,
       LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, ' ') AS hierarchy,
       salary,
       employee_id
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees)
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
-- WHERE로 필터링해도 계층 구조는 유지되나 중간 노드가 빠질 수 있음
```

---

**[24번]** 모든 직원에 대해 '직속 부하 수'와 '전체 부하 수(재귀)'를 계산하시오.

```sql
-- 직속 부하 수
SELECT m.employee_id,
       m.last_name,
       COUNT(e.employee_id) AS direct_reports
FROM   employees m
LEFT JOIN employees e ON e.manager_id = m.employee_id
GROUP  BY m.employee_id, m.last_name
ORDER  BY direct_reports DESC;

-- 전체 부하 수 (계층 재귀)
SELECT root_id, root_name,
       COUNT(*) - 1 AS total_subordinates
FROM (
    SELECT CONNECT_BY_ROOT employee_id AS root_id,
           CONNECT_BY_ROOT last_name   AS root_name,
           employee_id
    FROM   employees
    START  WITH manager_id IS NULL
    CONNECT BY PRIOR employee_id = manager_id
)
GROUP  BY root_id, root_name
ORDER  BY total_subordinates DESC;
```

---

**[25번]** 조직 계층을 JSON 형태의 경로로 시각화하는 보고서를 작성하시오.

```sql
SELECT LEVEL                                          AS depth,
       employee_id,
       last_name,
       salary,
       '{"path":"' ||
           REPLACE(SYS_CONNECT_BY_PATH(last_name, '/'), '/', ' > ')
           || '"}'                                    AS path_json,
       CONNECT_BY_ISLEAF                             AS leaf
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

---

**[26번]** 가지치기(Pruning) 전/후 비교: Kochhar 팀을 WHERE로 제거한 경우와 CONNECT BY로 제거한 경우를 비교하시오.

```sql
-- WHERE로 제거 (Kochhar만 제거, 부하 직원은 남음)
SELECT 'WHERE 제거' AS method,
       LEVEL, last_name
FROM   employees
WHERE  last_name != 'Kochhar'
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;

-- CONNECT BY로 제거 (Kochhar + 모든 부하 제거)
SELECT 'CONNECT BY 제거' AS method,
       LEVEL, last_name
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND last_name != 'Kochhar'
ORDER  SIBLINGS BY last_name;
-- 두 결과를 비교하여 차이 확인
```
