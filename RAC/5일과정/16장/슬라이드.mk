@TITLE Oracle Database 19c RAC 과정|RAC One Node|인스턴스 하나를 노드 사이로 옮겨 다니는 RAC|제16장

@PLAIN 학습 목표
- 단일 인스턴스·RAC One Node·RAC 를 구분한다
- 변환의 두 조건과 PRCD-1214·1242 를 설명한다
- remove instance 와 dbca -deleteInstance 를 구분한다
- 온라인 재배치 단계와 서비스 이동 시점을 말한다
- 인스턴스 이름 변화와 ORA-01034 를 다룬다
- RAC 로 되돌리고 인스턴스 이름을 원복한다

@PLAIN Agenda
- 16.2  RAC One Node 란
- 16.3  RAC 를 RAC One Node 로 변환
- 16.4  온라인 재배치
- 16.5  재배치 중에 다른 명령을 내면
- 16.6  RAC 로 되돌리기
- 16.7  RAC 와 RAC One Node 사이의 선택

@SEC 16.2|RAC One Node 란
- 세 가지 구성
- 언제 쓰는가
- 지금의 구성과 명령

@IMG 16_compare.png|세 가지 구성|단일 인스턴스, RAC One Node, RAC
@NOTE 세 구성을 나란히 놓았습니다. 단일 인스턴스는 노드 하나에 인스턴스 하나라 노드가 멈추면 데이터베이스도 멈춥니다. RAC는 노드마다 인스턴스가 있어 하나가 멈춰도 나머지가 계속 서비스합니다. RAC One Node는 그 중간입니다. 공유 스토리지, Clusterware, ASM, 스레드와 UNDO 분리는 RAC와 똑같이 쓰면서 평소에는 인스턴스 하나만 엽니다. 대신 그 인스턴스를 다른 후보 노드로 옮길 수 있습니다. 15장에서 노드를 지운 뒤의 상태는 옮길 기능도 노드도 없는 인스턴스 하나짜리 RAC였습니다.

@SLIDE 언제 쓰는가|유지보수 중단은 피하고 CPU 는 한 노드로 충분할 때
- 패치·점검 전에 다른 노드로 옮겨 두고 작업
- 여러 데이터베이스를 노드마다 하나씩 배치
- 부하 분산이 필요하면 RAC
- 노드 장애 땐 재기동 시간만큼 멈춘다
- 별도 라이선스 옵션 — 계약 확인
@NOTE RAC One Node가 어울리는 곳은 데이터베이스 하나에 CPU가 많이 필요하지는 않지만 노드 유지보수 때 멈추면 곤란한 경우입니다. 패치 전에 데이터베이스를 다른 노드로 옮겨 두고 작업합니다. 여러 데이터베이스를 한 클러스터에 모아 노드마다 하나씩 두는 통합 환경에도 씁니다. 반대로 부하를 두 노드에 나눠야 하거나, 노드 장애 순간에도 접속이 이어져야 한다면 RAC입니다. RAC One Node는 장애 때 다른 노드에서 다시 띄우는 동안 멈춥니다. 라이선스는 별도 옵션이니 계약을 먼저 확인합니다.

@SLIDE 지금의 구성|Type RAC, 인스턴스 둘, 서비스 없음
- srvctl config database: administrator managed
- SPFILE 항목이 racdb1·racdb2 sid 에 묶여 있다
- 변환은 OCR 자원 정의를 바꾼다
- 시작 전 ocrconfig -manualbackup
@NOTE 출발점을 확인합니다. srvctl config database를 보면 유형은 RAC, 인스턴스는 둘, srvctl에 등록된 서비스는 없고 관리자 관리형입니다. 관리자 관리형은 인스턴스와 노드를 이름으로 묶는 방식이라 RAC One Node로 바꿀 때 인스턴스 이름 접두어를 반드시 줘야 합니다. v spparameter를 보면 인스턴스 번호, 스레드, UNDO가 racdb1과 racdb2라는 이름에 묶여 있습니다. 이 장에서 인스턴스 이름이 바뀔 때 이 항목들이 어떻게 되는지 지켜보십시오. 변환은 OCR을 바꾸므로 수동 백업을 먼저 뜹니다.

