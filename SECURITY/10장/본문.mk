@H1 제10장  Transparent Data Encryption

@H2 10.1  학습 목표

@P 데이터 파일, 백업 파일, 덤프 파일이 서버 밖으로 나가면 데이터베이스의 접근 제어는 아무 소용이 없다. Transparent Data Encryption(TDE)은 디스크에 기록되는 데이터를 암호화해, 파일을 손에 넣어도 키 없이는 읽을 수 없게 한다.

@B TDE가 막는 위협(저장 매체·파일 유출)과 막지 못하는 위협(정상 권한을 가진 사용자)을 구분해 설명할 수 있다.
@B 2계층 키 구조(마스터 암호화 키와 테이블·테이블스페이스 키)가 동작하는 방식과 키 교체가 빠른 이유를 설명할 수 있다.
@B 19c 방식인 `WALLET_ROOT`와 `TDE_CONFIGURATION`으로 키스토어 위치를 구성하고, 원본 자료의 sqlnet.ora 방식과 차이를 말할 수 있다.
@B `ADMINISTER KEY MANAGEMENT`로 키스토어를 만들고, 열고, 마스터 키를 설정하고, auto-login 키스토어를 만들 수 있다.
@B 컬럼 암호화와 테이블스페이스 암호화의 차이를 알고 업무 조건에 맞게 고를 수 있다.
@B 기존 테이블스페이스를 온라인으로 암호화하고, 마스터 키를 교체하고, 키스토어를 백업할 수 있다.
@B V$ENCRYPTION_WALLET, V$ENCRYPTION_KEYS, V$ENCRYPTED_TABLESPACES, DBA_ENCRYPTED_COLUMNS로 TDE 상태를 점검할 수 있다.

@H2 10.2  TDE의 개념

@H3 10.2.1  저장 데이터 암호화가 필요한 이유

@B 데이터베이스 접근 제어(권한, VPD, Redaction)는 SQL을 통해 들어오는 요청에만 작동한다. 데이터 파일을 OS 수준에서 복사해 가면 SQL을 거치지 않는다.
@B 데이터 파일은 블록 형식이라 `strings` 같은 단순한 도구로도 문자열 데이터를 상당 부분 읽어 낼 수 있다.
@B 유출 경로는 생각보다 다양하다. 폐기한 디스크, 외부 보관 백업 테이프, 테스트 서버로 복사한 데이터 파일, 공유 디렉터리에 남은 Data Pump 덤프 파일이 모두 해당한다.
@B 여러 규제(개인정보 보호, 카드 산업 보안 표준 등)가 저장 데이터의 암호화를 요구한다. TDE는 애플리케이션을 고치지 않고 이 요구를 충족하는 수단이다.
@B 스토리지 장비나 OS 수준의 디스크 암호화도 있다. 이 방식은 디스크를 떼어 가는 경우는 막지만, 서버에 로그인한 OS 사용자가 파일을 복사하면 평문 파일이 나온다. TDE는 복사된 파일도 암호문으로 남는다.

@H3 10.2.2  "투명"의 의미

@B 데이터를 쓸 때 데이터베이스가 암호화하고, 읽을 때 복호화한다. 애플리케이션 SQL, 사용자 권한, 실행 계획은 바뀌지 않는다.
@B 권한이 있는 사용자는 평소처럼 평문을 본다. TDE는 사용자를 구분하지 않는다.
@B 따라서 TDE는 "SELECT 권한을 가진 사용자가 데이터를 보는 것"을 막지 못한다. 그런 통제는 권한, VPD(7장), Data Redaction(8장)이 맡는다.
@B 반대로 DBMS_CRYPTO(9장)로 애플리케이션이 직접 암호화하면 SQL로 읽어도 암호문이 나온다. 대신 애플리케이션이 키를 관리하고 암·복호화를 직접 호출해야 한다.
@B 원본 자료는 TDE를 "Transparent"와 "Data Encryption" 두 말로 나눠 설명한다. 앞의 말은 애플리케이션을 고치지 않아도 된다는 점을, 뒤의 말은 보호 대상이 디스크에 저장되는 데이터(Data at Rest)임을 가리킨다.

@TBL
구분 | TDE | DBMS_CRYPTO
암·복호화 주체 | 데이터베이스 엔진 | 애플리케이션 코드
애플리케이션 변경 | 없음 | 암·복호화 호출 추가
SQL로 조회한 결과 | 평문 | 암호문(복호화 호출 전)
키 관리 | 키스토어와 마스터 키 | 애플리케이션 책임
라이선스 | Advanced Security 옵션 | 기본 기능
@END

@H3 10.2.3  라이선스

@B TDE는 Oracle Advanced Security 옵션의 기능이다. Enterprise Edition에 별도 옵션 라이선스가 필요하다.
@B 같은 옵션에 Data Redaction(8장)도 포함된다. 실습 VM은 교육용이며 운영 DB에 적용할 때는 라이선스 보유 여부를 먼저 확인한다.
@B 키스토어를 만들고 마스터 키를 설정하는 것만으로는 데이터가 암호화되지 않는다. 암호화된 컬럼이나 테이블스페이스를 만드는 시점부터 옵션 사용으로 본다.

@H2 10.3  키 구조

@H3 10.3.1  2계층 키

@TBL
계층 | 이름 | 저장 위치 | 하는 일
1 | TDE 마스터 암호화 키(MEK) | 키스토어(지갑 파일 ewallet.p12 등) | 2계층 키를 암호화
2 | 테이블스페이스 키 | 데이터 파일 헤더(암호화된 채) | 테이블스페이스 블록 암호화
2 | 테이블 키(컬럼 암호화) | 데이터 딕셔너리(암호화된 채) | 테이블의 암호화 컬럼 값 암호화
@END

@B 실제 데이터를 암호화하는 키는 2계층 키다. 2계층 키는 마스터 키로 암호화된 상태로 데이터베이스 안에 저장된다.
@B 마스터 키는 데이터베이스 밖의 키스토어에만 있다. 데이터 파일과 키스토어를 함께 잃지 않는 한 데이터 파일만으로는 복호화할 수 없다.
@B 마스터 키를 교체하면 2계층 키를 새 마스터 키로 다시 암호화하기만 한다. 데이터 블록을 다시 암호화하지 않으므로 수 TB 데이터베이스에서도 마스터 키 교체는 금방 끝난다.
@B 2계층 키 자체를 바꾸는 작업(테이블스페이스 rekey)은 블록을 다시 암호화하므로 시간이 걸린다. 10.7.3절에서 다룬다.
@B 실습 05에서 마스터 키를 교체한 직후에도 암호화 테이블과 암호화 컬럼이 바로 조회됐다. 데이터를 다시 암호화하지 않았기 때문에 교체가 순식간에 끝났다.

@H3 10.3.2  키스토어 종류

@B 소프트웨어 키스토어는 파일 시스템의 지갑 파일이다. 이 장의 실습이 쓰는 방식이다.
@B 비밀번호 키스토어(ewallet.p12)는 열 때마다 비밀번호가 필요하다. 인스턴스를 재기동하면 닫힌 상태로 시작한다.
@B auto-login 키스토어(cwallet.sso)는 비밀번호 없이 열린다. 인스턴스가 시작되면 자동으로 열린다. local auto-login은 만든 호스트에서만 열린다.
@B 하드웨어 보안 모듈(HSM)이나 Oracle Key Vault 같은 외부 키스토어도 쓸 수 있다. 이 경우 TDE_CONFIGURATION의 KEYSTORE_CONFIGURATION 값이 HSM, OKV 등으로 바뀐다.
@B 외부 키스토어는 키를 DB 서버 밖에 두므로 서버 파일 시스템을 통째로 얻어도 키가 나오지 않는다. 데이터베이스가 많을수록 키를 한곳에서 관리하는 장점이 커진다.

@H3 10.3.3  키스토어 상태

@TBL
STATUS | 의미
NOT_AVAILABLE | 지정된 위치에 키스토어 파일이 없음
CLOSED | 키스토어가 있으나 닫혀 있음. 암호화된 데이터에 접근하면 ORA-28365
OPEN_NO_MASTER_KEY | 열려 있으나 마스터 키가 아직 설정되지 않음
OPEN | 열려 있고 마스터 키가 있어 암·복호화 가능
OPEN_UNKNOWN_MASTER_KEY_STATUS | 열려 있으나 마스터 키 존재 여부를 판단할 수 없음(주로 읽기 전용 Standby 등)
@END

