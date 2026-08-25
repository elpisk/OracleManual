-- ============================================================================
-- [실측 검증 2026-08-25] db file scattered read 69회·physical reads 6613·direct 0 — _serial_direct_read=NEVER 우회 재현 확인(CLAIM_DETAILS 3회 스캔)
-- WL_02_io.sql  :  물리 I/O 부하 (전체 스캔 + 인덱스 경유 랜덤 단일 블록 읽기)
-- Oracle Database 19c 성능 튜닝 실무 과정 · 공용 부하 스크립트 (2/6)
-- ============================================================================
-- 목적       : 두 가지 성격이 다른 물리 I/O를 각각 분리해 유발한다.
--                구획 1) 인덱스 경유 랜덤 단일 블록 읽기 -> db file sequential read
--                구획 2) 대량 전체 스캔(다중 블록 읽기)   -> db file scattered read
--              같은 "physical reads" 라도 어떤 대기 이벤트로 나타나는지, 그리고
--              한 번의 요청이 몇 블록을 읽는지가 다르다는 것을 수치로 보여준다.
--              (14장 대기 이벤트 구분, 17장 버퍼 캐시, 20장 I/O 구성에서 사용)
--
-- 전제       : 1) SQLT 계정 접속. CLAIM_DETAILS(100만+), REVIEW_LOG(50만),
--                 MEDICAL_CLAIMS(30만)와 각 PK 인덱스가 존재할 것.
--                 - 랜덤 읽기는 PK_CLAIM_DETAILS(DETAIL_ID), PK_REVIEW_LOG(LOG_ID)를
--                   경유한다. 이 스키마에는 FK 컬럼 인덱스가 없으므로 PK를 쓴다.
--              2) V$ 뷰 조회 권한.  SYS 에서 1회 :  GRANT SELECT_CATALOG_ROLE TO SQLT;
--              3) 버퍼 캐시 비우기(wl_flush=1)를 쓰려면 ALTER SYSTEM 권한이 필요하다.
--                 권한이 없으면 자동으로 건너뛰고 안내만 출력한다.
--              4) 이 스크립트는 SELECT만 수행한다. 원본 데이터를 변경하지 않는다.
--
-- 소요 시간  : 기본값(wl_rand=5000, wl_scan=5) 기준 대략 40초~2분.
--              [근거] 랜덤 단일 블록 읽기는 캐시 미스 시 대략 0.2~5ms/건 이므로
--                     5,000회 x (0.2~5ms) = 약 1~25초.
--                     CLAIM_DETAILS 는 100만 행 x 약 50바이트 = 약 50MB 수준이라
--                     전체 스캔 1회는 디스크에서 읽어도 대개 1~5초, 캐시에 올라온
--                     뒤에는 1초 미만이다. 5회 반복해 약 5~25초.
--                     여기에 스냅샷·집계 조회를 더해 40초~2분으로 잡았다.
--              [조절] wl_rand(랜덤 읽기 횟수), wl_scan(전체 스캔 반복 횟수)를 바꾼다.
--                     물리 읽기가 적게 잡히면 wl_flush=1 로 캐시를 비우는 편이
--                     횟수를 늘리는 것보다 효과가 크다.
--
-- 관찰 지표  : db file sequential read / db file scattered read / direct path read,
--              physical reads, physical reads cache, physical read IO requests,
--              session logical reads, table scans (long tables), table fetch by rowid.
--              스크립트가 구획별로 전후 델타를 스스로 출력한다.
--              추가로 아래 SQL을 직접 조회해 확인한다.
--
--                -- (1) 대기 이벤트 (요청당 평균 대기시간까지 본다)
--                SELECT EVENT, TOTAL_WAITS, TIME_WAITED_MICRO,
--                       ROUND(TIME_WAITED_MICRO/DECODE(TOTAL_WAITS,0,1,TOTAL_WAITS)/1000,3) AVG_MS
--                  FROM V$SYSTEM_EVENT
--                 WHERE EVENT IN ('db file sequential read','db file scattered read',
--                                 'db file parallel read','direct path read');
--
--                -- (2) 세그먼트별 물리 읽기 (원인 세그먼트 지목)
--                SELECT OWNER, OBJECT_NAME, OBJECT_TYPE, STATISTIC_NAME, VALUE
--                  FROM V$SEGMENT_STATISTICS
--                 WHERE OWNER = 'SQLT'
--                   AND STATISTIC_NAME IN ('physical reads','physical reads direct',
--                                          'logical reads')
--                   AND VALUE > 0
--                 ORDER BY VALUE DESC FETCH FIRST 15 ROWS ONLY;
--
--                -- (3) 데이터파일별 I/O 분포 (20장)
--                SELECT f.FILE#, d.NAME, f.PHYBLKRD, f.PHYRDS, f.SINGLEBLKRDS,
--                       ROUND(f.PHYBLKRD/DECODE(f.PHYRDS,0,1,f.PHYRDS),2) BLK_PER_REQ
--                  FROM V$FILESTAT f, V$DATAFILE d
--                 WHERE f.FILE# = d.FILE# ORDER BY f.PHYBLKRD DESC;
--
--                -- (4) 버퍼 캐시 히트율 (17장 "히트율의 함정"과 함께 읽을 것)
--                SELECT ROUND((1 - (pr.VALUE - prd.VALUE) /
--                             (dbg.VALUE + cg.VALUE)) * 100, 2) HIT_RATIO
--                  FROM V$SYSSTAT pr, V$SYSSTAT prd, V$SYSSTAT dbg, V$SYSSTAT cg
--                 WHERE pr.NAME='physical reads' AND prd.NAME='physical reads direct'
--                   AND dbg.NAME='db block gets' AND cg.NAME='consistent gets';
--
-- 되돌리기   : 1) 생성하는 영구 객체가 없다. 삭제할 것 없음.
--              2) 세션에서 바꾼 "_serial_direct_read" 는 접속 종료 시 사라진다.
--                 같은 세션에서 즉시 원복하려면:
--                    ALTER SESSION SET "_serial_direct_read" = AUTO;   -- 기본값
--              3) 버퍼 캐시를 비웠다면 원복이라는 개념이 없다. 부하가 다시 돌면
--                 자연히 채워진다. 실습 직후 다른 실습을 이어가면 첫 조회가
--                 느린 것이 정상이다.
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              ▶▶ ALTER SYSTEM FLUSH BUFFER_CACHE 는 운영 DB에서 절대 실행 금지 ◀◀
--              인스턴스 전체의 버퍼 캐시를 통째로 비운다. 실행 직후 모든 세션이
--              디스크에서 다시 읽게 되어 순간적으로 I/O가 폭주하고 응답시간이
--              수십 배 나빠진다. 되돌릴 수 없다. 이 스크립트는 wl_flush=0(끔)이
--              기본값이며, 1로 바꾸는 것은 본인 전용 인스턴스에서만 하라.
--              "_serial_direct_read" 는 언더스코어(숨김) 파라미터다. 세션 수준
--              변경만 사용하고, 인스턴스 수준으로는 바꾸지 않는다.
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
--   wl_rand      : 인덱스 경유 랜덤 단일 블록 조회 횟수 (기본 5000)
--   wl_scan      : CLAIM_DETAILS 전체 스캔 반복 횟수  (기본 5)
--   wl_flush     : 1이면 각 구획 시작 전에 버퍼 캐시를 비운다. 기본 0(끔).
--                  ★ 개인 실습 환경에서만 1로 바꿀 것 ★
--   wl_nodirect  : 1이면 세션에서 serial direct path read 를 끈다(기본 1).
--                  19c는 큰 테이블을 직렬 전체 스캔할 때 버퍼 캐시를 우회하는
--                  'direct path read' 를 쓰는 경우가 많아, 그대로 두면
--                  db file scattered read 가 잡히지 않는다. 이 실습은
--                  scattered read 를 보는 것이 목적이므로 기본값을 1로 둔다.
--                  0으로 두고 실행해 direct path read 로 나타나는 것을 대조하면
--                  20장 "다중 블록 읽기" 실습 소재가 된다.
-- ----------------------------------------------------------------------------
DEFINE wl_rand     = 5000
DEFINE wl_scan     = 5
DEFINE wl_flush    = 0
DEFINE wl_nodirect = 1

