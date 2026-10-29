@TITLE Oracle Database 19c RAC 과정|RAC 백업과 복구|스레드별 아카이브, 노드 분산 백업, 인스턴스 복구와 미디어 복구|제14장

@PLAIN 학습 목표
- ARCHIVELOG 전환 절차와 ORA-01126 조건을 설명한다
- 스레드별 아카이브와 %t 의 역할을 이해한다
- 로컬 아카이브 경로와 빈 문자열의 함정을 피한다
- 채널을 VIP 로 고정해 백업을 두 노드에 나눈다
- 인스턴스 복구 순서를 알럿 로그로 읽는다
- 데이터 파일 미디어 복구와 SPFILE 복원 부작용을 다룬다

@PLAIN Agenda
- 14.2  RAC 백업의 전제
- 14.3  ARCHIVELOG 구성  /  14.4  아카이브 위치의 함정
- 14.5  노드 분산 백업  /  14.6  백업 검증
- 14.7  인스턴스 복구
- 14.8  미디어 복구
- 14.9  컨트롤 파일·SPFILE과 운영 지침

@SEC 14.2|RAC 백업의 전제
- 한 벌인 것과 스레드별인 것
- 복구에는 모든 스레드가 필요하다

@SLIDE 한 벌인 것과 스레드별인 것|RMAN 명령은 단일 인스턴스와 같다
- 데이터 파일·컨트롤 파일·SPFILE: +DATA 에 한 벌
- 온라인 리두: thread 1 은 racdb1, thread 2 는 racdb2
- 아카이브도 스레드마다 따로 생긴다
- SPFILE 백업에는 racdb1. / racdb2. 항목이 함께
@NOTE RAC의 백업은 RMAN 명령만 놓고 보면 단일 인스턴스와 똑같습니다. 데이터 파일과 컨트롤 파일, SPFILE이 모두 +DATA에 한 벌씩 있기 때문입니다. 다른 점은 리두입니다. 인스턴스마다 자기 리두 스레드를 쓰므로 아카이브도 스레드마다 따로 생기고, 시퀀스 번호도 스레드마다 독립적으로 올라갑니다. SPFILE을 백업하면 인스턴스별 접두어가 붙은 항목이 그대로 들어가므로, 복원하면 두 인스턴스가 각자의 설정을 되찾습니다.

@SLIDE 복구에는 모든 스레드가 필요하다|어느 노드에서든 모든 스레드의 아카이브를 읽어야 한다
- 미디어 복구는 모든 스레드의 리두를 SCN 순으로 합쳐 적용
- 한 스레드라도 빠지면 그 지점에서 복구가 멈춘다
- 아카이브는 공유 디스크그룹 +FRA 에 둔다
- 컨트롤 파일은 모든 스레드의 아카이브 기록을 가진다
@NOTE 미디어 복구를 할 때 RMAN은 thread 1과 thread 2의 리두를 SCN 순서로 합쳐서 적용합니다. 그래서 어느 한 스레드의 아카이브가 하나라도 빠지면 그 지점을 넘어서 복구할 수 없습니다. RAC 백업 설계의 첫 번째 조건은 어느 노드에서 백업하고 복구하든 모든 스레드의 아카이브를 읽을 수 있어야 한다는 것입니다. 실습 환경은 아카이브를 공유 디스크그룹인 +FRA에 두어서 이 조건을 만족합니다. 이 조건이 깨지는 경우를 잠시 뒤에 봅니다.

@SEC 14.3|ARCHIVELOG 구성
- 아카이브 관련 파라미터
- 전환 절차
- 스레드별 아카이브와 FRA 크기

