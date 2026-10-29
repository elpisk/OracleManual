@H1 제8장  ASM 마이그레이션 — RMAN 활용

@H2 8.1  학습 목표

@P 실습 DB racdb는 설치 때 DBCA가 처음부터 +DATA에 만들었다(설치 가이드 v2의 9장). 현장에서는 파일 시스템에서 운영하던 데이터베이스를 ASM으로 옮기는 일이 더 흔하고, 단일 인스턴스를 RAC로 바꿀 때는 반드시 거쳐야 한다. 공유 스토리지에 있지 않은 파일은 다른 노드가 열 수 없기 때문이다. 이 장은 RMAN의 `BACKUP AS COPY`와 `SWITCH ... TO COPY` 두 명령으로 데이터 파일을 옮기고, 그 과정에서 만나는 오류가 각각 무엇을 요구하는지 정리한다.

@B 로컬 파일 시스템의 데이터 파일이 다른 노드에서 ORA-01157을 내는 이유와 그것을 찾는 조회를 설명할 수 있다.
@B 마이그레이션 전에 확인할 파일 위치, 필요 공간, 아카이브 모드를 점검할 수 있다.
@B `BACKUP AS COPY`와 `SWITCH ... TO COPY`로 데이터 파일을 ASM으로 옮길 수 있다.
@B ORA-19602, RMAN-06572, ORA-01113이 각각 요구하는 조건을 구분하고 SCN 관점에서 복구가 필요한 이유를 설명할 수 있다.
@B 컨트롤 파일과 SPFILE의 이동 절차가 데이터 파일과 다른 이유, `srvctl modify database -spfile`이 필요한 이유를 말할 수 있다.
@B 옮긴 뒤 남은 사본을 RMAN으로 정리할 수 있다.

@H2 8.2  마이그레이션 전 점검

@P 옮기기 전에 무엇이 어디 있는지, 옮기는 동안 공간이 얼마나 필요한지, 데이터베이스가 어떤 로그 모드인지를 확인한다. 셋째 항목이 이후 절차 전체를 정한다.

@H3 8.2.1  파일 위치 지도

@CODE
SYS@racdb1> select 'DATAFILE' kind, file#, name from v$datafile
  2  union all select 'TEMPFILE', file#, name from v$tempfile
  3  union all select 'CONTROLFILE', 0, name from v$controlfile
  4  order by 1, 2;
SYS@racdb1> select l.group#, l.thread#, l.status, f.member
  2    from v$log l join v$logfile f on l.group#=f.group# order by 1,4;
@END

@B 이 랩은 데이터 파일 13개, 템프 파일 3개, 컨트롤 파일 2개가 모두 ASM에 있다. 옮길 것이 없으므로 실습에서는 로컬 파일 시스템에 데이터 파일을 하나 만들어 놓고 옮긴다.
@B 리두 그룹 1·2는 `THREAD#` 1(racdb1), 3·4는 `THREAD#` 2(racdb2)이고, 각 그룹의 멤버가 +DATA와 +FRA에 하나씩 있다. 인스턴스마다 자기 리두 스레드를 가지는 RAC 구조가 여기서 보인다.
@B SPFILE 위치는 `show parameter spfile`과 `srvctl config database -d racdb`의 `Spfile:` 줄 두 곳에서 같은 값으로 나온다. 앞은 지금 돌고 있는 인스턴스가 읽은 파일이고, 뒤는 Clusterware가 다음 기동 때 쓸 값이다(8.6절).

@H3 8.2.2  필요 공간

@B 대상 크기는 `V$DATAFILE`·`V$TEMPFILE`·`V$LOG`의 BYTES 합으로 잰다. 이 랩은 데이터 파일 3455MB, 템프 108MB, 리두 800MB였다.
@B `BACKUP AS COPY`는 원본을 둔 채 사본을 만든다. 옮기는 동안 두 벌이 함께 존재하므로 대상 디스크그룹에 원본 크기만큼의 여유가 있어야 한다.
@B Normal 이중화 디스크그룹이면 원시 공간은 두 배가 든다. 판단 기준은 `FREE_MB`가 아니라 `USABLE_FILE_MB`다(7장). 메타데이터와 여유를 감안해 옮길 양의 1.2배쯤을 잡는다.
@B 테이블스페이스 단위로 나눠 옮기고 원본을 지운 뒤 다음을 옮기면 필요한 여유가 줄지만, 원본을 지우는 순간 되돌릴 곳이 없어진다.

