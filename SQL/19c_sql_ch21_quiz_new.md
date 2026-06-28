# Oracle Database 19c: SQL Workshop
## Chapter 21 — 고급 그룹 함수 | 연습문제 (50문제)

---

## 하(기초) — 20문제

**[1번]** `ROLLUP(a, b, c)`를 사용하면 생성되는 집계 수준(level)의 수는?

① 2  
② 3  
③ 4  
④ 8

---

**[2번]** 다음 중 ROLLUP 쿼리 결과에서 `전체 합계 행`을 나타내는 설명으로 옳은 것은?

① 첫 번째 행에 나타난다  
② GROUP BY 컬럼이 모두 NULL로 표시된다  
③ SUM 값이 가장 작은 행이다  
④ WHERE 절로 필터링된다

---

**[3번]** `CUBE(a, b)` 결과에서 생성되는 집계 조합의 수는?

① 2  
② 3  
③ 4  
④ 8

---

**[4번]** `ROLLUP(dept, job)`과 `CUBE(dept, job)` 결과의 차이점으로 옳은 것은?

① CUBE에는 전체 합계 행이 없다  
② CUBE에는 직무(job) 단독 소계 행이 추가된다  
③ ROLLUP이 더 많은 행을 생성한다  
④ 두 결과는 동일하다

---

**[5번]** `GROUPING(department_id)` 함수가 `1`을 반환하는 경우는?

① department_id가 NULL인 실제 데이터  
② ROLLUP/CUBE가 소계를 위해 department_id를 NULL로 채운 행  
③ WHERE 절에 department_id IS NULL 조건이 있을 때  
④ GROUP BY에 department_id가 없을 때

---

**[6번]** 다음 중 `GROUPING SETS` 사용의 장점이 아닌 것은?

① 기본 테이블을 한 번만 읽음  
② UNION ALL보다 코드가 간결  
③ 여러 그룹화 결과를 단일 SELECT로 출력  
④ GROUP BY 절을 완전히 대체하여 집계함수 없이 사용 가능

---

**[7번]** 다음 SQL의 결과 행 수 특성으로 옳은 것은?

```sql
GROUP BY ROLLUP(a, b)
```

① CUBE(a, b)보다 항상 행 수가 많다  
② 일반 GROUP BY보다 소계 행이 추가된다  
③ 집계 결과가 없으면 오류가 발생한다  
④ 결과 행 수는 항상 고정이다

---

**[8번]** ROLLUP에서 소계(subtotal)가 생성될 때, 집계되지 않는 컬럼에 표시되는 값은?

① 0  
② 공백(' ')  
③ NULL  
④ 'SUBTOTAL'

---

**[9번]** 다음 중 `GROUPING SETS` 구문의 올바른 형식은?

① `GROUP BY GROUPING SETS (col1, col2)`  
② `GROUP BY GROUPING SETS ((col1), (col2))`  
③ `GROUP BY GROUPING SETS [col1, col2]`  
④ `GROUPING SETS (col1) GROUP BY col2`

---

**[10번]** `ROLLUP(a, (b, c))`에서 생성되는 집계 수준은?

① (a, b, c), (a, b), (a), ()  
② (a, b, c), (a), ()  
③ (a, b, c), (b, c), ()  
④ (a, b, c), (a, b, c) 의 소계

---

**[11번]** 다음 SQL에서 `GRP_JOB = 1`인 행이 의미하는 것은?

```sql
SELECT department_id, job_id, SUM(salary),
       GROUPING(job_id) GRP_JOB
FROM   employees
GROUP BY ROLLUP(department_id, job_id);
```

① job_id가 원래 NULL인 직원  
② ROLLUP이 job_id를 집계하여 NULL을 채운 소계 행  
③ job_id에 값이 있는 일반 행  
④ 오류가 발생하는 조건

---

**[12번]** `CUBE(a, b, c)`에서 생성되는 집계 수준의 수는?

① 4  
② 6  
③ 7  
④ 8

---

**[13번]** 다음 중 ROLLUP과 CUBE의 공통점은?

① 생성 행 수가 동일하다  
② 전체 합계(Grand Total) 행을 생성한다  
③ WHERE 절을 사용할 수 없다  
④ 집계 결과를 역순으로 정렬한다

---

