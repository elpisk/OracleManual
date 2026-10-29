@H1 제9장  인스턴스와 클러스터 DB 관리

@H2 9.1  학습 목표

@P racdb는 설치 가이드 v2의 9장에서 DBCA로 만들어졌고, 지금까지는 그대로 써 왔다. 이 장은 먼저 그렇게 생성된 RAC 데이터베이스가 Clusterware에 어떻게 등록되어 있고 인스턴스마다 무엇을 따로 가지는지 읽는다. 이어서 인스턴스를 내리고 올리는 세 도구(srvctl, crsctl, SQL*Plus)에 Clusterware가 어떻게 반응하는지, SPFILE의 `sid.parameter` 표기를 어떻게 다루는지, PDB를 노드별로 어떻게 열고 닫는지를 다룬다.

@B `srvctl config database` 출력에서 인스턴스·노드·SPFILE·기동 정책을 읽어 낼 수 있다.
@B 인스턴스마다 배정된 리두 스레드와 UNDO 테이블스페이스를 조회로 확인할 수 있다.
@B PDB를 두 인스턴스에서 열고 `SAVE STATE INSTANCES=ALL`이 필요한 이유를 설명할 수 있다.
@B 정상 종료와 비정상 종료에서 자원의 TARGET·STATE가 어떻게 달라지고 Clusterware가 언제 다시 올리는지 설명할 수 있다.
@B 파라미터를 반드시 같아야 하는 것, 반드시 달라야 하는 것, 같은 것이 권장되는 것으로 나누고 `sid=` 지정의 위험을 설명할 수 있다.
@B `ALTER SYSTEM RESET`으로 인스턴스별 값을 지우고 SPFILE을 기준선으로 되돌릴 수 있다.

@H2 9.2  생성된 RAC DB의 구성 확인

@P DBCA가 끝났다고 RAC 데이터베이스가 제대로 만들어진 것은 아니다. Clusterware 등록, 인스턴스와 스레드, UNDO, SPFILE의 인스턴스별 값, PDB 상태를 차례로 확인한다. 생성 절차 자체는 설치 가이드 v2의 9장에 있다.

@IMG 09_config.png | 그림 9-1. srvctl config database 출력 읽기 — Clusterware에 저장된 racdb의 정의

@H3 9.2.1  srvctl config database

@CODE
[oracle@rac1 ~]$ srvctl config database -d racdb
Database unique name: racdb
Oracle home: /u01/app/oracle/product/19.3.0/dbhome_rac
Spfile: +DATA/RACDB/PARAMETERFILE/spfile.272.1242762487
Password file: +DATA/RACDB/PASSWORD/pwdracdb.256.1242761627
Start options: open
Stop options: immediate
Management policy: AUTOMATIC
Disk Groups: DATA,FRA
Type: RAC
Database instances: racdb1,racdb2
Configured nodes: rac1,rac2
Database is administrator managed
@END

@B 이 정의는 Clusterware 안(OCR)에 저장되어 데이터베이스가 내려가 있어도 남는다. 인스턴스를 띄우는 주체가 Clusterware이므로 SPFILE과 암호 파일 위치도 여기에 기록된다(8장).
@B `Start options: open`, `Stop options: immediate`는 srvctl을 옵션 없이 실행할 때의 기본 동작이다. `srvctl stop database`는 곧 `shutdown immediate`다.
@B `Management policy: AUTOMATIC`이면 노드가 부팅될 때 Clusterware가 데이터베이스를 자동으로 올린다.
@B `Disk Groups: DATA,FRA`는 시작 의존성이다. 이 디스크그룹이 마운트되어야 인스턴스가 기동한다.
@B `Database instances`와 `Configured nodes`, 마지막 줄 `administrator managed`가 racdb1은 rac1에, racdb2는 rac2에 고정 배치된다는 뜻이다.

@H3 9.2.2  인스턴스·스레드·UNDO 배정