@H3 8.2.3  아카이브 모드 — 절차를 가르는 갈림길

@CODE
SYS@racdb1> select log_mode, name, open_mode from v$database;
LOG_MODE     NAME      OPEN_MODE
------------ --------- --------------------
NOARCHIVELOG RACDB     READ WRITE
@END

@B ARCHIVELOG 모드라면 데이터베이스를 연 채 온라인 데이터 파일을 복사할 수 있다. 복사 중의 변경은 리두로 맞춘다.
@B NOARCHIVELOG에서는 복사본이 어느 시점의 것인지 맞출 방법이 없어 대상 파일을 OFFLINE으로 내려야 복사할 수 있다.
@B 이 랩의 racdb는 NOARCHIVELOG다. 이 장의 실습이 모두 OFFLINE을 거치는 이유다. 아카이브 모드 전환은 14장에서 다룬다.

@H2 8.3  공유되지 않은 파일 — ORA-01157

@P 마이그레이션이 왜 필요한지부터 확인한다. rac1의 로컬 디렉터리에 데이터 파일을 만들면 rac1에서는 아무 문제가 없다.

@IMG 08_shared.png | 그림 8-1. 로컬 파일 시스템의 데이터 파일. 컨트롤 파일에는 등록되어 있지만 rac2에는 그 경로가 없다

@CODE
[root@rac1 ~]# mkdir -p /u01/app/oracle/oradata
[root@rac1 ~]# chown oracle:oinstall /u01/app/oracle/oradata
SYS@racdb1> create tablespace ts_mig
  2    datafile '/u01/app/oracle/oradata/ts_mig01.dbf' size 100M autoextend off;
SYS@racdb1> create table sys.mig_t (a number, b varchar2(100)) tablespace ts_mig;
SYS@racdb1> insert into sys.mig_t select level, lpad('m',100,'m')
  2    from dual connect by level<=20000;
SYS@racdb1> commit;
@END

@B 새 파일은 FILE# 23을 받았다. rac1에서는 테이블을 만들고 2만 행을 넣고 읽는 데 문제가 없다.
@B rac2에서 같은 테이블을 읽으면 ORA-01157(cannot identify/lock data file 23)과 ORA-01110이 난다.
@B 그런데 rac2의 `V$DATAFILE`은 파일 23을 ONLINE으로 보여 주고 `V$RECOVER_FILE`은 비어 있다. 딕셔너리와 컨트롤 파일 관점에서는 이상이 없다.
@B 원인은 OS 계층에 있다. rac2에서 `ls -l /u01/app/oracle/oradata/`를 하면 디렉터리 자체가 없다. rac1의 로컬 디스크에 만든 파일이기 때문이다.

@CODE
SYS@racdb1> select name from v$datafile where name not like '+%';
@END

@CASE 두 번째 노드에서만 특정 스키마가 실패한 사례
단일 인스턴스를 RAC로 전환하면서 데이터 파일 대부분을 공유 스토리지로 옮겼다. 전환 시험은 첫 노드에서 모두 통과했다. 운영을 시작한 뒤 두 번째 노드로 연결된 세션만 특정 스키마를 조회할 때 ORA-01157이 났다.
나중에 추가한 테이블스페이스 하나가 첫 노드의 로컬 경로에 남아 있었다. `+`로 시작하지 않는 데이터 파일을 찾는 위 조회 한 줄을 전환 점검표에 넣고, 모든 확인을 두 번째 노드에서도 하도록 절차를 바꿨다.
@END

@H2 8.4  데이터 파일을 ASM으로 — 복사와 전환

@P 이동은 두 단계다. `BACKUP AS COPY`로 대상 디스크그룹에 사본을 만들고, `SWITCH ... TO COPY`로 컨트롤 파일이 가리키는 경로를 사본으로 바꾼다. 시간이 드는 것은 앞 단계뿐이다.

