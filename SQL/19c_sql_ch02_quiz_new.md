# Oracle Database 19c: SQL Workshop
## Chapter 2 — SQL SELECT 문으로 데이터 조회 | 연습문제

> **사용 스키마:** HR (Human Resources)  
> **주요 테이블:** EMPLOYEES, DEPARTMENTS, JOBS, JOB_HISTORY, LOCATIONS, COUNTRIES, REGIONS

### HR 스키마 주요 구조 참고

| 테이블 | 주요 컬럼 |
|--------|----------|
| EMPLOYEES | employee_id, first_name, last_name, email, hire_date, job_id, salary, commission_pct, manager_id, department_id |
| DEPARTMENTS | department_id, department_name, manager_id, location_id |
| JOBS | job_id, job_title, min_salary, max_salary |

---

# ★ 하 (기초) — 20문제

---

**[하-01]** SQL 문의 작성 규칙으로 옳지 **않은** 것을 고르시오.

① SQL 문은 대소문자를 구분하지 않는다  
② SELECT 키워드는 SELECT, select, Select 모두 사용 가능하다  
③ SQL 키워드(예: SELECT, FROM)는 두 줄에 나누어 작성할 수 있다  
④ 가독성을 위해 들여쓰기를 사용할 수 있다

---

**[하-02]** EMPLOYEES 테이블의 모든 열을 조회하는 SQL 문을 완성하시오.

```sql
SELECT ___
FROM   employees;
```

---

**[하-03]** 다음 중 NULL 값에 대한 설명으로 **옳은** 것을 고르시오.

① NULL은 숫자 0과 동일하다  
② NULL은 빈 문자열('')과 동일하다  
③ NULL은 사용할 수 없거나 아직 알 수 없는 값이다  
④ NULL은 음수를 의미한다

---

**[하-04]** EMPLOYEES 테이블의 `commission_pct` 열은 일부 사원에게만 값이 있고 나머지는 NULL이다.  
다음 SQL 실행 시 commission_pct가 NULL인 사원의 세 번째 열 결과는?

```sql
SELECT last_name, salary, 12 * salary * commission_pct
FROM   employees;
```

---

**[하-05]** 열 별칭(Column Alias)에서 `AS` 키워드는 필수인가, 선택인가?

---

**[하-06]** DISTINCT 키워드의 역할로 올바른 것을 고르시오.

① 결과를 오름차순으로 정렬한다  
② 결과에서 중복된 행을 제거한다  
③ NULL 값만 제거한다  
④ 조회 결과 행의 수를 10개로 제한한다

---

**[하-07]** `DESCRIBE employees` 명령어의 올바른 축약형은?

① `DES employees`  
② `DESC employees`  
③ `DESCR employees`  
④ `DE employees`

---

**[하-08]** Oracle에서 테이블 없이 표현식이나 함수 결과를 조회할 때 FROM 절에 사용하는 특수 테이블명은?

---

**[하-09]** 열 별칭에 공백이 포함될 경우 반드시 사용해야 하는 기호는?

① 단일 따옴표 `'`  
② 큰따옴표 `"`  
③ 대괄호 `[]`  
④ 역따옴표 `` ` ``

---

**[하-10]** Oracle에서 두 문자열을 연결하는 연산자는?

---

**[하-11]** 다음 중 산술 연산에서 우선순위가 가장 높은 연산자는?

① `+` (더하기)  
② `-` (빼기)  
③ `*` (곱하기)  
④ 모두 동일하다

---

**[하-12]** SELECT 문을 구성하는 **필수** 절 두 가지는?

---

**[하-13]** 리터럴 문자열에서 날짜와 문자 값은 어떤 따옴표로 감싸야 하는가?

① 큰따옴표 `"`  
② 단일 따옴표 `'`  
③ 역따옴표 `` ` ``  
④ 따옴표 없이 사용

---

**[하-14]** `DESCRIBE employees` 실행 결과로 확인할 수 **없는** 정보는?

① 열 이름 (Column Name)  
② 데이터 타입 (Data Type)  
③ NULL 허용 여부  
④ 현재 저장된 데이터 값

---

**[하-15]** 다음 SQL 문에서 빈칸에 들어갈 올바른 키워드는?

```sql
SELECT ___ department_id
FROM   employees;
```

(EMPLOYEES에 실제 배정된 부서는 11개다. 중복 없이 고유한 부서 ID만 조회하고 싶다.)

---

**[하-16]** 다음 SQL 문의 실행 목적으로 올바른 것은?

```sql
SELECT *
FROM   dual;
```

① EMPLOYEES 테이블의 모든 데이터를 조회한다  
② Oracle이 자동 생성한 단일 행·단일 열 테이블의 내용을 조회한다  
③ 데이터베이스의 모든 테이블 목록을 조회한다  
④ 오류가 발생한다

---

**[하-17]** Oracle에서 `'Department's Budget'` 처럼 단일 따옴표가 포함된 문자열을 간편하게 처리하는 대체 따옴표 연산자는?

---

**[하-18]** 다음 중 SQL Developer에서 열 머리글의 기본 표시 방식으로 올바른 것은?

