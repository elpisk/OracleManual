# Oracle Database 19c: SQL Workshop
## Chapter 23 — 계층 쿼리 (Hierarchical Queries)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- `START WITH`와 `CONNECT BY PRIOR`로 계층 쿼리를 작성한다
- `LEVEL` 의사컬럼으로 계층 깊이를 확인한다
- Top-Down(부모→자식)과 Bottom-Up(자식→부모) 방향 탐색을 구분한다
- `LPAD`와 `SYS_CONNECT_BY_PATH`로 트리 구조를 시각화한다
- `WHERE` 절과 `CONNECT BY` 절 필터링의 차이를 이해한다
- `CONNECT_BY_ROOT`, `CONNECT_BY_ISLEAF`로 루트·잎 노드를 식별한다
- `ORDER SIBLINGS BY`로 같은 계층(형제) 노드를 정렬한다
- `NOCYCLE`과 `CONNECT_BY_ISCYCLE`로 순환 참조를 처리한다

---

## 1. 계층 데이터와 계층 쿼리 개요

### 1-1. 계층 데이터란

한 테이블의 행들이 **부모-자식(parent-child) 관계**로 연결된 데이터 구조이다.

| 계층 구조 예시 | 설명 |
|----------------|------|
| 조직도 | 최고 경영자 → 부서장 → 팀장 → 직원 |
| 품목 구성(BOM) | 완제품 → 부품 → 세부 부품 |
| 폴더/파일 시스템 | 루트 폴더 → 하위 폴더 → 파일 |
| 지역 코드 | 국가 → 지역 → 도시 |

HR 스키마의 `EMPLOYEES` 테이블은 `EMPLOYEE_ID`(자식)와 `MANAGER_ID`(부모)로 조직 계층을 표현한다.

```
King (100) — 최상위 관리자 (MANAGER_ID = NULL)
 ├── Kochhar (101)
 │    ├── Greenberg (108)
 │    └── Zlotkey (149)
 └── De Haan (102)
      └── Hunold (103)
           ├── Austin (105)
           └── Pataballa (106)
```

### 1-2. 계층 쿼리 구문

```sql
SELECT [LEVEL,] 컬럼, ...
FROM   테이블
[WHERE 조건]                        -- 개별 행 필터 (계층 유지)
START WITH 루트_조건                -- 계층 탐색 시작 행
CONNECT BY [NOCYCLE] PRIOR 자식키 = 부모키  -- 부모→자식 (Top-Down)
         -- 또는
         PRIOR 부모키 = 자식키      -- 자식→부모 (Bottom-Up)
[ORDER SIBLINGS BY 정렬컬럼];      -- 형제 노드 정렬
```

---

## 2. LEVEL 의사컬럼

`LEVEL`은 계층 쿼리에서만 사용 가능한 **의사컬럼(Pseudocolumn)**으로, 현재 행의 계층 깊이를 나타낸다.

- 루트 노드: `LEVEL = 1`
- 루트의 직속 자식: `LEVEL = 2`
- 그 자식의 자식: `LEVEL = 3`

```sql
-- 전체 조직도 계층 조회 (Top-Down)
SELECT LEVEL,
       employee_id,
       last_name,
       manager_id
FROM   employees
START WITH manager_id IS NULL          -- King(100): 최상위
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
    3          108  Greenberg          101
    3          103  Hunold             102
```

---

## 3. Top-Down vs Bottom-Up 탐색

### 3-1. Top-Down (위→아래, 가장 일반적)

루트에서 출발하여 자식 방향으로 탐색한다.

```sql
-- King 밑의 모든 직원 (Top-Down)
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS org_chart,
       employee_id,
       manager_id
FROM   employees
START WITH employee_id = 100          -- King부터 시작
CONNECT BY PRIOR employee_id = manager_id;
```

**결과 예시 (LPAD로 들여쓰기):**
```
LEVEL  ORG_CHART           EMPLOYEE_ID  MANAGER_ID
-----  ------------------  -----------  ----------
    1  King                        100
    2    Kochhar                   101         100
    3      Greenberg               108         101
    4        Faviet                109         108
    2    De Haan                   102         100
    3      Hunold                  103         102
```

### 3-2. Bottom-Up (아래→위)

특정 자식에서 출발하여 루트 방향으로 탐색한다. `PRIOR`의 위치가 바뀐다.

```sql
-- Hunold(103)의 모든 상위 관리자 체인
SELECT LEVEL,
       employee_id,
       last_name,
       manager_id
FROM   employees
START WITH employee_id = 103          -- Hunold부터 시작
CONNECT BY PRIOR manager_id = employee_id;  -- 자식→부모 방향
```

**결과 예시:**
```
LEVEL  EMPLOYEE_ID  LAST_NAME  MANAGER_ID
-----  -----------  ---------  ----------
    1          103  Hunold            102
    2          102  De Haan           100
    3          100  King
```

---

## 4. 계층 시각화 — LPAD & SYS_CONNECT_BY_PATH

### 4-1. LPAD로 들여쓰기

```sql
SELECT LPAD(' ', (LEVEL-1)*3) || last_name AS org_chart,
       LEVEL,
       job_id,
       salary
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

`LPAD(' ', (LEVEL-1)*3)`: LEVEL 1 → 공백 0, LEVEL 2 → 공백 3, LEVEL 3 → 공백 6 ...

### 4-2. SYS_CONNECT_BY_PATH

루트부터 현재 노드까지의 **전체 경로**를 문자열로 반환한다.

```sql
-- 구문: SYS_CONNECT_BY_PATH(컬럼, 구분자)
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
EMPLOYEE_ID  LAST_NAME   LEVEL  PATH
-----------  ----------  -----  -------------------------------------
100          King            1  / King
101          Kochhar         2  / King / Kochhar
108          Greenberg       3  / King / Kochhar / Greenberg
109          Faviet          4  / King / Kochhar / Greenberg / Faviet
```

---

## 5. 가지치기 — WHERE vs CONNECT BY 필터

두 가지 필터 방식은 **결과가 다르다**.

### 5-1. WHERE 절 필터 — 해당 행만 제거 (계층 구조 유지)

```sql
-- IT 직군(IT_%)을 제외하되 그 하위 직원은 유지
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS name,
       job_id