@IMG 08_flow.png | 그림 8-2. 데이터 파일 이동 순서 — NOARCHIVELOG에서는 복사부터 전환까지 OFFLINE을 유지한다

@H3 8.4.1  첫 오류 ORA-19602

@CODE
[oracle@rac1 ~]$ rman target /
RMAN> backup as copy datafile 23 format '+DATA';
...
RMAN-03009: failure of backup command on ORA_DISK_1 channel at 09/03/2026 19:32:53
ORA-19602: cannot backup or copy active file in NOARCHIVELOG mode
@END

@B 메시지가 원인을 그대로 말한다. NOARCHIVELOG 모드에서는 활성(ONLINE) 파일을 복사할 수 없다.
@B 선택지는 둘이다. 데이터베이스를 ARCHIVELOG로 바꾸면 온라인 복사가 되지만 모드 전환에 재기동이 필요하다. 대상 테이블스페이스만 OFFLINE으로 내리면 그 테이블스페이스만 잠시 못 쓴다. 실습은 뒤의 방법을 쓴다.

@H3 8.4.2  OFFLINE 후 복사

@CODE
SYS@racdb1> alter tablespace ts_mig offline;
RMAN> backup as copy datafile 23 format '+DATA';
input datafile file number=00023 name=/u01/app/oracle/oradata/ts_mig01.dbf
output file name=+DATA/RACDB/DATAFILE/ts_mig.279.1243020779
...
Starting Control File and SPFILE Autobackup at 03-SEP-26
@END

@B 100MB 복사가 7초 남짓 걸렸다. 출력 파일 이름은 ASM이 OMF 규칙으로 지었다. `ts_mig.279.1243020779`에서 279가 파일 번호, 뒤가 인카네이션 번호다(5장).
@B 컨트롤 파일과 SPFILE 자동 백업이 함께 실행되어 +FRA에 조각이 생긴다. 구조를 바꾸는 작업 뒤에 RMAN이 하는 동작이다.
@B `list copy of datafile 23`으로 사본과 그 체크포인트 SCN(Ckp SCN)을 확인한다. 이 SCN이 사본이 어느 시점의 것인지를 말한다.

@H3 8.4.3  SWITCH와 ONLINE

@CODE
RMAN> switch datafile 23 to copy;
datafile 23 switched to datafile copy "+DATA/RACDB/DATAFILE/ts_mig.279.1243020779"
SYS@racdb1> alter tablespace ts_mig online;
SYS@racdb1> select count(*) from sys.mig_t;
@END

@B SWITCH는 2초 남짓에 끝났다. 파일을 옮기지 않고 컨트롤 파일에 적힌 경로만 바꾸므로 100MB든 1TB든 걸리는 시간이 같다.
@B 복사부터 SWITCH까지 OFFLINE을 유지했으므로 사본 이후 바뀐 것이 없어 복구 없이 바로 ONLINE이 되었다.
@B rac2에서 같은 조회를 하면 이번에는 20000이 나온다. rac2에서는 아무것도 하지 않았다. 파일이 공유 스토리지로 옮겨진 것만으로 두 번째 노드가 정상이 되었다.

@BP 원본은 자동으로 지워지지 않는다
SWITCH 뒤에도 `/u01/app/oracle/oradata/ts_mig01.dbf`는 그대로 남는다. 문제가 생기면 반대로 SWITCH해 되돌릴 수 있게 남겨 두는 것이다. 검증이 끝나면 OS 명령이 아니라 RMAN의 `DELETE COPY`로 지운다. RMAN 저장소의 기록도 함께 정리된다.
@END

@H3 8.4.4  파일 하나에서 데이터베이스 전체로

@P 실습은 데이터 파일 하나를 옮기지만 같은 명령은 테이블스페이스나 데이터베이스 단위로도 쓴다. 단위가 커져도 순서와 요구 조건은 같다.

