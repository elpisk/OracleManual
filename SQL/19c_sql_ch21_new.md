# Oracle Database 19c: SQL Workshop
## Chapter 21 — 고급 그룹 함수 (Generating Reports by Grouping Related Data)

---

## 학습 목표

이 단원을 마치면 다음을 수행할 수 있습니다.

- ROLLUP 연산으로 소계(subtotal) 값을 생성한다
- CUBE 연산으로 교차 집계(cross-tabulation) 값을 생성한다
- GROUPING 함수로 ROLLUP/CUBE가 생성한 NULL 행을 식별한다
- GROUPING SETS로 단일 SELECT에서 여러 그룹화를 정의한다
- 복합 컬럼(Composite Columns)과 연결 그룹화(Concatenated Groupings)를 활용한다

---

## 1. GROUP BY 복습

```sql
-- 기본 집계
SELECT AVG(salary), STDDEV(salary), COUNT(commission_pct), MAX(hire_date)
FROM   employees
WHERE  job_id LIKE 'SA%';

-- GROUP BY + HAVING
SELECT   department_id, job_id, SUM(salary), COUNT(employee_id)
FROM     employees
GROUP BY department_id, job_id;
```

---

## 2. ROLLUP 연산자

`ROLLUP`은 `GROUP BY`의 확장으로, 일반 그룹 행 외에 **소계(subtotal) 행**을 자동으로 생성한다.

### 2-1. 구문

```sql
SELECT   [column,] group_function(column) ...
FROM     table
[WHERE   condition]
[GROUP BY ROLLUP (col1, col2, ...)]
[HAVING  having_expression]
[ORDER BY column];
```

### 2-2. 동작 방식

`ROLLUP(a, b, c)`는 다음 수준의 집계를 생성한다:
1. `(a, b, c)` — 가장 세분화된 그룹 (일반 GROUP BY와 동일)
2. `(a, b)` — b 기준 소계
3. `(a)` — a 기준 소계
4. `()` — 전체 합계 (Grand Total)

소계 행에서 집계되지 않는 컬럼은 **NULL**로 표시된다.

### 2-3. 예제

```sql
-- department_id < 60인 직원의 부서 + 직무별 급여 합계 및 소계
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY ROLLUP(department_id, job_id);
```

**결과 예시:**
```
DEPARTMENT_ID  JOB_ID      SUM(SALARY)
10             AD_ASST     4400        ← 일반 그룹
10             NULL        4400        ← 부서 소계
20             MK_MAN      13000
20             MK_REP      6000
20             NULL        19000       ← 부서 소계
...
NULL           NULL        XXXXX       ← 전체 합계
```

---

## 3. CUBE 연산자

`CUBE`는 `GROUP BY`의 확장으로, ROLLUP의 모든 행 + **모든 열 조합의 교차 집계** 행을 생성한다.

### 3-1. 구문

```sql
SELECT   [column,] group_function(column) ...
FROM     table
[WHERE   condition]
[GROUP BY CUBE (col1, col2, ...)]
[HAVING  having_expression]
[ORDER BY column];
```

### 3-2. 동작 방식

`CUBE(a, b)`는 다음 네 가지 수준의 집계를 생성한다:
1. `(a, b)` — 기본 그룹
2. `(a)` — a 기준 소계
3. `(b)` — b 기준 소계 ← ROLLUP에는 없는 행
4. `()` — 전체 합계

**n개의 컬럼**: ROLLUP → n+1가지 집계 / CUBE → 2^n가지 집계

### 3-3. 예제

```sql
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY CUBE(department_id, job_id);
```

**ROLLUP vs CUBE 차이:**
```
ROLLUP(dept, job):              CUBE(dept, job):
(dept, job) 소계 있음           (dept, job) 소계 있음
(dept) 소계 있음                (dept) 소계 있음
() 전체 합계 있음               () 전체 합계 있음
                                (job) 소계 있음  ← CUBE에만 존재
```

---

## 4. ROLLUP vs CUBE 비교

| 항목 | ROLLUP | CUBE |
|------|--------|------|
| 생성 행 수 | n+1 수준 | 2^n 수준 |
| 소계 방향 | 계층적 (왼쪽 → 오른쪽) | 모든 조합 |
| 특수 행 | 소계 + 전체 합계 | 소계 + 전체 합계 + 교차 집계 |
| 용도 | 계층적 보고서 (월 → 분기 → 연) | 다차원 분석 (피벗 테이블) |

---

## 5. GROUPING 함수

ROLLUP/CUBE 결과에서 **소계 행과 일반 행을 구별**한다.

### 5-1. 동작 원리

