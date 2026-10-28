@H1 Oracle 19c Security 1일 실습 트랜스크립트
@H2 과정 개요
@B 인증, 접근 통제, 데이터 보호, 암호화, 감사의 다섯 축을 하루 동안 실습 10개로 훑는다.
@B 대상은 SQL·PL/SQL·Database Administration 과정을 마친 학습자다. 사용자 생성, 권한 부여, 리스너 기동 같은 기본 작업은 설명 없이 진행한다.
@B 실습마다 앞에서 원리와 내부 동작을 정리하고, 뒤에 OEL7V9에서 실제로 실행한 스크립트와 출력을 싣는다.
@B 출력은 실측 그대로다. 같은 명령을 실행하면 시각, SID, 해시값, 인증서 일련번호 같은 값만 다르게 나온다.
@B 성공 흐름만 담지 않았다. 실습마다 의도된 오류를 하나 이상 일으키고 그 원인을 딕셔너리 뷰나 트레이스로 확인한다. 실무에서 먼저 만나는 것은 대개 오류 쪽이다.

@H2 시간표
@TBL
시간 | 실습 | 주제 | 축
09:00~09:30 | 01 | 지갑으로 배치 스크립트의 비밀번호 없애기 (SEPS) | 인증
09:30~10:00 | 02 | 프록시 인증과 실제 사용자 추적 | 인증
10:10~10:40 | 03 | Secure Application Role로 역할 활성화 통제 | 권한
10:40~11:10 | 04 | 네트워크 ACL로 외부 호출 통제 | 권한
11:20~12:10 | 05 | Application Context와 VPD로 행·컬럼 통제 | 접근 통제
13:10~13:50 | 06 | Data Redaction으로 조회 결과 가리기 | 데이터 보호
13:50~14:30 | 07 | DBMS_CRYPTO로 컬럼 암호화 패키지 만들기 | 암호화
14:40~15:30 | 08 | TDE 키스토어와 테이블스페이스 암호화 | 암호화
15:40~16:40 | 09 | TLS로 접속 구간 암호화와 인증서 로그인 | 암호화
16:50~17:40 | 10 | FGA·통합 감사와 감사 기록 관리 | 감사
@END

@H2 실습 환경
@TBL
항목 | 값
서버 | OEL7V9 (Oracle Linux 7.9, 172.16.225.50)
DB | Oracle Database 19.3 Enterprise Edition, non-CDB, SID orcl, ARCHIVELOG
감사 모드 | 혼합 모드(mixed). `audit_trail=DB`, 통합 감사 정책 ORA_SECURECONFIG·ORA_LOGON_FAILURES 활성
샘플 스키마 | HR(비밀번호 hr), SCOTT(비밀번호 tiger)
OS 계정 | oracle(DB 소유자), root(09 실습의 일부 확인용)
실습 08 | DBCA로 만든 임시 DB d08tde. 키스토어가 한 번도 없던 DB에서 시작해야 흐름이 맞기 때문이다
@END
@B 프롬프트는 `사용자@접속식별자>` 형식이다. `SYS@orcl>`은 `sqlplus / as sysdba`, `HR@orcl>`은 HR 로컬 접속을 뜻한다.
@B 셸 프롬프트 `[oracle@oel7v9 디렉터리]$`는 oracle OS 계정이다.
@B 실습끼리는 서로 의존하지 않는다. 각 실습은 시작할 때 필요한 객체를 만들고, 끝날 때 모두 지운 다음 지워졌는지 조회로 확인한다. 순서를 바꾸거나 일부만 골라 진행해도 된다.
@B 객체 이름에는 실습 번호 접두사(`D01_`~`D10_`, 사용자는 `d01_app` 식)를 붙였다. 다른 실습이나 기존 객체와 겹치지 않게 하기 위해서다.

@NOTE 실습 전 공통 확인
공용 네트워크 설정 파일(`$ORACLE_HOME/network/admin`의 sqlnet.ora·listener.ora·tnsnames.ora)은 실습 전에 백업한다. 01·09 실습의 클라이언트 설정은 실습 전용 TNS_ADMIN 디렉터리에 두므로 공용 파일을 바꾸지 않는다. 09 실습은 listener.ora에 별도 리스너 항목을 넣었다가 끝에서 되돌린다.
@END

@P 백업 명령 (출력 없음)
@CODE
cd $ORACLE_HOME/network/admin
for f in sqlnet listener tnsnames; do cp -p $f.ora $f.ora.bak_day1; done
@END
@H2 실습 01  지갑으로 배치 스크립트의 비밀번호 없애기 (SEPS)
@TBL
항목 | 내용
목표 | 배치 계정의 비밀번호를 스크립트에서 지우고 Secure External Password Store로 접속한다. 비밀번호 변경·크론 환경·감사 기록까지 운영 흐름으로 확인한다
소요 | 30분
접속 | oracle OS 계정 셸, SYS(/ AS SYSDBA)
변경 | 사용자 D01_BATCH, 디렉터리 /home/oracle/d01(지갑·전용 TNS_ADMIN). 마지막 단계에서 모두 지움
@END

@H3 01.1  실습 전에 — 접속 문자열과 자격 증명을 지갑에 묶는 구조
@B 배치·크론 스크립트에 `user/password@db`를 적으면 비밀번호는 스크립트 파일, 형상 관리 저장소, 백업 사본 어디서나 평문으로 읽힌다.
@B 19.3의 sqlplus는 기동 직후 명령행 인자의 자격 증명을 공백으로 덮어써서 `ps` 출력에서는 가려진다(실습 [2]). 덮어쓰기 전의 짧은 순간과 파일에 남은 평문은 막지 못한다.
@B Secure External Password Store(SEPS)는 접속 문자열과 사용자·비밀번호 쌍을 Oracle 지갑에 저장한다. 클라이언트가 `/@별칭`으로 접속하면 지갑에서 같은 이름의 자격 증명을 꺼내 일반 비밀번호 인증을 한다.
@B DB 쪽에서는 평범한 비밀번호 로그인이다. `AUTHENTICATION_METHOD`는 PASSWORD로 보이고 프로파일 규칙도 그대로 적용된다.
@B 구성 요소는 세 가지다.
@B 지갑: `ewallet.p12`와 자동 로그인 파일 `cwallet.sso`. `mkstore -create`는 둘을 함께 만든다.
@B `sqlnet.ora`: `WALLET_LOCATION`과 `SQLNET.WALLET_OVERRIDE = TRUE`. OVERRIDE가 없으면 지갑을 읽지 않고 빈 자격 증명으로 로그인을 시도한다.
@B `tnsnames.ora`: 별칭 이름이 지갑의 connect_string과 글자까지 같아야 한다.
@B `cwallet.sso`는 비밀번호 없이 열린다. 실질적인 보호 수단은 지갑 디렉터리의 소유자와 700 권한이다. 지갑 비밀번호는 자격 증명을 추가·수정·조회할 때만 쓰인다.
@B 지갑 비밀번호는 8자 이상이고 영문에 숫자나 특수문자가 섞여야 한다. 어기면 PKI-01002가 난다.
@B DB 비밀번호 변경과 `-modifyCredential`은 한 작업으로 묶는다. 지갑만 낡으면 배치가 ORA-01017을 되풀이하고, `FAILED_LOGIN_ATTEMPTS`에 걸려 계정이 잠길 수 있다.
@B 크론은 로그인 셸의 환경 변수를 읽지 않는다. 공용 `$ORACLE_HOME/network/admin`을 고치지 않고 배치 전용 `TNS_ADMIN`을 스크립트 안에서 지정하면 다른 접속에 영향이 없다.
@B 자격 증명 하나는 접속 문자열·사용자·비밀번호 세 값이다. 같은 DB라도 별칭을 달리하면 여러 계정을 한 지갑에 넣는다. 이미 있는 접속 문자열로 다시 등록하면 `Credential already exists`로 거부된다(교안 1장 실습 03).
@B `/@별칭` 형식은 sqlplus 전용이 아니다. `expdp /@별칭`처럼 OCI 기반 도구는 같은 방식으로 지갑을 쓴다(교안 1장 실습 04). 문서상 `AS SYSDBA`를 붙인 관리 접속도 된다.
@B 지갑은 클라이언트 쪽 파일이라 DB는 지갑을 썼는지 모른다. 확인할 딕셔너리 뷰가 없으므로 진단은 `mkstore -listCredential`, 별칭 해석(`tnsping`), 클라이언트 트레이스로 한다.
@NOTE 지갑 파일의 이동
`mkstore -create`로 만든 자동 로그인 지갑은 다른 서버나 다른 OS 사용자에게 복사해도 열린다. `orapki wallet create -auto_login_local`로 만든 지갑은 만든 호스트와 사용자에서만 열린다. 다른 OS 사용자에게 복사하면 ORA-12578로 실패한다(교안 1장 실습 05).
@END

@H3 01.2  진행 순서
@TBL
단계 | 주제 | 하는 일 | 확인할 것
[1] | 계정 준비 | D01_BATCH 생성 | CREATED 날짜
[2] | 평문 비밀번호 문제 | 비밀번호가 든 배치 스크립트 실행 | ps에는 가려지지만 파일에는 평문
[3] | 지갑 생성 | 약한 비밀번호 → 다시 생성, 자격 증명 등록 | PKI-01002, -listCredential
[4~5] | 전용 TNS_ADMIN | OVERRIDE 없이 → 추가 후 접속 | ORA-01017 → PASSWORD 인증
[6~7] | 비밀번호 변경 | DB만 변경 → 지갑 갱신 | ORA-01017 → 접속 성공
[8] | 크론 환경 | env -i 로 환경 없이 실행 | ORA-12154와 TNS_ADMIN 지정
[9] | 감사 | 실패 로그인 기록 조회 | DBUSERNAME 이 비는 경우
[10] | 원복 | 계정·디렉터리 삭제 | 0건
@END

@H3 01.3  실습 스크립트

@P [1] 배치 계정 준비
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d01_batch IDENTIFIED BY "Batch#2026";

User created.

SYS@orcl> GRANT CREATE SESSION TO d01_batch;

Grant succeeded.

SYS@orcl> COL username FOR a10
SYS@orcl> SELECT username, account_status, created FROM dba_users WHERE username = 'D01_BATCH';

USERNAME   ACCOUNT_STATUS                   CREATED
---------- -------------------------------- ----------
D01_BATCH  OPEN                             2026-10-28

1 row selected.
@END

@P [2] 배치 스크립트에 박힌 비밀번호
@CODE
-- ★ 배치 스크립트가 비밀번호를 품은 상태를 재현한다.
[oracle@oel7v9 ~]$ mkdir -p /home/oracle/d01/wallet /home/oracle/d01/tns
[oracle@oel7v9 ~]$ chmod 700 /home/oracle/d01
[oracle@oel7v9 ~]$ printf 'EXEC DBMS_SESSION.SLEEP(5)\nEXIT\n' > /home/oracle/d01/sleep.sql
[oracle@oel7v9 ~]$ printf '%s\n' 'sqlplus -s -L d01_batch/Batch#2026@//oel7v9:1521/orcl @/home/oracle/d01/sleep.sql' > /home/oracle/d01/job.sh
[oracle@oel7v9 ~]$ cat /home/oracle/d01/job.sh
sqlplus -s -L d01_batch/Batch#2026@//oel7v9:1521/orcl @/home/oracle/d01/sleep.sql
[oracle@oel7v9 ~]$ bash /home/oracle/d01/job.sh > /dev/null 2>&1 < /dev/null &
[oracle@oel7v9 ~]$ sleep 2
[oracle@oel7v9 ~]$ ps -ef | grep '[s]leep.sql' | cut -c49-
sqlplus -s -L                                         @/home/oracle/d01/sleep.sql
[oracle@oel7v9 ~]$ sleep 5
-- ★ ps 출력에서 사용자/비밀번호 자리가 공백으로 바뀌었다. sqlplus가 기동 직후 인자를 덮어쓴 결과다.
-- ★ 파일 job.sh 에는 평문이 그대로 남는다. 스크립트를 읽을 수 있는 계정이면 누구나 본다.
@END

@P [3] 지갑 만들기와 자격 증명 등록
@CODE
[oracle@oel7v9 ~]$ printf 'oracle\noracle\n' | mkstore -wrl /home/oracle/d01/wallet -create
Oracle Secret Store Tool Release 19.0.0.0.0 - Production
Version 19.3.0.0.0
Copyright (c) 2004, 2019, Oracle and/or its affiliates. All rights reserved.

Enter password:   
PKI-01002: Invalid password. Passwords must have a minimum length of eight characters and contain alphabetic characters combined with numbers or special characters. 
Enter password:   
PKI-01002: Invalid password. Passwords must have a minimum length of eight characters and contain alphabetic characters combined with numbers or special characters. 
[oracle@oel7v9 ~]$ printf 'Wallet#2026\nWallet#2026\n' | mkstore -wrl /home/oracle/d01/wallet -create
Oracle Secret Store Tool Release 19.0.0.0.0 - Production
Version 19.3.0.0.0
Copyright (c) 2004, 2019, Oracle and/or its affiliates. All rights reserved.

Enter password:   
Enter password again:   
[oracle@oel7v9 ~]$ printf 'Batch#2026\nBatch#2026\nWallet#2026\n' | mkstore -wrl /home/oracle/d01/wallet -createCredential d01_batch d01_batch
Oracle Secret Store Tool Release 19.0.0.0.0 - Production
Version 19.3.0.0.0
Copyright (c) 2004, 2019, Oracle and/or its affiliates. All rights reserved.

Your secret/Password is missing in the command line 
Enter your secret/Password:   
Re-enter your secret/Password:   
Enter wallet password:   
[oracle@oel7v9 ~]$ printf 'Wallet#2026\n' | mkstore -wrl /home/oracle/d01/wallet -listCredential
Oracle Secret Store Tool Release 19.0.0.0.0 - Production
Version 19.3.0.0.0
Copyright (c) 2004, 2019, Oracle and/or its affiliates. All rights reserved.

Enter wallet password:   
List credential (index: connect_string username)
1: d01_batch d01_batch
[oracle@oel7v9 ~]$ ls -l /home/oracle/d01/wallet
total 8
-rw-------. 1 oracle dba 589 Oct 28 08:45 cwallet.sso
-rw-------. 1 oracle dba   0 Oct 28 08:45 cwallet.sso.lck
-rw-------. 1 oracle dba 544 Oct 28 08:45 ewallet.p12
-rw-------. 1 oracle dba   0 Oct 28 08:45 ewallet.p12.lck
-- ★ 첫 시도는 PKI-01002로 거부된다. 'oracle'은 길이와 조합 규칙을 모두 어긴다.
-- ★ -create 한 번으로 ewallet.p12와 cwallet.sso가 함께 생긴다. .lck 파일은 잠금용이다.
-- ★ createCredential 의 첫 인자 d01_batch 가 접속 문자열이고, 두 번째가 DB 사용자다.
@END

@P [4] 전용 TNS_ADMIN — WALLET_OVERRIDE 없이
@CODE
-- ★ 공용 설정을 건드리지 않도록 /home/oracle/d01/tns 를 TNS_ADMIN 으로 쓴다.
[oracle@oel7v9 ~]$ cd /home/oracle/d01/tns
[oracle@oel7v9 tns]$ printf '%s\n' 'WALLET_LOCATION =' '  (SOURCE = (METHOD = FILE)' '    (METHOD_DATA = (DIRECTORY = /home/oracle/d01/wallet)))' > sqlnet.ora
[oracle@oel7v9 tns]$ printf '%s\n' 'D01_BATCH =' '  (DESCRIPTION =' '    (ADDRESS = (PROTOCOL = TCP)(HOST = oel7v9)(PORT = 1521))' '    (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = orcl)))' > tnsnames.ora
[oracle@oel7v9 tns]$ cat sqlnet.ora
WALLET_LOCATION =
  (SOURCE = (METHOD = FILE)
    (METHOD_DATA = (DIRECTORY = /home/oracle/d01/wallet)))
[oracle@oel7v9 tns]$ export TNS_ADMIN=/home/oracle/d01/tns
[oracle@oel7v9 tns]$ echo 'SHOW USER' | sqlplus -s -L /@d01_batch
ERROR:
ORA-01017: invalid username/password; logon denied


SP2-0751: Unable to connect to Oracle.  Exiting SQL*Plus
-- ★ WALLET_OVERRIDE 가 없으면 지갑을 쓰지 않는다. 빈 자격 증명으로 로그인해 ORA-01017이 난다.
@END

@P [5] WALLET_OVERRIDE 추가
@CODE
[oracle@oel7v9 ~]$ cd /home/oracle/d01/tns
[oracle@oel7v9 tns]$ echo 'SQLNET.WALLET_OVERRIDE = TRUE' >> sqlnet.ora
[oracle@oel7v9 tns]$ export TNS_ADMIN=/home/oracle/d01/tns
[oracle@oel7v9 tns]$ printf '%s\n' 'COL usr FOR a10' 'COL auth FOR a10' "SELECT SUBSTR(SYS_CONTEXT('USERENV','SESSION_USER'),1,10) usr, SUBSTR(SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD'),1,10) auth FROM dual;" | sqlplus -s -L /@d01_batch

USR	   AUTH
---------- ----------
D01_BATCH  PASSWORD
-- ★ OVERRIDE 한 줄로 접속된다. DB 입장에서는 PASSWORD 인증이다.
@END

@P [6] DB 비밀번호 변경
@CODE
-- ★ 운영에서 흔한 실수: DBA가 비밀번호만 바꾸고 지갑은 그대로 둔다.
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> ALTER USER d01_batch IDENTIFIED BY "Batch#2027";

User altered.
@END

@P [7] 지갑이 낡았을 때와 갱신
@CODE
[oracle@oel7v9 ~]$ export TNS_ADMIN=/home/oracle/d01/tns
[oracle@oel7v9 ~]$ echo 'SHOW USER' | sqlplus -s -L /@d01_batch
ERROR:
ORA-01017: invalid username/password; logon denied


SP2-0751: Unable to connect to Oracle.  Exiting SQL*Plus
[oracle@oel7v9 ~]$ printf 'Batch#2027\nBatch#2027\nWallet#2026\n' | mkstore -wrl /home/oracle/d01/wallet -modifyCredential d01_batch d01_batch
Oracle Secret Store Tool Release 19.0.0.0.0 - Production
Version 19.3.0.0.0
Copyright (c) 2004, 2019, Oracle and/or its affiliates. All rights reserved.

Your secret/Password is missing in the command line 
Enter your secret/Password:   
Re-enter your secret/Password:   
Enter wallet password:   
[oracle@oel7v9 ~]$ echo 'SHOW USER' | sqlplus -s -L /@d01_batch
USER is "D01_BATCH"
-- ★ 지갑의 옛 비밀번호로 ORA-01017이 난다. -modifyCredential 로 고치면 스크립트 변경 없이 복구된다.
@END

@P [8] 크론처럼 빈 환경에서
@CODE
[oracle@oel7v9 ~]$ env -i HOME=/home/oracle ORACLE_HOME=$ORACLE_HOME PATH=$ORACLE_HOME/bin:/usr/bin:/bin bash -c "echo 'SHOW USER' | sqlplus -s -L /@d01_batch"
ERROR:
ORA-12154: TNS:could not resolve the connect identifier specified


SP2-0751: Unable to connect to Oracle.  Exiting SQL*Plus
[oracle@oel7v9 ~]$ env -i HOME=/home/oracle ORACLE_HOME=$ORACLE_HOME PATH=$ORACLE_HOME/bin:/usr/bin:/bin TNS_ADMIN=/home/oracle/d01/tns bash -c "echo 'SHOW USER' | sqlplus -s -L /@d01_batch"
USER is "D01_BATCH"
-- ★ env -i 는 크론처럼 환경 변수가 거의 없는 상태다. TNS_ADMIN 이 없으면 공용 tnsnames.ora 를 읽어 별칭을 못 찾는다(ORA-12154).
-- ★ 크론 스크립트 첫머리에 TNS_ADMIN 을 export 한다.
@END

@P [9] 실패 로그인은 어떻게 남나
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> EXEC DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL

PL/SQL procedure successfully completed.

SYS@orcl> COL t FOR a8
SYS@orcl> COL dbusername FOR a10
SYS@orcl> COL os_username FOR a8
SYS@orcl> COL action_name FOR a8
SYS@orcl> SELECT TO_CHAR(event_timestamp, 'HH24:MI:SS') t, NVL(dbusername, '(null)') dbusername,
  2         os_username, action_name, return_code
  3    FROM unified_audit_trail
  4   WHERE action_name = 'LOGON'
  5     AND event_timestamp >= (SELECT created FROM dba_users WHERE username = 'D01_BATCH')
  6     AND (dbusername = 'D01_BATCH' OR return_code <> 0)
  7   ORDER BY event_timestamp;

T        DBUSERNAME OS_USERN ACTION_N RETURN_CODE
-------- ---------- -------- -------- -----------
08:46:01 (null)     oracle   LOGON           1017
08:46:06 D01_BATCH  oracle   LOGON           1017

2 rows selected.
-- ★ 첫 행은 [4]의 OVERRIDE 없는 시도다. 지갑을 읽지 않아 사용자 이름 없이 기록됐다.
-- ★ 두 번째 행은 [7]의 낡은 지갑이다. 사용자 이름이 남는다.
-- ★ 같은 ORA-01017이라도 기록 모양이 달라서 원인 구분에 쓸 수 있다.
@END

@P [10] 원복
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> DROP USER d01_batch CASCADE;

User dropped.

SYS@orcl> HOST rm -rf /home/oracle/d01

SYS@orcl> SELECT COUNT(*) AS d01_users FROM dba_users WHERE username LIKE 'D01%';

 D01_USERS
----------
         0

1 row selected.

SYS@orcl> HOST ls -d /home/oracle/d01

SYS@orcl> EXIT

[stderr] ls: cannot access /home/oracle/d01: No such file or directory
-- ★ 계정 0건, 디렉터리 없음(ls 오류)으로 원복을 확인한다.
@END

@H3 01.4  정리와 확인 포인트
@B 19.3 sqlplus는 ps에서 자격 증명을 가린다. 실제 노출 경로는 파일, 저장소, 셸 히스토리이고, SEPS는 이 경로를 없앤다.
@B `/@별칭` 접속이 실패하면 OVERRIDE 여부, 별칭과 connect_string 일치, TNS_ADMIN 경로 순으로 본다. 앞의 두 원인은 모두 ORA-01017로 보인다.
@B 실패 로그인의 DBUSERNAME이 비어 있으면 지갑을 아예 읽지 못했다는 신호다.
@B 비밀번호 순환 절차서에는 `ALTER USER`와 `-modifyCredential`을 한 단계로 적고, 바로 `/@별칭` 접속 확인을 붙인다.
@B 지갑 디렉터리는 배치 계정만 읽게 한다. 이 권한이 사실상 비밀번호 보호 수준이다.
@H2 실습 02  프록시 인증과 실제 사용자 추적
@TBL
항목 | 내용
목표 | 중간 계정이 대상 사용자 세션을 대신 여는 프록시 인증을 구성하고, WITH ROLE 로 권한을 줄인 결과와 통합 감사의 실제 사용자 기록을 확인한다
소요 | 30분
접속 | SYS, D02_APP[D02_CLERK] 프록시 세션, D02_CLERK 직접 세션
변경 | 사용자 D02_OWNER·D02_APP·D02_CLERK, 역할 D02_R_READ·D02_R_WRITE, 감사 정책 D02_POL. 마지막 단계에서 모두 지움
@END

@H3 02.1  실습 전에 — 한 계정의 인증으로 다른 사용자의 세션을 연다
@B 응용 서버는 커넥션 풀 계정 하나로 접속한다. 그래도 권한 판정과 감사는 실제 업무 사용자 기준이어야 한다.
@B 프록시 인증에서는 중간 계정(D02_APP)이 자기 비밀번호로 인증한 뒤 대상 사용자(D02_CLERK)의 세션을 연다. 응용 서버는 대상 사용자의 비밀번호를 몰라도 된다.
@B 허용은 대상 사용자 쪽 속성이다.
@CODE
ALTER USER client GRANT CONNECT THROUGH proxy
  [WITH ROLE r1, r2 | WITH ROLE ALL EXCEPT r3 | WITH NO ROLES]
  [AUTHENTICATION REQUIRED];
@END
@B 확인은 `PROXY_USERS`(허용 관계와 FLAGS), `PROXY_ROLES`(WITH ROLE 목록)로 한다.
@B 허용 없이 `proxy[client]`로 접속하면 19.3에서는 ORA-28150이 아니라 ORA-01017이 난다(교안 1·2장 실측). 비밀번호 오류와 구분되지 않으므로 진단은 `PROXY_USERS` 조회가 먼저다.
@B WITH ROLE은 세션에서 켤 수 있는 역할만 제한한다. 나머지 역할을 `SET ROLE`로 켜려 하면 ORA-01924가 난다. 대상 사용자가 직접 받은 시스템·객체 권한은 그대로 남는다(Security Guide 프록시 계정 지침).
@B 세션 안에서는 `SESSION_USER`가 대상 사용자, `PROXY_USER`가 중간 계정이다. 통합 감사에는 `DBUSERNAME`과 `DBPROXY_USERNAME`으로 나뉘어 남는다.
@B SQL*Plus 문법은 `CONNECT proxy[client]/proxy_password`다. JDBC·OCI는 풀의 물리 연결 위에서 경량 프록시 세션을 여닫는다(문서 기준).
@B 권한 부족으로 실패한 DML은 화면에는 ORA-01031로 보인다. 통합 감사의 RETURN_CODE에는 2004로 남는다(실습 [7] 실측). 1031만 찾는 실패 감사 조회는 이 행을 놓친다.
@B 프록시 계정에는 CREATE SESSION만 주고 비밀번호를 강하게 둔다. 이 계정의 비밀번호가 곧 허용된 모든 대상 사용자의 세션 열쇠다.
@B `AUTHENTICATION REQUIRED`를 붙이면 프록시 계정이 대상 사용자의 비밀번호까지 제시해야 한다. 제시하지 않은 접속은 ORA-28150으로 거부된다(교안 2장 실습 03). 응용 서버가 사용자 비밀번호를 받는 구조에서만 쓴다.
@B 허용은 대상 사용자마다 따로 준다. 응용 서버 계정 하나에 CONNECT THROUGH가 수백 개 걸리면 `PROXY_USERS`가 곧 위임 목록이므로 정기 점검 대상이 된다.
@B 프록시 계정 자체에는 업무 권한을 주지 않는다. 실습에서 D02_APP의 권한은 CREATE SESSION뿐인데도 프록시 세션의 조회가 성공한다. 권한 판정은 대상 사용자 기준이다.
@B `SYS_CONTEXT('USERENV', 'PROXY_USER')`는 서버가 정하는 값이다. 응용 역할의 활성화 조건(실습 03)이나 VPD 정책 함수의 술어(실습 05)에 그대로 쓴다.

@H3 02.2  진행 순서
@TBL
단계 | 주제 | 하는 일 | 확인할 것
[1] | 준비 | 소유자·테이블, 프록시·대상 계정, 역할 2개 | 역할은 대상 사용자에게만
[2] | 허용 없이 접속 | proxy[client] 접속 | ORA-01017
[3] | WITH ROLE 허용 | CONNECT THROUGH ... WITH ROLE d02_r_read | PROXY_USERS·PROXY_ROLES
[4] | 프록시 세션 | SESSION_USER·PROXY_USER, 역할, DML | ORA-01031, ORA-01924
[5] | 감사 정책 | SELECT·INSERT·UPDATE 감사 | BY USER / ALL USERS
[6] | 같은 작업 비교 | 프록시 세션과 직접 접속에서 같은 SQL | 직접 접속은 UPDATE 성공
[7] | 감사 조회 | DBUSERNAME·DBPROXY_USERNAME | RETURN_CODE 2004
[8] | 원복 | 정책·사용자·역할 삭제 | 0건
@END

@H3 02.3  실습 스크립트

@P [1] 계정·역할·테이블 준비
@CODE
-- ★ 응용 테이블 소유자는 접속 권한이 없다. 읽기·쓰기 역할은 대상 사용자 D02_CLERK 에게만 준다.
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d02_owner IDENTIFIED BY Owner2026x QUOTA 10M ON users;

User created.

SYS@orcl> CREATE TABLE d02_owner.pay (emp_id NUMBER, amount NUMBER) TABLESPACE users;

Table created.

SYS@orcl> INSERT INTO d02_owner.pay VALUES (100, 5000);

1 row created.

SYS@orcl> INSERT INTO d02_owner.pay VALUES (101, 4200);

1 row created.

SYS@orcl> COMMIT;

Commit complete.

SYS@orcl> CREATE USER d02_app IDENTIFIED BY App2026x;

User created.

SYS@orcl> CREATE USER d02_clerk IDENTIFIED BY Clerk2026x;

User created.

SYS@orcl> GRANT CREATE SESSION TO d02_app, d02_clerk;

