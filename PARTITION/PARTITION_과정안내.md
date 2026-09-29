# Oracle Database 19c 파티셔닝 실습 과정 안내

> 원본 : `Partition.pdf` (Prep course for DBA Practicum — Performance Tuning, KEY WORDS: Partition Table/Index)
> 원본의 명령 목록을 설명 + 실측 트랜스크립트 형태로 다시 구성한 것이다.
> 모든 출력은 Oracle 19.3.0 / Oracle Linux 7 / non-CDB / 8K 블록 랩에서 직접 측정한 값이다.

| 항목 | 내용 |
|---|---|
| 대상 | Oracle DBA / 성능 담당자 / 대용량 테이블을 설계하는 개발자 |
| 선수 지식 | SQL, 실행계획 읽기(EXPLAIN PLAN · DBMS_XPLAN), 세그먼트·익스텐트 개념 |
| 환경 | Oracle 19.3.0 Enterprise Edition + Partitioning 옵션, non-CDB ORCL, HR 샘플 스키마 |
| 실습 수 | 11종 (각 40~60분) |
| 총 소요 | 약 9시간 (1.5일) |
| 계정 | SYS (대상 스키마 HR). 원본 교안 표기를 따랐다 |

---

## 1. 파티셔닝이란 무엇인가

하나의 테이블을 **여러 개의 세그먼트로 나누어 저장**하고, 애플리케이션에는 **하나의 테이블로 보이게** 하는 기능이다.

```
                논리적으로 하나의 테이블 (SALES)
   ┌──────────────────────────────────────────────────────────┐
   │  P2023        P2024        P2025        PMAX             │
   │ [세그먼트]    [세그먼트]    [세그먼트]    [세그먼트]      │  <- 물리적으로는 따로
   └──────────────────────────────────────────────────────────┘
        ↑ 2024년 조건으로 조회하면 P2024 하나만 읽는다 (프루닝)
```

### 얻는 것 네 가지

| 이득 | 설명 | 확인하는 실습 |
|---|---|---|
| **성능** | 조건에 맞는 파티션만 읽는다 (파티션 프루닝) | 02 · 08 |
| **관리성** | 파티션 단위로 DROP · TRUNCATE · MOVE · 백업한다 | 06 · 07 · 11 |
| **가용성** | 한 파티션에 문제가 생겨도 다른 파티션은 정상 조회된다 | 09 · 10 |
| **비용** | 오래된 파티션을 느린 디스크·압축 테이블스페이스로 내린다 (ILM) | 07 |

관리성 쪽 이득이 성능보다 크다는 점을 먼저 이해해야 한다.
1억 건 테이블에서 지난 달 데이터를 `DELETE` 하면 몇 시간이 걸리고 UNDO·REDO 가 폭증한다.
`ALTER TABLE ... DROP PARTITION` 은 몇 초에 끝나고 REDO 도 거의 없다.

### 도입 기준

| 기준 | 목표값 |
|---|---|
| 테이블 크기 | 수 GB 이상 (또는 향후 그렇게 될 것) |
| 파티션 하나의 크기 | 최소 수십만 건 이상. 파티션마다 기본 8MB 를 먼저 잡는다 |
| 조회 패턴 | 특정 범위·코드값으로 조회하는 SQL 이 대부분이다 |
| 관리 요건 | 기간 단위로 데이터를 버리거나 옮긴다 |
| 라이선스 | **Partitioning 옵션** (Enterprise Edition 별도 유상 옵션) |

`SELECT * FROM v$option WHERE parameter='Partitioning'` 이 `TRUE` 인지 먼저 확인한다.

---

## 2. 파티션 방식

### 2-1. RANGE — 순서가 있는 값을 자른다

```sql
CREATE TABLE hr.emp_yr
PARTITION BY RANGE (hire_date)
(PARTITION p2004 VALUES LESS THAN (TO_DATE('2005-01-01','YYYY-MM-DD')),
 PARTITION p2005 VALUES LESS THAN (TO_DATE('2006-01-01','YYYY-MM-DD')),
 PARTITION pmax  VALUES LESS THAN (MAXVALUE))
TABLESPACE users;
```

- `VALUES LESS THAN` 은 **미만**이다. 경계값 자신은 다음 파티션으로 간다.
- `MAXVALUE` 파티션이 없으면 범위를 넘는 값에서 `ORA-14400` 이 난다.
- 가장 많이 쓰이는 방식이다. 이력·로그·거래 테이블은 거의 전부 이것이다.
- 파티션 키 컬럼은 삭제할 수 없다 (`ORA-12984`). 키 변경은 테이블 재생성이다.

### 2-2. INTERVAL — 파티션을 자동으로 만든다 (11g)

```sql
PARTITION BY RANGE (hire_date) INTERVAL (NUMTOYMINTERVAL(1,'year'))
(PARTITION p2004 VALUES LESS THAN (TO_DATE('2005-01-01','YYYY-MM-DD')))
```

| 실측 사실 | 값 |
|---|---|
| `dba_part_tables.partition_count` | **1048575** (실제 개수가 아니라 이론상 상한) |
| 자동 생성 파티션 이름 | `SYS_Pnnn` — `dba_tab_partitions.interval` 이 `YES` |
| `MAXVALUE` 파티션과 공존 | 불가. 기존 RANGE 테이블에 `SET INTERVAL` 하면 `ORA-14759` |
| `ADD PARTITION` | 불가 (`ORA-14760`). 추가는 INSERT 가 대신한다 |
| 빈 구간 | 만들지 않는다. 2009~2011 이 없이 2012 파티션만 생길 수 있다 |
| 해제 | `ALTER TABLE ... SET INTERVAL ()` — 평범한 RANGE 로 돌아간다 |