FROM   employees
WHERE  job_id NOT LIKE 'IT%'           -- Hunold(IT_PROG)는 제외, 자식은 유지
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

### 5-2. CONNECT BY 절 필터 — 해당 가지 전체 제거 (Pruning)

```sql
-- IT 직군 아래의 모든 자식 포함 가지 전체 제거
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS name,
       job_id
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND job_id NOT LIKE 'IT%';      -- IT_PROG 행과 그 모든 자식 제거
```

| 구분 | WHERE 절 | CONNECT BY 절 |
|------|----------|----------------|
| 제거 범위 | 해당 행만 제거 | 해당 행 + 모든 하위 자식 제거 |
| 계층 구조 | 유지 (자식은 상위로 연결) | 해당 가지 전체 제거 |
| 용도 | 결과 필터링 | 가지 전체 배제(Pruning) |

---

## 6. CONNECT_BY_ROOT & CONNECT_BY_ISLEAF

### 6-1. CONNECT_BY_ROOT

현재 행의 루트 노드 값을 반환하는 연산자이다.

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       CONNECT_BY_ROOT last_name    AS root_name,
       CONNECT_BY_ROOT employee_id  AS root_id
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   LEVEL  ROOT_NAME  ROOT_ID
-----------  ----------  -----  ---------  -------
100          King            1  King           100
101          Kochhar         2  King           100
108          Greenberg       3  King           100
```

### 6-2. CONNECT_BY_ISLEAF

현재 행이 잎(Leaf) 노드이면 1, 아니면 0을 반환한다. 잎 노드 = 자식이 없는 최하위 노드.

```sql
SELECT employee_id,
       last_name,
       LEVEL,
       CONNECT_BY_ISLEAF  AS is_leaf,
       CONNECT_BY_ROOT last_name AS root_emp
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME   LEVEL  IS_LEAF  ROOT_EMP
-----------  ----------  -----  -------  --------
100          King            1        0  King
101          Kochhar         2        0  King
108          Greenberg       3        0  King
109          Faviet          4        1  King      ← 잎 노드
```

---

## 7. ORDER SIBLINGS BY

`ORDER BY`는 계층 순서를 무시하므로 계층 쿼리에서는 `ORDER SIBLINGS BY`를 사용한다. 같은 부모를 가진 형제 노드끼리만 정렬하며 계층 구조를 유지한다.

```sql
-- 같은 관리자 밑의 직원을 급여 내림차순으로 정렬
SELECT LEVEL,
       LPAD(' ', (LEVEL-1)*2) || last_name AS name,
       salary
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY salary DESC;
```

> **주의:** `ORDER BY`를 사용하면 계층 순서가 깨진다. 계층 정렬에는 반드시 `ORDER SIBLINGS BY` 사용.

---

## 8. 순환 참조 처리 — NOCYCLE & CONNECT_BY_ISCYCLE

데이터에 순환 참조(A→B→C→A)가 있으면 `CONNECT BY`는 무한 루프에 빠진다.

### 8-1. NOCYCLE 키워드

순환이 감지되면 해당 경로를 중단하고 오류 없이 진행한다.

```sql
SELECT LEVEL,
       employee_id,
       last_name,
       CONNECT_BY_ISCYCLE AS is_cycle
FROM   employees
START WITH manager_id IS NULL
CONNECT BY NOCYCLE PRIOR employee_id = manager_id;
```

### 8-2. CONNECT_BY_ISCYCLE

현재 행이 순환 참조를 유발하는 노드이면 1, 아니면 0을 반환한다. `NOCYCLE`과 함께 사용.

```sql
-- 순환 참조 발생 행 확인
SELECT employee_id, last_name, CONNECT_BY_ISCYCLE AS cycle_flag
FROM   employees
START WITH manager_id IS NULL
CONNECT BY NOCYCLE PRIOR employee_id = manager_id
HAVING CONNECT_BY_ISCYCLE = 1;
```

---

## 9. 계층 쿼리 활용 예제

### 9-1. 특정 관리자 아래 모든 직원 수 집계

```sql
SELECT CONNECT_BY_ROOT last_name  AS top_mgr,
       COUNT(*) - 1               AS total_subordinates
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
GROUP BY CONNECT_BY_ROOT last_name
ORDER BY total_subordinates DESC;
```

### 9-2. 최하위 직원(잎 노드)만 조회

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  CONNECT_BY_ISLEAF = 1
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER BY salary DESC;
```

### 9-3. 특정 직원의 상위 경로 조회

```sql
-- Faviet(109)의 루트까지 경로 조회
SELECT LEVEL,
       employee_id,
       last_name,
       SYS_CONNECT_BY_PATH(last_name, '→') AS full_path
FROM   employees
START WITH employee_id = 109
CONNECT BY PRIOR manager_id = employee_id;
```

**결과:**
```
LEVEL  EMPLOYEE_ID  LAST_NAME   FULL_PATH
-----  -----------  ----------  ----------------------------
    1          109  Faviet      →Faviet
    2          108  Greenberg   →Faviet→Greenberg
    3          101  Kochhar     →Faviet→Greenberg→Kochhar
    4          100  King        →Faviet→Greenberg→Kochhar→King
```
