-- ============================================================================
-- PF_00_환경점검.sql  :  과제를 시작하기 전에 환경을 기록한다
-- AWR 진단 포트폴리오 과제 공용 스크립트 (1/3)
-- ============================================================================
-- 목적       : 이 과제는 "지금 이 환경에서 내가 직접 잰 값" 이 전부다. 그래서
--              시작 시점의 환경을 먼저 기록해 두어야 한다. 이 스크립트의 출력은
--              보고서 1장(측정 환경)에 그대로 붙여 넣는 근거다.
--
--              ★ 중요 ★  이 스크립트는 "완벽한 기준 상태" 를 요구하지 않는다.
--              실습 랩은 여러 사람이 쓰고, 자동 통계 수집 작업이 밤마다 돌아
--              히스토그램을 다시 만든다. 운영 DB 도 마찬가지다. 그래서 어긋난
--              것을 막는 대신 **적어서 보고하게** 한다. 보고서에 "측정 당시
--              환경은 이러했다" 고 쓰는 것이 진단의 출발점이다.
--
-- 전제       : SYS AS SYSDBA 로 접속. (AWR·V$ 조회에 필요하다)
--              대상 스키마는 SQLT 의 진료비청구심사 7개 표.
--
-- 사용법     : SQL> @PF_00_환경점검.sql
--              SPOOL 로 감싸 파일로 남긴다 :
--                 SQL> SPOOL 01_근거/00_환경점검.log
--                 SQL> @PF_00_환경점검.sql
--                 SQL> SPOOL OFF
--
-- 소요 시간  : 약 20~40초 (건수 COUNT 7회 포함).
--
-- 관찰 지표  : V$INSTANCE·V$DATABASE·V$OSSTAT(CPU·메모리)·V$PARAMETER
--              DBA_HIST_WR_CONTROL(주기·보존) · DBA_HIST_SNAPSHOT(남은 구간)
--              V$SYSAUX_OCCUPANTS(AWR 가 쓰는 용량) · V$ACTIVE_SESSION_HISTORY
--              7개 표의 건수 · 인덱스 · 히스토그램 · 확장 통계
--              DBA_AUTOTASK_JOB_HISTORY(자동 통계 수집이 마지막으로 돈 때)
--              V$RSRC_PLAN(활성 플랜)
--
-- 되돌리기   : 조회만 한다. 되돌릴 것이 없다.
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              여기서 나온 값을 운영 실적처럼 쓰지 않는다. 보고서 표지에
--              "개인 실습 VM 재현 사례" 를 반드시 적는다.
-- ============================================================================

SET LINESIZE 200 PAGESIZE 300 FEEDBACK OFF VERIFY OFF SERVEROUTPUT OFF
COLUMN item    FORMAT A30
COLUMN found   FORMAT A46
COLUMN note    FORMAT A44
COLUMN name    FORMAT A34
COLUMN table_name FORMAT A16
COLUMN value   FORMAT A30

PROMPT
PROMPT ============================================================
PROMPT  AWR 진단 포트폴리오 과제 - 측정 환경 기록
PROMPT ============================================================
SELECT TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS TZR') AS "측정 시각" FROM dual;


PROMPT
PROMPT === 1. 인스턴스와 하드웨어 ==================================
SELECT i.instance_name, i.version, i.host_name,
       TO_CHAR(i.startup_time, 'YYYY-MM-DD HH24:MI') AS "기동 시각",
       d.name AS "DB명", d.dbid, d.database_role, d.log_mode
  FROM v$instance i, v$database d;

SELECT stat_name AS name, TO_CHAR(value) AS value
  FROM v$osstat
 WHERE stat_name IN ('NUM_CPUS', 'NUM_CPU_CORES', 'NUM_CPU_SOCKETS',
                     'PHYSICAL_MEMORY_BYTES')
 ORDER BY stat_name;

SELECT name, value FROM v$parameter
 WHERE name IN ('cpu_count', 'sga_target', 'sga_max_size',
                'pga_aggregate_target', 'pga_aggregate_limit',
                'memory_target', 'db_block_size', 'filesystemio_options')
 ORDER BY name;


