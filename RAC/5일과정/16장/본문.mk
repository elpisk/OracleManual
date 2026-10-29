@H1 제16장  RAC One Node

@H2 16.1  학습 목표

@P 15장에서 rac2를 지웠을 때 racdb는 인스턴스가 하나뿐인 RAC 데이터베이스였다. 노드가 하나 남았고, 그 노드가 멈추면 데이터베이스도 멈췄다. RAC One Node는 겉보기에 그 상태와 비슷하게 인스턴스 하나만 돈다. 다른 점은 노드가 둘 다 살아 있고, 인스턴스를 다른 노드로 옮길 수 있다는 것이다. 이 장은 racdb를 RAC One Node로 바꾸고, rac2로 옮겼다가 다시 rac1로 옮기고, 원래의 RAC로 되돌린다.

@B 단일 인스턴스, RAC One Node, RAC를 동시에 여는 인스턴스 수와 장애 시 동작으로 구분할 수 있다.
@B 관리자 관리형 RAC를 RAC One Node로 바꾸는 두 조건과 각 오류 번호(PRCD-1214, PRCD-1242)를 설명할 수 있다.
@B `srvctl remove instance`와 `dbca -deleteInstance`의 차이를 스레드·UNDO 관점에서 설명할 수 있다.
@B 온라인 재배치의 단계를 순서대로 말하고, 서비스가 언제 옮겨지는지 설명할 수 있다.
@B RAC One Node에서 인스턴스 이름이 바뀌는 규칙과 그로 인한 ORA-01034를 설명할 수 있다.
@B 재배치 중에 막히는 명령과 통하는 명령을 구분할 수 있다.
@B RAC로 되돌린 뒤 인스턴스 이름을 원래대로 맞추는 절차를 수행할 수 있다.

@H2 16.2  RAC One Node란

@P RAC One Node는 공유 스토리지, Clusterware, ASM을 RAC와 똑같이 쓴다. 다른 것은 평소 동시에 여는 인스턴스가 하나라는 점이다.

@IMG 16_compare.png | 그림 16-1. 단일 인스턴스, RAC One Node, RAC의 비교

@H3 16.2.1  세 가지 구성

@TBL
구성 | 노드 | 동시에 여는 인스턴스 | 노드가 멈추면
단일 인스턴스 | 하나 | 하나 | 데이터베이스 중단
RAC One Node | 후보 여럿 | 하나(재배치 중에만 잠시 둘) | 다른 후보 노드에서 인스턴스를 다시 띄운다
RAC | 여럿 | 노드 수만큼 | 남은 인스턴스가 계속 서비스
@END

@B 재배치는 12·13장에서 다룬 서비스 기능 위에서 돈다. 새 인스턴스를 띄우고 서비스를 옮기는 것은 `srvctl relocate service`와 같은 동작이고, 옛 인스턴스의 세션에 이동을 알리는 것은 FAN이다.
@B 재배치하는 동안 잠시 두 인스턴스가 같은 데이터 파일을 함께 연다. 그래서 Cache Fusion, 스레드 분리, UNDO 분리가 RAC와 똑같이 필요하다.
@B 15장에서 노드를 지운 상태는 "인스턴스가 하나뿐인 RAC"였다. 다른 노드로 옮기는 기능도, 옮길 노드도 없었다.

@H3 16.2.2  언제 쓰는가

@B 데이터베이스 하나에 CPU가 많이 필요하지 않지만 노드 유지보수 때 멈추면 곤란한 경우다. 패치나 하드웨어 점검 전에 데이터베이스를 다른 노드로 옮겨 두고 작업한다.
@B 여러 데이터베이스를 한 클러스터에 모아 두고 노드마다 하나씩 배치하는 통합 환경에서 쓴다. 한 노드를 비워야 할 때 그 노드의 데이터베이스만 옮긴다.
@B 부하를 두 노드에 나눠 받아야 하거나, 노드 장애 순간에도 접속이 끊기지 않아야 하면 RAC를 쓴다. RAC One Node는 노드 장애 때 다른 노드에서 다시 띄우는 시간만큼 멈춘다.

