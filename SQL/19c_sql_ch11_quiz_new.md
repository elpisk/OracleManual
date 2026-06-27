# Oracle Database 19c: SQL Workshop
## Chapter 11 — 데이터 정의 언어(DDL) 소개 | 연습문제 (50문제)

> **구성:** 하(기초) 20문제 + 중(응용) 20문제 + 상(심화) 10문제

---

## 하(기초) — 20문제

---

**[1번]** DDL의 약자와 의미로 올바른 것은?

① DML — 데이터 조작 언어  
② DDL — 데이터 정의 언어  
③ DCL — 데이터 제어 언어  
④ DQL — 데이터 조회 언어

---

**[2번]** 다음 중 데이터베이스 객체가 **아닌** 것은?

① 테이블(Table)  
② 인덱스(Index)  
③ 트랜잭션(Transaction)  
④ 시퀀스(Sequence)

---

**[3번]** 테이블 이름의 명명 규칙으로 **올바른** 것은?

① 숫자로 시작할 수 있다  
② 최대 50자까지 가능하다  
③ 공백 문자를 포함할 수 있다  
④ 문자로 시작하며 1~30자 길이여야 한다

---

**[4번]** `VARCHAR2(50)` 데이터 타입의 특징으로 올바른 것은?

① 항상 50바이트를 사용하는 고정 길이  
② 최대 50바이트의 가변 길이 문자 데이터  
③ 50개의 숫자만 저장 가능  
④ 50행의 데이터를 저장 가능

---

**[5번]** `NUMBER(7, 2)` 데이터 타입으로 저장 가능한 값은?

① 1234567.89  
② 12345.67  
③ 123456789  
④ 12345.678

---

**[6번]** 열에 기본값을 지정하는 Oracle DDL 옵션은?

① `SET DEFAULT`  
② `DEFAULT`  
③ `INITIAL`  
④ `INIT VALUE`

---

**[7번]** 다음 중 NOT NULL 제약 조건에 대한 올바른 설명은?

① 열의 모든 값이 고유해야 함  
② 해당 열에 NULL 값을 허용하지 않음  
③ 다른 테이블의 기본 키를 참조함  
④ 각 행이 만족해야 하는 조건 정의

---

**[8번]** UNIQUE 제약 조건에 대한 올바른 설명은?

① NULL 값을 허용하지 않는다  
② 열의 모든 값이 고유해야 하며 NULL은 허용됨  
③ 테이블당 하나만 존재 가능  
④ 다른 테이블을 참조한다

---

**[9번]** PRIMARY KEY 제약 조건에 대한 올바른 설명은?

① NULL 허용, 중복 허용  
② NULL 불허, 중복 허용  
③ NULL 불허, 중복 불허  
④ NULL 허용, 중복 불허

---

**[10번]** FOREIGN KEY 제약 조건의 역할로 올바른 것은?

① 열의 모든 값이 고유해야 함  
② 참조 무결성 유지 — 자식 테이블의 열이 부모 테이블의 기본 키를 참조  
③ NULL 값 불허  
④ 각 행의 조건 검사

---

**[11번]** CHECK 제약 조건의 특징으로 **올바른** 것은?

① 다른 테이블의 열을 참조할 수 있다  
② 각 행이 만족해야 하는 조건을 정의한다  
③ 테이블당 하나만 정의 가능하다  
④ NULL 값을 자동으로 거부한다

---

**[12번]** ALTER TABLE 문으로 기존 테이블에 새 열을 추가할 때 사용하는 절은?

① MODIFY  
② INSERT  
③ ADD  
④ APPEND

---

**[13번]** ALTER TABLE 문으로 열의 데이터 타입이나 크기를 변경할 때 사용하는 절은?

① ADD  
② MODIFY  
③ CHANGE  
④ UPDATE

---

**[14번]** ALTER TABLE 문으로 열을 삭제할 때 사용하는 절은?

① REMOVE  
② DELETE  
③ DROP  
④ ERASE

---

