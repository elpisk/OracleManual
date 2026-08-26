# Oracle SQL 튜닝 실전 과정 — 최종 종합 실습 테스트 해설

`SQL튜닝_최종테스트_문제.md`와 번호가 1:1로 대응합니다. 모든 수치는 이 해설을 작성하며
실습 DB(SQLT 계정)에서 실제로 실행해 얻은 결과입니다. 채점 시 아래 수치와 정확히
같지 않아도, 같은 방향·같은 원리로 측정·해석했다면 정답으로 인정하십시오(데이터가
`DBMS_RANDOM` 기반이라 정확한 건수는 재현할 때마다 조금씩 다를 수 있으나, 스키마 자체는
고정 데이터라 실제로는 거의 동일한 값이 나옵니다).

---

## I. SQL 튜닝 기초 · SQL 처리 과정 (1~10번)

**1.** `CATEGORY='처치'` 처방 청구(182,860건)를 IN/EXISTS/JOIN 세 방식으로 실행한 결과:

| 방식 | Buffers | 비고 |
|---|---:|---|
| IN | 8,604 | `HASH JOIN RIGHT SEMI` + `VW_NSO_1` |
| EXISTS | 8,604 | `HASH JOIN RIGHT SEMI` + `VW_SQ_1`, IN과 오퍼레이션 완전 동일 |
| JOIN+`COUNT(DISTINCT)` | 6,713 | `VW_DAG_0`, `MEDICAL_CLAIMS` 접근 없음 |

주사제(Chapter 1)든 처치(이번 실습)든 같은 패턴이 재현됩니다.

**2.** 처음 실행한 IN 버전은 `Reads=8,586`(콜드), A-Time 6.60초. 바로 이어 실행한 EXISTS
버전은 Reads가 0으로 표시(웜), A-Time 0.16초. 순서를 바꿔도 "먼저 실행되는 쪽이 콜드"라는
관계 자체는 유지됩니다 — Chapter 1·14의 원리가 실행 순서와 무관하게 성립함을 확인할 수
있습니다.

**3.** 두 실행계획은 `VIEW` 이름(`VW_NSO_1`/`VW_SQ_1`)만 다르고 `HASH JOIN RIGHT SEMI`
이하 구조가 완전히 동일합니다 — Predicate Information도 `access`/`filter` 위치까지 같습니다.

**4.** `WHERE pat_id = 100`과 `WHERE pat_id = '100'`은 `V$SQL`에서 각각
`bcaq8bvfwypfw`, `6gf8yr1yv9j1a`로 **서로 다른 SQL_ID**를 받았습니다. `PAT_ID`는
`NUMBER` 컬럼이므로 이번엔 리터럴(`'100'`, 문자열)이 컬럼 타입에 맞춰 변환되는 구조였을
가능성이 높습니다(Chapter 6의 "VARCHAR2 컬럼+NUMBER 리터럴"과 반대 방향) — 다만 SQL_ID가
다른 것 자체는 텍스트가 다르기 때문이며 변환 방향과 무관하게 항상 성립합니다.

**5.** `VARIABLE b1 NUMBER`로 100, 200을 대입해 두 번 실행한 결과 `V$SQL`에서 SQL_ID
`bx05cxywby808` 하나에 `EXECUTIONS=2`로 확인됐습니다 — Chapter 2의 바인드 변수 재사용
원리가 그대로 재현됩니다.

**6.** `DISEASES`-`MEDICAL_CLAIMS`-`PATIENTS` 3-way 조인(`ROWNUM<=20`)의 실행계획에는
`MEDICAL_CLAIMS`에 대한 `TABLE ACCESS BY INDEX ROWID`+`INDEX UNIQUE SCAN`이 **그대로
나타났습니다**(Buffers 111 전체 중 일부). Chapter 1의 조인 제거(Q1C)와 다른 점은, 이번
쿼리는 `p.pat_name`(즉 `PATIENTS`의 컬럼)이 필요하고 그 값을 얻으려면 `mc.pat_id`를
거쳐야 하는데, `mc.pat_id`는 `DISEASES`나 조인 키만으로는 대체할 수 없는 **별도 컬럼**
이기 때문에 조인 제거가 적용되지 않았습니다 — "조인 키 컬럼 자체만 필요할 때"와 "그
테이블의 다른 컬럼이 필요할 때"의 차이를 보여주는 좋은 대조 사례입니다.

