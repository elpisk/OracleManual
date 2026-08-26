# 진료비 청구 및 심사 시스템 — SQL 고급 활용 실습문제 50제 · 해설 및 모범답안

`진료비청구심사_SQL고급활용_문제_50제.md`와 문제 번호가 1:1로 대응합니다. 모든 SQL은
**Oracle 전통(원본) 조인 문법**만 사용합니다 — `JOIN`, `LEFT JOIN`, `ON` 같은 ANSI SQL:99
구문은 쓰지 않고, `FROM`절에 테이블을 콤마로 나열한 뒤 `WHERE`절에 조인 조건을 적으며,
아우터 조인은 `(+)` 연산자로 표현합니다.

> **데이터 특성 안내**: 이 스키마의 데이터는 `DBMS_RANDOM`으로 대량 생성되어 실행마다 값이
> 달라집니다. 따라서 해설의 "예상 결과"는 정확한 행 단위 계산이 아니라 편중 비율 기반의
> **추정치·구조 설명**이거나, 형식만 보여주는 **예시(실제 값과 다를 수 있음)**입니다.
> 뷰/시퀀스 생성 문항의 "결과"는 쿼리 결과 대신 생성 성공 메시지로 대체합니다.
> 각 해설은 (a) 사용 개념, (b) 방식 선택 이유/대안, (c) 흔한 실수·ORA 에러, (d) 실무 주의사항
> 순으로 서술합니다.

---

## Oracle 전통 조인 문법 요약 (첫 등장 시 필독)

| 구분 | ANSI 문법 (사용 안 함) | Oracle 전통 문법 (이 문서에서 사용) |
|---|---|---|
| 내부 조인 | `FROM a JOIN b ON a.id=b.id` | `FROM a, b WHERE a.id = b.id` |
| 왼쪽(외부) 조인 | `FROM a LEFT JOIN b ON a.id=b.id` | `FROM a, b WHERE a.id = b.id(+)` — `(+)`는 **결측(행 없음)을 허용할 쪽**(b)에 붙인다 |
| 조인 + 추가 필터 | `... ON a.id=b.id AND b.col='X'` | `WHERE a.id = b.id(+) AND b.col(+) = 'X'` — 아우터 대상 테이블 컬럼 필터에도 **`(+)`를 붙여야** 결측 행이 보존된다 |

**`(+)` 연산자 제약 (반드시 기억)**
- `(+)`는 조인의 **한쪽에만** 붙일 수 있다. 양쪽에 붙이면 `ORA-01468: a predicate may
  reference only one outer-joined table` 오류가 나고, FULL OUTER JOIN은 이 문법으로 표현 불가
  (두 쿼리를 `UNION`으로 합쳐야 함).
- `(+)`가 붙은 컬럼은 **서브쿼리·`IN` 리스트·`OR`로 연결된 조건**과 함께 쓸 수 없다.
- 아우터 대상 테이블 필터에서 `(+)`를 빠뜨리면 보존됐던 NULL 행이 그 필터에서 다시 걸러져
  결과적으로 INNER JOIN과 같아진다(대표적 실수).

---

# Ⅰ. 다중 테이블 조인 (1~8번)

## 1. [상] 4-테이블 등가 조인 — 서울 종합병원의 주사제 내역

```sql
SELECT h.hosp_name, c.claim_id, d.drug_name, cd.amt
FROM   hospitals h, medical_claims c, claim_details cd, drug_master d
WHERE  h.hosp_id   = c.hosp_id
AND    c.claim_id  = cd.claim_id
AND    cd.drug_code = d.drug_code
AND    h.city      = '서울'
AND    h.hosp_type = '종합병원'
AND    d.category  = '주사제'
AND    c.receipt_date >= DATE '2024-01-01'
AND    c.receipt_date <  DATE '2025-01-01'
ORDER  BY cd.amt DESC;
```

**예상 결과 (예시이며 실제 값은 다를 수 있음)**

| HOSP_NAME | CLAIM_ID | DRUG_NAME | AMT |
|---|---|---|---|
| 요양기관_20 | 20240712-0123456 | 약품_842 | 269,730 |
| ... | ... | ... | ... |

**해설**
- (a) 개념: 네 테이블을 콤마로 나열하고 인접한 FK 조인 조건 3개(`h~c`, `c~cd`, `cd~d`)를
  `AND`로 이은 전형적 등가 조인. N개 테이블을 조인하려면 조인 조건이 최소 N−1개 필요하다.
- (b) 이유/대안: 날짜 조건을 `>= '2024-01-01' AND < '2025-01-01'`로 쓴 것은 컬럼에 함수를
  씌우지 않아(예: `TO_CHAR(receipt_date,'YYYY')='2024'`) 인덱스 활용 여지를 남기기 위함.
- (c) 실수/ORA: 조인 조건을 하나라도 빠뜨리면 카티션 곱(Cartesian product)이 발생해 행이
  폭증한다. 각 테이블 컬럼에 별칭을 붙이지 않으면 동명 컬럼에서 `ORA-00918: column ambiguously
  defined`가 난다.
- (d) 실무: '종합병원'(약 4%) + '서울'(HOSP_ID 1~400) + '주사제'(약 10%)로 필터가 강해 결과가
  많지 않다. 상세내역(백만 건)이 가장 큰 테이블이므로 조인 순서상 필터로 먼저 줄이는 게 유리하다.

## 2. [상] 4-테이블 등가 조인 — 주상병 감기(J00) 청구

```sql
SELECT h.hosp_name, p.pat_name, c.dept_code, c.receipt_date, c.total_amt
FROM   hospitals h, patients p, medical_claims c, diseases ds
WHERE  c.hosp_id  = h.hosp_id
AND    c.pat_id   = p.pat_id
AND    c.claim_id = ds.claim_id
AND    ds.dis_type = '1'
AND    ds.dis_code = 'J00'
AND    c.receipt_date >= DATE '2024-02-01'
AND    c.receipt_date <  DATE '2024-03-01'
ORDER  BY c.receipt_date;
```

**해설**
- (a) 개념: HOSPITALS·PATIENTS·MEDICAL_CLAIMS·DISEASES 4-테이블 등가 조인. DISEASES는 청구당
  주상병 1건이 항상 존재하므로 내부 조인으로 충분하다.
- (b) 이유/대안: `ds.dis_type='1'`을 걸어 주상병만 본다. 이 조건이 없으면 부상병도 J00일 때
  중복 매칭될 수 있다(부상병은 M코드만 생성되지만 방어적으로 명시).
- (c) 실수: DISEASES 조인 조건을 빼면 한 청구에 상병이 여러 건일 때 청구 행이 상병 수만큼
  복제된다.
- (d) 실무: 'J00'은 전체 주상병의 약 30%로 흔하다. 2월 한 달로 한정했어도 대형병원 스큐 탓에
  결과가 상당수 나온다.

## 3. [상] 아우터 조인 + 필터에 `(+)` — 부상병 포함 조회

```sql
SELECT c.claim_id, c.dept_code, ds.dis_code
FROM   medical_claims c, diseases ds
WHERE  c.claim_id = ds.claim_id(+)
AND    ds.dis_type(+) = '2'
AND    c.claim_id LIKE '20240103%'
ORDER  BY c.claim_id;
```

**해설**
- (a) 개념: 부상병이 없는 청구서도 보존해야 하므로 DISEASES 쪽에 `(+)`를 붙인 왼쪽 아우터
  조인. 핵심은 필터 `dis_type='2'`에도 `(+)`를 붙였다는 점.
- (b) 왜 필터에도 `(+)`인가: `(+)`를 빼고 `AND ds.dis_type='2'`로 쓰면, 아우터로 보존됐던 NULL
  행(부상병 없는 청구)이 이 조건에서 다시 탈락해 INNER JOIN과 같아진다.
- (c) ORA/제약: `(+)`는 한쪽에만, 서브쿼리·`IN`·`OR`와 함께 못 쓴다. `LIKE '20240103%'`는
  MEDICAL_CLAIMS(보존 대상) 컬럼이므로 `(+)`를 붙이지 않는다.
- (d) 실무: 부상병은 약 33% 확률로만 존재하므로 결과 다수 행의 DIS_CODE가 NULL로 나오는 것이
  정상이다.

## 4. [상] 셀프 조인 — 주상병·부상병 동시 기재 청구

```sql
SELECT d1.claim_id,
       d1.dis_code AS main_dis,
       d2.dis_code AS sub_dis
FROM   diseases d1, diseases d2
WHERE  d1.claim_id = d2.claim_id
AND    d1.dis_type = '1'
AND    d2.dis_type = '2'
AND    d1.claim_id LIKE '20240105%'
ORDER  BY d1.claim_id;
```

**해설**
- (a) 개념: 같은 DISEASES 테이블에 두 별칭(d1, d2)을 주어 자기 자신과 조인하는 **셀프 조인**.
  같은 CLAIM_ID를 공유하되 한쪽은 주상병, 다른 쪽은 부상병인 행을 짝짓는다.
- (b) 이유/대안: 부상병이 있는 청구만 자연스럽게 걸러진다(내부 조인이므로 d2가 없으면 탈락).
  "부상병 없는 청구도 보고 싶다"면 3번처럼 `(+)` 아우터 조인을 써야 한다.
- (c) 실수: `d1.claim_id = d2.claim_id`만 쓰고 dis_type 조건을 빼면 (주상병,주상병) 자기
  자신까지 매칭된다.
- (d) 실무: 부상병은 청구당 최대 1건이므로 결과가 청구당 1행이지만, 만약 부상병이 여러 건인
  스키마라면 카티션처럼 행이 곱해진다.

## 5. [최상] 복합 아우터 조인 — 반려 로그 + 부상병 동시 아우터

```sql
SELECT c.claim_id, p.pat_name, r.error_code, ds.dis_code
FROM   medical_claims c, patients p, review_log r, diseases ds
WHERE  c.pat_id   = p.pat_id
AND    c.claim_id = r.claim_id(+)
AND    r.error_code(+) BETWEEN 'E10' AND 'E99'
AND    c.claim_id = ds.claim_id(+)
AND    ds.dis_type(+) = '2'
AND    c.hosp_id  = 1
AND    c.receipt_date >= DATE '2024-01-01'
AND    c.receipt_date <  DATE '2024-02-01'
ORDER  BY c.claim_id;
```

**해설**
- (a) 개념: PATIENTS는 내부 조인, REVIEW_LOG와 DISEASES는 각각 독립적인 왼쪽 아우터 조인.
  두 아우터 대상 테이블의 필터(`error_code`, `dis_type`)에 모두 `(+)`를 붙였다.
