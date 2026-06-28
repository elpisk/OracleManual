# Oracle Database 19c: SQL Workshop
## Chapter 20 — 다른 시간대의 데이터 관리 | 연습문제

> 총 50문제 (하 20문제 / 중 20문제 / 상 10문제)

---

## 하(기초) — 20문제

**[1번]** `CURRENT_DATE` 함수의 반환 데이터 타입은?

① TIMESTAMP  
② TIMESTAMP WITH TIME ZONE  
③ DATE  
④ VARCHAR2

---

**[2번]** `CURRENT_TIMESTAMP` 함수의 반환 데이터 타입은?

① DATE  
② TIMESTAMP  
③ TIMESTAMP WITH TIME ZONE  
④ TIMESTAMP WITH LOCAL TIME ZONE

---

**[3번]** `LOCALTIMESTAMP` 함수의 반환 데이터 타입은?

① DATE  
② TIMESTAMP  
③ TIMESTAMP WITH TIME ZONE  
④ NUMBER

---

**[4번]** 세션의 시간대를 미국 동부(UTC-5)로 설정하는 구문으로 올바른 것은?

① `SET TIME_ZONE = '-05:00'`  
② `ALTER SESSION SET TIME_ZONE = '-05:00'`  
③ `ALTER DATABASE SET TIME_ZONE = '-05:00'`  
④ `SET SESSION TIMEZONE = '-05:00'`

---

**[5번]** 데이터베이스 서버의 시간대를 조회하는 구문은?

① `SELECT DBTIMEZONE FROM DUAL`  
② `SELECT DBTIME FROM DUAL`  
③ `SELECT DB_TIME_ZONE FROM DUAL`  
④ `SELECT TIMEZONE FROM DUAL`

---

**[6번]** 현재 세션의 시간대를 조회하는 함수는?

① DBTIMEZONE  
② CURRENT_TIMEZONE  
③ SESSIONTIMEZONE  
④ LOCAL_TIMEZONE

---

**[7번]** `TIMESTAMP WITH TIME ZONE` 타입에 저장되는 추가 정보는?

① 밀리초 정밀도  
② 시간대 오프셋 (TIMEZONE_HOUR, TIMEZONE_MINUTE) 또는 지역명  
③ 로컬 운영체제 시간  
④ 데이터베이스 SCN

---

**[8번]** 다음 중 TIMESTAMP 타입 3종에 포함되지 않는 것은?

① TIMESTAMP  
② TIMESTAMP WITH TIME ZONE  
③ TIMESTAMP WITH LOCAL TIME ZONE  
④ TIMESTAMP WITH DATABASE TIME ZONE

---

**[9번]** INTERVAL 데이터 타입이 저장하는 값의 종류는?

① 특정 시점의 날짜  
② 두 날짜/시간 값의 차이(간격)  
③ 타임스탬프와 시간대 조합  
④ 세션 시간대 정보

---

**[10번]** `INTERVAL YEAR TO MONTH` 타입에 포함되는 필드는?

① YEAR, MONTH, DAY  
② YEAR, MONTH  
③ DAY, HOUR, MINUTE, SECOND  
④ YEAR, MONTH, HOUR

---

**[11번]** `INTERVAL DAY TO SECOND` 타입에 포함되는 필드는?

① YEAR, MONTH  
② DAY, MONTH  
③ DAY, HOUR, MINUTE, SECOND  
④ HOUR, MINUTE, SECOND

---

**[12번]** `EXTRACT` 함수의 사용 목적은?

① 문자열에서 특정 패턴을 추출한다  
② 날짜/타임스탬프에서 특정 컴포넌트를 추출한다  
③ 테이블에서 행을 추출한다  
④ NUMBER에서 정수부를 추출한다

---

**[13번]** `TZ_OFFSET('US/Eastern')`의 반환값은?

① `+00:00`  
② `-05:00`  
③ `-08:00`  
④ `+05:00`

---

**[14번]** `FROM_TZ` 함수가 수행하는 작업은?