Grant succeeded.

SYS@orcl> CREATE ROLE d02_r_read;

Role created.

SYS@orcl> CREATE ROLE d02_r_write;

Role created.

SYS@orcl> GRANT SELECT ON d02_owner.pay TO d02_r_read;

Grant succeeded.

SYS@orcl> GRANT INSERT, UPDATE ON d02_owner.pay TO d02_r_write;

Grant succeeded.

SYS@orcl> GRANT d02_r_read, d02_r_write TO d02_clerk;

Grant succeeded.
@END

@P [2] CONNECT THROUGH 없이 프록시 접속
@CODE
SQL> CONNECT d02_app[d02_clerk]/App2026x
ERROR:
ORA-01017: invalid username/password; logon denied
-- ★ CONNECT THROUGH 허용이 없을 때 19.3은 ORA-01017을 돌려준다. 프록시 관계의 존재 여부를 드러내지 않는다.
@END

@P [3] WITH ROLE 로 프록시 허용
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> ALTER USER d02_clerk GRANT CONNECT THROUGH d02_app WITH ROLE d02_r_read;

User altered.

SYS@orcl> COL proxy FOR a8
SYS@orcl> COL client FOR a10
SYS@orcl> COL role FOR a10
SYS@orcl> SELECT proxy, client, authentication, flags FROM proxy_users WHERE proxy = 'D02_APP';

PROXY    CLIENT     AUT FLAGS
-------- ---------- --- -----------------------------------
D02_APP  D02_CLERK  NO  PROXY MAY ACTIVATE ROLE

1 row selected.

SYS@orcl> SELECT proxy, client, role FROM proxy_roles WHERE proxy = 'D02_APP';

PROXY    CLIENT     ROLE
-------- ---------- ----------
D02_APP  D02_CLERK  D02_R_READ

1 row selected.
-- ★ FLAGS 'PROXY MAY ACTIVATE ROLE': 프록시 세션은 WITH ROLE 목록의 역할만 켤 수 있다.
-- ★ AUTHENTICATION 이 NO 이므로 대상 사용자의 비밀번호는 묻지 않는다.
@END

@P [4] 프록시 세션에서 보이는 것
@CODE
-- ★ D02_APP 의 비밀번호로 D02_CLERK 세션이 열린다. 프롬프트도 대상 사용자로 바뀐다.
SQL> CONNECT d02_app[d02_clerk]/App2026x
Connected.
D02_CLERK@orcl> COL session_user FOR a10
D02_CLERK@orcl> COL proxy_user FOR a10
D02_CLERK@orcl> COL ident FOR a10
D02_CLERK@orcl> SELECT SYS_CONTEXT('USERENV', 'SESSION_USER') session_user,
  2         SYS_CONTEXT('USERENV', 'PROXY_USER') proxy_user,
  3         SYS_CONTEXT('USERENV', 'AUTHENTICATED_IDENTITY') ident
  4    FROM dual;

SESSION_US PROXY_USER IDENT
---------- ---------- ----------
D02_CLERK  D02_APP    D02_CLERK

1 row selected.

D02_CLERK@orcl> COL role FOR a12
D02_CLERK@orcl> SELECT role FROM session_roles;

ROLE
------------
D02_R_READ

1 row selected.

D02_CLERK@orcl> SELECT * FROM d02_owner.pay;

    EMP_ID     AMOUNT
---------- ----------
       100       5000
       101       4200

2 rows selected.

D02_CLERK@orcl> INSERT INTO d02_owner.pay VALUES (102, 3900);
INSERT INTO d02_owner.pay VALUES (102, 3900)
                      *
ERROR at line 1:
ORA-01031: insufficient privileges


D02_CLERK@orcl> SET ROLE d02_r_write;
SET ROLE d02_r_write
*
ERROR at line 1:
ORA-01924: role 'D02_R_WRITE' not granted or does not exist
-- ★ AUTHENTICATED_IDENTITY 는 D02_CLERK 로 나온다. 프록시 계정은 PROXY_USER 로 따로 보인다.
-- ★ SESSION_ROLES 에는 D02_R_READ 만 있다. 쓰기 역할은 받았어도 켜지지 않았다.
-- ★ INSERT 는 ORA-01031, 쓰기 역할을 켜려는 SET ROLE 은 ORA-01924 다.
@END

@P [5] 통합 감사 정책
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE AUDIT POLICY d02_pol
  2    ACTIONS SELECT ON d02_owner.pay, INSERT ON d02_owner.pay, UPDATE ON d02_owner.pay;

Audit policy created.

SYS@orcl> AUDIT POLICY d02_pol;

Audit succeeded.

SYS@orcl> COL policy_name FOR a10
SYS@orcl> COL entity_name FOR a10
SYS@orcl> SELECT policy_name, enabled_option, entity_name, success, failure
  2    FROM audit_unified_enabled_policies WHERE policy_name = 'D02_POL';

POLICY_NAM ENABLED_OPTION  ENTITY_NAM SUC FAI
---------- --------------- ---------- --- ---
D02_POL    BY USER         ALL USERS  YES YES

1 row selected.
-- ★ BY 절 없이 켰으므로 ENABLED_OPTION 은 BY USER, ENTITY_NAME 은 ALL USERS 다. 정책은 이후 세션의 대상 작업부터 기록한다.
@END

@P [6] 프록시와 직접 접속에서 같은 작업
@CODE
SQL> CONNECT d02_app[d02_clerk]/App2026x
Connected.
D02_CLERK@orcl> SELECT COUNT(*) FROM d02_owner.pay;

  COUNT(*)
----------
         2

1 row selected.

D02_CLERK@orcl> UPDATE d02_owner.pay SET amount = amount WHERE emp_id = 100;
UPDATE d02_owner.pay SET amount = amount WHERE emp_id = 100
                 *
ERROR at line 1:
ORA-01031: insufficient privileges


D02_CLERK@orcl> CONNECT d02_clerk/Clerk2026x
Connected.
D02_CLERK@orcl> SELECT COUNT(*) FROM d02_owner.pay;

  COUNT(*)
----------
         2

1 row selected.

D02_CLERK@orcl> UPDATE d02_owner.pay SET amount = amount WHERE emp_id = 100;

1 row updated.

D02_CLERK@orcl> ROLLBACK;

Rollback complete.
-- ★ 같은 사용자 D02_CLERK 인데 프록시 세션의 UPDATE 는 실패하고 직접 접속의 UPDATE 는 성공한다. 권한 차이는 접속 경로에서 나온다.
@END

@P [7] 감사 기록에서 실제 사용자 찾기
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> EXEC DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL

PL/SQL procedure successfully completed.

SYS@orcl> COL t FOR a8
SYS@orcl> COL dbusername FOR a10
SYS@orcl> COL dbproxy_username FOR a10
SYS@orcl> COL action_name FOR a7
SYS@orcl> SELECT TO_CHAR(event_timestamp, 'HH24:MI:SS') t, dbusername, dbproxy_username,
  2         action_name, return_code
  3    FROM unified_audit_trail
  4   WHERE unified_audit_policies LIKE '%D02_POL%'
  5   ORDER BY event_timestamp, action_name;

T        DBUSERNAME DBPROXY_US ACTION_ RETURN_CODE
-------- ---------- ---------- ------- -----------
08:46:30 D02_CLERK  D02_APP    SELECT            0
08:46:30 D02_CLERK  D02_APP    UPDATE         2004
08:46:30 D02_CLERK             SELECT            0
08:46:30 D02_CLERK             UPDATE            0
08:47:34 D02_CLERK  D02_APP    SELECT            0
08:47:34 D02_CLERK  D02_APP    UPDATE         2004
08:47:34 D02_CLERK             SELECT            0
08:47:34 D02_CLERK             UPDATE            0

8 rows selected.
-- ★ DBPROXY_USERNAME 이 채워진 두 행이 프록시 세션의 작업이다.
-- ★ 프록시 세션의 UPDATE 는 화면에서 ORA-01031이었지만 RETURN_CODE 는 2004 로 남았다.
-- ★ 직접 접속 행은 DBPROXY_USERNAME 이 비어 있다.
@END

@P [8] 원복
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> NOAUDIT POLICY d02_pol;

Noaudit succeeded.

SYS@orcl> DROP AUDIT POLICY d02_pol;

Audit Policy dropped.

SYS@orcl> DROP USER d02_app CASCADE;

User dropped.

SYS@orcl> DROP USER d02_clerk CASCADE;

User dropped.

SYS@orcl> DROP USER d02_owner CASCADE;

User dropped.

SYS@orcl> DROP ROLE d02_r_read;

Role dropped.

SYS@orcl> DROP ROLE d02_r_write;

Role dropped.

SYS@orcl> SELECT COUNT(*) AS d02_users FROM dba_users WHERE username LIKE 'D02%';

 D02_USERS
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) AS d02_roles FROM dba_roles WHERE role LIKE 'D02%';

 D02_ROLES
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) AS d02_pols FROM audit_unified_policies WHERE policy_name = 'D02_POL';

  D02_POLS
----------
         0

1 row selected.
-- ★ NOAUDIT 후 DROP 해야 정책이 지워진다. 사용자·역할·정책 모두 0건이다.
@END

@H3 02.4  정리와 확인 포인트
@B 프록시 세션의 권한은 대상 사용자의 직접 권한에 WITH ROLE 역할을 더한 범위다. 줄일 수 있는 쪽은 역할뿐이므로 민감 권한은 역할로만 준다.
@B 감사에서 실제 사용자는 DBUSERNAME, 경유한 풀 계정은 DBPROXY_USERNAME이다. 둘을 함께 조회 조건으로 쓴다.
@B 프록시 접속의 ORA-01017은 비밀번호보다 PROXY_USERS를 먼저 확인한다.
@B 권한 위반 감사를 조회할 때는 RETURN_CODE 1031과 2004를 함께 본다.
@B 프록시 허용을 회수하려면 `ALTER USER client REVOKE CONNECT THROUGH proxy`를 쓴다. 프록시 계정을 지우지 않아도 해당 대상 사용자만 끊긴다.
@H2 실습 03  Secure Application Role로 역할 활성화 통제
@TBL
항목 | 내용
목표 | 지정한 PL/SQL 프로시저 안에서만 켜지는 응용 역할을 만들고, 정의자·호출자 권한 차이와 활성화 조건의 강도를 실측으로 비교한다
소요 | 30분
접속 | SYS, D03_SEC(검사 로직 소유자), D03_USER(업무 사용자, 로컬·TCP 두 경로)
변경 | 사용자 D03_SEC·D03_USER, 역할 D03_HR_ROLE(HR.EMPLOYEES 조회). 마지막 단계에서 모두 지움
@END

@H3 03.1  실습 전에 — 역할을 켜는 조건을 코드로 고정한다
@B `IDENTIFIED BY` 비밀번호 역할은 비밀번호를 아는 사람이면 어느 도구에서든 켤 수 있다. 응용 프로그램 안에 박힌 역할 비밀번호는 결국 새어 나간다.
@B Secure Application Role은 `CREATE ROLE r IDENTIFIED USING schema.proc`로 만든다. 지정한 프로시저 안에서 `DBMS_SESSION.SET_ROLE`을 부를 때만 켜진다.
@B 직접 `SET ROLE r`을 하면 ORA-28201이 난다.
@B 활성화 프로시저는 호출자 권한(`AUTHID CURRENT_USER`)이어야 한다. 정의자 권한 코드 안에서는 역할을 바꿀 수 없어서 ORA-06565가 난다. 역할은 호출한 세션의 것이기 때문이다.
@B 프로시저가 검사하는 재료는 대부분 `SYS_CONTEXT('USERENV', ...)`다. IP_ADDRESS, MODULE, PROXY_USER, AUTHENTICATION_METHOD, OS_USER, 응용 컨텍스트 값을 쓴다.
@B 재료마다 신뢰도가 다르다.
@B MODULE·CLIENT_INFO·CLIENT_IDENTIFIER는 클라이언트가 `DBMS_APPLICATION_INFO`나 드라이버 속성으로 마음대로 정한다. 단독 조건으로는 약하다.
@B IP_ADDRESS는 서버가 네트워크 연결에서 기록하는 값이다. bequeath 로컬 접속에서는 NULL이다(실습 [6]).
@B PROXY_USER, 인증 방식, 전역 응용 컨텍스트처럼 서버 쪽에서 정해지는 값과 묶으면 강해진다.
@B 부여된 응용 역할은 기본 역할이 아니다(`DBA_ROLE_PRIVS.DEFAULT_ROLE = NO`). 로그인 때 자동으로 켜지지 않는다.
@B 역할을 만든 계정(여기서는 SYS)에게도 역할이 부여된다. 정의는 `DBA_APPLICATION_ROLES`에서 SCHEMA·PACKAGE로 확인한다.
@B 통제의 실체는 프로시저 코드다. 이 프로시저를 고칠 수 있는 계정(소유자, CREATE ANY PROCEDURE 보유자)의 관리가 역할 자체만큼 중요하다.
@B `DBMS_SESSION.SET_ROLE`은 SET ROLE 문과 같다. 세션의 활성 역할을 통째로 바꾸므로, 이미 켜진 역할을 유지하려면 `'r1, r2'`처럼 함께 적는다.
@B 반영 시점이 다르다. 객체·시스템 권한 부여와 회수는 열린 세션에 즉시 반영된다. 역할 부여와 회수는 SET ROLE을 다시 하거나 새 세션을 열어야 반영된다(교안 3장).
@B 활성화 시도 자체를 남기려면 `ACTIONS EXECUTE ON d03_sec.enable_hr` 통합 감사 정책을 건다.(문서 기준, 실습에서는 측정하지 않음).
@CASE 보고 도구에서만 급여 조회 허용
급여 테이블 조회 역할을 응용 역할로 만들었다. 프로시저는 접속 IP가 응용 서버 대역이고 PROXY_USER가 풀 계정일 때만 역할을 켠다. 같은 사용자가 개인 PC의 SQL Developer로 접속하면 IP와 PROXY_USER 조건이 맞지 않아 역할이 켜지지 않는다. 실패는 RAISE_APPLICATION_ERROR 메시지로 남기고, 통합 감사로 EXECUTE를 기록한다.
@END

@H3 03.2  진행 순서
@TBL
단계 | 주제 | 하는 일 | 확인할 것
[1] | 준비 | 검사 소유자·업무 사용자, IDENTIFIED USING 역할 | DBA_APPLICATION_ROLES, DEFAULT_ROLE
[2] | 정의자 권한 프로시저 | AUTHID DEFINER로 생성 | 컴파일은 성공
[3] | 활성화 시도 | 직접 SET ROLE, 조건 불일치, 조건 일치 | ORA-28201, ORA-20001, ORA-06565
[4] | 호출자 권한으로 재작성 | AUTHID CURRENT_USER | VALID
[5] | 활성화 성공 | MODULE 설정 후 호출 | SESSION_ROLES, 107건
[6] | 조건 강화 | MODULE + IP_ADDRESS | 로컬은 거부, TCP는 허용
[7] | 원복 | 사용자·역할 삭제 | 0건
@END

@H3 03.3  실습 스크립트

@P [1] 계정과 응용 역할 준비
@CODE
-- ★ 역할이 가리키는 D03_SEC.ENABLE_HR 은 아직 없다. 역할 생성 시점에는 프로시저 존재를 검사하지 않는다.
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d03_sec IDENTIFIED BY Sec2026x;

User created.

SYS@orcl> GRANT CREATE SESSION, CREATE PROCEDURE TO d03_sec;

Grant succeeded.

SYS@orcl> CREATE USER d03_user IDENTIFIED BY User2026x;

User created.

SYS@orcl> GRANT CREATE SESSION TO d03_user;

Grant succeeded.

SYS@orcl> CREATE ROLE d03_hr_role IDENTIFIED USING d03_sec.enable_hr;

Role created.

SYS@orcl> GRANT SELECT ON hr.employees TO d03_hr_role;

Grant succeeded.

SYS@orcl> GRANT d03_hr_role TO d03_user;

Grant succeeded.

SYS@orcl> COL role FOR a12
SYS@orcl> COL schema FOR a8
SYS@orcl> COL package FOR a10
SYS@orcl> SELECT role, schema, package FROM dba_application_roles WHERE role = 'D03_HR_ROLE';

ROLE         SCHEMA   PACKAGE
------------ -------- ----------
D03_HR_ROLE  D03_SEC  ENABLE_HR

1 row selected.

SYS@orcl> COL grantee FOR a10
SYS@orcl> COL granted_role FOR a12
SYS@orcl> SELECT grantee, granted_role, default_role FROM dba_role_privs WHERE granted_role = 'D03_HR_ROLE';

GRANTEE    GRANTED_ROLE DEF
---------- ------------ ---
SYS        D03_HR_ROLE  NO
D03_USER   D03_HR_ROLE  NO

2 rows selected.
-- ★ 역할 부여 행이 두 개다. 역할을 만든 SYS 에게도 자동으로 부여됐다.
-- ★ 두 행 모두 DEFAULT_ROLE 이 NO 다. 응용 역할은 로그인 때 켜지지 않는다.
@END

@P [2] 정의자 권한으로 만든 활성화 프로시저
@CODE
-- ★ 일부러 정의자 권한으로 만든다. 컴파일 오류는 나지 않는다.
SQL> CONNECT d03_sec/Sec2026x
Connected.
D03_SEC@orcl> CREATE OR REPLACE PROCEDURE enable_hr
  2  AUTHID DEFINER
  3  AS
  4  BEGIN
  5    IF SYS_CONTEXT('USERENV', 'MODULE') = 'D03_HRAPP' THEN
  6      DBMS_SESSION.SET_ROLE('d03_hr_role');
  7    ELSE
  8      RAISE_APPLICATION_ERROR(-20001,
  9        'module ' || SYS_CONTEXT('USERENV', 'MODULE') || ' is not allowed');
 10    END IF;
 11  END;
 12  /

Procedure created.

D03_SEC@orcl> GRANT EXECUTE ON enable_hr TO d03_user;

Grant succeeded.
@END

@P [3] 역할을 켜려는 시도들
@CODE
SQL> CONNECT d03_user/User2026x
Connected.
D03_USER@orcl> SELECT COUNT(*) FROM hr.employees;
SELECT COUNT(*) FROM hr.employees
                        *
ERROR at line 1:
ORA-00942: table or view does not exist


D03_USER@orcl> SET ROLE d03_hr_role;
SET ROLE d03_hr_role
*
ERROR at line 1:
ORA-28201: invalid command to enable secure application role 'D03_HR_ROLE'


D03_USER@orcl> EXEC d03_sec.enable_hr
BEGIN d03_sec.enable_hr; END;

*
ERROR at line 1:
ORA-20001: module SQL*Plus is not allowed
ORA-06512: at "D03_SEC.ENABLE_HR", line 8
ORA-06512: at line 1


D03_USER@orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('D03_HRAPP', NULL)

PL/SQL procedure successfully completed.

D03_USER@orcl> EXEC d03_sec.enable_hr
BEGIN d03_sec.enable_hr; END;

*
ERROR at line 1:
ORA-06565: cannot execute SET ROLE from within stored procedure
ORA-06512: at "SYS.DBMS_SESSION", line 183
ORA-06512: at "D03_SEC.ENABLE_HR", line 6
ORA-06512: at line 1
-- ★ 직접 SET ROLE 은 ORA-28201로 거부된다.
-- ★ MODULE 기본값은 'SQL*Plus' 라서 프로시저가 ORA-20001을 던진다.
-- ★ MODULE 을 맞추면 조건은 통과하지만 정의자 권한이라 ORA-06565가 난다. 오류 스택의 DBMS_SESSION 줄이 SET_ROLE 지점이다.
@END

@P [4] AUTHID CURRENT_USER 로 다시 만들기
@CODE
SQL> CONNECT d03_sec/Sec2026x
Connected.
D03_SEC@orcl> CREATE OR REPLACE PROCEDURE enable_hr
  2  AUTHID CURRENT_USER
  3  AS
  4  BEGIN
  5    IF SYS_CONTEXT('USERENV', 'MODULE') = 'D03_HRAPP' THEN
  6      DBMS_SESSION.SET_ROLE('d03_hr_role');
  7    ELSE
  8      RAISE_APPLICATION_ERROR(-20001,
  9        'module ' || SYS_CONTEXT('USERENV', 'MODULE') || ' is not allowed');
 10    END IF;
 11  END;
 12  /

Procedure created.

D03_SEC@orcl> COL object_name FOR a12
D03_SEC@orcl> SELECT object_name, status FROM user_objects WHERE object_name = 'ENABLE_HR';

OBJECT_NAME  STATUS
------------ -------
ENABLE_HR    VALID

1 row selected.
-- ★ AUTHID 한 단어만 바뀌었다.
@END

@P [5] 조건을 맞춘 활성화
@CODE
SQL> CONNECT d03_user/User2026x
Connected.
D03_USER@orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('D03_HRAPP', NULL)

PL/SQL procedure successfully completed.

D03_USER@orcl> EXEC d03_sec.enable_hr

PL/SQL procedure successfully completed.

D03_USER@orcl> COL role FOR a12
D03_USER@orcl> SELECT role FROM session_roles;

ROLE
------------
D03_HR_ROLE

1 row selected.

D03_USER@orcl> SELECT COUNT(*) FROM hr.employees;

  COUNT(*)
----------
       107

1 row selected.
-- ★ 역할이 켜지고 HR.EMPLOYEES 107건이 조회된다.
-- ★ 다만 MODULE 은 사용자가 직접 정한 값이다. 이 조건은 사실상 아무나 통과한다.
@END

@P [6] MODULE 만으로는 약하다 — 접속 주소 추가
@CODE
-- ★ 조건에 IP_ADDRESS 를 더한다. 서버가 기록하는 값이라 클라이언트가 바꿀 수 없다.
SQL> CONNECT d03_sec/Sec2026x
Connected.
D03_SEC@orcl> CREATE OR REPLACE PROCEDURE enable_hr
  2  AUTHID CURRENT_USER
  3  AS
  4    v_ip VARCHAR2(40) := SYS_CONTEXT('USERENV', 'IP_ADDRESS');
  5  BEGIN
  6    IF SYS_CONTEXT('USERENV', 'MODULE') = 'D03_HRAPP'
  7       AND v_ip = '172.16.225.50' THEN
  8      DBMS_SESSION.SET_ROLE('d03_hr_role');
  9    ELSE
 10      RAISE_APPLICATION_ERROR(-20001,
 11        'denied: module=' || SYS_CONTEXT('USERENV', 'MODULE') || ', ip=' || NVL(v_ip, '(none)'));
 12    END IF;
 13  END;
 14  /

Procedure created.

D03_SEC@orcl> CONNECT d03_user/User2026x
Connected.
D03_USER@orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('D03_HRAPP', NULL)

PL/SQL procedure successfully completed.

D03_USER@orcl> EXEC d03_sec.enable_hr
BEGIN d03_sec.enable_hr; END;

*
ERROR at line 1:
ORA-20001: denied: module=D03_HRAPP, ip=(none)
ORA-06512: at "D03_SEC.ENABLE_HR", line 10
ORA-06512: at line 1


D03_USER@orcl> CONNECT d03_user/User2026x@//172.16.225.50:1521/orcl
Connected.
D03_USER@//172.16.225.50:1521/orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('D03_HRAPP', NULL)

PL/SQL procedure successfully completed.

D03_USER@//172.16.225.50:1521/orcl> EXEC d03_sec.enable_hr

PL/SQL procedure successfully completed.

D03_USER@//172.16.225.50:1521/orcl> COL role FOR a12
D03_USER@//172.16.225.50:1521/orcl> SELECT role FROM session_roles;

ROLE
------------
D03_HR_ROLE

1 row selected.
-- ★ bequeath 로컬 접속은 IP_ADDRESS 가 NULL 이라 거부된다.
-- ★ 리스너를 거친 TCP 접속은 172.16.225.50 으로 기록돼 역할이 켜진다.
@END

@P [7] 원복
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> DROP USER d03_user CASCADE;

User dropped.

SYS@orcl> DROP USER d03_sec CASCADE;

User dropped.

SYS@orcl> DROP ROLE d03_hr_role;

Role dropped.

SYS@orcl> SELECT COUNT(*) AS d03_users FROM dba_users WHERE username LIKE 'D03%';

 D03_USERS
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) AS d03_roles FROM dba_roles WHERE role LIKE 'D03%';

 D03_ROLES
----------
         0

1 row selected.
-- ★ 역할을 지우면 부여 관계도 함께 사라진다.
@END

@H3 03.4  정리와 확인 포인트
@B 응용 역할의 세 가지 오류를 구분한다. 직접 SET ROLE은 ORA-28201, 정의자 권한 프로시저는 ORA-06565, 조건 불일치는 프로시저가 정한 사용자 오류다.
@B 활성화 조건에는 클라이언트가 정하는 값과 서버가 정하는 값을 섞는다. MODULE 단독 조건은 문서상 통제일 뿐이다.
@B 응용 역할은 기본 역할이 아니므로, 응용 프로그램이 접속 직후 활성화 프로시저를 부르는 흐름을 표준으로 둔다.
@B 역할 생성자에게 남는 부여(SYS 행)는 필요 없으면 회수한다.
@B 프로시저 소유 스키마에는 접속 권한을 최소화하고 코드 변경을 감사한다.
@H2 실습 04  네트워크 ACL로 외부 호출 통제
@TBL
항목 | 내용
목표 | UTL_HTTP·UTL_INADDR 호출을 호스트 ACE로 허용·거부하고, 역할 기반 ACE와 정의자 권한 코드의 관계, 호스트 우선순위를 실측으로 확인한다
소요 | 30분
접속 | root(시험용 HTTP 서버), SYS, D04_APP
변경 | 사용자 D04_APP, 역할 D04_WEB_ROLE, D04_% 대상 ACE 4개, 포트 8094 HTTP 서버. 마지막 단계에서 모두 지움
@END

@H3 04.1  실습 전에 — 패키지 실행 권한과 네트워크 접근 권한은 따로 판정된다
@B UTL_HTTP·UTL_TCP·UTL_SMTP·UTL_INADDR의 EXECUTE는 기본적으로 PUBLIC에 있다. 실제 네트워크 접근은 호스트 ACL이 허용해야 한다. 허용이 없으면 ORA-24247이 나고, UTL_HTTP는 이를 ORA-29273으로 감싼다.
@B 12c부터는 `DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE`와 `REMOVE_HOST_ACE`로 ACE를 직접 다룬다. 조회는 `DBA_HOST_ACLS`, `DBA_HOST_ACES`로 한다. 11g의 CREATE_ACL·ADD_PRIVILEGE·ASSIGN_ACL은 디프리케이트됐다.
@B 권한 종류는 connect, resolve, http, http_proxy, smtp, jdwp다. http는 UTL_HTTP 요청만 허용하고, 이름 풀이(UTL_INADDR)는 resolve가 따로 필요하다.
@B 호스트 지정은 정확한 이름·IP, 와일드카드(`172.16.225.*`, `*.example.com`), 전체(`*`)로 한다.
@B 판정은 가장 구체적인 호스트부터 본다. IP 172.16.225.50은 172.16.225.50 → 172.16.225.* → 172.16.* → 172.* → * 순이다(`DBMS_NETWORK_ACL_UTILITY.DOMAINS`, 실습 [8]).
@B 구체적인 호스트의 ACE에서 판정이 나면 넓은 호스트의 ACE는 보지 않는다. 그래서 `*`에 resolve GRANT가 있어도 `oel7v9`의 DENY가 이긴다(실습 [7]).
@B 포트 범위가 있는 ACE가 포트 범위 없는 ACE보다 우선한다. 범위 밖 포트는 허용되지 않는다.
@B ACE의 대상(principal)은 사용자나 역할이다. 정의자 권한 PL/SQL 안에서는 역할이 꺼지므로, 역할로 받은 ACE도 효과가 없다(실습 [5] 실측).
@B 운영 패키지가 외부를 호출하면 ACE를 패키지 소유 스키마에 직접 준다. 역할 ACE는 대화형·호출자 권한 코드용이다.
@B `REMOVE_HOST_ACE`는 호스트·포트·권한·대상·GRANT/DENY가 모두 같아야 지운다. 정리는 `DBA_HOST_ACES`를 읽어 같은 값으로 돌리는 방식이 안전하다.
@B ACE를 처음 추가하면 해당 호스트·포트 조합의 ACL이 시스템 이름으로 자동 생성된다. 같은 조합에 다시 추가하면 그 ACL에 ACE가 덧붙고 ACE_ORDER가 1, 2로 늘어난다(실습 [4]·[6]).
@B UTL_HTTP 오류는 ORA-29273 아래에 실제 원인이 깔린다. 스택에 ORA-24247이 있으면 ACL 판정이고, 없으면 연결이나 대상 서버 쪽 원인이다.
@B 현재 사용자 기준의 점검은 `USER_HOST_ACES`로 한다. 자기에게 적용되는 ACE와 판정 상태를 보여 준다(문서 기준).
@B 웹 프록시를 거치는 호출에는 대상 호스트 ACE 외에 프록시 호스트에 대한 http_proxy 권한이 필요하다(문서 기준).
@NOTE HTTPS 호출
HTTPS는 ACE 외에 신뢰할 인증서를 담은 지갑이 필요하다(`UTL_HTTP.SET_WALLET`). 이 실습은 평문 HTTP만 다룬다.
@END

