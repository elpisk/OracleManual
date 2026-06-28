# Oracle Database 19c: SQL Workshop
## Chapter 19 — 고급 쿼리를 이용한 데이터 조작 | 연습문제

> 총 50문제 (하 20문제 / 중 20문제 / 상 10문제)

---

## 하(기초) — 20문제

**[1번]** INSERT 문에서 열에 정의된 기본값을 명시적으로 삽입하려고 할 때 사용하는 키워드는?

① NULL  
② EMPTY  
③ DEFAULT  
④ AUTO

---

**[2번]** UPDATE 문에서 `salary = DEFAULT`를 실행했을 때의 동작으로 올바른 것은?

① 항상 salary를 0으로 설정한다  
② 열에 정의된 DEFAULT 값으로 salary를 변경한다  
③ salary 열을 삭제한다  
④ 오류가 발생한다

---

**[3번]** 다중 테이블 INSERT에서 조건 없이 모든 INTO 절에 행을 삽입하는 구문은?

① INSERT FIRST  
② INSERT MERGE  
③ INSERT ALL  
④ INSERT ANY

---

**[4번]** 다음 중 다중 테이블 INSERT 구문의 기본 구조에 포함되지 않는 절은?

① INTO  
② FROM  
③ WHEN  
④ JOIN

---

**[5번]** Conditional INSERT ALL에서 한 행이 여러 WHEN 조건을 모두 만족하면 어떻게 되는가?

① 첫 번째 조건의 테이블에만 삽입된다  
② 오류가 발생한다  
③ 조건을 만족하는 모든 테이블에 삽입된다  
④ 마지막 조건의 테이블에만 삽입된다

---

**[6번]** Conditional INSERT FIRST에서 한 행이 첫 번째 WHEN 조건을 만족하면 어떻게 되는가?

① 모든 WHEN 조건을 계속 평가한다  
② 첫 번째 조건의 INTO 절에 삽입하고 나머지 조건 평가를 중단한다  
③ 마지막 WHEN 조건의 테이블에도 삽입된다  
④ ELSE 절에도 삽입된다

---

**[7번]** Pivoting INSERT의 주된 목적은?

① 테이블 구조를 변경한다  
② 여러 행을 하나의 열로 집계한다  
③ 열 기반(가로) 데이터를 행 기반(세로) 데이터로 변환하여 삽입한다  
④ 중복 행을 제거하고 삽입한다

---

**[8번]** MERGE 문에서 소스와 대상을 연결하는 키워드는?

① WHERE  
② JOIN  
③ ON  
④ USING과 ON

---

**[9번]** MERGE 문에서 소스에는 있지만 대상에 없는 행을 처리하는 절은?

① WHEN MATCHED THEN INSERT  
② WHEN NOT MATCHED THEN INSERT  
③ WHEN MISSING THEN INSERT  
④ WHEN NULL THEN INSERT

---

**[10번]** MERGE 문에서 대상에 이미 존재하는 행을 갱신하는 절은?

① WHEN NOT MATCHED THEN UPDATE  
② WHEN EXISTS THEN UPDATE  
③ WHEN MATCHED THEN UPDATE  
④ WHEN FOUND THEN UPDATE

---

**[11번]** FLASHBACK TABLE 명령어의 주된 용도는?

① 테이블 구조를 이전 버전으로 변경한다  
② 테이블 데이터를 특정 과거 시점으로 복구한다  
③ 삭제된 열을 복구한다  
④ 테이블 이름을 변경한다

---

**[12번]** DROP TABLE 후 RECYCLEBIN에 있는 테이블을 복구하는 구문으로 올바른 것은?

① `FLASHBACK TABLE emp TO UNDO;`  
② `FLASHBACK TABLE emp TO BEFORE DROP;`  
③ `RESTORE TABLE emp FROM RECYCLEBIN;`  
④ `RECOVER TABLE emp BEFORE DROP;`

---

**[13번]** Flashback Query에서 특정 시점의 과거 데이터를 조회하는 키워드 조합은?

① FROM ... WHERE  
② SELECT ... BETWEEN  
③ AS OF TIMESTAMP  
④ PRIOR TO TIMESTAMP

---

**[14번]** `SYSTIMESTAMP - INTERVAL '1' MINUTE`의 의미는?

① 현재 시각에서 1초를 뺀 값  
② 현재 타임스탬프에서 1분을 뺀 값  
③ 시스템 시작 후 1분 경과한 값  
④ 1분 뒤의 타임스탬프

---

**[15번]** Flashback Version Query에서 사용하는 절은?

