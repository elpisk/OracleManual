# Oracle 19c LOB 실습 과정 안내

대용량 객체(LOB) 타입을 **타입별 성질 → 다루는 방법 → 실무 적용 기준** 순서로 익히는 실습 과정이다.
이론 설명과 실습 트랜스크립트 8개로 구성되며, 트랜스크립트의 모든 출력은 실제 19.3 랩에서 실행해 얻은 것이다.

- 환경 : Oracle Database 19.3.0 EE / Oracle Linux 7.9 / non-CDB `orcl` / `AL32UTF8` + `AL16UTF16` / 블록 8K
- 선행 : SQL 기본, PL/SQL 기본(블록·예외), 테이블스페이스 개념(ADMIN 17~19장 수준)
- 소요 : 실습 8개 약 10시간 (설명 포함 2일 구성 권장)
- 계정 : 실습 전용 `loblab`, 디렉터리 객체 `lob_dir`, 테이블스페이스 `lobtbs`(ASSM)·`lobmssm`(MSSM)

> **실측 고지** — 트랜스크립트의 화면은 19.3.0 non-CDB 랩에서 그대로 실행해 받은 것이다.
> 인스턴스 이름과 경로만 이 과정의 표준 표기(`orcl`, `/u01/app/oracle/oradata/orcl/`)로 옮겼고,
> SCN·세그먼트 이름·바이트 수·오류 번호는 측정값 그대로다. 세그먼트 이름(`SYS_LOB0000074644C00003$$` 등)은
> 객체 번호에 따라 환경마다 달라진다.

---

## 1. LOB 이란 무엇인가

`VARCHAR2`·`RAW` 는 한 행 안에 값을 담는다. SQL 에서 쓸 수 있는 최대 길이는 4000 바이트
(`max_string_size=EXTENDED` 로 확장하면 32767)이고, 그보다 큰 문서·이미지·로그를 담을 수 없다.
LOB(Large OBject)은 **값을 별도의 세그먼트에 두고 행에는 위치 정보(로케이터)만 남기는** 타입이다.

| 구분 | VARCHAR2 / RAW | LOB |
|---|---|---|
| 최대 크기 | 4000 바이트 (확장 시 32767) | 8~128 TB (블록 크기·CHUNK 에 따름) |
| 저장 위치 | 행 안 | 작을 때는 행 안, 크면 별도 LOB 세그먼트 |
| SQL 에서 값 다루기 | 모든 함수·비교·정렬·인덱스 | 일부만. 비교·정렬·DISTINCT·인덱스 불가 |
| 부분 읽기·쓰기 | 불가 (항상 전체) | 가능 (`DBMS_LOB.READ`/`WRITE`, 오프셋 지정) |
| 프로그램 인터페이스 | 값 자체 | **로케이터**(포인터)를 받아 API 로 조작 |

실측으로 확인한 최대 크기(8K 블록, `DBMS_LOB.GET_STORAGE_LIMIT`) :

```
저장 한계(GET_STORAGE_LIMIT)=17463337021470        -- 약 15.9 TB
```

### LONG / LONG RAW 는 쓰지 않는다

`LONG` 은 LOB 이전 세대의 타입이다. 한 테이블에 한 개만 둘 수 있고, SQL 에서 거의 쓸 수 없다.
실측한 제약은 이렇다(실습 08).

```
SQL> SELECT id FROM legacy_note WHERE note LIKE '%본문%';
ORA-00932: inconsistent datatypes: expected CHAR got LONG

SQL> CREATE TABLE legacy_copy AS SELECT * FROM legacy_note;
ORA-00997: illegal use of LONG datatype
```

신규 설계에서는 쓰지 않고, 기존 컬럼은 `ALTER TABLE ... MODIFY (col CLOB)` 또는 `TO_LOB` 으로 전환한다.

---

## 2. 타입별 소개

### 2-1. BLOB — 이진 대용량 객체

이미지·PDF·압축파일처럼 **바이트 열 그대로** 보관한다. 문자집합 변환이 없다.

- 데이터베이스 안에 저장되고 **트랜잭션·복구·백업의 대상**이다(REDO/UNDO 를 남긴다).
- 길이 단위는 바이트. `DBMS_LOB.GETLENGTH` 가 바이트 수를 돌려준다.
- 적용 : 첨부파일, 서명 이미지, 직렬화한 바이너리, 암호화가 필요한 원문.

### 2-2. CLOB — 문자 대용량 객체

데이터베이스 문자집합(`NLS_CHARACTERSET`)으로 해석되는 문자열을 담는다.