**[15번]** DROP TABLE 문의 기본 동작으로 올바른 것은?

① 테이블을 즉시 완전 삭제한다  
② 테이블을 휴지통(Recycle Bin)으로 이동한다  
③ 테이블 구조만 삭제하고 데이터는 유지한다  
④ 테이블을 잠금 처리한다

---

**[16번]** 서브쿼리를 사용하여 테이블을 생성하는 구문은?

① `CREATE TABLE t AS SELECT ...`  
② `CREATE TABLE t FROM SELECT ...`  
③ `CREATE TABLE t INSERT SELECT ...`  
④ `CREATE TABLE t COPY SELECT ...`

---

**[17번]** `CHAR(10)` 데이터 타입의 특징으로 올바른 것은?

① 가변 길이로 최대 10바이트  
② 항상 10바이트를 사용하는 고정 길이  
③ 10개의 숫자를 저장  
④ 10행의 데이터를 저장

---

**[18번]** SET UNUSED 옵션의 목적으로 올바른 것은?

① 열을 즉시 삭제한다  
② 열을 미사용으로 표시하여 나중에 삭제한다  
③ 열 데이터를 NULL로 초기화한다  
④ 열을 읽기 전용으로 설정한다

---

**[19번]** 테이블을 읽기 전용으로 설정하는 올바른 구문은?

① `LOCK TABLE employees;`  
② `ALTER TABLE employees READ ONLY;`  
③ `SET TABLE employees READONLY;`  
④ `GRANT READ ONLY ON employees;`

---

**[20번]** 제약 조건을 생성할 때 이름을 지정하지 않으면 Oracle이 자동으로 부여하는 이름 형식은?

① `CON_n`  
② `SYS_Cn`  
③ `ORA_Cn`  
④ `CONS_n`

---

## 중(응용) — 20문제

---

**[21번]** 다음 CREATE TABLE 문에서 오류가 발생하는 이유는?

```sql
CREATE TABLE 123_employee
(id NUMBER, name VARCHAR2(50));
```

① 테이블 이름이 예약어임  
② 테이블 이름이 숫자로 시작함  
③ 열 개수가 부족함  
④ 데이터 타입 오류

---

**[22번]** 다음 중 올바른 CREATE TABLE 구문은?

① `CREATE TABLE emp (id NUMBER, name CHAR DEFAULT 'Unknown');`  
② `CREATE TABLE emp (id NUMBER PRIMARY, name VARCHAR2(50));`  
③ `CREATE TABLE emp (id NUMBER PRIMARY KEY, name VARCHAR2(50) NOT NULL);`  
④ `CREATE TABLE emp (id NUMBER UNIQUE NULL, name VARCHAR2(50));`

---

**[23번]** 다음 ALTER TABLE 문의 결과로 올바른 것은?

```sql
ALTER TABLE dept80
ADD (job_id VARCHAR2(9));
```

① dept80의 첫 번째 열로 job_id 추가  
② dept80의 마지막 열로 job_id 추가  
③ 오류 발생 — 열은 CREATE TABLE에서만 추가 가능  
④ 기존 job_id 열 수정

---

**[24번]** 다음 SQL에서 오류가 발생하는 이유는?

```sql
UPDATE employees
SET    department_id = 55
WHERE  department_id = 110;
```

① department_id 55는 DEPARTMENTS에 존재하지 않아 FK 위반  
② department_id 110이 존재하지 않음  
③ UPDATE 문법 오류  
④ WHERE 절 없이 UPDATE 불가

---

**[25번]** ON DELETE CASCADE 옵션의 동작으로 올바른 것은?

① 부모 행 삭제 시 자식 행의 FK 값을 NULL로 변경  
② 부모 행 삭제 시 자식 행도 자동으로 삭제  
③ 부모 행 삭제를 금지  
④ 자식 행 삭제 시 부모 행도 삭제

---

**[26번]** 다음 중 PRIMARY KEY와 UNIQUE 제약 조건의 차이점으로 올바른 것은?

