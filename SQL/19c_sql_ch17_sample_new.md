# Oracle Database 19c: SQL Workshop
## Chapter 17 — 서브쿼리를 이용한 데이터 조작 | SQL 실습 문제

---

## 실습 준비

아래 실습 테이블을 먼저 생성한 뒤 문제를 풀어주세요.

```sql
-- 실습용 테이블 생성
CREATE TABLE empl7 AS SELECT * FROM employees;
CREATE TABLE dept7 AS SELECT * FROM departments;

-- 이력 테이블 (job_history 기반)
CREATE TABLE empl7_history AS SELECT * FROM job_history;

-- 지역 실습 테이블
CREATE TABLE loc7 AS SELECT * FROM locations;
```

---

## Group 1: INSERT INTO (서브쿼리) & INSERT INTO ... SELECT

**[1번]** `loc7` 테이블에서 유럽(Europe) 지역 위치들을 조인한 인라인 뷰에 새 행을 삽입하시오.

```sql
-- 삽입할 값: location_id=3300, city='Cardiff', country_id='UK'
-- 인라인 뷰: loc7, countries, regions를 조인하여 region_name='Europe' 필터링
```

삽입 후 `SELECT * FROM loc7 WHERE location_id = 3300;`으로 확인하시오.

---

**[2번]** [1번]에서 작성한 `INSERT INTO (서브쿼리)`에 `WITH CHECK OPTION`을 추가하고, 조건을 **위반하는** 값(예: `location_id=9999, city='Sydney', country_id='AU'`)을 삽입하여 오류가 발생하는지 확인하시오.

오류 메시지를 기록하고, 위반 이유를 설명하시오.

---

**[3번]** `empl7_history` 테이블에 직원 100번, 101번, 176번의 현재 정보를 이력으로 추가하시오.

```sql
INSERT INTO empl7_history (employee_id, start_date, end_date, job_id, department_id)
-- employees 테이블에서 SELECT로 가져오되:
-- start_date = hire_date, end_date = SYSDATE
```

삽입 후 `SELECT * FROM empl7_history WHERE employee_id IN (100, 101, 176);`으로 확인.

---

**[4번]** 부서 80번 직원 중 급여가 10,000 이상인 직원만 별도 테이블 `sales_top_new`에 복사하시오.

```sql
CREATE TABLE sales_top_new AS SELECT * FROM empl7 WHERE 1=0;  -- 구조만 복사

-- INSERT INTO ... SELECT로 조건에 맞는 데이터 삽입
```

복사 후 몇 건이 삽입되었는지 COUNT로 확인하시오.

---

**[5번]** 다음 조건으로 `dept7_stats_new`라는 테이블을 만들고 데이터를 삽입하시오.

| 컬럼 | 내용 |
|------|------|
| department_id | 부서 ID |
| department_name | 부서명 |
| emp_count | 직원 수 |
| avg_salary | 부서 평균 급여 |

```sql
CREATE TABLE dept7_stats_new (
    department_id   NUMBER(4),
    department_name VARCHAR2(30),
    emp_count       NUMBER,
    avg_salary      NUMBER(10, 2)
);

-- INSERT INTO ... SELECT로 부서별 통계 삽입
```

---

## Group 2: WITH CHECK OPTION (DML)

**[6번]** `loc7` 테이블에서 `country_id = 'US'`인 행만 대상으로 하는 인라인 뷰에 `WITH CHECK OPTION`을 적용하여 올바른 데이터(country_id='US')를 삽입하시오.

```sql
-- 삽입 값: location_id=9100, city='Dallas', country_id='US'
```

---

**[7번]** [6번]과 동일한 인라인 뷰에 `WITH CHECK OPTION`을 유지하면서 조건 위반 값(country_id='CA')을 삽입하시오. 오류 코드와 메시지를 확인하고 기록하시오.

---

**[8번]** `empl7` 테이블에서 부서 80번 직원만 대상으로 하는 인라인 뷰에 `WITH CHECK OPTION`을 적용하여 급여를 갱신(UPDATE)하되, 조건 위반이 발생하는 상황을 만들어 보시오.

```sql
-- department_id = 80인 직원의 인라인 뷰
UPDATE (
    SELECT employee_id, salary, department_id
    FROM   empl7
    WHERE  department_id = 80
    WITH CHECK OPTION
)
SET department_id = 90    -- 조건(department_id=80) 위반!
WHERE employee_id = 145;
```

오류 메시지를 확인하시오.

---

**[9번]** `WITH CHECK OPTION`을 사용하여 유럽(Europe) 지역 국가의 `loc7` 행만 수정할 수 있는 인라인 뷰를 작성하고, 해당 뷰로 `city = 'London Updated'`로 갱신하시오.

```sql
UPDATE (
    SELECT l.location_id, l.city, l.country_id
    FROM   loc7 l
    JOIN   countries c ON (l.country_id = c.country_id)
    JOIN   regions        USING (region_id)
    WHERE  region_name = 'Europe'
    WITH CHECK OPTION
)
SET    city = 'London Updated'
WHERE  city = 'London';
```

