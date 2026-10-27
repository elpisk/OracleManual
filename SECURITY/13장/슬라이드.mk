@TITLE Oracle Database 19c Security 과정|감사 기록 관리와 syslog 전송|어디에 쌓이고, 어떻게 찾고, 언제 지우고, 어디로 내보내는가|제13장

@PLAIN 학습 목표
- 혼합 모드와 순수 통합 감사를 구분한다
- 감사 기록별 저장 위치와 조회 뷰를 구분한다
- 기본 정책의 기록을 UNIFIED_AUDIT_TRAIL에서 찾는다
- DBMS_AUDIT_MGMT로 아카이브 이전 기록만 정리한다
- AUDIT_SYSLOG_LEVEL로 SYS 감사를 syslog로 보낸다
- UNIFIED_AUDIT_SYSTEMLOG와의 차이를 설명한다

@PLAIN Agenda
- 13.2 감사 모드  /  13.3 통합 감사 정책
- 13.4 통합 감사 기록 조회
- 13.5 감사 기록의 저장
- 13.6 DBMS_AUDIT_MGMT로 정리
- 13.7 syslog로 감사 기록 보내기
- 13.8 감사 기록 보호와 운영  /  13.9 딕셔너리 뷰

@SEC 13.2|감사 모드
- 19c 기본은 혼합 모드
- V$OPTION으로 판별
- 전환은 실행 파일 재링크

@SLIDE 혼합 모드와 순수 통합 감사|두 감사 장치가 함께 돈다
- 혼합: 전통적 감사 + 통합 감사 정책
- 기존 감사 파라미터가 그대로 동작
- 순수 통합: 전통적 감사 꺼짐, 기록 일원화
- V$OPTION Unified Auditing으로 판별
@NOTE 통합 감사는 12c에서 도입되어 여러 구성 요소의 감사 기록을 한 곳에 모읍니다. 그런데 19c를 새로 설치해도 바로 순수 통합 감사가 되지는 않고, 기존 감사와 통합 감사가 함께 도는 혼합 모드로 시작합니다. 실습 DB orcl도 V$OPTION에서 Unified Auditing이 FALSE로 나오는 혼합 모드입니다. 혼합 모드에서는 AUDIT_TRAIL, AUDIT_SYS_OPERATIONS, AUDIT_SYSLOG_LEVEL 같은 기존 파라미터가 모두 살아 있다는 점이 이 장 뒷부분의 syslog 실습과 연결됩니다.

@SLIDE 순수 통합 감사로 전환|파라미터가 아니라 재링크
- DB를 내리고 uniaud_on으로 재링크
- 같은 ORACLE_HOME의 모든 DB가 전환
- uniaud_off로 되돌릴 수 있다
- 실습 서버는 홈을 공유해 전환하지 않는다
@NOTE 순수 통합 감사는 초기화 파라미터 하나로 켜지는 기능이 아닙니다. oracle 실행 파일을 uniaud_on 옵션으로 다시 링크해야 하기 때문에, 같은 ORACLE_HOME을 쓰는 데이터베이스가 모두 함께 바뀝니다. 실습 서버에는 orcl 외에도 여러 데이터베이스가 같은 홈을 쓰고 있어 이 장에서는 전환을 직접 해 보지 않습니다. 운영에서 전환할 때는 Upgrade Guide의 통합 감사 이전 절차를 따르고, 기존 감사 기록을 어떻게 보관할지 먼저 정해 둡니다.