① 소문자, 왼쪽 정렬  
② 대문자, 왼쪽 정렬  
③ 대문자, 오른쪽 정렬  
④ 소문자, 오른쪽 정렬

---

**[하-19]** 다음 SQL 문에서 세 번째 열의 열 머리글 이름은 무엇인가?

```sql
SELECT last_name, salary, salary + 300
FROM   employees;
```

---

**[하-20]** 아래 보기 중 EMPLOYEES 테이블에서 `last_name`과 `salary` **두 열만** 조회하는 올바른 SQL은?

① `SELECT * FROM employees;`  
② `SELECT last_name, salary FROM employees;`  
③ `SELECT ALL FROM employees;`  
④ `SELECT last_name salary FROM employees;`

---

# ★★ 중 (응용) — 20문제

---

**[중-01]** EMPLOYEES 테이블에서 `last_name`, `job_id`, `hire_date` 세 열을 조회하는 SQL 문을 작성하시오.

---

**[중-02]** 다음 두 SQL 문의 결과 차이를 설명하시오.

```sql
-- (A)
SELECT last_name, salary, 12 * salary + 100
FROM   employees;

-- (B)
SELECT last_name, salary, 12 * (salary + 100)
FROM   employees;
```

Steven King의 salary = 24,000일 때, 각 SQL의 세 번째 열 결과값을 계산하시오.

---

**[중-03]** EMPLOYEES 테이블에서 `department_id`의 고유값(중복 없이)만 조회하는 SQL 문을 작성하시오.

---

**[중-04]** 다음 SQL 문에서 잘못된 부분을 찾아 수정하시오.

```sql
SELECT last_name, salary Annual Salary
FROM   employees;
```

---

**[중-05]** EMPLOYEES 테이블에서 `last_name`을 `"사원명"`, `salary * 12`를 `"연봉"`이라는 한글 별칭으로 조회하는 SQL 문을 작성하시오.

---

**[중-06]** EMPLOYEES 테이블에서 `last_name`과 `job_id`를 ` is a ` 문자열로 연결하여 `"Employee Details"` 별칭으로 조회하는 SQL 문을 Oracle 연결 연산자(`||`)를 사용하여 작성하시오.

---

**[중-07]** 다음 SQL 문의 실행 결과에서 세 번째 열(`bonus`)에 표시되는 값은 무엇인가? 이유도 함께 설명하시오.

```sql
SELECT last_name, salary, 12 * salary * commission_pct AS bonus
FROM   employees
WHERE  last_name = 'King';
```

(Steven King: salary=24000, commission_pct=NULL)

---

**[중-08]** Oracle의 `dual` 테이블을 이용하여 현재 시스템 날짜(SYSDATE)를 조회하는 SQL 문을 작성하시오.

---

**[중-09]** 다음 SQL 문에서 오류가 발생하는 원인을 설명하고 올바르게 수정하시오.

```sql
SELECT last_name, salary, salary + 300
FORM   employees;
```

---

**[중-10]** EMPLOYEES 테이블에서 월급에 12를 곱하고 `annual_sal`이라는 열 별칭을 붙여 조회하는 SQL 문을 `AS` 키워드를 사용하여 작성하시오.

---

**[중-11]** 다음 SQL 문의 결과로 올바른 것을 고르시오.

```sql
SELECT 100 + NULL
FROM   dual;
```

① 100  
② 0  
③ NULL  
④ 오류 발생

---

**[중-12]** EMPLOYEES 테이블의 구조를 확인하는 명령어를 두 가지 형식으로 작성하시오.

---

**[중-13]** 다음 SQL 문의 실행 결과에서 각 열의 **열 머리글** 이름을 쓰시오.

```sql
SELECT last_name "Employee Name",
       salary * 12 annual_sal,
       department_id
FROM   employees;
```

---

**[중-14]** DEPARTMENTS 테이블에서 `q''` 대체 따옴표 연산자를 활용하여 아래 출력 형식으로 조회하는 SQL 문을 작성하시오.

출력 예시:
```
Administration Department's Location: 1700
Marketing Department's Location: 1800
```

---

**[중-15]** 다음 SQL 문의 실행 결과 행(row) 수는 몇 개인가? 이유를 설명하시오.

```sql
SELECT DISTINCT job_id
FROM   employees;
```

(EMPLOYEES 테이블: 총 107행, 고유한 job_id는 19가지)

---

**[중-16]** 열 별칭에 큰따옴표(`"`)가 **반드시** 필요한 경우를 모두 고르시오.

① `AS name`  
② `AS "Annual Salary"`  
③ `AS employee_name`  
④ `AS "이름"`  
⑤ `AS "Name"` (대소문자를 정확히 표시해야 할 때)

---

**[중-17]** JOBS 테이블에서 `job_title`과 `max_salary - min_salary`를 `salary_range` 별칭으로 조회하는 SQL 문을 작성하시오.

---

**[중-18]** 다음 두 SQL 문의 결과 행 수 차이를 설명하시오.

```sql
-- (A)
SELECT department_id FROM employees;

-- (B)
SELECT DISTINCT department_id FROM employees;
```

