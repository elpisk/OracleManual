# Oracle Database 19c: SQL Workshop
## Chapter 13 — 시퀀스, 동의어, 인덱스 생성 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | 시퀀스 = 고유한 숫자 값을 자동 생성 |
| 2 | ③ | `START WITH n` — 시작 값 지정 |
| 3 | ② | `seq.NEXTVAL` — 다음 시퀀스 값 반환 |
| 4 | ③ | CURRVAL은 NEXTVAL 호출 이후에만 사용 가능 |
| 5 | ② | NOCYCLE: 최대값 도달 시 오류, 더 이상 값 생성 안 함 |
| 6 | ② | CACHE n: n개의 값을 메모리에 미리 생성하여 빠른 접근 |
| 7 | ③ | COMMIT은 시퀀스 갭과 무관 — 갭은 ROLLBACK/크래시/다중 테이블 사용 시 발생 |
| 8 | ② | `ALTER SEQUENCE seq INCREMENT BY 5;` |
| 9 | ③ | `DROP SEQUENCE seq;` |
| 10 | ③ | USER_SEQUENCES — 시퀀스 정의 조회 |
| 11 | ② | 동의어는 데이터 딕셔너리에 정의만 저장, 별도 스토리지 없음 |
| 12 | ① | `CREATE SYNONYM dept FOR departments;` |
| 13 | ③ | CREATE PUBLIC SYNONYM 권한 (보통 DBA 보유) |
| 14 | ③ | `DROP SYNONYM dept;` |
| 15 | ② | 인덱스 = 데이터 검색 속도 향상 |
| 16 | ② | PK/UK 제약 시 Oracle이 자동으로 UNIQUE 인덱스 생성 |
| 17 | ② | `CREATE INDEX idx ON emp(last_name);` (UNIQUE 없으면 비고유 인덱스) |
| 18 | ③ | `DROP INDEX emp_idx;` |
| 19 | ② | USER_INDEXES — 인덱스 기본 정보 |
| 20 | ② | USER_IND_COLUMNS — 인덱스가 적용된 열 이름 제공 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ③**

`START WITH 100`으로 설정했으므로 첫 번째 `NEXTVAL`은 **100**.  
두 번째는 105, 세 번째는 110 순으로 증가.

---

**[22번] 정답: ②**

`START WITH 1, INCREMENT BY 1` 기준:
- 1번째 INSERT: `NEXTVAL` = 1
- 2번째 INSERT: `NEXTVAL` = 2
- `CURRVAL` = **2** (마지막으로 반환된 NEXTVAL 값)

---

**[23번] 정답: ②**

Oracle 12c 이후 `DEFAULT` 절에 시퀀스의 `NEXTVAL` 사용 가능.  
INSERT 시 `id`를 생략하면 `emp_seq.NEXTVAL`이 자동으로 사용된다.

```sql
INSERT INTO emp_new (name) VALUES ('Alice');  -- id=1 자동 할당
INSERT INTO emp_new (name) VALUES ('Bob');    -- id=2 자동 할당
```

---

**[24번] 정답: ③**

`ALTER SEQUENCE`로는 `START WITH`를 변경할 수 없다.  
시작 값을 변경하려면 **시퀀스를 DROP 후 재생성**해야 한다.

```sql
DROP SEQUENCE seq;
CREATE SEQUENCE seq START WITH 100 INCREMENT BY 1;
```

---

**[25번] 정답: ④**

`USER_SEQUENCES` 주요 컬럼: `SEQUENCE_NAME`, `MIN_VALUE`, `MAX_VALUE`, `INCREMENT_BY`, `CYCLE_FLAG`, `ORDER_FLAG`, `CACHE_SIZE`, `LAST_NUMBER`.  
`CURRENT_USER`는 `USER_SEQUENCES`의 컬럼이 아니다.

---

**[26번] 정답: ②**

동의어 `emp`는 `hr.employees` 테이블의 별칭이므로 `SELECT * FROM emp;`로 접근한다.  
`hr.emp`는 `hr` 스키마의 `emp` 테이블을 의미 (동의어 아님).

---

**[27번] 정답: ②**

| | PRIVATE | PUBLIC |
|---|---|---|
| 접근 범위 | 생성한 사용자만 | 모든 DB 사용자 |
| 생성 권한 | CREATE SYNONYM | CREATE PUBLIC SYNONYM |
| 용도 | 개인 스키마 내 단축 | 공용 테이블 공유 |

---

**[28번] 정답: ②**

