@TITLE Oracle Database 19c RAC 과정|OCR과 Voting File 관리|백업, 다중화, 재배치, 그리고 복구|제3장

@PLAIN 학습 목표
- OCR과 OLR의 위치·범위·읽는 주체를 구분한다
- PROT-24/25를 읽고 백업 주기를 설명한다
- manualbackup과 export를 만들고 차이를 말한다
- OCR을 다중화하고 되돌린다
- Voting File 개수와 과반수 규칙을 설명한다
- 배타 모드 복구 절차를 말한다

@PLAIN Agenda
- 3.2  OCR과 OLR
- 3.3  백업 상태 진단  /  3.4  백업을 만든다
- 3.5  OCR 다중화
- 3.6  Voting File
- 3.7  디스크를 내려 본다  /  3.8  복구 절차

@SEC 3.2|OCR과 OLR
- 레지스트리의 구조
- 두 레지스트리의 분업
- ocrcheck와 ocr.loc

@IMG 03_registry.png|OCR과 OLR|OLR은 로컬에서, OCR은 +CRS에서 읽힌다
@NOTE Clusterware가 의지하는 저장소는 셋입니다. 왼쪽의 OLR은 노드마다 로컬 디스크에 하나씩 있고 ohasd가 읽습니다. 오른쪽의 OCR은 +CRS 디스크그룹 안에 하나 있고 crsd가 읽습니다. Voting File도 +CRS 디스크에 있지만 ASM 파일이 아니라 디스크에 직접 기록됩니다. 아래 상자에 정리한 것처럼 이 배치는 부팅 순서에서 나왔습니다. ASM을 띄우는 방법은 OLR에 있어야 하고, 멤버십은 ASM 없이 Voting File로 정해야 하며, OCR은 ASM이 뜬 뒤에 읽습니다.

@SLIDE 레지스트리의 구조|키 트리, 키마다 권한
- 점으로 구분한 키 경로와 값의 트리
- 키마다 타입과 SECURITY 블록
- 노드별 버전·패치 수준도 기록
- 자원 정의, VIP·SCAN, 백업 위치까지
- 내용 확인: ocrdump 파일명
@NOTE OCR은 이름 그대로 레지스트리입니다. 점으로 구분된 키 경로와 값으로 이루어진 트리이고, ocrdump로 텍스트 파일에 뽑아 볼 수 있습니다. 키마다 값의 타입과 SECURITY 블록이 붙어 있어서 접근 제어가 키 단위로 됩니다. 노드별 버전과 패치 수준도 따로 기록되어 있어서 롤링 패치 중 노드마다 버전이 달라도 클러스터가 동작합니다. 자원 정의, 노드 목록, VIP와 SCAN, 그리고 OCR 백업 위치 설정까지 클러스터 구성 전체가 이 안에 있습니다.

@SLIDE OCR과 OLR의 분업|무엇을 어디서 누가 읽는가
- OCR: +CRS, 클러스터 1벌, crsd, ocr.loc
- OLR: crsdata/rac1/olr, 노드마다 1벌, ohasd
- OCR 자동 백업: 4시간 주기
- OLR 자동 백업: 설치·구성 변경 시점
- OLR ID는 노드마다, OCR ID는 같다
@NOTE 두 레지스트리를 표로 정리하면 범위, 위치, 읽는 주체, 위치 파일, 확인 명령, 백업 방식이 모두 다릅니다. OCR은 클러스터에 하나이고 ocr.loc가 위치를 알려 주며, OLR은 노드마다 하나이고 olr.loc가 위치를 알려 줍니다. OCR은 ASM 안에 있는데 ASM을 띄우려면 먼저 띄우는 방법을 알아야 합니다. 그 정보를 OLR에 두었기 때문에 OLR은 로컬 파일이어야 합니다. rac1과 rac2에서 OLR ID가 서로 다르게 나오는 것은 복제본이 아니라 별개의 레지스트리이기 때문입니다.

