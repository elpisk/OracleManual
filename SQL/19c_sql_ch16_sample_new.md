# Oracle Database 19c: SQL Workshop
## Chapter 16 — 서브쿼리를 이용한 데이터 조회 | SQL 실습 문제

---

## Group 1: 인라인 뷰 (FROM 절 서브쿼리)

**[1번]** 유럽(Europe) 지역에 위치한 부서의 이름과 도시를 조회하시오.  
인라인 뷰를 사용하여 `LOCATIONS`, `COUNTRIES`, `REGIONS`를 조인한 결과를 FROM 절에서 활용하시오.

---

**[2번]** 각 부서별 직원 수를 인라인 뷰로 구한 뒤, 직원 수가 5명 이상인 부서의 이름과 직원 수를 출력하시오.  
(`DEPARTMENTS`와 `EMPLOYEES` 테이블 사용)

---

**[3번]** 다음 인라인 뷰를 사용하여 급여가 회사 전체 평균 급여보다 높은 직원의 이름, 급여, 부서 ID를 조회하시오.

```sql
(SELECT AVG(salary) avg_sal FROM employees)
```

---

**[4번]** 부서별 최고 급여자 정보를 인라인 뷰를 활용하여 출력하시오.  
출력 컬럼: `department_id`, `max_salary`, `employee_id`, `last_name`  
(인라인 뷰로 부서별 MAX 급여를 구한 뒤 `EMPLOYEES`와 조인)

---

**[5번]** 각 직업(job_id)별 평균 급여를 인라인 뷰로 구하고, 그 중 평균 급여가 가장 높은 직업 3개를 출력하시오.  
(인라인 뷰 + `ROWNUM` 또는 `FETCH FIRST 3 ROWS ONLY` 사용)

---

## Group 2: 다중 열 서브쿼리 (쌍·비쌍 비교)

**[6번]** 직원 번호 174번, 141번과 **동일한** `manager_id`, `department_id` 조합을 가진 직원을 조회하시오.  
단, 직원 번호 174, 141 자신은 제외. **쌍 비교(pairwise)**를 사용하시오.  
출력 컬럼: `employee_id`, `last_name`, `manager_id`, `department_id`

---

**[7번]** [6번]과 동일한 조건을 **비쌍 비교(nonpairwise)**로 작성하시오.  
두 결과의 차이를 확인하고, 어느 쪽 결과가 더 많은지 설명하는 주석을 쿼리 앞에 추가하시오.

---

**[8번]** 급여와 부서 ID가 모두 특정 직원들(`employee_id IN (103, 107, 178)`)과 동일한 직원을 쌍 비교로 조회하시오.  
출력 컬럼: `employee_id`, `last_name`, `salary`, `department_id`

---

**[9번]** 다중 열 서브쿼리를 사용하여 각 부서에서 최소 급여를 받는 직원을 조회하시오.  
(서브쿼리: 부서별 MIN(salary) 반환, 메인 쿼리: `(department_id, salary) IN (서브쿼리)`)  
출력 컬럼: `employee_id`, `last_name`, `department_id`, `salary`

---

**[10번]** 부서 ID와 직업 ID 조합이 부서 10, 20, 30의 직원들과 동일한 직원을 쌍 비교로 조회하시오.  
단, 부서 10, 20, 30 직원 자신은 제외.  
출력 컬럼: `employee_id`, `last_name`, `department_id`, `job_id`

---

## Group 3: 스칼라 서브쿼리

**[11번]** `SELECT` 절에 스칼라 서브쿼리를 사용하여 각 직원의 이름, 급여, 그리고 해당 직원이 속한 부서의 평균 급여를 출력하시오.  
출력 컬럼: `last_name`, `salary`, `dept_avg_salary`  
급여 내림차순 정렬.

---

**[12번]** `CASE` 식에 스칼라 서브쿼리를 사용하여 각 직원의 급여가 해당 부서 평균 급여보다 높으면 'Above Average', 낮으면 'Below Average', 같으면 'Average'로 분류하시오.  
출력 컬럼: `employee_id`, `last_name`, `salary`, `salary_category`

---

**[13번]** `ORDER BY` 절에 스칼라 서브쿼리를 사용하여 직원 목록을 **부서 직원 수** 순(많은 부서 먼저)으로 정렬하시오.  
출력 컬럼: `employee_id`, `last_name`, `department_id`

---

**[14번]** 스칼라 서브쿼리를 사용하여 각 부서 정보와 함께 해당 부서에서 가장 최근 입사한 직원의 이름을 출력하시오.  
출력 컬럼: `department_id`, `department_name`, `latest_hire_name`  
(직원이 없는 부서는 `latest_hire_name`이 NULL)

---

**[15번]** 스칼라 서브쿼리를 사용하여 급여가 자신이 속한 부서 평균 급여의 1.5배 이상인 직원을 조회하시오.  
출력 컬럼: `employee_id`, `last_name`, `department_id`, `salary`  
급여 내림차순 정렬.

