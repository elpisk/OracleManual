-- ============================================================================
-- PF_99_원복.sql  :  과제가 만든 것만 지우고, 기준 통계로 되돌린다
-- AWR 진단 포트폴리오 과제 공용 스크립트 (3/3)
-- ============================================================================
-- 목적       : 시나리오 카드는 일부러 DB 를 망가뜨린다. 보고서를 다 쓴 뒤에는
--              다음 카드를 받을 수 있게 되돌려야 한다. 되돌리기까지가 진단이다.
--              운영에서도 "재현 환경을 원상복구했다" 를 못 쓰면 작업 승인을 못 받는다.
--
--              ★ 이 스크립트는 자기가 만든 것만 지운다 ★
--              이름이 PF_ 로 시작하는 객체와 PF_ADDM_ 작업만 건드린다.
--              그 밖에 기준과 어긋난 것은 '수동확인' 으로 적어서 보여 줄 뿐,
--              지우지 않는다. 실습 랩은 여러 사람이 쓰고, 남의 인덱스를 지우면
--              다른 장의 실습이 깨진다. 운영도 똑같다.
--
-- 전제       : SYS AS SYSDBA 로 접속. (PF_ 스크립트는 모두 SYS 로 돈다.
--              부하와 측정 쿼리만 SQLT 로 돈다)
--
-- 사용법     : SQL> SPOOL 01_근거/99_원복.log
--              SQL> @PF_99_원복.sql
--              SQL> SPOOL OFF
--
--              이 로그를 보고서 마지막 장(원복 확인)에 붙인다.
--
-- 소요 시간  : 약 10~60초. (실측 : 7개 표 통계 재수집 3초, 전체 약 10초.
--              버퍼 캐시가 식어 있으면 1~2분까지 걸린다)
--
-- 관찰 지표  : PF_ 객체 잔존 여부 · 확장 통계 수 · 히스토그램 목록
--              7개 표의 건수 · 활성 리소스 관리자 플랜
--
-- 되돌리기   : 이 스크립트가 되돌리기 그 자체다.
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              1) 세션 수준 변경(workarea_size_policy, sort_area_size 등)은
--                 접속을 끊으면 사라진다. 여기서 할 일이 없다.
--              2) ALTER SYSTEM 으로 바꾼 파라미터가 있으면 이 스크립트는
--                 되돌리지 않는다. 카드에 적힌 원복 명령을 직접 실행한다.
--                 (과제 규칙상 ALTER SYSTEM 을 쓰는 카드는 리소스 관리자 하나뿐이다)
--              3) 이미 만들어진 AWR 스냅샷은 지우지 않는다. 보존 기간이 지나면
--                 자동으로 사라진다. 보고서의 근거이므로 남겨 두는 게 맞다.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200 PAGESIZE 300 FEEDBACK OFF VERIFY OFF TAB OFF
COLUMN item   FORMAT A34
COLUMN found  FORMAT A30
COLUMN note   FORMAT A50

PROMPT
PROMPT ============================================================
PROMPT  PF 과제 원복
PROMPT ============================================================
SELECT TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') AS "실행 시각" FROM dual;


PROMPT
PROMPT === 1. 지우기 전에 무엇을 지울지 보여 준다 ==================
COLUMN object_name FORMAT A30
SELECT o.object_type AS item, o.object_name AS found,
       CASE WHEN SUBSTR(o.object_name, 1, 3) = 'PF_' THEN '지운다'
            WHEN o.object_type = 'INDEX'
             AND SUBSTR((SELECT i.table_name FROM dba_indexes i
                          WHERE i.owner = o.owner
                            AND i.index_name = o.object_name), 1, 3) = 'PF_'
                                                      THEN '표와 함께 지워진다'
            ELSE '수동확인 - 지우지 않는다' END AS note
  FROM dba_objects o
 WHERE o.owner = 'SQLT'
   AND o.object_name LIKE '%PF%'
   AND o.object_name NOT LIKE 'BIN$%'
 ORDER BY o.object_type, o.object_name;

