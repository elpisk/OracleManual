# Oracle Database 19c: SQL Workshop
## Appendix F — 계층적 데이터 조회 | SQL 실습 모범답안

---

## Group 1: 기본 계층 쿼리

**[1번]** 전체 직원 하향식 계층 조회

```sql
SELECT LEVEL, employee_id, last_name, manager_id
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

**결과 구조 (일부):**
```
LEVEL  EMP_ID  LAST_NAME   MGR_ID
1      100     King        NULL      ← 루트
2      102     De Haan     100
3      103     Hunold      102
4      104     Ernst       103
4      107     Lorentz     103
2      101     Kochhar     100
3      205     Higgins     101
4      206     Gietz       205
...
```

---

**[2번]** Kochhar를 루트로 하는 서브트리

```sql
SELECT LEVEL, employee_id, last_name, job_id
FROM   employees
START  WITH last_name = 'Kochhar'
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

Kochhar(LEVEL=1) 아래 Whalen, Higgins, Gietz가 포함된다.

---

**[3번]** Gietz에서 King까지 상향식 조회

```sql
SELECT employee_id, last_name, manager_id
FROM   employees
START  WITH employee_id = 206
CONNECT BY PRIOR manager_id = employee_id;
```

**결과:**
```
EMP_ID  LAST_NAME  MGR_ID
206     Gietz      205
205     Higgins    101
101     Kochhar    100
100     King       NULL
```

`PRIOR manager_id = employee_id`: 현재 행의 부모(manager_id)가 다음 행의 employee_id를 찾는다 → 상향식 탐색.

---

**[4번]** LEVEL + ORDER SIBLINGS BY last_name

```sql
SELECT LEVEL, last_name, employee_id, manager_id
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

**핵심:** `ORDER SIBLINGS BY`는 계층 구조를 유지하면서 동일 부모 아래 자식들만 정렬한다.

---

**[5번]** 매니저 이름 함께 출력 (Self JOIN + 계층)

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

`LEFT JOIN`: 루트(King)는 manager_id가 NULL이므로 LEFT JOIN으로 처리.

---

## Group 2: LEVEL과 들여쓰기

**[6번]** 공백 들여쓰기 조직도

```sql
COLUMN org_chart FORMAT A35
SELECT LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, ' ') AS org_chart,
       LEVEL, employee_id, salary
FROM   employees
START  WITH first_name='Steven' AND last_name='King'
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

**LPAD 공식:**
```
총 길이 = LENGTH(last_name) + (LEVEL * 2) - 2
LEVEL=1: +0글자 (루트는 들여쓰기 없음)
LEVEL=2: +2글자
LEVEL=3: +4글자
```

---

**[7번]** 밑줄 채우기 조직도

```sql
SELECT LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, '_') AS org_chart,
       job_id
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

**출력 예:**
```
ORG_CHART            JOB_ID
King                 AD_PRES
__De Haan            AD_VP
____Hunold           IT_PROG
______Ernst          IT_PROG
______Lorentz        IT_PROG
__Kochhar            AD_VP
____Higgins          AC_MGR
______Gietz          AC_ACCOUNT
```

---

**[8번]** LEVEL <= 3 (상위 3단계)

```sql
SELECT LEVEL,
       LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, ' ') AS name,
       employee_id, salary
FROM   employees
WHERE  LEVEL <= 3
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

`WHERE LEVEL <= 3`: 계층 탐색 후 결과에서 3단계 초과 행을 제거.

---

**[9번]** 리프 노드 조회

```sql
SELECT LEVEL, employee_id, last_name, salary
FROM   employees
WHERE  CONNECT_BY_ISLEAF = 1
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  BY last_name;
```

`CONNECT_BY_ISLEAF = 1`: 해당 노드가 트리에서 더 이상 자식이 없는 말단 노드.

---

## Group 3: 가지 제거 (Pruning)

**[10번]** WHERE로 Higgins만 제거