@SLIDE 명령 미리 읽기|convert 와 relocate
- convert -dbtype RACONENODE -instance 접두어 -timeout 분
- 대상은 "인스턴스가 하나인 RAC"
- relocate database 에는 -abort, -revert
- 일반 RAC 에 relocate → PRCD-1146
@NOTE 실행하기 전에 help를 읽어 두면 조건이 보입니다. convert database의 사용법에는 인스턴스가 하나인 RAC를 RAC One Node로 바꾼다고 적혀 있습니다. instance 옵션은 인스턴스 이름이 아니라 접두어이고, timeout은 재배치 때 옛 인스턴스가 내려가기를 기다리는 상한으로 단위는 분입니다. relocate database에 abort와 revert가 있다는 것은 재배치가 중간에 실패할 수 있다는 뜻입니다. 일반 RAC에 relocate를 치면 PRCD-1146으로 바로 거부됩니다. 서비스 재배치와 이름이 비슷하니 구분하십시오.

@SEC 16.3|RAC 를 RAC One Node 로 변환
- 인스턴스가 하나여야 한다
- 서비스가 있어야 한다
- 변환과 이름 어긋남

@IMG 16_convert.png|변환의 두 조건|PRCD-1214 와 PRCD-1242
@NOTE 변환은 두 번 거부된 뒤에 성공합니다. 처음에는 인스턴스가 둘이라 PRCD-1214가 납니다. 무엇을 남길지는 관리자가 정해야 하므로 racdb2를 정지하고 등록을 해제합니다. 다시 시도하면 이번에는 서비스가 없다는 PRCD-1242가 납니다. 재배치는 서비스를 새 인스턴스로 옮기는 일이라 서비스 없이는 의미가 없기 때문입니다. ronsvc 서비스를 만들고 시작한 뒤 변환하면 성공합니다. 아래 상자의 차이, 즉 등록만 해제하는 것과 dbca로 구조까지 지우는 것의 차이가 다음 절에서 중요해집니다.

@SLIDE 인스턴스 줄이기|srvctl remove instance 를 쓴다
- srvctl stop instance → remove instance -noprompt
- CRS 등록만 해제, thread 2 · UNDOTBS2 는 남는다
- dbca -deleteInstance 는 스레드·UNDO 까지 삭제
- 남긴 자리를 재배치된 인스턴스가 쓴다
@NOTE 인스턴스를 하나로 줄일 때 15장처럼 dbca deleteInstance를 쓰지 않고 srvctl remove instance를 씁니다. srvctl은 CRS 등록만 해제하고 데이터베이스 안의 thread 2, 리두 그룹, UNDOTBS2는 그대로 둡니다. dbca는 이것들까지 지웁니다. 15장은 노드 자체를 없애는 것이 목적이었으니 dbca가 맞았고, 여기서는 나중에 rac2로 옮긴 인스턴스가 thread 2와 UNDOTBS2를 써야 하므로 남겨 둡니다. 같은 인스턴스 삭제처럼 보여도 목적에 따라 명령을 고릅니다.

@SLIDE 변환 결과|몇 초, 데이터베이스는 멈추지 않는다
- Type RACOneNode, Candidate servers rac1
- Online relocation timeout 30, prefix racdb
- 상태에 Online relocation: INACTIVE
- SPFILE · 암호 파일 · 디스크그룹은 그대로
@NOTE 변환 명령은 몇 초 만에 출력 없이 끝나고 데이터베이스는 멈추지 않습니다. 바뀐 것은 OCR의 자원 정의뿐입니다. config를 보면 유형이 RACOneNode로 바뀌고, 재배치 시간 제한과 접두어, 후보 서버 줄이 새로 생깁니다. Configured nodes가 Candidate servers로 이름이 바뀐 것도 의미가 있습니다. 이 노드들에서 돈다는 뜻에서 이 노드들 중 하나에서 돈다는 뜻으로 바뀐 것입니다. 상태 출력에는 Online relocation 줄이 생기는데 평소에는 INACTIVE이고 재배치 중에만 ACTIVE입니다.

@SLIDE 구성과 실제 이름의 어긋남|구성은 racdb_1, 실제는 racdb1
- RAC One Node 는 이름을 접두어_번호로 짓는다
- 변환은 구성만 바꾸고 인스턴스를 재기동하지 않는다
- 오류가 아니다 — 다음 기동 때 구성 이름을 따른다
- config 와 status 를 함께 봐야 보인다
@NOTE 변환 직후 config는 인스턴스를 racdb_1이라고 하는데 status는 racdb1이 돈다고 합니다. RAC One Node는 인스턴스 이름을 접두어, 밑줄, 번호로 짓습니다. 변환은 구성만 바꾸고 돌고 있는 인스턴스를 다시 띄우지 않으므로 실제 인스턴스는 옛 이름 그대로입니다. 오류가 아니고, 다음에 인스턴스가 새로 뜰 때 구성의 이름을 따릅니다. 재배치가 그 시점입니다. 이런 어긋남은 오류 메시지 없이 지나가므로 config와 status를 항상 함께 보는 습관이 필요합니다.

