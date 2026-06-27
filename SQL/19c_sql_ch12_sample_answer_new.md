# Oracle Database 19c: SQL Workshop
## Chapter 12 — 데이터 딕셔너리 뷰 소개 | SQL 실습 문제 모범답안

---

## Group 1. DICTIONARY & USER_OBJECTS 뷰 실습 모범답안 (1~6번)

---

**[1번] 답**

```sql
DESCRIBE DICTIONARY;
-- TABLE_NAME VARCHAR2(128)
-- COMMENTS   VARCHAR2(4000)

SELECT table_name, comments
FROM   dictionary
WHERE  table_name LIKE '%TABLE%'
ORDER BY table_name;
```

예상 결과 (일부):
```
TABLE_NAME                  COMMENTS
--------------------------- ----------------------------------------
ALL_ALL_TABLES              Description of all object and relational...
ALL_TABLES                  Description of relational tables access...
USER_ALL_TABLES             Description of all object and relational...
USER_PART_TABLES            Partitioned tables owned by the user
USER_TABLES                 Description of the user's own relational...
...
```

주요 뷰: USER_TABLES, ALL_TABLES, USER_ALL_TABLES, USER_PART_TABLES, USER_TAB_COMMENTS 등

---

**[2번] 답**

```sql
SELECT object_type, COUNT(*) AS object_count
FROM   user_objects
GROUP BY object_type
ORDER BY object_count DESC;
```

HR 스키마 예상 결과:
```
OBJECT_TYPE   OBJECT_COUNT
------------- ------------
INDEX         19
TABLE         7
TRIGGER       5
SEQUENCE      3
PROCEDURE     2
VIEW          1
...
```

**INDEX**가 가장 많다 (각 PK, UK, FK에 자동 생성된 인덱스 포함).

---

**[3번] 답**

```sql
SELECT object_name, created, last_ddl_time, status
FROM   user_objects
WHERE  object_type = 'TABLE'
ORDER BY object_name;
```

예상 결과:
```
OBJECT_NAME    CREATED      LAST_DDL_TIME  STATUS
-------------- ------------ -------------- -------
COUNTRIES      26-JAN-24    26-JAN-24      VALID
DEPARTMENTS    26-JAN-24    26-JAN-24      VALID
EMPLOYEES      26-JAN-24    26-JAN-24      VALID
JOB_GRADES     26-JAN-24    26-JAN-24      VALID
JOB_HISTORY    26-JAN-24    26-JAN-24      VALID
JOBS           26-JAN-24    26-JAN-24      VALID
LOCATIONS      26-JAN-24    26-JAN-24      VALID
```

---

**[4번] 답**

```sql
SELECT object_name, object_type, status
FROM   user_objects
WHERE  status = 'INVALID';
```

정상 환경에서는 **0 rows** 반환 (모든 객체가 VALID).

**실무 활용 시점:**
- `ALTER TABLE DROP COLUMN` 후 해당 열을 참조하는 뷰가 INVALID로 변경
- 테이블 구조 변경(DDL) 후 의존하는 프로시저, 함수, 패키지가 INVALID가 됨
- 배포 후 점검 스크립트로 활용

---

**[5번] 답**

```sql
SELECT 'USER_OBJECTS' AS source, COUNT(*) AS cnt FROM user_objects
UNION ALL
SELECT 'ALL_OBJECTS',            COUNT(*) FROM all_objects;
```

예상 결과:
```
SOURCE         CNT
-------------- -----
USER_OBJECTS   37
ALL_OBJECTS    3852
```

**차이의 의미:** `ALL_OBJECTS`는 현재 사용자가 접근 권한을 가진 **모든 사용자의 객체**를 포함하므로 훨씬 많다. Oracle 시스템 객체(SYS, SYSTEM 스키마), 공용 동의어(PUBLIC SYNONYM) 등이 포함된다.

---

**[6번] 답**

```sql
SELECT object_name, object_type, last_ddl_time
FROM   user_objects
ORDER BY last_ddl_time DESC
FETCH FIRST 5 ROWS ONLY;
```

`LAST_DDL_TIME`이 최근인 상위 5개 객체를 내림차순으로 조회한다.

---

## Group 2. USER_TABLES & USER_TAB_COLUMNS 실습 모범답안 (7~12번)