@SLIDE ocrcheck와 ocr.loc|ID는 기준값으로 기록한다
- ID 665666554: 다중화·이동에도 불변
- integrity check: 블록 체크섬
- Logical corruption check: 키 트리 관계
- ocr.loc: OCR 위치의 부트스트랩 파일
- 조회는 grid, 변경은 root (PROT-20)
@NOTE ocrcheck 출력에서 가장 먼저 보는 것은 ID입니다. OCR을 다중화하거나 위치를 옮겨도 이 값은 바뀌지 않으므로, 작업 전후에 다르다면 다른 OCR을 물고 있다는 뜻입니다. 아래 두 검사는 층위가 다릅니다. 하나는 저장 위치의 블록 체크섬이고 다른 하나는 키 트리의 부모와 자식 관계입니다. ocr.loc는 OCR 위치를 담은 평문 파일인데 손으로 고치지 않고 ocrconfig 명령으로만 바꿉니다. 조회는 grid로 되지만 백업이나 추가, 삭제는 root만 되며 grid로 하면 PROT-20이 납니다.

@SEC 3.3|백업 상태 진단
- PROT-24와 PROT-25
- 자동 백업 주기
- OLR 백업

@SLIDE PROT-24와 PROT-25|설치 직후에는 OCR 백업이 없다
- PROT-24: 자동 백업 없음
- PROT-25: 수동 백업 없음
- 자동 백업은 crsd 연속 가동 4시간마다
- crsd 재시작 때 타이머 초기화
- crsd 기동 시각: ps -eo pid,lstart,cmd
@NOTE 2장 실습에서 showbackup을 실행했을 때 두 메시지가 나왔습니다. 오류처럼 보이지만 상태 보고입니다. PROT-24는 자동 백업이, PROT-25는 수동 백업이 하나도 없다는 뜻입니다. 수동 백업은 아무도 만들지 않았으니 없고, 자동 백업은 crsd가 4시간 연속으로 떠 있어야 만들어집니다. 이 타이머는 crsd가 재시작될 때마다 처음부터 다시 셉니다. 필요할 때만 VM을 켜는 실습 환경이나 매일 클러스터를 내렸다 올리는 현장에서는 자동 백업이 영원히 안 생길 수도 있습니다.

@SLIDE OLR 백업과 백업 위치|OLR 백업은 이미 두 벌 있다
- backup_: root.sh가 OLR을 만든 직후
- autobackup_: 구성 완료 직후
- 노드 로컬, 그 노드에서만 보임
- 끝의 724960844는 패치 수준
- OCR 백업 기본 위치는 +CRS (cdata 아님)
@NOTE OCR과 달리 OLR 백업은 설치 시점에 이미 두 벌 있습니다. root.sh가 OLR을 만든 직후의 backup과 구성이 끝난 뒤의 autobackup입니다. OLR은 구성이 바뀔 때만 갱신되므로 사건을 계기로 백업합니다. 노드 로컬이라 rac2에서는 rac2의 백업만 보이고, 노드가 통째로 사라지면 백업도 함께 사라집니다. 목록 끝의 숫자는 패치 수준이며 다른 패치 수준의 백업으로 복원하면 안 됩니다. 11g 자료에 나오는 cdata 디렉터리는 19c에 없고, OCR 백업의 기본 위치는 +CRS입니다.

@SEC 3.4|백업을 만든다
- 수동 백업
- 공유 저장소 제약
- 논리적 내보내기

@IMG 03_backup.png|두 가지 백업|manualbackup은 마스터 노드가 +CRS에, export는 로컬 파일로
@NOTE OCR 백업은 두 가지입니다. rac1에서 root로 manualbackup을 실행하면 요청은 OCR 마스터 노드로 가고, 그림에서는 rac2가 +CRS의 OCRBACKUP 디렉터리에 백업을 남깁니다. 그래서 출력 첫 칸에 rac2가 찍힙니다. export는 명령을 실행한 노드의 로컬 파일로 키만 직렬화해서 수백 KB 정도입니다. 백업 위치를 로컬 디렉터리로 바꾸려 하면 PROT-42로 거절됩니다. 노드와 함께 사라질 수 있는 위치이기 때문입니다. 아래쪽에는 자동 백업과 OLR 백업, 되살리는 명령을 정리했습니다.

