@H1 제10장  RAC 스토리지 관리

@H2 10.1  학습 목표

@P 4장부터 8장까지는 ASM 디스크그룹이라는 저장 계층을 다뤘다. 이 장은 그 위에 놓이는 데이터베이스 구조, 곧 온라인 리두, UNDO, 임시 테이블스페이스, 데이터 파일을 RAC 관점에서 다시 본다. 단일 인스턴스에서 익숙한 구조지만 RAC에서는 인스턴스마다 나뉘는 것과 모두가 공유하는 것이 갈린다. 그 경계가 어디서 생기고, 경계를 넘으려 할 때 어떤 오류가 나는지가 이 장의 주제다.

@B 리두 스레드와 리두 멤버를 구분하고, 스레드가 인스턴스와 대응하는 방식을 `V$LOG`·`V$THREAD`로 확인할 수 있다.
@B 특정 스레드에 리두 그룹을 추가하고, 사용 중인 그룹을 지울 때 나는 ORA-01623의 의미와 처리 순서를 설명할 수 있다.
@B 인스턴스별 UNDO 테이블스페이스 배정을 확인하고 ORA-30013과 ORA-30012를 구분할 수 있다.
@B 임시 테이블스페이스를 공유하면서 인스턴스마다 익스텐트를 따로 확보하는 구조를 설명할 수 있다.
@B 공유하는 자원과 나누는 자원을 가르는 기준을 말하고, 노드 추가 때 필요한 스토리지 작업을 나열할 수 있다.

@H2 10.2  공유하는 것과 나누는 것

@P 1장에서 데이터 파일·컨트롤 파일·SPFILE은 한 벌이고 리두와 UNDO는 인스턴스마다 따로라고 정리했다. 이 장은 그 구분을 자원별로 파고든다. 먼저 전체 그림을 놓고 시작한다.

@IMG 10_shared.png | 그림 10-1. 구조 정보는 모두 공유하고, 동시에 쓸 수 없는 리두와 UNDO만 인스턴스별로 나눈다

@TBL
자원 | 배치 | 나누거나 공유하는 이유
데이터 파일 | 완전 공유 | 데이터는 하나여야 한다. 블록 단위 동시 접근은 Cache Fusion이 조정한다
컨트롤 파일 | 완전 공유 | 리두 그룹·데이터 파일 목록 같은 구조 정보가 하나여야 한다
임시 테이블스페이스 | 공유, 익스텐트는 인스턴스별 확보 | 세션이 익스텐트 단위로 할당받아 쓰고 반납하므로 경합이 작다
UNDO 테이블스페이스 | 인스턴스별 분리 | 트랜잭션마다 롤백 세그먼트를 배타적으로 배정받는다
온라인 리두 | 인스턴스별 분리(스레드) | 순차 쓰기라 두 인스턴스가 한 파일 끝에 이어 붙일 수 없다
@END

@B 나누는 기준은 하나다. 두 인스턴스가 같은 대상을 동시에 써도 되는가. 순차 쓰기이거나 배타적 배정이 필요한 자원은 나눈다.
@B 나뉜 자원도 파일은 +DATA·+FRA에 있다. 평소에는 자기 것만 쓰지만 다른 인스턴스가 읽을 수 있어야 인스턴스 복구가 가능하다.
@B 구조 정보는 언제나 공유된다. 어느 노드에서 리두 그룹이나 데이터 파일을 추가하든 다른 노드에서 곧바로 보인다. 나뉘는 것은 구조가 아니라 사용이다.

@H2 10.3  온라인 리두와 스레드

@P 리두 로그는 변경 내역을 순서대로 기록하는 파일이다. RAC에서는 인스턴스마다 자기 리두 묶음을 갖고, 이 묶음을 스레드(thread)라 부른다.

@IMG 10_redo.png | 그림 10-2. 스레드는 누가 쓰는가, 멤버는 몇 벌 두는가 — 4개 그룹 × 2개 멤버