① AS OF SCN  
② VERSIONS BETWEEN SCN  
③ HISTORY BETWEEN  
④ ARCHIVE BETWEEN SCN

---

**[16번]** `VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE`에서 MINVALUE와 MAXVALUE의 의미는?

① 테이블의 최소·최대 기본 키 값 범위  
② UNDO에서 가용한 가장 오래된 SCN부터 가장 최신 SCN까지  
③ 트랜잭션 ID의 최솟값과 최댓값  
④ 세션이 시작된 SCN과 현재 SCN

---

**[17번]** FLASHBACK TABLE을 TIMESTAMP 기반으로 복구하기 전에 반드시 활성화해야 하는 테이블 옵션은?

① ENABLE MOVEMENT  
② ENABLE ROW MOVEMENT  
③ ENABLE FLASHBACK  
④ ENABLE UNDO RETENTION

---

**[18번]** MERGE 문에서 조건이 일치하는 행에 UPDATE와 동시에 특정 조건을 만족하는 행을 삭제하는 절은?

① DELETE WHERE  
② UPDATE DELETE WHERE  
③ WHEN MATCHED THEN DELETE  
④ UPDATE ... DELETE WHERE (WHEN MATCHED THEN 절 내에서)

---

**[19번]** 다중 테이블 INSERT에서 ELSE 절이 동작하는 조건은?

① 모든 WHEN 조건을 만족할 때  
② 어떤 WHEN 조건도 만족하지 않을 때  
③ 첫 번째 WHEN 조건만 만족할 때  
④ INTO 절이 없을 때

---

**[20번]** RECYCLEBIN 뷰에서 삭제된 테이블 정보를 조회할 때 사용하는 열로 올바른 것은?

① table_name  
② deleted_name  
③ original_name  
④ drop_name

---

## 중(응용) — 20문제

**[21번]** 다음 SQL의 결과로 올바른 것은?

```sql
CREATE TABLE dept2 (
    dept_id   NUMBER DEFAULT 100,
    dept_name VARCHAR2(50)
);
INSERT INTO dept2 (dept_name) VALUES ('Accounting');
SELECT dept_id FROM dept2;
```

① NULL  
② 0  
③ 100  
④ ORA-01400 오류 (NOT NULL 위반)

---

**[22번]** 아래 SQL에서 `INSERT ALL`을 실행하면 sal_history에 삽입되는 행 수는? (employees에서 조건에 맞는 행이 5행이라 가정)

```sql
INSERT ALL
    INTO sal_history VALUES (empid, hiredate, sal)
    INTO mgr_history VALUES (empid, mgr, sal)
SELECT employee_id empid, hire_date hiredate,
       salary sal, manager_id mgr
FROM   employees
WHERE  employee_id > 200;
```

① 0행  
② 5행  
③ 10행  
④ 소스 테이블 전체 행 수

---

**[23번]** 다음 중 INSERT FIRST와 INSERT ALL의 차이에 대한 설명으로 올바른 것은?

① INSERT FIRST는 조건이 없어도 사용 가능하다  
② INSERT ALL은 WHEN 조건을 순서대로 평가하여 첫 번째 조건 만족 시 중단한다  
③ INSERT FIRST는 한 행이 여러 조건을 만족해도 하나의 테이블에만 삽입된다  
④ INSERT ALL과 INSERT FIRST는 결과가 항상 동일하다

---

**[24번]** 아래 Conditional INSERT ALL에서 급여가 4,500이고 커미션이 있는 직원은 어느 테이블에 삽입되는가?

```sql
INSERT ALL
    WHEN salary < 5000 THEN
        INTO low_sal VALUES (employee_id, salary)
    WHEN commission_pct IS NOT NULL THEN
        INTO comm_emp VALUES (employee_id, commission_pct)
SELECT employee_id, salary, commission_pct
FROM   employees;
```

① low_sal에만 삽입  
② comm_emp에만 삽입  
③ low_sal과 comm_emp 두 테이블 모두 삽입  
④ 어디에도 삽입되지 않음

---

**[25번]** 동일한 조건에서 INSERT FIRST를 사용하면 급여가 4,500이고 커미션이 있는 직원은?

```sql
INSERT FIRST
    WHEN salary < 5000 THEN
        INTO low_sal VALUES (employee_id, salary)
    WHEN commission_pct IS NOT NULL THEN
        INTO comm_emp VALUES (employee_id, commission_pct)
SELECT employee_id, salary, commission_pct
FROM   employees;
```

① low_sal과 comm_emp 모두 삽입  
② low_sal에만 삽입  
③ comm_emp에만 삽입  
④ 어디에도 삽입되지 않음

---

