# Oracle Database 19c: SQL Workshop
## Chapter 2 — SQL 실습 문제 모범답안

---

## Group 1. SELECT 기본 조회 모범답안 (1~5번)

---

**[1번] 답**

```sql
SELECT *
FROM   employees;
```

> `*`는 테이블의 모든 열을 의미한다. EMPLOYEES 테이블은 11개 열, 107행이다.

---

**[2번] 답**

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees;
```

> 열 이름은 쉼표(`,`)로 구분하며, SELECT 절에 나열한 순서대로 출력된다.

---

**[3번] 답**

```sql
SELECT employee_id, last_name, job_id, hire_date, salary
FROM   employees;
```

> 2번 SQL에서 `hire_date`를 추가. 열 순서는 SELECT 절에 나열한 순서를 따른다.

---

**[4번] 답**

```sql
SELECT *
FROM   departments;
```

> DEPARTMENTS 테이블: 4개 열, 27행.

---

**[5번] 답**

```sql
SELECT job_id, job_title, min_salary, max_salary
FROM   jobs;
```

> JOBS 테이블: 4개 열, 19행.

---

## Group 2. DESCRIBE 명령어 모범답안 (6~7번)

---

**[6번] 답**

```sql
DESCRIBE employees
-- 또는 축약형
DESC employees
```

**NOT NULL 제약이 있는 열 (반드시 값이 있어야 하는 열):**

| 열 이름 | 타입 |
|---------|------|
| EMPLOYEE_ID | NUMBER(6) |
| LAST_NAME | VARCHAR2(25) |
| EMAIL | VARCHAR2(25) |
| HIRE_DATE | DATE |
| JOB_ID | VARCHAR2(10) |

> FIRST_NAME, PHONE_NUMBER, SALARY, COMMISSION_PCT, MANAGER_ID, DEPARTMENT_ID는 NULL 허용.

---

**[7번] 답**

```sql
DESC departments
```

**NULL 값을 허용하는 열:**

| 열 이름 | 타입 |
|---------|------|
| MANAGER_ID | NUMBER(6) |
| LOCATION_ID | NUMBER(4) |

> DEPARTMENT_ID와 DEPARTMENT_NAME은 NOT NULL — 반드시 값이 있어야 한다.

---

## Group 3. 산술 표현식 모범답안 (8~12번)

---

**[8번] 답**

```sql
SELECT last_name, salary, salary + 300
FROM   employees;
```

> 열 별칭이 없으면 표현식 자체가 열 머리글로 사용된다: `SALARY+300`

---

**[9번] 답**

```sql
SELECT last_name, salary, salary * 12
FROM   employees;
```

> 열 머리글: `SALARY*12` (별칭 없을 때)

---

**[10번] 답**

```sql
SELECT last_name,
       salary,
       12 * salary + 100,
       12 * (salary + 100)
FROM   employees;
```

**두 결과의 차이 이유 — 연산자 우선순위:**

| 표현식 | 계산 순서 | King(24000) 결과 |
|--------|----------|-----------------|
| `12 * salary + 100` | 곱셈 먼저: 12×24000=288000, 그 다음 +100 | **288,100** |
| `12 * (salary + 100)` | 괄호 먼저: 24000+100=24100, 그 다음 ×12 | **289,200** |

> 곱셈(`*`)은 덧셈(`+`)보다 우선순위가 높다. 괄호로 순서를 바꿀 수 있다.

---

**[11번] 답**

```sql
SELECT last_name, salary, salary / 30
FROM   employees;
```

> 나눗셈의 결과가 소수로 나올 수 있다 (예: 17000 / 30 = 566.666...).

---

**[12번] 답**

```sql
SELECT last_name, employee_id, employee_id * 10 - 100
FROM   employees;
```

> 연산자 우선순위: 곱셈(`* 10`) 먼저, 그 다음 뺄셈(`- 100`).  
> King(employee_id=100): 100 × 10 - 100 = **900**

---

## Group 4. NULL 값 모범답안 (13~15번)

---

**[13번] 답**

```sql
SELECT last_name, salary, commission_pct, 12 * salary * commission_pct
FROM   employees;
```

**확인 사항:**
- `commission_pct`가 NULL인 사원(대부분): `12 * salary * NULL` = **NULL** → 빈칸으로 표시
- `commission_pct`가 있는 사원 (SA_REP, SA_MAN 등):  
  예) John Russell: 12 × 14000 × 0.4 = **67,200**

> NULL을 포함한 산술 연산의 결과는 항상 NULL이다.

---

**[14번] 답**

```sql
SELECT last_name,
       salary,
       salary * 0,
       salary + NULL
