# Oracle Database 19c: SQL Workshop
## Chapter 1 — 소개 (Introduction)

---

## 학습 목표

이 단원을 완료하면 다음을 수행할 수 있습니다:

- 과정의 목표를 정의한다
- Oracle Database 19c의 특징을 나열한다
- 관계형 데이터베이스의 이론적·물리적 측면을 설명한다
- Oracle 서버의 RDBMS 및 ORDBMS 구현 방식을 설명한다
- 이 과정에서 사용할 수 있는 개발 환경을 식별한다
- 이 과정에서 사용하는 데이터베이스와 스키마를 설명한다

---

## 학습 목차

- 과정 목표, 로드맵, 그리고 부록
- Oracle Database 19c 및 관련 제품 개요
- 관계형 데이터베이스 관리 개념 및 용어 개요
- Human Resource (HR) 스키마 및 과정에서 사용하는 테이블
- SQL 및 개발 환경 소개
- Oracle Database 19c SQL 문서 및 추가 자료

---

## 과정 목표

이 과정을 완료하면 다음을 수행할 수 있습니다:

- Oracle Database와 MySQL의 주요 구성 요소를 식별한다
- SELECT 문으로 테이블에서 행과 열 데이터를 조회한다
- 정렬 및 제한된 데이터 보고서를 작성한다
- SQL 함수를 활용하여 사용자 정의 데이터를 생성하고 조회한다
- 복잡한 쿼리를 실행하여 여러 테이블에서 데이터를 조회한다
- DML(데이터 조작 언어) 문을 실행하여 데이터베이스 데이터를 업데이트한다
- DDL(데이터 정의 언어) 문을 실행하여 스키마 객체를 생성하고 관리한다

---

## 과정 로드맵

| 단원 | 레슨 |
|------|------|
| Unit 1: 데이터 조회·제한·정렬 | Lesson 1: 소개 |
| | Lesson 2: SQL SELECT로 데이터 조회 |
| | Lesson 3: 데이터 제한 및 정렬 |
| | Lesson 4: 단일행 함수로 출력 사용자 정의 |
| | Lesson 5: 변환 함수 및 조건 표현식 사용 |
| | Lesson 6: 그룹 함수로 집계 데이터 보고 |
| Unit 2: 조인·서브쿼리·집합 연산자 | Lesson 7: 조인으로 여러 테이블 데이터 표시 |
| | Lesson 8: 서브쿼리로 쿼리 해결 |
| | Lesson 9: 집합 연산자 사용 |
| Unit 3: DML과 DDL | Lesson 10: DML 문으로 테이블 관리 |
| | Lesson 11: DDL(데이터 정의 언어) 소개 |
| Unit 4: 뷰·시퀀스·동의어·인덱스 | Lesson 12: 데이터 딕셔너리 뷰 소개 |
| | Lesson 13: 시퀀스·동의어·인덱스 생성 |
| | Lesson 14: 뷰 생성 |
| Unit 5: 데이터베이스 객체 및 서브쿼리 관리 | Lesson 15: 스키마 객체 관리 |
| | Lesson 16: 서브쿼리로 데이터 조회 |
| | Lesson 17: 서브쿼리로 데이터 조작 |
| Unit 6: 사용자 접근 제어 | Lesson 18: 사용자 접근 제어 |
| Unit 7: 고급 쿼리 | Lesson 19: 고급 쿼리로 데이터 조작 |
| | Lesson 20: 다양한 시간대의 데이터 관리 |

---

## 과정에서 사용하는 부록 및 실습

- Oracle 및 MySQL 실습 가이드
- 부록 A: 테이블 설명
- 부록 B: SQL Developer 사용법
- 부록 C: SQL*Plus 사용법
- 부록 D: 자주 사용하는 SQL 명령어
- 부록 E: 관련 데이터 그룹화로 보고서 생성
- 부록 F: 계층적 데이터 조회
- 부록 G: 고급 스크립트 작성
- 부록 H: Oracle Database 아키텍처 구성 요소
- 부록 I: 정규 표현식 지원
- 실습 및 솔루션 / 추가 실습 및 솔루션

---

## Oracle Database 19c 중점 영역

| 영역 | 설명 |
|------|------|
| 정보 관리 | 대용량 데이터의 안전한 저장 및 관리 |
| 애플리케이션 개발 | 개발 도구 및 프레임워크 지원 |
| Oracle Cloud Infrastructure | 클라우드 기반 배포 및 운영 |
| 고가용성 | 무중단 운영 및 재해 복구 |
| 관리 용이성 | 자동화된 관리 기능 |
| 성능 | 쿼리 최적화 및 고성능 처리 |
| 정보 통합 | 다양한 데이터 소스 통합 |
| 보안 | 데이터 암호화 및 접근 제어 |

---

## MySQL: 디지털 시대를 위한 현대적 데이터베이스

**글로벌 기업들이 MySQL로 혁신을 이끌고 있습니다:**

