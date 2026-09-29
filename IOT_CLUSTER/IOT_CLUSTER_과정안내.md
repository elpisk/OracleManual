# Oracle Database 19c IOT · CLUSTER 실습 과정 안내

> 원본 : `IOT_CLUSTER.pdf` (Practice Oriented Course for ADM & REC — Performance Tuning, KEY WORDS: IOT/CLUSTER)
> 원본의 명령 목록을 설명 + 실측 트랜스크립트 형태로 다시 구성한 것이다.
> 모든 출력은 Oracle 19.3.0 / Oracle Linux 7 / non-CDB / 8K 블록 랩에서 직접 측정한 값이다.

| 항목 | 내용 |
|---|---|
| 대상 | Oracle DBA / 성능 담당자 / 물리 설계를 하는 개발자 |
| 선수 지식 | SQL, 실행계획 읽기(DBMS_XPLAN), 세그먼트·익스텐트·버퍼 캐시 개념 |
| 환경 | Oracle 19.3.0 (IOT·CLUSTER 는 별도 옵션이 필요 없다), non-CDB ORCL, HR 샘플 스키마 |
| 실습 수 | 8종 (각 45~55분) |
| 총 소요 | 약 7시간 (1일) |
| 계정 | SYS (대상 스키마 HR). 원본 교안 표기를 따랐다 |

---

## 1. 세 가지 저장 구조

Oracle 의 테이블 저장 방식은 세 가지다.

```
① HEAP (기본)        데이터를 아무 블록에나 담는다. 인덱스는 따로.
   [테이블 세그먼트]  +  [인덱스 세그먼트]

② IOT (인덱스 구성)  테이블 자체가 B*Tree 다. 세그먼트가 하나(+오버플로).
   [인덱스 세그먼트 = 데이터]  (+ [오버플로 세그먼트])

③ CLUSTER           여러 테이블의 행을 같은 블록에 섞어 담는다.
   [클러스터 세그먼트 : 키별로 여러 테이블의 행이 함께]
```

| | HEAP | IOT | INDEX CLUSTER | HASH CLUSTER |
|---|---|---|---|---|
| 데이터 위치 | 테이블 세그먼트 | 기본키 인덱스 안 | 클러스터 세그먼트 | 클러스터 세그먼트 |
| 키 찾는 방법 | 인덱스 → ROWID | 인덱스 자체 | 클러스터 인덱스 | **해시 계산** |
| 기본키 필수 | 아니다 | **필수** | 아니다 | 아니다 |
| ROWID | 물리 | **논리(UROWID)** | 물리 | 물리 |
| 등치 조회 I/O | 3 | 3 | — | **1** |
| 범위 조회 | 인덱스 유리 | **항상 유리** | 불가 | 불가 |
| 공간 사전 할당 | 없음 | 없음 | 없음 | **HASHKEYS × SIZE** |
| 신규 설계 권장 | 기본 | 조건부 | 거의 안 함 | 거의 안 함 |

(등치 조회 I/O 는 10만 건 테이블에서 측정한 `Buffers` 값이다)

---

## 2. IOT — 인덱스 구성 테이블

### 2-1. 만드는 법

```sql
CREATE TABLE hr.emp_iot (
  emp_id    NUMBER,
  emp_name  VARCHAR2(50),
  emp_email VARCHAR2(200),
  emp_notes VARCHAR2(2000),
  CONSTRAINT emp_iot_pk PRIMARY KEY (emp_id)
)
ORGANIZATION INDEX
TABLESPACE users
PCTFREE 0
INCLUDING emp_email          -- 여기까지 인덱스에, 이후는 오버플로로
OVERFLOW TABLESPACE users;
```

| 실측 사실 | 값 |
|---|---|
| 기본키가 없으면 | `ORA-25175: no PRIMARY KEY constraint found` (UNIQUE 로는 불가) |
| 기본키를 떼어 내면 | `ORA-25188` — 제거·비활성화·지연 모두 불가 |
| `dba_tables.iot_type` | `IOT` / `IOT_OVERFLOW` / `IOT_MAPPING` |
| `dba_tables.blocks` | **NULL** — 테이블 세그먼트가 없다 |
| `dba_indexes.index_type` | `IOT - TOP` |
| 세그먼트 | 기본키 인덱스 이름으로 하나 (`EMP_IOT_PK`) |
| `clustering_factor` | **0** — 인덱스 순서 = 데이터 순서 |
| LONG 컬럼 | `ORA-02160` (CLOB 은 가능) |

