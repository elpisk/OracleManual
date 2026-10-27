@H1 제7장  Virtual Private Database

@H2 7.1  학습 목표

@P 같은 테이블을 여러 사용자가 함께 쓰면서도 각자 볼 수 있는 행이 달라야 하는 경우가 많다. Oracle Virtual Private Database(VPD)는 이 조건을 애플리케이션이 아닌 데이터베이스 안에서 강제한다.

@B VPD가 SQL 문을 어떻게 재작성해 행을 걸러 내는지 설명하고, 뷰나 애플리케이션 조건과 비교해 어떤 점이 다른지 말할 수 있다.
@B 정책 함수, 정책, 애플리케이션 컨텍스트가 각각 맡는 역할을 구분하고 정책 관리자 계정을 분리하는 이유를 설명할 수 있다.
@B `DBMS_RLS.ADD_POLICY`의 주요 인자(statement_types, update_check, policy_type 등)를 목적에 맞게 지정할 수 있다.
@B 정책 술어 오류(ORA-28113)와 정책 등록 오류(ORA-28104, ORA-28101, ORA-28102)의 원인을 찾고 고칠 수 있다.
@B 컬럼 수준 VPD에서 기본 방식과 ALL_ROWS 방식의 결과 차이를 설명할 수 있다.
@B 정책 유형별 정책 함수 호출 시점을 알고 업무 조건에 맞는 유형을 고를 수 있다.
@B SYS 접속과 EXEMPT ACCESS POLICY 권한이 정책을 우회한다는 사실을 알고, 관련 데이터 딕셔너리 뷰로 정책을 점검할 수 있다.

@H2 7.2  VPD의 개념

@H3 7.2.1  행 단위 접근 제어가 필요한 이유

@B 객체 권한은 테이블 단위로 주어진다. `SELECT ON scott.emp`를 받은 사용자는 EMP의 모든 행을 읽는다.
@B 부서장은 자기 부서 사원만, 지점 직원은 자기 지점 계좌만 보게 하려면 행 단위 제어가 따로 필요하다.
@B 가장 흔한 방법은 애플리케이션이 SQL에 `WHERE deptno = :dept` 조건을 붙이는 것이다. 이 방식은 애플리케이션을 거치는 접근에만 통한다.
@B SQL*Plus, 보고서 도구, 다른 애플리케이션으로 같은 계정에 접속하면 조건 없이 전체 행을 읽을 수 있다.
@B 부서별 뷰를 만들어 뷰에만 권한을 주는 방법도 있다. 부서가 늘 때마다 뷰와 권한이 늘고, 조건이 사용자 속성에 따라 달라지면 뷰로 표현하기 어렵다.
@B VPD는 접근 경로와 관계없이 테이블에 직접 조건을 묶어 둔다. 어떤 도구로 접속하든 같은 조건이 붙는다.

@H3 7.2.2  동작 원리 — 문장 재작성

@P VPD의 본질은 파싱 단계의 문장 재작성이다. 사용자가 보낸 SQL을 데이터베이스가 받아 정책이 걸린 객체를 찾고, 정책 함수가 돌려준 조건을 WHERE 절에 덧붙인 뒤 실행한다.

@TBL
단계 | 하는 일
1. 파싱 | 문장이 참조하는 테이블·뷰·동의어를 확인하고 해당 객체에 걸린 정책을 찾음
2. 정책 함수 호출 | 정책마다 지정된 PL/SQL 함수를 실행해 술어 문자열을 받음
3. 술어 결합 | 받은 술어를 원래 WHERE 절과 AND로 결합. 정책이 여럿이면 모두 AND로 붙음
4. 실행 | 재작성된 문장을 최적화해 실행. 실행 계획의 술어 정보에도 정책 조건이 나타남
@END

@B 사용자가 `SELECT * FROM emp`를 보내고 정책 함수가 `deptno = 20`을 돌려주면 실제로 실행되는 문장은 `SELECT * FROM emp WHERE deptno = 20`과 같다.
@B 사용자가 직접 `WHERE deptno = 10`을 붙이면 `deptno = 10 AND deptno = 20`이 되어 0건이 나온다. 정책 조건을 사용자 조건으로 넓힐 방법은 없다.
@B 재작성은 옵티마이저 앞 단계에서 일어난다. 정책 술어도 일반 조건처럼 인덱스 선택과 조인 순서 결정에 쓰인다.
@B 정책 술어 컬럼에 인덱스가 없으면 모든 조회가 전체 스캔으로 바뀔 수 있다. 정책을 설계할 때 술어 컬럼의 인덱스를 함께 검토한다.
@B 실행 계획의 Predicate Information에 사용자가 쓰지 않은 조건이 보이면 VPD가 걸려 있다고 판단할 수 있다.

@H3 7.2.3  적용 범위와 기능 구분

@B 정책은 테이블, 뷰, 동의어에 걸 수 있다. SYS 소유 객체에는 걸 수 없다.
@B SELECT, INSERT, UPDATE, DELETE, INDEX 문장에 적용할 수 있다. 어떤 문장에 적용할지는 정책마다 고른다.
@B VPD는 Enterprise Edition에 포함된 기능이다. 별도 옵션 라이선스가 필요하지 않다.
@B 매뉴얼과 예전 자료에서 같은 기능을 FGAC(Fine-Grained Access Control), RLS(Row Level Security)로 부르기도 한다. 패키지 이름 `DBMS_RLS`가 그 흔적이다.
@B VPD와 이름이 비슷한 Fine-Grained Auditing(12장)은 접근을 막지 않고 기록만 한다. Data Redaction(8장)은 행을 거르지 않고 결과 값을 가린다.

@TBL
기능 | 대상 | 결과
VPD 행 수준 | 행 | 조건에 맞지 않는 행이 결과에서 빠짐
VPD 컬럼 수준(ALL_ROWS) | 컬럼 값 | 행은 모두 나오고 민감 컬럼 값이 NULL
Data Redaction | 컬럼 값 | 행은 모두 나오고 값이 가림 문자·0 등으로 바뀜
Fine-Grained Auditing | 접근 기록 | 결과는 그대로, 조건에 맞는 접근을 감사 기록에 남김
@END

@H3 7.2.4  뷰·애플리케이션 조건과 비교

@TBL
방법 | 강제 위치 | 우회 가능성 | 관리 부담
애플리케이션 WHERE 조건 | 애플리케이션 코드 | 다른 도구로 접속하면 우회 | 화면마다 조건 중복
부서별 뷰 + 뷰 권한 | 뷰 정의 | 원본 테이블 권한이 있으면 우회 | 부서·조건 수만큼 뷰 증가
VPD 정책 | 테이블에 묶인 정책 | SYS·면제 권한만 우회 | 정책 함수 하나로 규칙 관리
@END

@B 뷰 방식은 단순하고 결과를 예측하기 쉽다. 조건 종류가 몇 개로 고정되어 있고 사용자가 원본 테이블 권한을 갖지 않는다면 여전히 좋은 선택이다.
@B VPD는 조건이 사용자마다 다르고 접근 경로가 여럿일 때 효과가 크다. 애플리케이션 SQL을 고치지 않고 적용할 수 있다는 점도 기존 시스템에 보안을 덧붙일 때 유리하다.
@B 두 방식을 섞을 수도 있다. 뷰에 정책을 걸면 뷰를 통한 접근에만 술어가 붙고, 원본 테이블에 걸면 뷰를 포함한 모든 경로에 붙는다.

@NOTE 멀티테넌트 환경의 정책
CDB에서 VPD 정책은 PDB마다 따로 존재한다. 한 PDB에 건 정책은 다른 PDB에 영향을 주지 않는다.
12.2부터 애플리케이션 컨테이너에서는 ADD_POLICY의 common 인자로 애플리케이션 PDB 전체에 적용되는 공통 정책을 만들 수 있다. 이 과정의 실습 DB는 non-CDB라 해당하지 않는다.
@END

@H2 7.3  VPD의 구성 요소

@H3 7.3.1  정책 함수, 정책, 애플리케이션 컨텍스트

