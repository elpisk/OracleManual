# Oracle Database 19c: SQL Workshop
## Appendix G — 고급 스크립트 작성 | SQL 실습 모범답안

---

## Group 1: SQL Generating SQL 기본

**[1번]** COUNT(*) 문 자동 생성

```sql
SELECT 'SELECT COUNT(*) AS cnt, ''' || table_name || ''' AS tname FROM ' || table_name || ';'
AS count_script
FROM   user_tables
ORDER BY table_name;
```

**결과 예시:**
```
SELECT COUNT(*) AS cnt, 'COUNTRIES' AS tname FROM COUNTRIES;
SELECT COUNT(*) AS cnt, 'DEPARTMENTS' AS tname FROM DEPARTMENTS;
SELECT COUNT(*) AS cnt, 'EMPLOYEES' AS tname FROM EMPLOYEES;
...
```

---

**[2번]** DROP TABLE 문 생성

```sql
SELECT 'DROP TABLE ' || table_name || ' PURGE;' AS drop_script
FROM   user_tables ORDER BY table_name;
```

`PURGE`: 휴지통(Recycle Bin)에 넣지 않고 즉시 삭제.

---

**[3번]** 구조만 복사하는 CREATE TABLE 문 생성

```sql
SELECT 'CREATE TABLE ' || table_name ||
       '_bak AS SELECT * FROM ' || table_name || ' WHERE 1=2;'
FROM   user_tables;
```

`WHERE 1=2`: 항상 거짓 → 행 0개 복사 → 테이블 구조만 생성.

---

**[4번]** 현재 사용자 객체 목록

```sql
SELECT object_name, object_type, status, last_ddl_time
FROM   user_objects
ORDER BY object_type, object_name;
```

**주요 object_type**: TABLE, VIEW, INDEX, SEQUENCE, PROCEDURE, FUNCTION, TRIGGER

---

**[5번]** ENABLE CONSTRAINT 문 생성

```sql
SELECT 'ALTER TABLE ' || table_name ||
       ' ENABLE CONSTRAINT ' || constraint_name || ';'
FROM   user_constraints
WHERE  status = 'DISABLED'
ORDER BY table_name, constraint_name;
```

---

## Group 2: SET 명령어 및 출력 제어

**[6번]** departments INSERT 문 생성 스크립트

```sql
SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0 LINESIZE 200

SELECT 'INSERT INTO departments VALUES (' ||
       department_id   || ', ''' ||
       department_name || ''', ' ||
       NVL(TO_CHAR(manager_id), 'NULL')   || ', ' ||
       NVL(TO_CHAR(location_id), 'NULL')  || ');'
FROM   departments ORDER BY department_id;

SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON
```

**결과 예시:**
```
INSERT INTO departments VALUES (10, 'Administration', 200, 1700);
INSERT INTO departments VALUES (20, 'Marketing', 201, 1800);
INSERT INTO departments VALUES (30, 'Purchasing', 114, 1700);
...
```

**핵심:** `NVL(TO_CHAR(manager_id), 'NULL')`으로 NULL 처리.

---

**[7번]** employees INSERT 문 생성

```sql
SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0 LINESIZE 300

SELECT 'INSERT INTO employees (employee_id, first_name, last_name, '||
       'email, job_id, salary, department_id, manager_id) VALUES ('||
       employee_id   || ', '''|| first_name  || ''', '''||
       last_name     || ''', '''|| email     || ''', '''||
       job_id        || ''', ' || salary     || ', '    ||
       NVL(TO_CHAR(department_id), 'NULL') || ', '||
       NVL(TO_CHAR(manager_id), 'NULL')    || ');'
FROM   employees ORDER BY employee_id;

SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON
```

---

**[8번]** GRANT SELECT 문 생성

```sql
SELECT 'GRANT SELECT ON ' || table_name || ' TO PUBLIC;'
FROM   user_tables
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS','JOBS','LOCATIONS','COUNTRIES')
ORDER BY table_name;
```

---

## Group 3: 홑따옴표 처리

**[9번]** 홑따옴표 표현식 확인

```sql
SELECT ''''            AS q1,   -- 결과: '
       ''''''          AS q2,   -- 결과: ''
       '''X'''         AS q3,   -- 결과: 'X'
       ''''||'ABC'||'''' AS q4, -- 결과: 'ABC'
       'It''s easy'   AS q5    -- 결과: It's easy
FROM   dual;
```

**규칙:** SQL 문자열 내에서 `''` = 홑따옴표 하나 출력.

---

**[10번]** 홑따옴표 안전 처리 INSERT 문

```sql
SELECT 'INSERT INTO dept_copy VALUES (' ||
       department_id   || ', ''' ||
       REPLACE(department_name, '''', '''''') || ''');'
FROM   departments ORDER BY department_id;
```

