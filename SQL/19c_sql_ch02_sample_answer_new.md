# Oracle Database 19c: SQL Workshop
## Chapter 2 — SQL 실습 문제 모범답안

---

## Section A. HR 기본 조회 모범답안 (1~8번)

---

**[1번] 답**

```sql
SELECT employee_id, last_name, job_id
FROM   employees;
```

---

**[2번] 답**

```sql
SELECT DISTINCT job_id
FROM   employees
ORDER BY job_id;
```

---

**[3번] 답**

```sql
SELECT last_name  AS "성명",
       salary     AS "월급",
       salary * 12 AS "연봉"
FROM   employees;
```

---

**[4번] 답**

```sql
SELECT first_name || ' ' || last_name AS "사원명",
       job_id  AS "직무",
       salary  AS "기본급"
FROM   employees;
```

---

**[5번] 답**

```sql
SELECT last_name || ' 은(는) ' || job_id || ' 직무입니다.' AS "사원 정보"
FROM   employees;
```

---

**[6번] 답**

```sql
SELECT department_name || q'[ Department's Manager: ]' || manager_id
       AS "부서 및 매니저 정보"
FROM   departments;
```

---

**[7번] 답**

```sql
SELECT job_id,
       job_title,
       min_salary,
       max_salary,
       max_salary - min_salary AS "급여범위"
FROM   jobs
ORDER BY job_id;
```

---

**[8번] 답**

```sql
SELECT SYSDATE                    AS "오늘날짜",
       'Oracle 19c SQL Workshop'  AS "강의명",
       100 * 365                  AS "계산결과"
FROM   dual;
```

---

## Section B. 판매 데이터 분석 모범답안 (9~18번)

---

**[9번] 답**

```sql
SELECT COALESCE(k.saledate, j.saledate)  AS "SALEDATE",
       NVL(k.qty, 0)                     AS "한국",
       NVL(j.qty, 0)                     AS "일본",
       NVL(k.qty, 0) + NVL(j.qty, 0)    AS "합계"
FROM   kr_sales k
       FULL OUTER JOIN jp_sales j
       ON k.saledate = j.saledate
ORDER BY 1;
```

> **해설:** `FULL OUTER JOIN`은 양쪽 테이블에 있는 모든 날짜를 포함한다.  
> 한쪽에만 있는 날짜는 상대방 테이블의 qty가 NULL이 되므로 `NVL(qty, 0)`으로 0 처리한다.  
> `COALESCE(k.saledate, j.saledate)`는 두 날짜 중 NULL이 아닌 값을 선택한다.

---

**[10번] 답**

```sql
SELECT COALESCE(k.saledate, j.saledate)              AS "SALEDATE",
       NVL(k.qty, 0)                                 AS "한국",
       NVL(j.qty, 0)                                 AS "일본",
       NVL(k.qty, 0) + NVL(j.qty, 0)                AS "합계",
       SUM(NVL(k.qty, 0) + NVL(j.qty, 0))
           OVER (ORDER BY COALESCE(k.saledate, j.saledate))
                                                     AS "누적합계"
FROM   kr_sales k
       FULL OUTER JOIN jp_sales j
       ON k.saledate = j.saledate
ORDER BY 1;
```

> **해설:** `SUM(...) OVER (ORDER BY ...)` — 분석 함수(Window Function).  
> ORDER BY를 지정하면 첫 행부터 현재 행까지의 누적 합계를 계산한다.

---

**[11번] 답**

```sql
SELECT COALESCE(k.saledate, j.saledate)              AS "SALEDATE",
       NVL(k.qty, 0)                                 AS "한국",
       NVL(j.qty, 0)                                 AS "일본",
       NVL(k.qty, 0) + NVL(j.qty, 0)                AS "합계",
       (NVL(k.qty, 0) + NVL(j.qty, 0))
       - LAG(NVL(k.qty, 0) + NVL(j.qty, 0))
           OVER (ORDER BY COALESCE(k.saledate, j.saledate))
                                                     AS "전일대비"
FROM   kr_sales k
       FULL OUTER JOIN jp_sales j
       ON k.saledate = j.saledate
ORDER BY 1;
```

