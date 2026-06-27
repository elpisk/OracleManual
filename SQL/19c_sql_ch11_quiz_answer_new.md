# Oracle Database 19c: SQL Workshop
## Chapter 11 — 데이터 정의 언어(DDL) 소개 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | DDL = Data Definition Language (데이터 정의 언어) |
| 2 | ③ | 트랜잭션은 DML의 개념, 객체가 아님 |
| 3 | ④ | 문자로 시작, 1~30자, A-Z/0-9/_/$/#만 허용 |
| 4 | ② | VARCHAR2(50): 최대 50바이트 가변 길이 문자 |
| 5 | ② | NUMBER(7,2): 전체 7자리, 소수점 이하 2자리 → 최대 99999.99 |
| 6 | ② | `DEFAULT expr` 형태로 열 기본값 지정 |
| 7 | ② | NOT NULL = NULL 값 불허 |
| 8 | ② | UNIQUE: 고유값 보장, NULL은 허용 |
| 9 | ③ | PRIMARY KEY = NOT NULL + UNIQUE 조합 |
| 10 | ② | FOREIGN KEY: 자식 테이블이 부모 테이블 기본 키 참조 |
| 11 | ② | CHECK: 각 행이 만족해야 하는 논리 조건 정의 |
| 12 | ③ | `ALTER TABLE t ADD (col type)` |
| 13 | ② | `ALTER TABLE t MODIFY (col new_type)` |
| 14 | ③ | `ALTER TABLE t DROP (col)` |
| 15 | ② | DROP TABLE은 기본적으로 Recycle Bin으로 이동 |
| 16 | ① | `CREATE TABLE t AS SELECT ...` |
| 17 | ② | CHAR(10): 항상 10바이트 고정 길이 |
| 18 | ② | SET UNUSED: 열을 미사용으로 표시, 실제 삭제는 나중에 |
| 19 | ② | `ALTER TABLE t READ ONLY;` |
| 20 | ② | Oracle 자동 생성 이름: `SYS_Cn` 형식 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

테이블 이름 `123_employee`는 숫자(`1`)로 시작하므로 명명 규칙 위반.  
테이블 이름은 반드시 **문자**로 시작해야 한다.

---

**[22번] 정답: ③**

```sql
CREATE TABLE emp (id NUMBER PRIMARY KEY, name VARCHAR2(50) NOT NULL);
```

- ①: `CHAR`에 크기 없음 → 기본 1바이트 (문법상 허용되나 부적절)
- ②: `PRIMARY` → `PRIMARY KEY`가 올바른 키워드
- ③: 올바른 구문
- ④: `UNIQUE NULL` 조합 — UNIQUE는 NULL 허용이 기본이므로 `NULL` 키워드 불필요 (오류는 아니나 모순적)

---

**[23번] 정답: ②**

`ALTER TABLE dept80 ADD (job_id VARCHAR2(9))` 실행 시, 새로 추가되는 열은 항상 **테이블의 마지막 열**이 된다.

---

**[24번] 정답: ①**

```sql
UPDATE employees SET department_id = 55 WHERE department_id = 110;
```

DEPARTMENTS 테이블에 department_id=55가 존재하지 않으므로 FOREIGN KEY 무결성 위반.  
`ORA-02291: integrity constraint violated - parent key not found`

---

**[25번] 정답: ②**

`ON DELETE CASCADE`: 부모 행이 삭제될 때 해당 부모를 참조하는 자식 행들도 **자동으로 삭제**된다.

---

**[26번] 정답: ③**

| | PRIMARY KEY | UNIQUE |
|---|---|---|
| NULL 허용 | 불허 | 허용 |
| 중복 허용 | 불허 | 불허 |
| 테이블당 개수 | 1개 | 여러 개 가능 |

---

**[27번] 정답: ④**

`CREATE TABLE ... AS SELECT` 구문으로 생성 시:
- 복사됨: 테이블 구조 + 데이터 + **NOT NULL 제약 조건**
- **복사 안 됨**: PRIMARY KEY, UNIQUE, FOREIGN KEY, CHECK 제약 조건

---

**[28번] 정답: ②**

`SET UNUSED`는 열을 **미사용 표시**만 하고 즉시 삭제하지는 않는다.  
실제 삭제는 `ALTER TABLE t DROP UNUSED COLUMNS;`로 별도 실행.

---

**[29번] 정답: ②**

```sql
CHECK (salary > 0)
```

