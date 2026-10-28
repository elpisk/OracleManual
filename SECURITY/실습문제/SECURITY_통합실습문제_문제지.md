# Oracle 19c Security 통합 실습문제 — 문제지

FGA, FGAC(VPD), syslog, Data Redaction, Resource Manager 를 한 시나리오 안에서 함께 구성하는 문제 3개다. 문제마다 다섯 기능이 모두 들어간다. 모범답안과 해설은 `SECURITY_통합실습문제_해설_모범답안.md` 에 따로 있다.

## 공통 환경

| 항목 | 값 |
|---|---|
| 서버 | OEL7V9 (Oracle Linux 7.9) |
| DB | Oracle Database 19.3 EE, non-CDB, SID orcl |
| 감사 모드 | 혼합 모드. `audit_trail=DB`, 통합 감사 정책 ORA_SECURECONFIG·ORA_LOGON_FAILURES 활성 |
| 샘플 스키마 | HR (문제 2에서 HR.EMPLOYEES 를 복사해 씀) |
| OS 계정 | oracle, root (rsyslog 설정) |

- 문제 1 → 2 → 3 순서로 푼다. 문제 1에서 만든 syslog 전송 구성을 문제 2·3이 그대로 쓰고, 세 문제를 모두 마친 뒤 원래 상태로 되돌린다.
- 보안 정책, 컨텍스트, 리소스 플랜은 문제마다 정한 보안 관리 계정(PQ1_SECADM, PQ2_SEC, PQ3_SEC)으로 만든다. SYS 는 SYS 만 할 수 있는 작업에만 쓴다: 초기화 파라미터, 재기동, 통합 감사 정책, 플랜 활성화, 시스템 권한 부여.
- 준비 스크립트는 SYS 로 실행한다. 요구사항에 이름이 주어진 객체는 그 이름을 그대로 쓴다.
- 문제마다 끝에서 만든 객체를 모두 지우고, 지워졌는지 조회로 확인한다. 이미 있던 감사 기록은 지우지 않는다.
- 각 문제의 "확인" 항목은 실행 결과로 보여야 한다. 결과가 예상과 다르면 원인을 딕셔너리 뷰, 감사 기록, syslog 파일로 설명한다.

## 문제 1 [상] 병원 진료 기록 보호

### 상황
- 진료 시스템의 환자 테이블 PQ1_OWN.PATIENTS 를 내과 의사(PQ1_KIM), 외과 의사(PQ1_LEE), 통계 분석 담당(PQ1_STAT)이 함께 조회한다.
- 직원의 부서와 역할은 PQ1_OWN.STAFF 에 있다. 보안 설정은 보안 관리자 PQ1_SECADM 이 한다.
- 병원 감사팀은 보안 설정 변경 기록을 DB 밖에서도 보관하길 원한다.

