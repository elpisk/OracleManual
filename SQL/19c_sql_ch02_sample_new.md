# Oracle Database 19c: SQL Workshop
## Chapter 2 — SQL 실습 문제 (sql_sample 참고형)

> **사용 환경:** Oracle Database 19c  
> **사용 스키마:** HR (Human Resources) + 실습용 테이블  
> **작성 방식:** 주어진 출력 결과를 보고 SQL 문을 직접 작성하시오.

---

## Section A. HR 기본 조회 (1~8번)

> EMPLOYEES, DEPARTMENTS, JOBS 테이블을 사용한 기본 SELECT 실습

---

**[1번]** EMPLOYEES 테이블에서 사원의 사번, 성(last_name), 직무코드(job_id)를 조회하시오.

```
EMPLOYEE_ID  LAST_NAME            JOB_ID
------------ -------------------- ----------
100          King                 AD_PRES
101          Kochhar              AD_VP
102          De Haan              AD_VP
103          Hunold               IT_PROG
...
(107개 행)
```

---

**[2번]** EMPLOYEES 테이블에서 중복 없이 고유한 직무코드(job_id) 목록을 조회하시오.

```
JOB_ID
----------
AC_ACCOUNT
AC_MGR
AD_ASST
AD_PRES
AD_VP
FI_ACCOUNT
FI_MGR
HR_REP
IT_PROG
MK_MAN
MK_REP
PR_REP
PU_CLERK
PU_MAN
SA_MAN
SA_REP
SH_CLERK
ST_CLERK
ST_MAN
(19개 행)
```

---

**[3번]** EMPLOYEES 테이블에서 성(last_name), 월급(salary), 연봉(salary * 12)을 조회하시오.  
열 별칭은 각각 `성명`, `월급`, `연봉`으로 지정하시오.

```
성명                 월급       연봉
-------------------- ---------- ----------
King                 24000      288000
Kochhar              17000      204000
De Haan              17000      204000
Hunold               9000       108000
...
```

---

**[4번]** EMPLOYEES 테이블에서 `first_name`과 `last_name`을 공백으로 연결하여 `사원명`,  
`job_id`를 `직무`, `salary`를 `기본급`으로 조회하시오.

```
사원명                    직무       기본급
------------------------- ---------- ----------
Steven King               AD_PRES    24000
Neena Kochhar             AD_VP      17000
Lex De Haan               AD_VP      17000
Alexander Hunold          IT_PROG    9000
...
```

---

**[5번]** EMPLOYEES 테이블에서 성(last_name)과 직무(job_id)를 아래 형식으로 연결하여 출력하시오.  
열 별칭은 `사원 정보`로 지정하시오.

```
사원 정보
------------------------------
King 은(는) AD_PRES 직무입니다.
Kochhar 은(는) AD_VP 직무입니다.
De Haan 은(는) AD_VP 직무입니다.
...
```

---

**[6번]** DEPARTMENTS 테이블에서 부서명(department_name)과 매니저ID(manager_id)를 아래 형식으로 출력하시오.  
대체 따옴표 연산자(`q''`)를 사용하시오.

```
부서 및 매니저 정보
---------------------------------------
Administration Department's Manager: 200
Marketing Department's Manager: 201
Purchasing Department's Manager: 114
...
```

---

**[7번]** JOBS 테이블에서 직무코드(job_id), 직무명(job_title), 최저급여(min_salary), 최고급여(max_salary),  
급여범위(max_salary - min_salary)를 조회하시오. 급여범위의 열 별칭은 `급여범위`로 지정하시오.

```
JOB_ID     직무명                         MIN_SALARY MAX_SALARY    급여범위
---------- ------------------------------ ---------- ---------- ----------
AC_ACCOUNT Accountant                          4200       9000       4800
AC_MGR     Accounting Manager                  8200      16000       7800
AD_ASST    Administration Assistant            3000       6000       3000
AD_PRES    President                          20080      40000      19920
...
```

---

**[8번]** `dual` 테이블을 사용하여 다음 정보를 한 번에 조회하시오:  
① 현재 날짜(SYSDATE), ② `'Oracle 19c SQL Workshop'` 문자열, ③ `100 * 365` 계산 결과

