@H1 제5장  ASM 파일·디렉터리·템플릿

@H2 5.1  학습 목표

@P 4장에서 디스크그룹이라는 그릇을 만들었다. 이 장은 그 안에 들어가는 파일을 다룬다. ASM 파일 이름이 어떻게 만들어지는지, 이름과 실제 파일이 어떻게 이어지는지, 파일의 저장 방식은 무엇이 정하는지를 차례로 본다. 실습은 test1으로 만든 TEST 디스크그룹에서 한다.

@B `+DATA/RACDB/DATAFILE/system.257.1242761643` 같은 OMF 이름을 다섯 조각으로 나누고 각 조각의 뜻을 말할 수 있다.
@B 파일 번호와 incarnation의 역할, `V$ASM_FILE`과 `V$ASM_ALIAS`의 관계를 설명할 수 있다.
@B COARSE와 FINE 스트라이프의 차이와 컨트롤 파일이 FINE인 이유를 말할 수 있다.
@B 디렉터리와 별칭을 만들고 지우며 ORA-15114, 15173, 15046, 15177의 원인을 구분할 수 있다.
@B 시스템 이름과 사용자 이름의 경계를 `SYSTEM_CREATED` 열로 판단할 수 있다.
@B 템플릿을 조회·생성·적용하고 템플릿 변경이 기존 파일에 미치는 영향을 설명할 수 있다.
@B `asmcmd`의 ls, du, lsof, find, cp로 ASM 안의 파일을 다룰 수 있다.

@H2 5.2  OMF 이름 해부

@P 데이터베이스가 ASM에 만드는 파일은 OMF(Oracle Managed Files) 규칙으로 이름이 붙는다. 사람은 디스크그룹 이름만 주고 나머지는 Oracle이 정한다.

@CODE
SYS@racdb1> select file#, name from v$datafile order by file#;
     FILE# NAME
---------- --------------------------------------------------------------
         1 +DATA/RACDB/DATAFILE/system.257.1242761643
         4 +DATA/RACDB/DATAFILE/undotbs1.259.1242761683
         9 +DATA/RACDB/DATAFILE/undotbs2.269.1242762281
        10 +DATA/RACDB/5A569448ED6C2E8DE06365E110ACB045/DATAFILE/system.274.1242762677
@END

@IMG 05_omfname.png | 그림 5-1. OMF 이름의 다섯 조각 — 마지막 조각의 두 숫자가 ASM 안의 실제 파일을 가리킨다

@TBL
조각 | 예 | 뜻
디스크그룹 | +DATA | 파일이 놓인 디스크그룹
데이터베이스 | RACDB | DB_UNIQUE_NAME
컨테이너 | 5A569448... | PDB의 GUID. CDB$ROOT 파일은 이 조각이 없다
파일 종류 | DATAFILE | ASM이 파일 종류에 따라 만든 디렉터리
파일 이름 | system.257.1242761643 | 태그.파일번호.incarnation
@END

@H3 5.2.1  컨테이너 GUID

@B CDB인 racdb는 PDB마다 디렉터리가 나뉜다. `select con_id, name, guid from v$pdbs`로 보면 RACPDB1의 GUID가 5A569448ED6C2E8DE06365E110ACB045다.
@B PDB 이름 대신 GUID를 쓰는 이유는 PDB 이름을 바꾸거나 다른 CDB로 옮겨도 경로가 그대로 유지되게 하려는 것이다. GUID는 PDB를 만들 때 부여되고 바뀌지 않는다.
@B 컨트롤 파일과 온라인 리두는 GUID 조각이 없다. 특정 PDB가 아니라 CDB 전체에 속하는 파일이다.

@H3 5.2.2  파일 번호와 incarnation

@B 파일 번호(257)는 디스크그룹 안에서 파일을 식별한다. `V$ASM_FILE.FILE_NUMBER`와 같다. 디스크그룹마다 따로 매기므로 같은 리두 그룹의 멤버라도 +DATA에서는 262, +FRA에서는 258처럼 번호가 다르다.
@B incarnation(1242761643)은 파일 번호가 재사용될 때 이전 파일과 구분하는 값이다. 파일을 지우고 새로 만들면 같은 번호가 다시 쓰일 수 있는데 incarnation이 다르므로 옛 이름으로는 새 파일에 접근할 수 없다.
@B 태그(system)는 데이터베이스가 붙이며 보통 테이블스페이스 이름이다.

