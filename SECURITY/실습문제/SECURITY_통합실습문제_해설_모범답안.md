# Oracle 19c Security 통합 실습문제 — 해설·모범답안

- 문제지 `SECURITY_통합실습문제_문제지.md` 와 번호, 순서가 같다.
- 모범답안의 출력은 OEL7V9 orcl 19.3(non-CDB, 혼합 감사 모드)에서 2026-10-28 에 실제로 실행한 결과다. 시각, SID, SESID, 무작위 리댁션 값은 실행할 때마다 달라진다.
- 준비 스크립트의 실행 결과는 싣지 않았다. 모든 명령이 오류 없이 끝난다.
- 출력 뒤의 해설은 결과에서 읽을 점, 그 방식을 고른 이유, 흔한 실수와 오류 코드 순서로 적었다.

## 문제 1 [상] 병원 진료 기록 보호

### 풀이 방향
- syslog 파라미터 두 개는 모두 정적 파라미터다. 문제 1에서 SPFILE 에 넣고 한 번 재기동하면 문제 2·3이 그대로 쓴다.
- 컨텍스트 값이 정해져야 VPD, Redaction, Resource Manager 가 같은 기준(부서, 역할, 사용자)으로 움직인다. 순서는 컨텍스트 → VPD → Redaction → FGA → RM 이 자연스럽다.
- 감사 정책 PQ1_SECCFG_AUP 는 PQ1_SECADM 이 보안 설정을 시작하기 전에 켜 둬야 설정 과정 전체가 기록된다.

### [1] syslog 전송 파라미터 (SYS)
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> SHOW PARAMETER audit_syslog_level

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
audit_syslog_level                   string
SYS@orcl> SHOW PARAMETER unified_audit_systemlog

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
unified_audit_systemlog              string
SYS@orcl> SHOW PARAMETER audit_sys_operations

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
audit_sys_operations                 boolean     TRUE
SYS@orcl> ALTER SYSTEM SET audit_syslog_level = 'local1.warning' SCOPE = SPFILE;

System altered.

SYS@orcl> ALTER SYSTEM SET unified_audit_systemlog = 'local1.warning' SCOPE = SPFILE;

System altered.

```

- `audit_syslog_level` 은 SYS 작업 감사(`audit_sys_operations=TRUE`, 기본값)와 전통 감사(`audit_trail=OS`)의 기록을 syslog 로 보낸다. `audit_trail` 은 DB 그대로 둬도 SYS 작업 기록은 syslog 로 간다.
- `unified_audit_systemlog` 는 19c 에서 UNIX 계열에 추가된 파라미터로, 통합 감사 기록의 핵심 필드를 syslog 로 보낸다.
- 둘 다 정적이라 `SCOPE=SPFILE` 없이 바꾸면 ORA-02095 가 난다.

### [2] rsyslog 규칙 (root)
```text
[root@oel7v9 ~]# cp -p /etc/rsyslog.conf /etc/rsyslog.conf.bak_pq
[root@oel7v9 ~]# echo 'local1.*                                                /var/log/oracle_audit.log' >> /etc/rsyslog.conf
[root@oel7v9 ~]# grep -n '^local' /etc/rsyslog.conf
73:local7.*                                                /var/log/boot.log
92:local1.*                                                /var/log/oracle_audit.log
[root@oel7v9 ~]# systemctl restart rsyslog
[root@oel7v9 ~]# systemctl is-active rsyslog
active
```

- 원래 파일을 먼저 백업한다. 마무리 단계에서 이 백업으로 되돌리고 md5 로 확인한다.
- `local1.*` 는 local1 의 모든 priority 를 받는다. `local1.err` 로 쓰면 warning 으로 보낸 Oracle 기록이 걸러져 파일이 비게 된다.

### [3] 재기동과 확인 (SYS)
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> SHUTDOWN IMMEDIATE
Database closed.
Database dismounted.
ORACLE instance shut down.
SYS@orcl> STARTUP
ORACLE instance started.

Total System Global Area 2147481656 bytes
Fixed Size                  8898616 bytes
Variable Size            1509949440 bytes
Database Buffers          620756992 bytes
Redo Buffers                7876608 bytes
Database mounted.
Database opened.
SYS@orcl> SHOW PARAMETER audit_syslog_level

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
audit_syslog_level                   string      LOCAL1.WARNING
SYS@orcl> SHOW PARAMETER unified_audit_systemlog

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
unified_audit_systemlog              string      LOCAL1.WARNING
```

- 파라미터 이름에 SYSLOG 가 들어간 것은 audit_syslog_level 뿐이라 `SHOW PARAMETER SYSLOG` 로는 unified_audit_systemlog 가 나오지 않는다. 이름을 따로 조회한다.

### [4] 보안 설정 변경 감사 정책 (SYS)
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> CREATE AUDIT POLICY pq1_seccfg_aup
  2    ACTIONS EXECUTE ON sys.dbms_rls,
  3            EXECUTE ON sys.dbms_redact,
  4            EXECUTE ON sys.dbms_fga,
  5            EXECUTE ON sys.dbms_resource_manager;

Audit policy created.

SYS@orcl> AUDIT POLICY pq1_seccfg_aup BY pq1_secadm;

Audit succeeded.

SYS@orcl> COL policy_name FOR A16
SYS@orcl> COL entity_name FOR A12
SYS@orcl> SELECT policy_name, enabled_option, entity_name, success, failure
  2    FROM audit_unified_enabled_policies WHERE policy_name = 'PQ1_SECCFG_AUP';

POLICY_NAME      ENABLED_OPTION  ENTITY_NAME  SUC FAI
---------------- --------------- ------------ --- ---
PQ1_SECCFG_AUP   BY USER         PQ1_SECADM   YES YES

1 row selected.

```

- 패키지 실행 감사는 `ACTIONS EXECUTE ON sys.<패키지>` 형식의 객체 액션으로 건다. `BY pq1_secadm` 으로 대상을 보안 관리자 한 명으로 좁혔다.
- 통합 감사 정책을 만들고 켜는 작업은 AUDIT_ADMIN 역할이 필요하다. 보안 관리자에게 이 역할까지 주면 자기 감사를 끌 수 있으므로 SYS(또는 별도 감사 관리자)가 맡는다.

### [5] 컨텍스트와 로그온 트리거 (PQ1_SECADM)
```text
SQL> conn pq1_secadm/pq1_secadm
Connected.
PQ1_SECADM@orcl> CREATE CONTEXT pq1_ctx USING pq1_secadm.pq1_ctx_pkg;

Context created.

PQ1_SECADM@orcl> CREATE OR REPLACE PACKAGE pq1_ctx_pkg AS
  2    PROCEDURE set_ctx;
  3  END;
  4  /

Package created.

PQ1_SECADM@orcl> CREATE OR REPLACE PACKAGE BODY pq1_ctx_pkg AS
  2    PROCEDURE set_ctx IS
  3      v_dept pq1_own.staff.dept%TYPE;
  4      v_role pq1_own.staff.role%TYPE;
  5    BEGIN
  6      SELECT dept, role INTO v_dept, v_role
  7        FROM pq1_own.staff
  8       WHERE username = SYS_CONTEXT('USERENV', 'SESSION_USER');
  9      DBMS_SESSION.SET_CONTEXT('PQ1_CTX', 'DEPT', v_dept);
 10      DBMS_SESSION.SET_CONTEXT('PQ1_CTX', 'ROLE', v_role);
 11    EXCEPTION
 12      WHEN NO_DATA_FOUND THEN NULL;
 13    END;
 14  END;
 15  /

Package body created.

PQ1_SECADM@orcl> CREATE OR REPLACE TRIGGER pq1_logon_trg AFTER LOGON ON DATABASE
  2  BEGIN
  3    IF SYS_CONTEXT('USERENV', 'SESSION_USER') LIKE 'PQ1\_%' ESCAPE '\' THEN
  4      pq1_ctx_pkg.set_ctx;
  5    END IF;
  6  EXCEPTION
  7    WHEN OTHERS THEN NULL;
  8  END;
  9  /

Trigger created.

PQ1_SECADM@orcl> COL dept FOR A6
PQ1_SECADM@orcl> COL role FOR A8
PQ1_SECADM@orcl> conn pq1_kim/pq1_kim
Connected.
PQ1_KIM@orcl> SELECT SYS_CONTEXT('PQ1_CTX', 'DEPT') dept, SYS_CONTEXT('PQ1_CTX', 'ROLE') role FROM dual;

DEPT   ROLE
------ --------
IM     DOCTOR

1 row selected.

PQ1_KIM@orcl> conn pq1_stat/pq1_stat
Connected.
PQ1_STAT@orcl> SELECT SYS_CONTEXT('PQ1_CTX', 'DEPT') dept, SYS_CONTEXT('PQ1_CTX', 'ROLE') role FROM dual;

DEPT   ROLE
------ --------
       STAT

1 row selected.

```

- 컨텍스트 값은 `CREATE CONTEXT ... USING` 에 지정한 패키지 안에서만 넣을 수 있다. 사용자가 DBMS_SESSION.SET_CONTEXT 를 직접 부르면 ORA-01031.
- 트리거는 PQ1_ 사용자에게만 패키지를 부르도록 조건을 둔다. `AFTER LOGON ON DATABASE` 는 모든 사용자의 로그온에 실행되기 때문이다.
- 로그온 트리거에서 처리하지 않은 예외가 나면 DBA 권한이 없는 사용자는 로그인 자체가 실패한다. 여기서는 `WHEN OTHERS THEN NULL` 로 로그인을 살리고, 컨텍스트가 비면 정책 함수가 '1=0' 을 돌려주게 해서 안전한 쪽으로 닫았다. 운영에서는 예외를 로그 테이블에 남기는 처리를 함께 둔다.
- 패키지는 정의자 권한으로 실행되므로 PQ1_OWN.STAFF 조회 권한은 PQ1_SECADM 에게 직접(역할이 아니라) 줘야 한다.

### [6] 행 수준 VPD (PQ1_SECADM)
```text
SQL> conn pq1_secadm/pq1_secadm
Connected.
PQ1_SECADM@orcl> CREATE OR REPLACE FUNCTION pq1_dept_pred(p_schema IN VARCHAR2, p_obj IN VARCHAR2)
  2    RETURN VARCHAR2 IS
  3  BEGIN
  4    IF SYS_CONTEXT('PQ1_CTX', 'ROLE') = 'STAT' THEN
  5      RETURN NULL;
  6    ELSIF SYS_CONTEXT('PQ1_CTX', 'ROLE') = 'DOCTOR' THEN
  7      RETURN 'dept = SYS_CONTEXT(''PQ1_CTX'', ''DEPT'')';
  8    END IF;
  9    RETURN '1=0';
 10  END;
 11  /

Function created.

PQ1_SECADM@orcl> BEGIN
  2    DBMS_RLS.ADD_POLICY(
  3      object_schema   => 'PQ1_OWN',
  4      object_name     => 'PATIENTS',
  5      policy_name     => 'PQ1_DEPT_VPD',
  6      function_schema => 'PQ1_SECADM',
  7      policy_function => 'PQ1_DEPT_PRED',
  8      statement_types => 'SELECT',
  9      policy_type     => DBMS_RLS.CONTEXT_SENSITIVE,
 10      namespace       => 'PQ1_CTX',
 11      attribute       => 'ROLE');
 12  END;
 13  /

PL/SQL procedure successfully completed.

PQ1_SECADM@orcl> conn pq1_kim/pq1_kim
Connected.
PQ1_KIM@orcl> SELECT patient_id, name, dept FROM pq1_own.patients ORDER BY patient_id;

PATIENT_ID NAME                           DEPT
---------- ------------------------------ ----------
      1001 홍길동                         IM
      1002 김영희                         IM
      1003 이철수                         IM

3 rows selected.

PQ1_KIM@orcl> conn pq1_lee/pq1_lee
Connected.
PQ1_LEE@orcl> SELECT patient_id, name, dept FROM pq1_own.patients ORDER BY patient_id;

PATIENT_ID NAME                           DEPT
---------- ------------------------------ ----------
      1004 박민수                         GS
      1005 최지은                         GS
      1006 정우성                         GS

3 rows selected.

PQ1_LEE@orcl> conn pq1_stat/pq1_stat
Connected.
PQ1_STAT@orcl> SELECT dept, COUNT(*) FROM pq1_own.patients GROUP BY dept ORDER BY dept;

DEPT         COUNT(*)
---------- ----------
GS                  3
IM                  3
PED                 2

3 rows selected.