FROM   employees;
```

**두 결과의 차이:**

| 표현식 | 결과 | 이유 |
|--------|------|------|
| `salary * 0` | **0** | 0은 유효한 숫자값 — NULL이 아님 |
| `salary + NULL` | **NULL** | NULL을 포함한 연산은 결과도 NULL |

> `0`과 `NULL`은 완전히 다르다. `0`은 "값이 0", `NULL`은 "값이 없음(미정)"이다.

---

**[15번] 답**

```sql
SELECT 100 + NULL,
       NULL * 0,
       NULL + NULL
FROM   dual;
```

**결과:**

| 표현식 | 결과 |
|--------|------|
| `100 + NULL` | NULL (알 수 없는 값에 100을 더해도 결과는 알 수 없음) |
| `NULL * 0` | NULL (NULL × 0도 NULL — 0을 곱해도 NULL) |
| `NULL + NULL` | NULL |

> NULL은 연산 위치(좌/우)에 관계없이 결과를 NULL로 만든다.

---

## Group 5. 열 별칭 모범답안 (16~20번)

---

**[16번] 답**

```sql
SELECT last_name, salary, salary * 12 AS annual_sal
FROM   employees;
```

> `AS annual_sal` 추가 → 열 머리글이 `SALARY*12`에서 `ANNUAL_SAL`로 변경된다.  
> 따옴표 없는 별칭은 자동으로 대문자로 표시된다.

---

**[17번] 답**

```sql
SELECT last_name, salary, salary * 12 annual_sal
FROM   employees;
```

> `AS` 키워드는 선택적이다. 제거해도 결과가 동일하다.  
> `AS annual_sal` = `annual_sal` (완전히 동일한 결과)

---

**[18번] 답**

```sql
SELECT last_name        "Employee Name",
       salary * 12      "Annual Salary",
       commission_pct   "커미션율"
FROM   employees;
```

> **큰따옴표(`"`)가 필요한 경우:**
> - 공백 포함: `"Employee Name"`, `"Annual Salary"`
> - 한글 별칭: `"커미션율"`
> - 대소문자를 그대로 유지해야 할 때 (큰따옴표 없으면 자동으로 대문자 변환)

---

**[19번] 답**

```sql
SELECT last_name AS name,
       salary    AS "월급",
       salary * 12 annual_sal,
       salary / 30 daily_sal
FROM   employees;
```

> 세 가지 별칭 형식 비교:
>
> | 형식 | 예시 | 열 머리글 |
> |------|------|----------|
> | `AS 소문자별칭` | `AS name` | `NAME` (대문자 자동 변환) |
> | `AS "한글/공백"` | `AS "월급"` | `월급` (원형 유지) |
> | `소문자별칭` (AS 생략) | `annual_sal` | `ANNUAL_SAL` |

---

**[20번] 답**

```sql
SELECT job_id        AS "직무코드",
       job_title     AS "직무명",
       min_salary    AS "최저급여",
       max_salary    AS "최고급여",
       max_salary - min_salary AS "급여범위"
FROM   jobs;
```

> 산술 표현식에도 열 별칭을 붙일 수 있다.  
> 한글 별칭은 항상 큰따옴표(`"`)로 감싸는 것이 안전하다.

---

## Group 6. 연결 연산자와 리터럴 모범답안 (21~25번)

---

**[21번] 답**

```sql
SELECT last_name || job_id AS "Employees"
FROM   employees;
```

> `||` (파이프 두 개): Oracle의 문자열 연결 연산자.  
> 두 열을 바로 연결하면 구분자 없이 붙는다 (`KingAD_PRES`).

---

**[22번] 답**

```sql
SELECT last_name || ' is a ' || job_id AS "Employee Details"
FROM   employees;
```

> 리터럴 문자열 `' is a '`를 중간에 삽입하면 가독성이 향상된다.  
> 문자 리터럴은 단일 따옴표(`'`)로 감싼다.

---

**[23번] 답**

