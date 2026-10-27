@H1 제5장  Database Link 보안

@H2 5.1  학습 목표

@P Database Link는 한 데이터베이스의 세션이 다른 데이터베이스의 객체를 자기 것처럼 쓰게 해 준다. 편리한 만큼, 링크 하나가 원격 계정의 권한을 로컬의 다른 사용자에게 그대로 옮겨 놓는 통로가 되기도 한다.

@B 링크가 원격 객체 이름을 해석하고 원격에 접속하는 과정을 설명하고, USING 절과 GLOBAL_NAMES가 이름 해석에 미치는 영향을 말할 수 있다.
@B 사설·공용 링크와 고정 사용자·연결 사용자·현재 사용자 링크를 구분하고, 각각이 원격에서 어떤 계정으로 접속하는지 설명할 수 있다.
@B 링크 생성 후 첫 사용에서 드러나는 오류(ORA-01017, ORA-12154, ORA-02085, ORA-02019)의 원인을 구분할 수 있다.
@B 정의자 권한 프로시저와 로컬 뷰로 원격 작업을 위임하는 방법과, 원격 객체에 직접 권한을 줄 수 없는 이유(ORA-02021)를 설명할 수 있다.
@B 링크 비밀번호가 저장·전송되는 방식과 ALTER DATABASE LINK로 비밀번호를 갱신하는 절차를 설명할 수 있다.
@B 공용 링크와 CREATE DATABASE LINK 권한이 만드는 위험을 점검할 수 있다.
@B Data Pump NETWORK_LINK 작업에 필요한 권한 조건(ORA-39149)과 덤프 파일 암호화를 적용할 수 있다.

@H2 5.2  Database Link의 개념

@H3 5.2.1  원격 객체를 로컬처럼 쓰는 장치

@B Database Link는 로컬 데이터베이스에 저장된 "원격 접속 정보"다. 어느 데이터베이스에, 어떤 계정으로 접속할지를 담는다.
@B SQL에서 `객체이름@링크이름` 형식으로 원격 객체를 참조한다. `SELECT * FROM emp@sales_lnk`는 링크가 가리키는 원격 DB의 EMP를 읽는다.
@B 링크를 처음 쓰는 순간 로컬 서버 프로세스가 클라이언트가 되어 원격 리스너에 접속하고, 원격에 세션을 하나 연다.
@B 이 원격 세션은 로컬 세션이 끝나거나 링크를 명시적으로 닫을 때까지 유지된다. 같은 세션에서 같은 링크를 다시 쓰면 재사용된다.
@B SELECT뿐 아니라 INSERT, UPDATE, DELETE, 원격 프로시저 호출도 링크로 한다. 원격 DML이 섞인 트랜잭션은 분산 트랜잭션이 되어 2단계 커밋으로 확정된다.
@B 원격 DB에 대한 DDL(CREATE, ALTER, GRANT 등)은 링크로 실행할 수 없다. 원격 구조 변경은 원격에 직접 접속해서 한다.
@B 동의어로 `@링크`를 감추면 애플리케이션은 원격 객체를 로컬 객체처럼 쓴다. 이를 위치 투명성(location transparency)이라 한다.
@B 위치 투명성은 편하지만, SQL만 보고는 데이터가 다른 DB에서 온다는 사실을 알 수 없게 만든다. 보안 점검에서는 동의어와 뷰 뒤에 숨은 링크까지 따라가야 한다.

@H3 5.2.2  이름 해석 — USING 절과 전역 이름

@B `USING 'SALES'`의 문자열은 Oracle Net 연결 식별자다. 링크를 쓰는 로컬 서버의 tnsnames.ora나 이름 해석 방식으로 해석된다. 클라이언트 PC의 설정과는 관계가 없다.
@B 별칭 대신 `USING '(DESCRIPTION=(ADDRESS=...)(CONNECT_DATA=(SERVICE_NAME=sales)))'`처럼 접속 기술자를 직접 넣을 수도 있다. tnsnames.ora 관리 권한이 없거나 별칭 충돌을 피할 때 쓴다.
@B 별칭이 로컬에 없으면 링크 생성은 성공하고 첫 사용에서 ORA-12154가 난다.
@B 모든 데이터베이스는 전역 이름(global name)을 가진다. `SELECT * FROM global_name`으로 확인한다. 실습 환경의 두 DB는 ORCL, SALES다.
@B 초기화 파라미터 GLOBAL_NAMES가 TRUE면 링크 이름이 원격 DB의 전역 이름과 같아야 한다. 다르면 사용 시점에 ORA-02085(database link X connects to Y)가 난다.
@B GLOBAL_NAMES = TRUE는 링크 이름만 보고 목적지를 알 수 있게 강제한다. 링크가 많은 분산 환경에서 엉뚱한 DB에 접속하는 실수를 막는다. 세션 단위로도 바꿀 수 있다.

@H3 5.2.3  보안 관점에서 본 링크

@P 링크는 접속 정보를 데이터베이스 안에 저장해 둔다는 점에서 보안 검토 대상이다. 검토할 쟁점은 다음 세 가지다.

@TBL
쟁점 | 내용 | 다루는 절
권한의 이동 | 링크를 쓸 수 있는 로컬 사용자는 원격 계정의 권한으로 원격 데이터를 다룸 | 5.5, 5.6.5
자격 증명 저장 | 고정 사용자 링크는 원격 계정 비밀번호를 로컬 딕셔너리에 보관 | 5.6.1
네트워크 노출 | 링크 접속은 Oracle Net 통신이며, 고정 사용자 링크는 자격 증명을 원격에 보냄 | 5.6.2, 11장
@END

@B 원격 DB 입장에서 링크 접속은 일반 클라이언트 접속과 구별되지 않는다. 원격 계정에 준 권한이 곧 링크를 쓰는 모든 로컬 사용자의 상한이다.
@B 그래서 링크가 접속할 원격 계정은 링크 용도에 필요한 최소 권한만 가진 전용 계정으로 만든다. 업무 계정이나 DBA 계정을 링크 계정으로 쓰지 않는다.

@H3 5.2.4  링크 이름의 해석 규칙

@B 링크 이름에는 도메인을 붙일 수 있다. `sales.example.com`처럼 전체 이름을 쓰면 그대로, `sales`처럼 일부만 쓰면 로컬 DB 전역 이름의 도메인이 붙어 해석된다.
@B 매뉴얼은 부분 링크 이름을 확장할 때 DB_DOMAIN 파라미터가 아니라 로컬 전역 이름의 도메인을 쓴다고 명시한다. 전역 이름을 바꾸면 기존 링크 이름의 해석이 달라질 수 있다.
@B 실습 환경의 두 DB는 전역 이름에 도메인이 없어(ORCL, SALES) 링크 이름도 도메인 없이 쓴다.
@B GLOBAL_NAMES = TRUE 환경에서 같은 원격 DB로 가는 링크를 여러 개 두어야 하면 `SALES@HR_APP`처럼 링크 이름 뒤에 한정자(qualifier)를 붙인다. 앞부분이 전역 이름과 같으면 허용된다.
@B 링크 이름은 객체 이름 규칙을 따르지만 점(.)과 @를 포함할 수 있어 다른 객체와 구별된다. 이름 짓기 규칙을 정해 두면 감사 기록과 장애 분석이 쉬워진다.

@H2 5.3  링크의 종류와 필요한 권한

@H3 5.3.1  사설·공용·전역 링크

@TBL
종류 | 생성 문법 | 사용할 수 있는 사용자
사설(private) | CREATE DATABASE LINK | 링크를 소유한 스키마 사용자만
공용(public) | CREATE PUBLIC DATABASE LINK | 로컬 DB의 모든 사용자
전역(global) | 디렉터리 서버(LDAP)에 등록 | 디렉터리를 쓰는 모든 DB의 사용자
@END

@B 사설 링크는 소유자만 이름으로 참조할 수 있다. 다른 사용자가 같은 이름을 쓰면 ORA-02019: connection description for remote database not found가 난다.
@B 사설 링크를 다른 사용자에게 쓰게 하는 GRANT는 없다. 소유자의 뷰·프로시저를 통해서만 간접적으로 쓰게 할 수 있다(5.5절).
@B 공용 링크는 권한 없이 누구나 쓴다. 고정 사용자 공용 링크라면 로컬 DB의 모든 사용자가 같은 원격 계정으로 원격에 접속한다.
@B 이름이 같은 사설 링크와 공용 링크가 함께 있으면 사설 링크가 우선한다.

