# Oracle Database 19c: SQL Workshop
## Appendix F — 계층적 데이터 조회 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | `START WITH` — 루트 노드 조건 지정 |
| 2 | ② | `PRIOR employee_id = manager_id` → 부모의 employee_id = 자식의 manager_id → 하향식 |
| 3 | ② | `PRIOR manager_id = employee_id` → 자식의 manager_id(=부모id) = 부모의 employee_id → 상향식 |
| 4 | ② | 루트 노드는 LEVEL = 1 |
| 5 | ② | PRIOR: 현재 행의 부모 행 값을 참조하는 키워드 |
| 6 | ② | `LPAD(last_name, LENGTH(last_name)+(LEVEL*2)-2, '_')` |
| 7 | ② | `ORDER SIBLINGS BY`: 같은 부모의 형제 노드 간 정렬 |
| 8 | ② | `manager_id IS NULL` → 최상위 관리자(루트) |
| 9 | ② | `LEVEL=3`: `(3*2)-2 = 4` 문자 추가 → 원래 길이+4 → 4문자 들여쓰기 |
| 10 | ② | WHERE 절: 해당 노드만 제거, 하위 노드는 유지 |
| 11 | ② | CONNECT BY 절: 해당 노드와 모든 하위 가지 제거 |
| 12 | ③ | `CONNECT BY`만 필수, `START WITH`는 선택 (없으면 모든 행이 루트) |
| 13 | ② | 루트(King) = LEVEL 1 |
| 14 | ② | `PRIOR` 없이 `CONNECT BY` 사용 시 ORA-01788 오류 발생 |
| 15 | ① | 자기 참조 테이블: 부모 키(employee_id)와 자식 키(manager_id)가 같은 테이블에 존재 |
| 16 | ② | King=LEVEL 1, Kochhar=LEVEL 2 (King의 직속 부하) |
| 17 | ② | CONNECT BY: 부모-자식 관계 정의 및 탐색 방향 지정 |
| 18 | ② | `START WITH`: 루트 지정 / `WHERE`: 최종 결과 필터링 |
| 19 | ② | `SYS_CONNECT_BY_PATH(col, '구분자')`: 루트에서 현재 노드까지 경로 문자열 반환 |
| 20 | ② | `employee_id=206`(Gietz)에서 시작, `PRIOR manager_id = employee_id` → 상향식 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

`START WITH last_name = 'King'` → King이 루트 = LEVEL 1  
`ORDER SIBLINGS BY last_name`: King의 형제는 없으므로 첫 번째 행은 King 자신.

```
LEVEL  LAST_NAME
1      King
2      De Haan
3        Hunold
...
2      Kochhar
...
```

---

**[22번] 정답: ②**

`ORDER SIBLINGS BY last_name`: 같은 manager_id를 가진 직원들을 last_name 알파벳 오름차순으로 정렬.  
De Haan, Kochhar, Mourgos 순 (King의 직속 부하)

---

**[23번] 정답: ②**

`WHERE last_name != 'Kochhar'`는 계층 탐색이 완료된 후에 최종 결과에서 Kochhar 행만 제거한다.  
Kochhar의 부하 직원(Whalen, Higgins 등)은 계층 탐색 과정에서 이미 연결되었으므로 결과에 남는다.

---

**[24번] 정답: ②**

`CONNECT BY PRIOR employee_id = manager_id AND last_name != 'Kochhar'`:  
Kochhar 노드에서 탐색 자체가 중단되므로 Kochhar와 그의 모든 부하(Whalen, Higgins, Gietz 등)가 결과에서 제거된다.

---

**[25번] 정답: ②**

```
LPAD(last_name, LENGTH('De Haan') + (2*2) - 2, '_')
= LPAD('De Haan', 6 + 4 - 2, '_')
= LPAD('De Haan', 8, '_')
```
총 길이 8 → 원래 6자 + 앞에 '_' 2개 추가

---

**[26번] 정답: ③**

