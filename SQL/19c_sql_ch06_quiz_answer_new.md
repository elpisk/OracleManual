# Oracle Database 19c: SQL Workshop
## Chapter 6 — 그룹 함수 | 연습문제 모범답안

---

# ★ 하 (기초) — 모범답안

---

**[하-01] 답: ②**

그룹 함수는 행의 집합(그룹)에 대해 실행되어 그룹당 하나의 결과를 반환한다.  
단일행 함수가 각 행마다 하나의 결과를 반환하는 것과 대조된다.

---

**[하-02] 답: ②**

- `COUNT(*)`: 모든 행 카운트 (NULL 포함) → 107
- `COUNT(commission_pct)`: commission_pct가 NULL이 아닌 행만 카운트 → 35

---

**[하-03] 답: ③**

```sql
SELECT COUNT(*) FROM employees;
-- 결과: 107
```

HR 스키마 EMPLOYEES 테이블의 전체 사원 수는 107명이다.

---

**[하-04] 답: ②**

그룹 함수는 열의 NULL 값을 자동으로 무시(제외)한다.  
이 때문에 `AVG(commission_pct)`는 NULL이 아닌 35명만 대상으로 평균을 계산한다.

---

**[하-05] 답: ③**

`SELECT department_id, MAX(salary) FROM employees;` — **ORA-00937 오류**

GROUP BY 절 없이 그룹 함수(MAX)와 일반 열(department_id)을 혼용하면 오류가 발생한다.  
나머지 ①, ②, ④는 올바른 SQL이다.

---

**[하-06] 답: ③**

SELECT 목록에서 그룹 함수가 아닌 모든 열은 반드시 GROUP BY 절에 포함해야 한다.  
GROUP BY에 포함된 열 이외의 열도 SELECT에 사용할 수 있으나(그룹 함수로 감싸서), 반대로 일반 열은 GROUP BY에 반드시 있어야 한다.

---

**[하-07] 답: ②**

```sql
SELECT AVG(commission_pct) FROM employees;
```

그룹 함수는 NULL을 자동으로 무시한다. commission_pct가 NULL이 아닌 35명만 포함하여 평균을 계산한다.

---

**[하-08] 답: ③**

HAVING 절은 GROUP BY 이후에 그룹 함수 기준으로 그룹을 필터링하는 데 사용된다.  
WHERE는 개별 행을 필터링하고, HAVING은 그룹을 필터링한다.

---

**[하-09] 답: ②**

WHERE 절에서 그룹 함수를 사용하면 **ORA-00934: group function is not allowed here** 오류가 발생한다.  
그룹 함수로 그룹을 제한할 때는 HAVING 절을 사용해야 한다.

---

**[하-10] 답: ②**

```sql
SELECT   department_id, AVG(salary)
FROM     employees
GROUP BY department_id
HAVING   AVG(salary) > 8000;
```

HAVING 절이 들어가야 한다. WHERE에는 그룹 함수를 사용할 수 없다.

---

**[하-11] 답: ③**

```sql
SELECT COUNT(DISTINCT department_id) FROM employees;
-- 결과: 11
```

HR 스키마에서 NULL이 아닌 고유한 department_id는 11개이다.  
(전체 부서는 27개이지만, EMPLOYEES에 있는 부서 수가 11개)

---

**[하-12] 답: ②**

```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
```

SQL 처리 순서: 테이블 지정(FROM) → 행 필터링(WHERE) → 그룹화(GROUP BY) → 그룹 필터링(HAVING) → 열 선택(SELECT) → 정렬(ORDER BY)

---

**[하-13] 답: ③**

MIN/MAX 함수는 숫자, 문자, 날짜 데이터 타입 모두 사용 가능하다.  
`MIN(last_name)`은 알파벳 순서로 가장 앞에 오는(사전순 최솟값) last_name을 반환한다.

---

**[하-14] 답: ②**

`MAX(AVG(salary))`만 올바른 그룹 함수 중첩이다.  
Oracle에서 그룹 함수는 최대 2단계까지 중첩할 수 있다:

```sql
SELECT MAX(AVG(salary))
FROM   employees
GROUP BY department_id;
```

`SUM(SUM(salary))`, `MIN(MAX(salary))`는 동일 레벨 중첩으로 Oracle에서 지원되지 않는다.

---

**[하-15] 답: ②**

아니오. GROUP BY 열은 SELECT 목록에 없어도 된다.

