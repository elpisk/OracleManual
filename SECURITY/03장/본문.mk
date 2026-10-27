@H1 제3장  Secure Application Role

@H2 3.1  학습 목표

@P 권한을 사용자에게 주면 사용자는 어떤 도구로 접속하든 그 권한을 쓴다. Secure Application Role은 권한이 켜지는 조건을 데이터베이스 안의 PL/SQL 코드로 정해, 정해진 경로를 거친 세션에서만 권한이 살아나게 한다.

@B 시스템 권한, 객체 권한, 역할의 관계를 설명하고 부여 상태와 세션 활성 상태를 딕셔너리 뷰로 구분해 조회할 수 있다.
@B 역할의 인증 방식(없음, 비밀번호, 외부, 전역, 애플리케이션)을 구분하고 Secure Application Role이 필요한 상황을 설명할 수 있다.
@B `CREATE ROLE ... IDENTIFIED USING`으로 역할을 만들고 활성화 프로시저를 작성할 수 있다.
@B 활성화 프로시저가 호출자 권한이어야 하는 이유와 정의자 권한일 때의 오류(ORA-06565)를 설명할 수 있다.
@B 직접 SET ROLE, 직접 부여, 기본 역할 지정, LOGON 트리거가 이 역할에 어떻게 작용하는지 말할 수 있다.
@B 검사 조건에 쓸 세션 속성을 고르고, 클라이언트가 바꿀 수 있는 값의 한계를 설명할 수 있다.
@B DBA_APPLICATION_ROLES 등으로 역할과 활성화 프로시저의 연결을 점검할 수 있다.

@H2 3.2  권한과 역할의 기초

@H3 3.2.1  시스템 권한과 객체 권한

@B 시스템 권한은 데이터베이스 전체에 대한 작업 권한이다. `CREATE SESSION`, `CREATE TABLE`, `SELECT ANY TABLE`, `UNLIMITED TABLESPACE` 등이 있으며 19c에는 이백 개가 넘는다.
@B 객체 권한은 특정 객체에 대한 권한이다. `SELECT ON scott.emp`, `EXECUTE ON sys.dbms_rls`처럼 객체 이름이 붙는다.
@B ANY가 붙은 시스템 권한은 다른 스키마의 모든 객체에 영향을 준다. 업무 계정에 ANY 권한이 있으면 객체 권한으로 짠 통제가 의미를 잃는다.
@B 시스템 권한은 `WITH ADMIN OPTION`, 객체 권한은 `WITH GRANT OPTION`으로 재부여 권한까지 줄 수 있다. 재부여 권한은 권한이 어디까지 퍼질지 통제하기 어렵게 만든다.
@B 객체 소유자는 자기 객체에 대한 모든 권한을 갖는다. 소유자 계정으로 업무 접속을 하면 권한 통제가 없는 것과 같다.

@H3 3.2.2  역할

@B 역할(role)은 권한을 묶은 이름이다. 권한을 역할에 주고, 역할을 사용자에게 준다.
@B 역할은 다른 역할을 포함할 수 있다. 19c의 DBA 역할은 시스템 권한 이백여 개를 직접 갖고 다른 역할 열여덟 개를 포함한다.
@B 역할을 통해 받은 권한은 세션에서 역할이 켜져 있을 때만 쓸 수 있다. 직접 받은 권한은 항상 살아 있다.
@B 정의자 권한 PL/SQL(기본 방식) 안에서는 역할로 받은 권한이 꺼진다. 프로시저 안에서 쓰는 객체 권한은 소유자에게 직접 부여되어 있어야 한다.

@TBL
역할 | 19c 구성 | 참고
CONNECT | CREATE SESSION, SET CONTAINER | 10gR2 이전에는 CREATE TABLE 등 8개
RESOURCE | CREATE TABLE·PROCEDURE·SEQUENCE·TRIGGER·TYPE·CLUSTER·INDEXTYPE·OPERATOR, SODA_APP 역할 | 12c부터 UNLIMITED TABLESPACE를 함께 주지 않음
DBA | 시스템 권한 이백여 개 + 역할 열여덟 개 | 업무 계정에 주지 않음
@END

@NOTE 12c 이후 RESOURCE와 UNLIMITED TABLESPACE
예전 버전에서는 RESOURCE 역할을 부여하면 UNLIMITED TABLESPACE 시스템 권한이 사용자에게 직접 함께 부여됐다. 12c부터는 이 동작이 없어졌다.
19c에서 RESOURCE만 받은 사용자가 테이블에 데이터를 넣으면 테이블스페이스 할당량 오류가 난다. 사용자별로 `ALTER USER ... QUOTA`를 주는 쪽이 권장 방식이다. 업그레이드한 DB에는 예전 방식으로 받은 UNLIMITED TABLESPACE가 남아 있을 수 있어 점검 대상이 된다.
@END

@B PUBLIC은 모든 사용자가 자동으로 갖는 특수한 대상이다. PUBLIC에 준 권한은 개별 사용자의 부여 목록에는 나타나지 않으면서 모든 세션에서 쓰인다. 권한 점검 때 PUBLIC을 따로 조회한다.

@H3 3.2.3  부여 상태와 세션 상태를 보는 뷰

@TBL
뷰 | 보여 주는 것 | 조회 권한
DBA_SYS_PRIVS | 사용자·역할에 직접 부여된 시스템 권한 | SELECT ANY DICTIONARY 등
DBA_TAB_PRIVS | 객체 권한(테이블·뷰·프로시저·디렉터리 등) | 〃
DBA_ROLE_PRIVS | 사용자·역할에 부여된 역할, ADMIN_OPTION, DEFAULT_ROLE | 〃
ROLE_ROLE_PRIVS, ROLE_SYS_PRIVS, ROLE_TAB_PRIVS | 역할 안에 든 역할·권한 | 내가 가진 역할 범위
USER_SYS_PRIVS, USER_TAB_PRIVS, USER_ROLE_PRIVS | 내 부여 상태 | 누구나
SESSION_ROLES, SESSION_PRIVS | 지금 세션에 켜진 역할·권한 | 누구나
@END

@B 일반 사용자가 DBA_ 뷰를 조회하면 ORA-00942가 난다. 자기 권한은 USER_ 계열로 본다.
@B "권한이 있는데 안 된다"는 문의는 부여 상태(DBA_ROLE_PRIVS)와 세션 상태(SESSION_ROLES)를 나눠 보면 대부분 풀린다. 역할은 받았지만 켜지지 않은 경우가 흔하다.
@B DBA 역할 보유자는 정기 점검의 첫 항목이다. SYS, SYSTEM 외의 이름이 보이면 부여 경위를 확인한다.

@CODE
SYS@orcl> SELECT grantee, granted_role, admin_option, default_role
  2    FROM dba_role_privs WHERE granted_role = 'DBA';

SAR_DEV@orcl> SELECT role FROM session_roles;
SAR_DEV@orcl> SELECT privilege FROM user_sys_privs ORDER BY 1;
@END

@H3 3.2.4  부여와 회수의 연쇄

@B 시스템 권한을 WITH ADMIN OPTION으로 받은 A가 B에게 다시 줬다. 이후 A의 권한을 회수해도 B의 권한은 남는다. 시스템 권한 회수는 연쇄되지 않는다.
@B 객체 권한을 WITH GRANT OPTION으로 받은 A가 B에게 다시 줬다면, A의 권한을 회수할 때 B의 권한도 함께 사라진다. 객체 권한 회수는 연쇄된다.
@B 역할도 WITH ADMIN OPTION으로 재부여할 수 있고 회수는 연쇄되지 않는다. 역할을 만든 사용자는 자동으로 ADMIN OPTION과 함께 그 역할을 받는다.
@B PUBLIC에 준 권한은 모든 사용자가 갖는다. 19c 설치 직후에도 PUBLIC에 실행 권한이 열린 패키지가 있으며, 보안 기준에 따라 UTL_FILE, UTL_TCP 같은 패키지의 PUBLIC 실행 권한을 회수하기도 한다(4장).

@TBL
구분 | 재부여 옵션 | 중간 사용자 회수 시 하위 부여
시스템 권한 | WITH ADMIN OPTION | 남는다
역할 | WITH ADMIN OPTION | 남는다
객체 권한 | WITH GRANT OPTION | 함께 회수된다
@END

