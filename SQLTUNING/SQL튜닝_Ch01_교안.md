# Chapter 1. SQL 튜닝이란?

- 본 차시는 DDL 변경 없음
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: "주사제 카테고리 약품을 처방받은 청구 찾기"를 IN / EXISTS / JOIN 세 가지 방식으로
  작성해 비교

---

## 01. Why

- "SQL 튜닝"은 문법을 화려하게 쓰는 기술이 아니라, 같은 결과를 내는 여러 방법 중 자원을
  덜 쓰는 방법을 실측 근거로 골라내는 작업임
- 개발자 사이에 퍼진 "이 방식이 항상 더 빠르다"류의 통념이 실제로는 버전·데이터·상황에
  따라 틀리는 경우가 많음 — 06절 실측 사례가 그중 하나
- 본 차시 목표: SQL 성능을 판단하는 기준(자원 관점)과, 판단을 감이 아니라 실측으로 하는
  습관을 세움

## 02. Concept

- SQL 성능: "빠르다/느리다"가 아니라 **얼마만큼의 자원(CPU, I/O, 메모리)을 써서 결과를
  만들었는가**로 정의됨
- 같은 시간이 걸려도 자원 소비량이 다르면 동시 사용자가 많아졌을 때 체감 성능이 달라짐
  — 그래서 단순 "몇 초 걸렸다"보다 자원 소비량(Buffers 등)이 더 안정적인 지표임
- DB 성능 문제의 주요 원인 갈래
  - SQL 자체의 접근 경로 문제 (Full Scan이 불필요하게 발생 등)
  - 인덱스 설계 문제
  - 통계정보·카디널리티 추정 문제
  - 동시성/락 경합 문제 (본 과정 범위 밖)
- SQL 튜닝과 애플리케이션 튜닝의 관계
  - 애플리케이션 코드가 "같은 결과만 나오면 SQL 작성 방식은 상관없다"고 가정하면 안 됨
  - 09절·10절 사례처럼 결과는 완전히 같아도 내부 자원 소비는 최대 몇 배까지 차이 날 수 있음

## 03. Oracle Internals

- CPU 관점: 조건 비교, 정렬, 해시 연산 등 연산량
- I/O 관점: 몇 개의 블록을 읽었는가 — `Buffers`(논리적 I/O)로 확인. 메모리에 없으면
  물리적 I/O(디스크 접근)까지 추가로 발생
- Memory 관점: 해시 조인·정렬 등에 쓰이는 작업 영역(PGA) 크기 — 실행계획의 `OMem`/
  `1Mem`/`Used-Mem` 컬럼으로 확인 가능 (08절 참고)
- 좋은 SQL과 나쁜 SQL의 차이
  - 문법이 짧다고 좋은 SQL이 아니고, 길다고 나쁜 SQL도 아님
  - 실제 접근한 블록 수(Buffers), 사용한 메모리, 실행계획의 오퍼레이션 구성으로 판단해야
    함 — "느낌"이 아니라 실측

## 04. Example — 세 가지 동등 SQL

목표: `MEDICAL_CLAIMS` 중 `CLAIM_DETAILS`에서 `DRUG_MASTER.CATEGORY='주사제'`인 약품을
하나 이상 처방받은 청구 건수 확인. 사전 확인 결과 대상 건수는 79,342건(전체 30만 건의
약 26%).

```sql
-- A. IN 방식
SELECT COUNT(*)
FROM medical_claims
WHERE claim_id IN (
  SELECT cd.claim_id FROM claim_details cd, drug_master dm
  WHERE cd.drug_code = dm.drug_code AND dm.category = '주사제'
);

-- B. EXISTS 방식
SELECT COUNT(*)
FROM medical_claims mc
WHERE EXISTS (
  SELECT 1 FROM claim_details cd, drug_master dm
  WHERE cd.claim_id = mc.claim_id AND cd.drug_code = dm.drug_code AND dm.category = '주사제'
);

-- C. JOIN + DISTINCT 방식
SELECT COUNT(DISTINCT mc.claim_id)
FROM medical_claims mc, claim_details cd, drug_master dm
WHERE mc.claim_id = cd.claim_id AND cd.drug_code = dm.drug_code AND dm.category = '주사제';
```

