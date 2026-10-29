@H1 제6장  ASM 리밸런스와 이중화

@H2 6.1  학습 목표

@P 5장까지의 작업은 이름과 템플릿 같은 메타데이터만 바꿨다. 이 장에서는 디스크를 더하고 빼면서 ASM이 익스텐트를 실제로 옮기는 리밸런스를 관찰하고, 디스크를 일부러 잃었을 때 이중화가 어떻게 데이터를 지키고 되살리는지 확인한다. 실습은 설치 가이드 v2 부록 E로 붙여 둔 실습용 디스크 `/dev/asmdisk/test1~6`(4GB × 6)으로 만든 디스크그룹 TESTN에서만 하고 +CRS·+DATA·+FRA는 건드리지 않는다.

@B ASM 미러링에서 원본과 미러가 디스크에 어떻게 섞여 놓이는지, 장애 그룹이 무엇을 보장하는지 설명할 수 있다.
@B 디스크 추가·제거 뒤 리밸런스를 `V$ASM_OPERATION`으로 관찰하고 끝났는지 올바르게 판정할 수 있다.
@B RBAL·ARBA·ARB0의 역할과 파워(POWER)의 의미, 파워 0으로 멈추고 재개하는 방법을 말할 수 있다.
@B `FREE_MB`·`REQUIRED_MIRROR_FREE_MB`·`USABLE_FILE_MB`의 관계를 계산으로 확인할 수 있다.
@B 정상 제거와 FORCE 제거가 디스크 헤더에 남기는 차이와 ORA-59327·ORA-15033의 원인을 설명할 수 있다.
@B `DISK_REPAIR_TIME`이 만료될 때와 그 안에 되돌릴 때의 동작 차이, fast mirror resync의 원리를 설명할 수 있다.

@H2 6.2  실습 디스크그룹 준비

@P 리밸런스를 보려면 옮길 데이터가 있어야 한다. 빈 디스크그룹에 디스크를 더하면 옮길 것이 없어 순식간에 끝나므로, Normal 이중화 디스크그룹을 만들고 2500MB 테이블스페이스로 채운 뒤 시작한다.

@H3 6.2.1  TESTN 만들기

@CODE
SYS@+ASM1> CREATE DISKGROUP TESTN NORMAL REDUNDANCY
  2    FAILGROUP fgA DISK '/dev/asmdisk/test2' NAME d_a
  3    FAILGROUP fgB DISK '/dev/asmdisk/test3' NAME d_b
  4    ATTRIBUTE 'compatible.asm'='19.0.0.0.0','compatible.rdbms'='19.0.0.0.0';
SYS@+ASM1> ALTER DISKGROUP TESTN SET ATTRIBUTE 'disk_repair_time'='3m';
SYS@+ASM2> ALTER DISKGROUP TESTN MOUNT;
@END

@B 장애 그룹을 디스크마다 하나씩(fgA, fgB) 명시했다. 장애 그룹 이름을 빼면 ASM이 디스크 이름과 같은 장애 그룹을 디스크마다 만든다(4장).
@B `CREATE DISKGROUP`은 실행한 ASM 인스턴스에서만 마운트한다. rac2의 +ASM2에서 따로 마운트해야 rac2의 데이터베이스 인스턴스도 이 디스크그룹의 파일을 쓸 수 있다.
@B `disk_repair_time`의 기본값은 3.6h다. 실습에서 타이머 만료를 지켜보려고 3분으로 줄였다.

@NOTE disk_repair_time은 CREATE에서 지정할 수 없다
`ATTRIBUTE` 절에 `'disk_repair_time'='3m'`을 함께 넣으면 ORA-15018과 ORA-15237(invalid attribute disk_repair_time to CREATE DISKGROUP command)로 거절된다. 생성 시점에 정해지는 속성(compatible 계열, au_size, sector_size)만 CREATE에서 받고 나머지는 생성 뒤 `ALTER DISKGROUP ... SET ATTRIBUTE`로 바꾼다.
@END

@H3 6.2.2  데이터를 채운 뒤의 모습

@CODE
SQL> create tablespace ts_reb datafile '+TESTN' size 2500M;
NAME     PATH                 FAILGR   TOTAL_MB    FREE_MB    USED_MB
-------- -------------------- ------ ---------- ---------- ----------
D_A      /dev/asmdisk/test2   FGA          4096       1486       2610
D_B      /dev/asmdisk/test3   FGB          4096       1486       2610
@END

@B 2500MB 데이터 파일 하나를 만들었는데 두 디스크가 각각 2610MB, 합계 5220MB를 썼다. Normal 이중화라 모든 익스텐트가 두 벌 저장되고 메타데이터가 더해진다.
@B 이 테이블스페이스 생성에 4분 남짓 걸렸다. 가상 디스크 하나에 두 벌을 쓰는 환경이라 느리다. 리밸런스 소요 시간도 같은 이유로 길게 나온다.

