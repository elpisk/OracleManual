# Chapter 10. SORT / GROUP BY / 집계

- 본 차시는 DDL 변경 없음(기존 PK만 사용)
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: GROUP BY 대상을 줄이는 순서(필터를 먼저 vs 나중에), 그리고 ORDER BY 대상 컬럼에
  따라 정렬(SORT)이 생략되는지 여부

---

## 01. Why

- 집계(GROUP BY)와 정렬(ORDER BY)은 거의 모든 리포트성 쿼리에 들어감 — 이 두 연산이
  언제 비용을 유발하고 언제 생략되는지 아는 것이 중요함
- 흔한 믿음: "필터를 먼저 걸어야 집계가 빨라진다", "인덱스 컬럼으로 정렬하면 정렬이
  생략된다" — 본 차시는 이 두 믿음을 실측으로 검증함

## 02. Concept

- `ORDER BY`: 결과를 특정 순서로 정렬. 인덱스가 이미 그 순서로 정렬돼 있으면 별도의
  `SORT` 연산 없이 그대로 반환 가능
- `GROUP BY`: 지정한 컬럼(들)의 값이 같은 행끼리 묶어 집계. `HASH GROUP BY`(해시 기반)나
  `SORT GROUP BY`(정렬 기반) 방식으로 처리됨(이 스키마에서는 대부분 `HASH GROUP BY`가
  선택됨)
- 집계 대상 데이터 줄이기: 집계할 행의 수가 적을수록 `GROUP BY`의 CPU·메모리 부담이
  줄어듦 — 그래서 "필터를 먼저 걸어 집계 대상을 줄이자"는 조언이 흔함

## 03. Oracle Internals — 필터 위치보다 중요한 것

- `WHERE` 조건이 **GROUP BY 키 컬럼 자체**에 걸려 있다면(집계 결과가 아니라 그룹을
  나누는 기준 컬럼), 옵티마이저는 그 조건을 SQL에 어디 적혀 있든 **그룹화 이전으로
  자동으로 밀어넣을 수 있음**(predicate pushdown) — 그룹을 나누는 기준 자체가 이미
  좁혀지므로 결과가 달라지지 않기 때문
- 반면 `HAVING`처럼 **집계 함수의 결과**(`COUNT(*)`, `SUM(...)` 등)에 거는 조건은 그
  집계가 끝나야 값을 알 수 있으므로, 그룹화 이전으로 밀어넣을 수 없음(Chapter 8의
  인라인 뷰 사례가 이 경우였음 — 다만 그때는 집계 자체를 다시 계산할 필요는 없어 비용은
  같았음)
- 즉 "필터를 SQL 어디에 쓰느냐"보다 "그 필터가 그룹 키에 관한 것이냐, 집계 결과에 관한
  것이냐"가 실제 처리 방식을 결정함

## 04. Example — GROUP BY 필터 위치

```sql
-- Q1. WHERE로 먼저 필터(집계 대상 컬럼 아님, 그룹 키에 대한 필터)
SELECT hosp_id, COUNT(*), SUM(total_amt)
FROM medical_claims
WHERE claim_type = '입원'
GROUP BY hosp_id;

-- Q2. 불필요하게 claim_type까지 그룹핑한 뒤 바깥에서 필터(의도한 "비효율" 패턴)
SELECT hosp_id, cnt, total FROM (
  SELECT hosp_id, claim_type, COUNT(*) cnt, SUM(total_amt) total
  FROM medical_claims
  GROUP BY hosp_id, claim_type
) WHERE claim_type = '입원';
```

## 05. Execution Plan — 실측 결과 (놀랍게도 완전히 동일)

```text
Q1, Q2 공통 실행계획 (Plan hash value 완전히 동일: 3971657403)
| Id | Operation         | Name           | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT  |                |   1000 |00:00:00.03 |    3090 |
| 1  |  HASH GROUP BY    |                |   1000 |00:00:00.03 |    3090 |
| 2  |   TABLE ACCESS FULL| MEDICAL_CLAIMS|  59511 |00:00:00.03 |    3090 |
```

- Q2를 "일부러 비효율적으로" 작성했는데도(그룹핑 컬럼을 하나 더 추가한 뒤 바깥에서
  필터) 실행계획이 Q1과 **완전히 같음**
- 원인: `claim_type='입원'`이라는 조건이 `GROUP BY`의 **기준 컬럼(claim_type) 자체**에
  대한 것이었기 때문에, 옵티마이저가 이 조건을 그룹화 이전(`TABLE ACCESS FULL` 단계의
  필터)으로 자동으로 밀어넣었고, 그 결과 애초에 `claim_type`으로 나눌 필요가 없다는
  것까지 인식해 `GROUP BY hosp_id`만 남긴 것과 동일한 계획이 됨
