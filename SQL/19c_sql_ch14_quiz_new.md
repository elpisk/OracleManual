# Oracle Database 19c: SQL Workshop
## Chapter 14 — 뷰(View) 생성 | 연습문제 50문제

---

## 하(기초) — 20문제

**[1번]** 다음 중 뷰(View)에 대한 올바른 설명은?

① 데이터를 테이블과 별도로 저장하는 물리적 객체다  
② 하나 이상의 테이블 데이터를 논리적으로 표현하는 데이터베이스 객체다  
③ 뷰를 삭제하면 기반 테이블의 데이터도 삭제된다  
④ 뷰는 인덱스를 가질 수 없다

---

**[2번]** `CREATE VIEW` 구문에서 기반 테이블 없이 뷰를 강제로 생성하는 옵션은?

① `OR REPLACE`  
② `NOFORCE`  
③ `FORCE`  
④ `WITH READ ONLY`

---

**[3번]** 다음 중 단순 뷰(Simple View)의 특징으로 올바른 것은?

① 여러 테이블을 JOIN할 수 있다  
② 그룹 함수를 포함할 수 있다  
③ 기반 테이블이 1개이며 함수와 그룹이 없다  
④ DML 작업이 항상 불가능하다

---

**[4번]** 다음 SQL문을 실행하면 어떤 결과가 나타나는가?

```sql
CREATE VIEW empvu80
AS SELECT employee_id, last_name, salary
   FROM   employees
   WHERE  department_id = 80;
```

① 부서 80번 직원의 모든 열을 포함한 뷰가 생성된다  
② 부서 80번 직원의 employee_id, last_name, salary를 포함한 뷰가 생성된다  
③ 뷰 이름이 테이블 이름과 달라야 하므로 오류가 발생한다  
④ WHERE 절이 있는 뷰는 생성할 수 없으므로 오류가 발생한다

---

**[5번]** 뷰를 수정하는 올바른 방법은?

① `ALTER VIEW empvu80 AS SELECT ...;`  
② `CREATE OR REPLACE VIEW empvu80 AS SELECT ...;`  
③ `MODIFY VIEW empvu80 AS SELECT ...;`  
④ `UPDATE VIEW empvu80 SET ...;`

---

**[6번]** 뷰에서 데이터를 조회하는 올바른 SQL문은?

① `SELECT * FROM VIEW empvu80;`  
② `SELECT * FROM empvu80;`  
③ `SELECT * VIEW empvu80;`  
④ `QUERY VIEW empvu80;`

---

**[7번]** `USER_VIEWS` 딕셔너리 뷰에서 뷰의 정의(서브쿼리 텍스트)를 저장하는 컬럼은?

① `DEFINITION`  
② `QUERY`  
③ `TEXT`  
④ `SUBQUERY`

---

**[8번]** 다음 중 `WITH READ ONLY` 옵션에 대한 설명으로 올바른 것은?

① SELECT 문만 차단하고 DML은 허용한다  
② 뷰를 통한 모든 DML(INSERT/UPDATE/DELETE)을 차단한다  
③ UPDATE만 허용하고 INSERT/DELETE는 차단한다  
④ 읽기 전용 사용자만 접근할 수 있도록 제한한다

---

**[9번]** 뷰를 삭제하는 올바른 SQL문은?

① `DELETE VIEW empvu80;`  
② `REMOVE VIEW empvu80;`  
③ `DROP VIEW empvu80;`  
④ `TRUNCATE VIEW empvu80;`

---

**[10번]** `DROP VIEW`를 실행하면 기반 테이블의 데이터는 어떻게 되는가?

① 기반 테이블도 삭제된다  
② 기반 테이블의 데이터가 모두 삭제된다  
③ 기반 테이블과 데이터는 영향을 받지 않는다  
④ 기반 테이블이 READ ONLY 상태로 변경된다

---

**[11번]** 다음 중 `WITH CHECK OPTION`에 대한 설명으로 올바른 것은?

① 뷰에 대한 SELECT를 제한한다  
② 뷰의 WHERE 조건을 만족하는 행만 DML 허용  
③ 기반 테이블에 CHECK 제약을 추가한다  
④ 뷰를 통한 INSERT만 허용한다

