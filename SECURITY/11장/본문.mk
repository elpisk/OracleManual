@H1 제11장  TLS(SSL) 네트워크 암호화

@H2 11.1  학습 목표

@P 클라이언트와 데이터베이스 사이를 오가는 SQL, 결과, 비밀번호 검증 정보는 기본 설정에서 네트워크에 그대로 흐른다. TLS(Transport Layer Security)는 이 구간을 암호화하고, 인증서로 상대방이 진짜인지 확인한다.

@B 네트워크 구간에서 생기는 위협(도청, 변조, 중간자 공격)과 TLS가 각각을 막는 방식을 설명할 수 있다.
@B 공개 키·개인 키, 인증서, 인증 기관(CA), 신뢰 인증서의 관계를 설명할 수 있다.
@B `orapki`로 서버·클라이언트 지갑을 만들고, 자체 서명 CA로 인증서 요청에 서명하고, 인증서를 지갑에 가져올 수 있다.
@B TCPS 리스너, 서버·클라이언트 sqlnet.ora, tnsnames.ora의 TLS 관련 설정을 구성할 수 있다.
@B 인증서 DN으로 데이터베이스 사용자를 만들어 비밀번호 없이 인증서로 로그인할 수 있다.
@B 접속이 실제로 TLS인지 `SYS_CONTEXT('USERENV', ...)`로 확인하고, 대표적인 TLS 오류의 원인을 찾을 수 있다.

@H2 11.2  TLS의 개념

@H3 11.2.1  네트워크 구간의 위협

@B Oracle Net의 기본 TCP 접속은 SQL 문장과 결과 데이터를 평문으로 보낸다. 같은 네트워크 구간에서 패킷을 캡처하면 조회 결과를 그대로 읽을 수 있다.
@B 비밀번호 자체는 평문으로 보내지 않지만, 검증 과정에서 오가는 값은 오프라인 추측 공격의 재료가 될 수 있다.
@B 중간자 공격은 공격자가 클라이언트와 서버 사이에 끼어 양쪽에 상대방인 척하는 것이다. 클라이언트가 서버의 신원을 확인하지 않으면 막을 수 없다.
@B TLS는 세 가지를 제공한다. 암호화(기밀성), 메시지 인증 코드(무결성), 인증서 검증(상대방 인증)이다.
@B 변조 공격은 오가는 패킷의 내용을 바꾸는 것이다. 암호화만 하고 무결성 검사를 하지 않으면 내용은 못 읽어도 일부를 바꿔 끼울 수 있다. TLS는 메시지마다 무결성 값을 붙여 바뀐 패킷을 버린다.
@B 무선망, 공용 클라우드, 여러 조직이 함께 쓰는 데이터 센터처럼 네트워크 구간을 직접 통제하지 못하는 환경일수록 구간 암호화의 필요가 커진다.

@H3 11.2.2  TLS와 네이티브 네트워크 암호화

@TBL
구분 | TLS(TCPS) | 네이티브 네트워크 암호화
구성 | 지갑·인증서, TCPS 리스너 | sqlnet.ora 파라미터만
상대방 인증 | 인증서로 서버(및 클라이언트) 인증 | 없음
포트 | 별도 TCPS 포트(관례상 2484) | 기존 TCP 포트 그대로
사용자 인증에 활용 | 인증서 기반 로그인 가능 | 불가
표준 | 업계 표준 프로토콜 | Oracle 고유
@END

@B 네이티브 네트워크 암호화(`SQLNET.ENCRYPTION_SERVER` 등)는 구성이 간단하지만 서버 신원을 확인하지 않는다.
@B 규제나 감사가 "표준 TLS"를 요구하거나 인증서 기반 인증이 필요하면 TLS를 쓴다.
@B 두 방식은 성능 차이보다 운영 부담의 차이가 크다. 네이티브 암호화는 인증서 관리가 없고, TLS는 인증서 발급·배포·갱신 절차가 따라온다. 도입 전에 그 절차를 누가 맡을지부터 정한다.
@B 두 방식 모두 19c Enterprise Edition의 기본 기능이다. 예전에는 Advanced Security 옵션에 포함됐지만 지금은 별도 라이선스가 필요하지 않다.
@B 문서와 파라미터 이름에 SSL이라는 말이 남아 있다. SSL은 TLS의 이전 이름이며, 19c에서 실제로 쓰는 프로토콜은 TLS 1.2 이상이 권장된다.

@H3 11.2.3  TLS 핸드셰이크 흐름

@TBL
단계 | 하는 일
1. 클라이언트 hello | 지원하는 TLS 버전과 암호 스위트 목록을 보냄
2. 서버 hello와 인증서 | 사용할 버전·스위트를 정하고 서버 인증서를 보냄
3. 서버 인증 | 클라이언트가 서버 인증서를 신뢰 인증서(CA)로 검증
4. 클라이언트 인증서(선택) | 서버가 요구하면 클라이언트도 인증서를 보내고 서버가 검증
5. 세션 키 교환 | 양쪽이 대칭 세션 키를 합의
6. 암호화 통신 | 이후 Oracle Net 데이터 전체를 세션 키로 암호화
@END

@B 서버만 인증서를 보내는 방식을 단방향 TLS, 클라이언트도 인증서를 보내는 방식을 상호 TLS(mutual TLS)라 한다.
@B 상호 TLS에서 클라이언트 인증서는 데이터베이스 로그인 수단으로도 쓸 수 있다. 원본 실습 자료가 이 구성을 다룬다.
@B 서버 쪽 `SSL_CLIENT_AUTHENTICATION = TRUE`가 상호 TLS를 요구하는 설정이다. 기본값이 TRUE다.
@B 상호 TLS는 비밀번호 대신 인증서로 사용자를 확인하므로 비밀번호 추측 공격이 통하지 않는다. 대신 클라이언트마다 인증서를 발급하고 관리하는 부담이 생긴다.
@B 실무에서는 애플리케이션 서버처럼 접속 주체가 적은 곳에 상호 TLS를, 일반 사용자 접속에는 단방향 TLS와 비밀번호 인증을 조합하는 경우가 많다.

@H3 11.2.4  암호 스위트

@P 암호 스위트(cipher suite)는 핸드셰이크와 본 통신에 쓸 알고리즘의 묶음이다. 양쪽이 지원하는 스위트 중 하나가 협상으로 정해진다.

@TBL
구성 요소 | 역할 | 예
키 교환 | 세션 키를 안전하게 합의 | ECDHE, RSA
인증 | 인증서의 서명 방식 | RSA, ECDSA
대칭 암호 | 본 통신 암호화 | AES_128_GCM, AES_256_GCM
해시(MAC) | 무결성 검사 | SHA256, SHA384
@END

@B 스위트 이름은 이 요소를 이어 붙인 것이다. `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`는 ECDHE 키 교환, RSA 인증서, AES 256 GCM 암호, SHA384 해시를 쓴다.
@B ECDHE처럼 매 세션 임시 키를 쓰는 방식은 서버 개인 키가 나중에 유출돼도 과거 통신을 풀 수 없게 한다(전방 비밀성).
@B 특별한 요구가 없으면 스위트 목록을 지정하지 않고 기본값에 맡긴다. 규제가 특정 스위트를 요구할 때만 `SSL_CIPHER_SUITES`로 제한한다. 값은 괄호로 감싸야 제대로 해석된다.

@H3 11.2.5  TLS가 막지 않는 것

@B TLS는 통신 구간만 보호한다. 클라이언트나 서버 자체가 침해되면 그 안에서 평문으로 다뤄지는 데이터는 보호하지 못한다.
@B 디스크에 저장된 데이터 파일, 백업, 덤프 파일은 TLS와 관계가 없다. 저장 데이터는 TDE(10장)가 맡는다.
@B 정상적으로 로그인한 사용자가 권한 범위 안에서 데이터를 읽는 것도 막지 않는다. 행·컬럼 단위 통제는 VPD(7장)와 Data Redaction(8장)이 맡는다.
@B SQL 인젝션처럼 애플리케이션 논리를 노린 공격도 암호화된 통로를 그대로 통과한다.

@H2 11.3  인증서와 지갑

@H3 11.3.1  구성 요소

@TBL
구성 요소 | 내용
개인 키 | 소유자만 가진 비밀 키. 지갑 안에 보관
공개 키 | 개인 키와 짝을 이루는 키. 인증서에 담겨 상대방에게 전달
인증서 | 공개 키와 소유자 이름(DN)을 묶고 CA가 서명한 문서
인증 기관(CA) | 인증서에 서명하는 주체. CA의 인증서가 신뢰의 출발점
신뢰 인증서 | 상대방 인증서를 검증할 때 쓰는 CA 인증서. 지갑에 등록
DN(Distinguished Name) | 인증서 소유자 이름. 예: CN=client,O=oracle,C=KR
@END

