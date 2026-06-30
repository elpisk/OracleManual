# Oracle Database 19c: SQL Workshop
## Chapter 23 — 계층 쿼리 | 연습문제 (50문제)

---

## 하(기초) — 20문제

**[1번]** Oracle 계층 쿼리에서 탐색 시작 행을 지정하는 절은?

① CONNECT BY  
② START WITH  
③ LEVEL  
④ ORDER SIBLINGS BY

---

**[2번]** `CONNECT BY PRIOR employee_id = manager_id`에서 `PRIOR`가 붙은 쪽이 의미하는 것은?

① 현재 행(자식)  
② 이전 행(부모)  
③ 루트 행  
④ 잎(Leaf) 행

---

**[3번]** 루트 노드의 `LEVEL` 값은?

① 0  
② 1  
③ 루트의 자식 수  
④ NULL

---

**[4번]** `START WITH manager_id IS NULL`의 의미는?

① 모든 직원부터 계층 탐색 시작  
② `manager_id`가 NULL인 행(최상위 관리자)을 루트로 설정  
③ 관리자가 없는 직원을 제외  
④ NULL인 컬럼이 있으면 오류 발생

---

**[5번]** Top-Down 계층 탐색을 수행하는 올바른 구문은?

① `CONNECT BY PRIOR manager_id = employee_id`  
② `CONNECT BY PRIOR employee_id = manager_id`  
③ `CONNECT BY employee_id = PRIOR manager_id`  
④ `CONNECT BY manager_id = PRIOR employee_id`

---

**[6번]** `LPAD(' ', (LEVEL-1)*2) || last_name`에서 LEVEL 3인 행의 앞 공백 수는?

① 2  
② 3  
③ 4  
④ 6

---

**[7번]** `SYS_CONNECT_BY_PATH(last_name, '/')` 함수에 대한 설명으로 옳은 것은?

① 현재 행에서 잎 노드까지의 경로를 반환  
② 루트부터 현재 행까지의 경로를 구분자로 연결하여 반환  
③ 형제 노드들의 이름을 연결하여 반환  
④ 부모 노드의 이름만 반환

---

**[8번]** 계층 쿼리에서 `WHERE LEVEL <= 3`의 효과는?

① 3레벨 아래의 탐색 자체를 중단  
② 3레벨까지의 행만 결과에 표시 (탐색은 계속)  
③ 루트 노드 3개만 조회  
④ 3번째 자식 노드만 조회

---

**[9번]** `CONNECT_BY_ISLEAF = 1`인 행은?

① 루트 노드  
② 자식이 없는 최하위(잎) 노드  
③ LEVEL = 1인 행  
④ `manager_id IS NULL`인 행

---

**[10번]** `CONNECT_BY_ROOT last_name`이 반환하는 값은?

① 현재 행의 last_name  
② 현재 행의 부모 last_name  
③ 현재 행의 계층에서 루트 노드의 last_name  
④ 모든 루트 노드의 last_name 목록

---

**[11번]** 형제 노드(같은 부모를 가진 노드)끼리만 정렬하고 계층 구조를 유지하려면?

① `ORDER BY salary DESC`  
② `ORDER SIBLINGS BY salary DESC`  
③ `CONNECT BY PRIOR salary DESC`  
④ `START WITH SIBLINGS ORDER BY salary`

---

**[12번]** 순환 참조(A→B→C→A)가 있는 데이터에서 `CONNECT BY`를 사용하면?

① 자동으로 무시됨  
② ORA-01436 오류 발생 (무한 루프 감지)  
③ 순환 행이 NULL로 표시됨  
④ 경고 메시지와 함께 정상 실행

---

**[13번]** `NOCYCLE` 키워드의 역할은?

① 계층 쿼리를 비순환 방식으로 변환  
② 순환 참조 감지 시 해당 경로를 중단하고 오류 없이 진행  
③ 모든 순환 행을 결과에서 제외  
④ 루트 노드가 여러 개일 때 사용

