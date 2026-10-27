# Oracle Database 19c Security 교안 — 챕터 목록

**작성일**: 2026-10-27
**과정 코드명**: SECURITY (`OracleManual` 저장소 `SECURITY/`)
**산출물**: 장별 본문 docx · PPT · OEL7V9 실측 트랜스크립트. 실습문제·시험은 만들지 않는다.
**규격**: `..\작업규격.md`

---

## 1. 소스 인벤토리

| 약어 | 문서 | 위치 | 용도 |
|---|---|---|---|
| **SEG** | Oracle Database Security Guide 19c | https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/ | 1순위 근거. 장 구성·용어·문법 |
| **ASO** | Oracle Database Advanced Security Guide 19c | https://docs.oracle.com/en/database/oracle/oracle-database/19/asoag/ | 8장(Data Redaction)·10장(TDE) 근거 |
| **ARPLS** | PL/SQL Packages and Types Reference 19c | https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/ | 패키지 인자·상수 |
| **ETC** | `SEC_ETC.pdf` 45쪽 | `Downloads\sec\` | SSL, SEPS, Proxy, Secure Application Role, Application Context, Data Masking, DBMS_CRYPTO, TDE 실습 흐름 |
| **ACL** | `SEC_ACL.pdf` 9쪽 | 〃 | DBMS_NETWORK_ACL_ADMIN, UTL_HTTP |
| **LNK** | `SEC_DB_NETWORKLINK.pdf` 7쪽 | 〃 | DB Link 권한 위임, Data Pump NETWORK_LINK |
| **VPD** | `SEC_FGAC.pdf` 4쪽 | 〃 | DBMS_RLS |
| **FGA** | `SEC_FGA.pdf` 5쪽 | 〃 | DBMS_FGA |
| **SYS** | `SEC_syslog.pdf` 3쪽 | 〃 | AUDIT_SYSLOG_LEVEL, rsyslog |
| **MSK** | `Masking Data.txt` | 〃 | DBMS_REDACT FULL·PARTIAL |

원본 PDF는 한글 글꼴의 ToUnicode가 깨져 있어 텍스트 추출로는 한글이 빠진다. 페이지 이미지로 판독한
복원본을 스크래치 `src\*.md`에 두고 쓴다(저장소에 넣지 않는다).

## 2. 장 구성

| 장 | 제목 | 원본 | 매뉴얼 근거 |
|---|---|---|---|
| 1 | Secure External Password Store | ETC p6~11 | SEG Configuring Authentication — Managing the Secure External Password Store |
| 2 | 프록시 인증 (Proxy Authentication) | ETC p12~18 | SEG — Proxy Authentication and Authorization |
| 3 | Secure Application Role | ETC p19~25 | SEG Configuring Privilege and Role Authorization |
| 4 | 네트워크 ACL | ACL | SEG Managing Fine-Grained Access in PL/SQL Packages and Types |
| 5 | Database Link 보안 | LNK | SEG (DB link 권한), Administrator's Guide |
| 6 | Application Context | ETC p26~32 | SEG Using Application Contexts to Retrieve User Information |
| 7 | Virtual Private Database | VPD | SEG Using Oracle Virtual Private Database to Control Data Access |
| 8 | Data Redaction | MSK, ETC p33~37 | ASO Part II Using Oracle Data Redaction |
| 9 | DBMS_CRYPTO를 이용한 데이터 암호화 | ETC p38~39 | SEG Manually Encrypting Data |
| 10 | Transparent Data Encryption | ETC p40~45 | ASO Part I Using Transparent Data Encryption |
| 11 | TLS(SSL) 네트워크 암호화 | ETC p1~5 | SEG Configuring Transport Layer Security Encryption |
| 12 | Fine-Grained Auditing | FGA | SEG Configuring Audit Policies — Auditing Specific Activities with Fine-Grained Auditing |
| 13 | 감사 기록 관리와 syslog 전송 | SYS | SEG Administering the Audit Trail |


## 3. 장별 범위와 경계

- **1장 SEPS** — `mkstore`로 지갑 생성·자격 증명 등록, `sqlnet.ora`의 `WALLET_LOCATION`·`SQLNET.WALLET_OVERRIDE`, `/@alias` 접속.
  지갑 자체(PKCS#12, auto-login)의 원리는 여기서 처음 설명하고 10·11장은 참조만 한다.
- **2장 Proxy** — `ALTER USER ... GRANT CONNECT THROUGH`, `WITH ROLE`, `AUTHENTICATION REQUIRED`, `proxy[target]` 접속,
  `PROXY_USERS`, `SYS_CONTEXT('USERENV','PROXY_USER')`, 감사 기록에서 프록시 식별.
- **3장 Secure Application Role** — 역할·권한 조회 뷰(원본 앞부분) 간단히 → `CREATE ROLE ... IDENTIFIED USING`,
  invoker's rights 패키지에서 `SET ROLE`, 조건(IP·모듈) 검사. 컨텍스트 깊은 설명은 6장 몫.
- **4장 ACL** — 19c `APPEND_HOST_ACE`/`REMOVE_HOST_ACE`, `xs$ace_type`, `DBA_HOST_ACES`·`DBA_HOST_ACLS`,
  ORA-24247, `UTL_HTTP`로 확인. 원본의 `CREATE_ACL`·`ASSIGN_ACL`은 디프리케이트로 Note 처리.
- **5장 DB Link** — 링크 유형(connected/fixed/current user), 정의자 권한 프로시저로 원격 DML 위임, ORA-02021과 뷰 우회,
  `DBA_DB_LINKS`, 링크 비밀번호 보호, Data Pump `NETWORK_LINK`. 상대편 DB는 `sales`.
- **6장 Application Context** — 로컬(세션) 컨텍스트, 신뢰 패키지, LOGON 트리거, 전역 접근 컨텍스트(`ACCESSED GLOBALLY`,
  `CLIENT_IDENTIFIER`), 컨텍스트를 쓰는 보안 뷰. VPD 정책은 7장 몫.
- **7장 VPD** — 정책 함수, `DBMS_RLS.ADD_POLICY`, statement_types·update_check, 컬럼 수준 VPD(`sec_relevant_cols`,
  `ALL_ROWS`), 정책 유형, `EXEMPT ACCESS POLICY`, `DBA_POLICIES`·`V$VPD_POLICY`. 정책 관리자 계정은 매뉴얼 관례인 `sysadmin_vpd`.
- **8장 Data Redaction** — FULL·PARTIAL·REGEXP·RANDOM·NULLIFY, 정책 식, `ALTER_POLICY`, `EXEMPT REDACTION POLICY`,
  `REDACTION_POLICIES`·`REDACTION_COLUMNS`, 원본의 정적 마스킹(SDM) 비교는 개념 표로.
- **9장 DBMS_CRYPTO** — 알고리즘·체인·패딩 상수, `ENCRYPT`/`DECRYPT`, `HASH`, `MAC`, `RANDOMBYTES`, 키 관리 문제.
- **10장 TDE** — 19c `WALLET_ROOT`+`TDE_CONFIGURATION`, `ADMINISTER KEY MANAGEMENT`, 컬럼·테이블스페이스 암호화,
  온라인 변환, auto-login, 키 교체. orcl은 지갑이 없는 상태에서 시작해 실습 후 철거한다.
- **11장 TLS** — `orapki` 지갑·자체 서명 CA·인증서 요청/서명, TCPS 리스너(2484), `sqlnet.ora` TLS 파라미터,
  인증서 기반 사용자(`IDENTIFIED EXTERNALLY AS 'CN=...'`). 원본의 512·1024비트 키는 2048로.
- **12장 FGA** — `DBMS_FGA.ADD_POLICY`, audit_condition·audit_column·statement_types·handler,
  `DBA_FGA_AUDIT_TRAIL`과 mixed 모드에서 `UNIFIED_AUDIT_TRAIL`의 관계, `audit_trail` 옵션(DB, DB+EXTENDED, XML).
- **13장 감사 기록 관리** — 감사 모드(mixed/pure unified), Unified Audit Trail 조회, `DBMS_AUDIT_MGMT`로 정리·보관 기한,
  `AUDIT_SYSLOG_LEVEL`과 rsyslog 연동, `UNIFIED_AUDIT_SYSTEMLOG`. 감사 정책 생성 자체는 12장과 겹치지 않게 최소.

## 4. 진행 순서

1. 7장 시범본(트랜스크립트 → 본문 → PPT) → 사용자 검토
2. 1~6장, 8~13장. 실측은 한 VM에서 순차, 원고는 장별 병렬
3. `tools\verify.py` 전 장 + 직접 재검증 → `OracleManual\SECURITY\` 반영
