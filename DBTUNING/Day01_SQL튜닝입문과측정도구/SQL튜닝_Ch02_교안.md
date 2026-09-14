# Chapter 2. SQL은 어떻게 실행되는가?

- 본 차시는 DDL 변경 없음
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: `MEDICAL_CLAIMS`를 `HOSP_ID` 리터럴 값으로 조회하는 동일 SQL을 여러 번 실행하며
  Parse 단계의 동작을 관찰

---

## 01. Why

- 실행계획을 잘 읽어도, SQL이 애초에 "언제 다시 최적화되고 언제 재사용되는지"를 모르면
  실무에서 자주 나오는 성능 문제(공유 풀 부하, 반복적인 하드파싱)를 진단할 수 없음
- 본 차시 목표: SQL 한 문장이 실행되기까지 거치는 단계(Parse/Bind/Execute/Fetch)를
  이해하고, 그 단계 중 어디서 실행계획이 만들어지는지 파악함

## 02. Concept

- SQL 처리 4단계
  - **Parse**: SQL 문법·의미를 검사하고, 이미 같은 SQL이 공유 풀(Shared Pool)에 있는지
    확인. 없으면 옵티마이저가 새로 실행계획을 생성(하드 파싱), 있으면 기존 것을 재사용
    (소프트 파싱)
  - **Bind**: SQL에 바인드 변수(`:b_hosp` 등)가 있으면 실제 값을 대입
  - **Execute**: 만들어진 실행계획대로 실제 데이터를 처리
  - **Fetch**: 처리 결과를 클라이언트로 반환
- 옵티마이저는 Parse 단계에서 동작하며, 그 결과물이 바로 지금까지 다뤄온 실행계획임

## 03. Oracle Internals

- 하드 파싱(Hard Parse): 공유 풀에 동일한 SQL 텍스트가 없어 처음부터 문법 검사·의미
  분석·최적화(실행계획 생성)를 전부 수행하는 것 — 비용이 큼
- 소프트 파싱(Soft Parse): 공유 풀에 동일한 SQL 텍스트가 이미 있어 기존 실행계획을 그대로
  재사용하는 것 — 비용이 작음
- Oracle은 SQL 텍스트를 해시(SQL_ID)로 식별함 — **리터럴 값이 다르면 SQL 텍스트 자체가
  다르므로 SQL_ID도 다르게 부여됨**. 즉 `WHERE hosp_id = 1`과 `WHERE hosp_id = 500`은
  글자 하나만 다른데도 완전히 별개의 SQL로 취급되어 각각 하드 파싱됨
- 바인드 변수(`WHERE hosp_id = :b_hosp`)를 쓰면 값이 바뀌어도 SQL 텍스트는 그대로라 같은
  SQL_ID를 유지하며, 최초 1회 하드 파싱한 실행계획을 재사용할 수 있음

## 04. Example

```sql
-- A. 리터럴 SQL
SELECT COUNT(*) FROM medical_claims WHERE hosp_id = 1;
SELECT COUNT(*) FROM medical_claims WHERE hosp_id = 500;

-- B. 바인드 변수 SQL
VARIABLE b_hosp NUMBER
EXEC :b_hosp := 1
SELECT COUNT(*) FROM medical_claims WHERE hosp_id = :b_hosp;
EXEC :b_hosp := 500
SELECT COUNT(*) FROM medical_claims WHERE hosp_id = :b_hosp;
```

## 05. Execution Plan — 리터럴 값에 따른 실측 비교

**HOSP_ID=1** (SQL_ID `92p460f4hj858`, 대형병원·쏠림 구간)

```text
| Id | Operation         | Name           | E-Rows | A-Rows |   A-Time   | Buffers |
| 2  |  TABLE ACCESS FULL | MEDICAL_CLAIMS |   3039 |   3058 |00:00:01.92 |    3090 |
```

**HOSP_ID=500** (SQL_ID `5awbw1wcprrj2`, 일반 병원)

```text
| Id | Operation         | Name           | E-Rows | A-Rows |   A-Time   | Buffers |
| 2  |  TABLE ACCESS FULL | MEDICAL_CLAIMS |    109 |    177 |00:00:00.01 |    3090 |
```

