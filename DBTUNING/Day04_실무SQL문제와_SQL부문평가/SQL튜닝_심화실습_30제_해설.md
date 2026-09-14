# Oracle SQL 튜닝 심화 실습 30제 해설

`SQL튜닝_심화실습_30제_문제.md`와 번호가 1:1로 대응합니다. 모든 수치는 실습 DB
(SQLT 계정)에서 실제로 실행해 얻은 결과입니다. **이 해설의 절반 가까이는 "정석 기법을
그대로 적용했지만 개선되지 않았다"는 결과입니다** — 억지로 성공 사례로 포장하지 않고
있는 그대로 실었습니다. 실무에서도 흔히 벌어지는 일이며, 그 이유를 이해하는 것 자체가
심화 학습의 핵심입니다.

---

## I. 인덱스 재설계 · 쿼리 재작성 (1~6번)

**1.** 인덱스 없음: `TABLE ACCESS FULL`, Buffers=**3090**. `IX_ADV_A1(claim_type,
review_status, receipt_date)` 추가 후: `INDEX RANGE SCAN (MIN/MAX)`, Buffers=**3**
— 1030배 개선. 조건 두 개가 인덱스 선두 2개 컬럼과 정확히 일치하고, 구하려는 값
(`MAX(receipt_date)`)이 3번째 컬럼이라 Oracle이 인덱스의 맨 끝 항목 하나만 읽고
끝내는 `MIN/MAX` 최적화가 정확히 작동했습니다.

**2.** 단일 컬럼 인덱스만 있는 상태의 원본: `TABLE ACCESS FULL`, Buffers=**3090**.
`INDEX_DESC` + `ROWNUM=1`로 재작성한 버전: **Buffers=3090, 그대로**(`SORT ORDER BY
STOPKEY`+`TABLE ACCESS FULL` — 힌트가 무시됨). `FETCH FIRST 1 ROW ONLY` +
`FIRST_ROWS(1)` 힌트로 문법을 바꿔 재시도해도 **역시 Buffers=3090**
(`WINDOW SORT PUSHED RANK`+`TABLE ACCESS FULL`)으로 동일했습니다. **이 교과서적
기법은 이 경우 통하지 않았습니다** — `claim_type`/`review_status` 필터 컬럼이
인덱스에 전혀 없어서, 인덱스를 역순으로 스캔하며 각 항목마다 테이블을 확인해야 하는데
Oracle 옵티마이저는 이 방식보다 "전체를 한 번에 읽고 메모리에서 정렬 후 자르는" 방식이
더 싸다고 판단한 것으로 보입니다. 즉 이 기법이 효과를 보려면 **필터 컬럼도 함께
인덱스에 있어야** 합니다(1번 문항의 `IX_ADV_A1`처럼).

**3.** (a) `ins_type IN(...) AND city= AND gender= AND pat_name LIKE 'K%'`:
`INLIST ITERATOR`+`INDEX RANGE SCAN`, Buffers=**45** — 인덱스가 잘 먹힘. (b)
`city='기타' AND phone LIKE '%5%'`: `TABLE ACCESS FULL`, Buffers=**1594** —
`city`가 선두 컬럼이 아니고 `phone`은 앞부분 와일드카드라 인덱스를 전혀 못 씀. (c)
`city= AND ins_type= AND gender=`(선두 3개 컬럼 전부 등치인데도!): `TABLE ACCESS
FULL`, Buffers=**1032** — 8,856건(17.7%)이라는 선택도가 이 50,000행 테이블
크기에서는 인덱스보다 Full Scan이 이미 더 싼 영역이기 때문입니다. **인덱스 하나로
세 쿼리를 모두 만족시키는 것은 이 데이터 분포에서는 불가능했고, 3개 중 1개만 실제로
혜택을 봤습니다** — 실무에서 "인덱스 하나로 여러 쿼리를 커버하겠다"는 설계가 항상
성공하지는 않는다는 정직한 사례입니다.

