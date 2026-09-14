# 부하 생성 스크립트 (WL_01 ~ WL_06)

Oracle Database 19c 성능 튜닝 실무 과정의 **공용 자산**이다. 20챕터 110개 실습이 이 여섯 개
스크립트 위에서 돌아간다. 성능 데이터는 부하 없이 생기지 않는다. 조회만 하는 실습으로는
AWR·ASH가 비어 아무것도 배울 수 없다.

> **★ 개인 실습 환경 전용 ★**
> 파라미터 변경, 미커밋 트랜잭션 유지, 버퍼 캐시 비우기, 대량 리두·임시 공간 소비가 포함된다.
> 공유 DB나 운영 DB에서 실행하면 다른 세션의 응답시간이 눈에 띄게 나빠지거나 장애가 난다.

---

## 1. 6종 요약

| 스크립트 | 유발하는 것 | 핵심 관찰 지표 | 기본 소요 시간 | 사용 챕터 |
|---|---|---|---|---|
| `WL_01_parse.sql` | 리터럴 SQL 반복 실행으로 하드 파싱 폭증 (바인드 모드 대조 포함) | `parse count (hard)`, `V$LIBRARYCACHE`(SQL AREA), 공유 풀 사용량, 리터럴 커서 수 | 약 30초~2분 | **2 · 18** |
| `WL_02_io.sql` | 인덱스 경유 랜덤 단일 블록 읽기 + CLAIM_DETAILS 대량 전체 스캔 | `db file sequential read` / `db file scattered read`, `physical reads`, 요청당 블록 수 | 약 40초~2분 | **14 · 17 · 20** |
| `WL_03_sort.sql` | 작업 영역 축소 상태에서 대량 정렬·해시 조인·그룹핑 | `sorts (disk)`, `direct path write/read temp`, `V$SQL_WORKAREA`의 1-pass/multi-pass | 약 1~3분 | **19** |
| `WL_04_lock.sql` | 동일 행 갱신으로 TX 행 잠금 경합 (**최소 2세션**) | `enq: TX - row lock contention`, `V$SESSION.BLOCKING_SESSION`, `V$LOCK` | 약 1~2분 (`wl_hold_sec`) | **3 · 12 · 14** |
| `WL_05_commit.sql` | 소량 DML + 건당 커밋 / 배치 커밋 대조 | `log file sync`, `user commits`, `redo size`·`redo synch writes` | 약 30초~1분 30초 | **14** |
| `WL_06_mixed.sql` | 위 조합 — AWR 스냅샷 구간용 종합 부하 | Load Profile 전반, `V$SYS_TIME_MODEL`(DB time), `V$SYSTEM_WAIT_CLASS` | 약 3~5분 (`wl_cycles`) | **5 · 6 · 8 · 9 · 10 · 11** |

소요 시간은 일반적인 실습 VM 기준 추정치다. 각 스크립트 머리 주석의 **소요 시간** 항목에
산정 근거와 조절 방법이 적혀 있다. 실제 시간은 환경에 따라 달라지므로,
**WL_06은 실행 후 자신의 총 경과 시간을 출력한다.** 그 값을 보고 다음 실행의 `wl_cycles`를 정하면 된다.

---

## 2. 사전 준비 (1회)

### 2.1 대상 스키마

`SQLT` 계정이 소유한 진료비청구심사 스키마 7개 테이블
(`HOSPITALS` 1,000 / `PATIENTS` 50,000 / `DRUG_MASTER` 10,000 / `MEDICAL_CLAIMS` 300,000 /
`CLAIM_DETAILS` 1,000,000+ / `DISEASES` 약 400,000 / `REVIEW_LOG` 500,000).

이 스키마에는 **PK 인덱스만 존재하고 FK 컬럼에는 인덱스가 없다.** 스크립트는 이 사실을 전제로
설계돼 있다(랜덤 단일 블록 읽기는 `PK_CLAIM_DETAILS`·`PK_REVIEW_LOG`를 경유하고, 조인은
자연스럽게 해시 조인이 된다).

### 2.2 권한 부여

