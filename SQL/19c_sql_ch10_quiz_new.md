# Oracle Database 19c: SQL Workshop
## Chapter 10 — DML 문을 사용한 테이블 관리 | 연습문제 (50문제)

> **구성:** 하(기초) 20문제 + 중(응용) 20문제 + 상(심화) 10문제

---

## 하(기초) — 20문제

---

**[1번]** DML의 약자와 의미로 올바른 것은?

① DDL — 데이터 정의 언어  
② DML — 데이터 조작 언어  
③ DCL — 데이터 제어 언어  
④ TCL — 트랜잭션 제어 언어

---

**[2번]** 테이블에 새 행을 추가하는 DML 문은?

① UPDATE  
② DELETE  
③ INSERT  
④ MERGE

---

**[3번]** 테이블의 기존 행을 수정하는 DML 문은?

① INSERT  
② UPDATE  
③ DELETE  
④ TRUNCATE

---

**[4번]** 테이블에서 기존 행을 제거하는 DML 문은?

① INSERT  
② UPDATE  
③ TRUNCATE  
④ DELETE

---

**[5번]** INSERT 문의 기본 구문에서 한 번에 삽입할 수 있는 행의 수는?

① 최대 100행  
② 한 번에 한 행  
③ 테이블의 모든 행  
④ 제한 없음

---

**[6번]** INSERT 문에서 문자 및 날짜 값을 묶을 때 사용하는 기호는?

