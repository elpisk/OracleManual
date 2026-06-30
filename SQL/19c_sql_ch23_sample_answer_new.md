# Oracle Database 19c: SQL Workshop
## Chapter 23 — 계층 쿼리 | SQL 실습 모범답안

---

## Group 1: CONNECT BY 기본

**[1번]** 전체 조직도 — LEVEL + employee_id 정렬

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

**결과 예시:**
```
LEVEL  EMPLOYEE_ID  LAST_NAME   MANAGER_ID
-----  -----------  ----------  ----------
    1          100  King
    2          101  Kochhar            100
    2          102  De Haan            100
    2          114  Raphaely           100
    3          103  Hunold             102
    3          108  Greenberg          101
    4          105  Austin             103
    4          109  Faviet             108
```

키포인트: `manager_id IS NULL`은 King(100)을 유일한 루트로 설정. 총 107행 반환.

---

**[2번]** LPAD 들여쓰기 조직도 + ORDER SIBLINGS BY

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

**결과 예시:**
```
LEVEL  ORG_CHART             EMPLOYEE_ID   SALARY
-----  --------------------  -----------  -------
    1  King                          100    24000
    2    De Haan                     102    17000
    3      Hunold                    103     9000
    4        Austin                  105     4800
    4        Ernst                   104     6000
    4        Lorentz                 107     4200
    4        Pataballa               106     4800
    2    Kochhar                     101    17000
```

키포인트: `ORDER SIBLINGS BY last_name`은 같은 부모 아래 형제들을 알파벳 순 정렬. 계층 구조(부모-자식 순서)는 유지됨.

---

**[3번]** De Haan(102) 서브트리 Top-Down

```sql
SELECT LEVEL,
       employee_id,
       last_name
FROM   employees
START WITH employee_id = 102
CONNECT BY PRIOR employee_id = manager_id
ORDER BY LEVEL, employee_id;
```

**결과 예시:**
```
LEVEL  EMPLOYEE_ID  LAST_NAME
-----  -----------  ----------
    1          102  De Haan
    2          103  Hunold
    3          104  Ernst
    3          105  Austin
    3          106  Pataballa
    3          107  Lorentz
```

키포인트: `START WITH employee_id = 102`로 De Haan을 루트로 지정. LEVEL은 De Haan 기준으로 재계산됨.

---

**[4번]** King 직속 부하(LEVEL=2)만 조회

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  LEVEL = 2
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER BY salary DESC;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   JOB_ID   SALARY
-----------  ----------  -------  ------
101          Kochhar     AD_VP     17000
102          De Haan     AD_VP     17000
114          Raphaely    PU_MAN    11000
```

키포인트: `WHERE LEVEL = 2`는 계층 탐색 완료 후 필터링. King의 직속 부하 3명이 조회됨.

---

**[5번]** LEVEL 3 이하만 조회 (WHERE 사용)

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

키포인트: `WHERE LEVEL <= 3`는 탐색은 전체 수행 후 결과만 필터링. LEVEL 4 이상 행(Faviet, Austin 등)은 제외됨.

---

## Group 2: Bottom-Up & SYS_CONNECT_BY_PATH

**[6번]** Hunold(103) → King 관리자 체인 (Bottom-Up)

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

**결과 예시:**
```
LEVEL  EMPLOYEE_ID  LAST_NAME   MANAGER_ID
-----  -----------  ----------  ----------
    1          103  Hunold             102
    2          102  De Haan            100
    3          100  King
```

키포인트: `PRIOR manager_id = employee_id` — PRIOR가 manager_id(부모) 쪽 → 자식→부모 방향 탐색.

---

**[7번]** Faviet(109) → King 경로 (SYS_CONNECT_BY_PATH)

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

**결과 예시:**
```
LEVEL  EMPLOYEE_ID  LAST_NAME   FULL_PATH
-----  -----------  ----------  -----------------------------------
    1          109  Faviet       → Faviet
    2          108  Greenberg    → Faviet → Greenberg
    3          101  Kochhar      → Faviet → Greenberg → Kochhar
    4          100  King         → Faviet → Greenberg → Kochhar → King
```

키포인트: Bottom-Up에서도 `SYS_CONNECT_BY_PATH`는 탐색 시작(Faviet)부터 현재까지 경로를 누적.

---

**[8번]** 전체 조직도 경로 조회

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

**결과 예시:**
```
EMP  LAST_NAME   LV  PATH
---  ----------  --  ------------------------------------------
100  King         1  / King
102  De Haan      2  / King / De Haan
103  Hunold       3  / King / De Haan / Hunold
105  Austin       4  / King / De Haan / Hunold / Austin
101  Kochhar      2  / King / Kochhar
108  Greenberg    3  / King / Kochhar / Greenberg
109  Faviet       4  / King / Kochhar / Greenberg / Faviet
```

키포인트: 경로 문자열은 반드시 구분자(' / ')로 시작함.

---

**[9번]** 급여 상위 3명의 루트까지 체인

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

키포인트: 급여 상위 3명(King 24000, Kochhar 17000, De Haan 17000)의 Bottom-Up 체인을 한 번에 조회. 복수 START WITH 조건은 `IN (서브쿼리)`로 처리.

---

## Group 3: CONNECT_BY_ISLEAF & CONNECT_BY_ROOT

**[10번]** 잎 노드(최하위) 직원 — 급여 내림차순

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  CONNECT_BY_ISLEAF = 1
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER BY salary DESC;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   JOB_ID      SALARY
-----------  ----------  ----------  ------
145          Russell     SA_MAN       14000
146          Partners    SA_MAN       13500
168          Ozer        SA_REP       11500
169          Abel        SA_REP       11000
...
```

