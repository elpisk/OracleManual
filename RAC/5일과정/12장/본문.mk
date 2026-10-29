@H1 제12장  동적 데이터베이스 서비스

@H2 12.1  학습 목표

@P 10장에서 스레드별 리두 발생량을 비교하며 부하가 한 노드에 몰릴 수 있음을 봤다. 리두나 UNDO 크기를 키우는 것으로는 편중이 풀리지 않는다. 접속 자체를 나눠야 하고, 그 도구가 서비스다. 서비스는 어떤 접속을 어느 인스턴스가 받을지 정하는 이름이며 클라이언트는 인스턴스가 아니라 이 이름에 접속한다. 이 장은 서비스를 만들고, 배치를 확인하고, 옮기고, 장애 때 어떻게 움직이는지를 다룬다.

@B 기본 서비스와 사용자 서비스를 구분하고 로컬 리스너와 SCAN 리스너의 서비스 등록 차이를 읽을 수 있다.
@B 선호(preferred)와 가용(available) 인스턴스를 지정해 서비스를 만들고 그 정의를 `srvctl config service`로 해석할 수 있다.
@B `srvctl relocate service`가 새 접속과 기존 세션에 미치는 영향을 설명할 수 있다.
@B 계획된 정지(`-force`)와 실제 장애(프로세스 강제 종료)에서 서비스가 다르게 움직이는 이유를 설명하고 올바른 계획 정지 순서를 쓸 수 있다.
@B SCAN을 통한 접속 분산이 부하 기반이며 두 층으로 이뤄진다는 것을 설명할 수 있다.

@H2 12.2  서비스란 무엇인가

@P 서비스는 인스턴스와 클라이언트 사이에 두는 이름표다. 이름표를 다른 인스턴스로 옮기면 접속이 따라가고, 클라이언트는 접속 문자열을 바꾸지 않는다.

@IMG 12_service.png | 그림 12-1. 서비스는 이름표다 — 두 서비스의 선호 인스턴스를 엇갈리게 두고 서로를 가용 인스턴스로 둔다

@H3 12.2.1  이미 있는 서비스

@CODE
SQL> select inst_id, name, con_id from gv$active_services order by inst_id, name;

   INST_ID NAME                 CON_ID
---------- -------------------- ------
         1 SYS$BACKGROUND            1
         1 SYS$USERS                 1
         1 racdb                     1
         1 racdbXDB                  1
         1 racpdb1                   3
         2 SYS$BACKGROUND            1
         ...
10 rows selected.
@END

@B 사용자 서비스가 없어도 다섯 서비스가 인스턴스마다 하나씩 있다. `srvctl status service -d racdb`는 아무것도 출력하지 않고 종료 코드 0으로 끝난다. 사용자 서비스가 없다는 뜻이다.
@B `SYS$BACKGROUND`는 백그라운드 프로세스, `SYS$USERS`는 서비스 이름 없이 접속한 세션이 속하는 내부 서비스다.
@B `racdb`는 데이터베이스 이름과 같은 기본 서비스, `racdbXDB`는 XML DB용, `racpdb1`은 PDB를 만들 때 자동으로 생긴 PDB 서비스(CON_ID 3)다.
@B 루트에서 `DBA_SERVICES`를 조회하면 racpdb1이 나오지 않는다. 이 뷰는 현재 컨테이너의 서비스만 보여 준다.

@H3 12.2.2  리스너에서 본 서비스

@CODE
[grid@rac1 ~]$ lsnrctl status LISTENER
Service "racdb" has 1 instance(s).
  Instance "racdb1", status READY, has 1 handler(s) for this service...
[grid@rac1 ~]$ lsnrctl status LISTENER_SCAN1
Service "racdb" has 2 instance(s).
  Instance "racdb1", status READY, has 1 handler(s) for this service...
  Instance "racdb2", status READY, has 1 handler(s) for this service...
@END

