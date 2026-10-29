@TITLE Oracle Database 19c RAC 과정|인스턴스와 클러스터 DB 관리|구성 확인, 기동·정지, 파라미터, PDB|제9장

@PLAIN 학습 목표
- srvctl config database 출력을 읽는다
- 인스턴스별 스레드·UNDO 배정을 확인한다
- PDB를 두 인스턴스에서 열고 상태를 저장한다
- 종료 방식에 따른 Clusterware 반응을 설명한다
- 파라미터 세 분류와 sid= 지정의 위험을 안다
- RESET으로 SPFILE을 기준선으로 되돌린다

@PLAIN Agenda
- 9.2  생성된 RAC DB의 구성 확인
- 9.3  srvctl · crsctl · SQL*Plus
- 9.4  SPFILE의 sid.parameter 표기
- 9.5  같아야 할 것을 한쪽만 바꾸면
- 9.6  PDB를 노드별로 열고 닫기
- 9.7  운영 지침

@SEC 9.2|생성된 RAC DB의 구성 확인
- srvctl config database
- 인스턴스·스레드·UNDO
- PDB OPEN과 SAVE STATE

@IMG 09_config.png|srvctl config database 읽기|Clusterware에 저장된 racdb의 정의
@NOTE racdb는 설치 가이드 9장에서 DBCA로 만들었습니다. 만들어진 데이터베이스가 Clusterware에 어떻게 등록되었는지는 srvctl config database로 봅니다. 이 출력은 Clusterware 안에 저장된 정의라서 데이터베이스가 내려가 있어도 남습니다. 그림처럼 줄마다 의미가 있습니다. SPFILE과 암호 파일 위치, 옵션 없이 기동하고 정지할 때의 기본 동작, 노드 부팅 때 자동으로 올릴지 정하는 정책, 시작 전에 마운트되어야 하는 디스크그룹, 그리고 어느 노드에 어느 인스턴스가 있는지가 들어 있습니다.

@SLIDE 출력에서 읽을 줄|기본 동작과 배치
- Start options open / Stop options immediate
- Management policy AUTOMATIC: 부팅 때 자동 기동
- Disk Groups DATA,FRA: 시작 의존성
- racdb1@rac1, racdb2@rac2, administrator managed
@NOTE 몇 줄을 짚어 보겠습니다. Start options가 open이고 Stop options가 immediate이므로 srvctl stop database를 옵션 없이 실행하면 shutdown immediate가 수행됩니다. Management policy가 AUTOMATIC이면 노드가 부팅될 때 Clusterware가 데이터베이스를 자동으로 올립니다. Disk Groups 줄은 시작 의존성이어서 DATA와 FRA가 마운트되어야 인스턴스가 뜹니다. 마지막으로 인스턴스와 노드 목록, 관리자 관리형이라는 줄이 racdb1은 rac1, racdb2는 rac2에 고정된다는 것을 말해 줍니다.

@IMG 09_layout.png|인스턴스마다 따로 가지는 것|번호, 리두 스레드, UNDO
@NOTE 데이터 파일과 컨트롤 파일은 한 벌이지만 인스턴스마다 반드시 따로 가져야 하는 것이 셋 있습니다. 인스턴스를 구분하는 instance number, 자기만 쓰는 리두 스레드, 자기만 쓰는 UNDO 테이블스페이스입니다. racdb1은 1번, 스레드 1, UNDOTBS1이고 racdb2는 2번, 스레드 2, UNDOTBS2입니다. 스레드 1에는 리두 그룹 1과 2가, 스레드 2에는 3과 4가 있습니다. 이 파일들도 모두 공유 디스크그룹에 있기 때문에 한 인스턴스가 죽으면 다른 인스턴스가 읽어 복구할 수 있습니다.

@SLIDE 스레드와 UNDO 확인|조회 네 개로 RAC임을 증명한다
- GV$INSTANCE: 서로 다른 노드, THREAD# 1·2
- V$LOG: 스레드마다 그룹 2개, CURRENT 하나씩
- UNDO 테이블스페이스 2개
- GV$PARAMETER: undo_tablespace가 인스턴스마다 다름
@NOTE 생성된 데이터베이스가 정말 RAC인지는 몇 가지 조회로 확인합니다. GV instance에서 두 인스턴스가 서로 다른 노드에 있고 스레드 번호가 다른지 봅니다. v log에서는 스레드마다 리두 그룹이 두 개씩 있고 각각 CURRENT가 하나씩 있어서 인스턴스가 독립적으로 로그 스위치를 한다는 것을 봅니다. UNDO 테이블스페이스가 인스턴스 수만큼 있고 파라미터로 각각 다르게 배정되었는지도 확인합니다. 단일 인스턴스라면 스레드도 UNDO도 하나뿐입니다.

