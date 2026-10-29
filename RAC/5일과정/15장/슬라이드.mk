@TITLE Oracle Database 19c RAC 과정|노드 추가와 삭제|rac2 를 빼고 다시 넣는 동안 racdb1 은 멈추지 않는다|제15장

@PLAIN 학습 목표
- 노드가 기록되는 세 곳과 다루는 명령을 구분한다
- 노드 삭제 다섯 단계와 실행 위치를 설명한다
- 인벤토리 노드 목록을 -local 규칙에 맞게 고친다
- cluvfy 사전·사후 점검과 PRVG-11550 을 이해한다
- addnode.sh · root.sh · dbca -addInstance 로 재추가한다
- 잔재를 판단하고 기준선으로 원복을 검증한다

@PLAIN Agenda
- 15.2  노드 관리 작업의 전체 그림
- 15.3  추가·삭제 전 점검
- 15.4  노드 삭제  /  15.5  삭제 후 검증
- 15.6  노드 재추가
- 15.7  오류 재현 — 정리가 덜 된 재추가
- 15.8  원복 검증  /  15.9  다른 방법과 되돌리기

@SEC 15.2|노드 관리 작업의 전체 그림
- 세 계층
- 삭제와 추가의 순서
- 되돌림 지점

@IMG 15_layers.png|노드가 기록되는 세 곳|클러스터 구성, 소프트웨어 등록, 데이터베이스 구성
@NOTE 노드 하나는 세 곳에 기록되어 있습니다. 첫째는 공유 디스크의 OCR과 노드마다의 OLR로, 클러스터는 이것만 보고 움직입니다. 둘째는 노드마다 있는 중앙 인벤토리입니다. 여기 노드 목록이 틀려도 평소에는 아무 증상이 없지만, deinstall이나 addnode.sh, 패치 도구는 이 목록을 보고 대상을 정합니다. 셋째는 데이터베이스 구성으로, 스레드와 리두 그룹, UNDO, 인스턴스별 파라미터입니다. 노드를 빼거나 넣을 때는 이 세 곳을 모두 맞춰야 합니다.

@SLIDE 삭제와 추가의 순서|삭제는 설치의 역순
- 삭제: 인스턴스 → DB 홈 → Clusterware 해제 → OCR → 그리드 홈
- 추가: 그리드 홈 → root.sh → DB 홈 → root.sh → 인스턴스
- 추가 쪽 root.sh 가 OLR·스택·OCR 등록을 한 번에
- 인벤토리 목록은 OUI 의 -updateNodeList 로 고친다
@NOTE 삭제는 설치의 역순입니다. 맨 위에 올린 데이터베이스 인스턴스부터 지우고, DB 홈, Clusterware 구성, OCR 항목, 그리드 홈 순으로 내려갑니다. 추가는 반대로 그리드 홈을 복사하고 root.sh로 합류한 다음 DB 홈과 인스턴스를 올립니다. 삭제의 Clusterware 해제와 OCR 삭제에 해당하는 추가 명령은 따로 없습니다. 그리드 홈의 root.sh가 OLR을 만들고 스택을 올리고 OCR에 등록하는 일을 한 번에 합니다. 인벤토리 노드 목록은 각 홈의 OUI에 updateNodeList를 주어 고칩니다.

@SLIDE 되돌림 지점|노드 삭제는 되돌릴 수 없다
- OCR 에서 노드가 지워지고 소프트웨어가 삭제된다
- 공유 디스크는 VM 스냅샷에 들어가지 않는다
- 스냅샷 + -BackupShared 사본 + OCR 수동 백업
- 02·04 는 강사 시연, 수강생은 트랜스크립트 판독
@NOTE 노드 삭제는 되돌리기 어렵습니다. OCR에서 노드 항목이 지워지고 rac2의 소프트웨어가 삭제됩니다. 실습 환경의 공유 디스크는 independent-persistent 모드라 VM 스냅샷으로 되돌려도 OCR은 삭제된 상태 그대로입니다. 그래서 두 노드를 함께 정지해 뜬 스냅샷과 공유 디스크 사본, 그리고 작업 직전의 OCR 수동 백업을 합쳐서 되돌림 지점으로 삼습니다. 삭제와 재추가는 각각 1시간이 넘게 걸리므로 강사가 시연하고 수강생은 트랜스크립트로 출력을 판독합니다.

