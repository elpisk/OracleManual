# Oracle Database 19c: SQL Workshop
## Appendix I — 정규 표현식 지원 | 연습문제

---

> **문제 구성:** 하(기초) 20문제 + 중(응용) 20문제 + 상(심화) 10문제 = 총 50문제

---

## 하(기초) — 20문제

**[1번]** Oracle에서 정규 표현식을 지원하기 시작한 버전은?

① Oracle 8i  
② Oracle 9i  
③ Oracle 10g  
④ Oracle 11g

---

**[2번]** REGEXP_LIKE 함수의 주요 용도는?

① 패턴에 일치하는 문자열을 교체한다  
② WHERE 절에서 패턴 일치 여부를 검사한다  
③ 패턴 발생 위치를 반환한다  
④ 패턴에 일치하는 문자열을 추출한다

---

**[3번]** 정규 표현식에서 `.`(마침표) 메타문자의 의미는?

① 문자열의 끝  
② 임의의 문자 하나  
③ 0개 이상 반복  
④ 이스케이프 문자

---

**[4번]** 정규 표현식 `^Oracle`의 의미는?

① "Oracle"로 끝나는 문자열  
② "Oracle"이 포함된 문자열  
③ "Oracle"로 시작하는 문자열  
④ "Oracle"과 정확히 같은 문자열

---

**[5번]** 정규 표현식 `[[:digit:]]`이 일치하는 문자는?

① 알파벳 문자  
② 숫자 0~9  
③ 공백 문자  
④ 구두점 문자

---

**[6번]** 정규 표현식 `[aeiou]`의 의미는?

① 모음이 없는 문자  
② a, e, i, o, u 중 하나의 문자  
③ a부터 u 사이의 알파벳  
④ 문자열 "aeiou" 자체

---

**[7번]** 정규 표현식 `+` 수량자의 의미는?

① 앞 패턴 0회 이상 반복  
② 앞 패턴 1회 이상 반복  
③ 앞 패턴 0회 또는 1회  
④ 앞 패턴 정확히 1회

---

**[8번]** 정규 표현식 `{3,5}`의 의미는?

① 정확히 3회 또는 5회  
② 3회 이상  
③ 3회 이상 5회 이하  
④ 5회 이하

---

**[9번]** REGEXP_REPLACE의 주요 기능은?

① 패턴 일치 여부를 반환한다  
② 패턴에 일치하는 부분을 다른 문자열로 교체한다  
③ 패턴이 있는 위치 번호를 반환한다  
④ 패턴 발생 횟수를 반환한다

---

**[10번]** REGEXP_INSTR 함수의 반환값은?

① TRUE 또는 FALSE  
② 패턴에 일치하는 부분 문자열  
③ 패턴이 발생하는 위치(숫자)  
④ 패턴이 발생한 횟수

---

**[11번]** REGEXP_SUBSTR 함수의 역할은?

① 패턴에 일치하는 부분 문자열을 추출한다  
② 패턴 일치 횟수를 반환한다  
③ 패턴으로 문자열을 분리한다  
④ 패턴에 일치하는 행 번호를 반환한다

---

**[12번]** REGEXP_COUNT 함수는 몇 버전 이상에서 지원하는가?

① Oracle 9i  
② Oracle 10g  
③ Oracle 11g  
④ Oracle 12c

---

**[13번]** 정규 표현식에서 `$`의 의미는?

① 문자열의 시작  
② 숫자 문자  
③ 문자열의 끝  
④ 특수 문자

---

**[14번]** `[^0-9]`의 의미는?

① 0부터 9 사이의 숫자  
② 숫자가 아닌 문자  
③ 숫자 하나만  
④ 빈 문자열

---

**[15번]** REGEXP_LIKE에서 match_parameter `'i'`의 의미는?

① 대소문자를 구분한다  
② 대소문자를 구분하지 않는다  
③ `.`이 개행 문자도 일치한다  
④ `^`/`$`가 각 줄에 적용된다

---

**[16번]** 정규 표현식 `[[:alpha:]]`가 일치하는 문자는?

① 숫자  
② 알파벳(대문자+소문자)  
③ 알파벳+숫자  
④ 공백

---

**[17번]** 정규 표현식에서 `|`의 역할은?

① 문자 클래스 구분  
② OR 연산 (두 패턴 중 하나)  
③ 서브표현식 시작  
④ 이스케이프

---

**[18번]** 정규 표현식 `?` 수량자의 의미는?

① 1회 이상  
② 0회 이상  
③ 0회 또는 1회  
④ 정확히 1회

---

**[19번]** `REGEXP_REPLACE(col, '[^[:digit:]]', '')`의 결과는?

① 숫자를 모두 제거한다  
② 숫자가 아닌 모든 문자를 제거한다  
③ 첫 번째 비숫자 문자를 제거한다  
④ 모든 문자를 제거한다

---

**[20번]** CHECK 제약 조건에 정규 표현식을 사용하는 이유는?

① 성능을 향상시키기 위해  
② 복잡한 형식 검증 규칙을 데이터베이스 수준에서 적용하기 위해  
③ 인덱스를 더 효율적으로 만들기 위해  
④ NULL 값을 허용하기 위해