```sql
-- SYS AS SYSDBA 로 접속해 1회 수행
GRANT SELECT_CATALOG_ROLE TO SQLT;   -- V$ 뷰 조회 (전 스크립트 공통)
-- SQLT 에 CREATE TABLE 권한이 있어야 한다 (WL_04 / WL_05 / WL_06 의 복제 테이블)
```

`SELECT_CATALOG_ROLE`을 주기 어려운 환경이면 최소한 아래에 개별 SELECT를 부여한다.

```
V_$SYSSTAT  V_$MYSTAT  V_$STATNAME  V_$SYSTEM_EVENT  V_$SESSION_EVENT
V_$PARAMETER  V_$SESSION  V_$LOCK  V_$SQL  V_$SQLAREA  V_$LIBRARYCACHE
V_$SGASTAT  V_$SEGMENT_STATISTICS  V_$FILESTAT  V_$DATAFILE  V_$LOG
V_$LOG_HISTORY  V_$PGASTAT  V_$SQL_WORKAREA  V_$TEMPSEG_USAGE
V_$TEMP_SPACE_HEADER  V_$PGA_TARGET_ADVICE  V_$SYS_TIME_MODEL
V_$SYSTEM_WAIT_CLASS  V_$TRANSACTION  V_$SESSION_BLOCKERS
V_$MEMORY_DYNAMIC_COMPONENTS  DBA_OBJECTS  DBA_BLOCKERS  DBA_WAITERS
```

> `DBA_BLOCKERS` / `DBA_WAITERS` 는 `catblock.sql` 이 실행돼 있어야 존재한다.
> 없으면 `ORA-00942`가 나지만 WL_04의 나머지 조회는 그대로 진행된다.
> 없어도 `V$SESSION.BLOCKING_SESSION` 과 `V$SESSION_BLOCKERS` 로 같은 것을 볼 수 있다.

### 2.3 클라이언트 문자셋

스크립트는 UTF-8로 저장돼 있고 주석·화면 출력이 한글이다. 화면이 깨지면 SQL\*Plus 실행 전에
설정한다(SQL 실행 자체에는 영향이 없다 — 실행되는 SQL에는 한글 식별자·한글 리터럴이 없다).

```
-- Windows
set NLS_LANG=KOREAN_KOREA.AL32UTF8
chcp 65001
```

### 2.4 안전 점검

```sql
SHOW PARAMETER cursor_sharing        -- WL_01 은 EXACT 여야 한다(스크립트가 세션 수준으로 설정)
SHOW PARAMETER pga_aggregate_target  -- WL_03 실행 전 현재값을 기록해 둔다
SELECT TABLESPACE_NAME, ROUND(SUM(BYTES_FREE)/1024/1024) FREE_MB
  FROM V$TEMP_SPACE_HEADER GROUP BY TABLESPACE_NAME;   -- WL_03 은 수백 MB 를 쓴다
ARCHIVE LOG LIST                     -- WL_05 는 리두를 대량 생성한다
```

---

## 3. 공통 설계 규칙

여섯 스크립트가 모두 지키는 규칙이다. 트랜스크립트를 만들 때 이 규칙을 전제로 서술하면 된다.

1. **머리 주석 6항목** — `목적` / `전제` / `소요 시간` / `관찰 지표` / `되돌리기` / `주의`.
   `관찰 지표` 항에는 실제로 붙여 넣어 쓸 수 있는 조회 SQL이 함께 들어 있다.
2. **조절 변수는 파일 상단 `DEFINE` 블록에 모여 있다.** 반복 횟수·대상 건수·세션 역할·정리 여부를
   여기서만 바꾸면 된다. 기본값은 일반적인 실습 VM에서 30초~2분(WL_06만 3~5분)에 끝나도록 잡았고,
   그 산정 근거를 주석에 적어 두었다.
3. **원본 데이터를 훼손하지 않는다.** DML을 하는 `WL_04`·`WL_05`·`WL_06`은 `_WL` 접미사 복제
   테이블(`REVIEW_LOG_WL`, `REVIEW_LOG_CMT_WL`, `REVIEW_LOG_MIX_WL`)을 만들어 거기서만 작업한다.
   원본 7개 테이블에는 `INSERT`/`UPDATE`/`DELETE`/DDL이 **한 건도 없다.**
