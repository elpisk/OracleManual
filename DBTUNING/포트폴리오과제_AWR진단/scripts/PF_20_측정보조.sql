-- ============================================================================
-- PF_20_측정보조.sql  :  구간을 잡고, 그 구간의 AWR/ASH/ADDM 보고서를 뽑는다
-- AWR 진단 포트폴리오 과제 공용 스크립트 (2/3)
-- ============================================================================
-- 목적       : 이 과제의 모든 근거는 "두 시점 사이" 에서 나온다. 손으로
--              awrrpt.sql 을 돌리고 스냅샷 번호를 받아 적는 일을 없앤다.
--              태그 하나로 구간을 고정하고, 같은 구간에서 AWR·ASH·ADDM·
--              DBA_HIST_SQLSTAT 를 모두 뽑는다. 그래서 네 근거가 어긋나지 않는다.
--
--              ★ 이 스크립트는 판단을 대신하지 않는다 ★
--              보고서 텍스트를 만들어 줄 뿐이다. 어느 줄이 근거인지 고르고
--              왜 그렇게 읽었는지 쓰는 것이 과제다.
--
-- 전제       : 1) SYS AS SYSDBA 로 접속한다.
--                 AWR·ASH·ADDM 과 DBA_HIST_* 는 진단 팩 권한이 필요하다.
--              2) PF_00_환경점검.sql 에서 control_management_pack_access 가
--                 DIAGNOSTIC+TUNING 임을 확인했어야 한다.
--              3) 스냅샷 보관표 SQLT.PF_SNAP 을 자동으로 만든다.
--                 진료비청구심사 7개 표는 읽지도 쓰지도 않는다.
--
-- 사용법     : 인자는 항상 3개를 넘긴다. 쓰지 않는 자리에는 하이픈(-)을 넣는다.
--
--              [구간 잡기]
--                @PF_20_측정보조.sql SNAP   T0  -     -- 시작점 (AWR 스냅샷도 생성)
--                ... 부하 또는 조치 실행 ...
--                @PF_20_측정보조.sql SNAP   T1  -     -- 끝점
--
--              [구간 읽기]
--                @PF_20_측정보조.sql DELTA  T0  T1    -- 전/후/델타 3열 + DB Time 분해
--                @PF_20_측정보조.sql TOPSQL T0  T1    -- 그 구간의 상위 SQL
--                @PF_20_측정보조.sql AWR    T0  T1    -- AWR 보고서 본문
--                @PF_20_측정보조.sql ASH    T0  T1    -- ASH 보고서 본문
--                @PF_20_측정보조.sql ADDM   T0  T1    -- ADDM 보고서 본문
--
--              [두 구간 비교 - Compare Periods]
--                @PF_20_측정보조.sql DIFF   A0:A1  B0:B1
--                  정상 구간 A0~A1 과 이상 구간 B0~B1 을 나란히 놓는다.
--                  콜론으로 이은 태그 쌍을 하나의 인자로 넘긴다.
--
--              [관리]
--                @PF_20_측정보조.sql LIST   -   -      -- 잡아 둔 태그 목록
--                @PF_20_측정보조.sql CLEAR  -   -      -- 전체 삭제
--                @PF_20_측정보조.sql CLEAR  T0  -      -- T0 만 삭제
--
--              보고서는 반드시 파일로 남긴다. 화면 캡처는 근거가 되지 못한다.
--                SQL> SPOOL 01_근거/AWR_T0_T1.txt
--                SQL> @PF_20_측정보조.sql AWR T0 T1
--                SQL> SPOOL OFF
--
-- 소요 시간  : SNAP 5~20초(AWR 스냅샷 생성 포함) · DELTA/TOPSQL 1초 미만
--              AWR 10~40초 · ASH 5~20초 · ADDM 20~90초(분석 작업을 새로 돈다)
--
-- 관찰 지표  : V$SYSSTAT 19종 · V$SYS_TIME_MODEL 6종 · V$SYSTEM_WAIT_CLASS 전체
--              V$SYSTEM_EVENT 주요 10종 · AWR 스냅샷 번호와 DBID/INST
--              VAL1 은 횟수/바이트, VAL2 는 시간(센티초 또는 마이크로초)이다.
--
-- 되돌리기   : PF_99_원복.sql 이 PF_SNAP 과 PF_ADDM_* 작업을 지운다.
--              보고서 제출 전까지는 남겨 두는 편이 좋다(구간의 근거가 된다).
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              1) SNAP 은 AWR 스냅샷을 만든다. SYSAUX 를 조금씩 쓴다.
--                 PF_00 에서 본 보존 기간이 지나면 자동으로 지워진다.
--              2) V$ 누적값은 인스턴스 재기동으로 0 이 된다. 델타가 음수로
--                 나오면 재기동이 끼어든 것이다. 캡처를 버리고 다시 잡는다.
--              3) ADDM 은 이 4 CPU VM 에서 부하가 낮으면 아무 권고도 내지
--                 않는다. "권고 없음" 도 결과다. 그대로 보고서에 적는다.
--              4) ★ 이 스크립트는 SERVEROUTPUT 을 ON 으로 둔다 ★
--                 보고서 본문을 DBMS_OUTPUT 으로 내보내기 때문이다.
--                 실행 계획을 볼 때는 반드시 먼저 끈다 :
--                     SQL> SET SERVEROUTPUT OFF
--                 켜진 상태에서 DBMS_XPLAN.DISPLAY_CURSOR(NULL,...) 를 부르면
--                 "마지막 SQL" 이 DBMS_OUTPUT.GET_LINES 로 잡혀 계획을 못 가져온다.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED
SET LINESIZE 200
SET PAGESIZE 200
SET TRIMSPOOL ON
SET TAB OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET DEFINE ON