@NOTE 라이선스는 따로 확인한다
RAC One Node는 Enterprise Edition의 별도 옵션이다(1장). 기능은 같은 소프트웨어에 들어 있어 `srvctl` 한 줄로 바뀌지만 쓸 수 있는지는 계약이 정한다. 운영에서 유형을 바꾸기 전에는 보유한 옵션을 먼저 확인한다.
@END

@H3 16.2.3  지금의 구성

@CODE
[oracle@rac1 ~]$ srvctl config database -db racdb
Management policy: AUTOMATIC
Services:
Type: RAC
Database instances: racdb1,racdb2
Configured nodes: rac1,rac2
Database is administrator managed
@END

@B Type은 RAC, 인스턴스는 둘, `srvctl`에 등록된 서비스는 없다. 관리자 관리형이다.
@B 관리자 관리형은 인스턴스와 노드를 관리자가 이름으로 묶는 방식이다. RAC One Node로 바꿀 때 인스턴스 이름 접두어를 반드시 지정해야 한다.
@B `v$spparameter`를 보면 `instance_number`, `thread`, `undo_tablespace`가 `racdb1`, `racdb2`라는 sid에 묶여 있다(9장). 이 장에서 인스턴스 이름이 바뀔 때 이 항목들이 어떻게 되는지가 중요한 관찰 대상이다.
@B 시작 전에 `ocrconfig -manualbackup`으로 OCR 수동 백업을 뜬다. 이 장에서 바뀌는 것은 OCR 안의 데이터베이스 자원 정의이고, OCR은 공유 디스크에 있어 VM 스냅샷으로 되돌아가지 않는다.

@H3 16.2.4  명령 미리 읽기

@CODE
[oracle@rac1 ~]$ srvctl convert database -help
Convert RAC database having one instance to RAC One Node database.
Usage: srvctl convert database -db <db_unique_name> -dbtype RACONENODE [-instance <inst_name>] [-timeout <timeout>]
    -instance <inst_name>   Instance name prefix; required for administrator-managed RAC One Node database
    -timeout <timeout>      Online relocation timeout in minutes
@END

@B 변환 대상은 "인스턴스가 하나인 RAC"이고, 반대로 되돌린 결과도 "인스턴스가 하나인 RAC"다.
@B `-instance`는 인스턴스 이름이 아니라 접두어다. `-timeout`은 재배치 때 옛 인스턴스가 내려가기를 기다리는 상한이며 단위는 분이다.
@B `srvctl relocate database`에는 `-abort`와 `-revert`가 있다. 재배치가 중간에 실패할 수 있고, 그것을 정리하는 명령이 따로 있다는 뜻이다.
@B 일반 RAC에 `relocate database`를 치면 `PRCD-1146 : Database racdb is not a RAC One Node database`로 거부된다. 서비스 재배치(`relocate service`)는 서비스를 다른 인스턴스로 옮기고, 데이터베이스 재배치는 인스턴스 자체를 다른 노드로 옮긴다.

@H2 16.3  RAC를 RAC One Node로 변환

@P 관리자 관리형 RAC를 변환하려면 두 조건을 맞춰야 한다. 실습 02는 조건을 하나씩 어겨 오류를 본 뒤 맞춰 나간다.

@IMG 16_convert.png | 그림 16-2. 변환의 두 조건 — 인스턴스 하나(PRCD-1214)와 서비스 하나 이상(PRCD-1242)

@H3 16.3.1  인스턴스가 하나여야 한다

@CODE
[oracle@rac1 ~]$ srvctl convert database -db racdb -dbtype RACONENODE -instance racdb
PRCD-1214 : Administrator-managed RAC database racdb has more than one instance
[oracle@rac1 ~]$ srvctl stop instance -db racdb -instance racdb2
[oracle@rac1 ~]$ srvctl remove instance -db racdb -instance racdb2 -noprompt
@END

@B 둘 중 무엇을 남길지 `srvctl`이 대신 정하지 않는다. 관리자가 고른다. 여기서는 racdb1을 남긴다.
@B 정책 관리형 데이터베이스는 인스턴스와 노드를 이름으로 묶지 않아 접두어가 필수가 아니고, 서버 풀이 옮겨 갈 노드를 정한다. 이 과정의 racdb는 관리자 관리형이므로 이 장의 명령과 오류는 모두 관리자 관리형 기준이다.