4. **인스턴스 파라미터를 바꾸지 않는다.** 재현에 필요한 설정은 전부 `ALTER SESSION` 수준으로
   처리하고, 인스턴스 수준이 꼭 필요한 경우(예: `PGA_AGGREGATE_TARGET` 축소)는 실행하지 않고
   **주석으로 명령과 원복 절차만 안내**한다. 유일한 예외인 `ALTER SYSTEM FLUSH BUFFER_CACHE`는
   기본값이 꺼짐(`wl_flush = 0`)이고, 운영 DB 금지 경고가 붙어 있다.
5. **스크립트가 스스로 전후 지표를 캡처한다.** 시작 시점에 `V$SYSSTAT`/`V$MYSTAT`/`V$SYSTEM_EVENT`/
   `V$SESSION_EVENT`(WL_06은 `V$SYS_TIME_MODEL`·`V$SYSTEM_WAIT_CLASS`까지)에서 관심 항목만 뽑아
   스냅샷을 잡고, 끝난 뒤 `전(前) / 후(後) / 델타` 3열 표를 출력한다.
   **이 과정의 핵심이 "조치 전후 비교"이므로 스크립트가 먼저 그 습관을 보여준다.**
6. **19c 문법만 사용한다.** 대기는 `DBMS_SESSION.SLEEP`(19c 사용 가능)을 쓰고,
   권한 문제가 잦은 `DBMS_LOCK.SLEEP`은 쓰지 않는다.
7. **복제 테이블 참조는 전부 동적 SQL이다.** 익명 블록은 제출 시점에 통째로 컴파일되므로,
   같은 스크립트 안에서 방금 만든 테이블을 정적 SQL로 참조하면 `PLS-00201`이 난다.

---

## 4. 실행 순서 권장안

### 4.1 처음 한 번 — 스크립트 동작 검증

부하가 실제로 지표를 움직이는지 확인하는 순서다. **1장 파일럿 제작 전에 이 순서로 한 번 돌려
검증한다.**

```
1) @WL_01_parse.sql     -- 하드 파싱 델타가 반복 횟수만큼 늘어나는가
2) @WL_02_io.sql        -- sequential / scattered read 가 구획별로 갈리는가
                        --   물리 읽기가 0에 가까우면 DEFINE wl_flush = 1 로 재실행
3) @WL_03_sort.sql      -- sorts (disk) 델타가 0보다 큰가
                        --   0이면 wl_sort_area 를 262144 로 줄여 재실행
4) WL_04 (터미널 3개)    -- SETUP -> A -> B -> C -> CLEANUP
5) @WL_05_commit.sql    -- 건당/배치 커밋의 log file sync 대기 횟수가 갈리는가
6) @WL_06_mixed.sql     -- 총 경과 시간을 확인하고 wl_cycles 를 조정
```

각 단계에서 **델타가 움직이지 않으면 그 스크립트의 조절 변수를 키운 뒤 다시 실행한다.**
움직이지 않는 부하로 만든 트랜스크립트는 학습이 성립하지 않는다.

### 4.2 챕터 진행 순서에 따른 사용

| Day | 챕터 | 실행할 스크립트 |
|---|---|---|
| 1 | 2 | `WL_01_parse` (LITERAL / BIND 대조) |
| 2 | 3 | `WL_04_lock` (SETUP → A → B → C) |
| 3 | 5 · 6 | `WL_06_mixed` (AWR 스냅샷 사이) |
| 4 | 8 | `WL_06_mixed` (보고서 판독용 구간 + 부하 없는 대조 구간) |
| 5 | 9 · 10 | `WL_06_mixed` (`wl_gap_sec`로 강약을 주면 ASH 스파이크 실습이 된다) |
| 6 | 11 · 12 | `WL_06_mixed` 2회(설정을 달리해 기간 비교) · `WL_04_lock` |
| 7 | 14 | `WL_02_io` · `WL_04_lock` · `WL_05_commit` |
| 9 | 17 · 18 | `WL_02_io` · `WL_01_parse` |
| 10 | 19 · 20 | `WL_03_sort` · `WL_02_io` |

### 4.3 AWR 구간을 만드는 표준 절차 (WL_06)

