@TITLE Oracle Database 19c RAC 과정|FAN·TAF·Application Continuity|클라이언트가 장애를 넘기는 네 가지 방법|제13장

@PLAIN 학습 목표
- 클라이언트 페일오버 네 가지를 비교한다
- Connect-Time Failover를 구성한다
- TAF를 구성하고 서버 우선 규칙을 확인한다
- ONS·FAN 이벤트와 FCF를 설명한다
- clbgoal·rlbgoal과 GOODNESS를 해석한다
- AC·TAC의 속성과 재생 조건을 구분한다

@PLAIN Agenda
- 13.2  클라이언트 페일오버의 전체 그림
- 13.3  Connect-Time Failover
- 13.4  TAF
- 13.5  FAN과 FCF  /  13.6  부하 분산 권고
- 13.7  Application Continuity와 TAC
- 13.8  운영 지침

@SEC 13.2|클라이언트 페일오버의 전체 그림
- 네 가지 방법
- 겹쳐 쓰기

@IMG 13_compare.png|클라이언트 페일오버 네 가지|감지 주체와 이어 주는 범위가 다르다
@NOTE 이 장의 지도입니다. Connect-Time Failover는 접속을 맺는 순간 첫 주소가 안 되면 다음 주소로 가는 것이라 이미 맺어진 세션에는 아무 일도 하지 않습니다. TAF는 세션이 끊긴 뒤 OCI 라이브러리가 다시 접속하고 조회는 이어서 가져오지만 트랜잭션은 롤백됩니다. FAN과 FCF는 서버가 먼저 이벤트로 알려 커넥션 풀이 죽은 연결을 즉시 정리합니다. AC와 TAC는 커밋 여부를 확인한 뒤 진행 중이던 요청까지 다시 실행합니다. 오른쪽으로 갈수록 이어 주는 범위가 넓어집니다.

@SLIDE 겹쳐 쓰기|하나로 끝나지 않는다
- 모든 접속에 SCAN 기술자와 타임아웃
- 풀을 쓰면 FAN·FCF
- OCI 조회 위주면 TAF
- 무중단이 필요하면 AC·TAC, FAN도 함께
@NOTE 네 가지는 서로를 대신하지 않고 층층이 겹쳐 씁니다. 어떤 애플리케이션이든 접속 기술자는 SCAN과 서비스로 쓰고 타임아웃과 재시도를 넣습니다. 커넥션 풀을 쓴다면 FAN을 받아 FCF로 죽은 연결을 바로 정리하게 합니다. OCI 기반의 조회 위주 프로그램이라면 TAF로 조회를 이어 갈 수 있습니다. 장애 때 오류 없이 이어져야 한다면 AC나 TAC를 쓰는데, 이것도 FAN 위에서 동작하므로 FAN 설정이 함께 필요합니다.

@SEC 13.3|Connect-Time Failover
- 접속 기술자
- 타임아웃 파라미터
- SCAN과 VIP

@IMG 13_ctf.png|Connect-Time Failover|응답 없는 주소는 타임아웃 뒤 다음 주소로
@NOTE 클라이언트가 rac-scan 이름을 풀면 운영 환경에서는 IP 세 개가, 실습 환경에서는 하나가 나옵니다. FAILOVER가 켜져 있으면 첫 주소가 응답하지 않을 때 TRANSPORT_CONNECT_TIMEOUT만큼 기다린 뒤 다음 주소로 넘어갑니다. 연결된 SCAN 리스너는 서비스가 있는 인스턴스의 노드 리스너로 넘겨 줍니다. 오른쪽 위는 노드가 죽었을 때입니다. 그 노드의 VIP는 다른 노드로 옮겨 가 리스너 없이 즉시 거절하므로 TCP 타임아웃을 기다리지 않습니다.

