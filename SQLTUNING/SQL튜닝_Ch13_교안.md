# Chapter 13. Optimizer와 통계정보

- 본 차시는 통계정보를 일시적으로 변경함(`HOSP_ID` 컬럼 히스토그램 제거 후 복원).
  종료 시 원래 상태(HYBRID, 254버킷)로 정확히 복원 완료 확인
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: `MEDICAL_CLAIMS.HOSP_ID`의 실제 스큐(1~50번 병원에 청구 50% 집중)를 놓고,
  히스토그램이 있을 때/없을 때 E-Rows 추정치가 어떻게 달라지는지 직접 제거·복원하며 실측

---

## 01. Why

- Chapter 2에서 `HOSP_ID`에 히스토그램이 있어서 리터럴 값마다 다른 E-Rows가 나온다는
  것을 확인했음 — 하지만 히스토그램이 "없었다면" 어땠을지는 실제로 없애보지 않으면
  알 수 없음
- 본 차시 목표: 같은 컬럼, 같은 데이터로 히스토그램 유무를 직접 통제해가며 카디널리티
  추정에 미치는 영향을 눈으로 확인함

## 02. Concept

- CBO(Cost-Based Optimizer): 통계정보를 근거로 비용을 계산해 실행 방법을 고름
- Table/Column Statistics: 테이블 행 수, 컬럼별 고유값 개수(NDV), 최소/최대값 등
- Histogram(히스토그램): 컬럼 값의 분포를 구간(버킷)별로 기록한 통계 — 값이 균등하게
  분포하지 않는(스큐가 있는) 컬럼에서 정확한 추정을 가능하게 함
- Cardinality/Selectivity: 조건을 만족하는 행의 개수/비율. 히스토그램 유무가 이 추정치의
  정확도를 좌우함

## 03. Oracle Internals — 히스토그램이 없으면 무슨 값으로 추정하는가

- 히스토그램이 없는 컬럼의 등치 조건(`컬럼 = 값`)에 대한 E-Rows는 대략
  **`전체 행 수 ÷ NDV(고유값 개수)`**로 계산됨 — 모든 값이 똑같은 빈도로 나타난다는
  **균등 분포 가정**
- `MEDICAL_CLAIMS`는 300,000행이고 `HOSP_ID`의 NDV는 1,000이므로, 히스토그램이 없으면
  **어떤 `HOSP_ID` 값을 조회하든 E-Rows는 항상 300,000÷1,000=300으로 동일**하게 계산됨
- 히스토그램이 있으면 실제 값별 빈도를 버킷 단위로 반영하므로, 자주 나오는 값(스큐된
  값)과 드문 값을 구분해서 추정할 수 있음

## 04. Example — 히스토그램 있는 상태(현재)에서의 베이스라인

```sql
SELECT COUNT(*) FROM medical_claims WHERE hosp_id = 1;    -- 쏠린 병원(스큐)
SELECT COUNT(*) FROM medical_claims WHERE hosp_id = 500;  -- 일반 병원
```

`USER_TAB_COL_STATISTICS` 확인: `HOSP_ID` — `HISTOGRAM=HYBRID`, `NUM_BUCKETS=254`

## 05. Execution Plan — 히스토그램 있을 때 (베이스라인)

| 조건 | E-Rows | A-Rows | 추정 정확도 |
|---|---:|---:|---|
| `hosp_id=1`(스큐) | 3,470 | 3,058 | 근접(비율 약 1.13배) |
| `hosp_id=500`(일반) | 159 | 177 | 근접(비율 약 0.90배) |

- 두 값이 서로 다른 E-Rows를 받았고, 둘 다 실제값(A-Rows)에 상당히 근접함 — 히스토그램이
  스큐를 정확히 반영하고 있다는 뜻

## 06. Bad SQL — 히스토그램을 강제로 제거하면

```sql
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'MEDICAL_CLAIMS',
    METHOD_OPT => 'FOR COLUMNS HOSP_ID SIZE 1');  -- 버킷 1개 = 히스토그램 없음
END;
/
```

