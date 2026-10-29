@H1 제4장  ASM 인스턴스와 디스크그룹

@H2 4.1  학습 목표

@P 3장의 OCR과 Voting File은 +CRS 디스크그룹 안에 있었고, 그 디스크그룹은 ASM이 관리한다. 이 장은 ASM 인스턴스 자체와 디스크그룹을 다룬다. 설치 가이드 v2 부록 E로 추가한 실습용 후보 디스크 `/dev/asmdisk/test1~6`(4GB × 6)으로 디스크그룹을 만들고, 이중화를 비교하고, 마운트와 삭제의 규칙을 확인한다.

@B ASM 인스턴스와 데이터베이스 인스턴스의 차이를 INSTANCE_TYPE, 상태, 프로세스로 설명할 수 있다.
@B ASM_DISKSTRING, ASM_DISKGROUPS, ASM_POWER_LIMIT의 역할과 +CRS가 ASM_DISKGROUPS에 없는 이유를 말할 수 있다.
@B `V$ASM_DISK`의 HEADER_STATUS와 TOTAL_MB·OS_MB를 읽어 디스크 상태를 판단할 수 있다.
@B 디스크그룹을 만들고 ORA-15018 아래의 원인 코드(15029, 15031, 15167, 15237)를 구분할 수 있다.
@B External·Normal·High의 요건과 실제 저장 가능 용량, 장애 그룹의 의미를 설명할 수 있다.
@B SQL 마운트와 `srvctl start diskgroup`의 차이, ora.<이름>.dg 자원의 동작을 설명할 수 있다.
@B 언마운트와 삭제가 막히는 조건(ORA-15027, 15053, 15073)과 FORCE의 위험을 말할 수 있다.

@H2 4.2  ASM 인스턴스

@P ASM은 Oracle이 만든 볼륨 관리자이자 파일 시스템이다. 구현은 별도의 데몬이 아니라 Oracle 인스턴스다. SGA와 백그라운드 프로세스가 있고 SQL로 조작한다. 데이터베이스와 같은 커널을 쓰지만 데이터 파일은 하나도 열지 않는다.

@IMG 04_asminst.png | 그림 4-1. ASM 인스턴스와 데이터베이스 인스턴스 — 데이터베이스는 ASMB로 익스텐트 위치를 받아 디스크에 직접 I/O한다

@H3 4.2.1  데이터 파일이 없는 인스턴스

@CODE
[grid@rac1 ~]$ sqlplus / as sysasm
SYS@+ASM1> select instance_name, status, instance_role from v$instance;
INSTANCE_N STATUS    INSTANCE_ROLE
---------- --------- --------------
+ASM1      STARTED   UNKNOWN
SYS@+ASM1> select count(*) from v$datafile;
ORA-01507: database not mounted
@END

@TBL
항목 | ASM 인스턴스 | 데이터베이스 인스턴스
INSTANCE_TYPE | ASM | RDBMS
SID | +ASM1 / +ASM2 | racdb1 / racdb2
STATUS | STARTED | OPEN
INSTANCE_ROLE | UNKNOWN | PRIMARY_INSTANCE
데이터 파일 | 없음(ORA-01507) | 있음
접속 권한 | SYSASM | SYSDBA
OS 계정 · 프로세스 접두어 | grid · asm_ | oracle · ora_
@END

@B ASM 인스턴스는 마운트할 데이터베이스가 없어 항상 STARTED 상태다. `V$DATAFILE`을 조회하면 ORA-01507이 난다.
@B 인스턴스의 성격은 INSTANCE_TYPE 파라미터가 정한다. 바꿀 수 없다.
@B `GV$INSTANCE`는 ASM에서도 동작한다. +ASM1과 +ASM2가 두 행으로 나온다.

@H3 4.2.2  백그라운드 프로세스