- 길이 단위는 문자. `LENGTH`·`DBMS_LOB.GETLENGTH` 모두 문자 수다.
- **가변폭 문자집합(AL32UTF8 등)에서는 내부적으로 문자당 2바이트(UCS-2)로 저장한다.**
  그래서 `LENGTHB` 를 쓰면 막힌다(실측).
  ```
  SQL> SELECT LENGTHB(c) FROM c_1982 WHERE id=1;
  ORA-22998: CLOB or NCLOB in multibyte character set not supported
  ```
  이 성질이 인라인 저장 한계(3-2)와 저장 용량 산정에 그대로 영향을 준다.
- 적용 : 본문·설명·JSON·XML·로그 텍스트.

### 2-3. NCLOB — 국가문자집합 대용량 객체

`NLS_NCHAR_CHARACTERSET`(이 랩은 `AL16UTF16`)으로 저장한다. 항상 고정폭 2바이트다.

- DB 문자집합이 다국어를 담지 못할 때(예: `KO16MSWIN949`) 쓰는 타입이다.
- DB 문자집합이 이미 `AL32UTF8` 이면 **CLOB 으로 충분하고 NCLOB 을 쓸 이유가 거의 없다.**
  실측에서도 같은 한글 5자를 두 컬럼에 넣으면 길이가 같다.
  ```
  CLOB_CHARS NCLOB_CHARS      LEN_C
  ---------- ----------- ----------
           5           5          5
  ```
- 적용 : 레거시 DB 문자집합을 바꿀 수 없는 환경의 다국어 컬럼.

### 2-4. BFILE — 외부 파일 포인터

파일은 OS 파일시스템에 두고, 데이터베이스는 **디렉터리 객체 이름 + 파일명만** 보관한다.

- **읽기 전용**이다. `DBMS_LOB.WRITEAPPEND` 같은 쓰기 API 는 타입이 맞지 않아 컴파일 단계에서 막힌다.
  ```
  PLS-00306: wrong number or types of arguments in call to 'WRITEAPPEND'
  ```
- **트랜잭션 통제를 받지 않는다.** OS 파일이 바뀌면 조회 결과도 즉시 바뀌고(12288 → 20480 바이트 실측),
  파일이 사라지면 조회가 실패한다(`ORA-22288`). 롤백해도 파일은 돌아오지 않는다.
- `user_lobs` 에 나타나지 않는다. LOB 세그먼트가 없기 때문이다(실측: BFILE 컬럼은 0건).
- **백업·Data Pump 로 내용이 보존되지 않는다.** 포인터만 오간다(실습 08 에서 실측).
- 적용 : 수백 MB 이상의 동영상·원본 스캔 이미지처럼 DB 밖에 두는 것이 합리적이고, 변경되지 않으며,
  파일 관리 책임이 애플리케이션/스토리지에 있는 경우.

### 2-5. 임시 LOB — 세션 수명의 작업용 LOB

`DBMS_LOB.CREATETEMPORARY` 로 만들어 가공에 쓰는 LOB 이다. 테이블에 속하지 않는다.

- 임시 테이블스페이스를 쓴다. 실측: 8,000,000 문자 임시 CLOB → 임시 세그먼트 2176 블록(17MB),
  `FREETEMPORARY` 뒤 0 블록.
- `v$temporary_lobs` 로 세션별 개수를 본다(`cache=1`).
- 해제한 로케이터를 다시 쓰면 `ORA-22275: invalid LOB locator specified`.
- 적용 : 여러 소스를 이어 붙여 만드는 보고서 본문, 변환 중간 산출물. **반드시 해제**한다(누수 주의).

---

## 3. 저장 구조와 옵션

### 3-1. 세그먼트 세 개

LOB 컬럼 하나는 **테이블 세그먼트 + LOB 세그먼트 + LOB 인덱스**를 쓴다. 첫 행을 넣을 때 만들어진다(지연 세그먼트 생성).

```
SEGMENT_NAME               SEGMENT_TYPE         KB     BLOCKS
-------------------------- ------------ ---------- ----------
SYS_IL0000074644C00003$$   LOBINDEX             64          8
SYS_LOB0000074644C00003$$  LOBSEGMENT          128         16
DOC_MASTER                 TABLE                64          8
```

### 3-2. 인라인 저장 — 실측 경계는 3968 바이트

`ENABLE STORAGE IN ROW`(기본)이면 작은 값은 **행 안**에 저장된다. 경계를 넘으면 LOB 세그먼트로 나간다.
같은 데이터를 표 크기로 확인한 실측 결과다(각 300~500행 적재).

| 타입 | 값 크기 | LOB 세그먼트 | 테이블 세그먼트 | 판정 |
|---|---|---|---|---|
| BLOB | 3968 바이트 | 128 KB(초기 그대로) | 2048 KB | 행 안 |
| BLOB | 3969 바이트 | 4288 KB | 64 KB | 행 밖 |
| CLOB | 1984 문자 | 128 KB | 3072 KB | 행 안 |
| CLOB | 1985 문자 | 4288 KB | 64 KB | 행 밖 |

