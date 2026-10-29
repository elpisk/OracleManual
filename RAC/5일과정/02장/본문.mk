@H1 제2장  Clusterware 구조와 프로세스

@H2 2.1  학습 목표

@P 1장에서 RAC를 Clusterware, ASM, 데이터베이스 세 층으로 나눴다. 이 장은 맨 아래 Clusterware 층을 다룬다. 두 개의 스택과 그 안의 프로세스, 기동 순서, 자원이라는 개념을 정리하고, 설치가 남긴 네트워크 구성과 Grid 홈을 읽는 방법을 익힌다.

@B OHAS 스택과 CRS 스택을 구분하고 각각이 쓰는 저장소(OLR, OCR)를 말할 수 있다.
@B ohasd, crsd, ocssd, cssdagent, cssdmonitor, 에이전트의 역할과 실행 계정을 설명할 수 있다.
@B alert.log로 기동 순서를 따라가고 CRS-1601, CRS-5019의 의미를 판독할 수 있다.
@B `crsctl stop cluster`와 `crsctl stop crs`의 차이, CRS-4639와 CRS-4535의 차이로 장애 계층을 판별할 수 있다.
@B 자원과 자원 유형, local 자원과 cluster 자원, 의존 관계를 `crsctl status resource -p`로 읽을 수 있다.
@B `oifcfg getif`, `/etc/hosts`, `srvctl config scan/vip`로 공용·VIP·사설·SCAN 구성을 확인할 수 있다.
@B Grid 홈과 DB 홈, 두 ORACLE_BASE의 차이와 진단 로그 위치를 구분할 수 있다.

@H2 2.2  두 개의 스택

@P Clusterware는 하나의 덩어리가 아니라 두 층의 스택이다. 아래층은 OHAS(Oracle High Availability Services) 스택, 위층은 CRS(Cluster Ready Services) 스택이다. 명령도 관리 대상도 저장소도 다르다.

@IMG 02_twostack.png | 그림 2-1. 두 개의 스택 — OHAS 스택은 로컬 OLR로, CRS 스택은 +CRS 안의 OCR로 움직인다

@H3 2.2.1  OHAS 스택 — 아래층

@B 노드가 부팅하면 systemd가 `oracle-ohasd` 유닛으로 `init.ohasd`를 실행하고, 여기서 ohasd가 뜬다. ohasd가 OHAS 스택의 진입점이다.
@B 유닛에는 `After=network-online.target`, `Restart=always`, `StartLimitBurst=0`, `TimeoutStopSec=60min`이 들어 있다. 네트워크가 올라온 뒤 기동하고, 죽으면 제한 없이 다시 띄우며, 정지에는 최대 한 시간을 준다.
@B OHAS 스택의 자원은 `crsctl status resource -t -init`로 본다. ora.cssd, ora.ctssd, ora.asm, ora.gpnpd, ora.gipcd, ora.evmd, ora.cluster_interconnect.haip, ora.crsd 같은 저수준 자원이 나온다.
@B 이 목록에 ora.crsd가 있다. 위층 스택 전체가 아래층에게는 자원 하나다.
@B ora.diskmon은 Exadata 스토리지 셀을 감시하는 자원이라 일반 환경에서 OFFLINE이 정상이다.

@H3 2.2.2  CRS 스택 — 위층

@B crsd가 뜨면 CRS 스택이 시작된다. 리스너, VIP, SCAN, 디스크그룹, 데이터베이스, 서비스 같은 운영 자원을 관리한다.
@B `crsctl status resource -t`를 `-init` 없이 실행하면 이 목록이 나온다. 1장 실습 01에서 본 화면이다.
@B 두 스택은 저장소가 다르다. OHAS 스택은 노드마다 하나씩 있는 로컬 파일 OLR(Oracle Local Registry)을, CRS 스택은 클러스터가 공유하는 OCR(Oracle Cluster Registry)을 쓴다.

@CODE
[root@rac1 ~]# cat /etc/oracle/olr.loc
olrconfig_loc=/u01/app/grid/crsdata/rac1/olr/rac1_19.olr
crs_home=/u01/app/19.3.0/grid
[root@rac1 ~]# ocrcheck | grep -E "ID|Device"
         ID                       :  665666554
         Device/File Name         :       +CRS
@END

@B OLR은 로컬 파일 시스템에 있고 OCR은 ASM 디스크그룹 +CRS 안에 있다. 부팅 직후에는 ASM이 아직 없으므로 OHAS 스택은 OLR만으로 일어서야 한다. crsd는 ASM이 +CRS를 마운트한 뒤에야 뜬다.
@B OLR ID는 노드마다 다르고 OCR ID는 두 노드에서 같다. OLR은 노드별로 따로 만든 레지스트리이고 OCR은 하나를 공유한다. 두 저장소의 관리는 3장에서 다룬다.

