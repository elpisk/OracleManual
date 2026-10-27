@H1 제13장  감사 기록 관리와 syslog 전송

@H2 13.1  학습 목표

@P 감사는 기록을 남기는 것으로 끝나지 않는다. 기록이 어디에 쌓이는지 알고, 필요한 기록을 찾아내고, 보관 기간이 지난 기록을 안전하게 정리하고, 데이터베이스 관리자도 손댈 수 없는 곳으로 내보낼 수 있어야 감사가 제 역할을 한다.

@B 혼합 감사 모드와 순수 통합 감사 모드의 차이를 설명하고 현재 모드를 판별할 수 있다.
@B 전통적 감사 기록과 통합 감사 기록이 저장되는 위치와 조회 뷰를 구분할 수 있다.
@B 기본 통합 감사 정책(ORA_SECURECONFIG, ORA_LOGON_FAILURES)이 무엇을 기록하는지 확인하고 UNIFIED_AUDIT_TRAIL에서 필요한 기록을 찾을 수 있다.
@B DBMS_AUDIT_MGMT로 마지막 아카이브 시각을 지정하고 그 이전 기록만 정리하며, 정리 작업을 예약할 수 있다.
@B AUDIT_SYSLOG_LEVEL로 SYS 감사 기록을 syslog로 보내고 rsyslog에서 별도 파일로 받을 수 있다.
@B UNIFIED_AUDIT_SYSTEMLOG가 쓰이는 조건과 AUDIT_SYSLOG_LEVEL과의 차이를 설명할 수 있다.
@B 감사 기록을 감사 대상자로부터 보호하기 위한 권한 분리 방법을 제시할 수 있다.

@H2 13.2  감사 모드

@H3 13.2.1  혼합 모드와 순수 통합 감사

@B 12c에 도입된 통합 감사(unified auditing)는 표준 감사, FGA, SYS 감사, Data Pump·RMAN 같은 구성 요소의 감사 기록을 한 곳(UNIFIED_AUDIT_TRAIL)에 모은다.
@B 19c를 새로 설치하면 혼합 모드(mixed mode)로 동작한다. 전통적 감사와 통합 감사가 함께 켜져 있다.
@B 혼합 모드에서는 AUDIT_TRAIL, AUDIT_FILE_DEST, AUDIT_SYS_OPERATIONS, AUDIT_SYSLOG_LEVEL 같은 기존 파라미터가 그대로 동작하고, 통합 감사 정책으로 만든 기록은 통합 감사 기록에 남는다.
@B 순수 통합 감사(pure unified auditing)는 전통적 감사를 끄고 통합 감사만 쓴다. 감사 성능이 좋아지고 기록 위치가 하나로 정리된다.
@B 현재 모드는 V$OPTION으로 판별한다.

@CODE
SYS@orcl> SELECT value FROM v$option WHERE parameter = 'Unified Auditing';

VALUE
----------------------------------------------------------------
FALSE
@END

@B FALSE면 혼합 모드, TRUE면 순수 통합 감사다. 실습 DB orcl은 FALSE다.

@H3 13.2.2  순수 통합 감사로 전환

@B 순수 통합 감사는 파라미터가 아니라 oracle 실행 파일 링크로 결정된다. 데이터베이스를 내리고 `$ORACLE_HOME/rdbms/lib`에서 uniaud_on 옵션으로 다시 링크한 뒤 기동한다.
@B 같은 ORACLE_HOME을 쓰는 모든 데이터베이스가 함께 전환된다. 실습 서버처럼 한 홈에 여러 DB가 있으면 모든 DB가 영향을 받는다.
@B 다시 링크하면(uniaud_off) 혼합 모드로 되돌릴 수 있다.
@B 전환 뒤에는 AUDIT_TRAIL, AUDIT_SYS_OPERATIONS, AUDIT_SYSLOG_LEVEL 같은 전통적 감사 파라미터가 효과를 잃는다. 이 파라미터에 기대던 수집 경로(예: adump 파일 수집, syslog 수집)를 전환 전에 통합 감사 기준으로 바꿔야 감사 공백이 생기지 않는다.
@B 전환 전에 쌓인 AUD$, FGA_LOG$, .aud 파일은 그대로 남는다. 조회와 정리는 기존 방법으로 계속 해야 한다.
@B 이 과정의 실습은 다른 장과 같은 ORACLE_HOME을 공유하므로 전환을 직접 해 보지 않는다. 절차는 Oracle Database Upgrade Guide의 통합 감사 이전 절을 따른다.

@CODE
[oracle@oel7v9 ~]$ cd $ORACLE_HOME/rdbms/lib
[oracle@oel7v9 lib]$ make -f ins_rdbms.mk uniaud_on ioracle
@END

@H3 13.2.3  모드별 기록 위치

@TBL
기록 종류 | 혼합 모드 | 순수 통합 감사
통합 감사 정책 기록 | AUDSYS.AUD$UNIFIED(UNIFIED_AUDIT_TRAIL) | 같음
표준 감사(AUDIT 문) | AUDIT_TRAIL 값에 따라 SYS.AUD$ 또는 OS·XML 파일 | 통합 감사 기록
FGA | SYS.FGA_LOG$ 또는 XML 파일(audit_trail 인자) | 통합 감사 기록
SYS 감사 | AUDIT_FILE_DEST의 .aud 파일 또는 syslog | 통합 감사 기록
필수 감사(기동·종료, SYSDBA 접속) | AUDIT_FILE_DEST의 .aud 파일 | 통합 감사 기록
@END

@B 혼합 모드에서는 같은 사건이 정책 설정에 따라 두 곳에 기록될 수 있다. 감사 기록을 볼 때는 어느 감사 장치가 남긴 기록인지 먼저 구분한다.
@B 12장에서 확인했듯 혼합 모드의 FGA 기록은 FGA_LOG$에만 남았다. "UNIFIED_AUDIT_TRAIL에 없으니 접근이 없었다"고 판단하면 틀린다.
@B AUDIT_TRAIL 값은 NONE, OS, DB, DB,EXTENDED, XML, XML,EXTENDED 중 하나다. 정적 파라미터라 바꾸려면 재기동한다.
@B 실습 DB orcl의 감사 파라미터는 AUDIT_TRAIL = DB, AUDIT_SYS_OPERATIONS = TRUE, AUDIT_FILE_DEST = /u01/app/oracle/admin/orcl/adump이며 AUDIT_SYSLOG_LEVEL과 UNIFIED_AUDIT_SYSTEMLOG는 비어 있다. SYS 작업은 adump의 .aud 파일로 쌓이고 있다.
@B 실습 시점에 adump에는 .aud 파일이 7천 개 넘게 쌓여 있었다. 몇 달 동안 SYSDBA 접속과 재기동만으로 생긴 파일이다.

@H3 13.2.4  SYS 감사와 필수 감사

@B AUDIT_SYS_OPERATIONS = TRUE(19c 기본값)이면 SYSDBA·SYSOPER로 접속한 세션이 실행한 모든 문장이 SYS 감사 기록으로 남는다. 혼합 모드에서는 이 기록이 AUDIT_FILE_DEST의 .aud 파일로 간다.
@B 이와 별도로 데이터베이스 기동·종료, SYSDBA 접속 같은 필수 감사(mandatory audit)는 AUDIT_SYS_OPERATIONS 값과 관계없이 항상 기록된다.
@B .aud 파일 하나에는 서버 프로세스 하나의 기록이 들어간다. 파일 안에는 ACTION(실행한 문장), DATABASE USER(OS 인증이면 '/'), PRIVILEGE(SYSDBA 등), CLIENT USER(OS 사용자), STATUS(0이면 성공) 같은 항목이 있다.
@B SYS 작업은 데이터베이스 안의 권한으로 막을 수 없으므로 이 파일이 SYS 행위의 유일한 증거가 된다. 13.7절의 syslog 전송은 이 기록을 데이터베이스 서버 밖으로 내보내는 방법이다.

@CODE
ACTION :[7] 'CONNECT'
ACTION :[22] 'ALTER DATABASE   MOUNT'
ACTION :[7] 'STARTUP'
@END