@SEC 15.3|추가·삭제 전 점검
- 노드 목록과 함께 사라지는 자원
- OCR 수동 백업과 기준선
- 인벤토리와 cluvfy

@SLIDE 노드 목록과 자원|pin 상태와 rac2 전용 자원을 본다
- olsnodes -n -s -t: 번호 1·2, Active, Unpinned
- Pinned 면 crsctl unpin css 먼저
- rac2-vip 172.16.225.112 는 rac2 전용 → 기록
- LISTENER·ONS 는 노드별 행, SCAN VIP 는 rac1
@NOTE 먼저 olsnodes로 노드 번호와 pin 상태를 봅니다. pin된 노드는 crsctl delete node 전에 unpin해야 하지만 11.2 이후 기본값은 Unpinned입니다. 노드 번호도 적어 두었다가 재추가 뒤 그대로인지 확인합니다. rac2-vip는 rac2 전용 자원이라 노드를 지우면 함께 사라지고, 다시 넣을 때 addnode.sh 인자로 되살립니다. 이름과 주소를 기록해 두십시오. 리스너나 ONS는 정의가 하나이고 노드별 행이 붙는 구조라 개수가 줄지 않습니다. SCAN VIP는 rac1에 있어 접속이 끊기지 않습니다.

@SLIDE OCR 수동 백업과 기준선|비교할 숫자를 먼저 남긴다
- ocrconfig -manualbackup — 시점을 직접 고른다
- CRS 자원 17 / -init 13, 보팅 파일 3
- OCR ID 665666554, OLR ID 노드별
- 서비스 10행, 리두 그룹 4, UNDO 2
@NOTE OCR 자동 백업은 4시간, 하루, 한 주 주기라 원하는 시점을 고를 수 없습니다. 작업 직전에 root로 수동 백업을 떠 둡니다. 그리고 비교할 기준선을 숫자로 남깁니다. CRS 자원 수와 하위 스택 자원 수, 보팅 파일 개수, ocrcheck의 OCR ID, ocrcheck local의 노드별 OLR ID, 데이터베이스 쪽의 서비스 행 수와 리두 그룹, UNDO 개수입니다. 삭제 뒤와 재추가 뒤에 같은 명령으로 다시 재서 어떤 값이 바뀌고 어떤 값이 그대로인지 비교합니다.

@SLIDE 인벤토리 노드 목록|비어 있으면 deinstall 이 노드를 모른다
- inventory.xml 의 그리드 홈·dbhome_rac 아래 NODE_LIST
- 실습 환경은 목록이 비어 있었다
- -updateNodeList "CLUSTER_NODES={rac1,rac2}"
- 홈 소유자로 실행, CRS=TRUE 는 그리드 홈에만
@NOTE 중앙 인벤토리의 inventory.xml을 열어 각 홈 아래에 노드 목록이 있는지 봅니다. 실습 환경에서는 설치 때 인벤토리를 손본 영향으로 보이는데 목록이 비어 있었습니다. 이대로 삭제를 시작하면 deinstall이 어느 노드가 클러스터 노드인지 알지 못합니다. OUI에 updateNodeList와 두 노드 목록을 주어 먼저 등록합니다. 그리드 홈은 grid, DB 홈은 oracle 계정으로 실행하고, CRS 등호 TRUE는 그리드 홈에만 붙입니다. local 없이 실행하면 rac2의 인벤토리도 함께 고쳐집니다.

