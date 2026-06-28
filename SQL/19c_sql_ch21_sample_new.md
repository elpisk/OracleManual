# Oracle Database 19c: SQL Workshop
## Chapter 21 — 고급 그룹 함수 | SQL 실습 문제

---

> **참고:** 이 실습은 HR 스키마가 설치된 Oracle 19c 환경에서 수행하세요.

---

## Group 1: ROLLUP 기본

**[1번]** `employees` 테이블에서 부서별, 직무별 급여 합계를 조회하시오. ROLLUP을 사용하여 부서 소계와 전체 합계도 포함하시오.

```sql
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY ROLLUP(department_id, job_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

---

**[2번]** 부서별 직원 수 소계를 ROLLUP으로 조회하시오. `department_id`만 사용하고 전체 합계도 포함하시오.

```sql
SELECT   department_id,
         COUNT(*) AS employee_count
FROM     employees
GROUP BY ROLLUP(department_id)
ORDER BY department_id NULLS LAST;
```

---

**[3번]** `department_id`, `job_id`, `manager_id` 세 개 컬럼에 ROLLUP을 적용하여 다단계 소계를 생성하시오.

```sql
SELECT   department_id, job_id, manager_id,
         SUM(salary)    AS total_salary,
         COUNT(*)       AS headcount