@H2 13.3  통합 감사 정책

@H3 13.3.1  기본 정책

@B 새로 만든 19c 데이터베이스에는 ORA_SECURECONFIG와 ORA_LOGON_FAILURES가 모든 사용자에 대해 켜져 있다.
@B ORA_SECURECONFIG는 보안 관련 관리 작업(사용자·역할·프로파일 변경, 감사 정책 변경, 시스템 권한 부여 등)을 기록한다.
@B ORA_LOGON_FAILURES는 실패한 로그인 시도를 기록한다. 비밀번호 대입 공격의 흔적을 찾는 첫 자료다.
@B 이 밖에 ORA_ACCOUNT_MGMT, ORA_DATABASE_PARAMETER, ORA_CIS_RECOMMENDATIONS 같은 미리 정의된 정책이 있다. 정의만 있고 꺼져 있으므로 필요하면 AUDIT POLICY로 켠다.
@B 정의는 AUDIT_UNIFIED_POLICIES, 켜진 정책은 AUDIT_UNIFIED_ENABLED_POLICIES에서 본다.

@TBL
미리 정의된 정책 | 기록 대상 | 실습 DB 상태
ORA_SECURECONFIG | 사용자·역할·프로파일·권한 변경 등 보안 관리 작업(감사 옵션 49개) | 켜짐(모든 사용자)
ORA_LOGON_FAILURES | 실패한 로그인 | 켜짐(모든 사용자, 실패만)
ORA_ACCOUNT_MGMT | 계정 생성·변경·삭제 | 꺼짐
ORA_DATABASE_PARAMETER | 초기화 파라미터 변경 | 꺼짐
ORA_CIS_RECOMMENDATIONS | CIS 벤치마크 권고 항목 | 꺼짐
ORA_RAS_POLICY_MGMT, ORA_RAS_SESSION_MGMT | Real Application Security 관리·세션 | 꺼짐
ORA_DV_AUDPOL, ORA_DV_AUDPOL2 | Database Vault 관련 | 꺼짐
@END

@B ORA_LOGON_FAILURES는 실패(FAILURE)만 기록하도록 켜져 있다. 성공한 로그인까지 기록하면 기록 양이 크게 늘어나므로 필요할 때 별도 정책으로 범위를 좁혀 켠다.

@CODE
SYS@orcl> SELECT policy_name, enabled_option, entity_name FROM audit_unified_enabled_policies;
@END

@H3 13.3.2  정책 생성과 활성화

@B 감사 정책 자체의 설계는 Security Guide의 감사 정책 장 범위다. 이 장에서는 기록을 만들고 정리하는 데 필요한 최소한만 다룬다.
@B CREATE AUDIT POLICY로 정의하고 AUDIT POLICY로 켠다. BY 사용자, EXCEPT 사용자, WHENEVER [NOT] SUCCESSFUL로 대상과 조건을 좁힌다.
@B 켜진 정책은 DROP할 수 없다. NOAUDIT POLICY로 끈 다음 지운다.
@B 정책 변경은 그 뒤에 새로 연결하는 세션부터 적용된다. 이미 접속해 있던 세션은 이전 설정을 따른다.

@CODE
CREATE AUDIT POLICY sec13_emp_pol ACTIONS SELECT ON scott.emp, DELETE ON scott.emp;
AUDIT POLICY sec13_emp_pol BY scott;
NOAUDIT POLICY sec13_emp_pol BY scott;
DROP AUDIT POLICY sec13_emp_pol;
@END

@B 실습에서 켜진 정책을 바로 DROP하자 ORA-46361(Audit policy cannot be dropped as it is currently enabled)이 났다. NOAUDIT POLICY 후에는 지워졌다.
@B 정책 SEC13_EMP_POL 아래 SCOTT가 실행한 EMP 조회와 0건 DELETE가 모두 기록됐다. 지운 행이 없고 ROLLBACK했어도 DELETE 문의 실행 자체가 감사 대상이다.

@CODE
SYS@orcl> DROP AUDIT POLICY sec13_emp_pol;
ERROR at line 1:
ORA-46361: Audit policy cannot be dropped as it is currently enabled.
@END

@H3 13.3.3  정책 조건과 예외

@B `WHEN '조건' EVALUATE PER STATEMENT|SESSION|INSTANCE`로 정책이 기록할 상황을 좁힌다. 조건은 SYS_CONTEXT 같은 세션 속성으로 쓴다.
@B EVALUATE PER SESSION은 세션 시작 때 한 번 조건을 평가한다. 접속 프로그램이나 호스트처럼 세션 동안 바뀌지 않는 속성에 쓴다. 문장마다 바뀌는 속성은 PER STATEMENT를 쓴다.
@B `AUDIT POLICY 정책 EXCEPT 사용자`는 지정한 사용자를 뺀 나머지 모두를 대상으로 한다. 업무 애플리케이션 계정을 빼고 사람 계정만 기록할 때 쓴다.
@B `BY USERS WITH GRANTED ROLES 역할`은 특정 역할을 받은 사용자 전부를 대상으로 한다. DBA 역할 보유자의 행위를 모두 기록하는 식이다.
@B 행 값을 조건으로 쓸 수는 없다. "급여 1만 이상인 행을 읽었을 때"는 12장의 FGA 몫이다.

@CODE
CREATE AUDIT POLICY sec13_dba_pol
  ACTIONS ALL ON hr.employees
  WHEN 'SYS_CONTEXT(''USERENV'', ''MODULE'') <> ''HR_APP'''
  EVALUATE PER SESSION;
AUDIT POLICY sec13_dba_pol BY USERS WITH GRANTED ROLES dba;
@END

@H3 13.3.4  감사 관리 역할

@B AUDIT_ADMIN 역할은 통합 감사 정책을 만들고 켜며 감사 기록을 정리할 수 있다.
@B AUDIT_VIEWER 역할은 감사 기록을 조회만 할 수 있다.
@B 업무 DBA에게 AUDIT_ADMIN을 주면 감사 대상자가 자기 기록을 지울 수 있다. 감사 관리 계정을 따로 두고 DBA 역할과 분리한다.
@B 통합 감사 기록 테이블은 INSERT만 허용된다. AUD$UNIFIED를 직접 DELETE, UPDATE, TRUNCATE하면 실패하고, 그 시도 자체가 감사 기록으로 남는다. 정리는 DBMS_AUDIT_MGMT로만 한다.

@H2 13.4  통합 감사 기록 조회

@H3 13.4.1  주요 컬럼

@TBL
컬럼 | 내용
EVENT_TIMESTAMP | 사건 시각
DBUSERNAME | 데이터베이스 사용자
OS_USERNAME, USERHOST, TERMINAL | 접속한 OS 사용자와 클라이언트 호스트
CLIENT_PROGRAM_NAME | 접속 프로그램
AUDIT_TYPE | Standard, FineGrainedAudit, Datapump, RMAN_AUDIT 등 기록을 만든 구성 요소
UNIFIED_AUDIT_POLICIES | 이 기록을 만든 정책 이름
ACTION_NAME | LOGON, SELECT, CREATE USER 등 동작
OBJECT_SCHEMA, OBJECT_NAME | 대상 객체
RETURN_CODE | 0이면 성공, 그 밖에는 ORA- 오류 번호
SQL_TEXT, SQL_BINDS | 실행한 문장과 바인드 값
FGA_POLICY_NAME | FGA 기록일 때 정책 이름
@END

@B 19c의 UNIFIED_AUDIT_TRAIL에는 EVENT_TIMESTAMP와 함께 EVENT_TIMESTAMP_UTC 컬럼이 있다. 정리 작업의 아카이브 시각처럼 UTC가 필요한 곳에는 EVENT_TIMESTAMP_UTC를 쓴다.
@B ORA_LOGON_FAILURES가 만든 기록은 AUDIT_TYPE이 Standard이고 UNIFIED_AUDIT_POLICIES에 정책 이름이 들어간다. 실습에서 1017(비밀번호 오류) 외에 1045(CREATE SESSION 권한 없음), 28150(프록시 권한 없음)도 RETURN_CODE로 남았다.

