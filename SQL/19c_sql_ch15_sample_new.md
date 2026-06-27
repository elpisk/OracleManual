# Oracle Database 19c: SQL Workshop
## Chapter 15 — 스키마 객체 관리 | SQL 실습 문제 30문제

> **환경:** Oracle Database 19c, HR 스키마  
> **기반 테이블:** EMPLOYEES, DEPARTMENTS, JOBS, LOCATIONS

---

## Group 1: 제약 조건 추가 & 삭제 (문제 1~6)

**[1번]** 다음 단계로 실습 테이블을 생성하시오.

```sql
-- 부서 테이블 복사
CREATE TABLE dept2 AS SELECT * FROM departments;

-- 직원 테이블 복사
CREATE TABLE emp2  AS SELECT * FROM employees;
```

두 테이블의 구조를 확인하시오.

---

**[2번]** `dept2` 테이블에 `department_id`를 PK로 추가하시오.

```sql
ALTER TABLE dept2 MODIFY department_id PRIMARY KEY;
```

추가 후 `USER_CONSTRAINTS`에서 `dept2`의 제약 조건 목록을 조회하시오.

---

**[3번]** `emp2` 테이블에 다음 제약 조건을 추가하시오.

1. `employee_id`를 PK로 추가 (이름: `emp2_pk`)
2. `department_id`에 FK 추가 — `dept2(department_id)` 참조, `ON DELETE SET NULL` (이름: `emp2_dept_fk`)
3. `salary`에 CHECK 제약 추가 — salary > 0 (이름: `emp2_sal_ck`)

각 추가 후 `USER_CONSTRAINTS`로 확인하시오.

---

**[4번]** `emp2` 테이블에 자기 참조 FK를 추가하시오.  
- `manager_id`가 `emp2(employee_id)`를 참조 (이름: `emp2_mgr_fk`)

추가 후 manager_id = 100인 직원 데이터를 조회하여 참조가 유효한지 확인하시오.

---

**[5번]** `emp2_sal_ck` CHECK 제약 조건을 삭제하시오. 삭제 전후로 `USER_CONSTRAINTS`를 조회하여 변화를 확인하시오.

---

**[6번]** `dept2`의 PK를 CASCADE 옵션으로 삭제하시오.  
삭제 후 `emp2`의 `emp2_dept_fk`가 어떻게 되는지 `USER_CONSTRAINTS`에서 확인하시오.

---

## Group 2: 제약 조건 비활성화·활성화·이름 변경 (문제 7~12)

**[7번]** `dept2` 테이블에 PK를 다시 추가하고 (`dept2_pk` 이름), `emp2`에 FK를 다시 추가한 후 (`emp2_dept_fk`) 다음을 수행하시오.

`emp2_dept_fk` 제약 조건을 비활성화하시오. 비활성화 후 `STATUS` 컬럼으로 확인하시오.

---

**[8번]** 제약 비활성화 후 FK 조건을 위반하는 데이터를 삽입하시오.

```sql
INSERT INTO emp2 (employee_id, last_name, email, hire_date, job_id, department_id)
VALUES (500, 'TestEmp', 'TESTEMP', SYSDATE, 'IT_PROG', 9999);
-- department_id = 9999는 dept2에 존재하지 않음
```

삽입이 성공하는지 확인하고, 이후 `ROLLBACK`하시오.

---

**[9번]** `emp2_dept_fk` 제약을 다시 활성화하시오.  
활성화 시 `ENABLE VALIDATE`(기본값)를 사용하면 어떤 조건이 충족되어야 하는지 확인하시오.

---

**[10번]** `dept2` 테이블과 `emp2` 테이블의 이름을 변경하시오.

```sql
ALTER TABLE dept2 RENAME TO dept_backup;
ALTER TABLE emp2  RENAME TO emp_backup;
```

변경 후 `USER_TABLES`로 확인하고, 다시 원래 이름으로 되돌리시오.

---

**[11번]** `emp_backup(emp2)` 테이블의 열 이름을 변경하시오.

```sql
ALTER TABLE emp_backup RENAME COLUMN phone_number TO phone;
```

변경 후 `DESCRIBE emp_backup`으로 확인하시오. (그 후 원래 이름으로 되돌리기)

---

**[12번]** `dept_backup`의 PK 제약 이름을 변경하시오.  
현재 이름을 `USER_CONSTRAINTS`에서 확인 후 `dept2_id_pk`로 변경하고, 변경 후 다시 확인하시오.

---

## Group 3: CASCADE CONSTRAINTS & 지연 제약 (문제 13~18)

**[13번]** CASCADE CONSTRAINTS 실습:

```sql
-- 준비: test 테이블 생성
CREATE TABLE t_parent (pk_id NUMBER PRIMARY KEY, val VARCHAR2(50));
CREATE TABLE t_child  (fk_id NUMBER, val VARCHAR2(50),
                       CONSTRAINT tc_fk FOREIGN KEY(fk_id)
                       REFERENCES t_parent(pk_id));

-- 1. CASCADE CONSTRAINTS 없이 pk_id 열 삭제 시도 → 오류 확인
ALTER TABLE t_parent DROP COLUMN pk_id;

-- 2. CASCADE CONSTRAINTS로 삭제
ALTER TABLE t_parent DROP COLUMN pk_id CASCADE CONSTRAINTS;

-- 3. t_child의 tc_fk 제약이 삭제되었는지 확인
SELECT constraint_name FROM user_constraints WHERE table_name = 'T_CHILD';
```

---

**[14번]** ON DELETE 동작 실습:

```sql
-- dept2, emp2를 다시 초기화 (Group 1 실습 결과 재활용 또는 재생성)
-- ON DELETE SET NULL FK 추가 확인 후

-- dept2에서 행 삭제
DELETE FROM dept2 WHERE department_id = 10;

-- emp2에서 department_id = 10이었던 직원 확인
SELECT employee_id, last_name, department_id
FROM   emp2
WHERE  department_id IS NULL
  AND  employee_id IN (SELECT employee_id FROM employees WHERE department_id = 10);

ROLLBACK;
```

---

**[15번]** 지연 제약 조건 실습:

```sql
-- dept2에 지연 가능 PK 추가
ALTER TABLE dept2
ADD CONSTRAINT dept2_defer_pk PRIMARY KEY (department_id)
DEFERRABLE INITIALLY DEFERRED;

-- 중복 INSERT (COMMIT 전에는 오류 없어야 함)
INSERT INTO dept2 (department_id, department_name)
VALUES ((SELECT MIN(department_id) FROM departments), 'Dup Test');

-- COMMIT 시 오류 확인
COMMIT;

ROLLBACK;
```

---

**[16번]** INITIALLY IMMEDIATE 제약 실습:

```sql
-- 즉시 검사 제약 추가
ALTER TABLE dept2
ADD CONSTRAINT dept2_imm_pk PRIMARY KEY (department_id)
DEFERRABLE INITIALLY IMMEDIATE;

-- 중복 INSERT 시도 (즉시 오류 발생해야 함)
INSERT INTO dept2 (department_id, department_name)
VALUES ((SELECT MIN(department_id) FROM departments), 'Dup Test2');
```

오류 발생 시점을 기록하시오.

---

**[17번]** SET CONSTRAINTS로 검사 시점 변경 실습:

```sql
-- INITIALLY IMMEDIATE 제약을 현재 트랜잭션만 DEFERRED로 변경
SET CONSTRAINTS dept2_imm_pk DEFERRED;

-- 이제 중복 INSERT가 성공하는지 확인
INSERT INTO dept2 (department_id, department_name)
VALUES ((SELECT MIN(department_id) FROM departments), 'Deferred Test');

-- COMMIT 시 오류 확인
COMMIT;

ROLLBACK;
```

---

**[18번]** 제약 상태 조회 실습:

```sql
SELECT constraint_name, constraint_type,
       status, validated, deferrable, deferred
FROM   user_constraints
WHERE  table_name = 'DEPT2'
ORDER BY constraint_name;
```

각 컬럼의 의미를 정리하시오.

---

## Group 4: 임시 테이블 (문제 19~24)

**[19번]** 트랜잭션 기반 GTT를 생성하시오.

```sql
CREATE GLOBAL TEMPORARY TABLE tmp_order_staging
    (order_id    NUMBER,
     product_id  NUMBER,
     quantity    NUMBER,
     unit_price  NUMBER(10,2))
ON COMMIT DELETE ROWS;
```

생성 후 `USER_TABLES`에서 `TEMPORARY` 컬럼 값을 확인하시오.

---

**[20번]** GTT에 데이터를 삽입하고 COMMIT 전후를 비교하시오.

```sql
INSERT INTO tmp_order_staging VALUES (1001, 301, 5, 29.99);
INSERT INTO tmp_order_staging VALUES (1001, 302, 2, 49.99);
INSERT INTO tmp_order_staging VALUES (1002, 301, 1, 29.99);

-- COMMIT 전 조회
SELECT * FROM tmp_order_staging;

COMMIT;

-- COMMIT 후 조회
SELECT * FROM tmp_order_staging;
```

---

**[21번]** 세션 기반 GTT를 생성하고 테스트하시오.

```sql
CREATE GLOBAL TEMPORARY TABLE tmp_session_log
    (log_time   TIMESTAMP DEFAULT SYSTIMESTAMP,
     log_msg    VARCHAR2(200))
ON COMMIT PRESERVE ROWS;

INSERT INTO tmp_session_log (log_msg) VALUES ('Start process');
COMMIT;
INSERT INTO tmp_session_log (log_msg) VALUES ('Step 1 done');
COMMIT;

-- 두 번의 COMMIT 후에도 데이터가 남아 있는지 확인
SELECT * FROM tmp_session_log;
```

