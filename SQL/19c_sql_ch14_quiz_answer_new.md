# Oracle Database 19c: SQL Workshop
## Chapter 14 — 뷰(View) 생성 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | 뷰 = 하나 이상의 테이블 데이터를 논리적으로 표현하는 객체 (데이터 저장 없음) |
| 2 | ③ | `FORCE` — 기반 테이블 없어도 강제 생성 |
| 3 | ③ | 단순 뷰 = 1개 테이블, 함수·그룹 없음, DML 가능 |
| 4 | ② | 지정한 3개 열만 포함한 부서 80번 직원 뷰 생성 |
| 5 | ② | `CREATE OR REPLACE VIEW` — 뷰 재정의 표준 방법 |
| 6 | ② | 뷰는 일반 테이블처럼 `SELECT * FROM 뷰명` 사용 |
| 7 | ③ | `TEXT` 컬럼에 뷰 정의(서브쿼리) 저장 |
| 8 | ② | `WITH READ ONLY` = 모든 DML 차단, SELECT는 허용 |
| 9 | ③ | `DROP VIEW 뷰명;` |
| 10 | ③ | 뷰 삭제 시 기반 테이블·데이터 무영향 |
| 11 | ② | `WITH CHECK OPTION` = 뷰의 WHERE 조건을 만족하는 DML만 허용 |
| 12 | ② | 복합 뷰 = 여러 테이블·함수·그룹 포함 가능, DML 제한적 |
| 13 | ③ | `RENAME` 키워드는 뷰 열 별칭에 존재하지 않음 |
| 14 | ① | `OR REPLACE` = 기존 권한 유지하며 뷰 재정의 |
| 15 | ② | `salary*12`에 부여한 열 별칭 |
| 16 | ② | `SELECT view_name FROM user_views;` |
| 17 | ③ | 뷰는 데이터를 저장하지 않으므로 디스크 공간 절약과 무관 |
| 18 | ③ | `DESCRIBE` = 뷰의 열 이름과 데이터 타입 표시 |
| 19 | ② | 기반 테이블이 아직 없는 상황에서 뷰 정의를 미리 생성 |
| 20 | ③ | GROUP BY를 포함한 복합 뷰는 DML 불가 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

단순 뷰라도 다음 요소가 있으면 DELETE 불가:
- 그룹 함수 / GROUP BY / **DISTINCT** / ROWNUM

`DISTINCT`를 포함한 뷰는 특정 행을 식별할 수 없어 DELETE 불가.

---

**[22번] 정답: ②**

`WITH CHECK OPTION`은 뷰의 WHERE 조건(`department_id = 20`)을 벗어나는 DML을 차단.  
`department_id = 30`으로 삽입을 시도했으므로 **ORA-01402** 오류 발생.

```
ORA-01402: view WITH CHECK OPTION where-clause violation
```

---

**[23번] 정답: ②**

| 방법 | 기존 권한 | 비고 |
|------|-----------|------|
| `CREATE OR REPLACE VIEW` | **유지됨** | 뷰 재정의, 권한 유지 |
| `DROP VIEW` + `CREATE VIEW` | 사라짐 | 권한 재부여 필요 |

`OR REPLACE`가 운영 환경에서 안전한 이유.

---

**[24번] 정답: ②**

```sql
CREATE VIEW dept_sal_vu
AS SELECT department_id, AVG(salary) avg_sal
   FROM   employees GROUP BY department_id;
```

- `AVG(salary)` — 집계 함수 포함
- `GROUP BY` 절 포함

→ DELETE / UPDATE / INSERT 모두 불가.

---

**[25번] 정답: ②**

`annual_sal = salary * 12`는 **표현식**으로 정의된 열.  
표현식 열이 포함된 뷰는 INSERT 불가 (어떤 실제 열에 값을 넣어야 할지 알 수 없음).

```
ORA-01733: virtual column not allowed here
```

---

**[26번] 정답: ②**

`WITH READ ONLY`는 DML(INSERT/UPDATE/DELETE)만 차단.  
**SELECT는 정상적으로 수행 가능**.

---

**[27번] 정답: ②**

`CREATE VIEW 뷰명 (alias1, alias2, ...)` — 괄호 안 이름이 뷰의 열 별칭.  
서브쿼리 열 순서와 1:1 대응:
- `employee_id` → `id_number`
- `first_name||' '||last_name` → `name`
- `salary` → `sal`
- `department_id` → `department_id`

---

**[28번] 정답: ②**

```sql
SELECT text
FROM   user_views
WHERE  view_name = 'EMPVU80';
```

`TEXT` 컬럼에 서브쿼리 전체 텍스트가 저장됨.

---

**[29번] 정답: ③**