@B 정책 함수(policy function)는 술어 문자열을 만드는 PL/SQL 함수다. 어떤 사용자가 어떤 행을 볼지에 대한 판단 논리가 모두 여기에 들어간다.
@B 정책(policy)은 "이 객체에, 이런 문장이 오면, 이 함수를 불러라"를 등록한 것이다. `DBMS_RLS.ADD_POLICY`로 만든다.
@B 애플리케이션 컨텍스트(application context)는 정책 함수가 판단에 쓸 사용자 속성을 담아 두는 세션 메모리다. 부서 번호, 역할, 지점 코드 같은 값을 넣는다.
@B 정책 함수가 매번 테이블을 조회해 사용자 속성을 찾으면 느리다. 로그인할 때 한 번 컨텍스트에 넣어 두고 `SYS_CONTEXT`로 읽으면 비용이 거의 없다.
@B 컨텍스트 없이도 VPD는 동작한다. `SYS_CONTEXT('USERENV', 'SESSION_USER')` 같은 기본 제공 네임스페이스만으로 술어를 만들 수도 있다.

@H3 7.3.2  정책 관리자 계정을 따로 두는 이유

@B 정책 함수와 컨텍스트 패키지를 데이터 소유자 스키마에 두면 데이터 소유자가 정책 함수를 고쳐 제한을 풀 수 있다.
@B SYS 스키마에 두는 방식도 피한다. SYS 객체는 업그레이드와 패치의 영향을 받고, 일반 객체 관리 절차로 다루기 어렵다.
@B 매뉴얼의 VPD 튜토리얼은 `sysadmin_vpd`라는 전용 계정을 만들어 정책 함수, 컨텍스트 패키지, 정책 등록을 모두 이 계정에서 처리한다. 이 장의 실습도 같은 이름을 쓴다.
@B 정책 관리자 계정에는 `CREATE SESSION`, `CREATE PROCEDURE`, `CREATE ANY CONTEXT`와 `DBMS_RLS`, `DBMS_SESSION` 실행 권한을 준다. LOGON 트리거를 쓴다면 `CREATE TRIGGER`, `ADMINISTER DATABASE TRIGGER`도 필요하다.
@B `DBMS_RLS` 실행 권한은 정책을 걸고, 끄고, 지울 수 있는 권한이다. 정책 관리자 외에는 주지 않는다.

@CODE
SYS@orcl> CREATE USER sysadmin_vpd IDENTIFIED BY oracle;
SYS@orcl> GRANT CREATE SESSION, CREATE PROCEDURE, CREATE ANY CONTEXT TO sysadmin_vpd;
SYS@orcl> GRANT EXECUTE ON DBMS_RLS TO sysadmin_vpd;
SYS@orcl> GRANT EXECUTE ON DBMS_SESSION TO sysadmin_vpd;
@END

@NOTE 원본 실습 자료와 다른 점
과정 원본 자료는 정책 함수를 SCOTT 스키마에, 컨텍스트 프로시저를 SYS 스키마에 만든다. 기능은 동작하지만 데이터 소유자가 자기 정책을 고칠 수 있고 SYS에 사용자 코드가 남는다.
이 교안은 19c 매뉴얼의 권장대로 정책 관리 계정을 분리했다. 실습 이름(HR_CONTEXT, rls_dept, SCOTT.EMP)은 원본을 따랐다.
@END

@H3 7.3.3  세션 하나에서 일어나는 순서

@TBL
시점 | 일어나는 일 | 관여하는 구성 요소
로그인 | LOGON 트리거가 신뢰 패키지를 호출 | 트리거, 신뢰 패키지
로그인 직후 | 신뢰 패키지가 매핑을 찾아 컨텍스트에 부서를 기록 | DBMS_SESSION.SET_CONTEXT
SQL 파싱 | EMP에 걸린 정책을 찾아 정책 함수 호출 | DBMS_RLS로 등록된 정책
정책 함수 실행 | SYS_CONTEXT로 부서를 읽어 술어 문자열 반환 | 정책 함수
실행 | 술어가 결합된 문장 실행, 결과 반환 | 옵티마이저
@END

@B 이 순서 중 어느 하나라도 빠지면 결과는 0건이나 전체 행으로 나타난다. 오류 메시지가 없는 경우가 많아, 각 단계를 따로 확인할 수단을 알아 둬야 한다.
@B 컨텍스트 값은 `SYS_CONTEXT`로, 정책 함수의 반환 값은 함수 직접 호출로, 붙은 술어는 실행 계획과 V$VPD_POLICY로 확인한다.

@H2 7.4  정책 함수 작성

@H3 7.4.1  함수의 형식

@B 정책 함수는 인자 두 개를 받고 VARCHAR2를 돌려준다. 첫 인자는 정책이 걸린 객체의 스키마, 두 번째는 객체 이름이다.
@B 인자 이름은 자유지만 개수와 순서, 자료형은 고정이다. 하나의 함수를 여러 테이블 정책에 재사용할 때 이 인자로 대상 테이블을 구분한다.
@B 돌려주는 값은 WHERE 키워드를 뺀 조건식이다. `'deptno = 20'`처럼 쓴다.
@B 술어는 최대 32K 바이트까지 허용된다. 서브쿼리도 쓸 수 있지만 문장마다 실행되므로 비용을 고려한다.
@B 정책 함수는 정의자 권한으로 실행된다. 함수 안에서 참조하는 테이블은 함수 소유자가 읽을 수 있어야 한다.

@CODE
CREATE OR REPLACE FUNCTION rls_dept (
  p_schema IN VARCHAR2,
  p_object IN VARCHAR2)
RETURN VARCHAR2
AS
  v_dept NUMBER;
BEGIN
  v_dept := SYS_CONTEXT('HR_CONTEXT', 'DEPT');
  IF v_dept IS NULL THEN
    RETURN '1=2';
  END IF;
  RETURN 'deptno = ' || v_dept;
END;
/
@END

@B 정책 함수가 판단에 자주 쓰는 USERENV 속성은 다음과 같다. 모두 로그인 시점에 데이터베이스가 채우므로 사용자가 바꿀 수 없다(CLIENT_IDENTIFIER, MODULE은 애플리케이션이 설정).

@TBL
속성 | 값 | 활용
SESSION_USER | 로그인한 데이터베이스 사용자 | 사용자별 매핑, 예외 사용자 판별
PROXY_USER | 프록시 인증 시 중간 계층 계정(2장) | 애플리케이션 경유 여부 판별
CLIENT_IDENTIFIER | 애플리케이션이 설정한 최종 사용자 ID | 연결 풀 환경의 실제 사용자 구분(6장)
IP_ADDRESS | 클라이언트 IP | 사내망 접속만 허용하는 조건
MODULE | 애플리케이션이 설정한 프로그램 이름 | 특정 프로그램에서만 데이터 공개
AUTHENTICATION_METHOD | PASSWORD, SSL 등 인증 방식 | 인증서 로그인 사용자만 허용(11장)
@END

@B MODULE과 CLIENT_IDENTIFIER는 클라이언트가 설정하는 값이라 위조할 수 있다. 단독 근거로 쓰지 말고 SESSION_USER나 IP_ADDRESS 같은 서버 측 값과 함께 쓴다.

@H3 7.4.2  값이 없을 때의 기본 동작

@B 정책 함수가 NULL이나 빈 문자열을 돌려주면 술어가 붙지 않는다. 그 사용자는 모든 행을 본다.
@B 그래서 판단 근거(컨텍스트 값)가 없을 때는 `'1=2'`처럼 항상 거짓인 조건을 돌려주는 것이 안전하다. 실수로 값을 못 넣은 세션이 전체 데이터를 보는 일을 막는다.
@B 반대로 관리자처럼 전체를 봐야 하는 사용자는 함수 안에서 명시적으로 NULL을 돌려준다. 어떤 사용자에게 NULL을 돌려주는지가 곧 정책의 예외 목록이다.
@B 컨텍스트 네임스페이스 자체가 없어도 `SYS_CONTEXT`는 오류 없이 NULL을 돌려준다. 컨텍스트를 만들기 전에 정책부터 걸어도 동작한다.

@B 예외 사용자를 함수 안에 두는 예는 다음과 같다. 인사 관리자 계정은 NULL을 돌려받아 모든 행을 보고, 나머지 사용자는 컨텍스트 값으로 걸러진다.

@CODE
CREATE OR REPLACE FUNCTION rls_dept (
  p_schema IN VARCHAR2,
  p_object IN VARCHAR2)