- (b) 이유/대안: 두 아우터를 동시에 걸면 한 청구에 반려 로그가 2건, 부상병이 1건일 때
  2×1=2행으로 **행이 곱해진다(카티션 팽창)**. 이 곱 효과가 싫으면 각 아우터를 인라인 뷰에서
  미리 1행으로 집계(예: `MAX(error_code)`)한 뒤 조인해야 한다.
- (c) ORA: 한 술어에서 두 아우터 테이블을 함께 참조하면 `ORA-01417: a table may be outer
  joined to at most one other table`가 날 수 있다. 각 아우터 조인은 서로 독립된 술어로 둘 것.
- (d) 실무: HOSP_ID=1은 최대 스큐 병원이라 1월 청구가 수백 건. 아우터 곱 팽창을 감안해 대상을
  좁게 잡았다.

## 6. [상] 등가 + 비등가(non-equi) 조인 — 단가 상한 초과

```sql
SELECT cd.claim_id, cd.drug_code, d.drug_name,
       cd.unit_price, d.price, cd.unit_price - d.price AS over_amt
FROM   claim_details cd, drug_master d
WHERE  cd.drug_code = d.drug_code
AND    cd.unit_price > d.price
ORDER  BY over_amt DESC;
```

**해설**
- (a) 개념: DRUG_CODE로 등가 조인하면서 `cd.unit_price > d.price`라는 **비등가 조인 조건**을
  함께 건 형태. 등가·비등가 조건을 섞어 쓰는 전형적 심사(삭감 후보) 쿼리.
- (b) 이유/대안: 단가가 상한금액을 넘은 상세내역을 골라낸다. 데이터 생성 로직상 UNIT_PRICE는
  100~9,999, PRICE는 100~50,000이라 초과 건이 일부만 존재한다.
- (c) 실수: `cd.drug_code = d.drug_code` 등가 조건을 빼고 비등가만 남기면 카티션 곱이 된다.
- (d) 실무: 실제 심사에서 "청구 단가 > 고시 상한가"는 자동 삭감 대상 로직. 인덱스가 없으면
  대용량 상세내역 풀스캔이므로 기간·병원 등 선행 필터를 추가하는 것이 안전하다.

## 7. [상] 아우터 조인 + COUNT/NVL — 청구 없는 환자 포함 Top-N

```sql
SELECT *
FROM  (SELECT p.pat_id,
              p.pat_name,
              p.ins_type,
              COUNT(c.claim_id)          AS claim_cnt,
              NVL(SUM(c.total_amt), 0)   AS total_amt_sum
       FROM   patients p, medical_claims c
       WHERE  p.pat_id = c.pat_id(+)
       GROUP  BY p.pat_id, p.pat_name, p.ins_type
       ORDER  BY claim_cnt ASC, p.pat_id)
WHERE  ROWNUM <= 20;
```

**해설**
- (a) 개념: MEDICAL_CLAIMS 쪽에 `(+)`를 붙여 청구가 없는 환자도 보존하는 아우터 조인 +
  그룹 집계. `COUNT(c.claim_id)`는 NULL을 세지 않으므로 매칭 청구가 없으면 자동으로 0이 된다.
- (b) 왜 COUNT(*)가 아닌가: `COUNT(*)`를 쓰면 아우터로 생긴 NULL 행도 1로 세어 청구 없는
  환자가 0이 아니라 1로 나온다 — 반드시 `COUNT(조인상대_컬럼)`을 써야 한다. 반면 `SUM`은
  대상이 전부 NULL이면 0이 아니라 **NULL**을 반환하므로 `NVL(SUM(c.total_amt),0)`로 감싸야
  한다. 이 문제는 결과 상단이 실제로 청구 0건 환자로 채워지므로 `NVL`이 실제로 발동한다.
- (c) 실수: `ROWNUM`을 인라인 뷰 안(정렬 전)에 걸면 임의의 20건을 먼저 뽑고 정렬하게 되어
  오답이다 — 정렬은 인라인 뷰 안에서, `ROWNUM <= 20`은 반드시 바깥에서. `GROUP BY`에 SELECT의
  비집계 컬럼(pat_name, ins_type)을 빠뜨리면 `ORA-00979: not a GROUP BY expression`.
  12c 이상이면 인라인 뷰 대신 `ORDER BY ... FETCH FIRST 20 ROWS ONLY`로도 가능하다.
- (d) 결과 규모(근거): MEDICAL_CLAIMS 300,000건의 PAT_ID는 1~50,000에 균등 무작위로 배정되어
  환자 1인당 평균 청구는 300,000 / 50,000 = **6건**이고, 한 건도 배정되지 않을 확률은
  (1 − 1/50,000)^300,000 ≈ e⁻⁶ ≈ 0.0025다. 즉 청구 0건 환자가 50,000 × 0.0025 ≈
  **약 120~130명 내외** 존재하므로 상위 20행은 전부 `claim_cnt = 0`, `total_amt_sum = 0`으로
  채워진다. `DBMS_RANDOM` 시드에 따라 정확한 수는 매번 달라지므로,
  `SELECT COUNT(*) FROM patients` − `SELECT COUNT(DISTINCT pat_id) FROM medical_claims`로
  0건 환자 수를 검산한다. (같은 집계를 HOSPITALS로 하면 병원당 평균 청구가 158건 이상이라
  0건 병원이 나올 확률이 e⁻¹⁵⁸ — 아우터 조인이 이너 조인과 같은 결과를 내고 `NVL`도 한 번도
  발동하지 않는다.)

## 8. [최상] 6-테이블 등가 조인 — 서울 상급종합 입원 상세

```sql
SELECT h.hosp_name, p.pat_name, ds.dis_code, d.drug_name, cd.amt
FROM   hospitals h, medical_claims c, patients p,
       diseases ds, claim_details cd, drug_master d
WHERE  c.hosp_id   = h.hosp_id
AND    c.pat_id    = p.pat_id
AND    c.claim_id  = ds.claim_id
AND    c.claim_id  = cd.claim_id
AND    cd.drug_code = d.drug_code
AND    ds.dis_type = '1'
AND    h.city      = '서울'
AND    h.hosp_type = '상급종합'
AND    c.claim_type = '입원'
ORDER  BY cd.amt DESC;
```

**해설**
- (a) 개념: 6개 테이블, 5개 조인 조건(각 인접 관계 1개)을 이은 대형 등가 조인. MEDICAL_CLAIMS를
  중심(허브)으로 나머지 테이블이 방사형으로 붙는다.
- (b) 이유/대안: `ds.dis_type='1'`로 주상병 1건만 매칭해 상병 다중으로 인한 행 복제를 억제
  했다. 그래도 한 청구에 상세내역이 여러 건이면 (청구×상세) 조합으로 행이 늘어난다 — 이는
  "상세별 금액을 보는" 리포트의 의도된 동작.
- (c) 실수: 조인 조건 5개 중 하나라도 누락하면 대용량 카티션 곱으로 세션이 사실상 멈춘다.
  상급종합은 약 1% + 서울 + 입원 필터로 대상이 극히 좁아 실습에 안전하다.
- (d) 실무: 이렇게 넓은 조인은 필터로 상위 집합(병원·기간)을 먼저 좁히는 것이 성능의 핵심이다.

---

# Ⅱ. 그룹 함수 심화 (9~15번)

## 9. [상] GROUP BY + 복합 HAVING

```sql
SELECT h.hosp_id, h.hosp_name,
       COUNT(*) AS claim_cnt,
       ROUND(AVG(c.total_amt)) AS avg_amt
FROM   hospitals h, medical_claims c
WHERE  h.hosp_id = c.hosp_id
GROUP  BY h.hosp_id, h.hosp_name
HAVING COUNT(*) >= 200
AND    AVG(c.total_amt) >= 300000
ORDER  BY claim_cnt DESC;
```

**해설**
- (a) 개념: 그룹 집계 결과에 조건을 거는 `HAVING`에 두 집계 조건을 `AND`로 결합.
- (b) 이유/대안: 행 필터는 `WHERE`, 그룹 필터는 `HAVING`. `COUNT(*)>=200`을 `WHERE`에 쓸 수
  없다(집계는 그룹이 만들어진 뒤 평가되기 때문).
- (c) 실수: `WHERE COUNT(*) >= 200`처럼 쓰면 `ORA-00934: group function is not allowed here`.
- (d) 실무: 청구건수 200 이상은 사실상 대형병원(1~50)에 집중되므로 상위권은 대형병원 위주로
  나온다.

## 10. [상] HAVING + 서브쿼리(전체 평균 비교)

```sql
SELECT c.dept_code,
       COUNT(*) AS claim_cnt,
       ROUND(AVG(c.total_amt)) AS avg_amt
FROM   medical_claims c
GROUP  BY c.dept_code
HAVING AVG(c.total_amt) > (SELECT AVG(total_amt) FROM medical_claims)
ORDER  BY avg_amt DESC;
```

**해설**
- (a) 개념: 그룹별 평균을 전체 평균(스칼라 서브쿼리)과 비교하는 HAVING.
- (b) 이유/대안: 전체 평균은 그룹과 무관한 단일 값이라 서브쿼리로 한 번 계산한다. `WITH`로
  빼도 되지만 이 규모에선 스칼라 서브쿼리가 간결하다.
- (c) 실수: HAVING에 컬럼 별칭(avg_amt)을 쓰면 `ORA-00904`(HAVING은 별칭 인식 못 함) — 집계식을
  그대로 반복해야 한다.
- (d) 실무: DEPT_CODE는 'D1'~'D9'로 균등 분포라 평균 차이가 크지 않아 절반가량 진료과가
  걸린다.

## 11. [최상] ROLLUP + GROUPING 라벨링

```sql
SELECT DECODE(GROUPING(c.claim_type), 1, '전체합계', c.claim_type)   AS claim_type,
       DECODE(GROUPING(c.review_status), 1,
              DECODE(GROUPING(c.claim_type), 1, '', '유형합계'),
              c.review_status)                                        AS review_status,
       COUNT(*)          AS claim_cnt,
       SUM(c.total_amt)  AS sum_amt
FROM   medical_claims c
GROUP  BY ROLLUP(c.claim_type, c.review_status)
ORDER  BY GROUPING(c.claim_type), c.claim_type, GROUPING(c.review_status);
```

