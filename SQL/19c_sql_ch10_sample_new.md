# Oracle Database 19c: SQL Workshop
## Chapter 10 — DML 문을 사용한 테이블 관리 | SQL 실습 문제

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources)  
> **실습 테이블:** DEPARTMENTS, EMPLOYEES, COPY_EMP (직접 생성)  
> **범위:** INSERT, UPDATE, DELETE, TRUNCATE, 트랜잭션 제어(COMMIT/ROLLBACK/SAVEPOINT)  
>
> ⚠️ **주의:** 실습 전 `COPY_EMP` 테이블을 아래와 같이 생성한 후 진행하시오:
> ```sql
> CREATE TABLE copy_emp AS SELECT * FROM employees WHERE 1=2;
> -- 또는 데이터 포함:
> CREATE TABLE copy_emp AS SELECT * FROM employees;
> ```
> 각 문제는 독립적으로 실행할 수 있도록 설계되었다.  
> DML 실습 후 반드시 `ROLLBACK`으로 원래 상태를 복원하거나, `COMMIT` 후 데이터를 확인하시오.

---

## Group 1. INSERT 문 (1~6번)

---

**[1번]** DEPARTMENTS 테이블에 다음 새 부서를 삽입하시오.  
(열 목록 명시, 모든 값 제공)

| DEPARTMENT_ID | DEPARTMENT_NAME | MANAGER_ID | LOCATION_ID |
|---------------|-----------------|------------|-------------|
| 280 | Research | 100 | 1700 |

```
1 row created.
```

---

**[2번]** DEPARTMENTS 테이블에 다음 부서를 삽입하시오.  
(manager_id, location_id는 NULL로 — **암묵적 방법** 사용)

| DEPARTMENT_ID | DEPARTMENT_NAME |
|---------------|-----------------|
| 290 | Corporate Tax |

```
1 row created.
```

---

**[3번]** DEPARTMENTS 테이블에 다음 부서를 삽입하시오.  
(NULL 키워드를 명시적으로 사용)

| DEPARTMENT_ID | DEPARTMENT_NAME | MANAGER_ID | LOCATION_ID |
|---------------|-----------------|------------|-------------|
| 300 | Strategy | NULL | NULL |

```
1 row created.
```

---

**[4번]** EMPLOYEES 테이블에 다음 새 사원을 삽입하시오.  
(hire_date는 `CURRENT_DATE` 사용, commission_pct는 NULL)

| 열 | 값 |
|----|-----|
| employee_id | 207 |
| first_name | 'James' |
| last_name | 'Brown' |
| email | 'JBROWN' |
| phone_number | '515.123.9999' |
| hire_date | 현재 날짜 |
| job_id | 'IT_PROG' |
| salary | 7500 |
| commission_pct | NULL |
| manager_id | 103 |
| department_id | 60 |

```
1 row created.
```

---

**[5번]** EMPLOYEES 테이블에 다음 사원을 삽입하시오.  
(hire_date는 `TO_DATE` 함수 사용)

| 열 | 값 |
|----|-----|
| employee_id | 208 |
| first_name | 'Alice' |
| last_name | 'Kim' |
| email | 'AKIM' |
| phone_number | '515.123.8888' |
| hire_date | '15-JAN-2020' |
| job_id | 'SA_REP' |
| salary | 8500 |
| commission_pct | 0.15 |
| manager_id | 145 |
| department_id | 80 |

```
1 row created.
```

---

**[6번]** 서브쿼리를 사용하여 EMPLOYEES 테이블의 SA_REP 직무 사원을 COPY_EMP 테이블에 복사하시오.  
(VALUES 절 없이, job_id LIKE '%REP%' 조건 사용)

```
-- 실행 전 COPY_EMP가 비어있다고 가정
INSERT INTO copy_emp
SELECT * FROM employees WHERE ...;

N rows created.
```

---

## Group 2. UPDATE 문 (7~12번)

---

