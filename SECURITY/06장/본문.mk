@H1 제6장  Application Context

@H2 6.1  학습 목표

@P 접근 제어를 사용자마다 다르게 하려면 데이터베이스가 "지금 이 세션의 사용자가 누구이고 어떤 속성을 가졌는지"를 빠르게 알아야 한다. 애플리케이션 컨텍스트는 그 정보를 세션 또는 인스턴스 메모리에 담아 두는 장치다.

@B 애플리케이션 컨텍스트의 구조(네임스페이스, 속성, 값)와 세 가지 유형의 저장 위치·공유 범위를 설명할 수 있다.
@B 기본 제공 네임스페이스 USERENV에서 서버가 채우는 값과 클라이언트가 바꿀 수 있는 값을 구분할 수 있다.
@B `CREATE CONTEXT`와 신뢰 패키지로 세션 기반 컨텍스트를 만들고, 패키지 밖에서 값을 넣을 수 없는 이유를 설명할 수 있다.
@B LOGON 트리거로 컨텍스트를 자동 초기화하고, 트리거 오류가 로그인을 막는 상황을 예방할 수 있다.
@B 컨텍스트를 참조하는 보안 뷰를 만들고 VPD와 비교해 장단점을 말할 수 있다.
@B 전역 접근 컨텍스트에서 username·client_id 인자가 값을 볼 수 있는 세션을 어떻게 정하는지 설명하고 연결 풀 모델을 구성할 수 있다.
@B 컨텍스트 관련 데이터 딕셔너리 뷰로 정의와 현재 값을 점검할 수 있다.

@H2 6.2  애플리케이션 컨텍스트의 개념

@H3 6.2.1  세션에 붙는 이름표

@B 애플리케이션 컨텍스트는 이름=값 쌍의 묶음이다. 묶음 하나를 네임스페이스(namespace)라 하고, 그 안의 이름을 속성(attribute)이라 한다.
@B 사용자가 로그인할 때 "부서=90, 직급=과장, 접속 경로=사내망" 같은 값을 네임스페이스에 기록해 두면, 이후 SQL은 `SYS_CONTEXT('네임스페이스', '속성')`으로 언제든 그 값을 읽는다.
@B 원본 강의 자료는 이를 세션용 개인 명찰에 비유한다. 명찰은 로그인 때 발급되고, 내용은 정해진 발급 창구(신뢰 패키지)만 고칠 수 있으며, 로그아웃하면 사라진다.
@B 값을 읽는 쪽은 VPD 정책 함수(7장), 보안 뷰, 트리거, 감사 정책 조건 등이다. 같은 값을 여러 곳에서 테이블 조회 없이 재사용할 수 있다.
@B 값은 모두 문자열로 저장된다. 숫자 비교에 쓸 때는 암시적 형 변환이 일어나므로, 인덱스 컬럼과 비교할 때는 형을 맞춘다.

@H3 6.2.2  왜 테이블이 아니라 컨텍스트인가

@B 사용자 속성을 매번 테이블에서 조회하면 SQL 한 문장마다 추가 조회가 붙는다. 보안 판단은 거의 모든 문장에서 일어나므로 비용이 누적된다.
@B 컨텍스트는 세션 메모리 또는 SGA에서 값을 읽는다. 디스크나 버퍼 캐시를 거치지 않는다.
@B `SYS_CONTEXT`는 SQL 문 안에서 바인드 변수처럼 취급된다. 값이 바뀌어도 같은 커서를 재사용하므로 하드 파싱이 늘지 않는다.
@B 사용자가 값을 조작할 수 없다는 점이 더 중요하다. 테이블 값이나 PL/SQL 패키지 변수는 권한이나 코드에 따라 사용자가 바꿀 여지가 있지만, 컨텍스트 값은 지정된 신뢰 패키지만 바꿀 수 있다.

@H3 6.2.3  세 가지 유형

@TBL
유형 | 저장 위치 | 값을 볼 수 있는 범위 | 주요 용도
데이터베이스 세션 기반 (ACCESSED LOCALLY) | 세션 UGA | 값을 넣은 세션 | 전용 접속 사용자의 속성
전역 (ACCESSED GLOBALLY) | SGA | username·client_id 조건에 맞는 모든 세션 | 연결 풀 기반 애플리케이션
클라이언트 세션 기반 (CLIENTCONTEXT) | 세션 UGA | 해당 세션 | OCI 클라이언트가 직접 설정
@END

@B 기본값은 세션 기반이다. `CREATE CONTEXT ... USING 패키지`만 쓰면 ACCESSED LOCALLY가 된다.
@B 세션 기반 컨텍스트의 초기화 방식은 세 가지다. 신뢰 패키지가 데이터베이스 안에서 넣는 방식, OCI 애플리케이션이 접속할 때 넣는 INITIALIZED EXTERNALLY, 디렉터리 서버(LDAP)의 엔터프라이즈 사용자 정보로 넣는 INITIALIZED GLOBALLY다.
@B 이 장은 데이터베이스 안에서 신뢰 패키지로 넣는 방식과 전역 컨텍스트를 중심으로 다룬다. OCI·LDAP 초기화는 개념만 짚는다.

@H3 6.2.4  컨텍스트 값을 읽는 곳

@TBL
사용처 | 읽는 방식 | 관련 장
보안 뷰 | 뷰 WHERE 절의 SYS_CONTEXT | 이 장 6.6절
VPD 정책 함수 | 함수 안 또는 반환 술어 안의 SYS_CONTEXT | 7장
Data Redaction 정책 식 | expression 인자의 SYS_CONTEXT 조건 | 8장
Unified Auditing 정책 조건 | CREATE AUDIT POLICY의 WHEN 절 | 13장
트리거·업무 PL/SQL | 감사 컬럼 기록, 업무 규칙 분기 | -
@END

@B 같은 컨텍스트를 여러 기능이 함께 읽는다. 부서 값 하나를 컨텍스트에 두면 보안 뷰, VPD, Redaction 조건이 모두 같은 근거로 동작한다.
@B 반대로 컨텍스트 값이 틀리면 여러 보안 기능이 한꺼번에 틀린다. 컨텍스트 초기화는 보안 설계에서 가장 먼저 검증할 부분이다.
@B 감사 정책의 WHEN 절은 감사 대상 여부를 정할 때 컨텍스트를 읽는다. 예를 들어 사내망 IP가 아닌 접속만 감사하는 조건을 USERENV로 표현할 수 있다.

@H3 6.2.5  프록시 인증과 컨텍스트

@B 2장의 프록시 인증으로 접속하면 SESSION_USER는 최종 사용자, PROXY_USER는 중간 계층 계정이 된다.
@B 이 구조에서는 세션이 최종 사용자 이름으로 열리므로 세션 기반 컨텍스트와 LOGON 트리거를 그대로 쓸 수 있다. 연결 풀을 쓰면서도 전역 컨텍스트 없이 사용자별 값을 유지할 수 있는 방법이다.
@B 신뢰 패키지에서 PROXY_USER가 비어 있는지 확인하면, 애플리케이션을 거친 접속과 SQL 도구로 직접 들어온 접속에 서로 다른 값을 줄 수 있다.

@H2 6.3  기본 제공 네임스페이스 USERENV

@H3 6.3.1  주요 속성

@P USERENV는 데이터베이스가 미리 만들어 둔 네임스페이스다. 컨텍스트를 만들지 않아도 모든 세션에서 바로 읽을 수 있다.

@TBL
속성 | 값 | 누가 정하나
SESSION_USER | 로그인한 데이터베이스 사용자 | 서버
CURRENT_SCHEMA | 객체 이름 해석 기준 스키마 | 세션(ALTER SESSION으로 변경 가능)
AUTHENTICATION_METHOD | PASSWORD, OS, SSL 등 | 서버
IP_ADDRESS | 클라이언트 IP. 로컬 bequeath 접속이면 비어 있음 | 서버
PROXY_USER | 프록시 인증의 중간 계층 계정(2장) | 서버
SID, SESSIONID | 세션 번호, 감사 세션 ID | 서버
CLIENT_IDENTIFIER | 애플리케이션이 붙인 최종 사용자 식별자 | 클라이언트
MODULE, ACTION | 애플리케이션 프로그램 이름, 작업 이름 | 클라이언트
@END