**모니터링 쿼리를 고쳐야 한다.** IOT 의 크기·통계는 `dba_tables` 가 아니라 `dba_indexes` 에 있고, 세그먼트 이름은 테이블 이름이 아니라 기본키 인덱스 이름이다.

### 2-2. OVERFLOW · INCLUDING · PCTTHRESHOLD

행이 인덱스 리프 블록에 담기지 못할 만큼 크면 일부를 떼어 낼 곳이 필요하다.

| 항목 | 내용 |
|---|---|
| OVERFLOW 없이 큰 컬럼 | **CREATE 단계에서** `ORA-01429` (INSERT 가 아니다) |
| 판단 기준 | 선언된 **최대** 행 길이. 실제 데이터 크기와 무관하다 |
| 8K 블록 기준 | `VARCHAR2(4000)` 하나만 있어도 임계값(약 3950바이트) 초과 |
| `PCTTHRESHOLD` | 기본 50, 유효 범위 **1~50**. 51 이상은 `ORA-25179` |
| `INCLUDING col` | 그 컬럼까지 인덱스, 이후 전부 오버플로 (크기와 무관, 예측 가능) |
| 확인 위치 | **`dba_indexes.pct_threshold` · `dba_indexes.include_column`** (`dba_tables` 에 없다) |
| `include_column` 값 | 컬럼 **번호** (이름이 아니다) |
| 오버플로 세그먼트 | `SYS_IOT_OVER_nnn`, `segment_type` 은 `TABLE` |
| 나중에 추가 | `ALTER TABLE ... ADD OVERFLOW TABLESPACE ...` 가능 |
| `PCTTHRESHOLD` 변경 | 새로 넣는 행에만 적용. 기존 행은 `MOVE` 해야 재배치된다 |

**오버플로 접근 비용 (실측, 2000건)**

| 조회 | Buffers |
|---|---|
| 단건, 인덱스 컬럼만 | 2 |
| 단건, 오버플로 컬럼 포함 | 3 |
| 1000건 범위, 인덱스 컬럼만 | **8** |
| 1000건 범위, 오버플로 컬럼 포함 | **258** |

32배다. **자주 조회하는 컬럼을 모두 `INCLUDING` 안쪽에 넣었는지**가 IOT 설계의 핵심이다.
그리고 오버플로 접근은 **실행계획에 별도 단계로 나타나지 않는다.** `INDEX UNIQUE SCAN` 한 줄로 똑같이 보이고 `Buffers` 로만 구분된다.

### 2-3. 비트맵 인덱스와 MAPPING TABLE

```sql
CREATE BITMAP INDEX ... ON iot_table(col);
ORA-28669: bitmap index can not be created on an IOT with no mapping table
```

비트맵 인덱스는 물리 ROWID 를 비트 위치로 쓴다. IOT 는 논리 ROWID 라 불가능하다.
`MAPPING TABLE` 절을 주면 `SYS_IOT_MAP_nnn` 힙 테이블(`iot_type = IOT_MAPPING`)이 생기고 그 위에 비트맵 인덱스를 만들 수 있다. 세그먼트가 하나 늘고 DML 마다 대응표를 유지해야 한다.

### 2-4. 논리 ROWID 와 보조 인덱스

| 구분 | 값 |
|---|---|
| 힙 ROWID | `AAASoVAAHAAAAH7AAE` — 18자, 물리 주소 |
| IOT ROWID | `*BAHAAd8CwQb+` — 13자, `*` 로 시작하는 UROWID |
| `DBMS_ROWID` 사용 | `PLS-00306` — 물리 ROWID 전용 패키지다 |

IOT 의 보조 인덱스는 `키 + 논리 ROWID(기본키값) + 물리 추측(guess)` 를 담는다.
추측이 유효한 비율이 **`dba_indexes.pct_direct_access`** 다.

```
|   1 |  INDEX UNIQUE SCAN| EMP_IOT_CMP_PK  |   <- 상위: 기본키 인덱스
|   2 |   INDEX RANGE SCAN| EMP_IOT_CMP_IX1 |   <- 하위: 보조 인덱스
```

| 시점 | pct_direct_access | 같은 조회 Buffers |
|---|---|---|
| 보조 인덱스 생성 직후 | 100 | 5 |
| `ALTER TABLE ... MOVE` 후 | **0** | **7** (물리 읽기 2 발생) |
| `ALTER INDEX ... UPDATE BLOCK REFERENCES` 후 | 100 | 5 |