@H3 5.3.2  원격 접속 계정 — 고정·연결·현재 사용자

@TBL
유형 | 생성 문법 | 원격에서 접속하는 계정 | 비밀번호 저장
고정 사용자(fixed user) | CONNECT TO 사용자 IDENTIFIED BY 비밀번호 | 링크에 적힌 계정 | 로컬 딕셔너리에 암호화 저장
연결 사용자(connected user) | CONNECT TO 절 생략 | 링크를 쓰는 로컬 세션의 사용자 | 저장하지 않음
현재 사용자(current user) | CONNECT TO CURRENT_USER | 실행 문맥의 현재 사용자(전역 사용자) | 저장하지 않음
@END

@B 고정 사용자 링크가 가장 흔하다. 원격 계정 하나를 정해 두고 로컬의 여러 사용자가 그 계정으로 원격 작업을 한다.
@B 연결 사용자 링크는 원격 DB에 같은 이름과 같은 비밀번호의 계정이 있어야 한다. 없으면 ORA-01017이다. 사용자마다 원격 권한을 따로 관리할 수 있는 대신, 두 DB의 계정과 비밀번호를 맞춰 관리해야 한다.
@B 연결 사용자 링크는 정의자 권한 프로시저 안에서 쓰여도 세션 사용자로 접속한다. 프로시저를 실행한 사용자마다 원격 계정이 달라지므로, 위임용 프로시저에는 고정 사용자 링크를 쓴다.
@B 현재 사용자 링크는 정의자 권한 프로시저 안에서는 프로시저 소유자로, 밖에서는 세션 사용자로 접속한다. 매뉴얼에 따르면 두 DB 모두에서 전역 사용자(Enterprise User Security)여야 하며 Advanced Security 옵션이 필요하다. 로컬 DB 계정으로 쓰면 ORA-01017로 실패한다.

@CODE
CREATE DATABASE LINK sales_lnk
  CONNECT TO sec05_rmt IDENTIFIED BY sec05_rmt
  USING 'SALES';                      -- 고정 사용자

CREATE DATABASE LINK sales_cu USING 'SALES';   -- 연결 사용자

CREATE DATABASE LINK sales_curr
  CONNECT TO CURRENT_USER USING 'SALES';      -- 현재 사용자
@END

@H3 5.3.3  공유 링크

@B 공유 서버 환경에서 많은 세션이 같은 링크를 쓰면 원격 연결 수가 크게 는다. SHARED 키워드로 만든 링크는 원격 연결을 여러 세션이 나눠 쓴다.
@B 공유 링크는 `AUTHENTICATED BY` 절로 별도 인증 계정을 지정해야 한다. 매뉴얼은 이 계정이 링크 사용자로 위장한 클라이언트로부터 원격 공유 서버 프로세스를 보호한다고 설명한다.
@B 전용 서버 환경의 일반 업무에서는 공유 링크가 필요한 경우가 드물다.

@H3 5.3.4  필요한 권한

@TBL
권한 | 위치 | 필요한 작업
CREATE DATABASE LINK | 로컬 | 사설 링크 생성
CREATE PUBLIC DATABASE LINK | 로컬 | 공용 링크 생성
DROP PUBLIC DATABASE LINK | 로컬 | 공용 링크 삭제
ALTER DATABASE LINK | 로컬 | 사설 고정 사용자 링크의 비밀번호 갱신
ALTER PUBLIC DATABASE LINK | 로컬 | 공용 고정 사용자 링크의 비밀번호 갱신
CREATE SESSION | 원격 | 링크가 접속할 원격 계정
@END

@B 사설 링크 삭제에는 별도 권한이 없다. 소유자는 자기 링크를 지울 수 있다.
@B ALTER DATABASE LINK는 링크 소유자라도 시스템 권한을 받아야 한다. 받지 않으면 자기 링크도 ORA-01031로 거부된다.
@B 19c 샘플 스키마(HR, OE, SH 등)와 RESOURCE 역할을 받은 일부 계정에 CREATE DATABASE LINK가 직접 부여되어 있다. 이 권한은 아무 원격 DB로든 나가는 통로를 만들 수 있으므로 정기 점검 대상이다.

@H3 5.3.5  링크 도입 절차

@P 운영 환경에 새 링크를 만들 때는 원격 쪽과 로컬 쪽 작업을 나눠 순서대로 진행한다. 원격 DBA와 로컬 DBA가 다른 사람인 경우가 많아 절차를 문서로 맞춰 둔다.

@TBL
단계 | 위치 | 작업 | 확인할 것
1 | 원격 | 링크 전용 계정 생성, 필요한 객체 권한만 부여 | CREATE SESSION + 대상 객체 권한, DBA·ANY 권한 없음
2 | 원격 | 링크 계정용 프로파일 지정 | 비밀번호 만료 주기, 실패 로그인 잠금 정책
3 | 로컬 | 연결 식별자 준비 | 로컬 서버에서 tnsping, 또는 USING에 접속 기술자
4 | 로컬 | 링크 소유 계정에 링크 생성 | 사설 링크, 이름 규칙, 공용 링크 금지
5 | 로컬 | 접속 시험 | global_name@링크, user_users@링크
6 | 로컬 | 위임 객체 작성 | 프로시저·뷰, 업무 계정에는 그 객체 권한만
7 | 양쪽 | 감사 설정 | 로컬 링크 DDL 감사, 원격 링크 계정 접속 감사
8 | 로컬 | 비밀번호 보관 | 원격 계정 비밀번호를 별도 비밀 관리 체계에 기록
@END

@B 1단계에서 원격 계정 권한을 넓게 주면 이후 단계의 통제가 모두 무의미해진다. 링크 계정의 원격 권한이 위임 범위의 상한이다.
@B 4단계의 링크 소유 계정은 업무 접속에 쓰지 않는 전용 계정으로 둔다. 링크를 쓰는 위임 객체만 이 계정에 둔다.
@B 링크를 폐기할 때는 거꾸로 진행한다. 위임 객체 권한 회수, 링크 삭제, 원격 계정 잠금·삭제 순이다.

@H3 5.3.6  연결 사용자 링크와 INHERIT REMOTE PRIVILEGES

@P 연결 사용자 링크를 정의자 권한 프로시저 안에서 쓰면 프로시저는 소유자 권한으로 돌지만 원격 접속에는 실행한 사용자의 자격 증명이 쓰인다. Security Guide는 이 경우를 따로 통제하는 객체 권한으로 INHERIT REMOTE PRIVILEGES를 둔다(문서 기준, 실습 범위 밖).

@B 프로시저를 실행할 사용자가 프로시저 소유자에게 `GRANT INHERIT REMOTE PRIVILEGES ON USER 실행자 TO 소유자`로 권한을 준다. 내 자격 증명을 그 소유자의 코드가 원격 접속에 쓰도록 허락하는 구조다.
@B 권한이 없는 상태로 실행하면 ORA-25433: User does not have INHERIT REMOTE PRIVILEGES가 난다.
@B 적용 범위는 정의자 권한 프로시저 안의 연결 사용자 링크다. 사설 링크와 공용 링크에 모두 해당하며, 고정 사용자 링크에는 관계가 없다.
@B 기본값으로 PUBLIC에는 부여되어 있지 않다. 업그레이드한 DB의 기존 사용자에게도 자동으로 부여되지 않으므로, 업그레이드 후 연결 사용자 링크를 쓰는 프로시저가 ORA-25433으로 멈출 수 있다.
@B 시스템 권한 INHERIT ANY REMOTE PRIVILEGES는 모든 사용자의 자격 증명을 상속한다. SYS가 WITH GRANT OPTION으로 갖고 있으며, 매뉴얼은 신뢰하는 사용자에게만 주라고 적는다.
@B 문서의 예제는 부여 후 다시 접속해야 효과가 난다고 설명한다. 현재 세션에서 바로 시험하면 오류가 그대로 남을 수 있다.

