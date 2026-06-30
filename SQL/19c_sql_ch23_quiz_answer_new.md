# Oracle Database 19c: SQL Workshop
## Chapter 23 — 계층 쿼리 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | `START WITH` = 탐색 시작 행(루트) 조건 지정 |
| 2 | ② | `PRIOR`가 붙은 쪽 = 이전 행(부모). `PRIOR employee_id` = 부모의 employee_id |
| 3 | ② | 루트 노드 LEVEL = 1. 자식마다 +1 증가 |
| 4 | ② | `manager_id IS NULL`인 행 = 최상위 관리자(King) = 계층 루트 |
| 5 | ② | Top-Down: `PRIOR employee_id(부모) = manager_id(자식)` — PRIOR가 부모 쪽 |
| 6 | ③ | `(LEVEL-1)*2 = (3-1)*2 = 4`개의 공백 |
| 7 | ② | 루트→현재까지 경로를 구분자로 연결. 결과는 구분자로 시작 |
| 8 | ② | `WHERE LEVEL <= 3`: 결과 필터링만, 탐색은 전체 계속됨 |
| 9 | ② | `CONNECT_BY_ISLEAF = 1`: 자식이 없는 잎(Leaf) 노드 |
| 10 | ③ | 현재 행이 속한 계층에서 최상위(루트) 노드의 값 반환 |
| 11 | ② | `ORDER SIBLINGS BY`: 형제끼리만 정렬, 계층 구조 유지 |
| 12 | ② | 순환 감지 시 `ORA-01436: CONNECT BY loop in user data` 발생 |
| 13 | ② | `NOCYCLE`: 순환 감지 시 해당 경로 중단, 오류 없이 계속 진행 |
| 14 | ② | `CONNECT_BY_ISCYCLE = 1`: 현재 행이 순환을 유발하는 노드 |
| 15 | ② | `ORDER BY`는 전체 정렬 → 계층 파괴. `ORDER SIBLINGS BY`는 형제끼리만 정렬 |
| 16 | ② | Bottom-Up: START WITH 지정 행에서 루트 방향(부모)으로 탐색 |
| 17 | ① | `CONNECT BY ... AND 조건`: 조건 불만족 행 + 그 모든 자식(가지 전체) 제거 |
| 18 | ③ | `LEVEL`은 계층 쿼리에서만 사용 가능한 의사컬럼 |
| 19 | ② | 컬럼 값에 구분자 문자가 포함되면 `ORA-30004` 오류 발생 |
| 20 | ② | `employee_id` = 자식 키(현재 행), `manager_id` = 부모 키(상위 행) |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

`START WITH manager_id IS NULL`은 King(100)을 루트로 설정하고, `CONNECT BY PRIOR employee_id = manager_id`로 모든 자식 방향 탐색을 수행한다. HR 스키마의 전체 직원 107명 모두 King 아래 연결되어 있으므로 **107행**이 반환된다.

---

**[22번] 정답: ①**

`(LEVEL-1)*2 = (4-1)*2 = 6`개의 공백.

| LEVEL | 앞 공백 수 | 들여쓰기 예 |
|-------|-----------|-------------|
| 1 | 0 | King |
| 2 | 2 | `  Kochhar` |
| 3 | 4 | `    Greenberg` |
| 4 | 6 | `      Faviet` |

---

**[23번] 정답: ②**

Hunold(103)는 Austin(105)와 Pataballa(106)라는 자식을 가지고 있으므로 잎 노드가 아니다. `CONNECT_BY_ISLEAF = 0`.

Austin(105)과 Pataballa(106)은 자식이 없으므로 `CONNECT_BY_ISLEAF = 1`.

---

**[24번] 정답: ②**

`WHERE LEVEL = 2`는 계층 탐색 후 LEVEL이 정확히 2인 행만 필터링한다. LEVEL 2 = King의 직속 부하들 (Kochhar, De Haan, Raphaely 등 3명).

---

**[25번] 정답: ②**

Bottom-Up: Faviet(109, LEVEL=1) → Greenberg(108, LEVEL=2) → Kochhar(101, LEVEL=3) → King(100, LEVEL=4). LEVEL 최대값 = **4**.