@B rac1의 노드 리스너는 공용 IP 172.16.225.101과 VIP 172.16.225.111을 함께 듣고, 그 노드의 racdb1만 등록되어 있다.
@B SCAN 리스너(172.16.225.120)에는 두 인스턴스가 모두 등록되어 있다. 클라이언트가 SCAN에 접속하면 SCAN 리스너가 그 서비스를 제공하는 인스턴스의 노드 리스너로 연결을 넘긴다.
@B 진단할 때 두 리스너를 구분한다. 노드 리스너에 서비스가 없으면 그 노드의 인스턴스가 등록하지 않은 것이고, SCAN 리스너에 없으면 클러스터 어디에서도 그 서비스가 돌지 않는 것이다.

@H3 12.2.3  서비스를 두는 이유

@TBL
목적 | 서비스가 하는 일
부하 분리 | OLTP는 rac1, 배치는 rac2처럼 업무별로 인스턴스를 나눈다
분류와 추적 | `GV$SESSION.SERVICE_NAME`으로 세션의 출처를 구분한다
장애 대응 | 선호 인스턴스가 죽으면 가용 인스턴스로 옮겨 간다
유지보수 | 노드를 내리기 전에 서비스를 옮겨 새 접속을 비운다
@END

@H2 12.3  서비스 생성

@P 서비스를 만들 때 정하는 것은 두 가지다. 평소 어느 인스턴스에서 돌 것인가(선호), 그 인스턴스가 사라지면 어디로 갈 것인가(가용).

@CODE
[oracle@rac1 ~]$ srvctl add service -d racdb -s ch15_oltp -preferred racdb1 -available racdb2
[oracle@rac1 ~]$ srvctl add service -d racdb -s ch15_batch -preferred racdb2 -available racdb1
[grid@rac1 ~]$ crsctl stat res -t | grep -A1 'ora.racdb.ch15'
ora.racdb.ch15_batch.svc
      1        OFFLINE OFFLINE                               STABLE
ora.racdb.ch15_oltp.svc
      1        OFFLINE OFFLINE                               STABLE
@END

@B 두 서비스의 선호를 엇갈리게 두고 서로를 가용으로 지정했다. 평소에는 나뉘어 돌고 한쪽이 죽으면 남은 쪽이 둘 다 받는 기본형이다.
@B 성공하면 아무것도 출력하지 않는다. 만들어진 서비스는 `ora.<DB>.<서비스>.svc` 이름의 Clusterware 자원이 되며 11장의 자원 모델을 그대로 따른다.
@B 일반 자원 수가 17개에서 19개로 늘었다. 만들기만 하고 기동하지 않아 TARGET과 STATE가 OFFLINE이다.
@B 19c 긴 옵션으로는 `srvctl add service -db racdb -service ch15_oltp -preferred racdb1 -available racdb2`다.

@H3 12.3.1  잘못된 정의는 저장되지 않는다

@CODE
[oracle@rac1 ~]$ srvctl add service -d racdb -s ch15_bad -preferred racdb9 -available racdb2
PRKO-2101 : Failed to find database instances racdb9
[oracle@rac1 ~]$ srvctl add service -d nodb -s ch15_bad2 -preferred racdb1
PRCD-1120 : The resource for database nodb could not be found.
PRCR-1001 : Resource ora.nodb.db does not exist
@END

@B 없는 인스턴스를 선호로 지정하면 서비스를 만들기 전에 PRKO-2101로 거부된다. 잘못된 정의가 저장되었다가 기동할 때 드러나는 것보다 낫다.
@B 없는 데이터베이스를 지정하면 PRCD-1120과 PRCR-1001이 겹쳐 나온다. 11장의 규칙대로 아래 줄이 원인이다.

@H3 12.3.2  config로 본 서비스 정의

