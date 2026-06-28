# Oracle Database 19c: SQL Workshop
## Chapter 20 — 다른 시간대의 데이터 관리 | SQL 실습 문제

---

> **참고:** 이 실습은 HR 스키마가 설치된 Oracle 19c 환경에서 수행하세요.

---

## Group 1: 세션 시간대 설정 & 기본 함수

**[1번]** 현재 DB 시간대와 세션 시간대를 조회하시오.

```sql
SELECT DBTIMEZONE    AS db_tz,
       SESSIONTIMEZONE AS session_tz
FROM   DUAL;
```

---

**[2번]** 세션 시간대를 UTC-5로 설정한 후 CURRENT_DATE, CURRENT_TIMESTAMP, LOCALTIMESTAMP의 차이를 확인하시오.

```sql
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET TIME_ZONE = '-05:00';

SELECT SESSIONTIMEZONE           AS tz,
       CURRENT_DATE              AS cur_date,
       CURRENT_TIMESTAMP         AS cur_ts,
       LOCALTIMESTAMP            AS local_ts
FROM   DUAL;
-- CURRENT_TIMESTAMP에만 시간대 정보(-05:00)가 표시됨
```

---

**[3번]** 세션 시간대를 서울(Asia/Seoul)로 변경한 뒤 같은 쿼리를 실행하여 값의 차이를 확인하시오.

```sql
ALTER SESSION SET TIME_ZONE = 'Asia/Seoul';

SELECT SESSIONTIMEZONE,
       CURRENT_DATE,
       CURRENT_TIMESTAMP,
       LOCALTIMESTAMP
FROM   DUAL;
-- CURRENT_TIMESTAMP: '+09:00' 또는 'Asia/Seoul' 표시
```

---

**[4번]** 'US/Eastern', 'Asia/Seoul', 'Europe/London', 'Australia/Sydney' 시간대의 UTC 오프셋을 조회하시오.

```sql
SELECT TZ_OFFSET('US/Eastern')      AS us_east,
       TZ_OFFSET('Asia/Seoul')       AS seoul,
       TZ_OFFSET('Europe/London')    AS london,
       TZ_OFFSET('Australia/Sydney') AS sydney
FROM   DUAL;
```

---

**[5번]** 세션 시간대를 DB 시간대와 동일하게 설정하고 확인하시오.

```sql
ALTER SESSION SET TIME_ZONE = dbtimezone;

SELECT DBTIMEZONE,
       SESSIONTIMEZONE
FROM   DUAL;
-- 두 값이 동일해야 함
```

---

## Group 2: TIMESTAMP 데이터 타입

**[준비]**
```sql
CREATE TABLE web_orders (
    order_id      NUMBER,
    order_date    TIMESTAMP WITH TIME ZONE,
    delivery_time TIMESTAMP WITH LOCAL TIME ZONE,
    created_ts    TIMESTAMP
);
```

---

**[6번]** 다음 세 가지 타임스탬프 타입으로 데이터를 삽입하고 차이를 확인하시오.

```sql
ALTER SESSION SET TIME_ZONE = 'Asia/Seoul';

INSERT INTO web_orders VALUES (
    1,
    CURRENT_TIMESTAMP,           -- TIMESTAMP WITH TIME ZONE
    CURRENT_TIMESTAMP,           -- TIMESTAMP WITH LOCAL TIME ZONE
    LOCALTIMESTAMP               -- TIMESTAMP
);
COMMIT;

SELECT order_date,
       delivery_time,
       created_ts
FROM   web_orders
WHERE  order_id = 1;
-- order_date: 시간대 오프셋 포함
-- delivery_time: 세션 시간대로 표시 (같은 값이지만 TZ 오프셋 표시 방식 다름)
-- created_ts: 시간대 정보 없음
```

---

**[7번]** 세션 시간대를 미국 동부로 바꾼 후 같은 데이터를 다시 조회하여 차이를 확인하시오.