@IMG 09_layout.png | 그림 9-2. 인스턴스마다 따로 가지는 것 — instance_number, 리두 스레드, UNDO 테이블스페이스

@CODE
SYS@racdb1> select inst_id, instance_name, host_name, thread#, status
  2    from gv$instance order by 1;
SYS@racdb1> select group#, thread#, status from v$log order by group#;
SYS@racdb1> select tablespace_name from dba_tablespaces where contents='UNDO';
SYS@racdb1> select inst_id, value from gv$parameter
  2   where name='undo_tablespace' order by 1;
@END

@B `GV$INSTANCE`에서 두 인스턴스가 서로 다른 노드에 있고 `THREAD#`가 1과 2인지 본다. 같은 스레드를 쓰면 두 인스턴스가 같은 리두 로그를 두고 다툰다.
@B `V$LOG`에서 그룹 1·2가 스레드 1, 3·4가 스레드 2다. 스레드마다 CURRENT가 하나씩 있어 인스턴스가 각자 로그 스위치를 한다. racdb는 멤버가 +DATA와 +FRA에 한 벌씩 있어 `V$LOGFILE`로 보면 8행이다.
@B UNDO 테이블스페이스는 UNDOTBS1·UNDOTBS2 둘이고 `undo_tablespace`가 인스턴스마다 다르다. 단일 인스턴스라면 하나뿐이다.

@TBL
검증 항목 | 확인 방법 | 기대값
Clusterware 자원 | crsctl stat res ora.racdb.db -t | 두 노드 ONLINE
인스턴스 | GV$INSTANCE | 노드 수만큼, 서로 다른 노드
리두 스레드 | GV$INSTANCE의 THREAD#, V$LOG | 인스턴스마다 다르고 스레드당 그룹 2개 이상
UNDO | DBA_TABLESPACES (contents='UNDO') | 인스턴스 수만큼
SPFILE 인스턴스별 값 | V$SPPARAMETER (sid <> '*') | 인스턴스당 3항목
PDB | GV$PDBS, DBA_PDB_SAVED_STATES | 두 노드 READ WRITE, 인스턴스마다 저장 상태 한 행
@END

@H3 9.2.3  PDB를 두 인스턴스에서 열고 저장하기

@CODE
SYS@racdb1> alter pluggable database racpdb1 open instances=all;
SYS@racdb1> alter pluggable database racpdb1 save state instances=all;
SYS@racdb1> select con_name, instance_name, state from dba_pdb_saved_states;
CON_NAME     INSTANCE_NAME    STATE
------------ ---------------- --------------
RACPDB1      racdb1           OPEN
RACPDB1      racdb2           OPEN
@END

@B DBCA는 PDB를 열어 두기만 하고 그 상태를 저장하지 않는다. 생성 직후 `DBA_PDB_SAVED_STATES`는 비어 있고, 이 상태로 재기동하면 CDB는 열려도 PDB는 두 노드 모두 MOUNTED로 남는다. 실습 기록에서는 DBCA로 만든 testdb를 내렸다 올리자 TESTPDB가 두 노드에서 MOUNTED가 되었다.
@B 여는 것과 저장하는 것은 별개의 명령이고, 저장 상태도 인스턴스별로 기록된다. 둘 다 `INSTANCES=ALL`을 붙여야 두 노드에 적용된다. racdb는 설치 가이드 v2의 9장에서 이 두 명령을 실행해 두었다.
@B 생성 직후가 재기동 시험을 하기 가장 좋은 때다. 데이터가 없어 위험이 낮고, 정지 후 순차 기동해서 위 표의 모든 항목이 제자리로 돌아오는지 확인한다.

@H2 9.3  세 가지 도구 — srvctl, crsctl, SQL*Plus

@P 인스턴스를 내리는 방법은 셋이다. Clusterware는 어떤 도구를 썼는지가 아니라 정상 종료인지 비정상 종료인지를 보고 반응한다. 그 판단의 근거가 자원의 TARGET과 STATE다.