PROMPT
PROMPT ============================================================
PROMPT  WL_02_io.sql  -  물리 I/O 부하
PROMPT    랜덤 단일블록 조회(wl_rand)  : &wl_rand
PROMPT    전체 스캔 반복(wl_scan)      : &wl_scan
PROMPT    버퍼 캐시 비우기(wl_flush)   : &wl_flush   (1=비움 / 개인환경 전용)
PROMPT    직렬 직접경로읽기 끄기        : &wl_nodirect
PROMPT ============================================================
PROMPT


-- ----------------------------------------------------------------------------
-- [2] 사전 점검 - I/O 관련 파라미터와 캐시 크기 (조치 전 근거 캡처)
-- ----------------------------------------------------------------------------
PROMPT >>> [사전 점검] I/O 관련 파라미터
COLUMN name  FORMAT A34
COLUMN value FORMAT A28
SELECT NAME, VALUE
  FROM V$PARAMETER
 WHERE NAME IN ('db_block_size','db_file_multiblock_read_count','db_cache_size',
                'sga_target','filesystemio_options','disk_asynch_io',
                'db_cache_advice')
 ORDER BY NAME;

PROMPT >>> [사전 점검] 버퍼 캐시 현재 크기
COLUMN component FORMAT A28
SELECT COMPONENT, ROUND(CURRENT_SIZE/1024/1024) CURRENT_MB,
       ROUND(MIN_SIZE/1024/1024) MIN_MB, ROUND(MAX_SIZE/1024/1024) MAX_MB
  FROM V$MEMORY_DYNAMIC_COMPONENTS
 WHERE COMPONENT IN ('DEFAULT buffer cache','KEEP buffer cache','RECYCLE buffer cache')
   AND CURRENT_SIZE > 0;