@B 이 밖에 OS_USER, HOST, TERMINAL(클라이언트 OS 정보), DB_NAME, SERVER_HOST, INSTANCE_NAME(서버 정보), LANG, NLS_TERRITORY(언어 설정) 등이 있다. OS_USER와 HOST는 클라이언트가 보내 주는 값이라 위조할 수 있다.
@B 보안 판단에는 SESSION_USER를 쓴다. CURRENT_SCHEMA는 `ALTER SESSION SET CURRENT_SCHEMA`로 누구나 바꿀 수 있어 사용자 식별 근거가 되지 못한다.
@B CLIENT_IDENTIFIER는 `DBMS_SESSION.SET_IDENTIFIER`, MODULE·ACTION은 `DBMS_APPLICATION_INFO`로 세션이 직접 설정한다. 별도 권한이 필요 없다.
@B 클라이언트가 설정하는 값은 추적과 감사에 유용하다. 접근 허용 여부를 이 값 하나로 결정하면 사용자가 값을 흉내 내어 우회할 수 있다.
@B USERENV에 없는 속성을 요청하면 ORA-02003: invalid USERENV parameter가 난다. 사용자가 만든 네임스페이스는 없는 속성을 요청해도 NULL을 돌려주는 것과 대조적이다.

@CODE
HR@orcl> ALTER SESSION SET CURRENT_SCHEMA = scott;
HR@orcl> SELECT SYS_CONTEXT('USERENV', 'SESSION_USER')   AS session_user,
  2         SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema
  3    FROM dual;

SESSION_USER CURRENT_SCHEMA
------------ --------------
HR           SCOTT
@END

@CASE MODULE 값만 믿은 접근 허용
급여 화면 전용 데이터를 보호하려고 "MODULE이 payroll_ui일 때만 행을 보여 준다"는 조건을 보안 뷰에 넣었다. 급여 화면 외의 도구에서는 0건이 나와 의도대로 동작하는 것처럼 보였다.
감사 중에 한 개발자가 SQL*Plus에서 `DBMS_APPLICATION_INFO.SET_MODULE('payroll_ui', NULL)`을 실행한 뒤 급여 데이터를 조회한 기록이 발견됐다. MODULE은 세션이 스스로 정하는 값이라 별도 권한 없이 바꿀 수 있었다.
조건을 "급여 애플리케이션 계정(SESSION_USER)으로 접속했고 사내 애플리케이션 서버 IP(IP_ADDRESS)에서 왔을 때"로 바꾸고, MODULE은 추적 정보로만 남겼다.
@END

@H3 6.3.2  SYS_CONTEXT 함수

@B 형식은 `SYS_CONTEXT('네임스페이스', '속성' [, 길이])`다. 반환 길이를 생략하면 256바이트까지 돌려준다. 긴 값을 다룰 때는 세 번째 인자로 최대 4000바이트까지 늘린다.
@B 네임스페이스와 속성 이름은 대소문자를 구분하지 않는다. 내부적으로 대문자로 저장된다.
@B 존재하지 않는 사용자 네임스페이스나 속성은 오류 없이 NULL이다. 철자가 틀려도 오류가 나지 않으므로, 값이 NULL로 나오면 이름부터 확인한다.
@B SQL 안에서 `SYS_CONTEXT`는 문장 실행 중 한 번 평가된 값처럼 동작한다. 같은 문장 실행 도중 값이 바뀌어도 결과에 섞이지 않는다.

@H3 6.3.3  추적과 감사에 쓰는 USERENV

@B CLIENT_IDENTIFIER, MODULE, ACTION은 V$SESSION의 같은 이름 열에 그대로 보인다. 어느 화면의 어떤 작업이 부하를 일으키는지 DBA가 바로 찾을 수 있다.
@B Unified Auditing 기록(UNIFIED_AUDIT_TRAIL)에도 CLIENT_IDENTIFIER가 남는다. 연결 풀 환경에서 DB 계정은 모두 같아도 최종 사용자를 구분할 수 있다.
@B 이 값들은 클라이언트가 정하므로 "추적 정보"로 다룬다. 감사 분석에서 CLIENT_IDENTIFIER가 비어 있거나 형식이 맞지 않는 기록은 애플리케이션을 거치지 않은 접속을 의심하는 단서가 된다.
@B 애플리케이션 프레임워크가 요청 시작 시 세 값을 모두 설정하도록 표준화하면 성능 분석, 감사, 컨텍스트 기반 접근 제어가 같은 식별자를 공유한다.

@CODE
HR@orcl> EXEC DBMS_SESSION.SET_IDENTIFIER('kim.hr')
HR@orcl> EXEC DBMS_APPLICATION_INFO.SET_MODULE('payroll_ui', 'search')
HR@orcl> SELECT SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') AS client_id,
  2         SYS_CONTEXT('USERENV', 'MODULE')            AS module,
  3         SYS_CONTEXT('USERENV', 'ACTION')            AS action
  4    FROM dual;

CLIENT_ID    MODULE       ACTION
------------ ------------ ----------
kim.hr       payroll_ui   search
@END

@H2 6.4  세션 기반 컨텍스트 만들기

@H3 6.4.1  CREATE CONTEXT와 필요한 권한

@B 컨텍스트는 `CREATE CONTEXT 네임스페이스 USING [스키마.]패키지`로 만든다. USING에 적은 패키지가 그 네임스페이스의 신뢰 패키지(trusted package)다.
@B 컨텍스트는 특정 스키마에 속하는 객체가 아니다. DB 전체에서 이름이 하나뿐이므로 `CREATE ANY CONTEXT`, `DROP ANY CONTEXT` 같은 시스템 권한으로 관리한다.
@B 패키지는 컨텍스트보다 나중에 만들어도 된다. 컨텍스트는 이름과 패키지 이름의 연결만 기록한다.
@B 같은 이름으로 다시 만들면 ORA-00955: name is already used by an existing object가 난다. `CREATE OR REPLACE CONTEXT`는 신뢰 패키지와 유형을 한 번에 바꾼다.
@B 컨텍스트와 신뢰 패키지는 업무 데이터 소유자와 다른 보안 관리 계정에 둔다. 실습에서는 `ctxadm` 계정을 쓴다.

@CODE
SYS@orcl> CREATE USER ctxadm IDENTIFIED BY oracle DEFAULT TABLESPACE users QUOTA 10M ON users;
SYS@orcl> GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE,
  2        CREATE ANY CONTEXT, DROP ANY CONTEXT TO ctxadm;
CTXADM@orcl> CREATE CONTEXT c6_task_ctx USING ctxadm.c6_task_pkg;
@END

@NOTE 원본 실습 자료와 다른 점
과정 원본 자료는 컨텍스트 패키지를 HR이나 ateam처럼 데이터를 소유한 계정에 만들고, LOGON 트리거를 ON DATABASE로 건다.
이 교안의 실습은 보안 관리 계정 ctxadm에 컨텍스트·패키지·보안 뷰를 모으고, LOGON 트리거를 실습 사용자 스키마로 한정했다. 다른 실습과 같은 DB를 쓰는 환경에서 모든 로그인에 영향을 주지 않기 위해서다.
@END

@H3 6.4.2  신뢰 패키지와 DBMS_SESSION

@B 신뢰 패키지 안에서 `DBMS_SESSION.SET_CONTEXT(네임스페이스, 속성, 값)`으로 값을 넣는다. 같은 속성에 다시 넣으면 덮어쓴다.
@B 네임스페이스와 속성은 각각 128바이트, 값은 4KB까지다. 한 네임스페이스에 넣을 수 있는 속성 수에는 제한이 없다.
@B SET_CONTEXT는 호출 스택에 신뢰 패키지가 있어야 동작한다. 사용자가 직접 호출하면 DBMS_SESSION 실행 권한이 있어도 ORA-01031: insufficient privileges가 난다.
@B 호출 스택 검사 덕분에 값을 넣는 규칙은 신뢰 패키지 코드가 결정한다. 사용자는 패키지가 허락한 방식으로만 값에 영향을 줄 수 있다.
@B `CLEAR_CONTEXT(네임스페이스, client_id, 속성)`는 특정 속성을, `CLEAR_ALL_CONTEXT(네임스페이스)`는 네임스페이스 전체를 지운다. 둘 다 신뢰 패키지 안에서만 동작한다.

