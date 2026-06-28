# Oracle Database 19c: SQL Workshop
## Chapter 17 — 서브쿼리를 이용한 데이터 조작 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ④ | 열 데이터 타입 변경은 DDL(ALTER TABLE) — 서브쿼리 목적이 아님 |
| 2 | ③ | `INSERT INTO (subquery)` — 서브쿼리가 INTO 절에 위치 |
| 3 | ② | WITH CHECK OPTION: 서브쿼리 조건 위반 DML 차단 |
| 4 | ② | ORA-01402: view WITH CHECK OPTION where-clause violation |
| 5 | ③ | 상관 UPDATE SET 절 서브쿼리 = 스칼라 서브쿼리 (1행 1열) |
| 6 | ② | EXISTS: NULL 포함 시에도 안전하게 처리 |
| 7 | ② | VALUES 절과 SELECT 절은 동시에 사용 불가 |
| 8 | ② | 스칼라 서브쿼리 0건 반환 → NULL |
| 9 | ② | WITH CHECK OPTION 없으면 조건 위반 데이터도 삽입 가능 |
| 10 | ② | `e.department_id` — 외부 쿼리 별칭으로 departments와 연결 |
| 11 | ③ | 복수 행 가능성 시 `IN` 또는 `EXISTS` 사용 |
| 12 | ② | WITH CHECK OPTION은 CREATE VIEW와 INSERT INTO (subquery) 모두에서 사용 가능 |
| 13 | ① | country_id='UK' 조건 만족 → 삽입 성공 |
| 14 | ② | 'US'는 'UK' 조건 위반 → ORA-01402 |
| 15 | ④ | 복사 후 자동 동기화 없음 — 독립된 별도 테이블 |
| 16 | ② | 외부 행 → 서브쿼리 실행 → 갱신 → 반복 |
| 17 | ② | 올바른 상관 DELETE 구문 (외부 별칭 e 참조) |
| 18 | ③ | `INSERT INTO ... SELECT`: 여러 행 / `INSERT INTO (subquery) VALUES`: 단일 VALUES |
| 19 | ② | NOT EXISTS: 서브쿼리에 해당 행이 없을 때 삭제 |
| 20 | ③ | COMMIT: 변경 내용 확정 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ①**

Belgium(`BE`)은 Europe 지역 국가이므로 서브쿼리의 `region_name = 'Europe'` 조건을 만족.  
`WITH CHECK OPTION` 조건을 위반하지 않으므로 삽입 성공.

---

**[22번] 정답: ③**

SET 절의 서브쿼리(스칼라 서브쿼리)는 1행 1열만 반환해야 함.  
2행 이상 반환 → `ORA-01427: single-row subquery returns more than one row` 오류.

---

**[23번] 정답: ②**

```sql
SET salary = (SELECT MAX(salary) * 1.1 FROM employees WHERE department_id = e.department_id)
```

각 직원(e)의 소속 부서에서 최고 급여(MAX)를 구하고 1.1을 곱한 값으로 salary를 갱신.  
→ **각 직원 급여를 소속 부서 최고 급여의 110%로 갱신**.

---

**[24번] 정답: ②**

- **구문 A**: `WHERE employee_id = (서브쿼리)` — 서브쿼리가 2건 이상 반환 시 **ORA-01427 오류**
- **구문 B**: `WHERE EXISTS (...)` — EXISTS는 행 존재 여부만 확인, 복수 행 반환해도 정상 작동

`employee_history`에 같은 `employee_id`가 여러 건 있으면 B가 안전.

---

**[25번] 정답: ②**

```sql
UPDATE (...WHERE country_id = 'UK' WITH CHECK OPTION)
SET city = 'Birmingham' WHERE location_id = 2400;
```

`WITH CHECK OPTION`: country_id가 'UK'가 아닌 방향으로의 변경 차단.  
`location_id=2400`의 country_id가 이미 'UK'이면 변경 허용.  
city를 변경해도 WHERE 조건(country_id='UK')이 여전히 만족되므로 정상 실행.

---

**[26번] 정답: ③**

```sql
WHERE department_id = 80 AND salary > (SELECT AVG(salary) FROM employees WHERE department_id = 80)
```

`>` 연산자 사용 → 평균 **초과** 직원만 복사 (`>=`이면 이상).

---

**[27번] 정답: ③**

WITH 절로 `dept_names` CTE를 정의하고, 상관 서브쿼리로 `empl6.department_name`을 갱신.  
Oracle 19c에서 WITH 절은 DML(UPDATE, DELETE) 문에서도 사용 가능.