@B V$ENCRYPTION_WALLET의 WALLET_TYPE은 PASSWORD, AUTOLOGIN, LOCAL_AUTOLOGIN, UNKNOWN(닫혀 있어 판단 불가) 중 하나다.
@B 같은 디렉터리에 ewallet.p12와 cwallet.sso가 모두 있으면 인스턴스는 cwallet.sso를 먼저 쓴다. 비밀번호로 닫은 뒤에도 auto-login으로 다시 열려 있는 모습이 나타나는 이유다.

@H3 10.3.4  무엇이 암호화되는가

@TBL
대상 | 테이블스페이스 암호화 | 컬럼 암호화
데이터 파일 블록 | 암호화 | 해당 컬럼 값만 암호화
리두·아카이브 로그 | 해당 데이터 암호화 | 해당 컬럼 값 암호화
언두·임시 세그먼트 | 해당 데이터 암호화 | 해당 컬럼 값 암호화
버퍼 캐시(SGA) | 평문 | 암호화된 상태
RMAN 백업 셋 | 암호화된 블록 그대로 | 암호화된 값 그대로
Data Pump 덤프 | 기본은 평문 | 기본은 평문(경고 출력)
네트워크 전송 | 평문 | 평문
@END

@B 표에서 "평문"인 곳이 TDE가 보호하지 않는 구간이다. 덤프 파일과 네트워크는 다른 기능으로 막아야 한다.
@B 테이블스페이스 암호화가 버퍼 캐시에서 평문이라는 사실은 약점이 아니라 설계다. 메모리 덤프를 얻을 수 있는 공격자는 이미 키스토어도 얻을 수 있는 위치에 있다고 본다.

@H3 10.3.5  상태가 바뀌는 순서

@TBL
작업 | STATUS | WALLET_TYPE
아무 설정 없음 | NOT_AVAILABLE | UNKNOWN
WALLET_ROOT + TDE_CONFIGURATION | NOT_AVAILABLE(위치만 tde/로 바뀜) | UNKNOWN
CREATE KEYSTORE | CLOSED | UNKNOWN
SET KEYSTORE OPEN | OPEN_NO_MASTER_KEY | PASSWORD
SET KEY WITH BACKUP | OPEN | PASSWORD
재기동(비밀번호 키스토어만) | CLOSED | UNKNOWN
CREATE LOCAL AUTO_LOGIN 후 재기동 | OPEN | LOCAL_AUTOLOGIN
@END

@B 실습 01~05에서 실제로 거친 순서다. 상태가 다음 단계로 넘어가지 않으면 바로 앞 단계를 다시 확인한다.
@B WALLET_TYPE이 UNKNOWN이면 열린 키스토어가 없다는 뜻에 가깝다. 닫힌 상태에서는 어떤 종류의 키스토어인지 판단하지 않는다.

@H2 10.4  키스토어 위치 구성

@H3 10.4.1  19c 방식 — WALLET_ROOT와 TDE_CONFIGURATION

@B `WALLET_ROOT`는 키스토어의 최상위 디렉터리를 정하는 정적 초기화 파라미터다. SPFILE에 기록하고 인스턴스를 재기동해야 적용된다.
@B `TDE_CONFIGURATION`은 동적 파라미터다. `KEYSTORE_CONFIGURATION=FILE`로 두면 소프트웨어 키스토어를 쓴다.
@B TDE 키스토어는 `WALLET_ROOT` 아래 `tde` 하위 디렉터리에 만들어진다. 디렉터리가 없으면 CREATE KEYSTORE가 만든다.
@B 같은 WALLET_ROOT 아래에 TLS 지갑(`tls`), 외부 키스토어 비밀번호 저장소(`tde_seps`) 같은 구성 요소별 디렉터리가 함께 놓인다.

@CODE
SYS@orcl> ALTER SYSTEM SET wallet_root = '/u01/app/oracle/admin/orcl/wallet' SCOPE = SPFILE;
SYS@orcl> SHUTDOWN IMMEDIATE
SYS@orcl> STARTUP
SYS@orcl> ALTER SYSTEM SET tde_configuration = 'KEYSTORE_CONFIGURATION=FILE' SCOPE = BOTH;
@END

@H3 10.4.2  키스토어 검색 순서

@TBL
순서 | 위치
1 | WALLET_ROOT (TDE_CONFIGURATION의 KEYSTORE_CONFIGURATION=FILE일 때) 아래 tde
2 | sqlnet.ora의 WALLET_LOCATION
3 | sqlnet.ora의 ENCRYPTION_WALLET_LOCATION (19c에서 디프리케이트)
4 | $ORACLE_BASE/admin/db_unique_name/wallet
@END

@B WALLET_ROOT를 설정하지 않은 데이터베이스도 V$ENCRYPTION_WALLET에 기본 위치(4번)가 나타난다. 실습 DB orcl의 초기 상태가 `/u01/app/oracle/admin/orcl/wallet`, NOT_AVAILABLE이다.
@B sqlnet.ora 방식은 같은 Oracle Home을 쓰는 모든 데이터베이스가 같은 파일을 읽는다. 데이터베이스마다 다른 위치를 쓰려면 파일 안에서 $ORACLE_SID 같은 변수를 써야 했다.
@B WALLET_ROOT는 인스턴스 파라미터라 데이터베이스마다 따로 정해진다. 실습 VM의 sales DB가 이미 WALLET_ROOT로 TDE를 쓰고 있지만 orcl에는 아무 영향이 없다.

@H3 10.4.3  위치를 정하는 기준

@B WALLET_ROOT는 데이터 파일과 다른 파일 시스템에 두는 것이 원칙이다. 데이터 파일 디스크를 통째로 잃거나 유출해도 키스토어는 따로 남아야 한다.
@B 데이터베이스마다 다른 경로를 쓴다. 실습 VM에서 sales, orcl, tdedb는 각각 `$ORACLE_BASE/admin/DB이름/wallet`을 썼다.
@B RAC에서는 모든 인스턴스가 같은 키스토어를 봐야 하므로 공유 파일 시스템이나 ASM 위의 경로를 쓴다.
@B WALLET_ROOT 디렉터리는 oracle 소유자만 읽고 쓸 수 있게 둔다. 실습에서 CREATE KEYSTORE가 만든 tde 디렉터리는 750, 키스토어 파일은 600이었다.

@NOTE 원본 자료와 구버전 방식
과정 원본 자료는 이미 WALLET_ROOT를 쓰지만, CREATE KEYSTORE에 경로('/u01/app/oracle/admin/orcl/wallet/tde')를 직접 적는다. 19c 매뉴얼은 WALLET_ROOT가 설정되면 경로 없이 `ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY 비밀번호`를 쓰도록 안내한다. 실습 02에서 원본 문법을 그대로 실행하자 ORA-46633: creation of a password-based keystore failed가 났다.
12c 이전 자료에서 흔히 보는 sqlnet.ora의 ENCRYPTION_WALLET_LOCATION은 19c에서 디프리케이트됐다. 기존 구성을 옮길 때는 WALLET_ROOT와 TDE_CONFIGURATION으로 바꾼다.
@END

@H3 10.4.4  구버전 명령과 19c 명령

@TBL
작업 | 11g 시절 자료의 명령 | 19c에서 쓰는 명령
위치 지정 | sqlnet.ora ENCRYPTION_WALLET_LOCATION | WALLET_ROOT + TDE_CONFIGURATION
지갑 열기 | ALTER SYSTEM SET ENCRYPTION WALLET OPEN IDENTIFIED BY | ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY
마스터 키 설정·교체 | ALTER SYSTEM SET ENCRYPTION KEY IDENTIFIED BY | ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY ... WITH BACKUP
지갑 닫기 | ALTER SYSTEM SET ENCRYPTION WALLET CLOSE | ADMINISTER KEY MANAGEMENT SET KEYSTORE CLOSE
auto-login 지갑 생성 | orapki wallet create -auto_login | ADMINISTER KEY MANAGEMENT CREATE [LOCAL] AUTO_LOGIN KEYSTORE
@END

