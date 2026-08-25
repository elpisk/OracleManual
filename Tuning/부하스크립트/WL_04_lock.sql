-- ============================================================================
-- [실측 대기 2026-08-25] 정적 검증 통과. 다중 세션/PGA/커밋 부하는 SQL*Plus 실행 시 델타 확인 필요(README 4.1 절차).
-- WL_04_lock.sql  :  동일 행 갱신에 의한 TX 행 잠금 경합 (최소 2세션 필요)
-- Oracle Database 19c 성능 튜닝 실무 과정 · 공용 부하 스크립트 (4/6)
-- ============================================================================
-- 목적       : 세션 A가 특정 행을 UPDATE 한 뒤 커밋하지 않고 대기하고, 세션 B가
--              같은 행을 UPDATE 해 블로킹되는 고전적 구성으로
--              'enq: TX - row lock contention' 대기를 재현한다.
--              세션 C에서 블로커와 대기자를 추적하는 절차를 함께 익힌다.
--              (3장 긴급 대응, 12장 알림 대응, 14장 enqueue 대기 분석에서 사용)
--
-- 전제       : 1) SQLT 계정으로 접속한 SQL*Plus 터미널 3개 (A / B / C).
--                 최소 2개(A, B)만 있어도 재현은 되지만, 관찰(C)이 이 실습의 본체다.
--              2) SQLT 에 CREATE TABLE 권한 필요(복제 테이블 생성).
--              3) V$ 뷰 조회 권한.  SYS 에서 1회 :  GRANT SELECT_CATALOG_ROLE TO SQLT;
--              4) ★ 원본 REVIEW_LOG 은 절대 건드리지 않는다. ★
--                 복제 테이블 REVIEW_LOG_WL 을 만들어 그 안에서만 갱신한다.
--                 원본은 CREATE TABLE ... AS SELECT 의 읽기 대상으로만 쓰인다.
--
-- 소요 시간  : 세션 A 기준 wl_hold_sec(기본 60초) + 관찰 조회 시간 = 약 1~2분.
--              세션 B는 A가 롤백할 때까지 블로킹되므로 최대 wl_hold_sec 만큼 기다린다.
--              [근거] 블로킹은 "시간이 걸리는 계산"이 아니라 "대기"다. 그래서
--                     소요 시간이 곧 wl_hold_sec 이다. 60초로 잡은 이유는
--                     세션 C에서 V$SESSION / V$LOCK / DBA_WAITERS 를 차례로
--                     조회하며 관찰하기에 60초면 충분하기 때문이다.
--              [조절] DEFINE wl_hold_sec 값을 바꾼다. 관찰 항목을 더 늘려
--                     실습하려면 120~180 으로 올린다.
--
-- 관찰 지표  : enq: TX - row lock contention (V$SESSION_EVENT / V$SYSTEM_EVENT),
--              V$SESSION 의 BLOCKING_SESSION / BLOCKING_SESSION_STATUS /
--              SECONDS_IN_WAIT / EVENT / ROW_WAIT_OBJ# ,
--              V$LOCK 의 TYPE='TX' 행 (LMODE=6 보유 / REQUEST=6 요청),
--              enqueue waits / enqueue requests 통계.
--              세션 B가 자신의 대기 델타를 스스로 출력한다.
--              세션 C용 조회 SQL은 아래 [5]절에 있고, 핵심만 다시 적으면 :
--
--                -- (1) 블로커와 대기자 한눈에 보기
--                SELECT SID, SERIAL#, USERNAME, STATUS, EVENT, SECONDS_IN_WAIT,
--                       BLOCKING_SESSION_STATUS, BLOCKING_SESSION, SQL_ID
--                  FROM V$SESSION
--                 WHERE BLOCKING_SESSION IS NOT NULL
--                    OR SID IN (SELECT BLOCKING_SESSION FROM V$SESSION
--                                WHERE BLOCKING_SESSION IS NOT NULL);
--
--                -- (2) TX 락 보유/요청
--                SELECT SID, TYPE, ID1, ID2, LMODE, REQUEST, CTIME, BLOCK
--                  FROM V$LOCK WHERE TYPE IN ('TX','TM') ORDER BY TYPE, ID1;
--                   -- LMODE=6 인 행이 보유자, REQUEST=6 인 행이 대기자다.
--                   -- 두 행의 ID1/ID2 가 같으면 같은 트랜잭션을 두고 다투는 것이다.
--
--                -- (3) 어느 세그먼트의 몇 번째 행인가
--                SELECT s.SID, o.OWNER, o.OBJECT_NAME, s.ROW_WAIT_FILE#,
--                       s.ROW_WAIT_BLOCK#, s.ROW_WAIT_ROW#
--                  FROM V$SESSION s, DBA_OBJECTS o
--                 WHERE s.ROW_WAIT_OBJ# = o.OBJECT_ID AND s.BLOCKING_SESSION IS NOT NULL;
--
--                -- (4) 인스턴스 누적 enqueue 대기
--                SELECT EVENT, TOTAL_WAITS, TIME_WAITED_MICRO FROM V$SYSTEM_EVENT
--                 WHERE EVENT LIKE 'enq: TX%';
--
-- 되돌리기   : 1) 세션 A / B 는 스크립트 끝에서 ROLLBACK 한다(자동).
--                 수동으로 확실히 하려면 각 터미널에서 ROLLBACK; 을 한 번 더 친다.
--              2) 복제 테이블 삭제 :
--                    DEFINE wl_role = CLEANUP  으로 바꾸고 @WL_04_lock.sql 실행
--                    (또는 직접  DROP TABLE REVIEW_LOG_WL PURGE; )
--              3) 원본 REVIEW_LOG 은 변경한 적이 없으므로 원복 대상이 아니다.
--              4) 세션이 끊기지 않고 남아 블로킹이 계속될 때(비상시에만):
--                    ALTER SYSTEM KILL SESSION '<SID>,<SERIAL#>' IMMEDIATE;
--                 ★ 세션을 죽이기 전에 반드시 위 (1)~(3) 조회 결과를 캡처해 둘 것.
--                    근거를 남기지 않은 응급 조치는 원인 분석을 불가능하게 만든다
--                    (3장 DBA Point).
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              커밋하지 않은 트랜잭션을 일부러 유지한다. 공유 DB에서 실행하면
--              다른 업무 세션이 같은 자원을 기다리다 멈출 수 있다.
--              세션 A의 터미널을 그냥 닫으면 트랜잭션이 롤백될 때까지
--              세션 B가 계속 블로킹될 수 있으니, 반드시 스크립트를 끝까지 돌리거나
--              ROLLBACK 을 명시적으로 실행할 것.
--
-- ============================================================================
--  ▶ 실행 방법 (터미널 3개, 순서를 지킬 것)
-- ============================================================================
--   [0단계] 아무 터미널에서 준비 (복제 테이블 생성)
--           sqlplus sqlt/<pw>@<서비스>
--           SQL> DEFINE wl_role = SETUP
--           SQL> @WL_04_lock.sql
--
--   [1단계] 터미널 A - 잠금 보유자
--           SQL> DEFINE wl_role = A
--           SQL> @WL_04_lock.sql
--           -> 대상 행을 UPDATE 하고 커밋하지 않은 채 wl_hold_sec 초 대기한다.
--              화면에 자기 SID 를 출력하므로 적어 둔다.
--
--   [2단계] 터미널 B - 잠금 대기자   ※ A가 대기에 들어간 "직후" 실행할 것
--           SQL> DEFINE wl_role = B
--           SQL> @WL_04_lock.sql
--           -> 같은 행을 UPDATE 하려다 블로킹된다. 화면이 멈춘 것처럼 보이는 것이
--              정상이다. A가 롤백하면 자동으로 풀리고 대기 델타를 출력한다.
--
--   [3단계] 터미널 C - 관찰자        ※ B가 멈춰 있는 동안 실행할 것
--           SQL> DEFINE wl_role = C
--           SQL> @WL_04_lock.sql
--           -> 블로커/대기자, V$LOCK, 대기 이벤트를 조회해 화면에 출력한다.
--              여러 번 반복 실행해도 된다.
--
--   [4단계] 정리
--           SQL> DEFINE wl_role = CLEANUP
--           SQL> @WL_04_lock.sql
-- ============================================================================


