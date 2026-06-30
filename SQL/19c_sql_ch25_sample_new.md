# Oracle Database 19c: SQL Workshop
## Chapter 25 — 정규표현식 | SQL 실습 문제

---

> **참고:** 이 실습은 HR 스키마가 설치된 Oracle 19c 환경에서 수행하세요.

---

## Group 1: REGEXP_LIKE — 패턴 필터링

**[1번]** `employees` 테이블에서 `first_name`이 모음(A, E, I, O, U)으로 시작하는 직원을 조회하시오. (`employee_id`, `first_name`, `last_name`)

```sql
SELECT employee_id, first_name, last_name
FROM   employees
WHERE  REGEXP_LIKE(first_name, '^[AEIOU]', 'i')
ORDER BY first_name;
```

---

**[2번]** `employees` 테이블에서 `last_name`에 연속된 같은 문자(예: 'nn', 'ss')가 포함된 직원을 조회하시오.

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '(.)\1', 'i')
ORDER BY last_name;
```

---

**[3번]** `employees` 테이블에서 `phone_number`가 `NNN.NNN.NNNN` 형식(점으로 구분된 숫자)인 직원을 조회하시오.

```sql
SELECT employee_id, last_name, phone_number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id;
```

---

**[4번]** `employees` 테이블에서 `email`이 정확히 4~6자의 대문자 알파벳으로만 구성된 직원을 조회하시오.

```sql
SELECT employee_id, last_name, email
FROM   employees
WHERE  REGEXP_LIKE(email, '^[A-Z]{4,6}$')
ORDER BY LENGTH(email), email;
```

---

**[5번]** `employees` 테이블에서 `last_name`이 자음으로 시작하고, 두 번째 글자가 모음인 직원을 조회하시오.

```sql
SELECT employee_id, last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '^[^AEIOU][AEIOU]', 'i')
ORDER BY last_name;
```

---

## Group 2: REGEXP_INSTR — 위치 찾기

**[6번]** `employees` 테이블에서 `phone_number`에서 두 번째 숫자 그룹(`[0-9]+`)의 시작 위치를 조회하시오. 점 구분 형식인 직원만 대상으로 합니다.

```sql
SELECT last_name,
       phone_number,
       REGEXP_INSTR(phone_number, '[0-9]+', 1, 1) AS first_pos,
       REGEXP_INSTR(phone_number, '[0-9]+', 1, 2) AS second_pos,
       REGEXP_INSTR(phone_number, '[0-9]+', 1, 3) AS third_pos
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id
FETCH FIRST 8 ROWS ONLY;
```

---

**[7번]** `employees` 테이블에서 `last_name`에서 모음('a', 'e', 'i', 'o', 'u')이 처음 나타나는 위치를 조회하시오. 모음이 없으면 0 표시.

```sql
SELECT last_name,
       REGEXP_INSTR(last_name, '[aeiou]', 1, 1, 0, 'i') AS first_vowel_pos
FROM   employees
ORDER BY first_vowel_pos, last_name
FETCH FIRST 10 ROWS ONLY;
```

---

**[8번]** `employees` 테이블에서 `last_name`에서 두 번째 모음이 나타나는 위치를 조회하시오. 두 번째 모음이 없는 경우(0) 제외.

```sql
SELECT last_name,
       REGEXP_INSTR(last_name, '[aeiou]', 1, 2, 0, 'i') AS second_vowel_pos
FROM   employees
WHERE  REGEXP_INSTR(last_name, '[aeiou]', 1, 2, 0, 'i') > 0
ORDER BY second_vowel_pos DESC, last_name
FETCH FIRST 10 ROWS ONLY;
```

---

**[9번]** `employees` 테이블에서 `first_name`과 `last_name`을 연결한 전체 이름에서 공백(' ')의 위치를 조회하시오.

```sql
SELECT first_name || ' ' || last_name AS full_name,
       REGEXP_INSTR(first_name || ' ' || last_name, '\s') AS space_pos
FROM   employees
ORDER BY employee_id
FETCH FIRST 8 ROWS ONLY;
```

---

## Group 3: REGEXP_SUBSTR — 부분 추출

**[10번]** `employees` 테이블에서 `phone_number`를 지역번호, 국번, 번호로 분리하여 조회하시오. 점 구분 형식만 대상.

```sql
SELECT last_name,
       phone_number,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 1) AS area_code,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 2) AS exchange,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 3) AS number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id
