-- ============================================================================
-- EX_01_대상SQL.sql  :  문제 1 의 대상 SQL 두 개를 "있는 그대로" 실행해 베이스라인을 잡는다
-- DBTUNING 중간 평가(ch01~ch20) 공용 스크립트 (3/6)
-- ============================================================================
-- 목적       : 운영에서 신고된 느린 SQL 두 개를 손대지 않은 상태로 실행하고,
--              실행 통계가 붙은 실행계획을 함께 출력한다. 이 출력이 문제 1 의
--              "조치 전" 근거다. 응시자는 이 스크립트를 고치지 않는다 -
--              고친 SQL 은 자신의 답안 파일에 따로 적어 실행한다.
--
-- 전제       : 1) SQLT 계정 접속(sqlt/sqlt). @EX_00_환경점검.sql 이 전부 OK.
--              2) 인덱스는 PK 7개뿐인 상태. 히스토그램은 MEDICAL_CLAIMS.HOSP_ID 하나.
--              3) 조회만 한다. 원본 7개 테이블을 바꾸지 않는다.
--
-- 소요 시간  : 약 20초~1분 (두 SQL 모두 MEDICAL_CLAIMS 전체 스캔이 섞여 있다).
--
-- 관찰 지표  : A-Rows / Buffers / A-Time / Starts, OMem·1Mem·Used-Mem(정렬),
--              Predicate Information 의 access / filter 구분,
--              E-Rows 와 A-Rows 의 차이(추정 오류).
--
-- 되돌리기   : 없다(조회 전용).
--
-- 주의       : ★ 리터럴로 측정한다 ★  바인드 변수로 바꿔 측정하면 적응형 커서
--              공유(ACS)가 끼어들어 첫 실행의 계획이 달라질 수 있다
--              (ch08 실습 02 에서 실측으로 확인한 사실). 베이스라인은 리터럴로 잡는다.
--              같은 이유로 각 SQL 을 두 번 실행해 두 번째 값을 쓴다
--              (첫 실행은 콜드 캐시라 Reads 가 섞인다 - ch04 실습 01).
-- ============================================================================

SET LINESIZE 200
SET PAGESIZE 1000
SET SERVEROUTPUT OFF
SET TIMING ON
SET FEEDBACK ON
SET VERIFY OFF
ALTER SESSION SET statistics_level = TYPICAL;

PROMPT
PROMPT ============================================================
PROMPT  문제 1 대상 SQL - 조치 전 베이스라인
PROMPT ============================================================


-- ----------------------------------------------------------------------------
-- [Q1] 심사 화면 : "서울 지역 요양기관의 2024년 6월 청구 목록" 최신순, 50번째 페이지
--      신고 내용 : "페이지를 뒤로 넘길수록 느려진다. 1페이지는 참을 만한데
--                   50페이지는 체감이 다르다."
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> [Q1] 1회차 (캐시 적재용 - 이 값은 쓰지 않는다)
SELECT *
  FROM (SELECT ROWNUM rn, x.*
          FROM (SELECT c.claim_id, c.receipt_date, c.total_amt, h.hosp_name
                  FROM medical_claims c, hospitals h
                 WHERE c.hosp_id = h.hosp_id
                   AND TO_CHAR(c.receipt_date, 'YYYYMM') = '202406'
                   AND h.city = '서울'
                 ORDER BY c.receipt_date DESC, c.claim_id DESC) x
         WHERE ROWNUM <= 1000)
 WHERE rn > 980;

PROMPT
PROMPT >>> [Q1] 2회차 - 이 실행의 통계를 베이스라인으로 쓴다
SELECT /*+ GATHER_PLAN_STATISTICS EX01_Q1 */ *
  FROM (SELECT ROWNUM rn, x.*
          FROM (SELECT c.claim_id, c.receipt_date, c.total_amt, h.hosp_name
                  FROM medical_claims c, hospitals h
                 WHERE c.hosp_id = h.hosp_id
                   AND TO_CHAR(c.receipt_date, 'YYYYMM') = '202406'
                   AND h.city = '서울'
                 ORDER BY c.receipt_date DESC, c.claim_id DESC) x
         WHERE ROWNUM <= 1000)
 WHERE rn > 980;

PROMPT
PROMPT >>> [Q1] 실행계획 + 실행 통계
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST +PREDICATE'));


-- ----------------------------------------------------------------------------
-- [Q2] 정산 보고 : "2024년 6월 접수분 중 금액 상위 20건"
--      신고 내용 : "한 달치만 보는데 왜 전체를 읽는지 모르겠다. 인덱스를 만들면
--                   빨라지느냐고 개발팀이 묻는다."
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> [Q2] 1회차 (캐시 적재용)
SELECT c.claim_id, c.receipt_date, c.total_amt
  FROM medical_claims c
 WHERE c.receipt_date >= DATE '2024-06-01'
   AND c.receipt_date <  DATE '2024-07-01'
 ORDER BY c.total_amt DESC
 FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT >>> [Q2] 2회차 - 베이스라인
SELECT /*+ GATHER_PLAN_STATISTICS EX01_Q2 */ c.claim_id, c.receipt_date, c.total_amt
  FROM medical_claims c
 WHERE c.receipt_date >= DATE '2024-06-01'
   AND c.receipt_date <  DATE '2024-07-01'
 ORDER BY c.total_amt DESC
 FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT >>> [Q2] 실행계획 + 실행 통계
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST +PREDICATE'));


-- ----------------------------------------------------------------------------
-- [참고] 판단에 필요한 사실만 뽑아 둔다 (해석은 응시자가 한다)
-- ----------------------------------------------------------------------------
PROMPT
PROMPT >>> 표 크기와 통계 (ch05 - Full Scan 비용은 테이블 크기가 정한다)
COLUMN table_name FORMAT A16
SELECT table_name, num_rows, blocks, avg_row_len,
       TO_CHAR(last_analyzed, 'YYYY-MM-DD HH24:MI') last_analyzed
  FROM user_tables
 WHERE table_name IN ('MEDICAL_CLAIMS', 'HOSPITALS')
 ORDER BY table_name;

PROMPT
PROMPT >>> Q1·Q2 조건의 실제 선택도 (ch05 - 교차점 판단 근거)
SELECT (SELECT COUNT(*) FROM medical_claims)                             AS "전체",
       (SELECT COUNT(*) FROM medical_claims
         WHERE receipt_date >= DATE '2024-06-01'
           AND receipt_date <  DATE '2024-07-01')                        AS "6월_건수",
       (SELECT COUNT(*) FROM medical_claims c, hospitals h
         WHERE c.hosp_id = h.hosp_id AND h.city = '서울'
           AND c.receipt_date >= DATE '2024-06-01'
           AND c.receipt_date <  DATE '2024-07-01')                      AS "6월_서울",
       (SELECT COUNT(*) FROM hospitals WHERE city = '서울')               AS "서울_기관수"
  FROM dual;

PROMPT
PROMPT >>> 현재 인덱스 (조치 전 - PK 7개뿐이어야 한다)
COLUMN index_name FORMAT A20
SELECT table_name, index_name, uniqueness FROM user_indexes ORDER BY table_name;

PROMPT
PROMPT ============================================================
PROMPT  베이스라인 캡처 끝. 답안지 1-(1) 에 Q1·Q2 의
PROMPT  A-Rows / Buffers / A-Time / Used-Mem 을 적는다.
PROMPT  SPOOL 로 이 출력을 파일로 남겨 제출물에 포함시킨다.
PROMPT ============================================================
SET TIMING OFF
