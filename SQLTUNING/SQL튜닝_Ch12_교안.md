# Chapter 12. 실무에서 자주 발생하는 SQL 문제

- 본 차시는 DDL 변경 없음(기존 PK만 사용)
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: "청구 상세 조회 API"가 청구 20건에 대해 `CLAIM_DETAILS`를 건별로 반복 조회하는
  N+1 패턴을 PL/SQL 루프로 실제 재현하고, 조인 1회로 대체했을 때와 비교

---

## 01. Why

- 지금까지는 SQL 한 문장의 실행계획을 분석했음 — 하지만 실무 성능 문제의 상당수는
  "SQL 자체는 문제없는데, 그 SQL을 애플리케이션 코드가 반복 호출하는 방식"에서 생김
- 이번 챕터는 SQL 밖의 문제(반복 호출 패턴)를 실측으로 확인함

## 02. Concept

- N+1 문제: 목록 1건을 조회(1번)한 뒤, 그 목록의 각 항목마다 관련 데이터를 추가로
  조회(N번)하는 패턴. 총 쿼리 실행 횟수가 N+1번이 됨
- 그 외 실무에서 자주 나타나는 문제 유형: `SELECT *`(불필요한 컬럼까지 가져옴), 불필요한
  JOIN(쓰지도 않는 테이블을 조인), 같은 데이터를 여러 번 중복 조회, 과도한 페이지 크기,
  데이터 분포를 고려하지 않은 SQL(Chapter 4·13과 연결) — 이번 챕터는 그중 가장 흔하고
  파급력이 큰 N+1을 실측으로 다룸

## 03. Oracle Internals — N+1의 비용이 왜 배수로 커지는가

- `CLAIM_DETAILS`는 `CLAIM_ID`에 인덱스가 없음(PK는 `DETAIL_ID`뿐). 그래서
  `WHERE claim_id = :값`으로 조회하면 매번 `TABLE ACCESS FULL`이 발생함(Chapter 4에서
  이미 확인한 사례)
- 이 조회를 20번 반복하면, `TABLE ACCESS FULL` 자체가 **20번 반복**됨 — 한 번의 Full
  Scan 비용이 이미 상당한데(약 6,600 Buffers), 그것이 20번이면 단순 곱셈으로 커짐
- 반면 조인으로 한 번에 처리하면 `CLAIM_DETAILS`를 **단 한 번**만 Full Scan하고, 그 한
  번의 스캔 결과 안에서 20건 모두를 동시에 매칭시킬 수 있음(Hash Join의 특성,
  Chapter 7) — Full Scan 비용이 조회 건수와 무관하게 "한 번"으로 고정됨

## 04. Example

```sql
-- N+1 패턴(PL/SQL로 재현): 청구 20건에 대해 상세내역을 건별로 반복 조회
DECLARE
  v_cnt NUMBER;
BEGIN
  FOR r IN (SELECT claim_id FROM medical_claims WHERE hosp_id = 1 AND ROWNUM <= 20) LOOP
    SELECT COUNT(*) INTO v_cnt FROM claim_details WHERE claim_id = r.claim_id;
  END LOOP;
END;
/

-- 조인 1회로 대체
SELECT c.claim_id, COUNT(d.detail_id) cnt
FROM (SELECT claim_id FROM medical_claims WHERE hosp_id = 1 AND ROWNUM <= 20) c,
     claim_details d
WHERE c.claim_id = d.claim_id(+)
GROUP BY c.claim_id;
```

## 05. Execution Plan — 실측 비교

**N+1 패턴**: 바인드 변수를 써서(`:B1`) 20번 반복 실행한 뒤, `V$SQL`에서 누적 비용을 확인

```text
SQL_ID          EXECUTIONS  BUFFER_GETS  AVG_BUFFERS  ELAPSED_TIME(µs)
cq8zvf7njas01   20          132,468      6,623.4      374,094

SQL_TEXT: SELECT COUNT(*) FROM CLAIM_DETAILS WHERE CLAIM_ID = :B1
```

**조인 1회**