PROMPT >>> [사전 점검] 대상 세그먼트 크기
COLUMN segment_name FORMAT A20
SELECT SEGMENT_NAME, SEGMENT_TYPE, ROUND(BYTES/1024/1024,1) MB, BLOCKS
  FROM USER_SEGMENTS
 WHERE SEGMENT_NAME IN ('CLAIM_DETAILS','MEDICAL_CLAIMS','REVIEW_LOG',
                        'PK_CLAIM_DETAILS','PK_REVIEW_LOG')
 ORDER BY BYTES DESC;


-- ----------------------------------------------------------------------------
-- [3] 세션 설정 - serial direct path read 끄기 (선택)
-- ----------------------------------------------------------------------------
BEGIN
    IF &wl_nodirect = 1 THEN
        EXECUTE IMMEDIATE 'ALTER SESSION SET "_serial_direct_read" = NEVER';
        DBMS_OUTPUT.PUT_LINE('[안내] 세션 _serial_direct_read = NEVER 로 설정했다.');
        DBMS_OUTPUT.PUT_LINE('       전체 스캔이 버퍼 캐시를 경유하므로');
        DBMS_OUTPUT.PUT_LINE('       db file scattered read 로 관측된다.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[안내] _serial_direct_read 를 건드리지 않았다.');
        DBMS_OUTPUT.PUT_LINE('       전체 스캔이 direct path read 로 나타날 수 있다.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[안내] _serial_direct_read 설정 실패(무시하고 진행): '
                             || SQLERRM);
END;
/


