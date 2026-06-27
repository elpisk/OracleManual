# Oracle Database 19c: SQL Workshop
## Chapter 15 — 스키마 객체 관리 | SQL 실습 모범답안

---

## Group 1: 제약 조건 추가 & 삭제

**[1번]**
```sql
CREATE TABLE dept2 AS SELECT * FROM departments;
CREATE TABLE emp2  AS SELECT * FROM employees;

DESCRIBE dept2;
DESCRIBE emp2;
```

`AS SELECT`로 생성하면 데이터는 복사되지만 제약 조건(PK, FK, NOT NULL 제외)은 복사되지 않음.

---

**[2번]**
```sql
ALTER TABLE dept2 MODIFY department_id PRIMARY KEY;

SELECT constraint_name, constraint_type, status
FROM   user_constraints
WHERE  table_name = 'DEPT2';
```

결과: `SYS_Cxxxxxxxx  P  ENABLED` 형식으로 자동 생성된 이름의 PK 확인.

---

**[3번]**
```sql
-- 1. PK 추가
ALTER TABLE emp2
ADD CONSTRAINT emp2_pk PRIMARY KEY (employee_id);

-- 2. FK 추가 (ON DELETE SET NULL)
ALTER TABLE emp2
ADD CONSTRAINT emp2_dept_fk
    FOREIGN KEY (department_id)
    REFERENCES dept2(department_id)
    ON DELETE SET NULL;

-- 3. CHECK 추가
ALTER TABLE emp2
ADD CONSTRAINT emp2_sal_ck CHECK (salary > 0);

-- 확인
SELECT constraint_name, constraint_type, status, delete_rule
FROM   user_constraints
WHERE  table_name = 'EMP2'
ORDER BY constraint_name;
```

결과: `EMP2_DEPT_FK (R, SET NULL)`, `EMP2_PK (P)`, `EMP2_SAL_CK (C)` 확인.

---

**[4번]**
```sql
ALTER TABLE emp2
ADD CONSTRAINT emp2_mgr_fk
    FOREIGN KEY (manager_id)
    REFERENCES emp2(employee_id);

-- 자기 참조 확인: manager_id = 100인 직원
SELECT employee_id, manager_id
FROM   emp2
WHERE  manager_id = 100
FETCH FIRST 5 ROWS ONLY;
```

employee_id = 100인 행이 emp2에 있으므로 FK 참조 유효.

---

**[5번]**
```sql
-- 삭제 전 확인
SELECT constraint_name FROM user_constraints WHERE table_name = 'EMP2';

-- 삭제
ALTER TABLE emp2 DROP CONSTRAINT emp2_sal_ck;

-- 삭제 후 확인
SELECT constraint_name FROM user_constraints WHERE table_name = 'EMP2';
-- emp2_sal_ck 사라짐
```

---

**[6번]**
```sql
ALTER TABLE dept2 DROP PRIMARY KEY CASCADE;

-- emp2의 FK 확인
SELECT constraint_name, constraint_type, status
FROM   user_constraints
WHERE  table_name = 'EMP2' AND constraint_name = 'EMP2_DEPT_FK';
-- no rows selected → CASCADE로 FK도 삭제됨
```

`DROP PRIMARY KEY CASCADE`: dept2의 PK와 emp2의 emp2_dept_fk가 함께 삭제됨.

---

## Group 2: 제약 조건 비활성화·활성화·이름 변경

**[7번]**
```sql
-- PK, FK 재추가
ALTER TABLE dept2 ADD CONSTRAINT dept2_pk PRIMARY KEY (department_id);
ALTER TABLE emp2  ADD CONSTRAINT emp2_dept_fk
    FOREIGN KEY (department_id) REFERENCES dept2(department_id) ON DELETE SET NULL;

-- FK 비활성화
ALTER TABLE emp2 DISABLE CONSTRAINT emp2_dept_fk;

-- 상태 확인
SELECT constraint_name, status
FROM   user_constraints
WHERE  table_name = 'EMP2' AND constraint_name = 'EMP2_DEPT_FK';
-- EMP2_DEPT_FK  DISABLED
```

---

**[8번]**
```sql
-- FK 비활성화 상태에서 무효 FK 값 삽입
INSERT INTO emp2 (employee_id, last_name, email, hire_date, job_id, department_id)
VALUES (500, 'TestEmp', 'TESTEMP', SYSDATE, 'IT_PROG', 9999);
-- 1 row created. (제약 비활성화 상태이므로 성공)

SELECT employee_id, department_id FROM emp2 WHERE employee_id = 500;

ROLLBACK;
```

