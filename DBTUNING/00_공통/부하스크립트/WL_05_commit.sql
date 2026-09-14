-- ============================================================================
-- [실측 대기 2026-08-25] 정적 검증 통과. 다중 세션/PGA/커밋 부하는 SQL*Plus 실행 시 델타 확인 필요(README 4.1 절차).
-- WL_05_commit.sql  :  소량 DML + 잦은 커밋으로 log file sync 유발
-- Oracle Database 19c 성능 튜닝 실무 과정 · 공용 부하 스크립트 (5/6)
-- ============================================================================
-- 목적       : 같은 양의 DML을 두 가지 커밋 방식으로 실행해 대조한다.
--                구획 1) 건당 커밋 (1행 UPDATE -> COMMIT 반복)
--                구획 2) 배치 커밋 (N행 UPDATE 후 1회 COMMIT)
--              바뀐 데이터의 양(redo size)은 거의 같은데 log file sync 대기 횟수와
--              시간만 크게 달라지는 것을 보여, "일의 양"과 "대기"를 분리해
--              해석하는 훈련을 한다.
--              (14장 "log file sync 재현 - 커밋 빈도와의 관계"에서 사용)
--
-- 전제       : 1) SQLT 계정 접속. 원본 REVIEW_LOG(50만) 존재.
--              2) SQLT 에 CREATE TABLE 권한 필요(복제 테이블 생성).
--              3) V$ 뷰 조회 권한.  SYS 에서 1회 :  GRANT SELECT_CATALOG_ROLE TO SQLT;
--              4) 아카이브 로그 모드든 NOARCHIVELOG 든 재현된다. 다만 아카이브
--                 모드에서는 로그 스위치가 겹치면 수치가 크게 튈 수 있으니
--                 실행 직후 V$LOG_HISTORY 로 스위치 발생 여부를 함께 본다.
--              5) ★ 원본 REVIEW_LOG 은 절대 갱신하지 않는다. ★
--                 복제 테이블 REVIEW_LOG_CMT_WL 을 만들어 그 안에서만 DML 한다.
--                 원본은 CREATE TABLE ... AS SELECT 의 읽기 대상으로만 쓰인다.
--
-- 소요 시간  : 기본값(wl_rows=5000) 기준 대략 30초~1분 30초.
--              [근거] 커밋 1회는 LGWR 가 리두를 디스크에 내리고 응답할 때까지
--                     기다린다. 일반적인 실습 VM에서 log file sync 1회는
--                     대략 0.3~3ms 이므로 5,000회 x (0.3~3ms) = 약 2~15초.
--                     배치 커밋 구간은 커밋이 10회 남짓이라 1초 내외로 끝난다.
--                     여기에 복제 테이블 생성(5,000행 CTAS)과 스냅샷·집계 조회를
--                     더해 30초~1분 30초로 잡았다.
--              [조절] DEFINE wl_rows 를 바꾼다(시간은 대체로 선형).
--                     지표를 더 키우려면 20000, 짧게 끝내려면 2000.
--                     배치 크기는 DEFINE wl_batch 로 조절한다.
--
-- 관찰 지표  : log file sync (대기 횟수/시간), user commits,
--              redo size / redo entries / redo synch writes / redo synch time,
--              log file parallel write(백그라운드 LGWR 측 쓰기).
--              스크립트가 구획별 전후 델타와 두 방식 비교표를 스스로 출력한다.
--              추가로 아래 SQL을 직접 조회해 확인한다.
--
--                -- (1) 커밋 관련 대기
--                SELECT EVENT, TOTAL_WAITS, TIME_WAITED_MICRO,
--                       ROUND(TIME_WAITED_MICRO/DECODE(TOTAL_WAITS,0,1,TOTAL_WAITS)/1000,3) AVG_MS
--                  FROM V$SYSTEM_EVENT
--                 WHERE EVENT IN ('log file sync','log file parallel write',
--                                 'log file switch completion','log buffer space');
--
--                -- (2) 커밋/리두 통계
--                SELECT NAME, VALUE FROM V$SYSSTAT
--                 WHERE NAME IN ('user commits','user rollbacks','redo size',
--                                'redo entries','redo synch writes','redo synch time',
--                                'redo write time','redo wastage');
--
--                -- (3) 커밋 1건당 리두 크기 (Load Profile 의 "per transaction" 감각)
--                SELECT ROUND(r.VALUE / DECODE(c.VALUE,0,1,c.VALUE)) AS REDO_PER_COMMIT
--                  FROM V$SYSSTAT r, V$SYSSTAT c
--                 WHERE r.NAME='redo size' AND c.NAME='user commits';
--
--                -- (4) 로그 스위치가 끼어들었는지 확인
--                SELECT TO_CHAR(FIRST_TIME,'YYYY-MM-DD HH24:MI:SS') SWITCH_TIME, SEQUENCE#
--                  FROM V$LOG_HISTORY ORDER BY FIRST_TIME DESC FETCH FIRST 5 ROWS ONLY;
--
-- 되돌리기   : 1) 복제 테이블은 wl_cleanup=1(기본값)이면 스크립트 끝에서
--                 자동 삭제된다. 남겨 두려면 DEFINE wl_cleanup = 0 으로 실행하고
--                 나중에 직접 지운다 :   DROP TABLE REVIEW_LOG_CMT_WL PURGE;
--              2) 원본 REVIEW_LOG 은 변경한 적이 없으므로 원복 대상이 아니다.
--              3) 구획 3(COMMIT_WAIT=NOWAIT)을 실행했다면 세션 파라미터를 원복한다.
--                 스크립트가 자동으로 원복하지만, 수동으로 하려면 :
--                    ALTER SESSION SET COMMIT_WAIT = WAIT;
--                    ALTER SESSION SET COMMIT_LOGGING = IMMEDIATE;
--                 접속을 끊어도 원래대로 돌아간다.
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              리두를 대량으로 생성한다. 아카이브 로그 모드라면 아카이브 목적지
--              용량을 미리 확인할 것(가득 차면 인스턴스가 멈춘다).
--              COMMIT_WAIT=NOWAIT 는 커밋 응답을 리두 기록 완료 전에 돌려주는
--              설정이라, 인스턴스 장애 시 "커밋했다고 응답받은 트랜잭션"이
--              사라질 수 있다. 실습에서 원리를 보기 위한 것이고
--              운영 환경에 적용해서는 안 된다. 기본값은 실행하지 않음(0)이다.
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
--   wl_rows       : 각 구획에서 갱신할 행 수(= 건당 커밋 구획의 커밋 횟수). 기본 5000.
--   wl_batch      : 배치 커밋 구획의 커밋 단위. 기본 500 (5000행이면 커밋 10회).
--   wl_run_nowait : 1이면 구획 3(COMMIT_WAIT=NOWAIT) 도 실행. 기본 0(실행 안 함).
--                   ★ 데이터 유실 위험이 있는 설정이므로 원리 확인용으로만 켤 것 ★
--   wl_cleanup    : 1이면 스크립트 끝에서 복제 테이블을 삭제. 기본 1.
-- ----------------------------------------------------------------------------
DEFINE wl_rows       = 5000
DEFINE wl_batch      = 500
DEFINE wl_run_nowait = 0
DEFINE wl_cleanup    = 1

