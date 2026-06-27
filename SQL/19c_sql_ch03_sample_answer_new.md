# Oracle Database 19c: SQL Workshop
## Chapter 3 — 데이터 제한 및 정렬 | SQL 실습 문제 모범답안

---

## Group 1. WHERE 절 기본 조건 모범답안 (1~6번)

---

**[1번] 답**

```sql
SELECT employee_id, last_name, job_id, department_id
FROM   employees
WHERE  department_id = 90;
```

> 숫자 값은 따옴표 없이 사용한다. 문자·날짜 값만 단일 따옴표로 감싼다.

---

**[2번] 답**

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary <= 3000;
```

---

**[3번] 답**

```sql
SELECT *
FROM   employees
WHERE  last_name = 'Abel';
```

> 문자 값은 **대소문자를 구분**한다. `'abel'` 또는 `'ABEL'`로 조회하면 결과가 없다.

---

**[4번] 답**

```sql
SELECT last_name, hire_date
FROM   employees
WHERE  hire_date > '01-JAN-00'
ORDER BY hire_date;
```

> Oracle 기본 날짜 형식: `DD-MON-RR` (두 자리 연도, RR 형식)  
> `'01-JAN-00'`은 2000년 1월 1일을 의미한다.

---

**[5번] 답**

```sql
SELECT last_name, salary, commission_pct
FROM   employees
WHERE  commission_pct IS NOT NULL
ORDER BY salary DESC;
```

> NULL 비교는 반드시 `IS NULL` 또는 `IS NOT NULL`을 사용한다.  
> `commission_pct != NULL` 또는 `commission_pct <> NULL`은 항상 0건 반환.

---

**[6번] 답**

```sql
SELECT last_name, manager_id
FROM   employees
WHERE  manager_id IS NULL;
```

> 결과: Steven King 1명 — 회사 최상위 직급으로 관리자가 없다.

---

## Group 2. 범위·목록·패턴 조건 모범답안 (7~12번)

---

**[7번] 답**

```sql
SELECT last_name, salary
FROM   employees
WHERE  salary BETWEEN 2500 AND 3500;
```

> 동일한 표현: `WHERE salary >= 2500 AND salary <= 3500`  
> 경계값 2500과 3500 **모두 포함**된다.

---

**[8번] 답**

```sql
SELECT employee_id, last_name, salary, manager_id
FROM   employees
WHERE  manager_id IN (100, 101, 201);
```

> 동일한 표현:
> ```sql
> WHERE manager_id = 100 OR manager_id = 101 OR manager_id = 201
> ```
> IN을 사용하면 더 간결하게 작성할 수 있다.

---

**[9번] 답**

```sql
SELECT first_name
FROM   employees
WHERE  first_name LIKE 'S%';
```

> `'S%'`: 'S'로 시작하는 모든 값 (뒤에 0개 이상의 임의 문자)  
> 대소문자를 구분하므로 `'s%'`는 결과가 없을 수 있다.

---

**[10번] 답**

```sql
SELECT last_name
FROM   employees
WHERE  last_name LIKE '_o%';
```

> `_`: 정확히 1개의 임의 문자  
> `o`: 두 번째 자리가 반드시 'o'  
> `%`: 세 번째 자리 이후는 어떤 값이든

---

**[11번] 답**

```sql
SELECT last_name
FROM   employees
WHERE  last_name LIKE '%a%'
ORDER BY last_name;
```

> `'%a%'`: 'a'를 어디든 포함하는 값 (앞, 뒤 또는 중간)  
> 대소문자 구분 → 대문자 'A'는 포함되지 않는다. 대소문자 구분 없이 검색하려면 `LOWER(last_name) LIKE '%a%'` 사용.

---

**[12번] 답**

```sql
SELECT last_name, job_id
FROM   employees
WHERE  job_id NOT IN ('IT_PROG', 'ST_CLERK', 'SA_REP');
```

> 동일한 표현:
> ```sql
> WHERE job_id <> 'IT_PROG'
>   AND job_id <> 'ST_CLERK'
>   AND job_id <> 'SA_REP'
> ```

---

## Group 3. 논리 연산자 조합 모범답안 (13~18번)

---

**[13번] 답**

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary >= 10000
AND    job_id LIKE '%MAN%';
```

> AND는 두 조건이 **모두 TRUE**이어야 행을 반환한다.  
> 결과: SA_MAN(영업관리자) 5명 + MK_MAN(마케팅관리자) 1명 = 6명

---

