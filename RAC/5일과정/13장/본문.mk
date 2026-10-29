@H1 제13장  FAN·TAF·Application Continuity

@H2 13.1  학습 목표

@P 12장에서 서비스는 장애가 나면 10초 안에 가용 인스턴스로 옮겨 갔다. 서버 쪽 복구는 빠르지만, 죽은 인스턴스에 붙어 있던 클라이언트가 무엇을 겪는지는 별개의 문제다. 이 장은 클라이언트 쪽에서 장애를 넘기는 네 가지 방법을 비교한다. 새 접속을 다른 주소로 돌리는 Connect-Time Failover, 끊긴 세션을 다시 만드는 TAF, 서버의 알림으로 연결을 즉시 정리하는 FAN과 FCF, 진행 중이던 작업까지 다시 실행하는 Application Continuity(AC)와 Transparent Application Continuity(TAC)다.

@B 클라이언트 페일오버 네 가지를 감지 주체, 이어지는 범위, 진행 중 트랜잭션 처리, 필요한 클라이언트로 비교할 수 있다.
@B `ADDRESS_LIST`, `FAILOVER`, `LOAD_BALANCE`, 타임아웃 파라미터로 Connect-Time Failover를 구성하고 SCAN과의 관계를 설명할 수 있다.
@B 클라이언트 `FAILOVER_MODE`와 서버 `srvctl` 속성으로 TAF를 구성하고, 둘이 함께 있을 때 서버 쪽이 우선한다는 것을 `V$SESSION`으로 확인할 수 있다.
@B ONS의 포트 구조와 FAN 이벤트를 설명하고 FCF가 커넥션 풀에서 하는 일을 말할 수 있다.
@B `clbgoal`·`rlbgoal`과 `V$SERVICEMETRIC`의 관계를 설명할 수 있다.
@B AC와 TAC의 서비스 속성, Transaction Guard의 역할, 재생되는 것과 재생되지 않는 것을 구분할 수 있다.

@H2 13.2  클라이언트 페일오버의 전체 그림

@P 네 방법은 서로를 대신하지 않고 겹쳐 쓴다. 각자 장애를 다른 시점에 감지하고 다른 범위까지 이어 준다.

@IMG 13_compare.png | 그림 13-1. 클라이언트 페일오버 네 가지 — 무엇이 감지하고 어디까지 이어 주는가

@TBL
방법 | 감지 주체 | 무엇이 이어지는가 | 진행 중 트랜잭션 | 필요한 클라이언트
Connect-Time Failover | 클라이언트 Oracle Net(접속 시도 실패) | 새 접속만 다른 주소로 | 해당 없음(접속 전) | 모든 Oracle Net 클라이언트
TAF | 클라이언트 OCI 계층(세션 끊김) | 세션 재접속, SELECT는 커서까지 | 롤백, 애플리케이션이 ROLLBACK 처리 | OCI 기반(OCI, JDBC OCI, ODP.NET Unmanaged)
FAN·FCF | 서버(Clusterware → ONS 이벤트) | 풀의 다른 연결로 즉시 전환 | 롤백, 애플리케이션이 오류를 받고 재시도 | FAN 지원 풀(UCP, ODP.NET, OCI 세션 풀)
AC·TAC | 드라이버(오류·FAN) + 서버(Transaction Guard) | 세션 상태와 진행 중 요청을 재생 | 커밋 여부 확인 후 재생 | 재생 드라이버(JDBC Replay·UCP, OCI 12.2 이상, TAC는 19c 클라이언트)
@END

@B Connect-Time Failover는 이미 맺어진 세션에는 아무 일도 하지 않는다. 나머지 셋은 맺어진 세션을 다룬다.
@B TAF는 클라이언트가 끊김을 겪은 뒤에 반응하고, FAN은 서버가 먼저 알려 준다. TCP 타임아웃을 기다리는 시간이 이 차이에서 생긴다.
@B AC는 FAN과 Transaction Guard 위에서 동작한다. AC를 쓰는 서비스에도 FAN 설정이 함께 필요하다.

@H2 13.3  Connect-Time Failover

@P 접속을 맺는 순간에 첫 주소가 응답하지 않으면 다음 주소로 넘어가는 기능이다. 서버에 아무것도 설정하지 않고 접속 기술자만으로 동작한다.

@IMG 13_ctf.png | 그림 13-2. Connect-Time Failover — SCAN 이름이 주소 목록으로 풀리고, 실패한 주소는 타임아웃 뒤 다음 주소로 넘어간다

