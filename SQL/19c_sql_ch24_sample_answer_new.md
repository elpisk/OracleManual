# Oracle Database 19c: SQL Workshop
## Chapter 25 — 정규표현식 | SQL 실습 모범답안

---

## Group 1: REGEXP_LIKE — 패턴 필터링

**[1번]** 모음으로 시작하는 first_name 직원 조회

```sql
SELECT employee_id, first_name, last_name
FROM   employees
WHERE  REGEXP_LIKE(first_name, '^[AEIOU]', 'i')
ORDER BY first_name;
```

**결과 예시:**
```
EMPLOYEE_ID  FIRST_NAME  LAST_NAME
-----------  ----------  ----------
174          Ellen       Abel
166          Sundar      Ande
130          Mozhe       Atkinson
105          David       Austin
```

키포인트: `^[AEIOU]`는 시작(`^`) 앵커 + 모음 문자 집합. `'i'` 옵션으로 소문자 모음도 일치.

---

**[2번]** last_name에 연속 중복 문자가 있는 직원

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '(.)\1', 'i')
ORDER BY last_name;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME
-----------  ----------
101          Kochhar   (hh)
112          Urman     (현재없음... Whalen=없음)
177          Livingston (없음)
```

*HR 스키마에서 실제 해당 직원: Kochhar(hh), Mikkilineni(ii)*

키포인트: `(.)`는 임의의 한 문자를 그룹 1로 캡처, `\1`은 역참조 — 같은 문자 연속 2회.

---

**[3번]** NNN.NNN.NNNN 형식 전화번호 직원

```sql
SELECT employee_id, last_name, phone_number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME  PHONE_NUMBER
-----------  ---------  -------------
100          King       515.123.4567
101          Kochhar    515.123.4568
102          De Haan    515.123.4569
```

키포인트: `\.`는 메타문자가 아닌 리터럴 점. 국제 번호(`+1 650...`)는 패턴과 불일치.

---

**[4번]** email이 4~6자 대문자 알파벳인 직원

```sql
SELECT employee_id, last_name, email
FROM   employees
WHERE  REGEXP_LIKE(email, '^[A-Z]{4,6}$')
ORDER BY LENGTH(email), email;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME  EMAIL
-----------  ---------  ------
115          Khoo       DKHOO   (5자)
116          Baida      GBAIDA  (6자)
```

키포인트: HR 스키마 email은 모두 대문자 알파벳 — `{4,6}`은 4자 이상 6자 이하.

---

**[5번]** 자음 시작 + 두 번째 글자 모음인 직원

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '^[^AEIOU][AEIOU]', 'i')
ORDER BY last_name;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME
-----------  ----------
100          King       (K=자음, i=모음)
101          Kochhar    (K=자음, o=모음)
102          De Haan    (D=자음, e=모음)
```

키포인트: `[^AEIOU]`는 모음이 아닌 문자 집합(자음). 연속 배치로 두 문자 순서 지정.

---

## Group 2: REGEXP_INSTR — 위치 찾기

**[6번]** 전화번호 숫자 그룹 위치

```sql
SELECT last_name, phone_number,
       REGEXP_INSTR(phone_number, '[0-9]+', 1, 1) AS first_pos,
       REGEXP_INSTR(phone_number, '[0-9]+', 1, 2) AS second_pos,
       REGEXP_INSTR(phone_number, '[0-9]+', 1, 3) AS third_pos
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id FETCH FIRST 8 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  PHONE_NUMBER   FIRST_POS  SECOND_POS  THIRD_POS
---------  -------------  ---------  ----------  ---------
King       515.123.4567           1           5          9
Kochhar    515.123.4568           1           5          9
```

키포인트: `515.123.4567` — 첫 숫자 위치 1, 두 번째 숫자(123) 위치 5, 세 번째(4567) 위치 9.

---

**[7번]** last_name에서 첫 번째 모음 위치