@H3 04.2  진행 순서
@TBL
단계 | 주제 | 하는 일 | 확인할 것
[1] | 시험 서버 | root로 8094 포트 HTTP 서버 기동 | curl 응답
[2] | 준비 | D04_APP, D04_WEB_ROLE | CREATE PROCEDURE 포함
[3] | ACE 없이 | UTL_HTTP.REQUEST | ORA-29273 / ORA-24247
[4] | 역할 ACE | 역할에 http, 8094 | DBA_HOST_ACES
[5] | 실행 문맥 비교 | 익명 SQL과 정의자 권한 함수 | SQL은 성공, 함수는 ORA-24247
[6] | 사용자 ACE | 사용자에게 직접 http | 함수 성공, 8095는 거부
[7] | 우선순위 | '*' resolve GRANT + oel7v9 DENY | oel7v9 거부, localhost 허용
[8] | 판정 근거 | ACE 목록과 DOMAINS | ACE_ORDER, 도메인 순서
[9~10] | 원복 | ACE·사용자·역할·서버 정리 | D04 0건, 전체 ACE 3건
@END

@H3 04.3  실습 스크립트

@P [1] 시험용 HTTP 서버
@CODE
-- ★ root 로 파이썬 내장 웹 서버를 띄운다. 외부 API를 대신하는 시험 대상이다.
[root@oel7v9 ~]# pkill -f 'SimpleHTTPServer 8094'
[root@oel7v9 ~]# mkdir -p /tmp/d04_www
[root@oel7v9 ~]# echo '<html><body>D04 internal api</body></html>' > /tmp/d04_www/index.html
[root@oel7v9 ~]# cd /tmp/d04_www
[root@oel7v9 d04_www]# setsid nohup python -m SimpleHTTPServer 8094 > /tmp/d04_http.log 2>&1 < /dev/null &
[root@oel7v9 d04_www]# cd ~
[root@oel7v9 ~]# sleep 2
[root@oel7v9 ~]# curl -s http://172.16.225.50:8094/
<html><body>D04 internal api</body></html>
@END

@P [2] 계정과 역할 준비
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d04_app IDENTIFIED BY App2026x;

User created.

SYS@orcl> GRANT CREATE SESSION, CREATE PROCEDURE TO d04_app;

Grant succeeded.

SYS@orcl> CREATE ROLE d04_web_role;

Role created.

SYS@orcl> GRANT d04_web_role TO d04_app;

Grant succeeded.
@END

@P [3] ACE 없이 호출
@CODE
SQL> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8094/'), 1, 40) AS page FROM dual;
SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8094/'), 1, 40) AS page FROM dual
              *
ERROR at line 1:
ORA-29273: HTTP request failed
ORA-06512: at "SYS.UTL_HTTP", line 1530
ORA-24247: network access denied by access control list (ACL)
ORA-06512: at "SYS.UTL_HTTP", line 380
ORA-06512: at "SYS.UTL_HTTP", line 1470
ORA-06512: at line 1
-- ★ 실행 권한은 PUBLIC에 있어 패키지 호출 자체는 된다. 네트워크 단계에서 ORA-24247로 막힌다.
@END

@P [4] 역할에 http ACE 주기
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
  3      host       => '172.16.225.50',
  4      lower_port => 8094,
  5      upper_port => 8094,
  6      ace        => xs$ace_type(privilege_list => xs$name_list('http'),
  7                                principal_name => 'D04_WEB_ROLE',
  8                                principal_type => xs_acl.ptype_db));
  9  END;
 10  /

PL/SQL procedure successfully completed.

SYS@orcl> COL host FOR a14
SYS@orcl> COL principal FOR a12
SYS@orcl> COL privilege FOR a8
SYS@orcl> SELECT host, lower_port lo, upper_port hi, ace_order ord, principal, privilege, grant_type
  2    FROM dba_host_aces WHERE principal LIKE 'D04%' ORDER BY host, lo, ord;

HOST                   LO         HI        ORD PRINCIPAL    PRIVILEG GRANT
-------------- ---------- ---------- ---------- ------------ -------- -----
172.16.225.50        8094       8094          1 D04_WEB_ROLE HTTP     GRANT

1 row selected.
-- ★ ACE_ORDER 는 같은 호스트·포트 ACL 안의 평가 순서다.
@END

@P [5] 익명 SQL과 정의자 권한 함수
@CODE
SQL> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> COL page FOR a42
D04_APP@orcl> COL ip FOR a16
D04_APP@orcl> SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8094/'), 1, 40) AS page FROM dual;

PAGE
------------------------------------------
<html><body>D04 internal api</body></htm

1 row selected.

D04_APP@orcl> CREATE OR REPLACE FUNCTION get_page RETURN VARCHAR2
  2  AUTHID DEFINER
  3  AS
  4  BEGIN
  5    RETURN SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8094/'), 1, 40);
  6  END;
  7  /

Function created.

D04_APP@orcl> SELECT get_page AS page FROM dual;
SELECT get_page AS page FROM dual
       *
ERROR at line 1:
ORA-29273: HTTP request failed
ORA-06512: at "SYS.UTL_HTTP", line 1530
ORA-24247: network access denied by access control list (ACL)
ORA-06512: at "SYS.UTL_HTTP", line 380
ORA-06512: at "SYS.UTL_HTTP", line 1470
ORA-06512: at "D04_APP.GET_PAGE", line 5
-- ★ SQL에서는 역할이 켜져 있어 호출이 성공한다.
-- ★ 같은 호출을 정의자 권한 함수에 넣으면 역할이 꺼져 ORA-24247이 난다. 오류 스택 마지막 줄이 D04_APP.GET_PAGE 다.
@END

@P [6] 사용자에게 직접 ACE
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
  3      host       => '172.16.225.50',
  4      lower_port => 8094,
  5      upper_port => 8094,
  6      ace        => xs$ace_type(privilege_list => xs$name_list('http'),
  7                                principal_name => 'D04_APP',
  8                                principal_type => xs_acl.ptype_db));
  9  END;
 10  /

PL/SQL procedure successfully completed.

SYS@orcl> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> COL page FOR a42
D04_APP@orcl> COL ip FOR a16
D04_APP@orcl> SELECT get_page AS page FROM dual;

PAGE
------------------------------------------
<html><body>D04 internal api</body></htm

1 row selected.

D04_APP@orcl> SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8095/'), 1, 40) AS page FROM dual;
SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8095/'), 1, 40) AS page FROM dual
              *
ERROR at line 1:
ORA-29273: HTTP request failed
ORA-06512: at "SYS.UTL_HTTP", line 1530
ORA-24247: network access denied by access control list (ACL)
ORA-06512: at "SYS.UTL_HTTP", line 380
ORA-06512: at "SYS.UTL_HTTP", line 1470
ORA-06512: at line 1
-- ★ 사용자에게 직접 준 ACE는 정의자 권한 함수에서도 유효하다.
-- ★ 포트 8095는 범위 밖이라 거부된다. 서버가 없는 포트인데도 연결 시도 전에 ACL 단계에서 막힌다.
@END

@P [7] resolve 권한과 호스트 우선순위
@CODE
-- ★ '*' 에 resolve 를 허용한 뒤, 정확한 호스트 oel7v9 에 같은 권한의 DENY 를 추가한다.
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
  3      host       => '*',
  4      ace        => xs$ace_type(privilege_list => xs$name_list('resolve'),
  5                                principal_name => 'D04_APP',
  6                                principal_type => xs_acl.ptype_db));
  7  END;
  8  /

PL/SQL procedure successfully completed.

SYS@orcl> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> COL page FOR a42
D04_APP@orcl> COL ip FOR a16
D04_APP@orcl> SELECT UTL_INADDR.GET_HOST_ADDRESS('oel7v9') AS ip FROM dual;

IP
----------------
172.16.225.50

1 row selected.

D04_APP@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
  3      host       => 'oel7v9',
  4      ace        => xs$ace_type(privilege_list => xs$name_list('resolve'),
  5                                principal_name => 'D04_APP',
  6                                principal_type => xs_acl.ptype_db,
  7                                granted        => FALSE));
  8  END;
  9  /

PL/SQL procedure successfully completed.

SYS@orcl> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> COL page FOR a42
D04_APP@orcl> COL ip FOR a16
D04_APP@orcl> SELECT UTL_INADDR.GET_HOST_ADDRESS('oel7v9') AS ip FROM dual;
SELECT UTL_INADDR.GET_HOST_ADDRESS('oel7v9') AS ip FROM dual
       *
ERROR at line 1:
ORA-24247: network access denied by access control list (ACL)
ORA-06512: at "SYS.UTL_INADDR", line 19
ORA-06512: at "SYS.UTL_INADDR", line 40
ORA-06512: at line 1


D04_APP@orcl> SELECT UTL_INADDR.GET_HOST_ADDRESS('localhost') AS ip FROM dual;

IP
----------------
127.0.0.1

1 row selected.
-- ★ oel7v9 는 구체적인 호스트의 DENY 로 판정이 끝난다. '*' 의 GRANT 까지 내려가지 않는다.
-- ★ localhost 는 구체적인 ACE가 없어 '*' 의 GRANT 를 따른다.
@END

@P [8] 판정 근거 조회
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL host FOR a14
SYS@orcl> COL principal FOR a12
SYS@orcl> COL privilege FOR a8
SYS@orcl> SELECT host, lower_port lo, upper_port hi, ace_order ord, principal, privilege, grant_type
  2    FROM dba_host_aces WHERE principal LIKE 'D04%' ORDER BY host, lo, ord;

HOST                   LO         HI        ORD PRINCIPAL    PRIVILEG GRANT
-------------- ---------- ---------- ---------- ------------ -------- -----
*                                             3 D04_APP      RESOLVE  GRANT
172.16.225.50        8094       8094          1 D04_WEB_ROLE HTTP     GRANT
172.16.225.50        8094       8094          2 D04_APP      HTTP     GRANT
oel7v9                                        1 D04_APP      RESOLVE  DENY

4 rows selected.

SYS@orcl> COL domain FOR a16
SYS@orcl> SELECT COLUMN_VALUE AS domain FROM TABLE(DBMS_NETWORK_ACL_UTILITY.DOMAINS('172.16.225.50'));

DOMAIN
----------------
172.16.225.50
172.16.225.*
172.16.*
172.*
*

5 rows selected.
-- ★ DOMAINS 결과가 IP의 판정 순서다. 위에서부터 처음 판정이 나는 곳에서 멈춘다.
@END

@P [9] 원복
@CODE
-- ★ DBA_HOST_ACES 의 값을 그대로 REMOVE_HOST_ACE 에 넘겨 DENY 까지 지운다.
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    FOR r IN (SELECT host, lower_port, upper_port, principal, privilege, grant_type
  3                FROM dba_host_aces WHERE principal LIKE 'D04%') LOOP
  4      DBMS_NETWORK_ACL_ADMIN.REMOVE_HOST_ACE(r.host, r.lower_port, r.upper_port,
  5        xs$ace_type(privilege_list => xs$name_list(r.privilege),
  6                    principal_name => r.principal,
  7                    principal_type => xs_acl.ptype_db,
  8                    granted        => (r.grant_type = 'GRANT')), TRUE);
  9    END LOOP;
 10  END;
 11  /

PL/SQL procedure successfully completed.

SYS@orcl> DROP USER d04_app CASCADE;

User dropped.

SYS@orcl> DROP ROLE d04_web_role;

Role dropped.

SYS@orcl> SELECT COUNT(*) AS d04_aces FROM dba_host_aces WHERE principal LIKE 'D04%';

  D04_ACES
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) AS all_aces FROM dba_host_aces;

  ALL_ACES
----------
         3

1 row selected.

SYS@orcl> SELECT COUNT(*) AS d04_users FROM dba_users WHERE username LIKE 'D04%';

 D04_USERS
----------
         0

1 row selected.
-- ★ ALL_ACES 3건은 실습 전 기본 상태다.
@END

@P [10] HTTP 서버 정리
@CODE
[root@oel7v9 ~]# pkill -f 'SimpleHTTPServer 8094'
[root@oel7v9 ~]# rm -rf /tmp/d04_www /tmp/d04_http.log
[root@oel7v9 ~]# ss -ltn | grep -c 8094
0
-- ★ 포트 8094 리스닝 0건으로 시험 서버 정리를 확인한다.
@END

@H3 04.4  정리와 확인 포인트
@B ORA-24247은 패키지 권한 문제가 아니라 ACL 판정 결과다. DBA_HOST_ACES에서 호스트·포트·권한·대상을 차례로 대조한다.
@B 같은 사용자라도 실행 문맥에 따라 결과가 갈린다. 정의자 권한 코드에는 사용자 ACE가 필요하다.
@B 넓은 와일드카드 허용과 구체적 호스트 거부를 조합하면, 대부분 허용하고 특정 대상만 막는 정책이 된다. 반대 조합(넓게 거부, 좁게 허용)도 같은 원리로 동작한다.
@B http와 resolve는 별개다. URL에 호스트 이름을 쓰는 코드에는 두 권한이 모두 필요하다.
@B ACE 정리는 GRANT/DENY 값까지 맞춰야 한다. 남은 DENY ACE는 다음 허용을 조용히 무력화한다.
@H2 실습 05  Application Context와 VPD로 행·컬럼 통제
@TBL
항목 | 내용
목표 | 로그온 시점에 신뢰 패키지로 세션 속성을 채우고, 그 값으로 행 수준·컬럼 수준 VPD 정책을 건다. 정책 오류를 트레이스로 진단한다.
소요 | 50분
접속 | SYS(준비·진단), D05_SEC(보안 관리자), D05_KIM(50번 부서 사원), D05_LEE(80번 부서 관리자)
변경 | 사용자 4개, 컨텍스트 D05_CTX, 로그온 트리거 2개, VPD 정책 2개. 마지막 단계에서 모두 지움
@END

@H3 05.1  실습 전에 — 정책 함수는 술어 문자열을 돌려줄 뿐이다
@B VPD는 SQL을 고쳐 쓰는 기능이다. 정책 함수가 돌려준 문자열이 대상 테이블 자리에 `WHERE (술어)`가 붙은 인라인 뷰로 들어간다. 사용자 문장에는 흔적이 남지 않음.
@B 정책 함수는 `(스키마, 객체)` 두 인자를 받고 VARCHAR2를 돌려준다. NULL이나 빈 문자열이면 필터가 없고, `1=2`면 행이 하나도 안 보인다.
@B 술어 안에서 사용자 구분 값을 직접 조회하면 문장마다 서브쿼리가 붙는다. 그래서 값은 로그온 때 한 번 Application Context에 넣고, 술어는 `SYS_CONTEXT(...)`만 참조하게 만든다.
@B 로컬 컨텍스트 값은 `CREATE CONTEXT ... USING`에 지정한 패키지 안에서만 바꿀 수 있다. 사용자가 `DBMS_SESSION.SET_CONTEXT`를 직접 부르면 ORA-01031이 나고, 이 제약이 위조를 막는 장치다.
@B 컨텍스트 값을 채우는 로그온 트리거는 ON DATABASE보다 ON 스키마.SCHEMA로 거는 편이 안전하다. 트리거가 예외를 내면 그 사용자의 접속이 실패하므로, 매핑 누락 같은 예외는 패키지 안에서 처리한다.
@B 정책 함수는 함수 소유자의 권한으로 실행된다. 함수가 읽는 객체 권한은 소유자(D05_SEC)에게 직접 있어야 하고, 조회하는 사용자에게는 필요 없다.
@B 한 테이블에 정책이 여럿이면 각 술어가 AND로 결합된다. 행 정책과 컬럼 정책을 따로 만들어 겹쳐 쓸 수 있고, 응용별로 나누려면 정책 그룹(CREATE_POLICY_GROUP)을 쓴다.
@B 정책 유형마다 정책 함수를 다시 부르는 시점이 다르다.
@TBL
정책 유형 | 함수 재평가 시점 | 쓰는 경우
DYNAMIC(기본) | 문장을 실행할 때마다 | 술어가 시각·외부 상태에 따라 바뀜
CONTEXT_SENSITIVE | 세션의 컨텍스트 값이 바뀔 때 | 술어가 SYS_CONTEXT에만 기대는 경우(이번 실습)
STATIC | 처음 파싱할 때 한 번 | 술어 문자열 자체가 고정됨
@END
@B statement_types에 INSERT를 넣으려면 19c에서는 update_check => TRUE가 함께 있어야 한다. 빠지면 ORA-28104가 남. update_check가 켜지면 변경 후 행이 술어를 벗어나는 INSERT·UPDATE는 ORA-28115로 막힌다.
@B 컬럼 수준 VPD(sec_relevant_cols)는 지정 컬럼을 참조하는 문장에만 정책을 적용한다.
@B 기본 동작은 행 자체를 걸러낸다. ALL_ROWS 옵션을 주면 행은 모두 보이고 해당 컬럼만 NULL로 바뀜. ALL_ROWS는 SELECT 전용이다.
@B 술어 문법 오류는 ADD_POLICY 때 드러나지 않는다. 조회 시점에 ORA-28113으로 나타나고, 원인 문장은 세션 트레이스 파일에 남는다. V$VPD_POLICY에서는 커서마다 실제로 붙은 술어를 볼 수 있다.
@NOTE 정책이 적용되지 않는 계정
SYS와 EXEMPT ACCESS POLICY 권한 보유자에게는 VPD가 적용되지 않는다. 데이터 소유자는 면제 대상이 아니다. 이번 실습의 술어 함수가 대상 사용자 외에는 NULL을 돌려주는 것은, 소유자와 다른 업무 계정이 영향을 받지 않게 하려는 설계다. EXEMPT ACCESS POLICY 보유자는 정기 점검 대상에 넣는다.
@END

@H3 05.2  진행 순서
@TBL
단계 | 하는 일 | 확인할 것
[1] 준비 — 계정과 데이터 | 소유자·보안 관리자·사원 계정 생성, HR.EMPLOYEES 복사 | 50번 45명, 80번 34명
[2] 컨텍스트와 신뢰 패키지 | 매핑 테이블, CREATE CONTEXT USING, 값 설정 패키지 | 패키지가 컨텍스트의 유일한 쓰기 경로
[3] 로그온 트리거와 위조 시도 | 스키마 단위 AFTER LOGON 트리거, 직접 SET_CONTEXT 호출 | DEPT=50, 위조 시 ORA-01031
[4] 정책 함수와 행 수준 정책 | 술어 함수 작성, INSERT 포함 정책 등록 두 번 | update_check 없이 ORA-28104
[5] 사용자별 결과와 update_check | KIM·LEE 조회, 다른 부서 UPDATE·INSERT | KIM 50번만, 80번 UPDATE 0건, INSERT ORA-28115
[6] 컬럼 수준 정책 — 급여는 관리자만 | SALARY 컬럼에 ALL_ROWS 정책 추가 | KIM은 SALARY NULL, LEE는 값 보임
[7] 진단 — V$VPD_POLICY와 술어 오류 | 실제 술어 조회 후 함수를 틀린 컬럼명으로 교체 | ORA-28113
[8] 트레이스로 원인 찾기 | 세션 트레이스에서 정책 이름 검색 | RLS view 문장과 ORA-00904
[9] 술어 복구 | 함수를 원래대로 교체 후 재조회 | 45건
[10] 정리와 확인 | 정책·컨텍스트·사용자 삭제 | 모든 조회 0건
@END

@H3 05.3  실습 스크립트

@P [1] 준비 — 계정과 데이터
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d05_own IDENTIFIED BY d05_own QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d05_sec IDENTIFIED BY d05_sec QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d05_kim IDENTIFIED BY d05_kim;

User created.

SYS@orcl> CREATE USER d05_lee IDENTIFIED BY d05_lee;

User created.

SYS@orcl> GRANT CREATE SESSION TO d05_own, d05_sec, d05_kim, d05_lee;

Grant succeeded.

SYS@orcl> GRANT CREATE TABLE, CREATE PROCEDURE, CREATE ANY CONTEXT TO d05_sec;

Grant succeeded.

SYS@orcl> GRANT EXECUTE ON DBMS_RLS TO d05_sec;

Grant succeeded.

SYS@orcl> CREATE TABLE d05_own.emp AS
  2    SELECT employee_id, last_name, department_id, salary FROM hr.employees;

Table created.

SYS@orcl> GRANT SELECT, INSERT, UPDATE, DELETE ON d05_own.emp TO d05_kim, d05_lee;

Grant succeeded.

SYS@orcl> SELECT department_id, COUNT(*) cnt, SUM(salary) sum_sal
  2    FROM d05_own.emp WHERE department_id IN (50, 80) GROUP BY department_id ORDER BY 1;

DEPARTMENT_ID        CNT    SUM_SAL
------------- ---------- ----------
           50         45     156400
           80         34     304500

2 rows selected.

-- ★ 보안 관리자 D05_SEC는 정책·컨텍스트만 다룬다. 데이터는 D05_OWN 소유라 소유자와 정책 관리자가 분리됨.
--    두 부서의 행 수(45, 34)가 이후 정책 결과를 판단하는 기준이다.
@END

@P [2] 컨텍스트와 신뢰 패키지
@CODE
SQL> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE TABLE user_map (
  2    username  VARCHAR2(30) PRIMARY KEY,
  3    dept_id   NUMBER,
  4    is_mgr    CHAR(1));

Table created.

D05_SEC@orcl> INSERT INTO user_map VALUES ('D05_KIM', 50, 'N');

1 row created.

D05_SEC@orcl> INSERT INTO user_map VALUES ('D05_LEE', 80, 'Y');

1 row created.

D05_SEC@orcl> COMMIT;

Commit complete.

D05_SEC@orcl> CREATE CONTEXT d05_ctx USING d05_sec.ctx_pkg;

Context created.

D05_SEC@orcl> CREATE OR REPLACE PACKAGE ctx_pkg AS
  2    PROCEDURE set_user;
  3  END;
  4  /

Package created.

D05_SEC@orcl> CREATE OR REPLACE PACKAGE BODY ctx_pkg AS
  2    PROCEDURE set_user IS
  3      v_dept NUMBER;
  4      v_mgr  CHAR(1);
  5    BEGIN
  6      SELECT dept_id, is_mgr INTO v_dept, v_mgr
  7        FROM user_map WHERE username = SYS_CONTEXT('USERENV', 'SESSION_USER');
  8      DBMS_SESSION.SET_CONTEXT('D05_CTX', 'DEPT', v_dept);
  9      DBMS_SESSION.SET_CONTEXT('D05_CTX', 'MGR',  v_mgr);
 10    EXCEPTION
 11      WHEN NO_DATA_FOUND THEN NULL;
 12    END;
 13  END;
 14  /

Package body created.

-- ★ 컨텍스트를 패키지보다 먼저 만들었지만 오류가 없었다. USING 절에는 패키지 이름이 기록된다.
--    매핑에 없는 사용자는 NO_DATA_FOUND를 삼켜 값이 비게 둔다. 로그온 트리거가 예외를 내면 접속 자체가 막힌다.
@END

@P [3] 로그온 트리거와 위조 시도
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE OR REPLACE TRIGGER d05_sec.trg_logon_kim AFTER LOGON ON d05_kim.SCHEMA
  2  BEGIN d05_sec.ctx_pkg.set_user; END;
  3  /

Trigger created.

SYS@orcl> CREATE OR REPLACE TRIGGER d05_sec.trg_logon_lee AFTER LOGON ON d05_lee.SCHEMA
  2  BEGIN d05_sec.ctx_pkg.set_user; END;
  3  /

Trigger created.

SYS@orcl> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> COL dept FOR a6
D05_KIM@orcl> COL mgr FOR a4
D05_KIM@orcl> SELECT SYS_CONTEXT('D05_CTX', 'DEPT') dept, SYS_CONTEXT('D05_CTX', 'MGR') mgr FROM dual;

DEPT   MGR
------ ----
50     N

1 row selected.

D05_KIM@orcl> EXEC DBMS_SESSION.SET_CONTEXT('D05_CTX', 'DEPT', '80')
BEGIN DBMS_SESSION.SET_CONTEXT('D05_CTX', 'DEPT', '80'); END;

*
ERROR at line 1:
ORA-01031: insufficient privileges
ORA-06512: at "SYS.DBMS_SESSION", line 141
ORA-06512: at line 1


D05_KIM@orcl> SELECT SYS_CONTEXT('D05_CTX', 'DEPT') dept FROM dual;

DEPT
------
50

1 row selected.

-- ★ 트리거를 ON DATABASE가 아니라 ON d05_kim.SCHEMA로 걸어 다른 사용자 접속에는 영향이 없다.
--    직접 SET_CONTEXT는 ORA-01031. DBMS_SESSION은 PUBLIC 실행 권한이 있지만, 지정 패키지 밖에서의 쓰기를 커널이 거부한다.
--    위조 시도 뒤에도 DEPT는 50 그대로다.
@END

@P [4] 정책 함수와 행 수준 정책
@CODE
SQL> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE OR REPLACE FUNCTION row_pred (p_schema VARCHAR2, p_object VARCHAR2)
  2  RETURN VARCHAR2 AS
  3  BEGIN
  4    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('D05_KIM', 'D05_LEE') THEN
  5      RETURN 'department_id = SYS_CONTEXT(''D05_CTX'', ''DEPT'')';
  6    END IF;
  7    RETURN NULL;
  8  END;
  9  /

Function created.

D05_SEC@orcl> BEGIN
  2    DBMS_RLS.ADD_POLICY(
  3      object_schema   => 'D05_OWN',
  4      object_name     => 'EMP',
  5      policy_name     => 'D05_ROW_POL',
  6      function_schema => 'D05_SEC',
  7      policy_function => 'ROW_PRED',
  8      statement_types => 'SELECT,INSERT,UPDATE,DELETE',
  9      policy_type     => DBMS_RLS.CONTEXT_SENSITIVE);
 10  END;
 11  /
BEGIN
*
ERROR at line 1:
ORA-28104: input value for statement_types is not valid
ORA-06512: at "SYS.DBMS_RLS_INT", line 23
ORA-06512: at "SYS.DBMS_RLS", line 54
ORA-06512: at line 2


D05_SEC@orcl> BEGIN
  2    DBMS_RLS.ADD_POLICY(
  3      object_schema   => 'D05_OWN',
  4      object_name     => 'EMP',
  5      policy_name     => 'D05_ROW_POL',
  6      function_schema => 'D05_SEC',
  7      policy_function => 'ROW_PRED',
  8      statement_types => 'SELECT,INSERT,UPDATE,DELETE',
  9      update_check    => TRUE,
 10      policy_type     => DBMS_RLS.CONTEXT_SENSITIVE);
 11  END;
 12  /

PL/SQL procedure successfully completed.

-- ★ 첫 ADD_POLICY는 statement_types에 INSERT가 있는데 update_check가 없어 ORA-28104로 거부됐다.
--    두 번째 호출에서 update_check => TRUE를 넣자 등록됐다. 정책은 실패한 첫 호출에서 만들어지지 않았으므로 ORA-28101도 나지 않는다.
@END

@P [5] 사용자별 결과와 update_check
@CODE
SQL> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> SELECT department_id, COUNT(*) FROM d05_own.emp GROUP BY department_id;

DEPARTMENT_ID   COUNT(*)
------------- ----------
           50         45

1 row selected.

D05_KIM@orcl> UPDATE d05_own.emp SET salary = salary + 1 WHERE department_id = 80;

0 rows updated.

D05_KIM@orcl> INSERT INTO d05_own.emp VALUES (9001, 'Fake', 80, 1000);
INSERT INTO d05_own.emp VALUES (9001, 'Fake', 80, 1000)
                    *
ERROR at line 1:
ORA-28115: policy with check option violation


D05_KIM@orcl> INSERT INTO d05_own.emp VALUES (9002, 'Ok', 50, 1000);

1 row created.

D05_KIM@orcl> ROLLBACK;

Rollback complete.

D05_KIM@orcl> CONNECT d05_lee/d05_lee
Connected.
D05_LEE@orcl> SELECT department_id, COUNT(*) FROM d05_own.emp GROUP BY department_id;

DEPARTMENT_ID   COUNT(*)
------------- ----------
           80         34

1 row selected.

-- ★ KIM에게는 50번 45행, LEE에게는 80번 34행만 보인다. 같은 테이블, 같은 문장이다.
--    UPDATE ... WHERE department_id = 80은 오류 없이 0건이다. 술어가 대상 행을 먼저 걸러냈기 때문이다.
--    80번 부서 행 INSERT는 ORA-28115. 들어갈 행이 술어를 만족하지 않는다. 자기 부서(50) 행은 들어갔다.
@END

