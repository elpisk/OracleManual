# Oracle Database 19c: SQL Workshop
## Chapter 17 — 서브쿼리를 이용한 데이터 조작 (Manipulating Data by Using Subqueries)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- 서브쿼리를 대상(target)으로 사용하여 값을 삽입한다
- 서브쿼리로 데이터를 조작한다
- DML 문에서 WITH CHECK OPTION 키워드를 사용한다
- 상관 서브쿼리로 행을 갱신하고 삭제한다

---

## 1. 서브쿼리로 데이터 조작하기 개요

DML(Data Manipulation Language) 문에서 서브쿼리를 사용하면 다음이 가능하다.

| 작업 | 설명 |
|------|------|
| 인라인 뷰로 데이터 조회 | FROM 절에 서브쿼리 → 임시 결과 집합으로 조인 |
| 다른 테이블에 데이터 복사 | `INSERT INTO ... SELECT` |
| 다른 테이블 값 기반 갱신 | 상관 서브쿼리 + `UPDATE SET` |
| 다른 테이블 기반 삭제 | 상관 서브쿼리 + `DELETE FROM` |

---

## 2. 서브쿼리를 대상으로 삽입 (INSERT INTO Subquery)

INSERT 문의 INTO 절에 **서브쿼리**를 사용하면, 특정 조건을 만족하는 뷰 또는 필터된 결과 집합에 행을 삽입할 수 있다.

### 2-1. 기본 구문

```sql
INSERT INTO (
    SELECT column_list
    FROM   table_name
    [WHERE  condition]
    [WITH CHECK OPTION]
)
VALUES (value_list);
```

### 2-2. 예제 — 유럽 지역 위치 삽입

```sql
-- LOCATIONS, COUNTRIES, REGIONS를 조인한 인라인 뷰에 INSERT
INSERT INTO (
    SELECT l.location_id, l.city, l.country_id
    FROM   locations l
    JOIN   countries c ON (l.country_id = c.country_id)
    JOIN   regions USING (region_id)
    WHERE  region_name = 'Europe'
)
VALUES (3300, 'Cardiff', 'UK');
```

- FROM 절 서브쿼리(인라인 뷰)를 INSERT의 대상으로 사용
- UK가 유럽에 포함되므로 삽입 성공

### 2-3. 삽입 결과 확인

```sql
SELECT location_id, city, country_id
FROM   locations
WHERE  location_id = 3300;
```

---

## 3. WITH CHECK OPTION 키워드 (DML에서 사용)

### 3-1. 개념

`WITH CHECK OPTION`은 **서브쿼리의 WHERE 조건을 벗어나는 행**을 삽입·수정하지 못하도록 제한한다.

```sql
INSERT INTO (
    SELECT column_list
    FROM   table_name
    WHERE  condition
    WITH CHECK OPTION    -- 조건 위반 시 ORA-01402 오류
)
VALUES (...);
```

### 3-2. 예제 — 유럽 외 지역 삽입 시도 (오류 발생)

```sql
INSERT INTO (
    SELECT location_id, city, country_id
    FROM   locations
    WHERE  country_id IN (
        SELECT country_id
        FROM   countries
        NATURAL JOIN regions
        WHERE  region_name = 'Europe'
    )
    WITH CHECK OPTION     -- 유럽 국가만 허용
)
VALUES (3600, 'Washington', 'US');
```

**오류 결과:**
```
ORA-01402: view WITH CHECK OPTION where-clause violation
```

- `US`는 유럽 국가가 아니므로 조건을 위반 → 삽입 거부
- `WITH CHECK OPTION` 없이 삽입하면 조건과 무관하게 삽입됨 (데이터 무결성 위협)

### 3-3. WITH CHECK OPTION 적용 범위

| 상황 | WITH CHECK OPTION 없음 | WITH CHECK OPTION 있음 |
|------|------------------------|------------------------|
| 조건 만족 데이터 | 삽입 허용 | 삽입 허용 |
| 조건 미만족 데이터 | 삽입 허용 (무결성 위협) | ORA-01402 오류 |
| 조건 미만족 UPDATE | 갱신 허용 | ORA-01402 오류 |

---

## 4. 상관 UPDATE (Correlated UPDATE)

### 4-1. 개념

다른 테이블의 값을 기반으로 현재 테이블의 행을 갱신할 때 **상관 서브쿼리**를 사용한다.

```sql
UPDATE table1 alias1
SET    column = (
    SELECT expression
    FROM   table2 alias2
    WHERE  alias1.column = alias2.column
);
```

### 4-2. 예제 — 부서명 비정규화(Denormalization)