```sql
SELECT last_name,
       REGEXP_INSTR(last_name, '[aeiou]', 1, 1, 0, 'i') AS first_vowel_pos
FROM   employees
ORDER BY first_vowel_pos, last_name
FETCH FIRST 10 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  FIRST_VOWEL_POS
---------  ---------------
Fay                      2
Fox                      2
King                     2
```

키포인트: `REGEXP_INSTR(..., 0, 'i')` — 5번째 파라미터 0=시작 위치 반환, 6번째 'i'=대소문자 무시.

---

**[8번]** 두 번째 모음 위치 (없는 경우 제외)

```sql
SELECT last_name,
       REGEXP_INSTR(last_name, '[aeiou]', 1, 2, 0, 'i') AS second_vowel_pos
FROM   employees
WHERE  REGEXP_INSTR(last_name, '[aeiou]', 1, 2, 0, 'i') > 0
ORDER BY second_vowel_pos DESC, last_name FETCH FIRST 10 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME      SECOND_VOWEL_POS
-------------  ----------------
Mikkilineni                  10
Livingston                    6
```

키포인트: 두 번째 모음이 없으면 0 반환 → `WHERE > 0`으로 필터링.

---

**[9번]** 전체 이름에서 공백 위치

```sql
SELECT first_name || ' ' || last_name AS full_name,
       REGEXP_INSTR(first_name || ' ' || last_name, '\s') AS space_pos
FROM   employees
ORDER BY employee_id FETCH FIRST 8 ROWS ONLY;
```

**결과 예시:**
```
FULL_NAME         SPACE_POS
----------------  ---------
Steven King               7
Neena Kochhar             6
Lex De Haan               4
```

키포인트: `\s`는 공백 문자 클래스. `first_name` 길이 + 1 = 공백 위치.

---

## Group 3: REGEXP_SUBSTR — 부분 추출

**[10번]** 전화번호 분해 (지역번호·국번·번호)

```sql
SELECT last_name, phone_number,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 1) AS area_code,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 2) AS exchange,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 3) AS number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id FETCH FIRST 8 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  PHONE_NUMBER   AREA_CODE  EXCHANGE  NUMBER
---------  -------------  ---------  --------  ------
King       515.123.4567   515        123       4567
Kochhar    515.123.4568   515        123       4568
```

키포인트: `occurrence` 파라미터(4번째)로 1,2,3번째 숫자 그룹을 각각 추출.

---

**[11번]** first_name 이니셜 추출

```sql
SELECT first_name, last_name,
       REGEXP_SUBSTR(first_name, '^[A-Za-z]') || '.' AS initial
FROM   employees
ORDER BY last_name FETCH FIRST 10 ROWS ONLY;
```

**결과 예시:**
```
FIRST_NAME  LAST_NAME   INITIAL
----------  ----------  -------
Ellen       Abel        E.
Mozhe       Atkinson    M.
David       Austin      D.
```

키포인트: `^[A-Za-z]`는 시작 위치의 알파벳 한 글자. `|| '.'`로 점 추가.

---

**[12번]** last_name의 마지막 글자 추출

```sql
SELECT last_name,
       REGEXP_SUBSTR(last_name, '[A-Za-z]$') AS last_char
FROM   employees
ORDER BY last_char, last_name FETCH FIRST 10 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  LAST_CHAR
---------  ---------
De Haan    n
Fay        y
```

키포인트: `[A-Za-z]$`는 끝(`$`) 바로 앞 알파벳 한 글자.

---

**[13번]** last_name에서 두 번째 모음 추출

```sql
SELECT last_name,
       REGEXP_SUBSTR(last_name, '[aeiou]', 1, 2, 'i') AS second_vowel
FROM   employees
ORDER BY second_vowel NULLS LAST, last_name
FETCH FIRST 10 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME   SECOND_VOWEL
----------  ------------
Ande        e
Austin      i
De Haan     a
```

키포인트: 두 번째 모음이 없으면 NULL 반환 → `NULLS LAST`로 정렬 말미 배치.

---

**[14번]** job_id에서 직군 코드·역할 코드 분리

