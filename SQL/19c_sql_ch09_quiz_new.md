# Oracle Database 19c: SQL Workshop
## Chapter 9 — 집합 연산자 사용 | 연습문제 (50문제)

> **구성:** 하(기초) 20문제 + 중(응용) 20문제 + 상(심화) 10문제

---

## 하(기초) — 20문제

---

**[1번]** 집합 연산자 중 두 쿼리의 결과를 합치되 **중복 행을 제거**하는 연산자는?

① UNION ALL  
② UNION  
③ INTERSECT  
④ MINUS

---

**[2번]** 집합 연산자 중 두 쿼리의 결과를 합치되 **중복 행을 포함**하는 연산자는?

① UNION  
② UNION ALL  
③ INTERSECT  
④ MINUS

---

**[3번]** 집합 연산자 중 두 쿼리 결과에 **공통으로 존재하는 행만** 반환하는 연산자는?

① UNION  
② UNION ALL  
③ INTERSECT  
④ MINUS

---

**[4번]** 집합 연산자 중 **첫 번째 쿼리 결과에만 있고 두 번째에는 없는 행**을 반환하는 연산자는?

① UNION  
② INTERSECT  
③ MINUS  
④ UNION ALL

---

**[5번]** 집합 연산자 사용 시 두 SELECT 문이 반드시 일치해야 하는 것은?

① 테이블 이름  
② WHERE 조건  
③ 열 개수와 대응되는 열의 데이터 타입  
④ 열 이름

---

**[6번]** 집합 연산자를 사용한 복합 쿼리에서 결과의 열 이름은 어느 쿼리에서 결정되는가?

① 마지막 SELECT 쿼리  
② 첫 번째 SELECT 쿼리  
③ 행이 더 많은 쿼리  
④ 알파벳 순서

---

**[7번]** UNION을 사용할 때 기본 정렬 순서는?

① 내림차순  
② 입력 순서  
③ 오름차순  
④ 무작위

---

**[8번]** UNION ALL의 결과가 UNION보다 더 많은 행을 반환하는 이유는?

① 더 많은 테이블을 참조하기 때문  
② 중복 행을 제거하지 않기 때문  
③ WHERE 조건이 없기 때문  
④ 열 개수가 더 많기 때문

---

**[9번]** 다음 중 집합 연산자의 올바른 설명은?

① UNION은 중복을 포함한다  
② INTERSECT는 차집합이다  
③ MINUS는 교집합이다  
④ UNION ALL은 중복을 포함한다

---

**[10번]** 집합 연산자를 사용한 복합 쿼리에서 ORDER BY 절은 어디에 위치해야 하는가?

① 첫 번째 SELECT 문 끝  
② 모든 SELECT 문 끝  
③ 복합 쿼리의 맨 끝 (마지막 SELECT 문 뒤)  
④ FROM 절 뒤

---

**[11번]** 다음 중 올바른 집합 연산자 구문은?

① `SELECT a FROM t1 UNION SELECT b, c FROM t2`  
② `SELECT a, b FROM t1 UNION SELECT c, d FROM t2`  
③ `SELECT a FROM t1 UNION ALL b FROM t2`  
④ `SELECT a, b FROM t1 UNION SELECT c FROM t2`

---

**[12번]** 두 쿼리의 열 데이터 타입을 맞추기 위해 숫자 컬럼이 없는 쪽에 사용하는 Oracle 함수는?

① `NULLIF(0, 0)`  
② `NVL(NULL, 0)`  
③ `TO_CHAR(NULL)`  
④ `COALESCE(0)`

---

**[13번]** 집합 연산자에서 ORDER BY 절은 몇 번 사용할 수 있는가?

① 각 SELECT 문마다 한 번씩  
② 복합 쿼리 전체에서 한 번만  
③ 최대 두 번  
④ 제한 없음

---

**[14번]** UNION ALL을 제외한 집합 연산자에서 중복 행이 처리되는 방식은?