### 준비 스크립트 (SYS)
```sql
conn / as sysdba
CREATE USER pq1_own    IDENTIFIED BY pq1_own QUOTA 10M ON users;
CREATE USER pq1_secadm IDENTIFIED BY pq1_secadm QUOTA 10M ON users;
CREATE USER pq1_kim    IDENTIFIED BY pq1_kim;
CREATE USER pq1_lee    IDENTIFIED BY pq1_lee;
CREATE USER pq1_stat   IDENTIFIED BY pq1_stat;
GRANT CREATE SESSION, CREATE TABLE TO pq1_own;
GRANT CREATE SESSION TO pq1_kim, pq1_lee, pq1_stat;
GRANT CREATE SESSION, CREATE TABLE, CREATE PROCEDURE, CREATE TRIGGER,
      ADMINISTER DATABASE TRIGGER, CREATE ANY CONTEXT, DROP ANY CONTEXT TO pq1_secadm;
GRANT EXECUTE ON dbms_rls TO pq1_secadm;
GRANT EXECUTE ON dbms_redact TO pq1_secadm;
GRANT EXECUTE ON dbms_fga TO pq1_secadm;
EXEC DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SYSTEM_PRIVILEGE('PQ1_SECADM', 'ADMINISTER_RESOURCE_MANAGER', FALSE)
conn pq1_own/pq1_own
CREATE TABLE patients (
  patient_id NUMBER PRIMARY KEY,
  name       VARCHAR2(30),
  ssn        VARCHAR2(14),
  dept       VARCHAR2(10),
  diagnosis  VARCHAR2(60),
  cost       NUMBER);
INSERT INTO patients VALUES (1001, '홍길동', '900101-1234567', 'IM',  '고혈압',   350000);
INSERT INTO patients VALUES (1002, '김영희', '851212-2345678', 'IM',  '당뇨',    1200000);
INSERT INTO patients VALUES (1003, '이철수', '770505-1456789', 'IM',  '위염',      80000);
INSERT INTO patients VALUES (1004, '박민수', '920303-1567890', 'GS',  '맹장염',  1800000);
INSERT INTO patients VALUES (1005, '최지은', '880808-2678901', 'GS',  '골절',     950000);
INSERT INTO patients VALUES (1006, '정우성', '730707-1789012', 'GS',  '탈장',    2300000);
INSERT INTO patients VALUES (1007, '한소희', '150202-4890123', 'PED', '폐렴',     600000);
INSERT INTO patients VALUES (1008, '오지환', '170909-3901234', 'PED', '장염',     150000);
CREATE TABLE staff (
  username VARCHAR2(30) PRIMARY KEY,
  dept     VARCHAR2(10),
  role     VARCHAR2(10));
INSERT INTO staff VALUES ('PQ1_KIM',  'IM',  'DOCTOR');
INSERT INTO staff VALUES ('PQ1_LEE',  'GS',  'DOCTOR');
INSERT INTO staff VALUES ('PQ1_STAT', NULL,  'STAT');
COMMIT;
GRANT SELECT ON patients TO pq1_kim, pq1_lee, pq1_stat;
GRANT SELECT ON staff TO pq1_secadm;
```

| 계정 | 역할 |
|---|---|
| PQ1_OWN | 테이블 소유자 |
| PQ1_SECADM | 보안 관리자 (DBMS_RLS·DBMS_REDACT·DBMS_FGA 실행, ADMINISTER_RESOURCE_MANAGER) |
| PQ1_KIM | 내과(IM) 의사 |
| PQ1_LEE | 외과(GS) 의사 |
| PQ1_STAT | 통계 분석 (부서 없음) |

### 요구사항
1. syslog 전송
   - SYS 작업 감사 기록과 통합 감사 기록을 모두 syslog 로 보낸다. facility 는 local1, priority 는 warning.
   - rsyslog 는 local1 의 모든 메시지를 `/var/log/oracle_audit.log` 에 저장한다. 원래 rsyslog.conf 는 백업해 둔다.
2. 보안 설정 변경 감사
   - PQ1_SECADM 이 DBMS_RLS, DBMS_REDACT, DBMS_FGA, DBMS_RESOURCE_MANAGER 를 실행한 기록을 통합 감사 정책 PQ1_SECCFG_AUP 로 남긴다.
3. FGAC (행 수준)
   - 로그온할 때 STAFF 테이블에서 부서와 역할을 읽어 애플리케이션 컨텍스트 PQ1_CTX(속성 DEPT, ROLE)에 넣는다.
   - 역할이 DOCTOR 면 자기 부서 환자만, STAT 면 전체 환자가 보인다. 그 밖의 사용자(테이블 소유자 포함)에게는 0건이다.
   - 정책 이름은 PQ1_DEPT_VPD. 정책 함수는 ROLE 속성 값이 바뀔 때만 다시 실행되게 한다.
4. Data Redaction
   - SSN 은 누가 조회하든 앞 8자리(생년월일 6자리, '-', 성별 1자리)만 보이고 나머지는 `*` 로 가린다.
   - DIAGNOSIS 는 STAT 역할에게만 완전히 가린다. 두 열은 정책 하나(PQ1_RED)에 넣되, 열마다 다른 조건을 쓴다.
