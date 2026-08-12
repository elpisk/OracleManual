# Oracle PL/SQL 교안 — 챕터 목록 (v1)

- **소스 PRD**: `C:\Users\itwill\Downloads\OracleManual\PLSQL\PLSQL_PRD.md` (Oracle PL/SQL 7-Day Practical & DBA Automation Training, v1.0)
- **대상**: PL/SQL 입문 개발자 + Oracle DBA
- **기준 데이터**: Oracle HR Sample Schema (REGIONS/COUNTRIES/LOCATIONS/DEPARTMENTS/JOBS/EMPLOYEES/JOB_HISTORY)
- **산출물 파이프라인**: `ADMIN`(19c DBA 34챕터) 프로젝트와 **동일한 방식 재사용** — PRD의 "70문제+30문제+최종프로젝트" 형태가 아니라, ADMIN에서 검증된 챕터당 산출물 세트를 그대로 따른다.

## 챕터당 산출물 (ADMIN과 동일, 총 13~16개 파일)

| # | 파일 | 규격 |
|---|---|---|
| 1 | `{N}장_{제목}.docx` | 본문, 20~30페이지(26,000~30,000자), Heading1/2/3, 맑은 고딕/Consolas 코드블록, Note(노랑)/Best Practice(녹색)/실무시나리오(파랑)/Quiz(보라) 박스 |
| 2 | `{N}장_{제목}.pptx` | 35~55슬라이드(콘텐츠 분량에 비례), 다크 타이틀/섹션, 붉은 헤더 콘텐츠 슬라이드, 콘텐츠/코드/퀴즈 슬라이드 전부 발표자 노트 필수 |
| 3 | `{N}장_실습문제.docx` | 객관식 위주 50문항 (하20/중20/상10) — PL/SQL **개념·문법 이해도** 평가 |
| 4 | `{N}장_실습문제_정답.docx` | 정답 및 해설 |
| 5 | `{N}장_실습문제_추가서술형.docx` | 20문항(서술형8+문제해결형6+**코드작성형(명령어진행형 대응)**6), 객관식 절대 금지 — 실제 PL/SQL 코드 작성 문제 위주로 PRD의 "70개 코드 작성 문제" 취지를 반영 |
| 6 | `{N}장_실습문제_추가서술형_정답.docx` | 모범답안(완전한 실행 가능 PL/SQL 코드) 및 채점포인트 |
| 7~ | `{N}장_실습_{NN}_{주제}.txt` | SQL*Plus 세션 로그(`SQL>` 또는 `SYS@...>` 프롬프트, DBMS_OUTPUT 결과 포함, 한글 주석), 챕터별 개수는 `PLSQL_실습_트랜스크립트_주제_목록.md` 참고, 최소 1곳 "오류(컴파일 오류/예외) → 원인 파악 → 수정" 흐름 포함 |

## 챕터 목록 (PRD 섹션 9~15 기준, 7개)

| # | PRD 원제 | 한글 챕터명 | 상태 |
|---|---|---|---|
| 1 | PL/SQL Basic | PL/SQL 기초 | 대기 |
| 2 | Loop & Cursor | 반복문과 커서 | 대기 |
| 3 | Exception / Transaction / Collection | 예외 처리·트랜잭션·컬렉션 | 대기 |
| 4 | Procedure / Function | 프로시저와 함수 | 대기 |
| 5 | Package / Trigger | 패키지와 트리거 | 대기 |
| 6 | Dynamic SQL & DBA Automation | 동적 SQL과 DBA 자동화 | 대기 |
| 7 | Scheduler / Monitoring / Automation | 스케줄러·모니터링·운영 자동화 | 대기 |