@H2 6.3  미러는 어디에 놓이는가

@P ASM은 익스텐트 단위로 이중화한다. 한 디스크를 다른 디스크에 통째로 복사하는 RAID 1과 다르게, 익스텐트마다 원본(primary)과 미러(secondary)의 위치를 따로 정한다.

@IMG 06_mirror.png | 그림 6-1. 익스텐트 단위 미러링 — 같은 익스텐트의 두 사본은 반드시 서로 다른 장애 그룹에 놓인다

@H3 6.3.1  x$kffxp로 본 분포

@CODE
SQL> select x.disk_kffxp disk, x.lxn_kffxp side, count(*) extents
  2    from x$kffxp x, v$asm_diskgroup g
  3   where x.group_kffxp=g.group_number and g.name='TESTN'
  4   group by x.disk_kffxp, x.lxn_kffxp order by 1,2;
      DISK       SIDE    EXTENTS
---------- ---------- ----------
         0          0       1302
         0          1       1305
         1          0       1305
         1          1       1302
@END

@B `DISK_KFFXP`는 디스크 번호, `LXN_KFFXP`는 사본 번호다. 0이 원본, 1이 미러다. 디스크 번호 65534는 아직 디스크에 배정되지 않은 익스텐트를 뜻한다.
@B 디스크 0과 1이 원본과 미러를 거의 같은 수로 나눠 가진다. 미러 전용 디스크를 두지 않으므로 평소 읽기도 모든 디스크가 나눠 처리한다.
@B 규칙은 하나다. 같은 익스텐트의 원본과 미러는 서로 다른 장애 그룹에 놓인다. 그래서 장애 그룹 하나가 통째로 사라져도 모든 익스텐트의 사본이 남는다.

@H3 6.3.2  장애 그룹 규칙을 검증하는 조회

@P 디스크별 개수만으로는 "같은 익스텐트의 두 사본이 다른 곳에 있다"를 증명하지 못한다. 파일 번호(`NUMBER_KFFXP`)와 익스텐트 번호(`XNUM_KFFXP`)가 같은 행끼리 원본과 미러를 짝지어 본다.

@CODE
SQL> select p.disk_kffxp pri_disk, s.disk_kffxp sec_disk, count(*) cnt
  2    from x$kffxp p, x$kffxp s, v$asm_diskgroup g
  3   where p.group_kffxp=g.group_number and g.name='TESTN'
  4     and s.group_kffxp=p.group_kffxp and s.number_kffxp=p.number_kffxp
  5     and s.xnum_kffxp=p.xnum_kffxp and p.lxn_kffxp=0 and s.lxn_kffxp=1
  6     and p.disk_kffxp<>65534 and s.disk_kffxp<>65534
  7   group by p.disk_kffxp, s.disk_kffxp order by 1,2;
@END

@B 디스크 4장(장애 그룹 4개)일 때 이 조회는 12행을 돌려준다. 4개 디스크에서 서로 다른 두 개를 고르는 모든 조합이고, PRI_DISK와 SEC_DISK가 같은 행은 하나도 없다.
@B 한 장애 그룹에 디스크가 여러 장인 구성이라면 `V$ASM_DISK`와 조인해 `FAILGROUP` 기준으로 집계해야 같은 검증이 된다.
@B 디스크 4장 구성에서는 `LXN_KFFXP`=2인 익스텐트가 디스크마다 수십 개 보인다. 데이터 사본과는 별개로 디스크그룹 메타데이터 일부를 세 벌로 두는 몫이다.

@BP x$kffxp는 진단용으로만 쓴다
`X$` 테이블은 문서화되지 않은 내부 구조라 버전에 따라 열이 바뀔 수 있고 SYS로만 조회된다. 장애 그룹 설계를 검증할 때처럼 꼭 필요한 순간에 쓰고 결과를 파일로 남긴다. 정기 감시 스크립트는 `V$ASM_DISK` 집계로 짠다.
@END

@CASE 설계 문서와 실제 배치가 달랐던 사례
스토리지 컨트롤러 두 대에 맞춰 CTRL_A, CTRL_B 두 장애 그룹으로 설계한 디스크그룹이 있었다. 증설 때 한 담당자가 `ADD DISK`에 장애 그룹 이름을 빼먹어 새 디스크들이 각자 자기 이름의 장애 그룹이 되었다.
설계 문서만 보면 문제가 없었지만 원본과 미러 짝 조회를 돌리자 같은 컨트롤러에 걸린 디스크끼리 짝을 이룬 익스텐트가 나왔다. 컨트롤러 하나가 멈추면 일부 데이터의 두 사본을 함께 잃는 구성이었다. 디스크를 올바른 장애 그룹으로 다시 넣고 검증 조회를 증설 절차에 넣었다.
@END