@B 19c SQL Language Reference의 ALTER SYSTEM 예제에는 ENCRYPTION WALLET, ENCRYPTION KEY 구문이 아직 실려 있다. 오래된 운영 스크립트가 19c로 올라온 뒤에도 이 구문을 쓰는 이유다.
@B Advanced Security Guide의 절차는 모두 ADMINISTER KEY MANAGEMENT로 쓰여 있고, TDE 지갑을 orapki나 mkstore로 만들지 말라고 적고 있다. 이관할 때 스크립트도 함께 바꾼다.

@H2 10.5  키스토어 생성과 마스터 키 설정

@H3 10.5.1  키스토어 생성과 열기

@CODE
SYS@orcl> ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "Tde#2026orcl";
SYS@orcl> ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "Tde#2026orcl";
SYS@orcl> SELECT wrl_parameter, status, wallet_type FROM v$encryption_wallet;
@END

@B 키스토어 관리는 ADMINISTER KEY MANAGEMENT 시스템 권한이나 SYSKM 관리 권한으로 한다. SYSDBA에도 포함된다.
@B 생성 직후 상태는 CLOSED, 연 직후는 OPEN_NO_MASTER_KEY다. 아직 데이터를 암호화할 수 없다. 이 상태에서 암호화 테이블스페이스를 만들면 ORA-28361: master key not yet set이 난다.
@B 키스토어 디렉터리(WALLET_ROOT/tde)는 CREATE KEYSTORE가 750 권한으로 만들고, ewallet.p12는 600으로 만들어진다.
@B 키스토어 비밀번호는 지갑 파일을 여는 비밀번호다. DB 사용자 비밀번호와 관계가 없으며, 잃어버리면 키스토어를 열 수 없어 암호화된 데이터에 영원히 접근할 수 없다.
@B 실습에서는 키스토어 비밀번호에 영문 대소문자, 숫자, 특수 문자를 섞고 큰따옴표로 감싸 썼다. 특수 문자가 들어간 비밀번호는 따옴표가 없으면 SQL 구문으로 해석될 수 있다.
@B 키스토어 비밀번호는 IDENTIFIED BY 절로 SQL 문장에 들어가므로 감사 기록이나 셸 히스토리에 남지 않게 주의한다. SQL*Plus 스크립트 파일에 적어 두는 습관은 피한다.
@B 운영에서는 키스토어 비밀번호를 외부 키스토어 비밀번호 저장소(WALLET_ROOT/tde_seps)에 넣어 IDENTIFIED BY EXTERNAL STORE로 쓰는 방법도 있다.

@B 키스토어 관리 권한을 DBA와 분리하려면 SYSKM 관리 권한을 쓴다. `CONNECT 사용자 AS SYSKM`으로 접속한 키 관리자는 ADMINISTER KEY MANAGEMENT를 실행할 수 있지만 데이터 조회 권한은 없다.
@B 키 관리자와 DBA를 나누면 한 사람이 데이터와 키를 모두 손에 넣는 일을 줄일 수 있다. 규모가 작은 조직에서는 최소한 키스토어 비밀번호를 DBA 개인이 아닌 별도 보관 절차로 관리한다.

@CODE
SYS@orcl> CREATE USER key_admin IDENTIFIED BY "KeyAdm#2026";
SYS@orcl> GRANT SYSKM TO key_admin;
[oracle@oel7v9 ~]$ sqlplus key_admin/"KeyAdm#2026" AS SYSKM
SQL> ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "Tde#2026orcl";
@END

@B SYSKM으로 접속한 세션은 키스토어 작업만 할 수 있고 업무 테이블을 조회할 권한은 없다. SYSKM 권한을 받으려면 패스워드 파일이 구성돼 있어야 한다.

@H3 10.5.2  마스터 키 설정

@CODE
SYS@orcl> ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "Tde#2026orcl" WITH BACKUP;
@END

@B 마스터 키를 처음 만들 때와 교체할 때 같은 명령을 쓴다.
@B 비밀번호 키스토어에서는 WITH BACKUP이 필수다. 빼면 ORA-46631: keystore needs to be backed up이 난다. 키스토어를 바꾸기 직전 상태를 `ewallet_타임스탬프_식별자.p12`로 남긴다. 식별자는 `WITH BACKUP USING '식별자'`로 준다.
@B 이 사본은 변경 직전 상태라 새 마스터 키가 들어 있지 않다. 그래서 SET KEY 직후 FULLY_BACKED_UP은 NO다. BACKUP KEYSTORE로 따로 백업하자 YES가 됐다(실습 05).
@B 설정 후 STATUS가 OPEN이 되고, V$ENCRYPTION_KEYS에 KEY_ID가 한 행 생긴다.
@B 같은 순간 V$DATABASE_KEY_INFO의 MASTERKEY_ACTIVATED가 NO에서 YES로 바뀐다. MASTERKEYID는 KEY_ID를 Base64로 풀었을 때 앞의 버전 바이트 다음에 오는 값과 같다. 이 기록이 10.8.6절의 문제를 만든다.
@B `USING TAG '설명'`으로 키에 태그를 달아 두면 여러 번 교체한 뒤에도 어떤 키가 언제 왜 만들어졌는지 구분하기 쉽다.

@H3 10.5.3  auto-login 키스토어

@CODE
SYS@orcl> ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE
  2  FROM KEYSTORE IDENTIFIED BY "Tde#2026orcl";
@END

@B 비밀번호 키스토어만 있으면 인스턴스를 재기동할 때마다 DBA가 키스토어를 열어야 한다. 그 전까지 암호화된 테이블스페이스는 읽을 수 없다.
@B auto-login 키스토어(cwallet.sso)를 만들면 인스턴스가 시작될 때 자동으로 열린다.
@B `CREATE LOCAL AUTO_LOGIN KEYSTORE`는 만든 호스트에서만 열리는 cwallet.sso를 만든다. 키스토어 디렉터리를 다른 서버로 복사해도 열리지 않는다. RAC에서는 LOCAL을 빼야 한다.
@B auto-login을 만든 뒤에도 ewallet.p12를 지우면 안 된다. 마스터 키 교체, 백업 같은 관리 작업은 비밀번호 키스토어가 있어야 한다.

@H3 10.5.4  키스토어 디렉터리의 변화

@TBL
시점 | WALLET_ROOT/tde 안의 파일
CREATE KEYSTORE | ewallet.p12
SET KEY ... WITH BACKUP USING 'first' | ewallet.p12, ewallet_타임스탬프_first.p12
CREATE LOCAL AUTO_LOGIN KEYSTORE | 위 + cwallet.sso
SET KEY ... WITH BACKUP USING 'rotate1' | 위 + ewallet_타임스탬프_rotate1.p12
BACKUP KEYSTORE USING 'manual' | 위 + ewallet_타임스탬프_manual.p12
@END

@B 마스터 키를 바꿀 때마다 ewallet.p12가 커지고 백업 파일이 하나씩 늘어난다. 옛 키도 키스토어에 남기 때문이다.
@B 백업 파일은 같은 디렉터리에 쌓인다. 같은 디스크에 있는 백업은 디스크 장애를 막지 못하므로 정기적으로 다른 장소로 옮긴다.
@B cwallet.sso는 ewallet.p12를 바꿀 때 함께 갱신된다. 마스터 키 교체 후 cwallet.sso 크기도 커진 것을 실습 05에서 볼 수 있다.

@CASE 재기동 후 업무 테이블만 ORA-28365로 실패한다
정기 점검으로 데이터베이스를 재기동한 뒤 일부 업무 화면이 "ORA-28365: wallet is not open"으로 실패했다. 암호화하지 않은 테이블을 쓰는 화면은 정상이었다.
TDE를 도입하면서 비밀번호 키스토어만 만들고 auto-login 키스토어는 만들지 않았다. 재기동 전에는 DBA가 처음 열어 둔 상태가 유지됐지만 재기동 후에는 닫힌 상태로 시작했다.
DBA가 `SET KEYSTORE OPEN`으로 키스토어를 열자 화면이 정상으로 돌아왔다. 이후 운영 정책에 따라 local auto-login 키스토어를 만들고, 재기동 점검 목록에 V$ENCRYPTION_WALLET 확인을 넣었다.
@END

@H2 10.6  컬럼 암호화

@H3 10.6.1  컬럼 암호화 문법과 동작

@CODE
SYS@orcl> CREATE TABLE tde_lab.cust (
  2    cust_id  NUMBER,
  3    name     VARCHAR2(30),
  4    card_no  VARCHAR2(20) ENCRYPT);

