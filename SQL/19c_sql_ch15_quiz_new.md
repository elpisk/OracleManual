# Oracle Database 19c: SQL Workshop
## Chapter 15 — 스키마 객체 관리 | 연습문제 50문제

---

## 하(기초) — 20문제

**[1번]** 기존 테이블에 제약 조건을 추가하는 올바른 SQL 구문은?

① `CREATE CONSTRAINT ON emp2 ...;`  
② `ALTER TABLE emp2 ADD CONSTRAINT ...;`  
③ `MODIFY TABLE emp2 ADD CONSTRAINT ...;`  
④ `INSERT CONSTRAINT INTO emp2 ...;`

---

**[2번]** `NOT NULL` 제약 조건을 기존 열에 추가하는 올바른 방법은?

① `ALTER TABLE emp2 ADD last_name NOT NULL;`  
② `ALTER TABLE emp2 MODIFY last_name NOT NULL;`  
③ `ALTER TABLE emp2 ADD CONSTRAINT nn CHECK(last_name IS NOT NULL);`  
④ `ALTER TABLE emp2 SET last_name NOT NULL;`

---

**[3번]** 제약 조건을 삭제하는 올바른 SQL문은?

① `ALTER TABLE emp2 REMOVE CONSTRAINT emp_mgr_fk;`  
② `ALTER TABLE emp2 DELETE CONSTRAINT emp_mgr_fk;`  
③ `ALTER TABLE emp2 DROP CONSTRAINT emp_mgr_fk;`  
④ `DROP CONSTRAINT emp_mgr_fk FROM emp2;`

---

**[4번]** `ON DELETE CASCADE` 옵션의 동작은?

① 부모 행 삭제 시 자식 행의 FK 열이 NULL로 설정된다  
② 부모 행 삭제 시 자식 행도 자동으로 삭제된다  
③ 부모 행 삭제가 자식 행이 있을 경우 거부된다  
④ 자식 행이 먼저 삭제되어야만 부모 행을 삭제할 수 있다

---

**[5번]** `ON DELETE SET NULL` 옵션의 동작은?

① 부모 행 삭제 시 자식 행도 삭제된다  
② 부모 행 삭제 시 자식 행의 FK 열이 NULL로 설정된다  
③ 부모 행 삭제가 차단된다  
④ 자식 테이블이 삭제된다

---

**[6번]** 제약 조건을 비활성화하는 올바른 SQL문은?

① `ALTER TABLE emp2 DEACTIVATE CONSTRAINT emp_dt_fk;`  
② `ALTER TABLE emp2 DISABLE CONSTRAINT emp_dt_fk;`  
③ `ALTER TABLE emp2 OFF CONSTRAINT emp_dt_fk;`  
④ `ALTER TABLE emp2 STOP CONSTRAINT emp_dt_fk;`

---

**[7번]** 제약 조건을 활성화하는 올바른 SQL문은?

① `ALTER TABLE emp2 ACTIVATE CONSTRAINT emp_dt_fk;`  
② `ALTER TABLE emp2 ENABLE CONSTRAINT emp_dt_fk;`  
③ `ALTER TABLE emp2 ON CONSTRAINT emp_dt_fk;`  
④ `ALTER TABLE emp2 START CONSTRAINT emp_dt_fk;`

---

**[8번]** `DROP PRIMARY KEY CASCADE`의 동작은?

① PK만 삭제하고 연관 FK는 그대로 유지된다  
② PK를 삭제하고 연관된 모든 FK도 함께 삭제된다  
③ PK와 테이블을 함께 삭제한다  
④ FK를 모두 삭제한 후 PK를 삭제한다

---

**[9번]** 테이블 이름을 변경하는 올바른 SQL문은?

① `RENAME marketing TO new_marketing;`  
② `ALTER TABLE marketing RENAME TO new_marketing;`  
③ `ALTER TABLE marketing RENAME new_marketing;`  
④ ①과 ② 모두 올바르다