```text
| Id | Operation           | Name           | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT    |                |     20 |00:00:00.04 |    6645 |
| 1  |  HASH GROUP BY      |                |     20 |00:00:00.04 |    6645 |
| 2  |   HASH JOIN OUTER   |                |     65 |00:00:00.04 |    6645 |
| 3  |    VIEW             |                |     20 |00:00:00.01 |      23 |
| 4  |     COUNT STOPKEY   |                |     20 |00:00:00.01 |      23 |
| 5  |      TABLE ACCESS FULL| MEDICAL_CLAIMS|     20 |00:00:00.01 |      23 |
| 6  |    TABLE ACCESS FULL| CLAIM_DETAILS  |    899K|00:00:00.03 |    6622 |
```

- N+1 패턴: **총 132,468 Buffers** (20번 실행 누적, 1회 평균 6,623)
- 조인 1회: **총 6,645 Buffers**
- 비율: 132,468 ÷ 6,645 ≈ **19.9배** — 정확히 반복 횟수(20)에 가까운 배수로 커짐. 이는
  `CLAIM_DETAILS` Full Scan 비용(약 6,622)이 그대로 20번 곱해진 결과이기 때문
  (03절 원리 그대로)

## 06. Bad SQL — N+1이 특히 위험한 이유

- 이번 실습은 겨우 20건 기준이었다. 실무 화면에서 "청구 목록 100건"을 보여주며 각
  행마다 상세정보를 N+1로 가져온다면 100번의 반복이 되고, Buffers는 단순 계산으로도
  약 662,200(6,622×100)에 달할 것으로 예상됨 — 조인 1회 방식이라면 여전히 약
  6,600~7,000 수준에 머무를 것
- N+1의 위험한 특징: **목록 건수가 늘어날수록 배수로 나빠짐**. 개발 환경에서 테스트
  데이터가 적을 때는(예: 5건) 문제가 안 보이다가, 운영 환경에서 데이터가 많아지면
  (예: 100건, 1000건) 급격히 느려지는 전형적인 패턴이 바로 이것임

## 07. Tuning — N+1을 피하는 방법

- 가장 직접적인 해법: 04절처럼 반복 조회를 조인 1회로 대체
- 만약 애플리케이션 구조상 조인이 당장 어렵다면, 최소한 반복되는 조회의 `WHERE` 절
  컬럼(`CLAIM_ID`)에 **인덱스를 추가**하는 것만으로도 개별 조회 1회의 비용을 6,623에서
  훨씬 작은 값(인덱스 탐색 수준)으로 낮출 수 있음 — 다만 이는 "완화책"이지 N+1이라는
  반복 호출 구조 자체를 없애는 근본 해법은 아님. 반복 횟수가 계속 늘어나면 인덱스를 타도
  결국 배수로 커지는 것은 마찬가지임(Chapter 4 원칙: 결과가 몇 건이든 Full Scan은
  고정비용이지만, 인덱스 탐색은 반복될수록 그 나름대로 누적됨)

## 08. Benchmark

| 방식 | 실행 횟수 | 총 Buffers | 비고 |
|---|---:|---:|---|
| N+1 (개별 반복 조회) | 20 | 132,468 | 매번 CLAIM_DETAILS Full Scan |
| 조인 1회 | 1 | 6,645 | CLAIM_DETAILS Full Scan 단 1회 |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch12_문제.md` 참고

## 10. Review

- N+1 문제는 SQL 문장 자체가 아니라 "그 SQL이 몇 번 반복 호출되는가"에서 비롯됨 —
  실행계획만 봐서는 안 보이고, `V$SQL`의 누적 통계(`EXECUTIONS`, `BUFFER_GETS`)로
  확인해야 함
- 반복 조회 대상 컬럼에 인덱스가 없으면 N+1의 각 반복이 Full Scan이 되어 피해가 특히
  커짐
- N+1을 조인 1회로 바꾸면 반복되던 비용(Full Scan 등)이 "한 번"으로 고정되어, 목록
  건수가 늘어나도 비용이 배수로 커지지 않음
- 개발 환경의 적은 테스트 데이터로는 N+1이 잘 드러나지 않으므로, 실제 운영 규모를
  가정한 테스트가 중요함
