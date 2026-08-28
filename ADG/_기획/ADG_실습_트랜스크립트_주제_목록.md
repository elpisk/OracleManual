# Oracle Database 19c Active Data Guard 교안 — 실습 트랜스크립트 주제 목록 (v1 초안)

**작성일**: 2026-08-26
**상태**: 확인 대기

- **형식**: SQL\*Plus / DGMGRL / 셸 세션 트랜스크립트. 프롬프트는 노드를 구분한다 — `SYS@chicago>`, `SYS@boston>`, `DGMGRL>`, `[oracle@chicago-srv ~]$`, `[oracle@boston-srv ~]$`
- **파일명**: `{N}장_실습_{NN}_{주제}.txt`
- **총 16장 / 99개**
- 각 파일 최소 1곳에 **"오류·이상 징후 발생 → 원인 파악 → 조치 → 재확인"** 흐름을 넣는다
- **★** = 두 노드가 동시에 살아 있어야 성립하는 실습 (전체의 대부분)
- **🔒** = Active Data Guard 옵션 라이선스가 필요한 실습. 미보유 환경 대안 경로를 트랜스크립트 후반에 함께 넣는다
- **공통 전제**: 개인 실습 환경 전용. 역할 전환·강제 종료·파라미터 변경·재기동이 포함된다
- **되돌리기 원칙**: 역할 전환 실습은 반드시 원래 역할로 되돌린 상태로 끝낸다. Snapshot standby는 physical standby로 복귀시킨다. Broker 구성은 실습마다 삭제하지 않고 13장에서 만든 것을 15·16장까지 이어 쓴다

---

## 1장. Data Guard 개요와 아키텍처 (5개)
1. 현재 구성 파악 — `V$DATABASE`의 `DATABASE_ROLE`·`PROTECTION_MODE`·`OPEN_MODE`, `DB_UNIQUE_NAME` 확인
2. Data Guard 관련 백그라운드 프로세스 식별 — `V$MANAGED_STANDBY`, `V$PROCESS`에서 NSS·MRP·RFS 확인
3. **라이선스 확인 실습** — `DBA_FEATURE_USAGE_STATISTICS`에서 Active Data Guard·Far Sync 사용 이력 조회, EE 기본 기능과의 구분
4. standby 유형 세 가지의 차이를 조회로 확인 — physical / logical / snapshot 각각의 `DATABASE_ROLE`·`OPEN_MODE` 조합 정리
5. 구성 전 점검표 실습 — 두 노드의 버전·엔디안·문자셋·시간대 일치 확인. 불일치가 있으면 무엇이 막히는지 정리

## 2장. 데이터 보호 모드와 리두 전송 서비스 ★ (5개)
1. 현재 보호 모드 확인과 세 모드의 요건 비교 — `V$DATABASE.PROTECTION_MODE`·`PROTECTION_LEVEL` 두 열의 차이 확인
2. `LOG_ARCHIVE_DEST_2` 속성 해부 — `SERVICE`·`SYNC/ASYNC`·`AFFIRM/NOAFFIRM`·`VALID_FOR`·`DB_UNIQUE_NAME` 각각을 바꿔 가며 `V$ARCHIVE_DEST` 변화 관찰
3. Maximum Availability로 전환 → 조건 미충족 상태에서 Maximum Protection 전환을 시도해 **거부되는 오류 재현** → SRL 구성 후 재시도
4. 보호 모드별 primary 동작 차이 관찰 — standby를 내린 상태에서 각 모드의 primary가 멈추는지 계속 도는지 확인(Maximum Protection의 위험성 실증)
5. `PROTECTION_MODE`와 `PROTECTION_LEVEL`이 어긋나는 상황 재현과 해소 — 전송이 끊겼을 때 LEVEL이 RESYNCHRONIZATION으로 떨어지는 것 확인

## 3장. Data Guard를 위한 Oracle Net 구성 ★ (6개)
1. `tnsnames.ora` 양쪽 동일 구성 — chicago·boston 두 항목 등록과 `tnsping` 검증
2. `listener.ora` 정적 등록 — `SID_LIST_LISTENER`에 `GLOBAL_DBNAME`·`SID_NAME`·`ORACLE_HOME` 지정. 정적 등록이 필요한 이유(NOMOUNT 상태 접속)
3. **정적 등록 없이 RMAN DUPLICATE를 시도해 실패 재현** → `ORA-12514` 계열 확인 → 정적 등록 후 재시도
4. `LOG_ARCHIVE_CONFIG`의 `DG_CONFIG` 설정과 누락 시 증상 확인
5. 패스워드 파일 복사와 검증 — `orapwd` 재생성, 양쪽 SYS 비밀번호 불일치 시 전송 실패 재현(`ORA-01017` 흐름)
6. 방화벽·포트 점검 — `firewalld` 규칙 확인, 1521 차단 상태에서의 전송 오류와 해소

