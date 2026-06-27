# Oracle Database 19c: SQL Workshop
## Chapter 12 — 데이터 딕셔너리 뷰 소개 | SQL 실습 문제

> **실습 환경:** Oracle HR 스키마  
> **실습 전 참고:** 데이터 딕셔너리 뷰는 읽기 전용 메타데이터이므로 실습 후 정리가 필요 없다 (단, 주석 추가·제거는 별도 처리).

---

## Group 1. DICTIONARY & USER_OBJECTS 뷰 실습 (1~6번)

---

**[1번]** `DICTIONARY` 뷰의 구조를 확인하고, 이름에 'TABLE'이 포함된 딕셔너리 뷰를 모두 조회하시오.

```sql
-- 1단계: 구조 확인
DESCRIBE DICTIONARY;

-- 2단계: 이름에 TABLE이 포함된 뷰 조회
SELECT table_name, comments
FROM   dictionary
WHERE  table_name LIKE '%TABLE%'
ORDER BY table_name;
```

결과에서 확인된 뷰 이름을 3개 이상 나열하시오.

---

**[2번]** `USER_OBJECTS` 뷰에서 현재 사용자가 소유한 객체를 유형별로 조회하시오.

```sql
SELECT object_type, COUNT(*) AS object_count
FROM   user_objects
GROUP BY object_type
ORDER BY object_count DESC;
```

어떤 유형(object_type)이 가장 많은가?

---

**[3번]** `USER_OBJECTS` 뷰에서 테이블(TABLE)만 필터링하여 이름, 생성일, 최종 수정일, 상태를 조회하시오.

---

**[4번]** `USER_OBJECTS` 뷰에서 STATUS가 'INVALID'인 객체가 있는지 확인하시오.

```sql
SELECT object_name, object_type, status
FROM   user_objects
WHERE  status = 'INVALID';
```

결과가 없으면 현재 스키마가 유효한 상태임을 의미한다. 이 조회가 실무에서 언제 유용한지 설명하시오.

---

**[5번]** `ALL_OBJECTS` 뷰와 `USER_OBJECTS` 뷰의 결과 건수 차이를 확인하시오.

```sql
SELECT 'USER_OBJECTS' AS source, COUNT(*) AS cnt FROM user_objects
UNION ALL
SELECT 'ALL_OBJECTS',            COUNT(*) FROM all_objects;
```

두 결과의 차이가 의미하는 바를 설명하시오.

---

**[6번]** `USER_OBJECTS` 뷰에서 가장 최근에 DDL 변경이 이루어진 객체 5개를 조회하시오.

---

## Group 2. USER_TABLES & USER_TAB_COLUMNS 실습 (7~12번)

---

**[7번]** `USER_TABLES` 뷰를 DESCRIBE로 확인하고, HR 스키마의 모든 테이블 이름을 조회하시오.

```sql
DESCRIBE user_tables;
SELECT table_name FROM user_tables ORDER BY table_name;
```

---

**[8번]** `USER_TAB_COLUMNS`에서 EMPLOYEES 테이블의 모든 열 정보를 조회하시오.

```sql
SELECT column_name, data_type, data_length,
       data_precision, data_scale, nullable, data_default
FROM   user_tab_columns
WHERE  table_name = 'EMPLOYEES'
ORDER BY column_id;
```

다음 질문에 답하시오:
- NOT NULL 열은 몇 개인가?
- 기본값(DEFAULT)이 있는 열은?
- NUMBER 타입 열은 몇 개인가?

---

**[9번]** `USER_TAB_COLUMNS`에서 HR 스키마 전체에서 VARCHAR2 타입인 열의 최대 길이 Top 5를 조회하시오.

```sql
SELECT table_name, column_name, data_length
FROM   user_tab_columns
WHERE  data_type = 'VARCHAR2'
ORDER BY data_length DESC
FETCH FIRST 5 ROWS ONLY;
```

---

**[10번]** `USER_TAB_COLUMNS`에서 각 테이블의 열 개수를 조회하시오.

```sql
SELECT table_name, COUNT(*) AS col_count
FROM   user_tab_columns
GROUP BY table_name
ORDER BY col_count DESC;
```

---

