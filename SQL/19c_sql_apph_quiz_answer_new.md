# Oracle Database 19c: SQL Workshop
## Appendix H — Oracle 데이터베이스 아키텍처 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② | Oracle Instance = SGA(메모리) + 백그라운드 프로세스 |
| 2 | ④ | SGA는 Instance의 메모리 영역; Database는 디스크 파일 집합 |
| 3 | ② | SGA = Instance 시작 시 할당되는 공유 메모리 (모든 세션 공유) |
| 4 | ③ | Buffer Cache = 디스크에서 읽은 데이터 블록을 메모리에 캐시 |
| 5 | ② | Library Cache = 파싱된 SQL/PL/SQL 실행 계획 저장 |
| 6 | ② | Redo Log Buffer = 데이터 변경 내역을 임시 저장하는 순환 버퍼 |
| 7 | ② | PGA = 각 서버 프로세스(세션) 전용 메모리 (세션별 독립) |
| 8 | ② | DBWn = Buffer Cache의 Dirty Buffer → Data File 기록 |
| 9 | ③ | SELECT 실행 시는 LGWR이 기록하지 않음 (데이터 변경 없음) |
| 10 | ② | SMON = Instance 시작 시 자동 복구 (Instance Recovery) |
| 11 | ② | PMON = 실패한 사용자 프로세스의 Lock 해제 + Rollback |
| 12 | ② | ARCn = ARCHIVELOG 모드에서만 활동; Redo Log를 Archive로 복사 |
| 13 | ① | Database → Tablespace → Segment → Extent → Block (큰 → 작은 단위) |
| 14 | ② | 하나의 Tablespace = 하나 이상의 Data File 가능 (다대일 관계) |
| 15 | ③ | Oracle Block 기본 크기 = 8KB (`DB_BLOCK_SIZE` 파라미터) |
| 16 | ② | SQL 처리: Parse → Bind → Execute → Fetch |
| 17 | ③ | 하드 파싱 = Library Cache에서 SQL을 찾지 못할 때 발생 |
| 18 | ② | COMMIT 완료 = LGWR이 Redo Log File에 기록 완료 후 |
| 19 | ④ | Control File에는 DB 이름, 파일 위치, Checkpoint 정보 저장; 테이블 데이터는 Data File |
| 20 | ② | Instance Recovery: Redo Log File을 사용하여 Commit 데이터 재현 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ④**

PGA(Program Global Area)의 SQL Work Area(Sort Area 등)는 SGA가 아닌 PGA에 속한다. SGA 구성: Buffer Cache, Shared Pool, Redo Log Buffer, Large Pool, Java Pool 등.

---

**[22번] 정답: ②**

소프트 파싱이 발생하려면 완전히 동일한 SQL 문(대소문자, 공백까지 동일)이 Library Cache에 존재해야 한다. 단 한 글자라도 다르면 하드 파싱 발생.

---

**[23번] 정답: ②**

바인드 변수 사용 시 SQL 텍스트가 항상 동일 → Library Cache에서 파싱 결과 재사용 → 하드 파싱 횟수 감소 → CPU 사용량 감소 → 성능 향상.

```sql
-- 바인드 변수 사용 (권장 — 소프트 파싱)
SELECT * FROM employees WHERE employee_id = :eid;

-- 리터럴 사용 (비권장 — 매번 하드 파싱)
SELECT * FROM employees WHERE employee_id = 100;
SELECT * FROM employees WHERE employee_id = 101;
```

---

**[24번] 정답: ③**

Write-Ahead Logging 원칙: COMMIT → LGWR이 Redo Log에 즉시 기록 → 사용자에게 완료 응답 → 나중에 DBWn이 Data File에 기록. Data File 기록은 COMMIT과 동기화되지 않음.

---

**[25번] 정답: ②**

