# Oracle Database 19c: SQL Workshop
## Chapter 3 — 데이터 제한 및 정렬 | 모범답안

---

# ★ 하 (기초) 모범답안

---

**[하-01] 답: ③ FROM 절 바로 다음**

SQL 절의 순서: `SELECT → FROM → WHERE → ORDER BY`  
WHERE 절은 반드시 FROM 절 뒤에 위치한다.

---

**[하-02] 답**

```sql
SELECT employee_id, last_name, department_id
FROM   employees
WHERE  department_id = 90;
```

---

**[하-03] 답: ③ `WHERE last_name = 'King'`**

문자 값과 날짜 값은 반드시 **단일 따옴표(`'`)**로 감싼다.  
큰따옴표(`"`)는 열 별칭에만 사용한다. `'King'`은 대소문자를 구분하므로 `'king'`과 다른 결과를 반환한다.

---

**[하-04] 답: `<>` (또는 `!=`)**

Oracle에서 "같지 않다"는 `<>` 또는 `!=` 두 가지 모두 사용 가능하다.  
표준 SQL 표기는 `<>`이다.

---

**[하-05] 답: 포함한다**

`BETWEEN A AND B`는 **경계값 A와 B 모두 포함**한다.  
`WHERE salary BETWEEN 2500 AND 3500`은 salary가 2500, 3500인 행도 포함한다.  
이는 `WHERE salary >= 2500 AND salary <= 3500`과 동일하다.

---

**[하-06] 답: ②**

IN 연산자는 목록의 값 중 **하나라도** 일치하면 결과를 반환한다.  
`WHERE manager_id IN (100, 101, 201)` = `WHERE manager_id = 100 OR manager_id = 101 OR manager_id = 201`

---

**[하-07] 답**

| 와일드카드 | 의미 | 예시 |
|-----------|------|------|
| `%` | **0개 이상**의 임의 문자 | `'S%'` → S, Sa, Sam, Smith, ... |
| `_` | **정확히 1개**의 임의 문자 | `'_o%'` → 두 번째 글자가 'o'인 모든 값 |

---

**[하-08] 답: ② `WHERE manager_id IS NULL`**

NULL 값은 `= NULL`로 비교할 수 없다. NULL은 값이 없음을 의미하므로 반드시 **IS NULL** 또는 **IS NOT NULL**로 테스트한다.  
`WHERE manager_id = NULL` → 항상 0건 반환 (잘못된 구문)

---

**[하-09] 답: ②**

AND는 **두 조건이 모두 TRUE**이어야 결과를 반환한다.  
OR은 하나라도 TRUE이면 반환, NOT은 조건을 반전시킨다.

---

**[하-10] 답: ④ 산술 연산자**

연산자 우선순위 (높음 → 낮음):  
산술(+,-,*,/) → 연결(||) → 비교(=,<,>) → IS NULL/LIKE/IN → BETWEEN → NOT → AND → OR

---

**[하-11] 답: ② ASC (오름차순)**

ORDER BY의 기본 정렬은 **오름차순(ASC)**이다.  
`ORDER BY hire_date` = `ORDER BY hire_date ASC` (동일한 결과)

---

**[하-12] 답: DESC**

```sql
SELECT last_name, salary
FROM   employees
ORDER BY salary DESC;
```

---

**[하-13] 답: ③ `WHERE first_name LIKE 'S%'`**

- `'S'`: 정확히 'S'인 값만 (길이 1)
- `'S_'`: 'S'로 시작하고 두 번째 문자가 하나 있는 2글자 값
- `'S%'`: 'S'로 시작하는 모든 값 (0개 이상의 뒤 문자)
- `'%S'`: 'S'로 끝나는 값

---

**[하-14] 답: 세 번째 열 — department_id**

`ORDER BY 3`은 SELECT 절의 **세 번째 열**을 기준으로 정렬한다.  
`SELECT last_name(1), job_id(2), department_id(3), hire_date(4)` → 세 번째 열인 `department_id` 기준 정렬

---

**[하-15] 답: ③**

```sql
SELECT * FROM employees FETCH FIRST 5 ROWS ONLY;
```

- ①: SQL Server/MySQL 문법 (`TOP N`)
- ②: ROWNUM은 WHERE 절에 사용 가능하지만 문법이 다름 (`WHERE ROWNUM <= 5`)
- ④: MySQL 문법 (`LIMIT N`)

---

**[하-16] 답**

