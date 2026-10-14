-- ============================================================================
-- PF_11_부하패턴.sql  :  나쁜 부하를 그대로 재현한다 (카드 A·B·E·F·G·I·J)
-- AWR 진단 포트폴리오 과제 (5/5)
-- ============================================================================
-- 목적       : 열 장의 카드 중 일곱 장은 "망가진 설정" 이 아니라 "나쁜 부하" 다.
--              설정은 멀쩡한데 애플리케이션이 DB 를 잘못 쓰는 경우다. 운영에서
--              훨씬 흔하고, AWR 로만 잡아낼 수 있다. 실행 계획을 들여다봐도
--              각각은 정상이기 때문이다.
--
--                A  리터럴 SQL 폭주   - 같은 모양을 매번 새로 파싱한다
--                B  행별 커밋         - 1만 행을 1만 번 커밋한다
--                E  인덱스 부재       - 인덱스 없는 컬럼으로 200번 조회한다
--                F  행 잠금 경쟁      - 남이 쥔 행을 기다린다
--                G  작업 영역 축소    - 정렬을 디스크로 넘긴다
--                I  호출 횟수 폭주     - 회당 2~3 블록인데 3만 번 부른다
--                J  짧은 폭주         - AWR 평균에 묻히고 ASH 에만 보인다
--
-- 전제       : 1) SQLT 로 접속한다. ★ SYS 로 돌리지 않는다 ★
--                 이 부하가 수강생 세션의 통계에 그대로 남아야 한다.
--              2) 카드 F 만 준비가 따로 필요하다. 아래 [사용법] 참조.
--              3) 복제표 PF_WL_T 를 자동으로 만든다. 원본 7개 표는 읽기만 한다.
--
-- 사용법     : 인자 2개. 두 번째는 반복 횟수이고, 비우면 기본값을 쓴다.
--
--                @PF_11_부하패턴.sql A 2000    -- 리터럴 SQL 2,000번
--                @PF_11_부하패턴.sql B 10000   -- 행별 커밋 1만 행
--                @PF_11_부하패턴.sql E 200     -- 인덱스 없는 컬럼 200번 조회
--                @PF_11_부하패턴.sql EFIX 200  -- 조치(인덱스) 후 재측정 - 강사용
--                @PF_11_부하패턴.sql F 60      -- 60초간 잠금 대기
--                @PF_11_부하패턴.sql G 1       -- 디스크 정렬 1회
--                @PF_11_부하패턴.sql I 1       -- 호출 폭주 1회
--                @PF_11_부하패턴.sql J 1       -- 짧은 폭주 1회
--                @PF_11_부하패턴.sql PREP -    -- 복제표 준비 (처음 한 번)
--
--              구간을 잡고 돌린다. SYS 창과 SQLT 창을 따로 열어 두면 편하다.
--                [SYS]  @PF_20_측정보조.sql SNAP T0 -
--                [SQLT] @PF_11_부하패턴.sql A 2000
--                [SYS]  @PF_20_측정보조.sql SNAP T1 -
--                [SYS]  @PF_20_측정보조.sql DELTA  T0 T1
--                [SYS]  @PF_20_측정보조.sql TOPSQL T0 T1
--
--              ★ 카드 F 는 두 세션이 필요하다 ★
--              먼저 SYS 창에서 방해자를 띄운다 (60초간 행을 쥐고 있는 작업) :
--                [SYS]  @PF_11_부하패턴.sql BLOCKER 60
--              바로 이어서 SQLT 창에서 :
--                [SQLT] @PF_11_부하패턴.sql F 60
--
-- 소요 시간  : A 10~40초 · B 20~90초 · E 1~3초 · F 지정한 초만큼
--              G 2~5초 · I 20~60초 · J 10초(그중 폭주는 3초)
--              EFIX 10~40초(인덱스 생성 포함) · PREP 10~30초
--
-- 관찰 지표  : 카드별 블록 주석에 "AWR 에서 어디를 보는가" 를 적어 두었다.
--
-- 되돌리기   : 세션 수준 변경(카드 G)은 접속을 끊으면 사라진다.
--              복제표 PF_WL_T 와 방해자 작업은 PF_99_원복.sql 이 지운다.
--              ALTER SYSTEM 은 쓰지 않는다.
--
-- 주의       : ★ 개인 실습 환경 전용 ★
--              1) 원본 7개 표에는 INSERT·UPDATE·DELETE 를 하지 않는다.
--                 쓰기는 모두 PF_WL_T 복제표에만 한다.
--              2) 카드 B 는 리두를 만든다. 1만 행이면 수 MB 수준이라
--                 아카이브 영역에 부담은 없다. 10만 이상으로 올리지 않는다.
--              3) 카드 A 는 공유 풀에 커서를 2,000개 남긴다. 랩을 같이 쓰면
--                 남의 커서가 밀려날 수 있다. 횟수를 함부로 올리지 않는다.
--              4) 카드 J 는 일부러 짧게 끝난다. 그게 이 카드의 요점이다.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200 PAGESIZE 300 FEEDBACK OFF VERIFY OFF TAB OFF DEFINE ON
SET TIMING ON