@H3 9.3.1  start와 stop의 옵션

@TBL
옵션 | 명령 | 뜻
-startoption / -stopoption | start / stop | SQL*Plus의 startup·shutdown 인자 그대로 (OPEN, MOUNT, IMMEDIATE, ABORT 등)
-startconcurrency / -stopconcurrency | start / stop | 동시에 처리할 인스턴스 수. 자원이 빠듯하면 1로 순차 처리
-drain_timeout | stop | 정지 전에 서비스 세션이 빠질 시간(초). 12장의 서비스와 함께 쓴다
-eval | start / stop | 실행하지 않고 영향만 계산
-force | stop | 의존하는 서비스·자원까지 함께 정지
@END

@B `-force`는 stop에만 있다. 이것 없이 실패한다면 무언가가 그 데이터베이스에 의존하고 있다는 뜻이므로 먼저 무엇인지 확인한다.
@B 운영에서 정지 명령을 내리기 전에 `-eval`로 무엇이 함께 내려가는지 본다.

@H3 9.3.2  database와 instance, TARGET과 STATE

@CODE
[oracle@rac1 ~]$ srvctl stop instance -d racdb -i racdb2
[oracle@rac1 ~]$ srvctl status database -d racdb -v
Instance racdb1 is running on node rac1. Instance status: Open.
Instance racdb2 is not running on node rac2
[grid@rac1 ~]$ crsctl stat res ora.racdb.db -t
ora.racdb.db
      1        ONLINE  ONLINE       rac1     Open,HOME=/u01/app/oracle/...,STABLE
      2        OFFLINE OFFLINE               Instance Shutdown,STABLE
@END

@B 인스턴스 하나를 내려도 데이터베이스는 열려 있다. `GV$INSTANCE`는 한 행이 된다.
@B TARGET은 Clusterware가 유지하려는 상태, STATE는 실제 상태다. `srvctl stop`은 둘을 함께 OFFLINE으로 만들고, Clusterware는 사람이 의도적으로 내렸다고 보고 다시 올리지 않는다.
@B 이 랩에서 `srvctl stop instance`는 50초 남짓, `srvctl start instance`는 40초 남짓 걸렸다. 정지 쪽에 세션 정리와 체크포인트가 들어간다.

@H3 9.3.3  정상 종료와 비정상 종료

@IMG 09_target.png | 그림 9-3. 종료 방식에 따른 TARGET과 Clusterware의 반응 — 정상 종료면 그대로, 비정상 종료면 다시 올린다

@B rac2에서 SQL*Plus로 `shutdown immediate`를 실행한 뒤 100초 동안 20초 간격으로 관찰했다. TARGET이 OFFLINE으로 바뀌었고 Clusterware는 다시 올리지 않았다. 에이전트가 정상 종료를 감지해 TARGET도 함께 내린 것이다.
@B racdb2의 pmon을 `kill -9`로 죽이자 TARGET은 ONLINE으로 남았다. 20초 시점에 이미 STATE가 STARTING이었고 61초 만에 ONLINE으로 돌아왔다. TARGET과 STATE가 어긋난 것을 장애로 보고 다시 올린 것이다.

@CODE
[ 20초] pmon=1 | 2  ONLINE  OFFLINE  rac2  STARTING
[ 41초] pmon=1 | 2  ONLINE  OFFLINE  rac2  STARTING
[ 61초] pmon=1 | 2  ONLINE  ONLINE   rac2  Open,HOME=/u01/app/oracle/...
[grid@rac1 ~]$ crsctl stat res ora.racdb.db -p | grep -E 'RESTART_ATTEMPTS|UPTIME_THRESHOLD'
RESTART_ATTEMPTS=2
UPTIME_THRESHOLD=1h
@END