```sql
LEVEL  EMPLOYEE_ID  LAST_NAME
-----  -----------  ----------
    1          109  Faviet
    2          108  Greenberg
    3          101  Kochhar
    4          100  King
```

---

**[26번] 정답: ②**

`WHERE job_id NOT LIKE 'IT%'`는 **Hunold 행만 제거**한다. 탐색 자체는 계속되므로 Hunold의 자식인 Austin, Pataballa는 계층 탐색에서 찾아지고 결과에 포함된다.

```
King → De Haan → (Hunold 제외) → Austin ← 여전히 포함
                                → Pataballa ← 여전히 포함
```

---

**[27번] 정답: ②**

`CONNECT BY ... AND job_id NOT LIKE 'IT%'`는 `IT%` 직무인 Hunold를 탐색 경로에서 제거한다. Hunold 아래 가지 전체(Austin, Pataballa)도 함께 제거된다.

```
King → De Haan → (Hunold 가지 전체 제거)
                  Austin → 제거
                  Pataballa → 제거
```

---

**[28번] 정답: ②**

`CONNECT_BY_ROOT last_name`은 현재 행이 속한 계층의 루트 노드 last_name을 반환한다. `START WITH manager_id IS NULL`로 시작하면 루트는 King이므로 **모든 행에서 'King'**이 반환된다.

---

**[29번] 정답: ①**

`ORDER SIBLINGS BY last_name`은 알파벳 오름차순 정렬이므로:
- De Haan (D)
- Kochhar (K)
- Raphaely (R)

De Haan이 먼저, Kochhar가 다음 순서로 출력된다.

---

**[30번] 정답: ④**

`LEVEL` 의사컬럼은 SELECT, WHERE, ORDER BY 절에서 사용 가능하다. `CONNECT BY` 절 내부에서도 조건으로 사용 가능 (`CONNECT BY PRIOR ... AND LEVEL <= 3`). GROUP BY 절에서도 사용 가능하다. 따라서 ④번은 틀린 설명 — 실제로는 `GROUP BY LEVEL`도 가능하다.

---

**[31번] 정답: ②**

`WHERE CONNECT_BY_ISLEAF = 1`은 계층 탐색 후 자식이 없는 최하위 직원(잎 노드)만 필터링한다.

```sql
-- 결과 예시 (일부)
EMPLOYEE_ID  LAST_NAME
-----------  ----------
105          Austin
106          Pataballa
110          Chen
...
```

---

**[32번] 정답: ③**

`SYS_CONNECT_BY_PATH`는 루트부터 **현재 행**까지의 경로를 반환한다. `'/ King / Kochhar / Greenberg'`는 루트(King) → Kochhar → Greenberg까지의 경로이므로 **현재 행 = Greenberg**.

---

**[33번] 정답: ②**

`CONNECT BY ... AND LEVEL <= 3`은 LEVEL이 3을 초과하는 자식 탐색 자체를 중단한다 (Pruning). `WHERE LEVEL <= 3`은 탐색은 모두 하되 결과만 필터링한다.

| 조건 위치 | 효과 |
|-----------|------|
| `WHERE LEVEL <= 3` | 4레벨 이상 행은 결과에서 제외 (탐색은 계속) |
| `CONNECT BY ... AND LEVEL <= 3` | 4레벨 이상 자식 탐색 중단 (성능 유리) |

---

**[34번] 정답: ②**

`COUNT(*) - 1`에서 -1은 루트 노드 자신을 제외한 것이다. `GROUP BY CONNECT_BY_ROOT last_name`으로 루트별로 그룹핑하면 각 루트 아래의 **총 자손(부하 직원) 수**를 구할 수 있다.

HR 스키마에서 King이 유일한 루트이므로: `COUNT(*) - 1 = 107 - 1 = 106`.

---

**[35번] 정답: ①**

HR 스키마에서 King(employee_id=100)의 `manager_id`는 NULL이다. 따라서 `START WITH employee_id = 100`과 `START WITH manager_id IS NULL`은 동일한 루트(King)에서 출발하여 **동일한 결과**를 반환한다.

