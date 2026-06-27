# Oracle Database 19c: SQL Workshop
## Chapter 15 — 스키마 객체 관리 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | `ALTER TABLE … ADD CONSTRAINT …` |
| 2 | ② | NOT NULL은 `ALTER TABLE … MODIFY 열명 NOT NULL` |
| 3 | ③ | `ALTER TABLE … DROP CONSTRAINT 이름` |
| 4 | ② | ON DELETE CASCADE: 부모 삭제 시 자식 행 자동 삭제 |
| 5 | ② | ON DELETE SET NULL: 부모 삭제 시 자식 FK 열 → NULL |
| 6 | ② | `ALTER TABLE … DISABLE CONSTRAINT …` |
| 7 | ② | `ALTER TABLE … ENABLE CONSTRAINT …` |
| 8 | ② | DROP PRIMARY KEY CASCADE: PK + 참조하는 모든 FK 삭제 |
| 9 | ④ | `RENAME A TO B;`와 `ALTER TABLE A RENAME TO B;` 모두 가능 |
| 10 | ② | `ALTER TABLE t RENAME COLUMN 이름 TO 새이름` |
| 11 | ② | PURGE: 휴지통 없이 즉시 영구 삭제 + 공간 반환 |
| 12 | ③ | GTT: 딕셔너리 저장, 모든 세션에서 정의 조회 가능 |
| 13 | ② | ON COMMIT DELETE ROWS: COMMIT 시 데이터 삭제 |
| 14 | ② | PTT 이름은 반드시 `ORA$PTT_` 접두사 사용 |
| 15 | ③ | 외부 테이블: 파일 시스템 데이터를 Oracle로 조회 |
| 16 | ② | DEFAULT DIRECTORY: Oracle DIRECTORY 객체 이름 |
| 17 | ② | ORACLE_LOADER: 플랫 텍스트 파일(CSV, 고정 길이 등) 처리 |
| 18 | ③ | INITIALLY DEFERRED: 제약 검사가 COMMIT 시까지 지연 |
| 19 | ② | CASCADE CONSTRAINTS: 열 삭제 시 관련 제약 조건 함께 삭제 |
| 20 | ② | `CREATE OR REPLACE DIRECTORY 이름 AS '경로'` |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

`DROP PRIMARY KEY CASCADE`:
- emp2 테이블의 PK 제약 삭제
- emp2의 PK를 참조하는 다른 테이블의 모든 FK 제약도 함께 삭제

```sql
ALTER TABLE emp2 DROP PRIMARY KEY CASCADE;
-- emp2.EMPLOYEE_ID (PK) 삭제
-- + 어떤 테이블이 emp2.EMPLOYEE_ID를 FK로 참조하든 해당 FK도 삭제
```

---

**[22번] 정답: ②**

`ONLINE` 키워드:
- 제약 삭제 작업 중에도 해당 테이블에 대한 **DML(INSERT/UPDATE/DELETE)을 허용**
- 운영 중인 테이블에서 락 없이 제약을 제거할 때 유용
- 없으면 제약 삭제 중 테이블이 잠길 수 있음

---

**[23번] 정답: ②**

`ENABLE NOVALIDATE`:
- **활성화** 상태 → 새로 들어오는 DML에 대해서는 제약 검사
- 기존에 테이블에 있는 데이터는 검사하지 않음
- 대량 데이터 로드(ETL) 후 제약 재활성화 시 유용

```sql
ALTER TABLE dept2 ENABLE NOVALIDATE PRIMARY KEY;
```

---

**[24번] 정답: ②**

```sql
ALTER TABLE emp2
ADD CONSTRAINT emp_mgr_fk
    FOREIGN KEY (manager_id)
    REFERENCES emp2(employee_id);
```

- `CONSTRAINT` 이름 명시
- `FOREIGN KEY(열)` 와 `REFERENCES 테이블(열)` 구조
- 자기 참조(self-referencing) FK: 같은 테이블의 열을 참조

---

**[25번] 정답: ①**

| 옵션 | 데이터 삭제 시점 |
|------|----------------|
| `ON COMMIT DELETE ROWS` | COMMIT 시 |
| `ON COMMIT PRESERVE ROWS` | 세션 종료 시 |

PRESERVE ROWS는 트랜잭션이 끝나도 데이터를 유지하여 같은 세션의 다음 트랜잭션에서도 사용 가능.

---

**[26번] 정답: ②**

`DISABLE VALIDATE`:
- 제약이 **비활성화** → 새 DML에 대한 제약 검사 없음
- **DML도 차단** (INSERT/UPDATE/DELETE 불가)
- 기존 데이터의 무결성은 보장된 것으로 간주
- 주로 파티션 교환(partition exchange) 등 특수 작업에 사용

---

**[27번] 정답: ②**

`DEFERRABLE INITIALLY DEFERRED`:
- 각 INSERT 시에는 PK 중복을 검사하지 않음
- **COMMIT 시점에 PK 중복 검사 실행**
- 두 번째 INSERT(중복 값)는 성공하지만 COMMIT 시 `ORA-00001: unique constraint violated` 오류 발생