**[11번]** `USER_TAB_COLUMNS`에서 NULL을 허용하지 않는(NOT NULL) 열의 비율을 테이블별로 계산하시오.

```sql
SELECT table_name,
       COUNT(*) AS total_cols,
       SUM(CASE WHEN nullable = 'N' THEN 1 ELSE 0 END) AS notnull_cols,
       ROUND(SUM(CASE WHEN nullable = 'N' THEN 1 ELSE 0 END) / COUNT(*) * 100) AS notnull_pct
FROM   user_tab_columns
GROUP BY table_name
ORDER BY notnull_pct DESC;
```

어떤 테이블이 가장 엄격한 NOT NULL 제약을 가지고 있는가?

---

**[12번]** `USER_TABLES`와 `USER_TAB_COLUMNS`를 조인하여 각 테이블의 이름, 열 수, 상태를 조회하시오.

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

## Group 3. USER_CONSTRAINTS & USER_CONS_COLUMNS 실습 (13~18번)

---

**[13번]** `USER_CONSTRAINTS` 뷰를 DESCRIBE로 확인하고, EMPLOYEES 테이블의 모든 제약 조건을 조회하시오.

```sql
DESCRIBE user_constraints;

SELECT constraint_name, constraint_type,
       search_condition, r_constraint_name,
       delete_rule, status
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES'
ORDER BY constraint_type;
```

제약 조건 유형(C/P/U/R)과 개수를 정리하시오.

---

**[14번]** `USER_CONS_COLUMNS` 뷰에서 EMPLOYEES 테이블의 제약 조건별 열 이름을 조회하시오.

```sql
SELECT constraint_name, column_name, position
FROM   user_cons_columns
WHERE  table_name = 'EMPLOYEES'
ORDER BY constraint_name, position;
```

---

**[15번]** `USER_CONSTRAINTS`와 `USER_CONS_COLUMNS`를 JOIN하여 EMPLOYEES의 모든 제약 조건과 적용 열을 함께 조회하시오.

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

---

**[16번]** HR 스키마에서 FOREIGN KEY 제약 조건을 가진 테이블과, 각 FK가 참조하는 부모 테이블을 조회하시오.

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

---

**[17번]** HR 스키마에서 PRIMARY KEY가 없는 테이블이 있는지 확인하시오.

```sql
SELECT t.table_name
FROM   user_tables t
WHERE  NOT EXISTS (
    SELECT 1 FROM user_constraints c
    WHERE  c.table_name = t.table_name
    AND    c.constraint_type = 'P'
);
```

---

**[18번]** NOT NULL 제약 조건의 `SEARCH_CONDITION`을 조회하여 각 열의 NOT NULL 조건식을 확인하시오.

```sql
SELECT table_name, constraint_name, search_condition
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES'
AND    constraint_type = 'C'
ORDER BY constraint_name;
```

`SEARCH_CONDITION` 컬럼에서 NOT NULL 조건과 일반 CHECK 조건을 구분하는 방법을 설명하시오.

---

## Group 4. 주석(COMMENT) 실습 (19~24번)

---

**[19번]** EMPLOYEES 테이블과 일부 열에 주석을 추가하시오.

```sql
-- 테이블 주석
COMMENT ON TABLE employees
IS '인사 관리 시스템 - 전체 사원 정보 저장 테이블';

-- 열 주석
COMMENT ON COLUMN employees.employee_id
IS '사원 고유 식별번호 (기본 키)';

COMMENT ON COLUMN employees.first_name
IS '사원 이름 (영문)';

COMMENT ON COLUMN employees.salary
IS '월 기본급 (단위: USD)';
```

---

**[20번]** 19번에서 추가한 EMPLOYEES 테이블 주석을 조회하시오.

```sql
SELECT table_name, table_type, comments
FROM   user_tab_comments
WHERE  table_name = 'EMPLOYEES';
```

---

**[21번]** 19번에서 추가한 EMPLOYEES 열 주석을 조회하시오.

```sql
SELECT column_name, comments
FROM   user_col_comments
WHERE  table_name = 'EMPLOYEES'
ORDER BY column_name;
```

주석이 없는 열의 COMMENTS 컬럼 값은 무엇인가?