RETURN VARCHAR2
AS
BEGIN
  IF SYS_CONTEXT('USERENV', 'SESSION_USER') = 'HR_ADMIN' THEN
    RETURN NULL;
  END IF;
  RETURN 'deptno = SYS_CONTEXT(''HR_CONTEXT'', ''DEPT'')';
END;
/
@END

@B 두 번째 RETURN은 숫자를 이어 붙이지 않고 SYS_CONTEXT 호출 자체를 술어 문자열에 넣었다. 술어 문자열이 항상 같으므로 7.8절의 STATIC 계열 유형과 함께 쓸 수 있다.
@B 컨텍스트 값이 NULL이면 `deptno = NULL`이 되어 0건이다. '1=2'를 따로 돌려주지 않아도 같은 효과가 난다.
@B 예외 사용자 목록이 늘어나면 함수에 이름을 늘어놓지 말고 별도 테이블이나 역할 확인(`SYS_CONTEXT('SYS_SESSION_ROLES', '역할명')`)으로 바꾼다.

@B 정책 함수는 일반 함수처럼 직접 호출해 반환 값을 볼 수 있다. 정책을 걸기 전에 업무 계정 세션에서 컨텍스트를 채우고 함수를 불러 술어 문자열을 확인한다.

@CODE
SCOTT@orcl> EXEC sysadmin_vpd.hr_ctx_pkg.set_dept(20)
SCOTT@orcl> SELECT sysadmin_vpd.rls_dept('SCOTT', 'EMP') FROM dual;
@END

@B 직접 호출하려면 시험하는 계정이 함수 실행 권한을 받아야 한다. 시험이 끝나면 회수한다. 정책 함수 실행 권한은 업무 계정에 필요하지 않다.

@H3 7.4.3  술어 오류와 진단

@P 정책 함수는 문자열을 만들어 돌려줄 뿐이라 컬럼 이름이 틀려도 컴파일 오류가 나지 않는다. 정책 등록도 술어를 검사하지 않는다. 오류는 업무 사용자가 테이블을 조회하는 순간에 드러난다.

@TBL
오류 | 의미 | 주로 보는 곳
ORA-28110 | 정책 함수나 패키지가 INVALID 상태 | 함수 컴파일 오류(SHOW ERRORS)
ORA-28112 | 정책 함수 실행 중 예외 발생 | 함수 안의 SELECT, 형 변환
ORA-28113 | 함수가 돌려준 술어를 붙인 문장이 잘못됨 | 컬럼 이름, 따옴표, 괄호
@END

@B ORA-28112는 함수 안의 SELECT INTO가 행을 찾지 못하거나 숫자 변환이 실패할 때 흔히 난다. 정책 함수 안에서 예외를 처리하지 않으면 사소한 데이터 문제가 테이블 전체 접근 장애로 번진다.
@B 세 오류 모두 메시지만으로는 어느 정책이 원인인지 알 수 없다. 자세한 내용은 해당 세션의 서버 트레이스 파일에 남는다.
@B 트레이스에는 정책 이름, 정책 함수 이름, 술어가 붙은 최종 문장, 그 문장이 낸 원래 오류(ORA-00904 등)가 함께 기록된다.
@B 한 객체에 정책이 여러 개면 트레이스에 각 정책의 술어가 따로 나온다. 어느 술어가 원인인지 바로 구분된다.

@CODE
VPD Policy name    : EMP_TEST_POLICY
Policy function: SYSADMIN_VPD.RLS_DEPT_TEST
RLS view  :
SELECT  "EMPNO","ENAME",...,"DEPTNO" FROM "SCOTT"."EMP"   "EMP" WHERE (dept_no = 20)
ORA-00904: "DEPT_NO": invalid identifier
@END

@B 정책 함수를 고쳐도 정책은 다시 등록할 필요가 없다. 정책은 함수 이름만 참조한다.
@B 정책 함수가 보호 대상 테이블 자체를 조회하면 그 조회에도 정책이 걸려 재귀가 생길 수 있다. 사용자 속성은 별도 매핑 테이블이나 컨텍스트에서 읽는다.

@BP 정책 함수 작성 규칙
판단 근거가 없으면 `'1=2'`를 돌려준다. NULL은 "제한 없음"이다.
함수 안에서 무거운 조회를 하지 않는다. 사용자 속성은 로그인 시 컨텍스트에 넣고 함수는 `SYS_CONTEXT`만 읽는다.
술어 컬럼에는 인덱스를 준비한다.
업무 계정으로 SELECT, INSERT, UPDATE, DELETE를 모두 시험한 뒤 배포한다. SYS로 확인하면 정책이 적용되지 않아 시험이 되지 않는다.
@END

@H2 7.5  정책 등록과 관리 — DBMS_RLS

@H3 7.5.1  ADD_POLICY의 주요 인자

@TBL
인자 | 의미 | 기본값
object_schema, object_name | 정책을 걸 객체 | (필수)
policy_name | 객체 안에서 고유한 정책 이름 | (필수)
function_schema, policy_function | 술어를 만들 함수 | (필수)
statement_types | 정책을 적용할 문장 유형 | SELECT, UPDATE, DELETE
update_check | INSERT·UPDATE 후의 행도 술어로 검사 | FALSE
enable | 등록과 동시에 활성화 | TRUE
policy_type | 정책 함수 호출 시점(7.8절) | DYNAMIC
sec_relevant_cols | 컬럼 수준 VPD의 민감 컬럼 목록(7.7절) | NULL
sec_relevant_cols_opt | ALL_ROWS 지정 시 행은 모두, 민감 값만 NULL | NULL
namespace, attribute | CONTEXT_SENSITIVE 정책이 감시할 컨텍스트 속성 | NULL
@END

@CODE
BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'SCOTT',
    object_name     => 'EMP',
    policy_name     => 'EMP_DEPT_POLICY',
    function_schema => 'SYSADMIN_VPD',
    policy_function => 'RLS_DEPT',
    statement_types => 'SELECT, UPDATE, DELETE');
END;
/
@END

@B 인자는 이름 지정 방식(`=>`)으로 쓴다. 위치 방식은 인자가 많아 순서를 틀리기 쉽다.
@B 한 객체에 여러 정책을 걸 수 있다. 술어는 모두 AND로 결합된다. 정책 하나가 1=2를 돌려주면 다른 정책과 관계없이 0건이다.
@B 정책을 등록한 순간부터 해당 객체를 참조하는 커서는 다시 파싱된다. 운영 중인 대형 테이블에 정책을 걸 때는 공유 풀 부하를 고려해 한가한 시간에 한다.

@H3 7.5.2  statement_types와 update_check

@B statement_types의 기본값은 SELECT, UPDATE, DELETE다. INSERT와 INDEX는 기본값에 들어 있지 않다.
@B UPDATE, DELETE에 정책이 걸리면 술어 밖의 행은 수정·삭제 대상에서 빠진다. 오류가 아니라 "0 rows updated"로 끝난다.
@B 기본 설정에서는 INSERT를 막지 않는다. 컨텍스트가 20번 부서인 사용자가 10번 부서 행을 넣을 수 있고, 넣은 직후 그 행은 본인에게도 보이지 않는다.
@B UPDATE로 술어 컬럼 값을 바꾸는 것도 막지 않는다. 자기 부서 사원의 부서 번호를 30으로 바꾸면 그 행은 시야에서 사라지고 다른 부서 데이터가 된다.
@B update_check => TRUE를 주면 INSERT·UPDATE 후의 행이 술어를 만족하는지 다시 검사한다. 벗어나면 ORA-28115로 거부된다. 뷰의 WITH CHECK OPTION과 같은 동작이다.
@B INSERT를 statement_types에 넣으려면 update_check => TRUE가 반드시 함께 있어야 한다. 빠지면 ORA-28104: input value for statement_types is not valid가 난다. 19c PL/SQL Packages and Types Reference에 명시된 규칙이다.

@CODE
SCOTT@orcl> INSERT INTO emp VALUES (5557, 'RON1', 'DEV', 7902, DATE '2002-11-02', 2000, 100, 10);
INSERT INTO emp VALUES (5557, 'RON1', 'DEV', 7902, DATE '2002-11-02', 2000, 100, 10)
            *
ERROR at line 1:
ORA-28115: policy with check option violation
@END