**4.** `IX_ADV_A4(hosp_id, review_status, claim_type, receipt_date)`(중간에
`review_status` 조건 없음): Buffers=**410**, Predicate Information에 놀랍게도
`claim_type`과 `receipt_date`가 모두 **access**로 표시됩니다(filter가 아님) —
`hosp_id`가 `IN`-리스트(3개 값)라서 `INLIST ITERATOR`로 값마다 독립적인 스캔이
일어나는데, 이 경우 중간 컬럼에 조건이 없어도 Oracle이 뒤 컬럼들을 access로 사용할 수
있었습니다. 컬럼 순서를 `(hosp_id, claim_type, receipt_date, review_status)`로
바꾼 버전은 Buffers=**411**로 **사실상 동일**했습니다. "중간에 조건 없는 컬럼이
있으면 무조건 손해"라는 통념이 이 IN-리스트 상황에서는 거의 차이를 만들지 않는다는
것을 실측으로 확인했습니다.

**5.** `IX_ADV_A5(receipt_date, hosp_id, claim_type, review_status)`(선두 컬럼
조건 없음): `TABLE ACCESS FULL`, Buffers=**3106**(Predicate에
`INTERNAL_FUNCTION("HOSP_ID")`만 filter로 표시 — 인덱스를 아예 안 씀). 컬럼 순서를
`(hosp_id, claim_type, review_status)`로 바꾼 버전: `INLIST ITERATOR`+
`INDEX RANGE SCAN`, Buffers=**245** — 12.7배 개선. 이번엔 선두 컬럼에 조건이 전혀
없으니 인덱스 자체가 무용지물이 되는, 훨씬 더 확실한 사례였습니다.

**6.** `hosp_id`, `pat_id` 각각 단일 컬럼 인덱스가 있는 상태에서 OR 조건 실행 결과,
`CONCATENATION`이 아니라 **`BITMAP CONVERSION` + `BITMAP OR`**가 나타났습니다
(Buffers=**2030**). 두 B-Tree 인덱스 범위 스캔 결과를 각각 비트맵으로 변환한 뒤
`BITMAP OR`로 합친 다음 다시 ROWID로 변환해 테이블에 접근하는 방식입니다 — 흔히
"OR는 CONCATENATION으로 처리된다"고 알려져 있지만, 실제로는 옵티마이저가 상황에 따라
비트맵 결합을 선택할 수도 있다는 것을 보여주는 사례입니다.

## II. 다중 테이블 조인 설계 (7~12번)

**7.** `NO_UNNEST` 강제: `FILTER`(상관 방식) 실행, Buffers=**177,266**(!), PATIENTS를
59,511×2 = 약 118,504회에 걸쳐 반복 접근. 힌트 제거(언네스팅 허용): `HASH JOIN`,
Buffers=**3569** — **약 50배** 개선. 서브쿼리 언네스팅이 막히면 상관 서브쿼리가 바깥
쿼리의 매 행마다 반복 실행되어 얼마나 비싸지는지 극적으로 보여주는 사례입니다.

**8.** 힌트 없음(옵티마이저 자체 선택, `HASH JOIN` 연쇄): Buffers=**10,263**. 인덱스
4개 + `LEADING`+전부 `USE_NL` 강제: Buffers=**32,979**(3배 악화). 인덱스는 그대로
두고 일부만 `USE_HASH`로 바꾼 절충안(`LEADING(h m) USE_NL(m) USE_HASH(d) USE_HASH(g)
USE_HASH(p)`): Buffers=**13,783**(여전히 baseline보다 나쁨). **세 가지 설계 중
아무것도 옵티마이저의 기본 선택을 이기지 못했습니다.** `CLAIM_DETAILS`가 청구 1건당
평균 3건(팬아웃)인 1:N 관계라, NL 위주 설계는 반복 인덱스 탐색이 누적되어 오히려
손해를 봅니다 — 팬아웃이 있는 다중 조인에서는 해시 조인이 유리한 경우가 많다는 것을
실측으로 확인했습니다.