@B 서버 지갑에는 서버의 개인 키·인증서와, 클라이언트 인증서를 검증할 CA 인증서가 들어간다.
@B 클라이언트 지갑에는 서버 인증서를 검증할 CA 인증서와, 상호 TLS라면 클라이언트 자신의 개인 키·인증서가 들어간다.
@B 양쪽이 같은 CA를 신뢰하면 서로의 인증서를 검증할 수 있다. 실습에서는 서버 지갑의 자체 서명 인증서를 CA로 삼는다.
@B 개인 키는 지갑 밖으로 나가지 않는다. 인증서 요청(CSR)에는 공개 키와 DN만 들어 있어 CA에 보내도 안전하다.
@B 반대로 서명된 인증서와 CA 인증서도 비밀이 아니다. 원본 자료가 두 파일을 scp로 주고받는 것도 그래서 문제가 없다. 지켜야 할 것은 지갑 안의 개인 키다.

@H3 11.3.2  자체 서명 CA와 공인 CA

@B 운영 환경에서는 사내 CA나 공인 CA가 서명한 인증서를 쓴다. 인증서 요청(CSR)을 CA에 보내고 서명된 인증서를 받아 지갑에 가져온다.
@B 실습과 개발 환경에서는 `orapki wallet add -self_signed`로 만든 자체 서명 인증서를 CA로 쓴다. 원본 자료의 방식이며, 실제 CA 없이 전체 흐름을 재현할 수 있다.
@B 자체 서명 인증서를 CA로 쓰면 그 인증서를 신뢰 인증서로 등록한 클라이언트만 서버를 신뢰한다. 등록하지 않은 클라이언트는 접속에 실패한다.

@B 공인 CA 인증서는 브라우저처럼 널리 신뢰되지만, DB 접속에서는 클라이언트가 어떤 CA를 신뢰할지 직접 정한다. 공인 CA를 쓴다고 클라이언트 지갑 배포가 사라지지는 않는다.
@B 사내 CA를 쓰면 루트 CA 인증서 하나를 모든 클라이언트에 배포해 두고, 서버 인증서는 그 CA로 계속 발급·갱신할 수 있다. 인증서를 바꿀 때마다 클라이언트를 손대지 않아도 된다.

@H3 11.3.3  orapki 지갑 명령

@TBL
작업 | 명령
지갑 생성 | orapki wallet create -wallet 디렉터리 -pwd 비밀번호 -auto_login[_local]
자체 서명 인증서 | orapki wallet add -wallet 디렉터리 -dn "CN=..." -keysize 2048 -self_signed -validity 일수 -pwd 비밀번호
인증서 요청 생성 | orapki wallet add -wallet 디렉터리 -dn "CN=..." -keysize 2048 -pwd 비밀번호
요청 내보내기 | orapki wallet export -wallet 디렉터리 -dn "CN=..." -request 파일 -pwd 비밀번호
요청에 서명 | orapki cert create -wallet CA지갑 -request 파일 -cert 출력파일 -validity 일수 -pwd 비밀번호
인증서 내보내기 | orapki wallet export -wallet 디렉터리 -dn "CN=..." -cert 파일
신뢰 인증서 가져오기 | orapki wallet add -wallet 디렉터리 -trusted_cert -cert 파일 -pwd 비밀번호
사용자 인증서 가져오기 | orapki wallet add -wallet 디렉터리 -user_cert -cert 파일 -pwd 비밀번호
내용 보기 | orapki wallet display -wallet 디렉터리
@END

@B `-auto_login`을 주면 cwallet.sso가 함께 만들어진다. 서버 프로세스와 리스너는 비밀번호를 입력할 수 없으므로 TLS 지갑은 auto-login이어야 한다.
@B 인증서 요청을 만들면 지갑에 "요청 중" 상태의 항목이 생긴다. 서명된 인증서를 `-user_cert`로 가져오면 그 항목이 사용자 인증서로 바뀐다.
@B 정상 순서는 서명한 CA 인증서를 `-trusted_cert`로 먼저 넣고 사용자 인증서를 나중에 넣는 것이다. orapki도 "Please add all trusted certificates before adding the user certificate"라고 안내한다.
@B 19.3의 orapki는 순서를 바꿔도 사용자 인증서 가져오기를 막지 않았다(실습 02). 도구가 막지 않는다고 순서가 상관없다는 뜻은 아니다. CA가 빠진 지갑은 접속 단계에서 인증서 검증에 실패한다.

@H3 11.3.4  키 길이

@B 원본 실습 자료는 서버 인증서에 `-keysize 512`, 클라이언트에 `-keysize 1024`를 쓴다. 오래된 예제의 값이다.
@B 512비트, 1024비트 RSA 키는 현재 안전하지 않은 것으로 본다. 19c 실습에서는 2048비트 이상을 쓴다.
@B 19.3의 orapki는 원본 그대로 `-keysize 512`를 줘도 "Operation is successfully completed"로 인증서를 만들었다(실습 01). 키 길이 검사는 도구가 아니라 운영 기준이 맡는다.
@B 키 길이를 늘리면 핸드셰이크 비용이 늘지만 세션 키로 하는 본 통신 비용에는 영향이 거의 없다.

@H3 11.3.5  인증서의 내용과 체인

@TBL
항목 | 의미
Subject | 인증서 소유자 DN
Issuer | 서명한 CA의 DN. 자체 서명이면 Subject와 같음
Validity | 유효 기간 시작·끝
Serial Number | CA가 매긴 일련번호
Public Key | 소유자 공개 키와 길이
Signature | CA의 서명
@END

@B 인증서 파일은 보통 Base64로 인코딩된 PEM 형식이다. `-----BEGIN CERTIFICATE-----`로 시작한다.
@B `orapki cert display -cert 파일 -complete`로 인증서 내용을 읽을 수 있다. Subject와 Issuer를 보면 누가 누구에게 서명했는지 알 수 있다.
@B 인증서 체인은 사용자 인증서 → 중간 CA → 루트 CA로 이어진다. 검증하는 쪽은 체인 끝의 루트 CA를 신뢰 인증서로 갖고 있어야 한다. 실습의 체인은 클라이언트 인증서 → 서버 자체 서명 인증서의 두 단계다.
@B 유효 기간이 지난 인증서는 체인 어디에 있든 검증을 실패시킨다. 중간 CA의 만료도 감시 대상이다.

@H3 11.3.6  지갑 종류와 TLS

@B TLS에 쓰는 지갑도 1장의 SEPS 지갑과 같은 파일 형식(ewallet.p12, cwallet.sso)이다. 차이는 PKI 영역에 인증서와 키가 들어 있다는 점이다.
@B 리스너와 서버 프로세스는 사람이 비밀번호를 입력할 수 없으므로 서버 지갑은 auto-login이어야 한다. 클라이언트 지갑도 sqlplus가 비밀번호 없이 열 수 있어야 하므로 auto-login으로 만든다.
@B 같은 호스트에서만 쓰는 지갑은 `-auto_login_local`이 안전하다. 원본 자료는 클라이언트가 서버와 같은 머신이면 -auto_login_local을, 다른 머신으로 옮길 지갑이면 -auto_login을 쓰라고 안내한다.
@B orapki로 지갑 내용을 바꿀 때마다 지갑 비밀번호(-pwd)가 필요하다. 명령행 인자로 넣으면 히스토리에 남으므로 운영에서는 -pwd를 생략해 대화식으로 입력한다.

@H3 11.3.7  orapki를 쓸 때 주의할 점

@P 실습 01·02에서 19.3 orapki가 예상과 다르게 동작한 지점이다. 명령이 성공했다는 메시지만 믿지 말고 `orapki wallet display`로 결과를 확인한다.

@TBL
상황 | 19.3 orapki 동작 | 대처
같은 디렉터리에 wallet create 재실행 | 성공 메시지, 기존 인증서가 그대로 남음 | 지갑 파일을 지우고 새로 만든다
같은 DN 자체 서명 인증서를 두 번 add | 둘 다 들어가 인증서가 중복 | display로 확인, 섞였으면 다시 만든다
지갑 비밀번호를 틀림 | PKI-02003: Unable to load the wallet (incorrect password) | 비밀번호 확인
지갑에 없는 DN으로 export | could not found certificate with matching DN | display로 DN 확인
이미 있는 사용자 인증서를 다시 add | PKI-04004: already installed | 다시 넣을 필요 없음
@END