① DATE를 TIMESTAMP로 변환한다  
② TIMESTAMP 값에 시간대 정보를 추가하여 TIMESTAMP WITH TIME ZONE으로 변환한다  
③ 특정 시간대의 오프셋을 반환한다  
④ TIMESTAMP WITH TIME ZONE을 DATE로 변환한다

---

**[15번]** `TO_TIMESTAMP` 함수가 수행하는 작업은?

① TIMESTAMP를 DATE로 변환한다  
② 문자열을 TIMESTAMP로 변환한다  
③ TIMESTAMP에 시간대를 추가한다  
④ NUMBER를 TIMESTAMP로 변환한다

---

**[16번]** `TO_YMINTERVAL('01-02')` 의미는?

① 1개월 2일  
② 1년 2개월  
③ 12개월  
④ 0년 12개월

---

**[17번]** `TO_DSINTERVAL('100 10:00:00')` 의미는?

① 100시간 10분  
② 100일 10시간  
③ 100분 10초  
④ 10일 100시간

---

**[18번]** 일광 절약 시간(DST) 시작 시 어떤 현상이 발생하는가?

① 시간이 한 시간 뒤로 이동한다  
② 시간이 한 시간 앞으로 이동하여 특정 시간대가 무효가 된다  
③ 시간대가 자동으로 UTC로 변경된다  
④ 데이터베이스가 자동 재시작된다

---

**[19번]** `CURRENT_DATE`와 `SYSDATE`의 차이점은?

① CURRENT_DATE는 DATE 타입이 아니다  
② CURRENT_DATE는 세션 시간대 기준이고, SYSDATE는 DB 서버 시간대 기준이다  
③ SYSDATE는 소수점 초를 포함한다  
④ 두 함수의 반환값은 항상 동일하다

---

**[20번]** `TIMESTAMP WITH LOCAL TIME ZONE`의 특징으로 올바른 것은?

① 시간대 오프셋을 함께 저장한다  
② 저장 시 DB 시간대로 정규화되고, 조회 시 세션 시간대로 변환되어 표시된다  
③ 시간대를 저장하지 않는다  
④ 소수점 초를 지원하지 않는다

---

## 중(응용) — 20문제

**[21번]** 다음 SQL의 실행 결과 데이터 타입은?

```sql
SELECT CURRENT_TIMESTAMP FROM DUAL;
```

① DATE  
② TIMESTAMP  
③ TIMESTAMP WITH TIME ZONE  
④ VARCHAR2

---

**[22번]** 세션 시간대가 `-05:00`으로 설정되었을 때, 다음 세 함수가 반환하는 값의 차이점은?

```sql
SELECT CURRENT_DATE, CURRENT_TIMESTAMP, LOCALTIMESTAMP FROM DUAL;
```

① 세 함수 모두 동일한 값을 반환한다  
② CURRENT_DATE는 시간대 없는 DATE, CURRENT_TIMESTAMP는 시간대 포함 TIMESTAMP, LOCALTIMESTAMP는 시간대 없는 TIMESTAMP를 반환한다  
③ LOCALTIMESTAMP만 세션 시간대를 반영한다  
④ CURRENT_DATE만 세션 시간대를 반영한다

---

**[23번]** 다음 SQL의 결과는?

```sql
ALTER SESSION SET TIME_ZONE = 'America/New_York';
SELECT SESSIONTIMEZONE FROM DUAL;
```

① `+00:00`  
② `America/New_York`  
③ `-05:00` 또는 `-04:00` (DST에 따라)  
④ `New_York`

---

**[24번]** 다음 중 올바른 INTERVAL YEAR TO MONTH 삽입 구문은?

① `INSERT INTO warranty VALUES (1, INTERVAL '2 YEAR')`  
② `INSERT INTO warranty VALUES (1, INTERVAL '2' YEAR)`  
③ `INSERT INTO warranty VALUES (1, 2 YEAR)`  
④ `INSERT INTO warranty VALUES (1, '2Y')`

---