5. FGA
   - 진료비(COST) 100만 원 이상인 환자의 SSN 또는 DIAGNOSIS 를 조회하면 감사한다. 정책 이름은 PQ1_FGA_HIGH, SQL 문 전체를 남긴다.
   - 감사가 일어날 때마다 PQ1_SECADM.FGA_ALERT 테이블에 시각, 사용자, 정책 이름, SQL 문을 기록하는 핸들러를 붙인다.
6. Resource Manager
   - 플랜 PQ1_PLAN: 진료 그룹 PQ1_CLINIC 70%, 통계 그룹 PQ1_STAT 20%, 나머지 10%.
   - PQ1_STAT 그룹의 호출이 CPU 5초를 넘으면 그 SQL 만 취소한다. 세션은 끊지 않는다.
   - 그룹은 DB 사용자 이름으로 정한다. 플랜을 켜고, 실제 세션이 어느 그룹에 들어갔는지 확인한다.
7. 확인
   - 의사 두 명, 통계 사용자, 테이블 소유자의 조회 결과를 비교한다.
   - 감사 대상 질의와 대상이 아닌 질의를 섞어 실행하고, FGA 감사 기록과 FGA_ALERT 의 행이 맞는지 본다.
   - PQ1_STAT 가 스스로 PQ1_CLINIC 그룹으로 전환할 수 있는지 시도한다.
   - PQ1_STAT 의 CPU 를 오래 쓰는 질의가 취소되는 것과 그 횟수가 기록되는 곳을 확인한다.
   - syslog 파일에 남은 PQ1_SECADM 기록 수를 UNIFIED_AUDIT_TRAIL 과 비교하고, FGA 감사 기록이 syslog 로 가는지 확인한다.
8. 정리: 문제 1의 객체를 모두 지운다. syslog 전송 구성은 문제 2·3을 위해 남긴다.

### 생각해 볼 점
- PQ1_STAT 가 `GROUP BY diagnosis` 로 집계하면 가려진 진단명에 대해 무엇을 알 수 있는가.
- 로그온 트리거 안에서 예외가 나면 어떻게 되는가. 트리거의 예외 처리는 어떻게 정해야 하는가.

## 문제 2 [상] 인사 급여 데이터 접근 통제

### 상황
- HR.EMPLOYEES 를 복사한 PQ2_OWN.EMP 를 부서 관리자(PQ2_MGR, 사번 114 Raphaely), 인사팀(PQ2_HR), 급여 배치(PQ2_ETL)가 쓴다.
- 계정과 사번·역할의 대응은 PQ2_OWN.APP_MAP 에 있다. 보안 설정은 PQ2_SEC 가 한다.
- 배치는 낮 시간 온라인 업무에 영향을 주면 안 된다.

### 준비 스크립트 (SYS)
```sql
conn / as sysdba
CREATE USER pq2_own IDENTIFIED BY pq2_own QUOTA 10M ON users;
CREATE USER pq2_sec IDENTIFIED BY pq2_sec;
CREATE USER pq2_mgr IDENTIFIED BY pq2_mgr QUOTA 5M ON users;
CREATE USER pq2_hr  IDENTIFIED BY pq2_hr;
CREATE USER pq2_etl IDENTIFIED BY pq2_etl QUOTA 50M ON users;
GRANT CREATE SESSION, CREATE TABLE TO pq2_own, pq2_mgr, pq2_etl;
GRANT CREATE SESSION TO pq2_hr;
GRANT CREATE SESSION, CREATE PROCEDURE TO pq2_sec;
GRANT EXECUTE ON dbms_rls TO pq2_sec;
GRANT EXECUTE ON dbms_redact TO pq2_sec;
GRANT EXECUTE ON dbms_fga TO pq2_sec;
EXEC DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SYSTEM_PRIVILEGE('PQ2_SEC', 'ADMINISTER_RESOURCE_MANAGER', FALSE)
CREATE TABLE pq2_own.emp AS
  SELECT employee_id, last_name, email, phone_number, salary, commission_pct,
         manager_id, department_id
    FROM hr.employees;
ALTER TABLE pq2_own.emp ADD CONSTRAINT emp_pk PRIMARY KEY (employee_id);
CREATE TABLE pq2_own.app_map (
  username VARCHAR2(30) PRIMARY KEY,
  emp_id   NUMBER,
  app_role VARCHAR2(10));
INSERT INTO pq2_own.app_map VALUES ('PQ2_MGR', 114,  'MGR');
INSERT INTO pq2_own.app_map VALUES ('PQ2_HR',  NULL, 'HR');
INSERT INTO pq2_own.app_map VALUES ('PQ2_ETL', NULL, 'ETL');
COMMIT;
GRANT SELECT ON pq2_own.emp TO pq2_mgr, pq2_hr, pq2_etl;
GRANT UPDATE ON pq2_own.emp TO pq2_mgr, pq2_hr;
GRANT SELECT ON pq2_own.app_map TO pq2_sec;
CREATE TABLE pq2_etl.pay_stage (id NUMBER, pad VARCHAR2(200));
SELECT COUNT(*), COUNT(DISTINCT department_id) FROM pq2_own.emp;
```

