@H1 제2장  프록시 인증 (Proxy Authentication)

@H2 2.1  학습 목표

@P 웹 애플리케이션은 대개 하나의 데이터베이스 계정으로 수많은 사용자의 요청을 처리한다. 프록시 인증은 이 구조를 유지하면서도 데이터베이스가 "지금 누구를 위해 일하는가"를 알게 해 준다.

@B 다계층 환경에서 공용 계정 하나로 접속할 때 생기는 권한·감사 문제를 설명할 수 있다.
@B 프록시 사용자와 대상 사용자(클라이언트 사용자)의 관계, 프록시 세션의 사용자·권한·역할이 어떻게 정해지는지 설명할 수 있다.
@B `ALTER USER ... GRANT CONNECT THROUGH` 문으로 프록시 허용을 구성하고 WITH ROLE, WITH NO ROLES, AUTHENTICATION REQUIRED 조건을 목적에 맞게 지정할 수 있다.
@B 프록시 접속 실패 시 나오는 ORA-01017, ORA-01045, ORA-28150, ORA-28000의 원인을 구분할 수 있다.
@B USERENV 컨텍스트, V$SESSION_CONNECT_INFO, 통합 감사 기록의 DBPROXY_USERNAME으로 프록시 세션을 식별할 수 있다.
@B 프록시 경유 작업을 감사할 때 정책을 누구에게 걸어야 하는지 판단할 수 있다.

@H2 2.2  다계층 환경의 사용자 식별 문제

@H3 2.2.1  공용 계정 방식의 한계

@B 3계층 구조에서 브라우저 사용자는 애플리케이션 서버에 로그인하고, 애플리케이션 서버가 데이터베이스에 접속한다. 데이터베이스는 애플리케이션 서버만 상대한다.
@B 가장 단순한 구성은 애플리케이션 서버가 APP_USER 같은 공용 계정 하나로 접속하는 것이다. 연결 풀을 만들기 쉽고 계정 관리가 간단하다.
@B 대가는 세 가지다. 공용 계정이 모든 사용자에게 필요한 권한의 합을 가져야 하고, 데이터베이스 감사 기록에는 모두 APP_USER로 남고, VPD 같은 사용자별 정책을 데이터베이스가 적용할 근거가 없다.
@B 애플리케이션 서버가 침해되면 공격자는 공용 계정의 모든 권한을 그대로 얻는다. 최소 권한 원칙을 지키기 어렵다.
@B 반대로 최종 사용자마다 데이터베이스 계정을 두고 각자 비밀번호로 직접 접속하게 하면, 애플리케이션 서버가 모든 사용자의 비밀번호를 알아야 하고 연결 풀도 쓸 수 없다.

@H3 2.2.2  프록시 인증이 푸는 방식

@B 프록시 인증은 애플리케이션 서버 계정(프록시 사용자)이 자기 자격 증명으로 인증받은 뒤, 미리 허용된 대상 사용자로서 세션을 여는 방식이다.
@B 세션의 사용자와 권한은 대상 사용자의 것이 된다. 공용 계정에 권한을 몰아줄 필요가 없다.
@B 데이터베이스는 세션마다 실제 사용자와 거쳐 온 프록시 계정을 모두 알고 있다. 감사 기록과 정책 함수가 두 정보를 함께 쓸 수 있다.
@B 대상 사용자의 비밀번호는 기본적으로 필요하지 않다. 애플리케이션 서버가 최종 사용자의 데이터베이스 비밀번호를 보관하지 않아도 된다.
@B 대상 사용자가 데이터베이스 계정이어야 한다는 점은 전제 조건이다. 데이터베이스 계정이 없는 웹 사용자는 클라이언트 식별자(CLIENT_IDENTIFIER, 6장)로 구분한다.

@TBL
방식 | 세션 사용자 | 권한 | 감사 기록의 사용자 | 비밀번호 관리
공용 계정 | APP_USER | 공용 계정의 권한 합계 | 모두 APP_USER | 공용 계정 1개
사용자별 직접 접속 | 각 사용자 | 각 사용자 | 각 사용자 | 애플리케이션이 모든 비밀번호 보관
프록시 인증 | 대상 사용자 | 대상 사용자 | 대상 사용자 + 프록시 계정 | 프록시 계정 1개
클라이언트 식별자 | APP_USER | 공용 계정 | APP_USER + CLIENT_ID | 공용 계정 1개
@END

@H3 2.2.3  프록시 인증이 맞지 않는 경우

@B 최종 사용자가 수만 명이고 데이터베이스 계정을 만들 수 없는 인터넷 서비스에는 맞지 않는다. 계정 생성·잠금·퇴사 처리를 데이터베이스에서 감당할 수 없다.
@B 애플리케이션이 데이터베이스 권한 대신 자체 권한 모델로 모든 판단을 하고 있다면, 데이터베이스 계정을 사용자마다 만들어도 실제 효과가 작다.
@B 이런 환경에서는 공용 계정과 CLIENT_IDENTIFIER, 애플리케이션 컨텍스트(6장)로 사용자를 표시하는 쪽이 현실적이다.
@B 사내 업무 시스템처럼 사용자 수가 정해져 있고 데이터베이스 권한·감사로 통제해야 하는 환경에서 프록시 인증이 가장 효과가 크다.

@H2 2.3  프록시 세션의 동작

@H3 2.3.1  두 계정의 역할

@B 프록시 사용자(proxy user)는 애플리케이션 서버가 접속에 쓰는 데이터베이스 계정이다. 원본 자료의 APPSUSER, 실습의 PRX_APP이 여기에 해당한다.
@B 대상 사용자(client user, target user)는 실제 업무를 하는 사용자다. 프록시 세션의 세션 사용자가 된다.
@B 프록시 허용은 대상 사용자 쪽 속성이다. `ALTER USER 대상 GRANT CONNECT THROUGH 프록시`는 "대상 사용자가 이 프록시를 통한 접속을 허용한다"로 읽는다.
@B 한 대상 사용자가 여러 프록시를 허용할 수 있고, 한 프록시가 여러 대상 사용자로 접속할 수 있다. 허용은 쌍 단위로 관리된다.

@TBL
용어 | 이 장에서의 뜻 | 실습 이름
프록시 사용자(proxy user) | 애플리케이션 서버가 인증에 쓰는 계정 | PRX_APP
대상 사용자(client user) | 프록시 세션의 세션 사용자가 되는 계정 | PRX_USER1~3
프록시 허용 | 대상 사용자에 건 CONNECT THROUGH 속성 | DBA_PROXIES 행
프록시 세션 | 프록시 인증으로 열린 대상 사용자 세션 | AUTHENTICATION_TYPE=PROXY
@END

@H3 2.3.2  인증과 세션 생성 순서

@TBL
단계 | 일어나는 일
1 | 클라이언트가 프록시 계정과 그 비밀번호, 대상 사용자 이름을 보냄
2 | 데이터베이스가 프록시 계정의 비밀번호를 검증
3 | 대상 사용자에게 이 프록시에 대한 CONNECT THROUGH 허용이 있는지 확인
4 | AUTHENTICATION REQUIRED이면 대상 사용자의 자격 증명도 검증
5 | 대상 사용자의 CREATE SESSION 권한 확인
6 | 대상 사용자로 세션을 만들고, 허용된 역할 범위 안에서 기본 역할을 켬
@END

@B 2단계에서 실패하면 프록시 계정 비밀번호 오류, 3단계에서 실패하면 허용 없음이다. 두 경우 모두 ORA-01017이 나와 메시지로는 구분되지 않는다.
@B 5단계의 CREATE SESSION은 대상 사용자의 권한이다. 프록시 계정의 CREATE SESSION은 2단계에서만 의미가 있다.
@B 프록시 계정이 잠겨 있으면 2단계에서 ORA-28000으로 막힌다. 그 계정을 거치는 모든 대상 사용자 접속이 함께 막힌다.

@CODE
SQL> CONNECT prx_app[prx_user1]/prx_app
Connected.
PRX_USER1@orcl> SHOW USER
USER is "PRX_USER1"
@END

