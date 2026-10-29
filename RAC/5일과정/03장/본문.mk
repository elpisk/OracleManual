@H1 제3장  OCR과 Voting File 관리

@H2 3.1  학습 목표

@P Clusterware는 세 가지 저장소 위에서 돈다. 클러스터가 공유하는 OCR, 노드마다 하나씩 있는 OLR, 노드들이 서로의 생존을 확인하는 Voting File이다. 이 장은 세 저장소의 구조를 읽고, 백업을 만들고, 다중화와 재배치를 해 보고, 디스크 하나를 일부러 내려 클러스터의 반응을 확인한다.

@B OCR과 OLR의 위치·범위·읽는 주체를 구분하고 `ocr.loc`, `olr.loc`를 읽을 수 있다.
@B PROT-24/PROT-25의 의미를 알고 OCR 자동 백업 주기와 OLR 백업 시점을 설명할 수 있다.
@B root로 `ocrconfig -manualbackup`과 `-export`를 실행하고 두 백업의 차이를 말할 수 있다.
@B OCR을 다중화하고 되돌리며 PROT-28·29·30의 의미를 구분할 수 있다.
@B Voting File 개수가 디스크그룹 이중화로 정해지는 원리와 과반수 규칙을 설명할 수 있다.
@B `crsctl replace votedisk`의 동작과 CRS-4258·4261·4628을 읽을 수 있다.
@B 클러스터가 떠 있을 때 복원이 막히는 이유(PROT-19)와 배타 모드 복구 절차를 말할 수 있다.

@NOTE 이 장의 실습 하나는 디스크를 실제로 내린다
실습 05-06은 Voting File이 들어 있는 디스크를 OFFLINE으로 내리고, 되돌릴 수 없는 속성 변경(compatible.rdbms 상향)을 남긴다. 공유 디스크는 independent-persistent라 VM 스냅샷에 들어가지 않는다. 시작 전에 두 노드를 정지하고 `90_snapshot.ps1 -BackupShared`로 D:\RAC\SHARED 사본을 남긴다.
@END

@H2 3.2  OCR과 OLR

@P 2장에서 OHAS 스택은 OLR을, CRS 스택은 OCR을 읽는다고 했다. 두 레지스트리는 같은 형식이지만 범위와 위치가 다르다. 이 차이가 부팅 순서와 복구 방법을 결정한다.

@IMG 03_registry.png | 그림 3-1. OCR과 OLR — 부트스트랩 파일이 위치를 알려 주고, OLR은 로컬에서 OCR은 +CRS에서 읽힌다

@H3 3.2.1  레지스트리의 구조

@B OCR은 점으로 구분된 키 경로와 값의 트리다. `ocrdump 파일명`으로 내용을 텍스트로 뽑을 수 있다.
@B 키마다 타입(UB4, ORATEXT 등)과 SECURITY 블록이 붙는다. 접근 제어는 키 단위로 이루어진다.
@B 노드별 버전과 패치 수준도 OCR 안에 따로 기록된다. 롤링 패치 중 노드마다 버전이 달라도 클러스터가 동작하는 근거가 여기 있다.
@B 자원 정의, 노드 목록, VIP와 SCAN 구성, OCR 백업 위치(`SYSTEM.OCR.BACKUP.LOC`)까지 클러스터 구성이 모두 OCR에 있다.

@H3 3.2.2  OCR과 OLR의 분업

@TBL
구분 | OCR | OLR
범위 | 클러스터 전체 공유 1벌 | 노드마다 1벌
위치 | +CRS 디스크그룹 안 | /u01/app/grid/crsdata/rac1/olr/rac1_19.olr
읽는 주체 | crsd | ohasd
위치 파일 | /etc/oracle/ocr.loc | /etc/oracle/olr.loc
확인 | ocrcheck | ocrcheck -local
백업 | ocrconfig -manualbackup | ocrconfig -local -manualbackup
자동 백업 | crsd가 4시간 주기 | 설치·구성 변경 시점
@END

