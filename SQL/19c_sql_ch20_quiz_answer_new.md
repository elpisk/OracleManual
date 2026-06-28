# Oracle Database 19c: SQL Workshop
## Chapter 20 — 다른 시간대의 데이터 관리 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ③ | `CURRENT_DATE` → DATE 타입 반환 |
| 2 | ③ | `CURRENT_TIMESTAMP` → TIMESTAMP WITH TIME ZONE 반환 |
| 3 | ② | `LOCALTIMESTAMP` → TIMESTAMP 반환 (시간대 미포함) |
| 4 | ② | `ALTER SESSION SET TIME_ZONE = '-05:00'` |
| 5 | ① | `SELECT DBTIMEZONE FROM DUAL` |
| 6 | ③ | `SESSIONTIMEZONE` — 세션 시간대 확인 함수 |
| 7 | ② | 시간대 오프셋(TIMEZONE_HOUR, TIMEZONE_MINUTE) 또는 지역명 추가 저장 |
| 8 | ④ | TIMESTAMP WITH DATABASE TIME ZONE은 존재하지 않는 타입 |
| 9 | ② | INTERVAL → 두 날짜 값의 차이(기간) 저장 |
| 10 | ② | `INTERVAL YEAR TO MONTH` → YEAR, MONTH 필드 |
| 11 | ③ | `INTERVAL DAY TO SECOND` → DAY, HOUR, MINUTE, SECOND 필드 |
| 12 | ② | EXTRACT → 날짜/타임스탬프에서 특정 컴포넌트 추출 |
| 13 | ② | US/Eastern = UTC-5 = `-05:00` |
| 14 | ② | `FROM_TZ`: TIMESTAMP → TIMESTAMP WITH TIME ZONE 변환 |
| 15 | ② | `TO_TIMESTAMP`: 문자열 → TIMESTAMP 변환 |
| 16 | ② | `TO_YMINTERVAL('01-02')` = 1년 2개월 |
| 17 | ② | `TO_DSINTERVAL('100 10:00:00')` = 100일 10시간 |
| 18 | ② | DST 시작: 시간이 앞으로 이동 → 특정 구간이 건너뛰어져 무효 |
| 19 | ② | CURRENT_DATE = 세션 TZ 기준 / SYSDATE = DB 서버 TZ 기준 |
| 20 | ② | WITH LOCAL TIME ZONE: 저장 시 DB TZ로 정규화, 조회 시 세션 TZ로 표시 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ③**

`CURRENT_TIMESTAMP`는 항상 `TIMESTAMP WITH TIME ZONE` 타입을 반환한다.
세션 시간대 정보(-05:00 등)가 값에 포함되어 있다.

---

**[22번] 정답: ②**

세션 시간대 `-05:00` 기준:
- `CURRENT_DATE`: 세션 시간대 기준 날짜 — DATE 타입 (시간대 정보 없음)
- `CURRENT_TIMESTAMP`: 세션 시간대 기준 날짜+시간 — TIMESTAMP WITH TIME ZONE (시간대 포함)
- `LOCALTIMESTAMP`: 세션 시간대 기준 날짜+시간 — TIMESTAMP (시간대 정보 없음)

세 함수 모두 세션 시간대를 반영하지만, 반환 타입이 다르다.

---

**[23번] 정답: ②**

`ALTER SESSION SET TIME_ZONE = 'America/New_York'`으로 설정하면 `SESSIONTIMEZONE`은 지역명 형태인 `America/New_York`을 반환한다.
절대 오프셋(-05:00)으로 설정했을 때는 오프셋 값을 반환한다.

---

**[24번] 정답: ②**

올바른 INTERVAL YEAR 삽입:
```sql
INSERT INTO warranty VALUES (1, INTERVAL '2' YEAR);
```

- `INTERVAL '값' 단위` 형식을 사용
- 문자열 `'2Y'` 형식이나 숫자 직접 입력은 불가

---

**[25번] 정답: ②**

`EXTRACT(YEAR FROM hire_date) > 2007` 조건으로 2007년 이후 입사 직원 6명이 조회된다.
`hire_date`가 DATE 타입이면 직접 EXTRACT 사용 가능.

---

**[26번] 정답: ③**

`FROM_TZ(TIMESTAMP 값, '시간대')` → `TIMESTAMP WITH TIME ZONE` 반환.
호주 북부 시간대 정보가 결합된 타임스탬프가 반환된다.

---

**[27번] 정답: ③**

`hire_date = 2005-01-01`에 `TO_YMINTERVAL('01-02')` 즉 1년 2개월을 더하면:
- 2005-01-01 + 1년 2개월 = **2006-03-01**

---

**[28번] 정답: ②**

`TO_DSINTERVAL('3 12:30:00')`:
- 형식: `'일수 HH:MI:SS'`
- 3일 12시간 30분 0초

---

**[29번] 정답: ②**

