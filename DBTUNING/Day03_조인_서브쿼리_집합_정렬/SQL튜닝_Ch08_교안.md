# Chapter 8. Subquery / EXISTS / IN

- 본 차시는 DDL 변경 없음(기존 PK만 사용)
- 아래 예제는 전부 실습 DB 실측 결과
- Chapter 1에서 이미 IN/EXISTS/JOIN(존재 여부 확인 패턴)을 다뤘으므로, 본 차시는
  **스칼라 서브쿼리·인라인 뷰·상관 서브쿼리**라는 다른 세 가지 패턴을 새로 다룸

---

## 01. Why

- Chapter 1에서 "결과가 같은 여러 SQL 중 실측으로 골라야 한다"는 원칙을 IN/EXISTS/JOIN
  사례로 확인했음
- 서브쿼리에는 그 외에도 스칼라 서브쿼리(SELECT 절에 값 하나를 붙이는 것), 인라인 뷰
  (FROM 절에 서브쿼리를 넣는 것), 상관 서브쿼리(바깥 쿼리 값을 참조하는 것) 등 쓰임새가
  다양함 — 본 차시는 이 세 가지를 실측으로 다룸

## 02. Concept

- Scalar Subquery(스칼라 서브쿼리): SELECT 절에서 단일 값 하나를 반환하는 서브쿼리.
  "이 행에 관련된 다른 테이블의 값 하나를 붙여오는" 용도로 흔히 쓰임
- Inline View(인라인 뷰): FROM 절에 괄호로 감싼 서브쿼리를 마치 테이블처럼 사용하는 것
- Correlated Subquery(상관 서브쿼리): 서브쿼리 내부에서 바깥 쿼리의 컬럼을 참조하는
  서브쿼리. 바깥 쿼리의 행이 바뀔 때마다 서브쿼리 결과도 달라질 수 있음(Chapter 1의
  EXISTS 서브쿼리도 상관 서브쿼리의 한 예였음)
- 서브쿼리와 JOIN의 관계: 옵티마이저는 많은 경우 서브쿼리를 조인 형태로 내부 변환
  (unnesting)해서 처리함 — Chapter 1의 IN/EXISTS가 둘 다 `HASH JOIN RIGHT SEMI`로
  변환됐던 것이 그 예

## 03. Oracle Internals — 스칼라 서브쿼리 캐싱

- 스칼라 서브�큐리는 문법상 "행마다 한 번씩" 실행되는 것처럼 보이지만, Oracle은 **같은
  입력 값에 대해 이미 계산한 서브쿼리 결과를 캐시**해서 재사용함(스칼라 서브쿼리 캐싱)
- 예를 들어 15,029개의 행이 있어도 그 안의 `HOSP_ID` 값이 5종류(1~5)뿐이라면, 스칼라
  서브쿼리는 이론상 최대 5번만 실제로 실행되고 나머지는 캐시에서 즉시 값을 가져옴
- 이 캐싱 덕분에 "SELECT 절에 서브쿼리를 쓰면 무조건 느리다(N+1과 유사)"는 통념이 항상
  맞지는 않음 — 참조하는 값의 **distinct 개수**가 적을수록 캐싱 효과가 커짐
- 상관 서브쿼리가 WHERE절에서 집계값과 비교되는 경우(예: "그룹 평균보다 큰 행"), 옵티마이저는
  이를 종종 **그룹별 집계를 미리 계산한 뷰 + 조인**형태로 변환함 — 이 역시 unnesting의
  한 형태

## 04. Example — 스칼라 서브쿼리 vs JOIN

```sql
-- Q1. 스칼라 서브쿼리로 병원명 붙이기
SELECT c.claim_id, c.total_amt,
       (SELECT h.hosp_name FROM hospitals h WHERE h.hosp_id = c.hosp_id) hosp_name
FROM medical_claims c
WHERE c.hosp_id <= 5;

-- Q2. JOIN으로 병원명 붙이기
SELECT c.claim_id, c.total_amt, h.hosp_name
FROM medical_claims c, hospitals h
WHERE c.hosp_id = h.hosp_id AND c.hosp_id <= 5;
```

## 05. Execution Plan — 실측 비교

**Q1. 스칼라 서브쿼리**

```text
| Id | Operation                   | Name           | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT            |                |      1 |        |  15029 |00:00:00.09 |    4081 |
| 1  |  TABLE ACCESS BY INDEX ROWID| HOSPITALS      |      5 |      1 |      5 |00:00:00.01 |      13 |
| 2  |   INDEX UNIQUE SCAN         | PK_HOSPITALS   |      5 |      1 |      5 |00:00:00.01 |       8 |
| 3  |  TABLE ACCESS FULL          | MEDICAL_CLAIMS |      1 |  14397 |  15029 |00:00:00.09 |    4081 |
```

**Q2. JOIN**

```text
| Id | Operation                          | Name           | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT                   |                |      1 |        |  15029 |00:00:00.02 |    4083 |
| 1  |  HASH JOIN                         |                |      1 |     72 |  15029 |00:00:00.02 |    4083 |
| 2  |   TABLE ACCESS BY INDEX ROWID BATCHED| HOSPITALS    |      1 |      5 |      5 |00:00:00.01 |       3 |
| 3  |    INDEX RANGE SCAN                | PK_HOSPITALS   |      1 |      5 |      5 |00:00:00.01 |       2 |
| 4  |   TABLE ACCESS FULL                | MEDICAL_CLAIMS |      1 |  14397 |  15029 |00:00:00.02 |    4080 |
```

