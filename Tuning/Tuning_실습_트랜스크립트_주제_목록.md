# Oracle Database 19c 성능 튜닝 교안 — 실습 트랜스크립트 주제 목록 (v2)

- **형식**: SQL\*Plus 세션 트랜스크립트(`SYS@orcl>` 프롬프트, 한글 주석). 각 파일 최소 1곳 **"오류·이상 징후 발생 → 원인 파악 → 조치 → 재확인"** 흐름 포함
- **파일명**: `{N}장_실습_{NN}_{주제}.txt`
- **총 20장 / 110개** (v1 18장 96개 → 12·15장 신설로 +14)
- **공통 전제**: 개인 실습 환경 전용. 파라미터 변경·재기동·부하 유발이 포함된다
- **부하**: 과정 공용 스크립트 `WL_01`~`WL_06`(챕터 목록 4-1) 사용. 부하 없이는 성립하지 않는 챕터를 ★로 표시했다
- **라이선스**: Diagnostics Pack이 필요한 실습은 🔒로 표시했다. 해당 실습에는 **라이선스 없이 같은 것을 보는 대안 경로**를 트랜스크립트 후반에 함께 넣는다

---

## 1장. 성능 튜닝 개요 (5개)
1. 현재 인스턴스의 응답시간·처리량 지표를 각각 조회하고 무엇이 다른지 확인
2. 성능 도구 지도 확인 — V$ 뷰 / AWR / ADDM / ASH / Advisor 각각의 진입점
3. **라이선스 확인 실습** — `DBA_FEATURE_USAGE_STATISTICS`로 관리 팩 사용 이력 조회, `CONTROL_MANAGEMENT_PACK_ACCESS` 설정별 접근 차이 확인
4. 튜닝 목표를 수치로 정의하는 실습 — 대상 업무 선정, 현재값 측정, 목표값 설정
5. 진료비 스키마 실습 환경 점검 — 객체·건수·통계 상태 확인(전 챕터 공통 기준선)

## 2장. 성능을 고려한 설계와 개발 ★ (5개)
1. `WL_01_parse.sql` 실행 — 바인드 변수 유무에 따른 라이브러리 캐시 커서 수 비교
2. `CURSOR_SHARING` 설정별 동작 확인
3. 커넥션 획득 비용 측정 — 접속 반복 vs 커넥션 재사용
4. 배열 처리(`arraysize`) 변경에 따른 왕복 횟수와 논리 읽기 변화 확인
5. 시퀀스 경합 재현 — 오류 없이 대기로만 드러나는 확장성 문제 확인

## 3장. 성능 개선 방법론과 긴급 대응 ★ (5개)
1. Oracle Performance Improvement Method 절차대로 현재 인스턴스 1회 진단
2. `WL_04_lock.sql`로 응급 상황 재현 — 자원 독점 세션 식별·차단 절차
3. 라이브러리 캐시 경합 상황에서 원인 SQL 지목
4. 블로킹 세션 추적과 해소(`V$SESSION.BLOCKING_SESSION`, `DBA_BLOCKERS`)
5. 진단 근거를 남기는 절차 — 조치 전 스냅샷·상태 캡처 실습

## 4장. 성능을 위한 데이터베이스 구성 (5개)
1. 초기화 파라미터 중 성능 관련 항목 일괄 점검(`V$PARAMETER` 필터링)
2. Undo 보존과 `ORA-01555` 재현 → `UNDO_RETENTION`·테이블스페이스 조정
3. 임시 테이블스페이스 사용량 추적과 부족 상황 재현(`ORA-01652`)
4. 전용 서버 vs 공유 서버 접속 방식 비교 — 프로세스·메모리 차이 확인
5. 블록 크기와 행 이주(row migration) 관찰(`ANALYZE ... LIST CHAINED ROWS`)

## 5장. 성능 측정의 기준 — 통계와 DB Time ★ (6개)
1. `V$SYS_TIME_MODEL`로 DB Time 구성 확인 — CPU와 대기의 비율
2. `V$SESS_TIME_MODEL`로 특정 세션의 시간 사용 분해
3. 대기 클래스별 집계(`V$SYSTEM_WAIT_CLASS`)와 상위 클래스 지목
4. `STATISTICS_LEVEL` 수준별로 수집되는 통계 차이 확인
5. `WL_06_mixed.sql` 전후 DB Time 증가분 측정 — 델타 계산 방식 실습
6. 누적값을 그대로 해석했을 때의 오판 재현과 델타 방식 교정

