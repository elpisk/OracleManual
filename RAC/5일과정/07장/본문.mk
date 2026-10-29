@H1 제7장  ASM 뷰와 asmcmd

@H2 7.1  학습 목표

@P 4장부터 6장까지 ASM을 만들고 늘리고 부수면서 상태를 여러 번 확인했다. 이 장은 그 확인에 쓴 도구 자체를 다룬다. ASM을 보는 창은 SQL의 `V$ASM_*` 뷰와 셸의 asmcmd 두 가지이고, 같은 값을 보되 답하기 좋은 질문이 다르다. 마지막 절에서는 용량 지표 `USABLE_FILE_MB`를 음수까지 끌어내려 그 뜻을 확인한다.

@B ASM 인스턴스에 `DBA_` 뷰가 없는 이유와 `V$ASM_*` 뷰 가운데 반복해 쓰는 다섯 개가 답하는 질문을 말할 수 있다.
@B `V$`와 `GV$`의 차이를 ASM 클라이언트 조회로 설명하고, 두 노드의 대칭이 깨진 것을 이상 신호로 읽을 수 있다.
@B asmcmd의 접속 방식과 ls·du·lsof·lsct·lsdsk·iostat·spget·dsget의 쓰임을 안다.
@B ASMCMD-8102를 만났을 때 계층을 내려가 원인을 OSASM 그룹 소속으로 좁힐 수 있다.
@B ASMCA 무인 모드로 디스크그룹을 만드는 명령의 형태를 안다.
@B `USABLE_FILE_MB`가 음수일 때 무엇이 가능하고 무엇이 위험한지 설명할 수 있다.

@H2 7.2  ASM을 보는 두 창

@P ASM 인스턴스는 데이터베이스 인스턴스와 같은 커널을 쓴다. SGA와 백그라운드 프로세스가 있고 SQL을 파싱한다. 다만 열어 둔 데이터베이스가 없어서 데이터 딕셔너리도, 테이블도, 사용자도 없다.

@IMG 07_windows.png | 그림 7-1. ASM을 보는 두 창 — SQL과 asmcmd 모두 ASM 인스턴스 메모리의 V$ 정보를 읽는다

@H3 7.2.1  왜 V$뿐인가

@B ASM이 아는 것은 모두 메모리에서 바로 읽는 `V$ASM_` 뷰에 들어 있다. `DBA_` 계열 뷰는 딕셔너리가 있어야 하므로 ASM 인스턴스에는 없다.
@B SQL로 보려면 `sqlplus / as sysasm`으로 접속하고 열 이름을 알아야 한다. 디스크그룹 여유 공간 하나 보려고 매번 이 절차를 밟기는 번거롭다.
@B asmcmd는 그 번거로움을 줄인 셸이다. 내부적으로 같은 뷰를 조회하고 결과를 ls·du 같은 익숙한 명령 형태로 보여 준다.

@H3 7.2.2  같은 값을 두 창으로

@CODE
SYS@+ASM1> select name, type, total_mb, free_mb,
  2         required_mirror_free_mb req_mf, usable_file_mb usable
  3    from v$asm_diskgroup order by group_number;
NAME     TYPE     TOTAL_MB    FREE_MB     REQ_MF     USABLE
CRS      NORMAL      12288      11324       4096       3614
[grid@rac1 ~]$ asmcmd lsdg
State    Type    Rebal       AU  Total_MB  Free_MB  Req_mir_free_MB  Usable_file_MB  Voting_files  Name
MOUNTED  NORMAL  N      4194304     12288    11324             4096            3614             Y  CRS/
@END

@B 숫자가 같다. `asmcmd lsdg`는 `V$ASM_DISKGROUP`을 조회해 표로 찍어 주는 래퍼다.
@B asmcmd 쪽은 AU 크기와 Voting_files 열을 함께 보여 준다. +CRS의 AU는 4MB(4194304바이트), +DATA·+FRA는 1MB다. 설치 관리자가 만든 +CRS와 나중에 SQL로 만든 디스크그룹의 기본값이 다르고, AU 크기는 생성 뒤 바꿀 수 없다.