DEFINE pf_cmd = &1
DEFINE pf_t0  = &2
DEFINE pf_t1  = &3


-- ----------------------------------------------------------------------------
-- [1] 보관표 (없으면 만든다).  SQLT 스키마에 둔다 - SYS 에 표를 만들지 않는다.
-- ----------------------------------------------------------------------------
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt
      FROM dba_tables WHERE owner = 'SQLT' AND table_name = 'PF_SNAP';
    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE SQLT.PF_SNAP (
                tag   VARCHAR2(16)  NOT NULL,
                src   VARCHAR2(24)  NOT NULL,
                name  VARCHAR2(128) NOT NULL,
                val1  NUMBER,
                val2  NUMBER,
                ts    TIMESTAMP DEFAULT SYSTIMESTAMP
            )';
        EXECUTE IMMEDIATE
            'CREATE UNIQUE INDEX SQLT.PK_PF_SNAP ON SQLT.PF_SNAP (tag, src, name)';
        DBMS_OUTPUT.PUT_LINE('[준비] SQLT.PF_SNAP 을 만들었다.');
    END IF;
END;
/


-- ----------------------------------------------------------------------------
-- [2] SNAP  :  AWR 스냅샷을 만들고, 그 번호와 V$ 누적값을 태그에 담는다
-- ----------------------------------------------------------------------------
DECLARE
    v_cmd  VARCHAR2(16) := UPPER('&pf_cmd');
    v_tag  VARCHAR2(16) := UPPER('&pf_t0');
    v_snap NUMBER;
    v_dbid NUMBER;
    v_inst NUMBER;
    v_n    NUMBER;