@B SQL*Plus에서는 `프록시[대상]/프록시비밀번호` 형식으로 접속한다. 대괄호 안이 대상 사용자다.
@B 실제 애플리케이션은 OCI의 세션 풀이나 JDBC의 프록시 세션 API를 쓴다. 프록시 계정으로 물리 연결을 맺어 두고, 요청이 올 때마다 그 연결 위에 대상 사용자의 경량 세션을 연다.
@B 경량 세션은 물리 연결을 새로 맺지 않으므로 사용자별 세션을 만드는 비용이 작다. 연결 풀의 장점과 사용자 식별을 함께 얻는 구조다.

@NOTE 경량 세션과 세션 상태
연결 풀에서 프록시 세션을 열고 닫을 때 물리 연결은 그대로 재사용된다. 패키지 전역 변수, 임시 테이블, 애플리케이션 컨텍스트 같은 세션 상태가 다음 사용자에게 넘어가지 않는지 확인해야 한다.
로컬 애플리케이션 컨텍스트는 프록시 세션마다 새로 시작한다. 연결 풀 전체에서 값을 공유해야 한다면 6장의 전역 접근 컨텍스트를 쓴다.
@END

@H3 2.3.3  프록시 세션의 사용자 정보

@B 프록시 세션에서 `USER`, `SESSION_USER`, `CURRENT_USER`는 모두 대상 사용자다.
@B `SYS_CONTEXT('USERENV', 'PROXY_USER')`는 프록시 계정 이름을 돌려준다. 일반 접속에서는 NULL이다.
@B `AUTHENTICATION_METHOD`는 일반 비밀번호 접속에서 PASSWORD, 비밀번호 없는 프록시 세션에서 NONE으로 나왔다. 대상 사용자가 그 세션에서 스스로 인증받지 않았다는 표시다.
@B 이 값들은 정책 함수와 감사에 쓸 수 있다. "프록시를 거친 세션에서만 특정 데이터 공개" 같은 조건을 PROXY_USER로 표현한다.

@TBL
USERENV 속성 | 일반 접속(PRX_APP) | 프록시 세션(PRX_APP[PRX_USER1])
SESSION_USER | PRX_APP | PRX_USER1
PROXY_USER | (NULL) | PRX_APP
AUTHENTICATED_IDENTITY | PRX_APP | PRX_USER1
AUTHENTICATION_METHOD | PASSWORD | NONE
@END

@H3 2.3.4  클라이언트 API의 프록시 세션

@B JDBC에서는 프록시 계정으로 연결을 연 뒤 `OracleConnection.openProxySession`으로 대상 사용자의 프록시 세션을 연다. 세션을 닫으면 물리 연결은 풀로 돌아간다.
@B 대상 사용자 비밀번호가 필요한 허용(AUTHENTICATION REQUIRED)이면 같은 호출의 속성에 대상 사용자 비밀번호를 함께 넣는다.
@B 역할 제한은 세션을 열 때 PROXY_ROLES 속성으로 더 좁힐 수 있다. 데이터베이스 쪽 WITH ROLE 목록이 상한이고, 클라이언트는 그 안에서만 고를 수 있다.
@B OCI는 세션 풀(OCISessionPool)과 `OCISessionGet`에서 프록시 자격 증명을 지정하는 방식으로 같은 일을 한다.

@CODE
// JDBC 예: 프록시 계정 연결 위에 대상 사용자 세션 열기
OracleConnection conn = (OracleConnection) ds.getConnection("prx_app", pw);
Properties prop = new Properties();
prop.put(OracleConnection.PROXY_USER_NAME, "prx_user1");
conn.openProxySession(OracleConnection.PROXYTYPE_USER_NAME, prop);
// ... 업무 SQL은 PRX_USER1 권한으로 실행 ...
conn.close(OracleConnection.PROXY_SESSION);
@END

@B 애플리케이션 서버는 요청마다 프록시 세션을 열고 닫는다. 세션이 바뀔 때 이전 사용자의 패키지 변수나 컨텍스트 값이 남지 않는지 애플리케이션 쪽에서도 확인한다.
@B SQL*Plus의 `프록시[대상]` 형식은 시험과 장애 분석용이다. 동작을 손으로 확인할 때 쓴다.

@H2 2.4  프록시 허용 구성

@H3 2.4.1  프록시 계정 만들기

@B 프록시 계정은 접속만 할 수 있으면 된다. `CREATE SESSION` 외의 권한과 역할을 주지 않는다.
@B 프록시 계정에 테이블 권한이 있으면 프록시 계정으로 직접 접속해 그 권한을 쓸 수 있다. 애플리케이션 서버 설정 파일에서 비밀번호가 새면 그대로 노출된다.
@B 프록시 계정의 비밀번호는 애플리케이션 서버 설정에 들어가므로 1장의 Secure External Password Store 같은 지갑에 보관하는 것이 좋다.
@B 프록시 계정에는 업무용 객체를 두지 않는다. 스키마가 비어 있는 계정이 안전하다.

@CODE
SYS@orcl> CREATE USER prx_app IDENTIFIED BY prx_app;
SYS@orcl> GRANT CREATE SESSION TO prx_app;
@END

@B 애플리케이션마다 프록시 계정을 따로 둔다. 인사 시스템과 영업 시스템이 같은 프록시 계정을 쓰면 감사 기록의 DBPROXY_USERNAME으로 두 경로를 구분할 수 없다.
@B 프록시 계정 이름에 애플리케이션과 용도를 드러낸다(예: HRAPP_PRX, SALESAPP_PRX). 장애 때 감사 기록만 보고 어느 서버의 접속인지 알 수 있다.
@B 같은 애플리케이션이라도 배치 서버와 온라인 서버를 나누면 배치 경로만 따로 잠그거나 감사할 수 있다.

@H3 2.4.2  GRANT CONNECT THROUGH

@B 허용은 `ALTER USER` 문의 proxy 절로 건다. 실행하려면 ALTER USER 시스템 권한이 필요하다.
@B 기본 형식은 `ALTER USER 대상 GRANT CONNECT THROUGH 프록시`다. 조건을 붙이지 않으면 대상 사용자의 모든 역할을 쓸 수 있고 대상 사용자 비밀번호를 요구하지 않는다.
@B 허용을 회수할 때는 `ALTER USER 대상 REVOKE CONNECT THROUGH 프록시`다.
@B 같은 쌍에 GRANT를 다시 실행하면 조건이 새 값으로 바뀐다. 조건을 고치려고 먼저 REVOKE할 필요가 없다.
@B `GRANT CONNECT THROUGH ENTERPRISE USERS`는 Oracle Internet Directory의 엔터프라이즈 사용자가 대신 접속하도록 허용한다. 디렉터리 쪽 권한 부여가 함께 필요하며 이 과정에서는 다루지 않는다.

@CODE
ALTER USER prx_user1 GRANT CONNECT THROUGH prx_app;
ALTER USER prx_user2 GRANT CONNECT THROUGH prx_app WITH ROLE prx_role, connect;
ALTER USER prx_user2 GRANT CONNECT THROUGH prx_app WITH ROLE ALL EXCEPT dba;
ALTER USER prx_user2 GRANT CONNECT THROUGH prx_app WITH NO ROLES;
ALTER USER prx_user3 GRANT CONNECT THROUGH prx_app AUTHENTICATION REQUIRED;
ALTER USER prx_user1 REVOKE CONNECT THROUGH prx_app;
@END

@NOTE 허용이 없어도 ORA-01017
프록시 허용이 없는 대상 사용자로 접속하면 ORA-01017: invalid username/password가 나온다. 프록시 계정 비밀번호를 틀렸을 때와 같은 메시지다.
접속 시도자에게 대상 사용자의 존재나 허용 상태를 알려 주지 않으려는 동작이다. 비밀번호가 확실히 맞는데 ORA-01017이 나면 DBA_PROXIES에서 해당 쌍이 있는지부터 확인한다.
@END

@H3 2.4.3  허용 후 시험 순서