@TBL
단위 | 복사 | 전환 | 필요한 상태
데이터 파일 | BACKUP AS COPY DATAFILE n FORMAT '+DATA' | SWITCH DATAFILE n TO COPY | 파일 OFFLINE (DB OPEN 상태)
테이블스페이스 | BACKUP AS COPY TABLESPACE ts FORMAT '+DATA' | SWITCH TABLESPACE ts TO COPY | 테이블스페이스 OFFLINE
데이터베이스 전체 | BACKUP AS COPY DATABASE FORMAT '+DATA' | SWITCH DATABASE TO COPY | MOUNT 상태 (모든 인스턴스 정지 후 한 인스턴스만)
@END

@B 데이터베이스 전체를 옮길 때는 SYSTEM·UNDO처럼 OFFLINE할 수 없는 파일이 포함되므로 데이터베이스를 MOUNT 상태로 두고 SWITCH한다. RAC에서는 `srvctl stop database` 뒤 한 인스턴스만 MOUNT로 올려 작업하고, 끝나면 `srvctl start database`로 두 인스턴스를 연다.
@B 템프 파일은 RMAN 복사 대상이 아니다. 새 위치에 템프 파일을 추가하고 옛 것을 지운다. 온라인 리두는 새 위치에 멤버나 그룹을 추가하고 옛 것을 지우는 방식으로 옮긴다. 리두는 스레드마다 있으므로 두 인스턴스의 그룹을 모두 챙긴다.
@B 12c부터는 `ALTER DATABASE MOVE DATAFILE`로 데이터 파일을 연 채 옮기는 방법도 있다. 이 과정의 실습 기록에는 없는 방법이므로 여기서는 이름만 소개한다. 대량 이동이나 단일 인스턴스의 RAC 전환처럼 데이터베이스 단위 작업은 RMAN 방식이 표준이다.

@NOTE 전환 작업에서 RMAN 채널의 위치
RMAN은 접속한 인스턴스의 채널로 복사한다. 이 랩의 출력에도 `channel ORA_DISK_1: SID=151 instance=racdb1`처럼 어느 인스턴스에서 작업하는지가 찍힌다. 대상이 공유 디스크그룹이면 어느 노드에서 복사해도 결과는 같다. 원본이 한 노드의 로컬 디스크에 있다면 그 노드의 인스턴스에 접속해 복사해야 원본을 읽을 수 있다.
@END

@H2 8.5  순서를 어기면 — RMAN-06572와 ORA-01113

@P 같은 파일을 +DATA에서 +FRA로 한 번 더 옮긴다. ASM에서 ASM으로의 이동도 절차가 같다. 이번에는 사본을 만든 뒤 SWITCH 전에 테이블스페이스를 먼저 ONLINE으로 올리는 실수를 해 본다.

@H3 8.5.1  ONLINE 상태에서 SWITCH

@CODE
SYS@racdb1> alter tablespace ts_mig offline;
RMAN> backup as copy datafile 23 format '+FRA';
SYS@racdb1> alter tablespace ts_mig online;
RMAN> switch datafile 23 to copy;
RMAN-03002: failure of switch to copy command at 09/03/2026 19:34:01
RMAN-06572: database is open and datafile 23 is not offline
@END

@B 데이터베이스가 열려 있으면 SWITCH 대상 파일은 OFFLINE이어야 한다. 이 요구는 아카이브 모드와 상관없다. 누군가 쓰고 있는 파일의 정체를 통째로 바꿀 수는 없기 때문이다.

@TBL
단계 | 명령 | 요구 조건 | 아카이브 모드와의 관계
복사 | BACKUP AS COPY | NOARCHIVELOG면 파일 OFFLINE | ARCHIVELOG면 ONLINE 복사 가능
전환 | SWITCH ... TO COPY | DB가 OPEN이면 파일 OFFLINE | 모드와 무관
@END

@H3 8.5.2  SWITCH는 됐는데 ONLINE이 안 된다

@IMG 08_scn.png | 그림 8-3. 사본이 뒤처진 상태 — 사본의 체크포인트 SCN과 데이터베이스 현재 SCN의 차이를 리두로 메운다