```sql
-- GROUP BY department_id를 사용하되 SELECT에 department_id 없어도 됨
SELECT AVG(salary)
FROM   employees
GROUP BY department_id;
-- 각 부서의 평균 급여만 출력 (부서 번호 없이)
```

---

**[하-16] 답:**

```sql
SELECT department_id, job_id, COUNT(last_name)
FROM   employees
GROUP BY department_id;
```

**오류: ORA-00979: not a GROUP BY expression**  

SELECT 목록에 `job_id`가 있지만 GROUP BY에는 `department_id`만 있다.  
그룹 함수가 아닌 열(`job_id`)이 GROUP BY 절에 포함되지 않았기 때문에 오류가 발생한다.

**수정 방법:**
```sql
-- 방법 1: GROUP BY에 job_id 추가
SELECT department_id, job_id, COUNT(last_name)
FROM   employees
GROUP BY department_id, job_id;

-- 방법 2: SELECT에서 job_id 제거
SELECT department_id, COUNT(last_name)
FROM   employees
GROUP BY department_id;
```

---

**[하-17] 답: ①**

SUM 함수는 숫자 타입에만 사용 가능하다.  
반면 MIN/MAX는 숫자, 문자, 날짜 모두 사용 가능하다.

---

**[하-18] 답:**

두 쿼리의 결과가 다른 이유는 NULL 처리 방식의 차이 때문이다.

- **(A)** `AVG(commission_pct)`: 그룹 함수는 NULL을 자동 무시 → commission_pct가 있는 **35명** 기준 평균  
  결과: 약 0.2229 (35명의 평균)

- **(B)** `AVG(NVL(commission_pct, 0))`: NVL로 NULL을 0으로 대체 → **107명** 전체 기준 평균  
  결과: 약 0.0730 (107명 기준, 훨씬 낮음)

비즈니스 요구사항에 따라 어떤 방식을 사용할지 신중히 선택해야 한다.

---

**[하-19] 답: ②**

```sql
SELECT department_id, COUNT(*)
FROM   employees
GROUP BY department_id;
```

① `SELECT COUNT(*) FROM employees;` — 전체 사원 수 1개 행만 반환  
③ `SELECT department_id, COUNT(*) FROM employees;` — GROUP BY 없어서 ORA-00937 오류  
④ `SELECT COUNT(department_id) FROM employees GROUP BY department_id;` — GROUP BY 있지만 SELECT에 department_id 없어서 부서별 구분 불가 (GROUP BY는 맞지만 출력에 부서번호 없음 — 틀린 것은 아니나 의미상 부족)

---

**[하-20] 답: ④**

MAX 함수 결과가 NULL이 되는 경우:
- 테이블에 행이 없을 때 (빈 테이블)
- WHERE 조건으로 행이 없을 때 (결과 행 없음)
- 행이 있지만 모두 NULL인 경우

위의 세 가지 경우 모두 MAX는 NULL을 반환한다.

---

# ★★ 중 (응용) — 모범답안

---

**[중-01] 답**

```sql
SELECT MAX(salary)           AS max_salary,
       MIN(salary)           AS min_salary,
       ROUND(AVG(salary), 2) AS avg_salary,
       SUM(salary)           AS sum_salary
FROM   employees;
```

---

**[중-02] 답**

```sql
SELECT AVG(salary) AS avg_sal,
       MAX(salary) AS max_sal,
       MIN(salary) AS min_sal,
       SUM(salary) AS sum_sal
FROM   employees
WHERE  job_id LIKE '%REP%';
```

---

**[중-03] 답**

```sql
SELECT COUNT(*)              AS total_count,
       COUNT(commission_pct) AS with_comm_count
FROM   employees;
```

> 결과: total_count=107, with_comm_count=35

---

**[중-04] 답**

```sql
SELECT   department_id, COUNT(*) AS emp_count
FROM     employees
GROUP BY department_id
ORDER BY emp_count DESC;
```

---

**[중-05] 답**

```sql
SELECT   department_id, AVG(salary) AS avg_salary
FROM     employees
GROUP BY department_id
ORDER BY department_id;
```

> NULL 부서도 자동 포함된다 (GROUP BY는 NULL을 하나의 그룹으로 처리).

---

**[중-06] 답**

```sql
SELECT   job_id, SUM(salary) AS total_salary
FROM     employees
GROUP BY job_id
HAVING   SUM(salary) > 10000
ORDER BY job_id;
```

---

**[중-07] 답**

