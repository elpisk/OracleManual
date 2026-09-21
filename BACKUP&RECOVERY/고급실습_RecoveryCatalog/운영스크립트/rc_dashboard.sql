-- =============================================================================
--  rc_dashboard.sql  —  백업·복구 체계 종합 현황
--  출처   : 고급 실습 10
--  실행   : sqlplus -s rc_report/<pw>@rcat @rc_dashboard.sql
--  용도   : 고급 실습 01~10 에서 만든 체계가 표준대로 유지되는지 한눈에 본다
--
--  주의 : rc_rman_configuration 은 NAME/VALUE 두 열이다.
--         'CONTROLFILE AUTOBACKUP' 의 값은 'ON' 이고, 기본값인 설정은 행이 없다.
-- =============================================================================
SET LINESIZE 190 PAGESIZE 200 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
COLUMN db_name   FORMAT A8
COLUMN retention FORMAT A32
COLUMN cf_auto  FORMAT A7
COLUMN arch_pol FORMAT A8
COLUMN enc      FORMAT A3
COLUMN ret21    FORMAT A5
COLUMN bk_opt   FORMAT A6
COLUMN oldest_backup FORMAT A13

PROMPT ================================================================
PROMPT  백업·복구 체계 종합 현황
PROMPT ================================================================

PROMPT
PROMPT === 1. DB별 요약 ===
SELECT d.name AS db_name,
  TO_CHAR(MAX(s.completion_time),'MM-DD HH24:MI')          AS last_backup,
  ROUND((SYSDATE - MAX(s.completion_time))*24,1)           AS hours_ago,
  (SELECT COUNT(*) FROM rc_backup_set k
   WHERE k.db_key = d.db_key AND k.keep_options IS NOT NULL) AS keep_sets,
  (SELECT COUNT(*) FROM rc_unusable_backupfile_details u
   WHERE u.db_name = d.name)                                AS unusable,
  (SELECT c.value FROM rc_rman_configuration c
   WHERE c.db_key = d.db_key AND c.name = 'RETENTION POLICY') AS retention
FROM rc_database d LEFT JOIN rc_backup_set s ON d.db_key = s.db_key
GROUP BY d.name, d.db_key ORDER BY d.name;

PROMPT
PROMPT === 2. 설정 표준 준수 (Y = 명시 설정됨, 빈칸 = 기본값 또는 미설정) ===
SELECT d.name AS db_name,
  MAX(CASE WHEN c.name = 'CONTROLFILE AUTOBACKUP'       AND c.value = 'ON'            THEN 'Y' END) AS cf_auto,
  MAX(CASE WHEN c.name = 'ARCHIVELOG DELETION POLICY'   AND c.value LIKE 'TO BACKED UP%' THEN 'Y' END) AS arch_pol,
  MAX(CASE WHEN c.name = 'ENCRYPTION FOR DATABASE'      AND c.value = 'ON'            THEN 'Y' END) AS enc,
  MAX(CASE WHEN c.name = 'RETENTION POLICY'             AND c.value LIKE '%21 DAYS%'  THEN 'Y' END) AS ret21,
  MAX(CASE WHEN c.name = 'BACKUP OPTIMIZATION'          AND c.value = 'ON'            THEN 'Y' END) AS bk_opt
FROM rc_database d LEFT JOIN rc_rman_configuration c ON d.db_key = c.db_key
GROUP BY d.name ORDER BY d.name;

PROMPT
PROMPT === 3. 최근 30일 작업 성공률 ===
SELECT db_name, COUNT(*) AS jobs,
  SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) AS ok,
  ROUND(SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END)/COUNT(*)*100,1) AS pct
FROM rc_rman_backup_job_details
WHERE start_time > SYSDATE - 30 GROUP BY db_name ORDER BY db_name;

PROMPT
PROMPT === 4. 복구 가능 범위 (KEEP 제외, 가장 오래된 백업) ===
SELECT d.name AS db_name,
  TO_CHAR(MIN(s.completion_time),'MM-DD') AS oldest_backup,
  ROUND(SYSDATE - MIN(s.completion_time)) AS days_back
FROM rc_database d JOIN rc_backup_set s ON d.db_key = s.db_key
WHERE s.keep_options IS NULL
GROUP BY d.name ORDER BY d.name;

PROMPT
PROMPT === 5. 아카이브 백업 공백 (백업되지 않은 아카이브가 있는 DB) ===
SELECT a.db_name, COUNT(*) AS not_backed_up, MIN(a.sequence#) AS first_seq, MAX(a.sequence#) AS last_seq
FROM   rc_archived_log a
WHERE  a.dbinc_key = (SELECT dbinc_key FROM rc_database WHERE db_key = a.db_key)
AND    NOT EXISTS (SELECT 1 FROM rc_backup_redolog b
                   WHERE b.dbinc_key = a.dbinc_key AND b.sequence# = a.sequence#)
GROUP  BY a.db_name ORDER BY a.db_name;
EXIT
