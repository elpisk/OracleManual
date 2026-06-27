# Oracle Database 19c: SQL Workshop
## Chapter 13 — 시퀀스, 동의어, 인덱스 생성 | 연습문제 (50문제)

> **구성:** 하(기초) 20문제 + 중(응용) 20문제 + 상(심화) 10문제

---

## 하(기초) — 20문제

---

**[1번]** 시퀀스(Sequence)의 주요 목적으로 올바른 것은?

① 테이블 데이터를 정렬한다  
② 고유한 숫자 값을 자동으로 생성한다  
③ 테이블 검색 속도를 향상시킨다  
④ 객체에 대체 이름을 부여한다

---

**[2번]** CREATE SEQUENCE에서 시작 값을 100으로 설정하는 옵션은?

① `BEGIN WITH 100`  
② `INITIAL VALUE 100`  
③ `START WITH 100`  
④ `FIRST VALUE 100`

---

**[3번]** 시퀀스의 다음 값을 반환하는 의사열(pseudocolumn)은?

① `seq.CURRENT`  
② `seq.NEXTVAL`  
③ `seq.NEXT`  
④ `seq.INCREMENT`

---

**[4번]** `seq.CURRVAL`을 사용하기 전에 반드시 먼저 실행해야 하는 것은?

① `seq.RESET`  
② `seq.MINVAL`  
③ `seq.NEXTVAL`  
④ `SELECT seq FROM dual`

---

**[5번]** 시퀀스에서 `NOCYCLE` 옵션의 의미는?

① 최대값 도달 시 1부터 다시 시작  
② 최대값 도달 시 오류 반환 (더 이상 값 생성 안 함)  
③ 값을 순환하며 무한 반복  
④ 음수 값도 허용

---

**[6번]** 시퀀스에서 `CACHE 20` 옵션의 효과는?

① 20개의 시퀀스만 생성 가능  
② 메모리에 20개의 시퀀스 값을 미리 생성하여 빠른 접근 제공  
③ 20초마다 캐시를 갱신  
④ 20개의 테이블에서 공유 가능

---

**[7번]** 시퀀스 값에 갭(gap)이 발생할 수 있는 상황이 아닌 것은?

① 트랜잭션 롤백 발생  
② 시스템 크래시  
③ `COMMIT` 실행  
④ 같은 시퀀스를 다른 테이블에서 사용

---

**[8번]** 기존 시퀀스의 증가값을 변경하는 구문은?

① `MODIFY SEQUENCE seq INCREMENT BY 5;`  
② `ALTER SEQUENCE seq INCREMENT BY 5;`  
③ `UPDATE SEQUENCE seq SET INCREMENT = 5;`  
④ `CHANGE SEQUENCE seq INCREMENT BY 5;`

---

**[9번]** 시퀀스를 삭제하는 올바른 구문은?

① `DELETE SEQUENCE dept_seq;`  
② `REMOVE SEQUENCE dept_seq;`  
③ `DROP SEQUENCE dept_seq;`  
④ `TRUNCATE SEQUENCE dept_seq;`

---

**[10번]** 시퀀스 정보를 조회하는 딕셔너리 뷰는?

① USER_OBJECTS  
② USER_SEQ_INFO  
③ USER_SEQUENCES  
④ USER_AUTOINCREMENT

---

**[11번]** 동의어(Synonym)의 특징으로 올바른 것은?

① 별도의 저장 공간이 필요하다  
② 데이터 딕셔너리에 정의만 저장된다  
③ 테이블 데이터를 복사한다  
④ 성능을 향상시킨다

---

**[12번]** 개인(private) 동의어를 생성하는 올바른 구문은?

① `CREATE SYNONYM dept FOR departments;`  
② `CREATE PRIVATE SYNONYM dept FOR departments;`  
③ `CREATE ALIAS dept AS departments;`  
④ `RENAME departments TO dept;`

---

**[13번]** 공용(public) 동의어 생성에 필요한 권한은?

① 일반 사용자 권한  
② SELECT ANY TABLE 권한  
③ CREATE PUBLIC SYNONYM 권한 (보통 DBA 보유)  
④ GRANT 권한

---

