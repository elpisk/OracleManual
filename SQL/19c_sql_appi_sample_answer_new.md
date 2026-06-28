# Oracle Database 19c: SQL Workshop
## Appendix I — 정규 표현식 지원 | SQL 실습 모범답안

---

## Group 1: REGEXP_LIKE 기본

**[1번]** 알파벳만으로 구성된 first_name

```sql
SELECT first_name, last_name
FROM   employees
WHERE  REGEXP_LIKE(first_name, '^[[:alpha:]]+$')
ORDER BY first_name;
```

`^[[:alpha:]]+$`: 처음부터 끝까지 알파벳만. 숫자나 특수문자가 있으면 제외.  
HR 스키마에서 거의 모든 first_name이 해당. 하이픈(`-`)이나 공백이 있는 이름은 제외된다.

---

**[2번]** 대문자로 시작하고 나머지는 소문자인 last_name

```sql
SELECT last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '^[[:upper:]][[:lower:]]+$')
ORDER BY last_name;
```

`^[[:upper:]]`: 첫 글자 대문자 하나. `[[:lower:]]+$`: 이후 소문자 1자 이상.  
결과: King, Smith처럼 일반적인 영미권 성(姓) 형식.

---

**[3번]** `515.XXX.XXXX` 형식 전화번호

```sql
SELECT first_name, last_name, phone_number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^515\.[0-9]{3}\.[0-9]{4}$')
ORDER BY last_name;
```

`\.`: 마침표 문자 자체 (`.`은 임의 문자이므로 이스케이프 필요).  
`[0-9]{3}`: 정확히 3자리 숫자. `[0-9]{4}`: 정확히 4자리 숫자.

---

**[4번]** email에 숫자가 포함된 직원

```sql
SELECT first_name, last_name, email
FROM   employees
WHERE  REGEXP_LIKE(email, '[[:digit:]]')
ORDER BY last_name;
```

`[[:digit:]]`: 이메일 어디에든 숫자가 하나라도 있으면 일치.  
`^`와 `$` 없음 → 부분 일치 검색.

---

**[5번]** `XX_XXX` 형식 job_id 직원 수

```sql
SELECT COUNT(*) AS cnt
FROM   employees
WHERE  REGEXP_LIKE(job_id, '^[[:upper:]]{2}_[[:upper:]]{3}$');
```

HR 스키마 job_id 예: `IT_PROG`(IT_PROG = 2+_+4 = 불일치), `AD_VP`, `SA_REP`(SA=2, REP=3 = ✓).  
정확히 2+1+3=6자리 job_id만 해당.

---

## Group 2: REGEXP_REPLACE

**[6번]** 전화번호 구분자 `.` → `-`

```sql
SELECT phone_number,
       REGEXP_REPLACE(phone_number, '\.', '-') AS new_phone
FROM   employees WHERE ROWNUM <= 10;
```

**결과 예시:**
```
PHONE_NUMBER     NEW_PHONE
---------------- ----------------
515.123.4567     515-123-4567
590.423.4567     590-423-4567
```

---

**[7번]** 연속 공백 제거

```sql
SELECT REGEXP_REPLACE('Hello    World   Again', ' {2,}', ' ') AS clean_text
FROM   dual;
```

**결과:**
```
Hello World Again
```

` {2,}`: 공백 2개 이상 → 공백 1개로 교체.

---

**[8번]** 날짜 형식 변환 (서브표현식 역참조)

```sql
SELECT REGEXP_REPLACE('12/25/2024',
    '([0-9]{2})/([0-9]{2})/([0-9]{4})',
    '\3-\1-\2') AS iso_date
FROM   dual;
```

**결과:**
```
2024-12-25
```

- `\1` = 12 (MM)
- `\2` = 25 (DD)
- `\3` = 2024 (YYYY)
- `'\3-\1-\2'` = `2024-12-25`

---

**[9번]** 전화번호에서 숫자만 추출

