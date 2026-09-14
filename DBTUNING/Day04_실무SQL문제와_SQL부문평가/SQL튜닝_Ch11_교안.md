# Chapter 11. 페이징 SQL 튜닝

- 본 차시는 실습용 인덱스를 생성·삭제함(`IX_CH11_` 접두어). 종료 시 원상복구 확인 완료
  (`MEDICAL_CLAIMS`는 `PK_MEDICAL_CLAIMS`만 남음)
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: "청구 목록을 접수일 내림차순으로 20건씩 페이징 조회"를 `OFFSET/FETCH` 방식과
  Keyset(마지막으로 본 값 기준) 방식으로 비교

---

## 01. Why

- "1페이지는 빠른데 뒷페이지로 갈수록 느려진다"는 문제는 리스트·게시판 화면에서 매우
  흔하게 발생함
- 본 차시 목표: 이 현상이 왜 생기는지 실측으로 확인하고, `OFFSET` 깊이가 늘어나도 비용이
  거의 늘지 않는 대안(Keyset Pagination)을 확인함

## 02. Concept

- `OFFSET n ROWS FETCH NEXT m ROWS ONLY`: 정렬된 결과에서 앞의 n건을 건너뛰고 그다음
  m건을 가져옴
- `ROWNUM`: `OFFSET/FETCH`가 없던 시절 Oracle에서 페이징을 구현하던 전통적 방법(인라인
  뷰 + `ROWNUM` 비교)
- Keyset Pagination(키셋 페이징): "몇 번째부터"가 아니라 "마지막으로 본 값보다 작은/큰
  것부터"라는 조건으로 다음 페이지를 가져오는 방식(예: `WHERE receipt_date < :마지막으로_본_날짜`)

## 03. Oracle Internals — OFFSET이 깊어지면 왜 느려지는가

- `OFFSET n ROWS`를 처리하려면 Oracle이 **정렬된 순서에서 몇 번째 행인지**를 알아야
  하므로, 원칙적으로 처음부터 n+m번째 행까지는 순서를 매겨야 함(내부적으로
  `ROW_NUMBER() OVER (ORDER BY ...)`로 변환됨, `Predicate Information`에서 확인 가능)
- 즉 `OFFSET`이 커질수록 "순서를 매겨야 하는 범위" 자체가 커짐 — 물리적으로 읽어야
  하는 테이블 블록 수(Buffers)는 똑같아도(전체를 한 번 스캔하는 것은 동일), 그 결과를
  **정렬·순위 매기는 작업량(CPU, 메모리)**이 `OFFSET` 값에 비례해서 커짐
- 이 비용은 `Buffers`에는 거의 나타나지 않고 `A-Time`과 정렬 작업 메모리(`OMem`/
  `1Mem`/`Used-Mem`)에 나타남 — Chapter 9에서 확인한 "Buffers만으론 안 보이는 비용"이
  여기서도 그대로 재현됨
- Keyset 방식은 "몇 번째인지" 셀 필요 없이 "이 값보다 작은 것"이라는 조건으로 인덱스를
  바로 탐색해 들어갈 수 있어, 페이지 번호(깊이)와 무관하게 비용이 거의 일정함

## 04. Example

```sql
CREATE INDEX ix_receipt ON medical_claims(receipt_date);

-- OFFSET 방식: 페이지 번호로 접근
SELECT claim_id, receipt_date FROM medical_claims
ORDER BY receipt_date DESC
OFFSET :페이지시작 ROWS FETCH NEXT 20 ROWS ONLY;

-- Keyset 방식: 마지막으로 본 값으로 접근
SELECT claim_id, receipt_date FROM medical_claims
WHERE receipt_date < :마지막으로_본_날짜
ORDER BY receipt_date DESC
FETCH FIRST 20 ROWS ONLY;
```

## 05. Execution Plan — OFFSET 깊이에 따른 실측

| OFFSET | Buffers | A-Time | 정렬 작업 메모리(Used-Mem) |
|---|---:|---|---:|
| 0 (1페이지) | 3,090 | 0.02초 | 2K |
| 200,000 (약 1만 페이지) | 3,090 | 0.14초 | 10M |
| 280,000 (약 1만4천 페이지) | 3,090 | 0.18초 | 14M |

- **Buffers는 세 경우 모두 3,090으로 동일함** — `TABLE ACCESS FULL`로 전체 테이블을 한
  번 읽는 것은 OFFSET 값과 무관하기 때문