Checkpoint는 SCN(System Change Number)을 Control File과 Data File Header에 기록. Instance Recovery 시 이 SCN부터 Redo Log를 적용하면 되므로 복구 시간(MTTR) 최소화.

---

**[26번] 정답: ③**

PGA 구성: SQL Work Area(정렬, 해시 조인 등), Session Memory(로그인 정보), Private SQL Area(바인드 변수 값). 파싱 결과와 데이터 블록은 SGA에 저장.

---

**[27번] 정답: ①**

Write-Ahead Logging: 데이터를 Data File에 쓰기 전에 반드시 Redo Log에 먼저 기록. 장애 발생 시 Redo Log로 미기록 데이터를 복구할 수 있는 기반이 된다.

---

**[28번] 정답: ②**

`paddr != '00'`: paddr(Process Address)이 `00`이 아닌 경우가 실제 실행 중인 백그라운드 프로세스. `00`은 프로세스가 없음을 의미.

```sql
SELECT pname, description
FROM   v$bgprocess
WHERE  paddr != '00'
ORDER BY pname;
```

---

**[29번] 정답: ③**

Library Cache Hit Ratio가 낮다 = 파싱 결과 재사용률 낮음 = 하드 파싱 빈번. 해결책:
1. Shared Pool 크기 증가 (`ALTER SYSTEM SET SHARED_POOL_SIZE = ...`)
2. 애플리케이션에서 바인드 변수 사용 권장

---

**[30번] 정답: ②**

ROLLBACK: Undo Segment에 저장된 변경 전 값(Before Image)을 읽어 변경 내용을 취소한다. Undo Segment = Rollback Segment (Oracle 9i 이후 명칭 변경).

---

**[31번] 정답: ④**

Oracle Segment 유형: Data, Index, Rollback(Undo), Temporary. "Checkpoint Segment"는 존재하지 않는다.

---

**[32번] 정답: ②**

- **SMON**: Instance 장애 후 자동 복구 (Instance Recovery), 임시 세그먼트 정리
- **PMON**: 개별 사용자 세션 장애 처리 (Lock 해제, Rollback, 리소스 반환)

---

**[33번] 정답: ②**

ARCHIVELOG 모드의 핵심 장점:
- Redo Log 파일이 꽉 차면 ARCn이 복사 후 재사용
- 모든 변경 이력 보존 → Point-in-Time Recovery 가능
- 단점: 아카이브 공간 필요, 약간의 성능 오버헤드

---

**[34번] 정답: ②**

Block 크기가 클수록 한 번 I/O에 더 많은 데이터를 읽음 → 전체 테이블 스캔(Full Table Scan), 데이터 웨어하우스에 유리. OLTP(소량 랜덤 I/O)는 작은 Block 크기가 유리.

---

**[35번] 정답: ②**

`v$sgainfo`: SGA 각 구성 요소의 이름과 크기를 표시. 주요 구성: Fixed SGA, Variable Size, Database Buffers(Buffer Cache), Redo Buffers.

---

**[36번] 정답: ②**

리터럴 값은 각기 다른 SQL로 인식 → 매번 하드 파싱. 바인드 변수(`:변수명`)는 SQL 텍스트가 동일 → Library Cache에서 재사용 → 하드 파싱 최소화.

---

**[37번] 정답: ②**

Control File에는 Data File 위치, Redo Log 위치, DB 이름, Checkpoint 정보가 저장됨. Control File이 손상되면 Database를 마운트/오픈할 수 없어 시작 불가. 따라서 Oracle은 Control File을 여러 위치에 다중화(Multiplexing) 권장.

---

**[38번] 정답: ②**

비정상 종료 → Instance Recovery (자동, SMON 수행):
1. Redo Log 적용 (Roll Forward): Commit된 데이터 재현
2. Rollback (Roll Back): Commit 안 된 변경 취소
Media Recovery는 Data File 손상 시 수동으로 수행.

---

**[39번] 정답: ②**