@NOTE ocrcheck와 ocrcheck -local
`ocrcheck`는 OCR을, `ocrcheck -local`은 OLR을 본다. ASM이 내려간 노드에서 `ocrcheck`를 실행하면 PROT-602와 PROC-26(Insufficient quorum to open OCR devices)으로 실패하지만 `ocrcheck -local`은 정상이다. 레지스트리 손상을 의심하기 전에 ASM이 떠 있는지부터 본다.
@END

@H3 2.2.3  계층을 명령으로 가른다

@P 조회 명령마다 묻는 대상이 정해져 있다. 어느 명령이 되고 어느 명령이 안 되는지로 죽은 계층을 판별한다.

@TBL
명령 | 묻는 대상 | 정상 응답
crsctl check has | ohasd | CRS-4638 online
crsctl status resource -t -init | ohasd | OHAS 자원 목록
crsctl check crs | ohasd·crsd·cssd·evmd | CRS-4638, 4537, 4529, 4533
crsctl status resource -t | crsd | 운영 자원 목록
srvctl, olsnodes | crsd·cssd | 자원 상태, 노드 목록
@END

@CODE
[root@rac2 ~]# crsctl check crs
CRS-4638: Oracle High Availability Services is online
CRS-4535: Cannot communicate with Cluster Ready Services
CRS-4530: Communications failure contacting Cluster Synchronization Services daemon
CRS-4534: Cannot communicate with Event Manager
@END

@B 위 출력은 rac2에서 `crsctl stop cluster`를 실행한 직후의 모습이다. ohasd는 살아 있고 crsd, ocssd, evmd는 내려갔다.
@B 이때 `crsctl status resource -t -init`는 조회되고, `-init` 없는 조회는 CRS-4535로 실패한다.

@H3 2.2.4  stop cluster와 stop crs

@TBL
항목 | crsctl stop cluster | crsctl stop crs
내리는 범위 | CRS 계층과 그 아래 저수준 자원 | OHAS를 포함한 노드 스택 전체
ohasd | 남는다 | 종료된다
정지 후 crsctl check has | CRS-4638 online | CRS-4639 접촉 불가
마지막 메시지 | CRS-2792 | CRS-2792 → CRS-2793 → CRS-4133
다시 올릴 때 | crsctl start cluster | crsctl start crs
쓰는 상황 | 노드를 클러스터에서 잠시 뺄 때 | 노드 정지, OS 패치
@END

@B CRS-2792는 CRS 관리 자원의 정지 완료, CRS-2793은 OHAS 관리 자원의 정지 완료, CRS-4133은 OHAS 자체의 정지다.
@B stop crs가 더 오래 걸린다. OHAS 계층까지 모두 내리기 때문이다. 작업 계획에 이 차이를 반영한다.
@B `-all`을 붙이면 모든 노드에 적용된다(`crsctl stop cluster -all`). 노드 하나만 내릴 때는 붙이지 않는다.

@H2 2.3  프로세스와 실행 계정

@P `ps`로 보면 Clusterware 프로세스는 root와 grid 두 계정으로 나뉘어 돈다. 노드를 재부팅시키거나 네트워크 주소를 올려야 하는 프로세스는 root로, 나머지는 grid로 돈다.

@H3 2.3.1  핵심 데몬

@TBL
프로세스 | 계정 | 역할 | 죽으면
ohasd.bin | root | OHAS 스택 진입점. 저수준 자원 기동·감시 | systemd가 즉시 재기동
crsd.bin | root | OCR을 읽어 운영 자원을 기동·감시·재배치 | ohasd가 재기동. 그동안 자원 관리 정지
ocssd.bin | grid | 노드 멤버십 판정. 하트비트와 보팅 파일 사용 | 노드 재부팅(스플릿 브레인 방지)
evmd.bin | grid | 이벤트 발행. FAN 이벤트의 출발점 | 이벤트 통지가 끊긴다
octssd.bin | root | 클러스터 시간 동기화(CTSS) | 시간 동기가 멈춘다
gpnpd.bin | grid | GPnP 프로필 관리(인터커넥트, ASM 발견 문자열) | 부팅 정보를 얻지 못한다
gipcd.bin | grid | 노드 간 통신 계층(Grid IPC) | 노드 간 통신이 끊긴다
mdnsd.bin | grid | 멀티캐스트 이름 해석 | 이름 발견 실패
osysmond.bin | root | 시스템 자원 수집(CHM) | 성능 이력이 끊긴다
@END

