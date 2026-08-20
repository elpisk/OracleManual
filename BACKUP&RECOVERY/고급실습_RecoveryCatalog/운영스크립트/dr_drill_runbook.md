# DR 대응·훈련 런북

출처: 고급 실습 10
대상: orcl, sales, hrdb (Recovery Catalog `rcatowner@rcat`)
최종 갱신: 분기 훈련 직후 반드시 갱신할 것

---

## 0. 선언 값

| 항목 | 값 | 근거 |
|---|---|---|
| RTO | 3시간 | 실측 112분 × 여유 계수 1.5 |
| RPO | 4시간 | 아카이브 백업 주기 |
| 최종 검증 | 분기 훈련일 | 드릴 B 성공 |

여유 계수를 두는 이유 — 백업이 원격에 있을 수 있고, 담당자가 즉시 대응하지 못할 수 있으며, 여러 DB가 동시에 영향받을 수 있다.

---

## 1. 감지와 판정 (목표 10분)

1. 알림 확인. **어느 DB, 어떤 증상**인지 먼저 기록한다.
2. 상태를 확인한다.
   ```sql
   SELECT status FROM v$instance;
   SELECT open_mode FROM v$database;
   SELECT file#, error FROM v$recover_file;
   ```
3. 아래 표에서 유형을 고른다.

| 상태 | 증상 | 유형 | 절차 |
|---|---|---|---|
| OPEN | 특정 조회만 ORA-01578 | 블록 손상 | A |
| MOUNTED | ORA-01157 / ORA-01110 | 데이터파일 유실 | B |
| STARTED | ORA-00205 | 컨트롤파일 유실 | C |
| 접속 불가 | 서버 무응답 | 서버 소실 | D |
| OPEN | 잘못된 DML/DDL | 논리 오류 | E |

> 오류 메시지는 **첫 번째 파일만** 알려 준다. `v$recover_file` 로 전체 범위를 반드시 확인한다.

---

## 2. 손실 범위 산정 (목표 5분 · 절차 C·D 필수)

```bash
sqlplus -s rc_report/<pw>@rcat @dr_collect_info.sql <DB_NAME>
```

출력의 **"복구 가능 종점"** 항목을 즉시 업무 담당자에게 통보한다.
이 판단이 늦으면 업무 측이 수작업 복원 계획을 병행할 수 없어 전체 복구 시간이 길어진다.

통보 양식:
```
복구 가능 시점 : YYYY-MM-DD HH24:MI:SS (SCN nnnnnnn)
장애 발생 시점 : YYYY-MM-DD HH24:MI:SS
예상 손실 구간 : N시간 M분
```

---

## 3. 복구 절차

### 절차 A — 블록 손상

```
RMAN> VALIDATE DATAFILE <n>;
SQL>  SELECT file#, block#, blocks, corruption_type
      FROM v$database_block_corruption;
SQL>  SELECT DISTINCT owner, segment_name, segment_type FROM dba_extents
      WHERE file_id = <n> AND <blk> BETWEEN block_id AND block_id+blocks-1;
RMAN> RECOVER CORRUPTION LIST;
SQL>  SELECT * FROM v$database_block_corruption;   -- 비어야 한다
```

데이터베이스를 열어 둔 채 수행한다. 파일 전체를 복원하지 않는다.

### 절차 B — 데이터파일 유실

```
SQL>  SELECT file#, error FROM v$recover_file;     -- 범위 특정이 먼저다
```

손상 범위에 **SYSTEM 또는 UNDO 가 포함되는지**가 순서를 정한다.

포함되지 않으면 — 중단 시간을 줄이는 순서:
```
SQL>  ALTER DATABASE DATAFILE <n> OFFLINE;
SQL>  ALTER DATABASE OPEN;                          -- 나머지 업무 즉시 재개
RMAN> RESTORE DATAFILE <n>;
RMAN> RECOVER DATAFILE <n>;
RMAN> SQL 'ALTER DATABASE DATAFILE <n> ONLINE';
```

