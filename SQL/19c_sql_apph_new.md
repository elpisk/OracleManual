# Oracle Database 19c: SQL Workshop
## Appendix H — Oracle 데이터베이스 아키텍처 (Oracle Database Architectural Components)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- Oracle 데이터베이스 Instance와 Database의 차이를 설명한다
- SGA(System Global Area)의 구성 요소와 역할을 설명한다
- PGA(Program Global Area)의 역할을 설명한다
- 주요 백그라운드 프로세스와 각 역할을 설명한다
- Oracle 스토리지 구조의 계층을 설명한다
- SQL 문이 처리되는 과정(Parse, Execute, Fetch)을 설명한다
- COMMIT 처리 과정을 설명한다

---

## 1. Oracle Database 구조 개요

Oracle Database는 크게 **Instance**와 **Database**로 구분된다.

```
┌──────────────────────────────────────┐
│          Oracle Instance             │
│  ┌─────────────┐  ┌───────────────┐  │
│  │     SGA     │  │  Background   │  │
│  │ (메모리 영역) │  │  Processes    │  │
│  └─────────────┘  └───────────────┘  │
└──────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│          Oracle Database             │
│  ┌────────────┐  ┌────────────────┐  │
│  │ Data Files │  │ Redo Log Files │  │
│  └────────────┘  └────────────────┘  │
│  ┌─────────────────────────────────┐  │
│  │       Control File              │  │
│  └─────────────────────────────────┘  │
└──────────────────────────────────────┘
```

| 구분 | 설명 |
|------|------|
| **Instance** | 메모리(SGA) + 백그라운드 프로세스의 조합. 서버 시작 시 생성 |
| **Database** | 디스크의 물리적 파일(Data Files, Redo Log Files, Control File) 집합 |

**핵심:** Instance는 Database를 액세스하는 수단이며, Instance 없이 Database에 직접 접근할 수 없다.

---

## 2. System Global Area (SGA)

SGA는 Oracle Instance가 시작될 때 메모리에 할당되는 **공유 메모리 영역**이다.

```
┌──────────────────────────────────────────────────────┐
│                  SGA (System Global Area)             │
│  ┌──────────────────┐  ┌──────────────────────────┐   │
│  │  Database Buffer │  │      Shared Pool          │   │
│  │      Cache       │  │  ┌────────────────────┐   │   │
│  │  (데이터 블록 캐시)│  │  │  Library Cache     │   │   │
│  │                  │  │  │  (파싱된 SQL/PL/SQL) │   │   │
│  └──────────────────┘  │  └────────────────────┘   │   │
│                        │  ┌────────────────────┐   │   │
│  ┌──────────────────┐  │  │  Data Dictionary   │   │   │
│  │  Redo Log Buffer │  │  │  Cache             │   │   │
│  │  (변경 이력 로그) │  │  └────────────────────┘   │   │
│  └──────────────────┘  └──────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

### 2.1 Database Buffer Cache

- 디스크에서 읽은 **데이터 블록**을 캐시하는 메모리 영역
- Oracle이 데이터를 읽을 때 먼저 Buffer Cache를 확인 → 없으면 디스크에서 읽어 Cache에 저장
- **LRU(Least Recently Used)** 알고리즘으로 오래된 블록 제거
- 크기: `DB_CACHE_SIZE` 파라미터로 제어

```
SQL 처리 흐름:
  1. SELECT → Buffer Cache 확인
  2. 캐시 히트(Hit): 메모리에서 바로 반환 (빠름)
  3. 캐시 미스(Miss): 디스크에서 읽어 Cache에 적재 후 반환 (느림)