@B 실습 환경의 CTSS는 Active mode다. NTP가 구성되지 않았기 때문에 CTSS가 직접 시간을 맞춘다. `crsctl check ctss`로 확인한다.

@H3 2.3.2  감시자 — cssdagent와 cssdmonitor

@B cssdagent는 ocssd를 띄우고 상태를 감시한다. ocssd가 응답하지 않으면 노드를 재부팅한다.
@B cssdmonitor는 cssdagent와 시스템 행(hang)을 감시한다. 감시자를 다시 감시하는 구조다.
@B 둘 다 root로 돈다. 판단이 불가능해진 순간 노드를 내려야 하기 때문이다.
@B ocssd가 멈춘 노드는 자기가 클러스터에서 빠졌다는 사실도 모른다. 그 상태로 공유 스토리지에 계속 쓰면 데이터가 깨지므로 노드를 죽이는 쪽을 택한다. 이것이 축출(eviction)이다.

@CASE 감시 프로세스를 종료했다가 노드가 재부팅된 사례
운영 이관 전 점검에서 CPU를 쓰는 프로세스를 정리한다며 cssdmonitor를 kill했다. 몇 초 뒤 노드가 재부팅됐고 담당자는 하드웨어 결함을 의심했다.
감시 체계가 무너진 상태를 Clusterware는 데이터 손상보다 위험하게 본다. 프로세스 정리 규칙에서 Grid 홈의 프로세스를 제외하는 것을 운영 기준으로 둔다.
@END

@H3 2.3.3  에이전트

@B ohasd와 crsd는 지시만 하고, 자원을 실제로 기동·정지·점검하는 것은 에이전트다.
@B orarootagent는 root 권한이 필요한 자원(VIP, 네트워크, HAIP, 디스크그룹 일부)을, oraagent는 일반 계정 자원(리스너, ASM, 데이터베이스, 서비스)을 맡는다.
@B 에이전트는 계층별, 자원 소유자별로 하나씩 뜬다. 실습 환경에는 oraagent가 셋(OHAS용 grid, CRS용 grid, 데이터베이스용 oracle) 보인다.
@B 에이전트가 죽어도 자원은 살아 있다. 감시만 잠시 끊기고 crsd가 새 에이전트를 띄운다.

@H3 2.3.4  권한이 필요한 명령

@B `crsctl`의 check, get, status 계열은 grid로 된다. config 계열은 조회도 root를 요구한다. grid로 `crsctl config crs`를 실행하면 CRS-4563(Insufficient user privileges)이 난다.
@B root의 PATH에는 Grid 홈이 없다. root로 실행할 때는 `/u01/app/19.3.0/grid/bin/crsctl`처럼 전체 경로를 쓴다.

@H2 2.4  기동 순서

@P 스택이 올라오는 순서는 Clusterware alert.log에 그대로 남는다. 위치는 grid의 ORACLE_BASE 아래 `/u01/app/grid/diag/crs/rac1/crs/trace/alert.log`다.

@IMG 02_startup.png | 그림 2-2. 기동 순서 — OLR로 일어선 OHAS 스택이 멤버십을 확정하고, ASM이 +CRS를 마운트한 뒤 crsd가 뜬다

@CODE
[OHASD(2719)]  CRS-2112: The OLR service started on node rac1.
[OHASD(2719)]  CRS-1301: Oracle High Availability Service started on node rac1.
[OCSSD(3445)]  CRS-1601: CSSD Reconfiguration complete. Active nodes are rac1 rac2 .
[OCTSSD(4089)] CRS-2401: The Cluster Time Synchronization Service started on host rac1.
[ORAROOTAGENT] CRS-5019: All OCR locations are on ASM disk groups [CRS],
               and none of these disk groups are mounted.
[CRSD(4611)]   CRS-1012: The OCR service started on node rac1.
[CRSD(4611)]   CRS-1201: CRSD started on node rac1.
@END

@TBL
단계 | 무슨 일이 일어나는가
1 | systemd가 ohasd를 띄우고 ohasd가 OLR을 연다(CRS-2112)
2 | cssdagent, cssdmonitor, OHAS 계층 에이전트가 뜬다
3 | mdnsd, evmd, gpnpd, gipcd가 뜬다. 이름 해석과 노드 간 통신 기반
4 | ocssd가 뜨고 보팅 파일과 하트비트로 멤버십을 확정한다(CRS-1601)
5 | octssd가 뜬다(CRS-2401)
6 | ASM 인스턴스가 뜨기 전에는 OCR을 못 읽는다는 메시지가 남는다(CRS-5019)
7 | ASM이 +CRS를 마운트하면 crsd가 뜬다(CRS-1012, CRS-1201)
8 | crsd가 리스너, VIP, 디스크그룹, 데이터베이스 순으로 운영 자원을 올린다
@END