@CODE
CREATE OR REPLACE PACKAGE BODY c6_task_pkg AS
  PROCEDURE set_app_user (p_user_id VARCHAR2) IS
  BEGIN
    DBMS_SESSION.SET_CONTEXT('c6_task_ctx', 'app_user', p_user_id);
  END;
  PROCEDURE clear_app_user IS
  BEGIN
    DBMS_SESSION.CLEAR_CONTEXT('c6_task_ctx', NULL, 'app_user');
  END;
END;
/
@END

@TBL
SET_CONTEXT 인자 | 의미 | 제한
namespace | 컨텍스트 이름 | 128바이트, 필수
attribute | 속성 이름 | 128바이트, 필수
value | 값 | 4KB, 필수
username | 전역 컨텍스트에서 값을 볼 DB 사용자 | 128바이트, 기본 NULL
client_id | 전역 컨텍스트에서 값을 볼 CLIENT_IDENTIFIER | 64바이트, 기본 NULL
@END

@B username과 client_id는 전역 컨텍스트에서만 의미가 있다. 세션 기반 컨텍스트에서는 값이 그 세션에만 있으므로 공개 범위를 따로 정할 필요가 없다.

@H3 6.4.3  값을 넣는 패키지 설계

@B 원본 Local context 예제는 패키지가 인자로 받은 사용자 이름을 그대로 넣는다. 애플리케이션이 이미 사용자를 인증한 뒤 데이터베이스에 알려 주는 구조다.
@B 이 구조에서는 패키지 실행 권한을 가진 계정이 아무 값이나 넣을 수 있다. 실행 권한은 애플리케이션 계정에만 주고, 일반 사용자 계정에는 주지 않는다.
@B 사용자가 직접 접속하는 환경이라면 패키지가 인자를 받지 말고 `SYS_CONTEXT('USERENV', 'SESSION_USER')`로 스스로 사용자를 확인해 값을 찾게 만든다. 6.5절의 LOGON 트리거 방식이 이것이다.
@B 패키지는 정의자 권한으로 만든다. 매핑 테이블을 읽는 권한은 패키지 소유자만 가지면 되고, 호출하는 사용자는 매핑 테이블을 볼 수 없다.

@BP 신뢰 패키지 작성 규칙
값의 근거는 서버가 채운 USERENV 속성과 보안 관리 계정 소유의 매핑 테이블에서 가져온다.
매핑에 없는 사용자, 중복 매핑 같은 예외를 모두 처리한다. 예외가 밖으로 나가면 호출한 쪽(LOGON 트리거 등)이 실패한다.
값을 지우는 프로시저를 함께 제공한다. 연결을 재사용하는 환경에서는 반납 전에 반드시 지운다.
패키지 실행 권한은 필요한 계정에만 준다. PUBLIC에 주지 않는다.
@END

@H3 6.4.4  세션 단위로 존재하는 값

@B 세션 기반 컨텍스트 값은 세션 UGA에 있다. 같은 사용자라도 다른 세션에서는 보이지 않는다.
@B 실습 02에서 USER_A를 넣은 세션은 보안 뷰에서 2건을 보지만, CONNECT로 새로 연 세션은 0건이다. 로그아웃과 함께 값도 사라진다.
@B 현재 세션의 값 목록은 SESSION_CONTEXT 뷰로 본다. 네임스페이스, 속성, 값이 한 행씩 나온다.
@B 다른 세션의 값은 DBA도 볼 수 없다. 사용자가 "데이터가 보이지 않는다"고 하면 그 사용자의 세션에서 직접 SESSION_CONTEXT를 조회하게 해야 원인을 좁힐 수 있다.

@CODE
HR@orcl> SELECT namespace, attribute, value FROM session_context;

NAMESPACE    ATTRIBUTE  VALUE
------------ ---------- --------
C6_TASK_CTX  APP_USER   USER_B
@END

@B PL/SQL 안에서 같은 목록이 필요하면 `DBMS_SESSION.LIST_CONTEXT`를 쓴다. ARPLS 기준으로 현재 세션에 설정된 (네임스페이스, 속성, 값) 목록을 AppCtxTabTyp 연관 배열로, 항목 수를 두 번째 OUT 인자로 돌려준다.
@B 신뢰 패키지에 진단용 프로시저로 넣어 두면 애플리케이션 로그에 요청 시점의 컨텍스트 상태를 남길 수 있다. 민감한 값은 6.11의 주의대로 로그에서 뺀다.

@CODE
DECLARE
  l_list DBMS_SESSION.AppCtxTabTyp;
  l_cnt  NUMBER;
BEGIN
  DBMS_SESSION.LIST_CONTEXT(l_list, l_cnt);
  FOR i IN 1 .. l_cnt LOOP
    DBMS_OUTPUT.PUT_LINE(l_list(i).namespace || '.' || l_list(i).attribute || ' = ' || l_list(i).value);
  END LOOP;
END;
/
@END

@H3 6.4.5  속성 여러 개를 한 네임스페이스에

@B 네임스페이스 하나에 속성을 여러 개 둘 수 있다. 부서, 직무, 관리자 여부를 한 번의 조회로 찾아 함께 넣으면 정책마다 별도 컨텍스트를 만들 필요가 없다.
@B 속성 이름은 사용처가 읽기 쉬운 이름으로 정한다. 보안 뷰와 VPD 함수가 `SYS_CONTEXT('emp_ctx', 'is_manager')`처럼 의미가 드러나는 이름을 읽게 한다.
@B 속성 하나를 바꾸는 프로시저와 전체를 다시 계산하는 프로시저를 나눠 두면, 부서 이동처럼 일부만 바뀌는 상황에 대응하기 쉽다.

@CODE
PROCEDURE set_all IS
  v_dept  hr.employees.department_id%TYPE;
  v_job   hr.employees.job_id%TYPE;
  v_mgr   NUMBER;
BEGIN
  SELECT e.department_id, e.job_id,
         (SELECT COUNT(*) FROM hr.employees s WHERE s.manager_id = e.employee_id)
    INTO v_dept, v_job, v_mgr
    FROM hr.employees e JOIN c6_user_map m ON e.email = m.email
   WHERE m.username = SYS_CONTEXT('USERENV', 'SESSION_USER');
  DBMS_SESSION.SET_CONTEXT('c6_emp_ctx', 'dept_id', v_dept);
  DBMS_SESSION.SET_CONTEXT('c6_emp_ctx', 'job_id', v_job);
  DBMS_SESSION.SET_CONTEXT('c6_emp_ctx', 'is_manager', CASE WHEN v_mgr > 0 THEN 'Y' ELSE 'N' END);
EXCEPTION
  WHEN NO_DATA_FOUND THEN NULL;
END;
@END

@B 관리자 여부처럼 Y/N으로 판단하는 값은 NULL과 N을 구분한다. 값이 없을 때 권한이 넓어지는 방향으로 해석되지 않도록, 읽는 쪽은 'Y'일 때만 허용하는 조건으로 쓴다.

@H2 6.5  LOGON 트리거로 초기화

@H3 6.5.1  로그인 시점에 값 채우기

@P 사용자에게 값을 넣을 기회를 주지 않으려면 로그인 직후 데이터베이스가 직접 값을 채워야 한다. LOGON 트리거가 신뢰 패키지를 호출하는 구조가 가장 흔하다.

@TBL
순서 | 동작
1 | 사용자가 로그인 인증을 통과
2 | AFTER LOGON 트리거가 실행되어 신뢰 패키지 호출
3 | 패키지가 SESSION_USER로 매핑 테이블을 조회해 부서를 찾음
4 | SET_CONTEXT로 세션 컨텍스트에 부서 기록
5 | 사용자의 첫 SQL부터 보안 뷰·VPD가 그 값을 사용
@END

@CODE
CREATE OR REPLACE PACKAGE BODY c6_emp_pkg AS
  PROCEDURE set_department IS
    v_dept hr.employees.department_id%TYPE;
  BEGIN
    SELECT e.department_id INTO v_dept
      FROM hr.employees e JOIN c6_user_map m ON e.email = m.email
     WHERE m.username = SYS_CONTEXT('USERENV', 'SESSION_USER');
    DBMS_SESSION.SET_CONTEXT('c6_emp_ctx', 'dept_id', v_dept);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END;