**[7번]** COPY_EMP 테이블에서 employee_id = 100인 사원의 salary를 25000으로 변경하시오.

```
1 row updated.
```

---

**[8번]** COPY_EMP 테이블에서 department_id가 50인 모든 사원의 salary를 10% 인상하시오.

```
N rows updated.
(부서 50 사원 수만큼)
```

---

**[9번]** COPY_EMP 테이블에서 employee_id = 200인 사원의 job_id와 salary를  
employee_id = 205인 사원의 값으로 동시에 변경하시오.  
(서브쿼리로 두 열 동시 업데이트)

```
1 row updated.
```

---

**[10번]** COPY_EMP 테이블에서 employee_id = 115인 사원의 commission_pct를 NULL로 변경하시오.

```
1 row updated.
```

---

**[11번]** COPY_EMP 테이블에서 job_id가 'IT_PROG'인 사원들의 department_id를  
employee_id = 100인 사원의 department_id와 동일하게 변경하시오.  
(서브쿼리 활용)

```
N rows updated.
(IT_PROG 사원 수만큼)
```

---

**[12번]** COPY_EMP 테이블에서 salary가 전체 평균 급여보다 낮은 모든 사원의 salary를 평균 급여로 업데이트하시오.  
(서브쿼리로 평균 급여 계산)

```
N rows updated.
```

---

## Group 3. DELETE / TRUNCATE 문 (13~18번)

---

**[13번]** COPY_EMP 테이블에서 employee_id = 207인 사원을 삭제하시오.

```
1 row deleted.
```

---

**[14번]** COPY_EMP 테이블에서 department_id가 NULL인 사원을 모두 삭제하시오.

```
1 row deleted.
(Grant 사원 1명)
```

---

**[15번]** 서브쿼리를 사용하여 COPY_EMP 테이블에서  
department_name에 'Public'이 포함된 부서에 속한 사원을 삭제하시오.

```
N rows deleted.
```

---

**[16번]** COPY_EMP 테이블에서 salary가 전체 최대 급여(MAX)보다 낮고  
job_id가 'AD_VP'인 사원을 삭제하시오.  
(서브쿼리 활용)

```
N rows deleted.
```

---

**[17번]** COPY_EMP 테이블의 모든 행을 DELETE 문으로 삭제하시오.  
삭제 후 ROLLBACK하여 복원하시오.

```
107 rows deleted.
-- ROLLBACK 후
Rollback complete.
-- 확인
SELECT COUNT(*) FROM copy_emp;  -- 원래 행 수 반환
```

---

**[18번]** COPY_EMP 테이블의 모든 행을 TRUNCATE 문으로 삭제하시오.  
(ROLLBACK 불가 — 주의)

```
Table truncated.
SELECT COUNT(*) FROM copy_emp;  -- 0 반환
```

---

## Group 4. 트랜잭션 제어 (COMMIT/ROLLBACK/SAVEPOINT) (19~24번)

---

**[19번]** 다음 순서로 트랜잭션을 실행하고 결과를 확인하시오:

1. DEPARTMENTS에 (310, 'Test Dept', NULL, 1700) 삽입
2. SAVEPOINT sp1 생성
3. DEPARTMENTS에 (320, 'Test Dept 2', NULL, 1700) 삽입
4. ROLLBACK TO sp1 실행
5. SELECT로 확인 (부서 310과 320 중 어떤 것이 남는가?)

```
Step 1: 1 row created.
Step 2: Savepoint created.
Step 3: 1 row created.
Step 4: Rollback complete.
Step 5: 
DEPARTMENT_ID  DEPARTMENT_NAME
-------------  ---------------
          310  Test Dept
(부서 320은 취소됨)
```

---

**[20번]** 다음 순서로 트랜잭션을 실행하고 최종 상태를 확인하시오:

1. DEPARTMENTS에 (330, 'Alpha', NULL, 1700) 삽입
2. SAVEPOINT sp_a 생성
3. DEPARTMENTS에 (340, 'Beta', NULL, 1700) 삽입
4. SAVEPOINT sp_b 생성
5. 부서 330의 이름을 'Alpha Updated'로 UPDATE
6. ROLLBACK TO sp_b 실행
7. COMMIT 실행

```
최종 상태:
DEPARTMENT_ID  DEPARTMENT_NAME
330            Alpha
340            Beta
(UPDATE는 sp_b 이후이므로 취소됨, INSERT 330, 340은 커밋됨)
```

---

**[21번]** COMMIT 전과 후의 데이터 가시성을 확인하시오:

1. DEPARTMENTS에 (350, 'Gamma', NULL, 1700) 삽입 (COMMIT 전)
2. 현재 세션에서 SELECT로 부서 350 확인
3. COMMIT 실행
4. COMMIT 후 SELECT로 부서 350 재확인

```
-- COMMIT 전 현재 세션에서:
DEPARTMENT_ID  DEPARTMENT_NAME
350            Gamma     ← 현재 세션에서는 조회 가능

-- COMMIT 후:
DEPARTMENT_ID  DEPARTMENT_NAME
350            Gamma     ← 모든 세션에서 조회 가능
```

---

**[22번]** 다음 트랜잭션을 실행하고 ROLLBACK 후 상태를 확인하시오:

1. COPY_EMP에서 employee_id = 100인 사원의 salary를 99999로 UPDATE
2. DEPARTMENTS에 (360, 'Delta', NULL, 1700) INSERT
3. 두 작업 모두 SELECT로 확인 (변경된 것이 보이는가?)
4. ROLLBACK 실행
5. 다시 SELECT로 확인

```
-- Step 3 (ROLLBACK 전, 현재 세션):
EMPLOYEE_ID  SALARY
100          99999   ← 변경 보임

-- Step 5 (ROLLBACK 후):
EMPLOYEE_ID  SALARY
100          24000   ← 원래 값으로 복원
부서 360도 사라짐
```

---

**[23번]** SAVEPOINT와 ROLLBACK TO SAVEPOINT를 활용한 복합 트랜잭션:

1. COPY_EMP에서 department_id=10 사원 salary를 5000으로 UPDATE
2. `SAVEPOINT after_update` 생성
3. COPY_EMP에서 department_id=10 사원 DELETE
4. SELECT로 확인 (0행이어야 함)
5. `ROLLBACK TO after_update` 실행
6. SELECT로 재확인

```
-- Step 4:
0 rows selected.

-- Step 6:
EMPLOYEE_ID  LAST_NAME  SALARY
200          Whalen     5000    ← UPDATE는 유지, DELETE만 취소됨
```

---

**[24번]** DDL 문 실행 시 자동 커밋 확인:

1. COPY_EMP에서 employee_id=100 사원의 salary를 99999로 UPDATE
2. 확인 쿼리로 변경 확인
3. CREATE TABLE temp_test (id NUMBER) 실행 (DDL → 자동 커밋)
4. ROLLBACK 실행
5. COPY_EMP에서 employee_id=100 salary 재확인

```
-- Step 2: salary = 99999 (변경됨)
-- Step 3: Table created. (DDL → 자동 커밋으로 Step 1의 UPDATE도 커밋됨)
-- Step 4: Rollback complete. (커밋된 데이터는 롤백 불가)
-- Step 5: salary = 99999 (ROLLBACK에도 99999 유지 — DDL이 자동 커밋했음)
```

---

## Group 5. 종합 응용 (25~30번)

---

**[25번]** 다음 요구사항을 순서대로 SQL로 작성하시오:

1. COPY_EMP를 EMPLOYEES 데이터로 재생성 (TRUNCATE 후 INSERT ... SELECT)
2. COPY_EMP에서 salary가 6000 미만인 사원을 모두 삭제
3. 삭제된 행 수를 확인
4. ROLLBACK하여 원래 상태로 복원