## 4장. Primary 준비 — ARCHIVELOG·FORCE LOGGING·Standby Redo Log (6개)
1. DBCA silent 모드로 CDB 생성 — 설치 가이드 Step 그대로 수행하고 생성 로그 확인
2. ARCHIVELOG 모드 전환과 확인 — `V$DATABASE.LOG_MODE`, 아카이브 목적지 상태
3. FORCE LOGGING 활성화 — `nologging` 작업이 실제로 무시되는 것을 실증(`NOLOGGING` 테이블 생성 후 리두 발생량 비교)
4. **Standby Redo Log 개수 산정과 생성** — 공식(온라인 리두 그룹 수 + 1)을 적용하고, 크기가 온라인 리두와 다를 때 생기는 문제 재현
5. SRL을 만들지 않은 상태에서 실시간 적용을 시도해 실패 재현 → SRL 생성 후 재확인
6. 19c의 nologging 개선 모드 확인 — `STANDBY NOLOGGING FOR DATA AVAILABILITY` / `FOR LOAD PERFORMANCE` 차이 정리

## 5장. Physical Standby 생성 ① RMAN DUPLICATE (경로 지정 방식) ★ (7개)
1. Primary 파라미터 설정 — `LOG_ARCHIVE_DEST_1/2`, `LOG_ARCHIVE_DEST_STATE_n`, `FAL_SERVER`, `STANDBY_FILE_MANAGEMENT`, `DB_FILE_NAME_CONVERT`
2. Standby 초기 pfile 작성 — 최소 파라미터 구성과 `DB_UNIQUE_NAME` 지정
3. boston 인스턴스 NOMOUNT 기동과 접속 확인
4. **`DUPLICATE TARGET DATABASE FOR STANDBY FROM ACTIVE DATABASE` 실행** — 전체 로그를 남기고 단계별 동작 해설
5. convert 파라미터를 빠뜨린 채 DUPLICATE를 실행해 **파일 경로 오류 재현** → 파라미터 추가 후 재실행
6. 생성 결과 검증 — 데이터 파일 목록·SRL·컨트롤 파일 유형(`V$DATABASE.CONTROLFILE_TYPE`) 확인, DBID가 primary와 같음을 확인
7. `DBMS_DBCOMP.DBCOMP`로 primary·standby 블록 비교 수행과 결과 판독

## 6장. Physical Standby 생성 ② OMF 방식 ★ (6개)
1. OMF 파라미터 이해와 설정 — `DB_CREATE_FILE_DEST`, `DB_CREATE_ONLINE_LOG_DEST_n`, `DB_RECOVERY_FILE_DEST`
2. OMF를 켠 상태로 DBCA silent CDB 생성 — 자동 생성된 경로 구조 확인(`/u03/app/oracle/oradata/CHICAGO/`)
3. OMF 방식 standby 초기 pfile 작성 — convert 파라미터가 없는 최소 구성
4. **OMF 방식 DUPLICATE 실행**과 자동 배치 결과 확인 — `V$DATAFILE.NAME`으로 boston 경로가 자동 생성된 것 확인
5. 두 방식 대조 실습 — 5장 결과와 6장 결과의 파일 경로·파라미터·명령 길이를 표로 정리
6. OMF 환경에서 데이터 파일을 추가했을 때 standby에 자동 반영되는 것 확인 → `STANDBY_FILE_MANAGEMENT=MANUAL`로 바꿔 **반영 실패 재현** → AUTO 복귀

## 7장. Redo Apply 기동과 동기화 검증 ★ (7개)
1. MRP 기동 — `ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT`와 `V$MANAGED_STANDBY` 확인
2. 실시간 적용(real-time apply) 활성화 — `USING CURRENT LOGFILE` 유무에 따른 동작 차이 관찰
3. 동기화 검증 절차 — primary에서 로그 스위치 → `V$ARCHIVED_LOG.APPLIED` 확인 → 양쪽 시퀀스 대조
4. `V$DATAGUARD_STATS`로 transport lag / apply lag 판독 — 두 지표가 각각 무엇을 재는지 구분
5. **부하를 걸어 apply lag을 만들고 해소되는 과정 관찰** — 대량 DML 후 지연 증가와 회복
6. MRP를 중지한 채 리두를 쌓았다가 재기동해 따라잡는 과정 확인 — 갭 해소(FAL) 동작
7. **아카이브 로그를 의도적으로 삭제해 갭을 만들고 복구** — `V$ARCHIVE_GAP` 조회, FAL로 자동 해소되지 않는 경우의 수동 조치