@SLIDE 아카이브 관련 파라미터|racdb 는 NOARCHIVELOG 로 시작한다
- db_recovery_file_dest = +FRA (두 인스턴스 공통)
- log_archive_dest_1 미지정 → FRA 로 간다
- log_archive_format %t_%s_%r.dbf — %t 가 스레드
- DBID 1240378513 을 이 시점에 기록
@NOTE DBCA로 만든 racdb는 NOARCHIVELOG 모드로 시작합니다. 아카이브 대상 파라미터를 따로 지정하지 않았기 때문에 아카이브는 복구 영역인 +FRA로 갑니다. 아카이브 파일 이름 형식에서 퍼센트 t가 스레드 번호, 퍼센트 s가 시퀀스, 퍼센트 r이 리셋로그 아이디입니다. 스레드마다 시퀀스가 따로 올라가므로 이름에 스레드가 없으면 두 인스턴스의 파일 이름이 겹칩니다. 그리고 이때 DBID를 꼭 적어 두십시오. 컨트롤 파일을 모두 잃으면 이 값이 있어야 복구할 수 있습니다.

@SLIDE 전환 절차|한 인스턴스만 MOUNT 한 상태에서 바꾼다
- srvctl stop database -d racdb 로 전부 정지
- rac1 에서 startup mount → alter database archivelog
- alter database open → srvctl start instance -i racdb2
- 다른 인스턴스가 열려 있으면 ORA-01126 으로 거부
- cluster_database=FALSE 변경은 필요 없다
@NOTE 아카이브 모드는 컨트롤 파일의 전역 속성이라 한 인스턴스만 마운트한 상태에서 바꿔야 합니다. srvctl로 데이터베이스 전체를 내리고, rac1에서만 마운트로 올려 archivelog로 바꾼 뒤 엽니다. 그다음 racdb2를 srvctl start instance로 올립니다. 다른 인스턴스가 열려 있는 상태에서 시도하면 ORA-01126으로 거부되므로 실수로 잘못 바뀔 여지는 적습니다. 예전 자료에는 cluster_database를 FALSE로 바꾸라고 되어 있지만 11gR2부터는 필요 없고, 오히려 되돌릴 작업만 늘어납니다.

@IMG 14_archive.png|아카이브 위치|공유 +FRA 와 로컬 경로의 차이
@NOTE 왼쪽이 정상 구성입니다. rac1은 thread 1, rac2는 thread 2의 아카이브를 +FRA에 씁니다. 파일 이름에 thread_1, thread_2가 들어가고, 두 노드가 같은 ASM과 같은 컨트롤 파일을 보므로 어느 노드에서 조회해도 같은 목록이 나옵니다. 오른쪽은 rac1의 아카이브 대상을 로컬 디렉터리로 바꾼 경우입니다. 컨트롤 파일에는 기록이 남아 rac2에서도 목록은 보이지만, 정작 파일은 rac1 디스크에만 있어서 rac2의 crosscheck가 실패합니다.

@SLIDE FRA 크기|보관 기간으로 한도를 잡는다
- db_recovery_file_dest_size 는 디스크그룹 크기와 별개
- 한도에 이르면 아카이브를 못 만든 인스턴스가 멈춘다
- 하루 양 = 두 인스턴스 리두 발생량의 합
- SPACE_RECLAIMABLE 로 삭제 정책 동작 확인
@NOTE FRA 한도는 디스크그룹 크기와 따로 정하는 값입니다. FRA가 한도에 이르면 아카이브를 만들지 못한 인스턴스가 멈추고, 결국 서비스 전체가 영향을 받습니다. 한도를 정할 때는 하루 아카이브 양에 보관 기간을 곱합니다. RAC에서는 하루 아카이브 양이 두 인스턴스 리두 발생량의 합이라는 점을 놓치기 쉽습니다. v recovery file dest 뷰의 회수 가능 공간이 계속 0인데 사용량만 늘어난다면 백업이나 삭제 정책이 제대로 돌지 않는 것입니다.

@SEC 14.4|아카이브 위치의 함정
- 한 노드에만 있는 경로
- 빈 문자열은 기본값 복원이 아니다

