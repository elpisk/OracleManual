-- ============================================================================
-- [실측 대기 2026-08-25] 정적 검증 통과. 다중 세션/PGA/커밋 부하는 SQL*Plus 실행 시 델타 확인 필요(README 4.1 절차).
-- WL_03_sort.sql  :  대량 정렬 · 해시 조인으로 PGA 작업 영역 압박
-- Oracle Database 19c 성능 튜닝 실무 과정 · 공용 부하 스크립트 (3/6)
-- ============================================================================
-- 목적       : 작업 영역(work area)을 일부러 작게 잡은 상태에서 100만 행 규모의
--              정렬·해시 조인·그룹핑을 수행해, 메모리에서 끝나지 못한 작업이
--              임시 테이블스페이스로 넘어가는 것(1-pass / multi-pass)을 재현한다.
--              (19장 "PGA 작업 영역과 1-pass·multi-pass" 실습에서 사용)
--
-- 전제       : 1) SQLT 계정 접속. CLAIM_DETAILS(100만+), MEDICAL_CLAIMS(30만) 존재.
--              2) V$ 뷰 조회 권한.  SYS 에서 1회 :  GRANT SELECT_CATALOG_ROLE TO SQLT;
--                 (V_$PGASTAT, V_$SQL_WORKAREA, V_$SQL_WORKAREA_ACTIVE,
--                  V_$TEMPSEG_USAGE, V_$SORT_SEGMENT 포함)
--              3) 임시 테이블스페이스에 여유 공간이 필요하다. 기본 설정 기준
--                 수백 MB 정도면 충분하다. 부족하면 ORA-01652 가 발생한다
--                 (4장에서는 이 오류 자체가 실습 소재다).
--              4) ★ 작업 영역 축소는 이 스크립트가 세션 수준으로만 수행한다. ★
--                 인스턴스 파라미터(PGA_AGGREGATE_TARGET)는 건드리지 않는다.
--                    ALTER SESSION SET WORKAREA_SIZE_POLICY = MANUAL;
--                    ALTER SESSION SET SORT_AREA_SIZE = <바이트>;
--                    ALTER SESSION SET HASH_AREA_SIZE = <바이트>;
--                 세션만 바꾸므로 다른 세션과 인스턴스에 영향이 없고,
--                 접속을 끊으면 자동으로 원래대로 돌아간다.
--              5) 이 스크립트는 SELECT만 수행한다. 원본 데이터를 변경하지 않는다.
--
--              [참고] 인스턴스 수준으로 재현해야 할 때 (AUTO 정책 유지 실습용)
--                 -- 조치 전 현재값을 반드시 먼저 캡처한다
--                 SHOW PARAMETER pga_aggregate_target
--                 SHOW PARAMETER pga_aggregate_limit
--                 -- 축소 (개인 실습 환경 전용)
--                 ALTER SYSTEM SET PGA_AGGREGATE_TARGET = 100M SCOPE=MEMORY;
--                 -- 원복 : 위에서 캡처한 값을 그대로 되돌린다
--                 ALTER SYSTEM SET PGA_AGGREGATE_TARGET = <원래값> SCOPE=MEMORY;
--                 인스턴스 전체에 영향을 주므로 세션 방식이 안 될 때만 쓴다.
--
-- 소요 시간  : 기본값(wl_div=1, 세 구획 모두 실행) 기준 대략 1~3분.
--              [근거] CLAIM_DETAILS 는 약 100만 행 / 50MB 수준이다. 작업 영역을
--                     1MB 로 줄이면 정렬 데이터가 작업 영역의 수십 배가 되어
--                     반드시 디스크로 넘어간다. 정렬 1회는 임시 테이블스페이스
--                     쓰기+읽기를 합쳐 대략 10~40초, 해시 조인 10~40초,
--                     그룹핑 10~30초 수준이다.
--              [조절] 30초~1분 안에 끝내려면 DEFINE wl_div = 4 로 바꾼다.
--                     대상 행이 1/4 로 줄어 소요 시간도 대략 1/4 이 된다.
--                     디스크 정렬이 안 잡히면 wl_sort_area / wl_hash_area 를
--                     더 줄인다(단, 너무 줄이면 multi-pass 가 심해져 느려진다).
--
-- 관찰 지표  : sorts (memory) / sorts (disk) / sorts (rows),
--              physical writes direct temporary tablespace,
--              physical reads direct temporary tablespace,
--              direct path write temp / direct path read temp 대기,
--              V$SQL_WORKAREA 의 OPTIMAL/ONEPASS/MULTIPASSES_EXECUTIONS,
--              V$PGASTAT 의 over allocation count / cache hit percentage.
--              스크립트가 구획별 전후 델타를 스스로 출력한다.
--              추가로 아래 SQL을 직접 조회해 확인한다.
--
--                -- (1) 디스크 정렬 여부
--                SELECT NAME, VALUE FROM V$SYSSTAT
--                 WHERE NAME IN ('sorts (memory)','sorts (disk)','sorts (rows)');
--
--                -- (2) 작업 영역이 몇 pass 로 처리됐는가
--                SELECT s.SQL_ID, w.OPERATION_TYPE, w.POLICY,
--                       w.OPTIMAL_EXECUTIONS, w.ONEPASS_EXECUTIONS,
--                       w.MULTIPASSES_EXECUTIONS,
--                       ROUND(w.LAST_MEMORY_USED/1024) LAST_MEM_KB,
--                       ROUND(w.LAST_TEMPSEG_SIZE/1024/1024) LAST_TEMP_MB
--                  FROM V$SQL_WORKAREA w, V$SQL s
--                 WHERE w.SQL_ID = s.SQL_ID AND w.CHILD_NUMBER = s.CHILD_NUMBER
--                   AND s.SQL_TEXT LIKE '%WL03%';
--
--                -- (3) PGA 전체 상태
--                SELECT NAME, VALUE FROM V$PGASTAT;
--
--                -- (4) 실행 중 작업 영역 (부하가 도는 동안 다른 세션에서 조회)
--                SELECT SID, OPERATION_TYPE, POLICY, EXPECTED_SIZE, ACTUAL_MEM_USED,
--                       MAX_MEM_USED, TEMPSEG_SIZE, NUMBER_PASSES
--                  FROM V$SQL_WORKAREA_ACTIVE ORDER BY SID;
--
--                -- (5) 임시 테이블스페이스 사용량
--                SELECT TABLESPACE_NAME, ROUND(BYTES_USED/1024/1024) USED_MB,
--                       ROUND(BYTES_FREE/1024/1024) FREE_MB
--                  FROM V$TEMP_SPACE_HEADER;
--
-- 되돌리기   : 1) 생성하는 영구 객체가 없다. 삭제할 것 없음.
--              2) 세션 파라미터 원복 (스크립트 [6]절이 자동으로 수행한다):
--                    ALTER SESSION SET WORKAREA_SIZE_POLICY = AUTO;
--                 접속을 끊어도 원래대로 돌아간다.
--              3) 임시 세그먼트는 SQL 종료 시 자동 반환된다. 남아 있다면
--                 V$TEMPSEG_USAGE 로 사용 세션을 확인한다.
--              4) 인스턴스 파라미터는 이 스크립트가 바꾸지 않으므로 원복 대상이 없다.
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              임시 테이블스페이스를 수백 MB 단위로 소비한다. 공유 DB에서 돌리면
--              다른 세션이 ORA-01652(temp 확장 실패)를 맞을 수 있다.
--              WORKAREA_SIZE_POLICY=MANUAL 은 실습을 위한 의도적 퇴행 설정이다.
--              실무 운영 환경에서는 AUTO(기본값)를 유지하는 것이 정답이다.
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
--   wl_sort_area : 세션 SORT_AREA_SIZE (바이트). 기본 1MB.
--                  대상 정렬량이 약 50MB 이므로 1MB 면 확실히 디스크로 넘어간다.
--                  256KB 로 줄이면 multi-pass 가, 32MB 로 늘리면 optimal 이
--                  나오기 쉬워진다 - 세 값으로 돌려 비교하는 것이 19장 실습이다.
--   wl_hash_area : 세션 HASH_AREA_SIZE (바이트). 기본 2MB.
--                  관례상 sort_area_size 의 2배를 준다.
--   wl_div       : 대상 행 축소 계수. 1이면 전체, 4면 약 1/4 만 사용.
--                  소요 시간을 줄일 때 이 값을 올린다.
--   wl_run_sort  : 1이면 구획 1(정렬) 실행
--   wl_run_hash  : 1이면 구획 2(해시 조인) 실행
--   wl_run_group : 1이면 구획 3(그룹핑) 실행
-- ----------------------------------------------------------------------------
DEFINE wl_sort_area = 1048576
DEFINE wl_hash_area = 2097152
DEFINE wl_div       = 1
DEFINE wl_run_sort  = 1
DEFINE wl_run_hash  = 1
DEFINE wl_run_group = 1