---

**[10번]** 열 이름을 변경하는 올바른 SQL문은?

① `ALTER TABLE t RENAME team_id TO id;`  
② `ALTER TABLE t RENAME COLUMN team_id TO id;`  
③ `ALTER TABLE t MODIFY team_id RENAME id;`  
④ `ALTER COLUMN team_id RENAME TO id IN t;`

---

**[11번]** `DROP TABLE emp PURGE;`와 `DROP TABLE emp;`의 차이점은?

① PURGE를 사용하면 테이블이 삭제되지 않는다  
② PURGE를 사용하면 휴지통을 거치지 않고 즉시 영구 삭제된다  
③ PURGE를 사용하면 외래 키 제약이 있어도 삭제된다  
④ 두 구문은 완전히 동일하다

---

**[12번]** 글로벌 임시 테이블(Global Temporary Table)의 특징으로 올바른 것은?

① 테이블 이름에 `ORA$PTT_` 접두사를 사용해야 한다  
② 테이블 정의가 메모리에만 저장된다  
③ 테이블 정의는 딕셔너리에 저장되며 모든 세션에서 볼 수 있다  
④ 세션 종료 후에도 데이터가 유지된다

---

**[13번]** `CREATE GLOBAL TEMPORARY TABLE cart ON COMMIT DELETE ROWS;`에서 데이터가 삭제되는 시점은?

① 세션 종료 시  
② COMMIT 시  
③ ROLLBACK 시  
④ DROP TABLE 시

---

**[14번]** 프라이빗 임시 테이블(Private Temporary Table)의 이름 규칙은?

① `TEMP_` 접두사를 사용해야 한다  
② `ORA$PTT_` 접두사를 사용해야 한다  
③ `GTT_` 접두사를 사용해야 한다  
④ 특별한 이름 규칙이 없다

---

**[15번]** 외부 테이블(External Table)에 대한 설명으로 올바른 것은?

① 데이터가 데이터베이스 내부에 저장된다  
② SELECT와 DML(INSERT/UPDATE/DELETE) 모두 가능하다  
③ 파일 시스템의 데이터를 Oracle 테이블처럼 조회한다  
④ 인덱스를 생성하여 성능을 향상시킬 수 있다

---

**[16번]** 외부 테이블 생성 시 `DEFAULT DIRECTORY`에 지정하는 것은?

① 테이블이 저장될 테이블스페이스  
② Oracle DIRECTORY 객체 이름 (외부 파일의 OS 경로)  
③ 데이터 파일의 정확한 절대 경로  
④ 데이터베이스 서버의 홈 디렉토리

---

**[17번]** `ORACLE_LOADER` 접근 드라이버는 어떤 파일을 처리하는가?

① Oracle Export 형식의 이진 파일  
② 플랫 텍스트 파일 (CSV, 고정 길이 등)  
③ XML 파일  
④ JSON 파일

---

**[18번]** 지연 제약 조건(Deferrable Constraint)에서 `INITIALLY DEFERRED`의 의미는?

① 제약이 처음부터 비활성화 상태다  
② 제약 검사가 각 문장 실행 후 즉시 이루어진다  
③ 제약 검사가 트랜잭션 종료(COMMIT) 시점까지 지연된다  
④ 제약이 다음 세션에서만 활성화된다

---

**[19번]** `CASCADE CONSTRAINTS` 절의 역할은?

① 테이블의 모든 자식 테이블을 함께 삭제한다  
② 열 삭제 시 해당 열 관련 제약 조건도 함께 삭제한다  
③ 제약 조건을 자식 테이블에 자동 전파한다  
④ 모든 제약을 한 번에 활성화한다

---

**[20번]** 외부 테이블 생성을 위해 OS 디렉토리를 등록하는 SQL문은?

