-- =============================================================================
--  rc_daily_report.sql  —  Recovery Catalog 일일 백업 점검 리포트
--  출처   : 고급 실습 02
--  실행   : sqlplus -s rc_report/<pw>@rcat @rc_daily_report.sql
--  전제   : rc_report 계정이 rcatowner 소유 RC_* 뷰에 SELECT 권한을 가질 것
--  주의   : 반드시 전체 DB를 볼 수 있는 계정으로 실행한다.
--           VPC 계정으로 실행하면 일부만 점검하고 정상으로 보고한다.
-- =============================================================================
SET LINESIZE 200 PAGESIZE 0 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
SET HEADING ON NEWPAGE NONE

-- ---- 임계값 (조직 정책에 맞게 조정) ----
DEFINE full_warn_days     = 7
DEFINE arch_warn_days     = 1
DEFINE resync_warn_hours  = 24
DEFINE expected_db_count  = 3

COLUMN db_name    FORMAT A10
COLUMN last_full  FORMAT A13
COLUMN last_arch  FORMAT A13
COLUMN judge      FORMAT A6
COLUMN retention  FORMAT A48

PROMPT ================================================================================
PROMPT  Recovery Catalog 일일 백업 점검 리포트
PROMPT ================================================================================

-- ---- 안전장치 : 조회 가능 범위 확인 ----
SELECT CASE WHEN COUNT(*) < &expected_db_count
       THEN '*** 경고 : 조회 가능 DB ' || COUNT(*) || '대 — 계정 권한 확인 필요 ***'
       ELSE '점검 대상 DB : ' || COUNT(*) || '대' END AS check_scope
FROM   rc_database;

PROMPT
PROMPT [ 섹션 1. 요약 ]
SELECT d.name AS db_name,
  TO_CHAR(MAX(CASE WHEN s.incr_level = 0 OR s.incr_level IS NULL
              THEN s.completion_time END),'MM-DD HH24:MI')        AS last_full,
  TO_CHAR(MAX(CASE WHEN s.bck_type = 'L'
              THEN s.completion_time END),'MM-DD HH24:MI')        AS last_arch,
  (SELECT COUNT(*) FROM rc_datafile f
   WHERE  f.dbinc_key = d.dbinc_key
   AND    NOT EXISTS (SELECT 1 FROM rc_backup_datafile bd
                      WHERE bd.dbinc_key = f.dbinc_key AND bd.file# = f.file#
                      AND   bd.completion_time > SYSDATE - &full_warn_days))
                                                                   AS need_bkp,
  (SELECT COUNT(*) FROM rc_unusable_backupfile_details u
   WHERE  u.db_name = d.name)                                      AS unusable,
  (SELECT ROUND((SYSDATE - MAX(r.resync_time))*24,1) FROM rc_resync r
   WHERE  r.dbinc_key = d.dbinc_key)                               AS resync_h,
  CASE
    WHEN SYSDATE - MAX(CASE WHEN s.bck_type='L' THEN s.completion_time END)
         > &arch_warn_days THEN 'CRIT'
    WHEN (SELECT COUNT(*) FROM rc_unusable_backupfile_details u
          WHERE u.db_name = d.name) > 0 THEN 'WARN'
    ELSE 'OK' END                                                  AS judge
FROM   rc_database d LEFT JOIN rc_backup_set s ON d.db_key = s.db_key
GROUP  BY d.name, d.db_key, d.dbinc_key
ORDER  BY d.name;

PROMPT
PROMPT [ 섹션 2. 상세 ]
SELECT d.name AS db_name,
  ROUND(SYSDATE - MAX(CASE WHEN s.incr_level = 0 OR s.incr_level IS NULL
        THEN s.completion_time END),1)                             AS full_age_d,
  ROUND(SYSDATE - MAX(CASE WHEN s.bck_type='L'
        THEN s.completion_time END),1)                             AS arch_age_d,
  (SELECT COUNT(*) FROM rc_archived_log a
   WHERE  a.dbinc_key = d.dbinc_key
   AND    a.completion_time >
          (SELECT NVL(MAX(b.completion_time), SYSDATE-999)
           FROM rc_backup_set b
           WHERE b.db_key = d.db_key AND b.bck_type='L'))           AS unbacked_arch,
  (SELECT COUNT(*) FROM rc_rman_backup_job_details j
   WHERE  j.db_name = d.name AND j.start_time > SYSDATE-1
   AND    j.status <> 'COMPLETED')                                  AS failed_24h
FROM   rc_database d LEFT JOIN rc_backup_set s ON d.db_key = s.db_key
GROUP  BY d.name, d.db_key, d.dbinc_key
ORDER  BY d.name;

PROMPT
PROMPT [ 섹션 3. 예외 — 조치 필요 ]
SELECT msg FROM (
  SELECT '[CRIT] ' || d.name || ' : 아카이브 백업이 ' ||
         ROUND(SYSDATE - MAX(s.completion_time),1) || '일간 수행되지 않음' AS msg
  FROM   rc_database d JOIN rc_backup_set s
         ON d.db_key = s.db_key AND s.bck_type = 'L'
  GROUP  BY d.name
  HAVING SYSDATE - MAX(s.completion_time) > &arch_warn_days
  UNION ALL
  SELECT '[WARN] ' || db_name || ' : ' || status || ' 백업 조각 ' ||
         COUNT(*) || '개'
  FROM   rc_unusable_backupfile_details
  GROUP  BY db_name, status
  UNION ALL
  SELECT '[CRIT] ' || d.name || ' : 보존 정책 미설정 또는 NONE'
  FROM   rc_database d
  WHERE  NOT EXISTS (SELECT 1 FROM rc_rman_configuration c
                     WHERE c.db_key = d.db_key
                     AND   c.value LIKE 'RETENTION%'
                     AND   c.value NOT LIKE '%TO NONE%')
);

PROMPT
PROMPT [ 섹션 4. 최근 7일 추세 (DB INCR) ]
COLUMN day FORMAT A6
SELECT db_name, TO_CHAR(start_time,'MM-DD') AS day,
       ROUND(AVG(elapsed_seconds))                    AS avg_sec,
       ROUND(AVG(output_bytes)/1024/1024/1024,2)      AS out_gb
FROM   rc_rman_backup_job_details
WHERE  start_time > SYSDATE - 7 AND input_type = 'DB INCR'
GROUP  BY db_name, TO_CHAR(start_time,'MM-DD')
ORDER  BY db_name, day;

PROMPT
PROMPT [ 섹션 5. 보존 정책 현황 ]
SELECT d.name AS db_name,
       NVL(MAX(CASE WHEN c.value LIKE 'RETENTION%' THEN c.value END),
           '*** 정책 없음 ***') AS retention
FROM   rc_database d LEFT JOIN rc_rman_configuration c ON d.db_key = c.db_key
GROUP  BY d.name ORDER BY d.name;

PROMPT
PROMPT ================================================================================
EXIT
