-- ============================================================================
-- PF_10_시나리오주입.sql  :  환경 결함을 걸고, 푼다 (카드 C·D·H)
-- AWR 진단 포트폴리오 과제 (4/5)
-- ============================================================================
-- 목적       : 시나리오 카드가 요구하는 "이미 망가진 환경" 을 만든다.
--              수강생은 무엇이 걸렸는지 모른 채 AWR 로 찾아내야 한다.
--              그래서 강사가 이 스크립트를 돌려 주고, 수강생에게는 카드만 준다.
--
--              열 장의 카드 중 환경 결함 세 장이 여기 있다. 나머지 일곱 장은
--              결함이 아니라 부하 패턴이라 수강생 세션에서 직접 돌아야 한다
--              (PF_11_부하패턴.sql, SQLT 로 실행).
--
--                C  히스토그램 삭제        - 쏠린 분포를 못 보게 만든다
--                D  표현식 통계 부재       - 가공 컬럼 조건의 선택도를 못 보게 한다
--                H  리소스 관리자 제한     - CPU 와 동시 세션 수를 묶는다
--
-- 전제       : SYS AS SYSDBA 로 접속.
--              PF_00_환경점검.sql 을 먼저 돌려 기준 상태를 기록했어야 한다.
--
-- 사용법     : 인자 2개를 넘긴다.
--
--                @PF_10_시나리오주입.sql C INJECT    -- 카드 C 결함을 건다
--                @PF_10_시나리오주입.sql C UNDO      -- 카드 C 만 되돌린다
--                @PF_10_시나리오주입.sql - STATUS    -- 지금 무엇이 걸려 있는가
--
--              INJECT 는 무엇을 걸었는지 화면에 적는다. 강사용 기록이다.
--              수강생에게 이 로그를 주면 답을 알려 주는 것이니 보여 주지 않는다.
--
-- 소요 시간  : C 10~40초 · D 20~60초 · H 5초.
--              UNDO 는 C·D 가 통계 재수집을 하므로 10~60초, H 는 5초 미만.
--
-- 관찰 지표  : 카드별로 다르다. 각 카드 블록의 주석에 "AWR 에서 어디를 보는가" 를
--              적어 두었다. 채점 기준과 같은 내용이다.
--
-- 되돌리기   : @PF_10_시나리오주입.sql <카드> UNDO  로 한 장씩,
--              또는 PF_99_원복.sql 로 전부. PF_99 가 더 확실하다.
--              ★ 카드 H 는 인스턴스 전체에 걸린다. 반드시 UNDO 를 돌린다.
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              1) 원본 7개 표의 데이터는 건드리지 않는다. 통계만 손댄다.
--                 표를 만들지도 지우지도 않는다.
--              2) 카드 H 만 ALTER SYSTEM 을 쓴다. 다른 카드는 세션·통계
--                 수준에서 끝난다. 랩을 같이 쓰는 사람이 있으면 H 는 양해를 구한다.
--              3) 여러 장을 동시에 걸지 않는다. 한 장씩 걸고, 보고서를 쓰고,
--                 되돌린 다음 다음 장으로 간다. 두 결함이 겹치면 AWR 만으로는
--                 원인을 가릴 수 없고, 그건 과제가 가르치려는 것이 아니다.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200 PAGESIZE 300 FEEDBACK OFF VERIFY OFF TAB OFF DEFINE ON

DEFINE pf_card = &1
DEFINE pf_act  = &2

COLUMN item FORMAT A34
COLUMN found FORMAT A34
COLUMN note FORMAT A48

PROMPT
PROMPT ============================================================
PROMPT  시나리오 주입  :  카드 &pf_card  /  동작 &pf_act
PROMPT ============================================================
PROMPT  ★ 이 화면은 강사용이다. 수강생에게 보여 주면 답을 알려 주는 것이다.
PROMPT ============================================================


