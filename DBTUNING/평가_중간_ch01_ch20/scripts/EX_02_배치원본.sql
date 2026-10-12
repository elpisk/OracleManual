-- ============================================================================
-- EX_02_배치원본.sql  :  문제 2 의 "느린 야간 배치" 원본 - 고치기 전 상태
-- DBTUNING 중간 평가(ch01~ch20) 공용 스크립트 (4/6)
-- ============================================================================
-- 목적       : 운영에서 돌고 있는 심사 반려 배치를 그대로 재현한다. 이 배치에는
--              애플리케이션 쪽 낭비가 세 가지 들어 있고, 각각 다른 지표로 드러난다.
--              응시자는 이 스크립트를 고치지 않고, 앞뒤로 지표를 캡처해
--              "무엇이 낭비인지" 를 수치로 지목한 뒤 고친 판을 따로 작성한다.
--
--                구획 A : 2,000건 반려 로그 적재
--                구획 B : 청구 20건의 상세 건수 집계
--
-- 전제       : 1) SQLT 계정 접속(sqlt/sqlt). CREATE TABLE 권한 필요.
--              2) cursor_sharing = EXACT (EX_00 에서 확인). FORCE 면 하드 파싱이
--                 재현되지 않는다.
--              3) ★ 원본 7개 테이블에는 DML 을 하지 않는다 ★
--                 복제 테이블 REVIEW_LOG_EX_WL 을 만들어 그 안에서만 INSERT 한다.
--                 REVIEW_LOG / MEDICAL_CLAIMS / CLAIM_DETAILS 는 읽기만 한다.
--
-- 소요 시간  : 기본값(ex_rows=2000, ex_n=20) 기준 약 30초~1분 30초.
--              [근거] 구획 A 는 반복마다 하드 파싱 + 커밋이 붙어 건당 3~15ms,
--                     2,000건이면 6~30초. 구획 B 는 CLAIM_DETAILS(약 6,600블록)
--                     전체 스캔을 20회 하므로 6~20초. CTAS 와 조회를 더했다.
--              [조절] 짧게 : DEFINE ex_rows = 500 / DEFINE ex_n = 10
--                     크게 : DEFINE ex_rows = 5000 / DEFINE ex_n = 40
--
-- 관찰 지표  : parse count (hard) / parse count (total) / execute count
--              user commits / redo size / redo synch writes / log file sync
--              session logical reads / V$LIBRARYCACHE(SQL AREA)
--              V$SQL 의 리터럴 커서 수. 지표 캡처는 EX_90 이 담당한다.
--
-- 되돌리기   : @EX_99_원복확인.sql 이 REVIEW_LOG_EX_WL 을 지운다.
--              직접 지우려면 :  DROP TABLE REVIEW_LOG_EX_WL PURGE;
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              건당 커밋 2,000회는 리두를 만들고 공유 풀에 리터럴 커서를
--              2,000개 이상 쌓는다. 공유 DB 에서 실행하면 다른 세션의 커서가
--              밀려 나간다(ch16 · ch17 라이브러리 캐시 경합).
--
-- ---------------------------------------------------------------------------
-- 측정 감싸기 (응시자가 해야 하는 일) :
--      @EX_90_측정보조.sql SNAP  B0 -
--      @EX_02_배치원본.sql
--      @EX_90_측정보조.sql SNAP  B1 -
--      @EX_90_측정보조.sql DELTA B0 B1
-- ---------------------------------------------------------------------------
-- ============================================================================

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
--   ex_rows : 구획 A 가 적재할 반려 로그 건수(= 커밋 횟수). 기본 2000.
--   ex_n    : 구획 B 가 상세를 조회할 청구 건수(= 반복 횟수). 기본 20.
-- ----------------------------------------------------------------------------
SET TERMOUT OFF
COLUMN ex_rows NEW_VALUE ex_rows NOPRINT
COLUMN ex_n    NEW_VALUE ex_n    NOPRINT
SELECT NULL ex_rows, NULL ex_n FROM dual WHERE 1 = 2;
COLUMN ex_rows_d NEW_VALUE ex_rows NOPRINT
COLUMN ex_n_d    NEW_VALUE ex_n    NOPRINT
SELECT NVL(TRIM('&ex_rows'), '2000') ex_rows_d,
       NVL(TRIM('&ex_n'),    '20')   ex_n_d
  FROM dual;
SET TERMOUT ON

PROMPT
PROMPT ============================================================
PROMPT  EX_02 - 야간 심사 반려 배치 (원본, 고치기 전)
PROMPT    구획 A 적재 건수(ex_rows) : &ex_rows
PROMPT    구획 B 반복 횟수(ex_n)    : &ex_n
PROMPT ============================================================
PROMPT


-- ----------------------------------------------------------------------------
-- [2] 복제 테이블 준비  (원본 REVIEW_LOG 은 읽기 대상으로만 쓴다)
-- ----------------------------------------------------------------------------
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'REVIEW_LOG_EX_WL';
    IF v_cnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE REVIEW_LOG_EX_WL PURGE';
        DBMS_OUTPUT.PUT_LINE('[준비] 기존 REVIEW_LOG_EX_WL 을 지웠다.');
    END IF;

    EXECUTE IMMEDIATE '
        CREATE TABLE REVIEW_LOG_EX_WL (
            log_id       NUMBER(15)   NOT NULL,
            claim_id     VARCHAR2(20),
            reviewer_id  VARCHAR2(20),
            process_date DATE DEFAULT SYSDATE,
            action_msg   VARCHAR2(500),
            error_code   VARCHAR2(10),
            CONSTRAINT pk_review_log_ex_wl PRIMARY KEY (log_id)
        )';
    DBMS_OUTPUT.PUT_LINE('[준비] REVIEW_LOG_EX_WL 생성 완료(빈 테이블).');
