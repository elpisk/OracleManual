# 진료비 청구 및 심사 시스템 — NVARCHAR2 버전 (DB 문자셋을 못 바꾸는 경우)

DB의 `NLS_CHARACTERSET`이 `WE8MSWIN1252`(한글 미지원)이고 DB 자체를 재생성할 수 없는 상황을
위한 버전입니다. `진료비청구심사_스키마_생성스크립트_수정본.md`와 로직은 동일하고(FK 순서
수정, TOTAL_AMT 계산, DISEASES 주상병/부상병 비율 등 이전 수정사항 전부 포함), **한글이 실제로
들어가는 컬럼만 `NVARCHAR2`로 바꿔** 국가별 문자집합(`NLS_NCHAR_CHARACTERSET`, 보통
`AL16UTF16` — 한글 포함 전 유니코드 지원)에 저장되도록 했습니다.

## 시작 전 꼭 확인할 것

```sql
SELECT * FROM nls_database_parameters WHERE parameter = 'NLS_NCHAR_CHARACTERSET';
```

결과가 `AL16UTF16`(오라클 기본값)이면 아래 스크립트를 그대로 쓰면 됩니다. 만약 이것도
한글을 지원하지 않는 값이라면(극히 드문 경우) NVARCHAR2로도 해결이 안 되니 DB 재생성 쪽으로
가야 합니다.

## 어떤 컬럼을 바꿨는지 (그리고 왜 안 바꾼 컬럼도 있는지)

| 테이블 | NVARCHAR2로 전환 | 그대로 둔 이유 |
|---|---|---|
| HOSPITALS | HOSP_NAME, HOSP_TYPE, CITY, STATUS | HOSP_ID(NUMBER)는 해당 없음 |
| PATIENTS | CITY, INS_TYPE | **PAT_NAME은 그대로 VARCHAR2** — 생성 로직이 `DBMS_RANDOM.STRING('U'/'L', ..)`으로 영문자만 만들기 때문에 실제로 한글이 들어가지 않음. GENDER/BIRTH_DATE/PHONE도 영문·숫자뿐 |
| DRUG_MASTER | DRUG_NAME, CATEGORY, PHARM_COMPANY | DRUG_CODE는 PK이자 코드값('D000000001')이라 한글 없음 |
| MEDICAL_CLAIMS | CLAIM_TYPE, REVIEW_STATUS | CLAIM_ID/DEPT_CODE는 코드값, 나머지는 NUMBER/DATE |
| CLAIM_DETAILS | 없음 | 이 테이블은 컬럼 전체가 숫자/코드값이라 한글이 전혀 없음 |
| DISEASES | 없음 | DIS_CODE('J00', 'M45' 등)·DIS_TYPE('1'/'2')도 한글 없음 |
| REVIEW_LOG | ACTION_MSG | REVIEWER_ID('EMP_101', 'SYSTEM')·ERROR_CODE는 영문·코드값 |

**중요**: PK/FK로 쓰이는 컬럼(HOSP_ID, PAT_ID, DRUG_CODE, CLAIM_ID, DETAIL_ID, DIS_SEQ,
LOG_ID)은 전부 이번 변경 대상에서 제외됩니다 — 애초에 한글이 들어가지 않는 코드/숫자
컬럼들이라, 기본키·외래키 관계나 조인에는 이 수정이 전혀 영향을 주지 않습니다.

혹시 PAT_NAME도 나중에 실제 한글 이름으로 바꾸고 싶으시면(예: 성+이름 랜덤 조합) 말씀해
주세요 — 지금은 요청하신 범위(한글이 이미 들어가는 컬럼)에서 제외했습니다.

## PL/SQL에서 한글 리터럴은 반드시 `N'...'`로

`NVARCHAR2` 컬럼에 넣는 한글 문자열 리터럴 앞에는 `N` 접두사를 붙였습니다
(`N'상급종합'`처럼). 접두사 없이 `'상급종합'`처럼 일반 리터럴로 넣으면 Oracle이 그 리터럴을
먼저 DB 캐릭터셋(`WE8MSWIN1252`) 기준으로 해석한 뒤 NVARCHAR2로 변환하려 시도할 수 있어,
컬럼 타입만 NVARCHAR2로 바꿔도 여전히 깨질 위험이 있습니다. `N'...'`는 "이 리터럴은 처음부터
국가별 문자집합으로 다뤄라"라고 명시하는 표준적인 방법이라, 모든 한글 리터럴에 일관되게
적용했습니다.

## 수정된 전체 스크립트