**7.** `SELECT *`는 Bytes=10,000, 필요한 컬럼만 선택하면 Bytes=4,200으로 실측됐습니다
(Cost는 둘 다 4로 동일). 컬럼을 줄이면 옵티마이저의 데이터量 추정치가 실제로 줄어든다는
것이 확인됩니다.

**8.** 예시(`WHERE qty>=3` on CLAIM_DETAILS): EXPLAIN PLAN 기준 Rows=299K, Cost=1816;
실측 기준 Buffers=6,621. 두 지표 체계가 다른 것을 하나의 표로 정리하면 됩니다(임의의 다른
SQL을 골랐다면 그 SQL의 실제 수치를 쓰면 됩니다).

**9.** distinct 5개(`hosp_id<=5`)일 때 `Starts=5`, Buffers=4,081. distinct 200개
(`hosp_id<=200`)일 때 `Starts=11,293`(!), Buffers=14,539. 단순히 distinct 개수만큼만
실행될 것이라는 예상과 달리 200개에서는 distinct 값보다 훨씬 많이 실행됐습니다 — 스칼라
서브쿼리 캐시에 **용량 한계**가 있어, distinct 값이 많아지면 캐시가 다 담지 못하고 일부
값이 밀려나 재실행되는 것으로 해석됩니다.

**10.** (예시 답안) 9번 문항 자체가 좋은 사례입니다 — "distinct 값 개수만큼만 캐싱될
것"이라는 예상과 달리 실제로는 `Starts=11,293`으로 훨씬 많이 나와, 캐시 용량 한계라는
예상 밖의 현상을 발견했습니다.

## II. 실행계획 판독 · 성능 측정 (11~20번)

**11.** `WHERE qty>=3` EXPLAIN PLAN: `TABLE ACCESS FULL(CLAIM_DETAILS)`, Rows=299K,
Bytes=13M, Cost=1816, Predicate `filter("QTY">=3)`.

**12.** 실제 실행 결과 A-Rows=298,457, E-Rows(=Rows 추정치와 사실상 동일 개념)=299K로
거의 정확히 일치(오차 0.2% 미만) — `QTY`는 1~3 균등분포로 생성된 컬럼이라 히스토그램
없이도 균등가정이 실제와 잘 맞는 사례입니다.

**13.** 예시(`HOSPITALS`-`PATIENTS`, `city` 조인): 실행계획은
`HASH JOIN`(Id2) ← `TABLE ACCESS BY INDEX ROWID BATCHED/INDEX RANGE SCAN`(Id3-4,
HOSPITALS) + `TABLE ACCESS FULL`(Id5, PATIENTS). 실행 순서: **4→3→5→2→(SORT
AGGREGATE)→(SELECT STATEMENT)**.

**14.** `PAT_ID=12345`(등치): `INDEX UNIQUE SCAN`, Buffers 3. `PAT_ID BETWEEN 12000
AND 12100`(범위): `INDEX RANGE SCAN...BATCHED`, Buffers 18. `ORDER BY pat_id FETCH
FIRST 5`: `WINDOW NOSORT STOPKEY`+`INDEX FULL SCAN`, Buffers 3.

**15.** 예시: `PATIENTS`(city='서울') Cost=136 vs `DRUG_MASTER`(category='내복약')
Cost=25. 서로 다른 테이블·조건이라 Cost를 직접 비교하는 것 자체가 무의미함을 보여주는
사례로 제시하면 됩니다(A-Time으로 실제 비교해야 함).

