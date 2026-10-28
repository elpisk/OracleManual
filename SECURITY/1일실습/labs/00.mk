@H1 Oracle 19c Security 1일 실습 트랜스크립트
@H2 과정 개요
@B 인증, 접근 통제, 데이터 보호, 암호화, 감사의 다섯 축을 하루 동안 실습 10개로 훑는다.
@B 대상은 SQL·PL/SQL·Database Administration 과정을 마친 학습자다. 사용자 생성, 권한 부여, 리스너 기동 같은 기본 작업은 설명 없이 진행한다.
@B 실습마다 앞에서 원리와 내부 동작을 정리하고, 뒤에 OEL7V9에서 실제로 실행한 스크립트와 출력을 싣는다.
@B 출력은 실측 그대로다. 같은 명령을 실행하면 시각, SID, 해시값, 인증서 일련번호 같은 값만 다르게 나온다.
@B 성공 흐름만 담지 않았다. 실습마다 의도된 오류를 하나 이상 일으키고 그 원인을 딕셔너리 뷰나 트레이스로 확인한다. 실무에서 먼저 만나는 것은 대개 오류 쪽이다.

@H2 시간표
@TBL
시간 | 실습 | 주제 | 축
09:00~09:30 | 01 | 지갑으로 배치 스크립트의 비밀번호 없애기 (SEPS) | 인증
09:30~10:00 | 02 | 프록시 인증과 실제 사용자 추적 | 인증
10:10~10:40 | 03 | Secure Application Role로 역할 활성화 통제 | 권한
10:40~11:10 | 04 | 네트워크 ACL로 외부 호출 통제 | 권한
11:20~12:10 | 05 | Application Context와 VPD로 행·컬럼 통제 | 접근 통제
13:10~13:50 | 06 | Data Redaction으로 조회 결과 가리기 | 데이터 보호
13:50~14:30 | 07 | DBMS_CRYPTO로 컬럼 암호화 패키지 만들기 | 암호화
14:40~15:30 | 08 | TDE 키스토어와 테이블스페이스 암호화 | 암호화
15:40~16:40 | 09 | TLS로 접속 구간 암호화와 인증서 로그인 | 암호화
16:50~17:40 | 10 | FGA·통합 감사와 감사 기록 관리 | 감사
@END

@H2 실습 환경
@TBL
항목 | 값
서버 | OEL7V9 (Oracle Linux 7.9, 172.16.225.50)
DB | Oracle Database 19.3 Enterprise Edition, non-CDB, SID orcl, ARCHIVELOG
감사 모드 | 혼합 모드(mixed). `audit_trail=DB`, 통합 감사 정책 ORA_SECURECONFIG·ORA_LOGON_FAILURES 활성
샘플 스키마 | HR(비밀번호 hr), SCOTT(비밀번호 tiger)
OS 계정 | oracle(DB 소유자), root(09 실습의 일부 확인용)
실습 08 | DBCA로 만든 임시 DB d08tde. 키스토어가 한 번도 없던 DB에서 시작해야 흐름이 맞기 때문이다
@END
@B 프롬프트는 `사용자@접속식별자>` 형식이다. `SYS@orcl>`은 `sqlplus / as sysdba`, `HR@orcl>`은 HR 로컬 접속을 뜻한다.
@B 셸 프롬프트 `[oracle@oel7v9 디렉터리]$`는 oracle OS 계정이다.
@B 실습끼리는 서로 의존하지 않는다. 각 실습은 시작할 때 필요한 객체를 만들고, 끝날 때 모두 지운 다음 지워졌는지 조회로 확인한다. 순서를 바꾸거나 일부만 골라 진행해도 된다.
@B 객체 이름에는 실습 번호 접두사(`D01_`~`D10_`, 사용자는 `d01_app` 식)를 붙였다. 다른 실습이나 기존 객체와 겹치지 않게 하기 위해서다.

@NOTE 실습 전 공통 확인
공용 네트워크 설정 파일(`$ORACLE_HOME/network/admin`의 sqlnet.ora·listener.ora·tnsnames.ora)은 실습 전에 백업한다. 01·09 실습의 클라이언트 설정은 실습 전용 TNS_ADMIN 디렉터리에 두므로 공용 파일을 바꾸지 않는다. 09 실습은 listener.ora에 별도 리스너 항목을 넣었다가 끝에서 되돌린다.
@END

@P 백업 명령 (출력 없음)
@CODE
cd $ORACLE_HOME/network/admin
for f in sqlnet listener tnsnames; do cp -p $f.ora $f.ora.bak_day1; done
@END