DECLARE
    v_card VARCHAR2(8)  := UPPER('&pf_card');
    v_act  VARCHAR2(12) := UPPER('&pf_act');
    v_n    NUMBER;
    v_ext  VARCHAR2(1000);

    PROCEDURE say(p VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE(p); END;

    -- Day 0 통계. C·D 의 UNDO 가 공통으로 쓴다.
    PROCEDURE day0_stats IS
    BEGIN
        DBMS_STATS.GATHER_TABLE_STATS('SQLT', 'MEDICAL_CLAIMS',
            METHOD_OPT    => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS SIZE 254 HOSP_ID',
            CASCADE       => TRUE,
            NO_INVALIDATE => FALSE);
        say('[통계] MEDICAL_CLAIMS 기준 통계 재수집 (HOSP_ID 히스토그램 254 버킷)');
    END;
BEGIN

-- ===========================================================================
-- 카드 C : 히스토그램 삭제
-- ---------------------------------------------------------------------------
-- 무엇이 망가지는가
--   MEDICAL_CLAIMS.HOSP_ID 는 병원마다 청구 건수가 크게 다르다. 히스토그램이
--   있으면 옵티마이저가 그 쏠림을 본다. 히스토그램만 지우면 "1,000개 병원에
--   30만 건이 고르게 퍼져 있다" 고 믿고 건당 300건으로 계산한다.
--
-- 실측 (2026-10-14)
--   hosp_id = 1 단일 표     : E-Rows 3,506 -> 300   (A-Rows 3,058, 10.2배 과소)
--   상세 표 조인까지        : E-Rows 10,650 -> 911  (A-Rows 9,000, 9.9배 과소)
--
-- AWR 에서 어디를 보는가
--   - SQL ordered by Elapsed Time 에서 같은 SQL_ID 의 계획이 바뀐 것
--   - DBA_HIST_SQLSTAT 의 PLAN_HASH_VALUE 가 구간 전후로 다른 것
--   - 실행 계획의 E-Rows 와 A-Rows 차이 (AWR 이 아니라 DISPLAY_CURSOR 로 본다)
-- ===========================================================================
IF v_card = 'C' THEN
    IF v_act = 'INJECT' THEN
        DBMS_STATS.DELETE_COLUMN_STATS('SQLT', 'MEDICAL_CLAIMS', 'HOSP_ID',
            COL_STAT_TYPE => 'HISTOGRAM', NO_INVALIDATE => FALSE);
        say('[주입] MEDICAL_CLAIMS.HOSP_ID 히스토그램을 지웠다.');
        say('       컬럼 통계(NDV·최소·최대)는 남겨 두었다. 통계가 아예 없는 것이');
        say('       아니라 "분포만 모르는" 상태다. 이게 더 찾기 어렵다.');
        SELECT COUNT(*) INTO v_n FROM dba_tab_col_statistics
         WHERE owner='SQLT' AND table_name='MEDICAL_CLAIMS' AND histogram <> 'NONE';
        say('       남은 히스토그램 : ' || v_n || '개 (0 이어야 한다)');

    ELSIF v_act = 'UNDO' THEN
        day0_stats;
    END IF;


-- ===========================================================================
-- 카드 D : 표현식 통계 부재
-- ---------------------------------------------------------------------------
-- 무엇이 망가지는가
--   WHERE TO_CHAR(receipt_date,'YYYYMM') = '202406' 처럼 컬럼을 가공하면
--   옵티마이저는 그 컬럼의 통계를 쓸 수 없다. 기본 선택도 1% 를 끼운다.
--   30만 행의 1% = 3,000. 실제 6월 접수는 24,655 건이다.
--
--   ★ 이 카드는 거꾸로 걸린다 ★
--   기준 상태가 이미 "표현식 통계 없음" 이다. 그래서 INJECT 는 아무것도
--   걸지 않고, 수강생이 찾아낸 뒤 조치로 통계를 만든다. INJECT 는 그 조치가
--   먹히는지 강사가 미리 확인하는 용도다.
--
-- 실측 (2026-10-14)
--   전 : E-Rows 3,000  vs  A-Rows 24,655  (8.2배 과소)
--   후 : E-Rows 24,655 = A-Rows 24,655    (정확히 일치)
--   만들어진 확장 통계 이름 : SYS_STUX6K8UYPD0XXY_DGWEAYKFE8
--
-- AWR 에서 어디를 보는가
--   - SQL ordered by Elapsed Time / Buffer Gets 에 TO_CHAR 조건 SQL 이 올라온 것
--   - Segments by Logical Reads 에 MEDICAL_CLAIMS 가 올라온 것
--     (잘못된 추정 때문에 인덱스 대신 전체 스캔을 고른다)
-- ===========================================================================
ELSIF v_card = 'D' THEN
    IF v_act = 'INJECT' THEN
        say('[확인] 카드 D 는 기준 상태가 곧 결함이다. 걸 것이 없다.');
        SELECT COUNT(*) INTO v_n FROM dba_stat_extensions
         WHERE owner='SQLT' AND table_name='MEDICAL_CLAIMS';
        say('       MEDICAL_CLAIMS 확장 통계 : ' || v_n || '개 (0 이면 결함 상태)');
        IF v_n > 0 THEN
            say('       ★ 0 이 아니다. 앞 사람이 만든 것이 남았다. UNDO 를 먼저 돌려라.');
        END IF;
        say(' ');
        say('[참고] 수강생이 내야 할 조치는 이것이다 (강사용 정답) :');
        say('         DBMS_STATS.CREATE_EXTENDED_STATS(''SQLT'',''MEDICAL_CLAIMS'',');
        say('           ''(TO_CHAR("RECEIPT_DATE",''''YYYYMM''''))'');');
        say('       만든 뒤 METHOD_OPT 에 그 식을 넣어 다시 수집해야 값이 채워진다.');

    ELSIF v_act = 'VERIFY' THEN
        -- 강사가 조치의 효과를 미리 확인한다
        v_ext := DBMS_STATS.CREATE_EXTENDED_STATS('SQLT', 'MEDICAL_CLAIMS',
                     '(TO_CHAR("RECEIPT_DATE",''YYYYMM''))');
        say('[확인] 확장 통계 생성 : ' || v_ext);
        DBMS_STATS.GATHER_TABLE_STATS('SQLT', 'MEDICAL_CLAIMS',
            METHOD_OPT    => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS SIZE 254 HOSP_ID '
                          || 'FOR COLUMNS SIZE 254 (TO_CHAR("RECEIPT_DATE",''YYYYMM''))',
            NO_INVALIDATE => FALSE);
        say('       수집 완료. 이제 E-Rows 가 A-Rows 와 맞아야 한다.');

    ELSIF v_act = 'UNDO' THEN
        FOR r IN (SELECT extension FROM dba_stat_extensions
                   WHERE owner='SQLT' AND table_name='MEDICAL_CLAIMS') LOOP
            -- 커서의 SELECT 를 인자 자리에 바로 쓰면 PLS-00103 이 난다.
            -- 변수로 받아서 넘긴다.
            v_ext := r.extension;
            DBMS_STATS.DROP_EXTENDED_STATS('SQLT', 'MEDICAL_CLAIMS', v_ext);
            say('[원복] 확장 통계 제거 : ' || v_ext);
        END LOOP;
        day0_stats;
    END IF;


-- ===========================================================================
-- 카드 H : 리소스 관리자 제한
-- ---------------------------------------------------------------------------
-- 무엇이 망가지는가
--   SQLT 로 접속한 세션을 PF_BATCH_GROUP 에 넣고, 그 그룹에 CPU 20% 와
--   활성 세션 1개 제한을 건다. 같은 SQL 이 갑자기 느려지는데 실행 계획도
--   통계도 그대로다. 수강생은 "DB 안에서 일부러 묶어 놓은 것" 을 찾아야 한다.
--
-- AWR 에서 어디를 보는가
--   - Top 10 Foreground Events 에 resmgr: cpu quantum
--     (활성 세션 풀에 걸리면 resmgr:become active)
--   - Wait Class 가 Scheduler / Concurrency 로 쏠린다
--   - DB CPU 는 안 늘고 DB Time 만 늘어난다 - 기다린 시간이다
--   - Resource Limit Stats 와 보고서 머리의 활성 플랜 이름
--
-- ★ 이 카드만 ALTER SYSTEM 을 쓴다. 인스턴스 전체에 걸린다 ★
--   랩을 같이 쓰는 사람이 있으면 미리 양해를 구한다. 끝나면 반드시 UNDO.
--   매핑은 ORACLE_USER = 'SQLT' 로 좁혔다. SYS·SYSTEM 세션(백업 크론 등)은
--   영향을 받지 않는다.
-- ===========================================================================
ELSIF v_card = 'H' THEN
    IF v_act = 'INJECT' THEN
        SELECT name INTO v_ext FROM v$rsrc_plan WHERE ROWNUM = 1;
        say('[기록] 걸기 전 활성 플랜 : ' || v_ext || '  (UNDO 로 돌아간다)');

        DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA();

        DBMS_RESOURCE_MANAGER.CREATE_CONSUMER_GROUP(
            CONSUMER_GROUP => 'PF_BATCH_GROUP',
            COMMENT        => 'PF 과제 카드 H - 묶이는 쪽');
        DBMS_RESOURCE_MANAGER.CREATE_CONSUMER_GROUP(
            CONSUMER_GROUP => 'PF_OLTP_GROUP',
            COMMENT        => 'PF 과제 카드 H - 우대받는 쪽');

        DBMS_RESOURCE_MANAGER.CREATE_PLAN(
            PLAN    => 'PF_DAY_PLAN',
            COMMENT => 'PF 과제 카드 H');

        -- ★ 한 레벨의 MGMT_P 합은 정확히 100 이어야 한다 ★
        -- 2026-10-14 실측 : 80 + 20 + 100 으로 넣었더니 ORA-29375
        --   "값 합계 200(1 레벨)이 100을 초과함" 으로 검증에서 걸렸다.
        --   VALIDATE_PENDING_AREA 가 이걸 잡아 준다. 그래서 미결 영역이 있다.
        --
        -- OTHER_GROUPS 에 60 을 주는 이유 : SYS·SYSTEM 과 백업 크론이 거기
        -- 속한다. 레벨 1 에서 넉넉히 받아야 랩을 같이 쓰는 쪽이 굶지 않는다.
        DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
            PLAN => 'PF_DAY_PLAN', GROUP_OR_SUBPLAN => 'PF_OLTP_GROUP',
            COMMENT => '우대', MGMT_P1 => 30);
        DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
            PLAN => 'PF_DAY_PLAN', GROUP_OR_SUBPLAN => 'PF_BATCH_GROUP',
            COMMENT => '제한', MGMT_P1 => 10,
            ACTIVE_SESS_POOL_P1 => 1, QUEUEING_P1 => 30);
        DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
            PLAN => 'PF_DAY_PLAN', GROUP_OR_SUBPLAN => 'OTHER_GROUPS',
            COMMENT => '나머지(SYS·백업이 여기 속한다)', MGMT_P1 => 60);

        DBMS_RESOURCE_MANAGER.VALIDATE_PENDING_AREA();
        DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA();
        say('[주입] 플랜 PF_DAY_PLAN 과 소비자 그룹 2개를 만들었다.');

        -- 그룹을 쓸 권한을 주고, SQLT 세션을 그 그룹으로 보낸다
        DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP(
            GRANTEE_NAME => 'SQLT', CONSUMER_GROUP => 'PF_BATCH_GROUP',
            GRANT_OPTION => FALSE);
        DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA();
        DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
            ATTRIBUTE => DBMS_RESOURCE_MANAGER.ORACLE_USER,
            VALUE     => 'SQLT',
            CONSUMER_GROUP => 'PF_BATCH_GROUP');
        DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA();
        say('[주입] ORACLE_USER = SQLT 세션을 PF_BATCH_GROUP 으로 매핑했다.');
        say('       SYS·SYSTEM 은 매핑하지 않았다. 백업 크론은 영향이 없다.');

        EXECUTE IMMEDIATE 'ALTER SYSTEM SET resource_manager_plan = ''PF_DAY_PLAN''';
        say('[주입] 활성 플랜을 PF_DAY_PLAN 으로 바꿨다.');
        say('       ★ 인스턴스 전체에 걸렸다. 끝나면 반드시 UNDO 를 돌린다.');
        say('       매핑은 새 접속부터 적용된다. SQLT 세션을 다시 접속시킨다.');

    ELSIF v_act = 'UNDO' THEN
        -- 남의 플랜을 끄지 않는다. PF_ 로 시작할 때만 해제한다.
        BEGIN
            SELECT name INTO v_ext FROM v$rsrc_plan WHERE ROWNUM = 1;
            IF SUBSTR(v_ext, 1, 3) = 'PF_' THEN
                EXECUTE IMMEDIATE 'ALTER SYSTEM SET resource_manager_plan = ''''';
                say('[원복] 활성 플랜 ' || v_ext || ' 을 해제했다.');
            ELSE
                say('[원복] 활성 플랜은 ' || v_ext || ' 이다. PF 것이 아니라 둔다.');
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN say('[원복] 활성 플랜이 없다.');
            WHEN OTHERS THEN say('[원복] 플랜 해제 실패 : ' || SQLERRM);
        END;

        BEGIN
            DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA();
            DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
                ATTRIBUTE => DBMS_RESOURCE_MANAGER.ORACLE_USER,
                VALUE     => 'SQLT',
                CONSUMER_GROUP => NULL);     -- NULL 이 매핑 삭제다
            DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA();
            say('[원복] SQLT 매핑을 지웠다.');
        EXCEPTION WHEN OTHERS THEN
            DBMS_RESOURCE_MANAGER.CLEAR_PENDING_AREA();
            say('[원복] 매핑 삭제 실패 : ' || SQLERRM);
        END;

        BEGIN
            DBMS_RESOURCE_MANAGER_PRIVS.REVOKE_SWITCH_CONSUMER_GROUP(
                REVOKEE_NAME => 'SQLT', CONSUMER_GROUP => 'PF_BATCH_GROUP');
            say('[원복] SQLT 의 그룹 전환 권한을 회수했다.');
        EXCEPTION WHEN OTHERS THEN say('[원복] 권한 회수 생략 : ' || SQLERRM);
        END;

        -- 플랜을 먼저 지워야 그룹을 지울 수 있다. DELETE_PLAN_CASCADE 가 둘 다 한다.
        BEGIN
            DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA();
            DBMS_RESOURCE_MANAGER.DELETE_PLAN_CASCADE('PF_DAY_PLAN');
            DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA();
            say('[원복] 플랜 PF_DAY_PLAN 과 딸린 지시를 지웠다.');
        EXCEPTION WHEN OTHERS THEN
            DBMS_RESOURCE_MANAGER.CLEAR_PENDING_AREA();
            say('[원복] 플랜 삭제 실패 : ' || SQLERRM);
        END;

        FOR r IN (SELECT consumer_group FROM dba_rsrc_consumer_groups
                   WHERE SUBSTR(consumer_group, 1, 3) = 'PF_') LOOP
            BEGIN
                DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA();
                DBMS_RESOURCE_MANAGER.DELETE_CONSUMER_GROUP(r.consumer_group);
                DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA();
                say('[원복] 소비자 그룹 ' || r.consumer_group || ' 을 지웠다.');
            EXCEPTION WHEN OTHERS THEN
                DBMS_RESOURCE_MANAGER.CLEAR_PENDING_AREA();
                say('[원복] 그룹 ' || r.consumer_group || ' 삭제 실패 : ' || SQLERRM);
            END;
        END LOOP;
    END IF;


ELSIF v_act = 'STATUS' THEN
    NULL;   -- 아래 조회가 받는다

ELSE
    say('[안내] 카드는 C · D · E · H 중 하나다.');
    say('       A · B · F · G · I · J 는 부하 패턴이라 PF_11_부하패턴.sql 로');
    say('       SQLT 세션에서 돌린다.');
    say('       동작은 INJECT / UNDO / PREP(E) / VERIFY(D) / STATUS 다.');
END IF;

END;
/


-- ---------------------------------------------------------------------------
-- 지금 무엇이 걸려 있는가 (INJECT·UNDO·STATUS 뒤에 항상 찍는다)
-- ---------------------------------------------------------------------------
PROMPT
PROMPT === 현재 상태 =============================================

SELECT '카드 C 히스토그램' AS item,
       NVL(MAX(histogram), 'NONE') AS found,
       CASE WHEN COUNT(*) = 0 THEN '★ 걸려 있다 (지워진 상태)'
            ELSE '기준 상태' END AS note
  FROM dba_tab_col_statistics
 WHERE owner='SQLT' AND table_name='MEDICAL_CLAIMS'
   AND column_name='HOSP_ID' AND histogram <> 'NONE';

SELECT '카드 D 표현식 통계' AS item, TO_CHAR(COUNT(*)) AS found,
       CASE WHEN COUNT(*) = 0 THEN '★ 걸려 있다 (통계 없음 = 결함 상태)'
            ELSE '조치가 적용된 상태' END AS note
  FROM dba_stat_extensions
 WHERE owner='SQLT' AND table_name='MEDICAL_CLAIMS';

SELECT '카드 H 활성 플랜' AS item, name AS found,
       CASE WHEN SUBSTR(name, 1, 3) = 'PF_' THEN '★ 걸려 있다 - UNDO 를 잊지 말 것'
            ELSE '기준 상태' END AS note
  FROM v$rsrc_plan WHERE ROWNUM = 1;

PROMPT
PROMPT -- 카드 E 의 인덱스 (수강생이 조치로 만든다. 있으면 조치가 적용된 상태)
SELECT 'MEDICAL_CLAIMS.PAT_ID 인덱스' AS item,
       NVL(MAX(index_name), '없음') AS found,
       CASE WHEN COUNT(*) = 0 THEN '★ 걸려 있다 (인덱스 없음 = 결함 상태)'
            ELSE '조치가 적용된 상태' END AS note
  FROM dba_ind_columns
 WHERE index_owner = 'SQLT' AND table_name = 'MEDICAL_CLAIMS'
   AND column_name = 'PAT_ID' AND column_position = 1;

PROMPT
PROMPT ============================================================
SET FEEDBACK ON
UNDEFINE pf_card
UNDEFINE pf_act