-- ----------------------------------------------------------------------------
-- [0] SQL*Plus 환경 설정
-- ----------------------------------------------------------------------------
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 220
SET PAGESIZE 200
SET DEFINE ON
SET VERIFY OFF
SET FEEDBACK ON


-- ----------------------------------------------------------------------------
-- [1] 조절 변수
-- ----------------------------------------------------------------------------
--   wl_role     : SETUP / A / B / C / CLEANUP  (위 실행 방법 참조)
--                 기본값 SETUP - 아무 준비 없이 실행해도 안전하도록 잡았다.
--   wl_rows     : 복제 테이블 REVIEW_LOG_WL 에 담을 행 수 (기본 1000)
--                 잠금 실습에는 1행이면 충분하지만, 12장에서 "경합 대상이 아닌
--                 행은 잠기지 않는다"를 보이려고 여유 있게 1000행을 둔다.
--   wl_hold_sec : 세션 A가 커밋하지 않고 잠금을 유지할 시간(초). 기본 60.
-- ----------------------------------------------------------------------------
DEFINE wl_role     = SETUP
DEFINE wl_rows     = 1000
DEFINE wl_hold_sec = 60

PROMPT
PROMPT ============================================================
PROMPT  WL_04_lock.sql  -  TX 행 잠금 경합 부하
PROMPT    역할(wl_role)      : &wl_role
PROMPT    복제 행수(wl_rows) : &wl_rows
PROMPT    보유 시간(초)      : &wl_hold_sec
PROMPT ============================================================
PROMPT