@B CRS-1601은 멤버십 재구성이 끝났다는 메시지다. Active nodes 목록이 그 결과다. 노드가 들어오거나 빠질 때마다 남으므로 축출 사고를 조사할 때 가장 먼저 찾는다(17장).
@B CRS-5019는 부팅 중에 정상적으로 나오는 과도기 메시지다. 잠시 뒤 ASM이 뜨면 해소된다. 이 줄만 보고 OCR 복구를 시작하면 없던 문제를 만든다.
@B CRS-5019에서 crsd 기동까지가 ASM 인스턴스를 띄우고 +CRS를 마운트하는 시간이다. 재부팅 직후 바로 접속하면 ORA-01034를 만나므로 몇 분 기다린 뒤 상태를 확인한다.
@B 정지는 기동의 역순이다. ons와 network 같은 위층 자원을 내리고 crsd를 내린 뒤, storage와 asm을 거쳐 cssd를 마지막에 내린다.

@H2 2.5  자원과 의존 관계

@P Clusterware에게 관리 대상은 모두 자원(resource)이다. 자원마다 유형(type)이 있고, 유형이 기동·정지·점검 방법을 정한다.

@H3 2.5.1  자원 이름과 유형

@TBL
자원 이름 규칙 | 예 | 유형
ora.<DB이름>.db | ora.racdb.db | ora.database.type
ora.<노드>.vip | ora.rac1.vip | ora.cluster_vip_net1.type
ora.<디스크그룹>.dg | ora.DATA.dg | ora.diskgroup.type
ora.LISTENER.lsnr | 노드 리스너 | ora.listener.type
ora.LISTENER_SCAN1.lsnr | SCAN 리스너 | ora.scan_listener.type
ora.scan1.vip | SCAN VIP | ora.scan_vip.type
@END

@B ora. 접두어는 Oracle이 정의한 자원이다. 이 자원은 `srvctl`로 다룬다. `crsctl`로 직접 기동·정지하면 Oracle이 정의한 처리 순서를 건너뛴다(11장).
@B 기본 유형은 local_resource와 cluster_resource 등이다. local 자원은 모든 노드에 하나씩 뜨고(리스너, ONS, 네트워크), cluster 자원은 클러스터 전체에서 개수가 정해진다(SCAN, VIP, 데이터베이스, 디스크그룹).
@B `crsctl status resource -t` 화면의 Local Resources와 Cluster Resources 두 덩어리가 이 구분이다.
@B 이름을 틀리면 CRS-2613(Could not find resource)이 난다. ora.racdb는 서버 풀 이름이고 데이터베이스 자원은 ora.racdb.db다. CRS-2613은 이름 문제이고 CRS-4535·CRS-4639는 통신 문제다.

@H3 2.5.2  속성으로 읽는 의존 관계

@CODE
[grid@rac1 ~]$ crsctl status resource ora.racdb.db -p | grep -E '^(CARDINALITY|PLACEMENT|AUTO_START|START_DEPENDENCIES)='
AUTO_START=restore
CARDINALITY=2
PLACEMENT=restricted
START_DEPENDENCIES=hard(global:uniform:ora.FRA.dg, global:uniform:ora.DATA.dg)
  pullup(global:ora.DATA.dg, global:ora.FRA.dg) weak(type:ora.listener.type, ...)
@END

@B CARDINALITY=2는 인스턴스 두 개, PLACEMENT=restricted는 정해진 노드에만 배치한다는 뜻이다. 관리자 관리형 데이터베이스의 모습이다.
@B AUTO_START=restore는 재부팅 전 상태로 되돌린다는 뜻이다. 기동 상태였으면 올리고 정지 상태였으면 두고 본다.
@B hard 의존은 대상이 먼저 ONLINE이어야 기동한다는 뜻이다. +DATA와 +FRA가 없으면 racdb는 뜨지 않는다. weak 의존(리스너)은 없어도 기동은 한다.
@B ACL에서 소유자는 oracle이고 grid에는 r-x만 있다. 데이터베이스 자원의 권한 분리가 자원 수준에서 강제된다.

@H3 2.5.3  자원 재배치와 페일백

@B 클러스터에 하나만 필요한 자원(ora.scan1.vip, ora.cvu, ora.qosmserver)은 그 노드의 스택이 내려가면 살아 있는 노드로 옮겨 간다.
@B 노드가 돌아와도 자동으로 되돌아가지 않는다. 장애와 점검이 반복되면 자원이 한쪽으로 쏠리므로 주기적으로 배치를 보고 필요하면 `srvctl relocate`로 옮긴다.
@B 서버 풀은 `crsctl status serverpool`로 본다. Free, Generic, ora.racdb가 있고 두 노드가 Generic과 ora.racdb에 들어 있다.

