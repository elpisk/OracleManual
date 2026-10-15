# Oracle Database 19c Active Data Guard 교안 — 실습 트랜스크립트 주제 목록

**작성일**: 2026-08-26
**갱신일**: 2026-10-16 — 실제 실습 파일(`NN장\N장_실습_NN_*.txt`) 111개에 맞춰 장별 항목을 다시 씀
**상태**: 작성 완료

- **형식**: SQL\*Plus / DGMGRL / 셸 세션 트랜스크립트. 프롬프트는 노드를 구분한다 — `SYS@chicago>`, `SYS@boston>`, `DGMGRL>`, `[oracle@chicago-srv ~]$`, `[oracle@boston-srv ~]$`
- **파일명**: `{N}장_실습_{NN}_{주제}.txt`. 아래 항목 번호가 파일의 `NN`이다
- **총 16장 / 111개**
- 각 파일 최소 1곳에 **"오류·이상 징후 발생 → 원인 파악 → 조치 → 재확인"** 흐름을 넣는다
- **★** = 두 노드가 동시에 살아 있어야 성립하는 실습 (전체의 대부분)
- **🔒** = Active Data Guard 옵션 라이선스가 필요한 실습. 9장은 실습 08이 옵션 없는 대안 경로다
- **공통 전제**: 개인 실습 환경 전용. 역할 전환·강제 종료·파라미터 변경·재기동이 포함된다
- **되돌리기 원칙**: 역할 전환 실습은 반드시 원래 역할로 되돌린 상태로 끝낸다. Snapshot standby는 physical standby로 복귀시킨다. Broker 구성은 실습마다 삭제하지 않고 13장에서 만든 것을 15·16장까지 이어 쓴다

---

## 1장. Data Guard 개요와 아키텍처 (5개)
1. 현재 구성 파악 — `V$DATABASE`로 두 노드의 역할·열림 모드·보호 모드·DBID 확인, 같아야 할 값과 달라야 할 값 정리
2. Data Guard 프로세스 식별 — `V$MANAGED_STANDBY`·`V$DATAGUARD_PROCESS`로 양쪽 프로세스 확인, `CLIENT_ROLE`로 Primary·Standby 프로세스 짝 맞추기
3. 라이선스 확인 — Active Data Guard 옵션 사용 여부를 확인하는 경로와 그 한계. 판정은 계약서로 한다
4. Standby 유형별 ROLE / OPEN_MODE 확인 — snapshot standby로 바꿔 `DATABASE_ROLE`·`OPEN_MODE`·`CONTROLFILE_TYPE` 변화 관찰 후 원복
5. 구성 전 점검표 — 구성 전에 두 노드에서 확인할 항목을 조회로 점검, 일치해야 하는 것과 달라도 되는 것 구분

## 2장. 데이터 보호 모드와 리두 전송 서비스 ★ (5개)
1. 현재 보호 모드 확인과 세 모드의 요건 비교 — `PROTECTION_MODE`·`PROTECTION_LEVEL` 두 열의 차이, 모드별 전제 조건 조회
2. `LOG_ARCHIVE_DEST_2` 속성 해부 — `SERVICE`·`SYNC/ASYNC`·`AFFIRM`·`VALID_FOR`·`DB_UNIQUE_NAME`을 하나씩 바꾸며 `V$ARCHIVE_DEST` 열 변화 대응
3. **보호 모드 전환과 거부 재현** — Maximum Protection으로 올라가는 경로, 원인이 다른 두 가지 `ORA-01126` 구분
4. **보호 모드별 Primary 동작 차이** — Standby를 잃었을 때 Maximum Availability와 Maximum Protection의 Primary 반응 비교. Primary가 실제로 종료된다
5. `PROTECTION_MODE`와 `PROTECTION_LEVEL`이 어긋나는 상황 — 두 경로로 재현하고 해소, RESYNCHRONIZATION의 정상·이상 판별 기준