- 8억 명 이상의 가입자를 지원하는 이동통신망
- Booking.com — 하루 20억 건의 이벤트 처리
- 10억 명 시민의 ID 처리
- 17억 명의 활성 사용자
- PayPal — 100TB의 사용자 데이터
- Candy Crush — 하루 8억 5천만 건의 게임 플레이

---

## MySQL 지원 운영 체제

MySQL은 다음을 제공합니다:

- 사용자에게 제어권과 유연성을 제공
- 다양한 범용 플랫폼 지원:
  - Windows (x86, x86_64)
  - Linux (x86, x86_64)
  - Oracle Solaris (SPARC_64, x86_64, x86)
  - Mac OS X (x86, x86_64)
- 그 외 플랫폼에서도 컴파일하여 실행 가능

---

## MySQL Enterprise Edition

### 주요 기능

| 구분 | 기능 |
|------|------|
| 확장성 | MySQL Enterprise Thread Pool, 그룹 복제, InnoDB 클러스터 |
| 고가용성 | MySQL Enterprise HA |
| 보안 | 네트워크 접근 제어, 엔터프라이즈 인증, 감사, 암호화/TDE, 방화벽 |
| 모니터링 | MySQL Enterprise Monitor |
| 백업 | MySQL Enterprise Backup |
| 개발 | MySQL Connectors |
| 관리 | MySQL Workbench, MySQL Utilities |
| 마이그레이션 | MySQL Workbench |

### 지원

- Oracle Premier Support for MySQL (기술 및 컨설팅 지원)
- Oracle 공인 MySQL 데이터베이스 관리자 자격증
- Oracle 공인 MySQL 개발자 자격증

---

## Oracle Premier Support for MySQL

- 최대 규모의 MySQL 엔지니어링·지원 조직
- MySQL 개발자들이 직접 지원
- 29개 언어로 세계 최고 수준의 지원 제공
- 핫픽스 및 유지 관리 릴리즈 제공
- **24 × 7 × 365** 무중단 지원
- 무제한 인시던트 처리
- 컨설팅 지원
- 글로벌 규모의 지원 체계

> "MySQL 지원 서비스는 프로덕션 클러스터 문제 해결 및 권고 사항 제공에 큰 도움이 되었습니다. 감사합니다." — Carlos Morales (playfulplay.com)

---

## MySQL과 Oracle 통합

MySQL은 다음 Oracle 환경과 통합됩니다:

- Oracle Linux / Oracle Solaris
- Oracle OpenStack
- Oracle Fusion Middleware
- Oracle Enterprise Manager
- Oracle Secure Backup
- Oracle Clusterware
- Oracle Audit Vault and Database Firewall

---

## 관계형 및 객체 관계형 데이터베이스 관리 시스템

- 관계형 모델 및 객체 관계형 모델 지원
- 사용자 정의 데이터 타입 및 객체 지원
- 기존 관계형 데이터베이스와 완전 호환
- 멀티미디어 및 대용량 객체(LOB) 지원
- 고품질 데이터베이스 서버 기능 제공

---

## 관계형 데이터베이스의 개념

Dr. E. F. Codd는 1970년에 데이터베이스 시스템의 관계형 모델을 제안했습니다.

**관계형 모델의 구성 요소:**

- 객체 또는 관계(테이블)의 집합
- 관계에 작용하는 연산자 집합
- 정확성과 일관성을 위한 데이터 무결성

> 관계형 데이터베이스란 Oracle 서버가 제어하는 2차원 테이블(관계)의 집합입니다.

---

## 엔티티 관계 모델 (ERD)

비즈니스 요구 사항으로부터 엔티티 관계 다이어그램을 작성합니다.

**예시 시나리오:**
- "하나 이상의 직원을 부서에 배정한다."
- "일부 부서에는 아직 배정된 직원이 없을 수 있다."

**EMPLOYEE 엔티티:**
- `#* number` (식별자)
- `* name` (필수)
- `o job_title` (선택)

**DEPARTMENT 엔티티:**
- `#* number` (식별자)
- `* name` (필수)
- `o location` (선택)

### 모델링 규칙

| 구분 | 규칙 |
|------|------|
| 엔티티 | 단수·고유 이름, 대문자, 소프트 박스 |
| 속성 | 단수 이름, 소문자, 필수(`*`), 선택(`o`) |
| 고유 식별자 | 기본(`#`), 보조(`(#)`) |

---

## 여러 테이블 간의 관계

- 테이블의 각 데이터 행은 **기본 키(Primary Key)**로 고유하게 식별됩니다.
- **외래 키(Foreign Key)**를 통해 여러 테이블의 데이터를 논리적으로 연결할 수 있습니다.

### 관계형 데이터베이스 용어

| 용어 | 설명 |
|------|------|
| 테이블(Table) | 행과 열로 구성된 2차원 데이터 구조 |
| 행(Row) | 테이블의 단일 레코드 |
| 열(Column) | 테이블의 단일 속성 |
| 기본 키(Primary Key) | 행을 고유하게 식별하는 열 |
| 외래 키(Foreign Key) | 다른 테이블의 기본 키를 참조하는 열 |

---

## Human Resources (HR) 스키마

이 과정에서는 HR(인사) 애플리케이션 스키마를 사용합니다.

