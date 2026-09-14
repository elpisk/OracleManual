# Chapter 3. 실행계획 기초 — 실습문제 10제

`SQL튜닝_Ch03_교안.md`을 먼저 읽고 푸시기 바랍니다. 모든 실행계획은 실습 DB에서
`DBMS_XPLAN.DISPLAY` / `DBMS_XPLAN.DISPLAY_CURSOR(... 'ALLSTATS LAST')`로 실측한 결과입니다.
이번 챕터는 인덱스를 만들거나 지우지 않습니다 — 기존 PK 인덱스만으로 풀 수 있습니다.

---

**1. [상]** 다음은 `MEDICAL_CLAIMS`에서 `CLAIM_TYPE='입원' AND TOTAL_AMT>500000` 조건으로
조회했을 때의 실행계획이다.

```text
| Id | Operation         | Name           | Rows  | Bytes | Cost (%CPU)| Time     |
| 0  | SELECT STATEMENT  |                | 77946 |  2207K|   857   (1)| 00:00:01 |
| 1  | TABLE ACCESS FULL | MEDICAL_CLAIMS | 77946 |  2207K|   857   (1)| 00:00:01 |

Predicate Information (identified by operation id):
   1 - filter("CLAIM_TYPE"='입원' AND "TOTAL_AMT">500000)
```

`TABLE ACCESS FULL`이 발생한 이유를 `Predicate Information`의 `filter` 키워드와 연결지어
설명하시오. 만약 `CLAIM_TYPE`이나 `TOTAL_AMT`에 인덱스가 있었다면 이 `filter` 조건이
`access` 조건으로 바뀔 수 있었을지도 함께 논하시오.

**2. [상]** 위 1번과 동일한 SQL을 실제로 실행하고 `DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL,
'ALLSTATS LAST')`로 확인하면 `E-Rows 77946`, `A-Rows 411`이 나온다. 이 두 수치가 각각
무엇을 의미하는지, 그리고 이렇게 큰 차이가 나는 것이 왜 문제가 될 수 있는지(옵티마이저의
후속 판단에 미치는 영향 관점에서) 설명하시오.

**3. [상]** 다음은 `WHERE claim_id = '20240615-0013440'`(PK 등치 조건)의 실행계획이다.

```text
| Id | Operation                 | Name              | Starts | E-Rows | A-Rows | Buffers |
| 0  | SELECT STATEMENT          |                   |      1 |        |      1 |       4 |
| 1  |  TABLE ACCESS BY INDEX ROWID | MEDICAL_CLAIMS |      1 |      1 |      1 |       4 |
| 2  |   INDEX UNIQUE SCAN       | PK_MEDICAL_CLAIMS |      1 |      1 |      1 |       3 |

Predicate Information:
   2 - access("CLAIM_ID"='20240615-0013440')
```

이 실행계획의 실행 순서를 Id 2 → 1 → 0 순서로 설명하고, 왜 `INDEX UNIQUE SCAN` 하나만으로는
결과가 끝나지 않고 `TABLE ACCESS BY INDEX ROWID`가 한 단계 더 필요한지 설명하시오.

**4. [상]** 다음은 `WHERE pat_id BETWEEN 100 AND 130`(PK 범위 조건, `PATIENTS`)의 실행계획이다.

```text
| Id | Operation                          | Name        | Starts | E-Rows | A-Rows | Buffers |
| 0  | SELECT STATEMENT                   |             |      1 |        |     31 |       9 |
| 1  |  TABLE ACCESS BY INDEX ROWID BATCHED| PATIENTS   |      1 |     32 |     31 |       9 |
| 2  |   INDEX RANGE SCAN                 | PK_PATIENTS |      1 |     32 |     31 |       5 |

Predicate Information:
   2 - access("PAT_ID">=100 AND "PAT_ID"<=130)
```

3번 문항(`INDEX UNIQUE SCAN`)과 이 문항(`INDEX RANGE SCAN`)의 차이를 설명하시오. 같은 PK
인덱스인데 왜 오퍼레이션 이름이 다른가? `TABLE ACCESS BY INDEX ROWID BATCHED`처럼 `BATCHED`가
붙은 것은 3번 문항의 (`BATCHED`가 없는) `TABLE ACCESS BY INDEX ROWID`와 어떤 차이가 있을지
추론해보시오.

**5. [최상]** 다음은 `SELECT claim_id FROM medical_claims ORDER BY claim_id FETCH FIRST 5
ROWS ONLY`를 `INDEX(medical_claims PK_MEDICAL_CLAIMS)` 힌트로 실행한 결과다.