**[25번]** 다음 SQL의 결과 행 수는? (2007년 이후 입사 직원이 6명이라 가정)

```sql
SELECT last_name, hire_date
FROM   employees
WHERE  EXTRACT(YEAR FROM hire_date) > 2007;
```

① 0  
② 6  
③ 107  
④ 오류 발생

---

**[26번]** `FROM_TZ(TIMESTAMP '2000-07-12 08:00:00', 'Australia/North')`의 결과 타입은?

① TIMESTAMP  
② DATE  
③ TIMESTAMP WITH TIME ZONE  
④ VARCHAR2

---

**[27번]** 다음 SQL 결과에서 hire_plus_14months는 무엇인가? (hire_date = 2005-01-01)

```sql
SELECT hire_date, hire_date + TO_YMINTERVAL('01-02') AS hire_plus_14months
FROM   employees WHERE employee_id = 100;
```

① 2005-01-01  
② 2005-03-01  
③ 2006-03-01  
④ 2006-01-01

---

**[28번]** `TO_DSINTERVAL('3 12:30:00')`의 의미는?

① 3시간 12분 30초  
② 3일 12시간 30분  
③ 3분 12초  
④ 12일 3시간

---

**[29번]** 다음 중 INTERVAL YEAR TO MONTH의 MONTH 필드에 저장 가능한 값의 범위는?

① 1 ~ 12  
② 0 ~ 11  
③ 00 ~ 59  
④ 0 ~ 12

---

**[30번]** 다음 SQL의 결과는?

```sql
SELECT TZ_OFFSET('Europe/London') FROM DUAL;
```

(일광 절약 시간이 적용되지 않을 때)

① `-05:00`  
② `+01:00`  
③ `+00:00`  
④ `-08:00`

---

**[31번]** `TIMESTAMP WITH LOCAL TIME ZONE`과 `TIMESTAMP WITH TIME ZONE`의 가장 큰 차이는?

① WITH LOCAL TIME ZONE은 소수점 초를 지원하지 않는다  
② WITH LOCAL TIME ZONE은 저장 시 DB 시간대로 정규화하고 조회 시 세션 시간대로 표시하며, WITH TIME ZONE은 입력한 시간대 정보를 그대로 저장한다  
③ WITH TIME ZONE은 지역명을 저장할 수 없다  
④ 두 타입은 동일하다

---

**[32번]** 다음 INTERVAL DAY TO SECOND 삽입 구문의 의미는?

```sql
INSERT INTO lab VALUES (100012, INTERVAL '6 03:30:16' DAY TO SECOND);
```

① 6시간 3분 30초 16밀리초  
② 6일 3시간 30분 16초  
③ 6월 3일 30분  
④ 6년 3개월

---

**[33번]** 다음 쿼리에서 EXTRACT 함수가 사용되는 올바른 컴포넌트는? (TIMESTAMP 컬럼에서)

① EXTRACT(DATE FROM ts_col)  
② EXTRACT(YEAR FROM ts_col)  
③ EXTRACT(CENTURY FROM ts_col)  
④ EXTRACT(WEEK FROM ts_col)

---

**[34번]** `ALTER SESSION SET TIME_ZONE = dbtimezone`의 효과는?

① 세션 시간대를 UTC(+00:00)로 설정한다  
② 세션 시간대를 데이터베이스 서버의 시간대와 동일하게 설정한다  
③ 데이터베이스 시간대를 현재 세션 시간대로 변경한다  
④ 오류가 발생한다

---

**[35번]** 일광 절약 시간 종료 시점에 발생하는 문제는?

① 특정 시간이 건너뛰어져 무효가 된다  
② 시계가 뒤로 이동하여 동일한 시간대가 두 번 나타나 중복이 발생한다  
③ 데이터베이스 연결이 끊어진다  
④ 타임스탬프 컬럼의 값이 자동 변경된다

---

**[36번]** 다음 중 `TO_TIMESTAMP` 함수의 올바른 사용 예는?