```sql
SELECT   department_id,
         MIN(hire_date) AS earliest_hire,
         MAX(hire_date) AS latest_hire
FROM     employees
GROUP BY department_id
ORDER BY department_id;
```

---

**[중-08] 답**

```sql
SELECT   department_id, ROUND(AVG(salary), 2) AS avg_salary
FROM     employees
GROUP BY department_id
ORDER BY avg_salary DESC;
```

---

**[중-09] 답**

```sql
SELECT   department_id, job_id, SUM(salary) AS total_salary
FROM     employees
WHERE    department_id > 40
GROUP BY department_id, job_id
ORDER BY department_id;
```

---

**[중-10] 답**

```sql
SELECT   job_id, MIN(salary) AS min_salary
FROM     employees
GROUP BY job_id
ORDER BY min_salary;
```

> 가장 낮은 급여를 받는 직무를 찾으려면 ORDER BY min_salary로 오름차순 정렬 후 첫 행 참조.

---

**[중-11] 답**

```sql
SELECT   department_id, MAX(salary) AS max_salary
FROM     employees
GROUP BY department_id
HAVING   MAX(salary) > 10000
ORDER BY department_id;
```

---

**[중-12] 답**

```sql
SELECT   job_id, SUM(salary) AS payroll
FROM     employees
WHERE    job_id NOT LIKE '%REP%'
GROUP BY job_id
HAVING   SUM(salary) > 13000
ORDER BY payroll;
```

---

**[중-13] 답**

```sql
SELECT   department_id, COUNT(*) AS emp_count
FROM     employees
GROUP BY department_id
HAVING   COUNT(*) >= 5
ORDER BY department_id;
```

---

**[중-14] 답**

```sql
SELECT   job_id, COUNT(*) AS emp_count
FROM     employees
GROUP BY job_id
HAVING   COUNT(*) >= 3
ORDER BY emp_count DESC;
```

---

**[중-15] 답**

```sql
SELECT   department_id,
         ROUND(AVG((salary * 12) + (salary * 12 * NVL(commission_pct, 0))), 2) AS avg_annual
FROM     employees
GROUP BY department_id
ORDER BY department_id;
```

---

**[중-16] 답**

```sql
SELECT   department_id, COUNT(DISTINCT job_id) AS unique_jobs
FROM     employees
GROUP BY department_id
ORDER BY department_id;
```

---

**[중-17] 답**

```sql
SELECT   department_id, MIN(salary) AS min_salary
FROM     employees
GROUP BY department_id
HAVING   MIN(salary) >= 5000
ORDER BY department_id;
```

---

**[중-18] 답**

```sql
SELECT   manager_id, COUNT(*) AS subordinate_count
FROM     employees
WHERE    manager_id IS NOT NULL
GROUP BY manager_id
HAVING   COUNT(*) >= 3
ORDER BY manager_id;
```

---

**[중-19] 답**

```sql
SELECT   department_id, ROUND(AVG(salary), 2) AS avg_salary
FROM     employees
WHERE    department_id IN (50, 60, 80)
GROUP BY department_id
ORDER BY department_id;
```

---

**[중-20] 답**

```sql
SELECT   TO_CHAR(hire_date, 'YYYY') AS hire_year,
         COUNT(*)                   AS emp_count
FROM     employees
GROUP BY TO_CHAR(hire_date, 'YYYY')
ORDER BY hire_year;
```

---

# ★★★ 상 (심화) — 모범답안

---

**[상-01] 답**

```sql
-- 오류가 있는 원본
SELECT department_id, job_id, AVG(salary), COUNT(*)
FROM   employees
WHERE  AVG(salary) > 5000   -- 오류 1: WHERE에 그룹 함수 사용
GROUP BY department_id;      -- 오류 2: job_id가 GROUP BY에 없음
```

**발견된 오류:**

1. **ORA-00934**: WHERE 절에 그룹 함수 `AVG(salary)` 사용 → HAVING으로 이동
2. **ORA-00979**: SELECT에 `job_id`가 있지만 GROUP BY에 없음 → GROUP BY에 추가

**수정된 SQL:**

```sql
SELECT   department_id, job_id, AVG(salary), COUNT(*)
FROM     employees
GROUP BY department_id, job_id
HAVING   AVG(salary) > 5000;
```

---

**[상-02] 답**

**(A) 결과 행 수 분석:**

```sql
SELECT department_id, COUNT(*)
FROM   employees
WHERE  salary > 5000          -- 먼저 salary > 5000인 행만 필터링
GROUP BY department_id;
```