PQ1_STAT@orcl> conn pq1_own/pq1_own
Connected.
PQ1_OWN@orcl> SELECT COUNT(*) FROM patients;

  COUNT(*)
----------
         0

1 row selected.

```

- 술어에 부서 값을 리터럴로 넣지 않고 `SYS_CONTEXT('PQ1_CTX', 'DEPT')` 를 그대로 둬서 의사 두 명이 같은 커서를 공유한다.
- CONTEXT_SENSITIVE 에 `namespace`·`attribute` 를 주면 ROLE 속성이 바뀔 때만 함수를 다시 실행한다(12.2 이후). 이 연결은 로컬 컨텍스트에서만 된다. ACCESSED GLOBALLY 컨텍스트에 연결하면 ORA-28126 이 난다.
- 테이블 소유자 PQ1_OWN 도 0건이다. VPD 는 소유자에게도 적용되고, 예외는 SYS 와 EXEMPT ACCESS POLICY 권한자뿐이다.
- STAT 에게 NULL 을 돌려주면 술어가 붙지 않아 전체가 보인다. 빈 문자열('')도 같은 뜻이다.

### [7] Data Redaction (PQ1_SECADM)
```text
SQL> conn pq1_secadm/pq1_secadm
Connected.
PQ1_SECADM@orcl> BEGIN
  2    DBMS_REDACT.ADD_POLICY(
  3      object_schema       => 'PQ1_OWN',
  4      object_name         => 'PATIENTS',
  5      policy_name         => 'PQ1_RED',
  6      column_name         => 'SSN',
  7      function_type       => DBMS_REDACT.PARTIAL,
  8      function_parameters => 'VVVVVVFVVVVVVV,VVVVVV-VVVVVVV,*,8,13',
  9      expression          => '1=1');
 10    DBMS_REDACT.ALTER_POLICY(
 11      object_schema       => 'PQ1_OWN',
 12      object_name         => 'PATIENTS',
 13      policy_name         => 'PQ1_RED',
 14      action              => DBMS_REDACT.ADD_COLUMN,
 15      column_name         => 'DIAGNOSIS',
 16      function_type       => DBMS_REDACT.FULL);
 17    DBMS_REDACT.CREATE_POLICY_EXPRESSION(
 18      policy_expression_name => 'PQ1_IS_STAT',
 19      expression             => 'SYS_CONTEXT(''PQ1_CTX'', ''ROLE'') = ''STAT''');
 20    DBMS_REDACT.APPLY_POLICY_EXPR_TO_COL(
 21      object_schema          => 'PQ1_OWN',
 22      object_name            => 'PATIENTS',
 23      column_name            => 'DIAGNOSIS',
 24      policy_expression_name => 'PQ1_IS_STAT');
 25  END;
 26  /
BEGIN
*
ERROR at line 1:
ORA-28092: The parameter POLICY_EXPRESSION_NAME with value 'PQ1_IS_STAT' has an error.
ORA-06512: at "SYS.DBMS_REDACT_INT", line 266
ORA-06512: at "SYS.DBMS_REDACT", line 303
ORA-06512: at line 17

PQ1_SECADM@orcl> COL ssn FOR A14
PQ1_SECADM@orcl> COL diagnosis FOR A10
PQ1_SECADM@orcl> conn pq1_kim/pq1_kim
Connected.
PQ1_KIM@orcl> SELECT patient_id, ssn, diagnosis FROM pq1_own.patients ORDER BY patient_id;

PATIENT_ID SSN            DIAGNOSIS
---------- -------------- ----------
      1001 900101-1******
      1002 851212-2******
      1003 770505-1******

3 rows selected.

PQ1_KIM@orcl> conn pq1_stat/pq1_stat
Connected.
PQ1_STAT@orcl> SELECT patient_id, ssn, diagnosis FROM pq1_own.patients ORDER BY patient_id;

PATIENT_ID SSN            DIAGNOSIS
---------- -------------- ----------
      1001 900101-1******
      1002 851212-2******
      1003 770505-1******
      1004 920303-1******
      1005 880808-2******
      1006 730707-1******
      1007 150202-4******
      1008 170909-3******

8 rows selected.

PQ1_STAT@orcl> conn / as sysdba
Connected.
SYS@orcl> COL column_name FOR A10
SYS@orcl> COL function_type FOR A18
SYS@orcl> COL expr FOR A40
SYS@orcl> SELECT c.column_name, c.function_type, NVL(e.expression, p.expression) expr
  2    FROM redaction_columns c
  3    JOIN redaction_policies p ON p.object_owner = c.object_owner AND p.object_name = c.object_name
  4    LEFT JOIN redaction_expressions e ON e.object_owner = c.object_owner AND e.object_name = c.object_name
  5                                      AND e.column_name = c.column_name
  6   WHERE c.object_owner = 'PQ1_OWN' ORDER BY c.column_name;

COLUMN_NAM FUNCTION_TYPE      EXPR
---------- ------------------ ----------------------------------------
DIAGNOSIS  FULL REDACTION     1=1
SSN        PARTIAL REDACTION  1=1

2 rows selected.

```

- PARTIAL 의 형식 `입력형식,출력형식,마스크문자,시작,끝` 에서 위치는 입력형식의 V(값) 자리만 센다. '-' 는 F 라서 세지 않으므로 8~13번째 숫자가 뒷자리 6개다.
- 정책 표현식(`expression => '1=1'`)은 정책 전체에 하나다. 열마다 다른 조건이 필요하면 12.2 부터 있는 CREATE_POLICY_EXPRESSION 으로 이름 붙인 표현식을 만들고 APPLY_POLICY_EXPR_TO_COL 로 열에 붙인다.
- APPLY_POLICY_EXPR_TO_COL 의 인자는 `object_name` 이다. `table_name` 으로 쓰면 PLS-00306 이 나고 블록 전체가 실행되지 않는다(실측 중 겪은 실수).
- 의사에게도 SSN 은 가려지지만 진단명은 보인다. STAT 에게는 둘 다 가려진다. FULL 리댁션의 문자 값은 공백 한 칸이라 화면에는 빈칸처럼 보인다.

### [8] FGA와 핸들러 (PQ1_SECADM)
```text
SQL> conn pq1_secadm/pq1_secadm
Connected.
PQ1_SECADM@orcl> CREATE TABLE fga_alert (
  2    alert_time TIMESTAMP,
  3    db_user    VARCHAR2(30),
  4    policy     VARCHAR2(30),
  5    sql_text   VARCHAR2(400));

Table created.

PQ1_SECADM@orcl> CREATE OR REPLACE PROCEDURE pq1_fga_handler(
  2    p_schema IN VARCHAR2, p_obj IN VARCHAR2, p_policy IN VARCHAR2) IS
  3    PRAGMA AUTONOMOUS_TRANSACTION;
  4  BEGIN
  5    INSERT INTO fga_alert
  6    VALUES (SYSTIMESTAMP, SYS_CONTEXT('USERENV', 'SESSION_USER'), p_policy,
  7            SUBSTR(SYS_CONTEXT('USERENV', 'CURRENT_SQL'), 1, 400));
  8    COMMIT;
  9  END;
 10  /

Procedure created.

PQ1_SECADM@orcl> BEGIN
  2    DBMS_FGA.ADD_POLICY(
  3      object_schema   => 'PQ1_OWN',
  4      object_name     => 'PATIENTS',
  5      policy_name     => 'PQ1_FGA_HIGH',
  6      audit_condition => 'cost >= 1000000',
  7      audit_column    => 'SSN,DIAGNOSIS',
  8      handler_schema  => 'PQ1_SECADM',
  9      handler_module  => 'PQ1_FGA_HANDLER',
 10      statement_types => 'SELECT',
 11      audit_trail     => DBMS_FGA.DB + DBMS_FGA.EXTENDED);
 12  END;
 13  /

PL/SQL procedure successfully completed.

PQ1_SECADM@orcl> conn pq1_kim/pq1_kim
Connected.
PQ1_KIM@orcl> SELECT name, cost FROM pq1_own.patients ORDER BY patient_id;

NAME                                 COST
------------------------------ ----------
홍길동                             350000
김영희                            1200000
이철수                              80000

3 rows selected.

PQ1_KIM@orcl> SELECT name, ssn FROM pq1_own.patients ORDER BY patient_id;

NAME                           SSN
------------------------------ --------------
홍길동                         900101-1******
김영희                         851212-2******
이철수                         770505-1******

3 rows selected.

PQ1_KIM@orcl> conn pq1_lee/pq1_lee
Connected.
PQ1_LEE@orcl> SELECT name, ssn FROM pq1_own.patients WHERE cost < 1000000;

NAME                           SSN
------------------------------ --------------
최지은                         880808-2******

1 row selected.

PQ1_LEE@orcl> conn pq1_stat/pq1_stat
Connected.
PQ1_STAT@orcl> SELECT dept, COUNT(*) FROM pq1_own.patients GROUP BY dept ORDER BY dept;

DEPT         COUNT(*)
---------- ----------
GS                  3
IM                  3
PED                 2

3 rows selected.

PQ1_STAT@orcl> SELECT diagnosis, COUNT(*) FROM pq1_own.patients GROUP BY diagnosis ORDER BY 1;

DIAGNOSIS                                                      COUNT(*)
------------------------------------------------------------ ----------
                                                                      1
                                                                      1
                                                                      1
                                                                      1
                                                                      1
                                                                      1
                                                                      1
                                                                      1

8 rows selected.

PQ1_STAT@orcl> conn / as sysdba
Connected.
SYS@orcl> COL db_user FOR A9
SYS@orcl> COL sql_text FOR A70
SYS@orcl> SELECT db_user, sql_text FROM dba_fga_audit_trail
  2   WHERE policy_name = 'PQ1_FGA_HIGH'
  3     AND timestamp >= (SELECT created FROM dba_users WHERE username = 'PQ1_SECADM')
  4   ORDER BY timestamp;

DB_USER   SQL_TEXT
--------- ----------------------------------------------------------------------
PQ1_STAT  SELECT diagnosis, COUNT(*) FROM pq1_own.patients GROUP BY diagnosis OR
          DER BY 1

PQ1_KIM   SELECT name, ssn FROM pq1_own.patients ORDER BY patient_id

2 rows selected.

SYS@orcl> COL policy FOR A13
SYS@orcl> SELECT db_user, policy, sql_text FROM pq1_secadm.fga_alert ORDER BY alert_time;

DB_USER   POLICY        SQL_TEXT
--------- ------------- ----------------------------------------------------------------------
PQ1_KIM   PQ1_FGA_HIGH  SELECT name, ssn FROM pq1_own.patients ORDER BY patient_id
PQ1_STAT  PQ1_FGA_HIGH  SELECT diagnosis, COUNT(*) FROM pq1_own.patients GROUP BY diagnosis OR
                        DER BY 1

2 rows selected.

```

- 감사된 것은 PQ1_KIM 의 SSN 조회(1002 행이 120만 원)와 PQ1_STAT 의 진단명 집계뿐이다. COST 만 고른 질의, 100만 원 미만 행만 돌려준 PQ1_LEE 의 질의, 진단명 없는 집계는 감사되지 않았다.
- FGA 조건은 VPD 로 걸러진 뒤 실제로 돌려준 행에 대해 판정된다. PQ1_LEE 의 결과는 1005(95만 원) 한 행뿐이라 조건이 참인 행이 없었다.
- 핸들러는 자율 트랜잭션으로 써야 한다. 사용자의 트랜잭션과 묶이면 사용자가 롤백할 때 알림 행도 사라진다.
- STAT 의 GROUP BY diagnosis 결과는 빈칸 8줄이다. 진단명은 가려졌지만 집계가 실제 값으로 그룹을 나눠, 서로 다른 진단명이 8개라는 사실은 드러난다. Redaction 은 출력만 바꾸고 SQL 처리에는 원래 값을 쓰기 때문이다.
- DBA_FGA_AUDIT_TRAIL 은 사용자를 지워도 남는다. 같은 정책 이름으로 실습을 반복하면 지난 기록이 섞이므로 계정 생성 시각 이후로 거른다.

### [9] 리소스 플랜 만들기와 활성화
```text
SQL> conn pq1_secadm/pq1_secadm
Connected.
PQ1_SECADM@orcl> BEGIN
  2    DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
  3    DBMS_RESOURCE_MANAGER.CREATE_CONSUMER_GROUP('PQ1_CLINIC', 'clinic screens');
  4    DBMS_RESOURCE_MANAGER.CREATE_CONSUMER_GROUP('PQ1_STAT',   'statistics');
  5    DBMS_RESOURCE_MANAGER.CREATE_PLAN('PQ1_PLAN', 'clinic first');
  6    DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
  7      plan => 'PQ1_PLAN', group_or_subplan => 'PQ1_CLINIC', comment => 'clinic',
  8      mgmt_p1 => 70);
  9    DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
 10      plan => 'PQ1_PLAN', group_or_subplan => 'PQ1_STAT', comment => 'stat',
 11      mgmt_p1 => 20, switch_group => 'CANCEL_SQL', switch_time => 5);
 12    DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
 13      plan => 'PQ1_PLAN', group_or_subplan => 'OTHER_GROUPS', comment => 'others',
 14      mgmt_p1 => 10);
 15    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 16      DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ1_KIM',  'PQ1_CLINIC');
 17    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 18      DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ1_LEE',  'PQ1_CLINIC');
 19    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 20      DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ1_STAT', 'PQ1_STAT');
 21    DBMS_RESOURCE_MANAGER.VALIDATE_PENDING_AREA;
 22    DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA;
 23  END;
 24  /

