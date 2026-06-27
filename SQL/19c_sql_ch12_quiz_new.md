# Oracle Database 19c: SQL Workshop
## Chapter 12 — 데이터 딕셔너리 뷰 소개 | 연습문제 (50문제)

> **구성:** 하(기초) 20문제 + 중(응용) 20문제 + 상(심화) 10문제

---

## 하(기초) — 20문제

---

**[1번]** 데이터 딕셔너리(Data Dictionary)의 역할로 올바른 것은?

① 사용자 비즈니스 데이터를 저장한다  
② 데이터베이스 객체에 대한 메타데이터를 관리한다  
③ 트랜잭션을 처리한다  
④ 인덱스를 자동 생성한다

---

**[2번]** 데이터 딕셔너리는 어떤 두 계층으로 구성되는가?

① 테이블과 인덱스  
② 베이스 테이블과 사용자 접근 가능 뷰  
③ 프로시저와 함수  
④ 뷰와 시퀀스

---

**[3번]** `USER_` 접두사가 붙은 딕셔너리 뷰의 접근 범위는?

① 모든 사용자의 객체  
② DBA 전용 시스템 데이터  
③ 자신의 스키마(소유한 객체)  
④ 성능 관련 데이터

---

**[4번]** `ALL_` 접두사가 붙은 딕셔너리 뷰의 접근 범위는?

① 자신의 스키마만  
② 접근 권한이 있는 모든 사용자의 객체  
③ DBA만 조회 가능  
④ 삭제된 객체 포함

---

**[5번]** `DBA_` 접두사가 붙은 딕셔너리 뷰의 특징은?

① 일반 사용자도 조회 가능  
② 자신의 객체만 조회  
③ DBA 권한을 가진 사용자만 조회 가능  
④ 성능 데이터만 조회

---

**[6번]** `V$` 접두사가 붙은 딕셔너리 뷰의 특징은?

① 자신의 스키마 정보  
② 성능 관련 동적 데이터를 조회  
③ 삭제된 객체 목록  
④ 제약 조건 정보

---

**[7번]** 모든 데이터 딕셔너리 뷰의 이름과 설명이 저장된 뷰는?

① USER_OBJECTS  
② USER_TABLES  
③ DICTIONARY  
④ USER_CATALOG

---

**[8번]** 자신이 소유한 모든 객체(테이블, 뷰, 인덱스 등)를 조회하는 뷰는?

① USER_TABLES  
② USER_OBJECTS  
③ USER_CATALOG  
④ ALL_OBJECTS

---

**[9번]** `USER_OBJECTS` 뷰에서 `STATUS` 컬럼의 가능한 값은?

① YES / NO  
② VALID / INVALID  
③ ACTIVE / INACTIVE  
④ ENABLED / DISABLED

---

**[10번]** 자신이 소유한 테이블 목록과 상세 정보를 조회하는 뷰는?

① USER_OBJECTS  
② USER_TAB_COLUMNS  
③ USER_TABLES  
④ USER_CATALOG

---

**[11번]** 테이블의 열(컬럼) 정보를 조회하는 뷰는?

① USER_TABLES  
② USER_CONSTRAINTS  
③ USER_TAB_COLUMNS  
④ USER_OBJECTS

---

**[12번]** `USER_TAB_COLUMNS` 뷰의 `NULLABLE` 컬럼에서 NOT NULL 열을 나타내는 값은?

① YES  
② N  
③ NOT NULL  
④ 0

---

**[13번]** `USER_CONSTRAINTS` 뷰에서 `CONSTRAINT_TYPE = 'P'`가 의미하는 것은?

① CHECK 제약 조건  
② UNIQUE 제약 조건  
③ PRIMARY KEY 제약 조건  
④ FOREIGN KEY 제약 조건

---

**[14번]** `USER_CONSTRAINTS` 뷰에서 FOREIGN KEY를 나타내는 `CONSTRAINT_TYPE` 값은?

① C  
② U  
③ R  
④ F

---

**[15번]** `USER_CONS_COLUMNS` 뷰의 역할은?