---

**[12번]** 복합 뷰(Complex View)가 단순 뷰(Simple View)와 다른 점은?

① 복합 뷰는 WHERE 절을 사용할 수 없다  
② 복합 뷰는 여러 테이블, 함수, 그룹을 포함할 수 있다  
③ 복합 뷰는 CREATE OR REPLACE를 사용할 수 없다  
④ 복합 뷰는 항상 WITH READ ONLY가 적용된다

---

**[13번]** 뷰 생성 시 열에 별칭을 부여하는 방법으로 올바르지 않은 것은?

① 서브쿼리 내에서 `열 별칭` 형식 사용  
② `CREATE VIEW v (alias1, alias2) AS SELECT ...` 형식 사용  
③ `CREATE VIEW v AS SELECT col RENAME alias` 형식 사용  
④ 서브쿼리에서 `salary * 12 ANN_SALARY` 처럼 표현식에 별칭 지정

---

**[14번]** `OR REPLACE` 옵션의 장점은?

① 뷰를 삭제하지 않아도 재정의할 수 있으며 기존 권한이 유지된다  
② 뷰를 삭제하고 재생성하면서 권한을 초기화한다  
③ 기반 테이블의 데이터를 자동으로 갱신한다  
④ 동일 이름의 테이블이 있어도 뷰를 생성할 수 있다

---

**[15번]** 다음 뷰 정의에서 `ANN_SALARY`는 무엇인가?

```sql
CREATE VIEW salvu50
AS SELECT employee_id ID_NUMBER, last_name NAME, salary*12 ANN_SALARY
   FROM   employees WHERE department_id = 50;
```

① 기반 테이블의 실제 열 이름  
② 표현식 `salary*12`에 부여한 열 별칭  
③ 파라미터 변수  
④ 상수 값

---

**[16번]** 현재 사용자가 소유한 뷰 목록을 조회하는 올바른 SQL문은?

① `SELECT * FROM all_views;`  
② `SELECT view_name FROM user_views;`  
③ `SELECT name FROM sys.views;`  
④ `SHOW VIEWS;`

---

**[17번]** 다음 중 뷰의 장점이 아닌 것은?

① 민감한 데이터 열을 숨겨 보안을 강화한다  
② 복잡한 쿼리를 단순화할 수 있다  
③ 디스크 저장 공간을 줄인다  
④ 기반 테이블 변경으로부터 애플리케이션을 보호한다

---

**[18번]** `DESCRIBE empvu80;` 명령어를 실행하면 어떤 정보를 얻을 수 있는가?

① 뷰의 서브쿼리 텍스트  
② 뷰를 생성한 사용자 이름  
③ 뷰의 열 이름과 데이터 타입  
④ 뷰를 통해 접근 가능한 행 수

---

**[19번]** 다음 중 `FORCE` 옵션이 유용한 상황은?

① 기반 테이블이 이미 존재하는 경우  
② 기반 테이블이 아직 생성되지 않았지만 뷰 정의를 미리 만들고 싶은 경우  
③ 뷰에 인덱스를 생성하고 싶은 경우  
④ 다른 사용자의 테이블에 접근하는 뷰를 만드는 경우

---

**[20번]** 다음 중 뷰를 통해 DML을 수행할 수 없는 경우는?

① 단순 뷰이고 WHERE 절만 포함된 경우  
② 단순 뷰이고 계산 열이 없는 경우  
③ 복합 뷰이고 GROUP BY 절을 포함한 경우  
④ 단일 테이블 기반 뷰에서 조건 행을 UPDATE하는 경우

---

## 중(응용) — 20문제

**[21번]** 다음 중 단순 뷰에서 DELETE가 불가능한 경우는?

① 기반 테이블이 PRIMARY KEY를 가진 경우  
② 뷰가 DISTINCT 키워드를 포함한 경우  
③ 뷰에 WHERE 절이 있는 경우  
④ 뷰가 2개 이상의 열을 포함한 경우

---

