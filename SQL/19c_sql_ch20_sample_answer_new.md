# Oracle Database 19c: SQL Workshop
## Chapter 20 — 다른 시간대의 데이터 관리 | SQL 실습 모범답안

---

## Group 1: 세션 시간대 설정 & 기본 함수

**[1번]**
```sql
SELECT DBTIMEZONE AS db_tz, SESSIONTIMEZONE AS session_tz FROM DUAL;
-- DB_TZ        SESSION_TZ
-- +00:00       +00:00  (기본값은 DB 시간대와 동일, 변경 전)
-- (DB 구성에 따라 다를 수 있음)
```

---

**[2번]**
```sql
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET TIME_ZONE = '-05:00';

SELECT SESSIONTIMEZONE, CURRENT_DATE, CURRENT_TIMESTAMP, LOCALTIMESTAMP FROM DUAL;
-- SESSION_TZ    CUR_DATE              CUR_TS                              LOCAL_TS
-- -05:00        2026-06-28 06:00:00   28-JUN-26 06.00.00.000000 -05:00   28-JUN-26 06.00.00.000000
```

**핵심 차이:**
| 함수 | 타입 | 시간대 포함 |
|------|------|------------|
| `CURRENT_DATE` | DATE | 없음 |
| `CURRENT_TIMESTAMP` | TIMESTAMP WITH TIME ZONE | **있음** (`-05:00`) |
| `LOCALTIMESTAMP` | TIMESTAMP | 없음 |

---

**[3번]**
```sql
ALTER SESSION SET TIME_ZONE = 'Asia/Seoul';

SELECT SESSIONTIMEZONE, CURRENT_DATE, CURRENT_TIMESTAMP, LOCALTIMESTAMP FROM DUAL;
-- SESSION_TZ      CUR_DATE              CUR_TS                                    LOCAL_TS
-- Asia/Seoul      2026-06-28 20:00:00   28-JUN-26 20.00.00.000000 ASIA/SEOUL      28-JUN-26 20.00.00.000000
-- CURRENT_TIMESTAMP에 'ASIA/SEOUL' 지역명이 표시됨
```

---

**[4번]**
```sql
SELECT TZ_OFFSET('US/Eastern')      AS us_east,
       TZ_OFFSET('Asia/Seoul')       AS seoul,
       TZ_OFFSET('Europe/London')    AS london,
       TZ_OFFSET('Australia/Sydney') AS sydney
FROM DUAL;
-- US_EAST   SEOUL   LONDON   SYDNEY
-- -05:00    +09:00  +00:00   +10:00
-- (DST 적용 시 US/Eastern: -04:00, London: +01:00, Sydney: +11:00)
```

---

**[5번]**
```sql
ALTER SESSION SET TIME_ZONE = dbtimezone;

SELECT DBTIMEZONE, SESSIONTIMEZONE FROM DUAL;
-- DBTIMEZONE   SESSIONTIMEZONE
-- +00:00       +00:00   ← 동일한 값
```

---

## Group 2: TIMESTAMP 데이터 타입

**[6번]**
```sql
ALTER SESSION SET TIME_ZONE = 'Asia/Seoul';

INSERT INTO web_orders VALUES (1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, LOCALTIMESTAMP);
COMMIT;

SELECT order_date, delivery_time, created_ts FROM web_orders WHERE order_id = 1;
-- ORDER_DATE                              DELIVERY_TIME                   CREATED_TS
-- 28-JUN-26 08.00.00.000 ASIA/SEOUL       28-JUN-26 08.00.00.000 +09:00   28-JUN-26 08.00.00.000000000
-- (order_date: 지역명 표시, delivery_time: 오프셋 표시, created_ts: TZ 없음)
```

---

**[7번]**
```sql
ALTER SESSION SET TIME_ZONE = 'US/Eastern';

SELECT order_date, delivery_time, created_ts FROM web_orders WHERE order_id = 1;
-- ORDER_DATE                              DELIVERY_TIME                   CREATED_TS
-- 28-JUN-26 08.00.00.000 ASIA/SEOUL       27-JUN-26 18.00.00.000 -05:00   28-JUN-26 08.00.00.000
-- delivery_time: 뉴욕 시간(-05:00)으로 자동 변환됨 (14시간 차)
-- order_date: 저장된 서울 시간대 그대로 표시됨
-- created_ts: 변화 없음 (TZ 정보 없어 변환 불가)
```

