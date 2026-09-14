# Oracle SQL 튜닝 실전 과정 — 최종 종합 실습 테스트 (50제)

Chapter 1~14 전 범위를 통합하는 최종 실습 테스트입니다. 모든 문항은 **직접 SQL을 작성·
실행하고 실행계획 또는 통계 뷰(`V$SQL` 등)로 측정한 값을 근거로 답하는 실습형 문제**이며,
서술형/암기형 문제는 없습니다. 실습 DB(SQLT 계정)에 접속해 실습하십시오. Oracle
전통 조인 문법(`FROM a, b WHERE`, 아우터 조인은 `(+)`)을 기준으로 작성하십시오. 인덱스를
새로 만드는 문항은 `IX_FINAL_` 접두어를 쓰고, 실습 종료 후 반드시 `DROP INDEX`로
정리한 뒤 `USER_INDEXES`로 원상복구를 확인하십시오.

**제출 형식(모든 문항 공통)**: 작성한 SQL, `DBMS_XPLAN` 결과(또는 `V$SQL` 조회 결과),
측정값을 근거로 한 짧은 결론 1~2줄.

---

## I. SQL 튜닝 기초 · SQL 처리 과정 (1~10번)

**1. [상]** `DRUG_MASTER`에서 `CATEGORY='처치'`인 약품을 처방받은 청구를 IN, EXISTS,
JOIN 세 가지 방식으로 각각 작성하고 `DBMS_XPLAN.DISPLAY_CURSOR(...'ALLSTATS LAST')`로
Buffers를 측정해 비교표를 만드시오.

**2. [상]** 1번의 세 SQL을 실행 순서를 두 번 바꿔가며(예: JOIN→IN→EXISTS, 그다음
EXISTS→IN→JOIN) 각각 실행하고, 먼저 실행된 것과 나중에 실행된 것의 A-Time 차이가
있는지 측정하시오.

**3. [최상]** 1번 IN·EXISTS 버전의 실행계획을 나란히 놓고 Plan Operation 구성이
동일한지 확인하시오. 동일하다면 `VIEW` 이름(`VW_NSO_*`/`VW_SQ_*`)만 다른지 캡처해
제시하시오.

**4. [상]** `WHERE pat_id = 100`과 `WHERE pat_id = '100'`(문자열 리터럴)을 각각 실행한
뒤 `V$SQL`에서 `SQL_TEXT`, `SQL_ID`를 조회해 두 SQL이 같은 SQL_ID를 쓰는지 확인하시오.

**5. [상]** `VARIABLE b1 NUMBER`로 바인드 변수를 선언하고 `WHERE pat_id = :b1`에 100과
200을 순서대로 대입해 두 번 실행한 뒤, `V$SQL`에서 `EXECUTIONS`가 2로 나오는지
확인하시오.

**6. [최상]** `DISEASES`와 `MEDICAL_CLAIMS`, `PATIENTS`를 조인해 "J00 진단을 받은
환자명"을 조회하는 SQL을 작성하고, 실행계획에 `MEDICAL_CLAIMS` 테이블 접근이 나타나는지
확인하시오. 나타나지 않는다면(또는 나타난다면) `Predicate Information`을 근거로 그
이유를 설명하시오.

**7. [상]** `HOSPITALS`에서 `HOSP_ID<=200`인 행을 (a) `SELECT *`, (b) `SELECT hosp_id,
hosp_name`만 조회하는 두 버전으로 작성해 `Bytes`(EXPLAIN PLAN 기준)를 비교하시오.

**8. [상]** 임의의 SQL 하나를 골라 `EXPLAIN PLAN FOR`로 뽑은 Rows/Cost와,
`DBMS_XPLAN.DISPLAY_CURSOR`로 뽑은 E-Rows/A-Rows/Buffers를 한 표에 정리하시오.

**9. [상]** `(SELECT h.hosp_name FROM hospitals h WHERE h.hosp_id=c.hosp_id)` 형태의
스칼라 서브쿼리를 `hosp_id<=5`(distinct 5개)와 `hosp_id<=200`(distinct 200개) 두
조건에 각각 적용해 `HOSPITALS` 접근의 `Starts` 값이 어떻게 달라지는지 측정하시오.

