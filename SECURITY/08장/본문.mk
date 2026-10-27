@H1 제8장  Data Redaction

@H2 8.1  학습 목표

@P 콜센터 직원은 고객 이름과 주소는 봐야 하지만 주민번호 뒷자리까지 볼 필요는 없다. Oracle Data Redaction은 저장된 데이터는 그대로 두고, 조회 결과가 애플리케이션으로 나가기 직전에 민감한 값을 가린다.

@B 정적 마스킹과 동적 마스킹(Data Redaction)의 차이를 설명하고 각각이 맞는 환경을 구분할 수 있다.
@B 리댁션 정책의 구성 요소(객체, 컬럼, 리댁션 방식, 정책 식)와 테이블당 정책 하나라는 제약을 설명할 수 있다.
@B FULL, PARTIAL, REGEXP, RANDOM, NULLIFY, NONE 방식의 결과를 자료형별로 예측할 수 있다.
@B 정책 식에 쓸 수 있는 함수와 연산자를 알고, 사용자·역할 기반 식을 작성할 수 있다.
@B `DBMS_REDACT.ADD_POLICY`, `ALTER_POLICY`, `ENABLE_POLICY`, `DROP_POLICY`로 정책을 만들고 바꾸고 지울 수 있다.
@B 리댁션이 막는 것(CTAS 복사)과 막지 못하는 것(조건절 추론)을 구분하고 관련 오류를 해석할 수 있다.
@B EXEMPT REDACTION POLICY 권한과 데이터 딕셔너리 뷰로 정책과 우회 경로를 점검할 수 있다.

@H2 8.2  Data Redaction의 개념

@H3 8.2.1  데이터 마스킹의 두 갈래

@P 데이터 마스킹은 실제 값을 가짜 값이나 가린 값으로 바꿔 민감 정보를 보호하는 기술이다. 언제, 어디서 바꾸느냐에 따라 두 갈래로 나뉜다.

@TBL
구분 | 정적 데이터 마스킹(SDM) | 동적 데이터 마스킹(DDM, Data Redaction)
바꾸는 시점 | 복제본을 만들 때 한 번 | 조회할 때마다
저장 데이터 | 복제본에 가린 값이 저장됨 | 원본 그대로, 결과만 바뀜
사용자별 차등 | 불가(복제본 전체가 같은 값) | 정책 식으로 사용자마다 다르게
주 사용 환경 | 개발·테스트·교육용 DB 구축 | 운영 DB에서 일부 사용자에게 부분 공개
되돌리기 | 불가(원래 값이 복제본에 없음) | 정책을 끄면 즉시 원래 값
대표 도구 | Oracle Data Masking and Subsetting | Oracle Data Redaction(DBMS_REDACT)
@END

@B 정적 마스킹은 운영 데이터를 개발 서버로 옮길 때 쓴다. 복제본에는 처음부터 가짜 값만 있으므로 개발자가 어떤 SQL을 써도 원래 값을 알 수 없다.
@B Data Redaction은 운영 DB 안에서 동작한다. 같은 테이블을 급여 담당자는 원래 값으로, 일반 직원은 가린 값으로 본다.
@B 이 장은 Data Redaction을 다룬다. 정적 마스킹은 Enterprise Manager 기반 별도 제품의 영역이다.

@H3 8.2.2  동작 시점과 범위

@B 리댁션은 SQL 실행이 끝나고 결과를 애플리케이션에 돌려주기 직전에 일어난다. 버퍼 캐시와 데이터 파일의 값은 바뀌지 않는다.
@B 그래서 WHERE, ORDER BY, GROUP BY, 조인은 원래 값으로 처리된다. 결과 행 수와 순서는 리댁션 여부와 관계없이 같다.
@B 리댁션은 SELECT 결과 값에 적용된다. 정책이 걸린 사용자가 리댁션된 컬럼을 CREATE TABLE AS SELECT나 INSERT ... SELECT로 다른 테이블에 옮기려 하면 ORA-28081로 거부된다.
@B 애플리케이션 코드를 고치지 않아도 된다. 같은 SQL이 사용자에 따라 다른 값을 받는다.
@B 테이블과 뷰에 정책을 걸 수 있다. 가상 컬럼, VPD 술어에 쓰이는 컬럼에는 걸 수 없다.

@CODE
SKING@orcl> SELECT employee_id, first_name, salary FROM hr.employees WHERE employee_id BETWEEN 100 AND 102 ORDER BY 1;

EMPLOYEE_ID FIRST_NAME     SALARY
----------- ---------- ----------
        100 Steven              0
        101 Neena               0
        102 Lex                 0

SCOTT@orcl> SELECT employee_id, first_name, salary FROM hr.employees WHERE employee_id BETWEEN 100 AND 102 ORDER BY 1;

EMPLOYEE_ID FIRST_NAME     SALARY
----------- ---------- ----------
        100 Steven          24000
        101 Neena           17000
        102 Lex             17000
@END

@B 같은 SQL, 같은 행인데 SALARY만 다르다. 정책 식이 SKING 세션에서는 TRUE, SCOTT 세션에서는 FALSE로 평가됐기 때문이다.

@H3 8.2.3  라이선스와 관련 기능

@B Data Redaction은 Oracle Advanced Security 옵션에 포함된 기능이다. Enterprise Edition에 옵션 라이선스가 추가로 필요하다. TDE(10장)도 같은 옵션에 속한다.
@B 실습 DB처럼 옵션이 설치되어 있으면 패키지는 동작한다. 사용 가능 여부와 라이선스 보유 여부는 별개다.

@TBL
기능 | 바꾸는 것 | 결과
Data Redaction | 결과 값 | 행은 그대로, 값만 0·공백·부분 가림·임의 값
VPD 컬럼 수준 ALL_ROWS(7장) | 결과 값 | 행은 그대로, 값이 NULL
VPD 행 수준(7장) | 결과 행 | 조건 밖의 행이 빠짐
DBMS_CRYPTO(9장) | 저장 값 | 암호문을 저장, 복호화 권한이 있어야 원래 값
TDE(10장) | 디스크의 값 | 파일·백업은 암호화, SQL 결과는 원래 값
@END

@B 리댁션과 TDE는 막는 대상이 다르다. TDE는 데이터 파일을 훔쳐 가는 공격을, 리댁션은 정상 접속한 사용자의 화면 노출을 줄인다. 둘을 함께 쓰는 경우가 많다.

@H3 8.2.4  어디에 쓰는가

@TBL
업무 | 가릴 값 | 원래 값을 볼 사람 | 흔히 쓰는 방식
콜센터 고객 조회 | 주민번호 뒷자리, 카드 번호 가운데 | 본인 확인 담당 팀 | REGEXP, PARTIAL
사내 인사 조회 | 급여, 상여 | 급여 담당 역할 | FULL, PARTIAL
운영 지원 화면 | 이메일, 전화번호 | 개인정보 담당자 | REGEXP
분석용 계정 | 생년월일 일자 | 없음 | 날짜 PARTIAL
외주 개발자 운영 확인 | 거의 모든 개인정보 | 없음 | FULL, RANDOM
@END

@B 공통점은 "행은 봐야 하지만 값 전체는 볼 필요가 없는 사용자"가 있다는 점이다. 행 자체를 숨겨야 하면 VPD가, 운영 DB와 분리된 복제본이면 정적 마스킹이 맞다.
@B 개인정보보호 관련 규정이 요구하는 "화면 표시 시 일부 가림"을 애플리케이션마다 따로 구현하지 않고 DB 한곳에서 처리할 수 있다.

@NOTE 원본 실습 자료와 다른 점
원본 자료는 NULL로 가리는 방식을 DBMS_REDACT.NULL로 적었다. 19c 패키지의 상수 이름은 DBMS_REDACT.NULLIFY다.
원본은 날짜의 FULL 값을 0000-00-00으로 설명했다. 19.3의 REDACTION_VALUES_FOR_TYPE_FULL에서 확인한 날짜 값은 2001-01-01이다.
원본은 SYSTEM에도 DBMS_REDACT 실행 권한을 줬다. 정책을 만드는 계정에만 주면 되므로 이 교안의 실습은 HR에만 줬다.
@END

