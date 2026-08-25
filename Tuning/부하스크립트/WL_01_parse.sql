-- ============================================================================
-- [실측 검증 2026-08-25] 하드 파싱 델타 200회(리터럴 200회) vs 대조 바인드 1회 — orcl 19.3에서 재현 확인
-- WL_01_parse.sql  :  하드 파싱(Hard Parse) 폭증 부하
-- Oracle Database 19c 성능 튜닝 실무 과정 · 공용 부하 스크립트 (1/6)
-- ============================================================================
-- 목적       : 바인드 변수를 쓰지 않고 매 실행마다 리터럴이 바뀌는 SQL을 반복 실행해
--              하드 파싱을 대량 유발한다. 같은 부하를 바인드 변수로 실행하는 모드를
--              함께 제공해, 두 방식의 하드 파싱 횟수·라이브러리 캐시 점유를 대조한다.
--              (2장 "바인드 변수와 커서 공유", 18장 "공유 풀과 하드 파싱"에서 사용)
--
-- 전제       : 1) SQLT 계정으로 접속 (진료비청구심사 스키마 소유자).
--              2) PATIENTS 테이블(50,000건)과 PK_PATIENTS 인덱스가 존재할 것.
--              3) V$ 뷰 조회 권한 필요.  SYS로 다음을 1회 수행한다.
--                    GRANT SELECT_CATALOG_ROLE TO SQLT;
--                 (또는 V_$SYSSTAT, V_$MYSTAT, V_$STATNAME, V_$SYSTEM_EVENT,
--                       V_$SESSION_EVENT, V_$LIBRARYCACHE, V_$SGASTAT, V_$SQLAREA,
--                       V_$SQL, V_$PARAMETER 에 개별 SELECT 권한)
--              4) CURSOR_SHARING = EXACT 이어야 리터럴이 그대로 파싱된다.
--                 FORCE/SIMILAR 이면 하드 파싱이 거의 발생하지 않는다.
--                 -> 이 스크립트가 세션 수준으로 EXACT를 설정한다(원복 절차는 아래).
--              5) 이 스크립트는 SELECT만 수행한다. 생성/변경하는 객체가 없다.
--
-- 소요 시간  : 기본값(wl_loops=5000, wl_mode=BOTH) 기준 대략 30초~2분.
--              [근거] 단순 유니크 인덱스 조회 1건의 실행 비용은 수십 마이크로초에
--                     불과하므로 소요 시간의 대부분이 파싱 비용이다. 일반적인 실습
--                     VM에서 하드 파싱 1회는 대략 0.5~3ms 이므로
--                     5,000회 x 0.5~3ms = 약 3~15초(리터럴 모드),
--                     바인드 모드는 소프트 파싱이라 수 초 이내,
--                     여기에 스냅샷·집계 조회 시간을 더해 30초~2분으로 잡았다.
--              [조절] 아래 wl_loops 값을 바꾼다. 지표가 약하면 20000까지 올리고,
--                     너무 오래 걸리면 2000으로 내린다. 시간은 대체로 선형이다.
--
-- 관찰 지표  : parse count (hard), parse count (total), parse time cpu,
--              V$LIBRARYCACHE(SQL AREA)의 GETS/PINS/RELOADS/INVALIDATIONS,
--              공유 풀 사용량(V$SGASTAT), 리터럴 커서 개수(V$SQLAREA).
--              스크립트가 실행 전/후 스냅샷을 스스로 잡아 델타를 출력한다.
--              추가로 아래 SQL을 직접 조회해 확인한다.
--
--                -- (1) 하드 파싱 누적
--                SELECT NAME, VALUE FROM V$SYSSTAT
--                 WHERE NAME IN ('parse count (total)','parse count (hard)',
--                                'parse time cpu','execute count');
--
--                -- (2) 라이브러리 캐시 상태
--                SELECT NAMESPACE, GETS, GETHITRATIO, PINS, PINHITRATIO,
--                       RELOADS, INVALIDATIONS
--                  FROM V$LIBRARYCACHE
--                 WHERE NAMESPACE IN ('SQL AREA','TABLE/PROCEDURE');
--
--                -- (3) 공유 풀 사용량 상위
--                SELECT POOL, NAME, ROUND(BYTES/1024/1024,1) MB
--                  FROM V$SGASTAT
--                 WHERE POOL = 'shared pool'
--                 ORDER BY BYTES DESC FETCH FIRST 10 ROWS ONLY;
--
--                -- (4) 리터럴 때문에 갈라진 커서 개수
--                SELECT COUNT(*) CURSORS, ROUND(SUM(SHARABLE_MEM)/1024/1024,2) SHARED_POOL_MB
--                  FROM V$SQLAREA WHERE SQL_TEXT LIKE '%WL01_LIT%';
--
-- 되돌리기   : 1) 이 스크립트는 테이블/인덱스 등 영구 객체를 만들지 않는다. 삭제할 것 없음.
--              2) 세션에서 바꾼 CURSOR_SHARING은 접속을 끊으면 사라진다.
--                 같은 세션에서 즉시 원복하려면:
--                    ALTER SESSION SET CURSOR_SHARING = EXACT;   -- 기본값
--              3) 공유 풀에 쌓인 리터럴 커서는 시간이 지나면 에이징으로 사라진다.
--                 즉시 비우려면(개인 실습 환경에서만, SYSDBA 권한 필요):
--                    ALTER SYSTEM FLUSH SHARED_POOL;
--                 ** 운영 DB에서는 절대 금지. 전 세션의 실행계획이 사라져
--                    직후 하드 파싱 폭풍이 발생한다. **
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              공유 DB에서 실행하면 공유 풀을 리터럴 커서로 가득 채워 다른 세션에
--              ORA-04031 을 유발할 수 있다. 반드시 본인 전용 인스턴스에서 실행할 것.
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
-- [1] 조절 변수  (환경에 맞게 이 값만 바꾸면 된다)
-- ----------------------------------------------------------------------------
--   wl_loops : 각 모드의 SQL 반복 실행 횟수. 기본 5000.
--   wl_mode  : LITERAL(리터럴만) / BIND(바인드만) / BOTH(둘 다 실행해 대조)
--   wl_cs    : 세션 CURSOR_SHARING. EXACT 여야 리터럴이 하드 파싱된다.
--              18장에서 FORCE 로 바꿔 재실행하면 하드 파싱이 사라지는 것을 볼 수 있다.
-- ----------------------------------------------------------------------------
DEFINE wl_loops = 5000
DEFINE wl_mode  = BOTH
DEFINE wl_cs    = EXACT

