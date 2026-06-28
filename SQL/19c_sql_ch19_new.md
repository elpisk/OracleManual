# Oracle Database 19c: SQL Workshop
## Chapter 19 — 고급 쿼리를 이용한 데이터 조작 (Manipulating Data Using Advanced Queries)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- INSERT와 UPDATE 문에서 명시적 DEFAULT 값을 지정한다
- 다중 테이블 INSERT 문의 기능을 설명한다
- Unconditional / Conditional ALL / Conditional FIRST / Pivoting INSERT를 사용한다
- MERGE 문으로 행을 병합한다
- FLASHBACK TABLE로 테이블을 특정 시점으로 복구한다
- Flashback Query와 Flashback Version Query로 데이터 변경 이력을 추적한다

---

## 1. 명시적 DEFAULT 값 (Explicit Default Values)

`DEFAULT` 키워드를 사용하면 열에 정의된 기본값을 INSERT·UPDATE 시 명시적으로 적용할 수 있다.

### 1-1. INSERT에서 DEFAULT

```sql
INSERT INTO deptm3 (department_id, department_name, manager_id)
VALUES (300, 'Engineering', DEFAULT);
-- manager_id 열의 DEFAULT 값이 삽입됨
```

### 1-2. UPDATE에서 DEFAULT

```sql
UPDATE deptm3
SET    manager_id = DEFAULT
WHERE  department_id = 10;
-- manager_id를 DEFAULT 값으로 재설정
```

- DEFAULT 값이 정의되지 않은 열에 DEFAULT를 사용하면 NULL이 적용된다
- 사용자가 기본값 적용 시점을 직접 제어할 수 있다

---

## 2. 다중 테이블 INSERT (Multitable INSERT Statements)

하나의 DML 문으로 여러 테이블에 행을 삽입한다. 데이터 웨어하우스(ETL) 환경에서 성능이 뛰어나다.

### 2-1. 공통 구문

```sql
INSERT [ ALL | FIRST ]
    [ WHEN condition THEN ]
    INTO target_table [ (column_list) ] [ VALUES (value_list) ]
    ...
    [ ELSE INTO target_table ... ]
SELECT ...
FROM   source_table;
```

### 2-2. Unconditional INSERT ALL

조건 없이 모든 INTO 절에 행을 삽입한다.

```sql
-- employee_id > 200인 직원을 sal_history와 mgr_history에 동시 삽입
INSERT ALL
    INTO sal_history VALUES (empid, hiredate, sal)
    INTO mgr_history VALUES (empid, mgr, sal)
SELECT employee_id empid, hire_date hiredate,
       salary sal, manager_id mgr
FROM   employees
WHERE  employee_id > 200;
```

- 소스의 각 행이 모든 INTO 절에 삽입됨
- 조건 없이 항상 전체 대상에 삽입

### 2-3. Conditional INSERT ALL

WHEN 조건을 평가하여 조건을 만족하는 모든 INTO 절에 삽입 (중복 허용).

```sql
INSERT ALL
    WHEN hiredate < DATE '2015-01-01' THEN
        INTO emp_history VALUES (empid, hiredate, sal)
    WHEN comm IS NOT NULL THEN
        INTO emp_sales VALUES (empid, comm, sal)
SELECT employee_id empid, hire_date hiredate,
       salary sal, commission_pct comm
FROM   employees;
```

- 한 행이 여러 WHEN 조건을 만족하면 **여러 테이블에 모두 삽입** (ALL)
- WHEN 조건이 false인 대상은 건너뜀

### 2-4. Conditional INSERT FIRST

WHEN 조건을 순서대로 평가하여 **첫 번째로 만족하는 INTO 절에만** 삽입한다.

```sql
INSERT FIRST
    WHEN salary < 5000 THEN
        INTO sal_low VALUES (employee_id, last_name, salary)
    WHEN salary BETWEEN 5000 AND 10000 THEN
        INTO sal_mid VALUES (employee_id, last_name, salary)
    ELSE
        INTO sal_high VALUES (employee_id, last_name, salary)
SELECT employee_id, last_name, salary
FROM   employees;
```

- 급여가 2,000이면 sal_low에만 삽입 (sal_mid, sal_high 조건도 무시)
- ELSE 절: 어떤 WHEN 조건도 만족하지 않을 때 삽입

### 2-5. INSERT ALL vs INSERT FIRST 비교

| 항목 | INSERT ALL | INSERT FIRST |
|------|-----------|--------------|
| 조건 평가 | 모든 WHEN 평가 | 첫 번째 만족 후 중단 |
| 중복 삽입 | 여러 테이블에 가능 | 반드시 하나의 테이블에만 |
| 용도 | 동시에 여러 테이블에 복사 | 상호 배타적 분류 |

### 2-6. Pivoting INSERT

비관계형(열 기반) 형태의 데이터를 관계형(행 기반)으로 변환한다.

```
원본 (가로 형태):          변환 후 (세로 형태):
EMP_ID WEEK MON TUE WED   EMP_ID WEEK SALES
176    6    2000 3000 4000  176    6    2000
                            176    6    3000
                            176    6    4000
```

```sql
INSERT ALL
    INTO sales_info VALUES (employee_id, week_id, sales_mon)
    INTO sales_info VALUES (employee_id, week_id, sales_tue)
    INTO sales_info VALUES (employee_id, week_id, sales_wed)
    INTO sales_info VALUES (employee_id, week_id, sales_thur)
    INTO sales_info VALUES (employee_id, week_id, sales_fri)
SELECT employee_id, week_id,
       sales_mon, sales_tue, sales_wed, sales_thur, sales_fri
FROM   sales_source_data;
```