### 주요 테이블 구조

| 테이블 | 주요 컬럼 |
|--------|----------|
| **EMPLOYEES** | employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id |
| **DEPARTMENTS** | department_id, department_name, manager_id, location_id |
| **JOBS** | job_id, job_title, min_salary, max_salary |
| **JOB_HISTORY** | employee_id, start_date, end_date, job_id, department_id |
| **LOCATIONS** | location_id, street_address, postal_code, city, state_province, country_id |
| **COUNTRIES** | country_id, country_name, region_id |
| **REGIONS** | region_id, region_name |
| **JOB_GRADES** | grade_level, lowest_sal, highest_sal |

---

## SQL이란?

**SQL(Structured Query Language)**:

- 관계형 데이터베이스 운영을 위한 ANSI 표준 언어
- 효율적이고 배우기 쉬움
- 기능적으로 완전함 — 데이터 정의·조회·조작 모두 가능

```sql
SELECT department_name
FROM   departments;
```

### SQL의 특징

- 독립적이고 강력한 언어
- 데이터 그룹을 일괄 처리
- 논리적 수준에서 데이터 작업 가능

---

## 과정에서 사용하는 SQL 구문

| 구분 | 명령어 |
|------|--------|
| **DML** (데이터 조작 언어) | SELECT, INSERT, UPDATE, DELETE, MERGE |
| **DDL** (데이터 정의 언어) | CREATE, ALTER, DROP, RENAME, TRUNCATE, COMMENT |
| **DCL** (데이터 제어 언어) | GRANT, REVOKE |
| **트랜잭션 제어** | COMMIT, ROLLBACK, SAVEPOINT |

---

## Oracle SQL 개발 환경

이 과정에서는 두 가지 Oracle 개발 환경을 사용합니다:

- **주요 도구:** Oracle SQL Developer
- **보조 도구:** SQL*Plus 명령행 인터페이스

### Oracle Live SQL

- Oracle Database에서 SQL 및 PL/SQL 스크립트를 학습·테스트·공유할 수 있는 환경
- 무료로 가입하여 사용 가능

---

## MySQL 개발 환경

이 과정에서 사용할 수 있는 두 가지 MySQL 개발 환경:

- **주요 도구:** MySQL Workbench
- **보조 도구:** mysql 명령행 도구

---

## Oracle Database 문서 자료

- Oracle Database New Features Guide (신기능 가이드)
- Oracle Database Reference (참조 문서)
- Oracle Database SQL Language Reference (SQL 언어 참조)
- Oracle Database Concepts (개념 가이드)
- Oracle Database SQL Developer User's Guide (SQL Developer 사용자 가이드)

### 추가 자료

- Oracle Learning Library: http://www.oracle.com/goto/oll
- Oracle Cloud: cloud.oracle.com
- SQL Developer 홈페이지: http://www.oracle.com/technology/products/database/sql_developer/

---

## Oracle University SQL 교육 과정

| 수준 | 과정 |
|------|------|
| 입문 | Introduction to SQL |
| 중급 | PL/SQL Fundamentals |
| 고급 | SQL Tuning for Developers |

### Oracle SQL 자격증

- Oracle Database SQL Certified Associate
- Oracle Database PL/SQL Certified Associate
- Oracle Database PL/SQL Certified Professional

> Pearson VUE 시험 센터에서 원하는 시간에, 175개국 이상에서 응시 가능

---

## MySQL 온라인 리소스

| 사이트 | 내용 |
|--------|------|
| http://www.mysql.com | 제품 정보, 교육·자격증·컨설팅·지원 서비스, 백서 및 웨비나 |
| http://dev.mysql.com | 개발자 존, 문서, 다운로드 |
| https://github.com/mysql | MySQL 서버 및 제품 소스 코드 |

### MySQL 커뮤니티 자료

- 메일링 리스트 및 포럼
- 개발자 아티클
- MySQL 뉴스레터 (월간)
- Planet MySQL 블로그
- SNS 채널 (Facebook, Twitter, Google+)
- 개발자 데이, MySQL Tech Tours, 웨비나

---

## Oracle University MySQL 교육 과정

| 수준 | 과정 |
|------|------|
| 입문 | MySQL Fundamentals |
| 중급 | MySQL for Developers / MySQL for Database Administrators |
| 고급 | MySQL Performance Tuning / MySQL Cluster |

### MySQL 자격증

- Oracle Certified Professional: MySQL 5.6 Database Administrator
- Oracle Certified Professional: MySQL 5.6 Developer

---

## 단원 요약

이 단원에서 배운 내용:

- 과정의 목표
- Oracle Database 19c의 특징
- 관계형 데이터베이스의 이론적·물리적 측면
- Oracle 서버의 RDBMS 및 ORDBMS 구현
- 이 과정에서 사용할 수 있는 개발 환경
- 이 과정에서 사용하는 데이터베이스와 스키마

---

## Practice 1: 개요

이 실습에서 다루는 내용:

- Oracle SQL Developer 시작하기
- 새 데이터베이스 연결 생성
- HR 테이블 탐색