`REPLACE(name, '''', '''''')`는 데이터 내 홑따옴표를 이중 홑따옴표로 바꾸어 INSERT 문이 깨지지 않도록 한다.

---

**[11번]** 홑따옴표 포함 데이터 처리

```sql
WITH test_data AS (
    SELECT 1 AS id, 'McDonald''s' AS name FROM dual UNION ALL
    SELECT 2, 'O''Brien''s Pub' FROM dual
)
SELECT 'INSERT INTO t VALUES (' || id || ', ''' ||
       REPLACE(name, '''', '''''') || ''');'
FROM   test_data;
```

**결과:**
```
INSERT INTO t VALUES (1, 'McDonald''s');
INSERT INTO t VALUES (2, 'O''Brien''s Pub');
```

실행하면 올바르게 홑따옴표가 포함된 데이터로 삽입된다.

---

## Group 4: 동적 WHERE 절

**[12번]** 단순 동적 WHERE

```sql
COLUMN my_where NEW_VALUE dynamic_where

SELECT NVL('WHERE department_id = ' || '&dept_id', ' ') AS my_where
FROM   dual;

SELECT * FROM employees &dynamic_where;
```

dept_id = 80 입력 시: `WHERE department_id = 80`이 자동 삽입된다.

---

**[13번]** 복합 동적 WHERE (부서 + 입사 연도)

```sql
COLUMN my_where NEW_VALUE dynamic_where

SELECT DECODE('&&dept_no', null,
    DECODE('&&year_no', null, ' ',
        'WHERE EXTRACT(YEAR FROM hire_date) = ' || '&&year_no'),
    DECODE('&&year_no', null,
        'WHERE department_id = ' || '&&dept_no',
        'WHERE department_id = ' || '&&dept_no' ||
        ' AND EXTRACT(YEAR FROM hire_date) = ' || '&&year_no'))
    AS my_where
FROM dual;

SELECT employee_id, last_name, hire_date, department_id
FROM   employees &dynamic_where;
```

**동작 매트릭스:**
| dept_no | year_no | 생성 WHERE |
|---------|---------|-----------|
| null | null | (없음) |
| 80 | null | `WHERE department_id = 80` |
| null | 2005 | `WHERE EXTRACT(YEAR...) = 2005` |
| 80 | 2005 | `WHERE department_id = 80 AND EXTRACT...` |

---

**[14번]** 동적 ORDER BY

```sql
COLUMN sort_col NEW_VALUE order_col

SELECT NVL('&&sort_column', 'employee_id') AS sort_col
FROM   dual;

SELECT employee_id, last_name, salary, department_id
FROM   employees
ORDER BY &order_col;
```

`&&sort_column`에 `salary DESC`를 입력하면 급여 내림차순으로 정렬된다.

---

## Group 5: SPOOL을 이용한 파일 저장

**[15번]** SPOOL로 departments INSERT 스크립트 저장

```sql
SPOOL /tmp/dept_insert.sql

SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0 LINESIZE 200

SELECT 'INSERT INTO departments VALUES (' ||
       department_id || ', ''' ||
       department_name || ''', ' ||
       NVL(TO_CHAR(manager_id), 'NULL') || ', ' ||
       NVL(TO_CHAR(location_id), 'NULL') || ');'
FROM   departments ORDER BY department_id;

SPOOL OFF
SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON
```

생성 파일 `/tmp/dept_insert.sql`을 `@/tmp/dept_insert.sql`로 실행하면 데이터가 삽입된다.

---

**[16번]** ANALYZE 스크립트 SPOOL

```sql
SPOOL /tmp/analyze_tables.sql

SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0

SELECT 'ANALYZE TABLE ' || table_name || ' COMPUTE STATISTICS;'
FROM   user_tables ORDER BY table_name;

SPOOL OFF
SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON

-- 실행: @/tmp/analyze_tables.sql
```

---

## Group 6: 종합 실습

**[17번]** GRANT 스크립트 생성

```sql
SELECT 'GRANT SELECT, INSERT, UPDATE ON ' ||
       table_name || ' TO &&target_user;'
FROM   user_tables ORDER BY table_name;
```

`&&target_user`에 `HR_READONLY`와 같은 사용자명을 입력한다.

---

**[18번]** 부서별 통계 쿼리 생성

```sql
SELECT 'SELECT ' || department_id ||
       ' AS dept_id, COUNT(*), AVG(salary), MAX(salary), MIN(salary)' ||
       ' FROM employees WHERE department_id = ' || department_id || ';'
FROM (
    SELECT DISTINCT department_id
    FROM   employees
    WHERE  department_id IS NOT NULL
    ORDER BY department_id
);
```

---

**[19번]** UNION ALL 행 수 쿼리 생성

```sql
SELECT CASE
    WHEN rownum = 1 THEN
        'SELECT ''' || table_name || ''' AS tname, COUNT(*) AS cnt FROM ' || table_name
    ELSE
        'UNION ALL SELECT ''' || table_name || ''', COUNT(*) FROM ' || table_name
END AS union_query
FROM   user_tables
ORDER BY table_name;
```