@CODE
[oracle@rac1 ~]$ srvctl config service -d racdb -s ch15_oltp
Service name: ch15_oltp
Cardinality: 1
Service role: PRIMARY
Management policy: AUTOMATIC
AQ HA notifications: false
Commit Outcome: false
Failover type:
Failover restore: NONE
Connection Load Balancing Goal: LONG
Runtime Load Balancing Goal: NONE
Pluggable database name:
Preferred instances: racdb1
Available instances: racdb2
@END

@TBL
항목 | 뜻
Cardinality: 1 | 한 번에 한 인스턴스에서만 돈다. 선호를 둘 지정하면 2가 된다
Service role: PRIMARY | 데이터베이스가 프라이머리일 때만 돈다. Data Guard 스탠바이용은 PHYSICAL_STANDBY
Management policy: AUTOMATIC | 데이터베이스가 뜰 때 함께 뜬다
Connection Load Balancing Goal: LONG | SCAN이 접속을 나눌 때 세션 수 기준. SHORT는 응답 시간 기준
Failover·Commit Outcome·AQ HA | 클라이언트 페일오버 설정. 13장에서 채운다
Pluggable database name | 비어 있으면 CDB 루트에 붙는 서비스
@END

@BP PDB 서비스로 만든다
CDB 환경에서는 `-pdb racpdb1`을 지정해 서비스를 PDB에 붙인다. 그 서비스로 접속하면 곧바로 PDB 안이고, PDB를 다른 CDB로 옮겨도 서비스 이름만 유지하면 클라이언트를 바꾸지 않는다.
실습 트랜스크립트는 지정하지 않아 루트에 붙은 서비스로 진행했다. 운영에서는 `srvctl add service -db racdb -service <이름> -pdb racpdb1 -preferred racdb1 -available racdb2` 형태를 쓴다.
@END

@H3 12.3.3  서비스 명령 모음

@TBL
명령 | 하는 일 | 바뀌는 것
`srvctl add service` | 서비스 정의를 만든다 | 정의, 자원 추가
`srvctl start service` / `stop service` | 서비스를 기동·정지한다 | 상태
`srvctl relocate service` | 실행 위치를 다른 인스턴스로 옮긴다 | 상태만
`srvctl modify service -modifyconfig` | 선호·가용 목록을 다시 지정한다 | 정의
`srvctl modify service`(속성 옵션) | CLB goal, 페일오버 속성 등을 바꾼다 | 정의
`srvctl enable` / `disable service` | 자동 기동 대상에 넣고 뺀다 | 정의
`srvctl remove service` | 정의를 지운다(정지 후) | 정의, 자원 삭제
@END

@B 상태만 바꾸는 명령과 정의를 바꾸는 명령을 구분한다. 재기동 뒤에도 유지되어야 하는 변경은 정의를 바꾸는 명령으로 한다.
@B 정의를 바꾼 뒤에는 `srvctl config service`로 확인하고, 실행 중인 서비스라면 `srvctl status service`로 현실이 정의를 따라왔는지 함께 본다.
@B 서비스 속성 가운데 페일오버 관련 항목(`-failovertype`, `-commit_outcome`, `-notification` 등)은 다음 장의 주제다.

@H2 12.4  기동과 배치 확인

@CODE
[oracle@rac1 ~]$ srvctl start service -d racdb -s ch15_oltp
[oracle@rac1 ~]$ srvctl start service -d racdb -s ch15_batch
[oracle@rac1 ~]$ srvctl status database -d racdb -v
Instance racdb1 is running on node rac1 with online services ch15_oltp. Instance status: Open.
Instance racdb2 is running on node rac2 with online services ch15_batch. Instance status: Open.
@END

