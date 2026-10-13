# 브리지 04 절차서 — AWR 로 사건을 다루는 세 가지 방식

`브리지_04_AWR실무_세가지사례.txt` 의 실측을 절차로 뽑은 것이다.
ch20~ch25 를 끝낸 뒤, 운영에서 신고를 받았을 때 꺼내 쓰는 문서다.

- **대상** ch20(스냅샷·보존) · ch21(통계 환경설정) · ch22(AWR 판독) ·
  ch23(Compare Periods) · ch24(ADDM) · ch25(ASH)
- **실측** 2026-10-13 `orcl` 19.3.0.0 / 4 CPU / 7.49GB, 스냅샷 1112~1120
- 🔒 AWR·ADDM·ASH·SQL Monitor 는 Diagnostics/Tuning Pack. 미보유 환경은 **6절** 참조

---

## 1. 신고의 형태가 1차 도구를 정한다

신고는 세 가지뿐이다. 먼저 분류하고 시작한다. 분류를 건너뛰면 도구를 잘못 고른다.

| 신고 | 1차 도구 | 2차 도구 | 전형적 오류 |
|---|---|---|---|
| **A. 어제 ~시경 느렸다** | AWR 보고서 | ASH(분 단위) | 구간 평균만 보고 "문제 없음" |
| **B. 지난주보다 느리다** | Compare Periods | `DBA_HIST_SQLSTAT` 정규화 | 절대값 비교로 부하/성능 혼동 |
| **C. 지금 느리다** | `V$SESSION` · ASH | 사후 AWR | AWR 부터 열어 시간 낭비 |

세 경우 모두 ch19 의 원칙 위에 있다 — **누적값은 두 시점의 차이로만 읽는다.**

---

## 2. A. "어제 ~시경 느렸다" — 과거 구간

### 2.1 절차

1. **구간을 찾는다.** 보존 밖이면 여기서 끝이다.
   ```sql
   SELECT snap_id, begin_interval_time, end_interval_time
     FROM dba_hist_snapshot
    WHERE end_interval_time BETWEEN TIMESTAMP '2026-10-12 13:00:00'
                                AND TIMESTAMP '2026-10-12 16:00:00'
    ORDER BY snap_id;
   SELECT snap_interval, retention FROM dba_hist_wr_control;   -- 기본 1시간 / 8일
   ```
2. **AWR 보고서로 성격을 가린다.** 대화형 `awrrpt.sql` 대신 프로그램 호출을 쓴다.
   ```sql
   SET LINESIZE 200 PAGESIZE 2000 HEADING OFF
   SPOOL awr_<b>_<e>.txt
   SELECT output FROM TABLE(DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(
            (SELECT dbid FROM v$database), 1, &b, &e));
   SPOOL OFF
   ```
   읽는 순서는 **머리 요약 → Load Profile → Top 10 → Time Model → SQL 섹션** 이다.
3. **ASH 로 분 단위로 쪼갠다.** 이 단계를 빼면 짧은 사건을 놓친다.
   ```sql
   SELECT TO_CHAR(sample_time,'HH24:MI') mi, COUNT(*) 샘플,
          ROUND(COUNT(*)/60*100) 활성퍼센트, COUNT(DISTINCT session_id) 세션수
     FROM dba_hist_active_sess_history          -- V$ 는 메모리라 오래된 건 없다
    WHERE sample_time BETWEEN :t1 AND :t2
    GROUP BY TO_CHAR(sample_time,'HH24:MI') ORDER BY 1;
   ```
4. **그 분의 상위 SQL 을 뽑고**, `DBA_HIST_SQLSTAT` 로 실행당 비용을 확정한다.
5. **익명 블록이 1위면 봉투다.** 봉투 소비량과 캡처 SQL 합의 차이를 확인한다.
6. ADDM 은 돌려 보되 **"검색 결과 없음"을 "문제 없음"으로 읽지 않는다.**

### 2.2 실측 기준값 (스냅샷 1112→1113, 5분 5초 구간 안에 60초 스파이크)

| 단계 | 결과 | 판정 |
|---|---|---|
| AWR 머리 요약 | Elapsed 5.09분 / DB Time 1.04분 / **AAS 0.2** | 한가해 보인다 |
| Load Profile | Logical read **59,584 블록/초** | AAS 0.2 와 어긋난다 → 평균이 숨긴다 |
| Top 10 | **DB CPU 96.6%**, 대기 전부 1.5% 이하 | CPU 사건 (맞는 판정) |
| ADDM | **"보고할 검색 결과가 없습니다 / 작업이 부족합니다"** | 쓸 수 없다 |
| **ASH 분 단위** | 09:01 **62%** / 09:02 **88%** (평균 20%) | **희석 4.4배**, 사건 시각 확정 |
| SQLSTAT 델타 | `6p8yjz956nnk5` 1,868회 / **실행당 6,621 블록** | 원인 SQL 확정 |
| 봉투 vs 내용물 | 블록 18,140,158 vs 12,368,034 → 차이 **32%** | 리터럴이 AWR 에 안 남았다 |