SYS@orcl> ALTER TABLE tde_lab.cust MODIFY (name ENCRYPT USING 'AES256');
@END

@B ENCRYPT 키워드를 붙인 컬럼만 암호화된다. 기본 알고리즘은 AES192이고, 기본으로 salt가 붙으며 무결성 검사에 SHA-1을 쓴다.
@B 기존 컬럼은 `ALTER TABLE ... MODIFY (컬럼 ENCRYPT)`로 암호화한다. 테이블의 모든 행을 다시 쓰므로 큰 테이블에서는 시간이 걸리고 잠금이 생긴다.
@B 한 테이블의 암호화 컬럼은 같은 테이블 키와 같은 알고리즘을 쓴다. 다른 컬럼에 다른 알고리즘을 지정하면 ORA-28340이 난다. 알고리즘을 바꾸려면 `ALTER TABLE ... REKEY USING '알고리즘'`으로 테이블 키를 바꾼다.
@B salt는 컬럼마다 따로 정해진다. 같은 테이블에서 한 컬럼은 SALT, 다른 컬럼은 NO SALT일 수 있다.
@B 암호화된 컬럼 값은 버퍼 캐시 안에서도 암호화된 상태다. 읽을 때마다 복호화 비용이 든다.

@H3 10.6.2  salt와 인덱스

@B salt는 같은 평문도 행마다 다른 암호문이 되게 하는 임의 값이다. 암호문 패턴으로 값을 추측하는 공격을 어렵게 한다. 값마다 16바이트가 더 든다.
@B salt를 쓴 컬럼에는 B-tree 인덱스를 만들 수 없다. 같은 값이 다른 암호문이 되므로 정렬·동등 비교가 불가능하다. 시도하면 ORA-28338이 난다.
@B 인덱스가 필요한 컬럼은 `ENCRYPT NO SALT`로 암호화한다. 이 경우에도 인덱스는 동등 조건 검색에만 쓰이고 범위 검색에는 쓰이지 않는다.
@B 외래 키 제약에 쓰이는 컬럼, B-tree가 아닌 인덱스, identity 컬럼에는 컬럼 암호화를 쓸 수 없다.

@H3 10.6.3  실습에서 본 컬럼 암호화

@TBL
작업 | 결과
card_no VARCHAR2(20) ENCRYPT | AES 192 bits key, SALT YES, SHA-1
salt 컬럼에 CREATE INDEX | ORA-28338
MODIFY (card_no ENCRYPT NO SALT) 후 인덱스 | 성공
MODIFY (name ENCRYPT USING 'AES256') | ORA-28340(테이블은 AES192)
REKEY USING 'AES256' 후 name ENCRYPT | 두 컬럼 모두 AES 256, name은 SALT YES
@END

@B 알고리즘은 테이블 단위, salt는 컬럼 단위라는 차이가 결과에 그대로 드러난다.
@B REKEY는 테이블의 모든 암호화 값을 새 키로 다시 암호화한다. 큰 테이블에서는 시간과 언두·리두가 든다.

@H3 10.6.4  컬럼 암호화의 한계

@B 암호화 컬럼은 범위 조건(`BETWEEN`, `>`)에서 인덱스를 쓰지 못한다. 그런 컬럼이 많은 애플리케이션은 성능 영향이 크다.
@B 어느 컬럼에 민감 정보가 있는지 미리 알아야 한다. 새 컬럼이 추가되면 암호화도 따로 해 줘야 한다.
@B 정렬, 조인, 함수 처리가 많은 컬럼일수록 복호화 비용이 쌓인다. 이런 이유로 19c에서는 테이블스페이스 암호화가 일반적인 선택이다.
@B 컬럼 암호화를 쓰던 테이블을 테이블스페이스 암호화로 옮길 때는 암호화 테이블스페이스로 테이블을 이동한 뒤 컬럼 암호화를 해제(DECRYPT)한다. 두 방식을 겹쳐 두면 같은 값을 두 번 암·복호화한다.

@H2 10.7  테이블스페이스 암호화

@H3 10.7.1  암호화된 테이블스페이스 만들기

@CODE
SYS@orcl> CREATE TABLESPACE tde_ts
  2    DATAFILE '/u01/app/oracle/oradata/orcl/tde_ts01.dbf' SIZE 20M
  3    ENCRYPTION USING 'AES256' ENCRYPT;
@END

@B 테이블스페이스의 모든 블록이 디스크에 기록될 때 암호화된다. 그 안에 만드는 테이블·인덱스·LOB는 별도 지정 없이 모두 보호된다.
@B 블록은 디스크에서 읽어 버퍼 캐시에 올릴 때 복호화된다. 캐시 안에서는 평문이라 반복 조회 비용이 낮고 인덱스 범위 검색에도 제약이 없다.
@B 알고리즘을 생략하면 AES128이 쓰인다. 테이블스페이스 암호화에는 NO SALT 옵션이 없다.
@B 원본 자료의 `ENCRYPTION USING 'AES128' DEFAULT STORAGE(ENCRYPT)` 문법도 19c에서 동작한다. 매뉴얼의 현재 예제는 `ENCRYPTION USING '알고리즘' ENCRYPT` 형식이다.
@B 암호화된 테이블스페이스의 리두와 언두, 임시 세그먼트에 기록되는 해당 데이터도 암호화된다.

@B 실습 03에서 같은 카드 번호를 암호화 테이블스페이스와 일반 테이블스페이스에 한 행씩 넣고 체크포인트 후 데이터 파일을 strings로 읽었다. 일반 파일에서는 1건, 암호화 파일에서는 0건이 나왔다.
@B 같은 두 테이블을 SQL로 조회하면 모두 평문이 나온다. 파일과 SQL이라는 두 경로의 차이가 TDE가 지키는 범위다.
@B 체크포인트 전에는 변경이 아직 버퍼 캐시와 리두에만 있을 수 있다. 파일을 직접 읽어 확인할 때는 체크포인트 후에 본다.

@H3 10.7.2  기존 테이블스페이스의 온라인 변환

@CODE
SYS@tdedb> ALTER TABLESPACE tde_plain ENCRYPTION ONLINE USING 'AES256' ENCRYPT;

Tablespace altered.
@END

@B 12.2부터 기존 테이블스페이스를 열린 상태로 암호화할 수 있다. COMPATIBLE이 12.2.0 이상이어야 한다.
@B 온라인 변환은 데이터 파일을 새 파일로 복사하면서 암호화하고, 끝나면 새 파일로 바꾼다. 변환하는 동안 원래 파일 크기만큼 공간이 더 필요하다.
@B 예전 자료는 OMF가 아니면 FILE_NAME_CONVERT로 새 파일 이름을 줘야 한다고 설명한다. 19.3에서는 OMF가 아닌 DB에서도 FILE_NAME_CONVERT 없이 변환이 성공했고 파일 이름도 그대로 유지됐다(실습 03). 이름을 바꾸고 싶을 때만 FILE_NAME_CONVERT를 준다.
@B 이미 암호화된 테이블스페이스에 ENCRYPT를 다시 주면 ORA-28370이 난다. 알고리즘이나 키를 바꾸려면 REKEY를 쓴다.
@B 변환이 중간에 실패하면 같은 명령에 FINISH를 붙여 다시 실행해 마무리한다.
@B 오프라인 변환(`ALTER TABLESPACE ... ENCRYPTION OFFLINE ENCRYPT`)도 있다. 테이블스페이스를 오프라인으로 두는 대신 추가 공간이 필요 없다.
@B 복호화는 같은 형식에 DECRYPT를 쓴다. 암호화를 되돌릴 때도 키스토어가 열려 있어야 한다.

@H3 10.7.3  키 교체(rekey)

@TBL
작업 | 명령 | 데이터 재암호화
마스터 키 교체 | ADMINISTER KEY MANAGEMENT SET KEY ... WITH BACKUP | 없음(2계층 키만 다시 암호화)
테이블 키 교체 | ALTER TABLE ... REKEY [USING '알고리즘'] | 암호화 컬럼 전체
테이블스페이스 키 교체 | ALTER TABLESPACE ... ENCRYPTION ONLINE USING '알고리즘' REKEY | 테이블스페이스 전체
@END

@B 보안 정책이 정기적인 키 교체를 요구하면 보통 마스터 키 교체로 충족한다. 빠르고 서비스 영향이 거의 없다.
@B 마스터 키를 교체해도 옛 마스터 키는 키스토어에서 지워지지 않는다. 옛 키로 만든 백업을 복구할 때 필요하기 때문이다.
@B 2계층 키 교체는 키가 노출됐다고 의심될 때나 알고리즘을 바꿀 때 쓴다.