① `TO_TIMESTAMP(SYSDATE, 'YYYY-MM-DD')`  
② `TO_TIMESTAMP('2024-06-15 10:30:00', 'YYYY-MM-DD HH24:MI:SS')`  
③ `TO_TIMESTAMP(SYSTIMESTAMP)`  
④ `TO_TIMESTAMP('20240615')`

---

**[37번]** `INTERVAL '200' YEAR(3)`에서 숫자 3의 의미는?

① 정밀도 3: YEAR 필드가 최대 3자리 숫자를 가질 수 있음  
② 300을 의미한다  
③ MONTH가 최대 3개월임을 의미한다  
④ 아무 의미 없다

---

**[38번]** 다음 중 DBTIMEZONE과 SESSIONTIMEZONE이 다를 수 있는 이유는?

① Oracle은 항상 두 값을 동일하게 유지한다  
② `ALTER SESSION SET TIME_ZONE`으로 세션별 시간대를 독립적으로 설정할 수 있기 때문이다  
③ DBTIMEZONE은 변경할 수 없고 SESSIONTIMEZONE도 변경 불가하다  
④ SESSIONTIMEZONE은 항상 UTC이다

---

**[39번]** 다음 중 EXTRACT 함수에서 추출 가능한 컴포넌트가 아닌 것은?

① YEAR  
② MONTH  
③ DAY  
④ CENTURY

---

**[40번]** 전 세계 고객의 주문 시각을 정확하게 저장해야 할 때 가장 적합한 데이터 타입은?

① DATE  
② TIMESTAMP  
③ TIMESTAMP WITH TIME ZONE  
④ VARCHAR2

---

## 상(심화) — 10문제

**[41번]** 다음 쿼리의 실행 결과를 올바르게 설명한 것은? (세션 시간대 = '-05:00', DB 시간대 = '+00:00')

```sql
SELECT SYSDATE, CURRENT_DATE FROM DUAL;
```

① 두 값이 동일하다  
② SYSDATE는 DB 서버 시각(UTC), CURRENT_DATE는 세션 시각(-05:00 기준)으로 5시간 차이가 날 수 있다  
③ CURRENT_DATE는 항상 SYSDATE보다 크다  
④ 두 함수는 동일한 함수의 별칭이다

---

**[42번]** 다음 시나리오에서 가장 적절한 설계는?

```
요구사항: 전 세계 지사의 회의 예약 시스템
- 각 지사별 현지 시각 표시 필요
- DB에는 단일 표준 시각으로 저장 원칙
```

① `DATE` 타입 사용 (가장 단순)  
② `TIMESTAMP WITH LOCAL TIME ZONE` — DB에 정규화하여 저장, 각 세션에서 로컬 시각으로 자동 표시  
③ `VARCHAR2` 타입으로 문자열 저장  
④ `TIMESTAMP` — 시간대 정보 없이 저장

---

**[43번]** 다음 코드의 실행 후 WARRANTY 테이블에서 두 번째 행의 WARRANTY_TIME 값은?

```sql
CREATE TABLE warranty (
    prod_id       NUMBER,
    warranty_time INTERVAL YEAR(3) TO MONTH
);
INSERT INTO warranty VALUES (155, INTERVAL '200' YEAR(3));
SELECT warranty_time FROM warranty WHERE prod_id = 155;
```

① `+00-200`  
② `+200-00`  
③ `200`  
④ ORA 오류 발생

---

**[44번]** 다음 쿼리 실행 시 결과를 올바르게 설명한 것은?

```sql
ALTER SESSION SET TIME_ZONE = 'Asia/Seoul';     -- UTC+9

SELECT CURRENT_TIMESTAMP,
       LOCALTIMESTAMP,
       CURRENT_DATE
FROM DUAL;
```

① CURRENT_TIMESTAMP와 LOCALTIMESTAMP는 동일하다  
② CURRENT_TIMESTAMP는 '+09:00' 시간대 정보를 포함하고, LOCALTIMESTAMP는 시간대 없이 동일 시각을 표시한다. CURRENT_DATE는 DATE 타입으로 시각 정보만 날짜 형식으로 반환한다  
③ 세 값 모두 다른 시각을 나타낸다  
④ CURRENT_DATE는 UTC 기준이다

