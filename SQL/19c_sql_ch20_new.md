# Oracle Database 19c: SQL Workshop
## Chapter 20 — 다른 시간대의 데이터 관리 (Managing Data in Different Time Zones)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- DATE와 유사하지만 소수점 초와 시간대를 저장하는 데이터 타입을 사용한다
- 두 날짜/시간 값의 차이를 저장하는 INTERVAL 데이터 타입을 사용한다
- 다음 날짜/시간 함수를 사용한다:
  CURRENT_DATE, CURRENT_TIMESTAMP, LOCALTIMESTAMP, DBTIMEZONE, SESSIONTIMEZONE, EXTRACT, TZ_OFFSET, FROM_TZ, TO_TIMESTAMP, TO_YMINTERVAL, TO_DSINTERVAL

---

## 1. 시간대(Time Zone) 개요

### 1-1. E-Commerce 시나리오

글로벌 전자상거래 환경에서는 주문 시점의 **고객 현지 시간**을 기록해야 한다.

```
Rick (호주)       →   주문 입력   →   OracleKart DB 서버 (미국)
현지 시각 필요                        DB 서버 시각으로 저장 X
```

- 서버가 미국에 있어도 호주 고객의 주문 시각은 **호주 시간대** 기준으로 기록해야 한다
- Oracle은 세션 단위로 시간대를 설정하는 기능을 제공한다

### 1-2. TIME_ZONE 세션 파라미터

세션 시간대를 설정하는 방법:

```sql
-- 절대 오프셋 지정
ALTER SESSION SET TIME_ZONE = '-05:00';

-- DB 시간대와 동일하게
ALTER SESSION SET TIME_ZONE = dbtimezone;

-- OS 로컬 시간대
ALTER SESSION SET TIME_ZONE = local;

-- 지역명 지정
ALTER SESSION SET TIME_ZONE = 'America/New_York';
```

---

## 2. CURRENT_DATE, CURRENT_TIMESTAMP, LOCALTIMESTAMP

| 함수 | 반환 타입 | 설명 |
|------|-----------|------|
| `CURRENT_DATE` | DATE | 세션 시간대 기준 현재 날짜 |
| `CURRENT_TIMESTAMP` | TIMESTAMP WITH TIME ZONE | 세션 시간대 기준 현재 날짜+시간 (시간대 포함) |
| `LOCALTIMESTAMP` | TIMESTAMP | 세션 시간대 기준 현재 날짜+시간 (시간대 제외) |

```sql
-- 세션 시간대 설정 후 비교
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';
ALTER SESSION SET TIME_ZONE = '-5:00';

SELECT SESSIONTIMEZONE, CURRENT_DATE      FROM DUAL;  -- 1
SELECT SESSIONTIMEZONE, CURRENT_TIMESTAMP FROM DUAL;  -- 2
SELECT SESSIONTIMEZONE, LOCALTIMESTAMP    FROM DUAL;  -- 3
```

- ① `CURRENT_DATE`: 시간대 정보 없는 DATE
- ② `CURRENT_TIMESTAMP`: 시간대 오프셋(-05:00)이 함께 표시
- ③ `LOCALTIMESTAMP`: 시간대 정보 없는 TIMESTAMP

---

## 3. DBTIMEZONE & SESSIONTIMEZONE

```sql
-- DB 시간대 확인
SELECT DBTIMEZONE FROM DUAL;

-- 현재 세션 시간대 확인
SELECT SESSIONTIMEZONE FROM DUAL;
```

- `DBTIMEZONE`: 데이터베이스 서버의 시간대 오프셋 (예: `+00:00`)
- `SESSIONTIMEZONE`: 현재 세션의 시간대 (사용자가 ALTER SESSION으로 변경 가능)

---

## 4. TIMESTAMP 데이터 타입

DATE의 한계(초 단위까지만 저장)를 극복한 확장 타입:

| 데이터 타입 | 저장 내용 |
|-------------|-----------|
| `TIMESTAMP` | 연·월·일·시·분·초 (소수점 이하 초 포함) |
| `TIMESTAMP WITH TIME ZONE` | TIMESTAMP + 시간대 오프셋(TIMEZONE_HOUR, TIMEZONE_MINUTE) 또는 지역명 |
| `TIMESTAMP WITH LOCAL TIME ZONE` | TIMESTAMP + 로컬 시간대 오프셋 (저장 시 정규화, 조회 시 세션 시간대로 표시) |