@TBL
명령 | CRS 등록 | 스레드·리두 | UNDO 테이블스페이스
`srvctl remove instance` | 해제 | 남는다 | 남는다
`dbca -deleteInstance` | 해제 | 지운다 | 지운다
@END

@B 15장에서는 노드를 지우는 것이 목적이라 `dbca`로 데이터베이스 안의 구조까지 지웠다.
@B 여기서는 `srvctl`을 쓴다. thread 2와 UNDOTBS2를 남겨 두어야 rac2로 옮긴 인스턴스가 쓸 자리가 있다.

@H3 16.3.2  서비스가 있어야 한다

@CODE
[oracle@rac1 ~]$ srvctl convert database -db racdb -dbtype RACONENODE -instance racdb
PRCD-1242 : Unable to convert RAC database racdb to RAC One Node database because the database had no service added
[oracle@rac1 ~]$ srvctl add service -db racdb -service ronsvc -preferred racdb1 -pdb racpdb1
[oracle@rac1 ~]$ srvctl start service -db racdb -service ronsvc
@END

@B RAC One Node는 서비스로 접속한다는 것을 전제로 한다. 온라인 재배치는 새 노드에 인스턴스를 띄운 뒤 서비스를 그쪽으로 옮기고 옛 인스턴스를 내리는 일이다. 옮길 서비스가 없으면 재배치가 의미가 없으므로 변환 단계에서 막는다.
@B 선호 인스턴스는 남은 racdb1, 대상 PDB는 racpdb1이다.

@H3 16.3.3  변환

@CODE
[oracle@rac1 ~]$ srvctl convert database -db racdb -dbtype RACONENODE -instance racdb -timeout 30
[oracle@rac1 ~]$ srvctl config database -db racdb
Services: ronsvc
Type: RACOneNode
Online relocation timeout: 30
Instance name prefix: racdb
Candidate servers: rac1
Database instances: racdb_1
@END

@B 몇 초 만에 출력 없이 끝나고 데이터베이스는 멈추지 않는다. 바뀐 것은 OCR의 자원 정의뿐이다.
@B 새로 생긴 줄은 재배치 시간 제한, 인스턴스 접두어, 후보 서버다. `Configured nodes`가 `Candidate servers`로 이름이 바뀐다. RAC에서는 "이 노드들에서 돈다"였고, RAC One Node에서는 "이 노드들 중 하나에서 돈다"다.
@B `srvctl status database -v`에 `Online relocation: INACTIVE` 줄이 생긴다. 재배치 중에만 ACTIVE가 되고, 이 값이 다른 명령을 막는 기준이 된다(16.5).
@TBL
srvctl config 항목 | 변환 전(RAC) | 변환 후(RACOneNode)
Type | RAC | RACOneNode
Database instances | racdb1,racdb2 | racdb_1
Configured nodes / Candidate servers | rac1,rac2 | rac1
Services | (없음) | ronsvc
Online relocation timeout / Instance name prefix | (없음) | 30 / racdb
Spfile, Password file, Disk Groups, Management policy | +DATA의 같은 파일, AUTOMATIC | 그대로
@END

@B SPFILE, 암호 파일, 디스크그룹은 그대로다. 변환 전후로 같은 파일을 쓰는 같은 데이터베이스다.

@H3 16.3.4  구성과 실제 이름이 어긋난다

@B 구성은 `Database instances: racdb_1`인데 상태는 `Instance racdb1 is running`이다.
@B RAC One Node는 인스턴스 이름을 "접두어_번호"로 짓는다. 변환은 구성만 바꾸고 돌고 있는 인스턴스를 다시 띄우지 않으므로 실제 인스턴스는 옛 이름 그대로 남는다.
@B 이 어긋남은 오류가 아니다. 다음에 인스턴스가 새로 뜰 때 구성의 이름을 따른다. 재배치가 그 시점이다.

@H2 16.4  온라인 재배치

@P 재배치는 대상 노드에 새 인스턴스를 띄우고, 서비스를 옮기고, 옛 인스턴스를 내리는 순서로 진행된다. 실습 03은 한 세션에서 재배치를 걸고 다른 세션에서 5초 간격으로 상태를 관찰한다.

