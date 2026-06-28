# Oracle Database 19c: SQL Workshop
## Appendix F — 계층적 데이터 조회 | 연습문제 (50문제)

---

## 하(기초) — 20문제

**[1번]** 다음 중 Oracle 계층적 쿼리에서 루트 노드를 지정하는 절은?

① LEVEL  
② START WITH  
③ CONNECT BY  
④ PRIOR

---

**[2번]** `CONNECT BY PRIOR employee_id = manager_id`의 탐색 방향은?

① 상향식 (하위 → 상위)  
② 하향식 (상위 → 하위)  
③ 수평 탐색  
④ 역순 탐색

---

**[3번]** `CONNECT BY PRIOR manager_id = employee_id`의 탐색 방향은?

① 하향식 (상위 → 하위)  
② 상향식 (하위 → 상위)  
③ 방향 없음  
④ 알 수 없음

---

**[4번]** LEVEL 의사컬럼에서 루트 노드의 값은?

① 0  
② 1  
③ 루트의 employee_id 값  
④ NULL

---

**[5번]** 다음 계층적 쿼리에서 `PRIOR`의 역할은?

```sql
CONNECT BY PRIOR employee_id = manager_id
```

① manager_id를 자식 키로 참조  
② 현재 행의 부모 행 employee_id를 참조  
③ 순환 참조를 방지  
④ 정렬 순서를 지정

---

**[6번]** 계층 데이터를 들여쓰기로 시각화할 때 주로 사용하는 함수 조합은?

① SUBSTR + LEVEL  
② LPAD + LEVEL  
③ RPAD + ROWNUM  
④ TRIM + ROWNUM

---

**[7번]** 다음 중 `ORDER SIBLINGS BY`에 대한 올바른 설명은?

① 모든 행을 정렬한다  
② 같은 부모를 가진 형제 노드 간에만 정렬한다  
③ LEVEL 기준으로 정렬한다  
④ START WITH 조건에 따라 정렬한다

---

**[8번]** 다음 쿼리에서 시작 노드는?

```sql
START WITH manager_id IS NULL
```

① 특정 관리자가 있는 직원  
② 관리자가 없는 최상위 직원 (루트)  
③ 모든 직원  
④ manager_id = 0인 직원

---

**[9번]** `LPAD(last_name, LENGTH(last_name) + (LEVEL*2) - 2, '_')`에서 LEVEL=3일 때 들여쓰기 문자 수는?

① 2  
② 4  
③ 6  
④ LEVEL과 무관

---

**[10번]** WHERE 절로 특정 노드를 제거할 때의 결과는?

① 해당 노드와 모든 하위 노드가 제거된다  
② 해당 노드만 제거되고 하위 노드는 남는다  
③ 해당 노드의 상위 노드가 제거된다  
④ 쿼리가 오류를 발생시킨다

---

**[11번]** CONNECT BY 절로 특정 노드를 제거할 때의 결과는?

① 해당 노드만 제거되고 하위 노드는 남는다  
② 해당 노드와 그 하위 가지 전체가 제거된다  
③ 루트 노드가 제거된다  
④ 정렬 순서가 바뀐다

---

**[12번]** 다음 중 계층적 쿼리에서 반드시 필요한 절은?

① LEVEL  
② START WITH  
③ CONNECT BY  
④ ORDER SIBLINGS BY

---

**[13번]** 다음 쿼리에서 King의 LEVEL 값은?