@CODE
RACDB_OLTP =
  (DESCRIPTION =
    (CONNECT_TIMEOUT = 90)(TRANSPORT_CONNECT_TIMEOUT = 3)
    (RETRY_COUNT = 20)(RETRY_DELAY = 3)
    (ADDRESS_LIST =
      (LOAD_BALANCE = on)(FAILOVER = on)
      (ADDRESS = (PROTOCOL = TCP)(HOST = rac-scan)(PORT = 1521)))
    (CONNECT_DATA = (SERVICE_NAME = ch16_ac)))
@END

@TBL
파라미터 | 위치 | 뜻
FAILOVER | ADDRESS_LIST 또는 DESCRIPTION | on이면 주소 하나가 실패할 때 다음 주소를 시도한다. 기본값 on
LOAD_BALANCE | ADDRESS_LIST 또는 DESCRIPTION | on이면 시작 주소를 무작위로 고른다. ADDRESS_LIST와 DESCRIPTION의 기본값은 off
TRANSPORT_CONNECT_TIMEOUT | DESCRIPTION | 주소 하나에 TCP 연결을 맺을 때까지 기다리는 시간
CONNECT_TIMEOUT | DESCRIPTION | 인증 전까지 Oracle Net 연결 전체를 맺는 데 허용하는 시간
RETRY_COUNT / RETRY_DELAY | DESCRIPTION | 주소 목록 전체를 다시 도는 횟수와 그 사이 간격
@END

@B 운영 환경에서는 DNS가 SCAN 이름 하나에 IP 3개를 돌려준다. 11.2 이상 클라이언트는 그 IP들을 주소 목록처럼 다뤄, 하나가 응답하지 않으면 다음 IP로 넘어간다.
@B 실습 환경의 SCAN은 dnsmasq가 IP 하나(172.16.225.120)만 돌려준다. 주소 목록 안에서 넘어갈 곳은 없지만, SCAN VIP 자체가 살아 있는 노드로 옮겨 가므로 SCAN 접속은 계속 된다.
@B SCAN 리스너는 연결을 노드 리스너(VIP)로 넘긴다. 노드가 죽으면 그 VIP가 다른 노드로 옮겨 가 리스너 없이 접속을 즉시 거절하므로, 클라이언트는 TCP 타임아웃을 기다리지 않고 다음 시도로 넘어간다(1장).
@B `TRANSPORT_CONNECT_TIMEOUT`을 짧게 두면 응답 없는 주소에서 오래 머물지 않는다. 기본값에 맡기면 운영체제 TCP 타임아웃만큼 기다릴 수 있다.

@BP 접속 기술자는 SCAN과 서비스로 쓴다
`HOST`에 노드 이름이나 VIP를 나열하면 노드를 추가·삭제할 때마다 클라이언트를 고쳐야 한다. SCAN 하나와 서비스 이름으로 쓰고, 타임아웃과 재시도 파라미터를 함께 넣는다.
Data Guard 대기 사이트가 있다면 `DESCRIPTION_LIST`나 두 번째 `ADDRESS_LIST`에 대기 쪽 SCAN을 더해 같은 기술자로 사이트 전환까지 받는다.
@END

@H2 13.4  TAF — Transparent Application Failover

@P TAF는 세션이 끊긴 뒤 OCI 클라이언트 라이브러리가 자동으로 다시 접속하는 기능이다. SELECT 유형이면 열려 있던 조회를 이어서 가져온다. 설정은 클라이언트의 접속 기술자나 서버의 서비스 속성 어느 쪽에서도 할 수 있다.

@H3 13.4.1  클라이언트 쪽 설정

@CODE
CH16_LB_TAF =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = rac-scan)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ch16_lb)
      (FAILOVER_MODE = (TYPE = SELECT)(METHOD = BASIC)(RETRIES = 30)(DELAY = 5))))
@END

@TBL
FAILOVER_MODE 항목 | 값 | 뜻
TYPE | SESSION | 새 세션만 다시 만든다
TYPE | SELECT | 세션을 다시 만들고 열려 있던 커서를 다시 실행해 이미 받은 행 다음부터 이어 준다
TYPE | NONE | TAF를 쓰지 않는다
METHOD | BASIC | 장애가 난 뒤에 다시 접속한다
METHOD | PRECONNECT | 처음부터 BACKUP 기술자로 예비 연결을 하나 더 맺어 둔다
RETRIES / DELAY | 숫자 | 재접속 시도 횟수와 간격(초)
@END

@H3 13.4.2  서버 쪽 설정

