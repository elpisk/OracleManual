# Chapter 7. JOIN 실행 원리

- 본 차시는 실습용 인덱스를 생성·삭제함(`IX_CH07_` 접두어). 종료 시 원상복구 확인 완료
  (`MEDICAL_CLAIMS`는 `PK_MEDICAL_CLAIMS`만 남음)
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: `HOSPITALS`(1,000건, HOSP_ID≤5로 필터) ⋈ `MEDICAL_CLAIMS`(30만 건) 조인에서
  Nested Loops Join과 Hash Join을 힌트로 비교, 인덱스 유무에 따른 차이도 함께 확인

---

## 01. Why

- 지금까지는 단일 테이블 접근(Full Scan/Index Scan)만 다뤘음 — 실무 SQL 대부분은 여러
  테이블을 조인함
- 조인 방식(Nested Loops/Hash/Sort Merge)에 따라 같은 결과라도 비용이 크게 달라질 수
  있음 — 본 차시 목표는 그 차이를 실측하고, 힌트로 방식을 강제했을 때 실제로 의도대로
  적용되는지까지 확인하는 것

## 02. Concept

- JOIN의 기본 원리: 두 테이블(또는 결과 집합)에서 조인 조건에 맞는 행끼리 짝지어 하나의
  결과로 합치는 연산
- Nested Loops Join(NL): 한쪽(Outer, 드라이빙 테이블)의 각 행마다 다른 쪽(Inner, 드리븐
  테이블)에서 조건에 맞는 행을 찾아 반복적으로 결합
- Hash Join: 작은 쪽으로 해시 테이블을 메모리에 만든 뒤(Build), 큰 쪽을 한 번 훑으며
  (Probe) 매칭되는 행을 찾아 결합
- Driving Table(드라이빙 테이블): 조인을 시작하는 기준이 되는 테이블. NL에서는 Outer,
  Hash Join에서는 Build 쪽에 해당

## 03. Oracle Internals

- NL Join 비용: Outer 쪽 행 수 × (Inner 쪽에서 한 번 찾는 비용). Inner 테이블의 조인
  컬럼에 **인덱스가 있어야** 한 번 찾는 비용이 저렴함. 인덱스가 없으면 Outer 행 하나마다
  Inner 테이블을 통째로 훑어야 해서 치명적으로 느려질 수 있음
- Hash Join 비용: 두 테이블을 각각 한 번씩 읽는 비용에 가까움(Build 한 번 + Probe 한
  번). Outer 쪽에 인덱스가 없어도 상대적으로 안정적임
- 일반적 선택 기준: 조인 대상 중 한쪽이 매우 작고 다른 쪽의 조인 컬럼에 인덱스가 있으면
  NL이 유리, 양쪽 다 크거나 인덱스가 없으면 Hash Join이 유리한 경향이 있음(절대적 규칙은
  아니며 옵티마이저가 비용으로 판단)
- **힌트는 지시일 뿐 보장이 아님**: 옵티마이저가 쿼리를 내부적으로 변환(예: GROUP BY
  위치 조정)하는 과정에서 힌트가 적용되는 대상이 달라지거나 무시될 수 있음 — 06절 사례가
  이를 실측으로 보여줌

## 04. Example

```sql
SELECT h.hosp_type, COUNT(*)
FROM hospitals h, medical_claims m
WHERE h.hosp_id = m.hosp_id
AND   h.hosp_id <= 5
GROUP BY h.hosp_type;
```

## 05. Execution Plan — 인덱스 없는 상태에서 힌트 강제 실측

**Q1. 힌트 없음(베이스라인)**

```text
| Id | Operation                          | Name           | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT                   |                |      2 |00:00:00.02 |    3093 |
| 1  |  HASH GROUP BY                     |                |      2 |00:00:00.02 |    3093 |
| 2  |   HASH JOIN                        |                |  15029 |00:00:00.02 |    3093 |
| 3  |    TABLE ACCESS BY INDEX ROWID BATCHED| HOSPITALS   |      5 |00:00:00.01 |       3 |
| 4  |     INDEX RANGE SCAN               | PK_HOSPITALS   |      5 |00:00:00.01 |       2 |
| 5  |    TABLE ACCESS FULL               | MEDICAL_CLAIMS |  15029 |00:00:00.02 |    3090 |
```

**Q3. `/*+ USE_HASH(h m) */` 강제** — Q1과 완전히 동일한 계획(Plan hash value 619494044).
옵티마이저가 원래도 Hash Join을 선택하고 있었다는 뜻

## 06. Bad SQL — 힌트가 의도대로 안 먹힌 사례

**Q2. `/*+ USE_NL(h m) */` 강제했지만...**

```text
| Id | Operation                          | Name           | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT                   |                |      2 |00:00:00.03 |    3093 |
| 1  |  HASH GROUP BY                     |                |      2 |00:00:00.03 |    3093 |
| 2  |   HASH JOIN                        |                |  15029 |00:00:00.03 |    3093 |
| 3  |    VIEW                            | VW_GBF_7       |      5 |00:00:00.01 |       3 |
| 4  |     TABLE ACCESS BY INDEX ROWID BATCHED| HOSPITALS  |      5 |00:00:00.01 |       3 |
| 5  |     INDEX RANGE SCAN               | PK_HOSPITALS   |      5 |00:00:00.01 |       2 |
| 6  |    TABLE ACCESS FULL               | MEDICAL_CLAIMS | 300K   |00:00:00.01 |    3090 |
```