| 계정 | 역할 |
|---|---|
| PQ2_OWN | 테이블 소유자 |
| PQ2_SEC | 보안 관리자 |
| PQ2_MGR | 부서 관리자 (사번 114, 직속 부하 115~119) |
| PQ2_HR | 인사팀 |
| PQ2_ETL | 급여 배치 계정 |

### 요구사항
1. FGAC (열 수준, DML)
   - 모든 사원 행은 누구에게나 보인다. SALARY·COMMISSION_PCT 는 HR·ETL 에게는 모두 보이고, MGR 에게는 본인과 직속 부하의 값만 보이며 나머지는 NULL 이다. 정책 이름 PQ2_SAL_COLS.
   - UPDATE 는 HR 이 모든 행, MGR 이 직속 부하 행만 할 수 있다. MGR 이 부하를 다른 관리자 밑으로 옮기는 UPDATE 는 거부된다. 정책 이름 PQ2_UPD.
2. Data Redaction
   - EMAIL 은 첫 글자 뒤를 `****` 로, PHONE_NUMBER 는 마지막 4자리를 `####` 로 바꾼다. 정규식 리댁션을 쓰고, HR 에게는 원래 값을 보인다. 정책 이름 PQ2_RED.
   - ETL 은 급여 파일을 만들려고 EMP 를 CTAS 로 복사해야 하고, 복사본에는 원래 값이 들어가야 한다.
   - MGR 이 CTAS 나 INSERT ... SELECT 로 가려진 열을 자기 테이블에 옮겨 담을 수 없음을 확인한다.
3. FGA
   - HR 이 아닌 사용자가 SALARY 나 COMMISSION_PCT 를 조회하거나 수정하면 감사한다. 바인드 변수 값까지 남긴다. 정책 이름 PQ2_FGA_SAL.
4. Resource Manager
   - 플랜 PQ2_PLAN: 온라인 그룹 PQ2_OLTP 60%, 배치 그룹 PQ2_BATCH 30%, 나머지 10%.
   - 세 계정은 사용자 이름으로 PQ2_OLTP 에 들어간다. 단, 모듈 이름이 PAYROLL_ETL 인 세션은 계정과 상관없이 PQ2_BATCH 에 들어간다.
   - PQ2_BATCH 는 undo 를 1 MB 까지만 쓸 수 있다.
   - 확인: 같은 PQ2_ETL 계정으로 모듈을 지정한 세션과 지정하지 않은 세션의 그룹을 비교한다. 배치 모듈에서 PAY_STAGE 2만 건을 고치는 UPDATE 의 결과를 보고, 모듈을 해제한 뒤 같은 UPDATE 와 비교한다.
5. syslog
   - SYS 가 EMP 를 직접 조회할 때 VPD, Redaction, FGA 가 각각 어떻게 동작하는지 확인한다.
   - 그 조회가 DB 밖 syslog 파일에 SQL 문과 함께 남았는지 확인한다.
6. 정리: 문제 2의 객체를 모두 지우고 확인한다.

