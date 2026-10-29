@TITLE Oracle Database 19c RAC 과정|Clusterware 구조와 프로세스|두 개의 스택, 기동 순서, 자원, 설치가 남긴 구성|제2장

@PLAIN 학습 목표
- OHAS 스택과 CRS 스택, OLR과 OCR을 구분한다
- 핵심 데몬과 감시자, 에이전트의 역할과 계정을 안다
- alert.log로 기동 순서를 따라간다
- 오류 번호로 장애 계층을 판별한다
- 자원 유형과 의존 관계를 읽는다
- 네트워크 구성과 두 ORACLE_HOME을 확인한다

@PLAIN Agenda
- 2.2  두 개의 스택  /  2.3  프로세스와 실행 계정
- 2.4  기동 순서  /  2.5  자원과 의존 관계
- 2.6  장애 계층 판별
- 2.7  설치가 남긴 네트워크 구성
- 2.8  Grid 홈과 두 ORACLE_HOME

@SEC 2.2|두 개의 스택
- OHAS 스택과 CRS 스택
- 계층을 명령으로 가른다
- stop cluster와 stop crs

@IMG 02_twostack.png|두 개의 스택|OHAS 스택은 로컬 OLR로, CRS 스택은 +CRS 안의 OCR로 움직인다
@NOTE Clusterware는 한 덩어리가 아니라 두 층으로 되어 있습니다. 아래층인 OHAS 스택은 ohasd가 진입점이고 노드마다 있는 로컬 파일 OLR을 읽습니다. 위층인 CRS 스택은 crsd가 관리자이고 +CRS 디스크그룹 안의 OCR을 읽습니다. 그림 아래쪽의 빨간 상자를 보시면 ora.crsd가 OHAS 스택의 자원 목록에 들어 있습니다. 위층 전체가 아래층에게는 자원 하나라는 뜻입니다. 이 위계가 기동 순서와 장애 진단의 출발점이 됩니다.

@SLIDE OHAS 스택|systemd에서 시작하는 아래층
- systemd → oracle-ohasd → init.ohasd → ohasd
- Restart=always, 정지 대기 최대 60분
- 자원 조회: crsctl status resource -t -init
- ora.cssd, ora.asm, ora.ctssd, ora.crsd 등
- ora.diskmon OFFLINE은 정상 (Exadata 전용)
@NOTE 노드가 부팅하면 systemd가 oracle-ohasd 유닛을 실행하고 여기서 ohasd가 뜹니다. 유닛 파일에는 네트워크가 올라온 뒤 기동하고, 죽으면 제한 없이 재기동하고, 정지에 최대 한 시간을 준다는 설정이 들어 있습니다. OHAS 스택의 자원은 반드시 마이너스 init 옵션을 붙여 조회합니다. 이 옵션이 없으면 위층 자원만 보입니다. 목록에서 diskmon이 OFFLINE인 것을 보고 놀라는 경우가 있는데, Exadata 스토리지 셀을 감시하는 자원이라 일반 환경에서는 OFFLINE이 정상입니다.

@SLIDE CRS 스택과 두 레지스트리|OLR은 로컬, OCR은 +CRS 안
- crsd가 리스너·VIP·SCAN·디스크그룹·DB·서비스 관리
- OLR: /u01/app/grid/crsdata/rac1/olr/rac1_19.olr
- OCR: +CRS, 두 노드에서 같은 ID
- ASM이 +CRS를 마운트해야 crsd가 뜬다
- ocrcheck -local은 OLR, ocrcheck는 OCR
@NOTE crsd가 뜨면 위층 스택이 시작되고, 우리가 운영에서 다루는 자원은 대부분 여기에 있습니다. 두 스택은 저장소가 다릅니다. OLR은 로컬 파일 시스템에 있어서 부팅 직후 바로 읽을 수 있고, OCR은 ASM 디스크그룹 안에 있어서 ASM이 뜬 다음에야 읽힙니다. OLR은 노드마다 ID가 다르고 OCR은 두 노드에서 ID가 같습니다. ASM이 내려간 노드에서 ocrcheck를 실행하면 실패하지만 마이너스 local을 붙이면 정상으로 나옵니다. 레지스트리 손상을 의심하기 전에 ASM부터 확인해야 합니다.