**핵심:** `WITH LOCAL TIME ZONE`은 세션 TZ로 자동 변환, `WITH TIME ZONE`은 저장된 TZ 그대로.

---

**[8번]**
```sql
SELECT FROM_TZ(TIMESTAMP '2024-06-28 09:00:00', 'Asia/Seoul')   AS seoul_time,
       FROM_TZ(TIMESTAMP '2024-06-28 00:00:00', 'UTC')           AS utc_time,
       FROM_TZ(TIMESTAMP '2024-06-27 20:00:00', 'US/Eastern')    AS eastern_time
FROM DUAL;
-- SEOUL_TIME                             UTC_TIME                       EASTERN_TIME
-- 28-JUN-24 09.00.00.0 ASIA/SEOUL        28-JUN-24 00.00.00.0 UTC        27-JUN-24 20.00.00.0 US/EASTERN
-- 세 값은 모두 UTC 기준 동일한 순간을 나타냄 (2024-06-28 00:00:00 UTC)
```

---

**[9번]**
```sql
SELECT TO_TIMESTAMP('2026-06-28 15:30:00', 'YYYY-MM-DD HH24:MI:SS') AS ts1,
       TO_TIMESTAMP('28-JUN-2026 03:30:00 PM', 'DD-MON-YYYY HH:MI:SS AM') AS ts2
FROM DUAL;
-- TS1                                TS2
-- 28-JUN-26 03.30.00.000000000 PM    28-JUN-26 03.30.00.000000000 PM
-- 두 결과 동일 (형식만 다른 동일 시각)
```

---

**[10번]**
```sql
SELECT employee_id, last_name, hire_date,
       CAST(hire_date AS TIMESTAMP) AS hire_timestamp
FROM employees WHERE department_id = 90;
-- EMPLOYEE_ID  LAST_NAME  HIRE_DATE            HIRE_TIMESTAMP
-- 100          King       17-JUN-03            17-JUN-03 12.00.00.000000000 AM
-- 101          Kochhar    21-SEP-05            21-SEP-05 12.00.00.000000000 AM
-- 102          De Haan    13-JAN-01            13-JAN-01 12.00.00.000000000 AM
-- DATE → TIMESTAMP 변환 시 소수점 초가 0으로 채워짐
```

---

## Group 3: INTERVAL 데이터 타입

**[11번]**
```sql
INSERT INTO warranty VALUES (101, 'Smartphone',   INTERVAL '2' YEAR);
INSERT INTO warranty VALUES (102, 'Refrigerator', INTERVAL '5' YEAR);
INSERT INTO warranty VALUES (103, 'Laptop',       INTERVAL '18' MONTH);
INSERT INTO warranty VALUES (104, 'TV',           INTERVAL '3-6' YEAR TO MONTH);
INSERT INTO warranty VALUES (105, 'Car',          '10-0');
COMMIT;

SELECT prod_id, prod_name, warranty_time FROM warranty ORDER BY prod_id;
-- PROD_ID  PROD_NAME     WARRANTY_TIME
-- 101      Smartphone    +002-00  (2년 0개월)
-- 102      Refrigerator  +005-00  (5년 0개월)
-- 103      Laptop        +001-06  (1년 6개월 = 18개월)
-- 104      TV            +003-06  (3년 6개월)
-- 105      Car           +010-00  (10년 0개월)
```

**포인트:** `INTERVAL '18' MONTH`는 자동으로 1년 6개월(`+001-06`)로 정규화된다.

---

