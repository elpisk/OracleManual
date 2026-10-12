-- ============================================================================
-- EX_99_원복확인.sql  :  평가가 만든 것만 지우고, 기준 상태로 돌아갔는지 판정한다
-- DBTUNING 중간 평가(ch01~ch20) 공용 스크립트 (6/6)
-- ============================================================================
-- 목적       : 응시자가 만든 인덱스와 복제 테이블을 지우고, 원본 7개 표가 평가 전
--              기준 상태로 돌아갔는지 판정한다. 원복은 채점 항목이다 - 다음
--              응시자와 ch21~ch34 의 모든 실측이 이 상태를 전제한다.
--
--              ★ 이 스크립트는 "이번 평가가 만든 것" 만 지운다 ★
--                지우는 것 : 이름이 EX_ 로 시작하는 인덱스(문제지 규칙),
--                            REVIEW_LOG_EX_WL, (DROPALL 일 때) EX_SNAP_WL
--                지우지 않는 것 : 원본 7개 표, PK 인덱스, 시퀀스, 그리고
--                            다른 챕터 실습이 남긴 보조 테이블·인덱스.
--                            이것들은 "수동확인" 으로 보고만 한다.
--
--              [설계 근거] 실습 랩은 여러 사람이 쓴다. "PK 가 아닌 인덱스는 전부
--              지운다" 식으로 만들면 다른 사람의 진행 중인 객체를 지우고, PK
--              제약을 지탱하는 인덱스를 지우려다 ORA-02429 로 중간에 멈춘다
--              (초판에서 실제로 겪었다). 그래서 지우는 대상을 이름으로 못 박았다.
--
-- 사용법     : @EX_99_원복확인.sql CHECK    -- 지우지 않고 무엇이 남았는지만 본다
--              @EX_99_원복확인.sql DROP     -- 평가 산출물을 지운다(EX_SNAP_WL 은 남긴다)
--              @EX_99_원복확인.sql DROPALL  -- 채점이 끝났으면 EX_SNAP_WL 까지
--
-- 전제       : SQLT 계정 접속(sqlt/sqlt).
--
-- 소요 시간  : CHECK 약 10초, DROP 약 10~40초(통계 재수집이 끼면 길어진다).
--
-- 관찰 지표  : USER_INDEXES · USER_TABLES · USER_TAB_COL_STATISTICS · 건수 7종
--
-- 되돌리기   : 이 스크립트 자체가 되돌리기다.
--
-- 주의       : 통계를 다시 모을 때 METHOD_OPT 기본값(SIZE AUTO)을 쓰면
--              MEDICAL_CLAIMS 의 여러 컬럼에 히스토그램이 생겨 ch01~ch20 의
--              E-Rows 가 전부 달라진다. 이 스크립트는 기준 상태를 만드는
--              Day 0 명령(히스토그램은 HOSP_ID 하나)만 쓴다.
--              그리고 기준 상태이면 아예 다시 모으지 않는다.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 200
SET FEEDBACK OFF
SET VERIFY OFF
SET DEFINE ON

DEFINE ex_mode = &1

PROMPT
PROMPT ============================================================
PROMPT  EX_99 - 평가 종료 원복   (모드 : &ex_mode)
PROMPT ============================================================

COLUMN kind    FORMAT A8
COLUMN name    FORMAT A26
COLUMN note    FORMAT A52
COLUMN item    FORMAT A28
COLUMN found   FORMAT A40
COLUMN verdict FORMAT A10


-- ----------------------------------------------------------------------------
-- [1] 지울 대상 / 손대지 않을 대상
-- ----------------------------------------------------------------------------
PROMPT >>> 이번 평가가 만든 것 (지운다)
SELECT 'INDEX' kind, index_name name, '응시자 인덱스 - 문제지 규칙상 EX_ 로 시작' note
  FROM user_indexes WHERE index_name LIKE 'EX\_%' ESCAPE '\'
UNION ALL
SELECT 'TABLE', table_name, 'EX_02 복제 테이블'
  FROM user_tables WHERE table_name = 'REVIEW_LOG_EX_WL'
