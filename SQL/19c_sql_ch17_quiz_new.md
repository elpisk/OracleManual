# Oracle Database 19c: SQL Workshop
## Chapter 17 — 서브쿼리를 이용한 데이터 조작 | 연습문제 (50문제)

---

## 하(기초) — 20문제

**[1번]** 다음 중 DML 문에서 서브쿼리를 사용하는 목적이 **아닌** 것은?

① 다른 테이블에서 데이터를 복사하여 삽입하기 위해  
② 다른 테이블의 값을 기반으로 행을 갱신하기 위해  
③ 다른 테이블의 존재 여부에 따라 행을 삭제하기 위해  
④ 테이블의 열 데이터 타입을 변경하기 위해

---

**[2번]** `INSERT INTO (subquery) VALUES (...)` 문에서 서브쿼리가 위치하는 절은?

① SELECT 절  
② FROM 절  
③ INTO 절  
④ WHERE 절

---

**[3번]** 다음 중 `WITH CHECK OPTION`의 역할로 올바른 것은?

① 서브쿼리의 결과를 정렬한다  
② 서브쿼리의 조건을 위반하는 DML 작업을 차단한다  
③ INSERT 성능을 향상시킨다  
④ 서브쿼리 결과에 중복 제거를 적용한다

---

**[4번]** `WITH CHECK OPTION` 위반 시 발생하는 Oracle 오류 코드는?

① ORA-00001  
② ORA-01402  
③ ORA-02292  
④ ORA-01427

---

**[5번]** 상관 UPDATE의 SET 절에 사용하는 서브쿼리는 몇 행 몇 열을 반환해야 하는가?

① 다중 행, 1열  
② 1행, 다중 열  
③ 1행, 1열  
④ 다중 행, 다중 열

---

**[6번]** 다음 중 상관 DELETE에서 `=` 대신 `EXISTS`를 권장하는 이유는?

① 실행 속도가 빠르기 때문에  
② NULL 값이 포함되어도 안전하게 처리하기 때문에  
③ 더 많은 열을 참조할 수 있기 때문에  
④ DDL 문과 함께 사용할 수 있기 때문에

---

**[7번]** 다음 중 `INSERT INTO ... SELECT` 구문의 설명으로 틀린 것은?

① 서브쿼리 결과를 대상 테이블에 여러 행 삽입할 수 있다  
② VALUES 절과 함께 사용할 수 있다  
③ WHERE 절로 복사할 행을 필터링할 수 있다  
④ 대상 테이블과 소스 테이블이 같을 수도 있다

---

**[8번]** 상관 UPDATE에서 SET 절의 서브쿼리가 0건을 반환하면?

① 오류 발생 (ORA-01427)  
② 해당 열이 NULL로 갱신된다  
③ 원래 값 유지  
④ 행이 삭제된다

---

**[9번]** `INSERT INTO (서브쿼리) VALUES (...)` 구문에서 서브쿼리에 `WITH CHECK OPTION`을 추가하지 않으면?

① 항상 오류 발생  
② 조건 위반 데이터도 삽입 가능  
③ 자동으로 조건 검사 수행  
④ VALUES 절 사용 불가

---

**[10번]** 다음 SQL에서 괄호 안에 들어갈 올바른 표현은?

```sql
UPDATE empl6 e
SET    department_name = (
    SELECT department_name
    FROM   departments d
    WHERE  (     ) = d.department_id
);
```

① e.employee_id  
② e.department_id  
③ e.job_id  
④ d.location_id

---

**[11번]** 상관 DELETE의 WHERE 절에서 서브쿼리가 여러 행을 반환할 가능성이 있을 때 사용해야 하는 연산자는?

① `=`  
② `>`  
③ `IN` 또는 `EXISTS`  
④ `BETWEEN`

---

**[12번]** 다음 설명 중 틀린 것은?

① `INSERT INTO (subquery) VALUES`는 인라인 뷰에 행을 삽입한다  
② `WITH CHECK OPTION`은 CREATE VIEW 문에서만 사용 가능하다  
③ 상관 UPDATE의 SET 절 서브쿼리는 외부 쿼리의 별칭을 참조할 수 있다  
④ 상관 DELETE 후 COMMIT 전에 ROLLBACK으로 취소할 수 있다