@CASE 정책을 걸었는데 다른 부서 데이터가 계속 늘어난다
부서별 VPD를 SELECT, UPDATE, DELETE에 걸어 운영했다. 몇 달 뒤 집계해 보니 각 부서 담당자가 입력한 거래 중 일부가 엉뚱한 부서 번호로 저장돼 있었다. 담당자들은 자기 화면에서 그 거래를 본 적이 없다고 했다.
원인은 기본 statement_types에 INSERT가 없다는 데 있었다. 입력 화면의 부서 기본값이 잘못 설정된 상태로 저장되면 그 행은 입력한 사람에게도 보이지 않아 오류를 알아챌 수 없었다.
정책을 DROP한 뒤 statement_types에 INSERT를 넣고 update_check => TRUE로 다시 등록했다. 이후 잘못된 부서로 저장하려는 시도는 ORA-28115로 화면에 바로 드러났다.
@END

@H3 7.5.3  여러 정책의 결합

@B 한 테이블에 목적이 다른 정책을 나눠 걸 수 있다. 부서 제한 정책과 퇴사자 숨김 정책을 따로 두면 각 함수가 단순해지고 하나만 끄기도 쉽다.
@B 두 정책의 술어는 AND로 결합된다. 부서 정책이 `deptno = 20`, 퇴사자 정책이 `retire_dt IS NULL`을 돌려주면 실제 조건은 `deptno = 20 AND retire_dt IS NULL`이다.
@B 한 정책이라도 오류를 내면 문장 전체가 실패한다. 실습 01에서 시험용 정책의 술어 오류 하나가 정상 정책까지 포함한 조회 전체를 ORA-28113으로 막았다.
@B OR 조건이 필요하면 정책을 나누지 말고 한 함수 안에서 조합한다.

@H3 7.5.4  정책 변경, 비활성화, 삭제

@B `DBMS_RLS.ENABLE_POLICY(스키마, 객체, 정책, FALSE)`는 정의를 남긴 채 정책을 끈다. TRUE로 다시 켠다. 끄는 즉시 모든 행이 보이므로 운영 중에는 감사 대상 작업으로 다룬다.
@B `DBMS_RLS.DROP_POLICY`는 정책을 지운다. 이름이 틀리면 ORA-28102: policy does not exist가 난다.
@B 같은 이름으로 다시 ADD_POLICY하면 ORA-28101: policy already exists가 난다.
@B `DBMS_RLS.ALTER_POLICY`(12.2 이후)는 CONTEXT_SENSITIVE 정책의 컨텍스트 속성 연결을 추가·제거하는 용도다. statement_types, update_check, 정책 함수 같은 정의는 바꾸지 못한다.
@B 정의를 바꾸려면 DROP 후 ADD한다. 두 호출 사이에는 객체가 정책 없이 열려 있으므로 한 PL/SQL 블록 안에서 연달아 실행한다.
@B DROP과 ADD를 한 블록에 넣어도 ADD가 실패하면 DROP은 이미 끝난 상태다. 블록이 실패하면 즉시 정책 존재 여부를 확인한다.
@B `DBMS_RLS.REFRESH_POLICY`는 정책과 관련된 커서를 다시 파싱하게 한다. 정책 함수 논리를 바꾼 뒤 STATIC 계열 정책의 캐시를 비울 때 쓴다.

@CODE
BEGIN
  DBMS_RLS.DROP_POLICY('SCOTT', 'EMP', 'EMP_DEPT_POLICY');
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'SCOTT',
    object_name     => 'EMP',
    policy_name     => 'EMP_DEPT_POLICY',
    function_schema => 'SYSADMIN_VPD',
    policy_function => 'RLS_DEPT',
    statement_types => 'SELECT, INSERT, UPDATE, DELETE',
    update_check    => TRUE);
END;
/
@END

@H3 7.5.5  정책 그룹

@B 여러 애플리케이션이 같은 테이블을 서로 다른 규칙으로 써야 할 때 정책 그룹을 쓴다. 정책을 그룹으로 묶고 세션마다 어떤 그룹을 적용할지 고른다.
@B `CREATE_POLICY_GROUP`으로 그룹을 만들고 `ADD_GROUPED_POLICY`로 정책을 그룹에 넣는다.
@B `ADD_POLICY_CONTEXT`로 드라이빙 컨텍스트를 지정하면, 세션의 그 컨텍스트 값이 그룹 이름과 같은 그룹이 적용된다.
@B 그룹에 속하지 않는 기본 그룹 SYS_DEFAULT의 정책은 항상 적용된다. 공통 규칙은 SYS_DEFAULT에, 애플리케이션별 규칙은 각 그룹에 둔다.
@B 단일 애플리케이션 환경에서는 그룹 없이 ADD_POLICY만으로 충분하다.

@H3 7.5.6  INDEX 문장 유형

@B statement_types에 INDEX를 넣으면 CREATE INDEX 문에도 정책이 적용된다.
@B 함수 기반 인덱스는 인덱스를 만드는 동안 테이블의 모든 행에 함수를 적용해 결과를 인덱스에 저장한다. 정책이 없으면 인덱스 키를 통해 보호된 행의 값이 드러날 수 있다.
@B INDEX에 정책을 걸어 두면 정책 술어 밖의 행에 대해 함수 기반 인덱스를 만들 수 없게 된다. 민감 컬럼을 함수 기반 인덱스로 가공하는 시스템에서 검토한다.

@H3 7.5.7  ADD_POLICY의 나머지 인자와 제약

@P 7.5.1 표에서 뺀 인자와 사용 노트의 제약을 PL/SQL Packages and Types Reference의 DBMS_RLS 절 기준으로 정리한다.

@TBL
항목 | 문서 내용 | 설계 시 의미
object_name | 테이블, 뷰, 동의어에 정책을 걸 수 있음 | 동의어에 걸면 그 동의어를 참조하는 객체가 모두 INVALID로 표시됨
long_predicate | 기본 FALSE면 술어 4000바이트까지, TRUE면 32K까지 | IN 목록을 길게 만드는 함수는 TRUE가 필요
static_policy | 구버전 인자. TRUE면 모든 사용자에게 같은 술어로 간주 | policy_type을 주면 이 값은 무시됨
정책 수 | 객체 하나에 최대 255개 | 정책을 기능별로 쪼개도 한도는 넉넉함
전역 컨텍스트 | CONTEXT_SENSITIVE 계열 정책에 연결할 수 없음 | 연결 풀 구성(6장)은 DYNAMIC 등 다른 유형으로
@END

@B 정책 함수는 WNDS(데이터베이스 상태를 쓰지 않음) 순도를 지켜야 한다. 함수 안에서 로그 테이블에 INSERT하는 식의 기록은 할 수 없으므로, 접근 시도 기록은 감사 기능에 맡긴다.
@B 술어 안에 서브쿼리를 넣으면 그 안의 객체 검색과 권한 검사는 정책 함수 소유자 기준이다. 조회하는 사용자가 매핑 테이블 권한을 갖지 않아도 술어가 동작하는 이유다.
@B 술어에 테이블 별칭이 필요하면 테이블(또는 뷰) 이름 자체를 별칭으로 쓴다. 서버가 `select ... from tab tab where 술어` 형태의 임시 뷰를 만들기 때문이다.
@B 정책 함수의 유효성은 등록할 때가 아니라 실행할 때 검사된다. 실습 01의 술어 오류도 ADD_POLICY는 통과하고 첫 조회에서 ORA-28113으로 드러났다. 등록 직후 업무 계정으로 한 번 조회해 7.4.3 표의 오류가 없는지 본다.

@H2 7.6  애플리케이션 컨텍스트와의 연계

@H3 7.6.1  컨텍스트와 신뢰 패키지

@B `CREATE CONTEXT 네임스페이스 USING 스키마.패키지`로 컨텍스트를 만든다. USING에 적은 패키지가 그 네임스페이스에 값을 넣을 수 있는 유일한 통로다.
@B 패키지는 컨텍스트보다 나중에 만들어도 된다. 컨텍스트는 이름과 신뢰 패키지의 연결만 기록한다.
@B 신뢰 패키지 안에서 `DBMS_SESSION.SET_CONTEXT`를 호출해 값을 넣는다. 사용자가 `DBMS_SESSION.SET_CONTEXT`를 직접 호출하면 실행 권한이 있어도 ORA-01031: insufficient privileges가 난다.
@B 이 제약 덕분에 사용자는 자기 부서 번호를 마음대로 바꿔 넣을 수 없다. 값을 넣는 규칙은 신뢰 패키지의 코드가 정한다.
@B 정책 함수는 `SYS_CONTEXT('HR_CONTEXT', 'DEPT')`로 값을 읽는다. 읽기는 누구나 할 수 있다.