### 생각해 볼 점
- 열 수준 VPD(ALL_ROWS)와 Data Redaction 은 둘 다 값을 가린다. WHERE 절에서 두 기능은 어떻게 다르게 동작하는가.
- ETL 에 준 권한의 범위는 어디까지인가. 그 권한을 쓴 기록은 어디에 남는가.

## 문제 3 [상] 콜센터 카드 고객 조회

### 상황
- 카드사 콜센터의 고객 테이블 PQ3_OWN.CUSTOMERS 를 서울 상담원(PQ3_AGENT1), 부산 상담원(PQ3_AGENT2), 감독자(PQ3_SUP)가 조회한다.
- 담당 지역은 PQ3_OWN.AGENTS 에 있다. VIP 고객 정보는 역할 PQ3_VIP_ROLE 을 세션에서 켠 사람만 본다. PQ3_AGENT1 은 이 역할을 받았지만 기본 역할은 아니다.
- 보안 설정은 PQ3_SEC 가 한다. 보안팀은 콜센터 계정의 감사 기록만 별도 파일로 받길 원한다.

### 준비 스크립트 (SYS)
```sql
conn / as sysdba
CREATE USER pq3_own    IDENTIFIED BY pq3_own QUOTA 10M ON users;
CREATE USER pq3_sec    IDENTIFIED BY pq3_sec;
CREATE USER pq3_agent1 IDENTIFIED BY pq3_agent1;
CREATE USER pq3_agent2 IDENTIFIED BY pq3_agent2;
CREATE USER pq3_sup    IDENTIFIED BY pq3_sup;
CREATE ROLE pq3_vip_role;
GRANT CREATE SESSION, CREATE TABLE TO pq3_own;
GRANT CREATE SESSION TO pq3_agent1, pq3_agent2, pq3_sup;
GRANT CREATE SESSION, CREATE PROCEDURE TO pq3_sec;
GRANT EXECUTE ON dbms_rls TO pq3_sec;
GRANT EXECUTE ON dbms_redact TO pq3_sec;
GRANT EXECUTE ON dbms_fga TO pq3_sec;
EXEC DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SYSTEM_PRIVILEGE('PQ3_SEC', 'ADMINISTER_RESOURCE_MANAGER', FALSE)
GRANT pq3_vip_role TO pq3_agent1, pq3_sup;
ALTER USER pq3_agent1 DEFAULT ROLE ALL EXCEPT pq3_vip_role;
conn pq3_own/pq3_own
CREATE TABLE customers (
  cust_id      NUMBER PRIMARY KEY,
  name         VARCHAR2(30),
  card_no      VARCHAR2(19),
  grade        VARCHAR2(3),
  credit_limit NUMBER,
  region       VARCHAR2(10));
INSERT INTO customers VALUES (201, '김민지', '4512-3456-7890-1234', 'VIP', 30000000, 'SEOUL');
INSERT INTO customers VALUES (202, '이준호', '5310-1111-2222-3333', 'GEN',  5000000, 'SEOUL');
INSERT INTO customers VALUES (203, '박소라', '3760-4444-5555-6666', 'GEN',  2000000, 'SEOUL');
INSERT INTO customers VALUES (204, '최다은', '4512-7777-8888-9999', 'VIP', 50000000, 'SEOUL');
INSERT INTO customers VALUES (205, '정훈',   '5310-1212-3434-5656', 'VIP', 40000000, 'BUSAN');
INSERT INTO customers VALUES (206, '강유리', '3760-9898-7676-5454', 'GEN',  3000000, 'BUSAN');
INSERT INTO customers VALUES (207, '윤석',   '4512-1357-2468-9753', 'GEN',  8000000, 'BUSAN');
CREATE TABLE agents (
  username VARCHAR2(30) PRIMARY KEY,
  region   VARCHAR2(10));
INSERT INTO agents VALUES ('PQ3_AGENT1', 'SEOUL');
INSERT INTO agents VALUES ('PQ3_AGENT2', 'BUSAN');
INSERT INTO agents VALUES ('PQ3_SUP',    'ALL');
COMMIT;
GRANT SELECT ON customers TO pq3_agent1, pq3_agent2, pq3_sup;
GRANT SELECT ON agents TO pq3_sec;
```