- **한계는 3968 바이트**다. BLOB 은 바이트 수가 그대로 기준이고,
  **CLOB·NCLOB 은 문자당 2바이트로 계산**되므로 `3968 / 2 = 1984 문자`가 경계다.
  ASCII 만 들어 있어도 같다(측정값 그대로).
- `DISABLE STORAGE IN ROW` 를 주면 크기와 무관하게 항상 LOB 세그먼트로 나간다.
- 판단 기준
  - 값이 대부분 작고 **행과 함께 자주 읽는다** → `ENABLE STORAGE IN ROW` (기본). 행 한 번 읽기로 끝난다.
  - 값이 크고 **LOB 을 읽지 않는 조회가 많다** → `DISABLE STORAGE IN ROW`.
    테이블 세그먼트가 작아져 전체 스캔이 빨라진다(위 표에서 64 KB vs 3072 KB).

### 3-3. SecureFile 과 BasicFile

| 구분 | BasicFile (구) | SecureFile (11g~, 19c 기본) |
|---|---|---|
| 지정 | `STORE AS BASICFILE` | `STORE AS SECUREFILE` |
| 전제 | 모든 테이블스페이스 | **ASSM 테이블스페이스만** |
| 이전 버전 공간 | `PCTVERSION` | `RETENTION` (`AUTO`/`MIN`/`MAX`/`NONE`) |
| 중복 제거 | 없음 | `DEDUPLICATE` |
| 압축 | 없음 | `COMPRESS LOW/MEDIUM/HIGH` |
| 암호화 | 없음(TDE 테이블스페이스 수준만) | `ENCRYPT USING 'AES256'` 등 컬럼 단위 |
| `SHRINK SPACE` | 가능 | **불가** (`ORA-10635`) |

`db_securefile` 파라미터가 기본값을 정한다. 19c 기본은 `PREFERRED`(가능하면 SecureFile).

실측한 제약들 :

```
-- MSSM 테이블스페이스에 SecureFile
ORA-43853: SECUREFILE lobs cannot be used in non-ASSM tablespace "LOBMSSM"

-- BasicFile 에 SecureFile 전용 절(COMPRESS/DEDUPLICATE)
ORA-43856: Unsupported LOB type for SECUREFILE LOB operation

-- SecureFile 에 BasicFile 전용 절(PCTVERSION)
ORA-22853: invalid LOB storage option specification
```

### 3-4. 중복 제거·압축·암호화의 공간 효과 (실측)

같은 내용 200건(각 102,400 문자, 반복 텍스트)을 여섯 구성에 적재한 결과다.

| 구성 | LOB 세그먼트 | 기본 대비 |
|---|---|---|
| 기본 (SecureFile) | 48.19 MB | 1.00 |
| `ENCRYPT USING 'AES256'` | 48.19 MB | 1.00 (크기 변화 없음) |
| `COMPRESS LOW` | 3.19 MB | 0.07 |
| `COMPRESS MEDIUM` | 3.19 MB | 0.07 |
| `COMPRESS HIGH` | 3.19 MB | 0.07 |
| `DEDUPLICATE` | 1.19 MB | 0.02 |

읽는 법
- 이 데이터는 반복 문자열이라 LOW/MEDIUM/HIGH 차이가 나타나지 않았다.
  **압축률은 데이터에 달렸다.** 이미 압축된 이미지·동영상은 거의 줄지 않는다.
- 중복 제거는 200건이 완전히 동일할 때의 극단값이다. 실무에서는 같은 첨부가 여러 행에 붙는 경우
  (메일 첨부, 공통 양식)에만 이만큼 효과가 난다.
- 암호화는 크기를 바꾸지 않는다. 비용은 CPU 와 키 관리다.

> **라이선스** — `COMPRESS`(SecureFiles Compression/Deduplication)는 **Advanced Compression**,
> `ENCRYPT` 는 **Advanced Security** 옵션이다. EE 바이너리에서 명령이 실행되는 것과 라이선스가 있는 것은
> 별개다. 운영 적용 전 계약을 확인한다. (이 랩은 학습 목적이며 `dba_feature_usage_statistics` 에 사용 흔적이 남는다)

### 3-5. CACHE / NOCACHE — 버퍼 캐시 사용

기본은 `NOCACHE`. LOB 블록을 버퍼 캐시에 남기지 않는다.
같은 100 KB LOB 50건을 두 번 읽어 물리 읽기를 측정한 결과다.

| 구성 | 1회차 | 2회차 |
|---|---|---|
| `NOCACHE` | 100 블록 | 100 블록 |
| `CACHE` | 0 블록 | 0 블록 |