@SLIDE 접속 기술자|ADDRESS_LIST와 타임아웃
- FAILOVER=on (기본값 on)
- LOAD_BALANCE=on (ADDRESS_LIST 기본값 off)
- HOST = rac-scan, SERVICE_NAME = 서비스
- 서버 설정 없이 기술자만으로 동작
@NOTE Connect-Time Failover는 서버에 아무것도 설정하지 않고 클라이언트의 접속 기술자만으로 동작합니다. ADDRESS_LIST 안에 FAILOVER와 LOAD_BALANCE를 둡니다. FAILOVER는 기본값이 on이라 주소가 여럿이면 자동으로 다음 주소를 시도합니다. LOAD_BALANCE는 ADDRESS_LIST에서 기본값이 off라서 시작 주소를 무작위로 고르려면 직접 켭니다. 주소는 노드 이름이나 VIP를 나열하지 않고 SCAN 하나로 쓰고, 연결할 대상은 서비스 이름으로 지정합니다.

@SLIDE 타임아웃 파라미터|기다리는 시간을 정한다
- TRANSPORT_CONNECT_TIMEOUT: 주소 하나의 TCP 연결
- CONNECT_TIMEOUT: 인증 전까지 전체 연결
- RETRY_COUNT · RETRY_DELAY: 목록 재시도
- 기본값에 맡기면 OS TCP 타임아웃만큼 대기
@NOTE 장애 때 클라이언트가 얼마나 기다리는지는 타임아웃 파라미터가 정합니다. TRANSPORT_CONNECT_TIMEOUT은 주소 하나에 TCP 연결을 맺을 때까지 기다리는 시간이라 짧게 두면 응답 없는 주소에서 오래 머물지 않습니다. CONNECT_TIMEOUT은 인증 전까지 Oracle Net 연결 전체에 허용하는 시간입니다. RETRY_COUNT와 RETRY_DELAY는 주소 목록 전체를 몇 번, 어떤 간격으로 다시 돌지 정합니다. 이 값들을 넣지 않으면 운영체제의 TCP 타임아웃만큼 기다릴 수 있습니다.

@SLIDE SCAN과 VIP|실습 환경의 SCAN은 IP 하나
- 운영: DNS가 SCAN IP 3개를 돌려줌
- 11.2 이상 클라이언트는 IP 목록으로 다룸
- 실습: dnsmasq가 172.16.225.120 하나
- SCAN VIP가 살아 있는 노드로 이동
@NOTE 운영 환경에서는 DNS가 SCAN 이름 하나에 IP 세 개를 돌려주고, 11.2 이상 클라이언트는 이 IP들을 주소 목록처럼 다뤄 하나가 안 되면 다음으로 넘어갑니다. 실습 환경은 dnsmasq가 IP 하나만 돌려주므로 주소 목록 안에서 넘어갈 곳은 없습니다. 그래도 SCAN 접속이 계속 되는 이유는 SCAN VIP 자체가 Clusterware 자원이라 살아 있는 노드로 옮겨 가기 때문입니다. Data Guard 대기 사이트가 있다면 두 번째 주소 목록에 대기 쪽 SCAN을 더합니다.

@SEC 13.4|TAF
- 클라이언트 설정과 서버 설정
- 서버 우선 규칙
- 한계

@SLIDE TAF란|끊긴 세션을 OCI가 다시 만든다
- TYPE=SESSION: 세션만 재생성
- TYPE=SELECT: 열린 커서를 이어서 fetch
- METHOD=BASIC: 장애 뒤 재접속
- METHOD=PRECONNECT: 예비 연결을 미리
@NOTE TAF는 세션이 끊긴 뒤 OCI 클라이언트 라이브러리가 자동으로 다시 접속하는 기능입니다. SESSION 유형은 새 세션만 만들어 주고, SELECT 유형은 열려 있던 커서를 다시 실행해서 이미 받은 행 다음부터 이어 줍니다. 그래서 큰 조회 결과를 받는 도중 노드가 죽어도 애플리케이션은 계속 행을 받습니다. METHOD는 언제 다시 접속할지입니다. BASIC은 장애가 난 뒤에, PRECONNECT는 처음부터 BACKUP으로 지정한 예비 연결을 하나 더 맺어 둡니다.