인덱스 상태는 `VALID` 를 유지한다. **`UNUSABLE` 이 되지 않으므로 오류가 나지 않고 조용히 느려진다.**

```sql
-- MOVE 뒤에는 반드시 한 단계로 묶어 실행한다
ALTER TABLE hr.emp_iot_cmp MOVE TABLESPACE users;
ALTER INDEX hr.emp_iot_cmp_ix1 UPDATE BLOCK REFERENCES;   -- 보조 인덱스마다
ANALYZE INDEX hr.emp_iot_cmp_ix1 COMPUTE STATISTICS;      -- 확인
```

보조 인덱스에는 기본키 값이 들어 있으므로 **`(보조키, 기본키)` 만 읽는 쿼리는 매우 싸다** (실측 Buffers 4).

### 2-5. 키 압축과 파티션

```sql
ORGANIZATION INDEX ... COMPRESS 2     -- 선두 2개 컬럼의 중복 제거
```

| 구성 | prefix_length | leaf_blocks | 세그먼트 |
|---|---|---|---|
| `COMPRESS 2` | 2 | 587 | **5MB** |
| 압축 없음 | — | 756 | 7MB |

5만 건에서 29% 감소. IOT 는 데이터 전체가 인덱스이므로 키 압축이 **테이블 크기에 직접 반영**된다. 선두 컬럼이 반복되는 복합 기본키에서 효과가 크다.

IOT 도 파티션할 수 있다. 단 파티션 정보는 `dba_tab_partitions` 가 아니라 **`dba_ind_partitions`** 에 있고, 세그먼트는 `INDEX PARTITION` 으로 잡힌다. 기본키에 파티션 키가 포함돼야 한다.

---

## 3. IOT 와 HEAP — 실측 비교

같은 컬럼 구성(`OVERFLOW` 없음), 10만 건, 8K 블록.

| 측정 항목 | HEAP | IOT | 판정 |
|---|---|---|---|
| 적재 시간 | 4.18초 | 6.59초 | 힙 유리 (1.6배) |
| 세그먼트 합계 | 25MB + 2MB = **27MB** | **26MB** | 차이 없음 |
| `blevel` | 1 | **2** | IOT 인덱스가 깊다 |
| `clustering_factor` | 3,125 | **0** | — |
| 기본키 단건 조회 | Buffers **3** | Buffers **3** | 차이 없음 |
| 기본키 범위 1001건 | Buffers **36** | Buffers **36** | 차이 없음 |
| 키가 아닌 조건 | FULL SCAN 3,147 | FAST FULL 3,281 | 힙 약간 유리 |
| `COUNT(*)` | 인덱스 스캔 **266** | **3,281** | **힙 12배 유리** |
| 2만 건 UPDATE | 0.06초 | 0.09초 | 차이 없음 |

### 그럼 IOT 는 왜 쓰는가

위 표만 보면 IOT 를 쓸 이유가 없다. 조건이 하나 빠져 있다. **힙이 기본키 순서로 적재돼 있었다.**

같은 데이터를 무작위 순서로 다시 담으면:

| 구조 | clustering_factor | 범위 조회 계획 | Buffers |
|---|---|---|---|
| 힙 (키 순서 적재) | 3,125 | INDEX RANGE SCAN + BY ROWID | 36 |
| 힙 (무작위 적재) | **99,973** | **TABLE ACCESS FULL** | **3,230** |
| IOT | 0 | INDEX RANGE SCAN | **36** |

90배다. `clustering_factor` 가 건수에 가까워지면 옵티마이저가 인덱스를 아예 포기한다.

> **IOT 의 가치는 "빠르다" 가 아니라 `clustering_factor` 를 영구히 0 으로 고정한다는 것이다.**
> 힙은 DML 이 쌓이면 정렬이 깨져 주기적 재구성이 필요하다. IOT 는 그럴 일이 없다.

### 중간 키 INSERT 와 블록 분할

`PCTFREE 0` 인 IOT 에 감소하는 키로 2만 건을 끼워 넣었다.

| 구조 | 변화 | 배수 |
|---|---|---|
| 힙 | 테이블 25→30MB, 인덱스 2→3MB | 1.2배 |
| IOT | 26MB → **53MB**, leaf_blocks 3,225 → 6,668 | **2.0배** |

50/50 블록 분할 때문에 모든 리프 블록이 절반만 찬다.