- 실제 파티션 수는 `SELECT COUNT(*) FROM dba_tab_partitions` 로 센다.
- 자동 생성 이름은 `RENAME PARTITION FOR (값) TO 새이름` 으로 바꿀 수 있다.

### 2-3. HASH — 고르게 흩뿌린다

```sql
PARTITION BY HASH (employee_id) PARTITIONS 4
```

| 실측 사실 | 값 |
|---|---|
| 107건을 4개로 분산한 결과 | **25 / 32 / 31 / 19** (이상값 26.75) |
| `high_value` | 비어 있다 (경계값 개념이 없다) |
| 등치 조건 프루닝 | `PARTITION HASH SINGLE` — Buffers 2 |
| 범위 조건 프루닝 | **없다.** `PARTITION HASH ALL` — Buffers 8 |
| 파티션 추가 | `ADD PARTITION` — 한 파티션을 쪼갠다 (25 → 7 + 18) |
| 파티션 축소 | `COALESCE PARTITION` — 되분배해 원래 분포로 복귀 |
| `DROP PARTITION` | 불가 (`ORA-14255`) |

- 파티션 수는 **2의 거듭제곱**으로 잡는다. 그래야 분포가 고르다.
- 범위 조회가 주된 테이블에 HASH 를 쓰면 프루닝 이득이 **전혀 없다**.
- HASH 의 실제 이득은 파티션 단위 병렬 처리와 파티션 와이즈 조인, 경합 분산이다.

### 2-4. LIST — 값의 목록으로 묶는다

```sql
PARTITION BY LIST (department_id)
(PARTITION p_dept_1 VALUES (10,20,30,40),
 PARTITION p_dept_2 VALUES (50),
 PARTITION p_dept_4 VALUES (DEFAULT))
```

| 실측 사실 | 값 |
|---|---|
| `high_value` | 값 목록이 그대로 보인다 (`10, 20, 30, 40`) |
| NULL 의 행선지 | `DEFAULT` 파티션 (RANGE 에서는 MAXVALUE 쪽) |
| `DEFAULT` 가 있을 때 `ADD PARTITION` | `ORA-14323` |
| 값 추가 | `MODIFY PARTITION p ADD VALUES (120)` — 데이터 이동 없음 |
| 중복 값 추가 | `ORA-14312` (먼저 `DROP VALUES` 로 떼어 낸다) |
| `DEFAULT` 없이 범위 밖 INSERT | `ORA-14400` |

**자동 LIST 파티션 (19c)**

```sql
PARTITION BY LIST (department_id) AUTOMATIC
(PARTITION p_dept_10 VALUES (10))
```

- CTAS 만으로 부서값마다 파티션이 생겼다 (**11개**). 부서 999 를 넣으니 **12개**가 됐다.
- `dba_part_tables.autolist = YES`. `DEFAULT` 파티션과 함께 쓸 수 없다.
- 값 종류가 수천 개로 늘 수 있는 컬럼에는 쓰지 않는다.

### 2-5. COMPOSITE — 두 단계로 나눈다

```sql
PARTITION BY RANGE (hire_date)
SUBPARTITION BY LIST (department_id)
SUBPARTITION TEMPLATE
(SUBPARTITION s_dept_1 VALUES (10,20,30,40),
 SUBPARTITION s_dept_4 VALUES (DEFAULT))
(PARTITION p2005 VALUES LESS THAN (TO_DATE('2006-01-01','YYYY-MM-DD')), ...)
```

| 실측 사실 | 값 |
|---|---|
| 세그먼트 단위 | **서브파티션** (`segment_type = TABLE SUBPARTITION`) |
| 파티션 4 × 서브파티션 4 | 세그먼트 16개 중 **13개** (행 없는 3개는 생성 안 됨), 합 **104MB** |
| 템플릿 없는 이름 | `SYS_SUBPnnn` (예측 불가) |
| 템플릿 있는 이름 | `P2005_S_DEPT_1` — 파티션명_서브파티션명 |
| 상위 파티션의 `LOGGING` | `NONE` (속성은 서브파티션에 있다) |
| `ALTER TABLE ... LOGGING` | 상위·서브파티션 모두 `YES` 로 전파 |
| `granularity=>'AUTO'` 의 서브파티션 통계 | 테이블에 따라 다르다. 필요하면 `'ALL'` 을 명시한다 |

- **SUBPARTITION TEMPLATE 은 사실상 필수**다. 이름이 예측 가능해야 운영 스크립트를 쓸 수 있다.
- 용량은 곱셈이다. 파티션 12 × 서브파티션 8 = 세그먼트 96개 = 최소 768MB.

### 방식 선택 한 장 요약

| 조회·관리 패턴 | 방식 |
|---|---|
| 기간·금액 등 **범위**로 조회하고 기간 단위로 버린다 | RANGE (+ INTERVAL) |
| 지역·상태·부서 등 **코드값**으로 조회·관리한다 | LIST (+ AUTOMATIC) |
| 조회 조건은 거의 등치뿐이고 **분산**이 목적이다 | HASH |
| 조회 조건이 **항상 두 개**다 | COMPOSITE |

기준은 "무엇으로 조회하는가" 다. "무엇으로 나누고 싶은가" 가 아니다.

---

## 3. 저장 구조 — 파티션은 세그먼트다

```
TABLE (논리)
 └ TABLE PARTITION      <- 세그먼트 (단일 파티션)
     └ TABLE SUBPARTITION <- 세그먼트 (복합 파티션. 이때 상위는 논리적 묶음일 뿐)
```

### 3-1. 파티션 하나가 기본 8MB 를 먼저 잡는다 (실측)