@SLIDE 계층을 명령으로 가른다|명령마다 묻는 대상이 정해져 있다
- check has, status -t -init → ohasd
- check crs → ohasd·crsd·cssd·evmd
- status -t, srvctl, olsnodes → crsd·cssd
- stop cluster 직후: 4638 online + 4535·4530·4534
@NOTE 조회 명령이 어느 데몬에게 묻는지 알면 어느 계층이 죽었는지 바로 판단할 수 있습니다. check has와 마이너스 init 조회는 ohasd에게 묻습니다. check crs는 ohasd부터 evmd까지 네 군데를 모두 확인합니다. 마이너스 init 없는 조회와 srvctl, olsnodes는 위층에 묻습니다. rac2에서 stop cluster를 한 직후 check crs를 실행하면 첫 줄 CRS-4638은 online이고 나머지 세 줄이 실패로 나옵니다. ohasd는 살아 있고 그 위만 내려갔다는 뜻입니다.

@SLIDE stop cluster와 stop crs|ohasd를 남기느냐 내리느냐
- stop cluster: CRS 계층만, ohasd는 남음
- stop crs: OHAS까지 노드 스택 전체
- 마지막 메시지: CRS-2792 / CRS-2793 / CRS-4133
- 재기동: start cluster / start crs
- -all을 붙이면 모든 노드에 적용
@NOTE 두 명령을 같은 것으로 아는 경우가 많습니다. stop cluster는 CRS 계층과 그 아래 저수준 자원을 내리지만 ohasd는 남깁니다. stop crs는 ohasd까지 노드의 스택 전체를 내립니다. 출력의 마지막 메시지로 구별할 수 있습니다. CRS-2792는 위층 자원 정지 완료, CRS-2793은 아래층 자원 정지 완료, CRS-4133은 ohasd 자체가 멈췄다는 뜻입니다. stop cluster는 CRS-2792에서 끝납니다. 노드를 잠시 클러스터에서 뺄 때는 stop cluster, OS 패치처럼 완전히 내릴 때는 stop crs를 씁니다.

@SEC 2.3|프로세스와 실행 계정
- 핵심 데몬
- 감시자 cssdagent·cssdmonitor
- 에이전트와 권한

@SLIDE 핵심 데몬|재부팅 권한이 필요하면 root
- root: ohasd, crsd, octssd, osysmond
- grid: ocssd, evmd, gpnpd, gipcd, mdnsd
- ocssd가 죽으면 노드 재부팅
- evmd는 FAN 이벤트의 출발점
- CTSS Active mode: NTP 없이 직접 시간 동기
@NOTE ps로 프로세스를 보면 root와 grid 두 계정으로 나뉘어 있습니다. 노드를 재부팅시키거나 주소를 올리는 권한이 필요한 프로세스는 root로 돕니다. ocssd는 멤버십을 판정하는 가장 중요한 데몬이고, 이것이 응답하지 않으면 노드가 재부팅됩니다. evmd는 이벤트를 발행하며 13장에서 다룰 FAN 이벤트의 출발점입니다. 실습 환경은 NTP를 구성하지 않았으므로 octssd가 Active mode로 직접 두 노드의 시간을 맞춥니다. crsctl check ctss로 확인할 수 있습니다.

@SLIDE 감시자|cssdagent와 cssdmonitor는 죽이지 않는다
- cssdagent: ocssd 기동과 감시
- cssdmonitor: cssdagent와 시스템 행 감시
- 판단이 불가능해지면 노드를 내린다 (축출)
- 감시 프로세스 kill → 몇 초 뒤 재부팅
@NOTE cssdagent는 ocssd를 띄우고 감시하며, cssdmonitor는 그 cssdagent와 시스템 행을 다시 감시합니다. 둘 다 root로 도는 이유는 노드를 강제로 내려야 할 수 있기 때문입니다. ocssd가 멈춘 노드는 자기가 클러스터에서 빠졌다는 사실도 알 수 없고, 그 상태로 공유 디스크에 쓰면 데이터가 깨집니다. 그래서 판단이 불가능해지면 노드를 죽이는 쪽을 택합니다. CPU를 쓴다는 이유로 cssdmonitor를 kill했다가 노드가 재부팅된 사례가 있습니다. Grid 홈의 프로세스는 정리 대상에서 제외합니다.