PL/SQL procedure successfully completed.

PQ1_SECADM@orcl> EXEC DBMS_RESOURCE_MANAGER.SWITCH_PLAN('PQ1_PLAN')
BEGIN DBMS_RESOURCE_MANAGER.SWITCH_PLAN('PQ1_PLAN'); END;

*
ERROR at line 1:
ORA-01031: insufficient privileges
ORA-06512: at "SYS.DBMS_RESOURCE_MANAGER", line 789
ORA-06512: at "SYS.DBMS_SQL", line 1721
ORA-06512: at "SYS.DBMS_RESOURCE_MANAGER", line 783
ORA-06512: at line 1

PQ1_SECADM@orcl> conn / as sysdba
Connected.
SYS@orcl> ALTER SYSTEM SET resource_manager_plan = 'PQ1_PLAN';

System altered.

SYS@orcl> SELECT name, is_top_plan FROM v$rsrc_plan;

NAME                             IS_TO
-------------------------------- -----
PQ1_PLAN                         TRUE

1 row selected.

```

- 플랜, 그룹, 매핑은 대기 영역(pending area)에서 한 번에 만들고 VALIDATE 후 SUBMIT 한다. 중간에 실패하면 CLEAR_PENDING_AREA 로 비운다.
- `switch_group => 'CANCEL_SQL'` 과 `switch_time => 5` 는 호출 하나가 CPU 5초를 넘으면 그 SQL 만 취소한다. 세션까지 끊으려면 KILL_SESSION 을 쓴다.
- SWITCH_PLAN 은 내부에서 ALTER SYSTEM 을 실행하므로 ADMINISTER_RESOURCE_MANAGER 만 있는 PQ1_SECADM 은 ORA-01031 이 난다. 플랜 활성화는 SYS 가 `ALTER SYSTEM SET resource_manager_plan` 으로 한다.
- V$RSRC_PLAN 에 PQ1_PLAN 이 최상위로 보이면 활성화된 것이다. 플랜이 꺼져 있으면 매핑을 만들어도 세션은 그룹에 들어가지 않는다.

### [10] 전환 권한 부여 (PQ1_SECADM)
```text
SQL> conn pq1_secadm/pq1_secadm
Connected.
PQ1_SECADM@orcl> BEGIN
  2    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ1_KIM',  'PQ1_CLINIC', FALSE);
  3    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ1_LEE',  'PQ1_CLINIC', FALSE);
  4    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ1_STAT', 'PQ1_STAT',   FALSE);
  5  END;
  6  /

PL/SQL procedure successfully completed.

PQ1_SECADM@orcl> conn / as sysdba
Connected.
SYS@orcl> COL grantee FOR A10
SYS@orcl> COL granted_group FOR A12
SYS@orcl> SELECT grantee, granted_group FROM dba_rsrc_consumer_group_privs WHERE grantee LIKE 'PQ1%' ORDER BY 1;

GRANTEE    GRANTED_GROU
---------- ------------
PQ1_KIM    PQ1_CLINIC
PQ1_LEE    PQ1_CLINIC
PQ1_STAT   PQ1_STAT

3 rows selected.

```

- 사용자에게 그룹 전환 권한을 준다. 이 권한이 없는 그룹으로는 DBMS_SESSION 으로 직접 전환할 수 없다(12단계).
- 전환 권한은 사용자를 지워도 DBA_RSRC_CONSUMER_GROUP_PRIVS 에 남을 수 있다. 실습 중 같은 이름으로 계정을 다시 만들었더니 지난 권한이 그대로 보였다(19.3 실측). 정리할 때는 계정을 지우기 전에 REVOKE 한다.

### [11] 세션의 소비자 그룹 확인 (oracle)
```text
[oracle@oel7v9 ~]$ for u in pq1_kim pq1_stat; do (echo "exec dbms_session.sleep(8)" | sqlplus -s $u/$u >/dev/null &); done; sleep 3
[oracle@oel7v9 ~]$ printf "set lines 100 pages 50 feedback off\ncol username for a10\ncol resource_consumer_group for a24\nselect username, resource_consumer_group from v\$session where username like 'PQ1%%' order by 1;\n" | sqlplus -s / as sysdba

USERNAME   RESOURCE_CONSUMER_GROUP
---------- ------------------------
PQ1_KIM    PQ1_CLINIC
PQ1_STAT   PQ1_STAT
[oracle@oel7v9 ~]$ sleep 7
```

- 사용자는 V$SESSION 을 볼 수 없으므로 두 계정의 세션을 백그라운드로 잠시 띄우고 SYS 가 조회했다.
- PQ1_KIM 은 PQ1_CLINIC, PQ1_STAT 는 PQ1_STAT 에 들어갔다. 매핑이 맞지 않으면 OTHER_GROUPS 로 보인다.

### [12] 그룹 직접 전환 시도 (PQ1_STAT)
```text
SQL> conn pq1_stat/pq1_stat
Connected.
PQ1_STAT@orcl> VARIABLE old VARCHAR2(30)
PQ1_STAT@orcl> EXEC DBMS_SESSION.SWITCH_CURRENT_CONSUMER_GROUP('PQ1_CLINIC', :old, FALSE)
BEGIN DBMS_SESSION.SWITCH_CURRENT_CONSUMER_GROUP('PQ1_CLINIC', :old, FALSE); END;

*
ERROR at line 1:
ORA-01031: insufficient privileges
ORA-06512: at "SYS.DBMS_SESSION", line 177
ORA-06512: at line 1


```

- PQ1_STAT 는 PQ1_CLINIC 전환 권한이 없어 ORA-01031. 통계 사용자가 CPU 제한을 피해 진료 그룹으로 옮겨 갈 수 없다.

### [13] CPU 한도 초과 SQL 취소
```text
SQL> conn pq1_stat/pq1_stat
Connected.
PQ1_STAT@orcl> SET TIMING ON
PQ1_STAT@orcl> SELECT COUNT(*) FROM all_objects a, all_objects b WHERE a.object_id > b.object_id;
SELECT COUNT(*) FROM all_objects a, all_objects b WHERE a.object_id > b.object_id
                     *
ERROR at line 1:
ORA-00040: active time limit exceeded - call aborted

Elapsed: 00:00:07.65
PQ1_STAT@orcl> SET TIMING OFF
PQ1_STAT@orcl> conn / as sysdba
Connected.
SYS@orcl> COL name FOR A14
SYS@orcl> SELECT name, requests, consumed_cpu_time, sql_canceled
  2    FROM v$rsrc_consumer_group WHERE name LIKE 'PQ1%' ORDER BY name;

NAME             REQUESTS CONSUMED_CPU_TIME SQL_CANCELED
-------------- ---------- ----------------- ------------
PQ1_CLINIC              1                 8            0
PQ1_STAT                3              7635            1

2 rows selected.

```

- ORA-00040 은 switch_time 을 넘겨 CANCEL_SQL 로 전환된 호출이 받는 오류다. 세션은 살아 있어 다음 SQL 을 계속 실행할 수 있다.
- 경과 시간은 7.9초인데 기준은 CPU 5초다. 대기 시간은 세지 않는다.
- V$RSRC_CONSUMER_GROUP.SQL_CANCELED 에 취소 횟수가 쌓인다. 인스턴스를 재기동하면 0 부터 다시 센다.

### [14] syslog 파일 확인 (root)
```text
[root@oel7v9 ~]# grep -c 'DBUSER:"PQ1_SECADM"' /var/log/oracle_audit.log
5
[root@oel7v9 ~]# grep 'DBUSER:"PQ1_SECADM"' /var/log/oracle_audit.log | tail -n 3
Oct 28 16:21:24 oel7v9 journal: Oracle Unified Audit[22689]: LENGTH: '179' TYPE:"4" DBID:"1767674490" SESID:"1089044794" CLIENTID:"" ENTRYID:"1" STMTID:"11" DBUSER:"PQ1_SECADM" CURUSER:"PQ1_SECADM" ACTION:"47" RETCODE:"0" SCHEMA:"SYS" OBJNAME:"DBMS_FGA"
Oct 28 16:21:25 oel7v9 journal: Oracle Unified Audit[22787]: LENGTH: '190' TYPE:"4" DBID:"1767674490" SESID:"413986263" CLIENTID:"" ENTRYID:"1" STMTID:"7" DBUSER:"PQ1_SECADM" CURUSER:"PQ1_SECADM" ACTION:"47" RETCODE:"0" SCHEMA:"SYS" OBJNAME:"DBMS_RESOURCE_MANAGER"
Oct 28 16:21:26 oel7v9 journal: Oracle Unified Audit[22787]: LENGTH: '191' TYPE:"4" DBID:"1767674490" SESID:"413986263" CLIENTID:"" ENTRYID:"2" STMTID:"68" DBUSER:"PQ1_SECADM" CURUSER:"PQ1_SECADM" ACTION:"47" RETCODE:"0" SCHEMA:"SYS" OBJNAME:"DBMS_RESOURCE_MANAGER"
[root@oel7v9 ~]# grep -c 'OBJNAME:"PATIENTS"' /var/log/oracle_audit.log
0
```

- 'Oracle Unified Audit' 줄의 ACTION 47 은 EXECUTE, OBJNAME 은 실행한 패키지다. syslog 에는 SQL 문 없이 핵심 필드만 간다.
- PATIENTS 를 대상으로 한 기록은 0건이다. 혼합 모드에서 FGA 기록은 FGA_LOG$ 에만 남고 통합 감사 기록이 아니어서 syslog 로 가지 않는다.

### [15] 통합 감사 기록과 대조 (SYS)
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> EXEC DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL

PL/SQL procedure successfully completed.

SYS@orcl> COL action_name FOR A10
SYS@orcl> COL obj FOR A24
SYS@orcl> SELECT action_name, object_name obj, COUNT(*)
  2    FROM unified_audit_trail
  3   WHERE dbusername = 'PQ1_SECADM' AND unified_audit_policies LIKE '%PQ1_SECCFG_AUP%'
  4     AND event_timestamp >= (SELECT created FROM dba_users WHERE username = 'PQ1_SECADM')
  5   GROUP BY action_name, object_name ORDER BY obj;

ACTION_NAM OBJ                        COUNT(*)
---------- ------------------------ ----------
EXECUTE    DBMS_FGA                          1
EXECUTE    DBMS_REDACT                       1
EXECUTE    DBMS_RESOURCE_MANAGER             2
EXECUTE    DBMS_RLS                          1

4 rows selected.

```

- 통합 감사 기록 5건과 syslog 5건이 맞는다. 하나의 PL/SQL 블록에서 같은 패키지를 여러 번 불러도 기록은 한 건이다. DBMS_RESOURCE_MANAGER 2건은 플랜을 만든 블록과 실패한 SWITCH_PLAN 이다.
- 통합 감사는 기본적으로 큐에 모았다가 쓴다. 바로 조회하려면 FLUSH_UNIFIED_AUDIT_TRAIL 을 먼저 실행한다.

### [16] 정리
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> ALTER SYSTEM SET resource_manager_plan = '';

System altered.

SYS@orcl> conn pq1_secadm/pq1_secadm
Connected.
PQ1_SECADM@orcl> BEGIN
  2    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ1_KIM',  'PQ1_CLINIC');
  3    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ1_LEE',  'PQ1_CLINIC');
  4    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ1_STAT', 'PQ1_STAT');
  5    DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
  6    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ1_KIM',  NULL);
  7    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ1_LEE',  NULL);
  8    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ1_STAT', NULL);
  9    DBMS_RESOURCE_MANAGER.DELETE_PLAN_CASCADE('PQ1_PLAN');
 10    DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA;
 11  END;
 12  /

PL/SQL procedure successfully completed.