@B EVENT_TIMESTAMP는 데이터베이스 서버 시간대로, EVENT_TIMESTAMP_UTC는 UTC로 표시된다. 실습 DB에서 가장 오래된 기록이 EVENT_TIMESTAMP로 14:55, EVENT_TIMESTAMP_UTC로 05:55였다(KST와 9시간 차이).
@B 화면 조회에는 EVENT_TIMESTAMP, 정리 작업이나 다른 시스템 로그와의 대조에는 EVENT_TIMESTAMP_UTC를 쓰면 시간대 혼동이 줄어든다.

@H3 13.4.2  찾는 방법

@B 실패한 로그인은 ACTION_NAME = 'LOGON'이면서 RETURN_CODE가 0이 아닌 기록이다. ORA-01017은 1017로 남는다.
@B 실습 01에서는 비밀번호를 틀린 SCOTT의 시도가 ORA_LOGON_FAILURES 정책 이름과 함께 기록됐다. 같은 시간대의 다른 실패(권한 없음 1045, 프록시 권한 없음 28150)도 같은 조회로 함께 나왔다. 실패 원인이 RETURN_CODE로 구분되므로 집계할 때 이 컬럼을 함께 묶는다.
@B 특정 정책의 기록은 UNIFIED_AUDIT_POLICIES에 정책 이름이 들어간 기록이다. 여러 정책이 같은 사건을 기록하면 쉼표로 이어 붙는다.
@B 조회는 항상 시각 범위를 함께 준다. 통합 감사 테이블은 시각 기준으로 파티션되어 있어 범위를 주면 필요한 파티션만 읽는다.
@B 19c Security Guide는 파티션 제거가 일어나게 WHERE 절에 EVENT_TIMESTAMP_UTC를 쓰라고 권한다. 19c에서 AUD$UNIFIED에 파티션 기준 컬럼이 새로 들어가며 뷰에 이 컬럼이 생겼다.
@B 통합 감사 기록은 감사 대상 세션과 독립적으로 바로 기록된다. 12.2부터 큐에 모았다가 쓰는 방식이 없어져 FLUSH_UNIFIED_AUDIT_TRAIL은 더 이상 필요하지 않고 디프리케이트됐다.

@CODE
SYS@orcl> SELECT event_timestamp, dbusername, userhost, return_code
  2    FROM unified_audit_trail
  3   WHERE action_name = 'LOGON' AND return_code <> 0
  4     AND event_timestamp > SYSTIMESTAMP - INTERVAL '1' HOUR;
@END

@H3 13.4.3  자주 쓰는 조회

@CODE
-- 최근 하루 로그인 실패를 사용자·호스트별로
SELECT dbusername, userhost, return_code, COUNT(*)
  FROM unified_audit_trail
 WHERE action_name = 'LOGON' AND return_code <> 0
   AND event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
 GROUP BY dbusername, userhost, return_code ORDER BY 4 DESC;

-- 최근 일주일 사용자·권한 변경
SELECT event_timestamp, dbusername, action_name, object_name, sql_text
  FROM unified_audit_trail
 WHERE action_name IN ('CREATE USER', 'ALTER USER', 'DROP USER', 'GRANT', 'REVOKE')
   AND event_timestamp > SYSTIMESTAMP - INTERVAL '7' DAY
 ORDER BY event_timestamp;

-- 정책별 기록 건수
SELECT unified_audit_policies, COUNT(*)
  FROM unified_audit_trail
 WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
 GROUP BY unified_audit_policies ORDER BY 2 DESC;
@END

@B 정책별 건수 조회는 어떤 정책이 기록을 가장 많이 만드는지 보여 준다. 기록 공간이 빠르게 늘면 이 조회로 원인 정책부터 찾는다.
@B 실패한 로그인이 한 호스트에서 짧은 시간에 몰리면 비밀번호 대입이나 잘못된 접속 정보를 가진 배치 작업을 의심한다.

@CASE 새벽마다 늘어나는 로그인 실패
운영 DB의 계정 하나가 매일 아침 잠겨 있다는 신고가 들어왔다. 프로파일의 FAILED_LOGIN_ATTEMPTS에 걸려 잠긴 것이었는데, 사용자는 자신이 비밀번호를 틀린 적이 없다고 했다.
UNIFIED_AUDIT_TRAIL에서 해당 계정의 LOGON 실패 기록을 조회하니 새벽 2시 무렵 1017 오류가 10건씩 몰려 있었다. USERHOST와 CLIENT_PROGRAM_NAME이 모두 배치 서버의 오래된 스크립트를 가리켰다.
비밀번호를 바꾼 뒤 배치 스크립트의 접속 정보가 갱신되지 않은 것이 원인이었다. 스크립트를 1장의 Secure External Password Store 방식으로 바꿔 비밀번호를 파일에 적지 않게 했다. 기본 정책 ORA_LOGON_FAILURES가 켜져 있었기에 따로 감사를 설정하지 않고도 원인을 찾을 수 있었다.
@END

@H2 13.5  감사 기록의 저장

@H3 13.5.1  통합 감사 기록

@B 통합 감사 기록은 AUDSYS 스키마의 AUD$UNIFIED 테이블에 쌓이며 기본 위치는 SYSAUX 테이블스페이스다.
@B 매뉴얼은 통합 감사 기록용 테이블스페이스를 따로 두기를 권한다. `DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION`으로 옮긴다. 이후 새로 만들어지는 파티션부터 새 위치에 생긴다.
@B AUD$UNIFIED는 시각 기준 인터벌 파티션 테이블이며 기본 간격은 1개월이다. 기록이 많은 시스템은 `ALTER_PARTITION_INTERVAL`로 간격을 줄여 파티션 하나에 기록이 몰리지 않게 한다.
@B 데이터베이스에 쓸 수 없는 상태(마운트, 읽기 전용)에서 생긴 기록은 `$ORACLE_BASE/audit/$ORACLE_SID`의 OS 파일로 넘쳐 쓰인다. 열린 뒤 `LOAD_UNIFIED_AUDIT_FILES`로 테이블에 옮긴다.

@H3 13.5.2  전통적 감사 기록

@B SYS.AUD$는 표준 감사(AUDIT_TRAIL=DB) 기록, SYS.FGA_LOG$는 FGA 기록을 담는다. DBA_AUDIT_TRAIL, DBA_FGA_AUDIT_TRAIL로 본다.
@B AUDIT_FILE_DEST(실습 DB는 /u01/app/oracle/admin/orcl/adump)에는 SYS 감사와 필수 감사의 .aud 파일, XML 감사 파일이 쌓인다.
@B 이 파일들은 데이터베이스가 지우지 않는다. 정리하지 않으면 디렉터리의 inode나 공간이 고갈되고, 감사 파일을 쓸 수 없게 되면 접속이 실패할 수 있다.
@B 실습 DB에서 AUDSYS.AUD$UNIFIED는 `INTERVAL '1' MONTH`의 범위 파티션 테이블이었고 파티션 다섯 개가 모두 SYSAUX에 있었다.
@B 같은 DB의 SYS.AUD$와 SYS.FGA_LOG$는 SYSTEM 테이블스페이스에 있었다. 13.6.3의 INIT_CLEANUP이 이 위치를 바꾼다.

@NOTE 감사 기록 테이블은 SYS도 직접 지울 수 없다
실습에서 SYS로 `DELETE FROM audsys.aud$unified`와 `TRUNCATE TABLE audsys.aud$unified`를 시도하자 둘 다 ORA-46385로 거부됐다.
거부된 시도는 RETURN_CODE 46385인 감사 기록으로 남았다. 기록을 지우려는 시도 자체가 증거가 되는 구조다. 통합 감사 기록의 정리는 DBMS_AUDIT_MGMT로만 한다.
@END

@H3 13.5.3  adump 디렉터리 관리