FROM     employees
WHERE    department_id IN (20, 50, 80)
GROUP BY ROLLUP(department_id, job_id, manager_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST, manager_id NULLS LAST;
```

---

**[4번]** 입사 연도와 부서를 기준으로 급여 합계를 ROLLUP으로 집계하시오.

```sql
SELECT   EXTRACT(YEAR FROM hire_date) AS hire_year,
         department_id,
         SUM(salary)                  AS total_salary
FROM     employees
GROUP BY ROLLUP(EXTRACT(YEAR FROM hire_date), department_id)
ORDER BY hire_year NULLS LAST, department_id NULLS LAST;
```

---

**[5번]** ROLLUP 결과에서 소계 행에는 `'[소계]'`, 전체 합계 행에는 `'[전체]'` 레이블을 표시하시오.

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

---

## Group 2: CUBE 기본

**[6번]** `employees` 테이블에서 부서별, 직무별 급여 합계를 CUBE로 조회하시오. 모든 교차 집계가 포함되어야 한다.

```sql
SELECT   department_id, job_id, SUM(salary) AS total_salary
FROM     employees
WHERE    department_id < 60
GROUP BY CUBE(department_id, job_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

---

**[7번]** CUBE 결과에서 직무(job_id) 단독 소계만 조회하시오 (GROUPING 함수 활용).

```sql
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY CUBE(department_id, job_id)
HAVING   GROUPING(department_id) = 1
         AND GROUPING(job_id) = 0
ORDER BY job_id;
```

---

**[8번]** `department_id`, `job_id`, `manager_id`에 CUBE를 적용하고, GROUPING 함수로 각 집계 수준의 조합을 숫자로 표시하시오.

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

---

**[9번]** ROLLUP과 CUBE 결과를 비교하기 위해 두 쿼리를 각각 실행하고, CUBE에만 있는 행(직무 소계)을 확인하시오.

```sql
-- ROLLUP 결과
SELECT 'ROLLUP' AS src, department_id, job_id, SUM(salary)
FROM   employees
WHERE  department_id < 60
GROUP BY ROLLUP(department_id, job_id)
UNION ALL
-- CUBE에만 있는 행 (직무 단독 소계)
SELECT 'CUBE_ONLY' AS src, department_id, job_id, SUM(salary)
FROM   employees
WHERE  department_id < 60
GROUP BY CUBE(department_id, job_id)
HAVING GROUPING(department_id) = 1 AND GROUPING(job_id) = 0
ORDER BY src, department_id NULLS LAST, job_id NULLS LAST;
```

---

## Group 3: GROUPING 함수 활용

**[10번]** ROLLUP 결과에서 소계 행 유형을 GROUPING 함수로 판별하여 레이블(전체합계/부서소계/상세)로 표시하시오.

```sql
SELECT   CASE
             WHEN GROUPING(department_id) = 1 AND GROUPING(job_id) = 1 THEN '전체합계'
             WHEN GROUPING(department_id) = 0 AND GROUPING(job_id) = 1 THEN '부서소계'
             ELSE '상세'
         END                   AS row_type,
         department_id,
         job_id,
         SUM(salary)           AS total_salary,
         COUNT(*)              AS headcount
FROM     employees
WHERE    department_id < 60
GROUP BY ROLLUP(department_id, job_id)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

---

**[11번]** 전체 합계 행만 제외하고 일반 행과 소계 행만 조회하시오.

```sql
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY ROLLUP(department_id, job_id)
HAVING   NOT (GROUPING(department_id) = 1 AND GROUPING(job_id) = 1)
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
```

---

**[12번]** CUBE 결과에서 실제 데이터 행(일반 행)만 조회하시오 (소계/전체합계 제외).

```sql
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id < 60
GROUP BY CUBE(department_id, job_id)
HAVING   GROUPING(department_id) = 0 AND GROUPING(job_id) = 0
ORDER BY department_id, job_id;
```

---

**[13번]** GROUPING 함수를 사용하여 각 행이 어느 수준의 집계인지 비트 값으로 표시하시오.

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

---

## Group 4: GROUPING SETS

**[14번]** 부서-직무 조합과 직무-관리자 조합을 단일 SELECT로 조회하시오.

```sql
SELECT   department_id, job_id, manager_id,
         AVG(salary)  AS avg_salary,
         COUNT(*)     AS headcount
FROM     employees
GROUP BY GROUPING SETS (
    (department_id, job_id),
    (job_id, manager_id)
)
ORDER BY GROUPING(department_id), GROUPING(manager_id), department_id NULLS LAST;
```

---

**[15번]** 부서별, 직무별, 전체 세 가지 그룹화를 GROUPING SETS로 구현하시오.

```sql
SELECT   department_id, job_id, SUM(salary), COUNT(*) AS headcount
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

**[16번]** GROUPING SETS를 동등한 UNION ALL 쿼리와 비교하시오.

```sql
-- GROUPING SETS 버전
SELECT   department_id, job_id, SUM(salary)
FROM     employees
WHERE    department_id IN (10, 20, 30)
GROUP BY GROUPING SETS ((department_id, job_id), (department_id))
ORDER BY department_id NULLS LAST, job_id NULLS LAST;

-- 동등한 UNION ALL 버전
SELECT   department_id, job_id, SUM(salary)
FROM     employees WHERE department_id IN (10, 20, 30)
GROUP BY department_id, job_id
UNION ALL
SELECT   department_id, NULL, SUM(salary)
FROM     employees WHERE department_id IN (10, 20, 30)
GROUP BY department_id
ORDER BY department_id NULLS LAST, job_id NULLS LAST;
-- 두 쿼리의 결과를 비교하여 동일한지 확인
```

---

## Group 5: 복합 컬럼 & 연결 그룹화

**[17번]** `ROLLUP(department_id, (job_id, manager_id))`를 사용하여 복합 컬럼이 중간 소계를 건너뛰는 것을 확인하시오.

```sql
-- 일반 ROLLUP (3개 컬럼, 4가지 수준)
SELECT 'NORMAL' AS rollup_type, department_id, job_id, manager_id, SUM(salary)
FROM   employees
WHERE  department_id IN (20, 50)
GROUP BY ROLLUP(department_id, job_id, manager_id)
UNION ALL
-- 복합 컬럼 ROLLUP (3가지 수준)
SELECT 'COMPOSITE', department_id, job_id, manager_id, SUM(salary)
FROM   employees
WHERE  department_id IN (20, 50)
GROUP BY ROLLUP(department_id, (job_id, manager_id))
ORDER BY rollup_type, department_id NULLS LAST;
```

---

**[18번]** Concatenated Groupings로 `department_id`는 고정하고 `job_id`에 ROLLUP, `manager_id`에 CUBE를 적용하시오.

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

---

**[19번]** `GROUPING SETS`를 연결하여 두 가지 독립적 집계를 교차 조합하시오.

```sql
SELECT   department_id, job_id, manager_id, SUM(salary)
FROM     employees
WHERE    department_id IN (20, 50, 80)
GROUP BY GROUPING SETS (department_id, job_id),
         GROUPING SETS (manager_id, ())
ORDER BY department_id NULLS LAST, job_id NULLS LAST, manager_id NULLS LAST;
```

---

## Group 6: 종합 실습

**[20번]** 부서별, 직무별 급여 합계를 ROLLUP으로 집계하고, 소계 행은 굵은 표시(레이블 추가)로 출력하시오.

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

---

**[21번]** 경영진 보고용 다차원 급여 분석 보고서를 작성하시오. 부서, 직무, 관리자 3축의 CUBE 결과에서 소계 수준을 레이블로 표시하시오.

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
              AND COUNT(*) < 2)  -- 인원 2명 미만 상세 행 제외
ORDER BY GROUPING(department_id) + GROUPING(job_id) + GROUPING(manager_id),
         department_id NULLS LAST, job_id NULLS LAST, manager_id NULLS LAST;
```

---

**[22번]** 부서별 최대 급여, 최소 급여, 평균 급여를 ROLLUP으로 집계하고, 소계 구분 레이블을 추가하시오.

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

**[23번]** GROUPING SETS를 사용하여 월별 입사 현황과 부서별 입사 현황을 단일 쿼리로 출력하시오.

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

---

**[24번]** 부서별 급여 분포를 위한 피벗형 보고서를 CUBE로 작성하시오. 직무별 소계와 부서별 소계를 모두 포함하시오.

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

---

**[25번]** 입사 연도별, 부서별 인원 변화를 ROLLUP으로 파악하고, 연도 소계와 전체 합계를 포함하시오.

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
ORDER BY DECODE(gy, 1, 9999, hire_year), DECODE(gd, 1, 9999, department_id) NULLS LAST;
```

---

**[26번]** 종합: 급여 등급별(CASE로 S/A/B/C 구분), 부서별 인원수를 ROLLUP으로 집계하시오.

```sql
SELECT   DECODE(GROUPING(salary_grade), 1, '전체', salary_grade)  AS grade,
         DECODE(GROUPING(department_id), 1, '소계',
                TO_CHAR(department_id))                            AS dept,
         COUNT(*)   AS headcount,
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
