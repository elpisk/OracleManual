# Chapter 14. SQL 성능 측정

- 본 차시는 SYSDBA 권한으로 버퍼 캐시를 강제로 비움(`ALTER SYSTEM FLUSH BUFFER_CACHE`).
  SQLT 계정에는 영향 없는 인스턴스 레벨 작업이며 DDL 변경은 없음
- 아래 예제는 전부 실습 DB 실측 결과
- 소재: 같은 쿼리를 버퍼 캐시가 빈 상태(콜드)와 채워진 상태(웜)에서 각각 실행해
  Logical I/O(Buffers)와 Physical I/O(Reads)의 차이를 직접 확인

---

## 01. Why

- 지금까지 13개 챕터에서 `Buffers`를 핵심 지표로 계속 사용해왔음 — 그런데 Chapter 9·11
  에서 이미 "Buffers만으로 안 보이는 비용"을 여러 번 확인했음
- 본 차시는 그중 가장 근본적인 것, 즉 **Buffers(논리적 I/O)와 실제 디스크 접근(물리적
  I/O)의 차이**를 직접 통제된 실험으로 확인함 — 이 과정에서 배운 측정 도구들을 총정리함

## 02. Concept

- `EXPLAIN PLAN`: SQL을 실행하지 않고 옵티마이저의 예상 계획만 산출(Rows/Cost/Bytes,
  추정치)
- `DBMS_XPLAN.DISPLAY`: `EXPLAIN PLAN`으로 저장한 계획을 보기 좋게 출력
- `DBMS_XPLAN.DISPLAY_CURSOR(...'ALLSTATS LAST')`: SQL을 실제로 실행한 뒤 그 실행 통계
  (E-Rows/A-Rows/A-Time/Buffers 등)를 조회
- Logical I/O: 버퍼 캐시(메모리)에서 블록을 읽은 횟수. `Buffers`(= Consistent Gets)로
  표시됨
- Physical I/O: 디스크에서 실제로 블록을 읽어온 횟수. `Reads`로 표시됨(0이면 컬럼 자체가
  안 나타남)
- CPU Time / Elapsed Time: 실제 소요된 CPU 시간 / 전체 경과 시간(`A-Time`)
- Rows Processed: 실제로 처리된 행 수(`A-Rows`)

## 03. Oracle Internals — Buffers와 Reads는 서로 다른 것을 센다

- `Buffers`(Consistent Gets)는 "블록을 몇 번 요청했는가"를 센다 — 그 블록이 이미
  메모리(버퍼 캐시)에 있으면 디스크까지 갈 필요 없이 메모리에서 즉시 가져온다
- `Reads`(Physical Reads)는 그중 **실제로 디스크까지 가야 했던** 횟수만 센다
- 버퍼 캐시에 이미 있는 블록은 `Buffers`에는 잡히지만 `Reads`에는 잡히지 않음 — 그래서
  같은 쿼리를 반복 실행하면 `Buffers`는 그대로인데 `Reads`는 0에 가까워짐(캐시 예열
  효과, Chapter 1에서 이미 다룬 현상의 근본 원인이 바로 이것)

## 04. Example

```sql
-- (SYSDBA) 버퍼 캐시를 강제로 비움 — 이 세션 이후 첫 접근은 전부 디스크에서 읽어야 함
ALTER SYSTEM FLUSH BUFFER_CACHE;

-- (SQLT) 같은 쿼리를 연속으로 두 번 실행
SELECT claim_id, total_amt FROM medical_claims
WHERE claim_id BETWEEN '20240601-0000000' AND '20240602-0000000';
```

## 05. Execution Plan — 콜드 캐시 vs 웜 캐시 실측

**콜드 캐시(버퍼 캐시 비운 직후 첫 실행)**

```text
| Id | Operation         | Name           | A-Rows |   A-Time   | Buffers | Reads |
| 0  | SELECT STATEMENT  |                |    804 |00:00:03.46 |    3144 |  3085 |
| 1  |  TABLE ACCESS FULL| MEDICAL_CLAIMS |    804 |00:00:03.46 |    3144 |  3085 |
```

**웜 캐시(동일 쿼리 즉시 재실행)**

