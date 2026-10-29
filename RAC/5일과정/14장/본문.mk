@H1 제14장  RAC 백업과 복구

@H2 14.1  학습 목표

@P RAC의 백업과 복구는 RMAN 명령 자체로 보면 단일 인스턴스와 같다. 데이터 파일과 컨트롤 파일이 한 벌이기 때문이다. 달라지는 곳은 리두가 인스턴스마다 따로 쌓인다는 점, 백업을 여러 노드에 나눠 돌릴 수 있다는 점, 인스턴스 하나가 죽으면 다른 인스턴스가 복구를 대신한다는 점이다. 이 장은 그 세 가지를 중심으로 아카이브 구성, 노드 분산 백업, 인스턴스 복구, 미디어 복구, 컨트롤 파일·SPFILE 보호를 다룬다.

@B RAC 데이터베이스를 ARCHIVELOG 모드로 전환하는 절차와 ORA-01126이 나는 조건을 설명할 수 있다.
@B 스레드별 아카이브가 생기는 구조와 `log_archive_format`의 `%t`가 필요한 이유를 말할 수 있다.
@B 아카이브를 노드 로컬 경로에 두었을 때 생기는 문제와 `log_archive_dest_1=''`의 함정을 설명할 수 있다.
@B 채널을 노드 VIP로 접속시켜 백업을 두 인스턴스에 나누고, 출력으로 분산 여부를 확인할 수 있다.
@B 인스턴스 복구가 알럿 로그에 남기는 순서를 읽고, 인스턴스 복구 시간과 재기동 시간을 구분할 수 있다.
@B 데이터 파일 하나를 데이터베이스를 연 채로 복원·복구할 수 있다.
@B `restore spfile to` 가 CRS 등록 정보를 바꾸는 부작용과 컨트롤 파일 전체 손실 때의 절차를 설명할 수 있다.

@H2 14.2  RAC 백업의 전제

@P 백업 설계에 앞서 무엇이 한 벌이고 무엇이 인스턴스마다 따로인지 다시 정리한다. 1장과 10장에서 본 구조가 그대로 백업 설계의 전제가 된다.

@TBL
대상 | RAC에서의 형태 | 백업 관점
데이터 파일 | +DATA에 한 벌 | 어느 인스턴스에서 백업해도 같은 파일을 읽는다
컨트롤 파일 | +DATA·+FRA에 다중화, 내용은 하나 | 자동 백업으로 보호. 모든 스레드의 아카이브 기록을 함께 가진다
온라인 리두 | 인스턴스마다 스레드 | thread 1은 racdb1, thread 2는 racdb2가 쓴다
아카이브 | 스레드마다 따로 생성 | 복구에는 모든 스레드의 아카이브가 필요하다
SPFILE | +DATA에 한 벌 | `racdb1.` · `racdb2.` 접두어 항목이 함께 백업된다
@END

@B 스레드마다 시퀀스 번호가 독립적으로 증가한다. thread 1이 seq 19일 때 thread 2는 seq 14일 수 있다.
@B 미디어 복구는 모든 스레드의 리두를 SCN 순서로 합쳐 적용한다. 한 스레드의 아카이브가 하나라도 빠지면 그 지점 이후로 복구가 나아가지 못한다.
@B 그래서 RAC 백업의 첫 번째 조건은 "어느 노드에서든 모든 스레드의 아카이브를 읽을 수 있다"이다. 실습 환경은 아카이브를 공유 디스크그룹 +FRA에 두어 이 조건을 만족한다.

@H2 14.3  ARCHIVELOG 구성

@P 설치 가이드 v2의 9장(DBCA)으로 만든 racdb는 NOARCHIVELOG로 시작한다. 온라인 백업과 미디어 복구를 하려면 ARCHIVELOG로 바꿔야 한다.

@H3 14.3.1  아카이브 관련 파라미터

@CODE
SQL> select log_mode, name, dbid from v$database;

LOG_MODE     NAME            DBID
------------ --------- ----------
NOARCHIVELOG RACDB     1240378513
@END

@B `db_recovery_file_dest`는 두 인스턴스 모두 `+FRA`다. `log_archive_dest_1`을 지정하지 않으면 아카이브가 FRA(`USE_DB_RECOVERY_FILE_DEST`)로 간다.
@B `log_archive_format`의 기본값은 `%t_%s_%r.dbf`다. `%t`는 스레드, `%s`는 시퀀스, `%r`은 리셋로그 ID다. RAC에서는 스레드가 이름에 들어가야 두 인스턴스의 아카이브가 서로 덮어쓰지 않는다.
@B ASM에 저장할 때는 OMF 이름(`thread_1_seq_18.265.…`)이 붙어 형식 파라미터가 쓰이지 않는다. 파일 시스템 경로로 보낼 때 이 형식이 그대로 파일 이름이 된다.
@B DBID는 이 시점에 기록해 둔다. 컨트롤 파일을 모두 잃으면 데이터베이스가 자기 DBID를 모르므로 복구에 이 값이 필요하다(14.9.3).