@SLIDE 모드별 기록 위치|같은 사건이 두 곳에 남을 수 있다
- 통합 정책 기록: AUDSYS.AUD$UNIFIED
- 표준 감사: AUDIT_TRAIL에 따라 AUD$ 또는 파일
- FGA: FGA_LOG$ 또는 XML(audit_trail 인자)
- SYS·필수 감사: adump .aud 또는 syslog
- 순수 통합에서는 전부 통합 감사 기록
@NOTE 혼합 모드에서 가장 헷갈리는 부분이 기록 위치입니다. 통합 감사 정책이 만든 기록은 AUDSYS 스키마의 통합 감사 테이블에, 전통적 감사 기록은 AUDIT_TRAIL 값에 따라 SYS.AUD$나 OS 파일에 남습니다. 12장에서 본 FGA 기록은 audit_trail 인자에 따라 FGA_LOG$나 XML 파일로 갑니다. SYS 감사와 기동·종료 같은 필수 감사는 adump 디렉터리의 .aud 파일에 쌓이는데, AUDIT_SYSLOG_LEVEL을 설정하면 syslog로 방향이 바뀝니다. 기록을 볼 때 어느 장치가 남긴 것인지부터 구분해야 합니다.

@SEC 13.3|통합 감사 정책
- 기본 정책 두 개
- 정책 생성과 활성화의 최소한
- 감사 관리 역할

@SLIDE 기본 정책|설치 직후부터 켜져 있다
- ORA_SECURECONFIG: 보안 관련 관리 작업
- ORA_LOGON_FAILURES: 로그인 실패
- 그 밖의 ORA_ 정책은 정의만 있음
- AUDIT_UNIFIED_ENABLED_POLICIES로 확인
@NOTE 새로 만든 19c 데이터베이스에는 두 개의 통합 감사 정책이 모든 사용자에 대해 켜져 있습니다. ORA_SECURECONFIG는 사용자와 권한 변경 같은 보안 관리 작업을, ORA_LOGON_FAILURES는 실패한 로그인을 기록합니다. 그래서 따로 감사를 설정하지 않은 데이터베이스에서도 비밀번호 대입 시도 정도는 추적할 수 있습니다. 이 밖에도 ORA_로 시작하는 정책이 여럿 정의되어 있지만 꺼져 있으니, 필요하면 AUDIT POLICY로 켜서 씁니다.

@SLIDE 로그인 실패 추적|ORA_LOGON_FAILURES의 기록
- 틀린 비밀번호 → ORA-01017
- ACTION_NAME = 'LOGON', RETURN_CODE = 1017
- USERHOST, CLIENT_PROGRAM_NAME로 출처 확인
- 기본 정책만으로 1045, 28150 등도 기록
@NOTE 실습 1에서 SCOTT의 비밀번호를 일부러 틀리게 입력하고 통합 감사 기록을 조회했습니다. ACTION_NAME이 LOGON이고 RETURN_CODE가 1017인 기록이 ORA_LOGON_FAILURES 정책 이름과 함께 남아 있었습니다. 같은 시간대에 다른 실습에서 생긴 1045, 28150 같은 실패도 함께 보였는데, ORA- 번호가 RETURN_CODE에 그대로 들어가므로 실패 원인별로 집계할 수 있습니다. 접속 호스트와 프로그램 이름까지 남아 출처를 좁히는 데 충분합니다.

@SLIDE 정책 생성과 활성화|최소한의 흐름
- CREATE AUDIT POLICY ... ACTIONS
- AUDIT POLICY ... BY 사용자
- 켜진 정책은 DROP 불가 → NOAUDIT 먼저
- 실습: 켜진 정책 DROP → ORA-46361
@NOTE 통합 감사 정책은 CREATE AUDIT POLICY로 정의하고 AUDIT POLICY로 켭니다. 정책은 그 뒤에 새로 연결한 세션부터 적용되므로 실습에서도 CONNECT로 새 세션을 열어 작업했습니다. 0건 DELETE를 하고 ROLLBACK했는데도 DELETE 문 실행이 기록된 점을 눈여겨보십시오. 켜진 정책을 바로 지우려 하면 ORA-46361로 거부되고, NOAUDIT으로 끈 다음에야 지울 수 있습니다. 감사가 실수로 사라지는 것을 막는 안전장치입니다.