@B 서비스가 선호 인스턴스에서 떴다. `status database -v`가 인스턴스와 서비스를 한 번에 보여 주므로 장애 대응의 첫 명령으로 쓸 만하다.
@B `GV$ACTIVE_SERVICES`에서 ch15_oltp는 INST_ID 1, ch15_batch는 2에만 나온다. `srvctl status`는 Clusterware가 아는 배치, 이 뷰는 인스턴스가 아는 배치이며 둘이 일치해야 정상이다.
@B rac1 노드 리스너에는 ch15_oltp만 있고, SCAN 리스너에는 둘 다 있지만 각각 `has 1 instance(s)`다. SCAN이 ch15_oltp 접속을 받으면 racdb1로만 넘길 수 있다.

@CODE
[oracle@rac1 ~]$ for i in $(seq 10); do
>   sqlplus -s system/<SYSTEM 비밀번호>@rac-scan:1521/ch15_oltp <<'EOS'
set head off feed off pages 0
select instance_name from v$instance;
exit
EOS
> done | grep -v '^$' | sort | uniq -c
     10 racdb1
@END

@B SCAN을 통해 열 번 붙어 열 번 모두 선호 인스턴스에 앉았다. ch15_batch로 같은 확인을 하면 열 번 모두 racdb2다.
@B 접속 확인은 반드시 SCAN 주소로 한다. 노드 리스너 주소로 붙으면 그 노드의 인스턴스에만 갈 수 있어 서비스 배치를 검증할 수 없다.

@BP 접속 확인 스크립트를 하나 둔다
서비스 이름을 인자로 받아 SCAN으로 여러 번 접속하고 `v$instance`의 인스턴스 이름을 세는 스크립트면 충분하다. 실습 07의 `/tmp/svc_check.sh`가 그 형태다.
서비스를 만들거나 옮길 때마다 이 스크립트로 확인한다. `srvctl status`와 `GV$ACTIVE_SERVICES`가 맞아도 클라이언트 쪽 설정이나 이름 해석 문제로 실제 접속이 다르게 갈 수 있다.
@END

@H2 12.5  서비스 이동

@IMG 12_relocate.png | 그림 12-2. relocate는 새 접속의 방향만 바꾼다 — 이미 붙어 있던 세션은 원래 인스턴스에서 작업을 마친다

@CODE
[oracle@rac1 ~]$ srvctl relocate service -d racdb -s ch15_oltp -oldinst racdb1 -newinst racdb2
[oracle@rac1 ~]$ srvctl status service -d racdb
Service ch15_batch is running on instance(s) racdb2
Service ch15_oltp is running on instance(s) racdb2
@END

@B `-oldinst`와 `-newinst`를 함께 지정한다. 지금 어디에 있는지 명시하게 하는 안전장치이며 여러 인스턴스에서 도는 서비스라면 어느 것을 옮길지 특정해야 한다.
@B 이동은 2초 안팎에 끝났고, 이후 SCAN으로 붙은 새 접속은 모두 racdb2로 갔다.
@B 이동 직전에 붙어 45초 동안 대기하던 세션은 이동 뒤에도 같은 인스턴스(racdb1), 같은 SID로 작업을 마쳤다. relocate는 이미 맺어진 연결을 끊지 않는다.
@B 기존 세션까지 정리하려면 `-drain_timeout`(세션이 빠지기를 기다릴 초)과 `-stopoption`(시간이 지나면 어떻게 끊을지)을 함께 쓴다.

@CODE
srvctl relocate service -db racdb -service ch15_oltp -oldinst racdb1 -newinst racdb2 \
       -drain_timeout 120 -stopoption IMMEDIATE
@END

@B 위 형태는 새 접속을 즉시 racdb2로 돌리고, racdb1에 남은 세션이 빠지기를 최대 120초 기다린 뒤 남은 세션을 정리한다. 트랜스크립트는 두 옵션 없이 실행했으므로 기다리지도 끊지도 않았다.
@B 세션이 스스로 빠지려면 애플리케이션이 연결을 반납해야 한다. 커넥션 풀이 FAN 이벤트를 받아 연결을 정리하는 구조는 13장에서 다룬다.