## 3장. Data Guard를 위한 Oracle Net 구성 ★ (6개)
1. `tnsnames.ora` 구성과 `tnsping` 검증 — 양쪽 대칭 구성, `tnsping`이 확인해 주는 것과 확인해 주지 않는 것
2. `listener.ora` 정적 등록 — `SID_LIST_LISTENER`의 세 요소, `lsnrctl status`의 READY / UNKNOWN / BLOCKED 판독
3. **정적 등록 제거와 복원** — 정적 등록 없이 NOMOUNT 인스턴스에 접속할 수 없음을 재현, `ORA-12514`와 `ORA-12528` 구분
4. `LOG_ARCHIVE_CONFIG`의 `DG_CONFIG` — 하는 일과, 비웠을 때 일어나는 일·일어나지 않는 일
5. **패스워드 파일 불일치** — `ORA-01017` → `ORA-16191` 재현, 원인을 고쳐도 목적지 상태가 저절로 회복되지 않음 확인
6. 포트 차단과 해소 — iptables로 1521을 막아 `TNS-12535` 재현, 이 장의 오류를 계층 지도로 정리

## 4장. Primary 준비 — ARCHIVELOG·FORCE LOGGING·Standby Redo Log (6개)
1. DBCA silent 모드로 CDB 생성 — 구축 때 실행한 DBCA 명령과 로그를 읽고 옵션별 의미 해석 (재생성하지 않음)
2. ARCHIVELOG 모드 확인과 전환 — 두 가지 확인 방법, FRA 사용률 점검, 전환이 거부되는 조건 재현
3. FORCE LOGGING 실증 — 같은 작업을 세 조건에서 실행해 리두 발생량 비교
4. **Standby Redo Log 산정과 생성** — 온라인 리두를 근거로 개수·크기 산정, 크기가 다른 SRL을 만들었을 때의 결과
5. **SRL을 지우고 실시간 적용 시도** — `ORA-00261`·`ORA-01153`·`ORA-01184` 재현과 복구
6. 19c STANDBY NOLOGGING 모드 — `FOR DATA AVAILABILITY` / `FOR LOAD PERFORMANCE` 설정과 `V$DATABASE.FORCE_LOGGING` 변화

## 5장. Physical Standby 생성 ① RMAN DUPLICATE (경로 지정 방식) ★ (7개)
1. Primary 파라미터 확인과 기준값 기록 — 2~4장 설정값 확인, DUPLICATE 후 대조할 기준 기록
2. Standby 초기 pfile 작성 — 두 줄짜리 pfile로 충분한 이유, 나머지를 DUPLICATE가 만드는 방식
3. Standby 인스턴스 NOMOUNT 기동과 접속 확인 — Standby를 헐고 NOMOUNT로 기동, Primary에서 원격 SYS 접속 확인
4. **RMAN DUPLICATE 실행** — `FOR STANDBY FROM ACTIVE DATABASE` 실행과 진행 로그 단계별 판독
5. **DUPLICATE 실패 두 가지 재현과 진단** — convert 파라미터 누락, 대상 디렉터리 없음
6. 복제 결과 검증과 Active Data Guard 전환 — 실습 01 기준값과 대조, MOUNTED → READ ONLY WITH APPLY
7. `DBMS_DBCOMP` 블록 비교 — Primary·Standby 블록 직접 비교, 보고서 판독과 패키지의 함정 세 가지

## 6장. Physical Standby 생성 ② OMF 방식 ★ (7개)
1. OMF 파라미터와 기준 상태 확인 — OMF 세 파라미터의 현재 값, 5장 구성 기록
2. **없는 디렉터리를 가리켰을 때** — `db_create_file_dest`가 존재하지 않는 경로일 때 막히는 지점, 5장 실패와의 차이
3. **파라미터 누락 실패 재현** — `db_create_file_dest`도 convert도 없을 때 5장 첫 번째 실패와 같은 오류
4. **OMF 방식 DUPLICATE 실행** — 로그에서 OMF가 경로를 만드는 모습 확인
5. OMF가 만든 구조 해부 — GUID 디렉터리·파일 이름 규칙·로그 이중화, 5장 구성과 항목별 대조
6. 컨트롤 파일 교정 — 컨트롤 파일만 Primary 경로를 쓰는 문제를 찾아 BOSTON 경로로 바로잡기
7. 두 방식 비교와 ADG 복귀 검증 — 설치 가이드 후속 단계 검증, 5·6장 결과 열두 항목 대조