- `NOCACHE` 는 매번 디스크에서 읽는다. 큰 LOB 을 한 번씩 스트리밍하는 용도에 맞다.
- `CACHE` 는 캐시에 남긴다. 작고 자주 읽는 LOB(썸네일, 공통 양식)에 맞다.
  단, 버퍼 캐시를 LOB 이 밀어낼 수 있다.
- `CACHE READS` 는 읽기만 캐시한다.

### 3-6. LOGGING / NOLOGGING / FILESYSTEM_LIKE_LOGGING — 리두 생성량

20건 × 200 KB(약 4 MB)를 적재하며 세션 리두를 측정했다.

| 구성 | 리두 | 비고 |
|---|---|---|
| `LOGGING` (기본) | 6.45 MB | 데이터 + 메타데이터 전부 기록 |
| `NOLOGGING` | 3.06 MB | LOB 데이터는 기록하지 않음. 메타데이터·UNDO 는 남는다 |
| `FILESYSTEM_LIKE_LOGGING` | 3.06 MB | SecureFile 전용. 메타데이터만 기록 |

- `NOLOGGING` 으로 적재한 LOB 은 **복구할 수 없다.** 적재 직후 백업이 필수다.
  (ARCHIVELOG + `FORCE LOGGING` 이면 이 설정은 무시된다)
- `user_lobs.LOGGING` 은 `NOLOGGING` 과 `FILESYSTEM_LIKE_LOGGING` 을 모두 `NO` 로 보여 준다(실측).
  구분이 필요하면 DDL(`dbms_metadata.get_ddl`)을 확인한다.

### 3-7. RETENTION — 이전 버전 보관

SecureFile 은 `PCTVERSION` 대신 `RETENTION` 을 쓴다. 기본은 `DEFAULT`(= UNDO 보존 설정 따름).

| 값 | 뜻 |
|---|---|
| `AUTO` | UNDO 보존 시간에 맞춰 자동 |
| `MIN n` | 최소 n 초 |
| `MAX` | `MAXSIZE` 한도까지 |
| `NONE` | 이전 버전을 보관하지 않음 (읽기 일관성 실패 위험) |

실측 : `ALTER TABLE s_plain MODIFY LOB (c) (RETENTION NONE)` → `user_lobs.retention_type` 이 `DEFAULT` → `NONE`.

---

## 4. 다루는 방법

### 4-1. SQL 만으로 되는 것과 안 되는 것

| 작업 | 가능 여부 | 실측 |
|---|---|---|
| `INSERT` / `UPDATE` (4000 바이트 이하 리터럴) | 가능 | |
| 4000 바이트 초과 **단일 리터럴** | 불가 | `ORA-01704: string literal too long` |
| `SET LONG` 으로 조회 | 가능 | SQL*Plus 기본 80바이트만 보여 준다 |
| `LENGTH` / `SUBSTR` / `INSTR` / `LIKE` | 가능 | CLOB 대상. `SUBSTR` 은 CLOB 을 돌려준다 |
| `=` 비교 | **불가** | `ORA-00932: inconsistent datatypes: expected - got CLOB` |
| `DISTINCT` / `ORDER BY` / `GROUP BY` | **불가** | 같은 `ORA-00932` |
| 인덱스 생성 | **불가** | `ORA-02327: cannot create index on expression with datatype LOB` |
| `LENGTHB`(멀티바이트 CLOB) | **불가** | `ORA-22998` |

- 4000 바이트 초과 값을 SQL 로 넣어야 하면 `TO_CLOB(...) || TO_CLOB(...)` 로 이어 붙이거나
  PL/SQL 변수(최대 32767)를 바인드한다. SQL*Plus 스크립트에서는 한 줄이 4999자를 넘으면
  `SP2-0027: Input is too long (> 4999 characters) - line ignored` 가 먼저 난다(실측).
- 전문 검색이 필요하면 **Oracle Text 인덱스**(`CREATE INDEX ... INDEXTYPE IS CTXSYS.CONTEXT`)를 쓴다.
  일반 B-tree 인덱스는 만들 수 없다.

### 4-2. 표준 적재 패턴 — EMPTY_LOB + RETURNING + WRITEAPPEND

LOB 은 "행을 먼저 만들고 로케이터를 받아 쓰는" 순서가 기본이다.

```sql
DECLARE v_c CLOB;
BEGIN
  INSERT INTO article VALUES (2, 'EMPTY_CLOB 방식', EMPTY_CLOB(), NULL) RETURNING body INTO v_c;
  FOR i IN 1..10 LOOP
    DBMS_LOB.WRITEAPPEND(v_c, 1000, RPAD('L'||TO_CHAR(i,'FM00'),1000,'.'));
  END LOOP;
  COMMIT;
END;
```

### 4-3. DBMS_LOB 주요 프로시저