```sql
SELECT LEVEL, last_name
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① 0  
② 1  
③ 2  
④ King은 결과에 포함되지 않는다

---

**[14번]** `PRIOR` 키워드 없이 CONNECT BY를 사용하면?

① 하향식 탐색을 수행한다  
② 오류가 발생한다  
③ 상향식 탐색을 수행한다  
④ 계층 없이 일반 JOIN처럼 동작한다

---

**[15번]** 다음 중 자기 참조(Self-referencing) 테이블의 특징으로 옳은 것은?

① 같은 테이블에 부모 키와 자식 키가 모두 존재한다  
② 두 개의 서로 다른 테이블을 참조한다  
③ PRIMARY KEY가 없다  
④ FOREIGN KEY를 사용할 수 없다

---

**[16번]** Kochhar(employee_id=101, manager_id=100)의 LEVEL 값은 얼마인가? (King이 루트, LEVEL=1)

① 1  
② 2  
③ 3  
④ 101

---

**[17번]** 다음 계층적 쿼리에서 CONNECT BY 절의 역할은?

```sql
CONNECT BY PRIOR employee_id = manager_id
```

① 시작 노드 지정  
② 부모-자식 관계 정의 및 탐색 방향 지정  
③ 결과 정렬  
④ 중복 행 제거

---

**[18번]** 계층적 쿼리에서 `WHERE` 절과 `START WITH` 절의 차이는?

① 두 절은 동일한 기능이다  
② START WITH는 루트를 지정하고, WHERE는 최종 결과를 필터링한다  
③ WHERE는 루트를 지정하고, START WITH는 결과를 필터링한다  
④ 두 절은 함께 사용할 수 없다

---

**[19번]** 다음 중 `SYS_CONNECT_BY_PATH` 함수의 용도는?

① 계층 깊이를 반환한다  
② 루트에서 현재 노드까지의 경로를 문자열로 반환한다  
③ 루트 노드를 반환한다  
④ 형제 노드 수를 반환한다

---

**[20번]** 다음 쿼리의 탐색 방향은?

```sql
START  WITH employee_id = 206
CONNECT BY PRIOR manager_id = employee_id;
```

① King → Kochhar → ... → Gietz (하향식)  
② Gietz → Higgins → Kochhar → King (상향식)  
③ 방향 없음  
④ 가로 탐색

---

## 중(응용) — 20문제

**[21번]** 다음 쿼리 결과의 첫 번째 행은?

```sql
SELECT LEVEL, last_name
FROM   employees
START  WITH last_name = 'King'
CONNECT BY PRIOR employee_id = manager_id
ORDER  SIBLINGS BY last_name;
```

① LEVEL=1, last_name='De Haan'  
② LEVEL=1, last_name='King'  
③ LEVEL=2, last_name='Kochhar'  
④ LEVEL=0, last_name='King'

---

**[22번]** `ORDER SIBLINGS BY last_name` 결과에서 같은 manager_id를 가진 직원들은 어떻게 정렬되는가?

① LEVEL 기준 오름차순  
② last_name 알파벳 오름차순  
③ employee_id 기준  
④ 입력 순서

---

**[23번]** 다음 쿼리에서 WHERE 절의 영향을 올바르게 설명한 것은?

```sql
SELECT last_name
FROM   employees
WHERE  last_name != 'Kochhar'
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① Kochhar와 그의 모든 부하 직원이 제거된다  
② Kochhar만 결과에서 제외되고 그의 부하 직원은 유지된다  
③ 쿼리가 오류를 발생시킨다  
④ Kochhar의 상위 관리자가 제거된다

---

**[24번]** 다음 쿼리에서 CONNECT BY 조건의 영향은?

```sql
SELECT last_name
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
       AND last_name != 'Kochhar';
```

① Kochhar만 제외되고 부하 직원은 유지된다  
② Kochhar와 그의 모든 하위 직원이 제거된다  
③ 루트(King)가 제거된다  
④ 결과에 변화가 없다

---

**[25번]** 다음 LPAD 사용 예제에서 LEVEL=2인 직원의 org_chart 문자열 길이는? (last_name='De Haan', 길이=6)

```sql
LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, '_')
```

① 6  
② 8  
③ 10  
④ 4

---

**[26번]** 다음 쿼리에서 King의 직속 부하(Kochhar, De Haan 등)는 몇 레벨인가?

```sql
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
```

① LEVEL = 0  
② LEVEL = 1  
③ LEVEL = 2  
④ LEVEL = manager_id 값

---

**[27번]** 계층적 쿼리와 일반 SELECT의 가장 큰 차이점은?

① 집계 함수를 사용할 수 없다  
② 부모-자식 관계를 따라 재귀적으로 데이터를 탐색한다  
③ WHERE 절을 사용할 수 없다  
④ JOIN이 불가능하다

---

**[28번]** 다음 쿼리에서 Gietz(206)의 LEVEL은?

```
King(100) → Kochhar(101) → Higgins(205) → Gietz(206)
```

```sql
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
```

① 2  
② 3  
③ 4  
④ 5

---

**[29번]** PRIOR 키워드 위치에 따른 탐색 방향 변화로 옳은 것은?

① PRIOR 위치는 탐색 방향에 영향을 주지 않는다  
② PRIOR column1 = column2: column1이 부모  
③ column1 = PRIOR column2: column2가 부모  
④ 두 표현 모두 동일하다

