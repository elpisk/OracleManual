# Oracle Database 19c: SQL Workshop
## Appendix G — 고급 스크립트 작성 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | SQL Generating SQL의 주요 소스: user_tables, user_objects 등 데이터 딕셔너리 뷰 |
| 2 | ② | `SET ECHO OFF`: SQL 명령어 자체를 화면에 출력하지 않음 |
| 3 | ② | `SET FEEDBACK OFF`: "N rows selected" 피드백 메시지 숨김 |
| 4 | ② | `SET PAGESIZE 0`: 헤더와 페이지 구분선 모두 제거 (순수 데이터만 출력) |
| 5 | ③ | `/`: SQL*Plus에서 현재 버퍼의 SQL 문을 실행 |
| 6 | ② | SELECT로 DROP TABLE ... 문자열을 생성 — 실제 삭제는 하지 않음 |
| 7 | ② | SQL 문자열 내 홑따옴표: `''`(두 개 연속)로 표현 |
| 8 | ① | `SET HEADING OFF`: 컬럼 이름(헤더) 출력 안 함 |
| 9 | ① | `&`: 매번 입력 요청 / `&&`: 처음 한 번 입력 후 세션 동안 재사용 |
| 10 | ② | `SPOOL 파일명`: 이후 화면 출력을 지정한 파일에 저장 시작 |
| 11 | ① | `SPOOL OFF`: 파일 저장 중단 및 파일 닫기 |
| 12 | ② | `user_tables`: 현재 사용자 소유 테이블 목록 |
| 13 | ② | `SET LINESIZE 100`: 출력 한 줄의 최대 글자 수 100 |
| 14 | ② | `''''` = 홑따옴표 두 개 연속 → 홑따옴표 하나 출력: `'` |
| 15 | ② | `'''X'''` = `'` + `X` + `'` = `'X'` |
| 16 | ③ | `user_tables`는 현재 사용자 테이블만 조회; 다른 사용자 테이블은 `all_tables` |
| 17 | ② | SET ECHO ON 복원: 이후 인터랙티브 세션에서 SQL이 화면에 표시되도록 |
| 18 | ② | `COLUMN 컬럼명 NEW_VALUE 변수명`: 쿼리 결과를 SQL*Plus 변수에 저장 |
| 19 | ② | `SET ECHO OFF`: SQL*Plus 전용 명령어 (SQL 언어 키워드가 아님) |
| 20 | ② | `WHERE 1=2`: 항상 false → 행 0개 → 테이블 구조만 복사, 데이터 없음 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

```sql
SELECT 'CREATE TABLE ' || table_name ||
       '_backup AS SELECT * FROM ' || table_name || ';'
FROM   user_tables;
```

이 쿼리는 CREATE TABLE 문자열을 포함한 행을 생성한다. 실제 테이블을 생성하지는 않는다.  
생성된 문자열을 SPOOL로 저장 후 `@파일명`으로 실행해야 테이블이 생성된다.

---

**[22번] 정답: ②**

`SET PAGESIZE 0`과 `SET HEADING OFF`를 사용하면 출력에 헤더와 구분선이 없어진다.  
결과가 순수한 INSERT 문 텍스트만 포함되어 다른 시스템에 바로 적용 가능한 스크립트가 생성된다.

---

**[23번] 정답: ②**

`''''||department_name||''''`:
- 앞쪽 `''''`: 문자열에서 홑따옴표 출력 → `'`
- `department_name` = `Marketing`
- 뒤쪽 `''''`: 홑따옴표 출력 → `'`
- 결과: `'Marketing'`

---

**[24번] 정답: ①**

```sql
'INSERT INTO t VALUES (' || id || ', ''' || name || ''');'
```

분해:
- `''':` 홑따옴표 시작
- `|| name ||`: 이름 값
- `''');'`: 홑따옴표 닫기 + `);` + 문자열 닫기

→ 결과: `INSERT INTO t VALUES (1, 'Smith');`

②도 가능하지만 ①이 더 일반적이다.

---

**[25번] 정답: ①**

`DECODE('&&deptno', null, '처리A', '처리B')`:
- `&&deptno`가 null(빈 입력) → 첫 번째 WHEN 조건 일치 → `'처리A'` 반환

---

**[26번] 정답: ②**