- 반면 **A-Time은 0.02초 → 0.18초로 9배**, 정렬 작업 메모리는 **2K → 14M로 급증**함 —
  `WINDOW SORT PUSHED RANK` 오퍼레이션(전체 결과에 순위를 매기는 작업)이 OFFSET이
  커질수록 더 많은 행을 순위 매겨야 하기 때문
- 만약 Buffers만 보고 성능을 판단했다면 "페이지가 깊어져도 비용은 그대로"라고 잘못
  결론 내렸을 것임(Chapter 9의 교훈이 그대로 재현됨)

## 06. Bad SQL — Keyset 방식과의 비교

같은 정도의 깊이(약 280,000번째 부근)를 Keyset 방식으로 조회:

```text
| Id | Operation                    | Name             | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT             |                  |     20 |00:00:00.01 |      25 |
| 1  |  VIEW                        |                  |     20 |00:00:00.01 |      25 |
| 2  |   WINDOW NOSORT STOPKEY      |                  |     20 |00:00:00.01 |      25 |
| 3  |    TABLE ACCESS BY INDEX ROWID| MEDICAL_CLAIMS  |     20 |00:00:00.01 |      25 |
| 4  |     INDEX RANGE SCAN DESCENDING| IX_RECEIPT     |     20 |00:00:00.01 |       6 |
```

- Buffers **25**, A-Time **0.01초** — OFFSET 280,000 방식(Buffers 3,090, A-Time
  0.18초)과 비교가 안 될 정도로 저렴함
- `WINDOW SORT PUSHED RANK`(전체를 순위 매김) 대신 `WINDOW NOSORT STOPKEY`(인덱스가
  이미 정렬된 순서이므로 필요한 20건만 채우고 즉시 중단)가 선택됨 — Chapter 3의 Q4,
  Chapter 10의 좁은 범위 사례와 같은 원리
- `INDEX RANGE SCAN DESCENDING`은 `receipt_date < :마지막_날짜` 조건으로 인덱스에서
  그 지점을 바로 찾아 들어간 뒤 내림차순으로 20건만 읽고 멈춤 — "몇 번째 페이지인지" 셀
  필요가 전혀 없음

## 07. Tuning — Keyset 방식의 제약

- Keyset 방식은 "임의의 페이지 번호로 바로 이동"(예: "정확히 500페이지로 가줘")이
  어려움 — "마지막으로 본 값"이라는 커서 정보가 있어야 다음 페이지를 알 수 있는 구조라,
  순차적으로 다음/이전 페이지로 넘어가는 UI(무한 스크롤, "더보기" 버튼)에 적합함
- 반대로 "몇 페이지째인지" 숫자를 보여주거나 임의 페이지로 점프해야 하는 UI라면
  `OFFSET` 방식이 불가피할 수 있음 — 이 경우 07절의 비용을 감수하거나, 페이지 깊이에
  제한을 두는 등의 절충이 필요함

## 08. Benchmark

| 방식 | 깊이 | Buffers | A-Time |
|---|---|---:|---|
| OFFSET | 0 | 3,090 | 0.02초 |
| OFFSET | 200,000 | 3,090 | 0.14초 |
| OFFSET | 280,000 | 3,090 | 0.18초 |
| Keyset | 약 280,000 상당 | 25 | 0.01초 |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch11_문제.md` 참고

## 10. Review

- `OFFSET`이 깊어질수록 "순위를 매겨야 하는 범위"가 커져 CPU·메모리 비용이 커짐 —
  이 비용은 Buffers에는 잘 안 나타나고 A-Time·작업 메모리에 나타남
- Keyset Pagination은 인덱스로 바로 다음 페이지의 시작점을 찾아가므로, 페이지 깊이와
  무관하게 비용이 거의 일정함
- Keyset 방식은 "다음/이전 페이지"로만 이동 가능하다는 제약이 있어, UI 요구사항에 따라
  `OFFSET` 방식을 완전히 대체하지 못할 수도 있음
- 인덱스가 정렬 순서를 제공하면 `WINDOW SORT`(전체 순위 매김) 대신 `WINDOW NOSORT
  STOPKEY`(필요한 만큼만 읽고 중단)가 선택될 수 있음(Chapter 3·10과 동일한 원리)