@TBL
방식 | TARGET | STATE | Clusterware의 반응
srvctl stop instance | OFFLINE으로 바뀜 | OFFLINE | 다시 올리지 않음
SQL*Plus shutdown immediate | OFFLINE으로 바뀜 | OFFLINE | 다시 올리지 않음 (100초 관찰)
kill -9 pmon | ONLINE 유지 | OFFLINE → STARTING → ONLINE | 61초 만에 다시 올림
@END

@B `RESTART_ATTEMPTS=2`만큼 다시 올려 보고 모두 실패하면 OFFLINE으로 둔다. `UPTIME_THRESHOLD=1h`를 넘겨 정상 동작하면 실패 횟수를 잊는다.

@CASE 재부팅했는데 인스턴스가 올라오지 않았던 사례
점검을 위해 `srvctl stop instance`로 한 인스턴스를 내리고 노드를 재부팅했다. 노드가 올라왔는데 그 인스턴스만 내려가 있었다. Management policy가 AUTOMATIC인데도 그랬다.
srvctl로 내린 인스턴스는 TARGET이 OFFLINE으로 저장되어 재부팅 뒤에도 그대로다. 올릴 때도 `srvctl start instance`로 올려야 TARGET이 ONLINE으로 돌아온다. 점검 절차서에 정지와 기동을 같은 도구로 짝지어 적었다.
@END

@H3 9.3.4  그래도 srvctl을 쓰는 이유

@B 정상 종료라면 SQL*Plus로 내려도 Clusterware가 다시 올리지 않는다. 그래도 운영 작업은 srvctl로 한다.
@B srvctl은 서비스 같은 의존 자원을 순서대로 처리한다. SQL*Plus는 인스턴스 하나만 안다.
@B srvctl은 어느 노드에서든 실행할 수 있다. SQL*Plus는 그 인스턴스가 있는 노드에 접속해야 한다.
@B `-stopconcurrency`, `-drain_timeout`처럼 RAC용 옵션을 쓸 수 있다. 도구별 범위와 crsctl 자원 계층은 11장에서 자세히 다룬다.

@TBL
도구 | 다루는 대상 | 의존 자원 처리 | 원격 실행
srvctl | 데이터베이스·인스턴스·서비스·리스너 | 한다 | 가능
crsctl | Clusterware가 관리하는 모든 자원 | 한다 | 가능
crsctl ... -init | Clusterware 자신을 이루는 데몬(2장) | 해당 없음 | 해당 없음
SQL*Plus | 인스턴스 하나 | 안 한다 | 불가
@END

@H2 9.4  SPFILE의 sid.parameter 표기

@P RAC의 SPFILE에는 파라미터마다 적용 대상이 붙는다. `*`는 모든 인스턴스, 인스턴스 이름은 그 인스턴스에만 적용된다. pfile로 내려받으면 `*.open_cursors=300`, `racdb1.thread=1` 형태로 보인다.

@CODE
SYS@racdb1> select sid, count(*) cnt from v$spparameter where isspecified='TRUE'
  2   group by sid order by 1;
SID              CNT
*                 24
racdb1             3
racdb2             3
SYS@racdb1> select name, sid, value from v$spparameter
  2   where isspecified='TRUE' and sid <> '*' order by name, sid;
instance_number      racdb1   1
instance_number      racdb2   2
thread               racdb1   1
thread               racdb2   2
undo_tablespace      racdb1   UNDOTBS1
undo_tablespace      racdb2   UNDOTBS2
@END

@B 공통 24개, 인스턴스별 3개씩이 이 랩의 기준선이다. 공통 항목 수는 데이터베이스마다 다르고 인스턴스별 3개는 어느 RAC 데이터베이스에서나 같다.
@B 인스턴스별 셋은 모두 달라야만 하는 값이다. DBCA가 생성할 때 자동으로 넣고, 사람은 노드를 추가할 때(15장) 새 인스턴스용 값을 만든다.
@B `instance_name`은 SPFILE에 없는데도 인스턴스마다 다르다. 기동 때 `ORACLE_SID`로 정해지기 때문이다. SPFILE 목록에 없다고 공통인 것은 아니다.
@B 인스턴스별 값이 있으면 `*` 값보다 우선한다.