@H3 14.3.2  전환 절차

@B 아카이브 모드는 컨트롤 파일의 전역 속성이다. 한 인스턴스만 MOUNT한 상태에서 바꿔야 한다.
@B 절차는 네 단계다. `srvctl stop database`로 전부 내리고, 한 노드에서 `startup mount`, `alter database archivelog`, `alter database open`을 한 뒤 나머지 인스턴스를 `srvctl start instance`로 올린다.
@B 옛 자료에는 `cluster_database=FALSE`로 바꾼 뒤 전환하라고 되어 있다. 11gR2 이후로는 필요 없다. 이 파라미터를 건드리면 오히려 되돌리는 작업이 하나 더 생긴다(9장).

@CODE
[oracle@rac1 ~]$ srvctl stop database -d racdb
SQL> startup mount
SQL> alter database archivelog;
SQL> alter database open;
[oracle@rac1 ~]$ srvctl start instance -d racdb -i racdb2
[oracle@rac1 ~]$ srvctl status database -d racdb -v
Instance racdb1 is running on node rac1. Instance status: Open.
Instance racdb2 is running on node rac2. Instance status: Open.
@END

@B 다른 인스턴스가 데이터베이스를 연 상태에서 전환을 시도하면 `ORA-01126: database must be mounted in this instance and not open in any instance`로 거부된다. 실수로 잘못 바뀔 여지가 적다.
@B 데이터베이스를 한 번 완전히 내리는 작업이다. 실습 01은 부하가 낮을 때 진행하고, racdb2 기동을 포함해 몇 분이 걸린다.
@B `startup mount` 뒤 rac1에서 인스턴스를 연 상태는 Clusterware 입장에서 정상 기동과 같다. 나머지 인스턴스를 `srvctl`로 올리면 Management policy AUTOMATIC 구성이 그대로 유지된다.

@H3 14.3.3  스레드별로 생기는 아카이브

@IMG 14_archive.png | 그림 14-1. 아카이브 위치 — 공유 +FRA는 어느 노드에서든 두 스레드가 보이고, 로컬 경로는 그 노드에서만 보인다

@CODE
SQL> select thread#, sequence#, name from v$archived_log
  2   where deleted='NO' and name like '+FRA%ARCHIVELOG%' order by 1,2;
   THREAD#  SEQUENCE# NAME
---------- ---------- --------------------------------------------------
         1         18 +FRA/RACDB/ARCHIVELOG/2026_09_04/thread_1_seq_18...
         1         19 +FRA/RACDB/ARCHIVELOG/2026_09_04/thread_1_seq_19...
         2         13 +FRA/RACDB/ARCHIVELOG/2026_09_04/thread_2_seq_13...
         2         14 +FRA/RACDB/ARCHIVELOG/2026_09_04/thread_2_seq_14...
@END

@B rac1에서 `alter system archive log current`를 하면 thread 1의 시퀀스가, rac2에서 하면 thread 2의 시퀀스가 증가한다.
@B rac2에서 같은 조회를 해도 같은 행이 나온다. 두 노드가 같은 컨트롤 파일과 같은 ASM을 보기 때문이다.
@B `V$ARCHIVED_LOG`는 컨트롤 파일의 기록이다. 기록이 있다고 파일이 그 노드에서 읽힌다는 보장은 없다(14.4).

@BP FRA 크기는 보관 기간으로 잡는다
`db_recovery_file_dest_size`는 디스크그룹 크기와 별개의 한도다. FRA가 한도에 이르면 아카이브를 만들지 못한 인스턴스가 멈추고 서비스 전체에 영향이 간다.
하루 아카이브 양은 두 인스턴스의 리두 발생량 합이다. 여기에 백업 주기와 보관 정책을 곱해 한도를 정하고, `V$RECOVERY_FILE_DEST`의 `SPACE_RECLAIMABLE`로 삭제 정책이 돌고 있는지 함께 본다.
@END

@H2 14.4  아카이브 위치의 함정

@P 아카이브 대상을 잘못 바꾸는 사고는 두 가지 형태로 나타난다. 한 노드에만 있는 경로를 지정하는 경우와, 되돌리려고 빈 값을 넣는 경우다. 실습 02(자습)가 두 경우를 재현한다.

