# Oracle Database 19c: SQL Workshop
## Chapter 16 — 서브쿼리를 이용한 데이터 조회 | 연습문제 모범답안

---

## 하(기초) 모범답안

| 번호 | 정답 | 해설 |
|------|------|------|
| 1 | ③ | FROM 절의 서브쿼리 = 인라인 뷰(Inline View) |
| 2 | ② | 스칼라 서브쿼리 = 정확히 1행 1열 반환 |
| 3 | ③ | GROUP BY 절에서는 스칼라 서브쿼리 사용 불가 |
| 4 | ② | 쌍: 열을 묶어 동시 비교 / 비쌍: 열을 독립 비교 |
| 5 | ② | `(col1, col2) IN (...)` = 쌍 비교 |
| 6 | ② | 상관 서브쿼리: 외부 쿼리 각 행마다 반복 실행 |
| 7 | ② | EXISTS: 서브쿼리에 1행 이상 존재 시 TRUE |
| 8 | ② | NOT EXISTS: 서브쿼리 결과에 없는 행 찾기 |
| 9 | ② | WITH 절: 재사용 가능한 CTE → 가독성·성능 향상 |
| 10 | ② | WITH 절 결과: 사용자의 임시 테이블스페이스에 저장 |
| 11 | ② | EXISTS: 첫 행 발견 후 탐색 중단 → 효율적 |
| 12 | ② | 앵커 멤버: 재귀의 시작점(기본 케이스) |
| 13 | ② | EXISTS는 행 존재만 확인 → 어떤 값이든 무관 |
| 14 | ② | 상관 서브쿼리: 외부 쿼리 테이블의 별칭(alias)으로 참조 |
| 15 | ② | 인라인 뷰: FROM 절 정의, 해당 쿼리 내에서만 유효 |
| 16 | ② | 다중 열 서브쿼리: IN, NOT IN, =, <> 사용 가능 |
| 17 | ② | WITH 절 이름: 해당 쿼리 내에서만 유효한 임시 결과 집합 |
| 18 | ② | UNION ALL: 앵커 멤버와 재귀 멤버 결합 |
| 19 | ② | 스칼라 서브쿼리 0건 → NULL 반환 |
| 20 | ② | NOT EXISTS: NULL 포함 시에도 안전 / NOT IN: NULL 포함 시 0건 반환 위험 |

---

## 중(응용) 모범답안

---

**[21번] 정답: ①**

쌍 비교(Pairwise):
- 비교 조합: `(148, 80)` 또는 `(124, 50)` 중 정확히 일치하는 행만 포함
- `(148, 50)`처럼 섞인 조합은 포함하지 않음

비쌍 비교(Nonpairwise):
- manager_id ∈ {148, 124} **AND** department_id ∈ {80, 50}
- `(148, 50)` 조합도 포함됨 → 더 넓은 결과

---

**[22번] 정답: ②**

상관 서브쿼리는 **외부 쿼리의 각 행**에 대해 실행됨.  
EMPLOYEES 테이블 107행 → 내부 서브쿼리 **107번 실행**.

단, Oracle 옵티마이저가 캐싱이나 해시 등으로 실제 실행 횟수를 줄일 수 있음.

---

**[23번] 정답: ③**

```sql
WHERE EXISTS (SELECT NULL FROM employees WHERE manager_id = outer.employee_id)
```

- 자신의 employee_id를 manager_id로 가진 직원이 존재 = **부하 직원이 있는 직원**
- 즉, 관리자 역할을 하는 직원만 반환

---

**[24번] 정답: ②**

스칼라 서브쿼리가 2행을 반환하면:
```
ORA-01427: single-row subquery returns more than one row
```

스칼라 서브쿼리는 **정확히 1행**만 반환해야 함.  
이 예제에서 하나의 department_id에 여러 부서명이 있을 경우 오류 (실제로는 PK이므로 1행이지만, 설계 결함 시 문제).

---

**[25번] 정답: ②**

`dept_avg` CTE: 부서별 평균 급여 계산  
메인 쿼리: 직원의 급여 > 소속 부서 평균 급여인 행 필터링  
→ **각 부서 평균보다 높은 급여를 받는 직원만 출력**

---

**[26번] 정답: ②**

```sql
WHERE NOT EXISTS (SELECT NULL FROM employees WHERE department_id = d.department_id)
```

해당 부서의 직원이 **없으면** NOT EXISTS = TRUE → 해당 부서 반환  
→ **직원이 한 명도 없는 부서** 목록

---

**[27번] 정답: ①**

인라인 뷰 역할:
- `locations`, `countries`, `regions`를 조인하여 유럽 지역(region_name = 'Europe')의 `location_id`, `city`, `country_id`만 필터링
- 이 결과를 `departments`와 NATURAL JOIN하여 유럽 부서명·도시 반환

---