**10. [최상]** 이 스키마에서 "통념과 다른 결과가 나올 것 같다"고 스스로 예상되는 SQL
비교(예: 서로 다른 두 방식)를 직접 설계해 실행하고, 예상과 실제 측정 결과가 같았는지
달랐는지 보고하시오.

## II. 실행계획 판독 · 성능 측정 (11~20번)

**11. [상]** `CLAIM_DETAILS`에서 `QTY >= 3`인 행을 조회하는 SQL의 `EXPLAIN PLAN`을
뽑아 Id/Operation/Rows/Cost/Predicate Information을 표로 정리하시오.

**12. [상]** 11번 SQL을 실제 실행(`ALLSTATS LAST`)해 E-Rows와 A-Rows를 비교하고,
오차 비율을 계산하시오.

**13. [최상]** `HOSPITALS`와 `PATIENTS` 중 본인이 직접 고른 조인 조건으로 SQL을
작성해 실행계획을 뽑고, 들여쓰기를 기준으로 실행 순서를 번호로 표시하시오(예: "4→3→5→2→1→0").

**14. [상]** `PATIENTS.PAT_ID`에 대해 (a) 등치 조건, (b) `BETWEEN` 범위 조건,
(c) `ORDER BY pat_id`가 붙은 조건 세 가지로 SQL을 작성해 실행하고, 각각 어떤
`INDEX` 오퍼레이션이 나오는지 확인하시오.

**15. [상]** 임의의 SQL 하나를 골라 Cost를 확인한 뒤, 완전히 다른 테이블을 대상으로
한 다른 SQL의 Cost와 비교해보고, 두 Cost가 비슷하거나 다를 때 실제 A-Time도 그 관계를
따르는지 실측으로 확인하시오.

**16. [최상]** `MEDICAL_CLAIMS`에서 임의의 좁은 범위(예: 특정 하루) 조회를 연속으로
2번 실행하고, 첫 실행과 두 번째 실행의 `A-Time` 차이를 측정해 캐시 효과가 관찰되는지
보고하시오.

**17. [상]** `DRUG_MASTER`에서 `PRICE > 40000`인 약품을 (a) `COUNT(*)`만, (b)
`SELECT *`로 전체 컬럼을 조회하는 두 버전으로 작성해 Buffers를 비교하시오.

**18. [상]** `MEDICAL_CLAIMS`에서 PK 컬럼(`CLAIM_ID`)의 매우 좁은 범위(0.5% 이내)에
`FETCH FIRST 10 ROWS ONLY`를 붙인 SQL을 작성해 `WINDOW NOSORT STOPKEY`가 나오는지
확인하시오.

**19. [최상]** 임의의 SQL 하나를 5번 연속 실행하고 각 실행의 A-Time을 기록해, 실행
횟수가 늘수록 A-Time이 어떻게 변하는지(안정화되는지) 표로 제시하시오.

**20. [최상]** 지금까지 이 세션에서 본인이 실행한 SQL 중 `V$SQL`에서
`EXECUTIONS`가 가장 높은 것을 찾아 `SQL_TEXT`와 함께 제시하시오.

## III. 인덱스 설계 · SARGable SQL (21~30번)

**21. [상]** `PATIENTS`(5만 건, 작음)와 `CLAIM_DETAILS`(약 90만 건, 큼)에서 각각
"조건에 맞는 행이 소수(10건 이내)인" Full Scan SQL을 하나씩 작성해 Buffers를 비교하고,
결과 건수가 비슷한데도 Buffers가 크게 다른지 확인하시오.

**22. [상]** `MEDICAL_CLAIMS.CLAIM_ID` 범위 조회의 선택도를 0.5%, 5%, 15%로 각각
다르게 설정한 세 개의 SQL을 작성해 실행하고, 어느 지점에서 `TABLE ACCESS FULL`로
전환되는지 직접 찾으시오.

**23. [최상]** 22번과 같은 범위 조건에서 `COUNT(*)`만 필요한 버전과 `TOTAL_AMT`가
필요한 버전을 각각 작성해, 두 버전의 전환 지점(몇 % 선택도부터 Full Scan인지)이
다른지 비교하시오.