@B `ps -u grid -o cmd | grep -c asm_`으로 세면 같은 노드의 데이터베이스 인스턴스(`ora_`)보다 훨씬 적다. SQL 처리, 옵티마이저 통계, 서비스 등록 같은 일이 없기 때문이다.
@B RBAL은 리밸런스를 조정하고, 실제 데이터 이동은 리밸런스 중에만 뜨는 ARB0, ARB1 같은 슬레이브가 한다(6장).
@B GMON은 디스크그룹 멤버십과 PST(Partner Status Table)를 관리한다. 3장에서 디스크를 내렸을 때 alert.log에 등장했다.
@B ASMB는 데이터베이스와 ASM을 잇는 채널이다. ASM 쪽 `asm_asmb_+ASM1`과 데이터베이스 쪽 `ora_asmb_racdb1`이 짝을 이룬다.
@B LMON, LMD0, LMS0, LCK0도 있다. +ASM1과 +ASM2가 같은 디스크그룹의 메타데이터를 공유하므로 메타데이터 블록의 갱신을 조정해야 한다.

@NOTE 데이터 I/O는 ASM을 거치지 않는다
데이터베이스는 ASMB로 파일의 익스텐트가 어느 디스크 어느 위치에 있는지만 받아 오고, 읽기와 쓰기는 직접 디스크에 한다. ASM 인스턴스는 메타데이터만 다룬다. 디스크 장치는 grid:asmadmin 소유(660)인데, 역할을 분리한 설치에서는 DB 홈의 oracle 실행 파일이 asmadmin 그룹으로 setgid되어 데이터베이스 프로세스가 장치를 직접 연다.
@END

@H3 4.2.3  ASM 파라미터