@IMG 16_relocate.png | 그림 16-3. 온라인 재배치 — 새 인스턴스가 열린 뒤에 서비스가 옮겨지고, 옛 인스턴스는 transactional로 내려간다

@H3 16.4.1  후보 서버

@B `srvctl modify database -db racdb -node rac1,rac2`는 `PRKF-1125 : multiple values specified for the single value option "node"`로 실패한다. 이 버전의 `-node`는 값 하나만 받는다.
@B 관리자 관리형 RAC One Node는 후보에 없는 노드로 재배치하면 그 노드를 후보에 추가한다. 재배치 대상 노드를 `relocate`의 `-node`로 직접 준다.

@H3 16.4.2  재배치 순서

@CODE
[oracle@rac1 ~]$ srvctl relocate database -db racdb -node rac2 -verbose
Added target node rac2
Configuration updated to two instances
Instance racdb_2 started
Services relocated
Waiting for up to 30 minutes for instance racdb1 to stop ...
Instance racdb1 stopped
Configuration updated to one instance
@END

@B 새 인스턴스 기동이 서비스 이동보다 먼저다. 새 인스턴스가 완전히 열린 뒤에 서비스를 옮기므로 서비스로 접속하는 클라이언트는 갈 곳이 없어지는 순간이 없다.
@B 중간 관찰에서 racdb1(ronsvc)과 racdb_2가 함께 Open으로 보이는 구간이 있다. 그 순간 racdb는 인스턴스 둘인 RAC다. racdb1 알럿 로그에도 14장에서 본 `Reconfiguration started` 메시지가 찍힌다. 그때는 인스턴스가 줄었고, 지금은 늘었다.
@B 옛 인스턴스는 `transactional local`로 내려간다. 진행 중인 트랜잭션이 끝나기를 기다린 뒤 이 인스턴스만 내린다. 남은 세션은 13장의 FAN과 서비스 드레인으로 새 인스턴스 쪽으로 유도하며, `relocate`의 `-drain_timeout`이 그 대기 시간이다.
@B 대기 상한은 `-timeout`이다. 알럿 로그에 `ALTER SYSTEM SET _shutdown_completion_timeout_mins=30 SCOPE=MEMORY;`로 남는다.

@H3 16.4.3  어디에 시간이 드는가

@TBL
구간 | 실습 03·04 기록
재배치 전체 | 99.5초
racdb_2 기동 시작부터 RACPDB1 READ WRITE까지 | 23초
racdb1 정지 시작부터 완료까지 | 62초
rac1로 되돌아오는 재배치 | 85.9초
@END

@CODE
[rac2] alert_racdb_2.log
2026-10-28T18:13:21  Starting ORACLE instance (normal)
2026-10-28T18:13:34  Thread 2 opened at log sequence 44
2026-10-28T18:13:44  Pluggable database RACPDB1 opened read write
[rac1] alert_racdb1.log
2026-10-28T18:13:25  Reconfiguration started (old inc 6, new inc 8)
2026-10-28T18:13:46  Shutting down ORACLE instance (transactional local)
2026-10-28T18:14:48  Instance shutdown complete
@END

@B `srvctl status`의 5초 간격 관찰은 거칠다. 두 인스턴스의 알럿 로그를 시각으로 맞추면 단계가 더 정확히 보인다.
@B racdb_2가 thread 2를 열고 PDB까지 연 직후(18:13:44) racdb1의 정지가 시작된다(18:13:46). 서비스 이동이 그 사이에 일어난다.
@B 정지가 끝나기까지 1분 남짓 걸린 것은 PDB를 닫고 진행 중 트랜잭션을 기다리는 시간이다. 이번에는 사용자 세션이 없었으므로 운영에서는 이보다 길어질 수 있다.
@B 재배치 시간의 대부분은 옛 인스턴스를 내리는 쪽이다. 사용자 세션이 많으면 transactional 정지가 그만큼 길어진다.
@B 재배치 뒤 `Candidate servers`는 `rac1,rac2`가 되고, 구성과 실제 인스턴스 이름이 모두 `racdb_2`로 맞는다.

@H3 16.4.4  rac2에서 붙었더니 ORA-01034