**[26번]** Pivoting INSERT의 소스 데이터가 다음과 같을 때, sales_info 테이블에 삽입되는 총 행 수는?

```
소스 1행: emp_id=1, week=1, mon=100, tue=200, wed=300, thur=400, fri=500
소스 2행: emp_id=2, week=1, mon=150, tue=250, wed=350, thur=450, fri=550
```

① 2행  
② 5행  
③ 10행  
④ 25행

---

**[27번]** MERGE 문에서 `ON` 절의 역할은?

① 대상 테이블의 기본 키를 지정한다  
② 소스와 대상 행을 연결하는 조인 조건을 지정한다  
③ 업데이트할 열 목록을 지정한다  
④ 병합 후 커밋을 자동으로 수행한다

---

**[28번]** 다음 MERGE 구문에서 copy_emp에 이미 employee_id = 100인 행이 있을 때 수행되는 작업은?

```sql
MERGE INTO copy_emp c
USING employees e
ON (c.employee_id = e.employee_id)
WHEN MATCHED THEN
    UPDATE SET c.salary = e.salary
WHEN NOT MATCHED THEN
    INSERT VALUES (e.employee_id, e.last_name, e.salary);
```

① 새 행이 삽입된다  
② c.salary가 e.salary로 업데이트된다  
③ 오류가 발생한다  
④ 아무 작업도 수행되지 않는다

---

**[29번]** MERGE 문의 WHEN MATCHED THEN 절에서 DELETE WHERE를 추가할 때 삭제 기준은?

① ON 절의 조인 조건  
② WHEN MATCHED THEN 이후에 별도로 지정하는 WHERE 조건  
③ 소스 테이블의 PRIMARY KEY  
④ UPDATE SET 조건

---

**[30번]** 다음 Flashback Query가 조회하는 데이터는?

```sql
SELECT salary FROM employees
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '30' MINUTE)
WHERE employee_id = 100;
```

① 현재 시각 기준 30분 뒤의 salary  
② 현재 시각 기준 30분 전의 salary  
③ 30행의 salary  
④ employee_id가 30인 salary

---

**[31번]** FLASHBACK TABLE을 사용하기 위한 전제 조건으로 올바른 것은? (TIMESTAMP 복구 시)

① 테이블에 FLASHBACK ENABLE 옵션이 설정되어 있어야 한다  
② `ALTER TABLE ... ENABLE ROW MOVEMENT`를 실행해야 한다  
③ DBA 권한이 없어도 누구나 사용할 수 있다  
④ UNDO 데이터가 필요 없다

---

**[32번]** Flashback Version Query에서 특정 행의 변경 이력을 조회할 때 사용하는 의사 컬럼(Pseudo column)을 두 가지 모두 포함하는 것은?

① versions_rowid, versions_scn  
② versions_starttime, versions_endtime  
③ versions_timestamp, versions_commit  
④ start_scn, end_scn

---

**[33번]** DROP TABLE 후 RECYCLEBIN 내용을 확인하는 뷰는?

① dba_dropped_objects  
② all_recyclebin  
③ user_recyclebin 또는 recyclebin  
④ dropped_tables

---

**[34번]** 다음 중 MERGE 문의 장점으로 올바르지 않은 것은?

① 하나의 명령으로 INSERT와 UPDATE를 동시 처리한다  
② 소스 데이터를 한 번만 읽어 효율적이다  
③ ROLLBACK이 불가능하다  
④ 데이터 웨어하우스 ETL 작업에 유용하다

---

**[35번]** 다음 SQL의 실행 결과는?

```sql
INSERT FIRST
    WHEN salary < 10000 THEN
        INTO low_sal VALUES (employee_id, salary)
    WHEN salary < 15000 THEN
        INTO mid_sal VALUES (employee_id, salary)
    ELSE
        INTO high_sal VALUES (employee_id, salary)
SELECT employee_id, salary FROM employees WHERE employee_id = 100;
-- employee_id = 100의 salary = 24000
```

① low_sal에 삽입  
② mid_sal에 삽입  
③ high_sal에 삽입  
④ low_sal과 high_sal 두 곳에 삽입

---

**[36번]** MERGE 문에서 WHEN NOT MATCHED THEN 절에 WHERE 조건을 추가할 수 있는가?

① 불가능하다  
② WHEN NOT MATCHED THEN INSERT ... WHERE 형태로 삽입 필터를 추가할 수 있다  
③ WHERE 대신 HAVING을 사용해야 한다  
④ Oracle 12c 이상에서만 가능하다

---

**[37번]** 다음 중 Flashback 기능을 지원하는 저장 영역은?

① REDO LOG  
② UNDO TABLESPACE  
③ SYSAUX 테이블스페이스  
④ TEMP 테이블스페이스

