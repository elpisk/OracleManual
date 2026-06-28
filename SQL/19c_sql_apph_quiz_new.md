# Oracle Database 19c: SQL Workshop
## Appendix H — Oracle 데이터베이스 아키텍처 | 연습문제

---

> **문제 구성:** 하(기초) 20문제 + 중(응용) 20문제 + 상(심화) 10문제 = 총 50문제

---

## 하(기초) — 20문제

**[1번]** Oracle Instance의 구성 요소로 올바른 것은?

① Data File + Redo Log File  
② SGA + 백그라운드 프로세스  
③ Tablespace + Segment  
④ Control File + Parameter File

---

**[2번]** Oracle Database(물리적 의미)에 포함되지 않는 것은?

① Data File  
② Redo Log File  
③ Control File  
④ SGA 메모리

---

**[3번]** SGA(System Global Area)에 대한 설명으로 옳은 것은?

① 각 사용자 세션이 독립적으로 사용하는 메모리 영역이다  
② Instance 시작 시 할당되는 공유 메모리 영역이다  
③ 디스크에 저장되는 물리적 파일이다  
④ 백그라운드 프로세스만 접근할 수 있다

---

**[4번]** Database Buffer Cache의 역할로 옳은 것은?

① 파싱된 SQL 실행 계획을 저장한다  
② 데이터 변경 내역을 임시 저장한다  
③ 디스크에서 읽은 데이터 블록을 캐시한다  
④ 사용자 세션 정보를 저장한다

---

**[5번]** Shared Pool의 Library Cache에 저장되는 것은?

① 데이터 블록  
② 파싱된 SQL/PL/SQL 실행 계획  
③ Redo 로그 기록  
④ Undo 데이터

---

**[6번]** Redo Log Buffer에 대한 설명으로 옳은 것은?

① 데이터 블록을 디스크에서 읽어 저장하는 영역이다  
② 데이터 변경 내역을 임시 저장하는 순환 버퍼이다  
③ SQL 실행 계획을 저장하는 영역이다  
④ 사용자별 전용 메모리 영역이다

---

**[7번]** PGA(Program Global Area)에 대한 설명으로 옳은 것은?

① 모든 세션이 공유하는 메모리 영역이다  
② 각 서버 프로세스(세션)가 독자적으로 사용하는 메모리이다  
③ Instance 시작 시 한 번만 할당된다  
④ 디스크에 저장된다

---

**[8번]** DBWn(Database Writer) 프로세스의 역할은?

① Redo Log Buffer를 Redo Log File에 기록한다  
② Buffer Cache의 Dirty Buffer를 Data File에 기록한다  
③ 실패한 사용자 프로세스를 정리한다  
④ Checkpoint 정보를 Control File에 기록한다

---

**[9번]** LGWR(Log Writer) 프로세스가 Redo Log File에 기록하는 시점이 아닌 것은?

① COMMIT 발생 시  
② Redo Log Buffer가 1/3 이상 찼을 때  
③ SELECT 문 실행 시  
④ 3초마다 주기적으로

---

**[10번]** SMON 프로세스의 주요 역할은?

① 실패한 사용자 프로세스 정리  
② Instance 시작 시 자동 복구 수행  
③ Redo Log를 Archive로 복사  
④ Checkpoint 정보 기록

---

**[11번]** PMON 프로세스가 수행하는 작업은?

① 분산 트랜잭션 복구  
② 실패한 사용자 프로세스의 Lock 해제 및 Rollback  
③ Buffer Cache 정리  
④ Redo Log 기록

---

**[12번]** ARCn 프로세스에 대한 설명으로 옳은 것은?

① 항상 활성화되어 있다  
② ARCHIVELOG 모드에서만 활동한다  
③ Data File을 백업한다  
④ SGA 메모리를 관리한다

---

**[13번]** Oracle 스토리지 논리적 구조의 계층 순서로 올바른 것은?

