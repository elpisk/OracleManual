# Chapter 3. 실행계획 기초

- 본 차시는 인덱스를 신규 생성하지 않음
- 기존 PK 인덱스(HOSPITALS, PATIENTS, MEDICAL_CLAIMS 등)만으로 실습 진행
- 아래 예제는 전부 실습 DB 실측 결과

---

## 01. Why

- SQL이 느린 이유는 실행계획을 확인해야 파악 가능함
  - "느린 것 같다"는 체감만으로는 원인 특정 불가 — Full Scan 때문인지, 잘못된 조인
    순서 때문인지, 통계정보 부정확 때문인지는 실행계획을 봐야 구분됨
- 동일한 결과를 내는 SQL이라도 Oracle의 처리 방식(Full Scan, Index Scan, 조인 방식 등)은
  SQL 문장만으로는 판단 불가
  - 옵티마이저가 상황(데이터 분포, 통계정보, 인덱스 존재 여부)에 따라 매번 다른 방법을
    선택할 수 있기 때문
- 본 차시 범위: 튜닝이 아니라 실행계획 판독
  - 인덱스 설계·SQL 재작성 같은 실제 개선 조치는 다루지 않음
  - 이후 모든 챕터에서 "이 방법이 왜 더 나은지"를 실행계획으로 증명해야 하므로, 판독
    능력이 전제 조건임

## 02. Concept

- 실행계획: 옵티마이저가 SQL을 처리할 절차를 트리 구조로 표현한 것
- 트리의 각 노드(Operation)는 물리적 작업 단위 하나에 대응
  - 예: "테이블 전체를 처음부터 끝까지 읽는다"(TABLE ACCESS FULL), "인덱스에서 특정
    값을 찾는다"(INDEX SCAN 계열), "두 결과 집합을 합친다"(JOIN 계열)
- SQL 한 문장이 여러 개의 물리적 작업으로 분해되어 실행되며, 그 분해·조합 순서가 트리
  구조로 나타남

## 03. Oracle Internals

- 옵티마이저(CBO, Cost-Based Optimizer): 동일 SQL을 처리할 수 있는 여러 후보 실행 방법
  중, 예상 비용(Cost)이 가장 낮은 것을 선택
- Cost 계산에 사용되는 통계정보: 테이블 행 수, 각 컬럼의 고유값 개수(NDV), 데이터 분포
  (히스토그램 존재 여부), 인덱스 클러스터링 팩터 등
- 통계정보와 실제 데이터 분포가 어긋나는 대표 원인
  - 통계 미갱신(오래된 통계) — 데이터는 늘었는데 통계는 예전 그대로인 경우
  - 컬럼 간 상관관계 미반영 — 기본적으로 옵티마이저는 두 컬럼 조건을 독립으로 가정하고
    선택도를 곱해서 추정함 (06절 실측 사례가 이 경우)
  - 데이터 쏠림(skew)에 히스토그램이 없는 경우 — 평균 분포로 잘못 가정
- 위 원인 중 하나라도 해당되면 최적이 아닌 계획이 선택될 수 있음 (카디널리티 추정 오류).
  상세 대응은 Chapter 13에서 다룸

## 04. Example

```sql
SELECT claim_id, total_amt
FROM medical_claims
WHERE claim_type = '입원' AND total_amt > 500000;
```

- `EXPLAIN PLAN FOR ...` 실행: SQL을 실제로 실행하지 않고 옵티마이저의 예상 계획만 산출
- 이어서 `SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(...))`로 결과 조회

```text
| Id | Operation         | Name           | Rows  | Bytes | Cost (%CPU)| Time     |
| 0  | SELECT STATEMENT  |                | 77946 |  2207K|   857   (1)| 00:00:01 |
| 1  | TABLE ACCESS FULL | MEDICAL_CLAIMS | 77946 |  2207K|   857   (1)| 00:00:01 |

Predicate Information (identified by operation id):
   1 - filter("CLAIM_TYPE"='입원' AND "TOTAL_AMT">500000)
```

## 05. Execution Plan — 컬럼별 판독 기준

- **Id**: 트리 노드 번호. 생성 순서일 뿐 실행 순서가 아님 (실행 순서는 05절 하단 별도 원칙 참고)
- **Operation / Options**: 해당 단계가 수행하는 물리적 작업명
- **Name**: 작업 대상 오브젝트명(테이블 또는 인덱스)
- **Rows / Bytes**: 옵티마이저가 예상한 결과 건수·데이터 크기. 실행 전 추정치이며 통계정보
  기반으로 계산됨