### 4-1. 유효 범위

| 필드 | 유효값 |
|------|--------|
| YEAR | -4712 ~ 9999 (0년 제외) |
| MONTH | 01 ~ 12 |
| DAY | 01 ~ 31 |
| HOUR | 00 ~ 23 |
| MINUTE | 00 ~ 59 |
| SECOND | 00 ~ 59.9(N) (N = 소수점 정밀도) |
| TIMEZONE_HOUR | -12 ~ 14 |
| TIMEZONE_MINUTE | 00 ~ 59 |

### 4-2. DATE → TIMESTAMP 변환 예제

```sql
-- hire_date 컬럼을 TIMESTAMP로 변경
ALTER TABLE emp4 MODIFY hire_date TIMESTAMP;

-- 조회 결과: 소수점 초 자리가 함께 표시됨
SELECT hire_date FROM emp4;
```

### 4-3. TIMESTAMP WITH TIME ZONE 사용 예제

```sql
CREATE TABLE web_orders (
    order_date    TIMESTAMP WITH TIME ZONE,
    delivery_time TIMESTAMP WITH LOCAL TIME ZONE
);

INSERT INTO web_orders VALUES (CURRENT_DATE, CURRENT_TIMESTAMP + 2);

SELECT * FROM web_orders;
```

---

## 5. INTERVAL 데이터 타입

두 날짜/시간 값 사이의 **간격(차이)**을 저장하는 타입:

| 데이터 타입 | 저장 내용 | 필드 |
|-------------|-----------|------|
| `INTERVAL YEAR TO MONTH` | 연·월 단위 기간 | YEAR, MONTH |
| `INTERVAL DAY TO SECOND` | 일·시·분·초 단위 기간 | DAY, HOUR, MINUTE, SECOND |

### 5-1. INTERVAL YEAR TO MONTH 예제

```sql
CREATE TABLE warranty (
    prod_id      NUMBER,
    warranty_time INTERVAL YEAR(3) TO MONTH
);

-- 8개월
INSERT INTO warranty VALUES (123, INTERVAL '8' MONTH);

-- 200년 (YEAR 정밀도 3자리)
INSERT INTO warranty VALUES (155, INTERVAL '200' YEAR(3));

-- 200년 11개월 (문자열 리터럴)
INSERT INTO warranty VALUES (678, '200-11');

SELECT * FROM warranty;
```

### 5-2. INTERVAL DAY TO SECOND 예제

```sql
CREATE TABLE lab (
    exp_id    NUMBER,
    test_time INTERVAL DAY(2) TO SECOND
);

-- 90일
INSERT INTO lab VALUES (100012, '90 00:00:00');

-- 6일 3시간 30분 16초
INSERT INTO lab VALUES (56098, INTERVAL '6 03:30:16' DAY TO SECOND);

SELECT * FROM lab;
```

### 5-3. INTERVAL 산술 연산

```sql
-- 1년 2개월 후 날짜
SELECT hire_date + TO_YMINTERVAL('1-2') FROM employees WHERE employee_id = 100;

-- 100일 10시간 후
SELECT hire_date + TO_DSINTERVAL('100 10:00:00') FROM employees WHERE employee_id = 100;
```

---

## 6. 날짜/시간 함수

### 6-1. EXTRACT

날짜/타임스탬프에서 특정 컴포넌트(YEAR, MONTH, DAY, HOUR, MINUTE, SECOND 등)를 추출한다.

```sql
-- 2007년 이후 입사한 직원
SELECT last_name, employee_id, hire_date
FROM   employees
WHERE  EXTRACT(YEAR FROM TO_DATE(hire_date, 'DD-MON-RR')) > 2007
ORDER BY hire_date;

-- manager_id = 100인 직원의 입사 월
SELECT last_name, hire_date,
       EXTRACT(MONTH FROM hire_date) AS hire_month
FROM   employees
WHERE  manager_id = 100;
```

### 6-2. TZ_OFFSET

시간대 이름을 전달하면 UTC 기준 오프셋을 반환한다.