## 8장. Primary 구조 변경의 Standby 반영 ★ (6개)
1. 테이블스페이스 추가 시 standby 자동 반영 확인 (`STANDBY_FILE_MANAGEMENT=AUTO`)
2. 데이터 파일 추가·크기 변경의 반영 확인
3. **수동 개입이 필요한 변경 재현** — 온라인 리두 로그 그룹 추가·삭제 후 standby에서 별도 조치가 필요한 것 확인
4. 임시 파일 추가가 standby에 반영되지 않는 경우와 조치
5. 파라미터 변경의 전파 여부 확인 — spfile 변경이 standby에 자동 반영되지 않는 것과 broker 사용 시의 차이
6. 데이터 파일을 standby에서 잃어버린 상황 재현 → primary에서 해당 파일만 RMAN으로 복구해 standby에 적용

## 9장. Active Data Guard ① 실시간 조회와 DML 리다이렉션 ★🔒 (7개)
1. standby를 OPEN READ ONLY로 열고 MRP를 함께 돌리는 구성 — Real-Time Query 활성화
2. 읽기 전용 상태에서 조회 수행과 primary 결과 대조 — 일관성 확인
3. **읽기 전용 standby에서 DML을 시도해 오류 재현** (`ORA-16000`) → `ADG_REDIRECT_DML` 설정 후 성공 확인
4. Global Temporary Table 갱신 실습 — standby에서 GTT에 DML이 되는 이유
5. Private Temporary Table 사용 실습
6. PL/SQL 리다이렉션 설정과 동작 확인
7. **대안 경로(옵션 미보유)** — standby를 MOUNT로 두고 primary에서 `V$DATAGUARD_STATS`·`V$ARCHIVED_LOG`로 동기화를 확인하는 방법

## 10장. Active Data Guard ② Far Sync와 Real-Time Cascading ★🔒 (5개)
1. Far Sync 인스턴스의 구조 이해 — 컨트롤 파일과 SRL만 있고 데이터 파일이 없음을 확인
2. RMAN으로 far sync 인스턴스 생성
3. SQL로 far sync 인스턴스 생성 (대안 절차)
4. far sync를 경유한 zero data loss 구성 검증 — primary → far sync(SYNC) → standby(ASYNC) 경로 확인
5. **대안 경로(옵션 미보유)** — Real-Time Cascading만으로 다단 구성하기. 캐스케이딩 standby 설정과 제약 확인

## 11장. Snapshot Standby ★ (5개)
1. physical standby를 snapshot standby로 전환 — `CONVERT TO SNAPSHOT STANDBY`와 전제 조건(Flashback, FRA)
2. snapshot 상태에서 갱신 작업 수행 — 테스트 데이터 적재와 DDL
3. 전환 중에도 리두가 계속 수신되는 것 확인 — 수신은 되지만 적용되지 않음을 `V$ARCHIVED_LOG`로 확인
4. physical standby로 복귀 — `CONVERT TO PHYSICAL STANDBY`, 갱신분이 사라지는 것 확인
5. **FRA 공간 부족 상태에서 전환을 시도해 실패 재현** → 공간 확보 후 재시도. 복귀까지 마쳐 원상 복구

## 12장. Logical Standby와 SQL Apply ★ (6개)
1. logical standby가 필요한 상황 판별 — physical과의 차이를 표로 정리
2. 지원되지 않는 데이터 유형 사전 점검 — `DBA_LOGSTDBY_UNSUPPORTED` 조회
3. physical standby로부터 logical standby 생성 절차 수행
4. SQL Apply 기동·중지와 상태 확인 — `V$LOGSTDBY_PROCESS`, `V$LOGSTDBY_STATS`
5. SQL Apply 필터링 — `DBMS_LOGSTDBY.SKIP`으로 특정 스키마·테이블 제외
6. **지원되지 않는 유형의 테이블을 갱신해 SQL Apply가 멈추는 상황 재현** → `DBA_LOGSTDBY_EVENTS`로 원인 확인 → SKIP 등록 후 재기동

## 13장. Data Guard Broker 개요와 구성 생성 ★ (6개)
1. broker 활성화 — `DG_BROKER_START=TRUE`, 구성 파일 경로 지정과 파일 생성 확인
2. DGMGRL 접속과 구성 생성 — `CREATE CONFIGURATION`, `ADD DATABASE`
3. 구성 활성화 — `ENABLE CONFIGURATION`과 상태 확인
4. broker가 관리하는 파라미터 확인 — SQL로 직접 바꿨을 때 **broker가 되돌리거나 경고하는 것 재현**
5. 데이터베이스 속성 조회와 변경 — `EDIT DATABASE ... SET PROPERTY`
6. broker 구성 파일 이중화와 손상 시 복구 절차

