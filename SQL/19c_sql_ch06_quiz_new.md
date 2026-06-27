# Oracle Database 19c: SQL Workshop
## Chapter 6 — 그룹 함수 | 연습문제

> **사용 스키마:** HR (Human Resources)  
> **범위:** 그룹 함수(COUNT/AVG/SUM/MIN/MAX), DISTINCT, NULL 처리, GROUP BY, 다중 열 GROUP BY, 잘못된 쿼리, HAVING, 처리 순서, 그룹 함수 중첩

---

# ★ 하 (기초) — 20문제

---

**[하-01]** 그룹 함수의 특성으로 올바른 것은?

① 각 행에 대해 실행되어 행마다 하나의 결과를 반환한다  
② 행의 집합(그룹)에 대해 실행되어 그룹당 하나의 결과를 반환한다  
③ 두 개 이상의 인수가 항상 필요하다  
④ WHERE 절에서만 사용할 수 있다

---

**[하-02]** `COUNT(*)` 와 `COUNT(commission_pct)` 의 차이는?

① 두 함수는 항상 같은 결과를 반환한다  
② `COUNT(*)`는 NULL을 포함한 전체 행, `COUNT(commission_pct)`는 NULL을 제외한 행 수  
③ `COUNT(*)`는 NULL만 카운트한다  
④ `COUNT(commission_pct)`가 항상 더 크다

---

**[하-03]** HR 스키마에서 다음 SQL의 결과는?

```sql
SELECT COUNT(*)
FROM   employees;
```

① `35`  
② `45`  
③ `107`  
④ `27`

---

**[하-04]** 그룹 함수에서 NULL 값은 어떻게 처리되는가?

① 0으로 대체되어 계산에 포함된다  
② 자동으로 무시(제외)된다  
③ 오류를 발생시킨다  
④ NULL로 반환된다

---

**[하-05]** 다음 SQL 문 중 오류가 발생하는 것은?

① `SELECT MAX(salary) FROM employees;`  
② `SELECT department_id, MAX(salary) FROM employees GROUP BY department_id;`  
③ `SELECT department_id, MAX(salary) FROM employees;`  
④ `SELECT AVG(salary) FROM employees WHERE job_id LIKE '%REP%';`

---

**[하-06]** GROUP BY 절의 사용 규칙으로 올바른 것은?

① SELECT 목록의 모든 열을 GROUP BY에 포함해야 한다  
② GROUP BY에 포함된 열만 SELECT에 사용할 수 있다  
③ SELECT 목록에서 그룹 함수가 아닌 모든 열은 반드시 GROUP BY에 포함해야 한다  
④ GROUP BY 절은 WHERE 절 이후에 작성할 수 없다

---

**[하-07]** 다음 SQL 문의 결과는?

```sql
SELECT AVG(commission_pct)
FROM   employees;
```

① commission_pct가 NULL인 모든 사원 포함 평균  
② commission_pct가 NULL이 아닌 사원(35명)만 포함 평균  
③ 0을 반환한다  
④ 오류 발생

---

**[하-08]** HAVING 절에 대한 설명으로 올바른 것은?

① WHERE 절의 대체 구문이다  
② 개별 행을 필터링하는 데 사용된다  
③ GROUP BY 이후 그룹 함수 기준으로 그룹을 필터링한다  
④ ORDER BY 절 다음에 작성해야 한다

---

**[하-09]** WHERE 절에서 그룹 함수를 사용하면 어떻게 되는가?

① 정상적으로 실행된다  
② ORA-00934 오류 발생  
③ 결과는 같지만 성능이 저하된다  
④ HAVING과 동일한 결과를 반환한다

---

**[하-10]** 다음 SQL 문에서 빈칸에 들어갈 절은?

```sql
SELECT   department_id, AVG(salary)
FROM     employees
GROUP BY department_id
_____    AVG(salary) > 8000;
```

① `WHERE`  
② `HAVING`  
③ `AND`  
④ `ORDER BY`

---

**[하-11]** `COUNT(DISTINCT department_id)` 의 결과로 올바른 것은? (HR 스키마 기준)

① 107  
② 27  
③ 11  
④ 12

---

**[하-12]** 다음 SQL 처리 순서로 올바른 것은?

```sql
SELECT department_id, AVG(salary)
FROM   employees
WHERE  salary > 5000
GROUP BY department_id
HAVING AVG(salary) > 8000
ORDER BY AVG(salary) DESC;
```

① SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY  
② FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY  
③ FROM → GROUP BY → WHERE → HAVING → SELECT → ORDER BY  
④ WHERE → FROM → GROUP BY → SELECT → HAVING → ORDER BY

---

**[하-13]** `MIN(last_name)` 의 결과는 무엇인가? (문자 데이터에 MIN 적용)

① 오류 발생 — MIN은 숫자에만 사용 가능  
② last_name이 가장 짧은 사원  
③ 알파벳 순서로 가장 앞에 오는 last_name  
④ NULL 값

---