**[12번]**
```sql
INSERT INTO lab VALUES (1, 'Stability Test',  INTERVAL '90 00:00:00' DAY(3) TO SECOND);
INSERT INTO lab VALUES (2, 'Speed Test',      INTERVAL '6 03:30:16' DAY TO SECOND);
INSERT INTO lab VALUES (3, 'Endurance Test',  '45 12:00:00');
INSERT INTO lab VALUES (4, 'Quick Test',      INTERVAL '0 00:30:00' DAY TO SECOND);
COMMIT;

SELECT exp_id, exp_name, test_time FROM lab ORDER BY exp_id;
-- EXP_ID  EXP_NAME         TEST_TIME
-- 1       Stability Test   +090 00:00:00.000000  (90일)
-- 2       Speed Test       +006 03:30:16.000000  (6일 3시간 30분 16초)
-- 3       Endurance Test   +045 12:00:00.000000  (45일 12시간)
-- 4       Quick Test       +000 00:30:00.000000  (30분)
```

---

**[13번]**
```sql
SELECT employee_id, last_name, hire_date,
       hire_date + TO_YMINTERVAL('01-06') AS probation_end
FROM   employees WHERE department_id = 20;
-- EMPLOYEE_ID  LAST_NAME  HIRE_DATE    PROBATION_END
-- 201          Fay        17-FEB-04    17-AUG-05    (1년 6개월 후)
-- 202          Whalen     17-SEP-03    17-MAR-05    (1년 6개월 후)
```

---

**[14번]**
```sql
SELECT last_name,
       TO_CHAR(hire_date, 'YYYY-MM-DD HH24:MI:SS') AS hire_date,
       TO_CHAR(hire_date + TO_DSINTERVAL('100 10:00:00'), 'YYYY-MM-DD HH24:MI:SS') AS target_date
FROM   employees
WHERE  department_id = 80
ORDER BY hire_date
FETCH FIRST 5 ROWS ONLY;
-- LAST_NAME  HIRE_DATE              TARGET_DATE
-- Sewall     2006-03-03 00:00:00    2006-06-11 10:00:00   (100일 10시간 후)
-- Taylor     2006-03-24 00:00:00    2006-07-02 10:00:00
-- ...
```

---

**[15번]**
```sql
SELECT prod_id, prod_name, warranty_time
FROM   warranty
WHERE  warranty_time >= INTERVAL '3' YEAR
ORDER BY warranty_time DESC;
-- PROD_ID  PROD_NAME     WARRANTY_TIME
-- 105      Car           +010-00
-- 104      TV            +003-06
-- 102      Refrigerator  +005-00
-- (101 Smartphone 2년, 103 Laptop 1년6개월 제외)
```

---

## Group 4: EXTRACT 함수

**[16번]**
```sql
SELECT employee_id, last_name, hire_date,
       EXTRACT(YEAR  FROM hire_date) AS hire_year,
       EXTRACT(MONTH FROM hire_date) AS hire_month,
       EXTRACT(DAY   FROM hire_date) AS hire_day
FROM   employees WHERE department_id = 90;
-- EMPLOYEE_ID  LAST_NAME  HIRE_DATE   HIRE_YEAR  HIRE_MONTH  HIRE_DAY
-- 100          King       17-JUN-03   2003        6           17
-- 101          Kochhar    21-SEP-05   2005        9           21
-- 102          De Haan    13-JAN-01   2001        1           13
```

---

**[17번]**
```sql
SELECT EXTRACT(YEAR FROM hire_date) AS year,
       COUNT(*) AS employee_count
FROM   employees
WHERE  EXTRACT(YEAR FROM hire_date) >= 2005
GROUP BY EXTRACT(YEAR FROM hire_date)
ORDER BY year;
-- YEAR   EMPLOYEE_COUNT
-- 2005   15
-- 2006   17
-- 2007   6
-- 2008   7
```

---

**[18번]**
```sql
SELECT employee_id, last_name, hire_date,
       CEIL(EXTRACT(MONTH FROM hire_date) / 3) AS hire_quarter
FROM   employees
ORDER BY hire_quarter, hire_date;
-- 1분기(1-3월): CEIL(1/3)~CEIL(3/3) = 1
-- 2분기(4-6월): CEIL(4/3)~CEIL(6/3) = 2
-- 3분기(7-9월): CEIL(7/3)~CEIL(9/3) = 3
-- 4분기(10-12월): CEIL(10/3)~CEIL(12/3) = 4
```