| 계정 | 역할 |
|---|---|
| PQ3_OWN | 테이블 소유자 |
| PQ3_SEC | 보안 관리자 |
| PQ3_AGENT1 | 서울 상담원. PQ3_VIP_ROLE 보유(기본 역할 아님) |
| PQ3_AGENT2 | 부산 상담원. 역할 없음 |
| PQ3_SUP | 감독자. 전 지역(ALL), PQ3_VIP_ROLE 기본 역할 |

### 요구사항
1. syslog 분리 저장
   - 문제 1의 전송 구성을 그대로 두고, DB 사용자 이름이 PQ3_ 로 시작하는 통합 감사 기록만 `/var/log/oracle_pq3.log` 에도 따로 저장한다. 규칙은 `/etc/rsyslog.d/` 아래 별도 파일에 두고, `/var/log/oracle_audit.log` 에도 계속 남게 한다.
   - 통합 감사 정책 PQ3_ROLE_AUP 로 PQ3 계정 세 개의 SET ROLE 을 감사한다.
2. FGAC
   - 상담원은 AGENTS 에 등록된 담당 지역의 고객만 본다. 지역이 ALL 이면 전 지역을 본다.
   - VIP 고객은 세션에서 PQ3_VIP_ROLE 이 켜져 있을 때만 보인다.
   - 정책 이름 PQ3_CUST_VPD. 정책 함수는 한 번만 실행되는 STATIC 유형으로 만들되, 사용자나 역할이 바뀌어도 결과가 맞아야 한다.
3. Data Redaction
   - CARD_NO 는 마지막 4자리만 보이게 하고, CREDIT_LIMIT 는 무작위 값으로 바꾼다. 감독자에게는 원래 값을 보인다. 정책 이름 PQ3_RED.
   - 확인: 상담원이 가려진 CREDIT_LIMIT 로 조건 검색과 정렬을 했을 때 무엇이 드러나는지 본다.
4. FGA
   - VIP 고객의 CREDIT_LIMIT 를 참조하는 SELECT 를 감사한다. 정책 이름 PQ3_FGA_LIMIT.
   - 확인: CREDIT_LIMIT 가 조회 목록에 없고 WHERE 절에만 있을 때도 감사되는지, VIP 행이 보이지 않는 상담원의 조회는 어떻게 되는지 본다.
5. Resource Manager
   - 플랜 PQ3_PLAN: 상담원 그룹 PQ3_AGENT 50%, 감독자 그룹 PQ3_SUP 40%, 나머지 10%.
   - PQ3_AGENT 그룹에서 예상 실행 시간이 5초를 넘는 SQL 은 실행 전에 거부한다.
   - 확인: 상담원이 큰 카테시안 조인을 실행했을 때의 결과와, 같은 뷰를 쓰는 평범한 조인의 결과를 비교한다.
6. 확인
   - PQ3_AGENT2 의 로그인 실패 1회와 PQ3_AGENT1 의 SET ROLE 두 번을 만든 뒤, `/var/log/oracle_pq3.log` 와 UNIFIED_AUDIT_TRAIL 의 기록을 비교한다.
7. 정리: 문제 3의 객체와 rsyslog 규칙 파일을 지우고 확인한다.

### 생각해 볼 점
- STATIC 정책인데도 사용자와 역할에 따라 결과가 달라지는 이유는 무엇인가.
- 상담원에게 PQ3_OWN.AGENTS 조회 권한이 없을 때, 술어 안의 서브쿼리는 어떻게 되는가.
- Redaction 과 FGA 를 함께 써야 하는 이유를 3번 확인 결과로 설명한다.

## 마무리 — 환경 원복
- 세 문제를 마친 뒤 syslog 관련 초기화 파라미터를 원래 값(미설정)으로 되돌리고 재기동한다.
- rsyslog.conf 를 백업으로 되돌리고, 실습에서 만든 로그 파일과 백업 파일을 지운다.
- resource_manager_plan 이 비어 있는지 확인한다.