---

**[14번]** `CONNECT_BY_ISCYCLE = 1`인 행의 의미는?

① 현재 행이 루트 노드임  
② 현재 행이 순환 참조를 발생시키는 노드임  
③ 현재 행에 중복 값이 있음  
④ 현재 행의 자식이 없음

---

**[15번]** 계층 쿼리에서 `ORDER BY`와 `ORDER SIBLINGS BY`의 차이로 옳은 것은?

① `ORDER BY`는 형제 노드끼리, `ORDER SIBLINGS BY`는 전체를 정렬  
② `ORDER BY`는 계층 순서를 무시하고, `ORDER SIBLINGS BY`는 계층 유지하며 형제끼리 정렬  
③ `ORDER SIBLINGS BY`는 루트 노드만 정렬  
④ 두 절은 계층 쿼리에서 동일한 결과를 반환

---

**[16번]** Bottom-Up 탐색에서 `START WITH employee_id = 109`가 의미하는 것은?

① employee_id = 109인 행부터 자식 방향으로 탐색  
② employee_id = 109인 행부터 부모(루트) 방향으로 탐색  
③ employee_id = 109를 루트로 설정하여 전체 트리 탐색  
④ employee_id가 109 이상인 행만 탐색

---

**[17번]** `CONNECT BY` 절에서 `AND` 조건을 추가하면 어떻게 되는가?

① 해당 조건을 만족하지 않는 행과 그 모든 하위 자식이 제거됨  
② 해당 조건을 만족하지 않는 행만 제거되고 자식은 유지됨  
③ 오류가 발생함  
④ WHERE 절과 동일한 효과

---

**[18번]** 다음 중 계층 쿼리에서만 사용 가능한 의사컬럼(Pseudocolumn)은?

① ROWNUM  
② ROWID  
③ LEVEL  
④ SYSDATE

---

**[19번]** `SYS_CONNECT_BY_PATH`에서 오류가 발생하는 경우는?

① 컬럼 값에 NULL이 포함될 때  
② 컬럼 값에 구분자 문자가 포함될 때  
③ LEVEL이 10 이상일 때  
④ Bottom-Up 방향 탐색 시

---

**[20번]** 다음 중 HR 스키마의 `EMPLOYEES` 테이블에서 계층 쿼리의 자식 키와 부모 키로 올바른 것은?

① 자식 키: `manager_id`, 부모 키: `employee_id`  
② 자식 키: `employee_id`, 부모 키: `manager_id`  
③ 자식 키: `job_id`, 부모 키: `manager_id`  
④ 자식 키: `department_id`, 부모 키: `employee_id`

---

## 중(응용) — 16문제

**[21번]** 다음 쿼리의 결과로 옳은 것은?

```sql
SELECT COUNT(*) AS cnt
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① 최상위 관리자(King) 1명  
② HR 스키마 전체 직원 107명  
③ King의 직속 부하 직원 수  
④ 잎 노드 수

---

**[22번]** `LPAD(' ', (LEVEL-1)*2) || last_name`에서 LEVEL = 4인 행의 앞 공백 수는?

① 6  
② 8  
③ 4  
④ 3

---

**[23번]** 다음 쿼리에서 `Hunold(103)`의 `is_leaf` 값은? (Hunold의 부하: Austin, Pataballa)

```sql
SELECT last_name, CONNECT_BY_ISLEAF AS is_leaf
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① 1  
② 0  
③ NULL  
④ LEVEL 값과 동일

---

**[24번]** 다음 쿼리의 실행 결과 행 수로 옳은 것은?

