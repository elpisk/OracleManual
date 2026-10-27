@H1 제12장  Fine-Grained Auditing

@H2 12.1  학습 목표

@P 표준 감사는 "누가 어떤 테이블에 SELECT를 했다"까지 기록한다. 그 조회가 고액 연봉자의 급여를 읽었는지, 이름만 읽었는지는 구분하지 못한다. Fine-Grained Auditing(FGA)은 조회한 내용을 기준으로 감사 기록을 남긴다.

@B FGA가 표준 감사와 어떻게 다른지, 어떤 조건에서 감사 기록이 생기는지 설명할 수 있다.
@B `DBMS_FGA.ADD_POLICY`의 audit_condition, audit_column, audit_column_opts, statement_types를 목적에 맞게 지정할 수 있다.
@B audit_condition 작성 규칙과 위반 시의 오류를 알고, 문장당 기록 건수의 원리를 설명할 수 있다.
@B audit_trail 옵션(DB, DB+EXTENDED, XML, XML+EXTENDED)에 따라 기록 위치와 내용이 어떻게 달라지는지 설명할 수 있다.
@B 혼합 감사 모드(mixed mode)에서 FGA 기록이 남는 위치를 확인하고, 순수 통합 감사(pure unified auditing)에서 달라지는 점을 말할 수 있다.
@B 이벤트 핸들러를 작성해 감사 조건이 충족될 때 알림을 보내고, 핸들러 오류가 사용자 문장에 주는 영향을 설명할 수 있다.
@B 정책을 비활성화·삭제하고 DBA_AUDIT_POLICIES, DBA_FGA_AUDIT_TRAIL 등으로 정책과 기록을 점검할 수 있다.

@H2 12.2  FGA의 개념

@H3 12.2.1  표준 감사로는 부족한 경우

@B 표준 감사(`AUDIT SELECT ON hr.employees`)와 통합 감사 정책은 문장 종류와 대상 객체를 기준으로 기록한다. 같은 테이블을 읽은 문장이면 내용과 관계없이 똑같이 기록된다.
@B 급여 컬럼을 읽은 조회만, 또는 연봉 1만 이상인 사원의 행을 건드린 조회만 골라 기록하려면 표준 감사로는 표현할 수 없다.
@B 모든 SELECT를 기록하면 감사 기록이 업무량만큼 쌓인다. 정작 확인해야 할 민감 데이터 접근은 대량의 일상 기록에 묻힌다.
@B FGA는 감사할 컬럼과 행 조건을 정책으로 지정한다. 조건을 만족하는 접근만 기록하므로 기록 양이 줄고 의미가 분명해진다.

@H3 12.2.2  동작 원리

@TBL
단계 | 하는 일
1. 문장 실행 | 정책이 걸린 테이블·뷰를 참조하는 문장이 실행됨
2. 컬럼 검사 | 문장이 audit_column에 지정된 컬럼을 참조하는지 확인(ANY 또는 ALL 기준)
3. 행 조건 검사 | 처리되는 행 중 audit_condition을 만족하는 행이 있는지 확인
4. 기록 | 두 검사를 통과하면 문장 하나당 정책 하나에 대해 감사 기록 1건 생성
5. 핸들러 | 지정된 경우 조건을 만족한 첫 행이 처리된 뒤 핸들러 프로시저 호출
@END

@B 기록 단위는 행이 아니라 문장이다. 조건을 만족하는 행이 100개 반환되어도 그 문장에 대한 기록은 정책마다 1건이다.
@B 조건을 만족하는 행이 실제로 처리되어야 기록된다. 급여 컬럼을 조회해도 조건에 맞는 행이 결과에 없으면 기록이 없다.
@B 감사 기록은 사용자 트랜잭션과 독립적으로 저장된다. 사용자가 UPDATE를 ROLLBACK해도 감사 기록은 남는다.
@B FGA는 접근을 막지 않는다. 사용자는 아무 차이 없이 결과를 받고, 기록만 따로 남는다. 접근 자체를 제한하는 것은 VPD(7장)의 일이다.
@B 사용자는 자신의 조회가 기록됐는지 알 수 없다. 감사 사실을 알리지 않는 것이 FGA의 기본 전제이며, 기록을 볼 수 있는 권한도 감사 담당자에게만 준다.

@H3 12.2.3  관련 기능과의 구분

@TBL
기능 | 기준 | 결과
표준 감사·통합 감사 정책 | 문장 종류, 객체, 권한 사용 | 조건 없이 해당 문장을 기록
Fine-Grained Auditing | 컬럼 참조, 행 조건 | 조건을 만족하는 문장만 기록
Virtual Private Database | 정책 함수의 술어 | 행을 걸러 냄(기록 없음)
Data Redaction | 정책 식 | 값을 가림(기록 없음)
@END

@B FGA는 Enterprise Edition에 포함된 기능이다. 별도 옵션 라이선스가 필요하지 않다.
@B VPD와 FGA는 같은 "정책" 개념을 쓰지만 패키지와 뷰가 다르다. VPD는 DBMS_RLS·DBA_POLICIES, FGA는 DBMS_FGA·DBA_AUDIT_POLICIES다.
@B 두 기능을 함께 쓰면 VPD로 걸러진 뒤 남은 행에 대해 FGA 조건이 평가된다. 볼 수 없는 행은 처리되지 않으므로 감사 조건도 만족하지 않는다.
@B Security Guide 기준으로 VPD 정책이 걸린 객체의 FGA 기록에는 그때 붙은 VPD 술어가 RLS_INFO 컬럼(DBA_FGA_AUDIT_TRAIL, UNIFIED_AUDIT_TRAIL)에 자동으로 남는다. 따로 정책을 만들 필요가 없고, 술어가 여러 개면 이어 붙여 저장되며 DBMS_AUDIT_UTIL 함수로 행을 나눠 볼 수 있다.
@B "그 사용자는 그때 어떤 행까지 볼 수 있었는가"라는 질문에 RLS_INFO가 답한다. 7장의 VPD 정책 함수가 사용자마다 다른 술어를 만든다면 감사 기록만으로 당시의 접근 범위를 재구성할 수 있다.

@H3 12.2.4  내부 동작 — 감사용 질의

@B FGA는 정책 조건을 그대로 평가하지 않고 감사용 내부 질의를 만든다. 실습 02의 세션 트레이스에서 그 모양을 볼 수 있다.
@B 내부 질의는 대상 테이블을 읽으면서 `SYS_AUDIT((CASE WHEN (조건) THEN 1 ELSE NULL END), '스키마', '객체', '정책', ...)`를 평가한다. 조건이 참인 행을 만나면 SYS_AUDIT가 감사 기록을 남긴다.
@B 조건 안에 같은 테이블을 읽는 서브쿼리가 있으면 이 내부 질의가 다시 그 테이블의 FGA 정책을 부른다. 재귀가 생겨 파싱이 실패하는 이유다.
@B 조건 평가는 사용자 문장이 처리하는 행에 대해 이루어진다. 조건이 단순할수록 추가 비용이 작다.

@CODE
FGA: Actual Query is SELECT "EMPLOYEE_ID", ... FROM "HR"."EMPLOYEES" "EMPLOYEES"
     WHERE SYS_AUDIT((CASE WHEN(SALARY > 9999) THEN 1 ELSE NULL END),
                     'HR','EMPLOYEES', 'EMP_HIGH_SAL',3 ) IS NULL
@END

@H3 12.2.5  VPD 정책과의 대응

@TBL
작업 | VPD(DBMS_RLS) | FGA(DBMS_FGA)
정책 생성 | ADD_POLICY | ADD_POLICY
정책 삭제 | DROP_POLICY | DROP_POLICY
켜기·끄기 | ENABLE_POLICY(…, TRUE·FALSE) | ENABLE_POLICY, DISABLE_POLICY
정책 정의 조회 | DBA_POLICIES | DBA_AUDIT_POLICIES
결과에 미치는 영향 | 행이 걸러짐 | 없음(기록만)
면제 | SYS, EXEMPT ACCESS POLICY | SYS 작업은 FGA가 아닌 SYS 감사 대상
@END