@H2 6.4  디스크 추가와 리밸런스

@P 디스크를 추가하는 명령은 1초 안에 돌아온다. 실제 작업은 그 뒤 백그라운드에서 익스텐트를 새 디스크로 옮기는 리밸런스이고, 이 랩에서는 몇 분이 걸린다.

@IMG 06_rebalance.png | 그림 6-2. 리밸런스의 흐름 — RBAL이 계획하고 ARBA가 작업량을 추정하며 ARB0 슬레이브가 익스텐트를 옮긴다

@H3 6.4.1  추가와 관찰

@CODE
SQL> alter diskgroup TESTN add failgroup fgC disk '/dev/asmdisk/test6'
  2    name d_c rebalance power 1;
SQL> select operation, state, power, sofar, est_work, est_minutes
  2    from v$asm_operation;
@END

@B `V$ASM_OPERATION`을 몇 초 간격으로 반복 조회하면 `OPERATION`=REBAL, `STATE`=RUN인 행이 보인다. 파워 1로 test6을 더한 작업은 239초 남짓 걸렸다.
@B 처음 조회에서 `EST_WORK`는 0이다. ARBA 프로세스가 작업량을 계산한 뒤에 값이 채워진다.
@B `SOFAR`가 1100을 넘어 오르다가 갑자기 두 자리 수로 떨어지고 `EST_WORK`도 0으로 바뀐다. 리밸런스가 여러 단계(phase)로 진행되고 단계가 바뀔 때 카운터가 새로 시작하기 때문이다.
@B 그래서 `SOFAR/EST_WORK`로 진행률을 계산하면 뒤로 가거나 100%를 넘는다. 완료 판정은 `V$ASM_OPERATION`에 그 디스크그룹의 행이 없어졌는지로 한다.

@H3 6.4.2  RBAL과 ARB 프로세스

@B RBAL은 ASM 인스턴스에 늘 떠 있으면서 리밸런스가 필요한지 판단하고 계획을 세운다.
@B ARB 계열은 평소에는 없다. 리밸런스가 시작되면 ASM alert.log에 ARBA와 ARB0이 뜨는 기록이 남는다. ARBA는 작업량을 추정해 `EST_WORK`·`EST_MINUTES`를 채우고, ARB0은 익스텐트를 실제로 복사한다.
@B 리밸런스가 끝나면 ARB 프로세스가 정지하고, 모든 ASM 인스턴스에 멤버십 갱신을 요청한 뒤 `SUCCESS: rebalance completed`를 남긴다. +ASM2도 새 디스크 구성을 알아야 하기 때문이다.

@CODE
NOTE: starting rebalance of group 5/0x9c506d29 (TESTN) at power 1
NOTE: assigning ARBA to group 5/0x9c506d29 (TESTN) to compute estimates
NOTE: assigning ARB0 to group 5/0x9c506d29 (TESTN) with 1 parallel I/O
...
SUCCESS: rebalance completed for group 5/0x9c506d29 (TESTN)
@END

@TBL
확인 방법 | 무엇을 보나 | 쓰임
V$ASM_OPERATION | 행이 있으면 진행 중, 파워와 추정치 | 스크립트의 완료 판정
asmcmd lsdg | Rebal 열이 Y면 진행 중 | 여러 디스크그룹을 한눈에
ps -u grid -o cmd 로 asm_arb 개수 | 실제로 도는 슬레이브 수 | 파워가 적용됐는지 확인
@END

@H3 6.4.3  재분배 결과

@CODE
NAME     PATH                 FAILGR   TOTAL_MB    FREE_MB    USED_MB
-------- -------------------- ------ ---------- ---------- ----------
D_A      /dev/asmdisk/test2   FGA          4096       2317       1779
D_B      /dev/asmdisk/test3   FGB          4096       2318       1778
D_C      /dev/asmdisk/test6   FGC          4096       2321       1775
@END

@B 2610MB씩 쓰던 두 디스크와 새 디스크가 1775~1779MB로 고르게 나뉘었다. 리밸런스의 목표는 모든 디스크의 사용률을 같게 만드는 것이다. 크기가 다른 디스크가 섞이면 크기에 비례해 나눈다.
@B 리밸런스가 도는 동안에도 데이터베이스는 같은 파일 이름으로 파일을 연다. 리밸런스는 익스텐트 층에서만 일어나고 파일과 별칭 층은 바뀌지 않는다(5장).
@B 이미 디스크그룹에 들어 있는 디스크를 다시 추가하면 ORA-15029(already mounted by this instance)가 난다. 추가 전에 `V$ASM_DISK`에서 대상이 CANDIDATE나 FORMER인지 확인한다.