@H3 10.3.1  스레드와 인스턴스의 대응

@CODE
SQL> select group#, thread#, sequence#, bytes/1024/1024 mb, members, status
  2    from v$log order by group#;

    GROUP#    THREAD#  SEQUENCE#         MB    MEMBERS STATUS
---------- ---------- ---------- ---------- ---------- ----------------
         1          1         15        200          2 INACTIVE
         2          1         16        200          2 CURRENT
         3          2         13        200          2 CURRENT
         4          2         12        200          2 INACTIVE
@END

@B 그룹 1·2는 스레드 1, 그룹 3·4는 스레드 2에 속한다. 스레드마다 그룹이 두 개 이상 있어야 로그 스위치를 할 수 있다.
@B `CURRENT`가 두 개다. 단일 인스턴스라면 하나뿐이지만 RAC에서는 스레드마다 하나씩 CURRENT를 가진다.
@B `SEQUENCE#`는 스레드 안에서만 증가한다. 위 예에서 스레드 1이 세 번 더 스위치했는데, 두 인스턴스의 변경량이 다르기 때문이다.
@B 여러 스레드의 리두를 함께 복구할 때는 `SEQUENCE#`가 아니라 SCN 순서로 병합해 적용한다.

@CODE
SQL> select thread#, status, enabled, groups, instance from v$thread order by thread#;

   THREAD# STATUS ENABLED      GROUPS INSTANCE
---------- ------ -------- ---------- ------------
         1 OPEN   PUBLIC            2 racdb1
         2 OPEN   PUBLIC            2 racdb2
@END

@TBL
열 | 값 | 뜻
STATUS | OPEN / CLOSED | 지금 그 스레드를 쓰는 인스턴스가 있는가. 인스턴스를 내리면 CLOSED
ENABLED | PUBLIC / PRIVATE / DISABLED | PUBLIC은 어느 인스턴스든 쓸 수 있고, PRIVATE는 지정된 인스턴스에 고정된다
GROUPS | 숫자 | 스레드에 속한 리두 그룹 수
INSTANCE | 인스턴스 이름 | 스레드를 쓰는 인스턴스
@END

@B 인스턴스가 어느 스레드를 쓸지는 SPFILE의 `thread` 파라미터가 정한다. 실습 환경은 `racdb1.thread=1`, `racdb2.thread=2`다(9장).
@B ENABLED가 PUBLIC인데 STATUS가 오래 CLOSED로 남아 있다면 노드를 뺀 뒤 스레드를 정리하지 않은 흔적일 수 있다. 쓰지 않는 스레드는 `alter database disable thread N`으로 끄고 그룹을 지운다.

@H3 10.3.2  스레드와 멤버

@CODE
SQL> select l.group#, l.thread#, f.member
  2    from v$log l, v$logfile f
  3   where l.group#=f.group# order by l.group#, f.member;

    GROUP#    THREAD# MEMBER
---------- ---------- ----------------------------------------------
         1          1 +DATA/RACDB/ONLINELOG/group_1.262.1242761749
         1          1 +FRA/RACDB/ONLINELOG/group_1.258.1242761759
         ...
         4          2 +FRA/RACDB/ONLINELOG/group_4.260.1242762483
8 rows selected.
@END

@B 그룹은 넷인데 행은 여덟이다. 스레드(누가 쓰는가)와 멤버(몇 벌 두는가)가 서로 다른 축이기 때문이다.
@B 멤버는 같은 내용을 담은 사본이다. +DATA와 +FRA에 하나씩 두어 디스크그룹 하나를 잃어도 리두가 남는다. 이 축은 단일 인스턴스에도 있다.
@B 스레드는 RAC에서 생긴 축이다. 스레드 1은 racdb1만 쓰지만 파일은 공유 디스크그룹에 있으므로 racdb2도 읽을 수 있다.