```sql
SELECT employee_id, last_name, LEVEL
FROM   employees
WHERE  LEVEL = 2
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① 1행 (King)  
② King의 직속 부하 수 (LEVEL 2 직원들)  
③ 전체 직원 수  
④ 0행 (오류)

---

**[25번]** Bottom-Up 쿼리에서 `Faviet(109)`를 START WITH로 지정하면 최종 LEVEL 값은?

```sql
SELECT LEVEL, last_name
FROM   employees
START WITH employee_id = 109
CONNECT BY PRIOR manager_id = employee_id;
```

(Faviet → Greenberg → Kochhar → King 4단계)

① LEVEL 최대값 = 3  
② LEVEL 최대값 = 4  
③ LEVEL 최대값 = 1  
④ LEVEL은 Bottom-Up에서 사용 불가

---

**[26번]** `WHERE job_id NOT LIKE 'IT%'`를 계층 쿼리에 추가하면 Hunold(IT_PROG)의 부하 Austin, Pataballa는?

① 결과에서 제외됨  
② 결과에 포함됨  
③ NULL로 표시됨  
④ 루트 노드로 이동됨

---

**[27번]** `CONNECT BY ... AND job_id NOT LIKE 'IT%'`를 계층 쿼리에 추가하면 Hunold(IT_PROG)의 부하 Austin, Pataballa는?

① 결과에 포함됨  
② 결과에서 제외됨 (가지 전체 제거)  
③ LEVEL이 0으로 표시됨  
④ WHERE 절과 동일하게 행만 제거됨

---

**[28번]** 다음 쿼리에서 `root_name` 컬럼의 값으로 옳은 것은?

```sql
SELECT last_name,
       CONNECT_BY_ROOT last_name AS root_name
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① 각 행의 last_name  
② 모든 행에서 'King'  
③ 각 행의 직속 관리자 last_name  
④ 각 행의 잎 노드 last_name

---

**[29번]** `ORDER SIBLINGS BY last_name`이 적용될 때, De Haan(102)과 Kochhar(101)의 순서는?

① De Haan → Kochhar (알파벳 순)  
② Kochhar → De Haan (employee_id 순)  
③ 무작위  
④ LEVEL 높은 순

---

**[30번]** 다음 중 계층 쿼리에서 `LEVEL` 의사컬럼을 사용할 수 없는 절은?

① SELECT 절  
② WHERE 절  
③ GROUP BY 절  
④ CONNECT BY 절에서 조건으로만 사용

---

**[31번]** 다음 쿼리의 결과로 옳은 것은?

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  CONNECT_BY_ISLEAF = 1
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① 루트 노드(King)만 조회  
② 자식이 없는 최하위 직원만 조회  
③ LEVEL = 1인 직원만 조회  
④ 모든 직원 조회

---

**[32번]** 다음 쿼리에서 `path` 컬럼의 값이 '/ King / Kochhar / Greenberg'인 행은?

```sql
SELECT last_name,
       SYS_CONNECT_BY_PATH(last_name, ' / ') AS path
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① King  
② Kochhar  
③ Greenberg  
④ Faviet

---

**[33번]** `CONNECT BY PRIOR employee_id = manager_id AND LEVEL <= 3`의 효과는?

① 3레벨 직원만 결과에 표시  
② 3레벨 이하 자식 탐색 자체를 중단 (Pruning)  
③ WHERE LEVEL <= 3과 동일한 결과  
④ LEVEL 의사컬럼을 CONNECT BY에서 사용하면 오류

---

**[34번]** 다음 쿼리 결과에서 `total_sub`의 의미는?

```sql
SELECT CONNECT_BY_ROOT last_name AS top_mgr,
       COUNT(*) - 1              AS total_sub