BEGIN
    IF v_cmd <> 'SNAP' THEN RETURN; END IF;
    IF v_tag IS NULL OR v_tag = '-' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'SNAP 은 태그가 필요하다. 예: @PF_20_측정보조.sql SNAP T0 -');
    END IF;

    EXECUTE IMMEDIATE 'DELETE FROM SQLT.PF_SNAP WHERE tag = :1' USING v_tag;

    -- (0) AWR 스냅샷을 지금 만든다. 구간 경계를 사람이 받아 적지 않게 한다.
    v_snap := DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT('TYPICAL');
    SELECT dbid INTO v_dbid FROM v$database;
    SELECT instance_number INTO v_inst FROM v$instance;

    EXECUTE IMMEDIATE '
        INSERT INTO SQLT.PF_SNAP (tag, src, name, val1)
        SELECT :a, ''AWR'', ''SNAP_ID'', :b FROM dual UNION ALL
        SELECT :a, ''AWR'', ''DBID'',    :c FROM dual UNION ALL
        SELECT :a, ''AWR'', ''INST'',    :d FROM dual'
      USING v_tag, v_snap, v_tag, v_dbid, v_tag, v_inst;

    -- (1) 시스템 통계
    EXECUTE IMMEDIATE '
        INSERT INTO SQLT.PF_SNAP (tag, src, name, val1, val2)
        SELECT :1, ''SYSSTAT'', name, value, NULL
          FROM v$sysstat
         WHERE name IN (''parse count (total)'',''parse count (hard)'',
                        ''execute count'',''user calls'',''recursive calls'',
                        ''user commits'',''user rollbacks'',
                        ''session logical reads'',''physical reads'',
                        ''physical read total bytes'',''physical writes'',
                        ''redo size'',''redo entries'',''redo synch writes'',
                        ''sorts (memory)'',''sorts (disk)'',
                        ''table scans (long tables)'',''table scans (short tables)'',
                        ''SQL*Net roundtrips to/from client'')' USING v_tag;

    -- (2) 시간 모델 (DB time 분해)
    EXECUTE IMMEDIATE '
        INSERT INTO SQLT.PF_SNAP (tag, src, name, val1, val2)
        SELECT :1, ''TIMEMODEL'', stat_name, value, NULL
          FROM v$sys_time_model
         WHERE stat_name IN (''DB time'',''DB CPU'',''sql execute elapsed time'',
                             ''parse time elapsed'',''hard parse elapsed time'',
                             ''PL/SQL execution elapsed time'')' USING v_tag;

    -- (3) 대기 클래스 (전체)
    EXECUTE IMMEDIATE '
        INSERT INTO SQLT.PF_SNAP (tag, src, name, val1, val2)
        SELECT :1, ''WAITCLASS'', wait_class, total_waits, time_waited
          FROM v$system_wait_class' USING v_tag;

    -- (4) 주요 대기 이벤트
    EXECUTE IMMEDIATE '
        INSERT INTO SQLT.PF_SNAP (tag, src, name, val1, val2)
        SELECT :1, ''EVENT'', event, total_waits, time_waited_micro
          FROM v$system_event
         WHERE event IN (''db file sequential read'',''db file scattered read'',
                         ''log file sync'',''log file parallel write'',
                         ''direct path write temp'',''direct path read temp'',
                         ''latch: shared pool'',''library cache: mutex X'',
                         ''enq: TX - row lock contention'',''buffer busy waits'')' USING v_tag;

    COMMIT;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM SQLT.PF_SNAP WHERE tag = :1'
      INTO v_n USING v_tag;
    DBMS_OUTPUT.PUT_LINE('[캡처] 태그 ' || v_tag || ' : AWR 스냅샷 #' || v_snap
                         || ', 항목 ' || v_n || '개 ('
                         || TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') || ')');
    DBMS_OUTPUT.PUT_LINE('        보고서에 적을 구간 경계 : DBID ' || v_dbid
                         || ' / INST ' || v_inst || ' / SNAP ' || v_snap);
END;
/


-- ----------------------------------------------------------------------------
-- [3] CLEAR / LIST
-- ----------------------------------------------------------------------------
DECLARE
    v_cmd VARCHAR2(16) := UPPER('&pf_cmd');
    v_tag VARCHAR2(16) := UPPER('&pf_t0');