@CODE
SYS@racdb1> alter database datafile '+DATA/RACDB/DATAFILE/users.260.1242761684' offline;
ORA-01516: nonexistent log file, data file, or temporary file
           "+DATA/RACDB/DATAFILE/users.260.1242761684" in the current container
@END

@B incarnation의 마지막 자리를 3에서 4로 잘못 적었다. 파일은 있고 이름만 틀렸는데 메시지는 파일이 없다고 한다. 파일이 사라졌다고 판단해 복구 절차를 밟기 쉬운 지점이다.
@B 이름은 `V$DATAFILE`에서 복사해 쓰거나 `alter database datafile 7 offline`처럼 파일 번호로 지정한다.

@H3 5.2.3  V$ASM_FILE에서 본 같은 파일

@CODE
SYS@+ASM1> select file_number, type, redundancy, striped, bytes/1024/1024 mb, blocks
  2  from v$asm_file where group_number=2 and type='DATAFILE' order by 1;
FILE_NUMBER TYPE       REDUND STRIPE         MB     BLOCKS
----------- ---------- ------ ------ ---------- ----------
        257 DATAFILE   UNPROT COARSE 890.007813     113921
        258 DATAFILE   UNPROT COARSE 590.007813      75521
@END

@B `V$ASM_FILE`에는 이름 열이 없다. ASM은 파일을 번호로 관리하고 이름은 `V$ASM_ALIAS`가 따로 관리한다. 이 분리 덕분에 파일 하나에 이름을 여러 개 붙일 수 있다(5.4절).
@B REDUNDANCY UNPROT은 +DATA가 External이라 미러가 없다는 뜻이다. +CRS의 OCR 백업은 MIRROR였다(3장).
@B MB 값 끝의 0.0078125는 8KB 헤더 블록 하나다. 데이터 파일은 지정한 크기에 파일 헤더 블록 하나가 더 붙어 113920이 아니라 113921블록이다.

@H3 5.2.4  디스크그룹별 파일 구성

@CODE
SYS@+ASM1> select g.name dg, f.type, count(*) cnt, round(sum(f.bytes)/1024/1024) mb
  2  from v$asm_file f, v$asm_diskgroup g
  3  where f.group_number=g.group_number group by g.name, f.type order by 1,2;
@END

@TBL
디스크그룹 | 파일 종류(TYPE) | 내용
CRS | OCRFILE, OCRBACKUP, ASMPARAMETERFILE, PASSWORD | OCR, 3장에서 만든 OCR 백업, ASM SPFILE, ASM·Clusterware용 암호 파일
DATA | DATAFILE, TEMPFILE, CONTROLFILE, ONLINELOG, PARAMETERFILE, PASSWORD | racdb의 데이터·임시 파일, 컨트롤 파일과 리두 첫 멤버, SPFILE, 암호 파일
FRA | CONTROLFILE, ONLINELOG (+ ARCHIVELOG, BACKUPSET) | 컨트롤 파일·리두 다중화 사본, 아카이브와 백업이 생기면 함께 쌓인다
@END

@B 이 조회 한 번으로 클러스터의 저장 구조가 드러난다. Voting File은 어느 디스크그룹의 목록에도 없다. ASM 파일이 아니기 때문이다.
@B 온라인 리두는 그룹 4개(스레드마다 2개)가 +DATA와 +FRA에 멤버를 하나씩 둔다. 1장에서 본 스레드별 리두가 두 디스크그룹에 다중화된 모습이다.
@B 컨트롤 파일도 +DATA와 +FRA에 한 벌씩 있다. `V$CONTROLFILE`이 두 경로를 보여 준다.

@H2 5.3  스트라이프 — COARSE와 FINE

@P ASM은 파일을 디스크그룹의 모든 디스크에 고르게 나눠 놓는다. 나누는 단위가 두 가지다.

@IMG 05_stripe.png | 그림 5-2. COARSE와 FINE — COARSE는 AU 단위로, FINE은 128KB 단위로 여러 디스크에 흩는다