`UPPER(last_name)` 함수 기반 인덱스는 `WHERE UPPER(last_name) = 'KING'` 쿼리에서만 활용된다.  
`WHERE last_name = 'King'`은 함수를 사용하지 않으므로 해당 인덱스 대신 다른 인덱스나 풀 스캔을 수행한다.

---

**[29번] 정답: ②**

인덱스 효과: 대용량 테이블에서 **소량(2~4% 미만)의 행**을 조회할 때 가장 효과적.  
- 소규모 테이블: 풀 스캔이 더 빠름
- 대부분의 행 조회: 풀 스캔이 효율적
- 카디널리티가 낮은 열(성별 등): 효과 적음

---

**[30번] 정답: ③**

```sql
CREATE TABLE test_tbl (
    id   NUMBER PRIMARY KEY,  -- PRIMARY KEY → UNIQUE 인덱스 자동 생성
    code VARCHAR2(10) UNIQUE, -- UNIQUE → UNIQUE 인덱스 자동 생성
    name VARCHAR2(50)
);
```

`id`와 `code` **두 열 모두**에 자동으로 UNIQUE 인덱스 생성.

---

**[31번] 정답: ②**

`PRIMARY KEY USING INDEX (CREATE INDEX ...)` 구문으로 Oracle이 자동 생성하는 인덱스 이름을 사용자가 직접 지정할 수 있다.  
기본적으로 Oracle은 `SYS_C0000n` 형식의 이름을 부여하는데, 이를 의미 있는 이름으로 변경할 수 있다.

---

**[32번] 정답: ②**

`USER_INDEXES`: 인덱스 이름(`INDEX_NAME`), 테이블 이름(`TABLE_NAME`), 고유 여부(`UNIQUENESS`) 등 제공.  
인덱스가 걸린 열 이름은 `USER_IND_COLUMNS`에서 확인.

---

**[33번] 정답: ②**

`START WITH 100`이 `MAXVALUE 50`보다 크므로 오류 발생.  
`ORA-04006: START WITH value cannot be made to exceed MAXVALUE`

---

**[34번] 정답: ③**

`WHERE TO_CHAR(salary) = '5000'`은 `salary` 열에 함수를 적용했으므로 일반 인덱스를 사용할 수 없다 (함수 기반 인덱스가 있어야 가능).  
나머지는 모두 `salary` 열 직접 비교이므로 인덱스 활용 가능.

---

**[35번] 정답: ②**

동의어가 참조하는 기본 객체(테이블 등)가 삭제되어도 **동의어 자체는 삭제되지 않는다**.  
이후 동의어를 사용하면 `ORA-04043: object does not exist` 오류가 발생한다.

---

**[36번] 정답: ④**

`ALTER SEQUENCE`로 변경 가능: `INCREMENT BY`, `MAXVALUE`, `MINVALUE`, `CYCLE`, `CACHE`.  
**`START WITH` (현재 값 재설정)는 불가** — DROP 후 재생성 필요.

---

**[37번] 정답: ①**

```sql
CREATE INDEX idx ON emp(last_name, first_name);
```

쉼표로 여러 열을 나열하면 복합 인덱스가 생성된다.  
`COMPOSITE` 키워드는 존재하지 않는다.

---

**[38번] 정답: ①**

`USER_SYNONYMS` 주요 컬럼:
- `SYNONYM_NAME`: 동의어 이름
- `TABLE_OWNER`: 참조하는 객체의 소유자
- `TABLE_NAME`: 참조하는 객체 이름
- `DB_LINK`: 데이터베이스 링크 (원격 객체 시)

---

**[39번] 정답: ②**

`INVISIBLE` 인덱스: 옵티마이저가 사용하지 않지만 인덱스 구조 자체는 유지·갱신된다.  
다른 타입의 인덱스를 생성하기 전에 기존 인덱스를 INVISIBLE로 전환하는 데 사용한다.  
다시 활성화하려면 `ALTER INDEX idx VISIBLE;`.

---

**[40번] 정답: ②**

`ORDER` 옵션은 **RAC(Real Application Clusters)** 환경에서 여러 인스턴스가 동일 시퀀스를 사용할 때 순서를 보장하기 위해 사용한다.  
단일 인스턴스에서는 `ORDER`/`NOORDER` 차이 없음.

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

시퀀스는 **롤백에 영향을 받지 않는다**. ROLLBACK이 발생해도 시퀀스 카운터는 되돌아가지 않는다.  
→ 세 번 NEXTVAL 호출 후 ROLLBACK → 다음 NEXTVAL = **4**

이것이 시퀀스에서 갭이 발생하는 주요 원인 중 하나다.

---

**[42번] 정답: ②**

