# Oracle Database 19c: SQL Workshop
## Chapter 5 — 변환 함수와 조건식 | 연습문제

> **사용 스키마:** HR (Human Resources)  
> **범위:** 암시적/명시적 변환, TO_CHAR(날짜/숫자), TO_DATE, TO_NUMBER, CAST, NVL, NVL2, NULLIF, COALESCE, CASE, Searched CASE, DECODE, JSON 함수

---

# ★ 하 (기초) — 20문제

---

**[하-01]** 다음 중 Oracle의 암시적(Implicit) 데이터 타입 변환에 대한 설명으로 올바른 것은?

① 사용자가 TO_CHAR 함수를 직접 작성하여 수행한다  
② Oracle 서버가 자동으로 필요한 타입으로 변환한다  
③ 암시적 변환은 항상 오류를 발생시킨다  
④ 숫자에서 날짜로만 변환 가능하다

---

**[하-02]** `TO_CHAR(hire_date, 'YYYY')` 의 결과로 올바른 것은? (hire_date = 17-JUN-87)

① `17`  
② `JUN`  
③ `1987`  
④ `JUNE`

---

**[하-03]** 날짜 형식 모델에서 `MM`이 반환하는 것은?

① 월 전체 이름 (예: JUNE)  
② 두 자리 월 숫자 (예: 06)  
③ 월 3자리 약어 (예: JUN)  
④ 요일 이름 (예: MONDAY)

---

**[하-04]** `TO_CHAR(hire_date, 'DD Month YYYY')` 에서 `fm` 접두사를 추가하는 이유는?

① 날짜를 숫자로 변환하기 위해  
② 앞 공백과 앞의 0을 제거하여 깔끔하게 출력하기 위해  
③ 날짜 형식을 강제로 변경하기 위해  
④ NULL 값을 처리하기 위해

---

**[하-05]** `TO_CHAR(salary, '$99,999.00')` 에서 숫자 형식의 `0`의 역할은?

① 숫자 자리를 나타내며 앞자리가 없으면 공백 표시  
② 0을 강제로 표시 (자릿수가 모자라도 0 표시)  
③ 소수점 구분자  
④ 천 단위 구분자

---

**[하-06]** `TO_NUMBER('$1,234', '$9,999')` 의 결과는?

① `'$1,234'` (변환 안 됨)  
② `1234`  
③ `1.234`  
④ 오류 발생

---

**[하-07]** `TO_DATE('25-DEC-23', 'DD-MON-RR')` 의 결과로 올바른 것은?

① 1923년 12월 25일  
② 2023년 12월 25일  
③ 2123년 12월 25일  
④ 오류 발생

---

**[하-08]** `NVL(commission_pct, 0)` 함수에 대한 설명으로 올바른 것은?

① commission_pct가 0이면 NULL을 반환한다  
② commission_pct가 NULL이면 0을 반환한다  
③ commission_pct가 NULL이 아니면 0을 반환한다  
④ commission_pct와 0 중 큰 값을 반환한다

---

**[하-09]** `NVL2(commission_pct, 'SAL+COMM', 'SAL')` 에서 commission_pct가 NULL이면 반환값은?

① `'SAL+COMM'`  
② `'SAL'`  
③ NULL  
④ commission_pct 값

---

**[하-10]** `NULLIF(10, 10)` 의 결과는?

① `10`  
② `0`  
③ NULL  
④ 오류 발생

---

**[하-11]** `COALESCE(NULL, NULL, 100, 200)` 의 결과는?

① NULL  
② `100`  
③ `200`  
④ `300`

---

**[하-12]** CASE 표현식의 설명으로 올바른 것은?

① Oracle 전용 기능으로 표준 SQL에서는 사용 불가  
② IF-THEN-ELSE 논리를 SQL 문에서 구현한다  
③ 한 번에 하나의 조건만 평가할 수 있다  
④ SELECT 절에서는 사용할 수 없다

---

**[하-13]** 다음 CASE 표현식의 결과는? (job_id = 'IT_PROG', salary = 9000)

```sql
CASE job_id
    WHEN 'IT_PROG'  THEN 1.10 * salary
    WHEN 'ST_CLERK' THEN 1.15 * salary
    ELSE salary
END
```