SELECT 'ADVISOR TASK' AS item, task_name AS found, '지운다' AS note
  FROM dba_advisor_tasks
 WHERE owner = 'SYS' AND SUBSTR(task_name, 1, 8) = 'PF_ADDM_'
 ORDER BY task_name;


PROMPT
PROMPT === 2. PF_ 객체 제거 ======================================
DECLARE
    v_dropped NUMBER := 0;
    v_failed  NUMBER := 0;

    PROCEDURE say(p VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE(p); END;
BEGIN
    -- (1) PF_ 로 시작하는 표 (보관표 PF_SNAP, 카드가 만든 복제표 PF_*_WL 등)
    FOR r IN (SELECT table_name FROM dba_tables
               WHERE owner = 'SQLT'
                 AND SUBSTR(table_name, 1, 3) = 'PF_'
               ORDER BY table_name) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE SQLT.' || r.table_name || ' PURGE';
            v_dropped := v_dropped + 1;
            say('[제거] 표 ' || r.table_name);
        EXCEPTION WHEN OTHERS THEN
            v_failed := v_failed + 1;
            say('[실패] 표 ' || r.table_name || ' : ' || SQLERRM);
        END;
    END LOOP;

    -- (2) PF_ 로 시작하는 인덱스 (표와 함께 지워지지 않고 남은 것)
    FOR r IN (SELECT index_name, table_name FROM dba_indexes
               WHERE owner = 'SQLT'
                 AND SUBSTR(index_name, 1, 3) = 'PF_'
               ORDER BY index_name) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX SQLT.' || r.index_name;
            v_dropped := v_dropped + 1;
            say('[제거] 인덱스 ' || r.index_name || ' (' || r.table_name || ')');
        EXCEPTION WHEN OTHERS THEN
            -- ORA-02429 : 제약을 받치는 인덱스는 이 이름이어도 지우지 않는다
            v_failed := v_failed + 1;
            say('[실패] 인덱스 ' || r.index_name || ' : ' || SQLERRM);
        END;
    END LOOP;

    -- (3) PF_ 로 시작하는 뷰 / 시퀀스
    FOR r IN (SELECT object_type, object_name FROM dba_objects
               WHERE owner = 'SQLT'
                 AND object_type IN ('VIEW', 'SEQUENCE', 'SYNONYM')
                 AND SUBSTR(object_name, 1, 3) = 'PF_') LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP ' || r.object_type || ' SQLT.' || r.object_name;
            v_dropped := v_dropped + 1;
            say('[제거] ' || r.object_type || ' ' || r.object_name);
        EXCEPTION WHEN OTHERS THEN
            v_failed := v_failed + 1;
            say('[실패] ' || r.object_type || ' ' || r.object_name || ' : ' || SQLERRM);
        END;
    END LOOP;

    -- (4) ADDM 분석 작업
    FOR r IN (SELECT task_name FROM dba_advisor_tasks
               WHERE owner = 'SYS'
                 AND SUBSTR(task_name, 1, 8) = 'PF_ADDM_') LOOP
        BEGIN
            DBMS_ADVISOR.DELETE_TASK(r.task_name);
            v_dropped := v_dropped + 1;
            say('[제거] ADDM 작업 ' || r.task_name);
        EXCEPTION WHEN OTHERS THEN
            v_failed := v_failed + 1;
            say('[실패] ADDM 작업 ' || r.task_name || ' : ' || SQLERRM);
        END;
    END LOOP;

    say(' ');
    say('   제거 ' || v_dropped || '건, 실패 ' || v_failed || '건.');
    IF v_failed > 0 THEN
        say('   ★ 실패한 것은 보고서에 그대로 적는다. 숨기면 원복이 안 된 것이다.');
    END IF;
END;
/


PROMPT
PROMPT === 3. 확장 통계 제거 =====================================
PROMPT -- 기준은 확장 통계 0개다. 카드 D(표현식 통계)·컬럼 그룹 실험의 잔재를 지운다.
DECLARE
    v_ext VARCHAR2(1000);
    v_n   NUMBER := 0;
BEGIN
    FOR r IN (SELECT table_name, extension_name, extension
                FROM dba_stat_extensions
               WHERE owner = 'SQLT'
                 AND table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER',
                                    'MEDICAL_CLAIMS','CLAIM_DETAILS',
                                    'DISEASES','REVIEW_LOG')) LOOP
        -- DROP_EXTENDED_STATS 의 인자는 정의식이다. 커서 안의 SELECT 를
        -- 인자 자리에 바로 넣으면 PLS-00103 이 난다. 변수로 받아서 넘긴다.
        v_ext := r.extension;
        BEGIN
            DBMS_STATS.DROP_EXTENDED_STATS('SQLT', r.table_name, v_ext);
            v_n := v_n + 1;
            DBMS_OUTPUT.PUT_LINE('[제거] 확장 통계 ' || r.table_name || ' '
                                 || r.extension_name || ' = ' || v_ext);
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[실패] 확장 통계 ' || r.extension_name
                                 || ' : ' || SQLERRM);
        END;
    END LOOP;
    IF v_n = 0 THEN
        DBMS_OUTPUT.PUT_LINE('   확장 통계가 없다. 기준 상태다.');
    END IF;