```sql
SELECT '사번: ' || employee_id
       || '  이름: ' || first_name || ' ' || last_name
       || '  부서: ' || department_id
       AS "사원 정보"
FROM   employees;
```

> `||`는 열, 숫자, 문자열을 모두 연결할 수 있다.  
> 숫자(`employee_id`, `department_id`)는 자동으로 문자열로 변환된다.

---

**[24번] 답**

```sql
SELECT department_name || q'[ Department's Manager: ]' || manager_id
       AS "부서 및 매니저 정보"
FROM   departments;
```

> **`q''` 대체 따옴표 연산자:** 단일 따옴표(`'`)가 포함된 문자열을 간편하게 작성할 수 있다.  
> 구분자 쌍 `[ ]` 안에 내용을 그대로 쓰면 된다.  
> `q'[...]'` 외에도 `q'{...}'`, `q'(...)'`, `q'<...>'` 등도 사용 가능하다.

---

**[25번] 답**

```sql
SELECT department_name
       || q'[ Department's Manager: ]' || manager_id
       || q'[, Location: ]' || location_id
       AS "부서 정보"
FROM   departments;
```

> `q''` 연산자를 여러 번 사용하여 더 긴 문자열을 조합할 수 있다.  
> `manager_id`와 `location_id`는 숫자이지만 `||` 연산 시 자동으로 문자열로 변환된다.

---

## Group 7. DISTINCT 모범답안 (26~28번)

---

**[26번] 답**

```sql
-- 중복 포함 (107개 행)
SELECT job_id
FROM   employees;

-- 중복 제거 (19개 행)
SELECT DISTINCT job_id
FROM   employees;
```

> **비교:**
> - 중복 포함: 107명 × 각자의 job_id = 107행 (같은 job_id 반복 등장)
> - 중복 제거: 고유한 job_id 19가지 = 19행

---

**[27번] 답**

```sql
SELECT DISTINCT department_id
FROM   employees;
```

> **결과: 12개 행** (11개 부서 + NULL 1개)
>
> - EMPLOYEES 테이블에서 실제 사원이 배정된 부서: 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110 (11개)
> - 부서가 없는 사원(department_id = NULL): 1명 (Kimberely Grant)  
> - `DISTINCT`는 NULL도 하나의 고유 값으로 처리한다.

---

**[28번] 답**

```sql
SELECT DISTINCT job_id, department_id
FROM   employees;
```

> **두 열 DISTINCT:** `job_id + department_id` 조합이 고유한 행만 반환.  
> - `SELECT DISTINCT job_id` → 19행 (job_id만 기준)  
> - `SELECT DISTINCT job_id, department_id` → 19행 (이 예에서는 우연히 동일)  
>
> `DISTINCT`는 SELECT 뒤의 **전체 열 조합**을 기준으로 중복을 제거한다.

---

## Group 8. dual 테이블과 종합 모범답안 (29~30번)

---

**[29번] 답**

```sql
SELECT SYSDATE            AS "현재날짜",
       100 * 365 + 25     AS "계산결과1",
       (200 + 100) * 4    AS "계산결과2"
FROM   dual;
```

> **dual 테이블 특성:**
> - Oracle이 자동 생성하는 단일 행(`DUMMY VARCHAR2(1)`, 값 `'X'`) 테이블
> - 테이블 없이 표현식·함수·상수를 조회할 때 FROM 절에 사용
> - 항상 1행만 반환하므로 결과도 항상 1행

---

**[30번] 답**

```sql
SELECT employee_id                                       AS "사번",
       first_name || ' ' || last_name                   AS "성명",
       first_name || ' ' || last_name
           || ' 의 직무: ' || job_id                    AS "직무정보",
       salary                                           AS "기본급",
       salary * 12                                      AS "연봉",
       salary / 30                                      AS "일급"
FROM   employees;
```

> **활용된 Chapter 2 기법 종합:**
>
> | 기법 | 사용 위치 |
> |------|----------|
> | 특정 열 선택 | `employee_id`, `salary` 등 명시 |
> | 산술 표현식 | `salary * 12`, `salary / 30` |
> | 열 별칭 (`AS "한글"`) | `AS "사번"`, `AS "기본급"` 등 |
> | 연결 연산자 (`\|\|`) | `first_name \|\| ' ' \|\| last_name` |
> | 리터럴 문자열 | `' 의 직무: '` |