@CODE
srvctl modify service -db racdb -service ch16_lb \
       -failovertype SELECT -failovermethod BASIC \
       -failoverretry 30 -failoverdelay 5 -failover_restore LEVEL1
@END

@TBL
srvctl 옵션 | 값 | 뜻
-failovertype | NONE / SESSION / SELECT / TRANSACTION / AUTO | SESSION·SELECT는 TAF, TRANSACTION은 AC, AUTO는 TAC
-failovermethod | NONE / BASIC | 서버 쪽 TAF는 BASIC만 쓴다
-failoverretry / -failoverdelay | 숫자 | 재접속 시도 횟수와 간격(초)
-failover_restore | NONE / LEVEL1 / AUTO | 재접속 후 처음 세션 상태를 복원한다. AUTO는 TAC용
@END

@B 서버에 설정하면 접속 기술자에 `FAILOVER_MODE`가 없는 EZConnect(`rac-scan:1521/서비스`) 접속에도 적용된다. 클라이언트 수백 대의 tnsnames.ora를 고치지 않고 서버 한 곳에서 관리할 수 있다.
@B `srvctl config service`의 Failover type·Failover method 항목과 `DBA_SERVICES`의 `FAILOVER_TYPE`·`FAILOVER_METHOD` 열에 같은 값이 보인다.

@H3 13.4.3  둘 다 있으면 서버가 이긴다

@P 서비스 속성과 클라이언트 `FAILOVER_MODE`가 함께 있으면 서버 쪽 서비스 속성이 우선한다. 실습 06은 이 규칙을 네 칸 실험으로 확인한다. ch16_ac는 서버에 `-failovertype TRANSACTION`이 있고 ch16_lb는 없다.

@IMG 13_precedence.png | 그림 13-3. 페일오버 유형이 정해지는 곳 — 서버 설정이 있으면 클라이언트 FAILOVER_MODE는 무시된다

@CODE
SQL> select service_name, failover_type, failover_method, failed_over
  2    from v$session where sid = sys_context('userenv','sid');
@END

@TBL
접속 | 서비스 설정 | 클라이언트 설정 | FAILOVER_TYPE | FAILOVER_METHOD
rac-scan:1521/ch16_ac | TRANSACTION | 없음 | TRANSACTIONAL | BASIC
CH16_TAF | TRANSACTION | TYPE=SELECT | TRANSACTIONAL | BASIC
rac-scan:1521/ch16_lb | 없음 | 없음 | NONE | NONE
CH16_LB_TAF | 없음 | TYPE=SELECT | SELECT | BASIC
@END

@B 서비스에만 있으면 서비스 값이 적용된다(1행). 클라이언트에만 있으면 클라이언트 값이 적용된다(4행).
@B 둘 다 있으면 서비스 값이 이긴다(2행). 클라이언트는 SELECT를 요청했지만 세션에는 TRANSACTIONAL이 협상되었다.
@B 서비스에는 `TRANSACTION`으로 넣지만 `V$SESSION`에는 `TRANSACTIONAL`로 나온다. 점검 스크립트로 두 값을 비교할 때 표기 차이를 감안한다.
@B 애플리케이션 팀이 tnsnames.ora를 보고 판단한 동작과 실제 동작이 다를 수 있다. 적용된 값은 설정 파일이 아니라 `V$SESSION`으로 확인한다. 의도와 다르면 클라이언트 쪽 `FAILOVER_MODE`를 지우거나 서비스 속성을 바꾼다.

@H3 13.4.4  TAF의 한계

@B 진행 중이던 트랜잭션은 롤백된다. 장애 뒤 첫 호출에서 ORA-25402(transaction must roll back)를 받으면 애플리케이션이 ROLLBACK을 하고 트랜잭션을 처음부터 다시 실행해야 한다.
@B `ALTER SESSION` 설정, PL/SQL 패키지 상태, 임시 테이블 내용은 새 세션에 따라오지 않는다. `-failover_restore LEVEL1`이나 OCI 페일오버 콜백으로 일부를 복원한다.
@B OCI 기반 클라이언트만 지원한다. JDBC Thin 드라이버는 TAF를 쓰지 못하며 FCF나 AC를 쓴다.
@B 세션이 끊긴 것을 클라이언트가 알아야 동작하므로, 노드가 통째로 멈춘 경우에는 TCP 타임아웃만큼 늦어질 수 있다. FAN과 함께 쓰는 이유다.
@B `V$SESSION.FAILED_OVER`는 평상시 NO이고 실제로 재접속이 일어난 세션에서 YES가 된다. 실습의 네 칸 측정은 장애 없이 했으므로 모두 NO였다.