| 적재 패턴 | 설정 |
|---|---|
| 키가 계속 증가 (시퀀스·날짜) | `PCTFREE 0` |
| 키가 중간에 끼어듦 (자연키·코드) | `PCTFREE 10~20` + 주기적 `COALESCE` / `MOVE` |

---

## 4. 다중 버퍼 풀 — IOT 와 함께 쓴다

IOT 는 성질이 다른 두 세그먼트로 나뉘므로 버퍼 풀 분리와 잘 맞는다.

```sql
ALTER SYSTEM SET db_keep_cache_size    = 50M SCOPE=BOTH;   -- 동적. 재기동 불필요
ALTER SYSTEM SET db_recycle_cache_size = 30M SCOPE=BOTH;

CREATE TABLE ... ORGANIZATION INDEX
  STORAGE (BUFFER_POOL KEEP)        -- 인덱스(본체) 세그먼트
  INCLUDING emp_email
  OVERFLOW STORAGE (BUFFER_POOL RECYCLE);   -- 오버플로 세그먼트

-- 나중에 바꿀 때는 두 절을 구분한다
ALTER TABLE t STORAGE (BUFFER_POOL KEEP);
ALTER TABLE t OVERFLOW STORAGE (BUFFER_POOL RECYCLE);
```

| 실측 사실 | 값 |
|---|---|
| 설정 결과 | DEFAULT 624MB → 540MB, KEEP 52MB, RECYCLE 32MB |
| 버퍼 개수 | KEEP 6,344 / RECYCLE 3,904 / DEFAULT 65,880 |
| 파라미터 vs 실제 | 50M → 52MB (입도 단위 반올림) |
| ASMM | KEEP·RECYCLE 은 **자동 조정 대상이 아니다** |

**2만 건(인덱스 2MB / 오버플로 40MB) 두 번 조회**

| 조회 | 1회차 | 2회차 | 풀 물리 읽기 |
|---|---|---|---|
| 인덱스 컬럼만 (KEEP) | Buffers 199 | Buffers 199, **Reads 없음** | 증가 0 |
| 오버플로 포함 (RECYCLE) | Buffers 5,256 / Reads 4,998 | 같음 | 매번 +4,998 |

`v$bh` 로 확인하면 KEEP 쪽은 202 블록 전체가 남아 있고, RECYCLE 쪽은 **정확히 3,904 블록**(풀 크기 상한)만 남아 있다.

> **RECYCLE 은 그 SQL 을 빠르게 하려고 쓰는 것이 아니다.** 목적은 큰 세그먼트가 DEFAULT 풀을 오염시켜 **다른 SQL** 을 느리게 만드는 것을 막는 격리다.

측정 도구

| 뷰 | 보는 것 |
|---|---|
| `v$sga_dynamic_components` | 풀 크기 |
| `v$buffer_pool` | 풀별 버퍼 개수 |
| `v$buffer_pool_statistics` | 풀별 논리·물리 읽기 (컬럼은 `buffers` 가 아니라 **`set_msize`**) |
| `v$bh` | 오브젝트별 실제 캐시 블록 수 |
| `dba_segments.buffer_pool` | 세그먼트의 풀 지정 |

---

## 5. 인덱스 클러스터

```sql
CREATE CLUSTER hr.personnel_cluster (deptno NUMBER(2)) SIZE 512 TABLESPACE users;
CREATE INDEX  hr.personnel_cluster_idx ON CLUSTER hr.personnel_cluster;
CREATE TABLE  hr.dept_clu (...) CLUSTER hr.personnel_cluster (deptno);
CREATE TABLE  hr.emp_clu  (...) CLUSTER hr.personnel_cluster (deptno);
```

순서를 지켜야 한다. 인덱스를 빼먹으면 `ORA-02032: clustered tables cannot be used before the cluster index is built` 다.

| 항목 | 내용 |
|---|---|
| `SIZE 512` | 키 하나가 쓸 바이트 수. 8K 블록이면 블록당 키 16개로 계산 |
| 세그먼트 | **클러스터 이름으로 하나.** 테이블 이름의 세그먼트가 **없다** |
| `dba_tables.cluster_name` | 그 테이블이 속한 클러스터 |
| `dba_clu_columns` | 클러스터 컬럼 ↔ 테이블 컬럼 매핑 (이름이 달라도 된다) |
| `dba_indexes` | `index_type = CLUSTER`, `table_type = CLUSTER` |
| 건강 지표 | `dba_clusters.avg_blocks_per_key` — 1 이 이상적 |
| 통계 수집 | **`ANALYZE CLUSTER ... COMPUTE STATISTICS`** (dbms_stats 로는 안 채워진다) |
| DROP | 테이블이 남아 있으면 `ORA-00951` → `INCLUDING TABLES` |