@CODE
NAME                   VALUE              ISDEFAULT
---------------------- ------------------ ---------
asm_diskgroups         DATA, FRA          FALSE
asm_diskstring         /dev/asmdisk/*     FALSE
asm_power_limit        1                  FALSE
cluster_database       TRUE               TRUE
instance_type          ASM                TRUE
@END

@B ASM_DISKSTRING은 ASM이 디스크를 찾는 경로 패턴이다. udev가 WWN 기준으로 만든 `/dev/asmdisk/*`만 지정했다.
@B ASM_DISKGROUPS는 인스턴스 기동 때 자동으로 마운트할 디스크그룹 목록이다. +CRS가 없는 것이 정상이다. +CRS는 OCR과 Voting File이 들어 있어 이 목록을 읽기 전부터 필요하므로 Clusterware가 직접 마운트한다.
@B ASM_POWER_LIMIT은 리밸런스 병렬도의 기본값이다. 범위는 0~1024이고 벗어나면 ORA-00068이다(6장).
@B ASM 파라미터는 ASM 인스턴스에서만 유효하다. racdb1에서 `alter system set asm_power_limit=4`를 실행하면 ORA-15021(not valid in RDBMS instance)이다.
@B ASM의 SPFILE도 ASM 안에 있다. `asmcmd spget`은 `+CRS/rac-cluster/ASMPARAMETERFILE/registry.253...`를 돌려준다.
@B `asmcmd dsget`은 두 줄을 보여 준다. parameter는 현재 인스턴스의 값, profile은 GPnP 프로필에 저장된 값이다. 둘이 다르면 재기동 뒤 디스크를 못 찾을 수 있다.

@BP asm_diskstring은 좁게 잡는다
`/dev/sd*`처럼 넓게 잡으면 ASM이 기동할 때마다 모든 블록 장치를 열어 헤더를 읽는다. 디스크가 많으면 기동이 느려지고 다른 용도의 디스크를 건드릴 위험도 생긴다. 전용 디렉터리만 지정한다.
@END

@H3 4.2.4  접속 권한과 기동 주체

@TBL
OS 그룹 | 권한 | 실습 환경
asmadmin | SYSASM: 디스크그룹 생성·삭제, 디스크 추가, 인스턴스 기동·정지 | grid
asmdba | SYSDBA for ASM: 데이터베이스가 ASM 파일을 쓰는 데 필요 | grid, oracle
asmoper | SYSOPER for ASM: 기동·정지 같은 운영 작업 | grid
@END

@B grid 계정으로 `sqlplus / as sysasm`에 OS 인증으로 접속한다. oracle 계정은 asmdba에 속해 데이터베이스 파일을 ASM에 둘 수 있지만 디스크그룹을 만들 수는 없다.
@B ASM 인스턴스는 OHAS 스택의 ora.asm 자원이다(2장). 기동과 정지는 Clusterware가 하고, 사람이 할 때는 `srvctl start asm -node rac1`, `srvctl status asm`을 쓴다.
@B 19c는 Flex ASM으로 구성된다. 데이터베이스 인스턴스는 ASM 네트워크(ASMNET1LSNR_ASM 리스너)로 ASM 인스턴스에 붙으며, 한 노드의 ASM 인스턴스에 문제가 생기면 다른 노드의 ASM 인스턴스로 옮겨 붙을 수 있다. `srvctl config asm`으로 ASM 리스너와 인스턴스 개수를 확인한다.
@B 디스크그룹 속성은 `V$ASM_ATTRIBUTE`로 본다. compatible.asm, compatible.rdbms, au_size, sector_size, disk_repair_time 같은 값이 디스크그룹마다 따로 있다. `asmcmd lsattr -l -G CRS`도 같은 정보를 보여 준다.

@CASE 한 노드에서만 새 디스크가 덜 보인 사례
2노드 클러스터에 디스크 6장을 추가한 뒤 rac1의 `V$ASM_DISK`에는 CANDIDATE가 6장, rac2에는 4장만 보였다. 그대로 디스크그룹을 만들었다면 rac2에서 마운트가 실패했을 것이다.
원인은 rac2의 udev 규칙 파일에 두 줄이 빠진 것이었다. 규칙 파일을 한 노드에서 만들어 모든 노드에 배포하고, 디스크그룹을 만들기 전에 모든 ASM 인스턴스에서 후보 디스크 수를 대조하는 것을 작업 절차에 넣었다.
@END

@H2 4.3  디스크 발견

@P ASM이 ASM_DISKSTRING 경로에서 찾은 디스크는 디스크그룹 소속과 상관없이 모두 `V$ASM_DISK`에 나온다.

@CODE
PATH                     NAME       HEADER_STATU MOUNT_S GROUP_NUMBER   TOTAL_MB      OS_MB
------------------------ ---------- ------------ ------- ------------ ---------- ----------
/dev/asmdisk/test1                  CANDIDATE    CLOSED             0          0       4096
/dev/asmdisk/test2                  CANDIDATE    CLOSED             0          0       4096
/dev/asmdisk/crs1        CRS_0000   MEMBER       CACHED             1       4096       4096
/dev/asmdisk/data1       DATA_0000  MEMBER       CACHED             2      20480      20480
@END

@B 설치 가이드 v2 부록 E로 붙인 test 디스크 6장은 CANDIDATE, 기존 crs·data·fra 8장은 MEMBER다. test 디스크의 udev 규칙도 같은 부록에서 만들었다.
@B CANDIDATE는 NAME이 비어 있다. 이름은 디스크그룹에 들어갈 때 붙는다.
@B MOUNT_STATUS CLOSED는 ASM이 헤더만 읽고 열어 두지 않았다는 뜻이다.
@B TOTAL_MB는 ASM이 쓸 수 있는 크기, OS_MB는 OS가 보고한 크기다. 디스크그룹에 들어가기 전에는 TOTAL_MB가 0이다. 디스크가 인식되지 않는다고 오해하기 쉬우므로 두 열을 함께 본다.

@IMG 04_header.png | 그림 4-2. HEADER_STATUS의 변화 — 디스크그룹에 들어가면 MEMBER, 정상적으로 빠져나오면 FORMER가 된다

@TBL
HEADER_STATUS | 뜻 | 새 디스크그룹에 넣을 수 있는가
CANDIDATE | 한 번도 쓰인 적 없는 디스크 | 가능
MEMBER | 현재 어떤 디스크그룹의 구성원 | FORCE 필요, 기존 데이터 파괴
FORMER | 디스크그룹에서 정상적으로 빠진 디스크 | 가능
PROVISIONED | 관리자가 ASM용으로 표시함 | 가능
FOREIGN | 다른 제품이 쓰는 디스크 | 불가
@END

@H3 4.3.1  두 노드가 같은 디스크를 보는가

@B 디스크그룹을 만들기 전에 rac2의 +ASM2에서도 같은 조회를 해 CANDIDATE 6장이 같은 경로로 보이는지 확인한다. 개수가 다르면 만든 뒤 그 노드에서 마운트가 실패한다.
@B 장치 이름은 노드마다 다를 수 있다. rac1의 crs1은 sdb, rac2의 crs1은 sda를 가리키지만 `/lib/udev/scsi_id -g -u -d`로 보면 WWN이 같다. udev 규칙을 WWN 기준으로 만든 이유다(설치 가이드 v2 4장).
@B 한 노드에서만 디스크가 덜 보이면 그 노드에서 `lsblk`, `ls -l /dev/asmdisk/`, WWN 순서로 확인한다.

@H2 4.4  디스크그룹 만들기

@P 디스크그룹 생성이 실패하면 첫 줄은 항상 ORA-15018(diskgroup cannot be created)이고, 실제 원인은 그 아래 줄에 있다.

@TBL
명령의 문제 | 원인 코드 | 뜻
MEMBER 디스크(/dev/asmdisk/data1) 지정 | ORA-15029 | 이미 이 인스턴스가 마운트한 디스크
없는 경로(/dev/asmdisk/nosuch) 지정 | ORA-15031 | 경로 패턴에 맞는 디스크가 없음
Normal에 디스크 1장 | ORA-15167 | 장애 그룹 2개 이상 필요(found only 1)
High에 장애 그룹 2개 | ORA-15167 | 장애 그룹 3개 이상 필요(found only 2)
CREATE에 disk_repair_time 지정 | ORA-15237 | CREATE 절에서 지정할 수 없는 속성
@END

@B ORA-15029가 나면 `V$ASM_DISK.GROUP_NUMBER`로 어느 디스크그룹 소속인지 확인한다. FORCE로 헤더를 덮어쓰면 그 디스크그룹의 데이터가 파괴된다.
@B CREATE에서 지정할 수 있는 속성은 compatible 계열, au_size, sector_size처럼 생성 시점에 고정되는 것이다. disk_repair_time은 만든 뒤 `ALTER DISKGROUP ... SET ATTRIBUTE`로 설정한다.

@H3 4.4.1  만들어 본다

@CODE
SYS@+ASM1> create diskgroup TEST external redundancy disk '/dev/asmdisk/test1'
  2  attribute 'compatible.asm'='19.0.0.0.0', 'compatible.rdbms'='19.0.0.0.0';
Diskgroup created.
@END

@B 생성 직후 TEST는 4096MB 중 수십 MB를 메타데이터에 쓰고 나머지가 FREE_MB로 남는다.
@B test1은 CANDIDATE에서 MEMBER로 바뀌고 NAME TEST_0000, MOUNT_STATUS CACHED가 된다. 이름을 지정하지 않으면 디스크그룹 이름 뒤에 네 자리 번호를 붙인다.
@B compatible.asm은 디스크그룹이 쓸 수 있는 ASM 기능의 수준, compatible.rdbms는 이 디스크그룹을 쓸 수 있는 데이터베이스의 최저 버전이다. 3장에서 +CRS의 compatible.rdbms 10.1 때문에 디스크 OFFLINE이 막혔다. 직접 만들 때는 처음부터 지정한다.
@B AU(Allocation Unit) 크기도 생성 때 정해진다. 실습 환경은 +CRS가 4MB, +DATA와 +FRA가 1MB다. `asmcmd lsdg`의 AU 열로 확인한다.

@CODE
ASMCMD> lsdg
State    Type    Rebal  Sector  Block       AU  Total_MB  Free_MB  Req_mir_free_MB  Usable_file_MB  Offline_disks  Voting_files  Name
MOUNTED  NORMAL  N         512   4096  4194304     12288    11324             4096            3614              0             Y  CRS/
MOUNTED  EXTERN  N         512   4096  1048576     61440    56956                0           56956              0             N  DATA/
MOUNTED  EXTERN  N         512   4096  1048576      4096     3826                0            3826              0             N  TEST/
@END

@B `asmcmd lsdg`는 `V$ASM_DISKGROUP`의 주요 열을 한 줄에 보여 준다. Rebal은 리밸런스 진행 여부, Req_mir_free_MB와 Usable_file_MB는 이중화를 고려한 여유 공간, Voting_files는 Voting File 보유 여부다.
@B +CRS만 Req_mir_free_MB가 잡혀 있다. Normal이고 OCR과 백업 같은 데이터가 들어 있어 디스크 하나 손실에 대비한 공간을 남겨 둔다. External인 DATA와 TEST는 0이다.

@BP compatible은 만들 때 정한다
compatible 속성은 올릴 수만 있고 낮출 수 없다. 모든 데이터베이스가 19c라면 처음부터 19.0.0.0.0으로 만든다. 구버전 데이터베이스가 붙을 가능성이 있다면 compatible.rdbms는 그 버전에 맞춘다.
@END

@H3 4.4.2  만든 노드에서만 마운트된다

@P rac1에서 만든 TEST를 rac2의 +ASM2에서 보면 DISMOUNTED이고 TOTAL_MB가 0이다. 디스크그룹의 존재는 전파되지만 마운트는 자동으로 되지 않는다.

@IMG 04_layers.png | 그림 4-3. 두 계층의 상태 — SQL로 마운트하면 ASM은 MOUNTED여도 Clusterware 자원은 OFFLINE으로 남는다

@CODE
[root@rac1 ~]# crsctl status resource ora.TEST.dg -t
ora.TEST.dg(ora.asmgroup)
      1        OFFLINE OFFLINE                               STABLE
      2        OFFLINE OFFLINE                               STABLE
      3        OFFLINE OFFLINE                               STABLE
[grid@rac1 ~]$ srvctl start diskgroup -g TEST
[grid@rac1 ~]$ srvctl status diskgroup -g TEST
Disk Group TEST is running on rac1,rac2
@END

@B 디스크그룹을 만들면 ora.TEST.dg 자원이 자동으로 생긴다. 그러나 SQL로 한 마운트는 자원 상태에 반영되지 않아 TARGET과 STATE가 OFFLINE이다.
@B TARGET이 OFFLINE이면 노드가 재기동할 때 Clusterware가 이 디스크그룹을 올리지 않는다. 그 안에 파일이 있는 데이터베이스는 기동에 실패한다.
@B `srvctl start diskgroup -g TEST`로 올리면 TARGET과 STATE가 모두 ONLINE이 되고 두 노드에 마운트된다. 세 번째 행이 OFFLINE인 것은 ora.asmgroup의 카디널리티가 3이고 노드가 2개이기 때문이다.
@B 없는 디스크그룹을 조회하면 PRCA-1000(ASM 계층)과 PRCR-1001(Clusterware 계층)이 함께 나온다. 삭제 뒤 이 두 줄이 나오면 자원까지 정리된 것이다.

@H2 4.5  이중화 세 가지

@P test1~6으로 External·Normal·High 디스크그룹을 하나씩 만들어 용량을 비교한다. 디스크는 모두 4096MB다.

@CODE
SYS@+ASM1> create diskgroup TESTH high redundancy
  2  failgroup fg1 disk '/dev/asmdisk/test4'
  3  failgroup fg2 disk '/dev/asmdisk/test5'
  4  failgroup fg3 disk '/dev/asmdisk/test6'
  5  attribute 'compatible.asm'='19.0.0.0.0';
@END

@IMG 04_redundancy.png | 그림 4-4. 이중화와 용량 — 디스크를 1·2·3장 넣어도 담을 수 있는 양은 4GB 남짓으로 같다

@TBL
디스크그룹 | 이중화 | 디스크 | TOTAL_MB | USABLE_FILE_MB | 견디는 손실
TEST | External | test1 | 4096 | 3998 | 0
TESTN | Normal | test2, test3 | 8192 | 4038 | 장애 그룹 1개
TESTH | High | test4, test5, test6 | 12288 | 4037 | 장애 그룹 2개
@END

@B 디스크를 두 배, 세 배 넣었지만 담을 수 있는 양은 같다. 늘어난 것은 견딜 수 있는 손실 개수다.
@B External은 ASM이 미러링하지 않고 스토리지 RAID에 맡긴다. Normal은 2벌, High는 3벌을 서로 다른 장애 그룹에 둔다.
@B REQUIRED_MIRROR_FREE_MB는 장애 그룹 하나를 잃었을 때 미러를 다시 만들기 위해 남겨 둘 공간이다. 빈 디스크그룹이라 지금은 0이다. 데이터가 차면 이 값이 커지고 USABLE_FILE_MB가 음수가 되면 디스크를 하나 더 잃었을 때 복구할 수 없다는 경고다(6장).

@H3 4.5.1  장애 그룹

@B 장애 그룹을 지정하지 않으면 디스크마다 별도의 장애 그룹이 만들어지고 디스크 이름(TEST_0000)을 그대로 쓴다. TESTN, TESTH는 FG1~FG3으로 지정했다.
@B 장애 그룹은 함께 죽는 단위다. 같은 컨트롤러, 같은 랙의 디스크는 같은 장애 그룹으로 묶고 CTRL_A, RACK_1처럼 실제 경계를 드러내는 이름을 쓴다.
@B FAILGROUP_TYPE은 REGULAR와 QUORUM이 있다. QUORUM 장애 그룹은 데이터 없이 Voting File만 담는다. 두 사이트에 걸친 확장 클러스터에서 제3의 위치에 둔다.
@B 실습 환경의 test 디스크는 모두 호스트의 D:\RAC\SHARED에 있다. 물리적으로는 장애 그룹이 하나이고 FG1~FG3은 동작을 관찰하기 위한 논리적 구분이다.

@TBL
상황 | 권장 | 이유
RAID로 보호된 엔터프라이즈 스토리지 | External | 이중 보호는 용량과 쓰기만 늘린다
JBOD·로컬 디스크 | Normal 이상 | ASM이 유일한 보호 수단
OCR·Voting File 디스크그룹 | Normal 이상 | Voting File 3개로 한 장 손실을 견딘다
두 사이트 확장 클러스터 | Normal + QUORUM | 사이트별 장애 그룹과 제3의 투표 위치
@END

@B 실습 환경의 +CRS가 Normal인 이유는 가상 디스크에 RAID 보호가 없고 OCR과 Voting File이 들어 있기 때문이다. +DATA와 +FRA는 학습 환경이라 용량을 우선해 External로 만들었다.
@B RAID 위에 Normal을 얹으면 물리 용량의 4분의 1만 남는다. RAID에서 절반, ASM에서 다시 절반이고 쓰기도 두 배가 된다.

@H2 4.6  마운트·언마운트·삭제

@P 디스크그룹 안에 데이터베이스 파일이 생기면 언마운트와 삭제에 순서가 생긴다.

@H3 4.6.1  사용 중인 디스크그룹

@B racdb1에서 `create tablespace ts_test datafile '+TEST' size 500M`을 실행하면 파일은 `+TEST/RACDB/DATAFILE/ts_test.256...`으로 만들어진다.
@B 데이터베이스 alert.log에 `dependency between database racdb and diskgroup resource ora.TEST.dg is established`가 남는다. 이제 Clusterware는 racdb를 띄우기 전에 ora.TEST.dg를 띄운다.
@B 이 상태에서 `alter diskgroup TEST dismount`는 ORA-15027(active use of diskgroup precludes its dismount)로 거절된다. 데이터베이스가 파일을 열고 있으므로 정상적인 보호다.

@IMG 04_dismount.png | 그림 4-5. 언마운트와 삭제의 순서 — 데이터베이스 쪽을 먼저 정리하고, 모든 ASM 인스턴스에서 내린 뒤 지운다

@H3 4.6.2  FORCE의 결과

@B `dismount force`는 사용 중이어도 언마운트한다. 그런데 데이터베이스는 그 데이터 파일을 계속 ONLINE으로 알고 있다. 접근하는 첫 쿼리부터 오류가 번진다.
@B 데이터베이스 alert.log에는 AMB1 프로세스가 다른 노드의 +ASM2에 붙어 ASM 상태를 재구성하는 기록이 남는다. 19c의 Flex ASM 구성에서는 한 ASM 인스턴스에서 디스크그룹이 사라지면 다른 노드의 ASM 인스턴스로 옮겨 붙는다.
@B 실습 환경이 아니라면 순서를 지킨다. 데이터베이스에서 테이블스페이스를 오프라인으로 내리거나 삭제한 뒤 ASM에서 언마운트한다.

@H3 4.6.3  삭제가 막히는 두 조건

@CODE
SYS@+ASM1> drop diskgroup TEST;
ORA-15039: diskgroup not dropped
ORA-15053: diskgroup "TEST" contains existing files
-- 테이블스페이스 삭제 후
SYS@+ASM1> drop diskgroup TEST;
ORA-15039: diskgroup not dropped
ORA-15073: diskgroup TEST is mounted by another ASM instance
@END

@B ORA-15053은 파일이 남아 있다는 뜻이다. 데이터베이스에서 `drop tablespace ts_test including contents and datafiles`로 먼저 지운다. 파일째 지우려면 `drop diskgroup ... including contents`를 쓴다.
@B ORA-15073은 다른 ASM 인스턴스가 마운트하고 있다는 뜻이다. rac2의 +ASM2에서 `alter diskgroup TEST dismount`한 뒤, 지우는 인스턴스 하나만 마운트한 상태에서 삭제한다.
@B 첫 줄 ORA-15039는 매번 같고 둘째 줄의 원인이 매번 다르다. ASM 오류는 둘째 줄부터 읽는다.

@H3 4.6.4  삭제 후

@B 지운 디스크그룹의 디스크는 FORMER가 된다. CANDIDATE와 마찬가지로 FORCE 없이 새 디스크그룹에 넣을 수 있다. FORMER는 전에 쓰인 적이 있다는 표시이므로 남의 데이터가 있었는지 한 번 확인할 단서가 된다.
@B SQL로 지웠어도 ora.TEST.dg 자원은 함께 사라진다. 생성과 삭제는 Clusterware에 전파되고, 마운트와 언마운트는 전파되지 않는다.
@B 강제 삭제나 ASM 비정상 종료 뒤 자원만 남는 경우가 있다. 이때는 `srvctl remove diskgroup -g 이름`으로 자원만 지운다.
@B 실습을 마치면 TEST, TESTN, TESTH를 지우고 `V$ASM_DISK`에서 test1~6이 FORMER 6, 기존 디스크가 MEMBER 8인지 확인한다. 5장과 6장이 이 디스크를 다시 쓴다.

@H2 4.7  요약

@B ASM은 INSTANCE_TYPE=ASM인 Oracle 인스턴스다. 항상 STARTED이고 데이터 파일이 없으며 메타데이터만 다룬다. 데이터 I/O는 데이터베이스가 직접 한다.
@B ASM_DISKSTRING은 디스크 탐색 경로, ASM_DISKGROUPS는 자동 마운트 목록이다. +CRS는 Clusterware가 직접 마운트한다. ASM 파라미터는 RDBMS 인스턴스에서 설정할 수 없다(ORA-15021).
@B `V$ASM_DISK`에서 CANDIDATE·FORMER는 바로 쓸 수 있고 MEMBER는 쓰면 안 된다. 그룹 밖 디스크는 TOTAL_MB가 0이다.
@B 생성 실패는 ORA-15018 아래의 원인 코드로 판단한다. Normal은 장애 그룹 2개, High는 3개가 최소다.
@B compatible 속성은 만들 때 정한다. 올릴 수만 있다.
@B SQL 마운트는 Clusterware 자원에 반영되지 않는다. 운영에서는 `srvctl start/stop diskgroup`을 쓴다.
@B 이중화가 늘리는 것은 용량이 아니라 견딜 수 있는 손실 개수다.
@B 사용 중이면 ORA-15027, 파일이 있으면 ORA-15053, 다른 인스턴스가 마운트 중이면 ORA-15073으로 막힌다.

@H2 4.8  퀴즈

@QUIZ 퀴즈
1. ASM 인스턴스의 STATUS가 OPEN이 되지 않는 이유는?
2. CANDIDATE 디스크의 TOTAL_MB가 0이고 OS_MB가 4096이다. 디스크에 문제가 있는가?
3. ASM_DISKGROUPS에 CRS가 없다. 설정 누락인가?
4. 디스크 3장으로 만든 High 디스크그룹(디스크당 4GB)에 실제로 담을 수 있는 데이터는 대략 얼마인가?
5. SQL로 두 노드에 마운트했는데 ora.TEST.dg가 OFFLINE이다. 그대로 두면 무엇이 문제이며 어떻게 맞추는가?
6. `drop diskgroup`이 ORA-15073으로 막혔다. 다음 단계는?
@END

@NOTE 정답과 해설
1. 마운트할 데이터베이스가 없다. ASM 인스턴스는 STARTED 상태로 디스크그룹 메타데이터만 관리한다.
2. 아니다. TOTAL_MB는 ASM이 쓸 수 있는 크기라 디스크그룹에 들어가기 전에는 0이다. OS_MB가 실제 크기다.
3. 아니다. +CRS에는 OCR과 Voting File이 있어 ASM_DISKGROUPS를 읽기 전에 Clusterware가 직접 마운트한다.
4. 약 4GB. 3벌 미러라 12GB 중 3분의 1이다(USABLE_FILE_MB 4037).
5. TARGET이 OFFLINE이라 노드 재기동 때 디스크그룹이 올라오지 않고, 그 안에 파일이 있는 데이터베이스가 기동에 실패한다. `srvctl start diskgroup -g TEST`로 맞춘다.
6. 다른 노드의 ASM 인스턴스(+ASM2)에서 언마운트한 뒤 다시 삭제한다.
@END

@H2 4.9  실습 개요

@P 이 장의 실습은 설치 가이드 v2 부록 E로 추가한 test1~6 디스크만 쓴다. 두 노드에서 `ls -l /dev/asmdisk/test*`로 여섯 장이 보이는지 먼저 확인한다. crs·data·fra 디스크는 건드리지 않는다. 실습 번호는 폴더 번호와 파일 번호를 이은 것이다.

@TBL
실습 | 파일 | 목적
06-01 | RAC/06장/6장_실습_01_ASM인스턴스파악.txt | ASM과 DB 인스턴스를 나란히 조회하고 ASM 고유 프로세스를 확인한다
06-03 ★ | RAC/06장/6장_실습_03_디스크발견.txt | HEADER_STATUS와 TOTAL_MB·OS_MB를 읽고 두 노드가 같은 디스크를 보는지 확인한다
06-04 ★ | RAC/06장/6장_실습_04_디스크그룹생성.txt | TEST를 만들어 양 노드에 마운트하고 자원 상태를 srvctl로 맞춘다
06-05 | RAC/06장/6장_실습_05_생성오류재현.txt | ORA-15029·15031·15167·15237을 재현하고 원인 코드를 읽는다
06-07 ★ | RAC/06장/6장_실습_07_이중화세가지.txt | External·Normal·High를 만들어 용량과 장애 그룹을 비교하고 정리한다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다. 스냅샷이 필요한 실습은 없다.
@B 수료 후 자습: 6장_실습_02_ASM파라미터, 6장_실습_06_마운트와언마운트.
@B 실습 06-07의 끝에서 TEST·TESTN·TESTH를 모두 지우고 test 디스크가 FORMER 6장인지 확인한다.
