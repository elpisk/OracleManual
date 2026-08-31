# Oracle Database 19c Real Application Clusters 교안 — 챕터 목록 (v1)

**작성일**: 2026-08-31
**과정 코드명**: RAC (`OracleManual` 저장소의 일곱 번째 과정)
**상태**: 챕터 20장 확정. 실습 환경 구축 후 1장 착수.

---

## 1. 소스 인벤토리

| 약어 | 문서 | 위치 | 분량 | 용도 |
|---|---|---|---|---|
| **RACG** | *Real Application Clusters Administration and Deployment Guide* 19c | `Downloads\RAC\real-application-clusters-administration-and-deployment-guide.pdf` | **491쪽 / 9장** | **1순위 근거.** RAC 인스턴스·서비스·백업·클로닝 |
| **CRSG** | *Clusterware Administration and Deployment Guide* 19c | `Downloads\RAC\clusterware-administration-and-deployment-guide.pdf` | **702쪽 / 8장** | **1순위 근거.** Clusterware 구조·OCR/Voting·노드 관리 |
| **ASMG** | *Automatic Storage Management Administrator's Guide* 19c | `Downloads\RAC\automatic-storage-management-administrators-guide.pdf` | **791쪽 / 9장** | **1순위 근거.** ASM 인스턴스·디스크그룹·파일·마이그레이션 |
| GI | `Create_GI_19c (Linux).txt` (직접 제작) | `D:\Oracle\설치파일\2026-04\` | 12,563자 | **실습 골격.** 단일 노드 GI(Oracle Restart) 설치 절차 |
| SW | `19c_grid_linux.zip` / `19c_db_linux.zip` | `D:\Oracle\설치파일\2026-03\` | 2.9GB / 3.1GB | 설치 매체 |
| ADMIN | 기존 ADMIN 과정 5장(DBCA)·9~13장(Oracle Net)·14~16장(PDB) | 저장소 `ADMIN\` | — | 전제 지식. 중복 회피 대조 |
| BR | 기존 BR 과정 13~16장(RMAN) | 저장소 `BACKUP&RECOVERY\` | — | **경계 대조**(2-2) |
| ADG | 기존 ADG 과정 16장 | 저장소 `ADG\` | — | **경계 대조**(2-3). 고가용성의 다른 축 |

**세 PDF 는 Oracle 공식 문서다.** 규칙 2에 따라 저장소에 커밋하지 않으며 `.gitignore` 에도 넣지 않고 untracked 로 둔다. Tuning 과정의 `database-performance-tuning-guide.pdf` 와 같은 취급이다.

### 1-1. 원본 문서의 장 구성 (근거 매핑용)

| 단위 | 원본 | 제목 |
|---|---|---|
| R1 | RACG 1장 | Introduction to Oracle RAC |
| R2 | RACG 2장 | Administering Storage in Oracle RAC |
| R3 | RACG 3장 | Administering Database Instances and Cluster Databases |
| R4 | RACG 4장 | Administering Oracle RAC One Node |
| R5 | RACG 5장 | Workload Management with Dynamic Database Services |
| R6 | RACG 6장 | Ensuring Application Continuity |
| R7 | RACG 7장 | Configuring Recovery Manager and Archiving |
| R8 | RACG 8장 | Managing Backup and Recovery |
| R9 | RACG 9장 | Cloning Oracle RAC to Nodes in a New Cluster |
| C1 | CRSG 1장 | Introduction to Oracle Clusterware |
| C2 | CRSG 2장 | Oracle Clusterware Configuration and Administration |
| C3 | CRSG 3장 | Policy-Based Cluster and Capacity Management |
| C4 | CRSG 4장 | Oracle Flex Clusters |
| C5 | CRSG 5장 | Managing Oracle Cluster Registry and Voting Files |
| C6 | CRSG 6장 | Adding and Deleting Cluster Nodes |
| C7 | CRSG 7장 | Cloning Oracle Clusterware |
| C8 | CRSG 8장 | Making Applications Highly Available Using Oracle Clusterware |
| A1 | ASMG 1장 | Introducing Oracle Automatic Storage Management |
| A2 | ASMG 2장 | Exploring Considerations for Oracle ASM Storage |
| A3 | ASMG 3장 | Administering Oracle ASM Instances |
| A4 | ASMG 4장 | Administering Oracle ASM Disk Groups |
| A5 | ASMG 5장 | Administering Oracle ASM Files, Directories, and Templates |
| A6 | ASMG 6장 | Using Views to Display Oracle ASM Information |
| A7 | ASMG 7장 | Administering Oracle ASM with Oracle Enterprise Manager |
| A8 | ASMG 8장 | Performing Oracle ASM Data Migration with RMAN |
| A9 | ASMG 9장 | Managing Oracle ASM With ASMCA |

---

## 2. 다른 과정과의 관계

### 2-1. 전제 지식으로 삼는 것 (다시 가르치지 않는다)

| 주제 | 어느 과정에서 다뤘나 | 이 과정에서의 처리 |
|---|---|---|
| DBCA 로 DB 생성 | ADMIN 5장 | 11장에서 **RAC 옵션과 응답 파일만** 다루고 일반 옵션 설명은 생략 |
| 리스너·tnsnames 기초 | ADMIN 9~13장 | 3·15장은 **RAC 가 요구하는 추가 조건만** — SCAN, VIP, 원격 리스너 등록 |
| PDB·CDB 구조 | ADMIN 14~16장 | 12장에서 **RAC 에서 PDB 를 열고 닫는 방식**만 |
| ARCHIVELOG·FRA | BR 2장 | 17장에서 절차만 재확인 |
| RMAN 백업·복구 명령 | BR 13~16장 | 17장은 **RAC 특유의 것만** — 채널 분산, 노드별 아카이브 접근 |
| 초기화 파라미터 일반 | ADMIN 3장 | 12장은 **SPFILE 의 `sid.parameter` 표기와 세 분류만** |

### 2-2. BR 과정과의 경계 (중요)

| 구분 | BR 13~16장 | RAC 17장 |
|---|---|---|
| 대상 | 단일 인스턴스 | **여러 인스턴스가 공유하는 하나의 DB** |
| 아카이브 | 로컬 경로 | **모든 노드가 읽을 수 있어야 한다** (ASM 또는 공유 파일 시스템) |
| 채널 | 하나의 노드에서 할당 | **노드별로 나눠 병렬 백업** |
| 복구 | 그 인스턴스가 수행 | **어느 노드에서든 수행. 스레드별 리두를 모두 적용** |
| 초점 | 백업·복구 자체 | **여러 노드에 흩어진 자원을 하나로 다루는 법** |

### 2-3. ADG 과정과의 경계

| 구분 | ADG | RAC |
|---|---|---|
| 막는 장애 | **서버·사이트 전체 장애** (재해 복구) | **인스턴스·노드 장애** (가용성) |
| 데이터 사본 | **둘 이상** | **하나** (공유 스토리지) |
| 노드 관계 | Primary → Standby 단방향 | **모든 노드가 동시에 읽고 쓴다** |
| 전환 | Switchover·Failover (수십 초) | **장애 노드만 빠지고 나머지가 계속** (수 초) |
| 결합 | 둘을 함께 쓴다 — RAC 로 가용성, ADG 로 재해 복구 | 20장에서 그 조합을 다룬다 |

**중복 회피** — ADG 16장의 역할 전환은 이 과정에서 다시 가르치지 않는다. 20장에서 "RAC + Data Guard" 구성의 개요만 제시하고 ADG 과정을 참조한다.

---

## 3. 챕터 목록 (20장)

산출물 규격은 기존 과정과 동일하다 — 챕터당 본문 docx(26,000~30,000자) + PPT(35~55슬라이드) + 실습문제 50문항(하20/중20/상10) + 정답 + 추가서술형 20문항 + 정답 + 세션 트랜스크립트. 상세는 `제작_가이드.md` 3장.

| 장 | 제목 | 근거 | 비고 |
|---|---|---|---|
| 1 | RAC 개요와 아키텍처 | R1, C1 | 공유 디스크 구조, Cache Fusion, 단일 인스턴스와의 차이, 라이선스 경계 |
| 2 | Clusterware 구조와 프로세스 | C1, C2 | CRS·CSS·EVM 스택, `ohasd`·`crsd`, 자원(resource) 개념, 시작 순서 |
| 3 | 클러스터 설치 준비 — 네트워크와 스토리지 | C2, A2 | 공용·사설 네트워크, SCAN·VIP, 공유 디스크 요건, `cluvfy` |
| 4 | Grid Infrastructure 설치 | C2 + GI | 응답 파일 설치, `root.sh`, 설치 후 검증, 실패 시 되돌리기 |
| 5 | OCR·Voting File 관리 | C5 | 백업·복원, 위치 이동, 다중화, 손실 시 복구 |
| 6 | ASM 인스턴스와 디스크그룹 | A1, A3, A4 | ASM 인스턴스 파라미터, 디스크그룹 생성·마운트, 이중화 수준 |
| 7 | ASM 파일·디렉터리·템플릿 | A5 | OMF 이름 규칙, 별칭, 템플릿, 파일 접근 |
| 8 | ASM 리밸런스와 이중화 | A4 | 디스크 추가·삭제, 리밸런스 관찰, 장애 그룹, 디스크 손실 대응 |
| 9 | ASM 뷰와 asmcmd | A6, A9 | `V$ASM_*` 계열, `asmcmd` 명령 체계, ASMCA |
| 10 | ASM 마이그레이션 — RMAN 활용 | A8 | 파일 시스템 → ASM, 디스크그룹 간 이동, 되돌리기 |
| 11 | RAC 데이터베이스 생성 | R1, R3 | DBCA 무인 설치, 인스턴스 이름·스레드·UNDO 분리, 생성 결과 검증 |
| 12 | 인스턴스와 클러스터 DB 관리 | R3 | 기동·정지 순서, SPFILE 의 `sid.parameter`, 세 분류, PDB 관리 |
| 13 | RAC 스토리지 관리 | R2 | 스레드별 리두, UNDO 테이블스페이스, 임시 테이블스페이스, 파일 추가 |
| 14 | srvctl·crsctl 명령 체계 | C2, R3 | 두 명령의 역할 분담, 자원 유형별 사용법, 오류 번호 읽기 |
| 15 | 동적 데이터베이스 서비스 | R5 | 서비스 생성·이동, 선호/가용 인스턴스, 접속 부하 분산 |
| 16 | 부하 관리와 Application Continuity | R5, R6 | FAN, 부하 분산 권고, 투명한 애플리케이션 이어 가기 |
| 17 | RAC 백업과 복구 | R7, R8 | 아카이브 구성, 노드 분산 백업, 인스턴스 복구와 미디어 복구 |
| 18 | 노드 추가와 삭제 | C6 | `addnode.sh`, 노드 정리, 검증, 실패 시 롤백 |
| 19 | RAC One Node | R4 | 온라인 재배치, 단일 인스턴스와 RAC 사이의 선택 |
| 20 | 진단·성능·종합 운영 | R1, C2, R8 | 클러스터 대기 이벤트, 로그 수집(`diagcollection`), 종합 점검표, RAC + Data Guard |

### 3-1. 원본에서 축소하거나 제외한 것

| 원본 | 처리 | 이유 |
|---|---|---|
| C3 Policy-Based Management | **20장에서 개념만** | 서버 풀은 대규모 클러스터의 주제. 2노드 랩에서 실측 가치가 낮다 |
| C4 Flex Clusters | **제외** | Hub/Leaf 구성은 4노드 이상이 필요하다. 개요만 1장에 한 문단 |
| C7 Cloning Clusterware / R9 Cloning RAC | **18장에 흡수** | 노드 추가의 한 방법으로만 다룬다 |
| C8 애플리케이션 HA (`crsctl add resource`) | **14장에 흡수** | 자원 관리의 한 사례로 |
| A7 EM 으로 ASM 관리 | **제외** | GUI 중심. 이 과정은 CLI 로 간다 |
| R6 클라이언트별 설정(JDBC·OCI·ODP.NET) | **16장에서 요약** | 애플리케이션 개발 영역. 서버 쪽 구성만 실측 |

### 3-2. 20장으로 잡은 근거

- 세 문서 1,984쪽은 ADG 원본(356쪽)의 5.6배다. 같은 밀도로 다루면 90장이 넘으므로 **실습 가능한 것 위주로 압축**했다.
- ASM 을 5장(6~10)으로 둔 이유 — RAC 의 스토리지는 사실상 ASM 이고, 단일 노드 Oracle Restart 로도 쓰이는 독립 주제라 축소하면 과정의 실용성이 떨어진다.
- Clusterware 를 5장(2~5, 18)으로 나눈 이유 — 설치·OCR·노드 관리는 각각 실습 단위가 다르다.
- 12·13·14장을 나눈 이유 — "인스턴스 관리"·"스토리지"·"명령 체계"는 실습에서 섞이지 않는다.

---

## 4. 실습 환경

### 4-1. 구성

| 항목 | 노드 1 | 노드 2 |
|---|---|---|
| 호스트명 | `rac1` | `rac2` |
| 공용 (VMnet8 NAT) | `172.16.225.101` | `172.16.225.102` |
| VIP | `172.16.225.111` (`rac1-vip`) | `172.16.225.112` (`rac2-vip`) |
| 사설 인터커넥트 (VMnet1) | `172.16.119.101` | `172.16.119.102` |
| SCAN | `rac-scan` → `172.16.225.120` (단일 IP, `/etc/hosts` 기반) | |
| 메모리 / CPU | 8GB / 4 vCPU | 8GB / 4 vCPU |
| OS | Oracle Linux 7.9 | Oracle Linux 7.9 |

### 4-2. 공유 디스크 (VMware `sharedBus="virtual"`)

| 디스크그룹 | 개수 × 크기 | 이중화 | 용도 |
|---|---|---|---|
| `+CRS` | 3 × 5GB | Normal | OCR·Voting File. **3개인 이유는 Voting File 이 3벌 필요하기 때문** |
| `+DATA` | 3 × 20GB | External | 데이터 파일·SPFILE·컨트롤 파일 |
| `+FRA` | 2 × 15GB | External | 아카이브·플래시백·백업 |

디스크를 이렇게 나눈 것은 8장(리밸런스·이중화)과 5장(Voting File 다중화)의 실습을 위해서다. 단일 디스크그룹으로는 그 실습이 성립하지 않는다.

### 4-3. 소프트웨어

| 구분 | 값 |
|---|---|
| Grid 홈 | `/u01/app/19.0.0/grid` (소유자 `grid`) |
| Oracle 홈 | `/u01/app/oracle/product/19.0.0/dbhome_1` (소유자 `oracle`) |
| DB 이름 | `racdb` — 인스턴스 `racdb1`(rac1) / `racdb2`(rac2) |
| PDB | `racpdb1` |
| 설치 매체 | `D:\Oracle\설치파일\2026-03\19c_grid_linux.zip`, `19c_db_linux.zip` |

### 4-4. 원칙

- **모든 수치·오류 번호는 이 환경에서 실측한다.** 문서에서 옮겨 적지 않는다.
- **되돌리기** — 각 장의 실습은 끝에서 기준 상태로 복귀한다. 되돌릴 수 없는 실습(노드 삭제 등)은 **스냅샷을 먼저 뜨고** 시작한다.
- **스냅샷은 전원을 끈 상태로 뜬다.** ADG 과정에서 확인한 규칙이며, RAC 는 두 노드의 시점이 어긋나면 클러스터가 깨지므로 **양쪽을 동시에 정지한 뒤** 떠야 한다.
- ADG 랩(`D:\ADG\`)은 정지 상태로 보존한다. 삭제하지 않는다.

---

## 5. 진행 순서

| 단계 | 내용 | 예상 |
|---|---|---|
| 0 | ADG 랩 정지 | 완료 |
| 1 | 노드 2대 생성 (OEL7V9 복제, 네트워크·커널 파라미터·사용자) | — |
| 2 | 공유 디스크 8개 생성과 연결, `oracleasm` 또는 udev 설정 | — |
| 3 | Grid Infrastructure 설치 + `root.sh` | — |
| 4 | 디스크그룹 `+DATA`·`+FRA` 추가, DBCA 로 `racdb` 생성 | — |
| 5 | 기준 상태 스냅샷 `rac-base` | — |
| 6 | 1장부터 순차 제작 | — |

**1~5단계 자체가 3·4·11장의 실습 재료가 된다.** 설치 과정에서 만나는 오류와 그 조치를 그대로 트랜스크립트로 남긴다.