King = LEVEL 1 (루트)  
King의 직속 부하 (Kochhar, De Haan 등) = **LEVEL 2**

---

**[27번] 정답: ②**

계층적 쿼리는 `CONNECT BY PRIOR`를 통해 부모-자식 관계를 따라가며 재귀적으로 데이터를 탐색한다. 일반 SELECT는 행 간의 관계를 탐색하지 않는다.

---

**[28번] 정답: ③**

```
King (LEVEL=1) → Kochhar (LEVEL=2) → Higgins (LEVEL=3) → Gietz (LEVEL=4)
```

---

**[29번] 정답: ②**

`CONNECT BY PRIOR column1 = column2`:
- `PRIOR column1`: 현재 행의 부모 행의 column1
- `column2`: 현재 행의 column2
- 부모의 column1이 자식의 column2와 같을 때 → column1이 부모 키

`PRIOR employee_id = manager_id`: 부모의 employee_id = 자식의 manager_id → 하향식

---

**[30번] 정답: ②**

`SYS_CONNECT_BY_PATH(last_name, '/')`:  
루트에서 현재 노드까지 경로를 `'/'`로 구분하여 문자열로 반환.  
예: `/King/Kochhar/Whalen`

---

**[31번] 정답: ①**

`CONNECT_BY_ROOT column`: 현재 행이 속한 서브트리의 루트 노드의 column 값을 반환.  
계층 내 모든 행이 동일한 루트에서 출발했다면, 모든 행에서 같은 값을 반환.

---

**[32번] 정답: ②**

`CONNECT_BY_ISLEAF`:
- `1`: 현재 노드에 자식이 없는 리프(Leaf) 노드
- `0`: 자식이 있는 부모 노드

---

**[33번] 정답: ①**

`START WITH department_id = 90`:  
department_id = 90에 속한 **모든 직원**이 각각 루트가 된다.  
즉, 여러 서브트리가 생성될 수 있다.

---

**[34번] 정답: ②**

`NOCYCLE`: 순환 참조(A→B→C→A)가 있는 경우, 일반적으로 `ORA-01436: CONNECT BY loop in user data` 오류가 발생한다.  
`NOCYCLE`을 지정하면 오류 대신 순환이 감지된 지점에서 탐색을 중단하고 계속 진행한다.

---

**[35번] 정답: ②**

계층적 쿼리에서:
- `WHERE`: 계층 탐색 완료 후 최종 결과 행을 필터링
- `HAVING`: 집계 함수 결과를 조건으로 필터링 (GROUP BY와 함께)

두 절은 역할이 다르며, 계층적 쿼리에서 HAVING은 집계와 함께 사용한다.

---

**[36번] 정답: ②**

`CONNECT BY PRIOR employee_id = manager_id`에서:
- `PRIOR employee_id`: 부모 행의 employee_id
- `manager_id` (PRIOR 없음): **현재 행의** manager_id

---

**[37번] 정답: ②**

계층적 쿼리에서 집계 함수를 직접 사용하면 의미가 불분명해진다.  
올바른 방법:
```sql
SELECT SUM(salary)
FROM (
    SELECT salary
    FROM   employees
    START  WITH employee_id = 101
    CONNECT BY PRIOR employee_id = manager_id
);
```

---

**[38번] 정답: ①**

`LPAD(문자열, 총_길이, 채우기_문자)`:
- 1번째 인수: 원본 문자열
- 2번째 인수: 결과 총 길이
- 3번째 인수: 왼쪽에 채울 문자

---

**[39번] 정답: ②**

`START WITH` 절이 없으면 테이블의 **모든 행**이 루트가 되어 각자의 서브트리를 형성한다.  
결과가 매우 많아질 수 있으므로 일반적으로 `START WITH`를 명시한다.

---

**[40번] 정답: ②**

`SYS_CONNECT_BY_PATH(last_name, '/')`:
- 두 번째 인수 `'/'`가 각 노드 값을 구분하는 구분자
- 루트부터 현재 노드까지 `'/값1/값2/값3'` 형태로 경로 반환

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

