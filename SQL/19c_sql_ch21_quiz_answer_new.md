# Oracle Database 19c: SQL Workshop
## Chapter 21 — 고급 그룹 함수 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ③ | `ROLLUP(a, b, c)` → (a,b,c), (a,b), (a), () 4가지 수준 |
| 2 | ② | 전체 합계 행: 모든 GROUP BY 컬럼이 NULL로 표시됨 |
| 3 | ③ | `CUBE(a, b)` → 2^2 = 4가지 조합 |
| 4 | ② | CUBE에만 직무(job) 단독 소계 행이 추가됨 |
| 5 | ② | ROLLUP/CUBE가 소계를 위해 NULL을 채운 경우 GROUPING() = 1 |
| 6 | ④ | GROUPING SETS도 GROUP BY의 확장이므로 집계 함수 필요 |
| 7 | ② | ROLLUP은 일반 GROUP BY보다 소계 행이 추가됨 |
| 8 | ③ | 소계 행에서 집계되지 않는 컬럼은 NULL로 표시됨 |
| 9 | ② | `GROUP BY GROUPING SETS ((col1), (col2))` — 각 집합을 괄호로 묶음 |
| 10 | ② | `ROLLUP(a, (b, c))` → (a, b, c), (a), () — 중간 (b,c) 수준 건너뜀 |
| 11 | ② | GRP_JOB = 1 → ROLLUP이 소계를 위해 job_id를 NULL로 채운 행 |
| 12 | ④ | `CUBE(a, b, c)` → 2^3 = 8가지 집계 수준 |
| 13 | ② | ROLLUP과 CUBE 모두 전체 합계(Grand Total) 행을 생성한다 |
| 14 | ② | `GROUPING SETS ((dept, job), (dept))` ≡ `GROUP BY dept, job UNION ALL GROUP BY dept` |
| 15 | ③ | ROLLUP이 계층적(왼쪽→오른쪽) 소계에 가장 적합 |
| 16 | ② | GROUPING 함수 반환값: 0(일반 값) 또는 1(소계 NULL) |
| 17 | ② | Concatenated Groupings: 쉼표로 연결하여 교차 곱 생성 |
| 18 | ② | dept=20, job=NULL → department_id=20 그룹의 소계 행 |
| 19 | ② | 복합 컬럼: 괄호로 묶인 컬럼들을 하나의 단위로 취급 |
| 20 | ② | `GROUP BY ROLLUP(col1, col2)` — 올바른 구문 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ③**

`ROLLUP(department_id, job_id)` 집계 수준:
- 부서+직무 조합: 5 × 3 = 15행
- 부서 소계: 5행
- 전체 합계: 1행
- 합계: **15 + 5 + 1 = 21행**

---

**[22번] 정답: ②**

| GROUPING(dept) | GROUPING(job) | 의미 |
|---------------|--------------|------|
| 0 | 0 | 일반 행 (부서+직무 조합) |
| 0 | 1 | 부서별 소계 행 → department_id는 있고 job_id는 집계 NULL |
| 1 | 1 | 전체 합계 행 |

`gd=0, gj=1` → **부서별 소계 행**

---

**[23번] 정답: ②**

`ROLLUP(a, b)` → (a,b), (a), () = 3가지 수준  
`CUBE(a, b)` → (a,b), (a), (b), () = 4가지 수준

CUBE에는 (b) 수준(job_id 단독 소계)이 추가된다.

---

**[24번] 정답: ②**

`DECODE(GROUPING(job_id), 1, 'Sub Total', job_id)`

- `GROUPING(job_id) = 1`일 때 → `'Sub Total'` 표시
- 그 외 → `job_id` 값 그대로

---

**[25번] 정답: ②**

| 쿼리 | 생성되는 수준 |
|------|-------------|
| 쿼리 A (GROUPING SETS) | (dept, job), (dept) |
| 쿼리 B (ROLLUP) | (dept, job), (dept), **()** |

쿼리 B에만 전체 합계 행 `()`이 존재한다.

---

**[26번] 정답: ③**

`GROUPING(dept) = 1 AND GROUPING(job) = 1` → 두 컬럼이 모두 소계 NULL인 행  
→ **전체 합계 행**만 해당된다.

---

**[27번] 정답: ②**

`ROLLUP(a, (b, c))`에서 `(b, c)`는 복합 컬럼(하나의 단위):
- 생성 수준: `(a, b, c)`, `(a)`, `()`
- `(b, c)` 단독 소계(중간 수준)는 건너뜀

---

**[28번] 정답: ①**

`GROUPING SETS`의 핵심 장점: 기본 테이블을 **1번만 읽어** 내부적으로 여러 그룹화 결과를 집계한다.  
UNION ALL로 작성하면 2번 읽어야 하는 쿼리가 GROUPING SETS에서는 단일 패스로 처리된다.