@CODE
CREATE CONTEXT hr_context USING sysadmin_vpd.hr_ctx_pkg;

CREATE OR REPLACE PACKAGE BODY hr_ctx_pkg AS
  PROCEDURE set_dept (p_deptno IN NUMBER) IS
  BEGIN
    DBMS_SESSION.SET_CONTEXT('HR_CONTEXT', 'DEPT', p_deptno);
  END;
END;
/
@END

@H3 7.6.2  로컬 컨텍스트는 세션 단위

@B 기본 컨텍스트는 ACCESSED LOCALLY 유형이다. 값은 세션의 UGA에 저장되고 그 세션에서만 보인다.
@B 다른 세션에서 값을 넣어도 조회하는 세션에는 영향이 없다. 세션이 끊기면 값도 사라진다.
@B 세션 사이에 값을 공유해야 하는 연결 풀 환경은 ACCESSED GLOBALLY 컨텍스트와 CLIENT_IDENTIFIER를 쓴다. 6장에서 다룬다.

@CASE SYS에서 컨텍스트를 설정했는데 SCOTT에게 아무것도 안 보인다
교육 자료를 따라 SYS 세션에서 `exec set_hr_context(20)`을 실행한 뒤 SCOTT로 접속해 EMP를 조회했다. 결과는 0건이었다. 정책 함수와 컨텍스트 정의를 아무리 살펴봐도 잘못된 곳이 없었다.
SCOTT 세션에서 `SELECT SYS_CONTEXT('HR_CONTEXT','DEPT') FROM dual`을 실행하니 NULL이 나왔다. SYS 세션에 넣은 값은 SYS 세션에만 있었고, CONNECT로 새로 열린 SCOTT 세션은 빈 컨텍스트로 시작했다.
SCOTT 세션 안에서 신뢰 패키지를 호출하도록 순서를 바꾸자 20번 부서 5건이 조회됐다. 운영 환경에서는 사용자가 직접 호출하지 않고 LOGON 트리거가 로그인 직후 값을 넣는다.
@END

@H3 7.6.3  값을 누가 넣는가

@B 실습에서는 SCOTT에게 패키지 실행 권한을 주고 원하는 부서를 직접 넣게 했다. 동작을 보기 위한 단순화다.
@B 실제 시스템에서 사용자가 부서 번호를 인자로 넘기면 아무 부서나 넣을 수 있어 정책이 의미를 잃는다.
@B 신뢰 패키지는 인자를 받지 않고 `SYS_CONTEXT('USERENV', 'SESSION_USER')`로 로그인 사용자를 확인한 뒤 매핑 테이블에서 부서를 찾아 넣도록 만든다.
@B 이 패키지를 LOGON 트리거에서 호출하면 사용자는 컨텍스트 값을 바꿀 기회가 없다. 트리거 안의 예외는 로그인 실패로 이어지므로 예외 처리를 반드시 넣는다.

@H3 7.6.4  LOGON 트리거로 값 넣기

@P 매뉴얼 튜토리얼은 로그인 사용자와 부서의 매핑을 테이블에 두고, LOGON 트리거가 신뢰 패키지를 불러 컨텍스트를 채우는 구조를 쓴다. 사용자는 컨텍스트 값을 정할 기회가 없다.

@CODE
CREATE OR REPLACE PACKAGE BODY hr_ctx_pkg AS
  PROCEDURE set_dept IS
    v_dept NUMBER;
  BEGIN
    SELECT deptno INTO v_dept
      FROM sysadmin_vpd.user_dept_map
     WHERE username = SYS_CONTEXT('USERENV', 'SESSION_USER');
    DBMS_SESSION.SET_CONTEXT('HR_CONTEXT', 'DEPT', v_dept);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL;
  END;
END;
/
CREATE OR REPLACE TRIGGER set_hr_ctx_trg AFTER LOGON ON DATABASE
BEGIN
  sysadmin_vpd.hr_ctx_pkg.set_dept;
END;
/
@END

@B 매핑에 없는 사용자는 NO_DATA_FOUND를 삼키고 컨텍스트를 비워 둔다. 정책 함수는 값이 없으므로 '1=2' 또는 `deptno = NULL`로 0건을 돌려준다.
@B 예외 처리를 빼면 매핑에 없는 사용자의 로그인이 트리거 오류로 실패한다. DBA 계정까지 막힐 수 있으므로 트리거는 반드시 예외를 처리한다.
@B 트리거와 매핑 테이블의 소유자도 정책 관리자 계정이다. 매핑 테이블을 고칠 수 있는 사람이 곧 모든 사용자의 부서를 바꿀 수 있는 사람이다.
@B LOGON 트리거, 컨텍스트 유형, 연결 풀 환경의 값 관리는 6장에서 자세히 다룬다.

@H3 7.6.5  세션의 컨텍스트 값 확인

@B 현재 세션에 들어 있는 모든 애플리케이션 컨텍스트 값은 SESSION_CONTEXT 뷰로 본다. 네임스페이스, 속성, 값이 한 행씩 나온다.
@B 특정 값 하나는 `SYS_CONTEXT('HR_CONTEXT', 'DEPT')`로 본다. 존재하지 않는 네임스페이스나 속성도 오류 없이 NULL을 돌려주므로, NULL이 나오면 이름 철자부터 확인한다.
@B 다른 세션의 로컬 컨텍스트 값은 볼 수 없다. 사용자가 "데이터가 안 보인다"고 하면 그 사용자 세션에서 직접 SESSION_CONTEXT를 조회하게 하거나, 애플리케이션 로그에 로그인 직후 컨텍스트 값을 남기도록 한다.

@CODE
SCOTT@orcl> SELECT namespace, attribute, value FROM session_context;
@END

@H2 7.7  컬럼 수준 VPD

@H3 7.7.1  sec_relevant_cols

@B 행 수준 VPD는 테이블을 참조하기만 하면 술어가 붙는다. 컬럼 수준 VPD는 지정한 민감 컬럼을 참조할 때만 붙는다.
@B 사원 이름과 부서는 누구나 보되 급여는 자기 부서 것만 보게 하는 요구가 대표적이다.
@B `sec_relevant_cols => 'SAL,COMM'`을 주면 SELECT 목록이나 WHERE 절에서 SAL·COMM을 참조하는 문장에만 정책 술어가 붙는다.
@B 민감 컬럼을 참조하지 않는 문장은 전체 행을 본다. 19.3에서 `COUNT(*)`는 민감 컬럼을 적지 않았는데도 정책이 적용됐다. 행 수를 보여 주는 화면은 정책 적용을 전제로 설계한다.
@B 정책 함수는 행 수준 VPD와 같은 것을 그대로 쓴다. 달라지는 것은 술어를 붙일지 정하는 조건뿐이다.

@H3 7.7.2  ALL_ROWS — 행은 그대로, 값만 NULL

@B 기본 방식에서는 민감 컬럼을 참조하면 술어 밖의 행이 통째로 빠진다. 이름 목록에 급여를 함께 보여 주는 화면에서는 다른 부서 사원이 목록에서 사라진다.
@B `sec_relevant_cols_opt => DBMS_RLS.ALL_ROWS`를 주면 모든 행을 돌려주고, 술어를 만족하지 않는 행의 민감 컬럼만 NULL로 바꾼다.
@B ALL_ROWS는 SELECT 문에만 쓸 수 있다. statement_types에 UPDATE 등을 함께 주면 ORA-28104: input value for sec_relevant_cols_opt is not valid가 난다.
@B ALL_ROWS를 쓸 때 정책 함수가 돌려주는 술어는 단순한 불리언 식이어야 한다.

@TBL
조회 (컨텍스트 20) | 기본 방식 | ALL_ROWS
SELECT ename, deptno | 14건 | 14건
SELECT ename, sal | 20번 부서 5건 | 14건, 20번 외 SAL은 NULL
SUM(sal) 부서별 | 20번만 나옴 | 10·30번은 NULL로 나옴
WHERE sal > 0 | 5건 | 5건(NULL은 조건을 만족하지 않음)
@END