PQ1_SECADM@orcl> EXEC DBMS_REDACT.DROP_POLICY_EXPRESSION('PQ1_IS_STAT')

PL/SQL procedure successfully completed.

PQ1_SECADM@orcl> conn / as sysdba
Connected.
SYS@orcl> NOAUDIT POLICY pq1_seccfg_aup BY pq1_secadm;

Noaudit succeeded.

SYS@orcl> DROP AUDIT POLICY pq1_seccfg_aup;

Audit Policy dropped.

SYS@orcl> DROP TRIGGER pq1_secadm.pq1_logon_trg;

Trigger dropped.

SYS@orcl> DROP CONTEXT pq1_ctx;

Context dropped.

SYS@orcl> DROP USER pq1_kim CASCADE;

User dropped.

SYS@orcl> DROP USER pq1_lee CASCADE;

User dropped.

SYS@orcl> DROP USER pq1_stat CASCADE;

User dropped.

SYS@orcl> DROP USER pq1_own CASCADE;

User dropped.

SYS@orcl> DROP USER pq1_secadm CASCADE;

User dropped.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'PQ1%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_rsrc_plans WHERE plan LIKE 'PQ1%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_rsrc_consumer_groups WHERE consumer_group LIKE 'PQ1%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_rsrc_consumer_group_privs WHERE grantee LIKE 'PQ1%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM redaction_expressions WHERE policy_expression_name LIKE 'PQ1%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM audit_unified_policies WHERE policy_name LIKE 'PQ1%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SHOW PARAMETER resource_manager_plan

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
resource_manager_plan                string
```

- 플랜을 먼저 끄고, 전환 권한을 회수한 뒤, 매핑과 플랜을 지운다. 그룹을 지운 다음 권한을 회수하면 ORA-00600 [kzdtpd2] 가 난 사례가 있다(이 VM 의 SEC 변환 실측).
- DROP_POLICY_EXPRESSION 은 표현식이 아직 열에 붙어 있어 ORA-28092 로 실패했다. 열에서 떼어 내거나 테이블을 지우면 함께 없어지며, 마지막 조회에서 0건으로 확인된다.
- 로그온 트리거는 DATABASE 수준이라 다른 사용자의 로그온에도 실행된다. 계정 삭제(CASCADE)에 맡기지 않고 따로 지워 확인한다.

### 생각해 볼 점 — 답
- GROUP BY diagnosis: 진단명이 8가지라는 것과 진단명별 환자 수가 드러난다. 값이 적은 열에서는 조건 검색(`WHERE diagnosis = '당뇨'`)으로 값을 하나씩 맞혀 볼 수도 있다. 민감도가 높으면 Redaction 대신 열 수준 VPD(ALL_ROWS)로 열 값 자체를 NULL 로 처리하거나, 조회 권한을 뷰로 좁힌다.
- 로그온 트리거 예외: 처리하지 않은 예외는 로그인 실패(ORA-04088 계열)로 이어지고, ADMINISTER DATABASE TRIGGER 권한이 없는 모든 사용자가 접속하지 못한다. 예외는 잡되 보안상 안전한 쪽(컨텍스트 비움 → 0건)으로 떨어지게 하고 원인은 별도 로그에 남긴다.

## 문제 2 [상] 인사 급여 데이터 접근 통제

### 풀이 방향
- 행은 모두 보이고 값만 감춰야 하므로 행 수준 VPD 가 아니라 열 수준 VPD(`sec_relevant_cols` + ALL_ROWS)를 쓴다. UPDATE 는 별도 정책으로 나눈다. ALL_ROWS 는 SELECT 에만 쓸 수 있다.
- 정책 함수는 APP_MAP 을 직접 읽는다. 컨텍스트가 없으므로 기본 유형(DYNAMIC)으로 둔다.
- Resource Manager 매핑은 MODULE_NAME 이 ORACLE_USER 보다 우선순위가 높다는 점을 이용한다.

### [1] 열 수준 VPD와 UPDATE 정책 (PQ2_SEC)
```text
SQL> conn pq2_sec/pq2_sec
Connected.
PQ2_SEC@orcl> CREATE OR REPLACE FUNCTION pq2_sal_pred(p_schema IN VARCHAR2, p_obj IN VARCHAR2)
  2    RETURN VARCHAR2 IS
  3    v_emp  pq2_own.app_map.emp_id%TYPE;
  4    v_role pq2_own.app_map.app_role%TYPE;
  5  BEGIN
  6    SELECT emp_id, app_role INTO v_emp, v_role
  7      FROM pq2_own.app_map WHERE username = SYS_CONTEXT('USERENV', 'SESSION_USER');
  8    IF v_role IN ('HR', 'ETL') THEN
  9      RETURN NULL;
 10    ELSIF v_role = 'MGR' THEN
 11      RETURN 'employee_id = ' || v_emp || ' OR manager_id = ' || v_emp;
 12    END IF;
 13    RETURN '1=0';
 14  EXCEPTION
 15    WHEN NO_DATA_FOUND THEN RETURN '1=0';
 16  END;
 17  /

Function created.

PQ2_SEC@orcl> CREATE OR REPLACE FUNCTION pq2_upd_pred(p_schema IN VARCHAR2, p_obj IN VARCHAR2)
  2    RETURN VARCHAR2 IS
  3    v_emp  pq2_own.app_map.emp_id%TYPE;
  4    v_role pq2_own.app_map.app_role%TYPE;
  5  BEGIN
  6    SELECT emp_id, app_role INTO v_emp, v_role
  7      FROM pq2_own.app_map WHERE username = SYS_CONTEXT('USERENV', 'SESSION_USER');
  8    IF v_role = 'HR' THEN
  9      RETURN NULL;
 10    ELSIF v_role = 'MGR' THEN
 11      RETURN 'manager_id = ' || v_emp;
 12    END IF;
 13    RETURN '1=0';
 14  EXCEPTION
 15    WHEN NO_DATA_FOUND THEN RETURN '1=0';
 16  END;
 17  /

Function created.

PQ2_SEC@orcl> BEGIN
  2    DBMS_RLS.ADD_POLICY(
  3      object_schema         => 'PQ2_OWN',
  4      object_name           => 'EMP',
  5      policy_name           => 'PQ2_SAL_COLS',
  6      function_schema       => 'PQ2_SEC',
  7      policy_function       => 'PQ2_SAL_PRED',
  8      statement_types       => 'SELECT',
  9      sec_relevant_cols     => 'SALARY,COMMISSION_PCT',
 10      sec_relevant_cols_opt => DBMS_RLS.ALL_ROWS);
 11    DBMS_RLS.ADD_POLICY(
 12      object_schema   => 'PQ2_OWN',
 13      object_name     => 'EMP',
 14      policy_name     => 'PQ2_UPD',
 15      function_schema => 'PQ2_SEC',
 16      policy_function => 'PQ2_UPD_PRED',
 17      statement_types => 'UPDATE',
 18      update_check    => TRUE);
 19  END;
 20  /

PL/SQL procedure successfully completed.

PQ2_SEC@orcl> conn pq2_mgr/pq2_mgr
Connected.
PQ2_MGR@orcl> SELECT employee_id, last_name, salary, commission_pct, manager_id
  2    FROM pq2_own.emp WHERE department_id IN (30, 80) AND employee_id < 150
  3   ORDER BY employee_id;

EMPLOYEE_ID LAST_NAME                     SALARY COMMISSION_PCT MANAGER_ID
----------- ------------------------- ---------- -------------- ----------
        114 Raphaely                       11000                       100
        115 Khoo                            3100                       114
        116 Baida                           2900                       114
        117 Tobias                          2800                       114
        118 Himuro                          2600                       114
        119 Colmenares                      2500                       114
        145 Russell                                                    100
        146 Partners                                                   100
        147 Errazuriz                                                  100
        148 Cambrault                                                  100
        149 Zlotkey                                                    100

11 rows selected.

PQ2_MGR@orcl> SELECT COUNT(*), COUNT(salary) FROM pq2_own.emp;

  COUNT(*) COUNT(SALARY)
---------- -------------
       107             6

1 row selected.

PQ2_MGR@orcl> UPDATE pq2_own.emp SET salary = salary * 1.1 WHERE employee_id = 115;

1 row updated.

PQ2_MGR@orcl> UPDATE pq2_own.emp SET salary = salary * 1.1 WHERE employee_id = 145;

0 rows updated.

PQ2_MGR@orcl> UPDATE pq2_own.emp SET manager_id = 100 WHERE employee_id = 116;
UPDATE pq2_own.emp SET manager_id = 100 WHERE employee_id = 116
               *
ERROR at line 1:
ORA-28115: policy with check option violation

PQ2_MGR@orcl> ROLLBACK;

Rollback complete.

PQ2_MGR@orcl> conn pq2_hr/pq2_hr
Connected.
PQ2_HR@orcl> SELECT COUNT(*), COUNT(salary) FROM pq2_own.emp;

  COUNT(*) COUNT(SALARY)
---------- -------------
       107           107

1 row selected.

