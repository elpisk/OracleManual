@H1 제11장  srvctl과 crsctl 명령 체계

@H2 11.1  학습 목표

@P 9장과 10장에서 인스턴스를 올리고 내리며 `srvctl`과 `crsctl`을 모두 썼다. 이 장은 두 명령이 맡은 계층을 정리하고, 경계를 넘을 때 Clusterware가 어떻게 막는지 확인한다. 이어서 자원 목록과 속성을 읽는 법, 사용자가 만든 스크립트를 클러스터 자원으로 등록해 감시·재기동·이동을 맡기는 법, 오류 접두어로 문제 계층을 좁히는 법을 다룬다.

@B `srvctl`과 `crsctl`이 각각 다루는 대상과 실행 계정을 구분하고, CRS-4995가 나는 이유를 설명할 수 있다.
@B `srvctl`의 명령·대상·옵션 구조를 이해하고 status와 config, stop과 disable의 차이를 말할 수 있다.
@B `crsctl stat res -t`의 Local·Cluster Resources와 `-init` 목록을 구분해 읽고, 정상적인 OFFLINE을 가려낼 수 있다.
@B AUTO_START, RESTART_ATTEMPTS, CHECK_INTERVAL과 hard·weak·pullup 의존 관계를 해석할 수 있다.
@B 액션 스크립트로 사용자 자원을 등록하고 자동 복구·이동·복구 실패를 관찰할 수 있다.
@B CRS·PRKO·PRCD·PRCR·PRCC 접두어로 오류가 난 계층을 판단할 수 있다.

@H2 11.2  두 명령의 역할 분담

@P 한 문장으로 정리하면 `srvctl`은 Oracle이 정의한 자원을, `crsctl`은 Clusterware 자체와 자원 모델 전체를 다룬다. 같은 자원을 두 명령으로 볼 수 있어서 처음에는 헷갈리지만, 상태를 바꾸는 작업에서는 경계가 분명하다.

@IMG 11_boundary.png | 그림 11-1. 두 명령의 경계 — srvctl은 Oracle 자원을, crsctl은 스택과 자원 모델을 다룬다

@TBL
구분 | srvctl | crsctl
다루는 대상 | database, instance, service, listener, scan, asm, nodeapps, vip 등 Oracle 자원 | Clusterware 스택(crs, cluster, css, has), 자원 정의, 사용자 자원
주 실행 계정 | oracle(DB 자원), grid(리스너·ASM·SCAN) | grid, 스택 기동·정지는 root
모르는 것 | 사용자 자원(ch14.app 같은 것) | DB 정지 절차(세션 정리, 체크포인트, 서비스 처리)
대표 명령 | `srvctl status database -d racdb -v` | `crsctl stat res -t`, `crsctl check cluster -all`
@END

@H3 11.2.1  경계를 넘으면 — CRS-4995

@CODE
[grid@rac1 ~]$ crsctl stop resource ora.racdb.db
CRS-4995:  The command 'Stop  resource' is invalid in crsctl. Use srvctl for this command.
[grid@rac1 ~]$ echo $?
1
[grid@rac1 ~]$ crsctl start resource ora.racdb.db
CRS-4995:  The command 'Start  resource' is invalid in crsctl. Use srvctl for this command.
@END

@B `ora.`로 시작하는 Oracle 자원의 상태를 `crsctl`로 바꾸려 하면 거부되고 `srvctl`을 쓰라는 안내가 나온다. 종료 코드가 1이라 스크립트에서도 실패로 잡힌다.
@B 조회는 허용된다. `crsctl stat res ora.racdb.db -p`는 정상 동작한다. 자원 정의는 OCR에 있고 `crsctl`은 OCR을 읽는 도구이기 때문이다.
@B 데이터베이스 정지는 세션 정리, 체크포인트, 서비스 이동을 포함한 절차다. `srvctl`은 이 절차를 알고 `crsctl`은 모른다. 읽기는 열어 두고 쓰기는 막은 비대칭이 두 도구의 관계를 보여 준다.
@B 반대 방향도 막혀 있다. `srvctl status resource`처럼 `srvctl`이 모르는 대상을 주면 사용법만 출력한다. 사용자 자원은 `srvctl`의 대상 목록에 없다.