**[28번] 정답: ②**

```sql
WHERE salary = (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id)
```

- 상관 서브쿼리: 각 직원의 부서에서 최고 급여를 구해 비교
- ③ (`GROUP BY` 서브쿼리 + IN)도 같은 결과를 낼 수 있음

**정답: ②와 ③ 모두 가능하지만, ②가 정석적인 상관 서브쿼리 사용법**

---

**[29번] 정답: ②**

재귀 WITH 절:
- CTE 내부에서 **자기 자신을 참조** (재귀 멤버)
- `UNION ALL`로 앵커 + 재귀 결합
- 계층 구조, 그래프 탐색 등에 활용

---

**[30번] 정답: ①**

CASE 문에서 스칼라 서브쿼리 사용:
```sql
CASE WHEN (SELECT COUNT(*) FROM employees) > 100 THEN 'Big' ELSE 'Small' END
```

②는 IN을 사용한 것으로 스칼라 서브쿼리가 아님.  
③도 유효한 스칼라 서브쿼리 사용법.  
**①과 ③ 모두 올바르지만, 문제 의도상 가장 전형적인 ①이 정답.**

---

**[31번] 정답: ①**

```sql
WITH a AS (...), b AS (...) SELECT ...
```

여러 CTE를 `,`(쉼표)로 구분하여 하나의 `WITH` 키워드 아래 정의.

---

**[32번] 정답: ③**

`(NULL, 80) IN ((NULL, 80), ...)`:
- NULL = NULL → **UNKNOWN** (Oracle에서 NULL 비교는 항상 UNKNOWN)
- UNKNOWN은 FALSE처럼 동작 → 해당 행은 결과에서 **제외**

---

**[33번] 정답: ②**

```sql
-- A: NOT IN
WHERE department_id NOT IN (SELECT department_id FROM employees)
-- employees.department_id에 NULL이 있으면:
-- NOT IN 조건이 dept_id != 10 AND dept_id != 20 AND dept_id != NULL
-- dept_id != NULL → UNKNOWN → 전체 조건 UNKNOWN → 0건 반환

-- B: NOT EXISTS
-- department_id = d.department_id로 NULL 처리 문제 없음 → 올바른 결과
```

**A: 0건 반환, B: 직원 없는 부서 정상 반환**

---

**[34번] 정답: ②**

상관 서브쿼리 성능 향상:
- **내부 서브쿼리에서 참조하는 열에 인덱스 생성** (예: department_id)
- WITH 절로 변환하면 반복 실행 횟수 감소
- JOIN으로 변환도 옵션

---

**[35번] 정답: ②**

```sql
UPDATE employees e
SET    salary = (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id);
```

- SET 절의 스칼라 서브쿼리도 외부 테이블 별칭 참조 가능
- 각 직원의 부서 최대 급여로 salary를 업데이트 (실무에서는 주의 필요)

---

**[36번] 정답: ②**

WITH 절 재사용 이점:
- 정의된 CTE 결과를 임시 저장소에 캐시
- 동일 CTE가 여러 번 참조될 때 **반복 계산 방지**
- 특히 비용이 높은 집계·조인을 한 번만 수행

---

**[37번] 정답: ③**

EXISTS 서브쿼리는 IN 또는 JOIN으로 변환 가능하며 결과가 동일.  
- ①: JOIN 방식
- ②: IN 방식 (서브쿼리)
- 세 가지 모두 같은 결과를 반환할 수 있음

---

**[38번] 정답: ②**

재귀 WITH 무한 루프 방지:
- 재귀 멤버의 **WHERE 조건이 점진적으로 거짓**이 되도록 설계
- 예: `hops < 10` 조건으로 최대 반복 횟수 제한
- Oracle에서는 `CYCLE` 절이나 `MAXDEPTH` 힌트로도 제어 가능

---

**[39번] 정답: ②**

인라인 뷰와 WITH 절 공통점:
- 둘 다 **임시 결과 집합**을 정의
- 해당 쿼리 내에서만 유효 (영구 객체 아님)
- DML, SELECT 모두 사용 가능
- GROUP BY, 집계 함수 포함 가능

차이: WITH 절은 이름을 붙여 여러 번 재사용 가능, 인라인 뷰는 FROM 절에 한 번만 사용

---

**[40번] 정답: ②**

쌍 비교: `(manager_id, department_id) IN ((148, 80))`
- 정확히 `manager_id=148 AND department_id=80`인 행만 포함
- `manager_id=148, department_id=50` → 제외
- `manager_id=100, department_id=80` → 제외

---

## 상(심화) 모범답안

---

**[41번] 정답: ①**

```
sal_stats: 부서별 avg_sal, max_sal, min_sal
above_avg: salary > avg_sal인 직원 (sal_stats JOIN)
최종: above_avg와 sal_stats를 재조인하여 avg_sal, max_sal과 함께 출력
```

