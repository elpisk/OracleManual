# Oracle Backup & Recovery 교안 — 챕터 목록 (v2)

> v1 → v2 변경: `Clone DB.pdf` 소스 반영, **Data Pump를 독립 챕터로 승격**, 이에 따라 16장 → **19장**으로 확대. (2026-08-19)

- **과정명**: Oracle Database 19c Backup & Recovery (Prep course for DBA Practicum)
- **대상**: ADMIN(19c DBA) 과정 수료자 / 실무 DBA
- **기준 환경**: Oracle Database 19.3.0, Oracle Linux 7, **non-CDB `ORCL`** (원본 시나리오 환경 유지)
  - CDB/PDB 환경에서 달라지는 부분은 각 장의 **Note 박스**로 보강한다(전면 CDB 전환은 하지 않음 — 사용자 확정, 2026-08-19).
- **기준 스키마**: HR Sample Schema (EMPLOYEES/DEPARTMENTS 등), 실습용 보조 테이블 `hr.emp1`~`hr.emp9`, `hr.emp_temp`, `hr.insa_2025`
- **산출물 파이프라인**: `ADMIN`(19c DBA 34챕터)에서 검증된 챕터당 산출물 세트를 그대로 재사용

---

## 1. 소스 인벤토리

### 1-1. 교재 (개념 골격용, 3개)

| 약어 | 파일 | 내용 | 주의 |
|---|---|---|---|
| BR1 | `C:\Users\itwill\Downloads\4. Backup&Recovery\BR1.pdf` | Oracle Database **11g**: Administration Workshop II, Volume I Student Guide (D50079GC20, Ed 2.0, 2010) | **11g 기준** |
| BR2 | `...\BR2.pdf` | 동 Volume II | **11g 기준** |
| BR3 | `...\BR3.pdf` | 동 Volume III | **11g 기준** |

> ⚠️ **버전 경고**: BR1~3은 11g 교재다. 제작_가이드 5장 규칙 1번(버전 혼동 금지 — ADMIN 1장을 11g로 썼다 전면 재작성한 사고)이 그대로 적용된다.
> 교재는 **목차·개념 골격·용어 정의**만 차용하고, 명령어·뷰·화면·기능 설명은 전부 19c로 갱신해서 쓴다. 대조표는 3절 참고.

### 1-2. 시나리오 원본 (19개)

| 파일 | 계통 | 원본 시나리오 | 개수 |
|---|---|---|---|
| BNR_01~05 | User Managed — **NOARCHIVELOG** | 1~24 | 24 |
| BNR_06~11 | User Managed — **ARCHIVELOG** | 1~34 (22.1 포함) | 35 |
| BNR_12~14 | **RMAN** (recovery catalog 사용) | 1~21 | 21 |
| BNR_15 | Database Availability | Block Corruption(+Data Recovery Advisor) / Data Pump / dbms_metadata | 3 |
| BNR_16 | Database Availability | Flashback 6종 + Flashback Data Archive / Cursor Sharing | 8 |
| **Clone DB** | **복제 데이터베이스** | 1~2 (수동 Clone DB 생성 / RMAN Active Duplication) | **2** |
| BNR_test, BNR_test_add | 실습 시험 | OELCLONE·oel7v9 서버 과제형 | — |

합계 **93개 시나리오/주제**.

### 1-3. ⚠️ 소스 파일 위치가 두 폴더로 갈려 있음 (작업 전 정리 필요)