@TBL
방식 | 단위 | 쓰는 파일 | 이유
COARSE | AU 크기(실습 환경 +DATA 1MB) | 데이터 파일, 리두, 아카이브 등 대부분 | 큰 순차 I/O에 유리하고 메타데이터가 적다
FINE | 128KB | 컨트롤 파일 | 작고 갱신이 잦으며 여러 인스턴스가 동시에 접근한다
@END

@CODE
ASMCMD> ls -ls +DATA/RACDB/CONTROLFILE
Type         Redund  Striped  Time             Sys  Block_Size  Blocks     Bytes     Space  Name
CONTROLFILE  UNPROT  FINE     SEP 01 19:00:00  Y         16384    1203  19709952  25165824  Current.261.1242761745
@END

@B 컨트롤 파일을 AU 하나에 몰아 두면 그 AU가 있는 디스크에 부하가 집중된다. 잘게 나눠 여러 디스크에 퍼뜨린다.
@B Bytes와 Space가 다르다. 할당이 AU 단위로 이루어져 실제 크기보다 조금 더 공간을 쓴다.
@B 파일 종류별 저장 방식은 템플릿이 정한다(5.5절).

@H2 5.4  디렉터리와 별칭

@P ASM의 이름 공간은 디렉터리와 별칭으로 이루어진 트리다. 시스템이 만든 이름과 사람이 만든 이름이 섞여 있고, 사람이 지울 수 있는 것은 사람이 만든 것뿐이다.

@H3 5.4.1  계층 구조

@CODE
ASMCMD> ls -l +DATA/RACDB
Type  Redund  Striped  Time  Sys  Name
                             Y    5A569448ED6C2E8DE06365E110ACB045/
                             Y    CONTROLFILE/
                             Y    DATAFILE/
                             Y    ONLINELOG/
                             Y    PARAMETERFILE/
                             Y    PASSWORD/
                             Y    TEMPFILE/
@END

@B Sys 열의 Y는 시스템이 만든 것, N은 사용자가 만든 것이다. DATAFILE, CONTROLFILE 같은 디렉터리는 파일을 만들 때 ASM이 자동으로 만든다.
@B `+DATA` 바로 아래의 RACDB는 `ls -l +DATA`에서 N으로 보인다. 데이터베이스가 만들었지만 ASM 입장에서는 사용자 디렉터리로 다룬다.

@H3 5.4.2  V$ASM_ALIAS

@CODE
NAME                       FILE_NUMBER A S
-------------------------- ----------- - -
RACDB                       4294967295 Y Y
DATAFILE                    4294967295 Y Y
mydir                       4294967295 Y N
TS_ALIAS.256.1242847959            256 N Y
my_alias.dbf                       256 N N
@END

@B FILE_NUMBER 4294967295(32비트 부호 없는 정수의 최댓값)에 ALIAS_DIRECTORY Y인 행은 디렉터리다.
@B SYSTEM_CREATED Y에 파일 번호가 있는 행은 시스템 이름(정규 이름), N인 행은 사용자가 만든 별칭이다.
@B my_alias.dbf와 TS_ALIAS.256.1242847959는 같은 FILE_NUMBER 256을 가리킨다. 이름이 둘일 뿐 파일은 하나다.
@B 트리는 PARENT_INDEX와 REFERENCE_INDEX로 이어진다. 자식의 PARENT_INDEX가 부모의 REFERENCE_INDEX다. 파일 행의 REFERENCE_INDEX는 자식을 가질 수 없다는 고정값이다. asmcmd가 보여 주는 경로는 이 관계를 따라 복원한 것이다.

@CODE
NAME                        ALIAS_INDEX PARENT_INDEX REFERENCE_INDEX A S
--------------------------- ----------- ------------ --------------- - -
RACDB                                 0     50331648        50331701 Y Y
CONTROLFILE                          53     50331701        50331754 Y Y
ONLINELOG                            54     50331701        50331807 Y Y
Current.256.1242761745              106     50331754        67108863 N Y
group_1.258.1242761759              160     50331807        67108863 N Y
@END