BEGIN
    IF v_cmd = 'CLEAR' THEN
        IF v_tag IS NULL OR v_tag = '-' THEN
            EXECUTE IMMEDIATE 'DELETE FROM SQLT.PF_SNAP';
            DBMS_OUTPUT.PUT_LINE('[정리] 모든 스냅샷 캡처를 지웠다.');
            DBMS_OUTPUT.PUT_LINE('        AWR 스냅샷 자체는 남는다(보존 기간까지).');
        ELSE
            EXECUTE IMMEDIATE 'DELETE FROM SQLT.PF_SNAP WHERE tag = :1' USING v_tag;
            DBMS_OUTPUT.PUT_LINE('[정리] 태그 ' || v_tag || ' 을 지웠다.');
        END IF;
        COMMIT;
    END IF;
END;
/

COLUMN tag      FORMAT A8
COLUMN captured FORMAT A20
COLUMN snap_id  FORMAT 999999
COLUMN items    FORMAT 9999
SELECT tag,
       TO_CHAR(MIN(ts), 'YYYY-MM-DD HH24:MI:SS') AS captured,
       MAX(DECODE(name, 'SNAP_ID', val1))        AS snap_id,
       COUNT(*)                                  AS items
  FROM sqlt.pf_snap
 WHERE UPPER('&pf_cmd') IN ('LIST', 'CLEAR')
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

SET HEADING OFF
SELECT '============================================================' || CHR(10) ||
       ' 델타 : ' || UPPER('&pf_t0') || '  ->  ' || UPPER('&pf_t1') || CHR(10) ||
       '  * 누적값을 그대로 비교하지 말고 이 ''델타'' 열만 읽는다.' || CHR(10) ||
       '  * 델타가 음수면 인스턴스가 재기동된 것이다 - 캡처를 다시 잡는다.' || CHR(10) ||
       '============================================================'
  FROM dual WHERE UPPER('&pf_cmd') = 'DELTA';
SET HEADING ON
SELECT a.src, a.name,
       a.val1 AS "전(前)", b.val1 AS "후(後)", b.val1 - a.val1 AS "델타",
       CASE a.src
         WHEN 'TIMEMODEL' THEN '마이크로초'
         WHEN 'WAITCLASS' THEN '대기 ' || TO_CHAR(NVL(b.val2,0) - NVL(a.val2,0)) || ' cs'
         WHEN 'EVENT'     THEN '대기 ' || TO_CHAR(ROUND((NVL(b.val2,0) - NVL(a.val2,0))/1000)) || ' ms'
         ELSE NULL
       END AS "비고"
  FROM sqlt.pf_snap a
  JOIN sqlt.pf_snap b
    ON  b.tag = UPPER('&pf_t1') AND b.src = a.src AND b.name = a.name
 WHERE a.tag = UPPER('&pf_t0')
   AND UPPER('&pf_cmd') = 'DELTA'
   AND a.src <> 'AWR'
   AND (b.val1 - a.val1) <> 0
 ORDER BY DECODE(a.src, 'TIMEMODEL',1, 'WAITCLASS',2, 'SYSSTAT',3, 'EVENT',4),
          b.val1 - a.val1 DESC;

SET HEADING OFF
SELECT CHR(10) || '>>> DB Time 분해 (델타 기준)'
  FROM dual WHERE UPPER('&pf_cmd') = 'DELTA';
SET HEADING ON
SELECT ROUND(MAX(DECODE(name,'DB time',                  d))/1e6, 2) AS "DB_time_초",
       ROUND(MAX(DECODE(name,'DB CPU',                   d))/1e6, 2) AS "DB_CPU_초",
       ROUND(MAX(DECODE(name,'sql execute elapsed time', d))/1e6, 2) AS "SQL실행_초",
       ROUND(MAX(DECODE(name,'hard parse elapsed time',  d))/1e6, 2) AS "하드파싱_초",
       ROUND( (MAX(DECODE(name,'DB time', d)) - MAX(DECODE(name,'DB CPU', d)))
              / DECODE(MAX(DECODE(name,'DB time', d)), 0, 1,
                       MAX(DECODE(name,'DB time', d))) * 100, 1) AS "대기몫_퍼센트"
  FROM (SELECT a.name, b.val1 - a.val1 d
          FROM sqlt.pf_snap a
          JOIN sqlt.pf_snap b ON b.tag = UPPER('&pf_t1')
                             AND b.src = a.src AND b.name = a.name
         WHERE a.tag = UPPER('&pf_t0') AND a.src = 'TIMEMODEL')
 WHERE UPPER('&pf_cmd') = 'DELTA'
