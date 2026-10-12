-- ============================================================================
-- EX_00_환경점검.sql  :  평가 시작 전 기준 상태 확인 (응시자가 가장 먼저 실행)
-- DBTUNING 중간 평가(ch01~ch20) 공용 스크립트 (2/6)
-- ============================================================================
-- 목적       : 이 평가의 모든 기대값은 "진료비청구심사 스키마가 기준 상태"임을
--              전제한다. 기준 상태가 아니면 응시자의 측정값이 모범답안과 달라져
--              채점이 불가능하다. 7개 항목을 자동 판정해 OK / 조치필요 로 찍는다.
--              ch01 실습 01(환경 점검)과 ch15 실습 05(스키마 환경 점검)에서
--              배운 점검 항목을 그대로 쓴다.
--
-- 전제       : SQLT 계정 접속(sqlt/sqlt). V$ 뷰 조회 권한.
--
-- 소요 시간  : 약 10~30초 (건수 COUNT 7회).
--
-- 관찰 지표  : 표 건수 7종 · 인덱스(PK 만) · 히스토그램(HOSP_ID 하나)
--              statistics_level · cursor_sharing · 남은 _WL 복제 테이블
--              TEMP / UNDO 여유
--
-- 되돌리기   : 조회만 한다. 되돌릴 것이 없다.
--
-- 주의       : '조치필요' 가 하나라도 나오면 평가를 시작하지 말고 강사에게 알린다.
--              특히 PK 외 인덱스가 남아 있으면 문제 1 의 모든 Buffers 가 달라진다.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ============================================================
PROMPT  DBTUNING 중간 평가 (ch01~ch20) - 환경 점검
PROMPT ============================================================

COLUMN item   FORMAT A34
COLUMN found  FORMAT A30
COLUMN expect FORMAT A24
COLUMN verdict FORMAT A10

WITH cnt AS (
    SELECT 'HOSPITALS' t, COUNT(*) c FROM hospitals      UNION ALL
    SELECT 'PATIENTS',      COUNT(*)  FROM patients       UNION ALL
    SELECT 'DRUG_MASTER',   COUNT(*)  FROM drug_master    UNION ALL
    SELECT 'MEDICAL_CLAIMS',COUNT(*)  FROM medical_claims UNION ALL
    SELECT 'CLAIM_DETAILS', COUNT(*)  FROM claim_details  UNION ALL
    SELECT 'DISEASES',      COUNT(*)  FROM diseases       UNION ALL
    SELECT 'REVIEW_LOG',    COUNT(*)  FROM review_log
), chk AS (
    -- 1~5) 건수가 정확히 맞아야 하는 표
    SELECT 1 ord, '건수 ' || t item, TO_CHAR(c) found,
           TO_CHAR(e) expect, CASE WHEN c = e THEN 'OK' ELSE '조치필요' END verdict
      FROM cnt JOIN (SELECT 'HOSPITALS' t, 1000 e FROM dual UNION ALL
                     SELECT 'PATIENTS', 50000 FROM dual UNION ALL
                     SELECT 'DRUG_MASTER', 10000 FROM dual UNION ALL
                     SELECT 'MEDICAL_CLAIMS', 300000 FROM dual UNION ALL
                     SELECT 'REVIEW_LOG', 500000 FROM dual) USING (t)
    UNION ALL
    -- 6~7) DBMS_RANDOM 이 정하므로 범위로 본다
    SELECT 2, '건수 ' || t, TO_CHAR(c), '약 ' || TO_CHAR(e) || ' (±1%)',
           CASE WHEN ABS(c - e) <= e * 0.01 THEN 'OK' ELSE '조치필요' END
      FROM cnt JOIN (SELECT 'CLAIM_DETAILS' t, 900000 e FROM dual UNION ALL
                     SELECT 'DISEASES', 399500 FROM dual) USING (t)
    UNION ALL
    -- 8) 원본 7개 표의 인덱스는 PK 7개만
    --    (휴지통 BIN$ 객체와 다른 실습이 남긴 보조 테이블의 인덱스는 센다/안 센다를
    --     구분해야 하므로 대상 표를 7개로 못 박는다)
    SELECT 3, '원본 7개 표의 인덱스',
           'PK ' || COUNT(CASE WHEN index_name LIKE 'PK%' THEN 1 END) ||
           ' / 그 외 ' || COUNT(CASE WHEN index_name NOT LIKE 'PK%' THEN 1 END),
           'PK 7 / 그 외 0',
           CASE WHEN COUNT(*) = 7
                 AND COUNT(CASE WHEN index_name LIKE 'PK%' THEN 1 END) = 7
                THEN 'OK' ELSE '조치필요' END
      FROM user_indexes
     WHERE table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                          'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
    UNION ALL
    -- 9) 히스토그램은 MEDICAL_CLAIMS.HOSP_ID 하나 (원본 7개 표 기준)
    SELECT 4, '원본 7개 표의 히스토그램',
           NVL(LISTAGG(table_name || '.' || column_name, ',')
               WITHIN GROUP (ORDER BY table_name, column_name), '없음'),
           'MEDICAL_CLAIMS.HOSP_ID',
           CASE WHEN COUNT(*) = 1
                 AND MAX(table_name || '.' || column_name) = 'MEDICAL_CLAIMS.HOSP_ID'
                THEN 'OK' ELSE '조치필요' END
      FROM user_tab_col_statistics
     WHERE histogram <> 'NONE'
       AND table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                          'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
    UNION ALL
    -- 10) 이번 평가가 쓰는 이름의 잔재 (앞 응시자가 남긴 것)
    SELECT 5, '평가용 객체 잔재(EX_)',
           NVL(LISTAGG(table_name, ',') WITHIN GROUP (ORDER BY table_name), '없음'),
           '없음',
           CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE '조치필요' END
      FROM user_tables
     WHERE table_name IN ('REVIEW_LOG_EX_WL', 'EX_SNAP_WL')
    UNION ALL
    -- 11) 그 밖의 보조 테이블 (다른 챕터 실습 잔재) - 평가에는 영향이 없으나 알려 준다
    SELECT 8, '그 밖의 보조 테이블(참고)',
           NVL(LISTAGG(table_name, ',') WITHIN GROUP (ORDER BY table_name), '없음'),
           '평가에 영향 없음',
           '참고'
      FROM user_tables
     WHERE table_name NOT IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                              'CLAIM_DETAILS','DISEASES','REVIEW_LOG',
                              'REVIEW_LOG_EX_WL','EX_SNAP_WL')
       AND table_name NOT LIKE 'BIN$%'
    UNION ALL
    -- 11) statistics_level (ALL 이면 모든 SQL 이 느려져 측정이 왜곡된다)
    SELECT 6, '파라미터 statistics_level', value, 'TYPICAL',
           CASE WHEN value = 'TYPICAL' THEN 'OK' ELSE '조치필요' END
      FROM v$parameter WHERE name = 'statistics_level'
    UNION ALL
    -- 12) cursor_sharing (FORCE 면 문제 2 의 하드 파싱이 재현되지 않는다)
    SELECT 7, '파라미터 cursor_sharing', value, 'EXACT',
           CASE WHEN value = 'EXACT' THEN 'OK' ELSE '조치필요' END
      FROM v$parameter WHERE name = 'cursor_sharing'
)
SELECT item, found, expect, verdict FROM chk ORDER BY ord, item;

