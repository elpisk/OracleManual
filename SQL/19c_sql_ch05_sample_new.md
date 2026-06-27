# Oracle Database 19c: SQL Workshop
## Chapter 5 — 변환 함수와 조건식 | SQL 실습 문제 (sql_sample 참고형)

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources)  
> **범위:** TO_CHAR(날짜/숫자), TO_DATE, TO_NUMBER, NVL, NVL2, NULLIF, COALESCE, CASE, Searched CASE, DECODE  
> **작성 방식:** 주어진 출력 결과를 보고 SQL 문을 직접 작성하시오.

---

## Group 1. TO_CHAR — 날짜 형식 변환 (1~6번)

---

**[1번]** EMPLOYEES 테이블에서 all 사원의 last_name과 hire_date를 `'fmDD Month YYYY'` 형식으로 출력하시오.

```
LAST_NAME  HIRE_DATE_FMT
---------- ---------------------
King       17 June 1987
Kochhar    21 September 1989
De Haan    13 January 1993
Hunold     3 January 1990
...
(107개 행)
```

---

**[2번]** EMPLOYEES 테이블에서 last_name이 'Higgins'인 사원의 employee_id와 입사 월/연도를 `'MM/YY'` 형식으로 출력하시오.

```
EMPLOYEE_ID MONTH_HIRED
----------- -----------
        205 06/02
(1개 행)
```

---

**[3번]** EMPLOYEES 테이블에서 모든 사원의 hire_date를 `'fmDay, DD Month YYYY'` 형식으로 출력하시오. (요일 이름 포함)

```
LAST_NAME  FULL_HIRE_DATE
---------- -------------------------
King       Wednesday, 17 June 1987
Kochhar    Thursday, 21 September 1989
De Haan    Wednesday, 13 January 1993
...
```

---

**[4번]** EMPLOYEES 테이블에서 부서 90 사원의 last_name과 hire_date에서 연도만 4자리 숫자로 추출하시오.

```
LAST_NAME  HIRE_YEAR
---------- ----------
King       1987
Kochhar    1989
De Haan    1993
(3개 행)
```

---

**[5번]** `dual` 테이블에서 현재 날짜와 시간을 다음 형식으로 출력하시오.

```
DATE_KR               TIME_KR
--------------------- -------------------
2026년 06월 27일      14시 30분 22초
```

---

**[6번]** EMPLOYEES 테이블에서 hire_date를 기준으로 입사 분기(Q1/Q2/Q3/Q4)를 출력하시오.  
(TO_CHAR와 SUBSTR 또는 TO_CHAR의 Q 형식 모델 활용)

```
LAST_NAME  HIRE_DATE  QUARTER
---------- ---------- -------
King       87/06/17   Q2
Kochhar    89/09/21   Q3
De Haan    93/01/13   Q1
...
```

---

## Group 2. TO_CHAR — 숫자 형식 변환 (7~10번)

---

**[7번]** EMPLOYEES 테이블에서 salary를 `'$99,999.00'` 형식으로 출력하시오.

```
LAST_NAME  FORMATTED_SALARY
---------- ----------------
King       $24,000.00
Kochhar    $17,000.00
De Haan    $17,000.00
...
```

---

**[8번]** EMPLOYEES 테이블에서 salary를 `'L99,999'` 형식(지역 통화 기호 포함)으로 출력하시오.

```
LAST_NAME  LOCAL_SALARY
---------- ------------
King       $24,000
Kochhar    $17,000
...
```

---

**[9번]** EMPLOYEES 테이블에서 salary를 10자리 고정 폭으로 앞에 0을 채워 출력하시오.

```
LAST_NAME  PADDED_SALARY
---------- -------------
King       0000024000
Kochhar    0000017000
...
```

---

**[10번]** EMPLOYEES 테이블에서 salary와 commission_pct를 이용하여 연봉을 계산하고 `'$999,999'` 형식으로 출력하시오.  
(commission_pct가 NULL인 경우 0으로 처리 — NVL 활용)

```
LAST_NAME  ANNUAL_SALARY_FMT
---------- -----------------
Russell    $201,600        ← 14000 × 12 × (1 + 0.4) = 235,200? (14000*12=168000 + 14000*12*0.4=67200 = 235,200)
King       $288,000
...
```

---

## Group 3. NVL / NVL2 / NULLIF / COALESCE (11~17번)

---

**[11번]** EMPLOYEES 테이블에서 commission_pct가 NULL이면 0, 아니면 실제 값을 출력하시오.  
출력 열: last_name, salary, commission_pct, NVL 적용 결과

```
LAST_NAME  SALARY COMMISSION_PCT NVL_RESULT
---------- ------ -------------- ----------
King        24000                         0
Kochhar     17000                         0
...
Russell     14000             .4         .4
...
```

---

**[12번]** EMPLOYEES 테이블에서 commission_pct 유무에 따른 연봉 계산을 NVL을 사용하여 출력하시오.

