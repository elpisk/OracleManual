@TITLE Oracle Database 19c RAC 과정|ASM 인스턴스와 디스크그룹|인스턴스, 디스크 발견, 이중화, 마운트와 삭제|제4장

@PLAIN 학습 목표
- ASM 인스턴스와 DB 인스턴스의 차이를 설명한다
- ASM 주요 파라미터와 +CRS의 예외를 안다
- V$ASM_DISK로 디스크 상태를 판단한다
- 디스크그룹 생성 오류의 원인 코드를 구분한다
- 세 가지 이중화의 용량과 장애 그룹을 비교한다
- 마운트·언마운트·삭제의 규칙을 지킨다

@PLAIN Agenda
- 4.2  ASM 인스턴스
- 4.3  디스크 발견
- 4.4  디스크그룹 만들기
- 4.5  이중화 세 가지
- 4.6  마운트·언마운트·삭제

@SEC 4.2|ASM 인스턴스
- 데이터 파일이 없는 인스턴스
- 백그라운드 프로세스와 I/O 경로
- 파라미터와 권한

@IMG 04_asminst.png|ASM 인스턴스와 데이터베이스 인스턴스|데이터베이스는 ASMB로 위치를 받아 디스크에 직접 I/O한다
@NOTE 한 노드 안에 ASM 인스턴스와 데이터베이스 인스턴스가 나란히 떠 있습니다. 왼쪽 +ASM1은 grid 계정으로 돌며 디스크그룹의 메타데이터만 관리합니다. 오른쪽 racdb1은 oracle 계정으로 돌며 실제 데이터 파일을 엽니다. 둘은 ASMB 프로세스로 연결되고, 데이터베이스는 이 채널로 파일의 익스텐트가 어느 디스크 어디에 있는지만 받아 옵니다. 빨간 화살표처럼 실제 읽기와 쓰기는 데이터베이스가 디스크에 직접 합니다. 아래 점선 상자의 test1부터 test6은 설치 가이드 v2 부록 E로 추가한 실습 디스크입니다.

@SLIDE 데이터 파일이 없는 인스턴스|STATUS는 항상 STARTED
- INSTANCE_TYPE=ASM, 바꿀 수 없음
- STATUS STARTED, INSTANCE_ROLE UNKNOWN
- V$DATAFILE 조회 → ORA-01507
- 접속은 SYSASM, 계정은 grid
- GV$INSTANCE로 +ASM1, +ASM2 확인
@NOTE ASM 인스턴스에 sysasm으로 접속해 v$instance를 보면 데이터베이스 인스턴스와 거의 같은 모양인데 두 가지가 다릅니다. STATUS가 OPEN이 아니라 STARTED이고 INSTANCE_ROLE이 UNKNOWN입니다. 마운트할 데이터베이스가 없기 때문에 영원히 STARTED에 머무릅니다. v$datafile을 조회하면 ORA-01507이 나는 것도 같은 이유입니다. 인스턴스의 성격은 INSTANCE_TYPE 파라미터가 정하고 바꿀 수 없습니다. GV 달러 뷰는 ASM에서도 동작해서 두 노드의 ASM 인스턴스가 함께 보입니다.

@SLIDE 백그라운드 프로세스|ASM은 가볍고, 메타데이터만 다룬다
- 프로세스 수: asm_ 가 ora_ 보다 훨씬 적다
- RBAL: 리밸런스 조정, ARBn이 실제 이동
- GMON: 디스크그룹 멤버십과 PST
- ASMB: 양쪽에 있는 연결 채널
- LMON·LMD0·LMS0: 메타데이터 블록 조정
@NOTE ps로 세어 보면 ASM 쪽 프로세스가 데이터베이스보다 훨씬 적습니다. SQL 처리나 통계 같은 일이 없기 때문입니다. ASM에만 있는 프로세스는 세 가지입니다. RBAL은 리밸런스를 조정하고 실제 이동은 리밸런스 중에만 뜨는 ARB 슬레이브가 합니다. GMON은 디스크그룹 멤버십과 파트너 상태 테이블을 관리하며 3장에서 디스크를 내릴 때 등장했습니다. ASMB는 ASM 쪽과 데이터베이스 쪽에 하나씩 있습니다. LMON이나 LMS도 있는데 두 ASM 인스턴스가 메타데이터를 공유하기 때문입니다.