@SLIDE 한 노드에만 있는 경로|컨트롤 파일에는 있고 rac2 에는 파일이 없다
- rac1 만 LOCATION=/u01/app/oracle/arch_local
- 파일 이름 1_23_1242761748.dbf (형식 그대로)
- rac2 의 V$ARCHIVED_LOG 에도 보인다
- rac2 crosscheck → validation failed 세 건
@NOTE 실습 02에서 rac1의 아카이브 대상만 로컬 디렉터리로 바꿔 봅니다. 그러면 thread 1의 아카이브가 rac1 로컬 디스크에 형식 파라미터대로 이름이 붙어 생깁니다. 컨트롤 파일은 공유되므로 rac2에서 조회해도 이 파일 목록이 보입니다. 하지만 rac2에는 그 디렉터리가 없어서 RMAN crosscheck를 하면 그 세 파일만 validation failed로 나옵니다. 로컬 경로에 데이터 파일을 만들었을 때 다른 노드가 ORA-01157을 냈던 10장의 사례와 같은 구조입니다.

@SLIDE 로컬 아카이브가 만드는 문제|복구가 필요한 날에야 드러난다
- 백업을 그 노드에서만 돌려야 한다
- 그 노드가 죽으면 그 아카이브를 못 읽는다
- 복구 때 모든 스레드가 한곳에 모이지 않는다
- 스케줄러가 다른 노드에서 돌리면 구간이 조용히 빠진다
@NOTE 로컬 아카이브 구성은 세 가지 문제를 만듭니다. 첫째, 백업을 반드시 그 노드에서만 돌려야 합니다. 둘째, 그 노드가 죽으면 거기 있던 아카이브를 읽을 수 없어서 노드 장애와 미디어 장애가 겹치면 복구가 불가능해집니다. 셋째, 복구할 때 모든 스레드의 아카이브가 한곳에 있어야 하는데 그렇지 않으니 수동으로 복사해 와야 합니다. 백업 스케줄러가 노드를 가리지 않는 환경이라면 어느 날 백업에서 그 구간이 빠져도 아무도 모르고 지나갑니다.

@SLIDE 빈 문자열의 함정|log_archive_dest_1='' 은 대상 비활성화
- 되돌리려고 빈 값을 넣으면 ORA-16014
- GV$ARCHIVE_DEST 의 STATUS 가 INACTIVE
- 리두 그룹이 다 차는 순간 인스턴스 정지
- 원래는 미지정 상태여서 FRA 가 암묵적으로 쓰였다
@NOTE 로컬 경로를 원래대로 돌리려고 빈 문자열을 넣으면 또 다른 사고가 납니다. 로그 스위치를 하면 ORA-16014, 아카이브할 대상이 없다는 오류가 나고 gv archive dest의 상태가 INACTIVE로 바뀝니다. 처음에 이 파라미터는 지정되지 않은 상태였고, 그때는 FRA가 암묵적으로 쓰였습니다. 한 번 지정한 뒤 빈 값을 넣으면 그 암묵적인 동작이 돌아오지 않고 대상이 꺼질 뿐입니다. 이대로 두면 온라인 리두 그룹이 다 차는 순간 인스턴스가 멈춥니다.

@SLIDE 올바르게 되돌리기|바꾼 직후 반드시 로그 스위치로 검증
- 메모리 값: LOCATION=USE_DB_RECOVERY_FILE_DEST 명시
- SPFILE 값: alter system reset ... scope=spfile
- 원래 상태는 V$SPPARAMETER 의 ISSPECIFIED 로 확인
- archive log current 후 두 인스턴스 모두 VALID 확인
@NOTE 메모리에만 바꾼 값은 LOCATION 등호 USE_DB_RECOVERY_FILE_DEST를 명시해서 되살립니다. SPFILE에 기록한 값이라면 alter system reset으로 항목 자체를 지우는 것이 원래 상태로 돌아가는 방법입니다. 원래 상태가 지정 안 됨이었는지는 v spparameter의 ISSPECIFIED 열로 확인할 수 있습니다. 가장 중요한 습관은 아카이브 대상을 건드린 직후 바로 로그 스위치를 해 보고 두 인스턴스의 대상 상태가 VALID인지 확인하는 것입니다. 리두가 다 찬 뒤에 알면 늦습니다.

