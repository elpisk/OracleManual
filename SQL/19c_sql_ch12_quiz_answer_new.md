# Oracle Database 19c: SQL Workshop
## Chapter 12 — 데이터 딕셔너리 뷰 소개 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | 데이터 딕셔너리 = 데이터베이스 객체 메타데이터 관리 저장소 |
| 2 | ② | 베이스 테이블(내부) + 사용자 접근 가능 뷰 |
| 3 | ③ | USER_ = 자신의 스키마(소유한 객체)만 조회 |
| 4 | ② | ALL_ = 접근 권한이 있는 모든 사용자의 객체 |
| 5 | ③ | DBA_ = DBA 권한 보유자만 조회 가능 |
| 6 | ② | V$ = 성능 관련 동적 데이터 |
| 7 | ③ | DICTIONARY = 모든 딕셔너리 뷰의 이름·설명 저장 |
| 8 | ② | USER_OBJECTS = 자신이 소유한 모든 객체 |
| 9 | ② | STATUS: VALID 또는 INVALID |
| 10 | ③ | USER_TABLES = 자신이 소유한 테이블 정보 |
| 11 | ③ | USER_TAB_COLUMNS = 열 정보 조회 |
| 12 | ② | NULLABLE = 'N' → NOT NULL 열 |
| 13 | ③ | CONSTRAINT_TYPE = 'P' → PRIMARY KEY |
| 14 | ③ | CONSTRAINT_TYPE = 'R' → FOREIGN KEY (Referential) |
| 15 | ① | USER_CONS_COLUMNS = 제약 조건이 적용된 열 정보 |
| 16 | ② | `COMMENT ON TABLE t IS '...';` |
| 17 | ② | `COMMENT ON COLUMN t.col IS '...';` |
| 18 | ① | USER_TAB_COMMENTS = 테이블 주석 조회 |
| 19 | ③ | USER_COL_COMMENTS = 열 주석 조회 |
| 20 | ③ | 빈 문자열(`IS ''`)로 주석 삭제 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

```sql
SELECT object_name, object_type, created, status
FROM   user_objects
ORDER BY object_type;
```

`USER_OBJECTS`는 **현재 사용자가 소유**한 객체만 반환한다.  
`ORDER BY object_type`으로 TABLE, VIEW, INDEX 등 유형별로 정렬된다.

---

**[22번] 정답: ②**

```sql
SELECT * FROM user_tab_columns
WHERE  table_name = 'EMPLOYEES'
AND    data_type  = 'NUMBER';
```

`TABLE_NAME`과 `DATA_TYPE` 조건 모두 필요하다.  
`TABLE_NAME`은 대문자로 입력해야 한다 (딕셔너리는 대문자로 저장).

---

**[23번] 정답: ③**

`CONSTRAINT_TYPE = 'R'` → FOREIGN KEY (Referential Integrity)  
EMPLOYEES가 다른 테이블(부모)의 기본 키를 참조하는 FK가 있음을 의미한다.  
`R_CONSTRAINT_NAME`에 부모 테이블의 PK 제약 조건 이름이 표시된다.

---

**[24번] 정답: ②**

```sql
SELECT table_name, comments
FROM   user_tab_comments
WHERE  comments IS NOT NULL;
```

`COMMENTS IS NOT NULL` 조건으로 **주석이 등록된 테이블만** 조회한다.

---

**[25번] 정답: ②**

`DELETE_RULE` 컬럼 가능한 값:
- `CASCADE`: 부모 삭제 시 자식도 삭제
- `SET NULL`: 부모 삭제 시 자식 FK를 NULL로
- `NO ACTION`: 기본값 — 자식이 있으면 부모 삭제 불가

---

**[26번] 정답: ①**

```sql
SELECT table_name FROM dictionary WHERE table_name LIKE 'USER_%';
```

`DICTIONARY` 뷰에서 이름에 'USER_'로 시작하는 딕셔너리 뷰 목록을 조회한다.  
(USER_TABLES, USER_OBJECTS, USER_CONSTRAINTS 등이 반환됨)

---

**[27번] 정답: ②**

```sql
SELECT * FROM user_objects
WHERE  TRUNC(created) = TRUNC(SYSDATE)
AND    object_type = 'TABLE';
```

`TRUNC()`로 시간 부분을 제거하고 날짜만 비교해야 한다.  
`created = SYSDATE`는 초 단위까지 일치해야 하므로 실용적이지 않다.

---

**[28번] 정답: ②**

두 뷰를 JOIN하는 이유:
- `USER_CONSTRAINTS`: 제약 조건 이름, 유형, 조건식 등
- `USER_CONS_COLUMNS`: 어떤 열에 제약이 걸렸는지

두 뷰를 `CONSTRAINT_NAME`과 `TABLE_NAME`으로 JOIN하면 **제약 조건과 열 이름을 함께** 조회할 수 있다.

---