@B 허용을 건 직후 DBA_PROXIES로 쌍과 조건을 확인한다. AUTHENTICATION과 ROLE 열이 의도와 같은지 본다.
@B SQL*Plus로 `프록시[대상]` 접속을 시험하고, 세션 안에서 SESSION_USER, PROXY_USER, SESSION_ROLES를 조회한다.
@B 업무에 필요한 SQL 하나를 실제로 실행해 권한이 충분한지 확인한다. 역할을 제한했다면 필요한 권한이 그 역할 안에 있는지가 핵심 확인 항목이다.
@B 마지막으로 프록시 계정 자신으로 접속해 업무 테이블에 접근할 수 없는지도 시험한다. 프록시 계정에 권한이 남아 있으면 여기서 드러난다.

@CODE
SYS@orcl> SELECT proxy, client, authentication, authorization_constraint, role
  2         FROM dba_proxies WHERE client = 'PRX_USER1';
SQL> CONNECT prx_app[prx_user1]/prx_app
PRX_USER1@orcl> SELECT SYS_CONTEXT('USERENV','PROXY_USER') FROM dual;
PRX_USER1@orcl> SELECT role FROM session_roles;
@END

@NOTE 프록시 허용을 거는 권한
GRANT CONNECT THROUGH는 ALTER USER 문의 일부라 ALTER USER 시스템 권한이 있어야 실행할 수 있다. 사용자가 자기 계정에 스스로 프록시 허용을 거는 것은 이 권한 없이는 불가능하다.
ALTER USER 권한은 비밀번호 변경, 계정 잠금 해제까지 할 수 있는 강한 권한이다. 프록시 허용 관리를 계정 관리자에게 맡길 때 이 권한의 범위를 함께 고려한다.
프록시 허용의 생성·변경은 통합 감사의 ALTER USER 액션으로 기록된다. 기본 정책 ORA_SECURECONFIG가 이 액션을 포함한다.
@END

@H3 2.4.4  매뉴얼의 프록시 계정 지침

@P Security Guide는 프록시 계정을 만들 때의 지침을 따로 둔다. 문서 기준으로 정리한다.

@B 프록시 계정에는 CREATE SESSION만 주고 다른 권한은 주지 않는다. 연결 중에 쓰이는 권한은 프록시 계정이 아닌 접속하는 사용자의 것이어야 한다.
@B 여러 사용자가 같은 프록시 계정을 거쳐 접속하므로 프록시 계정 비밀번호는 특히 강하게 정한다.
@B 네트워크 도청을 막기 위해 Oracle의 강한 인증 기능을 검토하라고 권한다. 프록시 계정 비밀번호가 오가는 경로이므로 TLS(11장) 같은 암호화 접속이 해당된다.
@B 프록시 세션은 대상 사용자가 직접 받은 권한을 모두 갖는다. WITH ROLE이 줄이는 것은 역할뿐이므로, 직접 부여된 강한 권한은 허용 조건으로 막을 수 없다.
@B 사용자 이름과 프록시 조합은 250자를 넘을 수 없다.
@B 프록시 계정을 만들려면 CREATE USER, 허용을 걸려면 ALTER USER 시스템 권한이 필요하다. Database Vault가 켜진 DB에서는 DV_ACCTMGR 역할이 계정 생성을 맡는다.
@B 같은 문서는 Database Vault의 operations control이 켜진 환경에서 공통 사용자가 PDB의 로컬 사용자로 프록시 접속할 수 없다고 적는다. 운영 DBA의 공통 계정으로 PDB 사용자 세션을 여는 방식은 그런 환경에서 막힌다.

@H2 2.5  역할 제한

@H3 2.5.1  WITH ROLE, ALL EXCEPT, NO ROLES

@B 대상 사용자가 가진 역할이 모두 애플리케이션에 필요한 것은 아니다. 사용자가 다른 업무용으로 받은 강한 역할이 애플리케이션 경로로 켜지지 않게 막는다.
@B `WITH ROLE 역할목록`은 나열한 역할만 켤 수 있게 한다. 목록에는 대상 사용자에게 부여된 역할만 쓸 수 있다.
@B `WITH ROLE ALL EXCEPT 역할목록`은 나열한 역할을 뺀 나머지를 허용한다.
@B `WITH NO ROLES`는 어떤 역할도 켤 수 없게 한다. 직접 받은 시스템·객체 권한만 남는다.
@B 허용된 역할 중 대상 사용자의 기본 역할(DEFAULT ROLE)인 것은 로그인 시 자동으로 켜진다.
@B 비밀번호로 보호된 역할과 Secure Application Role(3장)도 프록시 세션에서 쓰려면 WITH ROLE 목록에 넣어야 한다. 목록에 없으면 올바른 비밀번호나 패키지 호출로도 켤 수 없다.

@TBL
조건 | DBA_PROXIES.AUTHORIZATION_CONSTRAINT | 프록시 세션에서 켤 수 있는 역할
조건 없음 | PROXY MAY ACTIVATE ALL CLIENT ROLES | 대상 사용자의 모든 역할
WITH ROLE r1, r2 | PROXY MAY ACTIVATE ROLE (역할마다 한 행) | r1, r2
WITH ROLE ALL EXCEPT r1 | PROXY MAY NOT ACTIVATE ROLE | r1을 뺀 나머지
WITH NO ROLES | NO CLIENT ROLES MAY BE ACTIVATED | 없음
@END

@H3 2.5.2  역할 제한과 CREATE SESSION

@B 로그인 권한도 권한이다. 대상 사용자가 CREATE SESSION을 CONNECT 역할로만 받았다면, WITH ROLE 목록에서 CONNECT를 빼는 순간 로그인 권한도 사라진다.
@B 이때 프록시 허용은 정상이지만 접속은 ORA-01045: user lacks CREATE SESSION privilege로 거부된다.
@B 해결은 두 가지다. WITH ROLE 목록에 CONNECT를 넣거나, 대상 사용자에게 CREATE SESSION을 직접 부여한다.
@B WITH NO ROLES를 쓰려면 CREATE SESSION을 반드시 직접 권한으로 줘야 한다.
@B CONNECT 역할은 19c에서 CREATE SESSION과 SET CONTAINER만 담고 있다. 오래된 시스템에서 만든 사용자 정의 역할이 CREATE SESSION을 품고 있는 경우도 있으니 `DBA_SYS_PRIVS`로 실제 출처를 확인한다.

@CASE 역할을 줄였더니 애플리케이션 로그인이 전부 실패한다
보안 점검에서 애플리케이션 사용자들이 프록시 경로로 RESOURCE 역할까지 켜고 있다는 지적이 나왔다. 담당자는 모든 사용자의 허용을 `WITH ROLE app_role`로 바꿨다.
변경 직후 애플리케이션 로그인이 일제히 실패했고, 애플리케이션 로그에는 ORA-01045가 찍혀 있었다. 사용자 계정의 CREATE SESSION이 CONNECT 역할에서만 오고 있었기 때문이다.
허용을 `WITH ROLE app_role, connect`로 다시 GRANT해 즉시 복구했다. 이후 계정 생성 표준을 바꿔 CREATE SESSION은 직접 권한으로 주고, 프록시 허용에는 업무 역할만 나열하도록 정리했다.
@END

@H3 2.5.3  SET ROLE의 범위

@B 프록시 세션 안에서 SET ROLE로 역할을 켜는 것도 허용 범위 안에서만 된다.
@B `SET ROLE ALL`은 오류 없이 끝나지만, 켜지는 역할은 WITH ROLE 목록에 있는 것뿐이다. 실습에서도 세션 역할은 CONNECT, PRX_ROLE 두 개에서 바뀌지 않았다.
@B WITH NO ROLES 세션에서 대상 사용자의 역할을 지정해 켜면 ORA-01924: role not granted or does not exist가 난다. 역할이 부여돼 있어도 프록시 세션에서는 없는 역할처럼 취급된다.

@H3 2.5.4  역할 설계 예

@P 대상 사용자 한 명이 여러 업무에 걸쳐 역할을 받는 경우가 많다. 애플리케이션 경로에서 쓸 역할만 WITH ROLE로 묶어 두면, 같은 사용자가 다른 도구로 접속했을 때의 권한과 애플리케이션 경로의 권한을 분리할 수 있다.

@TBL
사용자 역할 | 용도 | 프록시 허용에 포함
CONNECT | 로그인 | 포함(또는 CREATE SESSION 직접 부여)
HR_CLERK | 인사 화면 조회·입력 | 포함
HR_REPORT | 보고서 도구 전용 | 제외
DATA_FIX | 데이터 보정 작업용 | 제외
@END