@H3 9.4.1  세 분류

@IMG 09_params.png | 그림 9-4. 파라미터 세 분류 — 같아야 하는 것 중 일부만 Oracle이 막는다

@TBL
분류 | 예 | 이유
반드시 같아야 | db_name, db_block_size, control_files, cluster_database, compatible | 다르면 같은 데이터베이스로 동작할 수 없다
반드시 달라야 | instance_number, thread, undo_tablespace | 같으면 두 인스턴스가 충돌한다
같은 것이 권장 | sga_target, processes, open_cursors, pga_aggregate_target | 달라도 동작하지만 접속 노드에 따라 동작이 달라진다
@END

@B `GV$PARAMETER`를 INST_ID로 피벗해 두 인스턴스 값을 나란히 보면 분류가 확인된다. `undo_management`는 AUTO로 같고 `undo_tablespace`만 다르다. 방식은 공통이고 대상만 인스턴스별이다.

@H2 9.5  같아야 할 것을 한쪽만 바꾸면

@P 반드시 같아야 하는 파라미터에 `sid='racdb1'`을 붙여 한 인스턴스에만 다른 값을 넣어 본다. Oracle이 막아 주는 것과 막지 않는 것이 갈린다. 모두 `scope=spfile`로만 바꾸므로 지금 돌고 있는 인스턴스에는 영향이 없다.

@H3 9.5.1  막는 경우와 막지 않는 경우

@CODE
SYS@racdb1> alter system set db_block_size=16384 sid='racdb1' scope=spfile;
ORA-32017: failure in updating SPFILE
ORA-32016: parameter "db_block_size" cannot be updated in SPFILE
SYS@racdb1> alter system set cluster_database=false sid='racdb1' scope=spfile;
System altered.
SYS@racdb1> alter system set control_files='+DATA/x' sid='racdb1' scope=spfile;
System altered.
@END

@B `db_block_size`, `db_name`은 생성 때 확정되어 바꿀 수 없는 값이라 인스턴스별 지정 이전에 변경 자체가 ORA-32016으로 막힌다.
@B `cluster_database`와 `control_files`는 같은 분류인데 경고 없이 통과하고, `V$SPPARAMETER`에 racdb1 전용 항목이 생겨 `*` 값과 공존한다.
@B 다음에 racdb1을 기동하면 존재하지 않는 컨트롤 파일 경로 때문에 MOUNT에서 실패한다. 경로를 고쳐도 `cluster_database=FALSE`인 racdb1은 데이터베이스를 배타적으로 열려 하다가 racdb2가 이미 열고 있어 실패한다. Clusterware는 RESTART_ATTEMPTS만큼 다시 시도하다 포기한다.
@B 막지 않는 데는 이유가 있다. `cluster_database=FALSE`는 업그레이드나 일부 복구처럼 한 인스턴스만 단일 모드로 열어야 하는 작업에 쓰이고, `control_files`를 `scope=spfile`로 바꾸는 것은 8장의 컨트롤 파일 이동 절차의 첫 단계다. 명령 자체가 틀린 것이 아니라 지금 상황에서 틀린 것이고, 도구는 상황을 모른다.

@H3 9.5.2  RESET으로 되돌리기

@CODE
SYS@racdb1> alter system reset cluster_database sid='racdb1' scope=spfile;
SYS@racdb1> alter system reset control_files sid='racdb1' scope=spfile;
SYS@racdb1> select sid, count(*) cnt from v$spparameter where isspecified='TRUE'
  2   group by sid order by 1;    -- * 24 / racdb1 3 / racdb2 3
@END