---

**[22번]** DEPARTMENTS 테이블에도 주석을 추가하고 조회하시오.

```sql
-- 주석 추가
COMMENT ON TABLE departments
IS '부서 정보 테이블 - 회사 전체 부서 목록';

COMMENT ON COLUMN departments.department_id
IS '부서 고유 식별번호';

COMMENT ON COLUMN departments.department_name
IS '부서 정식 명칭';

-- 조회
SELECT table_name, comments FROM user_tab_comments WHERE comments IS NOT NULL;
```

---

**[23번]** `ALL_TAB_COMMENTS`와 `USER_TAB_COMMENTS`를 비교하여 접근 범위 차이를 확인하시오.

```sql
-- 두 뷰의 행 수 비교
SELECT 'USER_TAB_COMMENTS' AS view_name, COUNT(*) AS cnt
FROM   user_tab_comments
UNION ALL
SELECT 'ALL_TAB_COMMENTS', COUNT(*)
FROM   all_tab_comments;
```

---

**[24번]** EMPLOYEES 테이블의 주석을 삭제하고 삭제 여부를 확인하시오.

```sql
-- 테이블 주석 삭제 (빈 문자열 입력)
COMMENT ON TABLE employees IS '';

-- 열 주석 삭제
COMMENT ON COLUMN employees.employee_id IS '';
COMMENT ON COLUMN employees.first_name IS '';
COMMENT ON COLUMN employees.salary IS '';

-- 삭제 확인
SELECT table_name, comments
FROM   user_tab_comments
WHERE  table_name = 'EMPLOYEES';
-- comments가 NULL로 변경됨
```

---

## Group 5. 종합 활용 실습 (25~30번)

---

**[25번]** 데이터 딕셔너리를 활용하여 HR 스키마 전체 구조 보고서를 만드시오.

```sql
-- 테이블별 열 수, NOT NULL 비율, 제약 조건 수
SELECT t.table_name,
       t_col.col_count,
       t_con.constraint_count,
       ROUND(nn.notnull_col * 100 / t_col.col_count) AS notnull_pct
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

---

**[26번]** 특정 열 이름(예: 'DEPARTMENT_ID')이 어떤 테이블에서 사용되는지 조회하시오.

```sql
SELECT table_name, column_id, data_type, nullable
FROM   user_tab_columns
WHERE  column_name = 'DEPARTMENT_ID'
ORDER BY table_name;
```

`DEPARTMENT_ID` 열이 존재하는 테이블 목록과 각 테이블에서의 타입, NULL 허용 여부를 확인하시오.

---

**[27번]** HR 스키마에서 이름에 'DATE'가 포함된 열을 가진 테이블과 열 정보를 조회하시오.

```sql
SELECT table_name, column_name, data_type, nullable
FROM   user_tab_columns
WHERE  column_name LIKE '%DATE%'
ORDER BY table_name, column_name;
```

---

**[28번]** 딕셔너리를 활용하여 EMPLOYEES 테이블의 완전한 제약 조건 목록(유형, 열, 조건식, 참조 정보)을 하나의 SQL로 조회하시오.

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

---

**[29번]** `USER_OBJECTS`에서 HR 스키마 객체를 유형별로 정리하고, 가장 오래된 객체와 가장 최근에 수정된 객체를 각각 조회하시오.

```sql
-- 유형별 통계
SELECT object_type,
       COUNT(*) AS cnt,
       MIN(created) AS oldest,
       MAX(last_ddl_time) AS latest_change
FROM   user_objects
GROUP BY object_type
ORDER BY cnt DESC;
```

---

**[30번]** 딕셔너리를 활용하여 HR 스키마 테이블 중 EMPLOYEES를 참조하는 테이블 목록(자식 테이블)을 조회하시오.

```sql
-- EMPLOYEES의 PK 제약 조건 이름 확인
SELECT constraint_name
FROM   user_constraints
WHERE  table_name = 'EMPLOYEES'
AND    constraint_type = 'P';

-- 그 PK를 참조하는 FK가 있는 자식 테이블 조회
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

결과에서 어떤 테이블이 EMPLOYEES를 부모 테이블로 참조하고 있는지 확인하시오.
