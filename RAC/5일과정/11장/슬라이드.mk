@TITLE Oracle Database 19c RAC 과정|srvctl과 crsctl 명령 체계|두 도구의 경계, 자원 모델, 오류 접두어|제11장

@PLAIN 학습 목표
- srvctl과 crsctl의 대상·계정을 구분한다
- status와 config, stop과 disable을 구분한다
- crsctl stat res -t와 -init 목록을 읽는다
- 자원 속성과 의존 관계를 해석한다
- 사용자 스크립트를 클러스터 자원으로 등록한다
- 오류 접두어로 문제 계층을 좁힌다

@PLAIN Agenda
- 11.2  두 명령의 역할 분담
- 11.3  srvctl 명령·대상·옵션
- 11.4  crsctl stat res -t 읽기
- 11.5  자원 속성과 의존 관계
- 11.6  사용자 자원  /  11.7  오류 번호 체계

@SEC 11.2|두 명령의 역할 분담
- 경계와 CRS-4995
- 스택 상태 확인

@IMG 11_boundary.png|srvctl과 crsctl의 경계|Oracle 자원의 상태 변경은 srvctl만
@NOTE 두 명령이 어디까지 다루는지 그림으로 정리했습니다. 왼쪽 srvctl은 데이터베이스, 인스턴스, 서비스, 리스너처럼 Oracle이 정의한 자원을 기동하고 정지하고 조회합니다. 오른쪽 crsctl은 Clusterware 스택과 자원 정의 자체를 다룹니다. 빨간 점선이 핵심입니다. crsctl로 ora 자원을 조회하는 것은 되지만 기동이나 정지는 CRS-4995로 거부됩니다. 반대로 사용자가 등록한 자원은 srvctl이 아예 모르고 crsctl로만 다룹니다.

@SLIDE CRS-4995|경계를 넘으면 거부된다
- crsctl stop resource ora.racdb.db 거부
- Use srvctl for this command 안내, 종료 코드 1
- crsctl stat res ora.racdb.db -p 조회는 허용
- DB 정지 절차는 srvctl만 안다
@NOTE grid 계정으로 crsctl stop resource ora.racdb.db를 실행하면 CRS-4995가 나고 srvctl을 쓰라는 안내까지 나옵니다. 종료 코드도 1이라 스크립트에서 실패로 잡힙니다. 반면 같은 자원을 -p로 조회하는 것은 잘 됩니다. 자원 정의는 OCR에 있고 crsctl은 OCR을 읽는 도구이기 때문입니다. 데이터베이스를 내리는 일은 세션 정리, 체크포인트, 서비스 처리를 포함하는 절차라서 그 절차를 아는 srvctl에게만 맡깁니다. 읽기는 열고 쓰기는 막은 구조입니다.

@SLIDE 스택 상태 확인|crsctl로만 하는 일
- crsctl check crs: 이 노드, OHAS 포함 4개
- crsctl check cluster -all: 모든 노드, 3개씩
- OHAS는 노드별 최하위 데몬
- 스택 기동·정지는 root
@NOTE crsctl로만 할 수 있는 대표적인 일이 스택 상태 확인입니다. check crs는 실행한 노드에서 OHAS, CRS, CSS, EVM 네 가지가 online인지 보여 줍니다. check cluster에 all을 붙이면 모든 노드를 돌며 CRS, CSS, EVM 세 가지를 보여 줍니다. OHAS가 빠지는 이유는 노드마다 독립적으로 뜨는 맨 아래 데몬이라 클러스터 관점의 조회 대상이 아니기 때문입니다. 스택 자체를 올리고 내리는 crsctl start crs 같은 명령은 root 권한이 필요합니다.

@SEC 11.3|srvctl 명령·대상·옵션
- 3단 구조
- 대상별 출력
- -help와 -eval

@SLIDE 3단 구조|srvctl 명령 대상 옵션
- status와 config: 현실과 정의
- start·stop과 enable·disable
- add·modify·remove는 되돌리기 어려움
- 긴 옵션(-db)과 짧은 옵션(-d) 모두 허용
@NOTE srvctl은 명령, 대상, 옵션 순서로 씁니다. 이 구조만 알면 처음 보는 대상도 짐작할 수 있습니다. 가장 중요한 구분은 둘입니다. status는 지금의 현실이고 config는 저장된 정의입니다. stop은 지금 내리는 것이고 disable은 앞으로 자동으로 올라오지 않게 빼 두는 것입니다. 유지보수 때는 둘을 함께 씁니다. 19c는 db, instance처럼 긴 옵션 이름을 쓰고 d, i 같은 예전 짧은 이름도 받습니다. 과정의 트랜스크립트는 주로 짧은 이름을 씁니다.