@BP 스레드마다 크기를 같게 둔다
스레드별로 부하가 달라 스위치 주기가 달라져도 그룹 크기를 스레드마다 다르게 잡지 않는다. 인스턴스 복구 시간을 예측하기 어려워지고, 노드 추가·삭제 때 기준이 흔들린다.
한쪽 스레드만 스위치가 잦다면 리두 크기보다 부하 배치를 먼저 본다. 접속을 나누는 도구는 12장의 서비스다.
@END

@H3 10.3.3  리두 그룹 추가

@CODE
SQL> alter database add logfile thread 1 group 5 ('+DATA','+FRA') size 50M;
Database altered.

SQL> select group#, member from v$logfile where group#=5 order by member;
    GROUP# MEMBER
---------- ------------------------------------------------------
         5 +DATA/RACDB/ONLINELOG/group_5.279.1243078375
         5 +FRA/RACDB/ONLINELOG/group_5.261.1243078377
@END

@B `thread 1`이 어느 스레드에 붙일지 정한다. 이 절을 빠뜨리면 오류 없이 명령을 실행한 인스턴스의 스레드에 붙는다. 오류가 나지 않아 오히려 놓치기 쉽다.
@B `('+DATA','+FRA')`는 멤버 두 개를 각 디스크그룹에 하나씩 만든다. 파일 이름은 ASM이 OMF 규칙으로 짓는다(5장).
@B 새 그룹의 STATUS는 `UNUSED`다. 로그 스위치가 아직 그 그룹 차례까지 오지 않았다는 뜻이다.
@B rac1에서 추가한 그룹이 rac2의 `V$LOG`에도 곧바로 보인다. 리두 구성은 공유되는 컨트롤 파일에 기록되기 때문이다. 보이는 것과 쓰는 것은 다르다. 그룹 5는 스레드 1의 것이라 racdb2는 쓰지 않는다.

@H3 10.3.4  사용 중인 그룹을 지우면 — ORA-01623

@CODE
SQL> alter database drop logfile group 2;
ORA-01623: log 2 is current log for instance racdb1 (thread 1) - cannot drop
ORA-00312: online log 2 thread 1: '+DATA/RACDB/ONLINELOG/group_2.263.1242761749'
ORA-00312: online log 2 thread 1: '+FRA/RACDB/ONLINELOG/group_2.257.1242761759'
@END

@B 그룹 2는 racdb1의 CURRENT 로그다. 지금 쓰고 있는 리두는 지울 수 없다.
@B 메시지에 인스턴스 이름과 스레드 번호가 함께 나온다. 어느 노드에서 로그 스위치를 해야 하는지 이 줄에서 바로 알 수 있다.
@B 함께 나오는 ORA-00312 두 줄은 그 그룹의 멤버 파일이다. 멤버가 둘이라 두 줄이다.
@B racdb2에서 아무리 스위치해도 스레드 1의 CURRENT는 바뀌지 않는다. 스위치는 해당 스레드를 쓰는 인스턴스에서 한다.

@H3 10.3.5  리두 크기를 바꾸는 순서

@P 리두 그룹의 크기는 바꿀 수 없으므로 새 크기의 그룹을 만들고 옛 그룹을 빼는 방식을 쓴다. 지우고 다시 만드는 순서를 거꾸로 밟으면 중간에 그룹이 모자라 거부된다.

@IMG 10_resize.png | 그림 10-3. 리두 크기 변경 — 새 그룹 추가, 해당 스레드의 인스턴스에서 스위치, INACTIVE 확인 후 삭제

@CODE
-- 1. 새 크기 그룹을 스레드마다 먼저 추가
alter database add logfile thread 1 group 11 ('+DATA','+FRA') size 500M;
alter database add logfile thread 1 group 12 ('+DATA','+FRA') size 500M;
alter database add logfile thread 2 group 13 ('+DATA','+FRA') size 500M;
alter database add logfile thread 2 group 14 ('+DATA','+FRA') size 500M;
-- 2. 해당 스레드의 인스턴스에서 스위치와 체크포인트
alter system switch logfile;
alter system checkpoint;
-- 3. INACTIVE 확인 후 옛 그룹 삭제
select group#, thread#, status from v$log order by group#;
alter database drop logfile group 1;
@END