① 첫 번째 행만 유지  
② 마지막 행만 유지  
③ 자동으로 제거  
④ 오류 발생

---

**[15번]** 다음 중 MINUS 연산자에 대한 설명으로 **올바른** 것은?

① 두 쿼리의 교집합을 반환한다  
② 두 쿼리 결과를 모두 포함한다  
③ 첫 번째 쿼리에만 있는 고유 행을 반환한다  
④ 두 번째 쿼리에만 있는 행을 반환한다

---

**[16번]** 집합 연산자를 사용할 때 괄호의 역할은?

① 오류를 방지한다  
② 실행 순서를 변경한다  
③ 중복을 제거한다  
④ ORDER BY 없이 정렬한다

---

**[17번]** INTERSECT 연산자로 반환된 결과에 대한 올바른 설명은?

① 두 쿼리 중 어느 하나에만 존재하는 행  
② 두 쿼리 모두에 존재하는 행  
③ 두 쿼리의 모든 행  
④ 첫 번째 쿼리의 행만

---

**[18번]** 다음 집합 연산자 중 성능이 가장 빠른 것은?

① UNION  
② INTERSECT  
③ UNION ALL  
④ MINUS

---

**[19번]** ORDER BY `2`는 무엇을 의미하는가?

① 두 번째 테이블의 기준 열  
② 결과의 두 번째 열을 기준으로 정렬  
③ 두 번째 행  
④ 두 번째 조건

---

**[20번]** 다음 중 집합 연산자 사용 시 오류가 발생하는 경우는?

① 두 쿼리의 열 이름이 다른 경우  
② 두 쿼리의 열 개수가 다른 경우  
③ WHERE 조건이 다른 경우  
④ 테이블 이름이 다른 경우

---

## 중(응용) — 20문제

---

**[21번]** 다음 SQL의 출력 결과에 대한 설명으로 올바른 것은?

```sql
SELECT job_id FROM employees
UNION ALL
SELECT job_id FROM job_history;
```

① 고유한 job_id만 반환된다  
② 중복 job_id도 모두 반환된다  
③ 오류가 발생한다  
④ job_history만 반환된다

---

**[22번]** EMPLOYEES 테이블과 JOB_HISTORY 테이블에서 **공통으로 나타나는 employee_id와 job_id**를 조회하려면 어떤 연산자를 사용해야 하는가?

① UNION  
② UNION ALL  
③ INTERSECT  
④ MINUS

---

**[23번]** 다음 SQL에서 결과의 열 이름은 무엇인가?

```sql
SELECT last_name AS "사원명", salary
FROM   employees
UNION
SELECT last_name, salary
FROM   job_history_view;
```

① `사원명`, `SALARY` — 첫 번째 쿼리 기준  
② `LAST_NAME`, `SALARY` — 원래 열 이름  
③ `사원명`, `SALARY`  
④ 오류 발생

---

**[24번]** 다음 중 EMPLOYEES에서 JOB_HISTORY에 이력이 없는 사원을 찾는 올바른 SQL은?

① `SELECT employee_id FROM employees INTERSECT SELECT employee_id FROM job_history`  
② `SELECT employee_id FROM employees MINUS SELECT employee_id FROM job_history`  
③ `SELECT employee_id FROM employees UNION SELECT employee_id FROM job_history`  
④ `SELECT employee_id FROM job_history MINUS SELECT employee_id FROM employees`

---

**[25번]** 다음 SQL의 결과로 올바른 것은?

```sql
SELECT department_id FROM employees
INTERSECT
SELECT department_id FROM departments;
```

① EMPLOYEES에 존재하지만 DEPARTMENTS에 없는 department_id  
② DEPARTMENTS에 있는 모든 department_id  
③ EMPLOYEES와 DEPARTMENTS 양쪽 모두에 있는 department_id  
④ 두 테이블의 모든 department_id

---

**[26번]** 다음 SQL에서 오류가 발생하는 이유는?

```sql
SELECT employee_id, last_name, salary
FROM   employees
UNION
SELECT employee_id, last_name
FROM   job_history;
```