① UNIQUE는 NULL을 허용하지 않음  
② PRIMARY KEY는 NULL을 허용하고 UNIQUE는 허용하지 않음  
③ PRIMARY KEY는 NULL 불허 + 고유, UNIQUE는 NULL 허용 + 고유  
④ 두 제약 조건은 완전히 동일하다

---

**[27번]** 다음 서브쿼리로 테이블을 생성할 때 복사되는 것은?

```sql
CREATE TABLE dept80
AS SELECT employee_id, last_name FROM employees WHERE department_id = 80;
```

① 테이블 구조(열 정의)만  
② 데이터만  
③ 테이블 구조 + 데이터 + 모든 제약 조건  
④ 테이블 구조 + 데이터 (NOT NULL 제외 제약 조건은 복사 안 됨)

---

**[28번]** 다음 SQL의 목적으로 올바른 것은?

```sql
ALTER TABLE dept80 SET UNUSED (job_id);
```

① job_id 열을 즉시 삭제  
② job_id 열을 미사용으로 표시 (실제 삭제는 나중에)  
③ job_id 열의 값을 NULL로 초기화  
④ job_id 열을 읽기 전용으로 설정

---

**[29번]** 다음 중 CHECK 제약 조건으로 유효한 것은?

① `CHECK (salary > commission)` (다른 열 참조)  
② `CHECK (salary > 0)`  
③ `CHECK (hire_date > SYSDATE)` (의사열 참조)  
④ `CHECK (employee_id IN (SELECT employee_id FROM other_table))` (서브쿼리)

---

**[30번]** ALTER TABLE MODIFY 문의 제한 사항으로 올바른 것은?

① 모든 데이터 타입으로 언제든지 변경 가능  
② 기존 데이터와 호환되어야 하며, 데이터가 있을 때 크기 축소는 제한됨  
③ 열 수정은 비어있는 테이블에서만 가능  
④ MODIFY는 이름 변경에만 사용 가능

---

**[31번]** 다음 구문의 올바른 설명은?

```sql
CONSTRAINT emp_dept_fk FOREIGN KEY (department_id)
    REFERENCES departments(department_id)
    ON DELETE SET NULL
```

① 부모 행 삭제 시 자식 행도 삭제됨  
② 부모 행 삭제 시 자식의 department_id가 NULL로 변경됨  
③ 자식 행이 있으면 부모 행 삭제 불가  
④ NULL 값을 자동으로 기본값으로 변경

---

**[32번]** DROP TABLE 문에 PURGE를 추가하면 어떻게 되는가?

① 테이블이 휴지통으로 이동됨  
② 테이블과 데이터가 즉시 완전히 삭제됨 (복구 불가)  
③ 테이블 구조만 삭제됨  
④ 오류 발생

---

**[33번]** 다음 중 열 수준 제약 조건으로 정의할 수 없는 것은?

① NOT NULL  
② UNIQUE  
③ PRIMARY KEY  
④ 복합 PRIMARY KEY (여러 열 조합)

---

**[34번]** `NUMBER(5)` 열에 저장 가능한 최대 값은?

① 5  
② 99999  
③ 99999.9  
④ 9999999999

---

**[35번]** 다음 DEFAULT 옵션 사용 중 **잘못된** 것은?

① `hire_date DATE DEFAULT SYSDATE`  
② `status VARCHAR2(10) DEFAULT 'Active'`  
③ `dept_id NUMBER DEFAULT department_id` (다른 열 참조)  
④ `count NUMBER DEFAULT 0`

---

**[36번]** 다음 SQL에서 미사용(UNUSED) 열을 실제로 제거하는 방법은?

```sql
ALTER TABLE dept80 SET UNUSED (job_id);
-- 이 후에 실제 삭제하려면?
```

① `ALTER TABLE dept80 DROP (job_id);`  
② `ALTER TABLE dept80 DROP UNUSED COLUMNS;`  
③ `DELETE COLUMN job_id FROM dept80;`  
④ `TRUNCATE COLUMN job_id FROM dept80;`

---