`COLUMN my_col NEW_VALUE dyn_where_clause`:
- 이후 SELECT 쿼리에서 `my_col` 컬럼의 값이
- `dyn_where_clause`라는 SQL*Plus 변수에 자동으로 저장됨
- 이 변수를 다음 쿼리의 WHERE 절에 `&dyn_where_clause`로 활용

---

**[27번] 정답: ②**

올바른 순서:
```
1. SPOOL 파일명 시작
2. SET ECHO OFF, FEEDBACK OFF, PAGESIZE 0 (출력 정리)
3. SQL 실행
4. SPOOL OFF
5. SET 명령어 복원 (FEEDBACK ON, PAGESIZE 24, ECHO ON)
```

---

**[28번] 정답: ②**

```sql
SPOOL /tmp/drop_tables.sql
SELECT 'DROP TABLE ' || table_name || ';' FROM user_tables;
SPOOL OFF
```

이후 `@/tmp/drop_tables.sql`로 생성된 스크립트를 실행한다.

---

**[29번] 정답: ②**

`user_objects`에는 TABLE, VIEW, INDEX, SEQUENCE, PROCEDURE 등 다양한 객체가 있다.  
`WHERE object_type = 'TABLE'`으로 테이블 객체만 필터링한다.

---

**[30번] 정답: ②**

`SET ECHO ON`(기본값)이면 SQL*Plus가 입력된 SQL 문을 화면에 먼저 출력한 후 결과를 출력한다.  
스크립트 파일을 `@파일명`으로 실행할 때도 SQL 문이 화면에 표시된다.

---

**[31번] 정답: ②**

SQL Generating SQL:
- 반복적인 DDL 작업(테이블별 GRANT, DROP, ANALYZE 등)을 자동화
- 데이터 딕셔너리의 메타데이터를 활용하여 다수의 SQL 문을 한 번에 생성

---

**[32번] 정답: ②**

`SET FEEDBACK ON` 시 출력:
```
SELECT * FROM employees;

107 rows selected.
```
행 수를 나타내는 `"N rows selected."` 메시지가 출력된다.

---

**[33번] 정답: ①**

100개 테이블을 수동으로 ANALYZE하려면 100번 타이핑이 필요하다.  
SQL Generating SQL으로 데이터 딕셔너리에서 테이블 목록을 가져와 ANALYZE 문을 자동 생성하면 한 번의 쿼리로 해결된다.

---

**[34번] 정답: ①**

- `'&deptno'`: 작은 따옴표로 감싸인 문자열 내의 `&deptno`는 치환 변수로 인식될 수 있지만, 컨텍스트에 따라 다름
- `&&deptno`: 치환 변수로 처음 한 번 입력 후 세션 동안 재사용

실제로 `DECODE('&&deptno', null, ...)`: `&&deptno`에 빈 값 입력 시 null 비교가 동작한다.

---

**[35번] 정답: ③**

deptno와 hiredate 모두 입력된 경우:
- 바깥쪽 DECODE: deptno != null → 내부 DECODE로
- 내부 DECODE: hiredate != null → 두 조건 AND

결과: `WHERE department_id = 50 AND hire_date = TO_DATE('01-JAN-2005','DD-MON-YYYY')`

---

**[36번] 정답: ①**

컬럼 헤더 제거:
```sql
SET HEADING OFF
```

또는 `SET PAGESIZE 0`도 헤더를 제거한다.

---

**[37번] 정답: ①**

SQL Generating SQL → 파일로 저장 → 실행:
```sql
SPOOL /tmp/generated.sql
SELECT ... FROM user_tables;  -- SQL 생성
SPOOL OFF
@/tmp/generated.sql           -- 생성된 SQL 실행
```

---

**[38번] 정답: ①**

`SET LINESIZE`가 너무 작으면 출력이 여러 줄로 잘려서 표시된다.  
예: LINESIZE=20으로 100자 출력 → 5줄로 나뉨.  
SQL 스크립트 생성 시 INSERT 문이 잘리면 오류가 발생할 수 있다.

---

**[39번] 정답: ①**

`NEW_VALUE`는 SQL*Plus `COLUMN` 명령어의 옵션이다:
```sql
COLUMN col_name NEW_VALUE variable_name
```
COLUMN 명령어를 통해서만 사용 가능하다.

---

**[40번] 정답: ①**

SQL*Plus에서 지원하는 주석:
- `-- 한 줄 주석`
- `/* 여러 줄 주석 */`
- `REMARK 주석` (SQL*Plus 전용, REM으로 단축)

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

