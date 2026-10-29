@H1 제1장  RAC 개요와 아키텍처

@H2 1.1  학습 목표

@P Oracle Real Application Clusters(RAC)는 여러 서버가 하나의 데이터베이스를 동시에 열어 함께 서비스하는 구성이다. 이 장은 이후 모든 장의 바탕이 되는 구조를 세운다. 무엇이 공유되고 무엇이 인스턴스마다 따로인지, 노드 사이에 어떤 네트워크가 왜 필요한지, 블록이 노드를 건너갈 때 무슨 일이 일어나는지를 다룬다.

@B 수직 확장과 수평 확장의 차이, RAC가 막는 장애와 막지 못하는 장애를 구분해 설명할 수 있다.
@B 노드·인터커넥트·공유 스토리지와 Clusterware·ASM·데이터베이스 세 계층의 역할을 말할 수 있다.
@B 데이터베이스와 인스턴스를 구분하고, 공유되는 파일과 인스턴스별 구성 요소(리두 스레드, UNDO)를 나열할 수 있다.
@B `GV$` 뷰와 `V$` 뷰의 차이를 알고 클러스터 전체를 조회할 수 있다.
@B Cache Fusion이 블록을 전송하는 과정과 gc 대기 이벤트의 의미를 설명할 수 있다.
@B 공용 IP·VIP·SCAN·사설 인터커넥트의 용도를 실습 환경의 실제 주소와 연결해 설명할 수 있다.
@B 인스턴스 하나가 빠졌을 때 계속되는 것과 끊기는 것을 구분할 수 있다.

@H2 1.2  확장성과 가용성

@P RAC를 도입하는 이유는 확장성과 가용성 두 가지로 나뉜다. 같은 구조에서 나오지만 요구하는 설계가 달라서 처음부터 구분해 둔다.

@H3 1.2.1  수직 확장과 수평 확장

@B 수직 확장(scale-up)은 더 큰 서버로 바꾸는 방식이다. 애플리케이션과 데이터베이스 구조를 건드리지 않지만, 서버 한 대가 가질 수 있는 소켓과 메모리에 상한이 있고 상한에 가까울수록 비용이 급격히 오른다.
@B 수평 확장(scale-out)은 같은 사양의 서버를 클러스터에 더 붙이는 방식이다. 새 노드는 같은 데이터베이스를 열고 곧바로 부하를 나눠 받는다.
@B RAC는 데이터를 쪼개지 않는다. 어느 노드에 접속하든 데이터베이스 전체가 보인다. 이 점이 샤딩이나 애플리케이션 수준 분산과 다르다.
@B 확장이 선형으로 늘지는 않는다. 노드가 늘면 노드 사이에 블록과 잠금 정보를 주고받는 비용도 는다. 같은 블록을 여러 노드가 심하게 갱신하는 워크로드는 노드를 늘려도 처리량이 늘지 않을 수 있다. 12장의 서비스 설계로 부하를 나누는 이유가 여기에 있다.

@H3 1.2.2  계획되지 않은 정지와 계획된 정지

@B 노드 하나에서 하드웨어 고장, OS 패닉, 인스턴스 이상 종료가 나도 남은 노드가 서비스를 이어 간다.
@B 살아 있는 인스턴스가 죽은 인스턴스의 리두 스레드를 읽어 인스턴스 복구를 수행한다. 그동안에도 자기 몫의 트랜잭션은 계속 처리한다.
@B 죽은 노드에 붙어 있던 세션은 끊긴다. 재접속을 자동화하거나 진행 중이던 작업을 다시 실행하는 일은 TAF와 Application Continuity가 맡는다(13장).
@B 패치나 점검처럼 계획된 작업은 노드를 하나씩 내렸다 올리는 롤링 방식으로 서비스를 끊지 않고 할 수 있다. 데이터베이스 구조를 바꾸는 작업은 대개 전체 정지가 필요하다.

@NOTE RAC는 재해 복구 수단이 아니다
모든 노드는 같은 스토리지를 쓴다. 스토리지가 손상되거나 데이터센터 전체가 멈추면 노드 수와 상관없이 데이터베이스가 멈춘다.
사이트 장애에는 Data Guard, 잘못된 DELETE 같은 논리 오류에는 백업과 플래시백이 필요하다. RAC·Data Guard·백업은 서로를 대신하지 않고 각자 다른 위험을 막는다.
@END