@B 512비트 인증서가 남은 지갑에 새 인증서를 더해 여러 사용자 인증서가 섞이자, 예비 시험에서 클라이언트 접속이 모두 ORA-29024로 실패했다. 지갑 하나에는 용도에 맞는 사용자 인증서 하나만 둔다.
@B 지갑을 고친 뒤에는 그 지갑을 쓰는 리스너를 다시 시작한다. 실행 중인 리스너가 옛 지갑을 물고 있으면 ORA-28860 같은 핸드셰이크 오류가 난다.

@H3 11.3.8  인증서 수명 주기

@TBL
단계 | 하는 일 | 놓치기 쉬운 것
발급 | 키 생성, 요청(CSR), CA 서명 | 키 길이, DN 규칙, 유효 기간
배포 | 서버·클라이언트 지갑에 설치, CA 인증서 배포 | 모든 클라이언트에 CA 인증서
갱신 | 만료 전 새 인증서로 교체 | 새 CA로 바뀌면 클라이언트 선배포
폐기 | 유출·퇴직 시 인증서 무효화 | DB 사용자 잠금을 먼저
@END

@B 인증서 기반 사용자는 인증서가 곧 로그인 수단이다. 퇴직자의 인증서가 아직 유효 기간 안이라면 DB 사용자를 잠그거나 지워야 접속이 막힌다.
@B 자체 서명 CA는 폐기 목록을 운영하기 어렵다. 인증서 하나를 무효화하려면 CA부터 다시 만들어야 하는 경우가 생긴다. 운영에는 폐기 기능이 있는 사내 CA를 쓴다.

@BP 인증서 관리 원칙
지갑 하나에는 용도에 맞는 사용자 인증서 하나만 둔다.
인증서마다 만료일, 설치 위치, 담당자를 목록으로 관리하고 만료 90일·30일 전에 경보를 건다.
CA를 바꿀 때는 새 CA 인증서를 모든 클라이언트에 먼저 배포한 뒤 서버 인증서를 교체한다.
지갑을 고친 뒤에는 그 지갑을 쓰는 리스너를 다시 시작하고 실제 로그인으로 확인한다.
@END

@H3 11.3.9  원본 자료 절차와 이 교안 실습

@TBL
원본 단계 | 원본 내용 | 이 교안 실습에서
1 서버 지갑 | orapki create, 512비트 자체 서명 | 01. 512비트는 19.3도 받아들이지만 2048비트로 다시 만듦
2 클라이언트 지갑 | 1024비트 요청, scp로 서버에 전달 | 02. 2048비트, 같은 VM의 디렉터리로 전달
3 DB 사용자 | IDENTIFIED EXTERNALLY AS 'CN=client,...' | 03. CN=tls_client,O=itwill,C=KR
4 리스너 | 기존 리스너에 TCPS 1522 추가 | 03. 별도 LISTENER_TLS 2484
5·6 sqlnet.ora | 서버·클라이언트에 TCPS, SSL_VERSION=0 | 03·04. SSL_VERSION 생략(협상)
7 tnsnames | ORCLSSL 별칭 | 04. ORCL_TLS 별칭
8 DB 파라미터 | OS_AUTHENT_PREFIX='' 후 재기동 | 생략. 기본값 그대로 인증서 로그인 확인
9 시험 | tnsping, sqlplus /@ORCLSSL | 04. SYS_CONTEXT로 tcps·SSL 확인
@END

@H3 11.3.10  인증서 폐기 확인(CRL)

@P 유효 기간 안의 인증서도 개인 키 유출이나 퇴직으로 무효화해야 할 때가 있다. CA는 무효화한 인증서를 폐기 목록(CRL)에 올리고, 검증하는 쪽은 이 목록을 대조한다. 실습에서는 구성하지 않았으며 아래는 Security Guide 기준이다.

@TBL
SSL_CERT_REVOCATION 값 | 동작
NONE(기본값) | 폐기 여부를 확인하지 않음
REQUESTED | CRL이 있으면 확인. 폐기된 인증서는 거부, CRL이 없으면 접속 허용
REQUIRED | 반드시 확인. 폐기된 인증서뿐 아니라 CRL을 찾지 못해도 거부
@END

@B 서버는 로컬 파일(SSL_CRL_FILE, SSL_CRL_PATH, 둘 다 없으면 지갑 위치), 디렉터리 서버(Oracle Internet Directory), 인증서의 CRL 배포 지점 순으로 CA의 DN에 맞는 CRL을 찾는다.
@B CRL 파일은 `orapki crl hash -crl 파일 -symlink 디렉터리`로 발급자 이름의 해시 값 링크를 만들어 둬야 서버가 찾는다. 파일만 복사해 두면 읽히지 않는다.
@B CRL에도 유효 기간이 있다. REQUIRED로 운영하면서 CRL 갱신을 놓치면 정상 인증서까지 모두 거부되므로, CRL 갱신을 인증서 만료 감시와 같은 목록에 넣는다.
@B 매뉴얼은 NONE을 기본값으로 두되, 네트워크 ACL 등 다른 수단으로 접속 주체를 제한하지 않는 환경에서는 NONE을 권하지 않는다. 폐기 확인이 없으면 11.3.8의 폐기 단계는 DB 사용자 잠금으로만 실현된다.

@H2 11.4  서버 구성

@H3 11.4.1  TCPS 리스너

@CODE
LISTENER_TLS =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCPS)(HOST = oel7v9)(PORT = 2484))
    )
  )
WALLET_LOCATION =
  (SOURCE = (METHOD = FILE)
    (METHOD_DATA = (DIRECTORY = /home/oracle/tls/server_wallet)))
SSL_CLIENT_AUTHENTICATION = FALSE
@END

@B TCPS 주소는 기존 리스너에 추가해도 되고 별도 리스너로 띄워도 된다. 관례적인 포트는 2484다. 원본 자료는 기존 리스너에 1522번 TCPS 주소를 추가한다.
@B 리스너도 TLS 핸드셰이크에 참여하므로 listener.ora에 WALLET_LOCATION이 필요하다.
@B 리스너 쪽 `SSL_CLIENT_AUTHENTICATION`은 보통 FALSE로 둔다. 클라이언트 인증은 연결을 넘겨받은 서버 프로세스가 하기 때문이다.
@B 데이터베이스가 TCPS 리스너에 서비스를 등록해야 한다. 동적 등록은 LOCAL_LISTENER 파라미터에 TCPS 주소를 넣고, 정적 등록은 SID_LIST에 데이터베이스를 적는다.
@B 리스너는 지갑을 시작할 때 읽는다. 지갑을 바꾼 뒤에는 리스너를 다시 시작해야 새 인증서가 쓰인다.
@B TCPS 포트도 방화벽 규칙에 따로 열어야 한다. 1521만 열려 있는 환경에서 2484 접속은 리스너까지 오지 못한다.

@H3 11.4.2  서비스 등록 방식

@TBL
방식 | 구성 | 특징
동적 등록 | LOCAL_LISTENER에 TCPS 주소 추가 | 인스턴스가 서비스 상태를 알림. 파라미터 변경 필요
정적 등록 | listener.ora의 SID_LIST에 SID_DESC | 인스턴스 상태와 무관하게 서비스 표시. ENVS로 환경 변수 지정 가능
@END

@B 기존 리스너에 TCPS 주소를 추가하면 그 리스너에 이미 동적 등록된 서비스가 TCPS 주소로도 열린다. 가장 단순한 운영 구성이다.
@B 별도 리스너를 띄우면 LOCAL_LISTENER에 그 리스너 주소를 추가하거나 정적 등록을 해야 서비스가 보인다.
@B 정적 등록의 `ENVS`는 리스너가 서버 프로세스를 띄울 때 넘길 환경 변수다. 실습은 `ENVS = "TNS_ADMIN=..."`으로 TCPS 경로의 서버 프로세스만 별도 sqlnet.ora를 읽게 한다.
@B `lsnrctl status`에서 서비스 상태가 READY면 동적 등록, UNKNOWN이면 정적 등록이다.

@CODE
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = oel7v9)(PORT = 1521)))
    (DESCRIPTION = (ADDRESS = (PROTOCOL = TCPS)(HOST = oel7v9)(PORT = 2484))))
@END

@B 위는 원본 자료 방식처럼 기존 리스너에 TCPS 주소를 더한 예다. 이 경우 listener.ora와 서버 sqlnet.ora에 WALLET_LOCATION을 넣고 리스너를 재기동한다. 운영 중인 리스너라 재기동 시점을 잡아야 한다.