① `CREATE PATH emp_dir AS '/path/to/dir';`  
② `CREATE OR REPLACE DIRECTORY emp_dir AS '/path/to/dir';`  
③ `REGISTER DIRECTORY emp_dir AT '/path/to/dir';`  
④ `ADD DIRECTORY emp_dir = '/path/to/dir';`

---

## 중(응용) — 20문제

**[21번]** 다음 SQL의 실행 결과는?

```sql
ALTER TABLE emp2
DROP PRIMARY KEY CASCADE;
```

① emp2 테이블의 PK만 삭제된다  
② emp2 테이블의 PK와, emp2 PK를 참조하는 모든 테이블의 FK도 삭제된다  
③ emp2 테이블 자체가 삭제된다  
④ emp2 PK가 비활성화된다

---

**[22번]** 다음 SQL에서 `ONLINE` 키워드의 효과는?

```sql
ALTER TABLE myemp2
DROP CONSTRAINT emp_name_pk ONLINE;
```

① 제약 삭제가 즉시 처리되지 않고 대기열에 등록된다  
② 제약 삭제 작업 중에도 해당 테이블의 DML이 허용된다  
③ 다른 세션의 읽기가 차단된다  
④ 삭제 후 자동으로 COMMIT이 실행된다

---

**[23번]** 다음 제약 상태 중 대량 데이터 로드 후 새 DML만 제약 검사를 받게 하려면 어떤 상태를 사용해야 하는가?

① `ENABLE VALIDATE`  
② `ENABLE NOVALIDATE`  
③ `DISABLE VALIDATE`  
④ `DISABLE NOVALIDATE`

---

**[24번]** 다음 시나리오에서 올바른 SQL은?

> emp2 테이블에 자기 참조 FK를 추가: manager_id가 자신의 테이블 employee_id를 참조

① `ALTER TABLE emp2 ADD FOREIGN KEY(manager_id) REFERENCES emp2;`  
② `ALTER TABLE emp2 ADD CONSTRAINT emp_mgr_fk FOREIGN KEY(manager_id) REFERENCES emp2(employee_id);`  
③ `ALTER TABLE emp2 ADD CONSTRAINT emp_mgr_fk REFERENCES emp2(employee_id);`  
④ `ALTER TABLE emp2 MODIFY manager_id REFERENCES emp2(employee_id);`

---

**[25번]** GTT에서 `ON COMMIT PRESERVE ROWS`와 `ON COMMIT DELETE ROWS`의 차이는?

① PRESERVE ROWS: 세션 종료 시 삭제, DELETE ROWS: COMMIT 시 삭제  
② PRESERVE ROWS: 영구 저장, DELETE ROWS: ROLLBACK 시 삭제  
③ PRESERVE ROWS: COMMIT 후에도 데이터 유지, DELETE ROWS: COMMIT 시 삭제  
④ 두 옵션은 동일하다

---

**[26번]** 다음 중 `DISABLE VALIDATE` 상태에 대한 설명으로 올바른 것은?

① 제약이 비활성화되어 DML이 자유롭게 가능하다  
② 제약이 비활성화되어 있지만 DML도 차단된다  
③ 제약이 활성화되어 있지만 기존 데이터는 검사하지 않는다  
④ 제약이 완전히 활성화된 상태다

---

**[27번]** 다음 SQL 실행 후 어떤 일이 발생하는가?

```sql
ALTER TABLE dept2
ADD CONSTRAINT dept2_id_pk PRIMARY KEY (department_id)
DEFERRABLE INITIALLY DEFERRED;

INSERT INTO dept2 VALUES (10, 'Test', 100);
INSERT INTO dept2 VALUES (10, 'Dup', 200);
-- 오류는 언제 발생하는가?
```

① 두 번째 INSERT 시 즉시 오류 발생  
② COMMIT 시 PK 중복 오류 발생  
③ 세션 종료 시 오류 발생  
④ 오류 없이 정상 실행된다

---

**[28번]** PTT(Private Temporary Table)의 `ON COMMIT DROP DEFINITION`은 무엇을 의미하는가?