@H2 1.3  클러스터를 이루는 구성 요소

@P RAC 클러스터는 노드, 상호 연결(인터커넥트), 공유 스토리지 세 가지 물리 요소 위에 소프트웨어 계층을 얹은 구조다. 그림 1-1은 이 과정의 실습 환경을 그대로 그린 것이다.

@IMG 01_cluster.png | 그림 1-1. 실습 클러스터 rac-cluster — 두 노드가 공용망·사설망으로 연결되고 공유 디스크그룹 세 개를 함께 쓴다

@H3 1.3.1  노드

@B 노드는 클러스터에 참여하는 서버 한 대다. 노드마다 CPU, 메모리, OS, Oracle 소프트웨어 설치본(Grid 홈, DB 홈)을 따로 가진다.
@B 노드들은 같은 OS 버전, 같은 패치 수준, 같은 Oracle 버전을 유지한다. 사양이 다른 서버를 섞을 수는 있지만 느린 노드가 클러스터 전체 응답을 끌어내리기 쉬워 실무에서는 같은 사양을 쓴다.
@B 노드 목록과 상태는 `olsnodes -n -s -t`로 본다. 노드 번호, Active 여부, Pinned 여부가 함께 나온다.
@B 노드마다 데이터베이스 인스턴스가 하나씩 뜬다. 실습 DB `racdb`는 관리자 관리형(administrator-managed)이라 rac1에는 racdb1, rac2에는 racdb2가 고정으로 배치된다.

@H3 1.3.2  인터커넥트 — 사설 네트워크

@B 노드끼리만 쓰는 전용 네트워크다. 실습 환경에서는 VMnet1에 연결된 `ens160`(172.16.119.0/24)이 이 역할을 한다.
@B 두 가지 트래픽이 흐른다. Clusterware의 하트비트와 Cache Fusion의 블록·잠금 메시지다. 양은 Cache Fusion 쪽이 훨씬 많다.
@B 하트비트가 정해진 시간 안에 오지 않으면 클러스터는 그 노드를 축출(eviction)한다. 인터커넥트의 순간 지연이 노드 재부팅으로 이어질 수 있다.
@B 인터커넥트에는 다른 트래픽(백업 전송, 파일 복사)을 태우지 않는다. 평균 사용률이 낮아도 순간 지연이 튀면 클러스터가 노드를 죽인다.

@CASE 인터커넥트에 백업 트래픽을 태운 사례
야간 배치 시간대에만 특정 노드가 축출되는 현상이 반복됐다. CPU와 메모리는 여유가 있었고 DB 로그에도 원인이 없었다.
새 백업 서버를 들이면서 인터커넥트 스위치에 백업 VLAN을 얹은 것이 원인이었다. 백업이 시작되면 스위치 버퍼가 차서 하트비트 패킷이 늦게 도착했다. 백업 VLAN을 분리하자 축출이 멈췄다.
@END

@H3 1.3.3  공유 스토리지

@B 데이터 파일, 컨트롤 파일, 온라인 리두, SPFILE, 그리고 Clusterware가 쓰는 OCR과 보팅 파일이 모두 공유 스토리지에 있다.
@B 공유 스토리지의 조건은 두 가지다. 모든 노드가 같은 디스크를 동시에 읽고 쓸 수 있어야 하고, 노드마다 장치 이름이 달라도 같은 디스크로 식별할 수 있어야 한다.
@B 리눅스의 `/dev/sdb`는 인식 순서에 따라 노드마다 다른 디스크를 가리킬 수 있다. 실습 환경은 WWN 기준 udev 규칙으로 `/dev/asmdisk/crs1` 같은 고정 이름을 만들었다(설치 가이드 v2 4장).
@B 그 위의 볼륨 관리와 파일 시스템은 ASM이 맡는다. 4장부터 8장까지가 ASM을 다룬다.

@TBL
디스크그룹 | 디스크 | 이중화 | 담는 것
+CRS | /dev/asmdisk/crs1~3 (4GB × 3) | Normal | OCR, 보팅 파일 3벌
+DATA | /dev/asmdisk/data1~3 (20GB × 3) | External | 데이터 파일, 컨트롤 파일, 리두, SPFILE, 암호 파일
+FRA | /dev/asmdisk/fra1~2 (12GB × 2) | External | 컨트롤 파일·리두 다중화 사본, 아카이브
@END

