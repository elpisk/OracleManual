-- ============================================================================
--  진료비 청구 및 심사 시스템 - 스키마 · 대량 데이터 생성 스크립트 (실행용)
-- ============================================================================
--  출처 : 진료비청구심사_스키마_생성스크립트_수정본.md 의 「수정된 전체 스크립트」
--         (원본 PDF 스크립트를 검토해 찾은 9건을 반영한 판)
--  용도 : SQL 튜닝 / SQL 고급활용 실습 스키마를 빈 계정에 한 번에 만든다.
--         진료비청구심사_실습문제_50제 · SQL고급활용_문제_50제 가 쓰는 표들이다.
--
--  실행 방법
--      $ sqlplus 실습계정/비밀번호@orcl @진료비청구심사_스키마_생성.sql
--      SQL Developer 라면 F5(스크립트 실행). F9(문장 실행)로는 돌아가지 않는다.
--
--  필요 권한 : CREATE TABLE, CREATE SEQUENCE, 테이블스페이스 QUOTA
--              (CONNECT + RESOURCE 롤이면 충분하다)
--
--  실측 (19.3.0.0 / OEL7 / 문서 기준 전량, 2026-09-30)
--      전체          1분 51초
--        1단계(마스터 6.1만 건)      1.92 초
--        2단계(청구 30만 건 루프)  1분 42.76 초   <- 대부분이 여기다
--        3단계(로그 50만 건)         3.72 초
--        통계 수집 7개               1.6 초
--      세그먼트 총 179.1 MB (표 134 MB + 인덱스 45 MB)
--      -> 테이블스페이스 여유를 200 MB 이상 확보하고 시작한다.
--      장비가 느리면 2단계가 길어진다. 아래 DEFINE 을 줄여 소량으로 한 번
--      돌려 확인한 뒤 전량을 실행하는 것을 권한다.
--
--  !! 주의 : 0단계에서 표 7개와 시퀀스 2개를 PURGE 로 DROP 한다.
--            같은 이름의 표가 이미 있는 계정에서 돌리면 그 데이터는 사라진다.
--            SYS / SYSTEM 으로는 실행되지 않도록 앞에서 막아 두었다.
--
--  주석 표기
--      [수정 N]    .md 「발견된 문제점」 표의 N 번 항목 (생성 로직 자체의 수정)
--      [실행 보완] .md 에는 없으나 그대로 실행하려면 필요한 부분
-- ============================================================================

SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE     180
SET PAGESIZE     5000
SET TRIMSPOOL    ON
SET VERIFY       OFF
SET TIMING       ON
SET DEFINE       ON
SET SQLBLANKLINES ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
WHENEVER OSERROR  EXIT FAILURE

SPOOL claim_schema_build.log

-- ---------------------------------------------------------------------------
-- [실행 보완] 생성 건수. 소량 시험 실행은 이 값들만 줄이면 된다.
--   문서 기준 전량 :  1000 / 50000 / 10000 / 300000 / 300000 / 200000
--   빠른 확인용 예 :    50 /  2000 /  1000 /   2000 /   2000 /   1000
--
--   n_drug 주의 : .md 코드블록의 루프는 1..20000 이지만, 같은 문서의
--   DBMS_OUTPUT 문구("10,000건 생성 완료")와 「수정 후 기대 결과」표는 10,000
--   이다. 문서 안에서 어긋나 있으므로 값을 여기 한 곳으로 모았다.
--   2만 건이 필요하면 n_drug 만 20000 으로 바꾼다.
--
--   n_claim 주의 : CLAIM_ID 가 LPAD(i,7,'0') 이라 9,999,999 까지만 안전하다.
-- ---------------------------------------------------------------------------
DEFINE n_hosp   = 1000
DEFINE n_pat    = 50000
DEFINE n_drug   = 10000
DEFINE n_claim  = 300000
DEFINE n_log_ok = 300000
DEFINE n_log_ng = 200000