@H2 13.5  FAN과 FCF

@P FAN(Fast Application Notification)은 서비스·인스턴스·노드의 상태가 바뀌면 Clusterware가 이벤트를 만들어 구독자에게 즉시 알리는 구조다. 클라이언트는 TCP 타임아웃을 기다리지 않고 죽은 인스턴스로 향한 연결을 바로 정리한다.

@IMG 13_ons.png | 그림 13-4. FAN 이벤트의 흐름 — ONS가 노드끼리 6200 포트로 이벤트를 나누고 원격 클라이언트도 6200으로 구독한다

@H3 13.5.1  ONS

@CODE
[grid@rac1 ~]$ srvctl config nodeapps -onsonly
ONS exists: Local port 6100, remote port 6200, EM port 2016, Uses SSL true
[grid@rac1 ~]$ netstat -tlnp | grep -E '6100|6200'
tcp   0  0 127.0.0.1:6100    0.0.0.0:*   LISTEN   23152/ons
tcp6  0  0 ::1:6100          :::*        LISTEN   23152/ons
tcp6  0  0 :::6200           :::*        LISTEN   23152/ons
@END

@B ONS(Oracle Notification Service)는 노드마다 도는 데몬이며 `srvctl status nodeapps`에 나온다.
@B 로컬 포트 6100은 루프백에만 열려 같은 노드의 프로세스가 붙는다. 원격 포트 6200은 모든 주소에서 받아 다른 노드의 ONS와 원격 클라이언트가 붙는다. 방화벽에서는 6200만 연다.
@B `onsctl`은 PATH에 없으므로 `/u01/app/19.3.0/grid/opmn/bin/onsctl ping`처럼 전체 경로로 실행한다.
@B `onsctl debug`의 `Servers:` 절에 상대 노드(rac2에서 보면 172.16.225.101:6200)가 있어야 한쪽 이벤트가 다른 쪽으로 간다. DEFER가 계속 늘면 상대에게 보내지 못하고 쌓이는 것이다.
@B `/u01/app/19.3.0/grid/opmn/conf/ons.config`의 항목에는 `# line added by Agent` 주석이 붙어 있다. Clusterware 에이전트가 관리하는 파일이므로 직접 고치지 않고 `srvctl modify nodeapps`를 쓴다.

@H3 13.5.2  FAN 이벤트

@TBL
이벤트 유형 | 대상 | 주요 상태
SERVICEMEMBER | 인스턴스 하나의 서비스 | UP, DOWN
SERVICE | 서비스 전체 | UP, DOWN
INSTANCE / DATABASE | 인스턴스, 데이터베이스 | UP, DOWN
NODE | 노드 | NODEDOWN
SERVICEMETRICS | 서비스별 부하 권고 | 인스턴스별 비율(13.6절)
@END

@B 이벤트에는 reason이 붙는다. FAILURE는 계획되지 않은 장애, USER는 `srvctl`로 관리자가 한 작업이다. 풀은 FAILURE면 그 인스턴스 연결을 즉시 버리고, USER면 사용 중인 연결이 반납되기를 기다렸다가 닫는다.
@B UP 이벤트도 중요하다. 인스턴스가 돌아오면 풀이 그쪽으로 새 연결을 만들어 부하를 다시 나눈다.
@B 서버 쪽 콜아웃으로도 받을 수 있다. Grid 홈의 `racg/usrco` 디렉터리에 실행 파일을 두면 이벤트마다 호출되어 알림이나 기록에 쓸 수 있다.

@H3 13.5.3  FCF — 커넥션 풀이 FAN을 쓰는 방식

@B FCF(Fast Connection Failover)는 FAN 이벤트를 구독하는 커넥션 풀의 기능이다. DOWN 이벤트를 받으면 죽은 인스턴스의 연결을 풀에서 즉시 정리하고, 그 연결을 쓰던 스레드는 기다리지 않고 바로 오류를 받는다.
@B UCP는 `setFastConnectionFailoverEnabled(true)`로 켜고, ODP.NET은 접속 문자열의 `HA Events=true`로 켜며, OCI 세션 풀은 이벤트 모드로 환경을 만든다. 12c 이후 클라이언트는 접속할 때 서버에서 ONS 구성을 받아 오므로 원격 ONS 주소를 따로 적지 않아도 되는 경우가 많다.
@B OCI 계열 클라이언트에 FAN을 보내려면 서비스의 `-notification TRUE`가 필요하다. `srvctl config service`에는 `AQ HA notifications: true`로, `DBA_SERVICES`에는 `AQ_HA_NOTIFICATIONS=YES`로 보인다. 기본값은 FALSE다.
@B FCF는 진행 중이던 작업을 살려 주지 않는다. 애플리케이션은 오류를 받고 재시도 로직으로 다시 실행한다. 작업까지 이어 주는 것은 13.7절의 AC다.