@SLIDE 클라이언트 쪽 설정|tnsnames.ora의 FAILOVER_MODE
- CONNECT_DATA 안에 FAILOVER_MODE
- TYPE=SELECT, METHOD=BASIC
- RETRIES=30, DELAY=5
- 클라이언트마다 고쳐야 하는 부담
@NOTE 클라이언트 쪽에서는 tnsnames.ora의 CONNECT_DATA 안에 FAILOVER_MODE를 넣습니다. 실습 06에서 쓴 CH16_LB_TAF 항목은 TYPE을 SELECT, METHOD를 BASIC으로 두고 재시도 30번, 간격 5초로 설정했습니다. 이 방식은 설정이 눈에 보인다는 장점이 있지만, 클라이언트가 수백 대라면 파일을 모두 고쳐야 하고 EZConnect처럼 기술자 없이 붙는 접속에는 적용할 수 없습니다. 그래서 서버 쪽 서비스 속성으로 관리하는 방법이 함께 있습니다.

@SLIDE 서버 쪽 설정|srvctl modify service
- -failovertype NONE/SESSION/SELECT/TRANSACTION/AUTO
- -failovermethod NONE/BASIC (서버 TAF는 BASIC)
- -failoverretry 30 -failoverdelay 5
- -failover_restore NONE/LEVEL1/AUTO
@NOTE 서버 쪽에서는 srvctl modify service로 서비스 속성을 지정합니다. failovertype이 SESSION이나 SELECT면 TAF이고, TRANSACTION은 AC, AUTO는 TAC입니다. failovermethod는 서버 쪽에서는 BASIC만 씁니다. failoverretry와 failoverdelay로 재시도 횟수와 간격을, failover_restore로 재접속 뒤 처음 세션 상태를 복원할지를 정합니다. 서버에 지정하면 FAILOVER_MODE가 없는 EZConnect 접속에도 적용되므로 클라이언트를 고치지 않고 한 곳에서 관리할 수 있습니다.

@IMG 13_precedence.png|둘 다 있으면 서버가 이긴다|실습 06의 네 칸 실험
@NOTE 서버와 클라이언트 양쪽에 설정이 있으면 무엇이 적용될까요. 실습 06에서 네 칸을 모두 측정했습니다. ch16_ac는 서버에 TRANSACTION이 있고 ch16_lb는 없습니다. 서버에만 있으면 서버 값, 클라이언트에만 있으면 클라이언트 값이 적용됩니다. 핵심은 오른쪽 위 칸입니다. 클라이언트가 TYPE SELECT를 요청했는데 세션에는 TRANSACTIONAL이 협상되었습니다. 서버 쪽 서비스 속성이 클라이언트 FAILOVER_MODE보다 우선한다는 규칙이 그대로 확인됩니다.

@SLIDE 네 칸 결과 읽기|설정 파일이 아니라 V$SESSION으로
- failover_type, failover_method, failed_over 조회
- TRANSACTION은 TRANSACTIONAL로 표기
- tnsnames.ora만 보고 판단하면 틀린다
- 의도와 다르면 한쪽 설정을 정리
@NOTE 확인은 자기 세션의 V$SESSION에서 FAILOVER_TYPE, FAILOVER_METHOD, FAILED_OVER를 조회하는 것으로 합니다. 서비스에는 TRANSACTION으로 넣었는데 V$SESSION에는 TRANSACTIONAL로 나오니 점검 스크립트로 비교할 때 표기 차이를 감안합니다. 운영에서는 애플리케이션 팀이 tnsnames.ora에 SELECT를 넣었다고 믿는데 실제로는 다르게 동작하는 일이 생깁니다. 의도가 TRANSACTION이면 클라이언트 쪽 설정을 지우고, SELECT가 맞다면 서비스 속성을 바꿉니다.