```
오늘날짜   강의명                    계산결과
---------- ------------------------- ----------
26/06/27   Oracle 19c SQL Workshop       36500
```

---

## Section B. 판매 데이터 분석 (9~18번)

> 아래 테이블을 먼저 생성한 후 각 문제의 SQL을 작성하시오.

**테이블 생성 스크립트:**

```sql
-- 기존 테이블이 있으면 삭제
DROP TABLE kr_sales PURGE;
DROP TABLE jp_sales PURGE;

-- 한국 판매 테이블
CREATE TABLE kr_sales (
    saledate DATE,
    qty      NUMBER(5)
);

-- 일본 판매 테이블
CREATE TABLE jp_sales (
    saledate DATE,
    qty      NUMBER(5)
);

-- 한국 판매 데이터 입력
INSERT INTO kr_sales VALUES (DATE '2024-01-01',  0);
INSERT INTO kr_sales VALUES (DATE '2024-01-02', 61);
INSERT INTO kr_sales VALUES (DATE '2024-01-04', 62);
INSERT INTO kr_sales VALUES (DATE '2024-01-06',  0);
INSERT INTO kr_sales VALUES (DATE '2024-01-07', 96);
INSERT INTO kr_sales VALUES (DATE '2024-01-10', 31);
INSERT INTO kr_sales VALUES (DATE '2024-01-12', 68);
INSERT INTO kr_sales VALUES (DATE '2024-01-13', 55);
INSERT INTO kr_sales VALUES (DATE '2024-01-15', 42);
INSERT INTO kr_sales VALUES (DATE '2024-01-17', 78);

-- 일본 판매 데이터 입력
INSERT INTO jp_sales VALUES (DATE '2024-01-01', 27);
INSERT INTO jp_sales VALUES (DATE '2024-01-02',  0);
INSERT INTO jp_sales VALUES (DATE '2024-01-04', 52);
INSERT INTO jp_sales VALUES (DATE '2024-01-06', 94);
INSERT INTO jp_sales VALUES (DATE '2024-01-07', 93);
INSERT INTO jp_sales VALUES (DATE '2024-01-10', 74);
INSERT INTO jp_sales VALUES (DATE '2024-01-12', 44);
INSERT INTO jp_sales VALUES (DATE '2024-01-14', 83);
INSERT INTO jp_sales VALUES (DATE '2024-01-15', 19);
INSERT INTO jp_sales VALUES (DATE '2024-01-17', 36);

COMMIT;
```

---

**[9번]** kr_sales와 jp_sales 테이블을 날짜 기준으로 FULL OUTER JOIN하여  
날짜, 한국 판매량, 일본 판매량, 합계를 조회하시오.  
판매 기록이 없는 날은 0으로 표시하고, 날짜 오름차순으로 정렬하시오.

```
SALEDATE   한국       일본       합계
---------- ---------- ---------- ----------
24/01/01            0         27         27
24/01/02           61          0         61
24/01/04           62         52        114
24/01/06            0         94         94
24/01/07           96         93        189
24/01/10           31         74        105
24/01/12           68         44        112
24/01/13           55          0         55
24/01/14            0         83         83
24/01/15           42         19         61
24/01/17           78         36        114
(11개 행)
```

---

**[10번]** 9번 결과에 누적합계 열을 추가하시오.  
(힌트: `SUM(합계컬럼) OVER (ORDER BY 날짜)`)

```
SALEDATE   한국       일본       합계       누적합계
---------- ---------- ---------- ---------- ----------
24/01/01            0         27         27         27
24/01/02           61          0         61         88
24/01/04           62         52        114        202
24/01/06            0         94         94        296
24/01/07           96         93        189        485
24/01/10           31         74        105        590
24/01/12           68         44        112        702
24/01/13           55          0         55        757
24/01/14            0         83         83        840
24/01/15           42         19         61        901
24/01/17           78         36        114       1015
```

---

**[11번]** 10번 결과에 전일대비 열을 추가하시오. 첫 번째 날은 전일 데이터가 없으므로 NULL(공백)으로 표시한다.  
(힌트: `LAG(합계컬럼) OVER (ORDER BY 날짜)`)