**16.** 같은 좁은 범위(claim_id 1일치) 쿼리를 두 번 연속 실행한 결과 **두 번 다 Buffers
8, A-Time 0.01초로 동일**했습니다 — 이 경우 콜드/웜 차이가 관측되지 않았는데, 이는 해당
블록들이 이전 문항들의 반복 실습으로 이미 버퍼 캐시에 계속 남아있었을 가능성이 높습니다.
"항상 콜드/웜 차이가 관측되는 것은 아니며, 캐시 상태는 그 세션·그 서버의 최근 이력에
좌우된다"는 점을 정직하게 확인할 수 있는 결과입니다(Chapter 14 실습처럼 `ALTER SYSTEM
FLUSH BUFFER_CACHE`로 강제 콜드 상태를 만들어야 차이를 확실히 재현할 수 있습니다).

**17.** `COUNT(*)`만: Buffers 91. `SELECT *`(인라인 뷰로 COUNT 감쌈): Buffers 91,
**완전히 동일**했습니다 — `COUNT(*)`가 외부에 있으면 내부 `SELECT *`의 개별 컬럼이
실제로는 필요 없어 옵티마이저가 불필요한 컬럼 처리를 생략해준 것으로 해석됩니다.

**18.** `claim_id` 하루치 범위 + `ORDER BY claim_id FETCH FIRST 10`: `WINDOW NOSORT
STOPKEY`+`INDEX RANGE SCAN`, Buffers 4로 재현 성공.

**19.** 같은 SQL(`hosp_id=30`)을 5번 반복 실행(`V$SQL` 기준 EXECUTIONS=5,
BUFFER_GETS=15,450, ELAPSED_TIME=51,222µs≈0.051초) — 평균 1회당 약 10.2ms로 매우
안정적입니다(최초 1회도 이미 웜 캐시였던 것으로 추정).

**20.** `V$SQL`에서 `SQL_TEXT LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS f_%'`로 조회한
결과 `f_q19`가 `EXECUTIONS=5`로 이 세션 중 가장 높았습니다.

## III. 인덱스 설계 · SARGable SQL (21~30번)

**21.** 작은 테이블(PATIENTS, 4중 조건) 조회는 결과 0건이었지만 `PAT_ID<200` 조건 덕에
이미 `INDEX RANGE SCAN`(Buffers 4)이 선택됐습니다. 큰 테이블(CLAIM_DETAILS,
`detail_id=500000`)은 PK 등치라 `INDEX UNIQUE SCAN`(Buffers 3)이었습니다. (조건 설계상
두 경우 모두 인덱스가 자연스럽게 선택되어 "작은 테이블은 Full Scan도 저렴하다"는
Chapter 4 원리를 직접 재현하려면 인덱스 없는 컬럼으로 조건을 다시 잡아 비교해보는 것을
권장합니다 — 예: `WHERE gender='M' AND city='기타'`처럼 인덱스가 없는 조합.)

**22.** `CLAIM_ID` 범위를 넓혀가며 실측한 결과 **0.5%(1,632건)/5%(14,555건)/15%
(50,249건) 모두 `INDEX RANGE SCAN`을 유지**했습니다(Buffers 13/92/310). `COUNT(*)`만
필요한 인덱스 전용(Index-Only) 조회라, Chapter 4에서 확인한 "Index-Only면 선택도가
높아도(49%까지) 인덱스가 유지된다"는 원리가 15%에서도 그대로 성립한 것입니다.

**23.** 같은 5% 범위에서 `TOTAL_AMT`가 필요해지자 즉시 `TABLE ACCESS FULL`(Buffers
3,090)로 전환됐습니다 — 22번의 `COUNT(*)` 버전(Buffers 92)과 대조하면, "선택도"보다
"인덱스만으로 처리 가능한가"가 전환 지점을 훨씬 크게 좌우한다는 것이 다시 확인됩니다.

**24.** `IX_FINAL_A(HOSP_ID, REVIEW_STATUS)`에서 선두 컬럼(`HOSP_ID=1`)만 조건이면
Buffers 14(`INDEX RANGE SCAN`), 후행 컬럼(`REVIEW_STATUS='심사중'`)만 조건이면
Buffers 1,153(`INDEX FAST FULL SCAN`)으로, Chapter 5와 동일한 패턴이 재현됐습니다.

**25.** `WHERE birth_date <= 20000101`(따옴표 없음)의 Predicate Information에
`TO_NUMBER("BIRTH_DATE")<=20000101`이 그대로 나타나 묵시적 형변환이 확인됐습니다
(Buffers 442, Full Scan).