-- ============================================================================
-- [2] [공통 준비] 복제 테이블 REVIEW_LOG_WL 생성
--     원본 REVIEW_LOG 은 SELECT 대상으로만 쓴다. 갱신은 전부 복제본에서 한다.
-- ============================================================================
DECLARE
    v_cnt  NUMBER;
    v_role VARCHAR2(20) := UPPER('&wl_role');
BEGIN
    IF v_role NOT IN ('SETUP','A','B') THEN
        DBMS_OUTPUT.PUT_LINE('[준비] 역할이 ' || v_role || ' 이므로 준비 단계를 건너뛴다.');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME = 'REVIEW_LOG_WL';

    -- SETUP 은 항상 새로 만든다. A/B 는 없을 때만 만든다(진행 중 잠금 파괴 방지).
    IF v_role = 'SETUP' AND v_cnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE REVIEW_LOG_WL PURGE';
        v_cnt := 0;
        DBMS_OUTPUT.PUT_LINE('[준비] 기존 REVIEW_LOG_WL 을 삭제했다.');
    END IF;

    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE TABLE REVIEW_LOG_WL AS ' ||
            'SELECT LOG_ID, CLAIM_ID, REVIEWER_ID, PROCESS_DATE, ACTION_MSG, ERROR_CODE ' ||
            '  FROM REVIEW_LOG WHERE ROWNUM <= ' || &wl_rows;
        EXECUTE IMMEDIATE
            'ALTER TABLE REVIEW_LOG_WL ADD CONSTRAINT PK_REVIEW_LOG_WL PRIMARY KEY (LOG_ID)';
        DBMS_OUTPUT.PUT_LINE('[준비] REVIEW_LOG_WL 생성 완료 (' || &wl_rows || '행 이하).');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[준비] REVIEW_LOG_WL 이 이미 있으므로 그대로 사용한다.');
    END IF;

    -- REVIEW_LOG_WL 은 실행 시점에야 존재하므로 정적 SQL로 참조하면
    -- 익명 블록 컴파일 단계에서 PLS-00201 이 난다. 반드시 동적 SQL을 쓴다.
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM REVIEW_LOG_WL' INTO v_cnt;
    DBMS_OUTPUT.PUT_LINE('[준비] REVIEW_LOG_WL 현재 행수 = ' || v_cnt);

    IF v_role = 'SETUP' THEN
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('>>> 준비 완료. 이제 터미널 A 에서 다음을 실행한다.');
        DBMS_OUTPUT.PUT_LINE('      DEFINE wl_role = A');
        DBMS_OUTPUT.PUT_LINE('      @WL_04_lock.sql');
    END IF;
END;
/


-- ============================================================================
-- [3] [세션 A]  잠금 보유자
--     - 대상 행을 UPDATE 하고 커밋하지 않는다.
--     - wl_hold_sec 초 동안 트랜잭션을 열어 둔 채 대기한다.
--     - 이 구간에 세션 B를 띄우면 블로킹이 발생한다.
-- ============================================================================
DECLARE
    v_role   VARCHAR2(20) := UPPER('&wl_role');
    v_sid    NUMBER;
    v_ser    NUMBER;
    v_target NUMBER;
