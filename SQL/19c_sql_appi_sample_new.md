# Oracle Database 19c: SQL Workshop
## Appendix I — 정규 표현식 지원 | SQL 실습 문제

---

> **참고:** HR 스키마의 employees, departments 테이블을 활용합니다.

---

## Group 1: REGEXP_LIKE 기본

**[1번]** employees 테이블에서 first_name이 알파벳 문자만으로 구성된 직원을 조회하시오.

```sql
SELECT first_name, last_name
FROM   employees
WHERE  REGEXP_LIKE(first_name, '^[[:alpha:]]+$')
ORDER BY first_name;
```

---

**[2번]** employees 테이블에서 last_name이 대문자로 시작하고 나머지는 소문자인 직원을 조회하시오.

```sql
SELECT last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '^[[:upper:]][[:lower:]]+$')
ORDER BY last_name;
```

---

**[3번]** employees 테이블에서 phone_number가 `515.XXX.XXXX` 형식인 직원을 조회하시오.

```sql
SELECT first_name, last_name, phone_number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^515\.[0-9]{3}\.[0-9]{4}$')
ORDER BY last_name;
```

---

**[4번]** employees 테이블에서 email이 숫자를 포함하는 직원을 조회하시오.

```sql
SELECT first_name, last_name, email
FROM   employees
WHERE  REGEXP_LIKE(email, '[[:digit:]]')
ORDER BY last_name;
```

---

**[5번]** employees 테이블에서 job_id가 `XX_XXX` 형식(대문자 2자 + _ + 대문자 3자)인 직원 수를 조회하시오.

```sql
SELECT COUNT(*) AS cnt
FROM   employees
WHERE  REGEXP_LIKE(job_id, '^[[:upper:]]{2}_[[:upper:]]{3}$');
```

---

## Group 2: REGEXP_REPLACE

**[6번]** employees 테이블에서 phone_number의 구분자(`.`)를 `-`로 변경하시오.

```sql
SELECT phone_number,
       REGEXP_REPLACE(phone_number, '\.', '-') AS new_phone
FROM   employees
WHERE  ROWNUM <= 10;
```

---

**[7번]** 문자열 `'Hello    World   Again'`에서 연속된 공백 2개 이상을 공백 1개로 줄이시오.

```sql
SELECT REGEXP_REPLACE('Hello    World   Again', ' {2,}', ' ') AS clean_text
FROM   dual;
```

---

**[8번]** 날짜 문자열 `'12/25/2024'`를 `YYYY-MM-DD` 형식으로 변환하시오. (서브표현식 역참조 활용)

```sql
SELECT REGEXP_REPLACE('12/25/2024',
    '([0-9]{2})/([0-9]{2})/([0-9]{4})',
    '\3-\1-\2') AS iso_date
FROM   dual;
```

---

**[9번]** employees 테이블에서 phone_number에서 숫자 이외의 문자를 모두 제거하시오.

```sql
SELECT phone_number,
       REGEXP_REPLACE(phone_number, '[^[:digit:]]', '') AS digits_only
FROM   employees
WHERE  ROWNUM <= 10;
```

---

**[10번]** employees 테이블에서 last_name의 모든 모음(aeiou)을 `*`로 교체하시오. (대소문자 무관)

```sql
SELECT last_name,
       REGEXP_REPLACE(last_name, '[aeiouAEIOU]', '*') AS masked_name
FROM   employees
ORDER BY last_name;
```

---

## Group 3: REGEXP_INSTR

**[11번]** 문자열 `'abc123def456'`에서 숫자가 처음 나타나는 위치를 구하시오.

```sql
SELECT REGEXP_INSTR('abc123def456', '[[:digit:]]') AS first_digit_pos
FROM   dual;
```

---

**[12번]** 문자열 `'abc123def456'`에서 두 번째 숫자 그룹의 시작 위치를 구하시오.

```sql
SELECT REGEXP_INSTR('abc123def456', '[[:digit:]]+', 1, 2) AS second_group_pos
FROM   dual;
```

---

**[13번]** employees 테이블에서 email에서 `@` 기호의 위치를 조회하시오.

```sql
SELECT email,
       REGEXP_INSTR(email, '@') AS at_position
FROM   employees
WHERE  ROWNUM <= 10;
```

---

**[14번]** employees 테이블에서 phone_number에서 두 번째 점(`.`)의 위치를 조회하시오.

```sql
SELECT phone_number,
       REGEXP_INSTR(phone_number, '\.', 1, 2) AS second_dot_pos
FROM   employees
WHERE  ROWNUM <= 5;
```

---

## Group 4: REGEXP_SUBSTR

**[15번]** employees 테이블에서 phone_number에서 첫 번째 숫자 그룹(지역번호)을 추출하시오.

```sql
SELECT phone_number,
       REGEXP_SUBSTR(phone_number, '[[:digit:]]+', 1, 1) AS area_code
FROM   employees
WHERE  ROWNUM <= 10;
```

---

**[16번]** 쉼표로 구분된 문자열 `'Red,Green,Blue,Yellow'`에서 세 번째 값을 추출하시오.

```sql
SELECT REGEXP_SUBSTR('Red,Green,Blue,Yellow', '[^,]+', 1, 3) AS third_item
FROM   dual;
```

---

**[17번]** employees 테이블에서 email에서 `@` 앞부분(로컬 파트)만 추출하시오.

```sql
SELECT email,
       REGEXP_SUBSTR(email, '^[^@]+') AS local_part
FROM   employees
ORDER BY last_name;
```

---

**[18번]** 문자열 `'2024-12-25'`에서 서브표현식을 이용하여 연도, 월, 일을 각각 추출하시오.