이 결과를 SPOOL로 저장 후 실행하면 모든 테이블의 행 수를 한 쿼리로 확인할 수 있다.

---

**[20번]** 부서 80 데이터 마이그레이션 INSERT 문

```sql
SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0 LINESIZE 400

SELECT 'INSERT INTO backup_employees VALUES (' ||
       employee_id          || ', '''           ||
       first_name           || ''', '''         ||
       last_name            || ''', '''         ||
       email                || ''', '''         ||
       NVL(phone_number, 'N/A') || ''', '''     ||
       TO_CHAR(hire_date, 'DD-MON-YYYY') || ''', ''' ||
       job_id               || ''', '           ||
       salary               || ', '             ||
       NVL(TO_CHAR(commission_pct), 'NULL') || ', ' ||
       NVL(TO_CHAR(manager_id), 'NULL')     || ', ' ||
       NVL(TO_CHAR(department_id), 'NULL')  || ');'
FROM   employees
WHERE  department_id = 80
ORDER BY employee_id;

SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON
```

**주요 처리 사항:**
- DATE 타입: `TO_CHAR(hire_date, 'DD-MON-YYYY')` + 홑따옴표로 감싸기
- NUMBER NULL: `NVL(TO_CHAR(commission_pct), 'NULL')`
- VARCHAR2 NULL: `NVL(phone_number, 'N/A')` + 홑따옴표로 감싸기

---

**[21번]** 외래 키 비활성화 스크립트

```sql
SELECT 'ALTER TABLE ' || table_name ||
       ' DISABLE CONSTRAINT ' || constraint_name || ';'
FROM   user_constraints
WHERE  constraint_type = 'R'
  AND  status = 'ENABLED'
ORDER BY table_name, constraint_name;
```

데이터 대량 적재 전에 외래 키를 비활성화하면 성능이 향상된다.

---

**[22번]** 인덱스 REBUILD 스크립트

```sql
SELECT 'ALTER INDEX ' || index_name || ' REBUILD;'
FROM   user_indexes
WHERE  status != 'VALID'
ORDER BY index_name;
```

`REBUILD`: 인덱스를 재구성하여 단편화를 제거하고 성능을 개선한다.

---

**[23번]** DBMS_METADATA로 DDL 추출

```sql
SET LONG 10000
SELECT DBMS_METADATA.GET_DDL('TABLE', 'EMPLOYEES') AS ddl
FROM   dual;
```

`SET LONG 10000`: CLOB/LONG 타입 출력 길이 확대.

---

**[24번]** 인덱스 생성 스크립트

```sql
SELECT 'CREATE INDEX ' || index_name ||
       ' ON ' || table_name || ' (' ||
       (SELECT LISTAGG(column_name, ', ')
               WITHIN GROUP (ORDER BY column_position)
        FROM   user_ind_columns uic
        WHERE  uic.index_name = ui.index_name) || ');'
FROM   user_indexes ui
WHERE  index_type = 'NORMAL'
ORDER BY table_name, index_name;
```

`LISTAGG`: 여러 컬럼을 쉼표로 연결하여 복합 인덱스도 올바르게 생성.

---

**[25번]** 백업 절차 스크립트 생성

```sql
SPOOL /tmp/backup_procedure.sql

SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0

SELECT '-- ===== 백업 시작: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || ' =====' FROM dual;
SELECT 'CREATE TABLE employees_bak_' || TO_CHAR(SYSDATE,'YYYYMMDD') ||
       ' AS SELECT * FROM employees;' FROM dual;
SELECT 'SELECT COUNT(*) AS original_count FROM employees;' FROM dual;
SELECT 'SELECT COUNT(*) AS backup_count FROM employees_bak_' ||
       TO_CHAR(SYSDATE,'YYYYMMDD') || ';' FROM dual;

SPOOL OFF
SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON
```

---

**[26번]** 날짜 포함 동적 보고서 스크립트

```sql
COLUMN report_date NEW_VALUE rpt_date
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') AS report_date FROM dual;

SPOOL /tmp/employee_report_&rpt_date..sql

SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0 LINESIZE 200

SELECT '-- Employee Report: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM dual;
SELECT '-- Generated by: ' || USER FROM dual;

SELECT 'INSERT INTO report_stats VALUES (' ||
       department_id || ', ' || COUNT(*) || ', ' ||
       ROUND(AVG(salary)) || ', ' || MAX(salary) || ');'
FROM   employees
WHERE  department_id IS NOT NULL
GROUP  BY department_id
ORDER  BY department_id;

SPOOL OFF
SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON
```

**파일명 처리:** `&rpt_date..sql` — 점 두 개(`.`)로 변수명 종료와 파일 확장자를 구분.