① WHERE 조건 없음  
② 열 개수 불일치 (3개 vs 2개)  
③ 데이터 타입 불일치  
④ UNION은 두 테이블만 지원

---

**[27번]** 다음 SQL의 결과 행 수에 대한 설명으로 올바른 것은?

```sql
SELECT job_id FROM employees   -- 19가지 job_id, 107행
UNION
SELECT job_id FROM job_history; -- 8가지 job_id 포함
```

① 반드시 107행 반환  
② 반드시 107+모든 job_history 행 반환  
③ 두 테이블의 고유 job_id 합집합 (중복 제거)  
④ job_history 행 수만 반환

---

**[28번]** 다음 SQL에서 ORDER BY 절의 위치가 올바른 것은?

```sql
(A) SELECT job_id FROM employees ORDER BY job_id
    UNION
    SELECT job_id FROM job_history;

(B) SELECT job_id FROM employees
    UNION
    SELECT job_id FROM job_history
    ORDER BY job_id;
```

① (A)만 올바름  
② (B)만 올바름  
③ 둘 다 올바름  
④ 둘 다 잘못됨

---

**[29번]** EMPLOYEES와 DEPARTMENTS 테이블의 열 개수가 다를 때, 열 개수를 맞추기 위해 사용하는 방법은?

① 더 많은 열을 가진 테이블에서 일부 열 삭제  
② 없는 열 자리에 `TO_CHAR(NULL)` 또는 `TO_DATE(NULL)` 등 NULL 변환 사용  
③ UNION 대신 JOIN 사용  
④ 오류이므로 집합 연산 불가

---

**[30번]** 다음 SQL의 목적으로 올바른 것은?

```sql
SELECT employee_id FROM employees
MINUS
SELECT manager_id FROM employees
WHERE manager_id IS NOT NULL;
```

① 관리자인 사원 조회  
② 관리자가 아닌 사원의 employee_id 조회  
③ 모든 사원 조회  
④ 부서장만 조회

---

**[31번]** 집합 연산자로 세 개의 테이블을 결합할 때 올바른 구문 형식은?

① 집합 연산자는 두 테이블만 지원  
② `SELECT ... UNION SELECT ... UNION SELECT ...`  
③ `SELECT ... JOIN ... JOIN ...`  
④ 서브쿼리로만 가능

---

**[32번]** 다음 SQL에서 ORDER BY `1`의 의미는?

```sql
SELECT employee_id, job_id FROM employees
UNION
SELECT employee_id, job_id FROM job_history
ORDER BY 1;
```

① 1행만 반환  
② job_id(두 번째 열) 기준 정렬  
③ employee_id(첫 번째 열) 기준 오름차순 정렬  
④ 기본 정렬 해제

---

**[33번]** 다음 두 SQL의 차이점으로 올바른 것은?

```sql
-- SQL A
SELECT job_id FROM employees UNION SELECT job_id FROM job_history;
-- SQL B
SELECT job_id FROM employees UNION ALL SELECT job_id FROM job_history;
```

① A와 B의 결과가 항상 같다  
② A는 중복을 제거하고 B는 중복을 포함한다  
③ B는 오류가 발생한다  
④ A는 더 많은 행을 반환한다

---

**[34번]** 다음 SQL에서 `TO_DATE(NULL)`의 역할은?

```sql
SELECT first_name, job_id, hire_date
FROM   employees
UNION
SELECT first_name, job_id, TO_DATE(NULL)
FROM   some_table;
```

① hire_date 열의 값을 오늘 날짜로 대체  
② hire_date 열이 없는 테이블에서 DATE 타입의 NULL로 열 개수/타입 일치  
③ 오류를 발생시킴  
④ 빈 문자열로 대체

---

**[35번]** MINUS 연산자를 사용할 때 결과에 포함되는 행은?