| 폴더 | 보유 파일 |
|---|---|
| `C:\Users\itwill\Downloads\4. Backup&Recovery\` | BNR_01~16, BNR_test, BNR_test_add, **BR1~3, Clone DB.pdf** (전체 22개) |
| `C:\Users\itwill\Downloads\OracleManual\BACKUP&RECOVERY\` (git 저장소) | BNR_01~16, BNR_test, BNR_test_add, Clone DB.pdf (19개) |

`Clone DB.pdf`는 git 저장소 폴더로 복사 완료(2026-08-19).

**BR1~3(11g Oracle University 교재)은 저장소에 넣지 않는다** — 사용자 확정, 2026-08-19. 저작권 자료이므로 `4. Backup&Recovery\` 폴더에만 두고 로컬 참조용으로만 쓴다. `.gitignore`에도 별도 항목을 추가하지 않는다(애초에 저장소 폴더로 복사하지 않으므로 불필요).

> 챕터 작성 에이전트 주의: BR1~3을 **읽는 것은 허용**(개념 골격 참고)이지만, 저장소 폴더로 복사하거나 원문을 그대로 옮겨 쓰지 말 것. 교재에서 가져온 내용은 19c 기준으로 다시 쓴 서술이어야 한다.

---

## 2. 시나리오 정교화 규격 (이번 과정의 핵심 작업)

원본은 SQL*Plus 세션 로그를 그대로 붙인 형태라 결손·오탈자가 많다. 정교화는 **오탈자 수정 + 결손 보완 + 표준 템플릿 재구성** 세 가지를 함께 수행한다.

### 2-1. 표준 8단계 템플릿

모든 시나리오는 아래 8단계로 재작성한다. 본문 docx의 절 구성, 트랜스크립트 txt의 주석 구조 모두 이 순서를 따른다.

| 단계 | 내용 |
|---|---|
| ① 시나리오 개요 | 장애 상황 1~2줄 + **복구 유형 명시**(완전복구 / 불완전복구 / 복구 불가) |
| ② 사전 조건 | `log_mode`, 백업 시점과 종류(cold/hot, open/close), 아카이브·리두 보유 여부 |
| ③ 초기 상태 확인 | `v$database` / `v$datafile` / `v$log` / `v$logfile` / `v$archived_log` 조회 + 실제 출력 |
| ④ 장애 유발 | `rm`, `dd`, `drop`, 파일 이동 등 **재현 가능한 명령** |
| ⑤ 증상 관찰 | ORA- 에러 전문 + alert log 발췌 |
| ⑥ 진단 | 어느 파일이 / 어느 SCN까지 / 무엇이 필요한지 판단 근거 (SCN·sequence 비교 근거 제시) |
| ⑦ 복구 절차 | 단계별 명령 + 출력. **최소 1회 "오류 발생 → 원인 파악 → 수정" 흐름 필수** |
| ⑧ 검증 및 실무 포인트 | 복구 확인 쿼리 + 현업 주의사항 |

> 복제(17장)·Data Pump(19장)처럼 "장애 복구"가 아닌 챕터는 ④⑤를 **"작업 수행"·"진행 로그"** 로 치환해 같은 뼈대를 유지한다.

### 2-2. 확장 방침

- 원본 시나리오와 **1:1 대응하지 않는다**. 논리적으로 같은 계열은 묶고, 원본에 없는 결손 케이스를 채워 넣는다.
  - 예: NOARCHIVELOG 시5·6(SYSTEM 손상, 리두 O/X)은 한 절로 묶되 원본에 없는 **SYSAUX 손상** 케이스를 추가.
  - 예: NOARCHIVELOG 시13~17(컨트롤파일만 손상 4가지 변형)은 "백업본 사용 / trace 재생성" 두 축으로 재편.
- 각 장 말미에 **"장애 유형 → 복구 전략 판단표"** 를 넣어 시나리오를 하나로 꿰는 의사결정 기준을 제시한다.

### 2-3. 원본에서 확인된 수정 대상 (착수 시 반드시 반영)

| 위치 | 문제 | 조치 |
|---|---|---|
| BNR_05 시18 | `from v$datafile a, v$table b` | `v$tablespace`로 수정 |
| BNR_05 시18 | `b.next_v$logfile a, v$log b` (문장 깨짐) | `b.next_change# from v$logfile a, v$log b`로 복원 |
| BNR_02 시3 | `/u01/app/oracle/oradata/ORCL/tbs01.율` (인코딩 깨짐) | `tbs01.dbf` |
| BNR_01 | 프롬프트가 `SYS@orcl>` / `SYS@ora19c>` / `SQL>` 혼재, 경로도 `ORCL`/`ORA19C` 혼재 | **`SYS@orcl>` + `/u01/app/oracle/oradata/ORCL/`로 통일** |
| BNR_11 시26 | "Alert log 확인" 항목 이후 내용 없음 | alert log 출력 예시 작성 |
| BNR_08 시9 | `v$datafile` 출력이 컬럼 줄바꿈으로 판독 불가 | `set linesize 200` 적용한 정돈된 출력으로 재작성 |
| BNR_15 | DRA 출력의 `Impact: Object    owned by    might be unavailable`(객체명 공백) | 실제 객체명(`EMP owned by HR`)으로 채움 |
| Clone DB 시1 | 셸 프롬프트가 `oel7v9r2` / `oracle19c` 혼재 | `oel7v9r2`로 통일 |
| Clone DB 시1 | `db_name='clone'`(소문자)인데 `CREATE CONTROLFILE SET DATABASE "CLONE"`(대문자) | 대소문자 무관함을 Note로 명시하거나 표기 통일 |
| 전반 | `oradata/orcl/`(소문자)와 `oradata/ORCL/`(대문자) 혼재 | 대문자 `ORCL`로 통일 |