@H2 1.4  소프트웨어 스택 — 세 개의 층

@P 노드 하나에서 도는 Oracle 소프트웨어는 Clusterware, ASM, 데이터베이스 세 층으로 나뉜다. 층마다 홈, 운영 계정, 명령이 다르다. 이 구분이 흐리면 장애가 났을 때 어느 로그와 어느 명령을 봐야 할지 정하지 못한다.

@IMG 01_stack.png | 그림 1-2. 노드 하나의 소프트웨어 스택 — Clusterware와 ASM은 Grid 홈을, 데이터베이스는 DB 홈을 쓴다

@H3 1.4.1  Oracle Clusterware

@B 여러 서버를 하나의 클러스터로 묶는다. 구성원(멤버십)을 관리하고, 노드 생존을 감시하고, 등록된 자원을 정해진 순서로 기동·정지·재기동한다.
@B 자원(resource)은 리스너, VIP, ASM 인스턴스, DB 인스턴스, 서비스처럼 Clusterware가 관리하는 대상 하나하나를 말한다(2장, 11장).
@B 노드가 죽었는지 판단하고 살아 있는 노드만 스토리지에 접근하게 통제한다. 이 통제가 없으면 서로 상대가 죽었다고 믿는 두 노드가 같은 파일을 각자 갱신하는 스플릿 브레인이 생긴다.

@H3 1.4.2  Grid Infrastructure

@B Grid Infrastructure(GI)는 Clusterware와 ASM을 함께 배포하는 설치 단위의 이름이다.
@B 실습 환경의 Grid 홈은 `/u01/app/19.3.0/grid`, ORACLE_BASE는 `/u01/app/grid`, 소유 계정은 `grid`다.
@B GI는 DB 소프트웨어보다 먼저 올라와야 한다. 데이터베이스가 쓸 디스크그룹과 클러스터 멤버십이 GI에서 나온다.

@H3 1.4.3  RAC 데이터베이스

@B DB 홈은 `/u01/app/oracle/product/19.3.0/dbhome_rac`, 소유 계정은 `oracle`이다.
@B 단일 인스턴스와 같은 소프트웨어에 RAC 옵션이 링크된 것이다. 생성할 때 여러 노드에 인스턴스를 배치한다는 점이 다르다.
@B grid와 oracle 계정을 나누면 스토리지 관리와 DB 관리의 권한을 분리할 수 있고, GI 패치와 DB 패치를 따로 적용할 수 있다.

@TBL
계층 | 하는 일 | 홈 · 계정 | 주 명령
Clusterware | 멤버십, 자원 기동·감시·페일오버 | Grid 홈 · grid (일부 root) | crsctl, olsnodes, oifcfg
ASM | 공유 디스크를 디스크그룹으로 제공 | Grid 홈 · grid | asmcmd, sqlplus / as sysasm
데이터베이스 | 인스턴스, 트랜잭션, Cache Fusion | DB 홈 · oracle | srvctl, sqlplus / as sysdba
@END

@BP 계층별로 명령을 구분한다
`srvctl`은 데이터베이스·인스턴스·리스너·서비스처럼 Oracle이 정의한 자원을 다루며 grid나 oracle 계정으로 실행한다. `crsctl`은 Clusterware 자체와 저수준 자원을 다루고 상당수가 root 권한을 요구한다.
같은 대상을 두 명령으로 볼 수 있어도 운영 작업은 `srvctl`로 한다. `crsctl`로 DB 자원을 직접 정지하면 Oracle이 정의한 의존 관계를 건너뛴다(11장).
@END

@H2 1.5  하나의 데이터베이스, 여러 인스턴스

@P 데이터베이스는 디스크 위의 파일 집합이고, 인스턴스는 그 파일을 다루는 메모리 구조와 백그라운드 프로세스의 집합이다. 단일 인스턴스 환경에서는 두 말을 섞어 써도 통하지만 RAC에서는 정확히 갈라 써야 한다.

