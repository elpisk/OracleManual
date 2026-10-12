-- ============================================================================
-- EX_90_측정보조.sql  :  지표 스냅샷을 잡고 전(前)/후(後)/델타 3열로 출력한다
-- DBTUNING 중간 평가(ch01~ch20) 공용 스크립트 (1/6)
-- ============================================================================
-- 목적       : 세 문제가 공통으로 요구하는 "조치 전 캡처 → 조치 → 조치 후 캡처 →
--              델타 비교" 를 손으로 반복하지 않게 한다. 누적값(V$SYSSTAT 등)을
--              그대로 비교하면 틀린 결론이 나온다는 것이 이 과정의 핵심 교훈이므로
--              (ch19 실습 06), 이 스크립트는 반드시 두 시점을 잡아 차이만 본다.
--
-- 사용법     : 인자 3개를 항상 넘긴다. 쓰지 않는 자리에는 하이픈(-)을 넣는다.
--
--                @EX_90_측정보조.sql SNAP  T0  -        -- T0 시점 캡처
--                ... 부하 또는 조치 실행 ...
--                @EX_90_측정보조.sql SNAP  T1  -        -- T1 시점 캡처
--                @EX_90_측정보조.sql DELTA T0  T1       -- 3열 비교 출력
--
--                @EX_90_측정보조.sql LIST  -   -        -- 잡아 둔 태그 목록
--                @EX_90_측정보조.sql CLEAR -   -        -- 전체 삭제
--                @EX_90_측정보조.sql CLEAR T0  -        -- T0 만 삭제
--
-- 전제       : 1) SQLT 계정 접속(평가 응시자 계정). CREATE TABLE 권한 필요.
--              2) V$ 뷰 조회 권한.  SYS 에서 1회 :  GRANT SELECT_CATALOG_ROLE TO SQLT;
--              3) 스냅샷 보관용 EX_SNAP_WL 테이블을 자동 생성한다.
--                 원본 7개 테이블은 읽지도 쓰지도 않는다.
--
-- 소요 시간  : 캡처 1회 1초 미만, DELTA 출력 1초 미만.
--
-- 관찰 지표  : V$SYSSTAT(통계 17종) · V$SYS_TIME_MODEL(시간 모델 6종)
--              V$SYSTEM_WAIT_CLASS(대기 클래스 전체) · V$SYSTEM_EVENT(주요 이벤트 9종)
--              VAL1 은 횟수/바이트, VAL2 는 시간(센티초 또는 마이크로초)이다.
--
-- 되돌리기   : DROP TABLE EX_SNAP_WL PURGE;
--              채점용으로 남겨 두는 편이 좋다(응시자의 캡처 이력이 근거가 된다).
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              V$ 누적값은 인스턴스 재기동으로 0 이 된다. 재기동이 끼면 델타가
--              음수로 나오므로, 그 경우 캡처를 버리고 다시 잡는다.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 200
SET VERIFY OFF
SET FEEDBACK OFF
SET DEFINE ON

DEFINE ex_cmd = &1
DEFINE ex_t0  = &2
DEFINE ex_t1  = &3


-- ----------------------------------------------------------------------------
-- [1] 보관 테이블 (없으면 만든다)
-- ----------------------------------------------------------------------------
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'EX_SNAP_WL';
    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE EX_SNAP_WL (
                tag   VARCHAR2(16)  NOT NULL,
                src   VARCHAR2(24)  NOT NULL,
                name  VARCHAR2(128) NOT NULL,
                val1  NUMBER,
                val2  NUMBER,
                ts    TIMESTAMP DEFAULT SYSTIMESTAMP
            )';
        EXECUTE IMMEDIATE
            'CREATE UNIQUE INDEX PK_EX_SNAP_WL ON EX_SNAP_WL (tag, src, name)';
        DBMS_OUTPUT.PUT_LINE('[준비] EX_SNAP_WL 을 만들었다.');
    END IF;
END;
/


-- ----------------------------------------------------------------------------
-- [2] SNAP  :  현재 누적값을 태그에 담는다
-- ----------------------------------------------------------------------------
DECLARE
    v_cmd VARCHAR2(16) := UPPER('&ex_cmd');
    v_tag VARCHAR2(16) := UPPER('&ex_t0');
    v_n   NUMBER;