---

## 3. 19c 갱신 포인트 (11g 교재에서 끌어올 때 주의)

| 항목 | 11g 교재 | 19c에서 쓸 내용 |
|---|---|---|
| 관리 콘솔 | EM Database Control | **EM Express** (또는 OEM Cloud Control 13c). DB Control은 12c에서 제거 |
| 테이블 복구 | RMAN으로 직접 불가 → TSPITR/보조 인스턴스 수동 | **`RECOVER TABLE ... UNTIL ...`** (12c+, BNR_14 시17이 이미 이 방식) |
| 데이터파일 이동 | offline 후 이동 | **`ALTER DATABASE MOVE DATAFILE ... TO ...`** (12c+, 온라인 이동) |
| 백업 사전 점검 | `RESTORE ... VALIDATE` | `RESTORE ... PREVIEW` / `VALIDATE DATABASE` / `REPORT NEED BACKUP` 확장 |
| DB 복제 | `DUPLICATE ... FROM ACTIVE DATABASE`(11g 도입) | 19c는 **`FROM ACTIVE DATABASE` 백업셋 방식 기본**, `SECTION SIZE`·`USING COMPRESSED BACKUPSET` 지원 |
| Data Pump | expdp/impdp 기본 | **`VIEWS_AS_TABLES`, `LOGTIME`, `TRANSFORM`, 병렬 메타데이터, `CREDENTIAL`(클라우드)** 등 확장 |
| Multitenant | 없음 | **PDB 단위 백업/복구, PDB PITR, `ALTER PLUGGABLE DATABASE`** — 각 장 Note로 언급 |
| Flashback | Flashback Database (DB 단위) | **PDB 단위 Flashback Database** 지원(12.2+) |
| Flashback Data Archive | FBDA 기본형 | 19c는 **최적화·사용자 컨텍스트 추적** 강화 |
| Undo | 인스턴스별 UNDO | CDB에서 **Local Undo Mode** (12.2+) |
| 컨트롤파일 재생성 | 동일 | 절차는 동일하나 `RESETLOGS` 이후 처리 지침 19c 기준으로 서술 |

---

## 4. 챕터당 산출물 (ADMIN/PLSQL과 동일, 총 13~16개 파일)

| # | 파일 | 규격 |
|---|---|---|
| 1 | `{N}장_{제목}.docx` | 본문, 20~30페이지(**26,000~30,000자**), Heading1("제N장  제목")/2/3, 맑은 고딕 + Consolas 코드블록, Note(노랑)/Best Practice(녹색)/실무시나리오(파랑)/Quiz(보라) 박스, 퀴즈 6문항 + 요약 + 실습 개요로 마무리 |
| 2 | `{N}장_{제목}.pptx` | **35~55슬라이드**, 다크 타이틀/섹션, 붉은 헤더(`#C0392B`) 콘텐츠 슬라이드. 타이틀/학습목표/Agenda/섹션구분/요약/실습개요를 제외한 **모든 슬라이드에 발표자 노트 필수**(200~500자) |
| 3 | `{N}장_실습문제.docx` | 객관식 위주 **50문항 (하20/중20/상10)**, 표기 `[하-01]`/`[중-01]`/`[상-01]`, 보기 `①②③④` |
| 4 | `{N}장_실습문제_정답.docx` | 정답 + 해설 |
| 5 | `{N}장_실습문제_추가서술형.docx` | **20문항**(서술형8 + 문제해결형6 + **명령어진행형6**), 표기 `[추가-01]`, 객관식 절대 금지 |
| 6 | `{N}장_실습문제_추가서술형_정답.docx` | 모범답안 + 채점포인트 |
| 7~ | `{N}장_실습_{NN}_{주제}.txt` | 세션 트랜스크립트. **2-1 표준 8단계 템플릿** 준수. 개수는 `BR_실습_트랜스크립트_주제_목록.md` 참고 |

> 이 과정은 장애 복구가 주제라 **명령어진행형 6문항**의 비중이 특히 중요하다. 추가서술형은 "이 상황에서 어떤 명령을 어떤 순서로 내릴 것인가"를 묻는 형태를 우선한다.

---

## 5. 챕터 목록 (19장)