→ salary > 5000인 사원들을 부서별로 그룹화. salary가 5000 이하인 사원은 **제외**된 상태로 카운트.

**(B) 결과 행 수 분석:**

```sql
SELECT department_id, COUNT(*)
FROM   employees
GROUP BY department_id
HAVING AVG(salary) > 5000;   -- 그룹화 후 평균 급여 > 5000인 그룹만 표시
```

→ **전체 사원**을 부서별로 그룹화 후, 해당 부서의 평균 급여가 5000 초과인 부서만 필터링.

**핵심 차이:**
- (A): salary > 5000인 **개별 사원**만 포함 (저임금 사원은 카운트에서 제외)
- (B): 모든 사원을 카운트하되 부서 **평균 급여**가 조건을 만족하는 부서만 표시

결과 행 수는 다를 수 있으며, COUNT 값도 다르다.

---

**[상-03] 답**

```sql
SELECT MAX(AVG(salary))
FROM   employees
GROUP BY department_id;
```

**처리 과정:**
1. `GROUP BY department_id`: 부서별로 그룹화
2. `AVG(salary)`: 각 부서의 평균 급여 계산
3. `MAX(...)`: 여러 부서 평균 중 최대값 1개 반환

---

**[상-04] 답**

```sql
SELECT   department_id,
         COUNT(*)                   AS emp_count,
         ROUND(AVG(salary))         AS avg_salary,
         MAX(salary)                AS max_salary,
         MIN(salary)                AS min_salary,
         SUM(salary)                AS total_salary
FROM     employees
WHERE    department_id IN (20, 50, 60, 80, 90)
GROUP BY department_id
HAVING   SUM(salary) >= 50000
ORDER BY avg_salary DESC;
```

---

**[상-05] 답**

```sql
SELECT   job_id, SUM(salary) AS PAYROLL
FROM     employees
WHERE    job_id NOT LIKE '%REP%'
GROUP BY job_id
HAVING   SUM(salary) > 13000
ORDER BY SUM(salary);
```

**(1) 처리 순서:**

```
1. FROM     → employees 테이블에서 데이터 읽기
2. WHERE    → job_id NOT LIKE '%REP%' 조건으로 행 필터링 (REP 포함 직무 제외)
3. GROUP BY → job_id별로 남은 행을 그룹화
4. HAVING   → SUM(salary) > 13000인 그룹만 유지
5. SELECT   → job_id와 SUM(salary) 계산 후 PAYROLL 별칭 부여
6. ORDER BY → SUM(salary) 오름차순 정렬
```

**(2) WHERE와 HAVING의 역할 차이:**

| 구분 | WHERE | HAVING |
|------|-------|--------|
| 적용 대상 | 개별 행 (GROUP BY 이전) | 그룹 (GROUP BY 이후) |
| 그룹 함수 | 사용 불가 | 사용 가능 |
| 이 쿼리에서 | 'REP' 직무를 제외 (행 필터) | 급여 합계 13,000 이하 직무 제외 (그룹 필터) |

**(3) 예상 결과 (HR 데이터 기준):**

REP 계열 직무(SA_REP, SA_MAN 등)를 제외한 나머지 직무 중, 급여 합계가 13,000 초과인 직무 목록이 급여 합계 오름차순으로 출력된다.  
예시: AC_ACCOUNT, PU_CLERK, ST_CLERK 등 여러 직무가 포함될 수 있다.

---

**[상-06] 답**

**(A) 올바름**

```sql
SELECT department_id, AVG(salary)
FROM   employees
GROUP BY department_id
HAVING AVG(salary) > 8000;
```

부서별 평균 급여를 구하고 HAVING으로 그룹 필터링. 정상 실행된다.

**(B) 올바름**

```sql
SELECT department_id, AVG(salary)
FROM   employees
WHERE  salary > 3000
GROUP BY department_id;
```

먼저 개별 행을 salary > 3000으로 필터링한 후 부서별 평균 계산. 정상 실행된다.

**(C) 오류: ORA-00979**

```sql
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY department_id;  -- job_id가 GROUP BY에 없음!
```

SELECT에 `job_id`가 있지만 GROUP BY에 포함되지 않았다.  
수정: `GROUP BY department_id, job_id`

**(D) 올바름**

```sql
SELECT MAX(AVG(salary))
FROM   employees
GROUP BY department_id;
```

그룹 함수 중첩(2단계)으로 Oracle에서 유효하다.

**정리:** 올바른 것 → **(A), (B), (D)** / 오류 → **(C)**

---