END;
/
CREATE OR REPLACE TRIGGER ctxadm.c6_king_logon AFTER LOGON ON c6_king.SCHEMA
BEGIN
  ctxadm.c6_emp_pkg.set_department;
END;
/
@END

@B 원본은 사원 EMAIL이 로그인 이름과 같다고 가정한다. 운영에서는 로그인 이름과 업무 속성을 잇는 매핑 테이블을 따로 두는 편이 관리하기 쉽다.
@B 매핑 테이블을 고칠 수 있는 사람이 곧 모든 사용자의 부서를 정하는 사람이다. 소유자는 보안 관리 계정이고, 변경은 감사한다.

@H3 6.5.2  트리거 범위 — DATABASE와 SCHEMA

@B `AFTER LOGON ON DATABASE`는 모든 사용자의 로그인마다 실행된다. 컨텍스트를 모든 사용자에게 적용할 때 쓰며 `ADMINISTER DATABASE TRIGGER` 권한이 필요하다.
@B `AFTER LOGON ON 사용자.SCHEMA`는 그 사용자의 로그인에만 실행된다. 특정 업무 계정에만 컨텍스트가 필요할 때 범위를 좁힐 수 있다.
@B 다른 사용자 스키마에 트리거를 걸려면 `CREATE ANY TRIGGER`가 필요하다. 실습에서는 SYS가 ctxadm 소유로 사용자별 트리거를 만들었다.
@B 트리거가 하는 일이 많을수록 로그인이 느려진다. 트리거에서는 신뢰 패키지 호출 하나만 하고, 무거운 조회는 피한다.

@H3 6.5.3  트리거 오류는 로그인 장애가 된다

@B LOGON 트리거 안에서 처리되지 않은 예외가 발생하면 로그인이 거부된다. 실습 03에서 매핑이 없는 c6_nomap 사용자는 ORA-04088과 ORA-01403을 받고 접속하지 못했다.
@B ON DATABASE 트리거라면 같은 오류가 매핑에 없는 모든 사용자에게 일어난다. 패키지가 INVALID가 되거나 매핑 테이블이 잠겨도 마찬가지다.
@B `ADMINISTER DATABASE TRIGGER` 권한을 가진 사용자(DBA 등)는 LOGON 트리거가 실패해도 로그인된다. 장애 때 DBA가 들어가 트리거를 고칠 수 있는 통로다.
@B 그래서 신뢰 패키지는 예상 가능한 예외를 모두 처리하고, 값이 없을 때는 컨텍스트를 비워 둔 채 끝내야 한다. 비어 있는 컨텍스트는 보안 뷰와 VPD에서 0건으로 이어지므로 안전한 쪽으로 닫힌다.

@CODE
SQL> CONNECT c6_nomap/oracle
ERROR:
ORA-04088: error during execution of trigger 'CTXADM.C6_NOMAP_LOGON'
ORA-01403: no data found
ORA-06512: at "CTXADM.C6_EMP_PKG", line 5
@END

@CASE 배포 직후 신규 입사자만 로그인하지 못한다
부서별 데이터 접근 제어를 도입하면서 LOGON ON DATABASE 트리거와 컨텍스트 패키지를 배포했다. 기존 직원은 문제없었지만 그날 계정을 받은 신규 입사자 전원이 로그인 단계에서 ORA-04088을 받았다.
원인은 신규 입사자가 아직 인사 매핑 테이블에 들어 있지 않아 패키지의 SELECT INTO가 NO_DATA_FOUND를 낸 데 있었다. 패키지에 예외 처리가 없었다.
DBA 계정은 ADMINISTER DATABASE TRIGGER 권한 덕분에 접속할 수 있었다. 패키지에 예외 처리를 넣어 다시 컴파일하자 신규 입사자도 로그인됐고, 매핑이 등록되기 전까지는 보안 뷰에서 0건을 보게 됐다.
@END

@H3 6.5.4  트리거 초기화와 애플리케이션 초기화

@TBL
방식 | 값을 넣는 주체 | 적합한 환경
LOGON 트리거 | 데이터베이스(로그인 직후 자동) | 사용자마다 DB 계정이 있는 전용 접속
애플리케이션 호출 | 애플리케이션 코드가 신뢰 패키지 호출 | 애플리케이션이 사용자를 인증하는 구조
INITIALIZED EXTERNALLY | OCI 클라이언트의 접속 처리 | OCI 기반 클라이언트
INITIALIZED GLOBALLY | 디렉터리 서버의 사용자 속성 | 엔터프라이즈 사용자(LDAP)
@END

@B LOGON 트리거는 사용자가 관여할 틈이 없다는 장점이 있지만, 연결 풀처럼 세션 하나를 여러 사용자가 돌려 쓰는 환경에서는 로그인이 한 번뿐이라 맞지 않는다.
@B 애플리케이션 호출 방식은 애플리케이션이 이미 사용자를 인증했다고 믿는 구조다. 신뢰 패키지 실행 권한을 애플리케이션 계정에만 주어야 의미가 있다.
@B 두 방식을 섞을 수 있다. 전용 접속 사용자는 트리거로, 애플리케이션 경유 사용자는 애플리케이션 호출로 같은 네임스페이스를 채우되, 신뢰 패키지 안에서 PROXY_USER나 SESSION_USER를 보고 경로를 구분한다.

@H3 6.5.5  원본 예제와 교안 실습의 차이

@TBL
항목 | 원본 강의 자료 | 이 교안의 실습
컨텍스트·패키지 소유자 | HR(데이터 소유자) | ctxadm(보안 관리 계정)
사용자 식별 | EMAIL = SESSION_USER 가정 | 로그인 이름과 EMAIL 매핑 테이블
LOGON 트리거 범위 | ON DATABASE | 실습 사용자별 ON 사용자.SCHEMA
예외 처리 | NO_DATA_FOUND 처리 | 처음엔 빼서 장애를 재현한 뒤 추가
보안 뷰 권한 | PUBLIC | 실습 사용자에게만
@END

@B 원본 구조도 동작은 한다. 데이터 소유자가 패키지를 고쳐 자기 제한을 풀 수 있고, ON DATABASE 트리거가 모든 로그인에 영향을 준다는 점이 운영에서 문제가 된다.
@B 보안 뷰를 PUBLIC에 주면 컨텍스트가 비어 있는 모든 계정도 뷰에 접근한다. 결과는 0건이지만, 권한은 필요한 계정에만 주는 원칙에 맞춰 범위를 좁힌다.

@H2 6.6  컨텍스트를 쓰는 보안 뷰

@H3 6.6.1  뷰의 WHERE 절에 SYS_CONTEXT

@B 컨텍스트 값을 WHERE 절에 넣은 뷰를 만들고, 사용자에게는 원본 테이블이 아닌 뷰 권한만 준다. 원본 강의 자료의 secure_employees가 이 방식이다.
@B 같은 뷰가 세션의 컨텍스트 값에 따라 다른 행을 돌려준다. 부서마다 뷰를 따로 만들 필요가 없다.
@B 컨텍스트가 비어 있으면 `department_id = NULL`이 되어 0건이다. 별도 처리 없이도 값이 없을 때 닫힌다.

@CODE
CREATE OR REPLACE VIEW c6_secure_emp AS
  SELECT employee_id, first_name, department_id
    FROM hr.employees
   WHERE department_id = SYS_CONTEXT('c6_emp_ctx', 'dept_id');
GRANT SELECT ON c6_secure_emp TO c6_king, c6_hunold, c6_nomap;
@END

@H3 6.6.2  보안 뷰와 VPD

@TBL
항목 | 보안 뷰 | VPD(7장)
조건 위치 | 뷰 정의 | 테이블에 걸린 정책 함수
원본 테이블 권한이 있는 사용자 | 조건 없이 전체 조회 가능 | 원본 테이블에도 조건이 붙음
조건 변경 | 뷰 재정의 | 정책 함수 수정
DML 제어 | WITH CHECK OPTION | statement_types, update_check
라이선스 | 모든 에디션 | Enterprise Edition
@END