| # | 챕터명 | 주 소스 | 원본 시나리오 |
|---|---|---|---|
| 1 | 백업·복구 개요와 19c 복구 아키텍처 | BR1 ch1~2 (19c 갱신) | — |
| 2 | 복구 가능성 구성 — ARCHIVELOG·FRA·다중화 | BR1 ch2, BNR_06 | ARCH 시1 |
| 3 | User Managed 백업 — Cold Backup과 Hot Backup | BNR_01, BNR_09, BR1 | NOARCH·ARCH 백업부 |
| 4 | NOARCHIVELOG 복구 ① 데이터파일 손상 | BNR_01~02 | NOARCH 시1~6 |
| 5 | NOARCHIVELOG 복구 ② UNDO·TEMP·전체 디스크 장애 | BNR_02~04 | NOARCH 시7~12 |
| 6 | NOARCHIVELOG 복구 ③ 컨트롤파일 장애 | BNR_04~05 | NOARCH 시13~18 |
| 7 | NOARCHIVELOG 복구 ④ 리두로그 장애와 복합 장애 | BNR_05 | NOARCH 시19~24 |
| 8 | ARCHIVELOG 복구 ① 데이터파일 완전복구 | BNR_06~07 | ARCH 시2~8 |
| 9 | ARCHIVELOG 복구 ② 전체 데이터파일·UNDO·아카이브 결손 | BNR_08~09 | ARCH 시9~14 |
| 10 | ARCHIVELOG 복구 ③ 불완전 복구와 INACTIVE 리두로그 장애 | BNR_09 | ARCH 시15~19 |
| 11 | ARCHIVELOG 복구 ④ CURRENT 리두로그 장애와 컨트롤파일 복구 | BNR_10~11 | ARCH 시20~26 |
| 12 | ARCHIVELOG 복구 ⑤ 복합 장애 종합 복구 | BNR_11 | ARCH 시27~34 |
| 13 | RMAN 개요·구성과 Recovery Catalog | BNR_12, BR2 | RMAN 시1 |
| 14 | RMAN 백업 — Full·Incremental·Image Copy·암호화 | BNR_14, BR2 | RMAN 시18·19·21 |
| 15 | RMAN 복구 시나리오 | BNR_12~13 | RMAN 시2~16 |
| 16 | RMAN 고급 복구와 블록 손상 복구 | BNR_14~15, BR3 | RMAN 시17·20 + BNR_15 |
| 17 | **데이터베이스 복제 — Clone DB와 RMAN Duplicate** | **Clone DB.pdf**, BR3 | **Clone 시1·2** |
| 18 | Flashback 기술 | BNR_16, BR3 | BNR_16 |
| 19 | **Data Pump와 논리 백업** | **BNR_15**, BR2~3 | BNR_15 |

### v1(16장) 대비 변경 내역

| v1 | v2 |
|---|---|
| 16장 "RMAN 고급 복구와 Flashback·데이터 가용성" 하나에 RMAN 시17·20 + Block Corruption + Flashback 7종 + Data Pump + dbms_metadata를 전부 몰아넣음 | **4개 장으로 분리** — 16장(RMAN 고급 + 블록 손상), 17장(복제), 18장(Flashback), 19장(Data Pump) |
| Clone DB 소스 없음 | 17장 신설. `Clone DB.pdf` 시나리오 2개 + TSPITR·`nid`·백업 기반 복제로 확장 |
| Data Pump는 16장의 한 절 | **19장 독립 챕터로 승격** (사용자 지시, 2026-08-19) |

v1에서 16장은 배정 주제가 11개였다. 본문 26,000~30,000자 규격 안에 다 담으면 각 주제가 2,500자 남짓으로 쪼그라들어 Flashback Database나 Data Pump처럼 파라미터가 많은 주제를 제대로 다룰 수 없다. 분리가 맞다.

### 챕터 간 역할 분담 (제작_가이드 규칙 10번)

