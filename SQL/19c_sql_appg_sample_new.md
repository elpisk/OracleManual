# Oracle Database 19c: SQL Workshop
## Appendix G — 고급 스크립트 작성 | SQL 실습 문제

---

> **참고:** 이 실습은 SQL*Plus 또는 SQL Developer의 스크립트 기능이 있는 환경에서 수행하세요.

---

## Group 1: SQL Generating SQL 기본

**[1번]** user_tables에서 각 테이블에 대한 `SELECT COUNT(*)`문을 자동 생성하시오.

```sql
SELECT 'SELECT COUNT(*) AS cnt, ''' || table_name || ''' AS tname FROM ' || table_name || ';'
AS count_script
FROM   user_tables
ORDER BY table_name;
```

---

**[2번]** 각 테이블에 대한 `DROP TABLE ... PURGE` 문을 생성하시오 (user_tables 활용).

```sql
SELECT 'DROP TABLE ' || table_name || ' PURGE;'
AS drop_script
FROM   user_tables
ORDER BY table_name;
```

---

**[3번]** user_tables에서 모든 테이블의 빈 복사본을 만드는 `CREATE TABLE ... AS SELECT ... WHERE 1=2` 문을 생성하시오.

```sql
SELECT 'CREATE TABLE ' || table_name ||
       '_bak AS SELECT * FROM ' || table_name || ' WHERE 1=2;'
AS create_script
FROM   user_tables;
```

---

**[4번]** user_objects에서 현재 사용자의 모든 객체 목록(이름, 타입)을 조회하시오.

```sql
SELECT object_name, object_type, status, last_ddl_time
FROM   user_objects
ORDER BY object_type, object_name;
```

---

**[5번]** user_constraints에서 비활성화된 제약 조건에 대한 `ALTER TABLE ... ENABLE CONSTRAINT ...` 문을 생성하시오.

```sql
SELECT 'ALTER TABLE ' || table_name ||
       ' ENABLE CONSTRAINT ' || constraint_name || ';'
AS enable_script
FROM   user_constraints
WHERE  status = 'DISABLED'
ORDER BY table_name, constraint_name;
```

---

## Group 2: SET 명령어 및 출력 제어

**[6번]** 다음 순서로 스크립트 환경을 설정하고 departments 테이블의 INSERT 문을 생성하시오.

```sql
-- 출력 최소화
SET ECHO     OFF
SET FEEDBACK OFF
SET HEADING  OFF
SET PAGESIZE 0
SET LINESIZE 200

-- INSERT 문 생성
SELECT 'INSERT INTO departments VALUES (' ||
       department_id   || ', ''' ||
       department_name || ''', ' ||
       NVL(TO_CHAR(manager_id), 'NULL')   || ', ' ||
       NVL(TO_CHAR(location_id), 'NULL')  || ');'
FROM   departments
ORDER BY department_id;

-- 환경 복원
SET FEEDBACK ON
SET HEADING  ON
SET PAGESIZE 24
SET ECHO     ON
```

---

**[7번]** employees 테이블의 모든 데이터를 INSERT 문으로 생성하시오 (주요 컬럼만 사용).

```sql
SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0 LINESIZE 300

SELECT 'INSERT INTO employees (employee_id, first_name, last_name, '||
       'email, job_id, salary, department_id, manager_id) VALUES ('||
       employee_id   || ', '''||
       first_name    || ''', '''||
       last_name     || ''', '''||
       email         || ''', '''||
       job_id        || ''', '  ||
       salary        || ', '    ||
       NVL(TO_CHAR(department_id), 'NULL') || ', '||
       NVL(TO_CHAR(manager_id), 'NULL')    || ');'
FROM   employees
ORDER BY employee_id;

SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON
```

---

**[8번]** jobs 테이블의 모든 GRANT SELECT 문을 PUBLIC에 부여하는 스크립트를 생성하시오.

```sql
SELECT 'GRANT SELECT ON ' || table_name || ' TO PUBLIC;'
AS grant_script
FROM   user_tables
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS','JOBS','LOCATIONS','COUNTRIES')
ORDER BY table_name;
```

---

## Group 3: 홑따옴표 처리

**[9번]** 다음 각 표현식의 실제 출력값을 확인하시오.

