# Oracle Database 19c: SQL Workshop
## Chapter 14 — 뷰(View) 생성 | SQL 실습 문제 30문제

> **환경:** Oracle Database 19c, HR 스키마  
> **테이블:** EMPLOYEES(107행), DEPARTMENTS(27행), JOBS(19행), LOCATIONS, COUNTRIES, JOB_HISTORY

---

## Group 1: 단순 뷰 생성 & 조회 (문제 1~6)

**[1번]** 부서 번호가 50인 직원의 `employee_id`, `last_name`, `salary`, `hire_date`를 포함하는 `emp_dept50_vu`라는 뷰를 생성하시오.

---

**[2번]** 문제 1에서 생성한 `emp_dept50_vu` 뷰를 조회하여 모든 데이터를 출력하시오.

---

**[3번]** `emp_dept50_vu` 뷰의 구조를 확인하시오. (열 이름과 데이터 타입 표시)

---

**[4번]** `salary * 12`를 `annual_salary`라는 별칭으로 표현한 열을 포함하여, 직원 번호와 이름을 함께 표시하는 `emp_annual_sal_vu` 뷰를 생성하시오. (모든 직원 대상)

---

**[5번]** 뷰 이름에 별칭을 지정하는 방식으로 `emp_dept50_vu`를 재생성하시오.  
- 열 별칭: `employee_id` → `EMP_ID`, `last_name` → `NAME`, `salary` → `MONTHLY_SAL`, `hire_date` → `START_DATE`

---

**[6번]** `USER_VIEWS` 딕셔너리 뷰에서 현재 사용자가 보유한 뷰 이름 목록을 조회하시오.

---

## Group 2: 뷰 수정 & 복합 뷰 (문제 7~12)

**[7번]** `emp_dept50_vu` 뷰를 수정하여 `department_id` 열을 추가하시오. `CREATE OR REPLACE VIEW`를 사용하고, 열 별칭을 제거하여 원래 열 이름을 사용하시오.

---

**[8번]** 두 개의 테이블을 JOIN하여 복합 뷰를 생성하시오.  
- 뷰 이름: `emp_dept_vu`  
- 포함 열: `employee_id`, `last_name`, `department_name`, `city`  
- 테이블: `employees`, `departments`, `locations` (JOIN 사용)

---

**[9번]** 부서별 최소 급여, 최대 급여, 평균 급여를 보여주는 복합 뷰를 생성하시오.  
- 뷰 이름: `dept_sal_stats_vu`  
- 열 별칭: `department_name`, `min_sal`, `max_sal`, `avg_sal`
- GROUP BY 사용

---

**[10번]** 직종(job_id)별로 평균 급여를 표시하는 뷰 `job_avg_sal_vu`를 생성하고, 평균 급여가 8000 이상인 직종만 표시하도록 `HAVING` 절을 사용하시오.

---

**[11번]** `emp_dept_vu` 뷰(문제 8)를 사용하여 도시(city)가 'Seattle'인 직원의 이름과 부서명을 조회하시오.

---

**[12번]** `USER_VIEWS`에서 `dept_sal_stats_vu` 뷰의 서브쿼리 텍스트(TEXT)를 조회하시오.

---

## Group 3: WITH CHECK OPTION & WITH READ ONLY (문제 13~18)

**[13번]** 부서 번호가 20인 직원만 포함하는 뷰를 생성하시오.  
- 뷰 이름: `emp_dept20_ck_vu`  
- `WITH CHECK OPTION CONSTRAINT empvu20_ck` 적용

---

**[14번]** 문제 13에서 생성한 `emp_dept20_ck_vu` 뷰를 통해 `department_id = 30`인 직원 행을 삽입하려고 시도하고, 발생하는 오류를 확인하시오.

```sql
INSERT INTO emp_dept20_ck_vu
    (employee_id, last_name, email, hire_date, job_id, department_id)
VALUES (500, 'TestUser', 'TESTUSER', SYSDATE, 'MK_REP', 30);
```

---

**[15번]** `emp_dept20_ck_vu` 뷰를 통해 `department_id = 20`인 유효한 직원을 삽입하시오.