```
SALEDATE   한국       일본       합계       전일대비
---------- ---------- ---------- ---------- ----------
24/01/01            0         27         27
24/01/02           61          0         61         34
24/01/04           62         52        114         53
24/01/06            0         94         94        -20
24/01/07           96         93        189         95
24/01/10           31         74        105        -84
24/01/12           68         44        112          7
24/01/13           55          0         55        -57
24/01/14            0         83         83         28
24/01/15           42         19         61        -22
24/01/17           78         36        114         53
```

---

**[12번]** 11번 결과에 전일대비 값에 따른 추세 열을 추가하시오.  
- 전일대비 양수: `상승`  
- 전일대비 0: `보합`  
- 전일대비 음수: `하락`  
- 첫 번째 날(NULL): `(없음)`  
(힌트: `CASE WHEN ... THEN ... END`)

```
SALEDATE   한국       일본       합계       전일대비   추세
---------- ---------- ---------- ---------- ---------- ------
24/01/01            0         27         27            (없음)
24/01/02           61          0         61         34 상승
24/01/04           62         52        114         53 상승
24/01/06            0         94         94        -20 하락
24/01/07           96         93        189         95 상승
24/01/10           31         74        105        -84 하락
24/01/12           68         44        112          7 상승
24/01/13           55          0         55        -57 하락
24/01/14            0         83         83         28 상승
24/01/15           42         19         61        -22 하락
24/01/17           78         36        114         53 상승
```

---

**[13번]** kr_sales와 jp_sales 각각에서 총 판매량 합계와 일 평균 판매량을 구하는 SQL을 작성하시오.

```
구분       총판매량   일수    일평균판매량
---------- ---------- ------- ------------
한국            493       10        49.3
일본            528       10        52.8
```

---

**[14번]** 한국 판매량이 일본 판매량보다 많은 날만 조회하시오.

```
SALEDATE   한국       일본       차이
---------- ---------- ---------- ----------
24/01/02           61          0         61
24/01/04           62         52         10
24/01/07           96         93          3
24/01/12           68         44         24
24/01/13           55          0         55
24/01/15           42         19         23
24/01/17           78         36         42
```

---

**[15번]** 한국과 일본 모두 판매가 있는 날(양쪽 테이블에 해당 날짜 존재)만 조회하고,  
합계를 내림차순으로 정렬하시오.

```
SALEDATE   한국       일본       합계
---------- ---------- ---------- ----------
24/01/07           96         93        189
24/01/04           62         52        114
24/01/17           78         36        114
24/01/10           31         74        105
24/01/12           68         44        112
24/01/06            0         94         94
24/01/15           42         19         61
24/01/01            0         27         27
```

---

**[16번]** 날짜별로 한국과 일본 판매량을 하나의 열에 행으로 표현하는 UNION 쿼리를 작성하시오.

```
SALEDATE   국가   QTY
---------- ------ ----------
24/01/01   한국            0
24/01/01   일본           27
24/01/02   한국           61
24/01/02   일본            0
...
(20개 행)
```

---

**[17번]** 월별 한국과 일본의 총 판매량 합계를 구하시오.  
(현재 데이터는 2024년 1월만 있으므로 1월 합계가 출력됨)

```
연월     한국_합계  일본_합계  전체합계
-------- ---------- ---------- ----------
2024-01        493        528       1021
```

---

**[18번]** 한국 또는 일본 중 어느 한쪽에만 판매 기록이 있는 날을 조회하시오.

```
SALEDATE   한국       일본
---------- ---------- ----------
24/01/13           55          0
24/01/14            0         83
```

---

## Section C. 조직 계층 조회 (19~26번)

> 아래 테이블을 먼저 생성한 후 각 문제의 SQL을 작성하시오.

**테이블 생성 스크립트:**

```sql
-- 기존 테이블이 있으면 삭제
DROP TABLE service PURGE;

-- 서비스 테이블 생성 (관리자, 부관리자 포함)
CREATE TABLE service (
    no      NUMBER(3),
    name    VARCHAR2(20),
    manager NUMBER(6),
    submgr  NUMBER(6)
);

INSERT INTO service VALUES (1, '시스템1', 100, 121);
INSERT INTO service VALUES (2, '시스템2', 101, 133);
INSERT INTO service VALUES (3, '시스템3', 106, NULL);
INSERT INTO service VALUES (4, '시스템4', 108, 138);
INSERT INTO service VALUES (5, '시스템5', 102, 140);
INSERT INTO service VALUES (6, '시스템6', 105, 141);
INSERT INTO service VALUES (7, '시스템7', 109, NULL);
INSERT INTO service VALUES (8, '시스템8', 110, 125);
INSERT INTO service VALUES (9, '시스템9', 111, 128);
INSERT INTO service VALUES (10, '시스템10', 115, NULL);

COMMIT;
```

