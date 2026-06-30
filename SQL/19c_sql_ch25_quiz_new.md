# Oracle Database 19c: SQL Workshop
## Chapter 25 — 정규표현식 | 연습문제 (50문제)

---

## 하(기초) — 20문제

**[1번]** Oracle에서 정규표현식을 지원하기 위해 도입된 버전은?

① Oracle 8i  
② Oracle 9i  
③ Oracle 10g  
④ Oracle 11g

---

**[2번]** 정규표현식에서 임의의 한 문자를 나타내는 메타문자는?

① `%`  
② `_`  
③ `.`  
④ `*`

---

**[3번]** 정규표현식에서 문자열의 시작을 나타내는 메타문자는?

① `$`  
② `^`  
③ `|`  
④ `\`

---

**[4번]** 정규표현식에서 앞 문자가 1회 이상 반복됨을 나타내는 메타문자는?

① `*`  
② `?`  
③ `+`  
④ `.`

---

**[5번]** 다음 중 `[aeiou]`가 의미하는 것은?

① 문자열 "aeiou"와 정확히 일치  
② a, e, i, o, u 중 하나의 문자  
③ a부터 u까지의 범위  
④ a, e, i, o, u 모두 포함

---

**[6번]** `REGEXP_LIKE`의 반환값 형태는?

① 숫자  
② 문자열  
③ TRUE 또는 FALSE  
④ NULL

---

**[7번]** `REGEXP_INSTR` 함수가 패턴과 일치하지 않을 때 반환하는 값은?

① -1  
② NULL  
③ 0  
④ 1

---

**[8번]** `REGEXP_SUBSTR` 함수가 패턴과 일치하지 않을 때 반환하는 값은?

① 0  
② -1  
③ 빈 문자열('')  
④ NULL

---

**[9번]** `match_param`에서 대소문자를 무시하도록 설정하는 옵션은?

① `c`  
② `i`  
③ `n`  
④ `m`

---

**[10번]** POSIX 문자 클래스 `[:digit:]`는 다음 중 무엇과 동일한가?

① `[a-z]`  
② `[A-Z]`  
③ `[0-9]`  
④ `[a-zA-Z]`

---

**[11번]** 정규표현식 `{3}`이 의미하는 것은?

① 최소 3회 반복  
② 정확히 3회 반복  
③ 최대 3회 반복  
④ 3회 미만 반복

---

**[12번]** 다음 중 `REGEXP_REPLACE` 함수의 역참조에 사용하는 표기법은?

① `$1`, `$2`  
② `%1`, `%2`  
③ `\1`, `\2`  
④ `&1`, `&2`

---

**[13번]** `REGEXP_COUNT` 함수가 추가된 Oracle 버전은?

① Oracle 9i  
② Oracle 10g  
③ Oracle 11g  
④ Oracle 12c

---

**[14번]** 정규표현식 `[^0-9]`가 의미하는 것은?

① 0~9 사이의 숫자 한 개  
② 숫자가 아닌 문자 한 개  
③ 0부터 9까지의 범위 밖  
④ 0 또는 9

---

**[15번]** `REGEXP_LIKE`는 SQL 문의 어느 절에서 주로 사용되는가?

① SELECT  
② FROM  
③ WHERE  
④ GROUP BY

---

**[16번]** 정규표현식 `^[A-Z]`가 의미하는 것은?

① 대문자로 시작하는 문자열  
② 대문자만으로 이루어진 문자열  
③ 대문자 A부터 Z  
④ 대문자로 끝나는 문자열

---

**[17번]** 정규표현식 `colou?r`에 일치하는 것은?

① "colour"만  
② "color"만  
③ "colour"와 "color" 모두  
④ "colouur"도 포함

---

**[18번]** `REGEXP_INSTR`의 `return_opt` 파라미터 값이 `1`일 때 반환하는 것은?

① 일치하는 문자열의 시작 위치  
② 일치하는 문자열의 끝 위치 + 1  
③ 일치하는 문자열 길이  
④ 일치 횟수

---

**[19번]** 정규표현식 `.+`가 일치하는 최소 문자열 길이는?

① 0  
② 1  
③ 2  
④ 제한 없음

---

**[20번]** `match_param` `'m'`(다중행 모드)에서 `^`과 `$`의 동작 변화는?

① 각 행의 시작과 끝에도 적용  
② 전체 문자열 시작과 끝에만 적용  
③ `^`과 `$`를 무시  
④ 줄바꿈 문자와 일치

---

## 중(응용) — 16문제

**[21번]** 다음 SQL의 실행 결과로 맞는 것은?

```sql
SELECT last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '^[AEIOU]', 'i');
```

① last_name이 모음으로 끝나는 직원  
② last_name이 모음으로 시작하는 직원  
③ last_name에 모음이 포함된 직원  
④ last_name이 모음만으로 구성된 직원

---

**[22번]** 다음 SQL에서 반환되는 값은?

```sql
SELECT REGEXP_INSTR('515.123.4567', '[0-9]+', 1, 2)
FROM   dual;
```

① 1  
② 4  
③ 5  
④ 8

---

**[23번]** 다음 SQL의 결과는?

```sql
SELECT REGEXP_SUBSTR('Oracle Database 19c', '[A-Za-z]+', 1, 2)
FROM   dual;
```

① 'Oracle'  
② 'Database'  
③ '19c'  
④ NULL

---

**[24번]** 다음 SQL에서 반환되는 값은?

```sql
SELECT REGEXP_REPLACE('Hello   World', '\s+', ' ')
FROM   dual;
```

① 'Hello World'  
② 'HelloWorld'  
③ 'Hello   World'  
④ NULL

---

**[25번]** 다음 SQL에서 `REGEXP_COUNT`의 반환값은?

```sql
SELECT REGEXP_COUNT('Mississippi', 's', 1, 'i')
FROM   dual;
```

① 2  
② 4  
③ 5  
④ 3

---

**[26번]** 다음 SQL에서 결과가 반환되는 행은?

```sql
SELECT last_name
FROM   employees
WHERE  REGEXP_LIKE(email, '^[A-Z]{4,6}$');
```

① 이메일이 4~6자 소문자로 구성된 직원  
② 이메일이 4~6자 대문자로 구성된 직원  
③ 이메일이 정확히 5자 대문자인 직원  
④ 이메일이 4~6개 문자(숫자 포함)로 구성된 직원

---

**[27번]** 다음 SQL의 결과로 알맞은 것은?

```sql
SELECT REGEXP_REPLACE('King Steven', '^(\S+)\s+(\S+)$', '\2 \1')
FROM   dual;
```

① 'King Steven'  
② 'Steven King'  
③ '\2 \1'  
④ NULL

---

**[28번]** 다음 중 패턴 `\d{3}\.\d{3}\.\d{4}`와 일치하는 문자열은?

① '123-456-7890'  
② '123.456.7890'  
③ '12.34.567'  
④ 'ABC.123.4567'

---

**[29번]** 다음 SQL에서 오류가 발생하는 이유는?

```sql
SELECT last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '[A-Z');
```

① 대괄호를 닫지 않아 잘못된 패턴  
② `REGEXP_LIKE`는 WHERE에 사용 불가  
③ `last_name`이 정규표현식 지원 안 함  
④ `[A-Z]`는 유효한 패턴

---

**[30번]** 다음 SQL의 결과로 알맞은 것은?

```sql
SELECT REGEXP_SUBSTR('abc123def456', '[0-9]+', 1, 1)
FROM   dual;
```

① 'abc'  
② '123'  
③ 'def'  
④ '456'

---

**[31번]** 다음 SQL에서 결과가 반환되는 행은?

```sql
SELECT last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '(.)\1');
```

① last_name에 같은 문자가 2번 연속 나오는 직원  
② last_name에 문자가 반복되는 직원  
③ last_name 길이가 홀수인 직원  
④ last_name이 두 글자인 직원

---

**[32번]** 다음 SQL에서 `REGEXP_INSTR`의 결과는?

```sql
SELECT REGEXP_INSTR('abcabcabc', 'abc', 1, 3)
FROM   dual;
```

① 1  
② 4  
③ 7  
④ 9

---

**[33번]** 다음 중 `REGEXP_REPLACE`로 문자열에서 숫자만 제거하는 올바른 코드는?

① `REGEXP_REPLACE(str, '[0-9]', '')`  
② `REGEXP_REPLACE(str, '[^0-9]', '')`  
③ `REGEXP_REPLACE(str, '[0-9]+', NULL)`  
④ `REGEXP_REPLACE(str, '\d', 'X')`

---

**[34번]** 다음 SQL에서 반환되는 값은?

```sql
SELECT REGEXP_COUNT('aababab', 'ab')
FROM   dual;
```

① 2  
② 3  
③ 4  
④ 1

---

**[35번]** 다음 SQL의 결과는?

```sql
SELECT REGEXP_SUBSTR('2024-01-15', '(\d{4})-(\d{2})-(\d{2})',
                     1, 1, NULL, 2)