```

### 2.2 Shared Pool

파싱된 SQL/PL/SQL과 데이터 딕셔너리 정보를 캐시하는 영역.

**Library Cache:**
- 파싱된 SQL/PL/SQL 문의 실행 계획(Execution Plan) 저장
- 동일 SQL 재실행 시 파싱 단계 건너뜀 → 성능 향상
- 소프트 파싱(Soft Parse) vs 하드 파싱(Hard Parse)

```sql
-- 소프트 파싱 예: 동일 SQL 두 번째 실행 시 Library Cache에서 재사용
SELECT last_name FROM employees WHERE department_id = 80;
SELECT last_name FROM employees WHERE department_id = 80;  -- 빠름!
```

**Data Dictionary Cache (Row Cache):**
- 테이블 정의, 컬럼 정보, 권한 등 데이터 딕셔너리 정보 캐시
- SQL 파싱 시 딕셔너리를 반복 조회하는 비용 감소

### 2.3 Redo Log Buffer

- 데이터 변경 내역(INSERT/UPDATE/DELETE)을 임시 저장하는 순환 버퍼
- LGWR 백그라운드 프로세스가 주기적으로 디스크의 Redo Log File에 기록
- 장애 복구(Recovery)의 핵심 역할

---

## 3. Program Global Area (PGA)

PGA는 **각 서버 프로세스(사용자 세션)가 독자적으로 사용하는 메모리 영역**이다.

| 항목 | SGA | PGA |
|------|-----|-----|
| 공유 여부 | 모든 세션 공유 | 세션 전용 |
| 저장 내용 | 데이터 캐시, 파싱 결과 | 정렬 공간, 세션 변수 |
| 크기 파라미터 | `SGA_TARGET` | `PGA_AGGREGATE_TARGET` |

**PGA 주요 구성:**
- **SQL Work Area**: 정렬(ORDER BY), 해시 조인(HASH JOIN), 비트맵 연산에 사용
- **Session Memory**: 로그인 정보, 세션 상태 저장
- **Private SQL Area**: 바인드 변수 값, 실행 상태

```sql
-- PGA 사용량 모니터링
SELECT sid, pga_used_mem, pga_alloc_mem, pga_freeable_mem
FROM   v$process
ORDER BY pga_alloc_mem DESC;
```

---

## 4. 백그라운드 프로세스 (Background Processes)

Oracle Instance는 여러 백그라운드 프로세스로 구성되며 각각 특정 역할을 담당한다.

### 4.1 DBWn (Database Writer)

- **Buffer Cache의 Dirty Buffer를 디스크(Data File)에 기록**
- 여러 개 존재 가능: DBW0, DBW1, ... DBW9, DBWa, ...
- 기록 시점:
  - Checkpoint 발생 시
  - Buffer Cache가 부족할 때
  - 일정 수의 Dirty Buffer 누적 시

### 4.2 LGWR (Log Writer)

- **Redo Log Buffer 내용을 Redo Log File에 기록**
- 기록 시점:
  - COMMIT 발생 시 (즉시)
  - Redo Log Buffer가 1/3 이상 찼을 때
  - 3초마다 주기적으로
  - DBWn이 Data File에 쓰기 전

```
COMMIT 처리:
  사용자 → LGWR가 Redo Log File에 기록 완료 → 사용자에게 완료 응답
  (Data File 쓰기는 나중에 DBWn이 처리)