**해설**
- (a) 개념: `ROLLUP(a,b)`는 (a,b) 상세 → (a) 소계 → () 총계의 계층 소계를 만든다. `GROUPING(col)`은
  그 컬럼이 소계로 집계돼 NULL이 된 자리에 1을 돌려줘 "진짜 NULL"과 "소계 자리 NULL"을 구분한다.
- (b) 이유/대안: 라벨링에 `DECODE(GROUPING(...),1,'합계',원값)` 패턴을 썼다. `CASE WHEN
  GROUPING(...)=1 THEN ... END`로도 동일하게 쓸 수 있다.
- (c) 실수: `GROUPING` 없이 소계 행을 그냥 두면 NULL로 보여 실제 NULL 값과 헷갈린다. ROLLUP
  컬럼 순서를 바꾸면 소계의 의미가 달라진다(대칭 아님).
- (d) 실무: 유형(입원/외래)×상태(심사중/심사완료) 4조합 + 유형 소계 2행 + 총계 1행 = 7행 내외.

## 12. [최상] CUBE + GROUPING_ID

```sql
SELECT DECODE(GROUPING(h.hosp_type), 1, '전체', h.hosp_type)  AS hosp_type,
       DECODE(GROUPING(p.ins_type),  1, '전체', p.ins_type)   AS ins_type,
       CASE GROUPING_ID(h.hosp_type, p.ins_type)
            WHEN 0 THEN '상세'
            WHEN 1 THEN '유형별소계'
            WHEN 2 THEN '보험별소계'
            WHEN 3 THEN '전체합계'
       END                AS grp_level,
       COUNT(*)           AS claim_cnt,
       SUM(c.total_amt)   AS sum_amt
FROM   hospitals h, medical_claims c, patients p
WHERE  c.hosp_id = h.hosp_id
AND    c.pat_id  = p.pat_id
GROUP  BY CUBE(h.hosp_type, p.ins_type)
ORDER  BY GROUPING_ID(h.hosp_type, p.ins_type), h.hosp_type, p.ins_type;
```

**해설**
- (a) 개념: `CUBE(a,b)`는 (a,b),(a),(b),() 모든 부분집합 소계를 만든다. `GROUPING_ID(a,b)`는
  각 컬럼의 GROUPING 비트를 이진수로 합쳐(2*g(a)+g(b)) 집계 수준을 0~3의 한 숫자로 준다.
- (b) 이유/대안: 컬럼이 2개면 `GROUPING_ID`로 4단계를 한 번에 분기하는 게 `GROUPING` 2개를
  중첩 DECODE하는 것보다 깔끔하다.
- (c) 실수: `GROUPING_ID`의 비트 순서(왼쪽 인자가 상위 비트)를 헷갈리면 라벨이 뒤바뀐다.
- (d) 실무: 유형 4종 × 보험 3종 = 최대 12 상세 + 소계들. '상급종합×보훈'처럼 희소 조합은 건수가
  매우 작게 나온다.

## 13. [최상] GROUPING SETS — 세 축 개별 집계

```sql
SELECT h.city, h.hosp_type, c.dept_code, COUNT(*) AS claim_cnt
FROM   hospitals h, medical_claims c
WHERE  c.hosp_id = h.hosp_id
GROUP  BY GROUPING SETS ( (h.city), (h.hosp_type), (c.dept_code) )
ORDER  BY GROUPING(h.city), GROUPING(h.hosp_type), GROUPING(c.dept_code);
```

**해설**
- (a) 개념: `GROUPING SETS`는 원하는 그룹 조합만 정확히 지정한다. 여기서는 지역별·유형별·
  진료과별 세 집계를 한 결과 집합으로 세로로 쌓는다.
- (b) 이유/대안: `CUBE(city,hosp_type,dept_code)`는 8개 조합을 다 만들어 불필요한 교차 소계가
  생긴다. 필요한 3개 그룹만 원하면 `GROUPING SETS`가 정답. (실제로 ROLLUP/CUBE도 내부적으로는
  GROUPING SETS로 표현된다.)
- (c) 실수: 각 세트를 `(city)`처럼 괄호로 감싸지 않고 `city, hosp_type`으로 쓰면 "그 조합"
  하나가 돼 의미가 달라진다.
- (d) 실무: 각 그룹의 비집계 컬럼 자리는 NULL로 채워지므로, 어느 축의 집계인지 구분하려면
  `GROUPING()`으로 라벨을 붙이는 것이 좋다.

## 14. [상] ROLLUP + GROUPING_ID 라벨링(월×유형)

```sql
SELECT TO_CHAR(c.receipt_date, 'YYYY-MM')  AS ym,
       h.hosp_type,
       GROUPING_ID(TO_CHAR(c.receipt_date,'YYYY-MM'), h.hosp_type) AS gid,
       CASE GROUPING_ID(TO_CHAR(c.receipt_date,'YYYY-MM'), h.hosp_type)
            WHEN 0 THEN '월+유형상세'
            WHEN 1 THEN '월 소계'
            WHEN 3 THEN '총계'
       END                 AS label,
       SUM(c.total_amt)    AS sum_amt
FROM   hospitals h, medical_claims c
WHERE  c.hosp_id = h.hosp_id
GROUP  BY ROLLUP(TO_CHAR(c.receipt_date,'YYYY-MM'), h.hosp_type)
ORDER  BY ym NULLS LAST, GROUPING(h.hosp_type);
```

**해설**
- (a) 개념: 월과 유형으로 `ROLLUP` → (월,유형) 상세 / (월) 소계 / 총계. `GROUPING_ID`로 세
  수준(0/1/3)을 분기해 라벨링. (ROLLUP은 2가 생기지 않으므로 CASE에 2는 없다.)
- (b) 이유/대안: 월을 `TO_CHAR(...,'YYYY-MM')`로 만들되 GROUP BY와 SELECT에 **동일 표현식**을
  써야 한다.
- (c) 실수: 정렬 시 소계/총계의 월이 NULL이라 `NULLS LAST`를 주지 않으면 소계가 위로 올라와
  가독성이 떨어진다.
- (d) 실무: 12개월 × 4유형 상세 + 월 소계 12 + 총계 1로 60행 내외의 소계 리포트가 된다.

## 15. [최상] 조건부 집계(수동 피벗)

```sql
SELECT c.hosp_id,
       SUM(CASE WHEN c.claim_type='입원' THEN 1 ELSE 0 END)          AS in_cnt,
       SUM(CASE WHEN c.claim_type='외래' THEN 1 ELSE 0 END)          AS out_cnt,
       COUNT(CASE WHEN c.review_status='심사중' THEN 1 END)          AS ing_cnt,
       COUNT(CASE WHEN c.review_status='심사완료' THEN 1 END)        AS done_cnt,
       SUM(CASE WHEN c.claim_type='입원' THEN c.total_amt ELSE 0 END) AS in_amt
FROM   medical_claims c
GROUP  BY c.hosp_id
ORDER  BY (in_cnt + out_cnt) DESC;
```

**해설**
- (a) 개념: `SUM(CASE ...)` / `COUNT(CASE ...)`로 한 번의 GROUP BY에서 여러 조건별 집계를 각
  컬럼으로 펼치는 **조건부 집계(수동 피벗)**.
- (b) 이유/대안: `PIVOT` 절로도 가능하지만, 조건이 다양하고(유형/상태 혼합) 값 집계식이 다를
  때는 조건부 집계가 더 유연하다. `COUNT(CASE WHEN 조건 THEN 1 END)`는 else를 NULL로 둬 COUNT가
  세지 않게 하는 관용구.
- (c) 실수: `COUNT(CASE WHEN 조건 THEN 1 ELSE 0 END)`처럼 else에 0을 주면 0도 값이라 전부 세어
  버린다 — COUNT엔 else를 생략, SUM엔 else 0.
- (d) 실무: 이런 요약 컬럼 집합은 대시보드/엑셀 다운로드에 그대로 쓰인다. 상위 정렬로 대형병원이
  먼저 온다.

---

# Ⅲ. 서브쿼리 전 유형 (16~23번)

## 16. [상] 중첩 단일행 서브쿼리 — 최고액 청구 병원

```sql
SELECT h.hosp_id, h.hosp_name, h.city, h.hosp_type
FROM   hospitals h
WHERE  h.hosp_id = (
         SELECT hosp_id
         FROM   medical_claims
         WHERE  total_amt = (SELECT MAX(total_amt) FROM medical_claims)
         AND    ROWNUM = 1
       );
```

**해설**
- (a) 개념: 최댓값을 구하는 서브쿼리를 다시 감싼 **중첩 단일행 서브쿼리**. 안쪽에서 MAX 금액을
  찾고, 그 금액의 HOSP_ID를 바깥에서 사용.
- (b) 이유/대안: `total_amt = MAX`가 여러 청구일 수 있어 `ROWNUM=1`로 한 건만 취했다. "동점을
  모두 보려면" `=` 대신 `IN`을 쓰고 ROWNUM을 빼야 한다(다중행 서브쿼리로 전환).
- (c) 실수: `ROWNUM=1` 없이 다건이 반환되면 상위 `=` 비교에서 `ORA-01427: single-row subquery
  returns more than one row`.
- (d) 실무: 최고액 청구서는 상세내역이 많은(5건) 고단가 조합에서 나온다.

## 17. [상] 다중행 서브쿼리(IN) — 입원 병원의 외래 청구

```sql
SELECT c.claim_id, c.hosp_id, c.total_amt
FROM   medical_claims c
WHERE  c.claim_type = '외래'
AND    c.receipt_date >= DATE '2024-12-01'
AND    c.receipt_date <  DATE '2025-01-01'
AND    c.hosp_id IN (
         SELECT hosp_id
         FROM   medical_claims
         WHERE  claim_type = '입원'
         AND    receipt_date >= DATE '2024-12-01'
         AND    receipt_date <  DATE '2025-01-01'
       )
ORDER  BY c.total_amt DESC;
```

**해설**
- (a) 개념: 서브쿼리가 여러 HOSP_ID를 반환하므로 `IN`으로 받는 **다중행 서브쿼리**.
- (b) 이유/대안: "그 집합에 속하는지"만 판정하면 되므로 `IN`이 자연스럽다. 상관 `EXISTS`로도
  가능하나, 여기선 비상관 서브쿼리가 읽기 쉽다.
- (c) 실수/함정: 서브쿼리 컬럼(hosp_id)에 NULL이 섞이면 `IN`은 문제없지만 `NOT IN`은 전체가
  UNKNOWN이 될 수 있다(21번 참조). 여기 HOSP_ID는 NOT NULL이라 안전.
- (d) 실무: 12월 한 달로 양쪽을 맞춰 "같은 달 입원 실적이 있는 병원의 외래"를 본다.