PROMPT
PROMPT ============================================================
PROMPT  WL_01_parse.sql  -  하드 파싱 부하
PROMPT    반복 횟수(wl_loops) : &wl_loops
PROMPT    실행 모드(wl_mode)  : &wl_mode
PROMPT    CURSOR_SHARING      : &wl_cs
PROMPT ============================================================
PROMPT


-- ----------------------------------------------------------------------------
-- [2] 사전 점검 - 관련 파라미터 현재 상태 (조치 전 근거 캡처)
-- ----------------------------------------------------------------------------
PROMPT >>> [사전 점검] 파싱 관련 파라미터 현재값
COLUMN name  FORMAT A32
COLUMN value FORMAT A30
SELECT NAME, VALUE
  FROM V$PARAMETER
 WHERE NAME IN ('cursor_sharing','session_cached_cursors','open_cursors',
                'shared_pool_size','sga_target','statistics_level')
 ORDER BY NAME;

PROMPT >>> [사전 점검] 라이브러리 캐시 (실행 전)
COLUMN namespace FORMAT A20
SELECT NAMESPACE, GETS, ROUND(GETHITRATIO,4) GETHITRATIO,
       PINS, ROUND(PINHITRATIO,4) PINHITRATIO, RELOADS, INVALIDATIONS
  FROM V$LIBRARYCACHE
 WHERE NAMESPACE IN ('SQL AREA','TABLE/PROCEDURE','BODY')
 ORDER BY NAMESPACE;

ALTER SESSION SET CURSOR_SHARING = &wl_cs;