@B 보안 뷰는 단순하고 결과를 예측하기 쉽다. 사용자가 원본 테이블 권한을 갖지 않는 구조라면 충분하다.
@B 원본 테이블 권한을 가진 계정이 여럿이거나 애플리케이션이 테이블을 직접 참조한다면 VPD가 맞다. 두 방식 모두 컨텍스트를 같은 방식으로 읽으므로, 컨텍스트 설계는 그대로 두고 적용 방식만 바꿀 수 있다.
@B 뷰 소유자는 원본 테이블에 대한 `SELECT ... WITH GRANT OPTION`이 있어야 다른 사용자에게 뷰 권한을 줄 수 있다. 실습의 ctxadm도 HR.EMPLOYEES 권한을 이렇게 받았다.

@H3 6.6.3  보안 뷰를 통한 DML

@B 단순 보안 뷰는 갱신 가능 뷰라 INSERT, UPDATE, DELETE도 뷰를 통해 할 수 있다. 보이는 행만 UPDATE·DELETE 대상이 된다.
@B INSERT와 UPDATE는 뷰 조건을 벗어나는 행을 만들 수 있다. 다른 부서 번호로 행을 넣으면 넣은 사람에게도 보이지 않는 행이 생긴다.
@B 뷰에 WITH CHECK OPTION을 붙이면 뷰 조건을 벗어나는 변경이 ORA-01402: view WITH CHECK OPTION where-clause violation으로 거부된다. VPD의 update_check와 같은 역할이다.
@B 조회 전용이 목적이라면 WITH READ ONLY로 만들어 DML 자체를 막는다.

@CODE
CREATE OR REPLACE VIEW c6_secure_emp AS
  SELECT employee_id, first_name, department_id
    FROM hr.employees
   WHERE department_id = SYS_CONTEXT('c6_emp_ctx', 'dept_id')
  WITH READ ONLY;
@END

@H3 6.6.4  보안 뷰의 성능

@B SYS_CONTEXT는 실행 시점에 한 번 평가되는 상수처럼 취급된다. 옵티마이저는 `department_id = SYS_CONTEXT(...)`를 바인드 변수 조건처럼 다뤄 인덱스를 쓸 수 있다.
@B 값이 바뀌어도 SQL 문장은 같으므로 커서를 공유한다. 부서마다 다른 리터럴 SQL을 만드는 방식보다 공유 풀 부담이 작다.
@B 컨텍스트 값은 문자열이다. 숫자 컬럼과 비교하면 값 쪽이 숫자로 변환되므로 숫자 컬럼의 인덱스는 그대로 쓸 수 있다. 반대로 문자 컬럼에 숫자 함수를 씌우는 식으로 비교하면 인덱스를 쓰지 못한다.

@B SET_CONTEXT는 값을 문자열로 저장한다. 부서 번호 90은 '90'으로 들어간다.
@B 숫자 컬럼과 비교할 때는 자동 변환으로 문제가 없지만, 앞에 0이 붙은 코드('090')나 날짜를 넣을 때는 형식이 어긋나 0건이 나오기 쉽다. 신뢰 패키지에서 TO_CHAR 형식을 명시해 넣고, 읽는 쪽도 같은 형식으로 변환한다.

@H2 6.7  전역 접근 컨텍스트

@H3 6.7.1  ACCESSED GLOBALLY와 SGA

@B `CREATE CONTEXT ... USING 패키지 ACCESSED GLOBALLY`로 만든 컨텍스트는 값을 SGA에 저장한다. 세션이 끝나도 값이 남고, 조건에 맞는 다른 세션이 그 값을 읽는다.
@B 연결 풀을 쓰는 3계층 애플리케이션을 위한 구조다. 최종 사용자는 애플리케이션에 로그인하고, 애플리케이션은 하나의 DB 계정으로 미리 열어 둔 세션들을 돌려 쓴다.
@B 사용자 속성을 요청마다 다시 계산하지 않고, 한 번 SGA에 올려 두면 어느 풀 세션에서든 읽을 수 있다.
@B 값은 인스턴스 메모리에 있으므로 인스턴스를 재기동하면 사라진다. 애플리케이션은 기동 후 필요한 값을 다시 초기화해야 한다.
@B RAC 환경에서도 전역 컨텍스트 값은 인스턴스 사이에서 접근할 수 있다(매뉴얼의 Global Application Contexts 절).

@H3 6.7.2  username·client_id가 정하는 공개 범위

@P 전역 컨텍스트의 값을 볼 수 있는 세션은 SET_CONTEXT를 호출할 때 준 username, client_id 인자로 정해진다. ARPLS의 DBMS_SESSION 사용 노트는 두 인자를 생략하면 NULL로 간주되어 모든 사용자가 값을 본다고 적고 있다.

@TBL
username | client_id | 값을 읽을 수 있는 세션
NULL | NULL | 모든 세션
지정 | NULL | 그 DB 사용자로 접속한 모든 세션
NULL | 지정 | CLIENT_IDENTIFIER가 같은 모든 세션(DB 사용자 무관)
지정 | 지정 | 그 DB 사용자이면서 CLIENT_IDENTIFIER가 같은 세션
@END

@B 원본 강의 자료의 전역 컨텍스트 예제는 두 인자 없이 값을 넣는다. 실습 04에서 c6_king이 90을 넣자, 아무것도 하지 않은 c6_hunold와 매핑도 없는 c6_nomap이 90을 읽었다. 나중에 c6_hunold가 60을 넣자 c6_king도 60을 봤다.
@B LOGON 트리거로 사용자마다 이런 전역 값을 넣으면 마지막에 로그인한 사용자의 속성이 모두에게 적용된다. 전역 컨텍스트에서는 username과 client_id 중 최소 하나는 반드시 지정한다.

@CASE 마지막 로그인 사용자의 부서가 모두에게 보인다
세션 기반 컨텍스트로 운영하던 부서 제한을 "RAC에서도 쓰기 위해" ACCESSED GLOBALLY로 바꿨다. 신뢰 패키지와 LOGON 트리거는 손대지 않았다.
이후 사용자들이 간헐적으로 다른 부서 데이터를 본다는 신고가 들어왔다. 재현해 보니 화면에 보이는 부서가 직전에 로그인한 사람의 부서였다.
SET_CONTEXT에 username, client_id가 없어 SGA의 값 하나를 모든 세션이 공유하고 있었다. 전용 접속 구조라 전역 컨텍스트가 필요 없었으므로 ACCESSED LOCALLY로 되돌렸다. 컨텍스트 유형 변경도 코드 변경과 같은 검토 대상으로 넣었다.
@END

@H3 6.7.3  연결 풀 모델과 CLIENT_IDENTIFIER

@B 애플리케이션 서버는 DB 계정 하나(실습의 c6_apppool)로 풀을 만든다. 최종 사용자를 구분하는 값은 CLIENT_IDENTIFIER다.
@B 사용자가 애플리케이션에 로그인하면, 애플리케이션이 신뢰 패키지를 호출해 `username => 'C6_APPPOOL', client_id => 사용자ID`로 속성을 SGA에 넣는다. 이 초기화는 사용자당 한 번이다.
@B 요청을 처리할 때마다 풀에서 세션을 빌려 `DBMS_SESSION.SET_IDENTIFIER(사용자ID)`를 호출한다. 그 세션의 SYS_CONTEXT는 해당 사용자의 값을 돌려준다.
@B 요청이 끝나면 `DBMS_SESSION.CLEAR_IDENTIFIER`로 식별자를 지우고 세션을 반납한다. 지우지 않으면 다음 요청이 앞 사용자의 권한으로 데이터를 본다.
@B username을 함께 지정했기 때문에 다른 DB 계정이 같은 식별자를 흉내 내도 값을 읽을 수 없다. 실습 04에서 c6_king이 SKING 식별자를 설정했지만 NULL을 받았다.

@CODE
DBMS_SESSION.SET_CONTEXT('c6_pool_ctx', 'dept_id', v_dept,
                         username  => 'C6_APPPOOL',
                         client_id => p_client_id);