`USERS`(초기 익스텐트 64KB, AUTOALLOCATE) 에 107건짜리 4파티션 테이블을 만들었을 때:

```
SEGMENT_NA PARTITIO SEGMENT_TYPE               KB     BLOCKS    EXTENTS
---------- -------- ------------------ ---------- ---------- ----------
EMP_YR     P2004    TABLE PARTITION          8192       1024          1
EMP_YR     P2005    TABLE PARTITION          8192       1024          1
EMP_YR     P2006    TABLE PARTITION          8192       1024          1
EMP_YR     PMAX     TABLE PARTITION          8192       1024          1
```

원인은 숨은 파라미터다.

| 파라미터 | 기본값 | 효과 |
|---|---|---|
| `_partition_large_extents` | **TRUE** | 테이블 파티션 첫 익스텐트를 8MB 로 잡는다 |
| `_index_partition_large_extents` | **FALSE** | 인덱스 파티션은 해당되지 않는다 |

Data Pump 가 뽑아 주는 DDL 에도 `STORAGE(INITIAL 8388608 ...)` 로 그대로 박혀 나온다.

**운영 의미** — 파티션 100개면 데이터가 없어도 800MB 를 먼저 잡는다.
월별 파티션을 5년치 미리 만들어 두는 설계는 용량 계획을 다시 해야 한다.

### 3-2. TRUNCATE 뒤 한 건만 넣어도 HWM 이 8MB 끝까지 올라간다 (실측)

```
시점                        총블록   미사용   HWM
--------------------------|--------|--------|------
생성 직후                    1024     1005     19
TRUNCATE PARTITION 직후      1024     1006     18
그 뒤 1건 INSERT             1024        0   1024   <- 8MB 전체가 포맷된다
SHRINK SPACE CASCADE 뒤        24        5     19
```

ASSM 은 블록을 묶음으로 포맷하므로 8MB 익스텐트 하나뿐인 세그먼트에
첫 행이 들어오면 그 익스텐트를 전부 포맷하고 HWM 을 끝까지 올린다.

풀 스캔은 HWM 까지 읽으므로 **1건짜리 파티션을 읽는 데 Buffers 36 · 물리 읽기 16** 이 들었고,
`SHRINK SPACE` 뒤에는 **Buffers 2** 가 됐다.

HWM 확인 방법 :

```sql
DECLARE
  v_tb NUMBER; v_tby NUMBER; v_ub NUMBER; v_uby NUMBER;
  v_lef NUMBER; v_leb NUMBER; v_lb NUMBER;
BEGIN
  FOR r IN (SELECT partition_name FROM dba_tab_partitions
            WHERE table_owner='HR' AND table_name='SAL_EMP' ORDER BY partition_position) LOOP
    dbms_space.unused_space('HR','SAL_EMP','TABLE PARTITION',
      v_tb, v_tby, v_ub, v_uby, v_lef, v_leb, v_lb, r.partition_name);
    dbms_output.put_line(RPAD(r.partition_name,8)||' HWM='||(v_tb - v_ub));
  END LOOP;
END;
/
```

### 3-3. 딕셔너리

| 뷰 | 보는 것 |
|---|---|
| `dba_part_tables` | 방식 · 파티션 수 · 기본 테이블스페이스 · `interval` · `autolist` · 서브파티션 방식 |
| `dba_tab_partitions` | 파티션별 `high_value`(LONG) · 통계 · 테이블스페이스 · `logging` · `segment_created` |
| `dba_tab_subpartitions` | 서브파티션별 같은 정보 |
| `dba_part_key_columns` | 파티션 키 컬럼과 순서 (컬럼 이름이 `name` 이다) |
| `dba_subpart_key_columns` | 서브파티션 키 컬럼 |
| `dba_part_indexes` | `locality`(LOCAL/GLOBAL) · `alignment`(PREFIXED/NON_PREFIXED) · 파티션 수 |
| `dba_ind_partitions` | 인덱스 파티션별 `blevel` · `leaf_blocks` · **`status`** |
| `dba_segments` | 파티션·서브파티션 단위 실제 크기 |

`high_value` 는 **LONG** 이다. `WHERE` 절·`SUBSTR`·조인에 쓸 수 없고(`ORA-00997`),
`SET LONG` 을 늘려야 전체가 보인다. 값으로 파티션을 찾으려면 `PARTITION FOR (값)` 을 쓴다.

### 3-4. 파티션 지정 조회

```sql
SELECT ... FROM hr.emp_yr PARTITION (p2005);                          -- 이름
SELECT ... FROM hr.emp_yr PARTITION FOR (DATE '2005-06-01');          -- 값 → 파티션
SELECT ... FROM hr.t SUBPARTITION (p2005_s_dept_2);                   -- 서브파티션 이름
SELECT ... FROM hr.t SUBPARTITION FOR (DATE '2005-06-01', 50);        -- 값 두 개
```

- 없는 이름 → `ORA-02149`
- 복합 파티션이 아닌데 `SUBPARTITION` 지정 → `ORA-14173`

---

## 4. 파티션 프루닝 — 실행계획 읽는 법

```sql
ALTER SESSION SET statistics_level = ALL;
SELECT /*+ gather_plan_statistics */ ... ;
SELECT * FROM TABLE(dbms_xplan.display_cursor(NULL,NULL,'ALLSTATS LAST +PARTITION'));
```

`+PARTITION` 을 빼면 `Pstart`/`Pstop` 이 나오지 않는다. 파티션 분석에서는 필수다.

### 4-1. 연산 이름으로 판정한다

