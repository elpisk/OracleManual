# Oracle Database 19c: SQL Workshop
## Appendix I — 정규 표현식 지원 (Regular Expression Support)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- 정규 표현식의 개념과 Oracle 지원 함수를 설명한다
- REGEXP_LIKE로 패턴에 일치하는 행을 필터링한다
- REGEXP_REPLACE로 패턴에 일치하는 문자열을 교체한다
- REGEXP_INSTR로 패턴의 위치를 반환한다
- REGEXP_SUBSTR로 패턴에 일치하는 부분 문자열을 추출한다
- REGEXP_COUNT로 패턴 일치 횟수를 계산한다
- 주요 정규 표현식 메타문자를 활용한다
- 서브표현식(Subexpression)을 사용한다
- CHECK 제약 조건에 정규 표현식을 적용한다

---

## 1. 정규 표현식이란?

정규 표현식(Regular Expression)은 **문자열 패턴을 정의하는 형식 언어**이다.

Oracle 10g부터 POSIX 표준 기반 정규 표현식을 SQL/PL/SQL에서 지원한다.

```
기존 LIKE:  WHERE phone LIKE '010-%'         (패턴이 단순)
정규 표현식: WHERE REGEXP_LIKE(phone, '^010-[0-9]{4}-[0-9]{4}$')  (강력한 패턴)
```

---

## 2. 주요 메타문자 (Metacharacters)

| 메타문자 | 의미 | 예제 |
|---------|------|------|
| `.` | 임의의 문자 하나 | `a.c` → abc, aXc |
| `*` | 앞 패턴 0회 이상 반복 | `a*` → "", a, aa, aaa |
| `+` | 앞 패턴 1회 이상 반복 | `a+` → a, aa, aaa |
| `?` | 앞 패턴 0회 또는 1회 | `colou?r` → color, colour |
| `^` | 문자열 시작 | `^Oracle` → Oracle로 시작 |
| `$` | 문자열 끝 | `end$` → end로 끝 |
| `|` | 또는(OR) | `cat|dog` → cat 또는 dog |
| `()` | 그룹화 (서브표현식) | `(ab)+` → ab, abab |
| `[]` | 문자 클래스 | `[aeiou]` → a, e, i, o, u 중 하나 |
| `[^]` | 부정 문자 클래스 | `[^0-9]` → 숫자가 아닌 문자 |
| `{n}` | 정확히 n회 반복 | `[0-9]{4}` → 숫자 정확히 4자리 |
| `{n,}` | n회 이상 반복 | `[0-9]{2,}` → 숫자 2자리 이상 |
| `{n,m}` | n회 이상 m회 이하 반복 | `[a-z]{2,5}` → 소문자 2~5자 |
| `\` | 이스케이프 | `\.` → 마침표 문자 자체 |

### 문자 클래스 단축 표현 (POSIX)

| 표현 | 의미 | 동등한 패턴 |
|------|------|------------|
| `[:alpha:]` | 알파벳 문자 | `[a-zA-Z]` |
| `[:digit:]` | 숫자 | `[0-9]` |
| `[:alnum:]` | 알파벳 + 숫자 | `[a-zA-Z0-9]` |
| `[:upper:]` | 대문자 | `[A-Z]` |
| `[:lower:]` | 소문자 | `[a-z]` |
| `[:space:]` | 공백 문자 | 스페이스, 탭, 개행 |
| `[:punct:]` | 구두점 | `!`, `.`, `,` 등 |

---

## 3. REGEXP_LIKE

`WHERE` 절에서 패턴 일치 여부를 검사한다. SQL `LIKE`의 강력한 대체 함수.

```
REGEXP_LIKE(source_string, pattern [, match_parameter])
```

**match_parameter:**
- `'i'`: 대소문자 구분 없음 (case-insensitive)
- `'c'`: 대소문자 구분 (기본값, case-sensitive)
- `'n'`: `.`이 개행 문자도 일치
- `'m'`: `^`/`$`가 각 줄의 시작/끝에 적용

```sql
-- first_name이 정확히 알파벳 문자만으로 구성된 행
SELECT first_name, last_name
FROM   employees
WHERE  REGEXP_LIKE(first_name, '^[[:alpha:]]+$');

-- 이메일에 숫자가 포함된 직원
SELECT first_name, email
FROM   employees
WHERE  REGEXP_LIKE(email, '[[:digit:]]');

-- 성이 대문자로 시작하고 나머지는 소문자인 직원
SELECT last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '^[[:upper:]][[:lower:]]+$');

-- 전화번호 형식: 515.xxx.xxxx
SELECT first_name, phone_number
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '515\.[0-9]{3}\.[0-9]{4}');

