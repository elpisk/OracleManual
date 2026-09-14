-- ============================================================================
-- [실측 대기 2026-08-25] 정적 검증 통과. 다중 세션/PGA/커밋 부하는 SQL*Plus 실행 시 델타 확인 필요(README 4.1 절차).
-- WL_06_mixed.sql  :  종합 부하 (AWR / Statspack 스냅샷 구간용)
-- Oracle Database 19c 성능 튜닝 실무 과정 · 공용 부하 스크립트 (6/6)
-- ============================================================================
-- 목적       : WL_01~WL_05 의 부하를 축약해 한 세션에서 순환 실행하여
--              AWR 스냅샷 두 개 사이를 "읽을 거리가 있는 구간"으로 만든다.
--              파싱 / 물리 I/O / 정렬 / DML·커밋을 섞어 돌리므로 Load Profile,
--              Top Events, 시간 모델, 대기 클래스가 모두 움직인다.
--              스크립트 자신이 Load Profile 형식의 요약(초당·트랜잭션당)을
--              출력하므로, AWR 보고서를 읽기 전에 정답지를 손에 쥔 상태로
--              보고서를 대조해 볼 수 있다.
--              (5장 DB Time, 6장 AWR 인프라, 8장 AWR 판독, 9장 ADDM,
--               10장 ASH, 11장 기간 비교에서 사용)
--
-- 전제       : 1) SQLT 계정 접속. 진료비청구심사 스키마 7개 테이블이 모두 존재.
--              2) SQLT 에 CREATE TABLE 권한 필요(복제 테이블 생성).
--              3) V$ 뷰 조회 권한.  SYS 에서 1회 :  GRANT SELECT_CATALOG_ROLE TO SQLT;
--              4) 임시 테이블스페이스 여유 공간(정렬 구획).
--              5) 🔒 AWR 스냅샷·보고서는 Diagnostics Pack 라이선스가 필요하다.
--                 라이선스가 없으면 아래 [실행 절차]의 Statspack 경로를 쓴다.
--              6) ★ DML은 복제 테이블 REVIEW_LOG_MIX_WL 에서만 수행한다. ★
--                 원본 7개 테이블은 전부 읽기 전용으로만 사용한다.
--
-- 소요 시간  : 기본값(wl_cycles=3) 기준 대략 3~5분 (환경에 따라 2~6분).
--              [근거] 1주기 구성과 예상 시간(일반적인 실습 VM 기준)
--                       파싱   2,000회 리터럴          약  3~10초
--                       I/O    랜덤 2,000회 + 전체스캔 2회  약  3~20초
--                       정렬   CLAIM_DETAILS 1/4 정렬+해시  약 10~40초
--                       DML    2,000행 건당커밋 + 배치커밋  약  2~10초
--                       휴지   wl_gap_sec(기본 5초)
--                     합계 약 23~85초 x 3주기 = 약 1분 10초 ~ 4분 15초.
--                     여기에 준비·스냅샷·요약 출력을 더해 3~5분으로 잡았다.
--              [조절] DEFINE wl_cycles 로 주기 수를 조절한다(시간은 거의 선형).
--                     10분짜리 AWR 구간을 만들려면 wl_cycles = 8 정도로 올린다.
--                     스크립트가 실제 총 경과 시간을 마지막에 출력하므로,
--                     그 값을 보고 다음 실행의 wl_cycles 를 정하면 된다.
--
-- 관찰 지표  : Load Profile 전반.
--              DB time / DB CPU (V$SYS_TIME_MODEL),
--              대기 클래스별 시간 (V$SYSTEM_WAIT_CLASS),
--              redo size / session logical reads / physical reads /
--              user calls / parse count (total,hard) / execute count /
--              user commits + user rollbacks (= 트랜잭션 수),
--              주요 대기 이벤트(db file, log file sync, direct path temp, enq).
--              스크립트가 전후 델타와 "초당·트랜잭션당" 환산치를 스스로 출력한다.
--              추가로 아래 SQL을 직접 조회해 확인한다.
--
--                -- (1) DB Time 구성
--                SELECT STAT_NAME, ROUND(VALUE/1000000,2) SEC
--                  FROM V$SYS_TIME_MODEL ORDER BY VALUE DESC;
--
--                -- (2) 대기 클래스별 집계 (상위 클래스 지목)
--                SELECT WAIT_CLASS, TOTAL_WAITS, ROUND(TIME_WAITED/100,2) SEC
--                  FROM V$SYSTEM_WAIT_CLASS ORDER BY TIME_WAITED DESC;
--
--                -- (3) 상위 전경(foreground) 대기 이벤트
--                SELECT EVENT, WAIT_CLASS, TOTAL_WAITS,
--                       ROUND(TIME_WAITED_MICRO/1000000,2) SEC
--                  FROM V$SYSTEM_EVENT
--                 WHERE WAIT_CLASS <> 'Idle'
--                 ORDER BY TIME_WAITED_MICRO DESC FETCH FIRST 10 ROWS ONLY;
--
--                -- (4) 상위 SQL
--                SELECT SQL_ID, ROUND(ELAPSED_TIME/1000000,2) SEC, EXECUTIONS,
--                       BUFFER_GETS, DISK_READS, SUBSTR(SQL_TEXT,1,60) TXT
--                  FROM V$SQL WHERE PARSING_SCHEMA_NAME='SQLT'
--                 ORDER BY ELAPSED_TIME DESC FETCH FIRST 10 ROWS ONLY;
--
-- 되돌리기   : 1) 복제 테이블은 wl_cleanup=1(기본값)이면 스크립트 끝에서 자동 삭제.
--                 남겼다면 :  DROP TABLE REVIEW_LOG_MIX_WL PURGE;
--              2) 세션 파라미터(WORKAREA_SIZE_POLICY, _serial_direct_read,
--                 CURSOR_SHARING)는 [7]절에서 자동 원복한다. 접속을 끊어도
--                 원래대로 돌아간다.
--              3) 인스턴스 파라미터는 변경하지 않으므로 원복 대상이 없다.
--              4) AWR 스냅샷은 지우지 않아도 보존 기간이 지나면 자동 정리된다.
--                 굳이 지우려면 SYSDBA 로 :
--                    EXEC DBMS_WORKLOAD_REPOSITORY.DROP_SNAPSHOT_RANGE(시작ID, 끝ID);
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              CPU·I/O·리두·임시 테이블스페이스를 동시에 소모한다.
--              공유 DB에서 실행하면 다른 업무의 응답시간이 눈에 띄게 나빠진다.
--              행 잠금 경합(enq: TX)은 여러 세션이 있어야 재현되므로 이 스크립트에
--              포함하지 않았다. Load Profile 에 enqueue 대기까지 담고 싶다면
--              이 스크립트가 도는 동안 별도 터미널 2개에서 WL_04_lock.sql 을
--              A / B 역할로 함께 돌린다(아래 실행 절차 참조).
--
-- ============================================================================
--  ▶ 실행 절차 (AWR 스냅샷 구간 만들기)
-- ============================================================================
--   [터미널 1 : SYS AS SYSDBA]   🔒 Diagnostics Pack 필요
--     SQL> EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;
--     SQL> SELECT MAX(SNAP_ID) FROM DBA_HIST_SNAPSHOT;    -- 시작 스냅 ID 기록
--
--   [터미널 2 : SQLT]
--     SQL> @WL_06_mixed.sql
--
--   [선택 · 터미널 3,4 : SQLT]  잠금 경합까지 넣고 싶을 때
--     SQL> DEFINE wl_role = A   / @WL_04_lock.sql      (터미널 3)
--     SQL> DEFINE wl_role = B   / @WL_04_lock.sql      (터미널 4)
--
--   [터미널 1 : SYS AS SYSDBA]  부하 종료 후
--     SQL> EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;
--     SQL> @?/rdbms/admin/awrrpt.sql        -- 위 두 스냅 ID 구간 지정
--
--   [라이선스가 없을 때 - Statspack 대안 경로]
--     SQL> CONNECT perfstat/<pw>
--     SQL> EXEC STATSPACK.SNAP;
--          ... 부하 실행 ...
--     SQL> EXEC STATSPACK.SNAP;
--     SQL> @?/rdbms/admin/spreport.sql
--     또는 라이선스 없이도 되는 경로로, 이 스크립트가 출력하는
--     V$ 기반 델타 요약(아래 [6]절)을 그대로 쓴다.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- [0] SQL*Plus 환경 설정
-- ----------------------------------------------------------------------------
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 200
SET DEFINE ON
SET VERIFY OFF
SET FEEDBACK ON