@SLIDE cluvfy 사전 점검|삭제 사전 점검은 없다
- cluvfy stage -pre nodeadd -n rac2: 추가 전 점검
- -pre nodedel 은 사용법만 출력
- 삭제는 -post nodedel 로 사후 확인
- PRVG-11368: SCAN 단일 IP 설계 그대로
@NOTE cluvfy에는 노드 추가 전 점검인 pre nodeadd가 있습니다. rac2가 이미 멤버일 때 치면 이미 클러스터의 일부라고 알려 주고 통과합니다. 그런데 pre nodedel을 치면 오류 대신 사용법이 나옵니다. 삭제 전 점검은 없고 삭제 뒤의 post nodedel만 있다는 뜻입니다. 그래서 삭제 전에는 pin 상태, 자원, OCR 백업, 인벤토리를 직접 보는 것으로 대신합니다. 함께 본 경고 PRVG-11368은 SCAN이 IP 세 개 이상으로 풀리기를 권하는 것으로, 단일 IP로 구성한 이 환경에서는 정상입니다.

@SEC 15.4|노드 삭제
- 인스턴스와 DB 홈
- Clusterware 해제와 OCR 삭제
- 그리드 홈 삭제

@IMG 15_delete.png|노드 삭제 다섯 단계|단계마다 실행 노드와 계정이 다르다
@NOTE 삭제 다섯 단계를 실행 위치와 함께 정리한 그림입니다. 인스턴스 삭제는 살아남는 rac1에서 oracle 계정으로 합니다. DB 홈과 그리드 홈 삭제는 rac2에서 지우고 rac1에서 목록을 줄이는 두 노드 작업입니다. Clusterware 해제는 rac2에서 root로, OCR 항목 삭제는 rac1에서 root로 합니다. 이 과정 내내 racdb1은 Open 상태를 유지해야 하므로 단계마다 srvctl status database로 확인합니다. 시연을 보면서 지금 어느 노드의 어느 계정 프롬프트인지 계속 확인하십시오.

@SLIDE DB 인스턴스 삭제|rac1 에서 dbca -deleteInstance
- dbca 가 열린 racdb1 에 붙어 구조를 지운다
- thread 2, 리두 그룹 3·4, UNDOTBS2 제거
- 서비스 10 → 5, CRS 자원 17 그대로
- rac2 의 diag 디렉터리는 남는다
@NOTE 첫 단계는 rac1에서 dbca deleteInstance로 racdb2를 지우는 것입니다. dbca는 열려 있는 racdb1에 붙어서 데이터베이스 안의 구조, 즉 thread 2와 리두 그룹 3, 4, 그리고 UNDOTBS2를 지웁니다. 서비스 행은 10에서 5로 줄어듭니다. 그런데 CRS 자원 수는 17 그대로입니다. 데이터베이스 자원은 하나이고 인스턴스는 그 안의 칸으로 붙는 구조라 칸만 줄어들기 때문입니다. rac2의 진단 디렉터리는 장애 분석 기록이라 dbca가 지우지 않습니다.

@IMG 15_inventory.png|홈을 지우는 세 박자|지울 노드 -local, deinstall, 남는 노드
@NOTE DB 홈과 그리드 홈은 같은 세 박자로 지웁니다. 먼저 지울 노드 rac2에서 local 옵션을 붙여 자기 인벤토리 목록만 rac2로 줄입니다. 다음으로 deinstall을 checkonly로 돌려 응답 파일을 만들고, 지울 노드 목록에 rac1이 없는지 확인한 뒤 silent로 실제 삭제합니다. 마지막으로 남는 노드 rac1에서는 local 없이 목록을 rac1로 줄입니다. 첫 단계에서 local을 빼면 rac1의 목록까지 rac2 하나로 바뀌는 사고가 납니다. 단계마다 두 노드의 inventory.xml을 직접 열어 보십시오.

@SLIDE DB 홈 deinstall|응답 파일로 범위를 확인한다
- -checkonly: 지우지 않고 응답 파일만 생성
- "will be performed are:rac2" 확인
- DB_UNIQUE_NAME_LIST 비어 있음 — 인스턴스를 먼저 지운 덕
- 순서가 바뀌면 deinstall 이 DB 구성까지 건드린다
@NOTE deinstall은 바로 실행하지 않고 checkonly로 먼저 돌립니다. 아무것도 지우지 않고 응답 파일만 만들어 주는데, 출력에 삭제를 수행할 노드가 rac2만 나오는지 확인합니다. rac1이 보이면 거기서 멈춥니다. 응답 파일의 데이터베이스 목록 항목이 비어 있는 것도 봅니다. 앞 단계에서 인스턴스를 먼저 지웠기 때문입니다. 순서를 거꾸로 하면 여기에 racdb가 잡혀서 deinstall이 데이터베이스 구성까지 건드리려 합니다. 순서가 중요한 이유입니다.