-- 이메일 유효성 검사
SELECT first_name, email
FROM   employees
WHERE  REGEXP_LIKE(email, '^[[:alnum:]._-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}$', 'i');
```

---

## 4. REGEXP_REPLACE

패턴에 일치하는 부분 문자열을 다른 문자열로 교체한다.

```
REGEXP_REPLACE(source_string, pattern [, replace_string [, position [, occurrence [, match_parameter]]]])
```

| 인수 | 설명 |
|------|------|
| source_string | 원본 문자열 |
| pattern | 검색할 정규 표현식 |
| replace_string | 대체 문자열 (생략 시 삭제) |
| position | 검색 시작 위치 (기본: 1) |
| occurrence | 교체할 발생 번호 (0=전체, 기본: 0) |
| match_parameter | 일치 옵션 |

```sql
-- 전화번호 형식 표준화: 숫자만 남기기
SELECT phone_number,
       REGEXP_REPLACE(phone_number, '[^[:digit:]]', '') AS digits_only
FROM   employees;

-- 연속된 공백을 하나로 줄이기
SELECT REGEXP_REPLACE('Hello    World   Again', ' {2,}', ' ') AS clean_text
FROM   dual;
-- 결과: 'Hello World Again'

-- 날짜 형식 변환: MM/DD/YYYY → YYYY-MM-DD
SELECT REGEXP_REPLACE('12/25/2024', '([0-9]{2})/([0-9]{2})/([0-9]{4})',
                       '\3-\1-\2') AS new_date
FROM   dual;
-- 결과: 2024-12-25

-- 이름의 첫 글자만 남기고 나머지 대문자 제거
SELECT last_name,
       REGEXP_REPLACE(last_name, '([[:upper:]])', ' \1', 2) AS formatted
FROM   employees;
```

---

## 5. REGEXP_INSTR

패턴이 처음 일치하는 위치(Position)를 반환한다.

```
REGEXP_INSTR(source_string, pattern [, position [, occurrence [, return_option [, match_parameter]]]])
```

| 인수 | 설명 |
|------|------|
| position | 검색 시작 위치 (기본: 1) |
| occurrence | 몇 번째 발생을 찾을지 (기본: 1) |
| return_option | 0=일치 시작 위치, 1=일치 끝 다음 위치 |

```sql
-- 문자열에서 숫자가 처음 나타나는 위치
SELECT REGEXP_INSTR('Hello2024World', '[[:digit:]]') AS pos
FROM   dual;
-- 결과: 6

-- 두 번째 숫자 그룹이 나타나는 위치
SELECT REGEXP_INSTR('abc123def456', '[[:digit:]]+', 1, 2) AS second_num_pos
FROM   dual;
-- 결과: 10

-- email에서 @ 기호 위치
SELECT email,
       REGEXP_INSTR(email, '@') AS at_pos
FROM   employees;

-- 전화번호에서 두 번째 점(.) 위치
SELECT phone_number,
       REGEXP_INSTR(phone_number, '\.', 1, 2) AS second_dot
FROM   employees WHERE ROWNUM <= 5;
```

---

## 6. REGEXP_SUBSTR

패턴에 일치하는 부분 문자열을 추출한다.

```
REGEXP_SUBSTR(source_string, pattern [, position [, occurrence [, match_parameter [, subexpression]]]])
```

```sql
-- 전화번호에서 지역번호(첫 번째 숫자 그룹) 추출
SELECT phone_number,
       REGEXP_SUBSTR(phone_number, '[[:digit:]]+') AS area_code
FROM   employees WHERE ROWNUM <= 5;

-- URL에서 도메인 이름 추출
SELECT REGEXP_SUBSTR('https://www.oracle.com/database', 
                     '//([[:alnum:].-]+)', 1, 1, 'i', 1) AS domain
FROM   dual;
-- 결과: www.oracle.com

-- 쉼표 구분 문자열에서 두 번째 값 추출
SELECT REGEXP_SUBSTR('Apple,Banana,Cherry', '[^,]+', 1, 2) AS second_item
FROM   dual;
-- 결과: Banana

-- 이메일에서 @ 앞부분(로컬 파트) 추출
SELECT email,
       REGEXP_SUBSTR(email, '^[^@]+') AS local_part
FROM   employees;

-- 이메일에서 도메인 파트 추출
SELECT email,
       REGEXP_SUBSTR(email, '[^@]+$') AS domain_part
FROM   employees;
```

---

## 7. REGEXP_COUNT

패턴이 문자열에서 발생하는 횟수를 반환한다. (Oracle 11g 이상)

```
REGEXP_COUNT(source_string, pattern [, position [, match_parameter]])
```

```sql
-- 문자열에서 숫자 개수 세기
SELECT REGEXP_COUNT('abc123def456ghi', '[[:digit:]]') AS digit_count
FROM   dual;
-- 결과: 6

-- 이메일에서 점(.) 개수
SELECT email,
       REGEXP_COUNT(email, '\.') AS dot_count
FROM   employees;

-- 전화번호에서 숫자 그룹(세그먼트) 개수
SELECT phone_number,
       REGEXP_COUNT(phone_number, '[[:digit:]]+') AS num_groups
FROM   employees WHERE ROWNUM <= 5;