CHECK 제약 조건의 제한:
- ①: 다른 열 참조 불가 (같은 행의 다른 열과 비교는 같은 테이블 내에서 가능하지만, 일반적으로 salary > commission 같은 비교는 허용됨 — 실제로는 허용되는 케이스도 있음)
- ③: `SYSDATE` 의사열 참조 불가
- ④: 서브쿼리 불가
- ②: 단순 상수 비교 — 항상 유효

---

**[30번] 정답: ②**

ALTER TABLE MODIFY 규칙:
- 열 크기 **늘리기**: 항상 가능
- 열 크기 **줄이기**: 기존 데이터가 없거나, 모든 데이터가 새 크기에 맞을 때만 가능
- 데이터가 있을 때 `VARCHAR2(100)` → `VARCHAR2(10)` 등은 오류 발생

---

**[31번] 정답: ②**

`ON DELETE SET NULL`: 부모 테이블의 행이 삭제되면 자식 테이블의 외래 키 열 값을 **NULL로 변경**.

---

**[32번] 정답: ②**

```sql
DROP TABLE dept80 PURGE;
```

`PURGE` 절: 테이블을 Recycle Bin으로 이동하지 않고 즉시 완전히 삭제 → **복구 불가**.

---

**[33번] 정답: ④**

복합 PRIMARY KEY (여러 열 조합)는 **테이블 수준(Table Level)**에서만 정의 가능하다:

```sql
CONSTRAINT emp_pk PRIMARY KEY (emp_id, dept_id)  -- 테이블 수준
```

열 수준으로는 하나의 열에만 PRIMARY KEY를 붙일 수 있다.

---

**[34번] 정답: ②**

`NUMBER(5)`: 정수 5자리 → 최대값 **99999** (5자리 최대 수).

---

**[35번] 정답: ③**

```sql
dept_id NUMBER DEFAULT department_id  -- 오류! 다른 열 참조 불가
```

DEFAULT 값으로 **다른 열 이름**이나 **의사열(pseudocolumn)**은 사용 불가.  
리터럴, 표현식, SQL 함수(SYSDATE 등)는 허용.

---

**[36번] 정답: ②**

```sql
ALTER TABLE dept80 DROP UNUSED COLUMNS;
```

`SET UNUSED`로 표시된 열들을 실제로 제거하는 명령어.

---

**[37번] 정답: ②**

FOREIGN KEY 참조 무결성: 자식 테이블에 **부모 테이블에 없는 값** 삽입 시 위반.  
`ORA-02291: integrity constraint violated - parent key not found`

---

**[38번] 정답: ②**

| DATE | 날짜 + 시(시분초)까지 저장 |
|---|---|
| TIMESTAMP | 날짜 + 시분초 + **소수 초(fractional seconds)** 저장 |

TIMESTAMP는 DATE보다 더 정밀한 시간 정보를 저장한다.

---

**[39번] 정답: ③**

`WHERE 1=2`: 항상 거짓 → 행이 하나도 선택되지 않음.  
결과: **테이블 구조(열 정의)만 복사**되고 데이터는 없는 빈 테이블 생성.  
(백업 테이블 구조만 만들 때 자주 사용하는 패턴)

---

**[40번] 정답: ②**

```sql
ALTER TABLE t RENAME COLUMN old_col TO new_col;
```

Oracle에서 열 이름을 변경하는 올바른 구문.

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

```sql
status VARCHAR2(20) DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING','SHIPPED','CANCELLED'))
```

열 수준에서 DEFAULT와 CHECK를 동시에 정의하는 것은 **완전히 유효**한 Oracle 구문.  
INSERT 시 status 미지정 → 'PENDING', 잘못된 값 입력 시 CHECK 위반.

---

**[42번] 정답: ①**

- **열 수준(A)**: 해당 열에 바로 정의 → 단일 열만 가능
- **테이블 수준(B)**: 열 목록 아래 별도로 정의 → **복합 기본 키**(여러 열 조합)도 가능

```sql
CONSTRAINT pk PRIMARY KEY (col1, col2)  -- 복합 키 → 반드시 테이블 수준
```

---

**[43번] 정답: ②**

```
ORA-02292: integrity constraint violated - child record found
```

DEPARTMENTS의 department_id=60을 참조하는 EMPLOYEES 행이 존재하므로 삭제 불가.  
해결 방법:
1. EMPLOYEES에서 해당 부서 사원을 먼저 삭제/이동
2. FK에 `ON DELETE CASCADE` 정의 (부모 삭제 시 자식도 자동 삭제)
3. FK에 `ON DELETE SET NULL` 정의 (부모 삭제 시 자식 FK를 NULL로)