---

**[22번]** Private Temporary Table(PTT)을 생성하시오.

```sql
-- 트랜잭션 기반 PTT
CREATE PRIVATE TEMPORARY TABLE ORA$PTT_calc_temp
    (calc_id    NUMBER,
     calc_val   NUMBER(15,4),
     calc_note  VARCHAR2(100))
ON COMMIT DROP DEFINITION;

-- 데이터 삽입 및 조회
INSERT INTO ORA$PTT_calc_temp VALUES (1, 3.14159, 'Pi value');
SELECT * FROM ORA$PTT_calc_temp;

-- COMMIT 후 테이블 존재 여부 확인
COMMIT;
SELECT * FROM ORA$PTT_calc_temp;  -- 오류 예상
```

---

**[23번]** 세션 기반 PTT를 생성하시오.

```sql
CREATE PRIVATE TEMPORARY TABLE ORA$PTT_sess_work
    (row_id   NUMBER,
     row_data VARCHAR2(200))
ON COMMIT PRESERVE DEFINITION;

INSERT INTO ORA$PTT_sess_work VALUES (1, 'First row');
COMMIT;

-- COMMIT 후에도 테이블 정의와 데이터가 있는지 확인
SELECT * FROM ORA$PTT_sess_work;
```

---

**[24번]** GTT와 일반 테이블 구분 실습:

```sql
-- USER_TABLES에서 임시 테이블 조회
SELECT table_name, temporary, duration
FROM   user_tables
WHERE  temporary = 'Y'
ORDER BY table_name;
```

`DURATION` 컬럼의 값(SYS$SESSION / SYS$TRANSACTION)이 무엇을 의미하는지 설명하시오.

---

## Group 5: 외부 테이블 & 정리 (문제 25~30)

**[25번]** DIRECTORY 객체 생성 실습 (DBA 권한 필요 또는 권한이 있는 계정 사용):

```sql
-- (실제 경로는 Oracle 서버의 유효한 경로로 변경)
CREATE OR REPLACE DIRECTORY ext_data_dir
AS '/home/oracle/ext_data';

-- 현재 사용자에게 읽기 권한 부여
GRANT READ ON DIRECTORY ext_data_dir TO hr;

-- DIRECTORY 목록 확인
SELECT directory_name, directory_path
FROM   all_directories
WHERE  directory_name = 'EXT_DATA_DIR';
```

---

**[26번]** 외부 테이블 생성 (ORACLE_LOADER):

다음 SQL을 작성하시오. `emp_ext_loader` 테이블이 `/home/oracle/ext_data/emp_data.csv` 파일을 읽도록 정의하시오.

파일 구조: `employee_id(1-6)`, `last_name(8-32)`, `salary(34-41)` (고정 길이)

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

---

**[27번]** ORACLE_DATAPUMP 외부 테이블로 데이터 내보내기:

```sql
-- employees의 일부 데이터를 외부 파일로 내보내기
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
```

생성 후 외부 테이블을 조회하시오.

---

**[28번]** 외부 테이블에 DML 시도:

```sql
-- INSERT 시도
INSERT INTO emp_export_ext VALUES (500, 'Test', 5000, 80);

-- UPDATE 시도
UPDATE emp_export_ext SET salary = 9999 WHERE employee_id = 145;
```

발생하는 오류를 확인하고 왜 불가한지 설명하시오.

---

**[29번]** `USER_EXTERNAL_TABLES`에서 외부 테이블 정보를 조회하시오.

```sql
SELECT table_name, type_name, default_directory_name,
       access_type, location
FROM   user_external_tables;
```

---

**[30번]** 실습 정리 — 생성한 객체 모두 삭제:

```sql
-- 외부 테이블 삭제
DROP TABLE emp_ext_loader;
DROP TABLE emp_export_ext;

-- 임시 테이블 삭제
DROP TABLE tmp_order_staging;
DROP TABLE tmp_session_log;

-- 실습용 테이블 삭제
DROP TABLE emp_backup;   -- (emp2에서 이름 변경된 경우)
DROP TABLE emp2;
DROP TABLE dept_backup;  -- (dept2에서 이름 변경된 경우)
DROP TABLE dept2;
DROP TABLE t_parent;
DROP TABLE t_child;

-- DIRECTORY 삭제
DROP DIRECTORY ext_data_dir;

-- 정리 확인
SELECT table_name FROM user_tables
WHERE  table_name IN ('EMP2','DEPT2','T_PARENT','T_CHILD',
                      'TMP_ORDER_STAGING','TMP_SESSION_LOG',
                      'EMP_EXT_LOADER','EMP_EXPORT_EXT');
-- no rows selected
```

---

*[Chapter 15 실습 문제 끝 — 30문제]*