@B 이렇게 두면 HR 화면을 거친 세션에서는 HR_CLERK 권한만 쓰인다. 보정 작업은 보고서 도구나 별도 경로로 직접 접속할 때만 가능하다.
@B 반대로 애플리케이션 경로에서만 써야 하는 강한 권한은 3장의 Secure Application Role로 만든다. 패키지가 PROXY_USER 값을 확인해 프록시 경로일 때만 역할을 켜게 한다.
@B Secure Application Role을 프록시 세션에서 쓰려면 WITH ROLE 목록에 그 역할을 넣어야 한다. 목록에 없으면 패키지가 SET ROLE을 실행해도 켜지지 않는다.

@H3 2.5.5  기본 역할과의 관계

@B 프록시 세션이 열릴 때 켜지는 역할은 "허용 범위 안에 있으면서 대상 사용자의 기본 역할인 것"이다.
@B 허용 범위에 있어도 기본 역할이 아니면 로그인 때 켜지지 않는다. 애플리케이션이 필요한 시점에 SET ROLE로 켠다.
@B 대상 사용자의 기본 역할 설정(`ALTER USER ... DEFAULT ROLE`)을 바꾸면 프록시 세션의 초기 역할도 함께 바뀐다. 허용 조건을 바꾸지 않았는데 동작이 달라졌다면 기본 역할 변경 이력을 확인한다.

@H3 2.5.6  비밀번호로 보호된 역할

@B `IDENTIFIED BY`로 비밀번호를 건 역할도 프록시 세션에서 쓸 수 있다. 조건은 WITH ROLE 목록에 포함돼 있는 것이다.
@B 조건 없는 허용(WITH ROLE ALL이 기본)에는 이런 역할도 포함된다. SET ROLE 역할 IDENTIFIED BY 비밀번호로 켠다.
@B WITH NO ROLES이거나 목록에서 빠져 있으면 비밀번호가 맞아도 켤 수 없다. SQL Language Reference 19c의 proxy 절 설명에 명시된 동작이다.

@H2 2.6  AUTHENTICATION REQUIRED

@H3 2.6.1  대상 사용자 자격 증명 요구

@B 기본 프록시 허용은 대상 사용자의 비밀번호를 묻지 않는다. 프록시 계정을 신뢰한다는 전제다.
@B `AUTHENTICATION REQUIRED`를 붙이면 프록시가 대상 사용자의 자격 증명(비밀번호)도 함께 제시해야 한다. DBA_PROXIES의 AUTHENTICATION 열이 YES가 된다.
@B 프록시 계정이 침해돼도 대상 사용자 비밀번호를 모르면 그 사용자로 접속할 수 없다. 민감한 업무 계정에 쓴다.
@B 조건을 만족하지 못하면 ORA-28150: proxy not authorized to connect as client가 난다.
@B SQL*Plus의 `프록시[대상]/비밀번호` 형식은 프록시 비밀번호만 넘기므로 AUTHENTICATION REQUIRED 허용으로는 접속할 수 없다. 대상 사용자 비밀번호를 함께 넘기는 것은 OCI·JDBC 프록시 세션 API에서 한다.

@H3 2.6.2  원본 자료의 AUTHENTICATED USING

@B 원본 자료는 인증 옵션으로 `AUTHENTICATED USING PASSWORD`, `DISTINGUISHED NAME`, `CERTIFICATE`를 소개한다. 예전 릴리스의 문법이다.
@B 19c SQL Language Reference는 AUTHENTICATED USING 절을 디프리케이트로 분류한다. PASSWORD는 AUTHENTICATION REQUIRED로 변환되고, DISTINGUISHED NAME과 CERTIFICATE는 이 절을 생략한 것과 같다.
@B 19.3에서 `AUTHENTICATED USING PASSWORD`로 허용하면 오류 없이 받아들이고 DBA_PROXIES의 AUTHENTICATION이 YES로 기록된다. 새로 작성하는 스크립트는 AUTHENTICATION REQUIRED를 쓴다.

@NOTE 인증서·DN 기반 프록시
대상 사용자가 인증서로 식별되는 환경(11장의 TLS 인증서 사용자 등)에서도 프록시 허용 자체는 같은 GRANT CONNECT THROUGH 문으로 건다.
어떤 자격 증명을 넘길지는 클라이언트 API가 정한다. 데이터베이스 쪽 문법에서 인증서나 DN을 지정하던 옛 절은 19c에서 의미가 없다.
@END

@H3 2.6.3  언제 인증을 요구하는가

@B 프록시 계정을 신뢰할 수 있고 사용자 인증은 애플리케이션 서버가 책임지는 구조라면 기본 허용(인증 없음)이 맞다. 대부분의 웹 애플리케이션이 여기에 해당한다.
@B 프록시 계정 하나가 뚫리면 허용된 모든 사용자로 접속할 수 있다는 점은 기본 허용의 위험이다. 그래서 프록시 계정의 비밀번호 보관과 접속 경로 제한이 중요하다.
@B 결재·자금 이체처럼 사용자가 그 순간 본인임을 다시 증명해야 하는 업무라면 AUTHENTICATION REQUIRED를 쓴다. 애플리케이션이 사용자에게 데이터베이스 비밀번호를 받아 넘기는 구조가 전제다.
@B AUTHENTICATION REQUIRED 허용으로 접속하는 애플리케이션은 대상 사용자 비밀번호를 받아 전달하는 동안 메모리와 로그에 남기지 않도록 주의한다. 비밀번호가 애플리케이션 로그에 찍히면 이 옵션을 쓴 의미가 사라진다.
@B 같은 사용자에 대해 프록시마다 조건을 달리 줄 수 있다. 온라인 서버 프록시는 인증 없이, 외부 연계 서버 프록시는 인증 요구로 허용하는 식이다.

@CASE 원본 자료대로 했는데 접속이 안 된다
교육 담당자가 예전 자료를 따라 `ALTER USER user1 GRANT CONNECT THROUGH appsuser AUTHENTICATED USING PASSWORD`로 허용을 걸었다. 문장은 오류 없이 실행됐지만 SQL*Plus에서 `appsuser[user1]/appsuser`로 접속하자 ORA-28150이 났다.
DBA_PROXIES를 보니 AUTHENTICATION 열이 YES였다. 19c가 옛 문법의 PASSWORD 옵션을 AUTHENTICATION REQUIRED로 바꿔 저장한 결과였다. 이 자료가 쓰인 시점의 의도는 "프록시 계정 비밀번호로 인증"이었지만, 현재 의미는 "대상 사용자 비밀번호도 요구"다.
조건 없이 `GRANT CONNECT THROUGH appsuser`로 다시 실행하자 AUTHENTICATION이 NO로 바뀌고 접속됐다. 옛 문법이 남은 스크립트는 19c 문법으로 정리했다.
@END

@H3 2.6.4  오류로 단계 짚기

@B ORA-01017은 2.3.2절 순서의 앞 단계(프록시 계정 인증, 허용 존재)에서 나온다.
@B ORA-28150은 허용은 있지만 대상 사용자 인증 조건을 만족하지 못했을 때 나온다. 허용이 존재한다는 증거이기도 하다.
@B ORA-01045는 인증과 허용을 모두 통과한 뒤 로그인 권한 검사에서 나온다. 가장 마지막 단계의 실패다.
@B 같은 화면에서 사용자마다 다른 오류가 나면 이 순서를 기준으로 원인을 좁힌다.

@H2 2.7  프록시 세션 식별

@H3 2.7.1  세션 안에서

@B 현재 세션이 프록시 세션인지는 `SYS_CONTEXT('USERENV', 'PROXY_USER')`가 NULL인지로 판단한다.
@B `PROXY_USERID`는 프록시 계정의 사용자 ID를 돌려준다. 계정 이름이 바뀌어도 변하지 않는 값이 필요할 때 쓴다.
@B 애플리케이션이 이 값을 로그에 함께 남기면 데이터베이스 감사 기록과 애플리케이션 로그를 대조하기 쉽다.

@H3 2.7.2  다른 세션에서