@SLIDE TAF의 한계|트랜잭션은 이어지지 않는다
- 진행 중 트랜잭션 롤백, ORA-25402
- ALTER SESSION·패키지 상태는 사라짐
- OCI 기반만, JDBC Thin은 불가
- 끊김을 겪어야 반응, FAN과 함께
@NOTE TAF는 조회를 이어 주지만 트랜잭션은 이어 주지 않습니다. 진행 중이던 트랜잭션은 롤백되고, 장애 뒤 첫 호출에서 ORA-25402를 받으면 애플리케이션이 ROLLBACK을 하고 처음부터 다시 실행해야 합니다. ALTER SESSION으로 바꾼 설정이나 PL/SQL 패키지 상태도 새 세션에 따라오지 않습니다. OCI 기반 클라이언트만 지원하므로 JDBC Thin은 쓸 수 없습니다. 또 클라이언트가 끊김을 직접 겪어야 반응하므로 노드가 통째로 멈추면 늦어질 수 있어 FAN과 함께 씁니다.

@SEC 13.5|FAN과 FCF
- ONS
- FAN 이벤트
- FCF

@IMG 13_ons.png|FAN 이벤트의 흐름|ONS가 6200으로 이벤트를 나르고 풀이 받는다
@NOTE racdb1에 장애가 나면 Clusterware가 이벤트를 만들고 그 노드의 ONS가 받습니다. ONS는 원격 포트 6200으로 다른 노드의 ONS에 이벤트를 전하고, 같은 포트로 구독하고 있는 클라이언트 커넥션 풀에도 보냅니다. 풀은 DOWN 이벤트를 받는 즉시 racdb1로 향한 연결을 정리하고, 그 연결을 쓰던 스레드는 기다리지 않고 바로 오류를 받습니다. 인스턴스가 돌아오면 UP 이벤트가 오고 풀은 연결을 다시 나눕니다. 이것이 FCF입니다.

@SLIDE ONS 확인|포트와 데몬
- Local port 6100: 루프백 전용
- Remote port 6200: 모든 주소, 방화벽은 6200만
- onsctl ping: 데몬 생존
- onsctl debug Servers 절: 상대 노드, DEFER
@NOTE srvctl config nodeapps에 onsonly를 붙이면 ONS의 로컬 포트 6100과 원격 포트 6200, SSL 사용 여부가 나옵니다. netstat로 보면 6100은 루프백에만, 6200은 모든 주소에 열려 있습니다. 그래서 방화벽에는 6200만 열면 됩니다. onsctl은 Grid 홈의 opmn bin 아래에 있어 전체 경로로 실행합니다. ping은 데몬이 살아 있는지만 알려 주므로 debug의 Servers 절에서 상대 노드를 잡고 있는지, DEFER가 쌓이지 않는지까지 봅니다.

@SLIDE ons.config|에이전트가 관리하는 파일
- # line added by Agent 주석
- nodes=rac1:6200,rac2:6200
- walletfile, Uses SSL true
- 직접 고치지 않고 srvctl modify nodeapps
@NOTE ONS 구성 파일은 Grid 홈의 opmn conf 아래 ons.config입니다. 대부분의 줄에 line added by Agent라는 주석이 붙어 있는데, 사람이 아니라 Clusterware 에이전트가 쓴 줄이라는 뜻입니다. 직접 고치면 에이전트가 다시 덮어쓰므로 바꿀 일이 있으면 srvctl modify nodeapps를 씁니다. nodes 줄이 앞에서 본 Servers 목록의 근거이고, 노드를 추가하면 자동으로 늘어납니다. wallet 파일이 있어 ONS 통신은 SSL로 보호됩니다.

