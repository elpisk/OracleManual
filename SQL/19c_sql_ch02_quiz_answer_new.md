# Oracle Database 19c: SQL Workshop
## Chapter 2 — SQL SELECT 문으로 데이터 조회 | 모범답안

---

# ★ 하 (기초) 모범답안

---

**[하-01] 답: ③**

SQL 문 자체는 여러 줄에 걸쳐 작성할 수 있지만, `SELECT`, `FROM` 같은 **키워드(예약어)** 는 줄 중간에 쪼개어 작성할 수 없다.  
(예: `SE`와 `LECT`으로 나누어 쓰는 것은 불가)

---

**[하-02] 답**

```sql
SELECT *
FROM   employees;
```

---

**[하-03] 답: ③**

NULL은 값 자체가 존재하지 않음(사용할 수 없거나, 할당되지 않았거나, 알 수 없는 값)을 나타낸다.  
0(숫자)이나 공백 문자('')와는 전혀 다른 개념이다.

---

**[하-04] 답: NULL**

NULL을 포함한 모든 산술 표현식의 결과는 NULL이다.  
`12 * salary * NULL` = NULL (어떤 수를 NULL과 연산해도 결과는 NULL)

---

**[하-05] 답: 선택 (Optional)**

`AS` 키워드는 생략 가능하다. 아래 두 SQL 문은 동일한 결과를 출력한다.
```sql
SELECT salary AS annual_sal FROM employees;
SELECT salary annual_sal    FROM employees;  -- AS 생략
```

---

**[하-06] 답: ②**

`DISTINCT`는 SELECT 결과에서 **중복된 행을 제거**하고 고유한 행만 반환한다.

---

**[하-07] 답: ②**

```sql
DESC employees
```

---

**[하-08] 답: DUAL**

`DUAL`은 Oracle Database가 자동으로 생성하는 특수 테이블로, 단일 열(`DUMMY VARCHAR2(1)`)과 단일 행(값 `'X'`)으로 구성된다. 테이블 없이 표현식·함수 결과를 조회할 때 사용한다.

---

**[하-09] 답: ②**

열 별칭에 **공백, 특수문자**가 포함되거나 **대소문자를 정확히 표시**해야 할 경우 큰따옴표(`"`)로 감싸야 한다.
```sql
SELECT salary "Annual Salary" FROM employees;
```

---

**[하-10] 답: `||` (파이프 두 개)**

Oracle에서는 두 수직 막대(`||`)를 연결 연산자로 사용한다.
```sql
SELECT last_name || ' ' || job_id FROM employees;
```

---

**[하-11] 답: ③ `*` (곱하기)**

산술 연산자 우선순위: `*`, `/` (곱셈·나눗셈) → `+`, `-` (덧셈·뺄셈)  
같은 우선순위 내에서는 왼쪽에서 오른쪽 순서로 계산된다.

---

**[하-12] 답: SELECT 절, FROM 절**

```sql
SELECT 열목록
FROM   테이블명;
```

WHERE, ORDER BY 등의 절은 선택적이다.

---

**[하-13] 답: ② 단일 따옴표 `'`**

```sql
SELECT 'Hello' || last_name FROM employees;
SELECT hire_date FROM employees WHERE hire_date = '2003-06-17';
```

큰따옴표(`"`)는 열 별칭에만 사용한다.

---

**[하-14] 답: ④ 현재 저장된 데이터 값**

`DESCRIBE`(또는 `DESC`)는 테이블의 **구조 정보**(열 이름, 데이터 타입, NOT NULL 여부)만 보여준다.  
실제 저장된 데이터를 조회하려면 SELECT 문을 사용해야 한다.

---

**[하-15] 답: DISTINCT**

```sql
SELECT DISTINCT department_id
FROM   employees;
```

---

**[하-16] 답: ②**

`dual`은 Oracle이 자동 생성하는 단일 행·단일 열 테이블이다. `SELECT * FROM dual`은 `DUMMY` 열의 값 `'X'`를 반환하는 1행 결과를 반환한다.

---

**[하-17] 답: `q''` 대체 따옴표 연산자 (Alternative Quote Operator)**

```sql
SELECT q'[Department's Budget]' FROM dual;
SELECT q'{This won't fail}' FROM dual;
```

구분자로 `[ ]`, `{ }`, `( )`, `< >` 또는 임의의 비알파벳 문자 쌍을 사용할 수 있다.

---

**[하-18] 답: ② 대문자, 왼쪽 정렬**

SQL Developer에서 열 머리글의 기본값:
- 열 이름: **대문자** 표시
- 문자·날짜 데이터: **왼쪽** 정렬
- 숫자 데이터: **오른쪽** 정렬