@CODE
-- 실행자(hr)가 프로시저 소유자(sec05_own)에게 부여
HR@orcl> GRANT INHERIT REMOTE PRIVILEGES ON USER hr TO sec05_own;

-- 회수
HR@orcl> REVOKE INHERIT REMOTE PRIVILEGES ON USER hr FROM sec05_own;
@END

@B 5.3.2에서 위임용 프로시저에 고정 사용자 링크를 권장하는 이유가 여기서도 드러난다. 연결 사용자 링크를 쓰면 실행자마다 원격 계정이 바뀌는 데다, 실행자마다 이 권한까지 관리해야 한다.

@H2 5.4  링크 생성과 사용 시점 오류

@H3 5.4.1  생성은 접속을 검증하지 않는다

@B CREATE DATABASE LINK는 접속 정보를 딕셔너리에 기록할 뿐 원격에 접속해 보지 않는다. 비밀번호가 틀려도, 별칭이 없어도 "Database link created."가 나온다.
@B 오류는 링크를 처음 쓰는 순간 나온다. 배포 스크립트가 링크를 만든 뒤 바로 시험 조회를 하지 않으면 업무가 시작된 뒤에야 문제를 안다.
@B 링크를 통해 난 원격 오류에는 ORA-02063(preceding line from 링크이름)이 붙는다. 어느 링크에서 온 오류인지 알려 주는 꼬리표다.

@TBL
오류 | 원인 | 확인 방법
ORA-12154 | USING 별칭을 로컬 서버가 해석하지 못함 | 로컬 서버에서 tnsping 별칭
ORA-12514, ORA-12541 | 원격 리스너·서비스 문제 | 원격 lsnrctl status
ORA-01017 + ORA-02063 | 원격 계정 이름·비밀번호 불일치 | 원격에서 직접 접속 시험
ORA-02085 | GLOBAL_NAMES=TRUE인데 링크 이름 ≠ 원격 전역 이름 | SELECT * FROM global_name@링크 (FALSE 상태에서)
ORA-02019 | 해당 이름의 링크가 내 스키마나 공용에 없음 | DBA_DB_LINKS의 OWNER
@END

@B DBA_DB_LINKS의 VALID 열은 19c에 있는 열이다. 비밀번호가 틀린 링크도 YES로 남아 있으므로 접속 가능 여부의 근거로 쓰지 않는다.

@BP 링크를 만든 직후 할 일
링크를 만들면 그 자리에서 `SELECT * FROM global_name@링크`로 목적지 DB를 확인한다.
`SELECT username FROM user_users@링크`로 원격에서 실제로 접속한 계정을 확인한다.
링크 이름에 목적지 DB 이름을 넣어 이름만 보고 목적지를 알 수 있게 한다. 가능하면 GLOBAL_NAMES = TRUE를 쓴다.
배포 스크립트에 위 두 조회를 넣어 실패하면 배포를 멈추게 한다.
@END

@H3 5.4.2  원격 계정 확인 — USER 함수의 함정

@B `SELECT USER FROM dual@sales_lnk`는 원격 계정이 아니라 로컬 세션 사용자를 돌려준다. USER는 로컬에서 평가되는 함수다.
@B 고정 사용자 링크(원격 계정 SEC05_RMT)로 이 문장을 실행해도 결과는 로컬 사용자 SEC05_OWN이다. 공용 링크를 SCOTT가 쓰면 SCOTT가 나온다.
@B 원격에서 실제로 접속한 계정은 원격 뷰를 조회해 확인한다. `SELECT username FROM user_users@sales_lnk`는 원격에서 실행되어 SEC05_RMT를 돌려준다.
@CODE
SEC05_OWN@orcl> SELECT USER FROM dual@sales_lnk;
USER
------------
SEC05_OWN

SEC05_OWN@orcl> SELECT username FROM user_users@sales_lnk;
USERNAME
------------
SEC05_RMT
@END

@B SYSDATE 같은 다른 SQL 함수도 원격 객체와 함께 쓸 때 어디서 평가되는지 주의한다. 원격 시각이 필요하면 원격 뷰나 원격 함수 호출로 받는다.

@H3 5.4.3  USING에 접속 기술자를 직접 쓰기

@B tnsnames.ora에 별칭을 추가할 권한이 없거나, 별칭이 다른 용도와 충돌하면 USING에 접속 기술자 전체를 넣는다.
@B 기술자를 넣은 링크는 tnsnames.ora와 무관하게 동작한다. 대신 원격 호스트나 서비스 이름이 바뀌면 링크를 다시 만들어야 한다.
@B 기술자는 DBA_DB_LINKS의 HOST 열에 그대로 남는다. 접속 정보가 딕셔너리에 노출되지만 비밀번호는 포함되지 않는다.
@B 별칭 방식은 서버의 tnsnames.ora를 고칠 수 있는 사람이 링크의 목적지를 바꿀 수 있다는 뜻이기도 하다. tnsnames.ora 파일 권한도 링크 보안의 일부다.

@CODE
CREATE DATABASE LINK sales_desc
  CONNECT TO sec05_rmt IDENTIFIED BY sec05_rmt
  USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=oel7v9)(PORT=1521))
          (CONNECT_DATA=(SERVICE_NAME=sales)))';
@END

@H2 5.5  링크를 통한 권한 위임

@H3 5.5.1  정의자 권한 프로시저로 원격 DML 위임

@P 원격 데이터를 고쳐야 하는 사용자에게 원격 계정 비밀번호나 링크를 직접 주지 않고, 링크 소유자가 만든 프로시저만 실행하게 하는 방식이다. 매뉴얼도 원격 DB 권한을 사용자에게 주지 않는 간단한 방법으로 링크를 품은 프로시저를 제시한다.

@CODE
CREATE OR REPLACE PROCEDURE update_rmt_sal (
  p_empno IN NUMBER,
  p_sal   IN NUMBER)
IS
BEGIN
  UPDATE emp@sales_lnk SET sal = p_sal WHERE empno = p_empno;
END;
/
GRANT EXECUTE ON update_rmt_sal TO sec05_r1;
@END

@B 프로시저는 정의자 권한으로 실행되므로 링크도 소유자(sec05_own) 문맥에서 쓰인다. 실행 권한만 받은 HR은 링크 이름도 원격 비밀번호도 모른다.
@B HR이 할 수 있는 일은 프로시저가 허용한 형태로 한정된다. 위 예라면 사번과 급여를 받아 급여만 바꾼다.
@B 역할을 통해 받은 EXECUTE 권한으로도 프로시저가 실행된다. 실행 권한 관리를 역할로 묶어 두면 사용자 추가·삭제가 쉽다.
@B 원격 UPDATE가 포함된 트랜잭션은 분산 트랜잭션이다. 호출한 세션의 COMMIT이 로컬과 원격을 함께 확정한다.
@B 프로시저 안에서 입력값을 검사하지 않으면 위임 범위가 넓어진다. 허용 범위(대상 부서, 급여 상한 등)를 프로시저가 검사하게 한다.

@H3 5.5.2  원격 객체에는 GRANT할 수 없다

@B 링크 소유자가 `GRANT SELECT ON emp@sales_lnk TO hr`를 실행하면 ORA-02021: DDL operations are not allowed on a remote database가 난다.
@B GRANT는 DDL이고 원격 객체에 대한 DDL은 링크로 실행할 수 없다. 원격 DB의 권한은 원격 DB 안에서만 관리된다.
@B 조회를 위임하려면 원격 테이블을 감싼 로컬 뷰를 만들고 그 뷰에 권한을 준다. 뷰의 열과 조건이 노출 범위를 정한다.
@B 받은 사용자는 동의어를 만들어 원격 데이터를 로컬 테이블처럼 쓸 수 있다.

@CODE
SEC05_OWN@orcl> CREATE VIEW emp_rmt_vw AS
  2    SELECT empno, ename, sal, deptno FROM emp@sales_lnk;
SEC05_OWN@orcl> GRANT SELECT ON emp_rmt_vw TO hr;

HR@orcl> CREATE SYNONYM rmt_emp FOR sec05_own.emp_rmt_vw;
HR@orcl> SELECT deptno, COUNT(*) FROM rmt_emp GROUP BY deptno;
@END