---

**[38번]** `VERSIONS BETWEEN TIMESTAMP t1 AND t2` 구문에서 조회되는 데이터의 범위는?

① t1 시각에 커밋된 버전만  
② t1에서 t2 사이에 존재했던 모든 버전  
③ t2 시각에 존재하는 현재 버전만  
④ t1과 t2 사이에 삭제된 행만

---

**[39번]** DEFAULT 키워드 사용 시 열에 DEFAULT 값이 정의되지 않은 경우 어떤 값이 적용되는가?

① 0  
② -1  
③ NULL  
④ 오류 발생

---

**[40번]** Unconditional INSERT ALL에서 소스 테이블에서 3행을 읽어 2개 테이블에 INSERT ALL을 실행하면 총 삽입 행 수는?

① 3행  
② 6행  
③ 5행  
④ 소스 행 수에 관계없이 항상 INTO 절 수만큼

---

## 상(심화) — 10문제

**[41번]** 다음 시나리오에서 MERGE 문 실행 후 copy_dept의 상태를 올바르게 설명한 것은?

```sql
-- copy_dept: department_id = 10 (Budget=500), 20 (Budget=800)
-- departments:  department_id = 10 (Budget=1000), 30 (Budget=1500)

MERGE INTO copy_dept cd
USING departments d
ON (cd.department_id = d.department_id)
WHEN MATCHED THEN
    UPDATE SET cd.budget = d.budget
    DELETE WHERE cd.budget > 900
WHEN NOT MATCHED THEN
    INSERT VALUES (d.department_id, d.budget);
```

① copy_dept에 10, 20, 30 행이 모두 존재한다  
② copy_dept에 20, 30 행만 존재한다  
③ copy_dept에 10, 30 행만 존재한다  
④ copy_dept에 30 행만 존재한다

---

**[42번]** 아래 MERGE 구문에 대한 설명으로 가장 올바른 것은?

```sql
MERGE INTO target t
USING source s
ON (t.id = s.id)
WHEN MATCHED THEN
    UPDATE SET t.val = s.val
    DELETE WHERE s.status = 'INACTIVE'
WHEN NOT MATCHED THEN
    INSERT (id, val) VALUES (s.id, s.val)
    WHERE s.status = 'ACTIVE';
```

① WHEN NOT MATCHED THEN INSERT에 WHERE는 문법 오류이다  
② 상태가 ACTIVE인 새 행만 삽입되고, 기존 행 중 s.status가 INACTIVE인 것은 업데이트 후 삭제된다  
③ DELETE WHERE는 WHEN NOT MATCHED 절에서도 사용 가능하다  
④ WHEN NOT MATCHED THEN INSERT에 WHERE는 Oracle에서 지원되지 않는다

---

**[43번]** 다음 시나리오에서 Flashback Version Query로 조회 가능한 데이터의 제한은?

```
09:00 — employees3 생성, salary=5000 for emp_id=1 (SCN: 1000)
09:10 — UPDATE salary=6000 (SCN: 2000)
09:20 — UPDATE salary=7000 (SCN: 3000)
09:30 — UNDO_RETENTION 설정으로 SCN 1000 이전 UNDO 삭제됨
```

```sql
SELECT salary FROM employees3
VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE
WHERE employee_id = 1;
```

① salary = 5000, 6000, 7000 모두 조회 가능  
② salary = 7000 (현재 값)만 조회 가능  
③ UNDO가 삭제된 SCN 1000 이전 버전(5000)은 조회 불가  
④ FLASHBACK 기능이 비활성화되어 오류 발생

---

**[44번]** 아래와 같은 상황에서 FLASHBACK TABLE을 사용할 수 없는 이유를 올바르게 설명한 것은?

```sql
-- 실행 순서:
DROP TABLE emp3;
PURGE RECYCLEBIN;
FLASHBACK TABLE emp3 TO BEFORE DROP;  -- 오류 발생
```

① ROW MOVEMENT가 비활성화되어 있기 때문이다  
② PURGE RECYCLEBIN으로 RECYCLEBIN에서 삭제됐기 때문이다  
③ emp3에 FK 참조 제약이 있기 때문이다  
④ UNDO 데이터가 만료되었기 때문이다

---

**[45번]** 다음 Pivoting INSERT를 설계할 때, 소스에 NULL인 요일 데이터가 포함된 경우 어떻게 처리해야 하는가?

```sql
INSERT ALL
    INTO sales_info VALUES (emp_id, week_id, sales_mon)
    INTO sales_info VALUES (emp_id, week_id, sales_tue)
    ...
SELECT emp_id, week_id, sales_mon, sales_tue ...
FROM sales_source;
```