@H2 6.5  용량 지표 — 디스크를 늘렸는데 쓸 공간이 줄었다

@P 디스크 2장에서 3장으로 늘린 뒤 `V$ASM_DISKGROUP`을 보면 총량은 늘었는데 `USABLE_FILE_MB`는 줄어 있다. 이 현상을 이해하면 Normal 이중화 디스크그룹의 용량을 제대로 읽을 수 있다.

@IMG 06_space.png | 그림 6-3. FREE_MB·REQUIRED_MIRROR_FREE_MB·USABLE_FILE_MB의 관계 — 장애 그룹이 셋 이상이 되면 한 그룹만큼을 예약한다

@H3 6.5.1  세 지표의 뜻

@TBL
지표 | 뜻
FREE_MB | 디스크에 남은 원시 공간. 이중화를 고려하지 않는다
REQUIRED_MIRROR_FREE_MB | 장애 그룹 하나를 잃었을 때 이중화를 다시 맞추려고 남겨 둬야 할 공간. 가장 큰 장애 그룹의 크기
USABLE_FILE_MB | 지금부터 안전하게 더 넣을 수 있는 데이터 양. Normal은 (FREE_MB − REQUIRED_MIRROR_FREE_MB) / 2
@END

@H3 6.5.2  2장에서 3장으로

@TBL
시점 | TOTAL_MB | FREE_MB | REQUIRED_MIRROR_FREE_MB | USABLE_FILE_MB
빈 TESTN (2장) | 8192 | 8076 | 0 | 4038
2500MB 적재 후 (2장) | 8192 | 2972 | 0 | 1486
test6 추가 후 (3장) | 12288 | 6956 | 4096 | 1430
@END

@B 장애 그룹이 둘이면 하나를 잃었을 때 남은 하나에 두 사본을 둘 수 없다. 복구가 불가능하니 예약할 공간도 계산하지 않아 0이다.
@B 셋이 되자 장애 그룹 하나(4096MB)를 잃어도 남은 둘에 미러를 다시 만들 수 있게 되었고, 그만큼을 예약한다. (6956 − 4096) / 2 = 1430으로 뷰의 값과 맞는다.
@B 1486에서 1430으로 줄어든 숫자는 손해가 아니다. 2장일 때의 1486은 디스크 한 장을 잃으면 이중화가 영구히 깨진 채로 남는 숫자였다.
@B 용량 감시는 `FREE_MB`가 아니라 `USABLE_FILE_MB`에 건다. 이 값이 음수가 되는 상황과 그 의미는 7장에서 직접 만들어 확인한다.

@H2 6.6  리밸런스 속도 — POWER

@P 파워는 동시에 일하는 ARB 슬레이브 수를 정한다. 기본값은 `ASM_POWER_LIMIT` 파라미터(기본 1)를 따르고, 명령마다 `REBALANCE POWER n`으로 지정하거나 진행 중에 바꿀 수 있다.

@H3 6.6.1  파워와 소요 시간

@TBL
작업 | 파워 | 소요 시간
디스크 추가 (test6) | 1 | 239.1초
디스크 추가 (test6) | 8 | 68.4초
디스크 제거 (d_c) | 1 | 88.4초
@END

@B 파워를 8배 올렸는데 3.5배쯤 빨라졌다. 슬레이브를 늘려도 디스크 대역폭이나 CPU가 먼저 한계에 닿으면 더 빨라지지 않는다. 가상 디스크가 한 물리 디스크를 나눠 쓰는 랩에서는 이 한계가 일찍 온다.
@B 제거가 추가보다 빨랐다. 제거는 나가는 디스크의 데이터만 옮기면 되지만 추가는 모든 디스크에 걸쳐 다시 고르게 나눈다.
@B 파워의 유효 범위는 0~1024다. 범위 밖 값을 주면 ORA-15102(invalid POWER expression)가 난다.

@H3 6.6.2  멈추고 재개하기

@CODE
SQL> alter diskgroup DATA rebalance power 0;   -- 중단
SQL> alter diskgroup DATA rebalance power 8;   -- 중단 지점부터 재개
@END

@TBL
파워 | 쓰임
0 | 리밸런스를 멈춘다. 취소가 아니라 중단이며 재개하면 이어서 진행한다
1 | 기본값. 업무 영향을 최소로 하고 오래 걸린다
4~8 | 야간·주말처럼 여유가 있을 때
그 이상 | 디스크가 많고 대역폭이 넉넉할 때만 효과가 있다
@END