## 18. [최상] `> ALL` 다중행 서브쿼리 — 상급종합 최고액 초과

```sql
SELECT c.claim_id, c.hosp_id, c.total_amt
FROM   medical_claims c
WHERE  c.total_amt > ALL (
         SELECT mc.total_amt
         FROM   medical_claims mc, hospitals h
         WHERE  mc.hosp_id = h.hosp_id
         AND    h.hosp_type = '상급종합'
       )
ORDER  BY c.total_amt DESC;
```

**해설**
- (a) 개념: `> ALL(집합)`은 "집합의 모든 값보다 크다" = "집합의 **최댓값보다 크다**"와 동치.
  즉 상급종합병원의 어떤 청구보다도 비싼 청구서를 찾는다.
- (b) 이유/대안: `> ALL (SELECT total_amt ...)`은 `> (SELECT MAX(total_amt) ...)`로 바꿔 쓰면
  훨씬 효율적이다(집합 전체를 비교하지 않고 최댓값 하나만). 학습용으로 `> ALL`을 썼다.
- (c) 함정: 서브쿼리 결과에 **NULL이 하나라도 있으면** `> ALL`은 절대 TRUE가 되지 못해 결과가
  0건이 될 수 있다(`x > NULL`이 UNKNOWN). TOTAL_AMT는 NOT NULL 계산값이라 안전. 또 서브쿼리가
  **빈 집합이면** `> ALL`은 항상 TRUE가 된다.
- (d) 실무: 상급종합은 대형 청구가 많아 그 최댓값을 넘는 청구는 극소수이거나 없을 수 있다.

## 19. [상] 상관 서브쿼리 — 병원 평균 초과 청구

```sql
SELECT c.claim_id, c.hosp_id, c.total_amt
FROM   medical_claims c
WHERE  c.hosp_id BETWEEN 1 AND 5
AND    c.total_amt > (
         SELECT AVG(c2.total_amt)
         FROM   medical_claims c2
         WHERE  c2.hosp_id = c.hosp_id
       )
ORDER  BY c.hosp_id, c.total_amt DESC;
```

**해설**
- (a) 개념: 서브쿼리가 바깥 행의 `c.hosp_id`를 참조하는 **상관 서브쿼리**. 바깥 청구마다 같은
  병원의 평균을 다시 계산해 비교한다.
- (b) 이유/대안: "그룹별 평균과 비교"는 GROUP BY로는 직접 못 하고(집계 후 개별 행이 사라짐)
  상관 서브쿼리나 분석함수(`AVG() OVER (PARTITION BY hosp_id)`)로 푼다. 분석함수 버전이 대개
  더 빠르다.
- (c) 실수: 상관 서브쿼리에서 별칭(c2)을 안 주고 `hosp_id=hosp_id`로 쓰면 자기 자신 참조가 돼
  항상 참(모든 행)이 된다.
- (d) 실무: HOSP_ID 1~5는 초대형 병원이라 평균 초과 청구가 각 병원 절반가량 나온다.

## 20. [최상] 다단계 중첩 서브쿼리 — 최다 약품을 최다 처방한 병원

```sql
SELECT c.hosp_id, h.hosp_name, COUNT(*) AS rx_cnt
FROM   claim_details cd, medical_claims c, hospitals h
WHERE  cd.claim_id = c.claim_id
AND    c.hosp_id   = h.hosp_id
AND    cd.drug_code = (
         SELECT drug_code
         FROM   ( SELECT drug_code
                  FROM   claim_details
                  GROUP  BY drug_code
                  ORDER  BY COUNT(*) DESC )
         WHERE  ROWNUM = 1
       )
GROUP  BY c.hosp_id, h.hosp_name
ORDER  BY rx_cnt DESC
FETCH  FIRST 1 ROWS ONLY;
```

**해설**
- (a) 개념: (1) 처방 최다 약품코드를 인라인 뷰+ROWNUM으로 구하고, (2) 그 약품의 처방을 병원별
  집계해 최다 병원을 뽑는 **다단계 중첩** 구조.
- (b) 이유/대안: "최다"를 뽑으려면 정렬 후 상단 1건을 취해야 하므로, 정렬된 인라인 뷰에
  `ROWNUM=1`(또는 바깥에서 `FETCH FIRST 1 ROWS ONLY`)을 적용. `MAX(COUNT(*))` 만으로는 어느
  약품인지 알 수 없다.
- (c) 실수: `WHERE ROWNUM=1 ORDER BY ...`처럼 같은 레벨에서 쓰면 정렬 전에 ROWNUM이 매겨져 엉뚱한
  행이 나온다 — 정렬을 인라인 뷰로 감싸야 한다.
- (d) 실무: 약품 1만 종에 처방이 고르게 흩어져 최다 약품도 처방 횟수가 그리 압도적이진 않다.

## 21. [최상] NOT EXISTS vs NOT IN(NULL 함정) — 자동반려 없는 청구

```sql
SELECT c.claim_id, c.hosp_id, c.review_status
FROM   medical_claims c
WHERE  c.receipt_date = DATE '2024-01-01'
AND    NOT EXISTS (
         SELECT 1
         FROM   review_log r
         WHERE  r.claim_id = c.claim_id
         AND    r.reviewer_id = 'SYSTEM'
       );
```

**해설**
- (a) 개념: 상관 `NOT EXISTS`로 "해당 청구에 SYSTEM 반려 로그가 존재하지 않는" 건을 찾는다.
- (b) 왜 NOT IN이 아니라 NOT EXISTS인가: `claim_id NOT IN (SELECT claim_id FROM review_log
  WHERE reviewer_id='SYSTEM')`에서 서브쿼리 결과에 **NULL이 하나라도 있으면 전체가 UNKNOWN**이
  되어 **결과가 0건**이 된다(NOT IN의 3치 논리 함정). REVIEW_LOG.CLAIM_ID는 FK지만 NULL 허용
  컬럼이므로 이 위험이 실재한다. `NOT EXISTS`는 NULL에 영향받지 않아 안전하다.
- (c) 실수: `NOT IN` 서브쿼리에 `AND claim_id IS NOT NULL`을 빠뜨리는 것이 대표적 버그.
- (d) 실무: 대용량에서 `NOT EXISTS`는 anti-join으로 잘 최적화된다. `RECEIPT_DATE=날짜`는 시간
  성분이 00:00:00으로 생성돼 등호 비교가 성립한다.

## 22. [상] SELECT절 스칼라 서브쿼리 — 상세/상병 건수 부착

```sql
SELECT c.claim_id, c.hosp_id, c.total_amt,
       (SELECT COUNT(*) FROM claim_details cd WHERE cd.claim_id = c.claim_id) AS detail_cnt,
       (SELECT COUNT(*) FROM diseases ds     WHERE ds.claim_id = c.claim_id) AS dis_cnt
FROM   medical_claims c
WHERE  c.claim_id LIKE '20240110%'
ORDER  BY c.claim_id;
```

**해설**
- (a) 개념: SELECT 목록에 놓인 상관 **스칼라 서브쿼리** 두 개. 각 청구마다 상세/상병 건수를
  1행 1값으로 되돌린다.
- (b) 이유/대안: 조인 후 GROUP BY로도 구할 수 있으나, 두 개의 1:N을 동시에 조인하면 카티션
  팽창(상세 3건 × 상병 2건 = 6행)이 생겨 집계가 왜곡된다. 스칼라 서브쿼리는 이 팽창을 피한다.
- (c) 실수: 스칼라 서브쿼리가 2행 이상 반환하면 `ORA-01427`. 반드시 집계나 단일행을 반환해야
  한다.
- (d) 실무: 서브쿼리가 행마다 실행되므로 결과 집합이 크면 비용이 커진다 — 소규모 목록 화면에
  적합.

## 23. [최상] 이중 EXISTS 결합 — 주사제 처방 + 자동반려 병원

```sql
SELECT h.hosp_id, h.hosp_name, h.city
FROM   hospitals h
WHERE  EXISTS (
         SELECT 1
         FROM   medical_claims c, claim_details cd, drug_master d
         WHERE  c.hosp_id = h.hosp_id
         AND    c.claim_id = cd.claim_id
         AND    cd.drug_code = d.drug_code
         AND    d.category = '주사제'
       )
AND    EXISTS (
         SELECT 1
         FROM   medical_claims c2, review_log r
         WHERE  c2.hosp_id = h.hosp_id
         AND    c2.claim_id = r.claim_id
         AND    r.reviewer_id = 'SYSTEM'
       );
```

**해설**
- (a) 개념: 두 개의 상관 `EXISTS`를 `AND`로 결합해 "두 조건을 모두 만족하는" 병원을 필터.
- (b) 이유/대안: 조건마다 서로 다른 조인 경로(약품 vs 로그)라 EXISTS로 분리하는 것이 깔끔하다.
  하나의 큰 조인으로 묶으면 카티션 팽창 후 DISTINCT가 필요해진다.
- (c) 실수: EXISTS 내부에서 바깥 `h.hosp_id` 상관 조건을 빠뜨리면 병원과 무관하게 "전체에
  하나라도 있으면 참"이 돼 모든 병원이 반환된다.
- (d) 실무: 주사제 처방은 흔하고 자동반려도 20만 건이라 상당수 병원이 두 조건을 만족한다.

---

# Ⅳ. SET 연산자 (24~27번)

## 24. [상] UNION — 고액 ∪ 심사중 청구

```sql
SELECT claim_id FROM medical_claims WHERE total_amt >= 1000000
UNION
SELECT claim_id FROM medical_claims WHERE review_status = '심사중';
```

**해설**
- (a) 개념: 두 결과 집합의 **합집합**. `UNION`은 중복을 제거하고 자동으로 정렬(중복 제거를 위한
  sort)까지 수행한다.
- (b) UNION vs UNION ALL: 고액이면서 동시에 심사중인 청구는 두 SELECT 모두에 등장한다. `UNION`은
  이를 1건으로, `UNION ALL`은 2건으로 센다. 그래서 `UNION ALL` 건수 ≥ `UNION` 건수이며 차이는
  "두 집합의 교집합 크기"만큼이다. 중복 제거가 불필요하면 `UNION ALL`이 정렬 비용이 없어 빠르다.
- (c) 실수: 두 SELECT의 컬럼 개수·데이터타입이 다르면 `ORA-01789: query block has incorrect
  number of result columns`.
- (d) 실무: 고액(1백만 이상)은 상세내역이 많은 극소수 청구라 대부분은 심사중 집합이 결과를
  좌우한다.