@SLIDE 에이전트와 권한|실제로 일하는 것은 에이전트
- orarootagent: VIP, 네트워크, HAIP 등 root 자원
- oraagent: 리스너, ASM, DB, 서비스
- 계층별·소유자별로 하나씩 (oraagent 셋)
- config 계열은 root 필요 (CRS-4563)
- root는 전체 경로로 crsctl 실행
@NOTE ohasd와 crsd는 지시만 하고 자원을 실제로 올리고 내리고 점검하는 것은 에이전트입니다. orarootagent는 root 권한이 필요한 자원을, oraagent는 일반 계정 자원을 맡습니다. 에이전트는 자원 소유자마다 따로 떠서 실습 환경에는 oraagent가 셋 보입니다. 하나는 데이터베이스 자원을 위한 oracle 계정 것입니다. 권한도 함께 정리합니다. crsctl의 check, get, status는 grid로 되지만 config 계열은 조회도 root가 필요해 CRS-4563이 납니다. root의 PATH에는 Grid 홈이 없으므로 전체 경로를 씁니다.

@SEC 2.4|기동 순서
- alert.log로 따라가기
- CRS-1601과 CRS-5019
- 정지는 역순

@IMG 02_startup.png|기동 순서|OLR로 일어선 스택이 멤버십을 확정하고 ASM이 +CRS를 마운트한 뒤 crsd가 뜬다
@NOTE Clusterware alert.log는 grid의 ORACLE_BASE 아래 diag, crs, 노드 이름, trace 폴더에 있습니다. 부팅 기록을 따라가면 이 그림의 순서가 그대로 나옵니다. ohasd가 OLR을 열고, 감시자와 에이전트가 뜨고, 이름 해석과 통신 기반 데몬이 올라온 뒤 ocssd가 멤버십을 확정합니다. 시간 동기 다음에는 OCR을 아직 못 읽는다는 CRS-5019가 남고, ASM이 +CRS를 마운트하면 crsd가 뜹니다. 그다음에 crsd가 네트워크, 리스너, 디스크그룹, 데이터베이스 순으로 운영 자원을 올립니다.

@SLIDE 기동 로그의 두 메시지|CRS-1601은 찾고, CRS-5019는 놀라지 않는다
- CRS-1601: 멤버십 확정, Active nodes 목록
- 축출 조사 때 가장 먼저 찾는 줄 (17장)
- CRS-5019: +CRS 마운트 전 과도기 메시지
- 재부팅 직후 ORA-01034는 기다리면 해소
@NOTE 기동 로그에서 특히 볼 메시지가 둘 있습니다. CRS-1601은 CSSD 재구성이 끝났다는 뜻이고 뒤에 Active nodes 목록이 붙습니다. 노드가 들어오거나 빠질 때마다 남으므로 축출 사고를 조사할 때 두 노드의 alert.log에서 가장 먼저 찾는 줄입니다. CRS-5019는 OCR이 있는 디스크그룹이 아직 마운트되지 않았다는 메시지인데 부팅 중에는 정상입니다. 이것을 보고 OCR 복구를 시작하면 없던 문제를 만듭니다. 재부팅 직후 데이터베이스 접속이 ORA-01034로 실패해도 몇 분 기다린 뒤 다시 확인합니다.

