# Oracle Database 19c: SQL Workshop
## Chapter 14 — 뷰(View) 생성

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- 단순 뷰와 복합 뷰를 생성한다
- 뷰에서 데이터를 조회한다
- 데이터 딕셔너리 뷰를 통해 뷰 정보를 조회한다

---

## 1. 뷰(View) 개요

### 1-1. 뷰란?

뷰(View)는 하나 이상의 테이블 데이터를 논리적으로 표현하는 **데이터베이스 객체**다.  
실제 데이터를 저장하지 않으며, 데이터 딕셔너리에 서브쿼리 정의만 저장된다.

```
[ EMPLOYEES 테이블 ]
  └─ CREATE VIEW ──→ [ EMPLOYEES VIEW ]
                        └─ 포털/보고서/애플리케이션에서 사용
```

### 1-2. 뷰를 사용하는 이유

| 목적 | 설명 |
|------|------|
| 데이터 접근 제한 | 민감한 열(급여, 주민번호 등)을 숨김 |
| 복잡한 쿼리 단순화 | 복잡한 JOIN·집계를 뷰로 캡슐화 |
| 데이터 독립성 | 기반 테이블 구조가 바뀌어도 애플리케이션 코드 변경 최소화 |
| 다양한 데이터 관점 | 같은 데이터를 다른 사용자에게 다른 방식으로 제공 |

### 1-3. 데이터베이스 객체 요약

| 객체 | 설명 |
|------|------|
| Table | 데이터 저장 기본 단위 |
| **View** | **하나 이상의 테이블에서 데이터를 논리적으로 표현** |
| Sequence | 숫자 값 자동 생성 |
| Index | 데이터 검색 성능 향상 |
| Synonym | 객체에 대체 이름 부여 |

---

## 2. 단순 뷰 vs 복합 뷰

| 특징 | 단순 뷰 | 복합 뷰 |
|------|---------|---------|
| 기반 테이블 수 | 1개 | 1개 이상 |
| 함수 포함 | 불가 | 가능 |
| 그룹 데이터 | 불가 | 가능 |
| DML 수행 | 가능 | 제한적 |

---

## 3. 뷰 생성

### 3-1. CREATE VIEW 기본 구문

```sql
CREATE [OR REPLACE] [FORCE|NOFORCE] VIEW view_name
    [(alias [, alias]...)]
AS subquery
[WITH CHECK OPTION [CONSTRAINT constraint_name]]
[WITH READ ONLY [CONSTRAINT constraint_name]];
```

| 옵션 | 설명 |
|------|------|
| `OR REPLACE` | 이미 존재하면 자동으로 재생성 (DROP 없이) |
| `FORCE` | 기반 테이블이 없어도 뷰 생성 (나중에 테이블 생성 예정) |
| `NOFORCE` | 기반 테이블이 있어야만 생성 (기본값) |
| `alias` | 서브쿼리 열에 별칭 지정 |
| `WITH CHECK OPTION` | 뷰를 통한 DML 시 WHERE 조건 준수 강제 |
| `WITH READ ONLY` | 뷰를 통한 DML 완전 차단 |

### 3-2. 단순 뷰 생성 예제

```sql
-- 부서 80번 직원 정보 뷰
CREATE VIEW empvu80
AS SELECT employee_id, last_name, salary
   FROM   employees
   WHERE  department_id = 80;

-- 뷰 구조 확인
DESCRIBE empvu80;
```

### 3-3. 열 별칭 사용

```sql
-- 서브쿼리에서 직접 별칭 지정
CREATE VIEW salvu50
AS SELECT employee_id  ID_NUMBER,
          last_name    NAME,
          salary * 12  ANN_SALARY
   FROM   employees
   WHERE  department_id = 50;

-- 별칭으로 조회
SELECT ID_NUMBER, NAME, ANN_SALARY
FROM   salvu50;
```

### 3-4. 뷰에서 데이터 조회

```sql
SELECT *
FROM   salvu50;
```

뷰는 일반 테이블처럼 SELECT 문에서 사용할 수 있다.

### 3-5. 뷰 수정 (CREATE OR REPLACE)

```sql
-- 기존 EMPVU80 뷰를 수정 (열 별칭 추가)
CREATE OR REPLACE VIEW empvu80
    (id_number, name, sal, department_id)
AS SELECT employee_id,
          first_name || ' ' || last_name,
          salary,
          department_id
   FROM   employees
   WHERE  department_id = 80;
```

- `CREATE OR REPLACE VIEW` — 기존 뷰를 DROP하지 않고 재정의
- 뷰 정의 목록의 별칭 순서는 서브쿼리 열 순서와 동일해야 함
- 기존 뷰에 부여된 권한은 유지됨

---

