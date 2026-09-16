# 브리지 02 — AWR 상위 SQL 을 실행계획으로 판독하는 절차

**쓰는 시점** Day 7, TUN 8장 실습 04(SQL 섹션 대상 선별) 직후 · **소요** 30분 · **권한** SYSDBA
**연결** TUN 8장(AWR SQL 섹션) → SQLT Ch03·Ch14(실행계획 판독·측정) → SQLT Ch04~Ch13(고치는 기법)
**라이선스** 1~3 단계는 Diagnostics Pack. 6 단계에 미보유 환경 대안이 있다

> 이 문서는 **절차서**다. 같은 절차를 랩(orcl 19.3)에서 돌려 실행 출력을 붙인 트랜스크립트가 `브리지_02_AWR상위SQL_실행계획판독.txt` 다 —
> 수업에서는 그쪽을 연다. 이 문서는 SQL 과 판독 기준의 원본이다.

---

## 0. 전제

8장 실습 04 를 마친 상태여야 한다. 즉 다음 세 가지를 손에 들고 시작한다.

| 항목 | 어디서 얻었나 |
|---|---|
| 스냅샷 쌍 `&begin_snap`, `&end_snap` | 6장 실습 02 (`WL_06_mixed` 전후) |
| AWR 보고서의 *SQL ordered by Elapsed Time* 상위 1~3 개 `SQL_ID` | 8장 실습 04 |
| 그 SQL 의 `PLAN_HASH_VALUE` | 같은 섹션 (없으면 1 단계에서 얻는다) |

Day 1~4 에서 튜닝한 SQL 이 AWR 상위에 올라오게 하려면 `WL_06_mixed` 실행 전에 그 SQL 을 여러 번 실행해 둔다.

---

## 1. 구간 안에서 그 SQL 이 실제로 얼마나 썼는가 — `DBA_HIST_SQLSTAT`

AWR 보고서의 숫자를 뷰에서 직접 다시 뽑는다. **델타 컬럼**(`*_DELTA`)을 쓴다. 누적 컬럼(`*_TOTAL`)을 쓰면 5장 실습 06 의 오판을 되풀이한다.

```sql
SYS@orcl> SELECT s.sql_id, s.plan_hash_value,
  2         SUM(s.executions_delta)                                   AS execs,
  3         ROUND(SUM(s.elapsed_time_delta)/1e6, 2)                   AS elapsed_s,
  4         SUM(s.buffer_gets_delta)                                  AS buffer_gets,
  5         SUM(s.disk_reads_delta)                                   AS disk_reads,
  6         ROUND(SUM(s.buffer_gets_delta)/NULLIF(SUM(s.executions_delta),0)) AS gets_per_exec,
  7         ROUND(SUM(s.elapsed_time_delta)/NULLIF(SUM(s.executions_delta),0)/1e3, 1) AS ms_per_exec
  8    FROM dba_hist_sqlstat s
  9   WHERE s.snap_id > &begin_snap AND s.snap_id <= &end_snap
 10     AND s.dbid = (SELECT dbid FROM v$database)
 11     AND s.sql_id = '&sql_id'
 12   GROUP BY s.sql_id, s.plan_hash_value;
```

**판독**

- `gets_per_exec` 이 Day 1 Ch14 에서 본 Buffers 열과 같은 것이다. 이 SQL 의 튜닝 전 Buffers(3,091 같은 값)와 비교한다.
- `plan_hash_value` 가 두 줄 이상 나오면 구간 안에서 실행계획이 바뀐 것이다. 어느 계획이 더 나쁜지 `ms_per_exec` 로 가른다 (11장 SQL 회귀 탐지의 씨앗).
- 이 SQL 의 `elapsed_s` 를 8장 실습 03 에서 본 구간 DB Time 으로 나눈 값이 **이 SQL 의 DB Time 비중**이다. 브리지 01 의 징후 ②를 델타로 다시 잰 것이다.

---

## 2. AWR 에 남은 실행계획 — `DBMS_XPLAN.DISPLAY_AWR`

커서가 공유 풀에서 밀려났어도 AWR 은 계획을 보관한다.

```sql
SYS@orcl> SET LINESIZE 200 PAGESIZE 0
SYS@orcl> SELECT * FROM TABLE(
  2           DBMS_XPLAN.DISPLAY_AWR('&sql_id', &plan_hash_value, NULL, 'ALL'));
```

- `plan_hash_value` 자리에 `NULL` 을 주면 AWR 에 있는 그 SQL 의 모든 계획을 차례로 출력한다. 1 단계에서 계획이 둘 이상이면 이렇게 둘 다 본다.
- **`DISPLAY_AWR` 에는 A-Rows·Buffers 열이 없다.** AWR 은 실행 통계를 SQL 단위로만 보관하고 계획 행 단위로는 보관하지 않기 때문이다. 행 단위 실측이 필요하면 3 단계로 간다.

---

## 3. 행 단위 실측 — `DISPLAY_CURSOR` (커서가 아직 살아 있을 때)

```sql
SYS@orcl> SELECT * FROM TABLE(
  2           DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', NULL, 'ALLSTATS LAST'));
```