```sql
-- Step 1
TRUNCATE TABLE copy_emp;
INSERT INTO copy_emp SELECT * FROM employees;

-- Step 2
DELETE FROM copy_emp WHERE salary < 6000;
-- N rows deleted.

-- Step 3
SELECT COUNT(*) FROM employees WHERE salary < 6000;  -- 삭제된 것과 비교

-- Step 4
ROLLBACK;
```

---

**[26번]** 부서 50에 새 사원을 추가하는 트랜잭션을 작성하시오:

1. COPY_EMP에 다음 사원 INSERT:
   - employee_id: 209, first_name: 'Tom', last_name: 'Lee', email: 'TLEE', phone_number: '515.000.1111', hire_date: TO_DATE('2024-01-15', 'YYYY-MM-DD'), job_id: 'ST_CLERK', salary: 3200, commission_pct: NULL, manager_id: 121, department_id: 50
2. COPY_EMP에서 부서 50의 평균 급여 확인 (새 사원 포함)
3. COMMIT

```
1 row created.

AVG_SALARY
----------
      3398    (기존 평균 + 신규 사원 반영)

Commit complete.
```

---

**[27번]** 급여 조정 트랜잭션:

1. COPY_EMP에서 job_id = 'SA_REP'이면서 salary < 7000인 사원의 salary를 7000으로 일괄 업데이트
2. SAVEPOINT after_sa_update
3. COPY_EMP에서 job_id = 'IT_PROG'이면서 salary < 5000인 사원의 salary를 5000으로 업데이트
4. 두 변경 사항 SELECT로 확인
5. COMMIT

```
-- Step 1: N rows updated.
-- Step 2: Savepoint created.
-- Step 3: M rows updated.
-- Step 5: Commit complete.
```

---

**[28번]** 부서 삭제와 관련 사원 처리:

1. COPY_EMP에서 department_id가 DEPARTMENTS에 존재하지 않는 사원(고아 사원)을 확인:
   ```sql
   SELECT employee_id, department_id FROM copy_emp
   WHERE department_id NOT IN (SELECT department_id FROM departments WHERE department_id IS NOT NULL)
   OR department_id IS NULL;
   ```
2. 위 사원들의 department_id를 NULL로 UPDATE
3. COMMIT

---

**[29번]** 다중 테이블 트랜잭션:

1. DEPARTMENTS에 새 부서 삽입: (370, 'New Division', 100, 1700)
2. SAVEPOINT dept_added
3. COPY_EMP에서 department_id = 60인 모든 사원의 department_id를 370으로 변경
4. COPY_EMP에서 변경된 사원 수 확인
5. ROLLBACK TO dept_added (사원 이동 취소)
6. 부서 370이 남아있는지 확인 (INSERT는 유지)
7. COMMIT

```
-- Step 1: 1 row created.
-- Step 3: N rows updated. (department_id=60 사원 수)
-- Step 5: Rollback complete.
-- Step 6: 부서 370 존재 (SAVEPOINT 이전의 INSERT는 유지)
-- Step 7: Commit complete.
```

---

**[30번]** 종합 DML 실습 — HR 데이터 정비:

다음 요구사항을 하나의 트랜잭션으로 처리하시오:

1. COPY_EMP에서 salary가 전체 평균보다 낮고 manager_id가 NULL인 사원 확인
   ```sql
   SELECT employee_id, salary, manager_id FROM copy_emp
   WHERE salary < (SELECT AVG(salary) FROM copy_emp)
   AND   manager_id IS NULL;
   ```
2. 위 사원들의 salary를 전체 평균 급여로 업데이트
3. SAVEPOINT avg_update_done
4. COPY_EMP에서 commission_pct IS NOT NULL인 사원 수 확인
5. commission_pct가 있는 사원(commission_pct IS NOT NULL)의 salary를 5% 추가 인상
6. 최종 변경 사항 SELECT로 확인
7. COMMIT

```
-- Step 2: N rows updated.
-- Step 3: Savepoint created.
-- Step 5: M rows updated.
-- Step 7: Commit complete.
```