① `9000`  
② `9900`  
③ `10350`  
④ NULL

---

**[하-14]** Searched CASE 표현식에서 각 WHEN 절에 올 수 있는 것은?

① 등가 비교(`=`)만 가능  
② 범위 비교(`<`, `>`, `BETWEEN`)를 포함한 모든 조건  
③ 문자 비교만 가능  
④ 날짜 비교만 가능

---

**[하-15]** `DECODE(job_id, 'SA_REP', 1.20*salary, salary)` 에서 job_id가 'AD_PRES'일 때 결과는?

① NULL  
② `1.20 * salary`  
③ `salary` (기본값)  
④ 오류 발생

---

**[하-16]** 다음 중 CASE와 DECODE의 차이로 올바른 것은?

① DECODE는 ANSI 표준이고 CASE는 Oracle 전용이다  
② CASE는 범위 조건 처리 가능, DECODE는 등가 비교만 가능  
③ DECODE는 SELECT 절에서 사용 불가  
④ 두 함수는 완전히 동일하다

---

**[하-17]** `TO_CHAR(SYSDATE, 'HH24:MI:SS')` 의 결과 형식은?

① `2024-06-17`  
② `06/17/24`  
③ `15:30:22` (현재 시간)  
④ `JUNE 17`

---

**[하-18]** `TO_CHAR` 날짜 형식에서 `DY`가 반환하는 것은?

① 두 자리 일 숫자 (예: 17)  
② 요일 3자리 약어 (예: MON, TUE)  
③ 요일 전체 이름 (예: MONDAY)  
④ 월 3자리 약어 (예: JUN)

---

**[하-19]** `NVL` 함수에서 두 인수의 데이터 타입이 다르면 어떻게 되는가?

① 자동으로 변환되어 항상 성공  
② 오류 발생 — 두 표현식의 데이터 타입이 일치해야 한다  
③ 첫 번째 인수 타입을 기준으로 자동 변환  
④ NULL을 반환

---

**[하-20]** 다음 CASE 표현식에서 salary가 12000일 때의 결과는?

```sql
CASE
    WHEN salary < 5000  THEN 'Low'
    WHEN salary < 10000 THEN 'Medium'
    WHEN salary < 20000 THEN 'Good'
    ELSE 'Excellent'
END
```

① `'Low'`  
② `'Medium'`  
③ `'Good'`  
④ `'Excellent'`

---

# ★★ 중 (응용) — 20문제

---

**[중-01]** EMPLOYEES 테이블에서 모든 사원의 hire_date를 `'DD Month YYYY'` 형식으로 출력하시오. (fm 접두사 활용)

---

**[중-02]** EMPLOYEES 테이블에서 last_name이 'Higgins'인 사원의 입사 월과 연도를 `'MM/YY'` 형식으로 출력하시오.

---

**[중-03]** EMPLOYEES 테이블에서 salary를 `'$99,999.00'` 형식의 문자열로 출력하시오.  
출력 열: last_name, 형식화된 salary

---

**[중-04]** EMPLOYEES 테이블에서 commission_pct가 NULL인 경우 0으로 대체하여 연봉(annual_salary)을 계산하시오.  
(연봉 = salary × 12 + salary × 12 × commission_pct)

---

**[중-05]** EMPLOYEES 테이블에서 commission_pct가 있는 사원은 `'SAL+COMM'`, 없는 사원은 `'SAL ONLY'`로 표시하시오.  
(NVL2 사용)

---

**[중-06]** EMPLOYEES 테이블에서 first_name의 길이와 last_name의 길이를 비교하여 같으면 NULL, 다르면 first_name 길이를 출력하시오.  
(NULLIF 사용)

---

**[중-07]** EMPLOYEES 테이블에서 commission_pct가 있으면 salary + (salary × commission_pct), 없으면 salary + 500을 반환하는 쿼리를 작성하시오.  
(COALESCE 사용)

---

**[중-08]** EMPLOYEES 테이블에서 2010년 이전에 입사한 사원의 last_name과 hire_date를 `'DD-Mon-YYYY'` 형식으로 출력하시오.  
(TO_DATE와 TO_CHAR 함께 사용)