@H3 14.4.1  한 노드에만 있는 경로

@B rac1의 `log_archive_dest_1`만 `LOCATION=/u01/app/oracle/arch_local`로 바꾸면 thread 1의 아카이브가 rac1 로컬 디스크에 생긴다. 파일 이름은 형식 파라미터 그대로 `1_23_1242761748.dbf`가 된다.
@B 컨트롤 파일은 공유되므로 rac2의 `V$ARCHIVED_LOG`에도 이 파일이 보인다. 그러나 rac2에는 그 디렉터리가 없다.
@B 로컬 경로에 데이터 파일을 만들었을 때 다른 노드가 ORA-01157을 내던 것과 같은 구조다(10장). 딕셔너리에는 이름이 있고 파일은 한 노드에만 있다.

@CODE
-- rac2 에서
RMAN> crosscheck archivelog all;
validation failed for archived log
archived log file name=/u01/app/oracle/arch_local/1_23_1242761748.dbf RECID=44
   ( 같은 실패가 1_24, 1_25 에서도 나고 +FRA 의 아카이브는 모두 succeeded )
@END

@B 이 구성은 세 가지 문제를 만든다. 백업을 그 노드에서만 돌려야 하고, 그 노드가 죽으면 그 아카이브를 못 읽고, 복구할 때 모든 스레드의 아카이브가 한곳에 모이지 않는다.
@B 백업 스케줄러가 노드를 가리지 않고 작업을 띄우는 환경이라면 어느 날의 백업에서 thread 1 구간이 조용히 빠진다. 복구가 필요해진 날에야 드러난다.

@H3 14.4.2  빈 문자열은 기본값 복원이 아니다

@CODE
SQL> alter system set log_archive_dest_1='' sid='racdb1' scope=memory;
SQL> alter system archive log current;
ORA-16014: log 2 sequence# 26 not archived, no available destinations
ORA-00312: online log 2 thread 1: '+DATA/RACDB/ONLINELOG/group_2.263.1242761749'
@END

@B 처음에 이 파라미터는 지정되지 않은 상태였고, 그때는 FRA가 암묵적으로 쓰였다. 한 번 지정한 뒤 빈 값을 넣으면 대상이 비활성화될 뿐 암묵적 동작이 돌아오지 않는다.
@B `GV$ARCHIVE_DEST`에서 inst_id 1, dest_id 1의 `STATUS`가 `INACTIVE`로 바뀐다. 이대로 두면 온라인 리두 그룹이 모두 차는 순간 인스턴스가 멈춘다.
@B 메모리 값은 `LOCATION=USE_DB_RECOVERY_FILE_DEST`를 명시해 되살린다. SPFILE에 남긴 값이라면 `alter system reset log_archive_dest_1 sid='racdb1' scope=spfile`로 항목을 지운다.
@B 원래 상태가 "지정 안 됨"이었는지는 `V$SPPARAMETER`의 `ISSPECIFIED`로 확인한다. FALSE면 지정된 적이 없다.

@BP 아카이브 대상을 바꾼 직후에는 반드시 검증한다
`alter system archive log current`를 바로 실행하고 `GV$ARCHIVE_DEST`의 `STATUS`가 두 인스턴스 모두 VALID인지 본다. 리두가 다 찬 뒤에 알게 되면 그때는 인스턴스가 이미 멈춰 있다.
@END

@H2 14.5  노드 분산 백업

@P 백업은 CPU와 I/O를 많이 쓴다. RAC에서는 채널을 여러 인스턴스에 나눠 부하를 분산할 수 있다. 관건은 채널이 원하는 인스턴스에 정확히 붙게 하는 것이다.

@IMG 14_channels.png | 그림 14-2. 노드 분산 백업 — 채널 ch1은 rac1-vip로, ch2는 rac2-vip로 접속해 각 인스턴스에 고정된다

@H3 14.5.1  채널을 인스턴스에 고정한다

@B SCAN으로 접속하면 서비스가 두 인스턴스에 있으므로 어느 쪽으로 갈지 정할 수 없다.
@B 노드 VIP로 접속하면 그 노드의 로컬 리스너가 받는다. 로컬 리스너에는 그 노드의 인스턴스만 등록되어 있어 결과가 결정적이다.
@B 12장에서는 접속 확인을 SCAN으로 하라고 했다. 그것은 서비스 동작을 검증할 때의 이야기다. 특정 인스턴스를 지목해야 하는 백업 채널은 VIP를 쓴다.