@CODE
SYS@racdb1> alter tablespace ts_mig offline;
RMAN> switch datafile 23 to copy;
SYS@racdb1> alter tablespace ts_mig online;
ORA-01113: file 23 needs media recovery
ORA-01110: data file 23: '+FRA/RACDB/DATAFILE/ts_mig.262.1243020835'
SYS@racdb1> select file#, checkpoint_change# from v$datafile where file#=23;   -- 3993926
SYS@racdb1> select current_scn from v$database;                               -- 3994002
@END

@B 사본의 체크포인트 SCN은 3993926인데 데이터베이스 현재 SCN은 3994002다. 사본을 만든 뒤 테이블스페이스를 ONLINE으로 올린 동안 데이터베이스가 앞으로 나아갔고, 사본은 그 이전 시점에 머물러 있다.
@B 이 상태에서 테이블을 조회하면 ORA-00376(file 23 cannot be read at this time)이 난다.
@B `RMAN> recover datafile 23;`으로 벌어진 만큼 리두를 적용한 뒤 ONLINE하면 20000행이 그대로 보인다. rac2에서도 정상이다. +DATA와 +FRA 모두 공유 디스크그룹이라 디스크그룹이 바뀌어도 RAC 관점에서는 차이가 없다.

@NOTE NOARCHIVELOG에서 이 복구가 된 이유
아카이브 로그가 없는데도 미디어 복구가 성공한 것은 필요한 리두가 아직 온라인 리두 로그에 남아 있었기 때문이다. 그 사이 로그 스위치가 여러 번 일어나 필요한 리두가 덮어써졌다면 복구는 실패하고 그 파일은 되살릴 수 없다. NOARCHIVELOG에서는 복사부터 SWITCH까지 OFFLINE을 유지해 SCN이 벌어지는 상황 자체를 만들지 않는다.
@END

@BP 중단 시간을 줄이려면 ARCHIVELOG에서 옮긴다
ARCHIVELOG 모드에서는 복사를 온라인으로 끝내 두고 SWITCH 직전에만 OFFLINE한 뒤 `RECOVER DATAFILE`로 차이를 메우고 ONLINE한다. 복사가 몇 시간이 걸려도 업무 중단은 SWITCH와 복구에 드는 짧은 시간뿐이다. 복사 시간이 허용 가능한 중단 시간보다 길면 마이그레이션 전에 아카이브 모드 전환을 검토한다.
@END

@H2 8.6  컨트롤 파일과 SPFILE

@P 데이터 파일은 RMAN으로 복사하고 SWITCH하면 끝난다. 컨트롤 파일과 SPFILE은 위치 정보가 저장된 곳이 달라 같은 방법을 쓸 수 없다.

@IMG 08_spfile.png | 그림 8-4. 위치 정보가 기록된 곳 — control_files는 SPFILE에, SPFILE 위치는 인스턴스와 Clusterware 자원 두 곳에 있다

@H3 8.6.1  control_files는 실행 중에 바꿀 수 없다

@CODE
SYS@racdb1> alter system set
  2    control_files='+DATA/RACDB/CONTROLFILE/current.261.1242761745' scope=memory;
ORA-02095: specified initialization parameter cannot be modified
SYS@racdb1> select name, issys_modifiable from v$parameter
  2   where name in ('control_files','spfile','db_create_file_dest');
@END

@B `control_files`의 `ISSYS_MODIFIABLE`은 FALSE다. 인스턴스가 살아 있는 동안에는 어떤 방법으로도 바꿀 수 없고, SPFILE에 새 값을 써 두고 재기동해야 반영된다. `spfile`, `db_create_file_dest`는 IMMEDIATE다.
@B 컨트롤 파일 이동 순서는 SPFILE에 새 위치 기록(scope=spfile) → 데이터베이스 정지 후 NOMOUNT로 기동 → RMAN `RESTORE CONTROLFILE ... FROM` 기존 사본 → MOUNT 후 OPEN이다.
@B RAC에서는 모든 인스턴스가 같은 컨트롤 파일을 봐야 하므로 이 작업 동안 데이터베이스 전체를 내린다. 노드별 롤링으로 할 수 없다.
@B 이 랩의 컨트롤 파일은 +DATA와 +FRA에 이미 두 벌이다. 위치를 바꿔야 한다면 새 위치에 사본을 하나 더한 뒤 안정되면 옛 것을 빼는 방식이 사본이 하나뿐인 순간을 만들지 않는다.