## 05. Execution Plan — 세 버전 실측 비교

**A. IN 방식** (SQL_ID `cmm0gaqr7whs5`)

```text
| Id | Operation             | Name               | E-Rows | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT      |                    |        |      1 |00:00:03.04 |    8604 |
| 1  |  SORT AGGREGATE       |                    |      1 |      1 |00:00:03.04 |    8604 |
| 2  |   HASH JOIN RIGHT SEMI|                    |   296K |  79342 |00:00:03.03 |    8604 |
| 3  |    VIEW                | VW_NSO_1          |   299K |  90430 |00:00:00.03 |    6713 |
| 4  |     HASH JOIN          |                    |   299K |  90430 |00:00:00.02 |    6713 |
| 5  |      TABLE ACCESS FULL | DRUG_MASTER        |   3333 |   1000 |00:00:00.01 |      91 |
| 6  |      TABLE ACCESS FULL | CLAIM_DETAILS      |   899K |   899K |00:00:00.01 |    6621 |
| 7  |    INDEX FAST FULL SCAN| PK_MEDICAL_CLAIMS  |   300K |   300K |00:00:02.88 |    1891 |
```

**B. EXISTS 방식** (SQL_ID `b0r8p72bjvc2f`) — 구조가 A와 동일, `VIEW` 이름만 `VW_SQ_1`

```text
| Id | Operation             | Name               | E-Rows | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT      |                    |        |      1 |00:00:00.13 |    8604 |
| 1  |  SORT AGGREGATE       |                    |      1 |      1 |00:00:00.13 |    8604 |
| 2  |   HASH JOIN RIGHT SEMI|                    |   296K |  79342 |00:00:00.12 |    8604 |
| 3  |    VIEW                | VW_SQ_1           |   299K |  90430 |00:00:00.04 |    6713 |
| 4  |     HASH JOIN          |                    |   299K |  90430 |00:00:00.03 |    6713 |
| 5  |      TABLE ACCESS FULL | DRUG_MASTER        |   3333 |   1000 |00:00:00.01 |      91 |
| 6  |      TABLE ACCESS FULL | CLAIM_DETAILS      |   899K |   899K |00:00:00.02 |    6621 |
| 7  |    INDEX FAST FULL SCAN| PK_MEDICAL_CLAIMS  |   300K |   300K |00:00:00.02 |    1891 |
```

**C. JOIN + DISTINCT 방식** (SQL_ID `a3nqx088zkzhq`)

```text
| Id | Operation           | Name          | E-Rows | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT    |               |        |      1 |00:00:00.04 |    6713 |
| 1  |  SORT AGGREGATE     |               |      1 |      1 |00:00:00.04 |    6713 |
| 2  |   VIEW               | VW_DAG_0     |   296K |  79342 |00:00:00.04 |    6713 |
| 3  |    HASH GROUP BY     |               |   296K |  79342 |00:00:00.04 |    6713 |
| 4  |     HASH JOIN        |               |   299K |  90430 |00:00:00.03 |    6713 |
| 5  |      TABLE ACCESS FULL| DRUG_MASTER  |   3333 |   1000 |00:00:00.01 |      91 |
| 6  |      TABLE ACCESS FULL| CLAIM_DETAILS|   899K |   899K |00:00:00.02 |    6621 |
```

- C 버전 실행계획에는 `MEDICAL_CLAIMS`나 `PK_MEDICAL_CLAIMS`에 대한 접근이 전혀 없음 —
  `FROM` 절에 `medical_claims mc`가 분명히 있는데도 실행계획에 나타나지 않음. 상세 원인은
  09절에서 다룸

## 06. Bad SQL — "EXISTS가 IN보다 빠르다"는 통념 검증

- A(IN)와 B(EXISTS)의 실행계획은 `VIEW` 이름(`VW_NSO_1` vs `VW_SQ_1`)만 다를 뿐 오퍼레이션
  구성이 완전히 동일함 — Oracle 옵티마이저가 IN 서브쿼리와 EXISTS 서브쿼리를 **같은
  세미조인(HASH JOIN RIGHT SEMI) 형태로 변환**했기 때문