@CASE 낮에 디스크를 더했다가 배치가 느려진 사례
스토리지 확장을 위해 업무 시간에 +DATA에 디스크를 추가했다. 파워는 기본값 1이었지만 리밸런스가 디스크 대역폭을 나눠 쓰면서 배치 응답 시간이 두 배가 되었다.
즉시 `REBALANCE POWER 0`으로 멈추고 야간에 파워 8로 재개해 남은 작업을 마쳤다. 추가 명령은 1초면 끝나도 그 뒤의 리밸런스는 몇 시간 갈 수 있으므로 디스크 추가는 작업 계획에 넣어 시간을 정한다.
@END

@H2 6.7  디스크 제거

@P 제거도 추가와 같이 명령은 즉시 끝나고 데이터 이동은 그 뒤에 일어난다. 이 절은 제거가 막히는 경우, 제거가 끝났는지 판단하는 방법, FORCE의 대가를 다룬다.

@IMG 06_drop.png | 그림 6-4. 정상 제거와 FORCE 제거 — 헤더가 FORMER로 정리되는지 MEMBER로 남는지가 갈린다

@H3 6.7.1  장애 그룹을 최소 요건까지 줄일 수 없다

@CODE
SQL> alter diskgroup TESTN drop disk d_c;
ORA-15032: not all alterations performed
ORA-59327: Dropping more fail groups is not allowed with disk group redundancy.
@END

@B 장애 그룹 3개인 Normal 디스크그룹에서 하나를 빼면 2개가 되어 한 장만 더 잃어도 복구할 수 없는 상태가 된다. 19c는 이 제거를 ORA-59327로 막는다.
@B 4개에서 3개로 줄이는 제거는 허용된다. 실습에서는 test5를 fgD로 먼저 더한 뒤 d_c를 뺀다.
@B 막혔을 때의 올바른 조치는 디스크를 먼저 추가해 여유를 만드는 것이다. FORCE로 뚫는 것은 답이 아니다.

@H3 6.7.2  DROPPING에서 FORMER까지

@TBL
시점 | NAME | HEADER_STATUS | MOUNT_STATUS | STATE | GROUP_NUMBER
drop 직후 | D_C | MEMBER | CACHED | DROPPING | TESTN 번호
리밸런스 완료 후 | (비어 있음) | FORMER | CLOSED | NORMAL | 0
@END

@B `STATE`가 DROPPING인 동안은 데이터를 다른 디스크로 옮기는 중이다. 그 디스크에 아직 유일한 사본이 있을 수 있다.
@B 헤더가 FORMER가 되고 `GROUP_NUMBER`가 0이 되어야 실제로 빠진 것이다. 이 상태의 디스크는 그대로 다른 디스크그룹에 쓸 수 있다.

@NOTE 디스크 회수 요청은 FORMER를 확인한 뒤에
`DROP DISK`가 성공했다는 메시지만 보고 스토리지 담당자에게 회수를 요청하면 DROPPING 중인 디스크를 뽑게 될 수 있다. `V$ASM_DISK`에서 그 경로의 `HEADER_STATUS`가 FORMER인지 확인한 다음에 물리적으로 분리한다.
@END

@H3 6.7.3  FORCE 제거의 대가

@B `DROP DISK d_c FORCE`를 실행하면 디스크 이름이 `_DROPPED_0002_TESTN`(형식: `_DROPPED_디스크번호_디스크그룹`)으로 바뀌고 `PATH`가 비며, 남은 데이터 이동이 끝날 때까지 목록에 남는다.
@B 리밸런스가 끝난 뒤 그 경로의 헤더는 FORMER가 아니라 MEMBER로 남는다. FORCE는 데이터를 옮기되 헤더를 정리하지 않는다.
@B 이 디스크를 다시 추가하면 ORA-15033(disk belongs to diskgroup "TESTN")으로 거절된다. 헤더가 아직 TESTN 소속이라고 적혀 있기 때문이다. `ADD ... FORCE`로 헤더를 덮어써야 들어간다.

@TBL
오류 | 상황 | 구분 기준
ORA-15029 | 지금 이 인스턴스가 쓰고 있는 디스크를 추가 | GROUP_NUMBER가 0이 아님
ORA-15033 | 헤더가 다른(또는 같은) 디스크그룹 소속으로 남은 디스크를 추가 | GROUP_NUMBER 0, HEADER_STATUS MEMBER
ORA-15054 | 디스크그룹에 없는 디스크 이름을 지정 | 오타이거나 이미 제거된 디스크
@END

@BP FORCE는 마지막 수단이다
FORCE를 반복하면 어느 디스크가 실제로 어느 디스크그룹에 속하는지 헤더만으로 알 수 없게 된다. 다른 클러스터가 쓰는 디스크의 헤더를 덮어쓰는 사고도 이런 상황에서 생긴다. 명령이 막히면 먼저 왜 막혔는지 확인하고, ADD에 FORCE를 붙일 때는 그 디스크가 정말 버려진 것인지 경로와 크기로 다시 확인한다.
@END