@SLIDE Clusterware 해제|rac2 에서 rootcrs.sh -deconfig -force
- CLSRSC-336: deconfigured ... on this node
- -lastnode 금지 — OCR·보팅 파일까지 지운다
- rac1 에서 보면 rac2 Inactive, 자원 16 (rac2-vip 제거)
- rac2 crsctl check crs → CRS-4047
@NOTE 세 번째 단계는 rac2에서 root로 rootcrs.sh deconfig force를 실행하는 것입니다. force는 자원이 남아 있거나 다른 노드와 통신이 안 되어도 진행하라는 뜻입니다. 여기에 lastnode를 붙이면 안 됩니다. 마지막 노드용 옵션이라 OCR과 보팅 파일까지 지워 클러스터 전체를 해체합니다. 끝나면 rac1의 olsnodes에서 rac2가 Inactive로 보이고 자원은 rac2-vip가 빠져 16개가 됩니다. rac2에서 crsctl check crs를 치면 CRS-4047, 구성된 구성 요소가 없다는 메시지가 나옵니다.

@SLIDE OCR 에서 노드 삭제|rac1 에서 crsctl delete node
- crsctl delete node -n rac2 → CRS-4661
- 이제 olsnodes 에 rac1 만
- ASM·디스크그룹 자원은 세 칸 유지, rac2 칸만 OFFLINE
- Flex ASM 카디널리티 3
@NOTE 네 번째 단계는 rac1에서 root로 crsctl delete node를 실행해 OCR에서 rac2 항목을 지우는 것입니다. CRS-4661, 노드가 성공적으로 삭제되었다는 메시지가 나오고, 이 시점부터 rac2는 클러스터가 아는 노드가 아닙니다. olsnodes에는 rac1만 남습니다. ASM과 디스크그룹 자원은 여전히 세 칸이고 rac2가 쓰던 칸만 OFFLINE으로 바뀝니다. Flex ASM의 카디널리티가 3이라 노드 수가 줄어도 칸 수는 변하지 않습니다. 이 명령을 잘못된 노드에 치면 OCR 복원 말고는 돌아갈 곳이 없습니다.

@SLIDE 그리드 홈 삭제|deinstall 이 Standalone Server 홈으로 본다
- 세 박자 그대로, -updateNodeList 에 CRS=TRUE
- Clusterware 해제 뒤라 HOME_TYPE=SIHA
- 범위가 rac2 로 좁혀지고 ASM 미검출
- crsdata/rac2/crf 를 못 지워 261MB 잔재
@NOTE 마지막 단계는 그리드 홈 삭제입니다. 세 박자는 DB 홈과 같고 목록을 고칠 때 CRS 등호 TRUE를 붙입니다. 흥미로운 점은 deinstall이 이 홈을 Standalone Server 홈으로 본다는 것입니다. Clusterware를 이미 해제했기 때문에 Oracle Restart 홈처럼 보이는 것이고, 그 덕분에 지울 범위가 rac2 하나로 좁혀지고 공유 디스크그룹도 건드리지 않습니다. 다만 마지막 단계가 오류와 함께 끝나 클러스터 상태 모니터 저장소 아래 261MB가 남았습니다. 이것이 재추가 때 경고로 돌아옵니다.

@SEC 15.5|삭제 후 검증
- cluvfy -post nodedel
- 기준선 비교
- rac2 에 남은 것

