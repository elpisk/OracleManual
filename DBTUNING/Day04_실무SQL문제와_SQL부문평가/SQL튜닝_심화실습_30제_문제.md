# Oracle SQL 튜닝 심화 실습 30제

14개 챕터와 최종 종합 테스트(50제)를 마친 학습자를 위한 심화 문제입니다. 스키마는 기존
진료비청구심사 7개 테이블을 그대로 사용하며, 문제 형식은 실전 SQL 튜닝서에서 흔히 다루는
**"주어진 인덱스/쿼리/실행계획을 보고 직접 진단하고 고치는"** 유형으로 구성했습니다. 지금까지의
실습보다 한 단계 더 어렵습니다 — 정답이 하나로 정해져 있지 않고, 때로는 "정석 기법을 그대로
적용해도 개선되지 않는" 경우도 있습니다. **중요**: 이 문제집은 모범답안을 미리 정해두고
끼워맞춘 것이 아니라, 아래 모든 문항을 실습 DB(SQLT 계정)에서 실제로 실행해 나온
결과를 바탕으로 만들었습니다. 여러분이 실습할 때도 같은 결과가 나올 수도, 다를 수도
있습니다 — 그 자체가 학습 포인트입니다.

**공통 안내**: Oracle 전통 조인 문법(`FROM a, b WHERE`, 아우터 조인은 `(+)`)을 기준으로
작성하십시오. 인덱스를 새로 만드는 문항은 `IX_ADV_` 접두어를 쓰고, 실습 종료 후 반드시
`DROP INDEX`로 정리한 뒤 `USER_INDEXES`로 원상복구를 확인하십시오. 모든 문항은 직접 SQL을
작성·실행하고 `DBMS_XPLAN.DISPLAY_CURSOR(...'ALLSTATS LAST')` 또는 `V$SQL`로 측정한 값을
근거로 답해야 하는 실습형 문제이며, 서술형/암기형/객관식 문제는 없습니다.

---

## I. 인덱스 재설계 · 쿼리 재작성 (1~6번)

**1. [상]** 인덱스가 전혀 없는 상태에서 다음 쿼리는 `MEDICAL_CLAIMS`를 Full Scan한다.
**쿼리는 그대로 두고 인덱스만 추가**하여 성능을 개선하시오.

```sql
SELECT MAX(receipt_date)
FROM medical_claims
WHERE claim_type = '외래' AND review_status = '심사완료';
```

**2. [최상]** 이번엔 반대로, `medical_claims(receipt_date)` 단일 컬럼 인덱스 **하나만
존재하고 변경할 수 없는 상황**이다. 다음 쿼리를 인덱스는 그대로 둔 채 **쿼리만 재작성**하여
개선을 시도하시오(힌트: `INDEX_DESC` + `ROWNUM`/`FETCH FIRST` 조합으로 인덱스를 역순으로
훑다가 첫 매치에서 멈추는 기법이 교과서에 자주 소개된다).

```sql
SELECT MAX(receipt_date)
FROM medical_claims
WHERE claim_type = '입원' AND review_status = '심사중';
```

재작성한 쿼리를 실측하고, Buffers가 실제로 줄었는지 확인하시오. **줄지 않았다면 그 이유를
Predicate Information과 Operation을 근거로 설명하시오.**

**3. [최상]** 다음 3개의 쿼리를 모두 어느 정도 지원할 수 있는 `patients` 복합인덱스 하나를
설계하시오(컬럼과 순서를 직접 정하시오). 세 쿼리를 전부 실측해 Buffers를 비교하고,
인덱스가 모든 쿼리에 똑같이 유리하지는 않다는 것을 실측으로 보이시오.

```sql
-- (a)
SELECT * FROM patients
WHERE ins_type IN ('보훈','의료급여') AND city = '서울' AND gender = 'F'
AND pat_name LIKE 'K%' AND phone LIKE '%1%';

-- (b)
SELECT * FROM patients WHERE city = '기타' AND phone LIKE '%5%';

-- (c)
SELECT * FROM patients WHERE city = '서울' AND ins_type = '건강보험' AND gender = 'M';
```