@IMG 01_shared.png | 그림 1-3. 공유되는 것과 인스턴스마다 따로인 것 — 리두 스레드와 UNDO도 파일 자체는 공유 스토리지에 있다

@H3 1.5.1  공유되는 것과 따로인 것

@TBL
구분 | 항목 | 설명
공유(한 벌) | 데이터 파일, 데이터 사전 | 모든 인스턴스가 같은 파일을 읽고 쓴다
공유(한 벌) | 컨트롤 파일 | 다중화하되 같은 내용을 모든 인스턴스가 쓴다
공유(한 벌) | SPFILE | +DATA에 한 벌. `racdb1.` 같은 sid 접두어로 인스턴스별 값을 구분한다
공유(한 벌) | 암호 파일 | +DATA/RACDB/PASSWORD 아래 한 벌
인스턴스별 | SGA, PGA, 백그라운드 프로세스 | 노드 메모리에 따로 존재한다
인스턴스별 | 온라인 리두 스레드 | racdb1은 thread 1, racdb2는 thread 2
인스턴스별 | UNDO 테이블스페이스 | racdb1은 UNDOTBS1, racdb2는 UNDOTBS2
@END

@B 리두 스레드와 UNDO는 평소에 인스턴스마다 자기 것만 쓴다. 파일은 공유 스토리지에 있어서 다른 인스턴스도 읽을 수 있다.
@B 이 구조가 인스턴스 복구를 가능하게 한다. racdb2가 죽으면 racdb1이 thread 2의 리두를 읽고 UNDOTBS2의 정보로 미완료 트랜잭션을 되돌린다.
@B TEMP 테이블스페이스는 공유하되 인스턴스마다 익스텐트를 나눠 쓴다(10장).

@H3 1.5.2  GV$ 뷰 — 클러스터 전체를 보는 창

@B `V$` 뷰는 접속한 인스턴스의 정보만 보여 준다. 클러스터 전체는 `GV$` 뷰로 본다.
@B `GV$` 뷰에는 결과 행이 어느 인스턴스에서 왔는지 알려 주는 `INST_ID` 열이 붙는다.
@B 접속한 인스턴스가 다른 인스턴스에 병렬 슬레이브를 띄워 각자의 `V$`를 조회하고 결과를 모은다. 그래서 비용이 더 크고, 응답하지 않는 인스턴스가 있으면 조회가 멈출 수 있다.
@B 진단할 때 `V$`만 보고 "이상 없음"으로 판단하는 실수가 흔하다. 다른 노드의 문제는 `V$`에 나타나지 않는다.

@CODE
SYS@racdb1> SELECT inst_id, instance_name, host_name, status, thread#
  2  FROM gv$instance ORDER BY inst_id;

   INST_ID INSTANCE_NAME    HOST_NAME          STATUS      THREAD#
---------- ---------------- ------------------ -------- ----------
         1 racdb1           rac1.localdomain   OPEN              1
         2 racdb2           rac2.localdomain   OPEN              2
@END

@B 같은 세션에서 `V$INSTANCE`를 조회하면 racdb1 한 행만 나온다. `V$` 뷰에 `INST_ID`를 쓰면 ORA-00904 오류가 난다.

@NOTE INST_ID와 INSTANCE_NUMBER
`INST_ID`는 `GV$` 결과 행의 출처 인스턴스다. `INSTANCE_NUMBER`는 인스턴스에 부여된 고유 번호로 `instance_number` 파라미터가 정하고, 리두 스레드와 UNDO 배정의 기준이 된다. 실습 환경에서는 두 값이 같지만 의미는 다르다.
@END

@H3 1.5.3  RAC 구성을 확인하는 조회

@CODE
SELECT thread#, status, enabled, instance FROM v$thread ORDER BY 1;
SELECT inst_id, name, value FROM gv$parameter
 WHERE name IN ('undo_tablespace','instance_number','thread','cluster_database');
SELECT name FROM v$controlfile;
SELECT inst_id, name, open_mode FROM gv$pdbs WHERE name = 'RACPDB1';
@END