@NOTE NULL은 계산을 바꾼다
ALL_ROWS로 가려진 값은 0이 아니라 NULL이다. COUNT(sal)은 가려진 행을 세지 않고, SUM과 AVG는 가려진 값을 빼고 계산한다.
급여 합계를 내는 보고서가 ALL_ROWS 정책 아래에서 실행되면 오류 없이 작은 합계가 나온다. 계산이 들어가는 애플리케이션에는 기본 방식이 맞고, 값이 NULL일 수 있다는 사실을 애플리케이션이 알고 있어야 한다.
@END

@H3 7.7.3  컬럼 수준 VPD와 Data Redaction 중 고르기

@B 둘 다 "행은 보이고 민감 값만 가린다"는 결과를 낼 수 있다. 차이는 가리는 방식과 조건 표현에 있다.
@B ALL_ROWS 방식 VPD는 값을 NULL로만 바꾼다. 조건은 정책 함수에서 PL/SQL로 자유롭게 짠다.
@B Data Redaction은 값을 0, 공백, 부분 마스킹(카드 번호 끝 4자리만 표시), 정규식 치환, 임의 값으로 바꾼다. 조건은 정책 식(expression) 하나로 표현한다. Advanced Security 옵션 기능이다(8장).
@B 화면에 "가려졌다"는 표시가 필요하거나 형식을 유지해야 하면 Redaction이 맞다. 부서처럼 행마다 다른 조건으로 값을 가려야 하면 컬럼 수준 VPD가 맞다.
@B 같은 컬럼에 두 기능을 겹쳐 쓰면 결과를 예측하기 어렵다. 한 컬럼에는 한 가지 방식만 적용한다.

@H2 7.8  정책 유형과 성능

@H3 7.8.1  다섯 가지 정책 유형

@P 정책 유형은 정책 함수를 언제 다시 부를지 정한다. 함수 호출 비용과 술어의 정확성 사이의 선택이다.

@TBL
유형 | 정책 함수 호출 시점 | 공유
DYNAMIC (기본) | 문장을 파싱·실행할 때마다 | 객체 1개
STATIC | 처음 한 번 실행하고 술어를 SGA에 캐시 | 객체 1개
SHARED_STATIC | STATIC과 같고, 같은 함수를 쓰는 객체끼리 캐시 공유 | 여러 객체
CONTEXT_SENSITIVE | 커서 실행 시 컨텍스트가 바뀌었으면 다시 호출 | 객체 1개
SHARED_CONTEXT_SENSITIVE | CONTEXT_SENSITIVE와 같고, 세션 안에서 캐시 공유 | 여러 객체
@END

@B DYNAMIC은 가장 안전하고 가장 비싸다. 술어가 시각, 세션 정보 등 무엇에든 의존할 수 있다고 가정한다.
@B STATIC은 술어 문자열이 항상 같을 때만 쓴다. `'deptno = SYS_CONTEXT(''HR_CONTEXT'',''DEPT'')'`처럼 SYS_CONTEXT를 술어 문자열 안에 넣으면, 문자열은 고정이고 값은 실행 시점에 평가되므로 STATIC으로도 정확하다.
@B 반대로 함수 안에서 SYS_CONTEXT 값을 읽어 `'deptno = 20'` 같은 문자열을 만드는 함수를 STATIC으로 등록하면, 처음 만든 술어가 모든 세션에 재사용되어 엉뚱한 부서가 보인다.
@B CONTEXT_SENSITIVE는 컨텍스트 값이 바뀔 때만 함수를 다시 부른다. 12.2부터는 namespace, attribute 인자로 감시할 속성을 지정해 관계없는 컨텍스트 변경에 함수가 다시 호출되지 않게 한다.
@B SHARED_ 계열은 같은 정책 함수를 여러 테이블에 걸 때 쓴다. 함수가 객체 이름 인자로 테이블을 구분해야 한다면 공유 캐시가 틀린 술어를 재사용하지 않는지 확인한다.

@CODE
BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'SCOTT',
    object_name     => 'EMP',
    policy_name     => 'EMP_DEPT_POLICY',
    function_schema => 'SYSADMIN_VPD',
    policy_function => 'RLS_DEPT',
    statement_types => 'SELECT',
    policy_type     => DBMS_RLS.CONTEXT_SENSITIVE,
    namespace       => 'HR_CONTEXT',
    attribute       => 'DEPT');
END;
/
@END

@H3 7.8.2  유형 선택 기준

@B 술어가 사용자 속성 하나에만 의존하고 그 값이 로그인 때 정해진다면 CONTEXT_SENSITIVE가 무난하다.
@B 술어 문자열을 SYS_CONTEXT 호출을 포함한 고정 문자열로 만들 수 있다면 STATIC 계열이 가장 가볍다.
@B 판단 논리가 시각, 요청 프로그램, 테이블 조회 결과처럼 예측하기 어려운 값에 의존하면 DYNAMIC을 유지한다.
@B 유형을 바꾸기 전에는 같은 세션에서 컨텍스트 값을 바꿔 가며 결과가 따라 바뀌는지 시험한다. 캐시 오류는 오류 메시지 없이 틀린 결과로만 나타난다.
@B 실제 붙은 술어는 V$VPD_POLICY에서 커서별로 확인한다. 같은 SQL_ID에 컨텍스트 값마다 다른 술어가 기록되면 유형이 의도대로 동작한다.

@BP 정책 함수 비용 줄이기
정책 함수 안에서 테이블을 조회하지 말고 컨텍스트 값만 읽는다.
술어에 쓰이는 컬럼에 인덱스를 만든다.
DYNAMIC으로 먼저 정확성을 확인하고, 필요할 때만 CONTEXT_SENSITIVE나 STATIC 계열로 옮긴다.
유형을 옮긴 뒤에는 컨텍스트 값을 바꿔 가며 V$VPD_POLICY의 술어가 따라 바뀌는지 확인한다.
@END

@CASE 오전에는 맞고 오후에는 틀린 부서가 보인다
연결 풀을 쓰는 웹 애플리케이션에 VPD를 도입하면서 성능을 위해 정책 유형을 SHARED_STATIC으로 바꿨다. 오전 시험에서는 문제가 없었는데, 오후 들어 일부 사용자가 다른 부서 사원 목록을 본다는 신고가 들어왔다.
정책 함수는 컨텍스트에서 부서를 읽어 `'deptno = 20'` 같은 문자열을 만들고 있었다. SHARED_STATIC은 처음 만든 술어를 SGA에 캐시해 모든 세션이 재사용하므로, 첫 사용자의 부서가 다른 사용자에게도 적용됐다.
정책 함수가 `'deptno = SYS_CONTEXT(''HR_CONTEXT'',''DEPT'')'`를 돌려주도록 고쳤다. 술어 문자열이 고정되고 값은 실행 시점에 세션마다 평가되므로 캐시 유형을 유지하면서 결과가 맞게 됐다. 변경 후 `DBMS_RLS.REFRESH_POLICY`로 기존 캐시를 비웠다.
@END

@H2 7.9  정책 우회와 면제

@H3 7.9.1  SYS와 EXEMPT ACCESS POLICY

@B SYS로 접속하거나 AS SYSDBA로 접속한 세션에는 VPD 정책이 적용되지 않는다. 정책을 시험할 때 SYS로 결과를 확인하면 정책이 없는 것처럼 보인다.
@B `EXEMPT ACCESS POLICY` 시스템 권한을 받은 사용자도 모든 VPD 정책을 건너뛴다. 특정 테이블만 면제하는 옵션은 없다.
@B 이 권한은 정책이 걸린 테이블을 Data Pump로 통째로 내보내는 백업 계정 등에 한정해 준다. 권한이 없는 계정으로 내보내면 정책 술어가 적용된 일부 행만 내보내진다.
@B 면제 권한 부여와 사용은 감사 대상으로 둔다. 13장의 감사 기록 관리에서 이런 권한 사용을 추적한다.
@B 테이블 소유자도 정책을 받는다. SCOTT가 자기 EMP를 조회해도 정책 술어가 붙는다.

@CODE
SYS@orcl> GRANT EXEMPT ACCESS POLICY TO hr;
HR@orcl> SELECT COUNT(*) FROM scott.emp;

  COUNT(*)
----------
        14
@END

@H3 7.9.2  우회 경로 점검