@H3 11.4.3  서버 sqlnet.ora

@CODE
WALLET_LOCATION =
  (SOURCE = (METHOD = FILE)
    (METHOD_DATA = (DIRECTORY = /home/oracle/tls/server_wallet)))
SQLNET.AUTHENTICATION_SERVICES = (BEQ, TCPS)
SSL_CLIENT_AUTHENTICATION = TRUE
@END

@B 서버 프로세스가 읽는 sqlnet.ora다. WALLET_LOCATION은 서버 지갑을 가리킨다.
@B `SQLNET.AUTHENTICATION_SERVICES`에 TCPS를 넣어야 인증서 기반 로그인을 받는다. BEQ는 로컬 `/ as sysdba` 접속에 필요하므로 함께 둔다.
@B `SSL_CLIENT_AUTHENTICATION = TRUE`면 클라이언트 인증서를 요구한다. 단방향 TLS(암호화만)라면 FALSE로 두고 클라이언트는 비밀번호로 로그인한다.
@B 서버 sqlnet.ora를 고치면 그 Oracle Home의 모든 서버 프로세스가 영향을 받는다. 실습은 TCPS 리스너와 그 리스너가 띄우는 서버 프로세스만 별도 TNS_ADMIN을 쓰게 해 기존 접속에 영향을 주지 않는다.

@B 서버 프로세스는 자신을 띄운 리스너의 환경을 물려받는다. 정적 등록의 ENVS에 TNS_ADMIN을 넣으면 그 리스너를 거쳐 들어온 세션만 별도 sqlnet.ora를 읽는다.
@B 동적 등록으로 연결되는 경우에는 인스턴스 쪽 환경이 기준이 되므로, 서버 sqlnet.ora는 보통 $ORACLE_HOME/network/admin에 둔다. 실습처럼 경로를 분리하는 구성은 학습·시험용이다.

@H3 11.4.4  인증서 사용자

@CODE
SYS@orcl> CREATE USER tls_client IDENTIFIED EXTERNALLY AS 'CN=tls_client,O=itwill,C=KR';
SYS@orcl> GRANT CREATE SESSION TO tls_client;
@END

@B `IDENTIFIED EXTERNALLY AS 'DN'`는 이 DN의 인증서로 들어온 접속을 이 사용자로 로그인시킨다. DN 문자열은 인증서의 DN과 정확히 같아야 한다.
@B 원본 자료는 이 단계와 함께 `REMOTE_OS_AUTHENT=FALSE`, `OS_AUTHENT_PREFIX=''`를 설정하고 재기동한다. OS_AUTHENT_PREFIX는 `IDENTIFIED EXTERNALLY`(AS 없이)로 만든 OS 인증 사용자 이름에 붙는 접두사라, DN을 지정한 인증서 사용자와는 관계가 없다. 실습에서는 OS_AUTHENT_PREFIX를 기본값 ops$로 둔 채 인증서 로그인이 됐다.
@B DBA_USERS의 EXTERNAL_NAME에는 DN이 `cn=tls_client,o=itwill,c=KR`처럼 속성 이름만 소문자로 바뀌어 저장됐다. 인증서의 DN(`CN=...,O=...`)과 대소문자가 달라도 로그인에는 문제가 없었다.
@B DN을 고칠 때는 `ALTER USER 사용자 IDENTIFIED EXTERNALLY AS '새 DN'`을 쓴다. 사용자를 지우고 다시 만들 필요가 없다.
@B 인증서 사용자는 비밀번호가 없다. 인증서와 개인 키가 든 지갑이 곧 로그인 수단이므로 클라이언트 지갑 보호가 중요하다.
@B 같은 사용자를 보는 뷰마다 인증 방식 표기가 다르다. DBA_USERS의 AUTHENTICATION_TYPE은 EXTERNAL이었고, 로그인한 세션을 V$SESSION_CONNECT_INFO로 보면 GLOBAL이었다. 점검 스크립트에서 인증서 사용자를 고를 때는 DBA_USERS의 EXTERNAL_NAME에 'cn='이 들어 있는지로 OS 인증 사용자와 구분한다.

@H3 11.4.5  TCPS 리스너 운영

@B 별도 TNS_ADMIN의 리스너는 시작·중지·상태 확인 때마다 같은 TNS_ADMIN을 설정해야 한다. 설정을 빠뜨리면 lsnrctl이 공용 listener.ora를 읽어 엉뚱한 리스너를 다룬다.
@B 이미 떠 있는 리스너를 다시 start하면 TNS-01106: Listener ... has already been started가 난다. 상태는 `lsnrctl status 리스너이름`으로 확인한다.
@B lsnrctl status 출력의 Listening Endpoints에 `(PROTOCOL=tcps)(PORT=2484)`가 보여야 한다. 정적 등록 서비스는 status UNKNOWN으로 나온다.
@B 리스너 로그는 ADR 아래 `diag/tnslsnr/호스트/리스너이름` 디렉터리에 리스너마다 따로 쌓인다. 실습의 LISTENER_TLS는 listener_tls 디렉터리를 쓴다.

@H3 11.4.6  TCP와 TCPS 병행 운영

@B 전환 기간에는 1521(TCP)과 2484(TCPS)가 함께 열린다. 같은 서비스에 두 경로로 접속할 수 있으므로 어느 클라이언트가 아직 TCP를 쓰는지 추적해야 한다.
@B 실습 04처럼 같은 계정이 TCPS 별칭으로는 tcps, Easy Connect로는 tcp로 접속된다. 클라이언트 설정 하나만 틀려도 평문 접속이 된다.
@B 모든 클라이언트가 옮겨 간 것을 감사 기록으로 확인한 뒤 TCP 포트를 닫는다. 리스너의 TCP 주소를 지우거나 방화벽에서 1521을 막는다.
@B 로컬 관리 접속(`/ as sysdba`)은 리스너를 거치지 않는 BEQ 접속이라 TCP 주소를 닫아도 영향이 없다.

@H2 11.5  클라이언트 구성

@H3 11.5.1  클라이언트 sqlnet.ora와 tnsnames.ora

@CODE
WALLET_LOCATION =
  (SOURCE = (METHOD = FILE)
    (METHOD_DATA = (DIRECTORY = /home/oracle/tls/client_wallet)))
SQLNET.AUTHENTICATION_SERVICES = (TCPS)
SSL_CLIENT_AUTHENTICATION = TRUE

ORCL_TLS =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCPS)(HOST = oel7v9)(PORT = 2484))
    (CONNECT_DATA = (SERVICE_NAME = orcl)))
@END

@B 클라이언트 WALLET_LOCATION은 클라이언트 지갑을 가리킨다. 이 지갑에 서버 인증서를 검증할 CA 인증서가 있어야 한다.
@B 별칭의 PROTOCOL이 TCPS여야 TLS로 접속한다. TCP 별칭으로 접속하면 지갑이 있어도 평문 접속이다.
@B 인증서로 로그인할 때는 `sqlplus /@ORCL_TLS`처럼 사용자 이름과 비밀번호를 비운다. SEPS(1장)와 같은 형식이지만 동작은 다르다. SEPS는 지갑의 비밀번호를, TLS 인증은 지갑의 인증서를 쓴다.
@B 같은 지갑에 SEPS 자격 증명도 있고 `SQLNET.WALLET_OVERRIDE = TRUE`면 지갑의 사용자 이름·비밀번호가 우선한다. 인증서 로그인을 원하면 WALLET_OVERRIDE를 두지 않는다.

@H3 11.5.2  TLS 관련 파라미터

@TBL
파라미터 | 위치 | 의미 | 기본값
WALLET_LOCATION | 서버·클라이언트·리스너 | 지갑 디렉터리 | 없음
SSL_CLIENT_AUTHENTICATION | 서버·클라이언트 | 클라이언트 인증서 사용(상호 TLS) | TRUE
SSL_VERSION | 서버·클라이언트 | 허용 TLS 버전 | 정해지지 않음(양쪽 협상)
SSL_CIPHER_SUITES | 서버·클라이언트 | 허용 암호 스위트 목록 | 없음(기본 목록)
SSL_SERVER_DN_MATCH | 클라이언트 | 서버 인증서 DN을 접속 대상과 대조 | NO
SQLNET.AUTHENTICATION_SERVICES | 서버·클라이언트 | TCPS 포함 시 인증서 로그인 | 없음
@END

