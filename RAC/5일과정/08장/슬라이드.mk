@TITLE Oracle Database 19c RAC 과정|ASM 마이그레이션 — RMAN 활용|BACKUP AS COPY와 SWITCH로 공유 스토리지에 옮긴다|제8장

@PLAIN 학습 목표
- 로컬 데이터 파일이 다른 노드에서 실패하는 이유를 안다
- 이동 전 위치·공간·아카이브 모드를 점검한다
- BACKUP AS COPY와 SWITCH로 데이터 파일을 옮긴다
- ORA-19602·RMAN-06572·ORA-01113을 구분한다
- 컨트롤 파일과 SPFILE 절차가 다른 이유를 안다
- 남은 사본을 RMAN으로 정리한다

@PLAIN Agenda
- 8.2  마이그레이션 전 점검
- 8.3  공유되지 않은 파일 — ORA-01157
- 8.4  복사와 전환
- 8.5  순서를 어기면
- 8.6  컨트롤 파일과 SPFILE
- 8.7  되돌리기와 정리  /  8.8  운영 지침

@SEC 8.2|마이그레이션 전 점검
- 파일 위치 지도
- 필요 공간
- 아카이브 모드

@SLIDE 파일 위치 지도|무엇이 어디 있는가
- 데이터 파일 13, 템프 3, 컨트롤 2 모두 ASM
- 리두 그룹 1·2는 thread 1, 3·4는 thread 2
- 리두 멤버는 +DATA와 +FRA에 한 벌씩
- SPFILE 위치는 인스턴스와 srvctl 두 곳에
@NOTE 옮기려면 먼저 무엇이 어디에 있는지 알아야 합니다. 데이터 파일, 템프 파일, 컨트롤 파일 목록을 한 번에 뽑아 보면 이 랩은 이미 전부 ASM에 있습니다. 그래서 실습에서는 로컬 디스크에 데이터 파일을 하나 일부러 만들어 놓고 옮깁니다. 리두 로그를 보면 THREAD 열이 RAC의 특징을 보여 줍니다. 그룹 1과 2는 racdb1이, 3과 4는 racdb2가 씁니다. SPFILE 위치는 show parameter와 srvctl config 두 곳에 나오는데, 이것이 뒤에서 문제가 됩니다.

@SLIDE 필요 공간|옮기는 동안은 두 벌
- 원본은 그대로 두고 사본을 만듦
- 대상 디스크그룹에 원본 크기만큼 여유
- Normal이면 원시 공간 두 배, USABLE로 판단
- 옮길 양의 1.2배 정도를 확보
@NOTE BACKUP AS COPY는 원본을 둔 채 대상 디스크그룹에 사본을 새로 만듭니다. 그래서 옮기는 동안에는 같은 파일이 두 벌 존재하고, 대상 쪽에 원본 크기만큼의 여유가 있어야 합니다. 대상이 Normal 이중화라면 원시 공간은 두 배가 들기 때문에 FREE가 아니라 7장에서 본 USABLE FILE MB로 판단합니다. 메타데이터와 여유분을 생각해 옮길 양의 1.2배 정도를 잡습니다. 테이블스페이스 단위로 나눠 옮기면 여유가 덜 필요하지만 원본을 지우는 순간 되돌릴 곳이 없어집니다.

@SLIDE 아카이브 모드|절차를 가르는 갈림길
- racdb는 NOARCHIVELOG
- ARCHIVELOG: 연 채로 온라인 복사 가능
- NOARCHIVELOG: 대상 파일을 OFFLINE해야 복사
- 아카이브 전환은 14장
@NOTE 점검 항목 가운데 가장 중요한 것이 로그 모드입니다. ARCHIVELOG 모드라면 데이터베이스를 연 채 온라인 상태의 데이터 파일을 복사할 수 있습니다. 복사 중에 바뀐 내용은 리두로 맞추면 되기 때문입니다. NOARCHIVELOG에서는 복사본이 어느 시점의 것인지 맞출 방법이 없어 대상 파일을 OFFLINE으로 내려야만 복사할 수 있습니다. 이 랩의 racdb는 NOARCHIVELOG라서 이 장의 실습은 모두 OFFLINE을 거칩니다. 아카이브 모드 전환은 14장 백업과 복구에서 다룹니다.

@SEC 8.3|공유되지 않은 파일
- 로컬 경로의 데이터 파일
- rac2에서 ORA-01157
- 찾는 조회

