# Chapter 4. Full Scan vs Index Scan

- 본 차시는 인덱스를 신규 생성하지 않음(기존 PK만 사용)
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: 작은 테이블(HOSPITALS) vs 큰 테이블(CLAIM_DETAILS)의 Full Scan 비용 비교, 그리고
  `PK_MEDICAL_CLAIMS`를 이용한 범위 조회에서 선택도에 따라 접근 방식이 바뀌는 지점 확인

---

## 01. Why

- Chapter 3에서 Full Scan과 여러 Index Scan을 "읽는 법"은 익혔지만, **언제 어느 쪽이
  유리한지** 판단하는 기준은 아직 다루지 않음
- "인덱스가 있으면 무조건 인덱스를 써야 좋다"는 생각은 틀린 경우가 많음 — 본 차시는 그
  경계를 실측으로 확인함

## 02. Concept

- Selectivity(선택도): 조건을 만족하는 행이 전체 중 차지하는 비율. 선택도가 낮을수록(=
  조건을 만족하는 행이 적을수록) 인덱스가 유리해짐
- Cardinality(카디널리티): 조건을 만족하는 실제 행의 개수(선택도 × 전체 행 수)
- 데이터 분포: 컬럼 값이 고르게 퍼져 있는지, 특정 값에 몰려 있는지에 따라 같은 조건이라도
  선택도가 달라짐

## 03. Oracle Internals

- Full Scan 비용: **테이블 전체 블록 수에 비례**함. 조건을 만족하는 행이 1건이든 90만
  건이든, Full Scan은 테이블의 모든 블록을 읽어야 하므로 비용이 거의 고정적임
- Index Range Scan 비용: **조건을 만족하는 행의 개수(와 그 행들을 찾아가는 랜덤 접근
  비용)에 비례**함. 조건을 만족하는 행이 적으면 매우 저렴하지만, 많아지면 랜덤 접근이
  누적되어 오히려 Full Scan보다 비싸질 수 있음
- 이 두 비용 곡선이 교차하는 지점이 있음 — 선택도가 그 지점보다 낮으면(적게 걸리면) 인덱스가,
  높으면(많이 걸리면) Full Scan이 유리함. 옵티마이저는 이 교차점을 통계정보로 추정해서
  자동으로 판단함
- 작은 테이블에서 Full Scan이 유리한 이유: 애초에 전체 블록 수가 적어서, 설령 조건을
  만족하는 행이 1건뿐이어도 인덱스를 거쳐 테이블에 접근하는 오버헤드(추가 단계)보다
  그냥 다 읽는 게 더 쌀 수 있음

## 04. Example — 작은 테이블 vs 큰 테이블 Full Scan

```sql
-- A. 작은 테이블(HOSPITALS, 1,000건)
SELECT COUNT(*) FROM hospitals WHERE hosp_type = '의원';

-- B. 큰 테이블(CLAIM_DETAILS, 약 90만 건, 비인덱스 컬럼)
SELECT COUNT(*) FROM claim_details WHERE claim_id = '20240615-0013440';
```

## 05. Execution Plan — 실측 비교

**A. HOSPITALS (1,000건)**

```text
| Id | Operation         | Name      | E-Rows | A-Rows |   A-Time   | Buffers |
| 2  |  TABLE ACCESS FULL | HOSPITALS |    250 |    800 |00:00:00.04 |      15 |
```

**B. CLAIM_DETAILS (약 90만 건)**

```text
| Id | Operation         | Name          | E-Rows | A-Rows |   A-Time   | Buffers |
| 2  |  TABLE ACCESS FULL | CLAIM_DETAILS |      3 |      3 |00:00:00.05 |    6621 |
```

- 두 쿼리 모두 조건에 맞는 인덱스가 없어 Full Scan만 가능한 상황이었음
- HOSPITALS는 조건에 800건이나 걸렸는데도 Buffers 15에 그침 — 테이블 자체가 작기 때문
- CLAIM_DETAILS는 조건에 딱 3건만 걸렸는데도 Buffers 6,621 — 결과가 적어도 테이블
  전체(90만 건)를 다 읽어야 했기 때문