@P [6] 컬럼 수준 정책 — 급여는 관리자만
@CODE
SQL> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE OR REPLACE FUNCTION sal_pred (p_schema VARCHAR2, p_object VARCHAR2)
  2  RETURN VARCHAR2 AS
  3  BEGIN
  4    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('D05_KIM', 'D05_LEE') THEN
  5      RETURN 'SYS_CONTEXT(''D05_CTX'', ''MGR'') = ''Y''';
  6    END IF;
  7    RETURN NULL;
  8  END;
  9  /

Function created.

D05_SEC@orcl> BEGIN
  2    DBMS_RLS.ADD_POLICY(
  3      object_schema         => 'D05_OWN',
  4      object_name           => 'EMP',
  5      policy_name           => 'D05_SAL_POL',
  6      function_schema       => 'D05_SEC',
  7      policy_function       => 'SAL_PRED',
  8      statement_types       => 'SELECT',
  9      sec_relevant_cols     => 'SALARY',
 10      sec_relevant_cols_opt => DBMS_RLS.ALL_ROWS,
 11      policy_type           => DBMS_RLS.CONTEXT_SENSITIVE);
 12  END;
 13  /

PL/SQL procedure successfully completed.

D05_SEC@orcl> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> SELECT employee_id, last_name, salary FROM d05_own.emp WHERE employee_id BETWEEN 120 AND 124 ORDER BY 1;

EMPLOYEE_ID LAST_NAME                     SALARY
----------- ------------------------- ----------
        120 Weiss
        121 Fripp
        122 Kaufling
        123 Vollman
        124 Mourgos

5 rows selected.

D05_KIM@orcl> SELECT COUNT(*), COUNT(salary) FROM d05_own.emp;

  COUNT(*) COUNT(SALARY)
---------- -------------
        45             0

1 row selected.

D05_KIM@orcl> CONNECT d05_lee/d05_lee
Connected.
D05_LEE@orcl> SELECT employee_id, last_name, salary FROM d05_own.emp WHERE employee_id BETWEEN 145 AND 149 ORDER BY 1;

EMPLOYEE_ID LAST_NAME                     SALARY
----------- ------------------------- ----------
        145 Russell                        14000
        146 Partners                       13500
        147 Errazuriz                      12000
        148 Cambrault                      11000
        149 Zlotkey                        10500

5 rows selected.

-- ★ KIM은 행은 보지만 SALARY가 비었다. COUNT(*)는 45, COUNT(salary)는 0이다. ALL_ROWS라서 행 수는 줄지 않음.
--    LEE는 MGR=Y라 급여가 보인다. 두 정책이 AND로 겹쳐, LEE도 여전히 80번 부서 행만 본다.
--    ALL_ROWS 없이 기본값으로 걸면 SALARY를 참조한 문장에서 행 자체가 사라진다(원 교안 7장 실습 04).
@END

@P [7] 진단 — V$VPD_POLICY와 술어 오류
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL policy FOR a12
SYS@orcl> COL predicate FOR a50
SYS@orcl> SELECT DISTINCT policy, predicate FROM v$vpd_policy WHERE object_owner = 'D05_OWN' ORDER BY 1;

POLICY       PREDICATE
------------ --------------------------------------------------
D05_ROW_POL  department_id = SYS_CONTEXT('D05_CTX', 'DEPT')
D05_SAL_POL  SYS_CONTEXT('D05_CTX', 'MGR') = 'Y'

2 rows selected.

SYS@orcl> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE OR REPLACE FUNCTION row_pred (p_schema VARCHAR2, p_object VARCHAR2)
  2  RETURN VARCHAR2 AS
  3  BEGIN
  4    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('D05_KIM', 'D05_LEE') THEN
  5      RETURN 'dept_no = SYS_CONTEXT(''D05_CTX'', ''DEPT'')';
  6    END IF;
  7    RETURN NULL;
  8  END;
  9  /

Function created.

D05_SEC@orcl> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> SELECT COUNT(*) FROM d05_own.emp;
SELECT COUNT(*) FROM d05_own.emp
                             *
ERROR at line 1:
ORA-28113: policy predicate has error

-- ★ V$VPD_POLICY에는 공유 풀 커서에 실제로 붙은 술어가 남는다. 함수 코드를 보지 않고도 정책 결과를 확인할 수 있다.
--    함수는 잘 컴파일됐지만, 돌려주는 술어의 컬럼명(dept_no)이 틀렸다. 조회 시점에 ORA-28113이 남.
@END

@P [8] 트레이스로 원인 찾기
@CODE
[oracle@oel7v9 ~]$ cd /u01/app/oracle/diag/rdbms/orcl/orcl/trace
[oracle@oel7v9 trace]$ grep -l 'D05_ROW_POL' $(ls -t *.trc | head -30) | head -1
orcl_ora_2271.trc
[oracle@oel7v9 trace]$ grep -h -A2 -B1 'dept_no' $(grep -l 'D05_ROW_POL' $(ls -t *.trc | head -30) | head -1) | head -12
RLS view  :
SELECT  "EMPLOYEE_ID","LAST_NAME","DEPARTMENT_ID","SALARY" FROM "D05_OWN"."EMP"   "EMP" WHERE (dept_no = SYS_CONTEXT('D05_CTX', 'DEPT'))
ORA-00904: "DEPT_NO": invalid identifier
-------------------------------------------------------------

-- ★ ORA-28113이 나면 서버 프로세스가 트레이스를 쓴다. 정책 이름으로 찾으면 술어가 붙은 최종 문장(RLS view)과 실제 원인 ORA-00904가 함께 나온다.
--    사용자에게 보이는 오류는 ORA-28113 하나뿐이라, 원인 확인은 DBA 몫이다.
@END

@P [9] 술어 복구
@CODE
SQL> CONNECT d05_sec/d05_sec
Connected.
D05_SEC@orcl> CREATE OR REPLACE FUNCTION row_pred (p_schema VARCHAR2, p_object VARCHAR2)
  2  RETURN VARCHAR2 AS
  3  BEGIN
  4    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('D05_KIM', 'D05_LEE') THEN
  5      RETURN 'department_id = SYS_CONTEXT(''D05_CTX'', ''DEPT'')';
  6    END IF;
  7    RETURN NULL;
  8  END;
  9  /

Function created.

D05_SEC@orcl> CONNECT d05_kim/d05_kim
Connected.
D05_KIM@orcl> SELECT COUNT(*) FROM d05_own.emp;

  COUNT(*)
----------
        45

1 row selected.

-- ★ 정책을 다시 등록하지 않아도 된다. 정책은 함수 이름만 가리키므로 함수만 고치면 다음 파싱부터 바로 반영됨.
@END

@P [10] 정리와 확인
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_RLS.DROP_POLICY('D05_OWN', 'EMP', 'D05_SAL_POL');
  3    DBMS_RLS.DROP_POLICY('D05_OWN', 'EMP', 'D05_ROW_POL');
  4  END;
  5  /

PL/SQL procedure successfully completed.

SYS@orcl> DROP CONTEXT d05_ctx;

Context dropped.

SYS@orcl> DROP USER d05_kim CASCADE;

User dropped.

SYS@orcl> DROP USER d05_lee CASCADE;

User dropped.

SYS@orcl> DROP USER d05_sec CASCADE;

User dropped.

SYS@orcl> DROP USER d05_own CASCADE;

User dropped.

SYS@orcl> SELECT COUNT(*) FROM dba_policies WHERE object_owner = 'D05_OWN';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_context WHERE namespace = 'D05_CTX';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'D05%';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_triggers WHERE owner = 'D05_SEC';

  COUNT(*)
----------
         0

1 row selected.

-- ★ 컨텍스트는 스키마 객체가 아니어서 DROP USER CASCADE로 지워지지 않는다. 따로 DROP CONTEXT 해야 한다.
--    트리거는 소유자 D05_SEC와 함께 지워졌다.
@END

@H3 05.4  정리와 확인 포인트
@B 컨텍스트는 신뢰 패키지로만 바뀐다. 위조 시도는 ORA-01031이고 값은 유지됐다.
@B INSERT를 포함하는 정책은 update_check => TRUE가 필수다(없으면 ORA-28104). 술어를 벗어나는 변경은 ORA-28115로 막힌다.
@B 범위 밖 UPDATE·DELETE는 오류 없이 0건으로 끝난다. 응용 프로그램이 처리 건수를 확인하지 않으면 실패를 알아채지 못함.
@B ALL_ROWS 컬럼 정책은 행 수를 유지하고 값만 NULL로 만든다. 집계나 보고서가 NULL을 0으로 오해하지 않는지 확인한다.
@B 술어 오류는 조회 시점에 ORA-28113으로 드러난다. 원인은 트레이스의 RLS view 문장에서 찾고, 운영 반영 전에는 대상 계정으로 실제 조회를 한 번 돌려 본다.
@H2 실습 06  Data Redaction으로 조회 결과 가리기
@TBL
항목 | 내용
목표 | 한 정책에 FULL·REGEXP·PARTIAL 리댁션을 묶고, 급여 컬럼만 역할 기반 정책 식으로 따로 통제한다. 리댁션이 막지 못하는 경로를 직접 확인한다.
소요 | 40분
접속 | SYS, D06_SEC(정책 관리자), D06_APP(일반 응용 계정), D06_PAY(급여 담당, D06_PAYROLL 역할)
변경 | 사용자 4개, 역할 1개, 리댁션 정책 1개, 이름 붙은 정책 식 1개. 마지막 단계에서 모두 지움
@END

@H3 06.1  실습 전에 — 리댁션은 결과를 바꿀 뿐 데이터 접근을 막지 않는다
@B Data Redaction은 질의 결과가 클라이언트로 나가기 직전에 컬럼 값을 바꾼다. 블록, 버퍼 캐시, 언두, 리두에는 원래 값이 그대로 있다. 권한이 있는 사용자는 실제 값으로 계산함.
@B 이 때문에 WHERE, ORDER BY, GROUP BY는 실제 값으로 평가된다. `WHERE salary > 7000`을 조건만 바꿔 가며 반복하면 가려진 값을 좁혀 갈 수 있다. 리댁션은 화면 노출을 줄이는 장치이고, 접근 통제는 VPD와 권한으로 따로 한다.
@B 테이블 하나에 정책은 하나만 만들 수 있다. 컬럼은 ALTER_POLICY의 ADD_COLUMN으로 늘린다. 정책의 expression은 모든 컬럼에 공통으로 적용된다.
@B 컬럼마다 다른 조건이 필요하면 이름 붙은 정책 식을 쓴다(12.2부터). CREATE_POLICY_EXPRESSION으로 식을 만들고 APPLY_POLICY_EXPR_TO_COL로 특정 컬럼에 붙인다.
@B 리댁션 유형은 출력 형태에 따라 고른다.
@TBL
유형 | 결과 | 적합한 데이터
FULL | 숫자 0, 문자 공백, 날짜 0001-01-01 | 급여처럼 값 전체를 숨길 때
PARTIAL | 고정 위치의 일부 문자만 치환 | 카드 번호, 고정 형식 날짜
REGEXP | 정규식 패턴 치환 | 주민번호, 전화번호, 이메일
RANDOM | 같은 형식의 임의 값 | 시험 데이터 노출
NULLIFY | NULL | 값 존재 자체를 숨길 때
@END
@B expression에는 SYS_CONTEXT로 읽는 세션 정보를 쓴다. 19.3에서 일반 사용자 함수를 넣으면 ORA-28088(unsupported PL/SQL function)로 거부됐다(원 교안 8장 실습 03). 역할 기반 조건 `SYS_CONTEXT('SYS_SESSION_ROLES', '역할') = 'FALSE'`는 SET ROLE로 역할이 꺼지면 바로 리댁션 대상이 됨.
@B FULL 리댁션의 숫자 0, 날짜 0001-01-01 같은 값은 REDACTION_VALUES_FOR_TYPE_FULL 뷰에 있다. UPDATE_FULL_REDACTION_VALUES로 바꿀 수 있지만 DB 전체 정책에 한꺼번에 적용된다.
@B 정책은 DISABLE_POLICY·ENABLE_POLICY로 끄고 켤 수 있다. 꺼진 동안의 조회는 원래 값을 돌려주므로, 정책 변경 호출을 감사 대상으로 둔다.
@B 리댁션은 조회 결과에만 작용한다. UPDATE·DELETE 권한이 있는 사용자는 가려진 값을 가진 행을 조건으로 찾아 그대로 바꿀 수 있다. 쓰기 권한은 리댁션과 별개로 최소화한다.
@B 리댁션된 컬럼을 CREATE TABLE AS SELECT나 INSERT ... SELECT로 옮기면 ORA-28081로 거부된다. 원래 값이 가려지지 않은 채 다른 테이블로 새는 것을 막는 장치다.
@B DBMS_REDACT는 PUBLIC에 실행 권한이 없다. 정책 관리자에게 EXECUTE를 따로 주고, 딕셔너리 뷰(REDACTION_COLUMNS 등)를 보려면 SELECT_CATALOG_ROLE 같은 조회 권한도 필요하다.
@NOTE 면제 경로
SYS와 EXEMPT REDACTION POLICY 보유자에게는 리댁션이 적용되지 않는다. 19c 기본 상태에서 이 권한은 EXP_FULL_DATABASE 역할에 들어 있어 Data Pump 내보내기 계정은 원래 값을 덤프에 담는다. 이 역할 부여 현황을 함께 점검한다.
@END

@H3 06.2  진행 순서
@TBL
단계 | 하는 일 | 확인할 것
[1] 준비 — 고객 테이블과 계정 | 소유자·정책 관리자·응용·급여 담당 계정, 역할, 고객 3행 | D06_PAY에 D06_PAYROLL 기본 역할
[2] 실행 권한과 첫 정책 | 권한 없이 ADD_POLICY, EXECUTE 부여 후 재시도 | PLS-00201 후 성공
[3] 컬럼 추가 — REGEXP·PARTIAL | SSN·PHONE·EMAIL은 REGEXP, CARD_NO·JOIN_DATE는 PARTIAL로 추가 | 딕셔너리 조회 ORA-00942 후 6개 컬럼
[4] 급여만 따로 — 이름 붙은 정책 식 | 역할 기반 정책 식 생성, SALARY 컬럼에 적용 | REDACTION_EXPRESSIONS에 식 1개
[5] 사용자별 결과 | D06_APP, D06_PAY 조회, SET ROLE NONE 후 재조회 | 급여만 차이, 역할을 끄면 0
[6] 리댁션의 한계 | 급여 조건 검색, 급여 정렬, CTAS | 조건·정렬은 실제 값, CTAS는 ORA-28081
[7] 면제 권한과 점검 | EXEMPT REDACTION POLICY 부여·회수, 권한 보유자 조회 | 면제 시 원래 값, 기본 보유자 EXP_FULL_DATABASE
[8] 정리와 확인 | 정책·정책 식·사용자·역할 삭제 | 정책 0, 정책 식 0, 사용자 0
@END

@H3 06.3  실습 스크립트

@P [1] 준비 — 고객 테이블과 계정
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d06_own IDENTIFIED BY d06_own QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d06_sec IDENTIFIED BY d06_sec;

User created.

SYS@orcl> CREATE USER d06_app IDENTIFIED BY d06_app QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d06_pay IDENTIFIED BY d06_pay;

User created.

SYS@orcl> CREATE ROLE d06_payroll;

Role created.

SYS@orcl> GRANT CREATE SESSION TO d06_own, d06_sec, d06_app, d06_pay;

Grant succeeded.

SYS@orcl> GRANT CREATE TABLE TO d06_app;

Grant succeeded.

SYS@orcl> GRANT d06_payroll TO d06_pay;

Grant succeeded.

SYS@orcl> CREATE TABLE d06_own.customers (
  2    id        NUMBER PRIMARY KEY,
  3    name      VARCHAR2(20),
  4    ssn       VARCHAR2(14),
  5    phone     VARCHAR2(13),
  6    email     VARCHAR2(40),
  7    card_no   VARCHAR2(19),
  8    salary    NUMBER,
  9    join_date DATE);

Table created.

SYS@orcl> INSERT INTO d06_own.customers VALUES (1, 'Kim', '900101-1234567', '010-1111-2222', 'kim.minsu@itwill.co.kr', '4518-1234-5678-9012', 5200, DATE '2019-03-02');

1 row created.

SYS@orcl> INSERT INTO d06_own.customers VALUES (2, 'Lee', '850515-2345678', '010-3333-4444', 'lee@example.com', '5321-9876-5432-1098', 7400, DATE '2016-07-15');

1 row created.

SYS@orcl> INSERT INTO d06_own.customers VALUES (3, 'Park', '920303-1567890', '010-5555-6666', 'park.j@itwill.co.kr', '3714-4963-5398-4310', 9100, DATE '2021-11-30');

1 row created.

SYS@orcl> COMMIT;

Commit complete.

SYS@orcl> GRANT SELECT ON d06_own.customers TO d06_app, d06_pay;

Grant succeeded.

-- ★ 정책 관리자 D06_SEC에는 데이터 객체 권한이 없다. 리댁션 정책은 대상 테이블 SELECT 권한 없이 만들 수 있다.
@END

@P [2] 실행 권한과 첫 정책
@CODE
SQL> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> BEGIN
  2    DBMS_REDACT.ADD_POLICY(
  3      object_schema => 'D06_OWN',
  4      object_name   => 'CUSTOMERS',
  5      policy_name   => 'D06_CUST_RED',
  6      column_name   => 'SALARY',
  7      function_type => DBMS_REDACT.FULL,
  8      expression    => '1=1');
  9  END;
 10  /
    function_type => DBMS_REDACT.FULL,
                     *
ERROR at line 7:
ORA-06550: line 7, column 22:
PLS-00201: identifier 'DBMS_REDACT' must be declared
ORA-06550: line 2, column 3:
PL/SQL: Statement ignored


D06_SEC@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> GRANT EXECUTE ON DBMS_REDACT TO d06_sec;

Grant succeeded.

SYS@orcl> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> BEGIN
  2    DBMS_REDACT.ADD_POLICY(
  3      object_schema => 'D06_OWN',
  4      object_name   => 'CUSTOMERS',
  5      policy_name   => 'D06_CUST_RED',
  6      column_name   => 'SALARY',
  7      function_type => DBMS_REDACT.FULL,
  8      expression    => '1=1');
  9  END;
 10  /

PL/SQL procedure successfully completed.

-- ★ DBMS_REDACT는 PUBLIC 실행 권한이 없어 PLS-00201로 실패했다. EXECUTE ON DBMS_REDACT만 주자 다른 스키마 테이블에 정책이 만들어졌다.
--    expression '1=1'은 면제 사용자를 뺀 모든 세션에 리댁션을 적용한다.
@END

@P [3] 컬럼 추가 — REGEXP·PARTIAL
@CODE
SQL> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> BEGIN
  2    DBMS_REDACT.ALTER_POLICY(
  3      object_schema         => 'D06_OWN',
  4      object_name           => 'CUSTOMERS',
  5      policy_name           => 'D06_CUST_RED',
  6      action                => DBMS_REDACT.ADD_COLUMN,
  7      column_name           => 'SSN',
  8      function_type         => DBMS_REDACT.REGEXP,
  9      regexp_pattern        => '([0-9]{6})-([0-9])([0-9]{6})',
 10      regexp_replace_string => '\1-\2******');
 11    DBMS_REDACT.ALTER_POLICY(
 12      object_schema         => 'D06_OWN',
 13      object_name           => 'CUSTOMERS',
 14      policy_name           => 'D06_CUST_RED',
 15      action                => DBMS_REDACT.ADD_COLUMN,
 16      column_name           => 'PHONE',
 17      function_type         => DBMS_REDACT.REGEXP,
 18      regexp_pattern        => '([0-9]{3})-([0-9]{4})-([0-9]{4})',
 19      regexp_replace_string => '\1-****-\3');
 20    DBMS_REDACT.ALTER_POLICY(
 21      object_schema         => 'D06_OWN',
 22      object_name           => 'CUSTOMERS',
 23      policy_name           => 'D06_CUST_RED',
 24      action                => DBMS_REDACT.ADD_COLUMN,
 25      column_name           => 'EMAIL',
 26      function_type         => DBMS_REDACT.REGEXP,
 27      regexp_pattern        => DBMS_REDACT.RE_PATTERN_EMAIL_ADDRESS,
 28      regexp_replace_string => DBMS_REDACT.RE_REDACT_EMAIL_NAME);
 29    DBMS_REDACT.ALTER_POLICY(
 30      object_schema       => 'D06_OWN',
 31      object_name         => 'CUSTOMERS',
 32      policy_name         => 'D06_CUST_RED',
 33      action              => DBMS_REDACT.ADD_COLUMN,
 34      column_name         => 'CARD_NO',
 35      function_type       => DBMS_REDACT.PARTIAL,
 36      function_parameters => DBMS_REDACT.REDACT_CCN16_F12);
 37    DBMS_REDACT.ALTER_POLICY(
 38      object_schema       => 'D06_OWN',
 39      object_name         => 'CUSTOMERS',
 40      policy_name         => 'D06_CUST_RED',
 41      action              => DBMS_REDACT.ADD_COLUMN,
 42      column_name         => 'JOIN_DATE',
 43      function_type       => DBMS_REDACT.PARTIAL,
 44      function_parameters => 'm1d1Y');
 45  END;
 46  /

PL/SQL procedure successfully completed.

D06_SEC@orcl> COL column_name FOR a10
D06_SEC@orcl> COL function_type FOR a22
D06_SEC@orcl> COL function_parameters FOR a40
D06_SEC@orcl> SELECT column_name, function_type, function_parameters FROM redaction_columns
  2   WHERE object_owner = 'D06_OWN' ORDER BY column_name;
SELECT column_name, function_type, function_parameters FROM redaction_columns
                                                            *
ERROR at line 1:
ORA-00942: table or view does not exist


D06_SEC@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> GRANT SELECT_CATALOG_ROLE TO d06_sec;

Grant succeeded.

SYS@orcl> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> COL column_name FOR a10
D06_SEC@orcl> COL function_type FOR a22
D06_SEC@orcl> COL function_parameters FOR a40
D06_SEC@orcl> SELECT column_name, function_type, function_parameters FROM redaction_columns
  2   WHERE object_owner = 'D06_OWN' ORDER BY column_name;

COLUMN_NAM FUNCTION_TYPE          FUNCTION_PARAMETERS
---------- ---------------------- ----------------------------------------
CARD_NO    PARTIAL REDACTION      VVVVFVVVVFVVVVFVVVV,VVVV-VVVV-VVVV-VVVV,
                                  *,1,12

EMAIL      REGEXP REDACTION
JOIN_DATE  PARTIAL REDACTION      m1d1Y
PHONE      REGEXP REDACTION
SALARY     FULL REDACTION
SSN        REGEXP REDACTION

6 rows selected.

-- ★ REDACTION_COLUMNS 조회가 ORA-00942였다. 정책을 만드는 권한과 딕셔너리를 보는 권한은 별개다. SELECT_CATALOG_ROLE을 준 뒤 보였다.
--    CARD_NO에 쓴 REDACT_CCN16_F12는 '입력 형식,출력 형식,치환 문자,시작,끝' 다섯 항목 문자열 상수다.
--    REGEXP 컬럼은 FUNCTION_PARAMETERS가 비고, 패턴은 REGEXP_PATTERN 컬럼에 따로 저장된다.
@END

@P [4] 급여만 따로 — 이름 붙은 정책 식
@CODE
SQL> CONNECT d06_sec/d06_sec
Connected.
D06_SEC@orcl> BEGIN
  2    DBMS_REDACT.CREATE_POLICY_EXPRESSION(
  3      policy_expression_name        => 'D06_NOT_PAYROLL',
  4      expression                    => 'SYS_CONTEXT(''SYS_SESSION_ROLES'', ''D06_PAYROLL'') = ''FALSE''',
  5      policy_expression_description => 'D06_PAYROLL role holders see salary');
  6    DBMS_REDACT.APPLY_POLICY_EXPR_TO_COL(
  7      object_schema          => 'D06_OWN',
  8      object_name            => 'CUSTOMERS',
  9      column_name            => 'SALARY',
 10      policy_expression_name => 'D06_NOT_PAYROLL');
 11  END;
 12  /

PL/SQL procedure successfully completed.

D06_SEC@orcl> COL policy_expression_name FOR a16
D06_SEC@orcl> COL expression FOR a60
D06_SEC@orcl> SELECT policy_expression_name, expression FROM redaction_expressions WHERE policy_expression_name LIKE 'D06%';

POLICY_EXPRESSIO EXPRESSION
---------------- ------------------------------------------------------------
D06_NOT_PAYROLL  SYS_CONTEXT('SYS_SESSION_ROLES', 'D06_PAYROLL') = 'FALSE'

1 row selected.

-- ★ SALARY만 정책 식 D06_NOT_PAYROLL을 따르고, 나머지 컬럼은 정책 기본 식 1=1을 그대로 따른다.
--    19.3에서는 EXECUTE ON DBMS_REDACT만으로 정책 식이 만들어졌다. 최신 RU(19.32 이후) 문서는 정책 식 서브프로그램에 CREATE ANY TABLE을 추가로 요구한다.
@END

@P [5] 사용자별 결과
@CODE
SQL> CONNECT d06_app/d06_app
Connected.
D06_APP@orcl> ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

Session altered.

D06_APP@orcl> COL name FOR a8
D06_APP@orcl> COL ssn FOR a14
D06_APP@orcl> COL phone FOR a13
D06_APP@orcl> COL email FOR a22
D06_APP@orcl> COL card_no FOR a19
D06_APP@orcl> SELECT name, ssn, phone, email, card_no, salary, join_date FROM d06_own.customers ORDER BY id;

NAME     SSN            PHONE         EMAIL                  CARD_NO                 SALARY JOIN_DATE
-------- -------------- ------------- ---------------------- ------------------- ---------- ----------
Kim      900101-1****** 010-****-2222 xxxx@itwill.co.kr      ****-****-****-9012          0 2019-01-01
Lee      850515-2****** 010-****-4444 xxxx@example.com       ****-****-****-1098          0 2016-01-01
Park     920303-1****** 010-****-6666 xxxx@itwill.co.kr      ****-****-****-4310          0 2021-01-01

3 rows selected.

D06_APP@orcl> CONNECT d06_pay/d06_pay
Connected.
D06_PAY@orcl> ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

Session altered.

D06_PAY@orcl> COL name FOR a8
D06_PAY@orcl> COL ssn FOR a14
D06_PAY@orcl> COL phone FOR a13
D06_PAY@orcl> COL email FOR a22
D06_PAY@orcl> COL card_no FOR a19
D06_PAY@orcl> SELECT name, ssn, phone, email, card_no, salary, join_date FROM d06_own.customers ORDER BY id;

NAME     SSN            PHONE         EMAIL                  CARD_NO                 SALARY JOIN_DATE
-------- -------------- ------------- ---------------------- ------------------- ---------- ----------
Kim      900101-1****** 010-****-2222 xxxx@itwill.co.kr      ****-****-****-9012       5200 2019-01-01
Lee      850515-2****** 010-****-4444 xxxx@example.com       ****-****-****-1098       7400 2016-01-01
Park     920303-1****** 010-****-6666 xxxx@itwill.co.kr      ****-****-****-4310       9100 2021-01-01

3 rows selected.

D06_PAY@orcl> SET ROLE NONE;

Role set.

D06_PAY@orcl> SELECT name, salary FROM d06_own.customers ORDER BY id;

NAME         SALARY
-------- ----------
Kim               0
Lee               0
Park              0

3 rows selected.

-- ★ 두 사용자 모두 주민번호 뒷자리, 전화 가운데 자리, 이메일 이름, 카드 앞 12자리가 가려졌다. 입사일은 연도만 남고 1월 1일이 됐다.
--    급여는 D06_PAY에게만 보였다. 같은 세션에서 SET ROLE NONE을 하자 바로 0으로 바뀌었다. 역할 조건은 문장 실행 때마다 평가된다.
@END

@P [6] 리댁션의 한계
@CODE
SQL> CONNECT d06_app/d06_app
Connected.
D06_APP@orcl> SELECT name, salary FROM d06_own.customers WHERE salary > 7000 ORDER BY id;

NAME                     SALARY
-------------------- ----------
Lee                           0
Park                          0

2 rows selected.

D06_APP@orcl> SELECT name FROM d06_own.customers ORDER BY salary DESC;

NAME
--------------------
Park
Lee
Kim

3 rows selected.

D06_APP@orcl> CREATE TABLE cust_copy AS SELECT * FROM d06_own.customers;
CREATE TABLE cust_copy AS SELECT * FROM d06_own.customers
                                 *
ERROR at line 1:
ORA-28081: Insufficient privileges - the command references a redacted object.


D06_APP@orcl> CREATE TABLE cust_copy AS SELECT id, name FROM d06_own.customers;

Table created.

D06_APP@orcl> SELECT COUNT(*) FROM cust_copy;

  COUNT(*)