C6_APPPOOL@orcl> EXEC DBMS_SESSION.SET_IDENTIFIER('SKING')
C6_APPPOOL@orcl> SELECT SYS_CONTEXT('c6_pool_ctx', 'dept_id') AS dept FROM dual;

DEPT
------
90
@END

@B CLIENT_IDENTIFIER는 최대 64바이트이며 넘는 부분은 잘린다. 감사 기록(UNIFIED_AUDIT_TRAIL의 CLIENT_IDENTIFIER 열)에도 남으므로, 연결 풀 환경에서 최종 사용자를 추적하는 근거가 된다.
@B ARPLS는 client_id가 대소문자를 구분한다고 적고 있다. 19.3 실습에서는 SKING으로 넣은 값을 sking 식별자로도 읽었다. 버전에 따라 다를 수 있는 동작에 기대지 말고 식별자 표기를 한 가지로 통일한다.

@B 애플리케이션이 매 요청마다 DBMS_SESSION.SET_IDENTIFIER를 별도 호출로 보내면 서버 왕복이 하나 늘어난다.
@B JDBC의 end-to-end metrics(setClientInfo의 OCSID.CLIENTID)나 OCI 속성으로 식별자를 지정하면 다음 SQL 호출에 실려 함께 전달되어 왕복이 늘지 않는다. 어느 방식이든 서버 쪽에서 보이는 값은 USERENV의 CLIENT_IDENTIFIER로 같다.

@BP 연결 풀에서 컨텍스트 쓰기
전역 컨텍스트 값은 username(풀 계정)과 client_id(최종 사용자)를 모두 지정해 넣는다.
요청 시작 시 SET_IDENTIFIER, 요청 종료 시 CLEAR_IDENTIFIER를 애플리케이션 프레임워크의 공통 코드에 넣는다. 화면마다 개발자가 넣게 하면 반드시 빠지는 곳이 생긴다.
풀 계정의 비밀번호는 애플리케이션 서버만 알게 하고, 풀 계정으로 직접 SQL 도구에 접속하는 것을 막는다. 풀 계정은 식별자를 마음대로 바꿀 수 있기 때문이다.
사용자 로그아웃 때 해당 client_id의 전역 값을 신뢰 패키지로 지운다.
@END

@CASE 오후마다 다른 사람 화면이 섞인다
연결 풀 기반 웹 애플리케이션에서 일부 사용자가 가끔 다른 직원의 부서 데이터를 본다는 신고가 들어왔다. 재현은 어려웠고 오후 혼잡 시간에 주로 발생했다.
애플리케이션 로그를 보니 예외가 발생한 요청에서 CLEAR_IDENTIFIER가 호출되지 않은 채 세션이 반납되고 있었다. 정상 종료 경로에만 정리 코드가 있었기 때문이다.
그 세션을 다음에 받은 요청이 SET_IDENTIFIER를 호출하기 전에 첫 조회를 하면, 앞 사용자의 식별자로 컨텍스트 값을 읽었다. 요청 시작 시 먼저 CLEAR_IDENTIFIER를 하고 SET_IDENTIFIER를 하도록 순서를 바꾸고, 정리 코드를 finally 블록으로 옮겨 해결했다.
@END

@H3 6.7.4  전역 값 지우기

@B 신뢰 패키지 안에서 `CLEAR_CONTEXT(네임스페이스, client_id, 속성)`로 특정 사용자의 값을, `CLEAR_ALL_CONTEXT(네임스페이스)`로 전체를 지운다.
@B 인스턴스 전체의 전역 컨텍스트 값을 한 번에 비우려면 `ALTER SYSTEM FLUSH GLOBAL CONTEXT`를 쓴다. ALTER SYSTEM 권한이 필요하며 일반 사용자는 ORA-01031을 받는다.

@NOTE FLUSH 문법 표기
19c Security Guide의 Global Application Contexts 절은 이 문장을 `ALTER SYSTEM FLUSH GLOBAL_CONTEXT`로 적고 있다. 19.3에서 밑줄 표기로 실행하면 ORA-02000(missing ... GLOBAL CONTEXT ... keyword)이 난다.
오류 메시지가 알려 주는 대로 `FLUSH GLOBAL CONTEXT`(공백)로 실행해야 한다. 같은 이름의 데이터 딕셔너리 뷰 GLOBAL_CONTEXT는 밑줄을 쓴다.
@END

@H3 6.7.5  세션 기반과 전역 중 고르기

@TBL
질문 | 세션 기반(LOCALLY) | 전역(GLOBALLY)
사용자마다 DB 계정으로 직접 접속하는가 | 적합 | 불필요
하나의 풀 계정을 여러 사용자가 돌려 쓰는가 | 요청마다 다시 설정해야 함 | 적합(client_id)
값 초기화 비용이 큰가 | 세션마다 반복 | 사용자당 한 번
값이 세션 사이에 새면 안 되는가 | 구조적으로 안전 | username·client_id 설계에 의존
인스턴스 재기동 후 | 새 로그인 때 자동 초기화 | 애플리케이션이 다시 초기화
@END

@B 판단이 애매하면 세션 기반을 고른다. 값이 새는 사고는 구조적으로 일어나지 않는다.
@B 전역 컨텍스트는 연결 풀과 높은 초기화 비용이라는 두 조건이 겹칠 때 쓴다. 이때 username과 client_id 지정, 요청 단위 식별자 관리가 함께 따라와야 한다.

@H2 6.8  클라이언트 세션 기반 컨텍스트와 외부 초기화

@B 클라이언트 세션 기반 컨텍스트는 예약 네임스페이스 CLIENTCONTEXT를 쓴다. OCI 클라이언트가 서버 왕복 없이 값을 설정해 두면 다음 호출 때 서버로 함께 전달된다.
@B 신뢰 패키지 검사를 거치지 않으므로 클라이언트가 원하는 값을 넣을 수 있다. 성능을 위한 부가 정보 전달에 쓰고, 보안 판단의 근거로 쓰지 않는다.
@B `CREATE CONTEXT ... INITIALIZED EXTERNALLY`는 OCI 애플리케이션이 접속 시점에 값을 넣는 세션 기반 컨텍스트다. 값은 그 뒤 신뢰 패키지로만 바꿀 수 있다.
@B `CREATE CONTEXT ... INITIALIZED GLOBALLY`는 엔터프라이즈 사용자 로그인 때 디렉터리 서버(LDAP)에 저장된 속성으로 값을 채운다. 원본 자료의 "LDAP으로 가능"이 이 방식을 가리킨다.
@B 세 방식 모두 값을 읽는 쪽은 똑같이 SYS_CONTEXT를 쓴다. 값을 넣는 주체와 신뢰 수준이 다를 뿐이다.
@B 신뢰 수준은 데이터베이스 안의 신뢰 패키지, 디렉터리 서버(INITIALIZED GLOBALLY), OCI 접속 초기화(INITIALIZED EXTERNALLY), CLIENTCONTEXT 순으로 낮아진다. 보안 판단에 쓰는 값은 앞의 두 가지로 채운다.

@H2 6.9  컨텍스트 관리와 데이터 딕셔너리 뷰

@H3 6.9.1  정의 변경과 삭제

@B `CREATE OR REPLACE CONTEXT`는 신뢰 패키지와 유형을 바꾼다. 실습 05에서 C6_TASK_CTX를 ACCESSED GLOBALLY로 바꾸자, 패키지와 뷰를 그대로 둔 채로 값이 세션을 넘어 공유됐다.
@B 유형 변경은 코드 변경 없이 보안 동작을 바꾼다. 변경 전에 그 컨텍스트를 읽는 뷰, VPD 정책 함수, 트리거 목록을 확인한다.
@B `DROP CONTEXT`로 삭제한다. 컨텍스트는 스키마 객체가 아니므로 소유 계정을 지울 때 따로 지운다.
@B 컨텍스트를 지워도 그 컨텍스트를 읽는 뷰와 함수는 INVALID가 되지 않는다. SYS_CONTEXT가 NULL을 돌려주므로 결과가 조용히 0건이 된다.

@H3 6.9.2  데이터 딕셔너리 뷰