@SLIDE 감사 기록은 직접 지울 수 없다|INSERT만 허용되는 테이블
- AUD$UNIFIED에 DELETE·TRUNCATE 시도
- SYS도 ORA-46385로 거부
- 시도 자체가 감사 기록으로 남는다
- 정리는 DBMS_AUDIT_MGMT로만
@NOTE 통합 감사 기록 테이블 AUD$UNIFIED는 INSERT만 허용됩니다. 실습 2에서 SYS로 DELETE와 TRUNCATE를 시도하자 둘 다 ORA-46385로 거부됐습니다. 더 흥미로운 것은 그 시도 자체가 RETURN_CODE 46385인 감사 기록으로 남았다는 점입니다. 기록을 지우려 한 행위가 곧 증거가 되는 구조입니다. 통합 감사 기록을 정리하는 유일한 공식 경로는 DBMS_AUDIT_MGMT이며, 그 권한은 AUDIT_ADMIN 역할에 묶여 있습니다.

@SLIDE 감사 관리 역할|관리와 조회를 나눈다
- AUDIT_ADMIN: 정책 관리, 기록 정리
- AUDIT_VIEWER: 기록 조회만
- 업무 DBA와 감사 관리자를 분리
- 감사 대상자가 기록을 못 지우게
@NOTE 통합 감사에는 두 개의 전용 역할이 있습니다. AUDIT_ADMIN은 감사 정책을 만들고 켜고 끄는 것은 물론 감사 기록을 정리할 수 있고, AUDIT_VIEWER는 기록을 보기만 합니다. 업무 DBA에게 AUDIT_ADMIN을 주면 자신이 한 작업의 기록을 지울 수 있게 되므로 감사의 의미가 사라집니다. 감사 관리 계정을 따로 만들어 AUDIT_ADMIN을 주고, 감사 담당자에게는 AUDIT_VIEWER만 주는 구성이 기본입니다.

@SEC 13.4|통합 감사 기록 조회
- 주요 컬럼
- 시각 범위와 함께 조회
- 즉시 기록, FLUSH 불필요

@SLIDE 주요 컬럼|무엇으로 찾는가
- EVENT_TIMESTAMP, DBUSERNAME, USERHOST
- AUDIT_TYPE: Standard, FineGrainedAudit 등
- UNIFIED_AUDIT_POLICIES: 기록을 만든 정책
- ACTION_NAME, OBJECT_NAME, RETURN_CODE
- SQL_TEXT, SQL_BINDS
@NOTE UNIFIED_AUDIT_TRAIL은 컬럼이 백 개 가까이 되지만 자주 쓰는 것은 몇 개로 정해져 있습니다. 언제, 누가, 어디서 접속했는지는 EVENT_TIMESTAMP, DBUSERNAME, USERHOST로 봅니다. AUDIT_TYPE은 기록을 만든 구성 요소를 알려 주고, UNIFIED_AUDIT_POLICIES는 어떤 정책 때문에 기록됐는지를 알려 줍니다. RETURN_CODE가 0이 아니면 실패한 시도이며 그 값이 ORA- 오류 번호입니다. 조회할 때는 항상 시각 범위를 함께 주는 습관을 들이는 것이 좋습니다.

@SLIDE 시각 범위와 파티션|범위 없는 조회는 전체를 읽는다
- AUD$UNIFIED는 시각 기준 인터벌 파티션
- 기본 간격 1개월
- 시각 조건을 주면 필요한 파티션만 읽음
- 12.2부터 즉시 기록, FLUSH 디프리케이트
@NOTE 통합 감사 테이블은 시각을 기준으로 한 달마다 새 파티션이 생기는 구조입니다. 그래서 시각 범위를 조건으로 주면 필요한 파티션만 읽고, 범위 없이 조회하면 몇 년치 기록을 모두 훑게 됩니다. 기록이 많은 시스템이라면 ALTER_PARTITION_INTERVAL로 간격을 줄여 둡니다. 예전 자료에는 감사 기록이 메모리 큐에 모였다가 쓰이므로 FLUSH_UNIFIED_AUDIT_TRAIL을 불러야 한다는 설명이 있는데, 12.2부터는 바로 테이블에 기록되어 그 절차가 필요 없습니다.

