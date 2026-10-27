@H1 제1장  Secure External Password Store

@H2 1.1  학습 목표

@P 배치 스크립트, 백업 작업, 애플리케이션 설정 파일에는 데이터베이스 접속 비밀번호가 평문으로 들어가기 쉽다. Secure External Password Store(SEPS)는 이 비밀번호를 클라이언트 쪽 지갑에 암호화해 두고, 접속할 때 지갑에서 꺼내 쓰게 한다.

@B 스크립트와 애플리케이션에서 비밀번호가 노출되는 경로를 설명하고, SEPS가 그중 무엇을 막는지 말할 수 있다.
@B Oracle Wallet을 이루는 파일(ewallet.p12, cwallet.sso)의 역할과 auto-login, local auto-login의 차이를 설명할 수 있다.
@B `mkstore`로 지갑을 만들고 자격 증명을 등록·조회·수정·삭제할 수 있다.
@B `sqlnet.ora`의 `WALLET_LOCATION`, `SQLNET.WALLET_OVERRIDE`와 `tnsnames.ora` 별칭을 구성해 `/@별칭` 형식으로 접속할 수 있다.
@B 자격 증명이 접속 문자열 단위로 저장된다는 규칙을 알고, 한 데이터베이스에 여러 계정을 연결하는 방법을 설계할 수 있다.
@B 비밀번호 변경, 지갑 파일 권한, 지갑 복사처럼 운영 중에 생기는 문제를 진단하고 대처할 수 있다.

@H2 1.2  SEPS의 개념

@H3 1.2.1  비밀번호가 새는 경로

@B 가장 흔한 형태는 셸 스크립트 안의 `sqlplus scott/tiger@orcl`이다. 스크립트 파일을 읽을 수 있는 사람은 누구나 비밀번호를 본다.
@B 명령행 인자로 넘긴 비밀번호는 실행 중에 `ps -ef` 출력에 보인다. 같은 서버의 다른 OS 사용자도 볼 수 있다.
@B 셸 히스토리 파일(`.bash_history`)에도 명령이 그대로 남는다.
@B 애플리케이션 설정 파일, 크론 작업 정의, 형상 관리 저장소에 올라간 스크립트도 같은 문제를 안고 있다. 저장소에 한 번 올라간 비밀번호는 이력에서 지우기 어렵다.
@B 비밀번호를 바꾸면 그 비밀번호를 적어 둔 모든 파일을 찾아 고쳐야 한다. 하나라도 빠뜨리면 배치가 실패하고, 실패한 로그인이 반복되면 계정이 잠긴다.

@H3 1.2.2  SEPS의 동작 방식

@P SEPS는 클라이언트 쪽 기능이다. 데이터베이스 서버는 SEPS가 쓰였는지 알지 못하고, 평소처럼 사용자 이름과 비밀번호를 받아 인증한다.

@TBL
단계 | 하는 일
1. 접속 요청 | 사용자가 `sqlplus /@seps_app`처럼 사용자 이름과 비밀번호 없이 접속 문자열만 준다
2. 지갑 찾기 | 클라이언트가 `sqlnet.ora`의 `WALLET_LOCATION`에서 지갑 디렉터리를 찾는다
3. 지갑 열기 | auto-login 파일(cwallet.sso)로 비밀번호 입력 없이 지갑을 연다
4. 자격 증명 조회 | 접속 문자열 `seps_app`과 똑같은 이름으로 저장된 사용자 이름·비밀번호를 꺼낸다
5. 인증 | 꺼낸 사용자 이름·비밀번호로 일반 데이터베이스 인증을 수행한다
@END

@B 비밀번호는 지갑 안에 암호화되어 있다. 스크립트, 명령행, 히스토리 어디에도 비밀번호가 나타나지 않는다.
@B `SQLNET.WALLET_OVERRIDE = TRUE`가 있어야 `/@접속문자열` 형식이 지갑의 자격 증명을 쓴다. 기본값은 FALSE다.
@B 접속 형식은 `CONNECT /@db_connect_string`이며 `AS SYSDBA`, `AS SYSOPER`를 붙일 수도 있다.
@B 비밀번호를 바꿀 때는 지갑 하나만 고치면 된다. 그 지갑을 쓰는 모든 스크립트가 다음 접속부터 새 비밀번호를 쓴다.

@H3 1.2.3  다른 방식과의 비교

@TBL
방식 | 비밀번호 저장 위치 | 특징
스크립트에 직접 기록 | 스크립트 파일 | 가장 단순하지만 파일·ps·히스토리로 노출
OS 인증(OPS$) | 없음 | OS 계정이 곧 DB 계정. 원격 접속에 쓰기 어렵고 OS 계정 관리에 종속
SEPS | 클라이언트 지갑 | 일반 DB 계정 그대로 사용. 원격 DB에도 적용. 지갑 파일 보호가 관건
TLS 인증서 인증(11장) | 클라이언트 지갑의 인증서 | 비밀번호 자체가 없음. 서버 쪽 TCPS 구성 필요
@END

@B SEPS는 데이터베이스 쪽 설정을 바꾸지 않는다. 기존 계정과 비밀번호 정책을 그대로 쓰면서 클라이언트에서 비밀번호를 숨긴다.
@B OS 인증은 서버에 로그인한 OS 사용자와 DB 계정을 묶는다. 원격 OS 인증(`REMOTE_OS_AUTHENT`)은 위험해 19c 기본값이 FALSE이고 쓰지 않는 것이 원칙이다.
@B TLS 인증서 인증은 비밀번호가 아예 없어지는 대신 서버와 클라이언트 모두에 인증서 체계가 필요하다. SEPS보다 구성이 무겁다.

@NOTE SEPS가 막지 못하는 것
SEPS는 비밀번호 문자열이 파일과 화면에 드러나는 것을 막는다. 지갑 파일 자체를 손에 넣은 사람은 그 지갑으로 접속할 수 있다.
auto-login 지갑은 비밀번호 없이 열리므로, 지갑 디렉터리를 읽을 수 있는 OS 사용자는 사실상 그 DB 계정의 권한을 가진다. 지갑 파일의 OS 권한 관리가 SEPS 보안의 전부라고 봐도 된다.
@END

@H3 1.2.4  적용 범위

@TBL
대상 | SEPS 사용 | 비고
SQL*Plus, SQL*Loader | 가능 | sqlnet.ora 설정만으로 /@별칭
Data Pump(expdp, impdp) | 가능 | 실습 04에서 확인
RMAN | 가능 | rman target /@별칭, catalog /@별칭
OCI 기반 애플리케이션 | 가능 | 연결 문자열에서 사용자·비밀번호 생략
JDBC Thin | 별도 설정 | 드라이버 연결 속성으로 지갑 지정
DB 링크 | 해당 없음 | 링크 비밀번호는 링크 정의에 저장(5장)
@END

@B SEPS는 클라이언트 프로그램이 접속할 때 쓰는 기능이다. 데이터베이스 서버가 다른 DB로 접속하는 DB 링크는 서버 프로세스가 링크 정의의 자격 증명을 쓰므로 SEPS 지갑과 관계가 없다.
@B 하나의 서버에서 클라이언트 역할을 하는 배치 작업과 DB 링크를 모두 쓰는 경우, 두 곳의 비밀번호를 따로 관리해야 한다는 점을 비밀번호 변경 절차에 반영한다.

@H2 1.3  Oracle Wallet의 구조

@H3 1.3.1  지갑을 이루는 파일

@TBL
파일 | 내용 | 열 때 필요한 것
ewallet.p12 | PKCS#12 형식의 지갑 본체. 비밀번호로 암호화 | 지갑 비밀번호
cwallet.sso | auto-login용 사본. 비밀번호 없이 열림 | 없음(local이면 같은 호스트·같은 OS 사용자)
*.lck | 동시 갱신을 막는 잠금 파일 | 해당 없음
@END

@B 지갑 디렉터리 하나에 ewallet.p12와 cwallet.sso가 함께 있는 것이 일반적인 SEPS 지갑이다.
@B `mkstore`로 자격 증명을 추가·수정하면 두 파일이 함께 갱신된다. 이때 ewallet.p12를 열어야 하므로 지갑 비밀번호를 묻는다.
@B 클라이언트가 접속할 때는 cwallet.sso만 읽는다. 지갑 비밀번호를 묻지 않는 이유다.
@B ewallet.p12를 지우면 cwallet.sso로 접속은 계속되지만 자격 증명을 고칠 방법이 없어진다. 두 파일은 함께 백업한다.

