# Oracle Database 19c: SQL Workshop
## Chapter 10 — DML 문을 사용한 테이블 관리 (Managing Tables Using DML Statements)

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있다:
- 각 데이터 조작 언어(DML) 문을 설명한다
- 트랜잭션을 제어한다

---

## 1. 데이터 조작 언어(DML) 개요

DML(Data Manipulation Language) 문은 다음과 같은 경우에 실행된다:
- 테이블에 새 행을 **추가**할 때
- 테이블의 기존 행을 **수정**할 때
- 테이블에서 기존 행을 **제거**할 때

**트랜잭션(Transaction):** 논리적 작업 단위를 형성하는 DML 문의 집합

| DML 문 | 기능 |
|--------|------|
| `INSERT` | 테이블에 새 행 추가 |
| `UPDATE` | 테이블의 기존 행 수정 |
| `DELETE` | 테이블에서 기존 행 제거 |
| `TRUNCATE` | 테이블의 모든 행 제거 (DDL, 되돌릴 수 없음) |

---

## 2. INSERT 문

### 2-1. 기본 구문

```sql
INSERT INTO table [(column [, column...])]
VALUES      (value [, value...]);
```

- 이 구문으로는 한 번에 **한 행**만 삽입된다

### 2-2. 새 행 삽입

```sql
-- 모든 열에 값을 제공하는 새 행 삽입
INSERT INTO departments(department_id, department_name, manager_id, location_id)
VALUES (70, 'Public Relations', 100, 1700);
```

> - 열 목록을 생략하면 테이블의 기본 열 순서에 따라 값을 나열해야 한다
> - 문자와 날짜 값은 작은따옴표로 묶는다

### 2-3. NULL 값 삽입

**암묵적 방법:** 열 목록에서 해당 열을 생략한다

```sql
INSERT INTO departments (department_id, department_name)
VALUES (30, 'Purchasing');
-- manager_id, location_id는 자동으로 NULL
```

**명시적 방법:** VALUES 목록에 NULL 키워드를 지정한다

```sql
INSERT INTO departments
VALUES (100, 'Finance', NULL, NULL);
```

### 2-4. 특수 값 삽입 (CURRENT_DATE)

```sql
-- CURRENT_DATE: Oracle에서 현재 날짜와 시간을 기록
INSERT INTO employees (employee_id, first_name, last_name, email,
                       phone_number, hire_date, job_id, salary,
                       commission_pct, manager_id, department_id)
VALUES (113, 'Louis', 'Popp', 'LPOPP', '515.124.4567',
        CURRENT_DATE, 'AC_ACCOUNT', 6900, NULL, 205, 110);
```

### 2-5. 특정 날짜/시간 값 삽입 (TO_DATE)

```sql
INSERT INTO employees
VALUES (114, 'Den', 'Raphealy', 'DRAPHEAL', '515.127.4561',
        TO_DATE('FEB 3, 2016', 'MON DD, YYYY'),
        'SA_REP', 11000, 0.2, 100, 70);
```

### 2-6. 스크립트 생성 (&치환 변수)

```sql
-- & 기호: 값 입력을 위한 자리 표시자(placeholder)
INSERT INTO departments (department_id, department_name, location_id)
VALUES (&department_id, '&department_name', &location);
-- 실행 시 사용자에게 값 입력 요청
```

### 2-7. 다른 테이블에서 행 복사 (서브쿼리 INSERT)

```sql
-- VALUES 절 없이 서브쿼리 사용
INSERT INTO sales_reps(id, name, salary, commission_pct)
SELECT employee_id, last_name, salary, commission_pct
FROM   employees
WHERE  job_id LIKE '%REP%';
```

> - `VALUES` 절을 사용하지 않는다
> - INSERT 절의 열 개수와 서브쿼리의 열 개수가 일치해야 한다
> - 서브쿼리가 반환하는 모든 행이 테이블에 삽입된다

---

## 3. UPDATE 문

### 3-1. 기본 구문

```sql
UPDATE table
SET    column = value [, column = value, ...]
[WHERE condition];
```

- `WHERE` 절을 지정하면 특정 행만 수정
- `WHERE` 절을 생략하면 **모든 행이 수정**되므로 주의

### 3-2. 특정 행 수정

```sql
-- WHERE 절 사용: 특정 사원의 부서 변경
UPDATE employees
SET    department_id = 50
WHERE  employee_id = 113;
```

### 3-3. 모든 행 수정

```sql
-- WHERE 절 생략: 모든 행의 department_id를 110으로 변경
UPDATE copy_emp
SET    department_id = 110;
```

### 3-4. NULL 값으로 업데이트

```sql
UPDATE employees
SET    commission_pct = NULL
WHERE  employee_id = 113;
```