SQL 실행 시 `&employee_num` 부분에서 **사용자에게 값 입력을 요청**하는 대화상자가 표시된다.  
사용자가 값을 입력하면 해당 값이 `&employee_num` 자리에 치환되어 쿼리가 실행된다.  
예) `200` 입력 → `WHERE employee_id = 200`으로 실행

---

**[하-17] 답: ②**

NOT은 **조건을 반전**시킨다. 조건이 FALSE이면 TRUE를 반환하고, TRUE이면 FALSE를 반환한다.  
예) `NOT IN ('IT_PROG')` → IT_PROG가 아닌 모든 직무

---

**[하-18] 답**

WHERE 절이 없으면 조건 필터링 없이 **테이블의 모든 행**(EMPLOYEES: 107행)이 반환된다.

---

**[하-19] 답: `salary * 12` (annsal)**

`annsal`은 `salary * 12`의 열 별칭이다. ORDER BY 절에서는 SELECT에서 정의한 열 별칭을 사용할 수 있다. (WHERE 절과 달리 ORDER BY는 SELECT 이후에 처리되므로 별칭 참조 가능)

---

**[하-20] 답: ① A는 반드시 B보다 작아야 한다**

`BETWEEN A AND B`에서 A(하한값)는 B(상한값)보다 작거나 같아야 한다.  
`WHERE salary BETWEEN 3500 AND 2500` → 결과 없음 (A > B이므로 조건 불성립)

---

# ★★ 중 (응용) 모범답안

---

**[중-01] 답**

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary >= 10000;
```

---

**[중-02] 답**

```sql
SELECT *
FROM   employees
WHERE  last_name = 'Abel';
```

문자 값은 **대소문자 구분** → `'abel'` 또는 `'ABEL'`은 결과 없음.

---

**[중-03] 답**

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary BETWEEN 2500 AND 3500;
```

등가 표현:
```sql
WHERE salary >= 2500 AND salary <= 3500
```

---

**[중-04] 답**

```sql
SELECT employee_id, last_name, salary, manager_id
FROM   employees
WHERE  manager_id IN (100, 101, 201);
```

---

**[중-05] 답**

```sql
SELECT first_name
FROM   employees
WHERE  first_name LIKE 'S%';
```

결과 예: Steven, Shelley, Shanta, Susan, Shelli, ...

---

**[중-06] 답**

```sql
SELECT last_name
FROM   employees
WHERE  last_name LIKE '_o%';
```

`_`: 첫 글자(임의 1글자), `o`: 두 번째 글자가 'o', `%`: 나머지는 어떤 값이든

---

**[중-07] 답**

```sql
SELECT last_name, manager_id
FROM   employees
WHERE  manager_id IS NULL;
```

결과: Steven King (employee_id=100, 회사 최상위 직급으로 관리자 없음)

---

**[중-08] 답**

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary >= 10000
AND    job_id LIKE '%MAN%';
```

---

**[중-09] 답**

```sql
SELECT last_name, job_id
FROM   employees
WHERE  job_id NOT IN ('IT_PROG', 'ST_CLERK', 'SA_REP');
```

---

**[중-10] 답**

**연산자 우선순위: AND가 OR보다 높다**

| SQL | 조건 해석 |
|-----|---------|
| (A) | `dept=60 OR (dept=80 AND salary>10000)` — AND 먼저 평가됨 |
| (B) | `(dept=60 OR dept=80) AND salary>10000` — 괄호로 OR 먼저 |

- **(A) 결과:** 부서가 60인 **모든** 사원 + 부서가 80이고 급여가 10,000 초과인 사원
- **(B) 결과:** (부서가 60 또는 80)이면서 급여가 10,000 초과인 사원만

---

**[중-11] 답**

```sql
SELECT last_name, job_id, department_id, hire_date
FROM   employees
ORDER BY hire_date;          -- ASC는 기본값이므로 생략 가능
```

---

**[중-12] 답**

```sql
SELECT last_name, department_id, salary
FROM   employees
ORDER BY department_id DESC, salary DESC;
```

---

**[중-13] 답**

```sql
SELECT last_name, salary, commission_pct
FROM   employees
WHERE  commission_pct IS NOT NULL;
```

결과: SA_REP(영업 담당자), SA_MAN(영업 관리자) 등 커미션이 있는 사원 35명

---

**[중-14] 답**

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  employee_id BETWEEN 100 AND 120;
```

---

**[중-15] 답**

```sql
SELECT last_name, hire_date
FROM   employees
WHERE  hire_date > '01-JAN-99';
```

Oracle 기본 날짜 형식: `DD-MON-RR` (두 자리 연도)

---

**[중-16] 답**