@B 2단계는 스레드 1이면 rac1의 racdb1에서, 스레드 2면 rac2의 racdb2에서 실행한다. 노드마다 세션을 하나씩 열어 두고 진행한다.
@B STATUS가 ACTIVE면 아직 체크포인트가 끝나지 않은 것이다. INACTIVE가 된 뒤에 지운다. UNUSED인 그룹은 바로 지울 수 있다.
@B 작업 후에는 스레드마다 새 크기 그룹만 두 개 이상 남았는지 `V$LOG`로 확인한다. ASM 쪽 멤버 파일은 그룹을 지울 때 함께 지워진다.

@CASE 리두 크기 변경을 야간 작업으로 할 때
스위치와 체크포인트가 반복되어 I/O 부하가 생기므로 서비스 시간을 피한다. 두 스레드를 모두 바꿔야 하므로 rac1과 rac2에 각각 세션을 열고, 어디까지 했는지 기록하며 진행한다.
중간에 멈추면 옛 크기와 새 크기 그룹이 섞여 남는다. 동작은 하지만 옛 그룹이 CURRENT가 되는 동안 스위치 주기가 달라져 원인 모를 체크포인트 대기를 만든다.
@END

@H2 10.4  UNDO 테이블스페이스

@P UNDO는 트랜잭션을 되돌리고 읽기 일관성을 제공하는 데 쓰는 이전 값이다. RAC에서는 인스턴스마다 UNDO 테이블스페이스를 하나씩 배정한다.

@IMG 10_undo.png | 그림 10-4. 인스턴스별 UNDO 배정 — 남의 것을 지정하면 ORA-30013, 없는 것을 지정하면 ORA-30012

@H3 10.4.1  배정 확인

@CODE
SQL> select inst_id, value from gv$parameter
  2   where name='undo_tablespace' order by inst_id;

   INST_ID VALUE
---------- ----------
         1 UNDOTBS1
         2 UNDOTBS2
@END

@B 배정은 SPFILE의 `racdb1.undo_tablespace='UNDOTBS1'`처럼 sid 접두어가 붙은 항목으로 정해진다.
@B `undo_management`(AUTO)와 `undo_retention`(900)은 두 인스턴스가 같은 값을 쓴다. 보존 기간이 다르면 어느 노드에 붙었느냐에 따라 같은 조회가 ORA-01555로 실패하기도 한다.
@B 각 UNDO 테이블스페이스에는 롤백 세그먼트가 여러 개(`DBA_ROLLBACK_SEGS` 기준 10개씩) 있다. 인스턴스는 자기 테이블스페이스의 세그먼트만 트랜잭션에 배정한다.
@B 두 인스턴스가 한 UNDO를 함께 쓴다면 세그먼트 배정을 두고 노드 사이에서 다투게 된다. 그래서 나눈다.

@NOTE CDB에서 UNDO 파일을 조회할 때
`V$TABLESPACE`와 `V$DATAFILE`을 `ts#`만으로 조인하면 컨테이너마다 행이 곱해져 같은 파일이 여러 번 나온다. 조인 조건에 `con_id`를 넣고, 루트의 UNDO만 보려면 `df.con_id=1`로 거른다.
RAC는 인스턴스 축을, CDB는 컨테이너 축을 하나씩 더한다. 두 축을 모두 빠뜨리면 결과 행 수가 곱으로 늘어난다.
@END

@H3 10.4.2  크기와 사용 통계

