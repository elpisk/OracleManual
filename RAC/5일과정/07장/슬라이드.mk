@TITLE Oracle Database 19c RAC 과정|ASM 뷰와 asmcmd|ASM을 들여다보는 두 개의 창|제7장

@PLAIN 학습 목표
- ASM에 V$뿐인 이유와 핵심 다섯 뷰를 안다
- V$와 GV$의 차이를 ASM 클라이언트로 설명한다
- asmcmd의 접속 방식과 주요 명령을 쓴다
- ASMCMD-8102의 원인을 계층별로 좁힌다
- ASMCA 무인 모드 명령의 형태를 안다
- USABLE_FILE_MB 음수의 뜻을 설명한다

@PLAIN Agenda
- 7.2  ASM을 보는 두 창
- 7.3  V$ASM_* 뷰 지도  /  7.4  V$와 GV$
- 7.5  asmcmd 명령 체계
- 7.6  asmcmd가 거부될 때
- 7.7  ASMCA 무인 모드
- 7.8  USABLE_FILE_MB를 음수로

@SEC 7.2|ASM을 보는 두 창
- 왜 V$뿐인가
- 같은 값을 두 창으로
- 질문에 맞는 창 고르기

@IMG 07_windows.png|ASM을 보는 두 창|SQL과 asmcmd 모두 ASM 인스턴스의 V$ 정보를 읽는다
@NOTE ASM 인스턴스는 데이터베이스 인스턴스와 같은 커널이라 SGA와 백그라운드 프로세스가 있고 SQL도 받습니다. 하지만 열어 둔 데이터베이스가 없으니 데이터 딕셔너리가 없고, 그래서 DBA로 시작하는 뷰도 없습니다. ASM이 아는 모든 정보는 메모리에서 바로 읽는 V asm 뷰에 있습니다. 이 정보를 보는 방법이 두 가지입니다. sysasm으로 접속해 SQL로 조회하거나, asmcmd 셸에서 ls나 lsdg 같은 명령을 쓰는 것입니다. 둘 다 결국 같은 곳을 읽습니다.

@SLIDE 같은 값을 두 창으로|lsdg는 V$ASM_DISKGROUP의 래퍼
- SQL과 asmcmd lsdg의 숫자가 완전히 같음
- asmcmd는 AU 크기, Voting_files 열을 더 보여 줌
- +CRS AU 4MB, +DATA·+FRA AU 1MB
- AU 크기는 생성 뒤 변경 불가
@NOTE 디스크그룹 여유 공간을 SQL과 asmcmd 두 방법으로 조회해 보면 숫자가 하나도 다르지 않습니다. asmcmd lsdg가 v asm diskgroup을 조회해 표로 찍어 주는 도구이기 때문입니다. 차이는 보여 주는 열입니다. asmcmd 쪽은 AU 크기와 보팅 파일 여부를 함께 보여 줍니다. CRS 디스크그룹의 AU가 4메가이고 DATA와 FRA는 1메가인데, 설치 관리자가 만든 디스크그룹과 나중에 만든 디스크그룹의 기본값이 다르기 때문입니다. AU 크기는 만든 뒤에는 바꿀 수 없습니다.

@SLIDE 질문에 맞는 창 고르기|사람이 볼 것과 스크립트가 볼 것
- 한 번 보고 넘어갈 것: asmcmd
- 조건·계산이 필요한 것: SQL
- 감시 스크립트: SQL (asmcmd 열 배치는 바뀜)
- 두 노드를 한 번에: SQL의 GV$
@NOTE 두 창은 답하기 좋은 질문이 다릅니다. 지금 여유 공간이 얼마인지 사람이 한 번 보고 넘어갈 때는 asmcmd가 빠르고 편합니다. 여유가 일정 값 아래인 디스크그룹만 고르거나 다른 정보와 엮으려면 SQL이 낫습니다. 감시 스크립트는 반드시 SQL로 짭니다. asmcmd의 출력은 버전에 따라 열 위치가 바뀌어 파싱이 깨질 수 있기 때문입니다. 그리고 asmcmd는 인스턴스 하나에만 붙으므로 두 노드를 함께 보려면 SQL의 GV 뷰를 써야 합니다.