@B RESET은 값을 원래대로 쓰는 것이 아니라 그 항목을 SPFILE에서 지운다. 그러면 상위인 `*` 값이 다시 적용된다.
@B 24 / 3 / 3으로 돌아왔는지 세면 SPFILE이 깨끗한지 한 번에 확인된다.
@B 같은 것이 권장되는 `open_cursors`를 `sid='racdb1'`로 350으로 바꾸면 정상적으로 들어간다. 하드웨어가 다른 노드처럼 의도가 있을 때 쓰는 용법이지만, 접속 노드나 페일오버 뒤 세션 위치에 따라 동작이 달라지므로 기본은 같게 둔다. 실습 뒤에는 RESET한다.

@NOTE scope 고르기
`scope=memory`는 지금 인스턴스에만 적용되고 재기동하면 사라진다. `scope=spfile`은 SPFILE만 바꾸고 다음 기동에 반영된다. `scope=both`는 둘 다이며 기본값이다. 잘못된 값이 즉시 반영되면 실습 도중 클러스터가 무너지므로 이 장의 실습은 모두 `scope=spfile`이다. scope=spfile로 넣은 값은 재기동 순간 처음 적용되므로 재기동 직전이 마지막 확인 기회다.
@END

@H2 9.6  PDB를 노드별로 열고 닫기

@P PDB의 열림 상태는 인스턴스마다 따로 관리된다. 데이터 파일은 하나인데 그것을 여는 상태가 인스턴스마다 다를 수 있다. 단일 인스턴스에는 없는 개념이다.

@IMG 09_pdb.png | 그림 9-5. PDB 열림 상태는 인스턴스별 — 한 노드에서만 닫히면 그 노드로 붙은 세션만 실패한다

@CODE
SYS@racdb1> alter pluggable database racpdb1 close;
SYS@racdb1> select inst_id, name, open_mode from gv$pdbs where name='RACPDB1' order by 1;
   INST_ID NAME         OPEN_MODE
         1 RACPDB1      MOUNTED
         2 RACPDB1      READ WRITE
@END

@B 인스턴스 지정 없이 CLOSE하면 실행한 인스턴스에서만 닫힌다.
@B 닫힌 노드에서 `alter session set container=racpdb1`은 성공하지만 테이블 조회는 ORA-01219(queries allowed on fixed tables or views only), DML은 ORA-01109(database not open)가 난다. 같은 SQL이 열린 노드에서는 정상이다.
@B MOUNTED에서도 고정 뷰는 조회되므로 `GV$PDBS`로 상태를 확인할 수 있다.
@B `alter pluggable database racpdb1 open instances=all`로 한 노드에서 한 번 실행해 두 노드를 연다. 특정 인스턴스만 열려면 `instances=('racdb1')`처럼 쓴다.

@CASE 어제는 됐는데 오늘은 안 된다는 문의
사용자는 SCAN으로 접속하므로 어느 노드에 붙을지 모른다. 한 노드에서만 PDB가 닫혀 있으면 접속이 그 노드로 갈 때만 실패하고, 재시도하면 다른 노드로 붙어 성공하기도 한다. 증상이 간헐적이라 진단이 늦어졌다.
`GV$PDBS`에서 INST_ID별 OPEN_MODE가 다른 것을 보고 원인이 확정되었다. 전날 한 노드에서 점검하며 닫은 PDB를 다시 열 때 `INSTANCES=ALL`을 빼먹은 것이었다. 일상 점검에 이 조회를 넣었다.
@END

@BP PDB를 의도적으로 한 노드에서만 여는 경우
무거운 배치를 특정 PDB에 돌릴 때 그 PDB를 한 노드에서만 열어 두면 부하가 그 노드에 갇힌다. 한 노드에서 PDB를 닫고 유지보수하는 동안 다른 노드가 서비스를 이어 갈 수도 있다. 어느 쪽이든 의도와 기록이 있어야 한다. 접속을 노드에 묶는 정식 방법은 12장의 서비스다.
@END

@H2 9.7  운영 지침