@B `v$thread`는 스레드 2개가 모두 OPEN·PUBLIC으로 보여야 한다.
@B `cluster_database`는 두 인스턴스 모두 TRUE다. 이 값이 FALSE면 인스턴스 하나만 데이터베이스를 열 수 있다.
@B PDB `racpdb1`이 한쪽 인스턴스에서만 READ WRITE면 그 노드로 붙은 세션만 PDB를 쓸 수 있다. 실습 환경은 `SAVE STATE INSTANCES=ALL`로 두 인스턴스 모두 자동으로 열리게 해 두었다.

@H2 1.6  Cache Fusion

@P 단일 인스턴스에서는 버퍼 캐시에 있는 블록이 곧 최신본이다. RAC에서는 같은 블록의 최신본이 다른 노드의 메모리에 있을 수 있다. Cache Fusion은 그 블록을 디스크에 쓰고 다시 읽는 대신 인터커넥트로 직접 보내 주는 구조다.

@IMG 01_cachefusion.png | 그림 1-4. Cache Fusion — rac2가 요청한 블록을 rac1의 LMS가 인터커넥트로 보낸다

@H3 1.6.1  GRD와 마스터

@B GRD(Global Resource Directory)는 어느 블록을 어느 인스턴스가 어떤 모드로 들고 있는지 기록한 분산 목록이다. 모든 인스턴스가 나눠서 관리한다.
@B 블록마다 GRD 정보를 관리하는 인스턴스를 마스터라 한다. 블록이 필요하면 먼저 마스터에 묻는다.
@B GCS(Global Cache Service)는 블록 이동을, GES(Global Enqueue Service)는 블록 외의 잠금을 조정한다. LMS 프로세스가 블록 전송을 실제로 수행한다.

@H3 1.6.2  2-way와 3-way

@TBL
유형 | 경로 | 언제
2-way | 요청 노드 → 마스터(=보유 노드) → 요청 노드 | 마스터가 블록도 들고 있을 때. 2노드에서는 대부분 이 경우
3-way | 요청 노드 → 마스터 → 보유 노드 → 요청 노드 | 마스터와 보유 노드가 다를 때. 3노드 이상에서 생긴다
@END

@H3 1.6.3  current 블록과 CR 블록

@B current 블록은 갱신하려고 가져오는 최신 블록이다. 한 시점에 한 인스턴스만 배타 모드로 가질 수 있다.
@B CR(consistent read) 블록은 읽기 일관성을 맞추려고 특정 시점으로 되돌린 사본이다. 보유 노드가 만들어 보내 준다.
@B 갱신 중인 블록을 다른 노드가 읽으면 보유 노드는 CR 사본을 만들어 보내고 자기는 current 블록을 계속 쥔다.

@H3 1.6.4  gc 대기 이벤트와 통계

@TBL
이름 | 종류 | 뜻
gc cr block 2-way | 대기 이벤트 | CR 블록을 2-way로 받는 동안 기다린 시간
gc current block 2-way | 대기 이벤트 | current 블록을 2-way로 받는 동안 기다린 시간
gc cr blocks received / served | 통계 | 받은 CR 블록 수 / 보내 준 CR 블록 수
gc current blocks received / served | 통계 | 받은 current 블록 수 / 보내 준 current 블록 수
@END

@B 통계는 인스턴스 기동 이후 누적값이다. 작업 전후 값을 `GV$SYSSTAT`에서 두 번 읽어 차이를 본다.
@B 한쪽의 received 증가분과 다른 쪽의 served 증가분이 맞아떨어지면 블록이 그 방향으로 건너간 것이다.
@B gc 대기가 길어지는 원인은 인터커넥트 지연, 특정 블록에 몰린 경합(hot block), 보내는 쪽 LMS의 CPU 부족 셋으로 나눠 본다(17장).

@CODE
SELECT inst_id, name, value FROM gv$sysstat
 WHERE name IN ('gc cr blocks received','gc cr blocks served',
                'gc current blocks received','gc current blocks served')
 ORDER BY name, inst_id;
@END

@H2 1.7  네트워크 구성 — 공용·VIP·SCAN·사설

@P RAC 노드는 주소를 네 종류 가진다. 클라이언트가 어떤 주소로 접속하느냐에 따라 장애 때의 동작이 달라진다.