@SLIDE 수동 백업|출력 한 줄에 세 가지 사실
- 위치: +CRS:/rac-cluster/OCRBACKUP/
- .258.1242835765: ASM 파일 번호와 incarnation
- 첫 칸 rac2: OCR 마스터 노드가 수행
- Redund MIRROR: 백업도 두 벌
@NOTE ocrconfig manualbackup을 실행하면 한 줄이 출력됩니다. 이 한 줄에서 세 가지를 읽습니다. 백업은 +CRS 디스크그룹 안의 정규 ASM 파일이고, 이름 끝의 두 숫자는 5장에서 다룰 ASM 파일 번호와 incarnation입니다. 맨 앞 노드 이름이 rac2인데, 명령은 rac1에서 실행했어도 백업은 OCR 마스터 노드가 수행하기 때문입니다. asmcmd로 보면 종류가 OCRBACKUP이고 Redund가 MIRROR로 나옵니다. +CRS가 Normal이라 백업 파일도 두 벌로 저장되어 디스크 한 장을 잃어도 남습니다.

@SLIDE 백업 위치 제약과 export|로컬 디렉터리는 PROT-42
- backuploc /u01/...: PROT-42 (저장소 종류)
- 유효: ASM 디스크그룹, 공유 파일 시스템
- export: 키만 직렬화, 위치 제약 없음
- 되살리기: -restore / -import
- 구성 변경 전 둘 다, export는 클러스터 밖으로
@NOTE 백업 위치를 /u01 아래로 바꾸려 하면 소유자를 맞춰 줘도 PROT-42가 납니다. 권한 문제가 아니라 노드 로컬 디스크라서 거절된 것입니다. 백업이 rac1에만 쌓이면 rac1이 사라질 때 백업도 사라지기 때문입니다. 반면 export는 로컬 파일 시스템 어디에나 쓸 수 있습니다. 물리 백업은 restore로, export는 import로 되살립니다. 물리 백업은 +CRS 안에 있어 디스크그룹이 사라지면 함께 사라지므로, 구성 변경 직전에는 두 가지를 함께 만들고 export 파일은 클러스터 밖으로 옮깁니다.

@SLIDE 백업이 없을 때의 대가|두 줄이면 피할 수 있었다
- +CRS 손상, showbackup은 PROT-24/25
- 복원할 대상 없음 → GI 재구성
- +DATA 파일은 남았지만 자원 재등록
- 설치 직후 manualbackup과 export
@NOTE 교육용 클러스터에서 실제로 있었던 일입니다. 실습 도중 +CRS 디스크그룹이 손상됐는데 showbackup이 PROT-24와 25였습니다. 자동 백업 주기가 돌기 전이었고 수동 백업은 아무도 만들지 않았습니다. 복원할 것이 없어서 두 노드의 Clusterware 구성을 지우고 Grid Infrastructure를 다시 구성해야 했습니다. 데이터베이스 파일은 +DATA에 남아 있었지만 srvctl add database부터 자원을 하나하나 다시 등록했습니다. 설치 직후 manualbackup과 export 두 줄만 실행했어도 피할 수 있던 작업입니다.

@SEC 3.5|OCR 다중화
- 잘못된 위치는 걸러진다
- 두 벌로 만들기
- 마지막 한 벌

@SLIDE OCR 다중화|최대 5곳, 변경은 모든 노드에 전파
- +NOSUCHDG: PROT-30 + PROC-50(노드 이름)
- +CRS 다시: PROT-29 이미 등록
- add +DATA: 두 위치, ID 그대로
- ocr.loc에 ocrmirrorconfig_loc 추가 (rac2도)
- +CRS는 MIRROR, +DATA는 UNPROT
@NOTE OCR은 최대 다섯 곳까지 등록할 수 있습니다. 없는 디스크그룹을 넣으면 PROT-30과 PROC-50이 나오는데, PROC-50은 접근하지 못한 노드 이름을 알려 주므로 한 노드만 마운트하지 못한 상황을 찾는 데 유용합니다. 이미 있는 위치를 다시 넣으면 PROT-29입니다. +DATA를 추가하면 ocrcheck에 두 위치가 나오고 ID는 그대로입니다. rac1에서 한 번 실행했을 뿐인데 rac2의 ocr.loc도 바뀝니다. 같은 OCR이 +CRS에서는 미러링되고 +DATA에서는 보호 없이 저장되어 위치마다 보호 수준이 다릅니다.