@B 위는 +FRA의 `V$ASM_ALIAS`다. RACDB의 REFERENCE_INDEX 50331701을 부모로 갖는 것이 CONTROLFILE과 ONLINELOG이고, ONLINELOG의 50331807을 부모로 갖는 것이 group_1이다. 이 사슬을 따라가면 `+FRA/RACDB/ONLINELOG/group_1.258.1242761759`라는 경로가 나온다.
@B 파일 행의 REFERENCE_INDEX 67108863(0x3FFFFFF)은 자식을 가질 수 없다는 표시다.
@B 같은 트리를 SQL로 경로까지 펼치려면 `CONNECT BY PRIOR reference_index = parent_index`로 계층 질의를 한다. asmcmd의 `ls`와 `find`가 내부에서 하는 일이 이 복원이다.

@IMG 05_alias.png | 그림 5-3. 이름 계층 — 별칭과 정규 이름이 같은 파일 번호를 가리키고, 그 아래에서 익스텐트가 디스크에 흩어진다

@H3 5.4.3  별칭 만들기

@TBL
시도 | 결과 | 원인
add alias '+TEST/mydir/a.dbf' for file '+TEST/...' | ORA-15114 | FOR 다음에 file이라는 단어를 파일 이름으로 해석했다(구문)
add alias '+TEST/nodir/a.dbf' for '+TEST/...' | ORA-15173 | 별칭을 놓을 디렉터리가 없다(경로)
add alias '+TEST/mydir/second.dbf' for '+TEST/mydir/my_alias.dbf' | ORA-15046 | 대상이 정규 이름이 아니다(별칭에 별칭)
@END

@CODE
SYS@+ASM1> alter diskgroup TEST add directory '+TEST/mydir';
SYS@+ASM1> alter diskgroup TEST add alias '+TEST/mydir/my_alias.dbf'
  2  for '+TEST/RACDB/DATAFILE/ts_alias.256.1242847959';
Diskgroup altered.
ASMCMD> ls -l +TEST/mydir
DATAFILE  UNPROT  COARSE   SEP 01 19:00:00  N    my_alias.dbf => +TEST/RACDB/DATAFILE/TS_ALIAS.256.1242847959
@END

@B 디렉터리를 먼저 만들고 별칭을 건다. asmcmd는 별칭을 유닉스 심볼릭 링크처럼 화살표로 보여 준다. 별칭은 데이터를 복사하지 않는다.
@B 별칭의 대상은 반드시 정규 이름이다. ASM은 한 단계 별칭만 허용해 별칭 체인이 끊겨 추적하지 못하는 상황을 막는다.
@B ORA-15114의 별표 위치가 file이라는 단어를 가리킨다. 오류 메시지의 별표가 구문 오류의 위치다.

@H3 5.4.4  별칭을 지우면

@B 만들 때는 ADD ALIAS, 지울 때는 DROP ALIAS다. `delete alias`라고 쓰면 SQL 파서 단계의 ORA-00905(missing keyword)가 난다.
@B 별칭을 지워도 실제 파일과 데이터베이스는 영향을 받지 않는다. `V$DATAFILE`은 여전히 정규 이름을 보여 주고 테이블스페이스도 ONLINE이다. 데이터베이스는 별칭을 모르고 정규 이름으로 참조한다.
@B 시스템 이름을 지우려 하면 ORA-15177(cannot operate on system aliases)이다. 시스템 디렉터리(`+TEST/RACDB`)도 같다. 사람이 만든 빈 디렉터리(`+TEST/mydir`)는 지워진다.
@B 별칭이 남아 있는 디렉터리는 그대로 지워지지 않는다. 안의 별칭을 먼저 지우거나 `drop directory ... force`로 하위까지 지운다.

@TBL
계층 | 담는 것 | 보는 곳 | 사람이 바꿀 수 있는가
이름 | 경로, 별칭, 디렉터리 | V$ASM_ALIAS | 사용자 별칭과 사용자 디렉터리만
파일 | 파일 번호와 속성 | V$ASM_FILE | 아니오
익스텐트 | 데이터가 놓인 AU 위치 | X$KFFXP | 아니오
@END

@B 이 분리 덕분에 디스크를 추가하거나 제거해 익스텐트가 옮겨 다녀도 파일 번호와 이름은 그대로다. 데이터베이스는 리밸런스가 일어나는지 모른다(6장).
@B 이름만 보고는 파일이 몇 개 디스크에 흩어졌는지, 미러가 온전한지 알 수 없다. 저장 상태는 `V$ASM_FILE`, 배치는 X$KFFXP로 본다(6장).