-- ----------------------------------------------------------------------------
-- [1] 조절 변수
-- ----------------------------------------------------------------------------
--   wl_cycles      : 전체 주기 반복 횟수. 기본 3 (약 3~5분).
--   wl_parse_loops : 주기당 리터럴 SQL 실행 횟수 (WL_01 축약)
--   wl_rand        : 주기당 랜덤 단일 블록 조회 횟수 (WL_02 축약)
--   wl_scan        : 주기당 전체 스캔 반복 횟수     (WL_02 축약)
--   wl_sort_div    : 정렬 대상 축소 계수. 4면 약 1/4 행 (WL_03 축약)
--   wl_commit_rows : 주기당 DML 행 수               (WL_05 축약)
--   wl_batch       : 배치 커밋 단위
--   wl_gap_sec     : 주기 사이 휴지 시간(초). 부하에 강약을 주어 ASH 로
--                    스파이크를 구분하는 10장 실습에 쓰인다.
--   wl_cleanup     : 1이면 끝에서 복제 테이블 삭제
-- ----------------------------------------------------------------------------
DEFINE wl_cycles      = 3
DEFINE wl_parse_loops = 2000
DEFINE wl_rand        = 2000
DEFINE wl_scan        = 2
DEFINE wl_sort_div    = 4
DEFINE wl_commit_rows = 2000
DEFINE wl_batch       = 200
DEFINE wl_gap_sec     = 5
DEFINE wl_cleanup     = 1

