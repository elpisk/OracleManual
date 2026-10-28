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