@TBL
뷰 | 내용
DBA_CONTEXT, ALL_CONTEXT | 네임스페이스, 신뢰 패키지 스키마·이름, 유형(ACCESSED LOCALLY 등)
SESSION_CONTEXT | 현재 세션에 설정된 세션 기반 컨텍스트 값
V$CONTEXT | 현재 세션의 컨텍스트 속성과 값
GLOBAL_CONTEXT | 전역 컨텍스트 값 중 현재 세션이 볼 수 있는 것
@END

@B GLOBAL_CONTEXT는 이름과 달리 전역 값 전체를 보여 주지 않는다. 실습 04에서 SYS로 조회해도, 식별자를 설정하지 않은 c6_apppool로 조회해도 0건이었고, 식별자를 SKING으로 맞춘 뒤에야 그 사용자 값 한 행이 보였다.
@B 따라서 전역 값이 제대로 들어갔는지 확인하려면 풀 계정 세션에서 식별자를 바꿔 가며 조회한다.

@CODE
SYS@orcl> SELECT namespace, schema, package, type FROM dba_context WHERE namespace LIKE 'C6%';

C6_APPPOOL@orcl> EXEC DBMS_SESSION.SET_IDENTIFIER('SKING')
C6_APPPOOL@orcl> SELECT namespace, attribute, value, username, client_identifier
  2    FROM global_context WHERE namespace LIKE 'C6%';

NAMESPACE    ATTRIBUT VALUE  USERNAME    CLIENT_IDENTIFIER
------------ -------- ------ ----------- -----------------
C6_POOL_CTX  DEPT_ID  90     C6_APPPOOL  SKING
@END

@H3 6.9.3  점검 쿼리

@B 신뢰 패키지가 실제로 있고 VALID인지 컨텍스트 정의와 함께 확인한다. 패키지가 없거나 INVALID면 값을 넣는 모든 경로가 실패한다.
@B 신뢰 패키지 실행 권한을 가진 계정은 컨텍스트 값에 영향을 줄 수 있으므로 권한 보유자 목록을 함께 본다.

@CODE
SELECT c.namespace, c.schema, c.package, c.type, o.status
  FROM dba_context c
  LEFT JOIN dba_objects o
    ON o.owner = c.schema AND o.object_name = c.package AND o.object_type = 'PACKAGE BODY'
 WHERE c.schema NOT IN ('SYS', 'CTXSYS', 'LBACSYS', 'XDB');

SELECT grantee, owner, table_name AS package
  FROM dba_tab_privs
 WHERE privilege = 'EXECUTE'
   AND (owner, table_name) IN (SELECT schema, package FROM dba_context);
@END

@B 첫 쿼리에서 STATUS가 비어 있으면 패키지 본문이 없는 것이다. 실습 02처럼 컨텍스트를 먼저 만든 상태가 그대로 남아 있는 경우다.

@B DBA_CONTEXT의 신뢰 패키지가 모두 존재하고 VALID인지 본다.
@B 신뢰 패키지 실행 권한 보유자와 연결 풀 계정 목록을 확인한다.
@B LOGON 트리거 목록(DBA_TRIGGERS의 TRIGGERING_EVENT가 LOGON)과 그 상태를 확인한다.
@B 매핑 테이블과 인사 정보의 불일치(퇴사자, 부서 이동)를 대조한다.

@H3 6.9.4  자주 만나는 오류와 진단

@TBL
오류 | 상황 | 확인할 것
ORA-02003 | USERENV에 없는 속성을 SYS_CONTEXT로 요청 | 속성 철자. 사용자 네임스페이스라면 오류 없이 NULL
ORA-01031 (SYS.DBMS_SESSION) | 신뢰 패키지 밖에서 SET_CONTEXT·CLEAR_ALL_CONTEXT 호출 | DBA_CONTEXT의 SCHEMA·PACKAGE와 실제 호출 경로
ORA-04088 + ORA-01403 | LOGON 트리거가 부른 패키지에서 NO_DATA_FOUND | 매핑 없는 사용자에 대한 예외 처리
ORA-00955 | 이미 있는 이름으로 CREATE CONTEXT | DBA_CONTEXT. 바꾸려면 CREATE OR REPLACE
ORA-02000 | FLUSH GLOBAL_CONTEXT(밑줄)로 실행 | FLUSH GLOBAL CONTEXT(공백)
오류 없이 0건 | 값이 NULL이라 보안 뷰 조건이 거짓 | SESSION_CONTEXT, 네임스페이스 철자, 컨텍스트 삭제 여부
@END

@B ORA-01031 아래 ORA-06512가 SYS.DBMS_SESSION을 가리키면 객체 권한 문제로 볼 일이 아니다. 호출 스택에 신뢰 패키지가 없다는 신호다. 컨텍스트를 만든 뒤 패키지 이름을 바꿨거나 USING 절의 스키마를 틀린 경우가 흔하다.
@B 마지막 행이 가장 진단하기 어렵다. 오류 코드가 없어 애플리케이션은 "데이터 없음"으로 처리하므로, 사용자 신고가 들어오면 해당 세션의 SESSION_CONTEXT부터 확인한다.
@B ORA-04088은 로그인 단계에서 나므로 사용자는 SQL을 하나도 실행하지 못한다. 트리거 이름이 메시지에 나오므로 DBA_TRIGGERS에서 그 트리거가 부르는 패키지를 찾아 예외 처리부터 본다.

@H2 6.10  설계와 적용 절차

@TBL
단계 | 작업 | 확인할 것
1 | 보안 관리 계정 생성 | CREATE ANY CONTEXT, CREATE PROCEDURE, 필요한 테이블 권한
2 | 사용자 속성 매핑 준비 | 매핑 테이블 소유자와 변경 감사
3 | 컨텍스트 유형 결정 | 전용 접속이면 LOCALLY, 연결 풀이면 GLOBALLY + client_id
4 | 컨텍스트 생성 | DBA_CONTEXT의 신뢰 패키지 이름 철자
5 | 신뢰 패키지 작성 | 예외 처리, 값 지우기 프로시저
6 | 초기화 경로 구성 | LOGON 트리거 범위 또는 애플리케이션 초기화 코드
7 | 값 사용처 연결 | 보안 뷰, VPD 정책 함수(7장)
8 | 시험 | 매핑된 사용자, 매핑 없는 사용자, 식별자 없는 세션
@END

@B 4단계 전에 5단계 패키지를 만들 필요는 없지만, 6단계의 트리거는 반드시 패키지가 정상 컴파일된 뒤에 만든다. 순서가 바뀌면 트리거가 INVALID 패키지를 호출해 로그인이 막힌다.
@B 8단계의 "매핑 없는 사용자" 시험을 빼먹기 쉽다. 신규 계정, 서비스 계정, 배치 계정으로 반드시 로그인해 본다.
@B 전역 컨텍스트를 쓴다면 8단계에 "식별자 없는 세션"과 "다른 DB 계정이 같은 식별자를 쓰는 세션"을 추가한다. 둘 다 값이 보이지 않아야 한다.
@B 운영 반영 후에는 SESSION_CONTEXT와 GLOBAL_CONTEXT 조회를 장애 대응 절차서에 넣어 둔다.

@H2 6.11  운영 시 주의점

@B LOGON 트리거와 신뢰 패키지를 변경할 때는 ADMINISTER DATABASE TRIGGER 권한이 있는 세션을 하나 열어 둔 채 작업한다. 변경이 잘못되면 그 세션으로 되돌린다.
@B 매핑 테이블은 인사 시스템과 동기화한다. 부서 이동이 반영되지 않으면 이동한 직원은 이전 부서 데이터를 계속 보게 된다.
@B 컨텍스트 값은 로그인 시점에 정해지므로, 매핑을 바꿔도 이미 접속한 세션에는 반영되지 않는다. 즉시 반영이 필요하면 해당 사용자의 세션을 정리한다.
@B 전역 컨텍스트는 인스턴스 재기동으로 값이 사라진다. 기동 후 애플리케이션이 다시 초기화하는지 장애 복구 절차에 포함한다.
@B 연결 풀 계정과 신뢰 패키지 실행 권한을 가진 계정 목록을 정기적으로 점검한다. 이 계정들은 컨텍스트 값에 직접 영향을 줄 수 있다.
@B 컨텍스트 이름은 DB 전체에서 하나다. 여러 애플리케이션이 한 DB를 쓰면 이름 앞에 애플리케이션 접두어를 붙여 충돌을 막는다.
@B Data Pump로 스키마를 옮길 때 컨텍스트 정의는 스키마 단위 작업에 포함되지 않는다. 대상 DB에서 CREATE CONTEXT를 따로 실행하는 절차를 이관 계획에 넣는다.
@B 신뢰 패키지를 재컴파일하는 동안에는 그 패키지를 호출하는 LOGON 트리거가 잠시 대기하거나 실패할 수 있다. 패키지 변경은 접속이 적은 시간에 하고, 변경 직후 일반 계정으로 로그인 시험을 한다.
@B 컨텍스트 값은 로그에 남기지 않는다. 부서 번호 정도는 괜찮지만, 권한 등급이나 개인 식별 정보를 컨텍스트에 넣었다면 애플리케이션 디버그 로그로 새어 나가지 않게 한다.