@H2 8.3  리댁션 정책의 구성

@H3 8.3.1  네 가지 요소

@TBL
요소 | 설명 | 지정하는 곳
객체 | 정책을 걸 테이블 또는 뷰 | object_schema, object_name
컬럼 | 가릴 컬럼. 정책 하나에 여러 컬럼 | column_name, ALTER_POLICY ADD_COLUMN
리댁션 방식 | 컬럼마다 FULL, PARTIAL, REGEXP 등 | function_type, function_parameters, regexp_*
정책 식 | 리댁션을 적용할 세션 조건. TRUE면 리댁션 | expression
@END

@B 정책 식은 정책 전체에 하나다. 컬럼마다 다른 조건이 필요하면 이름 붙은 정책 식(8.4.4)을 컬럼에 연결한다.
@B 리댁션 방식은 컬럼마다 다르다. 같은 정책 안에서 급여는 FULL, 전화번호는 REGEXP, 입사일은 PARTIAL로 줄 수 있다.

@H3 8.3.2  테이블당 정책 하나

@B 한 테이블이나 뷰에는 리댁션 정책을 하나만 만들 수 있다. 두 번째 ADD_POLICY는 ORA-28069: A data redaction policy already exists on this object로 거부된다.
@B 컬럼을 더 가리려면 기존 정책에 `ALTER_POLICY`의 `ADD_COLUMN`으로 추가한다.
@B 같은 컬럼을 다른 조건으로 가려야 하는 별도 사용자 집단이 있으면 테이블 위에 뷰를 만들고 뷰에 두 번째 정책을 건다. 뷰가 겹치면 뷰 체인에서 가장 앞쪽 뷰의 정책이 쓰인다.
@B 이미 리댁션된 컬럼을 ADD_COLUMN으로 다시 추가하면 ORA-28060이 난다. 방식을 바꿀 때는 `MODIFY_COLUMN`을 쓴다.

@B 뷰와 NONE 정책을 함께 쓰는 예는 다음과 같다. 급여 담당자용 뷰에 NONE 정책을 걸면, 그 뷰를 통한 조회에는 테이블 정책 대신 뷰 정책이 적용되어 원래 값이 나간다.

@CODE
CREATE VIEW hr.emp_payroll_v AS SELECT employee_id, last_name, salary FROM hr.employees;
BEGIN
  DBMS_REDACT.ADD_POLICY(
    object_schema => 'HR',
    object_name   => 'EMP_PAYROLL_V',
    policy_name   => 'PAYROLL_VIEW_NONE',
    expression    => '1=1',
    column_name   => 'SALARY',
    function_type => DBMS_REDACT.NONE);
END;
/
@END

@B 이 뷰의 SELECT 권한은 급여 담당자에게만 준다. 뷰 권한 관리가 곧 원래 값 노출 범위가 되므로 권한 부여를 감사한다.

@H3 8.3.3  필요한 권한

@B 정책을 만들고 관리하려면 `DBMS_REDACT` 실행 권한이 필요하다. 19.3 기본 상태에서 이 권한은 EXECUTE_CATALOG_ROLE과 IMP_FULL_DATABASE에만 있고 PUBLIC에는 없다.
@B 권한 없이 호출하면 PL/SQL 컴파일 단계에서 PLS-00201: identifier 'DBMS_REDACT' must be declared가 난다.
@B 자기 스키마의 객체에는 CREATE TABLE(또는 CREATE ANY TABLE)이, 다른 스키마의 객체에는 CREATE ANY TABLE이 함께 필요하다.
@B `UPDATE_FULL_REDACTION_VALUES`는 DB 전체의 FULL 리댁션 값을 바꾸므로 항상 CREATE ANY TABLE이 필요하다.
@B 데이터 소유자에게 정책 권한을 주면 소유자가 자기 정책을 끌 수 있다. 업무 규모가 크면 보안 관리자 계정을 따로 두고 CREATE ANY TABLE과 실행 권한을 준다.

@CODE
SYS@orcl> GRANT EXECUTE ON DBMS_REDACT TO hr;
HR@orcl> BEGIN
  2    DBMS_REDACT.ADD_POLICY(
  3      object_schema => 'HR',
  4      object_name   => 'EMPLOYEES',
  5      policy_name   => 'MASK_SALARY_POLICY',
  6      expression    => 'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') NOT IN (''SCOTT'', ''HR'')',
  7      column_name   => 'SALARY',
  8      function_type => DBMS_REDACT.FULL);
  9  END;
 10  /
@END

@H3 8.3.4  정책을 누가 소유하는가

@B 실습은 단순하게 하려고 데이터 소유자 HR에게 실행 권한을 줘서 HR이 직접 정책을 만들었다.
@B 운영에서는 데이터 소유자가 정책을 끄거나 정책 식을 고쳐 자신이 원래 값을 보게 만들 수 있다는 점이 문제가 된다.
@B 보안 관리자 계정을 따로 두고 DBMS_REDACT 실행 권한과 CREATE ANY TABLE을 준다. 데이터 소유자에게는 실행 권한을 주지 않는다.
@B CREATE ANY TABLE은 리댁션 외에도 강력한 권한이다. 보안 관리자 계정의 접속과 사용을 감사 대상으로 둔다.

@H2 8.4  정책 식

@H3 8.4.1  TRUE일 때 리댁션된다

@B 정책 식이 TRUE로 평가되는 세션에서 값이 가려진다. FALSE면 원래 값이 나간다.
@B 모든 사용자에게 적용하려면 `expression => '1=1'`을 준다. 이때도 SYS와 EXEMPT REDACTION POLICY 보유자는 제외된다.
@B 식은 조회할 때마다 평가된다. 세션 속성이 바뀌면 같은 세션에서도 결과가 달라질 수 있다.
@B NULL과의 비교는 FALSE가 되기 쉽다. `SYS_CONTEXT('USERENV','CLIENT_IDENTIFIER') != 'ADMIN'`은 CLIENT_IDENTIFIER가 설정되지 않은 세션에서 NULL 비교가 되어 리댁션이 일어나지 않는다. 식을 쓸 때 값이 없는 경우를 먼저 생각한다.

@H3 8.4.2  쓸 수 있는 함수와 연산자

@TBL
구분 | 허용되는 것
연산자 | AND, OR, IN, NOT IN, =, !=, <>, <, >, <=, >=
컨텍스트 함수 | SYS_CONTEXT, XS_SYS_CONTEXT (USERENV, SYS_SESSION_ROLES, XS$SESSION, DBA_CONTEXT에 있는 사용자 정의 네임스페이스)
문자열 함수 | SUBSTR 계열, LENGTH 계열. 첫 인자는 상수 문자열이나 SYS_CONTEXT 호출
기타 | Application Express의 V, NV. Label Security의 OLS_ 계열 함수
@END

@B 사용자가 만든 PL/SQL 함수와 목록에 없는 내장 함수(NVL 등)는 정책 식에 쓸 수 없다. 19.3에서 `hr.is_manager = 'N'` 같은 식은 ORA-28086과 ORA-28088: The policy expression has an unsupported PL/SQL function으로 거부됐다.
@B 복잡한 판단이 필요하면 사용자 정의 애플리케이션 컨텍스트(6장)에 결과를 넣어 두고, 정책 식에서는 `SYS_CONTEXT('네임스페이스','속성') = '값'`만 비교한다.
@B 정책 식의 최대 길이를 넘으면 ORA-28062, 빈 식은 ORA-28063이 난다.

@H3 8.4.3  사용자 기반과 역할 기반

@B 사용자 이름으로 판정하는 식은 이해하기 쉽지만 사람이 바뀔 때마다 정책을 고쳐야 한다.
@B 역할로 판정하면 권한 부여만으로 리댁션 대상이 바뀐다. `SYS_CONTEXT('SYS_SESSION_ROLES', '역할명')`은 그 역할이 세션에서 활성화되어 있으면 'TRUE', 아니면 'FALSE'를 돌려준다.
@B 역할 기반 식은 "역할이 없으면 리댁션"으로 쓴다. 역할 이름을 잘못 쓰면 그 역할을 가진 세션이 없으므로 모든 사용자에게 리댁션이 일어난다. 원래 값이 새어 나가는 방향으로는 틀리지 않는다.