@BP 별칭은 사람이 읽기 위해 쓴다
별칭은 성능과 무관하다. control_files 파라미터처럼 경로를 적어야 하는 곳에 별칭을 쓰면 파일을 다시 만들어도 파라미터를 고치지 않아도 된다. 데이터 파일에 별칭을 거는 것은 대개 관리 대상만 늘린다.
@END

@H2 5.5  템플릿

@P 파일을 만들 때마다 이중화와 스트라이프를 지정하지 않아도 되는 것은 템플릿 덕분이다. 템플릿은 파일 종류별 저장 방식이다.

@H3 5.5.1  기본 템플릿

@CODE
SYS@+ASM1> select entry_number, name, redundancy, stripe, system from v$asm_template
  2  where group_number=(select group_number from v$asm_diskgroup where name='DATA');
ENTRY_NUMBER NAME                     REDUND STRIPE S
------------ ------------------------ ------ ------ -
         205 CONTROLFILE              UNPROT FINE   Y
         207 ARCHIVELOG               UNPROT COARSE Y
         208 ONLINELOG                UNPROT COARSE Y
         209 DATAFILE                 UNPROT COARSE Y
...
22 rows selected.
@END

@B 디스크그룹마다 시스템 템플릿 22개가 자동으로 만들어진다. CRS, DATA, FRA 모두 22개씩이고 한 디스크그룹의 템플릿을 바꿔도 다른 디스크그룹에는 영향이 없다.
@B CONTROLFILE만 FINE이고 나머지는 COARSE다.
@B REDUNDANCY는 디스크그룹 이중화를 따른다. External인 +DATA는 UNPROT, Normal인 +CRS는 MIRROR다.
@B VOTINGFILE 템플릿이 있지만 3장에서 본 것처럼 Voting File은 ASM 파일로 저장되지 않는다.
@B PRIMARY_REGION, MIRROR_REGION 열의 COLD는 Exadata 플래시 캐시 관련 속성이라 일반 환경에서는 의미가 없다.

@H3 5.5.2  사용자 템플릿

@IMG 05_template.png | 그림 5-4. 템플릿 적용 — 같은 DATAFILE이라도 +TEST(mytpl)로 만들면 FINE으로 저장된다

@CODE
SYS@+ASM1> alter diskgroup TEST add template mytpl attributes (unprotected fine);
SYS@racdb1> create tablespace ts_tpl datafile '+TEST(mytpl)' size 50M;
SYS@+ASM1> select file_number, type, redundancy, striped from v$asm_file
  2  where group_number=(select group_number from v$asm_diskgroup where name='TEST');
FILE_NUMBER TYPE       REDUND STRIPE
----------- ---------- ------ ------
        256 DATAFILE   UNPROT COARSE
        257 DATAFILE   UNPROT FINE
@END

@B 사용자 템플릿은 SYSTEM이 N이고 ENTRY_NUMBER가 시스템 템플릿 뒤에 붙는다.
@B attributes 절에는 이중화(unprotected, mirror, high)와 스트라이프(coarse, fine)를 쓴다. 이중화는 디스크그룹이 허용하는 범위 안에서만 지정할 수 있다.
@B 파일을 만들 때 `+디스크그룹(템플릿)` 형식으로 지정한다. 이름에는 차이가 없고 저장 방식만 다르다.
@B 쓰임새는 같은 종류의 파일을 용도에 따라 달리 저장하는 것이다. 크기가 작고 갱신이 잦은 테이블스페이스를 FINE으로 만들면 여러 디스크에 부하가 나뉜다. Normal 디스크그룹에서 다시 만들 수 있는 임시 파일이나 바로 백업되는 아카이브는 unprotected로 두어 공간을 아낄 수 있다.

@H3 5.5.3  오류와 변경

@CODE
SYS@racdb1> create tablespace ts_bad datafile '+TEST(nosuchtpl)' size 10M;
ORA-01119: error in creating database file '+TEST(nosuchtpl)'
ORA-17502: ksfdcre:4 Failed to create file +TEST(nosuchtpl)
ORA-15060: template "NOSUCHTPL" does not exist
@END