---

**[28번] 정답: ②**

```sql
WHERE NOT EXISTS (SELECT NULL FROM employees WHERE department_id = d.department_id)
```

직원이 **없는** 부서 → NOT EXISTS = TRUE → 해당 부서 삭제.

---

**[29번] 정답: ①**

```sql
WHERE department_id = (SELECT department_id FROM departments WHERE department_name = 'Sales')
```

- 비상관 서브쿼리 (외부 쿼리 참조 없음) → 한 번만 실행
- `department_name='Sales'`인 부서의 `department_id`를 구해 해당 직원 급여 5% 인상

---

**[30번] 정답: ②**

```sql
WHERE employee_id NOT IN (SELECT manager_id FROM employees)
```

`manager_id`에 NULL이 포함됨 (최상위 관리자의 manager_id는 NULL).  
`NULL NOT IN (목록 + NULL)` → **UNKNOWN** → 전체 조건 UNKNOWN → **0건 삭제**.

해결: `NOT EXISTS` 또는 `WHERE manager_id IS NOT NULL` 추가.

---

**[31번] 정답: ③**

`INSERT INTO ... SELECT` 또는 CTAS로 복사 시 **제약 조건(PK, FK, CHECK 등)은 복사되지 않음**.  
NOT NULL 제약은 CTAS 방식에서는 일부 복사될 수 있으나, PK/FK는 복사 안 됨.

---

**[32번] 정답: ③**

올바른 순서: `UPDATE` → `SELECT`(미커밋 상태 확인) → `COMMIT` 또는 `ROLLBACK`.  
트랜잭션 내에서 변경 전 SELECT로 현재 세션의 미커밋 데이터를 확인 가능.

---

**[33번] 정답: ①**

- `WITH CHECK OPTION` **없음**: country_id='UK' 조건과 무관하게 삽입 성공
- `WITH CHECK OPTION` **있음**: 'JP'는 'UK' 조건 위반 → ORA-01402 오류

---

**[34번] 정답: ③**

FK 제약 추가는 데이터 무결성 제약이며 UPDATE 성능과 직접 관련 없음 (오히려 부가 검사로 성능 저하 가능).  
성능 향상 방법: ① 인덱스 생성, ② WITH 절(CTE)로 집계 한 번 수행, ③ MERGE 방식 사용.

---

**[35번] 정답: ①**

```sql
SELECT employee_id, hire_date, SYSDATE, job_id, department_id
FROM employees WHERE employee_id IN (100, 101, 102)
```

직원 3명의 현재 정보를 `job_history`에 이력으로 삽입 (여러 행 삽입 가능).

---

**[36번] 정답: ①**

- **A (EXISTS)**: 이직 이력이 **있는** 직원 삭제 → 이직 이력이 **없는** 직원만 남음
- **B (NOT EXISTS)**: 이직 이력이 **없는** 직원 삭제 → 이직 이력이 **있는** 직원만 남음

"이직 이력 없는 직원만 남기려면" → 이직 이력 있는 직원을 삭제 → **A (EXISTS)**

---

**[37번] 정답: ②**

UPDATE의 FROM 절에 인라인 뷰(부서별 AVG 집계)를 사용하여 각 직원의 급여를 **소속 부서 평균 급여의 110%**로 갱신.

---

**[38번] 정답: ②**

DML(INSERT, UPDATE, DELETE)은 **COMMIT 실행 전**까지 ROLLBACK 가능.  
SAVEPOINT는 부분 롤백을 가능하게 하지만, ROLLBACK은 COMMIT 전 언제든 가능.

---

**[39번] 정답: ②**

- 상관 UPDATE: 외부 행마다 서브쿼리 반복 실행 → 대용량에서 비효율
- MERGE 또는 WITH 절 방식: 집계를 한 번만 수행 → 대용량에서 성능 우수

---

**[40번] 정답: ②**

```sql
WHERE department_id NOT IN (SELECT DISTINCT department_id FROM employees WHERE department_id IS NOT NULL)
```

`WHERE department_id IS NOT NULL`을 추가했으므로 NULL 문제 회피.  
→ 직원이 없는 부서(`employees`에 해당 `department_id`가 없는 부서) 삭제.

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

```sql
-- employees.department_id가 NULL인 직원:
-- NOT IN 조건: department_id NOT IN (10, 20, 30, ...)
-- NULL NOT IN (10, 20, ...) → UNKNOWN → 해당 행 제외
-- → department_id가 NULL인 직원은 삭제되지 않음
```