**[14번]** 동의어를 삭제하는 올바른 구문은?

① `DELETE SYNONYM dept;`  
② `REMOVE SYNONYM dept;`  
③ `DROP SYNONYM dept;`  
④ `ALTER SYNONYM dept REMOVE;`

---

**[15번]** 인덱스(Index)의 주요 역할은?

① 테이블 데이터 백업  
② 데이터 검색 쿼리의 속도 향상  
③ 제약 조건 적용  
④ 데이터 암호화

---

**[16번]** PRIMARY KEY 제약 조건 생성 시 Oracle이 자동으로 하는 것은?

① 뷰를 생성한다  
② UNIQUE 인덱스를 자동으로 생성한다  
③ 시퀀스를 생성한다  
④ 동의어를 생성한다

---

**[17번]** 비고유(non-unique) 인덱스를 생성하는 올바른 구문은?

① `CREATE UNIQUE INDEX idx ON emp(last_name);`  
② `CREATE INDEX idx ON emp(last_name);`  
③ `CREATE NONUNIQUE INDEX idx ON emp(last_name);`  
④ `CREATE INDEX idx NONUNIQUE ON emp(last_name);`

---

**[18번]** 인덱스를 삭제하는 올바른 구문은?

① `DELETE INDEX emp_idx;`  
② `REMOVE INDEX emp_idx;`  
③ `DROP INDEX emp_idx;`  
④ `ALTER TABLE emp DROP INDEX emp_idx;`

---

**[19번]** 인덱스 정보를 조회하는 딕셔너리 뷰는?

① USER_CONSTRAINTS  
② USER_INDEXES  
③ USER_INDEX_DATA  
④ USER_OBJECTS

---

**[20번]** `USER_IND_COLUMNS` 뷰가 제공하는 정보는?

① 인덱스 생성일  
② 인덱스가 적용된 열 이름  
③ 인덱스 크기  
④ 인덱스 소유자

---

## 중(응용) — 20문제

---

**[21번]** 다음 시퀀스 생성문에서 첫 번째 NEXTVAL 값은?

```sql
CREATE SEQUENCE my_seq
    START WITH 100
    INCREMENT BY 5
    MAXVALUE 200
    NOCYCLE;
```

① 5  
② 95  
③ 100  
④ 105

---

**[22번]** 다음 SQL에서 두 번째 INSERT 후 `my_seq.CURRVAL`의 값은?

```sql
INSERT INTO orders VALUES (my_seq.NEXTVAL, 'OrderA');
INSERT INTO orders VALUES (my_seq.NEXTVAL, 'OrderB');
SELECT my_seq.CURRVAL FROM dual;
-- (START WITH 1, INCREMENT BY 1 기준)
```

① 1  
② 2  
③ 3  
④ 0

---

**[23번]** 다음 SQL로 `DEFAULT` 값에 시퀀스를 사용하는 테이블이 올바르게 생성되는가?

```sql
CREATE SEQUENCE emp_seq START WITH 1;
CREATE TABLE emp_new (
    id   NUMBER DEFAULT emp_seq.NEXTVAL NOT NULL,
    name VARCHAR2(50)
);
```

① 오류 — DEFAULT에 시퀀스 사용 불가  
② 올바른 구문 — INSERT 시 id 미지정 시 시퀀스 자동 사용  
③ 오류 — NOT NULL과 DEFAULT 병용 불가  
④ 오류 — START WITH 1은 유효하지 않음

---

**[24번]** 시퀀스를 100번에서 재시작하려면 어떻게 해야 하는가?

① `ALTER SEQUENCE seq START WITH 100;`  
② `UPDATE SEQUENCE seq SET current_value = 100;`  
③ `DROP SEQUENCE seq;` 후 `CREATE SEQUENCE seq START WITH 100;`  
④ `RESET SEQUENCE seq TO 100;`

---

**[25번]** 다음 중 `USER_SEQUENCES` 뷰에서 확인 가능한 정보가 아닌 것은?

① `MIN_VALUE`  
② `MAX_VALUE`  
③ `LAST_NUMBER`  
④ `CURRENT_USER`

---

**[26번]** 다음 동의어 생성 후 올바른 쿼리는?