----------
         3

1 row selected.

-- ★ 급여가 0으로 보이는데도 salary > 7000 조건이 Lee, Park 두 행을 정확히 골랐다. ORDER BY salary DESC도 실제 급여 순서(Park, Lee, Kim)다.
--    전체 컬럼 CTAS는 ORA-28081로 막혔다. 리댁션 컬럼을 뺀 CTAS는 성공했다.
--    가려진 값을 추론으로 알아내는 것을 막아야 하면 리댁션 대신 VPD 컬럼 정책이나 권한 회수가 필요하다.
@END

@P [7] 면제 권한과 점검
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> GRANT EXEMPT REDACTION POLICY TO d06_app;

Grant succeeded.

SYS@orcl> CONNECT d06_app/d06_app
Connected.
D06_APP@orcl> COL ssn FOR a14
D06_APP@orcl> SELECT name, ssn, salary FROM d06_own.customers ORDER BY id;

NAME                 SSN                SALARY
-------------------- -------------- ----------
Kim                  900101-1234567       5200
Lee                  850515-2345678       7400
Park                 920303-1567890       9100

3 rows selected.

D06_APP@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> REVOKE EXEMPT REDACTION POLICY FROM d06_app;

Revoke succeeded.

SYS@orcl> COL grantee FOR a24
SYS@orcl> COL privilege FOR a24
SYS@orcl> SELECT grantee, privilege FROM dba_sys_privs WHERE privilege = 'EXEMPT REDACTION POLICY' ORDER BY 1;

GRANTEE                  PRIVILEGE
------------------------ ------------------------
EXP_FULL_DATABASE        EXEMPT REDACTION POLICY

1 row selected.

SYS@orcl> COL policy_name FOR a14
SYS@orcl> COL expression FOR a10
SYS@orcl> SELECT object_name, policy_name, expression, enable FROM redaction_policies WHERE object_owner = 'D06_OWN';

OBJECT_NAME
------------------------------------------------------------------------------------------------------------------------
POLICY_NAME    EXPRESSION ENA
-------------- ---------- ---
CUSTOMERS
D06_CUST_RED   1=1        YES


1 row selected.

-- ★ 면제 권한을 받자 정책은 그대로인데 원래 값이 모두 보였다. 정책 수정 없이 권한 하나로 우회된다.
--    기본 상태에서 이 권한을 가진 것은 EXP_FULL_DATABASE 역할 하나다. 내보내기 계정 관리가 곧 리댁션 관리다.
@END

@P [8] 정리와 확인
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_REDACT.DROP_POLICY('D06_OWN', 'CUSTOMERS', 'D06_CUST_RED');
  3    DBMS_REDACT.DROP_POLICY_EXPRESSION('D06_NOT_PAYROLL');
  4  END;
  5  /

PL/SQL procedure successfully completed.

SYS@orcl> DROP USER d06_app CASCADE;

User dropped.

SYS@orcl> DROP USER d06_pay CASCADE;

User dropped.

SYS@orcl> DROP USER d06_sec CASCADE;

User dropped.

SYS@orcl> DROP USER d06_own CASCADE;

User dropped.

SYS@orcl> DROP ROLE d06_payroll;

Role dropped.

SYS@orcl> SELECT COUNT(*) FROM redaction_policies;

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM redaction_expressions;

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'D06%';

  COUNT(*)
----------
         0

1 row selected.

-- ★ 정책 식은 정책을 지운 뒤 따로 DROP_POLICY_EXPRESSION 한다. 특정 스키마에 속하지 않아 DROP USER로 지워지지 않는다.
@END

@H3 06.4  정리와 확인 포인트
@B 리댁션은 출력만 바꾼다. WHERE·ORDER BY는 실제 값으로 동작해 반복 질의로 값을 추론할 수 있다.
@B 컬럼마다 다른 조건은 이름 붙은 정책 식으로 준다. 역할 조건은 SET ROLE에 즉시 반응한다.
@B CTAS·INSERT SELECT로 리댁션 컬럼을 옮기면 ORA-28081이 난다. 응용 배치가 이 오류로 멈추지 않는지 반영 전에 점검한다.
@B 정책 관리자에게는 EXECUTE ON DBMS_REDACT와 딕셔너리 조회 권한을 함께 준다.
@B EXEMPT REDACTION POLICY와 EXP_FULL_DATABASE 보유자는 리댁션 밖에 있다. 정기 권한 점검 목록에 넣는다.
@H2 실습 07  DBMS_CRYPTO로 컬럼 암호화 패키지 만들기
@TBL
항목 | 내용
목표 | 키 보관·암호화 코드·응용 데이터를 세 계정으로 나눈다. 무작위 IV를 쓰는 AES256-CBC 패키지와 HMAC 검색 컬럼을 만들고, 키 접근과 변조가 어떻게 실패하는지 확인한다.
소요 | 40분
접속 | SYS, D07_KEY(키 테이블 소유), D07_SEC(암호화 패키지 소유), D07_APP(응용 데이터 소유)
변경 | 사용자 3개와 그 스키마 객체(키 테이블, 패키지, 고객 테이블). 마지막 단계에서 모두 지움
@END

@H3 07.1  실습 전에 — 암호화보다 어려운 것은 키를 어디에 두느냐다
@B DBMS_CRYPTO는 알고리즘만 제공한다. 키 생성·보관·교체, IV 관리, 저장 형식은 모두 설계자 몫이다. 키 관리를 DB가 대신 맡는 방식은 실습 08의 TDE다.
@B 19.3의 DBMS_CRYPTO에는 ENCRYPT·DECRYPT·HASH·MAC·RANDOMBYTES·RANDOMINTEGER·RANDOMNUMBER 7개 서브프로그램이 있다. PUBLIC 실행 권한이 없어서 패키지 소유자에게 직접 EXECUTE를 준다(정의자 권한 패키지는 역할로 받은 권한을 쓰지 못함).
@B 암호문은 RAW로 저장한다. VARCHAR2에 넣으면 문자 집합 변환 중 바이트가 바뀌어 복호화가 ORA-28817로 실패할 수 있다(원 교안 9장 실습 02).
@B 키 길이는 알고리즘이 정한다. AES256은 32바이트이며, 짧으면 ORA-28234가 남. 키는 RANDOMBYTES로 만들고 코드에 적지 않는다. 소스에 적힌 키는 DBA_SOURCE에서 누구나 읽는다.
@B 같은 평문에 같은 IV를 쓰면 같은 암호문이 나와 빈도 분석이 가능하다. 값마다 RANDOMBYTES(16)로 IV를 만들고 암호문 앞에 붙여 저장한다. 대신 암호문으로는 등가 검색을 할 수 없다.
@B HASH와 MAC은 다르다. HASH는 키가 없어 누구나 같은 결과를 만든다. 주민번호처럼 경우의 수가 적은 값은 사전 대입으로 역산되므로 검색용 값으로 쓰지 않는다.
@B 검색이 필요한 컬럼은 별도 키로 만든 HMAC 값을 함께 저장한다. 같은 평문은 같은 MAC이 되므로 인덱스를 걸어 등가 검색에 쓴다. 범위 검색과 LIKE는 지원되지 않음.
@B CBC 모드 자체에는 무결성 검사가 없다. 암호문 일부를 바꾸면 패딩 검사에 걸려 ORA-28817이 나는 경우가 많다. 하지만 패딩이 우연히 맞으면 깨진 평문이 오류 없이 돌아온다. 변조를 확실히 잡으려면 암호문 전체에 MAC을 따로 계산해 비교한다.
@B 암호화한 컬럼은 범위 검색, 정렬, 집계를 잃는다. 응용 SQL에서 그 컬럼에 어떤 연산이 걸리는지 먼저 조사하고 대상을 정한다.
@B 함수형 ENCRYPT·DECRYPT는 RAW만 받는다. CLOB·BLOB은 프로시저형 오버로드를 쓴다(함수형에 넘기면 PLS-00306, 원 교안 9장 실습 05).
@B 키 교체는 새 키로 다시 암호화하는 작업이다. 암호문과 함께 key_id를 저장해 두면 키 버전을 나눠 단계적으로 바꿀 수 있다. 이번 실습은 key_id 1 하나만 쓴다.
@B 이번 패키지는 호출마다 키 테이블을 한 번씩 읽는다. 대량 처리에서는 패키지 변수에 키를 캐시하기도 하지만, 그만큼 세션 메모리에 키가 머무는 시간이 길어진다.
@TBL
계정 | 가진 것 | 가지지 않은 것
D07_KEY | 키 테이블 | 패키지 실행 권한
D07_SEC | 패키지, DBMS_CRYPTO 실행, 키 테이블 SELECT | 응용 데이터
D07_APP | 고객 테이블, 패키지 실행 권한 | 키 테이블, DBMS_CRYPTO
@END
@NOTE 이 구성이 막지 못하는 것
DBA와 SELECT ANY TABLE 보유자는 키 테이블을 읽을 수 있다. 키 테이블을 TDE 암호화 테이블스페이스에 두면 파일·백업 유출에는 대비되지만, 권한 있는 내부자는 막지 못한다. 이 경우는 Database Vault 같은 별도 통제가 필요하다.
@END

@H3 07.2  진행 순서
@TBL
단계 | 하는 일 | 확인할 것
[1] 준비 — 세 계정 분리 | 키·패키지·응용 소유 계정 생성, D07_SEC에만 DBMS_CRYPTO 실행 권한 | D07_APP의 직접 호출 ORA-00904
[2] 키 길이 오류와 키 테이블 | 16바이트 키로 AES256 시도, SYS가 32바이트 키 2개 생성 | ORA-28234, 키 길이 32·32
[3] 암호화 패키지 | enc·dec·mac 함수, 무작위 IV를 암호문 앞에 붙이는 형식 | 패키지 생성, D07_APP에 EXECUTE만 부여
[4] 응용 테이블에 저장 | RAW 컬럼에 암호문과 MAC 저장, MAC 컬럼 인덱스 | 같은 평문 두 행의 암호문은 다르고 MAC은 같음
[5] 복호화와 등가 검색 | 패키지로 복호화, MAC 검색, 암호문 검색 | MAC 검색 2행, 암호문 검색 0행
[6] 오류 흐름 — 키 접근과 변조 | 키 테이블 직접 조회, 암호문 마지막 바이트 변조 후 복호화 | ORA-00942, ORA-28817, 롤백 후 정상
[7] 키 노출 점검 | 응용 계정이 볼 수 있는 소스, 관련 객체 권한 조회 | PACKAGE(명세)만 보임, 권한 3건
[8] 정리와 확인 | 세 사용자 CASCADE 삭제 | D07% 사용자 0
@END

@H3 07.3  실습 스크립트

@P [1] 준비 — 세 계정 분리
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d07_key IDENTIFIED BY d07_key QUOTA 5M ON users;

User created.

SYS@orcl> CREATE USER d07_sec IDENTIFIED BY d07_sec;

User created.

SYS@orcl> CREATE USER d07_app IDENTIFIED BY d07_app QUOTA 10M ON users;

User created.

SYS@orcl> GRANT CREATE SESSION, CREATE TABLE TO d07_key, d07_app;

Grant succeeded.

SYS@orcl> GRANT CREATE SESSION, CREATE PROCEDURE TO d07_sec;

Grant succeeded.

SYS@orcl> GRANT EXECUTE ON DBMS_CRYPTO TO d07_sec;

Grant succeeded.

SYS@orcl> CONNECT d07_app/d07_app
Connected.
D07_APP@orcl> SELECT DBMS_CRYPTO.RANDOMBYTES(16) FROM dual;
SELECT DBMS_CRYPTO.RANDOMBYTES(16) FROM dual
       *
ERROR at line 1:
ORA-00904: "DBMS_CRYPTO"."RANDOMBYTES": invalid identifier

-- ★ D07_APP은 DBMS_CRYPTO 실행 권한이 없다. SQL에서 부르자 ORA-00904(invalid identifier)가 났다. PL/SQL 블록에서 불렀다면 PLS-00201이다.
--    권한 없는 객체는 존재하지 않는 것처럼 보고하므로, 이름 오류와 권한 부족을 구분하려면 DBA_TAB_PRIVS부터 본다.
@END

@P [2] 키 길이 오류와 키 테이블
@CODE
SQL> CONNECT d07_sec/d07_sec
Connected.
D07_SEC@orcl> SET SERVEROUTPUT ON
D07_SEC@orcl> DECLARE
  2    v_key RAW(32) := DBMS_CRYPTO.RANDOMBYTES(16);
  3    v_enc RAW(200);
  4  BEGIN
  5    v_enc := DBMS_CRYPTO.ENCRYPT(
  6               src => UTL_I18N.STRING_TO_RAW('test', 'AL32UTF8'),
  7               typ => DBMS_CRYPTO.ENCRYPT_AES256 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_PKCS5,
  8               key => v_key);
  9    DBMS_OUTPUT.PUT_LINE(RAWTOHEX(v_enc));
 10  END;
 11  /
DECLARE
*
ERROR at line 1:
ORA-28234: key length too short
ORA-06512: at "SYS.DBMS_CRYPTO_FFI", line 3
ORA-06512: at "SYS.DBMS_CRYPTO", line 13
ORA-06512: at line 5


D07_SEC@orcl> CONNECT d07_key/d07_key
Connected.
D07_KEY@orcl> CREATE TABLE keys (
  2    key_id   NUMBER PRIMARY KEY,
  3    enc_key  RAW(32) NOT NULL,
  4    mac_key  RAW(32) NOT NULL);

Table created.

D07_KEY@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> INSERT INTO d07_key.keys VALUES (1, DBMS_CRYPTO.RANDOMBYTES(32), DBMS_CRYPTO.RANDOMBYTES(32));

1 row created.

SYS@orcl> COMMIT;

Commit complete.

SYS@orcl> GRANT SELECT ON d07_key.keys TO d07_sec;

Grant succeeded.

SYS@orcl> SELECT key_id, UTL_RAW.LENGTH(enc_key) enc_len, UTL_RAW.LENGTH(mac_key) mac_len FROM d07_key.keys;

    KEY_ID    ENC_LEN    MAC_LEN
---------- ---------- ----------
         1         32         32

1 row selected.

-- ★ 16바이트 키를 AES256에 넣자 ORA-28234: key length too short가 났다.
--    암호화 키와 MAC 키를 따로 만들었다. 하나가 노출돼도 다른 용도로 쓰이지 않는다.
--    키는 SYS가 RANDOMBYTES(32)로 바로 넣어 평문 키가 화면이나 스크립트에 남지 않는다.
@END

@P [3] 암호화 패키지
@CODE
SQL> CONNECT d07_sec/d07_sec
Connected.
D07_SEC@orcl> CREATE OR REPLACE PACKAGE crypto_pkg AS
  2    FUNCTION enc (p_text VARCHAR2) RETURN RAW;
  3    FUNCTION dec (p_raw RAW) RETURN VARCHAR2;
  4    FUNCTION mac (p_text VARCHAR2) RETURN RAW;
  5  END;
  6  /

Package created.

D07_SEC@orcl> CREATE OR REPLACE PACKAGE BODY crypto_pkg AS
  2    c_typ CONSTANT PLS_INTEGER := DBMS_CRYPTO.ENCRYPT_AES256 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_PKCS5;
  3
  4    FUNCTION k (p_col VARCHAR2) RETURN RAW IS
  5      v RAW(32);
  6    BEGIN
  7      IF p_col = 'ENC' THEN
  8        SELECT enc_key INTO v FROM d07_key.keys WHERE key_id = 1;
  9      ELSE
 10        SELECT mac_key INTO v FROM d07_key.keys WHERE key_id = 1;
 11      END IF;
 12      RETURN v;
 13    END;
 14
 15    FUNCTION enc (p_text VARCHAR2) RETURN RAW IS
 16      v_iv RAW(16) := DBMS_CRYPTO.RANDOMBYTES(16);
 17    BEGIN
 18      RETURN UTL_RAW.CONCAT(v_iv,
 19               DBMS_CRYPTO.ENCRYPT(UTL_I18N.STRING_TO_RAW(p_text, 'AL32UTF8'), c_typ, k('ENC'), v_iv));
 20    END;
 21
 22    FUNCTION dec (p_raw RAW) RETURN VARCHAR2 IS
 23    BEGIN
 24      RETURN UTL_I18N.RAW_TO_CHAR(
 25               DBMS_CRYPTO.DECRYPT(UTL_RAW.SUBSTR(p_raw, 17), c_typ, k('ENC'), UTL_RAW.SUBSTR(p_raw, 1, 16)),
 26               'AL32UTF8');
 27    END;
 28
 29    FUNCTION mac (p_text VARCHAR2) RETURN RAW IS
 30    BEGIN
 31      RETURN DBMS_CRYPTO.MAC(UTL_I18N.STRING_TO_RAW(p_text, 'AL32UTF8'), DBMS_CRYPTO.HMAC_SH256, k('MAC'));
 32    END;
 33  END;
 34  /

Package body created.

D07_SEC@orcl> GRANT EXECUTE ON crypto_pkg TO d07_app;

Grant succeeded.

-- ★ enc는 IV(16바이트)와 암호문을 이어 붙여 돌려준다. dec는 앞 16바이트를 IV로 떼어 쓴다.
--    키는 호출마다 키 테이블에서 읽는다. 패키지 소스에는 키 값이 없다.
--    D07_SEC는 정의자 권한으로 키 테이블을 읽으므로, D07_APP은 키 테이블 권한 없이도 암호화·복호화를 할 수 있다.
@END

@P [4] 응용 테이블에 저장
@CODE
SQL> CONNECT d07_app/d07_app
Connected.
D07_APP@orcl> CREATE TABLE customers (
  2    id       NUMBER PRIMARY KEY,
  3    name     VARCHAR2(20),
  4    ssn_enc  RAW(64),
  5    ssn_mac  RAW(32));

Table created.

D07_APP@orcl> CREATE INDEX customers_mac_ix ON customers (ssn_mac);

Index created.

D07_APP@orcl> INSERT INTO customers VALUES (1, 'Kim',  d07_sec.crypto_pkg.enc('900101-1234567'), d07_sec.crypto_pkg.mac('900101-1234567'));

1 row created.

D07_APP@orcl> INSERT INTO customers VALUES (2, 'Lee',  d07_sec.crypto_pkg.enc('850515-2345678'), d07_sec.crypto_pkg.mac('850515-2345678'));

1 row created.

D07_APP@orcl> INSERT INTO customers VALUES (3, 'Kim2', d07_sec.crypto_pkg.enc('900101-1234567'), d07_sec.crypto_pkg.mac('900101-1234567'));

1 row created.

D07_APP@orcl> COMMIT;

Commit complete.

D07_APP@orcl> COL enc_head FOR a34
D07_APP@orcl> COL mac_head FOR a18
D07_APP@orcl> SELECT id, name, UTL_RAW.LENGTH(ssn_enc) len, SUBSTR(RAWTOHEX(ssn_enc), 1, 32) enc_head,
  2         SUBSTR(RAWTOHEX(ssn_mac), 1, 16) mac_head
  3    FROM customers ORDER BY id;

        ID NAME                        LEN ENC_HEAD                           MAC_HEAD
---------- -------------------- ---------- ---------------------------------- ------------------
         1 Kim                          32 5F8A1AAF416584FE1A5367F9B94E92BB   DF4EFE323A18932C
         2 Lee                          32 74F3CD0F2AD5C0B5C8C43FC0F9D19215   00CC9CFA201CB7B7
         3 Kim2                         32 41D69A3766540B74F12DD50E3F5DB193   DF4EFE323A18932C

3 rows selected.

-- ★ Kim과 Kim2는 같은 주민번호다. 암호문 앞부분(IV)부터 완전히 다르고, MAC은 같다.
--    14바이트 평문이 PKCS5 패딩으로 16바이트가 됐고, IV 16바이트를 더해 32바이트로 저장됐다. 컬럼 크기는 (평문을 16바이트 배수로 올린 값 + 16)으로 잡는다.
@END

@P [5] 복호화와 등가 검색
@CODE
SQL> CONNECT d07_app/d07_app
Connected.
D07_APP@orcl> COL ssn FOR a16
D07_APP@orcl> SELECT id, name, d07_sec.crypto_pkg.dec(ssn_enc) ssn FROM customers ORDER BY id;

        ID NAME                 SSN
---------- -------------------- ----------------
         1 Kim                  900101-1234567
         2 Lee                  850515-2345678
         3 Kim2                 900101-1234567

3 rows selected.

D07_APP@orcl> SELECT id, name FROM customers WHERE ssn_mac = d07_sec.crypto_pkg.mac('900101-1234567') ORDER BY id;

        ID NAME
---------- --------------------
         1 Kim
         3 Kim2

2 rows selected.

D07_APP@orcl> SELECT id, name FROM customers WHERE ssn_enc = d07_sec.crypto_pkg.enc('900101-1234567');

no rows selected

-- ★ MAC으로 찾자 같은 주민번호 두 행이 나왔다. 인덱스를 쓸 수 있는 형태다.
--    같은 값을 enc로 다시 암호화해 비교하면 IV가 매번 달라 한 건도 찾지 못한다. 무작위 IV를 쓰는 설계에서 검색은 MAC 컬럼이 맡는다.
@END

@P [6] 오류 흐름 — 키 접근과 변조
@CODE
SQL> CONNECT d07_app/d07_app
Connected.
D07_APP@orcl> COL ssn FOR a16
D07_APP@orcl> SELECT * FROM d07_key.keys;
SELECT * FROM d07_key.keys
                      *
ERROR at line 1:
ORA-00942: table or view does not exist


D07_APP@orcl> UPDATE customers SET ssn_enc = UTL_RAW.OVERLAY('00', ssn_enc, UTL_RAW.LENGTH(ssn_enc)) WHERE id = 2;

1 row updated.

D07_APP@orcl> SELECT id, d07_sec.crypto_pkg.dec(ssn_enc) ssn FROM customers WHERE id = 2;
SELECT id, d07_sec.crypto_pkg.dec(ssn_enc) ssn FROM customers WHERE id = 2
           *
ERROR at line 1:
ORA-28817: PL/SQL function returned an error.
ORA-06512: at "SYS.DBMS_CRYPTO_FFI", line 67
ORA-06512: at "SYS.DBMS_CRYPTO", line 44
ORA-06512: at "D07_SEC.CRYPTO_PKG", line 24


D07_APP@orcl> ROLLBACK;

Rollback complete.

D07_APP@orcl> SELECT id, d07_sec.crypto_pkg.dec(ssn_enc) ssn FROM customers WHERE id = 2;

        ID SSN
---------- ----------------
         2 850515-2345678

1 row selected.

-- ★ D07_APP은 키 테이블을 볼 수 없다(ORA-00942). 패키지 실행은 되는데 키는 못 보는 구성이 목표였다.
--    마지막 바이트를 00으로 바꾸자 패딩 검사가 실패해 ORA-28817이 났다. 스택의 CRYPTO_PKG line 24가 dec 함수의 DECRYPT 호출 위치다.
--    변조된 바이트가 우연히 유효한 패딩이 되면 오류 없이 엉뚱한 값이 나온다. ORA-28817은 무결성 검사가 아니다.
@END

@P [7] 키 노출 점검
@CODE
SQL> CONNECT d07_app/d07_app
Connected.
D07_APP@orcl> COL type FOR a14
D07_APP@orcl> SELECT type, COUNT(*) FROM all_source WHERE owner = 'D07_SEC' AND name = 'CRYPTO_PKG' GROUP BY type;

TYPE             COUNT(*)
-------------- ----------
PACKAGE                 5

1 row selected.

D07_APP@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL grantee FOR a10
SYS@orcl> COL owner FOR a8
SYS@orcl> COL table_name FOR a12
SYS@orcl> COL privilege FOR a10
SYS@orcl> SELECT grantee, owner, table_name, privilege FROM dba_tab_privs
  2   WHERE (owner = 'D07_KEY') OR (table_name IN ('DBMS_CRYPTO', 'CRYPTO_PKG') AND grantee LIKE 'D07%') ORDER BY 1, 3;

GRANTEE    OWNER    TABLE_NAME   PRIVILEGE
---------- -------- ------------ ----------
D07_APP    D07_SEC  CRYPTO_PKG   EXECUTE
D07_SEC    SYS      DBMS_CRYPTO  EXECUTE
D07_SEC    D07_KEY  KEYS         SELECT

3 rows selected.

-- ★ EXECUTE 권한자는 ALL_SOURCE에서 패키지 명세만 본다. 본문(PACKAGE BODY)은 보이지 않는다. 그래도 키는 본문이 아니라 테이블에 있어야 한다. 본문은 DBA_SOURCE에서 보인다.
--    권한은 세 줄뿐이다. 키 테이블 SELECT를 가진 계정은 D07_SEC 하나다.
@END

@P [8] 정리와 확인
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> DROP USER d07_app CASCADE;

User dropped.

SYS@orcl> DROP USER d07_sec CASCADE;

User dropped.

SYS@orcl> DROP USER d07_key CASCADE;

User dropped.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'D07%';

  COUNT(*)
----------
         0

1 row selected.

-- ★ 키 테이블이 지워지면 남은 암호문은 영구히 복호화할 수 없다. 운영에서는 키 테이블 백업을 데이터 백업과 분리해 보관한다.
@END

@H3 07.4  정리와 확인 포인트
@B DBMS_CRYPTO는 PUBLIC 권한이 없다. 패키지 소유자에게 직접 EXECUTE를 주고, 응용 계정에는 패키지 실행 권한만 준다.
@B 키는 RANDOMBYTES로 만들어 별도 스키마 테이블에 둔다. 소스 코드와 응용 계정에서 키가 보이지 않는지 확인한다.
@B 무작위 IV를 쓰면 같은 평문도 암호문이 달라진다. 등가 검색은 별도 키의 HMAC 컬럼으로 한다.
@B ORA-28234는 키 길이, ORA-28817은 키·IV·암호문 불일치다. ORA-28817이 없다고 데이터가 온전한 것은 아니다.
@B 범위 검색·정렬이 필요하거나 응용 수정이 어려우면 TDE(실습 08)를 먼저 검토한다.
@H2 실습 08  TDE 키스토어와 테이블스페이스 암호화
@TBL
항목 | 내용
목표 | 키스토어가 없던 DB에 19c 방식(WALLET_ROOT·TDE_CONFIGURATION)으로 TDE를 구성한다. 테이블스페이스를 새로 만들어 암호화하고 기존 것은 온라인으로 바꾼다. 재기동, auto-login, 마스터 키 교체까지 운영 흐름으로 확인한다
소요 | 50분
접속 | SYS(/ AS SYSDBA, 실습 DB d08tde), oracle OS 계정 셸
변경 | 파라미터 WALLET_ROOT·TDE_CONFIGURATION, 키스토어 디렉터리, 테이블스페이스 D08_ENC·D08_PLAIN, 사용자 D08_APP. 객체는 마지막 단계에서 지우고, 키스토어와 마스터 키 이력은 남는다
@END