@H2 6.8  디스크 손실과 재동기화

@P 디스크가 응답하지 않으면 ASM은 바로 버리지 않고 OFFLINE으로 두고 `DISK_REPAIR_TIME` 동안 기다린다. 그 안에 돌아오면 변경분만 맞추고, 시간이 지나면 디스크를 버리고 전체 리밸런스로 이중화를 다시 맞춘다.

@IMG 06_resync.png | 그림 6-5. OFFLINE 이후 두 갈래 — 타이머 안에 ONLINE하면 fast mirror resync, 만료되면 자동 FORCE 제거와 전체 리밸런스

@H3 6.8.1  OFFLINE과 타이머

@CODE
SQL> alter diskgroup TESTN offline disk d_c;
NAME     PATH                 FAILGR MODE_ST STATE    REPAIR_TIMER
-------- -------------------- ------ ------- -------- ------------
D_A      /dev/asmdisk/test2   FGA    ONLINE  NORMAL              0
D_C                           FGC    OFFLINE NORMAL            180
@END

@B `MODE_STATUS`가 OFFLINE이 되고 `REPAIR_TIMER`에 남은 초가 잡힌다. `disk_repair_time` 3m이 180초로 나타났다.
@B `STATE`는 NORMAL이다. 제거(DROPPING)가 아니라 일시 이탈이라 데이터를 옮기지 않고, 그 디스크의 `USED_MB`도 그대로 남는다.
@B 3장에서 보팅 파일이 든 +CRS 디스크를 내렸을 때는 이 타이머가 0이었다. 보팅 파일 디스크는 mandatory 표시가 붙어 타이머 관리 방식이 다르다. TESTN에는 보팅 파일이 없으므로 타이머가 정상으로 돈다.
@B 장애 그룹 단위로 사라질 때 쓰는 `failgroup_repair_time`(기본 24.0h)도 따로 있다. `V$ASM_ATTRIBUTE`에서 이름에 repair가 들어간 속성을 조회하면 둘 다 보인다.

@H3 6.8.2  타이머가 만료되면

@CODE
WARNING: PST-initiated drop of 1 disk(s) in group 5(.2622516521))
SQL> alter diskgroup TESTN drop disk D_C force /* ASM SERVER */
SUCCESS: PST-initiated drop disk in group 5(2622516521))
NOTE: starting rebalance of group 5/0x9c506d29 (TESTN) at power 1
@END

@B 오프라인 3분 뒤 ASM이 스스로 `DROP DISK ... FORCE`를 실행했다. 명령 끝의 `/* ASM SERVER */` 주석이 사람이 아닌 ASM이 낸 명령이라는 표시다.
@B 디스크 이름이 `_DROPPED_0002_TESTN`, `STATE`가 FORCING으로 바뀌고 남은 장애 그룹으로 미러를 다시 만드는 리밸런스가 시작된다. 헤더는 MEMBER로 남으므로 되돌릴 때 6.7.3처럼 `ADD ... FORCE`가 필요하고 전체 리밸런스가 다시 일어난다.
@B 그동안 `srvctl status database -d racdb`는 두 인스턴스 모두 running이고 TS_REB도 ONLINE이었다. 장애 그룹 하나를 잃어도 모든 익스텐트의 사본이 남아 있기 때문이다.

@H3 6.8.3  타이머 안에 되돌리면 — fast mirror resync

@CODE
SQL> alter diskgroup TESTN set attribute 'disk_repair_time'='2h';
SQL> alter diskgroup TESTN offline disk d_c;
SQL> alter diskgroup TESTN online disk d_c;
NOTE: Starting resync using Staleness Registry and ATE scan for group 5
NOTE: completed online of disk group 5 disks
@END

@B 타이머를 2시간으로 늘리고 40초쯤 내렸다가 되돌렸다. ONLINE 명령부터 alert.log의 완료 기록까지 약 9초였다. 같은 크기의 디스크를 파워 1로 추가할 때 239초가 걸린 것과 비교된다.
@B 차이는 `Staleness Registry`에 있다. 디스크가 오프라인인 동안 그 디스크에 반영하지 못한 익스텐트를 따로 기록해 두고, 돌아오면 그 목록만 갱신한다. 이 기능이 fast mirror resync다.
@B 전제는 두 가지다. 오프라인 동안 디스크의 데이터가 지워지지 않았어야 하고(OFFLINE은 USED_MB를 유지한다), 디스크그룹의 `compatible.rdbms`가 11.1 이상이어야 한다. 3장에서 +CRS의 디스크 OFFLINE이 ORA-15283으로 막혔던 이유가 이 compatible 조건이었다.