| 연산 이름 | 의미 |
|---|---|
| `PARTITION RANGE SINGLE` | 파티션 하나만 읽었다 |
| `PARTITION RANGE ITERATOR` | 연속한 여러 파티션을 순회했다 |
| `PARTITION RANGE INLIST` | IN 리스트의 값들에 해당하는 파티션만 읽었다 |
| `PARTITION RANGE ALL` | **프루닝 실패.** 전부 읽었다 |
| `PARTITION RANGE AND` | 조인 상대가 값을 공급해 실행 시점에 골랐다 |
| `PARTITION RANGE JOIN-FILTER` | 블룸 필터로 골랐다 |
| `PARTITION HASH SINGLE / ALL` | HASH 파티션 (등치만 SINGLE) |
| `PARTITION LIST SINGLE / INLIST / ALL` | LIST 파티션 |

### 4-2. Pstart / Pstop 값 읽기

| 표시 | 의미 |
|---|---|
| `2 / 2` | 2번 파티션 하나 (정적 프루닝) |
| `1 / 2` | 1~2번 파티션 (정적, 범위) |
| `1 / 4` | 전체 (프루닝 없음) |
| `KEY` | 실행 시점 결정 (바인드 변수) |
| `KEY(I)` | 실행 시점 결정, IN 리스트 |
| `KEY(AP)` | 실행 시점 결정, 조인 상대가 값 공급 (AND-Pruning) |
| `:BF0000` | 블룸 필터로 결정 (해시 조인) |

`KEY` 는 프루닝 실패가 아니다. **`Starts` 와 `Buffers` 로 실제 읽은 양을 확인**해야 판정할 수 있다.

### 4-3. 53만 5천 건 테이블 실측 비교

| 조건 | 연산 | Pstart/Pstop | Buffers |
|---|---|---|---|
| `salary BETWEEN 5000 AND 8000` (상수) | RANGE SINGLE | 2 / 2 | **1338** |
| `salary BETWEEN 3000 AND 8000` (상수) | RANGE ITERATOR | 1 / 2 | 3064 |
| `salary BETWEEN :b1 AND :b2` (바인드) | RANGE ITERATOR | KEY / KEY | **1338** |
| `salary IN (2500, 24000)` | RANGE INLIST | KEY(I) | 2378 |
| `salary + 0 BETWEEN 5000 AND 8000` | RANGE **ALL** | 1 / 4 | 3716 |
| `TO_CHAR(salary) = '6000'` | RANGE **ALL** | 1 / 4 | 3716 |
| `department_id = 50` (키 아님) | RANGE **ALL** | 1 / 4 | 3716 |
| `salary < 5000 OR department_id = 50` | RANGE **ALL** | 1 / 4 | 3716 |
| 조인 (NL, 상대가 값 공급) | RANGE **AND** | KEY(AP) | 1338 |
| 조인 (해시, 블룸 필터) | RANGE **JOIN-FILTER** | :BF0000 | 652 |

### 4-4. 프루닝이 깨지는 원인

1. **파티션 키에 연산·함수** — `키+0`, `NVL(키,0)`, `TRUNC(키)`, `키||''`
2. **형 변환** — 명시적(`TO_CHAR(키)`) 이든 **암시적**이든 같다.
   문자형 파티션 키에 숫자를 비교하면 조용히 사라진다. 가장 찾기 어려운 원인이다.
3. **파티션 키가 조건에 없다** — 설계 문제다. 키 선택을 다시 본다.
4. **OR 로 묶였다** — `UNION ALL` 분해를 검토한다.

성능 검증은 **애플리케이션과 같은 형태(바인드 변수)** 로 해야 한다.
상수로 테스트하면 정적 프루닝이라 항상 빠르다.

---

## 5. 파티션 인덱스

### 5-1. LOCAL 과 GLOBAL

| | LOCAL | GLOBAL |
|---|---|---|
| 구조 | 테이블 파티션 : 인덱스 파티션 = 1:1 | 테이블 파티션 구조와 무관 |
| 파티션 수 | 테이블과 **항상 같다** | 다를 수 있다 (실측 : 테이블 6, 인덱스 4) |
| 비접두 허용 | 허용 (`NON_PREFIXED`) | **불가** (`ORA-14038`) |
| UNIQUE 조건 | 키에 파티션 컬럼 포함 필수 (`ORA-14039`) | 제약 없음 |
| `DROP PARTITION` 영향 | 해당 인덱스 파티션만 함께 사라진다. 나머지 **USABLE** | **인덱스 전체 UNUSABLE** |
| `MOVE PARTITION` 영향 | 그 파티션만 UNUSABLE | 인덱스 전체 UNUSABLE |
| 전체 REBUILD | 불가 (`ORA-14086`) | 파티션 인덱스면 불가 / 비파티션이면 가능 |
| `status` 확인 위치 | `dba_ind_partitions` | 파티션이면 `dba_ind_partitions`, 아니면 `dba_indexes` |

**특별한 이유가 없으면 LOCAL 을 쓴다.** 파티션 단위 DDL 이 다른 파티션의 인덱스를 건드리지 않는다는 점 하나로 충분하다.

### 5-2. 접두(PREFIXED)와 비접두(NON_PREFIXED)

| | 정의 | 파티션 키 없는 조회 |
|---|---|---|
| PREFIXED | 인덱스 선두 컬럼 = 파티션 키 | 인덱스 파티션 하나만 탐색 |
| NON_PREFIXED | 인덱스 선두 컬럼 ≠ 파티션 키 | **인덱스 파티션 전부 탐색** (실측 Starts=6) |

비접두가 항상 나쁜 것은 아니다. 실측에서 인덱스 파티션 6개를 다 읽어도 Buffers 14 로,
테이블 풀 스캔(139) 보다 훨씬 쌌다. 다만 파티션이 수백 개면 그 오버헤드가 커진다.