```

- PQ2_MGR 은 107행이 모두 보이지만 SALARY 가 있는 행은 6건(본인 114, 부하 115~119)이다. 145~149 는 같은 부서 80 이지만 다른 관리자 소속이라 NULL.
- 145 의 UPDATE 는 술어 `manager_id = 114` 에 걸려 0건이다. 오류가 아니라 0건이라 애플리케이션은 권한 문제와 대상 없음을 구분하지 못한다.
- 116 을 다른 관리자 밑으로 옮기면 바뀐 행이 술어를 벗어나 update_check 가 ORA-28115 를 낸다. update_check 가 없으면 이 UPDATE 는 성공하고 116 은 MGR 의 관리 범위에서 사라진다.
- 정책 함수가 사용자마다 다른 리터럴 술어를 돌려주므로 STATIC 으로 두면 처음 실행한 사용자의 술어가 모든 사용자에게 붙는다. 기본값 DYNAMIC 이 맞다.

### [2] 정규식 Redaction과 복사 차단 (PQ2_SEC)
```text
SQL> conn pq2_sec/pq2_sec
Connected.
PQ2_SEC@orcl> BEGIN
  2    DBMS_REDACT.ADD_POLICY(
  3      object_schema      => 'PQ2_OWN',
  4      object_name        => 'EMP',
  5      policy_name        => 'PQ2_RED',
  6      column_name        => 'EMAIL',
  7      function_type      => DBMS_REDACT.REGEXP,
  8      regexp_pattern     => '^(.)(.*)$',
  9      regexp_replace_string => '\1****',
 10      regexp_position    => 1,
 11      regexp_occurrence  => 1,
 12      expression         => 'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') <> ''PQ2_HR''');
 13    DBMS_REDACT.ALTER_POLICY(
 14      object_schema      => 'PQ2_OWN',
 15      object_name        => 'EMP',
 16      policy_name        => 'PQ2_RED',
 17      action             => DBMS_REDACT.ADD_COLUMN,
 18      column_name        => 'PHONE_NUMBER',
 19      function_type      => DBMS_REDACT.REGEXP,
 20      regexp_pattern     => '[0-9]{4}$',
 21      regexp_replace_string => '####',
 22      regexp_position    => 1,
 23      regexp_occurrence  => 1);
 24  END;
 25  /

PL/SQL procedure successfully completed.

PQ2_SEC@orcl> COL email FOR A10
PQ2_SEC@orcl> COL phone_number FOR A14
PQ2_SEC@orcl> conn pq2_mgr/pq2_mgr
Connected.
PQ2_MGR@orcl> SELECT employee_id, email, phone_number FROM pq2_own.emp
  2   WHERE manager_id = 114 ORDER BY employee_id;

EMPLOYEE_ID EMAIL      PHONE_NUMBER
----------- ---------- --------------
        115 A****      515.127.####
        116 S****      515.127.####
        117 S****      515.127.####
        118 G****      515.127.####
        119 K****      515.127.####

5 rows selected.

PQ2_MGR@orcl> CREATE TABLE my_team AS SELECT employee_id, email FROM pq2_own.emp WHERE manager_id = 114;
CREATE TABLE my_team AS SELECT employee_id, email FROM pq2_own.emp WHERE manager_id = 114
                                            *
ERROR at line 1:
ORA-28081: Insufficient privileges - the command references a redacted object.

PQ2_MGR@orcl> conn pq2_hr/pq2_hr
Connected.
PQ2_HR@orcl> SELECT employee_id, email, phone_number FROM pq2_own.emp
  2   WHERE manager_id = 114 ORDER BY employee_id;

EMPLOYEE_ID EMAIL      PHONE_NUMBER
----------- ---------- --------------
        115 AKHOO      515.127.4562
        116 SBAIDA     515.127.4563
        117 STOBIAS    515.127.4564
        118 GHIMURO    515.127.4565
        119 KCOLMENA   515.127.4566

5 rows selected.

PQ2_HR@orcl> conn pq2_etl/pq2_etl
Connected.
PQ2_ETL@orcl> CREATE TABLE emp_copy AS SELECT employee_id, email, salary FROM pq2_own.emp;
CREATE TABLE emp_copy AS SELECT employee_id, email, salary FROM pq2_own.emp
                                             *
ERROR at line 1:
ORA-28081: Insufficient privileges - the command references a redacted object.

PQ2_ETL@orcl> conn / as sysdba
Connected.
SYS@orcl> GRANT EXEMPT REDACTION POLICY TO pq2_etl;

Grant succeeded.

SYS@orcl> conn pq2_etl/pq2_etl
Connected.
PQ2_ETL@orcl> CREATE TABLE emp_copy AS SELECT employee_id, email, salary FROM pq2_own.emp;

Table created.

PQ2_ETL@orcl> SELECT employee_id, email, salary FROM emp_copy WHERE employee_id IN (115, 145);

EMPLOYEE_ID EMAIL          SALARY
----------- ---------- ----------
        115 AKHOO            3100
        145 JRUSSEL         14000

2 rows selected.

PQ2_ETL@orcl> DROP TABLE emp_copy PURGE;

Table dropped.

PQ2_ETL@orcl> conn pq2_mgr/pq2_mgr
Connected.
PQ2_MGR@orcl> CREATE TABLE my_team (employee_id NUMBER, email VARCHAR2(25));

Table created.

PQ2_MGR@orcl> INSERT INTO my_team SELECT employee_id, email FROM pq2_own.emp WHERE manager_id = 114;
INSERT INTO my_team SELECT employee_id, email FROM pq2_own.emp WHERE manager_id = 114
                                        *
ERROR at line 1:
ORA-28081: Insufficient privileges - the command references a redacted object.

PQ2_MGR@orcl> DROP TABLE my_team PURGE;

Table dropped.

```

- REGEXP 리댁션은 REGEXP_REPLACE 와 같은 인자를 쓴다. `regexp_occurrence => 1` 로 첫 일치만 바꿨다.
- PQ2_MGR 의 CTAS 와 INSERT ... SELECT 는 모두 ORA-28081. 리댁션 정책이 있는 객체를 다른 테이블로 옮기는 문장은 막힌다.
- PQ2_ETL 의 CTAS 도 ORA-28081 이다. 정책 표현식에서 PQ2_ETL 을 뺀 구성(`NOT IN ('PQ2_HR', 'PQ2_ETL')`)으로도 측정했는데 CTAS 와 INSERT ... SELECT 는 똑같이 막혔다. 표현식은 표시 여부만 정하고 복사 차단에는 영향이 없다. 복사가 필요한 계정에는 EXEMPT REDACTION POLICY 를 준다.
- EXEMPT REDACTION POLICY 는 DB 안의 모든 리댁션 정책을 우회하는 시스템 권한이다. 배치 전용 계정에만 주고, ORA_SECURECONFIG 가 이 권한 사용을 감사하는지 확인해 둔다.

### [3] FGA — 급여 조회·수정 감사 (PQ2_SEC)
```text
SQL> conn pq2_sec/pq2_sec
Connected.
PQ2_SEC@orcl> BEGIN
  2    DBMS_FGA.ADD_POLICY(
  3      object_schema   => 'PQ2_OWN',
  4      object_name     => 'EMP',
  5      policy_name     => 'PQ2_FGA_SAL',
  6      audit_condition => 'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') <> ''PQ2_HR''',
  7      audit_column    => 'SALARY,COMMISSION_PCT',
  8      statement_types => 'SELECT,UPDATE',
  9      audit_trail     => DBMS_FGA.DB + DBMS_FGA.EXTENDED);
 10  END;
 11  /

PL/SQL procedure successfully completed.

PQ2_SEC@orcl> conn pq2_mgr/pq2_mgr
Connected.
PQ2_MGR@orcl> SELECT last_name, salary FROM pq2_own.emp WHERE department_id = 30 ORDER BY 1;

LAST_NAME                     SALARY
------------------------- ----------
Baida                           2900
Colmenares                      2500
Himuro                          2600
Khoo                            3100
Raphaely                       11000
Tobias                          2800

6 rows selected.

PQ2_MGR@orcl> VARIABLE eid NUMBER
PQ2_MGR@orcl> EXEC :eid := 117

PL/SQL procedure successfully completed.

PQ2_MGR@orcl> UPDATE pq2_own.emp SET salary = salary + 100 WHERE employee_id = :eid;

1 row updated.

PQ2_MGR@orcl> ROLLBACK;

Rollback complete.

PQ2_MGR@orcl> SELECT last_name, department_id FROM pq2_own.emp WHERE employee_id = 117;

LAST_NAME                 DEPARTMENT_ID
------------------------- -------------
Tobias                               30

1 row selected.

PQ2_MGR@orcl> conn pq2_hr/pq2_hr
Connected.
PQ2_HR@orcl> SELECT SUM(salary) FROM pq2_own.emp;

SUM(SALARY)
-----------
     691416

1 row selected.

PQ2_HR@orcl> conn / as sysdba
Connected.
SYS@orcl> COL db_user FOR A8
SYS@orcl> COL stmt FOR A6
SYS@orcl> COL sql_text FOR A62
SYS@orcl> COL sql_bind FOR A14
SYS@orcl> SELECT db_user, statement_type stmt, sql_text, sql_bind
  2    FROM dba_fga_audit_trail
  3   WHERE policy_name = 'PQ2_FGA_SAL'
  4     AND timestamp >= (SELECT created FROM dba_users WHERE username = 'PQ2_SEC')
  5   ORDER BY timestamp;

DB_USER  STMT   SQL_TEXT                                                       SQL_BIND
-------- ------ -------------------------------------------------------------- --------------
PQ2_MGR  UPDATE UPDATE pq2_own.emp SET salary = salary + 100 WHERE employee_id  #1(3):117
                 = :eid

PQ2_MGR  SELECT SELECT last_name, salary FROM pq2_own.emp WHERE department_id
                = 30 ORDER BY 1

2 rows selected.

```

- `audit_trail => DBMS_FGA.DB + DBMS_FGA.EXTENDED` 여야 SQL_TEXT 와 SQL_BIND 가 남는다. UPDATE 의 바인드 값 `#1(3):117` 은 첫 번째 바인드, 길이 3, 값 117 이라는 뜻이다.
- ROLLBACK 한 UPDATE 도 감사 기록은 남는다. FGA 기록은 자율 트랜잭션으로 쓰인다.
- PQ2_HR 의 SUM(salary) 는 audit_condition 이 거짓이라 기록되지 않았다. SALARY 를 쓰지 않은 117 조회도 기록이 없다.

### [4] 리소스 플랜과 매핑 (PQ2_SEC, SYS)
```text
SQL> conn pq2_sec/pq2_sec
Connected.
PQ2_SEC@orcl> BEGIN
  2    DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
  3    DBMS_RESOURCE_MANAGER.CREATE_CONSUMER_GROUP('PQ2_OLTP',  'online HR');
  4    DBMS_RESOURCE_MANAGER.CREATE_CONSUMER_GROUP('PQ2_BATCH', 'payroll batch');
  5    DBMS_RESOURCE_MANAGER.CREATE_PLAN('PQ2_PLAN', 'HR daytime');
  6    DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
  7      plan => 'PQ2_PLAN', group_or_subplan => 'PQ2_OLTP', comment => 'oltp',
  8      mgmt_p1 => 60);
  9    DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
 10      plan => 'PQ2_PLAN', group_or_subplan => 'PQ2_BATCH', comment => 'batch',
 11      mgmt_p1 => 30, undo_pool => 1024);
 12    DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
 13      plan => 'PQ2_PLAN', group_or_subplan => 'OTHER_GROUPS', comment => 'others',
 14      mgmt_p1 => 10);
 15    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 16      DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ2_MGR', 'PQ2_OLTP');
 17    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 18      DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ2_HR',  'PQ2_OLTP');
 19    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 20      DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ2_ETL', 'PQ2_OLTP');
 21    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 22      DBMS_RESOURCE_MANAGER.MODULE_NAME, 'PAYROLL_ETL', 'PQ2_BATCH');
 23    DBMS_RESOURCE_MANAGER.VALIDATE_PENDING_AREA;
 24    DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA;
 25    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ2_MGR', 'PQ2_OLTP',  FALSE);
 26    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ2_HR',  'PQ2_OLTP',  FALSE);
 27    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ2_ETL', 'PQ2_OLTP',  FALSE);
 28    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ2_ETL', 'PQ2_BATCH', FALSE);
 29  END;
 30  /

PL/SQL procedure successfully completed.

PQ2_SEC@orcl> conn / as sysdba
Connected.
SYS@orcl> ALTER SYSTEM SET resource_manager_plan = 'PQ2_PLAN';

System altered.

SYS@orcl> COL attribute FOR A22
SYS@orcl> SELECT attribute, priority FROM dba_rsrc_mapping_priority
  2   WHERE attribute IN ('MODULE_NAME', 'ORACLE_USER') ORDER BY priority;

ATTRIBUTE                PRIORITY
---------------------- ----------
MODULE_NAME                     5
ORACLE_USER                     7

2 rows selected.

```

- `undo_pool` 단위는 KB 다. 1024 는 1 MB.
- DBA_RSRC_MAPPING_PRIORITY 에서 MODULE_NAME(5)이 ORACLE_USER(7)보다 숫자가 작아 먼저 적용된다. 같은 사용자라도 모듈을 바꾸면 배치 그룹으로 간다.

### [5] 모듈별 소비자 그룹 확인 (oracle)
```text
[oracle@oel7v9 ~]$ (printf "exec dbms_application_info.set_module('PAYROLL_ETL', NULL)\nexec dbms_session.sleep(8)\n" | sqlplus -s pq2_etl/pq2_etl >/dev/null &); (echo "exec dbms_session.sleep(8)" | sqlplus -s pq2_etl/pq2_etl >/dev/null &); sleep 3
[oracle@oel7v9 ~]$ printf "set lines 100 pages 50 feedback off\ncol username for a8\ncol module for a12\ncol resource_consumer_group for a16\nselect username, module, resource_consumer_group from v\$session where username = 'PQ2_ETL' order by 2;\n" | sqlplus -s / as sysdba

USERNAME MODULE       RESOURCE_CONSUME
-------- ------------ ----------------
PQ2_ETL  PAYROLL_ETL  PQ2_BATCH
PQ2_ETL  SQL*Plus     PQ2_OLTP
[oracle@oel7v9 ~]$ sleep 7
```

- 같은 PQ2_ETL 계정인데 모듈이 PAYROLL_ETL 인 세션은 PQ2_BATCH, 기본 모듈(SQL*Plus) 세션은 PQ2_OLTP 다. 세션 도중에 모듈을 바꾸면 매핑을 다시 계산해 그룹이 바뀐다.
- 모듈 이름은 클라이언트가 정하는 값이라 사용자가 PAYROLL_ETL 을 피해 OLTP 로 남을 수도 있다. 모듈 기반 매핑은 업무 구분 수단이지 통제 수단이 아니다.

### [6] UNDO_POOL 한도
```text
SQL> conn pq2_etl/pq2_etl
Connected.
PQ2_ETL@orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('PAYROLL_ETL', NULL)

PL/SQL procedure successfully completed.

PQ2_ETL@orcl> INSERT INTO pay_stage SELECT level, RPAD('x', 200, 'x') FROM dual CONNECT BY level <= 20000;

20000 rows created.

PQ2_ETL@orcl> COMMIT;

Commit complete.

PQ2_ETL@orcl> UPDATE pay_stage SET pad = RPAD('y', 200, 'y');
UPDATE pay_stage SET pad = RPAD('y', 200, 'y')
       *
ERROR at line 1:
ORA-30027: Undo quota violation - failed to get 3424 (bytes)

PQ2_ETL@orcl> SELECT COUNT(*) FROM pay_stage WHERE pad LIKE 'y%';

  COUNT(*)
----------
         0

1 row selected.

PQ2_ETL@orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE(NULL, NULL)

PL/SQL procedure successfully completed.

PQ2_ETL@orcl> UPDATE pay_stage SET pad = RPAD('y', 200, 'y');

20000 rows updated.

PQ2_ETL@orcl> ROLLBACK;

Rollback complete.

```