**[22번]** 다음 뷰를 생성 후 아래 INSERT를 실행하면 어떤 결과인가?

```sql
CREATE OR REPLACE VIEW empvu20
AS SELECT * FROM employees
   WHERE  department_id = 20
WITH CHECK OPTION CONSTRAINT empvu20_ck;

INSERT INTO empvu20 (employee_id, last_name, email,
                     hire_date, job_id, department_id)
VALUES (500, 'Hong', 'HONG', SYSDATE, 'IT_PROG', 30);
```

① 정상적으로 삽입된다  
② ORA-01402: WITH CHECK OPTION 위반 오류가 발생한다  
③ ORA-00942: 테이블이 존재하지 않는다는 오류가 발생한다  
④ department_id가 자동으로 20으로 변환되어 삽입된다

---

**[23번]** `CREATE OR REPLACE VIEW`와 `DROP VIEW` 후 `CREATE VIEW`의 차이점은?

① 두 방법 모두 결과가 동일하다  
② `OR REPLACE`는 기존 뷰에 부여된 권한이 유지되고, DROP 후 재생성은 권한이 사라진다  
③ `OR REPLACE`는 기반 테이블 데이터를 삭제한다  
④ DROP 후 재생성이 권한 유지 측면에서 더 안전하다

---

**[24번]** 다음 복합 뷰에서 UPDATE가 가능한가?

```sql
CREATE VIEW dept_sal_vu
AS SELECT department_id, AVG(salary) avg_sal
   FROM   employees
   GROUP BY department_id;
```

① 가능하다. 뷰를 통해 avg_sal을 직접 수정할 수 있다  
② 불가능하다. GROUP BY와 집계 함수가 있는 뷰는 DML이 불가하다  
③ department_id는 수정 가능하다  
④ WHERE 절을 추가하면 UPDATE가 가능하다

---

**[25번]** 다음 뷰를 통해 INSERT를 실행할 때 발생하는 문제는?

```sql
CREATE VIEW emp_name_vu
AS SELECT employee_id, last_name,
          salary * 12 annual_sal
   FROM   employees;

INSERT INTO emp_name_vu VALUES (999, 'Kim', 120000);
```

① 정상 삽입된다  
② `annual_sal`이 표현식이므로 INSERT가 불가능하다  
③ employee_id가 PK이므로 INSERT가 불가하다  
④ 뷰를 통한 INSERT는 항상 불가능하다

---

**[26번]** `WITH READ ONLY` 뷰에서 SELECT를 실행하면?

① ORA-42399 오류가 발생한다  
② 정상적으로 데이터를 조회할 수 있다  
③ 관리자 권한이 있어야만 SELECT 가능하다  
④ WITH READ ONLY는 SELECT도 차단한다

---

**[27번]** 다음 뷰 정의에서 `(id_number, name, sal, department_id)`의 역할은?

```sql
CREATE OR REPLACE VIEW empvu80
    (id_number, name, sal, department_id)
AS SELECT employee_id, first_name || ' ' || last_name,
          salary, department_id
   FROM   employees
   WHERE  department_id = 80;
```

① 뷰의 인덱스 열을 정의한다  
② 뷰의 열 별칭을 서브쿼리 열 순서에 맞게 지정한다  
③ WHERE 조건을 지정한다  
④ 기반 테이블의 제약 조건을 정의한다

---

**[28번]** `USER_VIEWS`를 사용하여 특정 뷰의 서브쿼리를 조회하는 올바른 문장은?

① `SELECT definition FROM user_views WHERE view_name = 'EMPVU80';`  
② `SELECT text FROM user_views WHERE view_name = 'EMPVU80';`  
③ `SELECT query FROM user_views WHERE view_name = 'EMPVU80';`  
④ `SELECT subquery FROM user_views WHERE view_name = 'EMPVU80';`

---

**[29번]** 다음 중 뷰를 통해 INSERT가 불가능한 이유로 올바른 것을 모두 고르면?

```sql
CREATE VIEW emp_dept_vu
AS SELECT employee_id, last_name, department_name
   FROM   employees e JOIN departments d
   USING  (department_id);
```