PROMPT
PROMPT ============================================================
PROMPT  WL_05_commit.sql  -  커밋 빈도와 log file sync
PROMPT    갱신 행수(wl_rows)   : &wl_rows
PROMPT    배치 크기(wl_batch)  : &wl_batch
PROMPT    NOWAIT 구획 실행     : &wl_run_nowait  (0=실행 안 함)
PROMPT    종료 시 정리         : &wl_cleanup
PROMPT ============================================================
PROMPT


-- ----------------------------------------------------------------------------
-- [2] 사전 점검 - 리두 구성과 커밋 관련 파라미터 (조치 전 근거 캡처)
-- ----------------------------------------------------------------------------
PROMPT >>> [사전 점검] 커밋/리두 관련 파라미터
COLUMN name  FORMAT A30
COLUMN value FORMAT A28
SELECT NAME, VALUE
  FROM V$PARAMETER
 WHERE NAME IN ('commit_wait','commit_logging','commit_write','log_buffer',
                'fast_start_mttr_target')
 ORDER BY NAME;

PROMPT >>> [사전 점검] 리두 로그 그룹 구성
SELECT GROUP#, THREAD#, SEQUENCE#, ROUND(BYTES/1024/1024) MB, MEMBERS, STATUS
  FROM V$LOG
 ORDER BY GROUP#;