---

**[7번] 답**

```sql
DESCRIBE user_tables;
-- 주요 컬럼: TABLE_NAME, TABLESPACE_NAME, NUM_ROWS, BLOCKS, STATUS, READ_ONLY 등

SELECT table_name FROM user_tables ORDER BY table_name;
```

HR 스키마 테이블:
```
COUNTRIES
DEPARTMENTS
EMPLOYEES
JOB_GRADES
JOB_HISTORY
JOBS
LOCATIONS
```
(총 7개)

---

**[8번] 답**

```sql
SELECT column_name, data_type, data_length,
       data_precision, data_scale, nullable, data_default
FROM   user_tab_columns
WHERE  table_name = 'EMPLOYEES'
ORDER BY column_id;
```

예상 결과 (일부):
```
COLUMN_NAME     DATA_TYPE  LENGTH  PREC  SCALE  NULLABLE  DEFAULT
--------------- ---------- ------- ----- ------ --------- -------
EMPLOYEE_ID     NUMBER     22      6     0      N
FIRST_NAME      VARCHAR2   20            N      Y
LAST_NAME       VARCHAR2   25            N      N
EMAIL           VARCHAR2   25            N      N
PHONE_NUMBER    VARCHAR2   20            N      Y
HIRE_DATE       DATE       7             N      N
JOB_ID          VARCHAR2   10            N      N
SALARY          NUMBER     22      8     2      Y
COMMISSION_PCT  NUMBER     22      2     2      Y
MANAGER_ID      NUMBER     22      6     0      Y
DEPARTMENT_ID   NUMBER     22      4     0      Y
```

- **NOT NULL 열 (nullable = 'N'):** EMPLOYEE_ID, LAST_NAME, EMAIL, HIRE_DATE, JOB_ID → 5개
- **기본값 있는 열:** 없음 (HR 기본 스키마 기준)
- **NUMBER 타입 열:** EMPLOYEE_ID, SALARY, COMMISSION_PCT, MANAGER_ID, DEPARTMENT_ID → 5개

---

**[9번] 답**

```sql
SELECT table_name, column_name, data_length
FROM   user_tab_columns
WHERE  data_type = 'VARCHAR2'
ORDER BY data_length DESC
FETCH FIRST 5 ROWS ONLY;
```

예상 결과:
```
TABLE_NAME   COLUMN_NAME    DATA_LENGTH
------------ -------------- -----------
EMPLOYEES    PHONE_NUMBER   20  (또는 다른 열)
JOBS         JOB_TITLE      35
DEPARTMENTS  DEPARTMENT_NAME 30
...
```

---

**[10번] 답**

```sql
SELECT table_name, COUNT(*) AS col_count
FROM   user_tab_columns
GROUP BY table_name
ORDER BY col_count DESC;
```

예상 결과:
```
TABLE_NAME   COL_COUNT
------------ ---------
EMPLOYEES    11
JOB_HISTORY  6
LOCATIONS    6
DEPARTMENTS  4
JOBS         4
COUNTRIES    3
JOB_GRADES   6
```

EMPLOYEES가 가장 많은 열(11개)을 가진다.

---

**[11번] 답**

```sql
SELECT table_name,
       COUNT(*) AS total_cols,
       SUM(CASE WHEN nullable = 'N' THEN 1 ELSE 0 END) AS notnull_cols,
       ROUND(SUM(CASE WHEN nullable = 'N' THEN 1 ELSE 0 END) / COUNT(*) * 100) AS notnull_pct
FROM   user_tab_columns
GROUP BY table_name
ORDER BY notnull_pct DESC;
```

예상 결과 (일부):
```
TABLE_NAME   TOTAL  NOTNULL  NOTNULL_PCT
------------ ------ -------- -----------
JOB_GRADES   6      6        100
JOBS         4      4        100
COUNTRIES    3      3        100
DEPARTMENTS  4      2        50
EMPLOYEES    11     5        45
...
```

JOB_GRADES, JOBS, COUNTRIES 등이 모든 열이 NOT NULL인 가장 엄격한 테이블이다.

---

**[12번] 답**

```sql
SELECT t.table_name,
       t.status,
       COUNT(c.column_name) AS col_count
FROM   user_tables      t
JOIN   user_tab_columns c ON t.table_name = c.table_name
GROUP BY t.table_name, t.status
ORDER BY col_count DESC;
```