**[상-07] 답**

```sql
SELECT   department_id,
         COUNT(*)             AS total,
         COUNT(commission_pct) AS with_comm,
         COUNT(*) - COUNT(commission_pct) AS no_comm,
         ROUND(AVG(NVL(commission_pct, 0)), 4) AS avg_comm
FROM     employees
GROUP BY department_id
HAVING   COUNT(*) >= 5
ORDER BY department_id;
```

**(1) 부서 80 (34명, 모두 commission_pct 있음):**

| department_id | total | with_comm | no_comm | avg_comm |
|--------------|-------|-----------|---------|----------|
| 80 | 34 | 34 | 0 | ~0.2500 |

> 모두 commission_pct가 있으므로 no_comm=0, avg_comm은 34명 평균 (NVL 불필요)

**(2) 부서 50 (45명, commission_pct=NULL):**

| department_id | total | with_comm | no_comm | avg_comm |
|--------------|-------|-----------|---------|----------|
| 50 | 45 | 0 | 45 | 0.0000 |

> 모두 NULL이므로 with_comm=0, no_comm=45, NVL로 0 대체하여 avg_comm=0

**(3) 부서 90 (3명 → HAVING 조건 불충족):**

COUNT(*) = 3 < 5 이므로 HAVING `COUNT(*) >= 5` 조건에서 제외되어 **결과에 포함되지 않는다.**

---

**[상-08] 답**

```sql
SELECT   manager_id,
         COUNT(*)              AS sub_count,
         ROUND(AVG(salary))    AS avg_salary,
         MIN(salary)           AS min_salary,
         MAX(salary)           AS max_salary
FROM     employees
WHERE    manager_id IS NOT NULL
GROUP BY manager_id
HAVING   COUNT(*) >= 2
     AND AVG(salary) >= 8000
ORDER BY avg_salary DESC;
```

**각 절의 역할:**
- `WHERE manager_id IS NOT NULL`: 관리자가 없는 행 제외 (행 필터)
- `GROUP BY manager_id`: 관리자별 그룹화
- `HAVING COUNT(*) >= 2`: 부하 직원 2명 이상인 그룹만
- `HAVING AVG(salary) >= 8000`: 평균 급여 8,000 이상인 그룹만

---

**[상-09] 답**

**오류 원인:**

```sql
SELECT department_id, last_name, AVG(salary)
FROM   employees;
-- ORA-00937: not a single-group group function
```

`AVG(salary)`는 그룹 함수이고, `department_id`와 `last_name`은 일반 열이다.  
GROUP BY 없이 그룹 함수와 일반 열을 혼용하면 Oracle은 어떤 그룹을 기준으로 AVG를 계산해야 할지 알 수 없어 오류를 발생시킨다.

**수정 방법 1: GROUP BY 추가**

```sql
SELECT   department_id, last_name, AVG(salary)
FROM     employees
GROUP BY department_id, last_name;
```

> 이 경우 사원마다 고유한 last_name을 가지므로 결과는 107행 — 의미 없는 집계가 될 수 있다.

**수정 방법 2: 분석 목적에 맞게 재작성**

부서별 평균 급여를 구하려면:
```sql
SELECT   department_id, AVG(salary)
FROM     employees
GROUP BY department_id;
```

개인 급여와 부서 평균을 같이 보려면 서브쿼리 또는 분석 함수 사용:
```sql
SELECT department_id, last_name, salary,
       AVG(salary) OVER (PARTITION BY department_id) AS dept_avg
FROM   employees;
```

---

**[상-10] 답**

```sql
SELECT   TO_CHAR(hire_date, 'YYYY')    AS hire_year,
         COUNT(*)                       AS emp_count,
         ROUND(AVG(salary))             AS avg_salary,
         MAX(salary)                    AS max_salary,
         MIN(salary)                    AS min_salary,
         COUNT(commission_pct)          AS with_comm
FROM     employees
GROUP BY TO_CHAR(hire_date, 'YYYY')
HAVING   COUNT(*) >= 5
ORDER BY hire_year;
```

**쿼리 설명:**
- `GROUP BY TO_CHAR(hire_date, 'YYYY')`: 입사 연도 문자열로 그룹화
- `COUNT(commission_pct)`: NULL을 자동 제외하여 commission_pct가 있는 사원 수 계산
- `HAVING COUNT(*) >= 5`: 해당 연도 사원 수가 5명 이상인 연도만 포함
- `ORDER BY hire_year`: 입사 연도 오름차순 정렬