`departments.department_id`에 NULL이 없어도, `employees.department_id`가 NULL인 직원의 비교는 UNKNOWN → 삭제 안 됨.

---

**[42번] 정답: ②**

- **A (상관 UPDATE)**: employees 107행 → 서브쿼리(AVG) 최대 107번 반복
- **B (MERGE)**: `SELECT department_id, AVG(salary)` 를 한 번만 집계 → 훨씬 효율적

대용량에서는 MERGE 방식이 성능 우수.  
트랜잭션 롤백: A, B 모두 가능 (MERGE도 DML이므로 롤백 가능).

---

**[43번] 정답: ②**

```sql
INSERT INTO (... WITH CHECK OPTION)
SELECT 5000 + ROWNUM, city || '_copy', country_id
FROM   locations
WHERE  country_id IN (유럽 국가 코드);
```

- 복사 소스도 유럽 locations (`country_id` 유럽 국가)
- 삽입 대상도 유럽 locations (`WITH CHECK OPTION`)
- 복사본의 `country_id`도 동일한 유럽 국가 → 조건 위반 없음
- → **유럽 지역 locations 행들의 복사본이 삽입됨**

---

**[44번] 정답: ②**

`manager_id`가 NULL인 직원(최상위 관리자):
```sql
SELECT salary FROM employees WHERE employee_id = NULL
-- WHERE employee_id = NULL → 항상 UNKNOWN → 0건 반환
-- 스칼라 서브쿼리 0건 → NULL 반환
```
→ `mgr_salary`가 **NULL로 갱신됨**.

---

**[45번] 정답: ①**

```sql
DELETE FROM departments d WHERE EXISTS (SELECT NULL FROM employees WHERE department_id = d.department_id)
```

직원이 있는 부서를 삭제 시도 → `employees.department_id`가 `departments.department_id`를 FK로 참조하고 있으면:  
→ **ORA-02292: integrity constraint violated - child record found** 오류 발생.

---

**[46번] 정답: ②**

`department_id`가 NULL인 직원에 대해 서브쿼리:
```sql
SELECT department_name FROM departments WHERE department_id = NULL
-- = NULL → UNKNOWN → 0건 반환 → 스칼라 서브쿼리 NULL 반환
```
→ `department_name`이 **NULL로 갱신됨**.  
(④도 같은 의미이나, 문제 선택지에서 ②가 더 명확한 설명)

---

**[47번] 정답: ②**

- **A (IN 방식)**: `job_history.employee_id`의 중복 값도 `IN` 조건에서는 문제없이 처리
- **B (EXISTS 방식)**: 상관 서브쿼리로 행 존재 여부 확인

A에서 `job_history.employee_id`에 NULL이 포함되면 해당 NULL을 가진 직원 비교는 UNKNOWN이 되어 삭제 안 됨 (③).  
→ 실질적 차이: **NULL 처리**. A는 NULL 포함 시 해당 NULL과의 비교가 UNKNOWN, B는 NULL 안전.

---

**[48번] 정답: ①**

`ROLLBACK TO SAVEPOINT before_update`는 해당 SAVEPOINT 이후의 모든 변경을 취소:
- UPDATE (salary × 1.2) → 취소
- DELETE (department_id=99) → 취소
→ **두 DML 모두 취소됨**.

SAVEPOINT 이전의 커밋되지 않은 변경은 아직 유효 → 이후 COMMIT 또는 ROLLBACK 가능.

---

**[49번] 정답: ③**

`INSERT INTO (subquery) VALUES`에서 사용되는 인라인 뷰는 **key-preserved table**이어야 함.  
GROUP BY를 포함하면 집계 결과이므로 key-preserved가 아님 → 삽입 불가 (`ORA-01732` 또는 유사 오류).

---

**[50번] 정답: ①**

단계별 분석:
```
1단계: emp_temp 생성 (데이터 없음, 구조만)
2단계: 부서 80번 직원 삽입 (약 34명)
3단계: 각 직원 급여를 부서 80번 최고 급여의 1.1배로 갱신
       (MAX는 부서 80의 최고 급여, department_id=80이 모두 같으므로 동일 값)
4단계: emp_temp의 평균 급여 미만 행 삭제
       (3단계에서 모두 같은 값으로 갱신되었다면 삭제 없음 또는 부동소수점에 따라 일부 삭제)
COMMIT: 확정
```
→ **emp_temp에 부서 80번 직원 중 최고 급여의 1.1배로 갱신된 후, 팀 평균 미만인 행만 삭제된 결과 존재**.