```

### 4.3 CKPT (Checkpoint)

- **Checkpoint 정보를 Control File과 Data File Header에 기록**
- DBWn에게 Dirty Buffer를 기록하도록 신호
- 복구 시작점(SCN: System Change Number)을 기록
- 복구 시간(MTTR: Mean Time To Recover)을 최소화

### 4.4 SMON (System Monitor)

- **Instance 시작 시 자동 복구(Instance Recovery) 수행**
- Redo Log를 적용하여 Commit된 데이터 복구
- Rollback되지 않은 트랜잭션 정리
- 임시 세그먼트(Temporary Segment) 정리

### 4.5 PMON (Process Monitor)

- **실패한 사용자 프로세스 정리**
- 실패한 프로세스의 Lock 해제, Rollback 수행
- 리소스(메모리, Lock) 반환

### 4.6 RECO (Recoverer)

- **분산 데이터베이스의 실패한 분산 트랜잭션 복구**
- 다른 데이터베이스와 연결이 복구되면 미완료 분산 트랜잭션을 자동으로 커밋 또는 롤백

### 4.7 ARCn (Archiver)

- **가득 찬 Redo Log File을 Archive 위치에 복사**
- ARCHIVELOG 모드에서만 활동
- 백업과 Point-in-Time Recovery를 위한 Archived Log 생성

| 프로세스 | 주요 역할 | 기동 조건 |
|---------|-----------|-----------|
| DBWn | Buffer Cache → Data File 기록 | 항상 |
| LGWR | Redo Buffer → Redo Log File 기록 | 항상 |
| CKPT | Checkpoint 정보 기록 | 항상 |
| SMON | Instance 복구, 임시 세그먼트 정리 | 항상 |
| PMON | 실패 프로세스 정리 | 항상 |
| RECO | 분산 트랜잭션 복구 | 분산 DB 사용 시 |
| ARCn | Redo Log 아카이브 | ARCHIVELOG 모드 |

---

## 5. 스토리지 구조 (Storage Structures)

Oracle 스토리지는 논리적 구조와 물리적 구조로 계층화된다.

```
논리적 구조                   물리적 구조
────────────────              ────────────────
Database                      
  └─ Tablespace           →   Data File(s)
       └─ Segment              
            └─ Extent         
                 └─ Block  →  OS Block(s)
```

### 5.1 논리적 구조

| 구조 | 설명 |
|------|------|
| **Database** | 가장 상위 논리 단위 |
| **Tablespace** | 테이블, 인덱스 등을 저장하는 논리 컨테이너 (예: SYSTEM, USERS, TEMP) |
| **Segment** | 특정 객체(테이블, 인덱스)를 위한 공간 (Data/Index/Rollback/Temp 세그먼트) |
| **Extent** | 연속된 블록의 집합. 세그먼트 확장 시 Extent 단위로 할당 |
| **Block** | Oracle I/O의 최소 단위 (기본 8KB). DB_BLOCK_SIZE 파라미터로 설정 |

### 5.2 물리적 파일

| 파일 | 역할 |
|------|------|
| **Data File** (.dbf) | 실제 테이블/인덱스 데이터 저장 |
| **Redo Log File** (.log) | 모든 변경 내역 저장 (복구용) |
| **Control File** (.ctl) | DB 이름, 파일 위치, Checkpoint 정보 저장 |
| **Parameter File** (spfile.ora) | Instance 시작 파라미터 저장 |
| **Password File** | SYSDBA 권한 로그인 인증 |
| **Archive Log** | 가득 찬 Redo Log의 복사본 (ARCHIVELOG 모드) |

```sql
-- 데이터 파일 목록 확인
SELECT file_name, tablespace_name, bytes/1024/1024 AS mb, status
FROM   dba_data_files ORDER BY tablespace_name;

-- Redo Log 파일 확인
SELECT group#, member FROM v$logfile ORDER BY group#;
```

---

## 6. SQL 문 처리 과정 (SQL Processing)

SQL 문이 Oracle에서 처리되는 단계:

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  Parse  │───►│  Bind   │───►│ Execute │───►│  Fetch  │
│ (파싱)  │    │(바인딩) │    │ (실행)  │    │ (인출)  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
```

### 6.1 Parse (파싱)

SQL 문을 분석하여 실행 계획을 수립하는 단계.

**하드 파싱 (Hard Parse):**
1. 구문 분석 (Syntax Check): SQL 문법 오류 검사
2. 의미 분석 (Semantic Check): 테이블/컬럼 존재 여부, 권한 확인
3. 실행 계획 생성 (Optimization): 옵티마이저가 최적 실행 계획 결정
4. Library Cache에 저장

**소프트 파싱 (Soft Parse):**
- Library Cache에 동일 SQL의 실행 계획이 이미 있으면 재사용
- 구문/의미 분석 + 최적화 단계 건너뜀 → 빠름