PROMPT >>> [사전 점검] 커밋 관련 대기 (실행 전)
COLUMN event FORMAT A30
SELECT EVENT, TOTAL_WAITS, TIME_WAITED_MICRO,
       ROUND(TIME_WAITED_MICRO/DECODE(TOTAL_WAITS,0,1,TOTAL_WAITS)/1000,3) AVG_MS
  FROM V$SYSTEM_EVENT
 WHERE EVENT IN ('log file sync','log file parallel write',
                 'log file switch completion','log buffer space')
 ORDER BY EVENT;


-- ============================================================================
-- [3] 복제 테이블 생성  (원본 REVIEW_LOG 은 읽기 전용으로만 사용)
-- ============================================================================
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME = 'REVIEW_LOG_CMT_WL';
    IF v_cnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE REVIEW_LOG_CMT_WL PURGE';
        DBMS_OUTPUT.PUT_LINE('[준비] 기존 REVIEW_LOG_CMT_WL 을 삭제했다.');
    END IF;

    EXECUTE IMMEDIATE
        'CREATE TABLE REVIEW_LOG_CMT_WL AS ' ||
        'SELECT LOG_ID, CLAIM_ID, REVIEWER_ID, PROCESS_DATE, ACTION_MSG, ERROR_CODE ' ||
        '  FROM REVIEW_LOG WHERE ROWNUM <= ' || &wl_rows;

    EXECUTE IMMEDIATE
        'ALTER TABLE REVIEW_LOG_CMT_WL ' ||
        'ADD CONSTRAINT PK_REVIEW_LOG_CMT_WL PRIMARY KEY (LOG_ID)';

    -- 복제 테이블은 실행 시점에야 존재하므로 정적 SQL로 참조하면 익명 블록
    -- 컴파일 단계에서 PLS-00201 이 난다. 이후 모든 참조는 동적 SQL로 한다.
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM REVIEW_LOG_CMT_WL' INTO v_cnt;
    DBMS_OUTPUT.PUT_LINE('[준비] REVIEW_LOG_CMT_WL 생성 완료. 행수 = ' || v_cnt);
END;
/