@TBL
주소 | 실습 값 | 용도
공용 IP | rac1 172.16.225.101, rac2 172.16.225.102 (ens33) | 노드 관리용 접속, SSH
VIP | rac1-vip 172.16.225.111, rac2-vip 172.16.225.112 | 노드 리스너가 듣는 주소. 노드가 죽으면 다른 노드로 옮겨 간다
SCAN | rac-scan 172.16.225.120:1521 | 클라이언트 접속용 단일 이름. SCAN 리스너가 받아 서비스가 있는 인스턴스로 넘긴다
사설 IP | rac1-priv 172.16.119.101, rac2-priv 172.16.119.102 (ens160) | 하트비트, Cache Fusion, ASM 통신
@END

@H3 1.7.1  VIP

@B VIP는 Clusterware 자원(`ora.rac1.vip`)이다. 노드가 죽으면 살아 있는 노드로 옮겨 간다.
@B 옮겨 간 VIP에는 리스너가 없어서 접속 요청을 즉시 거절한다. 클라이언트는 TCP 타임아웃(수십 초~수 분)을 기다리지 않고 다음 주소로 넘어간다.
@B VIP가 막는 것은 타임아웃 대기다. 노드가 살아 있고 인스턴스만 내려간 경우에는 VIP가 옮겨 가지 않는다.

@H3 1.7.2  SCAN

@B SCAN(Single Client Access Name)은 클러스터 전체를 가리키는 접속 이름이다. 노드를 추가하거나 빼도 클라이언트 접속 문자열을 바꾸지 않아도 된다.
@B 운영 환경에서는 DNS에 IP 3개를 등록한다. 실습 환경은 dnsmasq가 `/etc/hosts`의 단일 IP(172.16.225.120)를 돌려주므로 SCAN 리스너도 하나(`LISTENER_SCAN1`)다.
@B 인스턴스는 `remote_listener=rac-scan:1521`로 SCAN 리스너에 서비스와 부하 정보를 등록한다. SCAN 리스너는 부하가 적은 인스턴스의 노드 리스너로 연결을 넘긴다.

@CODE
[oracle@rac1 ~]$ srvctl config scan
SCAN name: rac-scan, Network: 1
...
SCAN VIP name: scan1, IP: /rac-scan/172.16.225.120
[grid@rac1 ~]$ oifcfg getif
ens33  172.16.225.0  global  public
ens160  172.16.119.0  global  cluster_interconnect,asm
@END

@BP 접속 문자열에는 SCAN을 쓴다
노드 VIP나 공용 IP로 접속 문자열을 고정하면 그 노드의 인스턴스가 내려갔을 때 접속이 실패한다. 애플리케이션은 `rac-scan:1521/서비스명` 형식으로 접속하고, 어느 인스턴스로 갈지는 서비스 배치(12장)로 정한다.
@END

@H2 1.8  실습 환경

@P 이 과정의 모든 실습은 설치 가이드 v2로 구축한 2노드 클러스터에서 진행한다. 설치 절차는 가이드에 있고, 이 과정은 설치가 끝난 상태에서 시작한다.

@TBL
항목 | rac1 | rac2
호스트명 | rac1.localdomain | rac2.localdomain
공용 IP / VIP | 172.16.225.101 / 172.16.225.111 | 172.16.225.102 / 172.16.225.112
사설 IP | 172.16.119.101 | 172.16.119.102
ASM 인스턴스 | +ASM1 | +ASM2
DB 인스턴스 | racdb1 (thread 1) | racdb2 (thread 2)
VM | D:\RAC\RAC1, vCPU 4, 9216MB | D:\RAC\RAC2, vCPU 4, 9216MB
@END

@TBL
구분 | 값
클러스터 / SCAN | rac-cluster / rac-scan 172.16.225.120:1521
Grid 홈 (grid) | /u01/app/19.3.0/grid, ORACLE_BASE /u01/app/grid
DB 홈 (oracle) | /u01/app/oracle/product/19.3.0/dbhome_rac, ORACLE_BASE /u01/app/oracle
데이터베이스 | racdb, PDB racpdb1, 관리자 관리형, Management policy AUTOMATIC
OS | Oracle Linux 7.9, SELinux permissive, 시간 동기화 CTSS
실습용 추가 디스크 | /dev/asmdisk/test1~6 (4GB × 6). ASM 실습(4~7장) 전용 후보 디스크, 설치 가이드 v2 부록 E로 추가
기준 스냅샷 | rac-base (두 노드 정지 후 함께 뜸, 공유 디스크는 D:\RAC\SHARED 사본)
@END

