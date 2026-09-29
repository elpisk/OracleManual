-- ============================================================================
--  진료비 청구 및 심사 시스템 - 스키마 · 대량 데이터 생성 스크립트 (실행용)
-- ============================================================================
--  출처 : 진료비청구심사_스키마_생성스크립트_수정본.md 의 「수정된 전체 스크립트」
--         (원본 PDF 스크립트를 검토해 찾은 9건을 반영한 판)
--  용도 : SQL 튜닝 / SQL 고급활용 실습 스키마를 SQLT 계정에 한 번에 만든다.
--         SQL튜닝_Ch01~Ch14_실습 · 진료비청구심사_실습문제_50제 ·
--         SQL고급활용_문제_50제 가 모두 이 7개 표를 쓴다.
--
--  실행 방법
--      $ sqlplus sqlt/sqlt@orcl @진료비청구심사_스키마_생성.sql
--      SQL Developer 라면 F5(스크립트 실행). F9(문장 실행)로는 돌아가지 않는다.
--
--  계정이 없으면 SYS 로 먼저 만든다. 현재 랩의 SQLT 와 같은 권한 구성이다.
--      CREATE USER sqlt IDENTIFIED BY sqlt DEFAULT TABLESPACE users;
--      GRANT CONNECT, RESOURCE, PLUSTRACE, SELECT_CATALOG_ROLE TO sqlt;
--      GRANT CREATE VIEW, UNLIMITED TABLESPACE TO sqlt;
--      -- PLUSTRACE 는 AUTOTRACE(Ch14), SELECT_CATALOG_ROLE 은 V$SQL 조회에 쓴다.
--
--  실측 (19.3.0.0 / OEL7 / 위 DEFINE 그대로 전량 2회, 2026-09-30)
--      전체          1분 24초 ~ 1분 51초
--        1단계(마스터 6.1만 건)     1.7 ~  1.9 초
--        2단계(청구 30만 건 루프) 1분 16초 ~ 1분 43초   <- 대부분이 여기다
--        3단계(로그 50만 건)        2.9 ~  3.7 초
--        통계 수집                  2.8 초
--      세그먼트 총 179.1 MB (표 134 MB + 인덱스 45 MB). 두 번 다 같았고
--      현재 SQLT 스키마의 179.1 MB 와도 같다.
--      -> 테이블스페이스 여유를 200 MB 이상 확보하고 시작한다.
--      장비가 느리면 2단계가 길어진다. 아래 DEFINE 을 줄여 소량으로 한 번
--      돌려 확인한 뒤 전량을 실행하는 것을 권한다.
--
--  !! 주의 1 : 0단계에서 표 7개와 시퀀스 2개를 PURGE 로 DROP 한다.
--              이미 데이터가 있는 SQLT 에 그대로 돌리면 그 데이터는 사라진다.
--              SYS / SYSTEM 으로는 실행되지 않도록 앞에서 막아 두었다.
--
--  !! 주의 2 : 이 스크립트는 이미 실측이 끝난 SQLT 스키마를 "다시 만드는" 용도가
--              아니다. 건당 상세 개수(1~5)와 부상병 추가(33%)를 DBMS_RANDOM 으로
--              뽑으므로, 다시 돌리면 아래 두 건수가 수백 건 단위로 달라진다.
--
--                              현재 SQLT (교안 실측 기준)   재생성 시
--                CLAIM_DETAILS         899,894             약 90만 (±수백)
--                DISEASES              399,551             약 40만 (±수백)
--
--              나머지 5개 표(1,000 / 50,000 / 10,000 / 300,000 / 500,000)는
--              루프 상한이 정한 값이라 항상 똑같이 나온다.
--              SQL튜닝_Ch01~Ch14_실습 의 A-Rows·Buffers 는 현재 데이터를 전제로
--              측정한 값이다. 재생성하면 그 숫자가 미세하게 어긋난다. 실습 기록을
--              그대로 재현해야 한다면 이 스크립트를 SQLT 에 돌리지 말고, 비교용
--              별도 계정에 만들어 쓴다.
--              (학생마다 같은 데이터를 주고 싶으면 2단계 맨 앞에서
--               DBMS_RANDOM.SEED(1) 을 호출하면 재현 가능해진다)
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
-- [실행 보완] 생성 건수를 한 곳에 모았다. 아래 값이 원본(= 현재 SQLT) 그대로다.
--   바꾸지 말 것. 소량으로 한 번 시험해 볼 때만 줄이고, 본 실행은 이 값으로 한다.
--   빠른 확인용 예 :    50 /  2000 /  1000 /   2000 /   2000 /   1000
--
--   n_drug 은 10000 이 맞다. .md 코드블록의 루프만 1..20000 으로 적혀 있고,
--   같은 문서의 DBMS_OUTPUT 문구·「기대 결과」표는 10,000 이며, 실측이 끝난
--   SQLT.DRUG_MASTER 도 10,000 건이다(2026-09-30 확인). 코드블록이 오기다.
--   CLAIM_DETAILS 의 DRUG_CODE 도 D000000001~D000010000 에서만 뽑으므로
--   n_drug 을 20000 으로 올리면 뒤 10,000 건은 아무도 참조하지 않는 사표가 된다.
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

