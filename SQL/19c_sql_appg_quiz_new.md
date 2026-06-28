# Oracle Database 19c: SQL Workshop
## Appendix G — 고급 스크립트 작성 | 연습문제 (50문제)

---

## 하(기초) — 20문제

**[1번]** "SQL로 SQL을 생성"하는 기법에서 데이터 소스로 주로 활용되는 것은?

① DUAL 테이블  
② 데이터 딕셔너리(user_tables 등)  
③ 임시 테이블  
④ V$ 뷰

---

**[2번]** SQL*Plus에서 `SET ECHO OFF`의 역할은?

① SQL 결과를 숨긴다  
② SQL 명령어 자체가 화면에 출력되지 않도록 한다  
③ 오류 메시지를 숨긴다  
④ 연결을 끊는다

---

**[3번]** `SET FEEDBACK OFF`의 역할은?

① 컬럼 헤더를 숨긴다  
② "1 row(s) selected" 같은 피드백 메시지를 숨긴다  
③ SQL 명령어 출력을 끈다  
④ 페이지 구분선을 제거한다

---

**[4번]** `SET PAGESIZE 0`의 효과는?

① 출력 페이지를 0개로 제한한다  
② 헤더와 페이지 구분선을 모두 제거한다  
③ SQL 실행을 중단한다  
④ 한 페이지에 최대 0행을 표시한다

---

**[5번]** SQL*Plus에서 `/`(슬래시)의 역할은?

① 주석을 시작한다  
② 나눗셈 연산자  
③ 버퍼에 있는 SQL 문을 실행한다  
④ 다음 페이지로 이동한다

---

**[6번]** 다음 SQL의 결과로 올바른 것은?

```sql
SELECT 'DROP TABLE ' || object_name || ';'
FROM   user_objects
WHERE  object_type = 'TABLE';
```

① 테이블을 실제로 삭제한다  
② DROP TABLE 문자열을 포함한 텍스트 행을 생성한다  
③ 테이블 목록을 조회한다  
④ 오류가 발생한다

---