@SLIDE FAN 이벤트|유형·상태·이유
- SERVICEMEMBER, SERVICE, INSTANCE, NODE
- 상태 UP, DOWN, NODEDOWN
- reason FAILURE: 장애, USER: 관리자 작업
- SERVICEMETRICS: 부하 권고
@NOTE FAN 이벤트에는 유형이 있습니다. 인스턴스 하나의 서비스 상태는 SERVICEMEMBER, 서비스 전체는 SERVICE, 인스턴스와 노드도 각각 이벤트가 있습니다. 상태는 UP과 DOWN, 노드는 NODEDOWN입니다. 중요한 것은 reason입니다. FAILURE는 계획되지 않은 장애라 풀이 연결을 즉시 버리고, USER는 srvctl로 관리자가 한 작업이라 사용 중인 연결이 반납되기를 기다렸다가 닫습니다. SERVICEMETRICS는 13.6절의 부하 권고를 나르는 이벤트입니다.

@SLIDE FCF|FAN을 쓰는 커넥션 풀
- UCP: setFastConnectionFailoverEnabled(true)
- ODP.NET: HA Events=true
- OCI 세션 풀: 이벤트 모드, -notification TRUE
- 진행 중 작업은 앱이 재시도
@NOTE FCF는 커넥션 풀이 FAN 이벤트를 구독해 쓰는 기능입니다. Java의 UCP는 Fast Connection Failover를 켜는 설정 하나로, ODP.NET은 접속 문자열의 HA Events로, OCI 세션 풀은 이벤트 모드로 환경을 만들어 받습니다. OCI 계열에 이벤트를 보내려면 서비스의 notification을 TRUE로 해야 하는데 기본값이 FALSE라 자주 빠집니다. FCF는 죽은 연결을 빨리 치워 줄 뿐 진행 중이던 작업을 살려 주지는 않으므로 애플리케이션의 재시도 로직이 필요합니다.

@SLIDE 서버만 준비하면 소용없다|FAN 도입은 양쪽 작업
- 서비스 -notification TRUE
- 클라이언트 드라이버·풀 설정
- 방화벽 6200
- 데몬, 상대 노드, 풀 로그 순으로 점검
@NOTE ONS가 잘 돌고 있어도 클라이언트가 구독하지 않으면 장애 때 클라이언트는 여전히 TCP 타임아웃을 기다립니다. FAN 도입은 서버의 서비스 속성, 클라이언트 드라이버와 풀 설정, 그 사이의 방화벽을 함께 손대는 작업입니다. 점검도 세 단계로 합니다. onsctl ping으로 데몬을, onsctl debug로 상대 노드를, 마지막으로 클라이언트 풀의 로그에서 이벤트를 실제로 받는지 봅니다. 마지막 단계를 빼면 서버만 준비된 상태로 남기 쉽습니다.

@SEC 13.6|부하 분산 권고
- clbgoal과 rlbgoal
- GOODNESS

@SLIDE clbgoal과 rlbgoal|작동 시점이 다르다
- clbgoal: 리스너가 새 접속을 넘길 때
- rlbgoal: 풀이 열린 연결 중 고를 때
- rlbgoal NONE / SERVICE_TIME / THROUGHPUT
- DBA_SERVICES의 GOAL 열이 rlbgoal
@NOTE 12장의 Connection Load Balancing Goal은 새 접속을 맺는 순간 리스너가 쓰는 기준이었습니다. 커넥션 풀은 연결을 미리 열어 두므로 열린 연결 가운데 무엇을 쓸지가 더 중요한데, 이 기준이 Runtime Load Balancing Goal입니다. SERVICE_TIME은 응답 시간이 짧은 인스턴스를, THROUGHPUT은 처리량이 많은 인스턴스를 선호합니다. DBA_SERVICES에서는 GOAL 열이 rlbgoal이고 CLB_GOAL 열이 clbgoal이라 옵션 이름과 열 이름이 다릅니다.