```sql
SELECT REGEXP_SUBSTR('2024-12-25', '([0-9]{4})-([0-9]{2})-([0-9]{2})', 1, 1, NULL, 1) AS year_val,
       REGEXP_SUBSTR('2024-12-25', '([0-9]{4})-([0-9]{2})-([0-9]{2})', 1, 1, NULL, 2) AS month_val,
       REGEXP_SUBSTR('2024-12-25', '([0-9]{4})-([0-9]{2})-([0-9]{2})', 1, 1, NULL, 3) AS day_val
FROM   dual;
```

---

## Group 5: REGEXP_COUNT

**[19번]** 문자열 `'aababababc'`에서 패턴 `'ab'` 발생 횟수를 세시오.

```sql
SELECT REGEXP_COUNT('aababababc', 'ab') AS ab_count
FROM   dual;
```

---

**[20번]** employees 테이블에서 phone_number에 점(`.`)이 정확히 2개인 직원을 조회하시오.

```sql
SELECT first_name, last_name, phone_number
FROM   employees
WHERE  REGEXP_COUNT(phone_number, '\.') = 2
ORDER BY last_name;
```

---

**[21번]** 문자열 `'The quick brown fox'`에서 모음(aeiou) 개수를 세시오. (대소문자 무관)

```sql
SELECT REGEXP_COUNT('The quick brown fox', '[aeiou]', 1, 'i') AS vowel_count
FROM   dual;
```

---

**[22번]** employees 테이블에서 last_name에 모음이 가장 많은 상위 5명을 조회하시오.

```sql
SELECT last_name,
       REGEXP_COUNT(last_name, '[aeiouAEIOU]') AS vowel_count
FROM   employees
ORDER BY vowel_count DESC
FETCH FIRST 5 ROWS ONLY;
```

---

## Group 6: 종합 실습 및 CHECK 제약

**[23번]** 전화번호 형식, 이메일, 우편번호 CHECK 제약이 있는 테이블을 생성하시오.

```sql
CREATE TABLE contacts_new (
    contact_id  NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   VARCHAR2(100)   NOT NULL,
    phone       VARCHAR2(20)
        CONSTRAINT chk_phone_new
        CHECK (REGEXP_LIKE(phone, '^010-[0-9]{4}-[0-9]{4}$')),
    email       VARCHAR2(200)
        CONSTRAINT chk_email_new
        CHECK (REGEXP_LIKE(email, '^[[:alnum:]._%-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}$', 'i')),
    zipcode     VARCHAR2(10)
        CONSTRAINT chk_zip_new
        CHECK (REGEXP_LIKE(zipcode, '^[0-9]{5}(-[0-9]{4})?$'))
);
```

---

**[24번]** 위 contacts_new 테이블에 올바른 데이터와 잘못된 데이터를 INSERT하여 CHECK 제약을 확인하시오.

```sql
-- 올바른 데이터 (성공)
INSERT INTO contacts_new (full_name, phone, email, zipcode)
VALUES ('김철수', '010-1234-5678', 'kim@oracle.com', '12345');

-- 잘못된 전화번호 (실패)
INSERT INTO contacts_new (full_name, phone, email, zipcode)
VALUES ('이영희', '02-123-4567', 'lee@oracle.com', '12345');
-- ORA-02290: check constraint violated

-- 잘못된 이메일 (실패)
INSERT INTO contacts_new (full_name, phone, email, zipcode)
VALUES ('박민준', '010-5678-9012', 'not-an-email', '67890');
-- ORA-02290: check constraint violated
```

---

**[25번]** employees 테이블에서 last_name의 길이별 분포를 정규 표현식으로 분류하시오.

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

---

**[26번]** employees 테이블에서 phone_number의 세 번째 숫자 그룹(마지막 4자리)을 마스킹하시오.

```sql
SELECT phone_number,
       REGEXP_REPLACE(phone_number,
           '([0-9]{3})\.([0-9]{3})\.([0-9]{4})',
           '\1.\2.****') AS masked_phone
FROM   employees
WHERE  ROWNUM <= 10;
```

---

**[27번]** employees 테이블에서 hire_date를 기준으로 `YYYY-MM-DD` 형식 검증 후 연도를 추출하시오.

```sql
SELECT employee_id,
       TO_CHAR(hire_date, 'YYYY-MM-DD') AS hire_str,
       REGEXP_SUBSTR(TO_CHAR(hire_date, 'YYYY-MM-DD'), '^[0-9]{4}') AS hire_year
FROM   employees
WHERE  REGEXP_LIKE(TO_CHAR(hire_date, 'YYYY-MM-DD'),
           '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$')
ORDER BY hire_date;
```

---

**[28번]** 다음 HTML 문자열에서 모든 태그를 제거하시오.

```sql
SELECT REGEXP_REPLACE(
    '<h1>Oracle Database</h1><p>19c <b>SQL</b> Workshop</p>',
    '<[^>]+>',
    '') AS plain_text
FROM   dual;
```

---

**[29번]** employees 테이블에서 last_name의 모음(aeiou)을 각각 카운트하여 가장 많은 모음을 포함한 직원 상위 3명을 조회하시오.

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

**[30번]** 쉼표 구분 문자열을 행으로 분리하는 쿼리를 작성하시오 (CONNECT BY 활용).

```sql
WITH data AS (
    SELECT 'Apple,Banana,Cherry,Date,Elderberry' AS str FROM dual
)
SELECT REGEXP_SUBSTR(str, '[^,]+', 1, LEVEL) AS item,
       LEVEL AS item_num
FROM   data
CONNECT BY LEVEL <= REGEXP_COUNT(str, ',') + 1;
```