**실측 — 편중이 지표를 무너뜨린다**

| 시점 | avg_blocks_per_key | 클러스터 세그먼트 |
|---|---|---|
| 부서 2개 · 직원 3명 | 1 | 64KB |
| 부서 10 에 5,000건 추가 | **7** | 192KB |

`SIZE 512` 로 잡았는데 한 키의 데이터가 훨씬 커졌다. 클러스터는 **키마다 행 수가 균일하고 예측 가능할 때만** 동작한다.

**조인 계획 (부서 10 의 직원 5,002명)**

| 구조 | 계획 | Buffers |
|---|---|---|
| 클러스터 | NESTED LOOPS + **TABLE ACCESS CLUSTER** | 16 |
| 일반 테이블 | NESTED LOOPS + TABLE ACCESS FULL | 18 |

차이가 작다. 클러스터의 이득은 **키가 아주 많고, 키마다 행 수가 적고 균일하며, 항상 키 하나씩 조인해서 읽을 때** 나타난다.

---

## 6. 해시 클러스터

```sql
CREATE CLUSTER hr.hash_emp_cluster (empno NUMBER(6))
  SIZE 1024 HASHKEYS 10000 TABLESPACE users;      -- 클러스터 인덱스 불필요
CREATE TABLE hr.emp_hash_tab (...) CLUSTER hr.hash_emp_cluster (empno);
```

| 실측 사실 | 값 |
|---|---|
| `HASHKEYS 10000` | → **10007** (다음 소수로 올림). 5000 → 5003 |
| 생성 직후 세그먼트 | **12MB / 1,536 블록 / 익스텐트 27개** — 데이터 0건인데 |
| 클러스터 인덱스 | **필요 없다.** 해시 계산으로 블록을 찾는다 |
| `function` | `DEFAULT2` (내부 함수) / `HASH IS col` 을 주면 `COLUMN` |
| 등치 조회 | `TABLE ACCESS HASH`, **Buffers 1** |
| 범위 조회 | 해시가 쓰이지 않는다 (기본키 인덱스 또는 FULL SCAN) |
| `HASHKEYS` 변경 | **불가.** 재생성 + 데이터 이동뿐 |
| `SINGLE TABLE` | `single_table = Y`, 두 번째 테이블은 `ORA-25136` |

**힙 + 인덱스와 비교 (1만 건)**

| 항목 | 해시 클러스터 | 힙 + 인덱스 | 배수 |
|---|---|---|---|
| 등치 조회 | Buffers **1** | Buffers 3 | 해시 3배 유리 |
| 범위 101건 | Buffers 2 | Buffers 3 | 비슷 |
| 공간 | **12MB** | 0.31 + 0.25 = 0.56MB | **21배 낭비** |

실무에서 `Buffers 3` 도 대부분 버퍼 캐시에서 처리된다. 즉 이득이 "디스크 I/O 3→1" 이 아니라 "메모리 접근 3→1" 인 경우가 많다. 그래서 해시 클러스터를 쓸 이유가 점점 줄었다.

**쓸 조건 네 가지 (모두 맞아야 한다)**

1. 조회가 항상 키 등치(`=` 또는 `IN`)
2. 키 개수를 미리 알 수 있고 거의 변하지 않는다
3. 키마다 행 수가 균일하다
4. 공간을 미리 잡아도 괜찮다

---

## 7. 구조 전환

IOT 는 `ALTER TABLE` 로 전환할 수 없다. 방법은 두 가지다.

### ① CTAS + RENAME

```sql
-- 컬럼 목록에 데이터형을 쓰면 ORA-01773 이다. 이름만 나열한다
CREATE TABLE hr.acct_iot (
  acct_no, seq, amt, memo,
  CONSTRAINT acct_iot_pk PRIMARY KEY (acct_no, seq)
)
ORGANIZATION INDEX TABLESPACE users PCTFREE 0
AS SELECT acct_no, seq, amt, memo FROM hr.acct_heap;

-- 검증 : 건수 + MINUS (양방향)
SELECT COUNT(*) FROM (SELECT * FROM hr.acct_heap MINUS SELECT * FROM hr.acct_iot);

ALTER TABLE hr.acct_heap RENAME TO acct_heap_old;
ALTER TABLE hr.acct_iot  RENAME TO acct_heap;
```