- 2만 건 UPDATE 의 undo 가 1 MB 를 넘어 ORA-30027. 그 문장만 롤백되고 앞서 COMMIT 한 INSERT 는 남는다(pad 가 y 인 행 0건).
- INSERT 는 undo 가 적게 생겨 같은 건수로는 한도에 걸리지 않았다. 한도 시험에는 UPDATE·DELETE 를 쓴다.
- 모듈을 해제해 PQ2_OLTP 로 돌아가면 같은 UPDATE 가 성공한다. 배치는 커밋 단위를 나누어 한도 안에서 돈다.

### [7] SYS 직접 조회 (SYS)
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> COL email FOR A10
SYS@orcl> COL db_user FOR A8
SYS@orcl> SELECT employee_id, email, phone_number, salary FROM pq2_own.emp WHERE employee_id = 115;

EMPLOYEE_ID EMAIL      PHONE_NUMBER             SALARY
----------- ---------- -------------------- ----------
        115 AKHOO      515.127.4562               3100

1 row selected.

SYS@orcl> SELECT db_user, COUNT(*) FROM dba_fga_audit_trail
  2   WHERE policy_name = 'PQ2_FGA_SAL'
  3     AND timestamp >= (SELECT created FROM dba_users WHERE username = 'PQ2_SEC')
  4   GROUP BY db_user;

DB_USER    COUNT(*)
-------- ----------
PQ2_MGR           2

1 row selected.

```

- SYS 에게는 VPD, Redaction 이 적용되지 않아 EMAIL, PHONE_NUMBER, SALARY 가 원래 값으로 나온다.
- FGA 기록도 PQ2_MGR 2건뿐이다. SYS 의 조회는 FGA 로 잡히지 않는다. 그래서 SYS 작업은 DB 밖에서 따로 남겨야 한다.

### [8] syslog 의 SYS 작업 기록 (root)
```text
[root@oel7v9 ~]# grep 'Oracle Audit' /var/log/oracle_audit.log | grep -c 'pq2_own.emp WHERE employee_id = 115'
1
[root@oel7v9 ~]# grep 'Oracle Audit' /var/log/oracle_audit.log | grep 'pq2_own.emp WHERE employee_id = 115' | tail -n 1
Oct 28 16:22:10 oel7v9 journal: Oracle Audit[24198]: LENGTH : '348' ACTION :[88] 'SELECT employee_id, email, phone_number, salary FROM pq2_own.emp WHERE employee_id = 115' DATABASE USER:[1] '/' PRIVILEGE :[6] 'SYSDBA' CLIENT USER:[6] 'oracle' CLIENT TERMINAL:[5] 'pts/0' STATUS:[1] '0' DBID:[10] '1767674490' SESSIONID:[10] '4294967295' USERHOST:[18] 'oel7v9.localdomain' CLIENT ADDRESS:[0] '' ACTION NUMBER:[1] '3'
```

- 'Oracle Audit' 줄은 audit_syslog_level 로 간 SYS 작업 기록이다. ACTION 에 SQL 문 전체, PRIVILEGE 에 SYSDBA 가 남는다.
- syslog 파일은 root 소유(600)라 oracle OS 계정이나 DBA 는 지울 수 없다. 원격 로그 서버로 넘기면 DBA 권한과 분리된 보관이 된다.

### [9] 정리
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> ALTER SYSTEM SET resource_manager_plan = '';

System altered.

SYS@orcl> conn pq2_sec/pq2_sec
Connected.
PQ2_SEC@orcl> BEGIN
  2    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ2_MGR', 'PQ2_OLTP');
  3    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ2_HR',  'PQ2_OLTP');
  4    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ2_ETL', 'PQ2_OLTP');
  5    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ2_ETL', 'PQ2_BATCH');
  6    DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
  7    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ2_MGR', NULL);
  8    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ2_HR',  NULL);
  9    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ2_ETL', NULL);
 10    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.MODULE_NAME, 'PAYROLL_ETL', NULL);
 11    DBMS_RESOURCE_MANAGER.DELETE_PLAN_CASCADE('PQ2_PLAN');
 12    DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA;
 13  END;
 14  /

PL/SQL procedure successfully completed.

PQ2_SEC@orcl> conn / as sysdba
Connected.
SYS@orcl> DROP USER pq2_mgr CASCADE;

User dropped.

SYS@orcl> DROP USER pq2_hr CASCADE;

User dropped.

SYS@orcl> DROP USER pq2_etl CASCADE;

User dropped.

SYS@orcl> DROP USER pq2_own CASCADE;

User dropped.

SYS@orcl> DROP USER pq2_sec CASCADE;

User dropped.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'PQ2%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_rsrc_consumer_groups WHERE consumer_group LIKE 'PQ2%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_rsrc_consumer_group_privs WHERE grantee LIKE 'PQ2%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_rsrc_group_mappings WHERE value IN ('PAYROLL_ETL') OR value LIKE 'PQ2%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SHOW PARAMETER resource_manager_plan

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
resource_manager_plan                string
```

- 문제 1과 같은 순서로 플랜을 끄고, 권한을 회수하고, 매핑(MODULE_NAME 포함)과 플랜을 지운다.
- EXEMPT REDACTION POLICY 는 계정 삭제와 함께 사라진다. 계정을 남겨 두는 경우에는 REVOKE 를 따로 한다.

### 생각해 볼 점 — 답
- 열 수준 VPD 는 가려진 열을 WHERE 절에서도 NULL 로 평가한다(정책 술어가 거짓인 행에서는 값이 없는 것과 같음). Redaction 은 출력만 바꾸고 WHERE·ORDER BY·GROUP BY 는 원래 값으로 처리한다. 급여처럼 범위 검색으로 값을 추측할 수 있는 열은 VPD 쪽이 안전하고, 화면 표시만 감추면 되는 이메일·전화번호는 Redaction 이 간단하다.
- EXEMPT REDACTION POLICY 는 모든 스키마의 모든 리댁션 정책을 우회한다. 객체 단위로 줄 수 없으므로 배치 계정에만 주고, 대화형 로그인을 막거나(접속 경로 제한) ORA_SECURECONFIG 의 권한 사용 기록을 정기적으로 확인한다.

## 문제 3 [상] 콜센터 카드 고객 조회

### 풀이 방향
- 술어 문자열을 사용자와 무관한 상수로 만들고, 사용자·역할은 술어 안의 SYS_CONTEXT 가 실행할 때 평가하게 하면 STATIC 정책으로도 결과가 맞다.
- 역할이 켜져 있는지는 `SYS_CONTEXT('SYS_SESSION_ROLES', '<역할>')` 로 확인한다(12.1 이후).
- rsyslog 규칙은 `/etc/rsyslog.d/*.conf` 가 rsyslog.conf 의 규칙보다 먼저 읽힌다. 중단(stop) 없이 두면 두 파일에 모두 남는다.

### [1] rsyslog 분리 규칙 (root)
```text
[root@oel7v9 ~]# grep -n 'IncludeConfig' /etc/rsyslog.conf
36:$IncludeConfig /etc/rsyslog.d/*.conf
[root@oel7v9 ~]# echo ':msg, contains, "DBUSER:\"PQ3_"    /var/log/oracle_pq3.log' > /etc/rsyslog.d/oracle_pq3.conf
[root@oel7v9 ~]# cat /etc/rsyslog.d/oracle_pq3.conf
:msg, contains, "DBUSER:\"PQ3_"    /var/log/oracle_pq3.log
[root@oel7v9 ~]# rsyslogd -N1 2>&1 | tail -n 2
rsyslogd: version 8.24.0-55.el7, config validation run (level 1), master config /etc/rsyslog.conf
rsyslogd: End of config validation run. Bye.
[root@oel7v9 ~]# systemctl restart rsyslog
[root@oel7v9 ~]# systemctl is-active rsyslog
active
```

- `:msg, contains, "DBUSER:\"PQ3_"` 은 속성 기반 필터다. 대소문자를 구분하므로 SYS 가 소문자로 쓴 SQL 문(pq3_own...)은 걸리지 않고 DBUSER 필드만 걸린다.
- `rsyslogd -N1` 으로 재시작 전에 문법을 검사한다. 오류가 있으면 줄 번호와 함께 나온다.

### [2] SET ROLE 감사 정책 (SYS)
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> CREATE AUDIT POLICY pq3_role_aup ACTIONS SET ROLE;

Audit policy created.

SYS@orcl> AUDIT POLICY pq3_role_aup BY pq3_agent1, pq3_agent2, pq3_sup;

Audit succeeded.

SYS@orcl> COL policy_name FOR A18
SYS@orcl> COL entity_name FOR A12
SYS@orcl> SELECT policy_name, entity_name FROM audit_unified_enabled_policies
  2   WHERE policy_name IN ('PQ3_ROLE_AUP', 'ORA_LOGON_FAILURES') ORDER BY 1, 2;

POLICY_NAME        ENTITY_NAME
------------------ ------------
ORA_LOGON_FAILURES ALL USERS
PQ3_ROLE_AUP       PQ3_AGENT1
PQ3_ROLE_AUP       PQ3_AGENT2
PQ3_ROLE_AUP       PQ3_SUP

4 rows selected.

```

- ORA_SECURECONFIG 에도 SET ROLE 이 들어 있다. 별도 정책을 두면 감사 대상 계정을 명시할 수 있고, 기본 정책을 바꾸더라도 감시가 유지된다. 9단계에서 보듯 기록은 한 건이고 정책 이름이 함께 붙는다.

### [3] STATIC VPD — 지역과 역할 (PQ3_SEC)
```text
SQL> conn pq3_sec/pq3_sec
Connected.
PQ3_SEC@orcl> CREATE OR REPLACE FUNCTION pq3_cust_pred(p_schema IN VARCHAR2, p_obj IN VARCHAR2)
  2    RETURN VARCHAR2 IS
  3  BEGIN
  4    RETURN '(region IN (SELECT a.region FROM pq3_own.agents a'
  5        || '             WHERE a.username = SYS_CONTEXT(''USERENV'', ''SESSION_USER''))'
  6        || ' OR EXISTS (SELECT 1 FROM pq3_own.agents a'
  7        || '             WHERE a.username = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')'
  8        || '               AND a.region = ''ALL''))'
  9        || ' AND (grade <> ''VIP'''
 10        || '      OR SYS_CONTEXT(''SYS_SESSION_ROLES'', ''PQ3_VIP_ROLE'') = ''TRUE'')';
 11  END;
 12  /

Function created.

PQ3_SEC@orcl> BEGIN
  2    DBMS_RLS.ADD_POLICY(
  3      object_schema   => 'PQ3_OWN',
  4      object_name     => 'CUSTOMERS',
  5      policy_name     => 'PQ3_CUST_VPD',
  6      function_schema => 'PQ3_SEC',
  7      policy_function => 'PQ3_CUST_PRED',
  8      statement_types => 'SELECT',
  9      policy_type     => DBMS_RLS.STATIC);
 10  END;
 11  /

PL/SQL procedure successfully completed.

PQ3_SEC@orcl> conn pq3_agent1/pq3_agent1
Connected.
PQ3_AGENT1@orcl> SELECT cust_id, name, grade, region FROM pq3_own.customers ORDER BY cust_id;

   CUST_ID NAME                           GRA REGION
---------- ------------------------------ --- ----------
       202 이준호                         GEN SEOUL
       203 박소라                         GEN SEOUL

2 rows selected.

PQ3_AGENT1@orcl> SET ROLE pq3_vip_role;

Role set.

PQ3_AGENT1@orcl> SELECT cust_id, name, grade, region FROM pq3_own.customers ORDER BY cust_id;

   CUST_ID NAME                           GRA REGION
---------- ------------------------------ --- ----------
       201 김민지                         VIP SEOUL
       202 이준호                         GEN SEOUL
       203 박소라                         GEN SEOUL
       204 최다은                         VIP SEOUL

4 rows selected.

PQ3_AGENT1@orcl> conn pq3_agent2/pq3_agent2
Connected.
PQ3_AGENT2@orcl> SELECT cust_id, name, grade, region FROM pq3_own.customers ORDER BY cust_id;

   CUST_ID NAME                           GRA REGION
---------- ------------------------------ --- ----------
       206 강유리                         GEN BUSAN
       207 윤석                           GEN BUSAN

2 rows selected.

PQ3_AGENT2@orcl> SET ROLE pq3_vip_role;
SET ROLE pq3_vip_role
*
ERROR at line 1:
ORA-01924: role 'PQ3_VIP_ROLE' not granted or does not exist

PQ3_AGENT2@orcl> conn pq3_sup/pq3_sup
Connected.
PQ3_SUP@orcl> SELECT cust_id, name, grade, region FROM pq3_own.customers ORDER BY cust_id;

   CUST_ID NAME                           GRA REGION