① 세션 종료 시 테이블 정의가 삭제된다  
② COMMIT 시 데이터와 함께 테이블 정의도 삭제된다  
③ ROLLBACK 시 테이블 정의가 삭제된다  
④ DROP TABLE 없이도 자동 삭제된다 (COMMIT 없이)

---

**[29번]** 다음 중 외부 테이블(External Table)에 대해 올바른 것은?

① INSERT INTO external_table VALUES (...); 가능하다  
② SELECT * FROM external_table; 가능하다  
③ CREATE INDEX ON external_table(col); 가능하다  
④ UPDATE external_table SET col = val; 가능하다

---

**[30번]** `ORACLE_DATAPUMP` 접근 드라이버의 주요 용도는?

① CSV 텍스트 파일을 Oracle 테이블로 읽기  
② Oracle 독점 바이너리 형식으로 데이터를 내보내거나 가져오기  
③ JSON 파일을 Oracle 테이블로 읽기  
④ XML 파일을 Oracle 테이블로 읽기

---

**[31번]** 다음 제약 조건 이름 변경 SQL문의 올바른 형식은?

① `ALTER TABLE t RENAME CONSTRAINT old_name = new_name;`  
② `ALTER TABLE t RENAME CONSTRAINT old_name TO new_name;`  
③ `ALTER CONSTRAINT old_name TO new_name ON t;`  
④ `RENAME CONSTRAINT old_name TO new_name;`

---

**[32번]** 다음 중 GTT와 PTT의 차이점으로 올바른 것은?

① GTT는 세션 종료 후에도 테이블 정의가 유지되지만, PTT는 세션 종료 시 정의가 사라진다  
② GTT와 PTT 모두 모든 세션에서 테이블 정의를 볼 수 있다  
③ GTT는 트랜잭션 기반만 가능하고, PTT는 세션 기반만 가능하다  
④ GTT와 PTT는 이름 규칙이 동일하다

---

**[33번]** 다음 SQL에서 `CASCADE CONSTRAINTS`가 필요한 이유는?

```sql
ALTER TABLE emp2
DROP COLUMN employee_id CASCADE CONSTRAINTS;
```

① employee_id가 다른 테이블에서 FK로 참조될 수 있기 때문  
② employee_id가 PK일 때 관련 인덱스도 삭제해야 하기 때문  
③ CASCADE가 없으면 ROLLBACK이 발생하기 때문  
④ 열 삭제 시 항상 CASCADE가 필요하기 때문

---

**[34번]** `SET CONSTRAINTS dept2_id_pk IMMEDIATE;`의 효과는?

① dept2_id_pk 제약 조건을 즉시 활성화한다  
② dept2_id_pk 제약 조건의 검사 시점을 '각 문장 후 즉시'로 변경한다  
③ dept2_id_pk 제약 조건을 즉시 삭제한다  
④ dept2_id_pk 제약 조건을 비활성화한다

---

**[35번]** 외부 테이블 생성 시 `REJECT LIMIT`의 역할은?

① 쿼리가 반환하는 최대 행 수를 제한한다  
② 파일에서 허용되는 오류 행의 최대 수를 지정한다  
③ 외부 파일의 최대 크기를 설정한다  
④ 인덱스를 통해 거부된 행 수를 추적한다

---

**[36번]** 다음 중 `DISABLE PRIMARY KEY CASCADE`의 동작은?

① PK와 해당 테이블의 모든 FK를 비활성화한다  
② PK를 비활성화하고, 해당 PK를 참조하는 자식 테이블의 FK도 자동으로 비활성화한다  
③ 테이블과 모든 자식 테이블을 비활성화한다  
④ PK만 비활성화하고 FK는 영향받지 않는다

---

**[37번]** `ENABLE CONSTRAINT`를 실행할 때 기존 데이터에 제약 위반이 있으면?