@B .aud 파일은 DBMS_AUDIT_MGMT의 AUDIT_TRAIL_OS 유형으로 정리할 수 있다. 아카이브 시각은 파일을 만든 서버의 현지 시각으로 준다.
@B OS 쪽에서 find 명령으로 오래된 파일을 지우는 방법도 흔히 쓴다. 이때도 먼저 보관 대상인지 확인하고, 보관이 필요하면 다른 서버로 옮긴 뒤 지운다.
@B 파일 수가 많아지면 `ls`조차 느려지고 inode가 고갈될 수 있다. 실습 DB처럼 수천 개가 쌓이기 전에 정리 주기를 정한다.

@CODE
[oracle@oel7v9 ~]$ find /u01/app/oracle/admin/orcl/adump -name '*.aud' -mtime +90 | wc -l
[oracle@oel7v9 ~]$ find /u01/app/oracle/admin/orcl/adump -name '*.aud' -mtime +90 -delete
@END

@CASE adump 때문에 SYSDBA 접속이 안 된다
야간 작업 중 `sqlplus / as sysdba`가 갑자기 실패했다. 오류 메시지는 감사 파일을 쓸 수 없다는 내용이었고, 디스크 사용률은 60%로 여유가 있었다.
df -i로 확인하니 inode 사용률이 100%였다. 3년 동안 정리하지 않은 adump 디렉터리에 .aud 파일이 수백만 개 쌓여 있었다. SYSDBA 접속은 필수 감사 대상이라 파일을 만들 수 없으면 접속 자체가 실패한다.
90일이 지난 파일을 다른 서버로 압축해 옮긴 뒤 지우고, OS 스케줄러에 같은 작업을 매주 실행하도록 등록했다.
@END

@H3 13.5.4  감사 기록 공간 확인

@CODE
SELECT owner, segment_name, tablespace_name, ROUND(SUM(bytes)/1024/1024) mb
  FROM dba_segments
 WHERE (owner = 'AUDSYS') OR (owner = 'SYS' AND segment_name IN ('AUD$', 'FGA_LOG$'))
 GROUP BY owner, segment_name, tablespace_name;
@END

@B AUDSYS 세그먼트는 파티션과 LOB 세그먼트로 나뉘어 이름이 여러 개 나온다. 소유자 기준으로 합산해 추세를 본다.
@B SYSAUX를 쓰는 다른 구성 요소(AWR 등)와 공간을 나눠 쓰므로, 감사 기록이 늘면 AWR 보관에도 영향을 줄 수 있다. 전용 테이블스페이스를 권하는 이유다.

@H2 13.6  DBMS_AUDIT_MGMT로 감사 기록 정리

@H3 13.6.1  정리의 원칙

@P 감사 기록은 지우기 전에 보관해야 한다. DBMS_AUDIT_MGMT의 기본 흐름은 "외부 보관 → 마지막 아카이브 시각 기록 → 그 시각 이전 기록 삭제"다.

@B 감사 기록을 다른 저장소(감사 전용 DB, SIEM, 파일)로 옮긴 다음 SET_LAST_ARCHIVE_TIMESTAMP로 어디까지 옮겼는지 기록한다.
@B CLEAN_AUDIT_TRAIL은 use_last_arch_timestamp => TRUE(기본)일 때 그 시각 이전 기록만 지운다. FALSE면 모두 지운다. 매뉴얼은 실수로 지우는 일을 막기 위해 TRUE를 권한다.
@B 정기 정리는 CREATE_PURGE_JOB으로 예약한다. 작업은 내부적으로 CLEAN_AUDIT_TRAIL을 부른다. 아카이브 시각을 갱신하는 작업은 따로 만들어야 한다.

@H3 13.6.2  감사 기록 유형 상수

@TBL
상수 | 대상
AUDIT_TRAIL_UNIFIED | 통합 감사 기록
AUDIT_TRAIL_AUD_STD | SYS.AUD$
AUDIT_TRAIL_FGA_STD | SYS.FGA_LOG$
AUDIT_TRAIL_DB_STD | AUD$와 FGA_LOG$
AUDIT_TRAIL_OS | OS 감사 파일(.aud)
AUDIT_TRAIL_XML | XML 감사 파일
AUDIT_TRAIL_FILES | OS와 XML 파일
AUDIT_TRAIL_ALL | 위 전부
@END

@H3 13.6.3  초기화와 아카이브 시각

@B 통합 감사 기록은 따로 초기화하지 않아도 정리할 수 있다. AUDIT_TRAIL_UNIFIED로 INIT_CLEANUP을 부르면 ORA-46250이 난다.
@B AUD$, FGA_LOG$(AUD_STD, FGA_STD, DB_STD)는 INIT_CLEANUP으로 정리 기반을 만들어야 한다. IS_CLEANUP_INITIALIZED로 상태를 확인한다.
@B OS·XML 파일은 초기화가 필요 없다. 정리 대상은 현재 AUDIT_FILE_DEST에 있는 파일뿐이다.
@B SET_LAST_ARCHIVE_TIMESTAMP의 시각은 데이터베이스 기록(UNIFIED, AUD_STD, FGA_STD)이면 UTC, OS·XML 파일이면 파일을 만든 서버의 현지 시각으로 준다. 한국 표준시로 넣으면 9시간 어긋난 범위가 지워진다.
@B 단일 인스턴스에서 OS·XML 유형의 rac_instance_number는 1로 준다. DB 유형에는 이 인자를 주지 않는다.

@CODE
BEGIN
  IF NOT DBMS_AUDIT_MGMT.IS_CLEANUP_INITIALIZED(DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD) THEN
    DBMS_AUDIT_MGMT.INIT_CLEANUP(
      audit_trail_type         => DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD,
      default_cleanup_interval => 12);
  END IF;
END;
/
-- 이동된 테이블을 원래 위치로
BEGIN
  DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
    audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD,
    audit_trail_location_value => 'SYSTEM');
END;
/
@END
@B AUD$·FGA_LOG$에 INIT_CLEANUP을 실행하면 정리 기반을 만들면서 해당 테이블을 SYSAUX(기본값)로 옮긴다. 실습에서 FGA_LOG$가 SYSTEM에서 SYSAUX로 옮겨졌고 DBA_AUDIT_MGMT_CONFIG_PARAMS의 DB AUDIT TABLESPACE가 SYSAUX로 바뀌었다.
@B DEINIT_CLEANUP을 해도 테이블 위치는 돌아오지 않는다. 원래 위치로 되돌리려면 SET_AUDIT_TRAIL_LOCATION으로 다시 옮긴다. 운영 DB에서 처음 INIT_CLEANUP을 할 때는 테이블 크기만큼 이동 작업이 일어나므로 시간대를 고른다.
@B 초기화 전에 CLEAN_AUDIT_TRAIL(AUDIT_TRAIL_FGA_STD)을 부르면 ORA-46258(Cleanup not initialized), 통합 감사 기록에 INIT_CLEANUP을 부르면 ORA-46250이 난다. 실습 03에서 둘 다 확인한다.

@CODE
BEGIN
  DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
    audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    last_archive_time => SYS_EXTRACT_UTC(SYSTIMESTAMP) - INTERVAL '90' DAY);
  DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
    audit_trail_type        => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    use_last_arch_timestamp => TRUE);
END;
/
@END

@H3 13.6.4  정리 작업 예약

@CODE
BEGIN
  DBMS_AUDIT_MGMT.CREATE_PURGE_JOB(
    audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    audit_trail_purge_interval => 24,
    audit_trail_purge_name     => 'SEC13_UNIFIED_PURGE',
    use_last_arch_timestamp    => TRUE);
END;
/
@END

@B audit_trail_purge_interval은 시간 단위다. 24면 하루에 한 번 돈다.
@B 작업은 DBA_AUDIT_MGMT_CLEANUP_JOBS에서 확인하고, SET_PURGE_JOB_STATUS로 멈추거나 DROP_PURGE_JOB으로 지운다.
@B 마지막 아카이브 시각을 갱신하지 않으면 정리 작업은 매번 아무것도 지우지 않는다. 보관 작업이 끝날 때마다 시각을 갱신하는 단계를 같은 스케줄에 넣는다.
@B drop_partition_only => TRUE로 CLEAN_AUDIT_TRAIL을 부르면 통합 감사 기록에서 아카이브 시각 이전의 파티션만 통째로 지운다. 행 단위 삭제보다 빠르지만 현재 파티션의 기록은 남는다.