@TBL
상황 | 동작 | 소요(이 랩)
디스크 추가, 파워 1 | 전체 리밸런스, 모든 디스크로 재분배 | 239.1초
디스크 추가, 파워 8 | 전체 리밸런스 | 68.4초
디스크 제거, 파워 1 | 나가는 디스크의 데이터만 이동 | 88.4초
타이머 안에 ONLINE | Staleness Registry 기반 변경분 재동기화 | 약 9초
@END

@CASE 스토리지 경로가 30분 끊기는 점검
스토리지 담당자가 멀티패스 펌웨어 교체로 한 컨트롤러 경로를 30분 끊겠다고 알려 왔다. 그 경로에 물린 디스크가 디스크그룹의 절반이었고, 장애 그룹이 컨트롤러 단위로 나뉘어 있었다.
DBA는 먼저 `disk_repair_time`이 작업 시간보다 넉넉한지 확인했다. 그다음 작업 직전에 해당 장애 그룹의 디스크를 직접 `OFFLINE`했다. ASM이 I/O 오류로 스스로 판단하게 두는 것보다 상태가 분명하다. 작업 뒤 `ALTER DISKGROUP ... ONLINE ALL`로 되돌리자 30분간의 변경분만 재동기화되어 몇 분 만에 끝났다.
@END

@H2 6.9  운영 지침

@TBL
상황 | 지침 | 근거
디스크 추가 계획 | 업무 시간에는 파워 1, 야간에는 4~8 | 파워는 선형으로 듣지 않고 리밸런스는 대역폭을 나눠 쓴다
리밸런스 중 업무 영향 | 파워 0으로 멈추고 한가할 때 재개 | 중단 지점부터 이어진다
완료 판정 | V$ASM_OPERATION이 비었는지 | SOFAR는 단계마다 새로 센다
디스크 물리 회수 | HEADER_STATUS가 FORMER가 된 뒤 | DROPPING 중에는 유일한 사본이 있을 수 있다
제거가 막힐 때 | FORCE 전에 이유 확인, 먼저 디스크 추가 | FORCE는 헤더를 MEMBER로 남긴다
스토리지 점검 예정 | disk_repair_time을 작업 시간보다 길게, 직접 OFFLINE | 넘기면 전체 리밸런스가 필요하다
용량 계획 | USABLE_FILE_MB로 판단 | FREE_MB에는 미러 몫과 예약 공간이 섞여 있다
장애 그룹 설계 변경 후 | 원본·미러 짝 조회로 검증 | 이름을 빠뜨리면 디스크마다 장애 그룹이 생긴다
@END

@H2 6.10  요약

@B ASM은 익스텐트마다 원본과 미러의 위치를 정한다. 두 사본은 반드시 다른 장애 그룹에 놓이고, 원본과 미러가 모든 디스크에 섞여 있어 읽기도 나눠 처리한다.
@B 디스크 추가·제거 명령은 즉시 끝나고 리밸런스가 뒤에서 돈다. 완료는 `V$ASM_OPERATION`이 비었는지로 판단한다.
@B RBAL이 계획하고 ARBA가 추정하며 ARB0 슬레이브가 옮긴다. 파워는 슬레이브 수이며 0으로 멈추고 다시 올려 재개한다.
@B `USABLE_FILE_MB` = (`FREE_MB` − `REQUIRED_MIRROR_FREE_MB`) / 2(Normal). 장애 그룹이 셋 이상이 되면 가장 큰 그룹만큼 예약해 쓸 공간이 줄어들 수 있다.
@B 장애 그룹을 최소 요건까지 줄이는 제거는 ORA-59327로 막힌다. 정상 제거는 헤더를 FORMER로 정리하고, FORCE 제거는 MEMBER로 남겨 재사용 때 ORA-15033을 부른다.
@B OFFLINE 디스크는 `DISK_REPAIR_TIME` 동안 기다린다. 만료되면 ASM이 스스로 FORCE 제거하고, 그 안에 ONLINE하면 Staleness Registry로 변경분만 재동기화한다.

@H2 6.11  퀴즈

@QUIZ 퀴즈
1. `x$kffxp`에서 디스크 0과 1이 SIDE 0과 1을 거의 같은 수로 가진다. ASM이 미러 전용 디스크를 두지 않는 이유는?
2. 리밸런스 중 `V$ASM_OPERATION`의 SOFAR가 1139에서 38로 떨어졌다. 실패한 것인가? 완료는 어떻게 판정하는가?
3. 디스크 2장인 Normal 디스크그룹에 한 장을 더했더니 USABLE_FILE_MB가 1486에서 1430으로 줄었다. 이유를 계산과 함께 설명하시오.
4. 장애 그룹 3개인 Normal 디스크그룹에서 디스크 하나를 빼려다 ORA-59327이 났다. 올바른 조치는?
5. FORCE로 제거한 디스크를 다시 추가하려니 ORA-15033이 났다. 원인과 해결 방법은?
6. 디스크를 OFFLINE한 뒤 타이머 안에 ONLINE한 경우와 타이머가 만료된 경우의 동작 차이를 쓰시오.
@END