`USER_TAB_COL_STATISTICS` 재확인: `HOSP_ID` — `HISTOGRAM=NONE`, `NUM_BUCKETS=1`

| 조건 | E-Rows | A-Rows | 추정 정확도 |
|---|---:|---:|---|
| `hosp_id=1`(스큐) | **300** | 3,058 | **약 10.2배 과소추정** |
| `hosp_id=500`(일반) | **300** | 177 | 약 1.7배 과대추정 |

- 두 조건의 **E-Rows가 정확히 300으로 동일**해짐 — `300,000÷1,000`의 균등 분포 가정
  (03절)이 그대로 적용된 것이 숫자로 확인됨
- 실제로 3,058건이나 걸리는 쏠린 병원을 겨우 300건으로 추정 — 만약 이 조회가 더 큰
  쿼리(조인 등)의 일부였다면, 이렇게 과소평가된 예상 행 수 때문에 옵티마이저가
  부적절한 조인 방식(예: NL Join, Chapter 7)을 선택해 실제로는 큰 손해를 볼 수 있는
  상황이었음

## 07. Tuning — 히스토그램 복원과 확인

```sql
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'MEDICAL_CLAIMS',
    METHOD_OPT => 'FOR ALL COLUMNS SIZE AUTO');  -- 자동 판단으로 원복
END;
/
```

`USER_TAB_COL_STATISTICS` 재확인: `HOSP_ID` — `HISTOGRAM=HYBRID`, `NUM_BUCKETS=254`
(원상복구됨)

| 조건 | E-Rows | A-Rows | 추정 정확도 |
|---|---:|---:|---|
| `hosp_id=1`(스큐, 복원 후) | 3,285 | 3,058 | 근접(비율 약 1.07배) |

- 히스토그램을 복원하자 다시 스큐를 반영한 정확한 추정으로 돌아옴(수치가 04절의
  3,470과 완전히 같지는 않은데, 이는 통계 수집이 표본추출 기반이라 매번 약간씩 다를 수
  있기 때문 — 그래도 두 값 다 3,000대로 실제값에 근접함은 동일)
- `METHOD_OPT => 'FOR ALL COLUMNS SIZE AUTO'`는 Oracle이 각 컬럼의 데이터 분포를 보고
  히스토그램이 필요한지 스스로 판단하게 하는 옵션 — 이 스키마처럼 스큐가 실제로 있는
  컬럼에는 자동으로 히스토그램을 만들어준다

## 08. Benchmark

| 상태 | hosp_id=1 E-Rows | hosp_id=500 E-Rows | 두 값이 다른가? |
|---|---:|---:|---|
| 히스토그램 있음(원본) | 3,470 | 159 | 다름(스큐 반영) |
| 히스토그램 제거(SIZE 1) | 300 | 300 | **동일**(균등 가정) |
| 히스토그램 복원(AUTO) | 3,285 | (재측정 안 함, 복원 확인만) | 다시 다름 |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch13_문제.md` 참고

## 10. Review

- 히스토그램이 없는 컬럼의 등치 조건 E-Rows는 `전체 행 수 ÷ NDV`로 계산되며, 어떤 값을
  조회하든 항상 같은 값이 나옴(균등 분포 가정)
- 히스토그램이 있으면 실제 값별 빈도를 반영해 스큐를 정확히 추정할 수 있음
- `DBMS_STATS.GATHER_TABLE_STATS`의 `METHOD_OPT`로 히스토그램 생성 여부를 제어할 수
  있고, `SIZE AUTO`는 Oracle이 스큐 여부를 스스로 판단해 필요한 컬럼에만 히스토그램을
  만들어줌
- 카디널리티 추정이 크게 틀리면(이번 사례 10배) 그 SQL이 더 큰 쿼리의 일부일 때 조인
  방식 등 후속 판단까지 잘못될 위험이 있음(Chapter 3 Q1, Chapter 7과 연결)
- 통계정보는 `USER_TAB_COL_STATISTICS`(`HISTOGRAM`, `NUM_BUCKETS` 컬럼)로 직접 확인할
  수 있음