```sql
-- 터미널 1 (SYS AS SYSDBA)   🔒 Diagnostics Pack
EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;
SELECT MAX(SNAP_ID) FROM DBA_HIST_SNAPSHOT;      -- 시작 스냅 ID 기록

-- 터미널 2 (SQLT)
@WL_06_mixed.sql

-- (선택) 터미널 3,4 (SQLT) : 잠금 경합까지 포함하려면
--   DEFINE wl_role = A  / @WL_04_lock.sql
--   DEFINE wl_role = B  / @WL_04_lock.sql

-- 터미널 1 (SYS AS SYSDBA)
EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;
@?/rdbms/admin/awrrpt.sql
```

**라이선스가 없는 환경**은 Statspack 또는 WL_06이 출력하는 V\$ 기반 델타·Load Profile 요약을
그대로 쓴다.

```sql
@?/rdbms/admin/spcreate.sql     -- 설치 (PERFSTAT 계정)
EXEC STATSPACK.SNAP;            -- 부하 전
-- ... @WL_06_mixed.sql ...
EXEC STATSPACK.SNAP;            -- 부하 후
@?/rdbms/admin/spreport.sql
```

---

## 5. 스크립트별 조절 변수 요약

| 스크립트 | 변수 | 기본값 | 의미 |
|---|---|---|---|
| WL_01 | `wl_loops` / `wl_mode` / `wl_cs` | 5000 / BOTH / EXACT | 반복 횟수 / LITERAL·BIND·BOTH / 세션 CURSOR_SHARING |
| WL_02 | `wl_rand` / `wl_scan` / `wl_flush` / `wl_nodirect` | 5000 / 5 / 0 / 1 | 랜덤 조회 / 전체 스캔 / 버퍼 캐시 비우기 / 직렬 직접경로읽기 끄기 |
| WL_03 | `wl_sort_area` / `wl_hash_area` / `wl_div` / `wl_run_*` | 1MB / 2MB / 1 / 1 | 세션 작업 영역 크기 / 대상 축소 계수 / 구획 실행 여부 |
| WL_04 | `wl_role` / `wl_rows` / `wl_hold_sec` | SETUP / 1000 / 60 | 세션 역할 / 복제 행수 / 잠금 유지 시간 |
| WL_05 | `wl_rows` / `wl_batch` / `wl_run_nowait` / `wl_cleanup` | 5000 / 500 / 0 / 1 | 갱신 행수 / 배치 크기 / NOWAIT 구획 / 종료 시 정리 |
| WL_06 | `wl_cycles` / `wl_parse_loops` / `wl_rand` / `wl_scan` / `wl_sort_div` / `wl_commit_rows` / `wl_batch` / `wl_gap_sec` / `wl_cleanup` | 3 / 2000 / 2000 / 2 / 4 / 2000 / 200 / 5 / 1 | 주기 수와 주기당 부하량 |

`DEFINE` 값은 파일을 열어 고쳐도 되고, 스크립트를 부르기 전에 SQL\*Plus에서 덮어써도 된다.
다만 스크립트 안의 `DEFINE`이 나중에 실행되므로 **파일 안의 값이 이긴다** — 예외는
`WL_04`의 `wl_role`처럼 실행 전 지정을 전제로 한 변수이니, 이 경우 파일의 기본값을 직접 고친다.

---

## 6. 되돌리기 체크리스트

부하 실습을 마친 뒤 아래를 확인한다.

```sql
-- (1) 복제 테이블이 남아 있지 않은가
SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME LIKE '%\_WL' ESCAPE '\';
--     남아 있으면 :  DROP TABLE REVIEW_LOG_WL PURGE;  등

-- (2) 미커밋 트랜잭션이 남아 있지 않은가 (WL_04 이후 필수)
SELECT s.SID, s.USERNAME, t.STATUS, t.START_TIME
  FROM V$TRANSACTION t, V$SESSION s WHERE t.SES_ADDR = s.SADDR;

-- (3) 블로킹이 남아 있지 않은가
SELECT SID, BLOCKING_SESSION, EVENT, SECONDS_IN_WAIT
  FROM V$SESSION WHERE BLOCKING_SESSION IS NOT NULL;

-- (4) 세션 파라미터가 원복됐는가 (같은 세션을 계속 쓸 때)
SELECT NAME, VALUE FROM V$PARAMETER
 WHERE NAME IN ('cursor_sharing','workarea_size_policy','commit_wait','commit_logging');

-- (5) 인스턴스 파라미터는 애초에 바꾸지 않았다. 확인만 한다.
SHOW PARAMETER pga_aggregate_target
```