**[14번]** `GROUPING SETS ((dept, job), (dept))` 결과는 다음 중 어느 것과 동일한가?

① `GROUP BY CUBE(dept, job)`  
② `GROUP BY dept, job UNION ALL GROUP BY dept`  
③ `GROUP BY ROLLUP(dept, job)`  
④ `GROUP BY dept`

---

**[15번]** 다음 GROUP BY 절 확장 기능 중 계층적 보고서(예: 연→분기→월)에 가장 적합한 것은?

① CUBE  
② GROUPING SETS  
③ ROLLUP  
④ GROUPING 함수

---

**[16번]** GROUPING 함수의 반환값으로 가능한 것은?

① -1, 0, 1  
② 0, 1  
③ 0, 1, NULL  
④ TRUE, FALSE

---

**[17번]** 다음 중 Concatenated Groupings에 대한 설명으로 옳은 것은?

① CUBE와 ROLLUP을 동시에 사용할 수 없다  
② 여러 그룹화 연산을 쉼표로 연결하여 교차 곱을 생성한다  
③ GROUPING SETS와 동일한 기능이다  
④ 집계 함수 없이 사용할 수 있다

---

**[18번]** `ROLLUP(department_id, job_id)` 결과에서 `department_id = 20`이고 `job_id = NULL`인 행은 어떤 행인가?

① 전체 합계 행  
② department_id = 20에 대한 소계 행  
③ job_id가 없는 직원 행  
④ 오류를 나타내는 행

---

**[19번]** 다음 중 Composite Columns에 대한 설명으로 가장 옳은 것은?

① 두 컬럼을 합쳐 하나의 새 컬럼을 만든다  
② 괄호로 묶인 컬럼들을 하나의 단위로 취급하여 중간 소계를 건너뛴다  
③ 여러 테이블을 JOIN할 때 사용하는 기법이다  
④ NULL 값을 복합 키로 사용하는 방법이다

---

**[20번]** 다음 중 올바른 ROLLUP 구문은?

① `GROUP ROLLUP BY (department_id, job_id)`  
② `GROUP BY ROLLUP(department_id, job_id)`  
③ `ROLLUP GROUP BY (department_id, job_id)`  
④ `GROUP BY USING ROLLUP(department_id, job_id)`

---

## 중(응용) — 20문제

**[21번]** 다음 쿼리의 결과 행 수로 옳은 것은? (부서 수: 5개, 직무 수: 3개, 모든 조합에 데이터 존재 가정)

```sql
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY ROLLUP(department_id, job_id);
```

① 15  
② 18  
③ 21  
④ 30

---

**[22번]** 다음 쿼리에서 `GROUPING(department_id) = 0, GROUPING(job_id) = 1`인 행은?

```sql
SELECT department_id, job_id, SUM(salary),
       GROUPING(department_id) gd, GROUPING(job_id) gj
FROM   employees
GROUP BY ROLLUP(department_id, job_id);
```

① 전체 합계 행  
② 부서별 소계 행  
③ 부서-직무 조합의 일반 행  
④ job_id가 NULL인 직원 행

---

**[23번]** 다음 중 CUBE와 ROLLUP의 행 수 차이를 올바르게 설명한 것은?

```sql
-- GROUP BY ROLLUP(a, b)
-- GROUP BY CUBE(a, b)
```

① CUBE 결과 행 수 = ROLLUP 결과 행 수  
② CUBE 결과 = ROLLUP 결과 + job_id 단독 소계 행  
③ ROLLUP 결과 = CUBE 결과 + department_id 단독 소계 행  
④ CUBE는 항상 정확히 ROLLUP의 2배 행을 생성한다

---

**[24번]** 다음 쿼리에서 소계 행의 `job_id`를 'Sub Total'로 표시하려면 빈칸에 들어갈 함수는?

```sql
SELECT department_id,
       ________(GROUPING(job_id), 1, 'Sub Total', job_id) AS job,
       SUM(salary)
FROM   employees
GROUP BY ROLLUP(department_id, job_id);
```

① NVL  
② DECODE  
③ CASE WHEN  
④ COALESCE

---

**[25번]** 다음 두 쿼리의 차이로 올바른 것은?

