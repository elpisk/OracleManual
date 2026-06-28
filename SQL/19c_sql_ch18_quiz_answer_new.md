# Oracle Database 19c: SQL Workshop
## Chapter 18 — 사용자 접근 제어 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | 시스템 권한(System Privileges) / 객체 권한(Object Privileges) |
| 2 | ② | 시스템 권한: 데이터베이스 내 특정 작업 수행 권한 (200개 이상) |
| 3 | ③ | CREATE SESSION: 데이터베이스 접속 권한 |
| 4 | ② | `CREATE USER ... IDENTIFIED BY` 구문 |
| 5 | ③ | SELECT는 객체 권한 (특정 테이블에 대한 권한) |
| 6 | ② | `GRANT privilege TO user` 구문 |
| 7 | ② | 롤: 이름을 붙인 관련 권한의 집합 |
| 8 | ② | `CREATE ROLE role_name` 구문 |
| 9 | ③ | `ALTER USER ... IDENTIFIED BY` 구문 |
| 10 | ② | SELECT, INSERT, UPDATE, DELETE = 객체 권한 |
| 11 | ③ | INDEX 권한: 테이블에만 부여 가능, 뷰에 불가 |
| 12 | ② | `GRANT privilege ON object TO user` 구문 |
| 13 | ② | WITH GRANT OPTION: 받은 권한을 다른 사용자에게 재부여 가능 |
| 14 | ③ | PUBLIC: 모든 사용자에게 권한 부여 |
| 15 | ② | `REVOKE privilege ON object FROM user` 구문 |
| 16 | ② | USER_TAB_PRIVS_RECD: 사용자가 **받은** 객체 권한 |
| 17 | ② | `GRANT update (column_name) ON table TO user` — 괄호 안에 열 지정 |
| 18 | ③ | Oracle 시스템 권한은 200개 이상 |
| 19 | ② | USER_ROLE_PRIVS: 현재 사용자에게 부여된 롤 목록 |
| 20 | ① | 시퀀스: SELECT(CURRVAL/NEXTVAL), ALTER 권한 부여 가능 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ①**

```sql
GRANT create session, create table, create sequence, create view TO demo;
```

쉼표로 구분하여 여러 시스템 권한을 한 번에 부여 가능.  
`demo`는 이제 접속, 테이블/시퀀스/뷰 생성 권한을 갖게 됨.

---

**[22번] 정답: ②**

```sql
CREATE ROLE dev_role;
GRANT create table, create view TO dev_role;
GRANT dev_role TO user1, user2, ..., user10;
```

롤을 사용하면 10번의 개별 GRANT 대신 롤 1개로 관리.  
이후 권한 변경 시 dev_role만 수정하면 모든 멤버에게 자동 적용.

---

**[23번] 정답: ②**

연쇄 회수(Cascade Revoke):
```
hr → demo (WITH GRANT OPTION) → alice
hr REVOKE FROM demo → demo 권한 회수 + alice 권한도 자동 회수
```

`WITH GRANT OPTION`으로 부여된 권한은 원본 권한자가 REVOKE 시 연쇄 회수됨.

---

**[24번] 정답: ②**

```sql
GRANT update (salary, commission_pct) ON employees TO demo;
```

demo는 employees 테이블의 **salary와 commission_pct 열만** UPDATE 가능.  
다른 열(last_name 등) UPDATE 시도 시 권한 오류 발생.

---

**[25번] 정답: ③**

`WITH GRANT OPTION`은 **사용자에게** 직접 부여할 때만 사용 가능.  
롤에 권한을 부여할 때는 WITH GRANT OPTION을 지정할 수 없음.

---

**[26번] 정답: ①**

```
CREATE ROLE app_user; → 롤 생성
GRANT select ON employees TO app_user; → 롤에 권한 추가
GRANT select ON departments TO app_user; → 롤에 권한 추가
GRANT app_user TO demo, alice, bob; → 세 사용자에게 롤 부여
```

결과: demo, alice, bob 모두 employees와 departments SELECT 권한 획득.

---

**[27번] 정답: ②**

- `USER_SYS_PRIVS` → 사용자에게 부여된 **시스템 권한** (①은 틀림)
- `ROLE_TAB_PRIVS` → **롤에 부여된 테이블 권한** ← ② 정답
- `USER_TAB_PRIVS_MADE` → 사용자가 **부여한** 객체 권한 (③은 틀림)
- `USER_COL_PRIVS_RECD` → 사용자가 받은 **열 수준** 권한 (④는 설명 틀림)

