# Oracle Backup & Recovery 교안 — 실습 트랜스크립트 주제 목록 (v2)

> v1 → v2 변경: 16장 하나에 몰려 있던 주제를 16~19장으로 분리. 복제(17장)·Flashback(18장)·Data Pump(19장) 신설. 총 117개 → **142개**. (2026-08-19)

- **소스**: `BNR_01~16.pdf` + `Clone DB.pdf` 원본 시나리오 93개 + 결손 보완 케이스 (`BR_시나리오_매핑.md` 참고)
- **형식**: SQL*Plus / RMAN / 셸 세션 트랜스크립트
  - 프롬프트 표기 통일: `SYS@orcl>` (SQL*Plus, SYSDBA), `HR@orcl>` (일반 사용자), `RMAN>` (RMAN), `[oracle@oel7v9r1 ~]$` (셸)
  - 경로 표기 통일: `/u01/app/oracle/oradata/ORCL/`, `$ORACLE_HOME = /u01/app/oracle/product/19.3.0/dbhome_1`
  - 한글 주석은 `--` 로 달고, 명령 위에 붙인다
- **필수 구조**: 모든 트랜스크립트는 `BR_챕터_목록.md` 2-1절의 **표준 8단계 템플릿**(개요 → 사전조건 → 초기상태 → 장애유발 → 증상 → 진단 → 복구 → 검증)을 따른다
- **오류 흐름**: 파일마다 최소 1곳에 "오류 발생 → 원인 파악 → 수정" 흐름을 넣는다. 복구 시나리오 특성상 실제 있음직한 `ORA-01110`, `ORA-01113`, `ORA-01157`, `ORA-00279`, `ORA-01547`, `ORA-01194`, `ORA-00257` 등을 사용한다
- **환경**: non-CDB `ORCL`, Oracle 19.3.0, OEL 7

---

## 1장. 백업·복구 개요와 19c 복구 아키텍처 (5개)
1. 백업 대상 물리 파일 통합 조회 (v$datafile / v$controlfile / v$logfile UNION)
2. 인스턴스 복구 동작 확인 — shutdown abort 후 startup 시 롤포워드/롤백 관찰
3. 체크포인트와 SCN 흐름 추적 — checkpoint_change# 변화 및 scn_to_timestamp 확인
4. 백업 대상 파일 목록화와 백업 스크립트 자동 생성
5. alert log 및 ADR 진단 정보 확인 (adrci show alert)

## 2장. 복구 가능성 구성 — ARCHIVELOG·FRA·다중화 (7개)
1. NOARCHIVELOG → ARCHIVELOG 모드 전환 (원본 ARCH 시1)
2. LOG_ARCHIVE_DEST_n 다중 아카이브 대상 구성과 확인
3. Fast Recovery Area 구성과 공간 사용률 확인 (v$recovery_file_dest)
4. 컨트롤파일 다중화 — spfile 수정 → mount 단계 복사 → 재기동
5. 리두로그 그룹·멤버 다중화와 그룹 추가/삭제
6. 아카이브 대상 디스크 full로 인한 ORA-00257 재현과 해소
7. spfile/pfile 백업과 컨트롤파일 자동 백업 설정

## 3장. User Managed 백업 — Cold Backup과 Hot Backup (6개)
1. Cold Backup(close/consistent) 수행 절차와 SCN 일치 확인
2. shutdown abort 후 받은 백업본의 위험성 확인
3. Hot Backup — begin backup / end backup 절차
4. Hot Backup 중 리두 생성량 증가 관찰 (v$sesstat 기준)
5. begin backup 상태에서 shutdown 시도 → 오류 → 원인 파악 → 해소
6. 컨트롤파일 백업 2종 비교 — binary 백업과 trace 생성

## 4장. NOARCHIVELOG 복구 ① 데이터파일 손상 (7개)
1. 특정 데이터파일 손상 — 백업 이후 리두정보 있음(완전복구) [원본 시1]
2. 특정 데이터파일 손상 — 백업 이후 리두정보 없음(불완전복구) [시2]
3. 백업 받지 않은 테이블스페이스의 DF 손상 — 리두 O [시3]
4. 백업 받지 않은 TS의 DF 손상 — 리두 X, drop tablespace 불가 상황 [시4]
5. SYSTEM 데이터파일 손상 — 리두 O [시5]
6. SYSTEM 데이터파일 손상 — 리두 X [시6]
7. SYSAUX 데이터파일 손상 (결손 보완) — SYSTEM과의 차이 대비