@H3 11.2.2  crsctl로만 하는 일 — 스택 상태

@CODE
[grid@rac1 ~]$ crsctl check crs
CRS-4638: Oracle High Availability Services is online
CRS-4537: Cluster Ready Services is online
CRS-4529: Cluster Synchronization Services is online
CRS-4533: Event Manager is online
[grid@rac1 ~]$ crsctl check cluster -all
rac1:
CRS-4537: Cluster Ready Services is online
...
@END

@B `check crs`는 실행한 노드의 스택을 OHAS까지 넷 보여 준다. `check cluster -all`은 모든 노드를 돌며 CRS·CSS·EVM 셋을 보여 준다.
@B OHAS가 빠지는 이유는 노드마다 독립적으로 뜨는 최하위 데몬이라 클러스터 관점의 조회 대상이 아니기 때문이다(2장).

@H2 11.3  srvctl — 명령·대상·옵션

@P `srvctl`은 `srvctl <명령> <대상> <옵션>` 형태다. 명령 20여 개와 대상 40여 개를 조합하므로 구조를 알면 처음 보는 대상도 짐작해서 쓸 수 있다.

@TBL
명령 | 하는 일 | 주의
status | 지금 상태 | 가장 자주 쓴다
config | Clusterware에 저장된 정의 | 자원이 내려가 있어도 나온다
start / stop | 지금 올리고 내린다 | 상태를 바꾼다
enable / disable | 자동 기동 대상에 넣고 뺀다 | stop과 다르다
add / modify / remove | 정의를 만들고 고치고 지운다 | 되돌리기 어렵다
relocate | 다른 노드나 인스턴스로 옮긴다 | 서비스·SCAN·VIP 등에 쓴다
@END

@B status는 현실이고 config는 정의다. 두 노드로 정의된 데이터베이스가 한 노드에서만 떠 있다는 판단은 둘을 함께 봐야 선다.
@B stop은 지금 내리는 것이고 disable은 앞으로 자동으로 올라오지 않게 하는 것이다. 유지보수 때는 둘을 함께 쓴다. disable 없이 stop만 하면 다음 클러스터 기동 때 정책에 따라 다시 올라올 수 있다.
@B 옵션은 19c에서 `-db`, `-instance`, `-service`처럼 긴 이름을 쓰고 `-d`, `-i`, `-s` 같은 예전 짧은 이름도 받는다. 이 과정의 트랜스크립트는 짧은 이름을 주로 쓴다.

@H3 11.3.1  대상별 출력

@CODE
[grid@rac1 ~]$ srvctl status scan
SCAN VIP scan1 is enabled
SCAN VIP scan1 is running on node rac1
[grid@rac1 ~]$ srvctl status scan_listener
SCAN Listener LISTENER_SCAN1 is enabled
SCAN listener LISTENER_SCAN1 is running on node rac1
[grid@rac1 ~]$ srvctl config listener
Name: LISTENER
Network: 1, Owner: grid
End points: TCP:1521
@END

@B 출력 형식은 대상마다 조금씩 다르지만 공통적으로 enabled인가와 running인가를 나눠 말한다.
@B scan과 scan_listener는 별개 자원이다. SCAN은 IP 자원이고 SCAN 리스너는 그 IP에서 듣는 프로세스라 한쪽만 죽을 수 있다.
@B 리스너의 Owner가 grid다. 리스너는 Grid 홈에서 돌므로 리스너 로그를 볼 때 grid 계정으로 붙는다.
@B `srvctl status nodeapps`는 VIP 두 개, 네트워크 자원, ONS 데몬을 한 번에 보여 준다. ONS는 13장에서 FAN 이벤트를 나르는 데몬으로 다시 나온다.

@H3 11.3.2  -help, -eval, -startconcurrency