```sql
SELECT phone_number,
       REGEXP_REPLACE(phone_number, '[^[:digit:]]', '') AS digits_only
FROM   employees WHERE ROWNUM <= 10;
```

**결과 예시:**
```
PHONE_NUMBER     DIGITS_ONLY
---------------- -----------
515.123.4567     5151234567
590.423.4567     5904234567
```

---

**[10번]** 모음 마스킹

```sql
SELECT last_name,
       REGEXP_REPLACE(last_name, '[aeiouAEIOU]', '*') AS masked_name
FROM   employees ORDER BY last_name;
```

**결과 예시:**
```
LAST_NAME    MASKED_NAME
------------ ------------
Abel         *b*l
Davies       D*v**s
King         K*ng
```

---

## Group 3: REGEXP_INSTR

**[11번]** 처음 숫자 나타나는 위치

```sql
SELECT REGEXP_INSTR('abc123def456', '[[:digit:]]') AS first_digit_pos
FROM   dual;
```

**결과:** `4`  
`a(1) b(2) c(3) 1(4)` → 숫자 `1`이 4번째 위치.

---

**[12번]** 두 번째 숫자 그룹 위치

```sql
SELECT REGEXP_INSTR('abc123def456', '[[:digit:]]+', 1, 2) AS second_group_pos
FROM   dual;
```

**결과:** `10`  
- 1번째 그룹: `123` (위치 4)
- 2번째 그룹: `456` (위치 10)

---

**[13번]** email에서 @ 위치

```sql
SELECT email, REGEXP_INSTR(email, '@') AS at_position
FROM   employees WHERE ROWNUM <= 10;
```

**활용:** `@` 위치를 알면 로컬 파트(`SUBSTR(email, 1, at_pos-1)`)와 도메인 파트를 분리할 수 있다.

---

**[14번]** 전화번호에서 두 번째 점 위치

```sql
SELECT phone_number,
       REGEXP_INSTR(phone_number, '\.', 1, 2) AS second_dot_pos
FROM   employees WHERE ROWNUM <= 5;
```

**결과 예시:** `515.123.4567` → 두 번째 `.` = 위치 8.

---

## Group 4: REGEXP_SUBSTR

**[15번]** 첫 번째 숫자 그룹(지역번호) 추출

```sql
SELECT phone_number,
       REGEXP_SUBSTR(phone_number, '[[:digit:]]+', 1, 1) AS area_code
FROM   employees WHERE ROWNUM <= 10;
```

**결과 예시:** `515.123.4567` → `515`

---

**[16번]** 세 번째 항목 추출

```sql
SELECT REGEXP_SUBSTR('Red,Green,Blue,Yellow', '[^,]+', 1, 3) AS third_item
FROM   dual;
```

**결과:** `Blue`  
`[^,]+`: 쉼표가 아닌 문자의 연속 → `occurrence=3`으로 세 번째 항목.

---

**[17번]** 이메일 로컬 파트 추출

```sql
SELECT email, REGEXP_SUBSTR(email, '^[^@]+') AS local_part
FROM   employees ORDER BY last_name;
```

**결과 예시:**
```
EMAIL        LOCAL_PART
------------ ----------
SKING        SKING
NKOCHHAR     NKOCHHAR
```

---

**[18번]** 연도/월/일 분리 (서브표현식)

```sql
SELECT REGEXP_SUBSTR('2024-12-25', '([0-9]{4})-([0-9]{2})-([0-9]{2})', 1, 1, NULL, 1) AS year_val,
       REGEXP_SUBSTR('2024-12-25', '([0-9]{4})-([0-9]{2})-([0-9]{2})', 1, 1, NULL, 2) AS month_val,
       REGEXP_SUBSTR('2024-12-25', '([0-9]{4})-([0-9]{2})-([0-9]{2})', 1, 1, NULL, 3) AS day_val
FROM   dual;
```

**결과:**
```
YEAR_VAL  MONTH_VAL  DAY_VAL
--------  ---------  -------
2024      12         25
```