@H3 08.1  실습 전에 — 2단 키 구조와 키스토어 상태
@B TDE는 키를 두 단으로 둔다. 데이터를 암호화하는 테이블스페이스 키(컬럼 암호화는 테이블 키)는 DB 안에 저장되고, 그 키를 다시 마스터 키가 암호화한다. 마스터 키는 DB 밖의 키스토어에만 있다.
@B 이 구조 덕분에 마스터 키를 바꿔도 데이터 블록은 다시 쓰지 않는다. 테이블스페이스 키만 새 마스터 키로 다시 감싼다. 데이터 파일과 백업만 빼낸 쪽은 키스토어 없이 복호화할 수 없다.
@B 19c의 키스토어 위치 지정은 두 파라미터로 한다.
@B WALLET_ROOT: 정적 파라미터라 SPFILE에 쓰고 재기동해야 한다. 키스토어는 그 아래 `tde/` 디렉터리에 만들어진다.
@B TDE_CONFIGURATION: 동적 파라미터다. `KEYSTORE_CONFIGURATION=FILE`이면 소프트웨어 키스토어를 쓴다. WALLET_ROOT가 없으면 설정이 거부된다(실습 [2]).
@B 예전 방식인 sqlnet.ora의 ENCRYPTION_WALLET_LOCATION은 19c 문서에서 디프리케이트로 표시된다. 새로 구성하는 DB는 WALLET_ROOT를 쓴다.
@B WALLET_ROOT를 설정한 뒤에는 `CREATE KEYSTORE`에 경로를 적지 않는다. 경로를 적으면 ORA-46633이 난다(교안 10장 실습 02).
@B 상태는 `V$ENCRYPTION_WALLET`에서 읽는다. STATUS와 WALLET_TYPE 두 컬럼이 진단의 출발점이다.
@TBL
STATUS | 뜻 | 다음 조치
NOT_AVAILABLE | 지정 위치에 키스토어 파일이 없음 | CREATE KEYSTORE
OPEN_NO_MASTER_KEY | 열렸지만 마스터 키가 없음 | SET KEY ... WITH BACKUP
OPEN | 마스터 키까지 사용 가능 | 정상
CLOSED | 파일은 있으나 닫힘(재기동 직후 비밀번호 키스토어) | SET KEYSTORE OPEN
@END
@B 비밀번호 키스토어(`ewallet.p12`)는 재기동할 때마다 누군가 열어야 한다. 그동안 암호화 테이블스페이스의 객체는 ORA-28365로 막힌다.
@B auto-login 키스토어(`cwallet.sso`)는 기동 때 자동으로 열린다. LOCAL auto-login은 만든 호스트에서만 열리므로 파일을 복사해 가도 쓸 수 없다.
@B auto-login이 열려 있으면 비밀번호가 필요한 작업(키 교체, 백업)에 `FORCE KEYSTORE`를 붙인다. 붙이지 않으면 ORA-28417이 난다(실습 [12]).
@B `WITH BACKUP`은 키를 바꾸기 직전의 키스토어를 `ewallet_<시각>_<태그>.p12`로 남긴다. 비밀번호 키스토어에서는 생략할 수 없다(생략하면 ORA-46631, 교안 10장 실습 02).
@B 마스터 키는 한 번 활성화되면 그 이력이 DB 안(`V$DATABASE_KEY_INFO`)에 남는다. 암호화 객체를 모두 지워도 이 기록은 그대로다.
@B 그래서 키스토어 파일은 TDE를 그만 쓰더라도 지우지 않는다. 키스토어를 지운 DB는 재기동하다 ORA-28365로 멈출 수 있다(교안 10장 10.8.6 사례).
@B 운영에서는 키스토어를 DB 백업과 다른 매체에 따로 보관한다. RMAN 백업 안의 암호화 데이터 파일은 그 시점의 키스토어가 있어야 복원 후 읽힌다.
@NOTE 실습 DB
키스토어가 한 번도 없던 DB에서 시작해야 [1]~[6]의 흐름이 그대로 재현된다. 측정에는 DBCA로 만든 임시 DB d08tde(non-CDB, 19.3)를 썼다. 데이터 파일은 `/u01/app/oracle/d08data/D08TDE`에 있다. 학습자 환경에서는 경로만 바꾸면 된다.
@END

@H3 08.2  진행 순서
@TBL
단계 | 주제 | 하는 일 | 확인할 것
[1] | 기준 상태 | 키스토어·파라미터·키 정보 조회 | NOT_AVAILABLE, 활성화 안 된 MASTERKEYID
[2~3] | 위치 구성 | WALLET_ROOT 없이 시도 → SPFILE 설정·재기동 | ORA-46693, WRL_PARAMETER의 tde/
[4] | 키스토어 | 생성과 열기 | OPEN_NO_MASTER_KEY
[5~6] | 마스터 키 | 키 없이 암호화 시도 → SET KEY | ORA-28361, MASTERKEY_ACTIVATED=YES
[7~8] | 새 테이블스페이스 | 암호화·일반 각각 만들고 파일을 직접 읽기 | strings 결과 1과 0
[9~10] | 온라인 변환 | 기존 테이블스페이스를 운영 중 암호화 | 파일 이름 유지, strings 0
[11] | 비밀번호 키스토어 재기동 | 열기 전 조회 → 열고 조회 | CLOSED, ORA-28365
[12] | auto-login | LOCAL auto-login 생성 후 재기동 | OPEN / LOCAL_AUTOLOGIN
[13] | 키 교체 | FORCE KEYSTORE로 새 마스터 키 | ORA-28417, 키 2개, 데이터 그대로
[14] | 철거 | 객체 제거 후 남는 것 확인 | 키 이력은 남음
@END

@H3 08.3  실습 스크립트
@P [1] 기준 상태
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> SELECT name, open_mode FROM v$database;

NAME      OPEN_MODE
--------- --------------------
D08TDE    READ WRITE

1 row selected.

SYS@d08tde> COL wrl_parameter FOR a42
SYS@d08tde> COL status FOR a20
SYS@d08tde> COL wallet_type FOR a16
SYS@d08tde> SELECT wrl_parameter, status, wallet_type FROM v$encryption_wallet;

WRL_PARAMETER                              STATUS               WALLET_TYPE
------------------------------------------ -------------------- ----------------
/u01/app/oracle/admin/d08tde/wallet        NOT_AVAILABLE        UNKNOWN

1 row selected.

SYS@d08tde> SHOW PARAMETER wallet_root

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
wallet_root                          string
SYS@d08tde> SHOW PARAMETER tde_configuration

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
tde_configuration                    string
SYS@d08tde> COL masterkeyid FOR a34
SYS@d08tde> SELECT masterkeyid, masterkey_activated FROM v$database_key_info;

MASTERKEYID                        MAS
---------------------------------- ---
2CA567A3FF484F36BF9B7AD99D4B58EC   NO

1 row selected.
-- ★ 키스토어 파일이 없어 NOT_AVAILABLE. WRL_PARAMETER는 DBCA가 만든 기본 위치를 보여 줄 뿐 아직 아무것도 없다.
-- ★ V$DATABASE_KEY_INFO에는 DB 생성 때 정해진 MASTERKEYID가 이미 있지만 MASTERKEY_ACTIVATED=NO다. 활성화는 첫 SET KEY에서 일어난다.
@END

@P [2] WALLET_ROOT 없이 TDE_CONFIGURATION
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> ALTER SYSTEM SET tde_configuration = 'KEYSTORE_CONFIGURATION=FILE' SCOPE = BOTH;
ALTER SYSTEM SET tde_configuration = 'KEYSTORE_CONFIGURATION=FILE' SCOPE = BOTH
*
ERROR at line 1:
ORA-32017: failure in updating SPFILE
ORA-46693: The WALLET_ROOT location is missing or invalid.
-- ★ ORA-46693. TDE_CONFIGURATION은 WALLET_ROOT를 기준으로 키스토어를 찾으므로 순서가 정해져 있다. 먼저 WALLET_ROOT, 재기동, 그다음 TDE_CONFIGURATION이다.
@END

@P [3] WALLET_ROOT 설정과 재기동
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> HOST mkdir -p /u01/app/oracle/admin/d08tde/wallet

SYS@d08tde> ALTER SYSTEM SET wallet_root = '/u01/app/oracle/admin/d08tde/wallet' SCOPE = SPFILE;

System altered.

SYS@d08tde> SHUTDOWN IMMEDIATE
Database closed.
Database dismounted.
ORACLE instance shut down.
SYS@d08tde> STARTUP
ORACLE instance started.

Total System Global Area  943716976 bytes
Fixed Size                  8903280 bytes
Variable Size             247463936 bytes
Database Buffers          679477248 bytes
Redo Buffers                7872512 bytes
Database mounted.
Database opened.
SYS@d08tde> ALTER SYSTEM SET tde_configuration = 'KEYSTORE_CONFIGURATION=FILE' SCOPE = BOTH;

System altered.

SYS@d08tde> SHOW PARAMETER wallet_root

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
wallet_root                          string      /u01/app/oracle/admin/d08tde/w
                                                 allet
SYS@d08tde> SHOW PARAMETER tde_configuration

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
tde_configuration                    string      KEYSTORE_CONFIGURATION=FILE
SYS@d08tde> COL wrl_parameter FOR a42
SYS@d08tde> COL status FOR a20
SYS@d08tde> COL wallet_type FOR a16
SYS@d08tde> SELECT wrl_parameter, status, wallet_type FROM v$encryption_wallet;

WRL_PARAMETER                              STATUS               WALLET_TYPE
------------------------------------------ -------------------- ----------------
/u01/app/oracle/admin/d08tde/wallet/tde/   NOT_AVAILABLE        UNKNOWN

1 row selected.
-- ★ WALLET_ROOT는 정적 파라미터라 SCOPE=SPFILE과 재기동이 필요하다. 운영 DB라면 이 재기동을 작업 계획에 넣어야 한다.
-- ★ WRL_PARAMETER가 <WALLET_ROOT>/tde/ 로 바뀌었다. 키스토어는 이 하위 디렉터리에 만들어진다.
@END

@P [4] 키스토어 생성과 열기
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "Tde#D08_2026";

keystore altered.

SYS@d08tde> HOST ls -l /u01/app/oracle/admin/d08tde/wallet/tde
total 4
-rw-------. 1 oracle dba 2555 Oct 28 08:49 ewallet.p12

SYS@d08tde> ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "Tde#D08_2026";

keystore altered.

SYS@d08tde> COL wrl_parameter FOR a42
SYS@d08tde> COL status FOR a20
SYS@d08tde> COL wallet_type FOR a16
SYS@d08tde> SELECT wrl_parameter, status, wallet_type FROM v$encryption_wallet;

WRL_PARAMETER                              STATUS               WALLET_TYPE
------------------------------------------ -------------------- ----------------
/u01/app/oracle/admin/d08tde/wallet/tde/   OPEN_NO_MASTER_KEY   PASSWORD

1 row selected.
-- ★ 경로 없이 CREATE KEYSTORE를 실행하자 tde/ 아래에 ewallet.p12가 생겼다.
-- ★ 열었지만 OPEN_NO_MASTER_KEY다. 키스토어는 마스터 키를 담을 그릇일 뿐이고 키는 아직 없다.
@END

@P [5] 마스터 키 없이 암호화 테이블스페이스
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> CREATE TABLESPACE d08_enc DATAFILE '/u01/app/oracle/d08data/D08TDE/d08_enc01.dbf' SIZE 20M
  2    ENCRYPTION USING 'AES256' ENCRYPT;
CREATE TABLESPACE d08_enc DATAFILE '/u01/app/oracle/d08data/D08TDE/d08_enc01.dbf' SIZE 20M
*
ERROR at line 1:
ORA-28361: master key not yet set
-- ★ ORA-28361. 테이블스페이스 키를 감쌀 마스터 키가 없다. STATUS가 OPEN_NO_MASTER_KEY일 때 나는 전형적인 오류다.
@END

@P [6] 마스터 키 설정
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> ADMINISTER KEY MANAGEMENT SET KEY USING TAG 'k1' IDENTIFIED BY "Tde#D08_2026" WITH BACKUP USING 'k1';

keystore altered.

SYS@d08tde> COL wrl_parameter FOR a42
SYS@d08tde> COL status FOR a20
SYS@d08tde> COL wallet_type FOR a16
SYS@d08tde> SELECT wrl_parameter, status, wallet_type FROM v$encryption_wallet;

WRL_PARAMETER                              STATUS               WALLET_TYPE
------------------------------------------ -------------------- ----------------
/u01/app/oracle/admin/d08tde/wallet/tde/   OPEN                 PASSWORD

1 row selected.

SYS@d08tde> COL key_id FOR a54
SYS@d08tde> COL tag FOR a8
SYS@d08tde> SELECT key_id, tag, TO_CHAR(creation_time, 'HH24:MI:SS') created FROM v$encryption_keys ORDER BY creation_time;

KEY_ID                                                 TAG      CREATED
------------------------------------------------------ -------- --------
AbBxRXnOzU/pvzfdH4CN4rkAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   k1       23:49:02

1 row selected.

SYS@d08tde> COL masterkeyid FOR a34
SYS@d08tde> SELECT masterkeyid, masterkey_activated FROM v$database_key_info;

MASTERKEYID                        MAS
---------------------------------- ---
B0714579CECD4FE9BF37DD1F808DE2B9   YES

1 row selected.
-- ★ STATUS가 OPEN으로 바뀌고 V$ENCRYPTION_KEYS에 태그 k1 키가 생겼다. MASTERKEYID도 새 값으로 바뀌며 YES가 됐다.
-- ★ CREATION_TIME은 UTC로 기록된다. 서버 시각(KST 08:49)보다 9시간 앞선 23:49로 보인다.
@END

@P [7] 암호화 테이블스페이스와 일반 테이블스페이스
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> CREATE TABLESPACE d08_enc DATAFILE '/u01/app/oracle/d08data/D08TDE/d08_enc01.dbf' SIZE 20M
  2    ENCRYPTION USING 'AES256' ENCRYPT;

Tablespace created.

SYS@d08tde> CREATE TABLESPACE d08_plain DATAFILE '/u01/app/oracle/d08data/D08TDE/d08_plain01.dbf' SIZE 20M;

Tablespace created.

SYS@d08tde> CREATE USER d08_app IDENTIFIED BY "D08app#2026" QUOTA UNLIMITED ON d08_enc QUOTA UNLIMITED ON d08_plain;

User created.

SYS@d08tde> CREATE TABLE d08_app.card_enc (id NUMBER, card_no VARCHAR2(20)) TABLESPACE d08_enc;

Table created.

SYS@d08tde> CREATE TABLE d08_app.card_plain (id NUMBER, card_no VARCHAR2(20)) TABLESPACE d08_plain;

Table created.

SYS@d08tde> INSERT INTO d08_app.card_enc VALUES (1, 'CARD-9876-D08');

1 row created.

SYS@d08tde> INSERT INTO d08_app.card_plain VALUES (1, 'CARD-9876-D08');

1 row created.

SYS@d08tde> COMMIT;

Commit complete.

SYS@d08tde> ALTER SYSTEM CHECKPOINT;

System altered.

SYS@d08tde> COL tablespace_name FOR a10
SYS@d08tde> SELECT tablespace_name, encrypted FROM dba_tablespaces WHERE tablespace_name LIKE 'D08%';

TABLESPACE ENC
---------- ---
D08_ENC    YES
D08_PLAIN  NO

2 rows selected.
-- ★ 같은 값을 암호화 테이블스페이스와 일반 테이블스페이스에 한 행씩 넣고 체크포인트로 파일에 내렸다.
@END

@P [8] 데이터 파일을 직접 읽으면
@CODE
[oracle@oel7v9 ~]$ strings /u01/app/oracle/d08data/D08TDE/d08_plain01.dbf | grep -c 'CARD-9876-D08'
1
[oracle@oel7v9 ~]$ strings /u01/app/oracle/d08data/D08TDE/d08_enc01.dbf | grep -c 'CARD-9876-D08'
0
-- ★ 일반 테이블스페이스 파일에서는 카드 번호가 평문으로 1건 보이고, 암호화 테이블스페이스 파일에서는 0건이다. OS 파일이나 백업을 빼 간 쪽이 보는 화면이 이것이다.
@END

@P [9] 기존 테이블스페이스 온라인 암호화
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> ALTER TABLESPACE d08_plain ENCRYPTION ONLINE USING 'AES256' ENCRYPT;

Tablespace altered.

SYS@d08tde> COL name FOR a10
SYS@d08tde> SELECT t.name, e.encryptionalg, e.status
  2    FROM v$encrypted_tablespaces e JOIN v$tablespace t ON e.ts# = t.ts#;

NAME       ENCRYPT STATUS
---------- ------- ----------
D08_ENC    AES256  NORMAL
D08_PLAIN  AES256  NORMAL

2 rows selected.

SYS@d08tde> COL file_name FOR a50
SYS@d08tde> SELECT file_name FROM dba_data_files WHERE tablespace_name = 'D08_PLAIN';

FILE_NAME
--------------------------------------------------
/u01/app/oracle/d08data/D08TDE/d08_plain01.dbf

1 row selected.

SYS@d08tde> ALTER SYSTEM CHECKPOINT;

System altered.
-- ★ 운영 중에 ENCRYPTION ONLINE으로 기존 테이블스페이스를 바꿨다. 이 DB는 OMF가 아닌데도 FILE_NAME_CONVERT 없이 성공했고 파일 이름도 그대로다.
-- ★ 문서 기준으로 온라인 변환에는 보조 공간이 필요하다(오프라인 변환은 불필요). 큰 테이블스페이스는 여유 공간부터 확인한다.
@END

@P [10] 변환 뒤 다시 읽으면
@CODE
[oracle@oel7v9 ~]$ ls /u01/app/oracle/d08data/D08TDE | grep d08_
d08_enc01.dbf
d08_plain01.dbf
[oracle@oel7v9 ~]$ strings /u01/app/oracle/d08data/D08TDE/d08_plain01.dbf | grep -c 'CARD-9876-D08'
0
-- ★ 같은 파일에서 평문이 사라졌다(0건). 변환 전에 만든 백업에는 평문이 남아 있으므로, 변환 직후 새 백업을 받아야 한다.
@END

@P [11] 비밀번호 키스토어로 재기동
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> SHUTDOWN IMMEDIATE
Database closed.
Database dismounted.
ORACLE instance shut down.
SYS@d08tde> STARTUP
ORACLE instance started.

Total System Global Area  943716976 bytes
Fixed Size                  8903280 bytes
Variable Size             247463936 bytes
Database Buffers          679477248 bytes
Redo Buffers                7872512 bytes
Database mounted.
Database opened.
SYS@d08tde> COL wrl_parameter FOR a42
SYS@d08tde> COL status FOR a20
SYS@d08tde> COL wallet_type FOR a16
SYS@d08tde> SELECT wrl_parameter, status, wallet_type FROM v$encryption_wallet;

WRL_PARAMETER                              STATUS               WALLET_TYPE
------------------------------------------ -------------------- ----------------
/u01/app/oracle/admin/d08tde/wallet/tde/   CLOSED               UNKNOWN

1 row selected.

SYS@d08tde> SELECT * FROM d08_app.card_enc;
SELECT * FROM d08_app.card_enc
                      *
ERROR at line 1:
ORA-28365: wallet is not open


SYS@d08tde> SELECT COUNT(*) FROM d08_app.card_plain;
SELECT COUNT(*) FROM d08_app.card_plain
                             *
ERROR at line 1:
ORA-28365: wallet is not open


SYS@d08tde> ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "Tde#D08_2026";

keystore altered.

SYS@d08tde> SELECT * FROM d08_app.card_enc;

        ID CARD_NO
---------- --------------------
         1 CARD-9876-D08

1 row selected.
-- ★ 재기동 직후 CLOSED. 암호화 테이블스페이스 두 곳 모두 ORA-28365로 막힌다. COUNT(*)도 마찬가지다.
-- ★ DB 자체는 READ WRITE로 열려 있다. 비암호화 객체는 정상이라 장애가 늦게 드러나기 쉽다.
-- ★ 비밀번호로 연 뒤에야 조회가 된다. 운영에서 비밀번호 키스토어만 쓰면 재기동 절차에 열기 단계를 반드시 넣는다.
@END

@P [12] auto-login 키스토어와 재기동
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> ADMINISTER KEY MANAGEMENT CREATE LOCAL AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "Tde#D08_2026";

keystore altered.

SYS@d08tde> HOST ls -l /u01/app/oracle/admin/d08tde/wallet/tde
total 20
-rw-------. 1 oracle dba 4216 Oct 28 08:50 cwallet.sso
-rw-------. 1 oracle dba 4155 Oct 28 08:49 ewallet.p12
-rw-------. 1 oracle dba 2555 Oct 28 08:49 ewallet_2026102723490263_k1.p12

SYS@d08tde> SHUTDOWN IMMEDIATE
Database closed.
Database dismounted.
ORACLE instance shut down.
SYS@d08tde> STARTUP
ORACLE instance started.

Total System Global Area  943716976 bytes
Fixed Size                  8903280 bytes
Variable Size             247463936 bytes
Database Buffers          679477248 bytes
Redo Buffers                7872512 bytes
Database mounted.
Database opened.
SYS@d08tde> COL wrl_parameter FOR a42
SYS@d08tde> COL status FOR a20
SYS@d08tde> COL wallet_type FOR a16
SYS@d08tde> SELECT wrl_parameter, status, wallet_type FROM v$encryption_wallet;

WRL_PARAMETER                              STATUS               WALLET_TYPE
------------------------------------------ -------------------- ----------------
/u01/app/oracle/admin/d08tde/wallet/tde/   OPEN                 LOCAL_AUTOLOGIN

1 row selected.

SYS@d08tde> SELECT * FROM d08_app.card_enc;

        ID CARD_NO
---------- --------------------
         1 CARD-9876-D08

1 row selected.
-- ★ cwallet.sso가 생겼고, 재기동 후 STATUS=OPEN, WALLET_TYPE=LOCAL_AUTOLOGIN이다. 사람이 개입하지 않아도 조회된다.
-- ★ ewallet_..._k1.p12는 [6]의 WITH BACKUP이 남긴 사본이다.
@END

@P [13] auto-login 상태에서 키 교체
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> ADMINISTER KEY MANAGEMENT SET KEY USING TAG 'k2' IDENTIFIED BY "Tde#D08_2026" WITH BACKUP USING 'k2';
ADMINISTER KEY MANAGEMENT SET KEY USING TAG 'k2' IDENTIFIED BY "Tde#D08_2026" WITH BACKUP USING 'k2'
*
ERROR at line 1:
ORA-28417: password-based keystore is not open


SYS@d08tde> ADMINISTER KEY MANAGEMENT SET KEY USING TAG 'k2' FORCE KEYSTORE IDENTIFIED BY "Tde#D08_2026" WITH BACKUP USING 'k2';

keystore altered.

SYS@d08tde> COL key_id FOR a54
SYS@d08tde> COL tag FOR a8
SYS@d08tde> SELECT key_id, tag, TO_CHAR(creation_time, 'HH24:MI:SS') created FROM v$encryption_keys ORDER BY creation_time;

KEY_ID                                                 TAG      CREATED
------------------------------------------------------ -------- --------
AbBxRXnOzU/pvzfdH4CN4rkAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   k1       23:49:02
AaYzVw8egU/lv3bBMUNnn4QAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   k2       23:50:41

2 rows selected.

SYS@d08tde> COL masterkeyid FOR a34
SYS@d08tde> SELECT masterkeyid, masterkey_activated FROM v$database_key_info;

MASTERKEYID                        MAS
---------------------------------- ---
A633570F1E814FE5BF76C13143679F84   YES

1 row selected.

SYS@d08tde> SELECT * FROM d08_app.card_enc;

        ID CARD_NO
---------- --------------------
         1 CARD-9876-D08

1 row selected.

SYS@d08tde> HOST ls -l /u01/app/oracle/admin/d08tde/wallet/tde
total 28
-rw-------. 1 oracle dba 5656 Oct 28 08:50 cwallet.sso
-rw-------. 1 oracle dba 5595 Oct 28 08:50 ewallet.p12
-rw-------. 1 oracle dba 2555 Oct 28 08:49 ewallet_2026102723490263_k1.p12
-rw-------. 1 oracle dba 4155 Oct 28 08:50 ewallet_2026102723504139_k2.p12
-- ★ 첫 시도는 ORA-28417. 지금 열린 것은 auto-login 키스토어라 비밀번호 키스토어가 열려 있지 않다고 판단한다. FORCE KEYSTORE를 붙이면 잠시 비밀번호 키스토어를 열어 작업한다.
-- ★ 키가 두 개(k1, k2)가 됐고 MASTERKEYID는 k2로 바뀌었다. 데이터는 그대로 읽힌다. 블록을 다시 암호화하지 않고 테이블스페이스 키만 새 키로 감쌌기 때문이다.
-- ★ 이전 키 k1은 키스토어에 남는다. 예전 백업을 복원하려면 그 키가 필요하므로 지우지 않는다.
@END

@P [14] 철거와 남는 것
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@d08tde> DROP USER d08_app CASCADE;

User dropped.

SYS@d08tde> DROP TABLESPACE d08_enc INCLUDING CONTENTS AND DATAFILES;

Tablespace dropped.

SYS@d08tde> DROP TABLESPACE d08_plain INCLUDING CONTENTS AND DATAFILES;

Tablespace dropped.

SYS@d08tde> SELECT COUNT(*) FROM v$encrypted_tablespaces;

  COUNT(*)
----------
         0

1 row selected.

SYS@d08tde> COL masterkeyid FOR a34
SYS@d08tde> SELECT masterkeyid, masterkey_activated FROM v$database_key_info;

MASTERKEYID                        MAS
---------------------------------- ---
A633570F1E814FE5BF76C13143679F84   YES

1 row selected.

SYS@d08tde> COL key_id FOR a54
SYS@d08tde> COL tag FOR a8
SYS@d08tde> SELECT key_id, tag, TO_CHAR(creation_time, 'HH24:MI:SS') created FROM v$encryption_keys ORDER BY creation_time;

KEY_ID                                                 TAG      CREATED
------------------------------------------------------ -------- --------
AbBxRXnOzU/pvzfdH4CN4rkAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   k1       23:49:02
AaYzVw8egU/lv3bBMUNnn4QAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   k2       23:50:41

2 rows selected.
-- ★ 암호화 테이블스페이스는 0개가 됐지만 MASTERKEYID(활성화 YES)와 키 두 개는 그대로 남는다.
-- ★ 이 상태에서 키스토어 디렉터리를 지우면 다음 재기동에서 문제가 생긴다. TDE 실습을 마친 DB라도 키스토어는 보존한다.
-- ★ 측정 환경에서는 이 뒤에 임시 DB d08tde를 DBCA로 삭제했다.
@END

@H3 08.4  정리와 확인 포인트
@B 구성 순서는 WALLET_ROOT(SPFILE, 재기동) → TDE_CONFIGURATION → CREATE KEYSTORE → OPEN → SET KEY WITH BACKUP이다. 한 단계를 건너뛰면 ORA-46693, ORA-28361처럼 바로 다음 단계에서 막힌다.
@B 장애 진단은 `V$ENCRYPTION_WALLET`의 STATUS·WALLET_TYPE부터 본다. CLOSED면 열기, OPEN_NO_MASTER_KEY면 SET KEY다.
@B 비밀번호 키스토어만 쓰는 DB는 재기동할 때마다 열기 단계가 필요하다. 무인 기동이 필요하면 LOCAL auto-login을 만들고, 비밀번호가 필요한 작업에는 FORCE KEYSTORE를 붙인다.
@B 마스터 키 교체는 데이터를 다시 쓰지 않는 가벼운 작업이다. 교체 주기를 보안 정책에 넣고 매번 WITH BACKUP 사본과 키스토어 백업을 DB 백업과 분리해 보관한다.
@B 키스토어와 마스터 키 이력은 객체를 지워도 남는다. "TDE 해제"는 키스토어 삭제가 아니라 암호화 객체 복호화까지만이다.
@H2 실습 09  TLS로 접속 구간 암호화와 인증서 로그인
@TBL
항목 | 내용
목표 | 자체 루트 CA로 서버·클라이언트 인증서를 발급하고 TCPS 전용 리스너로 상호 인증 TLS 접속을 구성한다. 비밀번호 로그인과 인증서 로그인을 비교하고, 서버 DN 대조와 신뢰하지 않는 CA로 인한 실패를 진단한다
소요 | 60분
접속 | oracle OS 계정 셸, SYS(/ AS SYSDBA), SCOTT, 인증서 사용자 D09_CERT
변경 | 디렉터리 /home/oracle/d09(CA·지갑·서버/클라이언트 TNS_ADMIN), 리스너 LISTENER_D09(TCPS 2484), 사용자 D09_CERT. 마지막 단계에서 모두 지움. 공용 listener.ora·sqlnet.ora는 바꾸지 않음
@END

@H3 09.1  실습 전에 — 지갑 세 개와 신뢰 사슬
@B TLS 접속에는 인증서를 담은 지갑이 양쪽에 필요하다.
@B 서버 지갑: 서버 인증서와 개인 키, 그 인증서를 서명한 CA 인증서.
@B 클라이언트 지갑: 서버 인증서를 검증할 CA 인증서. 상호 인증(SSL_CLIENT_AUTHENTICATION=TRUE)이면 클라이언트 자신의 인증서와 개인 키도 들어간다.
@B 실무에서는 CA 개인 키를 서버 지갑에 두지 않는다. 이번 실습은 CA 전용 지갑을 따로 만들어 서명만 맡긴다. 교안 11장 실습은 서버 지갑의 자체 서명 인증서를 CA처럼 썼다.
@B 발급 절차는 어느 쪽이든 같다. 키 쌍과 인증서 요청 생성(`wallet add -dn`) → 요청 내보내기(`export -request`) → CA 서명(`cert create`) → CA 인증서를 먼저(`-trusted_cert`), 서명된 인증서를 나중에(`-user_cert`) 가져오기.
@B orapki는 약한 설정을 막지 않는다. 512비트 키, 같은 인증서 중복 추가, 기존 지갑 위의 `wallet create`도 그대로 받아들인다(교안 11장). 키 길이 2048 이상, `-sign_alg sha256`을 절차서에 명시한다.
@B TCPS 리스너는 별도 TNS_ADMIN 디렉터리의 listener.ora로 띄운다. 정적 SID_DESC의 `ENVS = "TNS_ADMIN=..."`이 이 리스너가 띄운 서버 프로세스에 서버 쪽 sqlnet.ora 위치를 넘긴다. 기존 1521 리스너와 공용 설정 파일은 손대지 않는다.
@B 인증서 로그인 사용자는 `IDENTIFIED EXTERNALLY AS '<인증서 DN>'`으로 만든다. DN 문자열이 클라이언트 인증서의 Subject와 맞아야 하고, 맞지 않으면 TLS 핸드셰이크는 통과하고 로그인만 ORA-01017로 거부된다(교안 11장 실습 05).
@B 같은 사용자가 보는 위치에 따라 다르게 표시된다.
@TBL
보는 곳 | 값 | 비고
DBA_USERS.AUTHENTICATION_TYPE | EXTERNAL | 사용자 정의 기준
SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') | SSL | 세션 기준
V$SESSION_CONNECT_INFO.AUTHENTICATION_TYPE | GLOBAL | 네트워크 서비스 기준, 배너에 TLS 표시는 없음
SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') | tcps | TLS 여부는 이 값으로 판정
@END
@B 클라이언트가 서버를 확인하는 단계는 두 겹이다. CA 서명 검증은 항상 한다. 서버 인증서 DN과 접속 대상의 대조는 `SSL_SERVER_DN_MATCH = YES`일 때만 한다. 중간자 공격을 막으려면 운영 클라이언트에서 켠다.
@B DN 대조가 켜진 상태에서 접속 기술자에 `SSL_SERVER_CERT_DN`이 있으면 전체 DN을 대조한다. 없으면 인증서 CN을 접속 기술자의 HOST 값과 견준다. 이 실습에서는 HOST에 IP를 쓴 별칭만 실패했다([10]).
@B 실패 위치에 따라 오류가 다르다. 서버 DN 불일치는 ORA-29003, CA를 신뢰하지 못하면 ORA-29024, 지갑 위치가 없으면 ORA-28759다. 서버 쪽 리스너 로그에는 TNS-00542(SSL Handshake failed)가 남는다.
@NOTE 최신 RU의 파라미터 이름
최신 19c RU 문서는 SSL_VERSION·SSL_CLIENT_AUTHENTICATION·SSL_SERVER_DN_MATCH를 TLS_로 시작하는 이름으로 소개한다. 19.3에서는 SSL_ 이름을 쓴다. 두 이름이 함께 있으면 SSL_ 쪽이 무시된다(교안 11장).
@END