---

**[중-09]** EMPLOYEES 테이블에서 직무 코드에 따라 급여를 인상한 값을 출력하시오.

| 직무 코드 | 인상률 |
|----------|--------|
| IT_PROG | 10% 인상 |
| ST_CLERK | 15% 인상 |
| SA_REP | 20% 인상 |
| 나머지 | 현재 급여 유지 |

(CASE 표현식 사용)

---

**[중-10]** 중-09번을 DECODE 함수로 동일하게 작성하시오.

---

**[중-11]** EMPLOYEES 테이블에서 급여 범위에 따른 등급을 부여하시오.

| 급여 범위 | 등급 |
|----------|------|
| 5,000 미만 | 'Low' |
| 5,000 이상 10,000 미만 | 'Medium' |
| 10,000 이상 20,000 미만 | 'High' |
| 20,000 이상 | 'Top' |

(Searched CASE 사용)

---

**[중-12]** EMPLOYEES 테이블에서 hire_date를 `'fmDay, DD Month YYYY'` 형식으로 출력하시오.  
(요일 이름 포함)

---

**[중-13]** EMPLOYEES 테이블에서 부서 80의 사원들에게 급여 구간에 따른 세율을 계산하시오.  
(DECODE와 TRUNC 사용, salary/2000 몫 기준)

| 몫 | 세율 |
|----|------|
| 0 | 0.00 |
| 1 | 0.09 |
| 2 | 0.20 |
| 3 | 0.30 |
| 4 | 0.40 |
| 기타 | 0.45 |

---

**[중-14]** EMPLOYEES 테이블에서 manager_id가 NULL인 사원은 'No Manager', NULL이 아닌 사원은 manager_id를 문자열로 출력하시오.  
(NVL 또는 COALESCE 사용)

---

**[중-15]** `dual` 테이블을 사용하여 다음을 출력하시오.

- 현재 날짜를 `'YYYY년 MM월 DD일'` 형식으로
- 현재 시간을 `'HH24시 MI분 SS초'` 형식으로

---

**[중-16]** EMPLOYEES 테이블에서 salary가 `'L99,999'` 형식 (지역 통화 기호 포함)으로 출력되도록 하시오.

---

**[중-17]** EMPLOYEES 테이블에서 입사 연도를 기준으로 다음 분류를 적용하시오.

| 입사 연도 | 분류 |
|----------|------|
| 1987년 이전 | '원년 멤버' |
| 1990년 이전 | '90년대 이전' |
| 2000년 이전 | '90년대' |
| 2000년 이후 | '2000년대 이후' |

(Searched CASE와 TO_CHAR 사용)

---

**[중-18]** EMPLOYEES 테이블에서 commission_pct의 실제 값이 없는 (NULL) 사원 수와 있는 사원 수를 각각 출력하시오.  
힌트: NVL2와 COUNT를 조합하거나 조건절 사용

---

**[중-19]** 문자열 `'2023-12-25'`를 Oracle 날짜로 변환하는 SQL을 작성하시오.  
(TO_DATE 사용, 형식 모델 지정)

---

**[중-20]** EMPLOYEES 테이블에서 salary를 `'000,099,999'` 형식으로 출력하여 앞에 0이 채워지도록 하시오.  
출력 열: last_name, salary, formatted_salary

---

# ★★★ 상 (심화) — 10문제

---

**[상-01]** 다음 두 SQL 문의 결과 차이를 분석하시오.

```sql
-- (A)
SELECT TO_CHAR(hire_date, 'DD Month YYYY') AS hire_fmt
FROM   employees WHERE last_name = 'King';

-- (B)
SELECT TO_CHAR(hire_date, 'fmDD Month YYYY') AS hire_fmt
FROM   employees WHERE last_name = 'King';
```

(1) `fm` 접두사 유무에 따른 결과 차이를 설명하시오.  
(2) King의 hire_date = 17-JUN-87 기준으로 각 출력을 예측하시오.

---

**[상-02]** 다음 SQL에서 오류를 찾아 수정하시오.

```sql
SELECT last_name, NVL(commission_pct, 'None'),
       TO_CHAR(hire_date, 'DD-MON-YYYY'),
       TO_NUMBER(salary, 'XXXXXX')
FROM   employees;
```