① 제약 조건이 정의된 열 정보를 조회  
② 제약 조건의 삭제 규칙을 조회  
③ 제약 조건의 상태(활성/비활성)를 조회  
④ 테이블의 행 수를 조회

---

**[16번]** 테이블에 주석을 추가하는 SQL 문은?

① `ADD COMMENT TO employees IS '...';`  
② `COMMENT ON TABLE employees IS '...';`  
③ `INSERT COMMENT ON employees IS '...';`  
④ `ALTER TABLE employees COMMENT IS '...';`

---

**[17번]** 열에 주석을 추가하는 올바른 구문은?

① `COMMENT ON employees.first_name IS '...';`  
② `COMMENT ON COLUMN employees.first_name IS '...';`  
③ `ADD COMMENT TO COLUMN first_name IN employees IS '...';`  
④ `ALTER COLUMN employees.first_name COMMENT '...';`

---

**[18번]** 테이블의 주석을 조회하는 뷰는?

① USER_TAB_COMMENTS  
② USER_TABLE_DESC  
③ USER_COMMENTS  
④ USER_OBJECTS

---

**[19번]** 열의 주석을 조회하는 뷰는?

① USER_COL_DESC  
② USER_COLUMN_COMMENTS  
③ USER_COL_COMMENTS  
④ USER_TAB_COLUMNS

---

**[20번]** 기존 주석을 삭제하는 방법은?

① `DELETE COMMENT ON TABLE employees;`  
② `DROP COMMENT ON TABLE employees;`  
③ `COMMENT ON TABLE employees IS '';` (빈 문자열 입력)  
④ `REMOVE COMMENT FROM employees;`

---

## 중(응용) — 20문제

---

**[21번]** 다음 SQL의 결과로 올바른 것은?

```sql
SELECT object_name, object_type, created, status
FROM   user_objects
ORDER BY object_type;
```

① 모든 Oracle 사용자의 객체 조회  
② 현재 사용자가 소유한 객체를 유형별로 정렬하여 조회  
③ DBA 권한 객체만 조회  
④ 삭제된 객체를 조회

---

**[22번]** `USER_TAB_COLUMNS`에서 EMPLOYEES 테이블의 NUMBER 타입 열만 조회하는 SQL은?

① `SELECT * FROM user_tab_columns WHERE data_type = 'NUMBER';`  
② `SELECT * FROM user_tab_columns WHERE table_name = 'EMPLOYEES' AND data_type = 'NUMBER';`  
③ `SELECT * FROM user_columns WHERE type = 'NUMBER';`  
④ `SELECT * FROM all_tab_columns WHERE column_type = 'NUMBER';`

---

**[23번]** 다음 SQL에서 `constraint_type = 'R'`인 행이 나타내는 것은?

```sql
SELECT constraint_name, constraint_type, r_constraint_name
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES';
```

① EMPLOYEES의 PRIMARY KEY  
② EMPLOYEES의 CHECK 제약 조건  
③ EMPLOYEES가 부모 테이블을 참조하는 FOREIGN KEY  
④ EMPLOYEES의 UNIQUE 제약 조건

---

**[24번]** 다음 SQL의 목적은?

```sql
SELECT table_name, comments
FROM   user_tab_comments
WHERE  comments IS NOT NULL;
```

① 주석이 없는 테이블 조회  
② 주석이 있는 테이블만 조회  
③ 모든 테이블의 행 수 조회  
④ 주석 추가 불가 테이블 조회

---

**[25번]** `USER_CONSTRAINTS`에서 `DELETE_RULE` 컬럼의 가능한 값은?

① YES / NO  
② CASCADE / SET NULL / NO ACTION  
③ DELETE / RESTRICT / IGNORE  
④ ENABLED / DISABLED

---

**[26번]** 다음 SQL이 반환하는 결과는?

```sql
SELECT table_name FROM dictionary
WHERE  table_name LIKE 'USER_%';
```

① USER로 시작하는 딕셔너리 뷰 목록  
② USER 테이블 데이터  
③ 현재 사용자 정보  
④ 오류 발생

---

**[27번]** `USER_OBJECTS` 뷰에서 오늘 생성된 테이블만 조회하는 SQL은?

