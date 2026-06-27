# Oracle Database 19c: SQL Workshop
## Chapter 9 — 집합 연산자 사용 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ② UNION | UNION은 두 쿼리 합집합, 중복 제거 |
| 2 | ② UNION ALL | UNION ALL은 중복 행 포함 |
| 3 | ③ INTERSECT | 교집합 — 두 쿼리 공통 행만 반환 |
| 4 | ③ MINUS | 차집합 — 첫 번째에만 있는 행 |
| 5 | ③ 열 개수와 데이터 타입 | 열 이름은 달라도 됨 |
| 6 | ② 첫 번째 SELECT 쿼리 | 열 이름은 첫 번째 쿼리에서 결정 |
| 7 | ③ 오름차순 | UNION ALL 제외, 기본 오름차순 |
| 8 | ② 중복 행을 제거하지 않기 때문 | UNION ALL은 중복 포함 |
| 9 | ④ UNION ALL은 중복을 포함한다 | UNION=중복제거, INTERSECT=교집합, MINUS=차집합 |
| 10 | ③ 복합 쿼리의 맨 끝 | ORDER BY는 마지막에 한 번만 |
| 11 | ② `SELECT a, b FROM t1 UNION SELECT c, d FROM t2` | 열 개수 일치 필수 |
| 12 | ③ `TO_CHAR(NULL)` | 없는 열 자리에 타입 일치 NULL 사용 |
| 13 | ② 복합 쿼리 전체에서 한 번만 | ORDER BY 단 한 번 |
| 14 | ③ 자동으로 제거 | UNION ALL만 중복 유지 |
| 15 | ③ 첫 번째 쿼리에만 있는 고유 행을 반환한다 | MINUS = A - B |
| 16 | ② 실행 순서를 변경한다 | 괄호로 집합 연산 우선순위 조정 |
| 17 | ② 두 쿼리 모두에 존재하는 행 | INTERSECT = 공통 행 |
| 18 | ③ UNION ALL | 중복 제거 연산 없음 → 가장 빠름 |
| 19 | ② 결과의 두 번째 열을 기준으로 정렬 | ORDER BY 열 위치 번호 |
| 20 | ② 두 쿼리의 열 개수가 다른 경우 | 열 개수 불일치 → ORA-01789 오류 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ②**

UNION ALL은 중복을 제거하지 않으므로 EMPLOYEES와 JOB_HISTORY에서 동일한 job_id가 있어도 모두 반환된다.

---

**[22번] 정답: ③ INTERSECT**

INTERSECT는 두 쿼리 결과의 교집합을 반환한다. `employee_id`와 `job_id`가 두 테이블 모두에 존재하는 공통 행만 반환한다.

---

**[23번] 정답: ① `사원명`, `SALARY` — 첫 번째 쿼리 기준**

집합 연산자에서 결과 열 이름은 **첫 번째 SELECT 쿼리의 열 이름(별칭 포함)**을 따른다.  
첫 번째 쿼리에서 `last_name AS "사원명"`을 지정했으므로 결과 열 이름은 `사원명`이 된다.

---

**[24번] 정답: ② `SELECT employee_id FROM employees MINUS SELECT employee_id FROM job_history`**

MINUS는 첫 번째 쿼리 결과에서 두 번째 쿼리 결과를 제거한다.  
EMPLOYEES - JOB_HISTORY = JOB_HISTORY에 이력이 없는 사원.

---

**[25번] 정답: ③ EMPLOYEES와 DEPARTMENTS 양쪽 모두에 있는 department_id**

INTERSECT는 두 쿼리의 공통 행을 반환한다. 두 테이블 모두에 존재하는 department_id가 반환된다.

---

**[26번] 정답: ② 열 개수 불일치 (3개 vs 2개)**

첫 번째 쿼리는 `employee_id, last_name, salary` 3개 열, 두 번째는 `employee_id, last_name` 2개 열이므로 ORA-01789 오류가 발생한다.

---

**[27번] 정답: ③ 두 테이블의 고유 job_id 합집합 (중복 제거)**

UNION은 중복을 제거하므로 EMPLOYEES와 JOB_HISTORY에 공통으로 있는 job_id는 한 번만 포함된다. 결과 행 수는 두 테이블의 고유 job_id 합집합 수이다.

---

**[28번] 정답: ② (B)만 올바름**

집합 연산자를 사용한 복합 쿼리에서 ORDER BY는 반드시 **마지막 SELECT 문 뒤**에 한 번만 위치해야 한다. (A)처럼 중간에 ORDER BY를 사용하면 오류가 발생한다.