① NOT NULL 열이 뷰에 없기 때문  
② DISTINCT를 포함하기 때문  
③ 여러 테이블을 JOIN하기 때문  
④ salary 열이 없기 때문

---

**[30번]** 뷰를 생성할 때 서브쿼리에서 `ORDER BY`를 사용할 수 있는가?

① 불가능하다. 뷰 서브쿼리에서 ORDER BY는 허용되지 않는다  
② 가능하다. 뷰 정의에 ORDER BY를 포함할 수 있다  
③ TOP-N 쿼리(`ROWNUM` 또는 `FETCH FIRST`)와 함께 사용하는 경우에만 가능하다  
④ GROUP BY가 있는 경우에만 ORDER BY를 사용할 수 있다

---

**[31번]** 다음 뷰에서 salary 열을 UPDATE 할 수 있는가?

```sql
CREATE VIEW empvu30
AS SELECT employee_id, last_name, salary
   FROM   employees
   WHERE  department_id = 30;
```

① 불가능하다. WHERE 절이 있는 뷰는 UPDATE 불가하다  
② 가능하다. 단순 뷰이고 salary가 직접 테이블 열이므로 UPDATE 가능하다  
③ 가능하지만 department_id가 30이 아닌 데이터는 수정 불가하다  
④ 뷰를 통한 UPDATE는 항상 금지된다

---

**[32번]** 다음 중 `USER_VIEWS`의 `READ_ONLY` 컬럼 값이 `'Y'`인 경우는?

① 뷰 생성 시 `WITH CHECK OPTION`을 사용한 경우  
② 뷰 생성 시 `WITH READ ONLY`를 사용한 경우  
③ 뷰가 복합 뷰인 경우  
④ 뷰가 FORCE로 생성된 경우

---

**[33번]** 다음 중 뷰를 삭제할 수 있는 권한은?

① SELECT ANY VIEW  
② ALTER ANY VIEW  
③ DROP ANY VIEW  
④ DELETE ANY VIEW

---

**[34번]** `WITH CHECK OPTION`에 `CONSTRAINT empvu20_ck`를 지정하는 이유는?

① 기반 테이블에 CHECK 제약을 추가하기 위해  
② 제약 조건에 이름을 부여하여 오류 메시지에 이름이 표시되도록 하기 위해  
③ 인덱스를 생성하기 위해  
④ 뷰의 WHERE 조건을 변경할 수 없도록 잠그기 위해

---

**[35번]** 다음 중 ROWNUM을 포함한 뷰에서 불가능한 작업은?

① SELECT  
② DELETE  
③ CREATE OR REPLACE  
④ DESCRIBE

---

**[36번]** 뷰 기반 뷰(뷰 위에 생성된 뷰)를 만들 수 있는가?

① 불가능하다. 뷰는 테이블만 기반으로 할 수 있다  
② 가능하다. 뷰를 서브쿼리의 FROM 절에서 사용하여 새 뷰를 만들 수 있다  
③ 가능하지만 2단계까지만 허용된다  
④ DBA 권한이 있어야만 가능하다

---

**[37번]** 다음 중 복합 뷰에서 가능한 작업은?

① `INSERT`가 항상 가능하다  
② `DELETE`가 항상 가능하다  
③ `SELECT`는 항상 가능하다  
④ `UPDATE`가 항상 가능하다

---

**[38번]** 단순 뷰에서 `WITH CHECK OPTION` 없이 `WHERE department_id = 20` 뷰에 `department_id = 30` 행을 INSERT하면?

① ORA-01402 오류가 발생한다  
② 삽입은 성공하지만 뷰를 조회하면 해당 행이 보이지 않는다  
③ 삽입은 성공하고 뷰에서도 조회된다  
④ 기반 테이블에 삽입되지 않는다

---

**[39번]** 다음 중 `ALL_VIEWS` 딕셔너리 뷰가 `USER_VIEWS`와 다른 점은?

① ALL_VIEWS는 서브쿼리 텍스트를 보여주지 않는다  
② ALL_VIEWS는 현재 사용자가 접근 권한을 가진 모든 사용자의 뷰를 보여준다  
③ ALL_VIEWS는 DBA만 조회할 수 있다  
④ ALL_VIEWS는 읽기 전용 뷰만 표시한다