@B OCR은 ASM 안에 있는데 ASM 인스턴스를 띄우려면 먼저 ASM을 어떻게 띄울지 알아야 한다. 그 정보가 OLR에 있다. OLR이 로컬 파일이어야 하는 이유다.
@B OLR은 노드마다 별개의 레지스트리다. rac1과 rac2의 OLR ID가 다르고 OCR ID는 같다.

@H3 3.2.3  ocrcheck와 ocr.loc 읽기

@CODE
[root@rac1 ~]# ocrcheck
         ID                       :  665666554
         Device/File Name         :       +CRS
                                    Device/File integrity check succeeded
         Cluster registry integrity check succeeded
         Logical corruption check succeeded
[root@rac1 ~]# cat /etc/oracle/ocr.loc
ocrconfig_loc=+CRS/rac-cluster/OCRFILE/registry.255.1242760249
local_only=false
@END

@B ID는 이 클러스터의 OCR을 식별한다. 다중화하거나 위치를 옮겨도 바뀌지 않는다. 작업 전후에 ID가 다르면 다른 OCR을 물고 있다는 뜻이므로 기준값으로 기록해 둔다.
@B Cluster registry integrity check는 저장 위치의 블록 체크섬을, Logical corruption check는 키 트리의 부모·자식 관계를 검사한다. 물리적으로 멀쩡하고 논리적으로 깨진 OCR이 있을 수 있다.
@B `ocr.loc`는 OCR 위치를 알려 주는 평문 부트스트랩 파일이다. `ocrcheck -config`는 디스크그룹 이름까지, `ocr.loc`는 ASM 파일 번호까지 보여 준다.
@B `local_only=false`는 클러스터 구성원이라는 뜻이다. Oracle Restart 환경에서는 true다.
@B 조회(`ocrcheck`, `-showbackup`)는 grid로 되지만 변경(`-manualbackup`, `-export`, `-add`, `-delete`)은 root만 된다. grid로 실행하면 PROT-20(Require privileged user)이다.

@BP OCR 위치는 명령으로만 바꾼다
`ocr.loc`를 손으로 고치면 노드 사이, 그리고 ASM 안의 실제 파일과 어긋난다. `ocrconfig -add/-delete/-replace`는 모든 노드의 `ocr.loc`와 실제 파일을 함께 맞춘다. 한 노드만 어긋났을 때 쓰는 `ocrconfig -repair`는 그 노드의 CRS가 내려가 있어야 동작한다.
@END

@H2 3.3  백업 상태 진단

@P 2장 실습 04-06에서 Grid 홈 도구를 확인할 때 `ocrconfig -showbackup`이 PROT-24와 PROT-25를 돌려줬다. 설치 직후의 클러스터에는 OCR 백업이 한 벌도 없다.

@CODE
[root@rac1 ~]# ocrconfig -showbackup
PROT-24: Auto backups for the Oracle Cluster Registry are not available
PROT-25: Manual backups for the Oracle Cluster Registry are not available
@END

@B 두 메시지는 오류가 아니라 상태 보고다. PROT-24는 자동 백업이, PROT-25는 수동 백업이 없다는 뜻이다. `-showbackup auto`, `-showbackup manual`로 따로 물을 수 있다.
@B 수동 백업이 없는 이유는 아무도 실행하지 않았기 때문이다.
@B 자동 백업은 crsd가 4시간 주기로 만든다. 이 타이머는 crsd가 재시작될 때마다 처음부터 다시 센다. VM을 필요할 때만 켜는 실습 환경이나 매일 클러스터를 내렸다 올리는 사이트에서는 자동 백업이 계속 만들어지지 않을 수 있다.
@B crsd 기동 시각은 `ps -eo pid,lstart,cmd | grep crsd.bin`으로 확인한다. 4시간이 지나지 않았으면 PROT-24는 당연한 결과다.

@H3 3.3.1  OLR 백업은 이미 있다

@CODE
[root@rac1 ~]# ocrconfig -local -showbackup
rac1  2026/08/31 19:27:29  /u01/app/grid/crsdata/rac1/olr/autobackup_20260831_192729.olr  724960844
rac1  2026/08/31 19:14:14  /u01/app/grid/crsdata/rac1/olr/backup_20260831_191414.olr      724960844
@END