단, 여러 최상위 관리자가 있는 조직에서는 `employee_id = 100`은 100번 직원 하나만, `manager_id IS NULL`은 모든 루트를 시작점으로 하여 결과가 달라진다.

---

**[36번] 정답: ②**

`NOCYCLE`을 제거하고 순환 참조 데이터가 있으면 Oracle이 무한 루프를 감지하여 `ORA-01436: CONNECT BY loop in user data` 오류를 발생시킨다.

---

## 상(심화) 모범답안

---

**[37번] 정답: ④**

Oracle은 `START WITH`, `CONNECT BY`, `WHERE`, `ORDER SIBLINGS BY` 절의 순서를 자동으로 인식하므로 `CONNECT BY`가 `START WITH`보다 앞에 와도 오류가 발생하지 않는다. 결과도 동일하다.

---

**[38번] 정답: ②**

- **쿼리 A** (`WHERE last_name != 'Kochhar'`): Kochhar 행만 결과에서 제외. Kochhar의 부하인 Greenberg, Zlotkey 등은 여전히 결과에 포함됨.
- **쿼리 B** (`CONNECT BY ... AND last_name != 'Kochhar'`): Kochhar 가지 전체 제거. Kochhar 행 + 그 모든 하위 직원(Greenberg, Zlotkey, Faviet 등) 모두 제거.

---

**[39번] 정답: ①**

Bottom-Up: `START WITH employee_id = 109` → PRIOR manager_id = employee_id 방향으로 탐색.
- LEVEL 1: Faviet(109)
- LEVEL 2: Greenberg(108)
- LEVEL 3: Kochhar(101)
- LEVEL 4: King(100)

`SYS_CONNECT_BY_PATH(employee_id, ',')`의 경로: `,109,108,101,100` (구분자로 시작). 결과 조회 순서는 LEVEL 오름차순이므로 109→108→101→100 순서로 출력.

---

**[40번] 정답: ③**

`CONNECT_BY_ISLEAF`를 WHERE 절에서 사용하면 문법 오류는 발생하지 않는다. 단, 계층 탐색이 완전히 수행된 후 잎 노드를 필터링하므로 **모든 행을 탐색해야 하는 비용**이 발생한다. 결과 자체는 올바르다.

---

**[41번] 정답: ②**

`GROUP BY`는 계층 쿼리 내부에서 직접 사용하면 예상치 못한 결과가 나올 수 있다. 올바른 방법은 계층 쿼리를 인라인 뷰 또는 CTE로 감싸고 외부에서 `GROUP BY`를 적용하는 것이다.

```sql
WITH hier AS (
    SELECT department_id, LEVEL AS lvl
    FROM   employees
    START WITH manager_id IS NULL
    CONNECT BY PRIOR employee_id = manager_id
)
SELECT department_id, ROUND(AVG(lvl), 2) AS avg_level
FROM   hier
GROUP BY department_id
ORDER BY avg_level;
```

---

**[42번] 정답: ②**

| 구분 | CONNECT_BY_ROOT | SYS_CONNECT_BY_PATH |
|------|----------------|---------------------|
| 반환 값 | 루트 노드의 단일 컬럼 값 | 루트~현재까지 전체 경로 문자열 |
| 형식 | 스칼라 값 (숫자/문자) | 문자열 (구분자로 연결) |
| 시작 | 구분자 없음 | 구분자로 시작 |
| 용도 | 루트 식별, 그룹핑 | 전체 경로 표시 |

---

**[43번] 정답: ②**

`CONNECT BY PRIOR employee_id = manager_id AND LEVEL <= 2`는 LEVEL 3 이상의 자식 탐색을 중단(Pruning)한다. 따라서:
- LEVEL 1: King(1명)
- LEVEL 2: King의 직속 부하들

두 레벨의 행이 모두 결과에 포함된다.

```sql
-- LEVEL <= 2 필터링 결과 예시
LEVEL  EMPLOYEE_ID  LAST_NAME
-----  -----------  ----------
    1          100  King
    2          101  Kochhar
    2          102  De Haan
    2          114  Raphaely
```

---

**[44번] 정답: ②**