@IMG 08_shared.png|로컬 파일 시스템의 데이터 파일|rac2에는 그 경로가 없다
@NOTE rac1의 로컬 디렉터리에 테이블스페이스를 만들면 rac1에서는 아무 문제가 없습니다. 테이블을 만들고 2만 건을 넣고 읽어도 정상입니다. 그런데 rac2에서 같은 테이블을 읽으면 ORA-01157, 데이터 파일 23을 식별하거나 잠글 수 없다는 오류가 납니다. 컨트롤 파일에는 이 파일이 등록되어 있지만 rac2의 디스크에는 그 디렉터리 자체가 없기 때문입니다. 그림의 아래쪽처럼 ASM 디스크그룹에 있는 파일은 두 노드가 같은 디스크를 보므로 어느 쪽에서든 열립니다.

@SLIDE 딕셔너리는 정상이라고 말한다|OS 계층까지 내려가야 보인다
- rac2 V$DATAFILE: 파일 23 ONLINE
- V$RECOVER_FILE: 0행
- rac2에서 ls: 디렉터리 없음
- 점검: name not like '+%' 가 0행이어야
@NOTE 이 오류가 까다로운 것은 데이터베이스 안에서 보면 아무 문제가 없어 보인다는 점입니다. rac2에서 데이터 파일 뷰를 보면 23번이 ONLINE이고 복구가 필요한 파일 목록도 비어 있습니다. 원인은 OS 계층에 있어서, rac2에서 그 경로를 ls 해 보면 디렉터리가 없다고 나옵니다. 실제 전환 현장에서는 나중에 추가한 테이블스페이스 하나가 로컬에 남아 두 번째 노드에서만 간헐적으로 터지는 형태로 나타납니다. 데이터 파일 이름이 플러스로 시작하지 않는 것을 찾는 한 줄을 점검표에 꼭 넣습니다.

@SEC 8.4|복사와 전환
- ORA-19602
- OFFLINE 후 복사
- SWITCH와 ONLINE

@IMG 08_flow.png|데이터 파일 이동 순서|NOARCHIVELOG에서는 OFFLINE을 끝까지 유지한다
@NOTE 이동은 두 명령으로 이루어집니다. BACKUP AS COPY가 대상 디스크그룹에 사본을 만들고, SWITCH TO COPY가 컨트롤 파일이 가리키는 경로를 그 사본으로 바꿉니다. 시간이 드는 것은 복사 단계뿐이고 SWITCH는 몇 초면 끝납니다. NOARCHIVELOG에서는 그림처럼 테이블스페이스를 OFFLINE으로 내린 뒤 복사하고, 그대로 SWITCH한 다음 ONLINE으로 올립니다. 이 순서를 지키면 사본 이후 바뀐 내용이 없어서 복구 없이 바로 올라옵니다.

@SLIDE ORA-19602|NOARCHIVELOG에서 온라인 복사 불가
- backup as copy datafile 23 format '+DATA'
- cannot backup or copy active file
- 선택 1: ARCHIVELOG로 전환 (재기동 필요)
- 선택 2: 테이블스페이스만 OFFLINE
@NOTE 먼저 그냥 복사를 시도해 봅니다. RMAN에서 데이터 파일 23을 DATA 디스크그룹으로 복사하라고 하면 ORA-19602가 납니다. NOARCHIVELOG 모드에서는 활성 파일을 복사할 수 없다는 메시지로, 원인을 정확히 말해 줍니다. 여기서 길은 둘입니다. 데이터베이스를 ARCHIVELOG로 바꾸면 온라인 복사가 가능하지만 모드 전환에 재기동이 필요합니다. 대상 테이블스페이스만 OFFLINE으로 내리면 그 테이블스페이스만 잠깐 못 쓰게 됩니다. 실습은 두 번째 방법을 씁니다.

@SLIDE OFFLINE 후 복사|이름은 ASM이 OMF로 짓는다
- alter tablespace ts_mig offline
- 출력: +DATA/RACDB/DATAFILE/ts_mig.279.…
- 컨트롤 파일·SPFILE 자동 백업이 함께 실행
- list copy로 사본과 Ckp SCN 확인
@NOTE 테이블스페이스를 OFFLINE으로 내리면 복사가 됩니다. 100메가를 복사하는 데 7초쯤 걸렸습니다. 출력 파일 이름을 보면 ASM이 OMF 규칙으로 알아서 지었는데, 279가 파일 번호이고 뒤의 긴 숫자가 인카네이션입니다. 출력 끝에는 컨트롤 파일과 SPFILE 자동 백업이 함께 실행된 기록이 있습니다. 구조를 바꾸는 작업 뒤에 RMAN이 하는 동작입니다. list copy로 보면 사본마다 체크포인트 SCN이 있는데, 이 숫자가 사본이 어느 시점의 것인지 말해 주고 잠시 뒤 중요해집니다.