```sql
INSERT INTO emp_dept20_ck_vu
    (employee_id, last_name, email, hire_date, job_id, department_id)
VALUES (501, 'GoodUser', 'GOODUSER', SYSDATE, 'MK_REP', 20);
```

삽입 후 뷰와 기반 테이블을 조회하여 결과를 확인하시오. (작업 후 ROLLBACK)

---

**[16번]** 부서 번호가 10인 직원 정보를 읽기 전용으로 보여주는 뷰를 생성하시오.  
- 뷰 이름: `emp_dept10_ro_vu`  
- 열 별칭: `employee_number`, `employee_name`, `job_title`  
- `WITH READ ONLY` 적용

---

**[17번]** 문제 16에서 생성한 `emp_dept10_ro_vu` 뷰를 통해 DELETE를 시도하시오.

```sql
DELETE FROM emp_dept10_ro_vu WHERE employee_number = 200;
```

발생하는 오류를 확인하시오.

---

**[18번]** `WITH CHECK OPTION` 없는 단순 뷰에서 "사라지는 행" 현상을 실습하시오.

1. 부서 80번 직원만 보이는 `emp_dept80_vu` 뷰 생성
2. 뷰를 통해 `department_id = 90`인 행을 삽입 (사전 조건: 필수 열 모두 제공)
3. 뷰를 재조회하여 삽입한 행이 보이지 않는 것을 확인
4. 기반 테이블 `employees`에서 해당 행이 존재하는지 확인
5. ROLLBACK

---

## Group 4: DML 제한 사항 (문제 19~24)

**[19번]** 다음 복합 뷰를 통해 DELETE를 시도하고 결과를 확인하시오.

```sql
CREATE OR REPLACE VIEW dept_sal_vu AS
SELECT department_id, MAX(salary) max_sal
FROM   employees GROUP BY department_id;

DELETE FROM dept_sal_vu WHERE department_id = 80;
```

---

**[20번]** 표현식 열을 포함한 뷰에서 INSERT를 시도하고 결과를 확인하시오.

```sql
CREATE OR REPLACE VIEW emp_expr_vu AS
SELECT employee_id, last_name, salary * 12 annual_sal
FROM   employees;

INSERT INTO emp_expr_vu VALUES (600, 'Kim', 96000);
```

---

**[21번]** 다음 단순 뷰에서 가능한 DML을 모두 시도하고, 각각 성공/실패 여부를 확인하시오.

```sql
CREATE OR REPLACE VIEW emp_simple_vu AS
SELECT employee_id, last_name, salary, department_id
FROM   employees WHERE department_id IN (10, 20, 30);
```

시도 목록:
- `UPDATE emp_simple_vu SET salary = 7000 WHERE employee_id = 200;`
- `DELETE FROM emp_simple_vu WHERE employee_id = 200;`
- `INSERT INTO emp_simple_vu (employee_id, last_name, email, hire_date, job_id, department_id) VALUES (601, 'Test', 'TEST', SYSDATE, 'AD_ASST', 10);`

작업 후 ROLLBACK.

---

**[22번]** DISTINCT를 포함한 뷰에서 DML을 시도하시오.

```sql
CREATE OR REPLACE VIEW distinct_dept_vu AS
SELECT DISTINCT department_id FROM employees;

DELETE FROM distinct_dept_vu WHERE department_id = 80;
```

---

**[23번]** ROWNUM을 포함한 뷰에서 UPDATE를 시도하시오.

```sql
CREATE OR REPLACE VIEW top10_emp_vu AS
SELECT employee_id, last_name, salary
FROM   employees WHERE ROWNUM <= 10;

UPDATE top10_emp_vu SET salary = 9999 WHERE employee_id = 100;
```

---

**[24번]** JOIN 뷰에서 DML 시도:

```sql
CREATE OR REPLACE VIEW emp_dept_join_vu AS
SELECT e.employee_id, e.last_name, d.department_name
FROM   employees e JOIN departments d USING (department_id);

UPDATE emp_dept_join_vu SET last_name = 'NewName' WHERE employee_id = 100;
DELETE FROM emp_dept_join_vu WHERE employee_id = 100;
```

각 DML의 성공/실패를 확인하시오.