@SEC 7.3|V$ASM_* 뷰 지도
- 50개 중 자주 쓰는 다섯
- V$ASM_DISK
- V$ASM_FILE

@IMG 07_viewmap.png|핵심 다섯 뷰|뷰 이름보다 지금 알고 싶은 질문에서 출발한다
@NOTE 19c ASM에는 V asm으로 시작하는 뷰가 50개 있습니다. 17개는 ACFS용이고 나머지 가운데 일상에서 반복해 쓰는 것은 다섯 개 정도입니다. 디스크그룹 뷰는 공간과 마운트 상태, 디스크 뷰는 디스크가 어디 붙어 있고 상태가 어떤지, 파일 뷰는 무엇이 얼마나 들어 있는지, 클라이언트 뷰는 누가 ASM을 쓰는지, 오퍼레이션 뷰는 지금 무슨 작업이 도는지를 답합니다. 아래로 갈수록 시점에 민감해서, 오퍼레이션 뷰는 작업이 없으면 0행이 정상입니다.

@SLIDE 뷰가 비어 있을 때|0행도 하나의 답이다
- V$ASM_OPERATION 0행 = 진행 중 작업 없음
- 접속·권한 확인은 다른 뷰로
- AUDIT·SPARSE·VOLUME 계열은 기능을 써야 행이 생김
- 보조: ATTRIBUTE·TEMPLATE·ALIAS
@NOTE 뷰를 조회했는데 행이 하나도 없으면 접속이나 권한 문제로 의심하기 쉽습니다. v asm operation은 지금 진행 중인 작업만 담으므로 리밸런스가 돌지 않으면 0행이 정상입니다. 의심스러우면 같은 세션에서 디스크그룹 뷰를 조회해 행이 나오는지 보면 됩니다. 감사, 씬 프로비저닝, ADVM 볼륨 계열 뷰도 그 기능을 쓰지 않는 이 랩에서는 모두 0행입니다. 그 밖에 6장의 속성은 attribute 뷰, 5장의 템플릿은 template 뷰, 별칭은 alias 뷰에서 봅니다.

@SLIDE V$ASM_DISK|TOTAL_MB와 OS_MB는 다르다
- GROUP_NUMBER 0: 어느 디스크그룹에도 없음
- 소속이 없으면 NAME도 비어 있음
- 소속 없는 디스크 TOTAL_MB는 0
- 물리 크기는 OS_MB 열에
@NOTE 디스크 뷰를 보면 test1부터 test6까지 그룹 번호가 0이고 이름이 비어 있습니다. ASM 디스크 이름은 디스크그룹에 들어갈 때 붙으므로 소속이 없으면 이름도 없습니다. 헷갈리는 것은 TOTAL MB가 0으로 나오는 점입니다. 4기가짜리 디스크인데 0인 이유는 이 열이 ASM이 쓰는 공간을 뜻하기 때문입니다. 디스크의 물리 크기는 OS MB 열에 있고 여기에는 4096이 정확히 나옵니다. 디스크를 추가하기 전에 크기를 확인할 때는 OS MB를 보면 됩니다.

@SLIDE V$ASM_FILE|한 장의 표에 랩 구조가 보인다
- +CRS: OCR, OCR 백업, ASM SPFILE·암호 파일
- +DATA: 데이터 파일 13개 3445MB, 리두, 컨트롤 파일
- +FRA: 컨트롤 파일 1, 리두 4 (다중화 사본)
- 데이터 파일은 다중화가 아니라 백업 대상
@NOTE 파일 뷰를 디스크그룹과 파일 종류로 묶어 세면 랩 전체 구조가 한 장에 들어옵니다. CRS에는 OCR과 그 백업, ASM 자신의 SPFILE과 암호 파일만 있고 데이터베이스 파일은 없습니다. DATA에는 데이터 파일 13개를 포함한 본체가 있는데, 컨테이너 데이터베이스라서 루트와 시드와 PDB가 각자 시스템 파일을 가지고 UNDO도 인스턴스마다 있어 개수가 많습니다. 컨트롤 파일과 리두는 DATA와 FRA에 한 벌씩 다중화되어 있고, 데이터 파일은 DATA에만 있어 백업으로 보호합니다.

