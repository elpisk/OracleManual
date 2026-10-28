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