```sql
CREATE SYNONYM emp FOR hr.employees;
```

① `SELECT * FROM employees;`  
② `SELECT * FROM emp;`  
③ `SELECT * FROM hr.emp;`  
④ `SELECT * FROM synonym.emp;`

---

**[27번]** PUBLIC 동의어와 PRIVATE 동의어의 차이점으로 올바른 것은?

① PRIVATE 동의어는 DBA만 생성 가능  
② PUBLIC 동의어는 모든 데이터베이스 사용자가 접근 가능  
③ PUBLIC 동의어는 하나만 생성 가능  
④ PRIVATE 동의어는 성능이 더 느리다

---

**[28번]** 다음 함수 기반 인덱스가 유용하게 쓰이는 쿼리는?

```sql
CREATE INDEX upper_name_idx ON employees (UPPER(last_name));
```

① `SELECT * FROM employees WHERE last_name = 'King';`  
② `SELECT * FROM employees WHERE UPPER(last_name) = 'KING';`  
③ `SELECT * FROM employees WHERE last_name LIKE 'K%';`  
④ `SELECT * FROM employees ORDER BY last_name;`

---

**[29번]** 다음 중 인덱스 생성이 가장 효과적인 경우는?

① 테이블 행이 100개이고 모든 행을 조회할 때  
② 테이블이 1,000만 건이고 특정 열로 2% 미만의 행을 조회할 때  
③ 테이블 전체를 집계할 때 (COUNT(*))  
④ 열 값이 거의 동일할 때 (예: 성별 열)

---

**[30번]** 다음 SQL에서 인덱스가 자동으로 생성되는 경우는?

```sql
CREATE TABLE test_tbl (
    id   NUMBER PRIMARY KEY,
    code VARCHAR2(10) UNIQUE,
    name VARCHAR2(50)
);
```

① id 열에만 인덱스 자동 생성  
② code 열에만 인덱스 자동 생성  
③ id, code 두 열 모두에 인덱스 자동 생성  
④ 인덱스는 자동으로 생성되지 않음

---

**[31번]** 다음 CREATE TABLE 구문에서 `USING INDEX` 절의 역할은?

```sql
CREATE TABLE new_emp (
    employee_id NUMBER(6)
        PRIMARY KEY USING INDEX
        (CREATE INDEX emp_id_idx ON new_emp(employee_id)),
    last_name VARCHAR2(25)
);
```

① PRIMARY KEY를 생성하지 않음  
② Oracle이 자동 생성하는 인덱스 이름을 직접 지정  
③ 인덱스 없이 기본 키만 생성  
④ 오류 발생

---

**[32번]** 다음 중 `USER_INDEXES` 뷰에서 확인 가능한 정보는?

① 인덱스가 걸린 열 이름  
② 인덱스 이름, 테이블 이름, UNIQUE 여부  
③ 인덱스 생성에 걸린 시간  
④ 인덱스를 사용한 쿼리 목록

---

**[33번]** 다음 SQL에서 오류가 발생하는 이유는?

```sql
CREATE SEQUENCE test_seq
    START WITH 100
    INCREMENT BY 10
    MAXVALUE 50;
```

① INCREMENT BY가 너무 크다  
② START WITH 값이 MAXVALUE보다 크다  
③ NOCYCLE을 명시해야 한다  
④ 이름에 '_'가 포함될 수 없다

---

**[34번]** 다음 쿼리에서 인덱스가 사용되지 않을 가능성이 높은 경우는?

```sql
CREATE INDEX emp_salary_idx ON employees(salary);
-- 다음 쿼리 중 인덱스를 타지 않는 것은?
```

① `WHERE salary > 10000`  
② `WHERE salary BETWEEN 5000 AND 10000`  
③ `WHERE TO_CHAR(salary) = '5000'`  
④ `WHERE salary = 5000`

---

**[35번]** 동의어가 참조하는 테이블이 삭제되면 어떻게 되는가?

① 동의어도 자동으로 삭제된다  
② 동의어는 그대로 남아 있지만 사용 시 오류 발생  
③ 동의어가 NULL로 변경된다  
④ 자동으로 다른 테이블을 참조한다

---

**[36번]** `ALTER SEQUENCE`로 변경할 수 없는 것은?