- 그런데 A-Time은 A가 3.04초, B가 0.13초로 크게 다름. Buffers는 둘 다 8,604로 동일
  - Buffers(논리적 I/O)가 같은데 시간이 다른 것은 **물리적 I/O(디스크 접근) 여부** 때문일
    가능성이 큼 — A를 먼저 실행해 디스크에서 블록을 읽어 캐시에 올렸고, B는 그 직후
    실행되어 이미 캐시에 있는 블록을 그대로 재사용했을 가능성이 높음
  - 특히 A의 7번 단계(`INDEX FAST FULL SCAN`, `PK_MEDICAL_CLAIMS`)만 유독 2.88초가
    걸렸고 B의 동일 단계는 0.02초임 — 같은 오퍼레이션인데 시간 차이가 집중된 지점이 정확히
    "처음 읽는 블록"에 해당하는 부분과 일치함
- 결론: 이번 실측에서 "EXISTS가 IN보다 빠르다"는 차이는 **EXISTS와 IN의 구조적 차이가
  아니라 캐시 상태(먼저 실행됐는지 나중에 실행됐는지)에서 비롯됨**. 실행계획 구조 자체는
  동일했음
- 실무 교훈: "A가 B보다 빠르다"는 통념을 실행 순서 통제 없이 한 번 측정한 결과만으로
  단정하면 안 됨. 최소한 Buffers처럼 캐시 상태에 덜 흔들리는 지표를 같이 봐야 함

## 07. Tuning (예고)

- C(JOIN+DISTINCT) 버전이 `MEDICAL_CLAIMS` 접근 자체를 생략해 Buffers가 가장 적음
  (6,713 vs 8,604) — 왜 이런 실행계획이 나오는지(조인 제거)는 Chapter 7(JOIN 실행 원리)
  에서 다룸
- 바인드 변수 사용 여부, 인덱스 설계 등 본격적인 개선 기법은 이후 챕터에서 순서대로 다룸.
  본 차시는 "판단 기준을 세우는 것"까지가 범위

## 08. Benchmark — 자원 관점 종합 비교

| 버전 | Buffers | A-Time | Memory(Used-Mem, 최대) | 비고 |
|---|---:|---|---|---|
| A. IN | 8,604 | 3.04초 | 6,694K | EXISTS와 구조 동일, 캐시 미보유 상태에서 측정 |
| B. EXISTS | 8,604 | 0.13초 | 6,694K | IN과 구조 동일, 캐시 보유 상태에서 측정 |
| C. JOIN+DISTINCT | 6,713 | 0.04초 | 12M(HASH GROUP BY) | MEDICAL_CLAIMS 접근 자체가 없음 |

- Buffers만 보면 C가 가장 적고, A·B는 동일함
- Memory는 C가 `HASH GROUP BY` 때문에 오히려 더 큰 작업 영역(12M)을 씀 — "Buffers가 적은
  게 항상 전방위로 유리하다"는 뜻은 아니며, 어떤 자원을 절약하는지 구분해서 봐야 함

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch01_문제.md` 참고

## 10. Review

- SQL 성능은 "몇 초"가 아니라 자원(CPU/I/O/Memory) 소비량으로 판단함
- Buffers가 같아도 A-Time이 다를 수 있음 — 캐시 상태(물리 I/O 여부)를 의심해야 함
- "이 방식이 항상 빠르다"는 통념은 실측 없이 신뢰하면 안 됨 — 이번 사례에서 IN과 EXISTS는
  실행계획이 동일했고 체감 속도 차이는 다른 요인(캐시)에서 비롯됨
- 같은 FROM 절이라도 옵티마이저가 불필요한 테이블 접근을 제거할 수 있음(C 버전) — 상세
  원리는 Chapter 7에서 다룸
- 자원 절약은 다차원적임 — Buffers를 아꼈다고 Memory도 함께 아꼈다는 보장은 없음