@SLIDE 정지는 기동의 역순|순서는 의존 관계에서 나온다
- 위층 자원(ons, network) → crsd
- storage → asm → haip
- cssd를 가장 마지막에
- 사람이 순서를 정하지 않는다
@NOTE rac2에서 stop cluster를 실행한 출력을 보면 ons와 network 같은 위층 자원부터 내리고 crsd를 내린 뒤 아래층으로 내려갑니다. storage를 내리고 asm을 내리고, 인터커넥트 HAIP를 거쳐 cssd를 가장 마지막에 내립니다. 기동할 때 cssd가 먼저였던 것과 정확히 반대입니다. 이 순서는 사람이 스크립트로 정한 것이 아니라 자원마다 정의된 의존 관계에서 Clusterware가 스스로 도출한 것입니다. 다음 절에서 그 의존 관계를 자원 속성으로 직접 읽어 봅니다.

@SEC 2.5|자원과 의존 관계
- 자원 이름과 유형
- 속성으로 읽는 의존 관계
- 재배치와 페일백

@SLIDE 자원 이름과 유형|ora.racdb는 서버 풀, DB 자원은 ora.racdb.db
- ora.racdb.db, ora.rac1.vip, ora.DATA.dg
- ora.LISTENER.lsnr, ora.LISTENER_SCAN1.lsnr
- local 자원: 노드마다 하나 (리스너, ONS)
- cluster 자원: 개수가 정해짐 (SCAN, VIP, DB)
- 이름을 틀리면 CRS-2613
@NOTE Clusterware에게 관리 대상은 모두 자원이고, 자원마다 유형이 있어 기동과 점검 방법을 정합니다. 이름에도 규칙이 있습니다. 데이터베이스는 ora 점 DB 이름 점 db, VIP는 ora 점 노드 이름 점 vip, 디스크그룹은 ora 점 이름 점 dg입니다. local 자원은 모든 노드에 하나씩 뜨고 cluster 자원은 클러스터 전체에서 개수가 정해집니다. status resource 화면의 두 덩어리가 이 구분입니다. ora.racdb로 조회하면 CRS-2613이 나는데 그것은 서버 풀 이름이기 때문입니다. 통신 오류와 혼동하지 않습니다.

@SLIDE 속성으로 읽는 의존 관계|crsctl status resource ora.racdb.db -p
- CARDINALITY=2, PLACEMENT=restricted
- AUTO_START=restore: 재부팅 전 상태로
- hard: DATA·FRA 디스크그룹이 먼저
- weak: 리스너는 없어도 기동
- ACL: oracle 소유, grid는 r-x
@NOTE 마이너스 p 옵션을 붙이면 자원 속성이 모두 나옵니다. racdb 자원은 CARDINALITY가 2이고 PLACEMENT가 restricted입니다. 정해진 두 노드에 인스턴스를 하나씩 두는 관리자 관리형의 모습입니다. AUTO_START가 restore이므로 재부팅 전 상태로 되돌립니다. START_DEPENDENCIES의 hard는 DATA와 FRA 디스크그룹이 먼저 올라와 있어야 한다는 뜻이고, weak는 리스너가 없어도 기동은 한다는 뜻입니다. ACL을 보면 grid에게는 읽기와 실행만 있어 권한 분리가 자원 수준에서 강제됩니다.

@SLIDE 재배치와 페일백|옮겨 간 자원은 돌아오지 않는다
- 하나만 필요한 자원: scan1.vip, cvu, qosmserver
- 노드 스택이 내려가면 살아 있는 노드로 이동
- 노드가 돌아와도 페일백 없음
- 필요하면 srvctl relocate
- 서버 풀: Free, Generic, ora.racdb
@NOTE 클러스터에 하나만 있으면 되는 자원은 그 노드의 스택이 내려가면 살아 있는 노드로 옮겨 갑니다. 실습에서 rac2를 정지하자 SCAN VIP, CVU, QoS 서버가 rac1로 옮겨 왔습니다. 그리고 rac2를 되살려도 세 자원은 rac1에 그대로 남았습니다. Clusterware에는 자동 페일백이 없습니다. 장애와 점검이 반복되면 자원이 한쪽으로 쏠리므로 주기적으로 배치를 보고 필요하면 srvctl relocate로 옮깁니다. 서버 풀은 crsctl status serverpool로 보며 두 노드가 Generic과 ora.racdb 풀에 들어 있습니다.

@SEC 2.6|장애 계층 판별
- 오류 번호가 가리키는 계층
- 다른 노드에서 확인
- CSS 파라미터와 자동 기동