## 5장. NOARCHIVELOG 복구 ② UNDO·TEMP·전체 디스크 장애 (7개)
1. UNDO 데이터파일 손상 — 리두 O [시7]
2. UNDO 데이터파일 손상 — 리두 X [시8]
3. 트랜잭션 진행 중 UNDO 데이터파일 손상 [시9]
4. TEMP 파일 손상과 재생성 [시10]
5. 읽기 전용 테이블스페이스 DF 손상 (결손 보완) — 복원만으로 종료되는 케이스
6. 모든 DF/CF/RF가 있는 디스크 전체 손상 [시11]
7. 백업본에 리두로그 파일이 없는 경우의 복구 [시12]

## 6장. NOARCHIVELOG 복구 ③ 컨트롤파일 장애 (6개)
1. 컨트롤파일만 손상 — binary 백업본으로 복구 [시13]
2. 컨트롤파일만 손상 — trace로 재생성 [시14]
3. 컨트롤파일 손상 — DB 정상 종료 상태 [시15]
4. 컨트롤파일 손상 — DB 비정상 종료 상태 [시16]
5. 데이터파일 + 컨트롤파일 동시 손상 — 정상 종료, 리두 O [시17]
6. 컨트롤파일·데이터파일 유실, 리두 X, 비정상 종료 [시18]

## 7장. NOARCHIVELOG 복구 ④ 리두로그 장애와 복합 장애 (6개)
1. DB 정상 종료 상태에서 리두로그 + 컨트롤파일 손상 [시19]
2. 리두로그 + 컨트롤파일 손상으로 DB가 비정상 종료된 경우 [시20]
3. 백업 컨트롤파일과 현재 데이터파일 정보 불일치 [시21]
4. DB 정상 종료 후 INACTIVE 로그 파일 삭제 [시22]
5. INACTIVE 로그 파일 삭제 후 DB 비정상 종료 [시23]
6. CURRENT 리두로그 파일 삭제 [시24]

## 8장. ARCHIVELOG 복구 ① 데이터파일 완전복구 (8개)
1. 운영 중 offline 되는 데이터파일 손상 — DB open 유지 상태 복구 [ARCH 시2]
2. 오프라인 상태 테이블스페이스 손상 복구 [시3]
3. 정상 종료 후 여러 데이터파일 손상 복구 [시4]
4. 백업 받지 않은 테이블스페이스의 DF 손상 복구 [시5]
5. 백업 받지 않은 TS의 DF를 새 위치로 복구 [시6]
6. 특정 데이터파일을 새 위치로 복구 — ALTER DATABASE RENAME FILE [시7]
7. TS의 여러 DF 중 특정 file만 손상 복구 [시8]
8. 읽기 전용 테이블스페이스 복구 (결손 보완)

## 9장. ARCHIVELOG 복구 ② 전체 데이터파일·UNDO·아카이브 결손 (7개)
1. 모든 데이터파일 손상 복구 [시9]
2. 모든 데이터파일 손상 — 새 위치로 복구 [시10]
3. UNDO 데이터파일 손상 복구 [시11]
4. 운영 중 UNDO 데이터파일 손상 복구 [시12]
5. 복구에 필요한 archive log가 다중 대상 중 한쪽에만 없을 경우 [시13]
6. 아카이브가 삭제됐지만 온라인 리두로 완전복구되는 경우 [시14]
7. ORA-00257(아카이브 대상 full)로 hang된 DB 복구 (결손 보완)

## 10장. ARCHIVELOG 복구 ③ 불완전 복구와 INACTIVE 리두로그 장애 (7개)
1. 필요한 archive log 손상 → Cancel-based 불완전 복구 [시15]
2. Time-based 불완전 복구 (UNTIL TIME)
3. SCN-based 불완전 복구 (UNTIL CHANGE) (결손 보완)
4. Log sequence-based 불완전 복구 (UNTIL SEQUENCE) (결손 보완)
5. DF + 모든 아카이브 삭제 — hot(open/online) backup 기반 불완전 복구 [시16]
6. DF + 모든 아카이브 삭제 — cold(close/offline) backup 기반 불완전 복구 [시17]
7. INACTIVE 리두로그 삭제 복구 — 정상 종료 후 / 운영 중 두 경우 [시18·19]

## 11장. ARCHIVELOG 복구 ④ CURRENT 리두로그 장애와 컨트롤파일 복구 (8개)
1. CURRENT 리두로그 삭제 후 DB 정상 종료 [시20]
2. CURRENT 리두로그 삭제 후 DB 비정상 종료 — 일관성 없는 백업 [시21]
3. 운영 중 CURRENT 리두로그 삭제 [시22]
4. clear unarchived logfile을 이용한 복구 [시22.1]
5. 정상 종료 후 컨트롤파일 손상 — 백업본 사용 [시23]
6. 정상 종료 후 컨트롤파일 손상 — 재생성 [시24]
7. 비정상 종료 후 컨트롤파일 손상 — 재생성 [시25]
8. 백업 CF 내용과 현재 DF 정보가 달라진 경우 복구 [시26]