갱신 후 결과를 `SELECT`로 확인하시오.

---

**[10번]** 다음 두 INSERT를 비교하고 각 결과를 설명하시오.

```sql
-- A: WITH CHECK OPTION 없음
INSERT INTO (SELECT location_id, city, country_id FROM loc7 WHERE country_id = 'UK')
VALUES (8001, 'Glasgow', 'UK');

-- B: WITH CHECK OPTION 있음
INSERT INTO (SELECT location_id, city, country_id FROM loc7 WHERE country_id = 'UK' WITH CHECK OPTION)
VALUES (8002, 'Glasgow', 'UK');
```

두 INSERT 모두 실행 후 `SELECT * FROM loc7 WHERE location_id IN (8001, 8002);`로 결과를 확인하시오.

---

## Group 3: 상관 UPDATE

**[11번]** `empl7` 테이블에 `dept_name` 컬럼을 추가하고, 상관 서브쿼리로 각 직원의 부서명을 채우시오.

```sql
ALTER TABLE empl7 ADD dept_name VARCHAR2(30);

UPDATE empl7 e
SET    dept_name = (
    -- departments 테이블에서 e.department_id와 일치하는 department_name 조회
);
```

갱신 후 `SELECT employee_id, last_name, department_id, dept_name FROM empl7 WHERE ROWNUM <= 10;`으로 확인.

---

**[12번]** 상관 UPDATE를 사용하여 `empl7`에서 각 직원의 급여를 소속 부서 평균 급여로 갱신하시오.

```sql
UPDATE empl7 e
SET    salary = (
    -- 각 직원의 부서 평균 급여를 서브쿼리로 계산
);
```

갱신 전후 몇 개의 행이 변경되었는지 확인하시오.

---

**[13번]** 부서 80번 직원의 급여를 해당 직업(job_id) 최고 급여의 90%로 갱신하시오 (상관 UPDATE 사용).

```sql
UPDATE empl7 e
SET    salary = (
    -- JOBS 테이블의 max_salary * 0.9
    -- 또는 empl7에서 같은 job_id 최고 급여 * 0.9
)
WHERE department_id = 80;
```

---

**[14번]** `empl7` 테이블에 `mgr_salary` 컬럼을 추가하고, 각 직원의 직속 상사 급여를 채우시오.  
최상위 관리자(manager_id IS NULL)의 경우 `mgr_salary`는 NULL이어야 합니다.

```sql
ALTER TABLE empl7 ADD mgr_salary NUMBER(8, 2);

UPDATE empl7 e
SET    mgr_salary = (
    -- manager_id로 상사의 salary를 empl7에서 조회
);
```

---

**[15번]** 상관 UPDATE를 WITH 절과 함께 사용하여 성능을 개선하시오.  
각 직원의 급여를 소속 부서 최고 급여로 갱신하되, 부서별 MAX 계산을 한 번만 수행하는 방식으로 작성하시오.

```sql
-- 방법: 인라인 뷰(FROM 절 집계 서브쿼리)와 UPDATE를 결합
UPDATE (
    SELECT e.salary, mx.max_sal
    FROM   empl7 e
    JOIN   (SELECT department_id, MAX(salary) max_sal
            FROM   empl7 GROUP BY department_id) mx
    ON     (e.department_id = mx.department_id)
)
SET salary = max_sal;
```

---

## Group 4: 상관 DELETE

**[16번]** 상관 서브쿼리를 사용하여 `empl7_history`에도 기록이 있는 직원을 `empl7`에서 삭제하시오 (`EXISTS` 사용).

```sql
DELETE FROM empl7 e
WHERE EXISTS (
    -- empl7_history에 e.employee_id와 일치하는 행이 있는지 확인
);
```

삭제 건수를 확인한 후 **ROLLBACK** 하시오.

---

**[17번]** 상관 서브쿼리를 사용하여 `empl7`에서 직업 이력(empl7_history)이 없는 직원을 삭제하시오 (`NOT EXISTS` 사용).

삭제 전 삭제될 직원 수를 `SELECT COUNT(*)`로 먼저 확인한 다음 DELETE를 실행하고 **ROLLBACK** 하시오.

---

**[18번]** `dept7` 테이블에서 직원이 없는 부서를 상관 DELETE로 삭제하시오.

```sql
DELETE FROM dept7 d
WHERE NOT EXISTS (
    -- empl7에서 d.department_id와 일치하는 행이 있는지 확인
);
```

삭제 건수를 확인한 후 **ROLLBACK** 하시오.

---

**[19번]** 다음 두 방식을 모두 작성하고 실행 계획(EXPLAIN PLAN) 차이를 비교하시오.