```sql
-- 쿼리 A
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY GROUPING SETS ((department_id, job_id), (department_id));

-- 쿼리 B
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY ROLLUP(department_id, job_id);
```

① 두 쿼리의 결과는 완전히 동일하다  
② 쿼리 B에는 전체 합계 행이 있고 쿼리 A에는 없다  
③ 쿼리 A가 더 많은 소계 행을 생성한다  
④ 쿼리 B에 직무별 소계 행이 있고 쿼리 A에는 없다

---

**[26번]** 다음 쿼리의 결과로 옳은 것은?

```sql
SELECT GROUPING(department_id) gd,
       GROUPING(job_id) gj,
       SUM(salary)
FROM   employees
WHERE  department_id < 50
GROUP BY CUBE(department_id, job_id)
HAVING GROUPING(department_id) = 1 AND GROUPING(job_id) = 1;
```

① 모든 소계 행  
② 부서별 소계 행만  
③ 전체 합계 행만  
④ 결과가 없다

---

**[27번]** Composite Columns `ROLLUP(a, (b, c))`가 생성하는 집계 수준으로 옳은 것은?

① `(a, b, c)`, `(a, b)`, `(a)`, `()`  
② `(a, b, c)`, `(a)`, `()`  
③ `(a, b, c)`, `(b, c)`, `(a)`, `()`  
④ `(a, b, c)` 하나만

---

**[28번]** 다음 쿼리에서 실행 계획상 기본 테이블을 몇 번 읽는가?

```sql
SELECT department_id, job_id, manager_id, AVG(salary)
FROM   employees
GROUP BY GROUPING SETS (
    (department_id, job_id),
    (job_id, manager_id)
);
```

① 1번 (단일 패스)  
② 2번  
③ 3번  
④ 그룹화 집합 수만큼

---

**[29번]** 다음 쿼리 결과 해석으로 옳은 것은?

```sql
SELECT department_id, job_id, SUM(salary)
FROM   employees
WHERE  department_id < 60
GROUP BY CUBE(department_id, job_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

① ROLLUP과 동일한 결과  
② 부서-직무 조합, 부서 소계, 직무 소계, 전체 합계 포함  
③ HAVING 절 없으면 소계가 생성되지 않음  
④ job_id가 NULL인 행은 결과에 포함되지 않음

---

**[30번]** GROUPING SETS를 UNION ALL로 동등하게 표현한 것으로 옳은 것은?

```sql
GROUP BY GROUPING SETS ((dept, job), (job))
```

① `GROUP BY dept, job UNION GROUP BY job`  
② `GROUP BY dept, job UNION ALL SELECT ... GROUP BY job`  
③ `GROUP BY ROLLUP(dept, job)`  
④ `GROUP BY CUBE(dept, job)`

---

**[31번]** 다음 중 GROUPING 함수를 사용하는 이유로 가장 옳은 것은?

① 원래 NULL 데이터와 소계로 인한 NULL을 구별하기 위해  
② NULL 값을 제거하기 위해  
③ 소계 행을 삭제하기 위해  
④ 집계 함수의 결과를 검증하기 위해

---

**[32번]** 다음 쿼리 결과에서 manager_id가 NULL인 행이 나타나는 이유 두 가지로 올바른 것은?

```sql
SELECT department_id, manager_id, SUM(salary),
       GROUPING(manager_id) gm