```sql
SELECT job_id,
       REGEXP_SUBSTR(job_id, '^[A-Z]+') AS dept_code,
       REGEXP_SUBSTR(job_id, '[A-Z]+$') AS role_code
FROM   employees
GROUP BY job_id ORDER BY job_id;
```

**결과 예시:**
```
JOB_ID    DEPT_CODE  ROLE_CODE
--------  ---------  ---------
AD_ASST   AD         ASST
AD_PRES   AD         PRES
AD_VP     AD         VP
FI_ACCOUNT FI        ACCOUNT
IT_PROG   IT         PROG
```

키포인트: `^[A-Z]+`는 언더스코어 전 대문자, `[A-Z]+$`는 언더스코어 후 대문자.

---

## Group 4: REGEXP_REPLACE — 패턴 치환

**[15번]** 전화번호 점 → 하이픈 변환

```sql
SELECT last_name, phone_number,
       REGEXP_REPLACE(phone_number, '\.', '-') AS formatted
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id FETCH FIRST 8 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  PHONE_NUMBER   FORMATTED
---------  -------------  -------------
King       515.123.4567   515-123-4567
Kochhar    515.123.4568   515-123-4568
```

키포인트: `occurrence` 기본값 0 = 모든 일치 치환. `\.`로 리터럴 점을 지정.

---

**[16번]** 이름 순서 변환 (성 이름 → 이름 성)

```sql
SELECT last_name || ' ' || first_name AS original,
       REGEXP_REPLACE(
           last_name || ' ' || first_name,
           '^(\S+)\s+(\S+)$', '\2 \1'
       ) AS swapped
FROM   employees ORDER BY employee_id FETCH FIRST 8 ROWS ONLY;
```

**결과 예시:**
```
ORIGINAL          SWAPPED
----------------  ----------------
King Steven       Steven King
Kochhar Neena     Neena Kochhar
De Haan Lex       Lex De Haan
```

키포인트: `(\S+)`는 비공백 문자 1개 이상을 그룹 캡처. `\2 \1`로 순서 교환.

---

**[17번]** 전화번호 → (NNN) NNN-NNNN 형식

```sql
SELECT phone_number,
       REGEXP_REPLACE(
           phone_number,
           '^(\d{3})\.(\d{3})\.(\d{4})$',
           '(\1) \2-\3'
       ) AS new_format
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id FETCH FIRST 8 ROWS ONLY;
```

**결과 예시:**
```
PHONE_NUMBER   NEW_FORMAT
-------------  ---------------
515.123.4567   (515) 123-4567
515.123.4568   (515) 123-4568
```

키포인트: 3개 그룹 캡처 후 `(\1) \2-\3` 패턴으로 형식 재구성.

---

**[18번]** last_name 모음 → `*` 치환

```sql
SELECT last_name,
       REGEXP_REPLACE(last_name, '[aeiou]', '*', 1, 0, 'i') AS masked
FROM   employees ORDER BY employee_id FETCH FIRST 10 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  MASKED
---------  ----------
King       K*ng
Kochhar    K*chh*r
De Haan    D* H**n
```

키포인트: `occurrence=0`은 모든 모음을 `*`로 치환. 대소문자 무시(`'i'`).

---

**[19번]** 연속 중복 문자 → 단일 문자 (deduplicate)

```sql
SELECT last_name,
       REGEXP_REPLACE(last_name, '(.)\1', '\1', 1, 0, 'i') AS dedup
FROM   employees
WHERE  REGEXP_LIKE(last_name, '(.)\1', 'i')
ORDER BY last_name;
```

**결과 예시:**
```
LAST_NAME       DEDUP
--------------  ----------
Kochhar         Kochar
Mikkilineni     Mikilinen
```

키포인트: `(.)\1` 일치를 `\1`(한 글자)로 치환 = 중복 제거.

---

## Group 5: REGEXP_COUNT — 횟수 집계

**[20번]** last_name 모음 개수 — 많은 순