@H3 1.3.2  auto-login과 local auto-login

@B auto-login 지갑(cwallet.sso)은 어느 호스트로 복사해도 열린다. 지갑 디렉터리를 통째로 복사하면 다른 서버에서도 같은 DB 계정으로 접속할 수 있다.
@B local auto-login 지갑은 만든 호스트와 만든 OS 사용자에서만 열린다. 다른 서버로 복사하면 열리지 않는다.
@B `orapki wallet create -wallet 디렉터리 -auto_login_local`로 처음부터 local auto-login 지갑을 만들 수 있다. 원본 실습 자료가 이 방식을 쓴다.
@B `mkstore -wrl 디렉터리 -create`로 만든 지갑은 일반 auto-login 지갑이다. 매뉴얼 절차는 이 명령을 기준으로 한다.
@B 배치 서버처럼 지갑을 한 호스트에서만 쓴다면 local auto-login이 더 안전하다. 같은 지갑을 여러 서버에 배포해야 하는 경우에만 일반 auto-login을 쓴다.

@NOTE local 지갑은 복사본을 거부한다
실습 05에서 orapki -auto_login_local로 만든 지갑과 mkstore -create로 만든 일반 지갑을 다른 OS 사용자에게 복사해 접속해 봤다.
local 지갑은 ORA-12578: TNS:wallet open failed로 열리지 않았고, 일반 지갑은 다른 사용자에게서도 그대로 열려 지갑 계정으로 접속됐다. 일반 auto-login 지갑은 파일만 있으면 어디서든 쓸 수 있다.
@END

@H3 1.3.3  지갑 비밀번호 규칙

@B `mkstore -create`와 `orapki wallet create`는 지갑 비밀번호의 복잡도를 검사한다. 너무 짧거나 문자 종류가 부족하면 지갑을 만들지 않는다.
@B 기준은 최소 8자이며 영문자와 숫자 또는 특수 문자를 섞어야 한다.
@B 지갑 비밀번호는 자격 증명을 고칠 때만 쓴다. 매일 쓰는 값이 아니므로 잊어버리기 쉽다. 지갑 비밀번호를 잃으면 지갑을 새로 만들고 자격 증명을 모두 다시 등록해야 한다.

@H3 1.3.4  자격 증명 영역과 PKI 영역

@B 지갑에는 인증서·개인 키를 담는 PKI 영역과 자격 증명을 담는 secret store 영역이 따로 있다.
@B PKI 영역은 `orapki`로 다룬다. TLS(11장)와 TDE(10장)가 이 영역을 쓴다.
@B secret store 영역은 `mkstore`로 다룬다. SEPS의 자격 증명은 이 영역에 `oracle.security.client.connect_string1`, `oracle.security.client.username1`, `oracle.security.client.password1` 같은 항목으로 저장된다.
@B 한 지갑에 두 영역이 함께 있을 수 있다. TLS 인증서가 들어 있는 클라이언트 지갑에 SEPS 자격 증명을 함께 넣는 구성도 가능하다.

@H3 1.3.5  지갑 내용 들여다보기

@B `orapki wallet display -wallet 디렉터리`는 지갑의 PKI 영역(사용자 인증서, 신뢰 인증서)을 보여 준다. SEPS만 쓰는 지갑은 이 영역이 비어 있다.
@B `mkstore -wrl 디렉터리 -list`는 secret store 영역의 항목 이름을 모두 보여 준다. 자격 증명 하나가 connect_string, username, password 세 항목으로 저장되고 끝에 같은 번호가 붙는다.
@B 번호는 등록 순서다. 중간 자격 증명을 지우면 번호에 빈자리가 생기며, 다음 등록이 그 번호를 다시 쓸 수 있다.
@B 항목 이름에 `oracle.security.client.default_username` 같은 기본 항목이 함께 보일 수 있다. 직접 만든 적이 없는 항목은 지우지 않는다.

@CODE
Oracle Secret Store entries:
oracle.security.client.connect_string1
oracle.security.client.connect_string2
oracle.security.client.password1
oracle.security.client.password2
oracle.security.client.username1
oracle.security.client.username2
@END

@H3 1.3.6  지갑 비밀번호 변경

@B 지갑 비밀번호는 `orapki wallet change_pwd -wallet 디렉터리`로 바꾼다. 옛 비밀번호와 새 비밀번호를 차례로 묻는다.
@B 지갑 비밀번호를 바꿔도 cwallet.sso는 함께 갱신되므로 접속에는 영향이 없다.
@B 지갑 비밀번호를 알던 사람이 퇴직하면 지갑 비밀번호를 바꾸고, `-viewEntry`로 볼 수 있었던 DB 계정 비밀번호도 함께 바꾼다. 지갑 비밀번호만 바꾸면 이미 본 DB 비밀번호는 그대로 유효하다.

@H3 1.3.7  지갑 파일 권한

@B mkstore와 orapki는 지갑 파일을 600 권한으로 만든다. 실습에서도 ewallet.p12, cwallet.sso, 잠금 파일 모두 `-rw-------`였다.
@B 상위 디렉터리 권한은 도구가 정하지 않는다. 디렉터리를 만들 때의 umask에 따라 755가 되기 쉬우므로 지갑을 담은 최상위 디렉터리를 700으로 직접 막는다.
@B 파일을 다른 위치로 복사하거나 압축을 풀면 권한이 바뀔 수 있다. 복사 후에는 `ls -l`로 다시 확인한다.
@B oracle 소유의 지갑을 다른 OS 사용자가 써야 한다면 지갑을 공유하지 말고 그 사용자의 지갑을 따로 만든다. 그룹 읽기 권한을 열어 주는 것은 지갑을 여러 사람에게 나눠 주는 것과 같다.

@H2 1.4  mkstore로 지갑과 자격 증명 관리

@H3 1.4.1  지갑 생성

@CODE
[oracle@oel7v9 ~]$ mkdir -p /home/oracle/seps/wallet
[oracle@oel7v9 ~]$ mkstore -wrl /home/oracle/seps/wallet -create
Enter password:
Enter password again:
@END

@B `-wrl`은 지갑 디렉터리를 가리킨다. 디렉터리는 미리 만들어 둔다.
@B 비밀번호를 두 번 묻는다. 복잡도 규칙에 맞지 않으면 여기서 실패한다.
@B 만든 직후 디렉터리에는 ewallet.p12와 cwallet.sso가 생긴다. 파일 권한은 소유자 읽기·쓰기(600)로 만들어진다.

@H3 1.4.2  자격 증명 등록

@CODE
[oracle@oel7v9 ~]$ mkstore -wrl /home/oracle/seps/wallet -createCredential seps_app seps_app
Your secret/Password is missing in the command line
Enter your secret/Password:
Re-enter your secret/Password:
Enter wallet password:
@END

@B 형식은 `-createCredential 접속문자열 사용자이름 [비밀번호]`다. 비밀번호를 명령행에 쓰지 않으면 대화식으로 묻는다.
@B 비밀번호를 명령행 인자로 넣으면 ps와 히스토리에 남는다. SEPS를 쓰는 목적과 어긋나므로 대화식으로 입력한다.
@B 마지막에 묻는 것은 DB 비밀번호가 아니라 지갑 비밀번호다. 순서를 헷갈려 지갑 비밀번호 자리에 DB 비밀번호를 넣으면 지갑을 열지 못해 실패한다.
@B 첫 인자인 접속 문자열이 자격 증명의 키다. 나중에 `/@seps_app`으로 접속할 때 이 문자열과 정확히 같아야 한다.

@H3 1.4.3  조회, 수정, 삭제

@TBL
작업 | 명령
목록 조회 | mkstore -wrl 지갑 -listCredential
수정 | mkstore -wrl 지갑 -modifyCredential 접속문자열 사용자이름
삭제 | mkstore -wrl 지갑 -deleteCredential 접속문자열
항목 전체 보기 | mkstore -wrl 지갑 -list
항목 값 보기 | mkstore -wrl 지갑 -viewEntry 항목이름
@END