BEGIN
    IF v_role <> 'A' THEN
        RETURN;
    END IF;

    SELECT SID, SERIAL# INTO v_sid, v_ser
      FROM V$SESSION
     WHERE SID = SYS_CONTEXT('USERENV','SID');

    -- 동적 SQL 사용 이유는 [2]절 주석 참조 (컴파일 시점 의존성 제거)
    EXECUTE IMMEDIATE 'SELECT MIN(LOG_ID) FROM REVIEW_LOG_WL' INTO v_target;

    DBMS_OUTPUT.PUT_LINE(RPAD('=',80,'='));
    DBMS_OUTPUT.PUT_LINE('[세션 A] 나의 SID = ' || v_sid || ' , SERIAL# = ' || v_ser);
    DBMS_OUTPUT.PUT_LINE('[세션 A] 잠글 대상 : REVIEW_LOG_WL.LOG_ID = ' || v_target);
    DBMS_OUTPUT.PUT_LINE(RPAD('=',80,'='));

    -- 복제 테이블에 대한 갱신. 원본 REVIEW_LOG 은 건드리지 않는다.
    EXECUTE IMMEDIATE
        'UPDATE /* WL04_SESSION_A */ REVIEW_LOG_WL ' ||
        '   SET ACTION_MSG   = ''WL04-A-'' || TO_CHAR(SYSDATE,''HH24MISS''), ' ||
        '       PROCESS_DATE = SYSDATE ' ||
        ' WHERE LOG_ID = :1'
        USING v_target;

    DBMS_OUTPUT.PUT_LINE('[세션 A] UPDATE ' || SQL%ROWCOUNT ||
                         ' 행 완료. 커밋하지 않는다 (TX 잠금 보유 중).');
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('>>> 지금 바로 터미널 B 에서 다음을 실행하라.');
    DBMS_OUTPUT.PUT_LINE('      DEFINE wl_role = B');
    DBMS_OUTPUT.PUT_LINE('      @WL_04_lock.sql');
    DBMS_OUTPUT.PUT_LINE('>>> 그리고 터미널 C 에서 관찰하라.');
    DBMS_OUTPUT.PUT_LINE('      DEFINE wl_role = C');
    DBMS_OUTPUT.PUT_LINE('      @WL_04_lock.sql');
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('[세션 A] ' || &wl_hold_sec || ' 초 동안 잠금을 유지한다...');

    -- 19c 에서 사용 가능. DBMS_LOCK.SLEEP 은 별도 EXECUTE 권한이 필요해 쓰지 않는다.
    DBMS_SESSION.SLEEP(&wl_hold_sec);

    DBMS_OUTPUT.PUT_LINE('[세션 A] 대기 종료. 아래 [5]절 관찰 조회를 수행한 뒤');
    DBMS_OUTPUT.PUT_LINE('         스크립트 끝의 ROLLBACK 으로 잠금을 해제한다.');
END;
/