FROM   dual;
```

① '2024'  
② '01'  
③ '15'  
④ '2024-01-15'

---

**[36번]** 다음 중 `match_param` 'i'와 'c' 옵션에 대한 설명으로 옳은 것은?

① 'i'는 Oracle 12c 이상에서만 지원  
② 두 옵션을 동시에 지정하면 'i'가 우선  
③ 기본값은 'c'(대소문자 구분)  
④ 'c'는 대소문자를 무시

---

## 상(심화) — 14문제

**[37번]** 다음 SQL의 결과로 가장 알맞은 것은?

```sql
SELECT last_name,
       REGEXP_REPLACE(last_name, '([aeiou])', '[\1]', 1, 0, 'i') AS masked
FROM   employees
WHERE  employee_id IN (100, 101, 102);
```

① 모음을 대괄호로 감싸서 표시  
② 모음을 삭제  
③ 모음을 X로 치환  
④ 모음을 대문자로 변환

---

**[38번]** 다음 SQL에서 반환되는 행의 조건은?

```sql
SELECT last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '^[^AEIOU][AEIOU]', 'i');
```

① last_name이 자음으로 시작하고 두 번째 문자가 모음인 직원  
② last_name이 모음이 아닌 문자로 시작하는 직원  
③ last_name의 첫 두 글자가 자음인 직원  
④ last_name에 자음과 모음이 번갈아 나오는 직원

---

**[39번]** 다음 SQL에서 `subexpr` 파라미터의 역할은?

```sql
SELECT REGEXP_SUBSTR('John Smith 30', '(\w+)\s+(\w+)\s+(\d+)',
                     1, 1, NULL, 3)