@BP 서버만 준비하면 FAN은 아무 일도 하지 않는다
ONS가 잘 돌아도 클라이언트가 구독하지 않으면 장애 때 클라이언트는 여전히 TCP 타임아웃을 기다린다. FAN 도입은 서비스 속성, 클라이언트 드라이버와 풀 설정, 방화벽 6200 포트를 함께 다루는 작업이다.
점검은 세 단계다. `onsctl ping`으로 데몬, `onsctl debug`로 상대 노드, 클라이언트 풀 로그로 이벤트 수신을 확인한다.
@END

@H2 13.6  부하 분산 권고

@P 12장의 Connection Load Balancing Goal은 새 접속을 맺는 순간에 작동한다. 커넥션 풀처럼 연결을 미리 열어 두는 구조에서는 이미 열린 연결 가운데 어느 것을 쓸지가 더 중요하다. 이 선택을 돕는 것이 Runtime Load Balancing(RLB)이다.

@TBL
설정 | 작동 시점 | 값 | 기본값
-clbgoal | 리스너가 새 접속을 넘길 때 | SHORT / LONG | LONG
-rlbgoal | 풀이 열린 연결 중 하나를 고를 때 | NONE / SERVICE_TIME / THROUGHPUT | NONE
@END

@CODE
[oracle@rac1 ~]$ srvctl add service -d racdb -s ch16_lb -preferred racdb1,racdb2 \
>      -clbgoal SHORT -rlbgoal SERVICE_TIME -notification TRUE
SQL> select inst_id, service_name, goodness, delta
  2    from gv$servicemetric where service_name in ('ch16_lb','racdb');
   INST_ID SERVICE_NAME   GOODNESS      DELTA
         1 ch16_lb             100        100
         2 ch16_lb             100        100
         1 racdb                 0          1
@END

@B 선호를 둘 지정해 Cardinality가 2다. 한 인스턴스가 죽어도 남은 쪽에서 계속 돌므로 가용 인스턴스가 비어 있다.
@B rlbgoal을 지정한 ch16_lb만 GOODNESS가 계산된다. 0은 나쁘다는 뜻이 아니라 계산하지 않는다는 뜻이다. 데이터베이스는 이 값을 SERVICEMETRICS FAN 이벤트로 풀에 보내고, 풀은 비율에 따라 연결을 고른다.
@B `GV$SERVICEMETRIC`에는 약 60초 구간(GROUP_ID 6)과 약 5초 구간(GROUP_ID 10) 집계가 섞여 있으므로 GROUP_ID로 걸러 본다. CPUPERCALL·DBTIMEPERCALL은 rlbgoal과 무관하게 채워져 인스턴스별 부하 비교에 쓸 수 있다.
@B `DBA_SERVICES`에서는 GOAL 열이 rlbgoal, CLB_GOAL 열이 clbgoal이다. 옵션 이름과 열 이름이 다르다.
@B rlbgoal의 효과는 FAN을 구독하는 커넥션 풀이 있어야 나타난다. SQL*Plus로 붙었다 끊는 방식으로는 GOODNESS가 계산된다는 사실까지만 확인할 수 있다.

@H2 13.7  Application Continuity와 TAC

@P AC는 장애로 끊긴 요청을 새 인스턴스에서 다시 실행해, 애플리케이션이 오류 대신 약간의 지연만 겪게 하는 기능이다. 가장 어려운 문제는 커밋을 보냈는데 응답을 못 받은 경우다. 다시 실행하면 중복될 수 있고, 안 하면 누락될 수 있다. AC는 Transaction Guard로 이 문제를 먼저 푼다.

@IMG 13_ac.png | 그림 13-5. AC의 재생 — 커밋 결과를 LTXID로 확인한 뒤, 커밋되지 않은 요청만 새 인스턴스에서 재생한다

@H3 13.7.1  Transaction Guard