**26.** `IX_FINAL_B(BIRTH_DATE)` 생성 후에도 형변환 버전은 **여전히 Full Scan**
(Buffers 442, 인덱스가 있어도 못 씀). 따옴표를 붙여 SARGable하게 고친 버전은
`INDEX FAST FULL SCAN`(Buffers 148)으로 전환됨 — 인덱스 존재 여부와 무관하게 SARGable
여부 자체가 핵심이라는 것을 다시 확인.

**27.** `TO_CHAR(receipt_date,'YYYYMM')='202408'`: Buffers 3,090(Full Scan, 인덱스
있어도 못 씀). 범위 조건으로 재작성(`receipt_date>=DATE'2024-08-01' AND <
DATE'2024-09-01'`): Buffers 71(`INDEX RANGE SCAN`) — 약 43배 차이.

**28.** 놀랍게도 이번 조건(claim_id 2일치, 약 0.54%)은 `total_amt`가 SELECT 절에
있다는 이유로 **`ORDER BY claim_id`, `ORDER BY total_amt` 둘 다 Full Scan+SORT ORDER
BY**(Buffers 3,090)였습니다. Chapter 10에서는 0.27%(claim_id만) 범위에서 정렬이
생략됐지만, 이번엔 `total_amt`까지 필요해서(23번과 같은 이유로) 이미 Full Scan
영역이었기 때문입니다 — "선택도"와 "필요 컬럼" 두 요인이 함께 크로스오버 지점을
결정한다는 Chapter 4·10의 원리가 다시 확인된 사례입니다.

**29.** 컬럼 순서를 반대(`REVIEW_STATUS, HOSP_ID`)로 만든 `IX_FINAL_A2`에서
`HOSP_ID=1`(이제 후행)을 조회하니 **`INDEX SKIP SCAN`**(Buffers 17)이 나왔습니다 —
Chapter 5에서 본 `INDEX FAST FULL SCAN`(Buffers 953)과 다른, 더 효율적인 오퍼레이션
입니다. `REVIEW_STATUS`(선두 컬럼)의 값이 단 2종류(심사중/심사완료)뿐이라 옵티마이저가
그 소수의 그룹만 "건너뛰며"(skip) 각각에서 `HOSP_ID=1`을 탐색할 수 있었기 때문입니다 —
"후행 컬럼만 조회하면 항상 Fast Full Scan"이라는 Chapter 5의 결론이 **선두 컬럼의
카디널리티가 매우 낮을 때는 더 유리한 Skip Scan으로 바뀔 수 있다**는 심화 사실을
보여줍니다. `REVIEW_STATUS='심사중'`(이제 선두)은 예상대로 `INDEX RANGE SCAN`
(Buffers 104)이었습니다.

**30.** `USER_INDEXES`로 전체 7개 테이블을 확인한 결과 모두 PK만 남아있었습니다(49번
문항에서 최종 확인).

## IV. 서브쿼리 · 집합연산 · 정렬/집계 (31~40번)

**31.** "외래 청구 낸 환자"∪"보훈 환자": `UNION`=49,603건, `UNION ALL`=240,989건 —
191,386건의 차이로, 두 조건을 동시에 만족하는 환자가 실제로 대량 존재함을 보여줍니다
(외래 비중이 80%로 커서 대부분의 환자가 걸리는 구조상 자연스러운 결과).

**32.** 두 버전 모두 Buffers 3,532로 **동일**했지만 A-Time은 UNION 0.17초, UNION
ALL 0.08초로 약 2배 차이 — Chapter 9와 동일하게 `SORT UNIQUE`의 비용이 Buffers에는
안 잡히고 시간에만 잡혔습니다.

**33.** `DEPT_CODE`별 평균 대비 상관 서브쿼리: `VW_SQ_1`(HASH GROUP BY로 부서별 평균
계산) + 원본 `MEDICAL_CLAIMS` 재조회, 합쳐서 `MEDICAL_CLAIMS`에 대한 `TABLE ACCESS
FULL`이 **2번**(Buffers 3,090×2≈6,181) 나타났습니다 — Chapter 8의 `HOSP_ID` 평균
사례와 동일한 구조가 `DEPT_CODE` 기준으로도 재현됩니다.