@TBL
질문 | 알맞은 창 | 이유
지금 여유 공간이 얼마인가 | asmcmd lsdg | 한 줄로 끝나고 사람이 읽기 좋다
여유가 일정 값 아래인 디스크그룹만 | SQL | 조건과 계산을 걸 수 있다
감시 스크립트 | SQL | asmcmd 출력은 버전마다 열 배치가 달라 파싱이 깨진다
파일을 경로처럼 둘러보기 | asmcmd ls·du | 디렉터리 계층을 그대로 보여 준다
두 노드를 한 번에 | SQL의 GV$ | asmcmd는 한 인스턴스에만 붙는다
@END

@H2 7.3  V$ASM_* 뷰 지도

@P 19c ASM 인스턴스의 `V$FIXED_VIEW_DEFINITION`에는 `V$ASM`으로 시작하는 뷰가 50개 있다. 그중 17개는 이름에 ACFS가 들어간 클러스터 파일 시스템용이고, 남은 33개 가운데 일상에서 반복해 쓰는 것은 다섯 개 남짓이다.

@IMG 07_viewmap.png | 그림 7-2. 자주 쓰는 다섯 뷰와 각각이 답하는 질문 — 위에서 아래로 갈수록 단위가 작고 시점에 민감하다

@TBL
뷰 | 한 행의 단위 | 답하는 질문
V$ASM_DISKGROUP | 디스크그룹 | 공간이 얼마나 남았나, 마운트되었나
V$ASM_DISK | 디스크 한 장 | 어떤 디스크가 어디 붙어 있고 상태는 어떤가
V$ASM_FILE | ASM 파일 하나 | 무엇이 얼마나 들어 있나
V$ASM_CLIENT | 접속한 클라이언트 | 누가 이 ASM을 쓰고 있나
V$ASM_OPERATION | 진행 중인 작업 | 지금 무슨 작업이 돌고 있나
@END

@B 보조로 쓰는 뷰로 `V$ASM_ATTRIBUTE`(디스크그룹 속성, 6장의 disk_repair_time), `V$ASM_TEMPLATE`(5장의 템플릿), `V$ASM_ALIAS`(별칭과 디렉터리)가 있다.
@B AUDIT·SPARSE·FILEGROUP·QUOTAGROUP·VOLUME·FILESYSTEM 계열은 해당 기능을 쓸 때만 행이 생긴다. 이 랩에서는 모두 0행이다. 뷰가 있는 것과 데이터가 있는 것은 별개다.
@B `V$ASM_OPERATION`이 0행이면 지금 진행 중인 작업이 없다는 답이다. 같은 세션에서 `V$ASM_DISKGROUP`을 조회해 행이 나오면 접속과 권한은 정상이다.

@H3 7.3.1  V$ASM_DISK — TOTAL_MB와 OS_MB

@CODE
        GN         DN NAME         PATH                 HEADER_STATU MOUNT_S STATE      TOTAL_MB    FREE_MB
---------- ---------- ------------ -------------------- ------------ ------- -------- ---------- ----------
         0          0              /dev/asmdisk/test2   FORMER       CLOSED  NORMAL            0          0
         1          0 CRS_0000     /dev/asmdisk/crs1    MEMBER       CACHED  NORMAL         4096       3772
         2          0 DATA_0000    /dev/asmdisk/data1   MEMBER       CACHED  NORMAL        20480      18971
@END

@B `GROUP_NUMBER`가 0인 디스크는 어느 디스크그룹에도 속하지 않는다. test1~6이 여기 있다. ASM 디스크 이름은 디스크그룹에 들어갈 때 붙으므로 소속이 없으면 `NAME`도 비어 있다.
@B 소속 없는 디스크의 `TOTAL_MB`는 0이다. 이 열은 ASM이 쓰는 공간이고 물리 크기는 `OS_MB` 열에 있다. 디스크를 추가하기 전 크기를 확인할 때는 `OS_MB`를 본다.

@H3 7.3.2  V$ASM_FILE — 무엇이 들어 있나

@CODE
SYS@+ASM1> select group_number gn, type, count(*) cnt, round(sum(bytes)/1024/1024) mb
  2    from v$asm_file group by group_number, type order by 1,2;
        GN TYPE                        CNT         MB
         1 OCRFILE                       1        158
         2 DATAFILE                     13       3445
         2 ONLINELOG                     4        800
         3 CONTROLFILE                   1         19
         3 ONLINELOG                     4        800