## 25. [상] UNION ALL — 요약표 세로 결합

```sql
SELECT '전체청구'   AS gubun, COUNT(*) AS cnt FROM medical_claims
UNION ALL
SELECT '입원청구',   COUNT(*) FROM medical_claims WHERE claim_type = '입원'
UNION ALL
SELECT '외래청구',   COUNT(*) FROM medical_claims WHERE claim_type = '외래'
UNION ALL
SELECT '심사중청구', COUNT(*) FROM medical_claims WHERE review_status = '심사중';
```

**해설**
- (a) 개념: 서로 다른 필터의 단일행 집계 4개를 세로로 쌓는 리포트. 각 구분 라벨을 상수 컬럼으로
  붙인다.
- (b) 왜 UNION ALL: 네 SELECT의 라벨(gubun)이 모두 달라 중복 행이 원천적으로 없다. 중복 제거
  (`UNION`)는 불필요한 정렬 비용만 유발하므로 `UNION ALL`이 정답.
- (c) 실수: 첫 SELECT의 컬럼 별칭(gubun, cnt)이 전체 결과의 컬럼명이 된다 — 두 번째 이후
  SELECT의 별칭은 무시된다.
- (d) 실무: 이런 "KPI 세로 요약"은 대시보드 상단 카드에 자주 쓰인다.

## 26. [상] MINUS — 청구했으나 자동반려 없는 환자

```sql
SELECT pat_id FROM medical_claims
MINUS
SELECT c.pat_id
FROM   medical_claims c, review_log r
WHERE  c.claim_id = r.claim_id
AND    r.reviewer_id = 'SYSTEM';
```

**해설**
- (a) 개념: `MINUS`는 첫 집합에서 둘째 집합에 있는 값을 뺀 **차집합**(중복 제거 포함).
- (b) 이유/대안: "전체 청구 환자 − 자동반려 청구 환자". `NOT IN`/`NOT EXISTS`로도 가능하나,
  집합 차 의미를 그대로 표현하는 `MINUS`가 직관적이다. 단 `MINUS`는 결과를 정렬한다.
- (c) 실수: 두 SELECT의 컬럼 순서/타입이 맞아야 한다. Oracle에서 표준 SQL의 `EXCEPT`는
  `MINUS`로 쓴다(키워드가 다름).
- (d) 실무: 자동반려(20만 건)가 걸린 환자가 많아 결과는 "한 번도 자동반려 안 걸린" 환자로
  상당히 줄어든다.

## 27. [상] INTERSECT — 1월·2월 연속 청구 병원

```sql
SELECT hosp_id FROM medical_claims
WHERE  receipt_date >= DATE '2024-01-01' AND receipt_date < DATE '2024-02-01'
INTERSECT
SELECT hosp_id FROM medical_claims
WHERE  receipt_date >= DATE '2024-02-01' AND receipt_date < DATE '2024-03-01'
ORDER  BY hosp_id;
```

**해설**
- (a) 개념: `INTERSECT`는 양쪽에 모두 존재하는 값(교집합)만, 중복 제거해 반환한다.
- (b) 이유/대안: "두 달 다 청구가 있었던 병원". 상관 서브쿼리 두 EXISTS로도 되지만 INTERSECT가
  간명하다.
- (c) 실수: SET 연산에서 `ORDER BY`는 **맨 마지막 SELECT 뒤에 한 번만** 올 수 있다. 각 SELECT에
  붙이면 오류.
- (d) 실무: 대형병원(1~50)은 매달 청구가 있어 거의 다 교집합에 포함되고, 소형 의원 일부만
  빠진다.

---

# Ⅴ. 분석 함수 (Window Function) (28~35번)

## 28. [최상] RANK/DENSE_RANK 파티션 — 유형별 고액 청구

```sql
SELECT *
FROM (
  SELECT c.claim_id, h.hosp_type, c.total_amt,
         RANK()       OVER (PARTITION BY h.hosp_type ORDER BY c.total_amt DESC) AS rnk,
         DENSE_RANK() OVER (PARTITION BY h.hosp_type ORDER BY c.total_amt DESC) AS drnk
  FROM   hospitals h, medical_claims c
  WHERE  c.hosp_id = h.hosp_id
  AND    c.receipt_date >= DATE '2024-03-01'
  AND    c.receipt_date <  DATE '2024-04-01'
)
WHERE rnk <= 3
ORDER BY hosp_type, rnk;
```

**해설**
- (a) 개념: `PARTITION BY hosp_type`으로 유형 안에서 금액 순위를 매긴다. `RANK`는 동점 뒤 순위를
  건너뛰고(1,1,3), `DENSE_RANK`는 건너뛰지 않는다(1,1,2).
- (b) 이유/대안: 분석함수는 SELECT 단계에서 계산되므로 `WHERE rnk<=3`을 같은 레벨에서 쓸 수
  없다 — 인라인 뷰로 감싼 뒤 바깥에서 필터한다.
- (c) 실수: 인라인 뷰 없이 `WHERE RANK() OVER(...) <= 3`로 쓰면 `ORA-30483: window functions
  are not allowed here`.
- (d) 실무: 동점(같은 total_amt)이 잦지 않은 금액 컬럼이라 RANK/DENSE_RANK 차이가 드물게
  나타난다.

## 29. [최상] [스큐 분석 1] NTILE + 누적 비중

```sql
SELECT hosp_id, claim_cnt,
       NTILE(10) OVER (ORDER BY claim_cnt DESC) AS decile,
       ROUND(RATIO_TO_REPORT(claim_cnt) OVER () * 100, 2) AS pct,
       ROUND(SUM(claim_cnt) OVER (ORDER BY claim_cnt DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             / SUM(claim_cnt) OVER () * 100, 2) AS cum_pct
FROM (
  SELECT hosp_id, COUNT(*) AS claim_cnt
  FROM   medical_claims
  GROUP  BY hosp_id
)
ORDER BY claim_cnt DESC;
```

**해설**
- (a) 개념: 병원별 건수 집계(인라인 뷰) 위에 `NTILE(10)`으로 10분위, `RATIO_TO_REPORT`로 개별
  비중, 누적 `SUM() OVER`로 내림차순 누적 비중을 계산.
- (b) 스큐 확인: 결과 상단에서 누적비중이 빠르게 올라가 **상위 50개 병원 안팎에서 누적비중이
  약 50%에 도달**한다(1~50번 대형병원 집중의 정량적 증거). 상위 5%(50개)가 전체 절반을 차지.
- (c) 실수: 누적합에서 프레임을 생략하면 `ORDER BY`가 있는 `SUM() OVER`는 기본이 `RANGE
  BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`라, 동점 건수 병원들이 한꺼번에 합산돼 계단이
  생긴다 — 정확한 행 누적을 원하면 `ROWS`로 명시.
- (d) 실무: "상위 N%가 전체 M%를 차지"는 파레토 분석의 핵심 지표.

## 30. [상] NTILE(4) — 환자 청구 규모 4등급

```sql
SELECT pat_id, pat_name, tot_amt, grade
FROM (
  SELECT p.pat_id, p.pat_name,
         SUM(c.total_amt) AS tot_amt,
         NTILE(4) OVER (ORDER BY SUM(c.total_amt) DESC) AS grade
  FROM   patients p, medical_claims c
  WHERE  p.pat_id = c.pat_id
  GROUP  BY p.pat_id, p.pat_name
)
ORDER BY tot_amt DESC;
```

**해설**
- (a) 개념: 환자별 총청구액을 집계하고 그 값 기준 `NTILE(4)`로 4개 등급(1=상위 25%)으로 균등
  분할.
- (b) 이유/대안: `NTILE`은 행 개수를 최대한 균등하게 나눈다. "금액 절대 구간"으로 나누려면
  `CASE`(42번 방식)를, "상대 등급"이면 NTILE을 쓴다.
- (c) 실수: 집계와 분석함수를 같은 쿼리에서 쓸 때 `NTILE(4) OVER (ORDER BY SUM(...))`처럼
  분석함수 ORDER BY에 집계식을 직접 넣을 수 있다(별칭은 불가).
- (d) 실무: 청구 실적 있는 환자만(내부 조인) 대상이라 청구 0건 환자는 등급에서 제외된다.

## 31. [상] LAG — 직전 청구 대비 증감

```sql
SELECT claim_id, receipt_date, total_amt,
       LAG(total_amt, 1, 0) OVER (ORDER BY receipt_date, claim_id) AS prev_amt,
       total_amt - LAG(total_amt, 1, 0) OVER (ORDER BY receipt_date, claim_id) AS diff
FROM   medical_claims
WHERE  hosp_id = 1
ORDER  BY receipt_date, claim_id;
```

**해설**
- (a) 개념: `LAG(col, 1, 기본값)`은 정렬 순서상 1행 앞 값을 가져온다. 세 번째 인자(0)로 첫
  행의 없는 값을 0으로 대체.
- (b) 이유/대안: `LAG` 기본값을 생략하면 첫 행이 NULL이 되고 `diff`도 NULL이 된다. 문제 요구가
  "첫 행 0"이므로 기본값 0을 명시.
- (c) 실수: 정렬 키에 tie(같은 접수일)가 많으면 "직전"이 불안정해진다 — `claim_id`를 보조 정렬
  키로 넣어 결정적 순서를 만든다.
- (d) 실무: HOSP_ID=1은 청구가 매우 많아 접수일 단위로 여러 건이 몰린다.

## 32. [최상] SUM() OVER — 누적합 + 3개월 이동평균

```sql
SELECT ym, month_amt,
       SUM(month_amt) OVER (ORDER BY ym
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_amt,
       ROUND(AVG(month_amt) OVER (ORDER BY ym
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)) AS mov_avg_3m
FROM (
  SELECT TO_CHAR(receipt_date, 'YYYY-MM') AS ym,
         SUM(total_amt) AS month_amt
  FROM   medical_claims
  WHERE  hosp_id = 1
  GROUP  BY TO_CHAR(receipt_date, 'YYYY-MM')
)
ORDER BY ym;
```

**해설**
- (a) 개념: 월별 집계(인라인 뷰) 위에 두 개의 윈도우 집계 — 누적합(`UNBOUNDED PRECEDING ~
  CURRENT ROW`)과 최근 3개월 이동평균(`2 PRECEDING ~ CURRENT ROW`).
- (b) 이유/대안: 이동평균은 프레임을 반드시 `ROWS`로 명시. 처음 두 달은 앞 데이터가 2개 미만
  이라 있는 만큼만 평균 낸다.