PROMPT
PROMPT ============================================================
PROMPT  0. 실행 계정 확인 및 기존 객체 정리 (재실행 가능)
PROMPT ============================================================

-- [실행 보완] DROP TABLE 9줄이 SYS/SYSTEM 에서 실행되는 사고를 막는다.
BEGIN
    IF USER IN ('SYS', 'SYSTEM') THEN
        RAISE_APPLICATION_ERROR(-20001,
            '이 스크립트는 ' || USER || ' 로 실행할 수 없습니다. 실습 전용 계정으로 접속하십시오.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('실행 계정 : ' || USER);
END;
/

-- [실행 보완] .md 의 DROP TABLE 7줄 · DROP SEQUENCE 2줄은 최초 실행 때
--             ORA-00942 / ORA-02289 로 멈춘다. 없으면 넘어가도록 감쌌다.
--             자식 -> 부모 순서는 .md 와 같다(FK 때문에 순서를 바꿀 수 없다).
DECLARE
    PROCEDURE drop_quietly(p_ddl VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_ddl;
        DBMS_OUTPUT.PUT_LINE(' - ' || p_ddl);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE NOT IN (-942, -2289) THEN RAISE; END IF;
    END;
BEGIN
    drop_quietly('DROP TABLE REVIEW_LOG PURGE');
    drop_quietly('DROP TABLE DISEASES PURGE');
    drop_quietly('DROP TABLE CLAIM_DETAILS PURGE');
    drop_quietly('DROP TABLE MEDICAL_CLAIMS PURGE');
    drop_quietly('DROP TABLE DRUG_MASTER PURGE');
    drop_quietly('DROP TABLE PATIENTS PURGE');
    drop_quietly('DROP TABLE HOSPITALS PURGE');
    drop_quietly('DROP SEQUENCE seq_detail_id');
    drop_quietly('DROP SEQUENCE seq_dis_id');
END;
/

PROMPT
PROMPT ============================================================
PROMPT  1. 테이블 생성
PROMPT ============================================================

CREATE TABLE HOSPITALS (
    HOSP_ID     NUMBER(10)    NOT NULL,
    HOSP_NAME   VARCHAR2(100),
    HOSP_TYPE   VARCHAR2(20),
    CITY        VARCHAR2(50),
    EST_DATE    DATE,
    STATUS      VARCHAR2(10),
    CONSTRAINT PK_HOSPITALS PRIMARY KEY (HOSP_ID)
);

CREATE TABLE PATIENTS (
    PAT_ID      NUMBER(10)   NOT NULL,
    PAT_NAME    VARCHAR2(50),
    GENDER      CHAR(1),
    BIRTH_DATE  VARCHAR2(8),
    CITY        VARCHAR2(50),
    INS_TYPE    VARCHAR2(20),
    PHONE       VARCHAR2(20),
    CONSTRAINT PK_PATIENTS PRIMARY KEY (PAT_ID)
);

CREATE TABLE DRUG_MASTER (
    DRUG_CODE      VARCHAR2(20)  NOT NULL,
    DRUG_NAME      VARCHAR2(200),
    CATEGORY       VARCHAR2(50),
    PRICE          NUMBER(10),
    PHARM_COMPANY  VARCHAR2(100),
    APPLY_DATE     DATE,
    CONSTRAINT PK_DRUG_MASTER PRIMARY KEY (DRUG_CODE)
);

CREATE TABLE MEDICAL_CLAIMS (
    CLAIM_ID       VARCHAR2(20)  NOT NULL,
    HOSP_ID        NUMBER(10)    NOT NULL,
    PAT_ID         NUMBER(10)    NOT NULL,
    RECEIPT_DATE   DATE,
    VISIT_DATE     DATE,
    DEPT_CODE      VARCHAR2(10),
    CLAIM_TYPE     VARCHAR2(20),
    TOTAL_AMT      NUMBER(12),
    REVIEW_STATUS  VARCHAR2(20),
    CONSTRAINT PK_MEDICAL_CLAIMS PRIMARY KEY (CLAIM_ID),
    CONSTRAINT FK_CLAIM_HOSP FOREIGN KEY (HOSP_ID) REFERENCES HOSPITALS(HOSP_ID),
    CONSTRAINT FK_CLAIM_PAT  FOREIGN KEY (PAT_ID)  REFERENCES PATIENTS(PAT_ID)
);

CREATE TABLE CLAIM_DETAILS (
    DETAIL_ID   NUMBER(15)    NOT NULL,
    CLAIM_ID    VARCHAR2(20)  NOT NULL,
    DRUG_CODE   VARCHAR2(20)  NOT NULL,
    QTY         NUMBER(5,2),
    DAYS        NUMBER(3),
    UNIT_PRICE  NUMBER(10),
    AMT         NUMBER(12),
    CONSTRAINT PK_CLAIM_DETAILS PRIMARY KEY (DETAIL_ID),
    CONSTRAINT FK_DETAIL_CLAIM FOREIGN KEY (CLAIM_ID)  REFERENCES MEDICAL_CLAIMS(CLAIM_ID),
    CONSTRAINT FK_DETAIL_DRUG  FOREIGN KEY (DRUG_CODE) REFERENCES DRUG_MASTER(DRUG_CODE)
);

CREATE TABLE DISEASES (
    DIS_SEQ    NUMBER(15)    NOT NULL,
    CLAIM_ID   VARCHAR2(20)  NOT NULL,
    DIS_CODE   VARCHAR2(10),
    DIS_TYPE   CHAR(1),
    CONSTRAINT PK_DISEASES PRIMARY KEY (DIS_SEQ),
    CONSTRAINT FK_DIS_CLAIM FOREIGN KEY (CLAIM_ID) REFERENCES MEDICAL_CLAIMS(CLAIM_ID)
);

CREATE TABLE REVIEW_LOG (
    LOG_ID         NUMBER(15)    NOT NULL,
    CLAIM_ID       VARCHAR2(20),
    REVIEWER_ID    VARCHAR2(20),
    PROCESS_DATE   DATE DEFAULT SYSDATE,
    ACTION_MSG     VARCHAR2(500),
    ERROR_CODE     VARCHAR2(10),
    CONSTRAINT PK_REVIEW_LOG PRIMARY KEY (LOG_ID),                                         -- [수정 1]
    CONSTRAINT FK_LOG_CLAIM  FOREIGN KEY (CLAIM_ID) REFERENCES MEDICAL_CLAIMS(CLAIM_ID)    -- [수정 1]
);

PROMPT
PROMPT ============================================================
PROMPT  2. 1단계: 마스터 데이터 생성 (병원 / 환자 / 약품)
PROMPT ============================================================

DECLARE
    v_cnt NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('1단계: 마스터 데이터 생성을 시작합니다...');

    -- HOSPITALS
    FOR i IN 1..&n_hosp LOOP
        INSERT INTO HOSPITALS (HOSP_ID, HOSP_NAME, HOSP_TYPE, CITY, EST_DATE, STATUS)
        VALUES (
            i,
            '요양기관_' || i,
            CASE WHEN MOD(i, 100) = 0 THEN '상급종합'   -- [수정 4] 약 1%
                 WHEN MOD(i, 20)  = 0 THEN '종합병원'    -- 약 4%
                 WHEN MOD(i, 5)   = 0 THEN '약국'         -- 약 15%
                 ELSE '의원' END,                          -- 약 80%
            CASE WHEN i <= &n_hosp * 0.4 THEN '서울'
                 WHEN i <= &n_hosp * 0.7 THEN '경기'
                 ELSE '부산' END,
            TO_DATE('20000101','YYYYMMDD') + TRUNC(DBMS_RANDOM.VALUE(0, 7000)),
            CASE WHEN MOD(i, 50) = 0 THEN '폐업'          -- [수정 5] 약 2%
                 WHEN MOD(i, 15) = 0 THEN '휴업'          -- 약 6%
                 ELSE '운영' END                           -- 약 92%
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(' - HOSPITALS &n_hosp 건 생성 완료');

    -- PATIENTS
    FOR i IN 1..&n_pat LOOP
        INSERT INTO PATIENTS (PAT_ID, PAT_NAME, GENDER, BIRTH_DATE, CITY, INS_TYPE, PHONE)
        VALUES (
            i,
            DBMS_RANDOM.STRING('U', 3) || DBMS_RANDOM.STRING('L', 4),
            CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.5 THEN 'M' ELSE 'F' END,
            TO_CHAR(TO_DATE('19400101','YYYYMMDD') + TRUNC(DBMS_RANDOM.VALUE(0, 25000)), 'YYYYMMDD'),
            CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.6 THEN '서울' ELSE '기타' END,
            CASE WHEN MOD(i, 100) = 0 THEN '보훈'          -- [수정 6] 약 1%
                 WHEN MOD(i, 10)  = 0 THEN '의료급여'      -- 약 9%
                 ELSE '건강보험' END,                       -- 약 90%
            '010-' || TRUNC(DBMS_RANDOM.VALUE(1000, 9999)) || '-' || TRUNC(DBMS_RANDOM.VALUE(1000, 9999))
        );
        IF MOD(i, 5000) = 0 THEN COMMIT; END IF;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(' - PATIENTS &n_pat 건 생성 완료');

    -- DRUG_MASTER
    FOR i IN 1..&n_drug LOOP
        INSERT INTO DRUG_MASTER (DRUG_CODE, DRUG_NAME, CATEGORY, PRICE, PHARM_COMPANY, APPLY_DATE)
        VALUES (
            'D' || LPAD(i, 9, '0'),
            '약품_' || i,
            CASE WHEN MOD(i, 10) = 0 THEN '주사제'
                 WHEN MOD(i, 3)  = 0 THEN '처치'
                 ELSE '내복약' END,
            TRUNC(DBMS_RANDOM.VALUE(100, 50000)),
            '제약사_' || TRUNC(DBMS_RANDOM.VALUE(1, 100)),
            TO_DATE('20200101','YYYYMMDD') + TRUNC(DBMS_RANDOM.VALUE(0, 1500))  -- [수정 9]
        );
        IF MOD(i, 5000) = 0 THEN COMMIT; END IF;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(' - DRUG_MASTER &n_drug 건 생성 완료');
END;
/

PROMPT
PROMPT ============================================================
PROMPT  3. 시퀀스 생성
PROMPT ============================================================

-- [실행 보완] 기본 CACHE 20 으로 두면 NEXTVAL 을 100 만 회 가까이 부르는 동안
--             딕셔너리 갱신(SEQ$ update)이 5 만 번 일어나 2단계가 크게 느려진다.
--             CACHE 만 키웠을 뿐이므로 만들어지는 데이터는 달라지지 않는다.
CREATE SEQUENCE seq_detail_id CACHE 1000;
CREATE SEQUENCE seq_dis_id    CACHE 1000;

PROMPT
PROMPT ============================================================
PROMPT  4. 2단계: 핵심 트랜잭션 데이터 대량 생성
PROMPT     (청구서 &n_claim 건 / 상세내역 그 3 배 가량 / 상병 1.33 배 가량)
PROMPT     * 가장 오래 걸리는 구간이다. 중간 진행 메시지는 나오지 않는다.
PROMPT ============================================================

DECLARE
    v_claim_id    VARCHAR2(20);
    v_hosp_id     NUMBER;
    v_pat_id      NUMBER;
    v_date        DATE;
    v_detail_cnt  NUMBER;
    v_qty         NUMBER;
    v_days        NUMBER;
    v_unit_price  NUMBER;
    v_line_amt    NUMBER;
    v_total_amt   NUMBER;         -- [수정 2] 청구서별 금액 누적용
BEGIN
    DBMS_OUTPUT.PUT_LINE('2단계: 트랜잭션 데이터 대량 생성을 시작합니다... (시간 소요됨)');

    FOR i IN 1..&n_claim LOOP
        -- 데이터 쏠림(Skew) 생성 로직: 1~50번 병원(대형병원 가정)에 청구의 50%를 몰아줌
        IF DBMS_RANDOM.VALUE(0, 1) < 0.5 THEN
            v_hosp_id := TRUNC(DBMS_RANDOM.VALUE(1, 51));
        ELSE
            v_hosp_id := TRUNC(DBMS_RANDOM.VALUE(51, &n_hosp + 1));
        END IF;

        v_pat_id    := TRUNC(DBMS_RANDOM.VALUE(1, &n_pat + 1));
        v_date      := TO_DATE('20240101','YYYYMMDD') + TRUNC(DBMS_RANDOM.VALUE(0, 366));  -- [수정 7]
        v_claim_id  := TO_CHAR(v_date, 'YYYYMMDD') || '-' || LPAD(i, 7, '0');
        v_total_amt := 0;

        -- [수정 2-a] MEDICAL_CLAIMS(부모)를 먼저 입력한다. TOTAL_AMT는 일단 0(자리표시자) --
        --            CLAIM_DETAILS.CLAIM_ID에 FK_DETAIL_CLAIM 제약이 걸려 있어 부모 행이
        --            먼저 존재해야만 자식(CLAIM_DETAILS)을 넣을 수 있기 때문이다.
        --            (앞선 버전에서 이 순서를 반대로 바꿨다가 ORA-02291 위반이 발생함 - 재수정)
        INSERT INTO MEDICAL_CLAIMS (CLAIM_ID, HOSP_ID, PAT_ID, RECEIPT_DATE, VISIT_DATE,
                                     DEPT_CODE, CLAIM_TYPE, TOTAL_AMT, REVIEW_STATUS)
        VALUES (
            v_claim_id,
            v_hosp_id,
            v_pat_id,
            v_date,
            v_date - TRUNC(DBMS_RANDOM.VALUE(1, 15)),  -- [수정 8] 진료일 = 접수일 1~14일 전
            'D' || TRUNC(DBMS_RANDOM.VALUE(1, 10)),
            CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.8 THEN '입원' ELSE '외래' END,
            0,                                           -- 자리표시자, 아래에서 UPDATE로 채움
            CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.9 THEN '심사중' ELSE '심사완료' END
        );

        -- [수정 2-b] CLAIM_DETAILS(자식)를 생성하며 실제 금액(AMT)을 계산·누적한다.
        v_detail_cnt := TRUNC(DBMS_RANDOM.VALUE(1, 6));  -- 건당 1~5개
        FOR j IN 1..v_detail_cnt LOOP
            v_qty        := TRUNC(DBMS_RANDOM.VALUE(1, 4));       -- 1~3
            v_days       := TRUNC(DBMS_RANDOM.VALUE(1, 10));      -- 1~9
            v_unit_price := TRUNC(DBMS_RANDOM.VALUE(100, 10000)); -- 100~9999
            v_line_amt   := v_unit_price * v_qty * v_days;        -- 0 하드코딩 제거, 실제 계산

            INSERT INTO CLAIM_DETAILS (DETAIL_ID, CLAIM_ID, DRUG_CODE, QTY, DAYS, UNIT_PRICE, AMT)
            VALUES (
                seq_detail_id.NEXTVAL,
                v_claim_id,
                'D' || LPAD(TRUNC(DBMS_RANDOM.VALUE(1, &n_drug + 1)), 9, '0'),
                v_qty, v_days, v_unit_price, v_line_amt
            );

            v_total_amt := v_total_amt + v_line_amt;
        END LOOP;

        -- [수정 2-c] 방금 계산한 합계로 MEDICAL_CLAIMS.TOTAL_AMT를 갱신한다.
        --            (자식 CLAIM_DETAILS가 전부 들어간 "뒤에" 실행해야 합계가 정확하다)
        UPDATE MEDICAL_CLAIMS
        SET    TOTAL_AMT = v_total_amt
        WHERE  CLAIM_ID  = v_claim_id;

        -- [수정 3] DISEASES: 주상병(DIS_TYPE=1)은 항상 1건, 부상병(DIS_TYPE=2)은 약 33% 확률로 추가
        --          -> 평균 1.33건/청구, 30만 청구 기준 총 약 40만 건 (문서상 목표치와 일치)
        INSERT INTO DISEASES (DIS_SEQ, CLAIM_ID, DIS_CODE, DIS_TYPE)
        VALUES (
            seq_dis_id.NEXTVAL,
            v_claim_id,
            CASE WHEN DBMS_RANDOM.VALUE(0,1) > 0.7 THEN 'J00'   -- 감기(흔한 질병) 30%
                 ELSE 'M' || TRUNC(DBMS_RANDOM.VALUE(10, 99)) END,
            '1'
        );
        IF DBMS_RANDOM.VALUE(0, 1) > 0.67 THEN                   -- [수정 3] 약 33% 확률
            INSERT INTO DISEASES (DIS_SEQ, CLAIM_ID, DIS_CODE, DIS_TYPE)
            VALUES (
                seq_dis_id.NEXTVAL,
                v_claim_id,
                'M' || TRUNC(DBMS_RANDOM.VALUE(10, 99)),
                '2'
            );
        END IF;

        IF MOD(i, 5000) = 0 THEN COMMIT; END IF;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(' - 트랜잭션 데이터 생성 완료');
END;
/

PROMPT
PROMPT ============================================================
PROMPT  5. 3단계: 로그 데이터 생성 및 마무리
PROMPT ============================================================

-- [실행 보완] .md 의 'DECLARE / BEGIN' 은 선언부가 비어 PLS-00103 이 난다.
--             선언할 변수가 없으므로 DECLARE 를 뺐다. 본문은 .md 와 같다.
BEGIN
    DBMS_OUTPUT.PUT_LINE('3단계: 로그 데이터 생성 및 마무리...');

    INSERT INTO REVIEW_LOG (LOG_ID, CLAIM_ID, REVIEWER_ID, PROCESS_DATE, ACTION_MSG, ERROR_CODE)
    SELECT
        ROWNUM,
        CLAIM_ID,
        'EMP_' || TRUNC(DBMS_RANDOM.VALUE(100, 200)),
        RECEIPT_DATE + DBMS_RANDOM.VALUE(1, 5),
        '심사 처리 완료',
        NULL
    FROM MEDICAL_CLAIMS
    WHERE ROWNUM <= &n_log_ok;

    INSERT INTO REVIEW_LOG (LOG_ID, CLAIM_ID, REVIEWER_ID, PROCESS_DATE, ACTION_MSG, ERROR_CODE)
    SELECT
        &n_log_ok + ROWNUM,
        CLAIM_ID,
        'SYSTEM',
        RECEIPT_DATE,
        '자동 심사 반려',
        'E' || TRUNC(DBMS_RANDOM.VALUE(10, 99))
    FROM MEDICAL_CLAIMS
    WHERE ROWNUM <= &n_log_ng;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(' - 전체 데이터 생성 완료!');
END;
/

PROMPT
PROMPT ============================================================
PROMPT  6. 통계 수집
PROMPT ============================================================

-- [실행 보완] .md 는 스키마명을 'ALICE' 로 박아 두었다. 다른 계정에서 실행하면
--             ORA-20000(object does not exist) 이 난다. 접속 계정(USER)을 쓴다.
--             1~50번 병원 쏠림을 옵티마이저가 보려면 히스토그램이 필요하므로
--             method_opt 은 기본값(FOR ALL COLUMNS SIZE AUTO)을 그대로 쓴다.
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'HOSPITALS',      cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENTS',       cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'DRUG_MASTER',    cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'MEDICAL_CLAIMS', cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'CLAIM_DETAILS',  cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'DISEASES',       cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'REVIEW_LOG',     cascade => TRUE);

PROMPT
PROMPT ============================================================
PROMPT  7. 데이터 생성 결과 확인
PROMPT ============================================================
SET TIMING OFF

COLUMN TNAME FORMAT A16

PROMPT
PROMPT === 7-1. 테이블별 건수 ===========================================
SELECT 'HOSPITALS' TNAME, COUNT(*) CNT FROM HOSPITALS
UNION ALL
SELECT 'PATIENTS', COUNT(*) FROM PATIENTS
UNION ALL
SELECT 'DRUG_MASTER', COUNT(*) FROM DRUG_MASTER
UNION ALL
SELECT 'MEDICAL_CLAIMS', COUNT(*) FROM MEDICAL_CLAIMS
UNION ALL
SELECT 'CLAIM_DETAILS', COUNT(*) FROM CLAIM_DETAILS
UNION ALL
SELECT 'DISEASES', COUNT(*) FROM DISEASES        -- 수정 후 약 39만~40만 건으로 나와야 정상
UNION ALL
SELECT 'REVIEW_LOG', COUNT(*) FROM REVIEW_LOG;

-- ---------------------------------------------------------------------------
-- [실행 보완] 아래 7-2 ~ 7-9 는 .md 「발견된 문제점」 9건이 실제로 고쳐졌는지
--             데이터로 확인하는 인수 검사다. 원본 스크립트로 만든 스키마라면
--             7-3 의 0원 건수가 전체 건수와 같고, 7-4 에 DIS_TYPE='2' 가 없고,
--             7-5 에 '상급종합'/'휴업'/'폐업' 이 없고, 7-6 에 '보훈' 이 없다.
-- ---------------------------------------------------------------------------

PROMPT
PROMPT === 7-2. [수정 1] REVIEW_LOG 의 PK / FK =======================
COLUMN constraint_name   FORMAT A20
COLUMN constraint_type   FORMAT A4
COLUMN r_constraint_name FORMAT A20
SELECT constraint_name, constraint_type, r_constraint_name
FROM   user_constraints
WHERE  table_name = 'REVIEW_LOG'
  AND  constraint_type IN ('P','R')
ORDER  BY constraint_type;

PROMPT
PROMPT === 7-3. [수정 2] 금액이 0 으로 고정되지 않았는지 =========================
PROMPT ( 0원_건수 가 0 이어야 정상. 원본 스크립트면 전체 건수가 그대로 나온다 )
SELECT MIN(total_amt)            AS "최소금액",
       ROUND(AVG(total_amt))     AS "평균금액",
       MAX(total_amt)            AS "최대금액",
       COUNT(CASE WHEN total_amt = 0 THEN 1 END) AS "0원_건수"
FROM   medical_claims;

SELECT MIN(amt)                  AS "최소금액",
       ROUND(AVG(amt))           AS "평균금액",
       MAX(amt)                  AS "최대금액",
       COUNT(CASE WHEN amt = 0 THEN 1 END)       AS "0원_건수"
FROM   claim_details;

PROMPT ( 불일치_건수 는 0 이어야 한다 : TOTAL_AMT = SUM(상세 AMT) )
SELECT COUNT(*) AS "불일치_건수"
FROM   medical_claims c
       LEFT JOIN (SELECT claim_id, SUM(amt) s FROM claim_details GROUP BY claim_id) d
              ON  d.claim_id = c.claim_id
WHERE  c.total_amt <> NVL(d.s, 0);

PROMPT
PROMPT === 7-4. [수정 3] DISEASES 주상병 / 부상병 =========================
SELECT CASE dis_type WHEN '1' THEN '1 (주상병)'
                     WHEN '2' THEN '2 (부상병)'
            END                  AS "상병구분",
       COUNT(*)                  AS "건수",
       ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100, 1) AS "비율(%)"
FROM   diseases
GROUP  BY dis_type
ORDER  BY dis_type;

PROMPT
PROMPT === 7-5. [수정 4,5] HOSPITALS 종별 / 상태 ========================
SELECT hosp_type AS "요양기관종별", COUNT(*) AS "건수" FROM hospitals GROUP BY hosp_type ORDER BY 2 DESC;
SELECT status    AS "상태",         COUNT(*) AS "건수" FROM hospitals GROUP BY status    ORDER BY 2 DESC;

PROMPT
PROMPT === 7-6. [수정 6] PATIENTS 보험유형 ==============================
SELECT ins_type AS "보험유형", COUNT(*) AS "건수" FROM patients GROUP BY ins_type ORDER BY 2 DESC;

PROMPT
PROMPT === 7-7. [수정 7,8] 접수일 범위 / 진료일 오프셋 =========================
PROMPT ( 접수일은 2024-01-01 ~ 2024-12-31, 진료일 차는 1 ~ 14 여야 한다 )
SELECT TO_CHAR(MIN(receipt_date),'YYYY-MM-DD') AS "최초접수일",
       TO_CHAR(MAX(receipt_date),'YYYY-MM-DD') AS "최종접수일",
       MIN(receipt_date - visit_date)          AS "진료일차_최소",
       MAX(receipt_date - visit_date)          AS "진료일차_최대"
FROM   medical_claims;

PROMPT
PROMPT === 7-8. [수정 9] DRUG_MASTER 적용일 범위 =========================
PROMPT ( 서로다른_적용일수 가 1 이면 원본(전부 2020-01-01) 그대로다 )
SELECT TO_CHAR(MIN(apply_date),'YYYY-MM-DD') AS "최초적용일",
       TO_CHAR(MAX(apply_date),'YYYY-MM-DD') AS "최종적용일",
       COUNT(DISTINCT apply_date)            AS "서로다른_적용일수"
FROM   drug_master;

PROMPT
PROMPT === 7-9. 데이터 쏠림(Skew) : 1~50번 병원이 약 50% ====================
SELECT CASE WHEN hosp_id <= 50 THEN '1~50번(대형)' ELSE '51번 이후' END AS "병원구간",
       COUNT(*)                                   AS "청구건수",
       ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100, 1) AS "비율(%)"
FROM   medical_claims
GROUP  BY CASE WHEN hosp_id <= 50 THEN '1~50번(대형)' ELSE '51번 이후' END;

PROMPT
PROMPT === 7-10. 세그먼트 크기 ==========================================
COLUMN segment_name FORMAT A20
COLUMN segment_type FORMAT A12
SELECT segment_name, segment_type, ROUND(SUM(bytes)/1024/1024, 1) AS "MB"
FROM   user_segments
GROUP  BY segment_name, segment_type
ORDER  BY SUM(bytes) DESC;

SELECT ROUND(SUM(bytes)/1024/1024, 1) AS "전체_MB" FROM user_segments;

PROMPT
PROMPT ============================================================
PROMPT  완료. 실행 기록은 claim_schema_build.log 에 남았다.
PROMPT ============================================================

-- [실행 보완] 대화형 세션에 EXIT 설정을 남기지 않는다.
WHENEVER SQLERROR CONTINUE NONE
WHENEVER OSERROR  CONTINUE NONE
SET TIMING OFF
SPOOL OFF