@SLIDE PDB OPEN과 SAVE STATE|DBCA는 저장하지 않는다
- 생성 직후 DBA_PDB_SAVED_STATES 0행
- 재기동하면 PDB가 두 노드 모두 MOUNTED
- OPEN INSTANCES=ALL + SAVE STATE INSTANCES=ALL
- 저장 상태도 인스턴스마다 한 행
@NOTE DBCA는 PDB를 열어 두기는 하지만 그 상태를 저장하지 않습니다. 실습 기록에서 DBCA로 만든 testdb를 내렸다 올렸더니 CDB는 열렸는데 PDB는 두 노드 모두 MOUNTED로 남았습니다. 데이터베이스는 Open이라고 나오고 리스너도 정상인데 애플리케이션은 접속에 실패하는 상황입니다. 그래서 생성 직후 OPEN INSTANCES ALL과 SAVE STATE INSTANCES ALL을 실행합니다. 저장 상태도 인스턴스별로 기록되므로 INSTANCES ALL을 빼면 한 노드에만 저장됩니다. racdb는 설치 때 이미 해 두었습니다.

@SEC 9.3|srvctl · crsctl · SQL*Plus
- start와 stop의 옵션
- TARGET과 STATE
- 정상 종료와 비정상 종료

@SLIDE start와 stop의 옵션|SQL*Plus 인자에 RAC 옵션이 더해진다
- -startoption / -stopoption: startup·shutdown 인자
- -start/-stopconcurrency: 동시 처리 인스턴스 수
- -drain_timeout: 서비스 세션이 빠질 시간
- -eval로 영향 확인, -force는 stop에만
@NOTE srvctl start와 stop의 도움말을 비교하면 설계 의도가 보입니다. startoption과 stopoption은 SQL Plus의 startup, shutdown 인자를 그대로 받습니다. srvctl이 결국 그 명령을 대신 실행하는 것입니다. 여기에 RAC 전용 옵션이 붙습니다. concurrency는 몇 개 인스턴스를 동시에 처리할지 정하는데 자원이 빠듯한 이 랩에서는 1로 순차 처리하는 편이 안전합니다. drain timeout은 12장 서비스와 함께 씁니다. eval은 실제로 실행하지 않고 영향만 계산하며, force는 의존 자원까지 함께 내리는 정지 전용 옵션입니다.

@SLIDE TARGET과 STATE|무엇을 유지하려 하는가, 지금은 어떤가
- srvctl stop instance racdb2 → 데이터베이스는 계속 열림
- crsctl stat res: 2번 OFFLINE OFFLINE
- srvctl stop은 TARGET도 OFFLINE으로
- 정지 약 50초, 기동 약 40초
@NOTE srvctl stop instance로 racdb2만 내려 봅니다. 데이터베이스는 계속 열려 있고 내려간 것은 인스턴스 하나뿐입니다. crsctl로 자원을 보면 2번 인스턴스가 OFFLINE OFFLINE으로 나옵니다. 앞의 것이 TARGET, 즉 Clusterware가 유지하려는 상태이고 뒤의 것이 STATE, 지금 실제 상태입니다. srvctl stop은 둘을 함께 OFFLINE으로 만들기 때문에 Clusterware는 사람이 의도적으로 내렸다고 보고 다시 올리지 않습니다. 이 랩에서 정지는 50초, 기동은 40초 남짓 걸렸습니다.

@IMG 09_target.png|종료 방식과 Clusterware의 반응|정상 종료면 그대로, 비정상 종료면 다시 올린다
@NOTE 그렇다면 SQL Plus로 shutdown immediate를 하면 어떻게 될까요. Clusterware가 모르니 다시 올릴 것 같지만, 100초 동안 지켜봐도 올라오지 않았습니다. 에이전트가 정상 종료를 감지해 TARGET도 OFFLINE으로 바꿨기 때문입니다. 반면 pmon 프로세스를 kill로 죽이면 TARGET이 ONLINE으로 남습니다. TARGET과 STATE가 어긋나니 Clusterware는 장애로 판단하고, 20초 시점에 이미 기동을 시작해 61초 만에 인스턴스를 다시 올렸습니다. Clusterware가 보는 것은 도구가 아니라 종료 방식입니다.