① `SELECT * FROM user_objects WHERE created = SYSDATE;`  
② `SELECT * FROM user_objects WHERE TRUNC(created) = TRUNC(SYSDATE) AND object_type = 'TABLE';`  
③ `SELECT * FROM user_tables WHERE today = 'YES';`  
④ `SELECT * FROM user_objects WHERE object_type = 'TODAY';`

---

**[28번]** 다음 SQL에서 JOIN의 목적은?

```sql
SELECT c.constraint_name, c.constraint_type, cc.column_name
FROM   user_constraints  c
JOIN   user_cons_columns cc
    ON c.constraint_name = cc.constraint_name
   AND c.table_name = cc.table_name
WHERE  c.table_name = 'EMPLOYEES';
```

① 두 테이블을 병합  
② 제약 조건 이름과 해당 제약이 적용된 열 이름을 함께 조회  
③ 중복 제약 조건 제거  
④ 제약 조건 비활성화

---

**[29번]** `USER_TABLES`의 `NUM_ROWS` 컬럼에 대한 올바른 설명은?

① 항상 실시간 행 수를 반영한다  
② ANALYZE 또는 DBMS_STATS 실행 후 갱신되는 통계 값이다  
③ 테이블 생성 시 고정된다  
④ 외래 키 참조 행 수를 나타낸다

---

**[30번]** 다음 중 `V$SESSION` 뷰를 조회할 수 있는 사용자는?

① 일반 HR 사용자  
② 주석을 추가한 사용자만  
③ DBA 또는 `SELECT ANY DICTIONARY` 권한을 가진 사용자  
④ USER_OBJECTS를 조회한 적 있는 사용자

---

**[31번]** 다음 SQL에서 `constraint_type = 'C'`가 포함하는 제약 조건은?

```sql
SELECT constraint_name, constraint_type, search_condition
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES'
AND    constraint_type = 'C';
```

① FOREIGN KEY만  
② PRIMARY KEY와 UNIQUE  
③ CHECK 조건과 NOT NULL 조건 모두  
④ UNIQUE만

---

**[32번]** `USER_TAB_COLUMNS`에서 기본값이 설정된 열을 찾는 SQL은?

① `SELECT * FROM user_tab_columns WHERE default_value IS NOT NULL;`  
② `SELECT * FROM user_tab_columns WHERE data_default IS NOT NULL;`  
③ `SELECT * FROM user_columns WHERE has_default = 'Y';`  
④ `SELECT * FROM user_tab_columns WHERE default = 'SET';`

---

**[33번]** 특정 사용자(예: HR)의 테이블을 조회하려면 어느 뷰를 사용해야 하는가?

① USER_TABLES  
② USER_OBJECTS  
③ ALL_TABLES (owner 조건 추가)  
④ DBA_TABLES (DBA 권한 없이)

---

**[34번]** `USER_CONS_COLUMNS`의 `POSITION` 컬럼의 역할은?

① 제약 조건의 생성 순서  
② 복합 제약 조건에서 해당 열의 위치 (1, 2, 3 ...)  
③ 열의 화면 표시 위치  
④ 제약 조건의 강도(priority)

---

**[35번]** EMPLOYEES 테이블의 제약 조건 중 `R_CONSTRAINT_NAME`이 값을 가지는 경우는?

① NOT NULL 제약 조건  
② CHECK 제약 조건  
③ FOREIGN KEY 제약 조건 (부모 PK 이름을 참조)  
④ PRIMARY KEY 제약 조건

---

**[36번]** 다음 SQL로 조회되는 정보는?

```sql
SELECT column_name, data_type, data_length,
       data_precision, data_scale, nullable
FROM   user_tab_columns
WHERE  table_name = 'EMPLOYEES';
```

① EMPLOYEES 테이블의 행 데이터  
② EMPLOYEES 테이블의 열 구조 및 타입 정보  
③ EMPLOYEES에 적용된 제약 조건  
④ EMPLOYEES의 인덱스 목록

---

**[37번]** 다음 SQL에서 `DESCRIBE user_tables`가 출력하는 것은?

① USER_TABLES가 포함하는 모든 테이블 목록  
② USER_TABLES 뷰 자체의 컬럼 구조  
③ USER_TABLES에 저장된 데이터  
④ USER_TABLES의 제약 조건