## 7장. Redo Apply 기동과 동기화 검증 ★ (7개)
1. 적용 프로세스 관찰 — `V$MANAGED_STANDBY`의 프로세스 역할과 상태, RFS·MRP0 관계에서 실시간 적용의 증거 찾기
2. 적용 제어와 두 가지 오류 — 적용을 켜고 끄는 세 명령, `ORA-16136`과 `ORA-01153` 구분
3. **BAD PARAM 진단과 교정** — Standby `LOG_ARCHIVE_DEST_1`의 BAD PARAM 원인 교정, `RECOVERY_MODE` 회복과 `FAL_CLIENT` 확인
4. 실시간 적용 판별 — `RECOVERY_MODE` 열과 기능 시험으로 판별, 19c에서 `USING CURRENT LOGFILE`이 바꾸는 것
5. **갭 만들기와 해소** — 적용을 멈추고 로그를 전환해 갭 생성, `V$ARCHIVE_GAP` 관찰과 따라잡기 추적
6. 지연 읽기 — `V$DATAGUARD_STATS` 네 행의 뜻, `TIME_COMPUTED`와 `DATUM_TIME` 차이, 통합 점검 조회
7. SRL과 적용 — SRL을 지웠다 복구하며 `ORA-00261`·`ORA-01184` 재현, OMF 이름 변화 관찰

## 8장. Primary 구조 변경의 Standby 반영 ★ (7개)
1. 테이블스페이스 추가의 자동 반영 — `STANDBY_FILE_MANAGEMENT=AUTO`에서 Standby 반영 확인
2. 데이터 파일 추가와 크기 변경 — 추가·resize·삭제의 자동 반영
3. **MANUAL 재현과 UNNAMED 파일** — `STANDBY_FILE_MANAGEMENT=MANUAL`에서 적용 정지, `ORA-1274`와 `ORA-1111` 구분
4. UNNAMED 파일 복구 — `ALTER DATABASE CREATE DATAFILE ... AS NEW`로 복구하고 데이터 일치 확인
5. PDB 추가와 삭제의 반영 — GUID 디렉터리까지 자동 반영, 삭제 후 남는 것
6. 반영되지 않는 것: 온라인 리두 로그 — 그룹 추가가 Standby에 반영되지 않음, 로그 파일 작업 오류 세 가지
7. 사고 분석: CURRENT 리두 파일 삭제 — 실제 사고의 오류 스택 판독, 보호 모드가 복구 가능성을 정하는 방식 (재현하지 않음)

## 9장. Active Data Guard ① 실시간 조회와 DML 리다이렉션 ★🔒 (8개)
1. ADG 상태 확인 — 두 표식으로 ADG 활성 확인, 사용 기록 조회 위치, 세션이 붙은 노드 확인
2. 읽기 일관성 검증 — Standby 조회가 커밋된 데이터만 보여 줌을 올바른 방법으로 검증, 잘못된 측정이 내는 결론
3. Standby에서 되는 것과 안 되는 것 — 쓰기 차단 확인과 그럼에도 되는 작업, 경계 기준
4. **DML 리다이렉션** — 읽기 전용 Standby에서 INSERT·UPDATE·DELETE 성공, 실제 실행 위치 검증
5. 리다이렉션의 제약 — SYS로 실패하는 이유, DDL이 대상이 아닌 이유, 점검 순서
6. 세션 지연 한도 — `STANDBY_MAX_DATA_DELAY` 설정, `ORA-03172`·`ORA-03174`·`ORA-03173` 구분
7. 지연 히스토그램 — `V$STANDBY_EVENT_HISTOGRAM`으로 지연 분포 판독, 적용 정지의 기록 방식
8. **대안 경로(옵션 미보유)** — Standby를 MOUNTED로 두었을 때 적용 지속 여부와 동기화 확인 방법

## 10장. Active Data Guard ② Far Sync와 Real-Time Cascading ★🔒 (7개)
1. Far Sync 노드 준비와 컨트롤 파일 — Primary에서 Far Sync용 컨트롤 파일 생성, 필요한 파일과 필요 없는 파일 구분
2. 인스턴스 기동과 역할 확인 — 파라미터 파일 작성, MOUNT 기동, `DATABASE_ROLE`·`CONTROLFILE_TYPE` 확인
3. SRL 실체화 — 컨트롤 파일과 함께 상속된 SRL 정의, 파일이 없는 상태를 `CLEAR LOGFILE`로 해결
4. Oracle Net 구성 — Far Sync 정적 등록과 세 노드 간 이름 해석, 정적 등록이 필수인 이유
5. **리두 경로 전환** — Primary 목적지를 Far Sync로 변경, 세 노드에서 리두 흐름 추적, 변경 순서를 어겼을 때의 결과
6. 보호 모드 상향과 Far Sync의 정체 — MAXIMUM AVAILABILITY 상향, 세 노드 값이 다른 이유, Far Sync가 할 수 있는 것과 없는 것
7. Cascading 규칙과 원복 — Standby가 다른 Standby로 전달하는 계단식 설정 규칙, 실습 환경 원복