- (c) 실수: `ROWS`를 빼면 기본 `RANGE`가 적용돼 값이 같은 행을 뭉쳐 계산할 수 있다.
- (d) 실무: 누적·이동평균은 추세선 대시보드의 기본 지표.

## 33. [상] FIRST_VALUE / LAST_VALUE — 병원별 최고·최저 청구

```sql
SELECT hosp_id, claim_id, total_amt,
       FIRST_VALUE(claim_id) OVER (PARTITION BY hosp_id ORDER BY total_amt DESC
             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS max_claim,
       LAST_VALUE(claim_id)  OVER (PARTITION BY hosp_id ORDER BY total_amt DESC
             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS min_claim
FROM   medical_claims
WHERE  hosp_id BETWEEN 1 AND 3
ORDER  BY hosp_id, total_amt DESC;
```

**해설**
- (a) 개념: 파티션(병원) 안에서 금액 내림차순 정렬 시 `FIRST_VALUE`는 최고액, `LAST_VALUE`는
  최저액 청구의 CLAIM_ID를 각 행에 반복 표시.
- (b) LAST_VALUE 함정: `ORDER BY`만 주고 프레임을 생략하면 기본이 `RANGE BETWEEN UNBOUNDED
  PRECEDING AND CURRENT ROW`라, `LAST_VALUE`가 "현재 행까지의 마지막"=현재 행 값을 돌려줘
  최저액이 아니라 매 행 자기 자신이 나온다. 반드시 `ROWS BETWEEN UNBOUNDED PRECEDING AND
  UNBOUNDED FOLLOWING`으로 프레임을 전체로 넓혀야 한다.
- (c) 실수: 위 프레임 누락이 가장 흔한 버그. `FIRST_VALUE`는 기본 프레임에서도 우연히 맞게
  나와 착각하기 쉽다.
- (d) 실무: `MIN/MAX ... KEEP (DENSE_RANK FIRST/LAST ...)`로도 같은 결과를 얻을 수 있다.

## 34. [최상] [스큐 분석 2] PERCENT_RANK / CUME_DIST

```sql
SELECT hosp_id, claim_cnt,
       ROUND(PERCENT_RANK() OVER (ORDER BY claim_cnt), 4) AS pct_rank,
       ROUND(CUME_DIST()    OVER (ORDER BY claim_cnt), 4) AS cume_dist
FROM (
  SELECT hosp_id, COUNT(*) AS claim_cnt
  FROM   medical_claims
  GROUP  BY hosp_id
)
ORDER BY claim_cnt DESC;
```

**해설**
- (a) 개념: `PERCENT_RANK`=(순위−1)/(행수−1)로 0~1, `CUME_DIST`=(자기 이하 행수)/(전체 행수)로
  (0,1]. 둘 다 상대적 위치(백분위)를 나타낸다.
- (b) 스큐 확인: 오름차순 정렬 기준이므로 청구건수가 큰 대형병원일수록 값이 1에 가깝다.
  `pct_rank ≈ 0.99` 이상 병원들이 바로 스큐를 만드는 상위 소수 병원이다.
- (c) 실수: `PERCENT_RANK`와 `CUME_DIST`의 정의를 혼동하면 경계(0/1 포함 여부) 해석이 틀린다.
- (d) 실무: "상위 1% 병원" 같은 컷오프를 백분위로 뽑을 때 유용하다.

## 35. [상] RATIO_TO_REPORT — 진료과별 청구액 비중

```sql
SELECT dept_code, dept_sum,
       ROUND(RATIO_TO_REPORT(dept_sum) OVER () * 100, 2) AS ratio_pct
FROM (
  SELECT dept_code, SUM(total_amt) AS dept_sum
  FROM   medical_claims
  GROUP  BY dept_code
)
ORDER BY ratio_pct DESC;
```

**해설**
- (a) 개념: `RATIO_TO_REPORT(x) OVER ()`는 x를 파티션(여기선 전체) 합으로 나눈 비율을 반환.
  진료과별 합계가 전체에서 차지하는 비중.
- (b) 이유/대안: `dept_sum / SUM(dept_sum) OVER ()`와 동일하지만 `RATIO_TO_REPORT`가 의도를
  더 명확히 드러낸다.
- (c) 실수: `OVER ()` 괄호를 빼면 문법 오류. 파티션을 주면 그 파티션 내 비중이 된다.
- (d) 실무: DEPT_CODE는 D1~D9 균등 분포라 각 진료과가 약 11% 안팎으로 고르게 나온다.

---

# Ⅵ. TOP-N / 페이징 (36~38번)

## 36. [상] ROWNUM 2단계 인라인 뷰 페이징 — 11~20위

```sql
SELECT hosp_id, hosp_name, sum_amt, rn
FROM (
  SELECT hosp_id, hosp_name, sum_amt, ROWNUM AS rn
  FROM (
    SELECT h.hosp_id, h.hosp_name, SUM(c.total_amt) AS sum_amt
    FROM   hospitals h, medical_claims c
    WHERE  h.hosp_id = c.hosp_id
    GROUP  BY h.hosp_id, h.hosp_name
    ORDER  BY SUM(c.total_amt) DESC
  )
)
WHERE rn BETWEEN 11 AND 20;
```

**해설**
- (a) 개념: 3단계 구조 — (1) 정렬된 집계, (2) 그 위에 `ROWNUM`을 확정 부여, (3) 바깥에서 범위
  필터. 페이징의 정석.
- (b) 왜 곧바로 안 되나: `ROWNUM`은 정렬 **전에**, 행이 나오는 순서대로 매겨진다. 그래서
  `WHERE ROWNUM BETWEEN 11 AND 20 ... ORDER BY`를 한 레벨에서 쓰면 엉뚱한 행이 잡힌다. 또
  `ROWNUM > 10` 같은 조건은 첫 행이 통과하지 못해 **아무 행도 반환되지 않는다**(ROWNUM은 통과한
  행에만 증가) — 반드시 `ROWNUM`을 별칭으로 고정한 뒤 바깥에서 `>`/`BETWEEN` 비교해야 한다.
- (c) 실수: `ROWNUM`을 한 번만 인라인 뷰로 감싸고 정렬을 같은 레벨에 두는 실수.
- (d) 실무: 12c 이전 버전 호환 페이징의 표준 관용구.

## 37. [상] OFFSET ... FETCH — 11~20위

```sql
SELECT h.hosp_id, h.hosp_name, SUM(c.total_amt) AS sum_amt
FROM   hospitals h, medical_claims c
WHERE  h.hosp_id = c.hosp_id
GROUP  BY h.hosp_id, h.hosp_name
ORDER  BY SUM(c.total_amt) DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
```

**해설**
- (a) 개념: Oracle 12c의 행 제한 절 `OFFSET n ROWS FETCH NEXT m ROWS ONLY`. 앞 10행을 건너뛰고
  다음 10행(=11~20위)을 반환.
- (b) 이유/대안: ROWNUM 3단계 중첩(36번)보다 훨씬 읽기 쉽고 표준 SQL에 가깝다. 단 12c 미만에서는
  못 쓴다(이식성 vs 가독성 트레이드오프).
- (c) 실수: `OFFSET`은 `ORDER BY` 뒤에 와야 하며, `ROWS`/`ROWS ONLY` 키워드를 빠뜨리면 문법
  오류. 내부적으로 `ROW_NUMBER()` 기반이라 대량 OFFSET은 여전히 앞 행을 스캔하므로 깊은
  페이지에선 느리다.
- (d) 실무: 신규 개발은 대개 이 구문을 선호한다.

## 38. [최상] 동점 처리 — WITH TIES vs RANK

```sql
-- (a) FETCH FIRST ... WITH TIES
SELECT hosp_id, claim_cnt
FROM (
  SELECT hosp_id, COUNT(*) AS claim_cnt
  FROM   medical_claims
  GROUP  BY hosp_id
)
ORDER BY claim_cnt DESC
FETCH FIRST 5 ROWS WITH TIES;

-- (b) RANK() <= 5
SELECT hosp_id, claim_cnt, rnk
FROM (
  SELECT hosp_id, COUNT(*) AS claim_cnt,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM   medical_claims
  GROUP  BY hosp_id
)
WHERE rnk <= 5
ORDER BY claim_cnt DESC;
```

**해설**
- (a) 개념: `FETCH FIRST 5 ROWS WITH TIES`는 5위 값과 동점인 행을 모두 포함(그래서 6건 이상
  가능). `RANK()<=5`도 동점을 같은 순위로 묶어 동일 결과를 낸다.
- (b) 비교: 두 방식은 결과 집합이 동일하다. `WITH TIES`는 반드시 `ORDER BY`가 있어야 하며 그
  정렬 키가 동점 판정 기준이 된다. `RANK`는 순위값을 별도 컬럼으로 볼 수 있는 장점.
- (c) 실수: `WITH TIES` 대신 `ROWS ONLY`를 쓰면 정확히 5건만 잘라 동점 병원이 임의로 탈락한다.
  `DENSE_RANK<=5`는 "서로 다른 상위 5개 값"이라 동점이 많으면 6건 이상이 되는 등 의미가 다르다.
- (d) 실무: 순위표에서 "공동 5위"를 정당하게 처리하려면 이 둘 중 하나를 써야 한다. 건수 동점은
  자주 발생.

---

# Ⅶ. 날짜·문자·변환 함수 / CASE·DECODE (39~44번)

## 39. [상] BIRTH_DATE 연령 계산 — 40대 환자 청구

```sql
SELECT COUNT(*) AS claim_cnt, SUM(c.total_amt) AS sum_amt
FROM   patients p, medical_claims c
WHERE  p.pat_id = c.pat_id
AND    TRUNC(MONTHS_BETWEEN(DATE '2026-07-21',
                           TO_DATE(p.birth_date, 'YYYYMMDD')) / 12) BETWEEN 40 AND 49;
```

**해설**
- (a) 개념: VARCHAR2(8) 문자열을 `TO_DATE(...,'YYYYMMDD')`로 날짜화한 뒤, `MONTHS_BETWEEN`으로
  기준일과의 개월수를 구해 12로 나누고 `TRUNC`으로 만 나이를 얻는다.
- (b) 이유/대안: `MONTHS_BETWEEN`/12 + TRUNC 방식은 생일 경과까지 정확히 반영한다. `(기준연도 −
  출생연도)`만으로 계산하면 생일 안 지난 사람 나이가 1살 많게 나온다.