- 실무 교훈: "필터를 먼저 쓰지 않으면 손해"라는 걱정은 **그 필터가 그룹 키에 대한
  것이라면** 대체로 기우임 — 옵티마이저가 알아서 밀어넣어 준다

## 06. Bad SQL — ORDER BY의 정렬 생략은 선택도에 달려 있음

같은 두 컬럼(`CLAIM_ID`, `TOTAL_AMT`)을 정렬 기준으로 바꿔가며, **범위가 넓을 때**와
**좁을 때**를 각각 확인:

**범위가 넓을 때(약 1개월, 8.5% 선택도 — Chapter 4에서 이미 Full Scan 전환 구간으로
확인된 범위)**

| 정렬 기준 | Operation | Buffers |
|---|---|---:|
| `ORDER BY total_amt`(비인덱스) | `SORT ORDER BY` + `TABLE ACCESS FULL` | 3,090 |
| `ORDER BY claim_id`(PK 컬럼) | `SORT ORDER BY` + `TABLE ACCESS FULL` | 3,090 |

- 이 범위에서는 **두 경우 모두 정렬이 생략되지 않음**. `claim_id`가 PK라 해도, 이미
  선택도 때문에 `TABLE ACCESS FULL`이 선택된 상황이라 인덱스의 정렬 순서를 애초에
  활용할 수 없기 때문(Full Scan은 특정 순서를 보장하지 않음)

**범위가 좁을 때(약 1일, 0.27% 선택도)**

| 정렬 기준 | Operation | Buffers |
|---|---|---:|
| `ORDER BY claim_id`(PK 컬럼) | `INDEX RANGE SCAN`만(정렬 생략됨) | 776 |
| `ORDER BY total_amt`(비인덱스) | `SORT ORDER BY` + `INDEX RANGE SCAN` | 717 |

- 이번엔 좁은 선택도 덕분에 `INDEX RANGE SCAN`이 선택됐고, 그 상태에서 `ORDER BY
  claim_id`는 인덱스가 이미 그 순서로 정렬해서 반환하므로 **별도 정렬 단계가 아예
  없음**. 반면 `ORDER BY total_amt`는 여전히 정렬이 필요함(인덱스에 없는 컬럼이므로)

## 07. Tuning — "인덱스 컬럼으로 정렬하면 정렬이 생략된다"는 조건부 사실

- 05·06절을 종합하면: 정렬이 생략되려면 **(1) 정렬 대상 컬럼이 인덱스 컬럼이어야 하고,
  (2) 그 인덱스가 실제로 이 쿼리의 접근 경로로 채택되어야** 한다
- 두 조건 중 하나라도 빠지면(이번 실습에서는 선택도가 높아 인덱스 자체가 채택되지
  않았던 경우) 정렬은 그대로 발생함 — Chapter 4의 "선택도에 따른 접근 방식 전환" 원칙이
  ORDER BY의 정렬 생략 여부에도 그대로 연결됨

## 08. Benchmark

| 시나리오 | Buffers | SORT 발생 여부 |
|---|---:|---|
| GROUP BY 키에 대한 필터(Q1, Q2 — 위치 무관) | 3,090 | HASH GROUP BY는 필연적으로 발생(정렬과 무관) |
| 넓은 범위 ORDER BY (선택도 8.5%, 두 컬럼 모두) | 3,090 | SORT ORDER BY 발생 |
| 좁은 범위 ORDER BY, 인덱스 컬럼(claim_id) | 776 | SORT 생략됨 |
| 좁은 범위 ORDER BY, 비인덱스 컬럼(total_amt) | 717 | SORT ORDER BY 발생 |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch10_문제.md` 참고

## 10. Review

- `WHERE` 조건이 GROUP BY의 기준 컬럼(그룹 키) 자체에 대한 것이라면, SQL에서 그 조건을
  어디에 쓰든 옵티마이저가 그룹화 이전으로 자동으로 밀어넣어줄 수 있음
- `HAVING`(집계 결과에 대한 조건)은 그룹화 이후에만 평가 가능하므로 이 자동 이동이
  적용되지 않음(다만 Chapter 8에서 확인했듯 비용이 항상 더 크지는 않음)
- `ORDER BY` 대상 컬럼이 인덱스 컬럼이라는 것만으로는 정렬이 생략되지 않음 — 그 인덱스가
  실제로 접근 경로로 채택돼야 함(선택도가 충분히 낮아야 함, Chapter 4)
- 같은 컬럼이라도 쿼리의 선택도(필터링되는 비율)에 따라 정렬 생략 여부가 달라질 수 있음