(EMPLOYEES 테이블: 총 107행, 고유 department_id 값은 NULL 포함 12개)

---

**[중-19]** EMPLOYEES 테이블에서 `first_name`과 `last_name`을 공백으로 연결하여 `"Full Name"` 별칭으로, `salary`를 `"월급"` 별칭으로 조회하는 SQL 문을 작성하시오.

---

**[중-20]** 다음 SQL 문을 실행했을 때 출력 결과를 예측하고, `dual` 테이블의 특성을 설명하시오.

```sql
SELECT 'Hello, Oracle!' AS greeting,
       SYSDATE          AS today
FROM   dual;
```

---

# ★★★ 상 (심화) — 10문제

---

**[상-01]** 아래 SQL 문의 각 열에 출력될 값을 예측하고 이유를 설명하시오.

```sql
SELECT last_name,
       salary,
       salary + NULL      AS col1,
       salary * 0         AS col2,
       0 / salary         AS col3
FROM   employees
WHERE  last_name = 'King';
```

(Steven King: salary = 24,000)

---

**[상-02]** 다음 SQL 문에는 **여러 개의 오류**가 포함되어 있다. 모든 오류를 찾아 올바르게 수정하시오.

```sql
SELCT last_name "Employee Name, salary*12 "Annual Salary", commission_pct comm pct
FORM  employees;
```

---

**[상-03]** EMPLOYEES 테이블에서 다음 요구사항을 모두 충족하는 SQL 문을 작성하시오.

- `employee_id`를 `"사번"`, `first_name || ' ' || last_name`을 `"성명"` 별칭으로 출력
- `salary`를 `"기본급"`, `salary * 12`를 `"연봉"` 별칭으로 출력
- `commission_pct`를 `"커미션율"` 별칭으로 출력
- `job_id`를 `"직무코드"` 별칭으로 출력

---

**[상-04]** 다음 SQL 문에서 열 별칭 `annual_sal`을 WHERE 절에서 참조하면 오류가 발생한다.  
SQL의 **논리적 처리 순서** 관점에서 오류 원인을 설명하고, 올바른 해결 방법을 제시하시오.

```sql
-- 오류 발생 SQL
SELECT salary * 12 AS annual_sal
FROM   employees
WHERE  annual_sal > 100000;
```

---

**[상-05]** `SELECT *`와 필요한 열만 명시하는 방식을 **실무 관점**에서 비교하시오.  
성능, 유지보수, 가독성, 네트워크 트래픽 측면에서 각각 분석하시오.

---

**[상-06]** EMPLOYEES 테이블에서 `commission_pct`가 NULL인 사원이 다수 존재한다.  
HR 팀은 `12 * salary * commission_pct`로 연간 커미션을 계산하려 했으나 NULL이 출력되었다.

(1) NULL이 출력되는 원인을 설명하시오.  
(2) 커미션이 없는 사원(NULL)은 0으로 처리하여 연간 커미션을 계산하는 SQL 문을 작성하시오.  
(힌트: `NVL(값, NULL일_때_대체값)`)

---

**[상-07]** 아래 두 SQL 문의 출력 결과 열의 수와 행의 수를 비교하고, 차이가 발생하는 이유를 설명하시오.

```sql
-- (A)
SELECT employee_id, department_id
FROM   employees;

-- (B)
SELECT DISTINCT department_id
FROM   employees;
```

(EMPLOYEES 테이블: 총 107행, 고유 department_id 12개)

---

**[상-08]** DEPARTMENTS 테이블에서 아래 형식으로 출력하는 SQL 문을  
Oracle의 `q''` 대체 따옴표 연산자를 사용하여 작성하시오.

출력 예시:
```
Administration Department's Manager ID is: 200
Marketing Department's Manager ID is: 201
Purchasing Department's Manager ID is: 114
```

---

**[상-09]** 다음은 신입 개발자가 작성한 SQL 문이다.  
코드 리뷰 관점에서 문제점을 지적하고, 개선된 SQL 문을 작성하시오.

```sql
select * from EMPLOYEES;
select * from DEPARTMENTS;
select * from JOBS;
```

개선 기준: ① 필요한 열만 조회 ② 열 별칭 활용 ③ SQL 작성 관례 준수 ④ 업무 목적에 맞는 열 구성

---

**[상-10]** 아래 SQL 문을 분석하여 다음 물음에 답하시오.

```sql
SELECT employee_id                               AS "사번",
       first_name || ' ' || last_name            AS "성명",
       job_id                                    AS "직무",
       salary                                    AS "기본급",
       salary * NVL(commission_pct, 0) * 12      AS "연간커미션",
       salary * 12 + salary * NVL(commission_pct, 0) * 12 AS "총연봉"
FROM   employees;
```

(1) 이 SQL 문이 출력하는 열의 수와 예상 행의 수를 쓰시오.  
(2) Steven King(salary=24000, commission_pct=NULL)의 각 열 출력값을 계산하시오.  
(3) John Russell(salary=14000, commission_pct=0.4)의 각 열 출력값을 계산하시오.  
(4) `NVL(commission_pct, 0)`을 사용하지 않으면 어떤 문제가 발생하는지 설명하시오.