```sql
-- 방식 A: NOT IN
DELETE FROM dept7 d
WHERE department_id NOT IN (
    SELECT DISTINCT department_id FROM empl7 WHERE department_id IS NOT NULL
);

ROLLBACK;

-- 방식 B: NOT EXISTS
DELETE FROM dept7 d
WHERE NOT EXISTS (
    SELECT NULL FROM empl7 e WHERE e.department_id = d.department_id
);

ROLLBACK;
```

두 방식의 삭제 건수가 동일한지 확인하시오.

---

**[20번]** `empl7`에서 동일한 `job_id`를 가진 직원 중 급여가 해당 직업 평균보다 낮은 직원을 삭제하시오 (상관 DELETE 사용).

```sql
DELETE FROM empl7 e
WHERE salary < (
    -- e.job_id 기준 평균 급여를 empl7에서 계산
);
```

삭제 전 몇 건이 삭제되는지 확인한 후 ROLLBACK 하시오.

---

## Group 5: 종합 DML 실습

**[21번]** 다음 시나리오를 순서대로 실행하시오.

1. `empl7_archive_new` 테이블을 `empl7`과 동일한 구조로 생성 (데이터 없음)
2. 급여가 12,000 이상인 직원을 `empl7_archive_new`에 복사
3. `empl7`에서 복사된 직원의 급여를 10% 인상
4. 결과 확인 후 COMMIT

---

**[22번]** SAVEPOINT를 활용한 단계별 DML 실습을 수행하시오.

```sql
SAVEPOINT start_point;

-- 1단계: 부서 90번 직원 급여 5% 인상
UPDATE empl7 SET salary = salary * 1.05 WHERE department_id = 90;

SAVEPOINT after_update;

-- 2단계: 직원이 없는 부서 삭제
DELETE FROM dept7 d WHERE NOT EXISTS (SELECT NULL FROM empl7 e WHERE e.department_id = d.department_id);

-- 3단계: 2단계(DELETE)만 취소
ROLLBACK TO after_update;

-- 4단계: 최종 확인
SELECT COUNT(*) FROM dept7;   -- 원래 부서 수와 동일해야 함
SELECT salary FROM empl7 WHERE department_id = 90 AND employee_id = 100;  -- 5% 인상 유지
```

---

**[23번]** 다음 비즈니스 요구사항을 단일 UPDATE로 구현하시오.

**요구사항:** 부서별 평균 급여보다 30% 이상 낮은 급여를 받는 직원의 급여를 부서 평균 급여의 90%로 조정하시오.

```sql
UPDATE empl7 e
SET    salary = (서브쿼리: 부서 평균 * 0.9)
WHERE  salary < (서브쿼리: 부서 평균 * 0.7);
```

갱신 건수를 확인하시오.

---

**[24번]** 다음 요구사항을 순서대로 구현하시오.

1. `empl7`에 `team_leader_new` 컬럼(VARCHAR2(25)) 추가
2. 상관 UPDATE로 각 직원이 속한 부서에서 가장 급여가 높은 직원의 `last_name`을 `team_leader_new`에 채우기
3. 자신이 팀 리더인 직원의 경우에도 동일하게 적용되는지 확인

```sql
ALTER TABLE empl7 ADD team_leader_new VARCHAR2(25);

UPDATE empl7 e
SET    team_leader_new = (
    SELECT last_name FROM empl7
    WHERE  department_id = e.department_id
    AND    salary = (SELECT MAX(salary) FROM empl7 WHERE department_id = e.department_id)
    AND    ROWNUM = 1
);
```

---

**[25번]** 아래 조건을 모두 포함하는 종합 DML 시나리오를 작성하고 실행하시오.

1. `INSERT INTO ... SELECT`: 급여 15,000 이상 직원 → `empl7_vip_new` 테이블에 복사
2. `상관 UPDATE`: `empl7_vip_new`의 `dept_name` 컬럼에 부서명 채우기
3. `상관 DELETE`: 직무 이력(empl7_history)이 없는 직원을 `empl7_vip_new`에서 삭제
4. 최종 `empl7_vip_new` 내용 출력 후 COMMIT

```sql
-- Step 1
CREATE TABLE empl7_vip_new AS SELECT *, NULL dept_name_x FROM empl7 WHERE 1=0;
-- (dept_name_x는 실습용 임시 컬럼)

-- Step 2, 3, 4는 직접 작성
```

---

**[26번]** 정리 작업: 실습에서 생성한 모든 테이블을 삭제하시오.

```sql
DROP TABLE empl7 PURGE;
DROP TABLE dept7 PURGE;
DROP TABLE empl7_history PURGE;
DROP TABLE loc7 PURGE;
DROP TABLE sales_top_new PURGE;
DROP TABLE dept7_stats_new PURGE;
DROP TABLE empl7_archive_new PURGE;
DROP TABLE empl7_vip_new PURGE;
```

삭제 후 `SELECT table_name FROM user_tables WHERE table_name LIKE 'EMPL7%' OR table_name LIKE 'DEPT7%';`로 정리 완료를 확인하시오.

---