- **Cost**: 동일 SQL 안에서 여러 실행 방법 후보를 비교하기 위해 옵티마이저가 내부적으로
  쓰는 상대 지표
  - 초 단위 실행 시간이 아님 — CPU 연산량과 I/O 예상 횟수를 옵티마이저 자체 공식으로
    환산한 무차원 수치
  - 서로 다른 SQL 두 개의 Cost를 나란히 놓고 "이게 더 작으니까 더 빠르다"고 판단하면
    틀림 — 비교는 같은 SQL의 대안 계획들 사이에서만 유효함 (문제지 9번 문항 참고)
- **Predicate Information**: 각 오퍼레이션 단계에서 실제로 적용된 조건
  - `access`: 인덱스나 조인 상대를 "찾아가는 데" 쓰인 조건. 이 조건에 해당 컬럼의
    인덱스가 있어야 발생 가능
  - `filter`: 이미 읽어온 행들 중에서 "걸러내는 데만" 쓰인 조건. 인덱스 유무와 무관하게
    항상 발생 가능
  - 둘의 구분으로 "이 조건이 실제로 인덱스를 활용하고 있는지"를 판별할 수 있음 — 같은
    조건이라도 컬럼에 인덱스가 없으면 `access`가 아니라 `filter`로만 나타남 (문제지 8번
    문항 참고)
- 실행 순서 판독 원칙: 트리에서 들여쓰기가 가장 깊은 노드부터 먼저 실행되고, 같은
  들여쓰기 레벨에서는 아래쪽이 먼저 실행됨. 그 결과가 위쪽/바깥쪽 노드로 전달되어 조합됨.
  Id 번호 순서(0→1→2)대로 읽으면 실제 실행 순서와 반대로 읽게 되므로 주의 필요

## 06. Bad SQL — 카디널리티 추정 오류 사례

04절 SQL을 실제 실행한 뒤 `DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST')`로
확인:

```text
| Id | Operation         | Name           | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT  |                |      1 |        |    411 |00:00:00.02 |    3117 |
| 1  | TABLE ACCESS FULL | MEDICAL_CLAIMS |      1 |  77946 |    411 |00:00:00.02 |    3117 |
```

- E-Rows(실행 전 예상) 77,946건 vs A-Rows(실제 실행 결과) 411건 — 약 190배 차이
- 발생 원인
  - 옵티마이저는 `CLAIM_TYPE='입원'`의 선택도와 `TOTAL_AMT>500000`의 선택도를 각각
    독립적으로 계산한 뒤 서로 곱해서 전체 조건의 선택도를 추정함
  - 그러나 실제 데이터에서는 두 조건이 서로 무관하지 않을 수 있음 — 예를 들어 입원
    진료가 외래보다 평균 진료비가 높은 경향이 있다면, "입원"과 "고액"이라는 두 조건은
    독립이 아니라 서로 겹치는 방향으로 상관되어 있어, 실제로 두 조건을 동시에 만족하는
    행이 "독립 가정하의 곱셈 추정치"보다 적어질 수 있음 (반대로 많아지는 경우도 있음)
  - 이런 상관관계를 옵티마이저가 자동으로 알아채지는 못함 — 별도로 확장 통계(extended
    statistics)를 만들어주지 않는 한 항상 독립 가정으로 계산함
- 결과적 위험: 이 SQL이 더 큰 쿼리의 일부(서브쿼리, 조인의 한쪽)였다면, 잘못된 77,946
  이라는 예상치를 근거로 조인 순서나 조인 방식까지 잘못 결정될 수 있음 — 추정 오류는
  그 자리에서 끝나지 않고 후속 판단으로 전파됨
- 상세 대응(히스토그램, 확장 통계 생성 등): Chapter 13(Optimizer와 통계정보)에서 다룸
- 실무 판독 원칙: E-Rows와 A-Rows 차이가 크면(수십 배 이상) 카디널리티 추정 오류를 의심함

## 07. Tuning (예고 — 본 차시에서는 미해결)

- 이 SQL이 Full Scan인 이유: `CLAIM_TYPE`, `TOTAL_AMT` 두 컬럼 모두 인덱스 없음
- 인덱스를 만들면 해결되는지, 어떤 인덱스가 적합한지는 Chapter 5(인덱스 설계)의 범위
- 본 차시에서 다루지 않는 이유: 지금 인덱스부터 만들면 "왜 그 인덱스를 선택했는지"를
  판단할 기준(선택도, 컬럼 순서)이 아직 없는 상태이기 때문 — 판독을 먼저 확립한 뒤
  설계로 넘어가는 순서를 따름

## 08. Benchmark — 주요 Operation 6종 비교

DDL 변경 없이 기존 PK 인덱스만으로 관찰한 6개 패턴:

| # | 쿼리 | 핵심 Operation | Buffers | 비고 |
|---|---|---|---:|---|
| Q1 | `claim_type=.. AND total_amt>..` (비인덱스 컬럼) | TABLE ACCESS FULL | 3,117 | E-Rows/A-Rows 190배 차이 |
| Q2 | `claim_id = '...'` (PK 등치) | INDEX UNIQUE SCAN → TABLE ACCESS BY INDEX ROWID | 4 | 추정치 정확 |
| Q3 | `pat_id BETWEEN 100 AND 130` (PK 범위) | INDEX RANGE SCAN → ...BATCHED | 9 | 등치 아닌 범위 조건이라 순회 |
| Q4 | `ORDER BY claim_id FETCH FIRST 5 ROWS` (힌트로 INDEX FULL SCAN 강제) | WINDOW NOSORT STOPKEY + INDEX FULL SCAN | 4 | 인덱스 정렬 순서 재활용, SORT 생략 |
| Q5 | `COUNT(claim_id)` | SORT AGGREGATE + INDEX FAST FULL SCAN | 1,891 | 테이블 미접근, 인덱스만으로 집계 |
| Q6 | HOSPITALS+MEDICAL_CLAIMS 조인 + GROUP BY | HASH GROUP BY + HASH JOIN | 3,093 | 여러 Operation 혼합, 실전형 |

패턴 해석:
- Q2(단건)와 Q3(범위)는 같은 PK 인덱스를 쓰지만 조건 성격(등치 vs 범위)에 따라 오퍼레이션
  이름이 갈림 — 등치는 결과가 최대 1건임이 보장되므로 UNIQUE SCAN, 범위는 여러 건일 수
  있어 인덱스를 순회하는 RANGE SCAN
- Q4·Q5는 둘 다 테이블 접근(TABLE ACCESS)이 생략되거나 최소화된 경우 — Q4는 SELECT 절이
  인덱스 컬럼(claim_id)만 요구해서 정렬까지 인덱스로 해결했고, Q5는 COUNT라는 집계
  특성상 정렬조차 필요 없어 더 빠른 FAST FULL SCAN이 선택됨
- Q6은 앞의 다섯 패턴이 섞여 나타나는 실전형 사례 — 작은 테이블(HOSPITALS)은 인덱스로,
  큰 테이블(MEDICAL_CLAIMS)은 인덱스가 없어 Full Scan으로 처리된 뒤 HASH JOIN으로 결합됨

Q6 전체 실행계획 (문제지 7번 문항 소재):

```text
| Id | Operation                          | Name           | Rows  | Bytes | Cost(%CPU)|
| 0  | SELECT STATEMENT                   |                |     4 |    84 |   860  (1)|
| 1  |  HASH GROUP BY                     |                |     4 |    84 |   860  (1)|
| 2  |   HASH JOIN                        |                |   297 |  6237 |   859  (1)|
| 3  |    TABLE ACCESS BY INDEX ROWID BATCHED| HOSPITALS   |    10 |   120 |     3  (0)|
| 4  |     INDEX RANGE SCAN               | PK_HOSPITALS   |    10 |       |     2  (0)|
| 5  |    TABLE ACCESS FULL               | MEDICAL_CLAIMS | 29631 |   260K|   855  (1)|

Predicate Information:
   2 - access("H"."HOSP_ID"="M"."HOSP_ID")
   4 - access("H"."HOSP_ID"<=10)
   5 - filter("M"."HOSP_ID"<=10)
```

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch03_문제.md` 참고
- 문항 구성: 판독 기본기(1~4번) → 심화 판독(5~8번) → 종합 적용(9~10번)

## 10. Review

- 실행 순서: 들여쓰기 깊은 것부터, 동일 레벨이면 아래쪽부터. Id 순서 아님
- Rows/Cost/Bytes = 실행 전 추정치, A-Rows/Buffers/A-Time = 실제 실행 후 통계 —
  `EXPLAIN PLAN`과 `DBMS_XPLAN.DISPLAY_CURSOR(...'ALLSTATS LAST')`로 각각 확인
- `access` = 인덱스·조인을 찾아가는 조건, `filter` = 가져온 뒤 걸러내는 조건 — 같은
  조건이라도 인덱스 유무에 따라 둘 중 하나로 갈림
- 동일 PK 인덱스라도 조건 성격(등치/범위/정렬활용/집계)에 따라 UNIQUE/RANGE/FULL/
  FAST FULL SCAN으로 구분됨
- E-Rows와 A-Rows 차이가 크면 카디널리티 추정 오류를 의심함 — 원인은 대부분 컬럼 간
  상관관계 미반영, 히스토그램 부재, 통계 미갱신 중 하나 (Chapter 13에서 상세 대응)
