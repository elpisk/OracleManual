# Oracle Database 19c: SQL Workshop
## Chapter 19 — 고급 쿼리를 이용한 데이터 조작 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ③ | `DEFAULT` 키워드: 열에 정의된 기본값을 명시적으로 삽입 |
| 2 | ② | `salary = DEFAULT` → 열의 DEFAULT 값으로 재설정 |
| 3 | ③ | `INSERT ALL`: 조건 없이 모든 INTO 절에 삽입 |
| 4 | ④ | 다중 테이블 INSERT에는 JOIN 절 없음 |
| 5 | ③ | Conditional INSERT ALL: 조건을 만족하는 모든 테이블에 삽입 (중복 허용) |
| 6 | ② | INSERT FIRST: 첫 번째 조건 만족 시 해당 테이블에 삽입 후 중단 |
| 7 | ③ | Pivoting INSERT: 열 기반(비정규화) → 행 기반(정규화) 변환 삽입 |
| 8 | ④ | MERGE는 `USING ... ON (조건)` 구조를 사용 |
| 9 | ② | `WHEN NOT MATCHED THEN INSERT`: 소스에 있고 대상에 없는 행 삽입 |
| 10 | ③ | `WHEN MATCHED THEN UPDATE`: 대상에 이미 존재하는 행 갱신 |
| 11 | ② | FLASHBACK TABLE: 테이블 데이터를 과거 시점으로 복구 |
| 12 | ② | `FLASHBACK TABLE emp TO BEFORE DROP` |
| 13 | ③ | `AS OF TIMESTAMP`: Flashback Query 구문 |
| 14 | ② | `SYSTIMESTAMP - INTERVAL '1' MINUTE` = 현재에서 1분 전 |
| 15 | ② | `VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE` |
| 16 | ② | UNDO에서 가용한 가장 오래된 SCN부터 최신 SCN까지 |
| 17 | ② | `ALTER TABLE ... ENABLE ROW MOVEMENT` |
| 18 | ④ | `WHEN MATCHED THEN UPDATE SET ... DELETE WHERE ...` |
| 19 | ② | ELSE 절: 어떤 WHEN 조건도 만족하지 않을 때 실행 |
| 20 | ③ | `ORIGINAL_NAME` 열: 원래 테이블 이름 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ③**

```sql
INSERT INTO dept2 (dept_name) VALUES ('Accounting');
```

dept_id는 지정하지 않았으므로 열의 DEFAULT 값인 100이 자동 적용된다.

---

**[22번] 정답: ②**

Unconditional INSERT ALL은 소스의 각 행을 모든 INTO 절에 삽입한다.
- 소스 행 5개 × sal_history INTO 1개 = 5행 삽입
- sal_history 기준으로만 답하면 **5행**

---

**[23번] 정답: ③**

`INSERT FIRST`는 WHEN 조건을 위에서부터 순서대로 평가하여 **첫 번째 만족 조건의 테이블에만 삽입하고 나머지 평가는 중단**한다.
한 행이 여러 조건을 만족해도 오직 하나의 테이블에만 삽입된다.

---

**[24번] 정답: ③**

Conditional INSERT ALL:
- salary < 5000 조건 만족 → low_sal에 삽입
- commission_pct IS NOT NULL 조건도 만족 → comm_emp에도 삽입
- 두 조건 모두 만족하므로 **두 테이블 모두에 삽입**

---

**[25번] 정답: ②**

INSERT FIRST:
- salary < 5000 조건 **먼저** 만족 → low_sal에 삽입하고 중단
- commission_pct IS NOT NULL 조건은 평가하지 않음
- **low_sal에만 삽입**

---

**[26번] 정답: ③**

Pivoting INSERT는 소스의 각 행을 INTO 절 수만큼 삽입한다.
- 소스 2행 × INTO 5개(mon, tue, wed, thur, fri) = **10행**

---

**[27번] 정답: ②**

MERGE의 `ON` 절은 소스 행과 대상 행을 연결하는 **조인 조건**을 지정한다.
- ON 조건 만족 → WHEN MATCHED (UPDATE/DELETE)
- ON 조건 불만족 → WHEN NOT MATCHED (INSERT)

---

