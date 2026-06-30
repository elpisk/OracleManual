# Oracle Database 19c: SQL Workshop
## Chapter 25 — 정규표현식 (Regular Expression Support)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- 정규표현식의 기본 개념과 메타문자를 이해한다
- `REGEXP_LIKE`를 사용하여 패턴 기반 행 필터링을 수행한다
- `REGEXP_INSTR`로 문자열 내 패턴 위치를 찾는다
- `REGEXP_SUBSTR`로 문자열에서 패턴에 일치하는 부분을 추출한다
- `REGEXP_REPLACE`로 패턴에 일치하는 문자열을 치환한다
- `REGEXP_COUNT`로 패턴 일치 횟수를 집계한다
- 일치 파라미터(`match_param`)를 활용하여 대소문자 무시, 줄바꿈 처리 등을 제어한다

---

## 1. 정규표현식 개요

정규표현식(Regular Expression)은 문자열 패턴을 정의하는 강력한 언어입니다. Oracle 10g부터 POSIX 표준 정규표현식을 지원하며, 기존 `LIKE` 연산자보다 훨씬 복잡한 패턴 검색이 가능합니다.

### 1-1. LIKE vs 정규표현식 비교

| 기능 | LIKE | 정규표현식 |
|------|------|-----------|
| 임의의 한 문자 | `_` | `.` |
| 임의의 0개 이상 | `%` | `.*` |
| 문자 집합 | 불가 | `[abc]`, `[a-z]` |
| 반복 횟수 지정 | 불가 | `{n}`, `{n,m}` |
| 선택(OR) | 불가 | `\|` |
| 앵커(시작/끝) | 불가 | `^`, `$` |

### 1-2. 주요 메타문자

| 메타문자 | 의미 | 예 |
|----------|------|-----|
| `.` | 임의의 한 문자 | `a.c` → "abc", "a1c" |
| `*` | 앞 문자 0회 이상 반복 | `ab*c` → "ac", "abc", "abbc" |
| `+` | 앞 문자 1회 이상 반복 | `ab+c` → "abc", "abbc" |
| `?` | 앞 문자 0회 또는 1회 | `colou?r` → "color", "colour" |
| `^` | 문자열 시작 | `^A` → "A"로 시작 |
| `$` | 문자열 끝 | `n$` → "n"으로 끝 |
| `[...]` | 문자 집합 | `[aeiou]` → 모음 한 글자 |
| `[^...]` | 부정 문자 집합 | `[^0-9]` → 숫자 아닌 문자 |
| `{n}` | 정확히 n회 반복 | `[0-9]{3}` → 숫자 3자리 |
| `{n,m}` | n~m회 반복 | `[0-9]{2,4}` → 숫자 2~4자리 |
| `\|` | OR (선택) | `cat\|dog` → "cat" 또는 "dog" |
| `()` | 그룹화 | `(ab)+` → "ab", "abab" |
| `\d` | 숫자 `[0-9]` | `\d{4}` → 4자리 숫자 |
| `\w` | 단어 문자 `[a-zA-Z0-9_]` | `\w+` → 단어 |
| `\s` | 공백 문자 | `\s+` → 공백 1개 이상 |

### 1-3. POSIX 문자 클래스

| 클래스 | 의미 |
|--------|------|
| `[:alpha:]` | 알파벳 문자 |
| `[:digit:]` | 숫자 |
| `[:alnum:]` | 알파벳 + 숫자 |
| `[:upper:]` | 대문자 |
| `[:lower:]` | 소문자 |
| `[:space:]` | 공백 문자 |
| `[:punct:]` | 구두점 |

---

## 2. REGEXP_LIKE

`REGEXP_LIKE`는 `LIKE` 연산자의 정규표현식 버전입니다. `WHERE` 절에서 패턴에 일치하는 행을 필터링합니다.

### 2-1. 구문

```sql
REGEXP_LIKE(source_string, pattern [, match_param])
```

| 파라미터 | 설명 |
|----------|------|
| `source_string` | 검색 대상 문자열 또는 컬럼 |
| `pattern` | 정규표현식 패턴 |
| `match_param` | 일치 옵션 (`i`, `c`, `n`, `m`, `x`) |

**match_param 옵션:**
- `i` : 대소문자 무시 (case-insensitive)
- `c` : 대소문자 구분 (기본값)
- `n` : `.`이 줄바꿈 문자도 일치
- `m` : 다중 행 모드 (`^`, `$`가 각 행의 시작/끝에 적용)
- `x` : 공백과 주석 허용 (가독성 향상)