## 6장. 통계 수집 ① 자동 수집과 AWR 인프라 ★🔒 (6개)
1. AWR 스냅샷 주기·보존 기간 확인과 변경(`DBMS_WORKLOAD_REPOSITORY`)
2. `WL_06_mixed.sql`을 사이에 두고 수동 스냅샷 쌍 확보
3. AWR 베이스라인 생성·조회·삭제
4. 보존 기간 초과로 데이터가 사라지는 상황 확인 → 필요한 구간을 베이스라인으로 보호
5. SYSAUX 사용량 추적 — AWR이 차지하는 공간 확인과 정리
6. **대안 경로** — Statspack 설치·스냅샷 수집·보고서 생성, AWR과의 차이 확인

## 7장. 통계 수집 ② 히스토그램·확장 통계·시스템 통계 (7개)
1. 편중 컬럼(HOSP_ID 1~50 집중)에 히스토그램 유무별 카디널리티 추정 차이 확인
2. `METHOD_OPT` 지정 방식별 히스토그램 생성 결과 비교
3. 컬럼 그룹 확장 통계 생성 — 상관관계 있는 두 컬럼의 추정 개선 확인
4. 표현식 통계 생성 — 함수 적용 컬럼의 추정 개선 확인
5. 시스템 통계 수집(`GATHER_SYSTEM_STATS`)과 수집 전후 계획 변화 관찰
6. 통계 Preferences 설정(`SET_TABLE_PREFS` 등)과 적용 범위 확인 *(ADMIN 33장 심화)*
7. Optimizer Statistics Advisor 실행과 권고 해석 → 통계 부재·과다 오차 해소 *(ADMIN 33장 심화)*

## 8장. AWR 보고서 읽기 ★🔒 (7개)
1. 텍스트 AWR 보고서 생성(`awrrpt.sql`)과 섹션 구조 확인
2. Load Profile 판독 — 초당 논리 읽기·파싱·트랜잭션 수 해석
3. Top 10 Foreground Events 판독 — 상위 대기와 DB Time 비중 지목
4. SQL Ordered by Elapsed Time / Gets / Reads 섹션에서 대상 SQL 선별
5. Instance Activity Stats에서 이상 지표 찾기
6. Advisory 섹션(버퍼 캐시·공유 풀·PGA) 판독과 권고 크기 확인
7. 부하 없는 구간의 보고서를 읽고 "문제 없음"을 근거와 함께 판정

## 9장. ADDM — 자동 진단 결과 해석 ★🔒 (5개)
1. ADDM 태스크 실행과 보고서 생성(`addmrpt.sql` / `DBMS_ADDM`)
2. Finding·Recommendation·Rationale 구조 확인과 영향도(Impact) 해석
3. ADDM 분석 모드 확인 — DB 전체 vs 특정 인스턴스 구간(non-CDB 환경) / CDB 환경에서의 차이는 개념으로만 언급
4. ADDM 뷰 직접 조회(`DBA_ADDM_FINDINGS`, `DBA_ADVISOR_*`)
5. 권고를 그대로 따르면 안 되는 사례 판별 — 근거 없는 채택 방지

## 10장. ASH — 샘플링 데이터로 특정 시점 추적 ★🔒 (6개)
1. `V$ACTIVE_SESSION_HISTORY` 구조와 샘플링 주기 확인
2. ASH 보고서 생성(`ashrpt.sql`)과 구간 지정
3. 특정 10분 구간의 상위 세션·SQL·대기 이벤트 도출
4. 세션 단위 추적 — 한 세션이 무엇을 기다렸는지 시간순 재구성
5. `DBA_HIST_ACTIVE_SESS_HISTORY`로 보존 구간 분석
6. AWR로는 안 보이고 ASH로만 보이는 짧은 스파이크 재현