---

**[38번]** `DICTIONARY` 뷰에서 제약 조건 관련 뷰를 검색하는 SQL은?

① `SELECT * FROM dictionary WHERE table_name = 'CONSTRAINT';`  
② `SELECT table_name, comments FROM dictionary WHERE table_name LIKE '%CONS%';`  
③ `SELECT * FROM user_constraints WHERE table_name = 'DICTIONARY';`  
④ `SELECT * FROM all_dictionary WHERE type = 'CONSTRAINT';`

---

**[39번]** 다음 SQL의 결과로 올바른 것은?

```sql
SELECT object_name, object_type, last_ddl_time
FROM   user_objects
WHERE  object_type IN ('TABLE', 'VIEW', 'INDEX')
ORDER BY last_ddl_time DESC;
```

① 생성일 오름차순으로 정렬된 모든 객체  
② 테이블, 뷰, 인덱스를 최근 수정 순으로 조회  
③ 삭제된 객체만 조회  
④ 오류 발생 (IN 절 사용 불가)

---

**[40번]** 다음 중 ALL_TAB_COMMENTS와 USER_TAB_COMMENTS의 차이점은?

① 존재하지 않는 뷰 이름이다  
② ALL_TAB_COMMENTS는 다른 사용자 소유 테이블의 주석도 포함한다  
③ USER_TAB_COMMENTS는 DBA 전용이다  
④ 두 뷰는 동일하다

---

## 상(심화) — 10문제

---

**[41번]** 다음 SQL에서 FK로 연결된 부모-자식 관계를 조회하는 방법으로 가장 완전한 것은?

```sql
-- (A) 단순 조회
SELECT * FROM user_constraints WHERE constraint_type = 'R';

-- (B) 부모 테이블까지 연결
SELECT c.table_name    AS 자식_테이블,
       cc.column_name  AS FK_열,
       pc.table_name   AS 부모_테이블,
       pcc.column_name AS PK_열
FROM   user_constraints  c
JOIN   user_cons_columns cc  ON c.constraint_name = cc.constraint_name AND c.table_name = cc.table_name
JOIN   user_constraints  pc  ON c.r_constraint_name = pc.constraint_name
JOIN   user_cons_columns pcc ON pc.constraint_name = pcc.constraint_name AND pc.table_name = pcc.table_name
WHERE  c.constraint_type = 'R';
```

① (A)가 더 완전하다  
② (B)가 더 완전하다 — FK 열과 참조 테이블/열을 함께 보여줌  
③ 두 SQL은 동일한 결과를 반환한다  
④ (B)는 오류가 발생한다

---

**[42번]** `USER_CONSTRAINTS`의 `SEARCH_CONDITION` 컬럼이 값을 가지는 경우는?

① PRIMARY KEY  
② UNIQUE  
③ FOREIGN KEY  
④ CHECK 및 NOT NULL (constraint_type = 'C')

---

**[43번]** 다음 SQL이 반환하는 정보를 분석하시오.

```sql
SELECT utc.table_name,
       utc.column_name,
       utc.data_type,
       uc.constraint_type,
       uc.constraint_name
FROM   user_tab_columns utc
LEFT JOIN user_cons_columns ucc ON utc.table_name = ucc.table_name AND utc.column_name = ucc.column_name
LEFT JOIN user_constraints  uc  ON ucc.constraint_name = uc.constraint_name AND ucc.table_name = uc.table_name
WHERE  utc.table_name = 'EMPLOYEES'
ORDER BY utc.column_id;
```

① EMPLOYEES의 열 정보와 해당 열에 적용된 제약 조건을 함께 조회  
② EMPLOYEES의 행 데이터와 제약 조건 데이터를 조인  
③ 오류 — USER_TAB_COLUMNS는 USER_CONS_COLUMNS와 조인 불가  
④ EMPLOYEES의 삭제된 열 조회

---

**[44번]** 다음 SQL에서 NULL 열 비중이 높은 테이블을 찾는 목적으로 올바른 것은?