```sql
SELECT TZ_OFFSET('US/Eastern'),
       TZ_OFFSET('Canada/Yukon'),
       TZ_OFFSET('Europe/London')
FROM   DUAL;
-- -05:00   -07:00   +00:00
```

### 6-3. FROM_TZ

`TIMESTAMP` 값에 시간대 정보를 추가하여 `TIMESTAMP WITH TIME ZONE`으로 변환한다.

```sql
SELECT FROM_TZ(TIMESTAMP '2000-07-12 08:00:00', 'Australia/North')
FROM   DUAL;
-- 2000-07-12 08:00:00.000000000 AUSTRALIA/NORTH
```

### 6-4. TO_TIMESTAMP

날짜/시간 문자열을 `TIMESTAMP`로 변환한다.

```sql
SELECT TO_TIMESTAMP('2016-03-06 11:00:00', 'YYYY-MM-DD HH:MI:SS')
FROM   DUAL;
-- 06-MAR-16 11.00.00.000000000 AM
```

### 6-5. TO_YMINTERVAL

`'YEAR-MONTH'` 형식 문자열을 `INTERVAL YEAR TO MONTH`로 변환한다.

```sql
-- 입사일로부터 1년 2개월 후
SELECT hire_date,
       hire_date + TO_YMINTERVAL('01-02') AS hire_plus_14months
FROM   employees
WHERE  department_id = 20;
```

### 6-6. TO_DSINTERVAL

`'DAYS HH:MM:SS'` 형식 문자열을 `INTERVAL DAY TO SECOND`로 변환한다.

```sql
-- 입사일로부터 100일 10시간 후
SELECT last_name,
       TO_CHAR(hire_date, 'MM-DD-YY:HH:MI:SS')                    AS hire_date,
       TO_CHAR(hire_date + TO_DSINTERVAL('100 10:00:00'),
               'MM-DD-YY:HH:MI:SS')                                AS hire_plus
FROM   employees;
```

---

## 7. 일광 절약 시간 (Daylight Saving Time, DST)

| 이벤트 | 동작 | 영향 |
|--------|------|------|
| DST 시작 | 01:59:59 → 03:00:00 으로 점프 | 02:00~02:59 시간대 **무효** |
| DST 종료 | 02:00:00 → 01:00:01 으로 뒤로 이동 | 01:00:01~02:00:00 시간대 **중복** |

- Oracle의 `TIMESTAMP WITH TIME ZONE`은 DST를 인식하여 정확한 시각을 저장한다
- `TIMESTAMP WITH LOCAL TIME ZONE`은 DST 변경 시 자동으로 조정된다

---

## 8. 단원 요약

| 주제 | 핵심 내용 |
|------|-----------|
| TIME_ZONE 파라미터 | `ALTER SESSION SET TIME_ZONE = ...`으로 세션 시간대 설정 |
| CURRENT_DATE | 세션 시간대 기준 현재 날짜 (DATE 타입) |
| CURRENT_TIMESTAMP | 세션 시간대 기준 현재 날짜+시간+시간대 |
| LOCALTIMESTAMP | 세션 시간대 기준 현재 날짜+시간 (시간대 미포함) |
| DBTIMEZONE | DB 서버 시간대 확인 |
| SESSIONTIMEZONE | 현재 세션 시간대 확인 |
| TIMESTAMP 타입 3종 | TIMESTAMP / WITH TIME ZONE / WITH LOCAL TIME ZONE |
| INTERVAL YEAR TO MONTH | 연·월 단위 기간 저장 |
| INTERVAL DAY TO SECOND | 일·시·분·초 단위 기간 저장 |
| EXTRACT | 날짜/시간에서 특정 필드 추출 |
| TZ_OFFSET | 시간대 이름 → UTC 오프셋 반환 |
| FROM_TZ | TIMESTAMP → TIMESTAMP WITH TIME ZONE 변환 |
| TO_TIMESTAMP | 문자열 → TIMESTAMP 변환 |
| TO_YMINTERVAL | 문자열 → INTERVAL YEAR TO MONTH 변환 |
| TO_DSINTERVAL | 문자열 → INTERVAL DAY TO SECOND 변환 |
| DST | TIMESTAMP WITH TIME ZONE이 일광 절약 시간 자동 처리 |