| 분류 | 프로시저 | 메모 |
|---|---|---|
| 조회 | `GETLENGTH` `SUBSTR` `INSTR` `COMPARE` `ISOPEN` `GETCHUNKSIZE` `GET_STORAGE_LIMIT(loc)` | `SUBSTR` 은 최대 32767 |
| 쓰기 | `WRITE`(오프셋 덮어쓰기) `WRITEAPPEND` `APPEND` `COPY` `ERASE` `TRIM` | `ERASE` 는 지운 자리를 공백/0 으로 채운다 |
| SecureFile 전용 | `FRAGMENT_INSERT` `FRAGMENT_DELETE` `FRAGMENT_MOVE` `FRAGMENT_REPLACE` | 길이가 실제로 늘거나 줄어든다 |
| 임시 LOB | `CREATETEMPORARY` `ISTEMPORARY` `FREETEMPORARY` | 해제 후 사용 시 `ORA-22275` |
| 파일 | `BFILENAME`(SQL 함수) `FILEOPEN` `FILECLOSE` `FILEEXISTS` `FILEGETNAME` `FILEISOPEN` | BFILE 전용 |
| 적재·변환 | `LOADBLOBFROMFILE` `LOADCLOBFROMFILE` `CONVERTTOBLOB` `CONVERTTOCLOB` | 문자집합 ID 와 warning 출력 인자 필요 |
| 잠금 최적화 | `OPEN` / `CLOSE` | 인덱스 갱신을 지연시킨다 |

`ERASE` 와 `FRAGMENT_DELETE` 의 차이(실측) :

```
WRITE/ERASE/TRIM 후 앞 30문자=[HELLOAAAAA          AAAAAAAAAA]   -- ERASE 는 자리를 비운다(길이 유지)
FRAGMENT_INSERT 후 길이=106                                       -- 실제로 6문자 늘어난다
FRAGMENT_DELETE 후 길이=100                                       -- 실제로 6문자 줄어든다
```

### 4-4. 파일에서 적재하기

```sql
DECLARE
  v_c CLOB; v_f BFILE := BFILENAME('LOB_DIR','manual.txt');
  d_off INTEGER := 1; s_off INTEGER := 1; lang INTEGER := 0; warn INTEGER;
BEGIN
  INSERT INTO file_store (...) VALUES (..., EMPTY_CLOB()) RETURNING text_content INTO v_c;
  DBMS_LOB.FILEOPEN(v_f, DBMS_LOB.FILE_READONLY);
  DBMS_LOB.LOADCLOBFROMFILE(v_c, v_f, DBMS_LOB.LOBMAXSIZE, d_off, s_off,
                            NLS_CHARSET_ID('AL32UTF8'), lang, warn);
  DBMS_LOB.FILECLOSE(v_f);
END;
```

실측 결과 : 7,566 바이트 UTF-8 파일 → **CLOB 5,154 문자**, `warning=0`.
즉 `s_off` 는 읽은 **바이트**, `GETLENGTH` 는 저장된 **문자** 수다. 둘을 혼동하면 적재 검증이 틀어진다.
BLOB 은 변환이 없으므로 12,288 바이트 파일이 그대로 12,288 바이트가 된다.

### 4-5. 로케이터와 트랜잭션 — 세 가지 규칙

| 상황 | 결과 (실측) |
|---|---|
| `SELECT` 로 받은 로케이터로 **쓰기** (행 잠금 없음) | `ORA-22920: row containing the LOB value is not locked` |
| `FOR UPDATE` 로 잠근 뒤 **커밋하고** 그 로케이터로 쓰기 | `ORA-22990: LOB locators cannot span transactions` |
| 읽기용 로케이터를 받은 뒤 커밋하고 **읽기** | 정상. 커밋 전 길이 100 = 커밋 후 100 |
| 값이 바뀐 뒤 **예전 로케이터**로 읽기 | 예전 값(100)이 보인다. 현재 값은 200 — 읽기 일관성 |

정리하면 **쓰려면 같은 트랜잭션 안에서 행을 잠근 채**, 읽기는 스냅숏처럼 동작한다.

---

## 5. 공간 관리

### 5-1. 실제 사용량 보기

`dba_segments` 는 할당된 크기만 보여 준다. SecureFile 의 내부 사용량은 `DBMS_SPACE.SPACE_USAGE` 로 본다.

```sql
DBMS_SPACE.SPACE_USAGE(USER, v_seg, 'LOB',
  v_sb, v_sby,    -- segment blocks / bytes
  v_ub, v_uby,    -- used
  v_eb, v_eby,    -- expired   (재사용 가능)
  v_xb, v_xby);   -- unexpired (RETENTION 때문에 아직 못 쓰는 이전 버전)
```

### 5-2. 삭제해도 세그먼트는 줄지 않는다 (실측)