@SLIDE 재시작 규칙|몇 번까지, 언제 잊는가
- RESTART_ATTEMPTS=2: 두 번까지 다시 올림
- 모두 실패하면 OFFLINE으로 둠
- UPTIME_THRESHOLD=1h: 1시간 정상이면 이력 초기화
- crsctl stat res ora.racdb.db -p로 확인
@NOTE Clusterware가 몇 번이나 다시 올려 보는지는 자원 속성에 있습니다. crsctl stat res에 p 옵션을 주면 속성 전체가 나오는데 RESTART ATTEMPTS가 2입니다. 두 번까지 다시 올려 보고 모두 실패하면 포기하고 OFFLINE으로 둡니다. UPTIME THRESHOLD는 1시간인데, 한 시간 이상 정상으로 돌면 그동안의 실패 횟수를 잊습니다. 그래서 하루에 한 번씩 죽는 인스턴스는 매번 두 번의 기회를 다시 받습니다. 파라미터가 잘못되어 기동이 안 되는 경우에는 두 번 실패하고 멈춥니다.

@SLIDE 그래도 srvctl을 쓰는 이유|정지와 기동은 같은 도구로
- 의존 자원(서비스)을 순서대로 처리
- 어느 노드에서든 실행 가능
- -stopconcurrency, -drain_timeout
- srvctl로 내린 인스턴스는 재부팅해도 안 올라옴
@NOTE 정상 종료라면 SQL Plus로 내려도 Clusterware가 다시 올리지 않는다는 것을 확인했습니다. 그래도 운영 작업은 srvctl로 합니다. 서비스 같은 의존 자원을 순서대로 처리하고, 어느 노드에서든 실행할 수 있고, RAC 전용 옵션을 쓸 수 있기 때문입니다. 반대로 알아 둘 점도 있습니다. srvctl로 내린 인스턴스는 TARGET이 OFFLINE으로 저장되어 노드를 재부팅해도 올라오지 않습니다. 재부팅했는데 왜 안 올라오느냐는 문의가 이 때문입니다. 올릴 때도 srvctl로 올립니다.

@SEC 9.4|SPFILE의 sid.parameter 표기
- * 와 인스턴스 이름
- 기준선 24 / 3 / 3
- 세 분류

@SLIDE * 와 인스턴스 이름|인스턴스별 값이 우선한다
- *.open_cursors=300: 모든 인스턴스
- racdb1.thread=1: 그 인스턴스만
- 공통 24, racdb1 3, racdb2 3
- 인스턴스별 셋: instance_number, thread, undo_tablespace
@NOTE RAC의 SPFILE에는 파라미터마다 적용 대상이 붙습니다. 별표는 모든 인스턴스, 인스턴스 이름은 그 인스턴스에만 적용되고, 둘이 함께 있으면 인스턴스별 값이 우선합니다. v spparameter를 SID로 묶어 세면 공통 24개, 인스턴스별 3개씩이 나옵니다. 이 세 숫자가 이 랩의 기준선입니다. 인스턴스별로 지정된 것은 instance number, thread, undo tablespace 셋뿐이고 모두 달라야만 하는 값입니다. instance name은 SPFILE에 없지만 ORACLE SID로 정해져 인스턴스마다 다릅니다.

@IMG 09_params.png|파라미터 세 분류|같아야 하는 것 중 일부만 Oracle이 막는다
@NOTE 파라미터를 세 가지로 나누면 관리 원칙이 분명해집니다. db name, db block size, control files, cluster database, compatible은 반드시 같아야 합니다. 다르면 같은 데이터베이스로 동작할 수 없습니다. instance number, thread, undo tablespace는 반드시 달라야 합니다. 같으면 두 인스턴스가 충돌합니다. sga target, processes, open cursors 같은 나머지는 달라도 동작하지만 같게 두는 것이 권장됩니다. 그림 아래쪽은 첫 번째 분류 가운데 Oracle이 막아 주는 것과 그대로 통과시키는 것을 나눠 보여 줍니다.

@SEC 9.5|같아야 할 것을 한쪽만 바꾸면
- ORA-32016으로 막히는 것
- 경고 없이 통과하는 것
- RESET으로 되돌리기

@SLIDE 막는 경우|생성 때 확정된 값
- db_block_size=16384 sid='racdb1' scope=spfile
- db_name='xxx' sid='racdb1' scope=spfile
- ORA-32017 / ORA-32016
- 인스턴스별 지정 이전에 변경 자체가 불가
@NOTE 반드시 같아야 하는 파라미터를 한 인스턴스에만 다르게 지정해 봅니다. 모두 scope spfile이라 지금 돌고 있는 인스턴스에는 영향이 없습니다. db block size와 db name을 racdb1에만 바꾸려 하면 ORA-32017과 ORA-32016이 나며 거부됩니다. 이 두 값은 데이터베이스를 만들 때 확정되어 이후 어떤 방법으로도 바꿀 수 없기 때문에, 인스턴스별 지정 이전에 변경 자체가 막혀 있습니다. 여기까지 보면 Oracle이 알아서 막아 주는구나 하고 안심하게 됩니다.