@H2 2.6  장애 계층 판별

@P 명령이 실패했을 때 오류 번호가 어느 계층에 닿지 못했는지 알려 준다.

@IMG 02_diagnose.png | 그림 2-3. 장애 계층 판별 — 아래층 명령이 되는지, 다른 노드에서는 어떻게 보이는지로 범위를 좁힌다

@TBL
명령 | stop crs 후 | stop cluster 후
crsctl check has | CRS-4639 | CRS-4638 online
crsctl check crs | CRS-4639 | CRS-4638 뒤에 CRS-4535, 4530, 4534
crsctl status resource -t -init | CRS-4639 | 조회됨(대부분 OFFLINE)
crsctl status resource -t | CRS-4535 | CRS-4535
srvctl status database | PRKH-1010, PRKH-3003 | PRKH-1010, PRKH-3003
olsnodes -s | PRCO-19, PRCO-2 | PRCO-19, PRCO-2
@END

@B CRS-4639는 ohasd에 닿지 못한 것이다. 스택 전체가 내려가 있다.
@B CRS-4535는 crsd, CRS-4530은 ocssd, CRS-4534는 evmd에 닿지 못한 것이다. ohasd는 살아 있을 수 있다.
@B PRKH-1010과 PRKH-3003은 srvctl이 CRS와 CSS 데몬에 닿지 못했다는 뜻이다.
@B 한 노드에서 명령이 실패하면 다른 노드에서 `olsnodes -s -n`을 실행한다. 그 노드만 Inactive면 노드 문제이고, 다른 노드에서도 실패하면 클러스터 전체 문제다.

@CODE
[grid@rac1 ~]$ olsnodes -s -n
rac1    1       Active
rac2    2       Inactive
@END

@BP 한 노드에서 실패하면 다른 노드에서 확인한다
스택이 내려간 노드에서 srvctl을 반복 실행하면 결과는 매번 같다. 살아 있는 노드에서 `olsnodes -s`를 한 번 실행하면 문제 범위가 확정된다. RAC 진단은 두 노드를 오가며 한다.
@END

@H3 2.6.1  CSS 파라미터와 자동 기동

@TBL
값 | 실습 환경 | 뜻
misscount | 30초 | 인터커넥트 하트비트가 이만큼 끊기면 네트워크 장애로 판단
disktimeout | 200초 | 보팅 파일 I/O가 이만큼 응답 없으면 디스크 장애로 판단
reboottime | 3초 | 축출 결정 후 재부팅까지 주는 시간
@END

@B 조회는 grid로 `crsctl get css misscount`처럼 한다. 기본값 유지를 권장한다. misscount를 늘리면 일시적 지연에는 덜 죽지만 진짜 장애 감지가 늦어진다.
@B 자동 기동 여부는 root로 `crsctl config crs`로 본다. CRS-4622가 enabled, CRS-4621이 disabled다.
@B OS 패치처럼 재부팅이 반복되는 작업은 `crsctl disable crs`로 막아 두고 끝에 `crsctl enable crs`로 되돌린다. 되돌리지 않으면 다음 재부팅 때 그 노드가 조용히 빠진다.

@H2 2.7  설치가 남긴 네트워크 구성

@P 네트워크와 이름 해석은 설치 가이드 v2의 3장(노드 OS 설정)과 5장(사전 점검)에서 구성했다. 운영에서는 그 결과를 읽고 맞는지 확인할 줄 알아야 한다.

@IMG 02_network.png | 그림 2-4. 인터페이스별 주소 — 공용·사설은 OS가, VIP·SCAN·HAIP는 Clusterware가 올린다

@H3 2.7.1  인터페이스와 주소

@CODE
[root@rac1 ~]# ip -o -4 addr show | awk '{print $2, $4}'
ens33   172.16.225.101/24
ens33   172.16.225.111/24
ens33   172.16.225.120/24
ens160  172.16.119.101/24
ens160  169.254.27.118/19
@END

@B ens33에는 공용 IP(.101), rac1-vip(.111), SCAN(.120)이 함께 올라와 있다. ens160에는 사설 IP와 HAIP(169.254.x.x)가 있다.
@B 공용·사설 IP는 OS가 올리고 VIP·SCAN·HAIP는 Clusterware가 올린다. 설치 전에는 VIP와 SCAN 주소가 어디에도 붙어 있으면 안 된다.
@B SCAN VIP는 클러스터에 하나뿐이라 어느 한 노드에만 보인다. 앞 절의 페일백 없음 때문에 rac1에 남아 있을 수도 있다.
@B HAIP는 인터커넥트를 위해 Clusterware가 자동으로 붙인 링크 로컬 주소다. ASM과 데이터베이스는 이 주소로 인터커넥트 통신을 한다.