@CODE
[oracle@rac2 ~]$ sqlplus / as sysdba
SQL> select inst_id, instance_name from gv$instance;
ORA-01034: ORACLE not available
[oracle@rac2 ~]$ ps -ef | grep [o]ra_pmon
oracle   22653     1  0 18:13 ?        00:00:00 ora_pmon_racdb_2
[oracle@rac2 ~]$ echo $ORACLE_SID
racdb2
@END

@B 데이터베이스는 rac2에서 Open인데 로컬 접속이 실패했다. oracle 계정 프로필의 `ORACLE_SID`는 racdb2이고 실제 인스턴스는 racdb_2다. `/ as sysdba`는 `ORACLE_SID`로 인스턴스를 찾는다.
@B `export ORACLE_SID=racdb_2`로 다시 붙으면 INST_ID 2, thread 2, `undo_tablespace` UNDOTBS2, RACPDB1 READ WRITE가 보인다.
@B RAC One Node의 인스턴스 이름은 재배치할 때마다 `접두어_1`, `접두어_2`로 번갈아 바뀐다. 고정된 `ORACLE_SID`와 어긋나는 것이 정상이다.

@BP 운영에서는 서비스로 접속한다
관리 작업으로 로컬 접속이 필요하면 `ps -ef | grep pmon`으로 지금 인스턴스 이름을 먼저 본다. 애플리케이션과 사용자는 인스턴스 이름에 기대지 않고 서비스(ronsvc)로 접속한다. 변환 조건의 PRCD-1242가 이 원칙을 강제한다.
@END

@H3 16.4.5  스레드와 UNDO는 어떻게 잡혔나

@B SPFILE에는 racdb_2 전용 항목이 없다. 그런데 racdb_2는 thread 2와 UNDOTBS2를 쓰고 있다.
@B 인스턴스별 지정이 없으면 인스턴스는 쓰이지 않는 열린 스레드와 쓰이지 않는 UNDO 테이블스페이스를 잡는다. racdb1이 thread 1과 UNDOTBS1을 쓰고 있었으므로 남은 것은 thread 2와 UNDOTBS2였다.
@B 16.3.1에서 `dbca` 대신 `srvctl remove instance`로 등록만 해제한 것이 여기서 쓰였다. `dbca`로 지웠다면 racdb_2가 잡을 스레드가 없었다.

@H2 16.5  재배치 중에 다른 명령을 내면

@P 재배치는 1~2분이 걸리고 그동안 인스턴스 둘이 잠시 함께 돈다. 실습 04(자습)는 rac1로 되돌아오는 재배치를 세션 A에서 걸고, 세션 B에서 다른 명령을 낸다.

@IMG 16_blocked.png | 그림 16-4. 재배치가 ACTIVE인 동안 막히는 명령과 통하는 명령

@CODE
[oracle@rac1 ~]$ srvctl relocate database -db racdb -node rac2
PRCD-1161 : Online relocation failed for RAC One Node database racdb
PRCD-1164 : An online relocation request for RAC One Node database racdb is already active
[oracle@rac1 ~]$ srvctl stop database -db racdb
PRKO-2143 : Cannot stop RAC One Node database when an online relocation request for the database is already active
@END

@B 재배치는 데이터베이스당 하나만 진행된다. 원인은 아래 줄 PRCD-1164다. 위 줄 PRCD-1161은 이번 요청이 실패했다는 겉 메시지이고, 세션 A의 재배치가 실패한 것이 아니다.
@B 재배치 중 정지는 PRKO-2143으로 막힌다. 어느 쪽을 어떤 순서로 내리고 재배치를 어떻게 마무리할지가 모호해지기 때문이다. 재배치가 끝나기를 기다리거나, 실패한 재배치라면 `relocate -abort`로 정리한 뒤 정지한다.
@B `srvctl modify database -db racdb -timeout 10`은 통했다. 그리고 진행 중인 재배치에 바로 반영되어 대기 문구가 "Waiting for up to 10 minutes"로 바뀌고, 알럿 로그에도 `_shutdown_completion_timeout_mins=10`이 남았다.
@B 이 동작은 양날이다. 오래 걸리는 재배치의 대기 상한을 도중에 줄일 수 있지만, 다른 사람이 설정을 바꾸면 진행 중인 작업이 예상과 다른 값으로 끝난다. 재배치 중에는 그 데이터베이스의 `srvctl modify`도 하지 않는 것으로 운영 규칙을 정한다.