---

## 중(응용) — 20문제

---

**[21번]** 다음 SQL의 결과로 올바른 것은?

```sql
SELECT REGEXP_LIKE('Hello123', '^[[:alpha:]]+$') FROM dual;
```

① TRUE (알파벳만 있으므로)  
② FALSE (숫자가 포함되어 있으므로)  
③ 에러 발생  
④ NULL

---

**[22번]** 전화번호 형식 `010-XXXX-XXXX`를 검증하는 정규 표현식으로 올바른 것은?

① `^010-[0-9]-[0-9]$`  
② `^010-[0-9]{4}-[0-9]{4}$`  
③ `^010.[0-9].[0-9]$`  
④ `010-[0-9]{4}-[0-9]{4}`

---

**[23번]** 다음 SQL의 결과는?

```sql
SELECT REGEXP_REPLACE('Hello    World', ' {2,}', ' ') FROM dual;
```

① `Hello    World` (변경 없음)  
② `Hello World`  
③ `HelloWorld`  
④ `Hello  World`

---

**[24번]** 다음 SQL의 결과는?

```sql
SELECT REGEXP_INSTR('abc123def', '[[:digit:]]') FROM dual;
```

① 1  
② 4  
③ 7  
④ 0 (없음)

---

**[25번]** 다음 SQL의 결과는?

```sql
SELECT REGEXP_SUBSTR('Apple,Banana,Cherry', '[^,]+', 1, 2) FROM dual;
```

① Apple  
② Banana  
③ Cherry  
④ NULL

---

**[26번]** 다음 SQL의 결과는?

```sql
SELECT REGEXP_COUNT('aababab', 'ab') FROM dual;
```

① 1  
② 2  
③ 3  
④ 4

---

**[27번]** 서브표현식(괄호 그룹)의 역참조로 날짜를 변환하는 SQL로 올바른 것은?

MM/DD/YYYY 형식을 YYYY-MM-DD로 변환하시오.

① `REGEXP_REPLACE(col, '(.+)/(.+)/(.+)', '\3-\1-\2')`  
② `REGEXP_REPLACE(col, '([0-9]{2})/([0-9]{2})/([0-9]{4})', '\3-\1-\2')`  
③ `REGEXP_REPLACE(col, '([0-9]{2})/([0-9]{2})/([0-9]{4})', '\1-\2-\3')`  
④ `REGEXP_INSTR(col, '([0-9]{2})/([0-9]{2})/([0-9]{4})')`

---

**[28번]** employees 테이블에서 이름(first_name)이 모두 소문자로 구성된 직원을 조회하는 쿼리는?

① `WHERE REGEXP_LIKE(first_name, '[[:lower:]]')`  
② `WHERE REGEXP_LIKE(first_name, '^[[:lower:]]+$')`  
③ `WHERE REGEXP_LIKE(first_name, '[^[:upper:]]')`  
④ `WHERE REGEXP_LIKE(first_name, '[:lower:]+')`

---

**[29번]** `REGEXP_SUBSTR('010-1234-5678', '[0-9]+', 1, 2)`의 결과는?

① 010  
② 1234  
③ 5678  
④ NULL

---

**[30번]** 정규 표현식 `^[[:upper:]][[:lower:]]+$`가 일치하는 문자열은?

① `ORACLE` (전체 대문자)  
② `oracle` (전체 소문자)  
③ `Oracle` (첫 글자 대문자, 나머지 소문자)  
④ `OraclE` (첫/마지막 대문자)

---

**[31번]** 다음 중 이메일 주소 유효성 검사에 가장 적합한 패턴은?

① `REGEXP_LIKE(email, '@')`  
② `REGEXP_LIKE(email, '^[[:alnum:]._-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}$', 'i')`  
③ `email LIKE '%@%'`  
④ `REGEXP_LIKE(email, '.+@.+')`

---

**[32번]** `REGEXP_REPLACE('Phone: 010-1234-5678', '[^[:digit:]]', '')`의 결과는?

① `Phone: 010-1234-5678` (변경 없음)  
② `01012345678` (숫자만 남음)  
③ `0101234` (일부만)  
④ 에러

---

**[33번]** REGEXP_INSTR에서 `return_option`이 1일 때의 의미는?

① 패턴 일치 시작 위치 반환  
② 패턴 일치 끝 다음 위치 반환  
③ 총 일치 횟수 반환  
④ 패턴 일치 문자열 길이 반환

---

**[34번]** 다음 중 `[[:space:]]`에 해당하지 않는 것은?

① 스페이스 문자  
② 탭 문자 (\t)  
③ 개행 문자 (\n)  
④ 숫자 0

---

**[35번]** CHECK 제약 조건에서 정규 표현식 적용 시 Oracle은 어떤 함수를 사용하는가?

① REGEXP_MATCH  
② REGEXP_LIKE  
③ REGEXP_INSTR  
④ REGEXP_SUBSTR

---

**[36번]** `REGEXP_COUNT('abcabc', 'a', 1, 'i')`의 결과는?