## 근거 소스 문서 (우선순위 순)
| 약어 | 문서명 | 사용 챕터 | 비고 |
|---|---|---|---|
| PLSQL1 | `C:\Users\itwill\Downloads\PLSQL1.pdf` | 1~7 (1순위) | 실제 과정 교재로 추정(ADMIN1.pdf/SQL1~3.pdf와 동일 계열). 이미지 기반일 가능성 높음 — 에이전트가 PyMuPDF 등으로 페이지를 이미지 렌더링해 목차/본문을 직접 확인할 것(19c-Admin PDF 처리 방식과 동일) |
| PLSQL2 | `C:\Users\itwill\Downloads\PLSQL2.pdf` | 1~7 (1순위) | PLSQL1.pdf의 후속권으로 추정. 동일 방식으로 확인 |
| PLSQL-REF | `C:\Users\itwill\Downloads\database-pl-sql-language-reference.pdf` | 1~7 (보강) | Oracle 공식 PL/SQL 언어 레퍼런스. PLSQL1/2.pdf에 해당 챕터 본문이 없거나 불충분할 때 문법/의미 보강용으로 사용 |
| PLSQL-PRD | `PLSQL_PRD.md` 섹션 9~15(챕터별 주요내용), 17~18(문제 표준), 6(교육용 로그 테이블 DDL) | 1~7 | 챕터 골격/구성 기준(항상 참고) |
| HR-SCHEMA | Oracle HR Sample Schema (EMPLOYEES/DEPARTMENTS/JOBS/JOB_HISTORY/LOCATIONS/COUNTRIES/REGIONS) | 1~7 전체 실습 기준 데이터 | |

**작업 지침**: 각 챕터 작성 에이전트는 먼저 PLSQL1.pdf/PLSQL2.pdf에서 목차를 확인해 해당 챕터(또는 대응 절) 위치를 찾고 본문을 근거로 작성한다. 두 파일 모두에 해당 내용이 없거나 부족하면 PLSQL-REF로 보강하고, 그래도 부족하면 PRD 골격 + Oracle 19c 공식 문서 수준의 정확한 지식으로 채운다(ADMIN 14~34장에서 검증된 방식).

## 비고 / 향후 계획 (PRD 범위 중 "챕터 산출물" 이후 단계 — 지금은 미착수)
- **최종 평가 30문제** (PRD 섹션 19): 7개 챕터 완료 후 별도로 작성. ADMIN에는 없던 산출물이므로 파일 규격은 착수 시점에 별도 확정.
- **최종 프로젝트 "HR Database DBA Automation Framework"** (PRD 섹션 20~21): 7개 챕터 완료 후 별도 작성. `PKG_DBA_AUTOMATION` 패키지(RUN_ALL_CHECK/CHECK_INVALID_OBJECT/CHECK_USER_STATUS/CHECK_HR_DATA/WRITE_LOG/WRITE_ERROR_LOG) 요구사항 포함.
- **강사용 자료/Workbook/자동채점/환경초기화 스크립트** (PRD 섹션 30~34, 45): 확장 옵션. 7개 챕터 + 최종평가 + 최종프로젝트 완료 후 사용자와 재논의.
- PRD 섹션 6의 교육용 로그 테이블(`plsql_job_log`, `dba_check_result`) DDL은 6장(동적 SQL/DBA 자동화)·7장(스케줄러) 실습에서 실제로 사용해야 하므로, 두 챕터 작업 시 반드시 반영할 것.
- BACKUP&RECOVERY 교안은 이번 라운드에서 다루지 않음(사용자 확인: "우선 PLSQL만 작성할 것").

## 작업 방식 (ADMIN과 동일)
- 챕터당 opus 서브에이전트 1개로 본문→PPT→실습문제 4종→트랜스크립트까지 전부 생성.
- 완료 후 이 세션에서 python-docx/python-pptx/정규식으로 직접 재검증(문자수/슬라이드수/빈노트수/문항수).
- 로컬 작업 폴더: `C:\Users\itwill\Downloads\oracle-plsql-교안\{N}장\`
- 완료된 챕터를 모아 GitHub(`elpisk/OracleManual` 저장소) `PLSQL` 폴더로 robocopy 동기화 후 커밋/푸시(ADMIN과 동일 절차).

세부 실습 트랜스크립트 주제는 `PLSQL_실습_트랜스크립트_주제_목록.md` 참고.