---

**[19번]** service 테이블의 모든 데이터를 조회하시오.

```
NO     NAME       MANAGER SUBMGR
------ ---------- ------- ------
     1 시스템1        100    121
     2 시스템2        101    133
     3 시스템3        106
     4 시스템4        108    138
     5 시스템5        102    140
     6 시스템6        105    141
     7 시스템7        109
     8 시스템8        110    125
     9 시스템9        111    128
    10 시스템10       115
```

---

**[20번]** service 테이블과 EMPLOYEES 테이블을 조인하여 서비스번호, 서비스명, 관리자번호, 관리자 이름(first_name)을 조회하시오.

```
NO     NAME       관리자번호  관리자이름
------ ---------- ---------- --------------------
     1 시스템1         100   Steven
     2 시스템2         101   Neena
     3 시스템3         106   Valli
     4 시스템4         108   Nancy
     5 시스템5         102   Lex
     6 시스템6         105   David
     7 시스템7         109   Daniel
     8 시스템8         110   John
     9 시스템9         111   Ismael
    10 시스템10        115   Alexander
```

---

**[21번]** 20번에서 부관리자번호와 부관리자 이름(first_name)을 추가하시오.  
부관리자가 없는 경우(NULL)도 포함하여 출력하시오.

```
NO     NAME       관리자번호  관리자이름       부관리자번호  부관리자이름
------ ---------- ---------- ---------------- ------------ ----------------
     1 시스템1         100   Steven                  121   Adam
     2 시스템2         101   Neena                   133   Jason
     3 시스템3         106   Valli
     4 시스템4         108   Nancy                   138   Stephen
     5 시스템5         102   Lex                     140   Joshua
     6 시스템6         105   David                   141   Trenna
     7 시스템7         109   Daniel
     8 시스템8         110   John                    125   Julia
     9 시스템9         111   Ismael                  128   Steven
    10 시스템10        115   Alexander
```

---

**[22번]** 아래 스크립트를 실행하여 새로운 서비스를 추가한 후, 21번 결과를 다시 조회하시오.

```sql
INSERT INTO service VALUES (11, '시스템11', 121, 122);
COMMIT;
```

11번 시스템의 관리자(121 = Adam)와 부관리자(122 = Payam) 정보가 함께 출력되어야 한다.

```
NO     NAME       관리자번호  관리자이름       부관리자번호  부관리자이름
------ ---------- ---------- ---------------- ------------ ----------------
     1 시스템1         100   Steven                  121   Adam
     2 시스템2         101   Neena                   133   Jason
     3 시스템3         106   Valli
     4 시스템4         108   Nancy                   138   Stephen
     5 시스템5         102   Lex                     140   Joshua
     6 시스템6         105   David                   141   Trenna
     7 시스템7         109   Daniel
     8 시스템8         110   John                    125   Julia
     9 시스템9         111   Ismael                  128   Steven
    10 시스템10        115   Alexander
    11 시스템11        121   Adam                    122   Payam
```

---

**[23번]** service 테이블에서 부관리자가 없는(NULL) 서비스 목록만 조회하시오.

```
NO     NAME       관리자번호  관리자이름
------ ---------- ---------- --------------------
     3 시스템3         106   Valli
     7 시스템7         109   Daniel
    10 시스템10        115   Alexander
```

---

**[24번]** EMPLOYEES 테이블에서 관리자(manager_id)와 사원(employee_id)의 이름을 함께 조회하는 셀프 조인(Self Join) SQL을 작성하시오.  
관리자가 없는 사원(Steven King, manager_id=NULL)도 포함하시오.

```
사원번호  사원이름         관리자번호  관리자이름
-------- ---------------- ---------- ----------------
     100 Steven King                 (없음)
     101 Neena Kochhar          100  Steven King
     102 Lex De Haan            100  Steven King
     103 Alexander Hunold       102  Lex De Haan
     104 Bruce Ernst            103  Alexander Hunold
...
```