@B `-listCredential`은 번호, 접속 문자열, 사용자 이름만 보여 준다. 비밀번호는 표시하지 않는다.
@B `-viewEntry`로 password 항목을 지정하면 저장된 비밀번호가 평문으로 나온다. 지갑 비밀번호를 아는 사람은 모든 저장 비밀번호를 볼 수 있다는 뜻이므로 지갑 비밀번호를 DB 비밀번호만큼 관리한다.
@B `-modifyCredential`은 DB에서 비밀번호를 바꾼 직후 지갑을 맞출 때 쓴다. 접속 문자열을 바꾸는 기능이 아니다. 접속 문자열을 바꾸려면 삭제 후 다시 등록한다.
@B `-deleteCredential`로 지우면 그 접속 문자열로는 더 이상 접속할 수 없다. 특정 배치의 접속만 막을 때 쓴다.

@H3 1.4.4  비대화식 입력의 함정

@B 원본 실습 자료는 히어 문서(`<<EOF`)로 지갑 비밀번호를 넣어 `mkstore`를 자동화한다. 실습에서는 편하지만 그 스크립트 파일에 지갑 비밀번호가 평문으로 남는다.
@B 운영 환경에서는 지갑을 만드는 일과 자격 증명을 등록하는 일을 사람이 대화식으로 수행한다. 자동화가 필요하면 지갑 비밀번호를 별도 비밀 관리 도구에서 넘겨받는다.
@B 지갑 작업을 끝낸 뒤 셸 히스토리를 확인한다. `mkstore` 명령행에 비밀번호를 넣었다면 히스토리에서 지운다.

@H3 1.4.5  원본 자료 방식과의 비교

@CODE
[oracle@oel7v9 ~]$ orapki wallet create -wallet /home/oracle/seps/wallet_local -pwd 'Wallet#2026' -auto_login_local
[oracle@oel7v9 ~]$ mkstore -wrl /home/oracle/seps/wallet_local -createCredential seps_app seps_app
@END

@B 원본 자료는 지갑을 orapki로 만들고 자격 증명은 mkstore로 넣는다. 두 도구가 같은 지갑 파일 형식을 쓰므로 섞어 써도 된다.
@B 차이는 지갑 종류다. `-auto_login_local`을 주면 local auto-login 지갑이 되고, mkstore -create는 일반 auto-login 지갑을 만든다.
@B orapki의 `-pwd` 옵션은 지갑 비밀번호를 명령행에 노출한다. 원본 실습처럼 학습할 때만 쓰고, 운영에서는 생략해 대화식으로 입력한다.
@B 원본 자료는 같은 DB에 tt1, tt2, tt_proxy 세 별칭을 두고 계정마다 자격 증명을 등록한다. 접속 문자열 하나에 자격 증명 하나라는 규칙을 별칭으로 해결한 예다.

@H3 1.4.6  지갑 백업과 이관

@B 지갑 백업은 디렉터리 전체(ewallet.p12, cwallet.sso)를 복사하는 것으로 충분하다. 지갑 비밀번호는 백업본과 다른 곳에 보관한다.
@B local auto-login 지갑의 백업본은 같은 호스트·같은 OS 사용자에서만 바로 쓸 수 있다. 다른 서버에서 복구해야 한다면 그 서버에서 지갑을 새로 만들고 자격 증명을 다시 등록하는 편이 확실하다.
@B 서버 이관 때 가장 안전한 방법은 새 서버에서 지갑을 새로 만들고 자격 증명을 다시 등록하는 것이다. 이 기회에 계정 비밀번호도 함께 바꾼다.

@H3 1.4.7  지갑 비밀번호를 묻는 작업

@B 등록·수정·삭제뿐 아니라 `-listCredential`과 `-viewEntry` 같은 조회 작업도 지갑 비밀번호를 묻는다. 실습 03에서도 목록을 보기 전에 `Enter wallet password:`가 나왔다.
@B 지갑 비밀번호 없이 할 수 있는 일은 cwallet.sso로 지갑을 열어 접속하는 것뿐이다. 지갑에 어떤 계정이 들었는지 점검하는 사람도 지갑 비밀번호를 알아야 하므로, 점검 담당자와 비밀번호 보관 위치를 미리 정한다.
@B `-listCredential` 출력은 `List credential (index: connect_string username)` 머리줄 아래 `1: seps_app seps_app`처럼 번호, 접속 문자열, 사용자 이름 순으로 나온다.
@B 거부된 작업은 `Secret Store error occurred: oracle.security.pki.OracleSecretStoreException:` 뒤에 사유가 붙어 나온다. 중복 등록 때의 사유는 `Credential already exists`였다.
@B 매뉴얼은 external password store 영역이 PKI 영역과 분리돼 있어 Oracle Wallet Manager로는 자격 증명을 관리할 수 없다고 적는다. 자격 증명 관리 도구는 mkstore 하나다.

@CASE 배치는 도는데 지갑을 고칠 수 없다
배치 담당자가 바뀌면서 지갑 비밀번호가 인계되지 않았다. cwallet.sso 덕분에 배치는 몇 달간 문제없이 돌았고, 아무도 지갑 비밀번호가 사라졌다는 사실을 몰랐다.
분기 비밀번호 순환 날 `-modifyCredential`을 실행하자 지갑 비밀번호를 묻는 단계에서 막혔다. DB 비밀번호는 이미 바꾼 뒤라 배치가 ORA-01017로 실패하기 시작했다.
지갑을 새로 만들고 자격 증명을 모두 다시 등록했다. 이후 지갑 비밀번호를 비밀 관리 도구에 등록하고, 순환 작업 전에 `-listCredential`로 지갑 비밀번호가 맞는지 먼저 확인하는 단계를 넣었다.
@END

@BP 지갑 디렉터리 관리 원칙
지갑 디렉터리는 지갑을 쓰는 OS 사용자만 읽을 수 있게 둔다(디렉터리 700, 파일 600).
지갑 하나에는 같은 목적의 자격 증명만 넣는다. 백업용, 보고서용, 애플리케이션용을 한 지갑에 섞으면 지갑을 읽을 수 있는 사람이 모든 계정을 갖게 된다.
ewallet.p12와 cwallet.sso를 함께 백업하고, 지갑 비밀번호는 별도로 보관한다.
배치 서버에서는 local auto-login 지갑을 우선 검토한다.
@END

@H2 1.5  클라이언트 구성

@H3 1.5.1  sqlnet.ora

@CODE
WALLET_LOCATION =
  (SOURCE =
    (METHOD = FILE)
    (METHOD_DATA =
      (DIRECTORY = /home/oracle/seps/wallet)
    )
  )
SQLNET.WALLET_OVERRIDE = TRUE
@END

@B `WALLET_LOCATION`은 지갑 디렉터리를 가리킨다. 값에는 파일 이름 대신 디렉터리 경로를 쓴다.
@B `SQLNET.WALLET_OVERRIDE = TRUE`는 `/@접속문자열` 접속에 지갑의 자격 증명을 쓰게 한다. 이 줄이 없으면 지갑 위치를 알아도 자격 증명을 쓰지 않는다.
@B `SQLNET.WALLET_OVERRIDE`는 클라이언트 쪽 파라미터다. 매뉴얼은 DB 서버의 sqlnet.ora에 TRUE를 두면 외부 프로시저가 동작하지 않을 수 있다고 경고한다.
@B 같은 sqlnet.ora에 외부 인증(SSL 등)이 함께 구성돼 있으면, WALLET_OVERRIDE가 TRUE일 때는 지갑의 사용자 이름·비밀번호가 우선한다.
@B 매뉴얼에 따르면 외부 인증을 쓰는 클라이언트에서 그 외부 인증이 실패하면 `/@접속문자열` 접속도 함께 실패한다. 지갑이 외부 인증 실패를 대신 메워 주지는 않는다.

@H3 1.5.2  sqlnet.ora 파라미터 정리

@TBL
파라미터 | 의미 | SEPS에서
WALLET_LOCATION | 지갑 디렉터리 | 필수
SQLNET.WALLET_OVERRIDE | /@접속에 지갑의 사용자 이름·비밀번호 사용 | 필수(TRUE)
SSL_CLIENT_AUTHENTICATION | TLS 상호 인증 여부 | 쓰지 않음
SSL_VERSION | TLS 프로토콜 버전 | 쓰지 않음
SQLNET.AUTHENTICATION_SERVICES | 외부 인증 방식 목록 | 비워 두거나 기존 값 유지
@END