@SEC 14.5|노드 분산 백업
- 채널을 인스턴스에 고정한다
- 분산 확인과 채널 수
- 채널 접속 오류

@IMG 14_channels.png|노드 분산 백업|채널마다 노드 VIP 로 접속한다
@NOTE 백업은 CPU와 I/O를 많이 쓰므로 RAC에서는 채널을 두 인스턴스에 나눠서 부하를 분산할 수 있습니다. RMAN은 rac1에서 실행하지만 채널 ch1은 rac1-vip로, ch2는 rac2-vip로 접속시킵니다. 각 채널은 해당 노드의 인스턴스에서 서버 프로세스로 돌면서 +DATA의 데이터 파일을 읽고 +FRA에 백업 조각을 씁니다. 데이터 파일은 공유되므로 어느 채널이든 모든 파일을 읽을 수 있고, 어느 파일을 어느 채널이 맡을지는 RMAN이 정합니다.

@SLIDE 채널을 인스턴스에 고정|SCAN 이 아니라 노드 VIP 로 접속한다
- SCAN 은 어느 인스턴스로 갈지 정할 수 없다
- 노드 VIP → 로컬 리스너 → 그 노드 인스턴스만
- connect 'sys/<SYS 비밀번호>@rac1-vip:1521/racdb'
- 서비스 검증은 SCAN, 인스턴스 지목은 VIP
@NOTE 채널을 특정 인스턴스에 붙이려면 접속 주소를 골라야 합니다. SCAN으로 접속하면 racdb 서비스가 두 인스턴스 모두에 있으므로 어느 쪽으로 갈지 알 수 없습니다. 노드 VIP로 접속하면 그 노드의 로컬 리스너가 받는데, 로컬 리스너에는 그 노드의 인스턴스만 등록되어 있으니 결과가 항상 같습니다. 12장에서 접속 확인은 SCAN으로 하라고 했던 것은 서비스 동작을 검증하는 목적이었습니다. 특정 인스턴스를 지목하는 목적이라면 VIP를 씁니다.

@SLIDE 분산 확인|출력의 instance= 두 줄이 근거
- channel ch1: SID=282 instance=racdb1
- channel ch2: SID=149 instance=racdb2
- input datafile 줄로 파일 배분을 확인
- 끝에 컨트롤 파일·SPFILE 자동 백업이 붙는다
@NOTE 분산 백업이 실제로 되었는지는 채널 할당 출력의 instance 등호 부분으로 확인합니다. ch1이 racdb1, ch2가 racdb2로 찍혀야 합니다. 명령을 그렇게 썼다는 것만으로는 근거가 되지 않으니 반드시 이 두 줄을 보십시오. input datafile 줄을 보면 system과 undotbs1은 ch1이, sysaux와 undotbs2, users는 ch2가 맡은 식으로 파일이 나뉜 것이 보입니다. 백업이 끝나면 컨트롤 파일과 SPFILE 자동 백업이 이어서 만들어지는데, 19c에서는 이것이 기본값입니다.

@SLIDE 채널 수와 압축|노드 자원이 채널 수를 정한다
- 노드가 둘이라고 채널이 둘일 필요는 없다
- 실습 환경은 노드당 채널 1개
- 백업 전 cat /proc/loadavg 로 부하 확인
- 압축은 I/O 를 줄이고 CPU 를 더 쓴다
@NOTE 노드당 채널 수는 그 노드의 CPU와 I/O 대역폭이 정합니다. 노드가 둘이니 채널도 둘이라는 식으로 정하는 것이 아닙니다. 실습 환경은 노드당 vCPU가 4개이고 호스트 자원도 넉넉하지 않아서 노드당 채널 하나로 진행합니다. 자원이 빠듯할 때 채널을 늘리면 하트비트가 늦어져 노드 축출까지 갈 수 있으니 백업 전에 부하를 확인하는 습관을 들이십시오. 압축 백업은 I/O를 줄이는 대신 CPU를 더 쓰므로 병목이 어디인지에 따라 득실이 갈립니다.