@B OLR 백업은 설치 시점에 두 벌 만들어졌다. root.sh가 OLR을 만든 직후의 backup과, 구성이 끝난 뒤의 autobackup이다. OLR 자동 백업은 구성 변경 같은 사건을 계기로 만들어진다.
@B OLR 백업은 노드 로컬이다. rac2에서는 rac2의 백업만 보인다. 노드가 통째로 사라지면 그 노드의 OLR 백업도 함께 사라지므로 이때는 복원보다 노드 재구축을 택한다.
@B 줄 끝의 724960844는 패치 수준이다. 패치 수준이 다른 백업으로 복원하면 안 되므로 목록에 함께 표시된다.

@H3 3.3.2  백업이 놓이는 곳

@B 11g 시절 자료는 OCR 백업 위치로 `GRID_HOME/cdata/<클러스터명>`을 든다. 19c에서 이 디렉터리는 없고, 백업 위치의 기본값은 OCR이 있는 디스크그룹(+CRS)이다.
@B 백업 위치 설정 자체가 OCR의 `SYSTEM.OCR.BACKUP.LOC` 키에 들어 있다. 어느 노드에서 조회해도 같은 값이 나온다.

@H2 3.4  백업을 만든다

@P OCR 백업은 두 가지다. OCR 저장 영역을 통째로 뜨는 물리적 백업과, 존재하는 키만 직렬화하는 논리적 내보내기다.

@IMG 03_backup.png | 그림 3-2. 두 가지 백업 — manualbackup은 OCR 마스터 노드가 +CRS에, export는 명령을 실행한 노드의 로컬 파일로 남긴다

@H3 3.4.1  수동 백업

@CODE
[root@rac1 ~]# ocrconfig -manualbackup
rac2  2026/09/01 16:09:24  +CRS:/rac-cluster/OCRBACKUP/backup_20260901_160924.ocr.258.1242835765  724960844
@END

@B 백업 파일은 +CRS 안의 정규 ASM 파일이다. `.258.1242835765`는 ASM 파일 번호와 incarnation이다(5장).
@B 맨 앞의 노드 이름이 rac2다. 명령은 rac1에서 실행했지만 백업은 OCR 마스터 노드가 수행한다. crsd 추적 파일에 `Manual backup request received` 기록이 남는다.
@B asmcmd로 보면 파일 종류가 OCRBACKUP이고 Redund가 MIRROR다. +CRS가 Normal이므로 백업 파일도 두 벌로 저장된다.

@H3 3.4.2  백업 위치는 공유 저장소여야 한다

@CODE
[root@rac1 ~]# ocrconfig -backuploc /u01/app/grid/ocrbackup
PROT-42: The specified location '/u01/app/grid/ocrbackup' designates an invalid
         storage type for Oracle Cluster Registry backup files.
@END

@B PROT-42는 저장소 종류를 문제 삼는다. `/u01`은 노드 로컬 디스크다. 한 노드에만 백업이 쌓이면 그 노드가 사라질 때 백업도 사라지므로 Clusterware가 이를 거절한다.
@B 유효한 위치는 ASM 디스크그룹이나 모든 노드가 공유하는 파일 시스템이다. 실습 뒤에는 `ocrconfig -backuploc +CRS`로 되돌린다.

@H3 3.4.3  논리적 내보내기

@CODE
[root@rac1 ~]# ocrconfig -export /root/ocr_ch5.dmp
PROT-58: successfully exported the Oracle Cluster Registry contents to file
         '/root/ocr_ch5.dmp'
@END

@TBL
항목 | -manualbackup (물리) | -export (논리)
대상 | OCR 저장 영역 전체 | 존재하는 키만
크기 | 수백 MB | 수백 KB
저장 위치 | ASM 또는 공유 파일 시스템만 | 제약 없음
수행 노드 | OCR 마스터 노드 | 명령을 실행한 노드
되살리기 | ocrconfig -restore | ocrconfig -import
용도 | 일상 백업, 자동 백업 | 구성 변경 직전, 클러스터 밖 보관
@END