FETCH FIRST 8 ROWS ONLY;
```

---

**[11번]** `employees` 테이블에서 `first_name`의 첫 글자(이니셜)를 추출하시오.

```sql
SELECT first_name,
       last_name,
       REGEXP_SUBSTR(first_name, '^[A-Za-z]') || '.' AS initial
FROM   employees
ORDER BY last_name
FETCH FIRST 10 ROWS ONLY;
```

---

**[12번]** `employees` 테이블에서 `last_name`의 마지막 글자를 추출하시오.

```sql
SELECT last_name,
       REGEXP_SUBSTR(last_name, '[A-Za-z]$') AS last_char
FROM   employees
ORDER BY last_char, last_name
FETCH FIRST 10 ROWS ONLY;
```

---

**[13번]** `employees` 테이블에서 `last_name`에서 두 번째 모음 문자를 추출하시오. 두 번째 모음이 없으면 NULL 표시.

```sql
SELECT last_name,
       REGEXP_SUBSTR(last_name, '[aeiou]', 1, 2, 'i') AS second_vowel
FROM   employees
ORDER BY second_vowel NULLS LAST, last_name
FETCH FIRST 10 ROWS ONLY;
```

---

**[14번]** `employees` 테이블에서 `job_id`에서 언더스코어(`_`) 앞 부분(직군 코드)을 추출하시오. 예) `IT_PROG` → `IT`

```sql
SELECT job_id,
       REGEXP_SUBSTR(job_id, '^[A-Z]+') AS dept_code,
       REGEXP_SUBSTR(job_id, '[A-Z]+$') AS role_code
FROM   employees
GROUP BY job_id
ORDER BY job_id;
```

---

## Group 4: REGEXP_REPLACE — 패턴 치환

**[15번]** `employees` 테이블에서 `phone_number`의 점(`.`)을 하이픈(`-`)으로 변환하여 조회하시오. 점 구분 형식만 대상.

```sql
SELECT last_name,
       phone_number,
       REGEXP_REPLACE(phone_number, '\.', '-') AS formatted
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id
FETCH FIRST 8 ROWS ONLY;
```

---

**[16번]** `employees` 테이블에서 `last_name`과 `first_name`을 연결한 전체 이름을 `이름 성` 순서로 바꾸어 조회하시오. (역참조 활용)

```sql
SELECT last_name || ' ' || first_name AS original,
       REGEXP_REPLACE(
           last_name || ' ' || first_name,
           '^(\S+)\s+(\S+)$',
           '\2 \1'
       ) AS swapped
FROM   employees
ORDER BY employee_id
FETCH FIRST 8 ROWS ONLY;
```

---

**[17번]** `employees` 테이블에서 `phone_number`를 `(NNN) NNN-NNNN` 형식으로 변환하시오. (점 구분 형식만)

```sql
SELECT phone_number,
       REGEXP_REPLACE(
           phone_number,
           '^(\d{3})\.(\d{3})\.(\d{4})$',
           '(\1) \2-\3'
       ) AS new_format
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id
FETCH FIRST 8 ROWS ONLY;
```

---

**[18번]** `employees` 테이블에서 `last_name`의 모든 모음을 `*`로 치환하여 조회하시오.

```sql
SELECT last_name,
       REGEXP_REPLACE(last_name, '[aeiou]', '*', 1, 0, 'i') AS masked
FROM   employees
ORDER BY employee_id
FETCH FIRST 10 ROWS ONLY;
```

---

**[19번]** `employees` 테이블에서 `last_name`에서 연속된 같은 문자를 하나로 줄이시오. (예: 'Kochhar' → 'Kochar')

```sql
SELECT last_name,
       REGEXP_REPLACE(last_name, '(.)\1', '\1', 1, 0, 'i') AS dedup
FROM   employees
WHERE  REGEXP_LIKE(last_name, '(.)\1', 'i')
ORDER BY last_name;
```

---

## Group 5: REGEXP_COUNT — 횟수 집계

**[20번]** `employees` 테이블에서 `last_name`에 모음(a, e, i, o, u)이 몇 개 있는지 집계하여 많은 순으로 조회하시오.

```sql
SELECT last_name,
       REGEXP_COUNT(last_name, '[aeiou]', 1, 'i') AS vowel_count