@TBL
상황 | 도구 | 이유
계획된 인스턴스 정지 | srvctl stop instance | Clusterware가 의도를 알고, 의존 자원을 처리한다
계획된 DB 전체 정지 | srvctl stop database | 서비스와 의존 자원까지 순서대로
자원이 빠듯한 환경 | srvctl ... -stopconcurrency 1 | 순차 처리로 부하 급등을 피한다
클러스터 전체 정지 | crsctl stop crs (root, 노드마다) | DB를 포함한 모든 자원을 내린다
단일 인스턴스 모드 작업 | SQL*Plus startup | Clusterware를 우회해 특정 상태로 연다
@END

@TBL
주기 | 확인 항목 | 명령
매일 | 두 인스턴스 기동 상태 | srvctl status database -d racdb -v
매일 | PDB의 노드별 열림 상태 | GV$PDBS의 INST_ID별 OPEN_MODE
주간 | SPFILE 인스턴스별 항목 수 | V$SPPARAMETER를 sid로 group by (24 / 3 / 3)
주간 | TARGET·STATE 불일치 자원 | crsctl stat res -t
변경 후 | 파라미터 두 노드 대조 | GV$PARAMETER를 name으로 피벗
@END

@B `sid=`를 붙이기 전에 그 파라미터가 세 분류 중 어디에 속하는지 확인한다. Oracle이 막아 주는 것은 일부뿐이다.
@B 되돌릴 때는 값을 다시 쓰지 않고 RESET으로 항목을 지운다.
@B 정지와 기동은 같은 도구로 짝지어 한다. srvctl로 내린 인스턴스는 srvctl로 올린다.

@H2 9.8  요약

@B `srvctl config database`는 Clusterware에 저장된 DB 정의다. 인스턴스·노드 배치, SPFILE 위치, 기본 기동·정지 옵션, Management policy, 디스크그룹 의존성을 보여 준다.
@B RAC 데이터베이스는 인스턴스마다 instance_number, 리두 스레드, UNDO 테이블스페이스를 따로 가진다. SPFILE에는 이 셋이 인스턴스별로 들어 있다.
@B PDB 열림 상태와 저장 상태는 인스턴스별이다. 열 때와 SAVE STATE 할 때 모두 `INSTANCES=ALL`을 붙인다.
@B Clusterware는 도구가 아니라 종료 방식을 본다. 정상 종료는 TARGET이 OFFLINE이 되어 그대로 두고, 비정상 종료는 TARGET이 ONLINE으로 남아 RESTART_ATTEMPTS만큼 다시 올린다.
@B 파라미터는 같아야 하는 것, 달라야 하는 것, 같은 것이 권장되는 것으로 나뉜다. `cluster_database`·`control_files`의 인스턴스별 지정은 경고 없이 통과하므로 사람이 막아야 한다.
@B 인스턴스별 값은 `ALTER SYSTEM RESET ... SID=`로 지운다. 이 랩의 기준선은 24 / 3 / 3이다.

@H2 9.9  퀴즈

@QUIZ 퀴즈
1. `srvctl config database -d racdb`에서 `srvctl stop database`의 기본 종료 방식을 알 수 있는 줄은? 그 값은?
2. 생성 직후의 RAC 데이터베이스가 제대로 만들어졌는지 확인할 항목 다섯 가지를 쓰시오.
3. DBCA로 만든 CDB를 재기동했더니 PDB가 두 노드 모두 MOUNTED로 남았다. 원인과 예방 명령은?
4. SQL*Plus로 shutdown immediate한 인스턴스와 pmon을 kill한 인스턴스에 Clusterware가 다르게 반응하는 이유를 TARGET으로 설명하시오.
5. `db_name`은 ORA-32016으로 막히는데 `cluster_database=false sid='racdb1'`은 통과한다. 이유와 위험은?
6. 인스턴스별로 잘못 넣은 값을 되돌릴 때 값을 다시 쓰지 않고 RESET을 쓰는 이유는?
@END