@H3 10.7.4  기존 데이터를 암호화하는 방법

@TBL
방법 | 서비스 영향 | 추가 공간 | 비고
온라인 변환(ENCRYPTION ONLINE) | 거의 없음 | 테이블스페이스 크기만큼 | 12.2 이상, 19.3은 FILE_NAME_CONVERT 생략 가능
오프라인 변환(ENCRYPTION OFFLINE) | 테이블스페이스 오프라인 | 없음 | 블록 단위로 제자리 변환
새 암호화 테이블스페이스로 이동 | 객체별 이동 중 잠금 | 객체 크기만큼 | ALTER TABLE MOVE ONLINE, 인덱스 재구성
Data Pump로 재적재 | 업무 중단 필요 | 덤프 파일 | 대규모 재구성과 함께 할 때
@END

@B 운영 중인 시스템에서는 온라인 변환이 가장 부담이 적다. 공간이 모자라면 오프라인 변환을 계획 정지 시간에 한다.
@B SYSTEM, SYSAUX, UNDO 테이블스페이스도 19c에서 온라인 변환으로 암호화할 수 있다. 전체 데이터베이스 암호화를 요구받으면 이 테이블스페이스들까지 포함한다.
@B 초기화 파라미터 `ENCRYPT_NEW_TABLESPACES`를 ALWAYS로 두면 이후 만드는 모든 테이블스페이스가 별도 지정 없이 AES128로 암호화된다. 기본값 CLOUD_ONLY는 클라우드 환경에서만 이렇게 동작한다.

@H3 10.7.5  테이블스페이스 키 교체

@CODE
SYS@orcl> ALTER TABLESPACE tde_ts ENCRYPTION ONLINE USING 'AES256' REKEY;
@END

@B 2계층 키인 테이블스페이스 키를 새로 만들고 블록을 다시 암호화한다. 온라인 변환과 같은 방식이라 추가 공간과 시간이 든다.
@B 이미 암호화된 테이블스페이스에 ENCRYPT를 주면 ORA-28370이 나는 것과 달리, REKEY는 암호화된 테이블스페이스에만 쓸 수 있다.
@B 알고리즘을 AES128에서 AES256으로 올릴 때도 REKEY에 USING '알고리즘'을 준다.

@BP 컬럼 암호화와 테이블스페이스 암호화 고르기
새로 설계하는 시스템은 테이블스페이스 암호화를 기본으로 한다. 애플리케이션 영향과 성능 제약이 가장 적다.
민감 데이터가 한두 컬럼에 한정되고 테이블을 다른 테이블스페이스로 옮기기 어려울 때 컬럼 암호화를 쓴다.
컬럼 암호화를 쓸 때는 인덱스·범위 검색·외래 키 사용 여부를 먼저 조사한다.
암호화 대상을 정할 때는 데이터 파일뿐 아니라 백업, 덤프 파일, 아카이브 로그가 어디로 나가는지도 함께 본다.
@END

@H2 10.8  운영 작업과 키스토어 관리

@H3 10.8.1  키스토어 열기와 닫기

@B `ADMINISTER KEY MANAGEMENT SET KEYSTORE CLOSE IDENTIFIED BY 비밀번호`로 비밀번호 키스토어를 닫는다.
@B auto-login 키스토어가 있으면 비밀번호 키스토어를 닫은 뒤에도 cwallet.sso로 다시 열린 상태가 된다. 원본 자료의 마지막 조회에서 WALLET_TYPE이 AUTOLOGIN, STATUS가 OPEN으로 보이는 이유다.
@B auto-login 키스토어로 열린 상태에서 `SET KEYSTORE CLOSE IDENTIFIED BY 비밀번호`를 실행하자 ORA-28417: password-based keystore is not open이 났고 키스토어는 계속 열려 있었다(실습 05). auto-login으로 연 키스토어를 닫으려면 IDENTIFIED BY 없이 CLOSE한다.
@B 같은 상태에서 마스터 키 교체나 백업처럼 비밀번호 키스토어를 고치는 작업에는 FORCE KEYSTORE 절을 붙인다. 문서는 이 절이 작업 동안 비밀번호 키스토어를 임시로 열고, auto-login이 열려 있으면 비밀번호 키스토어로 전환한다고 설명한다. 실습 05의 SET KEY와 BACKUP KEYSTORE가 이렇게 실행됐다.
@B 키스토어를 닫으면 암호화된 테이블스페이스·컬럼에 접근하는 모든 문장이 ORA-28365로 실패한다. 이미 캐시에 있는 블록도 예외가 아니다.
@B 컬럼 암호화 테이블은 암호화되지 않은 컬럼만 고르면 조회된다. 재기동 후 키스토어가 닫힌 상태에서 `SELECT *`는 실패하고 `SELECT cust_id`는 성공했다. 업무 화면 중 일부만 실패하는 증상이 이렇게 생긴다.

@H3 10.8.2  키스토어 백업

@B `ADMINISTER KEY MANAGEMENT BACKUP KEYSTORE USING '식별자' IDENTIFIED BY 비밀번호 TO '디렉터리'`로 키스토어를 백업한다.
@B 마스터 키를 설정·교체할 때의 WITH BACKUP도 백업 파일을 만든다. V$ENCRYPTION_WALLET의 FULLY_BACKED_UP 열이 YES인지 확인한다.
@B RMAN 백업에는 키스토어 파일이 포함되지 않는다. 데이터 파일 백업과 키스토어 백업을 다른 매체·다른 장소에 보관한다.
@B 데이터 파일 백업과 키스토어를 같은 테이프에 담으면 테이프 하나를 잃었을 때 TDE가 아무것도 막지 못한다.

@CASE 복구 서버에서 데이터 파일은 복원됐는데 열리지 않는다
디스크 장애 후 다른 서버에 RMAN으로 데이터베이스를 복원했다. 복원과 복구는 끝났지만 업무 테이블을 조회하자 ORA-28365가 났고, 키스토어를 열려고 하니 해당 위치에 파일이 없었다.
TDE 키스토어는 원래 서버의 `WALLET_ROOT/tde`에만 있었고 RMAN 백업에는 포함되지 않았다. 다행히 마스터 키를 설정할 때 WITH BACKUP으로 만든 백업 파일이 별도 보관 서버에 복사되어 있었다.
백업 키스토어를 복구 서버의 WALLET_ROOT 아래 tde 디렉터리에 두고 열자 데이터에 접근할 수 있었다. 이후 키스토어 백업 위치와 비밀번호 보관 절차를 재해 복구 문서에 넣었다.
@END

@H3 10.8.3  TDE와 다른 기능

@B Data Pump Export는 기본적으로 암호화된 컬럼을 평문으로 덤프에 쓴다. 덤프 파일을 보호하려면 `ENCRYPTION` 파라미터로 덤프 파일 자체를 암호화한다.
@B RMAN 백업 셋에 들어가는 암호화된 테이블스페이스 블록은 암호화된 상태 그대로다. 다른 테이블스페이스까지 보호하려면 RMAN 백업 암호화를 따로 설정한다.
@B Data Guard Standby도 같은 마스터 키가 있는 키스토어가 필요하다. Primary에서 마스터 키를 교체하면 Standby 키스토어도 갱신해야 한다.
@B 압축(테이블 압축)과 TDE를 함께 쓰면 압축된 뒤 암호화된다. 압축 효율은 그대로 얻는다.
@B 아카이브 로그와 리두에 담긴 암호화 테이블스페이스의 변경은 암호화된 채 기록된다. 아카이브 로그를 다른 서버로 옮겨 마이닝하거나 적용하려면 그쪽에도 같은 키가 있어야 한다.

@CODE
[oracle@oel7v9 ~]$ expdp system tables=tde_lab.cust directory=dp_dir dumpfile=cust.dmp                    encryption=all encryption_mode=password encryption_password=Dump#2026
@END

@B 덤프 파일을 암호화하는 Data Pump 파라미터 예다. ENCRYPTION=ALL은 데이터와 메타데이터를 모두 암호화한다.
@B ENCRYPTION_MODE=PASSWORD는 지정한 비밀번호로, TRANSPARENT는 키스토어의 키로, DUAL은 둘 다로 암호화한다. TRANSPARENT 덤프는 같은 키스토어가 있는 DB에서만 가져올 수 있다.
@B 명령행에 덤프 비밀번호를 쓰면 히스토리에 남는다. 파라미터 파일로 넘기고 파일 권한을 막는다.