@B 재부여 옵션이 섞인 권한은 누가 누구에게 줬는지 추적하기 어렵다. 업무 계정에는 재부여 옵션을 주지 않고, 부여는 보안 관리 계정이 직접 한다.

@H3 3.2.5  자주 쓰는 점검 조회

@B ANY 시스템 권한을 직접 가진 사용자는 다른 스키마의 객체 권한 통제를 무력화한다. Oracle 관리 계정을 빼고 조회한다.
@B 역할 안에 든 권한까지 펼쳐 보려면 DBA_ROLE_PRIVS를 CONNECT BY로 따라가거나, 대상 사용자로 접속해 SESSION_PRIVS를 본다.
@B PUBLIC에 열린 실행 권한은 모든 사용자의 권한이다. 네트워크·파일 관련 패키지가 PUBLIC에 열려 있는지 확인한다.

@CODE
SELECT grantee, privilege FROM dba_sys_privs
 WHERE privilege LIKE '%ANY%'
   AND grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N');

SELECT LPAD(' ', 2*(LEVEL-1)) || granted_role AS role_tree
  FROM dba_role_privs
 START WITH grantee = 'SAR_DEV'
 CONNECT BY PRIOR granted_role = grantee;

SELECT table_name FROM dba_tab_privs
 WHERE grantee = 'PUBLIC' AND table_name IN ('UTL_FILE', 'UTL_TCP', 'UTL_HTTP', 'UTL_SMTP');
@END

@H2 3.3  역할의 활성화와 인증 방식

@H3 3.3.1  기본 역할과 SET ROLE

@B 사용자에게 역할을 주면 기본적으로 기본 역할(default role)이 되어 로그인 때 자동으로 켜진다.
@B `ALTER USER ... DEFAULT ROLE`로 로그인 때 켤 역할을 지정한다. 기본 역할에서 뺀 역할은 `SET ROLE`로 켜야 한다.
@B `SET ROLE 역할명`은 이미 부여받은 역할을 켜고 나머지를 끈다. 받지 않은 역할을 켜려 하면 ORA-01924가 난다.
@B `SET ROLE NONE`은 모든 역할을 끈다. 직접 받은 권한은 그대로 남는다.
@B PL/SQL에서는 `DBMS_SESSION.SET_ROLE('역할명')`으로 같은 일을 한다. PL/SQL의 정적 SQL에는 SET ROLE을 쓸 수 없어 `EXECUTE IMMEDIATE`로 쓰는 방법도 있다.

@B 기본 역할 지정은 `DEFAULT ROLE ALL`, `DEFAULT ROLE ALL EXCEPT 역할`, `DEFAULT ROLE NONE`, `DEFAULT ROLE 역할목록` 형식을 쓴다. 비밀번호 역할을 기본 역할로 두면 로그인 때 비밀번호 없이 켜지므로 비밀번호 역할의 의미가 사라진다.

@CODE
ALTER USER sar_dev DEFAULT ROLE ALL EXCEPT pay_role;
SET ROLE NONE;
SET ROLE resource;
@END

@H3 3.3.2  역할의 인증 방식

@P 역할을 켤 때 무엇을 확인할지 역할마다 정할 수 있다. CREATE ROLE의 IDENTIFIED 절이 그 방식을 정한다.

@TBL
방식 | 생성 구문 | 켜는 조건 | DBA_ROLES.AUTHENTICATION_TYPE
없음 | CREATE ROLE r | 부여만 되어 있으면 | NONE
비밀번호 | IDENTIFIED BY 비밀번호 | SET ROLE r IDENTIFIED BY 비밀번호 | PASSWORD
외부 | IDENTIFIED EXTERNALLY | 운영체제 그룹 등 외부 인증 | EXTERNAL
전역 | IDENTIFIED GLOBALLY | 디렉터리 서비스(LDAP)에서 부여 | GLOBAL
애플리케이션 | IDENTIFIED USING 스키마.패키지 | 지정한 PL/SQL 코드가 켬 | APPLICATION
@END

@CODE
CREATE ROLE pay_role IDENTIFIED BY "Pay#2026";
SET ROLE pay_role IDENTIFIED BY "Pay#2026";

CREATE ROLE manager_role IDENTIFIED USING sar_admin.access_control_policy;
@END

@B 비밀번호 역할은 "애플리케이션만 역할 비밀번호를 안다"는 가정에 기댄다. 비밀번호가 소스 코드, 설정 파일, 테이블에 들어가는 순간 그 가정이 깨진다.
@B Secure Application Role은 비밀번호 대신 데이터베이스 안의 코드가 조건을 판단한다. 판단 규칙을 바꾸려면 코드를 바꾸면 되고 애플리케이션 배포가 필요 없다.

@CASE 역할 비밀번호가 설정 파일에서 발견됐다
업무 화면에서만 급여 테이블을 수정하게 하려고 비밀번호 역할을 만들고, 애플리케이션이 로그인 직후 `SET ROLE pay_role IDENTIFIED BY ...`를 실행하도록 했다. 사용자 계정에는 급여 테이블 권한을 주지 않았다.
몇 달 뒤 보안 점검에서 애플리케이션 서버의 설정 파일에 역할 비밀번호가 평문으로 들어 있는 것이 발견됐다. 서버 접근 권한이 있는 개발자라면 누구든 SQL*Plus에서 같은 SET ROLE로 급여 테이블을 수정할 수 있었다.
역할을 `IDENTIFIED USING sec_admin.pay_role_check`로 다시 만들었다. 프로시저는 접속 IP와 프록시 사용자를 확인한 뒤에만 역할을 켜도록 했고, 설정 파일에서 비밀번호를 지웠다.
@END

@H3 3.3.3  PL/SQL과 뷰 안에서의 역할

@B 정의자 권한 프로시저, 뷰, 트리거는 소유자의 권한으로 실행되며 이때 역할로 받은 권한은 쓰이지 않는다. 소유자가 DBA 역할을 갖고 있어도 프로시저 안에서 SELECT ANY TABLE을 쓸 수 없는 이유다.
@B 호출자 권한(AUTHID CURRENT_USER) 프로시저는 호출자의 권한과 현재 켜진 역할로 실행된다.
@B 12c부터는 역할을 PL/SQL 단위에 직접 부여할 수 있다(code based access control, CBAC). `GRANT 역할 TO PROCEDURE 스키마.프로시저` 형식이다.
@B CBAC로 프로시저에 붙인 역할은 그 프로시저가 실행되는 동안에만 쓰인다. 호출자 권한 프로시저가 호출자에게 없는 권한을 잠시 쓰게 할 때 쓴다.
@B Secure Application Role은 세션에 역할을 켜서 이후의 SQL 전체에 권한을 준다. CBAC는 특정 코드 실행 중에만 권한을 준다. 범위가 다르다.