HAVING COUNT(*) > 0;
SET FEEDBACK OFF

SET HEADING OFF
SELECT CHR(10) || '>>> 평균 활성 세션(AAS) = DB Time / 경과 시간' || CHR(10) ||
       '    AAS 가 CPU 수(' ||
       (SELECT value FROM v$osstat WHERE stat_name = 'NUM_CPUS') ||
       ') 보다 크면 CPU 가 포화다.'
  FROM dual WHERE UPPER('&pf_cmd') = 'DELTA';
SET HEADING ON
SELECT ROUND(e.sec, 1)                                        AS "경과_초",
       ROUND(e.dbt/1e6, 2)                                    AS "DB_time_초",
       ROUND(e.dbt/1e6 / DECODE(e.sec, 0, 1, e.sec), 2)       AS "AAS",
       (SELECT value FROM v$osstat WHERE stat_name = 'NUM_CPUS') AS "CPU_수"
  FROM (SELECT (SELECT (CAST(MAX(ts) AS DATE) - CAST(MIN(ts) AS DATE)) * 86400
                  FROM sqlt.pf_snap
                 WHERE tag IN (UPPER('&pf_t0'), UPPER('&pf_t1'))) AS sec,
               (SELECT b.val1 - a.val1
                  FROM sqlt.pf_snap a, sqlt.pf_snap b
                 WHERE a.tag = UPPER('&pf_t0') AND b.tag = UPPER('&pf_t1')
                   AND a.src = 'TIMEMODEL' AND b.src = 'TIMEMODEL'
                   AND a.name = 'DB time'  AND b.name = 'DB time') AS dbt
          FROM dual) e
 WHERE UPPER('&pf_cmd') = 'DELTA';
SET FEEDBACK OFF


-- ----------------------------------------------------------------------------
-- [5] TOPSQL  :  구간의 상위 SQL (AWR 본문을 읽기 전에 범인 후보를 좁힌다)
-- ----------------------------------------------------------------------------
COLUMN sql_id      FORMAT A14
COLUMN sqltext     FORMAT A44
COLUMN "경과_초"   FORMAT 999,999.99
COLUMN "실행"      FORMAT 999,999,999
COLUMN "회당_초"   FORMAT 999,999.999
COLUMN "버퍼읽기"  FORMAT 999,999,999,999
COLUMN "회당_버퍼" FORMAT 999,999,999

SET HEADING OFF
SELECT '============================================================' || CHR(10) ||
       ' 상위 SQL : ' || UPPER('&pf_t0') || ' -> ' || UPPER('&pf_t1') || CHR(10) ||
       '  * 총 경과 시간이 큰 SQL 이 아니라, 왜 큰지(회당? 횟수?)를 본다.' || CHR(10) ||
       '  * 회당은 짧은데 총합이 크면 호출 횟수 문제다 - SQL 을 고쳐도 안 준다.' || CHR(10) ||
       '  * wrh$_/wrm$_ 로 시작하는 INSERT 는 AWR 이 스냅샷을 쓰는 SQL 이다.' || CHR(10) ||
       '    측정 행위 자체가 남긴 흔적이니 범인 후보에서 뺀다.' || CHR(10) ||
       '  * DECLARE 로 시작하는 줄은 부하 스크립트의 PL/SQL 블록이다. 그 안의' || CHR(10) ||
       '    SQL 이 아래에 따로 잡히므로, 블록과 SQL 을 이중으로 세지 않는다.' || CHR(10) ||
       '============================================================'
  FROM dual WHERE UPPER('&pf_cmd') = 'TOPSQL';