@SLIDE 대상별 출력|enabled와 running을 나눠 말한다
- status scan과 status scan_listener는 별개
- SCAN은 IP 자원, SCAN 리스너는 프로세스
- 리스너 Owner는 grid
- status nodeapps: VIP·네트워크·ONS
@NOTE 대상마다 출력 형식이 조금씩 다르지만 공통적으로 enabled인지와 running인지를 나눠서 말합니다. SCAN과 SCAN 리스너는 별개 대상입니다. SCAN은 IP 주소 자원이고 SCAN 리스너는 그 주소에서 듣는 프로세스라 한쪽만 죽을 수 있습니다. 리스너 config를 보면 Owner가 grid입니다. 리스너는 Grid 홈에서 돌기 때문에 로그를 볼 때 grid로 붙어야 합니다. nodeapps는 VIP, 네트워크, ONS를 한 번에 보여 주는데 ONS는 13장에서 다시 나옵니다.

@SLIDE config database|정의로 읽는 기본값
- Start options open, Stop options immediate
- Management policy AUTOMATIC
- Disk Groups DATA,FRA → hard 의존
- 인스턴스 2개, 노드 2개 정의
@NOTE srvctl config database 출력에서 몇 줄만 골라 봅니다. Start options와 Stop options는 옵션 없이 기동하거나 정지할 때 쓰는 기본값입니다. 정지 기본값이 immediate이므로 진행 중 트랜잭션은 롤백됩니다. Management policy가 AUTOMATIC이면 클러스터가 뜰 때 데이터베이스도 함께 올라옵니다. Disk Groups 항목은 데이터베이스 자원이 어떤 디스크그룹에 의존할지를 만드는 목록입니다. 정의에는 인스턴스와 노드가 둘씩 있으니 status에 하나만 보이면 어긋난 것입니다.

@SLIDE -help와 -eval|문서보다 빠른 확인
- srvctl start database -help
- -eval: 실행 없이 영향만 계산
- -startconcurrency 1: 순차 기동
- status와 config를 한 세트로
@NOTE 옵션이 기억나지 않으면 해당 명령 뒤에 help를 붙입니다. 설치된 버전의 실제 문법이 나오므로 문서를 찾는 것보다 빠르고 정확합니다. eval은 명령을 실행하지 않고 영향만 계산해 줍니다. 서비스가 여럿 걸린 데이터베이스를 내리기 전에 무엇이 함께 내려가는지 미리 볼 때 씁니다. startconcurrency는 동시에 기동할 인스턴스 수입니다. 실습 환경처럼 자원이 넉넉하지 않으면 1로 두는 편이 안전합니다. 장애 때는 status와 config를 항상 짝으로 실행합니다.

@SEC 11.4|crsctl stat res -t 읽기
- 두 구획과 슬롯 번호
- 정상적인 OFFLINE
- -init 목록

@SLIDE 두 구획|Local과 Cluster Resources
- Local: 노드마다 하나, 노드 이름으로 구분
- Cluster: 정해진 개수, 왼쪽 숫자는 슬롯
- SCAN 리스너 슬롯 1개, racdb 슬롯 2개
- 일반 자원 17개를 기준선으로
@NOTE crsctl stat res -t 출력은 두 구획으로 나뉩니다. Local Resources는 노드마다 하나씩 있는 자원이라 왼쪽에 번호 없이 노드 이름으로 행이 나뉩니다. 노드 리스너와 네트워크 자원이 여기 있습니다. Cluster Resources는 클러스터 전체에서 정해진 개수만 도는 자원이고 왼쪽 숫자는 슬롯 번호입니다. 인스턴스 번호로 오해하기 쉬운데 다른 개념입니다. 실습 환경의 일반 자원은 17개입니다. 서비스나 사용자 자원을 만들면 늘어나므로 기준선으로 적어 둡니다.

