# Chapter 6. SARGable SQL

- 본 차시는 실습용 인덱스를 생성·삭제함(`IX_CH06_` 접두어). 종료 시 원상복구 확인 완료
  (`PATIENTS`, `MEDICAL_CLAIMS` 모두 PK만 남음)
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: `PATIENTS.BIRTH_DATE`(VARCHAR2 YYYYMMDD)와 `MEDICAL_CLAIMS.RECEIPT_DATE`(DATE)
  두 컬럼에서 조건절 작성 방식에 따라 인덱스 사용 여부가 어떻게 갈리는지 확인

---

## 01. Why

- Chapter 5에서 "인덱스를 만들면 빨라진다"를 확인했지만, **인덱스가 있어도 조건절을
  잘못 쓰면 아예 못 탈 수 있다**는 사실은 다루지 않음
- SARGable(Search ARGument-able)한 조건: 인덱스를 탐색하는 데 그대로 쓸 수 있는 형태의
  조건. 컬럼을 가공하지 않고 원래 값 그대로 비교하는 조건이 SARGable함
- 본 차시 목표: 인덱스가 있어도 못 타는 대표 패턴(함수, 묵시적 형변환)을 실측으로 확인

## 02. Concept

- 함수와 인덱스: 컬럼에 함수를 씌우면(`TO_NUMBER(col)`, `SUBSTR(col,..)` 등) 일반 인덱스는
  "가공되지 않은 원본 값"을 기준으로 정렬돼 있으므로 더 이상 그 인덱스로 바로 찾아갈 수 없음
- 묵시적 형변환: 조건에서 컬럼과 리터럴의 데이터 타입이 다르면, Oracle이 **둘 중 하나를
  자동으로 변환**해서 비교함. 이때 어느 쪽이 변환되는지가 인덱스 사용 여부를 가름
- 연산식, LIKE, 부정 조건(`!=`, `NOT IN`), NULL 조건(`IS NULL`)도 컬럼을 가공하거나
  인덱스의 정렬 특성과 안 맞아 인덱스를 못 타는 경우가 흔함 — 본 차시는 함수·형변환
  위주로 실측하고 나머지는 07절에서 간단히 짚음

## 03. Oracle Internals — 묵시적 형변환의 방향

- Oracle의 데이터 타입 우선순위(단순화): NUMBER가 VARCHAR2보다 우선순위가 높음
- `VARCHAR2` 컬럼을 `NUMBER` 리터럴과 비교하면(`WHERE varchar_col <= 19901231`), Oracle은
  **리터럴이 아니라 컬럼 쪽을 `TO_NUMBER()`로 감싸서** 비교함 — 사람이 보기엔 컬럼을 건드린
  적이 없어 보이지만 내부적으로는 컬럼에 함수가 씌워진 것과 동일한 효과가 발생함
- 즉 "리터럴에 작은따옴표를 빼먹었을 뿐"인데도 인덱스를 못 타게 만들 수 있음 — 04절 Q2
  사례가 정확히 이 경우

## 04. Example — BIRTH_DATE 세 가지 조건절 비교

```sql
CREATE INDEX ix_birth ON patients(birth_date);

-- Q1. SARGable: 문자열 리터럴 그대로 비교
SELECT COUNT(*) FROM patients WHERE birth_date <= '19901231';

-- Q2. 묵시적 형변환: 숫자 리터럴(따옴표 없음)과 비교
SELECT COUNT(*) FROM patients WHERE birth_date <= 19901231;

-- Q3. 명시적 함수: 컬럼을 직접 가공
SELECT COUNT(*) FROM patients WHERE TO_NUMBER(SUBSTR(birth_date,1,4)) <= 1990;
```

## 05. Execution Plan — 실측 비교

| 쿼리 | Operation | Buffers | Predicate Information |
|---|---|---:|---|
| Q1 (문자열 리터럴) | INDEX FAST FULL SCAN | 148 | `filter("BIRTH_DATE"<='19901231')` |
| Q2 (숫자 리터럴, 형변환) | TABLE ACCESS FULL | 442 | `filter(TO_NUMBER("BIRTH_DATE")<=19901231)` |
| Q3 (명시적 함수) | TABLE ACCESS FULL | 442 | `filter(TO_NUMBER(SUBSTR("BIRTH_DATE",1,4))<=1990)` |

