# Oracle Database 19c: SQL Workshop
## Appendix F — 계층적 데이터 조회 (Hierarchical Retrieval)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- 계층적 쿼리(Hierarchical Query) 개념을 설명한다
- 트리 구조 보고서를 작성한다
- 계층 데이터를 시각적으로 형식화한다
- 특정 노드나 가지(Branch)를 트리에서 제외한다

---

## 1. 계층적 데이터 개요

관계형 테이블은 부모-자식 관계를 표현하는 **자기 참조(Self-referencing)** 컬럼을 가질 수 있다.

EMPLOYEES 테이블 예:
- `employee_id` — 직원 고유 번호 (부모 키)
- `manager_id` — 이 직원의 관리자 employee_id (자식 키 → 부모 키 참조)

```
King (employee_id=100, manager_id=NULL)  ← 루트
├─ Kochhar (101, manager_id=100)
│  ├─ Whalen (200, manager_id=101)
│  └─ Higgins (205, manager_id=101)
│     └─ Gietz (206, manager_id=205)
└─ De Haan (102, manager_id=100)
   └─ Hunold (103, manager_id=102)
      ├─ Ernst (104, manager_id=103)
      └─ Lorentz (107, manager_id=103)
```

---

## 2. 계층적 쿼리 구문

```sql
SELECT [LEVEL], column, expr ...
FROM   table
[WHERE  condition(s)]
[START WITH condition(s)]
[CONNECT BY PRIOR condition(s)];
```

| 절 | 역할 |
|----|------|
| `START WITH` | 트리의 시작 노드(루트) 조건 지정 |
| `CONNECT BY PRIOR` | 부모-자식 관계를 정의하는 조건 |
| `LEVEL` | 현재 노드의 깊이 (루트 = 1) |

---

## 3. START WITH — 시작점 지정

트리 탐색을 시작할 루트 노드를 지정한다.

```sql
-- 직원 이름이 'Kochhar'인 사람을 루트로 시작
... START WITH last_name = 'Kochhar'

-- 일반 형식
... START WITH column1 = value
```

---

## 4. CONNECT BY PRIOR — 탐색 방향

```sql
CONNECT BY PRIOR column1 = column2
```

### 4-1. 하향식 (Top-Down): 상위 → 하위

```sql
-- PRIOR: 부모 키 = 자식의 manager_id 참조
... CONNECT BY PRIOR employee_id = manager_id
```

루트(King) → 부서장 → 팀장 → 팀원 순으로 내려간다.

### 4-2. 상향식 (Bottom-Up): 하위 → 상위

```sql
-- PRIOR: 부모의 manager_id = 현재 employee_id 참조
... CONNECT BY PRIOR manager_id = employee_id
```

특정 직원에서 시작하여 최상위 관리자까지 올라간다.

---

## 5. 하향식 예제 (Top-Down)

```sql
SELECT  last_name || ' reports to ' ||
        PRIOR last_name AS "Walk Top Down"
FROM    employees
START   WITH last_name = 'King'
CONNECT BY PRIOR employee_id = manager_id;
```

**결과 예시:**
```
Walk Top Down
------------------------------
King reports to
Kochhar reports to King
Whalen reports to Kochhar
Higgins reports to Kochhar
Gietz reports to Higgins
De Haan reports to King
...
```

---

## 6. 상향식 예제 (Bottom-Up)

```sql
SELECT employee_id, last_name, job_id, manager_id
FROM   employees
START  WITH  employee_id = 101
CONNECT BY PRIOR manager_id = employee_id;
```

employee_id = 101(Kochhar)에서 시작하여 최상위 관리자(King)까지 올라간다.

---

## 7. LEVEL 의사컬럼

`LEVEL`은 계층 쿼리에서 각 행의 **깊이(depth)** 를 반환하는 의사컬럼이다.

- 루트 노드: LEVEL = 1
- 루트의 직속 하위: LEVEL = 2
- 그 하위: LEVEL = 3 …

```sql
SELECT LEVEL, employee_id, last_name, manager_id
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

`ORDER SIBLINGS BY`: 같은 부모를 가진 형제 노드 간의 정렬 기준 지정.

---

## 8. LPAD로 계층 시각화

`LEVEL`과 `LPAD`를 결합하여 들여쓰기 조직도를 생성한다.

```sql
COLUMN org_chart FORMAT A20
SELECT LPAD(last_name,
            LENGTH(last_name) + (LEVEL * 2) - 2,
            '_')  AS org_chart
FROM   employees
START  WITH  first_name = 'Steven' AND last_name = 'King'
CONNECT BY PRIOR employee_id = manager_id;
```

**결과 예시:**
```
ORG_CHART
--------------------
King
__Kochhar
____Whalen
____Higgins
______Gietz
__De Haan
____Hunold
______Ernst
______Lorentz
```

---

## 9. 가지 제거 (Pruning Branches)

### 9-1. WHERE 절 — 단일 노드 제거

`WHERE` 절은 해당 노드만 결과에서 제외하고, 그 하위 노드는 그대로 유지한다.

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  last_name != 'Higgins'          -- Higgins만 제외 (Gietz는 남음)
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

### 9-2. CONNECT BY — 가지 전체 제거

`CONNECT BY` 조건에 추가하면 해당 노드와 그 하위 가지 전체가 제거된다.

```sql
SELECT employee_id, last_name
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND last_name != 'Higgins';     -- Higgins와 모든 하위 제거
```

---

## 10. 단원 요약

| 요소 | 설명 |
|------|------|
| `START WITH` | 루트 노드 조건 지정 |
| `CONNECT BY PRIOR a = b` | 하향식: PRIOR가 부모 키 앞에 위치 |
| `CONNECT BY PRIOR b = a` | 상향식: PRIOR가 자식 키 앞에 위치 |
| `LEVEL` | 각 행의 계층 깊이 (루트=1) |
| `LPAD + LEVEL` | 들여쓰기로 계층 시각화 |
| `ORDER SIBLINGS BY` | 형제 노드 간 정렬 |
| `WHERE` 절 제거 | 노드만 제거, 하위 유지 |
| `CONNECT BY` 절 제거 | 노드와 하위 가지 전체 제거 |