① Database → Tablespace → Segment → Extent → Block  
② Tablespace → Database → Block → Extent → Segment  
③ Block → Extent → Segment → Database → Tablespace  
④ Database → Block → Extent → Segment → Tablespace

---

**[14번]** Tablespace와 Data File의 관계로 옳은 것은?

① 하나의 Tablespace는 반드시 하나의 Data File만 가진다  
② 하나의 Tablespace는 하나 이상의 Data File을 가질 수 있다  
③ Data File과 Tablespace는 무관하다  
④ 하나의 Data File은 여러 Tablespace에 속할 수 있다

---

**[15번]** Oracle Block의 기본 크기는?

① 2KB  
② 4KB  
③ 8KB  
④ 16KB

---

**[16번]** SQL 처리 과정의 올바른 순서는?

① Execute → Parse → Bind → Fetch  
② Parse → Bind → Execute → Fetch  
③ Bind → Parse → Fetch → Execute  
④ Fetch → Execute → Bind → Parse

---

**[17번]** 하드 파싱(Hard Parse)이 발생하는 상황은?

① 동일한 SQL이 Library Cache에 있을 때  
② 바인드 변수를 사용하는 SQL이 처음 실행될 때  
③ Library Cache에서 SQL을 찾을 수 없을 때  
④ SELECT 문이 아닌 DML을 실행할 때

---

**[18번]** COMMIT이 완료되는 시점은?

① DBWn이 Data File에 모든 변경 내용을 기록한 후  
② LGWR이 Redo Log File에 기록을 완료한 후  
③ Checkpoint가 발생한 후  
④ SMON이 복구를 완료한 후

---

**[19번]** Control File에 저장되는 정보가 아닌 것은?

① 데이터베이스 이름  
② Data File 위치  
③ Checkpoint 정보  
④ 테이블 데이터

---

**[20번]** Instance Recovery(인스턴스 복구) 시 사용하는 것은?

① Data File  
② Redo Log File  
③ Parameter File  
④ Password File

---

## 중(응용) — 20문제

---

**[21번]** 다음 중 SGA에 포함되지 않는 것은?

① Database Buffer Cache  
② Shared Pool  
③ Redo Log Buffer  
④ Sort Area (SQL Work Area)

---

**[22번]** 소프트 파싱(Soft Parse)이 가능하려면?

① SQL 문이 처음 실행되어야 한다  
② 완전히 동일한 SQL 문이 Library Cache에 존재해야 한다  
③ 데이터 딕셔너리 캐시가 비어있어야 한다  
④ DML 문이어야 한다

---

**[23번]** 바인드 변수 사용의 주요 이점은?

① SQL 문 결과를 더 빠르게 가져올 수 있다  
② Library Cache에서 파싱 결과를 재사용하여 하드 파싱을 줄인다  
③ Data File I/O를 줄인다  
④ Redo Log 기록을 줄인다

---

**[24번]** COMMIT 후 데이터가 Data File에 언제 기록되는가?

① COMMIT 즉시  
② LGWR이 Redo Log File에 기록한 직후  
③ COMMIT 완료 후 DBWn이 나중에 기록 (Write-Ahead Logging)  
④ 다음 COMMIT 발생 시

---

**[25번]** Checkpoint의 역할로 옳은 것은?

① 실패한 사용자 세션을 정리한다  
② 복구 시작점(SCN)을 기록하여 Instance Recovery 시간을 단축한다  
③ Redo Log Buffer를 비운다  
④ 사용자 트랜잭션을 롤백한다

---

**[26번]** 다음 중 PGA에 저장되는 정보는?

① 파싱된 SQL 실행 계획  
② 데이터 블록 캐시  
③ 정렬 작업용 SQL Work Area  
④ 데이터 딕셔너리 정보

---

**[27번]** Oracle에서 "Write-Ahead Logging"이란?

① Data File에 쓰기 전에 Redo Log에 먼저 기록하는 원칙  
② Redo Log에 쓰기 전에 Data File을 먼저 쓰는 원칙  
③ COMMIT 전에 Undo를 먼저 기록하는 원칙  
④ SELECT 전에 캐시를 먼저 확인하는 원칙