---

## Group 3. USER_CONSTRAINTS & USER_CONS_COLUMNS 실습 모범답안 (13~18번)

---

**[13번] 답**

```sql
DESCRIBE user_constraints;

SELECT constraint_name, constraint_type,
       search_condition, r_constraint_name,
       delete_rule, status
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES'
ORDER BY constraint_type;
```

EMPLOYEES 테이블 제약 조건 요약 (HR 스키마 기준):

| 유형 | 개수 | 예시 |
|------|------|------|
| C (CHECK/NOT NULL) | 7개 | EMP_LAST_NAME_NN, EMP_EMAIL_NN 등 |
| P (PRIMARY KEY) | 1개 | EMP_EMP_ID_PK |
| R (FOREIGN KEY) | 3개 | EMP_DEPT_FK, EMP_JOB_FK, EMP_MANAGER_FK |
| U (UNIQUE) | 1개 | EMP_EMAIL_UK |

---

**[14번] 답**

```sql
SELECT constraint_name, column_name, position
FROM   user_cons_columns
WHERE  table_name = 'EMPLOYEES'
ORDER BY constraint_name, position;
```

예상 결과 (일부):
```
CONSTRAINT_NAME   COLUMN_NAME    POSITION
----------------- -------------- --------
EMP_DEPT_FK       DEPARTMENT_ID  1
EMP_EMAIL_UK      EMAIL          1
EMP_EMP_ID_PK     EMPLOYEE_ID    1
EMP_JOB_FK        JOB_ID         1
EMP_LAST_NAME_NN  LAST_NAME      1
EMP_MANAGER_FK    MANAGER_ID     1
...
```

---

**[15번] 답**

```sql
SELECT c.constraint_name,
       c.constraint_type,
       c.status,
       cc.column_name,
       c.search_condition
FROM   user_constraints  c
JOIN   user_cons_columns cc
    ON c.constraint_name = cc.constraint_name
   AND c.table_name      = cc.table_name
WHERE  c.table_name = 'EMPLOYEES'
ORDER BY c.constraint_type, cc.position;
```

예상 결과 (C 타입 일부):
```
CONSTRAINT_NAME    TYPE  STATUS   COLUMN        SEARCH_CONDITION
------------------ ----- -------- ------------- ----------------------------
EMP_EMAIL_NN       C     ENABLED  EMAIL         "EMAIL" IS NOT NULL
EMP_HIRE_DATE_NN   C     ENABLED  HIRE_DATE     "HIRE_DATE" IS NOT NULL
EMP_JOB_NN         C     ENABLED  JOB_ID        "JOB_ID" IS NOT NULL
EMP_LAST_NAME_NN   C     ENABLED  LAST_NAME     "LAST_NAME" IS NOT NULL
EMP_SALARY_MIN     C     ENABLED  SALARY        salary > 0
EMP_EMP_ID_PK      P     ENABLED  EMPLOYEE_ID
EMP_EMAIL_UK       U     ENABLED  EMAIL
EMP_DEPT_FK        R     ENABLED  DEPARTMENT_ID
...
```

---

**[16번] 답**

```sql
SELECT c.table_name       AS 자식_테이블,
       cc.column_name     AS FK_열,
       pc.table_name      AS 부모_테이블,
       pcc.column_name    AS PK_열,
       c.delete_rule      AS 삭제_규칙
FROM   user_constraints  c
JOIN   user_cons_columns cc
    ON c.constraint_name = cc.constraint_name AND c.table_name = cc.table_name
JOIN   user_constraints  pc
    ON c.r_constraint_name = pc.constraint_name
JOIN   user_cons_columns pcc
    ON pc.constraint_name = pcc.constraint_name AND pc.table_name = pcc.table_name
WHERE  c.constraint_type = 'R'
ORDER BY c.table_name;
```