@SLIDE ASM 파라미터|+CRS는 ASM_DISKGROUPS에 없다
- asm_diskstring = /dev/asmdisk/*
- asm_diskgroups = DATA, FRA
- +CRS는 Clusterware가 직접 마운트
- asm_power_limit 1, 범위 0~1024 (ORA-00068)
- RDBMS에서 설정하면 ORA-15021
@NOTE 핵심 파라미터를 봅니다. asm_diskstring은 ASM이 디스크를 찾는 경로로, udev가 만든 전용 디렉터리만 지정했습니다. asm_diskgroups는 기동 때 자동으로 마운트할 목록인데 CRS가 빠져 있습니다. 누락이 아닙니다. +CRS에는 OCR과 Voting File이 있어 이 목록을 읽기 전부터 필요하므로 Clusterware가 직접 마운트합니다. asm_power_limit은 리밸런스 기본 병렬도이고 1024를 넘기면 ORA-00068입니다. ASM 파라미터를 데이터베이스 인스턴스에서 설정하면 ORA-15021로 거절됩니다.

@SLIDE SPFILE과 dsget|ASM 설정도 ASM 안에
- spget: +CRS/rac-cluster/ASMPARAMETERFILE/...
- dsget parameter: 현재 인스턴스 값
- dsget profile: GPnP 프로필 값
- 둘이 다르면 재기동 후 디스크를 못 찾음
- diskstring은 좁게 잡는다
@NOTE ASM의 SPFILE도 +CRS 디스크그룹 안에 있습니다. asmcmd spget이 그 위치를 알려 줍니다. asmcmd dsget은 두 줄을 보여 주는데, parameter는 지금 인스턴스가 쓰는 디스크 탐색 경로이고 profile은 GPnP 프로필에 저장된 값입니다. ASM은 기동할 때 프로필 값을 쓰므로 둘이 다르면 재기동 뒤 디스크를 못 찾을 수 있습니다. 탐색 경로를 sd 별표처럼 넓게 잡으면 기동할 때마다 모든 블록 장치의 헤더를 읽어 느려지고 다른 디스크를 건드릴 위험도 있습니다.

@SLIDE 접속 권한과 기동 주체|grid는 SYSASM, oracle은 asmdba
- asmadmin: SYSASM, 디스크그룹 관리
- asmdba: DB가 ASM 파일을 쓰는 권한
- asmoper: 기동·정지 등 운영 작업
- ASM 인스턴스 = ora.asm 자원, srvctl status asm
- Flex ASM: ASMNET1LSNR_ASM으로 접속
@NOTE ASM 권한은 OS 그룹으로 나뉩니다. asmadmin은 SYSASM으로 디스크그룹을 만들고 지우는 최고 권한이고, asmdba는 데이터베이스가 ASM 파일을 쓰는 데 필요하며, asmoper는 기동과 정지 같은 운영 작업용입니다. grid는 세 그룹에 모두 속하고 oracle은 asmdba에만 속합니다. ASM 인스턴스 자체는 2장에서 본 OHAS 스택의 ora.asm 자원이라 Clusterware가 올리고 내립니다. 19c는 Flex ASM 구성이어서 데이터베이스가 ASM 리스너를 거쳐 ASM에 붙고, 필요하면 다른 노드의 ASM으로 옮겨 붙습니다.

@SEC 4.3|디스크 발견
- V$ASM_DISK 읽기
- HEADER_STATUS
- 두 노드 대조

@SLIDE V$ASM_DISK 읽기|TOTAL_MB 0은 문제가 아니다
- test1~6: CANDIDATE, NAME 없음, CLOSED
- crs·data·fra 8장: MEMBER, CACHED
- TOTAL_MB: ASM이 쓸 수 있는 크기
- OS_MB: OS가 보고한 크기
- 그룹 밖 디스크는 TOTAL_MB 0
@NOTE ASM이 탐색 경로에서 찾은 디스크는 디스크그룹 소속과 상관없이 모두 v$asm_disk에 나옵니다. 새로 붙인 test 디스크 여섯 장은 CANDIDATE이고 기존 여덟 장은 MEMBER입니다. CANDIDATE는 아직 이름이 없고 MOUNT_STATUS가 CLOSED입니다. 헤더만 읽고 열어 두지 않았다는 뜻입니다. 가장 오해하기 쉬운 것이 TOTAL_MB입니다. ASM이 쓸 수 있는 크기라 그룹에 들어가기 전에는 0이고, 실제 크기는 OS_MB의 4096입니다. 두 열을 함께 봐야 디스크가 인식되지 않았다는 오판을 피합니다.

@IMG 04_header.png|HEADER_STATUS의 변화|그룹에 들어가면 MEMBER, 정상적으로 빠지면 FORMER
@NOTE 디스크 하나의 헤더 상태가 어떻게 바뀌는지 따라갑니다. 처음에는 CANDIDATE입니다. create diskgroup으로 그룹에 넣으면 MEMBER가 되고 TEST_0000 같은 이름과 그룹 번호가 붙습니다. 디스크그룹을 지우면 FORMER가 됩니다. 한 번 쓰였다는 표시일 뿐 CANDIDATE처럼 그대로 새 그룹에 넣을 수 있습니다. 위험한 것은 왼쪽 아래의 경우입니다. 이미 +DATA의 구성원인 data1을 지정하면 ORA-15029로 막히는데, FORCE로 밀어붙이면 헤더를 덮어써 +DATA를 파괴합니다.

@SLIDE 두 노드 대조|같은 디스크를 같은 이름으로 보는가
- +ASM2에서도 CANDIDATE 6장 확인
- 개수가 다르면 그 노드에서 마운트 실패
- rac1 crs1 → sdb, rac2 crs1 → sda
- scsi_id로 보면 WWN이 같다
- 덜 보이면 lsblk → 링크 → WWN 순으로
@NOTE 디스크그룹을 만들기 전에 반드시 다른 노드에서도 같은 조회를 해서 같은 경로로 같은 개수가 보이는지 확인합니다. 장치 이름은 노드마다 다를 수 있습니다. 실습 환경에서도 rac1의 crs1은 sdb를, rac2의 crs1은 sda를 가리킵니다. 그래도 scsi_id로 WWN을 보면 같은 디스크입니다. udev 규칙을 WWN 기준으로 만든 이유가 이것입니다. 한 노드에서 디스크가 덜 보인다면 블록 장치, 심볼릭 링크, WWN 순서로 확인합니다. udev 규칙 줄이 빠진 사례가 실제로 있었습니다.

@SEC 4.4|디스크그룹 만들기
- 실패하는 경우부터
- 생성과 속성
- 두 계층의 상태

@SLIDE 실패에서 배우기|ORA-15018 아래 줄이 원인
- MEMBER 디스크 → ORA-15029
- 없는 경로 → ORA-15031
- Normal에 1장 → ORA-15167 (found only 1)
- High에 FG 2개 → ORA-15167 (found only 2)
- CREATE에 disk_repair_time → ORA-15237
@NOTE 디스크그룹 생성이 실패하면 첫 줄은 언제나 ORA-15018입니다. 만들 수 없었다는 결과만 알려 주고 원인은 그 아래 줄에 있습니다. 이미 다른 그룹이 쓰는 디스크면 15029, 경로가 틀리면 15031, 이중화가 요구하는 장애 그룹 수를 못 채우면 15167입니다. 15167은 메시지 안의 숫자로 Normal과 High의 요구량 차이를 보여 줍니다. disk_repair_time처럼 만든 뒤에 설정하는 속성을 CREATE에 넣으면 15237입니다. ASM 오류는 둘째 줄부터 읽는 습관을 들입니다.

@SLIDE 생성과 속성|compatible은 만들 때 정한다
- create diskgroup TEST external ... test1
- attribute compatible.asm / compatible.rdbms 19.0
- test1: CANDIDATE → MEMBER, TEST_0000
- AU: +CRS 4MB, +DATA·+FRA 1MB
- compatible은 올릴 수만 있다
@NOTE test1로 External 디스크그룹 TEST를 만듭니다. 이때 compatible 속성을 함께 지정했습니다. compatible.asm은 디스크그룹이 쓸 수 있는 ASM 기능 수준이고, compatible.rdbms는 이 그룹을 쓸 수 있는 데이터베이스의 최저 버전입니다. 3장에서 +CRS의 compatible.rdbms가 10.1이라 디스크 OFFLINE이 막혔던 것을 기억하시면 왜 처음부터 지정하는지 이해됩니다. 이 속성은 올릴 수만 있습니다. AU 크기도 만들 때 정해지는데 실습 환경은 +CRS가 4MB, 나머지가 1MB입니다.

@SLIDE asmcmd lsdg|한 줄로 보는 디스크그룹
- Type: NORMAL · EXTERN
- AU: 4194304 / 1048576
- Req_mir_free_MB: 손실 대비 공간
- Usable_file_MB: 이중화를 고려한 여유
- Voting_files: CRS만 Y
@NOTE asmcmd lsdg는 v$asm_diskgroup의 주요 열을 한 줄에 보여 줍니다. Type 열에서 이중화를, AU 열에서 할당 단위를 봅니다. Req_mir_free_MB는 디스크 하나를 잃었을 때 미러를 다시 만들 공간이고, +CRS만 값이 있는 것은 Normal이면서 데이터가 들어 있기 때문입니다. Usable_file_MB는 그 공간을 빼고 실제로 쓸 수 있는 양입니다. Voting_files는 CRS만 Y입니다. Rebal 열은 6장에서 리밸런스가 돌 때 Y로 바뀌는 것을 보게 됩니다.

@IMG 04_layers.png|두 계층의 상태|SQL 마운트는 Clusterware 자원에 반영되지 않는다
@NOTE rac1에서 만든 TEST를 rac2에서 보면 DISMOUNTED입니다. 존재는 전파되지만 마운트는 자동으로 되지 않습니다. 왼쪽처럼 SQL로 두 노드에 마운트하면 ASM 계층은 MOUNTED인데 Clusterware의 ora.TEST.dg 자원은 TARGET과 STATE가 모두 OFFLINE입니다. TARGET이 OFFLINE이면 노드 재기동 때 이 그룹이 올라오지 않고, 그 안에 파일이 있는 데이터베이스는 기동에 실패합니다. 오른쪽처럼 srvctl start diskgroup으로 올리면 두 계층이 일치합니다. 운영에서는 srvctl을 씁니다.

@SLIDE 자원 이름으로 확인|PRCA와 PRCR이 함께 나오면
- crsctl status resource ora.TEST.dg -t
- 3번 행 OFFLINE: asmgroup 카디널리티 3
- srvctl status diskgroup -g TEST
- 없는 이름: PRCA-1000 + PRCR-1001
- 생성·삭제는 전파, 마운트는 전파 안 됨
@NOTE 디스크그룹 자원은 ora 점 이름 점 dg 형태로 자동 생성됩니다. crsctl status resource로 보면 세 행이 나오고 세 번째는 항상 OFFLINE입니다. ora.asmgroup의 카디널리티가 3인데 노드가 둘이기 때문이고 1장에서 본 것과 같은 이유입니다. 없는 디스크그룹을 srvctl로 조회하면 ASM 계층의 PRCA-1000과 Clusterware 계층의 PRCR-1001이 함께 나옵니다. 삭제 뒤에 이 두 줄이 나오면 자원까지 깨끗이 정리된 것입니다. 정리하면 생성과 삭제는 전파되고 마운트와 언마운트는 전파되지 않습니다.

@SEC 4.5|이중화 세 가지
- 용량 비교
- 장애 그룹
- 고르는 기준

@IMG 04_redundancy.png|이중화 세 가지|디스크를 1·2·3장 넣어도 담는 양은 4GB 남짓
@NOTE test 디스크 여섯 장으로 세 가지 이중화를 만들었습니다. External인 TEST는 한 장, Normal인 TESTN은 두 장, High인 TESTH는 세 장입니다. TOTAL_MB는 4096, 8192, 12288로 늘지만 USABLE_FILE_MB는 셋 다 4천 MB 남짓으로 같습니다. 디스크를 두 배, 세 배 넣었는데 담을 수 있는 양은 그대로입니다. 늘어난 것은 견딜 수 있는 손실 개수입니다. 아래 상자처럼 최소 장애 그룹을 못 채우면 ORA-15167이 나고, 실습 디스크는 물리적으로 한 폴더에 있다는 한계도 기억해 둡니다.

@SLIDE 장애 그룹|함께 죽는 단위로 나눈다
- 미지정: 디스크마다 장애 그룹 (TEST_0000)
- 지정: FG1, FG2, FG3
- 이름은 CTRL_A, RACK_1처럼 실제 경계로
- QUORUM: 데이터 없이 Voting File만
- 실습 디스크는 물리적으로 한 그룹
@NOTE 장애 그룹을 지정하지 않으면 ASM은 디스크마다 별도 장애 그룹을 만들고 디스크 이름을 그대로 씁니다. 장애 그룹의 의미는 함께 죽는 단위입니다. 같은 컨트롤러나 같은 랙의 디스크는 함께 죽을 수 있으므로 같은 그룹으로 묶고, 이름도 FG1 같은 번호보다 컨트롤러나 랙 이름을 쓰면 v$asm_disk만 보고 배치를 판단할 수 있습니다. FAILGROUP_TYPE에는 QUORUM도 있는데, 데이터 없이 Voting File만 담아 확장 클러스터의 제3 위치에 둡니다. 실습 환경의 FG 구분은 학습용 논리 구분입니다.

@SLIDE 어느 이중화를 고를 것인가|스토리지가 이미 보호하는가
- RAID 스토리지: External
- JBOD·로컬 디스크: Normal 이상
- OCR·Voting File 그룹: Normal 이상
- 확장 클러스터: Normal + QUORUM
- RAID 위 Normal: 물리의 4분의 1
@NOTE 운영에서는 하나를 골라야 하고 기준은 스토리지가 이미 보호하고 있는가입니다. RAID로 보호되는 엔터프라이즈 스토리지라면 External이 맞고, JBOD나 로컬 디스크처럼 ASM이 유일한 보호 수단이면 Normal 이상입니다. OCR과 Voting File을 담는 그룹은 Voting File 세 개를 위해 Normal 이상으로 둡니다. 실습 환경의 +CRS가 Normal인 이유입니다. 흔한 실수는 RAID 위에 Normal을 얹는 것입니다. RAID에서 절반, ASM에서 다시 절반이라 물리 용량의 4분의 1만 남고 쓰기도 두 배가 됩니다.

@SEC 4.6|마운트·언마운트·삭제
- 사용 중인 디스크그룹
- FORCE의 결과
- 삭제 조건과 삭제 후

@IMG 04_dismount.png|언마운트와 삭제의 순서|데이터베이스 → 다른 노드 → 남은 노드
@NOTE TEST에 테이블스페이스를 만들면 데이터베이스와 디스크그룹 자원 사이에 의존 관계가 생기고, 그때부터 순서가 중요해집니다. 먼저 데이터베이스에서 테이블스페이스를 지웁니다. 건너뛰면 ORA-15053입니다. 다음으로 다른 노드의 +ASM2에서 언마운트합니다. 건너뛰면 ORA-15073입니다. 마지막으로 남은 +ASM1에서 지우면 디스크는 FORMER가 되고 자원도 사라집니다. 가운데 점선 상자는 사용 중에 FORCE로 언마운트한 경우인데, 데이터베이스는 파일을 여전히 ONLINE으로 알고 있어 첫 접근부터 오류가 납니다.

@SLIDE 사용 중인 디스크그룹|ORA-15027은 정상적인 보호
- create tablespace ts_test datafile '+TEST'
- alert.log: 의존 관계 established
- 이후 racdb는 ora.TEST.dg를 먼저 요구
- dismount → ORA-15027
- FORCE 전에 DB 쪽 정리
@NOTE racdb1에서 TEST에 500MB 테이블스페이스를 만들면 데이터베이스 alert.log에 racdb와 ora.TEST.dg 사이의 의존 관계가 설정되었다는 줄이 남습니다. 이제 Clusterware는 racdb를 띄우기 전에 TEST 디스크그룹을 먼저 띄우려 합니다. 이 상태에서 언마운트하면 ORA-15027로 거절됩니다. 데이터베이스가 파일을 열고 있으니 정상적인 보호입니다. 실습에서는 FORCE의 결과를 관찰하지만 운영에서는 데이터베이스 쪽에서 테이블스페이스를 내리거나 지운 다음에 ASM에서 언마운트합니다.

@SLIDE 삭제 조건과 삭제 후|ORA-15039 아래 줄이 매번 다르다
- 파일이 있으면 ORA-15053
- 다른 인스턴스가 마운트 중이면 ORA-15073
- 삭제 후 디스크는 FORMER
- 자원 ora.TEST.dg도 자동 삭제
- 자원만 남으면 srvctl remove diskgroup
@NOTE 삭제가 막히는 조건은 둘입니다. 그룹 안에 파일이 남아 있으면 ORA-15053, 다른 ASM 인스턴스가 마운트하고 있으면 ORA-15073입니다. 첫 줄 ORA-15039는 두 번 모두 같고 원인은 둘째 줄이 알려 줍니다. 지운 뒤 디스크는 FORMER가 되어 FORCE 없이 다시 쓸 수 있습니다. SQL로 지웠어도 Clusterware 자원은 함께 정리됩니다. 강제 삭제나 비정상 종료 뒤에 자원만 남아 OFFLINE으로 보이면 srvctl remove diskgroup으로 자원만 지웁니다.

@SLIDE 실습 뒤 기준 상태|다음 장이 같은 디스크를 쓴다
- TEST, TESTN, TESTH 모두 삭제
- HEADER_STATUS: FORMER 6, MEMBER 8
- crsctl check cluster -all 정상
- srvctl status database: 두 인스턴스
- ocrcheck ID 그대로
@NOTE 이 장의 실습은 test 디스크만 씁니다. crs, data, fra 디스크는 건드리지 않습니다. 실습을 마칠 때는 만든 디스크그룹 세 개를 모두 지우고, 헤더 상태가 FORMER 여섯 장과 MEMBER 여덟 장인지 확인합니다. 5장과 6장이 이 디스크를 그대로 다시 쓰기 때문입니다. 마지막으로 클러스터 상태, 두 데이터베이스 인스턴스, OCR ID가 장을 시작할 때와 같은지 확인합니다. 디스크그룹을 다루는 실습 뒤에는 항상 이 세 가지를 대조하는 습관을 들입니다.

@PLAIN 요약
- ASM은 메타데이터만 다루는 STARTED 인스턴스
- +CRS는 Clusterware가 직접 마운트
- CANDIDATE·FORMER는 사용 가능, MEMBER는 금지
- 생성 오류는 ORA-15018 아래 줄로 판단
- 이중화가 늘리는 것은 견디는 손실 개수
- 운영은 srvctl, 삭제는 순서대로

@PLAIN 퀴즈
- 1. ASM 인스턴스가 OPEN이 되지 않는 이유는?
- 2. CANDIDATE의 TOTAL_MB 0은 문제인가?
- 3. ASM_DISKGROUPS에 CRS가 없는 이유는?
- 4. 4GB 디스크 3장 High의 실제 저장량은?
- 5. SQL 마운트 후 ora.TEST.dg OFFLINE의 문제와 조치는?
- 6. drop diskgroup이 ORA-15073이면 다음 단계는?

@PLAIN 실습 개요
- 06-01  ASM 인스턴스 파악
- 06-03 ★  디스크 발견
- 06-04 ★  디스크그룹 생성
- 06-05  생성 오류 재현
- 06-07 ★  이중화 세 가지 (끝에 기준 상태로)
- 파일: RAC/06장/6장_실습_NN_*.txt