FROM   dual;
```

① '(\w+)\s+(\w+)\s+(\d+)' 전체를 추출  
② 세 번째 그룹 `(\d+)`의 값 '30'을 추출  
③ 세 번째 일치 항목을 추출  
④ 세 번째 캡처 그룹의 시작 위치 반환

---

**[40번]** 다음 SQL에서 반환되는 값은?

```sql
SELECT REGEXP_INSTR('Hello World', 'o', 1, 2)
FROM   dual;
```

① 5  
② 8  
③ 9  
④ 10

---

**[41번]** 다음 SQL에서 `REGEXP_REPLACE`가 수행하는 작업은?

```sql
SELECT REGEXP_REPLACE(phone_number,
                      '^(\d{3})\.(\d{3})\.(\d{4})$',
                      '(\1) \2-\3')
FROM   employees
WHERE  REGEXP_LIKE(phone_number, '^\d{3}\.\d{3}\.\d{4}$');
```

① 전화번호의 점(.)을 하이픈(-)으로 교체  
② `515.123.4567` → `(515) 123-4567` 형식으로 변환  
③ 전화번호에서 숫자만 추출  
④ 전화번호의 지역번호를 제거

---

**[42번]** 다음 중 `REGEXP_LIKE`를 사용하여 유효한 이메일 주소(user@domain.com 형식)를 필터링하는 패턴으로 가장 적합한 것은?

① `'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'`  
② `'^[A-Za-z]+@[A-Za-z]+\.com$'`  
③ `'%@%.%'`  
④ `'^.*@.*\..*$'`

---

**[43번]** 다음 SQL에서 반환되는 값은?

```sql
SELECT REGEXP_COUNT('the cat sat on the mat', 'at\b')
FROM   dual;
```

(단, `\b`는 단어 경계를 나타내는 Oracle 비표준 표기이며, 여기서는 `[[:space:]$]` 앞)

① 3  
② 2  
③ 4  
④ 1

---

**[44번]** 다음 쿼리가 수행하는 작업을 가장 정확하게 설명한 것은?

```sql
SELECT employee_id,
       LISTAGG(REGEXP_SUBSTR(job_history_str, '[A-Z_]+', 1, LEVEL),
               ', ')
       WITHIN GROUP (ORDER BY LEVEL) AS jobs
