# Oracle Database 19c Active Data Guard 교안 — 챕터 목록 (v1 초안)

**작성일**: 2026-08-26
**과정 코드명**: ADG (`OracleManual` 저장소의 여섯 번째 과정)
**상태**: 확인 대기. 챕터 구성과 실습 주제를 승인받은 뒤 1장 파일럿에 착수한다.

---

## 1. 소스 인벤토리

| 약어 | 문서 | 위치 | 분량 | 용도 |
|---|---|---|---|---|
| **DGW1** | *Oracle Database 19c: Data Guard Administration Workshop* — 슬라이드 + 발표자 노트 | `Downloads\ADG\19C_ADG_01.pdf` | 295쪽 / Lesson 1~10 | **1순위 근거.** 개념·구성 전반 |
| **DGW2** | 같은 워크숍 2권 — 노트 전용(슬라이드 없음) | `Downloads\ADG\19C_ADG_02.pdf` | 61쪽 | **1순위 근거.** 모니터링·보호 모드·역할 전환·백업 |
| **INST** | `ADG_Install_Guide_Chicago_Boston.docx` (직접 제작) | `Downloads\ADG\` | 20,119자 / Step 30 / 표 20 | **실습 골격.** 경로 지정 방식 |
| **OMF** | `ADG_OMF_Guide_Chicago_Boston.docx` (직접 제작) | `Downloads\ADG\` | 24,192자 / Step 29 / 표 28 | **실습 골격.** OMF 방식 |
| ADMIN | 기존 ADMIN 과정 5장(DBCA)·9~13장(Oracle Net)·14~16장(PDB) | 저장소 `ADMIN\` | — | 전제 지식. 중복 회피 대조 |
| BR | 기존 BR 과정 13~16장(RMAN)·17장(Clone DB·Duplicate) | 저장소 `BACKUP&RECOVERY\` | — | **경계 대조**(아래 2-2) |

**DGW1·DGW2는 Oracle University 교재다.** 규칙 2에 따라 저장소에 커밋하지 않으며 `.gitignore`에도 넣지 않고 untracked로 둔다. BR1~3, PLSQL1~2와 같은 취급이다. 텍스트 추출은 되므로(이미지 기반 아님) 근거로 읽는 데는 문제가 없다.

### 1-1. 원본 워크숍의 구성 (근거 매핑용)

| 단위 | 원본 위치 | 제목 |
|---|---|---|
| L1 | DGW1 p2~26 | Introduction to Oracle Data Guard |
| L2 | DGW1 p27~43 | Oracle Net Services in a Data Guard Configuration |
| L3 | DGW1 p44~94 | Creating a Physical Standby Database by Using RMAN |
| L4 | DGW1 p95~121 | Managing Physical Standby Files After Primary Changes |
| L5 | DGW1 p122~153 | Using Oracle Active Data Guard: Real-Time Query 외 |
| L6 | DGW1 p154~171 | Using Oracle Active Data Guard: Far Sync |
| L7 | DGW1 p172~184 | Creating and Managing a Snapshot Standby Database |
| L8 | DGW1 p185~225 | Creating a Logical Standby Database |
| L9 | DGW1 p226~246 | Oracle Data Guard Broker: Overview |
| L10 | DGW1 p247~295 | Creating a Data Guard Broker Configuration |
| N1 | DGW2 p2~13 | Broker 모니터링·검증 명령 (SHOW / VALIDATE 계열) |
| N2 | DGW2 p14~25 | V$ 뷰 기반 모니터링과 문제 해결 |
| N3 | DGW2 p26~33 | 리두 전송 모드와 데이터 보호 모드 |
| N4 | DGW2 p34~56 | 역할 전환 — Switchover · Failover · Fast-Start Failover |
| N5 | DGW2 p57~61 | Data Guard 환경의 백업·복구 |

---

## 2. 다른 과정과의 관계

### 2-1. 전제 지식으로 삼는 것 (다시 가르치지 않는다)

| 주제 | 어느 과정에서 다뤘나 | 이 과정에서의 처리 |
|---|---|---|
| DBCA를 이용한 DB 생성 | ADMIN 5장 | 4장에서 silent 모드 명령만 제시하고 옵션 설명은 생략. ADMIN 참조 표기 |
| 리스너·tnsnames 기초 | ADMIN 9~13장 | 3장은 "Data Guard가 요구하는 추가 조건"만 다룬다 — 정적 등록(SID_LIST), `GLOBAL_DBNAME`, 서비스 이름 규칙 |
| PDB·CDB 구조 | ADMIN 14~16장 | Multitenant 환경의 Data Guard는 5·6장에서 CDB 단위 전환임을 밝히는 정도로만 |
| ARCHIVELOG 전환, FRA | BR 2장 | 4장에서 절차만 재확인하고 원리는 BR 참조 |

### 2-2. BR 과정과의 경계 (중요)

BR 17장이 이미 **RMAN `DUPLICATE`로 데이터베이스를 복제**하는 법을 다룬다. 이 과정의 5·6장도 `DUPLICATE ... FOR STANDBY`를 쓴다. 겹쳐 보이지만 목적이 다르다.

| 구분 | BR 17장 | ADG 5·6장 |
|---|---|---|
| 명령 | `DUPLICATE TARGET DATABASE TO <새이름>` | `DUPLICATE TARGET DATABASE FOR STANDBY FROM ACTIVE DATABASE` |
| 결과물 | 독립된 별개의 DB. 원본과 관계가 끊긴다 | Standby DB. 원본과 리두로 계속 연결된다 |
| DBID | 새로 부여된다 | **원본과 같다** |
| 이후 상태 | OPEN | MOUNT + Redo Apply |
| 초점 | 복제 자체 | 복제 이후의 지속적 동기화 |

**5장 도입부에 이 표를 넣어 "BR 17장에서 배운 명령의 변형"임을 명시한다.** 중복이 아니라 연결이 되도록 한다.

### 2-3. Tuning 과정과의 경계

Tuning 20장은 단일 인스턴스의 성능을 다룬다. 이 과정에서 성능 이야기가 나오는 곳은 두 군데다 — 7장의 Apply 지연(`V$DATAGUARD_STATS`의 apply lag / transport lag)과 9장의 Active Data Guard 조회 부하. 둘 다 **"Data Guard 고유의 지표를 읽는 법"까지만** 다루고, 일반적인 DB Time 분해나 SQL 튜닝으로는 넘어가지 않는다. 넘어가야 하면 Tuning 과정으로 넘긴다.

---

## 3. 챕터 목록 (16장 제안)

산출물 규격은 기존 과정과 동일하다 — 챕터당 본문 docx(26,000~30,000자) + PPT(35~55슬라이드) + 실습문제 50문항(하20/중20/상10) + 정답 + 추가서술형 20문항 + 정답 + 세션 트랜스크립트. 상세는 `제작_가이드.md` 3장과 인계 문서 5-1절.

| 장 | 제목 | 근거 | 비고 |
|---|---|---|---|
| 1 | Data Guard 개요와 아키텍처 | DGW1 L1 | 구성 요소, physical·logical·snapshot standby 구분, 도입 효과, 라이선스 경계 |
| 2 | 데이터 보호 모드와 리두 전송 서비스 | DGW2 N3 | Maximum Protection·Availability·Performance, SYNC/ASYNC, AFFIRM/NOAFFIRM, SRL 요건 |
| 3 | Data Guard를 위한 Oracle Net 구성 | DGW1 L2 + INST 3장 | tnsnames·listener 정적 등록, `LOG_ARCHIVE_CONFIG`, 연결 검증 |
| 4 | Primary 준비 — ARCHIVELOG·FORCE LOGGING·Standby Redo Log | INST 2장 + DGW1 L3 | SRL 개수 산정 공식, FORCE LOGGING의 의미, nologging 개선 사항 |
| 5 | Physical Standby 생성 ① RMAN DUPLICATE (경로 지정 방식) | DGW1 L3 + INST 5장 | `db_file_name_convert` / `log_file_name_convert`, 초기 pfile, NOMOUNT 기동 |
| 6 | Physical Standby 생성 ② OMF 방식 | OMF 가이드 + DGW1 L3 | `db_create_file_dest`, convert 파라미터 불필요, 두 방식 대조 |
| 7 | Redo Apply 기동과 동기화 검증 | INST 6~7장 + DGW1 L4 | MRP 기동·중지, real-time apply, transport lag / apply lag 판독 |
| 8 | Primary 구조 변경의 Standby 반영 | DGW1 L4 | `STANDBY_FILE_MANAGEMENT`, 수동 개입이 필요한 변경과 아닌 변경 |
| 9 | Active Data Guard ① 실시간 조회와 DML 리다이렉션 🔒 | DGW1 L5 | Real-Time Query, GTT·PTT, `ADG_REDIRECT_DML`, In-Memory 지원 |
| 10 | Active Data Guard ② Far Sync와 Real-Time Cascading 🔒 | DGW1 L6 | 원거리 zero data loss, far sync 인스턴스 생성, 캐스케이딩 |
| 11 | Snapshot Standby | DGW1 L7 | 임시 갱신 가능 standby로 전환·복귀, Flashback 기반 동작 |
| 12 | Logical Standby와 SQL Apply | DGW1 L8 | 언제 쓰는가, 생성 절차, SQL Apply 필터링, 지원되지 않는 유형 |
| 13 | Data Guard Broker 개요와 구성 생성 | DGW1 L9 + L10 | broker 아키텍처, 구성 파일, DGMGRL로 구성 생성·등록 |
| 14 | Broker 모니터링과 검증 명령 | DGW2 N1 | `SHOW CONFIGURATION/DATABASE`, `VALIDATE DATABASE` 계열 4종 |
| 15 | V$ 뷰 기반 모니터링과 문제 해결 | DGW2 N2 | `V$DATAGUARD_STATS/STATUS`, `V$ARCHIVE_DEST`, `LOG_ARCHIVE_TRACE`, 전송 중단 진단 |
| 16 | 역할 전환과 이후 운영 | DGW2 N4 + N5 | Switchover, Failover, Fast-Start Failover, Reinstate, Data Guard 환경의 백업 |

🔒 = Active Data Guard 옵션 라이선스가 필요한 챕터(4-2절).

### 3-1. 원본에서 축소하거나 제외한 것

| 항목 | 처리 |
|---|---|
| Enterprise Manager로 Data Guard 관리 (L9·L10 일부) | **개념만 언급하고 실습 제외.** EM Cloud Control 설치가 전제라 실습 환경을 맞출 수 없다. 모든 실습은 DGMGRL과 SQL로 수행한다 |
| `DBMS_DBCOMP.DBCOMP` 블록 비교 (L3) | 5장에서 한 절로 축소. 실습은 넣되 대량 비교는 하지 않는다 |
| Logical Standby의 고급 필터링·재작성 (L8 후반) | 12장에서 개념과 기본 필터까지만. 물리 standby가 이 과정의 중심이다 |
| RAC 환경의 Data Guard | **제외.** 단일 인스턴스 2노드 구성으로 한정한다. RAC는 별도 과정 영역 |
| ASM 기반 파일 배치 | 6장에서 OMF와 함께 개념만 언급. 실습은 파일 시스템 경로로 한다(ADMIN 34장이 ASM을 다룬다) |

### 3-2. 챕터 수를 16으로 잡은 근거

원본 워크숍의 단위는 15개(L1~L10 + N1~N5)다. 여기에서 두 가지를 조정했다.

- **L3을 4·5·6장 셋으로 나눴다.** 원본 L3(51쪽)은 Primary 준비부터 RMAN DUPLICATE까지를 한 덩어리로 묶고 있는데, 직접 만든 설치 가이드 두 편이 이 구간을 Step 30개로 상세히 풀어 놓았다. 실습 비중이 가장 큰 구간이라 세 장으로 나누는 편이 챕터당 분량 규격(26,000~30,000자)에 맞는다. OMF 방식을 따로 둔 것은 두 가이드의 차이가 곧 6장의 교육 내용이기 때문이다.
- **N4와 N5를 16장으로 합쳤다.** N5(백업·복구)는 원본이 5쪽뿐이고 내용의 절반이 BR 과정과 겹친다. Failover 이후의 reinstate와 이어서 다루면 "역할 전환 이후에 무엇을 해야 하는가"라는 하나의 흐름이 된다.

---

## 4. 실습 환경

### 4-1. 2노드 구성이 필요하다 — **현재 준비되어 있지 않다**

이 과정은 다섯 과정 중 처음으로 **서버 두 대**를 요구한다. 설치 가이드가 전제하는 구성은 다음과 같다.

| 항목 | Primary | Standby |
|---|---|---|
| 호스트명 | chicago-srv | boston-srv |
| IP | 172.16.188.10 | 172.16.188.11 |
| DB_NAME / DB_UNIQUE_NAME | chicago / chicago | chicago / boston |
| 버전 | Oracle Database 19.3.0.0 EE | 동일 |
| OS | Oracle Linux 7.9 | 동일 |
| 데이터 경로 | `/u03/app/oracle/oradata/Chicago` (OMF본은 `/CHICAGO`) | `/u03/app/oracle/oradata/BOSTON` |
| FRA | `/u03/app/oracle/fast_recovery_area` | 동일 |

**2026-08-26 확인 결과 이 두 호스트는 존재하지 않는다.**

- `172.16.188.10:1521`, `172.16.188.11:1521` — 둘 다 응답 없음
- 로컬 VMware VM은 `D:\ORASRV.vmx`, `D:\OEL7V9\OEL7V9.vmx`, `D:\OELTEST\OELTEST.vmx` 세 개뿐이며 chicago/boston 전용 VM은 없다
- 살아 있는 실습 DB는 튜닝 과정이 쓰던 `172.16.225.50:1521/orcl` 하나뿐이다. **대역도 다르다**(VMnet8 172.16.225.x vs 가이드의 172.16.188.x)

따라서 착수 전에 다음 셋 중 하나를 정해야 한다.

| 선택지 | 내용 | 대가 |
|---|---|---|
| **A. 2노드 VM 구축** | OEL 7.9 + 19.3 EE 두 대를 만들어 가이드대로 ADG를 구성한다 | 구축에 시간이 들지만, Tuning 과정에서 확립한 **실측 캡처 방식**(인계 문서 9-2절)을 그대로 쓸 수 있다. 트랜스크립트의 모든 수치가 실측이 된다 |
| **B. 기존 VM 1대 복제** | `OEL7V9`를 복제해 boston으로 만들고 IP·hostname만 바꾼다 | A보다 빠르다. 단 원본 VM이 튜닝 실습 DB를 담고 있어 간섭 위험을 확인해야 한다 |
| **C. 실측 없이 제작** | 설치 가이드와 워크숍 노트만으로 트랜스크립트를 쓴다. 환경 의존 수치는 `<환경값>`으로 남긴다 | ADMIN·BR·PLSQL 세 과정이 이 방식이었다. 품질은 유지되지만 Tuning 수준의 실측 근거는 얻지 못한다 |

**권장은 B다.** ADG 실습의 핵심 관측치(전송 지연, apply 지연, 역할 전환 전후 상태, broker 검증 출력)는 실제로 두 노드가 돌아야만 나온다. C로 가면 16개 챕터 대부분의 트랜스크립트가 `<환경값>` 투성이가 된다.

### 4-2. 라이선스 방침 (확정 필요)

**Active Data Guard는 Enterprise Edition에 포함되지 않는 별도 옵션이다.** 이 과정은 이름에 ADG가 들어가지만 실제 내용의 대부분은 EE 기본 Data Guard로 실습할 수 있다. 구분을 분명히 해 둔다.

| 기능 | EE 기본 | ADG 옵션 필요 | 해당 챕터 |
|---|---|---|---|
| Physical standby 생성, Redo Apply | O | | 4~8 |
| MOUNT 상태 standby, 역할 전환 | O | | 16 |
| Logical standby, SQL Apply | O | | 12 |
| Snapshot standby | O | | 11 |
| Data Guard Broker, DGMGRL | O | | 13~15 |
| **Real-Time Query** (standby를 OPEN READ ONLY로 열고 조회) | | **O** | 9 |
| **DML 리다이렉션**, standby의 GTT·PTT 갱신 | | **O** | 9 |
| **Far Sync 인스턴스** | | **O** | 10 |
| **In-Memory Column Store on standby** | | **O** | 9 |

처리 방침은 Tuning 과정의 Diagnostics Pack 방침(챕터 목록 4-2절)을 그대로 따른다.

1. **1장에 라이선스 절을 둔다** — 어느 기능이 EE 기본이고 어느 것이 옵션인지, `DBA_FEATURE_USAGE_STATISTICS`로 사용 이력을 확인하는 법.
2. **9·10장 도입부에 라이선스 표기를 반복한다.**
3. **옵션 미보유 환경 대안을 병기한다** — 9장에는 "MOUNT 상태에서 같은 것을 확인하는 법"(standby에서 조회하는 대신 primary에서 `V$DATAGUARD_STATS`로 지연을 보는 경로)을, 10장에는 "Far Sync 없이 캐스케이딩만으로 구성하는 법"을 넣는다.

### 4-3. 실습 데이터

Data Guard 실습은 스키마 내용에 의존하지 않는다. 다만 리두를 발생시킬 대상이 필요하므로 **가벼운 전용 스키마를 새로 만든다**(`DGDEMO`). 진료비청구심사 스키마(SQLT)는 튜닝 과정 전용이며 **이 과정으로 가져오지 않는다** — 그 스키마는 "의도된 Before 상태"를 보존해야 하고(인계 문서 9-2절), ADG 실습은 대량 DML과 구조 변경을 반복하기 때문이다.

---

## 5. 다음 단계

1. **이 문서와 `ADG_실습_트랜스크립트_주제_목록.md` 확인**
2. **4-1절 선택지 결정** (A / B / C) — 이것이 정해져야 트랜스크립트 작성 방식이 확정된다
3. 1장 파일럿 제작 → 오케스트레이터 검증 → 나머지 챕터 병렬 진행
4. 5·6장 착수 전에 BR 17장 본문을 열어 서술 수준 확인 (2-2절 경계가 지켜지는지)