**9.** 힌트 없음: `HASH JOIN` 연쇄(adaptive plan), Buffers=**11,631**. 인덱스 2개 +
전부 `USE_NL` 강제: Buffers=**598,073**(!, 약 51배 악화). 절충안(`USE_HASH`
일부 적용)도 Buffers=**118,000**대로 여전히 baseline보다 훨씬 나쁨. 8번과 정확히
같은 패턴 — `DISEASES`(J00 진단만 89,840건)를 드라이빙으로 삼아도, 이후 `CLAIM_ID`
기준 NL 반복이 워낙 많아(71,975회) 해시 조인을 절대 이기지 못했습니다.

**10.** `LEADING(h m) USE_NL(m)`(작은 테이블 `HOSPITALS`가 드라이빙): `NESTED LOOPS`,
Buffers=**1223**. `LEADING(m h) USE_NL(h)`(큰 테이블 `MEDICAL_CLAIMS`가 드라이빙):
Buffers=**300,000**대(!) — 약 245배 차이. `HOSPITALS`는 400건인데 `MEDICAL_CLAIMS`는
205,023건이 매칭되므로, 큰 쪽을 드라이빙으로 삼으면 `INDEX UNIQUE SCAN`을 20만
번 넘게 반복해야 합니다. "NL 조인은 반드시 작은 테이블을 먼저 몰아야 한다"는 원칙이
이번엔 교과서 그대로 재현됐습니다.

**11.** 상관 서브쿼리(`hosp_id`별 평균): `HASH JOIN`+`VW_SQ_1`, `MEDICAL_CLAIMS`를
2번 스캔, Buffers=**6181**. `AVG() OVER(PARTITION BY hosp_id)` 윈도우 함수로
재작성: `WINDOW SORT`, 1번만 스캔, Buffers=**3090** — 정확히 절반. 스캔 횟수가
2회에서 1회로 줄어든 만큼 Buffers도 거의 정확히 절반이 됐습니다.

**12.** 힌트 없음(`HASH JOIN OUTER`, adaptive): Buffers=**5062**. `LEADING(m rl)
USE_NL(rl)` 강제: Buffers=**33,230**(약 6.6배 악화). `REVIEW_LOG`가 500,000건인
FK 없는 대형 테이블이라, `MEDICAL_CLAIMS` 15,029건마다 `IX_ADV_Q12` 인덱스를
반복 탐색하는 NL보다, `INDEX FAST FULL SCAN`으로 한 번에 훑는 해시 조인이 더
저렴했습니다. 8·9번과 함께 이 스키마에서는 "NL을 강제하면 오히려 손해"인 경우가
드물지 않다는 것을 보여주는 세 번째 사례입니다.

## III. 서브쿼리·집합연산·메모리 최소화 (13~19번)

**13.** `DISTINCT`: `HASH JOIN SEMI`+`HASH UNIQUE`, Buffers=**515**. `EXISTS`:
`HASH JOIN SEMI`만(별도 `HASH UNIQUE` 없음), Buffers=**508**. 세미 조인 자체가
이미 중복을 만들지 않으므로 `DISTINCT`가 붙었던 자리에 있던 추가 `HASH UNIQUE`
단계가 사라졌습니다 — 다만 이 케이스에서는 `HOSPITALS`가 1000건뿐이라 개선 폭
자체는 크지 않았습니다(515→508).

**14.** 힌트 없음과 `LEADING(h m d) USE_NL(m) USE_NL(d)` 강제 버전의 실행계획이
**완전히 동일**했습니다(Plan hash 1200083812, Buffers=**7030** 둘 다). `CLAIM_DETAILS`
필터(`qty>=3`)가 `INDEX FAST FULL SCAN`으로 처리되며 `HASH JOIN SEMI`가 이미 최선의
선택이었고, NL 힌트는 받아들여지지 않았습니다.

**15.** 인덱스 없음: `SORT UNIQUE`×2 + `TABLE ACCESS FULL`×2, Buffers=**3532**.
`patients(city, pat_id)`, `medical_claims(claim_type, pat_id)` 인덱스 추가: 한쪽은
`SORT UNIQUE`, 다른 한쪽은 **`SORT UNIQUE NOSORT`**(이미 `pat_id` 순으로 정렬된
인덱스라 정렬 생략)로 바뀌었고, `INDEX FAST FULL SCAN`/`INDEX RANGE SCAN`으로
전환되며 Buffers=**359** — 약 9.8배 개선. `MINUS`처럼 정렬이 필요한 집합 연산도,
인덱스로 이미 정렬된 입력을 주면 정렬 비용 자체를 없앨 수 있습니다.