따라오지 않는 것 — **보조 인덱스 · 외래키 · 체크 제약 · 권한 · 트리거 · 통계**.
`dbms_metadata.get_ddl` 로 원본 DDL 을 먼저 뽑아 체크리스트를 만든다.
제약 이름은 그대로 남는다(`ACCT_IOT_PK`). 필요하면 `ALTER TABLE ... RENAME CONSTRAINT`.

### ② DBMS_REDEFINITION (온라인)

```sql
EXEC dbms_redefinition.can_redef_table('HR','ACCT_HEAP', dbms_redefinition.cons_use_pk)
-- 중간 테이블을 목표 구조(IOT)로 만든다
EXEC dbms_redefinition.start_redef_table('HR','ACCT_HEAP','ACCT_INT', 'acct_no acct_no, ...')
-- 대량이면 중간에 sync_interim_table 로 변경분을 미리 반영해 잠금 시간을 줄인다
EXEC dbms_redefinition.finish_redef_table('HR','ACCT_HEAP','ACCT_INT')
```

제약·인덱스 이름이 중간 테이블 것으로 남는다(`ACCT_INT_PK`).

**되돌리는 경로는 CTAS 뿐이다.** IOT 전환은 되돌리기 어려운 결정이므로 전환 전 백업과 원본 보존 기간을 정해 둔다.

---

## 8. 적용 기준

```
① 이 테이블은 기본키로만 조회하는가
      아니다 -> HEAP (기본). 끝.
        ↓ 그렇다
② 기본키로 범위 조회를 하는가
      아니다 (등치만) -> HEAP + 인덱스로 충분하다
                        (키 개수가 고정이고 공간을 낭비해도 좋다면 HASH CLUSTER 검토)
        ↓ 그렇다
③ 데이터가 키 순서로 들어오는가
      아니다 -> IOT 가 특히 유리하다 (힙은 clustering_factor 가 무너진다)
      그렇다 -> 이득이 작다. 힙 + 인덱스도 충분하다
        ↓
④ COUNT(*) · 키만 읽는 집계가 주력인가
      그렇다 -> IOT 는 불리하다 (실측 12배). 힙을 쓰거나 보조 인덱스를 둔다
        ↓
⑤ 자주 쓰는 컬럼을 INCLUDING 안쪽에 모을 수 있는가
      아니다 -> IOT 이득이 사라진다 (범위 조회 Buffers 8 vs 258)
        ↓
⑥ ROWID 를 쓰는 코드가 있는가
      있다 -> 함께 수정하거나 대상에서 제외한다 (논리 ROWID)
        ↓
    IOT 채택. PCTFREE 를 적재 패턴에 맞춰 정하고,
    보조 인덱스가 있으면 MOVE 후 UPDATE BLOCK REFERENCES 를 절차에 넣는다
```

### 실무에서 IOT 가 잘 맞는 테이블

- 코드·분류 테이블 (실제로 **HR.COUNTRIES 가 IOT 다** — 샘플 스키마가 그렇게 만들어져 있다)
- 다대다 매핑 테이블 (두 키만 있고 부가 컬럼이 없다 → 공간 절약 효과가 크다)
- 기간+키로 범위 조회하는 이력 테이블 (파티션 IOT)
- 인덱스 전용 조회 테이블 (보조 인덱스만으로 답이 나오는 구조)

### 클러스터는 언제 쓰나

신규 설계에는 거의 쓰지 않는다. 같은 목적(조인 블록 지역성)을 지금은 파티션 · IOT · 머티리얼라이즈드 뷰 · 인메모리로 달성한다.
알아야 하는 이유는 **진단**이다. 실행계획에 `TABLE ACCESS CLUSTER` 나 `TABLE ACCESS HASH` 가 보이면 그 테이블은 클러스터에 속해 있고 세그먼트·통계·관리 방법이 전부 다르다.

---

## 9. 운영 점검 쿼리