공식: `(salary × 12) + (salary × 12 × NVL(commission_pct, 0))`

```
LAST_NAME  SALARY COMMISSION_PCT AN_SAL
---------- ------ -------------- ------
King        24000              0 288000
...
Russell     14000             .4 235200
...
```

---

**[13번]** EMPLOYEES 테이블에서 commission_pct가 있으면 `'Commission'`, 없으면 `'No Commission'`으로 표시하시오.  
(NVL2 사용)

```
LAST_NAME  SALARY STATUS
---------- ------ ---------------
King        24000 No Commission
...
Russell     14000 Commission
...
```

---

**[14번]** EMPLOYEES 테이블에서 first_name 길이와 last_name 길이를 비교하여, 같으면 NULL, 다르면 first_name 길이를 출력하시오.  
(NULLIF 사용)

```
FIRST_NAME LAST_NAME  FN_LEN LN_LEN RESULT
---------- ---------- ------ ------ ------
Steven     King            6      4      6
Neena      Kochhar         5      7      5
Lex        De Haan         3      7      3
...
```

---

**[15번]** EMPLOYEES 테이블에서 다음 우선순위로 급여 보정값을 출력하시오.  
COALESCE를 사용하여, commission이 있으면 `salary + (salary × commission_pct)`, 없으면 `salary + 500`

```
LAST_NAME  SALARY COMMISSION_PCT ADJUSTED_SALARY
---------- ------ -------------- ---------------
King        24000              0           24500
...
Russell     14000             .4           19600
...
```

---

**[16번]** EMPLOYEES 테이블에서 manager_id가 NULL인 경우 `'최고 경영자'`, 아닌 경우 manager_id를 문자로 출력하시오.

```
LAST_NAME  MANAGER_INFO
---------- ----------------
King       최고 경영자
Kochhar    100
De Haan    100
...
```

---

**[17번]** EMPLOYEES 테이블에서 commission_pct와 (salary/10000)의 값이 같은 경우 NULL, 다르면 commission_pct를 출력하시오.  
(NULLIF 활용 — 실제 같은 경우는 드물지만 함수 사용법 연습)

```
LAST_NAME  COMMISSION_PCT SALARY_RATIO NULLIF_RESULT
---------- -------------- ------------ -------------
Russell              .4       1.4           .4
...
```

---

## Group 4. CASE / Searched CASE / DECODE (18~25번)

---

**[18번]** EMPLOYEES 테이블에서 직무 코드에 따른 급여 인상분을 CASE로 계산하시오.

| 직무 | 인상률 |
|------|--------|
| IT_PROG | 10% |
| ST_CLERK | 15% |
| SA_REP | 20% |
| 기타 | 변동 없음 |

```
LAST_NAME  JOB_ID     SALARY REVISED_SALARY
---------- ---------- ------ --------------
King       AD_PRES     24000          24000
...
Hunold     IT_PROG      9000           9900
...
```

---

**[19번]** 18번 문제를 DECODE로 동일하게 작성하시오.

---

**[20번]** EMPLOYEES 테이블에서 급여 범위에 따른 등급을 Searched CASE로 출력하시오.

| 급여 | 등급 |
|------|------|
| 5,000 미만 | 'Low' |
| 5,000 이상 10,000 미만 | 'Medium' |
| 10,000 이상 20,000 미만 | 'High' |
| 20,000 이상 | 'Excellent' |

```
LAST_NAME  SALARY SALARY_GRADE
---------- ------ ------------
King        24000 Excellent
Kochhar     17000 High
...
Olson        2100 Low
...
```

---

**[21번]** 부서 80 사원에게 급여 구간 기준 세율을 DECODE로 적용하시오.  
(`TRUNC(salary/2000, 0)` 몫 기준)

| 몫 | 세율 |
|----|------|
| 0 | 0.00 |
| 1 | 0.09 |
| 2 | 0.20 |
| 3 | 0.30 |
| 4 | 0.40 |
| 기타 | 0.45 |

```
LAST_NAME  SALARY TAX_RATE
---------- ------ --------
Russell     14000     0.45
Partners    13500     0.45
...
Marjoram     6200     0.20
...
```

---

**[22번]** EMPLOYEES 테이블에서 입사 연도에 따른 구성원 분류를 DECODE로 출력하시오.

```
LAST_NAME  HIRE_YEAR  MEMBER_TYPE
---------- ---------- -----------
King       1987       원년 멤버
Kochhar    1989       초기 멤버
De Haan    1993       일반 멤버
...
```

(1987년 → '원년 멤버', 1989년 → '초기 멤버', 나머지 → '일반 멤버')

---

**[23번]** EMPLOYEES 테이블에서 요일에 따른 수당을 계산하시오.  
(TO_CHAR(hire_date, 'DY')로 입사 요일 추출 후 CASE 적용)