PROMPT
PROMPT ============================================================
PROMPT  WL_06_mixed.sql  -  AWR 구간용 종합 부하
PROMPT    주기 수(wl_cycles)      : &wl_cycles
PROMPT    주기당 파싱             : &wl_parse_loops
PROMPT    주기당 랜덤읽기/스캔    : &wl_rand / &wl_scan
PROMPT    정렬 축소 계수          : &wl_sort_div
PROMPT    주기당 DML 행수/배치    : &wl_commit_rows / &wl_batch
PROMPT    주기 간 휴지(초)        : &wl_gap_sec
PROMPT ------------------------------------------------------------
PROMPT  시작 전에 SYSDBA 세션에서 AWR 스냅샷을 하나 떠 두었는가?
PROMPT    EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;   (Diagnostics Pack)
PROMPT ============================================================
PROMPT


-- ============================================================================
-- [2] 복제 테이블 생성 (DML 전용). 원본은 읽기만 한다.
-- ============================================================================
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME = 'REVIEW_LOG_MIX_WL';
    IF v_cnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE REVIEW_LOG_MIX_WL PURGE';
    END IF;

    EXECUTE IMMEDIATE
        'CREATE TABLE REVIEW_LOG_MIX_WL AS ' ||
        'SELECT LOG_ID, CLAIM_ID, REVIEWER_ID, PROCESS_DATE, ACTION_MSG, ERROR_CODE ' ||
        '  FROM REVIEW_LOG WHERE ROWNUM <= ' || &wl_commit_rows;
    EXECUTE IMMEDIATE
        'ALTER TABLE REVIEW_LOG_MIX_WL ' ||
        'ADD CONSTRAINT PK_REVIEW_LOG_MIX_WL PRIMARY KEY (LOG_ID)';

    -- 실행 시점에야 존재하는 테이블이므로 이후 참조는 전부 동적 SQL로 한다.
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM REVIEW_LOG_MIX_WL' INTO v_cnt;
    DBMS_OUTPUT.PUT_LINE('[준비] REVIEW_LOG_MIX_WL 생성 완료. 행수 = ' || v_cnt);
END;
/


-- ============================================================================
-- [3] 세션 설정
--     - 리터럴이 그대로 파싱되도록 CURSOR_SHARING = EXACT
--     - 전체 스캔이 scattered read 로 보이도록 직렬 직접경로읽기 끄기
--     - 정렬이 디스크로 넘어가도록 작업 영역 축소(세션 한정)
--     인스턴스 파라미터는 하나도 건드리지 않는다.
-- ============================================================================
ALTER SESSION SET CURSOR_SHARING = EXACT;
ALTER SESSION SET WORKAREA_SIZE_POLICY = MANUAL;
ALTER SESSION SET SORT_AREA_SIZE = 1048576;
ALTER SESSION SET SORT_AREA_RETAINED_SIZE = 1048576;
ALTER SESSION SET HASH_AREA_SIZE = 2097152;

BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET "_serial_direct_read" = NEVER';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[안내] _serial_direct_read 설정 생략 : ' || SQLERRM);
END;
/


-- ============================================================================
-- [4] 종합 부하 실행 + 전후 델타 + Load Profile 요약
-- ============================================================================
DECLARE
    TYPE t_map IS TABLE OF NUMBER INDEX BY VARCHAR2(120);
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

    v_s0    t_map;
    v_s1    t_map;
    v_ids   t_ids;

    v_n       NUMBER;
    v_n2      NUMBER;
    v_c       VARCHAR2(20);
    v_id      NUMBER;
    v_max_det NUMBER;
    v_max_log NUMBER;

    v_t_all   NUMBER;
    v_t       NUMBER;
    v_sec     NUMBER;

    v_el_parse  NUMBER := 0;
    v_el_io     NUMBER := 0;
    v_el_sort   NUMBER := 0;
    v_el_dml    NUMBER := 0;

    c_upd  CONSTANT VARCHAR2(300) :=
        'UPDATE /* WL06_UPD */ REVIEW_LOG_MIX_WL ' ||
        '   SET ACTION_MSG   = :1, ' ||
        '       PROCESS_DATE = SYSDATE ' ||
        ' WHERE LOG_ID = :2';

    ------------------------------------------------------------------
    -- 스냅샷 : 통계 + 시간 모델 + 대기 클래스 + 주요 대기 이벤트
    ------------------------------------------------------------------
    PROCEDURE p_snap(p_m OUT t_map) IS
    BEGIN
        p_m.DELETE;
        FOR r IN (
            SELECT '01 [TIME] ' || STAT_NAME AS k, ROUND(VALUE/1000) AS v
              FROM V$SYS_TIME_MODEL
             WHERE STAT_NAME IN ('DB time','DB CPU','sql execute elapsed time',
                                 'parse time elapsed','hard parse elapsed time',
                                 'PL/SQL execution elapsed time',
                                 'background elapsed time','background cpu time')
            UNION ALL
            SELECT '02 [INST] ' || NAME, VALUE
              FROM V$SYSSTAT
             WHERE NAME IN ('user calls','user commits','user rollbacks',
                            'session logical reads','db block changes',
                            'physical reads','physical writes','redo size',
                            'parse count (total)','parse count (hard)',
                            'execute count','sorts (memory)','sorts (disk)',
                            'table scans (long tables)','CPU used by this session')
            UNION ALL
            SELECT '03 [CLAS] ' || WAIT_CLASS || '  (대기ms)', ROUND(TIME_WAITED*10)
              FROM V$SYSTEM_WAIT_CLASS
             WHERE WAIT_CLASS <> 'Idle'
            UNION ALL
            SELECT '04 [EVNT] ' || EVENT || '  (대기ms)', ROUND(TIME_WAITED_MICRO/1000)
              FROM V$SYSTEM_EVENT
             WHERE EVENT IN ('db file sequential read','db file scattered read',
                             'direct path read','direct path read temp',
                             'direct path write temp','log file sync',
                             'log file parallel write','library cache: mutex X',
                             'latch: shared pool','cursor: pin S wait on X',
                             'enq: TX - row lock contention','buffer busy waits')
        ) LOOP
            p_m(r.k) := r.v;
        END LOOP;
    END p_snap;

    FUNCTION f_get(p_m t_map, p_k VARCHAR2) RETURN NUMBER IS
    BEGIN
        IF p_m.EXISTS(p_k) THEN RETURN p_m(p_k); ELSE RETURN 0; END IF;
    END f_get;

    FUNCTION f_d(p_k VARCHAR2) RETURN NUMBER IS
    BEGIN
        RETURN f_get(v_s1, p_k) - f_get(v_s0, p_k);
    END f_d;

    PROCEDURE p_head(p_title VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE(RPAD('=',122,'='));
        DBMS_OUTPUT.PUT_LINE(p_title);
        DBMS_OUTPUT.PUT_LINE(RPAD('=',122,'='));
        DBMS_OUTPUT.PUT_LINE(RPAD('지표',58) || LPAD('전(前)',20) ||
                             LPAD('후(後)',20) || LPAD('델타',20));
        DBMS_OUTPUT.PUT_LINE(RPAD('-',122,'-'));
    END p_head;

    PROCEDURE p_diff(p_bm t_map, p_am t_map) IS
        v_k VARCHAR2(120);
        v_d NUMBER;
    BEGIN
        v_k := p_am.FIRST;
        WHILE v_k IS NOT NULL LOOP
            v_d := p_am(v_k) - f_get(p_bm, v_k);
            IF v_d <> 0 OR SUBSTR(v_k,1,2) IN ('01','02') THEN
                DBMS_OUTPUT.PUT_LINE(
                    RPAD(SUBSTR(v_k,4),58) ||
                    LPAD(TO_CHAR(f_get(p_bm,v_k),'999,999,999,990'),20) ||
                    LPAD(TO_CHAR(p_am(v_k),      '999,999,999,990'),20) ||
                    LPAD(TO_CHAR(v_d,           'S999,999,999,990'),20));
            END IF;
            v_k := p_am.NEXT(v_k);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(RPAD('-',122,'-'));
    END p_diff;

    -- Load Profile 한 줄 : 델타 / 초당 / 트랜잭션당
    PROCEDURE p_lp(p_label VARCHAR2, p_val NUMBER, p_sec NUMBER, p_txn NUMBER) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_label,40) ||
            LPAD(TO_CHAR(p_val,'999,999,999,990'),20) ||
            LPAD(TO_CHAR(ROUND(p_val / GREATEST(p_sec,0.01), 2),'999,999,990.99'),20) ||
            LPAD(TO_CHAR(ROUND(p_val / GREATEST(p_txn,1),   2),'999,999,990.99'),20));
    END p_lp;