@B 원본 자료의 `SSL_VERSION = 0`은 버전을 지정하지 않고 협상에 맡긴다는 뜻이다.
@B 최신 19c 릴리스 업데이트 문서는 이 파라미터들을 TLS_VERSION, TLS_CLIENT_AUTHENTICATION, TLS_CIPHER_SUITES, TLS_SERVER_DN_MATCH라는 새 이름으로 소개하고 SSL_ 이름을 디프리케이트로 표시한다. 실습 환경 19.3은 SSL_ 이름을 쓴다.
@B `SSL_SERVER_DN_MATCH = YES`를 켜면 서버 인증서 DN과 접속 대상을 대조한다. 중간자 공격 방어가 강해지므로 운영 클라이언트에서 검토한다.
@B 매뉴얼은 특별한 요구가 없으면 SSL_VERSION을 바꾸지 말라고 권한다. 구버전 클라이언트와의 호환 문제가 생기기 쉽다.
@B 최신 19c 문서는 SSL_ 이름과 TLS_ 이름이 함께 설정되면 SSL_ 쪽을 무시한다고 적는다. 릴리스 업데이트를 올리면서 새 이름을 일부만 추가하면 의도하지 않은 값이 적용될 수 있으므로 한 파일 안에서는 한쪽 이름으로 통일한다.
@B 같은 문서 기준으로 버전 값에 `(1.2+)`처럼 +를 붙이면 최소 버전을 지정한다. 실습 환경 19.3에서는 시험하지 않은 표기라 적용할 RU의 문서를 확인한 뒤 쓴다.
@B DN 대조를 NO로 두면 서버 인증서 DN이 맞지 않아도 오류를 기록만 하고 접속은 진행된다. 최신 문서 기준으로 YES로 켜면 기본은 인증서 CN에 접속 호스트 이름이 들어 있는지 보는 부분 대조이고, tnsnames.ora 접속 설명의 SECURITY 절에 SSL_SERVER_CERT_DN으로 DN 전체를 적으면 전체 대조를 한다.

@H3 11.5.3  Easy Connect와 다른 클라이언트

@B 19c의 Easy Connect는 프로토콜을 붙여 쓸 수 있다. `tcps://oel7v9:2484/orcl` 형식이면 tnsnames.ora 없이 TCPS로 접속한다.
@B 19c Easy Connect는 `?wallet_location=디렉터리` 같은 연결 속성도 받는다. 클라이언트마다 다른 지갑을 쓸 때 sqlnet.ora를 나누지 않아도 된다.
@B JDBC Thin 드라이버는 sqlnet.ora 대신 연결 속성으로 지갑을 지정한다. Oracle 지갑을 쓰려면 oraclepki 계열 라이브러리가, 자바 키스토어를 쓰려면 `javax.net.ssl.trustStore` 같은 표준 속성이 필요하다.
@B 애플리케이션 서버가 TLS로 바뀌면 연결 문자열의 포트와 프로토콜만 바뀌는 것이 아니다. 신뢰 인증서 배포가 함께 필요하므로 애플리케이션 담당자와 일정을 맞춘다.

@H3 11.5.4  단방향 TLS 구성

@B 클라이언트 인증서 없이 암호화와 서버 인증만 원하면 단방향 TLS로 구성한다. 서버·클라이언트 sqlnet.ora 모두 `SSL_CLIENT_AUTHENTICATION = FALSE`로 둔다.
@B 이때 클라이언트 지갑에는 서버를 검증할 CA 인증서만 있으면 된다. 사용자 인증서와 개인 키는 필요 없다.
@B 사용자는 평소처럼 비밀번호로 로그인하고, 통신 구간은 TCPS로 암호화된다. 대부분의 애플리케이션 서버 구성이 이 형태다.
@B 실습의 클라이언트는 `SSL_CLIENT_AUTHENTICATION = TRUE`였다. 그래서 인증서가 하나도 없는 빈 지갑으로는 비밀번호 사용자 접속도 ORA-28845로 실패했다.

@H3 11.5.5  클라이언트 지갑 배포

@B 단방향 TLS의 클라이언트 지갑에는 CA 인증서만 들어 있어 비밀이 없다. 여러 클라이언트에 같은 지갑을 배포해도 된다.
@B 상호 TLS의 클라이언트 지갑에는 개인 키가 들어 있다. 클라이언트마다 따로 만들고, 개인 키가 다른 곳으로 옮겨지지 않게 local auto-login을 검토한다.
@B 애플리케이션 서버처럼 접속 주체가 하나인 경우, 그 서버 전용 인증서와 DB 사용자를 하나씩 둔다. 여러 서버가 같은 인증서를 쓰면 감사 기록으로 서버를 구분할 수 없다.

@H3 11.5.6  SEPS와 TLS를 한 지갑에

@CODE
[oracle@oel7v9 ~]$ orapki wallet create -wallet /home/oracle/app_wallet -auto_login
[oracle@oel7v9 ~]$ orapki wallet add -wallet /home/oracle/app_wallet -trusted_cert -cert server_ca.cert
[oracle@oel7v9 ~]$ mkstore -wrl /home/oracle/app_wallet -createCredential orcl_tls app_user

WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = /home/oracle/app_wallet)))
SQLNET.WALLET_OVERRIDE = TRUE
SSL_CLIENT_AUTHENTICATION = FALSE
@END

@B 단방향 TLS와 SEPS를 함께 쓰는 애플리케이션 서버 구성의 예다. 지갑의 PKI 영역에는 서버를 검증할 CA 인증서가, secret store 영역에는 접속 계정의 자격 증명이 들어간다.
@B `/@orcl_tls`로 접속하면 비밀번호는 지갑에서 꺼내고 통신은 TCPS로 암호화된다. 로그인 방식은 PASSWORD, 프로토콜은 tcps가 된다.
@B 이 지갑에는 개인 키가 없지만 계정 비밀번호가 들어 있으므로 1장의 지갑 보호 원칙을 그대로 적용한다.

@H2 11.6  접속 확인과 문제 해결

@H3 11.6.1  TLS 접속인지 확인하기

@CODE
SQL> SELECT SYS_CONTEXT('USERENV', 'NETWORK_PROTOCOL')      AS proto,
  2         SYS_CONTEXT('USERENV', 'AUTHENTICATION_METHOD') AS auth,
  3         SYS_CONTEXT('USERENV', 'AUTHENTICATED_IDENTITY') AS identity
  4    FROM dual;
@END

@B NETWORK_PROTOCOL이 tcps면 TLS 접속이다. tcp면 평문 접속이다.
@B AUTHENTICATION_METHOD는 인증서 로그인이면 SSL, 비밀번호 로그인이면 PASSWORD로 나온다.
@B AUTHENTICATED_IDENTITY는 인증서 로그인일 때 인증서 DN을 보여 준다. 누가 어떤 인증서로 들어왔는지 감사 기록과 함께 확인할 수 있다.
@B 확인 조회는 애플리케이션 시작 시 한 번 실행해 로그로 남겨 두면 좋다. 설정이 바뀌어 평문 접속으로 떨어졌을 때 로그에서 바로 드러난다.
@B 실습에서는 출력 폭을 줄이려고 SYS_CONTEXT 결과를 SUBSTR로 잘라 조회했다. 값 자체는 짧아 잘리는 내용은 없다.
@B 서버에서 다른 세션을 볼 때는 V$SESSION_CONNECT_INFO를 본다. 인증서로 로그인한 세션은 AUTHENTICATION_TYPE이 GLOBAL로 나왔다(실습 04).
@B 같은 뷰의 NETWORK_SERVICE_BANNER에는 인증·암호화·체크섬 서비스 이름만 보이고 TLS나 TCPS라는 글자는 나오지 않는다. 배너 문구로 TLS 여부를 판단하지 않는다.

@H3 11.6.2  자주 만나는 오류

@TBL
오류 | 흔한 원인
ORA-28759 | 지갑 파일을 열지 못함. WALLET_LOCATION 누락·경로 오류, 파일 권한, auto-login 파일 누락(실습 04)
ORA-29024 | 인증서 검증 실패. 상대방 CA 인증서가 신뢰 인증서에 없음, 지갑에 인증서가 섞임
ORA-28860 | TLS 핸드셰이크 중 치명적 오류. 버전·스위트 불일치, 리스너가 옛 지갑을 물고 있음
ORA-12560 / TNS-12560 | 프로토콜 어댑터 오류. TCPS 리스너가 없거나 주소 불일치
ORA-01017 | 인증서는 통과했지만 DN과 일치하는 DB 사용자가 없음(실습 05)
ORA-28845 | 지갑에 인증서가 없음. 클라이언트 인증을 요구하는데 빈 지갑(실습 05)
ORA-28865 | TLS 연결 실패. 리스너 쪽 지갑·설정 문제
ORA-28786 | 개인 키 복호화 실패. auto-login이 아닌 지갑을 비밀번호 없이 열려 함(문서 기준)
ORA-28859 | 협상 실패. 양쪽이 함께 지원하는 TLS 버전·암호 스위트가 없음(문서 기준)
ORA-28862 | 상대가 연결을 닫음. 지갑 위치, 손으로 고친 SSL_CIPHER_SUITES의 철자 오류(대소문자 구분)(문서 기준)
ORA-28868 | 상대 인증서 체인 검증 실패. 체인 중 만료된 인증서, 신뢰 인증서에 없는 CA(문서 기준)
@END