**[28번] 정답: ②**

employee_id = 100이 copy_emp에 이미 존재(MATCHED) → `UPDATE SET c.salary = e.salary` 실행.
새 행은 삽입되지 않는다.

---

**[29번] 정답: ②**

```sql
WHEN MATCHED THEN
    UPDATE SET ...
    DELETE WHERE condition   ← 여기서 지정하는 별도 조건
```

UPDATE된 행 중 DELETE WHERE 조건을 만족하는 행을 삭제한다.

---

**[30번] 정답: ②**

```sql
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '30' MINUTE)
```

현재 타임스탬프에서 30분을 뺀 시점의 데이터, 즉 **30분 전의 salary 조회**.

---

**[31번] 정답: ②**

TIMESTAMP 기반 FLASHBACK TABLE 복구 전 필수:
```sql
ALTER TABLE table_name ENABLE ROW MOVEMENT;
```
Oracle은 타임스탬프에서 SCN으로 변환할 때 행 위치 변경이 발생할 수 있어 ROW MOVEMENT가 필요하다.

---

**[32번] 정답: ②**

Flashback Version Query의 주요 의사 컬럼:
- `VERSIONS_STARTTIME`: 해당 버전이 시작된 시각
- `VERSIONS_ENDTIME`: 해당 버전이 끝난 시각 (NULL이면 현재 버전)

---

**[33번] 정답: ③**

삭제된 테이블 정보 조회:
```sql
SELECT original_name, operation, droptime FROM recyclebin;
-- 또는
SELECT * FROM user_recyclebin;
```

---

**[34번] 정답: ③**

MERGE는 DML 문이므로 **ROLLBACK이 가능**하다.
DDL이 아니므로 AUTO COMMIT되지 않는다.

---

**[35번] 정답: ③**

salary = 24000:
- `salary < 10000` → 불만족
- `salary < 15000` → 불만족
- ELSE → **high_sal에 삽입**

---

**[36번] 정답: ②**

Oracle MERGE 문에서 `WHEN NOT MATCHED THEN INSERT ... WHERE condition`은 **삽입 필터**를 추가할 수 있다.
소스 행 중 조건을 만족하는 행만 대상에 삽입된다.

---

**[37번] 정답: ②**

Flashback 기능은 **UNDO TABLESPACE**에 저장된 이전 이미지(Before Image) 데이터를 활용한다.
UNDO_RETENTION 설정에 따라 보존 기간이 결정된다.

---

**[38번] 정답: ②**

`VERSIONS BETWEEN TIMESTAMP t1 AND t2`는 t1부터 t2 사이에 **존재했던 모든 버전의 행**을 반환한다.
삭제된 행도 포함된다.

---

**[39번] 정답: ③**

열에 DEFAULT 값이 정의되지 않은 경우 `DEFAULT` 키워드는 **NULL**로 처리된다.
NOT NULL 제약이 있으면 오류가 발생하지만, 그렇지 않으면 NULL이 삽입된다.

---

**[40번] 정답: ②**

소스 3행 × INTO 절 2개(두 테이블) = **6행 총 삽입**.
Unconditional INSERT ALL은 소스 행마다 모든 INTO 절을 실행한다.

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

MERGE 실행 흐름 분석:
```
dept_id = 10: MATCHED → UPDATE budget = 1000 → DELETE WHERE budget > 900 (1000 > 900) → 삭제
dept_id = 20: copy_dept에만 존재, departments에 없음 → ON 불만족 → 아무 작업 없음 (NOT MATCHED는 소스 기준)
dept_id = 30: NOT MATCHED → INSERT (budget=1500)
```

- dept_id = 10: 업데이트 후 조건(1000 > 900) 만족하여 삭제
- dept_id = 20: MERGE의 소스(departments)에 없으므로 MATCHED/NOT MATCHED 모두 해당 없음 → 그대로 유지
- dept_id = 30: NOT MATCHED → 삽입

최종: **20 (기존 유지), 30 (새 삽입)** → ② 정답

---

**[42번] 정답: ②**

- `WHEN NOT MATCHED THEN INSERT ... WHERE s.status = 'ACTIVE'`: 상태가 ACTIVE인 행만 삽입 → 지원됨
- `WHEN MATCHED THEN ... DELETE WHERE s.status = 'INACTIVE'`: UPDATE 후 INACTIVE인 행 삭제