```sql
SELECT table_name,
       COUNT(*) AS total_cols,
       SUM(CASE WHEN nullable = 'Y' THEN 1 ELSE 0 END) AS nullable_cols,
       ROUND(SUM(CASE WHEN nullable = 'Y' THEN 1 ELSE 0 END) / COUNT(*) * 100) AS null_pct
FROM   user_tab_columns
GROUP BY table_name
ORDER BY null_pct DESC;
```

① 무결성이 낮은 테이블 — NOT NULL 제약 부족  
② 행 수가 많은 테이블  
③ 인덱스가 많은 테이블  
④ 데이터 타입이 다양한 테이블

---

**[45번]** `USER_OBJECTS`의 `STATUS = 'INVALID'`가 의미하는 상황은?

① 테이블이 삭제된 상태  
② 뷰, 프로시저 등이 참조하는 객체 변경으로 재컴파일 필요 상태  
③ 권한이 없는 객체  
④ 읽기 전용 객체

---

**[46번]** 다음 SQL에서 제약 조건 이름으로 `SYS_C`로 시작하는 것이 의미하는 것은?

```sql
SELECT constraint_name, constraint_type
FROM   user_constraints
WHERE  table_name = 'MY_TABLE';
-- 결과: SYS_C007123  C
--       SYS_C007124  P
```

① 시스템이 자동 생성한 이름 (사용자가 명시적 이름을 지정하지 않음)  
② 오류가 있는 제약 조건  
③ 비활성화된 제약 조건  
④ DBA가 생성한 제약 조건

---

**[47번]** 다음 SQL에서 `user_constraints`와 `user_cons_columns`를 USING이 아닌 ON으로 조인해야 하는 이유는?

```sql
SELECT c.constraint_name, c.constraint_type, cc.column_name
FROM   user_constraints  c
JOIN   user_cons_columns cc
    ON c.constraint_name = cc.constraint_name
   AND c.table_name      = cc.table_name
WHERE  c.table_name = 'EMPLOYEES';
```

① USING이 문법적으로 지원되지 않기 때문  
② 두 뷰 모두 `TABLE_NAME`을 가지고 있어 USING 시 모호해지므로 ON으로 명시  
③ 성능 때문  
④ WHERE 절에 테이블 필터가 있기 때문

---

**[48번]** HR 스키마에서 모든 FK가 참조하는 부모 테이블 목록을 구하는 가장 적절한 SQL은?

① `SELECT * FROM user_constraints WHERE constraint_type = 'P';`  
② `SELECT DISTINCT pc.table_name AS 부모_테이블 FROM user_constraints c JOIN user_constraints pc ON c.r_constraint_name = pc.constraint_name WHERE c.constraint_type = 'R';`  
③ `SELECT table_name FROM user_tables WHERE has_children = 'YES';`  
④ `SELECT * FROM user_cons_columns WHERE constraint_type = 'R';`

---

**[49번]** 다음 SQL에서 `data_precision IS NULL AND data_type = 'NUMBER'`인 열이 의미하는 것은?

```sql
SELECT column_name, data_type, data_precision, data_scale
FROM   user_tab_columns
WHERE  table_name = 'SOME_TABLE'
AND    data_type = 'NUMBER'
AND    data_precision IS NULL;
```

① NUMBER 타입으로 선언했지만 오류가 있는 열  
② `NUMBER` (정밀도/스케일 미지정) — Oracle 최대 정밀도 허용  
③ 데이터가 없는 열  
④ NOT NULL 제약이 없는 열

---

**[50번]** 다음 상황에서 가장 적절한 딕셔너리 뷰 쿼리 전략은?

**상황:** DBA가 아닌 일반 HR 사용자로 접속 중이다.  
**목표:** 다른 사용자가 HR 스키마의 테이블에 부여한 SELECT 권한을 확인하고 싶다.

① `SELECT * FROM dba_tab_privs WHERE owner = 'HR';` — DBA 권한 필요  
② `SELECT * FROM all_tab_privs WHERE table_schema = 'HR';`  
③ `SELECT * FROM user_tab_privs WHERE grantee = 'HR';`  
④ `SELECT * FROM user_tables WHERE privilege = 'SELECT';`