---

**[30번]** 다음 쿼리에서 SYS_CONNECT_BY_PATH의 역할은?

```sql
SELECT SYS_CONNECT_BY_PATH(last_name, '/')
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① 각 직원의 LEVEL을 '/'로 구분하여 표시  
② 루트에서 현재 직원까지의 경로를 '/'로 구분한 문자열로 반환  
③ 부하 직원 목록을 '/'로 구분하여 반환  
④ 오류를 발생시킨다

---

**[31번]** 다음 중 CONNECT_BY_ROOT 함수의 역할은?

① 현재 행의 루트 노드 값을 반환한다  
② 현재 행의 부모 노드 값을 반환한다  
③ 형제 노드 수를 반환한다  
④ 트리의 전체 깊이를 반환한다

---

**[32번]** CONNECT_BY_ISLEAF 의사컬럼이 1을 반환하는 경우는?

① 루트 노드  
② 자식이 없는 리프(Leaf) 노드  
③ LEVEL = 1인 노드  
④ manager_id가 NULL인 노드

---

**[33번]** 다음 조건을 추가할 경우 어떤 노드부터 시작하는가?

```sql
START WITH department_id = 90
```

① department_id = 90에 속한 모든 직원부터 시작  
② department_id = 90인 부서장부터 시작  
③ department_id IS NULL인 직원부터 시작  
④ 쿼리가 오류를 발생시킨다

---

**[34번]** 다음 쿼리에서 NOCYCLE의 역할은?

```sql
SELECT last_name
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY NOCYCLE PRIOR employee_id = manager_id;
```

① 결과를 순환 방식으로 정렬한다  
② 순환 참조(Cycle)가 있는 경우 오류 대신 탐색을 중단하고 계속 진행한다  
③ LEVEL 값을 초기화한다  
④ 중복 행을 제거한다

---

**[35번]** 다음 중 계층적 쿼리에서 `WHERE`와 `HAVING`의 차이는?

① WHERE는 계층 탐색 전, HAVING은 탐색 후 필터링  
② WHERE는 최종 결과 필터링, HAVING은 집계 조건  
③ 두 절은 동일하다  
④ 계층적 쿼리에서 HAVING은 사용 불가

---

**[36번]** 다음 쿼리에서 PRIOR 키워드가 없는 `manager_id` 참조의 의미는?

```sql
CONNECT BY PRIOR employee_id = manager_id
```

① 이전 행의 manager_id  
② 현재 행의 manager_id  
③ 루트 행의 manager_id  
④ 부모 행의 manager_id

---

**[37번]** 계층적 쿼리에서 COUNT(*), SUM() 같은 집계 함수를 사용하려면?

① CONNECT BY 절 안에서 직접 사용  
② 인라인 뷰(Subquery)로 감싼 후 외부 쿼리에서 집계  
③ START WITH 절에서 사용  
④ LEVEL 절에서 사용

---

**[38번]** 다음 중 LPAD 인수로 옳은 것은?

```sql
LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, '_')
```

① LPAD(문자열, 총 길이, 채우기 문자)  
② LPAD(채우기 문자, 총 길이, 문자열)  
③ LPAD(문자열, 채우기 문자, 총 길이)  
④ LPAD(총 길이, 문자열, 채우기 문자)

---

**[39번]** 다음 중 START WITH 절이 없을 때의 기본 동작은?

① 오류가 발생한다  
② 모든 행이 루트가 되어 각각의 서브트리를 생성한다  
③ LEVEL = 1인 행만 반환한다  
④ manager_id IS NULL인 행을 자동으로 루트로 설정한다

---

**[40번]** 다음 쿼리에서 `'/'||last_name` 표현식의 의미는?

```sql
SYS_CONNECT_BY_PATH(last_name, '/')
```

① last_name 앞에 '/'를 붙인다  
② SYS_CONNECT_BY_PATH가 각 노드 값을 '/'로 구분하여 경로를 만든다  
③ last_name을 '/'로 자른다  
④ 오류를 발생시킨다

---

## 상(심화) — 10문제

**[41번]** 다음 쿼리에서 Whalen(200, manager_id=101)의 `SYS_CONNECT_BY_PATH` 결과는?

```sql
SELECT SYS_CONNECT_BY_PATH(last_name, '/') AS path
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① /King  
② /King/Kochhar/Whalen  
③ /Whalen/Kochhar/King  
④ King/Kochhar/Whalen