@NOTE 멀티테넌트 환경의 역할
CDB에서는 공통 역할(이름이 C## 등으로 시작)과 PDB 안의 로컬 역할이 구분된다. Secure Application Role은 보통 업무 PDB 안의 로컬 역할로 만들고, 활성화 프로시저도 같은 PDB에 둔다.
매뉴얼 예제의 접속 대상이 hrpdb인 이유가 이것이다. 이 과정의 실습 DB는 non-CDB라 구분이 없다.
@END

@H2 3.4  Secure Application Role의 개념

@H3 3.4.1  무엇을 막는가

@B 사용자 계정에 직접 준 권한은 애플리케이션 밖에서도 쓸 수 있다. 같은 계정과 비밀번호로 SQL*Plus나 보고서 도구에 접속하면 화면이 막아 둔 작업을 그대로 할 수 있다.
@B Secure Application Role은 권한을 역할에만 주고, 그 역할을 지정한 PL/SQL 프로시저나 패키지만 켤 수 있게 한다.
@B 프로시저는 세션 정보를 검사해 조건을 만족할 때만 역할을 켠다. 검사 항목은 접속 IP, 프록시 경유 여부, 애플리케이션 컨텍스트 값, 시간대, 직무 등이다.
@B 매뉴얼이 꼽는 장점은 세 가지다. 비밀번호가 애플리케이션 코드나 테이블에 들어가지 않고, 정책이 데이터베이스 한 곳에 있어 수정이 쉽고, 어떤 경로로 접속하든 같은 정책이 적용된다.

@H3 3.4.2  데이터베이스가 확인하는 것

@B 역할을 켜는 명령이 실행되면 Oracle은 호출 스택에 USING으로 지정한 PL/SQL 단위가 있는지 확인한다.
@B 지정한 프로시저 밖에서 SET ROLE이나 DBMS_SESSION.SET_ROLE을 직접 실행하면 ORA-28201: invalid command to enable secure application role이 난다. 역할을 만든 사용자도 예외가 아니다.
@B 같은 스키마의 다른 프로시저가 역할을 켜려 해도 실패한다. 19.3에서는 이 경우 ORA-01924(role not granted or does not exist)가 났다.
@B 역할을 켠 뒤의 권한 사용은 일반 역할과 같다. 세션이 끝나면 역할도 사라진다.

@TBL
시도 | 결과
SET ROLE manager_role | ORA-28201
EXEC DBMS_SESSION.SET_ROLE('manager_role') | ORA-28201
USING에 없는 다른 프로시저에서 SET_ROLE | ORA-01924
USING에 지정한 정의자 권한 프로시저에서 SET_ROLE | ORA-06565
USING에 지정한 호출자 권한 프로시저에서 SET_ROLE | 역할 활성화
@END

@H3 3.4.3  세션 하나에서 일어나는 순서

@TBL
순서 | 주체 | 일어나는 일
1 | 사용자 | 애플리케이션 또는 SQL*Plus로 로그인. 직접 받은 권한과 기본 역할만 켜짐
2 | 애플리케이션 | 로그인 직후 활성화 프로시저 호출
3 | 활성화 프로시저 | 호출자 권한으로 실행되며 세션 속성·매핑 테이블을 검사
4 | 활성화 프로시저 | 검사를 통과하면 DBMS_SESSION.SET_ROLE 호출
5 | 데이터베이스 | 호출 스택에 USING으로 지정한 PL/SQL 단위가 있는지 확인 후 역할 활성화
6 | 사용자 | 이후 SQL에서 역할 권한 사용. 세션 종료나 SET ROLE NONE으로 사라짐
@END

@B 2단계를 건너뛴 접속(직접 SQL*Plus 접속 등)은 역할 없이 1단계 상태로 남는다. 검사를 통과하지 못한 접속도 마찬가지다.
@B 2단계는 애플리케이션 코드가 하는 일이다. 데이터베이스가 대신해 줄 방법(기본 역할, LOGON 트리거)은 3.7절에서 보듯 막혀 있다.

@H3 3.4.4  맞지 않는 경우

@B 사용자가 직접 SQL 도구로 데이터를 다루는 것이 정상 업무라면 Secure Application Role은 업무를 막는다. 분석가 계정처럼 도구 접속이 본업인 경우는 권한 자체를 줄이는 쪽이 맞다.
@B 애플리케이션 코드를 고칠 수 없는 패키지 제품은 로그인 직후 프로시저를 호출하게 만들기 어렵다. 이 경우 프록시 인증이나 VPD처럼 애플리케이션 수정 없이 적용되는 기법을 먼저 검토한다.
@B 검사 근거가 클라이언트 값(MODULE 등)밖에 없는 환경에서는 효과가 제한적이다. 서버 측 근거를 만들 수 있는지(프록시 계정, 접속 서버 IP, 컨텍스트) 먼저 확인한다.
@B 권한이 아니라 데이터 범위를 나누는 것이 목적이면 VPD가 맞다. 역할은 켜지거나 꺼질 뿐 행을 고르지 못한다.

@H2 3.5  생성 절차

@P 매뉴얼의 튜토리얼은 두 단계다. 1단계에서 역할을 만들고 권한을 주며, 2단계에서 정책을 담은 PL/SQL을 만든다. 실습에서는 원본 자료의 시나리오(직무가 MANAGER인 사원만 급여 조회)를 이 순서로 구성했다.

@H3 3.5.1  역할 만들기와 권한 부여

@B 역할을 만들려면 CREATE ROLE 시스템 권한이 필요하다. 역할과 활성화 프로시저는 보안 관리 전용 계정이 함께 소유하는 것이 관리하기 좋다.
@B USING 절에 적은 프로시저는 이 시점에 없어도 된다. 역할은 이름만 기록한다.
@B 역할에 업무 권한을 준다. 사용자에게는 역할을 주지 않는다. 매뉴얼은 "역할을 사용자에게 직접 부여하지 말라. 프로시저가 정책을 통과한 사용자에게 대신 해 준다"고 적고 있다.
@B 역할을 만든 계정에는 ADMIN OPTION과 함께 역할이 자동 부여된다. 이 부여가 있어도 그 계정 역시 프로시저 밖에서는 역할을 켤 수 없다.

@CODE
SAR_ADMIN@orcl> CREATE ROLE manager_role IDENTIFIED USING sar_admin.access_control_policy;
SYS@orcl> GRANT SELECT ON scott.emp TO manager_role;

SYS@orcl> SELECT role, password_required, authentication_type
  2    FROM dba_roles WHERE role = 'MANAGER_ROLE';

ROLE           PASSWORD AUTHENTICATION_TYPE
-------------- -------- -------------------
MANAGER_ROLE   YES      APPLICATION
@END

@B DBA_ROLES의 PASSWORD_REQUIRED가 YES로 보이지만 비밀번호 역할은 아니다. 인증 방식은 AUTHENTICATION_TYPE으로 판단한다.

@H3 3.5.2  활성화 프로시저 작성

@P 매뉴얼은 프로시저가 갖춰야 할 조건으로 세 가지를 든다. 호출자 권한일 것, 사용자를 검증하는 검사를 하나 이상 포함할 것, 검사를 통과하면 SET ROLE 또는 DBMS_SESSION.SET_ROLE을 실행할 것.

@CODE
CREATE OR REPLACE PROCEDURE access_control_policy
AUTHID CURRENT_USER
AS
  v_job VARCHAR2(9);
BEGIN
  SELECT job INTO v_job
    FROM scott.emp_job
   WHERE ename = SYS_CONTEXT('USERENV', 'SESSION_USER');
  IF v_job = 'MANAGER' THEN
    DBMS_SESSION.SET_ROLE('manager_role');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN NULL;
END;
/
GRANT EXECUTE ON access_control_policy TO blake, james;
@END

@B 직무를 판단하는 뷰 EMP_JOB은 이름과 직무만 담는다. 급여가 있는 EMP는 역할을 통해서만 읽는다.
@B 호출자 권한이므로 EMP_JOB 조회도 호출한 사용자의 권한으로 실행된다. blake, james에게 EMP_JOB 조회 권한을 준 이유다.
@B 검사에 실패하면 아무 일도 하지 않고 끝난다. 사용자에게는 "프로시저는 성공했는데 권한이 없다"로 보인다.
@B 실행 권한은 역할을 써야 하는 사용자나 애플리케이션 계정에만 준다.

@H3 3.5.3  패키지로 구성하기

@B 역할이 여럿이거나 검사 로직이 길면 패키지로 만든다. 매뉴얼의 CREATE ROLE 구문도 USING 뒤에 패키지 이름을 받는다.
@B AUTHID CURRENT_USER는 패키지 명세에 둔다. 본문의 각 프로시저가 모두 호출자 권한으로 실행된다.
@B 역할 하나에 패키지 하나가 연결된다. 같은 패키지를 여러 역할의 USING에 지정하면, 패키지 안의 프로시저마다 다른 역할을 켜게 할 수 있다.

@CODE
CREATE OR REPLACE PACKAGE hr_role_pkg AUTHID CURRENT_USER AS
  PROCEDURE enable_manager;
  PROCEDURE enable_payroll;
END;
/
CREATE ROLE manager_role IDENTIFIED USING sar_admin.hr_role_pkg;
CREATE ROLE payroll_role IDENTIFIED USING sar_admin.hr_role_pkg;
@END

@B 이 경우 hr_role_pkg 안의 코드는 두 역할을 모두 켤 수 있다. 각 프로시저가 정확히 자기 역할만 켜는지는 코드 검토로 보장해야 한다.

@H3 3.5.4  시험

@B 업무 계정으로 접속해 프로시저 호출 전후의 SESSION_ROLES와 업무 조회 결과를 비교한다.
@B 실습에서 blake(MANAGER)는 호출 뒤 MANAGER_ROLE이 켜지고 EMP 급여를 조회했다. james(CLERK)는 호출이 성공했지만 역할이 켜지지 않아 ORA-00942가 그대로였다.
@B 조건을 통과하지 못하는 경로(다른 IP, 다른 프로그램, 다른 직무)도 반드시 시험한다. 통과 경로만 시험하면 검사가 동작하는지 알 수 없다.

@NOTE 원본 실습 자료와 다른 점
과정 원본 자료는 역할과 프로시저를 SYSTEM 스키마에 만든다. 기능은 같지만 관리 계정이 DBA 권한까지 가진 SYSTEM이 되어 역할 정책을 손대는 사람을 좁히기 어렵다.
이 교안은 매뉴얼 예제처럼 보안 관리 전용 계정(sar_admin)을 두었다. 원본 프로시저에는 NO_DATA_FOUND 처리가 없어 EMP에 없는 사용자가 호출하면 오류가 났는데, 예외 처리를 넣어 조용히 끝나게 했다.
@END

@H3 3.5.5  도입 순서

@TBL
단계 | 작업 | 확인할 것
1 | 대상 권한 선정 | 권한 분석 결과, 화면별로 쓰는 객체 권한
2 | 보안 관리 계정 준비 | CREATE ROLE, CREATE PROCEDURE 권한, 접속 제한
3 | 역할 생성 | IDENTIFIED USING에 적을 프로시저 이름 확정
4 | 역할에 권한 부여 | 사용자에게서 같은 권한 회수 계획
5 | 활성화 프로시저 작성 | AUTHID CURRENT_USER, 검사 조건, 예외 처리, 실패 기록
6 | 실행 권한 부여 | 애플리케이션 계정·업무 사용자만
7 | 애플리케이션 수정 | 로그인 직후 호출, 풀 반납 시 역할 끄기
8 | 시험 | 통과 경로와 실패 경로 모두, SESSION_ROLES 확인
9 | 기존 직접 권한 회수 | 회수 후 SQL 도구 접속에서 업무 객체 접근 불가 확인
@END

@B 9단계를 빼면 도입 효과가 없다. 사용자에게 직접 준 권한이 남아 있으면 역할 없이도 같은 작업을 할 수 있다.
@B 7단계 배포와 9단계 회수의 순서를 지킨다. 애플리케이션 수정보다 회수가 먼저면 업무 화면이 권한 오류로 멈춘다.

@CASE 역할을 도입했는데 SQL 도구에서 여전히 급여가 보인다
급여 조회 권한을 Secure Application Role로 옮기는 작업을 마쳤다고 보고됐다. 확인을 위해 업무 사용자 계정으로 SQL*Plus에 접속해 급여 테이블을 조회했는데, 활성화 프로시저를 부르지 않았는데도 조회가 됐다.
DBA_TAB_PRIVS를 보니 도입 전에 사용자에게 직접 준 SELECT 권한이 그대로 남아 있었다. 역할에 같은 권한을 줬을 뿐 기존 권한을 회수하는 단계가 빠졌던 것이다.
사용자별 직접 권한을 회수하고, 회수 뒤 SQL 도구로 접속했을 때 ORA-00942가 나는지까지 시험 항목에 넣었다.
@END

@H2 3.6  활성화 프로시저 설계

@H3 3.6.1  호출자 권한이어야 하는 이유

@B AUTHID 절이 없는 프로시저는 정의자 권한(AUTHID DEFINER)으로 실행된다. 정의자 권한 코드 안에서는 호출자의 역할이 꺼진 상태로 실행된다.
@B 이런 코드에서 역할을 켜려 하면 ORA-06565: cannot execute SET ROLE from within stored procedure가 난다. 실행 중에 역할 상태를 바꾸면 권한 판단 기준이 흔들리기 때문이다.
@B 호출자 권한(AUTHID CURRENT_USER) 코드는 호출한 사용자의 권한과 역할로 실행된다. 여기서 켠 역할은 프로시저가 끝난 뒤에도 그 세션에 남는다.
@B 매뉴얼은 "정의자 권한으로는 이 패키지를 만들 수 없다"고 명시한다. 패키지를 쓴다면 패키지 명세에 AUTHID CURRENT_USER를 둔다.

@H3 3.6.2  SET ROLE과 DBMS_SESSION.SET_ROLE

@B PL/SQL 정적 SQL은 SET ROLE을 지원하지 않는다. `EXECUTE IMMEDIATE 'SET ROLE manager_role'` 또는 `DBMS_SESSION.SET_ROLE('manager_role')`을 쓴다.
@B `SET ROLE ALL`로 이 유형의 역할을 켤 수는 없다.
@B SET ROLE은 지정한 역할만 켜고 나머지를 끈다. 사용자가 다른 기본 역할을 갖고 있었다면 호출 뒤 그 역할들이 꺼진다. 함께 켜 둬야 할 역할이 있으면 `SET_ROLE('manager_role, connect')`처럼 같이 적는다.

@B 화면 전환에 따라 다른 역할이 필요하면 프로시저를 둘로 나누고 각각 다른 역할을 켜게 한다. SET_ROLE은 지정한 역할 외의 역할을 끄므로 화면을 옮길 때마다 필요한 역할만 남는다.
@B 역할을 끌 때는 `DBMS_SESSION.SET_ROLE('NONE')`을 쓴다. 끄는 동작에는 USING 제약이 없어 어떤 코드에서든 가능하다.

@H3 3.6.3  검사 조건 고르기

@TBL
조건 | 얻는 방법 | 누가 정하는가
로그인 사용자 | SYS_CONTEXT('USERENV','SESSION_USER') | 데이터베이스
클라이언트 IP | SYS_CONTEXT('USERENV','IP_ADDRESS') | 데이터베이스(리스너 경유 시)
프록시 사용자 | SYS_CONTEXT('USERENV','PROXY_USER') | 데이터베이스(2장)
인증 방식 | SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') | 데이터베이스
시간대 | SYSDATE | 데이터베이스
모듈·액션 | SYS_CONTEXT('USERENV','MODULE') | 클라이언트
클라이언트 식별자 | SYS_CONTEXT('USERENV','CLIENT_IDENTIFIER') | 클라이언트
애플리케이션 컨텍스트 | SYS_CONTEXT('네임스페이스','속성') | 신뢰 패키지(6장)
@END

@B 데이터베이스가 채우는 값은 사용자가 바꿀 수 없다. 클라이언트가 채우는 값은 누구나 바꿀 수 있다.
@B 실습에서 MODULE이 'HRAPP'인지 검사하자, SQL*Plus에서 `DBMS_APPLICATION_INFO.SET_MODULE('HRAPP', NULL)` 한 줄로 조건을 통과했다. MODULE은 단독 근거가 되지 못한다.
@B 리스너를 거치지 않는 로컬(bequeath) 접속에서는 IP_ADDRESS가 비어 있다. IP 조건만으로 판단하면 서버에 로그인한 사용자는 모두 탈락하거나, 빈 값을 허용하는 실수를 하면 모두 통과한다.
@B 매뉴얼 예제는 IP 주소와 업무 시간(08~17시)을 함께 검사한다. 서로 다른 출처의 조건을 둘 이상 조합하는 것이 기본이다.

@CODE
CREATE OR REPLACE PROCEDURE access_control_policy
AUTHID CURRENT_USER
AS
  v_job VARCHAR2(9);
BEGIN
  IF SYS_CONTEXT('USERENV', 'MODULE') <> 'HRAPP'
     OR SYS_CONTEXT('USERENV', 'IP_ADDRESS') NOT LIKE '172.16.%' THEN
    RETURN;
  END IF;
  ...
@END

@B 매뉴얼 예제는 지정한 두 IP에서, 오전 8시부터 오후 5시 사이에만 역할을 켠다. 형식은 다음과 같다.

@CODE
CREATE OR REPLACE PROCEDURE hr_admin_role_check
AUTHID CURRENT_USER
AS
BEGIN
  IF (SYS_CONTEXT('USERENV', 'IP_ADDRESS') IN ('192.0.2.10', '192.0.2.11')
      AND TO_CHAR(SYSDATE, 'HH24') BETWEEN 8 AND 17) THEN
    EXECUTE IMMEDIATE 'SET ROLE hr_admin';
  END IF;
END;
/
@END

@B 시간 조건은 역할을 켜는 순간에만 검사된다. 오후 4시 59분에 켠 역할은 그 세션이 끝날 때까지 유지된다(3.10절).

@BP 활성화 프로시저 작성 규칙
AUTHID CURRENT_USER로 만든다.
서버가 채우는 값(SESSION_USER, IP_ADDRESS, PROXY_USER)을 중심으로 검사하고, 클라이언트 값은 보조로만 쓴다.
NULL이 나올 수 있는 조건(로컬 접속의 IP 등)이 어느 쪽으로 판정되는지 확인한다. `NOT LIKE`는 NULL에 대해 참도 거짓도 아니다.
검사 실패를 감사 기록이나 로그 테이블에 남긴다. 실패가 조용히 끝나면 공격 시도도 조용히 묻힌다.
예외를 처리해 프로시저가 업무 오류로 번지지 않게 한다.
@END

@H3 3.6.4  검사 실패를 기록하기

@B 검사 실패는 오류 없이 끝나므로 기록을 남기지 않으면 누가 시도했는지 알 수 없다.
@B 프로시저 안에서 로그 테이블에 쓰려면 자율 트랜잭션(PRAGMA AUTONOMOUS_TRANSACTION) 프로시저를 따로 만들어 호출한다. 업무 트랜잭션의 커밋·롤백과 무관하게 기록이 남는다.
@B 기록 항목은 시각, SESSION_USER, IP_ADDRESS, MODULE, OS_USER, 실패 사유 정도면 충분하다.
@B Unified Auditing을 쓰면 활성화 프로시저 실행 자체를 감사 정책으로 잡을 수 있다. 성공·실패 판단은 프로시저 안의 로그가, 호출 사실은 감사 기록이 맡는다(13장).

@CODE
CREATE OR REPLACE PROCEDURE log_role_fail (p_reason IN VARCHAR2) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO sar_admin.role_fail_log
  VALUES (SYSTIMESTAMP, SYS_CONTEXT('USERENV', 'SESSION_USER'),
          SYS_CONTEXT('USERENV', 'IP_ADDRESS'), SYS_CONTEXT('USERENV', 'MODULE'), p_reason);
  COMMIT;
END;
/
@END

@B 로그 프로시저는 정의자 권한으로 둬도 된다. 역할을 켜는 코드가 아니므로 ORA-06565와 관계없고, 호출자에게 로그 테이블 권한을 줄 필요도 없어진다.

@B 역할로 받은 권한의 사용 자체를 감사하려면 Unified Auditing 정책의 ROLES 절을 쓴다. `CREATE AUDIT POLICY ... ROLES manager_role`은 그 역할에 든 시스템 권한의 사용을 기록한다.
@B 객체 권한(예: SCOTT.EMP 조회)의 사용은 ACTIONS 절에 객체를 지정해 감사한다. 역할이 켜진 세션이 실제로 무엇을 조회했는지가 남는다.
@B 활성화 성공 기록, 실패 기록, 권한 사용 기록이 모이면 "누가 어떤 경로로 권한을 얻어 무엇을 했는지"를 재구성할 수 있다.

@H3 3.6.5  애플리케이션 컨텍스트와 함께 쓰기

@B 사용자 속성(부서, 직급, 인증 단계)을 로그인 시점에 애플리케이션 컨텍스트에 넣어 두면, 활성화 프로시저는 매핑 테이블을 다시 읽지 않고 `SYS_CONTEXT`로 판단한다.
@B 컨텍스트 값은 USING에 지정한 신뢰 패키지만 넣을 수 있어 사용자가 위조할 수 없다(6장). MODULE이나 CLIENT_IDENTIFIER보다 믿을 만한 근거가 된다.
@B 예를 들어 애플리케이션이 2차 인증을 마치면 신뢰 패키지가 컨텍스트에 `AUTH_LEVEL=2`를 넣고, 활성화 프로시저는 이 값이 2일 때만 급여 조회 역할을 켠다.

@H3 3.6.6  프록시 인증과 함께 쓰기

@B 3층 구조에서는 애플리케이션 서버가 프록시 계정으로 접속하고 최종 사용자 이름으로 세션을 연다(2장).
@B 활성화 프로시저에서 `SYS_CONTEXT('USERENV','PROXY_USER')`가 애플리케이션 서버 계정인지 확인하면 "애플리케이션 서버를 거친 세션"만 역할을 켜게 할 수 있다. 매뉴얼이 예로 드는 프록시 경유 확인이 이것이다.
@B 이 조건은 클라이언트가 바꿀 수 없는 값이라 MODULE 검사보다 훨씬 믿을 만하다.

@CASE 업무 화면 이름만 맞추면 누구나 급여를 본다
인사 시스템에 Secure Application Role을 도입하면서 활성화 프로시저가 MODULE이 'HRAPP'인지만 확인하도록 만들었다. 업무 화면은 로그인 직후 SET_MODULE로 이름을 넣고 프로시저를 호출했다.
내부 감사에서, 인사팀이 아닌 개발자가 SQL*Plus로 접속해 `DBMS_APPLICATION_INFO.SET_MODULE('HRAPP', NULL)`을 실행한 뒤 프로시저를 호출해 급여 테이블을 조회한 기록이 나왔다.
검사 조건을 바꿨다. 애플리케이션 서버의 프록시 계정을 거친 세션(PROXY_USER)이면서 애플리케이션 서버 IP에서 온 접속만 통과하게 했다. MODULE 검사는 화면별 권한 구분 용도로만 남기고, 검사 실패는 로그 테이블에 기록했다.
@END

@B 프록시 구성과 활성화 조건을 함께 쓰는 형식은 다음과 같다. appsrv는 애플리케이션 서버가 접속에 쓰는 계정이다.

@CODE
ALTER USER blake GRANT CONNECT THROUGH appsrv;

CREATE OR REPLACE PROCEDURE access_control_policy
AUTHID CURRENT_USER
AS
BEGIN
  IF SYS_CONTEXT('USERENV', 'PROXY_USER') = 'APPSRV' THEN
    DBMS_SESSION.SET_ROLE('manager_role');
  END IF;
END;
/
@END

@B SQL*Plus로 blake/비밀번호를 써서 직접 접속한 세션은 PROXY_USER가 NULL이라 역할이 켜지지 않는다. 같은 사용자라도 애플리케이션 서버를 거쳐야만 권한이 생긴다.

@H3 3.6.7  활성화 결과 확인과 변경의 반영 시점

@P 활성화 프로시저는 검사에 실패해도 오류 없이 끝난다. 아래 내용은 문서 기준이다.

@B PL/SQL Packages Reference 19c는 DBMS_SESSION에 `SESSION_IS_ROLE_ENABLED`(로그인 사용자 세션에 역할이 켜져 있는가)와 `CURRENT_IS_ROLE_ENABLED`(지금 켜져 있는가) 두 함수를 둔다. 둘 다 BOOLEAN을 돌려준다.
@B 예전부터 쓰던 `DBMS_SESSION.IS_ROLE_ENABLED`는 19c부터 디프리케이트다. 기존 코드에서 이 함수를 쓰고 있다면 두 함수 중 하나로 바꾼다.
@B 애플리케이션은 활성화 프로시저를 부른 뒤 이 함수로 역할 상태를 확인하고, FALSE면 업무 화면 대신 권한 없음 안내를 띄울 수 있다. ORA-00942를 사용자 화면에 그대로 노출하지 않게 된다.
@B Security Guide에 따르면 시스템·객체 권한의 부여와 회수는 즉시 반영된다. MANAGER_ROLE에서 SELECT ON scott.emp를 회수하면 이미 역할을 켠 세션도 곧바로 조회하지 못한다.
@B 역할 자체의 부여·회수는 세션이 SET ROLE을 다시 실행하거나 새 세션이 열릴 때 반영된다.
@B 한 세션에서 동시에 켤 수 있는 역할은 148개까지다. DBA처럼 다른 역할을 품은 역할은 안에 든 역할까지 개수에 들어간다.

@CODE
DECLARE
  v_on BOOLEAN;
BEGIN
  sar_admin.access_control_policy;
  v_on := DBMS_SESSION.SESSION_IS_ROLE_ENABLED('MANAGER_ROLE');
  IF NOT v_on THEN
    RAISE_APPLICATION_ERROR(-20001, '급여 조회 권한이 없습니다');
  END IF;
END;
/
@END

@H2 3.7  활성화 범위와 제약

@H3 3.7.1  세션 단위로 켜지고 꺼진다

@B 프로시저가 켠 역할은 그 세션에만 있다. 새로 접속하면 다시 호출해야 한다.
@B `SET ROLE NONE`은 이 역할도 끈다. 끄는 데에는 제약이 없다.
@B 연결 풀을 쓰는 애플리케이션은 풀에서 세션을 꺼낼 때마다 역할 상태를 확인하거나 다시 켜야 한다. 앞 요청이 켠 역할이 다음 요청에 남아 있을 수 있기 때문이다.

@CASE 연결 풀에서 권한이 다른 사용자에게 넘어갔다
웹 애플리케이션이 공용 계정 하나로 연결 풀을 만들고, 관리자 메뉴에 들어갈 때만 활성화 프로시저를 호출해 관리 역할을 켰다. 어느 날 일반 사용자 화면에서 관리자만 볼 수 있는 데이터가 조회됐다는 신고가 들어왔다.
풀에 반납된 세션에 관리 역할이 켜진 채 남아 있었고, 다음 요청이 그 세션을 받아 관리 권한으로 SQL을 실행한 것이었다.
세션을 풀에 반납할 때 `DBMS_SESSION.SET_ROLE('NONE')`을 호출하도록 고치고, 관리자 메뉴의 요청마다 프로시저를 다시 호출하도록 했다. 이후 사용자별 구분이 필요한 부분은 CLIENT_IDENTIFIER와 전역 컨텍스트(6장)로 옮겼다.
@END

@B 다른 세션에 어떤 역할이 켜져 있는지 DBA가 바로 볼 수 있는 뷰는 없다. SESSION_ROLES는 자기 세션만 보여 준다. 역할 활성화 여부를 운영 중에 추적하려면 활성화 프로시저가 성공도 기록하게 한다.

@H3 3.7.2  기본 역할로 지정할 수 없다

@B 매뉴얼은 이 유형의 역할을 기본 역할로 둘 수 없다고 적는다.
@B 19.3에서 `GRANT manager_role TO blake` 후 `ALTER USER blake DEFAULT ROLE manager_role`을 실행하자 "User altered."로 끝났다. DBA_ROLE_PRIVS의 DEFAULT_ROLE은 NO로 남았고 새 세션에서도 역할이 켜지지 않았다.
@B 오류 없이 무시되므로 설정이 됐다고 착각하기 쉽다. 결과는 DBA_ROLE_PRIVS와 새 세션의 SESSION_ROLES로 확인한다.
@B 역할을 사용자에게 직접 부여해도 SET ROLE은 여전히 ORA-28201이다. 부여로 얻는 것이 없으니 부여하지 않는다.

@H3 3.7.3  LOGON 트리거로 켤 수 없다

@B 매뉴얼은 LOGON 트리거로 이 역할을 켜거나 끌 수 없으니, 로그인 직후 애플리케이션이 프로시저를 직접 호출하라고 한다.
@B 실습에서 blake 스키마의 LOGON 트리거가 모듈 이름을 맞춘 뒤 프로시저를 불렀다. 로그인은 정상이었지만 SESSION_ROLES는 비어 있었다. 오류가 나지 않으므로 트리거 방식을 시도했다면 반드시 결과를 확인한다.
@B 이 제약 때문에 Secure Application Role은 "애플리케이션이 로그인 직후 호출한다"는 협력을 전제로 한다. 호출을 빠뜨린 화면에서는 권한 오류가 난다.

@CASE 기본 역할로 지정했는데 아침마다 권한 오류가 난다
보고서 서버가 매일 아침 배치를 돌리며 급여 테이블을 조회하는데, Secure Application Role을 도입한 뒤부터 첫 실행이 ORA-00942로 실패했다. 담당자는 배치 계정에 역할을 부여하고 기본 역할로 지정해 두었다고 했다.
DBA_ROLE_PRIVS를 보니 역할은 부여돼 있었지만 DEFAULT_ROLE이 NO였다. ALTER USER가 오류 없이 끝나 지정이 된 줄 알았던 것이다.
배치 스크립트 첫 줄에 활성화 프로시저 호출을 넣고, 사용자에게 준 역할은 회수했다. 프로시저에는 배치 서버 IP와 배치 계정 이름을 검사 조건으로 추가했다.
@END

@CASE 배포 직후 오전 내내 급여 화면이 안 열렸다
활성화 프로시저에 검사 조건을 추가해 운영 중에 재컴파일했다. 프로시저가 참조하는 매핑 테이블의 컬럼 이름이 개발 DB와 달라 컴파일 오류가 났고, 프로시저는 INVALID 상태가 됐다.
애플리케이션은 로그인할 때마다 프로시저를 호출했고 호출은 PLS-00905(object is invalid) 오류로 실패했다. 역할이 켜지지 않아 급여 화면 전체가 권한 오류로 멈췄다.
이전 버전 소스로 즉시 되돌려 컴파일했고, 이후 프로시저 배포는 업무 시간 밖에 하며 배포 직후 업무 계정으로 활성화 시험을 하도록 절차를 바꿨다.
@END

@H3 3.7.4  활성화 프로시저가 사라지면

@B 프로시저를 DROP하면 호출이 PLS-00201로 실패하고 역할을 켤 방법이 없어진다.
@B DBA_APPLICATION_ROLES에는 역할과 프로시저 이름의 연결이 그대로 남는다. 같은 이름으로 다시 만들면 원래대로 동작한다.
@B 프로시저가 INVALID 상태가 돼도 같은 결과다. 프로시저가 참조하는 뷰·테이블을 바꿀 때는 프로시저 상태를 함께 확인한다.

@H3 3.7.5  오류 스택으로 호출 경로 읽기

@P 역할 활성화 오류 아래에 이어지는 ORA-06512 줄은 역할을 켜려 한 코드의 위치를 알려 준다.

@CODE
ORA-06565: cannot execute SET ROLE from within stored procedure
ORA-06512: at "SYS.DBMS_SESSION", line 183
ORA-06512: at "SAR_ADMIN.ACCESS_CONTROL_POLICY", line 9
ORA-06512: at line 1
@END

@B DBMS_SESSION.SET_ROLE로 켰다면 첫 ORA-06512는 SYS.DBMS_SESSION이고, 원인 코드는 그 아래 줄에 있다.
@B 그다음 줄이 역할을 켜려 한 PL/SQL 단위와 줄 번호다. 이 단위를 DBA_APPLICATION_ROLES의 SCHEMA·PACKAGE와 비교한다.
@B 두 값이 같고 오류가 ORA-06565면 AUTHID가 빠진 정의자 권한 프로시저다. 다르고 오류가 ORA-01924면 USING에 없는 코드가 호출한 경우다. 실습 03의 OTHER_PROC 호출이 `ORA-06512: at "SAR_ADMIN.OTHER_PROC", line 5`로 나왔다.
@B 프로시저 밖에서 DBMS_SESSION.SET_ROLE을 바로 부르면 ORA-28201 아래에 DBMS_SESSION 줄과 `at line 1`만 남는다. 중간에 사용자 코드가 없다.
@B 프로시저가 없으면 스택 모양이 달라진다. `ORA-06550: line 1, column 7`과 `PLS-00201: identifier 'SAR_ADMIN.ACCESS_CONTROL_POLICY' must be declared`가 나오며, 호출문을 컴파일하는 단계에서 막혀 역할 검사까지 가지 못한다. DBA_OBJECTS로 프로시저가 있는지, 상태가 VALID인지부터 확인한다.

@H2 3.8  다른 기법과의 비교

@H3 3.8.1  기법별 통제 범위

@TBL
기법 | 통제 대상 | 조건 위치 | 우회 시 결과
객체 권한 직접 부여 | 객체 단위 | 없음 | 어떤 도구로든 사용 가능
비밀번호 역할 | 역할 활성화 | 역할 비밀번호 | 비밀번호를 알면 활성화
Secure Application Role | 역할 활성화 | PL/SQL 프로시저 | 조건 불충족 시 역할 없음
프록시 인증 WITH ROLE | 프록시 세션의 역할 | ALTER USER ... GRANT CONNECT THROUGH | 프록시를 거치지 않으면 해당 없음
VPD | 행·컬럼 | 정책 함수 | 술어 밖 행은 보이지 않음
@END

@B Secure Application Role은 "이 권한을 지금 쓸 수 있는가"를 정한다. "어느 행을 볼 수 있는가"는 VPD(7장)가 정한다. 두 기법은 겹치지 않고 함께 쓸 수 있다.
@B 예를 들어 급여 테이블 조회 권한은 Secure Application Role로 업무 화면 경유 세션에만 주고, 그 세션이 볼 수 있는 부서는 VPD 정책으로 제한한다.
@B 프록시 인증의 WITH ROLE 절은 프록시 세션에서 켤 수 있는 역할을 제한한다. Secure Application Role 검사 조건에 PROXY_USER를 쓰면 두 기법이 맞물린다.

@H3 3.8.2  최소 권한을 정하는 근거, 권한 분석

@B Secure Application Role로 옮길 권한을 고르려면 애플리케이션이 실제로 쓰는 권한을 알아야 한다.
@B `DBMS_PRIVILEGE_CAPTURE` 패키지(Privilege Analysis)는 지정한 기간 동안 사용된 권한과 사용되지 않은 권한을 기록한다. 19c에서는 Enterprise Edition에 포함된 기능이다.
@B 캡처 범위는 데이터베이스 전체, 특정 역할, 조건(예: MODULE이 HRAPP인 세션)으로 정할 수 있다.
@B 결과는 DBA_USED_PRIVS, DBA_UNUSED_PRIVS 등의 뷰로 본다. 사용되지 않은 권한은 회수 후보이고, 특정 화면에서만 쓰인 권한은 Secure Application Role로 옮길 후보다.

@H3 3.8.3  VPD와 함께 쓰는 예

@B 급여 테이블 조회 권한은 Secure Application Role이 업무 화면 경유 세션에만 준다. 이 역할이 없으면 테이블 자체를 읽을 수 없다(ORA-00942).
@B 역할이 켜진 세션이 볼 수 있는 행은 VPD 정책이 부서 컨텍스트로 제한한다. 역할이 있어도 다른 부서 급여는 보이지 않는다.
@B 두 기법의 조건 근거를 같은 애플리케이션 컨텍스트(6장)에서 가져오면 관리 지점이 하나로 모인다. 로그인 직후 신뢰 패키지가 부서·인증 단계를 넣고, 활성화 프로시저와 정책 함수가 모두 그 값을 읽는다.

@H2 3.9  관련 데이터 딕셔너리 뷰

@TBL
뷰 | 내용
DBA_APPLICATION_ROLES | ROLE, SCHEMA, PACKAGE. Secure Application Role과 활성화 PL/SQL 단위의 연결
DBA_ROLES | 역할 목록. AUTHENTICATION_TYPE(NONE, PASSWORD, EXTERNAL, GLOBAL, APPLICATION)
DBA_ROLE_PRIVS | 역할 부여 현황, ADMIN_OPTION, DEFAULT_ROLE
ROLE_TAB_PRIVS, ROLE_SYS_PRIVS | 역할에 든 객체·시스템 권한
DBA_TAB_PRIVS | 활성화 프로시저 실행 권한 보유자(TABLE_NAME에 프로시저 이름)
SESSION_ROLES | 현재 세션에 켜진 역할
@END

@CODE
SYS@orcl> SELECT role, schema, package FROM dba_application_roles;

ROLE           SCHEMA     PACKAGE
-------------- ---------- ----------------------
MANAGER_ROLE   SAR_ADMIN  ACCESS_CONTROL_POLICY

SYS@orcl> SELECT grantee, privilege FROM dba_tab_privs
  2   WHERE owner = 'SAR_ADMIN' AND table_name = 'ACCESS_CONTROL_POLICY';
@END

@B PACKAGE 열에는 패키지가 아닌 단독 프로시저 이름도 들어간다.
@B 점검은 세 단계로 한다. DBA_APPLICATION_ROLES로 연결을 찾고, DBA_OBJECTS로 프로시저가 VALID인지 보고, DBA_TAB_PRIVS로 실행 권한 보유자를 확인한다.

@CODE
SYS@orcl> SELECT role, authentication_type FROM dba_roles
  2   WHERE authentication_type IN ('PASSWORD', 'APPLICATION') AND oracle_maintained = 'N';
@END

@B 이 조회 결과의 APPLICATION 역할 수와 DBA_APPLICATION_ROLES의 행 수가 같아야 한다. 차이가 나면 딕셔너리 연결이 어긋난 역할이 있다.

@BP 정기 점검 항목
DBA 역할과 ANY 시스템 권한 보유자 목록.
AUTHENTICATION_TYPE이 PASSWORD인 역할(비밀번호 유출 위험)과 APPLICATION인 역할의 활성화 프로시저 상태.
APPLICATION 역할이 사용자에게 직접 부여된 경우(DBA_ROLE_PRIVS). 효과는 없지만 설계 의도와 어긋난 흔적이다.
활성화 프로시저의 실행 권한 보유자와 마지막 변경 시각(DBA_OBJECTS.LAST_DDL_TIME).
@END

@NOTE ORA-28201과 ORA-01924
같은 역할을 켜려다 실패해도 경로에 따라 오류 번호가 다르다. SET ROLE이나 DBMS_SESSION.SET_ROLE을 프로시저 밖에서 바로 호출하면 ORA-28201이고, USING에 없는 다른 PL/SQL 단위 안에서 호출하면 19.3에서는 ORA-01924였다.
ORA-01924는 일반 역할에서 "부여받지 않은 역할"을 켤 때도 나는 번호라 원인을 오해하기 쉽다. 역할의 AUTHENTICATION_TYPE이 APPLICATION이면 먼저 호출 경로를 의심한다.
@END

@B 역할 부여 현황을 보면 역할 생성자에게 ADMIN OPTION과 함께 부여된 행이 하나 보인다. 기본 역할은 NO다.

@CODE
GRANTEE    GRANTED_ROLE   ADM DEF
---------- -------------- --- ---
SAR_ADMIN  MANAGER_ROLE   YES NO
@END

@B 이 부여는 생성 시 자동으로 생긴 것이다. 생성자가 다른 사용자에게 역할을 재부여할 수 있는 근거가 되므로, 운영에서는 생성자 계정을 보안 관리 전용으로 제한한다.

@H2 3.10  운영 시 주의점

@B 활성화 프로시저는 보안 정책 그 자체다. 프로시저 소유 계정의 접속을 제한하고 프로시저 변경을 감사한다.
@B 프로시저가 참조하는 매핑 테이블(직무, IP 목록 등)을 수정할 수 있는 사람은 사실상 역할을 줄 수 있는 사람이다. 매핑 테이블의 쓰기 권한도 같은 수준으로 관리한다.
@B 검사 실패가 오류 없이 끝나므로 애플리케이션 쪽에서는 권한 오류(ORA-00942, ORA-01031)로만 드러난다. 장애 문의가 들어오면 SESSION_ROLES부터 확인한다.
@B 역할이 켜지는 조건에 시간대를 넣었다면, 긴 세션은 조건 시간이 지난 뒤에도 역할을 유지한다. 시간 제한이 엄격해야 하면 애플리케이션이 주기적으로 SET ROLE NONE 후 다시 호출하게 한다.
@B 연결 풀 환경에서 세션을 반납할 때 역할을 끄지 않으면 다음 사용자가 그 권한을 물려받는다. 풀 반납 시 `SET ROLE NONE` 또는 기본 역할로 되돌리는 처리를 둔다.
@B 사용자에게서 직접 권한을 회수하기 전에, 그 권한에 의존하는 사용자 소유 뷰·프로시저가 없는지 확인한다. 정의자 권한 객체는 역할 권한을 쓰지 못하므로 회수 뒤 INVALID가 된다.
@B 활성화 프로시저를 수정·재컴파일하는 동안에는 역할을 켤 수 없다. 운영 시간 중 배포는 피하고, 배포 직후 업무 계정으로 활성화 시험을 한다.
@B 업그레이드나 데이터 이관 뒤에는 DBA_APPLICATION_ROLES의 연결과 프로시저 상태를 다시 확인한다. 스키마 이름이 바뀌면 USING 절의 연결이 끊긴다.
@B 장애 대응 중 임시로 사용자에게 업무 권한을 직접 부여했다면 작업이 끝난 뒤 반드시 회수한다. 직접 권한이 남는 순간 Secure Application Role은 우회로가 생긴다.
@B 역할 이름과 프로시저 이름은 담당 업무가 드러나게 짓는다. DBA_APPLICATION_ROLES 한 줄만 보고 어느 애플리케이션의 정책인지 알 수 있어야 한다.
@B 실습이 끝나면 역할, 활성화 프로시저, 시험 사용자를 모두 지운다. DROP ROLE은 부여 관계도 함께 지운다.

@H2 3.11  요약

@B 권한은 시스템 권한과 객체 권한으로 나뉘고, 역할로 묶어 부여한다. 부여 상태는 DBA_SYS_PRIVS·DBA_TAB_PRIVS·DBA_ROLE_PRIVS, 세션 상태는 SESSION_ROLES·SESSION_PRIVS로 본다.
@B 19c의 CONNECT는 CREATE SESSION과 SET CONTAINER뿐이고, RESOURCE를 줘도 UNLIMITED TABLESPACE는 따라오지 않는다.
@B Secure Application Role은 `CREATE ROLE ... IDENTIFIED USING 스키마.프로시저`로 만들며, 지정한 PL/SQL 단위만 역할을 켤 수 있다. 직접 SET ROLE은 ORA-28201이다.
@B 활성화 프로시저는 호출자 권한이어야 한다. 정의자 권한이면 ORA-06565가 난다.
@B 검사 조건은 서버가 채우는 세션 속성을 중심으로 조합한다. MODULE, CLIENT_IDENTIFIER는 클라이언트가 바꿀 수 있다.
@B 이 역할은 기본 역할이 될 수 없고 LOGON 트리거로도 켜지지 않는다. 19.3에서 두 경우 모두 오류 없이 역할이 켜지지 않았다. 애플리케이션이 로그인 직후 프로시저를 호출해야 한다.
@B 활성화 프로시저가 사라지거나 INVALID면 역할을 켤 수 없다. 딕셔너리 연결은 남아 있으므로 프로시저 상태를 함께 본다.
@B 도입의 마지막 단계는 사용자에게 직접 준 업무 권한의 회수다. 직접 권한이 남으면 역할을 우회할 수 있다.
@B DBA_APPLICATION_ROLES로 역할과 프로시저의 연결을, DBA_TAB_PRIVS로 실행 권한 보유자를 점검한다.

@H2 3.12  퀴즈

@QUIZ 문제 1
`CREATE ROLE r1 IDENTIFIED USING sec.chk_proc`로 만든 역할을 역할 생성자가 `SET ROLE r1`로 켜려 한다. 결과는?
① 생성자이므로 켜진다  ② ORA-01924가 난다  ③ ORA-28201이 난다  ④ 비밀번호를 묻는다
정답 ③. Secure Application Role은 USING에 지정한 PL/SQL 단위가 호출 스택에 있을 때만 켜진다. 생성자에게 ADMIN OPTION과 함께 부여돼 있어도 직접 SET ROLE은 ORA-28201(invalid command to enable secure application role)로 거부된다.
@END

@QUIZ 문제 2
활성화 프로시저를 AUTHID 절 없이 만들고 사용자가 호출했다. 어떤 오류가 나는가?
① ORA-06565  ② ORA-28201  ③ ORA-00942  ④ 오류 없이 역할이 켜진다
정답 ①. AUTHID 절이 없으면 정의자 권한 프로시저가 된다. 정의자 권한 코드 안에서는 역할을 켤 수 없어 ORA-06565(cannot execute SET ROLE from within stored procedure)가 난다. AUTHID CURRENT_USER로 다시 만들어야 한다.
@END

@QUIZ 문제 3
Secure Application Role에 대한 설명으로 옳은 것은?
① 사용자에게 부여하고 기본 역할로 지정하면 로그인 때 켜진다  ② LOGON 트리거에서 프로시저를 호출하면 켜진다  ③ 권한은 역할에 주고 역할은 사용자에게 주지 않는다  ④ SET ROLE ALL로 함께 켤 수 있다
정답 ③. 매뉴얼은 역할을 사용자에게 직접 주지 말라고 한다. 이 유형은 기본 역할이 될 수 없고 LOGON 트리거로도 켜지지 않으며 SET ROLE ALL 대상도 아니다. 애플리케이션이 로그인 직후 프로시저를 호출해 켠다.
@END

@QUIZ 문제 4
검사 조건으로 가장 신뢰하기 어려운 값은?
① SYS_CONTEXT('USERENV','SESSION_USER')  ② SYS_CONTEXT('USERENV','PROXY_USER')  ③ SYS_CONTEXT('USERENV','IP_ADDRESS')  ④ SYS_CONTEXT('USERENV','MODULE')
정답 ④. MODULE은 클라이언트가 DBMS_APPLICATION_INFO.SET_MODULE 등으로 자유롭게 정하는 값이라 SQL*Plus에서도 한 줄로 바꿀 수 있다. 나머지는 데이터베이스가 로그인 과정에서 채운다. 다만 IP_ADDRESS는 로컬 접속에서 비어 있으므로 NULL 처리를 확인해야 한다.
@END

@QUIZ 문제 5
같은 보안 관리 스키마에 호출자 권한 프로시저 other_proc를 만들어 manager_role(USING access_control_policy)을 켜려 했다. 결과는?
① 같은 스키마라 켜진다  ② ORA-01924가 나며 켜지지 않는다  ③ ORA-06565가 난다  ④ 역할이 켜지고 경고가 남는다
정답 ②. 역할은 USING에 지정한 PL/SQL 단위만 켤 수 있다. 같은 스키마의 다른 프로시저는 해당하지 않아, 19.3에서는 ORA-01924(role not granted or does not exist)로 거부됐다.
@END

@QUIZ 문제 6
Secure Application Role의 활성화 프로시저와 역할 연결을 확인하는 뷰는?
① DBA_ROLES  ② DBA_APPLICATION_ROLES  ③ SESSION_ROLES  ④ DBA_POLICIES
정답 ②. DBA_APPLICATION_ROLES의 ROLE, SCHEMA, PACKAGE 열이 역할과 활성화 PL/SQL 단위를 연결한다. DBA_ROLES는 인증 방식(APPLICATION)만 보여 주고, SESSION_ROLES는 현재 세션의 활성 역할, DBA_POLICIES는 VPD 정책 뷰다.
@END

@H2 3.13  실습 개요

@P 실습은 oel7v9 서버의 orcl 데이터베이스(19.3, non-CDB)에서 진행한다. 보안 관리 계정 sar_admin과 시험 사용자 blake(MANAGER), james(CLERK)를 02에서 만들어 04까지 쓰고, 05에서 모두 철거한다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
3장_실습_01_권한과역할조회 | 부여 상태와 세션 상태 뷰, 19c CONNECT·RESOURCE 구성, DBA_ 뷰 ORA-00942, SET ROLE ORA-01924 | 3.2, 3.3.1
3장_실습_02_SecureApplicationRole만들기 | IDENTIFIED USING, AUTHENTICATION_TYPE=APPLICATION, 직접 SET ROLE과 직접 부여의 ORA-28201 | 3.4, 3.5.1
3장_실습_03_활성화프로시저와권한모델 | 정의자 권한 ORA-06565, 호출자 권한으로 수정, 직무별 활성화, 다른 프로시저 ORA-01924 | 3.5.2, 3.6.1
3장_실습_04_검사조건과활성화범위 | MODULE·IP 검사와 위조, 로컬 접속 IP, SET ROLE NONE, 기본 역할 무시, LOGON 트리거 | 3.6.3, 3.7
3장_실습_05_딕셔너리점검과원복 | DBA_APPLICATION_ROLES, 프로시저 삭제 시 PLS-00201, ORA-01919, 원복 확인 | 3.7.4, 3.9
@END