```sql
ALTER SESSION SET TIME_ZONE = 'US/Eastern';

SELECT order_date,
       delivery_time,   -- 세션 TZ로 자동 변환 표시
       created_ts
FROM   web_orders
WHERE  order_id = 1;
-- delivery_time: '-05:00' 기준 시각으로 변환되어 표시됨 (14시간 차이)
-- order_date: 저장된 원래 시간대 그대로 표시
-- created_ts: 변화 없음 (TZ 정보 없음)
```

---

**[8번]** FROM_TZ를 사용하여 TIMESTAMP를 TIMESTAMP WITH TIME ZONE으로 변환하시오.

```sql
SELECT FROM_TZ(TIMESTAMP '2024-06-28 09:00:00', 'Asia/Seoul')   AS seoul_time,
       FROM_TZ(TIMESTAMP '2024-06-28 00:00:00', 'UTC')           AS utc_time,
       FROM_TZ(TIMESTAMP '2024-06-27 20:00:00', 'US/Eastern')    AS eastern_time
FROM   DUAL;
-- 세 값은 모두 동일한 UTC 시각을 나타냄 (서울 09:00 = UTC 00:00 = 미동부 전날 20:00)
```

---

**[9번]** TO_TIMESTAMP를 사용하여 문자열을 TIMESTAMP로 변환하시오.

```sql
SELECT TO_TIMESTAMP('2026-06-28 15:30:00', 'YYYY-MM-DD HH24:MI:SS') AS ts1,
       TO_TIMESTAMP('28-JUN-2026 03:30:00 PM', 'DD-MON-YYYY HH:MI:SS AM') AS ts2
FROM   DUAL;
```

---

**[10번]** employees 테이블의 hire_date를 TIMESTAMP로 변환하여 소수점 초 형태로 출력하시오.

```sql
SELECT employee_id,
       last_name,
       hire_date,
       CAST(hire_date AS TIMESTAMP) AS hire_timestamp
FROM   employees
WHERE  department_id = 90;
```

---

## Group 3: INTERVAL 데이터 타입

**[준비]**
```sql
CREATE TABLE warranty (
    prod_id       NUMBER,
    prod_name     VARCHAR2(50),
    warranty_time INTERVAL YEAR(3) TO MONTH
);

CREATE TABLE lab (
    exp_id    NUMBER,
    exp_name  VARCHAR2(50),
    test_time INTERVAL DAY(3) TO SECOND
);
```

---

**[11번]** 다양한 형태의 INTERVAL YEAR TO MONTH 데이터를 삽입하시오.

```sql
INSERT INTO warranty VALUES (101, 'Smartphone',  INTERVAL '2' YEAR);
INSERT INTO warranty VALUES (102, 'Refrigerator', INTERVAL '5' YEAR);
INSERT INTO warranty VALUES (103, 'Laptop',       INTERVAL '18' MONTH);
INSERT INTO warranty VALUES (104, 'TV',           INTERVAL '3-6' YEAR TO MONTH);
INSERT INTO warranty VALUES (105, 'Car',          '10-0');
COMMIT;

SELECT prod_id, prod_name, warranty_time FROM warranty ORDER BY prod_id;
```

---

**[12번]** INTERVAL DAY TO SECOND 데이터를 삽입하시오.

```sql
INSERT INTO lab VALUES (1, 'Stability Test',  INTERVAL '90 00:00:00' DAY(3) TO SECOND);
INSERT INTO lab VALUES (2, 'Speed Test',      INTERVAL '6 03:30:16' DAY TO SECOND);
INSERT INTO lab VALUES (3, 'Endurance Test',  '45 12:00:00');
INSERT INTO lab VALUES (4, 'Quick Test',      INTERVAL '0 00:30:00' DAY TO SECOND);
COMMIT;

SELECT exp_id, exp_name, test_time FROM lab ORDER BY exp_id;
```

---