포함되면 — MOUNT 상태에서 복구를 마쳐야 한다:
```
RMAN> RESTORE DATABASE;  RECOVER DATABASE;
SQL>  ALTER DATABASE OPEN;
```

### 절차 C — 컨트롤파일 유실

```
RMAN> STARTUP NOMOUNT;
RMAN> SET DBID <DBID_LIST.txt 참조>;      -- 카탈로그 접속 시 생략 가능
RMAN> RESTORE CONTROLFILE FROM AUTOBACKUP;
RMAN> ALTER DATABASE MOUNT;
RMAN> RECOVER DATABASE;
```

`RMAN-06054` 가 나오면 정상이다. 복원된 컨트롤파일은 백업 컨트롤파일로 취급되어 온라인 리두를 자동으로 찾지 않는다.

```
SQL>  SELECT group#, sequence#, status FROM v$log;
SQL>  SELECT member FROM v$logfile WHERE group# = <CURRENT 그룹>;
SQL>  RECOVER DATABASE USING BACKUP CONTROLFILE UNTIL CANCEL;
      Specify log: <온라인 리두 경로 직접 입력>
SQL>  ALTER DATABASE OPEN RESETLOGS;
```

### 절차 D — 서버 소실

```bash
sh /home/oracle/rcadm/dr_rebuild.sh <DB_NAME> <데이터경로> <아카이브경로>
```

출력된 8단계 안내를 순서대로 수행한다. 실측 67분(오픈까지), 95분(백업 정상화까지).

순서를 **바꿀 수 없는** 지점:
1. spfile → 2. 컨트롤파일 → 3. MOUNT → 4. SET NEWNAME + RESTORE → 5. SWITCH → 6. RECOVER → 7. OPEN RESETLOGS

`SET NEWNAME` · `RESTORE` · `SWITCH` · `RECOVER` 는 한 묶음이다. 하나라도 빠지면 `ORA-19504` 또는 `RMAN-06571` 로 막힌다.

### 절차 E — 논리 오류

| 상황 | 방법 | 비고 |
|---|---|---|
| DELETE, UNDO 보존 기간 내 | Flashback Query | 무중단, 초 단위 |
| DROP (PURGE 아님) | `FLASHBACK TABLE ... TO BEFORE DROP` | 제약·인덱스 이름은 복원되지 않는다 |
| TRUNCATE | `RECOVER TABLE` | UNDO 를 남기지 않으므로 Flashback 불가 |
| 테이블스페이스 전체 | TSPITR | 자기 완결성 검사 선행 |
| 전체를 특정 시점으로 | 불완전 복구 | 그 이후 모든 변경이 사라진다 |

> **영향 범위가 방법을 정한다.** 한 테이블 때문에 전체를 되돌리면 그 자체가 사고다.

---

## 4. 정상화 체크리스트 (모든 절차 공통)

- [ ] `SELECT * FROM v$recover_file;` 결과 없음
- [ ] 무효 객체 0 (`@?/rdbms/admin/utlrp.sql` 필요 시)
- [ ] 행 수·표본 데이터 검증
- [ ] `RESYNC CATALOG` (영향받은 DB 전부)
- [ ] RESETLOGS 했다면 **새 인카네이션 기준 전체 백업**
- [ ] `LIST INCARNATION OF DATABASE` 로 확인
- [ ] 일일 리포트(`rc_daily_report.sql`) 정상 출력
- [ ] 리스너 / tnsnames / 애플리케이션 접속 전환
- [ ] 커넥션 풀 재시작, 배치 재개

> 복구 완료는 오픈이 아니라 **백업 체계 정상화까지**다.
> RESETLOGS 후 새 기준 백업이 없으면 다음 장애에서 인카네이션을 거슬러야 한다.

---

## 5. 훈련 절차

### 드릴 A — 테이블 복원 (월간, 30분, 서비스 영향 없음)