---

**[28번] 정답: ②**

PTT `ON COMMIT DROP DEFINITION`:
- **COMMIT 시 데이터뿐 아니라 테이블 정의까지 삭제**
- 트랜잭션이 끝나면 테이블 자체가 사라짐
- 반대: `ON COMMIT PRESERVE DEFINITION` — COMMIT 후에도 정의 유지, 세션 종료 시 삭제

---

**[29번] 정답: ②**

외부 테이블은 **읽기 전용**:
- ✔ `SELECT * FROM external_table;` — 가능
- ✘ INSERT, UPDATE, DELETE — 불가 (ORA-30657)
- ✘ 인덱스 생성 불가

---

**[30번] 정답: ②**

`ORACLE_DATAPUMP`:
- Oracle 전용 이진 형식(Export 파일) 읽기/쓰기
- `AS SELECT …` 구문으로 기존 테이블 데이터를 외부 파일로 내보내기 가능
- PARALLEL 병렬 처리 지원

`ORACLE_LOADER`: 플랫 텍스트 파일 읽기 전용

---

**[31번] 정답: ②**

```sql
ALTER TABLE new_marketing
RENAME CONSTRAINT mktg_pk TO new_mktg_pk;
```

`RENAME CONSTRAINT 기존이름 TO 새이름` 형식.

---

**[32번] 정답: ①**

| 구분 | GTT | PTT |
|------|-----|-----|
| 테이블 정의 저장 | 딕셔너리 (영구) | 메모리 (세션 종료 시 삭제) |
| 정의 가시성 | 모든 세션 | 생성 세션만 |
| 이름 규칙 | 일반 테이블과 동일 | ORA$PTT_ 접두사 필수 |
| COMMIT 옵션 | DELETE ROWS / PRESERVE ROWS | DROP DEFINITION / PRESERVE DEFINITION |

---

**[33번] 정답: ①**

`employee_id`가 PK 또는 UK일 때, 다른 테이블이 이 열을 FK로 참조할 수 있음.  
이런 경우 `CASCADE CONSTRAINTS` 없이 열을 삭제하면 `ORA-12992: cannot drop parent key column` 오류.  
`CASCADE CONSTRAINTS`를 사용하면 참조하는 FK 제약 조건도 함께 삭제됨.

---

**[34번] 정답: ②**

`SET CONSTRAINTS dept2_id_pk IMMEDIATE`:
- `dept2_id_pk` 제약 조건의 검사 시점을 **'각 문장 실행 후 즉시'**로 변경
- 현재 트랜잭션에만 적용 (세션 전체 변경: `ALTER SESSION SET CONSTRAINTS = IMMEDIATE`)
- DEFERRED → IMMEDIATE로 전환하면서 기존 데이터도 즉시 검사

---

**[35번] 정답: ②**

`REJECT LIMIT`:
- 외부 파일 읽기 중 허용되는 **오류(불량) 행의 최대 수**
- `REJECT LIMIT 0`: 첫 오류 발생 시 쿼리 중단
- `REJECT LIMIT UNLIMITED`: 오류 행을 무시하고 계속 진행
- 기본값은 0

---

**[36번] 정답: ②**

`DISABLE PRIMARY KEY CASCADE`:
- 해당 테이블의 PK 비활성화
- 해당 PK를 참조하는 **자식 테이블의 FK도 자동으로 비활성화**
- FK가 활성화된 상태에서 PK만 비활성화하면 무결성 문제가 발생하므로 CASCADE로 연쇄 처리

---

**[37번] 정답: ②**

`ENABLE CONSTRAINT`는 기존 데이터 전체를 검사함.  
위반 데이터가 있으면:
```
ORA-02298: cannot validate - parent keys not found
(또는 ORA-00001: unique constraint violated)
```
오류와 함께 제약 활성화 **실패**.

해결책: `ENABLE NOVALIDATE`로 기존 데이터 제외하고 활성화하거나, 위반 데이터를 먼저 수정.

---

**[38번] 정답: ②**

GTT 데이터는 **세션별로 독립적**:
- 같은 GTT에 접근하는 여러 세션은 각자의 데이터만 볼 수 있음
- 세션 A의 데이터는 세션 B에서 보이지 않음
- 이 특성 덕분에 GTT는 임시 처리 공간으로 안전하게 사용 가능

---

**[39번] 정답: ③**

외부 테이블은 데이터베이스 외부 파일에 저장되므로 **TABLESPACE 지정이 필요 없음**:
- ✔ DIRECTORY 객체 — 파일 경로 참조
- ✔ ORGANIZATION EXTERNAL — 외부 테이블임을 선언
- ✔ LOCATION — 실제 파일명
- ✘ TABLESPACE — 불필요 (내부 저장 없음)

---

**[40번] 정답: ③**

```sql
ON COMMIT DELETE ROWS → COMMIT 시 데이터 삭제
```