PROMPT
PROMPT ============================================================
PROMPT  WL_03_sort.sql  -  정렬/해시 조인 PGA 압박 부하
PROMPT    SORT_AREA_SIZE : &wl_sort_area  바이트
PROMPT    HASH_AREA_SIZE : &wl_hash_area  바이트
PROMPT    행 축소 계수   : &wl_div  (1=전체)
PROMPT    실행 구획      : sort=&wl_run_sort hash=&wl_run_hash group=&wl_run_group
PROMPT ============================================================
PROMPT


-- ----------------------------------------------------------------------------
-- [2] 사전 점검 - PGA 관련 현재 상태 (조치 전 근거 캡처)
-- ----------------------------------------------------------------------------
PROMPT >>> [사전 점검] PGA 관련 인스턴스 파라미터 (이 스크립트는 변경하지 않는다)
COLUMN name  FORMAT A34
COLUMN value FORMAT A28
SELECT NAME, VALUE
  FROM V$PARAMETER
 WHERE NAME IN ('pga_aggregate_target','pga_aggregate_limit',
                'workarea_size_policy','sort_area_size','hash_area_size',
                'memory_target')
 ORDER BY NAME;

PROMPT >>> [사전 점검] V$PGASTAT (실행 전)
COLUMN pga_name FORMAT A44
SELECT NAME pga_name, VALUE, UNIT
  FROM V$PGASTAT
 WHERE NAME IN ('aggregate PGA target parameter','total PGA allocated',
                'maximum PGA allocated','over allocation count',
                'cache hit percentage','extra bytes read/written',
                'total PGA used for auto workareas')
 ORDER BY NAME;