① INCREMENT BY  
② MAXVALUE  
③ CACHE  
④ START WITH (현재 값 재설정)

---

**[37번]** 다음 중 복합 인덱스(composite index)를 생성하는 올바른 구문은?

① `CREATE INDEX idx ON emp(last_name, first_name);`  
② `CREATE INDEX idx ON emp(last_name); CREATE INDEX idx ON emp(first_name);`  
③ `CREATE COMPOSITE INDEX idx ON emp(last_name, first_name);`  
④ `CREATE MULTI INDEX idx ON emp(last_name + first_name);`

---

**[38번]** `USER_SYNONYMS` 뷰에서 확인 가능한 정보로 올바른 것은?

① 동의어 이름, 참조하는 테이블/스키마 이름  
② 동의어가 사용된 쿼리 목록  
③ 동의어 생성일  
④ 동의어에 연결된 사용자 목록

---

**[39번]** 다음 SQL에서 `INVISIBLE` 옵션의 목적은?

```sql
ALTER INDEX emp_id_name_ix1 INVISIBLE;
```

① 인덱스를 완전히 삭제  
② 인덱스를 비활성화 — 옵티마이저가 사용하지 않지만 구조는 유지  
③ 인덱스를 숨겨 다른 사용자가 볼 수 없게 함  
④ 인덱스를 읽기 전용으로 변경

---

**[40번]** 시퀀스의 `ORDER` 옵션이 필요한 환경은?

① 단일 인스턴스 Oracle 환경  
② RAC(Real Application Clusters) 등 다중 인스턴스 환경에서 순서 보장 필요 시  
③ 음수 시퀀스 값이 필요할 때  
④ CYCLE 옵션과 함께 사용할 때

---

## 상(심화) — 10문제

---

**[41번]** 다음 시퀀스를 사용하여 세 번 NEXTVAL을 호출한 후 ROLLBACK했을 때 시퀀스 상태는?

```sql
CREATE SEQUENCE s START WITH 1 INCREMENT BY 1 NOCACHE;
-- 세션 A:
SELECT s.NEXTVAL FROM dual;  -- 1
SELECT s.NEXTVAL FROM dual;  -- 2
SELECT s.NEXTVAL FROM dual;  -- 3
ROLLBACK;
-- 이후 NEXTVAL 값은?
```

① 1 (ROLLBACK으로 복원됨)  
② 4 (ROLLBACK이 시퀀스에 영향 없음)  
③ 0 (초기화됨)  
④ 3 (마지막 값 유지)

---

**[42번]** 다음 상황에서 올바른 설명은?

```sql
CREATE SEQUENCE seq1 START WITH 1 INCREMENT BY 1 CACHE 20;
-- 시스템 크래시 발생 (캐시에 5~20이 남아있던 상황)
-- 재시작 후 NEXTVAL 값은?
```

① 크래시 전 마지막 값(5)의 다음인 6부터 시작  
② 21부터 시작 (캐시 블록의 다음부터)  
③ 1부터 다시 시작  
④ 20부터 시작

---

**[43번]** 다음 시나리오에서 가장 적절한 인덱스 전략은?

**상황:** `orders` 테이블 (1억 건), `WHERE status = 'PENDING'` 쿼리가 빈번하며, 전체 행의 약 0.5%가 'PENDING'이다.

① 인덱스 필요 없음 — 0.5%라도 풀 스캔이 빠름  
② `status` 열에 B-TREE 인덱스 생성  
③ `status` 열에 BITMAP 인덱스 생성 (카디널리티가 낮으므로)  
④ 함수 기반 인덱스 생성

---

**[44번]** 다음 SQL에서 동의어를 통한 DML 수행 가능 여부는?

```sql
CREATE SYNONYM my_emp FOR employees;

-- 다음 DML 중 가능한 것은?
UPDATE my_emp SET salary = 9999 WHERE employee_id = 100;
```

① 불가능 — 동의어를 통한 DML은 금지  
② 가능 — 동의어는 원본 테이블에 대한 모든 DML 허용  
③ 가능하지만 읽기 전용 모드만 허용  
④ 가능하지만 INSERT만 허용

---