@B 두 패키지의 이름과 인자가 비슷해 섞어 쓰기 쉽다. 같은 이름 재생성(ORA-28101), 없는 정책(ORA-28102)처럼 오류 번호도 같은 계열을 공유한다.
@B FGA에는 ENABLE_POLICY와 별도로 DISABLE_POLICY가 있다. VPD는 ENABLE_POLICY의 마지막 인자로 켜고 끈다.
@B FGA의 ENABLE_POLICY에도 BOOLEAN 인자 enable(기본값 TRUE)이 있다. 문서 기준으로 FALSE를 주면 끄는 효과가 나므로, 스크립트에서는 의도가 드러나도록 끌 때 DISABLE_POLICY를 쓴다.

@H2 12.3  감사 모드와 FGA 기록 위치

@H3 12.3.1  혼합 모드와 순수 통합 감사

@B 19c를 새로 설치하면 혼합 감사 모드(mixed mode)로 동작한다. 전통적 감사(AUDIT_TRAIL 파라미터)와 통합 감사(unified audit policy)가 함께 켜진 상태다.
@B 현재 모드는 V$OPTION으로 확인한다. `Unified Auditing`이 FALSE면 혼합 모드, TRUE면 순수 통합 감사다.
@B 혼합 모드에서는 기본 통합 감사 정책 ORA_SECURECONFIG, ORA_LOGON_FAILURES가 켜져 있고, AUDIT_TRAIL·AUDIT_FILE_DEST·AUDIT_SYS_OPERATIONS·AUDIT_SYSLOG_LEVEL 같은 기존 파라미터도 그대로 동작한다.
@B 혼합 모드에서 통합 감사 정책과 FGA 정책은 서로 독립적이다. 통합 감사 정책이 SELECT ON hr.employees를 기록하더라도 FGA 정책의 기록 위치는 바뀌지 않는다.
@B 순수 통합 감사는 oracle 실행 파일을 uniaud_on으로 다시 링크하고 재기동해야 켜진다. 이후 전통적 감사는 꺼지고 모든 기록은 통합 감사 기록(UNIFIED_AUDIT_TRAIL)으로 모인다. 감사 모드 전반은 13장에서 다룬다.

@H3 12.3.2  모드별 FGA 기록 위치

@TBL
상태 | FGA 기록 위치 | 조회
혼합 모드, audit_trail => DB | SYS.FGA_LOG$ | DBA_FGA_AUDIT_TRAIL
혼합 모드, audit_trail => XML | AUDIT_FILE_DEST의 XML 파일 | V$XML_AUDIT_TRAIL
순수 통합 감사 | AUDSYS의 통합 감사 테이블 | UNIFIED_AUDIT_TRAIL(AUDIT_TYPE = 'FineGrainedAudit')
@END

@B 실습 DB orcl(19.3, 혼합 모드, AUDIT_TRAIL = DB)에서 FGA 정책을 만들고 조회하자 기록은 DBA_FGA_AUDIT_TRAIL에만 남았다. 같은 시각 UNIFIED_AUDIT_TRAIL의 FineGrainedAudit 기록은 0건이었다.
@B audit_trail 인자를 생략한 정책은 DBA_AUDIT_POLICIES의 AUDIT_TRAIL이 DB+EXTENDED로 등록된다. 혼합 모드에서 아무것도 지정하지 않으면 SQL 문까지 FGA_LOG$에 남는다.
@B 순수 통합 감사로 전환하면 audit_trail 인자는 의미를 잃고 모든 FGA 기록이 UNIFIED_AUDIT_TRAIL로 간다. V$XML_AUDIT_TRAIL도 채워지지 않는다.
@B 감사 기록 조회 스크립트를 만들 때는 현재 모드와 정책의 AUDIT_TRAIL 값을 먼저 확인해야 엉뚱한 뷰에서 "기록 없음"을 보고 잘못 판단하는 일을 피한다.

@NOTE 정책 정의를 볼 때 놓치기 쉬운 점
DBA_AUDIT_POLICIES의 POLICY_COLUMN에는 audit_column에 지정한 컬럼 중 첫 번째만 보인다. 'SALARY,COMMISSION_PCT'로 만든 정책도 SALARY만 표시된다.
지정한 컬럼 전체는 DBA_AUDIT_POLICY_COLUMNS에서 확인한다. 정책 점검표를 만들 때 두 뷰를 함께 조회한다.
@END

@H3 12.3.3  FGA 기록에 남는 정보

@TBL
DBA_FGA_AUDIT_TRAIL 컬럼 | 내용
TIMESTAMP, EXTENDED_TIMESTAMP | 기록 시각. EXTENDED_TIMESTAMP는 시간대 포함
DB_USER, OS_USER, USERHOST | 데이터베이스 사용자, OS 사용자, 클라이언트 호스트
CLIENT_ID | 애플리케이션이 설정한 CLIENT_IDENTIFIER(6장)
PROXY_SESSIONID | 프록시 접속(2장)이면 프록시 세션 정보
OBJECT_SCHEMA, OBJECT_NAME, POLICY_NAME | 대상 객체와 정책
STATEMENT_TYPE | SELECT, INSERT, UPDATE, DELETE
SQL_TEXT, SQL_BIND | EXTENDED일 때 SQL 문과 바인드 값
SCN, TRANSACTIONID | 문장 시점의 SCN과 트랜잭션 ID
@END

@B 연결 풀을 쓰는 웹 애플리케이션은 DB_USER가 모두 같은 계정으로 남는다. 실제 사용자를 구분하려면 애플리케이션이 CLIENT_IDENTIFIER를 설정해야 하고, 그러면 CLIENT_ID 컬럼에 남는다.
@B SCN은 플래시백 질의와 함께 쓸 수 있다. 감사 기록의 SCN으로 `AS OF SCN`을 걸면 그 문장이 본 데이터 상태를 다시 확인할 수 있다(언두가 남아 있는 동안).
@B 플래시백 질의 자체도 감사 대상이다. 문서 기준으로 현재 걸려 있는 정책이 지정한 시각·SCN의 스냅숏 데이터에 적용되므로, 감사 담당자의 확인용 플래시백 조회도 조건을 만족하면 기록된다.

@H3 12.3.4  실습에서 확인한 기록 여부

@P 실습 01~05에서 실행한 조회와 DML이 기록됐는지를 한 표로 모으면 FGA의 판단 기준이 한눈에 보인다.

@TBL
정책 | 문장 | 기록 | 이유
SALARY,COMMISSION_PCT, 조건 없음 | 이름·직무만 조회 | 없음 | 감사 컬럼을 참조하지 않음
SALARY,COMMISSION_PCT, 조건 없음 | SALARY 포함 조회 | 1건 | 감사 컬럼 참조
SALARY,COMMISSION_PCT, 조건 없음 | WHERE commission_pct > 1 (0건) | 1건 | WHERE 참조, 조건 NULL은 항상 참
SALARY, 'SALARY > 9999' | 105번(4800) 조회 | 없음 | 조건 만족 행 없음
SALARY, 'SALARY > 9999' | 90번 부서 3명 조회 | 1건 | 문장당 1건
LAST_NAME,SALARY, ALL_COLUMNS | 이름만 / 급여만 | 없음 | 두 컬럼을 모두 참조해야 함
SALARY, INSERT·UPDATE | UPDATE 후 ROLLBACK | 1건 | 기록은 트랜잭션과 독립
SALARY, 'SALARY > 9999', 핸들러 | 핸들러 실패로 오류 난 조회 | 1건 | 기록은 핸들러 성공과 별개
@END

@H2 12.4  정책 만들기 — DBMS_FGA.ADD_POLICY

@H3 12.4.1  인자

@TBL
인자 | 의미 | 기본값
object_schema, object_name | 감사할 테이블·뷰 | 스키마 생략 시 현재 스키마
policy_name | 객체 안에서 고유한 정책 이름 | (필수)
audit_condition | 행 조건. 이 조건을 만족하는 행이 처리되면 기록 | NULL(항상 참)
audit_column | 감사할 컬럼 목록 | NULL(어떤 컬럼이든)
audit_column_opts | ANY_COLUMNS(하나라도) 또는 ALL_COLUMNS(모두) | ANY_COLUMNS
statement_types | SELECT, INSERT, UPDATE, DELETE 중 선택 | SELECT
handler_schema, handler_module | 조건 충족 시 호출할 프로시저 | NULL
enable | 생성과 동시에 활성화 | TRUE
audit_trail | DB, DB+EXTENDED, XML, XML+EXTENDED | DB+EXTENDED
@END