- Q1과 Q2는 SQL 상으로는 "따옴표가 있느냐 없느냐"만 다른데, 실행계획은 완전히 다름
- Q2의 `Predicate Information`을 보면 `TO_NUMBER("BIRTH_DATE")`처럼 **컬럼이 함수로
  감싸인 형태**로 나타남 — 이것이 Oracle이 리터럴이 아니라 컬럼 쪽을 변환했다는 직접적인
  증거임
- Q2와 Q3의 실행계획(Plan hash value)이 완전히 동일함 — 옵티마이저 입장에서는 "묵시적으로
  생긴 TO_NUMBER"나 "개발자가 명시적으로 쓴 TO_NUMBER(SUBSTR(..))"나 **컬럼이 가공됐다는
  점에서 동일하게 취급**됨

## 06. Bad SQL — DATE 컬럼에서도 동일한 문제 재현

```sql
CREATE INDEX ix_receipt ON medical_claims(receipt_date);

-- Q4. SARGable: 범위 조건으로 그대로 비교
SELECT COUNT(*) FROM medical_claims
WHERE receipt_date >= DATE'2024-06-01' AND receipt_date < DATE'2024-07-01';

-- Q5. 함수로 가공: 월 단위 문자열 비교
SELECT COUNT(*) FROM medical_claims
WHERE TO_CHAR(receipt_date,'YYYYMM') = '202406';
```

| 쿼리 | Operation | Buffers | Predicate Information |
|---|---|---:|---|
| Q4 (범위 조건) | INDEX RANGE SCAN | 68 | `access("RECEIPT_DATE">=... AND "RECEIPT_DATE"<...)` |
| Q5 (TO_CHAR 가공) | TABLE ACCESS FULL | 3,090 | `filter(TO_CHAR(...,'YYYYMM')='202406')` |

- 결과 건수는 두 쿼리 모두 24,655건으로 완전히 같은데, Buffers는 68 vs 3,090으로 45배
  이상 차이 남
- Q5처럼 "이번 달 데이터를 가져오자"는 흔한 요구를 `TO_CHAR(컬럼,'YYYYMM')='202406'`으로
  구현하면 인덱스가 있어도 못 씀 — Q4처럼 범위 조건(`>=` / `<`)으로 바꿔야 함

## 07. Tuning — 그 밖의 SARGable 위반 패턴 (개념 정리)

- `LIKE '%검색어%'`(앞에 `%`가 붙는 패턴): 인덱스가 왼쪽부터 정렬돼 있어 중간부터 일치하는
  값을 바로 찾을 방법이 없음 — 일반 B-Tree 인덱스로는 지원 불가(전문 검색 인덱스 등 별도
  기법 필요, 본 과정 범위 밖)
- 부정 조건(`!=`, `NOT IN`, `NOT LIKE`): "이 값이 아닌 것"은 인덱스 구조상 범위로 표현하기
  어려워 대개 Full Scan으로 처리됨
- `IS NULL`: 기본 B-Tree 인덱스는 **모든 컬럼 값이 NULL인 행을 아예 인덱스에 저장하지
  않음** — 그래서 `IS NULL` 조건은 그 인덱스를 쓸 수 없음(복합 인덱스 중 일부 컬럼만
  NULL이면 저장되므로 예외 있음)

## 08. Benchmark

| 컬럼 | SARGable 조건 | 위반 조건 | Buffers 차이 |
|---|---|---|---|
| PATIENTS.BIRTH_DATE | `<= '19901231'` | `<= 19901231`(형변환) | 148 vs 442 (3배) |
| MEDICAL_CLAIMS.RECEIPT_DATE | 범위(`>=`/`<`) | `TO_CHAR(..)='202406'` | 68 vs 3,090 (45배) |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch06_문제.md` 참고

## 10. Review

- 컬럼에 함수를 씌우면(명시적이든 묵시적이든) 일반 인덱스를 탈 수 없게 됨
- 데이터 타입이 다른 리터럴과 비교하면 Oracle이 컬럼 쪽을 자동 변환할 수 있음 — 이때
  변환된 컬럼은 함수가 씌워진 것과 같은 효과를 냄. `Predicate Information`에서 컬럼이
  함수로 감싸여 있는지 확인하면 진단 가능함
- "월 단위로 가져오자" 같은 요구는 `TO_CHAR(..)=...`가 아니라 범위 조건(`>=`/`<`)으로
  작성해야 인덱스를 탈 수 있음
- LIKE 앞부분 와일드카드, 부정 조건, IS NULL도 일반 인덱스와 궁합이 나쁜 대표 패턴임