-- ============================================================================
-- [4] [세션 B]  잠금 대기자
--     - 세션 A가 잡고 있는 같은 행을 UPDATE 하려다 블로킹된다.
--     - 블로킹 전후로 자기 대기 통계를 스냅샷해 델타를 출력한다.
--     - A가 롤백하면 자동으로 풀린다. 화면이 멈춰 보이는 것이 정상이다.
-- ============================================================================
DECLARE
    TYPE t_map IS TABLE OF NUMBER INDEX BY VARCHAR2(120);

    v_role   VARCHAR2(20) := UPPER('&wl_role');
    v_b      t_map;
    v_a      t_map;
    v_sid    NUMBER;
    v_target NUMBER;
    v_t      NUMBER;
    v_el     NUMBER;

    PROCEDURE p_snap(p_m OUT t_map) IS
    BEGIN
        p_m.DELETE;
        FOR r IN (
            SELECT '01 [SESS] ' || sn.NAME AS k, ms.VALUE AS v
              FROM V$MYSTAT ms, V$STATNAME sn
             WHERE ms.STATISTIC# = sn.STATISTIC#
               AND sn.NAME IN ('enqueue requests','enqueue waits',
                               'enqueue conversions','enqueue releases',
                               'user commits','user rollbacks','db block changes')
            UNION ALL
            SELECT '02 [SESS] ' || EVENT || '  (대기횟수)', TOTAL_WAITS
              FROM V$SESSION_EVENT
             WHERE SID = SYS_CONTEXT('USERENV','SID')
               AND EVENT LIKE 'enq: TX%'
            UNION ALL
            SELECT '03 [SESS] ' || EVENT || '  (대기ms)', ROUND(TIME_WAITED_MICRO/1000)
              FROM V$SESSION_EVENT
             WHERE SID = SYS_CONTEXT('USERENV','SID')
               AND EVENT LIKE 'enq: TX%'
            UNION ALL
            SELECT '04 [INST] ' || EVENT || '  (대기횟수)', TOTAL_WAITS
              FROM V$SYSTEM_EVENT
             WHERE EVENT LIKE 'enq: TX%'
            UNION ALL
            SELECT '05 [INST] ' || EVENT || '  (대기ms)', ROUND(TIME_WAITED_MICRO/1000)
              FROM V$SYSTEM_EVENT
             WHERE EVENT LIKE 'enq: TX%'
        ) LOOP
            p_m(r.k) := r.v;
        END LOOP;
    END p_snap;

    FUNCTION f_get(p_m t_map, p_k VARCHAR2) RETURN NUMBER IS
    BEGIN
        IF p_m.EXISTS(p_k) THEN RETURN p_m(p_k); ELSE RETURN 0; END IF;
    END f_get;

    PROCEDURE p_diff(p_bm t_map, p_am t_map) IS
        v_k VARCHAR2(120);
        v_d NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE(RPAD('=',122,'='));
        DBMS_OUTPUT.PUT_LINE('[세션 B] 블로킹 전후 델타');
        DBMS_OUTPUT.PUT_LINE(RPAD('=',122,'='));
        DBMS_OUTPUT.PUT_LINE(RPAD('지표',58) || LPAD('전(前)',20) ||
                             LPAD('후(後)',20) || LPAD('델타',20));
        DBMS_OUTPUT.PUT_LINE(RPAD('-',122,'-'));
        v_k := p_am.FIRST;
        WHILE v_k IS NOT NULL LOOP
            v_d := p_am(v_k) - f_get(p_bm, v_k);
            IF v_d <> 0 OR SUBSTR(v_k,1,2) = '01' THEN
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

BEGIN
    IF v_role <> 'B' THEN
        RETURN;
    END IF;

    v_sid := SYS_CONTEXT('USERENV','SID');
    EXECUTE IMMEDIATE 'SELECT MIN(LOG_ID) FROM REVIEW_LOG_WL' INTO v_target;

    DBMS_OUTPUT.PUT_LINE(RPAD('=',80,'='));
    DBMS_OUTPUT.PUT_LINE('[세션 B] 나의 SID = ' || v_sid);
    DBMS_OUTPUT.PUT_LINE('[세션 B] 갱신 시도 대상 : REVIEW_LOG_WL.LOG_ID = ' || v_target);
    DBMS_OUTPUT.PUT_LINE('[세션 B] 세션 A가 같은 행을 잡고 있으면 여기서 멈춘다.');
    DBMS_OUTPUT.PUT_LINE('         (화면이 멈춘 것처럼 보이는 것이 정상이다)');
    DBMS_OUTPUT.PUT_LINE(RPAD('=',80,'='));

    p_snap(v_b);
    v_t := DBMS_UTILITY.GET_TIME;

    -- ▼ 여기서 블로킹된다. 세션 A가 COMMIT/ROLLBACK 할 때까지 반환되지 않는다.
    EXECUTE IMMEDIATE
        'UPDATE /* WL04_SESSION_B */ REVIEW_LOG_WL ' ||
        '   SET ACTION_MSG   = ''WL04-B-'' || TO_CHAR(SYSDATE,''HH24MISS''), ' ||
        '       PROCESS_DATE = SYSDATE ' ||
        ' WHERE LOG_ID = :1'
        USING v_target;

    v_el := (DBMS_UTILITY.GET_TIME - v_t) / 100;
    p_snap(v_a);

    DBMS_OUTPUT.PUT_LINE('[세션 B] 잠금 해제됨. ' || SQL%ROWCOUNT ||
                         ' 행 갱신, 대기 시간 약 ' || v_el || ' 초');

    p_diff(v_b, v_a);

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('### 판정 포인트 ###');
    DBMS_OUTPUT.PUT_LINE('  1) [SESS] enq: TX - row lock contention 의 대기횟수 델타가');
    DBMS_OUTPUT.PUT_LINE('     보통 1, 대기ms 델타가 실제 블로킹 시간과 비슷해야 한다.');
    DBMS_OUTPUT.PUT_LINE('     "한 번 기다렸는데 시간이 길다" - 횟수가 아니라 시간으로');
    DBMS_OUTPUT.PUT_LINE('     판단해야 하는 대표적인 이벤트다.');
    DBMS_OUTPUT.PUT_LINE('  2) enqueue waits 통계도 함께 늘어난다.');
    DBMS_OUTPUT.PUT_LINE('  3) 대기가 잡히지 않았다면 세션 A가 이미 롤백한 뒤에');
    DBMS_OUTPUT.PUT_LINE('     B를 실행한 것이다. wl_hold_sec 를 늘려 다시 시도한다.');