@H3 2.7.2  oifcfg — 등록된 용도

@CODE
[grid@rac1 ~]$ oifcfg getif
ens160  172.16.119.0  global  cluster_interconnect,asm
ens33   172.16.225.0  global  public
[grid@rac1 ~]$ oifcfg iflist -p -n
ens33   172.16.225.0  PRIVATE  255.255.255.0
ens160  172.16.119.0  PRIVATE  255.255.255.0
ens160  169.254.0.0   UNKNOWN  255.255.224.0
@END

@B `getif`는 Clusterware에 등록된 용도다. ens33은 public, ens160은 cluster_interconnect와 asm이다. 운영 판단의 근거는 getif다.
@B `iflist -p`의 PRIVATE은 RFC 1918 사설 대역이라는 뜻일 뿐이다. 172.16.225.x도 사설 대역이라 PRIVATE으로 나온다. 인터커넥트라는 뜻이 아니다.
@B 용도를 바꾸는 명령은 `oifcfg setif`다. 인터커넥트 변경은 클러스터 재기동이 따르는 작업이라 계획 작업으로 다룬다.
@B 두 대역이 실제로 다른 경로로 나가는지는 `ip route`와 `ping -I ens160 rac2-priv`로 확인한다.

@H3 2.7.3  이름 해석 — /etc/hosts와 dnsmasq

@CODE
172.16.225.101  rac1.localdomain  rac1
172.16.225.111  rac1-vip.localdomain  rac1-vip
172.16.119.101  rac1-priv.localdomain  rac1-priv
172.16.225.120  rac-scan.localdomain  rac-scan
@END

@B 2노드 클러스터에는 공용 2, VIP 2, 사설 2, SCAN 1 해서 이름 일곱 개가 필요하다. 위는 그중 rac1 쪽 셋과 SCAN이다. FQDN과 짧은 이름을 함께 적고, 두 노드의 파일은 `diff`로 대조해 같게 둔다.
@B cluvfy는 네임서버가 지정되어 있고 그 네임서버가 노드 이름을 풀 것을 함께 요구한다. 실습 환경은 각 노드의 dnsmasq가 `/etc/hosts`를 DNS로 서비스하고 `/etc/resolv.conf`는 127.0.0.1을 가리킨다.
@B dnsmasq의 `expand-hosts`는 짧은 이름에 도메인을 붙여 FQDN으로도 답하게 하고, `no-resolv`는 자기 자신을 상위 DNS로 삼는 무한 참조를 막는다.
@B `/etc/hosts`를 고치면 두 노드 모두 고치고 dnsmasq를 재시작해야 반영된다.
@B SCAN이 IP 하나로만 풀리므로 `cluvfy comp scan`은 PRVG-11368 경고를 낸다. IP 3개를 권장한다는 경고이고 실패는 아니다.

@H3 2.7.4  srvctl로 보는 SCAN과 VIP

@CODE
[grid@rac1 ~]$ srvctl config scan
SCAN name: rac-scan, Network: 1
Subnet IPv4: 172.16.225.0/255.255.255.0/ens33, static
SCAN 1 IPv4 VIP: 172.16.225.120
[grid@rac1 ~]$ srvctl config vip -node rac2
VIP Name: rac2-vip
VIP IPv4 Address: 172.16.225.112
@END

@B `srvctl config scan`은 SCAN 이름, 서브넷, SCAN VIP 목록을, `srvctl config scan_listener`는 SCAN 리스너와 포트를 보여 준다.
@B `srvctl config vip -node`는 노드 VIP의 이름과 주소를, `srvctl config nodeapps`는 VIP·네트워크·ONS를 함께 보여 준다.
@B 없는 노드를 지정하면 PRKO-2310(VIP does not exist)이 난다. 노드 이름 오타를 잡는 데 쓴다.

@H2 2.8  Grid 홈과 두 ORACLE_HOME

@P RAC 서버에는 Oracle 홈이 둘 있다. Clusterware와 ASM이 쓰는 Grid 홈과 데이터베이스가 쓰는 DB 홈이다. 계정마다 ORACLE_HOME, ORACLE_SID, ORACLE_BASE가 모두 다르다.

@IMG 02_homes.png | 그림 2-5. 두 홈과 두 ORACLE_BASE — 진단 로그 위치와 adrci가 보여 주는 목록이 계정에 따라 갈린다