```text
| Id | Operation             | Name               | Starts | E-Rows | A-Rows | Buffers |
| 0  | SELECT STATEMENT      |                    |      1 |        |      5 |       4 |
| 1  |  VIEW                 |                    |      1 |      5 |      5 |       4 |
| 2  |   WINDOW NOSORT STOPKEY|                   |      1 |      5 |      5 |       4 |
| 3  |    INDEX FULL SCAN    | PK_MEDICAL_CLAIMS  |      1 |      5 |      5 |       4 |

Predicate Information:
   1 - filter("from$_subquery$_002"."rowlimit_$$_rownumber"<=5)
   2 - filter(ROW_NUMBER() OVER ( ORDER BY "CLAIM_ID")<=5)
```

`SORT` 오퍼레이션이 이 실행계획 어디에도 없다. `ORDER BY`가 있는데 왜 별도의 정렬 작업이
필요 없었는지, `WINDOW NOSORT STOPKEY`라는 오퍼레이션 이름 자체에서 힌트를 찾아 설명하시오.

**6. [상]** 다음은 `SELECT COUNT(claim_id) FROM medical_claims`의 실행계획이다.

```text
| Id | Operation             | Name               | Starts | E-Rows | A-Rows | Buffers |
| 0  | SELECT STATEMENT      |                    |      1 |        |      1 |    1891 |
| 1  |  SORT AGGREGATE       |                    |      1 |      1 |      1 |    1891 |
| 2  |   INDEX FAST FULL SCAN| PK_MEDICAL_CLAIMS  |      1 |   300K |   300K |    1891 |
```

이 쿼리는 `MEDICAL_CLAIMS` 테이블을 전혀 건드리지 않고 인덱스만 읽어서 결과를 낸다. 왜
그것이 가능한지(`CLAIM_ID` 컬럼의 제약조건과 연결지어) 설명하고, `INDEX FAST FULL SCAN`이
`INDEX FULL SCAN`(5번 문항)과 무엇이 다를지 — 왜 이 경우엔 "정렬된 순서로 읽을 필요"가
없는지 — 추론하시오.

**7. [최상]** 다음은 `HOSPITALS`(HOSP_ID≤10)와 `MEDICAL_CLAIMS`를 조인해 병원 유형별로 집계한
실행계획이다.

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

이 실행계획이 실제로 실행되는 순서를 Id 번호가 아니라 **실행되는 순서 그대로** 나열하시오
(힌트: 들여쓰기가 가장 깊은 것부터). 그리고 `HASH JOIN`의 두 입력 중 어느 쪽이 먼저 만들어져
"빌드(build)" 역할을 하고, 어느 쪽이 그 결과에 "탐침(probe)"되는 큰 테이블 역할을 하는지
Rows 컬럼의 값(10 vs 29,631)을 근거로 판단하시오.

**8. [상]** 7번 문항의 `Predicate Information`을 보면 `HOSP_ID<=10`이라는 같은 조건이 Id 4
에서는 `access`로, Id 5에서는 `filter`로 서로 다르게 나타난다. 왜 같은 조건이 한쪽 테이블
(`HOSPITALS`)에서는 인덱스를 "찾아가는" 데 쓰이고, 다른 쪽 테이블(`MEDICAL_CLAIMS`)에서는
가져온 후에 "걸러내는" 데만 쓰이는지 설명하시오. (힌트: `MEDICAL_CLAIMS`의 `HOSP_ID`에
인덱스가 있는가?)

**9. [상]** 1번 문항(Cost 857)과 7번 문항(Cost 860)은 서로 다른 SQL이지만 Cost 값이 비슷하다.
"Cost가 비슷하니 두 SQL의 실행 시간도 비슷할 것이다"라는 주장이 왜 틀렸는지, Cost라는 지표의
정의(교안 05절)를 근거로 반박하시오.

**10. [최상]** 이 문제지의 6개 시나리오(1~9번 문항의 소재) 중에서, "지금 당장은 문제없어
보이지만 데이터가 훨씬 커지면(예: `MEDICAL_CLAIMS`가 300만 건으로 늘어나면) 성능이 급격히
나빠질 가능성이 있는" 시나리오를 하나 이상 골라 그 이유를 설명하시오. (이 챕터에서는 실제로
고치지 않아도 된다 — Chapter 5·7에서 다룰 내용을 미리 예측해보는 것이 목표다.)