-- ============================================================================
-- [4] 부하 실행 + 구획별 전후 지표 델타 출력
-- ============================================================================
DECLARE
    TYPE t_map IS TABLE OF NUMBER INDEX BY VARCHAR2(120);
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

    v_s0  t_map;   -- 시작
    v_s1  t_map;   -- 구획 1(건당 커밋) 직후
    v_s2  t_map;   -- 구획 2(배치 커밋) 직후
    v_s3  t_map;   -- 구획 3(NOWAIT) 직후

    v_ids  t_ids;
    v_t    NUMBER;
    v_el1  NUMBER := 0;
    v_el2  NUMBER := 0;
    v_el3  NUMBER := 0;
    v_cmt1 NUMBER := 0;
    v_cmt2 NUMBER := 0;

    c_upd  CONSTANT VARCHAR2(300) :=
        'UPDATE /* WL05_UPD */ REVIEW_LOG_CMT_WL ' ||
        '   SET ACTION_MSG   = :1, ' ||
        '       PROCESS_DATE = SYSDATE ' ||
        ' WHERE LOG_ID = :2';

    PROCEDURE p_snap(p_m OUT t_map) IS
    BEGIN
        p_m.DELETE;
        FOR r IN (
            SELECT '01 [SESS] ' || sn.NAME AS k, ms.VALUE AS v
              FROM V$MYSTAT ms, V$STATNAME sn
             WHERE ms.STATISTIC# = sn.STATISTIC#
               AND sn.NAME IN ('user commits','user rollbacks','redo size',
                               'redo entries','redo synch writes','redo synch time',
                               'redo wastage','db block changes','execute count')
            UNION ALL
            SELECT '02 [INST] ' || NAME, VALUE
              FROM V$SYSSTAT
             WHERE NAME IN ('user commits','redo size','redo entries',
                            'redo synch writes','redo synch time',
                            'redo write time','redo blocks written',
                            'redo log space requests')
            UNION ALL
            SELECT '03 [SESS] ' || EVENT || '  (대기횟수)', TOTAL_WAITS
              FROM V$SESSION_EVENT
             WHERE SID = SYS_CONTEXT('USERENV','SID')
               AND EVENT IN ('log file sync','log file switch completion',
                             'log buffer space','buffer busy waits')
            UNION ALL
            SELECT '04 [SESS] ' || EVENT || '  (대기ms)', ROUND(TIME_WAITED_MICRO/1000)
              FROM V$SESSION_EVENT
             WHERE SID = SYS_CONTEXT('USERENV','SID')
               AND EVENT IN ('log file sync','log file switch completion',
                             'log buffer space','buffer busy waits')
            UNION ALL
            SELECT '05 [INST] ' || EVENT || '  (대기횟수)', TOTAL_WAITS
              FROM V$SYSTEM_EVENT
             WHERE EVENT IN ('log file sync','log file parallel write',
                             'log file switch completion','log buffer space')
            UNION ALL
            SELECT '06 [INST] ' || EVENT || '  (대기ms)', ROUND(TIME_WAITED_MICRO/1000)
              FROM V$SYSTEM_EVENT
             WHERE EVENT IN ('log file sync','log file parallel write',
                             'log file switch completion','log buffer space')
        ) LOOP
            p_m(r.k) := r.v;
        END LOOP;
    END p_snap;

    FUNCTION f_get(p_m t_map, p_k VARCHAR2) RETURN NUMBER IS
    BEGIN
        IF p_m.EXISTS(p_k) THEN RETURN p_m(p_k); ELSE RETURN 0; END IF;
    END f_get;

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

    -- 두 구획을 나란히 비교하는 요약표
    PROCEDURE p_compare(p_key VARCHAR2, p_label VARCHAR2,
                        p_b1 t_map, p_a1 t_map, p_b2 t_map, p_a2 t_map) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_label,44) ||
            LPAD(TO_CHAR(f_get(p_a1,p_key)-f_get(p_b1,p_key),'999,999,999,990'),24) ||
            LPAD(TO_CHAR(f_get(p_a2,p_key)-f_get(p_b2,p_key),'999,999,999,990'),24));
    END p_compare;