① 큰따옴표(")  
② 작은따옴표(')  
③ 백틱(`)  
④ 대괄호([])

---

**[7번]** INSERT 문에서 열을 NULL로 설정하는 **명시적(Explicit)** 방법은?

① 열 목록에서 해당 열을 생략한다  
② VALUES 절에 NULL 키워드를 지정한다  
③ VALUES 절에 0을 지정한다  
④ VALUES 절에 빈 문자열('')을 지정한다

---

**[8번]** Oracle에서 현재 날짜와 시간을 INSERT 시 기록하는 함수는?

① SYSDATE만 가능  
② CURRENT_DATE  
③ NOW()  
④ GETDATE()

---

**[9번]** UPDATE 문에서 WHERE 절을 생략하면 어떻게 되는가?

① 오류 발생  
② 첫 번째 행만 수정  
③ 테이블의 모든 행이 수정  
④ 수정되는 행 없음

---

**[10번]** DELETE 문에서 WHERE 절을 생략하면 어떻게 되는가?

① 오류 발생  
② 첫 번째 행만 삭제  
③ 테이블의 모든 행이 삭제  
④ 삭제되는 행 없음

---

**[11번]** TRUNCATE 문에 대한 설명으로 올바른 것은?

① DML 문이므로 ROLLBACK으로 되돌릴 수 있다  
② DDL 문이므로 ROLLBACK으로 되돌릴 수 없다  
③ 특정 행만 선택적으로 삭제할 수 있다  
④ DELETE보다 느리다

---

**[12번]** COMMIT 문의 기능으로 올바른 것은?

① 마지막 변경만 취소한다  
② 보류 중인 모든 데이터 변경을 영구적으로 반영한다  
③ 트랜잭션을 시작한다  
④ 특정 시점으로 되돌아간다

---

**[13번]** ROLLBACK 문의 기능으로 올바른 것은?

① 마지막 INSERT만 취소한다  
② 보류 중인 모든 데이터 변경을 취소한다  
③ 트랜잭션을 시작한다  
④ 데이터를 영구적으로 저장한다

---

**[14번]** SAVEPOINT 문의 역할은?

① 트랜잭션을 종료한다  
② 현재 트랜잭션에 마커를 생성하여 특정 시점으로 롤백 가능하게 한다  
③ 변경 사항을 영구 저장한다  
④ 테이블을 잠근다

---

**[15번]** 트랜잭션이 시작되는 시점은?

① COMMIT 실행 시  
② 첫 번째 DML 문이 실행될 때  
③ 데이터베이스 접속 시  
④ SELECT 문 실행 시

---

**[16번]** 다음 중 자동 커밋(Automatic COMMIT)이 발생하는 경우는?

① 오류가 발생할 때  
② DDL 문이 실행될 때  
③ DML 문이 실행될 때  
④ 사용자가 SAVEPOINT를 생성할 때

---

**[17번]** SELECT ... FOR UPDATE 절의 기능으로 올바른 것은?

① 선택된 행을 삭제한다  
② 선택된 행을 잠금 처리한다  
③ 읽기 전용으로 조회한다  
④ 선택된 행에 트리거를 설정한다

---

**[18번]** 읽기 일관성(Read Consistency)에 대한 설명으로 올바른 것은?

① 독자가 쓰기를 기다려야 한다  
② 데이터의 일관된 뷰를 보장한다  
③ 쓰기가 읽기를 기다려야 한다  
④ 한 번에 한 사용자만 데이터 조회 가능

---

**[19번]** INSERT 문에서 서브쿼리를 사용할 때 VALUES 절은?

① VALUES 절은 필수  
② VALUES 절을 사용하지 않는다  
③ VALUES 절에 서브쿼리를 포함한다  
④ VALUES 절은 선택 사항

---

**[20번]** ROLLBACK TO SAVEPOINT 문의 기능으로 올바른 것은?

① 전체 트랜잭션을 취소한다  
② 지정한 SAVEPOINT 이후의 변경만 취소한다  
③ 지정한 SAVEPOINT 이전의 변경을 취소한다  
④ SAVEPOINT를 삭제한다

---

## 중(응용) — 20문제

---

**[21번]** 다음 INSERT 문에서 오류가 발생하는 이유는?

```sql
INSERT INTO departments VALUES (280, 'HR Team');
```

① 부서 번호 280이 이미 존재함  
② VALUES 절에 모든 열의 값을 제공하지 않음  
③ 부서 이름에 공백이 있음  
④ INSERT INTO 다음에 열 목록이 없음

---

**[22번]** 다음 INSERT 문에서 & 기호의 역할은?

```sql
INSERT INTO departments (department_id, department_name)
VALUES (&dept_id, '&dept_name');
```

① 변수 선언  
② 사용자에게 값 입력을 요청하는 치환 변수  
③ NULL 값을 의미  
④ 오류 발생 원인

---

**[23번]** 다음 SQL의 결과로 올바른 것은?

```sql
UPDATE employees
SET    salary = salary * 1.1;
```

① 특정 조건에 맞는 사원의 급여만 10% 인상  
② 오류 — WHERE 절 없이 UPDATE 불가  
③ 모든 사원의 급여를 10% 인상  
④ 급여가 NULL인 사원만 수정

---

**[24번]** 다음 SQL의 목적으로 올바른 것은?

```sql
UPDATE  employees
SET     (job_id, salary) = (SELECT job_id, salary
                             FROM   employees
                             WHERE  employee_id = 205)
WHERE   employee_id = 103;
```

① 사원 103의 직무와 급여를 사원 205의 값으로 변경  
② 사원 205의 직무와 급여를 사원 103의 값으로 변경  
③ 두 사원의 직무와 급여를 교환  
④ 오류 — UPDATE에서 서브쿼리 사용 불가

---

**[25번]** 다음 SQL의 실행 결과로 올바른 것은?

```sql
DELETE FROM departments
WHERE  department_name = 'Sales';
```

① departments 테이블 전체 삭제  
② 부서 이름이 'Sales'인 행만 삭제  
③ 오류 발생 — Sales 부서가 존재하지 않음  
④ 부서 이름에 'Sales'가 포함된 모든 행 삭제

---

**[26번]** TRUNCATE와 DELETE의 가장 중요한 차이는?

① TRUNCATE는 WHERE 조건 사용 가능  
② TRUNCATE는 DDL이라 ROLLBACK으로 되돌릴 수 없다  
③ DELETE가 항상 더 빠르다  
④ TRUNCATE는 트리거를 실행한다

---

**[27번]** 다음 트랜잭션에서 ROLLBACK 후 남는 데이터는?

```sql
INSERT INTO departments VALUES (300, 'Test1', NULL, 1700);
SAVEPOINT sp1;
INSERT INTO departments VALUES (310, 'Test2', NULL, 1700);
ROLLBACK TO sp1;
```

① 두 INSERT 모두 취소됨 (부서 300, 310 모두 없음)  
② 부서 300만 남고 부서 310은 취소됨  
③ 부서 310만 남고 부서 300은 취소됨  
④ 두 INSERT 모두 커밋됨

---

**[28번]** 다음 중 자동 롤백(Automatic ROLLBACK)이 발생하는 경우는?

① COMMIT 문 실행  
② DDL 문 실행  
③ 시스템 충돌 또는 비정상 종료  
④ SELECT 문 실행

---

**[29번]** COMMIT 후 다른 세션에서 변경된 데이터를 볼 수 있는가?

① COMMIT 후에도 다른 세션에서 볼 수 없음  
② COMMIT 전에만 다른 세션에서 볼 수 있음  
③ COMMIT 후 모든 세션에서 볼 수 있음  
④ 세션 설정에 따라 다름

---

**[30번]** 다음 SQL에서 FOR UPDATE의 역할은?

```sql
SELECT employee_id, salary FROM employees
WHERE  job_id = 'SA_REP'
FOR UPDATE;
```

① 해당 사원의 급여를 즉시 업데이트  
② SA_REP 사원의 행을 잠금 처리 (다른 세션 수정 불가)  
③ 결과를 읽기 전용으로 조회  
④ SA_REP 사원만 현재 세션에서 볼 수 있게 함

---

**[31번]** 다음 중 올바른 서브쿼리 INSERT 구문은?

① `INSERT INTO t1 VALUES (SELECT col FROM t2);`  
② `INSERT INTO t1 SELECT col FROM t2;`  
③ `INSERT INTO t1 VALUES SELECT col FROM t2;`  
④ `INSERT SELECT col FROM t2 INTO t1;`

---

**[32번]** 다음 SQL의 실행 결과로 올바른 것은?

```sql
DELETE FROM copy_emp;
ROLLBACK;
SELECT COUNT(*) FROM copy_emp;
```

① 0행 반환 (삭제가 영구 반영됨)  
② ROLLBACK으로 삭제 취소 → copy_emp의 원래 행 수 반환  
③ 오류 — ROLLBACK 후 SELECT 불가  
④ NULL 반환

---

**[33번]** COMMIT 실행 시 SAVEPOINT는 어떻게 되는가?

① 모든 SAVEPOINT가 제거됨  
② SAVEPOINT는 유지됨  
③ 가장 최근 SAVEPOINT만 제거됨  
④ SAVEPOINT는 영구 저장됨

---

**[34번]** 다음 중 UPDATE 문에서 열 값을 NULL로 설정하는 올바른 방법은?

① `SET column = ''`  
② `SET column = 0`  
③ `SET column = NULL`  
④ `SET column = EMPTY`

---

**[35번]** COMMIT 전에 현재 세션에서 변경한 데이터를 SELECT로 조회할 수 있는가?

① 불가능 — COMMIT 후에만 조회 가능  
② 가능 — 현재 세션에서는 미커밋 변경도 조회됨  
③ 불가능 — LOCK이 설정되어 있음  
④ 가능 — 다른 세션에서도 조회됨

---

**[36번]** 다음 DELETE 문의 특이한 점은?

```sql
DELETE FROM employees
WHERE  department_id IN (
    SELECT department_id FROM departments
    WHERE  department_name LIKE '%Public%'
);
```

① DELETE에 서브쿼리 사용 불가 — 오류  
② 서브쿼리 결과 기반으로 다른 테이블의 값을 참조하여 삭제  
③ departments 테이블의 행이 삭제됨  
④ Public 부서의 부서명만 삭제

---

**[37번]** 문장 수준 롤백(Statement-Level Rollback)에 대한 설명으로 올바른 것은?

① 단일 DML 문 실패 시 전체 트랜잭션이 롤백  
② 단일 DML 문 실패 시 해당 문장만 롤백되고 다른 변경은 유지  
③ 오류 발생 시 자동 커밋  
④ 롤백은 수동으로만 가능

---

**[38번]** 다음 중 LOCK TABLE 문에 대한 설명으로 올바른 것은?

① SELECT 문과 동일한 기능  
② 하나 이상의 테이블을 지정 모드로 수동 잠금  
③ 테이블을 영구적으로 삭제  
④ 테이블을 읽기 전용으로 변경

---

**[39번]** INSERT 문에서 열 목록을 생략하는 경우 값을 나열하는 방식은?

① 알파벳 순서  
② 기본 키 열 먼저  
③ 테이블의 기본 열 순서대로 모든 열의 값을 나열  
④ NULL이 아닌 열만 나열

---

**[40번]** 다음 중 읽기 일관성(Read Consistency)에 대한 올바른 설명은?

① 동시에 한 사용자만 데이터를 읽을 수 있다  
② Oracle은 언두(Undo) 세그먼트로 변경 이전 데이터를 보관한다  
③ 읽기 중에는 쓰기가 불가능하다  
④ COMMIT 후에만 일관된 뷰를 제공한다

---

## 상(심화) — 10문제

---

**[41번]** 다음 INSERT 문이 실행될 때 삽입되는 행 수는?

```sql
INSERT INTO sales_reps(id, name, salary, commission_pct)
SELECT employee_id, last_name, salary, commission_pct
FROM   employees
WHERE  job_id LIKE '%REP%';
```

① 항상 1행  
② 서브쿼리가 반환하는 모든 행 (job_id에 REP가 포함된 사원 수)  
③ 오류 — INSERT에 LIKE 사용 불가  
④ 최대 10행

---

**[42번]** 다음 트랜잭션 시나리오에서 최종 커밋되는 행은?

```sql
INSERT INTO departments VALUES (300, 'Dept A', NULL, 1700);
SAVEPOINT a;
UPDATE departments SET department_name='Dept B' WHERE department_id=300;
SAVEPOINT b;
DELETE FROM departments WHERE department_id=300;
ROLLBACK TO a;
COMMIT;
```

① 행 없음 (ROLLBACK TO a 이후 INSERT도 취소)  
② 부서 300, 이름 'Dept A' (SAVEPOINT a 이전 상태가 커밋됨)  
③ 부서 300, 이름 'Dept B'  
④ 오류 발생

---

**[43번]** FOR UPDATE NOWAIT 옵션의 동작으로 올바른 것은?

① 다른 세션이 잠금을 해제할 때까지 무한정 대기  
② 잠긴 행을 건너뛰고 잠기지 않은 행만 반환  
③ 이미 잠긴 행이 있으면 즉시 오류(ORA-00054)를 반환하고 대기하지 않음  
④ 강제로 잠금을 해제하고 접근

---

**[44번]** 다음 UPDATE 문에서 잠재적인 문제점은?

```sql
UPDATE employees
SET    salary = (SELECT MAX(salary) FROM employees);
```

① 오류 발생 — SET 절에 서브쿼리 사용 불가  
② 모든 사원의 급여가 전체 최대 급여(24000)로 변경됨 (의도치 않을 수 있음)  
③ MAX() 함수는 서브쿼리에 사용 불가  
④ WHERE 절이 없어 오류

---

**[45번]** COMMIT 후 ROLLBACK을 실행하면?

① COMMIT 이전 상태로 복원됨  
② COMMIT 이후에는 ROLLBACK이 아무 효과 없음  
③ 오류 발생  
④ COMMIT된 데이터만 삭제됨

---

**[46번]** 다음 중 트랜잭션을 올바르게 종료하는 방법이 **아닌** 것은?

① COMMIT 실행  
② ROLLBACK 실행  
③ DDL 문 실행 (자동 커밋)  
④ SELECT 문 실행

---

**[47번]** 다음 시나리오에서 User B가 볼 수 있는 데이터는?

```
User A: UPDATE employees SET salary = 9000 WHERE employee_id = 100;
        (아직 COMMIT하지 않음)
User B: SELECT salary FROM employees WHERE employee_id = 100;
```

① User B는 salary = 9000을 봄 (User A의 변경이 반영됨)  
② User B는 User A의 변경 이전 데이터를 봄 (읽기 일관성)  
③ User B는 오류를 받음 (행이 잠겨 있음)  
④ User B는 NULL을 봄

---

**[48번]** 다음 INSERT 문의 실행 결과로 올바른 것은?

```sql
INSERT INTO departments (department_id, department_name)
VALUES (10, 'New Dept');
```

① 새 행이 삽입됨  
② 기존 부서 10의 이름이 변경됨  
③ 오류 — 부서 10이 이미 존재하므로 PK 제약 위반  
④ 기존 행이 삭제되고 새 행이 삽입됨

---

**[49번]** 단일 UPDATE 문이 실행 중 오류가 발생했다. 다른 DML 문으로 변경한 데이터는 어떻게 되는가?

① 전체 트랜잭션이 롤백됨  
② 실패한 UPDATE 문만 롤백되고 다른 변경은 유지됨  
③ 모든 변경이 자동 커밋됨  
④ 데이터베이스 연결이 종료됨

---

**[50번]** 다음 상황에서 올바른 SQL을 작성하시오:

EMPLOYEES 테이블에서 부서 50에 근무하는 모든 사원의 급여를 부서 50의 현재 평균 급여로 업데이트하시오.

```sql
UPDATE employees
SET    salary = (  __A__  )
WHERE  department_id = 50;
```

A에 들어갈 올바른 서브쿼리는?

① `SELECT salary FROM employees WHERE department_id = 50`  
② `SELECT AVG(salary) FROM employees WHERE department_id = 50`  
③ `SELECT MAX(salary) FROM employees WHERE department_id = 50`  
④ `SELECT salary FROM departments WHERE department_id = 50`