@B 뷰에 SELECT만 줬다면 HR의 UPDATE는 ORA-01031로 막힌다. 조회와 변경을 서로 다른 객체(뷰, 프로시저)로 나눠 위임하면 범위를 따로 통제한다.

@NOTE 원본 실습 자료와 다른 점
원본 자료는 SYS로 링크와 프로시저를 만들고, HR의 기존 EMP 테이블을 DROP한 뒤 같은 이름의 동의어를 만든다.
SYS 스키마에 업무 객체를 두면 업그레이드·패치 때 관리가 어렵고, SYS 소유 정의자 권한 프로시저는 그 자체로 위험한 권한 통로가 된다. 이 교안은 전용 링크 소유 계정(sec05_own)을 쓰고, 기존 테이블을 지우지 않도록 새 이름(rmt_emp)의 동의어를 만들었다.
@END

@CASE 보고서 담당자가 운영 DB의 급여를 바꿀 수 있었다
분석 DB에서 운영 DB로 가는 고정 사용자 공용 링크가 있었다. 링크 계정은 개발 초기에 편의상 운영 업무 계정으로 만들어 두었다.
보안 점검에서 보고서 작성용으로만 분석 DB에 접속하던 계정들이 이 공용 링크로 운영 DB의 급여 테이블을 UPDATE할 수 있다는 것이 드러났다. 원격 DB 입장에서는 정상 업무 계정의 접속이라 경보도 없었다.
공용 링크를 지우고, 운영 DB에 조회 전용 링크 계정을 새로 만들었다. 분석 DB에서는 전용 링크 소유 계정이 사설 링크를 갖고, 보고서 계정에는 필요한 열만 담은 뷰의 SELECT 권한만 줬다.
@END

@H3 5.5.3  링크에 의존하는 객체 찾기

@B 링크를 지우거나 비밀번호를 바꾸기 전에 그 링크를 쓰는 뷰·프로시저·동의어를 찾아야 한다. DBA_DEPENDENCIES의 REFERENCED_LINK_NAME 열이 이 정보를 담는다.
@B 링크를 쓰는 객체가 많으면 링크 하나의 장애가 여러 업무로 번진다. 의존 객체 목록을 링크 관리 문서에 함께 둔다.

@CODE
SELECT owner, name, type, referenced_owner, referenced_name, referenced_link_name
  FROM dba_dependencies
 WHERE referenced_link_name IS NOT NULL
 ORDER BY referenced_link_name, owner, name;
@END

@H3 5.5.4  위임 방식 비교

@TBL
방식 | 업무 계정이 받는 권한 | 노출 범위 | 비고
로컬 뷰 | 뷰의 SELECT | 뷰가 정한 열·행 | 조회 위임에 적합
로컬 프로시저(정의자 권한) | 프로시저 EXECUTE | 프로시저가 허용한 작업 | 변경 위임, 입력값 검사 가능
원격 프로시저 호출 | 로컬 래퍼 EXECUTE | 원격 프로시저의 논리 | 변경 규칙을 원격 DB가 소유
사설 링크 직접 사용 | 링크 소유자 본인만 | 원격 계정 권한 전체 | 위임 수단이 아님
공용 링크 | 권한 불필요 | 원격 계정 권한 전체를 모든 사용자에게 | 피해야 할 방식
@END

@B 원격 DB 쪽에 업무 규칙을 담은 프로시저를 만들어 두고 링크로 호출하면, 변경 규칙을 데이터 소유 DB가 관리한다. 로컬은 `원격프로시저@링크(인자)`를 호출하는 래퍼만 갖는다.
@B 이 경우 링크 계정에는 원격 테이블 권한 대신 원격 프로시저 EXECUTE만 주면 된다. 링크가 탈취돼도 할 수 있는 일이 원격 프로시저의 범위로 줄어든다.

@CODE
-- 원격(sales)
CREATE OR REPLACE PROCEDURE sec05_rmt.raise_sal (p_empno NUMBER, p_pct NUMBER) IS
BEGIN
  IF p_pct > 10 THEN
    RAISE_APPLICATION_ERROR(-20001, 'raise limit exceeded');
  END IF;
  UPDATE sec05_rmt.emp SET sal = sal * (1 + p_pct / 100) WHERE empno = p_empno;
END;
/
-- 로컬(orcl), 링크 소유자
BEGIN
  sec05_rmt.raise_sal@sales_lnk(201, 5);
END;
/
@END

@H2 5.6  링크 자격 증명 보호

@H3 5.6.1  비밀번호는 어디에 남는가

@B 고정 사용자 링크의 원격 비밀번호는 로컬 딕셔너리 테이블 SYS.LINK$에 저장된다. PASSWORD 열은 비어 있고 PASSWORDX 열에 암호화된 값만 있다.
@B DBA_DB_LINKS에는 비밀번호 열 자체가 없다. 소유자, 링크 이름, 원격 사용자, HOST(USING 문자열), 생성 시각, VALID 등을 보여 준다.
@CODE
SYS@orcl> SELECT name, userid, password, passwordx FROM sys.link$ WHERE name = 'SALES_LNK';

NAME       USERID     PASSWORD PASSWORDX
---------- ---------- -------- ----------------------------------------
SALES_LNK  SEC05_RMT           07EA7F36F870D40B5F09C3F80E6FF521403788C9
@END

@B DBA 역할을 가진 SYSTEM도 SYS.LINK$를 직접 조회하면 ORA-01031로 막힌다. 12c부터 SELECT ANY DICTIONARY 권한에서 LINK$, USER$ 같은 민감한 딕셔너리 테이블이 제외됐다.
@B 그렇다고 링크 비밀번호를 알 필요가 없는 것은 아니다. 링크를 다시 만들거나 다른 DB로 옮길 때 원격 비밀번호가 필요하므로 별도 비밀번호 관리 체계에 보관한다.
@B Data Pump로 스키마를 옮기면 링크 정의도 함께 옮겨지며, 암호화된 비밀번호 값이 새 DB에서 그대로 쓰이지 않을 수 있다. 이관 후에는 링크마다 접속 시험을 한다.

@H3 5.6.2  네트워크로 오가는 자격 증명

@B 고정 사용자 링크는 접속할 때마다 원격 계정의 자격 증명을 원격 서버에 보낸다. 매뉴얼은 이를 고정 사용자 링크의 특징으로 명시한다.
@B Oracle Net의 인증 과정은 비밀번호를 평문으로 보내지 않지만, 접속 후 오가는 데이터는 기본적으로 암호화되지 않는다.
@B 링크 구간에 민감한 데이터가 흐르면 두 서버 사이의 Oracle Net 통신을 암호화한다. 네이티브 네트워크 암호화나 TLS(11장)를 적용한다.
@B 링크는 서버에서 서버로 가는 접속이라, 클라이언트 PC 쪽 sqlnet.ora 설정은 영향이 없다. 로컬 DB 서버의 sqlnet.ora가 링크 접속의 클라이언트 설정이다.

@NOTE 링크 구간 암호화 설정은 어디에 하나
링크 접속에서 로컬 DB 서버는 클라이언트, 원격 DB 서버는 서버 역할을 한다. 네이티브 네트워크 암호화라면 로컬 서버 sqlnet.ora의 SQLNET.ENCRYPTION_CLIENT와 원격 서버 sqlnet.ora의 SQLNET.ENCRYPTION_SERVER가 협상에 쓰인다.
원격 서버에 SQLNET.ENCRYPTION_SERVER = REQUIRED를 두면 일반 클라이언트 접속과 링크 접속이 모두 암호화를 강제받는다. 실습 환경은 두 DB가 같은 홈의 sqlnet.ora를 공유한다.
@END

@H3 5.6.3  원격 비밀번호를 바꿀 때 — ALTER DATABASE LINK