@H3 13.6.5  정리 작업의 첫 실행

@B CREATE_PURGE_JOB으로 만든 작업은 생성 직후 첫 실행에 들어갈 수 있다. 실습에서 작업을 만들고 바로 DROP_PURGE_JOB을 부르자 ORA-27478(job is running)로 실패했다.
@B 실행을 마친 작업은 상태가 바뀐 뒤 지울 수 있었다. 작업을 시험 삼아 만들었다면 DBA_AUDIT_MGMT_CLEANUP_JOBS와 DBA_SCHEDULER_JOBS로 상태를 확인하고 지운다.
@B 첫 실행이 곧바로 일어난다는 것은 작업을 만드는 순간 정리가 시작된다는 뜻이기도 하다. 아카이브 시각이 잘못 설정된 상태에서 작업을 만들면 그 즉시 잘못된 범위가 지워진다. 작업 생성 전에 아카이브 시각부터 확인한다.

@H3 13.6.6  외부 보관 방법

@B 감사 전용 데이터베이스로 옮기기: DB 링크로 UNIFIED_AUDIT_TRAIL을 조회해 보관용 테이블에 INSERT한다. 옮긴 범위의 마지막 시각을 아카이브 시각으로 쓴다.
@B 파일로 내보내기: 기간별로 조회 결과를 CSV·JSON으로 내려 별도 저장소에 보관한다. 파일 위·변조를 막기 위해 해시 값을 함께 남긴다.
@B SIEM 연동: syslog(13.7절)나 수집 에이전트로 보안 관제 시스템에 실시간 전달한다. 이 경우에도 데이터베이스 기록의 정리 기준은 SIEM 수신 확인 시각으로 잡는다.
@B 어떤 방법이든 "옮긴 범위"와 "지운 범위"가 일치해야 한다. 그 일치를 보장하는 장치가 마지막 아카이브 시각이다.

@CASE 아카이브 시각을 한국 시각으로 넣었다
월말 감사 기록 정리 작업에서 SET_LAST_ARCHIVE_TIMESTAMP에 `SYSTIMESTAMP - 90`을 넣었다. 다음 달 감사 대응 중 보관 저장소에 없는 기록이 데이터베이스에서도 지워져 있다는 사실이 드러났다.
SYSTIMESTAMP는 서버 시간대(KST) 값이었고, 통합 감사 기록의 아카이브 시각은 UTC로 해석된다. 의도보다 9시간 늦은 시각까지의 기록이 지워졌고, 그 9시간분은 보관 작업이 아직 옮기지 않은 범위였다.
이후 시각 계산은 `SYS_EXTRACT_UTC(SYSTIMESTAMP)`나 EVENT_TIMESTAMP_UTC 기준으로 바꾸고, 정리 전에 DBA_AUDIT_MGMT_LAST_ARCH_TS의 값을 보관 저장소의 마지막 기록 시각과 비교하는 단계를 넣었다.
@END

@H3 13.6.7  실습에서 일어난 일

@TBL
작업 | 결과
FGA_STD 정리(초기화 전) | ORA-46258
UNIFIED에 INIT_CLEANUP | ORA-46250
FGA_STD에 INIT_CLEANUP | 성공, FGA_LOG$가 SYSTEM → SYSAUX로 이동
FGA_STD 정리(use_last_arch_timestamp => FALSE) | 20건 삭제, 정리 이력에 WAS_FORCED = YES
UNIFIED 아카이브 시각 = 가장 오래된 기록 + 10분 | 그 범위만 삭제, 가장 오래된 기록 시각이 뒤로 이동
CREATE_PURGE_JOB 직후 DROP_PURGE_JOB | ORA-27478(실행 중)
DEINIT_CLEANUP | 초기화 해제, 테이블 위치는 SYSAUX 그대로
SET_AUDIT_TRAIL_LOCATION(FGA_STD, 'SYSTEM') | FGA_LOG$가 SYSTEM으로 복귀
@END

@B 19.3의 DBA_AUDIT_MGMT_CLEAN_EVENTS에는 실습의 FGA 정리만 나타나고 통합 감사 기록 정리는 보이지 않았다. 정리 건수를 확인하려면 정리 전후 건수와 가장 오래된 기록 시각을 함께 남긴다.

@BP 감사 기록 정리 절차
보관 기간을 규정(법규, 내부 지침)으로 먼저 정한다.
기록을 외부로 내보내고 내보낸 범위를 확인한다.
SET_LAST_ARCHIVE_TIMESTAMP를 UTC로 넣고, DBA_AUDIT_MGMT_LAST_ARCH_TS로 다시 확인한다.
CLEAN_AUDIT_TRAIL은 use_last_arch_timestamp => TRUE로만 쓴다. FALSE는 시험 환경에서만 쓴다.
정리 전후 건수를 기록해 둔다.
@END

@H3 13.6.8  정리 설정 조회와 속성

@CODE
SYS@orcl> SELECT parameter_name, parameter_value, audit_trail
  2    FROM dba_audit_mgmt_config_params WHERE audit_trail LIKE 'FGA%';

PARAMETER_NAME               PARAMETER_VALUE  AUDIT_TRAIL
---------------------------- ---------------- --------------------
DB AUDIT TABLESPACE          SYSAUX           FGA AUDIT TRAIL
DB AUDIT CLEAN BATCH SIZE    10000            FGA AUDIT TRAIL
DEFAULT CLEAN UP INTERVAL    12               FGA AUDIT TRAIL
@END

@B 실습 03의 INIT_CLEANUP 직후 결과다. INIT_CLEANUP에 준 12시간이 DEFAULT CLEAN UP INTERVAL로, 삭제 단위 10,000건이 DB AUDIT CLEAN BATCH SIZE로 남았다.
@B FGA_STD만 초기화했으므로 FGA_LOG$만 SYSAUX로 옮겨졌고 AUD$는 SYSTEM에 그대로 있었다.
@B CREATE_PURGE_JOB의 24시간은 DBA_AUDIT_MGMT_CLEANUP_JOBS에 `FREQ=HOURLY;INTERVAL=24`로 나타났다. 주기를 바꿀 때는 작업을 지우지 않고 SET_PURGE_JOB_INTERVAL을 쓴다.

@TBL
SET_AUDIT_TRAIL_PROPERTY 속성 | 대상 유형 | 기본값
OS_FILE_MAX_SIZE | OS, XML | 10000KB. 넘으면 새 파일
OS_FILE_MAX_AGE | OS, XML | 5일. 지나면 새 파일
DB_DELETE_BATCH_SIZE | AUD_STD, FGA_STD(각각 지정) | 10000건
FILE_DELETE_BATCH_SIZE | OS, XML(각각 지정) | 1000개
@END

@B 표는 PL/SQL Packages and Types Reference 기준이다.
@B GET_LAST_ARCHIVE_TIMESTAMP 함수는 READ WRITE로 열린 DB에서 NULL을 돌려준다고 문서에 적혀 있다. 열린 DB의 아카이브 시각은 DBA_AUDIT_MGMT_LAST_ARCH_TS 뷰로 확인한다.

@H2 13.7  syslog로 감사 기록 보내기

@H3 13.7.1  왜 syslog인가

@B 데이터베이스 안의 감사 기록은 충분한 권한을 가진 DBA가 지우거나 감사를 끌 수 있다. 감사 대상인 DBA 자신의 행위를 데이터베이스 안에만 남기면 증거력이 약하다.
@B syslog는 운영체제의 표준 로깅 장치다. 기록을 OS 로그 파일로 보내고, rsyslog가 다시 원격 로그 서버로 전달하게 하면 DBA 권한만으로는 지울 수 없는 곳에 기록이 남는다.
@B 경고 로그(alert log)는 별도 파일이며 이 기능의 전송 대상이 아니다. 경고 로그를 중앙에서 모으려면 로그 수집 에이전트를 따로 쓴다.

@H3 13.7.2  facility와 priority