@SLIDE GOODNESS|rlbgoal을 켜야 계산된다
- ch16_lb만 GOODNESS 100, DELTA 100
- 0은 나쁨이 아니라 미계산
- GROUP_ID 6(약 60초)과 10(약 5초) 혼재
- 효과는 FAN 구독 풀에서만 관찰
@NOTE 실습 02에서 ch16_lb에만 rlbgoal SERVICE_TIME을 주고 GV 달러 SERVICEMETRIC을 보면 ch16_lb만 GOODNESS가 100으로 계산되고 나머지는 0입니다. 0은 나쁘다는 뜻이 아니라 계산하지 않는다는 뜻입니다. 이 값은 SERVICEMETRICS FAN 이벤트로 풀에 전달되고 풀은 그 비율로 연결을 고릅니다. 뷰에는 약 60초 구간과 약 5초 구간 집계가 섞여 있어 GROUP_ID로 걸러야 합니다. SQL*Plus로는 계산된다는 사실까지만 확인할 수 있습니다.

@SEC 13.7|Application Continuity와 TAC
- Transaction Guard
- AC 속성과 오류
- TAC와 재생 조건

@SLIDE AC가 푸는 문제|커밋했는데 응답을 못 받았다
- 다시 실행하면 중복 위험
- 안 하면 누락 위험
- Transaction Guard로 커밋 여부 확인
- 커밋 안 된 요청만 재생
@NOTE 고가용성에서 가장 까다로운 순간은 커밋을 보냈는데 응답을 받기 전에 인스턴스가 죽은 경우입니다. 애플리케이션은 커밋이 되었는지 알 수 없습니다. 다시 실행하면 이체가 두 번 될 수 있고, 안 하면 누락될 수 있습니다. Application Continuity는 이 문제를 두 단계로 풉니다. 먼저 Transaction Guard로 그 트랜잭션이 커밋되었는지 확실히 확인하고, 커밋되지 않은 요청만 새 인스턴스에서 다시 실행합니다. 애플리케이션은 오류 대신 약간의 지연만 겪습니다.

@SLIDE Transaction Guard|LTXID로 커밋 결과를 묻는다
- -commit_outcome TRUE: 트랜잭션마다 LTXID
- -retention 동안 결과 보관
- DBMS_APP_CONT.GET_LTXID_OUTCOME
- 실습 환경에 DBMS_APP_CONT VALID
@NOTE commit_outcome을 TRUE로 켜면 트랜잭션마다 논리 트랜잭션 ID, 줄여서 LTXID가 붙고 그 커밋 결과가 retention 동안 보관됩니다. 접속이 끊긴 뒤 드라이버는 DBMS_APP_CONT 패키지의 GET_LTXID_OUTCOME으로 그 LTXID가 커밋되었는지 묻습니다. 커밋되었으면 재생하지 않고 결과만 돌려주고, 아니면 재생합니다. 애플리케이션이 직접 이 결과를 조회하려면 실행 권한을 받아야 합니다. 실습 04에서 이 패키지가 VALID 상태로 있는 것을 확인합니다.

@SLIDE AC 서비스 속성|실습 04의 ch16_ac
- -failovertype TRANSACTION -commit_outcome TRUE
- -failover_restore LEVEL1 -session_state DYNAMIC
- -replay_init_time 600 -retention 86400
- -failoverretry 30 -failoverdelay 10 -notification TRUE
@NOTE 실습 04에서 만든 ch16_ac 서비스의 속성입니다. failovertype TRANSACTION과 commit_outcome TRUE가 AC의 기본 조합입니다. failover_restore LEVEL1은 재접속 뒤 NLS 같은 세션 상태를 복원하고, session_state DYNAMIC은 요청 도중 세션 상태가 바뀔 수 있다고 보고 추적합니다. replay_init_time 600은 요청이 시작되고 600초가 지나면 재생하지 않는다는 뜻입니다. 재시도는 30번, 10초 간격이고 FAN 전달도 켰습니다. config 출력의 빈 칸이 이 값들로 채워집니다.