SCN(System Change Number): 데이터베이스의 모든 변경을 순서대로 추적하는 단조 증가 숫자. COMMIT마다 증가. Checkpoint, Recovery, Flashback에서 일관성 기준으로 사용.

---

**[40번] 정답: ②**

Extent = 연속된 Oracle Block의 집합. Segment(테이블, 인덱스 등)가 공간 부족 시 Extent 단위로 공간을 추가 할당(Extend). 블록 단위가 아닌 Extent 단위로 할당되어 관리 효율화.

---

## 상(심화) 모범답안

---

**[41번] 정답: ③**

Fetch(인출) = 결과 행을 애플리케이션으로 전송 → Execute 단계가 아닌 별도의 Fetch 단계. Execute 단계에서는 인덱스/Full Scan 결정, 조인, WHERE 조건 적용 등 실제 데이터 처리가 이루어진다.

---

**[42번] 정답: ②**

Buffer Hit Ratio 낮음 → Cache Miss 빈번 → 데이터를 Buffer Cache에서 찾지 못하고 디스크(Data File)에서 읽는 Physical I/O 증가 → 성능 저하. 해결: Buffer Cache 크기 증가 (`DB_CACHE_SIZE`).

---

**[43번] 정답: ②**

Write-Ahead Logging 원칙에 의해:
- COMMIT 시 LGWR이 이미 Redo Log File에 기록 완료
- DBWn이 Data File에 기록 전 서버 다운 → Redo Log로 Instance Recovery 시 복구 가능
- 따라서 Commit된 데이터는 유실되지 않는다

---

**[44번] 정답: ②**

Library Cache는 SQL 텍스트 자체를 해시값으로 비교. `SELECT * FROM emp` ≠ `select * from emp` ≠ `SELECT  *  FROM emp` (공백 차이). 소문자/대문자, 공백 하나라도 다르면 다른 SQL로 인식 → 하드 파싱 발생.

---

**[45번] 정답: ④**

Redo Log Buffer → Redo Log File 기록은 **LGWR**의 역할. CKPT는:
- Data File Header에 SCN 기록
- Control File에 Checkpoint 정보 기록
- DBWn에게 Dirty Buffer 기록 신호 전송

---

**[46번] 정답: ③**

GETHITRATIO = 0.95 미만: Library Cache에서 파싱 결과를 찾을 확률이 95% 미만. 즉, 5% 이상의 요청이 하드 파싱 발생. 일반적으로 0.95 이상을 목표로 함. 미만이면 Shared Pool 증가 또는 바인드 변수 사용 권장.

---

**[47번] 정답: ③**

RAC(Real Application Clusters):
- 여러 서버(노드)가 각자의 Instance(SGA + 백그라운드 프로세스)를 가짐
- 하나의 물리적 Database(Data Files, Redo Log, Control File)를 공유
- Cache Fusion 기술로 각 Instance의 Buffer Cache 간 데이터 공유

---

**[48번] 정답: ②**

Temporary Tablespace 용도:
- `ORDER BY`, `GROUP BY`, `DISTINCT` 등 정렬 작업
- `HASH JOIN` 등 해시 작업
- 인덱스 생성 시 임시 작업 공간
- PGA 내 SQL Work Area가 부족할 때 디스크 임시 공간으로 사용

---

**[49번] 정답: ②**

**PMON** 담당:
- 사용자 세션 실패 감지
- 해당 세션의 모든 Lock 해제
- 미완료 트랜잭션(대량 UPDATE) Rollback 수행
- 사용된 메모리, 리소스 반환

---

**[50번] 정답: ③**

- **Instance Recovery**: 비정상 종료 → SMON 자동 수행 (Redo Log 사용)
- **Media Recovery**: Data File, Redo Log File의 물리적 손상 → 백업에서 복구 + Archive Log 적용
- Data File 물리 손상은 Instance Recovery로 불가 → Media Recovery 필요