키포인트: 잎 노드 = 부하 직원이 없는 직원. HR 스키마에서 대부분의 SA_REP, IT_PROG 직원들이 잎 노드.

---

**[11번]** 잎 여부 + 루트 관리자 정보

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       CONNECT_BY_ISLEAF           AS is_leaf,
       CONNECT_BY_ROOT last_name   AS root_mgr,
       CONNECT_BY_ROOT employee_id AS root_id
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

키포인트: `CONNECT_BY_ROOT`는 모든 행에서 'King', 100을 반환 (유일한 루트). `CONNECT_BY_ISLEAF`는 잎 노드만 1, 나머지는 0.

---

**[12번]** 잎 노드 vs 전체 직원 급여 평균 비교

```sql
WITH leaf_emps AS (
    SELECT salary
    FROM   employees
    WHERE  CONNECT_BY_ISLEAF = 1
    START WITH manager_id IS NULL
    CONNECT BY PRIOR employee_id = manager_id
)
SELECT ROUND(AVG(l.salary), 0)                       AS leaf_avg_sal,
       ROUND((SELECT AVG(salary) FROM employees), 0) AS total_avg_sal
FROM   leaf_emps l;
```

**결과 예시:**
```
LEAF_AVG_SAL  TOTAL_AVG_SAL
------------  -------------
        6147           6462
```

키포인트: 잎 노드(말단 직원) 평균이 전체 평균보다 낮음 — 관리자급 급여가 평균을 높임.

---

## Group 4: 가지치기 (WHERE vs CONNECT BY)

**[13번]** WHERE로 IT_PROG 제외 (하위 직원 유지)

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

키포인트: Hunold(IT_PROG) 행만 제거. Hunold의 자식(Austin, Ernst 등 IT_PROG)은 WHERE 조건에 의해 제거되지만 계층 탐색은 계속됨 — 단, IT_PROG 직원이 많아 대부분 제거됨.

---

**[14번]** CONNECT BY로 IT_PROG 가지 전체 제거 (Pruning)

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

키포인트: `CONNECT BY ... AND job_id != 'IT_PROG'` → Hunold(IT_PROG) 가지 탐색 자체 중단. Austin, Ernst, Lorentz, Pataballa(모두 IT_PROG) 포함 가지 전체 제거.

---

**[15번]** LEVEL <= 2로 탐색 깊이 제한

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

**결과 예시:**
```
LEVEL  NAME           EMPLOYEE_ID  MANAGER_ID
-----  -------------  -----------  ----------
    1  King                   100
    2    De Haan              102         100
    2    Kochhar              101         100
    2    Raphaely             114         100
```

키포인트: `CONNECT BY ... AND LEVEL <= 2` → LEVEL 3 이상 탐색 자체 중단(Pruning). `WHERE LEVEL <= 2`는 탐색은 계속하고 결과만 필터링하여 성능 차이 발생.

---

## Group 5: ORDER SIBLINGS BY & 집계

**[16번]** 형제 정렬 — 급여 내림차순

```sql
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS name,
       salary
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY salary DESC;
```

키포인트: 같은 부모(manager_id) 아래 형제들끼리만 급여 내림차순 정렬. 계층(부모→자식) 순서는 유지됨.

---

**[17번]** 형제 정렬 — last_name 알파벳 오름차순

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

키포인트: 전사 표준 조직도 출력에 활용. 같은 레벨에서 알파벳 정렬로 보기 좋게 표시.

---

**[18번]** 루트 관리자별 부하 직원 집계

```sql
SELECT CONNECT_BY_ROOT last_name   AS top_mgr,
       COUNT(*) - 1                AS total_sub,
       ROUND(AVG(salary), 0)       AS avg_sal,
       MAX(salary)                 AS max_sal
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
GROUP BY CONNECT_BY_ROOT last_name, CONNECT_BY_ROOT employee_id
ORDER BY total_sub DESC;
```

**결과 예시:**
```
TOP_MGR  TOTAL_SUB  AVG_SAL  MAX_SAL
-------  ---------  -------  -------
King           106     6461    24000
```

키포인트: `COUNT(*) - 1`에서 -1은 루트(King) 자신 제외. HR 스키마에서 King이 유일한 루트이므로 1행 반환.

---

**[19번]** 부서별 평균 계층 레벨 (인라인 뷰 활용)

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