INSERT 2건 → COMMIT → 데이터 삭제 → `SELECT COUNT(*)` = **0**

---

## 상(심화) 모범답안

---

**[41번] 정답: ①**

```sql
DEFERRABLE INITIALLY IMMEDIATE
```

- `DEFERRABLE`: 지연 가능하도록 선언
- `INITIALLY IMMEDIATE`: **기본 검사 시점 = 각 문장 실행 직후**

→ 두 번째 INSERT에서 PK 중복 → **즉시 ORA-00001 오류**.

`INITIALLY DEFERRED`였다면 COMMIT 시 오류가 발생할 것.

---

**[42번] 정답: ②**

`ENABLE NOVALIDATE` 활용 시나리오:
- ETL(데이터 웨어하우스 로드) 후 데이터 정제 전 상태에서 새 DML만 검사
- 대량 데이터 로드 중 제약을 DISABLE했다가 재활성화할 때 기존 데이터를 검사하지 않으려면

```sql
ALTER TABLE fact_table ENABLE NOVALIDATE CONSTRAINT fk_dim;
```

---

**[43번] 정답: ②**

GTT 데이터는 **세션 격리**:
- 세션 A가 INSERT + COMMIT해도, 세션 B의 shared_temp는 비어 있음
- `ON COMMIT PRESERVE ROWS`는 같은 세션 내 다음 트랜잭션에서만 데이터 유지
- **세션 간 데이터 공유 불가** → 세션 B 조회: `no rows selected`

---

**[44번] 정답: ②**

`PARALLEL` 키워드:
- `ORACLE_DATAPUMP` 외부 테이블 생성 시 **여러 병렬 프로세스로 데이터를 내보냄**
- `LOCATION ('emp1.exp', 'emp2.exp')` — 여러 파일로 병렬 분산 저장
- 대용량 데이터 내보내기 시 성능 향상

---

**[45번] 정답: ②**

지연 제약이 유용한 전형적인 시나리오:

**순환 참조 또는 부모-자식 동시 처리**:
```sql
-- DEFERRABLE FK가 있는 경우
-- 부모 먼저 삭제, 나중에 자식 삭제 (한 트랜잭션 내)
DELETE FROM departments WHERE department_id = 80;
-- 이 시점에서 즉시 FK 검사 시 오류
-- DEFERRED이면 COMMIT 전까지 유예
DELETE FROM employees WHERE department_id = 80;
COMMIT; -- 이 시점에 제약 검사 → 자식 없으므로 통과
```

---

**[46번] 정답: ②**

`CASCADE CONSTRAINTS` 없이 PK/UK 열 삭제 시:
```
ORA-12992: cannot drop parent key column
```

이유: 해당 열을 FK로 참조하는 다른 테이블/제약이 있으면 Oracle이 참조 무결성 보호를 위해 삭제를 거부.  
`CASCADE CONSTRAINTS` 사용 시 참조하는 FK 제약도 함께 삭제됨.

---

**[47번] 정답: ②**

PTT `ON COMMIT PRESERVE DEFINITION`:
- **COMMIT 후 데이터는 삭제**되지만
- **테이블 정의(구조)는 세션 종료까지 유지**
- 세션 내에서 여러 트랜잭션에 걸쳐 테이블을 재사용 가능
- 세션 종료 시 테이블 정의도 메모리에서 제거

---

**[48번] 정답: ①, ②, ③**

외부 테이블의 주요 제한 사항:
- ✔ ① DML(INSERT/UPDATE/DELETE) 불가 — 읽기 전용
- ✔ ② 인덱스 생성 불가
- ✔ ③ 파티셔닝 불가
- ✘ ④ PARALLEL 조회는 **가능** (외부 테이블은 병렬 쿼리 지원)

---

**[49번] 정답: ②**

3단계 분석:
```sql
-- 2단계에서 department_id = 80 → 999로 변경
-- 하지만 employees.department_id에 80을 참조하는 행이 존재
ALTER TABLE employees ENABLE CONSTRAINT emp_dept_fk;
```

`ENABLE CONSTRAINT`는 기존 데이터 전체를 검사:
- employees 테이블에 `department_id = 80`인 행이 있지만
- departments 테이블에는 `department_id = 80`이 더 이상 없음 (999로 변경됨)
→ **ORA-02298: 고아 키(orphan key) 존재 — 제약 활성화 실패**

---

**[50번] 정답: ①**

분석:
```sql
-- 제약: DEFERRABLE INITIALLY DEFERRED
-- 하지만 SET CONSTRAINTS dept2_pk IMMEDIATE로 즉시 검사로 변경

INSERT INTO dept2 (department_id, ...)
VALUES (10, 'DupTest');
-- department_id = 10이 이미 존재 → IMMEDIATE 상태이므로
-- INSERT 시점에 즉시 PK 중복 검사 → ORA-00001 오류
```

`SET CONSTRAINTS … IMMEDIATE`로 검사 시점이 바뀌었으므로, COMMIT이 아닌 **INSERT 시점에 즉시 오류** 발생.
