@H1 제15장  노드 추가와 삭제

@H2 15.1  학습 목표

@P 노드를 빼는 이유는 대개 하드웨어 교체나 장애이고, 넣는 이유는 증설이다. 어느 쪽이든 절차가 길고, 중간에 끊기면 반쯤 구성된 노드가 남는다. 이 장은 rac2를 클러스터에서 완전히 빼고 소프트웨어까지 지운 뒤 다시 넣는 과정을 따라간다. 그 사이 rac1의 racdb1은 한 번도 멈추지 않는다.

@B 노드 하나가 기록되는 세 곳(OCR, 중앙 인벤토리, 데이터베이스 구성)과 각각을 다루는 명령을 말할 수 있다.
@B 노드 삭제 다섯 단계를 순서대로 설명하고 각 단계를 어느 노드에서 어느 계정으로 실행하는지 구분할 수 있다.
@B 인벤토리 노드 목록을 `-updateNodeList`로 줄이고 늘리는 규칙(`-local`의 의미)을 설명할 수 있다.
@B `cluvfy stage -pre nodeadd`와 `-post nodedel`·`-post nodeadd`의 역할과 PRVG-11550의 원인을 설명할 수 있다.
@B `addnode.sh`, `root.sh`, `dbca -addInstance`로 노드와 인스턴스를 다시 넣는 순서를 말할 수 있다.
@B 복사 도중 끊긴 재추가의 잔재를 보고 다시 실행해도 되는지 판단할 수 있다.
@B 작업 전후의 기준선(자원 수, OCR·OLR ID, 스레드·UNDO)을 비교해 원복을 검증할 수 있다.

@H2 15.2  노드 관리 작업의 전체 그림

@P 노드 하나는 세 곳에 기록되어 있다. 지울 때도 넣을 때도 세 곳을 모두 맞춰야 한다. 어느 하나만 어긋나도 당장은 증상이 없다가 다음 작업에서 문제가 드러난다.

@IMG 15_layers.png | 그림 15-1. 노드 하나가 기록되는 세 곳 — 클러스터 구성, 소프트웨어 등록, 데이터베이스 구성

@H3 15.2.1  세 계층

@TBL
계층 | 어디에 있는가 | 무엇으로 다루는가
클러스터 구성 | OCR(공유 디스크 +CRS), 노드마다 OLR | `rootcrs.sh -deconfig`, `crsctl delete node`, 그리드 홈 `root.sh`
소프트웨어 등록 | 노드마다의 중앙 인벤토리 `/u01/app/oraInventory/ContentsXML/inventory.xml` | `-updateNodeList`, `deinstall`, `addnode.sh`
데이터베이스 구성 | 컨트롤 파일·SPFILE, CRS의 `ora.racdb.db` 자원 | `dbca -deleteInstance`, `dbca -addInstance`
@END

@B 클러스터는 OCR만 보고 돈다. 인벤토리가 틀려도 평소에는 아무 증상이 없다.
@B 인벤토리가 문제 되는 것은 소프트웨어를 다루는 순간이다. `deinstall`은 인벤토리의 노드 목록으로 어디서 지울지를 정하고, `addnode.sh`와 패치 도구는 어디로 복사하고 패치할지를 정한다.
@B 인벤토리 노드 목록은 각 홈의 `$ORACLE_HOME/oui/bin/runInstaller -updateNodeList`로 고친다. 소프트웨어를 설치하는 것이 아니라 inventory.xml 의 노드 목록만 바꾼다.

@H3 15.2.2  삭제와 추가의 순서

@TBL
단계 | 삭제 (위에서 아래로) | 추가 (아래에서 위로)
1 | DB 인스턴스 삭제 (`dbca -deleteInstance`) | 그리드 홈 확장 (`addnode.sh`)
2 | DB 홈 삭제 (`deinstall`) | rac2에서 그리드 홈 `root.sh`
3 | Clusterware 해제 (`rootcrs.sh -deconfig -force`) | DB 홈 확장 (`addnode.sh`)
4 | OCR에서 노드 삭제 (`crsctl delete node`) | rac2에서 DB 홈 `root.sh`
5 | 그리드 홈 삭제 (`deinstall`) | DB 인스턴스 추가 (`dbca -addInstance`)
@END

@B 삭제는 설치의 역순이다. 위에 올린 것부터 내린다.
@B 추가에는 삭제의 3·4단계에 해당하는 명령이 따로 없다. 그리드 홈의 `root.sh`가 OLR 생성, 하위 스택 기동, OCR 등록을 한 번에 한다.

@H3 15.2.3  되돌림 지점