@SLIDE 정상적인 OFFLINE|TARGET과 AUTO_START를 먼저 본다
- ora.chad rac2 OFFLINE: 부가 서비스
- ora.asmgroup 3번 슬롯: 노드가 둘이라 비어 있음
- ora.diskmon: AUTO_START never, Exadata 전용
- TARGET OFFLINE이면 의도된 상태
@NOTE 목록에 OFFLINE이 보인다고 모두 장애는 아닙니다. 실습 환경에서 Cluster Health Advisor인 ora.chad가 rac2에서 OFFLINE이었는데, srvctl status cha로 보면 enabled이지만 실행 중이 아니라고 나옵니다. 데이터베이스 동작에는 필수가 아닙니다. ora.asmgroup의 세 번째 슬롯은 Flex ASM 인스턴스 수가 3인데 노드가 둘이라 늘 비어 있습니다. ora.diskmon은 Exadata 전용이라 아예 올리지 않습니다. OFFLINE을 보면 TARGET과 AUTO_START부터 확인합니다.

@IMG 11_layers.png|두 개의 자원 목록|OHAS 관리 -init과 CRSD 관리 일반 목록
@NOTE crsctl stat res에 init을 붙이면 전혀 다른 목록이 나옵니다. cssd, crsd, ctssd, haip 같은 스택 자체의 자원으로, 노드마다 OHAS가 관리하므로 실행한 노드의 것만 보입니다. 기동 순서는 아래에서 위로 OHAS, CSSD, ASM, CRSD, 일반 자원입니다. CRSD는 OCR을 읽어야 일반 자원을 관리할 수 있는데 OCR이 CRS 디스크그룹에 있으니 ASM이 먼저 떠야 합니다. 그래서 ora.asm은 두 목록에 모두 나오고 각각 노드 관점과 클러스터 관점의 자원입니다.

@SLIDE 부팅이 멈췄을 때|아래에서 위로 본다
- -init에서 ora.cssd ONLINE인가
- 아니면 인터커넥트·보팅 파일 확인
- ora.crsd가 안 뜨면 ora.asm·OCR 확인
- 그다음 디스크그룹 → 데이터베이스 순
@NOTE 노드를 켰는데 데이터베이스가 안 올라올 때 데이터베이스 로그부터 뒤지는 것은 흔한 실수입니다. 아래 계층부터 봅니다. 그 노드에서 init 목록을 열어 cssd가 ONLINE인지 봅니다. 아니라면 클러스터에 합류하지 못한 것이니 인터커넥트와 보팅 파일을 확인합니다. cssd는 떴는데 crsd가 없으면 OCR을 읽지 못한 경우가 많아 ASM과 storage 자원을 봅니다. 여기까지 정상이면 일반 목록으로 올라와 디스크그룹에서 데이터베이스로 의존 순서를 따라갑니다.

@SEC 11.5|자원 속성과 의존 관계
- AUTO_START, RESTART_ATTEMPTS, CHECK_INTERVAL
- hard·weak·pullup

@SLIDE 자원 속성|-p가 보여 주는 동작 규칙
- AUTO_START: always / restore / never
- RESTART_ATTEMPTS: racdb 2, VIP 0, cssd 3
- CHECK_INTERVAL: racdb 900초, VIP·ASM 1초
- UPTIME_THRESHOLD 1h, CARDINALITY 2
@NOTE 자원 정의는 crsctl stat res에 p 옵션으로 봅니다. AUTO_START는 클러스터가 기동될 때 그 자원을 어떻게 할지 정하는데 대부분 restore입니다. 관리자가 내려 둔 자원은 재부팅 뒤에도 내린 채로 둔다는 뜻입니다. RESTART_ATTEMPTS는 같은 노드에서 되살릴 최대 횟수입니다. VIP가 0인 이유는 재시작 대신 다른 노드로 옮기는 것이 VIP의 역할이기 때문입니다. CHECK_INTERVAL은 점검 간격으로, 무거운 데이터베이스는 900초, 즉시 감지가 필요한 VIP는 1초입니다.

@IMG 11_deps.png|ora.racdb.db의 의존 관계|hard는 필수, weak는 선택, pullup은 연쇄 기동
@NOTE 데이터베이스 자원의 START_DEPENDENCIES를 그림으로 옮겼습니다. DATA와 FRA 디스크그룹에는 hard와 pullup이 함께 걸려 있습니다. 디스크그룹이 없으면 데이터베이스를 올릴 수 없고, 디스크그룹이 마운트되면 데이터베이스가 따라 올라갑니다. 리스너와 ONS는 weak라서 없어도 데이터베이스는 열립니다. 아래 ASM에서 오는 빨간 화살표는 STOP 의존으로 ASM이 내려가면 데이터베이스도 함께 내려갑니다. 오른쪽 위 CH9DG처럼 이미 지운 디스크그룹 이름이 정의에 남아 있을 수 있습니다.