```sql
-- ① IOT · 클러스터 목록
SELECT table_name, iot_type, iot_name, cluster_name, partitioned
FROM   dba_tables
WHERE  owner = 'HR' AND (iot_type IS NOT NULL OR cluster_name IS NOT NULL)
ORDER  BY table_name;

-- ② 보조 인덱스 추측(guess) 이 깨진 IOT  ← 가장 중요
--    index_type='NORMAL' 필터가 없으면 정상인 IOT 기본키 인덱스가 모두 오탐으로 잡힌다
SELECT i.index_name, i.table_name, i.pct_direct_access
FROM   dba_indexes i, dba_tables t
WHERE  i.owner = 'HR' AND i.index_type = 'NORMAL'
AND    t.owner = i.owner AND t.table_name = i.table_name AND t.iot_type = 'IOT'
AND    i.pct_direct_access < 100
ORDER  BY i.index_name;

-- ③ 클러스터 건강 지표 (1 에 가까워야 한다)
SELECT cluster_name, cluster_type, hashkeys, single_table, avg_blocks_per_key
FROM   dba_clusters WHERE owner = 'HR' ORDER BY cluster_name;

-- ④ 해시 클러스터 공간 낭비
SELECT c.cluster_name, c.hashkeys, c.key_size,
       ROUND(s.bytes/1024/1024,1) AS alloc_mb,
       (SELECT ROUND(SUM(t.num_rows * t.avg_row_len)/1024/1024,1)
        FROM dba_tables t WHERE t.owner = c.owner AND t.cluster_name = c.cluster_name) AS data_mb
FROM   dba_clusters c, dba_segments s
WHERE  c.owner = 'HR' AND s.owner = c.owner AND s.segment_name = c.cluster_name
ORDER  BY c.cluster_name;

-- ⑤ KEEP · RECYCLE 지정 세그먼트 크기 합 (풀 크기와 비교한다)
SELECT buffer_pool, COUNT(*) AS segs, ROUND(SUM(bytes)/1024/1024,1) AS mb
FROM   dba_segments WHERE buffer_pool <> 'DEFAULT' GROUP BY buffer_pool;
```

---

## 10. 오류 사전 (이 과정에서 실제로 재현한 것)

| 오류 | 상황 | 대응 |
|---|---|---|
| `ORA-25175` | 기본키 없이 `ORGANIZATION INDEX` | `PRIMARY KEY` 를 정의한다 (UNIQUE 로는 불가) |
| `ORA-25188` | IOT 의 기본키 제거·비활성화 | 불가. 테이블 재생성 (CTAS / 온라인 재정의) |
| `ORA-01429` | OVERFLOW 없이 큰 컬럼을 가진 IOT 생성 | `OVERFLOW` 절 추가. **CREATE 단계에서** 거부된다 |
| `ORA-25179` | `PCTTHRESHOLD` 51 이상 | 1~50 범위로 |
| `ORA-28669` | MAPPING TABLE 없이 비트맵 인덱스 | `MAPPING TABLE` 절을 주고 다시 만든다 |
| `ORA-02160` | IOT 에 `LONG` 컬럼 | `CLOB` 으로 바꾼다 |
| `ORA-01773` | IOT CTAS 에 데이터형 지정 | 컬럼 이름만 나열한다 |
| `PLS-00306` | IOT 의 ROWID 를 `DBMS_ROWID` 에 전달 | 물리 ROWID 전용 패키지다 |
| `ORA-02032` | 클러스터 인덱스 없이 클러스터 테이블 사용 | `CREATE INDEX ON CLUSTER` 를 먼저 |
| `ORA-00951` | 테이블이 남은 클러스터 `DROP` | `INCLUDING TABLES` |
| `ORA-25136` | `SINGLE TABLE` 해시 클러스터에 두 번째 테이블 | 일반 해시 클러스터로 만든다 |
| `ORA-00904` | `v$buffer_pool_statistics.buffers` | 컬럼 이름은 `set_msize` 다 |

---

## 11. 실습 구성