---

**[29번] 정답: ②**

`CUBE(department_id, job_id)` → 4가지 집계 수준:
- `(dept, job)` — 부서-직무 조합
- `(dept)` — 부서 소계
- `(job)` — 직무 소계 (ROLLUP에는 없는 행)
- `()` — 전체 합계

---

**[30번] 정답: ②**

```sql
-- 동등한 UNION ALL 표현
SELECT dept, job, SUM(salary) FROM employees GROUP BY dept, job
UNION ALL
SELECT dept, NULL, SUM(salary) FROM employees GROUP BY dept  -- job 소계
```

`GROUPING SETS ((dept, job), (job))` ≠ ROLLUP(dept, job)  
GROUPING SETS에서는 (job) 단독 소계 생성.

---

**[31번] 정답: ①**

ROLLUP/CUBE 결과에는 두 종류의 NULL이 존재한다:
1. **원래 데이터의 NULL**: 실제 manager가 없는 사장 (employee_id = 100 등)
2. **소계를 위한 NULL**: ROLLUP이 집계하여 채운 NULL

GROUPING 함수가 이 두 가지를 정확히 구별해준다.

---

**[32번] 정답: ①**

```
GRP_MGR = 0 & manager_id = NULL → 실제 데이터에서 manager_id가 NULL인 직원 (최고관리자 등)
GRP_MGR = 1 & manager_id = NULL → ROLLUP 소계 행
```

두 경우 모두 `manager_id`가 NULL로 보이지만, GROUPING 함수로 구별한다.

---

**[33번] 정답: ③**

CUBE는 ROLLUP의 모든 결과 + 역방향 소계를 추가한다.  
`CUBE(dept, job)` = `ROLLUP(dept, job)` 결과 + **job_id 단독 소계 행**

---

**[34번] 정답: ④**

| GROUPING(dept) | GROUPING(job) | 합계 | 행 종류 |
|---------------|--------------|------|---------|
| 0 | 0 | 0 | 일반 행 |
| 0 | 1 | 1 | 부서 소계 |
| 1 | 0 | 1 | 직무 소계 |
| 1 | 1 | 2 | **전체 합계** |

`GROUPING(dept) + GROUPING(job) = 2` → **전체 합계 행**

---

**[35번] 정답: ③**

`CUBE(department_id, job_id)` 집계 수준별 행 수 (부서 10개, 직무 5개):
- (dept, job) 조합: 10 × 5 = 50행
- (dept) 소계: 10행
- (job) 소계: 5행
- () 전체 합계: 1행
- 합계: **50 + 10 + 5 + 1 = 66행**

---

**[36번] 정답: ②**

`GROUP BY a, ROLLUP(b), CUBE(c)`는 Concatenated Groupings:
- `a`는 고정 (1가지)
- `ROLLUP(b)`: (b), () = 2가지
- `CUBE(c)`: (c), () = 2가지
- 교차 곱: 1 × 2 × 2 = **4가지** 집계 수준

---

**[37번] 정답: ②**

GROUPING SETS는 원하는 특정 그룹화 조합만 선택하여 사용할 때 최적이다.  
ROLLUP은 계층적 소계, CUBE는 모든 조합 집계에 적합하며, 불필요한 소계 행도 생성된다.  
특정 비계층적 그룹화 조합만 필요할 때 GROUPING SETS가 가장 효율적이다.

---

**[38번] 정답: ①**

| GROUPING(dept) | GROUPING(job) | 의미 |
|---------------|--------------|------|
| 0 | 0 | 일반 행 (부서+직무 조합) |
| 0 | 1 | 부서 소계 행 |
| 1 | 0 | 직무 소계 행 (CUBE 전용) |
| 1 | 1 | 전체 합계 행 |

---

**[39번] 정답: ②**

`HAVING` 절은 GROUP BY(ROLLUP 포함) 집계가 완료된 후 결과에 적용된다.  
소계 행, 일반 행 모두에 적용되며 조건을 만족하지 않는 행은 제외된다.

---

**[40번] 정답: ②**

CUBE는 모든 조합의 교차 집계를 생성하므로 **다차원 분석**에 최적이다.  
예: 부서 × 지역 × 제품 카테고리 → 각 조합의 집계 및 소계가 자동 생성된다.  
계층적 보고서에는 ROLLUP, 특정 조합만 필요할 때는 GROUPING SETS가 적합하다.

---

## 상(심화) 모범답안

---

**[41번] 정답: ③**