@NOTE 정답과 해설
1. Stop options 줄. immediate이므로 shutdown immediate가 수행된다.
2. Clusterware 자원이 두 노드 ONLINE, 인스턴스가 노드 수만큼 서로 다른 노드에, THREAD#가 인스턴스마다 다름, UNDO 테이블스페이스가 인스턴스 수만큼, SPFILE 인스턴스별 3항목, PDB 두 노드 READ WRITE와 저장 상태(그리고 재기동 시험).
3. DBCA는 PDB를 열기만 하고 상태를 저장하지 않는다. ALTER PLUGGABLE DATABASE ... OPEN INSTANCES=ALL 뒤 SAVE STATE INSTANCES=ALL.
4. 정상 종료는 에이전트가 감지해 TARGET을 OFFLINE으로 바꾸므로 TARGET과 STATE가 일치해 할 일이 없다. kill은 TARGET이 ONLINE으로 남아 STATE와 어긋나므로 장애로 보고 다시 올린다.
5. cluster_database=false는 단일 인스턴스 모드 작업이라는 정당한 용도가 있어 막지 않는다. 그대로 재기동하면 racdb1이 배타적으로 열려다 실패하고 Clusterware가 재시도 후 포기한다.
6. RESET은 인스턴스별 항목 자체를 SPFILE에서 지워 * 값이 다시 적용되게 한다. 값을 다시 쓰면 인스턴스별 항목이 남아 이후 * 값을 바꿔도 그 인스턴스에는 반영되지 않는다.
@END

@H2 9.10  실습 개요

@P 실습 중 인스턴스를 내렸다 올린다. 한 번에 40~110초가 걸리므로 시간을 넉넉히 잡고, 시작 전 두 인스턴스가 Open이고 부하가 높지 않은지 확인한다.

@TBL
실습 | 파일 | 목적
11-05 | RAC/11장/11장_실습_05_생성결과검증.txt | 생성된 RAC DB를 여섯 기준(자원·인스턴스·스레드·리두·UNDO·SPFILE)으로 검증한다
11-06 | RAC/11장/11장_실습_06_PDB양노드확인.txt | DBCA가 PDB에 하는 일과 하지 않는 일, 재기동 후 MOUNTED 함정과 SAVE STATE를 확인한다
12-01 ★ | RAC/12장/12장_실습_01_srvctl기동정지.txt | srvctl config를 읽고 인스턴스 하나를 내렸다 올리며 TARGET 변화를 본다
12-03 ★ | RAC/12장/12장_실습_03_정상종료와비정상종료.txt | shutdown immediate와 kill -9 pmon에 대한 Clusterware 반응 차이를 관찰한다
12-04 | RAC/12장/12장_실습_04_SPFILE표기.txt | V$SPPARAMETER로 * 와 인스턴스별 항목을 세고 기준선을 확인한다
12-05 ★ | RAC/12장/12장_실습_05_파라미터세분류.txt | GV$PARAMETER로 두 인스턴스 값을 대조해 세 분류를 확인한다
12-06 | RAC/12장/12장_실습_06_오류재현_파라미터.txt | ORA-32016과 경고 없이 통과하는 인스턴스별 지정을 재현하고 RESET으로 되돌린다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다.
@B 11장 실습 05·06의 기록은 DBCA로 만든 testdb(testdb1·testdb2, TESTPDB)에서 진행한 것이다. 이 과정에서는 DB 생성을 하지 않으므로 같은 조회를 racdb에 대해 실행하고(ORACLE_SID=racdb1), 기록의 testdb 결과와 비교해 읽는다. racdb는 이미 SAVE STATE가 되어 있어 재기동해도 RACPDB1이 열린다.
@B 실습 12-06은 SPFILE을 실제로 수정한다. 마지막 RESET 단계를 건너뛰면 다음 재기동에서 racdb1이 기동하지 않으므로 24 / 3 / 3 복귀를 반드시 확인한다.
@B 수료 후 자습: 12장_실습_02_crsctl자원계층, 12장_실습_07_PDB노드별제어.