@SLIDE 마지막 한 벌|PROT-28이 막는다
- 두 벌일 때는 -delete로 하나 제거 가능
- 한 벌 남으면 PROT-28
- 다시 만든 위치는 파일 번호가 바뀜, ID 불변
- 이동: add → 검증 → delete
- replace는 한 번에, 중간 검증 없음
@NOTE 두 벌일 때 한 위치를 지우면 지워지고 클러스터는 아무 일 없이 돕니다. 살아 있는 OCR이 하나 남아 있기 때문입니다. 한 벌만 남은 상태에서 지우려 하면 PROT-28로 막힙니다. 지웠다 다시 만든 위치는 ASM 파일 번호가 달라지지만 내용은 같으므로 ID는 그대로입니다. 스토리지를 교체하며 OCR을 옮길 때는 새 위치를 추가하고 두 위치가 모두 정상인지, 두 노드의 ocr.loc가 같은지 확인한 다음 옛 위치를 지웁니다. replace는 한 명령으로 끝나지만 중간에 검증할 기회가 없습니다.

@SEC 3.6|Voting File
- 개수와 과반수
- ASM 파일이 아니다
- replace와 롤백

@IMG 03_voting.png|Voting File과 과반수|개수는 이중화가 정하고 노드는 과반수에 닿아야 남는다
@NOTE Voting File은 노드들이 생존 신호를 쓰고 서로의 신호를 읽는 공용 게시판입니다. 위쪽의 인터커넥트 하트비트가 끊기면 어느 노드가 살아남을지를 여기서 정합니다. +CRS는 Normal이고 디스크 세 장이 각자 다른 장애 그룹이라 Voting File이 세 개입니다. 개수는 사람이 정하지 않고 이중화 수준이 정합니다. 노드는 과반수, 즉 셋 중 둘에 닿아야 클러스터에 남습니다. 짝수면 반반으로 갈렸을 때 결론이 나지 않으므로 홀수를 씁니다.

@SLIDE ASM 파일이 아닌 Voting File|asmcmd에는 보이지 않는다
- +CRS 목록: ASMPARAMETERFILE, OCRBACKUP, OCRFILE
- 디스크의 정해진 위치에 직접 기록
- CSS가 ASM보다 먼저 읽어야 하기 때문
- File Name 열은 /dev/asmdisk/crs1 형태
- ASM 쪽 확인: VOTING_FILES, VOTING_FILE 열
@NOTE asmcmd로 +CRS 아래를 보면 ASM 파라미터 파일, OCR 백업, OCR 파일만 있고 Voting File은 없습니다. 이것이 정상입니다. Voting File은 디스크의 정해진 위치에 직접 기록됩니다. CSS는 ASM 인스턴스가 뜨기 전에 Voting File을 읽어 멤버십을 정해야 하는데, ASM이 필요한 자리에 ASM을 쓸 수는 없기 때문입니다. 그래서 query css votedisk의 File Name 열에 원시 장치 경로가 찍힙니다. ASM 쪽에서는 디스크그룹의 VOTING_FILES 열과 디스크의 VOTING_FILE 열로 확인합니다.

@SLIDE replace와 롤백|개별 add·delete는 막혀 있다
- add/delete css votedisk: CRS-4258
- 같은 디스크그룹으로 replace: CRS-4261
- 없는 디스크그룹: CRS-4648 … ORA-15001
- CRS-4628: 실패했지만 롤백 성공
- 오류 스택은 아래부터 읽는다
@NOTE Voting File이 ASM에 있으면 개별 추가와 삭제는 CRS-4258로 막힙니다. grid든 root든 같으니 권한이 아니라 규칙의 문제입니다. 남은 수단은 디스크그룹 단위로 통째 옮기는 replace 하나입니다. 같은 디스크그룹으로 하면 CRS-4261입니다. 없는 디스크그룹을 지정하면 긴 오류가 나오는데 실제 원인인 ORA-15001은 스택 아래쪽에 있습니다. 가장 중요한 줄은 CRS-4628입니다. 실패했지만 롤백에 성공해 중간 상태로 남지 않았다는 보증입니다. 이 줄이 없으면 현재 상태를 직접 조회합니다.