**16.** `UNION`(같은 테이블 2회 스캔): `UNION-ALL`+`SORT UNIQUE`, Buffers=**6180**.
`OR`+`DISTINCT`(1회 스캔) 재작성: `HASH UNIQUE`, Buffers=**3090** — 정확히 절반.
스캔 횟수를 줄이는 재작성이 UNION 계열에서도 그대로 통했습니다.

**17.** IN 서브쿼리(2회 스캔): `HASH JOIN RIGHT SEMI`+`VW_NSO_1`, Buffers=**6180**.
`MAX(...) KEEP(DENSE_RANK FIRST ORDER BY total_amt DESC)`(1회 스캔): `SORT GROUP
BY`, Buffers=**3090** — 정확히 절반. `KEEP` 집계 함수로 "그룹별 1등 값과 그에 딸린
다른 컬럼"을 한 번의 `GROUP BY`로 동시에 뽑아낼 수 있음을 확인했습니다.

**18.** 자기 조인(`hosp_id=1`, 3,058건): `MERGE JOIN OUTER`, `MEDICAL_CLAIMS` 2회
스캔, Buffers=**6180**, **A-Time 1.11초**. `RANK() OVER(ORDER BY total_amt DESC)`
윈도우 함수: `TABLE ACCESS FULL` 1회, Buffers=**3090**, **A-Time 0.01초**. Buffers는
절반이지만 **A-Time은 111배** 차이가 납니다 — 자기 조인 버전은 `MERGE JOIN`을 위한
`SORT JOIN` 2번(각 3천여 건이지만 O(n²)에 가까운 비교 연산)이 A-Time에는 크게
잡히지만 Buffers에는 거의 드러나지 않습니다. Chapter 10·14에서부터 반복된 "Buffers만
보면 안 된다"는 원칙이 분석함수 재작성에서도 그대로 확인됩니다.

**19.** 일/월/연 3-way 조인(3회 스캔): `HASH JOIN RIGHT/OUTER` 연쇄,
Buffers=**9270**. `SUM(SUM(total_amt)) OVER(...)` 윈도우 함수(1회 스캔):
`WINDOW BUFFER`+`SORT GROUP BY`, Buffers=**3090** — 3배 개선(스캔 3회→1회와
정확히 비례).

## IV. 페이징 · 동적 조건절 · ORDER BY 제거 (20~24번)

**20.** 인덱스 없음: `HASH JOIN RIGHT OUTER`×2 + `SORT ORDER BY STOPKEY`,
Buffers=**3547**(216,489건을 모두 조인 후 정렬해야 몇 번째 20개인지 알 수 있음).
`IX_ADV_Q20(claim_type, review_status, receipt_date)` 추가: `NESTED LOOPS
OUTER`×2 + `INDEX RANGE SCAN` + `COUNT STOPKEY`, Buffers=**109** — **32.5배**
개선. 인덱스가 조건과 정렬 순서를 동시에 커버하니 필요한 20건만 딱 읽고 멈췄습니다.

**21.** `hosp_id`에 인덱스가 없는 상태에서, 옵션 값이 없을 때와 있을 때 모두
`TABLE ACCESS FULL`+동일한 SQL_ID(`1zznckc05dyy9`)를 공유했습니다(Buffers=3090
동일) — 인덱스가 없으니 애초에 바뀔 실행계획 자체가 없었던 것입니다(동적 조건절이
실행계획 분리를 유발하려면 그 조건에 유리한 인덱스가 있어야 의미가 생깁니다). 대신
`UNION ALL` 4분기 버전에서 흥미로운 사실을 확인했습니다: `Starts` 컬럼을 보면 4개
분기 중 **실제 바인드 조합에 해당하는 1개 분기만 `Starts=1`로 실행되고, 나머지 3개는
`Starts=0`**으로 아예 실행되지 않았습니다(Buffers도 0). 즉 Oracle은 `FILTER`
연산으로 필요 없는 `UNION ALL` 분기를 실행 시점에 완전히 건너뜁니다 — 문항이 의도한
"실행계획이 물리적으로 나뉘는 것"과는 다르지만, "불필요한 작업을 실행 안 한다"는
같은 목표를 다른 메커니즘으로 달성하는 것을 확인했습니다.