SET HEADING ON
SELECT * FROM (
  SELECT s.sql_id,
         SUBSTR(REGEXP_REPLACE(t.txt, '[[:space:]]+', ' '), 1, 44)   AS sqltext,
         ROUND(SUM(s.elapsed_time_delta)/1e6, 2)                     AS "경과_초",
         SUM(s.executions_delta)                                     AS "실행",
         ROUND(SUM(s.elapsed_time_delta)/1e6
               / DECODE(SUM(s.executions_delta), 0, 1, SUM(s.executions_delta)), 3)
                                                                     AS "회당_초",
         SUM(s.buffer_gets_delta)                                    AS "버퍼읽기",
         ROUND(SUM(s.buffer_gets_delta)
               / DECODE(SUM(s.executions_delta), 0, 1, SUM(s.executions_delta)))
                                                                     AS "회당_버퍼"
    FROM dba_hist_sqlstat s
    LEFT JOIN (SELECT dbid, sql_id, DBMS_LOB.SUBSTR(sql_text, 200, 1) AS txt
                 FROM dba_hist_sqltext) t
      ON t.dbid = s.dbid AND t.sql_id = s.sql_id
   WHERE UPPER('&pf_cmd') = 'TOPSQL'
     AND s.snap_id >  (SELECT val1 FROM sqlt.pf_snap
                        WHERE tag = UPPER('&pf_t0') AND name = 'SNAP_ID')
     AND s.snap_id <= (SELECT val1 FROM sqlt.pf_snap
                        WHERE tag = UPPER('&pf_t1') AND name = 'SNAP_ID')
     AND s.dbid    =  (SELECT val1 FROM sqlt.pf_snap
                        WHERE tag = UPPER('&pf_t0') AND name = 'DBID')
   GROUP BY s.sql_id, t.txt
   ORDER BY 3 DESC)
 WHERE ROWNUM <= 15;
SET FEEDBACK OFF

SET HEADING OFF
SELECT CHR(10) || '>>> 같은 모양·다른 리터럴로 쪼개진 SQL (리터럴 공유 여부)'
  FROM dual WHERE UPPER('&pf_cmd') = 'TOPSQL';
SET HEADING ON
COLUMN fms FORMAT 99999999999999999999
SELECT * FROM (
  SELECT s.force_matching_signature                AS fms,
         COUNT(DISTINCT s.sql_id)                  AS "서로_다른_SQL_ID",
         SUM(s.executions_delta)                   AS "실행",
         ROUND(SUM(s.elapsed_time_delta)/1e6, 2)   AS "경과_초",
         SUM(s.parse_calls_delta)                  AS "파싱_호출"
    FROM dba_hist_sqlstat s
   WHERE UPPER('&pf_cmd') = 'TOPSQL'
     AND s.force_matching_signature <> 0
     AND s.snap_id >  (SELECT val1 FROM sqlt.pf_snap
                        WHERE tag = UPPER('&pf_t0') AND name = 'SNAP_ID')
     AND s.snap_id <= (SELECT val1 FROM sqlt.pf_snap
                        WHERE tag = UPPER('&pf_t1') AND name = 'SNAP_ID')
   GROUP BY s.force_matching_signature
  HAVING COUNT(DISTINCT s.sql_id) > 1
   ORDER BY 2 DESC)
 WHERE ROWNUM <= 10;
SET FEEDBACK OFF


