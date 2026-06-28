# Oracle Database 19c: SQL Workshop
## Appendix H — Oracle 데이터베이스 아키텍처 | SQL 실습 모범답안

---

## Group 1: SGA 구성 요소 조회

**[1번]** SGA 구성 요소 크기 조회

```sql
SELECT name,
       ROUND(bytes/1024/1024, 2) AS size_mb,
       resizeable
FROM   v$sgainfo
ORDER BY bytes DESC;
```

**예시 결과:**
```
NAME                                    SIZE_MB  RESIZEABLE
--------------------------------------- -------- ----------
Maximum SGA Size                        1536.00  No
Total System Global Area                1536.00  No
Variable Size                           922.74   Yes
Database Buffers                        603.98   Yes
Fixed SGA Size                          8.86     No
Redo Buffers                            0.50     No
```

**해설:**
- `Variable Size`: Shared Pool, Java Pool 등 포함
- `Database Buffers`: Buffer Cache 크기
- `Redo Buffers`: Redo Log Buffer 크기
- `resizeable = Yes`: 동적 크기 조절 가능

---

**[2번]** v$sga 뷰 조회

```sql
SELECT name, value/1024/1024 AS mb
FROM   v$sga ORDER BY value DESC;
```

**예시 결과:**
```
NAME                    MB
----------------------- ------
Variable Size           922.74
Database Buffers        603.98
Fixed Size              8.86
Redo Buffers            0.50
```

---

**[3번]** SGA 고정/가변 구분

```sql
SELECT name,
       ROUND(bytes/1024/1024, 2) AS mb,
       CASE WHEN resizeable = 'Yes' THEN '가변' ELSE '고정' END AS size_type
FROM   v$sgainfo
ORDER BY resizeable DESC, bytes DESC;
```

**고정(No)**: Fixed SGA, Maximum SGA Size → 변경 불가  
**가변(Yes)**: Buffer Cache, Shared Pool → `ALTER SYSTEM SET ...`로 동적 조절 가능

---

**[4번]** SGA 관련 초기화 파라미터

```sql
SELECT name, value, description
FROM   v$parameter
WHERE  name IN ('sga_target', 'sga_max_size', 'db_cache_size',
                'shared_pool_size', 'log_buffer', 'pga_aggregate_target')
ORDER BY name;
```

**주요 파라미터:**
| 파라미터 | 의미 |
|---------|------|
| `sga_target` | SGA 자동 관리 총 크기 |
| `db_cache_size` | Buffer Cache 최소 크기 |
| `shared_pool_size` | Shared Pool 최소 크기 |
| `log_buffer` | Redo Log Buffer 크기 |
| `pga_aggregate_target` | PGA 총 목표 크기 |

---

**[5번]** Buffer Cache 적중률

```sql
SELECT ROUND(
    (1 - (phyrds / (dbgr + congets))) * 100, 2
) AS buffer_hit_ratio_pct
FROM (SELECT SUM(value) AS dbgr
      FROM v$sysstat WHERE name = 'db block gets'),
     (SELECT SUM(value) AS congets
      FROM v$sysstat WHERE name = 'consistent gets'),
     (SELECT SUM(value) AS phyrds
      FROM v$sysstat WHERE name = 'physical reads');
```

**해석:**
- 95% 이상: 양호 (대부분 메모리에서 처리)
- 90~95%: 보통 (Buffer Cache 크기 증가 검토)
- 90% 미만: 개선 필요 (빈번한 디스크 I/O)

---

## Group 2: 백그라운드 프로세스 조회

**[6번]** 활성 백그라운드 프로세스

```sql
SELECT pname, description
FROM   v$bgprocess
WHERE  paddr != '00'
ORDER BY pname;
```

**예시 결과:**
```
PNAME  DESCRIPTION
------ ----------------------------------------
ARC0   Archival Process 0
CKPT   Checkpoint
DBW0   Database Writer Process 0
LGWR   Redo Log Writer Process
PMON   Process Cleanup
RECO   Distributed Recovery
SMON   System Monitor Process
```

---

**[7번]** 필수 프로세스 상태 확인

```sql
SELECT pname,
       CASE WHEN paddr != '00' THEN '실행 중' ELSE '비활성' END AS status,
       description
FROM   v$bgprocess
WHERE  pname IN ('DBW0', 'DBW1', 'LGWR', 'CKPT', 'SMON', 'PMON', 'RECO', 'ARC0')
ORDER BY pname;
```