## 12장. ARCHIVELOG 복구 ⑤ 복합 장애 종합 복구 (8개)
1. 모든 DFs + CFs 손상 복구 [시27]
2. SYSTEM DF + CFs 삭제 복구 [시28]
3. RFs + CFs 손상 복구 [시29]
4. 일반 DFs + inactive RF + CFs 손상 복구 [시30]
5. 위 상태에서 log switch가 발생한 hang 상태 복구 [시31]
6. 모든 DFs/CFs/RFs 삭제 — 백업 이후 아카이브 있음 [시32]
7. 모든 DFs/CFs/RFs 삭제 — 아카이브 없음, open backup 사용 [시33]
8. 모든 DFs/CFs/RFs 삭제 — 아카이브 없음, close backup 사용 [시34]

## 13장. RMAN 개요·구성과 Recovery Catalog (7개)
1. RMAN nocatalog 접속과 REPORT SCHEMA 확인
2. listener.ora / tnsnames.ora 구성과 카탈로그 DB 연결 [RMAN 시1]
3. Recovery Catalog 생성·등록 — CREATE CATALOG / REGISTER DATABASE [시1]
4. CONFIGURE 영구 설정과 SHOW ALL 확인 (결손 보완)
5. Retention Policy 설정과 REPORT OBSOLETE / DELETE OBSOLETE (결손 보완)
6. LIST BACKUP / REPORT NEED BACKUP / CROSSCHECK (결손 보완)
7. RESYNC CATALOG와 Stored Script 등록·실행 (결손 보완)

## 14장. RMAN 백업 — Full·Incremental·Image Copy·암호화 (8개)
1. 전체 데이터베이스 백업 — BACKUP DATABASE PLUS ARCHIVELOG
2. 테이블스페이스·데이터파일 단위 백업
3. Incremental Backup Level 0/1 — 누적(cumulative)과 차등(differential) 비교 [시21]
4. Block Change Tracking 활성화와 백업 시간 변화 확인 (결손 보완)
5. Image Copy(BACKUP AS COPY)와 SWITCH를 이용한 즉시 복구 [시19]
6. 압축 백업(AS COMPRESSED BACKUPSET)과 백업 조각 크기 조정 (결손 보완)
7. RMAN 백업 암호화 — SET ENCRYPTION ON [시18]
8. VALIDATE DATABASE / BACKUP VALIDATE / RESTORE PREVIEW 사전 점검 (결손 보완)

## 15장. RMAN 복구 시나리오 (10개)
1. 데이터파일 유실 복구 — RESTORE / RECOVER DATAFILE [RMAN 시2]
2. 일반 테이블스페이스를 다른 위치로 복구 — SET NEWNAME / SWITCH [시3]
3. SYSTEM 데이터파일 손상 복구 [시4]
4. 모든 데이터파일 손상 복구 [시5]
5. 모든 데이터파일 손상 — 새 위치로 복구 [시6]
6. 백업받지 않은 TS의 DF 손상 복구 [시7]
7. TS에 속한 여러 DF 중 일부 손상 복구 [시8·16]
8. UNDO 데이터파일 손상 복구 [시9]
9. 컨트롤파일 손상 복구 — 백업본 사용 / 재생성 [시10·11]
10. 모든 DFs+CF / CF+RFs / DFs+CFs+RFs 전부 손상 복구와 Time-based·SCN-based 불완전 복구 [시12~15]

## 16장. RMAN 고급 복구와 블록 손상 복구 (8개)
1. RMAN Table Recovery — RECOVER TABLE ... UNTIL (19c 방식) [RMAN 시17]
2. 특정 테이블스페이스만 이용한 복제 DB 생성 후 테이블 복구 — 원본 시17 절차 [RMAN 시17]
3. spfile 손상 복구 — 자동 백업(autobackup)에서 RESTORE SPFILE [RMAN 시20]
4. pfile 손상과 spfile 재생성 [RMAN 시20]
5. Block Corruption 재현(dd) → VALIDATE DATAFILE로 손상 블록 확인 [BNR_15]
6. Data Recovery Advisor — LIST FAILURE / ADVISE FAILURE / REPAIR FAILURE PREVIEW / REPAIR FAILURE [BNR_15]
7. 수동 Block Media Recovery — RECOVER DATAFILE n BLOCK m (결손 보완)
8. DBVERIFY(dbv)와 DB_BLOCK_CHECKING/DB_BLOCK_CHECKSUM으로 손상 조기 탐지 (결손 보완)

