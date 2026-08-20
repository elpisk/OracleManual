-- =============================================================================
--  dr_collect_info.sql  —  재해 복구 정보 수집
--  출처   : 고급 실습 07
--  실행   : sqlplus -s rc_report/<pw>@rcat @dr_collect_info.sql <DB_NAME>
--  예     : sqlplus -s rc_report/oracle_4U@rcat @dr_collect_info.sql ORCL
--  출력   : 화면 + /tmp/dr_info_<DB_NAME>.txt
--
--  이 스크립트는 재해 상황에서 가장 먼저 실행한다.
--  카탈로그가 없으면 복구 계획조차 세울 수 없다.
--
--  평시 운영 권장
--    주 1회 실행해 결과를 운영 서버 밖에 보관한다.
--    카탈로그까지 잃은 최악의 상황에서 이 파일이 마지막 근거가 된다.
-- =============================================================================
SET LINESIZE 200 PAGESIZE 200 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON HEADING ON

DEFINE dbname = &1

SPOOL /tmp/dr_info_&dbname..txt

COLUMN name       FORMAT A55
COLUMN directory  FORMAT A60
COLUMN value      FORMAT A62
COLUMN stmt       FORMAT A90

PROMPT ================================================================================
PROMPT  재해 복구 정보 수집 : &dbname
PROMPT ================================================================================

PROMPT
PROMPT === 1. DBID 와 인카네이션  (가장 먼저 확보할 것) ===
PROMPT     DBID 없이는 자동 백업을 찾지 못한다
SELECT dbid, name, dbinc_key,
       TO_CHAR(reset_time,'YYYY-MM-DD HH24:MI:SS') AS reset_time,
       CASE WHEN dbinc_key = (SELECT MAX(dbinc_key) FROM rc_database
                              WHERE name = UPPER('&dbname'))
            THEN '<-- CURRENT' END AS cur
FROM   rc_database WHERE name = UPPER('&dbname') ORDER BY dbinc_key;

PROMPT
PROMPT === 2. 데이터파일 구성 ===
PROMPT     예외 경로에 있는 파일을 놓치지 않도록 전체를 확인한다
SELECT file#, tablespace_name, ROUND(bytes/1024/1024) AS mb, name
FROM   rc_datafile
WHERE  dbinc_key = (SELECT MAX(dbinc_key) FROM rc_database
                    WHERE name = UPPER('&dbname'))
ORDER  BY file#;

PROMPT
PROMPT === 3. SET NEWNAME 구문  (경로를 치환해 사용) ===
SELECT '  SET NEWNAME FOR DATAFILE ' || file# ||
       ' TO ''<신규경로>/' || SUBSTR(name, INSTR(name,'/',-1)+1) || ''';' AS stmt
FROM   rc_datafile
WHERE  dbinc_key = (SELECT MAX(dbinc_key) FROM rc_database
                    WHERE name = UPPER('&dbname'))
ORDER  BY file#;

PROMPT
PROMPT === 4. 리두 로그 구성  (RESETLOGS 후 이 구성으로 생성된다) ===
SELECT group#, thread#, ROUND(bytes/1024/1024) AS mb, members
FROM   rc_redo_log
WHERE  dbinc_key = (SELECT MAX(dbinc_key) FROM rc_database
                    WHERE name = UPPER('&dbname'))
ORDER  BY group#;

PROMPT
PROMPT === 5. 임시 테이블스페이스 ===
SELECT file#, tablespace_name, ROUND(bytes/1024/1024) AS mb, name
FROM   rc_tempfile
WHERE  dbinc_key = (SELECT MAX(dbinc_key) FROM rc_database
                    WHERE name = UPPER('&dbname'))
ORDER  BY file#;

PROMPT
PROMPT === 6. 최근 7일 백업  (복원 대상 판단) ===
SELECT bs_key, bck_type, incr_level,
       TO_CHAR(completion_time,'MM-DD HH24:MI') AS done,
       ROUND(bytes/1024/1024) AS mb
FROM   rc_backup_set
WHERE  db_name = UPPER('&dbname') AND completion_time > SYSDATE - 7
ORDER  BY completion_time;

PROMPT
PROMPT === 7. 백업 조각 위치  (매체 준비) ===
SELECT SUBSTR(handle, 1, INSTR(handle,'/',-1)) AS directory,
       COUNT(*) AS pieces,
       ROUND(SUM(bytes)/1024/1024/1024,2) AS gb
FROM   rc_backup_piece
WHERE  db_name = UPPER('&dbname') AND status = 'A'
GROUP  BY SUBSTR(handle, 1, INSTR(handle,'/',-1))
ORDER  BY 1;

PROMPT
PROMPT === 8. 복구 가능 종점  ★ 즉시 업무 담당자에게 통보 ★ ===
SELECT MAX(sequence#)                                     AS last_backed_seq,
       TO_CHAR(MAX(next_time),'YYYY-MM-DD HH24:MI:SS')    AS covered_until,
       MAX(next_change#)                                  AS covered_scn
FROM   rc_archived_log a
WHERE  a.db_name = UPPER('&dbname')
AND    EXISTS (SELECT 1 FROM rc_backup_redolog b
               WHERE b.dbinc_key = a.dbinc_key AND b.sequence# = a.sequence#);

PROMPT
PROMPT     ↑ 이 시각 이후의 변경은 온라인 리두가 남아 있지 않으면 복구할 수 없다
PROMPT

PROMPT === 9. CONFIGURE 설정  (대상 서버에서 재현) ===
SELECT value FROM rc_rman_configuration
WHERE  db_key = (SELECT MAX(db_key) FROM rc_database
                 WHERE name = UPPER('&dbname'))
ORDER  BY conf#;

PROMPT
PROMPT === 10. 장기 보관 백업  (정기 백업이 없을 때의 대안) ===
SELECT tag, TO_CHAR(completion_time,'YYYY-MM-DD') AS taken,
       CASE WHEN keep_until IS NULL THEN 'FOREVER'
            ELSE TO_CHAR(keep_until,'YYYY-MM-DD') END AS keep_until
FROM   rc_backup_set
WHERE  db_name = UPPER('&dbname') AND keep_options IS NOT NULL
ORDER  BY completion_time DESC;

PROMPT
PROMPT ================================================================================
PROMPT  다음 단계
PROMPT   1) 8번 항목을 업무 담당자에게 통보한다 (손실 범위)
PROMPT   2) 7번 항목의 경로에 접근 가능한지 확인한다
PROMPT   3) dr_rebuild.sh <DB_NAME> <데이터경로> <아카이브경로> 를 실행한다
PROMPT   4) dr_drill_runbook.md 의 절차 D 를 따른다
PROMPT ================================================================================

SPOOL OFF
EXIT