@SEC 7.4|V$와 GV$
- V$ASM_CLIENT
- GV$ASM_CLIENT와 대칭

@IMG 07_gvclient.png|V$ASM_CLIENT와 GV$ASM_CLIENT|DB 인스턴스는 자기 노드의 ASM에 붙는다
@NOTE 디스크그룹 공간처럼 두 ASM 인스턴스가 같은 값을 가진 정보는 어디서 봐도 같습니다. 하지만 누가 접속해 있는가는 인스턴스마다 답이 다릅니다. rac1의 ASM1에서 v asm client를 보면 racdb1만 있고 racdb2는 없습니다. racdb2는 rac2의 ASM2에 붙어 있기 때문입니다. 같은 질문을 GV 뷰로 하면 두 인스턴스의 답이 합쳐져 다섯 행이 열 행이 되고, INST ID 1과 2에 같은 구성이 대칭으로 나타납니다. 이 대칭이 깨지면 그 자체가 이상 신호입니다.

@SLIDE ASM의 클라이언트 셋|DB, ASM 자신, _OCR
- racdb1 / racdb2: 데이터베이스 인스턴스
- +ASM1: +CRS의 자기 SPFILE·암호 파일
- _OCR: CRS 데몬, 이름 자리에 호스트명
- INST_ID 2에 racdb2가 없으면 이상
@NOTE 클라이언트 목록에는 세 종류가 보입니다. 데이터베이스 인스턴스는 당연하고, ASM 자신도 클라이언트로 나옵니다. ASM의 SPFILE과 암호 파일이 CRS 디스크그룹 안에 있어서 그것을 읽으려면 자기 디스크그룹에 파일 접근을 열어야 하기 때문입니다. OCR이라는 이름의 클라이언트는 인스턴스가 아니라 CRS 데몬입니다. OCR 파일이 CRS 디스크그룹에 있으니 CRS도 ASM의 클라이언트가 되고, 그래서 인스턴스 이름 자리에 호스트명이 들어갑니다. 장애 진단 때 GV 조회는 걸릴 수 있으니 각 노드의 V 달러로 대신합니다.

@SEC 7.5|asmcmd 명령 체계
- 무엇에 어떻게 붙는가
- 명령별 쓰임
- 읽을 때 주의할 점

@SLIDE 무엇에 어떻게 붙는가|도움말에 답이 있다
- ORACLE_HOME과 ORACLE_SID가 대상 인스턴스를 정함
- / AS SYSASM과 같은 bequeath 접속
- 실행 계정은 OSASM 그룹 구성원이어야 함
- 인자 없이 실행하면 ASMCMD> 셸
@NOTE asmcmd 도움말을 보면 이 도구가 어디에 어떻게 붙는지 그대로 적혀 있습니다. 오라클 홈과 SID 환경 변수가 접속할 인스턴스를 정하고, sqlplus slash as sysasm과 같은 방식으로 리스너를 거치지 않는 로컬 접속을 맺습니다. 그리고 실행하는 사용자는 OSASM 그룹의 구성원이어야 한다고 되어 있습니다. 이 한 문장이 잠시 뒤에 볼 오류의 원인입니다. 인자 없이 실행하면 대화형 셸이 뜨고, 명령을 인자로 주면 한 번 실행하고 끝납니다.

@SLIDE 명령별 쓰임|뷰 하나에 명령 하나
- lsdg · lsdsk -k · lsct: DISKGROUP · DISK · CLIENT
- ls · du: 디렉터리와 사용량, Mirror_used_MB
- lsof: 이 인스턴스에 열린 파일
- iostat -G -t · spget · dsget
@NOTE asmcmd 명령은 대부분 뷰 하나와 짝을 이룹니다. lsdg는 디스크그룹 뷰, lsdsk는 디스크 뷰, lsct는 클라이언트 뷰입니다. ls와 du는 파일 시스템처럼 디렉터리를 둘러보고 사용량을 합산하는데, du는 미러를 뺀 크기와 미러를 포함한 크기를 함께 보여 줍니다. lsof는 접속한 ASM 인스턴스 기준으로 열린 파일을 보여 줍니다. iostat는 디스크별 누적 입출력을, spget은 ASM SPFILE 위치를, dsget은 디스크 검색 문자열을 보여 줍니다.