> **해설:** `LAG(열) OVER (ORDER BY ...)` — 현재 행 기준 이전 행의 값을 반환한다.  
> 첫 번째 행은 이전 행이 없으므로 NULL이 반환된다.

---

**[12번] 답**

```sql
WITH base AS (
    SELECT COALESCE(k.saledate, j.saledate)              AS saledate,
           NVL(k.qty, 0)                                 AS kr,
           NVL(j.qty, 0)                                 AS jp,
           NVL(k.qty, 0) + NVL(j.qty, 0)                AS total
    FROM   kr_sales k
           FULL OUTER JOIN jp_sales j
           ON k.saledate = j.saledate
)
SELECT saledate   AS "SALEDATE",
       kr         AS "한국",
       jp         AS "일본",
       total      AS "합계",
       total - LAG(total) OVER (ORDER BY saledate)  AS "전일대비",
       CASE
           WHEN LAG(total) OVER (ORDER BY saledate) IS NULL
               THEN '(없음)'
           WHEN total > LAG(total) OVER (ORDER BY saledate)
               THEN '상승'
           WHEN total = LAG(total) OVER (ORDER BY saledate)
               THEN '보합'
           ELSE '하락'
       END  AS "추세"
FROM   base
ORDER BY saledate;
```

> **해설:** `WITH` 절(CTE)로 기본 집합을 먼저 정의하면 복잡한 분석 함수를 중복 없이 사용할 수 있다.  
> `CASE WHEN ... THEN ... ELSE ... END` — 조건별 값을 반환하는 Oracle 조건 표현식.

---

**[13번] 답**

```sql
SELECT '한국'         AS "구분",
       SUM(qty)       AS "총판매량",
       COUNT(*)       AS "일수",
       ROUND(AVG(qty), 1) AS "일평균판매량"
FROM   kr_sales
UNION ALL
SELECT '일본',
       SUM(qty),
       COUNT(*),
       ROUND(AVG(qty), 1)
FROM   jp_sales;
```

---

**[14번] 답**

```sql
SELECT k.saledate               AS "SALEDATE",
       k.qty                    AS "한국",
       NVL(j.qty, 0)           AS "일본",
       k.qty - NVL(j.qty, 0)  AS "차이"
FROM   kr_sales k
       LEFT OUTER JOIN jp_sales j
       ON k.saledate = j.saledate
WHERE  k.qty > NVL(j.qty, 0)
ORDER BY k.saledate;
```

---

**[15번] 답**

```sql
SELECT k.saledate                AS "SALEDATE",
       k.qty                     AS "한국",
       j.qty                     AS "일본",
       k.qty + j.qty             AS "합계"
FROM   kr_sales k
       INNER JOIN jp_sales j
       ON k.saledate = j.saledate
ORDER BY (k.qty + j.qty) DESC;
```

> **해설:** `INNER JOIN`은 양쪽 테이블에 모두 존재하는 날짜만 반환한다.

---

**[16번] 답**

```sql
SELECT saledate AS "SALEDATE",
       '한국'   AS "국가",
       qty      AS "QTY"
FROM   kr_sales
UNION ALL
SELECT saledate,
       '일본',
       qty
FROM   jp_sales
ORDER BY saledate, 국가;
```

> **해설:** `UNION ALL`은 중복을 제거하지 않고 두 결과를 위아래로 합친다.

---

**[17번] 답**

```sql
SELECT TO_CHAR(k.saledate, 'YYYY-MM') AS "연월",
       SUM(k.qty)                      AS "한국_합계",
       SUM(j.qty)                      AS "일본_합계",
       SUM(k.qty) + SUM(j.qty)        AS "전체합계"
FROM   kr_sales k
       FULL OUTER JOIN jp_sales j ON k.saledate = j.saledate
GROUP BY TO_CHAR(k.saledate, 'YYYY-MM');
```