@SLIDE 막지 않는 경우|명령은 맞고 상황이 틀렸다
- cluster_database=false sid='racdb1' → 통과
- control_files='+DATA/x' sid='racdb1' → 통과
- 다음 기동: MOUNT 실패, 고쳐도 배타 열기 실패
- 정당한 용도가 있어 도구는 막지 못함
@NOTE 같은 분류의 cluster database와 control files는 아무 경고 없이 통과하고 SPFILE에 racdb1 전용 항목이 생깁니다. 다음에 racdb1을 기동하면 없는 경로의 컨트롤 파일을 찾다가 MOUNT에서 실패합니다. 그것을 고쳐도 cluster database가 FALSE인 racdb1은 데이터베이스를 혼자 열려다 racdb2 때문에 실패합니다. 명령을 내린 순간에는 아무 일도 없고 다음 재기동에서 드러난다는 점이 위험합니다. 막지 않는 이유는 업그레이드나 8장의 컨트롤 파일 이동처럼 정당한 용도가 있기 때문입니다.

@SLIDE RESET으로 되돌리기|값을 다시 쓰지 않고 항목을 지운다
- alter system reset cluster_database sid='racdb1' scope=spfile
- 항목이 사라지면 * 값이 다시 적용
- 24 / 3 / 3 복귀로 확인
- open_cursors 같은 권장 분류도 실습 뒤 RESET
@NOTE 잘못 넣은 인스턴스별 값은 ALTER SYSTEM RESET으로 지웁니다. RESET은 값을 원래대로 다시 쓰는 것이 아니라 그 항목을 SPFILE에서 없애서 상위인 별표 값이 다시 적용되게 합니다. 값을 다시 쓰는 방식으로 되돌리면 인스턴스별 항목이 남아 있어서 나중에 별표 값을 바꿔도 그 인스턴스에는 반영되지 않습니다. RESET 뒤에는 v spparameter를 다시 세어 24, 3, 3으로 돌아왔는지 확인합니다. open cursors처럼 달라도 되는 파라미터도 실습 뒤에는 같은 방법으로 되돌립니다.

@SLIDE scope 고르기|재기동 직전이 마지막 확인 기회
- memory: 지금 인스턴스만, 재기동하면 사라짐
- spfile: 다음 기동에 반영
- both: 기본값, 동적 파라미터에
- 실습은 모두 scope=spfile
@NOTE ALTER SYSTEM의 scope는 세 가지입니다. memory는 지금 돌고 있는 인스턴스에만 적용되고 SPFILE은 건드리지 않아 재기동하면 사라집니다. spfile은 SPFILE만 바꾸고 다음 기동에 반영됩니다. both는 둘 다 하는 기본값입니다. 이 장의 실습이 모두 spfile인 것은 의도적입니다. 잘못된 값이 지금 인스턴스에 즉시 반영되면 실습 도중 클러스터가 무너집니다. 반대로 spfile로 넣은 값은 재기동 순간 처음 적용되므로, 재기동 직전에 항목을 검토하는 것이 마지막 확인 기회입니다.

@SEC 9.6|PDB를 노드별로 열고 닫기
- 열림 상태는 인스턴스별
- ORA-01219와 ORA-01109
- OPEN INSTANCES=ALL

@IMG 09_pdb.png|PDB 열림 상태는 인스턴스별|한 노드에서만 닫히면 그 노드 세션만 실패
@NOTE GV pdbs를 보면 같은 PDB가 인스턴스마다 한 행씩 나옵니다. 데이터 파일은 하나지만 그것을 여는 상태는 인스턴스별로 관리됩니다. rac1에서 인스턴스 지정 없이 CLOSE하면 rac1에서만 MOUNTED가 되고 rac2는 READ WRITE 그대로입니다. 이때 rac1로 붙은 세션은 컨테이너 전환까지는 되지만 조회하면 ORA-01219, 데이터를 바꾸려 하면 ORA-01109가 납니다. rac2로 붙은 세션은 같은 SQL이 정상입니다. 다시 열 때는 INSTANCES ALL을 붙여 한 번에 두 노드를 엽니다.