## 11장. 기간 비교 ★🔒 (5개)
1. Compare Periods 보고서 생성(`awrddrpt.sql`)
2. 두 기간의 Load Profile 차이 판독
3. SQL 단위 회귀 탐지 — 실행계획 변경으로 느려진 SQL 식별
4. 베이스라인 대비 비교 수행
5. 부하 증가 때문인지 성능 저하 때문인지 구분하는 판정 실습

## 12장. 경고·메트릭 기반 상시 모니터링 ★ (7개) *(ADMIN 32장 흡수·심화)*
1. 서버 생성 알림 구조 확인 — Stateful/Stateless 구분과 `DBA_OUTSTANDING_ALERTS`·`DBA_ALERT_HISTORY`
2. 메트릭 임계값 설정(`DBMS_SERVER_ALERT.SET_THRESHOLD`)과 현재 설정 조회
3. **임계값을 얼마로 잡을 것인가** — `DBA_HIST_*` 이력에서 평시 분포를 뽑아 근거 있는 임계값 산정
4. 테이블스페이스 사용률 알림 발생·해제 전 과정 재현
5. `WL_04_lock.sql`로 경합 유발 → 알림 발생 시 대응 절차(무엇부터 보는가) 실습
6. 세션 모니터링 — 활성 세션 추적, 장기 실행 작업(`V$SESSION_LONGOPS`) 확인
7. 서비스 단위 모니터링(`V$SERVICE_STATS`, `V$SERVICEMETRIC`)과 업무별 성능 분리 관찰

## 13장. V$ 뷰 인스턴스 튜닝 ① 절차와 통계 해석 (5개)
1. 실시간 진단 경로 실습 — 세션 → 대기 → SQL → 세그먼트 순 추적
2. `V$SYSSTAT` 주요 통계 델타 계산과 해석
3. `V$SESSION`·`V$SESSION_WAIT`로 현재 활동 파악
4. `V$SQL` 정렬 기준별(실행시간·논리읽기·실행횟수) 상위 SQL 선별
5. 절대값만 보고 내린 오판을 델타·비율로 교정

## 14장. V$ 뷰 인스턴스 튜닝 ② 대기 이벤트 분석 ★ (7개)
1. 대기 이벤트 분류 체계 확인(`V$EVENT_NAME`, 클래스별)
2. `WL_02_io.sql`로 `db file sequential read` / `scattered read` 유발과 구분
3. `buffer busy waits` 재현과 원인 세그먼트 지목(`V$SEGMENT_STATISTICS`)
4. `WL_05_commit.sql`로 `log file sync` 재현 — 커밋 빈도와의 관계 확인
5. latch / mutex 경합 관찰 — 라이브러리 캐시 경합 상황
6. `WL_04_lock.sql`로 enqueue 대기(`enq: TX - row lock contention`) 재현과 블로커 추적
7. Idle 이벤트를 병목으로 오판하는 사례 재현과 교정

## 15장. Advisor 프레임워크와 자동 튜닝 (8개) *(ADMIN 29·30·33장 흡수·심화)*
1. 자동 유지관리 작업 구성 확인 — 어떤 작업이 언제 도는가(`DBA_AUTOTASK_*`)
2. 유지관리 윈도우 조정과 리소스 할당 변경 — 자동 작업이 업무 시간에 영향을 주는 상황 재현·해소
3. Advisory Framework 전반 확인(`DBA_ADVISOR_DEFINITIONS`)과 어드바이저별 진입점
4. SQL Tuning Advisor 수동 실행 — 권고(프로파일·인덱스·재작성) 해석
5. SQL Tuning Advisor 자동 실행 결과 조회와 자동 채택 정책 확인
6. SQL Access Advisor 실행 — 인덱스·MV 권고와 채택 판단
7. SQL Performance Analyzer로 변경 전후 비교 — 파라미터 변경이 SQL 집합에 미치는 영향 측정
8. SQL Plan Directives·Adaptive Plans 관찰 — 계획이 실행 중 바뀌는 상황 확인과 비활성화 판단