@SLIDE SWITCH와 ONLINE|경로만 바꾸므로 크기와 무관
- switch datafile 23 to copy: 약 2초
- OFFLINE 유지 → 복구 없이 ONLINE
- rac2에서 같은 조회가 이제 20000
- 원본은 남는다, 검증 뒤 DELETE COPY
@NOTE SWITCH는 2초 남짓에 끝납니다. 파일을 옮기는 것이 아니라 컨트롤 파일에 적힌 경로를 바꾸는 것뿐이어서 100메가든 1테라든 같은 시간이 걸립니다. 복사부터 SWITCH까지 OFFLINE을 유지했으니 사본 이후 바뀐 것이 없어서 복구 없이 바로 ONLINE이 됩니다. 이제 rac2에서 아까 ORA-01157을 내던 조회를 다시 하면 2만 건이 나옵니다. rac2에서는 아무것도 하지 않았습니다. 원본 파일은 되돌릴 수 있도록 남아 있으니 검증이 끝나면 RMAN으로 지웁니다.

@SEC 8.5|순서를 어기면
- RMAN-06572
- ORA-01113과 SCN
- RECOVER DATAFILE

@SLIDE RMAN-06572|SWITCH는 언제나 OFFLINE을 요구한다
- +FRA로 사본을 만든 뒤 먼저 ONLINE
- database is open and datafile 23 is not offline
- 복사의 OFFLINE 요구는 모드에 따라 다름
- 전환의 OFFLINE 요구는 모드와 무관
@NOTE 이번에는 같은 파일을 FRA로 옮기면서 흔한 실수를 해 봅니다. 사본을 만들었으니 SWITCH 전까지는 테이블스페이스를 써도 되겠다고 생각하고 먼저 ONLINE으로 올린 것입니다. 그 상태에서 SWITCH하면 RMAN-06572, 데이터베이스가 열려 있는데 파일이 오프라인이 아니라는 오류가 납니다. 복사 단계의 OFFLINE 요구는 아카이브 모드에 따라 다르지만, SWITCH의 OFFLINE 요구는 모드와 상관이 없습니다. 누군가 쓰고 있는 파일의 정체를 통째로 바꿀 수는 없기 때문입니다.

@IMG 08_scn.png|사본이 뒤처졌다|SCN 차이를 리두로 메운다
@NOTE 다시 OFFLINE으로 내리고 SWITCH하면 성공합니다. 그런데 ONLINE으로 올리려 하면 ORA-01113, 미디어 복구가 필요하다는 오류가 납니다. 사본의 체크포인트 SCN은 3993926인데 데이터베이스의 현재 SCN은 3994002입니다. 사본을 만든 뒤 ONLINE으로 올려 둔 사이에 데이터베이스가 앞으로 나아갔고 사본은 그 전 시점에 머물러 있는 것입니다. 이 상태에서 테이블을 읽으면 ORA-00376이 납니다. RECOVER DATAFILE로 그 차이만큼 리두를 적용하면 해결됩니다.

@SLIDE RECOVER DATAFILE|NOARCHIVELOG에서 된 이유
- recover datafile 23 → ONLINE → 20000행
- 필요한 리두가 온라인 로그에 남아 있었음
- 로그 스위치로 밀려났다면 복구 불가
- 예방: 복사부터 SWITCH까지 OFFLINE 유지
@NOTE RMAN에서 recover datafile 23을 실행하면 2초 만에 끝나고, ONLINE으로 올린 뒤 2만 건이 그대로 보입니다. 아카이브 로그가 없는데 어떻게 미디어 복구가 됐을까요. 필요한 리두가 아직 온라인 리두 로그에 남아 있었기 때문입니다. 그 사이 로그 스위치가 여러 번 일어나 리두가 덮어써졌다면 복구는 실패하고 그 파일은 되살릴 수 없었습니다. 그래서 NOARCHIVELOG에서는 SCN이 벌어지는 상황 자체를 만들지 않습니다. 복사부터 SWITCH까지 OFFLINE을 계속 유지하는 것이 답입니다.