@B DBA는 `V$SESSION_CONNECT_INFO.AUTHENTICATION_TYPE`이 PROXY인 행으로 프록시 세션을 고른다. SID로 V$SESSION과 조인한다.
@B V$SESSION.USERNAME에는 대상 사용자가 나온다. 프록시 계정 이름은 V$SESSION에 따로 나오지 않는다.
@B 경량 세션을 쓰는 연결 풀 환경에서는 한 물리 연결에 여러 세션이 차례로 올라온다. 순간 조회 결과보다 감사 기록이 추적에 더 적합하다.

@CODE
SELECT s.sid, s.username, i.authentication_type, i.osuser
  FROM v$session s JOIN v$session_connect_info i ON s.sid = i.sid
 WHERE i.authentication_type = 'PROXY';
@END

@H3 2.7.3  관련 USERENV 속성

@TBL
속성 | 프록시 세션에서의 값
SESSION_USER | 대상 사용자
CURRENT_USER | 대상 사용자(정의자 권한 프로시저 안에서는 소유자)
PROXY_USER | 프록시 계정 이름
PROXY_USERID | 프록시 계정의 사용자 ID
AUTHENTICATED_IDENTITY | 대상 사용자(실습 01 확인)
AUTHENTICATION_METHOD | NONE(비밀번호 없는 프록시, 실습 01 확인)
CLIENT_IDENTIFIER | 애플리케이션이 설정한 값(설정 안 하면 NULL)
@END

@B 정책 함수나 감사 조건에서 "누가 했는가"는 SESSION_USER, "어느 경로로 왔는가"는 PROXY_USER로 판단한다.
@B CURRENT_USER는 정의자 권한 프로시저 안에서 소유자로 바뀐다. 사용자 판별에 CURRENT_USER를 쓰면 프로시저 호출 여부에 따라 결과가 달라진다.

@H2 2.8  프록시 경유 작업의 감사

@H3 2.8.1  통합 감사 기록의 DBPROXY_USERNAME

@B 19c의 통합 감사(Unified Auditing) 기록 UNIFIED_AUDIT_TRAIL에는 DBUSERNAME과 DBPROXY_USERNAME이 함께 남는다.
@B 프록시 세션의 작업은 DBUSERNAME이 대상 사용자, DBPROXY_USERNAME이 프록시 계정이다. 같은 사용자가 직접 접속해 한 작업은 DBPROXY_USERNAME이 비어 있다.
@B 이 구분으로 "애플리케이션을 거친 작업"과 "도구로 직접 접속한 작업"을 나눠 볼 수 있다. 직접 접속 작업이 있어서는 안 되는 업무 계정이라면 그 자체로 점검 대상이다.
@B orcl은 mixed 감사 모드(19c 기본)라 통합 감사 정책과 전통 감사가 함께 동작한다. 감사 모드와 기록 관리는 13장에서 다룬다.

@CODE
CREATE AUDIT POLICY prx_dml_pol
  ACTIONS CREATE TABLE, INSERT, UPDATE, DELETE, SELECT ON scott.dept;
AUDIT POLICY prx_dml_pol BY prx_user1;

SELECT dbusername, dbproxy_username, action_name, object_name
  FROM unified_audit_trail
 WHERE unified_audit_policies = 'PRX_DML_POL';
@END

@H3 2.8.2  정책은 대상 사용자에게

@B `AUDIT POLICY ... BY 사용자`의 사용자는 세션 사용자 기준이다. 프록시 세션의 세션 사용자는 대상 사용자다.
@B 정책을 프록시 계정에 걸면(`BY prx_app`) 프록시 세션의 작업이 기록되지 않는다. 실습에서 정책 대상을 prx_app으로 옮긴 뒤 프록시 세션에서 INSERT한 작업은 기록이 늘지 않았다.
@B 프록시 경유 작업만 골라 감사하려면 정책을 대상 사용자에 걸고 조회할 때 DBPROXY_USERNAME으로 거른다. 통합 감사 정책의 WHEN 조건에 `SYS_CONTEXT('USERENV','PROXY_USER')`를 써서 기록 단계에서 거를 수도 있다.
@B 실패한 프록시 로그인은 기본 정책 ORA_LOGON_FAILURES가 기록한다. RETURN_CODE(1017, 1045, 28150 등)와 DBPROXY_USERNAME이 함께 남아 어느 애플리케이션 서버에서 시도했는지 보인다.

@NOTE 원본 자료의 전통 감사 문법
원본 자료는 `AUDIT SELECT TABLE ... BY appsuser ON BEHALF OF user1`과 DBA_AUDIT_TRAIL의 PROXY_SESSIONID 조인으로 프록시 작업을 추적한다. 전통 감사 문법으로, mixed 모드의 19c에서도 동작은 한다.
19c에서 전통 감사는 디프리케이트 상태이고 통합 감사가 권장 방식이다. 이 교안의 실습은 통합 감사 정책과 DBPROXY_USERNAME으로 같은 목적을 이룬다.
@END

@BP 프록시 환경의 감사 설계
감사 정책은 대상 사용자 또는 대상 사용자들이 받은 역할 기준으로 건다.
조회할 때는 DBUSERNAME과 DBPROXY_USERNAME을 함께 보고, 직접 접속 작업(DBPROXY_USERNAME이 비어 있는 행)을 따로 점검한다.
기본 정책 ORA_LOGON_FAILURES를 끄지 않는다. 프록시 허용 문제와 무차별 대입 시도가 모두 여기에 남는다.
애플리케이션이 CLIENT_IDENTIFIER도 설정하면 감사 기록의 CLIENT_ID 열로 웹 사용자까지 추적할 수 있다.
@END

@H3 2.8.3  조회 예

@P 실습 04에서 같은 PRX_USER1이 프록시 세션과 직접 세션에서 작업한 결과는 다음과 같이 기록됐다.

@CODE
DBUSERNAME DBPROXY_US ACTION_NAME   OBJECT_NAM RETURN_CODE
---------- ---------- ------------- ---------- -----------
PRX_USER1  PRX_APP    CREATE TABLE  PRX_TEST             0
PRX_USER1  PRX_APP    INSERT        PRX_TEST             0
PRX_USER1  PRX_APP    SELECT        DEPT              2004
PRX_USER1  PRX_APP    SELECT        DEPT                 0
PRX_USER1             INSERT        PRX_TEST             0
@END

@B 마지막 행은 PRX_USER1이 SQL*Plus로 직접 접속해 한 INSERT다. 애플리케이션 경로로만 작업해야 하는 계정이라면 이런 행이 점검 대상이 된다.
@B 세 번째 행은 SELECT 권한을 받기 전의 조회다. 사용자는 ORA-00942를 봤지만 감사 기록의 RETURN_CODE는 2004(ORA-02004 security violation)다. 객체의 존재를 사용자에게 숨기면서 감사에는 실제 사유를 남기는 동작이다. 권한 없는 접근 시도를 찾을 때는 RETURN_CODE 2004를 조건으로 쓴다.
@B 실패한 프록시 로그인은 같은 뷰에서 ACTION_NAME='LOGON'과 RETURN_CODE로 찾는다.

@CODE
SELECT dbusername, dbproxy_username, action_name, return_code
  FROM unified_audit_trail
 WHERE action_name = 'LOGON' AND return_code <> 0
   AND dbproxy_username IS NOT NULL
 ORDER BY event_timestamp;
@END

@H3 2.8.4  WHEN 조건으로 경로별 기록

@B 통합 감사 정책에는 WHEN 조건을 붙일 수 있다. 조건이 참인 세션의 작업만 기록한다.
@B 직접 접속만 기록하려면 PROXY_USER가 NULL인 경우로 조건을 건다. 반대로 프록시 경로의 작업만 남기는 정책도 같은 방식으로 만든다.
@B EVALUATE PER SESSION은 조건을 세션당 한 번만 평가한다. 프록시 여부는 세션 중에 바뀌지 않으므로 이 옵션이 맞다.

@CODE
CREATE AUDIT POLICY direct_dml_pol
  ACTIONS INSERT, UPDATE, DELETE
  WHEN 'SYS_CONTEXT(''USERENV'', ''PROXY_USER'') IS NULL'
  EVALUATE PER SESSION;
AUDIT POLICY direct_dml_pol BY prx_user1;
@END

