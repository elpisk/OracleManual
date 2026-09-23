# Chapter 3. 실행계획 기초 — 해설

`SQL튜닝_Ch03_문제.md`와 번호가 1:1로 대응합니다. 모든 실행계획은 실습 DB에서
실측했습니다 (`DBMS_XPLAN.DISPLAY` / `DBMS_XPLAN.DISPLAY_CURSOR(...'ALLSTATS LAST')`).

---

### 1. [상] TABLE ACCESS FULL과 filter 조건

`CLAIM_TYPE`과 `TOTAL_AMT` 두 컬럼 모두에 인덱스가 없기 때문에, Oracle은 이 조건을
"찾아갈" 방법이 없다. 그래서 테이블 전체를 처음부터 끝까지 읽으면서(`TABLE ACCESS FULL`)
읽어온 각 행에 대해 `CLAIM_TYPE='입원' AND TOTAL_AMT>500000` 조건을 하나하나 검사해
걸러낸다 — 이것이 `filter` 조건이다.

만약 `CLAIM_TYPE`이나 `TOTAL_AMT`에 인덱스가 있었다면, 그 인덱스를 이용해 조건에 맞는
행의 위치(ROWID)를 먼저 찾아낸 뒤 필요한 행만 골라 읽을 수 있었을 것이다 — 이 경우 조건이
`filter`가 아니라 `access`(인덱스를 탐색하는 조건)로 바뀌었을 것이다. 다만 `CLAIM_TYPE`처럼
값의 종류가 적은(입원/외래 2종) 컬럼은 인덱스를 만들어도 항상 쓰인다는 보장은 없다 — 이
주제는 Chapter 4·5에서 다룬다.

**흔한 실수**: "인덱스가 없으니까 무조건 나쁘다"고 단정하는 것. 조건을 만족하는 행이
전체의 상당 비율(예: 30% 이상)이라면, 인덱스를 쓰는 것보다 Full Scan이 더 빠를 수도 있다
(Chapter 4의 핵심 주제).

### 2. [상] E-Rows vs A-Rows

`E-Rows`(Estimated Rows)는 옵티마이저가 통계정보를 근거로 **실행 전에 추정한** 결과
건수이고, `A-Rows`(Actual Rows)는 **실제로 실행해서 나온** 건수다. 이 예제에서는 77,946건을
예상했지만 실제로는 411건뿐이었다 — 약 190배 차이다.

이 차이가 문제가 되는 이유: 옵티마이저는 이 SQL이 서브쿼리의 일부이거나 더 큰 조인의 한
쪽이었다면, "77,946건이 나올 것"이라는 잘못된 전제로 조인 순서·조인 방식(Nested Loops vs
Hash Join)·메모리 할당량까지 잘못 결정할 수 있다. 즉 카디널리티 추정 오류는 그 자리에서
끝나지 않고 **연쇄적으로 다른 판단까지 그르칠 수 있다**는 점이 핵심이다. 왜 이런 오류가
생기는지(두 컬럼 조건의 상관관계를 옵티마이저가 기본적으로 고려하지 못하는 것 등)는
Chapter 13에서 다룬다.

### 3. [상] INDEX UNIQUE SCAN → TABLE ACCESS BY INDEX ROWID

실행 순서는 안쪽(Id가 크고 들여쓰기가 깊은 것)부터다.
1. **Id 2 (`INDEX UNIQUE SCAN`)**: PK 인덱스에서 `CLAIM_ID='20240615-0013440'`에 해당하는
   항목을 찾는다. 인덱스에는 컬럼 값과 그 행의 물리적 주소(ROWID)만 들어있고, 나머지 컬럼
   (HOSP_ID, TOTAL_AMT 등)은 들어있지 않다.
2. **Id 1 (`TABLE ACCESS BY INDEX ROWID`)**: 방금 찾은 ROWID를 이용해 실제 테이블 블록에서
   그 행 전체(`SELECT *`이므로 모든 컬럼)를 가져온다.
3. **Id 0**: 결과를 반환한다.

`INDEX UNIQUE SCAN` 하나로 끝나지 않는 이유는 **인덱스가 SELECT 절에 필요한 컬럼을 전부
갖고 있지 않기 때문**이다. 만약 이 쿼리가 `SELECT claim_id`처럼 인덱스에 이미 있는 컬럼만
요구했다면, `TABLE ACCESS BY INDEX ROWID` 단계 없이 인덱스만으로 끝났을 것이다(Index-Only
Access, 5·6번 문항과 연결).

### 4. [상] UNIQUE SCAN vs RANGE SCAN, BATCHED

`INDEX UNIQUE SCAN`은 PK 인덱스가 "유일함"을 보장하므로 조건에 맞는 항목이 정확히 0개
아니면 1개라는 것을 옵티마이저가 알고 있을 때 쓰인다(등치 조건, `=`). 반면 `BETWEEN 100
AND 130`처럼 범위 조건이면 여러 개의 행이 나올 수 있으므로, 인덱스에서 시작점(100)부터
끝점(130)까지 **순회**해야 한다 — 이것이 `INDEX RANGE SCAN`이다. 같은 인덱스라도 조건의
성격(등치 vs 범위)에 따라 오퍼레이션 이름이 달라진다는 것이 핵심이다.