END;
/


-- ============================================================================
-- [5] [세션 C]  관찰 - 블로커/대기자 추적
--     아래 조회는 어느 역할로 실행하든 그대로 수행된다.
--     세션 C에서는 이 부분만 반복 실행하면 된다(스크립트를 다시 @ 해도 된다).
-- ============================================================================
PROMPT
PROMPT ============================================================
PROMPT  [세션 C] 관찰 : 블로커와 대기자
PROMPT ============================================================

PROMPT
PROMPT >>> (1) 블로킹 관계에 있는 세션 목록  (BLOCKING_SESSION 이 핵심)
COLUMN username FORMAT A12
COLUMN status   FORMAT A9
COLUMN event    FORMAT A34
COLUMN role_kind FORMAT A10
SELECT CASE WHEN s.BLOCKING_SESSION IS NOT NULL THEN 'WAITER' ELSE 'BLOCKER' END AS ROLE_KIND,
       s.SID, s.SERIAL#, s.USERNAME, s.STATUS, s.EVENT,
       s.SECONDS_IN_WAIT          AS WAIT_SECS,
       s.BLOCKING_SESSION_STATUS  AS BLK_STATUS,
       s.BLOCKING_SESSION         AS BLOCKER_SID,
       s.SQL_ID
  FROM V$SESSION s
 WHERE s.BLOCKING_SESSION IS NOT NULL
    OR s.SID IN (SELECT BLOCKING_SESSION FROM V$SESSION WHERE BLOCKING_SESSION IS NOT NULL)
 ORDER BY 1, s.SID;

PROMPT
PROMPT >>> (2) V$LOCK - TX/TM 락 보유(LMODE=6)와 요청(REQUEST=6)
SELECT l.SID, l.TYPE, l.ID1, l.ID2, l.LMODE, l.REQUEST, l.CTIME AS HELD_SECS, l.BLOCK,
       CASE WHEN l.LMODE > 0 AND l.REQUEST = 0 THEN 'HOLDING'
            WHEN l.REQUEST > 0                 THEN 'REQUESTING'
            ELSE '-' END AS LOCK_ROLE
  FROM V$LOCK l
 WHERE l.TYPE IN ('TX','TM')
 ORDER BY l.TYPE, l.ID1, l.REQUEST DESC, l.SID;

PROMPT
PROMPT >>> (3) 어느 객체의 몇 번째 행에서 막혔는가
COLUMN object_name FORMAT A22
COLUMN owner       FORMAT A12
SELECT s.SID, o.OWNER, o.OBJECT_NAME, o.OBJECT_TYPE,
       s.ROW_WAIT_FILE#  AS WAIT_FILE,
       s.ROW_WAIT_BLOCK# AS WAIT_BLOCK,
       s.ROW_WAIT_ROW#   AS WAIT_ROW
  FROM V$SESSION s, DBA_OBJECTS o
 WHERE s.ROW_WAIT_OBJ# = o.OBJECT_ID
   AND s.BLOCKING_SESSION IS NOT NULL;

PROMPT
PROMPT >>> (4) V$SESSION_BLOCKERS - 19c 의 블로킹 관계 뷰
SELECT SID, SESS_SERIAL#, BLOCKER_SID, BLOCKER_SESS_SERIAL#,
       WAIT_EVENT_TEXT, IN_WAIT_SECS
  FROM V$SESSION_BLOCKERS
 ORDER BY SID;

PROMPT
PROMPT >>> (5) DBA_BLOCKERS / DBA_WAITERS  (라이선스 불필요한 고전 경로)
SELECT 'BLOCKER' AS KIND, HOLDING_SESSION AS SID, NULL AS WAITING_FOR
  FROM DBA_BLOCKERS