-- ----------------------------------------------------------------------------
-- [4] 부하 실행 + 구획별 전후 지표 델타 출력
-- ----------------------------------------------------------------------------
DECLARE
    TYPE t_map IS TABLE OF NUMBER INDEX BY VARCHAR2(120);

    v_s0  t_map;   -- 시작
    v_s1  t_map;   -- 구획 1(랜덤 읽기) 직후
    v_s2  t_map;   -- 구획 2(전체 스캔) 직후

    v_n         NUMBER;
    v_c         VARCHAR2(20);
    v_t         NUMBER;
    v_el1       NUMBER := 0;
    v_el2       NUMBER := 0;
    v_max_det   NUMBER;
    v_max_log   NUMBER;
    v_id        NUMBER;
    v_hit       PLS_INTEGER := 0;
    v_flush_ok  BOOLEAN := TRUE;

    PROCEDURE p_snap(p_m OUT t_map) IS
    BEGIN
        p_m.DELETE;
        FOR r IN (
            SELECT '01 [INST] ' || NAME AS k, VALUE AS v
              FROM V$SYSSTAT
             WHERE NAME IN ('physical reads','physical reads cache',
                            'physical reads direct','physical read IO requests',
                            'physical read total bytes','session logical reads',
                            'consistent gets','db block gets',
                            'table scans (long tables)','table scans (short tables)',
                            'table fetch by rowid','table scan blocks gotten')
            UNION ALL
            SELECT '02 [SESS] ' || sn.NAME, ms.VALUE
              FROM V$MYSTAT ms, V$STATNAME sn
             WHERE ms.STATISTIC# = sn.STATISTIC#
               AND sn.NAME IN ('physical reads','physical reads cache',
                               'physical reads direct','physical read IO requests',
                               'session logical reads','consistent gets',
                               'table scans (long tables)','table fetch by rowid',
                               'table scan blocks gotten')
            UNION ALL
            SELECT '03 [SESS] ' || EVENT || '  (대기횟수)', TOTAL_WAITS
              FROM V$SESSION_EVENT
             WHERE SID = SYS_CONTEXT('USERENV','SID')
               AND EVENT IN ('db file sequential read','db file scattered read',
                             'db file parallel read','direct path read',
                             'read by other session','buffer busy waits')
            UNION ALL
            SELECT '04 [SESS] ' || EVENT || '  (대기ms)', ROUND(TIME_WAITED_MICRO/1000)
              FROM V$SESSION_EVENT
             WHERE SID = SYS_CONTEXT('USERENV','SID')
               AND EVENT IN ('db file sequential read','db file scattered read',
                             'db file parallel read','direct path read',
                             'read by other session','buffer busy waits')
            UNION ALL
            SELECT '05 [INST] ' || EVENT || '  (대기횟수)', TOTAL_WAITS
              FROM V$SYSTEM_EVENT
             WHERE EVENT IN ('db file sequential read','db file scattered read',
                             'db file parallel read','direct path read')
            UNION ALL
            SELECT '06 [INST] ' || EVENT || '  (대기ms)', ROUND(TIME_WAITED_MICRO/1000)
              FROM V$SYSTEM_EVENT
             WHERE EVENT IN ('db file sequential read','db file scattered read',
                             'db file parallel read','direct path read')
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

    -- 버퍼 캐시 비우기(선택). 권한이 없으면 안내만 남기고 진행한다.
    PROCEDURE p_flush IS
    BEGIN
        IF &wl_flush = 1 AND v_flush_ok THEN
            EXECUTE IMMEDIATE 'ALTER SYSTEM FLUSH BUFFER_CACHE';
            DBMS_OUTPUT.PUT_LINE('  [주의] 버퍼 캐시를 비웠다 (개인 실습 환경 전용).');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            v_flush_ok := FALSE;
            DBMS_OUTPUT.PUT_LINE('  [안내] 버퍼 캐시 비우기 실패(권한 부족 등). '
                                 || '이후 시도는 생략한다 : ' || SQLERRM);
    END p_flush;

BEGIN
    SELECT MAX(DETAIL_ID) INTO v_max_det FROM CLAIM_DETAILS;
    SELECT MAX(LOG_ID)    INTO v_max_log FROM REVIEW_LOG;
    DBMS_OUTPUT.PUT_LINE('[WL_02] 대상 범위 : DETAIL_ID 1~' || v_max_det ||
                         ', LOG_ID 1~' || v_max_log);

    p_snap(v_s0);

    --------------------------------------------------------------------------
    -- 구획 1 : 인덱스 경유 랜덤 단일 블록 읽기  ->  db file sequential read
    --   PK 유니크 인덱스를 타고 무작위 키를 찾는다. 인덱스 블록과 테이블 블록을
    --   한 번에 한 개씩 읽으므로 요청당 블록 수가 1 에 수렴한다.
    --------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('>>> 구획 1 : 랜덤 단일 블록 읽기 시작 (' || &wl_rand || '회)');
    p_flush;
    v_t := DBMS_UTILITY.GET_TIME;

    FOR i IN 1 .. &wl_rand LOOP
        -- CLAIM_DETAILS : PK_CLAIM_DETAILS(DETAIL_ID) 유니크 스캔 + ROWID 액세스
        v_id := TRUNC(DBMS_RANDOM.VALUE(1, v_max_det + 1));
        BEGIN
            SELECT /*+ INDEX(d PK_CLAIM_DETAILS) */ /* WL02_RAND_DET */ d.AMT
              INTO v_n
              FROM CLAIM_DETAILS d
             WHERE d.DETAIL_ID = v_id;
            v_hit := v_hit + 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
        END;

        -- REVIEW_LOG : 다른 세그먼트도 함께 두드려 세그먼트별 분포를 만든다
        IF MOD(i, 2) = 0 THEN
            v_id := TRUNC(DBMS_RANDOM.VALUE(1, v_max_log + 1));
            BEGIN
                SELECT /*+ INDEX(l PK_REVIEW_LOG) */ /* WL02_RAND_LOG */ l.CLAIM_ID
                  INTO v_c
                  FROM REVIEW_LOG l
                 WHERE l.LOG_ID = v_id;
            EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
            END;
        END IF;
    END LOOP;

    v_el1 := (DBMS_UTILITY.GET_TIME - v_t) / 100;
    DBMS_OUTPUT.PUT_LINE('    구획 1 완료 : ' || v_el1 || ' 초, 적중 ' || v_hit || ' 건');
    p_snap(v_s1);

    --------------------------------------------------------------------------
    -- 구획 2 : 대량 전체 스캔  ->  db file scattered read
    --   AMT / TOTAL_AMT 는 인덱스가 없는 컬럼이라 반드시 테이블을 다 읽어야 한다.
    --   FULL 힌트로 인덱스 고속 전체 스캔으로 새는 것을 막는다.
    --------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('>>> 구획 2 : 대량 전체 스캔 시작 (' || &wl_scan || '회 반복)');
    p_flush;
    v_t := DBMS_UTILITY.GET_TIME;

    FOR i IN 1 .. &wl_scan LOOP
        SELECT /*+ FULL(d) NO_PARALLEL(d) */ /* WL02_SCAN_DET */
               SUM(d.AMT)
          INTO v_n
          FROM CLAIM_DETAILS d
         WHERE d.QTY >= 0;

        SELECT /*+ FULL(c) NO_PARALLEL(c) */ /* WL02_SCAN_CLM */
               SUM(c.TOTAL_AMT)
          INTO v_n
          FROM MEDICAL_CLAIMS c
         WHERE c.TOTAL_AMT >= 0;

        -- 반복 사이에 캐시를 비워야 매 회차 물리 읽기가 발생한다(선택).
        IF i < &wl_scan THEN
            p_flush;
        END IF;
    END LOOP;

    v_el2 := (DBMS_UTILITY.GET_TIME - v_t) / 100;
    DBMS_OUTPUT.PUT_LINE('    구획 2 완료 : ' || v_el2 || ' 초');
    p_snap(v_s2);

    --------------------------------------------------------------------------
    -- 델타 리포트
    --------------------------------------------------------------------------
    p_head('[구획 1] 인덱스 경유 랜덤 단일 블록 읽기 - 전후 델타');
    p_diff(v_s0, v_s1);

    p_head('[구획 2] 대량 전체 스캔 - 전후 델타');
    p_diff(v_s1, v_s2);

    p_head('[전체] 구획 1 + 2 합산 - 전후 델타');
    p_diff(v_s0, v_s2);

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('### 판정 포인트 ###');
    DBMS_OUTPUT.PUT_LINE('  1) 구획 1 은 db file sequential read 가, 구획 2 는');
    DBMS_OUTPUT.PUT_LINE('     db file scattered read 가 지배적으로 늘어야 한다.');
    DBMS_OUTPUT.PUT_LINE('     구획 2 에서 direct path read 만 늘었다면 세션의');
    DBMS_OUTPUT.PUT_LINE('     _serial_direct_read 설정이 적용되지 않은 것이다.');
    DBMS_OUTPUT.PUT_LINE('  2) physical reads 델타를 physical read IO requests 델타로');
    DBMS_OUTPUT.PUT_LINE('     나눈 값이 "요청당 블록 수"다. 구획 1 은 1 에 가깝고');
    DBMS_OUTPUT.PUT_LINE('     구획 2 는 db_file_multiblock_read_count 에 가까워야 한다.');
    DBMS_OUTPUT.PUT_LINE('     같은 물리 읽기 블록 수라도 요청 횟수가 다르면 체감이 다르다.');
    DBMS_OUTPUT.PUT_LINE('  3) physical reads 델타가 0 에 가깝다면 이미 버퍼 캐시에');
    DBMS_OUTPUT.PUT_LINE('     다 올라와 있다는 뜻이다. wl_flush=1 로 다시 실행한다.');
    DBMS_OUTPUT.PUT_LINE('     (개인 실습 환경 전용 - 운영 DB 절대 금지)');
    DBMS_OUTPUT.PUT_LINE('  4) 경과 시간 : 구획1 ' || v_el1 || '초 / 구획2 ' || v_el2 || '초');
END;
/


-- ----------------------------------------------------------------------------
-- [5] 실행 후 관찰
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> [실행 후] I/O 대기 이벤트와 요청당 평균 대기시간
COLUMN event FORMAT A30
SELECT EVENT,
       TOTAL_WAITS,
       TIME_WAITED_MICRO,
       ROUND(TIME_WAITED_MICRO / DECODE(TOTAL_WAITS,0,1,TOTAL_WAITS) / 1000, 3) AVG_MS
  FROM V$SYSTEM_EVENT
 WHERE EVENT IN ('db file sequential read','db file scattered read',
                 'db file parallel read','direct path read',
                 'read by other session')
 ORDER BY TIME_WAITED_MICRO DESC;

PROMPT
PROMPT >>> [실행 후] 세그먼트별 물리/논리 읽기 상위 15 (원인 세그먼트 지목)
COLUMN object_name FORMAT A22
COLUMN statistic_name FORMAT A24
SELECT OBJECT_NAME, OBJECT_TYPE, STATISTIC_NAME, VALUE
  FROM V$SEGMENT_STATISTICS
 WHERE OWNER = USER
   AND STATISTIC_NAME IN ('physical reads','physical reads direct','logical reads')
   AND VALUE > 0
 ORDER BY VALUE DESC
 FETCH FIRST 15 ROWS ONLY;

PROMPT
PROMPT >>> [실행 후] 이번 부하 SQL 의 실행 통계
COLUMN sql_text FORMAT A46
SELECT SUBSTR(SQL_TEXT,1,46) sql_text, EXECUTIONS, BUFFER_GETS, DISK_READS,
       ROUND(ELAPSED_TIME/1000000,2) ELAPSED_SEC,
       ROUND(DISK_READS/DECODE(EXECUTIONS,0,1,EXECUTIONS),1) READS_PER_EXEC
  FROM V$SQL
 WHERE SQL_TEXT LIKE '%WL02_%'
   AND SQL_TEXT NOT LIKE '%V$SQL%'
 ORDER BY DISK_READS DESC
 FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT >>> [실행 후] 데이터파일별 I/O 분포 (20장 - 편중 판별)
COLUMN name FORMAT A50
SELECT f.FILE#, SUBSTR(d.NAME, -50) name, f.PHYRDS READ_REQS, f.PHYBLKRD BLKS_READ,
       f.SINGLEBLKRDS SINGLE_BLK_REQS,
       ROUND(f.PHYBLKRD / DECODE(f.PHYRDS,0,1,f.PHYRDS), 2) BLK_PER_REQ
  FROM V$FILESTAT f, V$DATAFILE d
 WHERE f.FILE# = d.FILE#
 ORDER BY f.PHYBLKRD DESC;


-- ----------------------------------------------------------------------------
-- [6] 되돌리기
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> [되돌리기] 세션 파라미터 원복
BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET "_serial_direct_read" = AUTO';
    DBMS_OUTPUT.PUT_LINE('세션 _serial_direct_read = AUTO(기본값) 로 원복했다.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('원복 생략 : ' || SQLERRM);
END;
/

PROMPT
PROMPT ============================================================
PROMPT  WL_02 완료.
PROMPT   - 생성한 영구 객체 없음(삭제할 것 없음).
PROMPT   - 원본 테이블은 읽기만 했다. 데이터 변경 없음.
PROMPT   - 물리 읽기가 약하면 DEFINE wl_flush = 1 로 재실행한다.
PROMPT     ** ALTER SYSTEM FLUSH BUFFER_CACHE 는 운영 DB 절대 금지 **
PROMPT   - 20장 대조 : DEFINE wl_nodirect = 0 으로 재실행하면 같은 스캔이
PROMPT     direct path read 로 나타나는 것을 확인할 수 있다.
PROMPT ============================================================
SET TIMING OFF
