-- =============================================================================
--  rc_perf_analysis.sql  —  백업 성능 분석 리포트
--  출처   : 고급 실습 08
--  실행   : sqlplus -s rc_report/<pw>@rcat @rc_perf_analysis.sql
--  용도   : 백업 창 초과 예측, 성능 저하 원인 규명, 개선 효과 측정
--
--  판정의 핵심
--    "증분 백업이 왜 전체 백업만큼 오래 걸리는가"
--    증분은 변경된 블록만 쓰지만 기본 동작은 전체 블록을 읽는다.
--    읽는 양(input_bytes)이 DB 크기에 근접하면 Block Change Tracking 검토 대상이다.
-- =============================================================================
SET LINESIZE 190 PAGESIZE 200 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

-- ---- 임계값 ----
DEFINE window_minutes = 60      -- 백업 창 (분)
DEFINE slow_pct       = 30      -- 처리량 하락 경고 기준 (%)
DEFINE window_warn    = 70      -- 백업 창 소진율 경고 기준 (%)
DEFINE trend_days     = 90
-- -----------------

COLUMN db_name FORMAT A10
COLUMN week    FORMAT A9
COLUMN judge   FORMAT A12
COLUMN db1     FORMAT A10
COLUMN db2     FORMAT A10

PROMPT ================================================================================
PROMPT  백업 성능 분석 리포트
PROMPT ================================================================================

PROMPT
PROMPT === 1. 주간 추세 (DB INCR, 최근 &trend_days 일) ===
PROMPT     mb_sec 가 떨어지는데 read_gb 가 그대로면 자원 경합을 의심한다
SELECT db_name, TO_CHAR(start_time,'IYYY-IW')                     AS week,
       COUNT(*)                                                    AS runs,
       ROUND(AVG(elapsed_seconds))                                 AS avg_sec,
       ROUND(AVG(input_bytes)/1024/1024/1024,2)                    AS read_gb,
       ROUND(AVG(output_bytes)/1024/1024/1024,2)                   AS write_gb,
       ROUND(AVG(input_bytes/NULLIF(elapsed_seconds,0))/1024/1024) AS mb_sec
FROM   rc_rman_backup_job_details
WHERE  input_type = 'DB INCR' AND start_time > SYSDATE - &trend_days
GROUP  BY db_name, TO_CHAR(start_time,'IYYY-IW')
ORDER  BY db_name, week;

PROMPT
PROMPT === 2. 증분 효율 (읽은 양 / 쓴 양) ===
PROMPT     ratio 가 크면 전체를 읽고 조금만 쓴다는 뜻 = BCT 검토 대상
SELECT db_name,
       ROUND(AVG(input_bytes)/1024/1024/1024,2)                AS avg_read_gb,
       ROUND(AVG(output_bytes)/1024/1024/1024,2)               AS avg_write_gb,
       ROUND(AVG(input_bytes)/NULLIF(AVG(output_bytes),0),1)   AS ratio,
       CASE WHEN AVG(input_bytes)/NULLIF(AVG(output_bytes),0) > 5
            THEN '*** BCT 검토 ***' ELSE 'OK' END              AS judge
FROM   rc_rman_backup_job_details
WHERE  input_type = 'DB INCR' AND start_time > SYSDATE - 7
GROUP  BY db_name ORDER BY ratio DESC NULLS LAST;

PROMPT
PROMPT === 3. 처리량 하락 감지 (최근 7일 vs 이전 23일) ===
SELECT db_name, recent_mb_sec, prev_mb_sec,
       ROUND((prev_mb_sec - recent_mb_sec)/NULLIF(prev_mb_sec,0)*100) AS drop_pct,
       CASE WHEN (prev_mb_sec - recent_mb_sec)/NULLIF(prev_mb_sec,0)*100
                 >= &slow_pct THEN '*** WARN ***' ELSE 'OK' END       AS judge
FROM (
  SELECT db_name,
    ROUND(AVG(CASE WHEN start_time > SYSDATE-7
          THEN input_bytes/NULLIF(elapsed_seconds,0) END)/1024/1024) AS recent_mb_sec,
    ROUND(AVG(CASE WHEN start_time BETWEEN SYSDATE-30 AND SYSDATE-7
          THEN input_bytes/NULLIF(elapsed_seconds,0) END)/1024/1024) AS prev_mb_sec
  FROM  rc_rman_backup_job_details
  WHERE input_type = 'DB INCR'
  GROUP BY db_name)
ORDER  BY drop_pct DESC NULLS LAST;

PROMPT
PROMPT === 4. 백업 창 소진율 (창 = &window_minutes 분) ===
SELECT db_name,
       ROUND(MAX(elapsed_seconds)/60,1)                                AS max_min,
       ROUND(AVG(elapsed_seconds)/60,1)                                AS avg_min,
       ROUND(MAX(elapsed_seconds)/60/&window_minutes*100)              AS used_pct,
       CASE WHEN MAX(elapsed_seconds)/60/&window_minutes*100 >= &window_warn
            THEN '*** WARN ***' ELSE 'OK' END                          AS judge
FROM   rc_rman_backup_job_details
WHERE  input_type = 'DB INCR' AND start_time > SYSDATE - 7
GROUP  BY db_name ORDER BY used_pct DESC;

PROMPT
PROMPT === 5. 작업 시간 중복 (I/O 경합 원인) ===
SELECT a.db_name AS db1, b.db_name AS db2,
       TO_CHAR(a.start_time,'MM-DD HH24:MI')      AS a_start,
       TO_CHAR(b.start_time,'HH24:MI')            AS b_start,
       ROUND((LEAST(a.end_time,b.end_time)
              - GREATEST(a.start_time,b.start_time)) * 24 * 60) AS overlap_min
FROM   rc_rman_backup_job_details a, rc_rman_backup_job_details b
WHERE  a.db_name < b.db_name
AND    a.start_time > SYSDATE - 7 AND b.start_time > SYSDATE - 7
AND    a.start_time < b.end_time  AND b.start_time < a.end_time
ORDER  BY overlap_min DESC FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT === 6. 유형별 소요 시간 ===
SELECT db_name, input_type, COUNT(*) AS runs,
       ROUND(AVG(elapsed_seconds))          AS avg_sec,
       ROUND(MAX(elapsed_seconds))          AS max_sec,
       ROUND(AVG(compression_ratio),2)      AS comp_ratio
FROM   rc_rman_backup_job_details
WHERE  start_time > SYSDATE - 30
GROUP  BY db_name, input_type
ORDER  BY db_name, input_type;

PROMPT
PROMPT === 7. 실패·경고 이력 ===
SELECT db_name, input_type, status,
       TO_CHAR(start_time,'MM-DD HH24:MI') AS started,
       time_taken_display
FROM   rc_rman_backup_job_details
WHERE  start_time > SYSDATE - 30 AND status <> 'COMPLETED'
ORDER  BY start_time DESC;

PROMPT
PROMPT ================================================================================
PROMPT  개선안 선택 기준
PROMPT   읽는 양이 DB 크기에 근접   → Block Change Tracking (새 Level 0 필요)
PROMPT   특정 파일이 병목            → SECTION SIZE
PROMPT   채널이 파일 수보다 적다     → PARALLELISM 증가
PROMPT   작업이 겹친다               → 스케줄 순차화
PROMPT   저장 공간이 문제            → 압축 (단, 시간은 늘어난다)
PROMPT
PROMPT  주의 : 백업을 빠르게 하는 선택이 복구를 느리게 할 수 있다.
PROMPT         차등은 백업이 짧고 복구가 길다. 누적은 그 반대다.
PROMPT ================================================================================
EXIT