@CODE
RMAN> run {
  allocate channel ch1 device type disk connect 'sys/<SYS 비밀번호>@rac1-vip:1521/racdb';
  allocate channel ch2 device type disk connect 'sys/<SYS 비밀번호>@rac2-vip:1521/racdb';
  backup as compressed backupset database format '+FRA';
  release channel ch1;
  release channel ch2;
}
channel ch1: SID=282 instance=racdb1 device type=DISK
channel ch2: SID=149 instance=racdb2 device type=DISK
@END

@B 분산이 실제로 일어났는지는 `instance=` 두 줄로 확인한다. 명령을 그렇게 썼다는 것만으로는 근거가 되지 않는다.
@B 어느 데이터 파일을 어느 채널이 맡을지는 RMAN이 정한다. 출력의 `input datafile` 줄을 보면 두 채널에 파일이 나뉜 것이 보인다.
@B 백업이 끝나면 컨트롤 파일과 SPFILE 자동 백업이 이어서 만들어진다. `CONTROLFILE AUTOBACKUP ON`이 19c의 기본값이다.

@H3 14.5.2  채널 수와 압축

@B 노드당 채널 수는 그 노드의 CPU와 I/O 대역폭이 정한다. 노드가 둘이라고 채널이 둘이어야 하는 것은 아니다.
@B 노드당 vCPU 4개인 실습 환경은 노드당 채널 1개로 진행한다. 호스트 자원이 빠듯할 때 채널을 늘리면 하트비트가 늦어져 노드 축출까지 갈 수 있다.
@B 백업 전에 `cat /proc/loadavg`로 부하를 확인한다. 부하가 높을 때는 채널 수를 줄이거나 시간대를 옮긴다.
@B `as compressed backupset`은 I/O를 줄이는 대신 CPU를 더 쓴다. 스토리지가 병목이면 이득이고 CPU가 병목이면 손해다.

@TBL
오류 | 원인 | 확인
ORA-12545 | 채널 접속 문자열의 호스트가 없다(`rac9-vip` 같은 오타) | `srvctl config nodeapps`, `tnsping rac1-vip:1521/racdb`
RMAN-03009 | 위 오류로 allocate 명령이 실패했다는 상위 메시지 | 바로 아래 줄의 ORA 번호를 본다
ORA-01017 | SYS 비밀번호 불일치 | 암호 파일은 +DATA에 한 벌이므로 두 노드 공통이다
@END

@B 접속 문자열은 스크립트에 넣기 전에 `sqlplus`로 먼저 붙여 보고 `v$instance`가 의도한 인스턴스인지 확인한다.

@H2 14.6  백업 검증

@P 백업이 만들어졌다는 것과 복구에 쓸 수 있다는 것은 다르다. RAC에서는 여기에 "어느 노드에서든 쓸 수 있는가"가 더해진다.

@B `restore database validate`는 백업셋을 실제로 읽어 복원 가능한지만 확인하고 데이터 파일을 건드리지 않는다.
@B 한 노드에서 만든 백업을 다른 노드에서 validate해 본다. 성공하면 그 백업은 어느 노드에서든 복구에 쓸 수 있다. 백업 조각이 +FRA에 있으므로 정상 구성이라면 성공한다.
@B `list backup summary`의 TY 열에서 A는 아카이브 백업, F는 전체 데이터 파일 백업이다. 자동 백업은 Compressed가 NO로 나온다.

@CODE
-- rac2 에서
RMAN> restore database validate;
channel ORA_DISK_1: validation complete, elapsed time: 00:00:26
Finished restore at 04-SEP-26
@END

@NOTE 스냅샷 컨트롤 파일 위치
`show all`의 `SNAPSHOT CONTROLFILE NAME`은 기본값이 DB 홈 아래 `dbs/snapcf_racdb1.f` 같은 로컬 경로다. 백업 중에 컨트롤 파일의 일관된 사본을 잠시 만드는 파일이다.
11gR2 이후 RAC에서는 컨트롤 파일 백업 때 모든 인스턴스가 이 파일에 접근할 수 있어야 하며, 그렇지 않으면 ORA-00245로 백업이 실패할 수 있다고 문서화되어 있다. 실습 환경은 백업을 rac1에서 시작해 기본값으로도 진행되지만, 운영 환경에서는 `CONFIGURE SNAPSHOT CONTROLFILE NAME TO '+DATA/snapcf_racdb.f'`처럼 공유 위치로 두는 편이 안전하다.
@END

@H2 14.7  인스턴스 복구