@B `DBMS_RLS` 실행 권한을 가진 계정은 정책을 끄거나 지울 수 있다. `DBA_TAB_PRIVS`에서 DBMS_RLS 실행 권한 보유자를 점검한다.
@B 정책 함수 소유자 계정은 함수를 고쳐 NULL을 돌려줄 수 있다. 소유자 계정의 비밀번호와 접속 경로를 데이터 소유자 계정보다 엄격하게 관리한다.
@B `EXEMPT ACCESS POLICY`를 받은 사용자와 역할은 `DBA_SYS_PRIVS`에서 확인한다. DBA 역할에는 이 권한이 포함되지 않지만 직접 부여된 경우가 있는지 본다.
@B 컨텍스트 신뢰 패키지의 실행 권한을 받은 계정은 컨텍스트 값을 바꿀 수 있다. 실습처럼 업무 계정에 패키지 실행 권한을 준 구성은 시험용으로만 쓰고, 운영에서는 LOGON 트리거만 패키지를 호출하게 한다.
@B 정기 점검 항목은 DBMS_RLS 실행 권한자, EXEMPT ACCESS POLICY 보유자, ENABLE이 NO인 정책, INVALID 상태의 정책 함수, 신뢰 패키지 실행 권한자 다섯 가지다.

@H3 7.9.3  Data Pump와 VPD

@B Data Pump Export는 내보내는 계정의 권한으로 테이블을 읽는다. 정책 적용 대상 계정이면 술어를 통과한 행만 덤프 파일에 들어간다.
@B 이때 일부 데이터만 내보내질 수 있다는 경고가 나오며 작업 자체는 성공한다. 경고를 놓치면 불완전한 백업을 정상으로 착각한다.
@B 전체 데이터를 내보내야 하는 계정에는 EXEMPT ACCESS POLICY를 주고, 그 계정의 사용을 감사한다.
@B 정책 정의 자체는 Data Pump 메타데이터에 포함된다. 다른 DB로 가져올 때 정책 함수와 정책 관리자 계정이 대상에 없으면 정책이 INVALID 함수를 가리키게 되어 ORA-28110이 날 수 있다.

@CASE 백업은 성공했는데 복원해 보니 행이 모자란다
야간 Data Pump 작업이 업무 계정 권한으로 돌고 있었다. VPD를 도입한 다음 날부터 덤프 파일 크기가 줄었지만 작업은 성공으로 끝났기 때문에 아무도 알아채지 못했다.
복원 시험에서 EMP의 행이 일부만 들어온 것을 보고 로그를 확인하니, 정책 때문에 일부 데이터만 내보내졌다는 경고가 매일 남아 있었다.
백업 전용 계정을 만들어 EXEMPT ACCESS POLICY를 주고, 그 계정의 로그인과 권한 사용을 감사하도록 바꿨다. 작업 로그의 경고도 모니터링 대상에 넣었다.
@END

@H2 7.10  VPD 관련 데이터 딕셔너리 뷰

@TBL
뷰 | 내용
DBA_POLICIES | 정책 정의. 객체, 정책 함수, 문장 유형별 적용 여부(SEL·INS·UPD·DEL·IDX), CHK_OPTION, ENABLE, POLICY_TYPE
DBA_POLICY_GROUPS | 정책 그룹 목록
DBA_POLICY_CONTEXTS | 객체별 드라이빙 컨텍스트
DBA_SEC_RELEVANT_COLS | 컬럼 수준 VPD의 민감 컬럼과 COLUMN_OPTION(ALL_ROWS 등)
DBA_POLICY_ATTRIBUTES | CONTEXT_SENSITIVE 정책에 연결된 네임스페이스·속성
V$VPD_POLICY | 공유 풀 커서별로 실제 붙은 정책과 술어
DBA_CONTEXT | 컨텍스트 네임스페이스와 신뢰 패키지, 유형
@END

@CODE
OBJECT_NAM POLICY_NAME      FUNCTION   SEL INS UPD DEL CHK ENA
---------- ---------------- ---------- --- --- --- --- --- ---
EMP        EMP_DEPT_POLICY  RLS_DEPT   YES YES YES YES YES YES

POLICY           PREDICATE
---------------- --------------------
EMP_DEPT_POLICY  deptno = 10
EMP_DEPT_POLICY  deptno = 30
@END

@B 첫 결과는 INSERT까지 update_check와 함께 걸린 정책이다. 두 번째 결과는 같은 정책이 컨텍스트 값에 따라 서로 다른 술어로 실행됐다는 기록이다.

@B ALL_ 계열과 USER_ 계열 뷰도 있다. USER_POLICIES는 내가 소유한 객체에 걸린 정책을 보여 준다. 정책 관리자 계정은 객체 소유자가 아니므로 DBA_ 계열을 조회할 권한을 따로 받거나 SYS로 점검한다.
@B DBA_POLICIES의 ENABLE이 NO인 정책은 정의만 남은 상태다. 정기 점검 목록에 넣는다.

@CODE
SYS@orcl> SELECT object_name, policy_name, function, sel, ins, upd, del, chk_option, enable
  2    FROM dba_policies WHERE object_owner = 'SCOTT';

SYS@orcl> SELECT DISTINCT policy, predicate FROM v$vpd_policy WHERE object_owner = 'SCOTT';
@END

@H2 7.11  설계와 적용 절차

@P 매뉴얼의 세션 기반 컨텍스트 VPD 튜토리얼은 다음 순서로 구성된다. 운영 환경에 처음 VPD를 도입할 때도 같은 순서를 따르면 빠뜨리는 단계가 없다.

@TBL
단계 | 작업 | 확인할 것
1 | 정책 관리자 계정 생성과 권한 부여 | DBMS_RLS, DBMS_SESSION 실행 권한, CREATE ANY CONTEXT
2 | 사용자 속성 매핑 테이블 준비 | 매핑 테이블의 소유자와 수정 권한
3 | 애플리케이션 컨텍스트 생성 | DBA_CONTEXT의 신뢰 패키지 이름
4 | 신뢰 패키지 작성 | 매핑에 없는 사용자의 예외 처리
5 | LOGON 트리거 작성 | 트리거 오류로 로그인이 막히지 않는지
6 | 정책 함수 작성 | 값이 없을 때 '1=2', 예외 사용자는 NULL
7 | 정책 등록 | statement_types, update_check, policy_type
8 | 업무 계정으로 시험 | SELECT·INSERT·UPDATE·DELETE, 실행 계획, V$VPD_POLICY
9 | 면제·우회 점검 | EXEMPT ACCESS POLICY, DBMS_RLS 실행 권한 보유자
@END

@B 4~6단계를 거꾸로 만들어도 동작은 한다. 컨텍스트가 비어 있으면 정책 함수가 0건을 돌려주므로, 정책을 먼저 걸면 업무가 갑자기 멈춘다. 운영 반영 순서는 표의 순서를 지킨다.
@B 8단계는 반드시 업무 계정으로 한다. SYS나 면제 권한 계정으로 시험하면 모든 행이 보여 정책이 없는 것과 구분되지 않는다.
@B 도입 초기에는 정책을 DYNAMIC으로 두고 결과가 맞는지 확인한 뒤 유형을 바꾼다.

@NOTE VPD와 감사는 함께 설계한다
VPD는 보지 못하게 막을 뿐 누가 시도했는지는 남기지 않는다. 0건이 나온 조회도 오류가 아니므로 애플리케이션 로그에도 흔적이 없다.
면제 권한 사용, 정책 비활성화, 정책 함수 변경은 Unified Auditing 정책이나 12장의 Fine-Grained Auditing으로 기록을 남긴다. 기록 관리는 13장에서 다룬다.
@END

@H2 7.12  운영 시 주의점