@H3 09.2  진행 순서
@TBL
단계 | 주제 | 하는 일 | 확인할 것
[1] | 준비 | 작업 디렉터리, 공용 파일 md5 기록 | 2484 포트 비어 있음
[2] | 루트 CA | CA 전용 지갑과 자체 서명 인증서 | Subject = Issuer
[3~4] | 인증서 발급 | 서버·클라이언트 요청 → CA 서명 → 가져오기 | User·Trusted 인증서 각 1개
[5] | 서버 구성 | 전용 TNS_ADMIN, LISTENER_D09 기동 | tcps 2484 엔드포인트
[6] | 인증서 사용자 | IDENTIFIED EXTERNALLY AS DN | AUTHENTICATION_TYPE=EXTERNAL
[7] | 클라이언트 접속 | 비밀번호 로그인과 인증서 로그인 | tcps, PASSWORD와 SSL
[8~9] | 서버에서 보기 | 세션 유지 후 V$SESSION_CONNECT_INFO | GLOBAL, 배너
[10] | 서버 DN 대조 | DN_MATCH=YES로 세 별칭 접속 | ORA-29003
[11~12] | 신뢰하지 않는 CA | 다른 CA만 믿는 클라이언트 | ORA-29024, TNS-00542
[13~14] | 철거 | 리스너 정지, 파일·사용자 삭제 | md5 일치, 0건
@END

@H3 09.3  실습 스크립트
@P [1] 작업 디렉터리와 공용 파일 기준값
@CODE
[oracle@oel7v9 ~]$ mkdir -p /home/oracle/d09/ca /home/oracle/d09/server_wallet /home/oracle/d09/client_wallet /home/oracle/d09/server_tns /home/oracle/d09/client_tns
[oracle@oel7v9 ~]$ chmod 700 /home/oracle/d09
[oracle@oel7v9 ~]$ md5sum $ORACLE_HOME/network/admin/listener.ora $ORACLE_HOME/network/admin/sqlnet.ora
10d7442986929ce050326f853ae81d8a  /u01/app/oracle/product/19.3.0/dbhome_1/network/admin/listener.ora
4842bc60cd301476deead5025d27f03e  /u01/app/oracle/product/19.3.0/dbhome_1/network/admin/sqlnet.ora
[oracle@oel7v9 ~]$ lsnrctl status | grep -i 'Alias\|PROTOCOL'
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=oel7v9)(PORT=1521)))
Alias                     LISTENER
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=oel7v9)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcps)(HOST=oel7v9)(PORT=5500))(Security=(my_wallet_directory=/u01/app/oracle/admin/orcl/xdb_wallet))(Presentation=HTTP)(Session=RAW))
[oracle@oel7v9 ~]$ netstat -lnt | grep -c ':2484 '
0
-- ★ 공용 listener.ora·sqlnet.ora의 md5를 적어 둔다. 끝에서 같은 값인지 확인한다.
-- ★ 기본 LISTENER는 1521(TCP)과 XDB용 5500(TCPS)만 듣는다. 2484는 비어 있다(0).
@END

@P [2] 루트 CA 만들기
@CODE
[oracle@oel7v9 ~]$ cd /home/oracle/d09
[oracle@oel7v9 d09]$ orapki wallet create -nologo -wallet ./ca -pwd 'Ca#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet add -nologo -wallet ./ca -dn 'CN=D09 Root CA,O=itwill,C=KR' -keysize 2048 -self_signed -validity 3650 -sign_alg sha256 -pwd 'Ca#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet export -nologo -wallet ./ca -dn 'CN=D09 Root CA,O=itwill,C=KR' -cert ./ca.cert -pwd 'Ca#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki cert display -nologo -cert ./ca.cert -summary
Subject:        CN=D09 Root CA,O=itwill,C=KR
Issuer:         CN=D09 Root CA,O=itwill,C=KR
Valid Until:    Sat Oct 25 08:52:51 KST 2036
-- ★ Subject와 Issuer가 같은 자체 서명 인증서다. 유효 기간 10년, SHA-256 서명.
-- ★ CA 지갑에는 auto-login을 만들지 않았다. 서명할 때마다 비밀번호를 입력하게 해 CA 개인 키를 보호한다.
@END

@P [3] 서버 지갑: 요청, 서명, 가져오기
@CODE
[oracle@oel7v9 ~]$ cd /home/oracle/d09
[oracle@oel7v9 d09]$ orapki wallet create -nologo -wallet ./server_wallet -pwd 'Srv#D09_2026' -auto_login
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet add -nologo -wallet ./server_wallet -dn 'CN=oel7v9,O=itwill,C=KR' -keysize 2048 -pwd 'Srv#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet export -nologo -wallet ./server_wallet -dn 'CN=oel7v9,O=itwill,C=KR' -request ./server.req -pwd 'Srv#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki cert create -nologo -wallet ./ca -request ./server.req -cert ./server.cert -validity 365 -sign_alg sha256 -pwd 'Ca#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet add -nologo -wallet ./server_wallet -trusted_cert -cert ./ca.cert -pwd 'Srv#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet add -nologo -wallet ./server_wallet -user_cert -cert ./server.cert -pwd 'Srv#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet display -nologo -wallet ./server_wallet
Requested Certificates:
User Certificates:
Subject:        CN=oel7v9,O=itwill,C=KR
Trusted Certificates:
Subject:        CN=D09 Root CA,O=itwill,C=KR
[oracle@oel7v9 d09]$ ls -l ./server_wallet
total 8
-rw-------. 1 oracle dba 3957 Oct 28 08:52 cwallet.sso
-rw-------. 1 oracle dba    0 Oct 28 08:52 cwallet.sso.lck
-rw-------. 1 oracle dba 3912 Oct 28 08:52 ewallet.p12
-rw-------. 1 oracle dba    0 Oct 28 08:52 ewallet.p12.lck
-- ★ wallet add -dn 은 키 쌍과 인증서 요청을 만든다. 서명된 인증서를 가져오면 Requested 목록에서 User Certificates로 옮겨 간다.
-- ★ 서버 지갑은 -auto_login으로 만들어 cwallet.sso가 있다. 리스너와 서버 프로세스가 비밀번호 없이 지갑을 열어야 하기 때문이다.
@END

@P [4] 클라이언트 지갑
@CODE
[oracle@oel7v9 ~]$ cd /home/oracle/d09
[oracle@oel7v9 d09]$ orapki wallet create -nologo -wallet ./client_wallet -pwd 'Cli#D09_2026' -auto_login
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet add -nologo -wallet ./client_wallet -dn 'CN=d09_client,O=itwill,C=KR' -keysize 2048 -pwd 'Cli#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet export -nologo -wallet ./client_wallet -dn 'CN=d09_client,O=itwill,C=KR' -request ./client.req -pwd 'Cli#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki cert create -nologo -wallet ./ca -request ./client.req -cert ./client.cert -validity 365 -sign_alg sha256 -pwd 'Ca#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet add -nologo -wallet ./client_wallet -trusted_cert -cert ./ca.cert -pwd 'Cli#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet add -nologo -wallet ./client_wallet -user_cert -cert ./client.cert -pwd 'Cli#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet display -nologo -wallet ./client_wallet
Requested Certificates:
User Certificates:
Subject:        CN=d09_client,O=itwill,C=KR
Trusted Certificates:
Subject:        CN=D09 Root CA,O=itwill,C=KR
-- ★ 같은 CA가 서명한 클라이언트 인증서. Subject가 DB 사용자의 외부 이름으로 쓰인다.
@END

@P [5] 서버 쪽 네트워크 구성과 TCPS 리스너
@CODE
[oracle@oel7v9 ~]$ cd /home/oracle/d09/server_tns
[oracle@oel7v9 server_tns]$ printf '%s\n' 'LISTENER_D09 =' '  (DESCRIPTION_LIST =' '    (DESCRIPTION =' '      (ADDRESS = (PROTOCOL = TCPS)(HOST = oel7v9)(PORT = 2484))))' 'SID_LIST_LISTENER_D09 =' '  (SID_LIST =' '    (SID_DESC =' '      (GLOBAL_DBNAME = orcl)' '      (ORACLE_HOME = /u01/app/oracle/product/19.3.0/dbhome_1)' '      (SID_NAME = orcl)' '      (ENVS = "TNS_ADMIN=/home/oracle/d09/server_tns")))' 'WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = /home/oracle/d09/server_wallet)))' 'SSL_CLIENT_AUTHENTICATION = FALSE' > listener.ora
[oracle@oel7v9 server_tns]$ printf '%s\n' 'WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = /home/oracle/d09/server_wallet)))' 'SQLNET.AUTHENTICATION_SERVICES = (BEQ, TCPS)' 'SSL_CLIENT_AUTHENTICATION = TRUE' 'SSL_VERSION = 1.2' > sqlnet.ora
[oracle@oel7v9 server_tns]$ cat listener.ora sqlnet.ora
LISTENER_D09 =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCPS)(HOST = oel7v9)(PORT = 2484))))
SID_LIST_LISTENER_D09 =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = orcl)
      (ORACLE_HOME = /u01/app/oracle/product/19.3.0/dbhome_1)
      (SID_NAME = orcl)
      (ENVS = "TNS_ADMIN=/home/oracle/d09/server_tns")))
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = /home/oracle/d09/server_wallet)))
SSL_CLIENT_AUTHENTICATION = FALSE
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = /home/oracle/d09/server_wallet)))
SQLNET.AUTHENTICATION_SERVICES = (BEQ, TCPS)
SSL_CLIENT_AUTHENTICATION = TRUE
SSL_VERSION = 1.2
[oracle@oel7v9 server_tns]$ export TNS_ADMIN=/home/oracle/d09/server_tns
[oracle@oel7v9 server_tns]$ lsnrctl start LISTENER_D09 | tail -8
Listener Parameter File   /home/oracle/d09/server_tns/listener.ora
Listener Log File         /u01/app/oracle/diag/tnslsnr/oel7v9/listener_d09/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcps)(HOST=oel7v9)(PORT=2484)))
Services Summary...
Service "orcl" has 1 instance(s).
  Instance "orcl", status UNKNOWN, has 1 handler(s) for this service...
The command completed successfully
[oracle@oel7v9 server_tns]$ lsnrctl status LISTENER_D09 | grep -i 'Alias\|tcps\|Service'
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=oel7v9)(PORT=2484)))
Alias                     LISTENER_D09
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcps)(HOST=oel7v9)(PORT=2484)))
Services Summary...
Service "orcl" has 1 instance(s).
  Instance "orcl", status UNKNOWN, has 1 handler(s) for this service...
-- ★ 서버 쪽 sqlnet.ora는 /home/oracle/d09/server_tns에 있다. 공용 sqlnet.ora와 별개라 1521 접속에는 영향이 없다.
-- ★ 서비스 상태 UNKNOWN은 정적 등록(SID_LIST)이라서 그렇다. 동적 등록은 기본 리스너로만 간다.
@END

@P [6] 인증서 사용자
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d09_cert IDENTIFIED EXTERNALLY AS 'CN=d09_client,O=itwill,C=KR';

User created.

SYS@orcl> GRANT CREATE SESSION TO d09_cert;

Grant succeeded.

SYS@orcl> COL username FOR a10
SYS@orcl> COL external_name FOR a30
SYS@orcl> SELECT username, authentication_type, external_name FROM dba_users WHERE username = 'D09_CERT';

USERNAME   AUTHENTI EXTERNAL_NAME
---------- -------- ------------------------------
D09_CERT   EXTERNAL cn=d09_client,o=itwill,c=KR

1 row selected.
-- ★ EXTERNAL_NAME은 속성 이름이 소문자로 저장됐다(cn=, o=). 인증서 Subject는 대문자(CN=, O=)지만 [7]의 인증서 로그인은 그대로 성공한다.
@END

@P [7] 클라이언트 구성과 두 가지 접속
@CODE
[oracle@oel7v9 ~]$ cd /home/oracle/d09/client_tns
[oracle@oel7v9 client_tns]$ printf '%s\n' 'WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = /home/oracle/d09/client_wallet)))' 'SQLNET.AUTHENTICATION_SERVICES = (TCPS)' 'SSL_CLIENT_AUTHENTICATION = TRUE' > sqlnet.ora
[oracle@oel7v9 client_tns]$ printf '%s\n' 'D09_TLS =' '  (DESCRIPTION =' '    (ADDRESS = (PROTOCOL = TCPS)(HOST = oel7v9)(PORT = 2484))' '    (CONNECT_DATA = (SERVICE_NAME = orcl)))' 'D09_DNOK =' '  (DESCRIPTION =' '    (ADDRESS = (PROTOCOL = TCPS)(HOST = oel7v9)(PORT = 2484))' '    (CONNECT_DATA = (SERVICE_NAME = orcl))' '    (SECURITY = (SSL_SERVER_CERT_DN = "CN=oel7v9,O=itwill,C=KR")))' 'D09_DNBAD =' '  (DESCRIPTION =' '    (ADDRESS = (PROTOCOL = TCPS)(HOST = oel7v9)(PORT = 2484))' '    (CONNECT_DATA = (SERVICE_NAME = orcl))' '    (SECURITY = (SSL_SERVER_CERT_DN = "CN=dbprod01,O=itwill,C=KR")))' 'D09_IP =' '  (DESCRIPTION =' '    (ADDRESS = (PROTOCOL = TCPS)(HOST = 172.16.225.50)(PORT = 2484))' '    (CONNECT_DATA = (SERVICE_NAME = orcl)))' > tnsnames.ora
[oracle@oel7v9 client_tns]$ cat sqlnet.ora
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = /home/oracle/d09/client_wallet)))
SQLNET.AUTHENTICATION_SERVICES = (TCPS)
SSL_CLIENT_AUTHENTICATION = TRUE
[oracle@oel7v9 client_tns]$ export TNS_ADMIN=/home/oracle/d09/client_tns
[oracle@oel7v9 client_tns]$ printf '%s\n' 'COL usr FOR a10' 'COL proto FOR a6' 'COL auth FOR a9' "SELECT SYS_CONTEXT('USERENV','SESSION_USER') usr, SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') proto, SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') auth FROM dual;" | sqlplus -s -L scott/tiger@d09_tls

USR        PROTO  AUTH
---------- ------ ---------
SCOTT      tcps   PASSWORD

[oracle@oel7v9 client_tns]$ printf '%s\n' 'COL usr FOR a10' 'COL proto FOR a6' 'COL auth FOR a9' "SELECT SYS_CONTEXT('USERENV','SESSION_USER') usr, SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') proto, SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') auth FROM dual;" | sqlplus -s -L /@d09_tls

USR        PROTO  AUTH
---------- ------ ---------
D09_CERT   tcps   SSL
-- ★ 같은 TCPS 별칭으로 두 번 접속했다. SCOTT은 비밀번호 인증(PASSWORD), /@d09_tls는 지갑의 인증서로 D09_CERT가 됐다(SSL).
-- ★ 두 세션 모두 NETWORK_PROTOCOL=tcps라 구간 암호화는 같다. 다른 것은 로그인 방식이다.
@END

@P [8] 세션 하나를 10초 유지
@CODE
[oracle@oel7v9 ~]$ export TNS_ADMIN=/home/oracle/d09/client_tns
[oracle@oel7v9 ~]$ cd /home/oracle/d09
[oracle@oel7v9 d09]$ nohup sh -c "echo 'EXEC DBMS_SESSION.SLEEP(10)' | sqlplus -s -L /@d09_tls" >/dev/null 2>&1 </dev/null &
[oracle@oel7v9 d09]$ sleep 4
-- ★ 서버에서 관찰할 수 있도록 인증서 세션을 10초 동안 붙잡아 둔다.
@END

@P [9] 서버에서 본 TLS 세션
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL username FOR a9
SYS@orcl> COL auth FOR a7
SYS@orcl> COL banner FOR a60
SYS@orcl> SELECT s.username, i.authentication_type auth, SUBSTR(i.network_service_banner, 1, 60) banner
  2    FROM v$session s JOIN v$session_connect_info i ON s.sid = i.sid AND s.serial# = i.serial#
  3   WHERE s.username = 'D09_CERT';

USERNAME  AUTH    BANNER
--------- ------- ------------------------------------------------------------
D09_CERT  GLOBAL
D09_CERT  GLOBAL  Authentication service for Linux: Version 19.0.0.0.0 - Produ
D09_CERT  GLOBAL  Encryption service for Linux: Version 19.0.0.0.0 - Productio
D09_CERT  GLOBAL  Crypto-checksumming service for Linux: Version 19.0.0.0.0 -

4 rows selected.
-- ★ AUTHENTICATION_TYPE은 GLOBAL로 보이고, 배너 어디에도 TLS나 SSL 표시가 없다. 서버에서 TLS 여부를 점검할 때 배너를 근거로 삼으면 안 된다.
-- ★ 점검 쿼리는 SYS_CONTEXT('USERENV','NETWORK_PROTOCOL')나 감사 기록의 접속 정보를 쓴다.
@END

@P [10] 서버 DN 대조 켜기
@CODE
[oracle@oel7v9 ~]$ cd /home/oracle/d09/client_tns
[oracle@oel7v9 client_tns]$ echo 'SSL_SERVER_DN_MATCH = YES' >> sqlnet.ora
[oracle@oel7v9 client_tns]$ grep SSL_SERVER_CERT_DN tnsnames.ora
    (SECURITY = (SSL_SERVER_CERT_DN = "CN=oel7v9,O=itwill,C=KR")))
    (SECURITY = (SSL_SERVER_CERT_DN = "CN=dbprod01,O=itwill,C=KR")))
[oracle@oel7v9 client_tns]$ export TNS_ADMIN=/home/oracle/d09/client_tns
[oracle@oel7v9 client_tns]$ printf '%s\n' 'COL usr FOR a10' 'COL proto FOR a6' 'COL auth FOR a9' "SELECT SYS_CONTEXT('USERENV','SESSION_USER') usr, SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') proto, SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') auth FROM dual;" | sqlplus -s -L scott/tiger@d09_dnok

USR        PROTO  AUTH
---------- ------ ---------
SCOTT      tcps   PASSWORD

[oracle@oel7v9 client_tns]$ printf '%s\n' 'COL usr FOR a10' 'COL proto FOR a6' 'COL auth FOR a9' "SELECT SYS_CONTEXT('USERENV','SESSION_USER') usr, SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') proto, SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') auth FROM dual;" | sqlplus -s -L scott/tiger@d09_dnbad
ERROR:
ORA-29003: SSL transport detected mismatched server certificate.


SP2-0751: Unable to connect to Oracle.  Exiting SQL*Plus
[oracle@oel7v9 client_tns]$ printf '%s\n' 'COL usr FOR a10' 'COL proto FOR a6' 'COL auth FOR a9' "SELECT SYS_CONTEXT('USERENV','SESSION_USER') usr, SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') proto, SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') auth FROM dual;" | sqlplus -s -L scott/tiger@d09_tls

USR        PROTO  AUTH
---------- ------ ---------
SCOTT      tcps   PASSWORD

[oracle@oel7v9 client_tns]$ printf '%s\n' 'COL usr FOR a10' 'COL proto FOR a6' 'COL auth FOR a9' "SELECT SYS_CONTEXT('USERENV','SESSION_USER') usr, SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') proto, SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') auth FROM dual;" | sqlplus -s -L scott/tiger@d09_ip
ERROR:
ORA-29003: SSL transport detected mismatched server certificate.


SP2-0751: Unable to connect to Oracle.  Exiting SQL*Plus
-- ★ DN_MATCH=YES에서 d09_dnok(정확한 DN)는 통과, d09_dnbad(CN=dbprod01)는 ORA-29003으로 거부됐다.
-- ★ SSL_SERVER_CERT_DN이 없는 별칭은 결과가 갈렸다. HOST=oel7v9인 d09_tls는 인증서 CN과 같아 통과했고, HOST=172.16.225.50인 d09_ip는 실패했다.
-- ★ 인증서 CN에 실제로 접속에 쓰는 호스트 이름을 넣거나, 별칭마다 SSL_SERVER_CERT_DN을 적는다.
@END

@P [11] 다른 CA를 신뢰하는 클라이언트
@CODE
[oracle@oel7v9 ~]$ cd /home/oracle/d09
[oracle@oel7v9 d09]$ mkdir -p rogue_ca client_wallet2 client_tns2
[oracle@oel7v9 d09]$ orapki wallet create -nologo -wallet ./rogue_ca -pwd 'Rogue#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet add -nologo -wallet ./rogue_ca -dn 'CN=Rogue CA,O=other,C=KR' -keysize 2048 -self_signed -validity 365 -sign_alg sha256 -pwd 'Rogue#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet export -nologo -wallet ./rogue_ca -dn 'CN=Rogue CA,O=other,C=KR' -cert ./rogue.cert -pwd 'Rogue#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet create -nologo -wallet ./client_wallet2 -pwd 'Cli2#D09_2026' -auto_login
Operation is successfully completed.
[oracle@oel7v9 d09]$ orapki wallet add -nologo -wallet ./client_wallet2 -trusted_cert -cert ./rogue.cert -pwd 'Cli2#D09_2026'
Operation is successfully completed.
[oracle@oel7v9 d09]$ cd /home/oracle/d09/client_tns2
[oracle@oel7v9 client_tns2]$ printf '%s\n' 'WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = /home/oracle/d09/client_wallet2)))' 'SQLNET.AUTHENTICATION_SERVICES = (TCPS)' 'SSL_CLIENT_AUTHENTICATION = TRUE' > sqlnet.ora
[oracle@oel7v9 client_tns2]$ cp ../client_tns/tnsnames.ora .
[oracle@oel7v9 client_tns2]$ export TNS_ADMIN=/home/oracle/d09/client_tns2
[oracle@oel7v9 client_tns2]$ printf '%s\n' 'COL usr FOR a10' 'COL proto FOR a6' 'COL auth FOR a9' "SELECT SYS_CONTEXT('USERENV','SESSION_USER') usr, SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') proto, SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') auth FROM dual;" | sqlplus -s -L scott/tiger@d09_tls
ERROR:
ORA-29024: Certificate validation failure


SP2-0751: Unable to connect to Oracle.  Exiting SQL*Plus
-- ★ 클라이언트 지갑에 Rogue CA만 있다. 서버 인증서를 서명한 D09 Root CA를 믿지 못해 ORA-29024가 난다. 비밀번호 로그인이라도 TLS 단계에서 먼저 막힌다.
-- ★ 운영에서는 CA를 바꿀 때 같은 오류가 날 수 있다. 새 CA 인증서를 클라이언트 지갑에 먼저 배포한 뒤 서버 인증서를 바꾸면 피할 수 있다.
@END

@P [12] 리스너 로그에서 실패 확인
@CODE
[oracle@oel7v9 ~]$ export TNS_ADMIN=/home/oracle/d09/server_tns
[oracle@oel7v9 ~]$ lsnrctl status LISTENER_D09 | grep -i 'Log File'
Listener Log File         /u01/app/oracle/diag/tnslsnr/oel7v9/listener_d09/alert/log.xml
[oracle@oel7v9 ~]$ grep -B4 'TNS-00542' /u01/app/oracle/diag/tnslsnr/oel7v9/listener_d09/trace/listener_d09.log | tail -6
--
2026-10-28T08:53:11.385578+09:00
28-OCT-2026 08:53:11 * (CONNECT_DATA=(SERVICE_NAME=orcl)(CID=(PROGRAM=sqlplus)(HOST=oel7v9.localdomain)(USER=oracle))) * (ADDRESS=(PROTOCOL=tcps)(HOST=172.16.225.50)(PORT=9506)) * establish * orcl * 0
2026-10-28T08:53:13.997559+09:00
28-OCT-2026 08:53:13 * (ADDRESS=(PROTOCOL=tcps)(HOST=172.16.225.50)(PORT=9598)) * <unknown connect data> * 542
TNS-00542: SSL Handshake failed
-- ★ 서버 쪽에는 클라이언트의 ORA-29024 대신 TNS-00542: SSL Handshake failed가 남는다. 접속 데이터도 <unknown connect data>로 찍혀 어떤 서비스로 오려 했는지 알 수 없다.
-- ★ 바로 앞 줄은 성공한 접속(establish * orcl * 0)이다. 실패 원인 구분은 클라이언트 쪽 오류 번호로 한다.
@END

@P [13] 철거: 리스너와 파일
@CODE
[oracle@oel7v9 ~]$ export TNS_ADMIN=/home/oracle/d09/server_tns
[oracle@oel7v9 ~]$ lsnrctl stop LISTENER_D09 | tail -2
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=oel7v9)(PORT=2484)))
The command completed successfully
[oracle@oel7v9 ~]$ unset TNS_ADMIN
[oracle@oel7v9 ~]$ rm -rf /home/oracle/d09
[oracle@oel7v9 ~]$ ls -d /home/oracle/d09
ls: cannot access /home/oracle/d09: No such file or directory
[oracle@oel7v9 ~]$ netstat -lnt | grep -c ':2484 '
0
[oracle@oel7v9 ~]$ md5sum $ORACLE_HOME/network/admin/listener.ora $ORACLE_HOME/network/admin/sqlnet.ora
10d7442986929ce050326f853ae81d8a  /u01/app/oracle/product/19.3.0/dbhome_1/network/admin/listener.ora
4842bc60cd301476deead5025d27f03e  /u01/app/oracle/product/19.3.0/dbhome_1/network/admin/sqlnet.ora
[oracle@oel7v9 ~]$ lsnrctl status | grep -i 'Alias\|PROTOCOL'
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=oel7v9)(PORT=1521)))
Alias                     LISTENER
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=oel7v9)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcps)(HOST=oel7v9)(PORT=5500))(Security=(my_wallet_directory=/u01/app/oracle/admin/orcl/xdb_wallet))(Presentation=HTTP)(Session=RAW))
-- ★ LISTENER_D09를 정지하고 디렉터리를 지웠다. 2484 포트는 다시 비었고 공용 listener.ora·sqlnet.ora의 md5는 [1]과 같다.
@END

@P [14] 철거: 사용자
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> DROP USER d09_cert CASCADE;

User dropped.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username = 'D09_CERT';

  COUNT(*)
----------
         0

1 row selected.
-- ★ 인증서 사용자 0건. 이것으로 실습 전 상태다.
@END