@SLIDE 옮겼다 되돌리기|0개가 되는 순간은 없다
- replace +DATA: 1개 추가 → 3개 삭제
- External이라 1개, 위험한 상태
- replace +CRS: 다시 3개, FUID 모두 새 값
- 작업 내내 클러스터·DB 정상
- 작업 전후 FUID 기록
@NOTE replace로 +DATA로 옮기면 출력 순서가 중요합니다. 새 위치에 먼저 추가하고 그다음 옛 위치를 삭제합니다. 어느 순간에도 Voting File이 0개가 되지 않아 무중단으로 옮겨집니다. +DATA는 External이라 하나만 생기는데, 이 상태에서는 data1 디스크 하나만 잃어도 클러스터가 내려가므로 바로 되돌립니다. +CRS로 돌아오면 다시 세 개지만 FUID는 모두 새 값입니다. 작업 전후로 FUID를 기록해 두면 실제로 새로 만들어졌는지 확인할 수 있습니다. 그동안 클러스터와 데이터베이스는 그대로 돌았습니다.

@SEC 3.7|디스크를 내려 본다
- compatible.rdbms 함정
- OFFLINE 후 상태
- ONLINE과 새 FUID

@SLIDE compatible.rdbms 함정|ORA-15283, 그리고 한 방향 상향
- offline disk → ORA-15032 + ORA-15283
- +CRS compatible.rdbms = 10.1.0.0.0
- fast mirror resync는 11.1 이상 필요
- 11.2로 상향, 되돌리면 ORA-15244
- 필요한 최소 값만 올린다
@NOTE 디스크를 내리는 표준 명령이 바로 실패합니다. ORA-15032는 포괄 메시지이고 원인은 ORA-15283입니다. +CRS의 compatible.asm은 19이지만 compatible.rdbms는 10.1입니다. 설치 때 이 속성을 지정하지 않으면 가장 낮은 값이 들어갑니다. 디스크 OFFLINE과 ONLINE은 11.1에서 들어온 기능이라 막혀 있었습니다. 11.2로 올리면 통과하는데 이 속성은 올릴 수만 있고 다시 낮추면 ORA-15244가 납니다. +CRS를 다시 만드는 것은 클러스터 재구성이므로 필요한 최소 값만 올립니다.

@IMG 03_offline.png|디스크 OFFLINE과 ONLINE|3개에서 2개로, 다시 새 FUID로 3개
@NOTE CRS_0002를 내리면 그 디스크의 PATH가 비고 VOTING_FILE이 N이 됩니다. ASM이 디스크를 더 이상 열어 두지 않기 때문입니다. 디스크그룹은 MOUNTED 그대로이고 OFFLINE_DISKS가 1이 됩니다. Voting File은 두 개로 줄었지만 셋 중 둘은 과반수라 두 노드와 데이터베이스는 정상입니다. 다시 ONLINE으로 올리면 Voting File이 세 개가 되는데 세 번째의 FUID가 새 값입니다. ASM이 새로 배치했기 때문입니다. 그래서 복구 여부는 FUID가 아니라 개수와 STATE로 판단합니다.

@SLIDE OFFLINE의 흔적|alert.log와 repair timer
- GMON이 PST 갱신: clear mandatory
- voting file relocation이 따로 일어남
- REPAIR_TIMER 0: mandatory 해제 디스크
- ONLINE: assign mandatory, 리밸런스
- 내리기 전: USABLE_FILE_MB, VOTING_FILE, repair time
@NOTE ASM alert.log를 보면 디스크를 내리는 첫 동작으로 GMON이 PST, 즉 파트너 상태 테이블을 갱신하고 clear mandatory가 기록됩니다. 이어서 Voting File 재배치가 필요하다는 메시지와 성공 메시지가 따로 나옵니다. 디스크 OFFLINE과 Voting File 조정이 별개의 단계라는 뜻입니다. 보통 디스크는 repair timer가 줄어드는데 이 디스크는 0에 머뭅니다. 올릴 때는 assign mandatory와 리밸런스가 기록됩니다. 운영에서 디스크를 내리기 전에는 여유 공간, Voting File 여부, repair time을 먼저 확인합니다.

@SEC 3.8|복구 절차
- PROT-19
- 시나리오별 절차
- 배타 모드