@H3 2.8.5  전통 감사 방식과 비교

@TBL
항목 | 전통 감사(원본 자료) | 통합 감사(19c 권장)
설정 문법 | AUDIT ... BY proxy ON BEHALF OF client | CREATE AUDIT POLICY + AUDIT POLICY ... BY client
기록 위치 | DBA_AUDIT_TRAIL(SYS.AUD$) | UNIFIED_AUDIT_TRAIL
프록시 식별 | PROXY_SESSIONID를 프록시 세션 기록과 조인 | DBPROXY_USERNAME 열에 직접 기록
19c 상태 | 디프리케이트(mixed 모드에서 동작) | 권장
@END

@B 원본 자료의 조회는 프록시 인증 기록(PROXY AUTHENTICATION ONLY)과 작업 기록을 세션 ID로 이어 붙여야 했다. 통합 감사에서는 한 행에 두 사용자가 함께 남아 조인이 필요 없다.
@B pure unified 모드로 전환하면 전통 감사 문장은 더 이상 기록을 남기지 않는다. 기존 스크립트를 통합 감사 정책으로 옮겨 두면 전환 때 공백이 생기지 않는다.

@H2 2.9  프록시 계정과 허용의 관리

@H3 2.9.1  잠금과 회수

@B 프록시 계정을 잠그면(`ACCOUNT LOCK`) 그 계정을 거치는 모든 대상 사용자 접속이 ORA-28000으로 막힌다. 대상 사용자의 직접 접속은 영향을 받지 않는다.
@B 애플리케이션 서버가 침해됐다고 의심될 때 프록시 계정 하나를 잠그면 그 경로 전체를 즉시 차단할 수 있다.
@B 개별 사용자의 애플리케이션 접근만 막을 때는 `REVOKE CONNECT THROUGH`를 쓴다. 회수 후 프록시 접속은 ORA-01017로 거부된다.
@B 대상 사용자 계정을 잠그면 직접 접속과 프록시 접속이 모두 막힌다. 퇴사자 처리처럼 사용자 자체를 막을 때 쓴다.

@TBL
조치 | 프록시 경유 접속 | 대상 사용자 직접 접속 | 같은 프록시의 다른 사용자
프록시 계정 잠금 | ORA-28000 | 가능 | 모두 차단
REVOKE CONNECT THROUGH | ORA-01017 | 가능 | 영향 없음
대상 사용자 잠금 | 차단 | ORA-28000 | 영향 없음
@END

@H3 2.9.2  오류 정리

@TBL
오류 | 상황 | 확인할 것
ORA-01017 | 프록시 계정 비밀번호 오류 또는 프록시 허용 없음 | 비밀번호, DBA_PROXIES의 쌍
ORA-01045 | 대상 사용자에게 CREATE SESSION 없음(역할 제한으로 사라진 경우 포함) | DBA_SYS_PRIVS, WITH ROLE 목록
ORA-28150 | AUTHENTICATION REQUIRED인데 대상 사용자 자격 증명 없음 | DBA_PROXIES.AUTHENTICATION
ORA-28000 | 프록시 계정 또는 대상 사용자가 잠김 | DBA_USERS.ACCOUNT_STATUS
ORA-01924 | 허용 범위 밖의 역할을 SET ROLE | DBA_PROXIES의 ROLE 행
ORA-46361 | BY 사용자로 켠 감사 정책을 BY 없이 NOAUDIT한 뒤 DROP | AUDIT_UNIFIED_ENABLED_POLICIES의 ENTITY_NAME
@END

@B 실습 05에서 `NOAUDIT POLICY prx_dml_pol`은 `Noaudit succeeded.`로 끝났지만 정책은 그대로 켜져 있었다. AUDIT_UNIFIED_ENABLED_POLICIES에 ENABLED_OPTION이 BY USER, ENTITY_NAME이 PRX_APP인 행이 남아 DROP이 ORA-46361로 거부됐다.
@B `NOAUDIT POLICY prx_dml_pol BY prx_app`처럼 켤 때와 같은 대상을 지정하자 DROP이 성공했다. 정책 대상을 여러 번 옮긴 경우에는 이 뷰에서 남은 대상을 먼저 확인한다.

@H3 2.9.3  계정 생명주기

@B 신규 사용자를 만들 때 프록시 허용을 함께 거는 절차를 표준화한다. 허용이 빠지면 사용자는 ORA-01017만 보고 원인을 알기 어렵다.
@B 퇴사·부서 이동 때는 대상 사용자 잠금 또는 허용 회수를 계정 처리 절차에 넣는다. 프록시 허용은 사용자 권한 목록 조회에 나오지 않아 놓치기 쉽다.
@B 프록시 계정 비밀번호를 바꿀 때는 그 계정을 쓰는 모든 애플리케이션 서버의 설정을 함께 바꿔야 한다. 19c의 점진적 비밀번호 롤오버(19.12 이후) 같은 기능을 검토하거나, 바꾸는 시간을 정해 일괄 처리한다.

@H3 2.9.4  멀티테넌트 환경

