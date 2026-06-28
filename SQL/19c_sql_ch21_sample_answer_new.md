# Oracle Database 19c: SQL Workshop
## Chapter 21 — 고급 그룹 함수 | SQL 실습 모범답안

---

## Group 1: ROLLUP 기본

**[1번]** 부서별, 직무별 급여 합계 (ROLLUP)

```sql
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY ROLLUP(department_id, job_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

**결과 구조:**
```
DEPARTMENT_ID  JOB_ID    SUM(SALARY)
----------     -------   -----------
10             AD_ASST        4400   ← 상세 행
10             NULL           4400   ← 부서 소계 (job NULL)
20             MK_MAN        13000
20             MK_REP         6000
20             NULL          19000   ← 부서 소계
...
NULL           NULL         XXXXX   ← 전체 합계 (모두 NULL)
```

**핵심 개념:** `ROLLUP(a, b)` → n+1 = 3가지 집계 수준

---

**[2번]** 부서별 직원 수 소계

```sql
SELECT   department_id,
         COUNT(*) AS employee_count
FROM     employees
GROUP BY ROLLUP(department_id)
ORDER BY department_id NULLS LAST;
```

**결과:** 부서별 직원 수 + 마지막에 전체 직원 수(107명)

---

**[3번]** 3컬럼 ROLLUP (다단계 소계)

```sql
SELECT   department_id, job_id, manager_id,
         SUM(salary)    AS total_salary,
         COUNT(*)       AS headcount