---

**[13번]** 다음 `INSERT INTO (서브쿼리)` 구문에서 삽입이 성공하는 조건은?

```sql
INSERT INTO (
    SELECT location_id, city, country_id
    FROM   locations
    WHERE  country_id = 'UK'
    WITH CHECK OPTION
)
VALUES (3300, 'Cardiff', 'UK');
```

① country_id가 'UK'이므로 조건 만족 → 삽입 성공  
② WITH CHECK OPTION은 항상 삽입을 차단한다  
③ location_id가 PK이므로 삽입 불가  
④ VALUES 절은 서브쿼리와 함께 사용 불가

---

**[14번]** 다음 SQL의 결과로 올바른 것은?

```sql
INSERT INTO (
    SELECT location_id, city, country_id
    FROM   locations
    WHERE  country_id = 'UK'
    WITH CHECK OPTION
)
VALUES (9999, 'New York', 'US');
```

① 삽입 성공 (country_id 'US'는 유효)  
② ORA-01402: WITH CHECK OPTION 조건 위반으로 오류  
③ ORA-00001: 중복 PK 오류  
④ ORA-01427: 서브쿼리가 여러 행 반환

---

**[15번]** `CREATE TABLE emp_backup AS SELECT * FROM employees;`에 대한 설명으로 틀린 것은?

① 테이블 구조와 데이터를 함께 복사한다  
② 원본 테이블의 제약 조건(PK, FK)은 복사되지 않는다  
③ WHERE 1=0을 추가하면 구조만 복사된다  
④ 복사된 테이블은 원본과 항상 동기화된다

---

**[16번]** 상관 UPDATE의 실행 순서로 올바른 것은?

① 서브쿼리 전체 실행 → 결과를 SET 절에 적용 → 외부 테이블 갱신  
② 외부 테이블 행 가져오기 → 해당 행의 값으로 서브쿼리 실행 → 결과로 갱신 반복  
③ 인덱스 스캔 → 전체 조인 실행 → 갱신  
④ WHERE 절 서브쿼리 먼저 실행 → SET 절 서브쿼리 실행

---

**[17번]** 상관 DELETE에서 `employee_history` 테이블에 존재하는 직원을 삭제하는 올바른 구문은?

① `DELETE FROM empl6 WHERE employee_id IN (SELECT * FROM employee_history)`  
② `DELETE FROM empl6 e WHERE employee_id = (SELECT employee_id FROM employee_history WHERE employee_id = e.employee_id)`  
③ `DELETE FROM empl6 WHERE EXISTS employee_history`  
④ `DELETE empl6 USING employee_history`

---

**[18번]** 다음 중 `INSERT INTO ... SELECT`와 `INSERT INTO (subquery) VALUES`의 차이점으로 올바른 것은?

① `INSERT INTO ... SELECT`는 한 행만 삽입 가능하다  
② `INSERT INTO (subquery) VALUES`는 여러 행을 삽입 가능하다  
③ `INSERT INTO ... SELECT`는 여러 행 삽입 가능, `INSERT INTO (subquery) VALUES`는 단일 VALUES로 삽입  
④ 두 구문은 동일하다

---

**[19번]** 상관 서브쿼리를 사용하는 DELETE에서 `NOT EXISTS`를 사용하면?

① 서브쿼리에 해당 행이 있을 때 삭제  
② 서브쿼리에 해당 행이 없을 때 삭제  
③ 항상 전체 행 삭제  
④ 오류 발생

---

**[20번]** 다음 중 DML 서브쿼리 실행 후 변경 내용을 확정하는 명령은?

① ROLLBACK  
② SAVEPOINT  
③ COMMIT  
④ FLUSH

---

## 중(응용) — 20문제

---

**[21번]** 다음 SQL을 실행하면 어떤 결과가 나타나는가?

```sql
INSERT INTO (
    SELECT location_id, city, country_id
    FROM   locations
    WHERE  country_id IN (
        SELECT country_id FROM countries
        NATURAL JOIN regions WHERE region_name = 'Europe'
    )
    WITH CHECK OPTION
)
VALUES (4000, 'Brussels', 'BE');
```