**핵심 프로세스 역할 요약:**
| 프로세스 | 역할 |
|---------|------|
| DBW0 | Dirty Buffer → Data File |
| LGWR | Redo Buffer → Redo Log File |
| CKPT | Checkpoint 정보 기록 |
| SMON | Instance 복구 |
| PMON | 실패 세션 정리 |

---

**[8번]** ARCn 프로세스 개수

```sql
SELECT COUNT(*) AS arc_count
FROM   v$bgprocess
WHERE  pname LIKE 'ARC%'
  AND  paddr != '00';
```

**해설:**
- 결과가 0: NOARCHIVELOG 모드 또는 아카이브 지연 없음
- 1 이상: ARCHIVELOG 모드, ARCn이 활성화됨
- `LOG_ARCHIVE_MAX_PROCESSES` 파라미터로 ARCn 개수 제어

---

## Group 3: Library Cache 및 파싱 성능

**[9번]** Library Cache 네임스페이스별 적중률

```sql
SELECT namespace,
       gets,
       gethits,
       ROUND(gethitratio * 100, 2) AS hit_ratio_pct,
       reloads,
       invalidations
FROM   v$librarycache
WHERE  gets > 0
ORDER BY gets DESC;
```

**주요 네임스페이스:**
| NAMESPACE | 의미 |
|-----------|------|
| SQL AREA | SQL 문 |
| TABLE/PROCEDURE | PL/SQL 객체 |
| BODY | 패키지 바디 |
| TRIGGER | 트리거 |

적중률 95% 미만 시 Shared Pool 증가 검토.

---

**[10번]** Data Dictionary Cache 적중률

```sql
SELECT parameter,
       gets,
       getmisses,
       ROUND((1 - getmisses/NULLIF(gets, 0)) * 100, 2) AS hit_ratio_pct
FROM   v$rowcache
WHERE  gets > 0
ORDER BY gets DESC;
```

**해석:** Dictionary Cache Hit Ratio가 낮으면 메타데이터 조회가 빈번히 디스크에서 발생 → Shared Pool 증가 필요.

---

**[11번]** Library Cache 저장 SQL 현황

```sql
SELECT COUNT(*) AS cached_sql_count,
       SUM(parse_calls) AS total_parse_calls,
       SUM(executions) AS total_executions,
       ROUND(SUM(parse_calls)/NULLIF(SUM(executions),0)*100, 2) AS parse_ratio_pct
FROM   v$sql;
```

**해석:**
- `parse_ratio_pct`가 낮을수록 재실행 대비 파싱이 적어 효율적
- 이상적: 실행 횟수에 비해 파싱 횟수가 매우 낮음 (바인드 변수 효과)

---

**[12번]** 파싱이 많은 상위 10개 SQL

```sql
SELECT ROWNUM AS rk,
       parse_calls,
       executions,
       sql_text
FROM   (SELECT parse_calls, executions, sql_text
        FROM   v$sql ORDER BY parse_calls DESC)
WHERE  ROWNUM <= 10;
```

**활용:** `parse_calls`가 높은 SQL은 바인드 변수 미사용 가능성 높음 → 코드 리팩토링 대상.

---

## Group 4: 스토리지 구조 조회

**[13번]** Data File 목록

```sql
SELECT file_name,
       tablespace_name,
       ROUND(bytes/1024/1024, 2) AS size_mb,
       status,
       autoextensible
FROM   dba_data_files
ORDER BY tablespace_name, file_name;
```

**예시 결과:**
```
FILE_NAME                          TABLESPACE  SIZE_MB  STATUS  AUTOEX
---------------------------------- ----------- -------- ------- ------
/opt/oracle/oradata/orcl/system01  SYSTEM       860.00  AVAILABLE  NO
/opt/oracle/oradata/orcl/users01   USERS         5.00  AVAILABLE  YES
```

---

**[14번]** Redo Log 그룹과 멤버

```sql
SELECT l.group#, l.members, l.bytes/1024/1024 AS size_mb,
       l.status, lf.member
FROM   v$log l JOIN v$logfile lf ON l.group# = lf.group#
ORDER BY l.group#, lf.member;
```