FROM   employees
GROUP BY ROLLUP(department_id, manager_id);
```

① 실제 manager_id가 NULL인 직원(사장 등) OR ROLLUP 소계 행  
② ROLLUP이 NULL로만 채운다  
③ WHERE 절 오류  
④ NULL 데이터가 없다

---

**[33번]** 다음 쿼리에서 ROLLUP 대신 CUBE를 사용했을 때 추가되는 행은?

```sql
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY ROLLUP(department_id, job_id);
```

① 전체 합계 행  
② 부서별 소계 행  
③ 직무(job_id) 단독 소계 행  
④ 추가 행 없음

---

**[34번]** 다음 쿼리의 결과로 `GROUPING(department_id) + GROUPING(job_id) = 2`인 행은?

① 일반 데이터 행  
② 부서 소계 행  
③ 직무 소계 행  
④ 전체 합계 행

---

**[35번]** 다음 쿼리에서 출력되는 총 행 수의 범주는? (emp 테이블에 10개 부서, 5개 직무, 모든 조합 데이터 존재)

```sql
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY CUBE(department_id, job_id);
```

① 50행  
② 50 + 10 + 1 = 61행  
③ 50 + 10 + 5 + 1 = 66행  
④ 50 + 10 + 5 = 65행

---

**[36번]** Concatenated Groupings `GROUP BY a, ROLLUP(b), CUBE(c)` 의 그룹화 조합 수로 옳은 것은?

① 2  
② 4  
③ 6  
④ 8

---

**[37번]** 다음 중 GROUPING SETS가 ROLLUP보다 유리한 상황은?

① 계층적 소계가 필요한 단순 보고서  
② 비계층적이고 특정 그룹화 조합만 필요한 경우  
③ 전체 합계만 필요한 경우  
④ 집계 함수가 없는 쿼리

---

**[38번]** 다음 GROUPING 함수 조합 결과의 의미로 옳은 것은?

| GROUPING(dept) | GROUPING(job) | 의미 |
|---------------|--------------|------|
| 0 | 0 | ? |
| 0 | 1 | ? |
| 1 | 0 | ? |
| 1 | 1 | ? |

① 일반행, 부서소계, 직무소계, 전체합계  
② 전체합계, 직무소계, 부서소계, 일반행  
③ 일반행, 직무소계, 부서소계, 전체합계  
④ 직무소계, 일반행, 전체합계, 부서소계

---

**[39번]** 다음 쿼리에서 HAVING 절 적용 시점으로 옳은 것은?

```sql
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY ROLLUP(department_id, job_id)
HAVING SUM(salary) > 10000;
```

① WHERE 절과 동시에 적용  
② ROLLUP 집계 후 결과에 적용  
③ 소계 행에만 적용  
④ 일반 행에만 적용

---

**[40번]** 다음 중 CUBE를 사용하는 가장 적합한 비즈니스 시나리오는?

① 연간 → 분기 → 월별 매출 소계 보고서  
② 부서, 지역, 제품 카테고리 조합별 다차원 분석  
③ 특정 두 그룹화만 비교하는 단순 보고서  
④ 단일 컬럼의 집계

---

## 상(심화) — 10문제

**[41번]** 다음 두 쿼리의 결과 차이를 정확히 설명한 것은?

```sql
-- 쿼리 A
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY ROLLUP(department_id, job_id);

-- 쿼리 B
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY ROLLUP(job_id, department_id);
```

① 두 쿼리는 완전히 동일한 결과를 반환한다  
② 쿼리 A는 부서 소계, 쿼리 B는 직무 소계를 생성한다  
③ 두 쿼리 모두 동일한 전체 합계를 갖지만 중간 소계의 그룹화 기준이 다르다  
④ 쿼리 B는 오류를 발생시킨다

---

**[42번]** 다음 쿼리에서 `GROUPING(job_id) = 1`인데 `job_id`가 실제로 NULL인 직원(최고 관리자)도 있다. 이 상황을 정확히 처리하는 방법은?

```sql
SELECT department_id, job_id, SUM(salary),
       GROUPING(job_id) gj
FROM   employees
GROUP BY ROLLUP(department_id, job_id);
```

① GROUPING 함수 값만으로는 구별 불가능  
② GROUPING 함수 값이 0이면 실제 NULL, 1이면 소계 NULL로 정확히 구별 가능  
③ NVL로 NULL을 처리하면 구별 가능  
④ COALESCE를 사용하면 구별 가능

---

**[43번]** 다음 쿼리 결과에서 올바른 집계 수준 조합은?

```sql
SELECT department_id, job_id, manager_id, SUM(salary)
FROM   employees
GROUP BY department_id, ROLLUP(job_id), CUBE(manager_id);
```

① (dept, job, mgr), (dept, job), (dept)  
② (dept, job, mgr), (dept, job), (dept, mgr), (dept)  
③ (dept, job, mgr), (dept, job), (dept, mgr), (dept) — 4가지  
④ (dept, job, mgr), (dept, mgr), (dept, job), (dept) 중 일부

---

**[44번]** 다음 시나리오에서 ROLLUP이 UNION ALL보다 성능이 우수한 이유는?

```sql
-- ROLLUP 사용
SELECT department_id, job_id, SUM(salary)
FROM   employees
GROUP BY ROLLUP(department_id, job_id);

