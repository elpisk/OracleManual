# Chapter 5. 인덱스 설계

- 본 차시는 실습용 인덱스를 생성·삭제함(`IX_CH05_` 접두어). 종료 시 `PK_MEDICAL_CLAIMS`
  외 모든 인덱스를 삭제하고 통계를 재수집해 원상복구함(실제 실행 및 확인 완료)
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: `MEDICAL_CLAIMS(HOSP_ID, RECEIPT_DATE)` 복합 인덱스와 컬럼 순서를 반대로 한
  `(RECEIPT_DATE, HOSP_ID)` 인덱스를 각각 만들어 비교

---

## 01. Why

- Chapter 4에서 "인덱스가 유리한 상황"을 확인했지만, 정작 인덱스를 어떻게 설계해야
  하는지(어떤 컬럼을, 어떤 순서로)는 다루지 않음
- 잘못 설계된 인덱스는 있어도 안 쓰이거나, 유지보수 비용만 늘릴 수 있음 — 본 차시 목표는
  복합 인덱스의 컬럼 순서가 실제로 실행계획에 미치는 영향을 실측으로 확인하는 것

## 02. Concept

- B-Tree 인덱스: 컬럼 값을 정렬된 트리 구조로 저장해, 특정 값이나 범위를 빠르게 찾을 수
  있게 함
- 단일 컬럼 인덱스: 컬럼 하나만으로 구성
- 복합 인덱스: 여러 컬럼을 정해진 순서로 묶어 하나의 인덱스로 구성. 순서가 중요함(03절)
- 선두 컬럼: 복합 인덱스에서 맨 앞에 오는 컬럼. 인덱스가 정렬되는 기준이 되는 컬럼

## 03. Oracle Internals — 컬럼 순서가 중요한 이유

- 복합 인덱스는 선두 컬럼 값을 기준으로 먼저 정렬되고, 그 안에서 두 번째 컬럼 값이
  정렬됨 — 마치 전화번호부가 "성"으로 먼저 정렬되고 그 안에서 "이름"으로 정렬되는 것과
  같은 구조
- 조건에 **선두 컬럼이 포함**되어 있으면, 인덱스에서 해당 값(또는 범위)의 시작·끝 위치를
  바로 찾아갈 수 있음 → `INDEX RANGE SCAN`
- 조건에 **선두 컬럼이 빠지고 후행 컬럼만** 있으면, 인덱스가 그 컬럼 기준으로는 정렬되어
  있지 않으므로 특정 위치를 바로 찾아갈 수 없음 → 인덱스 전체를 순서 없이 다 훑는
  `INDEX FAST FULL SCAN`으로 대체되거나(인덱스가 작으면), 아예 사용되지 않을 수 있음
- 인덱스의 장점: 조건에 맞는 소수의 행을 빠르게 찾음(선택도가 낮을 때 효과적, Chapter 4)
- 인덱스의 비용: 저장 공간을 추가로 차지하고, 원본 테이블에 INSERT/UPDATE/DELETE가
  일어날 때마다 인덱스도 함께 갱신해야 해서 DML 비용이 늘어남
- 인덱스를 너무 많이 만들면 생기는 문제: 테이블 하나에 인덱스가 여러 개면 DML 한 번에
  그 인덱스 개수만큼 추가 갱신이 발생함. 조회 성능을 위해 만든 인덱스가 입력·수정 성능을
  갉아먹는 트레이드오프 관계에 있음 — 이 챕터에서는 실측하지 않고 원리로만 짚음

## 04. Example

```sql
-- 인덱스 A: (HOSP_ID, RECEIPT_DATE) 순서
CREATE INDEX ix_hosp_receipt ON medical_claims(hosp_id, receipt_date);

-- 세 가지 조건으로 테스트
SELECT COUNT(*) FROM medical_claims WHERE hosp_id = 1 AND receipt_date = DATE'2024-06-15'; -- 둘 다
SELECT COUNT(*) FROM medical_claims WHERE hosp_id = 1;                                     -- 선두만
SELECT COUNT(*) FROM medical_claims WHERE receipt_date = DATE'2024-06-15';                 -- 후행만
```

## 05. Execution Plan — 인덱스 A `(HOSP_ID, RECEIPT_DATE)` 실측

| 조건 | Operation | Buffers | A-Rows |
|---|---|---:|---:|
| HOSP_ID=1 AND RECEIPT_DATE=.. (둘 다, 선두 포함) | INDEX RANGE SCAN | 3 | 11 |
| HOSP_ID=1 (선두 컬럼만) | INDEX RANGE SCAN | 12 | 3,058 |
| RECEIPT_DATE=.. (후행 컬럼만) | INDEX FAST FULL SCAN | 953 | 789 |

- 선두 컬럼(HOSP_ID)이 조건에 포함되면 두 경우 모두 `INDEX RANGE SCAN`으로 저렴하게
  처리됨(Buffers 3, 12)