@SLIDE 읽을 때 주의할 점|이름과 옵션을 그대로 믿지 않는다
- GUID 디렉터리는 파일 생성 시점의 PDB GUID
- PDB는 V$DATAFILE의 CON_ID로 역추적
- lsdsk --candidate는 소속 없는 디스크 전체
- dsget의 parameter와 profile이 같아야 함
@NOTE 출력을 읽을 때 조심할 곳이 몇 군데 있습니다. ls로 보이는 32자리 GUID 디렉터리는 파일이 만들어지던 순간의 PDB GUID라서 현재 GUID와 다를 수 있습니다. 실제로 PDB 시드의 데이터 파일과 템프 파일이 서로 다른 디렉터리에 있었습니다. PDB는 데이터 파일 뷰의 CON ID로 찾아야 합니다. lsdsk의 candidate 옵션은 이름과 달리 FORMER 디스크까지 보여 줍니다. dsget의 두 값이 다르면 다음 기동 때 디스크를 못 찾을 수 있습니다.

@SLIDE lsof와 iostat|열린 파일과 디스크 균형
- racdb1이 undotbs1과 undotbs2를 모두 열어 둠
- 다른 인스턴스 UNDO는 복구 때 읽음
- iostat는 절대값보다 디스크 간 균형
- 양은 적은데 시간이 길면 경로·장비 의심
@NOTE lsof를 보면 racdb1이 자기 UNDO뿐 아니라 racdb2의 UNDO 파일도 열어 둔 것이 보입니다. 평소에는 자기 UNDO만 쓰지만 다른 인스턴스가 죽었을 때 그 UNDO를 읽어 복구해야 하므로 파일은 열어 둡니다. iostat는 디스크별 누적 읽기와 쓰기, 걸린 시간을 보여 줍니다. 여기서 볼 것은 숫자의 크기가 아니라 디스크 사이의 균형입니다. 읽은 양이 적은 디스크가 시간이 더 걸렸다면 그 디스크만 경로나 장비가 다른지 의심해 봐야 합니다.

@SEC 7.6|asmcmd가 거부될 때
- 오류 재현
- OSASM 그룹
- root는 왜 되는가

@IMG 07_auth.png|계층을 내려가며 원인 찾기|메시지는 연결 문제, 원인은 그룹 소속
@NOTE oracle 계정에서 Grid 홈과 ASM1을 지정하고 asmcmd를 실행하면 idle instance에 연결했다며 ASMCMD-8102가 납니다. ASM은 멀쩡히 돌고 있는데 메시지는 ASM이 없다고 말합니다. 이럴 때는 한 계층 내려갑니다. asmcmd가 대신하는 sqlplus slash as sysasm을 같은 계정으로 실행하면 ORA-01017, 인증 거부가 나옵니다. OS 인증이므로 다음은 OS 그룹입니다. osdbagrp로 OSASM 그룹이 asmadmin임을 확인하고 id로 계정의 소속과 대조하면 원인이 확정됩니다.

@SLIDE OSASM 그룹|asmadmin 구성원은 grid뿐
- osdbagrp -a → asmadmin
- grid: asmadmin 포함 → 성공
- oracle: asmdba까지만 → 거부
- asmdba는 파일 사용 권한, 관리 권한 아님
@NOTE 이 랩에서 OSASM 그룹은 asmadmin이고 그 구성원은 grid 하나입니다. oracle 계정은 asmdba 그룹까지만 가지고 있습니다. asmdba는 데이터베이스가 ASM 파일을 읽고 쓸 수 있게 하는 권한이라 racdb는 DATA 디스크그룹을 정상으로 씁니다. 하지만 디스크그룹을 만들거나 지우는 관리 권한은 아닙니다. 그래서 oracle 계정으로는 asmcmd 관리 명령이 거부됩니다. 이것은 고장이 아니라 설치 때 의도한 권한 분리입니다. ASM 작업은 grid로 전환해서 합니다.