@P 인스턴스 복구는 1장에서 개념으로 다룬 "살아 있는 인스턴스가 죽은 인스턴스의 스레드를 읽어 복구한다"는 동작이다. 실습 05는 racdb2를 강제로 죽이고 racdb1의 알럿 로그로 이 과정을 따라간다.

@IMG 14_instrecovery.png | 그림 14-3. 인스턴스 복구의 순서 — 재구성(GRD 동결)과 thread 2 리두 적용을 거쳐 1초 안에 끝난다

@H3 14.7.1  복구 시간을 미리 가늠한다

@CODE
SQL> select inst_id, recovery_estimated_ios, actual_redo_blks,
  2         estimated_mttr, target_mttr from gv$instance_recovery;
   INST_ID RECOVERY_ESTIMATED_IOS ACTUAL_REDO_BLKS ESTIMATED_MTTR TARGET_MTTR
---------- ---------------------- ---------------- -------------- -----------
         1                   1161             9651              1           0
         2                   1018             7507              1           0
@END

@B `ACTUAL_REDO_BLKS`는 마지막 체크포인트 이후 쌓인 리두 블록 수다. 인스턴스 복구는 이 구간만 읽는다.
@B `ESTIMATED_MTTR`은 지금 인스턴스가 죽으면 복구에 걸릴 예상 초다. `fast_start_mttr_target`을 지정하면 `TARGET_MTTR`이 그 목표를 보여 주고, DBWn이 체크포인트를 앞당겨 목표를 맞춘다.

@H3 14.7.2  알럿 로그에 남는 순서

@CODE
Reconfiguration started (old inc 4, new inc 6)
Dead instances (total 1) : 2
 Global Resource Directory frozen
* dead instance detected - domain 2 invalid = TRUE, need cdb-level instance recovery
Reconfiguration complete (total time 0.1 secs)
Beginning instance recovery of 1 threads
 Thread 2: Recovery starting at checkpoint rba (logseq 25 block 8), scn 0
Completed instance recovery at
Redo thread 2 internally disabled at seq 26 (SMON)
@END

@B `Reconfiguration started`는 클러스터가 구성원 변화를 알아챘다는 표시다. 인스턴스 incarnation 번호가 올라간다.
@B `Global Resource Directory frozen` 동안은 GRD를 다시 나누느라 블록 전송이 멈춘다. 살아 있는 인스턴스의 세션도 이 짧은 시간 동안 gc 대기를 겪는다.
@B `Beginning instance recovery of 1 threads`에서 SMON이 thread 2를 맡는다. 온라인 리두 그룹의 두 멤버(+DATA, +FRA) 경로가 함께 찍힌다.
@B 롤포워드로 리두를 적용한 뒤 커밋되지 않은 트랜잭션을 롤백한다. 롤백은 데이터베이스를 연 뒤에도 필요한 블록부터 진행된다.
@B `Redo thread 2 internally disabled`는 복구를 마친 스레드를 닫는 표시다. racdb2가 다시 뜨면 스레드가 다시 열린다.

@H3 14.7.3  복구 시간과 재기동 시간

@B 실습 05 기록에서 재구성 시작부터 인스턴스 복구 완료까지는 1초가 걸리지 않았다. 앞서 본 `ESTIMATED_MTTR` 1초와 맞는다.
@B Clusterware가 racdb2를 자동으로 다시 올려 Open이 되기까지는 1분 가까이 걸렸다.
@B 살아 있는 인스턴스에 붙은 세션이 겪는 것은 앞의 시간이다. 죽은 인스턴스에 붙어 있던 세션은 끊기고, 재접속과 재실행은 13장의 FAN·TAF·AC가 다룬다.
@B 죽은 쪽 세션은 `ORA-03113: end-of-file on communication channel`을 받는다. 서버 프로세스와의 연결이 끊어졌다는 뜻이다.

@H2 14.8  미디어 복구

@P 미디어 복구는 파일 자체를 잃었을 때 백업에서 복원하고 리두를 적용해 현재 시점으로 되돌리는 작업이다. 데이터 파일 하나라면 데이터베이스를 연 채로 할 수 있다.

@IMG 14_media.png | 그림 14-4. 데이터 파일 하나의 미디어 복구 흐름과 인스턴스 복구와의 비교

@H3 14.8.1  장애 만들기