@IMG 02_diagnose.png|장애 계층 판별|아래층부터 묻고 다른 노드에서 범위를 정한다
@NOTE 명령이 실패하면 오류 번호가 어느 계층에 닿지 못했는지 알려 줍니다. 먼저 check has를 봅니다. CRS-4639가 나오면 ohasd까지 내려간 것이므로 start crs로 올려야 합니다. online이면 check crs를 봅니다. CRS-4535, 4530, 4534가 나오면 crsd 이하만 내려간 것이고 이때 마이너스 init 조회는 됩니다. 마지막으로 다른 노드에서 olsnodes를 실행해 범위를 정합니다. 아래쪽 점선 상자처럼 CRS-2613이나 CRS-4563은 이름과 권한 문제라 클러스터 상태와 상관없습니다.

@SLIDE 오류 번호 정리|한 노드에서 실패하면 다른 노드에서 본다
- CRS-4639: ohasd에 닿지 못함
- CRS-4535 crsd / 4530 ocssd / 4534 evmd
- PRKH-1010·3003: srvctl이 CRS·CSS와 통신 실패
- PRCO-19·2: olsnodes 통신 실패
- 다른 노드의 olsnodes -s: rac2 Inactive
@NOTE 오류 번호를 정리합니다. CRS-4639는 ohasd에 닿지 못한 것이고 스택 전체가 내려간 상태입니다. CRS-4535는 crsd, 4530은 ocssd, 4534는 evmd에 닿지 못한 것입니다. srvctl은 PRKH-1010과 3003, olsnodes는 PRCO-19와 2로 실패합니다. 스택이 내려간 노드에서 같은 명령을 반복해도 결과는 같습니다. 살아 있는 노드에서 olsnodes 마이너스 s를 한 번 실행하면 rac2만 Inactive인지, 클러스터 전체 문제인지가 바로 드러납니다. RAC 진단은 항상 두 노드를 오가며 합니다.

@SLIDE CSS 파라미터와 자동 기동|언제 노드를 죽이고, 부팅 때 올릴 것인가
- misscount 30초: 네트워크 하트비트
- disktimeout 200초: 보팅 파일 I/O
- 기본값 유지 권장
- crsctl config crs: CRS-4622 enabled
- disable crs 후 enable 되돌리기 필수
@NOTE ocssd가 축출을 판단하는 기준값입니다. 인터커넥트 하트비트가 30초 끊기면 네트워크 장애로, 보팅 파일 입출력이 200초 응답하지 않으면 디스크 장애로 봅니다. misscount를 늘리면 일시적 지연에 노드가 덜 죽지만 진짜 장애를 늦게 감지하므로 기본값을 유지합니다. 자동 기동 설정은 root로 crsctl config crs를 실행해 봅니다. OS 패치처럼 재부팅이 반복될 때는 disable해 두고 마지막에 반드시 enable로 되돌립니다. 잊으면 다음 재부팅 때 그 노드가 아무 오류 없이 빠집니다.

@SEC 2.7|설치가 남긴 네트워크 구성
- 인터페이스와 주소
- oifcfg getif
- /etc/hosts와 dnsmasq, srvctl config

@IMG 02_network.png|설치가 남긴 주소|공용·사설은 OS가, VIP·SCAN·HAIP는 Clusterware가 올린다
@NOTE 네트워크는 설치 가이드 v2의 3장과 5장에서 구성했고, 이 과정에서는 그 결과를 읽는 방법을 익힙니다. ip addr로 보면 rac1의 ens33에는 공용 IP, rac1-vip, SCAN 세 주소가 함께 있고 ens160에는 사설 IP와 HAIP가 있습니다. 공용과 사설은 OS가 올렸고 VIP, SCAN, HAIP는 Clusterware가 올린 것입니다. SCAN VIP는 클러스터에 하나라 한 노드에만 보입니다. 오른쪽 아래처럼 이름 해석은 각 노드의 dnsmasq가 /etc/hosts를 DNS로 서비스하는 구조입니다.