---------- ------------------------------ --- ----------
       201 김민지                         VIP SEOUL
       202 이준호                         GEN SEOUL
       203 박소라                         GEN SEOUL
       204 최다은                         VIP SEOUL
       205 정훈                           VIP BUSAN
       206 강유리                         GEN BUSAN
       207 윤석                           GEN BUSAN

7 rows selected.

```

- PQ3_AGENT1 은 역할을 켜기 전 서울 일반 고객 2건, `SET ROLE pq3_vip_role` 뒤 VIP 를 포함해 4건이다. PQ3_AGENT2 는 역할이 없어 ORA-01924 가 나고 부산 일반 고객 2건만 본다. PQ3_SUP 은 ALL 이라 7건이다.
- STATIC 이라 함수는 한 번만 실행되지만, 술어 안의 SYS_CONTEXT 와 서브쿼리는 실행할 때마다 평가되므로 사용자와 역할에 따라 결과가 달라진다.
- 상담원들은 PQ3_OWN.AGENTS 조회 권한이 없는데도 술어의 서브쿼리가 동작했다(19.3 실측). 상담원은 AGENTS 를 직접 조회할 수 없지만 정책은 정상으로 돈다.
- 역할 판정에 USER_ROLE_PRIVS 같은 뷰를 쓰면 기본 역할 여부만 알 수 있다. 세션에서 실제로 켜진 역할은 SYS_SESSION_ROLES 로 본다.

### [4] Redaction — 카드 번호와 신용한도 (PQ3_SEC)
```text
SQL> conn pq3_sec/pq3_sec
Connected.
PQ3_SEC@orcl> BEGIN
  2    DBMS_REDACT.ADD_POLICY(
  3      object_schema       => 'PQ3_OWN',
  4      object_name         => 'CUSTOMERS',
  5      policy_name         => 'PQ3_RED',
  6      column_name         => 'CARD_NO',
  7      function_type       => DBMS_REDACT.PARTIAL,
  8      function_parameters => DBMS_REDACT.REDACT_CCN16_F12,
  9      expression          => 'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') <> ''PQ3_SUP''');
 10    DBMS_REDACT.ALTER_POLICY(
 11      object_schema       => 'PQ3_OWN',
 12      object_name         => 'CUSTOMERS',
 13      policy_name         => 'PQ3_RED',
 14      action              => DBMS_REDACT.ADD_COLUMN,
 15      column_name         => 'CREDIT_LIMIT',
 16      function_type       => DBMS_REDACT.RANDOM);
 17  END;
 18  /

PL/SQL procedure successfully completed.

PQ3_SEC@orcl> COL card_no FOR A19
PQ3_SEC@orcl> conn pq3_agent1/pq3_agent1
Connected.
PQ3_AGENT1@orcl> SET ROLE pq3_vip_role;

Role set.

PQ3_AGENT1@orcl> SELECT cust_id, card_no, credit_limit FROM pq3_own.customers ORDER BY cust_id;

   CUST_ID CARD_NO             CREDIT_LIMIT
---------- ------------------- ------------
       201 ****-****-****-1234      1279828
       202 ****-****-****-3333       179348
       203 ****-****-****-6666       763098
       204 ****-****-****-9999     37094806

4 rows selected.

PQ3_AGENT1@orcl> SELECT cust_id, card_no, credit_limit FROM pq3_own.customers ORDER BY cust_id;

   CUST_ID CARD_NO             CREDIT_LIMIT
---------- ------------------- ------------
       201 ****-****-****-1234     10099236
       202 ****-****-****-3333      2678592
       203 ****-****-****-6666      1719090
       204 ****-****-****-9999     19230005

4 rows selected.

PQ3_AGENT1@orcl> SELECT cust_id, name FROM pq3_own.customers WHERE credit_limit >= 30000000 ORDER BY 1;

   CUST_ID NAME
---------- ------------------------------
       201 김민지
       204 최다은

2 rows selected.

PQ3_AGENT1@orcl> SELECT cust_id, name FROM pq3_own.customers ORDER BY credit_limit DESC FETCH FIRST 1 ROWS ONLY;

   CUST_ID NAME
---------- ------------------------------
       204 최다은

1 row selected.

PQ3_AGENT1@orcl> conn pq3_sup/pq3_sup
Connected.
PQ3_SUP@orcl> SELECT cust_id, card_no, credit_limit FROM pq3_own.customers ORDER BY cust_id;

   CUST_ID CARD_NO             CREDIT_LIMIT
---------- ------------------- ------------
       201 4512-3456-7890-1234     30000000
       202 5310-1111-2222-3333      5000000
       203 3760-4444-5555-6666      2000000
       204 4512-7777-8888-9999     50000000
       205 5310-1212-3434-5656     40000000
       206 3760-9898-7676-5454      3000000
       207 4512-1357-2468-9753      8000000

7 rows selected.

```

- REDACT_CCN16_F12 는 'VVVVFVVVVFVVVVFVVVV,VVVV-VVVV-VVVV-VVVV,*,1,12' 를 미리 정의한 상수다.
- RANDOM 리댁션은 조회할 때마다 다른 값을 낸다. 같은 질의를 두 번 실행한 결과가 다르다.
- `WHERE credit_limit >= 30000000` 은 실제 값으로 걸러 VIP 두 명을 정확히 찾고, `ORDER BY credit_limit DESC` 는 실제 최고 한도 고객(204)을 맞힌다. 화면 값은 무작위인데 검색과 정렬로 실제 값의 범위와 순위가 드러난다.
- PQ3_SUP 은 표현식에서 빠져 원래 값을 본다.

### [5] FGA — VIP 신용한도 참조 감사 (PQ3_SEC)
```text
SQL> conn pq3_sec/pq3_sec
Connected.
PQ3_SEC@orcl> BEGIN
  2    DBMS_FGA.ADD_POLICY(
  3      object_schema   => 'PQ3_OWN',
  4      object_name     => 'CUSTOMERS',
  5      policy_name     => 'PQ3_FGA_LIMIT',
  6      audit_condition => 'grade = ''VIP''',
  7      audit_column    => 'CREDIT_LIMIT',
  8      statement_types => 'SELECT',
  9      audit_trail     => DBMS_FGA.DB + DBMS_FGA.EXTENDED);
 10  END;
 11  /

PL/SQL procedure successfully completed.

PQ3_SEC@orcl> conn pq3_agent1/pq3_agent1
Connected.
PQ3_AGENT1@orcl> SET ROLE pq3_vip_role;

Role set.

PQ3_AGENT1@orcl> SELECT cust_id, name FROM pq3_own.customers WHERE credit_limit >= 30000000 ORDER BY 1;

   CUST_ID NAME
---------- ------------------------------
       201 김민지
       204 최다은

2 rows selected.

PQ3_AGENT1@orcl> SELECT cust_id, name, grade FROM pq3_own.customers ORDER BY 1;

   CUST_ID NAME                           GRA
---------- ------------------------------ ---
       201 김민지                         VIP
       202 이준호                         GEN
       203 박소라                         GEN
       204 최다은                         VIP

4 rows selected.

PQ3_AGENT1@orcl> conn pq3_agent2/pq3_agent2
Connected.
PQ3_AGENT2@orcl> SELECT name, credit_limit FROM pq3_own.customers ORDER BY 1;

NAME                           CREDIT_LIMIT
------------------------------ ------------
강유리                              2483111
윤석                                7560105

2 rows selected.

PQ3_AGENT2@orcl> conn pq3_sup/pq3_sup
Connected.
PQ3_SUP@orcl> SELECT region, SUM(credit_limit) FROM pq3_own.customers GROUP BY region ORDER BY 1;

REGION     SUM(CREDIT_LIMIT)
---------- -----------------
BUSAN               51000000
SEOUL               87000000

2 rows selected.

PQ3_SUP@orcl> conn / as sysdba
Connected.
SYS@orcl> COL db_user FOR A10
SYS@orcl> COL sql_text FOR A66
SYS@orcl> SELECT db_user, sql_text FROM dba_fga_audit_trail
  2   WHERE policy_name = 'PQ3_FGA_LIMIT'
  3     AND timestamp >= (SELECT created FROM dba_users WHERE username = 'PQ3_SEC')
  4   ORDER BY timestamp;

DB_USER    SQL_TEXT
---------- ------------------------------------------------------------------
PQ3_SUP    SELECT region, SUM(credit_limit) FROM pq3_own.customers GROUP BY r
           egion ORDER BY 1

PQ3_AGENT1 SELECT cust_id, name FROM pq3_own.customers WHERE credit_limit >=
           30000000 ORDER BY 1

2 rows selected.

```

- CREDIT_LIMIT 가 WHERE 절에만 있는 PQ3_AGENT1 의 질의도 감사됐다. FGA 의 audit_column 은 문장 어디에서든 그 열을 참조하면 대상이 된다. 4단계에서 본 추측 시도가 그대로 기록에 남는다.
- PQ3_AGENT2 는 CREDIT_LIMIT 를 조회했지만 VPD 로 VIP 행이 빠져 audit_condition 이 참인 행이 없어 기록되지 않았다.
- PQ3_SUP 의 지역별 합계는 VIP 행을 포함해 감사됐다. 감독자의 정상 업무도 기록되므로 분석할 때 사용자별로 나눠 본다.

### [6] Resource Manager — 예상 실행 시간 제한
```text
SQL> conn pq3_sec/pq3_sec
Connected.
PQ3_SEC@orcl> BEGIN
  2    DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
  3    DBMS_RESOURCE_MANAGER.CREATE_CONSUMER_GROUP('PQ3_AGENT', 'call center agents');
  4    DBMS_RESOURCE_MANAGER.CREATE_CONSUMER_GROUP('PQ3_SUP',   'supervisors');
  5    DBMS_RESOURCE_MANAGER.CREATE_PLAN('PQ3_PLAN', 'call center');
  6    DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
  7      plan => 'PQ3_PLAN', group_or_subplan => 'PQ3_AGENT', comment => 'agents',
  8      mgmt_p1 => 50, max_est_exec_time => 5);
  9    DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
 10      plan => 'PQ3_PLAN', group_or_subplan => 'PQ3_SUP', comment => 'supervisors',
 11      mgmt_p1 => 40);
 12    DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
 13      plan => 'PQ3_PLAN', group_or_subplan => 'OTHER_GROUPS', comment => 'others',
 14      mgmt_p1 => 10);
 15    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 16      DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ3_AGENT1', 'PQ3_AGENT');
 17    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 18      DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ3_AGENT2', 'PQ3_AGENT');
 19    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
 20      DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ3_SUP',    'PQ3_SUP');
 21    DBMS_RESOURCE_MANAGER.VALIDATE_PENDING_AREA;
 22    DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA;
 23    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ3_AGENT1', 'PQ3_AGENT', FALSE);
 24    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ3_AGENT2', 'PQ3_AGENT', FALSE);
 25    DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP('PQ3_SUP',    'PQ3_SUP',   FALSE);
 26  END;
 27  /

PL/SQL procedure successfully completed.

PQ3_SEC@orcl> conn / as sysdba
Connected.
SYS@orcl> ALTER SYSTEM SET resource_manager_plan = 'PQ3_PLAN';

System altered.

SYS@orcl> conn pq3_agent1/pq3_agent1
Connected.
PQ3_AGENT1@orcl> SELECT COUNT(*) FROM pq3_own.customers;

  COUNT(*)
----------
         2

1 row selected.

PQ3_AGENT1@orcl> SELECT COUNT(*) FROM all_objects a, all_objects b, all_objects c;
SELECT COUNT(*) FROM all_objects a, all_objects b, all_objects c
                     *
ERROR at line 1:
ORA-07455: estimated execution time (310267 secs), exceeds limit (5 secs)

PQ3_AGENT1@orcl> SELECT COUNT(*) FROM all_objects a, all_objects b WHERE a.object_id = b.object_id;

  COUNT(*)
----------
     54984

1 row selected.

```

- MAX_EST_EXEC_TIME 은 실행 전에 옵티마이저의 예상 시간을 보고 거부한다. ORA-07455 메시지에 예상치(310267초)와 한도가 함께 나온다. CPU 를 쓰기 전에 막으므로 문제 1의 CANCEL_SQL 보다 비용이 적다.
- 같은 뷰를 쓰는 동등 조인은 예상 시간이 짧아 그대로 실행된다. 예상은 통계에 기대므로 통계가 오래되면 큰 질의가 통과하거나 작은 질의가 막힐 수 있다.

### [7] 감사 이벤트 만들기
```text
SQL> conn pq3_agent2/wrongpw
ERROR:
ORA-01017: invalid username/password; logon denied