@B `-commit_outcome TRUE`를 켜면 트랜잭션마다 논리 트랜잭션 ID(LTXID)가 붙고 커밋 결과가 `-retention` 동안 보관된다.
@B 끊긴 뒤 드라이버는 `DBMS_APP_CONT.GET_LTXID_OUTCOME`으로 그 LTXID가 커밋되었는지 묻는다. 커밋되었으면 재생하지 않고 결과를 돌려주고, 아니면 재생한다.
@B 애플리케이션이 직접 결과를 조회하려면 사용자에게 `DBMS_APP_CONT` 실행 권한이 필요하다. 실습 환경에는 `DBMS_APP_CONT` 패키지가 VALID 상태로 있다.

@H3 13.7.2  AC 서비스 속성

@CODE
[oracle@rac1 ~]$ srvctl add service -d racdb -s ch16_ac \
>      -preferred racdb1 -available racdb2 \
>      -failovertype TRANSACTION -commit_outcome TRUE \
>      -failover_restore LEVEL1 -replay_init_time 600 \
>      -retention 86400 -session_state DYNAMIC \
>      -failoverretry 30 -failoverdelay 10 -notification TRUE
@END

@TBL
옵션 | 뜻 | 실습 값
-failovertype TRANSACTION | AC를 켠다 | TRANSACTION
-commit_outcome TRUE | Transaction Guard를 켠다. AC에 필수 | TRUE
-failover_restore | 재접속 후 세션 상태(NLS 등)를 복원 | LEVEL1
-replay_init_time | 요청이 시작된 뒤 이 초가 지나면 재생하지 않음 | 600
-retention | 커밋 결과 보관 시간(초) | 86400
-session_state | 세션 상태 일관성. DYNAMIC은 요청 중 상태가 바뀔 수 있다고 보고 추적 | DYNAMIC
-failoverretry / -failoverdelay | 재접속 시도 횟수와 간격 | 30 / 10
-notification TRUE | FAN 이벤트 전달 | TRUE
@END

@CODE
[oracle@rac1 ~]$ srvctl add service -d racdb -s ch16_bad \
>      -preferred racdb1 -available racdb2 -failovertype TRANSACTION
PRCD-1259 : Addition or modification of failover type to TRANSACTION is not allowed
            when commit outcome is set to FALSE
@END

@B `-commit_outcome TRUE` 없이 TRANSACTION을 지정하면 PRCD-1259로 거부되고 서비스는 만들어지지 않는다. 커밋 여부를 모르면 안전하게 재생할 수 없기 때문이다.
@B `-failovertype FOO`나 `-rlbgoal FASTEST`처럼 목록에 없는 값은 PRKO-3125다. PRKO-3125는 값이 틀린 문법 오류, PRCD-1259는 값은 맞는데 조합이 안 되는 의미 오류다.

@H3 13.7.3  TAC — 19c의 Transparent Application Continuity

@CODE
srvctl modify service -db racdb -service ch16_ac \
       -failovertype AUTO -failover_restore AUTO -commit_outcome TRUE
@END

@B TAC는 AC의 한 방식이다. AC는 커넥션 풀이 요청의 시작과 끝(request boundary)을 표시하고 애플리케이션이 세션 상태 사용을 맞춰야 하지만, TAC는 드라이버와 서버가 세션 상태를 자동으로 추적해 재생할 수 있는 지점을 스스로 찾는다.
@B 19c 이상 클라이언트 드라이버가 필요하다. 세션 상태를 확실히 알 수 없는 구간에서는 재생을 끄고, 다시 알 수 있게 되면 재생을 켠다.
@B 애플리케이션을 고칠 여지가 적을 때 TAC를 먼저 검토하고, 커넥션 풀과 요청 경계를 갖춘 애플리케이션이면 AC(TRANSACTION)를 쓴다.

@H3 13.7.4  재생되는 것과 재생되지 않는 것

@TBL
조건 | 재생 여부
서비스에 TRANSACTION 또는 AUTO, commit_outcome TRUE | 재생 가능
끊긴 시점이 replay_init_time 안 | 재생 가능. 넘으면 재생하지 않음
커밋되지 않은 요청 | 재생. 이미 커밋된 것은 결과만 돌려줌
UTL_HTTP·UTL_FILE·UTL_SMTP 같은 외부 부수 효과 | 재생하면 두 번 일어나므로 피하거나 멱등하게 만든다
ALTER SYSTEM, ALTER DATABASE | 재생하지 않음
SYSDATE·SYSTIMESTAMP·SYS_GUID·시퀀스 값 | 값이 달라짐. KEEP 권한으로 원래 값을 유지
재생 결과가 처음과 다름 | 재생을 중단하고 원래 오류를 돌려줌
@END

