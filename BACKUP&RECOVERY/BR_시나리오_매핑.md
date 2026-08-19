# Oracle Backup & Recovery 교안 — 원본 시나리오 매핑표 (v2)

> v1 → v2 변경: `Clone DB.pdf` 2개 시나리오 추가(E절 신설), Data Pump·Flashback·Block Corruption의 챕터 배정을 16→19장 체제에 맞게 재조정. (2026-08-19)

원본 PDF 19개에 담긴 시나리오 전체를 챕터에 배정한 표. 각 챕터 작성 에이전트는 **자기 챕터에 배정된 시나리오가 실린 원본 PDF만 읽으면 된다**(전체를 다 읽지 말 것 — 세션 한도 소진).

- 원본 위치: `C:\Users\itwill\Downloads\OracleManual\BACKUP&RECOVERY\` (단, `Clone DB.pdf`는 현재 `C:\Users\itwill\Downloads\4. Backup&Recovery\`에만 있음 — 착수 전 복사)
- 확장 방침·표준 8단계 템플릿·수정 대상 목록은 `BR_챕터_목록.md` 2절 참고
- 총계: NOARCHIVELOG 24 + ARCHIVELOG 35 + RMAN 21 + 가용성 11 + 복제 2 = **93개 시나리오/주제**

---

## A. User Managed — NOARCHIVELOG (BNR_01~05, 24개)

전 시나리오 공통 전제: `LOG_MODE = NOARCHIVELOG`, 백업은 `shutdown immediate` 후 cold(close/offline) 백업.

| 원본 | 시나리오 | 원본 PDF | 배정 장 |
|---|---|---|---|
| 1 | 특정 데이터파일 손상 — 백업 이후 리두정보 **있음** (완전복구 가능) | BNR_01 | 4 |
| 2 | 특정 데이터파일 손상 — 백업 이후 리두정보 **없음** (불완전복구) | BNR_01 | 4 |
| 3 | 백업 받지 않은 테이블스페이스의 데이터파일 손상 — 리두 O (drop tablespace 불가) | BNR_02 | 4 |
| 4 | 백업 받지 않은 테이블스페이스의 데이터파일 손상 — 리두 X | BNR_02 | 4 |
| 5 | SYSTEM 데이터파일 손상 — 리두 O | BNR_02 | 4 |
| 6 | SYSTEM 데이터파일 손상 — 리두 X | BNR_02 | 4 |
| 7 | UNDO 데이터파일 손상 — 리두 O | BNR_02 | 5 |
| 8 | UNDO 데이터파일 손상 — 리두 X | BNR_02 | 5 |
| 9 | 트랜잭션 진행 중 UNDO 데이터파일 손상 — 리두 X | BNR_03 | 5 |
| 10 | TEMP 파일 손상 | BNR_03 | 5 |
| 11 | 모든 DF/CF/RF가 있는 디스크 자체 손상 | BNR_03 | 5 |
| 12 | 백업본에 리두로그 파일이 포함되지 않은 경우 | BNR_04 | 5 |
| 13 | DF·RF 정상, 컨트롤파일만 손상 — 복구(Binary 백업본) | BNR_04 | 6 |
| 14 | DF·RF 정상, 컨트롤파일만 손상 — 복구(Trace 재생성) | BNR_04 | 6 |
| 15 | DF·RF 정상, 컨트롤파일만 손상 — 정상 종료 상태 | BNR_04 | 6 |
| 16 | DF·RF 정상, 컨트롤파일만 손상 — 비정상 종료 상태 | BNR_04 | 6 |
| 17 | 데이터파일 + 컨트롤파일 손상 — DB 정상 종료, 리두 O | BNR_04 | 6 |
| 18 | 컨트롤파일·데이터파일 유실, 리두 X, 비정상 종료 | BNR_05 | 6 |
| 19 | DB 정상 종료 상태에서 리두로그 + 컨트롤파일 손상 | BNR_05 | 7 |
| 20 | 리두로그 + 컨트롤파일 손상으로 DB가 비정상 종료된 경우 | BNR_05 | 7 |
| 21 | 백업한 컨트롤파일 내용과 현재 데이터파일 정보가 달라진 경우 | BNR_05 | 7 |
| 22 | DB 정상 종료 후 INACTIVE 로그 파일 삭제 | BNR_05 | 7 |
| 23 | INACTIVE 로그 파일 삭제 후 DB 비정상 종료 | BNR_05 | 7 |
| 24 | CURRENT 리두로그 파일 삭제 | BNR_05 | 7 |

### 정교화 시 추가할 결손 케이스
- **SYSAUX 데이터파일 손상** (원본에 없음) → 4장. SYSTEM과 달리 일부 기능만 영향받는 점 대비.
- **읽기 전용 테이블스페이스의 데이터파일 손상** → 5장. 백업 시점 이후 변경이 없어 리두 없이도 복원만으로 끝나는 케이스.
- **`shutdown abort` 후 백업본 사용 시 문제** → 3장(백업 방법론)에서 다루고 6장에서 참조.

---

## B. User Managed — ARCHIVELOG (BNR_06~11, 35개)

| 원본 | 시나리오 | 원본 PDF | 배정 장 |
|---|---|---|---|
| 1 | Archive log mode 의 변경 (NOARCHIVELOG → ARCHIVELOG) | BNR_06 | **2** |
| 2 | 데이터베이스 운영 중 offline 되는 데이터파일 손상 시 복구 | BNR_06 | 8 |
| 3 | 오프라인 상태 테이블스페이스가 손상되었을 경우 | BNR_06 | 8 |
| 4 | 데이터베이스 정상 종료 후 여러 데이터파일이 손상되었을 경우 | BNR_06 | 8 |
| 5 | 백업 받지 않은 테이블스페이스에 데이터파일 손상 | BNR_07 | 8 |
| 6 | 백업 받지 않은 TS의 DF 손상 시 기존 위치가 아닌 새 위치로 복구 | BNR_07 | 8 |
| 7 | 특정 데이터파일 손상 — 기존 위치가 아닌 새 위치로 복구 | BNR_07 | 8 |
| 8 | TS에 속한 여러 DF 중 특정 file만 손상되었을 경우 | BNR_07 | 8 |
| 9 | 모든 데이터파일 손상되었을 경우 복구 | BNR_08 | 9 |
| 10 | 모든 데이터파일 손상 — 새 위치로 복구 | BNR_08 | 9 |
| 11 | UNDO 데이터파일 손상 | BNR_08 | 9 |
| 12 | 운영 중 UNDO 데이터파일 손상 | BNR_08 | 9 |
| 13 | 복구 작업에 필요한 archive log file이 한쪽에 없을 경우 (다중 아카이브 대상) | BNR_08 | 9 |
| 14 | 모든 DF 손상 + 필요한 archive 삭제됐지만 redo log가 있어 문제없이 복구 | BNR_09 | 9 |
| 15 | 복구에 필요한 archive log file이 손상 → 완전복구 실패, 불완전 복구 | BNR_09 | 10 |
| 16 | DF 삭제 + 모든 아카이브 삭제 — 불완전 복구 (open/online/hot backup) | BNR_09 | 10 |
| 17 | DF 삭제 + 모든 아카이브 삭제 — 불완전 복구 (close/offline/cold backup) | BNR_09 | 10 |
| 18 | DB 정상 종료 후 INACTIVE redo log file 삭제된 경우 | BNR_09 | 10 |
| 19 | DB 운영 중 INACTIVE redo log file 삭제된 경우 | BNR_09 | 10 |
| 20 | CURRENT redo log file 삭제 후 DB 정상 종료 | BNR_10 | 11 |
| 21 | CURRENT redo log file 삭제 후 DB 비정상 종료 (일관성 없는 백업, online/hot) | BNR_10 | 11 |
| 22 | 운영 중 CURRENT redo log file 삭제 | BNR_10 | 11 |
| 22.1 | 22번 시나리오를 `clear unarchived` 로 복구 | BNR_10 | 11 |
| 23 | DB 정상 종료 후 controlfile 손상 시 복구 | BNR_10 | 11 |
| 24 | DB 정상 종료 후 controlfile 손상 시 복구 (컨트롤파일 재생성) | BNR_10 | 11 |
| 25 | DB 비정상 종료 후 controlfile 손상 시 복구 (컨트롤파일 재생성) | BNR_10 | 11 |
| 26 | CFs 장애 복구 — 백업한 CFs 내용과 현재 DFs 정보가 달라졌을 경우 | BNR_11 | 11 |
| 27 | 모든 DFs, CFs 손상된 경우 복구 | BNR_11 | 12 |
| 28 | System datafile, CFs 삭제된 경우 복구 | BNR_11 | 12 |
| 29 | RFs, CFs 손상되었을 경우 복구 | BNR_11 | 12 |
| 30 | 일반 DFs, inactive RF, CFs 손상된 경우 복구 | BNR_11 | 12 |
| 31 | 일반 DFs, inactive RF, CFs 손상 후 log switch가 발생했을 경우(hang 상태) 복구 | BNR_11 | 12 |
| 32 | 모든 DFs, CFs, RFs 삭제 — 백업 이후 아카이브 **있을** 경우 | BNR_11 | 12 |
| 33 | 모든 DFs, CFs, RFs 삭제 — 아카이브 **없을** 경우, open backup 사용 | BNR_11 | 12 |
| 34 | 모든 DFs, CFs, RFs 삭제 — 아카이브 없을 경우, close backup 사용 (DFs, CFs만 복원) | BNR_11 | 12 |

### 정교화 시 추가할 결손 케이스
- **아카이브 대상 디스크 full로 인한 DB hang** (`ORA-00257`) → 2장 또는 9장. FRA 용량 관리와 직결되는데 원본에 없음.
- **Cancel-based / Time-based / SCN-based / Log sequence-based 불완전 복구 4종 비교** → 10장. 원본은 사실상 cancel 기반만 다룸.
- **`RESETLOGS` 이후 즉시 전체 백업의 필요성** → 10장에서 명시.
- **읽기 전용 테이블스페이스 복구** → 8장.

---

## C. RMAN — Recovery Catalog 사용 (BNR_12~14, 21개)

| 원본 | 시나리오 | 원본 PDF | 배정 장 |
|---|---|---|---|
| 1 | Setting Recovery catalog (listener.ora/tnsnames.ora 구성 포함) | BNR_12 | **13** |
| 2 | DF 유실로 인한 복구 | BNR_12 | 15 |
| 3 | 일반 TS를 다른 위치에 복구 | BNR_12 | 15 |
| 4 | System DF 손상되었을 경우 복구 | BNR_12 | 15 |
| 5 | 모든 DFs 손상되었을 경우 복구 | BNR_12 | 15 |
| 6 | 모든 DFs 손상으로 새로운 위치로 복구 | BNR_12 | 15 |
| 7 | 백업받지 않은 TS의 DF 손상 복구 | BNR_12 | 15 |
| 8 | TS에 속한 여러 DF 중 일부분이 손상된 경우 복구 | BNR_12 | 15 |
| 9 | Undo DF 손상의 복구 | BNR_13 | 15 |
| 10 | 정상 종료 후 CF 손상의 복구 (백업본 사용) | BNR_13 | 15 |
| 11 | CF 손상의 복구 (CF 재생성) | BNR_13 | 15 |
| 12 | 모든 DFs, CF 손상되었을 경우 복구 | BNR_13 | 15 |
| 13 | CF 와 모든 RFs 손상의 복구 | BNR_13 | 15 |
| 14 | 모든 DFs, CFs, RFs 손상의 복구 | BNR_13 | 15 |
| 15 | 시간을 기준으로 불완전 복구 (Time based recovery) | BNR_13 | 15 |
| 16 | TS에 속한 여러 DF 중 일부분이 손상된 경우 복구 | BNR_13 | 15 |
| 17 | Recovering Tables (특정 TS만 이용해 복제 DB 생성 후 복구) | BNR_14 | **16** |
| 18 | RMAN 암호화 | BNR_14 | 14 |
| 19 | Image Copy | BNR_14 | 14 |
| 20 | 파라미터 파일(spfile, pfile) 손상되었을 경우 복구 | BNR_14 | **16** |
| 21 | Incremental Backup | BNR_14 | 14 |

### 정교화 시 추가할 결손 케이스 / 보강
- **Nocatalog 모드와 Catalog 모드 비교** → 13장. 원본은 catalog 전제로만 진행.
- **`SHOW ALL` / `CONFIGURE` 영구 설정, Retention Policy, Channel 병렬화** → 13장. 원본에 거의 없음.
- **`LIST BACKUP` / `REPORT NEED BACKUP` / `REPORT OBSOLETE` / `DELETE OBSOLETE` / `CROSSCHECK`** → 13장.
- **`RESTORE ... PREVIEW`, `VALIDATE DATABASE`, `BACKUP VALIDATE`** → 14장. 19c 실무 필수인데 원본에 없음.
- **Block Media Recovery (`RECOVER ... BLOCK`)** → 16장에서 BNR_15의 Block Corruption과 연결.
- **압축 백업(`AS COMPRESSED BACKUPSET`), 백업 조각 크기, `BACKUP AS COPY`** → 14장.
- **RMAN 시15(Time based)에 더해 SCN based / Log sequence based** → 15장.

---

## D. Database Availability (BNR_15~16, 11개 주제)

| 원본 | 주제 | 원본 PDF | 배정 장 |
|---|---|---|---|
| — | Block Corruption — `dd` 블록 훼손 → `VALIDATE DATAFILE` 탐지 → **Data Recovery Advisor**(`LIST/ADVISE/REPAIR FAILURE`) → Block Media Recovery | BNR_15 | **16** |
| — | Data Pump (디렉터리 객체, expdp schemas, impdp tables) | BNR_15 | **19** |
| — | dbms_metadata (DDL 추출) | BNR_15 | **19** |
| — | Flashback Query | BNR_16 | **18** |
| — | Flashback Version Query | BNR_16 | **18** |
| — | Flashback Table | BNR_16 | **18** |
| — | Flashback Data Archive | BNR_16 | **18** |
| — | Flashback Database | BNR_16 | **18** |
| — | Flashback Drop Table (휴지통) | BNR_16 | **18** |
| — | Cursor Sharing | BNR_16 | 18 (부록 트랜스크립트만) |

> **Cursor Sharing 처리**: 백업·복구와 직접 관련이 없다(공유 커서/바인드 변수 주제로, ADMIN 과정 성능 튜닝 챕터 영역). 18장 본문에서는 제외하고, 원본 보존 차원에서 트랜스크립트 1개만 부록 성격으로 남긴다.

### 16장(블록 손상) 보강
- 원본 BNR_15는 `dd if=/dev/zero ... seek=364 count=2`로 블록 2개를 훼손한 뒤 **Data Recovery Advisor**로 자동 복구한다. 이 흐름이 핵심이므로 그대로 살리되, 아래를 추가한다.
  - `DBVERIFY`(dbv)를 이용한 오프라인 블록 검증 (결손 보완)
  - `v$database_block_corruption` / `v$backup_corruption` 조회 (결손 보완)
  - `DB_BLOCK_CHECKING` / `DB_BLOCK_CHECKSUM` 파라미터로 손상 조기 탐지 (결손 보완)
  - DRA 자동 복구가 불가능할 때의 수동 `RECOVER DATAFILE n BLOCK m` (원본 repair script에 이미 등장)

### 19장(Data Pump) 보강 — 원본이 1~2페이지뿐이라 대폭 확장 필요
원본에 있는 것은 디렉터리 객체 생성/권한, `expdp schemas=hr`, `impdp tables=hr.emp`, dbms_metadata 정도다. 아래를 결손 보완으로 채운다.

| 구분 | 추가 항목 |
|---|---|
| 아키텍처 | Master/Worker 프로세스, Master Table, `DATA_PUMP_DIR` 기본 디렉터리 |
| 모드 | FULL / SCHEMAS / TABLES / TABLESPACES / TRANSPORT_TABLESPACES |
| 주요 파라미터 | `PARALLEL`, `COMPRESSION`, `ENCRYPTION`, `ESTIMATE`, `CONTENT`, `INCLUDE`/`EXCLUDE`, `QUERY`, `LOGTIME` |
| 재배치 | `REMAP_SCHEMA`, `REMAP_TABLESPACE`, `REMAP_DATAFILE`, `TRANSFORM` |
| 일관성 | `FLASHBACK_SCN`, `FLASHBACK_TIME` — 18장 Flashback과 연결 |
| 버전 호환 | `VERSION=` (11g ↔ 19c 이관, BNR_test 과제와 직결) |
| 네트워크 | `NETWORK_LINK`를 이용한 dump 파일 없는 직접 이관 |
| Job 제어 | `dba_datapump_jobs`, `ATTACH`, `STATUS`, `STOP_JOB`, `KILL_JOB` |
| 비교 | 구 `exp`/`imp`와의 차이, 물리 백업(3장)과의 역할 구분 |
| 19c 주의 | CDB/PDB에서의 `expdp` 접속 방식(서비스명 지정) — Note 박스 |

---

## E. 복제 데이터베이스 (Clone DB.pdf, 2개)

| 원본 | 시나리오 | 배정 장 |
|---|---|---|
| 1 | **CLONE DB 생성하기** (수동 복제) — 백업 데이터파일·아카이브를 `clone` 디렉터리로 복사 → `create pfile` → `alter database backup controlfile to trace` → pfile 수정(`db_name='clone'`, `control_files`, `log_archive_dest_1`) → `CREATE CONTROLFILE SET DATABASE "CLONE" RESETLOGS ARCHIVELOG` → `recover database using backup controlfile until cancel`(auto) → `alter database open resetlogs` → TEMP 파일 추가 → 복제 DB 삭제(`shutdown abort`, diag 디렉터리 정리, `. oraenv`로 SID 복귀) | 17 |
| 2 | **RMAN을 이용한 Oracle DB 복제 (Active Duplication)** — `orapwd`로 복제 DB 패스워드 파일 생성 → 소스 listener.ora에 SID 추가 → tnsnames.ora(T1/C1/N1) 구성 → 복제 DB 디렉터리 생성 → `initNEWDB.ora` 최소 파라미터 → `startup nomount` → `rman target ... auxiliary ...` → `DUPLICATE TARGET DATABASE TO NEWDB FROM ACTIVE DATABASE SPFILE SET ... NOFILENAMECHECK` | 17 |

### 정교화 시 추가할 결손 케이스
- **백업 기반 복제** — `DUPLICATE ... BACKUP LOCATION '<경로>'` (네트워크 없이 복제, 결손 보완)
- **`nid` 유틸리티**로 DBID / DB_NAME 변경 (결손 보완) — 수동 복제본을 정식 별도 DB로 승격할 때 필요
- **TSPITR** — 보조 인스턴스를 이용한 테이블스페이스 시점 복구 (결손 보완). 16장 `RECOVER TABLE`의 내부 동작을 손으로 풀어 보여주는 자리
- **`DUPLICATE ... UNTIL TIME/SCN`** 으로 특정 시점 복제 (결손 보완)
- 원본 시나리오 1은 `until cancel` 복구에서 `auto`를 입력해 넘어가는데, **왜 `using backup controlfile`이 필요한지**(재생성한 컨트롤파일에는 복구 종료 지점 정보가 없음)를 설명으로 보강한다
- 복제 DB 삭제 절차가 `rm -r`로 거칠게 되어 있다. `DROP DATABASE` 명령을 이용한 정식 절차를 병기한다

---

## F. 종합 실습 과제 (BNR_test, BNR_test_add)

| 원본 | 과제 | 19c 재구성 방향 |
|---|---|---|
| test-1 | 11g(oel5v8)의 scott schema를 oelclone 서버로 이전 | Data Pump 버전 호환(`VERSION=`) 주제로 재구성 |
| test-2 | emp table 실수로 truncate → 복구 절차 | Flashback Drop은 truncate에 안 통함 → RMAN Table Recovery / TSPITR로 유도 |
| test-3 | dept에 데이터 입력 → commit → loc 수정 → `ALTER SYSTEM ARCHIVE LOG CURRENT` → 이전 'Seoul' 시점으로 복구 | Flashback Query / Time-based 불완전 복구 두 경로 비교 |
| test-4 | emp1 생성 → 파일·블록 번호 기록 → 블록 손상 → 복구 | Block Media Recovery (`RECOVER ... BLOCK`) |
| add-1 | oel7v9에서 Incremental Backup Level 0/1 수행 | 블록 변경 추적(Block Change Tracking) 추가 |

챕터 19개 완료 후 `종합실습과제.docx` / `종합실습과제_모범답안.docx` 2종으로 작성. 원본 5문항을 12~15문항으로 확장하며, 확장분에 **DB 복제(17장)** 와 **Data Pump 버전 호환 이관(19장)** 과제를 포함한다.