**22.** `medical_claims(hosp_id)` 단일 인덱스 상태: `TABLE ACCESS FULL`+
`SORT ORDER BY`, Buffers=**3090**. `(hosp_id, receipt_date, claim_type)` 복합
인덱스로 교체해도 **Buffers=3090, 여전히 Full Scan+정렬** 그대로였습니다.
`hosp_id=10`이 3,005건(약 1%)인데 `SELECT` 목록에 인덱스에 없는 컬럼이 있어서가
아니라 — 사실 이번엔 `claim_id`가 SELECT 절에 있는데 인덱스엔 없어서, 인덱스로
읽더라도 매 행 테이블 접근이 필요해 Full Scan과 비용이 비슷했기 때문입니다.
**"정렬 순서와 일치하는 인덱스를 만들면 무조건 정렬이 사라진다"는 통념이 SELECT
절에 인덱스 밖 컬럼이 있으면 깨질 수 있음**을 확인한 사례입니다.

**23.** `LEADING(p m)`과 `LEADING(m p)` 두 힌트 모두 **완전히 동일한 실행계획**
(Buffers=3090, `TABLE ACCESS FULL`+`SORT ORDER BY`)이 나왔고, 두 경우 모두
**`PATIENTS`에 대한 접근이 실행계획에 전혀 나타나지 않았습니다.** `PAT_ID`가
`PATIENTS`의 PK이자 `MEDICAL_CLAIMS`의 FK(NOT NULL)라서, `SELECT` 목록에
`PATIENTS`의 컬럼이 하나도 없는 이 쿼리는 Chapter 1에서 배운 **조인 제거(join
elimination)**가 적용되어 조인 자체가 통째로 사라졌기 때문입니다 — 그러니
`LEADING`/`USE_NL` 힌트가 무엇을 지정하든 애초에 의미가 없었습니다.

**24.** 흔한 값(`심사완료`, 159,162건, 약 53%): **`INDEX FAST FULL SCAN`**,
Buffers=**1343**(인덱스 전체를 순서 없이 훑되 테이블은 안 감). 드문 값(`심사중`,
17,465건, 약 6%): **`INDEX RANGE SCAN`**, Buffers=**73** — 약 18배 차이. 둘 다
`COUNT(*)`만 필요해 테이블 접근 없이 인덱스만으로 끝났지만, 선두 컬럼 값의 비중이
크면 Oracle이 순서 있는 `RANGE SCAN` 대신 순서 없는 `FAST FULL SCAN`으로 전환해
인덱스 전체를 좀 더 효율적으로 훑는 것을 확인했습니다.

## V. 진단형 종합 문제 (25~30번)

**25.** `IN`(20개 리터럴): `INLIST ITERATOR`(`Starts=20`)+`INDEX RANGE SCAN`,
Buffers=**158**. `BETWEEN`(동일 범위): `INDEX RANGE SCAN` 1회, Buffers=**119** —
약 25% 적음. `IN`-리스트는 값 개수만큼 인덱스를 반복 탐색하는 반면 `BETWEEN`은
한 번의 연속 범위 스캔이라, 값이 연속적인 경우 `BETWEEN`이 근소하게 유리합니다.

**26.** 필터 없는 버전과 `claim_type='입원'` 필터가 있는 버전 **모두**
`WINDOW SORT PUSHED RANK`+`TABLE ACCESS FULL`이었고 **Buffers=3090으로 동일**했습니다.
인덱스(`receipt_date`)가 있었음에도 `INDEX ... DESCENDING`류의 부분범위처리는
필터 유무와 무관하게 전혀 나타나지 않았습니다 — 2번 문항에서 확인한 것과 같은 패턴이
`FETCH FIRST` 문법에서도 재현된 것으로, 이 인스턴스/데이터 분포에서는 Full Scan +
메모리 내 Top-N 정렬을 옵티마이저가 인덱스 역방향 스캔보다 일관되게 선호한다는 것을
알 수 있습니다(20번처럼 인덱스가 WHERE 조건까지 함께 커버할 때는 확실히 유리했던
것과 대조됩니다).