## 11장. Snapshot Standby ★ (7개)
1. 전제 조건 확인 — FRA·플래시백 상태 판독과 전환 후 비교용 기준값 기록
2. **전환 실패와 성공** — MRP가 도는 채로 전환해 `ORA-38784` 확인, 원인 해소 후 전환
3. 복원 지점 읽기 — 자동 생성된 보장 복원 지점의 이름·SCN·보장 여부·크기 해석
4. 열고 쓰기 — CDB·PDB를 열고 실제로 쓰기, PDB가 따라 열리지 않음 확인
5. 전환 중의 관찰 — 적용은 멈추고 수신은 계속됨, 두 지연이 갈라지고 FRA에 FLASHBACK LOG가 생김
6. **되돌리기** — Physical Standby로 복귀 후 ADG 상태로, 여는 순서를 어긴 `ORA-10456` 재현과 교정
7. 검증과 정리 — Snapshot에서 쓴 데이터는 사라지고 그동안의 Primary 변경은 적용되었는지 확인

## 12장. Logical Standby와 SQL Apply ★ (7개)
1. 전제 조건 점검 — `DBA_LOGSTDBY_*` 뷰로 지원 여부·고유 식별자·스킵 규칙 확인
2. LogMiner 딕셔너리 만들기 — `DBMS_LOGSTDBY.BUILD` 전후 비교, 딕셔너리가 리두로 전달되는 구조
3. **전환** — 순서를 어겨 멈춘 원인을 밝히고 해결, 전환 후 네 값의 변화 판독
4. SQL Apply 기동과 복제 확인 — 여섯 종류 프로세스와 상태 메시지, 일반 스키마와 SYSTEM 스키마의 차이
5. 골라서 복제하기와 조정 — SKIP 규칙으로 일부 제외, 지원되지 않는 타입 처리, SQL Apply 파라미터 변경과 원복
6. **데이터베이스 가드와 SYS 사고** — 가드 세 값이 막는 대상, SYS 예외가 복제를 깨뜨리는 사고 재현
7. 되살리기와 원복 — 깨진 SQL Apply를 단계적으로 복구하고 pre-logical 스냅샷으로 환경 원복

## 13장. Data Guard Broker 개요와 구성 생성 ★ (7개)
1. 전제 조건 점검 — Broker를 켜기 전 준비 상태, 손으로 만든 구성을 파라미터로 읽기
2. Broker 켜기 — `DG_BROKER_START=TRUE`와 DMON 확인, 오류가 `ORA-16525`에서 `ORA-16532`로 바뀌는 과정
3. **구성 만들기와 `ORA-16698`** — `CREATE CONFIGURATION`·`ADD DATABASE`, 손으로 해 둔 설정이 걸림돌이 되는 이유
4. 활성화와 인수 확인 — `ENABLE CONFIGURATION` 후 Broker가 재작성한 파라미터, 구성 파일과 Broker 로그
5. 상태 제어와 속성 — Broker 명령으로 적용 끄고 켜기, 속성으로 전송 방식 변경, SQL로 교차 확인
6. **Broker가 관리하는 것을 SQL로 바꾸면** — 파라미터를 SQL로 바꿨을 때의 결과와 실무 지침
7. 재기동 검증과 스냅샷 — 정상 종료 후 구성 유지 확인, 14~16장용 broker-ready 스냅샷 생성

## 14장. Broker 모니터링과 검증 명령 ★ (9개)
1. `VALIDATE DATABASE` 읽기 — 건강한 구성의 출력 항목별 해석, VERBOSE가 더 보여 주는 것
2. **SHOW와 VALIDATE의 차이** — 전송을 끄고 두 명령이 다른 답을 내는 것 확인
3. 모니터링 전용 속성 — 큐·전송 상태·대기 이벤트 조회, 조회 전용 속성과 설정 속성 구분
4. 적용 지연과 임계값 — `DelayMins`로 지연을 만들고 경고 관찰, `ApplyLagThreshold` 조정
5. V$ 뷰로 교차 확인 — Broker 요약을 SQL로 재확인, 뷰별 조회 위치 구분
6. 구성 내보내기 — `EXPORT CONFIGURATION` 결과물의 위치와 형태, 가져오기의 제약
7. Fast-Start Failover 켜고 끄기 — 전제 없이 켰을 때의 결과, 관측 전용 모드를 거친 해제 (관측자는 띄우지 않음)
8. **VALIDATE의 나머지 형태** — 여섯 가지 구문 전부 실행, 정적 등록을 잠시 제거해 `VALIDATE DATABASE`가 검사하지 않는 것 확인
9. Broker 로그 판독 — `drc<SID>.log`의 위치와 내용, Broker 화면에 없는 정보