@B 원격 계정 비밀번호를 바꾸면 그 계정을 쓰는 모든 고정 사용자 링크가 다음 사용에서 ORA-01017로 실패한다. 링크는 옛 비밀번호를 들고 있다.
@B 원격 계정에 비밀번호 만료 정책(PASSWORD_LIFE_TIME)이 걸려 있으면 같은 장애가 정기적으로 반복된다. 링크 계정용 프로파일을 따로 두고 교체 주기를 운영 일정으로 관리한다.
@B 12.2부터 `ALTER DATABASE LINK 링크 CONNECT TO 사용자 IDENTIFIED BY 새비밀번호`로 링크의 비밀번호만 바꿀 수 있다.
@B 매뉴얼의 제약은 다음과 같다. 고정 사용자 링크에만 쓰며, 원격 사용자를 바꿀 수는 없다(사용자를 바꾸려면 다시 만든다). 원격 계정 비밀번호 변경은 ALTER USER로 먼저 해야 한다.
@B 사설 링크는 ALTER DATABASE LINK, 공용 링크는 ALTER PUBLIC DATABASE LINK 시스템 권한이 필요하다. 링크 소유자도 권한이 없으면 ORA-01031이다.
@B DROP 후 CREATE와 달리 링크를 쓰는 뷰·프로시저가 INVALID 상태를 거치지 않는다. 운영 중 교체에 유리하다.

@CODE
SYSTEM@SALES> ALTER USER sec05_rmt IDENTIFIED BY sec05_new;

SYS@orcl> GRANT ALTER DATABASE LINK TO sec05_own;
SEC05_OWN@orcl> ALTER DATABASE LINK sales_lnk
  2    CONNECT TO sec05_rmt IDENTIFIED BY sec05_new;
@END

@BP 링크 계정 비밀번호 교체 순서
원격 DB에서 ALTER USER로 비밀번호를 바꾼다.
그 계정을 쓰는 링크를 모든 로컬 DB에서 찾는다(DBA_DB_LINKS의 USERNAME과 HOST).
링크마다 ALTER DATABASE LINK로 새 비밀번호를 넣는다.
링크마다 `SELECT username FROM user_users@링크`로 접속을 확인한다.
@END

@B 링크 계정 전용 프로파일의 예는 다음과 같다. 사람이 쓰는 계정과 정책을 분리하고, 실패 로그인 잠금은 유지해 무차별 대입을 막는다.

@CODE
CREATE PROFILE link_prof LIMIT
  PASSWORD_LIFE_TIME     180
  PASSWORD_GRACE_TIME    14
  FAILED_LOGIN_ATTEMPTS  5
  PASSWORD_LOCK_TIME     1/24;
ALTER USER sec05_rmt PROFILE link_prof;
@END

@B 실패 로그인 잠금은 양날이다. 링크 비밀번호가 틀린 상태로 배치가 반복 실행되면 링크 계정이 잠겨 다른 정상 링크까지 멈춘다. 교체 작업 중에는 배치를 멈춘다.

@H3 5.6.4  공용 링크의 위험

@B 고정 사용자 공용 링크는 로컬 DB의 모든 사용자에게 원격 계정 권한을 나눠 주는 것과 같다. 권한을 하나도 받지 않은 계정도 쓸 수 있다.
@B 새로 만든 계정, 잊힌 테스트 계정, 애플리케이션 계정이 모두 원격 DB에 접근할 수 있게 된다. 원격 DB의 감사 기록에는 링크 계정 이름만 남아 실제 사용자를 알기 어렵다.
@B 공용 링크가 꼭 필요하다면 연결 사용자 방식으로 만들어 원격 DB가 사용자별로 인증·권한을 판단하게 한다.
@B 공용 링크 생성·삭제 권한(CREATE/DROP PUBLIC DATABASE LINK)은 DBA 외에는 주지 않는다.

@H3 5.6.5  링크를 만들 수 있는 계정 관리

@B CREATE DATABASE LINK 권한이 있는 사용자는 자기가 아는 원격 계정으로 어떤 DB에든 링크를 만들 수 있다. 데이터를 밖으로 빼내는 경로가 될 수 있다.
@B 19c의 샘플 스키마 계정에는 이 권한이 직접 부여되어 있다. 운영 DB에서 샘플 스키마를 지우거나 잠그고, 업무에 필요 없는 계정의 권한을 회수한다.
@B 링크 생성·변경·삭제는 감사한다. Unified Auditing에서 CREATE DATABASE LINK, ALTER DATABASE LINK, DROP DATABASE LINK 동작을 감사 정책에 넣을 수 있다(13장).
@B 원격 DB 쪽에서도 링크 계정의 접속 위치를 제한한다. 링크 계정은 정해진 서버에서만 접속하므로 접속 IP·프로그램을 감사하거나 제한하기 쉽다.

@H3 5.6.6  링크 계정 권한 설계 예

@TBL
링크 용도 | 원격 계정에 줄 권한 | 주지 않을 권한
보고용 조회 | CREATE SESSION, 대상 테이블·뷰 SELECT | SELECT ANY TABLE, DBA 역할
정해진 변경 | CREATE SESSION, 원격 프로시저 EXECUTE | 대상 테이블 UPDATE·DELETE 직접 권한
이관 작업(한시) | CREATE SESSION, DATAPUMP_EXP_FULL_DATABASE | 작업 기간 이후의 FULL 역할
연결 사용자 링크 | 사용자별 업무 권한 | 공용 링크와 결합한 넓은 권한
@END

@B 원격 계정이 원격 DB의 객체를 소유하지 않게 한다. 소유자는 자기 객체에 모든 권한을 가지므로, 링크 계정이 테이블 소유자면 위임 범위를 좁힐 수 없다.
@B 실습의 sec05_rmt는 단순화를 위해 원격 EMP 테이블의 소유자로 만들었다. 운영에서는 데이터 소유 스키마와 링크 계정을 분리한다.

@H3 5.6.7  원격 쪽에서 링크 접속 식별

@B 원격 DB의 V$SESSION에서 링크 접속은 링크 계정 이름으로 보이고, MACHINE은 로컬 DB 서버, PROGRAM은 로컬 서버 프로세스(oracle@호스트) 형태로 나타난다.
@B 로컬에서 실제로 어떤 사용자가 링크를 썼는지는 원격 세션 정보만으로 알 수 없다. 공용 링크나 위임 프로시저를 여러 사용자가 쓰면 원격에는 같은 계정 하나로만 보인다.
@B Unified Auditing의 감사 기록(UNIFIED_AUDIT_TRAIL)에는 DBLINK_INFO 열이 있어, 링크를 통해 들어온 작업이면 원본 DB의 전역 이름, 링크 이름, 원본 세션의 감사 세션 ID 등이 기록된다. 원격과 로컬의 감사 기록을 이어 볼 수 있는 단서다.
@B 로컬 쪽에서 링크를 쓰는 프로시저 호출을 감사하면, 원격 기록과 시각을 맞춰 실제 사용자를 추적한다.

@CASE 매달 1일 새벽 배치가 실패한다
월초 정산 배치가 몇 달에 한 번씩 ORA-01017과 ORA-02063으로 실패했다. 배치를 다시 돌리면 같은 오류가 나고, DBA가 링크를 다시 만들면 해결됐다.
원격 DB의 링크 계정에 기본 프로파일이 적용되어 있었고, 비밀번호 수명(PASSWORD_LIFE_TIME)이 지나 만료된 것이 원인이었다. 만료 경고 기간에도 링크 접속은 경고를 보여 줄 사람이 없어 아무도 알아채지 못했다.
링크 계정 전용 프로파일을 만들어 수명과 교체 주기를 운영 일정에 맞췄다. 교체는 원격 ALTER USER 후 로컬 ALTER DATABASE LINK 순서로 하고, 교체 직후 user_users@링크 조회로 확인하는 절차를 문서화했다.
@END

@H2 5.7  분산 트랜잭션과 링크 연결 관리

@H3 5.7.1  링크 연결의 수명

@B 세션이 링크를 한 번 쓰면 원격 연결은 세션이 끝날 때까지 열려 있다. 연결 풀처럼 오래 사는 세션은 원격 연결도 오래 붙잡는다.
@B 세션당 동시에 열 수 있는 링크 연결 수는 OPEN_LINKS(기본 4)가 정한다. 정적 파라미터이며 0이면 분산 트랜잭션을 쓸 수 없다.
@B 현재 세션이 연 링크는 V$DBLINK로 본다. LOGGED_ON, OPEN_CURSORS, IN_TRANSACTION, UPDATE_SENT 열로 상태를 판단한다.
@B V$DBLINK는 현재 세션의 정보만 보여 준다. 매뉴얼은 SYSDBA로 접속해도 다른 세션의 링크는 볼 수 없다고 설명한다.
@B 원격 SELECT만 해도 IN_TRANSACTION이 YES가 된다. 원격 조회도 분산 트랜잭션 상태를 연다.