@BP 두 가지를 함께 남긴다
물리 백업은 +CRS 안에 있어서 디스크그룹이 통째로 사라지면 같이 사라진다. export 파일은 어디에나 둘 수 있다. 설치 직후와 구성 변경 직전에 `-manualbackup`과 `-export`를 함께 실행하고, export 파일은 클러스터 밖으로 복사한다.
@END

@CASE 백업이 없는 상태에서 +CRS를 잃은 사례
교육용 클러스터에서 실습 도중 +CRS 디스크그룹이 통째로 손상됐다. `-showbackup`은 PROT-24/PROT-25였다. 자동 백업 주기가 돌기 전이었고 수동 백업은 아무도 만들지 않았다.
복원할 대상이 없어 두 노드의 Clusterware 구성을 지우고 Grid Infrastructure를 다시 구성했다. +DATA의 데이터베이스 파일은 남아 있었지만 `srvctl add database`부터 자원을 다시 등록해야 했다. 설치 직후 백업 두 줄이면 피할 수 있던 작업이다.
@END

@H2 3.5  OCR 다중화

@P OCR은 최대 5곳까지 등록할 수 있다. 모든 위치에 같은 내용이 기록되므로 한 위치가 손상되어도 나머지로 계속 동작한다.

@CODE
[root@rac1 ~]# ocrconfig -add +NOSUCHDG
PROT-30: The Oracle Cluster Registry location to be added is not usable.
PROC-50: The Oracle Cluster Registry location to be added is inaccessible on nodes rac1.
[root@rac1 ~]# ocrconfig -add +CRS
PROT-29: The Oracle Cluster Registry location is already configured
[root@rac1 ~]# ocrconfig -add +DATA
@END

@B PROT-30은 판정, PROC-50은 근거다. PROC-50은 디스크그룹에 접근하지 못한 노드 이름을 알려 준다. 3노드 이상에서 한 노드만 마운트하지 못했을 때 그 노드가 여기 나온다.
@B `-add +DATA` 뒤 `ocrcheck`에는 +CRS와 +DATA 두 위치가 나오고 ID는 그대로다. 남은 `Device/File not configured` 줄은 빈 슬롯이다. ocrcheck는 항상 5개 슬롯을 보여 준다.
@B rac1에서 명령 한 번을 실행했지만 rac2의 `ocr.loc`에도 `ocrmirrorconfig_loc` 줄이 생긴다. 변경은 모든 노드에 전파된다.
@B 같은 OCR이 +CRS에서는 MIRROR, +DATA에서는 UNPROT으로 저장된다. 위치마다 보호 수준이 다를 수 있다.

@H3 3.5.1  마지막 한 벌은 지울 수 없다

@B 두 벌일 때는 한 위치를 `-delete`로 지워도 클러스터는 계속 돈다.
@B 한 벌만 남은 상태에서 지우려 하면 PROT-28(Cannot delete or replace the only configured location)로 막힌다.
@B 지웠다 다시 만든 위치는 ASM 파일 번호와 incarnation이 바뀐다. 내용은 같으므로 ocrcheck의 ID는 변하지 않는다.
@B 위치를 옮길 때는 새 위치를 `-add`하고 검증한 뒤 옛 위치를 `-delete`한다. `-replace`는 한 명령으로 끝나지만 중간 상태를 검증할 기회가 없다.

@H2 3.6  Voting File

@P Voting File은 노드들이 생존 신호를 쓰고 서로의 신호를 읽는 공용 게시판이다. 인터커넥트 하트비트가 끊겼을 때 어느 쪽이 살아남을지도 여기서 정한다.

@IMG 03_voting.png | 그림 3-3. Voting File과 과반수 — 개수는 디스크그룹 이중화가 정하고, 노드는 과반수에 접근할 수 있어야 남는다

@CODE
[root@rac1 ~]# crsctl query css votedisk
##  STATE    File Universal Id                File Name Disk group
 1. ONLINE   838fca0461384f6cbfe0440187190bd9 (/dev/asmdisk/crs1) [CRS]
 2. ONLINE   4c38f09d6d7b4f1fbfc0e6b7055c8515 (/dev/asmdisk/crs2) [CRS]
 3. ONLINE   370e2d1c1e604f6ebfd6c8aa3b8c0d35 (/dev/asmdisk/crs3) [CRS]