@B 원본 실습 자료의 sqlnet.ora에는 `SSL_CLIENT_AUTHENTICATION = FALSE`, `SSL_VERSION = 0`도 들어 있다. 같은 지갑을 TLS와 함께 쓰는 예제에서 옮겨 온 줄로, TCP 접속만 하는 SEPS에는 영향이 없다.
@B 쓰지 않는 파라미터를 남겨 두면 나중에 TLS를 구성할 때 의도와 다른 값이 남아 혼란을 준다. SEPS 전용 sqlnet.ora에는 WALLET_LOCATION과 SQLNET.WALLET_OVERRIDE만 둔다.
@B 최신 19c 릴리스 업데이트 문서는 SSL_로 시작하는 파라미터 이름을 TLS_로 바꿔 소개한다(11장).
@B 같은 문서의 예제 sqlnet.ora는 `TLS_CLIENT_AUTHENTICATION = FALSE`, `TLS_VERSION = UNDETERMINED`를 쓴다. 폐기 예정 기간에 TLS_CLIENT_AUTHENTICATION과 SSL_CLIENT_AUTHENTICATION이 함께 있으면 SSL_ 쪽은 무시된다.

@H3 1.5.3  tnsnames.ora 별칭

@B 자격 증명의 접속 문자열은 보통 tnsnames.ora 별칭이다. 별칭은 접속 대상 주소를, 지갑은 그 별칭으로 접속할 계정을 정한다.
@B 별칭 대신 Easy Connect 문자열(`oel7v9:1521/orcl`)을 자격 증명 키로 쓸 수도 있다. 이 경우 접속할 때도 같은 문자열을 정확히 써야 한다.
@B 별칭이 tnsnames.ora에 없으면 지갑에 자격 증명이 있어도 주소를 찾지 못해 ORA-12154가 난다.
@B 별칭은 있는데 지갑에 그 별칭의 자격 증명이 없으면 사용자 이름 없이 인증을 시도하는 꼴이 되어 실패한다.

@H3 1.5.4  TNS_ADMIN으로 구성 분리

@B 서버의 `$ORACLE_HOME/network/admin`에 있는 sqlnet.ora를 고치면 그 홈을 쓰는 모든 클라이언트와 DB 프로세스가 영향을 받는다.
@B SEPS 구성은 별도 디렉터리에 sqlnet.ora·tnsnames.ora를 두고 `TNS_ADMIN` 환경 변수로 가리키는 편이 안전하다. 원본 실습 자료도 `${HOME}/tns`를 따로 만들어 쓴다.
@B `TNS_ADMIN`을 설정하면 그 디렉터리의 tnsnames.ora만 쓴다. 기존 별칭이 필요하면 새 tnsnames.ora에 함께 옮겨 둔다.
@B 배치 스크립트 맨 위에 `export TNS_ADMIN=...`을 넣어 두면 스크립트마다 다른 지갑을 쓰게 할 수 있다.

@CASE 크론 배치만 접속에 실패한다
SEPS를 구성하고 터미널에서 `sqlplus /@seps_rpt`로 시험하니 잘 접속됐다. 그런데 같은 명령을 넣은 크론 작업은 매일 ORA-12154로 실패했다.
터미널에서는 `.bash_profile`이 `TNS_ADMIN`을 설정했지만 크론은 로그인 셸을 거치지 않아 `TNS_ADMIN`이 비어 있었다. 크론 프로세스는 `$ORACLE_HOME/network/admin`의 tnsnames.ora를 읽었고 거기에는 seps_rpt 별칭이 없었다.
배치 스크립트 첫 줄에 `export TNS_ADMIN=/home/oracle/seps/tns`와 ORACLE_HOME, PATH 설정을 넣었다. 이후 크론에서도 같은 지갑과 별칭을 쓰게 됐다.
@END

@NOTE 어느 sqlnet.ora가 읽히는가
클라이언트는 TNS_ADMIN 환경 변수가 있으면 그 디렉터리의 sqlnet.ora·tnsnames.ora를 읽고, 없으면 $ORACLE_HOME/network/admin을 읽는다.
실습 04에서 env -i로 환경 변수를 비우자 공용 디렉터리의 tnsnames.ora가 읽혀 SEPS 별칭을 찾지 못했다. 같은 명령에 TNS_ADMIN만 더하자 바로 접속됐다. 접속이 터미널과 배치에서 다르게 동작하면 가장 먼저 TNS_ADMIN을 확인한다.
@END

@H3 1.5.5  Easy Connect 문자열을 키로 쓸 때

@B 자격 증명의 접속 문자열에 `oel7v9:1521/orcl` 같은 Easy Connect 문자열을 그대로 쓸 수 있다. tnsnames.ora가 없어도 된다.
@B 이 경우 접속할 때 `/@oel7v9:1521/orcl`처럼 등록한 문자열과 글자 하나까지 같아야 한다. 호스트 이름 대신 IP를 쓰거나 포트를 생략하면 다른 문자열로 취급되어 자격 증명을 찾지 못한다.
@B 별칭 방식은 주소가 바뀔 때 tnsnames.ora만 고치면 되고, Easy Connect 방식은 지갑의 자격 증명을 다시 등록해야 한다. 운영에서는 별칭 방식이 관리하기 쉽다.

@H3 1.5.6  접속과 확인

@CODE
[oracle@oel7v9 ~]$ export TNS_ADMIN=/home/oracle/seps/tns
[oracle@oel7v9 ~]$ sqlplus /@seps_app

SQL> SHOW USER
USER is "SEPS_APP"
@END

@B 접속 후 `SHOW USER`나 `SYS_CONTEXT('USERENV', 'SESSION_USER')`로 실제 접속 계정을 확인한다.
@B 서버 쪽에서 보면 일반 비밀번호 인증과 구분되지 않는다. `SYS_CONTEXT('USERENV', 'AUTHENTICATION_METHOD')`는 PASSWORD로 나온다.
@B 감사 기록에도 일반 로그인으로 남는다. SEPS 사용 여부를 서버에서 판별할 수단은 없다.

@H3 1.5.7  여러 지갑을 쓰는 서버

@B 한 서버에서 여러 용도의 지갑을 쓸 때는 용도별 TNS_ADMIN 디렉터리를 만들고 각 sqlnet.ora가 해당 지갑을 가리키게 한다.
@B 스크립트는 맨 위에서 자기 TNS_ADMIN을 설정한다. 셸 프로파일의 전역 TNS_ADMIN에 기대면 어느 지갑이 쓰였는지 추적하기 어렵다.
@B sqlnet.ora 하나에 WALLET_LOCATION은 하나만 둘 수 있다. 같은 프로세스가 두 지갑을 번갈아 써야 한다면 지갑을 합치기보다 프로세스를 나눈다.

@H2 1.6  자격 증명 설계

@H3 1.6.1  접속 문자열 하나에 자격 증명 하나

@B 지갑은 접속 문자열을 키로 자격 증명을 찾는다. 같은 접속 문자열에 두 계정을 등록할 수 없다.
@B 매뉴얼은 "각 사용자 계정은 고유한 접속 문자열을 가져야 한다"고 적는다. 같은 데이터베이스에 여러 계정으로 접속하려면 별칭을 계정 수만큼 만든다.
@B 별칭 seps_app, seps_rpt가 모두 같은 orcl 서비스를 가리키되 지갑에는 각각 다른 계정을 등록하는 식이다.
@B 같은 접속 문자열로 다시 `-createCredential`을 실행하면 `Credential already exists`로 거부된다. 계정을 바꾸려면 삭제 후 등록하고, 비밀번호만 바꾸려면 `-modifyCredential`을 쓴다.

@TBL
별칭(접속 문자열) | 가리키는 서비스 | 지갑에 저장된 계정
seps_app | orcl | SEPS_APP
seps_rpt | orcl | SEPS_RPT
seps_proxy | orcl | SEPS_APP[SEPS_RPT] (프록시)
@END

@NOTE 매뉴얼의 "별도 지갑" 문구
매뉴얼은 같은 데이터베이스에 대한 여러 로그인 자격 증명을 한 지갑에 둘 수 없고 별도 지갑에 저장해야 한다고 적는다. 문장만 읽으면 위의 별칭 방식과 어긋나 보인다.
실습 02에서는 같은 orcl 서비스를 가리키는 seps_app, seps_rpt 두 별칭을 한 지갑에 등록했고 두 계정 모두 접속됐다. 지갑이 구분하는 단위는 접속 문자열이다. 계정마다 지갑을 쓰는 OS 사용자가 달라야 한다면 그때는 매뉴얼대로 지갑을 나눈다.
@END