---

**[40번]** 뷰가 참조하는 기반 테이블이 DROP되면 해당 뷰는?

① 자동으로 함께 삭제된다  
② 뷰 정의는 딕셔너리에 남아 있지만 INVALID 상태가 된다  
③ 기반 테이블이 재생성될 때까지 READ ONLY로 변환된다  
④ 뷰는 다른 테이블에서 자동으로 데이터를 가져온다

---

## 상(심화) — 10문제

**[41번]** 다음 뷰를 생성하고 실행했을 때 결과를 분석하시오.

```sql
CREATE OR REPLACE VIEW emp_dept_vu
AS SELECT e.employee_id, e.last_name, e.salary,
          d.department_name
   FROM   employees e JOIN departments d
   USING  (department_id)
   WHERE  e.salary > 5000;

DELETE FROM emp_dept_vu
WHERE  last_name = 'Fay';
```

① 정상 삭제된다 (단순한 필터 뷰이므로)  
② 오류 발생: JOIN을 포함한 복합 뷰는 DELETE 불가  
③ 오류 발생: salary 조건이 있으면 DELETE 불가  
④ 삭제는 되지만 다른 테이블에만 반영된다

---

**[42번]** `WITH CHECK OPTION`을 사용한 뷰에서 아래 UPDATE의 결과는?

```sql
CREATE OR REPLACE VIEW empvu20
AS SELECT * FROM employees
   WHERE  department_id = 20
WITH CHECK OPTION;

UPDATE empvu20
SET    department_id = 30
WHERE  employee_id = 201;
```

① 정상 업데이트된다  
② ORA-01402: WITH CHECK OPTION where-clause violation 오류  
③ 업데이트 후 해당 행이 뷰에서 사라지지만 오류는 없다  
④ WITH CHECK OPTION은 UPDATE는 허용하고 INSERT만 제한한다

---

**[43번]** 다음 세 가지 방법 중 실제 데이터 변경 여부와 오류 발생 여부를 바르게 분석한 것은?

```sql
-- 방법 A: 뷰를 통한 UPDATE (WITH READ ONLY 없음)
UPDATE empvu80 SET salary = salary * 1.1 WHERE employee_id = 145;

-- 방법 B: 기반 테이블 직접 UPDATE
UPDATE employees SET salary = salary * 1.1 WHERE employee_id = 145 AND department_id = 80;

-- 방법 C: WITH READ ONLY 뷰를 통한 UPDATE
UPDATE empvu10_ro SET salary = salary * 1.1 WHERE employee_id = 200;
```

① A·B 모두 정상, C는 오류  
② A·B·C 모두 정상  
③ A만 오류, B·C 정상  
④ A·C 오류, B만 정상

---

**[44번]** 다음과 같이 뷰를 생성한 후 특정 상황에서 INSERT가 가능한지 판별하시오.

```sql
CREATE VIEW emp_partial_vu
AS SELECT employee_id, last_name, email, hire_date, job_id
   FROM   employees;
```

`employees` 테이블에 `salary` 열이 `NOT NULL`이고 기본값이 없다면 이 뷰를 통한 INSERT는?

① 가능하다. 뷰에서 보이는 열만 삽입하면 된다  
② 불가능하다. 뷰에 없는 NOT NULL 열(salary)에 값을 제공할 수 없어 오류 발생  
③ salary는 기본값 0이 자동으로 삽입된다  
④ 뷰를 통한 INSERT는 단일 테이블이면 항상 가능하다

---

**[45번]** 다음 중 뷰 기반 뷰(nested view)를 만들 때 주의해야 할 사항으로 옳은 것은?

① 뷰 기반 뷰는 Oracle에서 지원하지 않는다  
② 뷰 기반 뷰를 많이 중첩하면 성능이 저하될 수 있으며, 기반 뷰가 삭제되면 INVALID 상태가 된다  
③ 뷰 기반 뷰에서는 WITH CHECK OPTION을 사용할 수 없다  
④ 뷰 기반 뷰는 읽기 전용이 자동 적용된다