`BE`는 Belgium의 국가 코드이며 Europe 지역에 속한다고 가정하시오.

① 삽입 성공  
② ORA-01402 오류 (WITH CHECK OPTION 위반)  
③ ORA-00001 오류 (PK 중복)  
④ ORA-01427 오류 (서브쿼리 다중 행)

---

**[22번]** 상관 UPDATE 실행 시 `SET department_name = (서브쿼리)`에서 서브쿼리가 2행을 반환하면?

① NULL로 갱신된다  
② 첫 번째 행 값으로 갱신된다  
③ ORA-01427 오류 발생  
④ ORA-00001 오류 발생

---

**[23번]** 다음 SQL의 결과로 올바른 설명은?

```sql
UPDATE employees e
SET salary = (
    SELECT MAX(salary) * 1.1
    FROM   employees
    WHERE  department_id = e.department_id
);
```

① 모든 직원의 급여를 10% 인상한다  
② 각 직원의 급여를 소속 부서 최고 급여의 110%로 갱신한다  
③ 부서별 최고 급여자만 급여를 갱신한다  
④ 오류 발생 (MAX와 상관 서브쿼리 혼용 불가)

---

**[24번]** 다음 두 DELETE 구문의 결과 차이는?

```sql
-- A
DELETE FROM empl6 e
WHERE employee_id = (SELECT employee_id FROM employee_history WHERE employee_id = e.employee_id);

-- B
DELETE FROM empl6 e
WHERE EXISTS (SELECT NULL FROM employee_history eh WHERE eh.employee_id = e.employee_id);
```

① A와 B는 항상 동일한 결과  
② employee_history에 같은 employee_id가 여러 건 있으면 A는 오류, B는 정상 작동  
③ B는 NULL을 반환하므로 삭제하지 않는다  
④ A가 B보다 항상 빠르다

---

**[25번]** 다음 SQL에서 `WITH CHECK OPTION`의 역할은?

```sql
UPDATE (
    SELECT location_id, city
    FROM   locations
    WHERE  country_id = 'UK'
    WITH CHECK OPTION
)
SET city = 'Birmingham'
WHERE location_id = 2400;
```

① location_id=2400의 도시명만 변경하도록 제한  
② country_id가 'UK'가 아닌 행으로의 변경 차단  
③ city 열을 NULL로 갱신하지 못하도록 방지  
④ UPDATE 후 자동으로 COMMIT

---

**[26번]** 다음 SQL을 실행할 때 예상되는 동작은?

```sql
INSERT INTO sales_emp
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  department_id = 80
AND    salary > (SELECT AVG(salary) FROM employees WHERE department_id = 80);
```

① 부서 80번 전체 직원 복사  
② 부서 80번 중 평균 급여 이상인 직원만 복사  
③ 부서 80번 중 평균 급여 초과인 직원만 복사  
④ 오류 발생 (INSERT와 서브쿼리 혼용 불가)

---

**[27번]** 상관 UPDATE를 WITH 절로 변환한 다음 SQL의 목적은?

```sql
WITH dept_names AS (
    SELECT department_id, department_name
    FROM   departments
)
UPDATE empl6 e
SET    department_name = (
    SELECT department_name FROM dept_names
    WHERE  department_id = e.department_id
);
```

① empl6 전체 행 삭제  
② departments 테이블 생성  
③ empl6의 department_name을 departments 기반으로 갱신  
④ 오류 발생 (WITH 절은 DML에서 사용 불가)

---

**[28번]** 다음 상관 DELETE에서 삭제되는 행은?

```sql
DELETE FROM departments d
WHERE NOT EXISTS (
    SELECT NULL FROM employees WHERE department_id = d.department_id
);
```

① 직원이 있는 부서  
② 직원이 없는 부서  
③ 모든 부서  
④ 오류 발생

---

**[29번]** 다음 SQL의 실행 결과로 올바른 것은?

```sql
UPDATE employees e
SET    salary = salary * 1.05
WHERE  department_id = (
    SELECT department_id FROM departments
    WHERE  department_name = 'Sales'
);
```