- **3장**은 백업 "방법론"(무엇을 어떻게 받는가)만 다루고, 복구는 4장부터 시작한다.
- **4~7장(NOARCHIVELOG)** 과 **8~12장(ARCHIVELOG)** 은 같은 장애 유형이 반복된다. NOARCHIVELOG 쪽은 **"왜 불완전 복구로 끝나는가"**, ARCHIVELOG 쪽은 **"어떻게 완전 복구로 끌고 가는가"** 에 서술 무게를 둔다. 동일 명령 설명을 두 번 반복하지 않는다.
- **13~16장(RMAN)** 은 4~12장에서 손으로 한 절차가 RMAN에서 어떤 명령 하나로 대체되는지를 대조하는 방식으로 쓴다. User Managed 절차를 다시 설명하지 않는다.
- **2장**의 ARCHIVELOG 전환(ARCH 시1)은 8장에서 재설명하지 않는다.
- **11장**의 컨트롤파일 재생성과 **6장**의 컨트롤파일 재생성은 아카이브 유무에 따른 `RESETLOGS` 이후 처리 차이를 축으로 나눈다.
- **16장 vs 17장**: 16장의 Table Recovery(`RECOVER TABLE`)는 내부적으로 보조 인스턴스를 쓰지만 **명령 한 줄로 끝나는 자동화**로 설명하고, 그 내부에서 벌어지는 복제·TSPITR 절차는 17장에서 손으로 풀어 보여준다. 16장에서 "복제 데이터베이스"를 설명하지 않고 17장을 참조시킨다.
- **17장 vs 13장**: 17장의 `DUPLICATE`는 RMAN 명령이지만 13장(카탈로그 구성)에서 다루지 않는다. 17장에서 필요한 네트워크·패스워드 파일 설정을 자체적으로 다시 정리한다.
- **19장 vs 3장**: 3장은 물리 백업, 19장은 논리 백업이다. 19장 도입부에서 "물리 백업으로는 못 하는 것"(스키마 이관, 버전 간 이동, 객체 단위 복원)을 축으로 차이를 세운다.
- **18장 Cursor Sharing 제외**: 백업·복구와 무관한 성능 튜닝 주제(ADMIN 과정 영역). 본문에서는 빼고 원본 보존 차원에서 트랜스크립트 1개만 부록으로 남긴다.

---

## 6. 별도 산출물 — 종합 실습 과제 (챕터 산출물과 분리)

`BNR_test.pdf` / `BNR_test_add.pdf` 기반. 19개 챕터 완료 후 별도 작성한다(사용자 확정, 2026-08-19).

| 파일 | 내용 |
|---|---|
| `종합실습과제.docx` | 서버 환경별 과제 세트. 원본 4+1문항을 12~15문항으로 확장(스키마 이전, truncate 복구, 시점 복구, 블록 손상 복구, Incremental Backup, Flashback, Data Pump, DB 복제) |
| `종합실습과제_모범답안.docx` | 단계별 명령 + 출력 + 채점 포인트 |

원본 과제에 명시된 환경(11g `oel5v8` → `oelclone` 이전)은 19c 기준으로 재구성한다. 11g 서버 간 이전은 **Data Pump 버전 호환(`VERSION=` 파라미터)** 주제로 살려 쓴다 — 19장과 직접 연결된다.

---

## 7. 작업 방식·검증·동기화