@SLIDE 삭제 후 기준선|OCR 은 새로 만들지 않았다
- cluvfy stage -post nodedel -n rac2 → PASSED
- 자원 17 → 16, 보팅 파일 3 그대로
- OCR ID 665666554 그대로 — 항목만 삭제
- Type 은 여전히 RAC, 인스턴스 1개
@NOTE 삭제가 끝나면 rac1에서 cluvfy post nodedel을 돌립니다. 남은 노드의 CRS가 온전한지, rac2의 흔적이 클러스터 구성에 남지 않았는지를 봅니다. 그다음 기준선과 비교합니다. 자원은 rac2-vip가 빠져 16개, 보팅 파일은 그대로 3개입니다. OCR ID가 그대로인 것이 중요합니다. 노드 삭제는 OCR 안의 항목을 지운 것이지 OCR을 새로 만든 것이 아닙니다. 데이터베이스는 인스턴스가 하나로 줄었을 뿐 여전히 RAC 유형입니다.

@SLIDE rac2 에 남은 것|deinstall 은 Oracle 이 설치한 것만 지운다
- 빈 그리드 홈 디렉터리: 영향 없음
- /u01/app/grid 261MB: INS-40111 경고
- OS 계정·커널·SSH·공유 디스크 이름: 그대로
- cvuqdisk RPM 삭제됨: PRVG-11550
@NOTE rac2에 무엇이 남았는지도 확인합니다. 그리드 홈 자리는 빈 디렉터리만 남아 재추가에 영향이 없습니다. ORACLE_BASE에 남은 261MB는 재추가 때 INS-40111 경고로 돌아옵니다. OS 계정, 커널 파라미터, SSH 설정, 공유 디스크 이름 규칙처럼 설치 가이드 3장과 4장에서 준비한 것은 그대로라 다시 할 필요가 없습니다. 예외가 cvuqdisk입니다. 그리드 홈 deinstall이 함께 지운 것으로 보이며, 재추가 사전 점검에서 실패 원인이 됩니다.

@SEC 15.6|노드 재추가
- 사전 점검과 PRVG-11550
- 그리드 홈 확장과 root.sh
- DB 홈 확장과 인스턴스 추가

@IMG 15_add.png|노드 재추가 순서|rac1 에서 복사, rac2 에서 합류, 그다음 인스턴스
@NOTE 재추가 흐름입니다. rac1에서 사전 점검을 하고 grid 계정으로 그리드 홈을 확장합니다. addnode.sh가 rac1의 홈을 ssh로 rac2에 복사하고 root.sh 실행을 안내하면 rac2에서 root로 실행합니다. 이것으로 rac2가 클러스터에 합류합니다. 다음은 oracle 계정으로 DB 홈을 같은 방식으로 확장하고 rac2에서 DB 홈 root.sh를 실행합니다. 마지막으로 rac1에서 dbca addInstance로 racdb2를 넣고, 두 노드의 인벤토리 목록을 직접 확인하고 끝냅니다.

@SLIDE 사전 점검과 PRVG-11550|cvuqdisk 가 없으면 디스크 점검이 통째로 실패
- 전제: grid·oracle 계정 SSH 등가성, 호스트 키 미리 등록
- cluvfy stage -pre nodeadd -n rac2 → FAILED
- rac1 grid/cv/rpm 의 cvuqdisk 를 rac2 에 설치
- 재점검: 공유 디스크 8개 접근까지 PASSED
@NOTE addnode.sh는 rac1에서 ssh로 rac2에 복사하므로 홈 소유 계정의 등가성이 필요합니다. 사설망 이름으로 처음 붙으면 호스트 키 질문이 나와 설치 관리자가 멈추니 미리 한 번 붙어 둡니다. 이제 pre nodeadd 점검을 하면 PRVG-11550, cvuqdisk 패키지가 없다는 실패가 납니다. 이 도구가 없으면 ASM 디스크 점검이 통째로 실패합니다. rac1 그리드 홈의 cv rpm 디렉터리에 있는 RPM을 복사해 그룹을 oinstall로 지정해 설치합니다. 다시 점검하면 공유 디스크 접근까지 검사하고 통과합니다.