BEGIN
    IF v_cmd <> 'SNAP' THEN RETURN; END IF;
    IF v_tag IS NULL OR v_tag = '-' THEN
        RAISE_APPLICATION_ERROR(-20001, 'SNAP 은 태그가 필요하다. 예: @EX_90_측정보조.sql SNAP T0 -');
    END IF;

    EXECUTE IMMEDIATE 'DELETE FROM EX_SNAP_WL WHERE tag = :1' USING v_tag;

    -- (1) 시스템 통계
    EXECUTE IMMEDIATE '
        INSERT INTO EX_SNAP_WL (tag, src, name, val1, val2)
        SELECT :1, ''SYSSTAT'', name, value, NULL
          FROM v$sysstat
         WHERE name IN (''parse count (total)'',''parse count (hard)'',
                        ''execute count'',''user calls'',''recursive calls'',
                        ''user commits'',''user rollbacks'',
                        ''session logical reads'',''physical reads'',
                        ''physical read total bytes'',
                        ''redo size'',''redo entries'',''redo synch writes'',
                        ''sorts (memory)'',''sorts (disk)'',
                        ''table scans (long tables)'',''table scans (short tables)'',
                        ''SQL*Net roundtrips to/from client'')' USING v_tag;

    -- (2) 시간 모델 (DB time 분해)
    EXECUTE IMMEDIATE '
        INSERT INTO EX_SNAP_WL (tag, src, name, val1, val2)
        SELECT :1, ''TIMEMODEL'', stat_name, value, NULL
          FROM v$sys_time_model
         WHERE stat_name IN (''DB time'',''DB CPU'',''sql execute elapsed time'',
                             ''parse time elapsed'',''hard parse elapsed time'',
                             ''PL/SQL execution elapsed time'')' USING v_tag;

    -- (3) 대기 클래스 (전체)
    EXECUTE IMMEDIATE '
        INSERT INTO EX_SNAP_WL (tag, src, name, val1, val2)
        SELECT :1, ''WAITCLASS'', wait_class, total_waits, time_waited
          FROM v$system_wait_class' USING v_tag;

    -- (4) 주요 대기 이벤트
    EXECUTE IMMEDIATE '
        INSERT INTO EX_SNAP_WL (tag, src, name, val1, val2)
        SELECT :1, ''EVENT'', event, total_waits, time_waited_micro
          FROM v$system_event
         WHERE event IN (''db file sequential read'',''db file scattered read'',
                         ''log file sync'',''log file parallel write'',
                         ''direct path write temp'',''direct path read temp'',
                         ''latch: shared pool'',''library cache: mutex X'',
                         ''enq: TX - row lock contention'',''buffer busy waits'')' USING v_tag;

    COMMIT;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM EX_SNAP_WL WHERE tag = :1' INTO v_n USING v_tag;
    DBMS_OUTPUT.PUT_LINE('[캡처] 태그 ' || v_tag || ' : 항목 ' || v_n || '개 ('
                         || TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') || ')');
END;
/


-- ----------------------------------------------------------------------------
-- [3] CLEAR / LIST
-- ----------------------------------------------------------------------------
DECLARE
    v_cmd VARCHAR2(16) := UPPER('&ex_cmd');
    v_tag VARCHAR2(16) := UPPER('&ex_t0');
BEGIN
    IF v_cmd = 'CLEAR' THEN
        IF v_tag IS NULL OR v_tag = '-' THEN
            EXECUTE IMMEDIATE 'DELETE FROM EX_SNAP_WL';
            DBMS_OUTPUT.PUT_LINE('[정리] 모든 스냅샷을 지웠다.');
        ELSE
            EXECUTE IMMEDIATE 'DELETE FROM EX_SNAP_WL WHERE tag = :1' USING v_tag;
            DBMS_OUTPUT.PUT_LINE('[정리] 태그 ' || v_tag || ' 을 지웠다.');
        END IF;
        COMMIT;
    END IF;
END;
/

COLUMN tag     FORMAT A8
COLUMN captured FORMAT A20
COLUMN items   FORMAT 9999
SET FEEDBACK ON
SELECT tag, TO_CHAR(MIN(ts), 'YYYY-MM-DD HH24:MI:SS') captured, COUNT(*) items
  FROM ex_snap_wl
 WHERE UPPER('&ex_cmd') IN ('LIST', 'CLEAR')
 GROUP BY tag
 ORDER BY MIN(ts);