결과: ACTIVE인 새 행만 삽입되고, MATCHED된 행 중 s.status = 'INACTIVE'인 것은 업데이트 후 삭제됨 → **② 정답**

---

**[43번] 정답: ③**

Flashback Version Query는 **UNDO TABLESPACE에 남아있는 데이터만** 조회 가능.
SCN 1000 이전의 UNDO가 삭제되었으므로:
- salary = 5000 (SCN 1000 이전 초기값): 조회 **불가**
- salary = 6000 (SCN 2000): 조회 가능
- salary = 7000 (SCN 3000, 현재): 조회 가능

---

**[44번] 정답: ②**

`PURGE RECYCLEBIN`은 RECYCLEBIN에 있는 모든 객체를 **영구 삭제**한다.
FLASHBACK TABLE ... TO BEFORE DROP은 RECYCLEBIN의 데이터를 사용하므로, PURGE 후에는 복구 불가.

---

**[45번] 정답: ③**

Pivoting INSERT는 NULL 값도 그대로 삽입한다.
NULL 값 행을 제외하려면 다음처럼 WHEN 조건을 추가할 수 있다:

```sql
INSERT ALL
    WHEN sales_mon IS NOT NULL THEN
        INTO sales_info VALUES (emp_id, week_id, sales_mon)
    WHEN sales_tue IS NOT NULL THEN
        INTO sales_info VALUES (emp_id, week_id, sales_tue)
    ...
SELECT emp_id, week_id, sales_mon, sales_tue ...
FROM sales_source;
```

---

**[46번] 정답: ①**

INSERT FIRST는 상호 배타적 조건을 순서대로 평가하여 각 직원을 **하나의 테이블에만** 삽입한다.
- high_sal: 8명 (salary > 10000)
- mid_sal: 40명 (5000 ≤ salary ≤ 10000)
- low_sal: 59명 (나머지)
- 합계: 8 + 40 + 59 = **107행** (전체 직원 수와 동일, 중복 없음)

---

**[47번] 정답: ①**

MERGE 문에서 `ON` 절에 사용된 조인 컬럼(c.employee_id)은 `UPDATE SET`에서 수정할 수 없다.
이를 시도하면:
```
ORA-38104: Columns referenced in the ON Clause cannot be updated: "C"."EMPLOYEE_ID"
```

ON 절 컬럼을 업데이트 대상으로 지정하는 것은 무결성 위반이므로 Oracle이 금지한다.

---

**[48번] 정답: ②**

| 기능 | 범위 | 의존 저장소 | 복구 단위 |
|------|------|------------|-----------|
| FLASHBACK TABLE | 테이블 단위 | UNDO TABLESPACE | 테이블 |
| Flashback Database | 데이터베이스 전체 | FLASHBACK LOGS | 데이터베이스 |

Flashback Database는 데이터베이스 전체를 특정 시점으로 복구하며, `ALTER DATABASE FLASHBACK ON` 설정과 FLASHBACK LOGS 보관이 필요하다.

---

**[49번] 정답: ②**

각 직원의 hire_date는 하나이므로 세 가지 날짜 범위 조건이 **상호 배타적**(overlap 없음).
`INSERT FIRST`를 사용하면:
- 첫 번째 만족 조건에만 삽입하고 나머지 조건은 평가하지 않음
- 불필요한 조건 평가 없이 정확한 분류 가능
- `INSERT ALL`을 사용해도 조건이 배타적이므로 결과는 동일하지만, **의미적으로 FIRST가 올바른 선택**이다

---

**[50번] 정답: ②**

MERGE 문은 **DML 트랜잭션**에 속하므로 ROLLBACK으로 전체를 취소할 수 있다.
ROLLBACK 실행 시:
- WHEN MATCHED THEN UPDATE로 변경된 salary → 원래 값으로 복구
- WHEN NOT MATCHED THEN INSERT로 삽입된 행 → 삭제

INSERT와 UPDATE가 같은 트랜잭션 내에 있으므로 **ROLLBACK은 MERGE 전체에 적용**된다.