@SLIDE 중단 시간을 줄이려면|ARCHIVELOG에서는 SWITCH 순간만 OFFLINE
- 복사는 온라인으로 끝내 둠
- SWITCH 직전 OFFLINE → SWITCH → RECOVER → ONLINE
- 복사가 몇 시간이어도 중단은 짧음
- 복사 시간 > 허용 중단이면 아카이브 전환 검토
@NOTE ARCHIVELOG 모드라면 절차가 달라집니다. 복사는 데이터베이스를 연 채 온라인으로 끝내 둡니다. 그다음 SWITCH 직전에만 파일을 OFFLINE으로 내리고, SWITCH한 뒤 RECOVER로 복사 이후의 변경을 적용하고 ONLINE으로 올립니다. 복사에 몇 시간이 걸려도 실제 업무 중단은 SWITCH와 복구에 드는 짧은 시간뿐입니다. 수 테라를 옮겨야 하는 현장에서 마이그레이션 전에 아카이브 모드 전환을 먼저 검토하는 이유입니다. 복사 시간이 허용 가능한 중단보다 길면 전환합니다.

@SEC 8.6|컨트롤 파일과 SPFILE
- control_files와 ORA-02095
- SPFILE 위치의 이중 기록

@IMG 08_spfile.png|위치 정보가 기록된 곳|control_files는 SPFILE에, SPFILE은 두 곳에
@NOTE 데이터 파일의 위치는 컨트롤 파일에 기록되어 있어서 SWITCH 한 번으로 바꿀 수 있었습니다. 컨트롤 파일의 위치는 SPFILE의 control files 파라미터에 기록되어 있고, 이 파라미터는 인스턴스가 돌고 있는 동안 바꿀 수 없습니다. SPFILE의 위치는 다시 두 곳에 있습니다. 지금 돌고 있는 인스턴스가 읽은 값과, Clusterware 자원 정의에 저장되어 다음 기동 때 쓰일 값입니다. 그림처럼 어디에 무엇이 적혀 있는지 알면 이동 절차의 순서가 자연스럽게 나옵니다.

@SLIDE control_files|실행 중에는 바꿀 수 없다
- scope=memory 변경 시도 → ORA-02095
- ISSYS_MODIFIABLE = FALSE
- SPFILE에 기록 → 정지 → NOMOUNT → RESTORE → OPEN
- RAC는 전체 정지, 사본을 하나 더 두는 방식이 안전
@NOTE control files를 ALTER SYSTEM으로 바꾸려 하면 ORA-02095가 납니다. 파라미터 뷰에서 수정 가능 여부를 보면 이것만 FALSE이고 spfile이나 db create file dest는 즉시 변경이 가능합니다. 그래서 컨트롤 파일 이동은 SPFILE에 새 위치를 써 두고, 데이터베이스를 내려 NOMOUNT로 올린 뒤, RMAN으로 기존 사본에서 새 위치에 컨트롤 파일을 복원하고 열어야 합니다. RAC에서는 모든 인스턴스가 같은 컨트롤 파일을 보므로 전체를 내립니다. 새 위치에 사본을 하나 더 둔 뒤 옛 것을 빼는 방식이 안전합니다.

@SLIDE SPFILE 이동|파일을 만들고, srvctl을 고치고, 재기동
- CREATE PFILE FROM SPFILE (55줄 텍스트)
- CREATE SPFILE='+FRA/…' FROM PFILE
- srvctl modify database -d racdb -spfile '+FRA/…'
- srvctl config로 확인 후 재기동
@NOTE SPFILE을 옮기는 순서는 네 단계입니다. 현재 SPFILE을 텍스트 pfile로 내려받고, 그것으로 새 위치에 SPFILE을 만들고, srvctl modify로 Clusterware에 새 위치를 알리고, 재기동합니다. 가장 흔한 실수가 세 번째 단계를 빠뜨리는 것입니다. 그러면 Clusterware가 옛 SPFILE로 인스턴스를 띄워서 바꾼 파라미터가 반영되지 않습니다. 반대로 srvctl만 고치고 파일을 만들지 않으면 인스턴스가 아예 뜨지 않습니다. 재기동 전에 srvctl config로 값을 눈으로 확인하면 둘 다 막을 수 있습니다.

@SEC 8.7|되돌리기와 정리
- ASM에서 파일 시스템으로
- 위치별 rac2 결과
- 사본 정리

@IMG 08_where.png|위치별 rac2의 결과|디스크그룹 종류보다 공유냐 아니냐
@NOTE 역방향 이동도 명령은 같고 FORMAT에 경로를 주면 됩니다. OFFLINE을 유지한 채 진행해서 복구도 즉시 끝납니다. 그런데 결과를 보면 rac1에서는 정상이고 rac2에서는 처음과 똑같은 ORA-01157이 다시 납니다. 그림은 데이터 파일 위치를 네 번 바꾸면서 rac2의 결과를 정리한 것입니다. DATA든 FRA든 공유 디스크그룹에 있을 때만 rac2가 정상이었습니다. RAC에서 로컬 파일 시스템으로 되돌리는 것은 절차상 가능해도 실질적인 선택지가 아닙니다.