@B 노드 삭제는 되돌릴 수 없다. OCR에서 노드가 지워지고 rac2의 소프트웨어가 삭제된다.
@B 실습 환경의 공유 디스크는 independent-persistent라 VM 스냅샷에 들어가지 않는다. 스냅샷으로 되돌리면 rac2의 로컬 디스크는 돌아오지만 OCR은 삭제된 상태 그대로다.
@B 그래서 두 노드를 함께 정지해 뜬 스냅샷, `-BackupShared` 사본, 작업 직전의 OCR 수동 백업을 합쳐 되돌림 지점으로 삼는다(3장).

@H2 15.3  추가·삭제 전 점검

@P 점검의 목적은 두 가지다. 작업할 수 있는 상태인지 확인하고, 나중에 비교할 기준선을 숫자로 남긴다. 실습 01이 이 단계다.

@H3 15.3.1  노드 목록과 함께 사라지는 자원

@CODE
[grid@rac1 ~]$ olsnodes -n -s -t
rac1    1       Active  Unpinned
rac2    2       Active  Unpinned
[grid@rac1 ~]$ srvctl config vip -node rac2
VIP Name: rac2-vip
VIP IPv4 Address: 172.16.225.112
@END

@B 세 번째 열이 Pinned인 노드는 `crsctl delete node` 전에 `crsctl unpin css`로 풀어야 한다. 11.2 이후 기본값은 Unpinned다.
@B 노드 번호 1, 2를 적어 둔다. 지웠다 다시 넣은 뒤 번호가 그대로인지 확인한다.
@B rac2-vip는 rac2 전용 자원이다. 노드를 지우면 함께 지워지고, 다시 넣을 때 `addnode.sh`의 `CLUSTER_NEW_VIRTUAL_HOSTNAMES`로 되살린다. 이름과 주소를 기록한다.
@B LISTENER, ONS, 네트워크 자원은 정의가 하나이고 노드마다 행이 붙는 구조다. 노드를 지워도 자원 수는 줄지 않는다. SCAN VIP는 rac1에 떠 있어 rac2를 지워도 SCAN 접속은 끊기지 않는다.

@H3 15.3.2  OCR 수동 백업과 기준선

@CODE
[root@rac1 ~]# /u01/app/19.3.0/grid/bin/ocrconfig -manualbackup
rac1     2026/10/14 19:53:35     +CRS:/rac-cluster/OCRBACKUP/backup_20261014_195335.ocr.261.1246650815
@END

@B 자동 백업은 4시간·하루·한 주 주기라 시점을 고를 수 없다. 작업 직전에 수동 백업을 뜬다.

@TBL
항목 | 작업 전 값 | 확인 명령
노드 | rac1(1), rac2(2) | `olsnodes -n -s -t`
CRS 자원 / -init 자원 | 17 / 13 | `crsctl stat res`, `crsctl stat res -init`
보팅 파일 | 3, 모두 ONLINE, +CRS | `crsctl query css votedisk`
OCR ID | 665666554 | `ocrcheck`
OLR ID | rac1 1636561748 / rac2 877385927 | `ocrcheck -local`
서비스 | `gv$active_services` 10행 | SQL
리두 그룹 / UNDO | 4(스레드당 2) / UNDOTBS1, UNDOTBS2 | `v$log`, `gv$parameter`
@END

@H3 15.3.3  인벤토리 노드 목록

@B 실습 환경의 `inventory.xml`에는 그리드 홈과 dbhome_rac 아래에 노드 목록이 비어 있었고, 그리드 홈에 `CRS="true"` 표시도 없었다. 설치 때 인벤토리 그룹 문제를 고치느라 인벤토리를 손댄 것이 원인으로 보이지만 로그로 확정하지는 못했다.
@B 이 상태로 삭제를 시작하면 `deinstall`이 어느 노드가 클러스터 노드인지 알지 못한다. 먼저 목록을 등록한다.

@CODE
[grid@rac1 ~]$ $ORACLE_HOME/oui/bin/runInstaller -updateNodeList -silent \
>   ORACLE_HOME=/u01/app/19.3.0/grid "CLUSTER_NODES={rac1,rac2}" CRS=TRUE
'UpdateNodeList' was successful.
@END

@B 홈 소유자로 실행한다. 그리드 홈은 grid, DB 홈은 oracle이다.
@B `CRS=TRUE`는 그리드 홈에만 붙인다. 빼면 `CRS="true"` 표시가 생기지 않는다.
@B `-local` 없이 rac1에서 실행하면 rac2의 인벤토리도 함께 고쳐진다.

@H3 15.3.4  cluvfy — 삭제 사전 점검은 없다

@B `cluvfy stage -pre nodeadd -n rac2`는 노드 추가 전 점검이다. rac2가 이미 멤버인 상태에서 치면 "already appears to be part of cluster"를 알리고 통과한다.
@B `-pre nodedel`을 치면 오류 대신 사용법이 나온다. 삭제는 사후 점검(`-post nodedel`)만 있다.
@B 삭제 전 점검은 pin 상태, 자원, OCR 백업, 인벤토리를 직접 보는 것으로 대신한다.
@B 함께 돌린 `cluvfy stage -post crsinst`의 경고는 PRVG-11368 하나였다. SCAN이 IP 3개 이상으로 풀리기를 권고하는 내용이고, 단일 IP로 구성한 이 환경의 설계 그대로다.