@B 옵션은 `srvctl start database -help`처럼 확인한다. 문서를 찾는 것보다 빠르고 설치된 버전의 실제 문법을 반영한다.
@B `-eval`은 실행하지 않고 영향만 계산한다. 서비스가 여럿 걸린 데이터베이스를 내리기 전에 무엇이 함께 내려가는지 미리 본다.
@B `-startconcurrency`는 동시에 기동할 인스턴스 수다. 실습 환경처럼 호스트 자원이 넉넉하지 않으면 1로 두어 순차 기동하는 편이 안전하다.

@H3 11.3.3  config database로 읽는 정의

@CODE
[oracle@rac1 ~]$ srvctl config database -d racdb | egrep 'instances|Configured|Start options|Stop options|Management|Disk Groups'
Start options: open
Stop options: immediate
Management policy: AUTOMATIC
Disk Groups: DATA,FRA
Database instances: racdb1,racdb2
Configured nodes: rac1,rac2
@END

@B Start options와 Stop options는 `srvctl start/stop database`가 옵션 없이 실행될 때 쓰는 기본값이다. 정지 기본값이 immediate라 진행 중 트랜잭션은 롤백된다.
@B Management policy가 AUTOMATIC이면 클러스터가 기동될 때 데이터베이스도 자원 정책에 따라 함께 올라온다. MANUAL로 바꾸면 관리자가 직접 올려야 한다.
@B Disk Groups는 데이터베이스 자원의 디스크그룹 의존을 만드는 목록이다. 11.5.1의 hard 의존이 여기서 나온다.
@B Database instances와 Configured nodes가 두 개씩이다. status 출력에 인스턴스가 하나만 보인다면 정의와 현실이 어긋난 것이다.

@BP status와 config를 한 세트로
장애 대응의 첫 명령을 정해 두면 판단이 빨라진다. 데이터베이스라면 `srvctl status database -d racdb -v`로 현실을, `srvctl config database -d racdb`로 정의를 본다.
여기에 `crsctl stat res ora.racdb.db -t`를 더하면 TARGET이 보인다. TARGET이 OFFLINE이면 Clusterware는 그 자원을 올릴 생각이 없으므로 기다려도 올라오지 않는다.
@END

@H2 11.4  crsctl stat res -t 읽기

@P 이 명령 하나가 클러스터 전체 자원을 한 화면에 보여 준다. 출력은 두 구획으로 나뉘고, `-init`을 붙이면 전혀 다른 목록이 나온다.

@H3 11.4.1  Local Resources와 Cluster Resources

@B Local Resources는 노드마다 하나씩 있는 자원이다. 왼쪽에 번호가 없고 노드 이름으로 행이 구분된다. 노드 리스너(`ora.LISTENER.lsnr`), 네트워크(`ora.net1.network`), ONS가 여기에 속한다.
@B Cluster Resources는 클러스터 전체에서 정해진 개수만 도는 자원이다. 왼쪽 숫자는 인스턴스 번호가 아니라 자원의 슬롯 번호다.
@B SCAN 리스너는 SCAN IP가 하나라 슬롯도 하나다. `ora.racdb.db`는 CARDINALITY가 2라 슬롯이 둘이다.
@B 실습 환경의 일반 자원은 17개다(`crsctl stat res | grep -c '^NAME='`). 서비스나 사용자 자원을 만들면 늘고 지우면 줄어드므로 기준선으로 기록해 둔다.

@H3 11.4.2  OFFLINE을 모두 장애로 보지 않는다

@B TARGET이 ONLINE인데 STATE가 OFFLINE이면 Clusterware가 올리려다 못 올린 상태다. 실습 환경의 `ora.chad`(Cluster Health Advisor)가 rac2에서 이렇게 보였고, `srvctl status cha -node rac2`가 enabled이지만 실행 중이 아니라고 한 겹 더 설명해 준다. 데이터베이스 동작에는 필수가 아니다.
@B `ora.asmgroup` 아래 세 번째 슬롯이 OFFLINE인 것은 정상이다. Flex ASM 인스턴스 수는 3인데 노드가 둘이기 때문이다.
@B `-init` 목록의 `ora.diskmon`은 AUTO_START가 never다. Exadata 전용이라 일반 환경에서는 올리지 않는다.
@B OFFLINE을 보면 TARGET과 AUTO_START를 먼저 본다. TARGET도 OFFLINE이거나 AUTO_START가 never면 의도된 상태다.

