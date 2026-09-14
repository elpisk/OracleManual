# 브리지 03 — 손으로 튜닝한 SQL 을 SQL Tuning Advisor 권고와 대조하는 절차

**쓰는 시점** Day 9, TUN 15장 실습 04(STA 수동 실행) 대신 또는 직후 · **소요** 40분 · **권한** SYSDBA
**연결** SQLT Day 4 평가에서 손으로 튜닝한 SQL → TUN 15장 SQL Tuning Advisor → 채택 판단
**라이선스** SQL Tuning Advisor 는 **Tuning Pack**. 미보유 환경은 7 단계

> 이 문서는 **절차서**다. 실행 출력은 실습 환경마다 다르므로 싣지 않았다. 실측 `.txt` 로 바꾸려면 랩에서 돌려 출력을 붙인다.
> 스키마 소유자는 원 과정과 같이 `SQLT`, 프롬프트는 `SYS@orcl>` 로 적었다.

---

## 0. 왜 하는가

Day 4 평가에서 수강생은 실행계획을 읽고 인덱스를 만들거나 SQL 을 재작성했다. 그 결과를 어드바이저에 넣으면 세 가지 중 하나가 나온다.

| 결과 | 뜻 | 배우는 것 |
|---|---|---|
| 권고가 내 조치와 같다 | 손 튜닝이 옳았다 | 어드바이저는 검산 도구다 |
| 권고가 내 조치보다 낫다 | 빠뜨린 것이 있다 (컬럼 순서, 포함 컬럼, 통계) | 권고에서 근거를 읽는 법 |
| 권고가 내 조치보다 못하거나 엉뚱하다 | 어드바이저의 한계 | **권고 맹신 경계** (9장과 같은 교훈) |

셋 중 무엇이 나오든 얻는 것이 있다. 어느 결과가 나올지 미리 정해 두지 않는다.

---

## 1. 전제 — Day 4 산출물 확보

| 항목 | 어디서 |
|---|---|
| 튜닝 **전** SQL 원문 | Day 4 평가 문제지(`평가_SQL부문/03_*`, `04_*`)의 제공 SQL |
| 내가 한 조치 | 만든 인덱스 DDL(이름·컬럼·순서), 재작성한 SQL, 수집한 통계 — **답안지에 적어 둔 것** |
| 튜닝 전·후 Buffers / A-Rows | Day 4 에 `DISPLAY_CURSOR('…','ALLSTATS LAST')` 로 캡처한 것 |

수강생마다 조치가 다르므로 아래는 **인덱스를 만든 경우**를 기준으로 쓰고, 재작성만 한 경우는 각 단계 끝의 *재작성 변형* 을 따른다.

---

## 2. 튜닝 전 상태 확인 — 인덱스는 이미 없다

SQL 부문은 매 실습·평가 말미에 `DROP INDEX` 원복을 요구하므로(Day 4 평가 03 의 마지막 과제가 원복 증명이다),
Day 9 의 스키마는 **PK 인덱스만 있는 튜닝 전 상태**다. 어드바이저가 봐야 할 상태가 이미 준비돼 있다. 확인만 한다.

```sql
SYS@orcl> SELECT table_name, index_name, uniqueness, visibility
  2    FROM dba_indexes
  3   WHERE owner = 'SQLT' AND table_name = 'MEDICAL_CLAIMS';
-- PK_MEDICAL_CLAIMS 한 줄만 나와야 한다

-- 정말 튜닝 전 계획인지 확인 (Day 1 Ch14 방식)
SQLT@orcl> SELECT /*+ GATHER_PLAN_STATISTICS BR03_BEFORE */ ...튜닝 전 SQL 원문... ;
SQLT@orcl> SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
```

`TABLE ACCESS FULL` 과 Day 4 에 캡처한 튜닝 전 Buffers 가 다시 나오면 준비된 것이다.

**PK 외 인덱스가 남아 있다면** — Day 4 원복이 빠진 것이다. 지우지 말고 `ALTER INDEX sqlt.<이름> INVISIBLE` 로 숨긴 뒤 진행하고,
누구 것인지 확인해 Day 4 답안의 원복 증명과 대조한다. 옵티마이저는 기본 설정(`OPTIMIZER_USE_INVISIBLE_INDEXES=FALSE`)에서
보이지 않는 인덱스를 쓰지 않으며 어드바이저도 같은 옵티마이저를 쓴다.

*재작성 변형*: 인덱스를 만들지 않았다면 첫 조회만 하고 넘어간다.

---

## 3. 튜닝 태스크 생성·실행

SQL 원문을 텍스트로 넘긴다. `sql_id` 로 넘기는 방법(15장 실습 04)도 있지만, 여기서는 **어드바이저가 튜닝 전 SQL 을 보게** 해야 하므로 원문을 준다.