---

**[19번]**
```sql
SELECT employee_id, last_name, hire_date,
       EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM hire_date) AS approx_years
FROM   employees
WHERE  EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM hire_date) >= 10
ORDER BY hire_date;
-- (현재 연도 - 입사 연도 >= 10인 직원 목록)
-- 대부분의 HR 직원 포함됨 (2003~2008년 입사, 현재 2026년 기준)
```

**주의:** 이 방법은 정확한 경과 연도가 아닌 연도 수 차이임. 정밀도가 필요하면 `MONTHS_BETWEEN / 12` 사용 권장.

---

**[20번]**
```sql
SELECT EXTRACT(MONTH FROM hire_date) AS month,
       COUNT(*) AS employee_count
FROM   employees
GROUP BY EXTRACT(MONTH FROM hire_date)
ORDER BY employee_count DESC;
-- MONTH  EMPLOYEE_COUNT
-- 1      16   ← 가장 많이 입사한 월
-- 6      12
-- 5      10
-- ...
```

---

## Group 5: TZ_OFFSET & FROM_TZ

**[21번]**
```sql
SELECT 'US/Eastern'       AS region, TZ_OFFSET('US/Eastern')      AS offset FROM DUAL UNION ALL
SELECT 'US/Pacific',                  TZ_OFFSET('US/Pacific')                 FROM DUAL UNION ALL
SELECT 'Europe/London',               TZ_OFFSET('Europe/London')              FROM DUAL UNION ALL
SELECT 'Europe/Paris',                TZ_OFFSET('Europe/Paris')               FROM DUAL UNION ALL
SELECT 'Asia/Seoul',                  TZ_OFFSET('Asia/Seoul')                 FROM DUAL UNION ALL
SELECT 'Asia/Tokyo',                  TZ_OFFSET('Asia/Tokyo')                 FROM DUAL UNION ALL
SELECT 'Australia/Sydney',            TZ_OFFSET('Australia/Sydney')           FROM DUAL
ORDER BY offset;
-- REGION            OFFSET
-- US/Pacific        -08:00 (또는 DST 시 -07:00)
-- US/Eastern        -05:00 (또는 DST 시 -04:00)
-- Europe/London     +00:00 (또는 DST 시 +01:00)
-- Europe/Paris      +01:00 (또는 DST 시 +02:00)
-- Asia/Seoul        +09:00
-- Asia/Tokyo        +09:00
-- Australia/Sydney  +10:00 (또는 DST 시 +11:00)
```

---

**[22번]**
```sql
SELECT FROM_TZ(TIMESTAMP '2026-06-28 09:00:00', 'Asia/Seoul')   AS seoul_tz,
       FROM_TZ(TIMESTAMP '2026-06-28 01:00:00', 'Europe/Paris')  AS paris_tz,
       FROM_TZ(TIMESTAMP '2026-06-27 20:00:00', 'US/Eastern')    AS eastern_tz
FROM DUAL;
-- 세 값은 모두 UTC 2026-06-28 00:00:00과 동일한 순간을 나타냄
-- 서울 09:00 (UTC+9) = 파리 01:00 (UTC+1) = 미동부 전날 20:00 (UTC-4, DST 적용 시)
```

---

**[23번]**
```sql
WITH event AS (
    SELECT FROM_TZ(TIMESTAMP '2026-07-01 14:00:00', 'Asia/Seoul') AS event_time
    FROM DUAL
)
SELECT event_time AS seoul_time,
       event_time AT TIME ZONE 'US/Eastern'   AS new_york_time,
       event_time AT TIME ZONE 'Europe/London' AS london_time
FROM event;
-- SEOUL_TIME                    NEW_YORK_TIME                  LONDON_TIME
-- 01-JUL-26 14.00 ASIA/SEOUL    01-JUL-26 01.00 US/EASTERN     01-JUL-26 06.00 EUROPE/LONDON
-- AT TIME ZONE 연산자로 시간대 변환 수행
```

---

## Group 6: TO_TIMESTAMP & 변환 함수