@H2 15.4  노드 삭제

@P 삭제는 다섯 단계다. 실행하는 노드와 계정이 단계마다 다르다. 실습 02는 1시간이 넘게 걸리고 되돌리기 어려워 강사가 시연하고 수강생은 트랜스크립트로 각 단계의 출력을 판독한다.

@IMG 15_delete.png | 그림 15-2. 노드 삭제 다섯 단계 — 단계마다 실행 노드와 계정이 다르다

@H3 15.4.1  DB 인스턴스 삭제(rac1)

@CODE
[oracle@rac1 ~]$ dbca -silent -deleteInstance -gdbName racdb -instanceName racdb2 \
>   -nodeName rac2 -sysDBAUserName sys -sysDBAPassword <SYS 비밀번호>
Instance "racdb2" deleted successfully from node "rac2".
@END

@B 실행은 살아남는 rac1에서 한다. `dbca`가 열려 있는 racdb1에 붙어서 데이터베이스 안의 구조를 지운다.
@B thread 2, 리두 그룹 3·4, UNDOTBS2가 지워지고 `gv$active_services`가 10행에서 5행으로 준다.
@B CRS 자원 수는 17 그대로다. `ora.racdb.db`는 자원 하나에 인스턴스가 CARDINALITY_ID로 붙는 구조라 칸만 1, 2에서 1로 바뀐다.
@B rac2의 진단 디렉터리(`diag/rdbms/racdb/racdb2`)는 장애 분석 기록이라 `dbca`가 지우지 않는다.

@H3 15.4.2  DB 홈 삭제와 세 박자

@IMG 15_inventory.png | 그림 15-3. 홈 하나를 지우는 세 박자 — 지울 노드에서 -local로 줄이고, deinstall하고, 남는 노드에서 줄인다

@CODE
[oracle@rac2 ~]$ $ORACLE_HOME/oui/bin/runInstaller -updateNodeList -silent \
>   ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_rac "CLUSTER_NODES={rac2}" -local
[oracle@rac2 ~]$ $ORACLE_HOME/deinstall/deinstall -local -checkonly
The cluster node(s) on which the Oracle home deinstallation will be performed are:rac2
[oracle@rac2 ~]$ $ORACLE_HOME/deinstall/deinstall -local -silent -paramfile <응답 파일>
[oracle@rac1 ~]$ $ORACLE_HOME/oui/bin/runInstaller -updateNodeList -silent \
>   ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_rac "CLUSTER_NODES={rac1}"
@END

@B 지울 노드에서 `-local`을 붙여 자기 목록만 rac2로 줄인다. 붙이지 않으면 rac1의 목록까지 rac2 하나로 바뀐다.
@B `-checkonly`는 아무것도 지우지 않고 응답 파일만 만든다. "will be performed are:rac2"에 rac1이 보이면 거기서 멈춘다.
@B 응답 파일의 `DB_UNIQUE_NAME_LIST`는 비어 있다. 인스턴스를 먼저 지웠기 때문이다. 순서를 거꾸로 하면 여기에 racdb가 잡혀 `deinstall`이 데이터베이스 구성까지 건드리려 한다.
@B 남는 노드의 목록 축소에는 `-local`을 붙이지 않는다. 단계마다 `srvctl status database`로 racdb1이 Open인지 본다.

@H3 15.4.3  Clusterware 해제(rac2)

@CODE
[root@rac2 ~]# /u01/app/19.3.0/grid/crs/install/rootcrs.sh -deconfig -force
CLSRSC-336: Successfully deconfigured Oracle Clusterware stack on this node
[grid@rac1 ~]$ olsnodes -s -t
rac1    Active    Unpinned
rac2    Inactive  Unpinned
@END

@B `-force`는 자원이 남아 있거나 다른 노드와 통신이 안 되어도 진행하라는 뜻이다.
@B `-lastnode`는 붙이지 않는다. 붙이면 OCR과 보팅 파일까지 지우는 클러스터 전체 해체가 된다.
@B rac2는 Inactive로 바뀌지만 OCR에는 아직 항목이 있다. CRS 자원은 16개가 되고, 빠진 것은 rac2-vip다.
@B 이 시점에 rac2에서 `crsctl check crs`를 치면 `CRS-4047: No Oracle Clusterware components configured.`가 나온다. 구성만 해제되고 소프트웨어는 남은 상태다.

@H3 15.4.4  OCR에서 노드 삭제(rac1)