6번째 인수 `subexpression`: 1=첫 번째 그룹, 2=두 번째 그룹, 3=세 번째 그룹.

---

## Group 5: REGEXP_COUNT

**[19번]** 'ab' 발생 횟수

```sql
SELECT REGEXP_COUNT('aababababc', 'ab') AS ab_count FROM dual;
```

**결과:** `4`  
`a|ab|ab|ab|ab|c` → `ab`가 4회 발생.

---

**[20번]** 점이 2개인 전화번호 직원

```sql
SELECT first_name, last_name, phone_number
FROM   employees
WHERE  REGEXP_COUNT(phone_number, '\.') = 2
ORDER BY last_name;
```

HR 스키마 phone_number 형식 `515.123.4567` → 점 2개 → 대부분 해당.  
`+1 515.123.4567` 형식은 동일하게 점 2개.

---

**[21번]** 문자열의 모음 개수

```sql
SELECT REGEXP_COUNT('The quick brown fox', '[aeiou]', 1, 'i') AS vowel_count
FROM   dual;
```

**결과:** `5`  
T**h**e qu**i**ck br**o**wn f**o**x → e, i, o, o = 4개... 실제로는 `The(e) quick(ui) brown(o) fox(o)` = e,u,i,o,o = 5개.

---

**[22번]** 모음이 많은 상위 5명

```sql
SELECT last_name,
       REGEXP_COUNT(last_name, '[aeiouAEIOU]') AS vowel_count
FROM   employees
ORDER BY vowel_count DESC
FETCH FIRST 5 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME     VOWEL_COUNT
------------- -----------
Marlow        2
Taylor        2
Kaufling      3
...
```

---

## Group 6: 종합 실습

**[23번]** CHECK 제약 테이블 생성

```sql
CREATE TABLE contacts_new (
    contact_id  NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   VARCHAR2(100)   NOT NULL,
    phone       VARCHAR2(20)    CONSTRAINT chk_phone_new
                                CHECK (REGEXP_LIKE(phone, '^010-[0-9]{4}-[0-9]{4}$')),
    email       VARCHAR2(200)   CONSTRAINT chk_email_new
                                CHECK (REGEXP_LIKE(email, '^[[:alnum:]._%-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}$', 'i')),
    zipcode     VARCHAR2(10)    CONSTRAINT chk_zip_new
                                CHECK (REGEXP_LIKE(zipcode, '^[0-9]{5}(-[0-9]{4})?$'))
);
```

---

**[24번]** CHECK 제약 검증

```sql
-- 성공: 올바른 데이터
INSERT INTO contacts_new (full_name, phone, email, zipcode)
VALUES ('김철수', '010-1234-5678', 'kim@oracle.com', '12345');
-- 1 row created.

-- 실패: 잘못된 전화번호 형식 (일반 전화번호)
INSERT INTO contacts_new (full_name, phone, email, zipcode)
VALUES ('이영희', '02-123-4567', 'lee@oracle.com', '12345');
-- ORA-02290: check constraint (HR.CHK_PHONE_NEW) violated

-- 실패: @ 없는 이메일
INSERT INTO contacts_new (full_name, phone, email, zipcode)
VALUES ('박민준', '010-5678-9012', 'not-an-email', '12345');
-- ORA-02290: check constraint (HR.CHK_EMAIL_NEW) violated
```

---

**[25번]** 이름 길이별 분포

```sql
SELECT CASE
           WHEN REGEXP_LIKE(last_name, '^.{1,4}$')  THEN '1~4자'
           WHEN REGEXP_LIKE(last_name, '^.{5,7}$')  THEN '5~7자'
           WHEN REGEXP_LIKE(last_name, '^.{8,10}$') THEN '8~10자'
           ELSE '11자 이상'
       END AS name_length_group,
       COUNT(*) AS cnt
FROM   employees
GROUP BY CASE
             WHEN REGEXP_LIKE(last_name, '^.{1,4}$')  THEN '1~4자'
             WHEN REGEXP_LIKE(last_name, '^.{5,7}$')  THEN '5~7자'
             WHEN REGEXP_LIKE(last_name, '^.{8,10}$') THEN '8~10자'
             ELSE '11자 이상'
         END
ORDER BY MIN(LENGTH(last_name));
```