### 2.3 이 경로의 사각지대

- **구간 평균은 짧은 사건을 희석한다.** 1시간 자동 스냅샷 + 5분 장애 = 12배 희석.
- **AWR 은 구간 상위 N개 SQL(`TOPNSQL`)만 보관한다.** 리터럴로 1,868개 커서로
  쪼개진 SQL 은 26회만 남았다. **사후에 복원할 수 없다.**
- **PL/SQL 블록은 자원을 중복 집계한다.** 보고서 자신이 밝힌다 —
  `Captured SQL 73.9%` + `Captured PL/SQL 100.2%` = 174%.

---

## 3. B. "지난주보다 느리다" — 비교

### 3.1 절차

1. **구간 길이를 맞춘다.** 요일·시간대를 같게 잡는다. `Elapsed` 가 다르면 비교가 안 된다.
2. **Compare Periods 머리 요약 세 줄**을 적는다. 여기까지가 뼈대다.
   ```sql
   SPOOL awrdd.txt
   SELECT output FROM TABLE(DBMS_WORKLOAD_REPOSITORY.AWR_DIFF_REPORT_TEXT(
            (SELECT dbid FROM v$database), 1, &b1, &e1,
            (SELECT dbid FROM v$database), 1, &b2, &e2));
   SPOOL OFF
   ```
3. **`DBA_HIST_SQLSTAT` 를 정규화해 판정한다.** 여기서 답이 나온다.
   ```sql
   SELECT snap_id, sql_id, plan_hash_value,
          executions_delta 실행,
          ROUND(elapsed_time_delta/DECODE(executions_delta,0,1,executions_delta)/1000,2) 실행당ms,
          ROUND(buffer_gets_delta/DECODE(executions_delta,0,1,executions_delta)) 실행당블록
     FROM dba_hist_sqlstat
    WHERE sql_id = :target AND snap_id BETWEEN :b AND :e
    ORDER BY snap_id;
   ```
4. **성능 저하면 `plan_hash_value` 변화를 본다.**

### 3.2 판정표

| 실행 횟수 | 실행당 비용 | 판정 | 조치 방향 |
|---|---|---|---|
| ↑ | = | **부하 증가** | 호출하는 쪽 (애플리케이션·배치 스케줄·동시 사용자) |
| = | ↑ | **성능 저하** | DB 쪽 (계획·통계·인덱스) |
| ↓ | ↑ | **성능 저하 확정** | 가장 분명한 신호. 일을 덜 했는데 더 오래 걸렸다 |
| ↑ | ↑ | 둘 다 | 보통 부하가 성능을 끌어내린 경우. 부하부터 줄여 재측정 |

정규화 기준은 **실행당 시간**과 **실행당 작업량** 둘이다.
**작업량(논리읽기)이 더 믿을 만하다** — 시간은 캐시 상태와 장비 부하에 흔들린다.

### 3.3 실측 기준값 (같은 SQL `0d6bnv7u13ns1`, 세 구간 각 61~62초)

| 구간 | 계획 | 실행 | 경과(초) | 실행당 ms | 실행당 블록 | 판정 |
|---|---|---|---|---|---|---|
| **A 평시** (인덱스 O, 100ms) | 1922395333 | 577 | 0.431 | **0.75** | **68** | 기준 |
| **C 부하 2배** (인덱스 O, 50ms) | 1922395333 | **1,169** | 0.895 | **0.77** | **68** | **부하 증가** |
| **B 성능 저하** (인덱스 X, 100ms) | **2119550289** | **528** | 5.877 | **11.13** | **3,090** | **성능 저하** |

구간 DB Time : A 1.4초 / C 1.6초 / **B 6.41초**
Compare Periods 머리 요약 (A vs B) : Elapsed **−1.0%** / DB time **+358.6%** / AAS **+400%**

> **절대값만 보면 A→C 와 A→B 를 구분할 수 없다.** 둘 다 DB Time 이 늘었다.
> 구분은 "실행 횟수 2.03배 · 실행당 동일" 과 "실행 횟수 0.92배 · 실행당 14.8배" 에서 난다.