## 14장. Broker 모니터링과 검증 명령 ★ (6개)
1. `SHOW CONFIGURATION` 판독 — 구성 상태와 각 DB의 역할·전송 지연
2. `SHOW DATABASE VERBOSE` 판독 — 속성 목록과 상태 보고
3. `VALIDATE DATABASE` 수행 — 역할 전환 준비 상태 점검 항목 해석
4. `VALIDATE DATABASE DATAFILE` / `VALIDATE DATABASE SPFILE` 수행과 결과 판독
5. `VALIDATE NETWORK CONFIGURATION` / `VALIDATE STATIC CONNECT IDENTIFIER` 수행 — 정적 등록이 잘못된 상태를 만들어 **검증 실패 재현** 후 해소
6. broker 로그(`drc<SID>.log`) 판독 — 구성 변경과 오류가 남는 위치 확인

## 15장. V$ 뷰 기반 모니터링과 문제 해결 ★ (7개)
1. SRL 상태 확인 — `V$LOGFILE`·`V$STANDBY_LOG`의 STATUS 열 해석
2. 아카이브 목적지 상태 진단 — `V$ARCHIVE_DEST`의 `STATUS`·`ERROR`·`VALID_NOW` 판독
3. **전송 중단 상황 재현과 진단** — standby 리스너를 내려 전송을 끊고 `V$ARCHIVE_DEST.ERROR` 확인 → 복구 후 재개 확인
4. `LOG_ARCHIVE_TRACE` 수준별 추적 활성화와 트레이스 파일 판독
5. `V$DATAGUARD_STATS` / `V$DATAGUARD_STATUS`로 현재 상태와 최근 메시지 확인
6. **logical standby 전용 모니터링** — `V$LOGSTDBY_TRANSACTION`으로 적용 중인 트랜잭션 추적 (실습 07 로 반영 완료)
7. 상시 점검 스크립트 작성 — 위 지표를 한 번에 수집하고 임계값으로 판정하는 절차 고정

## 16장. 역할 전환과 이후 운영 ★ (9개)
1. Switchover 사전 점검 — `VALIDATE DATABASE`와 `V$DATABASE.SWITCHOVER_STATUS` 판독
2. **DGMGRL로 switchover 수행** — `SWITCHOVER TO boston`, 전 과정 로그와 양쪽 역할 확인
3. SQL로 switchover 수행 (broker 없는 절차) — 명령 수가 늘어나는 것과 각 단계의 의미
4. **switchover 조건 미충족 상태를 만들어 거부 재현** — 활성 세션이나 SRL 미구성 상태에서 시도 → 해소 후 재수행
5. **원래 역할로 되돌리는 switchover** — 실습 종료 시 반드시 chicago가 primary인 상태로 복귀
6. Failover 수행 — primary를 강제 종료한 뒤 `FAILOVER TO boston`, 데이터 손실 여부 확인
7. Failover 이후 재구성 — `REINSTATE DATABASE`로 옛 primary를 standby로 복구, Flashback 전제 조건 확인
8. Fast-Start Failover 구성 — observer 기동, `FastStartFailoverThreshold` 설정, 자동 전환 발동 조건 확인과 실제 발동 관찰
9. Data Guard 환경의 백업 — standby에서 RMAN 백업을 받아 primary에서 복원에 쓸 수 있음을 확인, recovery catalog의 `DB_UNIQUE_NAME` 연결 확인

---

## 부록. 챕터별 요약

| 구분 | 챕터 | 실습 수 |
|---|---|---|
| 개념·구성 준비 | 1~4 | 22 |
| Standby 생성 | 5~6 | 13 |
| 운영·동기화 | 7~8 | 13 |
| Active Data Guard | 9~10 | 12 |
| 다른 유형의 standby | 11~12 | 11 |
| Broker | 13~14 | 12 |
| 모니터링·역할 전환 | 15~16 | 16 |
| **합계** | **16장** | **99** |

★(2노드 필요) 15개 챕터 / 🔒(ADG 옵션 필요) 2개 챕터 12개 실습 — 옵션이 필요한 실습에는 전부 대안 경로를 함께 싣는다.

**1장 5개를 제외한 94개가 두 노드를 요구한다.** 챕터 목록 4-1절의 환경 선택지(A/B/C)가 정해지기 전에는 트랜스크립트 작성에 착수할 수 없다.