```sql
SELECT ''''            AS q1,
       ''''''          AS q2,
       '''X'''         AS q3,
       ''''||'ABC'||'''' AS q4,
       'It''s easy'   AS q5
FROM   dual;
-- 결과: ', '', 'X', 'ABC', It's easy
```

---

**[10번]** departments 테이블에서 varchar2 컬럼인 department_name을 홑따옴표로 감싼 INSERT 문을 생성하시오.

```sql
SELECT 'INSERT INTO dept_copy VALUES (' ||
       department_id   || ', ''' ||
       REPLACE(department_name, '''', '''''') || ''');'
       -- REPLACE: 데이터 내 홑따옴표가 있을 경우 이중 처리
AS insert_stmt
FROM   departments
ORDER BY department_id;
```

---

**[11번]** 홑따옴표가 포함된 데이터를 안전하게 INSERT 문으로 생성하는 방법을 확인하시오.

```sql
-- 테스트 데이터 (홑따옴표 포함)
WITH test_data AS (
    SELECT 1 AS id, 'McDonald''s' AS name FROM dual UNION ALL
    SELECT 2, 'O''Brien''s Pub' FROM dual
)
SELECT 'INSERT INTO t VALUES (' || id || ', ''' ||
       REPLACE(name, '''', '''''') || ''');'
AS insert_stmt
FROM   test_data;
-- REPLACE로 홑따옴표 → 이중 홑따옴표 변환
```

---

## Group 4: 동적 WHERE 절

**[12번]** 부서 번호를 입력받아 동적으로 WHERE 절을 생성하는 쿼리를 실행하시오.

```sql
-- SQL*Plus에서 실행
COLUMN my_where NEW_VALUE dynamic_where

SELECT NVL('WHERE department_id = ' || '&dept_id', ' ') AS my_where
FROM   dual;

-- 생성된 WHERE 절 확인
SELECT * FROM employees &dynamic_where;
```

---

**[13번]** 입사 연도와 부서를 모두 입력받아 동적 WHERE 조건을 생성하시오.

```sql
COLUMN my_where NEW_VALUE dynamic_where

SELECT DECODE('&&dept_no', null,
    DECODE('&&year_no', null,
        ' ',
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

---

**[14번]** 동적 ORDER BY를 구현하시오 (컬럼명을 변수로 받음).

```sql
-- SQL*Plus에서: 정렬 컬럼 입력
COLUMN sort_col NEW_VALUE order_col

SELECT NVL('&&sort_column', 'employee_id') AS sort_col
FROM   dual;

SELECT employee_id, last_name, salary, department_id
FROM   employees
ORDER BY &order_col;
```

---

## Group 5: SPOOL을 이용한 파일 저장

**[15번]** SPOOL로 INSERT 스크립트를 파일에 저장하시오.

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

-- 결과 파일 확인
-- ! cat /tmp/dept_insert.sql   (Unix)
-- HOST type /tmp/dept_insert.sql  (Windows)
```

---

**[16번]** 모든 테이블에 대한 ANALYZE 명령어를 SPOOL로 저장하시오.

```sql
SPOOL /tmp/analyze_tables.sql

SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0

SELECT 'ANALYZE TABLE ' || table_name || ' COMPUTE STATISTICS;'
FROM   user_tables
ORDER BY table_name;

SPOOL OFF
SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON

-- 실행
-- @/tmp/analyze_tables.sql
```

---

## Group 6: 종합 실습

**[17번]** 특정 사용자의 모든 테이블에 대해 다른 사용자에게 권한을 부여하는 스크립트를 생성하시오.

```sql
-- 타겟 사용자: &target_user
SELECT 'GRANT SELECT, INSERT, UPDATE ON ' ||
       table_name || ' TO &&target_user;'
AS grant_script
FROM   user_tables
ORDER BY table_name;
```

---

**[18번]** employees 테이블의 각 부서별 통계를 생성하는 동적 스크립트를 작성하시오.

