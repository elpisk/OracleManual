# Chapter 9. UNION / UNION ALL / DISTINCT

- 본 차시는 DDL 변경 없음(기존 PK만 사용)
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: "입원 청구를 낸 환자" ∪ "의료급여 환자"를 `UNION`/`UNION ALL`로 비교, 그리고
  이미 유일함이 보장된 컬럼에 불필요한 `DISTINCT`를 붙였을 때의 실측

---

## 01. Why

- `UNION`과 `UNION ALL`을 습관적으로 아무거나 쓰는 경우가 많음 — 두 결과 집합에 중복이
  있을 수 있는지 따져보지 않고 "일단 중복 제거되는 UNION을 쓰자"는 식
- 본 차시 목표: 중복 제거(`DISTINCT`, `UNION`)에 실제로 어떤 비용이 드는지, 그리고 그
  비용이 항상 발생하는 것은 아니라는 점을 실측으로 확인

## 02. Concept

- `UNION`: 두 결과 집합을 합치면서 중복된 행을 제거함
- `UNION ALL`: 두 결과 집합을 그대로 이어붙임(중복 제거 없음)
- `DISTINCT`: 결과 집합에서 중복된 행을 제거함(단일 쿼리에도 적용 가능)
- 중복 제거 비용: 일반적으로 전체 결과를 정렬(SORT)하거나 해시로 묶어서 같은 값을
  찾아내는 과정이 필요함 — 03절에서 이 비용이 어떻게 나타나는지 확인

## 03. Oracle Internals — 중복 제거의 실제 비용은 어디에 나타나는가

- `UNION`은 내부적으로 `UNION-ALL`(합치기) 이후 `SORT UNIQUE`(정렬 후 중복 제거) 단계를
  추가로 거침
- 이 `SORT UNIQUE` 단계는 이미 메모리로 가져온 데이터를 대상으로 하는 **CPU/메모리
  작업**이라, 디스크·버퍼 캐시 블록을 추가로 읽는 것이 아님 — 그래서 `Buffers` 지표에는
  거의 나타나지 않고, 대신 `A-Time`(실제 소요 시간)이나 `OMem`/`1Mem`/`Used-Mem`(작업
  메모리 사용량) 지표에 나타남
- 즉 `Buffers`만 보고 "UNION과 UNION ALL의 비용이 같다"고 단정하면 안 됨 — 이 챕터는
  그 함정을 실측으로 짚음
- `DISTINCT`도 마찬가지로 SORT/HASH 기반 중복 제거가 필요하지만, 만약 옵티마이저가
  "이 컬럼은 이미 유일함이 보장된다"(PK, 유니크 인덱스 등)는 것을 알고 있다면 이 단계
  자체를 **완전히 생략**할 수 있음(06절)

## 04. Example — UNION vs UNION ALL

```sql
-- Q1. UNION (중복 제거)
SELECT COUNT(*) FROM (
  SELECT pat_id FROM medical_claims WHERE claim_type = '입원'
  UNION
  SELECT pat_id FROM patients WHERE ins_type = '의료급여'
);

-- Q2. UNION ALL (중복 미제거)
SELECT COUNT(*) FROM (
  SELECT pat_id FROM medical_claims WHERE claim_type = '입원'
  UNION ALL
  SELECT pat_id FROM patients WHERE ins_type = '의료급여'
);
```

## 05. Execution Plan — 실측 비교

**Q1. UNION**

```text
| Id | Operation           | Name           | A-Rows |   A-Time   | Buffers | OMem  | 1Mem | Used-Mem  |
| 0  | SELECT STATEMENT    |                |      1 |00:00:00.07 |    3532 |       |      |           |
| 1  |  SORT AGGREGATE     |                |      1 |00:00:00.07 |    3532 |       |      |           |
| 2  |   VIEW              |                |  35985 |00:00:00.07 |    3532 |       |      |           |
| 3  |    SORT UNIQUE      |                |  35985 |00:00:00.06 |    3532 | 1824K | 791K | 1621K (0) |
| 4  |     UNION-ALL       |                |  64011 |00:00:00.04 |    3532 |       |      |           |
| 5  |      TABLE ACCESS FULL| MEDICAL_CLAIMS|  59511 |00:00:00.02 |    3090 |       |      |           |
| 6  |      TABLE ACCESS FULL| PATIENTS      |   4500 |00:00:00.01 |     442 |       |      |           |
```

**Q2. UNION ALL**

```text
| Id | Operation           | Name           | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT    |                |      1 |00:00:00.03 |    3532 |
| 1  |  SORT AGGREGATE     |                |      1 |00:00:00.03 |    3532 |
| 2  |   VIEW              |                |  64011 |00:00:00.02 |    3532 |
| 3  |    UNION-ALL        |                |  64011 |00:00:00.02 |    3532 |
| 4  |     TABLE ACCESS FULL| MEDICAL_CLAIMS|  59511 |00:00:00.01 |    3090 |
| 5  |     TABLE ACCESS FULL| PATIENTS      |   4500 |00:00:00.01 |     442 |
```