@B 세 계층이 겹쳐 있다. ORA-01119는 데이터베이스, ORA-17502는 파일 생성 인터페이스, ORA-15060이 실제 원인인 ASM 계층이다. 3장의 CRS-4648 스택처럼 맨 아래부터 읽는다.
@B 시스템 템플릿은 지울 수 없다. `drop template DATAFILE`은 ORA-15008(cannot drop system template)이다. 속성 변경(`alter template`)은 된다.
@B 템플릿 변경은 이후 만드는 파일에만 적용된다. mytpl을 coarse로 바꿔도 이미 만든 257번 파일은 FINE 그대로다. 기존 파일까지 바꾸려면 파일을 다시 만들어야 한다.
@B compatible 속성과 달리 템플릿 변경은 언제든 되돌릴 수 있다.

@CASE 아카이브 로그만 미러 없이 저장한 사례
Normal 디스크그룹에 데이터 파일과 아카이브 로그를 함께 두던 사이트에서 용량이 빠듯해졌다. 아카이브 로그는 생성 직후 백업 서버로 복사되고 있었다.
`alter diskgroup DATA alter template ARCHIVELOG attributes (unprotected)`로 바꾸자 이후 아카이브 로그가 미러 없이 저장됐다. 이미 있던 아카이브 로그는 미러를 유지했고, 공간 효과는 오래된 아카이브가 백업 후 삭제되면서 서서히 나타났다.
@END

@H2 5.6  asmcmd로 파일 다루기

@P asmcmd는 ASM 이름 공간을 셸처럼 다루는 도구다. grid 계정에서 실행한다.

@IMG 05_asmcmd.png | 그림 5-5. asmcmd의 주요 명령 — 조회는 ls·du·lsof·find, 이동은 cp

@TBL
명령 | 하는 일 | 참고
ls -l, ls -ls | 디렉터리와 파일, Sys 열, 별칭 화살표 | -s를 붙이면 Bytes와 Space
du +DATA/RACDB | 디렉터리 이하 사용량 | External이면 Used와 Mirror_used가 같다
lsof -G DATA | 지금 열려 있는 파일과 인스턴스 | 언마운트 전에 사용처 확인
find --type CONTROLFILE + '*' | 종류·패턴으로 검색 | 디렉터리와 패턴을 모두 준다
cp 원본 대상 | ASM 안팎, 디스크그룹 사이 복사 | 열려 있는 데이터 파일의 일관된 백업은 RMAN
@END

@CODE
ASMCMD> du +DATA/RACDB
Used_MB      Mirror_used_MB
   4372                4372
ASMCMD> lsof -G DATA
DB_Name  Instance_Name  Path
racdb    racdb1         +DATA/RACDB/CONTROLFILE/current.261.1242761745
@END

@B `du`의 두 값이 같은 것은 +DATA가 External이기 때문이다. Normal 디스크그룹이면 Mirror_used_MB가 대략 두 배가 된다.
@B `lsof`로 사용처를 확인하면 4장의 ORA-15027을 미리 피할 수 있다.
@B `find`에 패턴을 빼먹으면 오류가 아니라 사용법만 출력된다. 별표는 셸이 확장하지 않게 따옴표로 감싼다.
@B `cp`로 ASM 밖으로 꺼낸 파일은 asmcmd를 실행한 계정(grid:oinstall) 소유가 된다.
@B `cp /tmp/copy_out.dbf +TEST/mydir/copied.dbf`처럼 ASM 안으로 넣으면 실제 파일은 `+TEST/ASM/DATAFILE/copied.dbf.258...`에 만들어지고 지정한 경로는 별칭이 된다. 데이터베이스 이름을 알 수 없으므로 ASM이라는 디렉터리를 쓴다.

@BP 이름으로 상태를 판단하지 않는다
파일 이름은 만들어질 때 고정되고 그 뒤 데이터의 위치나 보호 상태를 반영하지 않는다. 같은 이름이라도 리밸런스 뒤에는 익스텐트가 다른 디스크에 있을 수 있고, 디스크 하나가 OFFLINE이면 미러가 불완전할 수 있다. 상태는 `V$ASM_FILE`과 `V$ASM_DISK`로, 배치는 X$KFFXP로 확인한다.
@END

@H2 5.7  요약