---

## Group 4: 상관 서브쿼리 & EXISTS

**[16번]** 상관 서브쿼리를 사용하여 본인이 속한 부서에서 평균 급여보다 높은 급여를 받는 직원을 조회하시오.  
출력 컬럼: `last_name`, `department_id`, `salary`

---

**[17번]** 상관 서브쿼리를 사용하여 동일한 직업(job_id)을 가진 직원 중 급여가 평균보다 높은 직원을 조회하시오.  
출력 컬럼: `employee_id`, `last_name`, `job_id`, `salary`

---

**[18번]** `EXISTS` 연산자를 사용하여 부하 직원이 있는 관리자(manager) 직원 목록을 조회하시오.  
출력 컬럼: `employee_id`, `last_name`, `job_id`, `department_id`

---

**[19번]** `NOT EXISTS`를 사용하여 직원이 한 명도 없는 부서를 조회하시오.  
출력 컬럼: `department_id`, `department_name`  
부서 ID 오름차순 정렬.

---

**[20번]** 상관 서브쿼리를 사용하여 최소 1건 이상의 이력(`JOB_HISTORY`)이 있는 직원을 조회하시오.  
`EXISTS`를 사용하고, 출력 컬럼: `employee_id`, `last_name`, `job_id`

---

**[21번]** `NOT EXISTS`를 사용하여 `JOB_HISTORY`에 이력이 없는 직원을 조회하시오.  
출력 컬럼: `employee_id`, `last_name`, `hire_date`  
입사일 내림차순 정렬.

---

## Group 5: WITH 절 & 재귀 WITH

**[22번]** WITH 절을 사용하여 부서별 평균 급여를 구하고, 평균 급여가 10,000 이상인 부서의 이름과 평균 급여를 출력하시오.  
출력 컬럼: `department_name`, `avg_salary`  
평균 급여 내림차순 정렬.

---

**[23번]** 다음 두 개의 CTE를 WITH 절로 정의하고 메인 쿼리에서 활용하시오.

- `dept_stats`: 부서별 직원 수(`emp_count`), 평균 급여(`avg_sal`)
- `top_depts`: `dept_stats`에서 직원 수가 5명 이상인 부서

메인 쿼리: `top_depts`에 속한 직원의 이름, 급여, 부서 ID를 출력.  
급여 내림차순 정렬.

---

**[24번]** WITH 절을 사용하여 각 부서별 급여 합계를 구하고, 전체 급여 합계 대비 각 부서가 차지하는 비율(%)을 계산하여 출력하시오.  
출력 컬럼: `department_id`, `dept_total_sal`, `pct_of_total`  
비율 내림차순 정렬, 비율은 소수점 2자리 반올림.

---

**[25번]** WITH 절을 사용하여 가장 높은 급여를 받는 직원이 소속된 부서의 이름과 위치(도시)를 출력하시오.  
(단일 SQL로 작성, CTE에 최고 급여자 정보 포함)

---

**[26번]** WITH 절을 사용하여 직원을 다음 세 그룹으로 분류하고 각 그룹의 직원 수와 평균 급여를 출력하시오.

| 그룹 | 기준 |
|------|------|
| High | salary >= 10000 |
| Mid | 5000 <= salary < 10000 |
| Low | salary < 5000 |

출력 컬럼: `salary_group`, `emp_count`, `avg_salary`

---

**[27번]** 재귀 WITH 절을 사용하여 EMPLOYEES 테이블의 조직 계층 구조를 출력하시오.  
최상위 관리자(`manager_id IS NULL`)부터 시작하여 각 직원의 계층 레벨(`lvl`)을 표시하시오.  
출력 컬럼: `employee_id`, `last_name`, `manager_id`, `lvl`  
`lvl`, `manager_id` 순으로 정렬.

---

**[28번]** [27번]의 결과에 들여쓰기를 추가하여 계층 구조를 시각적으로 표현하시오.  
`LPAD(' ', (lvl-1)*3, ' ') || last_name` 형식을 사용하시오.  
출력 컬럼: `employee_id`, `org_chart`(들여쓰기+이름), `lvl`

---

**[29번]** WITH 절과 상관 서브쿼리를 함께 사용하여 부서별로 평균 급여를 구한 뒤, 평균 급여보다 20% 이상 높은 급여를 받는 직원을 조회하시오.  
출력 컬럼: `employee_id`, `last_name`, `department_id`, `salary`, `dept_avg_salary`  
급여 내림차순 정렬.

---

**[30번]** 다음 요구사항을 WITH 절 + 인라인 뷰 + EXISTS를 모두 활용한 단일 쿼리로 작성하시오.

**요구사항:** 부서별 최고 급여자 중 관리자(다른 직원의 manager_id로 등록된 직원)인 사람만 출력  
출력 컬럼: `employee_id`, `last_name`, `department_id`, `salary`  
급여 내림차순 정렬.

---