---

**[하-19] 답: `SALARY+300`**

열 별칭이 없으면 표현식 자체가 열 머리글로 사용된다.  
(예: `salary + 300` → 열 머리글은 `SALARY+300`)

---

**[하-20] 답: ②**

```sql
SELECT last_name, salary FROM employees;
```

- ①: 모든 열 조회  
- ③: 문법 오류 (`SELECT ALL`은 올바른 문법이 아님)  
- ④: `last_name salary` — `salary`가 `last_name`의 별칭으로 해석되어 의도와 다름

---

# ★★ 중 (응용) 모범답안

---

**[중-01] 답**

```sql
SELECT last_name, job_id, hire_date
FROM   employees;
```

---

**[중-02] 답**

| SQL | 계산식 | 결과값 |
|-----|--------|--------|
| (A) `12 * salary + 100` | 12 × 24,000 + 100 | **288,100** |
| (B) `12 * (salary + 100)` | 12 × (24,000 + 100) | **289,200** |

**차이 이유:** 곱셈(`*`)은 덧셈(`+`)보다 우선순위가 높으므로 (A)에서는 먼저 `12 * salary`가 계산된 후 100을 더한다. (B)에서는 괄호로 우선순위를 바꿔 먼저 `salary + 100`을 계산한다.

---

**[중-03] 답**

```sql
SELECT DISTINCT department_id
FROM   employees;
```

---

**[중-04] 답**

**문제점:** `Annual Salary`는 공백이 포함된 별칭이므로 큰따옴표로 감싸야 한다.

```sql
-- 오류 SQL
SELECT last_name, salary Annual Salary   -- 'Annual'은 별칭, 'Salary'는 인식 불가 → 오류
FROM   employees;

-- 수정 SQL
SELECT last_name, salary "Annual Salary"
FROM   employees;
```

---

**[중-05] 답**

```sql
SELECT last_name "사원명", salary * 12 "연봉"
FROM   employees;
```

---

**[중-06] 답**

```sql
SELECT last_name || ' is a ' || job_id AS "Employee Details"
FROM   employees;
```

출력 예시: `King is a AD_PRES`

---

**[중-07] 답: NULL**

**이유:** commission_pct가 NULL이므로 `12 * salary * commission_pct` = `12 * 24000 * NULL` = **NULL**  
NULL을 포함한 산술 연산의 결과는 항상 NULL이다.

---

**[중-08] 답**

```sql
SELECT SYSDATE
FROM   dual;
```

또는

```sql
SELECT SYSDATE AS "현재날짜"
FROM   dual;
```

---

**[중-09] 답**

**오류 원인:** `FORM`은 올바른 키워드가 아니다. `FROM`으로 수정해야 한다.

```sql
SELECT last_name, salary, salary + 300
FROM   employees;   -- FORM → FROM
```

---

**[중-10] 답**

```sql
SELECT last_name, salary * 12 AS annual_sal
FROM   employees;
```

---

**[중-11] 답: ③ NULL**

NULL을 포함한 산술 연산의 결과는 항상 NULL이다.  
`100 + NULL` = NULL (NULL은 알 수 없는 값이므로 연산 결과도 알 수 없음)

---

**[중-12] 답**

```sql
-- 전체 명령어
DESCRIBE employees

-- 축약형
DESC employees
```

---

**[중-13] 답**

| 열 | 열 머리글 |
|----|----------|
| `last_name "Employee Name"` | **Employee Name** (큰따옴표 → 원형 그대로, 대소문자 유지) |
| `salary * 12 annual_sal` | **ANNUAL_SAL** (따옴표 없는 별칭 → 대문자로 표시) |
| `department_id` | **DEPARTMENT_ID** (별칭 없음 → 컬럼명 대문자) |

---

**[중-14] 답**

```sql
SELECT department_name || q'[ Department's Location: ]' || location_id
       AS "Department and Location"
FROM   departments;
```

---

**[중-15] 답: 19개**

`DISTINCT job_id`는 107개 행에서 중복을 제거하고 **고유한 job_id 19개**만 반환하므로 결과 행 수는 19개다.

---

**[중-16] 답: ②④⑤**

| 보기 | 큰따옴표 필요 여부 | 이유 |
|------|-----------------|------|
| ① `AS name` | 불필요 | 공백·특수문자 없음 |
| ② `AS "Annual Salary"` | **필요** | 공백 포함 |
| ③ `AS employee_name` | 불필요 | 공백·특수문자 없음 |
| ④ `AS "이름"` | **필요** | 한글 특수 문자 포함 (권장) |
| ⑤ `AS "Name"` | **필요** | 대소문자 구분 유지 필요 시 |