@SLIDE 필수 조합과 잘못된 값|PRCD-1259와 PRKO-3125
- TRANSACTION만 지정 → PRCD-1259
- 서비스는 만들어지지 않음
- -failovertype FOO, -rlbgoal FASTEST → PRKO-3125
- 3125는 문법 오류, 1259는 의미 오류
@NOTE commit_outcome 없이 failovertype을 TRANSACTION으로만 지정하면 PRCD-1259로 거부되고 서비스는 만들어지지 않습니다. 커밋 여부를 모르는 채로 재생하면 중복이 생길 수 있으니 조합 자체를 막는 것입니다. 목록에 없는 값을 주면 PRKO-3125가 납니다. rlbgoal에 FASTEST처럼 그럴듯한 값을 쓰는 실수가 흔합니다. 두 오류의 성격이 다릅니다. PRKO-3125는 값이 틀린 문법 오류이고, PRCD-1259는 값은 모두 맞는데 함께 쓸 수 없는 의미 오류입니다.

@SLIDE TAC|19c의 Transparent Application Continuity
- -failovertype AUTO -failover_restore AUTO
- -commit_outcome TRUE
- 세션 상태를 자동 추적, 재생 지점을 스스로 찾음
- 19c 이상 클라이언트 드라이버
@NOTE TAC는 19c에서 도입된 AC의 한 방식입니다. 서비스에 failovertype AUTO와 failover_restore AUTO, 그리고 commit_outcome TRUE를 지정합니다. 일반 AC는 커넥션 풀이 요청의 시작과 끝을 표시하고 애플리케이션이 세션 상태 사용을 맞춰야 하지만, TAC는 드라이버와 서버가 세션 상태를 자동으로 추적해 재생할 수 있는 지점을 스스로 찾습니다. 상태를 확실히 모르는 구간에서는 재생을 껐다가 다시 켭니다. 코드를 고칠 여지가 적은 애플리케이션에 먼저 검토합니다.

@IMG 13_ac.png|AC의 재생|커밋 여부를 확인한 뒤 커밋되지 않은 요청만 재생
@NOTE 재생의 흐름입니다. 재생 드라이버는 요청 안의 호출을 기록해 둡니다. racdb1이 요청 도중 죽어 커밋 응답을 못 받으면 드라이버는 FAN이나 오류로 감지하고 racdb2에 다시 접속해 세션 상태를 복원합니다. 그다음 Transaction Guard로 커밋 결과를 묻습니다. 커밋되었으면 결과만 돌려주고, 커밋되지 않았으면 replay_init_time 안일 때 기록한 호출을 다시 실행합니다. 재생 결과가 처음과 다르면 재생을 멈추고 원래 오류를 애플리케이션에 돌려줍니다.

@SLIDE 재생되지 않는 것|애플리케이션 검토가 일의 대부분
- 외부 부수 효과: UTL_HTTP, UTL_FILE, UTL_SMTP
- ALTER SYSTEM, ALTER DATABASE
- SYSDATE·SYS_GUID·시퀀스는 KEEP 권한으로
- replay_init_time을 넘긴 요청
@NOTE 재생이 만능은 아닙니다. UTL_HTTP로 외부를 호출하거나 UTL_FILE로 파일을 쓰는 작업은 재생하면 두 번 일어나므로 트랜잭션 밖으로 빼거나 여러 번 실행해도 같은 결과가 나오게 만듭니다. ALTER SYSTEM과 ALTER DATABASE는 재생하지 않습니다. SYSDATE, SYS_GUID, 시퀀스 값은 재생 시점에 달라지는데 KEEP DATE TIME, KEEP SYSGUID 권한과 시퀀스의 KEEP 속성으로 원래 값을 쓰게 할 수 있습니다. replay_init_time을 넘긴 요청도 재생하지 않습니다.