`BATCHED`는 Oracle 12c 이상에서 도입된 최적화로, 인덱스에서 여러 ROWID를 먼저 모아
"배치(묶음)"로 정렬한 뒤 테이블 블록에 접근하는 방식이다. ROWID 하나씩 바로바로 테이블을
찾아가는 것보다, 물리적으로 가까운 블록끼리 묶어서 접근하면 디스크/메모리 접근 효율이
좋아진다. 3번 문항(단건 조회)은 애초에 결과가 1건이라 배치할 것이 없어 `BATCHED`가
붙지 않았다.

### 5. [최상] WINDOW NOSORT STOPKEY — SORT가 생략된 이유

PK 인덱스(`PK_MEDICAL_CLAIMS`)는 `CLAIM_ID` 값 순서대로 이미 정렬되어 저장되어 있다.
`ORDER BY claim_id`가 원하는 순서와 인덱스가 이미 저장된 순서가 정확히 같기 때문에,
Oracle은 별도로 데이터를 메모리에 모아 정렬(`SORT`)할 필요 없이 **인덱스를 순서대로 읽기만
하면 된다** — 이것이 오퍼레이션 이름의 `NOSORT`가 의미하는 바다.

`STOPKEY`는 `FETCH FIRST 5 ROWS ONLY`와 관련이 있다 — 필요한 5건을 확보하는 즉시 인덱스
읽기를 멈춘다(전체 인덱스를 다 읽지 않음). `WINDOW`는 내부적으로 `ROW_NUMBER() OVER (ORDER
BY claim_id) <= 5`로 변환되어 처리되기 때문에 붙는 이름이다(`Predicate Information`의
`ROW_NUMBER() OVER (...)` 조건 참고). 세 가지 특성(정렬 순서 재활용 + 조기 종료 + 윈도우
함수 변환)이 합쳐진 이름이 `WINDOW NOSORT STOPKEY`다.

**주의**: 이 예제는 힌트(`INDEX(medical_claims PK_MEDICAL_CLAIMS)`)로 강제한 것이다. 힌트
없이 그냥 실행하면 옵티마이저가 상황에 따라 Full Scan + Sort를 택할 수도 있다 — 5건만
필요한데 인덱스를 few-rows 상황이 아니면 이 방식이 항상 유리한 것은 아니다.

### 6. [상] INDEX FAST FULL SCAN — 테이블을 아예 안 읽는 경우

`CLAIM_ID`는 `PRIMARY KEY` 제약으로 `NOT NULL`이 보장된다. `COUNT(claim_id)`는 NULL이
아닌 값의 개수를 세는 것인데, PK 인덱스에는 애초에 NULL이 들어갈 수 없으므로 **인덱스에
있는 항목 개수 = COUNT(claim_id) 결과**가 정확히 같다. 따라서 굳이 테이블 블록까지 가서
데이터를 읽을 필요가 없다 — 인덱스만 읽고 끝낸다.

`INDEX FAST FULL SCAN`과 `INDEX FULL SCAN`(5번 문항)의 차이: `FULL SCAN`은 **정렬된 순서를
지켜야 할 때**(예: `ORDER BY`) 인덱스를 논리적인 순서(B-Tree의 리프 블록을 순서대로)로
읽는다. 반면 `FAST FULL SCAN`은 결과의 순서가 상관없을 때(단순 집계라 순서 무관) 인덱스를
디스크에 저장된 물리적 순서대로, 여러 블록을 한 번에 읽는 멀티블록 I/O로 빠르게 훑는다 —
이름의 "FAST"가 여기서 온다. `A-Rows 300K`(30만 건 전체)를 다 읽었다는 점에서 `COUNT(*)`가
사실상 전수조사이지만, 그래도 Buffers가 1,891에 그친 것은 멀티블록 읽기 덕분이다(Q1의
Full Scan Buffers 3,117과 비교해볼 만하다 — 같은 테이블인데도 접근 방식에 따라 차이가 난다).

### 7. [최상] 실행 순서와 드라이빙 테이블

**실행 순서** (들여쓰기가 깊은 것부터, 같은 레벨이면 아래부터):
1. Id 4 (`INDEX RANGE SCAN` on `PK_HOSPITALS`, `HOSP_ID<=10`) — 먼저 실행
2. Id 3 (`TABLE ACCESS BY INDEX ROWID BATCHED` on `HOSPITALS`) — 방금 찾은 10건의 실제 행을 가져옴
3. Id 5 (`TABLE ACCESS FULL` on `MEDICAL_CLAIMS`) — 큰 테이블을 전체 스캔
4. Id 2 (`HASH JOIN`) — 3의 결과(HOSPITALS 10건)와 5의 결과(MEDICAL_CLAIMS 필터링 후)를 조인
5. Id 1 (`HASH GROUP BY`) — 조인 결과를 HOSP_TYPE별로 집계
6. Id 0 — 최종 결과 반환