@B 표의 뒤 네 줄은 Security Guide의 TLS 문제 해결 절에 실린 오류로, 실습에서는 재현하지 않았다. 문서는 이 오류들 대부분에 Oracle Net 트레이스를 켜고 다시 시도하라는 조치를 공통으로 적는다.
@B 문서는 ORA-28862의 원인으로 손으로 고친 sqlnet.ora의 스위트 이름 철자 오류를 꼽는다. 스위트를 제한할 때는 이름을 문서에서 그대로 옮겨 적고, 바꾼 뒤 서버와 클라이언트 양쪽에서 실제 로그인으로 확인한다.

@B 같은 접속 명령이라도 원인에 따라 오류 단계가 다르다. 실습 04·05에서 지갑 위치 누락, 빈 지갑, DN 불일치를 차례로 만들어 보면 오류 코드만으로 어느 단계에서 끊겼는지 구분할 수 있다.
@B TLS 오류는 대개 지갑과 인증서 문제다. 오류가 나면 양쪽 지갑을 `orapki wallet display`로 열어 신뢰 인증서와 사용자 인증서를 대조한다.
@B 오류가 리스너 단계인지 서버 프로세스 단계인지는 리스너 로그와 sqlnet 트레이스로 구분한다. 리스너 로그에 연결 기록이 없으면 리스너 단계에서 끊긴 것이다.
@B `tnsping`은 TCPS 주소에도 쓸 수 있지만 TLS 핸드셰이크까지는 확인하지 않는 경우가 있다. 최종 확인은 실제 로그인으로 한다.

@H3 11.6.3  트레이스로 원인 좁히기

@B 클라이언트 sqlnet.ora에 `TRACE_LEVEL_CLIENT = 16`을 넣으면 핸드셰이크 단계별 기록이 트레이스 파일에 남는다. 어느 단계에서 끊겼는지 볼 수 있다.
@B 서버 쪽은 리스너 로그(ADR의 `diag/tnslsnr/호스트/리스너이름/trace`)에서 연결 요청이 도착했는지 먼저 본다. 도착 기록이 없으면 네트워크나 리스너 주소 문제다.
@B 리스너 로그에 연결이 있고 오류가 클라이언트에만 보이면 서버 프로세스 단계(지갑, 인증)의 문제일 가능성이 크다.
@B 트레이스는 파일이 빠르게 커지므로 원인을 찾으면 바로 끈다. 트레이스 파일에 인증서 DN 등 민감한 정보가 남을 수 있어 보관 위치도 신경 쓴다.

@H3 11.6.4  실습에서 본 출력 읽기

@CODE
USR          PROTO  AUTH
------------ ------ ----------
TLS_CLIENT   tcps   SSL

SCOTT        tcps   PASSWORD     <- TCPS 별칭(2484)
SCOTT        tcp    PASSWORD     <- Easy Connect(1521)
@END

@B 인증서 로그인은 tcps와 SSL의 조합으로 나온다. 비밀번호 사용자도 TCPS 별칭으로 들어오면 tcps다. 암호화 여부와 인증 방식은 별개다.
@B AUTHENTICATED_IDENTITY는 인증서에 적힌 DN을 그대로, ENTERPRISE_IDENTITY는 DB에 저장된 형식(속성 이름 소문자)으로 보여 줬다.
@B 서버 쪽 V$SESSION_CONNECT_INFO에서 인증서 세션의 AUTHENTICATION_TYPE은 GLOBAL이었다.

@H3 11.6.5  감사 기록으로 평문 접속 찾기

@B Unified Audit Trail의 AUTHENTICATION_TYPE 열에는 `(TYPE=(DATABASE));(CLIENT ADDRESS=((ADDRESS=(PROTOCOL=tcp)(HOST=...` 같은 문자열이 남는다. 1장 실습에서 실패 로그인 기록을 조회할 때 이 형식을 확인했다.
@B 이 문자열의 PROTOCOL 값을 보면 로그인이 tcp였는지 tcps였는지 알 수 있다. TCPS 전환을 끝낸 뒤 tcp로 들어오는 로그인이 남아 있는지 찾는 데 쓴다.
@B 로그인 감사 정책이 있어야 성공 로그인도 기록된다. 기본 정책 ORA_LOGON_FAILURES는 실패만 기록하므로, 전환 기간에는 성공 로그인을 기록하는 정책을 따로 둔다(13장).

@H3 11.6.6  계층별 진단 순서

@TBL
계층 | 확인 방법 | 이 단계 실패의 예
네트워크 | ping, 포트 열림 확인 | 방화벽에서 2484 차단
리스너 | lsnrctl status (TCPS 주소, 서비스) | TCPS 리스너 미기동, 서비스 미등록
핸드셰이크 | 클라이언트 트레이스, 리스너 로그 | ORA-28759, ORA-28845, ORA-29024, ORA-28860
DB 인증 | DBA_USERS의 EXTERNAL_NAME, 감사 기록 | ORA-01017(DN 불일치)
@END

@B 아래 계층부터 차례로 확인한다. 상위 계층의 오류 메시지가 하위 계층 원인을 가리고 있는 경우가 많다.
@B 실습 05에서 DN 불일치는 핸드셰이크를 통과한 뒤 DB 인증에서 실패했다. TLS 관련 코드(ORA-28xxx)가 아니라 ORA-01017이 나오면 인증서 자체보다 DB 사용자 쪽을 먼저 본다.

@H3 11.6.7  tnsping과 TCPS

@B tnsping은 별칭이 어떤 주소로 풀리는지와 리스너가 응답하는지만 확인한다. 원본 자료도 tnsping OK를 첫 시험으로 쓴다.
@B tnsping이 OK여도 지갑이 없거나 인증서가 맞지 않으면 실제 접속은 실패한다. 1장의 SEPS와 마찬가지로 최종 확인은 로그인과 SYS_CONTEXT 조회로 한다.

@CASE 인증서를 교체했더니 일부 클라이언트만 접속이 끊겼다
서버 인증서 만료가 다가와 새 사내 CA에서 서명한 인증서로 서버 지갑을 교체했다. 다음 날 아침 대부분의 클라이언트는 정상이었지만 보고서 서버 두 대만 ORA-29024로 접속에 실패했다.
두 서버의 클라이언트 지갑에는 옛 CA 인증서만 신뢰 인증서로 들어 있었다. 새 서버 인증서를 검증할 CA가 없어 인증서 검증 단계에서 실패했다.
두 지갑에 새 CA 인증서를 `-trusted_cert`로 추가하자 접속이 복구됐다. 이후 인증서 교체 절차에 "모든 클라이언트 지갑에 새 CA 인증서 선배포"를 넣었다.
@END

@CASE 새해 첫 출근날 모든 TLS 접속이 끊겼다
TLS를 도입하며 자체 서명 인증서를 유효 기간 365일로 만들었다. 정확히 1년 뒤 아침, TCPS로 접속하는 모든 클라이언트가 인증서 검증 오류로 실패했다. TCP로 접속하던 일부 레거시 시스템만 정상이었다.
서버 인증서와 CA로 쓰던 자체 서명 인증서가 함께 만료돼 있었다. 클라이언트들은 만료된 CA로 서명된 서버 인증서를 신뢰할 수 없었다.
새 CA와 서버 인증서를 만들고 모든 클라이언트 지갑에 새 CA를 배포해야 해서 복구에 반나절이 걸렸다. 이후 인증서 만료 90일·30일 전 경보를 모니터링에 넣고, 교체를 만료 한 달 전에 끝내는 절차를 만들었다.
@END

@H2 11.7  설계와 적용 절차