**[13번]** TO_YMINTERVAL을 사용하여 직원 입사일에 1년 6개월을 더한 날짜를 계산하시오.

```sql
SELECT employee_id,
       last_name,
       hire_date,
       hire_date + TO_YMINTERVAL('01-06') AS probation_end
FROM   employees
WHERE  department_id = 20;
-- 수습 기간 1년 6개월 후 날짜 계산
```

---

**[14번]** TO_DSINTERVAL을 사용하여 입사 후 100일 10시간이 지난 날짜를 계산하시오.

```sql
SELECT last_name,
       TO_CHAR(hire_date, 'YYYY-MM-DD HH24:MI:SS')                 AS hire_date,
       TO_CHAR(hire_date + TO_DSINTERVAL('100 10:00:00'),
               'YYYY-MM-DD HH24:MI:SS')                             AS target_date
FROM   employees
WHERE  department_id = 80
ORDER BY hire_date
FETCH FIRST 5 ROWS ONLY;
```

---

**[15번]** warranty 테이블에서 보증 기간이 3년 이상인 제품을 조회하시오.

```sql
SELECT prod_id, prod_name, warranty_time
FROM   warranty
WHERE  warranty_time >= INTERVAL '3' YEAR
ORDER BY warranty_time DESC;
```

---

## Group 4: EXTRACT 함수

**[16번]** EXTRACT로 직원 입사 연도, 월, 일을 각각 추출하여 조회하시오.

```sql
SELECT employee_id,
       last_name,
       hire_date,
       EXTRACT(YEAR  FROM hire_date) AS hire_year,
       EXTRACT(MONTH FROM hire_date) AS hire_month,
       EXTRACT(DAY   FROM hire_date) AS hire_day
FROM   employees
WHERE  department_id = 90;
```

---

**[17번]** 2005년 이후에 입사한 직원의 수를 입사 연도별로 집계하시오.

```sql
SELECT EXTRACT(YEAR FROM hire_date) AS year,
       COUNT(*) AS employee_count
FROM   employees
WHERE  EXTRACT(YEAR FROM hire_date) >= 2005
GROUP BY EXTRACT(YEAR FROM hire_date)
ORDER BY year;
```

---

**[18번]** 각 직원의 입사 분기(1~4분기)를 계산하여 출력하시오.

```sql
SELECT employee_id,
       last_name,
       hire_date,
       CEIL(EXTRACT(MONTH FROM hire_date) / 3) AS hire_quarter
FROM   employees
ORDER BY hire_quarter, hire_date;
```

---

**[19번]** 입사일로부터 현재까지 경과 연도를 계산하여 10년 이상 근속한 직원을 조회하시오.

```sql
SELECT employee_id,
       last_name,
       hire_date,
       EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM hire_date) AS approx_years
FROM   employees
WHERE  EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM hire_date) >= 10
ORDER BY hire_date;
```

---

**[20번]** 월별 입사 직원 수 분포를 조회하여 가장 많이 입사한 월을 확인하시오.

```sql
SELECT EXTRACT(MONTH FROM hire_date) AS month,
       COUNT(*) AS employee_count
FROM   employees
GROUP BY EXTRACT(MONTH FROM hire_date)
ORDER BY employee_count DESC;
```

---

## Group 5: TZ_OFFSET & FROM_TZ

**[21번]** 주요 도시들의 시간대 오프셋을 한눈에 조회하시오.

```sql
SELECT 'US/Eastern'      AS region, TZ_OFFSET('US/Eastern')      AS offset FROM DUAL UNION ALL
SELECT 'US/Pacific'      AS region, TZ_OFFSET('US/Pacific')       AS offset FROM DUAL UNION ALL
SELECT 'Europe/London'   AS region, TZ_OFFSET('Europe/London')    AS offset FROM DUAL UNION ALL
SELECT 'Europe/Paris'    AS region, TZ_OFFSET('Europe/Paris')     AS offset FROM DUAL UNION ALL
SELECT 'Asia/Seoul'      AS region, TZ_OFFSET('Asia/Seoul')       AS offset FROM DUAL UNION ALL
SELECT 'Asia/Tokyo'      AS region, TZ_OFFSET('Asia/Tokyo')       AS offset FROM DUAL UNION ALL
SELECT 'Australia/Sydney'AS region, TZ_OFFSET('Australia/Sydney') AS offset FROM DUAL
ORDER BY offset;
```

