-- ============================================================================
-- EX_03_사건재현.sql  :  문제 3 의 "오후에 느렸다" 사건을 지금 다시 일으킨다
-- DBTUNING 중간 평가(ch01~ch20) 공용 스크립트 (5/6)
-- ============================================================================
-- 목적       : 신고는 "느렸다" 한 줄뿐이고 SQL 도 시각도 주어지지 않은 상황을
--              만든다. 응시자는 이 스크립트를 실행하기 전에 평시 기준선을 잡고,
--              실행 후 델타만으로 (1) DB Time 이 어디로 갔는지 (2) 어느 대기
--              클래스인지 (3) 원인 SQL 과 세그먼트가 무엇인지를 지목해야 한다.
--
--              이 스크립트는 원인을 알려 주지 않는다. 화면에 찍히는 것은
--              구획 이름과 경과 시간뿐이다. 진단 질의는 응시자가 직접 쓴다.
--
-- 전제       : 1) SQLT 계정 접속(sqlt/sqlt). V$ 뷰 조회 권한.
--              2) @EX_00_환경점검.sql 이 전부 OK.
--              3) 조회 부하만 만든다. 원본 7개 테이블에 DML 이 없다.
--
-- 소요 시간  : 기본값(ex_cycles=8) 기준 약 1~3분.
--              [근거] 구획 1 은 CLAIM_DETAILS(약 6,600블록) 전체 스캔을
--                     주기마다 1회 하므로 주기당 0.3~1초. 구획 2 는 30만 행
--                     정렬이라 주기당 1~3초. 구획 3 은 리터럴 조립이라
--                     주기당 하드 파싱 10회. 8주기면 1~3분이다.
--              [조절] 짧게 : DEFINE ex_cycles = 4
--                     AWR 스냅샷 구간을 넉넉히 덮으려면 : DEFINE ex_cycles = 20
--
-- 관찰 지표  : (응시자가 고른다) V$SYS_TIME_MODEL · V$SYSTEM_WAIT_CLASS ·
--              V$SYSTEM_EVENT · V$SYSSTAT · V$SQL · V$SEGMENT_STATISTICS.
--              전부 누적값이다. 반드시 두 시점의 차이로 읽는다.
--
-- 되돌리기   : 조회 부하뿐이라 데이터는 그대로다. 세션 파라미터는 스크립트가
--              스스로 원복한다. 공유 풀에 쌓인 리터럴 커서는 시간이 지나면
--              밀려 나간다. 즉시 비우려면(개인 환경에서만) :
--                 ALTER SYSTEM FLUSH SHARED_POOL;
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              CPU 와 I/O 를 의도적으로 소모한다. 공유 DB 에서 실행하면 다른
--              세션의 응답시간이 눈에 띄게 나빠진다.
--
-- ---------------------------------------------------------------------------
-- 측정 감싸기 (응시자가 해야 하는 일) :
--      -- 1) 평시 기준선
--      @EX_90_측정보조.sql SNAP P0 -
--      ... 2~3분 평시 상태로 둔다(아무 것도 하지 않는다) ...
--      @EX_90_측정보조.sql SNAP P1 -
--      @EX_90_측정보조.sql DELTA P0 P1      -- 평시 DB Time 구성
--
--      -- 2) 사건 구간
--      @EX_90_측정보조.sql SNAP E0 -
--      @EX_03_사건재현.sql
--      @EX_90_측정보조.sql SNAP E1 -
--      @EX_90_측정보조.sql DELTA E0 E1      -- 사건 DB Time 구성
--
--      AWR 경로를 쓸 경우 SYS 로 접속해 E0 직전과 E1 직후에
--      EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT 을 1회씩 호출한다.
--      (Diagnostics Pack 라이선스가 없으면 Statspack 또는 위 V$ 델타 경로를
--       쓰고, 그 선택의 근거를 답안에 적는다 - ch15 실습 03 · ch20 실습 06)
-- ---------------------------------------------------------------------------
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 200
SET DEFINE ON
SET VERIFY OFF
SET FEEDBACK OFF