@H3 11.4.3  -init이 보여 주는 하위 계층

@IMG 11_layers.png | 그림 11-2. OHAS가 -init 자원을, CRSD가 일반 자원을 관리한다 — ora.asm은 두 목록에 모두 나온다

@B `crsctl stat res -t -init`에는 `ora.cssd`, `ora.crsd`, `ora.ctssd`, `ora.cluster_interconnect.haip`, `ora.asm` 같은 스택 자체의 자원이 나온다. 실습 환경에서 13개다.
@B Server 열이 모두 실행한 노드다. 이 자원들은 노드마다 독립적으로 뜨는 OHAS가 관리하므로 다른 노드를 보려면 그 노드에서 실행한다.
@B 기동 순서는 OHAS → CSSD(멤버십) → ASM → CRSD → 일반 자원이다. CRSD가 OCR을 읽어야 일반 자원을 관리할 수 있는데 OCR이 +CRS에 있으므로 ASM이 CRSD보다 먼저 떠야 한다.
@B 그래서 `ora.asm`은 두 목록에 모두 나온다. `-init` 쪽은 이 노드의 ASM 인스턴스를 OHAS가 띄우는 자원이고, 일반 목록 쪽은 Flex ASM 관점에서 클러스터 전체 ASM을 관리하는 자원이다.

@BP 노드가 올라왔는데 데이터베이스가 안 뜰 때
아래에서 위로 본다. 그 노드에서 `crsctl stat res -t -init`을 실행해 `ora.cssd`가 ONLINE인지 본다. 아니면 클러스터에 합류하지 못한 것이니 인터커넥트와 보팅 파일을 본다(2장, 3장).
`ora.cssd`는 떴는데 `ora.crsd`가 안 떴다면 OCR을 읽지 못한 경우가 많다. `ora.asm`과 `ora.storage`를 함께 본다. 여기까지 정상이면 `crsctl stat res -t`에서 디스크그룹 → 데이터베이스 순으로 의존 관계를 따라간다.
@END

@H2 11.5  자원 속성

@P `crsctl stat res <자원> -p`는 자원 정의 전체를 보여 준다. 자원이 재부팅 뒤 어떻게 할지, 얼마나 자주 점검할지, 무엇에 의존하는지가 모두 속성에 있다.

@CODE
[grid@rac1 ~]$ crsctl stat res ora.racdb.db -p | egrep '^NAME=|^TYPE=|^AUTO_START|^CARDINALITY|^CHECK_INTERVAL|^RESTART_ATTEMPTS|^UPTIME_THRESHOLD'
NAME=ora.racdb.db
TYPE=ora.database.type
AUTO_START=restore
CARDINALITY=2
CHECK_INTERVAL=900
RESTART_ATTEMPTS=2
UPTIME_THRESHOLD=1h
@END

@TBL
속성 | 뜻 | 실습 환경의 예
AUTO_START | 클러스터 기동 때 자원을 어떻게 할지. always / restore / never | 대부분 restore, ora.ons·일반 ora.asm은 always, ora.diskmon은 never
RESTART_ATTEMPTS | 같은 노드에서 되살리기를 시도할 최대 횟수 | ora.racdb.db 2, VIP 0, ora.cssd 3
CHECK_INTERVAL | 상태 점검 간격(초) | ora.racdb.db 900, VIP·네트워크·ASM 1
UPTIME_THRESHOLD | 이 시간 이상 살아 있으면 재시작 횟수를 초기화 | ora.racdb.db 1h
CARDINALITY | 클러스터에서 동시에 도는 개수 | ora.racdb.db 2
@END