END;
/


PROMPT
PROMPT === 4. 기준 통계 재수집 (Day 0 명령 그대로) ===============
PROMPT -- 이 한 번으로 아래 세 가지가 함께 되돌아온다.
PROMPT --   (1) 카드 C 가 지운 HOSP_ID 히스토그램이 다시 생긴다
PROMPT --   (2) 밤마다 도는 자동 통계 수집이 더 만든 히스토그램이 사라진다
PROMPT --       (METHOD_OPT 의 기본값 SIZE AUTO 가 6개를 더 만든다. 그러면
PROMPT --        ch01~ch14 의 E-Rows 실측값이 전부 달라진다)
PROMPT --   (3) 카드가 바꾼 통계(건수·블록 수)가 실제 값으로 맞춰진다
PROMPT -- 10초~2분 걸린다. 기다린다.

DECLARE
    v_t0 TIMESTAMP := SYSTIMESTAMP;
BEGIN
    -- 7개 표를 이름으로 지정한다. GATHER_SCHEMA_STATS 를 쓰면 다른 장이
    -- 남긴 보조 표(PATIENTS_WL 등)까지 건드린다. 남의 것은 손대지 않는다.
    FOR r IN (SELECT column_value AS t FROM TABLE(
                  SYS.ODCIVARCHAR2LIST('HOSPITALS','PATIENTS','DRUG_MASTER',
                                       'CLAIM_DETAILS','DISEASES','REVIEW_LOG'))) LOOP
        DBMS_STATS.GATHER_TABLE_STATS('SQLT', r.t,
            METHOD_OPT   => 'FOR ALL COLUMNS SIZE 1',
            CASCADE      => TRUE,
            NO_INVALIDATE => FALSE);
        DBMS_OUTPUT.PUT_LINE('[수집] ' || r.t);
    END LOOP;

    -- MEDICAL_CLAIMS 만 HOSP_ID 히스토그램을 가진다. 이것이 과정의 기준이다.
    DBMS_STATS.GATHER_TABLE_STATS('SQLT', 'MEDICAL_CLAIMS',
        METHOD_OPT    => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS SIZE 254 HOSP_ID',
        CASCADE       => TRUE,
        NO_INVALIDATE => FALSE);
    DBMS_OUTPUT.PUT_LINE('[수집] MEDICAL_CLAIMS (HOSP_ID 히스토그램 254 버킷)');

    DBMS_OUTPUT.PUT_LINE('   통계 재수집 '
        || ROUND(EXTRACT(SECOND FROM (SYSTIMESTAMP - v_t0))
               + EXTRACT(MINUTE FROM (SYSTIMESTAMP - v_t0)) * 60) || '초.');