---

**[9번]**
```sql
-- 먼저 emp2에 고아 데이터가 없어야 함 (ROLLBACK으로 제거됨)
ALTER TABLE emp2 ENABLE CONSTRAINT emp2_dept_fk;

-- 확인
SELECT constraint_name, status
FROM   user_constraints
WHERE  table_name = 'EMP2' AND constraint_name = 'EMP2_DEPT_FK';
-- EMP2_DEPT_FK  ENABLED
```

활성화 성공 조건: emp2의 모든 department_id 값이 dept2에 존재해야 함.  
고아 데이터가 있으면 `ORA-02298: parent keys not found` 오류.

---

**[10번]**
```sql
ALTER TABLE dept2 RENAME TO dept_backup;
ALTER TABLE emp2  RENAME TO emp_backup;

SELECT table_name FROM user_tables
WHERE  table_name IN ('DEPT_BACKUP','EMP_BACKUP');

-- 원래 이름으로 복원
ALTER TABLE dept_backup RENAME TO dept2;
ALTER TABLE emp_backup  RENAME TO emp2;
```

---

**[11번]**
```sql
ALTER TABLE emp2 RENAME COLUMN phone_number TO phone;

DESCRIBE emp2;
-- PHONE 컬럼명으로 변경 확인

-- 복원
ALTER TABLE emp2 RENAME COLUMN phone TO phone_number;
```

---

**[12번]**
```sql
-- 현재 제약 이름 확인
SELECT constraint_name FROM user_constraints
WHERE  table_name = 'DEPT2' AND constraint_type = 'P';

-- 이름 변경 (현재 이름이 SYS_Cxxxxxxxx인 경우)
ALTER TABLE dept2 RENAME CONSTRAINT dept2_pk TO dept2_id_pk;

-- 변경 후 확인
SELECT constraint_name FROM user_constraints
WHERE  table_name = 'DEPT2' AND constraint_type = 'P';
-- DEPT2_ID_PK
```

---

## Group 3: CASCADE CONSTRAINTS & 지연 제약

**[13번]**
```sql
CREATE TABLE t_parent (pk_id NUMBER PRIMARY KEY, val VARCHAR2(50));
CREATE TABLE t_child  (fk_id NUMBER, val VARCHAR2(50),
                       CONSTRAINT tc_fk FOREIGN KEY(fk_id)
                       REFERENCES t_parent(pk_id));

-- 1. CASCADE CONSTRAINTS 없이 시도
ALTER TABLE t_parent DROP COLUMN pk_id;
-- ORA-12992: cannot drop parent key column

-- 2. CASCADE CONSTRAINTS로 삭제
ALTER TABLE t_parent DROP COLUMN pk_id CASCADE CONSTRAINTS;

-- 3. t_child FK 확인
SELECT constraint_name FROM user_constraints WHERE table_name = 'T_CHILD';
-- no rows selected → tc_fk가 삭제됨
```

---

**[14번]**
```sql
-- ON DELETE SET NULL 확인
DELETE FROM dept2 WHERE department_id = 10;
-- dept2에서 department_id=10 삭제

SELECT employee_id, last_name, department_id
FROM   emp2
WHERE  employee_id IN (
    SELECT employee_id FROM employees WHERE department_id = 10
);
-- department_id가 NULL로 변경됨 (SET NULL 동작)

ROLLBACK;
```

---

**[15번]**
```sql
ALTER TABLE dept2
ADD CONSTRAINT dept2_defer_pk PRIMARY KEY (department_id)
DEFERRABLE INITIALLY DEFERRED;

-- 중복 PK 삽입 (오류 없이 성공)
INSERT INTO dept2 (department_id, department_name)
VALUES (10, 'Dup Test');
-- 1 row created (DEFERRED이므로 즉시 검사 안 함)

-- COMMIT 시 오류
COMMIT;
-- ORA-00001: unique constraint (HR.DEPT2_DEFER_PK) violated

ROLLBACK;
```

---

**[16번]**
```sql
-- dept2_defer_pk 삭제 후 IMMEDIATELY 제약 추가
ALTER TABLE dept2 DROP CONSTRAINT dept2_defer_pk;

ALTER TABLE dept2
ADD CONSTRAINT dept2_imm_pk PRIMARY KEY (department_id)
DEFERRABLE INITIALLY IMMEDIATE;

-- 중복 INSERT 시도 → INSERT 시점에 즉시 오류
INSERT INTO dept2 (department_id, department_name)
VALUES (10, 'Dup Test2');
-- ORA-00001: unique constraint 위반 → INSERT 시점에 발생
```