@SEC 16.4|온라인 재배치
- 후보 서버와 재배치 순서
- 시간이 드는 곳
- ORA-01034 와 스레드·UNDO

@SLIDE 후보 서버|목록을 넣지 말고 relocate -node 로
- modify database -node rac1,rac2 → PRKF-1125
- -node 는 값 하나만 받는다
- 후보에 없는 노드로 relocate 하면 자동 추가
- 출력 첫 줄: Added target node rac2
@NOTE 후보 서버 줄이 쉼표 목록이라 rac1과 rac2를 한 번에 넣고 싶어지지만 modify database의 node 옵션은 값 하나만 받아서 PRKF-1125가 납니다. 관리자 관리형 RAC One Node는 후보에 없는 노드로 재배치하면 그 노드를 후보에 추가합니다. 그래서 relocate의 node 옵션으로 대상 노드를 직접 줍니다. 재배치 출력의 첫 줄이 바로 rac2를 대상 노드로 추가했다는 메시지입니다. 재배치가 끝나면 후보 서버가 rac1, rac2 두 개가 됩니다.

@IMG 16_relocate.png|온라인 재배치|새 인스턴스가 열린 뒤 서비스 이동
@NOTE 재배치 과정을 시간 순서로 그린 그림입니다. relocate verbose 출력이 단계를 순서대로 보여 줍니다. 대상 노드를 추가하고, 구성을 인스턴스 둘로 바꾸고, rac2에 racdb_2를 띄웁니다. 새 인스턴스가 PDB까지 완전히 열린 뒤에 서비스를 옮기므로 서비스로 접속하는 클라이언트는 갈 곳이 없어지는 순간이 없습니다. 그다음 옛 인스턴스를 transactional local로 내리고 구성을 인스턴스 하나로 돌립니다. 잠깐 두 인스턴스가 함께 열리는 구간이 있는데, 그 순간 racdb는 RAC입니다.

@SLIDE 시간이 드는 곳|옛 인스턴스를 내리는 쪽이 길다
- 전체 99.5초, 되돌아올 때 85.9초
- 새 인스턴스 기동~PDB 23초
- 옛 인스턴스 정지 62초 (transactional local)
- 대기 상한 -timeout → _shutdown_completion_timeout_mins
@NOTE 실습 기록으로 보면 rac2로의 재배치는 99.5초, rac1로 돌아오는 재배치는 85.9초가 걸렸습니다. 알럿 로그를 맞춰 보면 새 인스턴스가 기동해 PDB까지 여는 데 23초, 옛 인스턴스가 정지를 시작해 끝내는 데 62초였습니다. 시간 대부분이 옛 인스턴스를 내리는 쪽입니다. 정지 방식이 transactional local이라 진행 중 트랜잭션을 기다리고, 그 상한이 변환 때 준 timeout입니다. 알럿 로그에 숨은 파라미터로 그 값이 들어가는 것이 보입니다. 사용자 세션이 많으면 더 길어집니다.

@SLIDE 재배치 뒤 ORA-01034|ORACLE_SID 는 racdb2, 인스턴스는 racdb_2
- sqlplus / as sysdba → ORA-01034
- ps -ef | grep pmon → ora_pmon_racdb_2
- export ORACLE_SID=racdb_2 후 접속
- 운영은 이름에 기대지 말고 서비스로
@NOTE 재배치 뒤 rac2에서 sysdba로 붙으면 ORA-01034, 오라클을 쓸 수 없다는 오류가 납니다. 데이터베이스는 rac2에서 열려 있는데도 그렇습니다. 프로필의 ORACLE_SID는 racdb2인데 실제 인스턴스 이름은 racdb_2이기 때문입니다. sysdba 로컬 접속은 ORACLE_SID로 인스턴스를 찾습니다. pmon 프로세스 이름으로 지금 이름을 확인하고 ORACLE_SID를 맞추면 붙습니다. RAC One Node에서는 이름이 재배치마다 바뀌니, 애플리케이션과 사용자는 반드시 서비스 이름으로 접속하게 합니다.