```sql
SELECT employee_id, last_name, salary * 12 AS annsal
FROM   employees
ORDER BY annsal DESC;
```

ORDER BY에서 열 별칭 `annsal` 사용 가능 (SELECT 절이 ORDER BY보다 먼저 처리됨).

---

**[중-17] 답**

**문제:** `BETWEEN 3500 AND 2500`은 하한값(A)이 상한값(B)보다 크므로 결과가 0건 반환된다.

```sql
-- 수정: 하한값과 상한값의 순서를 바꾼다
SELECT last_name, salary
FROM   employees
WHERE  salary BETWEEN 2500 AND 3500;
```

---

**[중-18] 답**

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary >= 10000
OR     job_id LIKE '%MAN%';
```

---

**[중-19] 답**

```sql
SELECT employee_id, first_name, last_name
FROM   employees
ORDER BY employee_id
FETCH FIRST 10 ROWS ONLY;
```

---

**[중-20] 답**

```sql
SELECT department_id, department_name
FROM   departments
WHERE  manager_id IS NULL;
```

---

# ★★★ 상 (심화) 모범답안

---

**[상-01] 답**

**연산자 우선순위: AND가 OR보다 높다.**

| SQL | 해석 |
|-----|------|
| (A) | `job_id = 'SA_REP'  OR  (job_id = 'AD_VP' AND salary > 15000)` |
| (B) | `(job_id = 'SA_REP' OR job_id = 'AD_VP')  AND  salary > 15000` |

**(A)의 결과:**
- SA_REP인 모든 사원 (급여 무관) → 약 30명
- AD_VP이고 급여 > 15,000인 사원 → Kochhar(17,000), De Haan(17,000)

**B의 결과:**
- SA_REP 또는 AD_VP이면서 급여 > 15,000인 사원만
- SA_REP 중 salary > 15,000인 사람은 없음 (최고 11,500)
- AD_VP 중 salary > 15,000 → Kochhar, De Haan

결론: (A)가 (B)보다 훨씬 많은 행을 반환한다.

---

**[상-02] 답**

**오류 목록:**

| 번호 | 오류 | 수정 |
|------|------|------|
| ① | `SELCT` — 오타 | `SELECT` |
| ② | `WERE` — 오타 | `WHERE` |
| ③ | `BETWEEN 5000 TO 10000` — `TO` 대신 `AND` 사용 | `BETWEEN 5000 AND 10000` |
| ④ | `"%king%"` — 큰따옴표 사용 및 대소문자 주의 | `'%King%'` (단일 따옴표, 대소문자 구분) |
| ⑤ | `ORDERBY` — 붙여쓰기 | `ORDER BY` |

**수정된 SQL:**

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary BETWEEN 5000 AND 10000
   OR  last_name LIKE '%King%'
ORDER BY salary;
```

---

**[상-03] 답**

```sql
SELECT employee_id, last_name, salary, department_id, commission_pct
FROM   employees
WHERE  department_id IN (50, 80)
AND    salary >= 5000
AND    last_name LIKE 'A%'
AND    commission_pct IS NOT NULL
ORDER BY salary DESC;
```

> **조건 분석:**
> - `department_id IN (50, 80)`: 부서 50(Shipping) 또는 80(Sales)
> - `salary >= 5000`: 급여 5천 이상
> - `last_name LIKE 'A%'`: 성이 'A'로 시작
> - `commission_pct IS NOT NULL`: 커미션 있는 사원
> - 부서 80(Sales)의 SA_REP 중 성이 'A'로 시작하고 급여 5000 이상인 사원이 해당될 가능성이 높다

---

**[상-04] 답**

**(1) 조건 설명:**  
부서 번호가 60, 80, 90 중 하나이면서, 급여가 5,000 미만이거나 12,000 초과인 사원  
(`NOT BETWEEN 5000 AND 12000` = `salary < 5000 OR salary > 12000`)

**(2) 예측 결과:**

| 사원 | 부서 | 급여 | 포함 여부 |
|------|------|------|---------|
| Steven King | 90 | 24,000 | ✅ (>12,000) |
| Neena Kochhar | 90 | 17,000 | ✅ (>12,000) |
| Lex De Haan | 90 | 17,000 | ✅ (>12,000) |
| IT_PROG (dept=60) | 60 | 4,200~9,000 | ⚠ 4,200은 포함(<5000), 5,800~9,000은 제외 |
| SA_REP (dept=80) | 80 | 6,100~11,500 | ❌ 대부분 5,000~12,000 사이 → 제외 |
| John Russell (SA_MAN) | 80 | 14,000 | ✅ (>12,000) |