PROMPT
PROMPT === 2. 진단 도구를 쓸 수 있는가 =============================
SELECT name, value,
       CASE WHEN name = 'control_management_pack_access'
                 AND value LIKE 'DIAGNOSTIC%' THEN 'AWR/ASH/ADDM 사용 가능'
            WHEN name = 'control_management_pack_access' THEN '★ AWR 사용 불가 - 강사에게 문의'
            WHEN name = 'statistics_level' AND value = 'TYPICAL' THEN '정상'
            WHEN name = 'statistics_level' THEN '★ TYPICAL 이 아니다 - 측정이 왜곡된다'
            ELSE NULL END AS note
  FROM v$parameter
 WHERE name IN ('control_management_pack_access', 'statistics_level',
                'timed_statistics', 'cursor_sharing')
 ORDER BY name;

PROMPT -- 라이선스 파라미터가 DIAGNOSTIC+TUNING 이어도 계약을 보장하지는 않는다.
PROMPT -- 보고서에는 "실습 환경에서 진단 팩이 활성화돼 있었다" 로만 적는다.


PROMPT
PROMPT === 3. AWR 설정과 보존 =====================================
SELECT snap_interval AS "스냅샷 주기", retention AS "보존 기간", topnsql AS "상위 SQL 보관"
  FROM dba_hist_wr_control;

SELECT COUNT(*)                                            AS "스냅샷 수",
       MIN(snap_id)                                        AS "최소 ID",
       MAX(snap_id)                                        AS "최대 ID",
       TO_CHAR(MIN(begin_interval_time), 'MM-DD HH24:MI')  AS "가장 오래된",
       TO_CHAR(MAX(end_interval_time),   'MM-DD HH24:MI')  AS "가장 최근"
  FROM dba_hist_snapshot;

PROMPT -- ★ 보고서에 반드시 적을 것 : 보존 기간을 넘긴 과거는 진단할 수 없다.
PROMPT --   "어제 오후" 를 보려면 그 구간을 덮는 스냅샷 쌍이 남아 있어야 한다.

COLUMN baseline_name FORMAT A32
SELECT baseline_id, baseline_name, start_snap_id, end_snap_id, baseline_type
  FROM dba_hist_baseline ORDER BY baseline_id;

SELECT occupant_name AS "SYSAUX 점유", ROUND(space_usage_kbytes/1024) AS "MB"
  FROM v$sysaux_occupants
 WHERE occupant_name IN ('SM/AWR', 'SM/ASH', 'SM/ADVISOR', 'SM/OPTSTAT')
 ORDER BY 2 DESC;

SELECT COUNT(*)                                    AS "V$ASH 샘플",
       TO_CHAR(MIN(sample_time), 'MM-DD HH24:MI')  AS "가장 오래된",
       TO_CHAR(MAX(sample_time), 'MM-DD HH24:MI')  AS "가장 최근"
  FROM v$active_session_history;


PROMPT
PROMPT === 4. 대상 스키마의 현재 상태 =============================
PROMPT -- 어긋난 것이 있어도 멈추지 않는다. 보고서에 적고 시작한다.

WITH cnt AS (
    SELECT 'HOSPITALS' t, COUNT(*) c FROM sqlt.hospitals      UNION ALL
    SELECT 'PATIENTS',      COUNT(*)  FROM sqlt.patients       UNION ALL
    SELECT 'DRUG_MASTER',   COUNT(*)  FROM sqlt.drug_master    UNION ALL
    SELECT 'MEDICAL_CLAIMS',COUNT(*)  FROM sqlt.medical_claims UNION ALL
    SELECT 'CLAIM_DETAILS', COUNT(*)  FROM sqlt.claim_details  UNION ALL
    SELECT 'DISEASES',      COUNT(*)  FROM sqlt.diseases       UNION ALL
    SELECT 'REVIEW_LOG',    COUNT(*)  FROM sqlt.review_log
)
SELECT t AS item, TO_CHAR(c, '999,999,999') AS found,
       CASE t WHEN 'HOSPITALS'      THEN DECODE(c, 1000,   '기준값',   '기준(1,000)과 다르다')
              WHEN 'PATIENTS'       THEN DECODE(c, 50000,  '기준값',   '기준(50,000)과 다르다')
              WHEN 'DRUG_MASTER'    THEN DECODE(c, 10000,  '기준값',   '기준(10,000)과 다르다')
              WHEN 'MEDICAL_CLAIMS' THEN DECODE(c, 300000, '기준값',   '기준(300,000)과 다르다')
              WHEN 'REVIEW_LOG'     THEN DECODE(c, 500000, '기준값',   '기준(500,000)과 다르다')
              ELSE '난수로 생성돼 기준 폭이 있다' END AS note
  FROM cnt
 ORDER BY DECODE(t, 'HOSPITALS',1,'PATIENTS',2,'DRUG_MASTER',3,
                    'MEDICAL_CLAIMS',4,'CLAIM_DETAILS',5,'DISEASES',6,7);