@H2 6.12  요약

@B 애플리케이션 컨텍스트는 네임스페이스·속성·값으로 이루어진 메모리 영역이며 SYS_CONTEXT로 읽는다. 값은 지정된 신뢰 패키지만 넣을 수 있다.
@B USERENV는 기본 제공 네임스페이스다. SESSION_USER처럼 서버가 채우는 값은 보안 판단에, CLIENT_IDENTIFIER·MODULE처럼 클라이언트가 바꾸는 값은 추적에 쓴다. 없는 속성은 ORA-02003이다.
@B 세션 기반 컨텍스트는 세션 UGA에 있고 그 세션에서만 보인다. 신뢰 패키지 밖에서 SET_CONTEXT를 부르면 ORA-01031이다.
@B LOGON 트리거로 로그인 시 값을 채우면 사용자가 값을 정할 수 없다. 트리거 안의 처리되지 않은 예외는 ORA-04088로 로그인을 막는다.
@B 보안 뷰는 컨텍스트 값을 WHERE 절에 넣어 행을 거르며, 원본 테이블 권한을 주지 않는 구조에서 쓴다. 원본 테이블까지 보호하려면 VPD를 쓴다.
@B 전역 컨텍스트는 SGA에 값을 두고 username·client_id로 공개 범위를 정한다. 둘 다 생략하면 모든 세션이 값을 공유한다.
@B 연결 풀 모델은 풀 계정 + CLIENT_IDENTIFIER로 최종 사용자를 구분하며, 요청마다 SET_IDENTIFIER와 CLEAR_IDENTIFIER를 짝지어 호출한다.
@B 전역 값 일괄 삭제는 `ALTER SYSTEM FLUSH GLOBAL CONTEXT`다. 정의는 DBA_CONTEXT, 현재 값은 SESSION_CONTEXT·GLOBAL_CONTEXT로 본다.

@H2 6.13  퀴즈

@QUIZ 문제 1
보안 판단의 근거로 쓰기에 가장 적절한 USERENV 속성은?
① CLIENT_IDENTIFIER  ② MODULE  ③ CURRENT_SCHEMA  ④ SESSION_USER
정답 ④. SESSION_USER는 서버가 로그인 시 정하는 값이라 세션이 바꿀 수 없다. CLIENT_IDENTIFIER와 MODULE은 세션이 직접 설정하고, CURRENT_SCHEMA는 ALTER SESSION으로 누구나 바꿀 수 있다.
@END

@QUIZ 문제 2
DBMS_SESSION 실행 권한이 있는 HR이 SQL*Plus에서 `EXEC DBMS_SESSION.SET_CONTEXT('c6_task_ctx','app_user','USER_A')`를 실행했다. 결과는?
① 정상 설정된다  ② ORA-01031이 발생한다  ③ ORA-02003이 발생한다  ④ 값이 전역으로 설정된다
정답 ②. SET_CONTEXT는 호출 스택에 해당 네임스페이스의 신뢰 패키지가 있어야 한다. 직접 호출하면 실행 권한과 관계없이 ORA-01031이 난다. ORA-02003은 USERENV의 없는 속성을 읽을 때 나는 오류다.
@END

@QUIZ 문제 3
AFTER LOGON 트리거가 호출하는 신뢰 패키지에서 매핑에 없는 사용자가 로그인할 때 NO_DATA_FOUND가 처리되지 않았다. 일반 사용자에게 일어나는 일은?
① 로그인되고 컨텍스트가 비어 있다  ② ORA-04088과 함께 로그인이 거부된다  ③ 로그인되고 경고만 남는다  ④ 컨텍스트에 기본값이 들어간다
정답 ②. LOGON 트리거 안의 처리되지 않은 예외는 로그인을 실패시킨다. ADMINISTER DATABASE TRIGGER 권한을 가진 사용자만 예외적으로 접속된다. 예외를 처리해 컨텍스트를 비워 두면 ①처럼 동작한다.
@END

@QUIZ 문제 4
ACCESSED GLOBALLY 컨텍스트에 username과 client_id 없이 값을 넣었다. 그 값을 읽을 수 있는 세션은?
① 값을 넣은 세션만  ② 같은 DB 사용자의 세션만  ③ 같은 CLIENT_IDENTIFIER의 세션만  ④ 모든 세션
정답 ④. 두 인자를 생략하면 NULL로 간주되어 모든 사용자가 값을 본다. 원본 예제처럼 LOGON 트리거로 사용자마다 넣으면 마지막에 설정한 값이 모두에게 적용된다.
@END

@QUIZ 문제 5
연결 풀 환경에서 요청 처리가 끝난 세션을 풀에 돌려주기 전에 반드시 해야 할 일은?
① ALTER SYSTEM FLUSH GLOBAL CONTEXT  ② DBMS_SESSION.CLEAR_IDENTIFIER  ③ DROP CONTEXT  ④ 세션 종료
정답 ②. 식별자를 지우지 않으면 같은 세션을 받은 다음 요청이 앞 사용자의 컨텍스트 값으로 데이터를 본다. FLUSH GLOBAL CONTEXT는 모든 사용자의 전역 값을 지우므로 요청 단위로 쓰면 안 된다.
@END

@QUIZ 문제 6
GLOBAL_CONTEXT 뷰에 대한 설명으로 옳은 것은?
① 인스턴스의 모든 전역 컨텍스트 값을 보여 준다  ② SYS로 조회하면 모든 값이 보인다  ③ 현재 세션이 볼 수 있는 전역 값만 보여 준다  ④ 세션 기반 컨텍스트 값도 보여 준다
정답 ③. 실습에서 SYS나 식별자 없는 풀 계정으로는 username·client_id가 지정된 값이 보이지 않았고, 식별자를 맞춘 뒤에야 해당 행이 보였다. 세션 기반 값은 SESSION_CONTEXT로 본다.
@END

@H2 6.14  실습 개요

@P 실습은 oel7v9 서버의 orcl 데이터베이스(19.3, non-CDB)에서 진행한다. 보안 관리 계정 ctxadm과 실습 사용자(c6_king, c6_hunold, c6_nomap, c6_apppool)를 만들어 쓰고, 05 마지막에 모두 철거한다. LOGON 트리거는 실습 사용자 스키마로 한정했다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
6장_실습_01_USERENV와세션컨텍스트 | USERENV 속성, SESSION_USER와 CURRENT_SCHEMA, ORA-02003, 클라이언트 설정 값, 없는 네임스페이스 | 6.3
6장_실습_02_로컬컨텍스트와신뢰패키지 | CREATE CONTEXT, 신뢰 패키지, ORA-01031, 보안 뷰, SESSION_CONTEXT, CLEAR_CONTEXT, 세션 단위 값 | 6.4, 6.6
6장_실습_03_LOGON트리거자동설정 | 매핑 테이블, 스키마 LOGON 트리거, ORA-04088 로그인 거부와 예외 처리 | 6.5
6장_실습_04_전역컨텍스트와CLIENT_IDENTIFIER | ACCESSED GLOBALLY 값 공유, ORA-02000과 FLUSH 문법, username·client_id, 연결 풀 모델, GLOBAL_CONTEXT | 6.7, 6.9.2
6장_실습_05_컨텍스트관리와원복 | ORA-00955, CREATE OR REPLACE로 유형 변경, 원복 확인 | 6.9.1
@END