JOIN을 포함한 뷰(여러 테이블 기반)는 INSERT 시 어느 테이블에 삽입해야 할지 Oracle이 판단할 수 없음.  
→ **JOIN이 포함된 복합 뷰에서는 INSERT 불가**.

---

**[30번] 정답: ③**

뷰 서브쿼리에서 ORDER BY는 일반적으로 허용되지 않음.  
단, `ROWNUM`이나 `FETCH FIRST` 등 TOP-N 쿼리와 함께 사용할 때는 허용됨.

```sql
-- 허용 예시
CREATE VIEW top5_sal AS
SELECT employee_id, salary FROM employees
ORDER BY salary DESC FETCH FIRST 5 ROWS ONLY;
```

---

**[31번] 정답: ②**

```sql
CREATE VIEW empvu30
AS SELECT employee_id, last_name, salary
   FROM   employees WHERE department_id = 30;
```

- 단순 뷰 (1개 테이블, 함수·그룹 없음, 표현식 없음)
- `salary`가 기반 테이블의 실제 열

→ **UPDATE 가능**.  
단, `WITH CHECK OPTION` 없으므로 salary 변경 후 뷰에서 사라져도 오류 없음.

---

**[32번] 정답: ②**

`USER_VIEWS.READ_ONLY = 'Y'`는 `WITH READ ONLY` 옵션으로 생성된 경우.  
`WITH CHECK OPTION`은 `READ_ONLY = 'N'`이고 DML 자체를 막지는 않음.

---

**[33번] 정답: ③**

- 자신의 뷰: 자동 소유 권한으로 DROP 가능
- 다른 사용자 뷰: `DROP ANY VIEW` 시스템 권한 필요

---

**[34번] 정답: ②**

`CONSTRAINT empvu20_ck`로 이름을 부여하면 오류 발생 시 메시지에 제약 조건 이름이 표시됨:

```
ORA-01402: view WITH CHECK OPTION where-clause violation
CONSTRAINT: EMPVU20_CK
```

디버깅·문제 추적 시 유용.

---

**[35번] 정답: ②**

`ROWNUM`을 포함한 뷰에서 불가능한 작업: **DELETE, UPDATE, INSERT** (DML 전체).  
`SELECT`와 `DESCRIBE`, `CREATE OR REPLACE`는 정상 수행 가능.

---

**[36번] 정답: ②**

Oracle은 뷰 위에 또 다른 뷰(뷰 기반 뷰)를 생성하는 것을 허용함.

```sql
CREATE VIEW emp_dept_vu AS
SELECT e.last_name, d.department_name
FROM   employees e JOIN departments d USING(department_id);

CREATE VIEW high_sal_dept_vu AS
SELECT * FROM emp_dept_vu WHERE ...;
```

---

**[37번] 정답: ③**

복합 뷰에서:
- **SELECT는 항상 가능** (데이터를 읽기만 하므로)
- INSERT/UPDATE/DELETE는 집계 함수, GROUP BY, DISTINCT, ROWNUM, 표현식, JOIN 여부에 따라 제한

---

**[38번] 정답: ②**

`WITH CHECK OPTION` 없는 뷰:
- 삽입은 **성공** — 기반 테이블에 `department_id = 30` 행이 들어감
- 뷰 재조회 시 WHERE `department_id = 20` 조건에 맞지 않아 **해당 행이 보이지 않음**

이를 **"사라지는 행(disappearing rows)"** 문제라 하며, 이를 방지하기 위해 `WITH CHECK OPTION` 사용.

---

**[39번] 정답: ②**

| 뷰 | 범위 |
|-----|------|
| `USER_VIEWS` | 현재 사용자가 소유한 뷰만 |
| `ALL_VIEWS` | 현재 사용자가 접근 권한을 가진 모든 사용자의 뷰 |
| `DBA_VIEWS` | DB의 모든 뷰 (DBA만 조회) |

---

**[40번] 정답: ②**

기반 테이블이 DROP되면:
- 뷰 정의는 딕셔너리에 **남아 있음**
- 뷰 상태가 **INVALID**로 변경
- 조회 시 `ORA-04063: view ... has errors` 오류

`USER_OBJECTS` 뷰의 `STATUS` 컬럼으로 확인 가능.

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

```sql
CREATE VIEW emp_dept_vu
AS SELECT e.employee_id, e.last_name, e.salary, d.department_name
   FROM   employees e JOIN departments d USING (department_id)
   WHERE  e.salary > 5000;
```

- `JOIN`을 포함한 뷰 → **복합 뷰**
- 복합 뷰에서 DELETE 불가: 어느 테이블에서 행을 삭제해야 할지 Oracle이 판단 불가
- **ORA-01732: data manipulation operation not legal on this view**

---

**[42번] 정답: ②**