@H3 1.6.2  프록시 자격 증명

@B 2장의 프록시 인증과 SEPS를 함께 쓸 수 있다. 자격 증명의 사용자 이름 자리에 `프록시사용자[대상사용자]`를 넣는다.
@B 저장되는 비밀번호는 프록시 사용자의 것이다. 접속하면 대상 사용자 세션이 열린다.
@B 대상 사용자마다 비밀번호를 지갑에 둘 필요가 없다. 프록시 계정 하나의 비밀번호만 관리하면 된다.
@B 프록시 권한(`ALTER USER 대상 GRANT CONNECT THROUGH 프록시`)이 없으면 접속이 실패한다. 19.3에서는 이때 오류가 ORA-28150이 아니라 ORA-01017로 나왔다. 메시지만 보면 비밀번호 문제로 오인하기 쉬우므로 프록시 자격 증명이 실패하면 PROXY_USERS부터 확인한다.
@B 감사 기록에는 이 실패가 대상 사용자(DBUSERNAME)와 프록시 사용자(DBPROXY_USERNAME)로 나뉘어 남는다. 프록시 구성은 2장에서 다룬다.

@H3 1.6.3  비밀번호 변경과 계정 잠금

@B DB에서 비밀번호를 바꾸면 지갑의 비밀번호는 저절로 바뀌지 않는다. 다음 접속부터 ORA-01017이 난다.
@B 배치가 재시도하도록 짜여 있으면 실패한 로그인이 빠르게 쌓인다. 프로파일의 FAILED_LOGIN_ATTEMPTS(기본 프로파일 10회)를 넘으면 계정이 잠기고 정상 비밀번호로도 접속할 수 없다.
@B 비밀번호 변경 절차에 "DB 변경 → 즉시 `-modifyCredential` → `/@별칭` 접속 확인"을 한 묶음으로 넣는다.
@B 비밀번호 만료(PASSWORD_LIFE_TIME)가 걸린 계정은 만료 후 유예 기간에 경고와 함께 접속되다가 결국 막힌다. 배치 계정은 만료 정책을 별도 프로파일로 관리한다.

@CASE 비밀번호 정기 변경 다음 날 백업이 멈췄다
보안 점검 결과에 따라 백업 계정의 비밀번호를 바꿨다. 다음 날 아침 RMAN 백업과 Data Pump 작업이 모두 실패했고, 담당자가 수동으로 접속하려 하니 계정이 잠겨 있었다.
백업 스크립트는 SEPS 지갑으로 접속하고 있었다. 지갑에는 옛 비밀번호가 남아 있었고, 실패한 작업이 재시도를 거듭하는 동안 FAILED_LOGIN_ATTEMPTS를 넘었다.
계정 잠금을 풀고 `mkstore -modifyCredential`로 지갑의 비밀번호를 맞춘 뒤 `/@별칭` 접속을 확인했다. 이후 비밀번호 변경 작업 지시서에 지갑 갱신과 접속 확인 단계를 넣었다.
@END

@H3 1.6.4  지갑 계정용 프로파일

@TBL
프로파일 한도 | 지갑 계정에서의 고려
FAILED_LOGIN_ATTEMPTS | 너무 작으면 지갑 불일치 한 번에 배치 전체가 멈춘다. 너무 크면 무차별 대입을 늦게 잡는다
PASSWORD_LOCK_TIME | 자동 잠금 해제 시간. 배치 재시도 간격보다 길게 두어야 재시도가 잠금을 연장하지 않는다
PASSWORD_LIFE_TIME | 만료되면 지갑 계정은 사람처럼 새 비밀번호를 입력할 수 없다. 만료 대신 계획된 순환을 쓴다
PASSWORD_GRACE_TIME | 만료 경고 기간. 배치 로그에 경고가 찍혀도 사람이 보지 못하는 경우가 많다
@END

@B 지갑 계정을 위한 프로파일을 따로 만들고, 계정 생성 때 그 프로파일을 지정한다. DEFAULT 프로파일을 바꾸면 사람 계정까지 영향을 받는다.
@B 만료 정책을 끄는 대신 순환 주기를 정해 지갑 수정과 함께 실행하는 절차를 둔다. 비밀번호를 영원히 그대로 두는 것은 SEPS가 해결하려던 문제를 다시 만든다.

@H3 1.6.5  계정 분리 전략

@TBL
용도 | 권장 계정 | 지갑 배치
애플리케이션 접속 | 애플리케이션 전용 계정(소유자 아님) | 애플리케이션 서버의 전용 OS 사용자
보고서 추출 | 읽기 전용 권한만 가진 계정 | 보고서 서버
백업·Data Pump | 필요한 관리 권한만 가진 백업 계정 | DB 서버의 백업 전용 OS 사용자
모니터링 | SELECT_CATALOG_ROLE 수준의 계정 | 모니터링 서버
@END

@B 스키마 소유자 계정을 지갑에 넣지 않는다. 소유자는 DDL까지 할 수 있어 지갑이 유출됐을 때 피해가 가장 크다.
@B 용도별로 지갑을 나누면 하나가 유출돼도 영향이 그 용도에 머문다. 지갑 하나에 모든 계정을 넣는 구성은 관리가 편한 대신 위험이 한곳에 몰린다.
@B 지갑을 쓰는 OS 사용자도 용도별로 나눈다. 같은 OS 사용자가 여러 지갑을 읽을 수 있으면 지갑을 나눈 의미가 줄어든다.

@BP 비밀번호 순환을 지갑과 묶기
비밀번호 변경 작업을 스크립트로 만든다. ALTER USER, mkstore -modifyCredential, /@별칭 접속 시험을 한 번에 수행하고 실패하면 즉시 알린다.
새 비밀번호는 작업자가 화면에 입력하고 스크립트 파일에는 남기지 않는다.
연결 풀을 쓰는 애플리케이션은 지갑 수정 직후 풀 재시작을 같은 작업에 넣는다.
작업 후 DBA_USERS의 PASSWORD_CHANGE_DATE와 실패 로그인 감사 기록을 확인해 옛 비밀번호로 접속하는 곳이 없는지 본다.
@END

@H3 1.6.6  별칭 이름 짓기

@B 별칭 이름에 계정 용도와 대상 DB를 함께 담는다. `prod_rpt`, `prod_bkp`처럼 지으면 지갑 목록만 봐도 어떤 접속인지 알 수 있다.
@B 운영 DB와 개발 DB에 같은 별칭 이름을 쓰지 않는다. 지갑을 잘못 가리킨 스크립트가 엉뚱한 DB에 접속하는 사고를 막는다.
@B 지갑 목록(-listCredential)과 tnsnames.ora 별칭 목록을 주기적으로 대조한다. 별칭만 남고 자격 증명이 없거나, 자격 증명만 남고 별칭이 없는 항목은 정리 대상이다.

@H2 1.7  활용

@H3 1.7.1  배치와 유틸리티

@B SQL*Plus를 비롯해 OCI 기반 클라이언트 도구는 모두 `/@별칭`을 쓸 수 있다. Data Pump(`expdp /@별칭`), SQL*Loader, RMAN(`rman target /@별칭`)이 대표적이다.
@B Data Pump의 `/@별칭`은 지갑의 계정으로 작업을 만든다. 작업 이름과 마스터 테이블도 그 계정 소유가 된다.
@B JDBC Thin 드라이버는 OCI 클라이언트가 아니라서 sqlnet.ora의 WALLET_OVERRIDE를 그대로 읽지 않는다. Thin 드라이버에서 지갑을 쓰려면 드라이버 쪽 지갑 설정(oraclepki 라이브러리와 연결 속성)이 따로 필요하다.

@CODE
[oracle@oel7v9 ~]$ expdp /@seps_app tables=seps_t directory=seps_dir dumpfile=seps_t.dmp
@END

@H3 1.7.2  관리자 접속

@B `/@별칭 AS SYSDBA` 형식으로 관리 작업도 지갑으로 할 수 있다. 저장된 계정에 SYSDBA 권한이 있고 서버에 패스워드 파일이 구성돼 있어야 한다.
@B SYS 비밀번호를 지갑에 넣는 구성은 지갑 파일 하나가 데이터베이스 전체 권한이 된다는 뜻이다. 관리 작업에는 SYSBACKUP, SYSDG 같은 작업별 관리 권한을 가진 전용 계정을 쓰는 편이 낫다.