@CODE
[root@rac1 ~]# /u01/app/19.3.0/grid/bin/crsctl delete node -n rac2
CRS-4661: Node rac2 successfully deleted.
@END

@B root로 실행한다. 이 시점부터 rac2는 클러스터가 아는 노드가 아니다.
@B ASM 자원과 디스크그룹 자원은 세 칸 그대로이고 rac2가 쓰던 칸만 OFFLINE이 된다. Flex ASM의 카디널리티가 3이라 노드가 줄어도 칸 수는 변하지 않는다.

@H3 15.4.5  그리드 홈 삭제

@B DB 홈과 같은 세 박자다. rac2에서 `CRS=TRUE -local`로 목록을 rac2로 줄이고, `deinstall -local`, 안내대로 `rootdeinstall.sh`, rac1에서 목록을 rac1로 줄인다.
@B Clusterware를 이미 해제했으므로 `deinstall`은 이 홈을 "Standalone Server" 홈으로 본다. 응답 파일에도 `HOME_TYPE=SIHA`가 적힌다. 그래서 지울 범위가 rac2 하나로 좁혀지고 ASM도 검출되지 않는다. 디스크그룹은 rac1이 계속 쓰고 있으므로 건드리지 않는 것이 맞다.
@B 마지막 단계가 "completed with errors"로 끝났다. `/u01/app/grid/crsdata/rac2/crf`(클러스터 상태 모니터 저장소) 아래 파일을 지우지 못해 `/u01/app/grid`에 261MB가 남았다. 이 잔재가 재추가 때 INS-40111 경고로 돌아온다.

@BP 지울 노드에서 -local, 남는 노드에서 -local 없이
DB 홈과 그리드 홈 모두 같은 세 박자다. 이 순서를 지키면 `deinstall`은 지울 노드 밖을 건드리지 않는다.
각 단계 뒤에 두 노드의 `inventory.xml`을 직접 열어 본다. 명령의 성공 메시지만으로는 어느 노드의 무엇이 바뀌었는지 알 수 없다.
@END

@H2 15.5  삭제 후 검증

@P 삭제가 끝나면 남은 노드의 클러스터가 온전한지, 지운 노드의 흔적이 클러스터 구성에 남지 않았는지를 확인한다. 실습 03이 이 단계다.

@CODE
[grid@rac1 ~]$ cluvfy stage -post nodedel -n rac2
  Verifying CRS Integrity ...PASSED
  Verifying Clusterware Version Consistency ...PASSED
Verifying Node Removal ...PASSED
Post-check for node removal was successful.
@END

@TBL
항목 | 삭제 전 | 삭제 후 | 이유
노드 | rac1, rac2 | rac1 | OCR에서 삭제
CRS 자원 | 17 | 16 | rac2-vip 제거
-init 자원 | 13 | 13 | rac1의 하위 스택
보팅 파일 | 3 ONLINE | 3 ONLINE | +CRS 그대로
OCR ID | 665666554 | 665666554 | 항목만 지웠다
인스턴스 / 리두 그룹 / UNDO | 2 / 4 / 2 | 1 / 2 / 1 | dbca 삭제
서비스 | 10 | 5 | 인스턴스 수만큼
@END

@B OCR ID가 그대로다. 노드 삭제는 OCR 안의 항목을 지운 것이지 OCR을 새로 만든 것이 아니다.
@B 데이터베이스는 여전히 RAC 데이터베이스다. `srvctl config database`의 Type은 RAC이고 인스턴스가 하나일 뿐이다.

@H3 15.5.1  rac2에 남은 것

@TBL
남은 것 | 상태 | 재추가에 주는 영향
/etc/oracle | lastgasp, maps. olr.loc·ocr.loc 없음 | 없음
그리드 홈 디렉터리 | 빈 디렉터리 | 없음(cluvfy PASSED)
/u01/app/grid | 261MB(CHM 데이터, 진단 로그) | INS-40111 경고
OS 계정·커널 파라미터·SSH·공유 디스크 이름 | 그대로 | 다시 준비할 필요 없음
cvuqdisk RPM | 삭제됨 | PRVG-11550 실패
@END

@B `deinstall`은 Oracle이 설치한 것만 지운다. 설치 가이드 v2의 3·4장에서 준비한 OS 수준 설정은 남으므로 다시 넣을 때 그 단계를 반복하지 않는다.
@B 예외가 cvuqdisk다. 설치 때 두 노드 모두에 넣었는데 삭제 뒤 rac2에서 사라졌다. 그리드 홈 `deinstall`이 함께 지운 것으로 보인다.
@B `/etc/oracle`에 olr.loc이나 ocr.loc이 남아 있으면 rac2가 이미 구성이 있는 노드로 보여 재추가가 꼬인다. 이 환경에서는 `rootcrs.sh -deconfig`가 깨끗이 지웠다.