@H3 5.7.2  링크 닫기

@B `ALTER SESSION CLOSE DATABASE LINK 링크`로 현재 세션의 링크 연결을 닫는다.
@B 트랜잭션이 진행 중이면 ORA-02080: database link is in use로 거부된다. COMMIT이나 ROLLBACK으로 트랜잭션을 끝낸 뒤 닫는다.
@B 링크를 가끔 쓰는 애플리케이션은 사용 후 닫아 원격 DB의 세션 수를 줄인다.
@B PL/SQL 안에서는 `DBMS_SESSION.CLOSE_DATABASE_LINK('링크')`로 같은 일을 한다. PL/SQL Packages and Types Reference는 이 프로시저를 ALTER SESSION CLOSE DATABASE LINK와 같은 동작으로 설명한다. 동적 SQL 없이 배치 프로시저 끝에서 링크를 정리할 때 쓴다.
@B 네트워크 장애로 2단계 커밋 도중 연결이 끊기면 in-doubt 트랜잭션이 남을 수 있다. DBA_2PC_PENDING에서 확인하고, 보통 연결이 복구되면 RECO 프로세스가 자동으로 정리한다.
@B in-doubt 트랜잭션이 잡은 행은 정리될 때까지 잠겨 있다. 원격 DB가 오래 복구되지 않으면 DBA가 COMMIT FORCE 또는 ROLLBACK FORCE로 수동 처리하는데, 양쪽 DB의 결정이 어긋나지 않도록 원격 상태를 먼저 확인한다.
@B 링크로 원격 DML을 하는 프로시저는 예외 처리에서 ROLLBACK을 명확히 해 둔다. 원격 쪽 실패가 로컬 트랜잭션을 반쯤 확정된 상태로 남기지 않게 한다.

@CODE
SEC05_OWN@orcl> SELECT db_link, in_transaction, update_sent FROM v$dblink;

DB_LINK      IN_ UPD
------------ --- ---
SALES_LNK    YES YES

SEC05_OWN@orcl> ALTER SESSION CLOSE DATABASE LINK sales_lnk;
ERROR:
ORA-02080: database link is in use
@END

@H3 5.7.3  분산 조회와 성능

@B 로컬 테이블과 원격 테이블을 조인하면 옵티마이저가 어느 쪽 데이터를 어느 쪽으로 보낼지 정한다. 큰 원격 테이블 전체가 네트워크로 끌려오는 계획이 나오기 쉽다.
@B DRIVING_SITE 힌트로 조인을 원격에서 수행하게 하면 원격에서 걸러진 결과만 돌아온다.
@B 원격 테이블에 대한 조건은 원격으로 전달되어 원격 인덱스를 쓴다. 조건에 로컬 함수를 쓰면 전달되지 않아 전체 행을 가져온 뒤 로컬에서 거르기도 한다.
@B 성능 문제로 링크 계정에 넓은 권한을 주거나 데이터를 통째로 복제하는 결정을 내리기 전에, 실행 계획의 REMOTE 단계부터 확인한다.

@H2 5.8  Data Pump NETWORK_LINK

@H3 5.8.1  동작 방식

@B expdp·impdp의 NETWORK_LINK 파라미터는 원격 DB의 데이터를 Database Link로 읽어 온다. 원본 서버에 접속하거나 원본 서버에 덤프 파일을 만들 필요가 없다.
@B expdp NETWORK_LINK는 원격 데이터를 읽어 작업을 수행하는 DB 서버의 디렉터리에 덤프 파일을 만든다. 원격 DB에 디스크 공간이나 디렉터리 객체가 없어도 된다.
@B impdp NETWORK_LINK는 덤프 파일 없이 원격 데이터를 바로 로컬 테이블에 넣는다. DIRECTORY는 로그 파일 용도로만 필요하다.
@B 링크는 작업을 수행하는 계정의 사설 링크나 공용 링크여야 한다. 원본 자료처럼 작업 계정이 직접 링크를 만들어 쓰는 것이 일반적이다.

@TBL
방식 | 덤프 파일 | 디스크 위치 | 쓰는 경우
expdp NETWORK_LINK | 생김 | 작업 DB 서버 | 원본 서버에 쓸 공간·권한이 없을 때, 원격 데이터를 파일로 보관
impdp NETWORK_LINK | 없음 | 로그만 | 원격 테이블을 바로 복제, 디스크 경유 없이 이관
일반 expdp + 파일 전송 + impdp | 생김 | 원본 서버 | 링크를 만들 수 없는 환경
@END

@H3 5.8.2  권한 수준 일치 — ORA-39149

@B 다른 스키마의 객체를 내보내려면 작업 계정에 DATAPUMP_EXP_FULL_DATABASE 역할이 필요하다. 가져올 때 REMAP_SCHEMA로 다른 스키마에 넣으려면 DATAPUMP_IMP_FULL_DATABASE가 필요하다.
@B 로컬 작업 계정이 이 권한을 가졌는데 링크가 접속하는 원격 계정에는 없으면 ORA-31631과 ORA-39149: cannot link privileged user to non-privileged user가 난다.
@B 권한이 낮은 원격 계정을 통로로 권한이 높은 작업을 하는 것을 Data Pump가 막는 장치다. 원격 계정에도 같은 수준의 역할을 준다.
@B 원격 계정에 FULL 역할을 주면 그 계정은 원격 DB 전체를 내보낼 수 있다. 작업이 끝나면 역할을 회수하거나 계정을 잠근다.

@H3 5.8.3  덤프 파일 암호화

@B ENCRYPTION=ALL, ENCRYPTION_MODE=PASSWORD, ENCRYPTION_PASSWORD로 덤프 파일 전체를 비밀번호로 암호화한다. Data Pump 암호화는 Advanced Security 옵션 기능이다.
@B 암호화된 덤프를 비밀번호 없이 가져오면 ORA-39002, ORA-39174: Encryption password must be supplied가 난다.
@B ENCRYPTION_MODE에는 PASSWORD 외에 TRANSPARENT(TDE 키스토어 사용), DUAL(둘 다)이 있다. TRANSPARENT는 같은 키스토어를 가진 DB에서만 풀 수 있어 다른 DB로 옮길 때는 PASSWORD나 DUAL을 쓴다.
@B 명령행에 비밀번호를 쓰면 셸 기록과 프로세스 목록에 남는다. 운영에서는 파라미터 파일을 쓰고 파일 권한을 제한하거나, ENCRYPTION_PWD_PROMPT=YES로 입력받는다.
@B impdp NETWORK_LINK는 덤프 파일이 없어 파일 암호화 대상이 없다. 대신 링크 구간의 데이터가 네트워크로 흐르므로 Oracle Net 암호화를 검토한다.

@CODE
expdp sec05_dp/sec05_dp@SALES network_link=orcl_lnk tables=scott.salgrade
      directory=sec05_dir dumpfile=sec05_sal.dmp logfile=sec05_exp.log
      encryption=all encryption_mode=password encryption_password=oracle_dp

impdp sec05_dp/sec05_dp@SALES network_link=orcl_lnk tables=scott.dept
      logfile=sec05_dir:sec05_net.log remap_schema=scott:sec05_dp exclude=grant
@END

@NOTE EXCLUDE=GRANT를 붙인 이유
원본 테이블에 걸려 있던 객체 권한(GRANT)도 덤프에 함께 들어간다. 받는 쪽 DB에 그 권한을 받은 사용자가 없으면 ORA-39083과 ORA-01917이 섞여 작업이 "completed with 1 error(s)"로 끝난다.
실습에서는 EXCLUDE=GRANT로 권한을 빼고 옮겼다. 운영 이관에서는 권한을 빼면 안 되는 경우가 많으므로 대상 DB에 사용자·역할을 먼저 만든다.
@END

@H3 5.8.4  NETWORK_LINK 운영 시 주의