---

**[18번] 답**

```sql
-- 방법 1: FULL OUTER JOIN + NULL 조건
SELECT COALESCE(k.saledate, j.saledate) AS "SALEDATE",
       NVL(k.qty, 0)                    AS "한국",
       NVL(j.qty, 0)                    AS "일본"
FROM   kr_sales k
       FULL OUTER JOIN jp_sales j
       ON k.saledate = j.saledate
WHERE  k.saledate IS NULL
   OR  j.saledate IS NULL
ORDER BY 1;

-- 방법 2: MINUS / EXCEPT 활용
SELECT saledate FROM kr_sales
MINUS
SELECT saledate FROM jp_sales;  -- kr_sales에만 있는 날짜
-- (jp_sales에만 있는 날짜는 반대로)
```

---

## Section C. 조직 계층 조회 모범답안 (19~26번)

---

**[19번] 답**

```sql
SELECT no, name, manager, submgr
FROM   service
ORDER BY no;
```

---

**[20번] 답**

```sql
SELECT s.no,
       s.name,
       s.manager          AS "관리자번호",
       e.first_name       AS "관리자이름"
FROM   service    s
       JOIN employees e
       ON s.manager = e.employee_id
ORDER BY s.no;
```

---

**[21번] 답**

```sql
SELECT s.no,
       s.name,
       s.manager                AS "관리자번호",
       e1.first_name            AS "관리자이름",
       s.submgr                 AS "부관리자번호",
       e2.first_name            AS "부관리자이름"
FROM   service    s
       JOIN      employees e1 ON s.manager = e1.employee_id
       LEFT JOIN employees e2 ON s.submgr  = e2.employee_id
ORDER BY s.no;
```

> **해설:** 부관리자가 없는 행(submgr = NULL)도 포함하기 위해  
> 부관리자 조인은 `LEFT JOIN`을 사용한다.

---

**[22번] 답**

```sql
-- 데이터 추가 후 동일한 쿼리 재실행
INSERT INTO service VALUES (11, '시스템11', 121, 122);
COMMIT;

SELECT s.no,
       s.name,
       s.manager                AS "관리자번호",
       e1.first_name            AS "관리자이름",
       s.submgr                 AS "부관리자번호",
       e2.first_name            AS "부관리자이름"
FROM   service    s
       JOIN      employees e1 ON s.manager = e1.employee_id
       LEFT JOIN employees e2 ON s.submgr  = e2.employee_id
ORDER BY s.no;
```

> **해설:** 21번과 동일한 SQL이지만 데이터가 추가되었으므로 11번 행이 자동으로 포함된다.

---

**[23번] 답**

```sql
SELECT s.no,
       s.name,
       s.manager          AS "관리자번호",
       e.first_name       AS "관리자이름"
FROM   service    s
       JOIN employees e ON s.manager = e.employee_id
WHERE  s.submgr IS NULL
ORDER BY s.no;
```

---

**[24번] 답**

```sql
SELECT e.employee_id                           AS "사원번호",
       e.first_name || ' ' || e.last_name      AS "사원이름",
       m.employee_id                           AS "관리자번호",
       NVL(m.first_name || ' ' || m.last_name, '(없음)') AS "관리자이름"
FROM   employees e
       LEFT JOIN employees m
       ON e.manager_id = m.employee_id
ORDER BY e.employee_id;
```

> **해설:** EMPLOYEES 테이블을 두 번 참조하는 **셀프 조인(Self Join)**.  
> `e`는 사원, `m`은 관리자 역할로 별칭을 달리하여 구분한다.  
> Steven King은 manager_id = NULL이므로 `LEFT JOIN`으로 포함한다.

---

**[25번] 답**