@SLIDE 스레드와 UNDO 는 어떻게 잡혔나|비어 있는 것을 잡는다
- SPFILE 에 racdb_2 전용 항목은 없다
- 그래도 racdb_2 는 thread 2 · UNDOTBS2
- 쓰이지 않는 스레드와 UNDO 를 잡는 규칙
- remove instance 로 남겨 둔 덕분
@NOTE racdb_2로 붙어서 보면 thread 2와 UNDOTBS2를 쓰고 있습니다. 그런데 SPFILE에는 racdb_2 전용 항목이 없습니다. 인스턴스별 지정이 없으면 인스턴스는 다른 인스턴스가 쓰지 않는 열린 스레드와 UNDO 테이블스페이스를 잡습니다. 재배치 순간에 racdb1이 thread 1과 UNDOTBS1을 쓰고 있었으니 남은 것이 thread 2와 UNDOTBS2였습니다. 앞에서 dbca 대신 srvctl remove instance로 등록만 해제한 이유가 여기서 드러납니다. dbca로 지웠다면 잡을 스레드가 없었습니다.

@SEC 16.5|재배치 중에 다른 명령을 내면
- 막히는 명령
- 통하는 명령과 위험

@IMG 16_blocked.png|재배치 중 명령|막히는 것과 통하는 것
@NOTE 세션 A에서 rac1로 되돌리는 재배치를 걸어 두고 세션 B에서 명령을 내 봅니다. 상태 조회는 됩니다. 같은 데이터베이스를 또 재배치하면 PRCD-1161과 PRCD-1164가 나는데, 원인은 아래 줄의 이미 진행 중이라는 메시지입니다. 위 줄만 보고 세션 A가 실패했다고 오해하지 마십시오. 정지는 PRKO-2143으로 막힙니다. 그런데 timeout을 바꾸는 modify는 통하고, 진행 중인 재배치의 대기 문구가 30분에서 10분으로 바로 바뀝니다. 남의 작업을 바꿀 수 있으니 재배치 중에는 modify도 하지 않는 규칙을 둡니다.

@SLIDE 재배치가 실패했을 때|ACTIVE 인지 FAILED 인지 먼저 본다
- srvctl status database -v 로 상태 구분
- ACTIVE → timeout 까지 기다린다
- FAILED → relocate -abort
- 관리자 관리형은 -revert 로 대상 노드를 후보에서 제거
@NOTE 대상 노드에서 인스턴스가 뜨지 않거나 서비스 이동이 실패하면 재배치가 FAILED 상태로 남을 수 있습니다. 실습에서는 재현하지 않았지만 대응 순서는 정해 둡니다. 먼저 status database verbose로 ACTIVE인지 FAILED인지 구분합니다. ACTIVE라면 진행 중이니 timeout까지 기다립니다. FAILED라면 relocate abort로 실패한 재배치를 정리하고, 관리자 관리형이면 revert를 함께 주어 실패한 대상 노드를 후보 목록에서 뺍니다. 정리하기 전에는 정지 명령도 막힐 수 있습니다.

@SEC 16.6|RAC 로 되돌리기
- 변환과 이름 섞임
- PRKO-3147 과 이름 원복
- 기준선

@SLIDE RAC 로 변환|몇 초, 이름은 racdb_1 그대로
- convert -dbtype RAC -node rac1
- 접두어·후보 서버·timeout 줄이 사라진다
- 결과는 인스턴스 하나인 RAC (racdb_1)
- racdb2 만 붙이면 racdb2, racdb_1 이 섞인다
@NOTE 실습 05는 rac1로 돌아온 상태에서 시작합니다. convert dbtype RAC로 되돌리면 몇 초 만에 끝나고 데이터베이스는 멈추지 않습니다. 접두어와 후보 서버, 재배치 시간 제한 줄이 사라지고 인스턴스 하나짜리 RAC가 됩니다. 그런데 인스턴스 이름은 racdb_1 그대로입니다. 여기서 racdb2만 추가하면 등록은 되지만 racdb2와 racdb_1이 섞입니다. SPFILE의 racdb1 항목은 racdb_1에 적용되지 않으니, 기동 순서에 따라 스레드와 UNDO가 바뀔 수 있습니다. 이름을 원래대로 돌려야 합니다.