@SLIDE 채널 접속 오류|오류 스택은 아래 줄이 원인이다
- RMAN-03009: allocate 명령 실패 (상위 메시지)
- ORA-12545: 호스트 없음 — VIP 이름 오타
- srvctl config nodeapps 로 VIP 이름 확인
- 스크립트에 넣기 전 sqlplus 로 먼저 접속 확인
@NOTE 채널 접속 문자열에 rac9-vip처럼 없는 호스트를 쓰면 RMAN-03009와 함께 ORA-12545가 납니다. RMAN-03009는 allocate 명령이 실패했다는 상위 메시지일 뿐이고, 실제 원인은 바로 아래의 ORA 번호입니다. VIP 이름은 srvctl config nodeapps로 확인할 수 있고, 이름 대신 172.16.225.111과 112 같은 IP를 직접 써도 됩니다. 백업 스크립트에 넣기 전에 같은 접속 문자열로 sqlplus에 붙어서 의도한 인스턴스로 가는지 먼저 확인해 두면 안전합니다.

@SEC 14.6|백업 검증
- 다른 노드에서 restore validate
- 스냅샷 컨트롤 파일

@SLIDE 다른 노드에서 검증|만든 노드와 다른 노드에서 validate
- restore database validate: 읽기만 하고 파일은 그대로
- rac1 에서 만든 백업을 rac2 에서 validate
- 성공하면 어느 노드에서든 복구에 쓸 수 있다
- list backup summary: TY A 아카이브, F 데이터 파일
@NOTE 백업이 만들어졌다는 것과 복구에 쓸 수 있다는 것은 별개입니다. restore database validate는 백업셋을 실제로 읽어서 복원할 수 있는지만 확인하고 데이터 파일은 건드리지 않습니다. RAC에서는 한 노드에서 만든 백업을 다른 노드에서 validate해 보는 것이 중요합니다. 성공하면 그 백업은 어느 노드에서든 복구에 쓸 수 있다는 근거가 됩니다. 백업 목록에서 TY 열의 A는 아카이브, F는 데이터 파일 전체 백업이고, 자동 백업은 압축되지 않습니다.

@SLIDE 스냅샷 컨트롤 파일|운영에서는 공유 위치에 둔다
- 기본값: dbhome_rac/dbs/snapcf_racdb1.f (로컬)
- 백업 중 컨트롤 파일의 일관된 사본을 잠시 만든다
- RAC 는 모든 인스턴스가 접근 가능해야 함 (ORA-00245)
- CONFIGURE SNAPSHOT CONTROLFILE NAME TO '+DATA/...'
@NOTE RMAN show all 출력을 보면 스냅샷 컨트롤 파일 위치가 DB 홈 아래의 로컬 경로로 되어 있습니다. 백업하는 동안 컨트롤 파일의 일관된 사본을 잠시 만들어 쓰는 파일입니다. 11gR2 이후 RAC에서는 컨트롤 파일 백업 때 모든 인스턴스가 이 파일에 접근할 수 있어야 하고, 그렇지 않으면 ORA-00245로 백업이 실패할 수 있다고 문서에 나와 있습니다. 실습 환경은 rac1에서 시작해 기본값으로도 진행되지만, 운영 환경에서는 +DATA 같은 공유 위치로 바꿔 두는 편이 안전합니다.

@SEC 14.7|인스턴스 복구
- 복구 시간을 미리 가늠한다
- 알럿 로그에 남는 순서
- 복구 시간과 재기동 시간