---

**[42번]** WHERE 절과 CONNECT BY 절에서 같은 조건으로 노드를 제거할 때, 결과가 다른 이유는?

① WHERE 절은 계층 탐색 후 결과를 필터링하므로 자식 노드가 남는다  
② CONNECT BY 절은 특정 노드에서 탐색 자체를 중단하지 않는다  
③ WHERE 절은 부모 노드를 제거한다  
④ CONNECT BY 절은 루트 노드만 제거한다

---

**[43번]** 다음 쿼리에서 Higgins를 CONNECT BY로 제거했을 때 Gietz가 포함되지 않는 이유는?

```sql
CONNECT BY PRIOR employee_id = manager_id
       AND last_name != 'Higgins';
```

① Gietz의 manager_id가 NULL이기 때문  
② Higgins 노드에서 탐색이 중단되므로 Gietz로 연결되는 경로가 없어진다  
③ Gietz의 LEVEL이 너무 깊기 때문  
④ WHERE 절 조건과 충돌하기 때문

---

**[44번]** 다음 중 `CONNECT_BY_ROOT` 사용 예로 올바른 것은?

```sql
SELECT last_name, CONNECT_BY_ROOT last_name AS root_name
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

① 결과의 root_name이 모두 'King'이다 (루트가 King인 경우)  
② root_name이 각 행의 manager 이름이다  
③ root_name이 각 행의 last_name과 같다  
④ 오류를 발생시킨다

---

**[45번]** 순환 참조(Cycle)가 발생하는 조건과 NOCYCLE의 역할로 옳은 것은?

① 같은 레벨의 두 행이 서로를 참조할 때 / NOCYCLE은 해당 행을 삭제한다  
② 자식 행의 키가 다시 조상 행의 키를 가리킬 때 / NOCYCLE은 순환 탐색을 중단하고 계속 진행한다  
③ LEVEL이 특정 값 이상일 때 / NOCYCLE은 최대 LEVEL을 제한한다  
④ 모든 행이 같은 manager_id를 가질 때 / NOCYCLE은 중복을 제거한다

---

**[46번]** 다음 중 `LEVEL`을 활용한 최대 계층 깊이 조회 쿼리로 옳은 것은?

① `SELECT MAX(LEVEL) FROM employees`  
② `SELECT MAX(LEVEL) FROM employees CONNECT BY PRIOR employee_id = manager_id`  
③ `SELECT MAX(LEVEL) FROM employees START WITH manager_id IS NULL CONNECT BY PRIOR employee_id = manager_id`  
④ `SELECT LEVEL FROM employees ORDER BY LEVEL DESC FETCH FIRST 1 ROW ONLY`

---

**[47번]** 다음 쿼리에서 START WITH에 여러 조건을 사용할 때의 동작은?

```sql
START WITH manager_id IS NULL OR department_id = 90
```

① 오류가 발생한다  
② manager_id IS NULL인 행과 department_id = 90인 행 모두가 루트가 된다  
③ 두 조건 모두 만족하는 행만 루트가 된다  
④ 첫 번째 조건만 사용된다

---

**[48번]** 계층적 쿼리에서 특정 레벨 이하의 노드만 조회하려면?

① `START WITH level <= 3`  
② `WHERE LEVEL <= 3`  
③ `CONNECT BY LEVEL <= 3`  
④ `HAVING LEVEL <= 3`

---

**[49번]** 다음 쿼리에서 ORDER SIBLINGS BY 대신 ORDER BY를 사용하면 어떤 문제가 발생하는가?

① 오류가 발생한다  
② 계층 구조가 무너지고 일반적인 정렬 결과로 바뀐다  
③ 결과가 동일하다  
④ LEVEL 값이 바뀐다

---

**[50번]** 다음 중 계층적 쿼리에서 특정 직원과 그 직원의 모든 부하 직원의 급여 합계를 구하는 올바른 방법은?

① `SELECT SUM(salary) FROM employees CONNECT BY PRIOR employee_id = manager_id`  
② 인라인 뷰로 계층 결과를 먼저 추출한 후, 외부 쿼리에서 SUM 집계  
③ `SUM(salary) OVER (CONNECT BY PRIOR employee_id = manager_id)`  
④ `GROUP BY CONNECT BY`