@B 결정적이지 않은 함수는 `GRANT KEEP DATE TIME TO <사용자>`, `GRANT KEEP SYSGUID TO <사용자>`, 시퀀스의 `KEEP` 속성으로 재생 때 원래 값을 쓰게 할 수 있다.
@B `V$SESSION`의 FAILOVER_TYPE이 TRANSACTIONAL이라는 것은 협상되었다는 뜻이지 재생 성공을 보장하지 않는다. 드라이버가 호출을 기록하고 있어야 재생된다.
@B 검증은 세 단계다. `srvctl config service`로 설정, `V$SESSION`으로 협상, 시험 환경에서 인스턴스를 강제로 죽여 FAILED_OVER가 YES로 바뀌면서 애플리케이션에 오류가 없는지 본다. 마지막 단계는 재생 드라이버를 쓰는 애플리케이션이 있어야 하므로 SQL*Plus로는 재현하지 못한다.

@CASE AC를 켰다는 보고를 받았는데 장애 때 오류가 쏟아졌다
DBA가 서비스에 `-failovertype TRANSACTION`과 `-commit_outcome TRUE`를 넣고 `srvctl config service` 출력을 보고서에 붙였다. 몇 달 뒤 노드 장애에서 애플리케이션은 오류를 그대로 받았다.
애플리케이션은 JDBC Thin 드라이버의 일반 데이터 소스를 쓰고 있어 호출을 기록하지 않았다. 배치는 외부 HTTP 호출을 트랜잭션 안에서 하고 있었다. 서버 설정은 시작일 뿐이고 드라이버 선택, 코드 검토, 장애 시험까지가 AC 도입이다.
@END

@H2 13.8  운영 지침

@H3 13.8.1  설정 선택 기준

@TBL
상황 | 권장 설정
모든 접속 기술자 | SCAN + 서비스, CONNECT_TIMEOUT·TRANSPORT_CONNECT_TIMEOUT·RETRY_COUNT
커넥션 풀을 쓰는 OLTP | FAN(-notification TRUE) + FCF, rlbgoal SERVICE_TIME
OCI 기반 조회 위주 애플리케이션 | 서버 쪽 TAF -failovertype SELECT -failovermethod BASIC
장애 때 오류 없이 이어져야 함, 재생 드라이버 사용 | -failovertype TRANSACTION -commit_outcome TRUE
코드 수정 여지가 적은 19c 클라이언트 | -failovertype AUTO -failover_restore AUTO -commit_outcome TRUE
@END

@H3 13.8.2  점검 항목

@TBL
주기 | 확인 항목 | 명령
매일 | ONS 데몬 생존(양 노드) | `onsctl ping`
주간 | ONS가 상대 노드를 잡고 있는가 | `onsctl debug`의 Servers 절과 DEFER
주간 | 서비스의 페일오버·부하 설정 | `srvctl config service`와 `dba_services` 비교
변경 후 | 세션에 실제로 협상된 유형 | `v$session`의 failover_type, failover_method
분기 | 장애 재현 검증 | 시험 환경에서 인스턴스를 강제 종료하고 애플리케이션 반응 확인
@END

@B 실습에서 만든 ch16_lb·ch16_ac는 정지 후 삭제하고, tnsnames.ora는 `cp -p`로 만든 백업에서 되돌려 원래 크기(341바이트)인지 확인한다.

@H2 13.9  요약

@B 클라이언트 페일오버는 Connect-Time Failover(새 접속), TAF(세션 재접속), FAN·FCF(서버 알림으로 즉시 정리), AC·TAC(요청 재생) 네 가지이며 겹쳐 쓴다.
@B Connect-Time Failover는 `FAILOVER`·`LOAD_BALANCE`와 타임아웃 파라미터로 구성하고, SCAN 이름은 IP 목록(실습 환경은 1개)으로 풀린다.
@B TAF는 클라이언트 `FAILOVER_MODE`나 서버 `-failovertype SESSION|SELECT -failovermethod BASIC`으로 켠다. 둘 다 있으면 서버 쪽이 우선하며 실제 값은 `V$SESSION`으로 확인한다.
@B TAF는 진행 중 트랜잭션을 롤백하고 OCI 기반 클라이언트만 지원한다.
@B FAN 이벤트는 ONS(로컬 6100, 원격 6200)가 나르고, FCF는 FAN을 받은 풀이 끊긴 연결을 즉시 정리하는 기능이다. OCI 계열에는 `-notification TRUE`가 필요하다.
@B rlbgoal을 켜면 `V$SERVICEMETRIC`의 GOODNESS가 계산되어 풀에 전달된다.
@B AC는 `-failovertype TRANSACTION -commit_outcome TRUE`, TAC는 `-failovertype AUTO -failover_restore AUTO`다. Transaction Guard로 커밋 여부를 확인한 뒤 커밋되지 않은 요청만 재생한다.