@B 원격 데이터는 작업 시점에 링크로 읽힌다. 여러 테이블을 일관된 시점으로 옮기려면 FLASHBACK_SCN이나 FLASHBACK_TIME을 지정한다. 이 SCN은 원격 DB 기준이다.
@B 링크 대상 원격 계정에 준 FULL 역할은 작업 기간에만 유지한다. 원본 자료처럼 이관용 계정(linkuser)을 따로 만들고 작업 후 잠그는 방식이 안전하다.
@B 대용량 이관은 네트워크 대역폭에 묶인다. 덤프 파일 방식보다 느릴 수 있으므로 시험 이관으로 시간을 재 둔다.
@B 링크의 원격 계정으로 읽을 수 없는 행은 이관되지 않는다. 원격 테이블에 VPD 정책(7장)이 있으면 링크 계정의 시각으로 걸러진 행만 옮겨진다.
@B 버전이 다른 DB 사이에서는 VERSION 파라미터로 호환 버전을 맞춘다.

@H3 5.8.5  원본 자료와 실습 계정의 대응

@TBL
원본 자료 | 이 교안의 실습 | 역할
ORCL | orcl | 데이터 원본, 링크가 접속하는 쪽
PROD(t1 별칭) | sales(ORCL 별칭) | Data Pump 작업 수행, 링크 소유
linkuser | sec05_src | 원본 쪽 링크 계정(조회 권한 + EXP FULL 역할)
ruser | sec05_dp | 작업 계정(링크·디렉터리·EXP/IMP FULL 역할)
datapump 디렉터리 | sec05_dir | 덤프·로그 위치
hr.emp(219,136행) | scott.salgrade, scott.dept | 옮길 테이블
@END

@B 원본 자료는 암호화 덤프 가져오기에서 ORA-39174를 겪은 뒤 비밀번호를 주어 해결한다. 실습 04가 같은 흐름이며, 앞에 ORA-39149 권한 오류와 덤프 없는 impdp NETWORK_LINK를 더했다.
@B 원본 자료의 ORCL은 TDE 지갑이 열린 상태였지만 ENCRYPTION_MODE=PASSWORD는 지갑과 무관하게 동작한다.

@H2 5.9  Database Link 관련 데이터 딕셔너리 뷰

@TBL
뷰 | 내용
DBA_DB_LINKS | 모든 링크. OWNER(PUBLIC은 공용), DB_LINK, USERNAME(고정 사용자 링크의 원격 계정), HOST, CREATED, VALID
USER_DB_LINKS | 내 사설 링크. PASSWORD 열이 있으나 값은 표시되지 않음
V$DBLINK, GV$DBLINK | 현재 세션이 연 링크와 트랜잭션 상태
DBA_2PC_PENDING | 정리되지 않은 in-doubt 분산 트랜잭션
DBA_SYS_PRIVS | CREATE/ALTER/DROP (PUBLIC) DATABASE LINK 권한 보유자
GLOBAL_NAME | 이 DB의 전역 이름
@END

@CODE
SYS@orcl> SELECT owner, db_link, username, host, valid FROM dba_db_links
  2   WHERE owner = 'SEC05_OWN' ORDER BY db_link;

OWNER      DB_LINK      USERNAME     HOST     VALID
---------- ------------ ------------ -------- -----
SEC05_OWN  SALES        SEC05_RMT    SALES    YES
SEC05_OWN  SALES_CU                  SALES    YES
SEC05_OWN  SALES_LNK    SEC05_RMT    SALES    YES
@END

@B USERNAME이 비어 있는 링크는 연결 사용자 링크다. 공용 링크는 OWNER가 PUBLIC으로 나온다.
@B HOST에는 USING 문자열이 그대로 남는다. 별칭이면 별칭이, 접속 기술자면 기술자 전체가 보인다.
@B 사용자를 DROP USER ... CASCADE로 지우면 그 사용자의 사설 링크도 함께 사라진다.
@B 링크 이름에 도메인이 붙어 있으면 DB_LINK 열에도 전체 이름이 나온다. 조회 조건에 링크 이름을 쓸 때는 대문자와 도메인까지 맞춘다.
@B 원격 DB 쪽에서는 링크 계정의 DBA_USERS 정보(프로파일, 마지막 로그인 LAST_LOGIN, 계정 상태)로 링크가 실제로 쓰이는지 판단한다. 오래 쓰이지 않은 링크 계정은 잠그고 로컬 링크도 정리한다.

@BP 링크 점검 조회 모음
공용 링크 목록: `SELECT db_link, username, host FROM dba_db_links WHERE owner = 'PUBLIC'`.
고정 사용자 링크와 원격 계정: `SELECT owner, db_link, username, host FROM dba_db_links WHERE username IS NOT NULL`.
링크 생성 권한 보유자: `SELECT grantee, privilege FROM dba_sys_privs WHERE privilege LIKE '%DATABASE LINK%'`.
링크 의존 객체: `SELECT owner, name, type, referenced_link_name FROM dba_dependencies WHERE referenced_link_name IS NOT NULL`.
원격 쪽 링크 계정 권한: 원격 DB에서 DBA_SYS_PRIVS, DBA_TAB_PRIVS, DBA_ROLE_PRIVS를 링크 계정으로 조회한다.
@END

@H2 5.10  운영 시 주의점

@B 링크 점검 목록: 공용 링크 목록, 고정 사용자 링크의 원격 계정과 그 계정의 원격 권한, CREATE DATABASE LINK 권한 보유자, 링크 생성·변경 감사 여부.
@B 링크 계정은 링크별 전용 계정으로 만들고 필요한 객체 권한만 준다. 원격에서 DBA 권한을 가진 계정을 링크에 쓰면 로컬의 링크 사용자가 원격 DBA가 된다.
@B 원격 DB를 재구성하거나 서비스 이름을 바꾸면 HOST에 별칭을 쓴 링크는 tnsnames.ora만 고치면 되지만, 접속 기술자를 직접 넣은 링크는 다시 만들어야 한다.
@B 링크 계정이 원격에서 잠기면(실패 로그인 누적) 그 계정을 쓰는 모든 링크가 ORA-28000으로 멈춘다. 링크별로 원격 계정을 나누면 장애 범위가 줄어든다.
@B 링크로 대량 데이터를 옮기면 원격 DB와 네트워크에 부하가 생긴다. 반복 작업은 Data Pump NETWORK_LINK나 구체화된 뷰로 설계한다.
@B 테스트 DB에서 운영 DB를 가리키는 링크가 남아 있지 않은지 확인한다. 운영 DB를 복제해 테스트 DB를 만들면 운영 링크가 그대로 따라온다.
@B 클론 DB나 테스트 DB를 만든 직후에는 링크를 모두 점검하고, 운영 쪽을 가리키는 링크는 지우거나 비밀번호를 바꾼다.
@B 링크 계정 비밀번호를 애플리케이션 설정 파일이나 배치 스크립트에도 함께 적어 두는 경우가 많다. 비밀번호 교체 때 함께 바뀌어야 할 곳을 목록으로 관리한다.
@B 원격 DB가 업그레이드되거나 다른 서버로 옮겨지면 링크 접속 경로와 인증 방식(비밀번호 버전, SQLNET.ALLOWED_LOGON_VERSION_SERVER)을 다시 확인한다. 오래된 버전의 링크는 인증 방식 차이로 ORA-28040이 날 수 있다.

@NOTE 멀티테넌트 환경의 링크
CDB 안의 PDB끼리도 링크로 접근한다. 19c DBA_DB_LINKS의 INTRA_CDB 열은 링크가 같은 CDB 안의 다른 PDB를 가리키는지 보여 준다.
PDB를 다른 CDB로 옮기거나 복제하면 그 PDB의 링크도 함께 옮겨진다. 이 과정의 실습 DB는 non-CDB라 INTRA_CDB는 실습 대상이 아니다.
@END