접속을 끊으면 세션 파라미터는 모두 기본값으로 돌아간다. 복제 테이블만 명시적으로 지우면 된다.

---

## 7. 잘 안 될 때

| 증상 | 원인 | 조치 |
|---|---|---|
| `ORA-00942: table or view does not exist` (V$ 뷰) | 카탈로그 조회 권한 없음 | `GRANT SELECT_CATALOG_ROLE TO SQLT;` |
| WL_01에서 하드 파싱이 안 늘어난다 | `CURSOR_SHARING`이 `FORCE`/`SIMILAR` | 스크립트가 세션 수준 `EXACT`로 설정한다. 인스턴스 값이 궁금하면 `SHOW PARAMETER cursor_sharing` |
| WL_02에서 `physical reads`가 거의 0 | 대상이 이미 버퍼 캐시에 있음 | `DEFINE wl_flush = 1` (개인 환경 전용) |
| WL_02에서 `scattered read` 대신 `direct path read` | 19c의 직렬 직접경로 읽기 | `wl_nodirect = 1`(기본). 실패하면 안내 메시지가 출력되며, 그대로 `direct path read`로 관찰해도 20장 소재가 된다 |
| WL_03에서 `sorts (disk)`가 0 | 작업 영역이 아직 넉넉함 | `wl_sort_area`를 262144로 낮춘다 |
| WL_03에서 `workarea executions - onepass`가 안 는다 | 이 통계는 `WORKAREA_SIZE_POLICY=AUTO`인 작업 영역만 집계 | `sorts (disk)`·temp 사용량으로 판정하고, pass 수는 `V$SQL_WORKAREA`로 본다 |
| WL_04에서 세션 B가 안 멈춘다 | 세션 A가 이미 롤백함 | `wl_hold_sec`를 늘리고 A→B 순서를 지킨다 |
| WL_04에서 블로킹이 안 풀린다 | A 터미널이 비정상 종료 | 근거 캡처 후 `ALTER SYSTEM KILL SESSION '<SID>,<SERIAL#>' IMMEDIATE;` |
| WL_05에서 `log file sync`가 안 는다 | 커밋 횟수가 부족 | `wl_rows`를 20000으로 올린다 |
| WL_06 총 시간이 목표와 다르다 | 환경 성능 차 | 출력된 총 경과 시간을 보고 `wl_cycles`를 비례 조정한다 |
| `ORA-01652` (temp 확장 실패) | 임시 테이블스페이스 부족 | `wl_div`/`wl_sort_div`를 올리거나 temp를 키운다. 4장에서는 이 오류 자체가 실습 소재다 |

---

## 8. 트랜스크립트 작성 시 지켜야 할 것

PRD 9.1과 11장 검증 기준에 따라, 이 스크립트를 쓰는 트랜스크립트는 다음을 만족해야 한다.

- **조치 전 → 조치 → 조치 후 3단 캡처**를 반드시 남긴다. 스크립트가 출력하는 델타 표를
  그대로 붙이면 "조치 전/후"가 자동으로 채워진다.
- **어느 시점에 어떤 `WL_` 스크립트를 어떤 변수값으로 몇 초간 돌렸는지** 명시한다.
- **환경에 따라 달라지는 수치는 `<환경값>`으로 두고**, "무엇과 무엇을 비교해 무엇을 판정하는가"를
  서술한다. 스크립트가 출력하는 값도 절대값이 아니라 델타의 방향과 비율로 읽게 한다.
- 🔒 실습(6·8·9·10·11장)에는 라이선스 표기와 **라이선스 없이 같은 것을 보는 대안 경로**를 병기한다.
  WL_06의 `[6]절`이 그 안내를 이미 출력한다.