@TBL
단계 | 작업 | 확인할 것
1 | CA 결정(사내 CA, 공인 CA, 자체 서명) | 인증서 유효 기간과 교체 주기
2 | 서버 지갑 생성(auto-login)과 서버 인증서 | orapki wallet display
3 | 클라이언트 지갑 생성과 CA 인증서 등록 | 신뢰 인증서 목록
4 | 상호 TLS면 클라이언트 인증서 요청·서명·가져오기 | 사용자 인증서 DN
5 | TCPS 리스너와 리스너 지갑 구성 | lsnrctl status의 TCPS 주소
6 | 서버 sqlnet.ora(WALLET_LOCATION, AUTHENTICATION_SERVICES, CLIENT_AUTHENTICATION) | 기존 TCP 접속 영향
7 | 인증서 사용자 생성(IDENTIFIED EXTERNALLY AS DN) | DN 문자열 일치
8 | 클라이언트 sqlnet.ora·tnsnames.ora | TCPS 별칭
9 | 접속 시험 | NETWORK_PROTOCOL = tcps, AUTHENTICATION_METHOD
@END

@B 기존 TCP 접속을 바로 막지 말고, TCPS를 추가한 뒤 클라이언트를 하나씩 옮긴다. 모두 옮긴 뒤 TCP 주소를 닫거나 방화벽에서 막는다.
@B 인증서 만료일을 감시한다. 만료된 서버 인증서는 모든 TLS 접속을 한꺼번에 끊는다.
@B 적용 결과는 문서로 남긴다. 서버 지갑 위치, 리스너 이름과 포트, 인증서 DN과 만료일, 인증서 사용자 목록이 다음 담당자에게 필요한 최소 정보다.
@B 시험은 비밀번호 사용자와 인증서 사용자 모두로 한다. 한쪽만 확인하면 SSL_CLIENT_AUTHENTICATION 설정 실수를 놓친다.

@BP TLS 전환 점검
서버: TCPS 리스너 주소와 서비스 등록, 리스너·서버 sqlnet.ora의 지갑 위치, 인증 서비스에 BEQ 유지, 방화벽 2484.
클라이언트: CA 인증서가 든 지갑, TCPS 별칭, 상호 TLS라면 사용자 인증서와 SSL_CLIENT_AUTHENTICATION.
확인: 비밀번호 사용자와 인증서 사용자 각각 NETWORK_PROTOCOL = tcps, 로컬 / as sysdba 접속, 재부팅 후 TCPS 리스너 자동 기동.
마무리: 감사 기록으로 tcp 로그인이 남지 않는 것을 확인한 뒤 TCP 경로를 닫는다.
@END

@H2 11.8  다른 보안 기능과의 조합

@B SEPS(1장)와 TLS를 함께 쓰면 비밀번호는 지갑에 숨기고 통신은 암호화한다. 별칭의 PROTOCOL을 TCPS로 바꾸고 지갑에 CA 인증서와 SEPS 자격 증명을 함께 넣는다.
@B TDE(10장)는 디스크의 데이터를, TLS는 네트워크의 데이터를 보호한다. 둘은 겹치지 않으므로 저장과 전송 모두를 보호하려면 둘 다 필요하다.
@B 프록시 인증(2장)에서 중간 계층 서버와 DB 사이를 TLS로 묶으면, 프록시 계정 자체를 인증서로 인증할 수 있다.
@B Data Guard(Redo 전송)나 DB 링크도 Oracle Net을 쓰므로 TCPS로 구성할 수 있다. 서버끼리의 구간도 암호화 대상에 넣을지 검토한다.
@B 감사 기록(13장)의 UNIFIED_AUDIT_TRAIL에는 AUTHENTICATION_TYPE 열이 있어 로그인이 비밀번호였는지 인증서였는지, 어떤 프로토콜이었는지 남는다. 평문 TCP로 들어오는 접속을 찾아낼 때 쓴다.
@B VPD(7장)나 LOGON 트리거에서 `SYS_CONTEXT('USERENV', 'NETWORK_PROTOCOL')`을 검사하면 민감 데이터를 TCPS 접속에서만 보이게 할 수도 있다.

@B 네이티브 네트워크 암호화와 TLS를 한 접속에 함께 쓰지 않는다. TCPS 접속이면 TLS가 이미 암호화를 맡으므로 네이티브 암호화 설정은 의미가 없다.
@B 문제는 서버에 `SQLNET.ENCRYPTION_SERVER = REQUIRED`가 이미 걸린 상태에서 TCPS 클라이언트를 받을 때 생긴다. 이전 릴리스는 네이티브 암호화와 TLS 인증을 함께 쓰는 구성을 막았고, 최신 19c RU 문서는 이런 충돌에서 네이티브 암호화 설정을 무시하게 하는 `SQLNET.IGNORE_ANO_ENCRYPTION_FOR_TCPS = TRUE`를 소개한다. 19.3 실습 환경에서는 확인하지 않은 파라미터다.

@NOTE 원본 자료와 다른 점
원본 자료는 기존 리스너에 1522번 TCPS 주소를 추가하고, 서버 sqlnet.ora를 공용 위치에서 고치며, REMOTE_OS_AUTHENT와 OS_AUTHENT_PREFIX를 바꾼 뒤 재기동한다.
이 교안의 실습은 같은 VM에서 다른 실습과 함께 쓰는 DB를 건드리지 않도록 별도 TNS_ADMIN의 TCPS 리스너(2484)를 띄우고, 인증서 사용자 로그인에 필요하지 않은 파라미터 변경은 하지 않는다. 키 길이도 2048비트로 바꿨다.
@END

@CASE 시험 서버에 운영 지갑을 복사했다
성능 시험을 위해 운영 서버의 TCPS 설정을 시험 서버로 옮기면서 서버 지갑 디렉터리를 그대로 복사했다. 시험은 잘 끝났고 아무도 지갑을 지우지 않았다.
몇 달 뒤 보안 점검에서 시험 서버에 운영 서버 인증서와 개인 키가 있다는 사실이 드러났다. auto-login 지갑이라 시험 서버 관리자 누구나 운영 서버로 행세할 수 있는 상태였다.
운영 인증서를 폐기하고 새로 발급해 교체했다. 시험 서버에는 시험용 CA로 만든 별도 인증서를 쓰도록 절차를 바꿨다.
@END

@CASE TLS 설정 뒤 로컬 SYSDBA 접속이 막혔다
서버 sqlnet.ora에 인증서 로그인을 위해 `SQLNET.AUTHENTICATION_SERVICES = (TCPS)`만 적고 저장했다. 이후 서버에서 `sqlplus / as sysdba`를 실행하자 운영체제 인증이 거부됐다.
AUTHENTICATION_SERVICES 목록에서 BEQ가 빠져 로컬 OS 인증이 허용되지 않았기 때문이다. 원본 자료와 매뉴얼 예제가 (BEQ, TCPS)를 함께 적는 이유다.
값을 (BEQ, TCPS)로 고치자 로컬 SYSDBA 접속이 돌아왔다. 이후 서버 sqlnet.ora 변경은 반드시 로컬 SYSDBA 접속 시험을 포함하도록 했다.
@END

@H2 11.9  운영 시 주의점

@B TLS 지갑은 auto-login이므로 지갑 파일을 가진 사람은 그 인증서로 행세할 수 있다. 서버·클라이언트 지갑 모두 OS 권한을 소유자 전용으로 둔다.
@B 인증서 유효 기간은 실습의 365일보다 짧게 잡는 추세다. 교체 절차를 문서로 만들고 연습해 둔다.
@B 서버 sqlnet.ora의 SQLNET.AUTHENTICATION_SERVICES를 바꾸면 OS 인증(`/ as sysdba`)에 영향을 줄 수 있다. BEQ를 빼지 않는다.
@B TLS 핸드셰이크는 접속마다 일어난다. 연결 풀 없이 짧은 접속을 반복하는 애플리케이션은 CPU 사용이 늘어난다.
@B 실습처럼 같은 서버에 서버·클라이언트 지갑을 두는 구성은 학습용이다. 운영에서는 클라이언트 개인 키가 서버에 있으면 안 된다.
@B TCPS 포트를 열었다면 TCP 포트를 언제 닫을지 계획을 세운다. 두 포트가 함께 열려 있으면 클라이언트 설정 실수 하나로 평문 접속이 생긴다.
@B 인증서 사용자는 비밀번호 만료 정책의 대상이 아니다. 대신 인증서 유효 기간이 계정 수명 역할을 하므로, 퇴직자 계정은 인증서 만료를 기다리지 말고 DB 계정을 잠근다.
@B 자체 서명 CA는 개발·시험 환경에만 쓴다. 운영 인증서는 사내 CA의 정책(발급 승인, 폐기 목록)에 따라 관리한다.
@B 리스너를 별도 TNS_ADMIN으로 띄웠다면 서버 재부팅 후 자동 기동 스크립트에도 같은 TNS_ADMIN을 넣는다. 빠뜨리면 재부팅 뒤 TCPS 리스너만 올라오지 않는다.
@B 인증서 로그인 사용자의 권한은 비밀번호 사용자보다 엄격하게 관리한다. 인증서 파일 하나가 비밀번호 없이 그 권한을 행사한다.
@B 최신 19c 문서는 암호 모듈을 기존(legacy) 공급자와 차세대(next-generation) 공급자로 나눈다. 기본은 기존 공급자로 TLS 1.0~1.2를 지원하고, 19.32 이후 RU에서 고를 수 있는 차세대 공급자는 TLS 1.2·1.3만 받는다.
@B 차세대 공급자로 바꾸면 MD5·SHA-1로 서명된 인증서를 쓸 수 없고 TLS 1.0·1.1 접속도 끊긴다. 오래된 클라이언트와 옛 인증서가 남은 환경은 RU를 올리기 전에 인증서 서명 알고리즘과 클라이언트 버전부터 조사한다.