@CODE
BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema => 'HR',
    object_name   => 'EMPLOYEES',
    policy_name   => 'MASK_SALARY_POLICY',
    action        => DBMS_REDACT.MODIFY_EXPRESSION,
    expression    => 'SYS_CONTEXT(''SYS_SESSION_ROLES'', ''HR_PAYROLL'') = ''FALSE''');
END;
/
@END

@B 애플리케이션이 공용 계정으로 접속하는 구조에서는 SESSION_USER가 모두 같다. 이때는 CLIENT_IDENTIFIER나 사용자 정의 컨텍스트로 실제 사용자를 구분한다(6장).

@B 사용자 정의 컨텍스트를 쓰는 식은 다음과 같다. 로그인 트리거가 HR_APP_CTX.CLEARANCE에 등급을 넣어 두면, 정책 식은 그 값만 비교한다.

@CODE
expression => 'SYS_CONTEXT(''HR_APP_CTX'', ''CLEARANCE'') != ''HIGH'''
@END

@B 컨텍스트 값이 없는 세션에서는 비교 결과가 NULL이 되어 식이 TRUE가 되지 않는다. 리댁션이 일어나지 않는 쪽으로 열린다.
@B 값이 없을 때도 가리려면 IS NULL 조건을 OR로 묶는다. 19.3에서 아래 식은 정상 등록됐다. 허용 연산자 표에 없는 IS NULL이지만 실제로는 받아들여진다.

@CODE
expression => 'SYS_CONTEXT(''HR_APP_CTX'', ''CLEARANCE'') != ''HIGH'' OR SYS_CONTEXT(''HR_APP_CTX'', ''CLEARANCE'') IS NULL'
@END

@B NVL로 기본값을 채우는 식은 거부된다. 19.3에서 `NVL(SYS_CONTEXT(...), 'NONE') != 'X'`는 ORA-28086, ORA-28087: The policy expression has an unsupported (use of) operator 'NVL'로 실패했다.
@B 정책 식은 문법 검사가 엄격하다. 운영 반영 전에 enable => FALSE로 만들어 등록 단계의 오류부터 걸러 낸다.

@H3 8.4.4  이름 붙은 정책 식

@B 12.2부터 정책 식에 이름을 붙여 따로 만들고 여러 컬럼에 연결할 수 있다. `CREATE_POLICY_EXPRESSION`으로 만들고 `APPLY_POLICY_EXPR_TO_COL`로 연결한다.
@B 컬럼에 연결된 이름 붙은 식은 그 컬럼에서 정책 기본 식보다 우선한다. 한 테이블 안에서 컬럼마다 다른 조건을 줄 수 있다.
@B `UPDATE_POLICY_EXPRESSION`으로 식을 고치면 연결된 모든 컬럼에 즉시 반영된다. 같은 조건을 여러 테이블에 쓰는 환경에서 관리가 쉬워진다.
@B 컬럼에 연결된 식은 지울 수 없다. 19.3에서 연결된 상태로 `DROP_POLICY_EXPRESSION`을 호출하면 ORA-28092가 났다. `APPLY_POLICY_EXPR_TO_COL`에 NULL을 줘서 연결을 끊은 뒤 지운다.
@B 이름 붙은 식은 COMPATIBLE 12.2.0 이상이 필요하고 다른 PDB의 컬럼에는 연결할 수 없다. REDACTION_EXPRESSIONS 뷰에서 식과 연결된 컬럼을 본다.
@B 이름 붙은 식은 특정 스키마에 속하지 않고 어느 스키마의 정책에서나 참조된다. 그래서 문서 기준으로 19c RU 19.32 이후에는 CREATE_POLICY_EXPRESSION, UPDATE_POLICY_EXPRESSION, DROP_POLICY_EXPRESSION이 자기 스키마 작업이라도 항상 CREATE ANY TABLE을 요구한다. 실습 DB 19.3에는 해당하지 않는다.
@B 패치 후 기존 정책 관리 스크립트가 권한 부족으로 멈출 수 있다. RU 적용 계획에 보안 관리자 계정의 권한 점검을 넣는다.

@NOTE 컬럼 식이 정책 식을 덮어쓴다
실습에서 정책 기본 식은 "HR_PAYROLL 역할이 없으면 리댁션"이었다. SALARY에 "HR이 아니면 리댁션"이라는 이름 붙은 식을 연결하자, 역할을 가진 SCOTT에게도 급여가 가려졌다.
정책 식만 보고 "이 사용자는 원래 값을 본다"고 판단하면 틀릴 수 있다. 점검할 때는 REDACTION_POLICIES와 REDACTION_EXPRESSIONS를 함께 본다.
@END

@H3 8.4.5  정책 식 시험하기

@B 정책 식이 어떻게 평가될지는 대상 사용자 세션에서 식에 쓰인 값을 직접 조회해 확인한다. `SELECT SYS_CONTEXT('USERENV','SESSION_USER'), SYS_CONTEXT('SYS_SESSION_ROLES','HR_PAYROLL') FROM dual`처럼 식의 재료를 그대로 본다.
@B 역할 판정은 세션에서 활성화된 역할을 본다. 역할을 받았어도 기본 역할이 아니면 로그인 직후에는 FALSE다.
@B 공용 계정 구조라면 애플리케이션이 CLIENT_IDENTIFIER나 컨텍스트를 설정한 다음에 조회가 일어나는지 확인한다. 설정 전에 실행되는 초기 조회는 다른 판정을 받는다.
@B 정책을 enable => FALSE로 만들어 둔 상태에서 식 재료를 확인하고, 시험 계정 하나로 ENABLE 후 결과를 본 다음 운영 계정에 넓힌다.

@H2 8.5  리댁션 방식

@H3 8.5.1  방식 한눈에 보기

@TBL
상수 | 값 | 결과
DBMS_REDACT.NONE | 0 | 가리지 않음(시험용, 뷰 예외용)
DBMS_REDACT.FULL | 1 | 자료형별 고정 값. 기본 방식
DBMS_REDACT.PARTIAL | 2 | 지정한 위치만 가림
DBMS_REDACT.RANDOM | 4 | 조회할 때마다 다른 임의 값
DBMS_REDACT.REGEXP | 5 | 정규식에 맞는 부분을 치환
DBMS_REDACT.NULLIFY | 6 | NULL
DBMS_REDACT.REGEXP_WIDTH | 7 | REGEXP와 같되 컬럼 폭 유지(특정 OLE DB 클라이언트용)
@END

@TBL
자료형 | FULL | PARTIAL | REGEXP | RANDOM
문자(CHAR, VARCHAR2, NCHAR, NVARCHAR2) | 가능 | 가능 | 가능 | 가능
숫자(NUMBER, FLOAT, BINARY_FLOAT·DOUBLE) | 가능 | 가능 | 불가 | 가능
날짜(DATE, TIMESTAMP 계열) | 가능 | 가능 | 불가 | 가능
BLOB | 가능 | 불가 | 불가 | 불가
CLOB, NCLOB | 가능 | 불가 | 가능 | 불가
RAW, LONG RAW, INTERVAL, BFILE, ROWID | 불가 | 불가 | 불가 | 불가
@END

@B 사용자 정의 타입, XMLType, 공간 데이터 타입은 어떤 방식도 지원하지 않는다. 지원하지 않는 자료형 컬럼을 지정하면 ORA-28073이 난다.

@H3 8.5.2  FULL

@B 기본 방식이다. function_type을 생략하면 FULL이 된다.
@B 숫자는 0, 문자는 공백 한 칸, 날짜는 2001-01-01로 바뀐다. CLOB은 [redacted]라는 문자열이 된다.
@B 현재 값은 REDACTION_VALUES_FOR_TYPE_FULL 뷰에서 본다. `DBMS_REDACT.UPDATE_FULL_REDACTION_VALUES`로 바꿀 수 있지만 DB의 모든 FULL 정책에 영향을 준다.
@B 숫자 0은 "값이 0"과 구분되지 않는다. 보고서에서 합계를 내면 조용히 틀린 값이 나온다. 숫자 컬럼을 가릴 때는 화면 사용자가 0을 실제 값으로 오해하지 않는지 먼저 확인한다.

