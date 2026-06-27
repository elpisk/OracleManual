# Oracle Database 19c: SQL Workshop
## Chapter 5 — 변환 함수와 조건식 | SQL 실습 문제 모범답안

---

## Group 1. TO_CHAR 날짜 형식 모범답안 (1~6번)

---

**[1번] 답**

```sql
SELECT last_name,
       TO_CHAR(hire_date, 'fmDD Month YYYY') AS hire_date_fmt
FROM   employees;
```

> `fm`: 앞 공백/0 제거, Month는 각 단어 첫 글자만 대문자로 표시

---

**[2번] 답**

```sql
SELECT employee_id,
       TO_CHAR(hire_date, 'MM/YY') AS month_hired
FROM   employees
WHERE  last_name = 'Higgins';
```

> Higgins hire_date = 07-JUN-02 → `06/02`

---

**[3번] 답**

```sql
SELECT last_name,
       TO_CHAR(hire_date, 'fmDay, DD Month YYYY') AS full_hire_date
FROM   employees;
```

> `Day`: 요일 전체 이름 (Wednesday)  
> `fm`: 요일 이름 뒤 불필요한 공백 제거  
> King: `Wednesday, 17 June 1987`

---

**[4번] 답**

```sql
SELECT last_name,
       TO_CHAR(hire_date, 'YYYY') AS hire_year
FROM   employees
WHERE  department_id = 90;
```

---

**[5번] 답**

```sql
SELECT TO_CHAR(SYSDATE, 'YYYY"년" MM"월" DD"일"') AS date_kr,
       TO_CHAR(SYSDATE, 'HH24"시" MI"분" SS"초"') AS time_kr
FROM   dual;
```

> 리터럴 문자열은 큰따옴표(`"`)로 감싸서 형식 모델 안에 삽입한다.

---

**[6번] 답**

```sql
SELECT last_name,
       hire_date,
       'Q' || TO_CHAR(hire_date, 'Q') AS quarter
FROM   employees;
```

> `TO_CHAR(date, 'Q')`: 해당 날짜의 분기 숫자 반환 (1~4)  
> `'Q' ||` : 문자열 결합으로 'Q1', 'Q2' 형태 생성  
> King(87-06-17): 6월 → 2분기 → `Q2`

---

## Group 2. TO_CHAR 숫자 형식 모범답안 (7~10번)

---

**[7번] 답**

```sql
SELECT last_name,
       TO_CHAR(salary, '$99,999.00') AS formatted_salary
FROM   employees;
```

> King(24000) → `$24,000.00`  
> `$`: 달러 기호, `,`: 천 단위, `.00`: 소수 2자리 강제 표시

---

**[8번] 답**

```sql
SELECT last_name,
       TO_CHAR(salary, 'L99,999') AS local_salary
FROM   employees;
```

> `L`: 세션의 NLS 지역 통화 기호 자동 적용 (미국: $, 한국: ₩)

---

**[9번] 답**

```sql
SELECT last_name,
       TO_CHAR(salary, '0000000000') AS padded_salary
FROM   employees;
```

> `0` 형식: 해당 자리에 숫자가 없으면 0 표시  
> 10자리 모두 `0`으로 지정하면 앞에 0이 채워진다.  
> King(24000) → `0000024000`

---

**[10번] 답**

```sql
SELECT last_name,
       TO_CHAR(
           (salary * 12) + (salary * 12 * NVL(commission_pct, 0)),
           '$999,999') AS annual_salary_fmt
FROM   employees;
```

> Russell(salary=14000, commission=0.4):  
> 14000×12 + 14000×12×0.4 = 168,000 + 67,200 = $235,200

---

## Group 3. NVL / NVL2 / NULLIF / COALESCE 모범답안 (11~17번)

---

**[11번] 답**

```sql
SELECT last_name, salary, commission_pct,
       NVL(commission_pct, 0) AS nvl_result
FROM   employees;
```

> commission_pct가 NULL이면 0, 아니면 실제 값 표시

---

**[12번] 답**

```sql
SELECT last_name, salary,
       NVL(commission_pct, 0) AS commission_pct,
       (salary * 12) + (salary * 12 * NVL(commission_pct, 0)) AS an_sal
FROM   employees;
```

---

**[13번] 답**