```sql
SELECT s.no,
       s.name,
       e1.first_name              AS "관리자이름",
       e1.department_id           AS "관리자부서",
       e2.first_name              AS "부관리자이름",
       e2.department_id           AS "부관리자부서"
FROM   service    s
       JOIN      employees e1 ON s.manager = e1.employee_id
       JOIN      employees e2 ON s.submgr  = e2.employee_id
WHERE  e1.department_id = e2.department_id
ORDER BY s.no;
```

> **해설:** 부관리자가 없는 행은 INNER JOIN으로 자동 제외된다.  
> `WHERE e1.department_id = e2.department_id`로 같은 부서 조건 필터링.

---

**[26번] 답**

```sql
SELECT s.no,
       s.name,
       s.manager                  AS "관리자번호",
       e1.first_name              AS "관리자이름",
       s.submgr1                  AS "부관리자1번호",
       e2.first_name              AS "부관리자1이름",
       s.submgr2                  AS "부관리자2번호",
       e3.first_name              AS "부관리자2이름"
FROM   service    s
       JOIN      employees e1 ON s.manager = e1.employee_id
       LEFT JOIN employees e2 ON s.submgr1 = e2.employee_id
       LEFT JOIN employees e3 ON s.submgr2 = e3.employee_id
ORDER BY s.no;
```

> **해설:** 부관리자1과 부관리자2 모두 NULL 가능이므로 `LEFT JOIN` 사용.  
> EMPLOYEES 테이블을 3번 참조 — 각각 다른 별칭(e1, e2, e3)으로 구분.

---

## Section D. HR 종합 분석 모범답안 (27~30번)

---

**[27번] 답**

```sql
SELECT department_id,
       COUNT(*) AS "사원수"
FROM   employees
GROUP BY department_id
ORDER BY department_id NULLS LAST;
```

> **해설:** `GROUP BY department_id`로 부서별 그룹을 만들어 `COUNT(*)`로 사원 수를 집계한다.  
> `NULLS LAST`는 NULL 값(부서 미배정 사원)을 맨 마지막에 표시한다.

---

**[28번] 답**

```sql
SELECT d.department_name    AS "부서명",
       COUNT(e.employee_id) AS "사원수",
       ROUND(AVG(e.salary)) AS "평균급여"
FROM   departments d
       JOIN employees e
       ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY d.department_name;
```

> **해설:** DEPARTMENTS와 EMPLOYEES를 `JOIN`하여 부서별로 집계한다.  
> `ROUND(AVG(salary))`로 소수 첫째 자리에서 반올림한다.

---

**[29번] 답**

```sql
SELECT jh.employee_id,
       e.first_name || ' ' || e.last_name AS "사원명",
       COUNT(*)                           AS "직무변경횟수"
FROM   job_history jh
       JOIN employees e
       ON jh.employee_id = e.employee_id
GROUP BY jh.employee_id,
         e.first_name || ' ' || e.last_name
HAVING COUNT(*) >= 2
ORDER BY COUNT(*) DESC;
```

> **해설:** `JOB_HISTORY` 테이블은 직무 변경 이력을 저장한다.  
> `HAVING COUNT(*) >= 2` — 집계 후 조건 필터링 (WHERE는 집계 전, HAVING은 집계 후).

---

**[30번] 답**

```sql
SELECT e.job_id,
       j.job_title              AS "직무명",
       COUNT(e.employee_id)     AS "사원수",
       MIN(e.salary)            AS "최저급여",
       MAX(e.salary)            AS "최고급여"
FROM   employees e
       JOIN jobs j ON e.job_id = j.job_id
GROUP BY e.job_id, j.job_title
HAVING COUNT(e.employee_id) >= 3
ORDER BY COUNT(e.employee_id) DESC;
```

> **해설:**  
> - `JOBS` 테이블을 JOIN하여 직무명(job_title)을 가져온다.  
> - `HAVING COUNT(...) >= 3` — 그룹화 후 사원 수가 3명 이상인 직무만 필터링한다.  
> - `MIN/MAX(salary)` — 각 직무의 실제 급여 범위를 계산한다.