@B 기본값 변경은 다음처럼 한다. 숫자 FULL 값을 0 대신 -1로 바꾸면 "가려진 값"과 "실제 0"을 화면에서 구분할 수 있다. 인자를 준 자료형만 바뀌고 나머지는 그대로다.

@CODE
BEGIN
  DBMS_REDACT.UPDATE_FULL_REDACTION_VALUES(number_val => -1);
END;
/
@END

@B 이 변경은 DB의 모든 FULL 리댁션 정책에 적용된다. 다른 애플리케이션이 숫자 0을 기대하고 있었다면 영향을 받으므로 공유 DB에서는 변경하지 않는 편이 안전하다. 실습에서는 기본값을 바꾸지 않았다.

@H3 8.5.3  PARTIAL

@B 값의 일부만 가린다. 형식은 자료형마다 다르다.

@TBL
자료형 | function_parameters 형식 | 예와 결과
문자 | 입력 형식,출력 형식,가림 문자,시작,끝 | 'VVVFVVVVFVVVV,VVV-VVVV-VVVV,X,4,7' → 010-XXXX-2222
숫자 | 가림 숫자,시작,끝 | '9,1,2' → 24000이 99000
날짜 | 월 일 연 시 분 초 순서의 문자. 소문자 뒤 숫자는 그 값으로 고정, 대문자는 유지 | 'm1d1YHMS' → 2003-06-17이 2003-01-01
@END

@B 문자 형식의 V는 가릴 수 있는 자리, F는 하이픈 같은 고정 문자 자리다. 출력 형식에서 F 자리를 다른 문자로 바꿔 보여 줄 수도 있다.
@B 미국 주민번호, 카드 번호처럼 흔한 형식은 `DBMS_REDACT.REDACT_US_SSN_F5`(XXX-XX-4320), `REDACT_NUM_US_SSN_F5` 같은 미리 정의된 상수가 있다.
@B 문자 PARTIAL은 자리 위치를 바이트 기준 고정 폭으로 다룬다. 매뉴얼은 UTF-8 같은 가변 폭 문자셋에서는 정규식 방식을 쓰라고 한다.
@B 19.3 AL32UTF8 DB에서도 ASCII로만 된 전화번호에는 문자 PARTIAL이 동작했다. 한글처럼 여러 바이트 문자가 섞인 컬럼에서는 위치가 어긋날 수 있으므로 REGEXP를 쓴다.
@B 데이터 폭이 일정해야 한다. 길이가 들쭉날쭉한 값에는 PARTIAL이 맞지 않는다.

@H3 8.5.4  REGEXP

@B 정규식에 맞는 부분을 치환 문자열로 바꾼다. regexp_pattern(최대 512바이트), regexp_replace_string(역참조 \1~\9), regexp_position, regexp_occurrence, regexp_match_parameter를 쓴다.
@B 주민번호 뒷자리는 `'([0-9]{6}-)([0-9]{7})'`과 `'\1#######'`로, 전화번호 가운데 자리는 `'([0-9]{3})-([0-9]{4})-([0-9]{4})'`와 `'\1-XXXX-\3'`으로 가린다.
@B 패턴에 맞지 않는 값은 그대로 나가지 않고 FULL 리댁션된다. 실습에서 하이픈 없이 저장된 주민번호는 공백으로 나왔다.
@B 이 동작은 안전한 쪽으로 닫혀 있지만, 형식이 섞인 데이터에서는 일부 행이 통째로 공백이 되어 업무에 지장을 준다. 데이터 형식을 먼저 정리하거나 패턴을 넓힌다.
@B 이메일, 전화번호, 카드 번호용 미리 정의된 패턴 상수도 있다.