FROM   employees
ORDER BY vowel_count DESC, last_name
FETCH FIRST 10 ROWS ONLY;
```

---

**[21번]** `employees` 테이블에서 모음 개수별 직원 수 분포를 조회하시오.

```sql
SELECT REGEXP_COUNT(last_name, '[aeiou]', 1, 'i') AS vowel_count,
       COUNT(*)                                    AS emp_count
FROM   employees
GROUP BY REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')
ORDER BY vowel_count;
```

---

**[22번]** `employees` 테이블에서 `phone_number`의 숫자 그룹 개수가 3개인 직원을 조회하시오. (점 구분 = 3개, 국제 번호 = 다를 수 있음)

```sql
SELECT employee_id, last_name, phone_number,
       REGEXP_COUNT(phone_number, '[0-9]+') AS digit_groups
FROM   employees
WHERE  REGEXP_COUNT(phone_number, '[0-9]+') = 3
ORDER BY employee_id
FETCH FIRST 8 ROWS ONLY;
```

---

**[23번]** `employees` 테이블에서 `last_name`의 자음 개수를 구하여 내림차순 상위 5명을 조회하시오. (자음 = 전체 글자 수 - 모음 수)

```sql
SELECT last_name,
       LENGTH(last_name)                                       AS total_len,
       REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')              AS vowels,
       LENGTH(last_name) - REGEXP_COUNT(last_name, '[aeiou]', 1, 'i') AS consonants
FROM   employees
ORDER BY consonants DESC, last_name
FETCH FIRST 5 ROWS ONLY;
```

---

## Group 6: 종합 실습

**[24번]** `employees` 테이블에서 이메일 유효성을 검사하고, 유효한 이메일(`^[A-Z]+$` 형식)에는 `@oracle.com`을 붙인 전체 이메일을 생성하시오.

```sql
SELECT employee_id,
       last_name,
       email,
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

---

**[25번]** `employees` 테이블에서 전화번호를 `(NNN) NNN-NNNN` 형식으로 변환하고, 지역번호·국번·번호를 각각 별도 컬럼으로도 분리하여 조회하시오.

```sql
SELECT last_name,
       phone_number,
       REGEXP_REPLACE(
           phone_number,
           '^(\d{3})\.(\d{3})\.(\d{4})$',
           '(\1) \2-\3'
       )                                          AS formatted,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 1) AS area_code,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 2) AS exchange,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 3) AS number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id
FETCH FIRST 8 ROWS ONLY;
```

---

**[26번]** `employees` 테이블에서 `last_name` 분석 보고서를 생성하시오. 다음 항목을 모두 포함: 이름 길이, 모음 수, 자음 수, 연속 중복 문자 여부, 이니셜.

```sql
SELECT employee_id,
       last_name,
       first_name,
       LENGTH(last_name)                                            AS name_len,
       REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')                  AS vowels,
       LENGTH(last_name)
         - REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')              AS consonants,
       CASE WHEN REGEXP_LIKE(last_name, '(.)\1', 'i')
            THEN 'Y'
            ELSE 'N'
       END                                                         AS has_double,
       REGEXP_SUBSTR(first_name, '^[A-Za-z]') || '.'
         || REGEXP_SUBSTR(last_name, '^[A-Za-z]') || '.'           AS initials
FROM   employees
ORDER BY vowels DESC, name_len DESC
FETCH FIRST 15 ROWS ONLY;
```

---

**[27번]** `employees` 테이블에서 `job_id` 값을 직군 코드와 역할 코드로 분리하고, 직군별 직원 수와 평균 급여를 집계하시오.

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

---

**[28번]** `employees` 테이블에서 이름(`first_name`)을 이니셜+점 형식으로 변환하고, `성, 이니셜` 형식의 표준 약식 이름을 생성하시오. 모음이 3개 이상인 last_name은 별표(`*`)로 표시하시오.

```sql
SELECT last_name,
       first_name,
       last_name || ', '
         || REGEXP_SUBSTR(first_name, '^[A-Za-z]') || '.'           AS abbrev_name,
       REGEXP_REPLACE(last_name, '[aeiou]', '*', 1, 0, 'i')         AS masked_name,
       REGEXP_COUNT(last_name, '[aeiou]', 1, 'i')                   AS vowel_count,
       CASE WHEN REGEXP_COUNT(last_name, '[aeiou]', 1, 'i') >= 3
            THEN '★ 모음 많음'
            ELSE ''
       END                                                          AS flag
FROM   employees
ORDER BY vowel_count DESC, last_name
FETCH FIRST 15 ROWS ONLY;
```

---