**[29번] 정답: ②**

`USER_TABLES.NUM_ROWS`는 실시간 값이 아니라, `ANALYZE TABLE` 또는 `DBMS_STATS.GATHER_TABLE_STATS()` 실행 후 갱신되는 통계 값이다.  
실제 행 수는 `SELECT COUNT(*) FROM t;`로 확인해야 한다.

---

**[30번] 정답: ③**

`V$` 뷰는 성능 관련 동적 뷰로, DBA 권한 또는 `SELECT ANY DICTIONARY` 권한이 있어야 조회 가능하다.  
일반 HR 사용자는 기본적으로 접근 불가.

---

**[31번] 정답: ③**

`CONSTRAINT_TYPE = 'C'`는 두 가지를 포함한다:
1. **CHECK 제약 조건** (명시적 조건식)
2. **NOT NULL 제약 조건** (Oracle 내부적으로 `C` 타입으로 저장)

`SEARCH_CONDITION` 컬럼에서 `"COLUMN_NAME" IS NOT NULL` 형태면 NOT NULL, 그 외는 CHECK.

---

**[32번] 정답: ②**

```sql
SELECT * FROM user_tab_columns
WHERE  data_default IS NOT NULL;
```

기본값은 `DATA_DEFAULT` 컬럼에 저장된다. (`DEFAULT_VALUE`가 아님)

---

**[33번] 정답: ③**

다른 사용자(HR)의 테이블을 조회하려면 `USER_TABLES` (자신의 것만) 대신  
`ALL_TABLES`에서 `owner = 'HR'` 조건을 추가해야 한다.

```sql
SELECT table_name FROM all_tables WHERE owner = 'HR';
```

`DBA_TABLES`는 DBA 권한이 필요하다.

---

**[34번] 정답: ②**

`USER_CONS_COLUMNS.POSITION`: 복합 제약 조건(여러 열 조합)에서 해당 열의 순서를 나타낸다.

```
복합 PK (col1, col2) → col1: POSITION=1, col2: POSITION=2
```

---

**[35번] 정답: ③**

`R_CONSTRAINT_NAME`은 FOREIGN KEY(`R` 타입) 제약 조건에서만 값을 가진다.  
이 컬럼은 **참조하는 부모 테이블의 PK 제약 조건 이름**을 나타낸다.

---

**[36번] 정답: ②**

`USER_TAB_COLUMNS` 뷰는 테이블의 각 열에 대한 구조 정보(열 이름, 타입, 크기, NULL 허용 여부)를 제공한다.  
행 데이터나 제약 조건은 각각 테이블 자체와 `USER_CONSTRAINTS`에서 조회한다.

---

**[37번] 정답: ②**

`DESCRIBE user_tables`는 `user_tables` 뷰 **자체의 컬럼 구조**(메타데이터)를 보여준다.  
`user_tables`가 가진 컬럼 이름, 데이터 타입, NULL 허용 여부가 출력된다.

---

**[38번] 정답: ②**

```sql
SELECT table_name, comments
FROM   dictionary
WHERE  table_name LIKE '%CONS%';
```

`%CONS%` 패턴으로 USER_CONSTRAINTS, USER_CONS_COLUMNS, ALL_CONSTRAINTS 등 제약 조건 관련 뷰를 검색할 수 있다.

---

**[39번] 정답: ②**

```sql
SELECT object_name, object_type, last_ddl_time
FROM   user_objects
WHERE  object_type IN ('TABLE', 'VIEW', 'INDEX')
ORDER BY last_ddl_time DESC;
```

`IN` 절로 TABLE, VIEW, INDEX 세 유형 필터링 후 `last_ddl_time DESC`로 최근 수정 순 정렬.

---

**[40번] 정답: ②**

| 뷰 | 범위 |
|----|------|
| `USER_TAB_COMMENTS` | 자신이 소유한 테이블/뷰의 주석만 |
| `ALL_TAB_COMMENTS` | 접근 권한이 있는 모든 사용자의 테이블/뷰 주석 포함 |

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

**(B)** SQL이 더 완전하다:
- (A): FK 제약 조건 이름만 알 수 있음
- (B): 자식 테이블·FK 열 + 부모 테이블·PK 열까지 한눈에 파악

```sql
SELECT c.table_name    AS 자식_테이블,
       cc.column_name  AS FK_열,
       pc.table_name   AS 부모_테이블,
       pcc.column_name AS PK_열
FROM   user_constraints  c
JOIN   user_cons_columns cc  ON c.constraint_name  = cc.constraint_name  AND c.table_name  = cc.table_name
JOIN   user_constraints  pc  ON c.r_constraint_name = pc.constraint_name
JOIN   user_cons_columns pcc ON pc.constraint_name  = pcc.constraint_name AND pc.table_name = pcc.table_name
WHERE  c.constraint_type = 'R';
```

---

**[42번] 정답: ④**