### 5-3. UNUSABLE 을 만드는 작업과 대응

| 작업 | LOCAL | GLOBAL | 대응 |
|---|---|---|---|
| `DROP PARTITION` | 해당 파티션 제거, 나머지 정상 | **전체 UNUSABLE** | `UPDATE INDEXES` |
| `TRUNCATE PARTITION` | 대체로 정상 | 전체 UNUSABLE | `UPDATE INDEXES` |
| `MOVE PARTITION` | 그 파티션 UNUSABLE | 전체 UNUSABLE | `UPDATE INDEXES` 또는 `REBUILD` |
| `SPLIT` / `MERGE` | 관련 파티션 UNUSABLE | 전체 UNUSABLE | `UPDATE INDEXES` |
| `EXCHANGE PARTITION` | 관련 파티션 UNUSABLE | 전체 UNUSABLE | `INCLUDING INDEXES` / `UPDATE INDEXES` |

**모든 파티션 DDL 문장에 `UPDATE INDEXES` 를 붙이는 것을 절차서의 기본으로 삼는다.**

UNUSABLE 인덱스는 **오류를 내지 않는다**. 옵티마이저가 무시하고 풀 스캔으로 우회한다.
실측에서 Buffers 가 94 → 608 로 6배 늘었는데 오류는 없었다. 감시가 유일한 발견 수단이다.

```sql
-- 점검 (두 쿼리 모두 필요하다. 파티션 인덱스는 dba_indexes.status 가 N/A 다)
SELECT index_owner, index_name, partition_name FROM dba_ind_partitions WHERE status <> 'USABLE';
SELECT owner, index_name FROM dba_indexes WHERE status = 'UNUSABLE';

-- 복구 스크립트 생성
SELECT 'ALTER INDEX '||index_owner||'.'||index_name||
       ' REBUILD PARTITION '||partition_name||' ONLINE;'
FROM   dba_ind_partitions WHERE status <> 'USABLE';
```

---

## 6. 파티션 관리 DDL

| DDL | 하는 일 | 비용 | 대상 방식 |
|---|---|---|---|
| `ADD PARTITION` | 맨 뒤에 붙인다 | 즉시 (빈 세그먼트) | RANGE · LIST · HASH |
| `SPLIT PARTITION` | 하나를 둘로 자른다 | **데이터 재작성** | RANGE · LIST |
| `MERGE PARTITIONS` | 인접한 둘을 합친다 | **데이터 재작성** | RANGE · LIST |
| `DROP PARTITION` | 데이터까지 버린다 | 즉시 | RANGE · LIST |
| `TRUNCATE PARTITION` | 데이터만 비운다 | 즉시 | 전부 |
| `RENAME PARTITION` | 이름만 바꾼다 | 즉시 | 전부 |
| `MOVE PARTITION` | 다른 테이블스페이스로 옮긴다 | **데이터 재작성** | 전부 |
| `EXCHANGE PARTITION` | 일반 테이블과 맞바꾼다 | **즉시** (이름표 교환) | RANGE · LIST |
| `COALESCE PARTITION` | 파티션 수를 줄인다 | 재분배 | HASH |
| `MODIFY PARTITION ... SHRINK SPACE` | HWM 을 내린다 | 온라인 | 전부 |
| `MODIFY PARTITION ... ADD/DROP VALUES` | LIST 값 조정 | 즉시 | LIST |

### 실무에서 자주 쓰는 조합

```sql
-- ① 이력 보관 후 파티션 버리기 (대용량 DELETE 대체)
expdp ... tables=hr.sal_emp:part2 dumpfile=part2.dmp      -- 백업
ALTER TABLE hr.sal_emp DROP PARTITION part2 UPDATE INDEXES;

-- ② 대용량 적재 (서비스 중단 없이)
--    스테이징 적재 -> 인덱스 생성 -> 통계 수집 -> 교환
ALTER TABLE hr.sal_emp EXCHANGE PARTITION p5 WITH TABLE hr.stg INCLUDING INDEXES;

-- ③ MAXVALUE 파티션 정기 분할 (월 배치)
ALTER TABLE hr.sal_emp SPLIT PARTITION pmax AT (경계) INTO (PARTITION p202502, PARTITION pmax);

-- ④ 공간 회수
ALTER TABLE hr.sal_emp ENABLE ROW MOVEMENT;
ALTER TABLE hr.sal_emp MODIFY PARTITION part3 SHRINK SPACE CASCADE;
ALTER TABLE hr.sal_emp DISABLE ROW MOVEMENT;

-- ⑤ 오래된 파티션을 느린 디스크로
ALTER TABLE hr.sal_emp MOVE PARTITION part1 TABLESPACE part_arch ONLINE UPDATE INDEXES;
```

### 파티션 키 UPDATE 와 ROW MOVEMENT

파티션을 넘어가는 `UPDATE` 는 기본적으로 금지된다 (`ORA-14402`).

```sql
ALTER TABLE hr.sal_emp ENABLE ROW MOVEMENT;   -- 허용
```

- 내부적으로 DELETE + INSERT 다. **ROWID 가 바뀐다.**
- REDO·UNDO 가 일반 UPDATE 보다 많다. 기본값이 DISABLE 인 이유다.
- `SHRINK SPACE` 도 ROW MOVEMENT 를 요구한다 (`ORA-10636`).
- 근본 대책은 **변하지 않는 컬럼을 파티션 키로 잡는 것**이다.
  등록일·거래일은 변하지 않고 수정일은 변한다.

### EXCHANGE PARTITION 의 조건

| 조건 | 오류 |
|---|---|
| 컬럼 수·순서·타입이 같아야 한다 (이름은 달라도 된다) | `ORA-14096` |
| 모든 행이 그 파티션의 경계를 만족해야 한다 | `ORA-14099` |
| 검증을 건너뛰려면 `WITHOUT VALIDATION` | — |