SQL> conn pq3_agent1/pq3_agent1
Connected.
PQ3_AGENT1@orcl> SET ROLE pq3_vip_role;

Role set.

PQ3_AGENT1@orcl> SET ROLE NONE;

Role set.

```

### [8] 분리된 syslog 파일 확인 (root)
```text
[root@oel7v9 ~]# grep -c 'DBUSER:"PQ3_' /var/log/oracle_pq3.log
9
[root@oel7v9 ~]# cat /var/log/oracle_pq3.log | sed 's/^.*Oracle Unified Audit/Oracle Unified Audit/'
Oracle Unified Audit[24703]: LENGTH: '171' TYPE:"4" DBID:"1767674490" SESID:"238534735" CLIENTID:"" ENTRYID:"1" STMTID:"8" DBUSER:"PQ3_SEC" CURUSER:"PQ3_SEC" ACTION:"47" RETCODE:"0" SCHEMA:"SYS" OBJNAME:"DBMS_RLS"
Oracle Unified Audit[24705]: LENGTH: '166' TYPE:"4" DBID:"1767674490" SESID:"108819308" CLIENTID:"" ENTRYID:"1" STMTID:"8" DBUSER:"PQ3_AGENT1" CURUSER:"PQ3_AGENT1" ACTION:"55" RETCODE:"0" SCHEMA:"" OBJNAME:""
Oracle Unified Audit[24706]: LENGTH: '170' TYPE:"4" DBID:"1767674490" SESID:"4088451647" CLIENTID:"" ENTRYID:"1" STMTID:"8" DBUSER:"PQ3_AGENT2" CURUSER:"PQ3_AGENT2" ACTION:"55" RETCODE:"1924" SCHEMA:"" OBJNAME:""
Oracle Unified Audit[24802]: LENGTH: '167' TYPE:"4" DBID:"1767674490" SESID:"2764725212" CLIENTID:"" ENTRYID:"1" STMTID:"7" DBUSER:"PQ3_AGENT1" CURUSER:"PQ3_AGENT1" ACTION:"55" RETCODE:"0" SCHEMA:"" OBJNAME:""
Oracle Unified Audit[24901]: LENGTH: '172' TYPE:"4" DBID:"1767674490" SESID:"3843485521" CLIENTID:"" ENTRYID:"1" STMTID:"7" DBUSER:"PQ3_SEC" CURUSER:"PQ3_SEC" ACTION:"47" RETCODE:"0" SCHEMA:"SYS" OBJNAME:"DBMS_FGA"
Oracle Unified Audit[24903]: LENGTH: '167' TYPE:"4" DBID:"1767674490" SESID:"3745271767" CLIENTID:"" ENTRYID:"1" STMTID:"7" DBUSER:"PQ3_AGENT1" CURUSER:"PQ3_AGENT1" ACTION:"55" RETCODE:"0" SCHEMA:"" OBJNAME:""
Oracle Unified Audit[25095]: LENGTH: '171' TYPE:"4" DBID:"1767674490" SESID:"1892119935" CLIENTID:"" ENTRYID:"1" STMTID:"1" DBUSER:"PQ3_AGENT2" CURUSER:"PQ3_AGENT2" ACTION:"100" RETCODE:"1017" SCHEMA:"" OBJNAME:""
Oracle Unified Audit[25098]: LENGTH: '166' TYPE:"4" DBID:"1767674490" SESID:"951919434" CLIENTID:"" ENTRYID:"1" STMTID:"7" DBUSER:"PQ3_AGENT1" CURUSER:"PQ3_AGENT1" ACTION:"55" RETCODE:"0" SCHEMA:"" OBJNAME:""
Oracle Unified Audit[25098]: LENGTH: '166' TYPE:"4" DBID:"1767674490" SESID:"951919434" CLIENTID:"" ENTRYID:"2" STMTID:"8" DBUSER:"PQ3_AGENT1" CURUSER:"PQ3_AGENT1" ACTION:"55" RETCODE:"0" SCHEMA:"" OBJNAME:""
[root@oel7v9 ~]# grep -c 'DBUSER:"PQ3_' /var/log/oracle_audit.log
9
```

- PQ3 계정의 통합 감사 기록 9건이 oracle_pq3.log 와 oracle_audit.log 에 똑같이 들어갔다.
- ACTION 55 는 SET ROLE, 100 은 LOGON 이다. RETCODE 1924 는 3단계의 역할 없는 SET ROLE, 1017 은 로그인 실패다. 실패한 시도도 같은 파일에 남는다.
- PQ3_SEC 의 DBMS_RLS·DBMS_FGA 실행도 DBUSER 가 PQ3_ 라 함께 모였다.

### [9] 통합 감사 기록과 대조 (SYS)
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> EXEC DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL

PL/SQL procedure successfully completed.

SYS@orcl> COL dbusername FOR A10
SYS@orcl> COL action_name FOR A10
SYS@orcl> COL policies FOR A20
SYS@orcl> SELECT dbusername, action_name, return_code, unified_audit_policies policies
  2    FROM unified_audit_trail
  3   WHERE dbusername LIKE 'PQ3%'
  4     AND event_timestamp >= (SELECT created FROM dba_users WHERE username = 'PQ3_SEC')
  5   ORDER BY event_timestamp;

DBUSERNAME ACTION_NAM RETURN_CODE POLICIES
---------- ---------- ----------- --------------------
PQ3_SEC    EXECUTE              0 ORA_SECURECONFIG
PQ3_AGENT1 SET ROLE             0 ORA_SECURECONFIG, PQ
                                  3_ROLE_AUP

PQ3_AGENT2 SET ROLE          1924 ORA_SECURECONFIG, PQ
                                  3_ROLE_AUP

PQ3_AGENT1 SET ROLE             0 ORA_SECURECONFIG, PQ
                                  3_ROLE_AUP

PQ3_SEC    EXECUTE              0
PQ3_AGENT1 SET ROLE             0 ORA_SECURECONFIG, PQ
                                  3_ROLE_AUP

PQ3_AGENT2 LOGON             1017 ORA_LOGON_FAILURES
PQ3_AGENT1 SET ROLE             0 ORA_SECURECONFIG, PQ
                                  3_ROLE_AUP

PQ3_AGENT1 SET ROLE             0 ORA_SECURECONFIG, PQ
                                  3_ROLE_AUP

9 rows selected.

```

- syslog 9건과 UNIFIED_AUDIT_TRAIL 9건이 맞는다.
- PQ3_SEC 의 DBMS_RLS 실행은 ORA_SECURECONFIG 로 잡혔다. DBMS_FGA 실행은 정책 이름이 비어 있는데, 통합 감사가 FGA 설정 변경을 정책과 상관없이 의무적으로 기록하기 때문이다.

### [10] 정리 (SYS, PQ3_SEC)
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> ALTER SYSTEM SET resource_manager_plan = '';

System altered.

SYS@orcl> conn pq3_sec/pq3_sec
Connected.
PQ3_SEC@orcl> BEGIN
  2    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ3_AGENT1', 'PQ3_AGENT');
  3    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ3_AGENT2', 'PQ3_AGENT');
  4    DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP('PQ3_SUP',    'PQ3_SUP');
  5    DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
  6    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ3_AGENT1', NULL);
  7    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ3_AGENT2', NULL);
  8    DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(DBMS_RESOURCE_MANAGER.ORACLE_USER, 'PQ3_SUP',    NULL);
  9    DBMS_RESOURCE_MANAGER.DELETE_PLAN_CASCADE('PQ3_PLAN');
 10    DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA;
 11  END;
 12  /

PL/SQL procedure successfully completed.

PQ3_SEC@orcl> conn / as sysdba
Connected.
SYS@orcl> NOAUDIT POLICY pq3_role_aup BY pq3_agent1, pq3_agent2, pq3_sup;

Noaudit succeeded.

SYS@orcl> DROP AUDIT POLICY pq3_role_aup;

Audit Policy dropped.

SYS@orcl> DROP USER pq3_agent1 CASCADE;

User dropped.

SYS@orcl> DROP USER pq3_agent2 CASCADE;

User dropped.

SYS@orcl> DROP USER pq3_sup CASCADE;

User dropped.

SYS@orcl> DROP USER pq3_own CASCADE;

User dropped.

SYS@orcl> DROP USER pq3_sec CASCADE;

User dropped.

SYS@orcl> DROP ROLE pq3_vip_role;

Role dropped.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'PQ3%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_roles WHERE role LIKE 'PQ3%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_rsrc_consumer_groups WHERE consumer_group LIKE 'PQ3%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_rsrc_consumer_group_privs WHERE grantee LIKE 'PQ3%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM audit_unified_policies WHERE policy_name LIKE 'PQ3%';

  COUNT(*)
----------
         0

1 row selected.

```

### [11] rsyslog 규칙 제거 (root)
```text
[root@oel7v9 ~]# rm -f /etc/rsyslog.d/oracle_pq3.conf /var/log/oracle_pq3.log
[root@oel7v9 ~]# systemctl restart rsyslog
[root@oel7v9 ~]# systemctl is-active rsyslog
active
[root@oel7v9 ~]# ls /etc/rsyslog.d/
iscsid-rsyslog.conf
listen.conf
```

- 규칙 파일과 분리 로그만 지운다. /etc/rsyslog.d 에 원래 있던 파일은 그대로 남는다.

### 생각해 볼 점 — 답
- STATIC 정책은 함수가 돌려준 술어 문자열을 캐시할 뿐이다. 문자열 안의 SYS_CONTEXT 호출과 서브쿼리는 문장을 실행할 때마다 평가되므로 결과는 사용자와 역할을 따라간다. 함수 안에서 값을 읽어 리터럴로 이어 붙이면 처음 사용자의 값이 캐시돼 다른 사용자에게 그대로 적용된다.
- 술어 안의 서브쿼리는 상담원에게 AGENTS 권한이 없어도 동작했다. 대신 정책 설계자가 이 테이블을 사용자에게 따로 열어 줄 필요가 없고, 열어 주지 않는 편이 안전하다.
- Redaction 은 화면 값을 감출 뿐 검색·정렬로 실제 값이 새는 것을 막지 못한다(4단계). FGA 는 그런 추측 질의를 WHERE 절 참조까지 기록한다(5단계). 열 수준 VPD 로 막을 수 없는 업무라면 Redaction 으로 노출을 줄이고 FGA 로 오남용을 잡는 조합을 쓴다.

## 마무리 — 환경 원복

### [1] syslog 파라미터 원복과 재기동 (SYS)
```text
SQL> conn / as sysdba
Connected.
SYS@orcl> ALTER SYSTEM RESET audit_syslog_level SCOPE = SPFILE;

System altered.

SYS@orcl> ALTER SYSTEM RESET unified_audit_systemlog SCOPE = SPFILE;

System altered.

SYS@orcl> SHUTDOWN IMMEDIATE
Database closed.
Database dismounted.
ORACLE instance shut down.
SYS@orcl> STARTUP
ORACLE instance started.

Total System Global Area 2147481656 bytes
Fixed Size                  8898616 bytes
Variable Size            1509949440 bytes
Database Buffers          620756992 bytes
Redo Buffers                7876608 bytes
Database mounted.
Database opened.
SYS@orcl> SHOW PARAMETER audit_syslog_level

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
audit_syslog_level                   string
SYS@orcl> SHOW PARAMETER unified_audit_systemlog

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
unified_audit_systemlog              string
SYS@orcl> SHOW PARAMETER resource_manager_plan

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
resource_manager_plan                string
```

- 원래 값이 없던 파라미터는 `ALTER SYSTEM RESET` 으로 SPFILE 에서 항목을 지운다. `SET ... = ''` 은 빈 값을 명시적으로 남긴다.

### [2] rsyslog 원복 (root)
```text
[root@oel7v9 ~]# cp -p /etc/rsyslog.conf.bak_pq /etc/rsyslog.conf
[root@oel7v9 ~]# grep -n '^local' /etc/rsyslog.conf
73:local7.*                                                /var/log/boot.log
[root@oel7v9 ~]# systemctl restart rsyslog
[root@oel7v9 ~]# systemctl is-active rsyslog
active
[root@oel7v9 ~]# rm -f /etc/rsyslog.conf.bak_pq /var/log/oracle_audit.log
[root@oel7v9 ~]# md5sum /etc/rsyslog.conf
0dd94a0c285fb32f41fa5b226e83c26b  /etc/rsyslog.conf
```

- md5 가 실습 전 값(0dd94a0c…)과 같다. 실습 로그 파일과 백업 파일도 지웠다.
