# Oracle Database 19c: SQL Workshop
## Chapter 6 — 그룹 함수 | SQL 실습 문제 모범답안

---

## Group 1. 그룹 함수 기본 모범답안 (1~6번)

---

**[1번] 답**

```sql
SELECT MAX(salary)           AS max_salary,
       MIN(salary)           AS min_salary,
       ROUND(AVG(salary))    AS avg_salary,
       SUM(salary)           AS sum_salary
FROM   employees;
```

> ROUND 없이 AVG를 출력하면 소수점이 붙는다. 정수로 표시할 때는 ROUND(AVG(salary)) 사용.

---

**[2번] 답**

```sql
SELECT COUNT(*)              AS total_count,
       COUNT(commission_pct) AS with_comm_count
FROM   employees;
```

> - `COUNT(*)`: NULL 포함 전체 행 수 → 107  
> - `COUNT(commission_pct)`: commission_pct가 NULL이 아닌 행 수 → 35

---

**[3번] 답**

```sql
SELECT MIN(last_name)  AS first_name,
       MAX(last_name)  AS last_name,
       MIN(hire_date)  AS earliest_hire,
       MAX(hire_date)  AS latest_hire
FROM   employees;
```

> MIN/MAX는 숫자, 문자, 날짜 타입 모두 적용 가능하다.  
> 문자에 적용 시 알파벳(사전) 순서 기준으로 최솟값/최댓값을 반환한다.

---

**[4번] 답**

```sql
SELECT ROUND(AVG(salary), 3) AS avg_sal,
       MAX(salary)            AS max_sal,
       MIN(salary)            AS min_sal,
       SUM(salary)            AS sum_sal
FROM   employees
WHERE  job_id LIKE '%REP%';
```

> `WHERE job_id LIKE '%REP%'`: SA_REP, SA_MAN 등 'REP'가 포함된 직무만 필터링

---

**[5번] 답**

```sql
SELECT COUNT(DISTINCT department_id) AS unique_depts,
       COUNT(DISTINCT job_id)        AS unique_jobs
FROM   employees;
```

> - `COUNT(DISTINCT department_id)`: NULL 제외, 중복 제거 → 11  
> - `COUNT(DISTINCT job_id)`: 고유 직무 수 → 19

---

**[6번] 답**

```sql
SELECT ROUND(AVG(commission_pct), 4)           AS avg_comm_excl_null,
       ROUND(AVG(NVL(commission_pct, 0)), 4)   AS avg_comm_incl_null
FROM   employees;
```

> - 좌측: NULL 제외, 35명 기준 평균 ≈ 0.2229  
> - 우측: NVL로 NULL을 0으로 대체, 107명 기준 평균 ≈ 0.0729  
> 비즈니스 요구사항에 따라 어떤 방식을 사용할지 결정해야 한다.

---

## Group 2. GROUP BY 단일 열 모범답안 (7~12번)

---

**[7번] 답**

```sql
SELECT   department_id, COUNT(*) AS emp_count
FROM     employees
GROUP BY department_id
ORDER BY department_id;
```

> GROUP BY는 NULL도 하나의 그룹으로 처리하므로 NULL 부서(1명)도 결과에 포함된다.

---

**[8번] 답**

```sql
SELECT   department_id, ROUND(AVG(salary), 1) AS avg_salary
FROM     employees
GROUP BY department_id
ORDER BY avg_salary DESC;
```

---

**[9번] 답**

```sql
SELECT   job_id, COUNT(*) AS emp_count
FROM     employees
GROUP BY job_id
ORDER BY emp_count DESC, job_id;
```

---

**[10번] 답**

```sql
SELECT   manager_id, COUNT(*) AS subordinate_count
FROM     employees
WHERE    manager_id IS NOT NULL
GROUP BY manager_id
ORDER BY subordinate_count DESC;
```

> `WHERE manager_id IS NOT NULL`: GROUP BY 전에 행 필터링 (NULL인 manager_id 제외)

---

**[11번] 답**

```sql
SELECT   TO_CHAR(hire_date, 'YYYY') AS hire_year,
         COUNT(*)                   AS emp_count
FROM     employees
GROUP BY TO_CHAR(hire_date, 'YYYY')
ORDER BY hire_year;
```

> GROUP BY 절에 함수 표현식을 직접 사용할 수 있다.

---

**[12번] 답**

```sql
SELECT   department_id,
         MIN(hire_date) AS earliest_hire,
         MAX(hire_date) AS latest_hire
FROM     employees
GROUP BY department_id
ORDER BY department_id;
```

---

## Group 3. HAVING 절 모범답안 (13~18번)

---

**[13번] 답**

```sql
SELECT   department_id, MAX(salary) AS max_salary
FROM     employees
GROUP BY department_id
HAVING   MAX(salary) > 10000
ORDER BY department_id;
```

> HAVING은 GROUP BY 이후 그룹 함수 결과를 조건으로 그룹을 필터링한다.

---

**[14번] 답**

```sql
SELECT   department_id, COUNT(*) AS emp_count
FROM     employees
GROUP BY department_id
HAVING   COUNT(*) >= 5
ORDER BY emp_count DESC;
```

---

**[15번] 답**

```sql
SELECT   job_id, SUM(salary) AS payroll
FROM     employees
WHERE    job_id NOT LIKE '%REP%'
GROUP BY job_id
HAVING   SUM(salary) > 13000
ORDER BY payroll;
```

> - `WHERE job_id NOT LIKE '%REP%'`: 그룹화 전에 REP 포함 직무 제외 (행 필터)  
> - `HAVING SUM(salary) > 13000`: 그룹화 후 급여 합계 조건 (그룹 필터)

