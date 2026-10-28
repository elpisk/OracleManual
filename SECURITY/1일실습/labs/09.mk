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