@H2 11.10  요약

@B TLS는 Oracle Net 구간을 암호화하고 무결성을 보장하며, 인증서로 서버(와 클라이언트)를 인증한다. 19c에서는 별도 옵션 없이 쓸 수 있다.
@B 지갑에는 자신의 개인 키·인증서와, 상대 인증서를 검증할 CA 인증서(신뢰 인증서)가 들어간다. TLS 지갑은 auto-login이어야 한다.
@B orapki로 지갑 생성, 자체 서명 인증서, 인증서 요청·서명·가져오기를 한다. CA 인증서를 사용자 인증서보다 먼저 넣는다.
@B 서버는 TCPS 리스너(관례 2484)와 sqlnet.ora(WALLET_LOCATION, AUTHENTICATION_SERVICES에 TCPS, SSL_CLIENT_AUTHENTICATION)를, 클라이언트는 지갑과 TCPS 별칭을 구성한다.
@B `IDENTIFIED EXTERNALLY AS 'DN'`으로 만든 사용자는 인증서로 비밀번호 없이 로그인한다. DN은 ALTER USER로 고칠 수 있다.
@B 19.3 orapki는 기존 지갑 위의 create, 같은 인증서 중복 추가, 512비트 키를 막지 않는다. 결과는 orapki wallet display로 확인한다.
@B NETWORK_PROTOCOL(tcps), AUTHENTICATION_METHOD(SSL), AUTHENTICATED_IDENTITY(DN)로 TLS 접속을 확인한다.
@B 512·1024비트 키는 쓰지 않는다. 19.3 orapki는 512비트도 거부하지 않으므로 운영 기준으로 막는다. 최신 19c 문서의 TLS_ 파라미터 이름은 SSL_ 이름을 대체한다.
@B 지갑 위치 누락은 ORA-28759, 빈 지갑은 ORA-28845, DN 불일치는 ORA-01017, 인증서가 섞인 지갑은 ORA-29024로 나타났다.

@H2 11.11  퀴즈

@QUIZ 문제 1
TLS가 네이티브 네트워크 암호화와 달리 제공하는 기능은?
① 데이터 암호화  ② 무결성 검사  ③ 인증서를 이용한 서버 신원 확인  ④ sqlnet.ora만으로 구성 가능
정답 ③. 두 방식 모두 암호화와 무결성 검사를 제공하지만 상대방 인증은 TLS만 한다. 네이티브 암호화가 sqlnet.ora 파라미터만으로 구성되는 쪽이다.
@END

@QUIZ 문제 2
클라이언트 sqlnet.ora에 WALLET_LOCATION 없이 TCPS 별칭으로 인증서 로그인을 시도했다. 실습에서 나온 결과는?
① ORA-28759: failure to open file  ② 평문 TCP로 바뀌어 접속된다  ③ 비밀번호를 묻는다  ④ ORA-01017
정답 ①. TCPS 접속에는 클라이언트 지갑이 필요하다. 지갑 위치가 없으면 지갑을 열지 못해 ORA-28759로 실패한다. ORA-01017은 핸드셰이크는 통과했지만 DN에 맞는 DB 사용자가 없을 때 나왔다.
@END

@QUIZ 문제 3
인증서 DN 'CN=tls_client,O=itwill,C=KR'로 비밀번호 없이 로그인할 사용자를 만드는 문장은?
① CREATE USER tls_client IDENTIFIED BY 'CN=tls_client,O=itwill,C=KR'  ② CREATE USER tls_client IDENTIFIED EXTERNALLY  ③ CREATE USER tls_client IDENTIFIED GLOBALLY  ④ CREATE USER tls_client IDENTIFIED EXTERNALLY AS 'CN=tls_client,O=itwill,C=KR'
정답 ④. IDENTIFIED EXTERNALLY AS 'DN'은 지정한 DN의 인증서로 들어온 접속을 이 사용자로 인증한다. AS 없는 EXTERNALLY는 OS 인증, GLOBALLY는 디렉터리 서비스 기반 전역 사용자다.
@END

@QUIZ 문제 4
접속한 세션이 TLS로 연결되어 있는지 확인하는 가장 직접적인 방법은?
① SYS_CONTEXT('USERENV', 'NETWORK_PROTOCOL')이 tcps인지 본다  ② SHOW USER  ③ V$ENCRYPTION_WALLET 조회  ④ tnsping 결과가 OK인지 본다
정답 ①. NETWORK_PROTOCOL이 tcps면 TLS 접속이다. V$ENCRYPTION_WALLET은 TDE 키스토어 상태를 보여 주며, tnsping은 주소 도달 여부만 확인한다.
@END

@QUIZ 문제 5
같은 클라이언트 지갑에 SEPS 자격 증명과 TLS 사용자 인증서가 모두 있고 sqlnet.ora에 SQLNET.WALLET_OVERRIDE = TRUE가 있다. /@ORCL_TLS로 접속하면?
① 인증서로 로그인한다  ② 지갑의 사용자 이름·비밀번호로 로그인한다  ③ ORA-28759가 난다  ④ 두 방식을 모두 검사한다
정답 ②. WALLET_OVERRIDE가 TRUE면 지갑의 비밀번호 자격 증명이 인증서보다 우선한다. 인증서 로그인을 원하면 WALLET_OVERRIDE를 두지 않는다. 접속 자체는 여전히 TCPS로 암호화된다.
@END

@QUIZ 문제 6
TLS 구성에 대한 설명으로 틀린 것은?
① 리스너도 TLS 핸드셰이크에 참여하므로 지갑 위치가 필요하다  ② TLS 지갑은 서버 프로세스가 비밀번호 없이 열 수 있어야 한다  ③ 원본 자료의 512비트 키도 운영에 써도 안전하다  ④ 서버 sqlnet.ora에서 BEQ를 빼면 로컬 OS 인증 접속에 영향이 있다
정답 ③. 512·1024비트 RSA 키는 안전하지 않은 것으로 보며 2048비트 이상을 써야 한다. 나머지는 모두 옳은 설명이다.
@END

@H2 11.12  실습 개요

@P 실습은 oel7v9 서버 한 대에서 서버 지갑·클라이언트 지갑 디렉터리와 TNS_ADMIN을 나눠 두 머신처럼 구성한다. 기존 리스너와 `$ORACLE_HOME/network/admin` 파일은 건드리지 않고 별도 TCPS 리스너(2484)를 띄운 뒤, 마지막에 리스너·지갑·사용자를 모두 철거한다.

@TBL
실습 파일 | 확인하는 개념 | 관련 절
11장_실습_01_서버지갑과자체서명CA | auto-login 서버 지갑, 512비트 키, 같은 디렉터리 재생성 함정, PKI-02003, CA 인증서 내보내기 | 11.3.3~11.3.7
11장_실습_02_클라이언트인증서요청과서명 | 인증서 요청·서명·가져오기, 가져오기 순서와 PKI-04004 | 11.3.3, 11.3.5
11장_실습_03_TCPS리스너와서버구성 | 별도 TNS_ADMIN의 TCPS 리스너, 정적 등록 ENVS, TNS-01106, 인증서 사용자 | 11.4
11장_실습_04_클라이언트접속과확인 | ORA-28759, 인증서 로그인, TCPS와 TCP 비교, V$SESSION_CONNECT_INFO, DN 확인 | 11.5, 11.6.1, 11.6.4
11장_실습_05_DN불일치와철거 | DN 불일치 ORA-01017과 ALTER USER, 빈 지갑 ORA-28845, 철거와 md5 대조 | 11.4.4, 11.6.2
@END