@CASE 재배치가 중간에 실패했을 때
대상 노드에서 인스턴스가 뜨지 않거나 서비스 이동이 실패하면 Online relocation이 FAILED 상태로 남을 수 있다. 실습에서는 재현하지 않았다.
이때는 `srvctl relocate database -db racdb -abort`로 실패한 재배치를 정리하고, 관리자 관리형이면 `-revert`를 함께 주어 실패한 대상 노드를 후보 서버 목록에서 뺀다. 먼저 `srvctl status database -v`로 ACTIVE인지 FAILED인지 구분한 뒤 기다릴지 abort할지 정한다.
@END

@H2 16.6  RAC로 되돌리기

@P RAC로 되돌리는 변환은 몇 초면 끝난다. 시간이 드는 곳은 그 뒤 인스턴스 이름을 원래대로 맞추는 작업이다. 실습 05가 이 단계다.

@IMG 16_names.png | 그림 16-5. 인스턴스 이름의 변화 — 빨간 두 구간은 오류 없이 구성과 실제가 어긋났다

@H3 16.6.1  변환

@CODE
[oracle@rac1 ~]$ srvctl convert database -db racdb -dbtype RAC -node rac1
[oracle@rac1 ~]$ srvctl config database -db racdb | grep -E "Type|instances|nodes"
Type: RAC
Database instances: racdb_1
Configured nodes: rac1
@END

@B 데이터베이스는 멈추지 않는다. 접두어, 후보 서버, 재배치 시간 제한 줄이 사라진다.
@B 인스턴스는 racdb_1 이름 그대로다. 여기서 끝내면 이름이 원래와 다른 RAC가 남는다.

@H3 16.6.2  racdb2만 붙이면 이름이 섞인다

@B `srvctl add instance -db racdb -instance racdb2 -node rac2`는 받아들여지지만 구성이 `racdb2,racdb_1`로 섞인다.
@B racdb_1은 지금 thread 1과 UNDOTBS1을 쓰지만 우연히 맞을 뿐이다. SPFILE의 `racdb1.thread=1`, `racdb1.undo_tablespace=UNDOTBS1`은 racdb1이라는 이름에 묶여 있어 racdb_1에는 적용되지 않는다.
@B 기동 순서가 바뀌면 rac1이 thread 2를 잡을 수도 있다. 9·10장에서 인스턴스마다 스레드와 UNDO를 고정한 설계가 이름 하나로 무력해진다.

@H3 16.6.3  PRKO-3147과 이름 원복

@CODE
[oracle@rac1 ~]$ srvctl remove instance -db racdb -instance racdb_1 -noprompt
PRKO-3147 : Instance racdb_1 cannot be removed because it is the only preferred instance for service(s) ronsvc for database racdb
@END

@B 서비스 ronsvc의 선호 인스턴스가 재배치를 거치며 racdb_1로 따라 바뀌어 있다. 유일한 선호 인스턴스를 지우면 서비스가 갈 곳이 없어지므로 거부된다.
@B ronsvc는 변환 조건을 맞추려고 만든 서비스이므로 먼저 정지·삭제한다.
@B 인스턴스 이름은 실행 중에 바꿀 수 없으므로 데이터베이스를 한 번 완전히 내린다. `srvctl stop database` → `remove instance -instance racdb_1` → `add instance -instance racdb1 -node rac1` → `srvctl start database` 순이다.
@B `srvctl start database` 한 번으로 racdb1, racdb2가 함께 올라온다. 이름이 돌아오자 SPFILE의 인스턴스별 항목이 다시 적용되어 thread 1·2와 UNDOTBS1·2가 이름에 고정된다.

@H3 16.6.4  기준선과 잔재

@TBL
항목 | 15장 끝 | 16장 끝
Type / 인스턴스 | RAC / racdb1, racdb2 | 같음
dba_pdb_saved_states | racdb1, racdb2 OPEN | 같음
SPFILE 인스턴스별 항목 | racdb1·racdb2 각 3개 | 같음(racdb_ 항목 없음)
gv$active_services / CRS 자원 | 10 / 17 | 같음
진단 디렉터리 | racdb1(rac1), racdb2(rac2) | racdb_1, racdb_2 추가
@END