BEGIN
    -- 갱신 대상 키 목록 확보 (동적 SQL - [3]절 주석 참조)
    EXECUTE IMMEDIATE 'SELECT LOG_ID FROM REVIEW_LOG_CMT_WL ORDER BY LOG_ID'
        BULK COLLECT INTO v_ids;
    DBMS_OUTPUT.PUT_LINE('[WL_05] 갱신 대상 ' || v_ids.COUNT || ' 행 확보.');

    p_snap(v_s0);

    --------------------------------------------------------------------------
    -- 구획 1 : 건당 커밋  (1행 UPDATE -> COMMIT)
    --   커밋할 때마다 LGWR 가 리두를 디스크에 내리고 응답할 때까지 기다린다.
    --   이 기다림이 log file sync 다.
    --------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('>>> 구획 1 : 건당 커밋 시작 (' || v_ids.COUNT || '회 커밋)');
    v_t := DBMS_UTILITY.GET_TIME;

    FOR i IN 1 .. v_ids.COUNT LOOP
        EXECUTE IMMEDIATE c_upd USING 'WL05-ROW-' || i, v_ids(i);
        COMMIT;
        v_cmt1 := v_cmt1 + 1;
    END LOOP;

    v_el1 := (DBMS_UTILITY.GET_TIME - v_t) / 100;
    DBMS_OUTPUT.PUT_LINE('    구획 1 완료 : ' || v_el1 || ' 초, 커밋 ' || v_cmt1 || ' 회');
    p_snap(v_s1);

    --------------------------------------------------------------------------
    -- 구획 2 : 배치 커밋  (wl_batch 행마다 1회 COMMIT)
    --   바꾸는 데이터 양은 같다. 커밋 횟수만 1/wl_batch 로 줄어든다.
    --------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('>>> 구획 2 : 배치 커밋 시작 (' || &wl_batch || '행마다 커밋)');
    v_t := DBMS_UTILITY.GET_TIME;

    FOR i IN 1 .. v_ids.COUNT LOOP
        EXECUTE IMMEDIATE c_upd USING 'WL05-BAT-' || i, v_ids(i);
        IF MOD(i, &wl_batch) = 0 THEN
            COMMIT;
            v_cmt2 := v_cmt2 + 1;
        END IF;
    END LOOP;
    COMMIT;
    v_cmt2 := v_cmt2 + 1;

    v_el2 := (DBMS_UTILITY.GET_TIME - v_t) / 100;
    DBMS_OUTPUT.PUT_LINE('    구획 2 완료 : ' || v_el2 || ' 초, 커밋 ' || v_cmt2 || ' 회');
    p_snap(v_s2);

    --------------------------------------------------------------------------
    -- 구획 3 (선택) : 건당 커밋 + COMMIT_WAIT = NOWAIT
    --   커밋 응답을 리두 기록 완료 전에 돌려준다 -> log file sync 가 사라진다.
    --   ★ 인스턴스 장애 시 커밋된 트랜잭션이 유실될 수 있다. 운영 금지. ★
    --------------------------------------------------------------------------
    v_s3 := v_s2;
    IF &wl_run_nowait = 1 THEN
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('>>> 구획 3 : COMMIT_WAIT=NOWAIT 로 건당 커밋 (원리 확인용)');
        EXECUTE IMMEDIATE 'ALTER SESSION SET COMMIT_WAIT = NOWAIT';
        EXECUTE IMMEDIATE 'ALTER SESSION SET COMMIT_LOGGING = BATCH';
        v_t := DBMS_UTILITY.GET_TIME;

        FOR i IN 1 .. v_ids.COUNT LOOP
            EXECUTE IMMEDIATE c_upd USING 'WL05-NOW-' || i, v_ids(i);
            COMMIT;
        END LOOP;

        v_el3 := (DBMS_UTILITY.GET_TIME - v_t) / 100;
        EXECUTE IMMEDIATE 'ALTER SESSION SET COMMIT_WAIT = WAIT';
        EXECUTE IMMEDIATE 'ALTER SESSION SET COMMIT_LOGGING = IMMEDIATE';
        DBMS_OUTPUT.PUT_LINE('    구획 3 완료 : ' || v_el3 || ' 초 (세션 설정은 원복했다)');
        p_snap(v_s3);
    ELSE
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('>>> 구획 3 건너뜀 (DEFINE wl_run_nowait = 1 이면 실행)');
    END IF;

    --------------------------------------------------------------------------
    -- 델타 리포트
    --------------------------------------------------------------------------
    p_head('[구획 1] 건당 커밋 ' || v_cmt1 || '회 - 전후 델타');
    p_diff(v_s0, v_s1);

    p_head('[구획 2] 배치 커밋 ' || v_cmt2 || '회 - 전후 델타');
    p_diff(v_s1, v_s2);

    IF &wl_run_nowait = 1 THEN
        p_head('[구획 3] NOWAIT 커밋 - 전후 델타');
        p_diff(v_s2, v_s3);
    END IF;

    --------------------------------------------------------------------------
    -- 두 방식 나란히 비교
    --------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE(RPAD('=',92,'='));
    DBMS_OUTPUT.PUT_LINE('[비교] 같은 행 수를 갱신했을 때 커밋 방식별 차이');
    DBMS_OUTPUT.PUT_LINE(RPAD('=',92,'='));
    DBMS_OUTPUT.PUT_LINE(RPAD('지표',44) || LPAD('건당 커밋',24) || LPAD('배치 커밋',24));
    DBMS_OUTPUT.PUT_LINE(RPAD('-',92,'-'));
    p_compare('01 [SESS] user commits',      'user commits (세션)',
              v_s0, v_s1, v_s1, v_s2);
    p_compare('01 [SESS] redo size',         'redo size (세션, bytes)',
              v_s0, v_s1, v_s1, v_s2);
    p_compare('01 [SESS] redo entries',      'redo entries (세션)',
              v_s0, v_s1, v_s1, v_s2);
    p_compare('01 [SESS] redo synch writes', 'redo synch writes (세션)',
              v_s0, v_s1, v_s1, v_s2);
    p_compare('01 [SESS] db block changes',  'db block changes (세션)',
              v_s0, v_s1, v_s1, v_s2);
    p_compare('03 [SESS] log file sync  (대기횟수)', 'log file sync 대기횟수',
              v_s0, v_s1, v_s1, v_s2);
    p_compare('04 [SESS] log file sync  (대기ms)',   'log file sync 대기ms',
              v_s0, v_s1, v_s1, v_s2);
    DBMS_OUTPUT.PUT_LINE(RPAD('-',92,'-'));
    DBMS_OUTPUT.PUT_LINE(RPAD('경과 시간(초)',44) ||
                         LPAD(TO_CHAR(v_el1,'999,990.99'),24) ||
                         LPAD(TO_CHAR(v_el2,'999,990.99'),24));
    DBMS_OUTPUT.PUT_LINE(RPAD('=',92,'='));

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('### 판정 포인트 ###');
    DBMS_OUTPUT.PUT_LINE('  1) db block changes / redo size 는 두 구획이 비슷해야 한다.');
    DBMS_OUTPUT.PUT_LINE('     "바꾼 데이터의 양"은 같기 때문이다.');
    DBMS_OUTPUT.PUT_LINE('  2) 그런데 log file sync 대기 횟수와 시간은 크게 벌어진다.');
    DBMS_OUTPUT.PUT_LINE('     늘어난 것은 일의 양이 아니라 "기다린 횟수"다.');
    DBMS_OUTPUT.PUT_LINE('     -> 11장 "부하 증가와 성능 저하 구분"의 반대 사례다.');
    DBMS_OUTPUT.PUT_LINE('  3) log file sync 평균 대기시간(ms)이 크면 커밋 빈도가 아니라');
    DBMS_OUTPUT.PUT_LINE('     리두 디스크 성능(log file parallel write)을 의심한다.');
    DBMS_OUTPUT.PUT_LINE('     두 이벤트의 평균 대기시간을 반드시 함께 본다.');
    DBMS_OUTPUT.PUT_LINE('  4) 배치 커밋이 항상 정답은 아니다. 커밋을 미루면 Undo 보존과');
    DBMS_OUTPUT.PUT_LINE('     잠금 유지 시간이 늘어난다(4장 ORA-01555, WL_04 잠금 경합).');