@TBL
계정 | ORACLE_HOME | ORACLE_SID (rac1/rac2) | ORACLE_BASE
grid | /u01/app/19.3.0/grid | +ASM1 / +ASM2 | /u01/app/grid
oracle | /u01/app/oracle/product/19.3.0/dbhome_rac | racdb1 / racdb2 | /u01/app/oracle
@END

@H3 2.8.1  Grid 홈의 주요 디렉터리

@TBL
경로 | 내용
bin | crsctl, srvctl, olsnodes, oifcfg, ocrcheck, ocrconfig, asmcmd, cluvfy, sqlplus, lsnrctl
crs/install | rootcrs.sh 등 구성 스크립트
network/admin | ASM 리스너와 SCAN 리스너가 쓰는 listener.ora
dbs | ASM 인스턴스 관련 파일
install | 설치 때 생긴 파일과 root.sh 로그
cv, deinstall, addnode | cluvfy 자료, 제거 도구, 노드 추가 도구(15장)
@END

@B Grid 홈은 grid의 ORACLE_BASE 하위가 아니다. `/u01/app/19.3.0/grid`는 `/u01/app/grid` 밖에 있다. Grid 홈의 상위 경로가 root 소유여야 하기 때문에 생긴 19c의 표준 배치다. DB 홈은 `/u01/app/oracle` 아래에 있다.
@B sqlplus는 두 홈에 각각 있다. grid에서는 Grid 홈의 것이, oracle에서는 DB 홈의 것이 잡힌다. 어느 쪽인지는 PATH와 ORACLE_HOME이 정한다.
@B 설치된 홈 목록은 `/u01/app/oraInventory/ContentsXML/inventory.xml`에 있다. 인벤토리가 가장 확실한 근거다.
@B `/etc/oratab`은 dbstart가 쓰던 목록이다. RAC 데이터베이스의 구성과 자동 기동은 `srvctl config database -d racdb`의 Type(RAC)과 Management policy(AUTOMATIC)로 확인한다(9장).

@H3 2.8.2  진단 로그가 갈리는 곳

@TBL
대상 | 위치
Clusterware | /u01/app/grid/diag/crs/rac1/crs/trace/alert.log, ocssd.trc, crsd.trc
ASM 인스턴스 | /u01/app/grid/diag/asm/+asm/+ASM1/trace/alert_+ASM1.log
리스너·SCAN 리스너 | /u01/app/grid/diag/tnslsnr/rac1/listener, listener_scan1
데이터베이스 | /u01/app/oracle/diag/rdbms/racdb/racdb1/trace/alert_racdb1.log
@END

@B adrci는 실행한 계정의 ORACLE_BASE 아래 진단 홈만 보여 준다. oracle로 `adrci exec="show homes"`를 실행하면 diag/crs가 목록에 없다. 로그가 없는 것이 아니라 계정이 다른 것이다.
@B Clusterware 진단은 grid로 한다. 파일 자체는 grid:oinstall 소유에 그룹 읽기 권한이 있어 oracle로도 경로를 알면 읽힌다.
@B 사람이 먼저 읽을 것은 alert.log다. CRS-nnnnn 코드가 붙어 있고, 상세가 필요하면 메시지가 가리키는 .trc 파일로 간다.

@BP 작업을 시작할 때 세 가지를 출력한다
`whoami; echo $ORACLE_HOME; echo $ORACLE_SID`를 먼저 실행한다. rac2에서 racdb1을 찾아 ORA-01034를 내거나, oracle 계정에서 Clusterware 로그를 찾다가 없다고 판단하는 실수가 여기서 걸러진다.
@END

@H2 2.9  요약

@B Clusterware는 OHAS 스택(ohasd, OLR)과 CRS 스택(crsd, OCR) 두 층이다. 위층 전체가 아래층에게는 ora.crsd 자원 하나다.
@B OLR은 노드 로컬 파일이라 ASM 없이 읽히고, OCR은 +CRS 안에 있어 ASM이 뜬 뒤에야 crsd가 올라온다.
@B 노드를 재부팅할 권한이 필요한 ohasd, crsd, cssdagent, cssdmonitor, octssd, osysmond는 root로 돈다. 감시 프로세스를 죽이면 노드가 재부팅된다.
@B 기동 로그의 CRS-1601은 멤버십 확정, CRS-5019는 부팅 중 과도기 메시지다.
@B CRS-4639는 ohasd, CRS-4535는 crsd에 닿지 못한 것이다. 한 노드에서 실패하면 다른 노드에서 `olsnodes -s`로 범위를 정한다.
@B ora. 자원은 srvctl로 다루고, 의존 관계는 `crsctl status resource -p`로 읽는다. 옮겨 간 자원은 돌아오지 않는다.
@B 네트워크 용도는 `oifcfg getif`가 정답이다. 이름 해석은 /etc/hosts를 dnsmasq가 서비스하고 SCAN은 IP 하나로 풀린다.
@B grid와 oracle은 ORACLE_HOME, ORACLE_SID, ORACLE_BASE가 모두 다르고 진단 로그도 각자의 ORACLE_BASE 아래에 있다.