`WITHOUT VALIDATION` 으로 경계를 위반한 행을 넣으면 **프루닝 때문에 조회되지 않는 유령 데이터**가 된다.
실측에서 `salary=45000` 인 행이 `p5`(30000 미만) 에 들어갔고, `salary=45000` 조건은 `pmax` 만 보므로 그 행을 못 찾는다.
스테이징 테이블에 같은 조건의 CHECK 제약을 걸면 검증이 빨라지므로 굳이 건너뛸 이유가 줄어든다.

---

## 7. 통계

```sql
EXEC dbms_stats.gather_table_stats('HR','SAL_EMP', granularity=>'AUTO')
EXEC dbms_stats.gather_table_stats('HR','SAL_EMP', partname=>'PART3', granularity=>'PARTITION')
```

| `granularity` | 수집 범위 |
|---|---|
| `AUTO` (기본) | 테이블 + 파티션 (서브파티션은 판단에 따라) |
| `GLOBAL` | 테이블 수준만 |
| `PARTITION` | 파티션 수준만 |
| `SUBPARTITION` | 서브파티션 수준만 |
| `ALL` | 전부 |

### 실측으로 확인한 것

- **구조 변경 DDL(`SPLIT`·`MERGE`) 은 통계를 무효화한다.** `num_rows` 가 `NULL` 이 된다.
  DDL 과 통계 수집을 한 단계로 묶어 절차서에 적는다.
- `partname` 으로 한 파티션만 수집하면 **테이블 수준 통계는 갱신되지 않는다.**
  실측에서 그 파티션만 `last_analyzed` 가 5초 뒤였고 테이블 통계는 그대로였다.
- **`EXCHANGE PARTITION` 은 통계까지 맞바꾼다.** 통계 없는 스테이징 테이블과 교환하면
  파티션 통계가 0 이 된다. 교환 **전에** 스테이징 테이블 통계를 수집해야 한다.
- 대용량에서는 증분 통계를 켠다.

```sql
EXEC dbms_stats.set_table_prefs('HR','SAL_EMP','INCREMENTAL','TRUE')
```

파티션만 수집해도 전체 통계를 합성해 준다. `global_stats = YES` 면 실제로 수집된 값이다.

---

## 8. Data Pump 로 파티션 다루기

```bash
# 테이블 전체
expdp system/oracle_4U directory=dirpump tables=hr.sal_emp dumpfile=t.dmp

# 파티션 하나
expdp system/oracle_4U directory=dirpump tables=hr.sal_emp:part2 dumpfile=p2.dmp

# 덤프에서 DDL 만 뽑기 (DB 에 아무 변화 없음)
impdp system/oracle_4U directory=dirpump dumpfile=t.dmp sqlfile=ddl.sql

# 특정 파티션 데이터만 넣기
impdp system/oracle_4U directory=dirpump dumpfile=t.dmp \
      tables=hr.sal_emp:pmax partition_options=merge table_exists_action=append

# 데이터만 넣기 (TRUNCATE 한 파티션 되채우기)
impdp system/oracle_4U directory=dirpump dumpfile=p2.dmp \
      tables=hr.sal_emp:part2 content=data_only

# 파티션을 독립 테이블로 떼어 내기
impdp system/oracle_4U directory=dirpump dumpfile=t.dmp \
      tables=hr.sal_emp partition_options=departition
```

| 옵션 | 값 | 동작 |
|---|---|---|
| `partition_options` | `none`(기본) | 파티션 구조를 그대로 재현 |
| | `merge` | 파티션 데이터를 대상 테이블 구조에 맞춰 합친다 |
| | `departition` | 파티션마다 독립 테이블 생성. 이름은 `원본_파티션명` |
| `table_exists_action` | `skip`(기본) | 이미 있으면 **아무 일도 하지 않는다** |
| | `append` / `truncate` / `replace` | 추가 / 비우고 넣기 / 재생성 |
| `content` | `data_only` | DDL 건너뛰고 데이터만 |

### 실측 사실

- `expdp`/`impdp` 로그는 **파티션마다 한 줄씩** 건수를 보고한다.
  `. . exported "HR"."SAL_EMP":"PART2"   7.601 KB   55 rows`
  → 이관 검증은 전체 건수가 아니라 **파티션별 건수 비교**로 한다.
- `remap_table` 은 `departition` 의 이름 규칙을 바꾸지 못했다. 규칙이 우선한다.
- 기본으로 통계까지 함께 온다 (`exclude=statistics` 로 제외).
- `table_exists_action` 기본값 `skip` 때문에 "성공했는데 데이터가 없다" 가 흔하다. **항상 명시한다.**
- Data Pump 는 논리 백업이다. 시점 복구·전체 복구는 RMAN 의 일이다.

---

## 9. 적용 기준 — 설계 순서