**[37번]** 다음 중 FOREIGN KEY 제약 조건 없이 참조 무결성을 위반하는 경우는?

① 자식 테이블에 NULL 삽입  
② 부모 테이블에 없는 값을 자식 테이블에 삽입  
③ 부모 테이블의 기본 키 값 수정  
④ 자식 테이블에서 행 삭제

---

**[38번]** 다음 구문에서 TIMESTAMP와 DATE의 차이점은?

① TIMESTAMP는 날짜만, DATE는 시간도 포함  
② TIMESTAMP는 소수 초를 포함, DATE는 초 단위까지만  
③ TIMESTAMP는 문자로 저장, DATE는 숫자로 저장  
④ 차이 없음

---

**[39번]** 서브쿼리로 테이블 생성 시 WHERE 절을 `WHERE 1=2`로 하면?

① 오류 발생  
② 모든 데이터 복사  
③ 테이블 구조만 복사되고 데이터는 없음  
④ 첫 번째 행만 복사

---

**[40번]** ALTER TABLE로 열 이름을 변경하는 올바른 구문은?

① `ALTER TABLE t MODIFY old_col TO new_col;`  
② `ALTER TABLE t RENAME COLUMN old_col TO new_col;`  
③ `ALTER TABLE t CHANGE old_col TO new_col;`  
④ `ALTER TABLE t SET old_col = new_col;`

---

## 상(심화) — 10문제

---

**[41번]** 다음 CREATE TABLE 문의 분석으로 올바른 것은?

```sql
CREATE TABLE orders (
    order_id    NUMBER(10)   PRIMARY KEY,
    customer_id NUMBER(10)   NOT NULL,
    order_date  DATE         DEFAULT SYSDATE,
    status      VARCHAR2(20) DEFAULT 'PENDING'
                             CHECK (status IN ('PENDING','SHIPPED','CANCELLED')),
    amount      NUMBER(12,2) CHECK (amount > 0)
);
```

① 오류 — DEFAULT와 CHECK를 함께 사용 불가  
② status 열에 DEFAULT와 CHECK가 모두 적용되는 유효한 구문  
③ CHECK 제약 조건은 테이블 수준에서만 정의 가능  
④ amount 열에는 음수를 저장할 수 있음

---

**[42번]** 다음 두 제약 조건의 차이점으로 올바른 것은?

```sql
-- (A) 열 수준
employee_id NUMBER(6) CONSTRAINT emp_pk PRIMARY KEY

-- (B) 테이블 수준
employee_id NUMBER(6),
...,
CONSTRAINT emp_pk PRIMARY KEY (employee_id)
```

① (A)는 단일 열에만 적용 가능, (B)는 복합 키에도 사용 가능  
② (A)가 항상 더 빠르다  
③ (B)는 이름 지정 불가  
④ 차이 없음

---

**[43번]** 다음 상황에서 오류가 발생하는 이유는?

```sql
DELETE FROM departments
WHERE department_id = 60;
-- ORA-02292 오류 발생
```

① department_id 60이 존재하지 않음  
② 부서 60에 소속된 사원이 EMPLOYEES 테이블에 FK로 참조하고 있어 삭제 불가  
③ DELETE 권한 없음  
④ WHERE 절에 비교 연산자 오류

---

**[44번]** 다음 SQL에서 실제로 어떤 일이 발생하는가?

```sql
CREATE TABLE emp_backup AS
SELECT * FROM employees WHERE 1=2;

INSERT INTO emp_backup SELECT * FROM employees WHERE hire_date < '01-JAN-2000';
```

① 오류 발생 — WHERE 1=2는 유효하지 않음  
② 구조만 있는 빈 테이블 생성 후, 2000년 이전 입사자 데이터 삽입  
③ 모든 직원 데이터로 백업 테이블 생성  
④ hire_date 2000년 이후 사원만 백업

---

**[45번]** 다음 중 ALTER TABLE MODIFY에서 발생할 수 있는 오류 상황은?