@P syslog 메시지는 facility(어디서 온 메시지인가)와 priority(얼마나 중요한가) 두 값으로 분류된다. rsyslog는 이 조합을 보고 메시지를 어느 파일로 보낼지 정한다.

@TBL
facility | 용도
KERN, USER, MAIL, DAEMON, AUTH, SYSLOG, LPR, NEWS, UUCP, CRON | 운영체제와 표준 서비스가 쓰는 분류
LOCAL0 ~ LOCAL7 | 사용자 정의. 애플리케이션 로그를 따로 받을 때 씀
@END

@TBL
priority | 의미(높은 순)
EMERG | 시스템을 쓸 수 없음
ALERT | 즉시 조치 필요
CRIT | 치명적 상태
ERR | 오류
WARNING | 경고
NOTICE | 정상이지만 주목할 사건
INFO | 정보
DEBUG | 디버깅
@END

@B rsyslog 규칙의 `local1.warning`은 local1 facility의 warning 이상 메시지를, `local1.*`은 local1의 모든 메시지를 뜻한다.
@B 다른 애플리케이션이 쓰지 않는 LOCAL 번호를 골라 오라클 감사 전용으로 쓰는 것이 일반적이다.

@H3 13.7.3  AUDIT_SYSLOG_LEVEL

@B 전통적 감사의 SYS 감사 기록과 OS 감사 기록을 syslog로 보낸다.
@B AUDIT_SYS_OPERATIONS = TRUE이면 SYS 감사 기록이 syslog로 간다. AUDIT_TRAIL = OS이면 표준 감사 기록도 syslog로 간다. 두 조건은 서로 독립적이다.
@B 값은 'facility.priority' 형식이다. facility로 USER, LOCAL0~7, SYSLOG, DAEMON, KERN, MAIL, AUTH, LPR, NEWS, UUCP, CRON을 쓸 수 있다.
@B 정적 파라미터다. SCOPE=SPFILE로 바꾸고 재기동해야 적용된다.
@B 순수 통합 감사로 전환한 데이터베이스에서는 이 파라미터가 아무 효과가 없다.
@B syslog 메시지는 512바이트에서 잘릴 수 있고, 잘린 조각이 다시 합쳐지지 않는다. 긴 SQL 문은 일부만 남는다는 점을 감안한다.

@CODE
SYS@orcl> ALTER SYSTEM SET audit_syslog_level = 'local1.warning' SCOPE = SPFILE;
SYS@orcl> SHUTDOWN IMMEDIATE
SYS@orcl> STARTUP

[root@oel7v9 ~]# vi /etc/rsyslog.conf
local1.*                                                /var/log/oracle_db.log
[root@oel7v9 ~]# systemctl restart rsyslog
@END

@B 실습에서 SCOPE 없이 `ALTER SYSTEM SET audit_syslog_level = ...`을 실행하자 ORA-02095(지정한 초기화 파라미터를 수정할 수 없음)가 났다. SCOPE=SPFILE로 넣고 재기동해야 한다.
@B 재기동 후 SYS로 실행한 조회·CREATE TABLE·DROP TABLE이 /var/log/oracle_db.log에 'Oracle Audit' 항목으로 남았다. ACTION에 SQL 문, PRIVILEGE에 SYSDBA, CLIENT USER에 OS 사용자가 들어간다.
@B 같은 시각 이후 adump에는 새 .aud 파일이 생기지 않았다. SYS 감사 기록의 행선지가 .aud 파일에서 syslog로 바뀐 것이다.
@B SQL*Plus의 SHOW PARAMETER가 내부적으로 실행하는 긴 문장은 LENGTH 494와 317 두 항목으로 나뉘어 기록됐다. 긴 문장은 여러 항목으로 쪼개지며, 수집 도구가 이를 다시 이어 붙여 주지 않는다.
@B OEL7에서는 메시지 앞에 `journal:`이 붙는다. 데이터베이스가 보낸 syslog 메시지가 systemd-journald를 거쳐 rsyslog로 전달되기 때문이다.

@CODE
Oct 27 20:16:12 oel7v9 journal: Oracle Audit[19644]: LENGTH : '298' ACTION :[38] 'CREATE TABLE scott.sec13_t (id NUMBER)'
  DATABASE USER:[1] '/' PRIVILEGE :[6] 'SYSDBA' CLIENT USER:[6] 'oracle' CLIENT TERMINAL:[5] 'pts/0' STATUS:[1] '0' ...
@END

@TBL
'Oracle Audit' 항목 필드 | 내용
ACTION | 실행한 SQL 문(길이 표시 후 본문)
DATABASE USER | 데이터베이스 사용자. OS 인증 SYSDBA는 '/'
PRIVILEGE | SYSDBA, SYSOPER 등 접속 권한
CLIENT USER, CLIENT TERMINAL, USERHOST | OS 사용자, 단말, 클라이언트 호스트
STATUS | 0이면 성공, 그 밖에는 오류 번호
DBID, SESSIONID | 데이터베이스와 세션 식별
ACTION NUMBER | 문장 종류 번호(3 = SELECT, 1 = CREATE TABLE, 12 = DROP TABLE 등)
@END

@B 실습의 syslog 파일에는 각 항목이 한 줄로 길게 들어간다. 수집 도구에서 필드 이름 기준으로 나눠 저장하면 검색이 쉬워진다.

@H3 13.7.4  원격 로그 서버로 전달

@B 같은 서버의 /var/log에만 남기면 root 권한을 가진 사람은 여전히 지울 수 있다. rsyslog가 받은 메시지를 원격 로그 서버로 다시 보내면 데이터베이스 서버의 관리자와 분리된다.
@B rsyslog 규칙에서 `local1.* @@로그서버:514`는 TCP, `@로그서버:514`는 UDP로 보낸다. 감사 기록은 유실되면 안 되므로 TCP와 큐 설정을 함께 쓴다.
@B 원격 서버에서는 호스트별, facility별로 파일을 나누고 보관 기간을 정한다. 데이터베이스 쪽 감사 정리와 별개로 관리된다.

@CODE
# /etc/rsyslog.conf (데이터베이스 서버)
local1.*                                                /var/log/oracle_db.log
local1.*                                                @@logserver.example.com:514
@END

@H3 13.7.5  설정과 원복 순서

@B 설정: rsyslog 규칙 추가와 재시작 → 데이터베이스 파라미터를 SPFILE에 기록 → 재기동 → SHOW PARAMETER로 확인 → SYS 작업 후 로그 파일 확인.
@B 원복: 파라미터 RESET(SCOPE 기본값은 BOTH라 SPFILE 항목까지 지워진다) → 재기동 → rsyslog 설정을 백업본으로 복구하고 재시작.
@B 실습에서 SCOPE 없이 RESET한 뒤 SCOPE=SPFILE로 다시 RESET하자 ORA-32010(SPFILE에서 지울 항목이 없음)이 났다. 첫 RESET이 이미 SPFILE 항목까지 지웠기 때문이다.
@B 재기동 전에 `CREATE PFILE ... FROM SPFILE`로 파라미터 파일을 백업해 두면 설정을 잘못 넣어 기동이 안 될 때 되돌릴 수 있다.

@H3 13.7.6  UNIFIED_AUDIT_SYSTEMLOG

@B 통합 감사 기록의 핵심 필드를 syslog(UNIX) 또는 Windows 이벤트 뷰어로 보낸다.
@B 전체 기록이 아니라 기록을 식별하는 일부 필드만 보낸다. syslog 항목 크기 제한(보통 1024바이트)을 넘지 않게 하려는 것이며, 상세 내용은 이 필드로 UNIFIED_AUDIT_TRAIL에서 찾는다.
@B UNIX에서 facility는 USER와 LOCAL0~7만 쓸 수 있다. 정적 파라미터이며 CDB에서는 PDB마다 지정한다.
@B UNIFIED_AUDIT_COMMON_SYSTEMLOG는 CDB 수준에서 공통 감사 정책의 기록을 한 곳으로 모은다.
@B 실습에서는 혼합 모드(19.3)에서 UNIFIED_AUDIT_SYSTEMLOG = 'local1.notice'를 함께 설정했다. 재기동 후 SCOTT의 로그인 실패가 'Oracle Unified Audit' 항목으로 syslog에 남았다. 혼합 모드에서도 통합 감사 정책의 기록이 이 파라미터로 전달된다.
@B 전달된 내용은 TYPE, DBID, SESID, ENTRYID, STMTID, DBUSER, ACTION, RETCODE, SCHEMA, OBJNAME 같은 식별 필드다. 상세 내용은 이 값으로 UNIFIED_AUDIT_TRAIL에서 찾는다.