① 제약 활성화가 성공하고 위반 데이터는 무시된다  
② 오류가 발생하고 제약 활성화에 실패한다  
③ 위반 데이터가 자동으로 삭제된다  
④ 위반 데이터가 별도 오류 테이블에 기록된다

---

**[38번]** 다음 중 임시 테이블 데이터의 특징으로 올바른 것은?

① 같은 GTT를 사용하는 두 세션은 서로의 데이터를 볼 수 있다  
② 임시 테이블 데이터는 세션마다 독립적(private)이다  
③ 임시 테이블 데이터는 UNDO가 생성되지 않는다  
④ 임시 테이블은 트랜잭션 롤백이 불가능하다

---

**[39번]** 다음 중 외부 테이블 생성에 필요한 구성 요소가 아닌 것은?

① DIRECTORY 객체  
② ORGANIZATION EXTERNAL  
③ TABLESPACE 지정  
④ LOCATION (파일명)

---

**[40번]** 다음 SQL의 결과는?

```sql
CREATE GLOBAL TEMPORARY TABLE cart
    (n NUMBER, d DATE)
ON COMMIT DELETE ROWS;

INSERT INTO cart VALUES (1, SYSDATE);
INSERT INTO cart VALUES (2, SYSDATE);
COMMIT;
SELECT COUNT(*) FROM cart;
```

① 2  
② 1  
③ 0  
④ ORA-14452 오류

---

## 상(심화) — 10문제

**[41번]** 다음 시나리오를 분석하시오.

```sql
-- dept2 테이블에 PK 지연 제약 추가
ALTER TABLE dept2
ADD CONSTRAINT dept2_pk PRIMARY KEY (department_id)
DEFERRABLE INITIALLY IMMEDIATE;

-- 트랜잭션 시작
INSERT INTO dept2 (department_id, department_name)
VALUES (10, 'Admin');

-- 동일 PK로 다시 삽입
INSERT INTO dept2 (department_id, department_name)
VALUES (10, 'Test');

COMMIT;
```

오류는 언제 발생하는가?

① 두 번째 INSERT 시점 (INITIALLY IMMEDIATE이므로 즉시 검사)  
② COMMIT 시점  
③ 첫 번째 INSERT 시점  
④ 오류 없음 (DEFERRABLE이므로)

---

**[42번]** 다음 중 `ENABLE NOVALIDATE` 사용이 적절한 시나리오는?

① 신규 테이블에 제약을 추가할 때  
② 대량 데이터 로드 후 기존 데이터는 검사하지 않고 새로 입력되는 데이터만 제약을 적용할 때  
③ 제약을 완전히 비활성화해야 할 때  
④ 성능 향상을 위해 모든 제약을 끄고 싶을 때

---

**[43번]** 다음 시나리오에서 발생하는 현상을 분석하시오.

```sql
-- 세션 A
CREATE GLOBAL TEMPORARY TABLE shared_temp
    (id NUMBER, val VARCHAR2(50))
ON COMMIT PRESERVE ROWS;

-- 세션 A: 데이터 삽입
INSERT INTO shared_temp VALUES (1, 'Session A data');
COMMIT;

-- 세션 B (별도 세션): 같은 GTT 조회
SELECT * FROM shared_temp;
```

세션 B의 조회 결과는?

① 세션 A가 삽입한 데이터 (id=1, val='Session A data')가 조회된다  
② no rows selected (GTT 데이터는 세션별로 독립적)  
③ ORA-00942: table or view does not exist  
④ 세션 A 데이터가 보이지만 수정은 불가하다

---

**[44번]** 다음 외부 테이블 정의에서 `PARALLEL` 키워드의 역할은?

```sql
CREATE TABLE emp_ext
    (employee_id, first_name, last_name)
ORGANIZATION EXTERNAL
(TYPE ORACLE_DATAPUMP
 DEFAULT DIRECTORY emp_dir
 LOCATION ('emp1.exp', 'emp2.exp'))
PARALLEL
AS SELECT employee_id, first_name, last_name
   FROM   employees;
```