**[45번]** 다음 복합 인덱스에서 어떤 WHERE 절이 인덱스를 가장 잘 활용하는가?

```sql
CREATE INDEX emp_composite_idx ON employees(department_id, job_id, salary);
```

① `WHERE salary > 5000`  
② `WHERE job_id = 'SA_REP'`  
③ `WHERE department_id = 80 AND job_id = 'SA_REP'`  
④ `WHERE salary BETWEEN 3000 AND 6000 AND job_id = 'IT_PROG'`

---

**[46번]** 다음 SQL에서 기존 인덱스를 재사용하는 올바른 방법은?

```sql
-- 시나리오: emp_id_name_ix1이 INVISIBLE 상태
-- emp_id_name_ix2(BITMAP)가 활성 상태

-- ix1을 다시 옵티마이저가 사용하게 하려면?
```

① `ALTER INDEX emp_id_name_ix1 ENABLE;`  
② `ALTER INDEX emp_id_name_ix1 VISIBLE;`  
③ `DROP INDEX emp_id_name_ix2; CREATE INDEX ...;`  
④ `SET OPTIMIZER_USE_INVISIBLE_INDEXES = TRUE;`

---

**[47번]** 다음 상황에서 가장 적절한 시퀀스 설계는?

**요구사항:**
- 주문 번호: 10000001부터 시작
- 1씩 증가
- 절대 중복 없어야 함
- 시스템 재시작 후에도 갭이 없어야 함 (감사 요건)

① `CREATE SEQUENCE ord_seq START WITH 10000001 INCREMENT BY 1 CACHE 20;`  
② `CREATE SEQUENCE ord_seq START WITH 10000001 INCREMENT BY 1 NOCACHE;`  
③ `CREATE SEQUENCE ord_seq START WITH 10000001 INCREMENT BY 1 CYCLE;`  
④ `CREATE SEQUENCE ord_seq START WITH 1 INCREMENT BY 1 MAXVALUE 10000001;`

---

**[48번]** 다음 SQL의 실행 결과를 분석하시오.

```sql
CREATE SEQUENCE s1 START WITH 1 INCREMENT BY 1;

CREATE TABLE t (
    id   NUMBER DEFAULT s1.NEXTVAL,
    val  VARCHAR2(10)
);

INSERT INTO t (val) VALUES ('A');
INSERT INTO t (id, val) VALUES (999, 'B');
INSERT INTO t (val) VALUES ('C');
SELECT * FROM t ORDER BY id;
```

① 1, 999, 2 순서로 id 값이 나옴  
② 1, 999, 3 순서로 id 값이 나옴 (2번째 INSERT에서 NEXTVAL 미호출)  
③ 오류 발생 — id=999가 시퀀스 범위 초과  
④ 1, 2, 3 순서로 id 값이 나옴

---

**[49번]** PUBLIC 동의어를 사용해야 하는 가장 적절한 상황은?

① 개인 스키마에서 테이블 이름을 단축할 때  
② 여러 개발팀이 DBA 스키마의 공용 테이블에 접근할 때 스키마명 없이 참조  
③ 뷰 대신 동의어로 데이터 필터링  
④ 외래 키 참조를 단순화할 때

---

**[50번]** 다음 인덱스 관련 SQL에 대한 분석으로 올바른 것은?

```sql
CREATE TABLE orders (
    order_id    NUMBER PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    status      VARCHAR2(20),
    order_date  DATE
);

-- 추가 인덱스
CREATE INDEX ord_cust_idx ON orders(customer_id);
CREATE INDEX ord_date_idx ON orders(order_date);
CREATE INDEX ord_status_date_idx ON orders(status, order_date);

-- 쿼리 패턴:
-- Q1: WHERE order_id = 123
-- Q2: WHERE customer_id = 456
-- Q3: WHERE status = 'PENDING' AND order_date >= SYSDATE - 7
-- Q4: WHERE order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
```

① Q1은 인덱스 없이 풀 스캔한다  
② Q3은 ord_status_date_idx를 활용할 가능성이 높다  
③ Q4는 ord_status_date_idx를 활용할 수 없다  
④ Q2는 인덱스가 없어 항상 풀 스캔한다