FROM   dual
CONNECT BY LEVEL <= REGEXP_COUNT(job_history_str, '[A-Z_]+');
```

① 특정 문자열에서 대문자+언더스코어 패턴을 모두 추출하여 쉼표로 연결  
② 직원별 직업 이력을 계층 쿼리로 분리  
③ `job_history_str`의 알파벳 문자 수를 집계  
④ 대문자 단어를 소문자로 변환

---

**[45번]** `REGEXP_REPLACE`의 `occurrence` 파라미터가 `0`일 때 동작은?

① 첫 번째 일치만 치환  
② 마지막 일치만 치환  
③ 모든 일치를 치환  
④ 치환하지 않음

---

**[46번]** 다음 SQL에서 반환되는 행을 가장 잘 설명한 것은?

```sql
SELECT last_name
FROM   employees
WHERE  REGEXP_LIKE(last_name, '^[A-Z][a-z]+$');
```

① 첫 글자만 대문자이고 나머지가 소문자인 last_name  
② 대문자만으로 구성된 last_name  
③ 첫 글자가 대문자인 last_name  
④ 소문자만으로 구성된 last_name

---

**[47번]** 다음 두 쿼리의 결과가 다른 이유는?

```sql
-- 쿼리 A
SELECT last_name FROM employees
WHERE  REGEXP_LIKE(last_name, 'king', 'i');

-- 쿼리 B
SELECT last_name FROM employees
WHERE  REGEXP_LIKE(last_name, '^king$', 'i');
```

① A는 'king'을 포함하는 모든 행, B는 정확히 'king'인 행  
② A와 B는 동일한 결과  
③ B는 오류 발생  
④ A는 대소문자 구분, B는 무시

---

**[48번]** 다음 SQL에서 의도한 결과를 올바르게 설명한 것은?

```sql
SELECT last_name,
       LENGTH(last_name) - LENGTH(REGEXP_REPLACE(last_name, '[aeiou]', '', 1, 0, 'i'))
         AS vowel_count
FROM   employees
ORDER BY vowel_count DESC
FETCH FIRST 5 ROWS ONLY;
```

① 모음을 모두 제거한 후 남은 자음의 수를 계산  
② 원래 길이에서 모음 제거 후 길이를 빼어 모음의 수를 계산  
③ 모음 제거 후 문자열을 반환  
④ `REGEXP_COUNT`와 동일한 결과

---

**[49번]** 다음 중 성능 관점에서 정규표현식 사용 시 주의할 점으로 옳지 않은 것은?

① 인덱스 컬럼에 `REGEXP_LIKE`를 사용하면 인덱스 스캔이 활성화된다  
② 복잡한 패턴은 단순한 패턴보다 CPU를 더 사용한다  
③ 단순한 패턴은 `LIKE`가 더 빠를 수 있다  
④ 대용량 데이터에서 정규표현식은 Full Table Scan을 유발할 수 있다

---

**[50번]** 다음 SQL에서 `REGEXP_SUBSTR`과 `CONNECT BY LEVEL`을 사용한 목적은?

```sql
SELECT TRIM(REGEXP_SUBSTR('a,bb,ccc,dddd', '[^,]+', 1, LEVEL)) AS token
FROM   dual
CONNECT BY LEVEL <= REGEXP_COUNT('a,bb,ccc,dddd', ',') + 1;
```

① 콤마로 구분된 문자열을 행으로 분리 (CSV Parsing)  
② 각 문자를 별도 행으로 분리  
③ 콤마를 제거한 문자열 반환  
④ 중복 단어 제거

---