- (c) 실수: BIRTH_DATE에 컬럼 함수를 씌워 비교하므로 인덱스를 못 탄다(함수기반 인덱스가 없으면
  풀스캔). BETWEEN 40 AND 49는 "40세 이상 50세 미만"과 같다.
- (d) 실무: 연령 조건 조회가 잦으면 나이 파생 컬럼/FBI를 두는 것이 정석(튜닝 영역).

## 40. [상] 날짜 함수 — 요일별 접수 지연 분석

```sql
SELECT TO_CHAR(receipt_date, 'DAY')          AS day_name,
       COUNT(*)                              AS claim_cnt,
       ROUND(AVG(receipt_date - visit_date), 1) AS avg_delay_days
FROM   medical_claims
WHERE  receipt_date >= DATE '2024-03-01'
AND    receipt_date <  DATE '2024-04-01'
GROUP  BY TO_CHAR(receipt_date, 'DAY'), TO_CHAR(receipt_date, 'D')
ORDER  BY TO_CHAR(receipt_date, 'D');
```

**해설**
- (a) 개념: 날짜 간 뺄셈(`receipt_date - visit_date`)은 일수를 준다. `TO_CHAR(date,'DAY')`는
  요일 이름, `'D'`는 요일 번호(1~7)로 정렬용.
- (b) 이유/대안: 요일 이름으로 GROUP BY하면서 정렬은 번호('D')로 해야 월~일 순서가 맞는다.
  그래서 GROUP BY에 두 표현식을 함께 넣었다.
- (c) 실수: `'DAY'`는 NLS 언어·세션에 따라 '월요일'/'MONDAY'로 다르게 나오고 공백 패딩이 붙는다
  (`TRIM` 권장). NLS_TERRITORY에 따라 주 시작 요일이 달라 'D' 값이 바뀔 수 있다.
- (d) 실무: 데이터 생성상 진료일=접수일−(1~14)일이라 avg_delay가 대략 7일 안팎으로 나온다.

## 41. [상] 문자열 파싱 — CLAIM_ID 분해

```sql
SELECT SUBSTR(claim_id, 1, 6)                          AS ym,
       COUNT(*)                                        AS claim_cnt
FROM   medical_claims
GROUP  BY SUBSTR(claim_id, 1, 6)
ORDER  BY ym;

-- 순번 부분 추출 예시: '-' 뒤 문자열
-- SUBSTR(claim_id, INSTR(claim_id, '-') + 1)  AS seq_part
```

**해설**
- (a) 개념: CLAIM_ID = 'YYYYMMDD-순번'. `SUBSTR(claim_id,1,6)`으로 'YYYYMM' 6자리, `INSTR(claim_id,
  '-')`로 하이픈 위치를 찾아 `SUBSTR(..., INSTR+1)`로 순번을 뗀다.
- (b) 이유/대안: 문제 요구가 "RECEIPT_DATE를 쓰지 말고 문자열 파싱"이라 `SUBSTR/INSTR`로 풀었다.
  실무라면 날짜 컬럼을 직접 쓰는 편이 정확·빠르다(문자열 형식이 깨지면 파싱도 깨짐).
- (c) 실수: `SUBSTR`의 시작 위치는 1부터(0 아님). `INSTR`가 못 찾으면 0을 반환하므로 `+1`이
  1이 되어 전체 문자열이 나온다 — 형식이 보장될 때만 안전.
- (d) 실무: CLAIM_ID 접미 순번은 전역 카운터라 날짜순으로 연속되지 않는다(스키마 특성). 접수
  연월 집계 용도로는 앞 6자리만으로 충분.

## 42. [상] CASE 구간화 — 청구액 등급

```sql
SELECT CASE WHEN total_amt >= 500000 THEN '고액'
            WHEN total_amt >= 100000 THEN '중액'
            ELSE '소액' END                 AS amt_grade,
       COUNT(*)          AS claim_cnt,
       SUM(total_amt)    AS sum_amt
FROM   medical_claims
GROUP  BY CASE WHEN total_amt >= 500000 THEN '고액'
               WHEN total_amt >= 100000 THEN '중액'
               ELSE '소액' END
ORDER  BY MIN(CASE WHEN total_amt >= 500000 THEN 1
                   WHEN total_amt >= 100000 THEN 2 ELSE 3 END);
```

**해설**
- (a) 개념: 검색형 `CASE`로 금액을 3구간으로 라벨링하고 그 라벨로 GROUP BY. 정렬은 라벨의
  문자 순('고<소<중')이 아니라 의도한 순서(고→중→소)를 만들기 위해 숫자 매핑으로 정렬.
- (b) 이유/대안: `WHEN >=500000 ... WHEN >=100000`처럼 큰 값부터 검사하는 것이 안전(순서 의존).
  구간이 겹치지 않게 상한/하한을 정확히 둔다.
- (c) 실수: GROUP BY에 SELECT의 CASE 별칭(amt_grade)을 쓰면 `ORA-00904` — 같은 CASE 식을 반복
  하거나, 인라인 뷰로 감싼 뒤 별칭으로 GROUP BY 한다.
- (d) 실무: 상세내역 평균 3건 × 평균 단가로 인해 대부분 청구가 '중액'대에 몰리고 '고액'은 소수.

## 43. [상] DECODE — 진료과 코드 매핑

```sql
SELECT DECODE(dept_code, 'D1','내과','D2','외과','D3','소아과',
                         'D4','정형외과','D5','피부과','D6','안과',
                         'D7','이비인후과','D8','산부인과','D9','신경과',
                         '기타')          AS dept_name,
       COUNT(*)                            AS claim_cnt
FROM   medical_claims
GROUP  BY DECODE(dept_code, 'D1','내과','D2','외과','D3','소아과',
                            'D4','정형외과','D5','피부과','D6','안과',
                            'D7','이비인후과','D8','산부인과','D9','신경과',
                            '기타')
ORDER  BY claim_cnt DESC;
```

**해설**
- (a) 개념: `DECODE(식, 값1,결과1, 값2,결과2, ..., 기본값)`은 등가 매핑 전용 함수. 코드→명칭
  치환에 간결하다.
- (b) DECODE vs CASE: `DECODE`는 **등호 비교만** 가능(범위·부등호 불가). `CASE`는 범위 비교
  (`WHEN x>=1000`)까지 되어 더 범용적. 42번 같은 구간화는 CASE만 가능하다.
- (c) NULL 처리 차이: `DECODE`는 **NULL을 NULL과 같다고 취급**해 매칭한다(예: `DECODE(x,NULL,'널')`
  가능). 반면 `CASE x WHEN NULL`은 절대 참이 안 된다(`x=NULL`은 UNKNOWN) — NULL은 `WHEN x IS
  NULL` 형태로 검색형 CASE를 써야 한다.
- (d) 실무: 코드 표가 별도 테이블이면 조인이 정석이나, 소량 고정 코드엔 DECODE/CASE가 간편.

## 44. [최상] 종합 변환 — 환자 세그먼트 라벨

```sql
SELECT seg, COUNT(*) AS pat_cnt
FROM (
  SELECT NVL(p.city, '미상') || '/' ||
         DECODE(p.gender, 'M','남', 'F','여', '기타') || '/' ||
         CASE
           WHEN age < 20 THEN '20대 미만'
           WHEN age < 30 THEN '20대'
           WHEN age < 40 THEN '30대'
           WHEN age < 50 THEN '40대'
           WHEN age < 60 THEN '50대'
           WHEN age < 70 THEN '60대'
           ELSE '70대 이상'
         END AS seg
  FROM (
    SELECT city, gender,
           TRUNC(MONTHS_BETWEEN(DATE '2026-07-21',
                 TO_DATE(birth_date,'YYYYMMDD')) / 12) AS age
    FROM   patients
  ) p
)
GROUP BY seg
ORDER BY pat_cnt DESC;
```

**해설**
- (a) 개념: 세 단계 변환 — (1) 만 나이 계산, (2) 나이/성별/지역을 CASE·DECODE로 라벨화, (3)
  문자열 연결(`||`)로 세그먼트 생성 후 집계.
- (b) 이유/대안: `MONTHS_BETWEEN/12 + TRUNC`로 생일 경과까지 반영한 정확한 만 나이. NULL 대비로
  `NVL(city,'미상')`, 예외 성별에 DECODE 기본값 '기타'를 뒀다. `COALESCE`는 여러 후보 중 첫
  non-NULL을 고를 때 유용(`NVL`은 2인자 전용).
- (c) 실수: 나이 CASE에서 경계(`< 30`)를 겹치거나 빠뜨리면 특정 나이가 누락된다. 문자열 연결에
  NULL이 섞이면 그 자리가 사라지므로 NVL 필수.
- (d) 실무: 이런 파생 세그먼트는 통계/마케팅 집계의 기본 축. 데이터 특성상 서울/건강보험 계층이
  가장 크게 나온다.

---

# Ⅷ. 뷰 / 시퀀스 / WITH절(CTE) / 인라인 뷰 (45~50번)

## 45. [상] 뷰 생성 — 병원별 청구 요약

```sql
CREATE OR REPLACE VIEW V_HOSP_CLAIM_SUMMARY AS
SELECT h.hosp_id, h.hosp_name,
       COUNT(c.claim_id)            AS claim_cnt,
       NVL(SUM(c.total_amt), 0)     AS sum_amt,
       ROUND(AVG(c.total_amt))      AS avg_amt,
       MAX(c.total_amt)             AS max_amt,
       MIN(c.total_amt)             AS min_amt
FROM   hospitals h, medical_claims c
WHERE  h.hosp_id = c.hosp_id(+)
GROUP  BY h.hosp_id, h.hosp_name;

-- 활용: 총액합계 상위 10개 병원
SELECT hosp_id, hosp_name, claim_cnt, sum_amt
FROM   V_HOSP_CLAIM_SUMMARY
ORDER  BY sum_amt DESC
FETCH  FIRST 10 ROWS ONLY;
```

**실행 결과**: `View V_HOSP_CLAIM_SUMMARY이(가) 생성되었습니다.` (조회 시 상위 10개는 대형병원
1~50번 위주)

**해설**
- (a) 개념: 복잡한 집계 로직을 뷰로 캡슐화해 재사용성을 높인다. 아우터 조인(`(+)`)으로 청구
  없는 병원도 건수 0으로 포함.
- (b) 이유/대안: 뷰는 저장된 SELECT일 뿐(데이터 미저장)이라 항상 최신을 반영한다. 반복 집계
  비용이 부담이면 머티리얼라이즈드 뷰를 고려(별도 주제).