- **초안 폴더**: `C:\Users\itwill\Downloads\oracle-br-교안\{N}장\`
- **정식 폴더**: `C:\Users\itwill\Downloads\OracleManual\BACKUP&RECOVERY\`
  - 이 폴더에는 현재 소스 PDF 18개가 들어 있다. robocopy `/MIR`는 **대상 폴더를 초안과 완전히 일치시키므로 PDF가 삭제된다.** 아래 중 하나를 반드시 적용할 것:
    1. 초안 폴더에 소스 PDF를 그대로 포함시킨 뒤 `/MIR` 실행, 또는
    2. `/MIR` 대신 `/E`(하위 디렉터리 포함 복사, 삭제 없음) 사용
  - PDF는 삭제하지 않는다(제작_가이드 규칙 4번).
- **PATH 재로드** (PowerShell 세션마다):
  ```powershell
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  ```
- **동기화 예시**:
  ```powershell
  $src = "C:\Users\itwill\Downloads\oracle-br-교안"
  $dst = "C:\Users\itwill\Downloads\OracleManual\BACKUP&RECOVERY"
  robocopy $src $dst /E /NFL /NDL /NJH /NJS
  ```
- **생성**: 챕터당 서브에이전트 1개로 본문 → PPT → 실습문제 4종 → 트랜스크립트 전부 생성.
- **검증**: 완료 후 오케스트레이터 세션에서 python-docx/python-pptx/정규식으로 직접 재검증(제작_가이드 4장 스크립트). 에이전트 자체 보고는 검증 전까지 신뢰하지 않는다.
- **push**: 여러 챕터를 모아 `elpisk/OracleManual` 저장소에 커밋/푸시.

### 착수 순서

1. 기획 문서 3종 확정 (본 문서 / `BR_실습_트랜스크립트_주제_목록.md` / `BR_시나리오_매핑.md`)
2. ~~`Clone DB.pdf` 복사, BR1~3 저작권 처리 확인~~ → 완료 (2026-08-19)
3. **1장 파일럿** 생성 → 전체 검증 → 문체·규격 확정
4. 2~19장 확산 (3~4개씩 묶어 진행, 각 묶음 후 검증)
5. 종합 실습 과제 2종 작성
6. robocopy 동기화 → commit → push

> robocopy 시 주의: 초안 폴더(`oracle-br-교안`)에 BR1~3을 두지 않는다. `/E`로 동기화하므로 초안 폴더에 있는 것은 그대로 저장소로 넘어간다.

---

## 8. 진행 상태

| 장 | 본문 | PPT | 실습문제 | 추가서술형 | 트랜스크립트 | 검증 |
|---|---|---|---|---|---|---|
| **1 (파일럿)** | **완료** 28,070자 | **완료** 55슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 5개 | **19/19 PASS** |
| **2** | **완료** 27,580자 | **완료** 39슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 7개 | **19/19 PASS** |
| **3** | **완료** 27,256자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 6개 | **19/19 PASS** |
| **4** | **완료** 27,189자 | **완료** 36슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 7개 | **19/19 PASS** |
| **5** | **완료** 26,691자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 7개 | **19/19 PASS** |
| **6** | **완료** 27,277자 | **완료** 45슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 6개 | **19/19 PASS** |
| **7** | **완료** 27,054자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 6개 | **19/19 PASS** |
| **8** | **완료** 26,827자 | **완료** 36슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 8개 | **19/19 PASS** |
| **9** | **완료** 26,226자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 7개 | **19/19 PASS** |
| **10** | **완료** 26,296자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 7개 | **19/19 PASS** |
| **11** | **완료** 26,104자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 8개 | **19/19 PASS** |
| **12** | **완료** 26,151자 | **완료** 36슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 8개 | **19/19 PASS** |
| **13** | **완료** 27,367자 | **완료** 36슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 7개 | **19/19 PASS** |
| **14** | **완료** 26,038자 | **완료** 36슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 8개 | **19/19 PASS** |
| **15** | **완료** 26,038자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 10개 | **19/19 PASS** |
| **16** | **완료** 26,158자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 8개 | **19/19 PASS** |
| **17** | **완료** 26,016자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 8개 | **19/19 PASS** |
| **18** | **완료** 26,073자 | **완료** 35슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 9개 | **19/19 PASS** |
| **19** | **완료** 26,049자 | **완료** 41슬라이드 | **완료** 50문항 | **완료** 20문항 | **완료** 10개 | **19/19 PASS** |
| 종합실습과제 | 대기 | — | — | — | — | — |

### 1장 파일럿에서 확정된 규격 (2~19장에 그대로 적용)

- **본문 문체**: 개조식(글머리 기호) + 평서체(`~다`/`~함`/`~됨`). 독자를 직접 부르지 않음.
  구조는 ADMIN 방식 유지(학습목표 → 절 → 퀴즈 → 요약 → 실습 개요).
- **docx 서식**: 8.5x11", 여백 1.25"/1", 맑은 고딕 10.5pt / 줄간격 1.35.
  박스 4종(참고 `FFF6D5` · Best Practice `E3F0DB` · 실무 시나리오 `E1ECF7` · Quiz `F3E4F5`),
  코드박스 `1E1E1E` + Consolas 9.5pt(주석 `7EC699`).
- **pptx 서식**: 16:9, 붉은 헤더 `C0392B`, 타이틀/섹션 다크 `17202A`,
  본문 불릿 18pt `202830` / 하위 16pt `5A6672`, 코드 12.5pt Consolas.
  **발표자 노트 전 슬라이드 200~500자**(1장 실적 min 209 / avg 314 / max 461).
- **트랜스크립트**: 표준 8단계 템플릿. 장애 복구가 아닌 장은 ④⑤를 "작업 수행 / 진행 로그"로 치환.
  프롬프트 `SYS@orcl>` · `HR@orcl>` · `RMAN>` · `[oracle@oel7v9r1 ~]$`, 경로 `/u01/app/oracle/oradata/ORCL/`.
- **빌더**: `br_style.py`(docx) / `br_ppt.py`(pptx) / `build_body.py N` / `build_pptx0N.py` / `build_quiz.py N` / `verify_ch.py N`. 장 번호를 인자로 받아 재사용한다.
  세션 스크래치패드에서 관리하며 프로젝트 폴더에 남기지 않는다.