① 두 번째 쿼리에만 있는 행  
② 첫 번째 쿼리와 두 번째 쿼리 모두에 있는 행  
③ 첫 번째 쿼리에 있지만 두 번째 쿼리에는 없는 행  
④ 두 쿼리의 모든 행

---

**[36번]** 다음 SQL의 결과로 올바른 것은?

```sql
SELECT department_id FROM employees WHERE department_id IS NOT NULL
MINUS
SELECT department_id FROM departments;
```

① 모든 부서 ID  
② EMPLOYEES에 있지만 DEPARTMENTS에 없는 department_id  
③ DEPARTMENTS에 있지만 EMPLOYEES에 없는 department_id  
④ 두 테이블 공통 department_id

---

**[37번]** ORDER BY 절에서 집합 연산자 쿼리의 별칭(alias)을 사용할 때 올바른 것은?

① 마지막 SELECT 쿼리의 별칭 사용  
② 첫 번째 SELECT 쿼리의 열 이름 또는 별칭 사용  
③ 모든 SELECT 쿼리에 동일한 별칭 필요  
④ 별칭 사용 불가, 열 번호만 가능

---

**[38번]** 다음 중 INTERSECT 연산자를 가장 잘 활용하는 상황은?

① 두 테이블의 모든 데이터를 합칠 때  
② 한 테이블에만 있는 데이터를 찾을 때  
③ 두 테이블 모두에 존재하는 공통 데이터를 찾을 때  
④ 중복 포함한 전체 목록이 필요할 때

---

**[39번]** 다음 SQL이 가능한가?

```sql
SELECT employee_id, last_name FROM employees
UNION
SELECT employee_id, last_name FROM job_history
INTERSECT
SELECT employee_id, last_name FROM departments;
```

① 불가능 — 두 연산자를 함께 사용할 수 없음  
② 가능 — 왼쪽에서 오른쪽으로 순서대로 실행됨  
③ 가능 — INTERSECT가 UNION보다 우선순위가 높아 먼저 처리됨  
④ 가능 — 괄호가 없으므로 Oracle이 자동으로 최적화

---

**[40번]** 다음 SQL의 결과 행 수에 대한 설명으로 올바른 것은?

```sql
SELECT job_id FROM employees    -- 107행
UNION ALL
SELECT job_id FROM job_history; -- 10행
```

① 최대 107행  
② 정확히 117행  
③ 최소 107행, 최대 117행  
④ 고유 job_id 수만큼

---

## 상(심화) — 10문제

---

**[41번]** 다음 SQL의 실행 결과에 대한 분석으로 **올바른** 것은?

```sql
SELECT department_id FROM departments
MINUS
SELECT department_id FROM employees WHERE department_id IS NOT NULL;
```

① 모든 부서에 사원이 존재한다면 결과는 0행  
② 결과는 항상 departments의 전체 행 수  
③ 오류 발생 — MINUS는 NULL 열에 사용 불가  
④ 모든 사원의 부서 ID 반환

---

**[42번]** 집합 연산자의 **우선순위**에 관한 설명으로 올바른 것은?

① UNION이 항상 가장 먼저 실행됨  
② INTERSECT가 UNION/UNION ALL보다 우선순위가 높음  
③ 모든 집합 연산자의 우선순위는 동일하며 괄호로 조정  
④ MINUS가 가장 낮은 우선순위

---

**[43번]** 다음 두 SQL의 결과가 **다른 경우**는 언제인가?

```sql
-- SQL X
SELECT employee_id FROM employees
MINUS
SELECT manager_id FROM employees WHERE manager_id IS NOT NULL;

-- SQL Y  
SELECT employee_id FROM employees
WHERE employee_id NOT IN (SELECT manager_id FROM employees WHERE manager_id IS NOT NULL);
```

① 항상 같다  
② manager_id에 NULL이 있을 때 SQL Y가 0행 반환 가능  
③ SQL X가 항상 더 많은 행 반환  
④ 결과는 다르지만 의미는 동일

---

**[44번]** 다음 SQL에서 오류가 발생하는 이유를 설명하시오.