@H3 12.5.1  정의는 바뀌지 않는다

@B relocate 뒤에도 `srvctl config service`의 Preferred instances는 racdb1이다. status는 바뀌고 config는 그대로다.
@B 데이터베이스를 재기동하면 서비스는 정의대로 선호 인스턴스에서 뜬다. 임시로 옮긴 배치가 재기동으로 원위치되는 셈이다.
@B 배치를 영구히 바꾸려면 `srvctl modify service -db racdb -service ch15_oltp -modifyconfig -preferred racdb2 -available racdb1`처럼 정의를 고친다.

@H2 12.6  장애 시 자동 이동

@P 같은 서비스, 같은 가용 인스턴스인데도 인스턴스가 어떻게 내려갔느냐에 따라 서비스의 운명이 갈린다.

@IMG 12_failure.png | 그림 12-3. 계획된 정지(-force)는 서비스를 함께 내리고, 실제 장애는 서비스를 가용 인스턴스로 옮긴다

@H3 12.6.1  서비스가 도는 인스턴스를 그냥 내리면

@CODE
[oracle@rac1 ~]$ srvctl stop instance -d racdb -i racdb1
PRCD-1131 : Failed to stop database racdb and its services on nodes rac1
PRCR-1133 : Failed to stop database racdb and its running services
PRCR-1132 : Failed to stop resources using a filter
CRS-2974: unable to act on resource 'ora.racdb.db' on server 'rac1' because that
would require stopping or relocating resource 'ora.racdb.ch15_oltp.svc' but the
appropriate force flag was not specified
@END

@B 네 줄이 겹쳤고 원인은 마지막 CRS-2974다. 이 인스턴스를 내리려면 그 위의 서비스 자원을 정지하거나 옮겨야 하는데 force 플래그가 없다는 뜻이다.
@B 서비스가 도는 인스턴스를 무심코 내리는 일을 막아 주는 장치다. 서비스가 없다면 이 명령은 그대로 통과한다.

@H3 12.6.2  -force로 강행하면

@B `srvctl stop instance -d racdb -i racdb1 -stopoption abort -force`는 성공했지만 ch15_oltp는 racdb2로 가지 않고 `is not running` 상태가 되었다. 60초 동안 지켜봐도 그대로였다.
@B 그동안 `rac-scan:1521/ch15_oltp`로 접속하면 ORA-12514가 났다. rac2는 살아 있는데 서비스가 없어 쓸 수 없는 상황이다.
@B `-force`는 서비스가 돌고 있어도 강행하라는 지시다. Clusterware는 관리자가 의도적으로 내린다고 보고 서비스 자원의 TARGET도 OFFLINE으로 내린다. 정상 종료한 자원은 다시 올리지 않는다는 9장의 원리와 같다.

@H3 12.6.3  실제 장애

@CODE
[root@rac1 ~]# date '+%T'; pkill -9 -f ora_pmon_racdb1
12:58:06
[oracle@rac2 ~]$ date '+%T'; srvctl status service -d racdb
12:58:16
Service ch15_batch is running on instance(s) racdb2
Service ch15_oltp is running on instance(s) racdb2
@END

@B PMON을 강제로 죽이자 10초 안에 ch15_oltp가 가용 인스턴스 racdb2로 옮겨 갔다. 비정상 종료라 TARGET이 ONLINE으로 남아 있었기 때문이다.
@B racdb1은 47초 뒤 Clusterware가 되살렸다. 그러나 서비스는 158초까지 지켜봐도 racdb2에 그대로 있었다.
@B 선호 인스턴스가 돌아와도 서비스는 자동으로 복귀하지 않는다. 옮기면 세션 배치가 다시 흔들리므로 Clusterware는 잘 돌고 있는 서비스를 건드리지 않는다. 복귀는 `srvctl relocate service ... -oldinst racdb2 -newinst racdb1`로 관리자가 한다.