FROM   employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
GROUP BY CONNECT_BY_ROOT last_name;
```

① 루트 노드 수  
② 루트를 제외한 해당 계층의 모든 자손 수  
③ 루트의 직속 부하 수  
④ 잎 노드 수

---

**[35번]** HR 스키마에서 `START WITH employee_id = 100`과 `START WITH manager_id IS NULL`의 결과 차이는?

① King(100)의 `manager_id`가 NULL이므로 결과가 동일하다  
② `manager_id IS NULL`은 여러 루트가 있을 때 모두 포함  
③ `employee_id = 100`은 King만, `manager_id IS NULL`은 모든 직원을 포함  
④ 항상 다른 결과를 반환한다

---

**[36번]** 다음 쿼리에서 `NOCYCLE`을 제거하면 어떻게 되는가? (데이터에 순환 참조 존재 가정)

```sql
SELECT employee_id, CONNECT_BY_ISCYCLE AS cycle_flag
FROM   employees
START WITH manager_id IS NULL
CONNECT BY NOCYCLE PRIOR employee_id = manager_id;
```

① 정상 실행됨  
② ORA-01436: CONNECT BY loop in user data 오류 발생  
③ 순환 행이 자동으로 NULL 처리됨  
④ 순환 행만 결과에서 제외됨

---

## 상(심화) — 14문제

**[37번]** 다음 쿼리가 잘못된 이유는?

```sql
SELECT LEVEL, last_name
FROM   employees
CONNECT BY PRIOR employee_id = manager_id
START WITH manager_id IS NULL;
```

① `CONNECT BY` 절이 `START WITH` 절보다 앞에 위치해서 오류  
② `LEVEL` 의사컬럼을 SELECT에서 사용할 수 없음  
③ `START WITH`가 없으면 오류가 나지만 있으므로 정상  
④ 오류 없음 — Oracle은 절 순서를 자동 인식

---

**[38번]** 다음 두 쿼리의 결과 차이를 올바르게 설명한 것은?

```sql
-- 쿼리 A
SELECT last_name FROM employees
WHERE  last_name != 'Kochhar'
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;

-- 쿼리 B
SELECT last_name FROM employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND last_name != 'Kochhar';
```

① A와 B는 동일한 결과를 반환한다  
② A는 Kochhar 행만 제거, B는 Kochhar와 그 모든 하위 직원을 제거  
③ B는 Kochhar 행만 제거, A는 Kochhar와 그 모든 하위 직원을 제거  
④ A는 오류가 발생한다

---

**[39번]** 다음 쿼리의 실행 결과로 옳은 것은?

```sql
SELECT employee_id, last_name, LEVEL,
       SYS_CONNECT_BY_PATH(employee_id, ',') AS id_path
FROM   employees
START WITH employee_id = 109
CONNECT BY PRIOR manager_id = employee_id;
```

① 109→108→101→100 순서로 employee_id 경로가 출력됨  
② 100→101→108→109 순서로 출력됨  
③ LEVEL이 낮은 순으로 출력됨  
④ SYS_CONNECT_BY_PATH는 Bottom-Up 방향에서 사용 불가

---

**[40번]** 아래에서 `CONNECT_BY_ISLEAF`를 WHERE 절에 사용할 때의 주의 사항은?

```sql
SELECT last_name
FROM   employees
WHERE  CONNECT_BY_ISLEAF = 1
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① `CONNECT_BY_ISLEAF`를 WHERE 절에 사용하면 오류  
② 전체 계층 탐색이 완료된 후 필터링되므로 성능 문제 없음  
③ 계층 탐색 후 잎 노드만 필터링되므로 결과는 올바르나 모든 행을 탐색해야 함  
④ `CONNECT_BY_ISLEAF`는 CONNECT BY 절에서만 사용 가능

---

**[41번]** 다음 중 계층 쿼리와 `GROUP BY`를 결합할 때 올바른 방법은?

① `CONNECT BY` 후 직접 `GROUP BY` 절 추가  
② 계층 쿼리를 인라인 뷰로 감싸고 외부에서 `GROUP BY` 적용  
③ `START WITH` 절 안에 `GROUP BY` 추가  
④ 계층 쿼리에서 `GROUP BY` 사용은 불가

---

**[42번]** `CONNECT_BY_ROOT`와 `SYS_CONNECT_BY_PATH`의 차이로 옳은 것은?