```sql
SELECT LEVEL,
       LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, ' ') AS name
FROM   employees
WHERE  last_name != 'Higgins'
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

**결과:** Higgins는 없지만 Gietz(LEVEL=4, Higgins의 부하)는 여전히 표시됨.  
→ 부모(Higgins)가 없는 Gietz가 마치 고아 노드처럼 표시된다.

---

**[11번]** CONNECT BY로 Higgins 가지 전체 제거

```sql
SELECT LEVEL,
       LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, ' ') AS name
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND last_name != 'Higgins'
ORDER  SIBLINGS BY last_name;
```

**결과:** Higgins와 Gietz 모두 제거됨.  
→ Higgins 노드에서 탐색이 중단되므로 그 이하로 연결되지 않는다.

---

**[12번]** IT 부서(60) 하위 가지 제거

```sql
SELECT LEVEL, employee_id, last_name, department_id
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND department_id != 60
ORDER  SIBLINGS BY last_name;
```

department_id=60(IT: Hunold, Ernst, Lorentz 등)에 속한 직원 전체가 제거된다.

---

## Group 4: SYS_CONNECT_BY_PATH & CONNECT_BY_ROOT

**[13번]** 루트에서 현재까지 경로 출력

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

**결과 예:**
```
EMP_ID  LAST_NAME  LEVEL  PATH
100     King       1      /King
102     De Haan    2      /King/De Haan
103     Hunold     3      /King/De Haan/Hunold
206     Gietz      4      /King/Kochhar/Higgins/Gietz
```

---

**[14번]** 루트 관리자 이름 함께 출력

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

`START WITH manager_id IS NULL`이면 King이 단일 루트이므로 모든 행에서 `root_mgr = 'King'`.

---

**[15번]** 직책(job_id) 경로 출력

```sql
SELECT employee_id,
       last_name,
       SYS_CONNECT_BY_PATH(job_id, '-') AS job_path
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

**결과 예:**
```
/AD_PRES
/AD_PRES-AD_VP
/AD_PRES-AD_VP-IT_PROG
/AD_PRES-AD_VP-IT_PROG-IT_PROG  ← Ernst
```

---

## Group 5: 종합 실습

**[16번]** 계층 종합 보고서

```sql
SELECT LEVEL                                               AS lvl,
       LPAD(e.last_name, LENGTH(e.last_name)+(LEVEL*2)-2, ' ') AS hierarchy,
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

**[17번]** Zlotkey 팀 급여 합계

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

**포인트:** 인라인 뷰로 계층 탐색 결과를 먼저 구하고, 외부 쿼리에서 집계한다.

---

**[18번]** 레벨별 평균 급여

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

**예상 결과:**
```
LEVEL  HEADCOUNT  AVG_SALARY  TOTAL_SALARY
1      1          24000       24000    ← King
2      ~6         ~15000      ...      ← VP 급
3      ~30        ~8000       ...
4      ~70        ~4500       ...
```

---

**[19번]** 리프 노드(말단 직원)와 경로

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

**[20번]** 최대 깊이 및 부서장별 부하 수

```sql
-- 전체 최대 깊이
SELECT MAX(LEVEL) AS max_depth
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;

-- 결과: 4 (King → VP → 팀장 → 팀원)

-- 각 최상위 부서장별 팀 규모
SELECT CONNECT_BY_ROOT employee_id   AS root_emp_id,
       CONNECT_BY_ROOT last_name     AS root_name,
       COUNT(*) - 1                  AS subordinates
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
GROUP  BY CONNECT_BY_ROOT employee_id, CONNECT_BY_ROOT last_name
ORDER  BY subordinates DESC;
```

`COUNT(*) - 1`: 루트 자신을 제외한 부하 직원 수.

---

**[21번]** 특정 직원 경로 조회 (인라인 뷰)

```sql
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

**결과:** ` > King > Kochhar`

---

**[22번]** 특정 부서 계층 구조

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

**[23번]** 평균 급여 초과 직원 필터링

```sql
SELECT LEVEL,
       LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, ' ') AS hierarchy,
       salary, employee_id
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees)
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

**주의:** WHERE로 필터링하므로 중간 노드가 빠져 계층이 불연속적으로 보일 수 있다.

---

**[24번]** 직속/전체 부하 수 분석

```sql
-- 직속 부하 수
SELECT m.employee_id, m.last_name,
       COUNT(e.employee_id) AS direct_reports
FROM   employees m
LEFT JOIN employees e ON e.manager_id = m.employee_id
GROUP  BY m.employee_id, m.last_name
ORDER  BY direct_reports DESC;

-- 전체 부하 수
SELECT root_id, root_name, COUNT(*) - 1 AS total_subordinates
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

**[25번]** JSON 스타일 경로 보고서

```sql
SELECT LEVEL                                          AS depth,
       employee_id, last_name, salary,
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

**[26번]** WHERE vs CONNECT BY 가지치기 비교

```sql
-- WHERE로 제거 (Kochhar만 제거, 부하 직원은 남음)
SELECT 'WHERE 제거' AS method, LEVEL, last_name
FROM   employees
WHERE  last_name != 'Kochhar'
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;

-- CONNECT BY로 제거 (Kochhar + 모든 부하 제거)
SELECT 'CONNECT BY 제거' AS method, LEVEL, last_name
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND last_name != 'Kochhar'
ORDER  SIBLINGS BY last_name;
```

**비교 포인트:**

| 방법 | Kochhar | Whalen, Higgins, Gietz |
|------|---------|----------------------|
| WHERE 절 | 제거됨 | **남아있음** |
| CONNECT BY 절 | 제거됨 | **모두 제거됨** |