SET FEEDBACK OFF


-- ----------------------------------------------------------------------------
-- [4] DELTA  :  전 / 후 / 델타 3열
-- ----------------------------------------------------------------------------
COLUMN src    FORMAT A10
COLUMN name   FORMAT A34
COLUMN "전(前)"  FORMAT 999,999,999,999
COLUMN "후(後)"  FORMAT 999,999,999,999
COLUMN "델타"    FORMAT 999,999,999,999
COLUMN "비고"    FORMAT A26

-- 머리글은 DELTA 일 때만 찍는다(SNAP/LIST 에서 빈 결과가 끼지 않게 한다)
SET HEADING OFF
SET FEEDBACK OFF
SELECT '============================================================' || CHR(10) ||
       ' 델타 : ' || UPPER('&ex_t0') || '  ->  ' || UPPER('&ex_t1') || CHR(10) ||
       '  * 누적값을 그대로 비교하지 말고 이 ''델타'' 열만 읽는다.' || CHR(10) ||
       '  * 델타가 음수면 인스턴스가 재기동된 것이다 - 캡처를 다시 잡는다.' || CHR(10) ||
       '============================================================'
  FROM dual WHERE UPPER('&ex_cmd') = 'DELTA';
SET HEADING ON
SET FEEDBACK ON
SELECT a.src, a.name,
       a.val1 AS "전(前)", b.val1 AS "후(後)", b.val1 - a.val1 AS "델타",
       CASE a.src
         WHEN 'TIMEMODEL' THEN '마이크로초'
         WHEN 'WAITCLASS' THEN '대기 '    || TO_CHAR(NVL(b.val2,0) - NVL(a.val2,0)) || ' cs'
         WHEN 'EVENT'     THEN '대기 '    || TO_CHAR(ROUND((NVL(b.val2,0) - NVL(a.val2,0))/1000)) || ' ms'
         ELSE NULL
       END AS "비고"
  FROM ex_snap_wl a
  JOIN ex_snap_wl b
    ON  b.tag = UPPER('&ex_t1') AND b.src = a.src AND b.name = a.name
 WHERE a.tag = UPPER('&ex_t0')
   AND UPPER('&ex_cmd') = 'DELTA'
   AND (b.val1 - a.val1) <> 0
 ORDER BY DECODE(a.src, 'TIMEMODEL',1, 'WAITCLASS',2, 'SYSSTAT',3, 'EVENT',4),
          b.val1 - a.val1 DESC;

SET HEADING OFF
SET FEEDBACK OFF
SELECT CHR(10) || '>>> DB Time 분해 (델타 기준)'
  FROM dual WHERE UPPER('&ex_cmd') = 'DELTA';
SET HEADING ON
SET FEEDBACK ON
SELECT ROUND(MAX(DECODE(name,'DB time',           d))/1e6, 2) AS "DB_time_초",
       ROUND(MAX(DECODE(name,'DB CPU',            d))/1e6, 2) AS "DB_CPU_초",
       ROUND(MAX(DECODE(name,'sql execute elapsed time', d))/1e6, 2) AS "SQL실행_초",
       ROUND(MAX(DECODE(name,'hard parse elapsed time',  d))/1e6, 2) AS "하드파싱_초",
       ROUND( (MAX(DECODE(name,'DB time', d)) - MAX(DECODE(name,'DB CPU', d)))
              / DECODE(MAX(DECODE(name,'DB time', d)), 0, 1,
                       MAX(DECODE(name,'DB time', d))) * 100, 1) AS "대기몫_퍼센트"
  FROM (SELECT a.name, b.val1 - a.val1 d
          FROM ex_snap_wl a
          JOIN ex_snap_wl b ON b.tag = UPPER('&ex_t1') AND b.src = a.src AND b.name = a.name
         WHERE a.tag = UPPER('&ex_t0') AND a.src = 'TIMEMODEL')
 WHERE UPPER('&ex_cmd') = 'DELTA';

SET FEEDBACK ON
UNDEFINE ex_cmd
UNDEFINE ex_t0
UNDEFINE ex_t1