---

**[46번]** 다음 시나리오를 분석하시오.

```sql
-- 1. 뷰 생성
CREATE VIEW emp_sal_vu AS
SELECT employee_id, last_name, salary
FROM   employees WHERE salary > 10000;

-- 2. 행 UPDATE (WITH CHECK OPTION 없음)
UPDATE emp_sal_vu
SET    salary = 8000
WHERE  employee_id = 100;

-- 3. 뷰 재조회
SELECT * FROM emp_sal_vu WHERE employee_id = 100;
```

3번 조회 결과는?

① employee_id = 100의 salary = 8000으로 조회된다  
② employee_id = 100의 행이 조회되지 않는다 (`salary > 10000` 조건 불만족)  
③ ORA-01402 오류가 발생한다  
④ UPDATE가 롤백되어 원래 값이 유지된다

---

**[47번]** 다음 시나리오에서 최종적으로 `employees` 테이블에서 employee_id = 300의 행이 존재하는지 판별하시오.

```sql
CREATE VIEW dept50_vu AS
SELECT * FROM employees WHERE department_id = 50;

INSERT INTO dept50_vu
    (employee_id, last_name, email, hire_date, job_id, department_id)
VALUES (300, 'Park', 'PARK', SYSDATE, 'ST_CLERK', 50);

COMMIT;

DROP VIEW dept50_vu;
```

① employees 테이블에 employee_id = 300 행이 존재한다  
② employees 테이블에 employee_id = 300 행이 없다 (뷰 삭제 시 함께 삭제)  
③ DROP VIEW 시 ORA-02449 오류로 삭제 실패한다  
④ INSERT가 뷰에만 저장되므로 테이블에는 반영되지 않는다

---

**[48번]** 다음 중 FORCE 옵션으로 생성된 뷰에 대한 설명으로 옳은 것은?

① 기반 테이블 생성 후 자동으로 VALID 상태가 된다  
② FORCE 뷰는 항상 INVALID 상태를 유지한다  
③ FORCE 뷰는 기반 테이블이 없는 동안 조회 시 ORA-04063 경고를 포함하며, 기반 테이블 생성 후 재컴파일하면 VALID가 된다  
④ FORCE 뷰는 DDL 정의만 저장되고 DML은 항상 차단된다

---

**[49번]** 아래 뷰에서 salary를 기반으로 어떤 DML이 가능한지 분석하시오.

```sql
CREATE VIEW emp_complex_vu AS
SELECT department_id,
       MAX(salary)  max_sal,
       MIN(salary)  min_sal,
       COUNT(*)     emp_cnt
FROM   employees
GROUP BY department_id;
```

① SELECT, INSERT, UPDATE, DELETE 모두 가능  
② SELECT만 가능 (집계 함수 + GROUP BY로 DML 전체 불가)  
③ SELECT, UPDATE만 가능  
④ SELECT, DELETE만 가능

---

**[50번]** 다음과 같이 뷰 계층(v1 → v2)을 만들 때 v2의 WITH CHECK OPTION이 v1의 조건도 검사하는지 분석하시오.

```sql
CREATE VIEW v1 AS
SELECT * FROM employees WHERE department_id = 50;

CREATE VIEW v2 AS
SELECT * FROM v1
WHERE  salary > 3000
WITH CHECK OPTION;

-- 다음 INSERT 결과는?
INSERT INTO v2 (employee_id, last_name, email,
                hire_date, job_id, department_id, salary)
VALUES (400, 'Lee', 'LEE', SYSDATE, 'ST_CLERK', 50, 2000);
```

① salary = 2000이 v2의 `salary > 3000` 조건을 위반하므로 ORA-01402 오류  
② department_id = 50이므로 정상 삽입  
③ v1과 v2 조건 모두 충족해야 하므로 salary > 3000 AND department_id = 50 이어야 한다 — ORA-01402  
④ WITH CHECK OPTION은 서브뷰에서는 검사하지 않는다

---

*[Chapter 14 연습문제 끝 — 50문제]*