### 3-5. 서브쿼리로 여러 열 수정

```sql
-- 사원 103의 직무와 급여를 사원 205의 값으로 변경
UPDATE  employees
SET     (job_id, salary) = (SELECT job_id, salary
                             FROM   employees
                             WHERE  employee_id = 205)
WHERE   employee_id = 103;
```

### 3-6. 다른 테이블 기반 수정

```sql
-- 다른 테이블의 값을 참조하여 업데이트
UPDATE  copy_emp
SET     department_id = (SELECT department_id
                         FROM   employees
                         WHERE  employee_id = 100)
WHERE   job_id = (SELECT job_id
                  FROM   employees
                  WHERE  employee_id = 200);
```

---

## 4. DELETE 문

### 4-1. 기본 구문

```sql
DELETE [FROM] table
[WHERE condition];
```

- `WHERE` 절을 지정하면 특정 행만 삭제
- `WHERE` 절을 생략하면 **모든 행이 삭제**되므로 주의

### 4-2. 특정 행 삭제

```sql
-- WHERE 절 사용: 특정 부서 삭제
DELETE FROM departments
WHERE  department_name = 'Finance';
```

### 4-3. 모든 행 삭제

```sql
-- WHERE 절 생략: 모든 행 삭제
DELETE FROM copy_emp;
```

### 4-4. 다른 테이블 기반 삭제 (서브쿼리)

```sql
-- 'Public'이 포함된 부서명에 속한 사원 삭제
DELETE FROM employees
WHERE  department_id IN (
    SELECT department_id
    FROM   departments
    WHERE  department_name LIKE '%Public%'
);
```

---

## 5. TRUNCATE 문

```sql
TRUNCATE TABLE table_name;

-- 예제
TRUNCATE TABLE copy_emp;
```

**TRUNCATE vs DELETE 비교:**

| 항목 | TRUNCATE | DELETE |
|------|----------|--------|
| 분류 | DDL | DML |
| 되돌리기 | 불가 (자동 커밋) | 가능 (ROLLBACK) |
| WHERE 조건 | 불가 (전체만) | 가능 (특정 행) |
| 속도 | 빠름 | 느림 (행 단위) |
| 트리거 | 실행 안 됨 | 실행됨 |

---

## 6. 트랜잭션 제어

### 6-1. 트랜잭션이란?

**트랜잭션(Database Transaction):** 다음 중 하나로 구성된다:
- 데이터에 일관된 변경을 구성하는 DML 문의 집합
- 하나의 DDL 문
- 하나의 DCL 문

### 6-2. 트랜잭션의 시작과 종료

**시작:** 첫 번째 DML SQL 문이 실행될 때

**종료:** 다음 중 하나가 발생할 때:
- `COMMIT` 또는 `ROLLBACK` 문이 실행됨
- DDL 또는 DCL 문이 실행됨 (자동 커밋)
- 사용자가 SQL Developer 또는 SQL*Plus에서 종료함
- 시스템 충돌

### 6-3. COMMIT과 ROLLBACK의 장점

```
COMMIT과 ROLLBACK 문을 사용하면:
- 데이터 일관성 보장
- 변경 사항을 영구적으로 반영하기 전에 미리 확인 가능
- 논리적으로 관련된 작업을 그룹화 가능
```

### 6-4. 명시적 트랜잭션 제어 문

```
시간 순서:
DELETE  →  SAVEPOINT A  →  INSERT  →  UPDATE  →  SAVEPOINT B  →  INSERT

ROLLBACK TO SAVEPOINT B: SAVEPOINT B 이후 변경 취소
ROLLBACK TO SAVEPOINT A: SAVEPOINT A 이후 변경 취소 (UPDATE, SAVEPOINT B, INSERT 포함)
ROLLBACK: 전체 트랜잭션 취소
COMMIT: 전체 트랜잭션 확정
```

### 6-5. SAVEPOINT 사용

```sql
UPDATE employees SET salary = salary * 1.1 WHERE department_id = 50;
SAVEPOINT update_done;     -- 마커 생성

INSERT INTO departments VALUES (300, 'Test Dept', NULL, 1700);

ROLLBACK TO update_done;   -- SAVEPOINT 이후 변경 취소 (INSERT 취소)
                            -- UPDATE는 유지됨
```

### 6-6. 묵시적 트랜잭션 처리 (Implicit Transaction Processing)

**자동 커밋(Automatic COMMIT)이 발생하는 경우:**
- DDL 문이 실행될 때
- DCL 문이 실행될 때
- SQL Developer 또는 SQL*Plus에서 COMMIT/ROLLBACK 없이 정상 종료할 때