**4. [최상]** 아래 인덱스와 쿼리에서, 인덱스의 2번째 컬럼(`review_status`)에는 조건이 없다.
"중간에 조건 없는 컬럼이 끼어 있으면 뒤 컬럼들이 access가 아니라 filter로 밀린다"는 통념이
이 경우에도 성립하는지 Predicate Information으로 직접 확인하시오. 그리고 컬럼 순서를
`(hosp_id, claim_type, receipt_date, review_status)`로 바꾼 버전과 Buffers를 비교하시오.

```sql
CREATE INDEX ix_adv_q4 ON medical_claims(hosp_id, review_status, claim_type, receipt_date);

SELECT claim_id, receipt_date, total_amt, claim_type, review_status, dept_code
FROM medical_claims
WHERE hosp_id IN (100,200,300)
AND claim_type = '외래'
AND receipt_date >= DATE'2024-01-01';
```

**5. [상]** 아래 인덱스는 선두 컬럼(`receipt_date`)에 조건이 전혀 없다. 이 쿼리의 실행계획을
확인하고, `(hosp_id, claim_type, review_status)` 순서로 다시 만든 인덱스와 Buffers를
비교하시오.

```sql
CREATE INDEX ix_adv_q5 ON medical_claims(receipt_date, hosp_id, claim_type, review_status);

SELECT pat_id, hosp_id, claim_type, review_status, total_amt
FROM medical_claims
WHERE hosp_id IN (100,200) AND claim_type = '외래' AND review_status = '심사완료';
```

**6. [최상]** `medical_claims(hosp_id)`와 `medical_claims(pat_id)` 두 개의 단일 컬럼
인덱스가 있는 상태에서 다음 OR 조건 쿼리를 실행하고, 실행계획에 `CONCATENATION`이
나타나는지 `BITMAP OR`가 나타나는지 직접 확인하시오. 어느 쪽이든, Operation Id별로 어떤
인덱스가 어떻게 결합되는지 설명하시오.

```sql
SELECT claim_id, hosp_id, pat_id, total_amt
FROM medical_claims WHERE hosp_id = 5 OR pat_id = 12345;
```

## II. 다중 테이블 조인 설계 (7~12번)

**7. [최상]** 다음 쿼리는 `NO_UNNEST` 힌트로 서브쿼리 언네스팅을 강제로 막고 있다.
힌트를 제거(또는 언네스팅이 되도록 재작성)한 버전과 Buffers를 비교하시오.

```sql
SELECT COUNT(*)
FROM medical_claims m
WHERE m.pat_id IN (SELECT /*+ NO_UNNEST */ pat_id FROM patients p
                    WHERE p.ins_type = '보훈' AND p.city = '서울')
AND m.claim_type = '입원';
```

**8. [최상]** `HOSPITALS`-`MEDICAL_CLAIMS`-`PATIENTS`-`CLAIM_DETAILS`-`DRUG_MASTER`
5개 테이블을 조인하는 다음 쿼리에 대해, 각 테이블에 인덱스를 설계하고 `LEADING`/`USE_NL`/
`USE_HASH` 힌트로 조인 순서와 방식을 직접 지정해보시오. 힌트 없이(옵티마이저가 스스로 고른
방식) 실행한 결과와 반드시 비교하시오 — **직접 설계한 쪽이 항상 더 낫다고 가정하지 말고
실측하시오.**

```sql
SELECT COUNT(*)
FROM hospitals h, medical_claims m, patients p, claim_details d, drug_master g
WHERE h.hosp_id = m.hosp_id
AND m.pat_id = p.pat_id
AND m.claim_id = d.claim_id
AND d.drug_code = g.drug_code
AND h.city IN ('서울','부산')
AND h.hosp_type = '종합병원'
AND p.gender = 'F'
AND p.ins_type IN ('건강보험','의료급여')
AND m.claim_type = '외래'
AND d.qty >= 2
AND g.category = '주사제';
```

**9. [최상]** `MEDICAL_CLAIMS`-`DISEASES`-`CLAIM_DETAILS`-`DRUG_MASTER` 4개 테이블
조인에 대해서도 8번과 동일한 방식으로 인덱스+힌트를 설계하고 옵티마이저의 기본 선택과
비교하시오.

```sql
SELECT COUNT(*)
FROM medical_claims m, diseases ds, claim_details d, drug_master g
WHERE m.claim_id = ds.claim_id
AND m.claim_id = d.claim_id
AND d.drug_code = g.drug_code
AND ds.dis_code = 'J00'
AND m.claim_type = '외래'
AND g.category = '내복약';
```