@SLIDE 정의에 남은 옛 이름|동작에는 영향 없지만 정리한다
- pullup에 ora.CH9DG.dg가 남음
- crsctl stat res ora.CH9DG.dg → CRS-2613
- 없는 자원은 올라오지 않아 무해
- srvctl modify database -diskgroup으로 정리
@NOTE 실습 환경의 데이터베이스 자원 정의를 보면 pullup 절에 CH9DG라는 디스크그룹 이름이 남아 있습니다. ASM 실습에서 만들었다가 지운 것이라 조회하면 자원이 없다는 CRS-2613이 납니다. pullup은 그 자원이 올라오면 따라 올라간다는 조건이고 없는 자원은 영원히 올라오지 않으므로 동작에는 영향이 없습니다. 다만 나중에 출력을 읽는 사람이 없는 디스크그룹을 찾아 헤맬 수 있으니, 운영 환경이라면 디스크그룹 목록을 다시 지정해 정리합니다.

@SEC 11.6|사용자 스크립트를 클러스터 자원으로
- 액션 스크립트
- 등록과 자동 복구
- 복구 실패와 정리

@SLIDE 액션 스크립트의 약속|start · stop · check · clean
- check 0이면 살아 있음, 그 밖은 죽음
- clean은 실패 잔재를 강제로 치움
- 호출마다 로그 한 줄
- 두 노드 같은 경로, grid 소유 755
@NOTE Clusterware는 등록된 스크립트를 인자 하나와 함께 부릅니다. start는 기동, stop은 정지, check는 생존 확인, clean은 실패한 자원의 잔재를 강제로 치우는 일입니다. check가 0을 돌려주면 살아 있다고 보고 그 밖의 값이면 죽었다고 봅니다. 실습 스크립트는 상태 파일 하나로 살아 있음을 흉내 내고, 호출될 때마다 로그를 한 줄 남깁니다. 자원이 어느 노드에서 뜰지 모르므로 스크립트는 두 노드의 같은 경로에 같은 권한으로 둡니다.

@SLIDE 자원 등록|crsctl add resource
- -type cluster_resource, 노드마다면 local_resource
- PLACEMENT=restricted, HOSTING_MEMBERS=rac1 rac2
- CHECK_INTERVAL=30, RESTART_ATTEMPTS=2
- 등록 직후 OFFLINE, crsctl start로 기동
@NOTE crsctl add resource로 등록합니다. cluster_resource는 클러스터에서 정해진 개수만 도는 유형이고 노드마다 하나씩 필요하면 local_resource를 씁니다. PLACEMENT를 restricted로 두고 HOSTING_MEMBERS에 두 노드를 적어 그 안에서만 돌게 했습니다. 30초마다 check를 부르고 네트워크 자원에 hard 의존을 걸었습니다. 지정하지 않은 속성에는 AUTO_START restore, CARDINALITY 1 같은 기본값이 들어갑니다. 등록만 하면 OFFLINE이므로 crsctl start resource로 올립니다.

@IMG 11_userres.png|감지와 자동 복구|화면에는 한 번도 OFFLINE이 보이지 않았다
@NOTE 상태 파일을 지운 뒤의 시간축입니다. 12시 3분 16초에 파일을 지웠는데 Clusterware는 바로 알지 못하고 다음 check인 26초에 실패를 감지했습니다. 바로 다음 초에 start를 불러 되살렸습니다. 감지 지연의 상한은 CHECK_INTERVAL인 30초입니다. 흥미로운 점은 crsctl stat res로 계속 지켜봤는데도 OFFLINE이 한 번도 보이지 않았다는 것입니다. 복구가 1초 만에 끝났기 때문입니다. 자동 복구는 조용히 일어나므로 장애 이력은 로그로 확인해야 합니다.

@SLIDE 이동과 복구 실패|relocate와 포기한 상태
- relocate: 먼저 stop, 그다음 다른 노드에서 start
- 동시에 두 노드에서 도는 순간이 없음
- 실패: 노드마다 start·check·clean·check 한 번
- TARGET ONLINE, STATE OFFLINE, Server 빈칸
@NOTE crsctl relocate resource로 rac2에 옮기면 rac1에서 stop을 먼저 부르고 rac2에서 start를 부릅니다. 두 노드에서 동시에 도는 순간이 없어서 하나만 돌아야 하는 데몬에 맞습니다. start가 실패하도록 만들면 Clusterware는 현재 노드에서 start, check, clean, check를 부르고 다른 노드에서도 같은 순서를 한 번 밟은 뒤 멈춥니다. 결과는 TARGET은 ONLINE인데 STATE는 OFFLINE이고 서버 칸이 비어 있습니다. RESTART_ATTEMPTS가 2였어도 실제 시도는 노드마다 한 번이었습니다.