@H2 15.6  노드 재추가

@P 재추가는 소프트웨어를 복사하고, 클러스터에 합류시키고, 인스턴스를 넣는 순서다. 실습 04는 실습 02와 같은 이유로 강사 시연과 트랜스크립트 판독으로 진행한다.

@IMG 15_add.png | 그림 15-4. 노드 재추가 — rac1에서 복사하고 rac2에서 root.sh로 합류한 뒤 인스턴스를 넣는다

@H3 15.6.1  사전 점검과 PRVG-11550

@B `addnode.sh`는 rac1에서 실행하고 rac1의 홈을 ssh로 rac2에 복사한다. 그리드 홈은 grid, DB 홈은 oracle 계정의 노드 간 SSH 등가성이 필요하다. 사설망 이름으로 처음 붙으면 호스트 키 질문이 나와 설치 관리자가 멈추므로 미리 한 번 붙어 둔다.

@CODE
[grid@rac1 ~]$ cluvfy stage -pre nodeadd -n rac2
Verifying Package: cvuqdisk-1.0.10-1 ...FAILED (PRVG-11550)
Verifying Device Checks for ASM ...FAILED (PRVG-11550)
Pre-check for node addition was unsuccessful.
rac2: PRVG-11550 : Package "cvuqdisk" is missing on node "rac2"
@END

@B cvuqdisk는 공유 디스크가 정말 공유되는지 확인할 때 쓰는 도구다. 없으면 "Device Checks for ASM"이 통째로 실패한다.
@B 원본 RPM은 rac1 그리드 홈의 `cv/rpm` 아래에 있다. rac2로 복사해 root로 `CVUQDISK_GRP=oinstall rpm -iv`로 설치하고 `/usr/sbin/cvuqdisk`의 setuid 비트와 그룹을 확인한다.
@B 다시 점검하면 이번에는 공유 디스크 8개의 접근까지 검사하고 통과한다. 앞의 실패 때는 이 항목이 아예 돌지 않았다.

@H3 15.6.2  그리드 홈 확장과 root.sh

@CODE
[grid@rac1 ~]$ /u01/app/19.3.0/grid/addnode/addnode.sh -silent \
>   "CLUSTER_NEW_NODES={rac2}" "CLUSTER_NEW_VIRTUAL_HOSTNAMES={rac2-vip}"
The Cluster Node Addition of /u01/app/19.3.0/grid was successful.
Execute /u01/app/19.3.0/grid/root.sh on the following nodes:
[rac2]
@END

@B `CLUSTER_NEW_NODES`는 새 노드의 공용 호스트명, `CLUSTER_NEW_VIRTUAL_HOSTNAMES`는 그 노드의 VIP 이름이다. 15.3.1에서 기록한 값이고 `/etc/hosts`에 그대로 남아 있다.
@B 시간의 대부분은 그리드 홈 6.4GB를 rac2로 보내는 데 쓴다. `addnode.sh`가 끝난 시점에 rac2는 아직 클러스터 멤버가 아니다.
@B rac2에서 root로 그리드 홈의 `root.sh`를 실행한다. OLR을 만들고, ohasd를 등록해 하위 스택을 올리고, CSS로 클러스터에 합류하고, OCR에 rac2와 rac2-vip를 등록하고, ASM을 띄워 디스크그룹을 마운트한다.
@B 끝나면 `olsnodes -n -s -t`에서 rac2가 다시 노드 번호 2, Active로 보인다. 지웠던 번호 자리가 비어 있어 그대로 받았다.

@H3 15.6.3  DB 홈 확장과 인스턴스 추가

@CODE
[oracle@rac1 ~]$ $ORACLE_HOME/addnode/addnode.sh -silent "CLUSTER_NEW_NODES={rac2}"
[root@rac2 ~]# /u01/app/oracle/product/19.3.0/dbhome_rac/root.sh
[oracle@rac1 ~]$ dbca -silent -addInstance -gdbName racdb -nodeName rac2 \
>   -instanceName racdb2 -sysDBAUserName sys -sysDBAPassword <SYS 비밀번호>
Instance "racdb2" added successfully on node "rac2".
@END

@B DB 홈 `addnode.sh`에는 `CLUSTER_NEW_VIRTUAL_HOSTNAMES`가 없다. VIP는 그리드의 자원이고 이미 있다.
@B DB 홈의 `root.sh`는 클러스터 구성을 건드리지 않는다.
@B `dbca -addInstance`도 rac1에서 실행한다. 삭제 때 지워진 thread 2(PUBLIC으로 활성화), 리두 그룹 3·4(thread 1과 같은 200MB), UNDOTBS2를 되살리고 racdb2를 띄운다.
@B 손으로 인스턴스를 추가하면 이것을 직접 해야 한다. `alter database add logfile thread 2`, `alter database enable public thread 2`, UNDO 테이블스페이스 생성, `sid='racdb2'` 파라미터 지정, `srvctl add instance`다.