**10. [상]** `medical_claims(hosp_id)` 인덱스가 있는 상태에서, 아래 쿼리를
`LEADING(h m)`(작은 테이블이 드라이빙)과 `LEADING(m h)`(큰 테이블이 드라이빙) 두 버전으로
각각 실행해 Buffers를 비교하시오.

```sql
SELECT COUNT(*) FROM hospitals h, medical_claims m
WHERE h.hosp_id = m.hosp_id AND h.city = '서울';
```

**11. [최상]** 다음 상관 서브쿼리(자기 상관, `hosp_id`별 평균 대비 초과 청구 건수)를
분석함수(`AVG() OVER`)를 이용한 단일 스캔 방식으로 재작성하고 Buffers/A-Time을
비교하시오.

```sql
SELECT COUNT(*) FROM medical_claims m
WHERE m.total_amt > (SELECT AVG(m2.total_amt) FROM medical_claims m2 WHERE m2.hosp_id = m.hosp_id)
AND m.claim_type = '입원';
```

**12. [최상]** `review_log(claim_id)` 인덱스가 있는 상태에서, 다음 아우터 조인을 힌트
없이 실행한 결과와 `LEADING(m rl) USE_NL(rl)`로 강제한 결과를 비교하시오.

```sql
SELECT COUNT(*) FROM medical_claims m, review_log rl
WHERE m.claim_id = rl.claim_id(+) AND m.hosp_id <= 5;
```

## III. 서브쿼리·집합연산·메모리 최소화 (13~19번)

**13. [상]** 다음 `DISTINCT` 쿼리를 `EXISTS` 방식으로 재작성해 실행계획에서 별도의
`HASH UNIQUE`/`SORT UNIQUE` 단계가 사라지는지 확인하시오.

```sql
SELECT DISTINCT h.hosp_id, h.hosp_name FROM hospitals h, medical_claims m
WHERE h.hosp_id = m.hosp_id AND m.claim_type = '입원';
```

**14. [최상]** `hospitals(city)`, `medical_claims(hosp_id)`, `claim_details(claim_id,
qty)` 인덱스가 있는 상태에서, 다음 3-way 조인+`DISTINCT` 쿼리를 힌트 없이 실행한 결과와
`LEADING(h m d) USE_NL(m) USE_NL(d)`로 강제한 결과를 비교하시오.

```sql
SELECT DISTINCT h.hosp_name, m.claim_type FROM hospitals h, medical_claims m, claim_details d
WHERE h.hosp_id = m.hosp_id AND m.claim_id = d.claim_id AND h.city = '서울' AND d.qty >= 3;
```

**15. [최상]** 다음 `MINUS` 쿼리에 적절한 인덱스를 추가해 `SORT UNIQUE`가
`SORT UNIQUE NOSORT`로 바뀌거나 아예 생략되도록 만들고 Buffers를 비교하시오.

```sql
SELECT pat_id FROM patients WHERE city = '서울'
MINUS
SELECT pat_id FROM medical_claims WHERE claim_type = '입원';
```

**16. [상]** 같은 테이블을 두 번 스캔하는 다음 `UNION` 쿼리를, `OR` 조건 + `DISTINCT` 한
번의 스캔으로 재작성하고 Buffers를 비교하시오.

```sql
SELECT hosp_id FROM medical_claims WHERE claim_type = '입원'
UNION
SELECT hosp_id FROM medical_claims WHERE review_status = '심사중';
```

**17. [상]** 부서별 최고 청구 건을 찾는 다음 쿼리(테이블을 2번 스캔)를 `KEEP
(DENSE_RANK FIRST ORDER BY ...)` 집계 함수를 이용한 단일 스캔 방식으로 재작성하시오.

```sql
SELECT m.claim_id, m.dept_code, m.total_amt FROM medical_claims m
WHERE (m.dept_code, m.total_amt) IN (SELECT dept_code, MAX(total_amt) FROM medical_claims GROUP BY dept_code);
```

**18. [최상]** 특정 병원(`hosp_id=1`) 청구를 금액 순위로 매기는 다음 자기 조인(self-join)
쿼리를 `RANK() OVER` 분석함수로 재작성하시오. Buffers뿐 아니라 A-Time 차이도 함께
보고하시오.