- (c) 실수: `CREATE OR REPLACE VIEW`를 쓰면 재실행에 안전하다. 뷰 컬럼에는 반드시 별칭을 줘야
  한다(집계식은 이름이 없으므로).
- (d) 실무: 집계 뷰는 리포트 표준화·권한 통제(원천 테이블 대신 뷰만 노출)에 유용.

## 46. [상] 시퀀스 채번 시나리오

```sql
CREATE SEQUENCE SEQ_HOSP_ID
  START WITH 1001
  INCREMENT BY 1
  CACHE 20;

-- 신규 병원 등록
INSERT INTO HOSPITALS (hosp_id, hosp_name, hosp_type, city, est_date, status)
VALUES (SEQ_HOSP_ID.NEXTVAL, '신규요양기관_A', '의원', '서울', SYSDATE, '운영');

-- 신규 청구접수번호 채번 예시
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || '-' || LPAD(SEQ_HOSP_ID.CURRVAL, 7, '0')
       AS new_claim_id
FROM   dual;
```

**실행 결과**: `Sequence SEQ_HOSP_ID이(가) 생성되었습니다.` / `1 행이 삽입되었습니다.`

**해설**
- (a) 개념: 시퀀스는 세션과 무관하게 유일한 정수를 발급한다. `NEXTVAL`이 다음 값을 채번,
  `CURRVAL`은 **현재 세션에서 마지막 NEXTVAL 값**을 재조회.
- (b) 이유/대안: 기존 최대 HOSP_ID(1000)와 겹치지 않게 `START WITH 1001`. `CACHE 20`은 20개를
  메모리에 미리 확보해 성능을 높인다.
- (c) 갭(gap) 발생: `CURRVAL`은 같은 세션에서 `NEXTVAL`을 한 번도 호출하지 않으면 `ORA-08002:
  sequence CURRVAL is not yet defined in this session` 오류. 또 롤백·캐시 유실·다중 세션 때문에
  시퀀스 값에 **구멍(gap)**이 생기는 것이 정상이며 연속성을 보장하지 않는다.
- (d) 실무: 시퀀스는 "유일성"만 보장하고 "연속·순서"는 보장하지 않는다 — 감사 번호로 연속성이
  필요하면 별도 설계가 필요.

## 47. [최상] WITH절 다단계 — 유형 평균 초과 병원

```sql
WITH hosp_sum AS (
  SELECT h.hosp_id, h.hosp_name, h.hosp_type,
         SUM(c.total_amt) AS sum_amt
  FROM   hospitals h, medical_claims c
  WHERE  h.hosp_id = c.hosp_id
  GROUP  BY h.hosp_id, h.hosp_name, h.hosp_type
),
type_avg AS (
  SELECT hosp_type, AVG(sum_amt) AS avg_type_sum
  FROM   hosp_sum
  GROUP  BY hosp_type
)
SELECT s.hosp_id, s.hosp_name, s.hosp_type, s.sum_amt,
       ROUND(t.avg_type_sum) AS type_avg
FROM   hosp_sum s, type_avg t
WHERE  s.hosp_type = t.hosp_type
AND    s.sum_amt   > t.avg_type_sum
ORDER  BY s.hosp_type, s.sum_amt DESC;
```

**해설**
- (a) 개념: `WITH`(서브쿼리 팩토링)로 (1) 병원별 합계, (2) 그 결과를 재집계한 유형별 평균 두
  단계를 정의하고 조인. 두 번째 CTE가 첫 번째를 참조하는 다단계 구조.
- (b) 이유/대안: `hosp_sum`을 두 번(집계 원천 + 최종 조인) 참조하므로 WITH가 인라인 뷰보다
  중복 없이 깔끔하다. 옵티마이저가 CTE를 매번 실행할지(inline) 임시 결과로 물릴지(materialize)
  판단한다.
- (c) 실수: CTE 사이 콤마 구분과 최종 SELECT가 반드시 뒤에 와야 한다. CTE 이름을 FROM에서
  실제 사용하지 않으면 계산되지 않는다.
- (d) 실무: 다단계 집계·재사용 로직 가독성을 크게 높인다. 상급종합처럼 표본이 작은 유형은
  평균이 소수 대형 청구에 휘둘릴 수 있다.

## 48. [최상] WITH + 분석함수 — 월별 1위 진료과

```sql
WITH monthly AS (
  SELECT TO_CHAR(receipt_date, 'YYYY-MM') AS ym,
         dept_code,
         SUM(total_amt) AS dept_amt
  FROM   medical_claims
  GROUP  BY TO_CHAR(receipt_date, 'YYYY-MM'), dept_code
)
SELECT ym, dept_code, dept_amt, rn
FROM (
  SELECT ym, dept_code, dept_amt,
         ROW_NUMBER() OVER (PARTITION BY ym ORDER BY dept_amt DESC) AS rn
  FROM   monthly
)
WHERE rn = 1
ORDER BY ym;
```

**해설**
- (a) 개념: WITH로 월×진료과 집계를 만든 뒤, `ROW_NUMBER() OVER (PARTITION BY ym ORDER BY
  dept_amt DESC)`로 월별 1위를 뽑는다.
- (b) 이유/대안: 1위만 필요하고 동점 시 하나만 원하면 `ROW_NUMBER`, 동점 모두 원하면 `RANK`.
  상관 서브쿼리(`dept_amt = (SELECT MAX ...)`)보다 분석함수가 한 번의 스캔으로 끝나 효율적.
- (c) 실수: `WHERE rn=1`을 분석함수와 같은 레벨에 쓰면 `ORA-30483` — 인라인 뷰로 감싸야 한다.
- (d) 실무: "그룹별 최상위 1건(top-1-per-group)"의 정석 패턴. 12개월이면 12행이 나온다.

## 49. [상] 인라인 뷰 + ROWNUM 순위 — 청구 상위 15개 병원

```sql
SELECT ROWNUM AS rank_no, hosp_id, hosp_name, claim_cnt
FROM (
  SELECT h.hosp_id, h.hosp_name, COUNT(*) AS claim_cnt
  FROM   hospitals h, medical_claims c
  WHERE  h.hosp_id = c.hosp_id
  GROUP  BY h.hosp_id, h.hosp_name
  ORDER  BY COUNT(*) DESC
)
WHERE ROWNUM <= 15;
```

**해설**
- (a) 개념: 정렬된 집계를 **인라인 뷰**로 감싼 뒤 바깥에서 `ROWNUM`으로 순번을 부여하고 상위
  15개로 자른다.
- (b) 이유/대안: `ROWNUM`은 정렬 전에 매겨지므로 반드시 "정렬을 인라인 뷰에서 끝낸 뒤" 바깥에서
  ROWNUM을 걸어야 상위 N이 정확하다. `FETCH FIRST 15 ROWS ONLY`로도 대체 가능.
- (c) 실수: 인라인 뷰 없이 `WHERE ROWNUM<=15 ... ORDER BY`를 한 레벨에 쓰면 "임의의 15건을
  뽑아 정렬"하게 되어 상위 15가 아니다.
- (d) 실무: 이 결과 상위권은 대형병원(1~50)이 독식한다(스큐 확인).

## 50. [최상] 종합 — 상급종합 월별 추이 + 뷰

```sql
-- 조회 쿼리
WITH tertiary AS (
  SELECT TO_CHAR(c.receipt_date,'YYYY-MM') AS ym, SUM(c.total_amt) AS ter_amt
  FROM   hospitals h, medical_claims c
  WHERE  c.hosp_id = h.hosp_id
  AND    h.hosp_type = '상급종합'
  GROUP  BY TO_CHAR(c.receipt_date,'YYYY-MM')
),
total AS (
  SELECT TO_CHAR(receipt_date,'YYYY-MM') AS ym, SUM(total_amt) AS all_amt
  FROM   medical_claims
  GROUP  BY TO_CHAR(receipt_date,'YYYY-MM')
)
SELECT t.ym, ter.ter_amt, t.all_amt,
       ROUND(ter.ter_amt / t.all_amt * 100, 2)                       AS ratio_pct,
       ter.ter_amt - LAG(ter.ter_amt) OVER (ORDER BY t.ym)           AS mom_diff
FROM   total t, tertiary ter
WHERE  t.ym = ter.ym
ORDER  BY t.ym;

-- 다단계 로직을 감춘 뷰
CREATE OR REPLACE VIEW V_TERTIARY_MONTHLY AS
SELECT t.ym,
       ter.ter_amt,
       t.all_amt,
       ROUND(ter.ter_amt / t.all_amt * 100, 2) AS ratio_pct
FROM   ( SELECT TO_CHAR(receipt_date,'YYYY-MM') AS ym, SUM(total_amt) AS all_amt
         FROM   medical_claims
         GROUP  BY TO_CHAR(receipt_date,'YYYY-MM') ) t,
       ( SELECT TO_CHAR(c.receipt_date,'YYYY-MM') AS ym, SUM(c.total_amt) AS ter_amt
         FROM   hospitals h, medical_claims c
         WHERE  c.hosp_id = h.hosp_id AND h.hosp_type = '상급종합'
         GROUP  BY TO_CHAR(c.receipt_date,'YYYY-MM') ) ter
WHERE  t.ym = ter.ym;
```

**실행 결과**: 조회는 12행(월별) 내외, 뷰는 `View V_TERTIARY_MONTHLY이(가) 생성되었습니다.`

**해설**
- (a) 개념: 두 CTE(상급종합 월합계 / 전체 월합계)를 `ym`으로 조인해 비중을 구하고, `LAG`로
  전월 대비 증감을 붙였다. 같은 로직을 뷰로 캡슐화해 재사용성을 확보.
- (b) 이유/대안: 뷰 정의에는 `WITH` 대신 인라인 뷰 두 개를 콤마 조인으로 넣었다(뷰 안에서도
  WITH 사용 가능하나 인라인 뷰가 더 보편적). 분석함수 `LAG`는 뷰에 넣지 않고 조회 시 얹어도
  된다(뷰는 순수 집계만, 시계열 연산은 상위에서).
- (c) 실수: `ter_amt / all_amt`에서 all_amt가 0인 월이 있으면 `ORA-01476: divisor is equal to
  zero`. 전체 청구는 매월 존재하므로 안전하나, 방어하려면 `NULLIF(all_amt,0)`.
- (d) 실무: 상급종합은 약 1%뿐이지만 대형 청구가 많아 전체의 상당 비중을 차지할 수 있다.
  월별 비중·증감 추이는 정책 모니터링의 핵심 지표.

---

*(해설 끝 — 총 50문항, 순수 SQL. 모든 조인은 Oracle 전통 문법 사용)*