@CODE
BEGIN
  DBMS_REDACT.ADD_POLICY(
    object_schema         => 'HR',
    object_name           => 'CUSTOMERS',
    policy_name           => 'MASK_CUST_POLICY',
    expression            => 'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') != ''HR''',
    column_name           => 'SSN_NO',
    function_type         => DBMS_REDACT.REGEXP,
    regexp_pattern        => '([0-9]{6}-)([0-9]{7})',
    regexp_replace_string => '\1#######');
END;
/
@END

@H3 8.5.5  RANDOM, NULLIFY, NONE

@B RANDOM은 조회할 때마다 다른 값을 돌려준다. VARCHAR2는 실제 길이만큼의 임의 문자열, 숫자는 원래 값의 절댓값 범위 안의 임의 수, 날짜는 원래와 다른 임의 날짜가 된다.
@B 같은 행을 두 번 조회해도 값이 다르므로 화면 사용자는 리댁션됐음을 알아챈다. 실습에서 145번 사원의 이메일은 두 번의 조회에서 서로 다른 문자열로 나왔다. 대신 형식 검증을 하는 애플리케이션에서 오류가 날 수 있다.
@B NULLIFY는 값을 NULL로 바꾼다. NULL을 허용하지 않는다고 가정한 애플리케이션 코드에서 예외가 날 수 있고, "원래 값이 없는 것"과 구분되지 않는다. 실습에서 커미션이 있던 사원과 없던 사원이 똑같이 보였다.
@B NONE은 가리지 않는다. 정책 시험용이거나, 리댁션된 테이블 위의 뷰에 NONE 정책을 걸어 특정 사용자 집단에 원래 값을 보여 줄 때 쓴다.

@H3 8.5.6  방식 고르기

@TBL
요구 | 맞는 방식 | 주의
값의 존재조차 숨김 | FULL, NULLIFY | 숫자 0·NULL이 실제 값과 구분되지 않음
형식을 유지하며 일부만 표시 | PARTIAL(고정 폭), REGEXP(가변) | 형식이 섞이면 REGEXP 불일치 행은 FULL
가렸다는 사실을 화면에 드러냄 | REGEXP(# 또는 * 치환) | 치환 문자가 원래 데이터에 없는지 확인
시험 데이터처럼 그럴듯한 값 | RANDOM | 조회마다 바뀌어 화면 비교·캐시에 혼란
특정 사용자 집단에만 원래 값 | 뷰 + NONE 정책 | 뷰 체인에서 가장 앞쪽 정책이 적용됨
@END

@BP 방식 선택 전에 확인할 것
애플리케이션이 그 컬럼을 계산이나 검증에 쓰는지 본다. 쓴다면 FULL과 RANDOM은 오류나 잘못된 결과를 만든다.
같은 컬럼의 데이터 형식이 모두 같은지 확인한다. REGEXP는 패턴 불일치 행을 통째로 가린다.
가린 값이 "가려졌다"고 보이는 것이 좋은지, 정상 값처럼 보이는 것이 좋은지 업무 담당자와 정한다.
@END

@CASE 콜센터 화면에서 주민번호 칸이 비어 있다
고객 테이블에 REGEXP 정책을 걸어 주민번호 뒷자리를 가렸다. 대부분 고객은 900101-####### 형태로 잘 보였는데, 일부 고객은 주민번호 칸이 아예 비어 있다는 문의가 들어왔다.
해당 고객들의 데이터를 HR 계정으로 확인하니 하이픈 없이 13자리로 저장돼 있었다. 패턴이 맞지 않아 FULL 리댁션이 적용되어 공백이 나간 것이다.
데이터 이관 때 형식이 섞인 것이 원인이었다. 패턴을 `'([0-9]{6})-?([0-9]{7})'`처럼 하이픈을 선택 사항으로 바꾸는 방법과 저장 형식을 통일하는 방법 중, 입력 검증까지 함께 고치는 후자를 택했다.
@END

@CASE NULLIFY를 적용했더니 정산 배치가 멈췄다
고객 테이블의 계좌 번호에 NULLIFY 정책을 걸고 정책 식을 "정산 역할이 없으면 리댁션"으로 줬다. 다음 날 새벽 정산 배치가 NullPointerException으로 중단됐다.
배치 프로그램은 별도 계정으로 접속하고 있었고 그 계정에는 정산 역할이 부여돼 있었다. 그런데 역할이 기본 역할(DEFAULT ROLE)로 지정되지 않아 로그인 직후 세션에서 비활성 상태였다. SYS_SESSION_ROLES 판정이 FALSE가 되어 계좌 번호가 NULL로 나갔다.
배치 계정의 기본 역할을 고쳐 해결했다. 이후 정책 식에 쓰는 역할은 대상 계정의 DBA_ROLE_PRIVS.DEFAULT_ROLE까지 확인하는 절차를 넣었다.
@END

@H2 8.6  정책 생성과 관리 — DBMS_REDACT

@H3 8.6.1  ADD_POLICY의 인자

@TBL
인자 | 의미 | 기본값
object_schema, object_name | 정책을 걸 테이블·뷰 | 현재 사용자, (필수)
policy_name | 정책 이름 | (필수)
column_name | 처음 가릴 컬럼 하나 | NULL(컬럼 없는 정책)
function_type | 리댁션 방식 | DBMS_REDACT.FULL
function_parameters | PARTIAL 형식 | NULL
expression | 정책 식 | (필수)
enable | 만들면서 바로 활성화 | TRUE
regexp_pattern 등 | REGEXP 방식 인자 | NULL, 위치 1, 전체 치환
policy_description, column_description | 설명 | NULL
@END

@B 인자는 이름 지정 방식(`=>`)으로 쓴다. 19.3에서 `ADD_POLICY('HR','EMPLOYEES','T_FULL','SALARY', expression=>'1=1')`처럼 네 번째 값을 위치로 넘기자 오류 없이 등록됐지만 REDACTION_COLUMNS에 컬럼이 없었다. 19.3의 ADD_POLICY 인자 순서(DBA_ARGUMENTS)에서 네 번째는 POLICY_DESCRIPTION, 다섯 번째가 COLUMN_NAME이다. 'SALARY'는 정책 설명으로 들어갔고 컬럼 없는 정책이 만들어졌다. 리댁션이 안 되는데 오류도 없으므로 알아채기 어렵다.
@B column_name을 비워 두면 컬럼 없는 정책이 만들어진다. 정책 식을 먼저 정해 두고 컬럼은 나중에 ALTER_POLICY로 붙이는 방식도 가능하다.
@B enable => FALSE로 만들어 두고 시험이 끝난 뒤 ENABLE_POLICY로 켜는 방식이 운영 반영에 안전하다.

@H3 8.6.2  ALTER_POLICY

@TBL
action | 하는 일 | 함께 주는 인자
ADD_COLUMN (기본) | 컬럼 추가 | column_name, function_type, 방식별 인자
DROP_COLUMN | 컬럼 제거 | column_name
MODIFY_COLUMN | 컬럼의 방식·인자 변경 | column_name, function_type, 방식별 인자
MODIFY_EXPRESSION | 정책 식 변경 | expression
SET_POLICY_DESCRIPTION | 정책 설명 | policy_description
SET_COLUMN_DESCRIPTION | 컬럼 설명 | column_name, column_description
@END

@B 한 번 호출에 하나의 action만 처리한다. 여러 컬럼을 바꿀 때는 한 PL/SQL 블록 안에서 여러 번 부른다.
@B action을 빼먹으면 기본값 ADD_COLUMN으로 동작한다. 기존 컬럼의 방식을 바꾸려다 action을 빠뜨리면 ORA-28060이 난다.

@H3 8.6.3  끄기, 켜기, 지우기

@B `DISABLE_POLICY`는 정의를 남긴 채 정책을 끈다. 이미 꺼진 정책을 또 끄면 ORA-28080이 난다. 켜는 것은 `ENABLE_POLICY`다.
@B `DROP_POLICY`는 정책을 지운다. 정책이 없는 객체에 대해 호출하면 ORA-28068: The object does not have a data redaction policy가 난다.
@B 정책을 끄는 순간 모든 사용자가 원래 값을 본다. 정책 끄기와 지우기는 감사 대상 작업으로 다룬다.
@B 원본 실습 자료는 정책 삭제 블록에서 SQLCODE -28109를 예외 처리했다. 19.3에서 "정책 없음"은 ORA-28068이었다. 반복 실행용 정리 스크립트를 쓸 때는 실제 오류 번호를 확인한다.

@CODE
EXEC DBMS_REDACT.DISABLE_POLICY('HR', 'CUSTOMERS', 'MASK_CUST_POLICY')
EXEC DBMS_REDACT.ENABLE_POLICY('HR', 'CUSTOMERS', 'MASK_CUST_POLICY')
EXEC DBMS_REDACT.DROP_POLICY('HR', 'CUSTOMERS', 'MASK_CUST_POLICY')
@END

@H3 8.6.4  여러 컬럼을 한 번에 구성하기

@P 한 정책에 컬럼을 여러 개 붙일 때는 ADD_POLICY로 첫 컬럼과 정책 식을 정하고, 나머지는 같은 블록에서 ALTER_POLICY로 붙인다. 실습 03에서 쓴 구성이다.

@CODE
BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema => 'HR', object_name => 'EMPLOYEES', policy_name => 'MASK_SALARY_POLICY',
    action        => DBMS_REDACT.ADD_COLUMN,
    column_name   => 'COMMISSION_PCT',
    function_type => DBMS_REDACT.NULLIFY);
  DBMS_REDACT.ALTER_POLICY(
    object_schema       => 'HR', object_name => 'EMPLOYEES', policy_name => 'MASK_SALARY_POLICY',
    action              => DBMS_REDACT.ADD_COLUMN,
    column_name         => 'HIRE_DATE',
    function_type       => DBMS_REDACT.PARTIAL,
    function_parameters => 'm1d1YHMS');
  DBMS_REDACT.ALTER_POLICY(
    object_schema       => 'HR', object_name => 'EMPLOYEES', policy_name => 'MASK_SALARY_POLICY',
    action              => DBMS_REDACT.MODIFY_COLUMN,
    column_name         => 'SALARY',
    function_type       => DBMS_REDACT.PARTIAL,
    function_parameters => '9,1,2');
END;
/
@END

@B 결과는 커미션 NULL, 입사일은 연도만 남고 01-01, 급여는 앞 두 자리가 9로 바뀐다(24000이 99000, 8300이 9900).
@B 중간 호출이 실패하면 앞의 호출은 이미 반영돼 있다. 실패 후에는 REDACTION_COLUMNS로 어디까지 들어갔는지 확인하고 이어서 처리한다.

@B 정책과 컬럼에는 설명을 남겨 둔다. 몇 달 뒤 정책을 점검하는 사람이 왜 이 컬럼을 이 방식으로 가렸는지 알 수 있다.

@CODE
BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema      => 'HR',
    object_name        => 'EMPLOYEES',
    policy_name        => 'MASK_SALARY_POLICY',
    action             => DBMS_REDACT.SET_POLICY_DESCRIPTION,
    policy_description => '급여 담당 역할(HR_PAYROLL) 외 급여·상여 가림. 2026-10 인사팀 요청');
END;
/
@END

@H3 8.6.5  자주 만나는 오류

@TBL
오류 | 상황
PLS-00201 | DBMS_REDACT 실행 권한 없음
ORA-28060 | 이미 리댁션된 컬럼을 ADD_COLUMN
ORA-28068 | 정책이 없는 객체에 DROP·ALTER
ORA-28069 | 정책이 있는 객체에 두 번째 ADD_POLICY
ORA-28073 | 지원하지 않는 자료형 컬럼
ORA-28080 | 이미 꺼진 정책을 DISABLE
ORA-28081 | 리댁션된 컬럼을 CTAS·INSERT SELECT로 복사
ORA-28086, ORA-28088 | 정책 식에 사용자 PL/SQL 함수
ORA-28086, ORA-28087 | 정책 식에 허용되지 않는 연산자·함수(NVL 등)
ORA-28092 | 컬럼에 연결된 이름 붙은 식을 삭제(19.3)
ORA-28094 | 뷰 정의 안에서 리댁션 컬럼을 연산(19.3)
@END

@H2 8.7  리댁션이 막는 것과 막지 못하는 것

@H3 8.7.1  조건절 추론

@B 조건절은 원래 값으로 평가된다. 급여가 모두 99000으로 보이는 사용자도 `WHERE salary > 15000`을 쓰면 실제로 15000을 넘는 사원만 돌려받는다.
@B 범위를 좁혀 가면 값을 알아낼 수 있다. `WHERE salary BETWEEN 23999 AND 24001`이 1건이면 그 사원의 급여는 24000이다.
@B ORDER BY도 원래 값으로 정렬된다. 값은 가려져 있어도 순위는 그대로 드러난다.
@B 매뉴얼도 Data Redaction이 임의 SQL을 작성할 수 있는 사용자의 추론 공격을 막기 위한 기능이 아니라고 밝힌다. 화면이 정해진 애플리케이션 사용자의 노출을 줄이는 데 맞다.
@B 임의 SQL 사용자에게서 값을 완전히 숨겨야 하면 VPD 컬럼 수준(7장)이나 권한 분리, 암호화(9장)를 함께 쓴다.

@CODE
SKING@orcl> SELECT COUNT(*) FROM hr.employees WHERE salary BETWEEN 23999 AND 24001;

  COUNT(*)
----------
         1
@END

@H3 8.7.2  값 복사 차단

@B 리댁션 대상 사용자가 리댁션된 컬럼을 CREATE TABLE AS SELECT로 복사하면 ORA-28081: Insufficient privileges - the command references a redacted object가 난다. INSERT ... SELECT도 같다.
@B 리댁션 대상이 아닌 컬럼만 고르면 같은 테이블에서도 복사가 된다. 실습에서 FIRST_NAME만 고른 CTAS는 107건으로 성공했다.
@B EXEMPT REDACTION POLICY를 가진 사용자는 원래 값을 복사할 수 있다. 복사된 테이블에는 정책이 없으므로 이후 누구에게나 원래 값이 보인다.

@H3 8.7.3  뷰와 리댁션

@B 리댁션된 컬럼을 그대로 노출하는 뷰는 리댁션된 값을 돌려준다. 원래 테이블의 정책이 뷰를 통해서도 적용된다.
@B 19.3에서는 뷰 정의 안에서 리댁션 컬럼을 가공(`salary * 12`)하면 조회 시 ORA-28094: SQL construct not supported by data redaction이 났다.
@B 같은 계산을 바깥 조회에서 하면 리댁션된 값 기준으로 계산된다. 99000으로 보이는 급여에 12를 곱해 1188000이 나온다. 계산 결과도 의미 없는 값이 되므로 화면 설계 때 고려한다.
@B 뷰에 별도 정책을 거는 방식은 8.3.2에서 본 것처럼 같은 컬럼을 사용자 집단마다 다르게 가릴 때 쓴다.

@H3 8.7.4  VPD와 함께 쓰기

@B 행 단위 제한은 VPD, 값 가림은 Data Redaction으로 나눠 함께 쓸 수 있다. 부서장은 자기 부서 사원만 보고(VPD), 그중 급여는 급여 담당 역할이 있을 때만 원래 값으로 본다(Redaction).
@B VPD 정책 함수가 만드는 술어에 쓰이는 컬럼에는 리댁션 정책을 걸 수 없다. 부서 번호로 행을 거른다면 부서 번호 컬럼은 리댁션 대상에서 뺀다.
@B 두 기능 모두 SYS에는 적용되지 않고, 면제 권한이 각각 따로 있다(EXEMPT ACCESS POLICY, EXEMPT REDACTION POLICY). 점검 목록에 둘 다 넣는다.

@CASE 연봉 화면이 갑자기 오류를 낸다
인사 시스템에 급여 리댁션 정책을 적용한 다음 날, 일반 직원용 "부서 연봉 현황" 화면이 ORA-28094로 열리지 않았다. 급여 담당자 화면은 정상이었다.
화면이 조회하는 뷰가 `salary * 12 + NVL(commission_pct, 0) * salary * 12` 같은 계산식을 담고 있었다. 리댁션 대상 사용자가 이 뷰를 조회하자 데이터베이스가 계산된 컬럼을 어떻게 가려야 할지 정하지 못했다.
일반 직원에게는 원래 연봉이 필요 없었으므로 뷰에서 계산 컬럼을 빼고, 계산은 급여 담당자 화면에서만 하도록 나눴다. 정책 적용 전에 리댁션 대상 사용자로 관련 뷰를 모두 조회해 보는 절차를 체크리스트에 넣었다.
@END

@H3 8.7.5  Data Pump와 리댁션

@P 아래 동작은 Advanced Security Guide의 "Oracle Data Redaction and Data Pump" 절이 설명하는 내용이다. 실습 DB에서는 Data Pump를 돌리지 않았다.

@B 리댁션 정책이 걸린 객체를 내보내면 실제 값이 리댁션되지 않은 채 덤프에 들어간다. 내보내기를 하는 DATAPUMP_EXP_FULL_DATABASE 역할에 EXEMPT REDACTION POLICY가 들어 있기 때문이다.
@B 정책 정의도 기본으로 함께 내보내지고 가져와진다. 대상 DB에서도 같은 정책 식이 평가되므로 조회 결과는 여전히 가려진다.
@B EXP_FULL_DATABASE가 없는 사용자가 스키마 단위로 내보내면 ORA-31696: unable to export/import TABLE_DATA ... using client specified DIRECT_PATH method가 날 수 있다. direct_path 없이 다시 돌리면 실제 원인인 ORA-28081이 드러난다.
@B 가져오기에서 CONTENT=ALL이나 METADATA_ONLY를 쓰면 대상 테이블에 있던 리댁션 정책이 지워지므로 다시 만들어야 한다. CONTENT=DATA_ONLY는 정책을 남긴다. 대상에 이미 정책이 있는 채로 정책 정의를 가져오면 ORA-28069와 충돌한다.
@B 원래 값이 든 덤프 파일은 원본 테이블만큼 민감하다. ENCRYPTION 파라미터로 덤프를 암호화하고(10장) 파일 보관 위치를 제한한다.

@H3 8.7.6  다른 기능과 함께 쓸 때

@TBL
기능 | 리댁션과의 관계(문서 기준)
DML의 RETURNING INTO | 조회로 취급되어 리댁션 적용
Database Vault realm | realm 권한이 없으면 EXEMPT REDACTION POLICY가 있어도 데이터를 보지 못함
구체화 뷰 query rewrite | 원 테이블의 정책은 지켜짐. 구체화 뷰 자체에 건 정책은 rewrite 경로에서 효과 없음
DB 링크를 참조하는 뷰 | 정책을 만들지 말 것
editioned view | 리댁션 불가
IS JSON 제약 컬럼 | ORA-28073(지원하지 않는 자료형)
Data Mining | 내부 DML·DDL 때문에 EXEMPT REDACTION POLICY가 필요할 수 있음
@END

@B 구체화 뷰에 정책을 걸어 두고 안심하면 안 된다. 사용자는 원 테이블을 조회했는데 옵티마이저가 구체화 뷰로 바꿔 읽는 경우, 적용되는 것은 원 테이블의 정책이다.

@H2 8.8  면제와 우회 점검

@B SYS와 EXEMPT REDACTION POLICY 시스템 권한 보유자는 모든 리댁션 정책을 건너뛴다. 특정 테이블만 면제하는 권한은 없다.
@B DBA 역할에는 EXP_FULL_DATABASE를 통해 EXEMPT REDACTION POLICY가 들어 있다. DBA 권한을 받은 업무 계정은 리댁션이 적용되지 않는다는 뜻이므로 DBA 역할 부여 현황을 함께 점검한다.
@B Data Pump Export로 리댁션된 테이블을 내보낼 때는 내보내는 계정이 면제 권한을 가져야 원래 값이 덤프에 들어간다. 면제 권한이 없으면 ORA-28081 계열 오류로 작업이 실패할 수 있다.
@B 정책 관리 권한(DBMS_REDACT 실행 + CREATE ANY TABLE)을 가진 계정은 정책을 끌 수 있다. 실행 권한 보유자는 DBA_TAB_PRIVS에서, 면제 권한 보유자는 DBA_SYS_PRIVS에서 확인한다.
@B NONE 정책이 걸린 뷰가 있으면 그 뷰의 SELECT 권한 보유자도 원래 값을 본다. REDACTION_COLUMNS에서 FUNCTION_TYPE이 NO REDACTION인 컬럼을 찾아 뷰 권한을 함께 점검한다.
@B 정책 식이 사용자 이름이나 역할에 의존하면 그 역할의 부여 현황도 우회 경로가 된다. HR_PAYROLL 같은 판정용 역할은 부여 이력을 감사한다.

@CASE DBA 권한을 받은 개발자에게 급여가 다 보인다
운영 장애 대응을 위해 외주 개발자 계정에 임시로 DBA 역할을 줬다. 며칠 뒤 그 개발자가 급여 테이블을 조회해 원래 값을 본 사실이 감사 기록에서 드러났다.
DBA 역할에는 EXP_FULL_DATABASE 역할이 들어 있고, EXP_FULL_DATABASE는 EXEMPT REDACTION POLICY 시스템 권한을 갖는다. 19.3에서 DBA_SYS_PRIVS를 조회하면 이 권한의 보유자로 EXP_FULL_DATABASE가 나온다.
임시 권한은 장애 대응에 필요한 시스템 권한만 골라 주는 방식으로 바꾸고, DBA 역할 부여를 감사 정책 대상에 넣었다.
@END

@CODE
SELECT grantee, privilege FROM dba_sys_privs WHERE privilege = 'EXEMPT REDACTION POLICY';
SELECT grantee FROM dba_role_privs WHERE granted_role IN ('DBA', 'EXP_FULL_DATABASE');
SELECT grantee FROM dba_tab_privs WHERE table_name = 'DBMS_REDACT';
SELECT object_owner, object_name, policy_name FROM redaction_policies WHERE enable = 'NO';
@END

@BP 리댁션 점검 다섯 가지
REDACTION_POLICIES에서 ENABLE이 NO인 정책이 없는지 본다.
REDACTION_EXPRESSIONS에서 컬럼별로 덮어쓴 식이 있는지 본다.
EXEMPT REDACTION POLICY 보유자와 DBA 역할 보유자를 확인한다.
DBMS_REDACT 실행 권한과 CREATE ANY TABLE을 함께 가진 계정을 확인한다.
리댁션 대상 사용자로 주요 화면과 뷰를 조회해 ORA-28094, ORA-28081이 나는 곳이 없는지 시험한다.
@END

@H2 8.9  Data Redaction 관련 데이터 딕셔너리 뷰

@TBL
뷰 | 내용
REDACTION_POLICIES | 정책 이름, 대상 객체, 정책 식, ENABLE, 설명
REDACTION_COLUMNS | 리댁션된 컬럼과 FUNCTION_TYPE, FUNCTION_PARAMETERS, 정규식 인자
REDACTION_EXPRESSIONS | 이름 붙은 정책 식과 연결된 객체·컬럼
REDACTION_VALUES_FOR_TYPE_FULL | 자료형별 FULL 리댁션 값
@END

@B 이 뷰들은 접두어 없이 이름 그대로 쓴다. DBA_ 계열이 따로 없다.
@B REDACTION_COLUMNS의 FUNCTION_TYPE은 'FULL REDACTION'처럼 설명 문자열로 나온다.

@CODE
SYS@orcl> SELECT object_name, policy_name, expression, enable FROM redaction_policies WHERE object_owner = 'HR';

OBJECT_NAM POLICY_NAME        EXPRESSION                                                     ENA
---------- ------------------ -------------------------------------------------------------- ---
EMPLOYEES  MASK_SALARY_POLICY SYS_CONTEXT('USERENV', 'SESSION_USER') NOT IN ('SCOTT', 'HR')  YES

SYS@orcl> SELECT number_value, char_value, varchar_value, date_value FROM redaction_values_for_type_full;

NUMBER_VALUE C V DATE_VALUE
------------ - - ----------
           0     2001-01-01
@END

@B 컬럼별 방식과 인자는 REDACTION_COLUMNS에서 본다.

@CODE
SYS@orcl> SELECT object_name, column_name, function_type FROM redaction_columns WHERE object_owner = 'HR';

OBJECT_NAM COLUMN_NAME  FUNCTION_TYPE
---------- ------------ --------------------
EMPLOYEES  SALARY       FULL REDACTION
@END

@NOTE 멀티테넌트 환경
CDB에서는 리댁션 정책이 PDB마다 따로 있다. 이름 붙은 정책 식도 같은 PDB의 컬럼에만 연결할 수 있다. 실습 DB는 non-CDB라 해당하지 않는다.
@END

@H2 8.10  설계와 적용 절차

@TBL
단계 | 작업 | 확인할 것
1 | 민감 컬럼 목록과 업무별 노출 수준 정리 | 누가 원래 값을, 누가 부분 값을 봐야 하는가
2 | 컬럼별 방식 선택 | 자료형 지원, 데이터 형식 일관성, 애플리케이션의 NULL·0 처리
3 | 정책 식 설계 | 사용자·역할·컨텍스트 중 판정 기준, 값이 없을 때의 결과
4 | enable => FALSE로 정책 생성 | 정책 식 문법(ORA-28088 등)
5 | 리댁션 대상 사용자로 화면·뷰·배치 시험 | ORA-28081, ORA-28094, 형식 검증 오류
6 | ENABLE_POLICY | 적용 직후 주요 화면 확인
7 | 면제·관리 권한 점검과 감사 설정 | EXEMPT REDACTION POLICY, DBA 역할, 정책 변경 감사
@END

@TBL
시험 항목 | 기대 결과
리댁션 대상 사용자 조회 | 가린 값, 행 수는 원래와 같음
원래 값 대상 사용자 조회 | 원래 값
정책 식이 판정하는 값이 없는 세션 | 의도한 쪽(대개 가림)
리댁션 컬럼을 쓰는 뷰 조회 | ORA-28094 없음
리댁션 대상 계정의 CTAS·INSERT SELECT 배치 | ORA-28081 여부를 미리 확인
화면의 형식 검증·계산 | 0, 공백, NULL, 임의 값에서 오류 없음
@END

@B 2단계가 가장 중요하다. 숫자 FULL의 0, NULLIFY의 NULL, RANDOM의 임의 값은 모두 애플리케이션 계산을 조용히 바꾼다.
@B 5단계는 배치 작업까지 포함한다. 배치 계정이 리댁션 대상이면 CTAS나 INSERT SELECT가 ORA-28081로 실패한다.
@B 리댁션은 화면 노출을 줄이는 기능이다. 데이터 파일 보호는 TDE, 행 단위 차단은 VPD, 접근 기록은 감사와 함께 설계한다.

@H2 8.11  운영 시 주의점

@B 정책 식과 리댁션 방식은 문장 실행 때마다 평가된다. 정책 자체의 비용은 크지 않지만 REGEXP는 행마다 정규식을 돌리므로 대량 조회에서 CPU를 쓴다.
@B 테이블당 정책이 하나이므로 여러 팀이 같은 테이블에 정책을 추가하려 하면 충돌한다. 정책 소유 조직을 정해 두고 컬럼 추가 요청을 받는다.
@B UPDATE_FULL_REDACTION_VALUES로 기본값을 바꾸면 DB의 모든 FULL 정책 결과가 바뀐다. 다른 애플리케이션의 화면을 함께 확인한다.
@B 리댁션된 값이 0, 공백, NULL로 보이는 경우 사용자 문의가 "데이터가 사라졌다"로 들어온다. 헬프데스크 응대 문서에 리댁션 대상 컬럼 목록을 넣어 둔다.
@B 통계 수집, 백업, 데이터 이관 계정이 리댁션 대상인지 확인한다. 대상이면 CTAS 기반 작업이 ORA-28081로 실패하고, 면제 권한을 주면 그 계정이 원래 값을 복사할 수 있게 된다.
@B 정책 변경 이력을 남긴다. Unified Auditing에서 DBMS_REDACT 호출과 EXEMPT REDACTION POLICY 사용을 감사 대상으로 두면 누가 언제 정책을 끄거나 바꿨는지 추적된다(13장).
@B 리댁션된 컬럼에 인덱스가 있어도 인덱스 사용에는 영향이 없다. 조건절이 원래 값으로 평가되므로 실행 계획은 리댁션 전과 같다.
@B 애플리케이션이 결과를 캐시하는 경우 원래 값 사용자의 결과가 캐시되어 리댁션 대상 사용자에게 보이지 않는지 확인한다. DB가 가린 값도 애플리케이션 캐시를 거치면 의미가 없어진다.
@B 실습이 끝나면 정책, 이름 붙은 정책 식, 판정용 역할, 실습 사용자와 권한을 모두 지운다. 남은 리댁션 정책은 다른 장 실습의 결과를 바꾼다.

@H2 8.12  요약

@B Data Redaction은 저장 값은 그대로 두고 조회 결과가 나가기 직전에 값을 가리는 동적 마스킹이다. 정적 마스킹은 복제본에 가린 값을 저장한다. Advanced Security 옵션 기능이다.
@B 정책은 객체, 컬럼, 리댁션 방식, 정책 식으로 구성되며 테이블·뷰당 하나다(ORA-28069). 컬럼은 ALTER_POLICY로 추가·변경한다.
@B 정책 식이 TRUE인 세션에서 리댁션된다. 허용된 함수와 연산자만 쓸 수 있고 사용자 PL/SQL 함수는 ORA-28088로 거부된다. 역할 판정은 SYS_SESSION_ROLES로 한다.
@B 방식은 FULL(0·공백·2001-01-01), PARTIAL(위치), REGEXP(패턴, 불일치 시 FULL), RANDOM, NULLIFY, NONE이다. 자료형마다 지원 방식이 다르다.
@B 이름 붙은 정책 식은 컬럼 단위로 정책 식을 덮어쓰며, 연결을 끊어야 지울 수 있다.
@B WHERE와 ORDER BY는 원래 값으로 평가되어 추론이 가능하다. CTAS·INSERT SELECT로 리댁션 컬럼을 옮기면 ORA-28081, 뷰에서 리댁션 컬럼을 연산하면 ORA-28094(19.3)가 난다.
@B SYS와 EXEMPT REDACTION POLICY 보유자는 모든 정책을 우회한다. REDACTION_POLICIES, REDACTION_COLUMNS, REDACTION_EXPRESSIONS로 점검한다.

@H2 8.13  퀴즈

@QUIZ 문제 1
Data Redaction 정책이 걸린 사용자가 SALARY가 0으로 보이는 상태에서 `SELECT COUNT(*) FROM hr.employees WHERE salary > 15000`을 실행했다. 결과는?
① 0건이다  ② 전체 행 수가 나온다  ③ 실제로 15000을 넘는 사원 수가 나온다  ④ ORA-28081이 난다
정답 ③. 리댁션은 결과 값을 내보내기 직전에만 적용되고 WHERE 절은 원래 값으로 평가된다. 그래서 값은 가려져도 조건 조회로 실제 분포를 알아낼 수 있다.
@END

@QUIZ 문제 2
이미 리댁션 정책이 있는 HR.CUSTOMERS에 다른 이름으로 ADD_POLICY를 실행해 PHONE_NUMBER를 가리려 했다. 결과와 올바른 방법은?
① 정상 등록된다  ② ORA-28069가 나며, 기존 정책에 ALTER_POLICY ADD_COLUMN으로 추가한다  ③ ORA-28060이 나며, DROP 후 다시 만든다  ④ 두 정책이 OR로 결합된다
정답 ②. 테이블·뷰 하나에는 정책을 하나만 둘 수 있다. 컬럼 추가는 ALTER_POLICY의 ADD_COLUMN으로 한다. ORA-28060은 이미 리댁션된 컬럼을 다시 추가할 때 나는 오류다.
@END

@QUIZ 문제 3
REGEXP 정책의 패턴이 '([0-9]{6}-)([0-9]{7})'일 때 하이픈 없이 저장된 '9304032455490'은 어떻게 보이는가?
① 그대로 보인다  ② 뒤 7자리만 가려진다  ③ FULL 리댁션되어 공백으로 보인다  ④ NULL로 보인다
정답 ③. 정규식이 맞지 않는 값은 원래 값이 나가지 않고 FULL 리댁션된다. 문자 컬럼의 FULL 값은 공백 한 칸이다.
@END

@QUIZ 문제 4
정책 식으로 쓸 수 없는 것은?
① SYS_CONTEXT('USERENV','SESSION_USER') != 'HR'  ② SYS_CONTEXT('SYS_SESSION_ROLES','HR_PAYROLL') = 'FALSE'  ③ 1=1  ④ hr.is_manager = 'N'
정답 ④. 사용자가 만든 PL/SQL 함수는 정책 식에 쓸 수 없고 ORA-28088로 거부된다. 복잡한 판단은 애플리케이션 컨텍스트에 결과를 넣고 SYS_CONTEXT로 비교한다.
@END

@QUIZ 문제 5
리댁션 대상 사용자가 리댁션된 SALARY를 포함해 CREATE TABLE AS SELECT를 실행했다. 결과는?
① 리댁션된 값(0)으로 복사된다  ② 원래 값으로 복사된다  ③ ORA-28081로 거부된다  ④ SALARY만 NULL로 복사된다
정답 ③. 리댁션된 컬럼을 다른 객체로 옮기는 CTAS와 INSERT ... SELECT는 ORA-28081로 막힌다. 리댁션 대상이 아닌 컬럼만 고르면 복사된다.
@END

@QUIZ 문제 6
숫자 컬럼에 FULL 리댁션을 적용할 때 가장 주의할 점은?
① 값이 NULL이 되어 NOT NULL 제약에 걸린다  ② 0으로 보여 실제 0과 구분되지 않고 합계가 틀어진다  ③ 조회마다 값이 바뀐다  ④ 숫자 컬럼은 FULL을 지원하지 않는다
정답 ②. 숫자의 FULL 기본값은 0이다. 화면 사용자가 실제 값으로 오해하거나 합계 계산이 조용히 틀릴 수 있다. 조회마다 바뀌는 것은 RANDOM, NULL이 되는 것은 NULLIFY다.
@END

@H2 8.14  실습 개요

@P 실습은 oel7v9 서버의 orcl 데이터베이스(19.3, non-CDB, AL32UTF8)에서 HR.EMPLOYEES와 실습용 HR.CUSTOMERS를 대상으로 진행한다. 01에서 만든 정책을 04까지 이어 쓰고 05 마지막에 모두 철거한다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
8장_실습_01_FULL리댁션과정책식 | DBMS_REDACT 실행 권한(PLS-00201), FULL 리댁션, 사용자별 결과, 딕셔너리 뷰와 FULL 기본값 | 8.3, 8.4.1, 8.5.2
8장_실습_02_REGEXP와PARTIAL | 주민번호·전화번호 REGEXP, 패턴 불일치 시 FULL, 테이블당 정책 하나(ORA-28069), 문자 PARTIAL | 8.3.2, 8.5.3, 8.5.4
8장_실습_03_RANDOM_NULLIFY와PARTIAL | NULLIFY·RANDOM·숫자/날짜 PARTIAL, ORA-28060, 사용자 함수 식(ORA-28088), 역할 기반 식 | 8.4.2, 8.4.3, 8.5, 8.6.4
8장_실습_04_리댁션의한계와면제 | 조건절 추론, CTAS·INSERT SELECT(ORA-28081), 뷰 연산(ORA-28094), EXEMPT REDACTION POLICY | 8.7, 8.8
8장_실습_05_정책관리와원복 | DISABLE/ENABLE(ORA-28080), 이름 붙은 정책 식(ORA-28092), ORA-28068, 원복 | 8.4.4, 8.6.3, 8.9
@END