@SLIDE 간헐적 실패로 나타난다|SCAN으로 붙으면 노드를 모른다
- 한 노드에서만 닫힌 PDB
- 그 노드로 붙을 때만 실패, 재시도하면 성공하기도
- GV$PDBS의 INST_ID별 OPEN_MODE로 즉시 확인
- 의도적으로 한 노드만 열 때는 기록을 남김
@NOTE 실무에서 이 상황은 어제는 됐는데 오늘은 안 된다는 문의로 들어옵니다. 사용자는 SCAN으로 접속하므로 어느 노드에 붙을지 모르고, PDB가 닫힌 노드로 갈 때만 실패합니다. 다시 시도하면 다른 노드로 붙어 성공하기도 해서 원인을 찾기 어렵습니다. 확인은 GV pdbs 한 줄이면 됩니다. 인스턴스별 OPEN MODE가 다르면 원인이 확정됩니다. 배치를 한 노드에 가두려고 일부러 한 노드에서만 여는 경우도 있지만, 그때는 반드시 기록을 남기고 정식으로는 12장의 서비스를 씁니다.

@SEC 9.7|운영 지침
- 도구 선택
- 일상 점검

@SLIDE 무엇으로 내리고 올릴 것인가|SQL*Plus는 단일 인스턴스 모드 작업에만
- 인스턴스·DB 정지: srvctl stop
- 빠듯한 환경: -stopconcurrency 1
- 클러스터 전체: crsctl stop crs (root)
- 정지와 기동은 같은 도구로 짝지어
@NOTE 도구 선택을 정리합니다. 계획된 인스턴스 정지와 데이터베이스 전체 정지는 srvctl로 합니다. Clusterware가 의도를 알고 의존 자원까지 순서대로 처리하기 때문입니다. 자원이 빠듯한 환경에서는 concurrency를 1로 주어 순차 처리합니다. 클러스터 전체를 내릴 때는 root로 crsctl stop crs를 노드마다 실행합니다. SQL Plus는 Clusterware를 우회해 단일 인스턴스 모드로 여는 것 같은 특수한 작업에만 씁니다. 그리고 srvctl로 내린 것은 srvctl로 올리는 짝을 지킵니다.

@SLIDE 일상 점검|두 노드가 같은가를 묻는다
- 매일: srvctl status database -v, GV$PDBS
- 주간: SPFILE 24 / 3 / 3, TARGET·STATE 불일치
- 변경 후: GV$PARAMETER 두 노드 대조
- sid= 붙이기 전 세 분류 확인
@NOTE 일상 점검 항목입니다. 매일 두 인스턴스가 떠 있는지와 PDB가 노드별로 같은 상태인지 봅니다. 주간으로는 SPFILE 항목 수가 기준선과 같은지, Clusterware 자원 가운데 TARGET과 STATE가 어긋난 것이 없는지 확인합니다. 파라미터를 바꾼 뒤에는 GV parameter로 두 노드 값을 나란히 놓고 대조합니다. PDB 상태와 파라미터 대조는 단일 인스턴스에는 없는 RAC 특유의 점검입니다. 그리고 sid를 붙여 파라미터를 바꾸기 전에는 그 파라미터가 세 분류 중 어디인지 먼저 확인합니다.

@PLAIN 요약
- srvctl config database는 Clusterware에 저장된 DB 정의
- 인스턴스마다 번호·리두 스레드·UNDO를 따로 가진다
- PDB는 OPEN과 SAVE STATE 모두 INSTANCES=ALL
- Clusterware는 도구가 아니라 종료 방식으로 판단
- cluster_database·control_files의 sid 지정은 통과한다
- RESET으로 항목을 지우고 24 / 3 / 3 확인

@PLAIN 퀴즈
- 1. srvctl stop database의 기본 종료 방식은? 어디서 보나?
- 2. 생성 직후 확인할 항목 다섯 가지는?
- 3. 재기동 후 PDB가 MOUNTED로 남는 원인과 예방은?
- 4. shutdown immediate와 kill pmon의 반응 차이는?
- 5. cluster_database sid 지정이 통과하는 이유와 위험은?
- 6. 되돌릴 때 RESET을 쓰는 이유는?

@PLAIN 실습 개요
- 11-05 · 11-06  생성 결과 검증, PDB 두 노드 (racdb로 실행)
- 12-01 ★  srvctl 기동·정지  /  12-03 ★  정상·비정상 종료
- 12-04  SPFILE 표기  /  12-05 ★  파라미터 세 분류
- 12-06  오류 재현과 RESET (24 / 3 / 3 복귀 필수)
- 파일: RAC/11장, RAC/12장 의 *_실습_NN_*.txt
