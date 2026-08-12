# Oracle PL/SQL 교안 — 실습 트랜스크립트 주제 목록 (v1)

- **소스**: `PLSQL_PRD.md` 섹션 9~15(챕터별 주요 내용) 기준
- **형식**: SQL*Plus 세션 트랜스크립트(`SQL>` 프롬프트, PL/SQL 블록 + `DBMS_OUTPUT.PUT_LINE` 결과 + 한글 주석, 컴파일 오류/런타임 예외 → 원인 파악 → 수정 흐름 포함)
- **기준 스키마**: HR (EMPLOYEES/DEPARTMENTS/JOBS/JOB_HISTORY/LOCATIONS/COUNTRIES/REGIONS)

## 1장. PL/SQL 기초 (6개)
1. Anonymous Block 구조(DECLARE/BEGIN/EXCEPTION/END) 확인
2. 변수 선언과 %TYPE/%ROWTYPE 활용 실습
3. SELECT INTO로 단일 행 조회 및 NO_DATA_FOUND 처리 실습
4. DBMS_OUTPUT.PUT_LINE을 이용한 출력 실습
5. IF문과 CASE문 활용 실습
6. 상수 선언 및 스코프(중첩 블록) 확인 실습

## 2장. 반복문과 커서 (7개)
1. 기본 LOOP / EXIT WHEN 구조 실습
2. WHILE LOOP와 FOR LOOP 비교 실습
3. Explicit Cursor 선언·OPEN·FETCH·CLOSE 실습
4. Cursor FOR LOOP 실습
5. Parameterized Cursor 실습
6. Cursor Attribute(%FOUND/%NOTFOUND/%ROWCOUNT/%ISOPEN) 실습
7. EMPLOYEES-DEPARTMENTS 조인 기반 중첩 Cursor 처리 실습

## 3장. 예외 처리·트랜잭션·컬렉션 (8개)
1. 사전 정의 예외(NO_DATA_FOUND/TOO_MANY_ROWS/ZERO_DIVIDE/VALUE_ERROR) 처리 실습
2. 사용자 정의 예외 선언 및 RAISE 실습
3. SQLCODE/SQLERRM으로 오류 정보 조회 실습
4. OTHERS 예외 처리와 예외 전파 실습
5. COMMIT/ROLLBACK/SAVEPOINT를 이용한 트랜잭션 제어 실습
6. Associative Array 선언 및 활용 실습
7. Nested Table과 VARRAY 비교 실습
8. BULK COLLECT로 대량 데이터 수집 실습

## 4장. 프로시저와 함수 (6개)
1. Procedure 생성과 IN/OUT/IN OUT 파라미터 실습
2. Function 생성과 RETURN 값 활용 실습
3. 파라미터 기본값(DEFAULT)과 Local Variable 실습
4. SQL 문장 내에서 Function 호출 실습
5. Stored Program 컴파일 오류(USER_ERRORS/SHOW ERRORS) 확인 및 수정 실습
6. Procedure/Function 재컴파일 및 삭제 실습

## 5장. 패키지와 트리거 (7개)
1. Package Specification과 Body 분리 작성 실습
2. Public/Private 요소와 Package 변수(상태 유지) 실습
3. Package Procedure/Function 호출 실습
4. BEFORE/AFTER Row Trigger와 :OLD/:NEW 활용 실습
5. Statement Trigger 실습
6. INSTEAD OF Trigger 개념 확인
7. Trigger 비활성화/활성화 및 실행 순서 확인 실습

## 6장. 동적 SQL과 DBA 자동화 (8개)
1. EXECUTE IMMEDIATE로 정적 SQL과 동적 SQL 비교 실습
2. Bind Variable을 이용한 Dynamic DML 실습
3. Dynamic DDL 실행 실습
4. Dynamic SELECT 결과 처리 실습
5. DBMS_SQL 개요 확인
6. USER_OBJECTS/USER_TABLES/USER_PROCEDURES로 스키마 객체 점검 실습
7. DBA_OBJECTS/DBA_USERS/DBA_TABLESPACES 조회 실습(DBA 권한 필요)
8. Dynamic SQL Injection 위험성 확인 및 Bind Variable 방어 실습

## 7장. 스케줄러·모니터링·운영 자동화 (8개)
1. DBMS_SCHEDULER.CREATE_JOB으로 Job 생성 실습
2. Program과 Schedule 분리 생성 및 Job 연결 실습
3. Job 실행/중지/삭제(RUN_JOB/STOP_JOB/DROP_JOB) 실습
4. Job 실행 이력 조회(DBA_SCHEDULER_JOB_RUN_DETAILS) 실습
5. 실패 Job 확인 및 오류 로그 기록 실습
6. `plsql_job_log`/`dba_check_result` 테이블을 이용한 운영 로그 기록 실습
7. CHECK_INVALID_OBJECT/CHECK_USER_STATUS 자동화 프로시저 실습
8. PKG_DBA_AUTOMATION 패키지 기반 통합 자동화 실행 실습

---

## 총계
7개 챕터, **총 50개** 트랜스크립트 (챕터별 6~8개, 콘텐츠 분량에 비례 배분)