@B CDB에서 프록시 허용은 PDB 안의 사용자 사이에 건다. 로컬 사용자끼리는 그 PDB에서만 유효하다.
@B 공통 사용자(C##)를 프록시나 대상으로 쓸 수도 있지만, 허용은 허용을 건 컨테이너에서만 의미가 있다. 애플리케이션이 접속하는 PDB에서 허용을 확인한다.
@B 이 과정의 실습 DB는 non-CDB라 해당하지 않는다.

@BP 프록시 계정 비밀번호 보관
프록시 계정 비밀번호는 애플리케이션 서버 설정 파일에 평문으로 두지 않는다. 1장의 Secure External Password Store로 지갑에 넣고 `/@별칭` 형식으로 접속하게 한다.
지갑 파일의 권한은 애플리케이션 서버 실행 계정만 읽을 수 있게 둔다.
프록시 계정에는 접속 시간대·접속 IP 제한(프로필, 로그온 트리거, 리스너 접근 제어)을 함께 건다. 다른 서버에서 프록시 계정으로 접속하는 시도는 그 자체로 이상 징후다.
@END

@CASE 프록시 계정 비밀번호가 설정 파일과 함께 유출됐다
개발 서버의 소스 저장소에 운영 애플리케이션 설정 파일이 실수로 올라갔고, 그 안에 프록시 계정 비밀번호가 평문으로 들어 있었다.
허용 목록을 확인하니 이 프록시 계정은 직원 300여 명의 계정으로 접속할 수 있었다. 유출된 비밀번호 하나로 그 모두를 대신할 수 있는 상태였다.
즉시 프록시 계정을 잠가 경로를 막고, 비밀번호를 바꾼 뒤 지갑 방식으로 설정을 옮겨 다시 열었다. 잠근 시점 이후의 ORA-28000 로그온 실패 기록에서 외부 IP의 접속 시도가 확인돼 추가 조사로 이어졌다.
@END

@H3 2.9.5  정기 점검 조회

@B 프록시로 쓰이는 계정에 CREATE SESSION 외의 권한이나 역할이 붙어 있는지 확인한다.

@CODE
SELECT p.proxy, sp.privilege
  FROM (SELECT DISTINCT proxy FROM dba_proxies) p
  JOIN dba_sys_privs sp ON sp.grantee = p.proxy
 WHERE sp.privilege <> 'CREATE SESSION'
UNION ALL
SELECT p.proxy, rp.granted_role
  FROM (SELECT DISTINCT proxy FROM dba_proxies) p
  JOIN dba_role_privs rp ON rp.grantee = p.proxy;
@END

@B 조건 없는 허용을 받은 대상 사용자 중 DBA 같은 강한 역할을 가진 사용자를 찾는다. 프록시 경로로 그 역할이 켜질 수 있다.

@CODE
SELECT x.proxy, x.client, r.granted_role
  FROM dba_proxies x JOIN dba_role_privs r ON r.grantee = x.client
 WHERE x.authorization_constraint = 'PROXY MAY ACTIVATE ALL CLIENT ROLES'
   AND r.granted_role IN ('DBA', 'IMP_FULL_DATABASE', 'EXP_FULL_DATABASE');
@END

@B 잠긴 계정이나 만료된 계정이 대상 사용자로 남아 있는 허용은 정리 대상이다. DBA_USERS.ACCOUNT_STATUS와 조인해 찾는다.

@H3 2.9.6  지갑과 함께 쓰는 두 가지 형식

@B Security Guide는 프록시 계정 비밀번호가 새는 것이 걱정되면 Secure External Password Store를 함께 쓰라고 권하고, 배치 파일 실행 같은 상황에 알맞다고 적는다.
@B 문서의 예는 `sqlplus [preston]/@db_alias`다. 지갑에는 db_alias에 대한 프록시 계정의 자격 증명을 두고, 대상 사용자는 접속할 때 대괄호로 지정한다. 이 형식은 문서 기준이며 이 장의 실습에서는 시험하지 않았다.
@B 1장 실습 04는 다른 방식을 썼다. 지갑의 사용자 이름 자리에 `seps_app[seps_rpt]`를 저장하고 `/@seps_proxy`로 접속해, SESSION_USER가 SEPS_RPT, PROXY_USER가 SEPS_APP인 세션이 열렸다.

@TBL
형식 | 지갑에 저장하는 사용자 이름 | 대상 사용자 지정 | 별칭 수
문서 예 [대상]/@별칭 | 프록시 계정 | 접속 명령의 대괄호 | 별칭 하나로 여러 대상
1장 실습 04 /@별칭 | 프록시[대상] | 지갑 항목에 고정 | 대상 사용자마다 별칭
@END

@B 대상 사용자를 지갑에 고정하면 스크립트가 다른 사용자로 접속할 여지가 없다. 대괄호 형식은 별칭 관리가 단순한 대신, 지갑을 쓸 수 있는 OS 사용자가 허용된 모든 대상 사용자로 접속할 수 있다.

@H2 2.10  프록시 인증 관련 데이터 딕셔너리 뷰

@TBL
뷰 | 내용
DBA_PROXIES | 프록시·대상 쌍, AUTHENTICATION(YES/NO), AUTHORIZATION_CONSTRAINT, 허용 역할(ROLE), PROXY_AUTHORITY
PROXY_USERS | 같은 관계의 요약. FLAGS 열에 역할 제한 방식
USER_PROXIES | 현재 사용자가 대상인 프록시 허용
V$SESSION_CONNECT_INFO | 세션별 AUTHENTICATION_TYPE(PROXY 등), 클라이언트 정보
UNIFIED_AUDIT_TRAIL | DBUSERNAME, DBPROXY_USERNAME, CLIENT_ID 등 감사 기록
@END

@B DBA_PROXIES는 WITH ROLE로 나열한 역할마다 한 행을 만든다. 쌍의 개수를 셀 때는 PROXY, CLIENT로 DISTINCT한다.
@B PROXY_AUTHORITY는 허용 주체를 나타낸다. 데이터베이스 사용자 간 허용은 DATABASE, 디렉터리 엔터프라이즈 사용자 허용은 DIRECTORY다.

@CODE
SELECT proxy, client, authentication, authorization_constraint, role
  FROM dba_proxies
 ORDER BY proxy, client;
@END

@H2 2.11  다른 보안 기능과의 연계

@H3 2.11.1  VPD 정책 함수

@B 프록시 인증으로 세션 사용자가 실제 사용자가 되면 7장의 VPD 정책 함수가 SESSION_USER로 사용자별 행을 거를 수 있다. 공용 계정 구조에서는 불가능하던 일이다.
@B PROXY_USER를 함께 보면 "애플리케이션을 거친 세션에서만 데이터를 보여 준다" 같은 조건도 만들 수 있다. 같은 사용자가 SQL*Plus로 직접 접속하면 0건을 돌려준다.

@CODE
CREATE OR REPLACE FUNCTION app_only (
  p_schema IN VARCHAR2,
  p_object IN VARCHAR2)
RETURN VARCHAR2
AS
BEGIN
  IF SYS_CONTEXT('USERENV', 'PROXY_USER') = 'PRX_APP' THEN
    RETURN 'owner_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')';
  END IF;
  RETURN '1=2';
END;
/
@END

@H3 2.11.2  클라이언트 식별자

@B 최종 사용자가 데이터베이스 계정을 갖지 않는 웹 서비스에서는 프록시 인증을 쓸 수 없다. 이때는 애플리케이션이 `DBMS_SESSION.SET_IDENTIFIER`로 웹 사용자 ID를 세션에 기록한다.
@B 이 값은 `SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER')`로 읽히고 감사 기록의 CLIENT_ID 열에 남는다. 전역 접근 컨텍스트(6장)와 함께 쓰면 연결 풀에서도 사용자별 값을 관리할 수 있다.
@B 두 방식을 함께 쓰는 구성도 흔하다. 부서 단위 데이터베이스 계정으로 프록시 세션을 열고, 그 안에서 개인 사번을 CLIENT_IDENTIFIER로 기록한다.
@B CLIENT_IDENTIFIER는 애플리케이션이 설정하는 값이라 데이터베이스가 진위를 검증하지 않는다. 권한 판단의 단독 근거로 쓰지 않는다.

@H3 2.11.3  Data Redaction과 감사

@B 8장의 Data Redaction 정책 식에도 PROXY_USER를 쓸 수 있다. 애플리케이션 경로에서는 마스킹된 값만, 승인된 분석 도구 경로에서는 원본을 보여 주는 식이다.
@B 12장의 Fine-Grained Auditing 조건과 핸들러에서도 같은 USERENV 값을 쓸 수 있다. 프록시 경로와 직접 접속 경로에 다른 감사 수준을 적용한다.

@H2 2.12  도입 절차

@TBL
단계 | 작업 | 확인할 것
1 | 애플리케이션별 프록시 계정 생성 | CREATE SESSION만 부여, 비밀번호는 지갑에 보관
2 | 대상 사용자의 CREATE SESSION 출처 확인 | 역할로만 받았다면 직접 부여 검토
3 | 프록시 허용(GRANT CONNECT THROUGH) | WITH ROLE 목록, AUTHENTICATION REQUIRED 여부
4 | 애플리케이션 연결 코드 변경 | JDBC·OCI 프록시 세션 API, 세션 반환 처리
5 | 감사 정책 정비 | 대상 사용자 기준 정책, DBPROXY_USERNAME 조회
6 | VPD·Redaction 정책 점검 | SESSION_USER·PROXY_USER 기준으로 동작하는지
7 | 운영 절차 반영 | 계정 생성·퇴사 처리에 허용 관리 포함, 프록시 계정 잠금 절차
@END

@B 공용 계정에서 프록시 인증으로 옮길 때는 공용 계정의 권한을 대상 사용자들의 역할로 나눠 옮기는 작업이 가장 크다. 권한 분석(Privilege Analysis)으로 실제 쓰는 권한을 먼저 확인하면 범위를 줄일 수 있다.
@B 전환 직후 한동안은 공용 계정과 프록시 경로가 함께 쓰인다. 감사 기록에서 공용 계정 접속이 사라지는 것을 확인한 뒤 공용 계정의 권한을 회수한다.

@CASE 공용 계정에서 프록시 인증으로 옮긴 뒤 감사 기록이 달라졌다
고객 정보 조회 화면이 공용 계정 APP_USER로 동작하던 시스템에서, 누가 어떤 고객을 조회했는지 추적할 수 없다는 감사 지적을 받았다.
직원마다 데이터베이스 계정을 만들고 APP_USER를 프록시 계정으로 바꿔 `GRANT CONNECT THROUGH app_user WITH ROLE cust_view`로 허용했다. 애플리케이션은 로그인한 직원의 계정으로 프록시 세션을 열도록 수정했다.
전환 후 감사 기록의 DBUSERNAME에는 직원 계정이, DBPROXY_USERNAME에는 APP_USER가 남았다. 같은 직원이 보고서 도구로 직접 접속한 기록은 DBPROXY_USERNAME이 비어 있어 따로 점검할 수 있게 됐다.
@END

@H2 2.13  운영 시 주의점