@B 실습 환경에서 UNDOTBS1은 350MB, UNDOTBS2는 25MB였다. 데이터베이스 생성 때 만들어져 그동안 자동 확장된 것과 두 번째 인스턴스용으로 만들어진 것의 차이다.
@B 크기 차이 자체는 문제가 아니다. 비슷한 부하인데 한쪽만 계속 커진다면 접속이 그 노드에 몰려 있다는 신호다.
@B `GV$UNDOSTAT`은 10분 구간마다 UNDO 사용량을 인스턴스별로 쌓는다. `MAXQUERYLEN`이 `undo_retention`을 넘는 구간은 ORA-01555 위험 구간이다.
@B UNDO 통계는 인스턴스마다 따로이므로 `V$UNDOSTAT`만 보면 절반만 본다. 반드시 `GV$`로 두 인스턴스를 함께 본다.

@CODE
SQL> select inst_id, undotsn, undoblks, txncount, maxquerylen
  2    from gv$undostat order by inst_id, begin_time desc;

   INST_ID    UNDOTSN   UNDOBLKS   TXNCOUNT MAXQUERYLEN
---------- ---------- ---------- ---------- -----------
         1          2          1         37         975
         1          2          1         18        1561
         1          2        310        207           0
@END

@B `UNDOTSN`은 그 인스턴스가 쓰는 UNDO 테이블스페이스 번호다. 인스턴스 2의 행에는 다른 번호가 나온다.
@B `UNDOBLKS`가 한 구간만 크게 튄 것은 그 시간대에 대량 변경이 있었다는 흔적이다. `MAXQUERYLEN` 1561초 구간은 보존 기간 900초를 넘긴 조회가 있었다는 뜻이므로 ORA-01555 가능성을 살핀다.

@H3 10.4.3  다른 인스턴스의 UNDO를 지정하면

@CODE
SQL> alter system set undo_tablespace='UNDOTBS2' scope=memory;
ORA-02097: parameter cannot be modified because specified value is invalid
ORA-30013: undo tablespace 'UNDOTBS2' is currently in use

SQL> alter system set undo_tablespace='UNDOTBS9' scope=memory;
ORA-02097: parameter cannot be modified because specified value is invalid
ORA-30012: undo tablespace 'UNDOTBS9' does not exist or of wrong type
@END

@TBL
오류 | 뜻 | 조치
ORA-30013 | 다른 인스턴스가 그 UNDO를 쓰고 있다 | 새 UNDO 테이블스페이스를 만들어 지정한다
ORA-30012 | 없는 이름이거나 UNDO 유형이 아니다 | 이름을 확인하거나 UNDO 테이블스페이스를 먼저 만든다
ORA-02097 | 파라미터를 바꿀 수 없다는 일반 메시지 | 아래 줄의 오류가 실제 원인이다
@END

@B 겹쳐 나온 오류는 마지막 줄을 먼저 읽는다. 위는 무엇을 하려다 실패했는지, 아래는 왜 실패했는지를 말한다(11장에서 오류 체계로 다시 정리한다).
@B `scope=memory`로 시도했으므로 거부된 뒤 SPFILE에는 아무것도 남지 않는다. 실습에서 파라미터를 시험할 때 쓰는 안전한 방법이다.
@B 오라클이 이 변경을 막을 수 있는 이유는 실행 시점에 확인이 가능해서다. UNDO가 지금 다른 인스턴스에 물려 있는지는 바로 알 수 있다.
@B 노드를 추가할 때 두 오류를 차례로 만나기 쉽다. 새 인스턴스용 UNDO를 만들지 않고 이름만 적으면 ORA-30012, 기존 것을 그대로 지정하면 ORA-30013이다.

@H2 10.5  임시 테이블스페이스

@P 정렬과 해시 조인이 메모리를 넘치면 임시 테이블스페이스를 쓴다. RAC에서도 TEMP는 하나를 공유하지만 사용량은 인스턴스별로 잡힌다.

@IMG 10_temp.png | 그림 10-5. TEMP 하나를 공유하되 인스턴스마다 익스텐트를 미리 확보해 세션에 나눠 준다