쿼리에 오류가 없고 의도한 대로 LEVEL <= 4 조건이 정상 동작한다. `WHERE LEVEL <= 4`는 계층 탐색 후 4레벨 이하 행만 결과에 표시한다. `ORDER SIBLINGS BY`는 계층 구조를 유지하며 형제 정렬을 수행하므로 LEVEL 필터와 충돌하지 않는다.

---

**[45번] 정답: ①**

`START WITH employee_id = 108`로 설정하면 Greenberg(108)를 루트로 하는 서브트리만 탐색한다.

```sql
SELECT LEVEL, LPAD(' ',(LEVEL-1)*2)||last_name AS name
FROM   employees
START WITH employee_id = 108
CONNECT BY PRIOR employee_id = manager_id;
-- 결과: Greenberg, Faviet 등 108 아래 직원들만
```

②번 `WHERE CONNECT_BY_ROOT employee_id = 108`은 전체 트리 탐색 후 필터링이므로 결과는 같을 수 있지만 비효율적이며 ①이 더 직접적인 방법이다.

---

**[46번] 정답: ②**

`LEVEL` 의사컬럼은 계층 쿼리 내부에서만 유효하다. 계층 쿼리를 WITH 절 내부 CTE로 정의하면 LEVEL을 컬럼으로 유지할 수 있고, 외부 SELECT에서 `GROUP BY`와 집계 함수를 사용할 수 있다.

```sql
WITH hier AS (
    SELECT department_id, LEVEL AS hier_level
    FROM   employees
    START WITH manager_id IS NULL
    CONNECT BY PRIOR employee_id = manager_id
)
SELECT department_id,
       ROUND(AVG(hier_level), 2) AS avg_level,
       MAX(hier_level)            AS max_level
FROM   hier
GROUP BY department_id
ORDER BY avg_level;
```

---

**[47번] 정답: ②**

HR 스키마의 조직 계층은 최대 4단계이다:
- LEVEL 1: King(100)
- LEVEL 2: Kochhar(101), De Haan(102), Raphaely(114) 등
- LEVEL 3: Greenberg(108), Hunold(103) 등
- LEVEL 4: Faviet(109), Austin(105) 등

따라서 최대 LEVEL = **4**.

---

**[48번] 정답: ②**

`CONNECT BY employee_id = manager_id` (`PRIOR` 없음)는 계층 관계를 정의하지 못한다. Oracle은 이를 일반 조인 조건처럼 처리하여 무한 루프 또는 의도치 않은 결과를 발생시킬 수 있다. 실제로 `PRIOR` 없이는 `CONNECT BY` 절이 의미 있는 계층을 만들지 못하고 오류나 단일 행 반환으로 이어진다.

---

**[49번] 정답: ②**

`CONNECT_BY_ROOT employee_id`는 각 행의 루트 관리자 ID를 반환한다. `GROUP BY CONNECT_BY_ROOT employee_id`로 그룹핑하면 동일한 최상위 관리자를 공유하는 직원 그룹을 구분할 수 있다.

```sql
SELECT CONNECT_BY_ROOT last_name  AS top_mgr,
       COUNT(*)                   AS group_size,
       MIN(salary)                AS min_sal,
       MAX(salary)                AS max_sal
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
GROUP BY CONNECT_BY_ROOT last_name, CONNECT_BY_ROOT employee_id;
```

---

**[50번] 정답: ③**

`CONNECT_BY_ISCYCLE`은 `NOCYCLE` 키워드와 함께 사용해야만 의미가 있다. `NOCYCLE` 없이 순환 참조 데이터에 `CONNECT BY`를 수행하면 `ORA-01436` 오류가 발생하므로 `CONNECT_BY_ISCYCLE` 자체를 실행할 수 없다.

다른 선택지(`LEVEL`, `SYS_CONNECT_BY_PATH`, `CONNECT_BY_ROOT`)도 순환 참조 데이터에서 `NOCYCLE` 없이는 사용 불가하지만, `CONNECT_BY_ISCYCLE`은 특히 `NOCYCLE`과 항상 쌍으로 사용해야 한다는 규칙이 강제된다.