@SLIDE 그리드 홈 확장|addnode.sh 두 인자
- CLUSTER_NEW_NODES={rac2}: 공용 호스트명
- CLUSTER_NEW_VIRTUAL_HOSTNAMES={rac2-vip}: VIP 이름
- 시간 대부분은 그리드 홈 6.4GB 복사
- 끝나도 rac2 는 아직 멤버가 아니다
@NOTE 그리드 홈 addnode.sh에는 두 인자를 줍니다. 새 노드의 공용 호스트명과 그 노드의 VIP 이름입니다. VIP 이름은 점검 단계에서 기록해 둔 rac2-vip이고 hosts 파일에도 그대로 남아 있습니다. 실행 시간의 대부분은 6.4GB짜리 그리드 홈을 rac2로 보내는 데 씁니다. 실행 중에는 두 노드 어느 쪽도 끄지 않습니다. addnode.sh가 성공으로 끝나도 rac2는 아직 클러스터 멤버가 아니고 소프트웨어만 복사된 상태입니다. 안내되는 root.sh를 실행해야 합류합니다.

@SLIDE 그리드 root.sh|rac2 가 클러스터에 합류한다
- OLR 생성, ohasd 등록, 하위 스택 기동
- CSS 합류, OCR 에 rac2·rac2-vip 등록
- ASM 기동, 디스크그룹 마운트
- olsnodes: rac2 다시 번호 2, Active
@NOTE rac2에서 root로 그리드 홈의 root.sh를 실행합니다. 화면에는 로그 위치 한 줄만 나오지만, 그 몇 분 동안 많은 일이 일어납니다. 로컬 레지스트리인 OLR을 만들고, ohasd를 등록해 하위 스택을 올리고, CSS로 클러스터에 합류하고, OCR에 rac2와 rac2-vip를 등록하고, ASM을 띄워 디스크그룹을 마운트합니다. 끝나면 rac1의 olsnodes에서 rac2가 다시 번호 2로 Active입니다. 지웠던 번호 자리가 비어 있어 그대로 받았습니다. 데이터베이스는 아직 rac1 한 줄입니다.

@SLIDE DB 홈 확장과 인스턴스 추가|addnode.sh 다음에 dbca
- DB 홈 addnode.sh: VIRTUAL_HOSTNAMES 없음
- DB 홈 root.sh 는 클러스터 구성을 건드리지 않음
- dbca -addInstance: thread 2, 리두 3·4, UNDOTBS2 복원
- 순서가 바뀌면 rac2 에 실행 파일이 없다
@NOTE DB 홈은 oracle 계정으로 addnode.sh를 실행합니다. VIP는 그리드 쪽 자원이라 이미 있으므로 VIP 인자는 없습니다. rac2에서 DB 홈 root.sh를 실행하는데, 이것은 클러스터 구성을 건드리지 않습니다. 그다음 rac1에서 dbca addInstance로 racdb2를 넣으면 삭제 때 지워졌던 thread 2, 리두 그룹 3과 4, UNDOTBS2가 되살아나고 인스턴스가 뜹니다. dbca는 rac2에 DB 홈이 있어야 인스턴스를 띄울 수 있으므로 반드시 addnode.sh를 먼저 합니다.

@SEC 15.7|오류 재현 — 정리가 덜 된 재추가
- 반쪽짜리 그리드 홈
- 잔재 위에 다시 실행
- 판단 기준

@SLIDE 반쪽짜리 그리드 홈|복사 20% 에서 원본 노드가 재부팅됐다
- 6.4GB 중 3.1GB, root.sh 는 있고 crsctl 은 없음
- root.sh 를 치면 중간에 멈춘다
- ohasd 미등록, rac1 에서 rac2 안 보임
- 구성 단계 전이라 덮어쓸 수 있다
@NOTE 첫 번째 그리드 홈 addnode.sh는 복사 20%에서 끊겼습니다. addnode.sh를 돌리던 rac1이 복사 도중 재부팅된 것입니다. rac2에는 6.4GB 중 3.1GB만 와 있었고, root.sh 파일은 있는데 crsctl 실행 파일은 없었습니다. 위험한 조합입니다. root.sh가 보이니 실행하고 싶어지지만 필요한 바이너리가 없어 중간에 멈추고, 반쯤 구성된 노드는 처음보다 정리하기 어렵습니다. 다행히 ohasd가 등록되지 않았고 rac1에서도 rac2가 보이지 않아 구성 단계 전이었습니다.