@SLIDE 검증 세 단계|설정은 시작일 뿐
- srvctl config service로 설정 확인
- V$SESSION으로 협상 확인
- 시험 환경 장애로 FAILED_OVER와 앱 반응 확인
- 재생 드라이버를 쓰는지 먼저 확인
@NOTE AC를 켰다는 보고만 믿으면 실제 장애 때 오류가 쏟아질 수 있습니다. 검증은 세 단계입니다. srvctl config service로 서비스 설정을, V$SESSION으로 세션에 협상된 유형을 봅니다. 이 둘은 실습에서 할 수 있습니다. 마지막으로 시험 환경에서 인스턴스를 강제로 죽여 FAILED_OVER가 YES로 바뀌면서 애플리케이션에 오류가 없는지 봅니다. 이때 애플리케이션이 재생 드라이버를 쓰지 않으면 서버 설정과 상관없이 재생은 일어나지 않습니다.

@SEC 13.8|운영 지침
- 설정 선택 기준
- 점검과 정리

@SLIDE 설정 선택 기준|상황별 권장 조합
- 모든 접속: SCAN + 서비스 + 타임아웃
- 풀 OLTP: FAN + FCF, rlbgoal SERVICE_TIME
- OCI 조회 위주: 서버 TAF SELECT
- 무중단: AC 또는 19c TAC
@NOTE 상황별로 정리합니다. 어떤 애플리케이션이든 접속 기술자는 SCAN과 서비스로 쓰고 타임아웃과 재시도를 넣습니다. 커넥션 풀을 쓰는 OLTP라면 notification을 켜서 FAN과 FCF를 쓰고 rlbgoal을 SERVICE_TIME으로 둡니다. OCI 기반의 조회 위주 프로그램이라면 서버 쪽 TAF를 SELECT, BASIC으로 둡니다. 장애 때 오류 없이 이어져야 하고 재생 드라이버를 쓴다면 AC를, 코드를 고치기 어려운 19c 클라이언트라면 TAC를 검토합니다.

@SLIDE 점검과 정리|이 장의 점검 다섯 가지
- 매일 onsctl ping, 주간 onsctl debug
- 주간 srvctl config와 dba_services 비교
- 변경 후 v$session 협상 값
- 분기 장애 재현 검증
- 실습 후 서비스 삭제, tnsnames 341바이트
@NOTE 점검 항목은 다섯 가지입니다. 매일 양 노드에서 ONS 데몬이 살아 있는지, 주간으로 ONS가 상대 노드를 잡고 있는지와 서비스의 페일오버·부하 설정이 의도대로인지 봅니다. 설정을 바꾼 뒤에는 V$SESSION으로 실제 협상 값을 확인하고, 분기마다 시험 환경에서 장애를 재현해 봅니다. 실습이 끝나면 ch16_lb와 ch16_ac를 정지하고 지운 뒤, tnsnames.ora를 백업에서 되돌려 원래 크기인 341바이트인지 확인합니다.

@PLAIN 요약
- 네 가지: Connect-Time, TAF, FAN·FCF, AC·TAC
- CTF는 기술자의 FAILOVER·타임아웃, 새 접속만
- TAF는 서버 속성이 클라이언트보다 우선
- FAN은 ONS 6200, FCF는 풀이 즉시 정리
- rlbgoal을 켜야 GOODNESS 계산
- AC는 TRANSACTION + commit_outcome, TAC는 AUTO

@PLAIN 퀴즈
- 1. 맺어진 세션에 아무 일도 하지 않는 방법은?
- 2. TRANSPORT_CONNECT_TIMEOUT을 짧게 두는 이유는?
- 3. ch16_ac에 TYPE=SELECT로 붙으면 협상 값은?
- 4. TAF 재접속 뒤 진행 중 트랜잭션은?
- 5. reason FAILURE와 USER의 풀 처리 차이는?
- 6. TRANSACTION만 지정하면 나는 오류와 이유는?

@PLAIN 실습 개요
- 01 ★  FAN 이벤트 확인 — ONS 포트와 onsctl
- 02  부하 분산 권고 — clbgoal·rlbgoal, GOODNESS
- 04  AC 설정과 속성 확인 — Transaction Guard
- 06  페일오버 유형 네 칸 실험과 정리
- 파일: RAC/16장/16장_실습_NN_*.txt