| 입사 요일 | 수당 |
|----------|------|
| MON | 500 |
| FRI | 300 |
| 기타 | 0 |

```
LAST_NAME  HIRE_DATE  HIRE_DAY ALLOWANCE
---------- ---------- -------- ---------
King       87/06/17   WED              0
Kochhar    89/09/21   THU              0
De Haan    93/01/13   WED              0
...
```

---

**[24번]** EMPLOYEES 테이블에서 NVL과 CASE를 조합하여, commission이 있는 사원은 실제 annual_salary, 없는 사원은 `'No Commission'` 문자열을 출력하시오.  
(NVL2와 TO_CHAR 활용)

```
LAST_NAME  COMMISSION_STATUS
---------- -------------------
King       No Commission
...
Russell    $235,200
...
```

---

**[25번]** EMPLOYEES 테이블에서 부서별 위치 분류를 DECODE로 출력하시오.

| 부서 번호 | 분류 |
|----------|------|
| 10 | '본사' |
| 20 | '마케팅' |
| 30 | '구매' |
| 60 | 'IT' |
| 80 | '영업' |
| 90 | '경영진' |
| 기타 | '기타부서' |

```
LAST_NAME  DEPARTMENT_ID DEPT_NAME
---------- ------------- ---------
King                  90 경영진
Kochhar               90 경영진
De Haan               90 경영진
...
Hunold                60 IT
...
```

---

## Group 5. 종합 응용 (26~30번)

---

**[26번]** EMPLOYEES 테이블에서 다음을 모두 포함하는 보고서를 출력하시오.

- full_name (first_name + ' ' + last_name)
- hire_date를 `'fmDD Month YYYY'` 형식으로
- salary를 `'$99,999'` 형식으로
- commission_pct를 NVL로 0 대체
- 부서 50, 80, 90만 조회
- hire_date 오름차순 정렬

```
FULL_NAME           HIRE_DATE_FMT          SALARY_FMT COMMISSION
------------------- ---------------------- ---------- ----------
Jennifer Whalen     17 September 1987      $4,400              0
...
```

---

**[27번]** EMPLOYEES 테이블에서 사원별 총 보상(total compensation)을 계산하시오.

- commission 있음: salary × 12 × (1 + commission_pct)
- commission 없음: salary × 12 + 1000 (고정 보너스)
- 총보상을 `'$999,999'` 형식으로 출력
- 총보상 내림차순 정렬

```
EMPLOYEE_ID LAST_NAME   TOTAL_COMP_FMT
----------- ----------- --------------
        100 King        $289,000
        ...
        145 Russell     $235,200
        ...
```

---

**[28번]** EMPLOYEES 테이블에서 급여 등급과 세율을 함께 출력하시오.

- 급여 등급 (Searched CASE): Low/Medium/High/Excellent
- 세율 (DECODE + TRUNC(salary/5000)):

| 몫 | 세율 |
|----|------|
| 0 | 5% |
| 1 | 10% |
| 2 | 15% |
| 기타 | 20% |

```
LAST_NAME  SALARY GRADE      TAX_RATE
---------- ------ ---------- --------
King        24000 Excellent  20%
Kochhar     17000 High       20%
...
Olson        2100 Low        5%
...
```

---

**[29번]** EMPLOYEES 테이블에서 다음 종합 보고서를 출력하시오.

- 출력 열: last_name, hire_date(fmDD Month YYYY), 근속 연수(현재연도 - 입사연도), 등급
- 등급 분류:
  - 30년 이상 → '30년+'
  - 20년 이상 → '20년+'
  - 10년 이상 → '10년+'
  - 10년 미만 → '신입'
- 정렬: 근속 연수 내림차순

```
LAST_NAME  HIRE_DATE_FMT          YEARS GRADE
---------- ---------------------- ----- -----
King       17 June 1987              39 30년+
Kochhar    21 September 1989         37 30년+
De Haan    13 January 1993           33 30년+
...
```

---

**[30번]** 다음 요구사항을 하나의 SQL 문으로 작성하시오.

요구사항:
- EMPLOYEES 테이블에서 2000년 이후 입사 사원 조회
- full_name (first_name + ' ' + last_name)
- hire_date를 `'fmDD Month YYYY'` 형식으로
- salary를 `'$99,999'` 형식으로
- 연봉(salary × 12 + salary × 12 × NVL(commission_pct, 0))을 `'$999,999'` 형식으로
- 급여 등급 (Searched CASE): Low/Medium/High/Excellent
- 입사 분기 (Q1/Q2/Q3/Q4)
- hire_date 오름차순 정렬

```
FULL_NAME         HIRE_DATE_FMT          SALARY_FMT ANNUAL_FMT GRADE   QUARTER
----------------- ---------------------- ---------- ---------- ------- -------
Kimberely Grant   24 May 2000            $7,000     $84,000    Medium  Q2
...
```