**[24번]**
```sql
SELECT TO_TIMESTAMP('2026-06-28 15:30:45.123', 'YYYY-MM-DD HH24:MI:SS.FF3') AS ts1,
       TO_TIMESTAMP('28-JUN-2026', 'DD-MON-YYYY') AS ts2,
       TO_TIMESTAMP('06/28/2026 3:30 PM', 'MM/DD/YYYY HH:MI AM') AS ts3
FROM DUAL;
-- TS1: 28-JUN-26 03.30.45.123000000 PM
-- TS2: 28-JUN-26 12.00.00.000000000 AM
-- TS3: 28-JUN-26 03.30.00.000000000 PM
```

**FF3**: 소수점 이하 3자리 (밀리초)

---

**[25번]**
```sql
SELECT employee_id, last_name,
       TO_CHAR(
           TO_TIMESTAMP(TO_CHAR(hire_date, 'YYYY-MM-DD'), 'YYYY-MM-DD')
           + TO_DSINTERVAL('180 00:00:00'),
           'YYYY-MM-DD'
       ) AS day180_after
FROM   employees WHERE department_id = 90;
-- EMPLOYEE_ID  LAST_NAME  DAY180_AFTER
-- 100          King       2003-12-14   (2003-06-17 + 180일)
-- 101          Kochhar    2006-03-19   (2005-09-21 + 180일)
-- 102          De Haan    2001-07-11   (2001-01-13 + 180일)
```

---

## Group 7: 종합 실습

**[26번]**
```sql
ALTER SESSION SET TIME_ZONE = 'Asia/Seoul';

CREATE TABLE global_orders (
    order_id      NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100),
    order_time    TIMESTAMP WITH TIME ZONE,
    delivery_est  TIMESTAMP WITH LOCAL TIME ZONE
);

INSERT INTO global_orders VALUES (
    1001, 'Kim Seoul',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + TO_DSINTERVAL('2 00:00:00')
);
INSERT INTO global_orders VALUES (
    1002, 'Park Busan',
    FROM_TZ(TIMESTAMP '2026-06-28 14:30:00', 'Asia/Seoul'),
    FROM_TZ(TIMESTAMP '2026-06-28 14:30:00', 'Asia/Seoul') + TO_DSINTERVAL('3 00:00:00')
);
COMMIT;

-- 서울 세션에서 조회
SELECT order_id, customer_name, order_time, delivery_est FROM global_orders;
-- ORDER_ID  CUSTOMER_NAME  ORDER_TIME                         DELIVERY_EST
-- 1001      Kim Seoul      28-JUN-26 15.00.00 ASIA/SEOUL      30-JUN-26 15.00.00 +09:00
-- 1002      Park Busan     28-JUN-26 14.30.00 ASIA/SEOUL      01-JUL-26 14.30.00 +09:00

-- 뉴욕 세션 전환
ALTER SESSION SET TIME_ZONE = 'US/Eastern';
SELECT order_id, customer_name, order_time, delivery_est FROM global_orders;
-- ORDER_ID  CUSTOMER_NAME  ORDER_TIME                         DELIVERY_EST
-- 1001      Kim Seoul      28-JUN-26 15.00.00 ASIA/SEOUL      30-JUN-26 01.00.00 -05:00  ← 자동 변환
-- 1002      Park Busan     28-JUN-26 14.30.00 ASIA/SEOUL      01-JUL-26 00.30.00 -05:00  ← 자동 변환
```

**핵심 관찰:**
| 컬럼 | 타입 | 서울 세션 | 뉴욕 세션 |
|------|------|-----------|-----------|
| `order_time` | WITH TIME ZONE | 저장된 ASIA/SEOUL 시간 표시 | 동일하게 ASIA/SEOUL 표시 |
| `delivery_est` | WITH LOCAL TIME ZONE | +09:00 기준 표시 | **-05:00 기준으로 자동 변환** |

`TIMESTAMP WITH LOCAL TIME ZONE`의 핵심: 세션마다 자동 시간대 변환으로 글로벌 사용자에게 현지 시각 제공.

```sql
DROP TABLE global_orders;
```