@CODE
Oct 27 20:16:13 oel7v9 journal: Oracle Unified Audit[19727]: LENGTH: '161' TYPE:"4" DBID:"1767674490"
  SESID:"1157323485" CLIENTID:"" ENTRYID:"1" STMTID:"1" DBUSER:"SCOTT" CURUSER:"SCOTT" ACTION:"100" RETCODE:"1017" ...
@END

@TBL
'Oracle Unified Audit' 필드 | UNIFIED_AUDIT_TRAIL에서 찾을 컬럼
DBID | DBID
SESID | SESSIONID
ENTRYID, STMTID | ENTRY_ID, STATEMENT_ID
DBUSER, CURUSER | DBUSERNAME, CURRENT_USER
ACTION | 동작 번호(100 = LOGON)
RETCODE | RETURN_CODE
SCHEMA, OBJNAME | OBJECT_SCHEMA, OBJECT_NAME
@END

@B syslog에서 이상 징후를 발견하면 SESID와 ENTRYID로 UNIFIED_AUDIT_TRAIL의 원래 기록을 찾아 SQL 문, 호스트, 프로그램 같은 상세를 확인한다.

@TBL
항목 | AUDIT_SYSLOG_LEVEL | UNIFIED_AUDIT_SYSTEMLOG
대상 기록 | SYS 감사, AUDIT_TRAIL=OS인 표준 감사 | 통합 감사 기록
보내는 내용 | 기록 전체(512바이트 제한) | 식별용 핵심 필드
순수 통합 감사에서 | 효과 없음 | 동작
CDB 범위 | CDB 전체 | PDB마다
@END

@H2 13.8  감사 기록 보호와 운영

@H3 13.8.1  권한 분리

@B 감사 정책 관리(AUDIT_ADMIN), 감사 기록 조회(AUDIT_VIEWER), 데이터베이스 운영(DBA)을 서로 다른 사람에게 준다.
@B SYS 작업은 데이터베이스 안의 권한으로 감출 수 없는 곳(syslog, 원격 로그 서버)에 남긴다.
@B AUDIT_FILE_DEST와 /var/log의 감사 파일은 oracle OS 계정이 아닌 root 소유 경로로 수집해 DBA가 지울 수 없게 한다.
@B DBMS_AUDIT_MGMT 실행은 항상 감사된다. 다만 DBMS_SCHEDULER 작업 안에서 부른 호출은 순수 통합 감사에서만 기록되고 혼합 모드에서는 남지 않는다고 문서에 적혀 있다. 혼합 모드의 정리 작업 이력은 정리 전후 건수로 따로 남긴다.

@H3 13.8.2  혼합 모드 운영 권장

@B 혼합 모드에서는 같은 사건이 전통적 감사와 통합 감사 양쪽에 기록될 수 있다. 새로 만드는 감사는 통합 감사 정책으로 만들고, 전통적 AUDIT 문은 늘리지 않는다.
@B 기존 AUDIT 문 설정은 DBA_STMT_AUDIT_OPTS, DBA_PRIV_AUDIT_OPTS, DBA_OBJ_AUDIT_OPTS로 확인해 통합 감사 정책으로 옮길 목록을 만든다.
@B 순수 통합 감사로 전환하기 전에 SYS 감사, FGA, syslog 수집이 전환 후 어디로 가는지 표로 정리해 둔다. 이 장의 13.2.3 표가 그 출발점이다.

@H3 13.8.3  운영 시 주의점

@B 감사 기록 테이블스페이스(SYSAUX 또는 지정한 공간)의 사용량을 감시한다. 공간이 부족해 감사 기록을 쓰지 못하면 OS 파일로 넘치거나 접속이 실패할 수 있다.
@B AUDIT_FILE_DEST의 .aud 파일은 데이터베이스가 지우지 않는다. 정리 작업(AUDIT_TRAIL_OS)이나 OS 스케줄러로 관리한다.
@B 정리 작업이 실제로 지우고 있는지 확인한다. DBA_AUDIT_MGMT_CLEAN_EVENTS에 나타나지 않는 정리도 있으므로(13.6.7) 가장 오래된 기록의 시각이 앞으로 움직이는지를 함께 본다. 아카이브 시각이 갱신되지 않아 매번 0건을 지우는 경우가 흔하다.
@B syslog 설정을 바꾼 뒤에는 rsyslog를 재시작하고, 데이터베이스 쪽 파라미터는 재기동 후 SHOW PARAMETER로 확인한다. 두 쪽 중 하나만 바뀌면 기록이 /var/log/messages로 섞이거나 사라진다.
@B 순수 통합 감사로 전환할 계획이라면 AUDIT_SYSLOG_LEVEL 기반 수집이 멈춘다는 점을 미리 반영해 UNIFIED_AUDIT_SYSTEMLOG로 바꿀 준비를 한다.

@H3 13.8.4  기록 양 가늠하기

@B 감사 정책을 켜기 전에 하루 기록 건수를 추정한다. 대상 문장의 실행 횟수는 V$SQL이나 AWR의 실행 통계로 가늠할 수 있다.
@B 켠 뒤에는 정책별 하루 건수와 AUD$UNIFIED 세그먼트 크기를 일주일 정도 기록해 증가 추세를 본다. 파티션 간격과 보관 기간, 정리 주기는 이 추세로 정한다.
@B 기록 양이 예상보다 많으면 정책 조건(WHEN, EXCEPT)으로 범위를 좁힌다. 기록을 줄이려고 정리 주기를 앞당기는 것은 보관 의무와 충돌할 수 있다.

@H3 13.8.5  19c에서 달라진 감사 기능

@TBL
변경 | 내용 | 운영에 미치는 영향
최상위 문장만 감사 | CREATE AUDIT POLICY ... ONLY TOPLEVEL | PL/SQL 안에서 실행된 간접 SQL을 빼고 사용자가 직접 낸 문장만 기록
EVENT_TIMESTAMP_UTC | AUD$UNIFIED 재설계와 함께 추가된 컬럼 | WHERE 절에 쓰면 파티션 제거로 조회가 빨라짐
UNIFIED_AUDIT_COMMON_SYSTEMLOG | 19.9부터, CDB 수준 파라미터 | 공통 정책 기록을 한 syslog 대상으로 모음. UNIX 전용
PDB_GUID 필드 | syslog·Windows 이벤트 뷰어 항목에 추가 | 어느 PDB의 기록인지 구분
@END

@B 표는 Security Guide 19c 변경 사항 기준이다. 실습에서는 EVENT_TIMESTAMP_UTC만 확인했다.
@B ONLY TOPLEVEL은 업무 로직을 PL/SQL 프로시저에 모아 둔 애플리케이션에서 쓸모가 있다. 프로시저 호출 문장만 남고 그 안에서 실행된 문장은 기록되지 않아, 사용자가 직접 낸 행위를 추적한다.

@NOTE 원본 실습 자료와 다른 점
원본은 AUDIT_TRAIL을 OS로 바꾼 뒤 AUDIT_SYSLOG_LEVEL을 설정했다. SYS 감사 기록만 syslog로 보내려면 AUDIT_TRAIL을 바꿀 필요가 없다. AUDIT_TRAIL = OS는 표준 감사 기록까지 syslog로 보낼 때 필요하다.
원본은 이 기능을 경고 로그(alert log) 전송으로 소개했다. AUDIT_SYSLOG_LEVEL이 보내는 것은 감사 기록이다.
@END

@H2 13.9  감사 기록 관리 데이터 딕셔너리 뷰