Located 3 voting disk(s).
@END

@H3 3.6.1  개수는 이중화가 정한다

@TBL
디스크그룹 이중화 | Voting File 수 | 견디는 손실 | 최소 장애 그룹
External | 1 | 0 | 1
Normal | 3 | 1 | 3
High | 5 | 2 | 5
@END

@B +CRS가 Normal이고 디스크 세 장이 각각 다른 장애 그룹에 있어 Voting File이 3개다. 개수는 사람이 정하지 않는다.
@B 노드는 Voting File의 과반수(3개 중 2개)에 접근할 수 있어야 구성원으로 남는다. 짝수면 반반으로 갈렸을 때 결론이 나지 않으므로 홀수를 쓴다.
@B ASM 쪽에서는 `V$ASM_DISKGROUP.VOTING_FILES`(CRS만 Y)와 `V$ASM_DISK.VOTING_FILE`로 확인한다.

@NOTE Voting File은 ASM 파일이 아니다
`asmcmd ls +CRS/rac-cluster/`에는 ASMPARAMETERFILE, OCRBACKUP, OCRFILE만 나오고 Voting File은 없다. Voting File은 디스크의 정해진 위치에 직접 기록된다. CSS는 ASM 인스턴스가 뜨기 전에 Voting File을 읽어야 하기 때문이다. 그래서 File Name 열에 원시 장치 경로가 찍힌다.
@END

@H3 3.6.2  개별 추가·삭제는 막혀 있다

@B Voting File이 ASM에 있으면 `crsctl add css votedisk`와 `crsctl delete css votedisk`는 CRS-4258(not allowed because the voting files are on ASM)로 거절된다. 권한 문제가 아니라 구성 방식의 규칙이다.
@B 남은 수단은 `crsctl replace votedisk +디스크그룹` 하나다. 디스크그룹 단위로 통째로 옮긴다.
@B 같은 디스크그룹으로 replace하면 CRS-4261(already configured with voting files)이다.

@CODE
[root@rac1 ~]# crsctl replace votedisk +NOSUCHDG
CRS-4648: Failed to create voting files on disk group NOSUCHDG.
CLSU-00104: additional error information: ORA-15001: diskgroup "NOSUCHDG" does not
            exist or is not mounted
CRS-4646: Disk group NOSUCHDG does not exist or is not mounted.
CRS-4628: Change to configuration failed, but was successfully rolled back.
@END

@B 실제 원인 ORA-15001은 스택 아래쪽에 있다. CRS 계층 메시지 사이에 ASM 계층 오류가 끼어 있으므로 아래부터 읽는다.
@B CRS-4628은 실패했지만 롤백에 성공했다는 보증이다. 이 줄이 없는 실패라면 `crsctl query css votedisk`로 현재 상태를 직접 확인한다.

@H3 3.6.3  다른 디스크그룹으로 옮겼다 되돌리기

@B `crsctl replace votedisk +DATA`를 실행하면 새 위치에 1개를 추가한 뒤 옛 위치의 3개를 삭제한다. 어느 순간에도 0개가 되지 않아 무중단으로 옮겨진다.
@B +DATA는 External이라 Voting File이 1개가 된다. data1 디스크 하나만 잃어도 클러스터 전체가 내려가는 위험한 상태다.
@B `crsctl replace votedisk +CRS`로 되돌리면 다시 3개가 되지만 FUID(File Universal Id)는 모두 새 값이다. 새로 만들 때마다 새 FUID가 붙으므로 작업 전후 FUID를 기록해 두면 실제로 새로 만들어졌는지 확인할 수 있다.
@B 작업 내내 `crsctl check cluster -all`은 정상이고 racdb1, racdb2도 그대로다. ASM alert.log에는 `Creating voting files in diskgroup: CRS`와 `Refresh completed ... Found 3 voting file(s)`가 두 노드에 모두 남는다.

@H2 3.7  디스크를 내려 본다