@B restore는 마지막 상태로 되돌린다는 뜻이다. 관리자가 `srvctl stop`으로 내려 둔 자원은 재부팅 뒤에도 올라오지 않는다(9장).
@B VIP의 RESTART_ATTEMPTS가 0인 이유는 재시작 대신 다른 노드로 옮겨 가는 것이 VIP의 역할이기 때문이다.
@B `ora.cssd`가 3인 것은 몇 번 되살려도 안 되면 노드를 재부팅하는 것이 맞다고 보기 때문이다. 노드 축출과 연결되는 값이다.

@H3 11.5.1  의존 관계

@IMG 11_deps.png | 그림 11-3. ora.racdb.db의 의존 관계 — hard는 필수, weak는 선택, pullup은 연쇄 기동

@CODE
START_DEPENDENCIES=hard(global:uniform:ora.DATA.dg, global:uniform:ora.FRA.dg)
  pullup(global:ora.DATA.dg, global:ora.FRA.dg, global:ora.CH9DG.dg)
  weak(type:ora.listener.type, global:type:ora.scan_listener.type,
       uniform:ora.ons, global:ora.gns)
STOP_DEPENDENCIES=hard(global:intermediate:ora.asm, global:shutdown:ora.DATA.dg,
                       global:shutdown:ora.FRA.dg)
@END

@B hard는 그 자원이 없으면 이 자원을 올릴 수 없다는 뜻이다. +DATA와 +FRA가 마운트되어 있어야 데이터베이스가 뜬다. 데이터베이스가 쓰는 디스크그룹을 내리려 하면 이 의존 때문에 거부된다.
@B weak는 있으면 좋고 없어도 뜬다. 리스너가 없어도 데이터베이스는 열리지만 원격 접속을 받지 못한다.
@B pullup은 그 자원이 올라오면 따라 올라간다는 뜻이다. 디스크그룹이 마운트되는 순간 데이터베이스가 자동으로 뜨는 근거다.
@B STOP_DEPENDENCIES는 반대 방향이다. ASM이 내려가면 데이터베이스도 내려간다.

@NOTE 정의에 남은 옛 이름
위 pullup에 `ora.CH9DG.dg`가 있다. ASM 실습에서 만들었다 지운 디스크그룹이라 `crsctl stat res ora.CH9DG.dg`는 CRS-2613(자원 없음)을 낸다. 없는 자원은 영원히 올라오지 않으므로 동작에는 영향이 없다.
읽는 사람이 없는 디스크그룹을 찾아 헤맬 수 있으므로 운영 환경이라면 `srvctl config database`의 Disk Groups를 확인하고 `srvctl modify database -diskgroup`으로 목록을 다시 지정해 정리한다.
@END

@H2 11.6  사용자 스크립트를 클러스터 자원으로

@P Clusterware는 Oracle 제품만 관리하는 도구가 아니다. 한 노드에서만 돌아야 하는 배치 데몬처럼, 감시하고 되살리고 옮겨야 하는 대상이면 무엇이든 자원으로 등록할 수 있다.

@H3 11.6.1  액션 스크립트의 약속

@TBL
인자 | Clusterware가 기대하는 동작 | 반환값
start | 자원을 기동한다 | 0 성공, 그 밖은 실패
stop | 자원을 정지한다 | 0 성공
check | 살아 있는지 확인한다 | 0 살아 있음, 그 밖은 죽음
clean | 실패한 자원의 잔재를 강제로 치운다 | 0 성공
@END

@CODE
#!/bin/bash
# /u01/app/grid/ch14/ch14app.sh  (양 노드 같은 경로, grid:oinstall, 755)
STATE=/tmp/ch14app.state
LOG=/tmp/ch14app.log
echo "$(date '+%F %T') $1" >> $LOG
case "$1" in
  start) echo "running since $(date '+%F %T')" > $STATE; exit 0 ;;
  stop)  rm -f $STATE; exit 0 ;;
  check) [ -f $STATE ] && exit 0 || exit 1 ;;
  clean) rm -f $STATE; exit 0 ;;
  *)     exit 1 ;;
esac
@END