| 시점 | 세그먼트 | 사용 | 만료 | 미만료 |
|---|---|---|---|---|
| 100건 적재 후 | 3088 블록 (24.1 MB) | 2600 | 409 | 0 |
| 90건 삭제 후 | 3088 블록 (24.1 MB) | 260 | 409 | 2340 |
| `MOVE LOB` 후 | **400 블록 (3.1 MB)** | 260 | 68 | 0 |

- 삭제는 공간을 **재사용 가능 상태로만** 바꾼다. 파일 크기는 그대로다.
- SecureFile 은 `SHRINK SPACE` 를 지원하지 않는다.
  ```
  SQL> ALTER TABLE s_plain MODIFY LOB (c) (SHRINK SPACE);
  ORA-10635: Invalid segment or tablespace type
  ```
- 회수는 `ALTER TABLE ... MOVE LOB (c) STORE AS (TABLESPACE ...)` 로 재작성한다.
  온라인 작업이 필요하면 `DBMS_REDEFINITION` 을 쓴다.
- BasicFile 은 `SHRINK SPACE` 가 동작한다(실측: 21 MB → 0.06 MB).

### 5-3. 속성 변경은 즉시 줄지 않는다 (실측)

기존 LOB 에 `DEDUPLICATE`·`COMPRESS` 를 걸면 세그먼트가 재작성되지만 **파일 크기는 그대로 남는다.**

| 시점 | 세그먼트 | 사용 | 만료 | 미만료 |
|---|---|---|---|---|
| `ALTER ... (DEDUPLICATE)` + `(COMPRESS HIGH)` 직후 | 2072 블록 (16.2 MB) | 638 | 692 | 663 |
| 이어서 `MOVE LOB` | **144 블록 (1.1 MB)** | **1** | 77 | 0 |

동일 내용 50건이 최종적으로 1 블록으로 줄었다. **속성 변경 → `MOVE` 로 마무리**가 실무 순서다.

### 5-4. LOB 만 다른 테이블스페이스로

```sql
ALTER TABLE s_plain MOVE LOB (c) STORE AS (TABLESPACE users);   -- LOB 세그먼트만 이동
```

테이블은 그대로 두고 LOB 만 옮길 수 있다. 백업 정책·디스크 등급을 LOB 만 다르게 할 때 쓴다.

---

## 6. Data Pump 와 백업

실측(`expdp`/`impdp`, 3개 테이블) 결과와 주의점이다.

```
. . exported "LOBLAB"."EXT_DOC"       5.992 KB   3 rows      ← BFILE : 포인터만
. . exported "LOBLAB"."FILE_STORE"    36.36 KB   3 rows
. . exported "LOBLAB"."S_ENC"         39.07 MB 200 rows      ← 암호화 LOB
덤프 파일 41,254,912 바이트, 31초 / 들여오기 15초
```

| 항목 | 결과 |
|---|---|
| BLOB/CLOB 데이터 | 그대로 보존 (들여온 뒤 길이 일치) |
| SecureFile 속성(`securefile`/`encrypt`) | 보존 |
| BFILE | **포인터만 이동.** 들여온 뒤 OS 파일을 옮기면 `FILEEXISTS`=0 |
| 암호화 LOB 을 기본 옵션으로 반출 | `ORA-39173: Encrypted data has been stored unencrypted in dump file set.` |

- 암호화 컬럼을 반출할 때는 `ENCRYPTION=ENCRYPTED_COLUMNS_ONLY ENCRYPTION_PASSWORD=...`
  (또는 `ENCRYPTION=ALL`)을 지정한다. 지정하면 위 경고가 사라진다(실측).
- BFILE 을 쓰는 시스템은 **DB 백업과 파일 백업을 따로 맞춰야 한다.** DB 만 복구하면 포인터만 살아난다.
- `NOLOGGING` 으로 적재한 LOB 은 미디어 복구로 되살아나지 않는다. 적재 직후 백업한다.

---

## 7. 적용 기준 — 무엇을 어떻게 고르는가

### 7-1. 타입 선택

```
값이 문자인가?
├─ 아니다(이진) ─────────────── BLOB
└─ 그렇다
   ├─ DB 문자집합이 그 언어를 담는가?
   │   ├─ 그렇다 ─────────────── CLOB
   │   └─ 아니다 ─────────────── NCLOB
   └─ 파일이 DB 밖에 있어야 하는가(수백 MB 이상·불변·외부 관리)?
       └─ 그렇다 ─────────────── BFILE (읽기 전용·백업 별도)
```

### 7-2. 저장 옵션 선택