```sql
SELECT last_name,
       REGEXP_COUNT(last_name, '[aeiou]', 1, 'i') AS vowel_count
FROM   employees
ORDER BY vowel_count DESC, last_name
FETCH FIRST 10 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME      VOWEL_COUNT
-------------  -----------
Mikkilineni              4
Livingston               3
Higgins                  3
```

키포인트: `REGEXP_COUNT`는 Oracle 11g+. 일치 없으면 0 반환.

---

**[21번]** 모음 개수별 직원 수 분포

```sql
SELECT REGEXP_COUNT(last_name, '[aeiou]', 1, 'i') AS vowel_count,
       COUNT(*)                                    AS emp_count
FROM   employees
GROUP BY REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')
ORDER BY vowel_count;
```

**결과 예시:**
```
VOWEL_COUNT  EMP_COUNT
-----------  ---------
          0          1
          1         28
          2         42
          3         28
          4          8
```

키포인트: `GROUP BY`에서도 `REGEXP_COUNT`를 직접 사용 가능.

---

**[22번]** 숫자 그룹이 3개인 전화번호

```sql
SELECT employee_id, last_name, phone_number,
       REGEXP_COUNT(phone_number, '[0-9]+') AS digit_groups
FROM   employees
WHERE  REGEXP_COUNT(phone_number, '[0-9]+') = 3
ORDER BY employee_id FETCH FIRST 8 ROWS ONLY;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME  PHONE_NUMBER   DIGIT_GROUPS
-----------  ---------  -------------  ------------
100          King       515.123.4567              3
101          Kochhar    515.123.4568              3
```

키포인트: 점 구분 형식은 숫자 그룹 3개. 국제 번호(`+1 650...`)는 그룹 수 다름.

---

**[23번]** 자음 개수 상위 5명

```sql
SELECT last_name,
       LENGTH(last_name)                                           AS total_len,
       REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')                 AS vowels,
       LENGTH(last_name) - REGEXP_COUNT(last_name, '[aeiou]', 1, 'i') AS consonants
FROM   employees
ORDER BY consonants DESC, last_name
FETCH FIRST 5 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME       TOTAL_LEN  VOWELS  CONSONANTS
--------------  ---------  ------  ----------
Mikkilineni            11       4           7
Livingston             10       3           7
```

키포인트: 자음 수 = 전체 길이 - 모음 수 (공백·특수문자 포함 주의).

---

## Group 6: 종합 실습

**[24번]** 이메일 유효성 검사 + 전체 이메일 생성

```sql
SELECT employee_id, last_name, email,
       CASE WHEN REGEXP_LIKE(email, '^[A-Z]+$')
            THEN LOWER(email) || '@oracle.com'
            ELSE '이메일 형식 오류'
       END AS full_email,
       CASE WHEN REGEXP_COUNT(email, '[A-Z]') BETWEEN 1 AND 4
            THEN '짧음'
            WHEN REGEXP_COUNT(email, '[A-Z]') BETWEEN 5 AND 6
            THEN '보통'
            ELSE '김'
       END AS email_length_category
FROM   employees
ORDER BY email_length_category, employee_id
FETCH FIRST 10 ROWS ONLY;
```

**결과 예시:**
```
EMP  LAST_NAME  EMAIL   FULL_EMAIL            CATEGORY
---  ---------  ------  --------------------  --------
115  Khoo       DKHOO   dkhoo@oracle.com      보통
100  King       SKING   sking@oracle.com      보통
```

키포인트: `REGEXP_LIKE`로 검증 후 `LOWER()`로 소문자 변환. `REGEXP_COUNT`로 길이 분류.

---

**[25번]** 전화번호 종합 — 형식 변환 + 분해

```sql
SELECT last_name, phone_number,
       REGEXP_REPLACE(
           phone_number,
           '^(\d{3})\.(\d{3})\.(\d{4})$', '(\1) \2-\3'
       )                                           AS formatted,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 1) AS area_code,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 2) AS exchange,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 3) AS number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id FETCH FIRST 8 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  PHONE_NUMBER   FORMATTED        AREA  EXCH  NUM
---------  -------------  ---------------  ----  ----  ----
King       515.123.4567   (515) 123-4567   515   123   4567
Kochhar    515.123.4568   (515) 123-4568   515   123   4568
```