@B 실습 06은 전용 테이블스페이스 `ts_ch17`을 만들어 테이블에 500행을 넣고, 두 채널로 그 테이블스페이스를 백업한 뒤 장애를 만든다.
@B 데이터 파일을 오프라인으로 하면 `V$DATAFILE`의 `STATUS`는 `RECOVER`, `V$DATAFILE_HEADER`의 `STATUS`는 `OFFLINE`이다. 앞은 컨트롤 파일이 아는 상태이고 뒤는 파일 헤더가 아는 상태다.
@B grid 계정으로 `asmcmd rm`해 파일을 지우면 rac2에서 그 테이블을 읽을 때 오류가 난다.

@CODE
SQL> select count(*) from sys.ch17_t;
ORA-00376: file 27 cannot be read at this time
ORA-01110: data file 27: '+DATA/RACDB/DATAFILE/ts_ch17.279.1243091315'
@END

@B ORA-00376은 지금 읽을 수 없다는 뜻이고 ORA-01110이 어느 파일인지 알려 준다. 겹쳐 나온 오류는 아래 줄이 구체적인 사실이다.

@H3 14.8.2  복원과 복구

@CODE
RMAN> run {
  allocate channel ch1 device type disk;
  restore datafile 27;
  recover datafile 27;
  release channel ch1;
}
SQL> alter database datafile 27 online;
@END

@B `restore`는 +FRA의 백업셋에서 파일을 꺼내 +DATA에 다시 만든다. ASM이 새 파일을 만들므로 이름의 숫자 부분이 바뀐다(`ts_ch17.279.1243091377`). 같은 논리 파일이며 컨트롤 파일이 새 이름을 기록한다.
@B `recover`는 백업 이후의 변경을 아카이브와 온라인 리두에서 적용한다. thread 1과 thread 2의 리두가 모두 대상이다.
@B 온라인으로 돌린 뒤 rac1과 rac2 양쪽에서 500행이 나오고 `V$DATAFILE`의 상태가 ONLINE인지 확인한다.
@B SYSTEM이나 UNDO 데이터 파일처럼 데이터베이스가 열려 있는 동안 오프라인으로 할 수 없는 파일은 데이터베이스를 MOUNT 상태로 내려 같은 절차를 밟는다. RAC에서는 이때 다른 인스턴스도 모두 내려가 있어야 한다.

@H2 14.9  컨트롤 파일과 SPFILE

@P 컨트롤 파일과 SPFILE은 둘 다 +DATA에 한 벌이다. 컨트롤 파일은 +FRA에 다중화 사본이 있고, 둘 다 자동 백업으로 보호한다.

@H3 14.9.1  위치와 자동 백업

@CODE
SQL> select name from v$controlfile;
+DATA/RACDB/CONTROLFILE/current.261.1242761745
+FRA/RACDB/CONTROLFILE/current.256.1242761745
SQL> select value from v$parameter where name='spfile';
+DATA/RACDB/PARAMETERFILE/spfile.272.1242762487
@END

@B `show all`의 `CONTROLFILE AUTOBACKUP ON`과 `FORMAT ... TO '%F'`가 기본값이다. 백업이나 구조 변경이 있을 때마다 +FRA/RACDB/AUTOBACKUP 아래에 컨트롤 파일과 SPFILE이 함께 저장된다.
@B `list backup of controlfile summary`로 최근 자동 백업을 확인한다.

@H3 14.9.2  restore spfile to 의 부작용

@IMG 14_spfile.png | 그림 14-5. 임시 위치로 SPFILE을 복원하면 CRS에 등록된 SPFILE 경로가 그 위치로 바뀐다

@B 자동 백업이 쓸 만한지 확인하려고 `restore spfile to '/tmp/spfile_ch17_test.ora' from autobackup`을 실행하면 데이터베이스를 연 채로 SPFILE을 임시 위치에 꺼낼 수 있다. 꺼낸 파일에는 `racdb1.`과 `racdb2.` 접두어 항목이 그대로 들어 있다.
@B 이 명령은 읽기 전용이 아니다. 실행 뒤 `srvctl config database -d racdb`의 `Spfile:` 줄이 `/tmp/spfile_ch17_test.ora`로 바뀐다. 백업만 했을 때는 바뀌지 않아 원인이 이 명령임을 대조로 확인할 수 있다.
@B 실행 중인 인스턴스는 기동 때 읽은 SPFILE을 계속 쓰므로 `gv$parameter`의 spfile 값은 그대로다. 그날은 아무 이상이 없어 보인다.
@B 다음에 `srvctl`로 기동할 때 CRS에 등록된 임시 경로를 쓴다. 그 파일을 지웠다면 SPFILE 없이 기동을 시도하게 된다. 계획 정지 후 재기동에서 문제가 드러나 원인을 찾기 어렵다.