-- ----------------------------------------------------------------------------
-- [3] 부하 실행 + 전후 지표 델타 출력
--     구조 : 전 스냅샷 -> 리터럴 부하 -> 중간 스냅샷 -> 바인드 부하 -> 후 스냅샷
--     하나의 익명 블록 안에서 처리해 세션 상태를 잃지 않는다.
-- ----------------------------------------------------------------------------
DECLARE
    TYPE t_map IS TABLE OF NUMBER INDEX BY VARCHAR2(120);

    v_s0    t_map;   -- 실행 전
    v_s1    t_map;   -- 리터럴 부하 직후
    v_s2    t_map;   -- 바인드 부하 직후(= 최종)

    v_n     NUMBER;
    v_t     NUMBER;
    v_el_lit  NUMBER := 0;
    v_el_bin  NUMBER := 0;
    v_run_lit BOOLEAN := UPPER('&wl_mode') IN ('LITERAL','BOTH');
    v_run_bin BOOLEAN := UPPER('&wl_mode') IN ('BIND','BOTH');

    ------------------------------------------------------------------
    -- 관심 지표만 뽑아 스냅샷을 뜬다.
    --   01 : 인스턴스 통계 (V$SYSSTAT)
    --   02 : 내 세션 통계  (V$MYSTAT)
    --   03 : 인스턴스 대기 이벤트 횟수 (V$SYSTEM_EVENT)
    --   04 : 인스턴스 대기 이벤트 시간 (V$SYSTEM_EVENT, ms)
    ------------------------------------------------------------------
    PROCEDURE p_snap(p_m OUT t_map) IS
    BEGIN
        p_m.DELETE;
        FOR r IN (
            SELECT '01 [INST] ' || NAME AS k, VALUE AS v
              FROM V$SYSSTAT
             WHERE NAME IN ('parse count (total)','parse count (hard)',
                            'parse count (failures)','parse time cpu',
                            'parse time elapsed','execute count',
                            'opened cursors cumulative',
                            'session cursor cache hits','recursive calls')
            UNION ALL
            SELECT '02 [SESS] ' || sn.NAME, ms.VALUE
              FROM V$MYSTAT ms, V$STATNAME sn
             WHERE ms.STATISTIC# = sn.STATISTIC#
               AND sn.NAME IN ('parse count (total)','parse count (hard)',
                               'parse time cpu','parse time elapsed',
                               'execute count','opened cursors cumulative',
                               'session cursor cache hits','recursive calls')
            UNION ALL
            SELECT '03 [INST] ' || EVENT || '  (대기횟수)', TOTAL_WAITS
              FROM V$SYSTEM_EVENT
             WHERE EVENT IN ('library cache: mutex X','library cache lock',
                             'library cache pin','cursor: pin S wait on X',
                             'cursor: mutex X','latch: shared pool',
                             'shared pool latch')
            UNION ALL
            SELECT '04 [INST] ' || EVENT || '  (대기ms)', ROUND(TIME_WAITED_MICRO/1000)
              FROM V$SYSTEM_EVENT
             WHERE EVENT IN ('library cache: mutex X','library cache lock',
                             'library cache pin','cursor: pin S wait on X',
                             'cursor: mutex X','latch: shared pool',
                             'shared pool latch')
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

    PROCEDURE p_diff(p_b t_map, p_a t_map) IS
        v_k VARCHAR2(120);
        v_d NUMBER;
    BEGIN
        v_k := p_a.FIRST;
        WHILE v_k IS NOT NULL LOOP
            v_d := p_a(v_k) - f_get(p_b, v_k);
            IF v_d <> 0 OR SUBSTR(v_k,1,2) IN ('01','02') THEN
                DBMS_OUTPUT.PUT_LINE(
                    RPAD(SUBSTR(v_k,4),58) ||
                    LPAD(TO_CHAR(f_get(p_b,v_k),'999,999,999,990'),20) ||
                    LPAD(TO_CHAR(p_a(v_k),      '999,999,999,990'),20) ||
                    LPAD(TO_CHAR(v_d,          'S999,999,999,990'),20));
            END IF;
            v_k := p_a.NEXT(v_k);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(RPAD('-',122,'-'));
    END p_diff;

BEGIN
    DBMS_OUTPUT.PUT_LINE('[WL_01] 부하 시작. 반복=' || &wl_loops ||
                         ', 모드=' || UPPER('&wl_mode'));

    p_snap(v_s0);

    --------------------------------------------------------------------------
    -- 구획 A : 리터럴 SQL  (매 실행마다 SQL 텍스트가 달라져 하드 파싱 발생)
    --   실행 자체는 PK 유니크 인덱스 조회라 거의 공짜다. 그래서 여기서 늘어나는
    --   시간은 곧 "파싱 비용"이다 - 파싱만 분리 관측하려고 일부러 가벼운 SQL을 썼다.
    --------------------------------------------------------------------------
    v_s1 := v_s0;
    IF v_run_lit THEN
        v_t := DBMS_UTILITY.GET_TIME;
        FOR i IN 1 .. &wl_loops LOOP
            EXECUTE IMMEDIATE
                'SELECT /* WL01_LIT */ COUNT(*) FROM PATIENTS WHERE PAT_ID = ' || i
                INTO v_n;
        END LOOP;
        v_el_lit := (DBMS_UTILITY.GET_TIME - v_t) / 100;
        DBMS_OUTPUT.PUT_LINE('  - 구획 A(리터럴) 완료 : ' || v_el_lit || ' 초');
        p_snap(v_s1);
    ELSE
        DBMS_OUTPUT.PUT_LINE('  - 구획 A(리터럴) 건너뜀');
    END IF;

    --------------------------------------------------------------------------
    -- 구획 B : 바인드 변수  (SQL 텍스트가 항상 동일 -> 최초 1회만 하드 파싱)
    --------------------------------------------------------------------------
    v_s2 := v_s1;
    IF v_run_bin THEN
        v_t := DBMS_UTILITY.GET_TIME;
        FOR i IN 1 .. &wl_loops LOOP
            EXECUTE IMMEDIATE
                'SELECT /* WL01_BIND */ COUNT(*) FROM PATIENTS WHERE PAT_ID = :b1'
                INTO v_n USING i;
        END LOOP;
        v_el_bin := (DBMS_UTILITY.GET_TIME - v_t) / 100;
        DBMS_OUTPUT.PUT_LINE('  - 구획 B(바인드) 완료 : ' || v_el_bin || ' 초');
        p_snap(v_s2);
    ELSE
        DBMS_OUTPUT.PUT_LINE('  - 구획 B(바인드) 건너뜀');
    END IF;

    --------------------------------------------------------------------------
    -- 델타 리포트
    --------------------------------------------------------------------------
    IF v_run_lit THEN
        p_head('[구획 A] 리터럴 SQL ' || &wl_loops || '회 - 전후 델타');
        p_diff(v_s0, v_s1);
    END IF;

    IF v_run_bin THEN
        p_head('[구획 B] 바인드 SQL ' || &wl_loops || '회 - 전후 델타');
        p_diff(v_s1, v_s2);
    END IF;

    IF v_run_lit AND v_run_bin THEN
        p_head('[전체] 구획 A + B 합산 - 전후 델타');
        p_diff(v_s0, v_s2);

        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('### 판정 포인트 ###');
        DBMS_OUTPUT.PUT_LINE('  1) [SESS] parse count (hard) 델타를 두 구획에서 비교한다.');
        DBMS_OUTPUT.PUT_LINE('     리터럴은 반복 횟수에 비례해 증가하고, 바인드는 한 자릿수에 머문다.');
        DBMS_OUTPUT.PUT_LINE('  2) 경과 시간 : 리터럴 ' || v_el_lit ||
                             '초  vs  바인드 ' || v_el_bin || '초');
        DBMS_OUTPUT.PUT_LINE('     같은 일을 하는데 벌어진 차이가 곧 파싱 비용이다.');
        DBMS_OUTPUT.PUT_LINE('  3) 실행 횟수(execute count)는 두 구획이 거의 같아야 한다.');
        DBMS_OUTPUT.PUT_LINE('     "일의 양은 같은데 시간이 다르다"는 것이 이 실습의 핵심이다.');
    END IF;
END;
/


-- ----------------------------------------------------------------------------
-- [4] 실행 후 관찰 - 라이브러리 캐시 / 공유 풀 / 커서 분포
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> [실행 후] 라이브러리 캐시 상태  (실행 전 값과 비교할 것)
SELECT NAMESPACE, GETS, ROUND(GETHITRATIO,4) GETHITRATIO,
       PINS, ROUND(PINHITRATIO,4) PINHITRATIO, RELOADS, INVALIDATIONS
  FROM V$LIBRARYCACHE
 WHERE NAMESPACE IN ('SQL AREA','TABLE/PROCEDURE','BODY')
 ORDER BY NAMESPACE;

PROMPT
PROMPT >>> [실행 후] 공유 풀 사용량 상위 10 (MB)
COLUMN pool FORMAT A14
COLUMN name FORMAT A40
SELECT POOL, NAME, ROUND(BYTES/1024/1024,2) MB
  FROM V$SGASTAT
 WHERE POOL = 'shared pool'
 ORDER BY BYTES DESC
 FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT >>> [실행 후] 이번 부하가 만든 커서 개수와 공유 풀 점유
COLUMN kind FORMAT A20
SELECT 'LITERAL(WL01_LIT)' AS KIND,
       COUNT(*) AS CURSORS,
       ROUND(SUM(SHARABLE_MEM)/1024/1024, 3) AS SHARED_POOL_MB,
       SUM(EXECUTIONS) AS TOTAL_EXEC
  FROM V$SQLAREA
 WHERE SQL_TEXT LIKE '%WL01_LIT%'
UNION ALL
SELECT 'BIND(WL01_BIND)',
       COUNT(*),
       ROUND(SUM(SHARABLE_MEM)/1024/1024, 3),
       SUM(EXECUTIONS)
  FROM V$SQLAREA
 WHERE SQL_TEXT LIKE '%WL01_BIND%';

PROMPT
PROMPT >>> [실행 후] FORCE_MATCHING_SIGNATURE 로 본 "사실상 같은 SQL" 묶음 상위 5
COLUMN sample_sql FORMAT A60
SELECT FORCE_MATCHING_SIGNATURE,
       COUNT(*) AS CURSORS,
       ROUND(SUM(SHARABLE_MEM)/1024/1024,3) AS SHARED_POOL_MB,
       MIN(SUBSTR(SQL_TEXT,1,60)) AS SAMPLE_SQL
  FROM V$SQL
 WHERE PARSING_SCHEMA_NAME = USER
   AND FORCE_MATCHING_SIGNATURE <> 0
 GROUP BY FORCE_MATCHING_SIGNATURE
 HAVING COUNT(*) > 1
 ORDER BY 2 DESC
 FETCH FIRST 5 ROWS ONLY;


-- ----------------------------------------------------------------------------
-- [5] 되돌리기
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> [되돌리기] 세션 CURSOR_SHARING 을 기본값(EXACT)으로 원복
ALTER SESSION SET CURSOR_SHARING = EXACT;

PROMPT
PROMPT ============================================================
PROMPT  WL_01 완료.
PROMPT   - 생성한 영구 객체 없음(삭제할 것 없음).
PROMPT   - 공유 풀에 쌓인 리터럴 커서는 에이징으로 자연 소멸한다.
PROMPT   - 즉시 비우려면 SYSDBA 로 아래를 실행한다(개인 실습 환경 전용):
PROMPT       ALTER SYSTEM FLUSH SHARED_POOL;
PROMPT     ** 운영 DB 절대 금지 - 전 세션 실행계획이 사라져 파싱 폭풍이 난다 **
PROMPT   - 18장 대조 실습 : DEFINE wl_cs = FORCE 로 바꿔 재실행하면
PROMPT     리터럴 SQL 인데도 하드 파싱이 급감하는 것을 확인할 수 있다.
PROMPT ============================================================
SET TIMING OFF