@TBL
뷰 | 내용
V$OPTION | Unified Auditing 값으로 감사 모드 판별
UNIFIED_AUDIT_TRAIL | 통합 감사 기록
AUDIT_UNIFIED_POLICIES | 통합 감사 정책 정의
AUDIT_UNIFIED_ENABLED_POLICIES | 켜진 정책과 대상
DBA_AUDIT_TRAIL | SYS.AUD$의 표준 감사 기록
DBA_FGA_AUDIT_TRAIL | SYS.FGA_LOG$의 FGA 기록
DBA_AUDIT_MGMT_CONFIG_PARAMS | 정리 기반 설정(테이블스페이스, 정리 간격 등)
DBA_AUDIT_MGMT_LAST_ARCH_TS | 유형별 마지막 아카이브 시각
DBA_AUDIT_MGMT_CLEANUP_JOBS | 예약된 정리 작업
DBA_AUDIT_MGMT_CLEAN_EVENTS | 정리 이력
@END

@H2 13.10  요약

@B 19c 기본은 혼합 감사 모드다. V$OPTION의 Unified Auditing이 FALSE면 혼합 모드, TRUE면 순수 통합 감사이며 전환은 실행 파일 재링크(uniaud_on)로 한다.
@B 혼합 모드에서는 통합 감사 기록(AUDSYS.AUD$UNIFIED)과 전통적 감사 기록(AUD$, FGA_LOG$, adump 파일)이 함께 존재한다.
@B 기본 정책 ORA_SECURECONFIG, ORA_LOGON_FAILURES가 보안 관리 작업과 로그인 실패를 기록한다. 켜진 정책은 NOAUDIT 후에 DROP한다.
@B UNIFIED_AUDIT_TRAIL은 AUDIT_TYPE, ACTION_NAME, RETURN_CODE, UNIFIED_AUDIT_POLICIES로 찾고 시각 범위를 함께 준다.
@B DBMS_AUDIT_MGMT 정리는 아카이브 시각(DB 기록은 UTC) 지정 후 CLEAN_AUDIT_TRAIL(use_last_arch_timestamp => TRUE)로 한다. 통합 감사 기록은 초기화가 필요 없고 AUD$·FGA_LOG$는 INIT_CLEANUP이 필요하다.
@B AUDIT_SYSLOG_LEVEL은 SYS 감사와 OS 표준 감사 기록을 syslog로 보내는 정적 파라미터이며 순수 통합 감사에서는 효과가 없다. UNIFIED_AUDIT_SYSTEMLOG는 통합 감사 기록의 핵심 필드를 보낸다.
@B 통합 감사 기록 테이블은 SYS도 직접 DELETE·TRUNCATE할 수 없고(ORA-46385), 그 시도도 기록된다.
@B 감사 기록은 감사 대상자가 지울 수 없는 곳으로 보내고, 감사 관리 권한을 DBA와 분리한다.

@H2 13.11  퀴즈

@QUIZ 문제 1
V$OPTION에서 Unified Auditing 값이 FALSE인 19c 데이터베이스에 대한 설명으로 옳은 것은?
① 감사가 전혀 동작하지 않는다  ② 통합 감사 정책은 동작하지 않는다  ③ 전통적 감사와 통합 감사가 함께 동작한다  ④ AUDIT_TRAIL 파라미터가 무시된다
정답 ③. FALSE는 혼합 모드다. 기본 통합 감사 정책이 켜져 있고 AUDIT_TRAIL 같은 전통적 감사 파라미터도 그대로 동작한다.
@END

@QUIZ 문제 2
켜져 있는 통합 감사 정책을 DROP AUDIT POLICY로 지우려 했다. 결과는?
① 정책과 기록이 모두 지워진다  ② 오류가 나고 지워지지 않는다  ③ 자동으로 NOAUDIT된 뒤 지워진다  ④ 다음 재기동 때 지워진다
정답 ②. 켜진 정책은 지울 수 없다. NOAUDIT POLICY로 먼저 끈 다음 DROP한다.
@END

@QUIZ 문제 3
DBMS_AUDIT_MGMT.INIT_CLEANUP이 필요하지 않은 감사 기록 유형은?
① AUDIT_TRAIL_AUD_STD  ② AUDIT_TRAIL_FGA_STD  ③ AUDIT_TRAIL_DB_STD  ④ AUDIT_TRAIL_UNIFIED
정답 ④. 통합 감사 기록은 처음부터 정리할 수 있는 상태이며 INIT_CLEANUP을 부르면 ORA-46250이 난다. AUD$·FGA_LOG$ 계열은 초기화가 필요하다.
@END

@QUIZ 문제 4
통합 감사 기록에 대해 SET_LAST_ARCHIVE_TIMESTAMP를 지정할 때 시각 기준은?
① UTC  ② 서버 현지 시각  ③ 클라이언트 시각  ④ 데이터베이스 시간대
정답 ①. AUD_STD, FGA_STD, UNIFIED 같은 데이터베이스 기록은 UTC로 지정한다. OS·XML 파일만 서버 현지 시각을 쓴다.
@END

@QUIZ 문제 5
AUDIT_SYSLOG_LEVEL = 'local1.warning'을 설정했을 때 syslog로 가는 기록은?
① AUDIT_SYS_OPERATIONS가 TRUE일 때의 SYS 감사 기록  ② 경고 로그(alert log)의 모든 메시지  ③ 모든 통합 감사 기록  ④ FGA_LOG$의 기록
정답 ①. AUDIT_SYSLOG_LEVEL은 SYS 감사 기록과 AUDIT_TRAIL=OS인 표준 감사 기록을 보낸다. 경고 로그 내용은 보내지 않으며, 통합 감사 기록은 UNIFIED_AUDIT_SYSTEMLOG의 몫이다.
@END

@QUIZ 문제 6
CLEAN_AUDIT_TRAIL을 use_last_arch_timestamp => TRUE로 실행했는데 기록이 하나도 지워지지 않았다. 가장 먼저 확인할 것은?
① AUDIT_SYSLOG_LEVEL 값  ② AUDIT_TRAIL이 OS인지  ③ 마지막 아카이브 시각이 설정·갱신되었는지  ④ AUDIT_VIEWER 역할 보유 여부
정답 ③. TRUE일 때는 마지막 아카이브 시각 이전 기록만 지운다. 시각이 없거나 오래된 값으로 남아 있으면 지울 대상이 없다. DBA_AUDIT_MGMT_LAST_ARCH_TS로 확인한다.
@END

@H2 13.12  실습 개요

@P 실습은 oel7v9 서버의 orcl 데이터베이스(19.3, non-CDB, 혼합 감사 모드)에서 진행한다. 03의 FGA 기록 정리는 12장 실습이 남긴 기록을 대상으로 하며, 통합 감사 기록은 가장 오래된 10분 범위만 지운다. 04와 05는 데이터베이스를 한 번씩 재기동하고 root로 /etc/rsyslog.conf를 고친다. 05에서 모든 변경을 되돌린다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
13장_실습_01_감사모드와기본정책 | V$OPTION, 감사 파라미터, 기본 정책, AUD$UNIFIED 파티션, 로그인 실패(ORA-01017) 기록 | 13.2, 13.3.1, 13.4
13장_실습_02_통합감사정책과기록보호 | 정책 생성·활성화, 정책 기록 조회, ORA-46361, AUD$UNIFIED 직접 삭제 시 ORA-46385, 감사 역할 | 13.3, 13.5
13장_실습_03_DBMS_AUDIT_MGMT정리 | ORA-46258·ORA-46250, INIT_CLEANUP과 테이블 이동, 아카이브 시각(UTC) 이전 범위 정리, 정리 이력, 실행 중 작업 삭제 ORA-27478 | 13.6
13장_실습_04_syslog전송설정 | rsyslog 규칙, ORA-02095, 재기동, SYS 감사의 syslog 기록, UNIFIED_AUDIT_SYSTEMLOG 기록, 긴 기록의 분할 | 13.7
13장_실습_05_원복과확인 | RESET의 범위와 ORA-32010, rsyslog 원복, 남은 정리 작업 삭제, SET_AUDIT_TRAIL_LOCATION으로 위치 원복 | 13.6, 13.7
@END