@CODE
[oracle@rac1 ~]$ srvctl modify database -d racdb \
>   -spfile '+DATA/RACDB/PARAMETERFILE/spfile.272.1242762487'
[oracle@rac1 ~]$ srvctl config database -d racdb | grep -i spfile
Spfile: +DATA/RACDB/PARAMETERFILE/spfile.272.1242762487
@END

@BP 복원 전에 원래 값을 기록한다
RMAN의 restore 계열은 데이터를 되살리면서 그 위치를 카탈로그와 CRS에 반영한다. 읽기만 하는 것은 validate 계열이다.
검증이 목적이면 `list backup of spfile`과 `list backup of controlfile`로 자동 백업의 존재만 확인한다. 임시 위치로 복원했다면 `srvctl modify database -spfile`로 반드시 되돌린다.
@END

@H3 14.9.3  컨트롤 파일을 모두 잃었을 때

@P 두 컨트롤 파일을 모두 잃는 상황은 실습에서 재현하지 않는다. 절차만 익힌다.

@TBL
순서 | 작업 | RAC에서 주의할 점
1 | `srvctl stop database -d racdb -o abort` | 컨트롤 파일이 없어 정상 종료가 되지 않는다
2 | 한 노드에서 `startup nomount` | 다른 인스턴스는 모두 내려가 있어야 한다
3 | RMAN `set dbid 1240378513;` `restore controlfile from autobackup;` | DBID를 미리 기록해 두어야 한다
4 | `alter database mount;` `recover database;` | 모든 스레드의 아카이브가 필요하다
5 | `alter database open resetlogs;` | 컨트롤 파일을 복원하면 리셋로그가 필요하다
6 | `srvctl start instance -d racdb -i racdb2` | 나머지 인스턴스를 올리고 상태를 확인한다
@END

@B DBID는 `V$DATABASE`와 RMAN 접속 출력(`connected to target database: RACDB (DBID=1240378513)`)에 나온다. 운영 문서 첫 페이지에 적어 두는 것이 관례다.
@B SPFILE도 잃었다면 2단계 전에 `startup nomount`를 임시 파라미터로 하고 `restore spfile from autobackup`으로 원래 위치에 SPFILE을 되살린다.

@H2 14.10  운영 지침

@P 실습을 마친 뒤에도 ARCHIVELOG 모드는 되돌리지 않는다. 이후 장은 이 상태를 전제로 한다. 아카이브가 계속 쌓이므로 삭제 정책과 점검 항목을 함께 정한다.

@TBL
삭제 정책 | 의미 | 쓰는 곳
NONE | 자동으로 지우지 않는다 | 기본값. 수동 관리
BACKED UP n TIMES TO DISK | 디스크에 n번 백업된 것만 지운다 | 일반적인 선택
APPLIED ON ALL STANDBY | 스탠바이에 모두 적용된 것만 지운다 | Data Guard 구성
SHIPPED TO ALL STANDBY | 스탠바이로 전송된 것만 지운다 | Data Guard 구성
@END

@TBL
주기 | 확인 항목 | 방법
매일 | 스레드별 아카이브가 생기는가 | `v$archived_log`의 thread#별 최근 시각
매일 | FRA 사용률 | `v$recovery_file_dest`의 space_used·space_limit
매일 | 아카이브 대상 상태 | `gv$archive_dest`의 status가 VALID인가
주간 | 다른 노드에서도 백업이 유효한가 | 다른 노드에서 `restore database validate`
주간 | 스레드별 시퀀스 누락 | thread#로 묶어 시퀀스 끊김 확인
변경 후 | SPFILE 등록 경로와 DBID 기록 | `srvctl config database`, `v$database`
@END

@B 아카이브 대상 상태 점검은 14.4.2의 INACTIVE를 미리 잡는다.
@B 다른 노드 validate와 스레드별 시퀀스 점검은 RAC에만 있는 항목이다. 스레드마다 시퀀스가 독립적이라 한 스레드만 끊길 수 있다.

@H2 14.11  요약

@B RAC의 데이터 파일과 컨트롤 파일은 한 벌이고 리두와 아카이브는 스레드마다 따로다. 복구에는 모든 스레드의 아카이브가 필요하다.
@B ARCHIVELOG 전환은 전부 내린 뒤 한 인스턴스만 MOUNT한 상태에서 한다. 다른 인스턴스가 열려 있으면 ORA-01126이 난다.
@B 아카이브를 로컬 경로에 두면 다른 노드의 crosscheck가 실패한다. `log_archive_dest_1=''`은 대상 비활성화이며 ORA-16014로 이어진다.
@B 채널을 노드 VIP로 접속시키면 인스턴스에 고정된다. 출력의 `instance=`로 분산을 확인한다.
@B 인스턴스 복구는 SMON이 죽은 스레드의 온라인 리두로 자동 수행하며 1초 안팎이다. 인스턴스 재기동 시간과 구분한다.
@B 데이터 파일 하나는 오프라인 → restore → recover → 온라인으로 데이터베이스를 연 채 복구한다.
@B `restore spfile to`는 CRS의 SPFILE 경로를 바꾼다. 원래 값을 기록하고 `srvctl modify database -spfile`로 되돌린다.