@H2 13.10  퀴즈

@QUIZ 퀴즈
1. 네 가지 클라이언트 페일오버 가운데 이미 맺어진 세션에 아무 일도 하지 않는 것은? 나머지 셋은 장애를 누가 감지하는가?
2. `TRANSPORT_CONNECT_TIMEOUT`을 짧게 두는 이유와, 실습 환경의 SCAN이 IP 하나인데도 SCAN 접속이 계속되는 이유를 쓰시오.
3. ch16_ac(서버 TRANSACTION)에 클라이언트 `TYPE=SELECT`로 접속했을 때 `V$SESSION.FAILOVER_TYPE`은? 그 이유는?
4. TAF로 재접속한 세션이 진행 중이던 트랜잭션은 어떻게 되며 애플리케이션은 무엇을 해야 하는가?
5. FAN 이벤트의 reason이 FAILURE일 때와 USER일 때 커넥션 풀의 처리는 어떻게 다른가?
6. `-failovertype TRANSACTION`만 지정했을 때 나는 오류와, AC에 `-commit_outcome TRUE`가 필요한 이유는?
@END

@NOTE 정답과 해설
1. Connect-Time Failover. TAF는 클라이언트 OCI 계층이 끊김을 겪은 뒤 감지하고, FAN·FCF는 서버(Clusterware)가 이벤트로 먼저 알리며, AC는 드라이버가 오류나 FAN으로 감지하고 서버의 Transaction Guard로 커밋 여부를 확인한다.
2. 응답 없는 주소에서 운영체제 TCP 타임아웃만큼 머물지 않게 하려는 것이다. 실습 환경은 SCAN VIP가 살아 있는 노드로 옮겨 가므로 같은 IP로 계속 접속할 수 있다.
3. TRANSACTIONAL. 서버 쪽 서비스 속성이 클라이언트 FAILOVER_MODE보다 우선하기 때문이다.
4. 롤백된다. ORA-25402를 받으면 애플리케이션이 ROLLBACK 후 트랜잭션을 처음부터 다시 실행한다.
5. FAILURE면 그 인스턴스의 연결을 즉시 정리하고, USER(계획 작업)면 사용 중인 연결이 반납되기를 기다렸다가 닫는다.
6. PRCD-1259. 커밋을 보내고 응답을 못 받은 요청을 재생하면 중복될 수 있으므로, Transaction Guard로 커밋 여부를 먼저 확인해야 안전하게 재생할 수 있다.
@END

@H2 13.11  실습 개요

@P 실습 02와 04에서 서비스 ch16_lb·ch16_ac를 만들고 06에서 페일오버 유형을 측정한 뒤 모두 정리한다. 인스턴스를 죽이는 실습은 없다. TAF 재접속, FCF, TAC 재생은 재생 드라이버를 쓰는 애플리케이션이 필요해 트랜스크립트에 측정이 없고, 이 장의 본문은 구성 문법까지 다룬다.

@TBL
실습 | 파일 | 목적
01 ★ | RAC/16장/16장_실습_01_FAN이벤트확인.txt | ONS 포트·onsctl ping·debug·ons.config로 FAN 전달 경로를 확인한다
02 | RAC/16장/16장_실습_02_부하분산권고.txt | clbgoal·rlbgoal 서비스를 만들고 V$SERVICEMETRIC의 GOODNESS를 확인한다
04 | RAC/16장/16장_실습_04_AC설정과속성확인.txt | AC 서비스 속성을 지정하고 srvctl config·DBA_SERVICES·DBMS_APP_CONT를 확인한다
06 | RAC/16장/16장_실습_06_페일오버유형과정리.txt | 서버·클라이언트 설정 네 칸 실험으로 우선순위를 확인하고 서비스와 tnsnames.ora를 정리한다
@END

@B ★는 두 노드에서 각각 명령을 실행하는 실습이다. 스냅샷이 필요한 실습은 없다.
@B 실습 06은 tnsnames.ora를 고치므로 시작 전에 `cp -p tnsnames.ora tnsnames.ora.ch16bak`으로 백업하고 끝에서 되돌린다.
@B 수료 후 자습: 16장_실습_03_접속부하분산실측, 16장_실습_05_오류재현_AC필수조합.