```sql
-- 1. empl6 테이블에 department_name 열 추가
ALTER TABLE empl6
ADD (department_name VARCHAR2(25));

-- 2. 상관 서브쿼리로 각 직원의 부서명 채우기
UPDATE empl6 e
SET    department_name = (
    SELECT department_name
    FROM   departments d
    WHERE  e.department_id = d.department_id
);
```

- `empl6`의 각 행에 대해 `departments`에서 부서명을 조회하여 갱신
- 부서가 없는 직원(department_id = NULL)은 NULL로 갱신됨

### 4-3. 상관 UPDATE 주의사항

| 항목 | 설명 |
|------|------|
| 스칼라 서브쿼리 필수 | SET 절의 서브쿼리는 반드시 1행 1열 반환 |
| NULL 처리 | 참조 테이블에 값이 없으면 NULL로 갱신 |
| 성능 | 외부 행 수만큼 반복 실행 → 인덱스 권장 |
| 트랜잭션 | UPDATE 후 COMMIT 전 ROLLBACK으로 취소 가능 |

---

## 5. 상관 DELETE (Correlated DELETE)

### 5-1. 개념

다른 테이블에 존재하는 행과 연관된 현재 테이블의 행을 삭제할 때 **상관 서브쿼리**를 사용한다.

```sql
DELETE FROM table1 alias1
WHERE  column operator (
    SELECT expression
    FROM   table2 alias2
    WHERE  alias1.column = alias2.column
);
```

### 5-2. 예제 — emp_history에도 존재하는 직원 삭제

```sql
-- empl6에서 employee_history에도 있는 직원을 삭제
DELETE FROM empl6 e
WHERE  employee_id = (
    SELECT employee_id
    FROM   employee_history
    WHERE  employee_id = e.employee_id
);
```

- `empl6`의 각 행에 대해 `employee_history`에 동일한 `employee_id`가 있으면 삭제
- `=` 대신 `IN` 또는 `EXISTS`로 변경하면 더 안전한 처리 가능

### 5-3. EXISTS 사용 권장 (NULL 안전)

```sql
-- NOT EXISTS를 사용하면 NULL 처리에 안전
DELETE FROM empl6 e
WHERE EXISTS (
    SELECT NULL
    FROM   employee_history eh
    WHERE  eh.employee_id = e.employee_id
);
```

### 5-4. 상관 DELETE 주의사항

| 항목 | 설명 |
|------|------|
| `=` vs `IN` | 서브쿼리가 1건 반환 확신 시 `=`, 복수 가능 시 `IN` 사용 |
| NULL 처리 | NOT IN vs NOT EXISTS → NOT EXISTS 권장 |
| FK 제약 | 자식 행이 있는 부모 행 삭제 시 ORA-02292 오류 |
| 롤백 가능 | COMMIT 전까지 ROLLBACK으로 복구 가능 |

---

## 6. INSERT INTO ... SELECT (다른 테이블에서 데이터 복사)

서브쿼리 결과 전체를 다른 테이블에 삽입한다.

```sql
-- 부서 80번 직원만 별도 테이블로 복사
INSERT INTO sales_employees (employee_id, last_name, salary, department_id)
SELECT employee_id, last_name, salary, department_id
FROM   employees
WHERE  department_id = 80;
```

```sql
-- 테이블 생성 + 데이터 복사 (CTAS)
CREATE TABLE emp_backup AS
SELECT * FROM employees;
```

---

## 7. 서브쿼리를 활용한 DML 종합 비교

| DML 유형 | 서브쿼리 위치 | 용도 |
|----------|--------------|------|
| `INSERT INTO (subquery)` | INTO 절 | 인라인 뷰에 행 삽입 |
| `INSERT INTO ... SELECT` | SELECT 절 | 다른 테이블에서 대량 복사 |
| `UPDATE ... SET (subquery)` | SET 절 | 다른 테이블 기반 갱신 |
| `DELETE WHERE (subquery)` | WHERE 절 | 다른 테이블 기반 삭제 |
| `WITH CHECK OPTION` | INTO 절 서브쿼리 | 조건 위반 DML 차단 |

---

## 8. 단원 요약

| 주제 | 핵심 내용 |
|------|-----------|
| INSERT INTO (subquery) | FROM 절 서브쿼리를 대상으로 값 삽입 |
| WITH CHECK OPTION | 서브쿼리 조건 위반 삽입·수정 차단 (ORA-01402) |
| 상관 UPDATE | 다른 테이블 기반으로 행 갱신, SET 절에 스칼라 서브쿼리 |
| 상관 DELETE | 다른 테이블 기반으로 행 삭제, EXISTS 사용 권장 |
| INSERT ... SELECT | 서브쿼리 결과 전체를 다른 테이블에 삽입 |