-- [실행 보완] 두 가지를 고쳤다.
--
--  (1) .md 는 스키마명을 'ALICE' 로 박아 두었다. SQLT 로 실행하면 ORA-20000
--      (object does not exist) 이 난다. 접속 계정(USER)을 쓴다.
--
--  (2) method_opt 를 기본값(FOR ALL COLUMNS SIZE AUTO)으로 두면 안 된다.
--      AUTO 는 "WHERE 에 쓰인 적이 있는 컬럼" 전부에 히스토그램을 만들어서
--      MEDICAL_CLAIMS 의 CLAIM_ID·CLAIM_TYPE·DEPT_CODE·RECEIPT_DATE·
--      REVIEW_STATUS·TOTAL_AMT 까지 붙는다. 그러면 SQL튜닝_Ch01~Ch14_실습 의
--      E-Rows 가 교안 기록과 달라진다.
--      이 과정의 기준 상태는 "히스토그램은 MEDICAL_CLAIMS.HOSP_ID 하나(HYBRID
--      254 버킷)" 이다 -- SQL튜닝_Ch01_실습_01 의 [2], Ch13_실습_03 의 [3] 과
--      같은 Day 0 준비 명령을 그대로 쓴다.
EXEC DBMS_STATS.GATHER_SCHEMA_STATS(USER, METHOD_OPT => 'FOR ALL COLUMNS SIZE 1');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'MEDICAL_CLAIMS', METHOD_OPT => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS SIZE 254 HOSP_ID', NO_INVALIDATE => FALSE);

PROMPT
PROMPT ============================================================
PROMPT  7. 데이터 생성 결과 확인
PROMPT ============================================================
SET TIMING OFF

COLUMN TNAME FORMAT A16

PROMPT
PROMPT === 7-1. 테이블별 건수 (교안 기준값과 비교) =======================
PROMPT ( 기준값 = SQL튜닝_Ch01_실습_01 의 [1] 에 실린 숫자.
PROMPT   CLAIM_DETAILS·DISEASES 만 DBMS_RANDOM 탓에 수백 건 흔들린다 )
COLUMN "기준값" FORMAT A12
COLUMN "판정"   FORMAT A6
SELECT t.tname AS TNAME, c.cnt AS CNT, t.base AS "기준값",
       CASE WHEN t.exact = 'Y' AND c.cnt = t.n           THEN '일치'
            WHEN t.exact = 'Y'                           THEN '불일치'
            WHEN ABS(c.cnt - t.n) <= t.n * 0.01          THEN '범위내'
            ELSE '벗어남' END AS "판정"
FROM  (SELECT 'HOSPITALS'      tname, 1000   n, '1,000'         base, 'Y' exact FROM dual UNION ALL
       SELECT 'PATIENTS',              50000,   '50,000',            'Y' FROM dual UNION ALL
       SELECT 'DRUG_MASTER',           10000,   '10,000',            'Y' FROM dual UNION ALL
       SELECT 'MEDICAL_CLAIMS',       300000,   '300,000',           'Y' FROM dual UNION ALL
       SELECT 'CLAIM_DETAILS',        899894,   '899,894 상당',       'N' FROM dual UNION ALL
       SELECT 'DISEASES',             399551,   '399,551 상당',       'N' FROM dual UNION ALL
       SELECT 'REVIEW_LOG',           500000,   '500,000',           'Y' FROM dual) t
      JOIN
      (SELECT 'HOSPITALS' tname, COUNT(*) cnt FROM HOSPITALS      UNION ALL
       SELECT 'PATIENTS',        COUNT(*)     FROM PATIENTS       UNION ALL
       SELECT 'DRUG_MASTER',     COUNT(*)     FROM DRUG_MASTER    UNION ALL
       SELECT 'MEDICAL_CLAIMS',  COUNT(*)     FROM MEDICAL_CLAIMS UNION ALL
       SELECT 'CLAIM_DETAILS',   COUNT(*)     FROM CLAIM_DETAILS  UNION ALL
       SELECT 'DISEASES',        COUNT(*)     FROM DISEASES       UNION ALL
       SELECT 'REVIEW_LOG',      COUNT(*)     FROM REVIEW_LOG) c
      ON c.tname = t.tname
ORDER BY DECODE(t.tname, 'HOSPITALS',1,'PATIENTS',2,'DRUG_MASTER',3,
                         'MEDICAL_CLAIMS',4,'CLAIM_DETAILS',5,'DISEASES',6,7);

PROMPT
PROMPT === 7-1b. 교안 기준 상태 : 인덱스는 PK 7개만 =====================
PROMPT ( IX_ 로 시작하는 인덱스가 보이면 Ch04~Ch12 의 Buffers 가 달라진다 )
COLUMN table_name FORMAT A16
COLUMN index_name FORMAT A20
SELECT table_name, index_name, uniqueness FROM user_indexes ORDER BY table_name;

PROMPT
PROMPT === 7-1c. 교안 기준 상태 : 히스토그램은 HOSP_ID 하나 =============
PROMPT ( 아래가 딱 1행(MEDICAL_CLAIMS / HOSP_ID / HYBRID / 254) 이어야 한다 )
COLUMN column_name FORMAT A14
SELECT table_name, column_name, histogram, num_buckets
FROM   user_tab_col_statistics WHERE histogram <> 'NONE'
ORDER  BY table_name, column_name;

PROMPT
PROMPT === 7-1d. 제약 13개 (PK 7 + FK 6) ===============================
SELECT COUNT(*) AS "제약수",
       COUNT(CASE WHEN constraint_type = 'P' THEN 1 END) AS "PK",
       COUNT(CASE WHEN constraint_type = 'R' THEN 1 END) AS "FK"
FROM   user_constraints WHERE constraint_type IN ('P','R');

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