---

**[25번]** service 테이블에서 관리자와 부관리자가 **같은 부서**에 소속된 서비스만 조회하시오.  
(EMPLOYEES.department_id를 기준으로 비교)

```
NO     NAME       관리자이름       관리자부서  부관리자이름     부관리자부서
------ ---------- ---------------- ---------- ---------------- ----------
...
```

---

**[26번]** service 테이블에서 관리자의 상위 관리자(manager_id의 manager_id)까지 3단계 계층 정보를 출력하시오.

```sql
-- service 테이블 재생성 (3단계 계층 지원)
DROP TABLE service PURGE;
CREATE TABLE service (
    no       NUMBER(3),
    name     VARCHAR2(20),
    manager  NUMBER(6),
    submgr1  NUMBER(6),
    submgr2  NUMBER(6)
);

INSERT INTO service VALUES (1, '시스템1', 100, 121, 151);
INSERT INTO service VALUES (2, '시스템2', 101, 133, 152);
INSERT INTO service VALUES (3, '시스템3', 106, NULL, NULL);
INSERT INTO service VALUES (4, '시스템4', 108, 138, NULL);
INSERT INTO service VALUES (5, '시스템5', 102, 140, 153);
COMMIT;
```

```
NO     NAME       관리자번호  관리자이름  부관리자1번호  부관리자1이름  부관리자2번호  부관리자2이름
------ ---------- ---------- ----------- ------------- -------------- ------------- --------------
     1 시스템1        100    Steven            121     Adam                151     David
     2 시스템2        101    Neena             133     Jason               152     Peter
     3 시스템3        106    Valli
     4 시스템4        108    Nancy             138     Stephen
     5 시스템5        102    Lex               140     Joshua              153     Christopher
```

---

## Section D. HR 종합 분석 (27~30번)

---

**[27번]** EMPLOYEES 테이블에서 부서별 사원 수를 집계하시오.  
부서가 없는 사원(department_id = NULL)도 포함하고, 부서 ID 오름차순으로 정렬하시오.

```
DEPARTMENT_ID  사원수
-------------- ------
            10      1
            20      2
            30      6
            40      1
            50     45
            60      5
            70      1
            80     34
            90      3
           100      6
           110      2
    (NULL)          1
(12개 행)
```

---

**[28번]** EMPLOYEES와 DEPARTMENTS를 조인하여 부서명, 사원 수, 평균급여를 조회하시오.  
평균급여는 소수 첫째 자리에서 반올림하시오.

```
부서명             사원수    평균급여
------------------ ------ ----------
Administration          1      4400
Marketing               2      9500
Purchasing              6      4150
Human Resources         1      6500
Shipping               45      3476
IT                      5      5760
Public Relations        1     10000
Sales                  34      8956
Executive               3     19333
Finance                 6      8600
Accounting              2     10154
```

---

**[29번]** JOB_HISTORY 테이블을 사용하여 두 번 이상 직무를 변경한 사원의  
사번, 이름, 직무 변경 횟수를 조회하시오.

```
EMPLOYEE_ID  사원명              직무변경횟수
------------ ------------------- ------------
         176 Jonathon Taylor                2
         200 Jennifer Whalen               2
         101 Neena Kochhar                 2
```

---

**[30번]** EMPLOYEES 테이블에서 같은 직무(job_id)에 종사하는 사원의 수가 3명 이상인  
직무코드, 직무명(JOBS 테이블 조인), 사원 수, 최저급여, 최고급여를 조회하시오.  
사원 수 내림차순으로 정렬하시오.

```
JOB_ID     직무명                            사원수  최저급여  최고급여
---------- --------------------------------- ------ -------- --------
SA_REP     Sales Representative                 30     6100    11500
ST_CLERK   Stock Clerk                          20     2100     3600
SH_CLERK   Shipping Clerk                       20     2500     4200
PU_CLERK   Purchasing Clerk                      5     2500     3100
IT_PROG    Programmer                            5     4200     9000
FI_ACCOUNT Accountant                           5     6900     9000
AC_ACCOUNT Accountant                           (확인 필요)
ST_MAN     Stock Manager                         5     5800     8200
SA_MAN     Sales Manager                         5    10000    14000
```