PROMPT
PROMPT >>> 세그먼트 크기 (원본 7개 표 + PK 기준: 합계 약 179 MB)
COLUMN segment_name FORMAT A22
SELECT segment_name, segment_type, ROUND(SUM(bytes)/1024/1024, 1) AS "MB"
  FROM user_segments
 WHERE segment_name NOT LIKE 'BIN$%'
 GROUP BY segment_name, segment_type
HAVING SUM(bytes) > 1024 * 1024
 ORDER BY SUM(bytes) DESC;

PROMPT >>> 휴지통 (용량만 차지한다. 비우려면 PURGE RECYCLEBIN)
SELECT COUNT(*) AS "휴지통_객체수",
       ROUND(NVL(SUM(space) * 8192 / 1024 / 1024, 0), 1) AS "휴지통_MB"
  FROM user_recyclebin;

PROMPT
PROMPT >>> TEMP / UNDO 여유 (문제 1 의 정렬, 문제 2 의 리두에 쓰인다)
COLUMN tablespace_name FORMAT A18
SELECT tablespace_name, ROUND(SUM(bytes_free)/1024/1024) AS "FREE_MB"
  FROM v$temp_space_header GROUP BY tablespace_name;
SELECT name, value FROM v$parameter WHERE name IN ('undo_retention','undo_tablespace');

PROMPT
PROMPT >>> 측정 준비 : GATHER_PLAN_STATISTICS 가 동작하는지 1회 확인
SELECT /*+ GATHER_PLAN_STATISTICS EX00_PROBE */ COUNT(*) AS "HOSP_ID_1_건수"
  FROM medical_claims WHERE hosp_id = 1;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

PROMPT
PROMPT ============================================================
PROMPT  위 verdict 에 '조치필요' 가 없으면 평가를 시작한다.
PROMPT  있으면 강사에게 알리고 기준 상태를 복구한 뒤 시작한다.
PROMPT    - PK 외 인덱스가 남음        : DROP INDEX <이름>;
PROMPT    - 히스토그램이 더 있음       : ch20 기준 상태 복구 명령
PROMPT        EXEC DBMS_STATS.GATHER_SCHEMA_STATS(USER, METHOD_OPT=>'FOR ALL COLUMNS SIZE 1')
PROMPT        EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'MEDICAL_CLAIMS', -
PROMPT               METHOD_OPT=>'FOR ALL COLUMNS SIZE 1 FOR COLUMNS SIZE 254 HOSP_ID', -
PROMPT               NO_INVALIDATE=>FALSE)
PROMPT    - 복제 테이블 잔재          : @EX_99_원복확인.sql
PROMPT ============================================================
SET FEEDBACK ON