@NOTE 인스턴스 기동 시간은 호스트 부하와 함께 기록한다
같은 실습에서 racdb1을 두 번 올렸는데, Clusterware가 자동으로 되살린 경우는 47초, `srvctl start instance`로 올린 경우는 122.9초였다. 명령 차이가 아니라 그 시점의 호스트 부하(loadavg 4대와 7.68) 차이였다.
기동이 오래 걸리는 동안 그 인스턴스의 서비스는 비어 있다. 계획 정지에서 서비스를 먼저 옮겨 두어야 하는 이유가 여기에도 있다. 기동 시간을 비교할 때는 `cat /proc/loadavg`를 기동 전후로 남긴다.
@END

@NOTE 자동 복귀 대신 점검으로 잡는다
선호 인스턴스로 자동 복귀하게 하는 기본 설정은 없다. `srvctl status service`의 실행 위치와 `srvctl config service`의 Preferred instances를 비교하는 점검 스크립트를 두면 어긋난 서비스를 찾아낼 수 있다.
서비스가 옮겨 가 있다는 것은 무슨 일이 있었다는 뜻이므로 원인을 확인한 뒤 사람이 되돌린다. 장애 대응 절차서의 마지막 항목에 서비스 복귀를 넣지 않으면 부하가 한 노드에 몰린 채 며칠이 지나간다.
@END

@CASE 계획 정지 절차를 한 줄로 적었을 때
야간 패치 계획서에 `srvctl stop instance -d racdb -i racdb1 -force` 한 줄만 있었다. 작업 시작과 함께 OLTP 접속이 모두 ORA-12514로 실패했다. rac2는 정상이었지만 서비스가 함께 정지되어 받을 곳이 없었다.
올바른 순서는 서비스를 먼저 옮기고, 세션이 빠질 시간을 주고, 인스턴스를 내리는 것이다. 서비스가 없는 인스턴스는 `-force` 없이 내려간다. 패치 후 인스턴스를 올린 뒤 서비스를 다시 옮겨 오는 단계까지 계획서에 넣는다.
@END

@NOTE stop instance의 -failover 옵션
19c의 `srvctl stop instance`에는 정지하면서 서비스를 다른 인스턴스로 옮기는 `-failover` 옵션이 있다. 트랜스크립트에서는 쓰지 않았으므로 도입하기 전에 `srvctl stop instance -help`로 설치 버전의 문법을 확인하고 시험 환경에서 동작을 본다.
@END

@H2 12.7  SCAN을 통한 부하 분산

@IMG 12_lb.png | 그림 12-4. 접속 분산은 두 층이다 — 서비스 배치는 관리자가, 여러 인스턴스 중 어디로 보낼지는 리스너가 정한다

@B 기본 서비스 racdb는 두 인스턴스에서 돈다. SCAN으로 20번 붙었을 때 10 대 10으로 나뉜 적이 있다.
@B racdb1을 재기동한 직후 같은 측정을 하자 20번 모두 racdb1로 갔다. 세션이 하나도 없는 인스턴스를 리스너가 덜 바쁘다고 판단한 것이다. 라운드로빈으로 번갈아 넘기는 방식과 다르다.
@B 판단 기준은 서비스의 Connection Load Balancing Goal이다. LONG(기본값)은 세션 수를, SHORT는 응답 시간을 기준으로 삼는다. 커넥션 풀처럼 오래 유지되는 접속에는 LONG, 붙었다 끊기를 반복하는 접속에는 SHORT가 맞다.
@B 분산은 시점에 따라 결과가 크게 다르므로 한 번 재고 판단하지 않는다. 접속 횟수보다 `GV$SESSION`의 인스턴스별 세션 수를 보는 편이 리스너가 보는 값에 가깝다.