**결과 예시:**
```
NAME_LENGTH_GROUP  CNT
-----------------  ---
1~4자              12
5~7자              62
8~10자             31
11자 이상           2
```

---

**[26번]** 전화번호 마지막 4자리 마스킹

```sql
SELECT phone_number,
       REGEXP_REPLACE(phone_number,
           '([0-9]{3})\.([0-9]{3})\.([0-9]{4})',
           '\1.\2.****') AS masked_phone
FROM   employees WHERE ROWNUM <= 10;
```

**결과 예시:**
```
PHONE_NUMBER     MASKED_PHONE
---------------- ----------------
515.123.4567     515.123.****
590.423.4567     590.423.****
```

서브표현식 `\1`, `\2`로 앞 두 그룹은 유지, 세 번째 그룹(마지막 4자리)을 `****`로 교체.

---

**[27번]** 입사일 형식 검증 및 연도 추출

```sql
SELECT employee_id,
       TO_CHAR(hire_date, 'YYYY-MM-DD') AS hire_str,
       REGEXP_SUBSTR(TO_CHAR(hire_date, 'YYYY-MM-DD'), '^[0-9]{4}') AS hire_year
FROM   employees
WHERE  REGEXP_LIKE(TO_CHAR(hire_date, 'YYYY-MM-DD'),
           '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$')
ORDER BY hire_date;
```

`(0[1-9]|1[0-2])`: 월 01~12만 허용.  
`(0[1-9]|[12][0-9]|3[01])`: 일 01~31만 허용.

---

**[28번]** HTML 태그 제거

```sql
SELECT REGEXP_REPLACE(
    '<h1>Oracle Database</h1><p>19c <b>SQL</b> Workshop</p>',
    '<[^>]+>',
    '') AS plain_text
FROM   dual;
```

**결과:**
```
Oracle Database19c SQL Workshop
```

`<[^>]+>`: `<`로 시작하고 `>`가 아닌 문자들 후 `>`로 끝나는 패턴.

---

**[29번]** 모음별 카운트 및 최다 모음 직원

```sql
SELECT last_name,
       REGEXP_COUNT(LOWER(last_name), 'a') AS a_cnt,
       REGEXP_COUNT(LOWER(last_name), 'e') AS e_cnt,
       REGEXP_COUNT(LOWER(last_name), 'i') AS i_cnt,
       REGEXP_COUNT(LOWER(last_name), 'o') AS o_cnt,
       REGEXP_COUNT(LOWER(last_name), 'u') AS u_cnt,
       REGEXP_COUNT(last_name, '[aeiouAEIOU]') AS total_vowels
FROM   employees
ORDER BY total_vowels DESC
FETCH FIRST 3 ROWS ONLY;
```

---

**[30번]** 쉼표 구분 문자열을 행으로 분리

```sql
WITH data AS (
    SELECT 'Apple,Banana,Cherry,Date,Elderberry' AS str FROM dual
)
SELECT REGEXP_SUBSTR(str, '[^,]+', 1, LEVEL) AS item,
       LEVEL AS item_num
FROM   data
CONNECT BY LEVEL <= REGEXP_COUNT(str, ',') + 1;
```

**결과:**
```
ITEM          ITEM_NUM
------------- --------
Apple         1
Banana        2
Cherry        3
Date          4
Elderberry    5
```

**원리:**
- `REGEXP_COUNT(str, ',') + 1`: 쉼표 개수 + 1 = 항목 개수
- `CONNECT BY LEVEL <= 5`: 행 5개 생성
- `REGEXP_SUBSTR(str, '[^,]+', 1, LEVEL)`: 각 LEVEL번째 항목 추출