예상 결과:
```
자식_테이블  FK_열          부모_테이블  PK_열          삭제_규칙
------------ -------------- ------------ -------------- ---------
DEPARTMENTS  LOCATION_ID    LOCATIONS    LOCATION_ID    NO ACTION
DEPARTMENTS  MANAGER_ID     EMPLOYEES    EMPLOYEE_ID    NO ACTION
EMPLOYEES    DEPARTMENT_ID  DEPARTMENTS  DEPARTMENT_ID  NO ACTION
EMPLOYEES    JOB_ID         JOBS         JOB_ID         NO ACTION
EMPLOYEES    MANAGER_ID     EMPLOYEES    EMPLOYEE_ID    NO ACTION
JOB_HISTORY  DEPARTMENT_ID  DEPARTMENTS  DEPARTMENT_ID  NO ACTION
JOB_HISTORY  EMPLOYEE_ID    EMPLOYEES    EMPLOYEE_ID    NO ACTION
JOB_HISTORY  JOB_ID         JOBS         JOB_ID         NO ACTION
LOCATIONS    COUNTRY_ID     COUNTRIES    COUNTRY_ID     NO ACTION
```

> EMPLOYEES.MANAGER_ID → EMPLOYEES.EMPLOYEE_ID: **자기 참조(self-referencing) FK**

---

**[17번] 답**

```sql
SELECT t.table_name
FROM   user_tables t
WHERE  NOT EXISTS (
    SELECT 1 FROM user_constraints c
    WHERE  c.table_name = t.table_name
    AND    c.constraint_type = 'P'
);
```

HR 스키마에서 PRIMARY KEY 없는 테이블:
```
TABLE_NAME
----------
JOB_GRADES
```

> JOB_GRADES 테이블은 PRIMARY KEY 없이 grade 범위(LOWEST_SAL, HIGHEST_SAL)로만 구성.

---

**[18번] 답**

```sql
SELECT table_name, constraint_name, search_condition
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES'
AND    constraint_type = 'C'
ORDER BY constraint_name;
```

**NOT NULL과 CHECK 구분:**
- `"COLUMN_NAME" IS NOT NULL` 형식 → **NOT NULL** 제약 조건
- `salary > 0` 등 조건식 → **CHECK** 제약 조건

```sql
-- 더 명확하게 구분하는 방법
SELECT constraint_name,
       CASE WHEN search_condition LIKE '%IS NOT NULL%'
            THEN 'NOT NULL'
            ELSE 'CHECK'
       END AS actual_type,
       search_condition
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES'
AND    constraint_type = 'C';
```

---

## Group 4. 주석(COMMENT) 실습 모범답안 (19~24번)

---

**[19번] 답**

```sql
COMMENT ON TABLE employees
IS '인사 관리 시스템 - 전체 사원 정보 저장 테이블';

COMMENT ON COLUMN employees.employee_id
IS '사원 고유 식별번호 (기본 키)';

COMMENT ON COLUMN employees.first_name
IS '사원 이름 (영문)';

COMMENT ON COLUMN employees.salary
IS '월 기본급 (단위: USD)';
-- Comment created. (4회)
```

---

**[20번] 답**

```sql
SELECT table_name, table_type, comments
FROM   user_tab_comments
WHERE  table_name = 'EMPLOYEES';
```

예상 결과:
```
TABLE_NAME  TABLE_TYPE  COMMENTS
----------- ----------- ------------------------------------
EMPLOYEES   TABLE       인사 관리 시스템 - 전체 사원 정보 저장 테이블
```

---

**[21번] 답**

```sql
SELECT column_name, comments
FROM   user_col_comments
WHERE  table_name = 'EMPLOYEES'
ORDER BY column_name;
```

예상 결과:
```
COLUMN_NAME     COMMENTS
--------------- --------------------------------
COMMISSION_PCT  (null)
DEPARTMENT_ID   (null)
EMAIL           (null)
EMPLOYEE_ID     사원 고유 식별번호 (기본 키)
FIRST_NAME      사원 이름 (영문)
HIRE_DATE       (null)
JOB_ID          (null)
LAST_NAME       (null)
MANAGER_ID      (null)
PHONE_NUMBER    (null)
SALARY          월 기본급 (단위: USD)
```

**주석이 없는 열의 COMMENTS 컬럼 값:** `NULL`

---

**[22번] 답**

```sql
COMMENT ON TABLE departments IS '부서 정보 테이블 - 회사 전체 부서 목록';
COMMENT ON COLUMN departments.department_id IS '부서 고유 식별번호';
COMMENT ON COLUMN departments.department_name IS '부서 정식 명칭';

-- 주석 있는 테이블만 조회
SELECT table_name, comments
FROM   user_tab_comments
WHERE  comments IS NOT NULL;
```