- 후행 컬럼(RECEIPT_DATE)만 조건에 있으면 `INDEX RANGE SCAN`을 못 쓰고
  `INDEX FAST FULL SCAN`(인덱스 전체를 순서 없이 훑음)으로 전환되어 Buffers가 953까지
  치솟음 — 그래도 Full Table Scan(Chapter 4 기준 3,090)보다는 저렴한데, 인덱스 자체가
  테이블보다 작기 때문(RECEIPT_DATE 조건에 안 맞는 행도 인덱스에는 다 들어있지만, 인덱스
  엔트리가 테이블 행 전체보다 훨씬 작아서)

## 06. Bad SQL — 컬럼 순서를 반대로 하면?

인덱스 A를 삭제하고 컬럼 순서만 반대로 한 인덱스 B `(RECEIPT_DATE, HOSP_ID)`를 만들어
동일한 세 조건을 재실행:

| 조건 | Operation | Buffers | A-Rows |
|---|---|---:|---:|
| HOSP_ID=1 AND RECEIPT_DATE=.. (둘 다) | INDEX RANGE SCAN | 3 | 11 |
| HOSP_ID=1 (이번엔 후행 컬럼) | INDEX FAST FULL SCAN | 954 | 3,058 |
| RECEIPT_DATE=.. (이번엔 선두 컬럼) | INDEX RANGE SCAN | 5 | 789 |

- 두 조건을 모두 쓰는 첫 번째 경우는 인덱스 A든 B든 결과가 거의 같음(Buffers 3) — 컬럼
  순서와 무관하게 두 컬럼 다 조건에 있으면 인덱스를 온전히 활용할 수 있음
- 하지만 `HOSP_ID`만 조건에 있는 두 번째 경우는 인덱스 A에서는 저렴했지만(Buffers 12,
  선두 컬럼이었으므로) 인덱스 B에서는 비쌈(Buffers 954, 이번엔 후행 컬럼이므로) — 정확히
  뒤바뀜
- 결론: **어떤 컬럼을 선두에 둘지는 "이 인덱스를 어떤 조건으로 조회할 것인가"에 달려
  있다.** 두 컬럼을 항상 같이 조건으로 쓴다면 순서가 덜 중요하지만, 컬럼 하나만 단독으로
  자주 조회한다면 그 컬럼이 선두에 있어야 함

## 07. Tuning — 이번 스키마에 적용한다면

- `MEDICAL_CLAIMS`를 실무에서 조회하는 패턴을 가정
  - "특정 병원의 특정 기간 청구 조회"가 잦다면 `(HOSP_ID, RECEIPT_DATE)`가 적합
  - "기간 전체 청구 현황 조회(병원 무관)"가 더 잦다면 `(RECEIPT_DATE, HOSP_ID)`가 적합
- 두 조회 패턴이 비슷한 빈도로 필요하다면, 인덱스 하나로 둘 다 완벽히 커버할 수 없음 —
  이 경우 인덱스 두 개를 만들지, 하나만 만들고 다른 조회는 다소 느린 것을 감수할지는
  "인덱스를 너무 많이 만들면 생기는 문제"(03절)와 저울질해서 결정해야 함

## 08. Benchmark — 종합 비교표

| 인덱스 | 조건 | Buffers | 비고 |
|---|---|---:|---|
| 없음(Full Scan) | HOSP_ID+RECEIPT_DATE | 3,090 | Chapter 3 베이스라인 |
| A `(HOSP_ID, RECEIPT_DATE)` | HOSP_ID만 | 12 | 선두 컬럼 매치 |
| A `(HOSP_ID, RECEIPT_DATE)` | RECEIPT_DATE만 | 953 | 후행 컬럼만 매치 |
| B `(RECEIPT_DATE, HOSP_ID)` | HOSP_ID만 | 954 | 이번엔 후행 컬럼 |
| B `(RECEIPT_DATE, HOSP_ID)` | RECEIPT_DATE만 | 5 | 이번엔 선두 컬럼 |

같은 두 컬럼, 같은 조건이라도 인덱스 컬럼 순서에 따라 Buffers가 12↔954, 953↔5로 정확히
뒤바뀜 — 선두 컬럼 선택이 복합 인덱스 설계에서 가장 먼저 결정해야 할 사항임을 보여줌

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch05_문제.md` 참고

## 10. Review

- 복합 인덱스는 선두 컬럼을 기준으로 정렬됨 — 조건에 선두 컬럼이 포함되어야
  `INDEX RANGE SCAN`으로 저렴하게 처리됨
- 후행 컬럼만으로는 `INDEX RANGE SCAN`을 못 쓰고 `INDEX FAST FULL SCAN`(또는 미사용)으로
  전환되어 비용이 크게 늘어남
- 인덱스 컬럼 순서를 정할 때는 "이 인덱스가 실제로 어떤 조건으로 조회될 것인가"를
  기준으로 삼아야 함
- 인덱스는 조회를 빠르게 하지만 DML 비용을 늘리는 트레이드오프가 있음 — 무조건 많이
  만드는 것이 능사가 아님