@TBL
층 | 무엇을 정하는가 | 누가 정하는가 | 예
1층 | 서비스가 어느 인스턴스에서 도는가 | 관리자(선호·가용) | ch15_oltp는 racdb1에서만
2층 | 여러 인스턴스에서 도는 서비스의 새 접속을 어디로 넘기는가 | SCAN 리스너(CLB goal) | racdb는 덜 바쁜 쪽으로
@END

@B 부하를 확실히 나누려면 1층을 쓴다. 접속 수만 고르게 하려면 서비스 하나를 두 인스턴스에서 돌리는 2층으로 충분하다. 선호를 둘 다 지정하면 두 층을 함께 쓴다.

@H2 12.8  운영 지침

@H3 12.8.1  세션 분류와 정리

@CODE
SELECT inst_id, service_name, count(*) cnt
  FROM gv$session WHERE type='USER'
 GROUP BY inst_id, service_name ORDER BY 1, 2;
@END

@B `SYS$USERS`로 잡히는 세션이 많다면 접속 문자열에 서비스를 쓰지 않은 클라이언트가 있다. 그런 접속은 서비스를 옮겨도 따라오지 않으므로 찾아서 고친다.
@B 실습 서비스는 정지 후 삭제한다(`srvctl stop service` → `srvctl remove service`). 정지된 서비스로 접속하면 ORA-12514가 나는데, 그런 서비스가 없다는 뜻이 아니라 리스너가 지금 그 서비스를 모른다는 뜻이다. 원인 후보는 서비스 정지, 인스턴스 장애, 이름 오타다.
@B 정리 후 `GV$ACTIVE_SERVICES` 10행, 일반 자원 17개인지 확인한다.

@H3 12.8.2  점검 항목과 설계 원칙

@TBL
주기 | 확인 항목 | 명령
매일 | 모든 서비스가 도는가 | `srvctl status service -d racdb`
매일 | 선호 인스턴스에 있는가 | status 출력과 config의 Preferred 비교
매일 | 인스턴스별 서비스 배치 | `srvctl status database -d racdb -v`
주간 | 리스너 등록 상태 | `lsnrctl status LISTENER_SCAN1`
변경 후 | 실제 접속이 의도한 노드로 가는가 | SCAN 접속 확인 스크립트
@END

@B 애플리케이션마다 서비스를 두고 데이터베이스 이름으로 접속하지 않는다.
@B 이름에 업무 성격을 담는다. `GV$SESSION`의 SERVICE_NAME이 곧 분류가 된다.
@B 선호와 가용을 반드시 지정한다. 가용이 없으면 선호 인스턴스가 죽을 때 서비스가 사라진다.
@B 서로 다른 서비스의 선호를 엇갈리게 둔다. CDB라면 `-pdb`를 지정한다.

@H2 12.9  요약

@B 서비스는 인스턴스와 클라이언트 사이의 이름표다. 사용자 서비스가 없어도 기본 서비스 다섯 개가 인스턴스마다 있다.
@B 노드 리스너는 그 노드의 인스턴스만, SCAN 리스너는 클러스터 전체의 등록을 담는다.
@B 서비스는 선호·가용 인스턴스로 정의되고 `ora.<DB>.<서비스>.svc` 자원이 된다. 없는 인스턴스를 지정하면 PRKO-2101로 거부된다.
@B relocate는 새 접속의 방향만 바꾸고 기존 세션과 정의는 그대로 둔다. 영구 변경은 `srvctl modify service`다.
@B 서비스가 도는 인스턴스는 `-force` 없이 내려가지 않고(CRS-2974), `-force`로 내리면 서비스도 함께 정지된다. 실제 장애에서는 가용 인스턴스로 옮겨 간다.
@B 선호 인스턴스가 돌아와도 서비스는 자동 복귀하지 않는다.
@B SCAN 분산은 부하 기반이며, 서비스 배치(1층)와 리스너 선택(2층)으로 이뤄진다.

@H2 12.10  퀴즈