@SLIDE root는 왜 되는가|되는 것과 해도 되는 것
- root는 asmadmin에 없지만 성공
- Grid 홈 bin/oracle에 setuid (-rwsr-s--x)
- 감사 기록에 실제 작업자가 남지 않음
- root 소유 로그가 grid 작업을 방해
@NOTE 규칙대로라면 asmadmin에 없는 root도 실패해야 하는데 실제로는 성공합니다. Grid 홈의 oracle 실행 파일에 setuid 비트가 붙어 있고, uid 0인 root는 그룹 소속 검사를 통과하기 때문입니다. 그러니 규칙은 일반 계정은 asmadmin 소속이어야 한다로 다듬어야 합니다. 그렇다고 root로 작업해도 된다는 뜻은 아닙니다. 감사 기록에 root로 남으면 누가 했는지 알 수 없고, root가 만든 로그 파일 때문에 나중에 grid가 그 디렉터리에 쓰지 못하는 일이 생깁니다.

@SEC 7.7|ASMCA 무인 모드
- asmca -silent -createDiskGroup
- SQL로 만든 것과의 차이

@SLIDE ASMCA 무인 모드|인자만으로 디스크그룹 생성
- asmca -silent -createDiskGroup -diskGroupName CH9DG
- -disk, -redundancy, -au_size, -compatible.*
- DBT-30001로 성공, cfgtoollogs/asmca에 로그
- 도움말의 compatible 상한 12.2는 낡은 표기
@NOTE 디스크그룹은 SQL로도 만들 수 있지만 구축 현장에서는 asmca를 많이 씁니다. 화면 도구이지만 silent 옵션을 주면 인자만으로 동작하고, 로그와 종료 코드가 남아 자동화에 알맞습니다. 받는 인자는 CREATE DISKGROUP과 거의 같아서 디스크, 장애 그룹, 이중화 수준, AU 크기, compatible 속성을 지정합니다. 성공하면 DBT-30001 메시지가 나옵니다. 도움말에는 compatible 범위가 12.2까지로 적혀 있지만 19 버전을 넣어도 정상으로 만들어집니다. 도움말은 참고 자료로만 봅니다.

@SLIDE SQL로 만든 것과의 차이|자원 등록과 양 노드 마운트까지
- 결과 디스크그룹은 SQL로 만든 것과 같음
- ora.CH9DG.dg 자원이 자동으로 생김
- GV$ASM_DISKGROUP에서 두 인스턴스 MOUNTED
- asmgroup 슬롯 2 OFFLINE은 카디널리티 3 때문
@NOTE asmca로 만든 디스크그룹을 조회해 보면 SQL로 만든 것과 구별이 되지 않습니다. 장애 그룹을 지정하지 않았으니 디스크마다 하나씩 디스크 이름과 같은 장애 그룹이 생겼습니다. 차이는 그 다음입니다. Clusterware 자원이 자동으로 등록되고, rac1에서 한 번 실행했는데 rac2에서도 마운트되어 있습니다. SQL로 만들면 다른 노드에서 직접 마운트해야 했던 것과 다릅니다. 자원 상태에서 2번 슬롯이 OFFLINE인 것은 asmgroup의 카디널리티가 3인데 노드가 둘이라서이며 장애가 아닙니다.

@SEC 7.8|USABLE_FILE_MB를 음수로
- 공식 검산
- 1GB씩 채우기
- 음수의 뜻

@SLIDE 공식 검산|USABLE = (FREE − 예약) / 2
- +CRS: (11324 − 4096) / 2 = 3614
- External은 예약 0, USABLE = FREE
- 예약 = 가장 큰 장애 그룹 크기
- +CRS는 장애 그룹 셋, 각 4096MB
@NOTE 6장에서 본 공식을 모든 디스크그룹에 대해 계산으로 확인합니다. 디스크그룹 뷰에서 공식대로 계산한 열을 함께 뽑아 보면 USABLE 값과 정확히 일치합니다. External 이중화인 DATA와 FRA는 미러가 없어서 예약이 0이고 USABLE이 FREE와 같습니다. Normal인 CRS는 여유에서 예약을 빼고 둘로 나눕니다. 예약 4096은 장애 그룹 세 개 가운데 가장 큰 것의 크기입니다. 장애 그룹 하나가 사라지면 그만큼의 데이터를 남은 곳에 다시 복제해야 하기 때문입니다.