@END

@B 그룹 1(+CRS)에는 OCR 파일과 OCR 백업, ASM의 SPFILE·암호 파일만 있고 데이터베이스 파일은 없다.
@B 그룹 2(+DATA)에는 데이터 파일 13개를 포함한 본체가 있다. CDB$ROOT, PDB$SEED, RACPDB1이 각자 SYSTEM·SYSAUX를 가지고 UNDO가 인스턴스마다 있어 개수가 늘었다.
@B 컨트롤 파일과 온라인 리두는 +DATA와 +FRA에 한 벌씩 있다. 디스크그룹 하나를 잃어도 남는 다중화다. 데이터 파일은 +DATA에만 있으며 다중화가 아니라 백업 대상이다.

@H2 7.4  V$와 GV$ — 두 ASM 인스턴스

@P 디스크그룹 공간처럼 두 ASM 인스턴스가 같은 값을 갖는 정보는 어느 쪽에서 봐도 같다. 누가 접속해 있는가처럼 인스턴스마다 답이 다른 질문은 `GV$`로 봐야 한다.

@IMG 07_gvclient.png | 그림 7-3. V$ASM_CLIENT와 GV$ASM_CLIENT — 각 DB 인스턴스는 자기 노드의 ASM 인스턴스에 붙는다

@CODE
SYS@+ASM1> select inst_id, group_number, instance_name, db_name, status
  2    from gv$asm_client order by inst_id, group_number, instance_name;
   INST_ID GROUP_NUMBER INSTANCE_NAME     DB_NAME    STATUS
         1            1 +ASM1             +ASM       CONNECTED
         1            1 rac1.localdomain  _OCR       CONNECTED
         1            2 racdb1            racdb      CONNECTED
         2            1 +ASM2             +ASM       CONNECTED
         2            1 rac2.localdomain  _OCR       CONNECTED
         2            2 racdb2            racdb      CONNECTED
...
10 rows selected.
@END

@B 같은 질문을 `V$ASM_CLIENT`로 하면 5행이 나오고 racdb2가 없다. racdb2는 rac2의 +ASM2에 붙어 있기 때문이다.
@B 클라이언트는 셋이다. racdb 인스턴스, ASM 자신(+CRS의 SPFILE·암호 파일을 열어서), 그리고 `_OCR`이다. `_OCR`은 CRS 데몬이며 OCR이 +CRS에 있어 ASM의 클라이언트로 잡힌다. 그래서 INSTANCE_NAME 자리에 호스트명이 들어간다.
@B 두 노드의 행이 대칭이어야 정상이다. INST_ID 2에 racdb2가 없다면 rac2의 DB 인스턴스가 내려가 있거나 다른 노드의 ASM에 붙은 것이다.

@BP GV$는 진단 중에 걸릴 수 있다
`GV$` 조회는 다른 인스턴스에 병렬 슬레이브를 띄워 인터커넥트로 결과를 모은다. 한 노드가 응답하지 않는 장애 상황에서는 조회 자체가 멈출 수 있다. 그럴 때는 각 노드에서 `V$`를 따로 본다.
@END

@H2 7.5  asmcmd 명령 체계

@P asmcmd는 인자 없이 실행하면 `ASMCMD>` 대화형 셸이 뜨고, 명령을 인자로 주면 한 번 실행하고 끝난다. 접속 방식은 도움말에 적혀 있다.

@H3 7.5.1  무엇에 어떻게 붙는가

@B `ORACLE_HOME`과 `ORACLE_SID`가 접속할 인스턴스를 정한다. grid 계정에서 rac1이면 Grid 홈과 +ASM1이다.
@B 접속은 `SQLPLUS / AS SYSASM`과 같은 bequeath 방식이다. 리스너를 거치지 않는 로컬 OS 인증이다.
@B 실행 계정은 OSASM 그룹의 구성원이어야 한다. 이 조건이 7.6절 오류의 원인이 된다.
@B Flex ASM이 켜져 있으면 클러스터의 아무 ASM 인스턴스에나 붙을 수 있다고 도움말에 적혀 있다.

@H3 7.5.2  명령별 쓰임