**Redo Log 상태:**
| STATUS | 의미 |
|--------|------|
| CURRENT | 현재 LGWR이 기록 중 |
| ACTIVE | 아직 Checkpoint가 필요 |
| INACTIVE | 재사용 가능 |

---

**[15번]** Control File 위치

```sql
SELECT name AS control_file_location FROM v$controlfile ORDER BY name;
```

**다중화 권장:** Control File을 2~3개 위치에 복사(Multiplexing)하여 단일 장애점(SPOF) 방지.

---

**[16번]** Tablespace 사용량

```sql
SELECT t.tablespace_name,
       t.status,
       ROUND(NVL(f.total_bytes, 0)/1024/1024, 2) AS total_mb,
       ROUND(NVL(f.free_bytes, 0)/1024/1024, 2) AS free_mb,
       ROUND((1 - NVL(f.free_bytes,0)/NULLIF(f.total_bytes,0))*100, 1) AS used_pct
FROM   dba_tablespaces t
LEFT JOIN (
    SELECT tablespace_name, SUM(bytes) AS total_bytes
    FROM   dba_data_files GROUP BY tablespace_name
) f ON t.tablespace_name = f.tablespace_name
ORDER BY t.tablespace_name;
```

**경고 기준:** `used_pct` 85% 이상 시 Data File 추가 또는 AUTOEXTEND 설정 검토.

---

**[17번]** HR 스키마 세그먼트 크기

```sql
SELECT segment_name, segment_type,
       ROUND(bytes/1024, 2) AS size_kb, extents, blocks
FROM   dba_segments WHERE owner = 'HR'
ORDER BY bytes DESC;
```

**해설:**
- `segment_type = TABLE`: 테이블 데이터 세그먼트
- `segment_type = INDEX`: 인덱스 세그먼트
- `extents`: 할당된 Extent 수 (많을수록 단편화 가능)

---

## Group 5: 세션 및 PGA 모니터링

**[18번]** 활성 세션 목록

```sql
SELECT s.sid, s.serial#, s.username, s.status,
       s.program, s.machine, s.logon_time
FROM   v$session s
WHERE  s.type = 'USER' AND s.status = 'ACTIVE'
ORDER BY s.logon_time;
```

**v$session 주요 컬럼:**
| 컬럼 | 의미 |
|------|------|
| sid | Session ID |
| serial# | 세션 고유 번호 (재사용 방지) |
| status | ACTIVE/INACTIVE |
| program | 접속 프로그램명 |

---

**[19번]** 세션별 PGA 사용량

```sql
SELECT s.sid, s.username,
       ROUND(p.pga_used_mem/1024, 2) AS pga_used_kb,
       ROUND(p.pga_alloc_mem/1024, 2) AS pga_alloc_kb,
       ROUND(p.pga_freeable_mem/1024, 2) AS pga_free_kb
FROM   v$session s JOIN v$process p ON s.paddr = p.addr
WHERE  s.type = 'USER'
ORDER BY p.pga_alloc_mem DESC;
```

**해설:**
- `pga_used_mem`: 실제 사용 중인 PGA
- `pga_alloc_mem`: 할당된 PGA (해제 안 된 부분 포함)
- `pga_freeable_mem`: 운영체제에 반환 가능한 PGA

---

**[20번]** Lock 보유 세션 조회

```sql
SELECT s.sid, s.username, l.type AS lock_type,
       l.mode_held, o.object_name
FROM   v$session s
JOIN   v$lock l ON s.sid = l.sid
LEFT JOIN dba_objects o ON l.id1 = o.object_id
WHERE  l.mode_held > 0 AND s.type = 'USER'
ORDER BY s.sid;
```

**Lock 모드:**
| mode_held 값 | 의미 |
|-------------|------|
| 0 | None |
| 2 | Row Share (RS) |
| 3 | Row Exclusive (RX) |
| 6 | Exclusive (X) |

---

## Group 6: 종합 실습

**[21번]** 데이터베이스 주요 구성 정보

```sql
SELECT name AS db_name, created, log_mode,
       current_scn, db_unique_name, open_mode
FROM   v$database;
```

**log_mode 해석:**
- `ARCHIVELOG`: 아카이브 로그 모드 (Point-in-Time Recovery 가능)
- `NOARCHIVELOG`: 아카이브 없음 (최근 백업까지만 복구 가능)

