# Oracle Database 19c: SQL Workshop
## Chapter 10 — DML 문을 사용한 테이블 관리 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② DML — 데이터 조작 언어 | Data Manipulation Language |
| 2 | ③ INSERT | 새 행 추가 |
| 3 | ② UPDATE | 기존 행 수정 |
| 4 | ④ DELETE | 기존 행 제거 |
| 5 | ② 한 번에 한 행 | VALUES 절로는 1행씩 삽입 |
| 6 | ② 작은따옴표(') | 문자, 날짜 값은 작은따옴표 |
| 7 | ② VALUES 절에 NULL 키워드를 지정한다 | 암묵적=열 생략, 명시적=NULL 키워드 |
| 8 | ② CURRENT_DATE | Oracle에서 현재 날짜/시간 |
| 9 | ③ 테이블의 모든 행이 수정 | WHERE 없으면 전체 수정 |
| 10 | ③ 테이블의 모든 행이 삭제 | WHERE 없으면 전체 삭제 |
| 11 | ② DDL 문이므로 ROLLBACK으로 되돌릴 수 없다 | TRUNCATE=DDL, 자동 커밋 |
| 12 | ② 보류 중인 모든 데이터 변경을 영구적으로 반영한다 | COMMIT = 영구 저장 |
| 13 | ② 보류 중인 모든 데이터 변경을 취소한다 | ROLLBACK = 변경 취소 |
| 14 | ② 현재 트랜잭션에 마커를 생성하여 특정 시점으로 롤백 가능하게 한다 | SAVEPOINT |
| 15 | ② 첫 번째 DML 문이 실행될 때 | 트랜잭션 시작 시점 |
| 16 | ② DDL 문이 실행될 때 | DDL, DCL → 자동 커밋 |
| 17 | ② 선택된 행을 잠금 처리한다 | FOR UPDATE = 행 잠금 |
| 18 | ② 데이터의 일관된 뷰를 보장한다 | 읽기 일관성 = 일관된 뷰 |
| 19 | ② VALUES 절을 사용하지 않는다 | 서브쿼리 INSERT는 VALUES 없음 |
| 20 | ② 지정한 SAVEPOINT 이후의 변경만 취소한다 | TO SAVEPOINT = 이후 취소 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

DEPARTMENTS 테이블은 4개 열(department_id, department_name, manager_id, location_id)을 가지는데 VALUES에 2개 값만 제공했다. 열 목록을 생략하면 모든 열의 값을 제공해야 한다.

**해결:** 열 목록을 명시하거나 모든 값을 제공한다:
```sql
INSERT INTO departments (department_id, department_name)
VALUES (280, 'HR Team');
-- 또는
INSERT INTO departments VALUES (280, 'HR Team', NULL, NULL);
```

---

**[22번] 정답: ②**

`&` 기호는 SQL Developer나 SQL*Plus에서 치환 변수(substitution variable)로 사용된다. SQL 실행 시 사용자에게 값 입력을 요청하는 자리 표시자(placeholder) 역할을 한다.

---

**[23번] 정답: ③**

WHERE 절이 없는 UPDATE 문은 테이블의 **모든 행**에 적용된다. 따라서 EMPLOYEES 테이블의 모든 사원 급여가 10% 인상된다.

---

**[24번] 정답: ① 사원 103의 직무와 급여를 사원 205의 값으로 변경**

`SET (job_id, salary) = (서브쿼리)` 형식으로 여러 열을 동시에 업데이트할 수 있다. WHERE employee_id = 103이므로 사원 103의 값이 사원 205의 값으로 변경된다.

---

**[25번] 정답: ②**

WHERE 절이 `department_name = 'Sales'` (등호)이므로 정확히 이름이 'Sales'인 행만 삭제된다. LIKE '%Sales%'와는 다르다.

---

**[26번] 정답: ②**

TRUNCATE는 DDL 문이므로 자동 커밋이 발생하여 ROLLBACK으로 되돌릴 수 없다. DELETE는 DML 문이므로 ROLLBACK 가능하다.

---

**[27번] 정답: ②**

- `INSERT (300, 'Test1')` → 완료
- `SAVEPOINT sp1` → 마커 설정
- `INSERT (310, 'Test2')` → 완료
- `ROLLBACK TO sp1` → sp1 이후 변경(두 번째 INSERT) 취소

따라서 부서 300('Test1')만 남고 부서 310은 취소된다. (아직 COMMIT은 안 됨)

---

**[28번] 정답: ③**

자동 롤백은 SQL Developer 또는 SQL*Plus의 비정상 종료 시, 또는 시스템 충돌 시 발생한다.

---

**[29번] 정답: ③**

COMMIT 후에는 변경 사항이 데이터베이스에 영구 저장되며, 모든 세션(다른 사용자 포함)에서 변경된 데이터를 볼 수 있다.

---

**[30번] 정답: ②**

`SELECT ... FOR UPDATE`는 조회된 행에 잠금을 설정한다. 다른 세션에서 해당 행을 수정하려 하면 잠금이 해제될 때까지 대기한다. COMMIT 또는 ROLLBACK 시 잠금이 해제된다.

---

**[31번] 정답: ②**

서브쿼리를 사용한 INSERT 구문: `INSERT INTO table SELECT ... FROM ...`  
VALUES 절을 사용하지 않는다.

---

**[32번] 정답: ②**

ROLLBACK으로 DELETE가 취소되므로 copy_emp 테이블은 원래 상태로 복원된다. 이후 SELECT COUNT(*)는 원래 행 수를 반환한다.

---

**[33번] 정답: ①**

COMMIT 실행 시 모든 SAVEPOINT가 제거된다. 이후 ROLLBACK TO SAVEPOINT는 사용할 수 없다.

---

**[34번] 정답: ③ `SET column = NULL`**

열 값을 NULL로 설정하려면 `SET column = NULL`을 사용한다.  
`''`(빈 문자열)은 Oracle에서 NULL과 동일하게 처리되지만, 명시적으로 `NULL` 키워드를 사용하는 것이 권장된다.

---

**[35번] 정답: ②**

COMMIT 전이라도 **현재 세션**에서는 자신이 변경한 데이터를 SELECT로 조회할 수 있다.  
그러나 다른 세션에서는 COMMIT 전의 변경 내용을 볼 수 없다.

---

**[36번] 정답: ②**

DELETE 문에 서브쿼리를 사용하여 다른 테이블(departments)의 값을 참조해 삭제 조건을 지정할 수 있다. 'Public'이 포함된 부서의 department_id에 속한 employees 행이 삭제된다.

---

**[37번] 정답: ②**

문장 수준 롤백(Statement-Level Rollback): 단일 DML 문 실패 시 Oracle은 묵시적 SAVEPOINT를 구현하여 해당 문장만 롤백한다. 다른 변경 사항은 유지된다.

---

**[38번] 정답: ②**

LOCK TABLE 문은 하나 이상의 테이블을 지정한 잠금 모드(SHARE, EXCLUSIVE 등)로 수동으로 잠그는 데 사용된다. COMMIT 또는 ROLLBACK 시 잠금 해제된다.

---

**[39번] 정답: ③**

열 목록을 생략하면 테이블의 모든 열에 대해 테이블 정의의 기본 열 순서대로 값을 나열해야 한다.

---

**[40번] 정답: ②**

Oracle은 언두(Undo) 세그먼트에 변경 이전의 데이터('old' data)를 보관하여 읽기 일관성을 구현한다. 덕분에 읽기 중에 쓰기가 가능하고(독자는 쓰기를 기다리지 않음), 쓰기 중에도 읽기가 가능하다(쓰기는 읽기를 기다리지 않음).

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

서브쿼리를 사용한 INSERT는 서브쿼리가 반환하는 모든 행을 삽입한다.  
`WHERE job_id LIKE '%REP%'`를 만족하는 사원이 30명이라면 30행이 삽입된다.

---

**[42번] 정답: ② 부서 300, 이름 'Dept A'**

실행 순서 분석:
1. `INSERT (300, 'Dept A')` → 완료
2. `SAVEPOINT a` → 마커
3. `UPDATE → 'Dept B'` → 완료
4. `SAVEPOINT b` → 마커
5. `DELETE (300)` → 완료
6. `ROLLBACK TO a` → SAVEPOINT a 이후(UPDATE, SAVEPOINT b, DELETE) 모두 취소
   → 부서 300이 'Dept A'로 복원
7. `COMMIT` → INSERT(300, 'Dept A') 확정

결과: 부서 300, 이름 'Dept A'가 영구 저장됨.

---

**[43번] 정답: ③**

`FOR UPDATE NOWAIT`: 이미 다른 세션에 의해 잠긴 행이 있으면 즉시 `ORA-00054: resource busy and acquire with NOWAIT specified` 오류를 반환하고 대기하지 않는다.  
(일반 `FOR UPDATE`는 잠금 해제까지 대기)

---

**[44번] 정답: ②**

WHERE 절이 없으므로 모든 사원의 급여가 전체 최대 급여(King의 24,000)로 변경된다.  
의도한 결과라면 문제없지만, 보통 특정 조건(WHERE)을 함께 사용해야 한다. 비가역적 대규모 변경이므로 주의가 필요하다.

---

**[45번] 정답: ②**

COMMIT 후에는 변경 사항이 영구적으로 저장된다. 이후 ROLLBACK을 실행해도 COMMIT된 데이터는 되돌릴 수 없다. (아무 효과 없음)

---

**[46번] 정답: ④ SELECT 문 실행**

트랜잭션을 종료하는 방법:
- COMMIT (명시적 종료, 저장)
- ROLLBACK (명시적 종료, 취소)
- DDL 문 실행 (자동 커밋 → 종료)
- DCL 문 실행 (자동 커밋 → 종료)

SELECT 문은 DQL(데이터 조회 언어)로 트랜잭션을 시작하거나 종료하지 않는다.

---

**[47번] 정답: ②**

Oracle의 읽기 일관성(Read Consistency) 덕분에 User B는 User A가 COMMIT하기 전까지 **변경 이전의 데이터**를 본다. Oracle은 언두(Undo) 세그먼트를 통해 이전 이미지(before image)를 User B에게 제공한다.

행이 잠겨 있어도 **읽기**(SELECT)는 블로킹되지 않는다.

---

**[48번] 정답: ③**

DEPARTMENTS 테이블의 department_id는 기본 키(Primary Key)이다. department_id = 10은 이미 존재하는 부서이므로 PK 중복 위반(ORA-00001)이 발생한다.

```
ORA-00001: unique constraint (HR.DEPT_ID_PK) violated
```

---

**[49번] 정답: ②**

Oracle의 문장 수준 롤백(Statement-Level Rollback):
- 단일 DML 문 실패 시 **해당 문장만** 자동으로 롤백됨
- Oracle이 묵시적 SAVEPOINT를 설정하기 때문
- 트랜잭션의 다른 변경 사항은 유지됨
- 사용자는 COMMIT 또는 ROLLBACK으로 트랜잭션을 명시적으로 종료해야 함

---

**[50번] 정답: ② `SELECT AVG(salary) FROM employees WHERE department_id = 50`**

```sql
UPDATE employees
SET    salary = (SELECT AVG(salary)
                 FROM   employees
                 WHERE  department_id = 50)
WHERE  department_id = 50;
```

- 서브쿼리가 부서 50의 평균 급여를 계산하여 단일 값을 반환
- WHERE department_id = 50으로 부서 50 사원만 업데이트

> **주의:** Oracle에서는 동일 테이블을 UPDATE와 서브쿼리에서 동시에 참조할 때 제약이 있을 수 있다.  
> 정확한 평균을 보장하려면 인라인 뷰나 WITH 절을 활용하는 것이 안전하다.