---

**[상-03]** EMPLOYEES 테이블에서 다음 조건을 모두 처리하는 단일 SQL 문을 작성하시오.

- commission_pct가 NULL이 아닌 사원: 연봉 = salary × 12 × (1 + commission_pct)
- commission_pct가 NULL인 사원: 연봉 = salary × 12
- 연봉을 `'$999,999'` 형식으로 출력
- 입사일을 `'fmDD Month YYYY'` 형식으로 출력
- 정렬: 연봉 내림차순

---

**[상-04]** 다음 CASE 표현식과 DECODE 함수가 동일한 결과를 내는지 분석하시오.

```sql
-- CASE
CASE job_id
    WHEN 'IT_PROG' THEN 1.10 * salary
    WHEN 'SA_REP'  THEN 1.20 * salary
    ELSE salary
END

-- DECODE
DECODE(job_id, 'IT_PROG', 1.10*salary, 'SA_REP', 1.20*salary, salary)
```

(1) 두 표현식이 항상 동일한 결과를 반환하는지 설명하시오.  
(2) NULL 값 처리에서 차이가 발생할 수 있는지 설명하시오.

---

**[상-05]** COALESCE와 NVL의 차이를 설명하고, 다음 상황에서 어떤 함수가 더 적합한지 판단하시오.

상황: 사원의 연락처를 표시하는데, 우선순위는 휴대폰 → 이메일 → '연락처 없음' 순서이다.

---

**[상-06]** EMPLOYEES 테이블에서 다음을 출력하는 SQL 문을 작성하시오.

- 사원의 full_name (first_name + ' ' + last_name)
- hire_date를 `'fmDD Month YYYY'` 형식으로 (입사일)
- 입사 분기(Q1/Q2/Q3/Q4) — Searched CASE와 TO_CHAR(hire_date, 'MM') 조합
- salary를 `'$999,999'` 형식으로

---

**[상-07]** 다음 SQL 문의 실행 결과를 분석하시오.

```sql
SELECT last_name, salary, commission_pct,
       NULLIF(ROUND(salary/1000), TRUNC(salary/1000)) AS result
FROM   employees
WHERE  department_id = 80;
```

(1) NULLIF 함수가 NULL을 반환하는 경우는 언제인가?  
(2) 부서 80 사원들 중 이 NULLIF가 NULL을 반환하는 사원이 있는지 설명하시오.  
    (부서 80 급여: 6100, 6200, 7900, 8600 등 — 모두 정수)

---

**[상-08]** EMPLOYEES 테이블에서 다음 요구사항을 만족하는 SQL을 작성하시오.

- 사원 이름(full_name)
- 근속 연수 계산 (현재 연도 - TO_NUMBER(TO_CHAR(hire_date, 'YYYY')))
- 근속 연수 기준 보너스 지급:
  - 30년 이상: salary × 0.30
  - 20년 이상: salary × 0.20
  - 10년 이상: salary × 0.10
  - 10년 미만: salary × 0.05
- 보너스를 `'$99,999.00'` 형식으로 출력
- 정렬: 근속 연수 내림차순

---

**[상-09]** 다음 SQL 문을 분석하고 출력을 예측하시오.

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

(부서 90: King hire_date=87-06-17, Kochhar hire_date=89-09-21, De Haan hire_date=93-01-13)

---

**[상-10]** 다음 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항:
- EMPLOYEES 테이블에서 조회
- 사원의 연간 총 보상(total compensation) 계산:
  - commission이 있으면: (salary × 12) + (salary × 12 × commission_pct)
  - commission이 없으면: salary × 12 + 1000 (고정 보너스)
  - NVL2 또는 COALESCE 사용
- 총 보상을 `'$999,999'` 형식으로 출력
- 급여 등급 (Searched CASE):
  - 총보상 50,000 미만: 'Grade A'
  - 50,000 이상 100,000 미만: 'Grade B'
  - 100,000 이상 200,000 미만: 'Grade C'
  - 200,000 이상: 'Grade D'
- 출력 열: employee_id, last_name, total_comp_formatted, grade
- 정렬: 총 보상 내림차순