```sql
SELECT a.claim_id, a.total_amt, COUNT(b.claim_id)+1 rnk
FROM medical_claims a, medical_claims b
WHERE a.total_amt < b.total_amt(+) AND a.hosp_id = 1 AND b.hosp_id(+) = 1
GROUP BY a.claim_id, a.total_amt;
```

**19. [최상]** 일별/월별/연도별 청구 합계를 인라인 뷰 3개로 조인하는 다음 쿼리(테이블을
3번 스캔)를, 윈도우 함수(`SUM() OVER`)를 이용한 단일 스캔 방식으로 재작성하시오.

```sql
SELECT a.yyyymmdd, a.day_total, b.month_total, c.year_total
FROM (SELECT TO_CHAR(receipt_date,'YYYYMMDD') yyyymmdd, SUM(total_amt) day_total FROM medical_claims
      WHERE receipt_date BETWEEN DATE'2024-01-01' AND DATE'2024-12-31' GROUP BY TO_CHAR(receipt_date,'YYYYMMDD')) a,
     (SELECT TO_CHAR(receipt_date,'YYYYMM') yyyymm, SUM(total_amt) month_total FROM medical_claims
      WHERE receipt_date BETWEEN DATE'2024-01-01' AND DATE'2024-12-31' GROUP BY TO_CHAR(receipt_date,'YYYYMM')) b,
     (SELECT TO_CHAR(receipt_date,'YYYY') yyyy, SUM(total_amt) year_total FROM medical_claims
      WHERE receipt_date BETWEEN DATE'2024-01-01' AND DATE'2024-12-31' GROUP BY TO_CHAR(receipt_date,'YYYY')) c
WHERE SUBSTR(a.yyyymmdd,1,6) = b.yyyymm(+) AND SUBSTR(a.yyyymmdd,1,4) = c.yyyy(+);
```

## IV. 페이징 · 동적 조건절 · ORDER BY 제거 (20~24번)

**20. [최상]** 다음은 3-way 아우터 조인 기반 페이징 쿼리(11~20번째 행)이다. 적절한
인덱스를 추가해 `COUNT STOPKEY`가 나타나도록 만들고 Buffers를 비교하시오.

```sql
SELECT b.*, ROWNUM rnum FROM (
  SELECT b.*, ROWNUM rnum FROM (
    SELECT m.claim_id, m.receipt_date, h.hosp_name, p.pat_name
    FROM medical_claims m, hospitals h, patients p
    WHERE m.hosp_id = h.hosp_id(+) AND m.pat_id = p.pat_id(+)
    AND m.claim_type = '외래' AND m.review_status = '심사완료'
    ORDER BY m.receipt_date
  ) b WHERE ROWNUM <= 20
) WHERE rnum >= 11;
```

**21. [최상]** `hosp_id`는 필수, `claim_type`/`dept_code`는 선택(옵션)인 다음 동적
조건절 쿼리를 바인드 변수로 두 번(옵션값 없음/있음) 실행해 실행계획이 분리되는지
확인하시오. 그리고 4가지 조합을 `UNION ALL`로 미리 분리해둔 버전을 실행해, 실제로
필요한 분기만 실행되는지(`Starts`)를 확인하시오.

```sql
SELECT COUNT(*) FROM medical_claims
WHERE hosp_id = :b_hosp
AND (:b_claimtype IS NULL OR claim_type = :b_claimtype)
AND (:b_dept IS NULL OR dept_code = :b_dept);
```

**22. [상]** `medical_claims(hosp_id)` 단일 컬럼 인덱스만 있는 상태에서 다음 쿼리는
`SORT ORDER BY`가 나타난다. 인덱스를 `(hosp_id, receipt_date, claim_type)`로 재설계해
정렬이 제거되는지 확인하시오. **제거되지 않는다면 왜 그런지 Predicate Information과
Operation을 근거로 설명하시오.**

```sql
SELECT claim_id, receipt_date, claim_type
FROM medical_claims WHERE hosp_id = 10 ORDER BY receipt_date, claim_type;
```