@B 실제 데몬 대신 상태 파일 하나로 살아 있음을 표현한 실습용 스크립트다.
@B 호출될 때마다 로그 한 줄을 남긴다. Clusterware가 언제 무엇을 불렀는지 이 파일로만 확인할 수 있으므로 운영 스크립트에서도 유지할 습관이다.
@B 자원이 어느 노드에서 뜰지 모르므로 스크립트는 두 노드의 같은 경로에 둔다.

@H3 11.6.2  등록과 자동 복구

@CODE
[grid@rac1 ~]$ crsctl add resource ch14.app -type cluster_resource \
 -attr "ACTION_SCRIPT=/u01/app/grid/ch14/ch14app.sh,\
PLACEMENT=restricted,HOSTING_MEMBERS=rac1 rac2,\
CHECK_INTERVAL=30,RESTART_ATTEMPTS=2,\
START_DEPENDENCIES=hard(ora.net1.network),\
STOP_DEPENDENCIES=hard(ora.net1.network)"
[grid@rac1 ~]$ crsctl start resource ch14.app
CRS-2672: Attempting to start 'ch14.app' on 'rac1'
CRS-2676: Start of 'ch14.app' on 'rac1' succeeded
@END

@B `cluster_resource`는 클러스터에서 정해진 개수만 도는 유형이다. 노드마다 하나씩 필요하면 `local_resource`를 쓴다.
@B `PLACEMENT=restricted`와 `HOSTING_MEMBERS`는 지정한 노드에서만 돌게 한다. 지정하지 않은 속성은 기본값(AUTO_START=restore, CARDINALITY=1)이 들어간다.
@B 등록만 하면 TARGET·STATE가 모두 OFFLINE이다. `crsctl start resource`로 올린다. 사용자 자원은 `ora.` 자원이 아니므로 `crsctl`로 기동·정지할 수 있다.

@IMG 11_userres.png | 그림 11-4. 상태 파일을 지운 뒤의 시간축 — 다음 check에서 감지하고 곧바로 start로 되살린다

@B 12:03:16에 상태 파일을 지웠고 다음 check인 12:03:26에 실패를 감지했다. 12:03:27에 start를 불러 되살렸다. 감지 지연의 상한은 CHECK_INTERVAL 30초다.
@B 복구가 1초 만에 끝나서 `crsctl stat res -t`는 한 번도 OFFLINE을 보여 주지 않았다. 자동 복구는 조용히 일어나므로 상태 명령만으로는 장애를 놓친다. Oracle 자원이라면 `$ORACLE_BASE/diag/crs/<노드>/crs/trace/` 아래 에이전트 로그에서 같은 정보를 찾는다.
@B `crsctl relocate resource ch14.app -n rac2`는 rac1에서 stop을 부른 뒤 rac2에서 start를 부른다. 두 노드에서 동시에 도는 순간이 없으므로 배타적으로 하나만 돌아야 하는 데몬에 맞다.

@H3 11.6.3  되살리지 못하면

@B start가 실패하도록 만든 뒤 상태 파일을 지우자 Clusterware는 현재 노드에서 start → check → clean → check를 부르고, 다른 노드에서도 같은 순서를 밟은 뒤 멈췄다.
@B 그 뒤 `crsctl stat res ch14.app -t`는 TARGET ONLINE, STATE OFFLINE이고 Server 열이 비어 있다. 이 어긋남이 Clusterware가 포기했다는 신호다.
@B RESTART_ATTEMPTS가 2였지만 로그에는 노드마다 start가 한 번씩만 있었다. 속성값은 상한이며 실제 시도 횟수는 실패 유형에 따라 다르다. 시도 횟수는 로그로 확인한다.

@CODE
[grid@rac1 ~]$ crsctl stop resource ch14.app
[grid@rac1 ~]$ crsctl delete resource ch14.app
[grid@rac1 ~]$ crsctl stat res ch14.app
CRS-2613: Could not find resource 'ch14.app'.
@END

@B 정리는 정지 후 삭제 순서다. 삭제 뒤 CRS-2613이 나오는 것이 정상 확인이다. 두 노드의 스크립트와 `/tmp/ch14app.*` 파일도 지운다.