@B 실습 환경의 `DBA_TABLESPACES`에서 TEMPORARY 유형은 TEMP 하나다. `V$TEMPFILE`에 파일이 셋 보이는 것은 인스턴스가 아니라 컨테이너(CDB$ROOT, PDB$SEED, RACPDB1) 때문이다.
@B 각 인스턴스는 TEMP에서 자기 몫의 익스텐트를 확보해 두고 그 안에서 세션에 나눠 준다. 확보량은 `GV$SORT_SEGMENT`의 `TOTAL_BLOCKS`로 본다.
@B 지금 임시 공간을 쓰는 세션은 `GV$TEMPSEG_USAGE`로 본다.
@B 리두와 달리 나누지 않는 이유는 할당 단위가 처음부터 익스텐트로 나뉘어 있어 함께 써도 경합이 작기 때문이다.

@CODE
SELECT inst_id, tablespace_name, total_blocks, used_blocks, free_blocks
  FROM gv$sort_segment ORDER BY inst_id;
SELECT inst_id, count(*) FROM gv$tempseg_usage GROUP BY inst_id;
@END

@BP ORA-01652를 만나면 두 가지를 본다
하나는 테이블스페이스 전체의 여유다. `V$TEMPFILE` 크기와 자동 확장 설정을 확인한다.
다른 하나는 인스턴스별 확보량이다. 한 인스턴스가 대부분을 확보하고 있으면 전체 여유가 있어도 다른 인스턴스 세션이 공간을 얻지 못할 수 있다. 단일 인스턴스에는 없는 상황이라 전체 크기만 보고 원인을 찾지 못하는 경우가 많다.
@END

@H2 10.6  데이터 파일

@P 데이터 파일은 완전히 공유한다. 어느 노드에서 만들든 다른 노드에서 별도 작업 없이 쓸 수 있다.

@CODE
[oracle@rac2 ~]$ sqlplus / as sysdba
SQL> create tablespace ts_ch13 datafile '+DATA' size 100M autoextend off;
Tablespace created.

[oracle@rac1 ~]$ sqlplus / as sysdba
SQL> select tablespace_name, status from dba_tablespaces where tablespace_name='TS_CH13';
TABLESPACE_NAME                STATUS
------------------------------ ---------
TS_CH13                        ONLINE
@END

@B rac2에서 만든 테이블스페이스가 rac1에서 곧바로 보인다. 데이터 사전과 컨트롤 파일이 공유되기 때문이다.
@B 두 인스턴스가 같은 테이블에 동시에 행을 넣어도 양쪽 결과가 모두 보인다. 같은 블록을 두 인스턴스가 바꾸려 할 때의 조정은 저장 계층이 아니라 Cache Fusion이 맡는다(1장, 17장).
@B 파일이 공유 디스크그룹이 아닌 노드 로컬 경로에 만들어지면 다른 노드는 그 파일을 열지 못한다. 8장에서 로컬 경로 파일이 ORA-01157을 낸 것이 그 경우다. RAC에서 파일 위치는 언제나 `+DATA`처럼 디스크그룹으로 지정한다.

@H2 10.7  노드 추가와 스토리지 점검

@H3 10.7.1  새 인스턴스를 위한 스토리지 준비

@P 노드를 추가하면 새 인스턴스는 자기 스레드와 UNDO를 가져야 한다. 15장의 노드 추가 절차가 내부에서 수행하는 일을 스토리지 관점에서 정리한다.

@CODE
alter database add logfile thread 3 group 6 ('+DATA','+FRA') size 200M;
alter database add logfile thread 3 group 7 ('+DATA','+FRA') size 200M;
alter database enable public thread 3;
create undo tablespace UNDOTBS3 datafile '+DATA' size 200M autoextend on;
alter system set undo_tablespace='UNDOTBS3' sid='racdb3' scope=spfile;
alter system set thread=3 sid='racdb3' scope=spfile;
@END