### 2-2. 예제 1 — 이름이 모음으로 시작하는 직원

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

### 2-3. 예제 2 — 이메일이 특정 패턴인 직원

```sql
SELECT employee_id, last_name, email
FROM   employees
WHERE  REGEXP_LIKE(email, '^[A-Z]{4,6}$')
ORDER BY email;
```

**결과 예시:**
```
EMPLOYEE_ID  LAST_NAME  EMAIL
-----------  ---------  ------
115          Khoo       DKHOO
116          Baida      GBAIDA
117          Tobias     STOBIAS
```

### 2-4. 예제 3 — 전화번호가 특정 형식인 직원

```sql
SELECT employee_id, last_name, phone_number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id;
```

---

## 3. REGEXP_INSTR

`REGEXP_INSTR`는 문자열에서 정규표현식 패턴이 처음(또는 n번째) 나타나는 위치를 반환합니다. 일치하지 않으면 0을 반환합니다.

### 3-1. 구문

```sql
REGEXP_INSTR(source_string, pattern
             [, position [, occurrence [, return_opt
             [, match_param [, subexpr]]]]])
```

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `position` | 1 | 탐색 시작 위치 |
| `occurrence` | 1 | 몇 번째 일치 |
| `return_opt` | 0 | 0=시작위치, 1=끝위치+1 |
| `match_param` | — | 일치 옵션 |
| `subexpr` | 0 | 그룹 번호 (0=전체) |

### 3-2. 예제 1 — 이메일에서 '@' 위치 찾기

```sql
SELECT last_name,
       email,
       REGEXP_INSTR(email || '@company.com', '@') AS at_pos
FROM   employees
ORDER BY employee_id
FETCH FIRST 5 ROWS ONLY;
```

### 3-3. 예제 2 — 전화번호에서 두 번째 '.' 위치

```sql
SELECT last_name,
       phone_number,
       REGEXP_INSTR(phone_number, '\.', 1, 2) AS second_dot_pos
FROM   employees
WHERE  phone_number LIKE '%.%.%'
ORDER BY employee_id
FETCH FIRST 8 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  PHONE_NUMBER   SECOND_DOT_POS
---------  -------------  --------------
King       515.123.4567                8
Kochhar    515.123.4568                8
De Haan    515.123.4569                8
```

---

## 4. REGEXP_SUBSTR

`REGEXP_SUBSTR`는 문자열에서 정규표현식 패턴에 일치하는 부분 문자열을 추출합니다. 일치하지 않으면 NULL을 반환합니다.

### 4-1. 구문

```sql
REGEXP_SUBSTR(source_string, pattern
              [, position [, occurrence
              [, match_param [, subexpr]]]])
```

### 4-2. 예제 1 — 이름에서 첫 번째 단어 추출

```sql
SELECT last_name,
       REGEXP_SUBSTR(last_name, '[A-Za-z]+') AS first_word
FROM   employees
ORDER BY employee_id
FETCH FIRST 5 ROWS ONLY;
```

### 4-3. 예제 2 — 전화번호에서 지역번호(첫 번째 숫자 그룹) 추출

```sql
SELECT last_name,
       phone_number,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 1) AS area_code,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 2) AS exchange,
       REGEXP_SUBSTR(phone_number, '[0-9]+', 1, 3) AS number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id
FETCH FIRST 5 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  PHONE_NUMBER   AREA_CODE  EXCHANGE  NUMBER
---------  -------------  ---------  --------  ------
King       515.123.4567   515        123       4567
Kochhar    515.123.4568   515        123       4568
De Haan    515.123.4569   515        123       4569
```

### 4-4. 예제 3 — 그룹 캡처로 성씨 이니셜 추출

```sql
SELECT last_name,
       REGEXP_SUBSTR(last_name, '(^[A-Z])', 1, 1, 'i', 1) AS initial
FROM   employees
ORDER BY last_name
FETCH FIRST 5 ROWS ONLY;
```

---

## 5. REGEXP_REPLACE

`REGEXP_REPLACE`는 문자열에서 정규표현식 패턴에 일치하는 부분을 지정한 문자열로 치환합니다.

### 5-1. 구문

```sql
REGEXP_REPLACE(source_string, pattern
               [, replace_string [, position
               [, occurrence [, match_param]]]])
```

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `replace_string` | NULL | 치환할 문자열 (역참조: `\1`, `\2` 등) |
| `position` | 1 | 탐색 시작 위치 |
| `occurrence` | 0 | 0=모든 일치, n=n번째만 |

### 5-2. 예제 1 — 전화번호 형식 변환 (점 → 하이픈)