@B audit_trail은 통합 감사로 옮겨 가지 않은 환경에서 기록 위치와 SQL 문·바인드 값 저장 여부를 정한다. 순수 통합 감사에서는 생략하며, 지정해도 기록은 통합 감사 기록으로 간다.
@B policy_owner 인자도 있지만 사용자가 지정하는 값이 아니다. Data Pump가 정책을 다시 만들 때 내부적으로 쓴다.
@B 한 테이블·뷰에는 FGA 정책을 최대 256개까지 걸 수 있다. LOB처럼 행 밖에 저장되는 컬럼에는 걸지 않는다.

@CODE
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema   => 'HR',
    object_name     => 'EMPLOYEES',
    policy_name     => 'EMP_SAL_ACCESS',
    audit_column    => 'SALARY,COMMISSION_PCT',
    statement_types => 'SELECT');
END;
/
@END

@H3 12.4.2  누가 정책을 만드는가

@B 정책을 만들려면 DBMS_FGA 실행 권한이 필요하다. 이 권한을 가진 사용자는 감사 정책을 끄고 지울 수도 있으므로 감사 관리자에게만 준다.
@B 매뉴얼은 AUDIT_ADMIN 역할 또는 DBMS_FGA의 EXECUTE 권한 중 하나를 요구한다. 기록을 분석하는 사람에게는 AUDIT_VIEWER 역할을 준다.
@B DBMS_FGA는 호출자 권한(invoker rights) 패키지다. 감사 관리 계정이 다른 스키마의 테이블에 정책을 걸 때 그 계정의 권한으로 동작한다.
@B 원본 실습은 SYS로 정책을 만들었다. 이 교안의 실습은 원본의 핸들러 스키마 이름인 SECADM을 감사 관리 계정으로 만들어 정책·핸들러·알림 대상을 모두 이 계정에 둔다.
@B audit_condition은 정책을 만든 사용자의 권한으로 평가된다. 조건 안에서 함수를 부르면 정책 소유자가 그 함수의 실행 권한을 역할이 아닌 직접 권한으로 받아야 한다. 그렇지 않으면 ORA-28138이 난다.
@B 정책을 만든 사용자를 DROP하면 그 사용자가 만든 FGA 정책도 자동으로 삭제된다. 대상 객체를 DROP해도 정책이 사라진다. 감사 관리 계정을 정리할 때 감사가 함께 사라진다는 뜻이므로 계정 삭제 전에 정책 목록을 확인한다.

@H3 12.4.3  정책 이름

@B policy_name에는 공백이나 쉼표 같은 특수 문자를 쓰지 않는다. 꼭 써야 하면 큰따옴표로 감싸야 하는데, 이후 관리 프로시저를 부를 때마다 같은 표기를 맞춰야 해서 실수가 잦다.
@B 정책 이름은 객체 단위로 고유하다. 다른 테이블에 같은 이름의 정책을 둘 수 있으므로, 이름만으로 정책을 찾지 말고 스키마·객체와 함께 지정한다.
@B 감사 기록에는 정책 이름이 남는다. `EMP_HIGH_SAL`처럼 대상과 목적이 드러나는 이름이면 기록만 보고도 무엇을 감시하는 정책인지 알 수 있다.

@H3 12.4.4  자주 쓰는 정책 형태

@TBL
목적 | audit_column | audit_condition | statement_types
급여 컬럼을 읽은 모든 조회 | SALARY | NULL | SELECT
임원급 연봉 조회만 | SALARY | SALARY > 9999 | SELECT
본인 계정이 아닌 사용자의 조회 | SALARY | SYS_CONTEXT('USERENV','SESSION_USER') <> 'HR' | SELECT
급여 변경 시도 | SALARY | NULL | INSERT, UPDATE
이름과 주민번호를 함께 조회 | NAME,SSN(ALL_COLUMNS) | NULL | SELECT
행 삭제 전부 | NULL | NULL | DELETE
@END

@B 세 번째 형태처럼 USERENV 속성을 조건에 쓰면 "누가"를 기준으로 거를 수 있다. 업무 애플리케이션 계정의 일상 조회는 빼고 사람 계정의 직접 조회만 남기는 식이다.
@B 마지막 형태는 audit_column이 NULL이라 어떤 컬럼이든 해당한다. DELETE는 어떤 컬럼도 참조하지 않은 것으로 볼 수 없으므로 모든 DELETE가 기록된다.
@B 정책이 많아지면 한 테이블에 여러 정책이 같은 문장을 동시에 기록할 수 있다. 정책마다 1건씩 남으므로 기록 건수를 셀 때 정책 이름으로 구분한다.

@H2 12.5  감사 조건과 감사 컬럼

@H3 12.5.1  audit_column과 audit_column_opts

@B audit_column에 SALARY, COMMISSION_PCT를 지정하면 이 컬럼을 참조하는 문장만 감사 대상이 된다. SELECT 목록뿐 아니라 WHERE 절이나 ORDER BY에서 참조해도 해당한다.
@B audit_column을 비워 두면 테이블의 어떤 컬럼을 참조하든 감사 대상이다.
@B ANY_COLUMNS(기본)는 지정 컬럼 중 하나라도 참조하면 기록한다. ALL_COLUMNS는 지정 컬럼을 모두 참조해야 기록한다.
@B ALL_COLUMNS는 "이름과 주민번호를 함께 조회한 경우"처럼 조합이 위험한 경우에 쓴다. 이름만, 주민번호만 조회한 문장은 기록되지 않는다.

@CODE
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema     => 'HR',
    object_name       => 'EMPLOYEES',
    policy_name       => 'EMP_NAME_SAL',
    audit_column      => 'LAST_NAME,SALARY',
    audit_column_opts => DBMS_FGA.ALL_COLUMNS);
END;
/
@END

@B 실습 02에서 이 정책 아래 이름만, 급여만, 둘 다 조회한 세 문장 중 마지막 하나만 기록됐다.
@B ALL_COLUMNS의 컬럼 목록이 길어질수록 기록 조건이 까다로워진다. 실제로 함께 읽혀야 위험한 최소 조합만 지정한다.

@H3 12.5.2  audit_condition 작성 규칙

@B audit_condition은 처리되는 행의 값으로 평가할 수 있는 불리언 식이다. `'SALARY > 9999'`처럼 쓴다.
@B NULL이면 항상 참으로 취급된다. 이때는 처리된 행이 없어도, 즉 결과가 0건이어도 감사 기록이 남는다.
@B 서브쿼리와 시퀀스는 쓸 수 없다. ROWNUM, LEVEL, PRIOR 같은 의사 컬럼과 USERENV의 CURRENT_SQL, CURRENT_SQL_LENGTH, CURRENT_BIND 속성도 쓸 수 없다.
@B SYS_CONTEXT의 다른 속성은 쓸 수 있다. `SYS_CONTEXT('USERENV','SESSION_USER') <> 'HR'`처럼 "본인이 아닌 사용자의 조회"를 조건으로 만들 수 있다.
@B 감사 대상 테이블을 다시 읽는 조건은 쓰지 않는다. 'SALARY > (SELECT AVG(salary) FROM hr.employees)' 같은 조건은 19.3에서 ADD_POLICY 시점에는 통과하지만, 조회 때 FGA 내부 질의가 다시 같은 테이블의 FGA 정책을 부르는 재귀에 빠져 사용자 문장이 ORA-28112로 실패한다.
@B 매뉴얼은 audit_condition에서 AND·OR로 조건을 결합하지 말라고 적고 있다. 실습에서는 'SALARY > 9999 AND DEPARTMENT_ID = 80'이 오류 없이 동작했지만 지원 범위 밖으로 보고, 결합 조건을 쓸 때는 충분히 시험한다.
@B 매뉴얼은 조건 안의 함수가 감사 대상 테이블에 같은 문장을 다시 실행하게 만들지 말라고 경고한다. 이 경우 재귀로 ORA-1000이나 ORA-00036이 날 수 있다고 적는다. 서브쿼리 조건에서 본 ORA-28112와 같은 계열의 함정이다.
@B 정책 때문에 업무 조회가 실패하면 세션 트레이스를 본다. FGA는 조건을 `SYS_AUDIT(CASE WHEN 조건 THEN 1 ELSE NULL END, ...)` 형태로 바꾼 내부 질의를 만들며, 그 질의의 파싱 결과가 트레이스에 남는다.