@SLIDE PRKO-3147 과 이름 원복|서비스를 먼저 지우고 DB 를 한 번 내린다
- remove instance racdb_1 → PRKO-3147 (유일한 선호 인스턴스)
- ronsvc 정지·삭제
- stop database → remove racdb_1 → add racdb1 -node rac1
- start database 로 racdb1 · racdb2 함께 기동
@NOTE racdb_1의 등록을 해제하려 하면 PRKO-3147이 납니다. ronsvc의 선호 인스턴스가 재배치를 따라 racdb_1로 바뀌어 있었고, 유일한 선호 인스턴스를 지우면 서비스가 갈 곳이 없어지기 때문입니다. ronsvc는 변환 조건을 맞추려고 만든 것이니 먼저 지웁니다. 인스턴스 이름은 실행 중에 바꿀 수 없으므로 데이터베이스를 한 번 내리고, racdb_1을 해제한 뒤 racdb1을 rac1에 등록합니다. 다시 올리면 SPFILE의 인스턴스별 항목이 적용되어 스레드와 UNDO가 이름에 고정됩니다.

@IMG 16_names.png|인스턴스 이름의 변화|구성과 실제가 어긋난 두 구간
@NOTE 이 장 전체에서 인스턴스 이름이 어떻게 바뀌었는지 정리한 그림입니다. 이름은 접두어 racdb에 밑줄 1, 밑줄 2를 번갈아 붙이고, 재배치할 때마다 지금 쓰지 않는 번호를 새 인스턴스에 줍니다. 빨간 두 줄이 구성과 실제가 어긋난 구간입니다. 변환 직후와 racdb2만 붙였을 때인데, 둘 다 오류 메시지 없이 지나갔습니다. 마지막에 이름을 원복하자 기준선과 같아졌고, 진단 디렉터리 racdb_1과 racdb_2만 기록으로 남았습니다. OCR 수동 백업은 쓰지 않았습니다.

@SEC 16.7|RAC 와 RAC One Node 사이의 선택
- 상황별 권장
- 점검 항목

@SLIDE 어떤 데이터베이스를 One Node 로|이름에 기대는 스크립트를 먼저 찾는다
- 한 노드 CPU 로 충분 + 유지보수 중단 회피 → One Node
- 부하 분산, 장애 순간 연속성 → RAC
- 변환은 가볍고 이름 원복은 무겁다
- grep -r racdb1 로 이름 쓰는 곳 점검
@NOTE 정리하면 한 노드의 CPU로 충분하고 유지보수 때 멈추지 않기를 원하면 RAC One Node, 부하를 나눠야 하거나 노드 장애 순간에도 접속이 이어져야 하면 RAC입니다. 변환 자체는 두 방향 모두 몇 초였고 데이터베이스를 멈추지 않았습니다. 시간이 든 것은 변환 앞뒤의 인스턴스 정리와 이름 원복이었습니다. 가장 조심할 것은 인스턴스 이름에 기대는 스크립트입니다. 백업 스크립트, 모니터링, cron 작업을 미리 찾아 서비스 이름이나 pmon 기준으로 고쳐 두어야 합니다.

@PLAIN 요약
- One Node 는 RAC 구조를 쓰고 인스턴스는 하나
- 조건: 인스턴스 하나(PRCD-1214), 서비스(PRCD-1242)
- remove instance 로 스레드·UNDO 를 남긴다
- 재배치: 새 인스턴스 → 서비스 이동 → 옛 인스턴스 정지
- 이름은 접두어_번호, 운영은 서비스로 접속
- 되돌린 뒤 서비스 삭제, DB 정지 후 이름 원복

@PLAIN 퀴즈
- 1. 세 구성을 인스턴스 수와 장애 시 동작으로 구분하면?
- 2. 변환의 두 조건과 각 오류 번호는?
- 3. srvctl remove instance 를 쓴 이유는?
- 4. 재배치에서 서비스가 옮겨지는 시점과 이점은?
- 5. 재배치 뒤 ORA-01034 의 이유와 조치는?
- 6. 재배치 중 막히는 명령과 통하는 명령은?

@PLAIN 실습 개요
- 01  개념과 구성 확인 — OCR 수동 백업 먼저
- 02 ★  RAC 를 RAC One Node 로 변환
- 03 ★  온라인 재배치와 소요 시간, ORA-01034
- 05 ★  RAC 로 되돌리고 인스턴스 이름 원복
- 05 전에 relocate -node rac1 로 되돌려 둔다
- 파일: RAC/19장/19장_실습_NN_*.txt