@SLIDE 사례: 새벽마다 잠기는 계정|기본 정책이 원인을 알려 준다
- 매일 아침 계정 잠김 신고
- LOGON 실패 1017이 새벽 2시에 몰림
- USERHOST·프로그램이 배치 서버를 가리킴
- 비밀번호 변경 미반영 스크립트가 원인
@NOTE 이 사례는 따로 감사를 설정하지 않은 데이터베이스에서도 기본 정책만으로 원인을 찾은 경우입니다. 프로파일의 로그인 실패 횟수 제한에 걸려 계정이 잠겼는데, 사용자 본인은 비밀번호를 틀린 적이 없었습니다. 통합 감사 기록의 로그인 실패를 시각순으로 보니 새벽 배치 시간에 몰려 있었고, 접속 호스트와 프로그램 이름이 오래된 배치 스크립트를 가리켰습니다. 이후 스크립트를 1장의 Secure External Password Store로 바꿔 같은 문제가 다시 생기지 않게 했습니다.

@SEC 13.5|감사 기록의 저장
- 통합 감사 기록은 AUDSYS, SYSAUX
- 전통적 감사는 AUD$, FGA_LOG$, adump

@SLIDE 통합 감사 기록의 저장|위치와 넘침 파일
- AUDSYS.AUD$UNIFIED, 기본 SYSAUX
- SET_AUDIT_TRAIL_LOCATION으로 전용 공간
- 쓸 수 없는 상태면 OS 파일로 넘침
- 열린 뒤 LOAD_UNIFIED_AUDIT_FILES
@NOTE 통합 감사 기록은 AUDSYS 스키마의 테이블에 쌓이고 기본 위치는 SYSAUX입니다. 매뉴얼은 감사 기록용 테이블스페이스를 따로 두기를 권하는데, SYSAUX가 다른 구성 요소와 공간을 나눠 쓰기 때문입니다. 마운트 상태나 읽기 전용 상태처럼 테이블에 쓸 수 없을 때 생긴 기록은 ORACLE_BASE 아래 audit 디렉터리의 파일로 넘쳐 쓰입니다. 데이터베이스가 열린 뒤 LOAD_UNIFIED_AUDIT_FILES로 테이블에 옮겨야 조회할 수 있습니다.

@SLIDE 전통적 감사 기록|DB 테이블과 adump 파일
- SYS.AUD$ → DBA_AUDIT_TRAIL
- SYS.FGA_LOG$ → DBA_FGA_AUDIT_TRAIL
- adump: SYS 감사·필수 감사 .aud, XML
- adump 파일은 DB가 지우지 않는다
@NOTE 혼합 모드에서는 전통적 감사 기록도 계속 쌓입니다. 표준 감사 기록은 SYS.AUD$에, FGA 기록은 SYS.FGA_LOG$에 남고 각각 DBA_AUDIT_TRAIL, DBA_FGA_AUDIT_TRAIL로 봅니다. 실무에서 자주 문제가 되는 것은 adump 디렉터리입니다. SYSDBA 접속이나 기동·종료 기록이 .aud 파일로 계속 생기는데 데이터베이스가 이 파일을 지우지 않습니다. 몇 년 동안 방치하면 파일 수가 수백만 개가 되어 디렉터리 조회조차 느려지고, 공간이 차면 접속이 실패할 수도 있습니다.

@SEC 13.6|DBMS_AUDIT_MGMT로 정리
- 보관 → 아카이브 시각 → 삭제
- 유형별 초기화 차이
- 정리 작업 예약