DEFINE pf_card = &1
DEFINE pf_n    = &2

PROMPT
PROMPT ============================================================
PROMPT  부하 패턴  :  카드 &pf_card   /  반복 &pf_n
PROMPT ============================================================

DECLARE
    v_card VARCHAR2(12) := UPPER('&pf_card');
    v_arg  VARCHAR2(20) := '&pf_n';
    v_n    NUMBER;
    v_cnt  NUMBER;
    v_t0   TIMESTAMP;
    v_sql  VARCHAR2(400);
    v_dummy NUMBER;
    v_str   VARCHAR2(200);

    PROCEDURE say(p VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE(p); END;

    FUNCTION secs(p_from TIMESTAMP) RETURN NUMBER IS
    BEGIN
        RETURN ROUND(EXTRACT(SECOND FROM (SYSTIMESTAMP - p_from))
                   + EXTRACT(MINUTE FROM (SYSTIMESTAMP - p_from)) * 60, 2);
    END;
BEGIN
    -- 반복 횟수. 하이픈이나 빈 값이면 카드별 기본값을 쓴다.
    BEGIN
        v_n := TO_NUMBER(v_arg);
    EXCEPTION WHEN OTHERS THEN v_n := NULL;
    END;


-- ===========================================================================
-- PREP : 복제표 준비 (카드 B·F 가 쓴다)
-- ---------------------------------------------------------------------------
IF v_card = 'PREP' THEN
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE PF_WL_T PURGE';
        say('[준비] 앞서 남은 PF_WL_T 를 지웠다.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -942 THEN RAISE; END IF;
    END;

    EXECUTE IMMEDIATE
        'CREATE TABLE PF_WL_T (
             id      NUMBER        NOT NULL,
             hosp_id NUMBER,
             amt     NUMBER,
             memo    VARCHAR2(200),
             CONSTRAINT PF_WL_T_PK PRIMARY KEY (id))';
    EXECUTE IMMEDIATE
        'INSERT INTO PF_WL_T (id, hosp_id, amt, memo)
         SELECT ROWNUM, MOD(ROWNUM, 1000) + 1, ROWNUM * 10, ''초기값''
           FROM SQLT.medical_claims WHERE ROWNUM <= 20000';
    v_cnt := SQL%ROWCOUNT;
    COMMIT;
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PF_WL_T',
        METHOD_OPT => 'FOR ALL COLUMNS SIZE 1', NO_INVALIDATE => FALSE);
    say('[준비] PF_WL_T ' || v_cnt || '행. 쓰기는 전부 이 표에만 한다.');