```sql
SELECT last_name, salary,
       NVL2(commission_pct, 'Commission', 'No Commission') AS status
FROM   employees;
```

> NVL2(expr1, expr2, expr3):  
> - expr1 ≠ NULL → expr2 ('Commission')  
> - expr1 = NULL → expr3 ('No Commission')

---

**[14번] 답**

```sql
SELECT first_name,
       last_name,
       LENGTH(first_name) AS fn_len,
       LENGTH(last_name)  AS ln_len,
       NULLIF(LENGTH(first_name), LENGTH(last_name)) AS result
FROM   employees;
```

> 두 길이가 같으면 NULL, 다르면 first_name 길이 반환

---

**[15번] 답**

```sql
SELECT last_name, salary, commission_pct,
       COALESCE(salary + (salary * commission_pct),
                salary + 500) AS adjusted_salary
FROM   employees;
```

> commission_pct가 NULL이면 첫 표현식 결과가 NULL  
> → COALESCE가 두 번째 값(salary + 500) 반환

---

**[16번] 답**

```sql
SELECT last_name,
       NVL(TO_CHAR(manager_id), '최고 경영자') AS manager_info
FROM   employees;
```

> manager_id는 NUMBER 타입이므로 TO_CHAR로 변환 후 NVL 적용  
> King(manager_id=NULL) → '최고 경영자'

---

**[17번] 답**

```sql
SELECT last_name,
       commission_pct,
       ROUND(salary / 10000, 1) AS salary_ratio,
       NULLIF(commission_pct, ROUND(salary / 10000, 1)) AS nullif_result
FROM   employees
WHERE  commission_pct IS NOT NULL;
```

> commission_pct = salary/10000이면 NULL 반환  
> 실제로 같은 경우는 드물어 대부분 commission_pct 값이 그대로 반환됨

---

## Group 4. CASE / DECODE 모범답안 (18~25번)

---

**[18번] 답**

```sql
SELECT last_name, job_id, salary,
       CASE job_id
           WHEN 'IT_PROG'  THEN 1.10 * salary
           WHEN 'ST_CLERK' THEN 1.15 * salary
           WHEN 'SA_REP'   THEN 1.20 * salary
           ELSE salary
       END AS revised_salary
FROM   employees;
```

---

**[19번] 답**

```sql
SELECT last_name, job_id, salary,
       DECODE(job_id,
              'IT_PROG',  1.10 * salary,
              'ST_CLERK', 1.15 * salary,
              'SA_REP',   1.20 * salary,
              salary) AS revised_salary
FROM   employees;
```

> 18번의 CASE 표현식과 동일한 결과

---

**[20번] 답**

```sql
SELECT last_name, salary,
       CASE
           WHEN salary < 5000  THEN 'Low'
           WHEN salary < 10000 THEN 'Medium'
           WHEN salary < 20000 THEN 'High'
           ELSE 'Excellent'
       END AS salary_grade
FROM   employees;
```

---

**[21번] 답**

```sql
SELECT last_name, salary,
       DECODE(TRUNC(salary / 2000, 0),
              0, 0.00,
              1, 0.09,
              2, 0.20,
              3, 0.30,
              4, 0.40,
              0.45) AS tax_rate
FROM   employees
WHERE  department_id = 80;
```

> Russell(14000): 14000/2000=7.0 → 몫=7 → 기본값 0.45  
> Marjoram(6200): 6200/2000=3.1 → 몫=3 → 0.30

---

**[22번] 답**

```sql
SELECT last_name,
       TO_CHAR(hire_date, 'YYYY') AS hire_year,
       DECODE(TO_CHAR(hire_date, 'YYYY'),
              '1987', '원년 멤버',
              '1989', '초기 멤버',
              '일반 멤버') AS member_type
FROM   employees
WHERE  department_id = 90;
```

---

**[23번] 답**

```sql
SELECT last_name, hire_date,
       TO_CHAR(hire_date, 'DY') AS hire_day,
       CASE TO_CHAR(hire_date, 'DY')
           WHEN 'MON' THEN 500
           WHEN 'FRI' THEN 300
           ELSE 0
       END AS allowance
FROM   employees;
```

---

**[24번] 답**