@SLIDE 복구 시간 가늠|GV$INSTANCE_RECOVERY
- ACTUAL_REDO_BLKS: 마지막 체크포인트 이후 리두
- ESTIMATED_MTTR: 지금 죽으면 걸릴 예상 초
- fast_start_mttr_target 으로 목표 설정
- 체크포인트가 잦을수록 복구 구간이 짧다
@NOTE 인스턴스 복구는 마지막 체크포인트 이후의 리두만 읽습니다. gv instance recovery 뷰의 ACTUAL_REDO_BLKS가 그 구간의 리두 블록 수이고, ESTIMATED_MTTR은 지금 인스턴스가 죽으면 복구에 걸릴 예상 시간을 초 단위로 보여 줍니다. 실습 환경에서는 두 인스턴스 모두 1초로 나옵니다. fast_start_mttr_target을 지정하면 DBWn이 체크포인트를 앞당겨 그 목표를 맞춥니다. 실습 05에서는 이 예상값과 실제 알럿 로그의 시간을 나란히 비교해 봅니다.

@IMG 14_instrecovery.png|인스턴스 복구의 순서|racdb2 가 죽은 뒤 racdb1 의 알럿 로그
@NOTE 실습 05에서 rac2의 PMON을 강제로 죽인 뒤 racdb1의 알럿 로그를 시간 순서로 정리한 그림입니다. 약 5초 뒤 Reconfiguration started가 찍히고 GRD가 잠시 얼어붙습니다. 이 동안에는 블록 전송이 멈춥니다. 재구성은 0.1초 만에 끝나고, SMON이 thread 2의 온라인 리두를 읽어 롤포워드합니다. 마지막에 thread 2를 닫는 메시지가 나옵니다. 재구성 시작부터 복구 완료까지 1초가 걸리지 않았습니다. 아래 상자의 두 시간 구분이 이 실습의 핵심 관찰 포인트입니다.

@SLIDE 알럿 로그 읽기|메시지마다 의미가 있다
- Reconfiguration started: 구성원 변화 감지
- GRD frozen: 블록 전송 잠시 정지
- Beginning instance recovery of 1 threads
- Redo thread 2 internally disabled (SMON)
@NOTE 알럿 로그 메시지를 하나씩 읽어 보겠습니다. Reconfiguration started는 클러스터가 인스턴스 구성원의 변화를 알아챘다는 표시이고 incarnation 번호가 올라갑니다. Global Resource Directory frozen 동안에는 GRD를 다시 나누느라 블록 전송이 멈추므로 살아 있는 쪽 세션도 잠깐 gc 대기를 겪습니다. Beginning instance recovery of 1 threads에서 SMON이 죽은 thread 2를 맡고, 리두 그룹 두 멤버의 경로가 함께 찍힙니다. 마지막 메시지는 복구가 끝난 스레드를 닫는다는 뜻입니다.

@SLIDE 복구 시간과 재기동 시간|두 시간을 섞지 않는다
- 인스턴스 복구: 1초 미만 (살아 있는 쪽 영향)
- 인스턴스 재기동: 1분 가까이 (서비스 복귀)
- 죽은 쪽 세션: ORA-03113 으로 끊김
- 재접속·재실행은 FAN·TAF·AC (13장)
@NOTE 실습 05에서는 두 가지 시간을 구분해서 봅니다. 하나는 인스턴스 복구 시간으로, 1초가 걸리지 않았습니다. racdb1에 붙어 있는 세션이 겪는 영향은 이 시간뿐입니다. 다른 하나는 Clusterware가 racdb2를 다시 올려 Open이 될 때까지의 시간으로 1분 가까이 걸렸습니다. racdb2에 붙어 있던 세션은 ORA-03113을 받고 끊깁니다. 이 세션을 자동으로 이어 주거나 진행 중이던 작업을 다시 실행하는 것은 13장에서 다룬 FAN, TAF, Application Continuity의 몫입니다.

@SEC 14.8|미디어 복구
- 장애 만들기
- 복원과 복구

@IMG 14_media.png|데이터 파일 미디어 복구|데이터베이스는 열린 채로
@NOTE 미디어 복구는 파일 자체를 잃었을 때 백업에서 복원하고 리두를 적용하는 작업입니다. 실습 06은 데이터 파일 하나를 오프라인으로 만들고 ASM에서 지운 다음, restore와 recover로 되살리고 다시 온라인으로 돌립니다. 그동안 데이터베이스는 계속 열려 있습니다. 아래 비교표를 보면 인스턴스 복구는 자동이고 백업이 필요 없지만, 미디어 복구는 DBA가 직접 하고 백업과 모든 스레드의 아카이브가 필요합니다. 두 복구를 혼동하지 않도록 이 표를 기준으로 정리해 두십시오.