-- ===========================================================================
-- 카드 A : 리터럴 SQL 폭주
-- ---------------------------------------------------------------------------
-- 무엇이 나쁜가
--   값을 바인드 변수로 넘기지 않고 SQL 문장에 박아 넣으면, 값이 바뀔 때마다
--   다른 SQL 이 된다. 공유 풀에서 찾지 못하니 매번 처음부터 파싱한다.
--   파싱은 CPU 를 쓰고 라이브러리 캐시 래치를 잡는다. 동시 사용자가 많으면
--   여기서 전부 줄을 선다.
--
-- AWR 에서 어디를 보는가
--   - Load Profile 의 "Hard parses (SQL)" 가 "Parses (SQL)" 에 근접한다
--     (정상이면 하드 파싱은 전체 파싱의 몇 % 여야 한다)
--   - Instance Efficiency 의 Soft Parse % 가 떨어진다
--   - SQL ordered by Parse Calls 에 같은 모양의 SQL 이 여러 SQL_ID 로 흩어진다
--   - PF_20 의 TOPSQL 이 FORCE_MATCHING_SIGNATURE 로 그 묶음을 보여 준다
--   - Top 10 Events 에 latch: shared pool, library cache: mutex X
--
-- 실측 (2026-10-14, 2,000번)
--   경과 17.15초 · 이 세션 누적 하드 파싱 비율 98.6%
--   공유 풀에 남은 커서 1,323개 (2,000개를 만들었는데 677개는 이미 밀려났다.
--   그 자체가 공유 풀이 압박받았다는 증거다. 보고서에 쓸 만한 숫자다)
--
-- 조치
--   바인드 변수를 쓴다. 애플리케이션을 못 고치면 CURSOR_SHARING=FORCE 가
--   임시 방편이지만, 히스토그램을 못 쓰게 되는 부작용이 있다. 보고서에는
--   그 부작용까지 적어야 점수가 된다.
-- ===========================================================================
ELSIF v_card = 'A' THEN
    v_n := NVL(v_n, 2000);
    v_t0 := SYSTIMESTAMP;
    FOR i IN 1 .. v_n LOOP
        -- 값을 문장에 박는다. 이게 이 카드의 결함이다.
        v_sql := 'SELECT COUNT(*) FROM SQLT.medical_claims '
              || 'WHERE hosp_id = ' || TO_CHAR(i) || ' AND total_amt > 0';
        EXECUTE IMMEDIATE v_sql INTO v_dummy;
    END LOOP;
    say('[부하] 리터럴 SQL ' || v_n || '번. ' || secs(v_t0) || '초.');
    say('       같은 모양인데 SQL_ID 가 ' || v_n || '개 생겼다.');

    SELECT COUNT(*) INTO v_cnt FROM v$sql
     WHERE sql_text LIKE 'SELECT COUNT(*) FROM SQLT.medical_claims WHERE hosp_id = %'
       AND sql_text NOT LIKE '%v$sql%';
    say('       공유 풀에 남은 커서 : ' || v_cnt || '개');

    SELECT ROUND(SUM(DECODE(name, 'parse count (hard)',  value)) * 100
               / GREATEST(SUM(DECODE(name, 'parse count (total)', value)), 1), 1)
      INTO v_cnt FROM v$mystat s JOIN v$statname n USING (statistic#)
     WHERE name IN ('parse count (total)', 'parse count (hard)');
    say('       이 세션 누적 하드 파싱 비율 : ' || v_cnt || '%');


-- ===========================================================================
-- 카드 B : 행별 커밋
-- ---------------------------------------------------------------------------
-- 무엇이 나쁜가
--   커밋은 로그 라이터에게 "지금 디스크에 써라" 고 시키고 그 완료를 기다린다.
--   한 행마다 커밋하면 그 왕복을 행 수만큼 한다. 일은 안 늘고 기다림만 는다.
--
-- AWR 에서 어디를 보는가
--   - Top 10 Foreground Events 1위가 log file sync
--   - Wait Class 가 Commit 으로 쏠린다
--   - Load Profile 의 Transactions 가 비정상으로 높다 (행 수와 비슷해진다)
--   - Instance Activity 의 "user commits" 와 "redo synch writes" 가 같이 뛴다
--   - redo size 는 벌크 적재와 비슷한데 시간은 몇 배 걸린다
--
-- 실측 (2026-10-14, 10,000행)
--   1건씩 커밋 0.42초  vs  일괄 커밋 0.03초  =  14배
--
--   ★ 이 랩의 한계를 알고 봐야 한다 ★
--   커밋당 42마이크로초다. 이 VM 의 로그 파일이 로컬 디스크에 있어 왕복이
--   너무 빠르다. 그래서 log file sync 의 절대 시간이 작게 나오고, AWR 의
--   Top Events 1위로 안 올라올 수도 있다. 실제 운영에서 공유 스토리지를
--   쓰면 커밋당 수 밀리초가 되어 1위가 된다.
--   이 랩에서는 절대 시간이 아니라 아래 두 가지로 읽는다.
--     - 14배라는 비율
--     - PF_20 의 DELTA 가 보여 주는 user commits 델타 (행 수와 같아진다)
--   보고서에도 "이 환경에서는 절대 시간이 작다" 를 적는 편이 낫다.
--   측정 환경의 한계를 밝히는 것이 감점이 아니라 가점이다.
--
-- 조치
--   한 건씩 커밋하지 말고 배치로 묶는다. 주의할 점은 "커밋을 줄이면 잠금을
--   오래 쥔다" 는 맞교환이다. 보고서에 그 맞교환을 적는다.
-- ===========================================================================
ELSIF v_card = 'B' THEN
    v_n := NVL(v_n, 10000);
    v_t0 := SYSTIMESTAMP;
    -- 표가 없는 동안에도 이 블록이 컴파일돼야 한다. 정적 참조는 못 쓴다.
    FOR i IN 1 .. v_n LOOP
        EXECUTE IMMEDIATE
            'UPDATE PF_WL_T SET amt = amt + 1, memo = ''행별커밋'' WHERE id = :1'
          USING i;
        COMMIT;                    -- ★ 여기가 결함이다
    END LOOP;
    say('[부하] ' || v_n || '행을 ' || v_n || '번 커밋. ' || secs(v_t0) || '초.');
    say(' ');
    say('       같은 일을 한 번만 커밋하면 얼마나 걸리는지 바로 비교한다 :');

    v_t0 := SYSTIMESTAMP;
    EXECUTE IMMEDIATE
        'UPDATE PF_WL_T SET amt = amt + 1, memo = ''일괄커밋'' WHERE id <= :1'
      USING v_n;
    COMMIT;                        -- 한 번만
    say('[비교] 같은 ' || v_n || '행, 커밋 1번. ' || secs(v_t0) || '초.');
    say('       이 두 숫자의 비가 보고서의 핵심 근거다.');


-- ===========================================================================
-- 카드 E : 인덱스 부재 - 같은 조회를 200번 반복한다
-- ---------------------------------------------------------------------------
-- 무엇이 나쁜가
--   MEDICAL_CLAIMS.PAT_ID 에는 인덱스가 없다. 환자 한 명의 청구를 찾을 때마다
--   30만 행을 전부 읽는다. 한 번은 0.006초니 아무도 못 느낀다. 200번이면
--   논리 읽기가 61만 8천 블록이다. 화면 한 장을 그리려고 DB 를 통째로 200번
--   훑는 셈이다.
--
--   ★ 기준 상태가 곧 결함이다 ★
--   걸 것이 없다. 인덱스가 원래 없기 때문이다. 수강생은 AWR 에서 "회당 버퍼가
--   비정상으로 크다" 를 찾아내고, 조치로 인덱스를 만들어야 한다.
--
-- 실측 (2026-10-14, pat_id 1~200 을 각각 COUNT)
--   인덱스 없음 : 논리 읽기 618,000 · 회당 버퍼 3,090 · 1.15초
--   인덱스 있음 : 논리 읽기     602 · 회당 버퍼     3 · 0.00초
--   1,026배다. 회당 버퍼 3,090 에서 3 으로 떨어진다.
--
-- AWR 에서 어디를 보는가
--   - SQL ordered by Buffer Gets 1위. Gets per Exec 가 3,000 을 넘는다
--     (한 행을 세려고 3,090 블록을 읽는다. 이 비율이 결정적 단서다)
--   - Segments by Logical Reads 1위가 MEDICAL_CLAIMS
--   - Instance Activity 의 "table scans (long tables)" 가 호출 수만큼 뛴다
--   - Buffer Pool Advisory : 캐시를 늘려도 안 줄어든다. 읽을 양 자체가 문제다
--   - Top Events 는 조용하다. 전부 버퍼 캐시에서 읽혀 CPU 만 쓴다
--     (★ 대기가 없으니 "대기 이벤트만 보는" 진단으로는 절대 못 잡는다)
--
-- 조치
--   CREATE INDEX ... ON medical_claims (pat_id);
--   보고서에는 맞교환도 적는다 - 인덱스는 DML 을 느리게 하고 공간을 먹는다.
--   이 표가 읽기 위주인지 쓰기 위주인지 근거를 들어야 점수가 된다.
-- ===========================================================================
ELSIF v_card IN ('E', 'EFIX') THEN
    v_n := NVL(v_n, 200);

    IF v_card = 'EFIX' THEN
        -- 강사가 조치의 효과를 미리 확인한다. 수강생에게는 보여 주지 않는다.
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX PF_IX_MC_PAT';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        EXECUTE IMMEDIATE 'CREATE INDEX PF_IX_MC_PAT ON SQLT.medical_claims (pat_id)';
        DBMS_STATS.GATHER_TABLE_STATS('SQLT', 'MEDICAL_CLAIMS',
            METHOD_OPT    => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS SIZE 254 HOSP_ID',
            CASCADE       => TRUE, NO_INVALIDATE => FALSE);
        say('[조치] PF_IX_MC_PAT 를 만들었다 (pat_id). 통계도 다시 수집했다.');
        say('       ★ 이 인덱스는 PF_99_원복.sql 이 지운다.');
    END IF;

    -- 논리 읽기를 직접 센다. AWR 을 기다리지 않고 바로 숫자를 본다.
    SELECT s.value INTO v_cnt
      FROM v$mystat s JOIN v$statname n ON n.statistic# = s.statistic#
     WHERE n.name = 'session logical reads';
    v_t0 := SYSTIMESTAMP;

    FOR i IN 1 .. v_n LOOP
        SELECT COUNT(*) INTO v_dummy FROM sqlt.medical_claims WHERE pat_id = i;
    END LOOP;

    SELECT s.value - v_cnt INTO v_cnt
      FROM v$mystat s JOIN v$statname n ON n.statistic# = s.statistic#
     WHERE n.name = 'session logical reads';

    say('[부하] pat_id 조회 ' || v_n || '번. ' || secs(v_t0) || '초.');
    say('       논리 읽기 ' || TO_CHAR(v_cnt, '999,999,999')
        || ' 블록, 회당 ' || TO_CHAR(ROUND(v_cnt / GREATEST(v_n, 1)), '999,999'));
    say('       ★ 이 "회당" 숫자가 보고서의 핵심 근거다.');
    say('       한 행을 세려고 몇 블록을 읽었는지 묻는 것이다.');


-- ===========================================================================
-- BLOCKER : 카드 F 의 방해자 (SYS 로 실행한다)
-- ---------------------------------------------------------------------------
-- 행 하나를 잡고 지정한 초만큼 쥐고 있는 작업을 띄운다. 스케줄러 작업으로
-- 띄우므로 이 창은 바로 돌아온다. 작업이 끝나면 롤백하고 스스로 사라진다.
-- ===========================================================================
ELSIF v_card = 'BLOCKER' THEN
    v_n := NVL(v_n, 60);
    BEGIN
        DBMS_SCHEDULER.DROP_JOB('PF_BLOCKER_JOB', FORCE => TRUE);
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    DBMS_SCHEDULER.CREATE_JOB(
        JOB_NAME   => 'PF_BLOCKER_JOB',
        JOB_TYPE   => 'PLSQL_BLOCK',
        JOB_ACTION => 'BEGIN
                         UPDATE SQLT.PF_WL_T SET amt = amt + 1 WHERE id = 1;
                         DBMS_SESSION.SLEEP(' || v_n || ');
                         ROLLBACK;
                       END;',
        ENABLED    => TRUE,
        AUTO_DROP  => TRUE,
        COMMENTS   => 'PF 과제 카드 F - 행 1 을 쥐고 있는 방해자');
    say('[방해자] PF_BLOCKER_JOB 을 띄웠다. ' || v_n || '초간 PF_WL_T 의 id=1 을 쥔다.');
    say('         바로 SQLT 창에서  @PF_11_부하패턴.sql F ' || v_n || '  를 돌린다.');
    say('         끝나면 롤백하고 작업은 스스로 사라진다(AUTO_DROP).');


-- ===========================================================================
-- 카드 F : 행 잠금 경쟁
-- ---------------------------------------------------------------------------
-- 무엇이 나쁜가
--   남이 쥔 행을 고치려면 놓을 때까지 기다린다. CPU 도 디스크도 안 쓴다.
--   그냥 멈춰 있다. 그래서 OS 지표(top, iostat)로는 아무 이상이 없어 보인다.
--   "서버는 한가한데 화면이 안 돌아온다" 는 신고가 이 모양이다.
--
-- AWR 에서 어디를 보는가
--   - Top 10 Foreground Events 에 enq: TX - row lock contention
--   - Wait Class 가 Application 으로 쏠린다
--   - DB Time 은 크게 늘었는데 DB CPU 는 거의 안 늘었다 (★ 결정적 단서)
--   - ASH 가 더 낫다 : 누가 누구를 막았는지 BLOCKING_SESSION 으로 나온다
--     PF_20 의 ASH 명령을 쓴다. AWR 은 "무엇을 기다렸나" 까지만 말해 준다.
--
-- 실측 (2026-10-14, 방해자가 45초간 쥐고 있을 때)
--   44.18초 기다린 뒤 잠금을 얻었다.
--   V$SESSION 의 EVENT = 'enq: TX - row lock contention'
--
--   ★ BLOCKING_SESSION 은 대기 중에만 보인다 ★
--   실측에서 이 값이 비어 있었다. 잠금을 얻은 뒤에 조회했기 때문이다.
--   EVENT 는 마지막 대기로 남아 있지만 막은 세션은 이미 풀려 NULL 이 된다.
--   누가 누구를 막았는지 보려면 기다리는 동안 다른 창에서 V$SESSION 을
--   조회하거나, 지나간 일이라면 ASH 를 본다. ASH 가 그 순간을 저장해 둔다.
--
-- 조치
--   애플리케이션의 트랜잭션 경계를 줄인다. 잠금을 쥔 채 사용자 입력을
--   기다리는 설계를 고친다. DB 설정으로 풀 수 있는 문제가 아니다.
-- ===========================================================================
ELSIF v_card = 'F' THEN
    v_n := NVL(v_n, 60);
    say('[부하] 방해자가 쥔 행을 기다린다. 최대 ' || v_n || '초.');
    v_t0 := SYSTIMESTAMP;
    BEGIN
        EXECUTE IMMEDIATE
            'UPDATE PF_WL_T SET amt = amt + 1 WHERE id = 1';
        ROLLBACK;
        say('[부하] ' || secs(v_t0) || '초 기다린 뒤 잠금을 얻었다.');
        IF secs(v_t0) < 2 THEN
            say('       ★ 너무 빨리 끝났다. 방해자가 안 떠 있었다.');
            say('       SYS 창에서 BLOCKER 를 먼저 띄우고 다시 돌린다.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        say('[부하] ' || secs(v_t0) || '초 뒤 오류 : ' || SQLERRM);
    END;

    -- 누가 막았는지 지금 보여 준다 (보고서에는 ASH 로 다시 확인하게 한다)
    say(' ');
    FOR r IN (SELECT s.sid, s.event, s.blocking_session, s.seconds_in_wait
                FROM v$session s
               WHERE s.event LIKE 'enq: TX%') LOOP
        say('       대기 중 : SID ' || r.sid || ' / ' || r.event
            || ' / 막은 세션 ' || NVL(TO_CHAR(r.blocking_session), '-')
            || ' / ' || r.seconds_in_wait || '초');
    END LOOP;


-- ===========================================================================
-- 카드 G : 작업 영역 축소 - 정렬이 디스크로 넘친다
-- ---------------------------------------------------------------------------
-- 무엇이 나쁜가
--   정렬·해시 조인은 PGA 안에서 끝나야 빠르다. 작업 영역이 모자라면
--   임시 테이블스페이스로 넘긴다(spill). 메모리에서 하던 일을 디스크에서 한다.
--
--   ★ 세션 수준으로만 바꾼다 ★ ALTER SYSTEM 을 쓰지 않는다.
--   접속을 끊으면 원래대로 돌아온다. 그래서 되돌릴 것이 없다.
--
-- 실측 (2026-10-14, claim_details 90만 행을 claim_id 로 묶어 30만 그룹)
--   AUTO          : 0.13초, 메모리 27M 사용, 디스크 안 씀
--   MANUAL 64KB   : 1.78초, 읽기/쓰기 12,627/12,627 블록, 임시 37M
--   V$SQL_WORKAREA : LAST_MEMORY_USED 28,385,280 -> 840,704
--                    LAST_TEMPSEG_SIZE 0 -> 38,797,312
--
--   ★ 시간은 믿지 말고 임시 I/O 를 본다 ★
--   같은 스크립트를 다시 돌렸을 때는 0.89초 -> 1.21초로 차이가 작았다.
--   버퍼 캐시가 더워져 있으면 시간 차이가 줄어든다. 그런데 임시
--   테이블스페이스 읽기/쓰기 12,627 블록은 두 번 다 똑같이 나왔다.
--   이 카드의 근거는 경과 시간이 아니라 그 12,627 이다.
--
--   또 하나 : MANUAL 정책에서는 workarea executions 통계가 안 쌓인다.
--   실측에서 optimal 6 / onepass 0 / multipass 0 이고 sorts (disk) 도 0 이었다.
--   디스크로 넘쳤는데 그 통계에는 안 잡힌다. AUTO 정책에서만 집계되기
--   때문이다. 해시 집계라 sorts 통계에도 안 들어간다.
--   "통계가 0 이니 디스크 정렬이 없었다" 고 읽으면 틀린다.
--
-- AWR 에서 어디를 보는가
--   - Top 10 Events 에 direct path write temp / direct path read temp
--   - Instance Activity 의 "sorts (disk)" 가 0 이 아니다
--   - PGA Aggr Target Stats 의 "W/A MB processed" 와 1-pass 실행 수
--   - Tablespace IO Stats 에 TEMP 가 올라온다
--   - Segments by ... 에는 안 나온다. 임시 세그먼트는 사용자 객체가 아니다.
-- ===========================================================================
ELSIF v_card = 'G' THEN
    v_t0 := SYSTIMESTAMP;
    EXECUTE IMMEDIATE 'ALTER SESSION SET workarea_size_policy = AUTO';
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM (SELECT d.claim_id, COUNT(*) c, SUM(d.amt) s
                                 FROM SQLT.claim_details d GROUP BY d.claim_id)'
      INTO v_dummy;
    say('[기준] AUTO (메모리 정렬) : ' || secs(v_t0) || '초, 그룹 ' || v_dummy || '개');

    EXECUTE IMMEDIATE 'ALTER SESSION SET workarea_size_policy = MANUAL';
    EXECUTE IMMEDIATE 'ALTER SESSION SET sort_area_size = 65536';
    EXECUTE IMMEDIATE 'ALTER SESSION SET hash_area_size = 131072';
    say('[주입] 세션 작업 영역을 MANUAL 64KB 로 줄였다.');

    v_t0 := SYSTIMESTAMP;
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM (SELECT d.claim_id, COUNT(*) c, SUM(d.amt) s
                                 FROM SQLT.claim_details d GROUP BY d.claim_id)'
      INTO v_dummy;
    say('[부하] MANUAL 64KB (디스크 정렬) : ' || secs(v_t0) || '초');

    FOR r IN (SELECT n.name, s.value
                FROM v$mystat s JOIN v$statname n USING (statistic#)
               WHERE n.name IN ('sorts (memory)', 'sorts (disk)',
                                'physical reads direct temporary tablespace',
                                'physical writes direct temporary tablespace',
                                'workarea executions - optimal',
                                'workarea executions - onepass',
                                'workarea executions - multipass')) LOOP
        say('       ' || RPAD(r.name, 48) || r.value);
    END LOOP;

    EXECUTE IMMEDIATE 'ALTER SESSION SET workarea_size_policy = AUTO';
    say('[원복] 세션 정책을 AUTO 로 돌렸다. 접속을 끊어도 돌아온다.');


-- ===========================================================================
-- 카드 I : 호출 횟수 폭주 - 회당은 빠른데 횟수가 많다
-- ---------------------------------------------------------------------------
-- 무엇이 나쁜가
--   청구 3만 건을 돌면서, 각 건의 병원 이름을 따로 조회한다. 조회 하나하나는
--   HOSPITALS(1,000행)의 PK 유니크 조회다. 회당 2~3 블록, 0.1ms. 실행 계획도
--   완벽하다. 그런데 3만 번이면 합계가 커진다.
--   SQL 을 하나씩 튜닝해서는 절대 못 고친다. 호출 구조를 고쳐야 한다.
--   N+1 문제라고 부른다. ORM 을 쓰는 애플리케이션에서 흔하다.
--
-- 처음 설계가 틀렸던 것 (2026-10-14)
--   claim_details 를 claim_id 로 3만 번 조회하게 만들었더니, 그 컬럼에
--   인덱스가 없어 회당 6,621 블록짜리 전체 스캔이 3만 번 돌았다. 74초를
--   넘겨도 안 끝나 세션을 끊었다. 그건 카드 E(인덱스 부재)지 카드 I 가 아니다.
--   카드 I 가 성립하려면 ★ 회당이 정말 빨라야 ★ 한다.
--
-- AWR 에서 어디를 보는가
--   - SQL ordered by Executions 1위. Elapsed per Exec 는 0.00 에 가깝다
--   - SQL ordered by Elapsed Time 에서도 상위인데, 회당으로 나누면 아무것도 아니다
--     (PF_20 의 TOPSQL 이 "회당_초" 와 "실행" 을 나란히 놓는 이유다)
--   - Load Profile 의 Executes 와 "SQL*Net roundtrips" 가 같이 높다
--   - Top Events 에 SQL*Net message from client (왕복 자체가 비용이다)
--
-- 실측 (2026-10-14, 30,000번)
--   1건씩 30,000번 : 0.16초 · 논리 읽기 90,624 블록 · 회당 3.0 블록
--   조인 한 번     : 0.01초
--   16배다. 회당 3 블록짜리 완벽한 SQL 을 30,000번 부른 결과다.
--   AWR 에서는 경과 시간보다 Executions 30,000 이라는 숫자가 먼저 눈에 띈다.
--
-- 조치
--   한 번의 조인이나 배치 조회로 바꾼다. SQL 을 고치는 게 아니라 호출을 줄인다.
-- ===========================================================================
ELSIF v_card = 'I' THEN
    v_n := NVL(v_n, 30000);

    -- 논리 읽기를 같이 센다. 회당 몇 블록인지 보여야 이 카드가 성립한다.
    SELECT s.value INTO v_cnt
      FROM v$mystat s JOIN v$statname n ON n.statistic# = s.statistic#
     WHERE n.name = 'session logical reads';
    v_t0 := SYSTIMESTAMP;
    v_dummy := 0;

    FOR r IN (SELECT hosp_id FROM sqlt.medical_claims WHERE ROWNUM <= v_n) LOOP
        -- 청구 한 건마다 병원 이름을 따로 조회한다. ★ 여기가 결함이다
        -- HOSPITALS 는 1,000행, PK 유니크 조회다. 이 SQL 자체는 완벽하다.
        SELECT hosp_name INTO v_str
          FROM sqlt.hospitals WHERE hosp_id = r.hosp_id;
        v_dummy := v_dummy + 1;
    END LOOP;

    SELECT s.value - v_cnt INTO v_cnt
      FROM v$mystat s JOIN v$statname n ON n.statistic# = s.statistic#
     WHERE n.name = 'session logical reads';

    say('[부하] 1건씩 ' || v_dummy || '번 조회. ' || secs(v_t0) || '초.');
    say('       논리 읽기 ' || TO_CHAR(v_cnt, '999,999,999')
        || ' 블록, 회당 ' || ROUND(v_cnt / GREATEST(v_dummy, 1), 1) || ' 블록');
    say('       회당 몇 블록. 이 SQL 은 아무 문제가 없다. 그게 함정이다.');

    say(' ');
    say('       같은 결과를 조인 한 번으로 내면 :');
    v_t0 := SYSTIMESTAMP;
    SELECT COUNT(*) INTO v_cnt FROM (
        SELECT c.hosp_id, h.hosp_name
          FROM (SELECT hosp_id FROM sqlt.medical_claims WHERE ROWNUM <= v_n) c
          JOIN sqlt.hospitals h ON h.hosp_id = c.hosp_id);
    say('[비교] 조인 1번으로 ' || v_cnt || '건. ' || secs(v_t0) || '초.');
    say('       회당 시간으로는 1건 조회가 더 짧다. 그런데 합계가 몇십 배다.');
    say('       "느린 SQL 을 찾아라" 로는 절대 안 잡히는 문제다.');


-- ===========================================================================
-- 카드 J : 짧은 폭주 - AWR 평균에 묻히고 ASH 에만 보인다
-- ---------------------------------------------------------------------------
-- 무엇이 나쁜가
--   나쁜 것은 부하가 아니라 우리가 보는 방법이다. 1시간 구간의 AWR 은
--   그 안의 3초짜리 폭주를 1/1200 로 희석한다. 평균은 멀쩡하다.
--   "오전 10시 12분에 3초간 멈췄다" 는 신고를 AWR 로 재현할 수 없는 이유다.
--
-- 이 카드가 요구하는 것
--   1) 구간을 짧게 잡는다 (스냅샷을 직접 만든다 - PF_20 의 SNAP 이 그 일을 한다)
--   2) 또는 ASH 를 본다. ASH 는 1초마다 샘플을 남긴다
--   3) 두 방법으로 본 결과를 보고서에 나란히 놓고, 왜 다른지 쓴다
--
-- AWR 에서 어디를 보는가
--   - 1시간 구간 AWR : 아무 이상 없다. 그게 결론이다
--   - 같은 시각 ASH  : Top Events 와 Top SQL 에 폭주가 또렷하다
--   - V$ACTIVE_SESSION_HISTORY 를 1초 단위로 세어 보면 봉우리가 보인다
--
-- 실측 (2026-10-14)
--   조용 3초 -> 폭주 3.88초 -> 조용 3초, 전체 9.99초
--   폭주 구간만 디스크 정렬이 돈다.
--
-- 조치
--   문제는 DB 가 아니라 관측 해상도다. 짧은 장애는 ASH 로 본다.
--   스냅샷 주기를 줄이는 것은 SYSAUX 를 먹으니 신중해야 한다.
-- ===========================================================================
ELSIF v_card = 'J' THEN
    say('[부하] 조용히 10초를 보낸다. 그중 3초만 폭주한다.');

    -- 조용한 구간 (3초)
    v_t0 := SYSTIMESTAMP;
    WHILE secs(v_t0) < 3 LOOP
        SELECT COUNT(*) INTO v_dummy FROM sqlt.hospitals WHERE hosp_id = 1;
        DBMS_SESSION.SLEEP(0.3);
    END LOOP;
    say('       [1] 조용 3초 - 가벼운 조회만');

    -- 폭주 구간 (3초). 정렬을 디스크로 넘겨 대기를 만든다.
    EXECUTE IMMEDIATE 'ALTER SESSION SET workarea_size_policy = MANUAL';
    EXECUTE IMMEDIATE 'ALTER SESSION SET sort_area_size = 65536';
    v_t0 := SYSTIMESTAMP;
    WHILE secs(v_t0) < 3 LOOP
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM (SELECT d.claim_id, COUNT(*) c
                                     FROM SQLT.claim_details d GROUP BY d.claim_id)'
          INTO v_dummy;
    END LOOP;
    EXECUTE IMMEDIATE 'ALTER SESSION SET workarea_size_policy = AUTO';
    say('       [2] 폭주 ' || secs(v_t0) || '초 - 디스크 정렬');

    -- 다시 조용한 구간 (3초)
    v_t0 := SYSTIMESTAMP;
    WHILE secs(v_t0) < 3 LOOP
        SELECT COUNT(*) INTO v_dummy FROM sqlt.hospitals WHERE hosp_id = 1;
        DBMS_SESSION.SLEEP(0.3);
    END LOOP;
    say('       [3] 조용 3초');
    say(' ');
    say('       이제 두 가지로 본다.');
    say('        - 10초 구간을 덮는 AWR : 폭주가 평균에 희석된다');
    say('        - 같은 시각 ASH        : 폭주 3초가 또렷하다');
    say('       1시간 구간이라면 차이가 훨씬 크다. 보고서에 그 점을 적는다.');


ELSE
    say('[안내] 카드는 A · B · F · G · I · J 중 하나다.');
    say('       C · D · E · H 는 환경 결함이라 PF_10_시나리오주입.sql 로');
    say('       SYS 세션에서 건다.');
    say('       그 밖에 PREP(복제표 준비) 와 BLOCKER(카드 F 방해자) 가 있다.');
END IF;

END;
/

SET TIMING OFF
SET FEEDBACK ON
UNDEFINE pf_card
UNDEFINE pf_n