@B 남은 것은 진단 디렉터리 racdb_1(rac1)과 racdb_2(rac2)다. 그 이름으로 돌았던 동안의 알럿 로그가 들어 있어 재배치 기록을 볼 때 쓴다.
@B 모든 변경을 `srvctl`로 되돌렸으므로 OCR 수동 백업은 쓰지 않았다.

@H2 16.7  RAC와 RAC One Node 사이의 선택

@TBL
상황 | 권장 | 이유
한 노드의 CPU로 충분하고 유지보수 중단을 피하고 싶다 | RAC One Node | 재배치로 노드를 비운다
부하를 두 노드에 나눠야 한다 | RAC | One Node는 인스턴스 하나에 몰린다
노드 장애 순간에도 접속이 이어져야 한다 | RAC | One Node는 재기동 시간만큼 멈춘다
데이터베이스 여러 개를 노드에 나눠 배치한다 | RAC One Node | 데이터베이스마다 노드를 옮길 수 있다
인스턴스 이름에 기대는 스크립트가 많다 | RAC | One Node는 이름이 바뀐다
@END

@B 변환은 두 방향 모두 데이터베이스를 멈추지 않았다. 시간이 든 것은 변환 앞뒤의 인스턴스 정리와 이름 원복이다.
@B 유형을 자주 오간다면 처음부터 접두어 방식의 이름을 RAC에서도 쓰고 SPFILE의 인스턴스별 항목도 그 이름으로 두는 편이 낫다. 실습은 기존 설계를 지키려고 원래 이름으로 돌렸다.
@B 마지막 줄을 가볍게 보면 안 된다. ORA-01034는 프로필의 `ORACLE_SID` 하나에서 났다. 백업 스크립트, 모니터링 에이전트, cron 작업이 인스턴스 이름을 고정해 쓰고 있다면 바꾸기 전에 `grep -r racdb1` 같은 방식으로 찾아 서비스 이름이나 pmon 프로세스 이름 기준으로 고친다.
@B 노드 장애 때 RAC One Node는 Clusterware가 인스턴스를 다른 후보 노드에서 다시 띄우므로 그동안 멈춘다. 14장처럼 살아 있는 인스턴스가 스레드를 이어받는 RAC와 다르다. 이 동작은 실습에서 재현하지 않았다.

@TBL
시점 | 확인 항목 | 명령
변환 전 | 유형·관리 방식, 인스턴스 하나, 서비스 하나 이상 | `srvctl config database`, `srvctl config service`
변환 전 | OCR 수동 백업 | `ocrconfig -manualbackup`
재배치 중 | 진행 상태 | `srvctl status database -v`의 Online relocation
재배치 후 | 지금 인스턴스 이름 | `ps -ef`의 pmon, `srvctl status database`
되돌린 뒤 | 인스턴스 이름과 SPFILE 항목, PDB 저장 상태 | `v$spparameter`의 sid, `gv$instance`, `dba_pdb_saved_states`
@END

@H2 16.8  요약

@B RAC One Node는 공유 스토리지와 Clusterware를 RAC와 똑같이 쓰고 인스턴스는 하나만 연다. 필요하면 그 인스턴스를 다른 노드로 옮긴다.
@B 관리자 관리형 RAC를 변환하려면 인스턴스가 하나여야 하고(PRCD-1214) 서비스가 하나 이상 있어야 한다(PRCD-1242).
@B 인스턴스를 줄일 때는 `srvctl remove instance`를 쓴다. 스레드와 UNDO가 남아 재배치 때 새 인스턴스가 그 자리를 쓴다.
@B 재배치는 새 인스턴스 기동 → 서비스 이동 → 옛 인스턴스 transactional 정지 순이며, 정지 대기 상한이 `-timeout`이다.
@B 인스턴스 이름은 `접두어_번호`로 바뀐다. 고정 `ORACLE_SID`로 붙으면 ORA-01034가 나므로 운영은 서비스로 접속한다.
@B 재배치 중에는 재배치(PRCD-1164)와 정지(PRKO-2143)가 막히고, `modify -timeout`은 진행 중인 재배치에 반영된다.
@B RAC로 되돌린 뒤에는 서비스를 지우고(PRKO-3147 회피) 데이터베이스를 내려 원래 인스턴스 이름으로 재등록한다.