SQL에서 NUMBER 타입(location_id, department_id)은 홑따옴표 없이 숫자 리터럴로 직접 삽입한다:
```sql
INSERT INTO departments VALUES (10, 'Administration', 1700);
```
VARCHAR2 타입(department_name)만 홑따옴표로 감싸야 한다.

---

**[42번] 정답: ①**

`last_name`은 VARCHAR2 타입이므로 INSERT 문에서 홑따옴표로 감싸야 한다:
```sql
-- 올바른 버전
SELECT 'INSERT INTO emp VALUES (''' || last_name || ''');'
FROM   employees;
```
홑따옴표 없이 생성된 `INSERT INTO emp VALUES (King);`은 실행 시 오류 발생.

---

**[43번] 정답: ②**

동적 WHERE 절은 사용자가 입력하는 조건이 매번 달라질 때 유용하다:
- 부서만 선택: `WHERE department_id = N`
- 날짜만 선택: `WHERE hire_date = ...`
- 둘 다 선택: `WHERE dept = N AND hire_date = ...`
- 둘 다 없음: 전체 조회

---

**[44번] 정답: ①**

`table_name NOT LIKE '%$%'`:
- Oracle 데이터 딕셔너리의 시스템 내부 테이블 이름에는 `$` 문자가 포함된다
- 예: `SYS.AUD$`, `OBJ$`, `CON$` 등
- 이런 내부 테이블을 제외하고 사용자 테이블에만 GRANT 생성

---

**[45번] 정답: ①**

```sql
SELECT 'INSERT INTO t VALUES (''' || city || ''', ''' || country || ''');'
FROM   (SELECT 'Seoul' AS city, 'Korea' AS country FROM dual);
```

분해:
- `'('`: 여는 괄호
- `'''`: 홑따옴표 시작
- `|| city ||`: Seoul
- `'''`: 홑따옴표 닫기
- `, '`: 쉼표+공백+홑따옴표 시작
- `'' || country ||`: Korea 값 + 홑따옴표 닫기 (주의: 중간 `''`와 `|| country ||` 구분 필요)

올바른 결과: `INSERT INTO t VALUES ('Seoul', 'Korea');`

---

**[46번] 정답: ②**

`&&변수명`: 세션 변수 (Session Variable)
- 첫 번째 사용 시 사용자에게 입력 요청
- 이후 같은 세션에서 동일 `&&변수명` 참조 시 처음 입력한 값 자동 사용
- `UNDEFINE 변수명`으로 세션 변수 제거 가능

---

**[47번] 정답: ②**

완전한 패턴:
```sql
-- 1. 스풀 파일 생성
SPOOL /tmp/generated_script.sql
SET ECHO OFF FEEDBACK OFF PAGESIZE 0

-- 2. SQL 생성
SELECT 'ALTER TABLE ' || table_name || ' ENABLE ALL CONSTRAINTS;'
FROM   user_tables;

SPOOL OFF

-- 3. 생성된 스크립트 실행
@/tmp/generated_script.sql
```

---

**[48번] 정답: ①**

```sql
-- user_constraints에서 비활성화된 제약 조건 목록 조회 후 ALTER 문 생성
SELECT 'ALTER TABLE ' || table_name ||
       ' ENABLE CONSTRAINT ' || constraint_name || ';'
FROM   user_constraints
WHERE  status = 'DISABLED';
```

`user_constraints`는 제약 조건 이름, 테이블 이름, 타입, 상태 등을 포함한다.

---

**[49번] 정답: ②**

SQL*Plus 스크립트 실행:
```sql
@script_name.sql      -- @ 기호 사용
START script_name.sql -- START 명령어 사용
```
두 방법은 동일하다.

---

**[50번] 정답: ②**

NULL 값 처리:
```sql
SELECT 'INSERT INTO emp VALUES ('||
       employee_id || ', '||
       NVL(TO_CHAR(commission_pct), 'NULL') || ');'
FROM   employees;
```

- `commission_pct`가 NULL인 경우: `NVL(TO_CHAR(NULL), 'NULL')` → 문자열 `'NULL'`
- 값이 있는 경우: `NVL(TO_CHAR(0.25), 'NULL')` → `'.25'`

결과: `INSERT INTO emp VALUES (100, NULL);` 또는 `INSERT INTO emp VALUES (150, .25);`