- A-Rows·Buffers 열이 비어 있으면 그 SQL 이 `STATISTICS_LEVEL=ALL` 이나 `/*+ GATHER_PLAN_STATISTICS */` 없이 실행된 것이다. Day 1 Ch14 에서 배운 대로 힌트를 붙여 한 번 다시 실행한 뒤 다시 조회한다.
- 커서가 없다고 나오면(`SQL_ID … cannot be found`) 2 단계의 AWR 계획으로 판독을 대신한다.

---

## 4. 판독 — Day 1~4 의 어느 장으로 돌아가는가

계획을 위에서 아래로 훑으며 아래 표의 징후를 찾는다. 하나가 보이면 그 장의 기법으로 고친다.

| 계획에서 보이는 것 | 뜻 | 돌아갈 장 |
|---|---|---|
| 큰 테이블(`MEDICAL_CLAIMS`, `CLAIM_DETAILS`)에 `TABLE ACCESS FULL` 인데 Predicate 에 등치 조건이 있다 | 인덱스가 없거나 못 탄다 | Ch04 스캔 방식 · Ch05 인덱스 설계 |
| Predicate Information 의 `filter(...)` 안에 `TO_CHAR(`, `SUBSTR(`, `TO_NUMBER(`, `INTERNAL_FUNCTION(` | 컬럼 가공·묵시적 형변환으로 인덱스 무력화 | Ch06 SARGable |
| `access(...)` 는 선두 컬럼만, 나머지는 `filter(...)` | 복합 인덱스 컬럼 순서가 조건과 안 맞는다 | Ch05 컬럼 순서 |
| E-Rows 와 A-Rows 가 10배 이상 차이 | 통계 부재·히스토그램 부재·컬럼 상관 | Ch13 통계 → TUN 7장 확장 통계 |
| `NESTED LOOPS` 안쪽 테이블이 `TABLE ACCESS FULL` 이고 바깥 A-Rows 가 크다 | 조인 방식·드라이빙 순서 오류 | Ch07 JOIN |
| `FILTER` 연산 아래 서브쿼리가 바깥 행 수만큼 실행(Starts 열) | 상관 서브쿼리 반복 | Ch08 서브쿼리 |
| `SORT UNIQUE` / `HASH UNIQUE` 가 큰 A-Rows 위에 있다 | 불필요한 DISTINCT·UNION | Ch09 집합 연산 |
| `SORT ORDER BY` 뒤에 `COUNT STOPKEY`, A-Rows 가 페이지 크기의 수백 배 | 깊은 OFFSET 페이징 | Ch11 페이징 |
| 같은 SQL_ID 의 `executions` 가 비정상적으로 많고 건당 Buffers 는 작다 | N+1 호출 패턴 | Ch12 실무 SQL 문제 |
| 위 어느 것도 아니고 `Buffers` 는 작은데 `elapsed` 만 크다 | SQL 밖의 문제 — 대기 이벤트 | **TUN 13·14장으로** (SQL 을 고치지 않는다) |

마지막 행이 이 브리지의 핵심이다. 계획이 깨끗한데 느리다면 SQL 부문으로 돌아가지 않는다.

---

## 5. 원문 SQL 과 바인드 값

```sql
-- 원문 (커서가 없어도 AWR 에 남아 있다)
SYS@orcl> SELECT sql_text FROM dba_hist_sqltext WHERE sql_id = '&sql_id';

-- 바인드 값 (계획을 재현할 때 필요. 커서가 살아 있을 때만)
SYS@orcl> SELECT name, position, datatype_string, value_string
  2    FROM v$sql_bind_capture
  3   WHERE sql_id = '&sql_id' ORDER BY position;
```

---

## 6. 미보유 환경 대안 — Diagnostics Pack 없이 같은 것을 보는 법

| 팩 필요 | 대안 |
|---|---|
| `DBA_HIST_SQLSTAT` (1 단계) | `V$SQL` 의 `EXECUTIONS`, `ELAPSED_TIME`, `BUFFER_GETS` 를 부하 전후 두 번 조회해 손으로 델타를 낸다 (13장 실습 02 방식) |
| `DISPLAY_AWR` (2 단계) | `DISPLAY_CURSOR` (3 단계) 또는 `V$SQL_PLAN` 직접 조회. 커서가 밀려나기 전에 봐야 한다 |
| `DBA_HIST_SQLTEXT` (5 단계) | `V$SQL.SQL_FULLTEXT` |
| AWR SQL 섹션 자체 | 6장 실습 06 의 Statspack `sprepsql.sql` |

---

## 7. 기록 양식

각 SQL 마다 아래를 적고 Day 8 11장(기간 비교)에서 "조치 후" 열을 채운다.

| 항목 | 조치 전 | 조치 후 (Day 8) |
|---|---|---|
| SQL_ID / PLAN_HASH_VALUE | | |
| 구간 DB Time 비중 (%) | | |
| gets_per_exec | | |
| ms_per_exec | | |
| 4 단계에서 찾은 징후 / 돌아간 장 | | |
| 조치 내용 (인덱스·재작성·통계·"SQL 아님") | | |

---

## 8. 정리

이 절차에서 만든 객체는 없다. 조회만 했으므로 되돌릴 것도 없다.
4 단계에서 "SQL 아님" 으로 판정한 SQL_ID 는 따로 적어 두었다가 Day 8 14장 실습 02~06 에서 그 SQL 이 무엇을 기다렸는지 추적한다.