### 3.4 이 경로의 사각지대

- `awrddrpt` **텍스트 본문은 1st/2nd 를 좌우로 붙여 한 줄이 200자를 넘는다.**
  본문은 HTML(`AWR_DIFF_REPORT_HTML`)로 보고, 판정은 `DBA_HIST_SQLSTAT` 로 한다.
- 계획이 안 바뀌었는데 실행당이 늘었으면 데이터량·경합·장비를 본다.

---

## 4. C. "지금 느리다" — 진행 중

### 4.1 절차

1. **`V$SESSION` 활성 목록** — SID · SQL_ID · EVENT · BLOCKING_SESSION (1초면 된다)
2. **최근 60초 ASH 로 비중을 교정한다.** 순간의 이벤트에 끌려가지 않는다.
3. **`V$SQL_MONITOR`** 로 지금 실행 중인 문장을 확정. `V$SQL` 은 **실행당**으로 정렬.
4. **★ 조치하기 전에 수동 스냅샷을 뜬다. ★**
   ```sql
   EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;
   ```
   이것이 없으면 사후 AWR 구간이 자동 스냅샷 경계까지 희석된다.
   사건이 길 것 같으면 5~10분 간격으로 몇 개 더 뜬다(1분 미만은 비용이 크다).
5. 급하면 세션 차단(ch17 실습 02), 아니면 원인 SQL 을 고친다.
6. **끝난 뒤 그 스냅샷 쌍으로 AWR 을 만들어 실시간 판단을 검증하고 기록으로 남긴다.**

### 4.2 실측 기준값 (SQLT 2세션 동시 조회 150초, 스냅샷 1119→1120)

| 단계 | 결과 |
|---|---|
| `V$SESSION` | SQLT 2세션, 같은 `9068nx8p9zz9c`, `latch: cache buffers chains` |
| **ASH 60초** | **94.7% ON CPU** / db file sequential read 3.9% → **래치는 비중 없음** |
| `V$SQL_MONITOR` | 두 세션 모두 `b9x4v5kzum2aq` EXECUTING, 25.6초, 각 610만 블록 |
| `V$SQL` 실행당 | `9068nx8p9zz9c` **실행당 9,795 블록** |
| 수동 스냅샷 | **1119 @ 09:15:19** (사건 진행 중) |
| 사후 AWR | Elapsed 2.08분 / DB Time 4.19분 → **AAS 2.0** / **DB CPU 98.0%** |
| 사후 AWR 의 래치 | **2회 / 0초 / 0.0%** → 3단계 판단이 옳았다는 증거 |
| 사후 AWR SQL 섹션 | `9068nx8p9zz9c` 5,963회 / **실행당 9,824 블록** / 전체의 **97.6%** |
| ADDM | **AAS 2.03 인데도 "작업이 부족하다"** |

### 4.3 이 경로의 사각지대

`V$SESSION` 은 **순간 한 장**이다. `STATE` 가 `WAITED ... TIME` 이면
"지금 기다리는 중"이 아니라 "직전에 기다렸고 지금은 CPU 를 쓰는 중"이다.
**비중은 반드시 구간 집계(ASH 60초 또는 사후 AWR)로 확인한다.**

> 사례 1 과 사례 3 은 정확히 반대 방향의 함정이다.
> **사례 1** — 구간 평균이 짧은 사건을 **숨긴다**.
> **사례 3** — 순간 한 장이 비중 없는 이벤트를 **과장한다**.
> 둘 다 "집계 구간을 의식해서 읽어라"는 같은 교훈이다.

---

## 5. ADDM 을 어디에 쓰는가

실측에서 ADDM 은 **두 구간 모두 침묵했다.**

| 구간 | DB Time | AAS | ADDM |
|---|---|---|---|
| 사례 1 (1112→1113) | 62초 | 0.2 | 보고할 검색 결과 없음 / 작업 부족 |
| 사례 3 (1119→1120) | 252초 | **2.03** | 보고할 검색 결과 없음 / 작업 부족 |

ADDM 의 기준은 절대 DB Time 이 아니라 **CPU 수 대비 평균 활성 세션**이다.
4 CPU 장비에서 AAS 2.03 은 절반 수준이고, 그 아래에서는 의견을 내지 않는다.