@H3 1.7.3  애플리케이션 서버

@B OCI 기반 애플리케이션(Pro*C, OCI 드라이버를 쓰는 PHP·Python 클라이언트 등)은 sqlnet.ora 설정만으로 SEPS를 쓴다. 연결 문자열에서 사용자 이름과 비밀번호를 비워 두면 된다.
@B JDBC OCI 드라이버도 같은 방식으로 동작한다. Thin 드라이버는 연결 속성으로 지갑 위치(`oracle.net.wallet_location`)를 지정하고, oraclepki 계열 라이브러리를 클래스 경로에 둬야 한다.
@B 연결 풀은 시작할 때 지갑에서 비밀번호를 읽는다. 지갑을 고친 뒤에는 풀을 다시 시작해야 새 비밀번호가 적용된다.

@H3 1.7.4  RMAN과 카탈로그 접속

@B RMAN도 `rman target /@prod_bkp catalog /@rcat_owner` 형식으로 대상 DB와 카탈로그 DB 모두 지갑의 자격 증명을 쓸 수 있다.
@B 백업 스크립트에서 카탈로그 소유자 비밀번호가 사라지므로, 카탈로그 비밀번호를 바꿀 때 스크립트를 고칠 필요가 없다.
@B 대상 DB 접속 계정은 SYS 대신 SYSBACKUP 권한을 가진 백업 전용 계정을 지갑에 넣는다. 지갑 유출의 피해가 백업 작업 범위에 머문다.

@NOTE mkstore와 orapki
19c에서도 SEPS 자격 증명 관리는 `mkstore`로 한다. 지갑 생성은 `mkstore -create`와 `orapki wallet create` 둘 다 가능하다.
`orapki`로 만든 지갑에 `mkstore`로 자격 증명을 넣을 수 있다. 원본 실습 자료는 `orapki ... -auto_login_local`로 지갑을 만들고 `mkstore -createCredential`로 자격 증명을 넣는 방식을 쓴다.
@END

@H2 1.8  설계와 적용 절차

@P 운영 환경에 SEPS를 처음 적용할 때의 순서다. 실습 01~03이 이 순서를 따른다.

@TBL
단계 | 작업 | 확인할 것
1 | 용도별 DB 계정과 OS 사용자 결정 | 계정 권한 최소화, 스키마 소유자 제외
2 | 지갑 디렉터리 생성과 권한 설정 | 디렉터리 700, 소유자
3 | 지갑 생성(mkstore -create 또는 orapki -auto_login_local) | ewallet.p12·cwallet.sso 생성, 파일 600
4 | 별도 TNS_ADMIN에 sqlnet.ora·tnsnames.ora 작성 | WALLET_LOCATION, WALLET_OVERRIDE, 별칭
5 | 자격 증명 등록(-createCredential, 대화식 입력) | -listCredential로 별칭·계정 확인
6 | /@별칭 접속 시험 | SHOW USER, 필요한 작업 권한
7 | 스크립트에서 비밀번호 제거 | 스크립트 첫 줄 TNS_ADMIN 설정, 히스토리 정리
8 | 비밀번호 변경 절차 문서화 | DB 변경 → modifyCredential → 접속 확인
@END

@B 7단계를 끝내기 전에는 SEPS를 적용했다고 볼 수 없다. 스크립트와 설정 파일에 남은 옛 비밀번호를 찾아 지우고, 그 비밀번호 자체도 바꾼다.
@B 기존 비밀번호를 그대로 지갑에 넣으면, 이미 스크립트로 퍼진 비밀번호가 계속 유효하다. 지갑 적용과 동시에 비밀번호를 새로 정하는 것이 원칙이다.

@H3 1.8.1  도입 전 점검 항목

@B 지금 비밀번호가 들어 있는 파일 목록: 셸 스크립트, 크론 정의, 애플리케이션 설정 파일, 형상 관리 저장소.
@B 각 파일이 쓰는 계정과 접속 대상: 같은 계정을 여러 곳에서 쓰는지, 계정을 용도별로 나눌 수 있는지.
@B 클라이언트 종류: OCI 기반인지, JDBC Thin처럼 별도 설정이 필요한 클라이언트가 섞여 있는지.
@B 실행 환경: 크론, 스케줄러, 애플리케이션 서버가 어떤 환경 변수로 실행되는지. TNS_ADMIN을 어디서 설정할지.
@B 비밀번호 순환 담당자와 절차: 지갑 수정과 연결 풀 재시작을 누가 언제 하는지.

@H2 1.9  문제 해결

@TBL
증상 | 원인 | 확인과 조치
ORA-12154 | tnsnames.ora에 별칭이 없거나 TNS_ADMIN이 다른 곳을 가리킴 | echo $TNS_ADMIN, tnsping 별칭
ORA-01017 | 지갑의 비밀번호가 DB와 다르거나 WALLET_OVERRIDE가 빠짐 | -listCredential, sqlnet.ora 확인, -modifyCredential
ORA-28000 | 잘못된 저장 비밀번호로 실패가 반복되어 계정 잠김 | DBA_USERS.ACCOUNT_STATUS, ALTER USER ACCOUNT UNLOCK 후 지갑 수정
ORA-12578 | 지갑을 열지 못함. local 지갑을 다른 OS 사용자·호스트에서 사용, cwallet.sso 없음 | ls -l 지갑, 지갑을 만든 사용자·호스트 확인
ORA-01017(자격 증명 삭제 후) | 별칭은 있으나 지갑에 그 접속 문자열의 자격 증명이 없음 | -listCredential
Credential already exists | 같은 접속 문자열이 이미 있음 | -listCredential로 확인 후 -modifyCredential 또는 삭제 후 등록
PKI-01002 | 지갑 비밀번호 복잡도 미달 | 8자 이상, 영문자와 숫자·특수 문자 혼합
@END

@B 진단 순서는 별칭(tnsping) → 지갑 위치(sqlnet.ora와 TNS_ADMIN) → 자격 증명(-listCredential) → DB 계정 상태(DBA_USERS)다.
@B `tnsping`은 주소만 확인한다. 성공해도 지갑이 맞는지는 알려 주지 않는다.
@B sqlnet.ora를 두 곳(TNS_ADMIN과 ORACLE_HOME)에서 고쳐 놓으면 어느 쪽이 읽혔는지 헷갈린다. 구성 디렉터리를 하나로 정하고 그곳만 고친다.

@CASE 다른 서버로 옮긴 지갑이 열리지 않는다
배치 서버를 새 장비로 옮기면서 `/home/oracle/seps` 디렉터리를 통째로 복사했다. 새 서버에서 `sqlplus /@seps_rpt`를 실행하니 지갑 비밀번호를 묻고, 그대로 엔터를 치자 인증에 실패했다.
옛 서버의 지갑은 `orapki wallet create -auto_login_local`로 만든 local auto-login 지갑이었다. cwallet.sso는 만든 호스트와 OS 사용자에서만 열리므로 새 서버에서는 auto-login이 동작하지 않았다.
새 서버에서 지갑을 새로 만들고 자격 증명을 다시 등록했다. 지갑을 복사해 옮기는 대신 다시 만드는 절차를 서버 이관 체크리스트에 넣었다.
@END

@H3 1.9.1  실패한 로그인은 감사 기록에 어떻게 남나

@P 19c 기본 Unified Auditing 정책 ORA_LOGON_FAILURES는 실패한 로그인을 기록한다. 지갑 설정 문제로 생긴 실패가 이 기록에 어떻게 보이는지 실습 03·04에서 확인했다.

@TBL
실패 원인 | 접속 결과 | 감사 기록의 DBUSERNAME
WALLET_OVERRIDE 누락 | ORA-01017 | 비어 있음(NULL). 사용자 이름 없이 시도
지갑에 옛 비밀번호 | ORA-01017 | 지갑 계정 이름(SEPS_APP)
지갑에 자격 증명 없음(삭제됨) | ORA-01017 | 기록되지 않음(19.3)
프록시 권한 없음 | ORA-01017 | 대상 사용자, DBPROXY_USERNAME에 프록시 사용자
@END

@B 비밀번호가 틀린 경우만 계정 이름으로 남는다. 설정 실수로 생긴 실패는 이름이 비거나 아예 남지 않으므로, 감사 기록만으로 지갑 문제를 모두 찾을 수는 없다.
@B 감사 기록은 메모리 큐에 먼저 쌓인다. 실습처럼 바로 확인하려면 `DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL`로 내려쓴 뒤 조회한다.
@B 실패 횟수는 계정의 FAILED_LOGIN_ATTEMPTS 계산에도 들어간다. 성공한 로그인이 한 번 있으면 이 계산은 0으로 돌아간다.