END;
/


-- ============================================================================
-- [3] 구획 A  -  반려 로그 적재
--     운영 배치가 이렇게 돌고 있다. 두 가지가 섞여 있으니 지표로 가려내야 한다.
-- ============================================================================
PROMPT >>> [구획 A] 반려 로그 &ex_rows 건 적재 시작
DECLARE
    v_claim VARCHAR2(20);
    v_sql   VARCHAR2(1000);
    v_id    NUMBER := 0;
    v_t0    NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
    FOR r IN (SELECT claim_id
                FROM medical_claims
               WHERE review_status = '심사중'
                 AND ROWNUM <= &ex_rows) LOOP

        v_claim := r.claim_id;
        v_id    := v_id + 1;

        -- 운영 코드 그대로 : 값을 SQL 문장에 직접 이어 붙인다
        v_sql := 'INSERT INTO REVIEW_LOG_EX_WL '
              || '(log_id, claim_id, reviewer_id, process_date, action_msg, error_code) '
              || 'VALUES ('
              || TO_CHAR(v_id) || ', '
              || '''' || v_claim || ''', '
              || '''SYSTEM'', '
              || 'SYSDATE, '
              || '''자동 심사 반려 - ' || v_claim || ''', '
              || '''E' || TO_CHAR(10 + MOD(v_id, 89)) || ''')';

        EXECUTE IMMEDIATE v_sql;
        COMMIT;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('[구획 A] 완료. 경과 '
        || ROUND((DBMS_UTILITY.GET_TIME - v_t0) / 100, 2) || ' 초');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[구획 A] 중단: ' || SQLERRM);
        RAISE;
END;
/

PROMPT >>> [구획 A] 적재 결과
SELECT COUNT(*) AS "적재_건수", COUNT(DISTINCT error_code) AS "오류코드_종류"
  FROM review_log_ex_wl;


-- ============================================================================
-- [4] 구획 B  -  청구 &ex_n 건의 상세 건수 집계
--     화면 목록을 그리는 코드가 이 모양이다.
-- ============================================================================
PROMPT
PROMPT >>> [구획 B] 청구 &ex_n 건에 대해 상세 건수 조회 시작
DECLARE
    v_cnt   NUMBER;
    v_sum   NUMBER := 0;
    v_t0    NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
    -- 먼저 목록을 뽑고
    FOR r IN (SELECT claim_id
                FROM medical_claims
               WHERE receipt_date >= DATE '2024-06-01'
                 AND receipt_date <  DATE '2024-06-02'
                 AND ROWNUM <= &ex_n) LOOP

        -- 목록의 건마다 상세를 다시 조회한다
        SELECT /*+ EX02_DETAIL */ COUNT(*)
          INTO v_cnt
          FROM claim_details
         WHERE claim_id = r.claim_id;

        v_sum := v_sum + v_cnt;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('[구획 B] 완료. 상세 합계 ' || v_sum
        || ' 건, 경과 ' || ROUND((DBMS_UTILITY.GET_TIME - v_t0) / 100, 2) || ' 초');
END;
/


-- ----------------------------------------------------------------------------
-- [5] 배치가 남긴 흔적 (해석은 응시자가 한다)
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> 공유 풀에 쌓인 이 배치의 커서
COLUMN sql_text FORMAT A74
SELECT COUNT(*)                       AS "커서_개수",
       SUM(executions)                AS "총_실행횟수",
       ROUND(AVG(executions), 2)      AS "커서당_평균_실행",
       SUM(parse_calls)               AS "파싱_호출",
       ROUND(SUM(sharable_mem)/1024)  AS "공유풀_KB"
  FROM v$sql
 WHERE sql_text LIKE 'INSERT INTO REVIEW_LOG_EX_WL%';

PROMPT >>> 같은 모양의 커서 세 개만 눈으로 확인
SELECT sql_id, executions, SUBSTR(sql_text, 1, 74) sql_text
  FROM v$sql
 WHERE sql_text LIKE 'INSERT INTO REVIEW_LOG_EX_WL%'
 ORDER BY first_load_time
 FETCH FIRST 3 ROWS ONLY;

PROMPT >>> 구획 B 의 상세 조회 커서 (실행당 논리 읽기를 본다)
SELECT sql_id, executions, buffer_gets,
       ROUND(buffer_gets / DECODE(executions, 0, 1, executions)) AS "실행당_논리읽기"
  FROM v$sql
 WHERE sql_text LIKE '%EX02_DETAIL%'
   AND sql_text NOT LIKE '%v$sql%';

PROMPT >>> 라이브러리 캐시 (SQL AREA)
SELECT namespace, gets, gethits,
       ROUND(gethitratio * 100, 2) AS "GET_히트율",
       pins, reloads, invalidations
  FROM v$librarycache
 WHERE namespace = 'SQL AREA';

PROMPT
PROMPT ============================================================
PROMPT  배치 실행 끝. 이제 EX_90 으로 B1 을 캡처하고 델타를 본다.
PROMPT  답안지 2-(1) 에 지표 이름과 델타 값을 적는다.
PROMPT  복제 테이블은 @EX_99_원복확인.sql 로 정리한다.
PROMPT ============================================================
SET TIMING OFF