@NOTE dbca보다 addnode.sh가 먼저다
`dbca -addInstance`는 rac2에 DB 홈이 있어야 인스턴스를 띄울 수 있다. 순서를 바꾸는 실수가 흔하므로 `dbca` 전에 rac2의 `dbhome_rac/bin/oracle`이 있는지, 인벤토리의 dbhome_rac 노드 목록에 rac2가 있는지 본다.
@END

@H2 15.7  오류 재현 — 정리가 덜 된 상태에서 재추가

@P 첫 번째 그리드 홈 `addnode.sh`는 복사 20%에서 끊겼다. 실행하던 rac1이 복사 도중에 재부팅된 것이다. 실습 05(자습)가 이 상황을 다룬다.

@IMG 15_leftover.png | 그림 15-5. 잔재가 남은 노드에 다시 넣을 수 있는지 판단하는 기준

@H3 15.7.1  반쪽짜리 그리드 홈

@B rac2의 그리드 홈은 정상 6.4GB 중 3.1GB만 와 있었다. `root.sh`는 있는데 `bin/crsctl`이 없었다.
@B 위험한 조합이다. `root.sh`가 보이니 실행할 수 있을 것 같지만 필요한 바이너리를 찾지 못하고 중간에 멈춘다. 반쯤 구성된 노드는 처음 상태보다 정리하기 어렵다.
@B `/etc/oracle`에 olr.loc 등이 생겼지만 `/etc/init.d/ohasd`는 없었고 rac1에서 보면 rac2는 클러스터에 없었다. 구성 단계(`root.sh`)까지는 가지 않았다.

@H3 15.7.2  잔재 위에 다시 실행

@B 두 번째 `addnode.sh`는 성공했다. 경고는 두 개였다.
@B INS-40111은 rac2의 ORACLE_BASE(`/u01/app/grid`)가 비어 있지 않다는 경고다. 15.4.5에서 남은 261MB 때문이다.
@B INS-43055는 그리드 홈 자리가 인벤토리에 등록되지 않았는데 비어 있지도 않으며, 비우지 않으면 덮어쓴다는 경고다. 로그에 "Advice is CONTINUE"가 찍히고 덮어썼다.
@B 이번에 통한 이유는 rac2가 파일만 있고 구성은 없는 상태였기 때문이다.

@TBL
잔재 | 재추가 영향 | 조치
빈 그리드 홈 디렉터리 | 없음 | 그대로 둔다
ORACLE_BASE의 crsdata·diag | INS-40111 경고 | 비우는 것이 원칙
반쯤 복사된 홈(구성 전) | INS-43055 경고 후 덮어씀 | `addnode.sh` 재실행
cvuqdisk 없음 | PRVG-11550 실패 | RPM 재설치
ohasd 등록·OLR 생성까지 된 노드 | `root.sh` 실패 위험 | `rootcrs.sh -deconfig -force` 후 재시도
OCR에 노드 항목이 남음 | 이미 멤버로 취급 | `crsctl delete node` 후 재시도
@END

@CASE 복사 도중 노드가 내려갔을 때
`addnode.sh`가 `root.sh` 실행을 안내하기 전에는 `root.sh`를 치지 않는다. 안내가 없었다는 것 자체가 복사가 끝나지 않았다는 증거다. rac2에서 `bin/crsctl`이 있는지, 그리드 홈 크기가 rac1과 같은지, `addNodeActions` 로그가 100%까지 갔는지 본다.
이미 `root.sh`를 쳐서 중간에 멈췄다면 rac2에서 `rootcrs.sh -deconfig -force`로 반쯤 된 구성을 걷어 낸다. rac1의 `olsnodes`에 rac2가 보이면 `crsctl delete node -n rac2`까지 한 뒤 `addnode.sh`부터 다시 한다.
@END

@H2 15.8  원복 검증

@P 재추가가 끝나면 작업 전 기준선과 하나씩 대조한다. 같은 값과 달라야 정상인 값을 구분한다.

@CODE
[grid@rac1 ~]$ cluvfy stage -post nodeadd -n rac2
Verifying Node Addition ...PASSED
Verifying Node Application Existence ...PASSED
Verifying Single Client Access Name (SCAN) ...WARNING (PRVG-11368)
Post-check for node addition was successful.
@END

@TBL
항목 | 작업 전 | 삭제 후 | 재추가 후
노드 | rac1, rac2 | rac1 | rac1, rac2(번호 1, 2)
CRS 자원 / -init | 17 / 13 | 16 / 13 | 17 / 13
OCR ID | 665666554 | 665666554 | 665666554
OLR ID rac2 | 877385927 | - | 930016669
서비스 | 10 | 5 | 10
인스턴스 / 리두 그룹 / UNDO | 2 / 4 / 2 | 1 / 2 / 1 | 2 / 4 / 2
@END