@B ASM 파일 이름은 디스크그룹·DB·컨테이너·종류·이름 다섯 조각이다. 마지막 조각은 태그.파일번호.incarnation이다.
@B incarnation은 재사용된 파일 번호를 구분한다. 이름을 손으로 옮기다 틀리면 ORA-01516을 만난다.
@B ASM은 파일을 번호로 관리하고 이름은 `V$ASM_ALIAS`가 관리한다. 별칭과 정규 이름은 같은 파일 번호를 가리킨다.
@B 컨트롤 파일만 FINE(128KB), 나머지는 COARSE(AU)로 흩어 놓는다.
@B 별칭 생성 오류: ORA-15114(구문), 15173(디렉터리 없음), 15046(별칭에 별칭). 시스템 이름 삭제는 ORA-15177이다.
@B 별칭을 지워도 파일과 데이터베이스는 영향이 없다.
@B 템플릿은 디스크그룹마다 22개이고 파일 종류별 이중화와 스트라이프를 정한다. 변경은 이후 파일에만 적용된다.
@B asmcmd cp로 넣은 파일은 ASM 규칙대로 저장되고 지정한 경로는 별칭이 된다.

@H2 5.8  퀴즈

@QUIZ 퀴즈
1. `+DATA/RACDB/DATAFILE/system.257.1242761643`의 다섯 조각과 각각의 뜻을 쓰시오.
2. 파일 이름 끝의 두 숫자 중 뒤의 것은 무엇이며 왜 필요한가?
3. `V$ASM_ALIAS`에서 FILE_NUMBER가 4294967295인 행은 무엇인가?
4. 데이터 파일에 건 별칭을 지우면 데이터베이스는 어떻게 되는가? 근거는?
5. 컨트롤 파일만 FINE 스트라이프인 이유는?
6. 템플릿 mytpl을 fine에서 coarse로 바꿨다. 이미 mytpl로 만든 파일은 어떻게 되는가?
@END

@NOTE 정답과 해설
1. +DATA 디스크그룹, RACDB DB_UNIQUE_NAME, CDB$ROOT라 컨테이너 조각 없음, DATAFILE 파일 종류, system.257.1242761643은 태그.파일번호.incarnation.
2. incarnation. 파일 번호가 재사용될 때 이전 파일과 구분해 옛 이름으로 새 파일에 접근하지 못하게 한다.
3. 디렉터리다. 파일이 아님을 뜻하는 표시값(32비트 부호 없는 정수 최댓값)이다.
4. 영향이 없다. 데이터베이스는 정규 이름으로 참조하고, 별칭은 같은 파일 번호를 가리키는 또 하나의 이름일 뿐이다.
5. 작고 갱신이 잦으며 여러 인스턴스가 동시에 접근하므로 128KB 단위로 여러 디스크에 퍼뜨려 부하를 나눈다.
6. 그대로 FINE이다. 템플릿은 파일을 만들 때만 참조된다.
@END

@H2 5.9  실습 개요

@P 실습은 4장 실습 06-07을 마쳐 test 디스크(설치 가이드 v2 부록 E)가 FORMER인 상태에서 시작한다. test1로 TEST 디스크그룹을 만들어 쓰고, 끝나면 테이블스페이스와 TEST를 지워 기준 상태로 돌린다. 실습 번호는 폴더 번호와 파일 번호를 이은 것이다.

@TBL
실습 | 파일 | 목적
07-01 | RAC/07장/7장_실습_01_OMF이름해부.txt | V$DATAFILE과 V$ASM_FILE을 대조해 이름의 다섯 조각과 파일 번호를 확인한다
07-03 | RAC/07장/7장_실습_03_별칭만들기.txt | ORA-15114·15173·15046을 재현하고 별칭을 만든다
07-04 | RAC/07장/7장_실습_04_별칭삭제실험.txt | 별칭을 지워도 파일과 데이터베이스가 무사한지 확인하고 ORA-15177을 본다
07-05 | RAC/07장/7장_실습_05_템플릿.txt | 사용자 템플릿으로 FINE 파일을 만들고 ORA-15060·15008을 재현한다
@END

@B 이 장의 실습은 한 노드(rac1)에서 진행하며 스냅샷이 필요하지 않다.
@B 수료 후 자습: 7장_실습_02_디렉터리구조, 7장_실습_06_파일복사.
@B 마지막에 `V$ASM_DISK`에서 test 디스크가 다시 FORMER 6장인지 확인한다. 6장의 리밸런스 실습이 이 디스크를 쓴다.