-- ----------------------------------------------------------------------------
-- [1] 조절 변수
-- ----------------------------------------------------------------------------
--   ex_cycles : 세 구획을 몇 번 반복할지. 기본 8.
-- ----------------------------------------------------------------------------
SET TERMOUT OFF
COLUMN ex_cycles NEW_VALUE ex_cycles NOPRINT
SELECT NULL ex_cycles FROM dual WHERE 1 = 2;
COLUMN ex_cycles_d NEW_VALUE ex_cycles NOPRINT
SELECT NVL(TRIM('&ex_cycles'), '8') ex_cycles_d FROM dual;
SET TERMOUT ON

PROMPT
PROMPT ============================================================
PROMPT  EX_03 - 사건 재현 (원인은 알려 주지 않는다)
PROMPT    반복 주기(ex_cycles) : &ex_cycles
PROMPT    시작 시각            : 아래 출력 확인
PROMPT ============================================================
SELECT TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') AS "사건_시작" FROM dual;
PROMPT


-- ============================================================================
-- [2] 부하
-- ============================================================================
DECLARE
    v_cycles  PLS_INTEGER := TO_NUMBER('&ex_cycles');
    v_t0      NUMBER;
    v_dummy   NUMBER;
    v_sql     VARCHAR2(1000);
    v_hosp    PLS_INTEGER;
BEGIN
    FOR c IN 1 .. v_cycles LOOP
        v_t0 := DBMS_UTILITY.GET_TIME;

        -- 구획 1
        SELECT /*+ EX03_A */ COUNT(*)
          INTO v_dummy
          FROM claim_details
         WHERE amt > 200000;

        -- 구획 2
        SELECT /*+ EX03_B */ COUNT(*)
          INTO v_dummy
          FROM (SELECT claim_id,
                       ROW_NUMBER() OVER (ORDER BY total_amt DESC, claim_id) rn
                  FROM medical_claims)
         WHERE rn <= 100;

        -- 구획 3
        FOR i IN 1 .. 10 LOOP
            v_hosp := MOD((c - 1) * 10 + i, 1000) + 1;
            v_sql := 'SELECT /* EX03_C */ COUNT(*) FROM medical_claims '
                  || ' WHERE hosp_id = ' || TO_CHAR(v_hosp)
                  || '   AND review_status = ''심사완료''';
            EXECUTE IMMEDIATE v_sql INTO v_dummy;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('  주기 ' || LPAD(c, 2) || ' / ' || v_cycles
            || '   경과 ' || ROUND((DBMS_UTILITY.GET_TIME - v_t0) / 100, 2) || ' 초');
    END LOOP;
END;
/

SELECT TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') AS "사건_종료" FROM dual;

PROMPT
PROMPT ============================================================
PROMPT  사건 재현 끝. 지금부터는 사후 진단이다.
PROMPT
PROMPT   1) E1 을 캡처하고 DELTA E0 E1 을 본다.
PROMPT   2) 평시(DELTA P0 P1)와 사건(DELTA E0 E1)의 DB Time 구성을 나란히 놓는다.
PROMPT   3) 원인 SQL 은 V$SQL 의 "절대값 상위" 가 아니라 "이 구간의 증가분" 으로
PROMPT      찾아야 한다. 두 순위를 모두 제출하고 어느 쪽이 맞는지 근거를 적는다.
PROMPT   4) 원인 세그먼트는 V$SEGMENT_STATISTICS 의 구간 증가분으로 지목한다.
PROMPT
PROMPT  * 이 스크립트는 세 가지 서로 다른 성격의 부하를 섞어 놓았다.
PROMPT    지표 하나만 보고 결론 내리면 셋 중 하나만 맞힌다.
PROMPT ============================================================
SET TIMING OFF
SET FEEDBACK ON