## 16장. 데이터베이스 메모리 할당 구조 (5개)
1. 현재 메모리 관리 방식 판별(AMM / ASMM / 수동)과 관련 파라미터 확인
2. AMM 구성과 `MEMORY_TARGET` 조정 후 재기동 확인
3. ASMM으로 전환하고 `SGA_TARGET`·`PGA_AGGREGATE_TARGET` 동작 확인
4. 자동 조정 이력 추적(`V$SGA_RESIZE_OPS`, `V$MEMORY_RESIZE_OPS`)
5. 메모리 부족 상황 재현(`ORA-04031`) → 구성 조정으로 해소

## 17장. SGA 튜닝 ① 버퍼 캐시와 리두 로그 버퍼 ★ (6개)
1. 버퍼 캐시 구성과 현재 크기·사용률 확인
2. **캐시 히트율의 함정 재현** — 히트율은 높은데 응답시간이 나쁜 상황 만들기
3. 버퍼 캐시 어드바이저(`V$DB_CACHE_ADVICE`)로 크기 변경 효과 예측
4. 다중 버퍼 풀 구성 — KEEP 풀에 소형 참조 테이블(DRUG_MASTER 등) 배치 후 효과 확인
5. RECYCLE 풀 구성과 대량 스캔 대상 분리
6. 리두 로그 버퍼 크기와 `log buffer space` 대기 관찰

## 18장. SGA 튜닝 ② 공유 풀과 라지 풀 ★ (6개)
1. 라이브러리 캐시 구성 확인(`V$LIBRARYCACHE`)과 재파싱 지표 판독
2. `WL_01_parse.sql`로 하드 파싱 유발 후 공유 풀 사용량 변화 관찰
3. 커서 공유 설정별 공유 풀 점유 비교
4. 공유 풀 어드바이저(`V$SHARED_POOL_ADVICE`) 판독
5. `ORA-04031` 재현과 원인 영역 식별 → 예약 풀·크기 조정으로 해소
6. 라지 풀 구성 — 병렬 처리·RMAN 버퍼가 공유 풀을 침범하지 않게 분리

## 19장. 결과 캐시와 PGA 튜닝 ★ (6개)
1. 서버 결과 캐시 활성화와 `RESULT_CACHE` 힌트 적용 효과 확인
2. 결과 캐시 무효화 관찰 — 기반 테이블 변경 시 동작
3. 결과 캐시 모니터링(`V$RESULT_CACHE_STATISTICS`)과 적용 부적합 사례 판별
4. PGA 작업 영역 확인(`V$PGASTAT`, `V$SQL_WORKAREA`)
5. **1-pass·multi-pass 정렬 재현** — PGA 축소 후 `WL_03_sort.sql` 실행, 임시 테이블스페이스 사용 관찰
6. `PGA_AGGREGATE_LIMIT` 초과 상황 재현(`ORA-04036`)과 조정

## 20장. I/O 구성과 OS 자원 관리 ★ (7개)
1. 데이터파일별 I/O 분포 확인(`V$FILESTAT`)과 편중 판별
2. I/O 캘리브레이션 수행(`DBMS_RESOURCE_MANAGER.CALIBRATE_IO`)과 결과 해석
3. 비동기 I/O 설정 확인(`FILESYSTEMIO_OPTIONS`, `DISK_ASYNCH_IO`)
4. 다중 블록 읽기 크기와 전체 스캔 성능 관계 확인
5. OS 수준 CPU 사용률과 DB 통계 대조 — 병목이 DB 안인지 밖인지 판별
6. 메모리 스와핑 징후 확인과 SGA 크기 재검토
7. 네트워크 지연이 원인일 때의 판별 — `SQL*Net message from client` 오해 사례 교정

---

## 부록. 챕터별 요약

| 구분 | 챕터 | 실습 수 |
|---|---|---|
| 기초·방법론 | 1~4 | 20 |
| 측정·진단 | 5~11 | 42 |
| 상시 모니터링 | 12 | 7 |
| 인스턴스 튜닝 | 13~14 | 12 |
| 어드바이저 | 15 | 8 |
| 메모리·자원 | 16~20 | 30 |
| **합계** | **20장** | **110** |

★(부하 필요) 12개 챕터 / 🔒(Diagnostics Pack 필요) 5개 챕터 29개 실습 — 전부 대안 경로를 함께 싣는다.