`INTERVAL YEAR TO MONTH`에서 MONTH 필드의 유효값은 **0 ~ 11**이다.
MONTH는 12 이상이 되면 자동으로 YEAR로 올림이 된다.

---

**[30번] 정답: ③**

영국 런던(Europe/London)은 DST 비적용 시 UTC+0이므로 `+00:00`을 반환한다.
DST 적용 시에는 `+01:00`이 된다.

---

**[31번] 정답: ②**

| 구분 | WITH TIME ZONE | WITH LOCAL TIME ZONE |
|------|---------------|---------------------|
| 저장 | 입력한 시간대 그대로 | DB 시간대로 정규화 |
| 조회 | 저장된 시간대 그대로 표시 | 세션 시간대로 변환하여 표시 |

`WITH LOCAL TIME ZONE`은 국제화 앱에서 세션별 자동 시간대 변환에 유용하다.

---

**[32번] 정답: ②**

`INTERVAL '6 03:30:16' DAY TO SECOND`:
- 형식: `'일 HH:MI:SS'`
- **6일 3시간 30분 16초**

---

**[33번] 정답: ②**

EXTRACT가 지원하는 컴포넌트:
- DATE/TIMESTAMP: `YEAR, MONTH, DAY`
- TIMESTAMP만: `HOUR, MINUTE, SECOND`
- TIMESTAMP WITH TIME ZONE: `TIMEZONE_HOUR, TIMEZONE_MINUTE, TIMEZONE_REGION, TIMEZONE_ABBR`
- `CENTURY`, `WEEK`는 EXTRACT에서 지원되지 않음

---

**[34번] 정답: ②**

`ALTER SESSION SET TIME_ZONE = dbtimezone`은 세션 시간대를 DB 서버의 시간대와 동일하게 맞춘다.
DB 시간대 변경 효과는 없다.

---

**[35번] 정답: ②**

DST **종료** 시점:
- 시계가 02:00:00에서 01:00:01로 뒤로 이동
- 01:00:01 ~ 02:00:00 시간대가 두 번 나타남 → **중복 발생**
- Oracle은 `TIMESTAMP WITH TIME ZONE`으로 이를 정확히 구분하여 저장

---

**[36번] 정답: ②**

```sql
TO_TIMESTAMP('2024-06-15 10:30:00', 'YYYY-MM-DD HH24:MI:SS')
```

- 첫 번째 인수: 변환할 **문자열**
- 두 번째 인수: **형식 마스크**
- SYSDATE(DATE 타입)나 SYSTIMESTAMP를 첫 인수로 주는 것은 TO_TIMESTAMP 용도에 맞지 않음

---

**[37번] 정답: ①**

`INTERVAL YEAR(3)`에서 `(3)`은 **정밀도(precision)**를 의미한다.
YEAR 필드에 최대 3자리(0 ~ 999) 숫자를 가질 수 있다.
기본 정밀도는 2이므로 100 이상의 연도를 저장하려면 YEAR(3) 이상으로 지정해야 한다.

---

**[38번] 정답: ②**

`ALTER SESSION SET TIME_ZONE = ...`은 세션 단위로 실행된다.
각 사용자 세션이 독립적으로 시간대를 설정할 수 있으므로, 동일 DB에 접속한 세션이라도 SESSIONTIMEZONE이 다를 수 있다.

---

**[39번] 정답: ④**

EXTRACT에서 추출 가능한 컴포넌트: `YEAR, MONTH, DAY, HOUR, MINUTE, SECOND, TIMEZONE_HOUR, TIMEZONE_MINUTE, TIMEZONE_REGION, TIMEZONE_ABBR`
`CENTURY`는 Oracle EXTRACT에서 지원되지 않는다.

---

**[40번] 정답: ③**

전 세계 고객의 주문 시각 → 각 지역 시간대 정보까지 저장 필요.
`TIMESTAMP WITH TIME ZONE`이 시간대 오프셋 또는 지역명을 함께 저장하므로 가장 적합하다.

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

```
DB 시간대: +00:00 (UTC)    → SYSDATE = DB 서버 시각 (UTC 기준)
세션 시간대: -05:00         → CURRENT_DATE = 세션 시각 (UTC-5 기준)
```

두 값은 서버가 UTC이고 세션이 -05:00이라면 5시간 차이가 난다.
세션이 UTC와 동일 시간대를 사용한다면 두 값이 같을 수 있다.

---

**[42번] 정답: ②**

`TIMESTAMP WITH LOCAL TIME ZONE`의 동작:
- 저장 시: 입력 시각을 DB 서버 시간대(UTC 등)로 정규화하여 저장
- 조회 시: 각 세션의 시간대로 자동 변환하여 표시

서울 세션(+09:00)에서 저장 → UTC 정규화 → 뉴욕 세션(-05:00)에서 조회 시 자동 변환.
DB에 하나의 값, 각 세션에서 현지 시각 자동 표시 → 글로벌 회의 예약에 최적.

---

**[43번] 정답: ②**