**34.** `PAT_ID`(PK) 범위에 `DISTINCT`를 붙인 버전과 안 붙인 버전 모두 `INDEX RANGE
SCAN`만 나타나고 `SORT UNIQUE`가 없었습니다(둘 다 Buffers 36) — Chapter 9의 PK
DISTINCT 생략 원리가 재현됩니다.

**35.** `MEDICAL_CLAIMS.HOSP_ID`(FK, PK 아님)에 `DISTINCT`를 붙이니 이번엔 실제로
`HASH UNIQUE`가 나타났습니다(Buffers 3,090, 대부분 Full Scan 몫이고 HASH UNIQUE
자체의 추가 비용은 미미). PK가 아닌 컬럼은 옵티마이저가 유일성을 증명할 수 없어
`DISTINCT`가 실제로 수행됨을 확인했습니다.

**36.** `WHERE review_status='심사완료' GROUP BY hosp_id`와 `GROUP BY hosp_id,
review_status` 후 바깥 필터, 두 버전의 Plan hash value가 **완전히 동일**했습니다
(`3971657403`) — Chapter 10의 predicate pushdown이 다른 컬럼(`REVIEW_STATUS`)에도
그대로 적용됨을 확인했습니다.

**37.** 인라인 뷰(`WHERE cnt>2500`)와 `HAVING COUNT(*)>2500` 모두 `MEDICAL_CLAIMS`를
한 번만 스캔했고(둘 다 Buffers 3,090대), Chapter 8의 뷰 병합 원리가 재현됩니다.

**38.** `CLAIM_DETAILS`(detail_id 1~5000, PK 좁은 범위)에서 `ORDER BY detail_id`
(인덱스 컬럼): `INDEX RANGE SCAN`만, Buffers **715**. `ORDER BY amt`(비인덱스):
`SORT ORDER BY`+`...BATCHED`, Buffers **47**(!). Chapter 10 Q7·8과 정확히 같은
역설적 패턴(정렬이 있는 쪽이 오히려 더 저렴)이 재현됐습니다 — `BATCHED` 최적화가
정렬 비용을 상쇄하고도 남을 수 있음을 다시 확인.

**39.** 31번(UNION, Buffers 3,532/A-Time 0.17초)과 Chapter 11 스타일 OFFSET 깊은
페이징(Buffers 3,090/A-Time 0.10~0.18초)을 비교하면, 둘 다 Buffers는 완전 스캔 1회
수준에 고정되고 A-Time·메모리만 늘어나는 동일한 패턴을 보입니다 — 근본 원인(정렬/집계가
메모리 연산이라는 것)이 같기 때문입니다.

**40.** (예시) 서브쿼리 — 스칼라 서브쿼리 캐싱(9번); 집합연산 — 없음(UNION은
예상대로 비용이 들었음, 이 자체도 "항상 옵티마이저가 봐주는 건 아니다"라는 교훈);
집계 — GROUP BY 키 필터의 자동 pushdown(36번). 옵티마이저가 유리하게 처리해준
사례와, 그렇지 않고 정직하게 비용이 드는 사례를 함께 보고하는 것이 좋은 답안입니다.

## V. JOIN 실행 원리 (41~45번)

**41.** `HOSP_ID<=3` 힌트 없음: `HASH JOIN`(Buffers 3,093) — Chapter 7과 동일 패턴.

**42.** `USE_NL` 힌트를 붙였지만 `VW_GBF_7` 변환 때문에 여전히 `HASH JOIN`
(Buffers 3,093, Chapter 7과 완전히 동일한 현상 재현) — 힌트가 GROUP BY 변환에
가로막히는 현상이 우연이 아니라 이 쿼리 형태(조인+GROUP BY)의 일반적 특성임을 다시
확인.

**43.** `IX_FINAL_D(HOSP_ID)` 생성 후 `USE_NL` 강제와 힌트 없음 모두 **동일한
`NESTED LOOPS`**(Buffers **28**, Chapter 7의 44보다도 더 적음 — Outer 행이 3건뿐이라)
로 나왔습니다.