---

**[중-17] 답**

```sql
SELECT job_title, max_salary - min_salary AS salary_range
FROM   jobs;
```

---

**[중-18] 답**

| SQL | 결과 행 수 |
|-----|-----------|
| (A) `SELECT department_id` | **107행** (모든 사원의 부서 ID, 중복 포함) |
| (B) `SELECT DISTINCT department_id` | **12개** (NULL 포함 고유 값) |

**이유:** `DISTINCT`는 중복 값을 하나로 합쳐 고유한 값만 반환한다. NULL도 하나의 고유 값으로 처리된다.

---

**[중-19] 답**

```sql
SELECT first_name || ' ' || last_name AS "Full Name",
       salary AS "월급"
FROM   employees;
```

---

**[중-20] 답**

**실행 결과:** 1행 반환

```
GREETING          TODAY
----------------- ----------
Hello, Oracle!    26/06/26
```

**dual 테이블 특성:**
- Oracle이 자동으로 생성하는 시스템 테이블
- `DUMMY` VARCHAR2(1) 열 하나, 값 `'X'` 하나로 구성 (항상 1행)
- 테이블 없이 상수, 함수, 산술 계산 결과를 조회할 때 사용
- `FROM` 절이 필수인 Oracle에서 표현식만 평가할 때 유용

---

# ★★★ 상 (심화) 모범답안

---

**[상-01] 답**

| 열 | 계산 | 결과 | 이유 |
|----|------|------|------|
| `salary` | — | **24,000** | 원래 값 그대로 |
| `col1` (salary + NULL) | 24,000 + NULL | **NULL** | NULL을 포함한 산술은 항상 NULL |
| `col2` (salary * 0) | 24,000 × 0 | **0** | 0은 NULL이 아닌 유효한 숫자 |
| `col3` (0 / salary) | 0 ÷ 24,000 | **0** | 0을 어떤 수로 나눠도 0 (단, salary≠0이어야 함) |

**핵심:** `0 * salary ≠ NULL`, `NULL * 0 = NULL` 이므로 피연산자 위치가 중요하다.

---

**[상-02] 답**

**오류 목록:**

| 번호 | 오류 내용 | 수정 방법 |
|------|----------|----------|
| ① | `SELCT` — 오타 | `SELECT`로 수정 |
| ② | `"Employee Name` — 닫는 큰따옴표 누락 | `"Employee Name"` |
| ③ | `salary*12` 바로 뒤 별칭이 앞 오류와 혼재 | 구분자 정리 필요 |
| ④ | `comm pct` — 공백 포함 별칭에 따옴표 없음 | `"comm pct"` |
| ⑤ | `FORM` — 오타 | `FROM`으로 수정 |

**수정된 SQL:**

```sql
SELECT last_name          "Employee Name",
       salary * 12        "Annual Salary",
       commission_pct     "comm pct"
FROM   employees;
```

---

**[상-03] 답**

```sql
SELECT employee_id                      AS "사번",
       first_name || ' ' || last_name   AS "성명",
       salary                           AS "기본급",
       salary * 12                      AS "연봉",
       commission_pct                   AS "커미션율",
       job_id                           AS "직무코드"
FROM   employees;
```

---

**[상-04] 답**

**오류 원인 — SQL 논리적 처리 순서:**

```
처리 순서: FROM → WHERE → SELECT → ORDER BY
```

`WHERE` 절은 `SELECT` 절보다 먼저 실행된다. 따라서 `SELECT`에서 정의한 열 별칭 `annual_sal`은 `WHERE` 절이 실행될 시점에 아직 정의되지 않아 인식할 수 없다.

**올바른 해결 방법 — 표현식을 직접 사용:**

```sql
SELECT salary * 12 AS annual_sal
FROM   employees
WHERE  salary * 12 > 100000;
```

---

**[상-05] 답**

| 비교 항목 | `SELECT *` | 명시적 컬럼 선택 |
|-----------|-----------|----------------|
| **성능** | 불필요한 열까지 읽어 I/O 증가 | 필요한 열만 읽어 성능 향상 |
| **네트워크** | 전체 데이터 전송으로 트래픽 증가 | 필요한 데이터만 전송 |
| **가독성** | 코드 의도 파악 어려움 | 무엇을 조회하는지 명확 |
| **유지보수** | 테이블에 열 추가 시 결과 자동 변경 → 의도치 않은 변경 위험 | 열 추가/순서 변경에 안전 |
| **적합한 경우** | 개발·탐색·임시 조회 | 운영 코드, 애플리케이션 쿼리 |

**결론:** 실무 운영 환경에서는 반드시 필요한 열만 명시하여 조회하는 것을 권장한다.