@IMG 07_usable.png|1GB씩 채울 때|4GB에서 USABLE이 −77
@NOTE 디스크 세 장짜리 Normal 디스크그룹 CH9DG에 1기가 데이터 파일을 하나씩 더하며 값을 따라갑니다. 데이터 파일 하나가 FREE를 약 2005메가씩 깎습니다. 미러까지 2000메가에 메타데이터가 조금 더해진 것입니다. USABLE은 매번 약 1002메가씩 줄어듭니다. 4기가를 넣은 순간 FREE 3941이 예약 4096보다 작아지고 USABLE이 마이너스 77이 됩니다. 그래프에서 FREE 막대는 아직 넉넉해 보이는데 USABLE 선은 0 아래로 내려간 것을 볼 수 있습니다.

@SLIDE 음수의 뜻|쓸 수 없다가 아니라 복원할 수 없다
- 음수 상태에서 5만 행 INSERT·COMMIT 정상
- 원시 공간 FREE 3941MB는 남아 있음
- 장애 그룹 하나를 잃으면 이중화 복원 불가
- 경보는 0보다 앞에서, 두 단계로
@NOTE USABLE이 음수인 상태에서 테이블을 만들고 5만 건을 넣어도 아무 오류 없이 커밋됩니다. 원시 공간은 아직 3941메가가 남아 있기 때문입니다. 그러니 음수는 더 이상 쓸 수 없다는 뜻이 아닙니다. 지금 장애 그룹 하나를 잃으면 이중화를 다시 맞출 공간이 없다는 경고입니다. FREE만 감시하고 있었다면 이 위험을 전혀 알아채지 못합니다. 그래서 경보는 USABLE에 걸고, 0이 되기 전에 경고와 심각 두 단계를 둡니다.

@SEC 7.9|운영 지침
- 정기 점검 항목

@SLIDE 정기 점검 항목|매일·주간·변경 후
- 매일: USABLE_FILE_MB, OFFLINE 디스크 수
- 주간: GV$ASM_DISKGROUP·CLIENT 대칭
- 증설 전후: iostat 균형, 장애 시 헤더 상태
- 관리 작업은 grid, 스크립트는 SQL
@NOTE 이 장의 도구 가운데 일상 점검에 넣을 것을 추립니다. 매일 디스크그룹의 USABLE과 오프라인 디스크 수를 봅니다. 이것은 스크립트로 돌리고 임계값을 넘으면 알리게 합니다. 주간으로는 두 노드의 마운트 상태와 클라이언트가 대칭인지 봅니다. 증설 전후에는 iostat로 디스크 사이의 균형을, 장애가 났을 때는 디스크 헤더 상태를 확인합니다. 관리 작업은 grid 계정으로 하고, 메시지가 원인을 잘못 가리키면 한 계층 아래 도구로 내려가 확인합니다.

@PLAIN 요약
- ASM에는 딕셔너리가 없어 V$ASM_* 뷰만 있다
- 핵심 다섯: DISKGROUP·DISK·FILE·CLIENT·OPERATION
- 인스턴스마다 다른 정보는 GV$로, 대칭을 확인
- asmcmd는 bequeath 접속, asmadmin 소속 필요
- ASMCMD-8102는 sqlplus로 내려가 ORA-01017 확인
- USABLE 음수는 이중화 복원 불가 경고

@PLAIN 퀴즈
- 1. ASM 인스턴스에 DBA_ 뷰가 없는 이유는?
- 2. TOTAL_MB 0, OS_MB 4096인 디스크의 상태는?
- 3. +ASM1의 V$ASM_CLIENT에 racdb2가 없다. 정상인가?
- 4. ASMCMD-8102의 원인을 확정하는 순서는?
- 5. root로 asmcmd가 되는 이유와 피해야 할 이유는?
- 6. USABLE −77인 디스크그룹에 더 쓸 수 있는가?

@PLAIN 실습 개요
- 01  ASM 뷰 지도 — 다섯 뷰로 랩 구성 읽기
- 03  asmcmd 명령 체계 — 접속 방식과 주요 명령
- 06 ★  USABLE_FILE_MB 음수 만들기
- 06은 CH9DG 전제 (없으면 asmca 한 줄로 생성)
- 파일: RAC/09장/9장_실습_NN_*.txt