```sql
SELECT last_name,
       phone_number,
       REGEXP_REPLACE(phone_number, '\.', '-') AS formatted
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$')
ORDER BY employee_id
FETCH FIRST 5 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME  PHONE_NUMBER   FORMATTED
---------  -------------  -------------
King       515.123.4567   515-123-4567
Kochhar    515.123.4568   515-123-4568
```

### 5-3. 예제 2 — 역참조로 이름 순서 변경 (성 이름 → 이름 성)

```sql
SELECT last_name || ', ' || first_name AS original,
       REGEXP_REPLACE(
           last_name || ' ' || first_name,
           '^(\S+)\s+(\S+)$',
           '\2 \1'
       ) AS swapped
FROM   employees
ORDER BY employee_id
FETCH FIRST 5 ROWS ONLY;
```

**결과 예시:**
```
ORIGINAL          SWAPPED
----------------  ----------------
King, Steven      Steven King
Kochhar, Neena    Neena Kochhar
De Haan, Lex      Lex De Haan
```

### 5-4. 예제 3 — 연속 공백을 단일 공백으로

```sql
SELECT REGEXP_REPLACE('  Oracle   Database  19c  ', '\s+', ' ') AS cleaned
FROM   dual;
```

**결과 예시:**
```
CLEANED
-------
 Oracle Database 19c
```

---

## 6. REGEXP_COUNT

`REGEXP_COUNT`는 문자열에서 정규표현식 패턴이 일치하는 횟수를 반환합니다. Oracle 11g에서 추가된 함수입니다.

### 6-1. 구문

```sql
REGEXP_COUNT(source_string, pattern [, position [, match_param]])
```

### 6-2. 예제 1 — 이름에서 모음 개수 세기

```sql
SELECT last_name,
       REGEXP_COUNT(last_name, '[AEIOU]', 1, 'i') AS vowel_count
FROM   employees
ORDER BY vowel_count DESC, last_name
FETCH FIRST 10 ROWS ONLY;
```

**결과 예시:**
```
LAST_NAME      VOWEL_COUNT
-------------  -----------
Higgins                  3
Livingston               3
Mikkilineni              4
```

### 6-3. 예제 2 — 전화번호에서 숫자 그룹 개수 확인

```sql
SELECT last_name,
       phone_number,
       REGEXP_COUNT(phone_number, '[0-9]+') AS digit_groups
FROM   employees
ORDER BY digit_groups DESC, employee_id
FETCH FIRST 8 ROWS ONLY;
```

### 6-4. 예제 3 — 특정 패턴 포함 직원 수 집계

```sql
SELECT REGEXP_COUNT(last_name, 'a', 1, 'i') AS a_count,
       COUNT(*)                              AS emp_count
FROM   employees
GROUP BY REGEXP_COUNT(last_name, 'a', 1, 'i')
ORDER BY a_count;
```

---

## 7. 정규표현식 함수 비교표

| 함수 | 반환값 | 주요 사용처 |
|------|--------|------------|
| `REGEXP_LIKE` | TRUE/FALSE | WHERE 절 패턴 필터링 |
| `REGEXP_INSTR` | 숫자(위치) | 패턴의 위치 찾기 |
| `REGEXP_SUBSTR` | 문자열 | 패턴에 맞는 부분 추출 |
| `REGEXP_REPLACE` | 문자열 | 패턴 치환·변환 |
| `REGEXP_COUNT` | 숫자(횟수) | 패턴 출현 횟수 집계 |

---

## 8. 종합 예제 — 데이터 정제 시나리오

HR 스키마 직원 데이터에서 이메일 유효성 검사 및 형식 변환을 수행합니다.

```sql
-- 이메일 형식 검증 및 표준화
SELECT employee_id,
       last_name,
       email,
       -- 알파벳만으로 구성된 이메일 (현 HR 스키마 형식)
       CASE WHEN REGEXP_LIKE(email, '^[A-Z]+$')
            THEN email || '@oracle.com'
            ELSE 'INVALID'
       END                                              AS full_email,
       -- 이메일 길이 분류
       CASE WHEN REGEXP_COUNT(email, '[A-Z]') <= 4
            THEN '짧음'
            WHEN REGEXP_COUNT(email, '[A-Z]') <= 6
            THEN '보통'
            ELSE '김'
       END                                              AS email_len,
       -- 이름 이니셜
       REGEXP_SUBSTR(first_name, '^[A-Za-z]') || '.'  AS f_initial
FROM   employees
ORDER BY email_len, employee_id
FETCH FIRST 10 ROWS ONLY;
```