-- ----------------------------------------------------------------------------
-- [6] AWR / DIFF / ASH / ADDM  :  보고서 본문
-- ----------------------------------------------------------------------------
-- 보고서는 PL/SQL 블록 안에서 만들어 DBMS_OUTPUT 으로 내보낸다.
--
-- 왜 SELECT 한 방으로 쓰지 않는가 :
--   SELECT output FROM TABLE(AWR_REPORT_TEXT(...)) WHERE '명령' = 'AWR'
--   처럼 쓰면, 조건이 거짓이어도 테이블 함수가 먼저 실행된다. 태그가 없을 때
--   NULL 인자로 호출돼 엉뚱한 오류가 난다. IF 문으로 막아야 확실히 건너뛴다.
--
-- 왜 함수를 PL/SQL 에서 바로 부르지 않는가 :
--   AWR_REPORT_TEXT 는 파이프라인 테이블 함수다. PL/SQL 에서 직접 호출하면
--   PLS-00653 "PL/SQL 범위에는 집계/테이블 함수는 허용되지 않습니다" 가 난다.
--   반드시 SELECT ... FROM TABLE(...) 커서로 감싼다.
-- ----------------------------------------------------------------------------
DECLARE
    v_cmd  VARCHAR2(16) := UPPER('&pf_cmd');
    v_a    VARCHAR2(40) := UPPER('&pf_t0');
    v_b    VARCHAR2(40) := UPPER('&pf_t1');
    v_task VARCHAR2(60);

    -- 구간 경계 (SQL 커서에 넘길 변수)
    n_dbid  NUMBER;  n_inst  NUMBER;  n_b  NUMBER;  n_e  NUMBER;
    n_dbid2 NUMBER;  n_inst2 NUMBER;  n_b2 NUMBER;  n_e2 NUMBER;
    d_b DATE;        d_e DATE;

    -- 태그에서 구간 경계를 꺼낸다
    FUNCTION val(p_tag VARCHAR2, p_name VARCHAR2) RETURN NUMBER IS
        v_n NUMBER;
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT val1 FROM SQLT.PF_SNAP
              WHERE tag = :1 AND src = ''AWR'' AND name = :2'
          INTO v_n USING p_tag, p_name;
        RETURN v_n;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002,
                '태그 ' || p_tag || ' 의 ' || p_name || ' 가 없다. '
                || 'SNAP 으로 먼저 구간을 잡아라 (LIST 로 확인).');
    END;

    -- 태그를 잡은 시각 (ASH 구간 경계)
    FUNCTION tim(p_tag VARCHAR2, p_min BOOLEAN) RETURN DATE IS
        v_d DATE;
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT CAST(' || CASE WHEN p_min THEN 'MIN' ELSE 'MAX' END
            || '(ts) AS DATE) FROM SQLT.PF_SNAP WHERE tag = :1'
          INTO v_d USING p_tag;
        IF v_d IS NULL THEN
            RAISE_APPLICATION_ERROR(-20002, '태그 ' || p_tag || ' 이 없다.');
        END IF;
        RETURN v_d;
    END;

    -- 'A0:A1' 을 앞/뒤로 쪼갠다
    FUNCTION part(p_pair VARCHAR2, p_no NUMBER) RETURN VARCHAR2 IS
    BEGIN
        IF INSTR(p_pair, ':') = 0 THEN
            RAISE_APPLICATION_ERROR(-20003,
                'DIFF 는 태그 쌍을 콜론으로 이어 넘긴다. 예: DIFF A0:A1 B0:B1');
        END IF;
        RETURN CASE p_no
                 WHEN 1 THEN SUBSTR(p_pair, 1, INSTR(p_pair, ':') - 1)
                 ELSE        SUBSTR(p_pair, INSTR(p_pair, ':') + 1)
               END;
    END;

    -- CLOB 을 줄 단위로 내보낸다 (ADDM 보고서)
    PROCEDURE emit_clob(p_clob CLOB) IS
        v_len NUMBER := NVL(DBMS_LOB.GETLENGTH(p_clob), 0);
        v_pos NUMBER := 1;
        v_nl  NUMBER;
    BEGIN
        IF v_len = 0 THEN
            DBMS_OUTPUT.PUT_LINE('(보고서가 비어 있다)');
            RETURN;
        END IF;
        WHILE v_pos <= v_len LOOP
            v_nl := DBMS_LOB.INSTR(p_clob, CHR(10), v_pos);
            IF v_nl = 0 THEN v_nl := v_len + 1; END IF;
            IF v_nl > v_pos THEN
                DBMS_OUTPUT.PUT_LINE(RTRIM(
                    DBMS_LOB.SUBSTR(p_clob, LEAST(v_nl - v_pos, 4000), v_pos), CHR(13)));
            ELSE
                DBMS_OUTPUT.PUT_LINE(' ');
            END IF;
            v_pos := v_nl + 1;
        END LOOP;
    END;
BEGIN
    IF v_cmd = 'AWR' THEN
        n_dbid := val(v_a, 'DBID');
        n_inst := val(v_a, 'INST');
        n_b    := val(v_a, 'SNAP_ID');
        n_e    := val(v_b, 'SNAP_ID');
        FOR r IN (SELECT output FROM TABLE(
                      DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(
                          n_dbid, n_inst, n_b, n_e))) LOOP
            DBMS_OUTPUT.PUT_LINE(RTRIM(NVL(r.output, ' ')));
        END LOOP;

    ELSIF v_cmd = 'DIFF' THEN
        n_dbid  := val(part(v_a,1), 'DBID');
        n_inst  := val(part(v_a,1), 'INST');
        n_b     := val(part(v_a,1), 'SNAP_ID');
        n_e     := val(part(v_a,2), 'SNAP_ID');
        n_dbid2 := val(part(v_b,1), 'DBID');
        n_inst2 := val(part(v_b,1), 'INST');
        n_b2    := val(part(v_b,1), 'SNAP_ID');
        n_e2    := val(part(v_b,2), 'SNAP_ID');
        FOR r IN (SELECT output FROM TABLE(
                      DBMS_WORKLOAD_REPOSITORY.AWR_DIFF_REPORT_TEXT(
                          n_dbid,  n_inst,  n_b,  n_e,
                          n_dbid2, n_inst2, n_b2, n_e2))) LOOP
            DBMS_OUTPUT.PUT_LINE(RTRIM(NVL(r.output, ' ')));
        END LOOP;

    ELSIF v_cmd = 'ASH' THEN
        n_dbid := val(v_a, 'DBID');
        n_inst := val(v_a, 'INST');
        d_b    := tim(v_a, TRUE);
        d_e    := tim(v_b, FALSE);
        FOR r IN (SELECT output FROM TABLE(
                      DBMS_WORKLOAD_REPOSITORY.ASH_REPORT_TEXT(
                          n_dbid, n_inst, d_b, d_e))) LOOP
            DBMS_OUTPUT.PUT_LINE(RTRIM(NVL(r.output, ' ')));
        END LOOP;

    ELSIF v_cmd = 'ADDM' THEN
        n_b := val(v_a, 'SNAP_ID');
        n_e := val(v_b, 'SNAP_ID');
        v_task := 'PF_ADDM_' || v_a || '_' || v_b;
        BEGIN
            DBMS_ADVISOR.DELETE_TASK(v_task);   -- 같은 이름을 다시 쓸 수 있게
        EXCEPTION WHEN OTHERS THEN NULL;        -- 첫 실행이면 없다
        END;
        DBMS_ADDM.ANALYZE_DB(v_task, n_b, n_e);
        DBMS_OUTPUT.PUT_LINE('[ADDM] 작업 ' || v_task || ' 완료 (스냅샷 '
                             || n_b || ' ~ ' || n_e || ')');
        DBMS_OUTPUT.PUT_LINE(' ');
        emit_clob(DBMS_ADDM.GET_REPORT(v_task));
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('-- 해석: 권고가 비어 있으면 "이 구간에서 ADDM 은 권고를');
        DBMS_OUTPUT.PUT_LINE('--       내지 않았다" 가 결과다. 부하가 낮거나(AAS 가 작다)');
        DBMS_OUTPUT.PUT_LINE('--       병목이 DB 밖이면 침묵한다. 보고서에는 침묵 사실과,');
        DBMS_OUTPUT.PUT_LINE('--       그래서 무엇을 대신 근거로 삼았는지 쓴다.');
    END IF;
END;
/

SET FEEDBACK ON
UNDEFINE pf_cmd
UNDEFINE pf_t0
UNDEFINE pf_t1