---

**[17번]**
```sql
-- 현재 트랜잭션만 DEFERRED로 변경
SET CONSTRAINTS dept2_imm_pk DEFERRED;

-- 중복 INSERT 성공 (DEFERRED 상태이므로)
INSERT INTO dept2 (department_id, department_name)
VALUES (10, 'Deferred Test');
-- 1 row created

-- COMMIT 시 오류
COMMIT;
-- ORA-00001: unique constraint 위반 → COMMIT 시점에 발생

ROLLBACK;
```

---

**[18번]**
```sql
SELECT constraint_name, constraint_type,
       status, validated, deferrable, deferred
FROM   user_constraints
WHERE  table_name = 'DEPT2'
ORDER BY constraint_name;
```

| 컬럼 | 의미 |
|------|------|
| `STATUS` | ENABLED/DISABLED — 현재 활성화 여부 |
| `VALIDATED` | VALIDATED/NOT VALIDATED — 기존 데이터 검사 여부 |
| `DEFERRABLE` | DEFERRABLE/NOT DEFERRABLE — 지연 가능 여부 |
| `DEFERRED` | IMMEDIATE/DEFERRED — 현재 검사 시점 |

---

## Group 4: 임시 테이블

**[19번]**
```sql
CREATE GLOBAL TEMPORARY TABLE tmp_order_staging
    (order_id   NUMBER,
     product_id NUMBER,
     quantity   NUMBER,
     unit_price NUMBER(10,2))
ON COMMIT DELETE ROWS;

SELECT table_name, temporary, duration
FROM   user_tables
WHERE  table_name = 'TMP_ORDER_STAGING';
-- TEMPORARY=Y, DURATION=SYS$TRANSACTION
```

---

**[20번]**
```sql
INSERT INTO tmp_order_staging VALUES (1001, 301, 5, 29.99);
INSERT INTO tmp_order_staging VALUES (1001, 302, 2, 49.99);
INSERT INTO tmp_order_staging VALUES (1002, 301, 1, 29.99);

-- COMMIT 전: 3건 조회됨
SELECT * FROM tmp_order_staging;  -- 3 rows

COMMIT;

-- COMMIT 후: ON COMMIT DELETE ROWS → 0건
SELECT * FROM tmp_order_staging;  -- 0 rows (no rows selected)
```

---

**[21번]**
```sql
CREATE GLOBAL TEMPORARY TABLE tmp_session_log
    (log_time TIMESTAMP DEFAULT SYSTIMESTAMP,
     log_msg  VARCHAR2(200))
ON COMMIT PRESERVE ROWS;

INSERT INTO tmp_session_log (log_msg) VALUES ('Start process');
COMMIT;
INSERT INTO tmp_session_log (log_msg) VALUES ('Step 1 done');
COMMIT;

-- COMMIT 2번 후에도 데이터 유지
SELECT * FROM tmp_session_log;  -- 2 rows
```

`ON COMMIT PRESERVE ROWS`: COMMIT 후에도 세션 종료까지 데이터 유지.

---

**[22번]**
```sql
CREATE PRIVATE TEMPORARY TABLE ORA$PTT_calc_temp
    (calc_id   NUMBER,
     calc_val  NUMBER(15,4),
     calc_note VARCHAR2(100))
ON COMMIT DROP DEFINITION;

INSERT INTO ORA$PTT_calc_temp VALUES (1, 3.14159, 'Pi value');
SELECT * FROM ORA$PTT_calc_temp;  -- 1 row

COMMIT;

SELECT * FROM ORA$PTT_calc_temp;
-- ORA-00942: table or view does not exist
-- ON COMMIT DROP DEFINITION → COMMIT 시 테이블 정의까지 삭제
```

---

**[23번]**
```sql
CREATE PRIVATE TEMPORARY TABLE ORA$PTT_sess_work
    (row_id   NUMBER,
     row_data VARCHAR2(200))
ON COMMIT PRESERVE DEFINITION;

INSERT INTO ORA$PTT_sess_work VALUES (1, 'First row');
COMMIT;

-- COMMIT 후에도 테이블 정의 유지 (데이터는 삭제됨)
SELECT * FROM ORA$PTT_sess_work;
-- no rows selected (데이터 삭제됨, 하지만 테이블은 존재)
```