---

**[44번] 정답: ②**

```sql
CREATE TABLE emp_backup AS SELECT * FROM employees WHERE 1=2;
-- → 구조만 있는 빈 테이블 생성 (NOT NULL 제외 제약 조건은 복사 안 됨)

INSERT INTO emp_backup SELECT * FROM employees WHERE hire_date < '01-JAN-2000';
-- → 2000년 이전 입사자 데이터를 빈 테이블에 삽입
```

두 SQL의 조합: **선택적 데이터 백업 패턴** (구조 생성 후 원하는 데이터만 삽입).

---

**[45번] 정답: ②**

MODIFY 제한:
- ① 크기 늘리기: 항상 허용 ✅
- ② **데이터 있는 열 크기 축소**: 데이터가 새 크기를 초과하면 `ORA-01441: cannot decrease column length` 오류 ❌
- ③ DEFAULT만 변경: 허용 ✅
- ④ 빈 테이블에서 타입 변경: 허용 ✅

---

**[46번] 정답: ②**

ON DELETE SET NULL과 NOT NULL 충돌:

```sql
CREATE TABLE employees (
    department_id NUMBER(4) NOT NULL,  -- NOT NULL 제약 있음
    CONSTRAINT fk FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON DELETE SET NULL  -- 부모 삭제 시 NULL로 바꾸려 함
);
```

위 상황에서 부모 행 삭제 시 NULL로 바꾸려 하지만 NOT NULL 제약 때문에  
`ORA-01407: cannot update to NULL` 오류 발생 → 설계 오류.

---

**[47번] 정답: ②**

여러 제약 조건을 테이블 수준에서 정의한 유효한 구문:
- `emp_pk`: PRIMARY KEY
- `emp_email_uk`: UNIQUE
- `emp_dept_fk`: FOREIGN KEY ON DELETE CASCADE

복합적인 테이블 수준 제약 조건 정의 — 완전히 올바른 DDL 패턴.

---

**[48번] 정답: ②**

SET UNUSED의 실용적 이유:  
대형 테이블(수억 건)에서 `ALTER TABLE DROP COLUMN`은 데이터 재구성으로 **장시간 소요** + 테이블 잠금.  
→ `SET UNUSED`로 먼저 숨기고, 업무 시간 외에 `DROP UNUSED COLUMNS` 실행.  

참고: UNUSED로 표시된 열은 SELECT, DML에서 접근 불가 (숨겨진 상태).

---

**[49번] 정답: ②**

```sql
CREATE TABLE test_tbl AS SELECT employee_id, salary FROM employees;
-- → employee_id, salary 두 열

ALTER TABLE test_tbl ADD (dept_id NUMBER(4));
-- → employee_id, salary, dept_id 세 열

ALTER TABLE test_tbl MODIFY (salary NUMBER(10,2));
-- → salary 타입 변경 (NUMBER → NUMBER(10,2)) 성공

ALTER TABLE test_tbl SET UNUSED (dept_id);
-- → dept_id 미사용 표시

ALTER TABLE test_tbl DROP UNUSED COLUMNS;
-- → dept_id 실제 삭제

DESCRIBE test_tbl;
-- → employee_id, salary 두 열만 존재
```

---

**[50번] 정답: ①**

```sql
CREATE TABLE products (
    product_id   NUMBER(10)    PRIMARY KEY,         -- A: 고유 + NOT NULL
    product_name VARCHAR2(100) NOT NULL,            -- B: 필수 (중복 허용 → UNIQUE 불필요)
    price        NUMBER(10,2)  CHECK(price > 0),    -- C: 0보다 커야 함
    category_id  NUMBER(5)     REFERENCES categories(category_id), -- D: FK
    sku          VARCHAR2(20)  UNIQUE                -- E: 고유, NULL 허용
);
```

요구사항 분석:
- `product_id`: 고유 식별자 + NULL 불허 → **PRIMARY KEY**
- `product_name`: 필수(NOT NULL), 중복 허용 → **NOT NULL**
- `price`: 0보다 커야 함 → **CHECK(price > 0)**
- `category_id`: 다른 테이블 참조 → **REFERENCES** (FK 단축 구문)
- `sku`: 고유하지만 NULL 허용 → **UNIQUE** (UNIQUE는 NULL 허용)