@IMG 03_recovery.png|OCR 전체 복원|모든 노드를 내리고 한 노드만 배타 모드로 올려 복원한다
@NOTE 복원 명령은 클러스터가 떠 있으면 PROT-19로 막힙니다. crsd가 OCR을 열어 두고 계속 읽고 쓰는데 그 밑에서 파일을 갈아 끼우면 내용이 어긋나기 때문입니다. 그래서 첫 단계는 모든 노드의 stop crs입니다. 다음으로 한 노드에서만 마이너스 excl 마이너스 nocrs로 기동하면 ASM은 떠서 +CRS를 마운트하지만 crsd는 뜨지 않습니다. 이 상태에서 restore하고 ocrcheck로 ID를 대조합니다. 마지막으로 stop crs 마이너스 f로 배타 모드를 끝내고 모든 노드를 정상 기동합니다.

@SLIDE 시나리오별 절차|Voting File은 replace, OCR은 restore
- OCR 한 위치 손상: -delete 후 -add, 무중단
- OCR 전체 손상: 배타 모드 → -restore
- 한 노드 ocr.loc 불일치: -repair
- Voting File 과반수 손실: 배타 모드 → replace
- OLR 손상: -local -restore 또는 노드 재구축
@NOTE 상황별 절차를 정리하면 패턴이 보입니다. 다중화된 OCR 중 한 위치만 손상되면 클러스터를 내리지 않고 지웠다 다시 추가합니다. OCR 전체가 손상되면 앞 그림의 배타 모드 절차로 restore합니다. 한 노드만 ocr.loc가 어긋났다면 그 노드만 내리고 repair를 씁니다. Voting File 하나를 잃었으면 디스크를 복구해 ONLINE으로 올리면 되고, 과반수를 잃었으면 배타 모드에서 replace합니다. OLR이 손상되면 local restore를 쓰거나 노드를 재구축합니다. 백업 경로는 showbackup 출력을 그대로 복사해 씁니다.

@SLIDE 평상시 점검 항목|복구는 기록에서 시작한다
- 설치 직후·변경 직전: manualbackup + export
- export 파일은 클러스터 밖으로
- ocrcheck ID, votedisk FUID 기록
- showbackup을 주기 점검에
- PROT-24가 계속되면 crsd 재시작 의심
@NOTE 복구가 가능한지는 평소에 무엇을 남겨 두었는지로 정해집니다. 설치 직후와 구성 변경 직전에는 manualbackup과 export를 함께 실행하고, export 파일은 클러스터 밖으로 복사합니다. ocrcheck의 ID와 query css votedisk의 FUID 목록을 작업 기록에 적어 두면 복구 뒤에 대조할 기준이 됩니다. showbackup은 주기 점검 항목에 넣습니다. 몇 주가 지나도 PROT-24가 계속 나온다면 crsd가 자주 재시작되고 있다는 신호이므로 그 원인부터 조사합니다.

@PLAIN 요약
- OCR은 +CRS의 공유 레지스트리, OLR은 노드 로컬
- 설치 직후 OCR 백업 없음, 자동 백업은 4시간 연속 가동
- 백업은 root만, 마스터 노드가 +CRS에, 로컬은 PROT-42
- OCR 다중화는 5곳까지, 마지막 한 벌은 PROT-28
- Voting File 수는 이중화가 정하고 replace만 가능
- 복원은 PROT-19 때문에 배타 모드에서

@PLAIN 퀴즈
- 1. 작업 전후 ocrcheck ID가 바뀌면 무엇을 의심하는가?
- 2. 하루가 지나도 PROT-24가 나오는 원인은?
- 3. rac1에서 백업했는데 rac2가 찍힌 이유는?
- 4. 로컬 디렉터리가 PROT-42로 거절되는 이유는?
- 5. 디스크 하나를 내려도 클러스터가 도는 이유는?
- 6. restore가 PROT-19로 막히면 다음 단계는?

@PLAIN 실습 개요
- 05-01  현재 구성 확인  /  05-02  백업 상태 진단
- 05-03  수동 백업과 내보내기
- 05-05 ★  Voting File 재배치
- 05-06 ★⚠  디스크 강제 OFFLINE (공유 디스크 사본 필수)
- 파일: RAC/05장/5장_실습_NN_*.txt