```sql
-- 바인드 변수 사용으로 소프트 파싱 유도 (권장)
SELECT last_name FROM employees WHERE employee_id = :emp_id;
-- 리터럴 사용 시 매번 하드 파싱 (비권장)
SELECT last_name FROM employees WHERE employee_id = 100;
SELECT last_name FROM employees WHERE employee_id = 101;
```

### 6.2 Bind (바인딩)

- 바인드 변수(`:변수명`)에 실제 값을 대입하는 단계
- 바인드 변수 사용 시 동일 SQL 공유 → Library Cache 효율 극대화

### 6.3 Execute (실행)

- 실행 계획에 따라 실제 데이터 처리 수행
- **DML(INSERT/UPDATE/DELETE)**: Execute 단계에서 완료
- **SELECT**: Execute 후 → Fetch 단계 진행

### 6.4 Fetch (인출)

- SELECT 결과 행을 애플리케이션으로 전송
- 배열 인출(Array Fetch)로 여러 행을 한 번에 전송하여 네트워크 왕복 최소화

---

## 7. COMMIT 처리 과정

COMMIT이 실행되면 Oracle은 다음 순서로 처리한다.

```
1. COMMIT 명령 발행
2. LGWR가 Redo Log Buffer를 Redo Log File에 기록 (즉시)
3. 사용자에게 "커밋 완료" 응답
4. SCN(System Change Number) 증가
5. Lock 해제
6. (나중에) DBWn이 Buffer Cache의 Dirty Buffer를 Data File에 기록
```

**핵심:** Data File에 쓰기 전에 Redo Log에 먼저 기록 → **"Write-Ahead Logging" 원칙**

```
ROLLBACK 처리:
1. ROLLBACK 명령 발행
2. Undo Segment에서 이전 값을 읽어 변경 내용 취소
3. Lock 해제
```

| 구분 | Redo Log | Data File |
|------|----------|-----------|
| COMMIT | LGWR가 즉시 기록 | DBWn이 나중에 기록 |
| 복구 시 | Redo Log로 Commit 데이터 재현 | Data File 직접 사용 |

---

## 8. 데이터 딕셔너리 뷰 (아키텍처 관련)

```sql
-- SGA 구성 요소 크기 확인
SELECT name, bytes/1024/1024 AS mb
FROM   v$sgainfo ORDER BY bytes DESC;

-- 백그라운드 프로세스 목록
SELECT pname, description
FROM   v$bgprocess
WHERE  paddr != '00'
ORDER BY pname;

-- Library Cache 적중률 확인
SELECT namespace,
       gets, gethits,
       ROUND(gethitratio*100, 2) AS hit_ratio
FROM   v$librarycache
ORDER BY gets DESC;

-- Buffer Cache 적중률 확인
SELECT ROUND((1 - phyrds/(dbgr+congets))*100, 2) AS buffer_hit_ratio
FROM (SELECT SUM(value) dbgr FROM v$sysstat WHERE name = 'db block gets'),
     (SELECT SUM(value) congets FROM v$sysstat WHERE name = 'consistent gets'),
     (SELECT SUM(value) phyrds FROM v$sysstat WHERE name = 'physical reads');
```

---

## 9. 단원 요약

| 구성 요소 | 핵심 내용 |
|-----------|-----------|
| **Instance** | SGA + 백그라운드 프로세스; 메모리에서 동작 |
| **Database** | Data File, Redo Log File, Control File; 디스크에 저장 |
| **SGA** | Buffer Cache(데이터 캐시) + Shared Pool(파싱 캐시) + Redo Buffer |
| **PGA** | 세션 전용 메모리; 정렬, 해시 조인, 세션 변수 |
| **DBWn** | Dirty Buffer → Data File 기록 |
| **LGWR** | Redo Buffer → Redo Log File 기록 (COMMIT 시 즉시) |
| **CKPT** | Checkpoint 정보 기록 |
| **SMON/PMON** | Instance 복구 / 실패 프로세스 정리 |
| **SQL 처리** | Parse → Bind → Execute → Fetch |
| **COMMIT** | LGWR 기록 후 완료 응답 → DBWn이 나중에 Data File에 기록 |