@B 리두 그룹을 최소 둘 만들고 스레드를 활성화한다. 활성화를 빠뜨리면 새 인스턴스가 열리지 않는다.
@B 새 UNDO 테이블스페이스를 만들고 SPFILE에 sid 접두어로 지정한다. 만들지 않고 이름만 적으면 ORA-30012다.
@B 임시 테이블스페이스와 데이터 파일은 손댈 것이 없다. 공유하기 때문이다.

@CASE 노드를 붙였는데 새 인스턴스가 열리지 않는다
새 노드에 소프트웨어와 인스턴스 정의까지 넣었는데 기동 단계에서 실패했다. 경보 로그에는 쓸 수 있는 공개 스레드가 없다는 ORA-01620이 남아 있었다.
리두 그룹은 만들었지만 `enable public thread 3`을 빠뜨린 것이 원인이었다. 스레드를 활성화하자 인스턴스가 열렸다. 이어서 UNDO를 지정하지 않은 상태라 ORA-30012를 한 번 더 만났다. 세 가지 준비물을 점검표로 두면 두 번의 재시도를 줄일 수 있다.
@END

@H3 10.7.2  일상 점검 항목

@TBL
주기 | 확인 항목 | 조회
매일 | 스레드마다 CURRENT가 하나씩인가 | `v$log`의 thread#, status
매일 | UNDO 크기가 한쪽만 커지지 않는가 | `dba_data_files`의 UNDO 파일 크기
주간 | 스레드마다 그룹이 둘 이상인가 | `v$log`를 thread#로 집계
주간 | 인스턴스별 임시 공간 확보량의 균형 | `gv$sort_segment`
변경 후 | 양 노드에서 같은 구성이 보이는가 | `dba_data_files`, `v$log`
@END

@B 스레드별 리두 발생량은 `GV$SYSSTAT`의 `redo size`로 비교한다. 인스턴스 기동 이후 누적값이므로 `GV$INSTANCE.STARTUP_TIME`이 크게 다르면 시간당 값으로 환산해 본다.
@B `redo log space requests`가 계속 늘면 리두 그룹이 작거나 부족한 것이다.

@CODE
SQL> select thread#, count(*) cnt, min(sequence#) mn, max(sequence#) mx
  2    from v$log_history group by thread# order by thread#;

   THREAD#        CNT         MN         MX
---------- ---------- ---------- ----------
         1         15          1         15
         2         12          1         12
@END

@B `V$LOG_HISTORY`는 지나간 스위치 이력이라 STATUS 열이 없다. STATUS를 넣으면 ORA-00904가 난다. 이력은 스레드별 건수와 범위로 집계해 본다.
@B 위 예는 스레드 1이 더 자주 스위치했다는 뜻이다. 실습 대부분을 rac1에서 진행했기 때문이며, 운영에서 같은 모습이 이어지면 접속 분산을 점검한다(12장).

@H2 10.8  요약

@B RAC는 데이터 파일·컨트롤 파일·TEMP를 공유하고, 온라인 리두와 UNDO를 인스턴스별로 나눈다. 기준은 동시에 써도 되는가다.
@B 리두는 스레드 단위로 나뉜다. 스레드는 누가 쓰는가, 멤버는 몇 벌 두는가를 정하는 서로 다른 축이다.
@B 리두 그룹은 `thread N` 절로 붙일 스레드를 지정해 추가한다. 구성은 컨트롤 파일에 기록되어 모든 노드에서 곧바로 보인다.
@B CURRENT 그룹을 지우면 ORA-01623이 나고 메시지에 인스턴스와 스레드가 함께 나온다. 스위치는 그 스레드의 인스턴스에서 한다.
@B UNDO는 인스턴스마다 배정된다. 다른 인스턴스의 것을 지정하면 ORA-30013, 없는 것을 지정하면 ORA-30012다.
@B TEMP는 하나를 공유하되 인스턴스마다 익스텐트를 확보한다. 임시 공간 부족은 전체 여유와 인스턴스별 확보량을 함께 본다.
@B 노드를 추가할 때는 리두 그룹, 스레드 활성화, UNDO 테이블스페이스 세 가지를 준비한다.