@P Voting File을 담은 디스크 하나를 OFFLINE으로 내리고 클러스터가 어떻게 반응하는지 본다. 그 전에 디스크그룹 속성 때문에 한 번 막힌다.

@H3 3.7.1  compatible.rdbms 때문에 막힌다

@CODE
SYS@+ASM1> alter diskgroup CRS offline disk CRS_0002;
ORA-15032: not all alterations performed
ORA-15283: ASM operation requires compatible.rdbms of 11.1.0.0.0 or higher
SYS@+ASM1> alter diskgroup CRS set attribute 'compatible.rdbms'='11.2.0.0.0';
Diskgroup altered.
@END

@B ORA-15032는 포괄 메시지이고 원인은 ORA-15283이다. +CRS는 compatible.asm이 19.0.0.0.0인데 compatible.rdbms가 10.1.0.0.0이다. 설치 때 이 속성을 지정하지 않아 가장 낮은 값이 들어갔다.
@B 디스크 OFFLINE/ONLINE(fast mirror resync)은 11.1에서 들어온 기능이라 compatible.rdbms 11.1 이상이 필요하다.
@B compatible 속성은 올릴 수만 있다. 11.2로 올린 뒤 10.1로 되돌리면 ORA-15242와 ORA-15244(new compatibility setting less than current)가 난다. 낮추려면 디스크그룹을 다시 만들어야 하고, +CRS를 다시 만든다는 것은 클러스터 재구성이다. 필요한 최소 값만 올린다(4장).

@H3 3.7.2  OFFLINE 후의 상태

@IMG 03_offline.png | 그림 3-4. 디스크 OFFLINE과 ONLINE — Voting File은 3개에서 2개로 줄었다가 새 FUID로 다시 3개가 된다

@CODE
NAME       PATH                MODE_ST STATE  REPAIR_TIMER V
---------- ------------------- ------- ------ ------------ -
CRS_0000   /dev/asmdisk/crs1   ONLINE  NORMAL            0 Y
CRS_0001   /dev/asmdisk/crs2   ONLINE  NORMAL            0 Y
CRS_0002                       OFFLINE NORMAL            0 N
@END

@B CRS_0002의 MODE_STATUS가 OFFLINE이 되고 PATH가 비고 VOTING_FILE이 N이 됐다. ASM이 그 디스크를 더 이상 열어 두지 않는다.
@B 디스크그룹은 MOUNTED이고 OFFLINE_DISKS가 1이다. TOTAL_MB는 그대로다. 디스크는 구성원으로 남아 있고 일시적으로 접근 불가로 표시될 뿐이다.
@B `crsctl query css votedisk`는 2개를 보여 준다. 3개 중 2개는 과반수이므로 두 노드 모두 CRS-4537/4529/4533 online이고 데이터베이스도 그대로 돈다.
@B ASM alert.log에는 GMON이 PST(Partner Status Table)를 갱신하는 `op = clear mandatory`와, 이어서 `Voting file relocation is required`, `Successful voting file relocation`이 남는다. 디스크 OFFLINE과 Voting File 조정은 별개의 단계다.
@B 보통 디스크라면 REPAIR_TIMER가 `disk_repair_time`부터 줄어든다. Voting File을 담았던 디스크는 mandatory 속성이 해제되어 타이머가 0에 머문다. 리밸런스와 repair timer는 6장에서 다룬다.

@H3 3.7.3  ONLINE으로 되돌리기

@B `alter diskgroup CRS online disk CRS_0002`로 올리면 PATH가 돌아오고 VOTING_FILE이 Y가 되며 OFFLINE_DISKS는 0이 된다. alert.log에는 `op = assign mandatory`와 리밸런스 완료가 남는다.
@B Voting File은 다시 3개지만 세 번째 FUID는 내리기 전과 다르다. 디스크가 돌아오면 ASM이 Voting File을 새로 배치한다. 복구 여부는 FUID가 아니라 개수와 STATE로 판단한다.

@BP 운영에서 디스크를 내리기 전에
`USABLE_FILE_MB`가 음수가 아닌지, 그 디스크가 `VOTING_FILE=Y`인지, `disk_repair_time`이 교체 작업 시간보다 긴지 확인한다. 작업 전후에는 `crsctl query css votedisk`와 `ocrcheck`의 ID를 기록해 대조한다.
@END