```sql
SELECT employee_id, last_name, hire_date
FROM   employees
ORDER BY hire_date
UNION
SELECT employee_id, job_id, start_date
FROM   job_history;
```

① hire_date와 start_date 타입 불일치  
② ORDER BY를 첫 번째 SELECT에 사용했기 때문  
③ UNION에서 DATE 타입 미지원  
④ 열 개수 불일치

---

**[45번]** 다음 SQL의 실행 결과로 올바른 것은?

```sql
SELECT 'A' AS category, employee_id, salary FROM employees WHERE department_id = 10
UNION ALL
SELECT 'B', employee_id, salary FROM employees WHERE department_id = 20
UNION ALL
SELECT 'C', employee_id, salary FROM employees WHERE department_id = 30
ORDER BY 3 DESC;
```

① category가 알파벳 순으로 정렬됨  
② salary 내림차순으로 전체 결과 정렬됨  
③ 오류 — 리터럴 값('A', 'B', 'C')은 집합 연산에 사용 불가  
④ 세 번째 GROUP BY 기준 정렬됨

---

**[46번]** UNION을 서브쿼리에서 사용하는 다음 SQL의 결과를 분석하시오.

```sql
SELECT last_name, salary
FROM   employees
WHERE  department_id IN (
    SELECT department_id FROM departments WHERE location_id = 1700
    UNION
    SELECT department_id FROM departments WHERE location_id = 1800
);
```

① 문법 오류 — UNION은 IN 서브쿼리에 사용 불가  
② location_id가 1700 또는 1800인 부서의 사원 반환  
③ location_id가 1700이면서 1800인 부서의 사원 반환  
④ IN 절에서 UNION은 자동으로 INTERSECT로 처리됨

---

**[47번]** 다음 두 SQL의 결과 차이를 설명하시오.

```sql
-- SQL P
SELECT department_id FROM employees
INTERSECT
SELECT department_id FROM departments;

-- SQL Q
SELECT DISTINCT e.department_id
FROM   employees e
JOIN   departments d ON e.department_id = d.department_id
WHERE  e.department_id IS NOT NULL;
```

① SQL P는 오류 발생  
② 결과가 항상 동일  
③ SQL Q는 NULL 부서 사원도 포함할 수 있음  
④ SQL P가 더 많은 행 반환

---

**[48번]** 집합 연산자를 사용한 쿼리에서 **성능 최적화** 관점으로 올바른 것은?

① UNION보다 UNION ALL이 빠르므로 중복이 없음이 확실할 때 UNION ALL 선호  
② INTERSECT가 가장 빠름  
③ 집합 연산자는 항상 JOIN보다 빠름  
④ ORDER BY를 각 SELECT에 적용해야 빠름

---

**[49번]** 다음 SQL이 반환하는 결과의 의미를 바르게 설명한 것은?

```sql
SELECT job_id FROM employees
UNION
SELECT job_id FROM job_history
MINUS
SELECT job_id FROM (SELECT job_id FROM employees WHERE department_id = 50);
```

① EMPLOYEES와 JOB_HISTORY를 합한 후 부서 50의 직무를 제거한 고유 직무 목록
② EMPLOYEES의 직무에서 JOB_HISTORY 직무를 제거한 목록  
③ 오류 — 세 개의 집합 연산 불가  
④ 부서 50의 직무만 반환

---

**[50번]** 다음 상황에서 MINUS를 사용해 올바른 결과를 반환하도록 SQL을 완성하시오.

**요구사항:** JOB_HISTORY 테이블에는 있지만 현재 EMPLOYEES 테이블에는 없는 employee_id를 조회하시오.  
(즉, 회사를 퇴직한 사원의 employee_id)

```sql
SELECT employee_id FROM (  __A__  )
MINUS
SELECT employee_id FROM (  __B__  );
```

① A: `job_history`, B: `employees`  
② A: `employees`, B: `job_history`  
③ A와 B 모두 `employees`  
④ A: `job_history`, B: `job_history`