@TBL
명령 | 보는 것 | 대응 뷰 · 비고
lsdg | 디스크그룹 공간·상태·Rebal | V$ASM_DISKGROUP
ls +DATA/RACDB | 디렉터리 계층 | V$ASM_ALIAS. 파일 종류별 디렉터리와 PDB GUID 디렉터리
du +DATA/RACDB | 사용량 합계 (Used_MB, Mirror_used_MB) | Normal이면 Mirror_used_MB가 두 배
lsof | 인스턴스별로 열린 파일 | 접속한 ASM 인스턴스 기준
lsct DATA | 디스크그룹의 클라이언트 | V$ASM_CLIENT
lsdsk -k | 디스크와 OS_MB | V$ASM_DISK
iostat -G DATA -t | 디스크별 누적 읽기·쓰기와 시간 | V$ASM_DISK_IOSTAT
spget / dsget | ASM SPFILE 위치 / 디스크 검색 문자열 | dsget은 parameter와 profile 두 값
@END

@CODE
ASMCMD> ls +DATA/RACDB
5A566B559A25734BE06365E110AC68E0/
5A569448ED6C2E8DE06365E110ACB045/
86B637B62FE07A65E053F706E80A27CA/
CONTROLFILE/
DATAFILE/
ONLINELOG/
PARAMETERFILE/
PASSWORD/
TEMPFILE/
ASMCMD> du +DATA/RACDB
Used_MB      Mirror_used_MB
   4412                4412
@END

@B +DATA 바로 아래에는 데이터베이스 이름 디렉터리 RACDB 하나가 있고, 그 아래 파일 종류별 디렉터리(5장의 OMF 구조)와 PDB GUID 디렉터리가 섞여 있다.
@B +DATA는 External이라 du의 두 값이 같다. Normal 디스크그룹에서는 Mirror_used_MB가 Used_MB의 두 배로 나온다.

@H3 7.5.3  읽을 때 주의할 점

@B `ls +DATA/RACDB` 아래 32자리 16진수 디렉터리는 PDB GUID다. 그런데 이름은 파일이 만들어지던 순간의 GUID라 현재 PDB GUID와 다를 수 있다. PDB$SEED의 데이터 파일과 템프 파일이 서로 다른 GUID 디렉터리에 나뉘어 있는 것이 그 예다. PDB는 디렉터리 이름이 아니라 `V$DATAFILE`의 `CON_ID`로 역추적한다.
@B `lsof`에는 racdb1이 연 파일만 나온다. undotbs1과 undotbs2가 둘 다 racdb1에 열려 있는데, 인스턴스 복구 때 다른 인스턴스의 UNDO를 읽어야 하므로 파일은 열어 둔다.
@B `lsdsk --candidate`는 이름과 달리 HEADER_STATUS가 CANDIDATE인 디스크가 아니라 디스크그룹에 속하지 않은 디스크를 보여 준다. FORMER인 test1~6이 모두 나오지만 SQL로 `header_status='CANDIDATE'`를 조회하면 0행이다.
@B `iostat`은 절대값보다 디스크 사이의 균형을 본다. 읽은 양이 적은 디스크가 시간은 더 걸렸다면 그 디스크만 경로나 장비가 다른지 의심한다.
@B `dsget`의 parameter(현재 `asm_diskstring`)와 profile(GPnP 프로파일 값)이 다르면 다음 기동 때 디스크를 찾지 못할 수 있다. 이 랩은 둘 다 `/dev/asmdisk/*`다.