| 상황 | 선택 |
|---|---|
| 값이 대부분 작고(≤3968 B) 행과 함께 읽는다 | `ENABLE STORAGE IN ROW` (기본) |
| 값이 크고 LOB 없는 조회가 잦다 | `DISABLE STORAGE IN ROW` |
| 같은 첨부가 여러 행에 반복된다 | `DEDUPLICATE` |
| 텍스트·로그처럼 압축이 잘 되는 내용 | `COMPRESS MEDIUM` (이미 압축된 미디어는 효과 없음) |
| 개인정보·계약서 | `ENCRYPT USING 'AES256'` + 지갑 관리 + Data Pump 시 `ENCRYPTION_PASSWORD` |
| 작고 자주 읽는다 | `CACHE` |
| 크고 한 번씩 스트리밍한다 | `NOCACHE` (기본) |
| 초기 대량 적재 | `NOLOGGING` 으로 적재 → **직후 백업** → `LOGGING` 복귀 |

### 7-3. 설계 점검 목록

- [ ] LOB 을 담을 테이블스페이스를 따로 뒀는가 (백업·이동·용량 관리 단위 분리)
- [ ] ASSM 테이블스페이스인가 (SecureFile 전제)
- [ ] 인라인 여부를 값 크기 분포로 결정했는가 (평균이 아니라 분포)
- [ ] 검색이 필요하면 Oracle Text 를 계획했는가 (B-tree 인덱스는 불가)
- [ ] 애플리케이션이 로케이터 규칙(`FOR UPDATE`, 트랜잭션 경계)을 지키는가
- [ ] 임시 LOB 을 `FREETEMPORARY` 로 해제하는가
- [ ] 삭제가 많은 테이블의 공간 회수 주기(`MOVE`)를 정했는가
- [ ] BFILE 이면 파일 백업·경로 이관 절차가 있는가
- [ ] 압축·암호화의 라이선스를 확인했는가

---

## 8. 오류 사전 (이 과정에서 실제로 재현한 것)

| 오류 | 상황 | 대응 |
|---|---|---|
| `ORA-01704: string literal too long` | 4000 바이트 초과 단일 리터럴 | `TO_CLOB` 이어 붙이기 / PL/SQL 바인드 |
| `SP2-0027: Input is too long (> 4999 characters)` | SQL*Plus 한 줄이 4999자 초과 | 줄을 나눈다 |
| `ORA-00932: inconsistent datatypes: expected - got CLOB` | LOB 비교·`DISTINCT`·`ORDER BY` | `DBMS_LOB.COMPARE` / 해시 컬럼 별도 보관 |
| `ORA-02327: cannot create index on expression with datatype LOB` | LOB 에 인덱스 | Oracle Text 인덱스 |
| `ORA-22998: CLOB or NCLOB in multibyte character set not supported` | 멀티바이트 CLOB 에 `LENGTHB` | `DBMS_LOB.GETLENGTH`(문자) 사용 |
| `ORA-22920: row containing the LOB value is not locked` | 잠금 없이 LOB 쓰기 | `SELECT ... FOR UPDATE` |
| `ORA-22990: LOB locators cannot span transactions` | 커밋 뒤 예전 로케이터로 쓰기 | 트랜잭션 안에서 다시 조회 |
| `ORA-22275: invalid LOB locator specified` | `FREETEMPORARY` 뒤 사용 | 로케이터 재생성 |
| `ORA-22288: file or LOB operation FILEOPEN/GETLENGTH failed` | BFILE 대상 파일 없음 | 파일 복구 또는 `FILEEXISTS` 선검사 |
| `ORA-22285: non-existent directory or file for FILEOPEN operation` | 디렉터리 객체 없음/권한 없음 | 디렉터리 객체 생성·`GRANT READ` |
| `ORA-43853: SECUREFILE lobs cannot be used in non-ASSM tablespace` | MSSM 테이블스페이스 | ASSM 테이블스페이스로 |
| `ORA-43856: Unsupported LOB type for SECUREFILE LOB operation` | BasicFile 에 SecureFile 전용 절 | `STORE AS SECUREFILE` 로 |
| `ORA-22853: invalid LOB storage option specification` | SecureFile 에 `PCTVERSION` | `RETENTION` 으로 |
| `ORA-10635: Invalid segment or tablespace type` | SecureFile 에 `SHRINK SPACE` | `MOVE LOB` 로 재작성 |
| `ORA-06502 ... raw variable length too long` | `UTL_RAW.CAST_TO_RAW` 2000 바이트 초과 | 나눠서 `WRITEAPPEND` |
| `ORA-22921: length of input buffer is smaller than amount requested` | `WRITEAPPEND` 의 amount > 버퍼 길이 | 버퍼 길이와 amount 를 맞춘다 |
| `ORA-00997: illegal use of LONG datatype` | `CTAS` 로 LONG 복제 | `TO_LOB` 사용 |
| `ORA-39173: Encrypted data has been stored unencrypted in dump file set.` | 암호화 LOB 기본 반출 | `ENCRYPTION_PASSWORD` 지정 |

---

