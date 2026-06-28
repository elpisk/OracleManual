# Oracle Database 19c: SQL Workshop
## Appendix G — 고급 스크립트 작성 (Writing Advanced Scripts)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- SQL로 SQL을 생성(SQL Generating SQL)하는 기법을 설명한다
- 기본 SQL 스크립트를 작성한다
- 스크립트 출력 결과를 파일로 저장한다
- 테이블 데이터를 INSERT 문 형태로 파일에 덤프한다
- 동적 WHERE 절(Dynamic Predicate)을 생성한다

---

## 1. SQL로 SQL 생성 (SQL Generating SQL)

SQL은 **SQL 스크립트를 생성하는 도구**로도 활용할 수 있다.

```sql
-- 각 테이블에 대한 CREATE TABLE 문을 자동 생성
SELECT 'CREATE TABLE ' || table_name ||
       '_test AS SELECT * FROM ' || table_name ||
       ' WHERE 1=2;'  AS "Create Table Script"
FROM   user_tables;
```

**출력 예:**
```
CREATE TABLE DEPARTMENTS_test AS SELECT * FROM DEPARTMENTS WHERE 1=2;
CREATE TABLE EMPLOYEES_test AS SELECT * FROM EMPLOYEES WHERE 1=2;
...
```

---

## 2. 환경 제어 (SET 명령어)

SQL*Plus의 `SET` 명령어로 스크립트 실행 환경을 제어한다.

```sql
-- 스크립트 시작: 출력 최소화
SET ECHO     OFF    -- SQL 명령어 자체를 화면에 출력 안 함
SET FEEDBACK OFF    -- "1 row(s) selected" 등 피드백 메시지 숨김
SET PAGESIZE 0      -- 헤더/페이지 구분선 제거

--- SQL 스크립트 실행 ---

-- 스크립트 끝: 원래 설정으로 복원
SET FEEDBACK ON
SET PAGESIZE 24
SET ECHO     ON
```

| SET 옵션 | 설명 |
|----------|------|
| `ECHO OFF/ON` | SQL 명령어 출력 여부 |
| `FEEDBACK OFF/ON` | "N rows selected" 메시지 출력 여부 |
| `PAGESIZE n` | 페이지당 행 수 (0=무제한) |
| `HEADING OFF/ON` | 컬럼 헤더 출력 여부 |
| `LINESIZE n` | 한 줄 최대 글자 수 |

---

## 3. DROP 문 스크립트 생성 예제

```sql
SET ECHO     OFF
SET FEEDBACK OFF
SET PAGESIZE 0

SELECT 'DROP TABLE ' || object_name || ';'
FROM   user_objects
WHERE  object_type = 'TABLE'
/

SET FEEDBACK ON
SET PAGESIZE 24
SET ECHO     ON
```

`/`는 SQL*Plus에서 버퍼의 SQL을 실행하는 명령어이다.

---

## 4. 테이블 데이터를 파일로 덤프

`SELECT`로 INSERT 문을 동적으로 생성하여 데이터를 백업할 수 있다.

```sql
SET HEADING  OFF
SET ECHO     OFF
SET FEEDBACK OFF
SET PAGESIZE 0

SELECT 'INSERT INTO departments_test VALUES ('
       || department_id  || ', '''
       || department_name || ''', '
       || location_id    || ');'
       AS "Insert Statements Script"
FROM   departments
/

SET PAGESIZE  24
SET HEADING   ON
SET ECHO      ON
SET FEEDBACK  ON
```

**출력 예:**
```
INSERT INTO departments_test VALUES (10, 'Administration', 1700);
INSERT INTO departments_test VALUES (20, 'Marketing', 1800);
...
```

---

## 5. 인용 부호 규칙

```
표현식            실제 출력
'''X'''           'X'        (양쪽 홑따옴표로 감싼 문자열)
''''              '          (홑따옴표 문자 자체)
''''||name||''''  'Admin'    (name 양쪽에 홑따옴표 추가)
''', '''          ', '       (쉼표+공백 앞뒤 홑따옴표)
''');'            ');         (닫는 괄호+세미콜론 앞 홑따옴표)
```

SQL 문자열 내에서 홑따옴표를 출력하려면 **두 개 연속**으로 작성한다: `''''` → `'`

---

## 6. 동적 WHERE 절 (Dynamic Predicate)

SQL*Plus 치환 변수(`&`, `&&`)를 활용하여 실행 시점에 WHERE 조건을 동적으로 결정한다.

```sql
-- 단순 치환 변수 사용
SELECT last_name FROM employees &dyn_where_clause;

-- DECODE를 활용한 복합 동적 조건 생성
COLUMN my_col NEW_VALUE dyn_where_clause

SELECT DECODE('&&deptno', null,
    DECODE ('&&hiredate', null, ' ',
        'WHERE hire_date=TO_DATE('''||'&&hiredate'||''',''DD-MON-YYYY'')'),
    DECODE ('&&hiredate', null,
        'WHERE department_id = ' || '&&deptno',
        'WHERE department_id = ' || '&&deptno' ||
        ' AND hire_date = TO_DATE('''||'&&hiredate'||''',''DD-MON-YYYY'')'))
    AS my_col
FROM dual;
```

**동작:**
- `&&deptno`와 `&&hiredate` 모두 NULL → WHERE 절 없음 (전체 조회)
- `&&deptno`만 입력 → `WHERE department_id = 값`
- `&&hiredate`만 입력 → `WHERE hire_date = 날짜`
- 둘 다 입력 → AND로 두 조건 결합

---

## 7. 스파일로 출력 저장 (SPOOL)

```sql
SPOOL /path/to/output.sql        -- 파일로 출력 시작

-- SQL 스크립트 실행 ...
SELECT ...;

SPOOL OFF                         -- 파일 저장 종료
```

---

## 8. 단원 요약

| 기법 | 핵심 내용 |
|------|-----------|
| SQL Generating SQL | SELECT로 DDL/DML 문을 자동 생성 |
| SET 명령어 | ECHO, FEEDBACK, PAGESIZE, HEADING으로 출력 제어 |
| 데이터 덤프 | SELECT로 INSERT 문 생성 → 데이터 백업 파일 작성 |
| 홑따옴표 처리 | SQL 내 `''`(두 개 연속)로 홑따옴표 출력 |
| 동적 WHERE 절 | `&&변수`와 DECODE/CASE로 실행 시점에 조건 결정 |
| SPOOL | 쿼리 결과를 파일로 저장 |