@H2 3.8  복구 절차

@P 복원 명령은 클러스터가 떠 있으면 실행되지 않는다. crsd가 OCR을 열어 두고 계속 읽고 쓰기 때문이다.

@CODE
[root@rac1 ~]# ocrconfig -restore +CRS:/rac-cluster/OCRBACKUP/backup_20260901_160924.ocr.258.1242835765
PROT-19: Cannot proceed while the Cluster Ready Service is running
@END

@B `-restore`, `-import`, `-repair`가 모두 PROT-19로 막힌다. 복구는 모든 노드의 `crsctl stop crs`에서 시작한다.

@IMG 03_recovery.png | 그림 3-5. OCR 전체 복원 — 모든 노드를 내리고 한 노드만 배타 모드로 올려 ASM만 띄운 상태에서 복원한다

@TBL
상황 | 진단 | 조치
다중화된 OCR 중 한 위치 손상 | ocrcheck에서 그 위치만 실패 | -delete 후 -add. 무중단
OCR 전체 손상 | ocrcheck 실패, crsd 기동 실패 | 전 노드 stop crs → 한 노드 start crs -excl -nocrs → -restore → 정상 기동
한 노드만 ocr.loc 불일치 | 그 노드만 crsd 기동 실패 | 그 노드 stop crs → ocrconfig -repair → 기동
Voting File 1개 손실(Normal) | votedisk가 2개 | 디스크 복구 후 ONLINE, 자동 재배치
Voting File 과반수 손실 | 전 노드 CSS 기동 실패 | start crs -excl -nocrs → replace votedisk
+CRS 디스크그룹 소실 | ASM 마운트 실패 | 디스크그룹 재생성 → replace votedisk → -restore
특정 노드 OLR 손상 | 그 노드 ohasd 기동 실패 | ocrconfig -local -restore 또는 노드 재구축
@END

@B 반복되는 패턴이 있다. Voting File은 replace로, OCR은 restore로 되살리고, 대부분의 절차가 배타 모드 기동을 거친다.
@B `crsctl start crs -excl -nocrs`는 한 노드에서만, crsd 없이 스택을 올린다. ASM은 떠서 +CRS를 마운트하지만 crsd가 없으므로 PROT-19를 피할 수 있다.
@B 복원 뒤에는 `crsctl stop crs -f`로 배타 모드를 끝내고 모든 노드에서 `crsctl start crs`로 정상 기동한다. 배타 모드 스택은 정상 종료 경로를 따르지 않아 `-f`가 필요하다.
@B 백업 경로는 `ocrconfig -showbackup`이 보여 준 문자열을 그대로 복사해 쓴다.

@H3 3.8.1  평상시 점검 항목

@B 설치 직후와 구성 변경 직전에 `-manualbackup`과 `-export`를 함께 실행하고 export 파일을 클러스터 밖으로 옮긴다.
@B `ocrcheck`의 ID와 `crsctl query css votedisk`의 FUID 목록을 기록해 둔다.
@B `ocrconfig -showbackup`을 주기 점검에 넣는다. PROT-24가 계속 나오면 crsd가 자주 재시작되고 있다는 신호다.

@H2 3.9  요약

@B OCR은 +CRS 안의 클러스터 공유 레지스트리, OLR은 노드 로컬 레지스트리다. crsd는 OCR을, ohasd는 OLR을 읽는다.
@B 설치 직후에는 OCR 백업이 없다(PROT-24/25). 자동 백업은 crsd 연속 가동 4시간마다 만들어지고, OLR 백업은 설치 시점에 이미 있다.
@B OCR 백업은 root만 만들 수 있고(PROT-20), OCR 마스터 노드가 +CRS에 만든다. 로컬 디렉터리는 PROT-42로 거절된다. export는 어디에나 둘 수 있다.
@B OCR은 5곳까지 다중화하며 변경은 모든 노드의 ocr.loc에 전파된다. 마지막 한 벌은 PROT-28로 보호된다.
@B Voting File 개수는 디스크그룹 이중화가 정한다. ASM에 있으면 개별 추가·삭제는 CRS-4258로 막히고 replace만 된다.
@B Normal 디스크그룹의 디스크 하나를 내려도 Voting File 2개로 과반수가 유지된다. 디스크 OFFLINE에는 compatible.rdbms 11.1 이상이 필요하고 이 속성은 올릴 수만 있다.
@B 복원은 PROT-19 때문에 모든 노드를 내리고 배타 모드에서 한다.