FROM     employees
WHERE    department_id IN (20, 50, 80)
GROUP BY ROLLUP(department_id, job_id, manager_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST, manager_id NULLS LAST;
```

**결과 수준:** 4가지
1. `(dept, job, mgr)` — 상세
2. `(dept, job)` — 관리자 소계
3. `(dept)` — 부서 소계
4. `()` — 전체 합계

---

**[4번]** 입사 연도 + 부서별 집계

```sql
SELECT   EXTRACT(YEAR FROM hire_date) AS hire_year,
         department_id,
         SUM(salary)                  AS total_salary
FROM     employees
GROUP BY ROLLUP(EXTRACT(YEAR FROM hire_date), department_id)
ORDER BY hire_year NULLS LAST, department_id NULLS LAST;
```

**포인트:** `ROLLUP` 안에 일반 표현식(EXTRACT 함수)도 사용 가능.

---

**[5번]** GROUPING 함수로 소계 행 레이블 처리

```sql
SELECT   DECODE(GROUPING(department_id), 1, '[전체]',
                TO_CHAR(department_id)) AS dept,
         DECODE(GROUPING(job_id), 1, '[소계]',
                job_id)                 AS job,
         SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY ROLLUP(department_id, job_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

**결과 예시:**
```
DEPT    JOB       SUM(SALARY)
10      AD_ASST        4400
10      [소계]         4400
20      MK_MAN        13000
20      MK_REP         6000
20      [소계]        19000
[전체]  [소계]        XXXXX   ← 전체 합계 행
```

---

## Group 2: CUBE 기본

**[6번]** 부서별, 직무별 급여 합계 (CUBE)

```sql
SELECT   department_id, job_id, SUM(salary) AS total_salary
FROM     employees
WHERE    department_id < 60
GROUP BY CUBE(department_id, job_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

**ROLLUP과의 차이:** CUBE 결과에는 직무(job_id) 단독 소계 행이 추가됨
```
-- CUBE에만 있는 행 예시:
NULL  AD_ASST   4400   ← job 단독 소계 (dept=NULL)
NULL  MK_MAN   13000
```

---

**[7번]** 직무 단독 소계 행만 추출

```sql
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY CUBE(department_id, job_id)
HAVING   GROUPING(department_id) = 1
         AND GROUPING(job_id) = 0
ORDER BY job_id;
```

**조건 해석:**
- `GROUPING(dept) = 1`: department_id는 집계된 NULL
- `GROUPING(job_id) = 0`: job_id는 실제 값이 있는 행

---

**[8번]** CUBE + GROUPING 비트 마스크

```sql
SELECT   department_id, job_id, manager_id,
         SUM(salary),
         GROUPING(department_id) AS gd,
         GROUPING(job_id)        AS gj,
         GROUPING(manager_id)    AS gm
FROM     employees
WHERE    department_id IN (20, 50)
GROUP BY CUBE(department_id, job_id, manager_id)
ORDER BY gd, gj, gm;
```

**GROUPING 조합 해석:**
```
gd gj gm   집계 수준
0  0  0    상세 행
0  0  1    (dept, job) 소계
0  1  0    (dept, mgr) 소계
0  1  1    (dept) 소계
1  0  0    (job, mgr) 소계
1  0  1    (job) 소계
1  1  0    (mgr) 소계
1  1  1    전체 합계
```

---

**[9번]** ROLLUP과 CUBE 비교

```sql
-- ROLLUP 결과
SELECT 'ROLLUP' AS src, department_id, job_id, SUM(salary)
FROM   employees
WHERE  department_id < 60
GROUP BY ROLLUP(department_id, job_id)
UNION ALL
-- CUBE에만 있는 행 (직무 단독 소계)
SELECT 'CUBE_ONLY', department_id, job_id, SUM(salary)
FROM   employees
WHERE  department_id < 60
GROUP BY CUBE(department_id, job_id)
HAVING GROUPING(department_id) = 1 AND GROUPING(job_id) = 0
ORDER BY src, department_id NULLS LAST, job_id NULLS LAST;
```

---

## Group 3: GROUPING 함수 활용

**[10번]** 소계 유형 레이블 표시 (CASE WHEN)

```sql
SELECT   CASE
             WHEN GROUPING(department_id) = 1 AND GROUPING(job_id) = 1 THEN '전체합계'
             WHEN GROUPING(department_id) = 0 AND GROUPING(job_id) = 1 THEN '부서소계'
             ELSE '상세'
         END               AS row_type,
         department_id,
         job_id,
         SUM(salary)       AS total_salary,
         COUNT(*)          AS headcount
FROM     employees
WHERE    department_id < 60
GROUP BY ROLLUP(department_id, job_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

---

**[11번]** 전체 합계 행 제외

```sql
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY ROLLUP(department_id, job_id)
HAVING   NOT (GROUPING(department_id) = 1 AND GROUPING(job_id) = 1)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

**핵심:** `HAVING`으로 특정 소계 수준을 제거할 수 있다.

---

**[12번]** 상세 행(일반 행)만 추출

```sql
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY CUBE(department_id, job_id)
HAVING   GROUPING(department_id) = 0 AND GROUPING(job_id) = 0
ORDER BY department_id, job_id;
```

**결과:** 일반 `GROUP BY ROLLUP(dept, job)` 없이 CUBE를 쓰면 이렇게 소계 행을 직접 필터링 가능.

---

**[13번]** 비트 마스크로 집계 수준 표시

```sql
SELECT   department_id,
         job_id,
         manager_id,
         SUM(salary),
         GROUPING(department_id) * 4
         + GROUPING(job_id) * 2
         + GROUPING(manager_id) * 1 AS grouping_level
FROM     employees
WHERE    department_id IN (20, 50)
GROUP BY CUBE(department_id, job_id, manager_id)
ORDER BY grouping_level, department_id NULLS LAST;
```

**grouping_level 해석:**
- 0 = 상세 행 (모두 실제 값)
- 1 = (dept, job) 소계
- 2 = (dept, mgr) 소계
- 3 = (dept) 소계
- 4 = (job, mgr) 소계
- 5 = (job) 소계
- 6 = (mgr) 소계
- 7 = 전체 합계

---

## Group 4: GROUPING SETS

**[14번]** 두 가지 그룹화 조합 (GROUPING SETS)

```sql
SELECT   department_id, job_id, manager_id,
         AVG(salary)  AS avg_salary,
         COUNT(*)     AS headcount
FROM     employees
GROUP BY GROUPING SETS (
    (department_id, job_id),
    (job_id, manager_id)
)
ORDER BY GROUPING(department_id), GROUPING(manager_id),
         department_id NULLS LAST;
```

**포인트:**
- `(dept, job)` 그룹에서는 manager_id = NULL
- `(job, mgr)` 그룹에서는 department_id = NULL
- 두 결과가 UNION ALL 방식으로 결합됨

---

**[15번]** 세 가지 그룹화를 단일 쿼리로

```sql
SELECT   department_id, job_id,
         SUM(salary), COUNT(*) AS headcount
FROM     employees
GROUP BY GROUPING SETS (
    (department_id),
    (job_id),
    ()
)
ORDER BY GROUPING(department_id) DESC, GROUPING(job_id) DESC,
         department_id NULLS LAST, job_id NULLS LAST;
```

---

**[16번]** GROUPING SETS vs UNION ALL 비교

두 쿼리는 동일한 결과를 반환하지만 GROUPING SETS 방식이 테이블을 1번만 읽어 성능이 우수하다.

```sql
-- GROUPING SETS (권장)
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id IN (10, 20, 30)
GROUP BY GROUPING SETS ((department_id, job_id), (department_id));

-- 동등 UNION ALL
SELECT   department_id, job_id, SUM(salary)
FROM     employees WHERE department_id IN (10, 20, 30)
GROUP BY department_id, job_id
UNION ALL
SELECT   department_id, NULL, SUM(salary)
FROM     employees WHERE department_id IN (10, 20, 30)
GROUP BY department_id;
```

---

## Group 5: 복합 컬럼 & 연결 그룹화

**[17번]** 일반 ROLLUP vs 복합 컬럼 ROLLUP 비교

```sql
SELECT 'NORMAL' AS rollup_type, department_id, job_id, manager_id, SUM(salary)
FROM   employees
WHERE  department_id IN (20, 50)
GROUP BY ROLLUP(department_id, job_id, manager_id)
UNION ALL
SELECT 'COMPOSITE', department_id, job_id, manager_id, SUM(salary)
FROM   employees
WHERE  department_id IN (20, 50)
GROUP BY ROLLUP(department_id, (job_id, manager_id))
ORDER BY rollup_type, department_id NULLS LAST;
```

**차이점:**
```
NORMAL ROLLUP(a, b, c):
  (a, b, c), (a, b), (a), () — 4가지 수준

COMPOSITE ROLLUP(a, (b, c)):
  (a, b, c), (a), ()       — 3가지 수준 (중간 수준 건너뜀)
```

---

**[18번]** Concatenated Groupings

```sql
SELECT   department_id, job_id, manager_id,
         SUM(salary),
         GROUPING(department_id) gd,
         GROUPING(job_id)        gj,
         GROUPING(manager_id)    gm
FROM     employees
WHERE    department_id IN (20, 50)
GROUP BY department_id,
         ROLLUP(job_id),
         CUBE(manager_id)
ORDER BY department_id, gj, gm, job_id NULLS LAST, manager_id NULLS LAST;
```

**집계 수준 계산:**
- `dept`: 고정 (1)
- `ROLLUP(job)`: (job), () = 2가지
- `CUBE(mgr)`: (mgr), () = 2가지
- 교차 곱: 2 × 2 = 4가지 수준

---

**[19번]** GROUPING SETS 연결 (교차 조합)

```sql
SELECT   department_id, job_id, manager_id, SUM(salary)
FROM     employees
WHERE    department_id IN (20, 50, 80)
GROUP BY GROUPING SETS (department_id, job_id),
         GROUPING SETS (manager_id, ())
ORDER BY department_id NULLS LAST, job_id NULLS LAST, manager_id NULLS LAST;
```

**생성 그룹화 조합:**
- `(dept, mgr)`, `(dept)`
- `(job, mgr)`, `(job)`
- 총 4가지 그룹화

---

## Group 6: 종합 실습

**[20번]** 부서명 포함 ROLLUP 레이블 보고서

```sql
SELECT   DECODE(GROUPING(d.department_name), 1, '★ 전체 합계',
         DECODE(GROUPING(e.job_id), 1, '  ▶ 소계: ' || d.department_name,
                d.department_name))       AS dept_label,
         DECODE(GROUPING(e.job_id), 1, '',
                e.job_id)                 AS job,
         SUM(e.salary)                   AS total_salary,
         COUNT(e.employee_id)            AS headcount,
         ROUND(AVG(e.salary))            AS avg_salary
FROM     employees  e
JOIN     departments d ON e.department_id = d.department_id
WHERE    e.department_id IN (10, 20, 30, 40, 50)
GROUP BY ROLLUP(d.department_name, e.job_id)
ORDER BY GROUPING(d.department_name), GROUPING(e.job_id),
         d.department_name, e.job_id NULLS LAST;
```

**출력 예시:**
```
DEPT_LABEL             JOB        TOTAL_SALARY  HEADCOUNT  AVG_SALARY
Administration         AD_ASST          4400          1       4400
  ▶ 소계: Administration               4400          1       4400
Marketing              MK_MAN          13000          1      13000
Marketing              MK_REP           6000          1       6000
  ▶ 소계: Marketing                   19000          2       9500
...
★ 전체 합계                           XXXXX         XX       XXXX
```

---

**[21번]** 3축 CUBE 다차원 보고서

```sql
SELECT   CASE
             WHEN GROUPING(department_id) = 1
              AND GROUPING(job_id) = 1
              AND GROUPING(manager_id) = 1 THEN '전체합계'
             WHEN GROUPING(department_id) = 0
              AND GROUPING(job_id) = 1
              AND GROUPING(manager_id) = 1 THEN '부서합계'
             WHEN GROUPING(department_id) = 1
              AND GROUPING(job_id) = 0
              AND GROUPING(manager_id) = 1 THEN '직무합계'
             WHEN GROUPING(department_id) = 1
              AND GROUPING(job_id) = 1
              AND GROUPING(manager_id) = 0 THEN '관리자합계'
             ELSE '상세'
         END AS level_label,
         department_id, job_id, manager_id,
         SUM(salary)   AS total_sal,
         COUNT(*)      AS cnt
FROM     employees
WHERE    department_id IN (20, 50, 80)
GROUP BY CUBE(department_id, job_id, manager_id)
HAVING   NOT (GROUPING(department_id) = 0
              AND GROUPING(job_id) = 0
              AND GROUPING(manager_id) = 0
              AND COUNT(*) < 2)
ORDER BY GROUPING(department_id) + GROUPING(job_id) + GROUPING(manager_id),
         department_id NULLS LAST, job_id NULLS LAST, manager_id NULLS LAST;
```

---

**[22번]** 통계 집계 ROLLUP 보고서

```sql
SELECT   DECODE(GROUPING(d.department_name), 1, '전체',
                d.department_name)        AS dept,
         DECODE(GROUPING(e.job_id), 1, '---',
                e.job_id)                 AS job,
         MAX(e.salary)    AS max_sal,
         MIN(e.salary)    AS min_sal,
         ROUND(AVG(e.salary)) AS avg_sal,
         COUNT(*)         AS cnt
FROM     employees  e
JOIN     departments d ON e.department_id = d.department_id
WHERE    e.department_id < 80
GROUP BY ROLLUP(d.department_name, e.job_id)
ORDER BY GROUPING(d.department_name), GROUPING(e.job_id),
         d.department_name NULLS LAST, e.job_id NULLS LAST;
```

---

**[23번]** GROUPING SETS 비교 보고서 (월별 vs 부서별)

```sql
SELECT   DECODE(GROUPING(EXTRACT(MONTH FROM hire_date)), 0,
                '입사월: ' || TO_CHAR(EXTRACT(MONTH FROM hire_date), '09'),
                NULL)                      AS hire_month,
         DECODE(GROUPING(department_id), 0,
                '부서: ' || TO_CHAR(department_id),
                NULL)                      AS dept,
         COUNT(*)                          AS hire_count,
         ROUND(AVG(salary))               AS avg_salary
FROM     employees
GROUP BY GROUPING SETS (
    (EXTRACT(MONTH FROM hire_date)),
    (department_id)
)
ORDER BY GROUPING(EXTRACT(MONTH FROM hire_date)) DESC,
         hire_month NULLS LAST, dept NULLS LAST;
```

**출력 예시 (일부):**
```
HIRE_MONTH  DEPT   HIRE_COUNT  AVG_SALARY
입사월:  01  NULL        5        6000
입사월:  02  NULL        4        8000
...
NULL   부서: 10        1        4400
NULL   부서: 20        2        9500
```

---

**[24번]** 다차원 피벗 보고서 (CUBE + JOIN)

```sql
SELECT   NVL(d.department_name, '전체') AS department,
         NVL(e.job_id, '전체')          AS job,
         SUM(e.salary)                  AS total_salary,
         COUNT(*)                       AS headcount,
         ROUND(AVG(e.salary))           AS avg_salary,
         MAX(e.salary)                  AS max_salary,
         MIN(e.salary)                  AS min_salary
FROM     employees  e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE    e.department_id IN (20, 50, 60, 80)
GROUP BY CUBE(d.department_name, e.job_id)
ORDER BY GROUPING(d.department_name),
         GROUPING(e.job_id),
         d.department_name NULLS LAST,
         e.job_id NULLS LAST;
```

**주의:** `LEFT JOIN` 사용으로 department_id가 있더라도 departments에 없는 경우 처리.

---

**[25번]** 입사 연도별 + 부서별 ROLLUP 보고서

```sql
SELECT   DECODE(GROUPING(hire_year), 1, '전체',
                TO_CHAR(hire_year))          AS year_label,
         DECODE(GROUPING(department_id), 1, '소계',
                TO_CHAR(department_id))      AS dept_label,
         hire_count,
         SUM(hire_count) OVER (
             PARTITION BY DECODE(GROUPING(hire_year), 1, 'ALL', TO_CHAR(hire_year))
             ORDER BY DECODE(GROUPING(department_id), 1, 9999, department_id)
         ) AS running_total
FROM (
    SELECT   EXTRACT(YEAR FROM hire_date) AS hire_year,
             department_id,
             COUNT(*) AS hire_count,
             GROUPING(EXTRACT(YEAR FROM hire_date)) AS gy,
             GROUPING(department_id) AS gd
    FROM     employees
    GROUP BY ROLLUP(EXTRACT(YEAR FROM hire_date), department_id)
) t
ORDER BY DECODE(gy, 1, 9999, hire_year),
         DECODE(gd, 1, 9999, department_id) NULLS LAST;
```

**포인트:** 인라인 뷰로 ROLLUP 결과를 먼저 만든 후, 분석 함수(SUM OVER)를 적용하여 누계를 계산한다.

---

**[26번]** 급여 등급별 + 부서별 ROLLUP 종합 보고서

```sql
SELECT   DECODE(GROUPING(salary_grade), 1, '전체', salary_grade)  AS grade,
         DECODE(GROUPING(department_id), 1, '소계',
                TO_CHAR(department_id))                            AS dept,
         COUNT(*)    AS headcount,
         SUM(salary) AS total_salary
FROM (
    SELECT employee_id,
           department_id,
           salary,
           CASE
               WHEN salary >= 10000 THEN 'S'
               WHEN salary >=  7000 THEN 'A'
               WHEN salary >=  4000 THEN 'B'
               ELSE                      'C'
           END AS salary_grade
    FROM   employees
) t
WHERE  department_id IS NOT NULL
GROUP BY ROLLUP(salary_grade, department_id)
ORDER BY GROUPING(salary_grade), salary_grade,
         GROUPING(department_id), department_id NULLS LAST;
```

**출력 예시:**
```
GRADE  DEPT   HEADCOUNT  TOTAL_SALARY
A      20         1          13000
A      50         8          ...
A      소계       9          ...
B      10         1           4400
B      50        16           ...
B      소계      17           ...
S      90         3          52000
S      소계       3          52000
전체   소계      XX          XXXXX   ← 전체 합계
```