---

**[28번]** 다음 v$bgprocess 쿼리 결과에서 활성 프로세스를 확인하는 조건은?

```sql
SELECT pname FROM v$bgprocess WHERE ???;
```

① `pname IS NOT NULL`  
② `paddr != '00'`  
③ `status = 'ACTIVE'`  
④ `pid > 0`

---

**[29번]** Library Cache 적중률(Hit Ratio)이 낮을 때 성능 개선 방법은?

① Data File 추가  
② Redo Log File 크기 증가  
③ Shared Pool 크기 증가 또는 바인드 변수 사용 권장  
④ PGA 크기 감소

---

**[30번]** ROLLBACK 처리 시 사용하는 Oracle 구조는?

① Redo Log Segment  
② Undo Segment  
③ Temporary Segment  
④ Index Segment

---

**[31번]** 다음 중 Segment 유형에 해당하지 않는 것은?

① Data Segment  
② Index Segment  
③ Rollback(Undo) Segment  
④ Checkpoint Segment

---

**[32번]** SMON과 PMON의 역할 차이로 옳은 것은?

① SMON은 사용자 프로세스 정리, PMON은 Instance 복구  
② SMON은 Instance 복구, PMON은 실패 사용자 프로세스 정리  
③ SMON은 Redo Log 기록, PMON은 Data File 기록  
④ 두 프로세스는 동일한 역할을 한다

---

**[33번]** 다음 중 ARCHIVELOG 모드의 장점은?

① 데이터베이스 성능이 향상된다  
② Point-in-Time Recovery(특정 시점 복구)가 가능하다  
③ Redo Log 파일이 필요 없다  
④ 백그라운드 프로세스 수가 줄어든다

---

**[34번]** Oracle Block 크기(`DB_BLOCK_SIZE`)를 크게 설정할 때의 특징은?

① 작은 데이터 조회에 유리하다  
② 전체 테이블 스캔에 유리하다  
③ OLTP 처리에 항상 최적이다  
④ Redo Log 크기가 줄어든다

---

**[35번]** 다음 SQL로 확인할 수 있는 정보는?

```sql
SELECT name, bytes/1024/1024 AS mb FROM v$sgainfo ORDER BY bytes DESC;
```

① 활성 백그라운드 프로세스 목록  
② SGA 각 구성 요소별 크기  
③ 현재 세션의 PGA 사용량  
④ 데이터 파일 위치와 크기

---

**[36번]** 하드 파싱을 줄이는 가장 효과적인 방법은?

① SELECT 문 대신 PL/SQL 사용  
② SQL 문에서 리터럴 값 대신 바인드 변수 사용  
③ Redo Log 버퍼 크기 증가  
④ Buffer Cache 크기 증가

---

**[37번]** 다음 중 Control File이 손상되면 발생하는 문제는?

① 특정 테이블 데이터 손실  
② 데이터베이스를 시작할 수 없다  
③ 사용자 세션이 모두 끊긴다  
④ Redo Log 기록이 중단된다

---

**[38번]** Oracle Instance가 비정상 종료 후 재시작 시 자동으로 발생하는 것은?

① Media Recovery  
② Instance Recovery (SMON 수행)  
③ Manual Archive  
④ Buffer Cache 재구성

---

**[39번]** SCN(System Change Number)이란?

① 사용자 세션 번호  
② 데이터베이스 변경 사항을 추적하는 단조 증가 숫자  
③ SGA 블록 번호  
④ 백그라운드 프로세스 번호

---

**[40번]** Extent 할당에 대한 설명으로 옳은 것은?

① Segment가 공간 부족 시 블록 단위로 공간을 추가한다  
② Segment가 공간 부족 시 Extent 단위로 공간을 추가한다  
③ Extent는 비연속적인 블록의 집합이다  
④ Tablespace 생성 시 Extent가 자동 제거된다