`CACHE 20` 시퀀스는 1~20을 메모리에 미리 생성한다.  
5개 사용 중 크래시 → 캐시의 나머지 6~20은 영구적으로 소실.  
재시작 후 Oracle은 캐시의 다음 블록(21~40)부터 시작 → **21부터 시작**.

이것이 캐시 사용 시 크래시 후 갭이 발생하는 이유다.

---

**[43번] 정답: ③**

- `status` 열: 카디널리티가 낮음 (PENDING, SHIPPED, CANCELLED 등 소수 값)
- 전체의 0.5% → 소량 → 인덱스가 효과적
- 카디널리티가 낮은 열 + 대용량 테이블 = **BITMAP 인덱스** 적합

B-TREE 인덱스는 카디널리티가 높은 열(고유 값이 많은 열)에 적합하다.

---

**[44번] 정답: ②**

동의어는 단순히 원본 테이블에 대한 **대체 이름**이므로, 원본 테이블에 대한 모든 DML(INSERT/UPDATE/DELETE) 이 동의어를 통해 가능하다.

```sql
UPDATE my_emp SET salary = 9999 WHERE employee_id = 100;
-- employees 테이블에 직접 UPDATE하는 것과 동일
```

단, `WITH READ ONLY` 뷰의 동의어는 DML 불가.

---

**[45번] 정답: ③**

복합 인덱스 `(department_id, job_id, salary)`:
- 인덱스는 **선두 열(leading column)부터** 매칭해야 효과적
- ①: salary만 — 선두 열 없음 → 인덱스 미활용
- ②: job_id만 — 첫 번째 열(department_id) 없음 → 미활용
- ③: `department_id = 80 AND job_id = 'SA_REP'` — 선두 두 열 일치 → **최적 활용**
- ④: salary + job_id — 첫 번째 열 없음 → 미활용

---

**[46번] 정답: ②**

INVISIBLE 상태의 인덱스를 옵티마이저가 다시 사용하게 하려면:

```sql
ALTER INDEX emp_id_name_ix1 VISIBLE;
```

`ENABLE`은 인덱스 명령어가 아니다 (제약 조건 명령어).

---

**[47번] 정답: ②**

감사 요건 "갭 없음" = 시스템 크래시 후에도 번호가 연속되어야 함.  
→ **NOCACHE 필수** (CACHE 사용 시 크래시 후 갭 발생 가능)

```sql
CREATE SEQUENCE ord_seq
    START WITH 10000001
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
```

- `CYCLE`: 최대값 도달 시 재시작 → 중복 발생 가능 → 부적합
- `CACHE 20`: 크래시 시 갭 발생 → 부적합

---

**[48번] 정답: ②**

```sql
INSERT INTO t (val) VALUES ('A');         -- id = NEXTVAL = 1
INSERT INTO t (id, val) VALUES (999, 'B'); -- id = 명시적 999, NEXTVAL 미호출
INSERT INTO t (val) VALUES ('C');         -- id = NEXTVAL = 2 (여전히 1다음)
```

두 번째 INSERT에서 `DEFAULT(NEXTVAL)` 대신 `999`를 명시적으로 지정했으므로 시퀀스가 호출되지 않았다.  
결과: id 값 = **1, 999, 2** (ORDER BY id 시: 1, 2, 999)

---

**[49번] 정답: ②**

PUBLIC 동의어의 주요 사용 사례:
- DBA 또는 공용 스키마의 테이블/패키지를 여러 사용자가 **스키마명 없이** 접근할 때
- 예: `hr.employees` → `CREATE PUBLIC SYNONYM employees FOR hr.employees;`
  → 모든 사용자가 `SELECT * FROM employees;`로 접근 가능

개인 스키마 내 단축은 PRIVATE 동의어로 충분하다.

---

**[50번] 정답: ②와 ③ 중 ②가 올바른 설명**

분석:
- **Q1** (`WHERE order_id = 123`): PRIMARY KEY → 자동 생성 인덱스 활용 ✔
- **Q2** (`WHERE customer_id = 456`): `ord_cust_idx` 활용 가능 ✔
- **Q3** (`WHERE status = 'PENDING' AND order_date >= SYSDATE-7`): `ord_status_date_idx(status, order_date)` 선두 열 일치 → **활용 가능** ✔
- **Q4** (`WHERE order_date BETWEEN ...`): `ord_date_idx` 또는 `ord_status_date_idx`에서 date 단독 사용 가능 (status가 없으므로 ord_status_date_idx의 선두열 누락 → ord_date_idx 활용)

**정답: ②** — Q3은 `ord_status_date_idx`를 활용할 가능성이 높다.