---

**[22번]** 하드 파싱 vs 소프트 파싱 비율

```sql
SELECT name,
       value,
       ROUND(value / NULLIF(
           (SELECT value FROM v$sysstat WHERE name = 'parse count (total)'), 0
       ) * 100, 2) AS pct_of_total
FROM   v$sysstat
WHERE  name IN ('parse count (hard)', 'parse count (total)', 'parse count (failures)')
ORDER BY name;
```

**해석:**
- 하드 파싱 비율이 높으면 → 바인드 변수 사용 권장
- 실패 파싱이 많으면 → SQL 오류 확인 필요

---

**[23번]** 주요 I/O 통계

```sql
SELECT name, value FROM v$sysstat
WHERE  name IN ('physical reads', 'physical writes',
                'db block gets', 'consistent gets', 'db block changes')
ORDER BY name;
```

**지표 해석:**
| 지표 | 의미 |
|------|------|
| `physical reads` | 디스크에서 읽은 블록 수 (적을수록 좋음) |
| `db block gets` | 현재 버전 블록을 Buffer Cache에서 읽은 수 |
| `consistent gets` | 일관성 읽기로 Cache에서 읽은 수 |
| `db block changes` | 변경된 블록 수 (DML 활동 지표) |

---

**[24번]** 대기 이벤트 세션

```sql
SELECT s.sid, s.username, s.status,
       w.event, w.wait_class, w.seconds_in_wait
FROM   v$session s JOIN v$session_wait w ON s.sid = w.sid
WHERE  s.type = 'USER' AND w.event NOT LIKE '%idle%'
ORDER BY w.seconds_in_wait DESC;
```

**주요 Wait Event:**
| Event | 의미 |
|-------|------|
| `db file sequential read` | 인덱스 스캔 I/O 대기 |
| `log file sync` | COMMIT 후 LGWR 완료 대기 |
| `enq: TX - row lock contention` | 행 Lock 대기 |
| `buffer busy waits` | Buffer Cache 경합 |

---

**[25번]** Archive Log 조회

```sql
-- 모드 확인
SELECT log_mode FROM v$database;

-- Archive Log 목록
SELECT sequence#, name AS archive_log_file,
       ROUND(blocks * block_size / 1024 / 1024, 2) AS size_mb,
       first_time, next_time, status
FROM   v$archived_log
WHERE  standby_dest = 'NO'
ORDER BY sequence# DESC;
```

**해설:** Archive Log 크기와 생성 빈도로 데이터베이스 변경량을 파악할 수 있다. 디스크 여유 공간 모니터링 필수.

---

**[26번]** 아키텍처 요약 보고서

```sql
-- DB 기본 정보
SELECT 'DB Name: ' || name || ' | Mode: ' || log_mode ||
       ' | Open: ' || open_mode || ' | SCN: ' || current_scn AS db_info
FROM   v$database;

-- SGA 총 크기
SELECT 'SGA Total: ' || ROUND(value/1024/1024, 0) || ' MB' AS sga_total
FROM   v$sga WHERE name = 'Total System Global Area';

-- 백그라운드 프로세스 수
SELECT 'Background Processes: ' || COUNT(*) || ' active' AS bg_proc
FROM   v$bgprocess WHERE paddr != '00';

-- 현재 세션 수
SELECT 'Active Sessions: ' ||
       COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) ||
       ' / Total: ' || COUNT(*) AS session_info
FROM   v$session WHERE type = 'USER';

-- Tablespace 수
SELECT 'Tablespaces: ' || COUNT(*) AS ts_count FROM dba_tablespaces;

-- Data File 총 크기
SELECT 'Data File Total: ' || ROUND(SUM(bytes)/1024/1024/1024, 2) || ' GB' AS df_total
FROM   dba_data_files;
```

**예시 출력:**
```
DB_INFO
-------------------------------------------------------
DB Name: ORCL | Mode: ARCHIVELOG | Open: READ WRITE | SCN: 2943876

SGA_TOTAL
--------------
SGA Total: 1536 MB

BG_PROC
---------------------
Background Processes: 23 active

SESSION_INFO
---------------------
Active Sessions: 3 / Total: 12

TS_COUNT
-----------
Tablespaces: 7

DF_TOTAL
--------------
Data File Total: 2.47 GB
```