@H2 14.12  퀴즈

@QUIZ 퀴즈
1. RAC 데이터베이스를 ARCHIVELOG로 전환하는 절차를 순서대로 쓰고, 다른 인스턴스가 열려 있을 때 나는 오류 번호를 쓰시오.
2. `log_archive_format`의 `%t`가 RAC에서 필요한 이유는?
3. rac1의 아카이브를 로컬 경로에 두었을 때 rac2의 `crosscheck archivelog all`이 보여 주는 결과와 그것이 복구에 미치는 영향은?
4. RMAN 채널을 특정 인스턴스에 고정하려면 어떤 주소로 접속해야 하며, 분산이 실제로 되었는지는 무엇으로 확인하는가?
5. 인스턴스 복구와 미디어 복구를 수행 주체, 읽는 리두, 백업 필요 여부로 비교하시오.
6. `restore spfile to '/tmp/…' from autobackup` 실행 뒤 확인하고 되돌려야 할 것은?
@END

@NOTE 정답과 해설
1. srvctl stop database → 한 노드에서 startup mount → alter database archivelog → alter database open → 나머지를 srvctl start instance. 다른 인스턴스가 열려 있으면 ORA-01126.
2. 스레드마다 시퀀스가 독립적이라 이름에 스레드가 없으면 두 인스턴스의 아카이브 이름이 겹친다. 파일 시스템 경로로 보낼 때 이 형식이 이름이 된다.
3. 로컬 경로의 thread 1 아카이브가 validation failed로 나온다. rac2에서 백업하면 그 구간이 빠지고, 복구가 그 지점에서 멈춘다.
4. 노드 VIP(rac1-vip, rac2-vip). 로컬 리스너에는 그 노드의 인스턴스만 있다. 채널 할당 출력의 instance=racdb1, instance=racdb2로 확인한다.
5. 인스턴스 복구는 살아 있는 인스턴스의 SMON이 자동으로, 죽은 스레드의 온라인 리두를 읽고 백업이 필요 없다. 미디어 복구는 DBA가 RMAN으로, 백업과 모든 스레드의 아카이브를 쓴다.
6. srvctl config database의 Spfile 경로가 임시 경로로 바뀐다. srvctl modify database -d racdb -spfile '+DATA/RACDB/PARAMETERFILE/spfile.272.1242762487'로 되돌린다.
@END

@H2 14.13  실습 개요

@P 이 장의 실습은 데이터베이스를 한 번 정지하고 인스턴스를 한 번 강제로 죽인다. ⚠ 실습은 그날의 마지막에 하고, 끝나면 두 노드를 정지해 `rac-base`로 되돌린다.

@TBL
실습 | 파일 | 목적
01 | RAC/17장/17장_실습_01_아카이브구성과전환.txt | 아카이브 파라미터를 확인하고 ARCHIVELOG로 전환해 스레드별 아카이브를 본다
03 ★ | RAC/17장/17장_실습_03_노드분산백업.txt | 채널을 두 VIP에 할당해 백업을 나누고 instance= 로 확인한다
05 ★⚠ | RAC/17장/17장_실습_05_인스턴스복구관찰.txt | racdb2를 강제 종료하고 racdb1 알럿 로그에서 인스턴스 복구 순서를 읽는다
06 ⚠ | RAC/17장/17장_실습_06_미디어복구.txt | 데이터 파일을 지우고 restore·recover로 되살려 두 노드에서 확인한다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습, ⚠는 스냅샷 복원이 필요한 실습이다.
@B 실습 01은 데이터베이스를 한 번 완전히 내린다. 시작 전에 `cat /proc/loadavg`로 부하를 확인한다.
@B 실습 05는 시작 전에 racdb1 알럿 로그를 `tail -f`로 열어 두고 관찰 시작 줄 번호를 기록한다.
@B 수료 후 자습: 17장_실습_02_오류재현_로컬아카이브, 17장_실습_04_백업검증, 17장_실습_07_컨트롤파일SPFILE과정리.