**44.** `Starts` 컬럼: `HOSPITALS`는 1회, `IX_FINAL_D`(`MEDICAL_CLAIMS` 인덱스)는
3회 — `HOSPITALS`가 Driving(Outer)임을 다시 확인.

**45.** `HOSP_ID<=300`(Outer 300건)으로 늘리자 옵티마이저가 **자동으로 HASH JOIN
+ `INDEX FAST FULL SCAN`**으로 전환했습니다(Buffers 621) — NL이 아니라 Hash Join을
택했지만 인덱스는 여전히 활용(Full Scan 3,090보다 훨씬 저렴)했습니다. Outer 행이
많아지면 NL의 반복 탐색 비용이 누적되어 옵티마이저가 스스로 다른 방식으로 갈아탄다는
Chapter 7의 예측이 실측으로 확인된 사례입니다.

## VI. 종합 실습 (46~50번)

**46.** `IX_FINAL_E(RECEIPT_DATE)` 생성 후: OFFSET 0(Buffers 3,090/A-Time 0.02초),
OFFSET 100,000(Buffers 3,090/A-Time **0.10초**, 5배), Keyset(`receipt_date<
'2024-09-25'`, Buffers **23**/A-Time 0.01초, `WINDOW NOSORT STOPKEY`+`INDEX RANGE
SCAN DESCENDING`) — Chapter 11의 패턴이 새 인덱스로도 정확히 재현됩니다.

**47.** 병원 10곳 대상 청구 10건에 대해 N+1(개별 반복): `EXECUTIONS=10`,
`BUFFER_GETS=66,216`(평균 6,621.6/회). 조인 1회: Buffers **6,626**. 비율
66,216÷6,626 ≈ **9.99배** — 반복 횟수(10)와 거의 정확히 일치, Chapter 12의 원리가
그대로 재현됩니다.

**48.** 히스토그램 있을 때: `hosp_id=1` E-Rows 3,437(A-Rows 3,058), `hosp_id=900`
E-Rows 158(A-Rows 168) — 둘 다 정확. 히스토그램 제거(`SIZE 1`) 후: **두 값 모두
E-Rows 300**으로 동일해짐(300,000÷1,000) — Chapter 13과 정확히 같은 현상이 다른
두 `HOSP_ID` 값(1, 900)으로도 재현됩니다. 복원 후 `HISTOGRAM=HYBRID`,
`NUM_BUCKETS=254`로 정상 확인.

**49.** `USER_INDEXES`로 7개 테이블 전체를 조회한 결과, 모든 테이블에 PK 인덱스
(`PK_HOSPITALS`, `PK_PATIENTS`, `PK_DRUG_MASTER`, `PK_MEDICAL_CLAIMS`,
`PK_CLAIM_DETAILS`, `PK_DISEASES`, `PK_REVIEW_LOG`)만 남아있음을 확인했습니다 —
이 최종 테스트에서 만든 모든 `IX_FINAL_*` 인덱스가 빠짐없이 정리되었습니다.

**50.** (예시 답안, 학생마다 다를 수 있음)
1. **9번 문항**: 스칼라 서브쿼리 캐시가 distinct 200개에서 `Starts=11,293`으로 예상보다
   훨씬 많이 나온 것 — 캐시에 용량 한계가 있다는 걸 실측 없이는 몰랐을 것이다.
2. **38번 문항**: `ORDER BY detail_id`(정렬 없음, Buffers 715)가 `ORDER BY amt`
   (정렬 있음, Buffers 47)보다 오히려 비쌌던 것 — "정렬이 없으면 항상 유리하다"는
   상식이 `BATCHED` 접근 최적화 앞에서 뒤집힌 사례.
3. **45번 문항**: Outer 300건에서 옵티마이저가 스스로 NL을 버리고 Hash Join
   (Buffers 621, 여전히 인덱스 활용)으로 전환한 것 — 사람이 힌트로 개입하지 않아도
   옵티마이저가 데이터 규모 변화에 맞춰 스스로 적응한다는 것을 직접 확인.