END;
/


-- ============================================================================
-- [5] 실행 후 관찰
-- ============================================================================
PROMPT
PROMPT >>> [실행 후] 커밋 관련 대기 (실행 전 값과 비교할 것)
SELECT EVENT, TOTAL_WAITS, TIME_WAITED_MICRO,
       ROUND(TIME_WAITED_MICRO/DECODE(TOTAL_WAITS,0,1,TOTAL_WAITS)/1000,3) AVG_MS
  FROM V$SYSTEM_EVENT
 WHERE EVENT IN ('log file sync','log file parallel write',
                 'log file switch completion','log buffer space')
 ORDER BY EVENT;

PROMPT
PROMPT >>> [실행 후] 커밋/리두 통계
SELECT NAME, VALUE
  FROM V$SYSSTAT
 WHERE NAME IN ('user commits','user rollbacks','redo size','redo entries',
                'redo synch writes','redo synch time','redo write time',
                'redo blocks written','redo wastage','redo log space requests')
 ORDER BY NAME;

PROMPT
PROMPT >>> [실행 후] 커밋 1건당 리두 크기 (AWR Load Profile 의 per transaction 감각)
SELECT ROUND(r.VALUE) AS REDO_BYTES,
       c.VALUE        AS COMMITS,
       ROUND(r.VALUE / DECODE(c.VALUE,0,1,c.VALUE)) AS REDO_PER_COMMIT
  FROM V$SYSSTAT r, V$SYSSTAT c
 WHERE r.NAME = 'redo size'
   AND c.NAME = 'user commits';