① Sales 부서 직원 급여 5% 인상  
② 모든 직원 급여 5% 인상  
③ 서브쿼리가 상관 서브쿼리이므로 각 행마다 반복 실행  
④ 오류 발생 (WHERE 절에 스칼라 서브쿼리 불가)

---

**[30번]** 다음 SQL에서 문제점은?

```sql
DELETE FROM employees e
WHERE employee_id NOT IN (
    SELECT manager_id FROM employees
);
```

① NOT IN 조건이 올바르지 않아 항상 0건 삭제  
② manager_id에 NULL이 포함되면 NOT IN이 항상 UNKNOWN → 0건 삭제  
③ 자기 자신을 참조하므로 오류 발생  
④ DELETE 문에 서브쿼리 사용 불가

---

**[31번]** `INSERT INTO ... SELECT`로 복사한 데이터에서 자동으로 부여받지 **않는** 것은?

① 데이터 값  
② 열 이름  
③ 원본 테이블의 PRIMARY KEY 제약  
④ NOT NULL 제약 (단, CTAS 방식과 다름)

---

**[32번]** 상관 UPDATE 후 변경 내용을 확인하는 올바른 순서는?

① COMMIT → SELECT → ROLLBACK  
② SELECT → COMMIT → ROLLBACK  
③ UPDATE → SELECT (미커밋 상태 확인) → COMMIT 또는 ROLLBACK  
④ UPDATE → ROLLBACK → SELECT

---

**[33번]** 다음 SQL에서 `WITH CHECK OPTION`이 없을 때와 있을 때의 차이는?

```sql
INSERT INTO (
    SELECT location_id, city, country_id
    FROM   locations
    WHERE  country_id = 'UK'
    [WITH CHECK OPTION]
)
VALUES (9999, 'Tokyo', 'JP');
```

① 없으면 삽입 성공, 있으면 ORA-01402 오류  
② 없으면 오류, 있으면 삽입 성공  
③ 두 경우 모두 삽입 성공  
④ 두 경우 모두 오류

---

**[34번]** 상관 UPDATE에서 성능 향상을 위한 방법으로 적절하지 **않은** 것은?

① 서브쿼리의 참조 열에 인덱스 생성  
② WITH 절로 서브쿼리를 한 번만 실행되도록 변환  
③ 갱신할 행에 FK 제약 추가  
④ JOIN UPDATE 방식으로 변환

---

**[35번]** 다음 SQL은 어떤 결과를 만드는가?

```sql
INSERT INTO job_history
SELECT employee_id, hire_date, SYSDATE, job_id, department_id
FROM   employees
WHERE  employee_id IN (100, 101, 102);
```

① employees에서 3명의 과거 이력을 job_history에 삽입  
② job_history에서 3명 삭제  
③ employees에서 3명의 급여 갱신  
④ 오류 발생 (INSERT에 서브쿼리 다중 행 불가)

---

**[36번]** 다음 상관 DELETE 중 직원이 이직 이력이 없는 직원만 남기려면 어떤 구문이 올바른가?

```sql
-- A
DELETE FROM employees e
WHERE EXISTS (SELECT NULL FROM job_history WHERE employee_id = e.employee_id);

-- B
DELETE FROM employees e
WHERE NOT EXISTS (SELECT NULL FROM job_history WHERE employee_id = e.employee_id);
```

① A (이직 이력 있는 직원 삭제 → 없는 직원만 남음)  
② B (이직 이력 없는 직원 삭제 → 있는 직원만 남음)  
③ A와 B 모두 동일한 결과  
④ 오류 발생

---

**[37번]** 다음 SQL의 목적으로 올바른 것은?

```sql
UPDATE (
    SELECT e.salary, d.avg_sal
    FROM   employees e
    JOIN   (SELECT department_id, AVG(salary) avg_sal
            FROM   employees GROUP BY department_id) d
    ON (e.department_id = d.department_id)
)
SET salary = avg_sal * 1.1;
```