@QUIZ 퀴즈
1. 노드 리스너와 SCAN 리스너의 서비스 목록은 어떻게 다르며, 진단에 어떻게 쓰는가?
2. 선호 인스턴스와 가용 인스턴스의 뜻을 쓰고, 두 서비스의 선호를 엇갈리게 두는 이유를 설명하시오.
3. relocate 직전에 붙어 있던 세션은 어떻게 되는가? relocate 뒤 데이터베이스를 재기동하면 서비스는 어디서 뜨는가?
4. CRS-2974가 나는 상황과 그 설계 의도는?
5. `-force`로 인스턴스를 정지했을 때와 PMON이 죽었을 때 서비스가 다르게 움직인 이유는?
6. SCAN 분산이 라운드로빈이 아니라는 근거를 측정 결과로 설명하시오.
@END

@NOTE 정답과 해설
1. 노드 리스너는 그 노드의 인스턴스만, SCAN 리스너는 서비스를 제공하는 모든 인스턴스를 등록한다. 노드 리스너에 없으면 그 노드 인스턴스의 문제, SCAN 리스너에 없으면 클러스터 어디에서도 서비스가 돌지 않는 것이다.
2. 선호는 평소 도는 곳, 가용은 선호가 사라졌을 때 옮겨 갈 곳이다. 엇갈리게 두면 평소에는 부하가 나뉘고 한쪽이 죽으면 남은 쪽이 둘 다 받는다.
3. 끊기지 않고 원래 인스턴스에서 작업을 마친다. 정의는 바뀌지 않았으므로 재기동하면 선호 인스턴스에서 뜬다.
4. 서비스가 도는 인스턴스를 -force 없이 정지하려 할 때 난다. 서비스를 무심코 함께 내리는 일을 막는다.
5. -force는 관리자 의도의 정상 정지라 서비스 TARGET도 OFFLINE이 되어 옮겨 가지 않는다. PMON 강제 종료는 비정상 종료라 TARGET이 ONLINE으로 남아 가용 인스턴스로 옮겨 간다.
6. 부하가 비슷할 때는 20번 중 10 대 10이었지만, racdb1 재기동 직후에는 20번 모두 racdb1로 갔다. 세션 수(LONG) 기준으로 덜 바쁜 쪽에 보낸 결과다.
@END

@H2 12.11  실습 개요

@P 실습 02에서 만든 서비스 두 개를 07 끝에서 지운다. 실습 05는 인스턴스를 두 번 내리므로 부하가 낮을 때 진행하고, racdb1이 되살아나 서비스가 원위치된 것을 확인한 뒤 넘어간다.

@TBL
실습 | 파일 | 목적
02 | RAC/15장/15장_실습_02_서비스생성.txt | 선호·가용을 엇갈리게 지정해 서비스 둘을 만들고 config 기본값과 PRKO-2101을 확인한다
03 | RAC/15장/15장_실습_03_기동과배치확인.txt | 서비스를 기동하고 srvctl·GV$·리스너·실제 접속으로 배치를 확인한다
04 ★ | RAC/15장/15장_실습_04_서비스이동.txt | relocate 뒤 새 접속과 기존 세션이 어떻게 되는지 두 세션으로 확인한다
05 ★ | RAC/15장/15장_실습_05_장애시자동이동.txt | CRS-2974, -force 정지, PMON 강제 종료를 비교하고 서비스를 되돌린다
07 | RAC/15장/15장_실습_07_SCAN부하분산과정리.txt | SCAN 분산이 부하 기반임을 확인하고 서비스를 지워 기준선으로 되돌린다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다. 스냅샷이 필요한 실습은 없다.
@B 수료 후 자습: 15장_실습_01_기본서비스확인, 15장_실습_06_오류재현_서비스생성.
@B 끝나면 `srvctl status service -d racdb`가 아무것도 출력하지 않고, `crsctl stat res | grep -c '^NAME='`가 17이어야 한다.