-- 동등한 UNION ALL
SELECT department_id, job_id, SUM(salary)
FROM   employees GROUP BY department_id, job_id
UNION ALL
SELECT department_id, NULL, SUM(salary)
FROM   employees GROUP BY department_id
UNION ALL
SELECT NULL, NULL, SUM(salary)
FROM   employees;
```

① 두 방법의 성능은 동일하다  
② ROLLUP은 기본 테이블을 한 번만 스캔하고 소계를 누적하여 계산한다  
③ ROLLUP은 인덱스를 사용하지 않아 더 빠르다  
④ UNION ALL이 더 빠르다

---

**[45번]** 다음 중 GROUPING SETS의 결과를 ROLLUP으로 표현할 수 없는 경우는?

① `GROUPING SETS ((a, b), (a), ())`  
② `GROUPING SETS ((a, b), (b))`  
③ `GROUPING SETS ((a, b, c), (a, b), (a), ())`  
④ `GROUPING SETS ((a), ())`

---

**[46번]** 다음 쿼리에서 오류가 발생하는 이유는?

```sql
SELECT department_id, GROUPING(salary), SUM(salary)
FROM   employees
GROUP BY ROLLUP(department_id, salary);
```

① GROUPING 함수는 GROUP BY 절에 있는 컬럼만 인수로 받을 수 없다  
② GROUPING 함수는 GROUP BY 절에 있는 컬럼만 인수로 사용해야 한다  
③ salary는 집계 컬럼이므로 GROUPING 인수로 사용 불가하다 (이 경우는 오류 아님)  
④ ROLLUP과 GROUPING을 함께 사용할 수 없다

---

**[47번]** 다음 쿼리 A와 쿼리 B의 결과 비교로 옳은 것은?

```sql
-- 쿼리 A
GROUP BY ROLLUP(department_id, (job_id, manager_id));

-- 쿼리 B
GROUP BY ROLLUP(department_id, job_id, manager_id);
```

① A와 B의 결과는 동일하다  
② A에는 (dept, job, mgr), (dept), () 수준만 있고 B에는 (dept, job, mgr), (dept, job), (dept), ()도 있다  
③ B에만 전체 합계 행이 있다  
④ A는 오류를 발생시킨다

---

**[48번]** 다음 조건을 만족하는 쿼리를 작성할 때 가장 적합한 GROUP BY 확장은?

```
조건:
- 부서별 급여 합계
- 직무별 급여 합계
- 전체 합계는 제외
```

① `GROUP BY ROLLUP(department_id, job_id)`  
② `GROUP BY CUBE(department_id, job_id)`  
③ `GROUP BY GROUPING SETS ((department_id), (job_id))`  
④ `GROUP BY department_id, job_id`

---

**[49번]** 다음 쿼리에서 동일한 `department_id` 값을 갖는 행이 두 개 이상 있는 이유는?

```sql
SELECT department_id, job_id, manager_id, AVG(salary)
FROM   employees
GROUP BY GROUPING SETS (
    (department_id, job_id),
    (department_id, manager_id)
);
```

① 오류이므로 실행되지 않는다  
② GROUPING SETS가 두 그룹화 결과를 UNION ALL 방식으로 결합하기 때문에 동일 department_id가 두 그룹화에 각각 나타난다  
③ 집계 함수 충돌  
④ JOIN이 누락되었기 때문

---

**[50번]** 다음 쿼리를 가장 효율적으로 재작성할 때 GROUPING SETS를 사용하면 어떻게 되는가?

```sql
SELECT department_id, NULL AS job_id, NULL AS manager_id, SUM(salary)
FROM   employees GROUP BY department_id
UNION ALL
SELECT NULL, job_id, NULL, SUM(salary)
FROM   employees GROUP BY job_id
UNION ALL
SELECT NULL, NULL, manager_id, SUM(salary)
FROM   employees GROUP BY manager_id;
```

① `GROUP BY ROLLUP(department_id, job_id, manager_id)`  
② `GROUP BY GROUPING SETS ((department_id), (job_id), (manager_id))`  
③ `GROUP BY CUBE(department_id, job_id, manager_id)`  
④ `GROUP BY department_id, job_id, manager_id`