## 15장. V$ 뷰 기반 모니터링과 문제 해결 ★ (7개)
1. 로그 파일과 SRL — `V$LOG`·`V$LOGFILE`·`V$STANDBY_LOG`의 STATUS를 역할별로 해석, 리두 흐름을 다섯 줄 SQL로 판정
2. 아카이브 목적지 — `V$ARCHIVE_DEST`와 `V$ARCHIVE_DEST_STATUS`의 관점 차이, `VALID_NOW`·`VALID_TYPE`·`VALID_ROLE` 판정
3. **전송 중단 재현과 진단** — Standby 리스너를 내려 층별 증상 확인, 복구가 `ReopenSecs`만큼 늦는 이유
4. 적용의 진행과 APPLIED — `V$MANAGED_STANDBY` 프로세스 구성, `V$ARCHIVED_LOG.APPLIED`와 `APPLIED_SEQ#`의 바른 해석
5. `LOG_ARCHIVE_TRACE` — 추적 활성화와 트레이스 파일 판독, 켤 때의 원칙과 되돌리는 절차
6. 상시 점검 스크립트 — 이 장의 지표를 한 번에 수집해 판정 규칙 적용, 역할별 스크립트가 필요한 이유
7. **Logical Standby 모니터링** — 역할이 바뀌면 비는 뷰, `V$LOGSTDBY_TRANSACTION` 추적, 멈춘 적용을 XID로 진단해 복구

## 16장. 역할 전환과 이후 운영 ★ (9개)
1. 전환 사전 점검 — `SWITCHOVER_STATUS`를 역할별로 판독하고 `VALIDATE DATABASE`로 최종 판정, 전환 30분 전 점검표 실행
2. **Switchover 실행** — DGMGRL `SWITCHOVER TO boston` 출력의 단계별 의미, 정적 등록이 쓰이는 지점
3. 전환 후 확인과 되돌리기 — 재작성된 파라미터 확인, 반대 방향 switchover로 chicago를 Primary로 복귀
4. **전환 거부 재현** — 전환이 거부되는 상황별 오류 구분, 실패한 명령이 상태를 바꾸지 않음 확인
5. **SQL 전환 사고와 복구** — Broker 구성에서 SQL로 전환했을 때 생기는 불일치와 복구, Broker 보호의 범위
6. 플래시백 준비 — 양쪽 FLASHBACK ON, 공간과 로그 파일 확인, Reinstate 전제
7. **Failover와 Reinstate** — Primary 강제 종료 후 Failover, 옛 Primary Reinstate, Switchover로 원래 역할 복귀
8. **관측자와 Fast-Start Failover 실제 발동** — 제3 호스트에 관측자 기동, Primary를 죽여 자동 전환과 자동 재편입 관찰
9. Standby를 백업에 활용 — Standby에서 받은 RMAN 백업을 Primary에서 사용, 카탈로그 없이 쓸 때 필요한 추가 절차

---

## 부록. 챕터별 요약

| 구분 | 챕터 | 실습 수 |
|---|---|---|
| 개념·구성 준비 | 1~4 | 22 |
| Standby 생성 | 5~6 | 14 |
| 운영·동기화 | 7~8 | 14 |
| Active Data Guard | 9~10 | 15 |
| 다른 유형의 standby | 11~12 | 14 |
| Broker | 13~14 | 16 |
| 모니터링·역할 전환 | 15~16 | 16 |
| **합계** | **16장** | **111** |

★(2노드 필요) 15개 챕터 / 🔒(ADG 옵션 필요) 2개 챕터 15개 실습.

1장 5개를 제외한 106개가 두 노드를 요구한다. 10장은 세 번째 노드(farsync-srv), 16장 실습 08은 관측자용 제3 호스트가 더 필요하다.