**[하-14]** 다음 중 그룹 함수 중첩이 가능한 것은?

① `SUM(SUM(salary))`  
② `MAX(AVG(salary))`  
③ `AVG(COUNT(*))`  
④ `MIN(MAX(salary))`

---

**[하-15]** GROUP BY 절에서 그룹화하는 열은 반드시 SELECT 목록에 있어야 하는가?

① 예, 반드시 SELECT 목록에 있어야 한다  
② 아니오, GROUP BY 열은 SELECT 목록에 없어도 된다  
③ SELECT 별칭으로 대체할 수 있다  
④ 첫 번째 열만 SELECT에 있어야 한다

---

**[하-16]** 다음 SQL 문의 오류를 설명하시오.

```sql
SELECT department_id, job_id, COUNT(last_name)
FROM   employees
GROUP BY department_id;
```

---

**[하-17]** SUM 함수는 어떤 데이터 타입에 사용 가능한가?

① 숫자 타입만 가능  
② 문자 타입만 가능  
③ 숫자, 문자, 날짜 모두 가능  
④ 날짜 타입만 가능

---

**[하-18]** 다음 두 쿼리의 결과가 다른 이유는?

```sql
-- (A)
SELECT AVG(commission_pct) FROM employees;

-- (B)
SELECT AVG(NVL(commission_pct, 0)) FROM employees;
```

---

**[하-19]** 부서별 사원 수를 구하는 올바른 SQL은?

① `SELECT COUNT(*) FROM employees;`  
② `SELECT department_id, COUNT(*) FROM employees GROUP BY department_id;`  
③ `SELECT department_id, COUNT(*) FROM employees;`  
④ `SELECT COUNT(department_id) FROM employees GROUP BY department_id;`

---

**[하-20]** MAX 함수의 결과로 NULL이 반환되는 경우는?

① 테이블에 행이 없을 때  
② 테이블에 행이 있고 모두 NULL인 경우  
③ WHERE 조건으로 행이 없을 때  
④ 위의 모든 경우

---

# ★★ 중 (응용) — 20문제

---

**[중-01]** EMPLOYEES 테이블에서 전체 사원의 최대 급여, 최소 급여, 평균 급여(소수 2자리 반올림), 급여 합계를 출력하시오.

---

**[중-02]** EMPLOYEES 테이블에서 직무에 'REP'가 포함된 사원들의 급여 통계(AVG, MAX, MIN, SUM)를 조회하시오.

---

**[중-03]** EMPLOYEES 테이블에서 전체 사원 수(COUNT(*))와 commission_pct가 있는 사원 수를 함께 출력하시오.

---

**[중-04]** EMPLOYEES 테이블에서 부서별 사원 수를 내림차순으로 정렬하여 출력하시오.

---

**[중-05]** EMPLOYEES 테이블에서 부서별 평균 급여를 출력하되, NULL 부서도 포함하시오.

---

**[중-06]** EMPLOYEES 테이블에서 직무(job_id)별 급여 합계를 구하되, 급여 합계가 10,000 초과인 직무만 출력하시오.

---

**[중-07]** EMPLOYEES 테이블에서 부서별로 최소 입사일과 최대 입사일을 출력하시오.

---

**[중-08]** EMPLOYEES 테이블에서 부서별 평균 급여를 출력하되, 평균 급여를 내림차순으로 정렬하시오.

---

**[중-09]** EMPLOYEES 테이블에서 부서(department_id)와 직무(job_id)를 기준으로 그룹화하여 급여 합계를 출력하시오.  
(department_id > 40인 부서만, 부서 번호 오름차순 정렬)

---

**[중-10]** EMPLOYEES 테이블에서 가장 낮은 급여를 받는 직무(job_id)를 찾으시오.  
(힌트: MIN(salary)를 job_id로 그룹화)

---

**[중-11]** EMPLOYEES 테이블에서 최대 급여가 10,000 초과인 부서의 department_id와 최대 급여를 출력하시오.  
(HAVING 사용)

---

**[중-12]** EMPLOYEES 테이블에서 급여 합계가 13,000 초과인 직무를 출력하시오.  
단, 'REP'가 포함된 직무는 제외한다.  
급여 합계 오름차순으로 정렬

---

**[중-13]** EMPLOYEES 테이블에서 사원 수가 5명 이상인 부서의 department_id와 사원 수를 출력하시오.

---

**[중-14]** EMPLOYEES 테이블에서 직무별 사원 수를 출력하되, 사원 수가 3명 이상인 직무만 표시하시오.  
사원 수 내림차순 정렬

---

**[중-15]** EMPLOYEES 테이블에서 부서별 평균 급여를 구하되 NULL인 commission_pct를 0으로 대체하여 포함한 연봉 평균을 계산하시오.  
(`(salary*12) + (salary*12*NVL(commission_pct,0))` 의 평균)

---

**[중-16]** EMPLOYEES 테이블에서 부서별로 고유한 직무(job_id)의 수를 출력하시오.  
(COUNT DISTINCT 사용)