@H3 8.6.2  SPFILE 위치는 두 곳에 기록된다

@CODE
SYS@racdb1> show parameter spfile
spfile     string   +DATA/RACDB/PARAMETERFILE/spfile.272.1242762487
[oracle@rac1 ~]$ srvctl config database -d racdb | grep -i spfile
Spfile: +DATA/RACDB/PARAMETERFILE/spfile.272.1242762487
@END

@B 인스턴스를 띄우는 주체가 Clusterware이기 때문에 생긴 구조다. 단일 인스턴스에는 이런 이중 기록이 없다.
@B SPFILE 이동 순서는 `CREATE PFILE='/tmp/pf_ch10.ora' FROM SPFILE` → `CREATE SPFILE='+FRA/...' FROM PFILE=...` → `srvctl modify database -d racdb -spfile '+FRA/...'` → 재기동이다.
@CODE
SYS@racdb1> create pfile='/tmp/pf_ch10.ora' from spfile;
[oracle@rac1 ~]$ grep -i 'control_files\|db_create' /tmp/pf_ch10.ora
*.control_files='+DATA/RACDB/CONTROLFILE/current.261.1242761745',
                '+FRA/RACDB/CONTROLFILE/current.256.1242761745'
*.db_create_file_dest='+DATA'
@END

@B 실습 파일에서 만든 pfile은 55줄짜리 텍스트로, `*.control_files`와 `*.db_create_file_dest='+DATA'` 같은 항목이 들어 있다. `*.`과 `racdb1.` 접두어의 뜻은 9장에서 다룬다.

@CASE 새 SPFILE이 반영되지 않았던 사례
SPFILE을 +FRA로 옮기고 파라미터를 고친 뒤 재기동했는데 변경이 반영되지 않았다. `show parameter spfile`에는 옛 경로가 나왔다. 셋째 단계 `srvctl modify database -spfile`을 빠뜨려 Clusterware가 옛 SPFILE로 인스턴스를 띄운 것이었다.
반대로 srvctl은 고쳤는데 그 경로에 파일을 만들지 않으면 인스턴스가 아예 기동하지 않는다. 파일을 먼저 만들고, srvctl을 고치고, `srvctl config database`로 값을 눈으로 확인한 뒤 재기동하는 순서로 두 실수를 모두 막는다.
@END

@H2 8.7  되돌리기와 정리

@P 역방향도 명령은 같다. `FORMAT`에 디스크그룹 대신 파일 시스템 경로를 주면 된다. 다만 RAC에서는 결과가 다르다.

@IMG 08_where.png | 그림 8-5. 데이터 파일 위치별 rac2의 결과. 디스크그룹이 무엇이냐보다 공유냐 아니냐가 갈린다

@CODE
RMAN> backup as copy datafile 23 format '/u01/app/oracle/oradata/ts_mig_back.dbf';
RMAN> switch datafile 23 to copy;
RMAN> recover datafile 23;
SYS@racdb1> alter tablespace ts_mig online;
@END

@B OFFLINE을 유지한 채 진행해 SCN이 벌어지지 않았고 복구는 0초에 끝났다. 대상이 파일 시스템이라 이름은 사람이 정한다.
@B rac1에서는 2만 행이 보이지만 rac2에서는 8.3절과 같은 ORA-01157이 다시 난다. RAC에서 로컬 파일 시스템으로 되돌리는 것은 절차상 가능하지만 실질적인 선택지가 아니다. NFS나 ACFS 같은 공유 파일 시스템이면 이 제약이 없다.

@TBL
데이터 파일 위치 | rac1 | rac2 | RAC에서 사용
로컬 파일 시스템 | 정상 (20000행) | ORA-01157 | 불가
+DATA | 정상 | 정상 | 가능
+FRA | 정상 | 정상 | 가능
로컬 파일 시스템 (되돌림) | 정상 | ORA-01157 | 불가
@END