@H2 3.10  퀴즈

@QUIZ 퀴즈
1. 작업 전후로 `ocrcheck`의 ID가 바뀌었다면 무엇을 의심해야 하는가?
2. 설치 후 하루가 지났는데도 PROT-24가 나온다. 가능한 원인과 대책은?
3. rac1에서 `ocrconfig -manualbackup`을 실행했는데 출력 첫 칸에 rac2가 찍혔다. 오류인가?
4. `ocrconfig -backuploc /u01/app/grid/ocrbackup`이 PROT-42로 거절되는 이유는?
5. +CRS의 디스크 하나를 OFFLINE으로 내려도 클러스터가 계속 도는 이유를 과반수 규칙으로 설명하시오.
6. `ocrconfig -restore`가 PROT-19로 막혔다. 다음 단계는 무엇인가?
@END

@NOTE 정답과 해설
1. 다른 클러스터의 OCR을 가리키고 있을 가능성. 다중화나 위치 이동으로는 ID가 바뀌지 않는다.
2. crsd가 4시간 연속 가동되지 않았다. 타이머는 crsd 재시작 때마다 초기화된다. 정지 전에 manualbackup을 실행하는 절차를 둔다.
3. 아니다. OCR 백업은 명령을 받은 노드가 아니라 OCR 마스터 노드가 수행한다.
4. /u01은 노드 로컬 디스크다. 그 노드가 사라지면 백업도 사라지므로 ASM이나 공유 파일 시스템만 허용한다.
5. Normal 이중화라 Voting File이 3개이고 노드는 과반수(2개)에 접근하면 구성원으로 남는다. 디스크 하나를 잃어도 2개가 남는다.
6. 모든 노드에서 crsctl stop crs, 한 노드에서 crsctl start crs -excl -nocrs로 ASM만 올린 뒤 복원하고, stop crs -f 후 모든 노드를 정상 기동한다.
@END

@H2 3.11  실습 개요

@P 실습 05-01부터 05-05까지는 끝에서 원래 구성으로 되돌린다. 실습 05-06은 디스크를 내렸다 올리며 되돌릴 수 없는 속성 변경을 남긴다. 실습 번호는 폴더 번호와 파일 번호를 이은 것이다.

@TBL
실습 | 파일 | 목적
05-01 | RAC/05장/5장_실습_01_현재구성확인.txt | ocrcheck, ocr.loc, olr.loc, votedisk를 읽고 대조 기준을 기록한다
05-02 | RAC/05장/5장_실습_02_백업상태진단.txt | PROT-24/25의 원인을 crsd 기동 시각으로 설명하고 OLR 백업을 확인한다
05-03 | RAC/05장/5장_실습_03_수동백업과내보내기.txt | PROT-20·42를 재현하고 manualbackup과 export를 만든다
05-05 ★ | RAC/05장/5장_실습_05_VotingFile재배치.txt | CRS-4258·4261·4648을 재현하고 Voting File을 +DATA로 옮겼다 되돌린다
05-06 ★⚠ | RAC/05장/5장_실습_06_디스크강제OFFLINE.txt | Voting File 디스크를 내렸다 올리며 클러스터의 반응과 FUID 변화를 관찰한다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습, ⚠는 시작 전에 공유 디스크 사본(-BackupShared)이 필요한 실습이다.
@B 수료 후 자습: 5장_실습_04_OCR다중화, 5장_실습_07_복구절차정리.
@B 실습 05-05를 마치면 votedisk가 +CRS에 3개인지, 05-06을 마치면 OFFLINE_DISKS가 0인지 확인한다.