@SLIDE 장애 만들기|두 뷰가 다른 상태를 보여 준다
- 데이터 파일 27 offline → V$DATAFILE: RECOVER
- V$DATAFILE_HEADER: OFFLINE
- asmcmd rm 으로 파일 삭제
- rac2 조회: ORA-00376 + ORA-01110
@NOTE 실습 06에서는 전용 테이블스페이스에 500행을 넣고 백업한 뒤 장애를 만듭니다. 데이터 파일을 오프라인으로 하면 v datafile은 RECOVER, v datafile header는 OFFLINE을 보여 줍니다. 앞은 컨트롤 파일이 아는 상태, 뒤는 파일 헤더가 아는 상태입니다. 그다음 grid 계정으로 asmcmd rm을 해서 파일을 지웁니다. rac2에서 그 테이블을 읽으면 ORA-00376과 ORA-01110이 함께 납니다. 위 오류는 지금 읽을 수 없다는 일반적인 내용이고, 아래 오류가 어느 파일인지 알려 줍니다.

@SLIDE 복원과 복구|restore → recover → online
- restore datafile 27: +FRA 백업셋에서 +DATA 로
- ASM 이름의 숫자 부분이 바뀐다
- recover datafile 27: 두 스레드의 리두 적용
- online 후 rac1·rac2 모두 500행 확인
@NOTE 복구는 RMAN에서 restore와 recover 두 명령으로 끝납니다. restore가 +FRA의 백업셋에서 파일을 꺼내 +DATA에 다시 만드는데, ASM이 새 파일을 만드는 것이라 이름 끝의 숫자가 바뀝니다. 같은 논리 파일이고 컨트롤 파일이 새 이름을 기록하므로 문제는 없습니다. recover는 백업 이후의 변경을 thread 1과 thread 2의 리두에서 적용합니다. 온라인으로 돌린 뒤에는 rac1과 rac2 양쪽에서 행 수와 파일 상태를 확인하고 마칩니다.

@SEC 14.9|컨트롤 파일·SPFILE과 운영 지침
- 자동 백업
- restore spfile to 의 부작용
- 전체 손실 절차와 점검 항목

@SLIDE 컨트롤 파일과 SPFILE 위치|자동 백업이 기본값
- 컨트롤 파일: +DATA, +FRA 두 벌
- SPFILE: +DATA/RACDB/PARAMETERFILE 한 벌
- CONTROLFILE AUTOBACKUP ON, FORMAT '%F'
- list backup of controlfile summary 로 확인
@NOTE 컨트롤 파일은 +DATA와 +FRA에 다중화되어 있고 SPFILE은 +DATA에 한 벌 있습니다. 19c에서 컨트롤 파일 자동 백업은 기본으로 켜져 있어서, 백업이나 구조 변경이 있을 때마다 +FRA의 AUTOBACKUP 디렉터리에 컨트롤 파일과 SPFILE이 함께 저장됩니다. 최근 자동 백업이 언제 만들어졌는지는 list backup of controlfile summary로 확인할 수 있습니다. 컨트롤 파일을 모두 잃었을 때 기댈 곳이 이 자동 백업이므로 존재 여부를 정기적으로 확인합니다.

@IMG 14_spfile.png|restore spfile to 의 부작용|CRS 에 등록된 SPFILE 경로가 바뀐다
@NOTE 자동 백업이 쓸 만한지 확인하려고 SPFILE을 임시 위치로 복원해 보는 경우가 있습니다. 파일은 정상으로 나오고 인스턴스별 항목도 그대로 있습니다. 그런데 srvctl config database를 보면 CRS에 등록된 SPFILE 경로가 그 임시 경로로 바뀌어 있습니다. 실행 중인 인스턴스는 기동 때 읽은 파일을 계속 쓰므로 그날은 아무 문제가 없습니다. 몇 주 뒤 계획 정지 후 srvctl로 올릴 때 임시 파일이 지워져 있으면 그때 문제가 드러납니다. 복원 전에 원래 경로를 기록하고 반드시 되돌려야 합니다.