@H3 8.7.1  사본 정리

@CODE
SYS@racdb1> drop table sys.mig_t purge;
SYS@racdb1> drop tablespace ts_mig including contents and datafiles;
RMAN> crosscheck copy;
RMAN> delete noprompt copy;
RMAN> delete noprompt backup device type disk;
SYS@racdb1> select name from v$datafile where name not like '+DATA%';
@END

@B `DROP TABLESPACE`가 지운 것은 현재 쓰던 파일 하나뿐이다. +DATA 사본, +FRA 사본, 처음의 로컬 파일은 RMAN 저장소에만 남아 있어 `DELETE COPY`로 지운다.
@B SWITCH 때마다 생긴 컨트롤 파일 자동 백업 조각도 지운다. 이 랩의 다른 백업이 없다는 전제의 명령이므로 운영 DB에서는 대상을 좁혀서 지운다.
@B 끝나면 데이터 파일 13개가 모두 +DATA에 있고 마지막 조회가 0행이어야 한다.

@H2 8.8  운영 지침

@TBL
순서 | 확인·작업 | 근거
1 | + 로 시작하지 않는 데이터 파일 목록 | 옮길 대상 확정
2 | 아카이브 모드 | 복사 단계의 OFFLINE 필요 여부
3 | 대상 디스크그룹의 USABLE_FILE_MB | 원본과 사본이 함께 존재
4 | 테이블스페이스 OFFLINE (NOARCHIVELOG) | ORA-19602 회피
5 | BACKUP AS COPY ... FORMAT '+DG' | 시간이 드는 유일한 단계
6 | SWITCH ... TO COPY (파일 OFFLINE 상태) | RMAN-06572 회피, 크기와 무관하게 수 초
7 | 필요하면 RECOVER DATAFILE | ORA-01113, SCN 차이
8 | ONLINE 후 다른 노드에서 조회 | RAC에서 확인할 것은 두 번째 노드
9 | DELETE COPY로 옛 사본 정리 | SWITCH는 원본을 지우지 않는다
@END

@TBL
오류 | 언제 | 요구하는 것
ORA-19602 | NOARCHIVELOG에서 ONLINE 파일 복사 | 파일 OFFLINE
RMAN-06572 | DB OPEN 상태에서 ONLINE 파일 SWITCH | 파일 OFFLINE
ORA-01113 | 사본 시점보다 DB가 앞선 상태로 ONLINE | RECOVER DATAFILE
ORA-01157 | 공유되지 않는 경로의 파일에 다른 노드가 접근 | 공유 스토리지로 이동
ORA-02095 | control_files 동적 변경 | SPFILE에 쓰고 재기동
@END

@B 앞의 세 오류는 순서를 지키면 만나지 않는다. ORA-01157은 순서와 무관한 구조의 문제라 위치를 바꾸는 것 말고는 해결책이 없다.
@B 원본이 남아 있는 동안은 반대 방향 SWITCH로 되돌릴 수 있다. NOARCHIVELOG에서는 되돌린 뒤 필요한 리두가 온라인 로그에서 밀려나면 복구가 불가능해지므로 검증은 이동 직후에 몰아서 한다.

@H2 8.9  요약

@B RAC에서 데이터 파일이 공유 스토리지에 없으면 다른 노드가 ORA-01157로 접근하지 못한다. 딕셔너리는 ONLINE으로 보여 주므로 `name not like '+%'` 조회로 찾는다.
@B 이동은 `BACKUP AS COPY ... FORMAT '+DG'`와 `SWITCH ... TO COPY` 두 명령이다. 시간은 복사에만 들고 SWITCH는 경로만 바꿔 수 초에 끝난다.
@B NOARCHIVELOG에서는 ONLINE 파일을 복사할 수 없다(ORA-19602). SWITCH는 모드와 무관하게 파일 OFFLINE을 요구한다(RMAN-06572).
@B 사본 뒤에 데이터베이스가 앞서 나가면 ORA-01113이 나고 `RECOVER DATAFILE`로 메운다. NOARCHIVELOG에서는 리두가 온라인 로그에 남아 있을 때만 가능하다.
@B `control_files`는 실행 중 변경이 불가해(ORA-02095) SPFILE에 쓰고 재기동한다. SPFILE 위치는 인스턴스와 Clusterware 두 곳에 있어 `srvctl modify database -spfile`이 필요하다.
@B SWITCH는 원본을 지우지 않는다. 검증 뒤 RMAN `DELETE COPY`로 정리한다.