**[14번] 답**

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  salary >= 10000
OR     job_id LIKE '%MAN%';
```

> OR는 **하나라도 TRUE**이면 행을 반환한다.  
> AND보다 훨씬 많은 행이 반환된다:
> - 급여 10,000 이상인 모든 사원 (약 32명)
> - 직무에 'MAN'이 포함된 사원 중 급여 10,000 미만인 사원까지 포함

---

**[15번] 답**

```sql
SELECT last_name, job_id
FROM   employees
WHERE  job_id NOT IN ('IT_PROG', 'ST_CLERK', 'SA_REP');
```

---

**[16번] 버전 A 답**

```sql
SELECT last_name, department_id, salary
FROM   employees
WHERE  department_id = 60
OR     department_id = 80
AND    salary > 10000;
```

**버전 B 답**

```sql
SELECT last_name, department_id, salary
FROM   employees
WHERE  (department_id = 60
OR      department_id = 80)
AND    salary > 10000;
```

> **차이 분석 (연산자 우선순위: AND > OR):**
>
> | 버전 | 실제 해석 | 결과 |
> |------|----------|------|
> | A | `dept=60 OR (dept=80 AND salary>10000)` | 부서 60 전체 + 부서 80이고 급여>10000 |
> | B | `(dept=60 OR dept=80) AND salary>10000` | (부서 60 또는 80)이고 급여>10000 |
>
> 버전 B가 더 엄격한 조건 → 부서 60의 저급여 사원이 제외됨

---

**[17번] 답**

```sql
SELECT last_name, department_id, salary
FROM   employees
WHERE  department_id = 50
AND    salary >= 3500
AND    last_name LIKE 'S%'
ORDER BY salary;
```

---

**[18번] 답**

```sql
SELECT last_name, salary, commission_pct
FROM   employees
WHERE  salary < 5000
OR     salary > 15000
OR     commission_pct >= 0.4
ORDER BY salary DESC;
```

> `salary < 5000 OR salary > 15000`은 `NOT BETWEEN 5000 AND 15000`과 동일하다.

---

## Group 4. ORDER BY 정렬 모범답안 (19~24번)

---

**[19번] 답**

```sql
SELECT last_name, job_id, department_id, hire_date
FROM   employees
ORDER BY hire_date;     -- ASC 기본값
```

---

**[20번] 답**

```sql
SELECT last_name, job_id, department_id, hire_date
FROM   employees
ORDER BY hire_date DESC;
```

---

**[21번] 답**

```sql
SELECT employee_id, last_name, salary * 12 AS annsal
FROM   employees
ORDER BY annsal DESC;
```

> **핵심:** ORDER BY 절에서는 SELECT에서 정의한 열 별칭을 사용할 수 있다.  
> (WHERE 절에서는 별칭 사용 불가 — 처리 순서: FROM → WHERE → SELECT → ORDER BY)

---

**[22번] 답**

```sql
SELECT last_name, department_id, salary
FROM   employees
ORDER BY department_id ASC, salary DESC;
```

> 다중 열 정렬: 첫 번째 정렬 기준이 같을 때 두 번째 기준으로 정렬한다.

---

**[23번] 답**

```sql
SELECT last_name, job_id, department_id, hire_date
FROM   employees
ORDER BY 3;
```

> `ORDER BY 3`: SELECT 절의 세 번째 열(`department_id`) 기준 오름차순 정렬  
> 열 이름/별칭 대신 위치 번호로 정렬하면 SELECT 순서 변경 시 의도치 않은 정렬이 발생할 수 있다.

---

**[24번] 답**

```sql
SELECT last_name, salary, commission_pct
FROM   employees
WHERE  commission_pct IS NOT NULL
ORDER BY commission_pct DESC, salary DESC;
```

---

## Group 5. FETCH FIRST & WHERE + ORDER BY 종합 모범답안 (25~30번)

---

**[25번] 답**

```sql
SELECT employee_id, first_name, last_name
FROM   employees
ORDER BY employee_id
FETCH FIRST 5 ROWS ONLY;
```

> `FETCH FIRST N ROWS ONLY`: Oracle 12c 이상에서 사용 가능한 행 제한 구문.  
> `ORDER BY`와 함께 사용하여 정렬된 결과에서 상위 N개를 가져온다.

---

**[26번] 답**

```sql
SELECT employee_id, first_name, last_name
FROM   employees
ORDER BY employee_id
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
```

> `OFFSET N ROWS`: N개의 행을 건너뛴다 (첫 5행 건너뛰기).  
> `FETCH NEXT`: OFFSET 이후 다음 N행을 가져온다.  
> 페이지 단위 데이터 조회(Pagination)에 활용된다.

---

**[27번] 답**

```sql
SELECT employee_id, last_name, salary
FROM   employees
ORDER BY salary DESC
FETCH FIRST 3 ROWS ONLY;
```

> 동일 급여(Kochhar, De Haan 모두 17,000)의 경우 `WITH TIES`를 사용하면 동점자 포함:
> ```sql
> FETCH FIRST 2 ROWS WITH TIES;  -- 17000이 2명이면 3행 반환
> ```

---

**[28번] 답**

```sql
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  department_id = 80
AND    salary >= 10000
ORDER BY salary DESC
FETCH FIRST 3 ROWS ONLY;
```

---

**[29번] 답**

```sql
SELECT employee_id, last_name, job_id, salary
FROM   employees
WHERE  job_id = 'SA_REP'
AND    salary >= 8000
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;
```

---

**[30번] 답**

```sql
SELECT employee_id, last_name, department_id, job_id, salary
FROM   employees
WHERE  department_id IN (50, 60, 80)
AND    salary >= 5000
AND    last_name >= 'A'
AND    last_name < 'N'
ORDER BY department_id ASC, last_name ASC;
```

> **조건 분석:**
> - `department_id IN (50, 60, 80)`: 부서 50, 60, 80
> - `salary >= 5000`: 급여 5,000 이상
> - `last_name >= 'A' AND last_name < 'N'`: 'A'~'M' 알파벳 범위  
>   (`BETWEEN 'A' AND 'M'`으로 쓰면 'M'으로 시작하는 값 중 'M' 이후 문자 포함 여부가 달라짐에 주의)
> - `ORDER BY department_id ASC, last_name ASC`: 부서 오름차순, 같은 부서 내 이름 알파벳 순