@SLIDE oifcfg getif와 iflist|용도의 근거는 getif
- getif: ens33 public, ens160 cluster_interconnect,asm
- iflist -p의 PRIVATE은 RFC 1918 대역이라는 뜻
- 169.254.0.0 UNKNOWN은 HAIP 대역
- 용도 변경은 oifcfg setif (계획 작업)
- 경로 분리: ip route, ping -I ens160
@NOTE oifcfg에는 헷갈리기 쉬운 하위 명령이 둘 있습니다. getif는 Clusterware에 등록된 용도로, ens33은 public이고 ens160은 인터커넥트와 ASM 용도입니다. iflist 마이너스 p는 주소 대역의 성격을 보여 주는데, 172.16 대역은 RFC 1918 사설 대역이라 공용망도 PRIVATE으로 나옵니다. 이것을 보고 공용망 설정이 잘못됐다고 보고하는 실수가 실제로 있습니다. 판단 근거는 항상 getif입니다. 두 대역이 다른 인터페이스로 나가는지는 ip route와 인터페이스를 지정한 ping으로 확인합니다.

@SLIDE 이름 해석|/etc/hosts를 dnsmasq가 서비스한다
- 이름 7개: 공용 2, VIP 2, 사설 2, SCAN 1
- FQDN과 짧은 이름 함께, 두 노드 diff로 대조
- resolv.conf → 127.0.0.1, expand-hosts, no-resolv
- hosts 수정 후 dnsmasq 재시작
- SCAN IP 1개 → PRVG-11368 경고
@NOTE 2노드 클러스터에 필요한 이름은 공용, VIP, 사설 각 두 개와 SCAN 하나로 모두 일곱 개입니다. FQDN과 짧은 이름을 함께 적고 두 노드의 파일을 diff로 대조합니다. cluvfy는 네임서버가 있고 그 네임서버가 노드 이름을 풀 것을 함께 요구하므로, 각 노드의 dnsmasq가 hosts 파일을 DNS로 서비스하게 했습니다. expand-hosts는 짧은 이름에 도메인을 붙여 주고 no-resolv는 무한 참조를 막습니다. SCAN이 IP 하나로 풀려 PRVG-11368 경고가 나오는데 실패가 아니라 권장 사항입니다.

@SLIDE srvctl로 보는 SCAN과 VIP|설치 결과를 Clusterware에게 묻는다
- srvctl config scan: rac-scan, 172.16.225.120
- srvctl config scan_listener: SCAN 리스너, 포트
- srvctl config vip -node rac2: rac2-vip .112
- srvctl config nodeapps: VIP·네트워크·ONS
- 없는 노드 → PRKO-2310
@NOTE OS에서 본 주소와 Clusterware에 등록된 구성은 srvctl로 대조합니다. config scan은 SCAN 이름과 서브넷, SCAN VIP 목록을 보여 주며 이 환경에서는 172.16.225.120 하나입니다. config scan_listener는 SCAN 리스너와 포트를 보여 줍니다. config vip에 노드를 지정하면 그 노드 VIP의 이름과 주소가 나오고, config nodeapps는 VIP와 네트워크, ONS를 함께 보여 줍니다. 없는 노드를 지정하면 PRKO-2310이 나오므로 노드 이름 오타를 잡는 데도 쓸 수 있습니다.

@SEC 2.8|Grid 홈과 두 ORACLE_HOME
- 계정별 환경 변수
- Grid 홈의 주요 디렉터리
- 진단 로그 위치

@IMG 02_homes.png|두 홈과 두 ORACLE_BASE|진단 로그 위치와 adrci 목록이 계정에 따라 갈린다
@NOTE RAC 서버에는 홈이 둘 있습니다. grid 계정은 Grid 홈과 ORACLE_BASE /u01/app/grid, SID +ASM1을 쓰고, oracle 계정은 dbhome_rac와 ORACLE_BASE /u01/app/oracle, SID racdb1을 씁니다. Grid 홈은 ORACLE_BASE 아래가 아니라 바깥에 있는데, 이것이 19c의 표준 배치입니다. ORACLE_BASE가 다르기 때문에 진단 로그도 갈립니다. Clusterware, ASM, 리스너 로그는 grid 쪽 diag에, 데이터베이스 로그는 oracle 쪽 diag에 있습니다. rac2에서는 SID가 +ASM2와 racdb2입니다.