@SLIDE 잔재 위에 다시 실행|두 경고는 WARNING 으로 지나간다
- INS-40111: ORACLE_BASE 가 비어 있지 않다
- INS-43055: 홈 자리 미등록·비어 있지 않음 → 덮어씀
- Advice is CONTINUE, 두 번째 시도 성공
- 이어서 root.sh 도 정상
@NOTE 두 번째 addnode.sh는 성공했고 경고가 두 개 나왔습니다. INS-40111은 rac2의 ORACLE_BASE가 비어 있지 않다는 경고로, 삭제 때 남은 261MB 때문입니다. INS-43055는 그리드 홈 자리가 인벤토리에 등록되지 않았는데 비어 있지도 않으니 비우지 않으면 덮어쓴다는 경고입니다. 로그에 계속 진행한다는 판단이 찍히고 덮어썼습니다. 이번에 통한 이유는 rac2에 파일만 있고 Clusterware 구성은 없었기 때문입니다. 이어서 실행한 root.sh도 정상으로 끝났습니다.

@IMG 15_leftover.png|잔재 판단 기준|Clusterware 구성이 남았는가
@NOTE 잔재가 남은 노드에 다시 넣을 수 있는지는 질문 하나로 판단합니다. rac2에 Clusterware 구성이 남아 있는가입니다. rac1의 olsnodes에 rac2가 보이면 OCR에 항목이 남은 것이니 crsctl delete node를 먼저 합니다. rac2에 ohasd 등록이 있으면 root.sh가 중간까지 진행된 것이니 rootcrs.sh deconfig force로 걷어 냅니다. 둘 다 아니면 파일만 남은 것이므로 addnode.sh를 다시 돌려 덮어쓰면 됩니다. addnode.sh가 root.sh 실행을 안내하지 않았다면 root.sh는 치지 않습니다.

@SEC 15.8|원복 검증
- cluvfy -post nodeadd 와 기준선
- 인벤토리는 늘어나지 않았다
- PDB 저장 상태와 재기동

@SLIDE 기준선 대조|달라진 값은 rac2 OLR ID 하나
- cluvfy -post nodeadd: 경고 PRVG-11368 하나
- 자원 17 / 13, OCR ID 그대로
- 서비스 10, 리두 4, UNDO 2 복원
- OLR ID rac2: 877385927 → 930016669
@NOTE 재추가가 끝나면 post nodeadd 점검을 돌립니다. 경고는 작업 전과 같은 SCAN 경고 하나이고 새로 생긴 것이 없습니다. 노드 애플리케이션 항목은 rac2의 VIP, 리스너, ONS가 다시 만들어졌는지 보는 것입니다. 기준선과 대조하면 자원 수, OCR ID, 서비스, 리두 그룹, UNDO가 모두 돌아왔습니다. 달라진 값은 rac2의 OLR ID 하나입니다. OLR은 rac2 로컬 디스크에 root.sh가 새로 만들었으니 바뀌는 것이 정상이고, 바뀌지 않았다면 옛 OLR이 남아 있었다는 신호입니다.

@SLIDE 인벤토리는 늘어나지 않았다|성공 메시지와 파일 내용이 다르다
- addnode.sh: Update Inventory successful
- 두 노드 inventory.xml: 여전히 rac1 한 줄
- 로그: 홈 플래그 clean → 저장 건너뜀
- -updateNodeList "{rac1,rac2}" 로 정정
@NOTE 재추가 뒤 이상한 점이 하나 있었습니다. addnode.sh는 두 번 다 인벤토리 저장과 갱신에 성공했다고 찍었는데, 두 노드의 inventory.xml에는 여전히 rac1 한 줄만 있었습니다. 로그를 보면 홈 플래그가 clean이라 바뀐 것이 없다고 판단해 저장을 건너뛰었습니다. 왜 그렇게 판단했는지는 더 좁히지 못했습니다. 당장 증상은 없지만 패치 도구가 rac1만 패치하거나 다음 삭제가 꼬일 수 있습니다. 점검 때와 같은 updateNodeList 명령으로 두 노드 목록을 넣어 고쳤습니다.