① 1  
② 2  
③ 3  
④ 6

---

**[37번]** 숫자만으로 구성된 우편번호(5자리)를 검증하는 패턴으로 올바른 것은?

① `^[0-9]$`  
② `^[0-9]{5}$`  
③ `[0-9]{5}`  
④ `^[[:digit:]]+$`

---

**[38번]** `REGEXP_SUBSTR('2024-12-25', '[0-9]+', 1, 2)`의 결과는?

① 2024  
② 12  
③ 25  
④ NULL

---

**[39번]** employees 테이블에서 phone_number에 '.'(마침표)가 두 개인 직원 수를 구하는 쿼리는?

① `WHERE REGEXP_COUNT(phone_number, '\.') = 2`  
② `WHERE REGEXP_COUNT(phone_number, '.') = 2`  
③ `WHERE REGEXP_INSTR(phone_number, '\.', 2) > 0`  
④ `WHERE REGEXP_LIKE(phone_number, '\.{2}')`

---

**[40번]** `REGEXP_REPLACE('Oracle 19c Database', '([[:upper:]][[:lower:]]*)', '[\1]')`의 결과는?

① `[Oracle] 19c [Database]`  
② `Oracle 19c Database` (변경 없음)  
③ `oracle 19c database`  
④ `[O]racle 19c [D]atabase`

---

## 상(심화) — 10문제

---

**[41번]** 다음 SQL의 결과는?

```sql
SELECT REGEXP_SUBSTR('one two three four', '[^ ]+', 1, 3) FROM dual;
```

① one  
② two  
③ three  
④ four

---

**[42번]** 서브표현식을 이용하여 `'John Smith'`에서 성(Smith)만 추출하는 쿼리로 올바른 것은?

① `REGEXP_SUBSTR('John Smith', '([^ ]+) ([^ ]+)', 1, 1, NULL, 1)`  
② `REGEXP_SUBSTR('John Smith', '([^ ]+) ([^ ]+)', 1, 1, NULL, 2)`  
③ `REGEXP_INSTR('John Smith', '[^ ]+')`  
④ `REGEXP_REPLACE('John Smith', '^[^ ]+ ', '')`

---

**[43번]** 다음 패턴 `^[[:upper:]][[:alnum:]]{7}$`에 일치하는 문자열은?

① `Oracle19`  
② `ORACLE19`  
③ `oracle19`  
④ `Oracle1`

---

**[44번]** employees 테이블에서 email이 숫자를 포함하지 않는 직원을 조회하는 쿼리로 올바른 것은?

① `WHERE NOT REGEXP_LIKE(email, '[[:digit:]]')`  
② `WHERE REGEXP_LIKE(email, '^[^[:digit:]]+$')`  
③ `WHERE REGEXP_COUNT(email, '[[:digit:]]') = 0`  
④ 위 세 가지 모두 올바른 결과를 반환한다

---

**[45번]** 다음 중 HTML 태그를 제거하는 올바른 정규 표현식은?

① `REGEXP_REPLACE(col, '<.*>', '')`  
② `REGEXP_REPLACE(col, '<[^>]+>', '')`  
③ `REGEXP_REPLACE(col, '<.*?>', '')`  
④ `REGEXP_REPLACE(col, '<[^/]+>', '')`

---

**[46번]** `REGEXP_INSTR('abcabc', 'b', 1, 2)`의 결과는?

① 2  
② 5  
③ 3  
④ 6

---

**[47번]** 다음 중 신용카드 번호 형식 XXXX-XXXX-XXXX-XXXX를 검증하는 올바른 패턴은?

① `^[0-9]{16}$`  
② `^[0-9]{4}(-[0-9]{4}){3}$`  
③ `^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}$`  
④ ②와 ③ 모두 올바르다 (형식 조건이 다름)

---

**[48번]** `REGEXP_REPLACE`에서 replace_string에 `\1`, `\2` 등을 사용하는 목적은?

① 특수 문자를 이스케이프하기 위해  
② 서브표현식(괄호 그룹)으로 캡처한 문자열을 역참조(Back Reference)하기 위해  
③ 반복 횟수를 지정하기 위해  
④ 문자 클래스를 정의하기 위해

---

**[49번]** 다음 SQL의 결과는?

```sql
SELECT REGEXP_COUNT('the cat sat on the mat', '[aeiou]', 1, 'i') FROM dual;
```

① 5  
② 6  
③ 7  
④ 8

---

**[50번]** employees 테이블에서 job_id가 `XX_XXX` 형식(대문자 알파벳 2자 + 언더스코어 + 대문자 알파벳 3자)인 직원을 조회하는 쿼리는?

① `WHERE REGEXP_LIKE(job_id, '^[A-Z]{2}_[A-Z]{3}$')`  
② `WHERE REGEXP_LIKE(job_id, '^[[:upper:]]{2}_[[:upper:]]{3}$')`  
③ `WHERE REGEXP_LIKE(job_id, '^[A-Z][A-Z]_[A-Z][A-Z][A-Z]$')`  
④ 위 세 가지 모두 동일한 결과를 반환한다