@H2 10.9  퀴즈

@QUIZ 퀴즈
1. 온라인 리두와 UNDO는 나누고 임시 테이블스페이스는 공유하는 기준은 무엇인가?
2. `V$LOG`에서 CURRENT가 두 개 보이는 이유와, `SEQUENCE#`가 스레드마다 다른 이유를 쓰시오.
3. 그룹 4개, 멤버 2개씩인 리두 구성에서 `V$LOGFILE` 조인 결과가 8행인 이유는?
4. ORA-01623이 났을 때 어느 노드에서 무엇을 해야 그 그룹을 지울 수 있는가?
5. ORA-30013과 ORA-30012의 차이를 쓰고, 노드 추가 때 각각 어떤 상황에서 나는지 설명하시오.
6. TEMP 전체에 여유가 있는데 한 인스턴스에서 ORA-01652가 났다. 무엇을 확인하는가?
@END

@NOTE 정답과 해설
1. 동시에 써도 되는가. 리두는 순차 쓰기라 한 파일 끝에 두 인스턴스가 이어 붙일 수 없고, UNDO는 롤백 세그먼트를 배타적으로 배정해야 한다. TEMP는 익스텐트 단위로 나눠 쓰므로 공유해도 경합이 작다.
2. 스레드마다 CURRENT가 하나씩 있기 때문이다. 각 인스턴스가 자기 스레드에서 독립적으로 스위치하므로 변경량에 따라 번호가 다르게 올라간다.
3. 스레드와 멤버가 다른 축이다. 그룹 4개 각각에 +DATA·+FRA 멤버가 있어 4 × 2 = 8행이다.
4. 메시지에 나온 인스턴스(racdb1, thread 1)가 있는 rac1에서 로그 스위치와 체크포인트를 해 그룹을 INACTIVE로 만든 뒤 지운다. 스레드마다 그룹이 둘 이상 남아야 한다.
5. ORA-30013은 다른 인스턴스가 쓰는 UNDO를 지정했을 때, ORA-30012는 없는 이름을 지정했을 때 난다. 새 인스턴스에 기존 UNDO를 지정하면 전자, UNDO를 만들지 않고 이름만 적으면 후자다.
6. `GV$SORT_SEGMENT`로 인스턴스별 확보량을 본다. 다른 인스턴스가 대부분을 확보하고 있으면 전체 여유와 상관없이 공간을 얻지 못할 수 있다.
@END

@H2 10.10  실습 개요

@P 이 장의 실습은 조회와 오류 재현 중심이다. 실습 02에서 만든 리두 그룹은 같은 실습 끝에서 지우므로 끝나면 리두 그룹 4개, UNDO 2개, TEMP 1개인 기준선으로 돌아온다.

@TBL
실습 | 파일 | 목적
01 | RAC/13장/13장_실습_01_스레드별리두확인.txt | 리두 스레드와 인스턴스의 대응, 스레드와 멤버의 차이를 확인한다
02 ★ | RAC/13장/13장_실습_02_리두그룹추가.txt | 스레드 1에 그룹을 추가해 rac2에서 확인하고 ORA-01623을 재현한 뒤 정리한다
03 | RAC/13장/13장_실습_03_UNDO구성.txt | 인스턴스별 UNDO 배정과 롤백 세그먼트, CDB 조인 주의점을 확인한다
04 | RAC/13장/13장_실습_04_오류재현_UNDO.txt | `scope=memory`로 ORA-30013과 ORA-30012를 재현하고 구분한다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다. 이 장에는 스냅샷이 필요한 실습이 없다.
@B 수료 후 자습: 13장_실습_05_임시테이블스페이스, 13장_실습_06_데이터파일공유와정리.
@B 실습 02는 마지막에 `alter database drop logfile group 5`로 그룹을 지우고 `asmcmd find +DATA 'group_5*'`가 아무것도 출력하지 않는지 확인한다.