@SLIDE 정리와 감시|정지 후 삭제, srvctl은 모른다
- crsctl stop resource → delete resource
- 삭제 확인은 CRS-2613
- 두 노드의 스크립트와 /tmp 파일 삭제
- 감시 목록에 crsctl 조회 추가
@NOTE 사용자 자원은 정지한 뒤 삭제합니다. 삭제 뒤 조회하면 자원을 찾을 수 없다는 CRS-2613이 나오는데 이것이 정상 확인입니다. 자원 정의만 지우고 끝내면 두 노드에 스크립트와 상태 파일, 로그가 남으니 함께 지웁니다. 운영 관점에서 기억할 점이 하나 있습니다. srvctl은 사용자 자원을 모르기 때문에 srvctl만 도는 기존 점검으로는 이 자원이 죽어도 알 수 없습니다. 사용자 자원을 들이면 감시 목록에 crsctl 조회를 추가합니다.

@SEC 11.7|오류 번호 체계
- 접두어와 계층
- 겹친 오류 읽기

@IMG 11_errors.png|오류 접두어가 알려 주는 계층|겹치면 아래 줄이 원인
@NOTE 이 장에서 만난 오류를 접두어로 묶었습니다. PRKO는 srvctl이 명령행을 해석하는 단계의 오류라 입력한 명령을 다시 보면 됩니다. PRCD, PRCR, PRCC는 srvctl 내부의 데이터베이스, 자원, 공통 계층에서 나오며 명령은 맞지만 대상이 없거나 상태가 다르다는 뜻입니다. CRS는 Clusterware 자원 계층입니다. 오른쪽처럼 두 줄이 겹치면 위는 무엇을 하려다 실패했는지, 아래는 왜 실패했는지를 말하므로 아래 줄부터 읽습니다.

@SLIDE 오류처럼 보이는 정상|PRCC-1015와 종료 코드
- PRCC-1015 racdb was already running
- 원하는 상태가 이미 되어 있음
- 기동 스크립트가 실패로 처리하지 않게
- 알림은 마지막 줄과 종료 코드까지
@NOTE 이미 떠 있는 인스턴스에 start를 하면 PRCC-1015와 PRCR-1004가 나옵니다. 오류 형식이지만 원하는 상태가 이미 되어 있다는 뜻입니다. 기동 스크립트가 이 메시지를 실패로 처리하면 두 번째 실행에서 뒤 단계가 멈춰 버립니다. 메시지와 종료 코드를 함께 보고 판단하도록 스크립트를 짭니다. 알림 시스템도 마찬가지입니다. 첫 줄만 잘라 보내면 원인이 담긴 아래 줄이 빠지므로 마지막 줄과 종료 코드까지 보내도록 설정합니다.

@PLAIN 요약
- srvctl은 Oracle 자원, crsctl은 스택과 자원 모델
- ora 자원의 상태 변경을 crsctl로 하면 CRS-4995
- status는 현실, config는 정의
- 슬롯 번호, -init 목록, 정상적인 OFFLINE
- 속성과 hard·weak·pullup이 동작을 정한다
- 사용자 자원은 check로 감시, 로그로 확인
- 겹친 오류는 마지막 줄부터

@PLAIN 퀴즈
- 1. crsctl stop resource ora.racdb.db가 거부되는 이유는?
- 2. srvctl stop과 disable의 차이는?
- 3. ora.racdb.db 아래 1, 2의 뜻은?
- 4. ora.asm이 두 목록에 모두 나오는 이유는?
- 5. 사용자 자원 장애가 화면에 안 보인 이유는?
- 6. PRKO-3032와 PRCD-1120의 차이는?

@PLAIN 실습 개요
- 01  두 명령의 역할 분담 — CRS-4995
- 02  srvctl 자원별 문법 — status와 config
- 04  crsctl로 DB 정지 시도 — 막힘과 허용
- 06 ★  사용자 자원 등록 — 자동 복구·이동·실패
- 파일: RAC/14장/14장_실습_NN_*.txt