예상 결과:
```
TABLE_NAME   COMMENTS
------------ ------------------------------------
EMPLOYEES    인사 관리 시스템 - 전체 사원 정보 저장 테이블
DEPARTMENTS  부서 정보 테이블 - 회사 전체 부서 목록
```

---

**[23번] 답**

```sql
SELECT 'USER_TAB_COMMENTS' AS view_name, COUNT(*) AS cnt
FROM   user_tab_comments
UNION ALL
SELECT 'ALL_TAB_COMMENTS', COUNT(*)
FROM   all_tab_comments;
```

예상 결과:
```
VIEW_NAME           CNT
------------------- -----
USER_TAB_COMMENTS   7
ALL_TAB_COMMENTS    2384
```

**해석:** `USER_TAB_COMMENTS`는 자신(HR)의 7개 테이블만, `ALL_TAB_COMMENTS`는 SYS, SYSTEM 등 Oracle 시스템 테이블 포함 수천 개의 테이블 주석을 반환한다.

---

**[24번] 답**

```sql
-- 주석 삭제 (빈 문자열)
COMMENT ON TABLE employees IS '';
COMMENT ON COLUMN employees.employee_id IS '';
COMMENT ON COLUMN employees.first_name IS '';
COMMENT ON COLUMN employees.salary IS '';

-- 삭제 확인
SELECT table_name, comments
FROM   user_tab_comments
WHERE  table_name = 'EMPLOYEES';
```

예상 결과:
```
TABLE_NAME  TABLE_TYPE  COMMENTS
----------- ----------- --------
EMPLOYEES   TABLE       (null)
```

> **확인:** 빈 문자열(`''`)을 입력하면 주석이 NULL로 변경된다 (삭제와 동일).

---

## Group 5. 종합 활용 실습 모범답안 (25~30번)

---

**[25번] 답**

```sql
SELECT t.table_name,
       t_col.col_count,
       NVL(t_con.constraint_count, 0) AS constraint_count,
       ROUND(NVL(nn.notnull_col, 0) * 100 / t_col.col_count) AS notnull_pct
FROM   user_tables t
JOIN   (SELECT table_name, COUNT(*) AS col_count
        FROM   user_tab_columns GROUP BY table_name) t_col
    ON t.table_name = t_col.table_name
LEFT JOIN (SELECT table_name, COUNT(DISTINCT constraint_name) AS constraint_count
           FROM   user_constraints GROUP BY table_name) t_con
    ON t.table_name = t_con.table_name
LEFT JOIN (SELECT table_name, COUNT(*) AS notnull_col
           FROM   user_tab_columns WHERE nullable = 'N' GROUP BY table_name) nn
    ON t.table_name = nn.table_name
ORDER BY t.table_name;
```

예상 결과 (일부):
```
TABLE_NAME   COL_COUNT  CONSTRAINT_COUNT  NOTNULL_PCT
------------ ---------- ----------------- -----------
COUNTRIES    3          2                 100
DEPARTMENTS  4          5                 50
EMPLOYEES    11         12                45
JOBS         4          3                 100
JOB_GRADES   6          0                 100
JOB_HISTORY  6          5                 100
LOCATIONS    6          4                 33
```

---

**[26번] 답**

```sql
SELECT table_name, column_id, data_type, nullable
FROM   user_tab_columns
WHERE  column_name = 'DEPARTMENT_ID'
ORDER BY table_name;
```

예상 결과:
```
TABLE_NAME   COLUMN_ID  DATA_TYPE  NULLABLE
------------ ---------- ---------- --------
DEPARTMENTS  1          NUMBER     N
EMPLOYEES    11         NUMBER     Y
JOB_HISTORY  6          NUMBER     N
```

- DEPARTMENTS: `department_id` → NOT NULL (기본 키)
- EMPLOYEES: `department_id` → NULL 허용 (외래 키, 부서 없는 사원 가능)
- JOB_HISTORY: `department_id` → NOT NULL

---

**[27번] 답**

```sql
SELECT table_name, column_name, data_type, nullable
FROM   user_tab_columns
WHERE  column_name LIKE '%DATE%'
ORDER BY table_name, column_name;
```