① 열 크기를 현재보다 크게 늘리는 경우  
② 데이터가 있는 열의 크기를 현재 데이터보다 작게 줄이는 경우  
③ 기본값(DEFAULT)만 변경하는 경우  
④ 빈 테이블에서 NUMBER를 VARCHAR2로 변경하는 경우

---

**[46번]** ON DELETE CASCADE와 ON DELETE SET NULL을 비교할 때 올바른 것은?

① ON DELETE CASCADE는 부모 행만 삭제하고 자식은 유지  
② ON DELETE SET NULL은 자식 테이블에 NOT NULL 제약이 있으면 오류 발생 가능  
③ ON DELETE CASCADE는 참조 무결성을 위반한다  
④ 두 옵션은 동일한 결과를 낸다

---

**[47번]** 다음 제약 조건 정의의 특이 사항은?

```sql
CREATE TABLE employees (
    employee_id NUMBER(6),
    email       VARCHAR2(25),
    department_id NUMBER(4),
    CONSTRAINT emp_pk   PRIMARY KEY (employee_id),
    CONSTRAINT emp_email_uk UNIQUE (email),
    CONSTRAINT emp_dept_fk  FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON DELETE CASCADE
);
```

① 오류 — 제약 조건은 하나만 정의 가능  
② 복합 제약 조건이 올바르게 테이블 수준에서 정의됨  
③ FOREIGN KEY에 ON DELETE CASCADE가 있으면 UNIQUE 불필요  
④ PRIMARY KEY와 UNIQUE를 같은 열에 정의했으므로 오류

---

**[48번]** SET UNUSED를 사용하는 이유로 가장 적절한 것은?

① SET UNUSED가 DROP COLUMN보다 안전하다  
② 대형 테이블에서 즉시 열 삭제 시 오랜 시간 소요 — UNUSED 표시 후 사용량이 적은 시간대에 DROP  
③ UNUSED 열은 복구할 수 있다  
④ UNUSED 열은 여전히 DML에서 사용 가능하다

---

**[49번]** 다음 SQL의 실행 결과에 대한 분석으로 올바른 것은?

```sql
CREATE TABLE test_tbl AS SELECT employee_id, salary FROM employees;
ALTER TABLE test_tbl ADD (dept_id NUMBER(4));
ALTER TABLE test_tbl MODIFY (salary NUMBER(10,2));
ALTER TABLE test_tbl SET UNUSED (dept_id);
ALTER TABLE test_tbl DROP UNUSED COLUMNS;
DESCRIBE test_tbl;
```

① employee_id, salary, dept_id 세 열이 존재  
② employee_id, salary 두 열만 존재 (dept_id는 SET UNUSED 후 DROP으로 제거됨)  
③ 모든 ALTER TABLE이 실패하여 원래 구조 유지  
④ salary 타입 변경 실패로 오류

---

**[50번]** 다음 상황에서 가장 적절한 제약 조건 조합은?

**요구사항:**
- products 테이블
- product_id: 고유 식별자, NULL 불허
- product_name: 필수 입력, 중복 허용
- price: 0보다 커야 함
- category_id: categories 테이블의 category_id 참조
- sku: 고유해야 하지만 없을 수도 있음 (NULL 허용)

```sql
CREATE TABLE products (
    product_id   NUMBER(10)   __A__,
    product_name VARCHAR2(100) __B__,
    price        NUMBER(10,2) __C__,
    category_id  NUMBER(5)    __D__,
    sku          VARCHAR2(20) __E__
);
```

① A: PRIMARY KEY, B: NOT NULL, C: CHECK(price > 0), D: REFERENCES categories(category_id), E: UNIQUE  
② A: UNIQUE, B: NOT NULL UNIQUE, C: CHECK(price >= 0), D: FOREIGN KEY, E: PRIMARY KEY  
③ A: NOT NULL, B: NOT NULL, C: NOT NULL, D: NOT NULL, E: UNIQUE  
④ A: PRIMARY KEY, B: UNIQUE, C: NOT NULL, D: FOREIGN KEY, E: NOT NULL