- 결과 행은 15,029건으로 동일한데, Q1의 스칼라 서브쿼리는 `HOSPITALS`에 대해 `Starts=5`
  로만 접근했음 — 15,029번이 아니라 `HOSP_ID`의 distinct 값 개수(5)만큼만 실행됨(03절
  캐싱 원리)
- 그 결과 Q1(4,081)과 Q2(4,083) Buffers가 **거의 동일**함 — "스칼라 서브쿼리는 조인보다
  항상 느리다"는 통념이 이 사례에서는 성립하지 않음

## 06. Bad SQL — 상관 서브쿼리가 항상 저렴하지는 않음

```sql
-- Q3. 자신이 속한 병원의 평균보다 총액이 큰 청구
SELECT c.claim_id, c.hosp_id, c.total_amt
FROM medical_claims c
WHERE c.hosp_id <= 5
AND   c.total_amt > (SELECT AVG(c2.total_amt) FROM medical_claims c2 WHERE c2.hosp_id = c.hosp_id);
```

```text
| Id | Operation           | Name           | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT    |                |      1 |        |   6462 |00:00:00.03 |    6609 |
| 1  |  HASH JOIN          |                |      1 |   6922 |   6462 |00:00:00.03 |    6609 |
| 2  |   VIEW               | VW_SQ_1       |      1 |     48 |      5 |00:00:00.01 |    3090 |
| 3  |    HASH GROUP BY     |                |      1 |     48 |      5 |00:00:00.01 |    3090 |
| 4  |     TABLE ACCESS FULL| MEDICAL_CLAIMS |      1 |  14397 |  15029 |00:00:00.01 |    3090 |
| 5  |   TABLE ACCESS FULL  | MEDICAL_CLAIMS |      1 |  14397 |  15029 |00:00:00.01 |    3518 |
```

- Oracle은 이 상관 서브쿼리를 "행마다 반복 실행"하지 않고, `HOSP_ID`별 평균을 미리 한
  번에 계산하는 `VIEW VW_SQ_1`(내부적으로 `HASH GROUP BY`)로 변환한 뒤, 원본 데이터와
  다시 조인하는 형태로 처리함
- 문제는 이 변환이 결과적으로 `MEDICAL_CLAIMS`를 **두 번** 읽게 만든다는 점(Id 4에서
  한 번, Id 5에서 한 번) — Buffers가 6,609로, Q1·Q2(약 4,080대)보다 오히려 커짐
- 상관 서브쿼리가 자동으로 효율적인 형태로 변환되긴 하지만, "원본 테이블을 여러 번
  읽어야 하는 구조"라면 그 변환 자체가 비용을 늘릴 수 있음 — 무조건 저렴하다고 가정하면
  안 됨

## 07. Tuning — 인라인 뷰의 WHERE는 HAVING과 같아지는가

```sql
-- Q4. 인라인 뷰 + 바깥 WHERE
SELECT * FROM (SELECT hosp_id, COUNT(*) cnt FROM medical_claims GROUP BY hosp_id) v
WHERE v.cnt > 1000;

-- Q5. HAVING으로 직접 작성
SELECT hosp_id, COUNT(*) cnt FROM medical_claims GROUP BY hosp_id HAVING COUNT(*) > 1000;
```

| 쿼리 | Operation 구조 | Buffers |
|---|---|---:|
| Q4 (인라인 뷰) | `FILTER` → `HASH GROUP BY` → `TABLE ACCESS FULL` | 3,090 |
| Q5 (HAVING) | `HASH GROUP BY`(필터 내장) → `TABLE ACCESS FULL` | 3,090 |

- 두 방식 모두 테이블을 한 번만 읽고(`TABLE ACCESS FULL` 1회) Buffers가 동일하게 3,090
  — 옵티마이저가 인라인 뷰를 그 자리에서 병합(view merging)해 사실상 같은 비용으로
  처리함
- 다만 오퍼레이션 트리 모양은 약간 다름(Q4는 별도 `FILTER` 단계가 붙음) — 겉보기 SQL
  스타일이 달라도 비용은 같을 수 있다는 것을 보여주는 사례

## 08. Benchmark

| 비교 | 방식 A | 방식 B | Buffers A | Buffers B | 비고 |
|---|---|---|---:|---:|---|
| 값 하나 붙이기 | 스칼라 서브쿼리 | JOIN | 4,081 | 4,083 | distinct 값이 적어 캐싱으로 거의 동일 |
| 그룹 평균과 비교 | 상관 서브쿼리 | (JOIN 미측정) | 6,609 | - | 테이블 2회 스캔되는 구조라 오히려 비쌈 |
| 집계 결과 필터링 | 인라인 뷰+WHERE | HAVING | 3,090 | 3,090 | 뷰 병합으로 완전히 동등 |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch08_문제.md` 참고

## 10. Review

- 스칼라 서브쿼리는 캐싱 덕분에 참조 값의 distinct 개수가 적으면 JOIN과 비슷한 비용이
  될 수 있음 — "서브쿼리 = 항상 느림"은 통념일 뿐, 실측해야 함
- 상관 서브쿼리도 옵티마이저가 조인 형태로 변환하지만, 그 변환이 원본 테이블을 여러 번
  읽게 만드는 구조라면 오히려 손해일 수 있음
- 인라인 뷰의 바깥 WHERE 조건은 많은 경우 HAVING과 동등하게 처리(view merging)되므로,
  두 문법 중 가독성이 좋은 쪽을 골라도 무방한 경우가 많음 — 다만 항상 실행계획으로
  확인해야 함