---

**[29번] 정답: ② 없는 열 자리에 `TO_CHAR(NULL)` 또는 `TO_DATE(NULL)` 등 NULL 변환 사용**

열 개수와 데이터 타입을 맞추기 위해 해당 테이블에 없는 열 자리에 적절한 데이터 타입의 NULL 변환 함수를 사용한다.

---

**[30번] 정답: ② 관리자가 아닌 사원의 employee_id 조회**

- 첫 번째 쿼리: 전체 사원의 employee_id
- 두 번째 쿼리: 관리자 역할을 하는 manager_id (IS NOT NULL 필터)
- MINUS: 전체 사원 중 관리자가 아닌 사원의 employee_id

---

**[31번] 정답: ② `SELECT ... UNION SELECT ... UNION SELECT ...`**

집합 연산자는 두 개 이상의 테이블에 연속 적용할 수 있다.  
예: `SELECT a FROM t1 UNION SELECT a FROM t2 UNION SELECT a FROM t3;`

---

**[32번] 정답: ③ employee_id(첫 번째 열) 기준 오름차순 정렬**

`ORDER BY 1`은 결과의 첫 번째 열을 기준으로 정렬한다. 첫 번째 열은 `employee_id`이므로 employee_id 오름차순 정렬이다.

---

**[33번] 정답: ② A는 중복을 제거하고 B는 중복을 포함한다**

UNION과 UNION ALL의 차이는 중복 처리 여부이다. 공통 job_id가 있다면 UNION은 한 번만, UNION ALL은 모두 포함한다.

---

**[34번] 정답: ② hire_date 열이 없는 테이블에서 DATE 타입의 NULL로 열 개수/타입 일치**

`TO_DATE(NULL)`은 DATE 타입의 NULL 값을 생성한다. 집합 연산에서 열 데이터 타입을 맞추기 위해 사용한다.

---

**[35번] 정답: ③ 첫 번째 쿼리에 있지만 두 번째 쿼리에는 없는 행**

MINUS는 A - B(차집합)을 반환한다. A에 있고 B에 없는 행만 결과에 포함된다.

---

**[36번] 정답: ② EMPLOYEES에 있지만 DEPARTMENTS에 없는 department_id**

EMPLOYEES의 department_id에서 DEPARTMENTS의 department_id를 뺀 결과이다.  
외래키 제약이 있다면 0행이 반환될 것이다.

---

**[37번] 정답: ② 첫 번째 SELECT 쿼리의 열 이름 또는 별칭 사용**

ORDER BY는 첫 번째 SELECT 쿼리의 열 이름이나 별칭을 인식한다.  
두 번째 이후 쿼리의 열 이름은 ORDER BY에서 사용할 수 없다.

---

**[38번] 정답: ③ 두 테이블 모두에 존재하는 공통 데이터를 찾을 때**

INTERSECT는 두 집합의 교집합을 반환하므로, 두 테이블 또는 조건에 모두 해당하는 공통 데이터를 찾을 때 가장 적합하다.

---

**[39번] 정답: ③ 가능 — INTERSECT가 UNION보다 우선순위가 높아 먼저 처리됨**

Oracle에서 집합 연산자의 우선순위:
1. **INTERSECT** (가장 높음)
2. UNION, UNION ALL, MINUS (동일)

따라서 위 SQL은 `(job_history INTERSECT departments)` 먼저 실행 후 `employees UNION` 결과와 합쳐진다. 괄호로 명시적으로 순서를 지정하는 것이 안전하다.

---

**[40번] 정답: ② 정확히 117행**

UNION ALL은 중복을 제거하지 않으므로 두 쿼리 결과의 행 수를 단순 합산한다: 107 + 10 = 117행.

---

## 상(심화) 모범답안

---

**[41번] 정답: ① 모든 부서에 사원이 존재한다면 결과는 0행**

```
DEPARTMENTS의 department_id - EMPLOYEES의 department_id
= EMPLOYEES에 없는 부서 ID (사원이 없는 부서)
```
모든 부서에 사원이 있다면 두 집합이 동일하므로 차집합은 0행이다.  
사원이 없는 부서가 있다면 해당 department_id가 반환된다.

---

**[42번] 정답: ③ 모든 집합 연산자의 우선순위는 동일하며 괄호로 조정**

표준 SQL(및 대부분의 구현)에서 집합 연산자의 우선순위는 동일하고 왼쪽에서 오른쪽으로 처리된다.  
단, Oracle에서 **INTERSECT**가 더 높은 우선순위를 가진다는 점에 주의해야 한다.  
정확한 실행 순서를 보장하려면 **괄호**를 명시적으로 사용하는 것이 권장된다.