**결과 예시:**
```
DEPARTMENT_ID  AVG_LEVEL  MAX_LEVEL  EMP_CNT
-------------  ---------  ---------  -------
           90       1.00          1        3
           20       3.00          3        2
          110       3.00          3        2
           60       4.00          4        5
```

키포인트: 계층 쿼리를 인라인 뷰로 감싸면 LEVEL을 일반 컬럼으로 사용 가능 → GROUP BY, AVG 적용 가능.

---

## Group 6: 종합 실습

**[20번]** 전체 정보 한 번에 조회

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

키포인트: 단일 쿼리에서 계층 의사컬럼(LEVEL, CONNECT_BY_ISLEAF, CONNECT_BY_ROOT, SYS_CONNECT_BY_PATH)을 모두 활용.

---

**[21번]** Greenberg(108) 서브트리 + 잎 여부 + 경로

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

**결과 예시:**
```
LEVEL  NAME          IS_LEAF  PATH
-----  ------------  -------  -------------------------
    1  Greenberg           0  → Greenberg
    2    Chen              1  → Greenberg → Chen
    2    Fandel            1  → Greenberg → Fandel
    2    Faviet            1  → Greenberg → Faviet
    2    Sciarra           1  → Greenberg → Sciarra
    2    Urman             1  → Greenberg → Urman
```

키포인트: Greenberg(108) 아래 직속 부하 5명 모두 잎 노드(is_leaf=1). 경로는 Greenberg부터 시작.

---

**[22번]** LEVEL별 직원 수·급여 통계 (WITH 절 활용)

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
       COUNT(*)              AS emp_count,
       ROUND(AVG(salary), 0) AS avg_sal,
       MIN(salary)            AS min_sal,
       MAX(salary)            AS max_sal
FROM   org
GROUP BY lvl
ORDER BY lvl;
```

**결과 예시:**
```
LVL  EMP_COUNT  AVG_SAL  MIN_SAL  MAX_SAL
---  ---------  -------  -------  -------
  1          1    24000    24000    24000
  2          3    15000    11000    17000
  3         33     7849     2100    12008
  4         70     5749     2100    14000
```

키포인트: CTE 내에서 LEVEL을 `lvl` 컬럼으로 저장 후 외부에서 GROUP BY 적용.

---

**[23번]** 관리자별 직속 부하 수·평균 급여

```sql
SELECT m.employee_id           AS mgr_id,
       m.last_name             AS mgr_name,
       COUNT(e.employee_id)    AS direct_reports,
       ROUND(AVG(e.salary), 0) AS avg_sub_salary
FROM   employees m
JOIN   employees e ON e.manager_id = m.employee_id
GROUP BY m.employee_id, m.last_name
ORDER BY direct_reports DESC, mgr_id;
```

**결과 예시:**
```
MGR_ID  MGR_NAME    DIRECT_REPORTS  AVG_SUB_SALARY
------  ----------  --------------  --------------
100     King                     3           15000
101     Kochhar                  5            8773
145     Russell                  6            8708
...
```

키포인트: 자기 참조 JOIN(Self Join)으로 직속 부하만 집계. 계층 쿼리 없이도 직속 부하 수는 Self Join으로 구현 가능.

---

**[24번]** 급여 10000 이상 직원에 `*` 표시

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

**결과 예시:**
```
LEVEL  NAME                 SALARY  IS_LEAF
-----  -------------------  ------  -------
    1  King *                24000        0
    2    De Haan *           17000        0
    3      Hunold             9000        0
    4        Austin           4800        1
    2    Kochhar *           17000        0
```

키포인트: `CASE WHEN salary >= 10000 THEN ' *'`을 last_name에 연결하여 동적 레이블 생성.

---

**[25번]** 특정 직원(Austin=105)의 형제 노드 조회

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  manager_id = (SELECT manager_id
                     FROM   employees
                     WHERE  employee_id = 105)
AND    employee_id != 105
ORDER BY last_name;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   JOB_ID    SALARY
-----------  ----------  --------  ------
104          Ernst       IT_PROG     6000
107          Lorentz     IT_PROG     4200
106          Pataballa   IT_PROG     4800
```

키포인트: Austin의 manager_id = Hunold(103). 동일 manager_id를 가진 직원이 Austin의 형제 노드.

---

**[26번]** LEVEL=3 직원 + 루트까지 거리·경로

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       LEVEL - 1                              AS distance_from_root,
       SYS_CONNECT_BY_PATH(last_name, ' / ') AS path
FROM   employees
WHERE  LEVEL = 3
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

**결과 예시:**
```
EMP  LAST_NAME   LV  DISTANCE  PATH
---  ----------  --  --------  ----------------------------
103  Hunold       3         2  / King / De Haan / Hunold
108  Greenberg    3         2  / King / Kochhar / Greenberg
115  Khoo         3         2  / King / Raphaely / Khoo
...
```

키포인트: `distance_from_root = LEVEL - 1`. LEVEL 3 직원은 루트(King)로부터 2단계 거리에 위치.