UNION ALL
SELECT 'WAITER', WAITING_SESSION, HOLDING_SESSION
  FROM DBA_WAITERS;

PROMPT
PROMPT >>> (6) 블로커 세션이 마지막에 실행한 SQL
COLUMN sql_text FORMAT A80
SELECT s.SID, s.PREV_SQL_ID, SUBSTR(q.SQL_TEXT,1,80) sql_text
  FROM V$SESSION s, V$SQL q
 WHERE s.PREV_SQL_ID = q.SQL_ID
   AND s.PREV_CHILD_NUMBER = q.CHILD_NUMBER
   AND s.SID IN (SELECT BLOCKING_SESSION FROM V$SESSION WHERE BLOCKING_SESSION IS NOT NULL);

PROMPT
PROMPT >>> (7) 인스턴스 누적 enqueue 대기
SELECT EVENT, TOTAL_WAITS, TIME_WAITED_MICRO,
       ROUND(TIME_WAITED_MICRO/DECODE(TOTAL_WAITS,0,1,TOTAL_WAITS)/1000000,2) AS AVG_SEC
  FROM V$SYSTEM_EVENT
 WHERE EVENT LIKE 'enq:%'
   AND TOTAL_WAITS > 0
 ORDER BY TIME_WAITED_MICRO DESC;

PROMPT
PROMPT >>> (8) 미커밋 트랜잭션 현황 (V$TRANSACTION)
SELECT t.XIDUSN, t.XIDSLOT, t.XIDSQN, s.SID, s.USERNAME,
       t.STATUS, t.USED_UBLK AS UNDO_BLOCKS, t.USED_UREC AS UNDO_RECORDS,
       t.START_TIME
  FROM V$TRANSACTION t, V$SESSION s
 WHERE t.SES_ADDR = s.SADDR
 ORDER BY t.START_TIME;


-- ============================================================================
-- [6] 마무리 - 잠금 해제
--     역할에 관계없이 이 세션의 미완료 트랜잭션을 롤백한다.
--     세션 A는 여기서 잠금을 놓고, 그 순간 세션 B의 블로킹이 풀린다.
-- ============================================================================
PROMPT
PROMPT >>> [마무리] ROLLBACK - 이 세션의 미커밋 트랜잭션을 되돌린다
ROLLBACK;

DECLARE
    v_role VARCHAR2(20) := UPPER('&wl_role');
BEGIN
    IF v_role = 'A' THEN
        DBMS_OUTPUT.PUT_LINE('[세션 A] 롤백 완료. 세션 B의 블로킹이 풀렸을 것이다.');
    ELSIF v_role = 'B' THEN
        DBMS_OUTPUT.PUT_LINE('[세션 B] 롤백 완료. 복제 테이블 내용도 원래대로다.');
    END IF;
END;
/


-- ============================================================================
-- [7] 되돌리기 - 복제 테이블 삭제 (wl_role = CLEANUP 일 때만)
-- ============================================================================
DECLARE
    v_role VARCHAR2(20) := UPPER('&wl_role');
    v_cnt  NUMBER;
BEGIN
    IF v_role <> 'CLEANUP' THEN
        DBMS_OUTPUT.PUT_LINE('[정리] 복제 테이블을 유지한다. ' ||
                             '삭제하려면 DEFINE wl_role = CLEANUP 후 재실행하라.');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME = 'REVIEW_LOG_WL';
    IF v_cnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE REVIEW_LOG_WL PURGE';
        DBMS_OUTPUT.PUT_LINE('[정리] REVIEW_LOG_WL 삭제 완료.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[정리] REVIEW_LOG_WL 이 없다. 정리할 것 없음.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('[정리] 원본 REVIEW_LOG 은 변경한 적이 없다.');
END;
/

PROMPT
PROMPT ============================================================
PROMPT  WL_04 (&wl_role) 완료.
PROMPT   - 갱신 대상은 복제 테이블 REVIEW_LOG_WL 뿐이며, 모두 롤백했다.
PROMPT   - 원본 REVIEW_LOG 은 읽기만 했다.
PROMPT   - 정리 : DEFINE wl_role = CLEANUP  후 @WL_04_lock.sql
PROMPT   - 블로킹이 남아 있다면 (근거 캡처 후에만!) :
PROMPT       ALTER SYSTEM KILL SESSION '<SID>,<SERIAL#>' IMMEDIATE;
PROMPT ============================================================
SET TIMING OFF