① 외부 파일 접근을 직렬로 처리한다  
② 여러 프로세스를 사용하여 병렬로 데이터를 내보낸다  
③ 외부 테이블을 여러 세션에서 동시 접근하도록 허용한다  
④ 인덱스를 병렬로 생성한다

---

**[45번]** 다음 중 지연 제약(Deferred Constraint)이 유용한 실제 시나리오는?

① 열의 데이터 타입을 변경할 때  
② 부모-자식 관계에서 부모를 먼저 삭제하고 나중에 자식도 삭제하는 트랜잭션  
③ 대량 INSERT 성능을 높일 때  
④ 테이블 이름을 변경할 때

---

**[46번]** 다음 시나리오에서 `CASCADE CONSTRAINTS`의 역할을 분석하시오.

```sql
-- t1 테이블의 pk_col을 참조하는 t2, t3의 FK가 존재
ALTER TABLE t1 DROP COLUMN pk_col CASCADE CONSTRAINTS;
```

`CASCADE CONSTRAINTS` 없이 실행하면?

① 정상 실행된다  
② ORA-12992: cannot drop parent key column 오류 발생  
③ pk_col만 삭제되고 FK는 유지된다  
④ 관련 FK가 자동으로 비활성화된다

---

**[47번]** 다음 PTT 정의에서 `ON COMMIT PRESERVE DEFINITION`의 의미는?

```sql
CREATE PRIVATE TEMPORARY TABLE ORA$PTT_sales_sess
    (time_id DATE, amt_sold NUMBER(8,2))
ON COMMIT PRESERVE DEFINITION;
```

① COMMIT 후에도 데이터가 유지된다  
② COMMIT 후 데이터는 삭제되지만 테이블 정의는 세션 종료 시까지 유지된다  
③ 세션 종료 후에도 테이블 정의가 딕셔너리에 저장된다  
④ 트랜잭션 기반으로 데이터가 관리된다

---

**[48번]** 다음 중 외부 테이블의 제한 사항으로 올바른 것을 모두 고르면?

① INSERT, UPDATE, DELETE 불가  
② 인덱스 생성 불가  
③ 파티셔닝 불가  
④ PARALLEL 조회 불가

---

**[49번]** 다음 시나리오를 분석하시오.

```sql
-- 1단계: 제약 비활성화
ALTER TABLE employees DISABLE CONSTRAINT emp_dept_fk;

-- 2단계: 부모 테이블 department_id 변경
UPDATE departments SET department_id = 999 WHERE department_id = 80;

-- 3단계: 제약 재활성화
ALTER TABLE employees ENABLE CONSTRAINT emp_dept_fk;
```

3단계에서 발생하는 결과는?

① 정상 활성화된다  
② ORA-02298 오류: 제약 활성화 실패 (고아 키 존재)  
③ 제약이 활성화되고 위반 데이터가 자동 수정된다  
④ 제약이 NOVALIDATE 상태로 활성화된다

---

**[50번]** 다음 복합 시나리오의 최종 결과를 분석하시오.

```sql
-- 지연 가능 PK 생성
ALTER TABLE dept2
ADD CONSTRAINT dept2_pk PRIMARY KEY (department_id)
DEFERRABLE INITIALLY DEFERRED;

-- 현재 세션에서만 즉시 검사로 변경
SET CONSTRAINTS dept2_pk IMMEDIATE;

-- PK 중복 삽입 시도
INSERT INTO dept2 (department_id, department_name)
VALUES (10, 'DupTest');

-- (department_id = 10이 이미 존재한다고 가정)
COMMIT;
```

오류는 언제 발생하는가?

① INSERT 시점 (SET CONSTRAINTS IMMEDIATE로 변경했으므로 즉시 검사)  
② COMMIT 시점  
③ ROLLBACK 시점  
④ 세션 종료 시점

---

*[Chapter 15 연습문제 끝 — 50문제]*