@H2 2.10  퀴즈

@QUIZ 퀴즈
1. `crsctl check has`는 online인데 `crsctl check crs`가 CRS-4535를 낸다. 어느 계층이 내려갔으며 자원은 어떤 명령으로 조회할 수 있는가?
2. 정지 출력만 보고 `stop cluster`와 `stop crs`를 구별하려면 어떤 메시지를 보는가?
3. 부팅 로그의 CRS-5019(OCR이 있는 디스크그룹 미마운트)에 조치가 필요한가?
4. crsd가 ocssd보다 늦게 뜨는 구조적 이유를 OLR과 OCR의 위치로 설명하시오.
5. `oifcfg iflist -p`가 ens33을 PRIVATE으로 보여 준다. 공용망 설정이 잘못된 것인가?
6. oracle 계정의 `adrci show homes`에 diag/crs가 없다. Clusterware 로그가 없는 것인가?
@END

@NOTE 정답과 해설
1. crsd 이하가 내려갔고 ohasd는 살아 있다. `crsctl status resource -t -init`는 ohasd에 묻기 때문에 조회된다.
2. CRS-4133(Oracle High Availability Services has been stopped). stop crs에서는 CRS-2792, CRS-2793에 이어 CRS-4133까지 나오고 stop cluster는 CRS-2792에서 끝난다.
3. 필요 없다. ASM이 +CRS를 마운트하기 전의 과도기 메시지이며 잠시 뒤 crsd가 뜬다.
4. ohasd는 로컬 파일인 OLR만으로 시작한다. crsd는 +CRS 안의 OCR을 읽어야 하므로 ocssd가 멤버십을 확정하고 ASM이 +CRS를 마운트한 뒤에 뜬다.
5. 아니다. PRIVATE은 RFC 1918 사설 대역이라는 뜻이다. Clusterware 용도는 `oifcfg getif`의 public으로 확인한다.
6. 아니다. adrci는 실행 계정의 ORACLE_BASE 아래만 보여 준다. Clusterware 로그는 /u01/app/grid/diag 아래에 있으므로 grid 계정으로 확인한다.
@END

@H2 2.11  실습 개요

@P 이 장의 실습은 대부분 조회다. 실습 02-05만 rac2의 Clusterware를 정지했다가 되살린다. 끝나면 `crsctl check cluster -all`과 `srvctl status database -d racdb`로 원상 복구를 확인한다.

@TBL
실습 | 파일 | 목적
02-01 | RAC/02장/2장_실습_01_Clusterware프로세스식별.txt | systemd 진입점부터 프로세스 목록과 실행 계정을 정리한다
02-02 | RAC/02장/2장_실습_02_두스택의구분.txt | check has와 check crs, -init 조회, OLR과 OCR을 대조한다
02-03 | RAC/02장/2장_실습_03_자원개념과유형.txt | 자원 유형, 속성, 의존 관계, 서버 풀을 읽는다
02-05 ★ | RAC/02장/2장_실습_05_정지시오류재현.txt | stop cluster와 stop crs 후의 오류를 계층별로 구분한다
03-01 | RAC/03장/3장_실습_01_네트워크요건확인.txt | 인터페이스 주소, oifcfg getif와 iflist, 경로 분리를 확인한다
04-06 | RAC/04장/4장_실습_06_Grid홈구조.txt | Grid 홈의 디렉터리와 실행 파일, 스크립트 권한을 본다
04-07 | RAC/04장/4장_실습_07_두ORACLE_HOME구분.txt | 계정별 환경 변수, 인벤토리, 진단 로그 위치를 구분한다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다. 스냅샷이 필요한 실습은 없다.
@B 수료 후 자습: 2장_실습_04_기동순서추적, 2장_실습_06_로그위치확인, 2장_실습_07_자동기동과CSS파라미터, 3장_실습_02_이름해석검증.
@B 03-01, 04-06, 04-07은 RAC/03장·04장 폴더의 트랜스크립트다. 실습 번호는 폴더 번호와 파일 번호를 이은 것이다. 설치 단계 설명(cluvfy, cvuqdisk, root.sh 래퍼)은 건너뛰고 확인 명령만 따라간다.