PROMPT
PROMPT -- 인덱스 : 과정 기준은 PK 7개뿐이다. 그 외가 있으면 적어 둔다.
COLUMN index_name FORMAT A26
COLUMN table_name FORMAT A16
COLUMN status     FORMAT A8
COLUMN cols FORMAT A40
SELECT i.index_name, i.table_name,
       (SELECT LISTAGG(c.column_name, ',') WITHIN GROUP (ORDER BY c.column_position)
          FROM dba_ind_columns c
         WHERE c.index_owner = 'SQLT' AND c.index_name = i.index_name) AS cols,
       CASE WHEN i.index_name LIKE 'PK%' THEN '기준' ELSE '★ 기준 외 - 보고서에 적는다' END AS note
  FROM dba_indexes i
 WHERE i.owner = 'SQLT'
   AND i.table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                        'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
 ORDER BY DECODE(SUBSTR(i.index_name,1,2), 'PK', 2, 1), i.table_name;

PROMPT
PROMPT -- 히스토그램 : 과정 기준은 MEDICAL_CLAIMS.HOSP_ID 하나다.
PROMPT --   자동 통계 수집(유지관리 창)이 밤마다 더 만들 수 있다. 어긋나도 정상이다.
COLUMN column_name FORMAT A18
COLUMN table_name  FORMAT A16
COLUMN histogram   FORMAT A10
SELECT table_name, column_name, histogram, num_buckets,
       TO_CHAR(last_analyzed, 'MM-DD HH24:MI') AS "수집 시각"
  FROM dba_tab_col_statistics
 WHERE owner = 'SQLT' AND histogram <> 'NONE'
   AND table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                      'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
 ORDER BY table_name, column_name;

SELECT COUNT(*) AS "확장 통계(컬럼 그룹·표현식)" FROM dba_stat_extensions WHERE owner = 'SQLT';

PROMPT
PROMPT -- 자동 통계 수집 작업이 마지막으로 돈 때
SELECT TO_CHAR(window_start_time, 'MM-DD HH24:MI') AS "실행 시각", job_status
  FROM (SELECT * FROM dba_autotask_job_history
         WHERE client_name LIKE '%stat%' ORDER BY window_start_time DESC)
 WHERE ROWNUM <= 3;

PROMPT
PROMPT -- 다른 사람이 남긴 보조 객체 (과제에 영향은 없지만 알고 시작한다)
SELECT table_name AS item, '보조 테이블' AS note
  FROM dba_tables
 WHERE owner = 'SQLT'
   AND table_name NOT IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                          'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
   AND table_name NOT LIKE 'BIN$%';


PROMPT
PROMPT === 5. 리소스 관리자 (카드 H 를 받았으면 반드시 기록) =======
SELECT name, value, isdefault FROM v$parameter WHERE name = 'resource_manager_plan';
SELECT name AS "활성 플랜", cpu_managed, instance_caging FROM v$rsrc_plan;


PROMPT
PROMPT === 6. 측정 준비 확인 ======================================
PROMPT -- GATHER_PLAN_STATISTICS 가 실제로 동작하는지 1회 확인한다.
SET FEEDBACK ON
SELECT /*+ GATHER_PLAN_STATISTICS PF00_PROBE */ COUNT(*) AS "HOSP_ID=1 건수"
  FROM sqlt.medical_claims WHERE hosp_id = 1;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
SET FEEDBACK OFF

PROMPT
PROMPT ============================================================
PROMPT  환경 기록 끝.
PROMPT
PROMPT  보고서 1장(측정 환경)에 아래 네 가지를 반드시 적는다.
PROMPT    1) 인스턴스 버전 · CPU 수 · 메모리 · SGA/PGA 설정
PROMPT    2) AWR 스냅샷 주기와 보존 기간  (= 사후 진단 가능 범위)
PROMPT    3) 대상 표 건수와, 기준에서 어긋난 항목(인덱스·히스토그램)
PROMPT    4) "개인 실습 VM 재현 사례" 라는 명시
PROMPT
PROMPT  ★ A-Rows·Buffers 열이 안 나오면 SET SERVEROUTPUT OFF 를 확인한다.
PROMPT    SERVEROUTPUT 가 켜져 있으면 DISPLAY_CURSOR 가 엉뚱한 커서를 잡는다.
PROMPT ============================================================
SET FEEDBACK ON