**27.** `TO_CHAR(m.claim_id) = d.claim_id`와 `m.claim_id = d.claim_id` **두 버전이
완전히 동일한 실행계획과 Buffers(6632)**를 보였습니다. `claim_id`가 이미
`VARCHAR2`이기 때문에 `TO_CHAR()`가 의미 없는 항등 함수가 되고, Oracle 옵티마이저가
이를 인식해 실질적으로 제거한 것으로 보입니다. Chapter 6의 "함수를 씌우면 인덱스를
못 쓴다"는 원칙은 **그 함수가 실제로 값을 변형시킬 때만** 성립하며, 이미 같은
타입에 대한 항등 함수는 예외일 수 있다는 걸 보여줍니다.

**28.** 힌트 없음(연간 전체, 사실상 100% 매칭): `TABLE ACCESS FULL`,
Buffers=**3090**. `INDEX(m ix_adv_q28)`로 강제: `TABLE ACCESS BY INDEX ROWID
BATCHED`+`INDEX RANGE SCAN`, Buffers=**264,000**대(!) — 약 **85배** 악화.
연간 전체를 범위 조건으로 걸면 사실상 테이블 전체를 읽어야 하는데, 인덱스를 강제하면
30만 건 전부를 `TABLE ACCESS BY INDEX ROWID`로 낱개 방문해야 해서 압도적으로
비효율적입니다. "배치 작업엔 인덱스보다 Full Scan이 나을 때가 있다"는 원칙이 이번엔
아주 극적으로 확인됐습니다.

**29.** "조인 후 GROUP BY"와 "`hosp_id`로 먼저 집계한 인라인 뷰 후 조인" 두 버전이
**Buffers=3106으로 동일**했습니다. `HOSPITALS`가 1000건뿐이라 이미 충분히 작아,
`MEDICAL_CLAIMS`(300,000건, 3090 버퍼)를 먼저 읽어야 하는 비용 자체는 어느 방식으로
써도 피할 수 없었기 때문입니다 — "조인 전 집계로 줄인다"는 기법은 **집계로 줄어드는
쪽이 조인 상대편보다 원래 더 컸을 때만** 의미가 있다는 것을 확인한 사례입니다.

**30.** 처음에 `COUNT(*)`로 감싸 측정했을 때는 두 버전이 완전히 동일했는데,
알고 보니 옵티마이저가 결과에 쓰이지 않는 스칼라 서브쿼리 SELECT 절 자체를
통째로 제거해버린 것이었습니다(실측 과정에서 발견한 함정 — 측정 방법 자체가
틀리면 잘못된 결론에 이를 수 있다는 교훈). `LENGTH()`로 감싸 실제 값을 쓰도록
재측정한 결과: 스칼라 서브쿼리 2개 버전 Buffers=**6063**(`hosp_name`용 서브쿼리
`Starts=2904`, `city`용 서브쿼리는 `Starts=50`으로 **같은 쿼리인데 캐시 히트율이
서로 다름** — 최종테스트 Q9의 "스칼라 서브쿼리 캐시 용량 한계"가 재확인됨과 동시에,
두 번째 서브쿼리는 첫 번째가 이미 캐시를 데워놓은 덕에 사실상 완전한 캐시 히트를
기록했습니다). 단일 `JOIN` 버전: Buffers=**3093** — 약 2배 개선. **컬럼이
여러 개 필요할 땐 스칼라 서브쿼리를 컬럼마다 반복하지 말고 JOIN 한 번으로 처리하는
것이 유리**하다는 원칙이 확인됐고, 덤으로 "COUNT(*)로 감싸면 실제 비용이 가려질 수
있다"는 실측 방법론상의 교훈도 얻었습니다.