@SLIDE 정리의 원칙|지우기 전에 보관한다
- 외부 저장소로 기록을 옮긴다
- SET_LAST_ARCHIVE_TIMESTAMP로 범위 표시
- CLEAN_AUDIT_TRAIL은 그 시각 이전만 삭제
- use_last_arch_timestamp FALSE는 전체 삭제
@NOTE DBMS_AUDIT_MGMT의 설계는 감사 기록을 함부로 지우지 못하게 하는 데 맞춰져 있습니다. 먼저 기록을 다른 곳으로 옮기고, 어디까지 옮겼는지를 마지막 아카이브 시각으로 기록한 다음, 그 시각 이전 기록만 지우는 흐름입니다. CLEAN_AUDIT_TRAIL의 use_last_arch_timestamp 기본값이 TRUE인 것도 이 때문입니다. FALSE로 주면 유형 전체를 지우므로 시험 환경이 아니라면 쓰지 않습니다. 실습에서는 12장이 남긴 FGA 기록에만 FALSE를 썼습니다.

@SLIDE 감사 기록 유형 상수|무엇을 지울지 고른다
- AUDIT_TRAIL_UNIFIED: 통합 감사 기록
- AUDIT_TRAIL_AUD_STD / FGA_STD / DB_STD
- AUDIT_TRAIL_OS / XML / FILES
- AUDIT_TRAIL_ALL: 전부
@NOTE 정리 프로시저는 모두 첫 인자로 감사 기록 유형을 받습니다. 통합 감사 기록은 AUDIT_TRAIL_UNIFIED, 전통적 감사의 AUD$는 AUD_STD, FGA_LOG$는 FGA_STD이고 둘을 합친 것이 DB_STD입니다. adump의 .aud 파일은 OS, XML 감사 파일은 XML, 둘을 합쳐 FILES입니다. 혼합 모드 데이터베이스라면 이 유형들이 모두 쌓일 수 있으므로, 정리 작업을 하나만 만들어 놓고 안심하지 말고 어떤 유형을 대상으로 하는지 확인해야 합니다.

@SLIDE 초기화가 필요한 유형|통합 감사는 필요 없다
- UNIFIED: 초기화 불필요(INIT_CLEANUP 시 ORA-46250)
- AUD_STD·FGA_STD·DB_STD: INIT_CLEANUP 필요
- OS·XML: 초기화 불필요
- INIT_CLEANUP은 FGA_LOG$를 SYSAUX로 옮겼다
@NOTE 초기화가 필요한 유형과 필요 없는 유형이 나뉩니다. 실습 3에서 초기화하지 않은 FGA_LOG$를 정리하려 하자 ORA-46258이, 반대로 통합 감사 기록에 INIT_CLEANUP을 부르자 ORA-46250이 났습니다. 주의할 점은 INIT_CLEANUP이 정리 기반만 만드는 것이 아니라 테이블을 SYSAUX로 옮긴다는 것입니다. 실습 DB의 FGA_LOG$가 SYSTEM에서 SYSAUX로 옮겨졌고, DEINIT_CLEANUP을 해도 돌아오지 않아 SET_AUDIT_TRAIL_LOCATION으로 되돌렸습니다.

@SLIDE 아카이브 시각은 UTC|9시간 어긋나면 엉뚱한 범위
- DB 기록(UNIFIED, AUD_STD, FGA_STD)은 UTC
- OS·XML 파일은 서버 현지 시각
- DBA_AUDIT_MGMT_LAST_ARCH_TS로 재확인
- 실습: 가장 오래된 기록 + 10분 이전만 삭제
@NOTE 아카이브 시각은 데이터베이스 기록이면 UTC, OS 파일이면 서버 현지 시각으로 줍니다. 한국 시각으로 넣으면 9시간 늦은 범위까지 지워질 수 있습니다. 실습 3에서는 기존 기록을 보호하려고 가장 오래된 기록에 10분을 더한 시각을 EVENT_TIMESTAMP_UTC로 계산해 넣었습니다. 정리 후 가장 오래된 기록의 시각이 그만큼 뒤로 이동했습니다. 정리 이력 뷰에 이 정리가 보이지 않았으므로 정리 전후 건수와 가장 오래된 시각을 함께 남겨 두는 것이 안전합니다.