@B 경고는 작업 전과 같은 PRVG-11368 하나다. "Node Application Existence"는 rac2의 VIP, 리스너, ONS가 다시 만들어졌는지 보는 항목이다.
@B 다른 값은 rac2의 OLR ID 하나다. OCR은 공유 디스크에 있어 한 번도 다시 만들지 않았고, OLR은 rac2의 로컬 디스크에 `root.sh`가 새로 만들었다. 바뀐 것이 정상이며, 바뀌지 않았다면 옛 OLR이 남아 있었다는 신호다.

@H3 15.8.1  인벤토리는 늘어나지 않았다

@B 클러스터는 2노드인데 두 노드의 `inventory.xml`이 모두 그리드 홈과 dbhome_rac 아래에 rac1 한 줄만 가지고 있었다.
@B `addnode.sh`는 "Saving cluster inventory successful"과 "Update Inventory successful"을 찍었지만, 로그에는 홈 플래그가 clean이라 저장을 건너뛰었다는 줄이 남아 있었다. 왜 clean으로 판단했는지는 로그로 더 좁히지 못했다.
@B 15.3.3과 같은 `-updateNodeList` 명령에 `"CLUSTER_NODES={rac1,rac2}"`를 주어 두 홈 모두 고쳤다.
@B 지금 당장은 증상이 없다. 패치 도구는 인벤토리 노드 목록으로 대상 노드를 정하므로 rac1만 패치되어 두 노드의 버전이 갈릴 수 있다. 다음 노드 삭제 때 `deinstall`이 rac2를 클러스터 노드로 보지 못하는 일도 생긴다.

@H3 15.8.2  PDB 저장 상태와 재기동

@B `dba_pdb_saved_states`에 racdb2 행이 있는지 본다. 없으면 racdb2가 다시 뜰 때 RACPDB1이 MOUNTED로 남는다. 빠져 있으면 racdb2에서 `alter pluggable database racpdb1 save state`를 한다.
@B 두 노드를 함께 정지했다 켠 뒤 데이터베이스가 자동으로 올라오지 않았다. `crsctl stat res ora.racdb.db -t`의 Target이 OFFLINE이었다. 지난 종료 때 `srvctl stop database`로 내렸다는 기록이며, Management policy가 AUTOMATIC이어도 관리자가 내린 자원은 CRS가 다시 올리지 않는다.
@B `srvctl start database -d racdb` 한 번으로 rac2까지 기동되면 CRS의 DB 자원에 rac2가 제대로 등록된 것이다.

@H2 15.9  다른 방법과 되돌리기

@B 노드를 여러 대 한꺼번에 늘리거나 원본 노드와 연결하기 어려우면 홈을 미리 묶어 두고 새 노드에서 풀어 쓰는 골드 이미지 방식을 쓴다. 19c는 그리드 홈과 DB 홈 각각의 설치 도구에 `-createGoldImage` 옵션이 있고, 예전 `clone.pl` 방식은 사용 중단(deprecated) 대상이다. 이 과정에서는 다루지 않는다.
@B 어느 방식이든 소프트웨어를 옮긴 뒤의 과정은 같다. `root.sh`로 합류하고, `dbca`로 인스턴스를 넣고, 인벤토리를 확인한다.

@TBL
멈춘 지점 | 되돌리는 방법
`addnode.sh` 복사 중 | rac2의 잔재를 둔 채 `addnode.sh` 재실행(15.7)
`root.sh` 도중 | rac2에서 `rootcrs.sh -deconfig -force`, rac1의 `olsnodes`에 남았으면 `crsctl delete node`
`dbca -addInstance` 도중 | `dbca -deleteInstance`로 지우고 다시
OCR 자체가 손상됨 | `ocrconfig -restore`로 15.3.2의 수동 백업 복원(3장)
@END

@B 노드 하나를 빼고 넣는 작업에서 OCR 복원까지 갈 일은 드물다. 그래도 수동 백업을 뜨는 이유는 `crsctl delete node`를 잘못된 노드에 쳤을 때 돌아갈 곳이 그것뿐이기 때문이다.

@TBL
시점 | 확인 항목 | 명령
작업 전 | 인벤토리 노드 목록이 클러스터와 같은가 | `inventory.xml`과 `olsnodes` 비교
작업 전 | OCR 수동 백업 | `ocrconfig -manualbackup`
삭제 후 | 클러스터 구성에서 빠졌는가 | `cluvfy stage -post nodedel`
삭제 후 | 지운 노드의 잔재 | `/etc/oracle`, `/u01/app/grid`, `rpm -q cvuqdisk`
추가 전 | 사전 점검 | `cluvfy stage -pre nodeadd`
추가 후 | 자원·OCR·OLR 기준선 대조 | `crsctl stat res`, `ocrcheck`, `ocrcheck -local`
추가 후 | 인벤토리와 PDB 저장 상태 | `inventory.xml`, `dba_pdb_saved_states`
@END