```sql
SYS@orcl> VARIABLE task VARCHAR2(64)
SYS@orcl> BEGIN
  2    :task := DBMS_SQLTUNE.CREATE_TUNING_TASK(
  3               sql_text    => q'[ ...튜닝 전 SQL 원문 (힌트·주석 제거)... ]',
  4               user_name   => 'SQLT',
  5               scope       => DBMS_SQLTUNE.SCOPE_COMPREHENSIVE,
  6               time_limit  => 120,
  7               task_name   => 'BR03_' || TO_CHAR(SYSDATE, 'HH24MISS'),
  8               description => 'Bridge 03 - Day4 hand-tuned SQL vs STA');
  9  END;
 10  /
SYS@orcl> PRINT task
SYS@orcl> EXEC DBMS_SQLTUNE.EXECUTE_TUNING_TASK(:task)

-- 상태 확인 (COMPLETED 가 아니면 time_limit 안에 못 끝난 것)
SYS@orcl> SELECT task_name, status, TO_CHAR(execution_end, 'HH24:MI:SS') done
  2    FROM dba_advisor_log WHERE task_name = :task;
```

- 바인드 변수가 있는 SQL 이면 `bind_list => SQL_BINDS(ANYDATA.ConvertNumber(1), ANYDATA.ConvertDate(DATE '2024-06-01'))` 처럼 위치 순서대로 값을 준다. 값 없이 넘기면 어드바이저가 카디널리티를 추정하지 못해 권고가 부실해진다.
- `SCOPE_LIMITED` 는 통계·구조만 보고 프로파일을 만들지 않는다. 대조가 목적이므로 `COMPREHENSIVE` 로 한다.

---

## 4. 보고서 읽기

```sql
SYS@orcl> SET LONG 1000000 LONGCHUNKSIZE 1000000 LINESIZE 200 PAGESIZE 0
SYS@orcl> SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK(:task) FROM dual;
```

보고서는 위에서 아래로 네 덩어리다. 각 덩어리에서 무엇을 뽑는지:

| 보고서 섹션 | 뽑을 것 | 내 조치와 대조할 항목 |
|---|---|---|
| **FINDINGS SECTION** — `Statistics Finding` | 어느 객체의 통계가 없거나 오래됐는지 | Day 4 에 통계를 다시 모았는가 |
| `SQL Profile Finding` | 프로파일 채택 시 예상 개선율 (%) | 내 재작성이 없앤 Buffers 감소율과 비교 |
| `Index Finding` | 권고 인덱스의 **테이블·컬럼·컬럼 순서** | 내가 만든 인덱스의 컬럼 순서와 같은가 |
| `Restructure SQL Finding` | 재작성 권고 (조인 조건 누락, 형변환, `NOT IN` 등) | 내 재작성이 같은 지점을 고쳤는가 |
| **EXPLAIN PLANS SECTION** | Original 계획 vs 권고 적용 계획 | 2 단계에서 본 튜닝 전 계획과 Original 이 같은가 |

`Index Finding` 이 있으면 다음도 본다. 어드바이저는 인덱스를 **직접 만들지 않고 SQL Access Advisor 에 넘길 것을 권한다** — 이것이 15장 실습 06 으로 이어지는 지점이다.

뷰로 직접 뽑을 때:

```sql
SYS@orcl> SELECT f.type, f.impact_type, ROUND(f.impact) impact, f.message
  2    FROM dba_advisor_findings f
  3   WHERE f.task_name = :task ORDER BY f.impact DESC NULLS LAST;

SYS@orcl> SELECT r.rec_id, r.type, r.rank, r.benefit
  2    FROM dba_advisor_recommendations r
  3   WHERE r.task_name = :task ORDER BY r.rank;
```

---

## 5. 대조표 작성 — 이 절차의 산출물

| 항목 | 내 조치 (Day 4) | STA 권고 | 판정 |
|---|---|---|---|
| 인덱스 컬럼·순서 | 예) `(HOSP_ID, RECEIPT_DATE)` | 예) `(HOSP_ID, RECEIPT_DATE, CLAIM_STATUS)` | 같음 / 권고가 더 좋음 / 내 것이 더 좋음 |
| 재작성 지점 | | | |
| 통계 | | | |
| 프로파일 제안 여부·개선율 | — | | |
| Original 계획 = 2 단계 계획 | | | 예 / 아니오 |

**판정 기준**