@CODE
T        DBUSERNAME DBPROXY_US RETURN_CODE
-------- ---------- ---------- -----------
20:23:28 (null)                       1017
20:23:44 SEPS_APP                     1017
20:24:08 SEPS_RPT   SEPS_APP          1017
@END

@H3 1.9.2  실습에서 본 출력 읽기

@B `mkstore -create`에 짧은 비밀번호를 주면 `PKI-01002: Invalid password. Passwords must have a minimum length of eight characters ...`가 나오고 지갑 파일이 하나도 생기지 않는다.
@B `-createCredential` 실행 시 나오는 `Your secret/Password is missing in the command line`은 오류가 아니다. 비밀번호를 대화식으로 묻겠다는 안내다.
@B 지갑을 만든 직후 ewallet.p12·cwallet.sso는 100~200바이트 크기다. 자격 증명 두 개를 넣으면 900바이트 정도로 커진다. 크기가 그대로면 등록이 실패했는지 의심한다.
@B Data Pump를 `/@별칭`으로 실행하면 `Password:` 줄이 잠깐 보이지만 입력을 기다리지 않는다. 작업 로그의 명령행에서는 `@seps_app` 앞의 자격 증명 자리가 별표로 가려진다.
@B tnsping이 OK여도 접속이 ORA-01017로 실패할 수 있다. tnsping은 주소만 확인하고 지갑은 보지 않는다.

@CASE 잠금을 풀었는데 몇 분 뒤 다시 잠긴다
보고서 계정이 잠겨 DBA가 ACCOUNT UNLOCK을 했지만 몇 분 뒤 다시 잠겼다. 비밀번호를 지갑과 같은 값으로 다시 설정해도 같은 일이 반복됐다.
감사 기록의 실패 로그인을 MACHINE별로 묶어 보니, 지갑을 고친 보고서 서버가 아니라 예전에 같은 지갑을 복사해 두었던 다른 서버에서 옛 비밀번호로 접속을 시도하고 있었다.
그 서버의 지갑을 지우고 배치를 중지하자 잠금이 더 이상 생기지 않았다. 이후 지갑 배포 위치를 문서로 관리하기 시작했다.
@END

@H2 1.10  보안 강화와 관련 뷰

@H3 1.10.1  지갑 밖에서 더할 수 있는 통제

@B SEPS는 비밀번호를 숨길 뿐 접속 자체를 제한하지 않는다. 지갑이 유출된 경우를 가정해 DB 쪽 통제를 겹쳐 둔다.
@B 계정 권한을 업무에 필요한 만큼으로 줄인다. 보고서 계정은 SELECT만, 백업 계정은 백업 권한만 갖게 한다.
@B 리스너 쪽 `TCP.VALIDNODE_CHECKING`, `TCP.INVITED_NODES`로 접속 가능한 클라이언트 IP를 제한하면 다른 서버로 복사된 지갑의 사용을 막을 수 있다. 이 설정은 리스너 재기동이 필요하고 모든 접속에 영향을 주므로 신중히 적용한다.
@B LOGON 트리거나 VPD(7장)에서 `SYS_CONTEXT('USERENV', 'IP_ADDRESS')`, `'HOST'`를 검사해 계정별로 허용 호스트를 제한할 수도 있다.
@B 로그인 감사(Unified Auditing의 기본 정책 ORA_LOGON_FAILURES 등)로 지갑 계정의 실패 로그인을 추적한다. 13장에서 감사 기록 관리를 다룬다.

@H3 1.10.2  점검에 쓰는 뷰

@P SEPS는 클라이언트 기능이라 SEPS 전용 데이터 딕셔너리 뷰는 없다. 지갑으로 접속하는 계정의 상태를 서버 쪽 뷰로 점검한다.

@TBL
뷰 | 보는 것
DBA_USERS | ACCOUNT_STATUS(잠김·만료), PROFILE, PASSWORD_CHANGE_DATE, LAST_LOGIN
DBA_PROFILES | FAILED_LOGIN_ATTEMPTS, PASSWORD_LIFE_TIME, PASSWORD_LOCK_TIME 등 프로파일 한도
V$SESSION | 지갑 계정 세션의 MACHINE, PROGRAM, OSUSER
UNIFIED_AUDIT_TRAIL | 지갑 계정의 로그인 성공·실패 기록(감사 정책이 있을 때)
@END

@B 지갑 계정의 PASSWORD_CHANGE_DATE가 지나치게 오래됐다면 비밀번호 순환이 되지 않고 있다는 뜻이다. 정기 점검 항목에 넣는다.
@B V$SESSION의 MACHINE이 예상한 배치 서버가 아니면 지갑이 다른 곳에서 쓰이고 있는지 의심한다.

@CODE
SYS@orcl> SELECT username, account_status, profile, password_change_date, last_login
  2    FROM dba_users WHERE username LIKE 'SEPS%';
@END

@H3 1.10.3  다른 보안 기능과의 조합

@B TLS(11장): 같은 지갑에 CA 인증서를 넣고 별칭을 TCPS로 바꾸면 비밀번호는 지갑에 숨기고 통신은 암호화한다. 이때 SQLNET.WALLET_OVERRIDE가 TRUE면 인증서보다 지갑의 비밀번호가 우선한다.
@B 프록시 인증(2장): 프록시 계정 하나의 비밀번호만 지갑에 두고 여러 대상 사용자로 접속한다. 감사 기록에 실제 사용자와 프록시 계정이 함께 남는다.
@B 감사(13장): 지갑 계정의 로그인 실패를 Unified Auditing으로 기록하고, 정기적으로 PROGRAM·MACHINE별로 묶어 예상하지 못한 접속 위치가 있는지 본다.
@B Application Context(6장): LOGON 트리거에서 지갑 계정의 접속 호스트를 검사하면 다른 서버로 복사된 지갑으로 들어온 세션을 막을 수 있다.

@CASE 형상 관리 저장소에 지갑 디렉터리가 올라갔다
배치 스크립트를 저장소로 옮기면서 스크립트 폴더 아래 두었던 wallet 디렉터리까지 함께 커밋했다. 스크립트에는 비밀번호가 없으니 안전하다고 여겼다.
지갑은 일반 auto-login 지갑이었다. 저장소를 내려받은 누구나 같은 sqlnet.ora 설정만 하면 배치 계정으로 접속할 수 있는 상태였다.
지갑 계정의 비밀번호를 즉시 바꾸고, 지갑을 새로 만들어 저장소 밖 디렉터리에 두었다. 저장소 이력에서도 지갑 파일을 제거하고, .gitignore에 *.p12와 *.sso를 넣었다.
@END

@H2 1.11  운영 시 주의점

@B 지갑 디렉터리의 소유자와 권한을 정기적으로 점검한다. 백업 복원이나 파일 복사 과정에서 권한이 644로 바뀌는 일이 흔하다.
@B 지갑 디렉터리는 웹 서버 문서 루트, 공유 디렉터리, 형상 관리 저장소 밖에 둔다.
@B 지갑을 쓰는 서버가 바뀌면 지갑을 복사하지 말고 새 서버에서 새로 만든다. 복사는 local auto-login이 아닌 지갑에서만 동작하고, 그만큼 유출된 지갑도 어디서나 동작한다.
@B 지갑에 들어 있는 접속 문자열과 계정 목록을 문서로 남긴다. 비밀번호 변경 대상 계정을 찾을 때 지갑부터 뒤지는 일이 없도록 한다.
@B 퇴직자나 역할 변경에 따라 접속을 끊어야 하면 DB 계정을 잠그는 것이 우선이다. 지갑 파일은 이미 복사됐을 수 있다.
@B 서버 쪽 `$ORACLE_HOME/network/admin/sqlnet.ora`에 WALLET_OVERRIDE를 넣지 않는다. 클라이언트 구성은 TNS_ADMIN으로 분리한다.
@B 지갑 계정은 별도 프로파일로 관리한다. 비밀번호 만료로 배치가 멈추지 않게 하되, 순환 주기를 정해 지갑과 함께 바꾼다.
@B 지갑 파일과 TNS 설정 디렉터리를 백업 대상에 넣되, 백업본도 원본과 같은 수준으로 접근을 제한한다.
@B 정기 점검표에 지갑 목록 대조(-listCredential과 tnsnames.ora), 지갑 파일 권한, 지갑 계정의 비밀번호 변경일, 실패 로그인 기록 네 가지를 넣는다.