-- 문자열에서 특정 단어 출현 횟수
SELECT REGEXP_COUNT(
    'The quick brown fox jumps over the lazy dog. The dog slept.',
    'the', 1, 'i') AS the_count
FROM   dual;
-- 결과: 3 (대소문자 무시)
```

---

## 8. 서브표현식 (Subexpression)

괄호 `()`로 정의된 그룹. 역참조(Back Reference)와 추출에 사용.

```sql
-- 서브표현식으로 날짜 재구성 (MM/DD/YYYY → YYYY-MM-DD)
SELECT REGEXP_REPLACE(
    '25/12/2024',
    '([0-9]{2})/([0-9]{2})/([0-9]{4})',
    '\3-\2-\1') AS iso_date
FROM dual;
-- 결과: 2024-12-25

-- 서브표현식 1번 그룹만 추출 (REGEXP_SUBSTR의 6번째 인수)
SELECT REGEXP_SUBSTR('Phone: 010-1234-5678', '([0-9]{3})-([0-9]{4})-([0-9]{4})', 1, 1, NULL, 2) AS middle_num
FROM dual;
-- 결과: 1234 (2번째 서브표현식)

-- 이름에서 성(last_name)의 첫 두 글자 추출
SELECT last_name,
       REGEXP_SUBSTR(last_name, '^(.{2})', 1, 1, NULL, 1) AS first_two
FROM   employees WHERE ROWNUM <= 5;
```

---

## 9. CHECK 제약 조건에서 정규 표현식 활용

```sql
-- 전화번호 형식 검증 CHECK 제약
CREATE TABLE contacts (
    id         NUMBER PRIMARY KEY,
    name       VARCHAR2(100),
    phone      VARCHAR2(20)
        CONSTRAINT chk_phone
        CHECK (REGEXP_LIKE(phone, '^\d{3}-\d{4}-\d{4}$')),
    email      VARCHAR2(200)
        CONSTRAINT chk_email
        CHECK (REGEXP_LIKE(email, '^[[:alnum:]._-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}$', 'i')),
    zipcode    VARCHAR2(10)
        CONSTRAINT chk_zip
        CHECK (REGEXP_LIKE(zipcode, '^[0-9]{5}(-[0-9]{4})?$'))
);

-- 올바른 데이터 INSERT (성공)
INSERT INTO contacts VALUES (1, 'Kim', '010-1234-5678', 'kim@example.com', '12345');

-- 잘못된 전화번호 (실패 — CHECK 제약 위반)
INSERT INTO contacts VALUES (2, 'Lee', '010-123-456', 'lee@example.com', '12345');
-- ORA-02290: check constraint (HR.CHK_PHONE) violated
```

---

## 10. 실용 패턴 모음

```sql
-- 한국 휴대폰 번호: 010-XXXX-XXXX
REGEXP_LIKE(col, '^010-[0-9]{4}-[0-9]{4}$')

-- 이메일 주소 유효성
REGEXP_LIKE(col, '^[[:alnum:]._%-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}$', 'i')

-- 숫자만으로 구성된 문자열
REGEXP_LIKE(col, '^[[:digit:]]+$')

-- 알파벳 + 숫자 조합 (특수문자 없음)
REGEXP_LIKE(col, '^[[:alnum:]]+$')

-- 소문자로 시작하고 길이 3~20자
REGEXP_LIKE(col, '^[[:lower:]][[:alnum:]_]{2,19}$')

-- 날짜 형식: YYYY-MM-DD
REGEXP_LIKE(col, '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$')

-- 신용카드 번호: XXXX-XXXX-XXXX-XXXX
REGEXP_LIKE(col, '^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}$')

-- HTML 태그 제거
REGEXP_REPLACE(col, '<[^>]+>', '')

-- 연속 공백을 단일 공백으로
REGEXP_REPLACE(col, '[[:space:]]+', ' ')

-- 숫자 이외 문자 제거
REGEXP_REPLACE(col, '[^[:digit:]]', '')
```

---

## 11. 단원 요약

| 함수 | 용도 | 반환값 |
|------|------|--------|
| `REGEXP_LIKE` | 패턴 일치 여부 확인 (WHERE 절) | TRUE/FALSE |
| `REGEXP_REPLACE` | 패턴 일치 부분을 다른 문자열로 교체 | 교체된 문자열 |
| `REGEXP_INSTR` | 패턴 일치 위치 반환 | 숫자(위치) |
| `REGEXP_SUBSTR` | 패턴 일치 부분 문자열 추출 | 문자열 |
| `REGEXP_COUNT` | 패턴 발생 횟수 계산 | 숫자(횟수) |

**메타문자 핵심:**
- `^` `$`: 시작/끝
- `[]`: 문자 클래스
- `{n,m}`: 반복 횟수
- `()`: 서브표현식 (그룹화 + 역참조)
- `[:alpha:]` `[:digit:]` 등: POSIX 문자 클래스