BEGIN
    SELECT MAX(DETAIL_ID) INTO v_max_det FROM CLAIM_DETAILS;
    SELECT MAX(LOG_ID)    INTO v_max_log FROM REVIEW_LOG;
    EXECUTE IMMEDIATE 'SELECT LOG_ID FROM REVIEW_LOG_MIX_WL ORDER BY LOG_ID'
        BULK COLLECT INTO v_ids;

    DBMS_OUTPUT.PUT_LINE('[WL_06] 종합 부하 시작 : ' ||
                         TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('        주기 ' || &wl_cycles || '회, DML 대상 ' ||
                         v_ids.COUNT || ' 행');

    p_snap(v_s0);
    v_t_all := DBMS_UTILITY.GET_TIME;

    FOR cyc IN 1 .. &wl_cycles LOOP
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('>>> 주기 ' || cyc || ' / ' || &wl_cycles ||
                             '  (' || TO_CHAR(SYSDATE,'HH24:MI:SS') || ')');

        ---------------------------------------------------------------- 파싱
        v_t := DBMS_UTILITY.GET_TIME;
        FOR i IN 1 .. &wl_parse_loops LOOP
            EXECUTE IMMEDIATE
                'SELECT /* WL06_LIT */ COUNT(*) FROM PATIENTS WHERE PAT_ID = '
                || (cyc * 100000 + i)
                INTO v_n;
        END LOOP;
        v_el_parse := v_el_parse + (DBMS_UTILITY.GET_TIME - v_t) / 100;
        DBMS_OUTPUT.PUT_LINE('    - 파싱 구획 완료');

        ---------------------------------------------------------------- I/O
        v_t := DBMS_UTILITY.GET_TIME;
        FOR i IN 1 .. &wl_rand LOOP
            v_id := TRUNC(DBMS_RANDOM.VALUE(1, v_max_det + 1));
            BEGIN
                SELECT /*+ INDEX(d PK_CLAIM_DETAILS) */ /* WL06_RAND */ d.AMT
                  INTO v_n FROM CLAIM_DETAILS d WHERE d.DETAIL_ID = v_id;
            EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
            END;

            IF MOD(i, 3) = 0 THEN
                v_id := TRUNC(DBMS_RANDOM.VALUE(1, v_max_log + 1));
                BEGIN
                    SELECT /*+ INDEX(l PK_REVIEW_LOG) */ /* WL06_RANDLOG */ l.CLAIM_ID
                      INTO v_c FROM REVIEW_LOG l WHERE l.LOG_ID = v_id;
                EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
                END;
            END IF;
        END LOOP;

        FOR i IN 1 .. &wl_scan LOOP
            SELECT /*+ FULL(d) NO_PARALLEL(d) */ /* WL06_SCAN */ SUM(d.AMT)
              INTO v_n FROM CLAIM_DETAILS d WHERE d.QTY >= 0;
            SELECT /*+ FULL(c) NO_PARALLEL(c) */ /* WL06_SCAN2 */ SUM(c.TOTAL_AMT)
              INTO v_n FROM MEDICAL_CLAIMS c WHERE c.TOTAL_AMT >= 0;
        END LOOP;
        v_el_io := v_el_io + (DBMS_UTILITY.GET_TIME - v_t) / 100;
        DBMS_OUTPUT.PUT_LINE('    - I/O 구획 완료');

        ---------------------------------------------------------------- 정렬
        v_t := DBMS_UTILITY.GET_TIME;
        SELECT /* WL06_SORT */ COUNT(*)
          INTO v_n
          FROM ( SELECT ROW_NUMBER() OVER (ORDER BY d.AMT, d.DETAIL_ID) rn
                   FROM CLAIM_DETAILS d
                  WHERE MOD(d.DETAIL_ID, &wl_sort_div) = 0 );

        SELECT /*+ LEADING(c d) USE_HASH(d) FULL(c) FULL(d)
                   NO_PARALLEL(c) NO_PARALLEL(d) */
               /* WL06_HASH */
               COUNT(*), SUM(d.AMT)
          INTO v_n, v_n2
          FROM MEDICAL_CLAIMS c, CLAIM_DETAILS d
         WHERE c.CLAIM_ID = d.CLAIM_ID
           AND MOD(d.DETAIL_ID, &wl_sort_div) = 0;
        v_el_sort := v_el_sort + (DBMS_UTILITY.GET_TIME - v_t) / 100;
        DBMS_OUTPUT.PUT_LINE('    - 정렬/해시 구획 완료');

        ---------------------------------------------------------------- DML
        v_t := DBMS_UTILITY.GET_TIME;
        -- 건당 커밋 (log file sync 유발)
        FOR i IN 1 .. v_ids.COUNT LOOP
            EXECUTE IMMEDIATE c_upd USING 'WL06-R' || cyc || '-' || i, v_ids(i);
            COMMIT;
        END LOOP;
        -- 배치 커밋 (대조군)
        FOR i IN 1 .. v_ids.COUNT LOOP
            EXECUTE IMMEDIATE c_upd USING 'WL06-B' || cyc || '-' || i, v_ids(i);
            IF MOD(i, &wl_batch) = 0 THEN COMMIT; END IF;
        END LOOP;
        COMMIT;
        v_el_dml := v_el_dml + (DBMS_UTILITY.GET_TIME - v_t) / 100;
        DBMS_OUTPUT.PUT_LINE('    - DML/커밋 구획 완료');

        ---------------------------------------------------------------- 휴지
        IF cyc < &wl_cycles AND &wl_gap_sec > 0 THEN
            DBMS_SESSION.SLEEP(&wl_gap_sec);
        END IF;
    END LOOP;

    v_sec := (DBMS_UTILITY.GET_TIME - v_t_all) / 100;
    p_snap(v_s1);

    --------------------------------------------------------------------------
    -- 전후 델타
    --------------------------------------------------------------------------
    p_head('[WL_06] 종합 부하 전후 델타  (총 경과 ' || v_sec || ' 초)');
    p_diff(v_s0, v_s1);

    --------------------------------------------------------------------------
    -- Load Profile 요약  (AWR 보고서의 Load Profile 과 같은 형식)
    --------------------------------------------------------------------------
    DECLARE
        v_txn NUMBER := f_d('02 [INST] user commits') + f_d('02 [INST] user rollbacks');
    BEGIN
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE(RPAD('=',100,'='));
        DBMS_OUTPUT.PUT_LINE('[Load Profile]  구간 ' || v_sec || ' 초 / 트랜잭션 ' ||
                             v_txn || ' 건');
        DBMS_OUTPUT.PUT_LINE(RPAD('=',100,'='));
        DBMS_OUTPUT.PUT_LINE(RPAD('항목',40) || LPAD('구간 합계',20) ||
                             LPAD('초당',20) || LPAD('트랜잭션당',20));
        DBMS_OUTPUT.PUT_LINE(RPAD('-',100,'-'));
        p_lp('DB Time (ms)',        f_d('01 [TIME] DB time'),               v_sec, v_txn);
        p_lp('DB CPU (ms)',         f_d('01 [TIME] DB CPU'),                v_sec, v_txn);
        p_lp('Redo size (bytes)',   f_d('02 [INST] redo size'),             v_sec, v_txn);
        p_lp('Logical reads',       f_d('02 [INST] session logical reads'), v_sec, v_txn);
        p_lp('Physical reads',      f_d('02 [INST] physical reads'),        v_sec, v_txn);
        p_lp('Physical writes',     f_d('02 [INST] physical writes'),       v_sec, v_txn);
        p_lp('Block changes',       f_d('02 [INST] db block changes'),      v_sec, v_txn);
        p_lp('User calls',          f_d('02 [INST] user calls'),            v_sec, v_txn);
        p_lp('Parses (total)',      f_d('02 [INST] parse count (total)'),   v_sec, v_txn);
        p_lp('Hard parses',         f_d('02 [INST] parse count (hard)'),    v_sec, v_txn);
        p_lp('Executes',            f_d('02 [INST] execute count'),         v_sec, v_txn);
        p_lp('Sorts (memory)',      f_d('02 [INST] sorts (memory)'),        v_sec, v_txn);
        p_lp('Sorts (disk)',        f_d('02 [INST] sorts (disk)'),          v_sec, v_txn);
        p_lp('Transactions',        v_txn,                                  v_sec, v_txn);
        DBMS_OUTPUT.PUT_LINE(RPAD('-',100,'-'));
        DBMS_OUTPUT.PUT_LINE('구획별 경과(초) : 파싱 ' || v_el_parse ||
                             ' / I/O ' || v_el_io ||
                             ' / 정렬 ' || v_el_sort ||
                             ' / DML ' || v_el_dml);
        DBMS_OUTPUT.PUT_LINE(RPAD('=',100,'='));
    END;

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('### 판정 포인트 ###');
    DBMS_OUTPUT.PUT_LINE('  1) 위 Load Profile 값을 AWR 보고서의 Load Profile 과 대조한다.');
    DBMS_OUTPUT.PUT_LINE('     AWR 구간이 이 부하 구간보다 넓으면 초당 값이 낮게 나온다.');
    DBMS_OUTPUT.PUT_LINE('     "구간을 어떻게 잡았는가"가 수치를 좌우한다는 것이 8장 요지다.');
    DBMS_OUTPUT.PUT_LINE('  2) [TIME] DB time 델타에서 DB CPU 를 뺀 값이 대략 대기 시간이다.');
    DBMS_OUTPUT.PUT_LINE('     [CLAS] 대기 클래스 델타 합과 비슷해야 앞뒤가 맞는다.');
    DBMS_OUTPUT.PUT_LINE('  3) enq: TX - row lock contention 이 0 이면 정상이다.');
    DBMS_OUTPUT.PUT_LINE('     이 스크립트는 단일 세션이라 잠금 경합을 만들지 않는다.');
    DBMS_OUTPUT.PUT_LINE('     필요하면 WL_04_lock.sql 을 별도 터미널에서 함께 돌린다.');
    DBMS_OUTPUT.PUT_LINE('  4) 총 경과 시간이 목표(3~5분)와 다르면 wl_cycles 를 조정한다.');
    DBMS_OUTPUT.PUT_LINE('     이번 실행 : ' || v_sec || ' 초 (주기 ' || &wl_cycles || '회)');
END;
/


-- ============================================================================
-- [5] 실행 후 관찰 - 부하 구간의 상위 항목
-- ============================================================================
PROMPT
PROMPT >>> [실행 후] DB Time 구성 (V$SYS_TIME_MODEL)
COLUMN stat_name FORMAT A40
SELECT STAT_NAME, ROUND(VALUE/1000000,2) AS SEC
  FROM V$SYS_TIME_MODEL
 ORDER BY VALUE DESC
 FETCH FIRST 12 ROWS ONLY;

PROMPT
PROMPT >>> [실행 후] 대기 클래스별 집계 (Idle 제외)
COLUMN wait_class FORMAT A22
SELECT WAIT_CLASS, TOTAL_WAITS, ROUND(TIME_WAITED/100,2) AS SEC
  FROM V$SYSTEM_WAIT_CLASS
 WHERE WAIT_CLASS <> 'Idle'
 ORDER BY TIME_WAITED DESC;

PROMPT
PROMPT >>> [실행 후] 상위 대기 이벤트 10 (Idle 제외)
COLUMN event FORMAT A34
SELECT EVENT, WAIT_CLASS, TOTAL_WAITS,
       ROUND(TIME_WAITED_MICRO/1000000,2) AS SEC,
       ROUND(TIME_WAITED_MICRO/DECODE(TOTAL_WAITS,0,1,TOTAL_WAITS)/1000,3) AS AVG_MS
  FROM V$SYSTEM_EVENT
 WHERE WAIT_CLASS <> 'Idle'
   AND TOTAL_WAITS > 0
 ORDER BY TIME_WAITED_MICRO DESC
 FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT >>> [실행 후] 이번 부하가 만든 상위 SQL (경과시간 기준)
COLUMN sql_text FORMAT A46
SELECT SQL_ID,
       ROUND(ELAPSED_TIME/1000000,2) AS SEC,
       EXECUTIONS, BUFFER_GETS, DISK_READS,
       SUBSTR(SQL_TEXT,1,46) AS SQL_TEXT
  FROM V$SQL
 WHERE SQL_TEXT LIKE '%WL06_%'
   AND SQL_TEXT NOT LIKE '%V$SQL%'
 ORDER BY ELAPSED_TIME DESC
 FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT >>> [실행 후] 리터럴 SQL 이 만든 커서 수 (WL_01 과 같은 현상)
SELECT COUNT(*) AS LITERAL_CURSORS,
       ROUND(SUM(SHARABLE_MEM)/1024/1024,3) AS SHARED_POOL_MB
  FROM V$SQLAREA
 WHERE SQL_TEXT LIKE '%WL06_LIT%';


-- ============================================================================
-- [6] 라이선스 없는 환경을 위한 안내
-- ============================================================================
PROMPT
PROMPT ------------------------------------------------------------
PROMPT  [라이선스 안내]
PROMPT   AWR / ADDM / ASH / DBA_HIST_* / V$ACTIVE_SESSION_HISTORY 는
PROMPT   Diagnostics Pack 라이선스가 필요하다.
PROMPT   라이선스가 없다면 :
PROMPT     - 위 [4]절이 출력한 V$ 기반 델타 요약을 그대로 쓴다
PROMPT     - Statspack 을 설치해 스냅샷/보고서를 쓴다
PROMPT         @?/rdbms/admin/spcreate.sql   (설치, PERFSTAT 계정)
PROMPT         EXEC STATSPACK.SNAP;          (스냅샷)
PROMPT         @?/rdbms/admin/spreport.sql   (보고서)
PROMPT   현재 설정 확인 : SHOW PARAMETER control_management_pack_access
PROMPT ------------------------------------------------------------


-- ============================================================================
-- [7] 되돌리기 - 세션 파라미터 원복 + 복제 테이블 정리
-- ============================================================================
PROMPT
PROMPT >>> [되돌리기] 세션 파라미터 원복
ALTER SESSION SET WORKAREA_SIZE_POLICY = AUTO;
ALTER SESSION SET CURSOR_SHARING = EXACT;

BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET "_serial_direct_read" = AUTO';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

PROMPT >>> [되돌리기] 복제 테이블 정리
DECLARE
    v_cnt NUMBER;
BEGIN
    IF &wl_cleanup <> 1 THEN
        DBMS_OUTPUT.PUT_LINE('[정리] wl_cleanup=0 이므로 REVIEW_LOG_MIX_WL 을 남긴다.');
        DBMS_OUTPUT.PUT_LINE('       나중에 직접 지울 것 : DROP TABLE REVIEW_LOG_MIX_WL PURGE;');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME = 'REVIEW_LOG_MIX_WL';
    IF v_cnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE REVIEW_LOG_MIX_WL PURGE';
        DBMS_OUTPUT.PUT_LINE('[정리] REVIEW_LOG_MIX_WL 삭제 완료.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('[정리] 원본 7개 테이블은 읽기만 했다. 변경 없음.');
END;
/

PROMPT
PROMPT ============================================================
PROMPT  WL_06 완료.
PROMPT   지금 SYSDBA 세션에서 종료 스냅샷을 뜨고 보고서를 만든다.
PROMPT     EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;
PROMPT     @?/rdbms/admin/awrrpt.sql
PROMPT   (라이선스가 없으면 Statspack 또는 위 [4]절 델타 요약을 사용)
PROMPT ============================================================
SET TIMING OFF