@CODE
HR@orcl> SELECT last_name, salary FROM employees WHERE employee_id = 105;
ERROR at line 1:
ORA-28112: failed to execute policy function

[oracle@oel7v9 ~]$ grep -h 'FGA: Query parsing returned' orcl_ora_*.trc | tail -1
FGA: Query parsing returned with error# 28112
@END

@H3 12.5.3  문장 유형과 DML 감사

@B statement_types 기본값은 SELECT다. INSERT, UPDATE, DELETE를 감사하려면 명시한다.
@B 지정할 수 있는 값은 SELECT, INSERT, UPDATE, DELETE뿐이다. MERGE를 넣으면 ORA-28106(input value for argument #9 is not valid)이 난다. 9번째 인자가 statement_types다.
@B MERGE 감사는 MERGE가 내부에서 하는 INSERT와 UPDATE로 잡는다. Security Guide는 statement_types => 'INSERT,UPDATE'로 정책을 만들라고 안내하며, 성공한 MERGE 한 문장에 정책마다 기록 1건이 생긴다고 적는다. 실습에서는 MERGE 지정 오류까지만 확인했다.
@B DML 감사 기록도 사용자 트랜잭션과 독립적이다. 급여를 고쳤다가 ROLLBACK한 시도도 기록에 남는다. 데이터 변경 이력이 아니라 접근 시도 이력이기 때문이다.
@B DML이 감사 대상이면 직접 경로 INSERT(APPEND 힌트) 같은 고속 경로가 자동으로 일반 경로로 바뀐다. 대량 적재 작업이 있는 테이블은 성능 영향을 미리 시험한다.
@B UPDATE는 SET 절에서 감사 컬럼을 바꾸거나 WHERE 절에서 참조하면 감사 컬럼 참조로 본다. 실습 03의 UPDATE는 SET 절의 SALARY 때문에 기록됐다.
@B DELETE를 감사하려면 audit_column을 비워 두거나, 조건으로 대상 행을 좁힌다. 예를 들어 'DEPARTMENT_ID = 90'을 조건으로 주면 임원 부서 행을 지우는 시도만 기록된다.
@B INSERT는 새로 넣는 행의 값으로 조건을 평가한다. 'SALARY > 9999'를 조건으로 주면 고액 연봉으로 등록하는 INSERT만 기록된다.

@H3 12.5.4  바인드 값의 기록 형식

@B EXTENDED 옵션에서 바인드 변수를 쓴 문장은 SQL_TEXT에 `:b` 같은 자리표시자가, SQL_BIND에 실제 값이 남는다.
@B SQL_BIND 형식은 `#번호(길이):값`이다. 실습 03의 `#1(3):105`는 첫 번째 바인드 변수에 세 글자 '105'가 들어갔음을 나타낸다. 바인드가 여럿이면 `#1(...)...#2(...)...`처럼 이어진다.
@B 리터럴로 값을 쓴 문장은 SQL_TEXT에 값이 그대로 들어가고 SQL_BIND는 비어 있다.
@B 감사 기록을 해석하는 도구를 만들 때 이 형식을 파싱해 원래 문장을 재구성할 수 있다. 같은 이유로 감사 기록이 유출되면 조회 조건이 그대로 드러난다.

@CODE
DB_USER  STMT   SQL_TEXT                                               SQL_BIND
-------- ------ ------------------------------------------------------ ----------
HR       UPDATE UPDATE employees SET salary = salary * 1.1             #1(3):105
                WHERE employee_id = :b
@END

@H3 12.5.5  뷰에 거는 FGA

@B FGA 정책은 테이블뿐 아니라 뷰에도 걸 수 있다. 뷰에 걸면 그 뷰를 통한 접근만 기록하고, 원본 테이블에 걸면 뷰를 포함한 모든 경로의 접근을 기록한다.
@B 애플리케이션이 특정 뷰로만 데이터를 읽는다면 뷰 정책으로 범위를 좁힐 수 있다. 직접 테이블에 접근하는 경로까지 감시하려면 테이블에 건다.
@B 뷰에 건 정책의 audit_column은 뷰의 컬럼 이름을 쓴다. 뷰가 컬럼 별칭을 쓰면 별칭 기준이다.

@CASE 고액 연봉자 조회만 골라 기록하기
인사 시스템에서 급여 정보 조회를 모두 기록하자 하루 수십만 건의 감사 기록이 쌓였다. 감사 담당자는 그중 임원급 연봉 조회만 확인하면 된다고 했다.
audit_column을 SALARY로, audit_condition을 'SALARY > 9999'로 정책을 바꿨다. 급여 컬럼을 읽더라도 결과에 1만 이상인 행이 없으면 기록되지 않는다.
기록이 하루 수백 건으로 줄었고, 기록마다 의미가 분명해졌다. 조건을 바꿀 때는 DROP_POLICY 후 ADD_POLICY로 다시 만들고, 바꾼 이력은 변경 관리 문서에 남겼다.
@END

@H2 12.6  audit_trail 옵션

@H3 12.6.1  DB와 DB+EXTENDED

@B DBMS_FGA.DB는 기록을 SYS.FGA_LOG$ 테이블에 남긴다. 누가, 언제, 어느 정책으로, 어떤 객체에 접근했는지가 기록된다.
@B DBMS_FGA.DB + DBMS_FGA.EXTENDED는 여기에 SQL 문 전체(LSQLTEXT)와 바인드 값(LSQLBIND)을 더한다. DBA_FGA_AUDIT_TRAIL의 SQL_TEXT, SQL_BIND 컬럼에서 본다.
@B 어떤 조건으로 조회했는지 알아야 감사 의미가 생기므로 대개 EXTENDED를 쓴다. 반대로 SQL 문과 바인드 값에 민감 정보가 그대로 남는다는 점을 함께 고려한다.

@NOTE 감사 기록에도 민감 정보가 남는다
EXTENDED로 기록하면 `WHERE ssn = :1` 문장의 바인드 값, `WHERE card_no = '4111...'` 문장의 리터럴이 감사 기록에 평문으로 저장된다.
감사 기록 테이블과 XML 파일의 접근 권한을 데이터 자체만큼 엄격하게 관리한다. 감사 기록을 다른 저장소로 옮길 때도 같은 보호 수준을 유지한다.
@END

@CASE 감사 기록에서 고객 주민번호가 발견됐다
개인정보 점검에서 감사 기록 테이블이 검사 대상에 포함됐다. 점검 도구가 FGA_LOG$의 바인드 값 컬럼에서 주민번호 형식의 문자열을 수천 건 찾아냈다.
고객 조회 화면이 주민번호를 바인드 변수로 넘겨 조회하고 있었고, 정책이 DB+EXTENDED로 걸려 있어 그 값이 모두 감사 기록에 남은 것이었다.
감사 목적상 조회 조건이 필요했기 때문에 EXTENDED를 끄지는 않았다. 대신 감사 기록 조회 권한을 감사 담당자 두 명으로 줄이고, 감사 기록을 옮기는 외부 저장소에도 데이터베이스와 같은 수준의 암호화와 접근 통제를 적용했다.
@END

@H3 12.6.2  XML과 XML+EXTENDED

@B DBMS_FGA.XML은 기록을 AUDIT_FILE_DEST 디렉터리의 XML 파일에 쓴다. 데이터베이스 안에서는 V$XML_AUDIT_TRAIL 뷰로 읽는다.
@B 운영체제 파일이므로 DBA가 데이터베이스 안에서 기록을 지우기 어렵다. 감사 대상과 감사 관리자를 분리하려는 환경에서 쓴다.
@B 파일 쓰기에 실패하면, 예를 들어 AUDIT_FILE_DEST가 가득 차면 감사 대상 문장 자체가 실패한다. 감사 디렉터리의 여유 공간은 감시 대상이다.
@B V$XML_AUDIT_TRAIL은 통합 감사가 켜지지 않은 환경에서만 채워진다.

@TBL
옵션 | 기록 위치 | SQL 문·바인드
DB | SYS.FGA_LOG$ | 없음
DB + EXTENDED | SYS.FGA_LOG$ | 있음
XML | AUDIT_FILE_DEST/*.xml | 없음
XML + EXTENDED | AUDIT_FILE_DEST/*.xml | 있음
@END

@H3 12.6.3  XML 기록의 구조

@B XML 파일 하나에는 한 세션의 감사 기록이 AuditRecord 요소로 이어져 들어간다. 파일 이름에 서버 프로세스 번호와 시각이 들어간다.
@B AuditRecord에는 DB_User, OS_User, Userhost, Object_Schema, Object_Name, Policy_Name, Stmt_Type, Scn, Sql_Text 등이 태그로 들어간다.
@B Extended_Timestamp는 끝에 Z가 붙은 UTC 시각이다. 실습에서 한국 시각 20:14의 기록이 11:14Z로 남았다. 다른 로그와 맞춰 볼 때 시간대를 먼저 맞춘다.
@B XML 파일은 데이터베이스가 지우지 않는다. 보관과 정리는 13장의 DBMS_AUDIT_MGMT(AUDIT_TRAIL_XML)나 OS 작업으로 한다.

@CODE
<AuditRecord><Audit_Type>2</Audit_Type> ... <Extended_Timestamp>2026-10-27T11:14:00.535915Z</Extended_Timestamp>
<DB_User>HR</DB_User> ... <Object_Name>EMPLOYEES</Object_Name><Policy_Name>EMP_SAL_DML</Policy_Name> ...
<Sql_Text>UPDATE employees SET salary = 9999 WHERE employee_id = 106</Sql_Text>
</AuditRecord>
@END

@H3 12.6.4  기록 위치를 바꿀 때

@B audit_trail을 바꾸려면 정책을 DROP 후 ADD한다. 바꾸기 전의 기록은 원래 위치에 남는다. 실습 03에서 DB에서 XML로 바꾼 뒤 DBA_FGA_AUDIT_TRAIL에는 이전 기록 1건만 남고, 새 기록은 XML 파일에만 생겼다.
@B 기록 위치를 바꾸는 시점을 감사 담당자에게 알려 두어야 한다. 조회 대상 뷰가 바뀌기 때문이다.
@B 순수 통합 감사로 전환하면 기존 FGA_LOG$와 XML 파일의 기록은 그대로 남고, 새 기록만 통합 감사 기록으로 간다. 전환 전 기록의 보관 계획을 따로 세운다.

@H3 12.6.5  audit_trail 선택 기준

@TBL
상황 | 권장 옵션 | 이유
조회 조건까지 확인해야 하는 감사 | DB + EXTENDED | SQL 문과 바인드 값으로 무엇을 찾았는지 알 수 있음
기록 양이 많고 접근 사실만 필요 | DB | 기록 크기가 작음
DBA와 감사 담당자를 분리해야 함 | XML + EXTENDED | OS 파일이라 DB 권한만으로 지우기 어려움
순수 통합 감사 환경 | 지정하지 않음 | 모든 기록이 UNIFIED_AUDIT_TRAIL로 감
@END

@B XML을 고를 때는 파일 디렉터리의 소유권과 수집 경로를 함께 설계한다. oracle OS 계정이 파일을 지울 수 있다면 DB 권한 분리의 의미가 줄어든다.
@B 같은 테이블에 옵션이 다른 정책을 함께 둘 수도 있다. 일상 감시용 DB 정책과 고위험 조회용 XML+EXTENDED 정책을 나누는 식이다.

@H2 12.7  이벤트 핸들러

@H3 12.7.1  핸들러의 형식과 실행 시점

@B 핸들러는 감사 조건이 충족됐을 때 호출되는 PL/SQL 프로시저다. 기록과 함께 즉시 알림을 보내야 할 때 쓴다.
@B 형식은 (object_schema, object_name, policy_name) 세 VARCHAR2 인자를 받는 프로시저로 고정이다.
@B 조건을 만족하는 첫 행이 처리된 뒤 한 번 호출된다. 핸들러 소유자의 권한으로 실행된다.
@B 핸들러 안에서 COMMIT, ROLLBACK, DDL을 쓰지 않는다. 같은 테이블에 DML을 하거나 DBMS_FGA.ENABLE_POLICY·DISABLE_POLICY를 부르는 재귀적 구성도 금지다.
@B 알림 방법으로는 파일 기록(UTL_FILE), 메일(UTL_SMTP·UTL_MAIL), 큐 등록이 쓰인다. 외부 시스템 호출은 4장의 네트워크 ACL이 필요하다.
@B 핸들러가 받는 인자에는 누가 조회했는지가 없다. 사용자 정보는 핸들러 안에서 `SYS_CONTEXT('USERENV', ...)`로 직접 읽는다. 실습 핸들러도 SESSION_USER를 읽어 알림에 넣었다.
@B 정책 정의의 PF_SCHEMA, PF_FUNCTION 컬럼(DBA_AUDIT_POLICIES)에 핸들러가 기록된다. 핸들러가 지워지거나 INVALID가 되면 감사 조건을 만족하는 순간 사용자 문장이 실패하므로 정기 점검 대상이다.

@CODE
CREATE OR REPLACE PROCEDURE secadm.rt_alert (
  p_schema IN VARCHAR2,
  p_object IN VARCHAR2,
  p_policy IN VARCHAR2)
AS
  f UTL_FILE.FILE_TYPE;
BEGIN
  f := UTL_FILE.FOPEN('FGA_ALERT_DIR', 'fga_alert.log', 'a');
  UTL_FILE.PUT_LINE(f, TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || ' '
                       || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' '
                       || p_schema || '.' || p_object || ' ' || p_policy);
  UTL_FILE.FCLOSE(f);
END;
/
@END

@H3 12.7.2  핸들러 오류는 사용자 문장을 실패시킨다

@B 핸들러가 예외를 내면 감사 대상이던 사용자 문장도 함께 실패한다. 매뉴얼에 명시된 동작이다.
@B 알림용 파일 디렉터리가 없어지거나 메일 서버가 응답하지 않으면 업무 조회가 실패하는 셈이다. 감사 장치가 업무 장애의 원인이 된다.
@B 핸들러는 예외를 반드시 처리한다. 알림 실패는 다른 방법(예: 별도 테이블, 경고 로그)으로 남기고 사용자 문장은 계속 진행되게 만든다.
@B 실습에서 알림 파일을 쓸 OS 디렉터리를 만들지 않은 채 조건을 만족하는 조회를 하자 사용자에게 ORA-28144(핸들러 실행 실패)와 그 원인인 ORA-29283이 돌아갔다. 조건을 만족하지 않는 조회는 핸들러가 불리지 않아 정상이었다.
@B 실패한 그 조회도 FGA 기록에는 남았다. 감사 기록은 핸들러의 성공 여부와 별개로 만들어진다.

@CODE
HR@orcl> SELECT last_name, salary FROM employees WHERE employee_id = 100;
ERROR at line 1:
ORA-28144: Failed to execute fine-grained audit handler
ORA-29283: invalid file operation: nonexistent file or path [29434]
@END

@H3 12.7.3  예외를 처리하는 핸들러

@B 실습의 핸들러는 오류를 그대로 올려 보내 업무 조회를 실패시켰다. 운영용 핸들러는 알림 실패를 삼키고 다른 경로로 흔적을 남긴다.
@B 아래 형태는 파일 기록이 실패하면 열린 파일을 닫고 아무것도 하지 않는다. 감사 기록 자체는 FGA_LOG$에 남으므로 알림이 빠져도 사후 확인은 가능하다.

@CODE
CREATE OR REPLACE PROCEDURE secadm.rt_alert (
  p_schema IN VARCHAR2,
  p_object IN VARCHAR2,
  p_policy IN VARCHAR2)
AS
  f UTL_FILE.FILE_TYPE;
BEGIN
  f := UTL_FILE.FOPEN('FGA_ALERT_DIR', 'fga_alert.log', 'a');
  UTL_FILE.PUT_LINE(f, TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || ' '
                       || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' ' || p_policy);
  UTL_FILE.FCLOSE(f);
EXCEPTION
  WHEN OTHERS THEN
    IF UTL_FILE.IS_OPEN(f) THEN
      UTL_FILE.FCLOSE(f);
    END IF;
END;
/
@END

@CASE 메일 서버 점검 시간에 인사 시스템이 멈췄다
고액 연봉자 조회 시 감사팀에 메일을 보내는 FGA 핸들러를 운영하고 있었다. 어느 토요일 사내 메일 서버 점검이 시작되자 인사 시스템의 급여 조회 화면이 모두 오류를 냈다.
화면 오류는 ORA-28144였고, 핸들러 안의 UTL_SMTP 연결이 실패하고 있었다. 감사 알림 하나 때문에 업무 조회 전체가 멈춘 것이다.
핸들러에 예외 처리를 넣어 메일 발송 실패 시 아무것도 하지 않도록 바꾸고, 대신 감사팀이 FGA 기록을 주기적으로 조회해 누락된 알림을 확인하는 절차를 만들었다.
@END

@TBL
알림 방법 | 쓰는 패키지 | 주의할 점
파일 기록 | UTL_FILE | 디렉터리 객체와 OS 경로, 파일 크기 관리
메일 | UTL_SMTP, UTL_MAIL | 네트워크 ACL(4장), 메일 서버 장애 시 예외 처리
비동기 처리 | DBMS_AQ(큐 등록) | 핸들러에서는 등록만, 실제 발송은 별도 작업
@END

@B 핸들러 안에서 시간이 오래 걸리는 일을 하면 사용자 조회가 그만큼 느려진다. 핸들러는 사용자 문장 처리 도중에 실행되기 때문이다.
@B 외부 시스템 호출은 큐에 넣고 별도 작업이 처리하게 하는 구성이 안전하다. 메일 서버나 메신저가 느려도 업무 조회가 영향을 받지 않는다.

@H3 12.7.4  핸들러와 사용자 트랜잭션

@B 핸들러는 사용자 문장 처리 도중에 같은 세션에서 실행된다. 핸들러가 DML을 하면 그 변경은 사용자 트랜잭션의 일부가 된다.
@B 매뉴얼이 핸들러 안의 COMMIT, ROLLBACK, DDL을 금지하는 이유가 여기에 있다. 핸들러가 COMMIT하면 사용자가 아직 확정하지 않은 변경까지 확정된다.
@B 알림을 테이블에 남기고 싶다면 핸들러는 큐 등록이나 파일 기록처럼 트랜잭션 밖의 수단을 쓰는 편이 안전하다. 실습이 UTL_FILE을 쓴 것도 같은 이유다.

@BP 핸들러 작성 규칙
인자 형식을 지키고 소유자 권한으로 필요한 객체에 접근할 수 있는지 확인한다.
외부 호출은 짧은 타임아웃을 두고, 모든 예외를 처리한다.
COMMIT, ROLLBACK, DDL, 같은 테이블에 대한 DML을 넣지 않는다.
업무 계정으로 감사 조건을 만족하는 조회와 만족하지 않는 조회를 모두 시험한다.
@END

@H2 12.8  정책 관리

@H3 12.8.1  비활성화, 활성화, 삭제

@B `DBMS_FGA.DISABLE_POLICY(스키마, 객체, 정책)`는 정책을 끄고, `ENABLE_POLICY`는 다시 켠다. 끈 동안의 접근은 기록되지 않는다.
@B `DROP_POLICY`는 정책을 지운다. 이미 쌓인 감사 기록은 지워지지 않는다.
@B 정책 조건이나 컬럼을 바꾸는 API는 없다. DROP 후 ADD로 다시 만든다. 그 사이의 접근은 기록되지 않으므로 한 블록에서 연달아 실행한다.
@B DBMS_FGA 프로시저는 실행 전에 세션의 진행 중인 DML 트랜잭션을 COMMIT한다. 같은 세션에서 데이터 작업 도중 정책을 바꾸면 의도치 않게 작업이 확정된다.
@B 같은 객체에 같은 이름으로 다시 ADD_POLICY하면 ORA-28101, 없는 이름을 DROP_POLICY하면 ORA-28102가 난다.
@CODE
SECADM@orcl> EXEC DBMS_FGA.DISABLE_POLICY('HR', 'EMPLOYEES', 'EMP_HIGH_SAL')
SECADM@orcl> EXEC DBMS_FGA.ENABLE_POLICY('HR', 'EMPLOYEES', 'EMP_HIGH_SAL')
SYS@orcl> SELECT policy_name, enabled FROM dba_audit_policies WHERE object_schema = 'HR';
@END

@B 정책을 만든 사용자를 지우면 정책도 사라진다. 실습에서 감사 관리 계정 SECADM을 `DROP USER ... CASCADE`로 지우자 HR.EMPLOYEES의 FGA 정책 수가 0이 됐다. 쌓인 감사 기록은 그대로 남는다.

@H3 12.8.2  Data Pump와 정책 이동

@B Data Pump로 테이블을 내보내면 FGA 정책 정의도 함께 내보내진다. ADD_POLICY의 policy_owner 인자는 이때 Data Pump가 원래 소유자를 기록하는 데 쓴다.
@B 가져오는 쪽 DB에 핸들러 프로시저나 정책 소유자가 없으면 정책이 정상 동작하지 않는다. 가져온 뒤 DBA_AUDIT_POLICIES와 핸들러 상태를 확인한다.
@B 감사 기록(FGA_LOG$)은 업무 테이블과 함께 이동하지 않는다. 기록 보관은 별도 절차다.

@CASE 담당자 계정을 정리했더니 감사가 사라졌다
감사 담당자가 퇴사해 그의 데이터베이스 계정을 DROP USER ... CASCADE로 정리했다. 몇 달 뒤 내부 감사에서 급여 조회 기록을 요청받았는데, 계정 정리 이후의 FGA 기록이 한 건도 없었다.
그 담당자가 만든 FGA 정책이 계정과 함께 자동으로 삭제된 것이 원인이었다. 이미 쌓여 있던 기록은 남았지만 그 뒤로는 아무것도 기록되지 않았다.
이후 FGA 정책은 개인 계정이 아닌 감사 관리 전용 계정으로만 만들도록 했고, 계정 삭제 체크리스트에 DBA_AUDIT_POLICIES의 POLICY_OWNER 확인을 넣었다.
@END

@H3 12.8.3  정책 관리 작업도 감사한다

@B 감사 정책을 끄고 민감 데이터를 조회한 뒤 다시 켜면 FGA 기록에는 흔적이 없다.
@B 정책 변경 자체를 기록하려면 통합 감사 정책으로 DBMS_FGA 실행을 감사 대상에 넣는다. 실습에서 DISABLE 중에 한 조회는 FGA 기록 건수를 바꾸지 않았다.
@B 감사 기록 정리 권한(DBMS_AUDIT_MGMT)과 감사 정책 관리 권한(DBMS_FGA)을 업무 DBA와 분리한다. 감사 대상자가 자기 기록을 지울 수 없게 하는 것이 감사의 기본 조건이다.

@H2 12.9  FGA 관련 데이터 딕셔너리 뷰

@TBL
뷰 | 내용
DBA_AUDIT_POLICIES | FGA 정책 정의. 객체, 정책 이름, 조건(POLICY_TEXT), 컬럼(POLICY_COLUMN), 핸들러, ENABLED, SEL·INS·UPD·DEL, AUDIT_TRAIL, POLICY_COLUMN_OPTIONS
DBA_AUDIT_POLICY_COLUMNS | 정책별 감사 컬럼
DBA_FGA_AUDIT_TRAIL | SYS.FGA_LOG$의 FGA 기록. DB_USER, OS_USER, TIMESTAMP, POLICY_NAME, SQL_TEXT, SQL_BIND
V$XML_AUDIT_TRAIL | XML 파일로 쓴 감사 기록(통합 감사가 켜지지 않은 경우)
DBA_COMMON_AUDIT_TRAIL | 표준 감사와 FGA 기록을 합쳐 보여 주는 뷰
UNIFIED_AUDIT_TRAIL | 통합 감사 기록. FGA 기록은 AUDIT_TYPE = 'FineGrainedAudit', FGA_POLICY_NAME 컬럼
@END

@B DBA_FGA_AUDIT_TRAIL의 TIMESTAMP는 기록 시각이다. 기록이 많아지면 시각 범위 조회도 느려지므로 정기 정리(13장)가 필요하다.
@CODE
POLICY_NAME    POLICY_TEXT  POLICY_COLUMN  ENA SEL INS UPD DEL AUDIT_TRAIL  POLICY_COLU
-------------- ------------ -------------- --- --- --- --- --- ------------ -----------
EMP_SAL_ACCESS              SALARY         YES YES NO  NO  NO  DB+EXTENDED  ANY_COLUMNS

POLICY_NAME    POLICY_COLUMN
-------------- --------------
EMP_SAL_ACCESS SALARY
EMP_SAL_ACCESS COMMISSION_PCT
@END

@B 위 결과는 실습 01의 정책이다. 조건(POLICY_TEXT)이 비어 있고, audit_trail을 생략했는데 DB+EXTENDED로 등록됐으며, 감사 컬럼 두 개 중 DBA_AUDIT_POLICIES에는 첫 번째만 보인다.
@B 정책 정의 점검에는 DBA_AUDIT_POLICIES, 실제 기록 확인에는 DBA_FGA_AUDIT_TRAIL·UNIFIED_AUDIT_TRAIL을 쓴다.
@B DBA_COMMON_AUDIT_TRAIL은 표준 감사(AUD$)와 FGA(FGA_LOG$) 기록을 한 뷰로 합쳐 보여 준다. 혼합 모드에서 전통적 감사 기록을 한 번에 훑을 때 쓴다.
@B 감사 기록 조회 권한(SELECT ANY DICTIONARY, 해당 뷰 SELECT 권한)을 가진 사람이 곧 감사 기록 속 민감 정보를 볼 수 있는 사람이다.

@CODE
SYS@orcl> SELECT object_name, policy_name, policy_text, policy_column, enabled, sel, ins, upd, del
  2    FROM dba_audit_policies WHERE object_schema = 'HR';

SYS@orcl> SELECT db_user, policy_name, timestamp, sql_text
  2    FROM dba_fga_audit_trail ORDER BY timestamp;
@END

@H3 12.9.1  감사 기록으로 질문에 답하기

@B "지난주에 누가 사장 연봉을 조회했는가"는 정책이 EMP_HIGH_SAL처럼 설계되어 있으면 한 번의 조회로 답할 수 있다.
@B 기록에 남은 SCN과 시각, 사용자, 호스트, 프로그램을 함께 보면 접속 경로까지 좁힐 수 있다. 프록시 접속이나 CLIENT_IDENTIFIER가 있다면 실제 사용자도 확인된다.

@CODE
SYS@orcl> SELECT db_user, os_user, userhost, client_id, timestamp, sql_text
  2    FROM dba_fga_audit_trail
  3   WHERE policy_name = 'EMP_HIGH_SAL'
  4     AND timestamp >= TRUNC(SYSDATE) - 7
  5   ORDER BY timestamp;
@END

@NOTE 원본 실습 자료와 다른 점
원본은 SYS로 정책을 만들고 핸들러 스키마만 SECADM을 썼다. 이 교안은 SECADM을 감사 관리 계정으로 만들어 정책과 핸들러를 모두 두었다.
원본의 XML 예제는 HR.EMPLOYEES에 정책을 걸고 SCOTT.EMP를 UPDATE했는데, 정책 대상과 문장 대상이 달라 기록이 생기지 않는 흐름이다. 실습 03은 정책 대상 테이블에서 UPDATE를 한다.
@END

@H2 12.10  설계와 운영 시 주의점

@H3 12.10.1  정책 설계 순서

@TBL
단계 | 작업 | 확인할 것
1 | 감사 목적 정의 | 무엇을 누가 봤는지가 문제인가(컬럼), 어떤 행인가(조건)
2 | 감사 관리 계정 준비 | DBMS_FGA 실행 권한, 업무 DBA와 분리
3 | 정책 생성 | audit_column, audit_condition, statement_types, audit_trail
4 | 조건별 시험 | 조건 만족·불만족, 컬럼 참조·미참조 조회를 모두 업무 계정으로
5 | 기록 확인 | DBA_FGA_AUDIT_TRAIL 또는 UNIFIED_AUDIT_TRAIL
6 | 정리 정책 | 보관 기간과 DBMS_AUDIT_MGMT 정리 작업(13장)
@END

@B 1단계에서 감사 목적을 문장으로 적어 두면 3단계의 인자가 자연스럽게 정해진다. "급여 1만 이상 사원의 급여를 본 사람"이라는 문장에서 audit_column(SALARY)과 audit_condition(SALARY > 9999)이 바로 나온다.
@B 4단계 시험은 기록이 생겨야 하는 경우와 생기지 않아야 하는 경우를 반씩 준비한다. 기록이 생기지 않는 경우를 시험하지 않으면 과잉 기록을 놓친다.
@B 정책을 운영에 올리기 전에 하루치 예상 기록 건수를 추정한다. 업무 조회 통계(V$SQL의 실행 횟수)를 보면 대략 가늠할 수 있다.

@H3 12.10.2  운영 시 주의점

@B 조건 없는 정책(audit_condition NULL, audit_column NULL)은 표준 감사와 다를 바 없다. 기록이 많아지고 성능 부담만 커진다.
@B FGA 기록은 기본적으로 SYSTEM 테이블스페이스의 FGA_LOG$에 쌓인다(13장의 정리 초기화를 하면 SYSAUX로 옮겨진다). 정리하지 않으면 테이블스페이스가 가득 차고, 감사 기록을 쓸 수 없으면 감사 대상 문장이 실패할 수 있다.
@B EXTENDED 기록의 SQL 문·바인드 값은 민감 정보다. 감사 기록 조회 권한을 최소화한다.
@B 테이블을 다시 만들거나(DROP 후 CREATE) 다른 스키마로 옮기면 정책이 사라진다. 이관 절차에 DBA_AUDIT_POLICIES 비교를 넣는다.
@B 순수 통합 감사로 전환할 계획이라면 audit_trail 인자에 의존하지 않는 방식으로 정책을 만들고, 조회 스크립트를 UNIFIED_AUDIT_TRAIL 기준으로 준비해 둔다.
@B 정책 이름에는 업무 영역과 감사 목적을 드러낸다. 감사 기록을 볼 때 정책 이름만으로 무엇을 감시하는지 알아야 한다.
@B 감사 조건에 함수나 서브쿼리를 넣고 싶어질 때는 먼저 조건 없이 컬럼만으로 정책을 만들고, 조회 단계에서 기록을 걸러 내는 방식을 검토한다. 정책 오류는 업무 장애가 되지만 조회 단계의 실수는 보고서만 틀리게 한다.

@H3 12.10.3  성능 고려

@B FGA 정책이 걸린 테이블의 문장은 감사용 내부 질의와 조건 평가가 더해진다. 조건이 단순하면 비용이 작지만, 함수 호출이 들어간 조건은 행마다 함수를 부른다.
@B 기록이 생기는 문장은 FGA_LOG$에 INSERT가 한 번 더 일어난다. EXTENDED는 SQL 문과 바인드 값까지 저장하므로 기록이 커진다.
@B 대량 배치가 감사 대상 테이블을 처리한다면 배치 계정을 조건으로 제외하는 방법을 검토한다. 예를 들어 `SYS_CONTEXT('USERENV','SESSION_USER') <> 'BATCH_USER'`를 조건에 넣는다.
@B 감사 대상 DML이 있으면 직접 경로 적재가 일반 경로로 바뀐다는 점도 배치 시간 산정에 반영한다.

@H3 12.10.4  FGA와 통합 감사 정책 중 고르기

@B 통합 감사 정책도 WHEN 절로 조건을 줄 수 있다. 다만 그 조건은 세션 속성(SYS_CONTEXT) 기준이며, 처리되는 행의 값을 볼 수 없다.
@B "어떤 사용자가 어떤 테이블을 조회했는가"는 통합 감사 정책으로 충분하다. "급여 1만 이상인 행을 읽었는가"처럼 행 값이 기준이면 FGA가 필요하다.
@B 컬럼 단위 조건(특정 컬럼을 읽었는가)도 FGA만 표현할 수 있다.
@B 두 장치를 함께 쓸 때는 같은 접근이 두 곳에 기록되지 않게 범위를 나눈다. 일상 접근은 통합 감사 정책, 민감 값 접근은 FGA로 나누는 식이다.

@BP FGA 정책 점검표
DBA_AUDIT_POLICIES에서 ENABLED = NO인 정책이 있는지 본다.
POLICY_OWNER가 개인 계정인 정책이 있는지 본다. 계정 정리 때 정책이 사라진다.
핸들러가 있는 정책은 핸들러 상태(VALID)와 예외 처리 여부를 확인한다.
DBA_AUDIT_POLICY_COLUMNS로 감사 컬럼 전체를 확인한다.
FGA_LOG$ 건수와 테이블스페이스 사용량, 마지막 정리 시각을 함께 기록한다.
@END

@H3 12.10.5  정책 변경 이력

@B 정책 조건을 바꾸면 그 시점 전후의 기록 기준이 달라진다. "작년에는 기록됐던 조회가 올해는 없다"는 질문에 답하려면 정책 변경 이력이 있어야 한다.
@B DBA_AUDIT_POLICIES는 현재 정의만 보여 준다. 변경할 때마다 정의를 별도 표나 문서에 날짜와 함께 남긴다.
@B 통합 감사 정책으로 DBMS_FGA 실행을 기록해 두면 누가 언제 정책을 바꿨는지는 감사 기록에서도 확인할 수 있다.

@H3 12.10.6  멀티테넌트와 에디션 환경

@P 실습 DB orcl은 non-CDB라 아래 내용은 Security Guide 기준이다. 같은 정책을 CDB로 옮기거나 에디션 기반 재정의를 쓰는 애플리케이션에 적용할 때 확인한다.

@B FGA 정책은 CDB 루트, 애플리케이션 루트, 각 PDB에 만들 수 있다. 어디서 만들든 그 컨테이너의 객체에만 적용된다.
@B 통합 감사 정책과 달리 공통(common) FGA 정책은 없다. 루트에 만든 정책이 모든 PDB로 퍼지지 않으므로 PDB마다 정책을 만들고 PDB별 점검표를 따로 둔다.
@B SYS 스키마의 객체에는 FGA 정책을 걸 수 없다. 딕셔너리 접근 감시는 통합 감사 정책으로 한다.
@B 애플리케이션이 테이블마다 에디셔닝 뷰를 씌워 에디션 기반 재정의를 준비하면, 테이블에 걸려 있던 FGA 정책을 에디셔닝 뷰로 옮겨야 한다. 정책 결과를 모든 에디션에 같게 둘지 에디션마다 다르게 둘지도 정할 수 있다.
@B 비용 기반 옵티마이저에서만 지원되는 기능이다. 규칙 기반 옵티마이저는 행을 걸러 내기 전에 감시가 일어나 불필요한 기록을 만들 수 있다고 문서가 경고한다.

@H2 12.11  요약

@B FGA는 감사할 컬럼과 행 조건을 정책으로 지정해, 조건을 만족하는 접근만 감사 기록으로 남긴다. 접근을 막지는 않는다.
@B 기록은 문장 하나당 정책 하나에 1건이다. 조건을 만족하는 행이 실제로 처리되어야 기록되며, 사용자 트랜잭션을 ROLLBACK해도 기록은 남는다.
@B audit_column과 audit_column_opts(ANY·ALL)로 컬럼 참조 기준을, audit_condition으로 행 조건을, statement_types로 문장 유형을 정한다. audit_condition이 NULL이면 항상 참이다.
@B audit_trail은 DB(FGA_LOG$)와 XML(AUDIT_FILE_DEST)을 고르고 EXTENDED로 SQL 문·바인드 값을 더한다. 순수 통합 감사에서는 기록이 UNIFIED_AUDIT_TRAIL로 간다.
@B 핸들러는 조건 충족 시 알림을 보내지만, 핸들러 오류는 사용자 문장을 실패시킨다. 예외 처리가 필수다.
@B 정책 변경은 DROP 후 ADD다. 정책을 만든 사용자나 대상 객체를 지우면 정책도 사라진다.
@B 정책은 DBA_AUDIT_POLICIES, 기록은 DBA_FGA_AUDIT_TRAIL·V$XML_AUDIT_TRAIL·UNIFIED_AUDIT_TRAIL로 확인한다.

@H2 12.12  퀴즈

@QUIZ 문제 1
audit_condition => 'SALARY > 9999', audit_column => 'SALARY'인 SELECT 정책이 있다. 한 조회가 급여 1만 이상인 사원 3명을 포함해 10행을 반환했다. 이 정책으로 생기는 감사 기록은 몇 건인가?
① 0건  ② 1건  ③ 3건  ④ 10건
정답 ②. FGA는 문장 하나당 정책 하나에 최대 1건을 기록한다. 조건을 만족하는 행이 몇 개든 한 번만 기록된다.
@END

@QUIZ 문제 2
audit_condition을 NULL로 둔 정책의 동작으로 옳은 것은?
① 정책이 동작하지 않는다  ② 조건을 만족하는 행이 있을 때만 기록한다  ③ 처리된 행이 없어도 기록한다  ④ ORA-28138이 난다
정답 ③. NULL 조건은 항상 참으로 취급되어, 결과가 0건인 조회도 감사 대상 컬럼을 참조했다면 기록된다.
@END

@QUIZ 문제 3
FGA 정책이 걸린 테이블에서 사용자가 급여를 UPDATE한 뒤 ROLLBACK했다. 감사 기록은?
① 남는다  ② ROLLBACK과 함께 지워진다  ③ COMMIT할 때까지 보이지 않는다  ④ 다음 세션에서 기록된다
정답 ①. FGA 기록은 사용자 트랜잭션과 독립적으로 저장된다. 변경이 취소돼도 접근 시도는 기록에 남는다.
@END

@QUIZ 문제 4
audit_trail => DBMS_FGA.DB + DBMS_FGA.EXTENDED가 DB와 다른 점은?
① 기록 위치가 XML 파일로 바뀐다  ② 행마다 기록된다  ③ SQL 문 전체와 바인드 값이 함께 기록된다  ④ 통합 감사 기록에만 남는다
정답 ③. EXTENDED는 LSQLTEXT, LSQLBIND를 채워 DBA_FGA_AUDIT_TRAIL의 SQL_TEXT, SQL_BIND로 보이게 한다. 민감 정보가 평문으로 남는다는 점도 함께 관리해야 한다.
@END

@QUIZ 문제 5
FGA 핸들러 프로시저가 예외를 냈다. 감사 대상이던 사용자의 SELECT는 어떻게 되는가?
① 함께 실패한다  ② 정상 수행되고 경고만 남는다  ③ 감사 기록 없이 수행된다  ④ 정책이 자동으로 비활성화된다
정답 ①. 핸들러 오류는 사용자 문장 실패로 이어진다(ORA-28144). 실패한 문장도 감사 조건을 만족했다면 기록은 남는다. 그래서 핸들러는 모든 예외를 처리해 알림 실패가 업무 장애로 번지지 않게 만든다.
@END

@QUIZ 문제 6
FGA 정책이 사라지는 경우가 아닌 것은?
① DBMS_FGA.DROP_POLICY 실행  ② 대상 테이블 DROP  ③ 정책을 만든 사용자 DROP  ④ DBMS_FGA.DISABLE_POLICY 실행
정답 ④. DISABLE_POLICY는 정의를 남긴 채 정책을 끈다. 정책을 만든 사용자나 대상 객체를 지우면 정책도 함께 삭제된다.
@END

@H2 12.13  실습 개요

@P 실습은 oel7v9 서버의 orcl 데이터베이스(19.3, non-CDB, 혼합 감사 모드)에서 HR.EMPLOYEES를 대상으로 진행한다. HR 사용자로 조회와 DML을 하고, 감사 기록은 SYS로 확인한다. 감사 관리 계정 SECADM은 01에서 만들어 05에서 지우며, 이 장에서 쌓인 FGA 기록은 13장 실습 03에서 정리한다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
12장_실습_01_정책기본과기록위치 | 감사 관리 계정, ADD_POLICY 기본값(DB+EXTENDED), WHERE 절 참조와 0건 결과 기록, ORA-28101, 혼합 모드의 기록 위치 | 12.3, 12.4
12장_실습_02_감사조건과컬럼옵션 | audit_condition과 문장당 1건, 같은 테이블을 읽는 조건의 ORA-28112와 트레이스, AND 조건, ALL_COLUMNS | 12.5
12장_실습_03_DML감사와audit_trail옵션 | MERGE 지정 시 ORA-28106, ROLLBACK과 기록, SQL_BIND, XML 파일과 V$XML_AUDIT_TRAIL | 12.5.3, 12.6
12장_실습_04_이벤트핸들러 | UTL_FILE 핸들러, 디렉터리 부재 시 ORA-28144, 실패한 문장의 기록 | 12.7
12장_실습_05_정책관리와철거 | DISABLE·ENABLE, ORA-28102, 소유자 삭제 시 정책 자동 삭제, 원복 | 12.8, 12.9
@END