① NULL 값이 있으면 Pivoting INSERT 자체가 실패한다  
② NULL 값이 있는 열의 행은 자동으로 건너뛴다  
③ NULL 값도 그대로 sales_info에 삽입되며, 필요 시 WHEN 조건을 추가하여 NULL 행 제외 가능하다  
④ Pivoting INSERT는 반드시 NOT NULL 열에만 사용해야 한다

---

**[46번]** 다음 SQL의 실행 결과 행 수는? (employees 테이블에 총 107명, 그 중 salary > 10000인 직원 = 8명, salary BETWEEN 5000 AND 10000 = 40명, 나머지 = 59명)

```sql
INSERT FIRST
    WHEN salary > 10000 THEN
        INTO high_sal VALUES (employee_id, salary)
    WHEN salary BETWEEN 5000 AND 10000 THEN
        INTO mid_sal VALUES (employee_id, salary)
    ELSE
        INTO low_sal VALUES (employee_id, salary)
SELECT employee_id, salary FROM employees;
```

최종적으로 high_sal, mid_sal, low_sal 세 테이블에 삽입된 총 행 수는?

① 107행  
② 214행  
③ 59행만 low_sal에 삽입  
④ 214행 + 59행 = 273행

---

**[47번]** 다음 MERGE 구문의 문제점은?

```sql
MERGE INTO copy_emp c
USING employees e
ON (c.employee_id = e.employee_id)
WHEN MATCHED THEN
    UPDATE SET c.employee_id = e.employee_id + 1;
```

① ON 절의 조인 컬럼(c.employee_id)을 UPDATE SET에서 수정하면 ORA-38104 오류 발생  
② WHEN NOT MATCHED 절이 없어서 실행 불가  
③ USING 절에서 서브쿼리를 사용해야 한다  
④ employee_id + 1은 산술 오류이다

---

**[48번]** Flashback Database와 FLASHBACK TABLE의 가장 큰 차이점은?

① Flashback Database는 테이블 단위, FLASHBACK TABLE은 데이터베이스 전체에 적용된다  
② Flashback Database는 데이터베이스 전체를 과거 시점으로 복구하며 FLASHBACK LOGS가 필요하고, FLASHBACK TABLE은 테이블 단위로 UNDO 데이터를 사용한다  
③ 두 기능은 동일하며 명칭만 다르다  
④ FLASHBACK TABLE은 ARCHIVELOG 모드에서만 사용 가능하다

---

**[49번]** 아래의 다중 테이블 INSERT에서 employees 소스를 추가 조인 없이 한 번만 읽어 3개 테이블에 각기 다른 기간의 직원을 삽입하려고 한다. FIRST와 ALL 중 어느 키워드가 올바르며, 그 이유는?

```sql
INSERT [?]
    WHEN hire_date < DATE '2000-01-01' THEN
        INTO emp_pre2000 VALUES (employee_id, last_name, hire_date)
    WHEN hire_date BETWEEN DATE '2000-01-01' AND DATE '2009-12-31' THEN
        INTO emp_2000s VALUES (employee_id, last_name, hire_date)
    WHEN hire_date >= DATE '2010-01-01' THEN
        INTO emp_2010plus VALUES (employee_id, last_name, hire_date)
SELECT employee_id, last_name, hire_date FROM employees;
```

① ALL — 한 직원이 세 테이블 모두에 삽입될 수 있으므로  
② FIRST — 입사일은 하나이므로 세 조건이 상호 배타적이며, 첫 번째 만족 조건에만 삽입하는 것이 안전  
③ 두 키워드 모두 동일한 결과를 반환하므로 차이 없음  
④ ALL을 사용해야 중복 삽입을 방지할 수 있다

---

**[50번]** 다음은 MERGE 이후 롤백 시나리오이다. 트랜잭션 관점에서 올바른 설명은?

```sql
-- T1
MERGE INTO copy_emp c
USING employees e
ON (c.employee_id = e.employee_id)
WHEN MATCHED THEN UPDATE SET c.salary = e.salary * 2
WHEN NOT MATCHED THEN INSERT VALUES (e.employee_id, e.salary);

-- T2
ROLLBACK;
```

① MERGE 문의 INSERT 부분만 롤백되고 UPDATE는 유지된다  
② ROLLBACK을 실행하면 MERGE 전체(INSERT + UPDATE)가 모두 롤백된다  
③ MERGE는 DDL이므로 AUTO COMMIT되어 롤백 불가  
④ UPDATE된 행만 롤백되고 INSERT된 행은 유지된다