키포인트: 단일 쿼리에서 `REGEXP_REPLACE`(형식 변환)와 `REGEXP_SUBSTR`(분해)를 동시에 활용.

---

**[26번]** last_name 종합 분석 보고서

```sql
SELECT employee_id, last_name, first_name,
       LENGTH(last_name)                                        AS name_len,
       REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')              AS vowels,
       LENGTH(last_name)
         - REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')          AS consonants,
       CASE WHEN REGEXP_LIKE(last_name, '(.)\1', 'i')
            THEN 'Y' ELSE 'N'
       END                                                     AS has_double,
       REGEXP_SUBSTR(first_name, '^[A-Za-z]') || '.'
         || REGEXP_SUBSTR(last_name, '^[A-Za-z]') || '.'       AS initials
FROM   employees
ORDER BY vowels DESC, name_len DESC
FETCH FIRST 15 ROWS ONLY;
```

**결과 예시:**
```
EMP  LAST_NAME      FIRST  LEN  VOWELS  CONS  DBL  INITIALS
---  -------------  -----  ---  ------  ----  ---  --------
     Mikkilineni          11       4       7   Y    S.M.
     Livingston           10       3       7   N    C.L.
100  King                  4       1       3   N    S.K.
```

키포인트: 5가지 정규표현식 함수(`REGEXP_COUNT`, `REGEXP_LIKE`, `REGEXP_SUBSTR`)를 단일 쿼리에서 조합.

---

**[27번]** job_id 직군별 집계

```sql
SELECT REGEXP_SUBSTR(job_id, '^[A-Z]+') AS dept_code,
       COUNT(*)                          AS emp_count,
       ROUND(AVG(salary), 0)             AS avg_salary,
       MIN(salary)                       AS min_salary,
       MAX(salary)                       AS max_salary
FROM   employees
GROUP BY REGEXP_SUBSTR(job_id, '^[A-Z]+')
ORDER BY avg_salary DESC;
```

**결과 예시:**
```
DEPT_CODE  EMP_COUNT  AVG_SALARY  MIN_SALARY  MAX_SALARY
---------  ---------  ----------  ----------  ----------
AD                 4       19500       17000       24000
AC                 2       12004       11000       13000
FI                 6        8400        6900       12008
IT                 5        5760        4200        9000
SA                62        8051        2100       14000
```

키포인트: `REGEXP_SUBSTR(job_id, '^[A-Z]+')`로 직군 코드 추출 → `GROUP BY`에 사용.

---

**[28번]** 이름 약식 표시 + 모음 플래그

```sql
SELECT last_name, first_name,
       last_name || ', '
         || REGEXP_SUBSTR(first_name, '^[A-Za-z]') || '.'      AS abbrev_name,
       REGEXP_REPLACE(last_name, '[aeiou]', '*', 1, 0, 'i')    AS masked_name,
       REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')              AS vowel_count,
       CASE WHEN REGEXP_COUNT(last_name, '[aeiou]', 1, 'i') >= 3
            THEN '★ 모음 많음' ELSE ''
       END                                                     AS flag
FROM   employees
ORDER BY vowel_count DESC, last_name
FETCH FIRST 15 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME      FIRST  ABBREV_NAME       MASKED_NAME    VOWELS  FLAG
-------------  -----  ----------------  -------------  ------  ----------
Mikkilineni    Irene  Mikkilineni, I.   M*kk*l*n*n*        4  ★ 모음 많음
Livingston     Jack   Livingston, J.    L*v*ngst*n         3  ★ 모음 많음
Higgins        Shelley Higgins, S.     H*gg*ns            3  ★ 모음 많음
King           Steven King, S.         K*ng               1
```

키포인트: `REGEXP_SUBSTR`(이니셜) + `REGEXP_REPLACE`(마스킹) + `REGEXP_COUNT`(집계) + `CASE WHEN`을 하나의 SELECT에 통합.