@SLIDE 사본 정리|SWITCH는 원본을 지우지 않는다
- drop tablespace는 현재 파일 하나만 삭제
- 나머지 사본은 RMAN 저장소에만 남음
- crosscheck copy → delete noprompt copy
- 자동 백업 조각도 정리, 마지막에 + 확인
@NOTE 실습을 정리할 때 테이블스페이스를 지우면 지금 쓰던 파일 하나만 지워집니다. DATA와 FRA에 만든 사본, 처음의 로컬 파일은 RMAN 저장소에만 기록된 채 남아 있으므로 crosscheck 후 delete copy로 따로 지웁니다. SWITCH 때마다 생긴 컨트롤 파일 자동 백업 조각도 지웁니다. 실습에서는 다른 백업이 없다는 전제로 디스크 백업을 모두 지우지만 운영에서는 대상을 좁혀야 합니다. 마지막으로 데이터 파일이 13개이고 모두 DATA에 있는지 확인합니다.

@SEC 8.8|운영 지침
- 점검 순서
- 오류별 요구 조건

@SLIDE 마이그레이션 점검표|순서를 지키면 세 오류를 만나지 않는다
- 대상 목록 → 아카이브 모드 → USABLE 확인
- OFFLINE → COPY → SWITCH → (RECOVER) → ONLINE
- 다른 노드에서 조회해 확인
- 검증 뒤 DELETE COPY
@NOTE 이 장의 절차를 점검표로 정리합니다. 먼저 플러스로 시작하지 않는 데이터 파일을 찾아 대상을 정하고, 아카이브 모드로 OFFLINE이 필요한지 판단하고, 대상 디스크그룹의 USABLE로 공간을 확인합니다. 그다음 OFFLINE, 복사, SWITCH, 필요하면 RECOVER, ONLINE 순서로 진행합니다. 가장 자주 빠지는 단계는 다른 노드에서의 확인입니다. 첫 노드에서 되면 끝난 줄 알기 쉽지만 RAC에서 확인해야 할 곳은 두 번째 노드입니다. 원본은 검증이 끝난 뒤에 지웁니다.

@SLIDE 오류별 요구 조건|무엇을 요구하는지로 기억한다
- ORA-19602: 파일 OFFLINE (NOARCHIVELOG 복사)
- RMAN-06572: 파일 OFFLINE (SWITCH)
- ORA-01113: RECOVER DATAFILE
- ORA-01157: 공유 스토리지로 / ORA-02095: 재기동
@NOTE 이 장에서 만난 오류를 무엇을 요구하는지로 정리합니다. ORA-19602와 RMAN-06572는 둘 다 파일을 OFFLINE으로 내리라는 요구지만, 앞의 것은 NOARCHIVELOG에서 복사할 때만, 뒤의 것은 SWITCH할 때 항상 나옵니다. ORA-01113은 사본이 뒤처졌으니 복구하라는 요구입니다. 이 셋은 순서만 지키면 만나지 않습니다. ORA-01157은 순서와 무관한 구조 문제라 파일 위치를 바꾸는 것 말고는 해결할 방법이 없습니다. ORA-02095는 재기동이 필요하다는 설계상의 제약입니다.

@PLAIN 요약
- 공유 스토리지에 없는 파일은 다른 노드에서 ORA-01157
- 이동은 BACKUP AS COPY와 SWITCH TO COPY
- 시간은 복사에만, SWITCH는 경로만 바꿔 수 초
- NOARCHIVELOG 복사와 모든 SWITCH는 파일 OFFLINE
- 사본이 뒤처지면 ORA-01113, RECOVER로 메운다
- SPFILE 이동은 srvctl modify까지, 사본은 DELETE COPY

@PLAIN 퀴즈
- 1. 로컬 데이터 파일을 rac2에서 읽으면? V$DATAFILE 상태는?
- 2. ORA-19602에서 고를 수 있는 두 조치는?
- 3. RMAN-06572는 아카이브 모드와 관계가 있는가?
- 4. SWITCH가 크기와 무관하게 빠른 이유는?
- 5. ORA-01113의 원인을 SCN으로 설명하면?
- 6. SPFILE을 옮겼는데 반영되지 않았다. 빠뜨린 단계는?

@PLAIN 실습 개요
- 01  마이그레이션 전 점검
- 02 ★  로컬 파일을 ASM으로, ORA-01157과 ORA-19602
- 03 ★  RMAN-06572와 ORA-01113 재현과 복구
- 03 뒤 이어 자습하지 않으면 ts_mig와 사본 정리
- 파일: RAC/10장/10장_실습_NN_*.txt