| # | 파일 | 주제 | 핵심 실측 |
|---|---|---|---|
| 01 | `IOT_CLUSTER_실습_01_IOT_구조.txt` | ORGANIZATION INDEX, 딕셔너리, 정렬 제거, 논리 ROWID | `ORA-25175`, 정렬 Buffers 3 vs 24 |
| 02 | `IOT_CLUSTER_실습_02_OVERFLOW와_INCLUDING.txt` | OVERFLOW · INCLUDING · PCTTHRESHOLD · MAPPING TABLE | 범위 조회 Buffers **8 vs 258** |
| 03 | `IOT_CLUSTER_실습_03_KEEP_RECYCLE_버퍼풀.txt` | KEEP/RECYCLE 풀, v$bh, 풀별 물리 읽기 | KEEP 물리읽기 0 / RECYCLE 매번 4,998 |
| 04 | `IOT_CLUSTER_실습_04_IOT와_HEAP_비교.txt` | 적재·크기·단건·범위·전체·갱신·블록 분할 | 무작위 힙 3,230 vs IOT **36**, 26→53MB |
| 05 | `IOT_CLUSTER_실습_05_보조인덱스와_논리ROWID.txt` | 보조 인덱스, pct_direct_access, 압축, 파티션 IOT | 100→0→100, Buffers 5→7→5 |
| 06 | `IOT_CLUSTER_실습_06_INDEX_CLUSTER.txt` | CREATE CLUSTER, avg_blocks_per_key, 조인 계획 | 1 → **7**, `ORA-02032` |
| 07 | `IOT_CLUSTER_실습_07_HASH_CLUSTER.txt` | HASHKEYS 소수 올림, TABLE ACCESS HASH, 공간 | 10000→**10007**, Buffers **1**, 21배 낭비 |
| 08 | `IOT_CLUSTER_실습_08_전환과_운영점검.txt` | CTAS · DBMS_REDEFINITION 전환, 점검 쿼리 4종 | HR.COUNTRIES 가 IOT, 12MB vs 0.7MB |

실습은 순서대로 진행한다. 04 가 만든 `hr.emp_iot_cmp` 를 05 가 이어 쓰고, 06·07 의 클러스터를 08 의 점검 쿼리가 대상으로 삼는다.

강의용 슬라이드는 `IOT_CLUSTER_IOT와_클러스터.pptx` 다. 이 문서의 1~10절과 같은 구성이며 모든 슬라이드에 발표자 노트가 있다.

### 실습 환경 준비 (SYS 로 한 번)

```sql
-- HR 샘플 스키마 확인
SELECT COUNT(*) FROM hr.employees;

-- USERS 테이블스페이스 여유 (전 과정에서 최대 200MB 를 쓴다)
SELECT tablespace_name, ROUND(SUM(bytes)/1024/1024,1) AS free_mb
FROM   dba_free_space WHERE tablespace_name = 'USERS' GROUP BY tablespace_name;

-- 실습 03 을 위한 SGA 여유 확인 (DEFAULT 버퍼 캐시가 100MB 이상이어야 한다)
SELECT component, current_size/1024/1024 AS mb FROM v$sga_dynamic_components
WHERE  current_size > 0;
```

DEFAULT 버퍼 캐시가 작으면 실습 03 전에 SGA 를 늘린다 (재기동 필요).

```sql
ALTER SYSTEM SET sga_max_size = 1200M SCOPE=SPFILE;
ALTER SYSTEM SET sga_target   = 1000M SCOPE=SPFILE;
-- SHUTDOWN IMMEDIATE / STARTUP
```

### 실습 환경 정리 (전 과정을 마친 뒤)

```sql
ALTER SYSTEM SET db_keep_cache_size    = 0 SCOPE=BOTH;
ALTER SYSTEM SET db_recycle_cache_size = 0 SCOPE=BOTH;

DROP TABLE hr.emp_iot PURGE;
DROP TABLE hr.emp_heap0 PURGE;
DROP TABLE hr.iot_small PURGE;
DROP TABLE hr.iot_ovf PURGE;
DROP TABLE hr.emp_iot_ovf PURGE;
DROP TABLE hr.emp_iot_thr PURGE;
DROP TABLE hr.emp_iot_map PURGE;
DROP TABLE hr.emp_iot_pool PURGE;
DROP TABLE hr.emp_heap PURGE;
DROP TABLE hr.emp_heap_rnd PURGE;
DROP TABLE hr.emp_iot_cmp PURGE;
DROP TABLE hr.iot_comp PURGE;
DROP TABLE hr.iot_nocomp PURGE;
DROP TABLE hr.iot_part PURGE;
DROP TABLE hr.dept_heap PURGE;
DROP TABLE hr.emp_heap_c PURGE;
DROP TABLE hr.emp_hash_heap PURGE;
DROP TABLE hr.acct_heap PURGE;
DROP TABLE hr.acct_back PURGE;
DROP CLUSTER hr.personnel_cluster   INCLUDING TABLES;
DROP CLUSTER hr.hash_emp_cluster    INCLUDING TABLES;
DROP CLUSTER hr.single_hash_cluster INCLUDING TABLES;
DROP SEQUENCE hr.iot_seq;
```

`HR.COUNTRIES` 는 샘플 스키마 원본이므로 건드리지 않는다.