---

**[16번] 답**

```sql
SELECT   department_id, ROUND(AVG(salary)) AS avg_salary
FROM     employees
GROUP BY department_id
HAVING   AVG(salary) >= 8000
ORDER BY avg_salary DESC;
```

---

**[17번] 답**

```sql
SELECT   department_id, MIN(salary) AS min_salary
FROM     employees
GROUP BY department_id
HAVING   MIN(salary) >= 5000
ORDER BY department_id;
```

---

**[18번] 답**

```sql
SELECT   job_id, COUNT(*) AS emp_count
FROM     employees
GROUP BY job_id
HAVING   COUNT(*) >= 3
ORDER BY emp_count DESC, job_id;
```

---

## Group 4. 다중 열 GROUP BY 모범답안 (19~24번)

---

**[19번] 답**

```sql
SELECT   department_id, job_id, COUNT(*) AS emp_count
FROM     employees
WHERE    department_id > 40
GROUP BY department_id, job_id
ORDER BY department_id, job_id;
```

> 다중 열 GROUP BY: 두 열의 조합이 하나의 그룹이 된다.

---

**[20번] 답**

```sql
SELECT   department_id, job_id, SUM(salary) AS total_salary
FROM     employees
GROUP BY department_id, job_id
ORDER BY department_id, total_salary DESC;
```

---

**[21번] 답**

```sql
SELECT   TO_CHAR(hire_date, 'YYYY') AS hire_year,
         department_id,
         COUNT(*)                   AS emp_count
FROM     employees
GROUP BY TO_CHAR(hire_date, 'YYYY'), department_id
ORDER BY hire_year, department_id;
```

---

**[22번] 답**

```sql
SELECT   department_id, manager_id, COUNT(*) AS emp_count
FROM     employees
WHERE    manager_id IS NOT NULL
GROUP BY department_id, manager_id
ORDER BY department_id, manager_id;
```

---

**[23번] 답**

```sql
SELECT   department_id, job_id, ROUND(AVG(salary), 3) AS avg_salary
FROM     employees
WHERE    department_id IN (60, 80)
GROUP BY department_id, job_id
ORDER BY avg_salary DESC;
```

---

**[24번] 답**

```sql
SELECT   department_id, job_id, COUNT(*) AS emp_count
FROM     employees
GROUP BY department_id, job_id
HAVING   COUNT(*) >= 2
ORDER BY department_id, emp_count DESC;
```

---

## Group 5. 그룹 함수 중첩 & 종합 응용 모범답안 (25~30번)

---

**[25번] 답**

```sql
SELECT MAX(AVG(salary)) AS max_of_avg_salary
FROM   employees
GROUP BY department_id;
```

> **처리 순서:**  
> 1. `GROUP BY department_id`: 부서별로 그룹화  
> 2. `AVG(salary)`: 각 부서의 평균 급여 계산  
> 3. `MAX(...)`: 여러 부서 평균 중 최대값 1개 반환  
> Oracle에서 그룹 함수는 최대 2단계까지 중첩 가능하다.

---

**[26번] 답**

```sql
SELECT MIN(AVG(salary)) AS min_of_avg_salary
FROM   employees
GROUP BY department_id;
```

---

**[27번] 답**

```sql
SELECT department_id,
       LISTAGG(last_name, ', ')
           WITHIN GROUP (ORDER BY last_name) AS employees_list
FROM   employees
WHERE  department_id = 20
GROUP BY department_id;
```

> **LISTAGG 구문:**  
> - `LISTAGG(열, 구분자)`: 그룹 내 값을 구분자로 연결  
> - `WITHIN GROUP (ORDER BY 열)`: 연결 순서 지정 (필수)  
> 결과: `Fay, Hartstein`

---

**[28번] 답**

```sql
SELECT   department_id,
         LISTAGG(last_name, ', ')
             WITHIN GROUP (ORDER BY last_name) AS employees_list
FROM     employees
WHERE    department_id IN (50, 60)
GROUP BY department_id
ORDER BY department_id;
```

---

**[29번] 답**

```sql
SELECT   department_id          AS dept,
         COUNT(*)               AS emp_count,
         ROUND(AVG(salary))     AS avg_sal,
         MAX(salary)            AS max_sal,
         MIN(salary)            AS min_sal,
         SUM(salary)            AS sum_sal
FROM     employees
WHERE    department_id IN (20, 50, 60, 80, 90)
GROUP BY department_id
HAVING   SUM(salary) >= 50000
ORDER BY avg_sal DESC;
```

> - `WHERE`: 대상 부서를 미리 필터링 (행 필터)  
> - `HAVING SUM(salary) >= 50000`: 급여 합계 조건으로 그룹 필터링  
> 부서 60은 급여 합계 28,800으로 50,000 미만이므로 제외된다.

---

**[30번] 답**

```sql
SELECT   department_id             AS dept,
         job_id,
         COUNT(*)                  AS cnt,
         SUM(salary)               AS sum_sal,
         ROUND(AVG(salary))        AS avg_sal
FROM     employees
WHERE    salary > 2000
GROUP BY department_id, job_id
HAVING   SUM(salary) >= 5000
ORDER BY department_id, sum_sal DESC;
```

> **쿼리 처리 순서:**  
> 1. `FROM employees`: 테이블 접근  
> 2. `WHERE salary > 2000`: salary > 2000인 행만 남김  
> 3. `GROUP BY department_id, job_id`: 부서·직무 조합으로 그룹화  
> 4. `HAVING SUM(salary) >= 5000`: 급여 합계가 5,000 미만인 그룹 제거  
> 5. `SELECT`: 열 계산  
> 6. `ORDER BY`: 정렬