- **쓸 곳** : 운영 수준 부하에서 1차 선별, 그리고 "내가 놓친 범주가 있나" 확인
- **쓰면 안 되는 곳** : 1차 도구, 짧은 스파이크, 실습·개발 환경
- **읽는 법** : `"검색 결과 없음" ≠ "문제 없음"`. "판단할 만큼 바쁘지 않았다"는 뜻이다
- `GET_REPORT` 는 CLOB 이므로 **`SET LONG 2000000` 을 먼저 올린다.**
  올리지 않으면 80자에서 잘려 제목만 나온다(실측에서 겪었다)

---

## 6. Diagnostics Pack 미보유 환경의 대안 경로

| 못 쓰는 것 | 대안 | 비고 |
|---|---|---|
| AWR 보고서 | **Statspack** | `perfstat` 계정 / `STATS$SNAPSHOT`. ch20 실습 06 |
| `DBA_HIST_*` | `V$` 를 두 시점에 캡처해 델타 | ch19 실습 06 의 `st_t0` 방식 |
| ASH | `V$SESSION` 을 1초 간격으로 샘플링해 표에 적재 | 직접 만드는 ASH |
| ADDM | 없음 | `V$SYSTEM_WAIT_CLASS` 델타로 대체 판단 |
| `V$SQL_MONITOR` | `V$SESSION_LONGOPS` + `V$SQL` 실행당 | Tuning Pack |

판정 논리(실행 횟수와 실행당의 분리, 계획 해시 변화)는 **도구와 무관하게 같다.**

---

## 7. 운영 설정 두 가지 (실측에서 드러난 것)

### 7.1 SYSAUX

```
SM/AWR        414 MB     (1시간 주기 · 8일 보존 · 스냅샷 212개)
SM/OPTSTAT    318 MB
SM/ADVISOR    175 MB     (자동 ADDM 태스크 703개)
```

보존을 늘리거나 주기를 짧게 하면 선형으로 늘어난다. 늘리기 전에 SYSAUX 여유를
확인한다(ch20 실습 05).

### 7.2 자동 통계 수집이 기준 상태를 밤마다 깬다

이 과정의 기준 상태는 **"히스토그램은 `MEDICAL_CLAIMS.HOSP_ID` 하나"** 다.
그런데 `auto optimizer stats collection` 이 유지관리 창(10-12 22:00)에서 돌아
**22:07:54 에 `CLAIM_ID`·`CLAIM_TYPE`·`DEPT_CODE`·`RECEIPT_DATE`·`TOTAL_AMT` 등에
히스토그램을 다시 만들었다.** 손으로 Day 0 명령을 돌려도 다음 밤에 또 벌어진다.

원인은 `METHOD_OPT` 기본값 `FOR ALL COLUMNS SIZE AUTO` 다. 실습에서 `WHERE` 에
쓴 컬럼이 컬럼 사용 이력에 남고, AUTO 가 그 컬럼에 히스토그램을 만든다.

고정하려면 **테이블 수준 환경설정**을 걸어야 한다(ch21 실습 06).

```sql
EXEC DBMS_STATS.SET_TABLE_PREFS('SQLT','MEDICAL_CLAIMS','METHOD_OPT', -
       'FOR ALL COLUMNS SIZE 1 FOR COLUMNS SIZE 254 HOSP_ID')

-- 나머지 6개 표
BEGIN
  FOR t IN (SELECT column_value tn FROM TABLE(sys.odcivarchar2list(
              'HOSPITALS','PATIENTS','DRUG_MASTER','CLAIM_DETAILS','DISEASES','REVIEW_LOG'))) LOOP
    DBMS_STATS.SET_TABLE_PREFS('SQLT', t.tn, 'METHOD_OPT', 'FOR ALL COLUMNS SIZE 1');
  END LOOP;
END;
/
```

또는 통계를 잠근다 — `EXEC DBMS_STATS.LOCK_TABLE_STATS('SQLT','<표>')`.
환경설정을 걸지 않는 한 **ch01~ch20 의 `E-Rows` 는 밤마다 조금씩 달라진다.**

---

## 8. 제출 양식 (ch17 실습 05 와 같다)

사건 하나당 `SPOOL` 파일 하나. 순서를 지킨다.

1. **신고 원문**과 분류(A/B/C)
2. **구간 확정** — 스냅샷 ID·시각, 또는 "스냅샷 없음"과 그 이유
3. **성격 판정** — DB Time 분해, 대기 vs CPU, 근거 수치
4. **시각·주체 확정** — ASH 분 단위 표
5. **원인 SQL** — SQL_ID · 실행 횟수 · 실행당 비용 · 계획 해시
6. **조치와 재측정** — 같은 질의를 같은 순서로 다시
7. **판정 한 문장** — "무엇을 바꿨더니 어느 지표가 얼마에서 얼마로 바뀌었다"