@H2 1.12  요약

@B SEPS는 DB 접속 비밀번호를 클라이언트 쪽 auto-login 지갑에 암호화해 두고, `/@접속문자열` 접속 때 꺼내 쓰게 하는 기능이다. 서버 설정은 바뀌지 않는다.
@B 지갑은 ewallet.p12(비밀번호로 여는 본체)와 cwallet.sso(auto-login 사본)로 이루어진다. local auto-login은 만든 호스트·OS 사용자에서만 열린다.
@B `mkstore -create`로 지갑을 만들고 `-createCredential`, `-listCredential`, `-modifyCredential`, `-deleteCredential`로 자격 증명을 관리한다.
@B 클라이언트 sqlnet.ora에 `WALLET_LOCATION`과 `SQLNET.WALLET_OVERRIDE = TRUE`를 두고, 접속 문자열은 자격 증명 등록 때와 똑같이 쓴다.
@B 자격 증명은 접속 문자열 단위다. 한 DB에 여러 계정을 쓰려면 별칭을 계정마다 만든다.
@B DB 비밀번호를 바꾸면 지갑을 함께 고쳐야 한다. 놓치면 ORA-01017 반복으로 계정이 잠긴다.
@B 지갑 파일을 읽을 수 있는 사람은 그 계정으로 접속할 수 있다. 지갑 보안은 OS 파일 권한 관리에 달려 있다.
@B 일반 auto-login 지갑은 다른 사용자에게 복사해도 열리고, local 지갑은 ORA-12578로 열리지 않는다.
@B 지갑 설정 실수로 생긴 로그인 실패는 감사 기록에 계정 이름 없이 남거나 아예 남지 않을 수 있다.

@H2 1.13  퀴즈

@QUIZ 문제 1
`sqlplus /@seps_app`으로 접속할 때 지갑의 자격 증명이 쓰이려면 클라이언트 sqlnet.ora에 반드시 있어야 하는 설정 조합은?
① WALLET_LOCATION과 SQLNET.WALLET_OVERRIDE = TRUE  ② SQLNET.AUTHENTICATION_SERVICES = (TCPS)  ③ SSL_CLIENT_AUTHENTICATION = TRUE  ④ ENCRYPTION_WALLET_LOCATION
정답 ①. 지갑 위치를 알려 주는 WALLET_LOCATION과, /@접속 때 지갑의 사용자 이름·비밀번호를 쓰게 하는 SQLNET.WALLET_OVERRIDE = TRUE가 함께 필요하다. 나머지는 TLS나 TDE용 설정이다.
@END

@QUIZ 문제 2
auto-login 지갑에 대한 설명으로 옳은 것은?
① cwallet.sso가 있으면 지갑 비밀번호 없이 지갑을 열 수 있다  ② ewallet.p12를 지우면 접속도 즉시 불가능해진다  ③ local auto-login 지갑은 다른 서버로 복사해도 열린다  ④ 자격 증명 추가 때도 지갑 비밀번호를 묻지 않는다
정답 ①. 접속 때는 cwallet.sso만 읽으므로 비밀번호가 필요 없다. ewallet.p12를 지워도 접속은 되지만 자격 증명을 고칠 수 없다. local auto-login은 만든 호스트·사용자에서만 열리고, 자격 증명 추가·수정은 ewallet.p12를 열어야 하므로 지갑 비밀번호를 묻는다.
@END

@QUIZ 문제 3
같은 orcl 데이터베이스에 SEPS_APP과 SEPS_RPT 두 계정으로 지갑을 이용해 접속하려 한다. 올바른 구성은?
① 별칭 하나에 두 계정을 차례로 -createCredential 한다  ② 지갑을 두 개 만들어 sqlnet.ora에 WALLET_LOCATION을 두 번 적는다  ③ 같은 서비스를 가리키는 별칭을 둘 만들고 각 별칭에 계정을 하나씩 등록한다  ④ 계정 이름을 접속 문자열 뒤에 붙여 /@orcl:seps_rpt로 접속한다
정답 ③. 자격 증명은 접속 문자열을 키로 저장되므로 같은 접속 문자열에 두 계정을 둘 수 없다. 별칭을 계정마다 만들면 한 지갑에서 여러 계정을 구분해 쓸 수 있다.
@END

@QUIZ 문제 4
DBA가 배치 계정의 비밀번호를 ALTER USER로 바꾼 뒤 아무 조치도 하지 않았다. 다음 배치 실행에서 예상되는 결과는?
① 지갑이 새 비밀번호를 자동으로 받아 정상 접속한다  ② ORA-12154가 난다  ③ ORA-28150이 난다  ④ ORA-01017이 나고, 재시도가 반복되면 계정이 잠길 수 있다
정답 ④. 지갑에는 옛 비밀번호가 남아 있어 인증에 실패한다. 실패 횟수가 프로파일의 FAILED_LOGIN_ATTEMPTS를 넘으면 계정이 잠긴다. 비밀번호 변경 직후 mkstore -modifyCredential로 지갑을 맞춰야 한다.
@END

@QUIZ 문제 5
mkstore로 자격 증명을 등록할 때 비밀번호를 명령행 인자로 넣지 않고 대화식으로 입력하는 가장 큰 이유는?
① 명령행 인자는 지갑에 암호화되지 않기 때문이다  ② 명령행 인자는 ps 출력과 셸 히스토리에 남기 때문이다  ③ 명령행 인자로는 특수 문자를 쓸 수 없기 때문이다  ④ 대화식 입력만 복잡도 검사를 하기 때문이다
정답 ②. 명령행에 넣은 비밀번호는 실행 중 프로세스 목록과 히스토리 파일에 평문으로 남는다. 비밀번호를 파일과 화면에서 없애려는 SEPS의 목적과 어긋난다.
@END

@QUIZ 문제 6
SEPS를 쓰는 서버에서 보안상 가장 먼저 점검할 항목은?
① 지갑 디렉터리와 파일의 OS 권한  ② 서버 sqlnet.ora의 SQLNET.WALLET_OVERRIDE 값  ③ V$ENCRYPTION_WALLET의 STATUS  ④ DB의 REMOTE_LOGIN_PASSWORDFILE
정답 ①. auto-login 지갑은 비밀번호 없이 열리므로 지갑 파일을 읽을 수 있는 사람은 그 DB 계정으로 접속할 수 있다. 디렉터리 700, 파일 600, 소유자 확인이 기본이다. V$ENCRYPTION_WALLET은 TDE 지갑을 보여 주는 뷰다.
@END

@H2 1.14  실습 개요

@P 실습은 oel7v9 서버의 orcl 데이터베이스(19.3, non-CDB)에서 진행한다. 서버의 `$ORACLE_HOME/network/admin` 파일은 건드리지 않고, `/home/oracle/seps` 아래에 지갑과 별도 TNS_ADMIN 디렉터리를 만들어 쓴 뒤 마지막에 철거한다. 실습에서는 기록을 남기려고 printf로 비밀번호를 넘기지만 운영에서는 대화식으로 입력한다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
1장_실습_01_지갑생성과자격증명등록 | 지갑 비밀번호 복잡도(PKI-01002), mkstore -create, -createCredential, -listCredential, -list | 1.3, 1.4
1장_실습_02_클라이언트구성과접속 | 별도 TNS_ADMIN, WALLET_OVERRIDE 누락(ORA-01017), 별칭 누락(ORA-12154), AUTHENTICATION_METHOD | 1.5
1장_실습_03_자격증명관리와비밀번호동기화 | 중복 등록 거부, 비밀번호 변경 후 ORA-01017과 -modifyCredential, -viewEntry, 삭제, 실패 로그인 감사 | 1.4.3, 1.6, 1.9.1
1장_실습_04_배치와프록시활용 | expdp /@별칭, 빈 환경(크론)의 ORA-12154, 프록시 자격 증명과 CONNECT THROUGH | 1.5.4, 1.6.2, 1.7
1장_실습_05_local지갑과철거 | orapki -auto_login_local, 다른 OS 사용자에서 ORA-12578, 일반 지갑 복사 위험, 원복 | 1.3.2, 1.9
@END