@B 프롬프트로 노드와 계정을 구분한다. `[grid@rac1 ~]$`, `[oracle@rac2 ~]$`, `[root@rac1 ~]#`, `SYS@racdb1>`, `SYS@+ASM1>`.
@B grid 계정의 `ORACLE_SID`는 rac1에서 `+ASM1`, rac2에서 `+ASM2`다. oracle 계정은 rac1에서 `racdb1`, rac2에서 `racdb2`다. rac2에 racdb1을 적어 두면 ORA-01034가 난다.
@B GIMR(관리 저장소)은 구성하지 않았다. `crsctl status resource -t`에서 `ora.asmgroup`의 3번째 항목이 OFFLINE인 것은 정상이다.

@NOTE 스냅샷과 공유 디스크
공유 디스크는 independent-persistent 모드라 VM 스냅샷에 들어가지 않는다. `rac-base`로 되돌려도 OCR·보팅 파일·디스크그룹·데이터베이스는 그대로 남는다.
디스크까지 되돌려야 하는 실습(⚠ 표시) 전에는 두 노드를 모두 정지하고 `90_snapshot.ps1 -BackupShared`로 D:\RAC\SHARED 사본을 함께 남긴다.
@END

@H2 1.9  라이선스와 옵션 경계

@B RAC는 Enterprise Edition의 별도 유료 옵션이다. 2노드 클러스터면 두 노드의 프로세서 모두에 EE와 RAC 라이선스가 필요하다.
@B RAC One Node(16장)는 평소 인스턴스 하나만 돌리고 필요할 때 다른 노드로 옮기는 별도 옵션이다.
@B Clusterware와 ASM은 Oracle DB 라이선스가 있는 서버에서 추가 비용 없이 쓸 수 있다.
@B 옵션 사용 여부는 `V$OPTION`의 `Real Application Clusters` 행과 `DBA_FEATURE_USAGE_STATISTICS`로 확인한다. 실습 환경은 교육용이며 실무 라이선스 판단은 계약 조건을 따른다.

@H2 1.10  인스턴스 하나가 빠지면

@P racdb2를 정지했을 때 클러스터와 클라이언트에서 무엇이 계속되고 무엇이 끊기는지 정리한다. 실습 06이 이 과정을 직접 따라간다.

@IMG 01_failover.png | 그림 1-5. racdb2가 빠졌을 때 — racdb1이 thread 2로 인스턴스 복구를 하고 서비스를 이어 간다

@H3 1.10.1  계속되는 것

@B 데이터베이스는 열려 있다. racdb1에 붙은 세션은 아무 영향 없이 작업을 이어 간다.
@B Clusterware는 두 노드 모두에서 동작한다. 인스턴스만 내려간 경우 rac2의 노드 리스너, VIP, ASM 인스턴스도 그대로다.
@B SCAN으로 새로 접속하면 racdb1로 연결된다.

@H3 1.10.2  끊기는 것

@B racdb2에 붙어 있던 세션은 끊기고 커밋하지 않은 트랜잭션은 롤백된다.
@B rac2-vip로 직접 접속하면 ORA-12514(리스너가 서비스를 모름)가 난다. 리스너는 살아 있지만 racdb2가 등록했던 서비스가 사라졌기 때문이다.

@TBL
오류 | 상황
ORA-12514 | 리스너는 살아 있고 요청한 서비스가 등록되어 있지 않다
ORA-12541 | 그 주소에 리스너가 없다
ORA-12170 / ORA-12543 | 노드가 꺼져 TCP 연결 자체가 안 된다
@END

@B `srvctl start instance -d racdb -i racdb2`로 다시 올리면 클러스터에 합류한다. 다른 인스턴스로 옮겨 간 서비스는 자동으로 돌아오지 않는다(12장).

@H2 1.11  요약