@SLIDE 컨트롤 파일 전체 손실|절차만 익힌다
- stop -o abort → 한 노드 startup nomount
- set dbid → restore controlfile from autobackup
- mount → recover database → open resetlogs
- 다른 인스턴스는 모두 내려가 있어야 한다
@NOTE 두 컨트롤 파일을 모두 잃는 상황은 실습에서 재현하지 않고 절차만 익힙니다. 먼저 abort 옵션으로 데이터베이스를 모두 내립니다. 컨트롤 파일이 없으니 정상 종료가 안 됩니다. 한 노드에서 nomount로 올리고 RMAN에서 DBID를 지정한 뒤 자동 백업으로 컨트롤 파일을 복원합니다. 마운트하고 모든 스레드의 아카이브로 recover한 다음 resetlogs로 엽니다. RAC에서는 이 동안 다른 인스턴스가 완전히 내려가 있어야 하고, DBID는 운영 문서에 미리 적어 두어야 합니다.

@SLIDE 삭제 정책과 점검 항목|ARCHIVELOG 는 되돌리지 않는다
- 삭제 정책: BACKED UP n TIMES TO DISK
- 매일: 스레드별 아카이브, FRA 사용률, 대상 VALID
- 주간: 다른 노드 validate, 스레드별 시퀀스 끊김
- 변경 후: SPFILE 등록 경로, DBID 기록
@NOTE 실습이 끝나도 ARCHIVELOG 모드는 그대로 둡니다. 대신 아카이브가 계속 쌓이므로 삭제 정책을 정합니다. 일반적으로 디스크에 n번 백업된 것만 지우는 정책을 쓰고, Data Guard가 있으면 스탠바이 적용 기준을 씁니다. 점검 항목 가운데 다른 노드에서의 validate와 스레드별 시퀀스 끊김 확인은 RAC에만 있는 것입니다. 스레드마다 시퀀스가 독립적이라서 한 스레드만 끊길 수 있습니다. 아카이브 대상 상태 점검은 앞에서 본 INACTIVE 사고를 미리 잡아 줍니다.

@PLAIN 요약
- 데이터 파일은 한 벌, 리두·아카이브는 스레드별. 복구엔 모든 스레드
- ARCHIVELOG 전환은 한 인스턴스만 MOUNT. 아니면 ORA-01126
- 로컬 아카이브는 다른 노드에서 실패, 빈 문자열은 ORA-16014
- 채널은 노드 VIP 로 고정, instance= 로 확인
- 인스턴스 복구 1초 미만, 재기동 시간과 구분
- restore spfile to 뒤에는 CRS 등록 경로를 되돌린다

@PLAIN 퀴즈
- 1. ARCHIVELOG 전환 절차와 거부될 때의 오류 번호는?
- 2. log_archive_format 의 %t 가 RAC 에서 필요한 이유는?
- 3. 로컬 아카이브일 때 rac2 crosscheck 결과와 영향은?
- 4. 채널을 인스턴스에 고정하는 주소와 확인 방법은?
- 5. 인스턴스 복구와 미디어 복구의 차이는?
- 6. restore spfile to 실행 뒤 되돌려야 할 것은?

@PLAIN 실습 개요
- 01  아카이브 구성과 ARCHIVELOG 전환
- 03 ★  노드 분산 백업 — 채널을 두 VIP 에
- 05 ★⚠  인스턴스 복구 관찰 — 알럿 로그 읽기
- 06 ⚠  미디어 복구 — 데이터 파일 손실과 복구
- 파일: RAC/17장/17장_실습_NN_*.txt, 끝나면 rac-base 복원