@NOTE 정답과 해설
1. 원본과 미러를 섞어 두면 평소 읽기를 모든 디스크가 나눠 처리한다. 지켜야 할 규칙은 같은 익스텐트의 두 사본이 다른 장애 그룹에 놓이는 것 하나다.
2. 실패가 아니다. 리밸런스는 여러 단계로 진행되고 단계가 바뀌면 SOFAR와 EST_WORK가 새로 시작한다. V$ASM_OPERATION에 그 디스크그룹의 행이 없으면 완료다.
3. 장애 그룹이 둘일 때는 하나를 잃으면 복구가 불가능해 REQUIRED_MIRROR_FREE_MB가 0이었다. 셋이 되자 한 그룹(4096MB)을 예약해 (6956−4096)/2=1430이 되었다. 디스크를 잃어도 이중화가 복원되는 보장의 값이다.
4. 제거하면 장애 그룹이 최소 요건인 2개가 되어 막힌 것이다. 디스크를 먼저 추가해 장애 그룹을 4개로 만든 뒤 제거한다.
5. FORCE 제거는 헤더를 FORMER로 정리하지 않고 MEMBER로 남긴다. 헤더가 TESTN 소속이라고 적혀 있어 거절된다. 버려진 디스크임을 확인한 뒤 ADD ... FORCE로 헤더를 덮어쓴다.
6. 타이머 안에 ONLINE하면 Staleness Registry에 기록된 변경분만 재동기화해 수 초에 끝난다. 만료되면 ASM이 DROP DISK ... FORCE를 실행하고 전체 리밸런스로 미러를 다시 만들며, 그 디스크는 헤더가 MEMBER로 남는다.
@END

@H2 6.12  실습 개요

@P 실습은 TESTN 하나를 만들어 끝까지 이어 쓴다. 시작 전에 test1~6이 FORMER 또는 CANDIDATE 상태인지 `V$ASM_DISK`로 확인한다. 06은 디스크를 실제로 잃는 실습이지만 대상이 실습용 디스크그룹이라 racdb에는 영향이 없다.

@TBL
실습 | 파일 | 목적
01 ★ | RAC/08장/8장_실습_01_디스크배치확인.txt | TESTN을 만들어 두 노드에서 마운트하고 데이터를 채운 뒤 x$kffxp로 익스텐트 분포를 읽는다
02 | RAC/08장/8장_실습_02_디스크추가와리밸런스.txt | test6을 추가하고 V$ASM_OPERATION과 alert.log로 리밸런스 진행을 관찰한다
04 | RAC/08장/8장_실습_04_디스크제거.txt | ORA-59327, DROPPING에서 FORMER까지의 변화, FORCE 제거와 ORA-15033을 확인한다
05 | RAC/08장/8장_실습_05_장애그룹검증.txt | 원본과 미러 짝 조회로 장애 그룹 규칙이 지켜지는지 검증한다
06 ⚠ | RAC/08장/8장_실습_06_디스크강제손실.txt | 디스크를 OFFLINE하고 3분 타이머 만료 후 ASM의 자동 FORCE 제거를 관찰한다
07 | RAC/08장/8장_실습_07_복구와재동기화.txt | 타이머 안에 ONLINE해 fast mirror resync를 확인하고 TESTN을 지워 기준선으로 돌린다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습, ⚠는 실습 전에 `-BackupShared` 사본을 남겨 두는 실습이다.
@B 실습 04는 TESTN에 디스크 4장이 있다고 가정한다. 실습 03을 건너뛰었으면 04 앞에서 03의 첫 단계(test5를 fgD로 추가)만 실행한다.
@B test 디스크가 `V$ASM_DISK`에 보이지 않으면 설치 가이드 v2 부록 E의 절차(host/04_add_test_disks.ps1, node/15_udev_testdisks.sh)로 추가했는지 확인한다.
@B 수료 후 자습: 8장_실습_03_리밸런스속도조절(파워 1과 8 비교, 파워 0 중단과 재개, ORA-15102).
@B 실습 07 끝에서 `disk_repair_time`을 3.6h로 되돌리고 TS_REB 테이블스페이스와 TESTN을 지운다. rac2에서 먼저 dismount한 뒤 rac1에서 drop하고, test 디스크가 모두 FORMER로 돌아왔는지 확인한다.