@CASE 테스트 서버의 배치가 운영 데이터를 지웠다
운영 DB를 복제해 테스트 DB를 만들었다. 복제 직후 개발자가 테스트 서버에서 정리 배치를 실행했는데, 배치가 쓰는 프로시저 안에 운영 보고 DB로 가는 고정 사용자 링크가 있었다.
링크는 복제와 함께 그대로 테스트 DB로 넘어왔고, USING 별칭도 테스트 서버의 tnsnames.ora에서 운영 보고 DB로 해석됐다. 배치는 운영 보고 DB의 집계 테이블을 지웠다.
이후 복제 절차에 "DBA_DB_LINKS 전수 점검과 운영 대상 링크 삭제"를 넣고, 테스트 서버의 tnsnames.ora에서 운영 별칭을 지웠다.
@END

@H2 5.11  요약

@B Database Link는 원격 DB의 접속 정보를 로컬에 저장해 `객체@링크`로 원격 객체를 쓰게 한다. 링크 접속은 원격 입장에서 일반 클라이언트 접속과 같다.
@B 고정 사용자 링크는 저장된 원격 계정으로, 연결 사용자 링크는 세션 사용자로, 현재 사용자 링크는 전역 사용자 문맥으로 접속한다.
@B 링크 생성은 접속을 검증하지 않는다. 첫 사용에서 ORA-12154(별칭), ORA-01017(계정), ORA-02085(GLOBAL_NAMES), ORA-02019(링크 없음)로 드러난다.
@B 원격 접속 계정 확인은 USER가 아니라 `user_users@링크`로 한다. USER는 로컬에서 평가된다.
@B 원격 객체에는 GRANT할 수 없다(ORA-02021). 링크 소유자의 정의자 권한 프로시저와 로컬 뷰로 위임 범위를 정해 넘긴다.
@B 링크 비밀번호는 SYS.LINK$에 암호화되어 저장되며 DBA도 직접 읽지 못한다. 원격 비밀번호가 바뀌면 ALTER DATABASE LINK(별도 시스템 권한 필요)로 갱신한다.
@B 고정 사용자 공용 링크는 원격 계정 권한을 로컬의 모든 사용자에게 연다. CREATE DATABASE LINK 권한 보유자도 정기 점검한다.
@B 트랜잭션 중에는 링크를 닫을 수 없다(ORA-02080). Data Pump NETWORK_LINK는 양쪽 계정의 권한 수준이 같아야 하고(ORA-39149), 암호화한 덤프는 비밀번호 없이 가져올 수 없다(ORA-39174).

@H2 5.12  퀴즈

@QUIZ 문제 1
비밀번호를 잘못 적은 채 CREATE DATABASE LINK를 실행했다. 어떤 결과가 나오는가?
① 생성 시점에 ORA-01017이 난다  ② 링크는 만들어지고, 처음 사용할 때 ORA-01017과 ORA-02063이 난다  ③ 링크가 INVALID 상태로 만들어진다  ④ DBA_DB_LINKS의 VALID가 NO로 표시된다
정답 ②. CREATE DATABASE LINK는 원격에 접속해 보지 않는다. 비밀번호 오류는 첫 사용에서 원격 오류 ORA-01017과 링크 이름을 알려 주는 ORA-02063으로 드러난다. VALID 열도 YES로 남아 있어 판단 근거가 되지 않는다.
@END

@QUIZ 문제 2
고정 사용자 링크 sales_lnk(원격 계정 SEC05_RMT)를 소유한 SEC05_OWN이 `SELECT USER FROM dual@sales_lnk`를 실행했다. 결과는?
① SEC05_RMT  ② SYS  ③ ORA-02019  ④ SEC05_OWN
정답 ④. USER 함수는 로컬에서 평가되어 로컬 세션 사용자를 돌려준다. 원격에서 실제로 접속한 계정은 `SELECT username FROM user_users@sales_lnk`처럼 원격 뷰를 조회해 확인한다.
@END

@QUIZ 문제 3
링크 소유자가 HR에게 원격 테이블 조회를 허용하려고 `GRANT SELECT ON emp@sales_lnk TO hr`를 실행했다. 결과와 올바른 대안은?
① 성공한다  ② ORA-02019, 공용 링크로 바꾼다  ③ ORA-02021, 원격 테이블을 감싼 로컬 뷰를 만들어 그 뷰에 권한을 준다  ④ ORA-01031, HR에게 CREATE DATABASE LINK를 준다
정답 ③. GRANT는 DDL이라 원격 객체에 실행할 수 없다. 링크 소유자가 로컬 뷰를 만들고 뷰에 SELECT를 주면, HR은 링크를 직접 쓰지 않고 뷰가 정한 범위의 원격 데이터만 본다.
@END

@QUIZ 문제 4
원격 계정의 비밀번호를 바꾼 뒤 링크 소유자가 ALTER DATABASE LINK로 새 비밀번호를 넣으려 했으나 ORA-01031이 났다. 원인은?
① 링크 소유자에게 ALTER DATABASE LINK 시스템 권한이 없다  ② 연결 사용자 링크라서 바꿀 수 없다  ③ 원격 계정이 잠겼다  ④ GLOBAL_NAMES가 TRUE다
정답 ①. ALTER DATABASE LINK는 자기 링크라도 같은 이름의 시스템 권한이 필요하다(공용 링크는 ALTER PUBLIC DATABASE LINK). 권한을 받은 뒤 비밀번호만 바꾸면 링크를 쓰는 뷰·프로시저가 INVALID를 거치지 않고 그대로 동작한다.
@END

@QUIZ 문제 5
Data Pump 작업 계정(DATAPUMP_EXP_FULL_DATABASE 보유)이 NETWORK_LINK로 다른 스키마 테이블을 내보내다가 ORA-39149가 났다. 조치로 알맞은 것은?
① 덤프 파일 이름을 바꾼다  ② 링크가 접속하는 원격 계정에도 DATAPUMP_EXP_FULL_DATABASE를 준다  ③ ENCRYPTION_PASSWORD를 준다  ④ GLOBAL_NAMES를 TRUE로 바꾼다
정답 ②. ORA-39149는 권한이 높은 로컬 사용자가 권한이 낮은 원격 사용자를 통해 작업하려 할 때 난다. 원격 계정에도 같은 수준의 역할을 줘야 하며, 작업 후에는 회수한다.
@END

@QUIZ 문제 6
링크 연결 관리에 대한 설명으로 틀린 것은?
① 세션이 링크를 쓰면 세션이 끝날 때까지 원격 연결이 유지된다  ② OPEN_LINKS는 세션당 동시 링크 연결 수의 상한이다  ③ 원격 UPDATE 후 커밋하기 전에도 ALTER SESSION CLOSE DATABASE LINK로 닫을 수 있다  ④ V$DBLINK는 현재 세션의 링크만 보여 준다
정답 ③. 트랜잭션이 진행 중인 링크를 닫으면 ORA-02080(database link is in use)이 난다. COMMIT이나 ROLLBACK으로 트랜잭션을 끝낸 뒤에 닫을 수 있다.
@END

@H2 5.13  실습 개요

@P 실습은 oel7v9 서버의 두 인스턴스 orcl(로컬)과 sales(원격)로 진행한다. 원본 자료의 clone DB(c1)와 PROD의 역할을 sales가 맡는다. 계정 이름은 모두 SEC05로 시작하며 05에서 양쪽 모두 철거한다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
5장_실습_01_링크생성과링크유형 | 고정·연결 사용자 링크, 생성 시 미검증과 ORA-01017·ORA-12154, GLOBAL_NAMES와 ORA-02085, USER 함수의 로컬 평가, DBA_DB_LINKS | 5.2, 5.3, 5.4
5장_실습_02_정의자권한으로원격DML위임 | 링크를 품은 프로시저와 역할로 원격 DML 위임, ORA-02019, ORA-02021과 로컬 뷰·동의어 | 5.5
5장_실습_03_링크자격증명보호와공용링크 | SYS.LINK$의 PASSWORDX, DBA의 LINK$ 접근 차단, 원격 비밀번호 교체와 ALTER DATABASE LINK 권한, CURRENT_USER 링크, 공용 링크 | 5.3.2, 5.6
5장_실습_04_DataPump_NETWORK_LINK | NETWORK_LINK 내보내기·가져오기, ORA-39149, 덤프 암호화와 ORA-39174, 덤프 없는 impdp | 5.8
5장_실습_05_링크세션관리와원복 | V$DBLINK, ORA-02080과 링크 닫기, 양쪽 DB 철거 확인 | 5.7, 5.9
@END