- 인수로 전달한 열이 **소계로 인해 NULL인 경우** → `1` 반환
- 열에 **실제 값이 있거나 원래 NULL인 경우** → `0` 반환

```sql
SELECT   [column,] group_function(column) ..,
         GROUPING(expr)
FROM     table
[WHERE   condition]
[GROUP BY [ROLLUP][CUBE] group_by_expression]
[HAVING  having_expression];
```

### 5-2. 예제

```sql
SELECT   department_id DEPTID, job_id JOB,
         SUM(salary),
         GROUPING(department_id) GRP_DEPT,
         GROUPING(job_id)        GRP_JOB
FROM     employees
WHERE    department_id < 50
GROUP BY ROLLUP(department_id, job_id);
```

**결과 해석:**
```
DEPTID  JOB      SUM(SALARY)  GRP_DEPT  GRP_JOB
10      AD_ASST  4400         0         0   ← 일반 행
10      NULL     4400         0         1   ← 부서 소계 (job_id = 집계 NULL)
20      MK_MAN   13000        0         0
20      MK_REP   6000         0         0
20      NULL     19000        0         1   ← 부서 소계
NULL    NULL     XXXXX        1         1   ← 전체 합계
```

`GRP_DEPT = 1, GRP_JOB = 1` → 전체 합계 행  
`GRP_DEPT = 0, GRP_JOB = 1` → 부서별 소계 행

### 5-3. GROUPING으로 레이블 표시

```sql
SELECT   DECODE(GROUPING(department_id), 1, '전체 합계',
                TO_CHAR(department_id))          AS dept,
         DECODE(GROUPING(job_id), 1, '소계',
                job_id)                          AS job,
         SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY ROLLUP(department_id, job_id);
```

---

## 6. GROUPING SETS

단일 SELECT 문에서 **여러 가지 그룹화를 동시에 정의**한다.  
내부적으로 각 그룹화 결과를 UNION ALL로 결합한다.

### 6-1. 구문

```sql
SELECT   column, group_function(column)
FROM     table
GROUP BY GROUPING SETS ((col_list1), (col_list2), ...);
```

### 6-2. 예제

```sql
-- (department_id, job_id) 그룹 + (job_id, manager_id) 그룹 동시 출력
SELECT   department_id, job_id, manager_id, AVG(salary)
FROM     employees
GROUP BY GROUPING SETS (
    (department_id, job_id),
    (job_id, manager_id)
);
```

### 6-3. GROUPING SETS 장점

| 항목 | 설명 |
|------|------|
| 단일 패스 | 기본 테이블을 한 번만 읽음 |
| 복잡한 UNION 불필요 | 동등한 UNION ALL보다 코드가 간결 |
| 성능 | 그룹화 집합이 많을수록 성능 이점 증가 |

---

## 7. 복합 컬럼 (Composite Columns)

여러 컬럼을 **하나의 단위로 묶어** ROLLUP/CUBE 계산 시 일부 집계 수준을 건너뛴다.

```sql
-- (job_id, manager_id)를 하나의 단위로 처리
SELECT   department_id, job_id, manager_id, SUM(salary)
FROM     employees
GROUP BY ROLLUP(department_id, (job_id, manager_id));
```

- `ROLLUP(a, (b, c))` → `(a, b, c)`, `(a)`, `()` 수준 생성
- `(b, c)` 중간 수준 소계는 **생략**됨

---

## 8. 연결 그룹화 (Concatenated Groupings)

여러 `GROUPING SETS`, `ROLLUP`, `CUBE`를 **쉼표로 연결**하여 조합의 교차 곱(cross-product) 생성.

```sql
-- GROUP BY GROUPING SETS(a, b), GROUPING SETS(c, d)
-- → (a,c), (a,d), (b,c), (b,d) 네 가지 그룹화 생성
SELECT   department_id, job_id, manager_id, SUM(salary)
FROM     employees
GROUP BY department_id,
         ROLLUP(job_id),
         CUBE(manager_id);
```

---

## 9. 단원 요약

| 연산자/함수 | 핵심 내용 |
|------------|-----------|
| `ROLLUP(a, b)` | 계층적 소계: (a,b) → (a) → () 순으로 n+1 수준 집계 |
| `CUBE(a, b)` | 모든 조합 집계: (a,b) + (a) + (b) + () 총 2^n 수준 |
| `GROUPING(col)` | 소계 NULL=1, 실제 값=0으로 소계 행 식별 |
| `GROUPING SETS` | 지정한 그룹화 집합 결과를 UNION ALL로 결합 |
| 복합 컬럼 | `(b, c)` 괄호로 묶어 소계 수준 건너뜀 |
| 연결 그룹화 | 여러 GROUPING SETS/ROLLUP/CUBE를 쉼표로 연결 |
