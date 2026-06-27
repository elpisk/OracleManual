# Oracle Database 19c: SQL Workshop
## Chapter 2 — SQL SELECT 문으로 데이터 조회

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있습니다:

- SQL SELECT 문의 기능을 나열한다
- 기본 SELECT 문을 실행한다

---

## 학습 목차

- SQL SELECT 문의 기능
- SELECT 문에서의 산술 표현식과 NULL 값
- 열 별칭 (Column Alias)
- 연결 연산자, 리터럴 문자열, 대체 따옴표 연산자, DISTINCT 키워드 사용
- DESCRIBE 명령어

---

## SQL 문 작성 규칙

- SQL 문은 대소문자를 구분하지 않는다
- SQL 문은 한 줄 또는 여러 줄에 걸쳐 입력할 수 있다
- 키워드는 축약하거나 줄을 나눌 수 없다
- 절(Clause)은 보통 별도의 줄에 작성한다
- 가독성을 높이기 위해 들여쓰기를 사용한다

---

## 기본 SELECT 문

- `SELECT` — 표시할 열을 지정한다
- `FROM` — 해당 열이 포함된 테이블을 지정한다

```sql
SELECT  *|{[DISTINCT] column [alias], ...}
FROM    table;
```

### 모든 열 조회

```sql
SELECT *
FROM   departments;
```

### 특정 열 조회

```sql
SELECT department_id, location_id
FROM   departments;
```

---

## SQL 실행 환경

### Oracle SQL Developer
- Execute Statement 버튼 또는 `F9` 키로 단일 문 실행
- Run Script 버튼 또는 `F5` 키로 스크립트 전체 실행
- 열 머리글 기본값: 왼쪽 정렬, 대문자

### MySQL Workbench
- SQL 편집기에 입력 후 Execute Current SQL Script 버튼 또는 `Ctrl+Enter`
- 결과는 Results Grid에 표시

### SQL*Plus / mysql 명령행
- SQL*Plus: 문 입력 후 `/` 또는 `;`로 실행
- mysql: `;`로 문을 끝내고 Enter
- 열 머리글: 문자·날짜는 왼쪽 정렬, 숫자는 오른쪽 정렬

---

## dual 테이블 (Oracle)

`dual`은 Oracle Database가 자동으로 생성하는 테이블입니다.
- `DUMMY`라는 단일 열(VARCHAR2(1))을 가지며 값은 `'X'`
- 테이블 없이 표현식이나 함수 결과를 조회할 때 사용

```sql
SELECT *
FROM   dual;

SELECT SYSDATE
FROM   dual;
```

### MySQL에서의 상수 표현식 조회

```sql
SELECT SYSDATE();          -- FROM 절 없이 사용 가능

SELECT SYSDATE()
FROM   DUAL;               -- DUAL 절을 허용하지만 무시함
```

---

## 산술 표현식

숫자와 날짜 데이터에 산술 연산자를 사용하여 표현식을 만들 수 있습니다.

| 연산자 | 설명 |
|--------|------|
| `+` | 더하기 |
| `-` | 빼기 |
| `*` | 곱하기 |
| `/` | 나누기 |

```sql
SELECT last_name, salary, salary + 300
FROM   employees;
```

### 연산자 우선순위

곱셈·나눗셈이 덧셈·뺄셈보다 먼저 계산됩니다. 괄호로 우선순위를 변경할 수 있습니다.

```sql
SELECT last_name, salary, 12*salary+100      -- salary에 12를 곱한 후 100을 더함
FROM   employees;

SELECT last_name, salary, 12*(salary+100)    -- (salary+100)에 12를 곱함
FROM   employees;
```

---

## NULL 값

- NULL은 사용할 수 없거나, 할당되지 않았거나, 알 수 없거나, 해당하지 않는 값
- NULL은 0 또는 공백과 다름
- **NULL을 포함한 산술 표현식의 결과는 NULL**

```sql
SELECT last_name, job_id, salary, commission_pct
FROM   employees;

-- commission_pct가 NULL이면 결과도 NULL
SELECT last_name, 12*salary*commission_pct
FROM   employees;
```

---

## 열 별칭 (Column Alias)

열 별칭은:
- 열 머리글의 이름을 변경한다
- 계산 결과에 유용하다
- 열 이름 바로 뒤에 위치한다 (선택적으로 `AS` 키워드 사용 가능)
- 공백·특수문자 또는 대소문자 구분이 필요한 경우 큰따옴표(`"`)로 감싼다

```sql
SELECT last_name AS name, commission_pct comm
FROM   employees;

SELECT last_name "Name", salary*12 "Annual Salary"
FROM   employees;
```

---

## 연결 연산자

### Oracle — `||` 연산자

두 수직 막대(`||`)로 열 또는 문자열을 연결합니다.

```sql
SELECT last_name || job_id AS "Employees"
FROM   employees;

SELECT last_name || ' is a ' || job_id AS "Employee Details"
FROM   employees;
```

### MySQL — `CONCAT()` 함수

```sql
SELECT CONCAT(last_name, job_id) AS "Employees"
FROM   employees;

SELECT CONCAT(last_name, ' is a ', job_id) AS 'Employee Details'
FROM   employees;
```

---

## 리터럴 문자열

- 리터럴은 SELECT 문에 포함되는 문자, 숫자, 날짜 값
- 날짜와 문자 리터럴은 반드시 **단일 따옴표(`'`)** 로 감싼다
- 각 문자열은 반환된 행마다 한 번씩 출력된다

---

## 대체 따옴표 연산자 (Oracle)

단일 따옴표가 포함된 문자열을 쉽게 처리할 수 있습니다.

```sql
SELECT department_name || q'[ Department's Manager Id: ]' || manager_id
       AS "Department and Manager"
FROM   departments;
```

### MySQL — 이스케이프 시퀀스

```sql
SELECT CONCAT(department_name, ' Department\'s Manager Id: ', manager_id)
       AS "Department and Manager"
FROM   departments;
```

---

## 중복 행 제거 — DISTINCT

기본 쿼리는 중복 행을 포함한 모든 행을 반환합니다.  
`DISTINCT` 키워드로 중복을 제거할 수 있습니다.

```sql
-- 중복 포함 (기본값)
SELECT department_id
FROM   employees;

-- 중복 제거
SELECT DISTINCT department_id
FROM   employees;
```

---

## 테이블 구조 조회 — DESCRIBE

`DESCRIBE` 명령어로 테이블의 열 이름, 데이터 타입, NULL 허용 여부를 확인합니다.

```sql
DESCRIBE employees
-- 또는 축약형
DESC employees
```

- **Oracle SQL Developer:** DESCRIBE 명령어 또는 연결 트리에서 테이블 선택 → Columns 탭
- **MySQL Workbench:** DESCRIBE 명령어 또는 Navigator에서 테이블 우클릭 → Table Inspector → Columns 탭

---

## 단원 요약

이 단원에서 배운 SELECT 문 기능:

- 테이블의 모든 행과 열을 반환한다
- 테이블에서 지정한 열만 반환한다
- 열 별칭으로 더 설명적인 열 머리글을 표시한다
- 산술 표현식을 사용하여 계산된 결과를 반환한다
- NULL 값의 특성을 이해한다
- DISTINCT로 중복 행을 제거한다
- DESCRIBE로 테이블 구조를 확인한다

---

## Practice 2: 개요

이 실습에서 다루는 내용:

- 다양한 테이블에서 모든 데이터 조회
- 테이블 구조 확인
- 산술 계산 수행 및 열 이름 지정