```
① 이 테이블이 파티셔닝 대상인가
     수 GB 이상 · 범위/코드 조회 위주 · 기간 단위 관리 필요 · 라이선스 보유
        ↓ 예
② 파티션 키를 무엇으로 할까
     v$sql 에서 그 테이블을 읽는 상위 SQL 의 WHERE 절을 모아 빈도를 센다
     가장 많이 쓰는 조건 컬럼을 키로 잡는다  (관리 편의보다 조회 패턴이 우선)
     변하지 않는 컬럼이어야 한다 (ROW MOVEMENT 회피)
        ↓
③ 방식은
     범위 -> RANGE (미래 파티션 관리가 부담이면 INTERVAL)
     코드값 -> LIST (값이 계속 늘면 AUTOMATIC)
     분산만 -> HASH (2의 거듭제곱, 등치 조회만 프루닝됨을 확인)
     조건이 항상 둘 -> COMPOSITE (+ SUBPARTITION TEMPLATE 필수)
        ↓
④ 파티션 개수와 크기
     파티션 하나가 최소 수십만 건 이상
     파티션당 기본 8MB 를 먼저 잡는다 -> 개수 x 8MB 를 용량 계획에 넣는다
        ↓
⑤ 인덱스
     조회 조건 = 파티션 키 -> LOCAL PREFIXED (기본 선택)
     조회 조건 != 파티션 키 -> LOCAL NON_PREFIXED 또는 GLOBAL
     기본키에 파티션 키를 포함시킬 수 있는가 -> UNIQUE LOCAL 가능 (권장)
        ↓
⑥ 운영 절차를 문서로 만든다
     파티션 추가 (ADD 또는 SPLIT pmax) · 주기와 담당자
     이력 보관·삭제 (expdp -> DROP PARTITION UPDATE INDEXES)
     통계 수집 (INCREMENTAL, DDL 직후 재수집)
     인덱스 상태 점검 (dba_ind_partitions / dba_indexes)
     공간 점검 (HWM 대비 실제 건수)
```

### 운영 점검 목록

```sql
-- 파티션 수와 방식
SELECT owner, table_name, partitioning_type, subpartitioning_type,
       (SELECT COUNT(*) FROM dba_tab_partitions p
        WHERE p.table_owner=t.owner AND p.table_name=t.table_name) AS real_parts
FROM   dba_part_tables t WHERE owner NOT IN ('SYS','SYSTEM');

-- UNUSABLE 인덱스 (두 쿼리 모두)
SELECT index_owner, index_name, partition_name FROM dba_ind_partitions WHERE status <> 'USABLE';
SELECT owner, index_name FROM dba_indexes WHERE status = 'UNUSABLE';

-- 통계가 낡은 파티션
SELECT table_owner, table_name, partition_name, num_rows, last_analyzed
FROM   dba_tab_partitions WHERE num_rows IS NULL OR last_analyzed < SYSDATE - 30;

-- MAXVALUE / DEFAULT 파티션이 비대해지지 않았는가
SELECT table_owner, table_name, partition_name, num_rows FROM dba_tab_partitions
WHERE  partition_name LIKE '%MAX%' OR partition_name LIKE '%DEFAULT%' ORDER BY num_rows DESC;

-- ROW MOVEMENT 가 켜진 테이블
SELECT owner, table_name, row_movement FROM dba_tables WHERE row_movement = 'ENABLED';
```

---

## 10. 오류 사전 (이 과정에서 실제로 재현한 것)

| 오류 | 상황 | 대응 |
|---|---|---|
| `ORA-01732` | UNION ALL 뷰(파티션 뷰) 에 DML | 파티션 테이블로 전환 |
| `ORA-02290` | 파티션 뷰의 CHECK 제약 위반 | 분기 판단을 DB 에 맡긴다 |
| `ORA-02149` | 없는 파티션 이름 지정 | `dba_tab_partitions` 로 이름 확인, `PARTITION FOR (값)` |
| `ORA-14400` | 경계에 맞는 파티션이 없다 | MAXVALUE/DEFAULT, INTERVAL/AUTOMATIC, 파티션 선행 생성 |
| `ORA-12984` | 파티션 키 컬럼 삭제 | 테이블 재생성 또는 `DBMS_REDEFINITION` |
| `ORA-00997` | `high_value`(LONG) 를 WHERE 에 사용 | `PARTITION FOR (값)`, PL/SQL 변수 |
| `ORA-14759` | MAXVALUE 가 있는 테이블에 `SET INTERVAL` | MAXVALUE 파티션 제거 후 재시도 |
| `ORA-14760` | INTERVAL 테이블에 `ADD PARTITION` | INSERT 가 추가를 대신한다 |
| `ORA-14173` | 복합 파티션이 아닌데 `SUBPARTITION` 지정 | `PARTITION` 으로 바꾼다 |
| `ORA-14255` | HASH 파티션에 `DROP PARTITION` | `COALESCE PARTITION` |
| `ORA-14323` | DEFAULT 파티션이 있는데 `ADD PARTITION` | DEFAULT 를 SPLIT 또는 `ADD VALUES` |
| `ORA-14312` | 다른 파티션에 이미 있는 값 추가 | 먼저 `DROP VALUES` |
| `ORA-14080` | 범위 밖의 값으로 `SPLIT` | `high_value` 확인 후 재시도 |
| `ORA-14074` | 마지막 파티션보다 낮은 경계로 `ADD` | `SPLIT` 을 쓴다 |
| `ORA-14274` | 인접하지 않은 파티션 `MERGE` | 인접한 쌍끼리 순서대로 |
| `ORA-14402` | 파티션 키 `UPDATE` | `ENABLE ROW MOVEMENT` |
| `ORA-10636` | ROW MOVEMENT 없이 `SHRINK SPACE` | `ENABLE ROW MOVEMENT` |
| `ORA-14096` | `EXCHANGE` 양쪽 컬럼 수 불일치 | `CTAS ... WHERE 1=2` 로 스테이징 생성 |
| `ORA-14099` | `EXCHANGE` 대상에 경계 위반 행 | 데이터 정리 또는 `WITHOUT VALIDATION` |
| `ORA-14039` | 파티션 키 없는 UNIQUE LOCAL 인덱스 | 키에 파티션 컬럼 포함 또는 GLOBAL |
| `ORA-14038` | 비접두 GLOBAL 파티션 인덱스 생성 | 선두 컬럼을 인덱스 파티션 키로 |
| `ORA-01502` | UNUSABLE 인덱스 사용 | `REBUILD PARTITION` |
| `ORA-14086` | 파티션 인덱스 전체 `REBUILD` | 파티션 단위로 반복 |
| `ORA-14078` | GLOBAL 인덱스의 마지막 파티션 `DROP` | `SPLIT`/`MERGE` 로 구조 조정 |

