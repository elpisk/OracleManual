# Oracle Database 19c: SQL Workshop
## Appendix H — Oracle 데이터베이스 아키텍처 | SQL 실습 문제

---

> **참고:** 이 실습은 DBA 또는 SELECT ANY DICTIONARY 권한이 있는 계정(예: SYSTEM, SYS)에서 수행하거나, HR 계정으로 접근 가능한 뷰를 사용합니다.

---

## Group 1: SGA 구성 요소 조회

**[1번]** v$sgainfo 뷰에서 SGA 각 구성 요소의 이름과 크기(MB)를 조회하시오.

```sql
SELECT name,
       ROUND(bytes/1024/1024, 2) AS size_mb,
       resizeable
FROM   v$sgainfo
ORDER BY bytes DESC;
```

---

**[2번]** v$sga 뷰에서 SGA 주요 영역별 크기를 조회하시오.

```sql
SELECT name, value/1024/1024 AS mb
FROM   v$sga
ORDER BY value DESC;
```

---

**[3번]** 현재 SGA의 고정 크기(Fixed SGA)와 가변 크기(Variable SGA)를 구분하여 조회하시오.

```sql
SELECT name,
       ROUND(bytes/1024/1024, 2) AS mb,
       CASE WHEN resizeable = 'Yes' THEN '가변' ELSE '고정' END AS size_type
FROM   v$sgainfo
ORDER BY resizeable DESC, bytes DESC;
```

---

**[4번]** v$parameter 뷰에서 SGA 관련 초기화 파라미터를 조회하시오.

```sql
SELECT name, value, description
FROM   v$parameter
WHERE  name IN ('sga_target', 'sga_max_size', 'db_cache_size',
                'shared_pool_size', 'log_buffer', 'pga_aggregate_target')
ORDER BY name;
```

---

**[5번]** Buffer Cache 적중률을 계산하시오 (v$sysstat 활용).

```sql
SELECT ROUND(
    (1 - (phyrds / (dbgr + congets))) * 100, 2
) AS buffer_hit_ratio_pct
FROM (SELECT SUM(value) AS dbgr
      FROM   v$sysstat WHERE name = 'db block gets'),
     (SELECT SUM(value) AS congets
      FROM   v$sysstat WHERE name = 'consistent gets'),
     (SELECT SUM(value) AS phyrds
      FROM   v$sysstat WHERE name = 'physical reads');
```

---

## Group 2: 백그라운드 프로세스 조회

**[6번]** v$bgprocess 뷰에서 현재 활성 백그라운드 프로세스 목록을 조회하시오.

```sql
SELECT pname, description
FROM   v$bgprocess
WHERE  paddr != '00'
ORDER BY pname;
```

---

**[7번]** 필수 백그라운드 프로세스(DBWn, LGWR, CKPT, SMON, PMON)가 모두 실행 중인지 확인하시오.

```sql
SELECT pname,
       CASE WHEN paddr != '00' THEN '실행 중' ELSE '비활성' END AS status,
       description
FROM   v$bgprocess
WHERE  pname IN ('DBW0', 'DBW1', 'LGWR', 'CKPT', 'SMON', 'PMON', 'RECO', 'ARC0')
ORDER BY pname;
```

---

**[8번]** ARCn(Archiver) 프로세스의 실행 여부와 개수를 확인하시오.

```sql
SELECT COUNT(*) AS arc_count
FROM   v$bgprocess
WHERE  pname LIKE 'ARC%'
  AND  paddr != '00';
```

---

## Group 3: Library Cache 및 파싱 성능

**[9번]** Library Cache의 네임스페이스별 Gets, Hits, 적중률을 조회하시오.

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

---

**[10번]** Shared Pool의 Data Dictionary Cache(Row Cache) 적중률을 조회하시오.

```sql
SELECT parameter,
       gets,
       getmisses,
       ROUND((1 - getmisses/NULLIF(gets, 0)) * 100, 2) AS hit_ratio_pct
FROM   v$rowcache
WHERE  gets > 0
ORDER BY gets DESC;
```

---

**[11번]** 현재 Library Cache에 저장된 SQL 문 개수와 총 파싱 횟수를 조회하시오.

```sql
SELECT COUNT(*) AS cached_sql_count,
       SUM(parse_calls) AS total_parse_calls,
       SUM(executions) AS total_executions,
       ROUND(SUM(parse_calls)/NULLIF(SUM(executions),0)*100, 2) AS parse_ratio_pct
FROM   v$sql;
```

---

**[12번]** 파싱이 가장 많이 발생한 상위 10개 SQL 문을 조회하시오.

```sql
SELECT ROWNUM AS rk,
       parse_calls,
       executions,
       sql_text
FROM   (SELECT parse_calls, executions, sql_text
        FROM   v$sql
        ORDER BY parse_calls DESC)
WHERE  ROWNUM <= 10;
```

---

## Group 4: 스토리지 구조 조회

**[13번]** 현재 데이터베이스의 Data File 목록(파일명, Tablespace, 크기)을 조회하시오.

```sql
SELECT file_name,
       tablespace_name,
       ROUND(bytes/1024/1024, 2) AS size_mb,
       status,
       autoextensible
FROM   dba_data_files
ORDER BY tablespace_name, file_name;
```

---

**[14번]** Redo Log 그룹과 멤버 파일을 조회하시오.

```sql
SELECT l.group#,
       l.members,
       l.bytes/1024/1024 AS size_mb,
       l.status,
       lf.member
FROM   v$log l
JOIN   v$logfile lf ON l.group# = lf.group#
ORDER BY l.group#, lf.member;
```

---

**[15번]** Control File 위치를 조회하시오.

```sql
SELECT name AS control_file_location
FROM   v$controlfile
ORDER BY name;
```

---