---

**[중-17]** EMPLOYEES 테이블에서 부서별 최소 급여가 5,000 이상인 부서의 department_id와 최소 급여를 출력하시오.

---

**[중-18]** EMPLOYEES 테이블에서 manager_id별 부하 직원 수를 출력하되, 부하 직원이 3명 이상인 경우만 표시하시오.  
(manager_id가 NULL인 경우 제외)

---

**[중-19]** EMPLOYEES 테이블에서 부서 번호가 50, 60, 80인 부서만 대상으로, 부서별 평균 급여를 출력하시오.

---

**[중-20]** EMPLOYEES 테이블에서 입사 연도별 사원 수를 출력하시오.  
(TO_CHAR(hire_date, 'YYYY') 활용, 입사 연도 오름차순 정렬)

---

# ★★★ 상 (심화) — 10문제

---

**[상-01]** 다음 SQL 문의 오류를 모두 찾아 수정하시오.

```sql
SELECT department_id, job_id, AVG(salary), COUNT(*)
FROM   employees
WHERE  AVG(salary) > 5000
GROUP BY department_id;
```

---

**[상-02]** 다음 두 SQL 문의 결과 행 수를 비교하고 차이를 설명하시오.

```sql
-- (A)
SELECT department_id, COUNT(*)
FROM   employees
WHERE  salary > 5000
GROUP BY department_id;

-- (B)
SELECT department_id, COUNT(*)
FROM   employees
GROUP BY department_id
HAVING AVG(salary) > 5000;
```

---

**[상-03]** EMPLOYEES 테이블에서 부서별 평균 급여 중 최대값(가장 높은 평균 급여를 가진 부서의 평균)을 구하시오.  
(그룹 함수 중첩 사용)

---

**[상-04]** EMPLOYEES 테이블에서 다음 조건을 모두 만족하는 결과를 출력하시오.

- 부서 번호가 20, 50, 60, 80, 90 중 하나
- 해당 부서의 급여 합계가 50,000 이상
- 출력 열: department_id, 사원 수, 평균 급여(정수), 최대 급여, 최소 급여, 급여 합계
- 평균 급여 내림차순 정렬

---

**[상-05]** 다음 SQL 문을 분석하여 각 절의 처리 순서와 역할을 설명하시오.

```sql
SELECT   job_id, SUM(salary) AS PAYROLL
FROM     employees
WHERE    job_id NOT LIKE '%REP%'
GROUP BY job_id
HAVING   SUM(salary) > 13000
ORDER BY SUM(salary);
```

(1) 각 절이 처리되는 순서를 나열하시오.  
(2) WHERE와 HAVING의 역할 차이를 설명하시오.  
(3) 이 쿼리의 예상 결과를 HR 데이터 기준으로 예측하시오.

---

**[상-06]** 다음 SQL 문 중 올바른 것을 모두 고르고, 나머지의 오류를 설명하시오.

```sql
-- (A)
SELECT department_id, AVG(salary)
FROM   employees
GROUP BY department_id
HAVING AVG(salary) > 8000;

-- (B)
SELECT department_id, AVG(salary)
FROM   employees
WHERE  salary > 3000
GROUP BY department_id;

-- (C)
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY department_id;

-- (D)
SELECT MAX(AVG(salary))
FROM   employees
GROUP BY department_id;
```

---

**[상-07]** EMPLOYEES 테이블에서 다음 조건의 결과를 예측하시오.

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

(1) 부서 80의 결과를 예측하시오. (부서 80: 34명, 모두 commission_pct 있음)  
(2) 부서 50의 결과를 예측하시오. (부서 50: 45명, commission_pct=NULL)  
(3) 부서 90의 결과를 예측하시오. (부서 90: 3명 → HAVING 조건 불충족)

---

**[상-08]** 다음 비즈니스 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항: "관리자별로 부하 직원의 급여 정보를 조회한다. 단, 관리자 자신이 없는 경우(manager_id=NULL) 제외하고, 부하 직원이 최소 2명 이상인 경우만 표시하며, 평균 급여가 8,000 이상인 관리자만 포함한다."

출력 열: manager_id, 부하 직원 수, 평균 급여(정수 반올림), 최소 급여, 최대 급여  
정렬: 평균 급여 내림차순

---

**[상-09]** GROUP BY 없이 그룹 함수와 일반 열을 혼용하면 왜 오류가 발생하는지 설명하고, 올바른 해결 방법을 제시하시오.

아래 잘못된 쿼리를 수정하시오:
```sql
SELECT department_id, last_name, AVG(salary)
FROM   employees;
```

---

**[상-10]** 다음 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항:
- EMPLOYEES 테이블에서 입사 연도(TO_CHAR(hire_date, 'YYYY'))별 통계를 출력
- 각 연도의 사원 수, 평균 급여(정수), 최고 급여, 최저 급여
- commission_pct가 있는 사원 수
- 입사 연도 오름차순 정렬
- 사원 수가 5명 이상인 연도만 포함