---

## 3. MERGE 문

`MERGE` 문은 단일 DML로 조건에 따라 **UPDATE, INSERT, DELETE**를 수행한다. 행이 존재하면 UPDATE, 없으면 INSERT.

### 3-1. 구문

```sql
MERGE INTO   target_table target_alias
USING        (source_table | view | subquery) source_alias
ON           (join_condition)
WHEN MATCHED THEN
    UPDATE SET col1 = val1, col2 = val2
    [DELETE WHERE condition]
WHEN NOT MATCHED THEN
    INSERT (column_list)
    VALUES (value_list);
```

### 3-2. 예제 — copy_emp3 테이블을 employees와 동기화

```sql
MERGE INTO copy_emp3 c
USING (SELECT * FROM employees) e
ON    (c.employee_id = e.employee_id)
WHEN MATCHED THEN
    UPDATE SET
        c.first_name     = e.first_name,
        c.last_name      = e.last_name,
        c.salary         = e.salary,
        c.department_id  = e.department_id
    DELETE WHERE (e.commission_pct IS NOT NULL)  -- 커미션 있는 직원 삭제
WHEN NOT MATCHED THEN
    INSERT VALUES (e.employee_id, e.first_name, e.last_name,
                  e.email, e.phone_number, e.hire_date, e.job_id,
                  e.salary, e.commission_pct, e.manager_id,
                  e.department_id);
```

### 3-3. MERGE 장점

| 항목 | 설명 |
|------|------|
| 단일 패스 | 소스 데이터를 한 번만 읽어 INSERT/UPDATE 동시 처리 |
| 성능 향상 | 개별 UPDATE/INSERT보다 효율적 |
| 데이터 웨어하우스 | ETL 작업에서 증분 로드 시 활용 |
| DELETE 지원 | WHEN MATCHED THEN UPDATE ... DELETE WHERE로 조건부 삭제 |

---

## 4. FLASHBACK TABLE 문

테이블을 특정 시점 또는 SCN(System Change Number)으로 복구한다.

### 4-1. 특징

- 테이블 데이터와 연관 인덱스·제약 조건 함께 복원
- 인플레이스(in-place) 복원 → IMPORT/EXPORT 불필요
- RECYCLEBIN(휴지통)에서 삭제된 테이블 복원 가능

### 4-2. 구문

```sql
FLASHBACK TABLE [schema.]table_name
TO { SCN expr
   | TIMESTAMP expr
   | RESTORE POINT restore_point_name }
[ { ENABLE | DISABLE } TRIGGERS ];
```

### 4-3. 예제 — 삭제된 테이블 복구

```sql
-- 1. 테이블 삭제 (RECYCLEBIN으로 이동)
DROP TABLE emp3;

-- 2. 휴지통 확인
SELECT original_name, operation, droptime
FROM   recyclebin;

-- 3. 복구
FLASHBACK TABLE emp3 TO BEFORE DROP;
```

### 4-4. 전제 조건

- `ROW MOVEMENT` 활성화 필요 (TIMESTAMP 기반 복구 시):
  ```sql
  ALTER TABLE table_name ENABLE ROW MOVEMENT;
  ```
- UNDO 데이터가 유지되는 시간 내에서만 복구 가능

---

## 5. Flashback Query (AS OF)

과거 특정 시점의 데이터를 조회한다 (DML 실수 확인 등).

```sql
-- 1분 전 급여 조회
SELECT salary
FROM   employees3
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '1' MINUTE)
WHERE  last_name = 'Chung';
```

- UNDO 데이터를 사용하여 과거 데이터 반환
- 테이블 복구 없이 과거 값을 SELECT로 확인

---

## 6. Flashback Version Query (VERSIONS BETWEEN)

특정 행의 변경 이력을 추적한다.

```sql
SELECT versions_starttime "START_DATE",
       versions_endtime   "END_DATE",
       salary
FROM   employees
VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE
WHERE  last_name = 'Lorentz';
```

```sql
-- SCN 범위로 변경 이력 조회
SELECT salary
FROM   employees3
VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE
WHERE  employee_id = 107;
```

- `VERSIONS_STARTTIME` / `VERSIONS_ENDTIME`: 해당 버전의 유효 시간
- `SCN MINVALUE AND MAXVALUE`: 가용한 모든 UNDO 범위
- `TIMESTAMP BETWEEN`: SCN 대신 타임스탬프 범위 사용 가능

---

## 7. 단원 요약

| 주제 | 핵심 내용 |
|------|-----------|
| DEFAULT 키워드 | INSERT/UPDATE에서 열 기본값 명시적 적용 |
| Unconditional INSERT ALL | 조건 없이 모든 INTO 절에 삽입 |
| Conditional INSERT ALL | WHEN 조건 만족하는 모든 절에 삽입 (중복 허용) |
| Conditional INSERT FIRST | 첫 번째 만족 조건의 절에만 삽입 |
| Pivoting INSERT | 열 기반 데이터를 행 기반으로 변환 삽입 |
| MERGE | MATCHED → UPDATE(+DELETE), NOT MATCHED → INSERT |
| FLASHBACK TABLE | 테이블을 시점/SCN/BEFORE DROP으로 복구 |
| Flashback Query | AS OF TIMESTAMP로 과거 시점 데이터 조회 |
| Flashback Version Query | VERSIONS BETWEEN으로 행 변경 이력 추적 |