- 두 SQL은 리터럴 값만 다를 뿐 문장 구조가 완전히 같은데도 **E-Rows가 3039 vs 109로
  실제 차이(3058 vs 177)에 가깝게 다르게 나옴**. 왜 이런 정확한 추정이 가능했는지는
  06절에서 확인함
- Buffers는 3,090으로 둘 다 동일 — `HOSP_ID`에 인덱스가 없어 두 조회 모두 테이블
  전체를 Full Scan하기 때문(어떤 값을 찾든 결국 전체를 다 읽어야 함)

## 06. Bad SQL — 이 챕터에는 해당 사례 없음 (07절로 대체)

이번 챕터의 핵심은 "SQL 자체의 문제"가 아니라 "SQL 처리 방식의 차이"이므로, 06절 대신
07절에서 파싱 관점의 관찰 결과를 다룬다.

## 07. Tuning — SQL_ID로 확인하는 파싱 재사용 여부

**A. 리터럴 SQL 2건의 SQL_ID·실행 통계**

```text
SQL_ID          EXECUTIONS  PARSE_CALLS  SQL_TEXT
5awbw1wcprrj2   1           1            ...WHERE hosp_id = 500
92p460f4hj858   1           1            ...WHERE hosp_id = 1
```

- 리터럴 값이 다른 두 SQL은 **서로 다른 SQL_ID**를 부여받음 — 각각 별도로 파싱·최적화됨
- 만약 이 서비스가 병원 ID별로 계속 다른 리터럴 값을 써서 조회한다면(예: 1,000개 병원
  각각), 공유 풀에 1,000개의 서로 다른 SQL_ID가 쌓이고 그때마다 하드 파싱이 반복됨

**B. 바인드 변수 SQL의 SQL_ID·실행 통계**

```text
SQL_ID          EXECUTIONS  PARSE_CALLS  SQL_TEXT
3zakhp3a1b0ac   2           2            ...WHERE hosp_id = :b_hosp
```

- `:b_hosp`에 1, 500 서로 다른 값을 대입해 두 번 실행했지만 **SQL_ID는 하나**로
  유지됨 — 같은 실행계획을 공유 풀에서 재사용함(EXECUTIONS=2가 이를 보여줌)
- 결론: 애플리케이션에서 매번 값이 바뀌는 조건으로 반복 조회하는 SQL이 있다면, 리터럴로
  직접 값을 넣지 말고 바인드 변수를 쓰는 것이 공유 풀 부담과 하드 파싱 횟수를 줄이는 길임

## 08. Benchmark

| 실행 방식 | SQL_ID 개수(2회 실행 기준) | 파싱 부담 |
|---|---|---|
| 리터럴 SQL (`hosp_id=1`, `hosp_id=500`) | 2개 | 매번 하드 파싱 |
| 바인드 변수 SQL (`:b_hosp`에 1, 500 대입) | 1개 | 최초 1회만 하드 파싱, 이후 재사용 |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch02_문제.md` 참고

## 10. Review

- SQL 처리는 Parse → Bind → Execute → Fetch 순서로 진행되며, 실행계획은 Parse 단계에서
  만들어짐
- 리터럴 값이 다르면 SQL 텍스트가 달라져 별도의 SQL_ID·하드 파싱이 발생함
- 바인드 변수를 쓰면 값이 달라도 같은 SQL_ID를 유지해 실행계획을 재사용함(소프트 파싱)
- `HOSP_ID`처럼 히스토그램이 있는 컬럼은 리터럴 값에 따라 E-Rows가 실제 분포를 반영해
  다르게 나올 수 있음 — 히스토그램의 원리는 Chapter 13에서 다룸
- 바인드 변수가 항상 무조건 유리한 것은 아님 — 히스토그램이 있는 컬럼에서는 바인드
  변수를 쓰면 최초 실행 시의 실행계획이 다른 값에도 그대로 재사용되어 오히려 부정확한
  계획이 반복 적용될 수 있음(바인드 변수 peeking 문제, Chapter 13에서 다룸)