---

**[45번]** 다음 SQL의 오류 원인은?

```sql
INSERT INTO warranty VALUES (100, INTERVAL '500' YEAR);
-- WARRANTY_TIME: INTERVAL YEAR(3) TO MONTH
```

① MONTH를 지정하지 않았기 때문이다  
② 500은 YEAR(3) 정밀도(최대 999) 이내이므로 오류 없다  
③ INTERVAL 리터럴이 아닌 문자열을 사용해야 한다  
④ INTERVAL 타입이 아닌 DATE를 사용해야 한다

---

**[46번]** 다음 두 쿼리의 결과 차이점을 올바르게 설명한 것은?

```sql
-- 쿼리 A
SELECT hire_date + TO_YMINTERVAL('01-00') FROM employees WHERE employee_id = 100;
-- 쿼리 B
SELECT hire_date + TO_DSINTERVAL('365 00:00:00') FROM employees WHERE employee_id = 100;
```

① 항상 동일한 날짜를 반환한다  
② 쿼리 A는 정확히 1년 후(달력 기준)를 반환하고, 쿼리 B는 정확히 365일 후를 반환한다. 윤년에는 두 결과가 다를 수 있다  
③ 쿼리 B는 오류가 발생한다  
④ 쿼리 A가 항상 더 이른 날짜를 반환한다

---

**[47번]** 다음 중 `TIMESTAMP WITH TIME ZONE` 컬럼에 올바르게 데이터를 삽입하는 방법은?

```sql
CREATE TABLE tz_test (ts_col TIMESTAMP WITH TIME ZONE);
```

① `INSERT INTO tz_test VALUES (SYSDATE)`  
② `INSERT INTO tz_test VALUES (CURRENT_TIMESTAMP)`  
③ `INSERT INTO tz_test VALUES (LOCALTIMESTAMP)`  
④ `INSERT INTO tz_test VALUES (TO_DATE('2024-01-01', 'YYYY-MM-DD'))`

---

**[48번]** 서울(UTC+9)에서 입력한 `TIMESTAMP WITH LOCAL TIME ZONE` 데이터를 뉴욕(UTC-5)에서 조회하면?

① 입력 시 저장된 값 그대로 출력된다 (UTC+9 기준)  
② 뉴욕 세션의 시간대(-05:00)로 자동 변환되어 14시간 이른 시각이 출력된다  
③ 오류가 발생한다  
④ UTC 기준 시각이 출력된다

---

**[49번]** 다음 DST 시나리오에서 문제가 발생하는 경우를 설명한 것은?

```
미국 동부 (America/New_York) DST 시작일 (3월 둘째 일요일 02:00)
→ 01:59:59 직후 03:00:00으로 이동
```

```sql
SELECT FROM_TZ(TIMESTAMP '2024-03-10 02:30:00', 'America/New_York')
FROM DUAL;
```

① 정상적으로 '2024-03-10 02:30:00 America/New_York'이 반환된다  
② 02:00~02:59 구간은 DST 전환으로 존재하지 않으므로 오류 또는 예외 처리가 필요하다  
③ 자동으로 03:30:00으로 변환된다  
④ Oracle은 DST를 처리하지 못한다

---

**[50번]** 다음 쿼리에서 EXTRACT를 활용한 분기(QUARTER) 계산 방법으로 올바른 것은?

```sql
-- hire_date가 몇 분기에 해당하는지 계산
SELECT last_name,
       hire_date,
       [??? 분기 계산 ???] AS quarter
FROM   employees
WHERE  department_id = 90;
```

① `EXTRACT(QUARTER FROM hire_date)`  
② `CEIL(EXTRACT(MONTH FROM hire_date) / 3)`  
③ `TRUNC(EXTRACT(MONTH FROM hire_date) / 3)`  
④ `EXTRACT(MONTH FROM hire_date) MOD 3`