@B 프록시 계정에는 CREATE SESSION만 준다. 정기 점검에서 프록시 계정의 권한과 역할이 늘어나지 않았는지 확인한다.
@B 강한 역할(DBA 등)을 가진 사용자에게 조건 없는 프록시 허용을 주지 않는다. 필요하면 WITH ROLE로 업무 역할만 허용한다.
@B 프록시 허용을 바꾼 뒤에는 실제 애플리케이션 경로로 로그인을 시험한다. ORA-01045 같은 문제는 허용을 바꾼 직후에만 드러난다.
@B VPD 정책 함수(7장)는 SESSION_USER가 대상 사용자라는 전제로 짠다. 공용 계정 시절의 함수를 그대로 두면 프록시 전환 후 정책이 엉뚱하게 동작할 수 있다.
@B 감사 정책은 대상 사용자 기준으로 걸고, DBPROXY_USERNAME이 빈 행을 별도로 점검한다.
@B 프록시 계정의 프로필에는 비밀번호 만료를 신중하게 건다. 만료되면 그 계정을 쓰는 애플리케이션 전체의 로그인이 한꺼번에 실패한다. 만료 대신 정해진 주기의 계획된 교체를 운영 절차로 둔다.
@B 프록시 계정에 FAILED_LOGIN_ATTEMPTS 제한을 걸면 잘못된 설정을 가진 서버 하나가 계정을 잠가 전체 서비스를 멈출 수 있다. 잠금 기준과 경보를 함께 설계한다.
@B 실습이 끝나면 프록시 허용, 사용자, 역할, 통합 감사 정책을 모두 지운다. 감사 정책은 BY로 켠 대상을 모두 NOAUDIT해야 삭제된다(ORA-46361).

@H2 2.14  요약

@B 프록시 인증은 프록시 계정이 자기 자격 증명으로 인증받고 허용된 대상 사용자로 세션을 여는 방식이다. 세션 사용자와 권한은 대상 사용자의 것이다.
@B 허용은 `ALTER USER 대상 GRANT CONNECT THROUGH 프록시`로 대상 사용자에 건다. 허용이 없으면 ORA-01017이 난다.
@B WITH ROLE, ALL EXCEPT, NO ROLES로 켤 수 있는 역할의 상한을 정한다. CREATE SESSION이 역할로만 들어오면 역할 제한 때문에 ORA-01045가 날 수 있다.
@B AUTHENTICATION REQUIRED는 대상 사용자 자격 증명을 요구한다(없으면 ORA-28150). AUTHENTICATED USING PASSWORD는 이 절로 변환되는 옛 문법이다.
@B 프록시 세션은 USERENV의 PROXY_USER, V$SESSION_CONNECT_INFO의 AUTHENTICATION_TYPE=PROXY, 감사 기록의 DBPROXY_USERNAME으로 식별한다.
@B 프록시 경유 작업의 감사 정책은 대상 사용자에 건다. 프록시 계정에 건 정책은 프록시 세션 작업을 기록하지 않는다.
@B 프록시 계정 잠금은 그 경로 전체를, REVOKE CONNECT THROUGH는 한 쌍을 차단한다.

@H2 2.15  퀴즈

@QUIZ 문제 1
APPSRV 계정으로 SCOTT를 대신해 접속하도록 허용하는 올바른 문장은?
① ALTER USER appsrv GRANT CONNECT THROUGH scott  ② GRANT PROXY ON scott TO appsrv  ③ ALTER USER scott GRANT CONNECT THROUGH appsrv  ④ GRANT CONNECT THROUGH appsrv TO scott
정답 ③. 프록시 허용은 대상 사용자의 속성이다. ALTER USER 대상 GRANT CONNECT THROUGH 프록시 형식으로 건다.
@END

@QUIZ 문제 2
프록시 세션에서 SYS_CONTEXT('USERENV','SESSION_USER')와 SYS_CONTEXT('USERENV','PROXY_USER')가 돌려주는 값의 조합으로 옳은 것은?
① 프록시 계정, 대상 사용자  ② 대상 사용자, 프록시 계정  ③ 대상 사용자, NULL  ④ 프록시 계정, NULL
정답 ②. 프록시 세션의 세션 사용자는 대상 사용자이고, PROXY_USER에 거쳐 온 프록시 계정이 남는다. 일반 접속에서는 PROXY_USER가 NULL이다.
@END

@QUIZ 문제 3
대상 사용자가 CREATE SESSION을 CONNECT 역할로만 받았다. 허용을 WITH ROLE app_role로 바꾼 뒤 프록시 접속을 시도하면?
① 정상 접속된다  ② ORA-01017  ③ ORA-28150  ④ ORA-01045
정답 ④. WITH ROLE 목록에 CONNECT가 없으면 그 역할로 들어오던 CREATE SESSION도 쓸 수 없어 로그인 권한 부족으로 거부된다. CONNECT를 목록에 넣거나 CREATE SESSION을 직접 부여한다.
@END

@QUIZ 문제 4
AUTHENTICATION REQUIRED로 허용된 쌍에 SQL*Plus에서 proxy[client]/proxy_password로 접속했다. 결과는?
① ORA-28150이 난다  ② 대상 사용자 비밀번호를 묻는 프롬프트가 뜬다  ③ 정상 접속된다  ④ ORA-01045가 난다
정답 ①. 이 형식은 프록시 비밀번호만 넘기므로 대상 사용자 자격 증명을 요구하는 조건을 만족하지 못한다. 대상 사용자 비밀번호를 함께 넘기는 것은 OCI·JDBC 프록시 세션 API의 몫이다.
@END

@QUIZ 문제 5
프록시 경유로 일어난 USER1의 DML을 통합 감사로 기록하려 한다. 가장 알맞은 설정은?
① AUDIT POLICY p BY appsrv  ② AUDIT POLICY p BY user1  ③ AUDIT POLICY p EXCEPT user1  ④ 프록시 세션은 통합 감사로 기록할 수 없다
정답 ②. 정책의 BY 사용자는 세션 사용자 기준이고, 프록시 세션의 세션 사용자는 USER1이다. 기록에는 DBPROXY_USERNAME으로 프록시 계정이 함께 남는다. 프록시 계정에 건 정책은 이 작업을 기록하지 않는다.
@END

@QUIZ 문제 6
애플리케이션 서버 하나가 침해된 것으로 보인다. 그 서버를 거치는 모든 사용자 접속을 가장 빠르게 막는 방법은?
① 모든 대상 사용자에서 REVOKE CONNECT THROUGH  ② 모든 대상 사용자 계정 잠금  ③ 그 서버가 쓰는 프록시 계정 잠금  ④ 감사 정책 추가
정답 ③. 프록시 계정을 잠그면 그 계정을 거치는 모든 프록시 접속이 ORA-28000으로 막히고, 대상 사용자의 다른 경로 접속에는 영향이 없다. 개별 REVOKE는 시간이 걸리고, 사용자 잠금은 정상 경로까지 막는다.
@END

@H2 2.16  실습 개요

@P 실습은 oel7v9 서버의 orcl 데이터베이스(19.3, non-CDB)에서 진행한다. 01에서 만든 프록시 계정과 사용자를 04까지 이어 쓰고, 05 마지막에 감사 정책까지 모두 철거한다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
2장_실습_01_프록시계정과대상사용자 | GRANT CONNECT THROUGH 전후 접속, 허용 없을 때 ORA-01017, 프록시 세션의 USERENV 값과 역할 | 2.3, 2.4
2장_실습_02_WITH_ROLE로역할제한 | WITH ROLE과 ORA-01045, CREATE SESSION의 출처, SET ROLE ALL 범위, WITH NO ROLES와 ORA-01924 | 2.5
2장_실습_03_AUTHENTICATION_REQUIRED | AUTHENTICATION REQUIRED와 ORA-28150, AUTHENTICATED USING PASSWORD의 19c 처리 | 2.6
2장_실습_04_감사기록으로실제사용자추적 | 통합 감사 정책, DBPROXY_USERNAME, 정책 대상(대상 사용자 vs 프록시 계정), 실패 로그인 기록 | 2.8
2장_실습_05_프록시관리와철거 | DBA_PROXIES·PROXY_USERS, V$SESSION_CONNECT_INFO, 프록시 계정 잠금 ORA-28000, REVOKE, ORA-46361과 원복 | 2.7, 2.9, 2.10
@END