@H2 16.9  퀴즈

@QUIZ 퀴즈
1. 단일 인스턴스, RAC One Node, RAC를 동시에 여는 인스턴스 수와 노드 장애 때의 동작으로 구분하시오.
2. 관리자 관리형 RAC를 RAC One Node로 바꾸기 위한 두 조건과 각 오류 번호를 쓰시오.
3. 인스턴스를 줄일 때 `dbca -deleteInstance` 대신 `srvctl remove instance`를 쓴 이유는?
4. 온라인 재배치에서 서비스는 언제 옮겨지며, 그 순서가 클라이언트에 주는 이점은?
5. 재배치 뒤 rac2에서 `sqlplus / as sysdba`가 ORA-01034를 낸 이유와 조치는?
6. 재배치 중에 막히는 명령과 통하는 명령을 하나씩 들고, 통하는 명령의 위험을 설명하시오.
@END

@NOTE 정답과 해설
1. 단일 인스턴스는 하나·중단, RAC One Node는 하나(재배치 중 잠시 둘)·다른 후보 노드에서 재기동, RAC는 노드 수만큼·남은 인스턴스가 계속 서비스.
2. 인스턴스가 하나여야 한다(PRCD-1214), 서비스가 하나 이상 있어야 한다(PRCD-1242).
3. CRS 등록만 해제하고 thread 2와 UNDOTBS2를 남겨 재배치된 racdb_2가 쓸 자리를 두기 위해서다.
4. 새 인스턴스가 완전히 열린 뒤(Instance racdb_2 started 다음)에 옮겨진다. 서비스로 접속하는 클라이언트가 갈 곳이 없어지는 순간이 없다.
5. ORACLE_SID는 racdb2인데 실제 인스턴스는 racdb_2다. ps -ef로 pmon 이름을 확인해 ORACLE_SID=racdb_2로 붙고, 평소에는 서비스로 접속한다.
6. 막힘: relocate(PRCD-1164), stop(PRKO-2143). 통함: modify -timeout. 진행 중인 재배치의 대기 상한이 바로 바뀌어 남의 작업이 예상과 다른 값으로 끝난다.
@END

@H2 16.10  실습 개요

@P 이 장의 실습은 데이터베이스 유형을 바꿨다가 되돌린다. 실습 01에서 OCR 수동 백업을 먼저 뜬다. 유형 변환은 OCR의 자원 정의를 바꾸므로 VM 스냅샷으로는 되돌릴 수 없다.

@TBL
실습 | 파일 | 목적
01 | RAC/19장/19장_실습_01_개념과구성확인.txt | 유형·서비스·인스턴스별 SPFILE 항목을 확인하고 OCR 수동 백업을 뜬다
02 ★ | RAC/19장/19장_실습_02_변환.txt | PRCD-1214·PRCD-1242를 확인하며 조건을 맞추고 RAC One Node로 변환한다
03 ★ | RAC/19장/19장_실습_03_온라인재배치.txt | rac2로 재배치하며 5초 간격으로 상태를 관찰하고 ORA-01034를 해결한다
05 ★ | RAC/19장/19장_실습_05_되돌리기.txt | RAC로 되돌리고 PRKO-3147을 피해 인스턴스 이름을 원복한다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다. 실습 03은 세션 두 개를 쓴다.
@B 실습 05에서 데이터베이스를 한 번 완전히 내린다. 끝나면 Type RAC, racdb1·racdb2 Open, 서비스 10행, CRS 자원 17개인지 확인한다.
@B 실습 05는 racdb_1이 rac1에서 Open인 상태를 전제로 한다. 수업에서는 실습 04의 오류 재현을 건너뛰고 `srvctl relocate database -db racdb -node rac1 -verbose`만 실행해 rac1로 되돌린 뒤 실습 05로 넘어간다.
@B 수료 후 자습: 19장_실습_04_오류재현_재배치중명령.