```sql
-- ============================================================
-- 0. 기존 테이블 정리 (재실행 시 초기화)
-- ============================================================
DROP TABLE REVIEW_LOG PURGE;
DROP TABLE DISEASES PURGE;
DROP TABLE CLAIM_DETAILS PURGE;
DROP TABLE MEDICAL_CLAIMS PURGE;
DROP TABLE DRUG_MASTER PURGE;
DROP TABLE PATIENTS PURGE;
DROP TABLE HOSPITALS PURGE;

-- ============================================================
-- 1. 테이블 생성 (한글 컬럼만 NVARCHAR2로 전환 — [NCHAR] 표시)
-- ============================================================
CREATE TABLE HOSPITALS (
    HOSP_ID     NUMBER(10)      NOT NULL,
    HOSP_NAME   NVARCHAR2(100),                 -- [NCHAR]
    HOSP_TYPE   NVARCHAR2(20),                  -- [NCHAR]
    CITY        NVARCHAR2(50),                  -- [NCHAR]
    EST_DATE    DATE,
    STATUS      NVARCHAR2(10),                  -- [NCHAR]
    CONSTRAINT PK_HOSPITALS PRIMARY KEY (HOSP_ID)
);

CREATE TABLE PATIENTS (
    PAT_ID      NUMBER(10)    NOT NULL,
    PAT_NAME    VARCHAR2(50),                    -- 영문 랜덤 문자열, 변경 없음
    GENDER      CHAR(1),
    BIRTH_DATE  VARCHAR2(8),
    CITY        NVARCHAR2(50),                  -- [NCHAR]
    INS_TYPE    NVARCHAR2(20),                  -- [NCHAR]
    PHONE       VARCHAR2(20),
    CONSTRAINT PK_PATIENTS PRIMARY KEY (PAT_ID)
);

CREATE TABLE DRUG_MASTER (
    DRUG_CODE      VARCHAR2(20)  NOT NULL,
    DRUG_NAME      NVARCHAR2(200),               -- [NCHAR]
    CATEGORY       NVARCHAR2(50),                -- [NCHAR]
    PRICE          NUMBER(10),
    PHARM_COMPANY  NVARCHAR2(100),               -- [NCHAR]
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
    CLAIM_TYPE     NVARCHAR2(20),                -- [NCHAR]
    TOTAL_AMT      NUMBER(12),
    REVIEW_STATUS  NVARCHAR2(20),                -- [NCHAR]
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
    ACTION_MSG     NVARCHAR2(500),               -- [NCHAR]
    ERROR_CODE     VARCHAR2(10),
    CONSTRAINT PK_REVIEW_LOG PRIMARY KEY (LOG_ID),
    CONSTRAINT FK_LOG_CLAIM  FOREIGN KEY (CLAIM_ID) REFERENCES MEDICAL_CLAIMS(CLAIM_ID)
);

-- ============================================================
-- 2. 1단계: 마스터 데이터 생성 (병원/환자/약품)
-- ============================================================
SET SERVEROUTPUT ON;

DECLARE
    v_cnt NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('1단계: 마스터 데이터 생성을 시작합니다...');

    -- HOSPITALS 1,000건
    FOR i IN 1..1000 LOOP
        INSERT INTO HOSPITALS (HOSP_ID, HOSP_NAME, HOSP_TYPE, CITY, EST_DATE, STATUS)
        VALUES (
            i,
            N'요양기관_' || i,
            CASE WHEN MOD(i, 100) = 0 THEN N'상급종합'   -- 약 1%
                 WHEN MOD(i, 20)  = 0 THEN N'종합병원'    -- 약 4%
                 WHEN MOD(i, 5)   = 0 THEN N'약국'         -- 약 15%
                 ELSE N'의원' END,                          -- 약 80%
            CASE WHEN i <= 400 THEN N'서울'
                 WHEN i <= 700 THEN N'경기'
                 ELSE N'부산' END,
            TO_DATE('20000101','YYYYMMDD') + TRUNC(DBMS_RANDOM.VALUE(0, 7000)),
            CASE WHEN MOD(i, 50) = 0 THEN N'폐업'          -- 약 2%
                 WHEN MOD(i, 15) = 0 THEN N'휴업'          -- 약 6%
                 ELSE N'운영' END                           -- 약 92%
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(' - HOSPITALS 1,000건 생성 완료');

    -- PATIENTS 50,000건
    FOR i IN 1..50000 LOOP
        INSERT INTO PATIENTS (PAT_ID, PAT_NAME, GENDER, BIRTH_DATE, CITY, INS_TYPE, PHONE)
        VALUES (
            i,
            DBMS_RANDOM.STRING('U', 3) || DBMS_RANDOM.STRING('L', 4),
            CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.5 THEN 'M' ELSE 'F' END,
            TO_CHAR(TO_DATE('19400101','YYYYMMDD') + TRUNC(DBMS_RANDOM.VALUE(0, 25000)), 'YYYYMMDD'),
            CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.6 THEN N'서울' ELSE N'기타' END,
            CASE WHEN MOD(i, 100) = 0 THEN N'보훈'          -- 약 1%
                 WHEN MOD(i, 10)  = 0 THEN N'의료급여'      -- 약 9%
                 ELSE N'건강보험' END,                       -- 약 90%
            '010-' || TRUNC(DBMS_RANDOM.VALUE(1000, 9999)) || '-' || TRUNC(DBMS_RANDOM.VALUE(1000, 9999))
        );
        IF MOD(i, 5000) = 0 THEN COMMIT; END IF;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(' - PATIENTS 50,000건 생성 완료');

    -- DRUG_MASTER 10,000건
    FOR i IN 1..10000 LOOP
        INSERT INTO DRUG_MASTER (DRUG_CODE, DRUG_NAME, CATEGORY, PRICE, PHARM_COMPANY, APPLY_DATE)
        VALUES (
            'D' || LPAD(i, 9, '0'),
            N'약품_' || i,
            CASE WHEN MOD(i, 10) = 0 THEN N'주사제'
                 WHEN MOD(i, 3)  = 0 THEN N'처치'
                 ELSE N'내복약' END,
            TRUNC(DBMS_RANDOM.VALUE(100, 50000)),
            N'제약사_' || TRUNC(DBMS_RANDOM.VALUE(1, 100)),
            TO_DATE('20200101','YYYYMMDD') + TRUNC(DBMS_RANDOM.VALUE(0, 1500))
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(' - DRUG_MASTER 10,000건 생성 완료');
END;
/

-- ============================================================
-- 3. 시퀀스 생성
-- ============================================================
CREATE SEQUENCE seq_detail_id;
CREATE SEQUENCE seq_dis_id;

-- ============================================================
-- 4. 2단계: 핵심 트랜잭션 데이터 대량 생성
--    (청구서 30만 건 / 상세내역 90만~120만 건 / 상병 약 40만 건)
-- ============================================================
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
    v_total_amt   NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('2단계: 트랜잭션 데이터 대량 생성을 시작합니다... (시간 소요됨)');

    FOR i IN 1..300000 LOOP
        -- 데이터 쏠림(Skew) 생성 로직: 1~50번 병원(대형병원 가정)에 청구의 50%를 몰아줌
        IF DBMS_RANDOM.VALUE(0, 1) < 0.5 THEN
            v_hosp_id := TRUNC(DBMS_RANDOM.VALUE(1, 51));
        ELSE
            v_hosp_id := TRUNC(DBMS_RANDOM.VALUE(51, 1001));
        END IF;

        v_pat_id    := TRUNC(DBMS_RANDOM.VALUE(1, 50001));
        v_date      := TO_DATE('20240101','YYYYMMDD') + TRUNC(DBMS_RANDOM.VALUE(0, 366));
        v_claim_id  := TO_CHAR(v_date, 'YYYYMMDD') || '-' || LPAD(i, 7, '0');
        v_total_amt := 0;

        -- MEDICAL_CLAIMS(부모)를 먼저 입력한다. TOTAL_AMT는 일단 0(자리표시자) —
        -- CLAIM_DETAILS.CLAIM_ID에 FK_DETAIL_CLAIM 제약이 걸려 있어 부모 행이
        -- 먼저 존재해야만 자식(CLAIM_DETAILS)을 넣을 수 있다.
        INSERT INTO MEDICAL_CLAIMS (CLAIM_ID, HOSP_ID, PAT_ID, RECEIPT_DATE, VISIT_DATE,
                                     DEPT_CODE, CLAIM_TYPE, TOTAL_AMT, REVIEW_STATUS)
        VALUES (
            v_claim_id,
            v_hosp_id,
            v_pat_id,
            v_date,
            v_date - TRUNC(DBMS_RANDOM.VALUE(1, 15)),  -- 진료일 = 접수일 1~14일 전
            'D' || TRUNC(DBMS_RANDOM.VALUE(1, 10)),
            CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.8 THEN N'입원' ELSE N'외래' END,
            0,                                           -- 자리표시자, 아래에서 UPDATE로 채움
            CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.9 THEN N'심사중' ELSE N'심사완료' END
        );

        -- CLAIM_DETAILS(자식)를 생성하며 실제 금액(AMT)을 계산·누적한다.
        v_detail_cnt := TRUNC(DBMS_RANDOM.VALUE(1, 6));  -- 건당 1~5개
        FOR j IN 1..v_detail_cnt LOOP
            v_qty        := TRUNC(DBMS_RANDOM.VALUE(1, 4));      -- 1~3
            v_days       := TRUNC(DBMS_RANDOM.VALUE(1, 10));     -- 1~9
            v_unit_price := TRUNC(DBMS_RANDOM.VALUE(100, 10000)); -- 100~9999
            v_line_amt   := v_unit_price * v_qty * v_days;

            INSERT INTO CLAIM_DETAILS (DETAIL_ID, CLAIM_ID, DRUG_CODE, QTY, DAYS, UNIT_PRICE, AMT)
            VALUES (
                seq_detail_id.NEXTVAL,
                v_claim_id,
                'D' || LPAD(TRUNC(DBMS_RANDOM.VALUE(1, 10001)), 9, '0'),
                v_qty, v_days, v_unit_price, v_line_amt
            );

            v_total_amt := v_total_amt + v_line_amt;
        END LOOP;

        -- 방금 계산한 합계로 MEDICAL_CLAIMS.TOTAL_AMT를 갱신한다.
        UPDATE MEDICAL_CLAIMS
        SET    TOTAL_AMT = v_total_amt
        WHERE  CLAIM_ID  = v_claim_id;

        -- DISEASES: 주상병(DIS_TYPE=1)은 항상 1건, 부상병(DIS_TYPE=2)은 약 33% 확률로 추가
        -- -> 평균 1.33건/청구, 30만 청구 기준 총 약 40만 건
        INSERT INTO DISEASES (DIS_SEQ, CLAIM_ID, DIS_CODE, DIS_TYPE)
        VALUES (
            seq_dis_id.NEXTVAL,
            v_claim_id,
            CASE WHEN DBMS_RANDOM.VALUE(0,1) > 0.7 THEN 'J00'   -- 감기(흔한 질병) 30%
                 ELSE 'M' || TRUNC(DBMS_RANDOM.VALUE(10, 99)) END,
            '1'
        );
        IF DBMS_RANDOM.VALUE(0, 1) > 0.67 THEN                   -- 약 33% 확률
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

-- ============================================================
-- 5. 3단계: 로그 데이터 생성 및 마무리
-- ============================================================
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('3단계: 로그 데이터 생성 및 마무리...');

    INSERT INTO REVIEW_LOG (LOG_ID, CLAIM_ID, REVIEWER_ID, PROCESS_DATE, ACTION_MSG, ERROR_CODE)
    SELECT
        ROWNUM,
        CLAIM_ID,
        'EMP_' || TRUNC(DBMS_RANDOM.VALUE(100, 200)),
        RECEIPT_DATE + DBMS_RANDOM.VALUE(1, 5),
        N'심사 처리 완료',
        NULL
    FROM MEDICAL_CLAIMS
    WHERE ROWNUM <= 300000;

    INSERT INTO REVIEW_LOG (LOG_ID, CLAIM_ID, REVIEWER_ID, PROCESS_DATE, ACTION_MSG, ERROR_CODE)
    SELECT
        300000 + ROWNUM,
        CLAIM_ID,
        'SYSTEM',
        RECEIPT_DATE,
        N'자동 심사 반려',
        'E' || TRUNC(DBMS_RANDOM.VALUE(10, 99))
    FROM MEDICAL_CLAIMS
    WHERE ROWNUM <= 200000;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(' - 전체 데이터 생성 완료!');
END;
/

-- ============================================================
-- 6. 데이터 생성 결과 확인
-- ============================================================
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
SELECT 'DISEASES', COUNT(*) FROM DISEASES
UNION ALL
SELECT 'REVIEW_LOG', COUNT(*) FROM REVIEW_LOG;

-- 한글이 제대로 들어갔는지 확인 (아래 세 쿼리 모두 물음표 없이 정상 출력되어야 함)
SELECT DISTINCT HOSP_TYPE FROM HOSPITALS;
SELECT DISTINCT STATUS FROM HOSPITALS;
SELECT DISTINCT INS_TYPE FROM PATIENTS;
```

## 남은 주의사항

- **화면에 여전히 `?`나 깨진 글자가 보인다면**, 이번엔 저장 문제가 아니라 SQL*Plus
  클라이언트 쪽 `NLS_LANG`/터미널 코드페이지 문제입니다(예전에 안내드린 `chcp`, `NLS_LANG`
  설정). `NVARCHAR2`로 바꾼 이상 DB에는 원본 한글이 손실 없이 저장되므로, 클라이언트 설정만
  맞추면 언제든 정상적으로 보이게 됩니다 — 데이터를 다시 만들 필요는 없습니다.
- `진료비청구심사_ERD_erwin리버스엔지니어링.sql`의 `COMMENT ON TABLE/COLUMN` 문구는 이번
  수정과는 무관하게 **여전히 영향을 받습니다** — 코멘트(주석) 메타데이터는 NVARCHAR2가 아니라
  DB 캐릭터셋(`WE8MSWIN1252`)으로 저장되는 오브젝트라서, 그 파일의 한글 설명은 DB 자체를
  AL32UTF8로 바꾸기 전까지는 erwin에서도 계속 깨져 보입니다. 필요하시면 그 파일의 COMMENT
  문구만 영문으로 바꾼 버전도 만들어 드릴 수 있습니다.