- `USE_NL(h m)`을 명시했는데도 실제 조인 오퍼레이션은 여전히 `HASH JOIN`임 — Buffers도
  Q1과 동일하게 3,093
- 원인: 옵티마이저가 `GROUP BY`를 조인보다 먼저 처리하도록 쿼리를 내부적으로 변환하면서
  `HOSPITALS`를 `VW_GBF_7`이라는 내부 뷰로 감쌌음. 이 변환 이후에는 힌트가 지정한
  `h`, `m` 별칭 조합이 최종 조인 단계에 그대로 대응되지 않아 힌트가 적용되지 못한 것으로
  보임
- 실무 교훈: **힌트를 걸었다고 그대로 적용됐다고 가정하면 안 됨.** 반드시 실행계획을
  다시 확인해서 의도한 오퍼레이션(`NESTED LOOPS` 등)이 실제로 나타났는지 검증해야 함

## 07. Tuning — 인덱스를 만들면 힌트 없이도 NL이 선택됨

`MEDICAL_CLAIMS(HOSP_ID)`에 인덱스를 만든 뒤 동일 쿼리를 재실행:

**Q4. `/*+ USE_NL(h m) */` 강제(인덱스 있음)**

```text
| Id | Operation                          | Name           | Starts | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT                   |                |      1 |      2 |00:00:00.01 |      44 |
| 1  |  HASH GROUP BY                     |                |      1 |      2 |00:00:00.01 |      44 |
| 2  |   NESTED LOOPS                     |                |      1 |  15029 |00:00:00.01 |      44 |
| 3  |    TABLE ACCESS BY INDEX ROWID BATCHED| HOSPITALS   |      1 |      5 |00:00:00.01 |       3 |
| 4  |     INDEX RANGE SCAN               | PK_HOSPITALS   |      1 |      5 |00:00:00.01 |       2 |
| 5  |    INDEX RANGE SCAN               | IX_CH07_HOSPID |      5 |  15029 |00:00:00.01 |      41 |
```

**Q5. 힌트 없음(인덱스 있음)** — Q4와 완전히 동일한 계획(Plan hash value 872004878),
"이 계획은 적응형 계획(adaptive plan)"이라는 안내 문구까지 동일하게 나타남

- 이번엔 `NESTED LOOPS`가 실제로 나타났고, Buffers가 3,093 → 44로 **약 70배** 줄어듦
- Id 5의 `Starts=5`는 `HOSPITALS`에서 걸러진 5건(HOSP_ID≤5) 각각에 대해
  `IX_CH07_HOSPID` 인덱스를 5번 반복 탐색했다는 뜻 — NL의 "Outer 각 행마다 Inner를
  찾는다"는 정의 그대로 실행된 것
- Q5(힌트 없음)가 Q4와 동일한 결과를 낸 것은, 인덱스가 있으면 **옵티마이저가 스스로도
  NL이 더 저렴하다고 판단**한다는 뜻 — 이번엔 힌트가 필요조차 없었음

## 08. Benchmark

| 상황 | 조인 방식 | Buffers |
|---|---|---:|
| 인덱스 없음, 힌트 없음(Q1) | HASH JOIN | 3,093 |
| 인덱스 없음, USE_NL 강제(Q2) | HASH JOIN (힌트 미적용) | 3,093 |
| 인덱스 없음, USE_HASH 강제(Q3) | HASH JOIN | 3,093 |
| 인덱스 있음, USE_NL 강제(Q4) | NESTED LOOPS | 44 |
| 인덱스 있음, 힌트 없음(Q5) | NESTED LOOPS(자동 선택) | 44 |

인덱스 유무가 힌트보다 훨씬 결정적인 변수였음 — 인덱스가 없으면 힌트로 NL을 강제하려
해도(적어도 이번 쿼리 형태에서는) 뜻대로 되지 않았고, 인덱스가 있으면 힌트 없이도
옵티마이저가 알아서 NL을 선택함

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch07_문제.md` 참고

## 10. Review

- NL Join은 Inner(드리븐) 테이블의 조인 컬럼에 인덱스가 있을 때, Outer(드라이빙) 쪽
  행 수가 적을수록 유리함
- Hash Join은 인덱스 유무와 무관하게 양쪽을 각각 한 번씩 읽는 방식이라 상대적으로
  안정적임
- 힌트는 "지시"이지 "보장"이 아님 — 쿼리 변환(GROUP BY 위치 조정 등)이 얽히면 힌트가
  의도대로 적용되지 않을 수 있으므로 반드시 실행계획으로 재확인해야 함
- 지원 인덱스가 없는 상태에서 NL을 강제하는 것은 위험할 수 있음 — 이번 사례에서는
  쿼리 변환 때문에 힌트가 무력화되어 우연히 참사를 피했지만, 힌트가 그대로 적용되는
  다른 쿼리 형태였다면 Outer 행 수만큼 Inner 테이블을 반복 Full Scan하는 최악의 상황이
  될 수 있었음