## 4. 복합 뷰 생성

```sql
-- 부서별 급여 통계 복합 뷰
CREATE OR REPLACE VIEW dept_sum_vu
    (name, minsal, maxsal, avgsal)
AS SELECT   d.department_name,
            MIN(e.salary),
            MAX(e.salary),
            AVG(e.salary)
   FROM     employees   e
   JOIN     departments d USING (department_id)
   GROUP BY d.department_name;
```

복합 뷰는 그룹 함수, JOIN, GROUP BY를 포함할 수 있다.

---

## 5. 뷰 정보 조회 (USER_VIEWS)

```sql
-- 현재 사용자의 뷰 목록
SELECT view_name
FROM   user_views;

-- 특정 뷰의 정의(서브쿼리 텍스트) 조회
SELECT text
FROM   user_views
WHERE  view_name = 'EMP_DETAILS_VIEW';

-- 뷰 구조 확인
DESCRIBE empvu80;
```

`USER_VIEWS` 주요 컬럼:

| 컬럼 | 설명 |
|------|------|
| VIEW_NAME | 뷰 이름 |
| TEXT | 뷰를 정의한 서브쿼리 |
| TEXT_LENGTH | 서브쿼리 텍스트 길이 |
| READ_ONLY | 읽기 전용 여부 (Y/N) |

---

## 6. 뷰를 통한 DML 규칙

### 6-1. DELETE 제한

다음을 포함하는 뷰는 행 삭제 불가:

- 그룹 함수 (MIN, MAX, AVG 등)
- `GROUP BY` 절
- `DISTINCT` 키워드
- `ROWNUM` 의사열

### 6-2. UPDATE 제한

다음을 포함하는 뷰는 데이터 수정 불가:

- 그룹 함수
- `GROUP BY` 절
- `DISTINCT` 키워드
- `ROWNUM` 의사열
- 표현식으로 정의된 열 (예: `salary * 12`)

### 6-3. INSERT 제한

다음을 포함하는 뷰는 행 삽입 불가:

- 그룹 함수
- `GROUP BY` 절
- `DISTINCT` 키워드
- `ROWNUM` 의사열
- 표현식으로 정의된 열
- 기반 테이블의 `NOT NULL` 열이 뷰에 포함되지 않고 기본값도 없는 경우

---

## 7. WITH CHECK OPTION

```sql
CREATE OR REPLACE VIEW empvu20
AS SELECT *
   FROM   employees
   WHERE  department_id = 20
WITH CHECK OPTION CONSTRAINT empvu20_ck;
```

- 뷰의 WHERE 조건을 통해 보이는 행만 INSERT/UPDATE 가능
- `department_id = 20`이 아닌 데이터 삽입/수정 시 `ORA-01402: view WITH CHECK OPTION where-clause violation` 오류
- `CONSTRAINT` 키워드로 제약 조건 이름 지정 가능

---

## 8. WITH READ ONLY

```sql
CREATE OR REPLACE VIEW empvu10
    (employee_number, employee_name, job_title)
AS SELECT employee_id, last_name, job_id
   FROM   employees
   WHERE  department_id = 10
WITH READ ONLY;
```

- 뷰를 통한 모든 DML(INSERT/UPDATE/DELETE) 완전 차단
- DML 시도 시 `ORA-42399: cannot perform a DML operation on a read-only view` 오류
- 데이터 보호가 필요한 보고용 뷰에 적합

---

## 9. 뷰 삭제

```sql
-- 뷰 삭제 (기반 테이블 데이터는 영향 없음)
DROP VIEW empvu80;
```

- 뷰는 데이터를 저장하지 않으므로 DROP해도 기반 테이블 데이터는 유지됨
- 소유자 또는 `DROP ANY VIEW` 권한 필요

---

## 10. 단원 요약

| 주제 | 핵심 내용 |
|------|-----------|
| 뷰 개념 | 테이블의 논리적 표현, 데이터 저장 없음, 딕셔너리에 서브쿼리 정의 |
| 단순 뷰 | 1개 테이블, 함수·그룹 없음, DML 가능 |
| 복합 뷰 | 여러 테이블·함수·그룹 가능, DML 제한적 |
| CREATE VIEW | `CREATE [OR REPLACE] VIEW … AS subquery` |
| 열 별칭 | 서브쿼리 내 별칭 또는 뷰 이름 뒤 별칭 목록 |
| OR REPLACE | 기존 뷰 권한 유지하며 재정의 |
| WITH CHECK OPTION | WHERE 조건 외 DML 방지 |
| WITH READ ONLY | 모든 DML 차단 |
| DROP VIEW | 뷰 삭제, 기반 테이블 무영향 |
| USER_VIEWS | 뷰 정의(TEXT) 및 목록 조회 |