@H2 15.10  요약

@B 노드 하나는 OCR, 노드마다의 인벤토리, 데이터베이스 구성 세 곳에 기록된다. 삭제와 추가는 세 곳을 모두 맞추는 작업이다.
@B 삭제 순서는 `dbca -deleteInstance`, DB 홈 `deinstall`, `rootcrs.sh -deconfig -force`, `crsctl delete node`, 그리드 홈 `deinstall`이다.
@B `deinstall` 앞뒤로 인벤토리 목록을 줄인다. 지울 노드에서 `-local`로, 남는 노드에서 `-local` 없이 한다.
@B `cluvfy`에는 `-pre nodedel`이 없다. 삭제는 `-post nodedel`, 추가는 `-pre nodeadd`와 `-post nodeadd`로 확인한다.
@B 그리드 홈 `deinstall`이 cvuqdisk까지 지워 재추가 사전 점검이 PRVG-11550으로 실패했다.
@B 재추가는 그리드 `addnode.sh` → rac2 `root.sh` → DB `addnode.sh` → `root.sh` → `dbca -addInstance` 순이다.
@B 재추가 뒤 달라지는 값은 rac2의 OLR ID 하나다. 인벤토리 노드 목록은 성공 메시지와 별개로 직접 확인한다.

@H2 15.11  퀴즈

@QUIZ 퀴즈
1. 노드 하나가 기록되는 세 곳을 쓰고 각각을 다루는 명령을 하나씩 드시오.
2. 노드 삭제의 다섯 단계를 순서대로 쓰시오.
3. `deinstall` 전에 지울 노드에서 `-updateNodeList`에 `-local`을 붙이는 이유는?
4. `rootcrs.sh -deconfig`에 `-lastnode`를 붙이면 안 되는 이유는?
5. 재추가 사전 점검에서 PRVG-11550이 난 원인과 조치는?
6. 재추가 뒤 rac2의 OLR ID만 바뀐 이유는?
@END

@NOTE 정답과 해설
1. OCR(crsctl delete node, root.sh), 중앙 인벤토리(-updateNodeList, deinstall), 데이터베이스 구성(dbca -deleteInstance/-addInstance).
2. dbca -deleteInstance → DB 홈 deinstall → rootcrs.sh -deconfig -force(rac2) → crsctl delete node(rac1) → 그리드 홈 deinstall.
3. -local 없이 실행하면 rac1의 인벤토리까지 고쳐져 rac1 목록이 rac2 하나로 바뀐다. deinstall은 그 목록으로 지울 노드를 정한다.
4. -lastnode는 마지막 노드용으로 OCR과 보팅 파일까지 지워 클러스터 전체를 해체한다.
5. 그리드 홈 deinstall이 rac2의 cvuqdisk RPM을 지웠다. rac1 그리드 홈의 cv/rpm에서 RPM을 복사해 CVUQDISK_GRP=oinstall로 설치한다.
6. OCR은 공유 디스크에 있어 다시 만들지 않았고, OLR은 rac2 로컬에 root.sh가 새로 만들었다.
@END

@H2 15.12  실습 개요

@P 수업에서는 점검과 검증 실습(01, 03)을 직접 한다. 노드 삭제(02)와 재추가(04)는 각각 1시간이 넘고 되돌리기 어려워 강사 시연·트랜스크립트 판독으로 진행한다. 수강생은 트랜스크립트에서 단계마다의 출력이 정상인지 판정한다.

@TBL
실습 | 파일 | 목적
01 ★ | RAC/18장/18장_실습_01_추가전점검.txt | 노드·자원·OCR·OLR 기준선을 남기고 OCR 수동 백업과 인벤토리 노드 목록을 확인한다
02 시연 | RAC/18장/18장_실습_02_노드삭제.txt | 삭제 다섯 단계의 출력을 판독한다(강사 시연)
03 | RAC/18장/18장_실습_03_삭제후검증.txt | cluvfy -post nodedel과 기준선 비교로 삭제 결과와 rac2 잔재를 확인한다
04 시연 | RAC/18장/18장_실습_04_노드재추가.txt | PRVG-11550 조치, addnode.sh, root.sh 출력을 판독한다(강사 시연)
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다. 시연 전에 강사는 두 노드를 함께 정지해 스냅샷과 `-BackupShared` 사본을 뜨고, 실습 01의 OCR 수동 백업을 함께 둔다.
@B 수료 후 자습: 18장_실습_05_오류재현_정리안된재추가, 18장_실습_06_DB인스턴스추가, 18장_실습_07_원복검증.