① `CONNECT_BY_ROOT`는 문자열, `SYS_CONNECT_BY_PATH`는 숫자 반환  
② `CONNECT_BY_ROOT`는 루트 한 값, `SYS_CONNECT_BY_PATH`는 루트~현재 전체 경로 문자열  
③ `CONNECT_BY_ROOT`는 Bottom-Up에서만 사용 가능  
④ `SYS_CONNECT_BY_PATH`는 Oracle 12c 이상에서만 지원

---

**[43번]** 다음 쿼리로 조회되는 행 수는? (HR 스키마에서 King 아래 직원 총 106명)

```sql
SELECT employee_id
FROM   employees
START WITH employee_id = 100
CONNECT BY PRIOR employee_id = manager_id
       AND LEVEL <= 2;
```

① 1행 (King만)  
② King + King의 직속 부하 (LEVEL 1+2)  
③ 3레벨까지 직원  
④ 전체 107명

---

**[44번]** 아래 쿼리가 원하는 결과(4레벨 초과 직원 제외)를 얻지 못하는 이유는?

```sql
SELECT last_name, LEVEL
FROM   employees
WHERE  LEVEL <= 4
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER SIBLINGS BY last_name;
```

① `ORDER SIBLINGS BY`가 LEVEL 필터와 충돌함  
② 오류 없음 — LEVEL <= 4 조건이 정상 동작  
③ WHERE LEVEL 사용은 불가  
④ START WITH 조건이 없어서 오류

---

**[45번]** 계층 쿼리에서 특정 서브트리(Greenberg(108) 아래)만 별도 조회하려 할 때 올바른 방법은?

① `START WITH employee_id = 108`로 설정  
② `WHERE CONNECT_BY_ROOT employee_id = 108`  
③ `CONNECT BY manager_id = 108`  
④ ①과 ②는 동일한 결과를 반환

---

**[46번]** 계층 쿼리 결과를 WITH 절과 결합하여 각 부서별 계층 레벨 평균을 구하는 올바른 방법은?

① 계층 쿼리 내부에서 바로 AVG(LEVEL) GROUP BY 사용  
② 계층 쿼리를 CTE로 정의하고 외부에서 AVG(LEVEL) GROUP BY 사용  
③ LEVEL 의사컬럼은 WITH 절 내부에서 사용 불가  
④ ORDER SIBLINGS BY와 GROUP BY를 함께 사용

---

**[47번]** HR 스키마에서 `employee_id = 100` (King)부터 시작하여 Top-Down 탐색 시 최대 LEVEL 값은? (조직도 4단계 가정)

① 3  
② 4  
③ 5  
④ LEVEL은 무제한

---

**[48번]** 다음 중 `CONNECT BY PRIOR`에서 `PRIOR`를 생략하면 어떻게 되는가?

```sql
CONNECT BY employee_id = manager_id
```

① Top-Down 탐색이 수행됨  
② 계층 탐색이 수행되지 않고 일반 자기 JOIN처럼 동작하거나 오류 발생  
③ Bottom-Up 탐색이 수행됨  
④ 루트 노드만 조회됨

---

**[49번]** 계층 쿼리 결과에서 `CONNECT_BY_ROOT`를 활용하여 "같은 최상위 관리자를 공유하는 직원 그룹"을 식별할 때 가장 적합한 방법은?

① `GROUP BY LEVEL`  
② `GROUP BY CONNECT_BY_ROOT employee_id`  
③ `ORDER SIBLINGS BY manager_id`  
④ `WHERE CONNECT_BY_ISLEAF = 0`

---

**[50번]** 계층 쿼리에서 다음 의사컬럼/연산자/함수 중 `NOCYCLE` 없이는 순환 참조 데이터에서 사용 불가한 것은?

① `LEVEL`  
② `SYS_CONNECT_BY_PATH`  
③ `CONNECT_BY_ISCYCLE`  
④ `CONNECT_BY_ROOT`