예상 결과:
```
TABLE_NAME   COLUMN_NAME  DATA_TYPE  NULLABLE
------------ ------------ ---------- --------
EMPLOYEES    HIRE_DATE    DATE       N
JOB_HISTORY  END_DATE     DATE       N
JOB_HISTORY  START_DATE   DATE       N
```

---

**[28번] 답**

```sql
SELECT c.constraint_name,
       CASE c.constraint_type
           WHEN 'P' THEN 'PRIMARY KEY'
           WHEN 'U' THEN 'UNIQUE'
           WHEN 'R' THEN 'FOREIGN KEY'
           WHEN 'C' THEN
               CASE WHEN c.search_condition LIKE '%IS NOT NULL%'
                    THEN 'NOT NULL'
                    ELSE 'CHECK'
               END
       END AS constraint_desc,
       cc.column_name,
       c.search_condition,
       pc.table_name AS ref_table,
       c.delete_rule,
       c.status
FROM   user_constraints  c
JOIN   user_cons_columns cc  ON c.constraint_name  = cc.constraint_name  AND c.table_name = cc.table_name
LEFT JOIN user_constraints  pc  ON c.r_constraint_name = pc.constraint_name
WHERE  c.table_name = 'EMPLOYEES'
ORDER BY c.constraint_type, cc.position;
```

이 쿼리는 EMPLOYEES 테이블의 **모든 제약 조건을 사람이 읽기 쉬운 형태**로 변환하여 보여준다:
- `CASE` 식으로 P/U/R/C → 실제 제약 조건 이름으로 변환
- NOT NULL과 CHECK를 구분
- FK의 경우 참조 테이블(ref_table)도 표시

---

**[29번] 답**

```sql
SELECT object_type,
       COUNT(*) AS cnt,
       MIN(created)        AS oldest,
       MAX(last_ddl_time)  AS latest_change
FROM   user_objects
GROUP BY object_type
ORDER BY cnt DESC;
```

예상 결과:
```
OBJECT_TYPE  CNT  OLDEST       LATEST_CHANGE
------------ ---- ------------ -------------
INDEX        19   26-JAN-2024  26-JAN-2024
TABLE        7    26-JAN-2024  26-JAN-2024
TRIGGER      5    26-JAN-2024  26-JAN-2024
SEQUENCE     3    26-JAN-2024  26-JAN-2024
PROCEDURE    2    26-JAN-2024  26-JAN-2024
VIEW         1    26-JAN-2024  26-JAN-2024
```

---

**[30번] 답**

```sql
-- Step 1: EMPLOYEES PK 이름 확인
SELECT constraint_name
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES'
AND    constraint_type = 'P';
-- 결과: EMP_EMP_ID_PK

-- Step 2: 자식 테이블 조회
SELECT c.table_name      AS 자식_테이블,
       cc.column_name    AS FK_열,
       c.constraint_name AS FK_이름,
       c.delete_rule     AS 삭제_규칙
FROM   user_constraints  c
JOIN   user_cons_columns cc ON c.constraint_name = cc.constraint_name AND c.table_name = cc.table_name
WHERE  c.r_constraint_name = (
    SELECT constraint_name FROM user_constraints
    WHERE  table_name = 'EMPLOYEES' AND constraint_type = 'P'
)
ORDER BY c.table_name;
```

예상 결과:
```
자식_테이블  FK_열        FK_이름          삭제_규칙
------------ ------------ ---------------- ---------
DEPARTMENTS  MANAGER_ID   DEPT_MGR_FK      NO ACTION
EMPLOYEES    MANAGER_ID   EMP_MANAGER_FK   NO ACTION
JOB_HISTORY  EMPLOYEE_ID  JHIST_EMP_FK     NO ACTION
```

**분석:**
- DEPARTMENTS.MANAGER_ID → EMPLOYEES (부서 관리자는 사원이어야 함)
- EMPLOYEES.MANAGER_ID → EMPLOYEES (관리자도 사원 — 자기 참조)
- JOB_HISTORY.EMPLOYEE_ID → EMPLOYEES (직무 이력은 사원에 속함)

EMPLOYEES는 부모 테이블이자 자식 테이블(자기 참조)인 **이중 역할** 테이블이다.