① 전체 직원 급여를 10% 인상  
② 각 직원의 급여를 소속 부서 평균 급여의 110%로 갱신  
③ 부서 평균 급여를 10% 올림  
④ 오류 발생 (FROM 절 서브쿼리에 UPDATE 불가)

---

**[38번]** 다음 중 서브쿼리를 이용한 DML이 ROLLBACK 가능한 시점은?

① DDL 문 실행 후  
② COMMIT 실행 전  
③ SAVEPOINT 설정 후에만  
④ 항상 ROLLBACK 불가

---

**[39번]** 상관 UPDATE 방식과 JOIN을 이용한 UPDATE 방식 중 Oracle에서 선호되는 방식은?

① 항상 상관 UPDATE  
② 대용량에서는 JOIN UPDATE(머지 방식) 또는 WITH 절 방식이 성능상 유리  
③ 항상 JOIN UPDATE  
④ 두 방식은 완전히 동일

---

**[40번]** 다음 SQL을 실행하면?

```sql
DELETE FROM departments
WHERE department_id NOT IN (
    SELECT DISTINCT department_id FROM employees WHERE department_id IS NOT NULL
);
```

① 직원이 있는 부서 삭제  
② 직원이 없는 부서 삭제  
③ 전체 부서 삭제  
④ NULL 처리로 인해 0건 삭제

---

## 상(심화) — 10문제

---

**[41번]** 다음 SQL에서 의도하지 않은 동작이 발생할 수 있는 이유는?

```sql
DELETE FROM employees e
WHERE department_id NOT IN (
    SELECT department_id FROM departments
);
```

`departments.department_id`는 NOT NULL이지만, `employees.department_id`는 NULL 허용.

① `departments.department_id`에 NULL이 있으면 0건 삭제 가능  
② `employees.department_id`에 NULL인 직원도 NOT IN 결과에서 UNKNOWN 처리되어 삭제 안 됨  
③ 오류 발생 (NULL 비교 불가)  
④ 부서가 없는 직원(NULL)이 삭제될 수 있어 의도치 않은 삭제 발생

---

**[42번]** 다음 두 UPDATE 구문의 결과 차이를 분석하시오.

```sql
-- A: 상관 UPDATE
UPDATE employees e
SET salary = (SELECT AVG(salary) FROM employees WHERE department_id = e.department_id);

-- B: MERGE 방식
MERGE INTO employees e
USING (SELECT department_id, AVG(salary) avg_sal FROM employees GROUP BY department_id) d
ON (e.department_id = d.department_id)
WHEN MATCHED THEN UPDATE SET e.salary = d.avg_sal;
```

① A와 B는 항상 동일한 결과  
② B는 집계를 한 번만 실행하므로 대용량에서 성능 우수, A는 행마다 반복 실행  
③ A는 트랜잭션 롤백 가능, B는 자동 COMMIT  
④ B는 DELETE도 수행하므로 결과가 다름

---

**[43번]** 다음 SQL을 분석하여 결과를 예측하시오.

```sql
INSERT INTO (
    SELECT location_id, city, country_id
    FROM   locations
    WHERE  country_id IN (
        SELECT country_id FROM countries NATURAL JOIN regions
        WHERE  region_name = 'Europe'
    )
    WITH CHECK OPTION
)
SELECT 5000 + ROWNUM, city || '_copy', country_id
FROM   locations
WHERE  country_id IN (
    SELECT country_id FROM countries NATURAL JOIN regions
    WHERE  region_name = 'Europe'
);
```

① ORA-01402 오류 (WITH CHECK OPTION 위반)  
② 유럽 지역 locations 행들의 복사본이 삽입됨  
③ 오류 발생 (INSERT INTO subquery에 SELECT 사용 불가)  
④ 빈 결과 (유럽 locations가 없는 경우)

---

**[44번]** 다음 상관 UPDATE의 의도치 않은 부작용을 설명하시오.

```sql
ALTER TABLE employees ADD mgr_salary NUMBER;

UPDATE employees e
SET mgr_salary = (
    SELECT salary FROM employees WHERE employee_id = e.manager_id
);
```

manager_id가 NULL인 직원(예: 최상위 관리자)의 `mgr_salary`는 어떻게 되는가?