---

## Group 5: 뷰 삭제 & 종합 (문제 25~30)

**[25번]** 실습 중 생성한 `emp_dept50_vu` 뷰를 삭제하시오. 삭제 전후로 `USER_VIEWS`를 조회하여 뷰가 삭제되었는지 확인하시오.

---

**[26번]** 기반 테이블이 INVALID 상태 영향을 주는 시나리오 실습:

```sql
-- 1. 임시 테이블 생성
CREATE TABLE temp_emp AS SELECT employee_id, last_name FROM employees WHERE 1=0;

-- 2. 뷰 생성
CREATE VIEW temp_emp_vu AS SELECT * FROM temp_emp;

-- 3. USER_OBJECTS에서 temp_emp_vu의 STATUS 확인
SELECT object_name, status FROM user_objects WHERE object_name = 'TEMP_EMP_VU';

-- 4. 기반 테이블 삭제
DROP TABLE temp_emp;

-- 5. STATUS 재확인
SELECT object_name, status FROM user_objects WHERE object_name = 'TEMP_EMP_VU';

-- 6. 뷰 조회 시도 (오류 예상)
SELECT * FROM temp_emp_vu;
```

각 단계 결과를 기록하고 정리하시오. (마지막에 `DROP VIEW temp_emp_vu;` 실행)

---

**[27번]** `FORCE` 옵션을 사용하여 기반 테이블 없이 뷰를 생성하시오.

```sql
-- 1. 존재하지 않는 테이블을 기반으로 뷰 생성
CREATE FORCE VIEW ghost_vu AS
SELECT id, name FROM ghost_table;

-- 2. STATUS 확인
SELECT object_name, status FROM user_objects WHERE object_name = 'GHOST_VU';

-- 3. 기반 테이블 생성
CREATE TABLE ghost_table (id NUMBER, name VARCHAR2(50));

-- 4. STATUS 재확인 (자동 변경 여부)
SELECT object_name, status FROM user_objects WHERE object_name = 'GHOST_VU';
```

(마지막에 `DROP VIEW ghost_vu; DROP TABLE ghost_table;`)

---

**[28번]** 뷰 기반 뷰(Nested View)를 생성하고 조회하시오.

1. 급여가 5000 초과인 직원 뷰 `high_sal_vu` 생성 (employee_id, last_name, salary, department_id)
2. `high_sal_vu` 기반으로 부서 80번만 필터링한 `dept80_high_sal_vu` 생성
3. `dept80_high_sal_vu` 조회하여 결과 확인

---

**[29번]** 종합 실습: 다음 요구사항을 충족하는 뷰를 생성하시오.

요구사항:
- 뷰 이름: `emp_summary_vu`
- 포함 내용: 직원 번호, 풀네임(`first_name || ' ' || last_name`), 부서명, 직종명, 연봉(`salary*12`)
- 연봉 5만 달러 이상만 포함
- 테이블: `employees`, `departments`, `jobs`
- 이 뷰는 보고용이므로 DML 차단

생성 후 부서명 기준으로 정렬하여 조회하시오.

---

**[30번]** 실습 정리: 실습 중 생성한 모든 뷰를 삭제하시오.

```sql
DROP VIEW emp_dept50_vu;
DROP VIEW emp_annual_sal_vu;
DROP VIEW emp_dept_vu;
DROP VIEW dept_sal_stats_vu;
DROP VIEW job_avg_sal_vu;
DROP VIEW emp_dept20_ck_vu;
DROP VIEW emp_dept10_ro_vu;
DROP VIEW emp_dept80_vu;
DROP VIEW dept_sal_vu;
DROP VIEW emp_expr_vu;
DROP VIEW emp_simple_vu;
DROP VIEW distinct_dept_vu;
DROP VIEW top10_emp_vu;
DROP VIEW emp_dept_join_vu;
DROP VIEW high_sal_vu;
DROP VIEW dept80_high_sal_vu;
DROP VIEW emp_summary_vu;
```

삭제 후 `USER_VIEWS`에서 Ch14 관련 뷰가 모두 제거되었는지 확인하시오.

---

*[Chapter 14 실습 문제 끝 — 30문제]*