**자동 롤백(Automatic ROLLBACK)이 발생하는 경우:**
- SQL Developer 또는 SQL*Plus의 비정상 종료 시
- 시스템 장애 시

### 6-7. COMMIT 전 데이터 상태

- 이전 상태의 데이터를 복구할 수 있다
- 현재 세션에서는 DML 작업 결과를 SELECT로 확인할 수 있다
- 다른 세션에서는 현재 세션의 DML 결과를 볼 수 없다
- 영향받은 행은 잠금(lock)이 설정되어 다른 세션이 변경할 수 없다

### 6-8. COMMIT 후 데이터 상태

```sql
-- 변경 실행
DELETE FROM employees WHERE employee_id = 113;
INSERT INTO departments VALUES (290, 'Corporate Tax', NULL, 1700);

-- 변경 확정
COMMIT;
```

COMMIT 후:
- 데이터 변경이 데이터베이스에 저장됨
- 이전 데이터 상태를 덮어씀
- 모든 세션에서 결과를 볼 수 있음
- 잠금 해제 → 다른 세션이 수정 가능
- 모든 SAVEPOINT 제거됨

### 6-9. ROLLBACK 후 데이터 상태

```sql
DELETE FROM copy_emp;
ROLLBACK;
-- 삭제가 취소되고 이전 상태로 복원됨
```

ROLLBACK 후:
- 데이터 변경이 취소됨
- 이전 데이터 상태로 복원됨
- 잠금 해제됨

### 6-10. 문장 수준 롤백 (Statement-Level Rollback)

- 단일 DML 문 실행 중 오류 발생 시, **해당 문장만** 롤백된다
- Oracle 서버가 묵시적 SAVEPOINT를 구현한다
- 다른 변경 사항은 유지된다
- 사용자는 COMMIT 또는 ROLLBACK으로 트랜잭션을 명시적으로 종료해야 한다

---

## 7. 읽기 일관성 (Read Consistency)

- 읽기 일관성은 항상 데이터의 일관된 뷰를 보장한다
- 한 사용자의 변경이 다른 사용자의 변경과 충돌하지 않는다
- **독자는 쓰기를 기다리지 않는다**
- **쓰기는 읽기를 기다리지 않는다**
- **쓰기는 쓰기를 기다린다** (동일한 행에 대한 쓰기 충돌)

Oracle은 **언두(Undo) 세그먼트**에 변경 이전의 데이터('old' data)를 보관하여 읽기 일관성을 구현한다.

---

## 8. 수동 데이터 잠금 (Manual Data Locking)

### 8-1. FOR UPDATE 절

SELECT 문에 `FOR UPDATE` 절을 사용하여 행을 잠글 수 있다.

```sql
-- SA_REP 사원의 행을 잠금
SELECT employee_id, salary, commission_pct, job_id
FROM   employees
WHERE  job_id = 'SA_REP'
FOR UPDATE
ORDER BY employee_id;
```

- 잠금은 `ROLLBACK` 또는 `COMMIT` 시에만 해제된다
- 다른 사용자가 잠긴 행을 수정하려 하면 대기한다

```sql
-- 여러 테이블에 FOR UPDATE 적용
SELECT e.employee_id, e.salary, e.commission_pct
FROM   employees e
JOIN   departments d USING (department_id)
WHERE  job_id = 'ST_CLERK'
AND    location_id = 1500
FOR UPDATE
ORDER BY e.employee_id;
-- EMPLOYEES와 DEPARTMENTS 양쪽 행 모두 잠금
```

### 8-2. LOCK TABLE 문

```sql
-- 하나 이상의 테이블을 지정 모드로 잠금
LOCK TABLE table_name
IN [ROW SHARE | ROW EXCLUSIVE | SHARE UPDATE |
    SHARE | SHARE ROW EXCLUSIVE | EXCLUSIVE] MODE
[NOWAIT];
```

- 자동 잠금을 수동으로 재정의할 때 사용
- `COMMIT` 또는 `ROLLBACK` 시 잠금 해제

---

## 9. DML 문 요약

| 문 | 기능 |
|----|------|
| `INSERT` | 테이블에 새 행 추가 |
| `UPDATE` | 테이블의 기존 행 수정 |
| `DELETE` | 테이블에서 기존 행 제거 |
| `TRUNCATE` | 테이블의 모든 행 제거 (DDL, 롤백 불가) |
| `COMMIT` | 보류 중인 모든 변경 사항을 영구 반영 |
| `SAVEPOINT` | ROLLBACK 마커 지점 저장 |
| `ROLLBACK` | 보류 중인 모든 데이터 변경 취소 |
| `SELECT ... FOR UPDATE` | SELECT 쿼리로 식별된 행 잠금 |