UNION ALL
SELECT 'TABLE', table_name, 'EX_90 측정 스냅샷 - DROPALL 에서만 지움'
  FROM user_tables WHERE table_name = 'EX_SNAP_WL'
ORDER BY 1, 2;

PROMPT
PROMPT >>> 평가 범위 밖의 이탈 (지우지 않는다. 강사가 판단한다)
SELECT 'INDEX' kind, index_name name,
       '원본 표의 PK 외 인덱스 - 다른 실습 잔재로 보인다' note
  FROM user_indexes
 WHERE table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                      'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
   AND index_name NOT LIKE 'PK%'
   AND index_name NOT LIKE 'EX\_%' ESCAPE '\'
UNION ALL
SELECT 'TABLE', table_name, '다른 챕터 실습이 남긴 보조 테이블'
  FROM user_tables
 WHERE table_name NOT IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                          'CLAIM_DETAILS','DISEASES','REVIEW_LOG',
                          'REVIEW_LOG_EX_WL','EX_SNAP_WL')
   AND table_name NOT LIKE 'BIN$%'
ORDER BY 1, 2;


-- ----------------------------------------------------------------------------
-- [2] 삭제 (대상마다 따로 예외 처리 - 하나가 실패해도 나머지는 지운다)
-- ----------------------------------------------------------------------------
DECLARE
    v_mode VARCHAR2(10) := UPPER(NVL(TRIM('&ex_mode'), 'CHECK'));
    v_n    PLS_INTEGER := 0;

    PROCEDURE kill(p_ddl VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_ddl;
        DBMS_OUTPUT.PUT_LINE('[삭제] ' || p_ddl);
        v_n := v_n + 1;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[실패] ' || p_ddl || '  ->  ' || SQLERRM);
    END;
BEGIN
    IF v_mode NOT IN ('DROP', 'DROPALL') THEN
        DBMS_OUTPUT.PUT_LINE('[CHECK] 지우지 않았다. 실제로 지우려면 '
                             || '@EX_99_원복확인.sql DROP');
        RETURN;
    END IF;

    -- 응시자 인덱스 (이름이 EX_ 로 시작하는 것만)
    FOR r IN (SELECT index_name FROM user_indexes
               WHERE index_name LIKE 'EX\_%' ESCAPE '\') LOOP
        kill('DROP INDEX ' || r.index_name);
    END LOOP;

    -- 평가용 복제 테이블
    FOR r IN (SELECT table_name FROM user_tables
               WHERE table_name = 'REVIEW_LOG_EX_WL'
                  OR (table_name = 'EX_SNAP_WL' AND v_mode = 'DROPALL')) LOOP
        kill('DROP TABLE ' || r.table_name || ' PURGE');
    END LOOP;

    IF v_n = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[삭제] 지울 것이 없었다.');
    END IF;
END;
/


-- ----------------------------------------------------------------------------
-- [3] 통계 : 원본 7개 표가 기준 상태가 아니면만 다시 모은다
-- ----------------------------------------------------------------------------
DECLARE
    v_mode VARCHAR2(10) := UPPER(NVL(TRIM('&ex_mode'), 'CHECK'));
    v_bad  PLS_INTEGER;
BEGIN
    IF v_mode NOT IN ('DROP', 'DROPALL') THEN RETURN; END IF;

    SELECT COUNT(*) INTO v_bad
      FROM user_tab_col_statistics
     WHERE histogram <> 'NONE'
       AND table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                          'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
       AND NOT (table_name = 'MEDICAL_CLAIMS' AND column_name = 'HOSP_ID');

    SELECT v_bad + COUNT(*) INTO v_bad FROM dual
     WHERE NOT EXISTS (SELECT 1 FROM user_tab_col_statistics
                        WHERE table_name = 'MEDICAL_CLAIMS'
                          AND column_name = 'HOSP_ID' AND histogram <> 'NONE');

    IF v_bad = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[통계] 이미 기준 상태다(히스토그램은 HOSP_ID 하나). '
                             || '다시 모으지 않는다.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('[통계] 기준 상태에서 ' || v_bad
        || ' 건 벗어났다. Day 0 명령으로 다시 모은다.');
    FOR r IN (SELECT column_value t FROM TABLE(sys.odcivarchar2list(
                  'HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                  'CLAIM_DETAILS','DISEASES','REVIEW_LOG'))) LOOP
        DBMS_STATS.GATHER_TABLE_STATS(USER, r.t,
            METHOD_OPT => 'FOR ALL COLUMNS SIZE 1', CASCADE => TRUE);
    END LOOP;
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'MEDICAL_CLAIMS',
        METHOD_OPT    => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS SIZE 254 HOSP_ID',
        NO_INVALIDATE => FALSE);
    DBMS_OUTPUT.PUT_LINE('[통계] 완료.');
END;
/


-- ----------------------------------------------------------------------------
-- [4] 판정
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> 원복 판정 (원본 7개 표 기준)
SELECT '원본 7개 표의 인덱스' item,
       'PK ' || COUNT(CASE WHEN index_name LIKE 'PK%' THEN 1 END) ||
       ' / 그 외 ' || COUNT(CASE WHEN index_name NOT LIKE 'PK%' THEN 1 END) found,
       CASE WHEN COUNT(*) = 7 THEN 'OK' ELSE '수동확인' END verdict
  FROM user_indexes
 WHERE table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                      'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
UNION ALL
SELECT '평가용 객체(EX_)',
       NVL(LISTAGG(table_name, ',') WITHIN GROUP (ORDER BY table_name), '없음'),
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE '미원복' END
  FROM user_tables WHERE table_name IN ('REVIEW_LOG_EX_WL', 'EX_SNAP_WL')
UNION ALL
SELECT '원본 7개 표의 히스토그램',
       NVL(LISTAGG(table_name || '.' || column_name, ',')
           WITHIN GROUP (ORDER BY table_name), '없음'),
       CASE WHEN COUNT(*) = 1
             AND MAX(table_name || '.' || column_name) = 'MEDICAL_CLAIMS.HOSP_ID'
            THEN 'OK' ELSE '미원복' END
  FROM user_tab_col_statistics
 WHERE histogram <> 'NONE'
   AND table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                      'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
UNION ALL
SELECT '원본 표 건수',
       TO_CHAR((SELECT COUNT(*) FROM hospitals)) || '/' ||
       TO_CHAR((SELECT COUNT(*) FROM patients)) || '/' ||
       TO_CHAR((SELECT COUNT(*) FROM drug_master)) || '/' ||
       TO_CHAR((SELECT COUNT(*) FROM medical_claims)) || '/' ||
       TO_CHAR((SELECT COUNT(*) FROM review_log)),
       CASE WHEN (SELECT COUNT(*) FROM hospitals) = 1000
             AND (SELECT COUNT(*) FROM patients) = 50000
             AND (SELECT COUNT(*) FROM drug_master) = 10000
             AND (SELECT COUNT(*) FROM medical_claims) = 300000
             AND (SELECT COUNT(*) FROM review_log) = 500000
            THEN 'OK' ELSE '훼손!' END
  FROM dual;

PROMPT
PROMPT ============================================================
PROMPT  'OK' 만 있으면 다음 응시자를 받을 수 있다.
PROMPT  '미원복'  : 평가 산출물이 남았다 - @EX_99_원복확인.sql DROP 을 다시 실행.
PROMPT  '수동확인': 평가 범위 밖의 인덱스가 원본 표에 남아 있다. 위 [1] 의 두 번째
PROMPT             목록을 보고 강사가 판단한다(다른 실습 잔재일 수 있으므로
PROMPT             이 스크립트는 지우지 않는다).
PROMPT  '훼손!'   : 원본 데이터가 변경됐다 - 즉시 보고하고
PROMPT             진료비청구심사_스키마_생성.sql 로 재생성한다(건수는 원본 그대로).
PROMPT ============================================================
SET FEEDBACK ON
UNDEFINE ex_mode