@BP 사용자 자원은 감시 스크립트에 crsctl을 추가한다
`srvctl`은 사용자 자원을 모른다. `srvctl`로만 도는 기존 점검으로는 사용자 자원이 죽어도 알 수 없다.
운영에 사용자 자원을 들이면 `crsctl stat res <자원> -t`를 점검 목록에 넣고, 액션 스크립트 로그를 함께 보관한다.
@END

@H2 11.7  오류 번호 체계

@IMG 11_errors.png | 그림 11-5. 오류 접두어가 알려 주는 계층 — 겹쳐 나오면 아래 줄이 원인이다

@TBL
접두어 | 계층 | 이 장의 예
PRKO- | srvctl 명령행 해석 | PRKO-2002 잘못된 옵션, PRKO-3032 잘못된 인스턴스 이름
PRCD- | srvctl 데이터베이스 계층 | PRCD-1120 데이터베이스 자원을 찾지 못함
PRCR- | srvctl 자원 계층 | PRCR-1001 자원 없음, PRCR-1004 이미 실행 중
PRCC- | srvctl 공통 계층 | PRCC-1015 이미 실행 중
CRS- | Clusterware 자원 계층 | CRS-4995 crsctl로 불가, CRS-2613 자원 없음, CRS-4000 명령 실패
@END

@CODE
[oracle@rac1 ~]$ srvctl status database -d nodb
PRCD-1120 : The resource for database nodb could not be found.
PRCR-1001 : Resource ora.nodb.db does not exist
[oracle@rac1 ~]$ srvctl start instance -d racdb -i racdb1
PRCC-1015 : racdb was already running on rac1
PRCR-1004 : Resource ora.racdb.db is already running
@END

@B PRKO면 입력한 명령을 다시 본다. PRCD·PRCR·PRCC·CRS면 명령은 맞고 대상이 없거나 상태가 다르다.
@B 여러 줄이 겹치면 위는 무엇을 하려다 실패했는지, 아래는 왜 실패했는지를 말한다. 마지막 줄을 먼저 읽는다. 10장의 ORA-02097과 ORA-30013도 같은 구조였다.
@B PRCC-1015는 오류처럼 보이지만 원하는 상태다. 기동 스크립트가 이 메시지를 실패로 처리하면 두 번째 실행에서 뒤 단계가 멈추므로 메시지와 종료 코드를 함께 판단한다.

@CASE 알림이 첫 줄만 보냈을 때
야간 알림 시스템이 오류의 첫 줄만 잘라 PRCD-1120만 전달했다. 데이터베이스 이름이 틀렸다는 것까지는 알지만 그다음 판단이 막힌다.
같은 조회 명령을 직접 실행해 전체 메시지를 봤다. 조회는 상태를 바꾸지 않으므로 안전하다. 이후 알림 설정을 마지막 줄과 종료 코드까지 보내도록 바꿨다.
@END

@H2 11.8  요약

@B `srvctl`은 Oracle 자원을, `crsctl`은 Clusterware 스택과 자원 모델을 다룬다. `crsctl`로 `ora.` 자원을 기동·정지하면 CRS-4995로 거부되고 조회는 허용된다.
@B status는 현실, config는 정의다. stop은 지금 내리는 것, disable은 자동 기동에서 빼는 것이다.
@B `crsctl stat res -t`의 Cluster Resources 왼쪽 숫자는 슬롯 번호다. `-init`은 OHAS가 관리하는 스택 자원을 실행한 노드 기준으로 보여 준다.
@B OFFLINE은 TARGET과 AUTO_START를 함께 보고 판단한다. 의도된 OFFLINE이 여럿 있다.
@B AUTO_START·RESTART_ATTEMPTS·CHECK_INTERVAL과 hard·weak·pullup 의존이 자원의 동작을 정한다.
@B 액션 스크립트를 자원으로 등록하면 Clusterware가 check로 감시하고 start로 되살리고 relocate로 옮긴다. 시도 횟수와 장애 이력은 로그로 확인한다.
@B 오류 접두어로 계층을 좁히고, 겹친 오류는 마지막 줄부터 읽는다.