@SLIDE PDB 저장 상태와 재기동|Target OFFLINE 은 자동으로 올리지 않는다
- dba_pdb_saved_states 에 racdb2 행 확인
- 없으면 racdb2 에서 save state
- 재기동 후 DB 정지 — 마지막에 srvctl 로 내렸기 때문
- srvctl start database 한 번에 두 인스턴스 기동
@NOTE 데이터베이스 쪽에서는 PDB 저장 상태를 확인합니다. racdb2 행이 없으면 racdb2가 다시 뜰 때 PDB가 MOUNTED로 남습니다. 빠져 있으면 racdb2에서 save state를 합니다. 또 두 노드를 함께 정지했다 켰을 때 클러스터는 올라왔는데 데이터베이스는 내려가 있었습니다. Target이 OFFLINE이었는데, 지난번에 srvctl로 내렸다는 기록입니다. Management policy가 AUTOMATIC이어도 관리자가 내린 자원은 다시 올리지 않습니다. srvctl start database 한 번으로 두 인스턴스가 뜨면 등록이 정상입니다.

@SEC 15.9|다른 방법과 되돌리기
- 골드 이미지 방식
- 멈춘 지점별 되돌리기

@SLIDE 다른 방법과 되돌리기|멈춘 지점마다 돌아갈 곳이 다르다
- 골드 이미지(-createGoldImage), clone.pl 은 deprecated
- 복사 중 중단 → addnode.sh 재실행
- root.sh 중 중단 → deconfig, 필요하면 delete node
- OCR 손상 → ocrconfig -restore (3장)
@NOTE 여러 노드를 한꺼번에 늘리거나 원본 노드와 연결하기 어려우면 홈을 미리 묶어 두는 골드 이미지 방식을 씁니다. 19c에서는 각 홈의 설치 도구에 골드 이미지 생성 옵션이 있고, 예전 clone.pl 방식은 사용 중단 대상입니다. 실패했을 때는 멈춘 지점에 따라 되돌립니다. 복사 중이면 다시 실행하고, root.sh 도중이면 구성을 해제하고 필요하면 OCR 항목도 지웁니다. dbca 도중이면 deleteInstance로 지우고 다시 합니다. OCR이 손상됐을 때만 3장의 수동 백업 복원으로 갑니다.

@PLAIN 요약
- 노드는 OCR · 인벤토리 · DB 구성 세 곳에 기록된다
- 삭제: deleteInstance → deinstall → deconfig → delete node → deinstall
- 지울 노드 -local, 남는 노드 -local 없이
- -pre nodedel 은 없다. 삭제는 -post nodedel 로
- 재추가: addnode.sh → root.sh → addnode.sh → root.sh → dbca
- 달라지는 값은 rac2 OLR ID, 인벤토리는 직접 확인

@PLAIN 퀴즈
- 1. 노드가 기록되는 세 곳과 각각을 다루는 명령은?
- 2. 노드 삭제의 다섯 단계를 순서대로?
- 3. 지울 노드에서 -updateNodeList 에 -local 을 붙이는 이유는?
- 4. rootcrs.sh -deconfig 에 -lastnode 를 붙이면 안 되는 이유는?
- 5. 재추가 사전 점검의 PRVG-11550 원인과 조치는?
- 6. 재추가 뒤 rac2 OLR ID 만 바뀐 이유는?

@PLAIN 실습 개요
- 01 ★  추가·삭제 전 점검 — 기준선, OCR 백업, 인벤토리
- 02  노드 삭제 — 강사 시연, 트랜스크립트 판독
- 03  삭제 후 검증 — -post nodedel, 잔재 확인
- 04  노드 재추가 — 강사 시연, 트랜스크립트 판독
- 02·04 는 1시간이 넘고 되돌리기 어려워 시연으로 진행
- 파일: RAC/18장/18장_실습_NN_*.txt