---

**[28번] 정답: ②**

```sql
GRANT update (department_name) ON departments TO demo;
```

열 수준 권한으로 `department_name` 열만 UPDATE 허용. 나머지 열은 수정 불가.

---

**[29번] 정답: ③**

```sql
GRANT select ON employees TO PUBLIC;
```

`PUBLIC`은 데이터베이스의 **현재 및 미래 모든 사용자**를 의미.  
이 실행 후 누구나 employees를 조회 가능하므로 주의 필요.

---

**[30번] 정답: ②**

```sql
REVOKE select, insert ON departments FROM demo;
```

demo의 departments에 대한 **SELECT와 INSERT만** 회수.  
다른 테이블이나 다른 권한은 영향 없음.

---

**[31번] 정답: ②**

`REFERENCES` 권한: 다른 사용자의 테이블을 **외래 키(FK)의 참조 대상**으로 사용하는 권한.  
예: demo가 hr.employees를 FK로 참조하는 테이블 생성 시 필요.

---

**[32번] 정답: ②**

| 구분 | 시스템 권한 | 객체 권한 |
|------|------------|-----------|
| ON 절 | 없음 | 있음 (`ON table`) |
| 대상 | 데이터베이스 작업 | 특정 객체 |
| 예 | CREATE TABLE | SELECT ON employees |

---

**[33번] 정답: ②**

롤의 최대 장점: **여러 사용자에게 권한 집합을 일괄 관리**.  
권한 변경 시 롤만 수정하면 모든 멤버에게 즉시 반영 → 관리 복잡성 감소.

---

**[34번] 정답: ③**

`CREATE USER` 구문을 실행하려면 `CREATE USER` **시스템 권한**이 필요.  
일반적으로 DBA 역할(SYSDBA, DBA 롤 보유자)만 실행 가능.

---

**[35번] 정답: ②**

- `USER_COL_PRIVS_MADE`: 내가 **부여한** 열 수준 권한
- `USER_COL_PRIVS_RECD`: 내가 **받은** 열 수준 권한

---

**[36번] 정답: ①**

```
CREATE ROLE analyst → 롤 생성
GRANT select, insert ON employees TO analyst → 롤에 권한 부여
GRANT analyst TO alice → alice에 롤 부여
```

alice는 analyst 롤을 통해 employees에 대한 **SELECT와 INSERT** 권한 획득.

---

**[37번] 정답: ②**

연쇄 회수 체인:
```
HR → demo (WITH GRANT OPTION) → bob
HR REVOKE FROM demo → demo 회수 + bob도 연쇄 회수
```

`WITH GRANT OPTION`으로 받은 권한이 회수되면 연쇄적으로 하위 사용자 권한도 모두 회수.

---

**[38번] 정답: ②**

```sql
GRANT ALL ON employees TO demo;
```

employees 테이블에 적용 가능한 **모든 객체 권한** (ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE) 부여.  
시스템 권한과는 무관.

---

**[39번] 정답: ②**

Oracle 스키마: 특정 사용자가 소유한 **데이터베이스 객체의 집합** (테이블, 뷰, 시퀀스 등).  
사용자명과 스키마명은 동일 (HR 사용자 = HR 스키마).

---

**[40번] 정답: ②**

`CASCADE CONSTRAINTS`: `REFERENCES` 권한 회수 시 해당 권한으로 생성된 **외래 키(FK) 제약을 함께 삭제**.  
FK가 남아있으면 REFERENCES 권한 회수 실패 → CASCADE CONSTRAINTS로 강제 삭제.

---

## 상(심화) 모범답안

---

**[41번] 정답: ②**

연쇄 회수(Cascade Revoke) 체인:
```
HR → alice (WITH GRANT OPTION)
      alice → bob (WITH GRANT OPTION)
               bob → carol

HR REVOKE FROM alice → alice 회수
                     → bob 연쇄 회수 (alice가 부여한 권한)
                     → carol 연쇄 회수 (bob이 부여한 권한)
```

`WITH GRANT OPTION`으로 부여된 권한의 연쇄 회수: **모든 하위 체인이 회수됨**.

---

**[42번] 정답: ②**