- 결론: Full Scan 비용은 **결과 건수가 아니라 테이블 크기**로 결정됨. CLAIM_DETAILS의
  3건짜리 결과에 6,621 Buffers가 든 것이 그 증거

## 06. Bad SQL — 선택도에 따른 접근 방식 전환

`PK_MEDICAL_CLAIMS`(CLAIM_ID 기준)를 이용해 범위를 점점 넓혀가며 관찰:

```sql
SELECT SUM(total_amt) FROM medical_claims
WHERE claim_id BETWEEN '20240101-0000000' AND :end_id;
```

| 범위 | 대상 건수(전체 30만건 중) | 선택도 | Operation | Buffers |
|---|---:|---:|---|---:|
| 약 1일 | 838건 | 0.3% | TABLE ACCESS BY INDEX ROWID BATCHED + INDEX RANGE SCAN | 731 |
| 약 1개월 | 25,406건 | 8.5% | TABLE ACCESS FULL | 3,090 |
| 약 6개월 | 148,028건 | 49% | TABLE ACCESS FULL | 3,090 |
| 약 11개월 | 274,000여건 | 91% | TABLE ACCESS FULL | 3,090 |

- 838건(0.3%)에서는 인덱스를 썼고, 25,406건(8.5%)부터는 Full Scan으로 전환됨 — 이 사이
  어딘가에 교차점이 있음(정확한 경계는 데이터·통계에 따라 달라짐)
- 25,406건부터 274,000여건까지 Buffers가 전부 3,090으로 동일함 — Full Scan은 결과가
  얼마나 많이 나오든 비용이 고정적이라는 05절 원칙과 일치함
- 참고(중요): `COUNT(*)`만 필요한 경우(테이블 컬럼 접근이 필요 없는 경우)라면 838건은
  물론 148,028건(49%)에서도 인덱스만으로 처리되어 Buffers가 훨씬 작았음(910) — 이는
  `TOTAL_AMT` 같은 인덱스에 없는 컬럼을 실제로 읽어야 하는지 여부에 따라 결과가 크게
  달라짐을 보여줌. Chapter 3의 "인덱스만으로 끝나는 쿼리 vs 테이블까지 가야 하는 쿼리"
  구분(Q2/Q5)이 여기서도 그대로 적용됨

## 07. Tuning (예고)

- "몇 % 선택도부터 인덱스가 유리한지"에 대한 절대적인 숫자는 없음 — 테이블·인덱스 크기,
  한 블록에 몇 행이 들어가는지(클러스터링 팩터), 인덱스만으로 끝나는지 여부에 따라 교차점이
  달라짐
- 실제 인덱스를 설계할 때 선택도를 어떻게 고려하는지는 Chapter 5에서 다룸

## 08. Benchmark — 선택도별 접근 방식 요약

| 선택도 | 접근 방식 경향 | 이번 챕터 근거 |
|---|---|---|
| 매우 낮음(0.3% 수준) | Index Range Scan 유리 | 838건, Buffers 731 |
| 중간(8% 이상) | Full Scan으로 전환 | 25,406건부터 Buffers 3,090 |
| 인덱스만으로 처리 가능(Index-Only) | 선택도가 높아도(49%) 인덱스 유지 | COUNT(*)류 쿼리, Buffers 910 |
| 테이블 자체가 작음 | 선택도 무관하게 Full Scan이 충분히 저렴 | HOSPITALS, Buffers 15 |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch04_문제.md` 참고

## 10. Review

- Full Scan 비용은 결과 건수가 아니라 테이블 크기에 비례함
- Index Range Scan 비용은 결과 건수에 비례하며, 결과가 많아지면 Full Scan보다 비쌀 수 있음
- 선택도가 낮으면(적게 걸리면) 인덱스가, 높으면(많이 걸리면) Full Scan이 유리한 경향이
  있으나 정확한 교차점은 데이터·쿼리 특성마다 다름
- 인덱스만으로 결과를 낼 수 있는 쿼리(Index-Only)는 선택도가 높아도 인덱스가 계속 유리할
  수 있음 — "테이블 접근이 필요한가"가 선택도 못지않게 중요한 변수
- 작은 테이블은 인덱스 유무와 무관하게 Full Scan이 저렴한 경우가 많음