@SLIDE 정리 작업 예약|아카이브 시각 갱신과 짝으로
- CREATE_PURGE_JOB, 간격은 시간 단위
- DBA_AUDIT_MGMT_CLEANUP_JOBS로 확인
- 아카이브 시각을 안 바꾸면 매번 0건
- 정리 이력은 DBA_AUDIT_MGMT_CLEAN_EVENTS
@NOTE CREATE_PURGE_JOB은 정해진 간격으로 CLEAN_AUDIT_TRAIL을 불러 주는 작업일 뿐 아카이브 시각을 바꿔 주지는 않습니다. 그래서 작업만 만들어 두고 아카이브 시각을 갱신하는 단계를 빠뜨리면 작업은 매일 성공하는데 실제로는 한 건도 지우지 않는 상황이 생깁니다. 정리 이력 뷰에서 삭제 건수를 확인하면 이 문제를 바로 알 수 있습니다. 보관 작업이 끝날 때마다 아카이브 시각을 갱신하는 단계를 같은 스케줄에 넣는 것이 일반적인 구성입니다.

@SEC 13.7|syslog로 감사 기록 보내기
- DBA가 지울 수 없는 곳으로
- facility와 priority
- AUDIT_SYSLOG_LEVEL과 UNIFIED_AUDIT_SYSTEMLOG

@SLIDE 왜 syslog인가|DB 밖에 남는 기록
- DB 안의 기록은 DBA가 지울 수 있다
- syslog는 OS 로깅, 원격 서버로 전달 가능
- SYS 작업을 증거력 있게 남긴다
- 보내는 것은 감사 기록, alert log가 아님
@NOTE 데이터베이스 안의 감사 기록은 충분한 권한을 가진 DBA라면 지우거나 감사를 꺼 버릴 수 있습니다. 감사 대상이 바로 그 DBA라면 증거로서 힘이 약하겠죠. syslog로 보내면 기록이 운영체제 로그로 가고, rsyslog를 원격 로그 서버로 전달하도록 구성하면 데이터베이스 권한만으로는 손댈 수 없는 곳에 남습니다. 참고로 원본 강의 자료는 이 기능을 경고 로그 내용을 보내는 기능으로 소개했는데, 실제로 보내는 것은 감사 기록입니다.

@SLIDE facility와 priority|rsyslog가 메시지를 나누는 기준
- facility: 메시지의 출처 분류
- LOCAL0~7은 사용자 정의, 오라클 전용으로
- priority: EMERG > ALERT > CRIT > ERR > WARNING > NOTICE > INFO > DEBUG
- 규칙 local1.* → local1의 모든 메시지
@NOTE syslog 메시지는 두 가지 값으로 분류됩니다. facility는 메시지가 어디서 왔는지를, priority는 얼마나 중요한지를 나타냅니다. rsyslog 설정 파일의 각 줄은 이 두 값의 조합을 보고 메시지를 어느 파일로 보낼지 정합니다. 오라클 감사 기록은 다른 애플리케이션이 쓰지 않는 LOCAL 번호 하나를 골라 보내는 것이 일반적이며, 원본 실습도 local1을 썼습니다. local1.*라고 쓰면 local1로 오는 메시지를 priority와 관계없이 모두 받습니다.

@SLIDE AUDIT_SYSLOG_LEVEL|전통적 감사의 syslog 전송
- SYS 감사(AUDIT_SYS_OPERATIONS=TRUE)
- 표준 감사(AUDIT_TRAIL=OS)
- 정적 파라미터, SCOPE=SPFILE + 재기동
- 순수 통합 감사에서는 효과 없음
- 512바이트에서 잘릴 수 있다
@NOTE AUDIT_SYSLOG_LEVEL이 보내는 기록은 두 종류입니다. AUDIT_SYS_OPERATIONS가 TRUE이면 SYS 감사 기록이, AUDIT_TRAIL이 OS이면 표준 감사 기록이 syslog로 갑니다. 원본 실습은 AUDIT_TRAIL도 OS로 바꿨지만, SYS 작업만 보내려면 그럴 필요가 없습니다. 이 파라미터는 정적이라 메모리에서 바로 바꿀 수 없고 SPFILE에 넣고 재기동해야 합니다. 또 syslog 메시지가 512바이트에서 잘릴 수 있어 긴 SQL 문은 앞부분만 남을 수 있다는 점도 알아 두어야 합니다.