---

## 11. 실습 구성

| # | 파일 | 주제 | 핵심 실측 |
|---|---|---|---|
| 01 | `PARTITION_실습_01_파티션뷰의_한계.txt` | UNION ALL 뷰 + CHECK 제약, 바인드에서 무너지는 지점 | Buffers 6/7 vs 18, `ORA-01732` |
| 02 | `PARTITION_실습_02_Range_파티션과_딕셔너리.txt` | RANGE 생성, 딕셔너리 4종, 세그먼트, 프루닝 | 파티션당 8MB, `ORA-14400`, `ORA-12984` |
| 03 | `PARTITION_실습_03_Interval_파티션.txt` | INTERVAL 자동 생성, SYS_P, 해제 | `partition_count 1048575`, `ORA-14759/14760` |
| 04 | `PARTITION_실습_04_Hash와_List_파티션.txt` | HASH 분포·ADD/COALESCE, LIST DEFAULT·AUTOMATIC | 25/32/31/19, 자동 LIST 11→12 |
| 05 | `PARTITION_실습_05_Composite_파티션.txt` | RANGE-HASH, RANGE-LIST + 템플릿, 두 단계 프루닝 | 세그먼트 13/16 = 104MB |
| 06 | `PARTITION_실습_06_파티션관리_구조변경.txt` | SPLIT·ADD·RENAME·DROP·TRUNCATE·MERGE, ROW MOVEMENT | `ORA-14080/14074/14402/14274` |
| 07 | `PARTITION_실습_07_공간과_EXCHANGE_통계.txt` | HWM, SHRINK, MOVE, EXCHANGE, 파티션 통계 | HWM 1024→19, Buffers 36→2 |
| 08 | `PARTITION_실습_08_파티션_프루닝.txt` | 정적·동적·INLIST·실패 3종·조인 프루닝 | Buffers 1338 vs 3716 vs 652 |
| 09 | `PARTITION_실습_09_로컬_파티션인덱스.txt` | LOCAL, 접두/비접두, DROP vs MOVE, UPDATE INDEXES | `ORA-14039`, `ORA-01502` |
| 10 | `PARTITION_실습_10_글로벌_파티션인덱스.txt` | GLOBAL, 전체 UNUSABLE, 파티션 단위 복구 | Buffers 94→608→77, `ORA-14038/14086/14078` |
| 11 | `PARTITION_실습_11_DataPump_파티션이관.txt` | 파티션 단위 export/import, sqlfile, departition | 파티션별 건수 보고, `INITIAL 8388608` |

실습은 순서대로 진행한다. 06 이 만든 구조를 07 이 그대로 이어 쓰고, 07 이 만든 테이블스페이스를 09 가 쓴다.

강의용 슬라이드는 `PARTITION_파티셔닝.pptx` 다. 이 문서의 1~10절과 같은 구성이며 모든 슬라이드에 발표자 노트가 있다.

### 실습 환경 준비 (SYS 로 한 번)

```sql
-- Partitioning 옵션 확인 (TRUE 여야 한다)
SELECT parameter, value FROM v$option WHERE parameter = 'Partitioning';

-- HR 샘플 스키마와 employees(107건) 확인
SELECT COUNT(*) FROM hr.employees;

-- USERS 테이블스페이스 여유 확인 (실습 전체에서 최대 300MB 를 쓴다)
SELECT tablespace_name, ROUND(SUM(bytes)/1024/1024,1) AS free_mb
FROM   dba_free_space WHERE tablespace_name='USERS' GROUP BY tablespace_name;
```

```bash
# 실습 11(Data Pump) 용 디렉터리
[oracle@oel7v9 ~]$ mkdir -p /home/oracle/datapump
```

```sql
-- 실습 11 용 디렉터리 객체
CREATE OR REPLACE DIRECTORY dirpump AS '/home/oracle/datapump';
GRANT READ, WRITE ON DIRECTORY dirpump TO system;
```

실습 07 이 `part_arch` 테이블스페이스를 직접 만든다. 데이터파일 경로는 환경에 맞게 바꾼다.

### 실습 환경 정리 (전 과정을 마친 뒤)

```sql
DROP VIEW  hr.emp_part_vw;
DROP TABLE hr.part1 PURGE;
DROP TABLE hr.part2 PURGE;
DROP TABLE hr.part3 PURGE;
DROP TABLE hr.emp_yr PURGE;
DROP TABLE hr.emp_hash PURGE;
DROP TABLE hr.emp_list PURGE;
DROP TABLE hr.emp_comp PURGE;
DROP TABLE hr.emp_comp_rl PURGE;
DROP TABLE hr.emp_big PURGE;
DROP TABLE hr.emp_local PURGE;
DROP TABLE hr.emp_global PURGE;
DROP TABLE hr.exch_emp PURGE;
DROP TABLE hr.sal_emp PURGE;
DROP TABLE hr.sal_emp_part1 PURGE;
DROP TABLE hr.sal_emp_part2 PURGE;
DROP TABLE hr.sal_emp_part3 PURGE;
DROP TABLE hr.sal_emp_pmax  PURGE;
DROP TABLESPACE part_arch INCLUDING CONTENTS AND DATAFILES;
DROP DIRECTORY dirpump;
```

```bash
[oracle@oel7v9 ~]$ rm -f /home/oracle/datapump/*
```