## 17장. 데이터베이스 복제 — Clone DB와 RMAN Duplicate (8개)
1. 백업 데이터파일·아카이브를 clone 디렉터리로 복사하고 pfile 준비 [Clone 시1]
2. control trace 생성과 pfile 수정(db_name, control_files, log_archive_dest_1) [Clone 시1]
3. CREATE CONTROLFILE SET DATABASE "CLONE" RESETLOGS ARCHIVELOG 실행 [Clone 시1]
4. recover database using backup controlfile until cancel → open resetlogs → TEMP 파일 추가 [Clone 시1]
5. 복제 DB 검증(v$database, v$log)과 복제 DB 삭제 — DROP DATABASE 정식 절차 병기 [Clone 시1]
6. Active Duplication 사전 준비 — orapwd, listener.ora SID 추가, tnsnames.ora(T1/C1/N1), nomount 기동 [Clone 시2]
7. DUPLICATE TARGET DATABASE TO NEWDB FROM ACTIVE DATABASE 수행과 Memory Script 해석 [Clone 시2]
8. 백업 기반 복제(DUPLICATE ... BACKUP LOCATION), UNTIL TIME 시점 복제, nid로 DBID/DB_NAME 변경, TSPITR (결손 보완)

## 18장. Flashback 기술 (9개)
1. UNDO_RETENTION / RETENTION GUARANTEE 설정과 Flashback 가용 시간 확인 (결손 보완)
2. Flashback Query — AS OF TIMESTAMP / AS OF SCN [BNR_16]
3. Flashback Version Query — VERSIONS BETWEEN [BNR_16]
4. Flashback Transaction Query — flashback_transaction_query, UNDO_SQL (결손 보완)
5. Flashback Table — ENABLE ROW MOVEMENT과 TO SCN/TIMESTAMP [BNR_16]
6. Flashback Drop과 휴지통(RECYCLEBIN) 관리 — PURGE, 동일명 객체 복원 [BNR_16]
7. Flashback Data Archive 구성과 이력 조회 [BNR_16]
8. Flashback Database — FLASHBACK ON, Guaranteed Restore Point, FLASHBACK DATABASE TO [BNR_16]
9. (부록) Cursor Sharing 동작 확인 [BNR_16] — 본문에는 넣지 않고 트랜스크립트만 보존

## 19장. Data Pump와 논리 백업 (10개)
1. 디렉터리 객체 생성과 READ/WRITE 권한 부여, DATA_PUMP_DIR 확인 [BNR_15]
2. Schema level Export — expdp schemas=hr [BNR_15]
3. Table level Import — drop table 후 impdp tables=hr.emp로 복원 [BNR_15]
4. FULL / TABLESPACES 모드 export·import (결손 보완)
5. REMAP_SCHEMA / REMAP_TABLESPACE / REMAP_DATAFILE / TRANSFORM (결손 보완)
6. PARALLEL·COMPRESSION·ENCRYPTION·ESTIMATE 옵션 비교 (결손 보완)
7. FLASHBACK_SCN / FLASHBACK_TIME 을 이용한 일관성 있는 export (결손 보완, 18장 연계)
8. NETWORK_LINK 직접 이관과 VERSION 파라미터를 이용한 버전 간 이관 (결손 보완)
9. Data Pump Job 모니터링·제어 — dba_datapump_jobs, ATTACH / STATUS / STOP_JOB / KILL_JOB (결손 보완)
10. dbms_metadata로 DDL 추출과 Transportable Tablespace 개요 [BNR_15]

---

## 총계

19개 챕터, **총 142개** 트랜스크립트 (챕터별 5~10개, 시나리오 밀도에 비례 배분)

| 계통 | 챕터 | 트랜스크립트 |
|---|---|---|
| 개요·구성·백업 | 1~3 | 18 |
| NOARCHIVELOG 복구 | 4~7 | 26 |
| ARCHIVELOG 복구 | 8~12 | 38 |
| RMAN | 13~16 | 33 |
| 복제 | 17 | 8 |
| Flashback | 18 | 9 |
| Data Pump·논리 백업 | 19 | 10 |

원본 93개 시나리오 중 **결손 보완으로 추가한 케이스는 33개**(각 항목에 "결손 보완" 표기). 나머지는 원본 시나리오를 표준 8단계 템플릿으로 재작성·확장한 것이다.

Data Pump(19장)는 원본 분량이 1~2페이지에 불과해 10개 중 7개가 결손 보완이다. 이 장만 원본 의존도가 낮고 19c 공식 지식 비중이 높으므로, 작성 에이전트에게 **Oracle 19c Utilities Guide 수준의 정확한 파라미터 서술**을 명시적으로 요구할 것.