결과: **부서 평균 초과 급여를 받는 직원 + 해당 부서의 평균·최대 급여**, 급여 내림차순

- CTE를 여러 번 참조해도 오류 없음 (①의 오답 옵션 ④ 제거)

---

**[42번] 정답: ②**

```
employees.department_id에 NULL 포함: {10, 20, NULL}

NOT IN 쿼리: WHERE department_id NOT IN (10, 20, NULL)
→ dept_id ≠ 10 AND dept_id ≠ 20 AND dept_id ≠ NULL
→ dept_id ≠ NULL → UNKNOWN → 전체 조건 UNKNOWN → 0건 반환

NOT EXISTS 쿼리: WHERE NOT EXISTS (SELECT NULL FROM employees WHERE department_id = d.department_id)
→ NULL이 포함되어도 d.department_id와 NULL 비교 → UNKNOWN (해당 행만 제외)
→ 직원 없는 부서는 정상 반환
```

---

**[43번] 정답: ②**

재귀 WITH 동작:
1. **앵커**: `manager_id IS NULL`인 직원 (최상위, level_n=1)
2. **재귀**: 앵커의 직원을 관리자로 가진 직원 (level_n=2, 3, ...)
3. 반복: 더 이상 부하가 없을 때까지

결과: 전체 조직 계층 구조를 level_n으로 표시하여 출력.

---

**[44번] 정답: ④**

- 기본적으로: employees 107행 × 2개 스칼라 서브쿼리 = 214번 실행
- Oracle의 **스칼라 서브쿼리 캐싱**: 같은 department_id 값이 반복되면 캐싱된 결과 재사용
- 실제 실행 횟수: 고유 department_id 개수 × 2 (캐싱 가정)
- → ①(최대 실행 횟수)과 ③(캐싱 동작) 모두 맞음

---

**[45번] 정답: ②**

```
emp999: manager_id=148, dept_id=50

쌍 비교 조건: (148,80) 또는 (124,50)
- (148, 50) → 해당 조합 없음 → 제외

비쌍 비교 조건: manager_id IN (148,124) AND dept_id IN (80,50)
- manager_id=148 ∈ {148,124} → 만족
- dept_id=50 ∈ {80,50} → 만족
- → 포함
```

→ **쌍 비교: 제외, 비쌍 비교: 포함** (결과 차이 발생)

---

**[46번] 정답: ①**

```
상관 서브쿼리: employees 107행 → AVG(salary) 107번 실행

WITH 절 버전:
1. dept_avg: GROUP BY → 부서별 평균 (최대 27번)
2. JOIN: employees × dept_avg 결합 → 집계는 1번

성능 비교: 107회 vs 1회 집계
→ WITH 절이 훨씬 효율적
```

---

**[47번] 정답: ②**

EXISTS 서브쿼리는 **행이 존재하는지**만 확인 → 반환 값은 무관.  
`SELECT NULL`, `SELECT 1`, `SELECT *`, `SELECT 'x'` 모두 동일한 결과.

관례상 `SELECT NULL`이나 `SELECT 1`을 사용하여 "값은 중요하지 않음"을 명시적으로 표현.

---

**[48번] 정답: ②**

```
regional_depts: 부서+지역 매핑
emp_stats: 부서별 직원수+평균급여
combined: 두 CTE 결합

최종: combined를 region_name으로 GROUP BY
→ 지역별: 부서 수(COUNT), 총 직원 수(SUM), 지역 평균 급여(AVG)
```

**지역별 부서 수, 총 직원 수, 평균 급여** 출력, 평균 급여 내림차순 정렬.

CTE는 개수 제한 없음 (오답 옵션 ④ 제거).

---

**[49번] 정답: ②**

- **스칼라 서브쿼리**: 반환 형태에 관한 개념 (1행 1열)
- **상관 서브쿼리**: 실행 방식에 관한 개념 (외부 쿼리 참조, 반복 실행)

두 개념은 독립적이며 동시에 해당될 수 있음:
```sql
-- 스칼라 + 상관 서브쿼리 (둘 다 해당)
SELECT (SELECT MAX(salary) FROM employees WHERE dept_id = e.dept_id)
FROM employees e;
-- 1행 1열 반환(스칼라) + 외부 쿼리 참조(상관)
```

---

**[50번] 정답: ②**

재귀 WITH 무한 루프 발생 조건:
```
routes에 A→B, B→A가 모두 있다면:
- A→B (hops=1)
- A→B→A (hops=2)
- A→B→A→B (hops=3)
... 무한 반복
```

방지 방법:
```sql
WHERE r.hops < 10   -- 최대 깊이 제한
```

Oracle에서는 `CYCLE` 절을 사용하여 순환 감지:
```sql
WITH ... CYCLE column SET flag TO 'Y' DEFAULT 'N'
```