```sql
SELECT last_name,
       NVL2(commission_pct,
            TO_CHAR((salary * 12) + (salary * 12 * commission_pct), '$999,999'),
            'No Commission') AS commission_status
FROM   employees;
```

> NVL2: commission_pct ≠ NULL → TO_CHAR로 연봉 형식화  
>         commission_pct = NULL → 'No Commission' 문자열

---

**[25번] 답**

```sql
SELECT last_name, department_id,
       DECODE(department_id,
              10, '본사',
              20, '마케팅',
              30, '구매',
              60, 'IT',
              80, '영업',
              90, '경영진',
              '기타부서') AS dept_name
FROM   employees
ORDER BY department_id;
```

---

## Group 5. 종합 응용 모범답안 (26~30번)

---

**[26번] 답**

```sql
SELECT first_name || ' ' || last_name          AS full_name,
       TO_CHAR(hire_date, 'fmDD Month YYYY')   AS hire_date_fmt,
       TO_CHAR(salary, '$99,999')              AS salary_fmt,
       NVL(commission_pct, 0)                  AS commission
FROM   employees
WHERE  department_id IN (50, 80, 90)
ORDER BY hire_date;
```

---

**[27번] 답**

```sql
SELECT employee_id,
       last_name,
       TO_CHAR(
           NVL2(commission_pct,
                salary * 12 * (1 + commission_pct),
                salary * 12 + 1000),
           '$999,999') AS total_comp_fmt
FROM   employees
ORDER BY NVL2(commission_pct,
              salary * 12 * (1 + commission_pct),
              salary * 12 + 1000) DESC;
```

> King(salary=24000, no commission): 24000×12 + 1000 = 289,000  
> Russell(salary=14000, commission=0.4): 14000×12×1.4 = 235,200

---

**[28번] 답**

```sql
SELECT last_name,
       salary,
       CASE
           WHEN salary < 5000  THEN 'Low'
           WHEN salary < 10000 THEN 'Medium'
           WHEN salary < 20000 THEN 'High'
           ELSE 'Excellent'
       END AS grade,
       DECODE(TRUNC(salary / 5000, 0),
              0, '5%',
              1, '10%',
              2, '15%',
              '20%') AS tax_rate
FROM   employees
ORDER BY salary DESC;
```

---

**[29번] 답**

```sql
SELECT last_name,
       TO_CHAR(hire_date, 'fmDD Month YYYY')   AS hire_date_fmt,
       TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')) -
       TO_NUMBER(TO_CHAR(hire_date, 'YYYY'))   AS years,
       CASE
           WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) -
                TO_NUMBER(TO_CHAR(hire_date,'YYYY')) >= 30 THEN '30년+'
           WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) -
                TO_NUMBER(TO_CHAR(hire_date,'YYYY')) >= 20 THEN '20년+'
           WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) -
                TO_NUMBER(TO_CHAR(hire_date,'YYYY')) >= 10 THEN '10년+'
           ELSE '신입'
       END AS grade
FROM   employees
ORDER BY years DESC;
```

---

**[30번] 답**

```sql
SELECT first_name || ' ' || last_name            AS full_name,
       TO_CHAR(hire_date, 'fmDD Month YYYY')     AS hire_date_fmt,
       TO_CHAR(salary, '$99,999')                AS salary_fmt,
       TO_CHAR(
           (salary * 12) + (salary * 12 * NVL(commission_pct, 0)),
           '$999,999')                           AS annual_fmt,
       CASE
           WHEN salary < 5000  THEN 'Low'
           WHEN salary < 10000 THEN 'Medium'
           WHEN salary < 20000 THEN 'High'
           ELSE 'Excellent'
       END                                       AS grade,
       'Q' || TO_CHAR(hire_date, 'Q')            AS quarter
FROM   employees
WHERE  hire_date >= TO_DATE('01-JAN-00', 'DD-MON-RR')
ORDER BY hire_date;
```

> **조건 설명:**
> - `hire_date >= TO_DATE('01-JAN-00', 'DD-MON-RR')`: 2000년 이후 입사자  
> - `NVL(commission_pct, 0)`: commission_pct가 NULL이면 0으로 대체하여 연봉 계산  
> - `'Q' || TO_CHAR(hire_date, 'Q')`: 입사 분기 ('Q1'~'Q4')