**24. [상]** `MEDICAL_CLAIMS(HOSP_ID, REVIEW_STATUS)` 복합 인덱스를 `IX_FINAL_A`로
만들고, `WHERE hosp_id=1`(선두 컬럼만), `WHERE review_status='심사중'`(후행 컬럼만)
두 조건으로 각각 실행해 Buffers 차이를 측정하시오. 측정 후 인덱스를 삭제하시오.

**25. [상]** `PATIENTS.BIRTH_DATE`(YYYYMMDD 문자열)에 대해 `WHERE birth_date <=
20000101`(따옴표 없음)로 조회한 뒤 `Predicate Information`에 어떤 함수가 나타나는지
확인하시오.

**26. [최상]** 25번의 문제를 SARGable하게 재작성한 SQL을 작성하고, 두 버전의
Buffers를 비교하시오(인덱스가 없다면 `IX_FINAL_B`를 `BIRTH_DATE`에 만들어 비교한 뒤
삭제하시오).

**27. [상]** `MEDICAL_CLAIMS`에서 "8월 청구 건수"를 (a) `TO_CHAR(receipt_date,
'YYYYMM')='202408'`, (b) 범위 조건(`>=`/`<`)으로 각각 작성해 Buffers를 비교하시오.
(인덱스가 필요하면 `IX_FINAL_C`를 `RECEIPT_DATE`에 만든 뒤 비교하고 삭제하시오.)

**28. [상]** `MEDICAL_CLAIMS`에서 PK 좁은 범위(1일 이내)를 대상으로 `ORDER BY
claim_id`와 `ORDER BY total_amt` 두 버전을 실행해, 어느 쪽에서 `SORT` 오퍼레이션이
생략되는지 확인하시오.

**29. [최상]** `IX_FINAL_A`(24번)를 다시 만들되 이번엔 컬럼 순서를 반대로
(`REVIEW_STATUS, HOSP_ID`) 만들고, 24번과 같은 두 조건을 재실행해 결과가 어떻게
뒤바뀌는지 측정한 뒤 삭제하시오.

**30. [상]** `USER_INDEXES`를 조회해 현재 `MEDICAL_CLAIMS`, `PATIENTS`에 PK 외
인덱스가 없는 상태(원본)인지 확인하시오. 만약 남아있는 인덱스가 있다면 어느 문항에서
정리를 빠뜨렸는지 찾아 정리하시오.

## IV. 서브쿼리 · 집합연산 · 정렬/집계 (31~40번)

**31. [상]** `MEDICAL_CLAIMS`에서 "외래 청구를 낸 환자" ∪ "보훈 대상 환자"를 `UNION`과
`UNION ALL`로 각각 조회해 결과 건수 차이를 확인하고, 실제로 중복이 존재하는지
판단하시오.

**32. [상]** 31번의 `UNION`/`UNION ALL` 두 SQL의 Buffers를 비교하고, 만약 같다면
`A-Time`이나 `Used-Mem`으로 추가 비교하시오.

**33. [최상]** `MEDICAL_CLAIMS`에서 "자신이 속한 진료과(`DEPT_CODE`) 평균보다 총액이
큰 청구"를 상관 서브쿼리로 작성해 실행계획을 확인하고, `MEDICAL_CLAIMS`에 대한 접근이
몇 번 나타나는지 세시오.

**34. [상]** `PATIENTS.PAT_ID`(PK)에 불필요한 `DISTINCT`를 붙인 SQL과 안 붙인 SQL을
각각 작성해 실행계획이 동일한지 확인하시오.

**35. [최상]** `MEDICAL_CLAIMS.HOSP_ID`(FK, PK 아님)에 `DISTINCT`를 붙인 SQL을
작성해, 34번과 달리 `SORT UNIQUE`나 `HASH UNIQUE`가 실제로 나타나는지 확인하시오.

**36. [상]** `MEDICAL_CLAIMS`에서 `WHERE review_status='심사완료'`로 먼저 필터한 뒤
`GROUP BY hosp_id`하는 버전과, `GROUP BY hosp_id, review_status`한 뒤 바깥에서
필터하는 버전을 각각 작성해 실행계획이 같은지 비교하시오.