@SLIDE 설정 순서|rsyslog 먼저, DB는 재기동
- /etc/rsyslog.conf에 local1.* 규칙 추가
- systemctl restart rsyslog
- SCOPE 없이 SET → ORA-02095, SCOPE=SPFILE
- SHUTDOWN IMMEDIATE / STARTUP
@NOTE 설정은 rsyslog 쪽부터 합니다. 실습 4에서 원본 설정 파일을 백업하고 local1의 모든 메시지를 별도 파일로 받는 규칙을 추가한 뒤 rsyslog를 재시작했습니다. 데이터베이스 쪽은 AUDIT_SYSLOG_LEVEL이 정적 파라미터라 SCOPE 없이 바꾸면 ORA-02095가 납니다. SCOPE=SPFILE로 넣고 재기동해야 적용됩니다. 재기동 전에 SPFILE을 PFILE로 백업해 두면 설정을 잘못 넣어 기동이 안 될 때 되돌릴 수 있습니다.

@SLIDE syslog에 남은 기록|무엇이 어떻게 보이는가
- SYS 조회·DDL이 'Oracle Audit' 항목으로
- 긴 SQL은 두 항목으로 나뉘어 기록
- adump .aud 파일과의 관계
- 원복: RESET + 재기동, rsyslog.conf 복구
@NOTE 재기동 후 SYS로 조회와 테이블 생성, 삭제를 하자 /var/log/oracle_db.log에 Oracle Audit 항목이 한 줄씩 남았습니다. ACTION에 SQL 문이, PRIVILEGE에 SYSDBA가 들어 있습니다. 같은 시각 이후로 adump에는 새 .aud 파일이 생기지 않았으니 SYS 감사의 행선지가 바뀐 것입니다. SHOW PARAMETER가 내부적으로 실행한 긴 문장은 두 항목으로 나뉘어 기록됐는데, 이것이 syslog 크기 제한의 실제 모습입니다. 원복은 RESET과 재기동, rsyslog 설정 복구 순으로 합니다.

@SLIDE UNIFIED_AUDIT_SYSTEMLOG|통합 감사 기록의 핵심 필드
- 통합 감사 기록을 syslog로(UNIX)
- 전체가 아닌 식별용 핵심 필드
- facility는 USER, LOCAL0~7
- CDB에서는 PDB마다 지정
- 실습: 혼합 모드에서도 로그인 실패가 전달됨
@NOTE UNIFIED_AUDIT_SYSTEMLOG는 통합 감사 기록을 syslog로 보내되, 전체가 아니라 기록을 찾아갈 수 있는 핵심 필드만 보냅니다. 실습 4에서 이 파라미터를 함께 설정했더니 혼합 모드인데도 SCOTT의 로그인 실패가 Oracle Unified Audit 항목으로 들어왔습니다. 세션 번호와 항목 번호, 사용자, 동작 번호, 반환 코드가 들어 있어서 이 값으로 UNIFIED_AUDIT_TRAIL에서 원래 기록을 찾습니다. 순수 통합 감사로 전환할 때 AUDIT_SYSLOG_LEVEL을 대신하는 수단이 됩니다.

@SEC 13.8|감사 기록 보호와 운영
- 권한 분리
- 공간과 정리 작업 감시