`INTERVAL '200' YEAR(3)` → YEAR 필드만 있고 MONTH는 0이므로 표시 형태는:
`+200-00` (200년 0개월)

INTERVAL YEAR TO MONTH의 출력 형식: `+YEAR-MONTH`

---

**[44번] 정답: ②**

세션 시간대 `Asia/Seoul` (UTC+9) 기준:

| 함수 | 타입 | 값 |
|------|------|-----|
| `CURRENT_TIMESTAMP` | TIMESTAMP WITH TIME ZONE | `2026-06-28 15:00:00.0 +09:00` |
| `LOCALTIMESTAMP` | TIMESTAMP | `2026-06-28 15:00:00.0` (시간대 없음) |
| `CURRENT_DATE` | DATE | `2026-06-28 15:00:00` |

CURRENT_TIMESTAMP만 시간대 정보(`+09:00`)를 포함한다.

---

**[45번] 정답: ②**

`INTERVAL YEAR(3)`의 정밀도는 3자리이므로 최대 **999**까지 저장 가능하다.
`INTERVAL '500' YEAR`에서 500은 3자리 이내이므로 **오류가 발생하지 않는다**.

단, 기본 정밀도 `INTERVAL YEAR(2)`인 경우 100 이상은 오류:
```sql
-- YEAR(2) 기본 정밀도 → 100 이상 ORA-01873
INSERT INTO t VALUES (INTERVAL '100' YEAR(2));  -- 오류
INSERT INTO t VALUES (INTERVAL '100' YEAR(3));  -- 정상
```

---

**[46번] 정답: ②**

| 방법 | 의미 | 윤년 영향 |
|------|------|-----------|
| `TO_YMINTERVAL('01-00')` | 달력 기준 1년 후 | 없음 (2025-01-01 → 2026-01-01) |
| `TO_DSINTERVAL('365 00:00:00')` | 정확히 365일 후 | 있음 (윤년이면 1년 = 366일) |

2024년은 윤년(366일)이므로 2024-01-01에:
- `+ TO_YMINTERVAL('01-00')` = 2025-01-01
- `+ TO_DSINTERVAL('365 00:00:00')` = 2024-12-31

---

**[47번] 정답: ②**

`TIMESTAMP WITH TIME ZONE` 컬럼에 삽입할 때:
- `CURRENT_TIMESTAMP` → TIMESTAMP WITH TIME ZONE 타입 → **직접 호환** ✓
- `SYSDATE` → DATE 타입 → 암묵적 변환은 되지만 시간대 정보 없음
- `LOCALTIMESTAMP` → TIMESTAMP (시간대 없음) → 세션 TZ로 자동 변환
- `TO_DATE(...)` → DATE 타입 → 시간대 정보 없음

명시적으로 시간대 정보를 포함한 `CURRENT_TIMESTAMP` 사용이 가장 적합하다.

---

**[48번] 정답: ②**

`TIMESTAMP WITH LOCAL TIME ZONE` 동작:
- 서울(+09:00)에서 입력한 값: DB에 UTC로 정규화되어 저장
- 뉴욕(-05:00) 세션에서 조회: UTC 저장값 - 5시간 = 뉴욕 현지 시각으로 표시
- 서울(+09:00)과 뉴욕(-05:00)의 차이: 14시간

결과: 뉴욕 세션에서는 서울 입력 시각보다 **14시간 이른 시각**이 표시됨.

---

**[49번] 정답: ②**

2024년 3월 10일(미국 DST 시작일)에 `02:00 ~ 02:59` 구간은 존재하지 않는다.
(01:59:59 → 03:00:00으로 건너뜀)

```sql
SELECT FROM_TZ(TIMESTAMP '2024-03-10 02:30:00', 'America/New_York')
FROM DUAL;
-- ORA-01878 또는 예외 처리 필요
-- 02:30:00은 DST 전환으로 존재하지 않는 시각
```

Oracle은 이런 경우 오류를 발생시키거나 경고를 반환한다.
정확한 처리를 위해 애플리케이션에서 DST 전환 시각을 미리 고려해야 한다.

---

**[50번] 정답: ②**

Oracle의 EXTRACT는 `QUARTER`를 직접 지원하지 않는다.
월(MONTH)을 추출한 후 수식으로 분기를 계산:

```sql
SELECT last_name,
       hire_date,
       CEIL(EXTRACT(MONTH FROM hire_date) / 3) AS quarter
FROM   employees
WHERE  department_id = 90;
-- MONTH 1-3 → 1분기, 4-6 → 2분기, 7-9 → 3분기, 10-12 → 4분기
```

- `CEIL(1/3) = 1`, `CEIL(3/3) = 1` → 1분기
- `CEIL(4/3) = 2`, `CEIL(6/3) = 2` → 2분기
- `TRUNC(month/3)`은 month=3일 때 1이 아닌 1이 되어 경계값 처리 오류가 생길 수 있으므로 `CEIL`이 올바르다