PROMPT
PROMPT >>> [실행 후] 최근 로그 스위치 5건 (수치가 튄다면 여기부터 확인)
COLUMN switch_time FORMAT A22
SELECT TO_CHAR(FIRST_TIME,'YYYY-MM-DD HH24:MI:SS') AS SWITCH_TIME, SEQUENCE#
  FROM V$LOG_HISTORY
 ORDER BY FIRST_TIME DESC
 FETCH FIRST 5 ROWS ONLY;

PROMPT
PROMPT >>> [실행 후] 이번 부하의 DML SQL 통계
COLUMN sql_text FORMAT A50
SELECT SUBSTR(SQL_TEXT,1,50) AS SQL_TEXT, EXECUTIONS,
       ROUND(ELAPSED_TIME/1000000,2) AS ELAPSED_SEC,
       BUFFER_GETS, ROWS_PROCESSED
  FROM V$SQL
 WHERE SQL_TEXT LIKE '%WL05_UPD%'
   AND SQL_TEXT NOT LIKE '%V$SQL%'
 ORDER BY EXECUTIONS DESC
 FETCH FIRST 5 ROWS ONLY;


-- ============================================================================
-- [6] 되돌리기 - 세션 파라미터 원복 + 복제 테이블 정리
-- ============================================================================
PROMPT
PROMPT >>> [되돌리기] 세션 커밋 파라미터 원복
BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET COMMIT_WAIT = WAIT';
    EXECUTE IMMEDIATE 'ALTER SESSION SET COMMIT_LOGGING = IMMEDIATE';
    DBMS_OUTPUT.PUT_LINE('COMMIT_WAIT=WAIT, COMMIT_LOGGING=IMMEDIATE 로 원복했다.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('세션 파라미터 원복 생략 : ' || SQLERRM);
END;
/

PROMPT >>> [되돌리기] 복제 테이블 정리
DECLARE
    v_cnt NUMBER;
BEGIN
    IF &wl_cleanup <> 1 THEN
        DBMS_OUTPUT.PUT_LINE('[정리] wl_cleanup=0 이므로 REVIEW_LOG_CMT_WL 을 남긴다.');
        DBMS_OUTPUT.PUT_LINE('       나중에 직접 지울 것 : DROP TABLE REVIEW_LOG_CMT_WL PURGE;');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME = 'REVIEW_LOG_CMT_WL';
    IF v_cnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE REVIEW_LOG_CMT_WL PURGE';
        DBMS_OUTPUT.PUT_LINE('[정리] REVIEW_LOG_CMT_WL 삭제 완료.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('[정리] 원본 REVIEW_LOG 은 변경한 적이 없다.');
END;
/

PROMPT
PROMPT ============================================================
PROMPT  WL_05 완료.
PROMPT   - DML 대상은 복제 테이블 REVIEW_LOG_CMT_WL 뿐이었다.
PROMPT   - 원본 REVIEW_LOG 은 읽기만 했다.
PROMPT   - 14장 확장 : DEFINE wl_batch 를 1 / 100 / 1000 으로 바꿔가며
PROMPT     log file sync 대기 횟수와 경과 시간을 표로 정리한다.
PROMPT ============================================================
SET TIMING OFF