## 9. 실습 구성

| # | 파일 | 주제 | 핵심 실측 |
|---|---|---|---|
| 01 | `LOB_실습_01_타입과_저장구조.txt` | 네 타입 생성, 딕셔너리, 세그먼트 3종, 인라인 경계 | 3968 바이트 / 1984 문자 |
| 02 | `LOB_실습_02_CLOB_조작과_SQL한계.txt` | `EMPTY_CLOB`+`RETURNING`, 읽기·쓰기 API, SQL 제약 | `ORA-01704`, `ORA-00932`, `ORA-02327` |
| 03 | `LOB_실습_03_BLOB_파일적재와_변환.txt` | 디렉터리 객체, `LOADBLOBFROMFILE`/`LOADCLOBFROMFILE`, `CONVERTTOBLOB` | 7566 바이트 → 5154 문자 |
| 04 | `LOB_실습_04_BFILE.txt` | BFILE 의 읽기 전용·비트랜잭션 성질 | `ORA-22288`, `ORA-22285` |
| 05 | `LOB_실습_05_임시LOB와_로케이터.txt` | 임시 LOB, 임시 테이블스페이스, 로케이터 규칙 | `ORA-22275`, `ORA-22920`, `ORA-22990` |
| 06 | `LOB_실습_06_SecureFile_옵션.txt` | BasicFile/SecureFile, 중복 제거·압축·암호화 | 48.19 → 3.19 → 1.19 MB |
| 07 | `LOB_실습_07_공간관리와_성능.txt` | `SPACE_USAGE`, `SHRINK` 제약, `MOVE`, 리두·캐시 | 24.1 → 3.1 MB, 리두 6.45 vs 3.06 MB |
| 08 | `LOB_실습_08_LONG전환과_DataPump.txt` | `LONG`→`CLOB`, Data Pump, BFILE·암호화 주의 | `ORA-00997`, `ORA-39173` |

실습은 순서대로 진행한다. 01 이 만든 계정·테이블스페이스를 이후 실습이 쓴다.

강의용 슬라이드는 `LOB_대용량객체_실습과정.pptx` (48장) 이다. 1부 LOB 이란 · 2부 타입 · 3부 저장 구조 · 4부 다루는 방법 · 5부 공간과 성능 · 6부 전환과 이관 순서이며, 이 문서의 1~6절과 같은 구성이다. 모든 슬라이드에 발표자 노트가 들어 있다.

### 실습 환경 준비 (SYS 로 한 번)

```sql
SYS@orcl> CREATE TABLESPACE lobtbs DATAFILE '/u01/app/oracle/oradata/orcl/lobtbs01.dbf'
  2    SIZE 200M AUTOEXTEND ON NEXT 50M MAXSIZE 1G
  3    EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO;
SYS@orcl> CREATE TABLESPACE lobmssm DATAFILE '/u01/app/oracle/oradata/orcl/lobmssm01.dbf'
  2    SIZE 20M EXTENT MANAGEMENT LOCAL UNIFORM SIZE 64K SEGMENT SPACE MANAGEMENT MANUAL;
SYS@orcl> CREATE USER loblab IDENTIFIED BY oracle_4U DEFAULT TABLESPACE lobtbs
  2    QUOTA UNLIMITED ON lobtbs QUOTA UNLIMITED ON lobmssm QUOTA UNLIMITED ON users;
SYS@orcl> GRANT CREATE SESSION, CREATE TABLE, CREATE PROCEDURE, CREATE SEQUENCE, CREATE VIEW TO loblab;
SYS@orcl> GRANT SELECT ON v_$temporary_lobs TO loblab;
SYS@orcl> GRANT SELECT ON v_$sort_usage     TO loblab;   -- v$tempseg_usage 의 기반 뷰
SYS@orcl> GRANT SELECT ON v_$session        TO loblab;
SYS@orcl> GRANT SELECT ON v_$mystat         TO loblab;
SYS@orcl> GRANT SELECT ON v_$statname       TO loblab;
SYS@orcl> CREATE OR REPLACE DIRECTORY lob_dir AS '/home/oracle/lobfiles';
SYS@orcl> GRANT READ, WRITE ON DIRECTORY lob_dir TO loblab;
```

```bash
[oracle@oel7v9 ~]$ mkdir -p /home/oracle/lobfiles
```

### 실습 뒤 정리

```sql
SYS@orcl> DROP USER loblab CASCADE;
SYS@orcl> DROP TABLESPACE lobtbs  INCLUDING CONTENTS AND DATAFILES;
SYS@orcl> DROP TABLESPACE lobmssm INCLUDING CONTENTS AND DATAFILES;
SYS@orcl> DROP DIRECTORY lob_dir;
```

```bash
[oracle@oel7v9 ~]$ rm -rf /home/oracle/lobfiles
```