**23. [최상]** `medical_claims(hosp_id, receipt_date)` 인덱스가 있는 상태에서, 다음
조인 쿼리를 `LEADING(p m)`과 `LEADING(m p)` 두 방향으로 실행해 `SORT ORDER BY`가
생기는지 비교하시오. 실행계획에 `PATIENTS` 접근이 실제로 나타나는지도 함께 확인하시오.

```sql
SELECT m.claim_id, m.receipt_date FROM patients p, medical_claims m
WHERE p.pat_id = m.pat_id AND m.hosp_id = 10
ORDER BY m.receipt_date;
```

**24. [상]** `medical_claims(review_status, receipt_date)` 인덱스가 있는 상태에서,
흔한 값(`review_status='심사완료'`, 약 90%)과 드문 값(`review_status='심사중'`, 약
10%)으로 각각 조회해 Operation이 어떻게 달라지는지, Buffers가 몇 배 차이 나는지
비교하시오.

```sql
SELECT COUNT(*) FROM medical_claims
WHERE review_status = :status AND receipt_date >= DATE'2024-06-01';
```

## V. 진단형 종합 문제 (25~30번)

**25. [상]** `medical_claims(hosp_id)` 인덱스가 있는 상태에서, `IN`(20개 리터럴 나열)
버전과 동일한 범위를 뜻하는 `BETWEEN` 버전을 비교해 `INLIST ITERATOR`의 `Starts` 값과
Buffers 차이를 실측하시오.

**26. [최상]** `medical_claims(receipt_date)` 인덱스가 있는 상태에서, 필터 조건이
없는 `ORDER BY receipt_date DESC FETCH FIRST 5 ROWS ONLY`와, `claim_type='입원'`
필터가 추가된 버전을 각각 실행하시오. 두 경우 모두 인덱스를 이용한 부분범위처리
(`INDEX ... DESCENDING` + `COUNT STOPKEY`류)가 나타나는지, 아니면 다른 방식이
선택되는지 확인하고 그 이유를 설명하시오.

**27. [상]** `claim_details(claim_id)` 인덱스가 있는 상태에서, 조인 조건에
`TO_CHAR(m.claim_id) = d.claim_id`처럼 불필요한 함수를 씌운 버전과 씌우지 않은 버전을
비교하시오. Chapter 6에서 배운 "조인/필터 컬럼에 함수를 씌우면 인덱스를 못 쓴다"는
원칙이 이 경우에도 그대로 적용되는지 확인하시오.

**28. [최상]** `medical_claims(receipt_date)` 인덱스가 있는 상태에서, 연간 전체
데이터를 대상으로 한 배치성 집계 쿼리를 힌트 없이 실행한 결과와, `INDEX(m ...)` 힌트로
인덱스 사용을 강제한 결과를 비교하시오. 배치 작업에서 인덱스 강제가 항상 유리하지는
않다는 것을 실측으로 보이시오.

```sql
SELECT SUM(total_amt) FROM medical_claims
WHERE receipt_date BETWEEN DATE'2024-01-01' AND DATE'2024-12-31';
```

**29. [최상]** 병원 도시별 청구 총액을 구하는 다음 쿼리를, "조인 먼저 → GROUP BY"
버전과 "`medical_claims`를 `hosp_id`로 먼저 집계한 인라인 뷰를 만든 뒤 → 작은 결과와
조인" 버전 두 가지로 작성해 Buffers를 비교하시오.

```sql
SELECT h.city, SUM(m.total_amt) FROM hospitals h, medical_claims m
WHERE h.hosp_id = m.hosp_id GROUP BY h.city;
```

**30. [최상]** 다음처럼 SELECT 절에 같은 상관 조건의 스칼라 서브쿼리를 2개(컬럼마다
하나씩) 쓴 버전과, 하나의 `JOIN`으로 두 컬럼을 한 번에 가져오는 버전을 비교하시오.
`Starts` 값을 근거로 스칼라 서브쿼리 캐시가 두 서브쿼리에 대해 동일한 효율을 내는지도
확인하시오.

```sql
SELECT m.claim_id,
  (SELECT h.hosp_name FROM hospitals h WHERE h.hosp_id = m.hosp_id) hosp_name,
  (SELECT h.city FROM hospitals h WHERE h.hosp_id = m.hosp_id) city
FROM medical_claims m WHERE m.hosp_id <= 50;
```