END;
/

PROMPT
PROMPT -- 통계를 NO_INVALIDATE => FALSE 로 수집했으므로, 이 표를 쓰는 커서는
PROMPT -- 즉시 무효화됐다. 다음 실행에서 새 통계로 계획을 다시 짠다.
PROMPT -- 공유 풀을 통째로 비우지는 않는다. 랩을 같이 쓰는 다른 세션의
PROMPT -- 계획까지 날아가고, 그러면 그쪽 실측값이 달라진다.


PROMPT
PROMPT === 5. 리소스 관리자 플랜 =================================
PROMPT -- 카드 H(리소스 관리자)를 받았으면 PF_ 플랜이 활성일 수 있다.
PROMPT -- 기준은 "유지관리 창 밖에서는 플랜이 없다" 이다.
DECLARE
    v_plan VARCHAR2(128);
BEGIN
    SELECT name INTO v_plan FROM v$rsrc_plan WHERE ROWNUM = 1;

    IF SUBSTR(v_plan, 1, 3) = 'PF_' THEN
        EXECUTE IMMEDIATE 'ALTER SYSTEM SET resource_manager_plan = '''' SCOPE=MEMORY';
        DBMS_OUTPUT.PUT_LINE('[원복] 활성 플랜 ' || v_plan || ' 을 해제했다.');
        DBMS_OUTPUT.PUT_LINE('        플랜·소비자 그룹 정의 자체는 카드에 적힌');
        DBMS_OUTPUT.PUT_LINE('        DELETE_PLAN_CASCADE 로 직접 지운다.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('   활성 플랜 : ' || v_plan || ' (PF 과제가 만든 것이 아니다. 둔다)');
    END IF;
EXCEPTION WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('   활성 플랜 없음. 기준 상태다.');
END;
/

PROMPT
PROMPT -- PF 가 만든 플랜·소비자 그룹 정의가 남아 있는지만 알려 준다 (지우지 않는다)
SELECT 'PLAN' AS item, plan AS found, '수동확인 - 카드의 원복 절차를 따른다' AS note
  FROM dba_rsrc_plans WHERE SUBSTR(plan, 1, 3) = 'PF_'
UNION ALL
SELECT 'CONSUMER GROUP', consumer_group, '수동확인 - 카드의 원복 절차를 따른다'
  FROM dba_rsrc_consumer_groups WHERE SUBSTR(consumer_group, 1, 3) = 'PF_';


PROMPT
PROMPT === 6. 원복 확인 ==========================================

PROMPT
PROMPT -- (1) PF_ 객체가 남았는가  (0건이어야 한다)
SELECT NVL(MAX(object_type), '-') AS item,
       TO_CHAR(COUNT(*))          AS found,
       DECODE(COUNT(*), 0, '정상 - 남은 것이 없다', '★ 2단계 실패 로그를 확인한다') AS note
  FROM dba_objects
 WHERE owner = 'SQLT' AND SUBSTR(object_name, 1, 3) = 'PF_'
   AND object_name NOT LIKE 'BIN$%';

PROMPT
PROMPT -- (2) 확장 통계  (0개여야 한다)
SELECT '확장 통계' AS item, TO_CHAR(COUNT(*)) AS found,
       DECODE(COUNT(*), 0, '정상', '★ 3단계 실패 로그를 확인한다') AS note
  FROM dba_stat_extensions WHERE owner = 'SQLT';

PROMPT
PROMPT -- (3) 히스토그램  (MEDICAL_CLAIMS.HOSP_ID 하나여야 한다)
COLUMN column_name FORMAT A18
COLUMN table_name  FORMAT A16
COLUMN histogram   FORMAT A10
SELECT table_name, column_name, histogram, num_buckets,
       CASE WHEN table_name = 'MEDICAL_CLAIMS' AND column_name = 'HOSP_ID'
            THEN '기준' ELSE '★ 기준 외' END AS note
  FROM dba_tab_col_statistics
 WHERE owner = 'SQLT' AND histogram <> 'NONE'
   AND table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                      'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
 ORDER BY table_name, column_name;

PROMPT
PROMPT -- (4) 인덱스  (PK 7개가 기준. 그 외는 지우지 않고 적어만 둔다)
COLUMN index_name FORMAT A26
COLUMN table_name FORMAT A16
COLUMN status     FORMAT A8
SELECT index_name, table_name, status,
       CASE WHEN index_name LIKE 'PK%' THEN '기준'
            ELSE '수동확인 - 다른 장의 것일 수 있다. 지우지 않았다' END AS note
  FROM dba_indexes
 WHERE owner = 'SQLT'
   AND table_name IN ('HOSPITALS','PATIENTS','DRUG_MASTER','MEDICAL_CLAIMS',
                      'CLAIM_DETAILS','DISEASES','REVIEW_LOG')
 ORDER BY DECODE(SUBSTR(index_name,1,2), 'PK', 2, 1), table_name;

PROMPT
PROMPT -- (5) 건수  (과제는 원본 데이터를 바꾸지 않는다. 바뀌었으면 큰일이다)
WITH cnt AS (
    SELECT 'HOSPITALS' t, COUNT(*) c, 1000   e FROM sqlt.hospitals      UNION ALL
    SELECT 'PATIENTS',      COUNT(*), 50000    FROM sqlt.patients       UNION ALL
    SELECT 'DRUG_MASTER',   COUNT(*), 10000    FROM sqlt.drug_master    UNION ALL
    SELECT 'MEDICAL_CLAIMS',COUNT(*), 300000   FROM sqlt.medical_claims UNION ALL
    SELECT 'REVIEW_LOG',    COUNT(*), 500000   FROM sqlt.review_log
)
SELECT t AS item, TO_CHAR(c, '999,999,999') AS found,
       CASE WHEN c = e THEN '기준값 그대로'
            ELSE '★ 기준 ' || TO_CHAR(e, '999,999,999')
                 || ' 과 다르다 - 원본이 변경됐다' END AS note
  FROM cnt
 ORDER BY DECODE(t,'HOSPITALS',1,'PATIENTS',2,'DRUG_MASTER',3,'MEDICAL_CLAIMS',4,5);

PROMPT
PROMPT -- CLAIM_DETAILS·DISEASES 는 난수 건수라 기준 폭이 있다. 참고로만 본다.
SELECT 'CLAIM_DETAILS' AS item, TO_CHAR(COUNT(*), '999,999,999') AS found,
       '청구 1건당 1~5행 (약 90만)' AS note FROM sqlt.claim_details
UNION ALL
SELECT 'DISEASES', TO_CHAR(COUNT(*), '999,999,999'),
       '약제 마스터 기반 (약 40만)' FROM sqlt.diseases;


PROMPT
PROMPT ============================================================
PROMPT  원복 끝.
PROMPT
PROMPT  보고서 마지막 장(원복 확인)에 이 로그를 붙이고, 아래를 한 줄씩 쓴다.
PROMPT    1) 무엇을 지웠는가 (2~3단계의 [제거] 줄)
PROMPT    2) 기준으로 되돌아온 것 (히스토그램·확장 통계·건수)
PROMPT    3) '수동확인' 으로 남은 것과, 왜 손대지 않았는가
PROMPT       → "다른 수강생/다른 장의 객체일 수 있어 지우지 않았다" 가 정답이다.
PROMPT       → 운영에서 남의 인덱스를 지우면 그게 바로 장애다.
PROMPT    4) 세션 수준 변경은 접속 종료로 사라졌다는 사실
PROMPT
PROMPT  ★ 실패 줄이 있으면 숨기지 말고 적는다. 못 지운 것을 아는 것이
PROMPT    모르는 것보다 낫다. 채점에서도 그렇게 본다.
PROMPT ============================================================
SET FEEDBACK ON