@H3 09.4  정리와 확인 포인트
@B 인증서 발급은 요청 → CA 서명 → CA 인증서 가져오기 → 사용자 인증서 가져오기 순서다. 키 길이와 서명 알고리즘은 orapki가 검사하지 않으므로 명령에 명시한다.
@B TLS 접속 여부는 NETWORK_PROTOCOL=tcps로 판정한다. V$SESSION_CONNECT_INFO의 배너와 AUTHENTICATION_TYPE으로는 구분되지 않는다.
@B 오류 번호로 실패 위치를 가른다. ORA-29024는 신뢰 사슬, ORA-29003은 서버 DN 대조, ORA-28759는 지갑 위치, ORA-01017은 TLS 통과 뒤 DN과 DB 사용자 불일치다.
@B SSL_SERVER_DN_MATCH=YES는 별칭마다 SSL_SERVER_CERT_DN을 함께 적을 때 동작이 분명하다. 적지 않으면 HOST 값과 인증서 CN의 일치에 기대게 된다.
@B 전용 TNS_ADMIN과 별도 리스너로 구성하면 기존 1521 접속을 건드리지 않고 TLS를 시험하고 되돌릴 수 있다.
@H2 실습 10  FGA·통합 감사와 감사 기록 관리
@TBL
항목 | 내용
목표 | 값 조건 기반 FGA와 통합 감사 정책을 함께 걸고, 혼합 모드에서 두 기록이 어디에 남는지 확인한다. 감사 기록 보호 장치와 DBMS_AUDIT_MGMT 정리 절차를 기존 기록을 지우지 않는 방식으로 실행한다.
소요 | 50분
접속 | SYS, D10_SEC(AUDIT_ADMIN), D10_CLERK(업무 계정), D10_AUD(AUDIT_VIEWER)
변경 | 사용자 4개, FGA 정책 1개, 통합 감사 정책 1개, 아카이브 기준 시각(실습 중 설정 후 해제). 감사 기록은 남음
@END

@H3 10.1  실습 전에 — 감사는 남기는 것보다 읽고 지키고 비우는 것이 일이다
@B 19c의 기본 설치는 혼합 모드다. V$OPTION의 Unified Auditing이 FALSE이면 AUDIT_TRAIL 같은 기존 감사 파라미터와 통합 감사 정책이 함께 동작함. ORA_SECURECONFIG, ORA_LOGON_FAILURES 두 기본 정책이 켜져 있다.
@B FGA는 '어떤 값에 접근했는가'를 감사한다. audit_condition은 행마다 평가되고, audit_column에 적은 컬럼을 SELECT 목록이나 WHERE 절에서 참조할 때만 기록이 생긴다. 조건을 만족하는 행이 결과에 하나라도 섞이면 문장 하나가 기록 한 건이 된다.
@B 혼합 모드(19.3)의 FGA 기록은 FGA_LOG$(DBA_FGA_AUDIT_TRAIL)에 남고 UNIFIED_AUDIT_TRAIL에는 남지 않는다(원 교안 12장 실습 01). 문서 기준으로는 순수 통합 감사로 바꾸면 FGA 기록도 통합 감사 기록으로 간다.
@B 통합 감사 정책은 CREATE AUDIT POLICY로 정의하고 AUDIT POLICY ... BY 사용자로 켠다. 성공·실패를 모두 기록하는 것이 기본이다. 정책이 켜진 상태에서는 DROP할 수 없음(ORA-46361).
@B 감사 권한은 역할로 나뉜다.
@TBL
역할 | 할 수 있는 것
AUDIT_ADMIN | 통합 감사 정책 생성·활성화, DBMS_FGA, DBMS_AUDIT_MGMT 실행
AUDIT_VIEWER | UNIFIED_AUDIT_TRAIL, DBA_FGA_AUDIT_TRAIL 등 감사 기록 조회
@END
@B 통합 감사 기록은 AUDSYS.AUD$UNIFIED에 있고 SYS도 DML·DDL을 할 수 없다(ORA-46385). 그 시도 자체가 감사 기록으로 남는다. 기록을 지우는 정상 경로는 DBMS_AUDIT_MGMT뿐이다.
@B DBMS_AUDIT_MGMT 정리는 '아카이브 기준 시각'을 중심으로 돈다. 외부 보관을 마친 시각을 SET_LAST_ARCHIVE_TIMESTAMP로 알려 주면 CLEAN_AUDIT_TRAIL(use_last_arch_timestamp => TRUE)은 그보다 오래된 기록만 지운다. 정리 작업(CREATE_PURGE_JOB)은 이 과정을 스케줄러에 등록함.
@B 통합 감사 기록은 INIT_CLEANUP이 필요 없다. 호출하면 ORA-46250이 남. 반대로 AUD$·FGA_LOG$는 INIT_CLEANUP 없이 정리하면 ORA-46258이다. INIT_CLEANUP은 FGA_LOG$를 SYSAUX로 옮기기도 한다(원 교안 13장 실습 03). 이번 실습은 FGA_LOG$를 건드리지 않는다.
@B 감사 기록을 syslog로도 보내려면 UNIFIED_AUDIT_SYSTEMLOG(통합 감사)나 AUDIT_SYSLOG_LEVEL(기존 감사)을 쓴다. 둘 다 정적 파라미터라 재기동이 필요해 이번 실습에서는 다루지 않는다. 설정과 결과는 원 교안 13장 실습 04에 있다.
@NOTE 이 실습이 남기는 것
감사 기록은 실습 객체를 지워도 남는다. 사용자를 지운 뒤에도 D10_CLERK의 기록은 그대로 조회됨. 실습 9단계의 정리 실행은 가장 오래된 기록보다 하루 앞선 기준 시각을 써서 삭제 0건으로 끝난다.
@END

@H3 10.2  진행 순서
@TBL
단계 | 하는 일 | 확인할 것
[1] 감사 모드 확인과 준비 | 감사 모드·AUDIT_TRAIL 확인, 역할별 계정과 테이블 | Unified Auditing FALSE, audit_trail DB
[2] FGA 정책 | 급여 10,000 초과 행의 SALARY·COMMISSION_PCT 접근 감사 | AUDIT_ADMIN의 딕셔너리 조회 ORA-00942
[3] 업무 계정의 조회와 변경 | 감사 컬럼 참조 여부·조건 충족 여부가 다른 문장 5개 | 모든 문장 정상 실행
[4] FGA 기록 확인 | AUDIT_VIEWER로 건수 조회, SYS로 문장 확인, 통합 감사 쪽 확인 | 3건, UNIFIED_AUDIT_TRAIL 0건
[5] 통합 감사 정책 | UPDATE·DELETE 감사 정책을 D10_CLERK에 켜고, 권한 없는 DELETE 시도 | BY USER, 성공·실패 YES, DELETE는 ORA-01031
[6] 통합 감사 기록 확인 | AUDIT_VIEWER로 정책별 기록 조회 | UPDATE 0, DELETE 2004
[7] 정책 관리와 기록 보호 | 켜진 정책 DROP, NOAUDIT 후 DROP, SYS의 AUD$UNIFIED DELETE | ORA-46361, ORA-46385와 그 기록
[8] DBMS_AUDIT_MGMT — 정리 기준 시각 | 정리 설정 조회, 통합 감사 INIT_CLEANUP, 가장 오래된 기록보다 하루 앞선 기준 시각 설정 | ORA-46250, 기준 시각 1행
[9] 정리 실행과 결과 확인 | 기준 시각으로 CLEAN_AUDIT_TRAIL, 기준 시각 해제, 관리 호출 기록 조회 | 가장 오래된 기록 그대로, 건수는 증가
[10] 정리와 확인 | FGA 정책·사용자 삭제, 기본 정책 상태 확인 | 정책 0, 활성 정책은 기본 2개
@END

@H3 10.3  실습 스크립트

@P [1] 감사 모드 확인과 준비
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL parameter FOR a20
SYS@orcl> COL value FOR a10
SYS@orcl> SELECT parameter, value FROM v$option WHERE parameter = 'Unified Auditing';

PARAMETER            VALUE
-------------------- ----------
Unified Auditing     FALSE

1 row selected.

SYS@orcl> SHOW PARAMETER audit_trail

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
audit_trail                          string      DB
SYS@orcl> CREATE USER d10_own IDENTIFIED BY d10_own QUOTA 10M ON users;

User created.

SYS@orcl> CREATE USER d10_sec IDENTIFIED BY d10_sec;

User created.

SYS@orcl> CREATE USER d10_clerk IDENTIFIED BY d10_clerk;

User created.

SYS@orcl> CREATE USER d10_aud IDENTIFIED BY d10_aud;

User created.

SYS@orcl> GRANT CREATE SESSION TO d10_own, d10_sec, d10_clerk, d10_aud;

Grant succeeded.

SYS@orcl> GRANT AUDIT_ADMIN TO d10_sec;

Grant succeeded.

SYS@orcl> GRANT AUDIT_VIEWER TO d10_aud;

Grant succeeded.

SYS@orcl> CREATE TABLE d10_own.emp AS
  2    SELECT employee_id, last_name, department_id, salary, commission_pct FROM hr.employees;

Table created.

SYS@orcl> GRANT SELECT, UPDATE ON d10_own.emp TO d10_clerk;

Grant succeeded.

-- ★ 혼합 모드다. D10_SEC에는 AUDIT_ADMIN, D10_AUD에는 AUDIT_VIEWER만 주었다. 정책을 만드는 계정과 기록을 읽는 계정을 분리함.
@END

@P [2] FGA 정책
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> BEGIN
  2    DBMS_FGA.ADD_POLICY(
  3      object_schema   => 'D10_OWN',
  4      object_name     => 'EMP',
  5      policy_name     => 'D10_SAL_FGA',
  6      audit_condition => 'SALARY > 10000',
  7      audit_column    => 'SALARY,COMMISSION_PCT',
  8      statement_types => 'SELECT,UPDATE',
  9      audit_trail     => DBMS_FGA.DB + DBMS_FGA.EXTENDED);
 10  END;
 11  /

PL/SQL procedure successfully completed.

D10_SEC@orcl> COL policy_name FOR a12
D10_SEC@orcl> COL policy_text FOR a16
D10_SEC@orcl> COL policy_column FOR a24
D10_SEC@orcl> SELECT policy_name, policy_text, policy_column, enabled, sel, upd, del FROM dba_audit_policies WHERE object_schema = 'D10_OWN';
SELECT policy_name, policy_text, policy_column, enabled, sel, upd, del FROM dba_audit_policies WHERE object_schema = 'D10_OWN'
                                                                            *
ERROR at line 1:
ORA-00942: table or view does not exist


D10_SEC@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL policy_name FOR a12
SYS@orcl> COL policy_text FOR a16
SYS@orcl> COL policy_column FOR a24
SYS@orcl> SELECT policy_name, policy_text, policy_column, enabled, sel, upd, del FROM dba_audit_policies WHERE object_schema = 'D10_OWN';

POLICY_NAME  POLICY_TEXT      POLICY_COLUMN            ENA SEL UPD DEL
------------ ---------------- ------------------------ --- --- --- ---
D10_SAL_FGA  SALARY > 10000   SALARY                   YES YES YES NO

1 row selected.

SYS@orcl> COL column_name FOR a16
SYS@orcl> SELECT policy_name, policy_column column_name FROM dba_audit_policy_columns WHERE object_schema = 'D10_OWN';

POLICY_NAME  COLUMN_NAME
------------ ----------------
D10_SAL_FGA  SALARY
D10_SAL_FGA  COMMISSION_PCT

2 rows selected.

-- ★ AUDIT_ADMIN만으로 DBMS_FGA.ADD_POLICY가 됐다. 그런데 같은 계정이 DBA_AUDIT_POLICIES를 조회하면 ORA-00942다. 정책 관리 권한과 딕셔너리 조회 권한은 따로 간다.
--    DBA_AUDIT_POLICIES의 POLICY_COLUMN에는 첫 컬럼(SALARY)만 보인다. 감사 컬럼 전체는 DBA_AUDIT_POLICY_COLUMNS에서 확인한다.
@END

@P [3] 업무 계정의 조회와 변경
@CODE
SQL> CONNECT d10_clerk/d10_clerk
Connected.
D10_CLERK@orcl> SELECT COUNT(*) FROM d10_own.emp WHERE department_id = 90;

  COUNT(*)
----------
         3

1 row selected.

D10_CLERK@orcl> SELECT last_name, salary FROM d10_own.emp WHERE department_id = 90 ORDER BY 1;

LAST_NAME                     SALARY
------------------------- ----------
De Haan                        17000
King                           24000
Kochhar                        17000

3 rows selected.

D10_CLERK@orcl> SELECT last_name, salary FROM d10_own.emp WHERE department_id = 50 AND ROWNUM <= 2 ORDER BY 1;

LAST_NAME                     SALARY
------------------------- ----------
Fripp                           8200
Weiss                           8000

2 rows selected.

D10_CLERK@orcl> SELECT COUNT(*) FROM d10_own.emp WHERE commission_pct > 0.3;

  COUNT(*)
----------
         4

1 row selected.

D10_CLERK@orcl> UPDATE d10_own.emp SET salary = salary * 1.1 WHERE employee_id = 101;

1 row updated.

D10_CLERK@orcl> ROLLBACK;

Rollback complete.

-- ★ 문장별 예상: 90번 COUNT(*)는 감사 컬럼을 참조하지 않는다. 90번 급여 조회는 조건을 만족한다.
--    50번 급여 조회는 결과 행 급여가 모두 10,000 이하다. 커미션 조건 검색은 WHERE에서 감사 컬럼을 참조한다.
--    101번(급여 17,000) UPDATE는 조건을 만족한다. ROLLBACK을 해도 감사 기록은 남는다.
@END

@P [4] FGA 기록 확인
@CODE
SQL> CONNECT d10_aud/d10_aud
Connected.
D10_AUD@orcl> SELECT COUNT(*) FROM dba_fga_audit_trail
  2   WHERE policy_name = 'D10_SAL_FGA' AND timestamp > SYSDATE - 2/1440;

  COUNT(*)
----------
         3

1 row selected.

D10_AUD@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL db_user FOR a10
SYS@orcl> COL stmt FOR a8
SYS@orcl> COL sql_text FOR a72
SYS@orcl> SELECT db_user, statement_type stmt, sql_text FROM dba_fga_audit_trail
  2   WHERE policy_name = 'D10_SAL_FGA' AND timestamp >= (SELECT created FROM dba_users WHERE username = 'D10_OWN')
  3   ORDER BY timestamp, sql_text;

DB_USER    STMT     SQL_TEXT
---------- -------- ------------------------------------------------------------------------
D10_CLERK  SELECT   SELECT COUNT(*) FROM d10_own.emp WHERE commission_pct > 0.3
D10_CLERK  SELECT   SELECT last_name, salary FROM d10_own.emp WHERE department_id = 90 ORDER
                     BY 1

D10_CLERK  UPDATE   UPDATE d10_own.emp SET salary = salary * 1.1 WHERE employee_id = 101

3 rows selected.

SYS@orcl> SELECT COUNT(*) FROM unified_audit_trail WHERE fga_policy_name = 'D10_SAL_FGA';

  COUNT(*)
----------
         0

1 row selected.

-- ★ 기록은 3건이다. 90번 급여 조회, 커미션 조건 검색, UPDATE만 남았다.
--    COUNT(*)와 50번 조회는 기록되지 않았다. 감사 컬럼을 안 썼거나, 조건을 만족하는 행이 없었다.
--    AUDIT_VIEWER로 DBA_FGA_AUDIT_TRAIL을 읽을 수 있다. 같은 시각 UNIFIED_AUDIT_TRAIL에는 이 정책의 기록이 없다. 혼합 모드의 FGA 기록은 FGA_LOG$에만 있다.
@END

@P [5] 통합 감사 정책
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> CREATE AUDIT POLICY d10_emp_pol
  2    ACTIONS UPDATE ON d10_own.emp, DELETE ON d10_own.emp;

Audit policy created.

D10_SEC@orcl> AUDIT POLICY d10_emp_pol BY d10_clerk;

Audit succeeded.

D10_SEC@orcl> COL policy_name FOR a14
D10_SEC@orcl> COL entity_name FOR a12
D10_SEC@orcl> SELECT policy_name, enabled_option, entity_name, success, failure
  2    FROM audit_unified_enabled_policies WHERE policy_name = 'D10_EMP_POL';

POLICY_NAME    ENABLED_OPTION  ENTITY_NAME  SUC FAI
-------------- --------------- ------------ --- ---
D10_EMP_POL    BY USER         D10_CLERK    YES YES

1 row selected.

D10_SEC@orcl> CONNECT d10_clerk/d10_clerk
Connected.
D10_CLERK@orcl> UPDATE d10_own.emp SET salary = salary + 100 WHERE department_id = 90;

3 rows updated.

D10_CLERK@orcl> DELETE FROM d10_own.emp WHERE employee_id = 100;
DELETE FROM d10_own.emp WHERE employee_id = 100
                    *
ERROR at line 1:
ORA-01031: insufficient privileges


D10_CLERK@orcl> ROLLBACK;

Rollback complete.

-- ★ AUDIT_UNIFIED_ENABLED_POLICIES에서 정책이 사용자 단위로 켜졌고 성공·실패 모두 기록 대상임을 확인했다.
--    D10_CLERK에는 DELETE 권한이 없어 ORA-01031로 실패했다. 실패한 문장도 감사 대상이다.
@END

@P [6] 통합 감사 기록 확인
@CODE
SQL> CONNECT d10_aud/d10_aud
Connected.
D10_AUD@orcl> COL dbusername FOR a10
D10_AUD@orcl> COL action_name FOR a8
D10_AUD@orcl> COL sql_text FOR a62
D10_AUD@orcl> SELECT dbusername, action_name, return_code, sql_text
  2    FROM unified_audit_trail
  3   WHERE unified_audit_policies = 'D10_EMP_POL' AND event_timestamp > SYSTIMESTAMP - INTERVAL '2' MINUTE
  4   ORDER BY event_timestamp;

DBUSERNAME ACTION_N RETURN_CODE SQL_TEXT
---------- -------- ----------- --------------------------------------------------------------
D10_CLERK  UPDATE             0 UPDATE d10_own.emp SET salary = salary + 100 WHERE departmen
                                t_id = 90

D10_CLERK  DELETE          2004 DELETE FROM d10_own.emp WHERE employee_id = 100



2 rows selected.

-- ★ UPDATE는 RETURN_CODE 0, 권한 없는 DELETE는 2004로 남았다. 사용자 화면의 ORA-01031과 다른 번호다. 실패 시도를 찾는 조회는 RETURN_CODE <> 0으로 건다.
--    기록에는 SQL_TEXT가 그대로 있다. 정책 하나만 걸어도 누가 어떤 문장을 실행했는지 남는다.
@END

@P [7] 정책 관리와 기록 보호
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> DROP AUDIT POLICY d10_emp_pol;
DROP AUDIT POLICY d10_emp_pol
*
ERROR at line 1:
ORA-46361: Audit policy cannot be dropped as it is currently enabled.


D10_SEC@orcl> NOAUDIT POLICY d10_emp_pol BY d10_clerk;

Noaudit succeeded.

D10_SEC@orcl> DROP AUDIT POLICY d10_emp_pol;

Audit Policy dropped.

D10_SEC@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> DELETE FROM audsys.aud$unified WHERE 1 = 0;
DELETE FROM audsys.aud$unified WHERE 1 = 0
                   *
ERROR at line 1:
ORA-46385: DML and DDL operations are not allowed on table "AUDSYS"."AUD$UNIFIED".


SYS@orcl> COL dbusername FOR a10
SYS@orcl> COL action_name FOR a8
SYS@orcl> COL object_name FOR a12
SYS@orcl> SELECT dbusername, action_name, object_name, return_code FROM unified_audit_trail
  2   WHERE object_schema = 'AUDSYS' AND object_name = 'AUD$UNIFIED'
  3     AND event_timestamp >= (SELECT created FROM dba_users WHERE username = 'D10_OWN');

DBUSERNAME ACTION_N OBJECT_NAME  RETURN_CODE
---------- -------- ------------ -----------
SYS        DELETE   AUD$UNIFIED        46385

1 row selected.

-- ★ 켜진 정책은 ORA-46361로 DROP이 거부됐다. NOAUDIT은 AUDIT 때와 같은 BY 절로 해야 실제로 꺼진다.
--    SYS가 0건 조건으로 DELETE를 해도 ORA-46385로 막혔다. 실행 전에 거부되고, 그 시도가 RETURN_CODE 46385로 남았다.
@END

@P [8] DBMS_AUDIT_MGMT — 정리 기준 시각
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> COL parameter_name FOR a30
D10_SEC@orcl> COL parameter_value FOR a14
D10_SEC@orcl> COL audit_trail FOR a20
D10_SEC@orcl> SELECT parameter_name, parameter_value, audit_trail FROM dba_audit_mgmt_config_params
  2   WHERE audit_trail IN ('UNIFIED AUDIT TRAIL', 'FGA AUDIT TRAIL') ORDER BY 3, 1;

PARAMETER_NAME                 PARAMETER_VALU AUDIT_TRAIL
------------------------------ -------------- --------------------
DB AUDIT CLEAN BATCH SIZE      10000          FGA AUDIT TRAIL
DB AUDIT TABLESPACE            SYSTEM         FGA AUDIT TRAIL
AUDIT FILE MAX AGE             5              UNIFIED AUDIT TRAIL
AUDIT FILE MAX SIZE            10000          UNIFIED AUDIT TRAIL
AUDIT WRITE MODE               QUEUED WRITE M UNIFIED AUDIT TRAIL
                               ODE

DB AUDIT TABLESPACE            SYSAUX         UNIFIED AUDIT TRAIL

6 rows selected.

D10_SEC@orcl> EXEC DBMS_AUDIT_MGMT.INIT_CLEANUP(DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED, 24)
BEGIN DBMS_AUDIT_MGMT.INIT_CLEANUP(DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED, 24); END;

*
ERROR at line 1:
ORA-46250: Invalid value for argument 'AUDIT_TRAIL_TYPE'
ORA-06512: at "AUDSYS.DBMS_AUDIT_MGMT", line 204
ORA-06512: at "AUDSYS.DBMS_AUDIT_MGMT", line 717
ORA-06512: at line 1


D10_SEC@orcl> COL oldest FOR a30
D10_SEC@orcl> SELECT COUNT(*) total, TO_CHAR(MIN(event_timestamp_utc), 'YYYY-MM-DD HH24:MI:SS') oldest FROM unified_audit_trail;

     TOTAL OLDEST
---------- ------------------------------
      2290 2026-07-29 06:06:31

1 row selected.

D10_SEC@orcl> DECLARE
  2    v_cut TIMESTAMP;
  3  BEGIN
  4    SELECT MIN(event_timestamp_utc) - INTERVAL '1' DAY INTO v_cut FROM unified_audit_trail;
  5    DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
  6      audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
  7      last_archive_time => v_cut);
  8  END;
  9  /

PL/SQL procedure successfully completed.

D10_SEC@orcl> COL last_archive_ts FOR a36
D10_SEC@orcl> SELECT audit_trail, last_archive_ts FROM dba_audit_mgmt_last_arch_ts;

AUDIT_TRAIL          LAST_ARCHIVE_TS
-------------------- ------------------------------------
UNIFIED AUDIT TRAIL  28-JUL-26 06.06.31.706784 AM +00:00

1 row selected.

-- ★ 통합 감사 기록은 SYSAUX에 있고, 이 버전의 쓰기 모드 설정값은 QUEUED WRITE MODE로 표시됐다. FGA 기록 테이블은 아직 SYSTEM에 있다.
--    통합 감사 기록에 INIT_CLEANUP을 부르자 ORA-46250이다. 초기화 없이 바로 정리할 수 있는 대상이다.
--    기준 시각은 가장 오래된 기록(2026-07-29 06:06:31 UTC)보다 하루 앞선 값이다. 이 시각보다 오래된 기록은 없다.
@END

@P [9] 정리 실행과 결과 확인
@CODE
SQL> CONNECT d10_sec/d10_sec
Connected.
D10_SEC@orcl> COL oldest FOR a30
D10_SEC@orcl> BEGIN
  2    DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
  3      audit_trail_type        => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
  4      use_last_arch_timestamp => TRUE);
  5  END;
  6  /

PL/SQL procedure successfully completed.

D10_SEC@orcl> SELECT COUNT(*) total, TO_CHAR(MIN(event_timestamp_utc), 'YYYY-MM-DD HH24:MI:SS') oldest FROM unified_audit_trail;

     TOTAL OLDEST
---------- ------------------------------
      2292 2026-07-29 06:06:31

1 row selected.

D10_SEC@orcl> EXEC DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP(DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED)

PL/SQL procedure successfully completed.

D10_SEC@orcl> SELECT COUNT(*) FROM dba_audit_mgmt_last_arch_ts;

  COUNT(*)
----------
         0

1 row selected.

D10_SEC@orcl> COL dbusername FOR a10
D10_SEC@orcl> COL action_name FOR a14
D10_SEC@orcl> COL object_name FOR a16
D10_SEC@orcl> COL sql_text FOR a50
D10_SEC@orcl> SELECT dbusername, action_name, object_name, SUBSTR(sql_text, 1, 50) sql_text FROM unified_audit_trail
  2   WHERE object_name = 'DBMS_AUDIT_MGMT' AND dbusername = 'D10_SEC'
  3     AND event_timestamp >= (SELECT created FROM dba_users WHERE username = 'D10_OWN')
  4   ORDER BY event_timestamp;

DBUSERNAME ACTION_NAME    OBJECT_NAME      SQL_TEXT
---------- -------------- ---------------- --------------------------------------------------
D10_SEC    EXECUTE        DBMS_AUDIT_MGMT  BEGIN DBMS_AUDIT_MGMT.INIT_CLEANUP(DBMS_AUDIT_MGMT


D10_SEC    EXECUTE        DBMS_AUDIT_MGMT  DECLARE
                                             v_cut TIMESTAMP;
                                           BEGIN
                                             SELECT MIN(even

D10_SEC    EXECUTE        DBMS_AUDIT_MGMT  BEGIN
                                             DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
                                               aud

D10_SEC    EXECUTE        DBMS_AUDIT_MGMT  BEGIN DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP



4 rows selected.

-- ★ 정리 후에도 가장 오래된 기록은 그대로다. 지워진 것이 없다. 건수는 오히려 늘었다. 정리 호출 자체가 기록되기 때문이다.
--    DBMS_AUDIT_MGMT 실행은 감사 정책이 없어도 항상 기록된다. D10_SEC의 호출 네 건(INIT_CLEANUP 실패 포함)이 모두 보인다.
--    실무에서는 외부 보관을 마친 시각을 기준으로 주고, 정리 작업으로 주기 실행한다. CLEAR_LAST_ARCHIVE_TIMESTAMP로 기준 시각을 지워 원래 상태로 돌렸다.
@END

@P [10] 정리와 확인
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> SELECT COUNT(*) FROM dba_fga_audit_trail WHERE policy_name = 'D10_SAL_FGA' AND timestamp >= (SELECT created FROM dba_users WHERE username = 'D10_OWN');

  COUNT(*)
----------
         4

1 row selected.

SYS@orcl> EXEC DBMS_FGA.DROP_POLICY('D10_OWN', 'EMP', 'D10_SAL_FGA')

PL/SQL procedure successfully completed.

SYS@orcl> DROP USER d10_clerk CASCADE;

User dropped.

SYS@orcl> DROP USER d10_aud CASCADE;

User dropped.

SYS@orcl> DROP USER d10_sec CASCADE;

User dropped.

SYS@orcl> DROP USER d10_own CASCADE;

User dropped.

SYS@orcl> SELECT COUNT(*) FROM dba_audit_policies WHERE object_schema = 'D10_OWN';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) FROM audit_unified_policies WHERE policy_name = 'D10_EMP_POL';

  COUNT(*)
----------
         0

1 row selected.

SYS@orcl> COL policy_name FOR a20
SYS@orcl> COL entity_name FOR a10
SYS@orcl> SELECT policy_name, entity_name FROM audit_unified_enabled_policies ORDER BY 1;

POLICY_NAME          ENTITY_NAM
-------------------- ----------
ORA_LOGON_FAILURES   ALL USERS
ORA_SECURECONFIG     ALL USERS

2 rows selected.

SYS@orcl> SELECT COUNT(*) FROM dba_users WHERE username LIKE 'D10%';

  COUNT(*)
----------
         0

1 row selected.

-- ★ FGA 기록 4건은 정책과 사용자를 지운 뒤에도 남는다. 3단계 3건에 5단계의 90번 부서 UPDATE가 더해졌다.
--    활성 통합 감사 정책은 실습 전과 같은 ORA_SECURECONFIG, ORA_LOGON_FAILURES 두 개다.
@END

@H3 10.4  정리와 확인 포인트
@B 혼합 모드에서 FGA 기록은 FGA_LOG$, 통합 감사 정책 기록은 UNIFIED_AUDIT_TRAIL에 따로 남는다. 조회·수집 경로를 둘 다 만든다.
@B FGA는 감사 컬럼 참조와 행 조건을 모두 만족할 때만 기록한다. ROLLBACK해도 기록은 남는다.
@B 통합 감사의 권한 실패 기록은 RETURN_CODE 2004로 남는다. 실패 탐지 조회는 RETURN_CODE <> 0으로 건다.
@B AUD$UNIFIED는 SYS도 직접 지울 수 없고, 시도는 기록된다. 삭제는 DBMS_AUDIT_MGMT 기준 시각과 정리 작업으로만 한다.
@B 정리 기준 시각은 외부 보관이 끝난 시각이어야 한다. 보관 확인 없이 기준 시각을 앞당기면 되돌릴 수 없는 삭제가 일어난다.