@H2 8.10  퀴즈

@QUIZ 퀴즈
1. rac1 로컬 경로에 만든 데이터 파일을 rac2에서 읽으면 어떤 오류가 나는가? 그때 rac2의 V$DATAFILE STATUS는 무엇으로 보이는가?
2. NOARCHIVELOG 데이터베이스에서 `BACKUP AS COPY DATAFILE 23`이 ORA-19602로 실패했다. 선택할 수 있는 두 가지 조치는?
3. RMAN-06572의 요구 조건은 아카이브 모드와 관계가 있는가?
4. SWITCH가 파일 크기와 무관하게 몇 초 만에 끝나는 이유는?
5. SWITCH 뒤 ONLINE에서 ORA-01113이 났다. 원인을 SCN으로 설명하고 조치를 쓰시오.
6. SPFILE을 새 위치로 옮기고 재기동했는데 변경이 반영되지 않았다. 빠뜨린 단계는?
@END

@NOTE 정답과 해설
1. ORA-01157(cannot identify/lock data file)과 ORA-01110. V$DATAFILE STATUS는 ONLINE이고 V$RECOVER_FILE도 비어 있다. 문제는 rac2 OS에 그 경로가 없다는 것이다.
2. 데이터베이스를 ARCHIVELOG로 전환하거나(재기동 필요), 대상 테이블스페이스를 OFFLINE으로 내린 뒤 복사한다.
3. 관계없다. 데이터베이스가 OPEN이면 SWITCH 대상 파일은 항상 OFFLINE이어야 한다.
4. 데이터를 옮기지 않고 컨트롤 파일에 기록된 파일 경로만 사본으로 바꾸기 때문이다.
5. 사본의 체크포인트 SCN(3993926)보다 데이터베이스 현재 SCN(3994002)이 앞서 있어 사본이 뒤처졌다. RECOVER DATAFILE 23으로 리두를 적용한 뒤 ONLINE한다.
6. srvctl modify database -d racdb -spfile '새 경로'. Clusterware가 옛 SPFILE 경로로 인스턴스를 띄웠다.
@END

@H2 8.11  실습 개요

@P 실습은 데이터 파일 하나(FILE# 23)를 계속 따라간다. 각 단계에서 rac2 조회를 빼먹지 않는다. 이 장의 요점이 두 번째 노드에서 보이는가이기 때문이다.

@TBL
실습 | 파일 | 목적
01 | RAC/10장/10장_실습_01_마이그레이션전점검.txt | 파일 위치 지도, 리두 스레드, SPFILE 이중 기록, 필요 공간, 아카이브 모드를 점검한다
02 ★ | RAC/10장/10장_실습_02_데이터파일을ASM으로.txt | 로컬 파일로 ORA-01157을 재현하고 ORA-19602를 거쳐 +DATA로 옮긴 뒤 rac2에서 확인한다
03 ★ | RAC/10장/10장_실습_03_오류재현_사용중SWITCH.txt | +FRA로 옮기며 RMAN-06572와 ORA-01113을 재현하고 RECOVER로 되살린다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다.
@B 실습 02에서 만든 ts_mig는 실습 03이 끝나도 +FRA에 남는다. 이어서 자습하지 않는다면 8.7.1절의 정리 명령으로 테이블, 테이블스페이스, 사본, 자동 백업 조각을 지우고 데이터 파일 13개가 모두 +DATA인지 확인한다. 로컬 사본(`/u01/app/oracle/oradata/ts_mig01.dbf`)도 `DELETE COPY`로 지운다.
@B 수료 후 자습: 10장_실습_04_디스크그룹간이동, 10장_실습_05_SPFILE과컨트롤파일, 10장_실습_06_되돌리기와제약.