---

**[43번] 정답: ① 항상 같다**

두 SQL 모두 동일한 결과를 반환한다:
- **SQL X (MINUS)**: employee_id 전체에서 manager_id를 제거 (IS NOT NULL 필터 적용)
- **SQL Y (NOT IN + IS NOT NULL)**: NOT IN 서브쿼리에 IS NOT NULL 필터 적용

두 경우 모두 NULL 문제를 올바르게 처리하므로 결과가 동일하다.  
※ IS NOT NULL 필터 없이 NOT IN을 사용했을 때 SQL Y는 0행 반환 가능.

---

**[44번] 정답: ② ORDER BY를 첫 번째 SELECT에 사용했기 때문**

집합 연산자를 사용할 때 ORDER BY는 복합 쿼리 **맨 끝에 단 한 번**만 사용할 수 있다.  
개별 SELECT 문 사이에 ORDER BY를 사용하면 오류가 발생한다.

올바른 형식:
```sql
SELECT employee_id, last_name, hire_date
FROM   employees
UNION
SELECT employee_id, job_id, start_date
FROM   job_history
ORDER BY hire_date;  -- 맨 끝에 한 번만
```

---

**[45번] 정답: ② salary 내림차순으로 전체 결과 정렬됨**

`ORDER BY 3`은 세 번째 열(salary)을 기준으로 내림차순 정렬한다.  
리터럴 값('A', 'B', 'C')도 SELECT 목록에 포함될 수 있으며, UNION ALL이므로 중복 포함 전체 결과가 salary 내림차순으로 정렬된다.

---

**[46번] 정답: ② location_id가 1700 또는 1800인 부서의 사원 반환**

서브쿼리 내에서 UNION은 OR 역할을 한다:
- location_id = 1700인 부서 OR location_id = 1800인 부서
- 해당 부서에 속한 사원의 last_name과 salary 반환

UNION이 IN 서브쿼리 안에서 사용 가능하며, 이는 유효한 SQL이다.

---

**[47번] 정답: ② 결과가 항상 동일**

두 SQL 모두 EMPLOYEES와 DEPARTMENTS 양쪽에 존재하는 department_id를 반환한다.  
- SQL P: INTERSECT로 교집합 추출
- SQL Q: JOIN으로 일치하는 행 추출 후 DISTINCT로 중복 제거, IS NOT NULL로 NULL 제외

단, SQL P에서 EMPLOYEES의 department_id에 NULL이 있다면 NULL은 집합 연산에서 자동 제외된다.

---

**[48번] 정답: ① UNION보다 UNION ALL이 빠르므로 중복이 없음이 확실할 때 UNION ALL 선호**

UNION은 중복 제거를 위해 정렬 또는 해시 연산이 필요하지만, UNION ALL은 결과를 그대로 합치므로 더 빠르다.  
두 쿼리 결과에 중복이 없음을 알고 있다면 UNION ALL을 사용하는 것이 성능상 유리하다.

---

**[49번] 정답: ① EMPLOYEES와 JOB_HISTORY를 합한 후 부서 50의 직무를 제거한 고유 직무 목록**

연산 순서 (MINUS > UNION 우선순위 고려, 또는 왼쪽에서 오른쪽):
1. `employees UNION job_history` → 고유 job_id 합집합
2. 결과에서 MINUS → 부서 50 직무 제거

최종: 두 테이블 전체 직무 중 부서 50에서만 사용되는 직무를 제외한 목록.

※ 실제 Oracle에서 집합 연산자는 왼쪽에서 오른쪽으로 처리되므로 괄호로 명시하는 것이 안전하다:
```sql
(SELECT job_id FROM employees UNION SELECT job_id FROM job_history)
MINUS
SELECT job_id FROM employees WHERE department_id = 50;
```

---

**[50번] 정답: ① A: `job_history`, B: `employees`**

```sql
SELECT employee_id FROM job_history
MINUS
SELECT employee_id FROM employees;
```

- JOB_HISTORY에 있는 employee_id: 과거에 근무했던 사원
- EMPLOYEES에 있는 employee_id: 현재 재직 중인 사원
- JOB_HISTORY MINUS EMPLOYEES: 과거에 근무했지만 현재는 없는 사원 = 퇴직 사원

> **주의:** 반대로 하면 (`employees MINUS job_history`) JOB_HISTORY 이력이 없는 현직 사원을 조회하게 됨.
