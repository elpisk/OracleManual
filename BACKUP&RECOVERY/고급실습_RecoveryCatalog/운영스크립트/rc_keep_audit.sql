-- =============================================================================
--  rc_keep_audit.sql  —  장기 보관 백업 감사 리포트
--  출처   : 고급 실습 06
--  실행   : sqlplus -s rc_report/<pw>@rcat @rc_keep_audit.sql
--  용도   : 분기 감사 제출, 보관 누락 점검, 만료 예정 확인
--
--  KEEP 백업의 성질
--    - 보존 정책의 대상에서 제외된다 (DELETE OBSOLETE 로 지워지지 않는다)
--    - 복원에 필요한 아카이브가 함께 백업된다 (자기 완결적)
--    - FRA 에는 저장할 수 없다 (ORA-19811)
--    - KEEP FOREVER 는 Recovery Catalog 가 있어야만 쓸 수 있다
-- =============================================================================
SET LINESIZE 190 PAGESIZE 200 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

DEFINE expire_warn_days = 30
DEFINE quarters_back    = 8

COLUMN db_name    FORMAT A8
COLUMN tag        FORMAT A26
COLUMN keep_until FORMAT A12
COLUMN handle     FORMAT A52
COLUMN qtr        FORMAT A8
COLUMN taken      FORMAT A14

PROMPT ================================================================================
PROMPT  장기 보관 백업 감사 리포트
PROMPT ================================================================================

PROMPT
PROMPT === 1. 보관 중인 백업 세트 ===
SELECT s.db_name, s.tag,
       TO_CHAR(s.completion_time,'YYYY-MM-DD')            AS taken,
       CASE WHEN s.keep_until IS NULL THEN 'FOREVER'
            ELSE TO_CHAR(s.keep_until,'YYYY-MM-DD') END   AS keep_until,
       CASE WHEN s.keep_until IS NULL THEN NULL
            ELSE ROUND(s.keep_until - SYSDATE) END        AS days_left,
       s.keep_options,
       ROUND(SUM(p.bytes)/1024/1024)                      AS mb
FROM   rc_backup_set s JOIN rc_backup_piece p ON s.bs_key = p.bs_key
WHERE  s.keep_options IS NOT NULL
GROUP  BY s.db_name, s.tag, s.completion_time, s.keep_until, s.keep_options
ORDER  BY s.db_name, s.completion_time;

PROMPT
PROMPT === 2. 만료 예정 (&expire_warn_days 일 내) ===
SELECT db_name, tag,
       TO_CHAR(keep_until,'YYYY-MM-DD')     AS expires,
       ROUND(keep_until - SYSDATE)          AS days_left
FROM   rc_backup_set
WHERE  keep_until IS NOT NULL
AND    keep_until BETWEEN SYSDATE AND SYSDATE + &expire_warn_days
ORDER  BY keep_until;

PROMPT
PROMPT === 3. 조각 상태 (파일이 실제로 있는가) ===
PROMPT     status A=AVAILABLE  X=EXPIRED(파일 없음)  U=UNAVAILABLE
SELECT s.db_name, s.tag, p.status, COUNT(*) AS pieces,
       ROUND(SUM(p.bytes)/1024/1024) AS mb
FROM   rc_backup_set s JOIN rc_backup_piece p ON s.bs_key = p.bs_key
WHERE  s.keep_options IS NOT NULL
GROUP  BY s.db_name, s.tag, p.status
ORDER  BY s.db_name, p.status;

PROMPT
PROMPT === 4. 보관 위치 (FRA 밖에 있어야 한다) ===
SELECT DISTINCT s.db_name,
       SUBSTR(p.handle, 1, INSTR(p.handle,'/',-1)) AS directory,
       COUNT(*) OVER (PARTITION BY SUBSTR(p.handle,1,INSTR(p.handle,'/',-1)))
                                                    AS pieces
FROM   rc_backup_set s JOIN rc_backup_piece p ON s.bs_key = p.bs_key
WHERE  s.keep_options IS NOT NULL
ORDER  BY s.db_name;

PROMPT
PROMPT === 5. 분기별 보관 누락 점검 (최근 &quarters_back 분기) ===
WITH q AS (
  SELECT ADD_MONTHS(TRUNC(SYSDATE,'Q'), -3*(LEVEL-1)) AS qstart,
         TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'Q'), -3*(LEVEL-1)),'YYYY"Q"Q') AS qtr
  FROM   dual CONNECT BY LEVEL <= &quarters_back
), dbq AS (
  SELECT d.name AS db_name, q.qtr, q.qstart FROM rc_database d CROSS JOIN q
)
SELECT dbq.db_name, dbq.qtr,
       NVL(TO_CHAR(MAX(b.completion_time),'YYYY-MM-DD'),'*** 누락 ***') AS taken
FROM   dbq LEFT JOIN rc_backup_set b
       ON b.db_name = dbq.db_name
      AND b.keep_options IS NOT NULL
      AND b.completion_time >= dbq.qstart
      AND b.completion_time <  ADD_MONTHS(dbq.qstart, 3)
GROUP  BY dbq.db_name, dbq.qtr, dbq.qstart
ORDER  BY dbq.db_name, dbq.qstart DESC;

PROMPT
PROMPT === 6. 보관 용량 ===
SELECT s.db_name,
       COUNT(DISTINCT s.bs_key)                    AS keep_sets,
       ROUND(SUM(p.bytes)/1024/1024/1024,2)        AS gb
FROM   rc_backup_set s JOIN rc_backup_piece p ON s.bs_key = p.bs_key
WHERE  s.keep_options IS NOT NULL
GROUP  BY s.db_name ORDER BY s.db_name;

PROMPT
PROMPT === 7. 복원 지점 (KEEP 백업과 짝을 이루어야 의미가 있다) ===
SELECT db_name, name AS restore_point, scn,
       TO_CHAR(time,'YYYY-MM-DD HH24:MI') AS created
FROM   rc_restore_point ORDER BY db_name, scn;

PROMPT
PROMPT ================================================================================
PROMPT  점검 요령
PROMPT   - 5번에 '누락'이 있으면 해당 분기 백업이 없다는 뜻이다
PROMPT   - 3번에 X(EXPIRED)가 있으면 파일이 사라진 것이다. 즉시 확인한다
PROMPT   - 4번의 경로가 FRA 안이면 설정 오류다. KEEP 은 FRA 에 둘 수 없다
PROMPT   - 목록에 있다고 복원되는 것은 아니다. 연 1회 전량 검증을 수행한다
PROMPT ================================================================================
EXIT