---

## 상(심화) — 10문제

---

**[41번]** 다음 중 SELECT 문 처리 시 Execute 단계에서 수행되는 작업이 아닌 것은?

① 인덱스 또는 Full Table Scan 결정  
② 조인 수행  
③ 결과 행을 애플리케이션으로 전송 (Fetch)  
④ WHERE 조건 적용

---

**[42번]** Buffer Cache 적중률(Buffer Hit Ratio)이 낮을 때의 올바른 해석은?

① 디스크 I/O보다 메모리 액세스가 더 많이 발생하고 있다  
② 캐시에서 데이터를 찾지 못해 디스크 I/O가 자주 발생한다 (성능 저하)  
③ SQL 파싱이 비효율적으로 이루어지고 있다  
④ Redo Log 기록이 너무 많다

---

**[43번]** 다음 상황에서 데이터 유실 가능성에 대한 설명으로 옳은 것은?

*"COMMIT 후 DBWn이 Data File에 아직 기록하지 않은 상태에서 서버가 다운되었다."*

① Commit 데이터는 Data File에 없으므로 유실된다  
② Commit 데이터는 Redo Log에 이미 기록되어 있어 복구 가능하다  
③ Undo Segment에서 복구한다  
④ 데이터 유실 여부는 DBWn에 달려 있다

---

**[44번]** 동일한 SQL인데 Library Cache에서 재사용되지 않는 이유로 가장 흔한 것은?

① SQL 문에 주석이 포함되어 있다  
② 대소문자나 공백이 다른 SQL 문은 다른 SQL로 인식된다  
③ 사용자가 다르면 재사용이 불가능하다  
④ DML 문은 절대 재사용되지 않는다

---

**[45번]** 다음 중 CKPT 프로세스가 수행하지 않는 작업은?

① Data File Header에 SCN 기록  
② Control File에 Checkpoint 정보 기록  
③ DBWn에게 Dirty Buffer 기록 신호 전송  
④ Redo Log Buffer를 Redo Log File에 기록

---

**[46번]** 다음 v$librarycache 쿼리에서 GETHITRATIO가 0.95 미만인 경우 의미하는 것은?

```sql
SELECT namespace, gethitratio FROM v$librarycache;
```

① SQL 파싱 결과의 5% 미만이 캐시에서 재사용된다  
② SQL 파싱 결과의 95% 이상이 하드 파싱이다  
③ Library Cache 미스율이 5%를 초과하여 성능 개선이 필요하다  
④ Shared Pool이 너무 크다

---

**[47번]** RAC(Real Application Clusters) 환경에서 여러 Instance가 하나의 Database를 공유할 때, 각 Instance는?

① 독립적인 Data File 세트를 사용한다  
② 동일한 SGA를 공유한다  
③ 각자의 SGA를 가지고 동일한 Database를 공유한다  
④ 별도의 Control File을 각각 가진다

---

**[48번]** 다음 중 Temporary Tablespace의 용도로 옳은 것은?

① 테이블 영구 데이터 저장  
② ORDER BY, GROUP BY, 해시 조인 등 임시 작업 공간  
③ Undo 데이터 저장  
④ 시스템 딕셔너리 저장

---

**[49번]** 다음 시나리오에서 발생하는 문제와 해결 프로세스로 옳은 것은?

*"사용자 A가 대량 UPDATE 중 갑자기 세션이 끊겼다."*

① SMON이 자동으로 해당 UPDATE를 커밋한다  
② PMON이 해당 세션의 Lock을 해제하고 미완료 트랜잭션을 롤백한다  
③ DBWn이 Data File을 정리한다  
④ CKPT가 Checkpoint를 발생시켜 정리한다

---

**[50번]** 다음 중 Media Recovery(미디어 복구)가 필요한 상황은?

① Instance 비정상 종료 후 재시작  
② 사용자 프로세스 실패  
③ Data File이 물리적으로 손상된 경우  
④ 분산 트랜잭션 실패