PROMPT >>> [사전 점검] 임시 테이블스페이스 사용량 (실행 전)
COLUMN tablespace_name FORMAT A22
SELECT TABLESPACE_NAME,
       ROUND(SUM(BYTES_USED)/1024/1024) USED_MB,
       ROUND(SUM(BYTES_FREE)/1024/1024) FREE_MB
  FROM V$TEMP_SPACE_HEADER
 GROUP BY TABLESPACE_NAME
 ORDER BY TABLESPACE_NAME;


-- ----------------------------------------------------------------------------
-- [3] 세션 작업 영역 축소  (인스턴스는 건드리지 않는다)
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> [설정] 세션 작업 영역을 수동(MANUAL)으로 전환하고 크기를 줄인다
ALTER SESSION SET WORKAREA_SIZE_POLICY = MANUAL;
ALTER SESSION SET SORT_AREA_SIZE = &wl_sort_area;
ALTER SESSION SET SORT_AREA_RETAINED_SIZE = &wl_sort_area;
ALTER SESSION SET HASH_AREA_SIZE = &wl_hash_area;


-- ----------------------------------------------------------------------------
-- [4] 부하 실행 + 구획별 전후 지표 델타 출력
-- ----------------------------------------------------------------------------
DECLARE
    TYPE t_map IS TABLE OF NUMBER INDEX BY VARCHAR2(120);

    v_s0  t_map;   -- 시작
    v_s1  t_map;   -- 구획 1 직후
    v_s2  t_map;   -- 구획 2 직후
    v_s3  t_map;   -- 구획 3 직후 (= 최종)

    v_n    NUMBER;
    v_n2   NUMBER;
    v_t    NUMBER;
    v_el1  NUMBER := 0;
    v_el2  NUMBER := 0;
    v_el3  NUMBER := 0;

    PROCEDURE p_snap(p_m OUT t_map) IS
    BEGIN
        p_m.DELETE;
        FOR r IN (
            SELECT '01 [SESS] ' || sn.NAME AS k, ms.VALUE AS v
              FROM V$MYSTAT ms, V$STATNAME sn
             WHERE ms.STATISTIC# = sn.STATISTIC#
               AND sn.NAME IN ('sorts (memory)','sorts (disk)','sorts (rows)',
                               'physical writes direct temporary tablespace',
                               'physical reads direct temporary tablespace',
                               'session pga memory','session pga memory max',
                               'session logical reads','physical reads')
            UNION ALL
            SELECT '02 [INST] ' || NAME, VALUE
              FROM V$SYSSTAT
             WHERE NAME IN ('sorts (memory)','sorts (disk)','sorts (rows)',
                            'physical writes direct temporary tablespace',
                            'physical reads direct temporary tablespace',
                            'workarea executions - optimal',
                            'workarea executions - onepass',
                            'workarea executions - multipass')
            UNION ALL
            SELECT '03 [SESS] ' || EVENT || '  (대기횟수)', TOTAL_WAITS
              FROM V$SESSION_EVENT
             WHERE SID = SYS_CONTEXT('USERENV','SID')
               AND EVENT IN ('direct path write temp','direct path read temp',
                             'db file scattered read','db file sequential read',
                             'direct path read')
            UNION ALL
            SELECT '04 [SESS] ' || EVENT || '  (대기ms)', ROUND(TIME_WAITED_MICRO/1000)
              FROM V$SESSION_EVENT
             WHERE SID = SYS_CONTEXT('USERENV','SID')
               AND EVENT IN ('direct path write temp','direct path read temp',
                             'db file scattered read','db file sequential read',
                             'direct path read')
            UNION ALL
            SELECT '05 [PGA ] ' || NAME, VALUE
              FROM V$PGASTAT
             WHERE NAME IN ('over allocation count','extra bytes read/written',
                            'total PGA allocated','maximum PGA allocated')
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
    DBMS_OUTPUT.PUT_LINE('[WL_03] 세션 작업 영역 : SORT=' || &wl_sort_area ||
                         ' bytes, HASH=' || &wl_hash_area || ' bytes');

    p_snap(v_s0);
    v_s1 := v_s0;
    v_s2 := v_s0;
    v_s3 := v_s0;

    --------------------------------------------------------------------------
    -- 구획 1 : 대량 정렬 (WINDOW SORT)
    --   ROW_NUMBER() OVER (ORDER BY ...) 는 옵티마이저가 제거할 수 없는 정렬이다.
    --   단순 ORDER BY 는 상위에서 COUNT(*) 만 세면 제거될 수 있어 쓰지 않는다.
    --------------------------------------------------------------------------
    IF &wl_run_sort = 1 THEN
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('>>> 구획 1 : 대량 정렬(WINDOW SORT) 시작');
        v_t := DBMS_UTILITY.GET_TIME;

        SELECT /* WL03_SORT */ COUNT(*)
          INTO v_n
          FROM ( SELECT ROW_NUMBER() OVER (ORDER BY d.AMT, d.UNIT_PRICE, d.DETAIL_ID) rn
                   FROM CLAIM_DETAILS d
                  WHERE MOD(d.DETAIL_ID, &wl_div) = 0 );

        v_el1 := (DBMS_UTILITY.GET_TIME - v_t) / 100;
        DBMS_OUTPUT.PUT_LINE('    정렬 대상 ' || v_n || ' 행, ' || v_el1 || ' 초');
        p_snap(v_s1);
    ELSE
        DBMS_OUTPUT.PUT_LINE('>>> 구획 1 건너뜀');
        v_s1 := v_s0;
    END IF;

    --------------------------------------------------------------------------
    -- 구획 2 : 대량 해시 조인
    --   CLAIM_DETAILS(100만) x MEDICAL_CLAIMS(30만) 을 CLAIM_ID 로 조인한다.
    --   이 스키마에는 CLAIM_DETAILS.CLAIM_ID 인덱스가 없으므로 원래도 해시 조인이
    --   자연스러운 형태다. HASH_AREA_SIZE 가 작아 빌드 테이블이 디스크로 넘어간다.
    --------------------------------------------------------------------------
    IF &wl_run_hash = 1 THEN
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('>>> 구획 2 : 대량 해시 조인 시작');
        v_t := DBMS_UTILITY.GET_TIME;

        SELECT /*+ LEADING(c d) USE_HASH(d) FULL(c) FULL(d)
                   NO_PARALLEL(c) NO_PARALLEL(d) */
               /* WL03_HASH */
               COUNT(*), SUM(d.AMT)
          INTO v_n, v_n2
          FROM MEDICAL_CLAIMS c, CLAIM_DETAILS d
         WHERE c.CLAIM_ID = d.CLAIM_ID
           AND MOD(d.DETAIL_ID, &wl_div) = 0;

        v_el2 := (DBMS_UTILITY.GET_TIME - v_t) / 100;
        DBMS_OUTPUT.PUT_LINE('    해시 조인 완료 : ' || v_el2 || ' 초');
        p_snap(v_s2);
    ELSE
        DBMS_OUTPUT.PUT_LINE('>>> 구획 2 건너뜀');
        v_s2 := v_s1;
    END IF;

    --------------------------------------------------------------------------
    -- 구획 3 : 대량 그룹핑 + 정렬
    --   CLAIM_ID + DRUG_CODE 조합은 카디널리티가 매우 높아(수십만 그룹)
    --   그룹 결과 자체가 작업 영역을 넘어선다.
    --------------------------------------------------------------------------
    IF &wl_run_group = 1 THEN
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('>>> 구획 3 : 대량 그룹핑 시작');
        v_t := DBMS_UTILITY.GET_TIME;

        SELECT /* WL03_GROUP */ COUNT(*)
          INTO v_n
          FROM ( SELECT d.CLAIM_ID, d.DRUG_CODE, SUM(d.AMT) s, COUNT(*) c
                   FROM CLAIM_DETAILS d
                  WHERE MOD(d.DETAIL_ID, &wl_div) = 0
                  GROUP BY d.CLAIM_ID, d.DRUG_CODE
                  ORDER BY 3 DESC );

        v_el3 := (DBMS_UTILITY.GET_TIME - v_t) / 100;
        DBMS_OUTPUT.PUT_LINE('    그룹 수 ' || v_n || ' 개, ' || v_el3 || ' 초');
        p_snap(v_s3);
    ELSE
        DBMS_OUTPUT.PUT_LINE('>>> 구획 3 건너뜀');
        v_s3 := v_s2;
    END IF;

    --------------------------------------------------------------------------
    -- 델타 리포트
    --------------------------------------------------------------------------
    IF &wl_run_sort = 1 THEN
        p_head('[구획 1] 대량 정렬(WINDOW SORT) - 전후 델타');
        p_diff(v_s0, v_s1);
    END IF;
    IF &wl_run_hash = 1 THEN
        p_head('[구획 2] 대량 해시 조인 - 전후 델타');
        p_diff(v_s1, v_s2);
    END IF;
    IF &wl_run_group = 1 THEN
        p_head('[구획 3] 대량 그룹핑 - 전후 델타');
        p_diff(v_s2, v_s3);
    END IF;

    p_head('[전체] 구획 1~3 합산 - 전후 델타');
    p_diff(v_s0, v_s3);

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('### 판정 포인트 ###');
    DBMS_OUTPUT.PUT_LINE('  1) [SESS] sorts (disk) 델타가 0 보다 커야 재현 성공이다.');
    DBMS_OUTPUT.PUT_LINE('     0 이면 작업 영역이 아직 넉넉하다는 뜻이므로');
    DBMS_OUTPUT.PUT_LINE('     wl_sort_area / wl_hash_area 를 더 줄여 재실행한다.');
    DBMS_OUTPUT.PUT_LINE('  2) physical writes/reads direct temporary tablespace 델타가');
    DBMS_OUTPUT.PUT_LINE('     곧 임시 테이블스페이스로 나간 데이터 양이다.');
    DBMS_OUTPUT.PUT_LINE('     direct path write temp / read temp 대기와 짝을 이룬다.');
    DBMS_OUTPUT.PUT_LINE('  3) [주의] workarea executions - onepass/multipass 통계는');
    DBMS_OUTPUT.PUT_LINE('     WORKAREA_SIZE_POLICY=AUTO 인 작업 영역만 집계한다.');
    DBMS_OUTPUT.PUT_LINE('     지금은 MANUAL 이므로 이 값이 안 늘 수 있다. 그때는');
    DBMS_OUTPUT.PUT_LINE('     sorts (disk) 와 temp 사용량으로 판정하고,');
    DBMS_OUTPUT.PUT_LINE('     pass 수를 직접 보려면 아래 [5]절 V$SQL_WORKAREA 를 본다.');
    DBMS_OUTPUT.PUT_LINE('  4) 경과 시간 : 정렬 ' || v_el1 || '초 / 해시 ' || v_el2 ||
                         '초 / 그룹핑 ' || v_el3 || '초');
END;
/


-- ----------------------------------------------------------------------------
-- [5] 실행 후 관찰
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> [실행 후] 이번 부하 SQL 의 작업 영역 처리 결과 (pass 수 확인)
COLUMN operation_type FORMAT A18
COLUMN policy         FORMAT A8
COLUMN sql_text       FORMAT A34
SELECT SUBSTR(s.SQL_TEXT,1,34) sql_text,
       w.OPERATION_TYPE,
       w.POLICY,
       w.OPTIMAL_EXECUTIONS   AS OPT,
       w.ONEPASS_EXECUTIONS   AS ONEPASS,
       w.MULTIPASSES_EXECUTIONS AS MULTIPASS,
       ROUND(w.LAST_MEMORY_USED/1024)      AS LAST_MEM_KB,
       ROUND(w.LAST_TEMPSEG_SIZE/1024/1024) AS LAST_TEMP_MB
  FROM V$SQL_WORKAREA w, V$SQL s
 WHERE w.SQL_ID = s.SQL_ID
   AND w.CHILD_NUMBER = s.CHILD_NUMBER
   AND s.SQL_TEXT LIKE '%WL03_%'
   AND s.SQL_TEXT NOT LIKE '%V$SQL_WORKAREA%'
 ORDER BY w.LAST_TEMPSEG_SIZE DESC NULLS LAST
 FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT >>> [실행 후] V$PGASTAT  (실행 전 값과 비교할 것)
COLUMN pga_name FORMAT A44
SELECT NAME pga_name, VALUE, UNIT
  FROM V$PGASTAT
 WHERE NAME IN ('aggregate PGA target parameter','total PGA allocated',
                'maximum PGA allocated','over allocation count',
                'cache hit percentage','extra bytes read/written',
                'total PGA used for auto workareas')
 ORDER BY NAME;

PROMPT
PROMPT >>> [실행 후] 임시 테이블스페이스 사용량  (실행 전 값과 비교할 것)
SELECT TABLESPACE_NAME,
       ROUND(SUM(BYTES_USED)/1024/1024) USED_MB,
       ROUND(SUM(BYTES_FREE)/1024/1024) FREE_MB
  FROM V$TEMP_SPACE_HEADER
 GROUP BY TABLESPACE_NAME
 ORDER BY TABLESPACE_NAME;

PROMPT
PROMPT >>> [실행 후] 남아 있는 임시 세그먼트 사용 세션 (정상이면 0건)
COLUMN username FORMAT A16
COLUMN segtype  FORMAT A12
SELECT USERNAME, SESSION_ADDR, SESSION_NUM, SQL_ID, SEGTYPE,
       BLOCKS, ROUND(BLOCKS * 8 / 1024) APPROX_MB
  FROM V$TEMPSEG_USAGE
 ORDER BY BLOCKS DESC;

PROMPT
PROMPT >>> [실행 후] PGA 어드바이저 - 목표 크기별 예상 효과 (19장)
SELECT PGA_TARGET_FOR_ESTIMATE/1024/1024 AS TARGET_MB,
       PGA_TARGET_FACTOR              AS FACTOR,
       ESTD_PGA_CACHE_HIT_PERCENTAGE  AS ESTD_HIT_PCT,
       ESTD_OVERALLOC_COUNT           AS ESTD_OVERALLOC
  FROM V$PGA_TARGET_ADVICE
 ORDER BY PGA_TARGET_FOR_ESTIMATE;


-- ----------------------------------------------------------------------------
-- [6] 되돌리기 - 세션 작업 영역 정책 원복
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> [되돌리기] 세션 작업 영역 정책을 기본값(AUTO)으로 원복
ALTER SESSION SET WORKAREA_SIZE_POLICY = AUTO;

PROMPT >>> [되돌리기 확인] 세션 파라미터 현재값
SELECT NAME, VALUE
  FROM V$PARAMETER
 WHERE NAME IN ('workarea_size_policy','sort_area_size','hash_area_size')
 ORDER BY NAME;

PROMPT
PROMPT ============================================================
PROMPT  WL_03 완료.
PROMPT   - 생성한 영구 객체 없음(삭제할 것 없음).
PROMPT   - 원본 테이블은 읽기만 했다. 데이터 변경 없음.
PROMPT   - 인스턴스 파라미터는 변경하지 않았으므로 원복 대상이 없다.
PROMPT   - 세션 WORKAREA_SIZE_POLICY 는 AUTO 로 되돌렸다.
PROMPT   - 19장 대조 실습 : wl_sort_area 를 262144 / 1048576 / 33554432 로
PROMPT     바꿔가며 3회 실행하고 sorts(disk) 와 경과 시간을 표로 정리한다.
PROMPT ============================================================
SET TIMING OFF