---

**[상-06] 답**

**(1) NULL이 출력되는 원인:**

`commission_pct`가 NULL인 사원에 대해 `12 * salary * NULL` = **NULL**  
NULL을 포함한 모든 산술 연산의 결과는 NULL이 되므로, 커미션이 없는 사원의 연간 커미션도 NULL로 표시된다.

**(2) NVL 함수를 사용한 수정 SQL:**

```sql
SELECT last_name,
       salary,
       12 * salary * NVL(commission_pct, 0) AS "연간커미션"
FROM   employees;
```

`NVL(commission_pct, 0)`: commission_pct가 NULL이면 0으로 대체하여 계산.  
커미션이 없는 사원은 0, 커미션이 있는 사원은 실제 값으로 계산된다.

---

**[상-07] 답**

| 항목 | (A) | (B) |
|------|-----|-----|
| **열 수** | 2열 (employee_id, department_id) | 1열 (department_id) |
| **행 수** | **107행** | **12행** |

**차이 이유:**
- (A): 107명 전체의 `employee_id`와 `department_id` 조합을 모두 반환
- (B): `DISTINCT`로 중복 제거 → 고유한 `department_id` 값(NULL 포함 12개)만 반환

**핵심:** `DISTINCT`는 `SELECT` 뒤의 전체 컬럼 조합을 기준으로 중복을 제거한다.

---

**[상-08] 답**

```sql
SELECT department_name
       || q'[ Department's Manager ID is: ]'
       || manager_id
       AS "Department and Manager"
FROM   departments;
```

`q'[ ]'` 안에 작은따옴표를 포함한 문자열을 그대로 사용할 수 있다.  
manager_id가 NULL인 부서는 해당 열이 NULL로 출력된다.

---

**[상-09] 답**

**문제점:**

| 번호 | 문제 | 이유 |
|------|------|------|
| ① | `select *` — 모든 열 조회 | 불필요한 열까지 전송, 성능 저하 |
| ② | SQL 키워드 소문자 | 관례 위반 (키워드는 대문자 권장) |
| ③ | 세 개의 독립 전체 조회 | 업무 목적 없이 데이터 전체 노출 |
| ④ | 코드에서 조회 의도 파악 불가 | 가독성 저하 |

**개선 SQL (예시 — 인사 정보 조회 목적):**

```sql
-- 직원 기본 정보
SELECT employee_id,
       first_name || ' ' || last_name AS "성명",
       job_id                         AS "직무코드",
       salary                         AS "기본급",
       department_id                  AS "부서"
FROM   employees;

-- 부서 정보
SELECT department_id   AS "부서번호",
       department_name AS "부서명",
       location_id     AS "위치"
FROM   departments;

-- 직무 급여 범위
SELECT job_id    AS "직무코드",
       job_title AS "직무명",
       min_salary AS "최저급여",
       max_salary AS "최고급여"
FROM   jobs;
```

---

**[상-10] 답**

**(1) 열 수와 행 수**
- **열 수:** 6열 (사번, 성명, 직무, 기본급, 연간커미션, 총연봉)
- **행 수:** 107행 (EMPLOYEES 전체)

**(2) Steven King (salary=24000, commission_pct=NULL)**

| 열 | 계산 | 결과 |
|----|------|------|
| 사번 | — | 100 |
| 성명 | 'Steven' \|\| ' ' \|\| 'King' | **Steven King** |
| 직무 | — | **AD_PRES** |
| 기본급 | — | **24,000** |
| 연간커미션 | 24,000 × NVL(NULL,0) × 12 = 24,000 × 0 × 12 | **0** |
| 총연봉 | 24,000 × 12 + 0 | **288,000** |

**(3) John Russell (salary=14000, commission_pct=0.4)**

| 열 | 계산 | 결과 |
|----|------|------|
| 사번 | — | 145 |
| 성명 | 'John' \|\| ' ' \|\| 'Russell' | **John Russell** |
| 직무 | — | **SA_MAN** |
| 기본급 | — | **14,000** |
| 연간커미션 | 14,000 × 0.4 × 12 | **67,200** |
| 총연봉 | 14,000 × 12 + 67,200 = 168,000 + 67,200 | **235,200** |

**(4) NVL 없이 commission_pct=NULL인 경우**

`salary * NULL * 12` = **NULL**이 되어 연간커미션이 NULL로 출력된다.  
또한 `총연봉 = salary * 12 + NULL` = **NULL**로 총연봉도 계산되지 않는다.  
결과적으로 커미션이 없는 107명 중 다수 사원의 총연봉이 NULL로 표시되어 데이터 분석이 불가능해진다.