- 권고 인덱스에 컬럼이 더 있으면 그 컬럼이 `SELECT` 목록에 있는지 본다. 있으면 테이블 접근을 없애는 **커버링** 이고 내가 놓친 것이다. 없으면 어드바이저가 그 SQL 하나만 보고 만든 과잉 인덱스일 수 있다 (Ch05 "인덱스가 많을 때의 비용").
- 프로파일 권고의 개선율이 내 재작성의 Buffers 감소율보다 낮으면 **프로파일을 받지 않는다**. 프로파일은 SQL 을 못 고칠 때(패키지 SW) 쓰는 수단이다.
- Original 계획이 2 단계에서 본 계획과 다르면 어드바이저가 다른 것을 보고 있는 것이다. 바인드 값·스키마·인덱스 가시성을 다시 확인한다.

---

## 6. 채택 여부에 따른 후속 — 그리고 반드시 원상 복구

**프로파일을 받기로 했다면** (교육용으로 한 번 해 보고 지운다):

```sql
SYS@orcl> DECLARE
  2    l_name VARCHAR2(64);
  3  BEGIN
  4    l_name := DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(task_name => :task,
  5                                              name      => 'BR03_PROFILE',
  6                                              force_match => TRUE);
  7  END;
  8  /
SYS@orcl> SELECT name, status, force_matching FROM dba_sql_profiles WHERE name = 'BR03_PROFILE';
-- 프로파일이 붙은 계획 확인: DISPLAY_CURSOR 의 Note 섹션에 "SQL profile BR03_PROFILE used"
SYS@orcl> EXEC DBMS_SQLTUNE.DROP_SQL_PROFILE('BR03_PROFILE')
```

**권고 인덱스와 내 인덱스를 실측으로 견주고 싶다면** (선택, 15분):

```sql
SQLT@orcl> CREATE INDEX ix_br03_mine ON medical_claims(hosp_id, receipt_date);   -- Day 4 답안의 DDL
SQLT@orcl> SELECT /*+ GATHER_PLAN_STATISTICS BR03_MINE */ ...튜닝 전 SQL 원문... ;
SQLT@orcl> SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
SQLT@orcl> DROP INDEX ix_br03_mine;
-- 권고 인덱스도 같은 방식으로 만들고 재고 지운다. 둘을 동시에 두지 않는다(어느 쪽이 선택됐는지 판정 불가)
```

**어느 경우든 마지막에**:

```sql
SYS@orcl> EXEC DBMS_SQLTUNE.DROP_TUNING_TASK(:task)
SYS@orcl> SELECT owner, table_name, index_name, visibility
  2    FROM dba_indexes
  3   WHERE owner = 'SQLT' AND index_name NOT LIKE 'PK%';
-- 0 행이어야 한다. 2 단계에서 INVISIBLE 로 숨긴 것이 있었다면 그 소유자가 DROP 한다
```

PK 외 인덱스를 남긴 채 Day 10 으로 넘어가면 18·19장 부하 실습과 종합 평가의 실행계획이 전부 달라진다. 종합 평가 문제지는
"PK 인덱스만 존재" 를 전제하고 인덱스 생성을 0점 사유로 둔다. 마지막 `SELECT` 로 확인한다.

---

## 7. 미보유 환경 대안 — Tuning Pack 없이 대조하는 법

STA 없이도 대조의 절반은 할 수 있다.

| STA 가 해 주는 것 | 대안 |
|---|---|
| Statistics Finding | `DBA_TAB_STATISTICS.STALE_STATS`, `DBA_TAB_COL_STATISTICS.HISTOGRAM` 직접 조회 (TUN 7장) |
| Index Finding | 없음. 대신 `V$SQL_PLAN` 의 `ACCESS_PREDICATES` / `FILTER_PREDICATES` 를 읽어 filter 로 밀린 컬럼을 인덱스 후보로 삼는다 (브리지 02 의 4 단계 표) |
| Restructure SQL Finding | 없음. Ch06·Ch08·Ch09 의 점검표를 손으로 돈다 |
| SQL Profile | 없음. 힌트를 SQL 에 직접 넣거나(권장하지 않음) SQL Plan Baseline(`DBMS_SPM`, EE 기본 기능)으로 계획을 고정한다 |

`DBMS_SPM` 은 Tuning Pack 없이 쓸 수 있지만 "계획을 고정" 할 뿐 "더 나은 계획을 찾아 주지" 는 않는다. 그 차이를 수강생에게 말해 준다.

---

## 8. 기록 양식

5 단계 대조표에 다음 두 줄을 더해 제출한다.

| 항목 | 내용 |
|---|---|
| 최종 판정 | 손 튜닝 유지 / 권고 일부 반영(무엇을) / 권고 전면 반영 |
| 근거 한 문장 | 예) "권고 인덱스의 세 번째 컬럼 CLAIM_STATUS 는 SELECT 목록에 있어 커버링이 되므로 반영" |

이 양식은 Day 10 종합 평가에서 "권고를 채택할 것인가" 문항의 채점 기준과 같다.