@B RAC는 하나의 데이터베이스를 여러 인스턴스가 동시에 여는 구성이다. 수평 확장과 노드 장애 대응을 제공하고, 사이트 장애와 논리 오류는 막지 못한다.
@B 물리 요소는 노드, 인터커넥트, 공유 스토리지다. 소프트웨어는 Clusterware·ASM(Grid 홈, grid)과 데이터베이스(DB 홈, oracle) 세 층이다.
@B 데이터 파일·컨트롤 파일·SPFILE은 한 벌이고, 리두 스레드와 UNDO는 인스턴스마다 따로지만 파일은 공유 스토리지에 있다.
@B 클러스터 전체는 `GV$` 뷰로 본다. `V$`는 접속한 인스턴스만 보여 준다.
@B Cache Fusion은 다른 노드의 메모리에 있는 블록을 인터커넥트로 받아 온다. gc 통계와 대기 이벤트로 관찰한다.
@B 클라이언트는 SCAN으로 접속한다. VIP는 노드 장애 때 타임아웃을 막고, 사설망은 하트비트와 Cache Fusion을 나른다.

@H2 1.12  퀴즈

@QUIZ 퀴즈
1. RAC가 막지 못하는 장애 두 가지를 들고 각각 무엇으로 대비하는지 쓰시오.
2. racdb2가 죽었을 때 racdb1이 인스턴스 복구를 할 수 있는 이유를 리두 스레드와 파일 위치로 설명하시오.
3. `V$INSTANCE`와 `GV$INSTANCE`를 같은 세션에서 조회하면 결과 행 수가 어떻게 다른가?
4. gc cr block 2-way 대기가 늘었을 때 의심할 원인 세 가지는?
5. 노드가 살아 있고 racdb2 인스턴스만 내려간 상태에서 rac2-vip로 접속하면 어떤 오류가 나며 그 이유는?
6. 실습 환경에서 SCAN 리스너가 하나뿐인 이유는?
@END

@NOTE 정답과 해설
1. 공유 스토리지 손상·사이트 전체 정지(Data Guard), 잘못된 DML 같은 논리 오류(백업·플래시백). 모든 노드가 같은 스토리지를 쓰기 때문이다.
2. 리두 스레드와 UNDO는 인스턴스별로 쓰지만 파일은 +DATA에 있어 모든 인스턴스가 읽을 수 있다. racdb1의 SMON이 thread 2를 읽어 복구한다.
3. GV$INSTANCE는 두 행(INST_ID 1, 2), V$INSTANCE는 접속한 인스턴스 한 행이다.
4. 인터커넥트 지연, 특정 블록에 몰린 경합, 블록을 보내는 쪽 LMS의 CPU 부족.
5. ORA-12514. rac2의 리스너는 살아 있지만 racdb2가 등록했던 서비스가 사라져 리스너가 서비스를 모른다. VIP는 노드가 죽을 때만 옮겨 간다.
6. SCAN 이름을 DNS 대신 dnsmasq가 /etc/hosts의 단일 IP(172.16.225.120)로 풀기 때문이다. SCAN VIP와 SCAN 리스너는 IP 수만큼 만들어진다.
@END

@H2 1.13  실습 개요

@P 이 장의 실습은 조회 중심이다. 마지막 실습만 인스턴스 하나를 잠시 정지했다가 되살린다. 실습 파일은 저장소의 기존 RAC 트랜스크립트를 쓴다.

@TBL
실습 | 파일 | 목적
01 | RAC/01장/1장_실습_01_클러스터상태파악.txt | `crsctl status resource -t` 한 화면으로 클러스터 전체 상태를 읽는다
02 | RAC/01장/1장_실습_02_공유데이터베이스확인.txt | GV$와 V$의 차이, 공유 파일이 한 벌임을 확인한다
03 ★ | RAC/01장/1장_실습_03_CacheFusion실측.txt | 한 노드에서 갱신한 블록을 다른 노드에서 읽고 gc 통계 변화를 대조한다
06 ★ | RAC/01장/1장_실습_06_노드정지와복귀.txt | racdb2를 정지했을 때 계속되는 것과 끊기는 것을 확인하고 되살린다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다.
@B 수료 후 자습: 1장_실습_04_단일인스턴스와의구조차이, 1장_실습_05_라이선스경계확인.
@B 실습 03은 실습용 사용자 CF를 만들고 마지막에 지운다. 실습 06은 끝에서 `srvctl status database -d racdb`로 두 인스턴스가 모두 Open인지 확인하고 마친다.