`WITH CHECK OPTION`은 INSERT뿐 아니라 **UPDATE도 제한**:
- `department_id`를 30으로 변경하면 WHERE `department_id = 20` 조건 위반
- **ORA-01402** 오류 발생

`WITH CHECK OPTION`의 목적: 뷰의 WHERE 조건 밖으로 행이 "사라지는" 것을 방지.

---

**[43번] 정답: ①**

| 방법 | 결과 |
|------|------|
| A (뷰를 통한 UPDATE, READ ONLY 없음) | **정상**: 단순 뷰, 기반 테이블 직접 수정 |
| B (기반 테이블 직접 UPDATE) | **정상**: 직접 테이블 수정 |
| C (WITH READ ONLY 뷰를 통한 UPDATE) | **ORA-42399 오류**: READ ONLY 뷰 DML 차단 |

→ **정답: A·B 정상, C 오류** → 보기 ①

---

**[44번] 정답: ②**

기반 테이블에 `NOT NULL`이고 기본값이 없는 `salary` 열이 있는데 뷰에 포함되지 않음.  
→ 뷰를 통한 INSERT 시 `salary` 값을 제공할 방법이 없으므로:

```
ORA-01400: cannot insert NULL into ("HR"."EMPLOYEES"."SALARY")
```

**INSERT 불가**.

---

**[45번] 정답: ②**

뷰 기반 뷰(Nested View)의 주요 위험:
1. **성능**: 각 뷰마다 쿼리 재실행 → 깊어질수록 실행 계획 복잡
2. **의존성**: 기반 뷰(v1)가 DROP되면 상위 뷰(v2)가 **INVALID** 상태
3. `WITH CHECK OPTION`: 중첩 뷰에서도 사용 가능

Oracle은 깊이 제한은 없지만, 과도한 중첩은 피하는 것이 권장됨.

---

**[46번] 정답: ②**

```sql
-- salary > 10000인 행만 보이는 뷰
UPDATE emp_sal_vu SET salary = 8000 WHERE employee_id = 100;
-- UPDATE 성공 (WITH CHECK OPTION 없으므로 오류 없음)

SELECT * FROM emp_sal_vu WHERE employee_id = 100;
-- salary = 8000 이므로 salary > 10000 조건 불만족
-- → 해당 행이 뷰에서 보이지 않음 (Empty)
```

이것이 `WITH CHECK OPTION` 없는 뷰의 "사라지는 행" 현상.  
기반 테이블에는 salary = 8000으로 정상 저장됨.

---

**[47번] 정답: ①**

흐름 분석:
1. `dept50_vu`는 `employees WHERE department_id = 50` 기반의 단순 뷰
2. 뷰를 통한 INSERT → **기반 테이블(`employees`)에 데이터 삽입**됨
3. `COMMIT` → 영구 저장
4. `DROP VIEW dept50_vu` → 뷰 정의만 삭제, **기반 테이블 데이터는 유지**

따라서 `employees` 테이블에 employee_id = 300 행이 **존재**.

---

**[48번] 정답: ③**

FORCE 옵션으로 생성된 뷰:
- 기반 테이블 없는 동안: **INVALID 상태**, 조회 시 경고 포함 오류
- 기반 테이블 생성 후: **자동으로 VALID로 전환되지 않음** — `ALTER VIEW 뷰명 COMPILE;` 또는 DDL 재실행으로 재컴파일 필요 (일부 버전에서는 최초 접근 시 자동 재컴파일)

실무적으로: 기반 테이블 생성 후 `ALTER VIEW ... COMPILE;`을 명시적으로 실행하는 것이 안전.

---

**[49번] 정답: ②**

```sql
CREATE VIEW emp_complex_vu AS
SELECT department_id,
       MAX(salary) max_sal, MIN(salary) min_sal, COUNT(*) emp_cnt
FROM   employees
GROUP BY department_id;
```

제한 요소: **집계 함수 (MAX, MIN, COUNT) + GROUP BY** → DML 전체(INSERT/UPDATE/DELETE) 불가.  
**SELECT만 가능**.

---

**[50번] 정답: ①**

```sql
CREATE VIEW v2 AS
SELECT * FROM v1        -- v1: department_id = 50
WHERE  salary > 3000
WITH CHECK OPTION;
```

v2의 `WITH CHECK OPTION`은 **v2의 WHERE 조건만** 검사:
- v2의 조건: `salary > 3000`
- salary = 2000 → `salary > 3000` 위반 → **ORA-01402 오류**

참고: `WITH CHECK OPTION`은 직접 정의된 WHERE 절만 검사.  
v1의 `department_id = 50` 조건은 v2의 CHECK OPTION 범위 밖 (v1에 CHECK OPTION이 없으므로).  
하지만 v2 자체 조건에서 salary 위반으로 오류 발생.