`ROLLUP(a, b)`와 `ROLLUP(b, a)`는 소계 기준이 다르다:
- `ROLLUP(dept, job)`: (dept, job), **(dept)** 소계, ()
- `ROLLUP(job, dept)`: (job, dept), **(job)** 소계, ()

두 쿼리 모두 전체 합계(같은 값)는 동일하지만, 중간 소계의 그룹화 기준이 달라진다.

---

**[42번] 정답: ②**

`GROUPING(job_id)` 함수의 반환값:
- `= 0`: job_id가 실제로 NULL인 직원 OR job_id에 값이 있는 직원 (원래 데이터)
- `= 1`: ROLLUP이 소계를 위해 채운 NULL (집계 NULL)

이 두 경우를 정확히 구별할 수 있으며, GROUPING 함수가 바로 이 목적으로 존재한다.

---

**[43번] 정답: ②**

`GROUP BY dept, ROLLUP(job), CUBE(mgr)`:
- `dept`: 고정 (1가지)
- `ROLLUP(job)`: (job), () = 2가지
- `CUBE(mgr)`: (mgr), () = 2가지
- 교차 곱: 2 × 2 = 4가지:
  1. (dept, job, mgr)
  2. (dept, job)
  3. (dept, mgr)
  4. (dept)

---

**[44번] 정답: ②**

ROLLUP의 성능 우위:
- ROLLUP: 기본 테이블을 **1회 스캔**하면서 소계를 누적 집계
- UNION ALL: 집계 수준별로 기본 테이블을 **여러 번 스캔** (3번)

데이터 규모가 클수록 ROLLUP의 성능 이점이 극대화된다.

---

**[45번] 정답: ②**

`GROUPING SETS ((a, b), (b))` = (a,b) 수준 + (b) 단독 수준  
이는 ROLLUP으로 표현 불가하다:
- `ROLLUP(a, b)` → (a,b), (a), ()  ← (b) 단독 소계 없음
- `ROLLUP(b, a)` → (b,a), (b), ()  ← (a,b)와 (b) 있지만 (a,b) ≡ (b,a)

따라서 `GROUPING SETS((a,b), (b))`를 ROLLUP으로 정확히 표현할 수 없다.

---

**[46번] 정답: ③**

실제로 오류가 아니다. `GROUP BY ROLLUP(department_id, salary)`는 유효한 구문이며, `GROUPING(salary)` 함수도 GROUP BY 절에 salary가 있으므로 사용 가능하다.

단, salary를 GROUP BY에 포함시키는 것은 의미상 부적절할 수 있다 (각 salary 값이 개별 그룹이 됨). 이 문제의 핵심은 GROUPING 함수는 GROUP BY에 포함된 컬럼에만 사용 가능하다는 규칙이며, 위 쿼리는 규칙을 만족하므로 오류가 발생하지 않는다.

---

**[47번] 정답: ②**

```
ROLLUP(dept, (job, mgr)):
  집계 수준: (dept, job, mgr), (dept), ()   ← 중간 수준 (dept, job)/(dept, mgr) 없음

ROLLUP(dept, job, mgr):
  집계 수준: (dept, job, mgr), (dept, job), (dept), ()   ← 4가지 수준
```

복합 컬럼 `(job, mgr)`을 묶으면 중간 소계 수준이 건너뛰어진다.

---

**[48번] 정답: ③**

조건 분석:
- 부서별 집계: `(department_id)` 그룹
- 직무별 집계: `(job_id)` 그룹  
- 전체 합계: **제외**
- 두 그룹 간 조합: 필요 없음

→ `GROUP BY GROUPING SETS ((department_id), (job_id))`

ROLLUP/CUBE는 전체 합계를 포함하므로 부적합.

---

**[49번] 정답: ②**

`GROUPING SETS` 결과는 내부적으로 UNION ALL로 결합된다:
```sql
-- (dept, job) 그룹에서 dept=10이 있고
-- (dept, mgr) 그룹에서도 dept=10이 있음
-- → 최종 결과에 dept=10 행이 두 번 나타남 (각각 다른 그룹화 수준에서)
```
이는 정상 동작이다.

---

**[50번] 정답: ②**

원래 UNION ALL 쿼리를 분석:
- `GROUP BY department_id` → (department_id) 그룹
- `GROUP BY job_id` → (job_id) 그룹  
- `GROUP BY manager_id` → (manager_id) 그룹

세 가지 독립적인 그룹화 집합 → `GROUPING SETS ((dept), (job), (mgr))`:

```sql
SELECT department_id, job_id, manager_id, SUM(salary)
FROM   employees
GROUP BY GROUPING SETS (
    (department_id),
    (job_id),
    (manager_id)
);
```

CUBE는 모든 조합(부서×직무×관리자 교차)을 생성하므로 과도하게 많은 행이 나온다.