Oracle 저장 프로시저의 권한 처리:
- **직접 부여(Direct Grant)**: 프로시저 내에서 권한 인식 → 실행 가능
- **롤을 통한 권한**: 기본적으로 저장 프로시저/함수에서 **비활성화** (세션 수준 롤이 프로시저에는 미적용)
- 해결: 프로시저에서 필요한 권한을 직접 부여하거나 `AUTHID CURRENT_USER` 사용

---

**[43번] 정답: ②**

`WITH GRANT OPTION` 없이 받은 권한은 **재부여 불가**.  
demo가 `hr.employees SELECT`를 `WITH GRANT OPTION` 없이 받았으므로:
```
demo가 GRANT select ON hr.employees TO alice 실행 →
ORA-01031: insufficient privileges
```

---

**[44번] 정답: ②**

시스템 권한 회수의 특성:
- `REVOKE create table FROM demo` 실행
- demo의 **기존에 생성된 테이블은 그대로 유지**됨
- 회수 후에는 새로운 테이블 생성만 불가
- 기존 객체를 삭제하려면 별도 DROP TABLE 필요

---

**[45번] 정답: ③**

```sql
GRANT select ON employees TO demo WITH GRANT OPTION WITH ADMIN OPTION;
```

`WITH GRANT OPTION`과 `WITH ADMIN OPTION`을 동시에 지정 불가:
- `WITH GRANT OPTION`: 객체 권한 재부여용
- `WITH ADMIN OPTION`: 시스템 권한/롤 재부여용
- 두 옵션은 각각 다른 권한 유형에 사용, 동시 지정은 문법 오류.

---

**[46번] 정답: ②**

| 구분 | WITH ADMIN OPTION | WITH GRANT OPTION |
|------|------------------|-------------------|
| 대상 | 시스템 권한 / 롤 | 객체 권한 |
| 재부여 | 가능 | 가능 |
| REVOKE 시 | 연쇄 회수 **없음** | 연쇄 회수 **발생** |

WITH ADMIN OPTION은 REVOKE 시 연쇄 회수가 **발생하지 않음** (④가 실제로 반대).

---

**[47번] 정답: ②**

최소 권한 원칙 + 롤 기반 설계:

```sql
-- 회계팀 롤
CREATE ROLE acct_role;
GRANT select (salary, commission_pct) ON employees TO acct_role;
GRANT update (salary, commission_pct) ON employees TO acct_role;

-- 인사팀 롤
CREATE ROLE hr_role;
GRANT select ON employees TO hr_role;

-- 부여
GRANT acct_role TO 회계팀원들;
GRANT hr_role TO 인사팀원들;
-- 일반 사용자: 아무 권한 없음
```

열 수준 권한 + 롤 조합으로 최소 권한 원칙 구현.

---

**[48번] 정답: ②**

분석:
```
GRANT reader TO alice, bob → alice·bob 모두 reader 롤 보유
GRANT reader TO bob WITH ADMIN OPTION → bob은 reader를 타인에게 부여 가능
REVOKE reader FROM alice → alice의 reader만 회수
```

- **alice**: reader 롤 회수됨 (employees·departments SELECT 불가)
- **bob**: reader 롤 유지 (WITH ADMIN OPTION과 무관, 본인 것은 유지)

REVOKE는 명시된 사용자의 롤만 회수 (WITH ADMIN OPTION이 있어도 자신의 롤은 보호되지 않음).

---

**[49번] 정답: ②**

`USER_TAB_PRIVS_MADE`: **현재 사용자가 부여한** 객체 권한.

HR 스키마 입장:
- HR이 demo에게 부여한 `SELECT ON employees`, `INSERT ON departments` → 이 정보가 `USER_TAB_PRIVS_MADE`에 기록
- demo가 alice에게 부여한 `my_table SELECT`는 **demo의** `USER_TAB_PRIVS_MADE`에 기록 (HR과 무관)

---

**[50번] 정답: ③**

보안 모범 사례 위반:
```sql
GRANT ALL ON employees TO PUBLIC;
```

PUBLIC에 DML 권한 부여는 **모든 사용자**가 employees를 조작할 수 있어 보안상 매우 위험.  
최소 권한 원칙에 위배되는 대표적 안티패턴.

① 최소 권한 원칙 → 올바른 모범 사례  
② RBAC → 올바른 모범 사례  
④ 정기 권한 감사 → 올바른 모범 사례