@H3 10.8.4  성능

@B 테이블스페이스 암호화의 비용은 디스크 I/O 때 블록을 암·복호화하는 데 든다. 캐시 적중이 높은 작업에서는 영향이 작다.
@B 최근 CPU는 AES 연산을 하드웨어 명령으로 처리한다. Oracle은 이를 자동으로 사용하므로 AES 계열 알고리즘이 성능상 유리하다.
@B 컬럼 암호화는 조회할 때마다 복호화하므로 대량 조회·정렬 작업에서 비용이 두드러진다. 컬럼 암호화를 쓰는 테이블은 도입 전후 주요 SQL의 응답 시간을 비교한다.
@B 온라인 변환 중에는 블록 복사와 리두가 늘어난다. 아카이브 로그 공간과 Data Guard 전송량도 함께 늘어나므로 업무가 한가한 시간에 한다.

@H3 10.8.5  키를 다른 데이터베이스로 옮길 때

@B 전송 가능 테이블스페이스나 PDB 이동처럼 암호화된 데이터가 다른 DB로 옮겨 갈 때는 마스터 키도 함께 옮겨야 한다.
@B `ADMINISTER KEY MANAGEMENT EXPORT ENCRYPTION KEYS ... TO '파일' IDENTIFIED BY 비밀번호`로 키를 파일로 내보내고, 대상 DB에서 `IMPORT ENCRYPTION KEYS`로 가져온다.
@B 내보낸 키 파일은 데이터 그 자체만큼 민감하다. 전달이 끝나면 지운다.
@B 키스토어 두 개를 하나로 합칠 때는 `MERGE KEYSTORE`를 쓴다. 키스토어 파일을 직접 덮어쓰면 기존 키를 잃는다.

@H3 10.8.6  키스토어를 지우면 생기는 일

@P 이 교안을 만들면서 다른 실습과 함께 쓰는 orcl에서 TDE 실습을 해 본 뒤, 원복한다며 암호화 객체를 지우고 키스토어 디렉터리까지 삭제했다. 그 결과 다음 일이 차례로 생겼다.

@TBL
시점 | 현상
원복 직후 | V$ENCRYPTION_WALLET은 NOT_AVAILABLE이지만 V$DATABASE_KEY_INFO는 MASTERKEY_ACTIVATED = YES로 남음
TDE 재구성 | 새 키스토어에서 SET KEY가 ORA-28374: typed master key not found in wallet으로 실패
다음 재기동 | SHUTDOWN IMMEDIATE가 ORA-28365: wallet is not open으로 중단되고 인스턴스가 반쯤 내려간 상태로 멈춤
복구 | SHUTDOWN ABORT 후 보관해 둔 키스토어를 WALLET_ROOT/tde에 되돌리고 STARTUP
@END

@B 암호화 객체를 모두 지워도 데이터베이스는 마스터 키가 활성화됐다는 기록을 컨트롤 파일 쪽에 남긴다. 이 기록을 되돌리는 정상적인 방법은 없다.
@B 그 기록에 맞는 키가 키스토어에 없으면 새 마스터 키 설정과 종료 같은 작업이 막힐 수 있다. TDE를 한 번이라도 쓴 데이터베이스의 키스토어는 객체를 지운 뒤에도 보관한다.
@B 잃어버린 마스터 키를 정리하는 숨은 파라미터(`_db_discard_lost_masterkey`)가 있지만 Oracle Support의 안내를 받아 쓰는 것이다. 키스토어 백업이 있으면 그것을 되돌리는 것이 우선이다.
@B 이 일 때문에 실습 01~06은 DBCA로 만든 실습 전용 DB tdedb에서 진행했고, 원복은 키스토어 삭제가 아니라 DB 삭제로 했다. orcl은 키스토어를 되돌린 TDE 구성 상태로 둔다.

@BP 키스토어 백업 원칙
마스터 키를 만들거나 바꾼 직후 BACKUP KEYSTORE로 따로 백업하고 FULLY_BACKED_UP이 YES인지 확인한다.
키스토어 백업은 데이터 백업과 다른 매체, 다른 장소에 둔다.
키스토어 비밀번호는 키스토어 백업과 또 다른 곳에 보관한다.
암호화 객체를 모두 지운 뒤에도 키스토어와 백업은 보관한다(10.8.6).
복구 연습 때 키스토어 복원까지 포함해 실제로 데이터를 열어 본다.
@END

@CASE 교체한 마스터 키가 백업에 없었다
보안 점검 결과에 따라 마스터 키를 교체했다. SET KEY ... WITH BACKUP으로 백업이 남았으니 안심하고 따로 백업하지 않았다.
얼마 뒤 디스크 장애로 키스토어 디렉터리를 잃고 백업에서 복원했는데, 복원한 키스토어로는 일부 데이터 파일을 열 수 없었다. WITH BACKUP이 남긴 파일은 교체 직전 상태라 새 마스터 키가 들어 있지 않았다.
다행히 다른 서버에 매일 복사해 두던 키스토어 사본에 새 키가 있어 복구할 수 있었다. 이후 키 교체 절차에 BACKUP KEYSTORE와 FULLY_BACKED_UP 확인을 넣었다.
@END

@H3 10.8.7  Data Guard와 키스토어

@P Data Guard 구성은 실습하지 않았다. 아래는 Advanced Security Guide의 "Using Transparent Data Encryption with Other Oracle Features" 장 기준이다.

@B Primary가 TDE를 쓰면 모든 Standby가 Primary 키스토어의 사본을 가져야 한다. Primary에서 마스터 키를 바꾸면 새 키가 든 키스토어를 Standby마다 다시 복사한다.
@B 파일 키스토어에서 SET KEY로 바로 교체하면 Standby의 관리 복구 프로세스(MRP)가 새 키를 찾지 못해 멈춘다. 문서는 교체를 CREATE KEY와 USE KEY 두 단계로 나누고, 단계마다 키스토어를 Standby에 복사해 강제로 열라고 권한다.
@B Primary의 local auto-login 키스토어는 Standby에서 열리지 않으므로 복사 대상에서 뺀다. Standby에서 비밀번호 키스토어로부터 자기 cwallet.sso를 따로 만든다.

@CODE
-- Primary: 키를 먼저 만들어 둔다(아직 사용하지 않음)
ADMINISTER KEY MANAGEMENT CREATE KEY USING TAG 'rotate2' FORCE KEYSTORE IDENTIFIED BY "비밀번호" WITH BACKUP;
-- 키스토어를 Standby에 복사한 뒤, V$ENCRYPTION_KEYS의 KEY_ID로 활성화
ADMINISTER KEY MANAGEMENT USE KEY '키_ID' FORCE KEYSTORE IDENTIFIED BY "비밀번호" WITH BACKUP;
@END

@H3 10.8.8  자주 만나는 오류

@TBL
오류 | 상황 | 조치
ORA-32017, ORA-46693 | WALLET_ROOT 없이 TDE_CONFIGURATION 설정 | WALLET_ROOT 먼저(SPFILE + 재기동)
ORA-02095 | WALLET_ROOT를 SCOPE=MEMORY로 변경 | SCOPE=SPFILE 후 재기동
ORA-46633 | WALLET_ROOT가 있는데 CREATE KEYSTORE에 경로 지정 | 경로 없이 실행
ORA-28361 | 마스터 키 없이 암호화 테이블스페이스 생성 | SET KEY ... WITH BACKUP
ORA-46631 | 비밀번호 키스토어 변경에 WITH BACKUP 누락 | WITH BACKUP 추가
ORA-28365 | 키스토어가 닫힌 상태에서 암호화 데이터 접근 | SET KEYSTORE OPEN, auto-login 검토
ORA-28338 | salt 컬럼에 인덱스 생성 | ENCRYPT NO SALT
ORA-28340 | 테이블과 다른 알고리즘으로 컬럼 암호화 | ALTER TABLE ... REKEY
ORA-28370 | 이미 암호화된 테이블스페이스에 ENCRYPT | REKEY 사용
ORA-28417 | auto-login으로 열린 상태에서 비밀번호로 CLOSE | IDENTIFIED BY 없이 CLOSE
ORA-28374 | 활성화 기록이 남은 키가 키스토어에 없음 | 보관한 키스토어 복원(10.8.6)
@END