**[7번]** SQL 문자열 내에서 홑따옴표(') 문자 자체를 출력하려면?

① `'` 하나  
② `''` 두 개 연속  
③ `\'` 역슬래시 사용  
④ `CHR(39)` 함수 사용만 가능

---

**[8번]** `SET HEADING OFF`의 역할은?

① 컬럼 헤더(이름)를 출력하지 않는다  
② 페이지 헤더를 제거한다  
③ 제목 행을 굵게 표시한다  
④ 결과를 CSV 형태로 출력한다

---

**[9번]** SQL*Plus 치환 변수 `&변수명`과 `&&변수명`의 차이는?

① `&`: 매번 입력 요청 / `&&`: 한 번만 입력 받고 세션 동안 재사용  
② `&&`: 매번 입력 요청 / `&`: 한 번만 입력 받음  
③ 두 개는 동일하다  
④ `&&`는 오류를 발생시킨다

---

**[10번]** `SPOOL /path/output.sql` 명령어의 역할은?

① output.sql 파일을 실행한다  
② 이후 화면 출력을 output.sql 파일에 저장하기 시작한다  
③ output.sql 파일을 삭제한다  
④ 화면 출력을 중단한다

---

**[11번]** `SPOOL OFF`의 역할은?

① 스풀 파일 쓰기를 중단하고 파일을 닫는다  
② 스풀 파일을 삭제한다  
③ 새 스풀 파일을 시작한다  
④ 화면 출력을 중단한다

---

**[12번]** 다음 중 데이터 딕셔너리 뷰에서 테이블 목록을 조회하는 올바른 뷰는?

① `all_columns`  
② `user_tables`  
③ `dual`  
④ `v$session`

---

**[13번]** `SET LINESIZE 100`의 역할은?

① 쿼리 결과를 100행으로 제한한다  
② 출력 한 줄의 최대 문자 수를 100으로 설정한다  
③ 100초 타임아웃을 설정한다  
④ 100개의 컬럼을 허용한다

---

**[14번]** 다음 표현식의 출력 결과는?

```sql
SELECT '''' FROM dual;
```

① `''''`  
② `'`  
③ 빈 문자열  
④ 오류

---

**[15번]** 다음 표현식의 출력 결과는?

```sql
SELECT '''X''' FROM dual;
```

① `X`  
② `'X'`  
③ `'''X'''`  
④ 오류

---

**[16번]** `user_tables`에서 조회할 수 없는 정보는?

① 테이블 이름  
② 테이블의 행 수 (근사치)  
③ 다른 사용자의 테이블 목록  
④ 테이블스페이스 이름

---

**[17번]** 다음 중 `SET ECHO ON`으로 복원해야 하는 이유는?

① 보안을 위해  
② 이후 인터랙티브 SQL*Plus 세션에서 입력한 SQL이 화면에 표시되도록  
③ 결과를 CSV로 저장하기 위해  
④ 오류를 방지하기 위해

---

**[18번]** `NEW_VALUE` 옵션을 사용하는 `COLUMN` 명령어의 역할은?

① 컬럼의 출력 형식을 지정한다  
② 쿼리 결과를 SQL*Plus 변수에 저장한다  
③ 컬럼을 숨긴다  
④ 컬럼에 별칭을 부여한다

---

**[19번]** 다음 중 SQL*Plus 전용 명령어(SQL이 아닌 것)는?

① SELECT  
② SET ECHO OFF  
③ WHERE  
④ GROUP BY

---

**[20번]** `WHERE 1=2` 조건의 역할은?

① 모든 행을 선택한다  
② 테이블 구조만 복사하고 데이터는 가져오지 않는다  
③ 첫 번째 행만 가져온다  
④ 오류를 발생시킨다

---

## 중(응용) — 20문제

**[21번]** 다음 쿼리의 출력 결과는?

```sql
SELECT 'CREATE TABLE ' || table_name ||
       '_backup AS SELECT * FROM ' || table_name || ';'
FROM   user_tables;
```

① 실제로 backup 테이블을 생성한다  
② 각 테이블에 대한 CREATE TABLE 문 문자열을 생성한다  
③ 테이블 목록을 조회한다  
④ user_tables를 백업한다

---

**[22번]** 다음 스크립트에서 `SET PAGESIZE 0`을 사용하는 이유는?

```sql
SET HEADING  OFF
SET PAGESIZE 0
SELECT 'INSERT INTO ...' FROM departments;
```

① 결과를 파일로 저장하기 위해  
② 헤더와 페이지 구분선 없이 순수한 SQL 문만 출력하기 위해  
③ 행 수를 제한하기 위해  
④ NULL 값을 처리하기 위해

---

**[23번]** 다음 표현식에서 `''''||department_name||''''`의 출력 결과는? (department_name = 'Marketing')

① `Marketing`  
② `'Marketing'`  
③ `''Marketing''`  
④ 오류

---

**[24번]** INSERT 문 생성 스크립트에서 문자열 컬럼을 홑따옴표로 감싸려면?

```sql
SELECT 'INSERT INTO t VALUES (' || id || ', ''' || name || ''');'
FROM   ...;
```

① `''' || name || '''` — 올바른 표현  
② `'''' || name || ''''` — 올바른 표현  
③ `"'" || name || "'"` — 올바른 표현  
④ `CHR(39) || name || CHR(39)` — 유일한 방법

---

**[25번]** 다음 중 `&&deptno` 변수가 NULL일 때의 DECODE 동작은?

```sql
DECODE('&&deptno', null, '처리A', '처리B')
```

① '처리A'를 반환한다  
② '처리B'를 반환한다  
③ NULL을 반환한다  
④ 오류가 발생한다

---

**[26번]** 동적 WHERE 절 스크립트에서 `COLUMN my_col NEW_VALUE dyn_where_clause`의 역할은?

① my_col 컬럼의 형식을 지정한다  
② 쿼리 결과의 my_col 값을 `dyn_where_clause` 변수에 저장한다  
③ my_col을 숨긴다  
④ WHERE 절을 직접 실행한다

---

**[27번]** 다음 스크립트 순서로 올바른 것은?

① SET 명령어 → SQL 실행 → SPOOL → SET 복원  
② SPOOL 시작 → SET 명령어 → SQL 실행 → SPOOL OFF → SET 복원  
③ SET 복원 → SQL 실행 → SET 명령어 → SPOOL  
④ SQL 실행 → SET 명령어 → SPOOL

---

**[28번]** 다음 쿼리 결과를 파일로 저장하려면?

```sql
SELECT 'DROP TABLE ' || table_name || ';' FROM user_tables;
```

① `SAVE file.sql`  
② `SPOOL file.sql` 이후 쿼리 실행, `SPOOL OFF`  
③ `WRITE file.sql`  
④ `OUTPUT file.sql`

---

**[29번]** `user_objects`에서 `object_type = 'TABLE'` 조건의 역할은?

① 테이블 타입의 컬럼만 조회  
② user_objects 중 TABLE 타입 객체만 필터링  
③ 시스템 테이블만 조회  
④ 뷰(VIEW)도 포함

---

**[30번]** 다음 중 `SET ECHO OFF`를 사용하지 않은 경우 스크립트 출력에 포함되는 것은?

① SELECT 결과만  
② SELECT 결과 + SELECT 구문 자체  
③ 오류 메시지만  
④ 아무것도 출력되지 않는다

---

**[31번]** SQL Generating SQL의 주요 장점은?

① 복잡한 JOIN을 피할 수 있다  
② 반복적인 DDL/DML 작업을 자동화한다  
③ 트랜잭션 처리 속도를 높인다  
④ NULL 처리를 개선한다

---

**[32번]** 다음 중 `SET FEEDBACK ON`으로 출력되는 메시지 형식은?

① "쿼리 실행 완료"  
② "N rows selected."  
③ "SQL 구문 오류"  
④ 오류 메시지

---

**[33번]** 100개 테이블 각각에 대해 분석(ANALYZE) 명령어를 실행하는 스크립트를 생성할 때 SQL Generating SQL 기법이 유리한 이유는?

① 각 테이블을 수동으로 분석하면 100번 타이핑이 필요 → 자동화로 효율적  
② SQL이 더 빠르게 실행된다  
③ 데이터 딕셔너리를 업데이트한다  
④ 인덱스를 자동 생성한다

---

**[34번]** 다음 코드에서 `'&deptno'`와 `&&deptno`의 차이는?

① `'&deptno'`는 문자열로 처리, `&&deptno`는 변수 치환  
② `&&deptno`는 매번 입력 요청, `'&deptno'`는 세션 유지  
③ 두 개는 동일하다  
④ `'&deptno'`는 오류를 발생시킨다

---

**[35번]** 다음 DECODE 기반 동적 WHERE 절에서 부서와 입사일이 모두 입력되었을 때의 결과는?

```sql
DECODE('&&deptno', null, ..., 
    DECODE('&&hiredate', null, 
        'WHERE department_id = ' || '&&deptno',
        'WHERE department_id = '||'&&deptno'||
        ' AND hire_date = TO_DATE('''||'&&hiredate'||''',''DD-MON-YYYY'')'
    )
)
```

① WHERE 절 없음  
② `WHERE department_id = 값`  
③ `WHERE department_id = 값 AND hire_date = 날짜`  
④ 오류

---

**[36번]** 다음 스크립트에서 출력 결과에 컬럼 헤더가 포함되지 않게 하려면?

① `SET HEADING OFF` 추가  
② `COLUMN name NOPRINT`  
③ `SET PAGESIZE 100`  
④ `NOHEADER` 키워드 추가

---

**[37번]** SQL Generating SQL에서 결과 SQL 문을 즉시 실행하려면?

① 결과를 SPOOL로 저장 후 `@파일명`으로 실행  
② `EXECUTE` 함수 사용  
③ `DYNAMIC` 키워드 사용  
④ 결과를 클립보드에 복사 후 붙여넣기

---

**[38번]** 다음 중 `SET LINESIZE`가 너무 작을 때 발생하는 문제는?

① 결과가 여러 줄로 잘려서 출력된다  
② 오류가 발생한다  
③ 결과가 잘린다  
④ 쿼리 성능이 저하된다

---

**[39번]** SQL*Plus에서 `COLUMN` 명령어 없이 `NEW_VALUE`를 사용할 수 없는 이유는?

① NEW_VALUE는 COLUMN 명령어의 옵션이기 때문  
② NEW_VALUE는 SQL 예약어이기 때문  
③ NEW_VALUE는 PL/SQL 전용이기 때문  
④ NEW_VALUE는 더 이상 지원되지 않기 때문

---

**[40번]** 다음 중 SQL*Plus 스크립트에서 주석 처리 방법으로 옳은 것은?

① `-- 주석` 또는 `/* 주석 */`  
② `# 주석`  
③ `// 주석`  
④ `REMARK 주석`만 사용 가능

---

## 상(심화) — 10문제

**[41번]** 다음 INSERT 덤프 스크립트에서 NUMBER 타입 컬럼(location_id)에 홑따옴표가 없는 이유는?

```sql
SELECT 'INSERT INTO departments VALUES ('
       || department_id  || ', '''
       || department_name || ''', '
       || location_id    || ');'
FROM   departments;
```

① location_id는 NULL이기 때문  
② NUMBER 타입은 홑따옴표 없이 직접 삽입 가능하기 때문  
③ SQL 규칙상 오류이므로 홑따옴표가 생략되었다  
④ location_id는 자동으로 변환된다

---

**[42번]** 다음 스크립트의 문제점은?

```sql
SELECT 'INSERT INTO emp VALUES (' || last_name || ');'
FROM   employees;
```

① `last_name`은 VARCHAR2이므로 홑따옴표로 감싸야 한다  
② INSERT 구문이 잘못되었다  
③ FROM 절이 잘못되었다  
④ 문제없다

---

**[43번]** 다음 중 동적 WHERE 절 기법이 정적 WHERE 절보다 유리한 시나리오는?

① 항상 동일한 조건으로 조회할 때  
② 사용자가 입력한 조건 조합에 따라 쿼리 조건이 달라질 때  
③ 인덱스를 활용할 때  
④ 단일 테이블을 조회할 때

---

**[44번]** 다음 코드에서 `REPLACE` 함수의 역할은? (스크립트 생성 과정에서)

```sql
SELECT 'GRANT SELECT ON ' || table_name || ' TO READONLY;'
FROM   user_tables
WHERE  table_name NOT LIKE '%$%';
```

① 특수 문자 `$`를 포함한 시스템 내부 테이블을 제외한다  
② REPLACE 함수 없이 일반 WHERE로 필터링  
③ GRANT 권한을 실제로 부여한다  
④ 오류를 발생시킨다

---

**[45번]** 다음 상황에서 올바른 홑따옴표 처리는?

목표: `INSERT INTO t VALUES ('Seoul', 'Korea');` 출력

```sql
-- 빈칸 채우기
SELECT 'INSERT INTO t VALUES (''' || city || ''', ''' || country || ''');'
FROM   (SELECT 'Seoul' AS city, 'Korea' AS country FROM dual);
```

① 위 코드가 올바르다  
② `'||city||'` 형태로 써야 한다  
③ `"Seoul"` 더블쿼트를 사용해야 한다  
④ 오류가 발생한다

---

**[46번]** SQL*Plus에서 `&&변수명`을 사용하면 스크립트 재실행 시 어떤 값이 사용되는가?

① 항상 새로운 입력을 요청한다  
② 세션 동안 처음 입력한 값이 재사용된다  
③ NULL이 사용된다  
④ 오류가 발생한다

---

**[47번]** 다음 중 SQL Generating SQL로 생성된 스크립트를 자동 실행하는 완전한 패턴은?

① 수동으로 복사-붙여넣기  
② `SPOOL /tmp/script.sql` → 스크립트 실행 → `SPOOL OFF` → `@/tmp/script.sql`  
③ `EXECUTE IMMEDIATE` 사용  
④ `DBMS_SQL` 패키지만 사용

---

**[48번]** 100개 테이블에 `ALTER TABLE ... ENABLE CONSTRAINT ...` 명령을 생성하는 쿼리는?

① 데이터 딕셔너리(`user_constraints`)를 활용하여 생성한다  
② user_tables에서 직접 조회한다  
③ DUAL 테이블만 활용한다  
④ 수동으로 작성해야 한다

---

**[49번]** 다음 중 SQL*Plus 스크립트를 실행하는 올바른 방법은?

① `RUN script.sql`  
② `@script.sql` 또는 `START script.sql`  
③ `EXEC script.sql`  
④ `CALL script.sql`

---

**[50번]** 다음 조건을 만족하는 INSERT 스크립트를 생성할 때 NULL 값 처리로 올바른 것은?

```
조건: commission_pct가 NULL인 경우 NULL 문자열로, 값이 있으면 숫자로 삽입
```

① `NVL(commission_pct, 'NULL')` 사용  
② `NVL(TO_CHAR(commission_pct), 'NULL')` 또는 DECODE 활용  
③ NULL 컬럼은 포함하지 않는다  
④ 오류가 발생하므로 불가능