Whalen의 경로: King(루트) → Kochhar → Whalen  
`SYS_CONNECT_BY_PATH(last_name, '/')` = `/King/Kochhar/Whalen`

---

**[42번] 정답: ①**

`WHERE` 절은 계층 탐색이 모두 완료된 **후에** 최종 결과에서 행을 필터링한다.  
따라서 Kochhar를 WHERE로 제거해도 이미 탐색된 Kochhar의 자식 노드들(Whalen, Higgins 등)은 결과에 남아있다.

반면 `CONNECT BY` 조건으로 Kochhar를 제거하면 **탐색 자체**를 중단하므로 자식 노드까지 제거된다.

---

**[43번] 정답: ②**

Gietz의 경로: Kochhar → Higgins → Gietz  
`CONNECT BY ... AND last_name != 'Higgins'`:
- Higgins 노드에서 탐색이 중단됨
- Higgins가 없으므로 Gietz(manager_id=Higgins.id)로 연결되는 경로가 형성되지 않음
- 결과: Gietz 포함 불가

---

**[44번] 정답: ①**

`CONNECT_BY_ROOT last_name`: 루트 노드의 last_name 값을 반환.  
`START WITH manager_id IS NULL`이면 King이 루트이므로 모든 행에서 `root_name = 'King'`.  
단, 여러 루트가 있을 경우 각 서브트리의 루트 이름이 표시된다.

---

**[45번] 정답: ②**

**순환 참조 발생 조건**: 자식 행이 다시 조상 행의 키를 가리킬 때.  
예: A→B→C→A (데이터 오류)

`NOCYCLE`: Oracle이 순환을 감지하면 오류(`ORA-01436`) 대신 순환 시작점에서 탐색을 중단하고 다른 경로를 계속 탐색한다.  
`CONNECT_BY_ISCYCLE` 의사컬럼으로 순환이 발생한 행을 식별할 수 있다.

---

**[46번] 정답: ③**

```sql
SELECT MAX(LEVEL) AS max_depth
FROM   employees
START  WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

`START WITH`와 `CONNECT BY`가 모두 있어야 올바른 계층 구조가 형성된다.  
그 결과에서 `MAX(LEVEL)`로 최대 깊이를 구할 수 있다.

---

**[47번] 정답: ②**

`START WITH condition1 OR condition2`:  
두 조건 중 **하나라도 만족**하는 행이 모두 루트가 된다.  
즉, 여러 독립적인 서브트리가 생성될 수 있다.

---

**[48번] 정답: ②**

`WHERE LEVEL <= 3`: 계층 탐색 완료 후 LEVEL이 3 이하인 행만 필터링.  
`START WITH manager_id IS NULL CONNECT BY PRIOR employee_id = manager_id WHERE LEVEL <= 3`

주의: `WHERE LEVEL <= 3`은 탐색 자체를 제한하지 않고 최종 결과를 필터링하므로, 깊은 트리에서도 정상적으로 동작한다.

---

**[49번] 정답: ②**

`ORDER SIBLINGS BY`: 형제 노드 간 정렬만 수행 → 계층 구조 유지  
`ORDER BY`: 모든 결과를 정렬 기준에 따라 재배열 → 계층 구조 무너짐

예: `ORDER BY last_name`으로 정렬하면 Abel(깊은 레벨)이 맨 앞에 올 수 있어 LEVEL 순서가 뒤섞인다.

---

**[50번] 정답: ②**

계층적 쿼리 결과에 집계 함수를 적용하려면 인라인 뷰를 사용한다:

```sql
-- 특정 직원(101)과 그 부하 직원들의 급여 합계
SELECT SUM(salary) AS total
FROM (
    SELECT salary
    FROM   employees
    START  WITH employee_id = 101
    CONNECT BY PRIOR employee_id = manager_id
);
```