@CODE
[grid@rac1 ~]$ asmcmd spget
+CRS/rac-cluster/ASMPARAMETERFILE/registry.253.1242760241
[grid@rac1 ~]$ asmcmd dsget
parameter:/dev/asmdisk/*
profile:/dev/asmdisk/*
@END

@H2 7.6  asmcmd가 거부될 때 — 계정과 권한

@P asmcmd는 grid 계정으로 쓰는 것이 정석이다. oracle 계정에서 Grid 홈과 +ASM1을 지정해 실행하면 오류가 나는데, 메시지가 가리키는 곳과 원인이 있는 곳이 다르다.

@IMG 07_auth.png | 그림 7-4. ASMCMD-8102를 계층별로 내려가 원인을 찾는 순서 — 메시지는 연결 문제를 말하지만 원인은 그룹 소속이다

@H3 7.6.1  오류 재현

@CODE
[oracle@rac1 ~]$ export ORACLE_HOME=/u01/app/19.3.0/grid
[oracle@rac1 ~]$ export ORACLE_SID=+ASM1
[oracle@rac1 ~]$ $ORACLE_HOME/bin/asmcmd lsdg
Connected to an idle instance.
ASMCMD-8102: no connection to Oracle ASM; command requires Oracle ASM to run
[oracle@rac1 ~]$ $ORACLE_HOME/bin/sqlplus -s / as sysasm
ERROR:
ORA-01017: invalid username/password; logon denied
@END

@B +ASM1은 정상으로 돌고 있는데 "idle instance"라고 나온다. 메시지만 믿으면 ASM이 죽었다고 판단하게 된다.
@B asmcmd는 `sqlplus / as sysasm`을 대신하는 도구이므로 한 계층 내려가 같은 계정으로 sqlplus를 실행한다. 진짜 오류 ORA-01017(인증 거부)이 나온다.

@H3 7.6.2  OSASM 그룹 확인

@CODE
[grid@rac1 ~]$ $ORACLE_HOME/bin/osdbagrp -a
asmadmin
[root@rac1 ~]# id -nG oracle
oinstall dba oper backupdba dgdba kmdba racdba asmdba
[root@rac1 ~]# id -nG grid
oinstall dba asmdba asmoper asmadmin
@END

@B `/ as sysasm`은 OS 인증이다. Grid 홈에 컴파일된 OSASM 그룹은 `osdbagrp -a`가 알려 주고, 이 랩에서는 asmadmin이다.
@B asmadmin의 구성원은 grid뿐이다. oracle은 asmdba까지만 가진다. asmdba는 데이터베이스가 ASM 파일을 읽고 쓰는 권한이라 racdb는 +DATA를 정상으로 쓰지만, oracle 계정으로 ASM 관리 명령은 낼 수 없다.

@TBL
계정 | asmadmin 소속 | asmcmd lsdg | 이유
grid | 예 | 성공 | OSASM 그룹 구성원
oracle | 아니오 (asmdba만) | ASMCMD-8102 | OS 인증에서 거부, sqlplus로는 ORA-01017
root | 아니오 | 성공 | Grid 홈 oracle 바이너리의 setuid와 uid 0
@END

@B root는 asmadmin에 없는데도 성공한다. Grid 홈의 `bin/oracle`은 `-rwsr-s--x` 권한으로 setuid가 붙어 있고, uid 0인 root는 그룹 소속 검사를 통과한다. 일반 계정에만 "asmadmin 소속이어야 한다"는 규칙이 걸린다.
@B 된다고 해서 root로 작업하지 않는다. 감사 기록에 root로 남아 실제 작업자를 알 수 없고, root가 만든 로그·트레이스 파일 때문에 나중에 grid가 같은 디렉터리에 쓰지 못하는 문제가 생긴다.

@CASE 멀쩡한 ASM을 재기동하려던 문의
구축 직후 "asmcmd가 ASM에 연결되지 않는다"는 문의가 들어왔고, 담당자는 ASMCMD-8102 메시지를 보고 crsctl로 ASM을 재기동하려던 참이었다.
확인 순서는 `whoami`로 계정, `echo $ORACLE_HOME`으로 Grid 홈 여부, `echo $ORACLE_SID`로 +ASM1 여부, 마지막으로 `id -nG`로 asmadmin 소속이다. 이 건은 oracle 계정에서 실행한 것이 원인이었다. 메시지를 믿고 재기동했다면 정상 클러스터를 흔들면서 원인은 그대로 남았을 것이다.
@END

@H2 7.7  ASMCA 무인 모드

@P 디스크그룹은 SQL의 `CREATE DISKGROUP`으로 만들 수 있지만 구축 현장에서는 asmca를 많이 쓴다. GUI 도구이지만 `-silent`를 주면 인자만으로 동작하고, 로그와 종료 코드가 남아 자동화에 쓰기 좋다.

@CODE
[grid@rac1 ~]$ asmca -silent -createDiskGroup -diskGroupName CH9DG \
>   -disk '/dev/asmdisk/test1' -disk '/dev/asmdisk/test2' \
>   -redundancy NORMAL -au_size 1 \
>   -compatible.asm 19.0.0.0.0 -compatible.rdbms 19.0.0.0.0
[INFO] [DBT-30001] Disk groups created successfully.
@END

@B 받는 인자는 `CREATE DISKGROUP`과 거의 같다. 디스크, 장애 그룹(`-failuregroup`), 이중화, AU 크기, compatible 속성이다. 로그는 `/u01/app/grid/cfgtoollogs/asmca/` 아래 남는다.
@B 도움말에는 compatible 범위가 `11.2.0.2 ~ 12.2`로 적혀 있지만 19.0.0.0.0을 넣어도 정상으로 만들어진다. 도움말 문자열이 버전을 따라 갱신되지 않은 것이다.
@B SQL로 만든 것과 다른 점은 Clusterware 자원 등록과 다른 노드 마운트까지 처리된다는 것이다. `ora.CH9DG.dg` 자원이 생기고 `GV$ASM_DISKGROUP`에서 두 인스턴스 모두 MOUNTED로 보인다.
@B `crsctl stat res ora.CH9DG.dg -t`에서 1·3번이 ONLINE, 2번이 OFFLINE으로 나온다. `ora.asmgroup`의 카디널리티가 3인데 노드가 둘이라 한 슬롯이 비어 있는 것이며 장애가 아니다.

@H2 7.8  USABLE_FILE_MB를 음수로 만들기

@P 6장에서 장애 그룹이 둘에서 셋이 되면 예약 공간(`REQUIRED_MIRROR_FREE_MB`)이 생겨 `USABLE_FILE_MB`가 줄어드는 것을 보았다. 여기서는 데이터를 계속 넣어 `FREE_MB`가 예약 공간보다 작아지는 지점까지 간다.

@H3 7.8.1  공식 검산

@CODE
SYS@+ASM1> select name, type, free_mb, required_mirror_free_mb rmf, usable_file_mb usable,
  2         case type when 'NORMAL' then (free_mb-required_mirror_free_mb)/2
  3                   else free_mb-required_mirror_free_mb end calc
  4    from v$asm_diskgroup order by group_number;
NAME     TYPE      FREE_MB        RMF     USABLE       CALC
CRS      NORMAL      11324       4096       3614       3614
DATA     EXTERN      56916          0      56916      56916
@END

@B External은 미러가 없어 예약이 0이고 USABLE이 FREE와 같다. Normal은 여유에서 예약을 빼고 2로 나눈다.
@B +CRS의 예약 4096은 장애 그룹 세 개(CRS_0000~0002, 각 4096MB) 가운데 가장 큰 것의 크기다.

@H3 7.8.2  1GB씩 채우기

@P 디스크 3장(test1~3)짜리 Normal 디스크그룹 CH9DG에 1000MB 데이터 파일을 하나씩 더하며 값을 추적했다.

@IMG 07_usable.png | 그림 7-5. 적재량에 따른 FREE_MB와 USABLE_FILE_MB — 4GB 시점에 USABLE이 −77로 내려간다

@TBL
적재량 | FREE_MB | REQUIRED_MIRROR_FREE_MB | USABLE_FILE_MB
0 (디스크 3장) | 11,982 | 4,096 | 3,943
1GB | 9,956 | 4,096 | 2,930
2GB | 7,951 | 4,096 | 1,927
3GB | 5,946 | 4,096 | 925
4GB | 3,941 | 4,096 | −77
@END

@B 1000MB 데이터 파일 하나가 `FREE_MB`를 약 2005MB씩 깎는다. 미러까지 2000MB, 나머지는 메타데이터다. `USABLE_FILE_MB`는 매번 약 1002MB씩 준다.
@B 4GB를 넣자 `FREE_MB` 3941이 예약 4096보다 작아져 USABLE이 −77이 되었다. `asmcmd lsdg CH9DG`에도 같은 −77이 나온다.

@B 같은 디스크그룹이 디스크 2장일 때는 예약이 0이라 USABLE이 3995였다. test3을 더한 직후 총량은 8192에서 12288로 늘었지만 USABLE은 3943으로 52MB 줄었다. 6장에서 본 현상과 같은 구조다.

@CASE 증설했는데 쓸 공간이 그대로라는 항의
Normal 이중화 디스크그룹에 장애 그룹 두 개로 운영하다가 디스크를 한 장 더 붙인 뒤 "4TB를 추가했는데 쓸 수 있는 공간이 오히려 줄었다"는 항의가 들어왔다.
장애 그룹이 셋이 되면서 예약이 0에서 장애 그룹 하나 크기로 뛴 것이 원인이었다. 설명은 총량이 아니라 잃어도 되는 것을 기준으로 했다. 이전에는 디스크 한 장을 잃으면 이중화가 깨진 채 운영해야 했고, 지금은 자동으로 복원된다. 줄어든 몫은 그 보장의 값이다.
@END

@H3 7.8.3  음수의 뜻

@B 음수 상태에서 테이블을 만들고 5만 행을 넣고 커밋하는 작업은 아무 오류 없이 끝났다. 원시 공간 3941MB가 남아 있기 때문이다.
@B 음수는 "더 쓸 수 없다"가 아니다. "지금 장애 그룹 하나를 잃으면 이중화를 복원할 공간이 없다"는 뜻이다.
@B 경보를 0에 걸면 이미 늦다. 전체 용량 대비 일정 비율 아래에서 경고, 0에 가까우면 심각으로 두 단계를 두는 구성이 흔하다.

@NOTE 실습 정리 순서
테이블스페이스를 먼저 지우고(`DROP TABLESPACE ts_ch9 INCLUDING CONTENTS AND DATAFILES`) 디스크그룹을 지운다. `DROP DISKGROUP`은 자기 인스턴스에만 마운트되어 있어야 동작하므로 rac2에서 dismount한 뒤 rac1에서 drop한다. 끝나면 `V$ASM_DISK`의 HEADER_STATUS가 FORMER 6, MEMBER 8로 돌아와야 한다.
@END

@H2 7.9  운영 지침

@TBL
주기 | 확인 항목 | 명령
매일 | 디스크그룹 USABLE_FILE_MB | asmcmd lsdg 또는 V$ASM_DISKGROUP
매일 | OFFLINE 디스크 수 | lsdg의 Offline_disks 열
주간 | 두 노드 마운트·클라이언트 대칭 | GV$ASM_DISKGROUP, GV$ASM_CLIENT
증설 전후 | 디스크별 입출력 균형 | asmcmd iostat -G 디스크그룹 -t
장애 시 | 디스크 헤더 상태 | V$ASM_DISK의 HEADER_STATUS
구성 변경 후 | 디스크 검색 문자열 일치 | asmcmd dsget
@END

@B 사람이 한 번 보고 넘어갈 것은 asmcmd, 조건을 걸거나 스크립트에 넣을 것은 SQL로 한다.
@B ASM 관리 작업은 grid 계정으로 한다. oracle에서 되지 않는 것은 설계된 권한 분리이고, root에서 되는 것은 setuid 때문이다.
@B 도구 메시지가 원인을 잘못 가리킬 때는 한 계층 아래 도구로 같은 일을 해 본다. asmcmd에서 sqlplus로, sqlplus에서 OS 그룹으로 내려간다.

@H2 7.10  요약

@B ASM 인스턴스에는 딕셔너리가 없어 `DBA_` 뷰가 없고 모든 정보는 `V$ASM_*` 뷰에 있다. 반복해 쓰는 것은 DISKGROUP·DISK·FILE·CLIENT·OPERATION 다섯이다.
@B 소속 없는 디스크는 `TOTAL_MB`가 0이고 물리 크기는 `OS_MB`에 있다. `V$ASM_OPERATION` 0행은 진행 중인 작업이 없다는 답이다.
@B 인스턴스마다 답이 다른 `V$ASM_CLIENT`는 `GV$`로 보고, 두 노드 행이 대칭인지 확인한다.
@B asmcmd는 `/ as sysasm`과 같은 bequeath 접속이며 OSASM 그룹(asmadmin) 소속이 필요하다. oracle 계정은 ASMCMD-8102, sqlplus로는 ORA-01017이 난다.
@B ASM 디렉터리의 GUID는 파일 생성 시점의 값이라 PDB 식별에 쓰지 않는다. `lsdsk --candidate`는 소속 없는 디스크 전체를 보여 준다.
@B `USABLE_FILE_MB` 음수에서도 쓰기는 된다. 장애 그룹 하나를 잃으면 이중화를 복원할 수 없다는 경고다. 용량 감시는 이 값에 건다.

@H2 7.11  퀴즈

@QUIZ 퀴즈
1. ASM 인스턴스에서 `DBA_` 계열 뷰를 조회할 수 없는 이유는?
2. `V$ASM_DISK`에서 TOTAL_MB가 0이고 OS_MB가 4096인 디스크는 어떤 상태인가?
3. +ASM1에서 `V$ASM_CLIENT`를 조회했는데 racdb2가 보이지 않는다. 정상인가? 두 노드를 함께 보려면?
4. oracle 계정으로 asmcmd를 실행해 ASMCMD-8102가 났다. 원인을 확정하는 순서를 쓰시오.
5. root는 asmadmin 그룹에 없는데 asmcmd가 성공한다. 이유와 root로 작업하지 말아야 할 이유는?
6. USABLE_FILE_MB가 −77인 디스크그룹에 데이터를 더 넣을 수 있는가? 이 값이 뜻하는 것은?
@END

@NOTE 정답과 해설
1. ASM 인스턴스는 데이터베이스를 열지 않아 데이터 딕셔너리가 없다. 메모리에서 읽는 V$ASM_ 뷰만 있다.
2. 어느 디스크그룹에도 속하지 않은 디스크다(GROUP_NUMBER 0). TOTAL_MB는 ASM이 쓰는 공간, OS_MB는 물리 크기다.
3. 정상이다. racdb2는 rac2의 +ASM2에 붙어 있다. GV$ASM_CLIENT를 조회하면 INST_ID 1·2의 행이 대칭으로 나온다.
4. whoami, ORACLE_HOME이 Grid 홈인지, ORACLE_SID가 +ASM1인지 확인한 뒤 같은 계정으로 sqlplus / as sysasm을 실행해 ORA-01017을 본다. osdbagrp -a로 OSASM 그룹(asmadmin)을 확인하고 id -nG로 소속을 대조한다.
5. Grid 홈 oracle 바이너리에 setuid가 붙어 있고 root(uid 0)는 그룹 검사를 통과한다. 감사 기록에 실제 작업자가 남지 않고, root 소유 로그·트레이스 파일이 생겨 grid 작업을 방해한다.
6. 넣을 수 있다. 원시 FREE_MB가 남아 있어 쓰기는 정상이다. 다만 장애 그룹 하나를 잃으면 이중화를 복원할 공간이 없다는 뜻이므로 증설하거나 데이터를 줄여야 한다.
@END

@H2 7.12  실습 개요

@P 이 장의 수업 실습은 조회 위주다. 마지막 실습만 디스크그룹을 만들어 채우고 지운다. 시작 전 test1~6이 FORMER 상태(6장 정리 결과)이고 racdb가 두 노드에서 Open인지 확인한다.

@TBL
실습 | 파일 | 목적
01 | RAC/09장/9장_실습_01_ASM뷰지도.txt | V$ASM_ 뷰 개수를 세고 다섯 핵심 뷰로 랩의 디스크·파일 구성을 읽는다
03 | RAC/09장/9장_실습_03_asmcmd명령체계.txt | asmcmd의 접속 방식과 ls·du·lsof·lsct·lsdsk·iostat·spget·dsget을 써 본다
06 ★ | RAC/09장/9장_실습_06_USABLE음수만들기.txt | 공식을 검산하고 CH9DG를 채워 USABLE_FILE_MB가 음수가 되는 과정과 의미를 확인한다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다(정리 단계에서 rac2 dismount).
@B 실습 06은 실습 05에서 만든 CH9DG(test1·test2, Normal)를 전제로 한다. 05를 건너뛰면 7.7절의 asmca 명령 한 줄로 CH9DG를 먼저 만든다. 데이터 파일 생성에 4분 남짓 걸린다.
@B 수료 후 자습: 9장_실습_02_GV로두인스턴스보기, 9장_실습_04_오류재현_계정권한, 9장_실습_05_ASMCA무인모드.
@B 모든 실습이 끝나면 디스크그룹이 CRS·DATA·FRA 셋, HEADER_STATUS가 FORMER 6 / MEMBER 8인 기준선으로 돌아와야 한다.
