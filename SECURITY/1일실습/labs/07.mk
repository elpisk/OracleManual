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