```
SQL>  SELECT current_scn FROM v$database;          -- 기록
RMAN> RECOVER TABLE <스키마>.<테이블>
        UNTIL SCN <scn>
        AUXILIARY DESTINATION '/u02/aux_drill'
        REMAP TABLE <스키마>.<테이블>:<테이블>_drill_<MMDD>;
SQL>  SELECT COUNT(*) FROM (
        SELECT * FROM <원본> MINUS SELECT * FROM <복원본>);   -- 0 이어야 한다
SQL>  DROP TABLE <복원본> PURGE;
$     rm -rf /u02/aux_drill/*
```

REMAP 을 쓰는 이유 — 원래 이름으로 받으면 현재 테이블과 충돌한다.

### 드릴 B — 타 서버 복제 (분기, 2시간, 서비스 영향 없음)

1. 대상 서버에 경로·비밀번호 파일·최소 pfile 준비
2. 리스너 **정적 등록** 후 `lsnrctl reload`, `tnsping` 확인
   NOMOUNT 인스턴스는 동적 등록을 하지 못한다. 없으면 `ORA-12514`.
3. `STARTUP NOMOUNT`
4. 복제 수행
   ```
   $ rman catalog rcatowner@rcat auxiliary sys/<pw>@<TNS>
   RMAN> SET DBID <dbid>;
   RMAN> RUN {
           ALLOCATE AUXILIARY CHANNEL a1 DEVICE TYPE DISK;
           ALLOCATE AUXILIARY CHANNEL a2 DEVICE TYPE DISK;
           DUPLICATE DATABASE TO <복제명>
             BACKUP LOCATION '<백업경로>' NOFILENAMECHECK;
         }
   ```
   원본 서버에 접속하지 않는다. **백업만으로 열리는지**를 보는 것이 목적이다.
5. 검증 — 행 수, 무효 객체 0, 테이블스페이스 상태, **DBID 가 원본과 다른지**
6. **정리 (생략 금지)**
   ```
   RMAN> STARTUP FORCE MOUNT;
   RMAN> DROP DATABASE INCLUDING BACKUPS NOPROMPT;
   $     rm -f $ORACLE_HOME/dbs/*<복제명>*
   $     df -h   # 공간 회수 확인
   ```
   > `DROP DATABASE` 는 복제본에만 쓴다. **SID 를 반드시 확인**하고 실행한다.
   > 정리하지 않으면 다음 훈련을 막고 운영 파일 시스템까지 압박한다.

### 드릴 C — 운영 DB 실제 복구 (연간, 3시간, 계획 정지 필요)

사전 승인, 서비스 공지, 롤백 계획(가상 머신 스냅숏)이 필수다.
중단 판단 기준을 미리 정하고 훈련 중 실제 복구가 실패했을 때의 대응을 명시한다.

---

## 6. 훈련 후 필수 작업

1. 소요 시간을 **단계별로** 기록한다
2. 발견 문제를 조치 항목으로 등록하고 담당·기한을 정한다
3. RTO/RPO 선언 값을 재검토한다
4. **이 런북을 갱신한다**

> 훈련에서 발견한 것이 반영되지 않은 런북은 실제 장애에서 같은 문제를 다시 만나게 한다.
> 문서로만 있는 절차는 동작하지 않는다.

---

## 7. 훈련 기록 양식

```
DR 훈련 기록
============
일시      :
수행자    :
대상      :

드릴 A (테이블 복원)
  방식 / 대상 / 소요 / 결과 / 비고

드릴 B (타 서버 복제)
  방식 / 대상 / 소요 / 결과 / 비고

발견 문제
  1) 내용 → 조치 → 담당 → 기한
  2) ...

다음 훈련 :
```

---

## 8. 관련 산출물

| 파일 | 용도 |
|---|---|
| `dr_collect_info.sql` | 재해 시 카탈로그에서 복구 정보 수집 |
| `dr_rebuild.sh` | 타 서버 재구축 준비·구문 생성 |
| `rc_restore_validate.sh` | L1~L3 상시 검증 |
| `rc_daily_report.sql` | 일일 백업 점검 |
| `rc_catalog_backup.sh` | 카탈로그 3중 보호 |
| `DBID_LIST.txt` | 컨트롤파일 유실 시 필수. **운영 서버 밖에도 보관** |