@SLIDE Grid 홈의 주요 디렉터리|bin, network/admin, install
- bin: crsctl, srvctl, oifcfg, ocrcheck, asmcmd
- network/admin: ASM·SCAN 리스너 설정
- crs/install, install: 구성 스크립트, 설치 로그
- sqlplus는 두 홈에 각각, PATH가 결정
- 홈 목록은 oraInventory의 inventory.xml
@NOTE Grid 홈에는 항목이 많지만 자주 쓰는 것은 몇 개입니다. bin에는 crsctl, srvctl, oifcfg, ocrcheck, asmcmd 같은 관리 도구가 있습니다. network/admin에는 ASM 리스너와 SCAN 리스너 설정이 있고, DB 홈의 network/admin과는 별개입니다. sqlplus는 두 홈에 각각 있어서 grid로 실행하면 Grid 홈의 것이, oracle로 실행하면 DB 홈의 것이 잡힙니다. 설치된 홈 목록은 인벤토리가 가장 확실한 근거이고, RAC 데이터베이스 구성은 oratab이 아니라 srvctl config database로 확인합니다.

@SLIDE 진단 로그 위치|로그가 없다고 판단하기 전에 계정부터
- Clusterware: grid diag/crs/rac1/crs/trace/alert.log
- ASM: diag/asm/+asm/+ASM1
- DB: oracle diag/rdbms/racdb/racdb1
- adrci는 실행 계정의 ORACLE_BASE만 보여 줌
- 작업 전 whoami, ORACLE_HOME, ORACLE_SID 출력
@NOTE 진단 로그는 계정의 ORACLE_BASE 아래에 있습니다. Clusterware는 grid 쪽 diag, crs 아래 alert.log를 먼저 보고, 상세는 같은 폴더의 trc 파일을 봅니다. adrci는 실행한 계정의 ORACLE_BASE 아래 홈만 보여 주기 때문에 oracle로 실행하면 crs 홈이 목록에 없습니다. 로그가 없는 것이 아니라 계정이 다른 것입니다. 파일 자체는 oinstall 그룹 읽기 권한이 있어 경로를 알면 oracle로도 읽힙니다. 작업을 시작할 때 계정, 홈, SID 세 가지를 먼저 출력하는 습관을 들이면 이런 혼란이 줄어듭니다.

@PLAIN 요약
- 두 스택: OHAS(ohasd, OLR)와 CRS(crsd, OCR)
- 재부팅 권한이 필요한 데몬은 root, 감시자는 죽이지 않는다
- CRS-1601은 멤버십 확정, CRS-5019는 부팅 중 정상
- CRS-4639는 ohasd, CRS-4535는 crsd에 닿지 못함
- ora. 자원은 srvctl로, 옮겨 간 자원은 돌아오지 않음
- 용도는 oifcfg getif, 로그는 계정의 ORACLE_BASE 아래

@PLAIN 퀴즈
- 1. check has online, check crs CRS-4535일 때 조회 방법은?
- 2. stop cluster와 stop crs를 출력으로 구별하는 메시지는?
- 3. 부팅 로그의 CRS-5019에 조치가 필요한가?
- 4. crsd가 ocssd보다 늦게 뜨는 이유는?
- 5. iflist가 ens33을 PRIVATE으로 보여 주면 설정 오류인가?
- 6. oracle의 adrci 목록에 diag/crs가 없는 이유는?

@PLAIN 실습 개요
- 02-01  프로세스 식별  /  02-02  두 스택의 구분
- 02-03  자원 개념과 유형
- 02-05 ★  정지 시 오류 재현 (rac2 정지 후 복구)
- 03-01  네트워크 요건 확인
- 04-06  Grid 홈 구조  /  04-07  두 ORACLE_HOME 구분
- 파일: RAC/02장, 03장, 04장의 트랜스크립트