---

**[상-05] 답**

| 방식 | 장점 | 단점 |
|------|------|------|
| 열 위치 번호 (`ORDER BY 3`) | 짧게 작성 가능 | SELECT 열 순서 변경 시 의도치 않게 다른 열로 정렬됨 / 코드 가독성 저하 |
| 열 이름 (`ORDER BY department_id`) | 의도 명확, 유지보수 용이 | 긴 표현식은 반복 작성 필요 |
| 열 별칭 (`ORDER BY annsal`) | 표현식을 반복하지 않아도 됨 | 별칭 변경 시 ORDER BY도 함께 변경 필요 |

**실무 권장:** 열 이름 또는 별칭 사용. 열 위치 번호는 코드 변경에 취약하여 지양.

---

**[상-06] 답**

```sql
SELECT employee_id, last_name, job_id, salary, department_id
FROM   employees
WHERE  job_id IN ('SA_REP', 'SA_MAN')
AND    salary >= 8000
ORDER BY department_id ASC, salary DESC
FETCH FIRST 5 ROWS ONLY;
```

---

**[상-07] 답**

**(1) 조건 평가 순서 분석:**

```
WHERE  department_id = 80         -- 비교
AND    salary > 10000             -- 비교
OR     commission_pct IS NOT NULL -- IS NOT NULL
AND    salary BETWEEN 6000 AND 9000 -- BETWEEN
```

AND가 OR보다 우선순위가 높으므로:

```
( department_id = 80  AND  salary > 10000 )
OR
( commission_pct IS NOT NULL  AND  salary BETWEEN 6000 AND 9000 )
```

즉: **부서=80이고 급여>10,000인 사원** 또는 **커미션이 있고 급여가 6,000~9,000인 사원**

**(2) 괄호를 사용한 명확한 버전:**

```sql
SELECT last_name, department_id, salary, commission_pct
FROM   employees
WHERE  (department_id = 80 AND salary > 10000)
OR     (commission_pct IS NOT NULL AND salary BETWEEN 6000 AND 9000);
```

---

**[상-08] 답**

```sql
SELECT last_name, salary, hire_date
FROM   employees
WHERE  job_id = '&job_title'
ORDER BY salary DESC;
```

실행 시 `job_title` 값 입력 요청 (예: `SA_REP`, `IT_PROG` 등)  
문자 값이므로 단일 따옴표로 감싼다: `'&job_title'`

더 유연한 버전 (열 이름도 변수로):
```sql
SELECT last_name, salary, hire_date
FROM   employees
WHERE  job_id = '&job_title'
ORDER BY &order_col;
```

---

**[상-09] 답**

**두 SQL은 결과가 다를 수 있다.**

| SQL | 조건 범위 |
|-----|---------|
| (A) `salary > 5000 AND salary < 10000` | 5,000 **초과** ~ 10,000 **미만** (경계값 불포함) |
| (B) `salary BETWEEN 5001 AND 9999` | 5,001 이상 ~ 9,999 이하 |

- salary가 정수라면 두 결과는 동일
- salary가 소수를 포함한다면 (예: 5000.5):
  - (A): 포함 (`5000 < 5000.5 < 10000`)
  - (B): 포함 (`5001 <= 5000.5` → FALSE → 미포함 가능성)
- 정확히 동일하게 하려면: `BETWEEN 5001 AND 9999`보다 `salary > 5000 AND salary < 10000`이 더 안전하다.

실제 HR 데이터(salary는 NUMBER(8,2))를 고려할 때 소수점 급여 가능성이 있으므로 (A)와 (B)는 이론적으로 다를 수 있다.

---

**[상-10] 답**

```sql
SELECT employee_id, last_name, department_id, job_id, salary, commission_pct
FROM   employees
WHERE  (department_id IN (50, 60, 80) OR department_id IS NULL)
AND    salary >= 5000
AND    job_id <> 'ST_CLERK'
ORDER BY department_id ASC NULLS LAST, salary DESC;
```

> **조건 분석:**
> - `department_id IN (50, 60, 80) OR department_id IS NULL`: 부서 50/60/80 또는 부서 없음
> - `salary >= 5000`: 급여 5천 이상
> - `job_id <> 'ST_CLERK'`: ST_CLERK 제외
> - `ORDER BY department_id ASC NULLS LAST`: NULL은 마지막에
> - `salary DESC`: 같은 부서 내 급여 내림차순

`NULLS LAST` 키워드: Oracle에서 NULL을 정렬 마지막에 배치한다 (기본값은 오름차순 시 NULL이 마지막).