**[16번]** 현재 데이터베이스의 Tablespace 목록과 사용량을 조회하시오.

```sql
SELECT t.tablespace_name,
       t.status,
       ROUND(NVL(f.total_bytes, 0)/1024/1024, 2) AS total_mb,
       ROUND(NVL(f.free_bytes, 0)/1024/1024, 2) AS free_mb,
       ROUND((1 - NVL(f.free_bytes,0)/NULLIF(f.total_bytes,0))*100, 1) AS used_pct
FROM   dba_tablespaces t
LEFT JOIN (
    SELECT tablespace_name,
           SUM(bytes) AS total_bytes
    FROM   dba_data_files GROUP BY tablespace_name
) f ON t.tablespace_name = f.tablespace_name
ORDER BY t.tablespace_name;
```

---

**[17번]** HR 스키마 객체별 세그먼트 크기를 조회하시오.

```sql
SELECT segment_name,
       segment_type,
       ROUND(bytes/1024, 2) AS size_kb,
       extents,
       blocks
FROM   dba_segments
WHERE  owner = 'HR'
ORDER BY bytes DESC;
```

---

## Group 5: 세션 및 PGA 모니터링

**[18번]** 현재 활성 세션 목록을 조회하시오.

```sql
SELECT s.sid,
       s.serial#,
       s.username,
       s.status,
       s.program,
       s.machine,
       s.logon_time
FROM   v$session s
WHERE  s.type = 'USER'
  AND  s.status = 'ACTIVE'
ORDER BY s.logon_time;
```

---

**[19번]** 세션별 PGA 메모리 사용량을 조회하시오.

```sql
SELECT s.sid,
       s.username,
       ROUND(p.pga_used_mem/1024, 2) AS pga_used_kb,
       ROUND(p.pga_alloc_mem/1024, 2) AS pga_alloc_kb,
       ROUND(p.pga_freeable_mem/1024, 2) AS pga_free_kb
FROM   v$session s
JOIN   v$process p ON s.paddr = p.addr
WHERE  s.type = 'USER'
ORDER BY p.pga_alloc_mem DESC;
```

---

**[20번]** 현재 Lock을 보유하고 있는 세션을 조회하시오.

```sql
SELECT s.sid,
       s.username,
       l.type AS lock_type,
       l.mode_held,
       o.object_name
FROM   v$session s
JOIN   v$lock l ON s.sid = l.sid
LEFT JOIN dba_objects o ON l.id1 = o.object_id
WHERE  l.mode_held > 0
  AND  s.type = 'USER'
ORDER BY s.sid;
```

---

## Group 6: 종합 실습

**[21번]** 데이터베이스 주요 구성 정보를 한 번에 조회하시오 (DB 이름, 생성일, 아카이브 모드, 현재 SCN).

```sql
SELECT name AS db_name,
       created,
       log_mode,
       current_scn,
       db_unique_name,
       open_mode
FROM   v$database;
```

---

**[22번]** Instance 시작 이후 하드 파싱과 소프트 파싱 횟수를 비교하시오.

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

---

**[23번]** v$sysstat에서 주요 I/O 통계를 조회하시오 (물리적 읽기/쓰기, 논리적 읽기).

```sql
SELECT name, value
FROM   v$sysstat
WHERE  name IN (
    'physical reads',
    'physical writes',
    'db block gets',
    'consistent gets',
    'db block changes'
)
ORDER BY name;
```

---

**[24번]** 현재 Wait Event(대기 이벤트) 중인 세션을 조회하시오.

```sql
SELECT s.sid,
       s.username,
       s.status,
       w.event,
       w.wait_class,
       w.seconds_in_wait
FROM   v$session s
JOIN   v$session_wait w ON s.sid = w.sid
WHERE  s.type = 'USER'
  AND  w.event NOT LIKE '%idle%'
ORDER BY w.seconds_in_wait DESC;
```

---

**[25번]** 아카이브 로그 정보를 조회하시오 (ARCHIVELOG 모드인 경우).

```sql
-- ARCHIVELOG 모드 확인
SELECT log_mode FROM v$database;

-- Archive Log 목록 (ARCHIVELOG 모드인 경우)
SELECT sequence#,
       name AS archive_log_file,
       ROUND(blocks * block_size / 1024 / 1024, 2) AS size_mb,
       first_time,
       next_time,
       status
FROM   v$archived_log
WHERE  standby_dest = 'NO'
ORDER BY sequence# DESC;
```

---

**[26번]** 데이터베이스 전체 아키텍처 요약 보고서를 생성하시오.

```sql
-- ========== Oracle DB 아키텍처 요약 ==========
-- 1. DB 기본 정보
SELECT 'DB Name: ' || name || ' | Mode: ' || log_mode ||
       ' | Open: ' || open_mode || ' | SCN: ' || current_scn AS db_info
FROM   v$database;

-- 2. SGA 총 크기
SELECT 'SGA Total: ' || ROUND(value/1024/1024, 0) || ' MB' AS sga_total
FROM   v$sga WHERE name = 'Total System Global Area';

-- 3. 백그라운드 프로세스 수
SELECT 'Background Processes: ' || COUNT(*) || ' active' AS bg_proc
FROM   v$bgprocess WHERE paddr != '00';

-- 4. 현재 세션 수
SELECT 'Active Sessions: ' ||
       COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) ||
       ' / Total: ' || COUNT(*) AS session_info
FROM   v$session WHERE type = 'USER';

-- 5. Tablespace 수
SELECT 'Tablespaces: ' || COUNT(*) AS ts_count FROM dba_tablespaces;

-- 6. Data File 총 크기
SELECT 'Data File Total: ' || ROUND(SUM(bytes)/1024/1024/1024, 2) || ' GB' AS df_total
FROM   dba_data_files;
```