```text
| Id | Operation         | Name           | A-Rows |   A-Time   | Buffers |
| 0  | SELECT STATEMENT  |                |    804 |00:00:00.01 |    3144 |
| 1  |  TABLE ACCESS FULL| MEDICAL_CLAIMS |    804 |00:00:00.01 |    3144 |
```

- **`Buffers`는 3,144로 완전히 동일함** — 논리적으로 "요청한" 블록 수는 캐시 상태와
  무관하게 같기 때문
- **`Reads`는 3,085 → (0, 컬럼이 사라짐)** — 콜드 캐시에서는 요청한 블록 대부분을
  디스크에서 읽어와야 했지만, 웜 캐시에서는 전부 메모리에 있어 디스크 접근이 전혀
  없었음
- **`A-Time`은 3.46초 → 0.01초로 약 346배** — 디스크 I/O가 메모리 접근보다 압도적으로
  느리다는 것이 시간 차이로 그대로 드러남

## 06. Bad SQL — Buffers만 보고 튜닝했다면

- 이 실험에서 `Buffers`는 콜드든 웜이든 3,144로 **완전히 동일**했다. 만약 `Buffers`만
  보고 "이 쿼리는 항상 똑같은 비용"이라고 판단했다면, 346배에 달하는 실제 체감 속도
  차이를 완전히 놓쳤을 것이다
- 이는 Chapter 1(IN vs EXISTS 캐시 효과), Chapter 9(SORT UNIQUE), Chapter 11(WINDOW
  SORT PUSHED RANK)에서 반복적으로 확인한 "Buffers만으론 안 보이는 비용"의 **가장
  근본적인 원인**이 바로 이 Logical/Physical I/O 차이였다는 것을 이제 명확히 알 수 있음

## 07. Tuning — 실무에서 이 차이가 중요한 이유

- 운영 중인 DB는 자주 조회되는 데이터가 대부분 버퍼 캐시에 남아있어 웜 캐시 상태에
  가깝다 — 그래서 개발자가 같은 쿼리를 반복 테스트하면 항상 빠르게 느껴질 수 있음
- 하지만 새벽 배치, 오랜만에 조회하는 오래된 데이터, DB 재시작 직후, 또는 버퍼 캐시가
  작아 자주 밀려나는 대용량 테이블은 콜드 캐시에 가까운 상황을 자주 겪음 — 개발 환경
  에서의 "체감상 빠름"이 운영 환경에서 그대로 재현되지 않을 수 있다는 뜻
- `Buffers`(Consistent Gets)가 낮은 SQL을 만드는 것이 여전히 중요한 이유: `Buffers`가
  낮으면 콜드 캐시 상황에서의 최악의 경우(전부 물리 I/O)에도 피해가 그만큼 제한됨 —
  결국 이번 챕터에서 배운 "Buffers를 줄이는 여러 기법"(인덱스, 조인 제거, N+1 회피 등)
  전부가 물리 I/O 상황에서 더더욱 중요해진다

## 08. Benchmark

| 상태 | Buffers | Reads | A-Time |
|---|---:|---:|---|
| 콜드 캐시(첫 실행) | 3,144 | 3,085 | 3.46초 |
| 웜 캐시(재실행) | 3,144 | 0(표시 안 됨) | 0.01초 |
| 배율 | 1배(동일) | - | 약 346배 |

## 09. Practice

- 실습문제 10문항: `SQL튜닝_Ch14_문제.md` 참고

## 10. Review

- `EXPLAIN PLAN`은 실행 전 추정치, `DBMS_XPLAN.DISPLAY_CURSOR(...'ALLSTATS LAST')`는
  실제 실행 후 통계 — 이 구분은 Chapter 2부터 계속 사용해온 원칙
- `Buffers`(논리적 I/O)와 `Reads`(물리적 I/O)는 서로 다른 것을 측정하며, 버퍼 캐시
  상태에 따라 같은 `Buffers`라도 실제 소요 시간이 수백 배 차이 날 수 있음
- 개발 환경에서의 반복 테스트는 웜 캐시 상태이기 쉬워 콜드 캐시의 실제 비용을 과소평가
  하게 만들 수 있음
- `Buffers`를 낮추는 튜닝(인덱스 설계, 조인 최적화, N+1 회피 등 이 과정 전체에서 다룬
  기법들)은 캐시 상태와 무관하게 항상 유효하며, 특히 콜드 캐시 상황에서 그 효과가 더욱
  커짐