@B 정책을 새로 걸거나 바꾸면 관련 커서가 무효화된다. 업무 시간 중 대형 테이블에 정책을 바꾸면 하드 파싱이 몰린다.
@B 정책 함수가 INVALID가 되면 그 테이블을 쓰는 모든 문장이 ORA-28110으로 실패한다. 함수가 참조하는 객체를 변경할 때는 함수 상태를 함께 확인한다.
@B Data Pump, 통계 수집, 배치 작업 계정이 정책 적용 대상인지 확인한다. 통계 수집은 SYS 권한으로 돌아 영향이 없지만, 업무 계정으로 돌리는 배치는 술어가 붙은 일부 행만 처리한다.
@B 술어가 붙은 문장은 결과 캐시와 SQL 계획 고정에도 영향을 준다. 계획을 고정할 때는 정책 술어가 포함된 실제 문장을 기준으로 한다.
@B 정책 이름, 함수 이름, 컨텍스트 이름에 규칙을 정해 둔다. 장애 때 트레이스 파일의 정책 이름만 보고 담당 애플리케이션을 찾을 수 있어야 한다.
@B 정책 관리자 계정은 일반 업무 접속에 쓰지 않는다. 정책 변경이 필요할 때만 쓰고, 그 계정의 접속과 DBMS_RLS 호출은 감사한다.
@B 테이블을 재구성하거나 다른 스키마로 옮길 때 정책은 따라가지 않을 수 있다. 이관 체크리스트에 DBA_POLICIES 비교를 넣는다.
@B 장애 신고가 "데이터가 없다" 또는 "다른 사람 데이터가 보인다"로 들어오면 컨텍스트 값, 정책 함수 반환 값, V$VPD_POLICY의 술어를 순서대로 확인한다.
@B 실습이 끝나면 정책, 컨텍스트, 정책 관리자 계정을 모두 지운다. 남은 정책은 이후 다른 실습의 결과를 조용히 바꾼다.

@H2 7.13  요약

@B VPD는 정책 함수가 돌려준 술어를 SQL의 WHERE 절에 덧붙여 행 단위 접근을 제어한다. 접근 경로와 관계없이 같은 조건이 적용된다.
@B 구성 요소는 정책 함수(술어 생성), 정책(`DBMS_RLS.ADD_POLICY`로 객체와 함수를 연결), 애플리케이션 컨텍스트(사용자 속성 보관)다. 정책 관리 계정은 데이터 소유자와 분리한다.
@B 정책 함수가 NULL을 돌려주면 제한이 없다. 판단 근거가 없으면 `'1=2'`를 돌려준다.
@B 술어 오류는 조회 시점에 ORA-28113으로 드러나며 원인은 세션 트레이스에 정책 이름, 술어, 원래 오류와 함께 남는다.
@B statement_types 기본값은 SELECT, UPDATE, DELETE다. INSERT를 넣으려면 update_check => TRUE가 필요하고(아니면 ORA-28104), update_check는 술어를 벗어나는 변경을 ORA-28115로 막는다.
@B 컬럼 수준 VPD는 민감 컬럼을 참조할 때만 술어를 붙인다. ALL_ROWS는 SELECT 전용이며 행은 모두 보여 주고 값만 NULL로 바꿔 집계 결과가 달라진다.
@B 정책 유형은 정책 함수 호출 시점을 정한다. 캐시를 쓰는 유형은 술어가 세션마다 달라지는 함수와 함께 쓰면 틀린 결과를 낸다.
@B SYS 접속과 EXEMPT ACCESS POLICY 권한은 모든 정책을 우회한다. 정책 점검은 DBA_POLICIES, DBA_SEC_RELEVANT_COLS, V$VPD_POLICY로 한다.

@H2 7.14  퀴즈

@QUIZ 문제 1
정책 함수가 특정 사용자에게 NULL을 돌려줄 때의 동작으로 옳은 것은?
① 그 사용자는 0건을 본다  ② 그 사용자는 모든 행을 본다  ③ ORA-28113이 발생한다  ④ 직전에 캐시된 술어가 적용된다
정답 ②. NULL이나 빈 문자열은 "술어 없음"으로 해석되어 정책이 걸리지 않은 것처럼 모든 행이 보인다. 판단 근거가 없을 때 데이터를 막으려면 '1=2'처럼 항상 거짓인 조건을 돌려줘야 한다.
@END

@QUIZ 문제 2
statement_types => 'SELECT, INSERT, UPDATE, DELETE'만 주고 다른 인자 없이 ADD_POLICY를 실행했다. 결과는?
① 정상 등록된다  ② ORA-28101이 발생한다  ③ ORA-28104가 발생한다  ④ INSERT만 빼고 등록된다
정답 ③. INSERT 문장 유형은 update_check => TRUE와 함께 써야 한다. 이 조건이 빠지면 statement_types 값이 유효하지 않다는 ORA-28104가 나고 정책은 등록되지 않는다.
@END

@QUIZ 문제 3
SYS 세션에서 신뢰 패키지로 HR_CONTEXT.DEPT에 20을 넣은 뒤 SCOTT로 새로 접속해 정책이 걸린 EMP를 조회했다. 정책 함수는 값이 없으면 '1=2'를 돌려준다. 결과는?
① 20번 부서 행이 보인다  ② 모든 행이 보인다  ③ 0건이다  ④ ORA-01031이 발생한다
정답 ③. 로컬 컨텍스트는 값을 넣은 세션에만 존재한다. 새로 열린 SCOTT 세션에서는 SYS_CONTEXT가 NULL이므로 함수가 '1=2'를 돌려주어 0건이 된다.
@END

@QUIZ 문제 4
컬럼 수준 VPD에 대한 설명으로 틀린 것은?
① sec_relevant_cols에 지정한 컬럼을 참조할 때 술어가 붙는다  ② ALL_ROWS는 민감 컬럼 값을 NULL로 바꾼다  ③ ALL_ROWS는 UPDATE 문에도 쓸 수 있다  ④ ALL_ROWS 아래에서 SUM(sal)은 가려진 값을 빼고 계산된다
정답 ③. ALL_ROWS는 SELECT 전용이다. statement_types에 UPDATE를 함께 주면 ORA-28104(sec_relevant_cols_opt)가 난다. 가려진 값은 NULL이라 집계에서 빠지므로 결과가 달라진다.
@END

@QUIZ 문제 5
정책 함수가 SYS_CONTEXT 값을 읽어 'deptno = 20' 같은 문자열을 만들어 돌려준다. 이 정책을 STATIC 유형으로 등록하면 생길 수 있는 문제는?
① 정책 함수가 매번 호출되어 느려진다  ② 처음 만든 술어가 다른 세션에도 재사용되어 엉뚱한 행이 보인다  ③ 등록 시 ORA-28104가 난다  ④ 컨텍스트 값이 바뀌면 ORA-28113이 난다
정답 ②. STATIC은 정책 함수를 한 번 실행하고 그 술어를 SGA에 캐시한다. 세션마다 달라져야 할 술어가 고정되므로 오류 없이 틀린 결과가 나온다. SYS_CONTEXT 호출을 술어 문자열 안에 넣거나 CONTEXT_SENSITIVE를 쓴다.
@END

@QUIZ 문제 6
VPD 정책을 건너뛰지 않는 것은?
① AS SYSDBA로 접속한 세션  ② EXEMPT ACCESS POLICY 권한을 받은 사용자  ③ 정책이 걸린 테이블의 소유자  ④ SYS 사용자
정답 ③. 테이블 소유자도 정책 적용 대상이다. SYS·SYSDBA 접속과 EXEMPT ACCESS POLICY 권한만 모든 VPD 정책을 우회한다.
@END

@H2 7.15  실습 개요

@P 실습은 oel7v9 서버의 orcl 데이터베이스(19.3, non-CDB)에서 SCOTT.EMP를 대상으로 진행한다. 01에서 만든 정책 관리자 계정과 정책을 04까지 이어 쓰고, 05 마지막에 모두 철거한다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
7장_실습_01_정책함수와행수준정책 | 정책 관리자 계정, 정책 함수와 ADD_POLICY, 값이 없을 때 1=2, SYS 우회, ORA-28113과 트레이스 진단 | 7.3, 7.4
7장_실습_02_애플리케이션컨텍스트연결 | 컨텍스트와 신뢰 패키지, 직접 설정 시 ORA-01031, 세션 단위 값, 실행 계획의 정책 술어 | 7.2.2, 7.6
7장_실습_03_문장유형과update_check | INSERT와 update_check(ORA-28104), 기본 설정의 INSERT·UPDATE 허점, ORA-28101, ORA-28115 | 7.5.2, 7.5.4
7장_실습_04_컬럼수준VPD | sec_relevant_cols, ALL_ROWS와 ORA-28104, NULL과 집계, DBA_SEC_RELEVANT_COLS | 7.7
7장_실습_05_정책유형면제와관리 | CONTEXT_SENSITIVE, V$VPD_POLICY, EXEMPT ACCESS POLICY, ENABLE_POLICY, ORA-28102, 원복 | 7.8, 7.9, 7.10
@END