`HASH JOIN`은 두 입력 중 더 작은 쪽으로 **해시 테이블을 메모리에 만들고**(Build), 더 큰
쪽을 한 행씩 그 해시 테이블에 대조(Probe)하는 방식으로 동작한다. `HOSPITALS`가 딱 10건
(Rows=10)인 반면 `MEDICAL_CLAIMS`는 29,631건(Rows=29631)으로 훨씬 크다 — 따라서 작은
`HOSPITALS`가 Build(빌드) 입력, 큰 `MEDICAL_CLAIMS`가 Probe(탐침) 입력 역할을 했을
가능성이 높다. 일반적으로 Hash Join은 작은 쪽을 빌드 입력으로 선택해야 메모리를 적게 쓰고
효율적이다.

### 8. [상] 같은 조건, 다른 predicate 종류

`HOSPITALS.HOSP_ID`는 `PK_HOSPITALS`라는 인덱스가 있는 컬럼이다 — 그래서 `HOSP_ID<=10`
조건으로 인덱스를 "찾아갈" 수 있고, 이것이 `access` 조건(Id 4)이 된다. 반면
`MEDICAL_CLAIMS.HOSP_ID`에는 인덱스가 없다(이 스키마는 PK 외 인덱스가 없는 상태다) —
그래서 `MEDICAL_CLAIMS`는 어차피 `TABLE ACCESS FULL`로 전체를 읽은 뒤, 읽어온 행 중에서
`HOSP_ID<=10`인 것만 골라내는 `filter`(Id 5)로 처리된다.

즉 같은 조건식이라도 **그 컬럼에 인덱스가 있는지 여부**에 따라 `access`가 될 수도,
`filter`가 될 수도 있다 — 이것이 "인덱스가 있는데 왜 안 쓰이지?"를 진단할 때 항상 먼저
확인해야 하는 지점이다.

### 9. [상] Cost는 실행 시간이 아니다

교안 05절에서 짚었듯, `Cost`는 **같은 SQL 안에서 여러 실행 방법 후보를 옵티마이저 내부적으로
비교하기 위한 상대적 지표**다. 서로 다른 SQL(1번 문항 vs 7번 문항)의 Cost를 나란히 놓고
"둘이 비슷하니 실행 시간도 비슷하겠다"고 판단하는 것은 잘못이다 — Cost는 CPU/I/O 예상
비용을 옵티마이저 내부 공식으로 환산한 단위 없는 수치일 뿐, 초 단위 시간과 1:1로 대응하지
않는다. 실제 소요 시간을 알고 싶다면 `A-Time`(실측)이나 `Elapsed Time`을 봐야 한다 —
1번 문항과 7번 문항 모두 Buffers는 3,000대로 비슷했지만, 이는 우연히 둘 다
`MEDICAL_CLAIMS` 전체를 훑었기 때문이지 Cost 수치가 같아서가 아니다.

### 10. [최상] 규모가 커지면 위험해질 소재 찾기

모범 답안 예시 (여러 정답이 가능하며, 근거가 타당하면 인정):

- **1번(Q1, Full Scan)**: 지금은 30만 건이라 Buffers 3,117로 크게 부담스럽지 않지만, 데이터가
  10배(300만 건)가 되면 Full Scan 비용도 대략 비례해서 커진다. `CLAIM_TYPE`/`TOTAL_AMT`
  조건에 맞는 인덱스가 없는 한 이 SQL은 데이터가 늘어날수록 그대로 느려진다 — Chapter 5의
  핵심 사례.
- **7번(Q6, HASH JOIN)**: `HOSPITALS`는 1,000건 고정에 가깝지만(요양기관 수는 급격히
  늘지 않음), `MEDICAL_CLAIMS`는 매년 데이터가 쌓여 계속 커진다. 지금은 `TABLE ACCESS
  FULL`(Id 5)의 대상이 30만 건이지만, 나중에 훨씬 커지면 이 Full Scan 자체가 병목이 될 수
  있다 — `HOSP_ID`에 인덱스를 만들면(Chapter 5) `TABLE ACCESS FULL`을 `INDEX RANGE SCAN`
  으로 바꿀 여지가 있다.
- **6번(Q5, COUNT)**: `INDEX FAST FULL SCAN`도 결국 전체 인덱스를 읽는 것이라, 데이터가
  커지면 Buffers도 비례해서 커진다. 다만 이건 "집계"라는 작업의 본질상 전수조사가
  불가피한 경우가 많아, 인덱스/파티셔닝보다는 **주기적으로 미리 집계해두는 요약 테이블**
  같은 구조적 해법이 필요할 수 있다(이 과정 범위 밖의 주제이지만 언급할 가치가 있다).