`ON COMMIT PRESERVE DEFINITION`: COMMIT 후 데이터는 삭제, 테이블 정의는 세션 종료까지 유지.

---

**[24번]**
```sql
SELECT table_name, temporary, duration
FROM   user_tables
WHERE  temporary = 'Y'
ORDER BY table_name;
```

| DURATION 값 | 의미 |
|-------------|------|
| `SYS$TRANSACTION` | `ON COMMIT DELETE ROWS` — COMMIT 시 데이터 삭제 |
| `SYS$SESSION` | `ON COMMIT PRESERVE ROWS` — 세션 종료 시 데이터 삭제 |

---

## Group 5: 외부 테이블 & 정리

**[25번]**
```sql
-- DBA 권한 계정으로 실행
CREATE OR REPLACE DIRECTORY ext_data_dir
AS '/home/oracle/ext_data';

GRANT READ ON DIRECTORY ext_data_dir TO hr;

-- 확인
SELECT directory_name, directory_path
FROM   all_directories
WHERE  directory_name = 'EXT_DATA_DIR';
```

**참고:** 실제 경로가 OS에 존재해야 하며 Oracle 서버 프로세스가 읽기 권한을 가져야 함.

---

**[26번]**
```sql
CREATE TABLE emp_ext_loader
    (employee_id NUMBER(6),
     last_name   VARCHAR2(25),
     salary      NUMBER(8,2))
ORGANIZATION EXTERNAL
(
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY ext_data_dir
    ACCESS PARAMETERS
    (
        RECORDS DELIMITED BY NEWLINE
        FIELDS (
            employee_id POSITION (1:6)   CHAR,
            last_name   POSITION (8:32)  CHAR,
            salary      POSITION (34:41) CHAR
        )
    )
    LOCATION ('emp_data.csv')
)
REJECT LIMIT UNLIMITED;
```

실제 파일이 있는 환경에서:
```sql
SELECT * FROM emp_ext_loader;
```

---

**[27번]**
```sql
CREATE TABLE emp_export_ext
    (employee_id, last_name, salary, department_id)
ORGANIZATION EXTERNAL
(
    TYPE ORACLE_DATAPUMP
    DEFAULT DIRECTORY ext_data_dir
    LOCATION ('emp_export.dmp')
)
AS SELECT employee_id, last_name, salary, department_id
   FROM   employees
   WHERE  department_id = 80;

SELECT * FROM emp_export_ext ORDER BY employee_id;
```

부서 80번 직원 데이터가 외부 파일로 저장되고 동시에 조회됨.

---

**[28번]**
```sql
INSERT INTO emp_export_ext VALUES (500, 'Test', 5000, 80);
-- ORA-30657: operation not supported on external organized table

UPDATE emp_export_ext SET salary = 9999 WHERE employee_id = 145;
-- ORA-30657: operation not supported on external organized table
```

외부 테이블은 **읽기 전용**: 파일 시스템의 데이터를 변경하는 DML은 불가.  
데이터 수정 필요 시 기반 파일을 직접 수정해야 함.

---

**[29번]**
```sql
SELECT table_name, type_name, default_directory_name,
       access_type, location
FROM   user_external_tables;
```

| 컬럼 | 설명 |
|------|------|
| TABLE_NAME | 외부 테이블 이름 |
| TYPE_NAME | ORACLE_LOADER / ORACLE_DATAPUMP |
| DEFAULT_DIRECTORY_NAME | 기본 DIRECTORY 객체 이름 |
| ACCESS_TYPE | 접근 드라이버 타입 |
| LOCATION | 파일명 |

---

**[30번]**
```sql
-- 외부 테이블
DROP TABLE emp_ext_loader;
DROP TABLE emp_export_ext;

-- 임시 테이블
DROP TABLE tmp_order_staging;
DROP TABLE tmp_session_log;

-- 실습용 테이블 (오류 무시 옵션 없으므로 존재 여부 확인 후 삭제)
DROP TABLE emp2;
DROP TABLE dept2;
DROP TABLE t_parent;
DROP TABLE t_child;

-- DIRECTORY 삭제 (DBA 계정으로)
DROP DIRECTORY ext_data_dir;

-- 정리 확인
SELECT table_name FROM user_tables
WHERE  table_name IN ('EMP2','DEPT2','T_PARENT','T_CHILD',
                      'TMP_ORDER_STAGING','TMP_SESSION_LOG',
                      'EMP_EXT_LOADER','EMP_EXPORT_EXT');
-- no rows selected
```