**결과 건수**: Q1(UNION) = 35,985건, Q2(UNION ALL) = 64,011건 — **28,026건의 차이**는
곧 "입원 청구를 낸 환자이면서 동시에 의료급여 환자이기도 한" 중복이 그만큼 실제로
존재했다는 뜻

- `Buffers`는 두 쿼리 모두 **3,532로 완전히 동일**함 — `SORT UNIQUE` 단계가 이미 읽어온
  데이터를 메모리에서 처리하는 작업이라 추가 블록 접근이 없기 때문(03절)
- 하지만 `A-Time`은 Q1이 0.07초, Q2가 0.03초로 2배 이상 차이 남 — `SORT UNIQUE`의 CPU
  비용이 여기에 나타남
- 만약 Buffers만 보고 판단했다면 "UNION과 UNION ALL은 비용이 같다"고 잘못 결론 내렸을
  것임

## 06. Bad SQL — 오히려 불필요한 DISTINCT는 완전히 제거되기도 함

```sql
-- Q3. 이미 유일함이 보장된 컬럼에 DISTINCT
SELECT DISTINCT hosp_id FROM hospitals WHERE hosp_id <= 100;

-- Q4. DISTINCT 없이 동일 조회
SELECT hosp_id FROM hospitals WHERE hosp_id <= 100;
```

```text
Q3, Q4 공통 실행계획 (Plan hash value 완전히 동일: 1619867082)
| Id | Operation         | Name         | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT  |              |    100 |00:00:00.01 |       9 |
| 1  |  INDEX RANGE SCAN | PK_HOSPITALS |    100 |00:00:00.01 |       9 |
```

- `HOSP_ID`는 `HOSPITALS`의 PK다. `DISTINCT`를 붙였는데도 실행계획에 `SORT UNIQUE`나
  `HASH UNIQUE` 같은 중복 제거 오퍼레이션이 **전혀 나타나지 않음**
- 옵티마이저가 "이 컬럼은 PK이므로 애초에 중복이 있을 수 없다"는 사실을 알고 있어서,
  `DISTINCT` 요청 자체를 아무 비용 없이 완전히 생략함
- 즉 "불필요해 보이는 DISTINCT는 항상 낭비"라는 것도 절대적이지 않음 — 유니크 제약이
  걸린 컬럼이라면 옵티마이저가 스스로 제거해준다. 다만 이는 **옵티마이저가 유일성을
  증명할 수 있는 경우에 한함** — 조인을 거치거나 유니크 제약이 없는 컬럼이라면 이런
  자동 생략은 기대할 수 없음

## 07. Tuning — 언제 UNION이 필요하고, 언제 DISTINCT를 빼도 되는가

- `UNION` vs `UNION ALL`: 두 결과 집합이 **논리적으로 겹칠 수 있는지** 먼저 따져야 함.
  이번 실습처럼 실제 겹침이 있다면(입원 환자와 의료급여 환자가 겹칠 수 있음) `UNION`이
  맞고, 두 집합이 애초에 겹칠 수 없는 구조(예: 서로 다른 배타적 조건)라면 `UNION ALL`로
  바꿔 불필요한 `SORT UNIQUE` 비용을 아낄 수 있음
- `DISTINCT` 제거 여부: 조회 대상이 PK나 유니크 인덱스 컬럼이라면 `DISTINCT`를 빼도
  결과가 같고, 옵티마이저가 어차피 생략해줄 가능성이 높음. 반대로 조인 이후의 컬럼처럼
  중복 가능성이 실제로 있는 경우에는 `DISTINCT`가 꼭 필요함

## 08. Benchmark

| 비교 | Buffers | A-Time | 비고 |
|---|---:|---|---|
| UNION (Q1) | 3,532 | 0.07초 | SORT UNIQUE 추가, 결과 35,985건 |
| UNION ALL (Q2) | 3,532 | 0.03초 | SORT UNIQUE 없음, 결과 64,011건(중복 포함) |
| DISTINCT, PK 컬럼(Q3) | 9 | 0.01초 | SORT UNIQUE 완전히 생략됨 |
| DISTINCT 없음, 동일 조회(Q4) | 9 | 0.01초 | Q3과 완전히 동일한 계획 |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch09_문제.md` 참고

## 10. Review

- `UNION`의 중복 제거(`SORT UNIQUE`)는 메모리 내 작업이라 `Buffers`에는 거의 안 나타나고
  `A-Time`·메모리 사용량에 나타남 — Buffers만으로 UNION과 UNION ALL을 비교하면 안 됨
- `UNION`과 `UNION ALL`의 결과 건수 차이 자체가 "실제로 두 집합에 중복이 있었는가"를
  보여주는 증거가 될 수 있음
- PK·유니크 인덱스 컬럼에 붙인 `DISTINCT`는 옵티마이저가 완전히 생략해줄 수 있음 —
  다만 이는 유일성을 증명할 수 있는 경우에 한함
- 두 결과 집합이 논리적으로 겹칠 수 있는지가 `UNION`/`UNION ALL` 선택의 핵심 기준임