@H2 10.9  TDE 관련 뷰

@TBL
뷰 | 내용
V$ENCRYPTION_WALLET | 키스토어 위치(WRL_PARAMETER), STATUS, WALLET_TYPE, KEYSTORE_MODE, FULLY_BACKED_UP
V$ENCRYPTION_KEYS | 마스터 키 KEY_ID, 생성 시각, 태그, 생성한 DB 등 키 이력
V$DATABASE_KEY_INFO | 현재 마스터 키 ID(MASTERKEYID)와 활성화 여부(MASTERKEY_ACTIVATED)
V$ENCRYPTED_TABLESPACES | 암호화된 테이블스페이스 번호(TS#), 알고리즘, ENCRYPTEDTS, 상태
DBA_TABLESPACES | ENCRYPTED 열로 테이블스페이스 암호화 여부
DBA_ENCRYPTED_COLUMNS | 암호화된 컬럼, 알고리즘, SALT 여부, 무결성 알고리즘
V$PARAMETER | wallet_root, tde_configuration 값
@END

@CODE
SYS@orcl> SELECT t.name, e.encryptedts, e.encryptionalg
  2    FROM v$encrypted_tablespaces e JOIN v$tablespace t ON e.ts# = t.ts#;

SYS@orcl> SELECT owner, table_name, column_name, encryption_alg, salt
  2    FROM dba_encrypted_columns;
@END

@CODE
WRL_PARAMETER                            STATUS               WALLET_TYPE      FULLY_BAC
---------------------------------------- -------------------- ---------------- ---------
/u01/app/oracle/admin/tdedb/wallet/tde/  OPEN                 LOCAL_AUTOLOGIN  YES

MASTERKEYID                        MAS
---------------------------------- ---
9F10688EF4694F62BFB89A47674CB212   YES
@END

@B 실습 05·06의 출력이다. 위는 local auto-login으로 열리고 따로 백업까지 된 상태, 아래는 암호화 객체를 모두 지운 뒤에도 남아 있는 마스터 키 활성화 기록이다.

@B V$ENCRYPTION_KEYS의 행 수는 마스터 키를 교체한 횟수만큼 늘어난다. 가장 최근 키가 현재 키다.
@B DBA_TABLESPACES의 ENCRYPTED가 YES인데 V$ENCRYPTED_TABLESPACES에 없으면 아직 한 번도 열리지 않은 상태 등 예외 상황이다. 두 뷰를 함께 본다.
@B V$ENCRYPTED_TABLESPACES의 STATUS는 보통 NORMAL이다. 온라인 변환이 중간에 멈추면 다른 값으로 남으므로, 변환 작업 뒤에는 이 열을 확인하고 필요하면 FINISH로 마무리한다.
@B DBA_ENCRYPTED_COLUMNS는 컬럼 암호화만 보여 준다. 암호화 테이블스페이스 안의 테이블은 이 뷰에 나오지 않으므로, 어떤 데이터가 보호되는지 보려면 두 뷰를 함께 본다.
@B 뷰 조회 권한도 관리 대상이다. 키 ID나 키스토어 경로는 그 자체로 공격자에게 쓸모 있는 정보다.

@NOTE 점검 조회 하나로 보는 TDE 상태
V$ENCRYPTION_WALLET에서 STATUS, WALLET_TYPE, FULLY_BACKED_UP을, V$DATABASE_KEY_INFO에서 MASTERKEY_ACTIVATED를 함께 본다.
MASTERKEY_ACTIVATED가 YES인데 STATUS가 NOT_AVAILABLE이면 마스터 키를 쓴 적이 있는데 키스토어가 보이지 않는 위험한 상태다. 10.8.6절의 orcl이 이 상태에서 종료에 실패했다. 이 조합이 보이면 재기동이나 키 작업을 하기 전에 키스토어부터 찾는다.
STATUS가 OPEN이고 FULLY_BACKED_UP이 NO면 최근 키 교체 뒤 백업을 하지 않은 것이다.
@END

@H2 10.10  설계와 적용 절차

@TBL
단계 | 작업 | 확인할 것
1 | 라이선스와 암호화 대상 결정 | 테이블스페이스 단위로 묶을 수 있는지
2 | WALLET_ROOT 설정과 재기동 | 재기동 시간 확보, V$PARAMETER
3 | TDE_CONFIGURATION 설정 | KEYSTORE_CONFIGURATION=FILE
4 | 키스토어 생성·열기 | V$ENCRYPTION_WALLET STATUS = OPEN_NO_MASTER_KEY
5 | 마스터 키 설정 WITH BACKUP | STATUS = OPEN, V$ENCRYPTION_KEYS
6 | auto-login 키스토어 생성 | 운영 정책에 따라 LOCAL 여부 결정
7 | 테이블스페이스 생성·변환 또는 컬럼 암호화 | V$ENCRYPTED_TABLESPACES, DBA_ENCRYPTED_COLUMNS
8 | 재기동 시험 | 재기동 후 STATUS, 업무 조회
9 | 키스토어 백업과 비밀번호 보관 | 데이터 백업과 다른 장소
@END

@B 2단계의 재기동 때문에 TDE 도입은 계획 정지 시간에 맞춘다. 3단계부터는 온라인으로 할 수 있다.
@B 6단계에서 LOCAL을 붙일지 정한다. 단일 서버라면 LOCAL이 안전하고, RAC나 키스토어를 공유 저장소에 두는 구성이면 LOCAL을 빼야 모든 인스턴스가 연다.
@B 8단계를 생략하면 첫 장애 재기동 때 문제를 발견한다. 도입 직후 한 번은 반드시 재기동해 본다.
@B 5단계와 9단계 사이에 FULLY_BACKED_UP이 YES가 되는지 확인한다. WITH BACKUP만으로는 NO로 남는다.
@B 시험 환경에서 절차를 먼저 끝까지 돌려 보되, 그 시험 DB는 다른 용도와 함께 쓰지 않는다. 마스터 키 기록이 남기 때문이다.

@CASE 테스트 서버로 복제한 DB가 열리지 않는다
운영 DB를 RMAN DUPLICATE로 테스트 서버에 복제했다. 복제 자체는 끝났지만 업무 테이블을 조회하면 ORA-28365가 나고, 테스트 서버에는 키스토어 파일이 없었다.
TDE를 쓰는 DB를 복제하려면 원본의 키스토어를 대상 서버의 WALLET_ROOT/tde에 미리 두고 WALLET_ROOT·TDE_CONFIGURATION도 맞춰야 한다. 운영 키스토어를 테스트 서버에 그대로 두면 운영 키가 테스트 환경에 퍼진다.
키스토어를 옮겨 복제를 마친 뒤 테스트 DB에서 마스터 키를 새로 교체하고, 운영 키가 든 옛 키스토어 백업은 테스트 서버에서 지웠다. 이후 복제 절차에 키 교체 단계를 넣었다.
@END

@H2 10.11  운영 시 주의점

@B 키스토어 비밀번호와 키스토어 백업은 데이터 자체만큼 중요하다. 둘 중 하나를 잃으면 암호화된 데이터를 복구할 수 없다.
@B 키스토어 파일의 OS 권한은 oracle 소유자만 읽을 수 있게 둔다. auto-login 키스토어는 파일을 가진 사람이 곧 키를 가진 사람이다.
@B 마스터 키 교체 후에는 반드시 키스토어를 백업한다. WITH BACKUP은 교체 직전 상태를 남길 뿐 교체 후 상태가 아니다.
@B 같은 Oracle Home에 여러 데이터베이스가 있으면 WALLET_ROOT를 데이터베이스마다 다른 경로로 둔다. 실습 VM의 sales와 orcl처럼 서로 독립적으로 관리된다.
@B TDE는 메모리와 네트워크의 데이터를 보호하지 않는다. 네트워크 구간은 TLS(11장)나 네이티브 네트워크 암호화로 따로 보호한다.
@B 키스토어 작업(열기, 키 교체, 백업)은 감사 대상으로 둔다. Unified Auditing에서 ADMINISTER KEY MANAGEMENT 작업을 기록하면 누가 언제 키를 바꿨는지 남는다(13장).
@B 운영 문서에 WALLET_ROOT 경로, 키스토어 종류(LOCAL 여부), 마지막 키 교체일, 백업 위치를 적어 둔다. 장애 때 가장 먼저 찾는 정보다.
@B 키스토어를 닫는 작업은 업무 중단과 같다. 운영 중에는 키스토어를 닫지 않는다.
@B TDE를 시험할 때는 운영 DB나 다른 실습과 함께 쓰는 DB를 피한다. 마스터 키 활성화 기록은 되돌릴 수 없으므로 실습처럼 전용 DB에서 하고 DB째로 지운다.
@B 재기동 점검 목록에 V$ENCRYPTION_WALLET 조회를 넣는다. STATUS가 OPEN이 아니면 업무를 열기 전에 원인을 찾는다.

@H2 10.12  요약

@B TDE는 디스크에 기록되는 데이터를 엔진이 암·복호화하는 Advanced Security 옵션 기능이다. 파일 유출을 막고, 권한 있는 사용자의 조회는 막지 않는다.
@B 마스터 키는 키스토어에, 테이블·테이블스페이스 키는 마스터 키로 암호화되어 DB 안에 있다. 마스터 키 교체는 데이터를 다시 암호화하지 않아 빠르다.
@B 19c에서는 정적 파라미터 WALLET_ROOT(재기동 필요)와 동적 파라미터 TDE_CONFIGURATION으로 키스토어 위치를 정한다. sqlnet.ora의 ENCRYPTION_WALLET_LOCATION은 디프리케이트됐다.
@B ADMINISTER KEY MANAGEMENT로 키스토어 생성 → 열기 → SET KEY WITH BACKUP → auto-login 생성 순으로 구성한다. 상태는 V$ENCRYPTION_WALLET으로 확인한다.
@B 컬럼 암호화는 기본 AES192·salt, 인덱스에는 NO SALT가 필요하다. 테이블스페이스 암호화는 기본 AES128이며 성능 제약이 적어 일반적인 선택이다.
@B 기존 테이블스페이스는 ENCRYPTION ONLINE ... ENCRYPT로 열린 상태에서 변환한다. 19.3에서는 FILE_NAME_CONVERT 없이도 같은 이름으로 변환됐다.
@B 키스토어가 닫히면 암호화된 데이터 접근은 ORA-28365로 실패한다. 키스토어 백업은 RMAN 백업에 포함되지 않으므로 따로 보관한다.
@B 한 번 마스터 키를 설정한 DB는 V$DATABASE_KEY_INFO에 활성화 기록이 남는다. 키스토어를 지우면 ORA-28374, 종료 실패 같은 문제가 생기므로 키스토어는 지우지 않는다.

@H2 10.13  퀴즈

@QUIZ 문제 1
TDE가 막을 수 있는 위협은?
① SELECT 권한을 가진 사용자의 대량 조회  ② 폐기된 디스크에서 데이터 파일을 읽어 내는 것  ③ SQL 인젝션으로 테이블을 조회하는 것  ④ DBA가 SQL*Plus로 테이블을 조회하는 것
정답 ②. TDE는 디스크에 기록된 데이터를 암호화해 파일 유출을 막는다. SQL을 통한 정상 접근에는 평문을 돌려주므로 ①③④는 권한 관리, VPD, Redaction, 감사로 통제한다.
@END

@QUIZ 문제 2
19c에서 WALLET_ROOT 파라미터에 대한 설명으로 옳은 것은?
① 동적 파라미터라 즉시 적용된다  ② sqlnet.ora에 적는다  ③ 정적 파라미터라 SPFILE에 기록하고 재기동해야 한다  ④ TDE_CONFIGURATION 없이도 FILE 키스토어로 동작한다
정답 ③. WALLET_ROOT는 정적 초기화 파라미터다. 재기동 후 동적 파라미터 TDE_CONFIGURATION에 KEYSTORE_CONFIGURATION=FILE을 설정해야 WALLET_ROOT/tde의 소프트웨어 키스토어를 쓴다.
@END

@QUIZ 문제 3
키스토어를 만들고 연 직후 V$ENCRYPTION_WALLET의 STATUS가 OPEN_NO_MASTER_KEY다. 다음에 할 일은?
① ADMINISTER KEY MANAGEMENT SET KEY ... WITH BACKUP  ② ALTER SYSTEM SET ENCRYPTION KEY  ③ 인스턴스 재기동  ④ CREATE AUTO_LOGIN KEYSTORE
정답 ①. 키스토어는 열렸지만 마스터 키가 없어 암호화를 할 수 없다. SET KEY로 마스터 키를 만들면 STATUS가 OPEN이 된다. 비밀번호 키스토어에서는 WITH BACKUP이 필수다.
@END

@QUIZ 문제 4
salt를 쓴 암호화 컬럼에 B-tree 인덱스를 만들려 할 때의 결과는?
① 인덱스가 만들어지고 범위 검색에도 쓰인다  ② ORA-28338로 거부된다  ③ 인덱스는 만들어지지만 암호화되지 않는다  ④ salt가 자동으로 제거된다
정답 ②. salt를 쓰면 같은 값도 행마다 다른 암호문이 되어 인덱스를 만들 수 없다. 인덱스가 필요하면 ENCRYPT NO SALT로 암호화하며, 그때도 동등 조건 검색에만 쓰인다.
@END

@QUIZ 문제 5
local auto-login 키스토어로 열려 있는 DB에서 ADMINISTER KEY MANAGEMENT SET KEYSTORE CLOSE IDENTIFIED BY 비밀번호를 실행했다. 실습에서 나온 결과는?
① 키스토어가 닫히고 STATUS가 CLOSED가 된다  ② ORA-28417이 나고 키스토어는 OPEN, LOCAL_AUTOLOGIN으로 남는다  ③ ORA-28365가 나고 인스턴스가 멈춘다  ④ STATUS가 NOT_AVAILABLE이 된다
정답 ②. 지금 열려 있는 것은 auto-login 키스토어라 비밀번호 키스토어를 닫으라는 명령은 ORA-28417(password-based keystore is not open)로 거부된다. auto-login으로 연 키스토어는 IDENTIFIED BY 없이 CLOSE한다.
@END

@QUIZ 문제 6
TDE를 쓰는 DB를 다른 서버로 RMAN 복원할 때 데이터 파일과 별도로 반드시 확보해야 하는 것은?
① 리스너 구성 파일  ② 패스워드 파일  ③ 키스토어 파일(또는 그 백업)과 키스토어 비밀번호  ④ sqlnet.ora의 ENCRYPTION_WALLET_LOCATION
정답 ③. 키스토어는 RMAN 백업에 포함되지 않는다. 마스터 키가 들어 있는 키스토어 없이는 암호화된 데이터를 복호화할 수 없으므로 키스토어 백업과 비밀번호를 데이터 백업과 별도로 보관해야 한다.
@END

@H2 10.14  실습 개요

@P 실습은 oel7v9 서버에 DBCA로 만든 실습 전용 DB tdedb(19.3, non-CDB, OMF 미사용)에서 진행한다. WALLET_ROOT 설정과 auto-login 확인을 위해 인스턴스를 세 번 재기동하며, 한 번 활성화한 마스터 키 기록은 되돌릴 수 없으므로 마지막에 DB를 통째로 삭제한다(10.8.6).

@TBL
실습 파일 | 확인하는 개념 | 관련 절
10장_실습_01_키스토어위치구성 | 기본 위치와 MASTERKEY_ACTIVATED, ORA-46693, ORA-02095, WALLET_ROOT 재기동 | 10.4
10장_실습_02_키스토어생성과마스터키 | 원본 문법 ORA-46633, OPEN_NO_MASTER_KEY, ORA-28361, ORA-46631, SET KEY WITH BACKUP | 10.5
10장_실습_03_테이블스페이스암호화 | strings로 파일 비교, 온라인 변환, ORA-28370 | 10.7
10장_실습_04_컬럼암호화 | AES192·salt 기본값, ORA-28338, NO SALT, ORA-28340과 REKEY | 10.6
10장_실습_05_재기동과autologin과키교체 | 재기동 후 ORA-28365, LOCAL AUTO_LOGIN, 키 교체·백업, ORA-28417 | 10.5.3, 10.7.3, 10.8
10장_실습_06_원복과남는것 | 객체 삭제 후에도 남는 마스터 키 기록, 실습 DB 삭제 | 10.8.6
@END