`SEARCH_CONDITION` 컬럼은 `CONSTRAINT_TYPE = 'C'` (CHECK/NOT NULL)일 때만 값을 가진다.

- NOT NULL: `"COLUMN_NAME" IS NOT NULL`
- CHECK: `SALARY > 0` 등 조건식

PRIMARY KEY, UNIQUE, FOREIGN KEY는 `SEARCH_CONDITION`이 NULL이다.

---

**[43번] 정답: ①**

```sql
SELECT utc.table_name, utc.column_name, utc.data_type,
       uc.constraint_type, uc.constraint_name
FROM   user_tab_columns utc
LEFT JOIN user_cons_columns ucc ON utc.table_name = ucc.table_name AND utc.column_name = ucc.column_name
LEFT JOIN user_constraints  uc  ON ucc.constraint_name = uc.constraint_name AND ucc.table_name = uc.table_name
WHERE  utc.table_name = 'EMPLOYEES'
ORDER BY utc.column_id;
```

`LEFT JOIN`으로 제약 조건이 없는 열도 포함하여 조회한다.  
결과: 각 열마다 해당 열의 타입 + 적용된 제약 조건 유형과 이름이 함께 표시된다.  
여러 제약 조건이 있는 열은 여러 행으로 나타날 수 있다.

---

**[44번] 정답: ①**

NOT NULL 비율이 낮다는 것은 **많은 열이 NULL을 허용**한다는 의미이다.  
→ 설계 검토 필요: 필수 데이터가 없어도 되는 구조인가? NOT NULL 제약이 누락된 것은 아닌가?

이 쿼리는 데이터 무결성 감사(Data Integrity Audit)에 활용된다.

---

**[45번] 정답: ②**

`STATUS = 'INVALID'` 주요 발생 상황:
- 뷰가 참조하는 테이블의 구조가 변경됨
- 저장 프로시저/함수가 참조하는 객체가 삭제됨
- `ALTER TABLE DROP COLUMN`으로 뷰에서 참조하던 열이 없어짐

**해결:** `ALTER VIEW v COMPILE;` 또는 `ALTER PROCEDURE p COMPILE;`로 재컴파일.

---

**[46번] 정답: ①**

`SYS_C007123` 형식의 이름 = Oracle이 **자동 생성**한 제약 조건 이름.

사용자가 제약 조건을 정의할 때 `CONSTRAINT` 키워드로 명시적 이름을 주지 않으면 Oracle이 `SYS_Cn` 형식으로 자동 부여한다.

**권장 방법:**
```sql
-- 자동 이름 (권장하지 않음)
salary NUMBER(8,2) CHECK(salary > 0)

-- 명시적 이름 (권장)
salary NUMBER(8,2) CONSTRAINT emp_salary_ck CHECK(salary > 0)
```

---

**[47번] 정답: ②**

`user_constraints`와 `user_cons_columns` **모두** `TABLE_NAME` 컬럼을 가지고 있다.  
`JOIN ... USING (constraint_name)`으로만 조인하면 `TABLE_NAME`에서 모호성(ambiguity)이 발생한다.  

따라서 `ON c.constraint_name = cc.constraint_name AND c.table_name = cc.table_name`으로 명시해야 한다.

---

**[48번] 정답: ②**

```sql
SELECT DISTINCT pc.table_name AS 부모_테이블
FROM   user_constraints  c
JOIN   user_constraints  pc ON c.r_constraint_name = pc.constraint_name
WHERE  c.constraint_type = 'R';
```

**흐름:**
1. `c` → FK 제약 조건 (constraint_type = 'R')
2. `c.r_constraint_name` → 참조하는 부모 PK 이름
3. `pc` → 그 PK가 속한 테이블 이름 = 부모 테이블

`DISTINCT`로 같은 부모 테이블이 여러 FK에서 참조되어도 중복 없이 조회.

---

**[49번] 정답: ②**

`NUMBER` (정밀도/스케일 미지정) 타입으로 선언된 경우:
- `DATA_PRECISION` = NULL
- `DATA_SCALE` = NULL

Oracle 최대 정밀도(38자리)를 허용하는 부동소수점 숫자로 처리된다.  
`NUMBER(p,s)`로 명시하면 `DATA_PRECISION = p`, `DATA_SCALE = s`가 저장된다.

---

**[50번] 정답: ②**

```sql
SELECT * FROM all_tab_privs WHERE table_schema = 'HR';
```

- `dba_tab_privs` → DBA 권한 필요 → 일반 HR 사용자 불가
- `all_tab_privs` → 자신에게 부여되었거나 자신이 부여한 권한을 조회 가능
- `user_tab_privs` → 자신이 **부여받은** 권한 (grantee = 현재 사용자)

`all_tab_privs WHERE table_schema = 'HR'`은 HR 스키마에 대한 접근 가능한 권한을 조회하는 가장 적합한 방법이다.