```sql
-- 각 부서에 대한 통계 쿼리 생성
SELECT 'SELECT ' || department_id ||
       ' AS dept_id, COUNT(*), AVG(salary), MAX(salary), MIN(salary)' ||
       ' FROM employees WHERE department_id = ' || department_id || ';'
AS stat_query
FROM (
    SELECT DISTINCT department_id
    FROM   employees
    WHERE  department_id IS NOT NULL
    ORDER BY department_id
);
```

---

**[19번]** user_tables에 존재하는 모든 테이블의 행 수를 한 번에 조회하는 UNION ALL 쿼리를 생성하시오.

```sql
-- UNION ALL 쿼리 생성
SELECT CASE
    WHEN rownum = 1 THEN
        'SELECT ''' || table_name || ''' AS tname, COUNT(*) AS cnt FROM ' || table_name
    ELSE
        'UNION ALL SELECT ''' || table_name || ''', COUNT(*) FROM ' || table_name
END AS union_query
FROM   user_tables
ORDER BY table_name;
```

---

**[20번]** 데이터 마이그레이션 스크립트 생성: 특정 부서(department_id=80)의 직원 데이터를 backup_employees 테이블에 삽입하는 INSERT 문을 생성하시오.

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

---

**[21번]** 모든 외래 키 제약 조건을 비활성화하는 스크립트를 생성하시오.

```sql
SELECT 'ALTER TABLE ' || table_name ||
       ' DISABLE CONSTRAINT ' || constraint_name || ';'
AS disable_fk
FROM   user_constraints
WHERE  constraint_type = 'R'    -- R = Foreign Key
  AND  status = 'ENABLED'
ORDER BY table_name, constraint_name;
```

---

**[22번]** 각 인덱스를 재구성(REBUILD)하는 스크립트를 생성하시오.

```sql
SELECT 'ALTER INDEX ' || index_name || ' REBUILD;'
AS rebuild_index
FROM   user_indexes
WHERE  status != 'VALID'
ORDER BY index_name;
```

---

**[23번]** SQL*Plus에서 특정 테이블의 DDL을 조회하는 방법을 활용하시오.

```sql
-- DBMS_METADATA를 사용하여 DDL 생성
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) AS ddl
FROM   user_tables
WHERE  table_name = 'EMPLOYEES';
```

---

**[24번]** 테이블별 인덱스 생성 스크립트를 자동 생성하시오.

```sql
SELECT 'CREATE INDEX ' || index_name ||
       ' ON ' || table_name || ' (' ||
       (SELECT LISTAGG(column_name, ', ')
               WITHIN GROUP (ORDER BY column_position)
        FROM   user_ind_columns uic
        WHERE  uic.index_name = ui.index_name) || ');'
AS create_index_script
FROM   user_indexes ui
WHERE  index_type = 'NORMAL'
ORDER BY table_name, index_name;
```

---

**[25번]** 전체 스크립트 생성 종합 예제: employees 테이블 백업 절차 스크립트를 생성하시오.

```sql
-- 전체 절차 스크립트 생성
SPOOL /tmp/backup_procedure.sql

SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0

-- 단계 1: 백업 테이블 생성
SELECT '-- ===== 백업 시작: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || ' =====' FROM dual;
SELECT 'CREATE TABLE employees_bak_' || TO_CHAR(SYSDATE,'YYYYMMDD') ||
       ' AS SELECT * FROM employees;' FROM dual;

-- 단계 2: 행 수 확인
SELECT 'SELECT COUNT(*) AS original_count FROM employees;' FROM dual;
SELECT 'SELECT COUNT(*) AS backup_count FROM employees_bak_' ||
       TO_CHAR(SYSDATE,'YYYYMMDD') || ';' FROM dual;

SPOOL OFF
SET FEEDBACK ON HEADING ON PAGESIZE 24 ECHO ON
```

---

**[26번]** SQL*Plus 환경 변수와 동적 WHERE를 활용한 종합 보고서 생성 스크립트를 작성하시오.

```sql
-- 보고서 파일명에 날짜 포함
COLUMN report_date NEW_VALUE rpt_date
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') AS report_date FROM dual;

SPOOL /tmp/employee_report_&rpt_date..sql

SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0 LINESIZE 200

-- 보고서 헤더
SELECT '-- Employee Report: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM dual;
SELECT '-- Generated by: ' || USER FROM dual;

-- 각 부서별 통계 INSERT 문
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