@SLIDE 감사 기록 보호와 운영|감사가 감사답게
- AUDIT_ADMIN·AUDIT_VIEWER·DBA 분리
- SYS 작업은 syslog·원격 서버로
- 감사 공간과 adump 감시
- 정리 이력으로 실제 삭제 건수 확인
- 순수 통합 전환 시 syslog 수집 방식 변경
@NOTE 감사 기록을 관리하는 원칙은 두 가지로 정리됩니다. 첫째, 감사를 받는 사람이 기록을 지울 수 없어야 합니다. 그래서 감사 관리 권한을 DBA와 분리하고, SYS 작업은 데이터베이스 밖의 syslog나 원격 서버에 남깁니다. 둘째, 감사 장치가 장애 원인이 되지 않아야 합니다. 감사 테이블스페이스와 adump 디렉터리 공간을 감시하고, 정리 작업이 실제로 지우고 있는지 이력을 확인합니다. 나중에 순수 통합 감사로 전환하면 AUDIT_SYSLOG_LEVEL 기반 수집이 멈추므로 그 대비도 필요합니다.

@SEC 13.9|딕셔너리 뷰
- 모드, 기록, 정책, 정리

@SLIDE 감사 기록 관리 뷰|모드·기록·정책·정리
- V$OPTION: 감사 모드
- UNIFIED_AUDIT_TRAIL, DBA_AUDIT_TRAIL, DBA_FGA_AUDIT_TRAIL
- AUDIT_UNIFIED_POLICIES / _ENABLED_POLICIES
- DBA_AUDIT_MGMT_CONFIG_PARAMS / LAST_ARCH_TS
- DBA_AUDIT_MGMT_CLEANUP_JOBS / CLEAN_EVENTS
@NOTE 이 장에서 쓴 뷰를 용도별로 묶으면 네 갈래입니다. 감사 모드는 V$OPTION으로, 기록은 통합 감사와 전통적 감사 각각의 TRAIL 뷰로, 정책은 AUDIT_UNIFIED로 시작하는 두 뷰로 봅니다. 정리와 관련된 설정과 이력은 DBA_AUDIT_MGMT로 시작하는 네 개의 뷰에 있습니다. 운영 점검표를 만든다면 마지막 아카이브 시각, 정리 작업 상태, 최근 정리 이력의 삭제 건수를 정기적으로 확인하는 항목을 넣는 것이 좋습니다.

@PLAIN 요약
- 19c 기본은 혼합 모드, 전환은 uniaud_on 재링크
- 혼합 모드는 통합 감사 + AUD$·FGA_LOG$·adump
- 기본 정책: ORA_SECURECONFIG, ORA_LOGON_FAILURES
- 정리 = 보관 → 아카이브 시각(UTC) → CLEAN
- UNIFIED는 초기화 불필요, AUD$·FGA_LOG$는 INIT_CLEANUP
- AUDIT_SYSLOG_LEVEL: SYS·OS 감사를 syslog로, 정적

@PLAIN 퀴즈 (1/2)
- Q1. Unified Auditing FALSE의 의미는? → 혼합 모드
- Q2. 켜진 정책을 DROP하면? → 오류, NOAUDIT 먼저
- Q3. INIT_CLEANUP이 필요 없는 유형은? → UNIFIED

@PLAIN 퀴즈 (2/2)
- Q4. 통합 감사 아카이브 시각의 기준은? → UTC
- Q5. AUDIT_SYSLOG_LEVEL이 보내는 것은? → SYS 감사 기록 등
- Q6. CLEAN이 0건을 지우면? → 아카이브 시각 확인

@PLAIN 실습 개요
- 01 감사 모드와 기본 정책: V$OPTION, 로그인 실패 기록 (13.2~13.4)
- 02 통합 감사 정책과 기록 보호: ORA-46361, ORA-46385 (13.3, 13.5)
- 03 DBMS_AUDIT_MGMT 정리: ORA-46258·46250, UTC 아카이브, ORA-27478 (13.6)
- 04 syslog 전송 설정: ORA-02095, Oracle Audit·Unified Audit 항목 (13.7)
- 05 원복과 확인: ORA-32010, 정리 작업·FGA_LOG$ 위치 원복 (13.6, 13.7)