@H2 11.9  퀴즈

@QUIZ 퀴즈
1. `crsctl stop resource ora.racdb.db`가 거부되는 이유와 오류 번호를 쓰시오. 같은 자원의 `-p` 조회는 왜 허용되는가?
2. `srvctl stop`과 `srvctl disable`의 차이는? 유지보수 때 둘을 함께 쓰는 이유는?
3. Cluster Resources에서 `ora.racdb.db` 아래의 1, 2는 무엇을 뜻하는가?
4. `ora.asm`이 일반 목록과 `-init` 목록에 모두 나오는 이유를 기동 순서로 설명하시오.
5. 사용자 자원의 상태 파일을 지웠는데 `crsctl stat res -t`에는 계속 ONLINE으로 보였다. 무슨 일이 있었고 어디서 확인하는가?
6. PRKO-3032와 PRCD-1120이 각각 알려 주는 것은? 겹쳐 나온 오류는 어느 줄을 먼저 읽는가?
@END

@NOTE 정답과 해설
1. CRS-4995. 데이터베이스 정지는 세션 정리·체크포인트·서비스 처리를 포함하는 절차라 srvctl만 수행한다. 자원 정의는 OCR에 있고 crsctl은 OCR을 읽는 도구라 조회는 허용된다.
2. stop은 지금 내리는 것, disable은 자동 기동 대상에서 빼는 것이다. disable 없이 stop만 하면 클러스터 재기동 때 다시 올라올 수 있다.
3. 자원 슬롯 번호다. CARDINALITY가 2라 슬롯이 둘이다. 인스턴스 번호와 같은 뜻이 아니다.
4. CRSD가 OCR을 읽어야 일반 자원을 관리하는데 OCR이 ASM 디스크그룹에 있어 ASM이 먼저 떠야 한다. -init 쪽은 OHAS가 노드의 ASM을 띄우는 자원, 일반 목록 쪽은 클러스터 전체 Flex ASM 자원이다.
5. 다음 check에서 실패를 감지하고 곧바로 start로 되살렸다. 복구가 1초라 상태 명령에는 나타나지 않는다. 액션 스크립트 로그(Oracle 자원은 에이전트 트레이스)로 확인한다.
6. PRKO-3032는 명령행의 인스턴스 이름이 틀렸다는 입력 오류, PRCD-1120은 그 데이터베이스 자원이 없다는 대상 오류다. 마지막 줄이 원인이다.
@END

@H2 11.10  실습 개요

@P 실습 01·02·04는 조회와 거부되는 명령뿐이라 상태가 바뀌지 않는다. 실습 06이 이 장의 중심이며 사용자 자원을 등록하고 장애를 주입한다.

@TBL
실습 | 파일 | 목적
01 | RAC/14장/14장_실습_01_두명령의역할분담.txt | 두 도움말을 비교하고 CRS-4995로 경계를 확인한다
02 | RAC/14장/14장_실습_02_srvctl자원별문법.txt | 대상별 status·config 출력과 -help, PRKO-2002를 확인한다
04 | RAC/14장/14장_실습_04_오류재현_crsctl로DB정지.txt | 막히는 것과 허용되는 것을 구분하고 srvctl 오류 접두어를 모은다
06 ★ | RAC/14장/14장_실습_06_사용자자원등록.txt | 액션 스크립트를 자원으로 등록해 자동 복구·이동·복구 실패를 관찰한다
@END

@B ★는 두 노드에 각각 세션을 열어야 하는 실습이다. 스냅샷이 필요한 실습은 없다.
@B 실습 06 뒤에는 반드시 정리한다. `crsctl stop resource ch14.app`, `crsctl delete resource ch14.app` 후 두 노드에서 `/u01/app/grid/ch14`와 `/tmp/ch14app.*`를 지우고, `crsctl stat res | grep -c '^NAME='`가 17인지 확인한다.
@B 수료 후 자습: 14장_실습_03_crsctl자원목록과init, 14장_실습_05_자원속성, 14장_실습_07_오류번호체계와정리.