**37. [상]** 인라인 뷰로 "병원별 청구 건수가 2,500건 넘는 병원"을 조회하는 SQL과,
`HAVING`으로 동일 조건을 작성한 SQL을 각각 실행해 Buffers를 비교하시오.

**38. [최상]** `CLAIM_DETAILS`에서 임의의 좁은 조건(1% 이내 선택도)에 `ORDER BY
detail_id`(PK)를 붙인 SQL과 `ORDER BY amt`(비인덱스)를 붙인 SQL을 비교해, `HASH
GROUP BY`가 없는데도 `SORT`가 생략/미생략되는 패턴이 재현되는지 확인하시오.

**39. [상]** 31번의 `UNION` 버전과 Chapter 11 스타일의 OFFSET 깊은 페이징 SQL을 하나씩
실행해, 두 경우 모두 Buffers는 비슷한데 A-Time이나 메모리가 차이 나는지 비교하시오.

**40. [최상]** 서브쿼리·집합연산·집계 세 영역에서 각각 하나씩(원하는 조건으로) SQL을
작성해 실행한 뒤, 그중 옵티마이저가 예상보다 유리하게 처리해준 사례가 있었는지 실측
근거와 함께 보고하시오.

## V. JOIN 실행 원리 (41~45번)

**41. [상]** `HOSPITALS`(`HOSP_ID<=3`)와 `MEDICAL_CLAIMS`를 조인하는 SQL을 힌트 없이
실행해 어떤 조인 방식이 선택되는지 확인하시오.

**42. [최상]** 41번 SQL에 `/*+ USE_NL(h m) */` 힌트를 붙여 실행하고, 실제로
`NESTED LOOPS`가 나타나는지, 아니면 다른 방식으로 대체되는지 확인하시오.

**43. [상]** `MEDICAL_CLAIMS(HOSP_ID)`에 `IX_FINAL_D` 인덱스를 만든 뒤 41·42번을
재실행해 Buffers가 어떻게 달라지는지 측정하고, 인덱스를 삭제하시오.

**44. [상]** 43번(인덱스 있는 상태)의 실행계획에서 `Starts` 컬럼을 근거로 어느
테이블이 Driving(Outer)인지 판단하시오.

**45. [최상]** `HOSP_ID<=3` 대신 `HOSP_ID<=300`(Outer 행이 훨씬 많음)으로 바꿔
43번을 재실행하고, NL Join의 Buffers가 어떻게 달라지는지(또는 옵티마이저가 다른
방식으로 바꾸는지) 확인하시오.

## VI. 종합 실습 (46~50번)

**46. [상]** `MEDICAL_CLAIMS(RECEIPT_DATE)`에 `IX_FINAL_E` 인덱스를 만들고,
`OFFSET 0`과 `OFFSET 100000`으로 페이징 SQL을 각각 실행해 Buffers·A-Time을
비교한 뒤, 같은 깊이의 Keyset 버전과 다시 비교하시오. 측정 후 인덱스를 삭제하시오.

**47. [상]** `HOSPITALS`에서 임의의 병원 10곳의 `HOSP_ID`를 뽑아, (a) PL/SQL 루프로
`CLAIM_DETAILS`를 건별 반복 조회, (b) 조인 1회로 동일 결과를 조회하는 두 방식을
각각 실행해 `V$SQL` 누적 Buffers를 비교하시오.

**48. [최상]** `MEDICAL_CLAIMS.HOSP_ID`의 히스토그램을 `METHOD_OPT=>'FOR COLUMNS
HOSP_ID SIZE 1'`로 제거한 뒤 `HOSP_ID=1`과 `HOSP_ID=900`(둘 다 임의로 선택)의
E-Rows가 같아지는지 확인하고, 히스토그램을 `SIZE AUTO`로 복원하시오.

**49. [상]** 이 최종 테스트를 진행하며 만든 모든 `IX_FINAL_*` 인덱스가 남아있지
않은지 `USER_INDEXES`로 최종 확인하시오.

**50. [최상]** 지금까지 47개 문항에서 측정한 결과 중 자신이 가장 인상 깊었던 실측
결과(수치) 3가지를 골라, 각각의 SQL과 측정값을 근거로 제시하고 왜 그 결과가
중요하다고 생각하는지 1~2줄로 정리하시오.