① 0으로 갱신  
② NULL로 갱신 (서브쿼리 0건 → NULL)  
③ 오류 발생 (ORA-01427)  
④ 원래 값 유지

---

**[45번]** 다음 SQL에서 FK 제약이 있을 때 발생하는 결과는?

```sql
-- departments.department_id를 PK, employees.department_id가 FK
DELETE FROM departments d
WHERE EXISTS (
    SELECT NULL FROM employees WHERE department_id = d.department_id
);
```

① 직원이 있는 부서를 삭제 → FK 제약(ORA-02292) 오류  
② 직원이 있는 부서를 정상 삭제  
③ 직원이 없는 부서만 삭제  
④ 전체 부서 삭제

---

**[46번]** 다음 시나리오에서 올바른 처리 방법은?

**상황:** `empl6` 테이블에 `department_name` 열을 추가하고, `departments` 테이블에서 해당 부서명을 채우려 한다. 단, 일부 직원의 `department_id`가 NULL이다.

```sql
UPDATE empl6 e
SET department_name = (
    SELECT department_name FROM departments
    WHERE  department_id = e.department_id
);
```

① department_id가 NULL인 직원의 경우 ORA-01427 오류  
② department_id가 NULL인 직원의 department_name은 NULL로 갱신됨  
③ department_id가 NULL인 직원은 갱신되지 않음  
④ 오류 없이 NULL 행 제외하고 모두 갱신됨 (②와 동일 의미)

---

**[47번]** 다음 두 DELETE 구문의 실행 결과 차이를 분석하시오.

```sql
-- A
DELETE FROM employees e
WHERE employee_id IN (
    SELECT employee_id FROM job_history
);

-- B
DELETE FROM employees e
WHERE EXISTS (
    SELECT NULL FROM job_history jh WHERE jh.employee_id = e.employee_id
);
```

① A가 B보다 항상 더 많은 행을 삭제  
② A는 job_history에서 중복 employee_id가 있어도 DISTINCT 없이 정상, B도 동일 결과  
③ A에서 job_history.employee_id에 NULL이 있으면 해당 직원은 삭제 안 됨  
④ B는 NULL에 안전하지 않다

---

**[48번]** 다음 SQL의 실행 결과로 올바른 분석은?

```sql
-- SAVEPOINT 설정 후 두 개의 DML 실행
SAVEPOINT before_update;

UPDATE employees SET salary = salary * 1.2 WHERE department_id = 80;

DELETE FROM departments WHERE department_id = 99;

ROLLBACK TO before_update;
```

① UPDATE와 DELETE 모두 취소됨  
② UPDATE만 취소됨 (DELETE는 DDL이므로 자동 COMMIT)  
③ DELETE만 취소됨  
④ ROLLBACK TO SAVEPOINT 이후에는 COMMIT 불필요

---

**[49번]** 다음 중 `INSERT INTO (subquery) VALUES`를 사용할 수 없는 경우는?

① 서브쿼리에 단순 WHERE 조건이 있는 경우  
② 서브쿼리에 WITH CHECK OPTION이 있는 경우  
③ 서브쿼리에 GROUP BY 절이 있는 경우  
④ 서브쿼리에 JOIN이 있는 경우

---

**[50번]** 다음 복합 DML 시나리오의 최종 상태를 예측하시오.

```sql
-- 1단계
CREATE TABLE emp_temp AS SELECT * FROM employees WHERE 1=0;

-- 2단계
INSERT INTO emp_temp
SELECT * FROM employees WHERE department_id = 80;

-- 3단계
UPDATE emp_temp e
SET salary = (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id);

-- 4단계
DELETE FROM emp_temp e
WHERE salary < (SELECT AVG(salary) FROM emp_temp);

COMMIT;
```

① emp_temp에 부서 80번 직원 중 부서 최고 급여로 갱신된 후, 팀 평균 미만 제거된 행만 존재  
② emp_temp는 비어있다  
③ emp_temp에 employees 전체 복사본 존재  
④ emp_temp에 부서 80번 직원 중 최고 급여보다 낮은 급여를 받던 직원만 존재