---

**[22번]** FROM_TZ를 사용하여 동일한 UTC 시각을 여러 시간대로 표현하시오.

```sql
-- UTC 2026-06-28 00:00:00 기준
SELECT FROM_TZ(TIMESTAMP '2026-06-28 09:00:00', 'Asia/Seoul')     AS seoul_tz,
       FROM_TZ(TIMESTAMP '2026-06-28 01:00:00', 'Europe/Paris')    AS paris_tz,
       FROM_TZ(TIMESTAMP '2026-06-27 20:00:00', 'US/Eastern')      AS eastern_tz
FROM   DUAL;
-- 세 값은 동일한 UTC 시각을 나타냄
```

---

**[23번]** CURRENT_TIMESTAMP를 FROM_TZ와 결합하여 특정 이벤트 시각을 여러 시간대로 변환하시오.

```sql
-- 서울 시간 기준 이벤트 시각: 2026-07-01 14:00:00
WITH event AS (
    SELECT FROM_TZ(TIMESTAMP '2026-07-01 14:00:00', 'Asia/Seoul') AS event_time
    FROM   DUAL
)
SELECT event_time AS seoul_time,
       event_time AT TIME ZONE 'US/Eastern' AS new_york_time,
       event_time AT TIME ZONE 'Europe/London' AS london_time
FROM   event;
```

---

## Group 6: TO_TIMESTAMP & 변환 함수

**[24번]** TO_TIMESTAMP로 다양한 형식의 날짜 문자열을 변환하시오.

```sql
SELECT TO_TIMESTAMP('2026-06-28 15:30:45.123',
                    'YYYY-MM-DD HH24:MI:SS.FF3') AS ts1,
       TO_TIMESTAMP('28-JUN-2026',
                    'DD-MON-YYYY') AS ts2,
       TO_TIMESTAMP('06/28/2026 3:30 PM',
                    'MM/DD/YYYY HH:MI AM') AS ts3
FROM   DUAL;
```

---

**[25번]** 문자열 형태로 저장된 날짜 데이터를 TIMESTAMP로 변환하여 INTERVAL 연산을 수행하시오.

```sql
-- 문자열 → TIMESTAMP → INTERVAL 연산
SELECT employee_id,
       last_name,
       TO_CHAR(
           TO_TIMESTAMP(TO_CHAR(hire_date, 'YYYY-MM-DD'), 'YYYY-MM-DD')
           + TO_DSINTERVAL('180 00:00:00'),
           'YYYY-MM-DD'
       ) AS day180_after
FROM   employees
WHERE  department_id = 90;
-- 입사 180일 후 날짜 계산
```

---

## Group 7: 종합 실습

**[26번]** 전자상거래 주문 시스템 시나리오를 시뮬레이션하시오. 서울 시간으로 주문 입력 후 뉴욕 시간으로 조회하시오.

```sql
-- 서울 세션으로 주문 입력
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
SELECT order_id, customer_name, order_time, delivery_est
FROM   global_orders;

-- 뉴욕 세션으로 전환 후 재조회
ALTER SESSION SET TIME_ZONE = 'US/Eastern';
SELECT order_id, customer_name, order_time, delivery_est
FROM   global_orders;
-- delivery_est(WITH LOCAL TIME ZONE)는 뉴욕 시간으로 자동 변환됨
-- order_time(WITH TIME ZONE)은 저장된 서울 시간대 그대로 표시됨

-- 정리
DROP TABLE global_orders;
```