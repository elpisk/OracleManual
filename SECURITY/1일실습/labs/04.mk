@H2 실습 04  네트워크 ACL로 외부 호출 통제
@TBL
항목 | 내용
목표 | UTL_HTTP·UTL_INADDR 호출을 호스트 ACE로 허용·거부하고, 역할 기반 ACE와 정의자 권한 코드의 관계, 호스트 우선순위를 실측으로 확인한다
소요 | 30분
접속 | root(시험용 HTTP 서버), SYS, D04_APP
변경 | 사용자 D04_APP, 역할 D04_WEB_ROLE, D04_% 대상 ACE 4개, 포트 8094 HTTP 서버. 마지막 단계에서 모두 지움
@END

@H3 04.1  실습 전에 — 패키지 실행 권한과 네트워크 접근 권한은 따로 판정된다
@B UTL_HTTP·UTL_TCP·UTL_SMTP·UTL_INADDR의 EXECUTE는 기본적으로 PUBLIC에 있다. 실제 네트워크 접근은 호스트 ACL이 허용해야 한다. 허용이 없으면 ORA-24247이 나고, UTL_HTTP는 이를 ORA-29273으로 감싼다.
@B 12c부터는 `DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE`와 `REMOVE_HOST_ACE`로 ACE를 직접 다룬다. 조회는 `DBA_HOST_ACLS`, `DBA_HOST_ACES`로 한다. 11g의 CREATE_ACL·ADD_PRIVILEGE·ASSIGN_ACL은 디프리케이트됐다.
@B 권한 종류는 connect, resolve, http, http_proxy, smtp, jdwp다. http는 UTL_HTTP 요청만 허용하고, 이름 풀이(UTL_INADDR)는 resolve가 따로 필요하다.
@B 호스트 지정은 정확한 이름·IP, 와일드카드(`172.16.225.*`, `*.example.com`), 전체(`*`)로 한다.
@B 판정은 가장 구체적인 호스트부터 본다. IP 172.16.225.50은 172.16.225.50 → 172.16.225.* → 172.16.* → 172.* → * 순이다(`DBMS_NETWORK_ACL_UTILITY.DOMAINS`, 실습 [8]).
@B 구체적인 호스트의 ACE에서 판정이 나면 넓은 호스트의 ACE는 보지 않는다. 그래서 `*`에 resolve GRANT가 있어도 `oel7v9`의 DENY가 이긴다(실습 [7]).
@B 포트 범위가 있는 ACE가 포트 범위 없는 ACE보다 우선한다. 범위 밖 포트는 허용되지 않는다.
@B ACE의 대상(principal)은 사용자나 역할이다. 정의자 권한 PL/SQL 안에서는 역할이 꺼지므로, 역할로 받은 ACE도 효과가 없다(실습 [5] 실측).
@B 운영 패키지가 외부를 호출하면 ACE를 패키지 소유 스키마에 직접 준다. 역할 ACE는 대화형·호출자 권한 코드용이다.
@B `REMOVE_HOST_ACE`는 호스트·포트·권한·대상·GRANT/DENY가 모두 같아야 지운다. 정리는 `DBA_HOST_ACES`를 읽어 같은 값으로 돌리는 방식이 안전하다.
@B ACE를 처음 추가하면 해당 호스트·포트 조합의 ACL이 시스템 이름으로 자동 생성된다. 같은 조합에 다시 추가하면 그 ACL에 ACE가 덧붙고 ACE_ORDER가 1, 2로 늘어난다(실습 [4]·[6]).
@B UTL_HTTP 오류는 ORA-29273 아래에 실제 원인이 깔린다. 스택에 ORA-24247이 있으면 ACL 판정이고, 없으면 연결이나 대상 서버 쪽 원인이다.
@B 현재 사용자 기준의 점검은 `USER_HOST_ACES`로 한다. 자기에게 적용되는 ACE와 판정 상태를 보여 준다(문서 기준).
@B 웹 프록시를 거치는 호출에는 대상 호스트 ACE 외에 프록시 호스트에 대한 http_proxy 권한이 필요하다(문서 기준).
@NOTE HTTPS 호출
HTTPS는 ACE 외에 신뢰할 인증서를 담은 지갑이 필요하다(`UTL_HTTP.SET_WALLET`). 이 실습은 평문 HTTP만 다룬다.
@END

@H3 04.2  진행 순서
@TBL
단계 | 주제 | 하는 일 | 확인할 것
[1] | 시험 서버 | root로 8094 포트 HTTP 서버 기동 | curl 응답
[2] | 준비 | D04_APP, D04_WEB_ROLE | CREATE PROCEDURE 포함
[3] | ACE 없이 | UTL_HTTP.REQUEST | ORA-29273 / ORA-24247
[4] | 역할 ACE | 역할에 http, 8094 | DBA_HOST_ACES
[5] | 실행 문맥 비교 | 익명 SQL과 정의자 권한 함수 | SQL은 성공, 함수는 ORA-24247
[6] | 사용자 ACE | 사용자에게 직접 http | 함수 성공, 8095는 거부
[7] | 우선순위 | '*' resolve GRANT + oel7v9 DENY | oel7v9 거부, localhost 허용
[8] | 판정 근거 | ACE 목록과 DOMAINS | ACE_ORDER, 도메인 순서
[9~10] | 원복 | ACE·사용자·역할·서버 정리 | D04 0건, 전체 ACE 3건
@END

@H3 04.3  실습 스크립트

@P [1] 시험용 HTTP 서버
@CODE
-- ★ root 로 파이썬 내장 웹 서버를 띄운다. 외부 API를 대신하는 시험 대상이다.
[root@oel7v9 ~]# pkill -f 'SimpleHTTPServer 8094'
[root@oel7v9 ~]# mkdir -p /tmp/d04_www
[root@oel7v9 ~]# echo '<html><body>D04 internal api</body></html>' > /tmp/d04_www/index.html
[root@oel7v9 ~]# cd /tmp/d04_www
[root@oel7v9 d04_www]# setsid nohup python -m SimpleHTTPServer 8094 > /tmp/d04_http.log 2>&1 < /dev/null &
[root@oel7v9 d04_www]# cd ~
[root@oel7v9 ~]# sleep 2
[root@oel7v9 ~]# curl -s http://172.16.225.50:8094/
<html><body>D04 internal api</body></html>
@END

@P [2] 계정과 역할 준비
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> CREATE USER d04_app IDENTIFIED BY App2026x;

User created.

SYS@orcl> GRANT CREATE SESSION, CREATE PROCEDURE TO d04_app;

Grant succeeded.

SYS@orcl> CREATE ROLE d04_web_role;

Role created.

SYS@orcl> GRANT d04_web_role TO d04_app;

Grant succeeded.
@END

@P [3] ACE 없이 호출
@CODE
SQL> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8094/'), 1, 40) AS page FROM dual;
SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8094/'), 1, 40) AS page FROM dual
              *
ERROR at line 1:
ORA-29273: HTTP request failed
ORA-06512: at "SYS.UTL_HTTP", line 1530
ORA-24247: network access denied by access control list (ACL)
ORA-06512: at "SYS.UTL_HTTP", line 380
ORA-06512: at "SYS.UTL_HTTP", line 1470
ORA-06512: at line 1
-- ★ 실행 권한은 PUBLIC에 있어 패키지 호출 자체는 된다. 네트워크 단계에서 ORA-24247로 막힌다.
@END

@P [4] 역할에 http ACE 주기
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
  3      host       => '172.16.225.50',
  4      lower_port => 8094,
  5      upper_port => 8094,
  6      ace        => xs$ace_type(privilege_list => xs$name_list('http'),
  7                                principal_name => 'D04_WEB_ROLE',
  8                                principal_type => xs_acl.ptype_db));
  9  END;
 10  /

PL/SQL procedure successfully completed.

SYS@orcl> COL host FOR a14
SYS@orcl> COL principal FOR a12
SYS@orcl> COL privilege FOR a8
SYS@orcl> SELECT host, lower_port lo, upper_port hi, ace_order ord, principal, privilege, grant_type
  2    FROM dba_host_aces WHERE principal LIKE 'D04%' ORDER BY host, lo, ord;

HOST                   LO         HI        ORD PRINCIPAL    PRIVILEG GRANT
-------------- ---------- ---------- ---------- ------------ -------- -----
172.16.225.50        8094       8094          1 D04_WEB_ROLE HTTP     GRANT

1 row selected.
-- ★ ACE_ORDER 는 같은 호스트·포트 ACL 안의 평가 순서다.
@END

@P [5] 익명 SQL과 정의자 권한 함수
@CODE
SQL> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> COL page FOR a42
D04_APP@orcl> COL ip FOR a16
D04_APP@orcl> SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8094/'), 1, 40) AS page FROM dual;

PAGE
------------------------------------------
<html><body>D04 internal api</body></htm

1 row selected.

D04_APP@orcl> CREATE OR REPLACE FUNCTION get_page RETURN VARCHAR2
  2  AUTHID DEFINER
  3  AS
  4  BEGIN
  5    RETURN SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8094/'), 1, 40);
  6  END;
  7  /

Function created.

D04_APP@orcl> SELECT get_page AS page FROM dual;
SELECT get_page AS page FROM dual
       *
ERROR at line 1:
ORA-29273: HTTP request failed
ORA-06512: at "SYS.UTL_HTTP", line 1530
ORA-24247: network access denied by access control list (ACL)
ORA-06512: at "SYS.UTL_HTTP", line 380
ORA-06512: at "SYS.UTL_HTTP", line 1470
ORA-06512: at "D04_APP.GET_PAGE", line 5
-- ★ SQL에서는 역할이 켜져 있어 호출이 성공한다.
-- ★ 같은 호출을 정의자 권한 함수에 넣으면 역할이 꺼져 ORA-24247이 난다. 오류 스택 마지막 줄이 D04_APP.GET_PAGE 다.
@END

@P [6] 사용자에게 직접 ACE
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
  3      host       => '172.16.225.50',
  4      lower_port => 8094,
  5      upper_port => 8094,
  6      ace        => xs$ace_type(privilege_list => xs$name_list('http'),
  7                                principal_name => 'D04_APP',
  8                                principal_type => xs_acl.ptype_db));
  9  END;
 10  /

PL/SQL procedure successfully completed.

SYS@orcl> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> COL page FOR a42
D04_APP@orcl> COL ip FOR a16
D04_APP@orcl> SELECT get_page AS page FROM dual;

PAGE
------------------------------------------
<html><body>D04 internal api</body></htm

1 row selected.

D04_APP@orcl> SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8095/'), 1, 40) AS page FROM dual;
SELECT SUBSTR(UTL_HTTP.REQUEST('http://172.16.225.50:8095/'), 1, 40) AS page FROM dual
              *
ERROR at line 1:
ORA-29273: HTTP request failed
ORA-06512: at "SYS.UTL_HTTP", line 1530
ORA-24247: network access denied by access control list (ACL)
ORA-06512: at "SYS.UTL_HTTP", line 380
ORA-06512: at "SYS.UTL_HTTP", line 1470
ORA-06512: at line 1
-- ★ 사용자에게 직접 준 ACE는 정의자 권한 함수에서도 유효하다.
-- ★ 포트 8095는 범위 밖이라 거부된다. 서버가 없는 포트인데도 연결 시도 전에 ACL 단계에서 막힌다.
@END

@P [7] resolve 권한과 호스트 우선순위
@CODE
-- ★ '*' 에 resolve 를 허용한 뒤, 정확한 호스트 oel7v9 에 같은 권한의 DENY 를 추가한다.
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
  3      host       => '*',
  4      ace        => xs$ace_type(privilege_list => xs$name_list('resolve'),
  5                                principal_name => 'D04_APP',
  6                                principal_type => xs_acl.ptype_db));
  7  END;
  8  /

PL/SQL procedure successfully completed.

SYS@orcl> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> COL page FOR a42
D04_APP@orcl> COL ip FOR a16
D04_APP@orcl> SELECT UTL_INADDR.GET_HOST_ADDRESS('oel7v9') AS ip FROM dual;

IP
----------------
172.16.225.50

1 row selected.

D04_APP@orcl> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
  3      host       => 'oel7v9',
  4      ace        => xs$ace_type(privilege_list => xs$name_list('resolve'),
  5                                principal_name => 'D04_APP',
  6                                principal_type => xs_acl.ptype_db,
  7                                granted        => FALSE));
  8  END;
  9  /

PL/SQL procedure successfully completed.

SYS@orcl> CONNECT d04_app/App2026x
Connected.
D04_APP@orcl> COL page FOR a42
D04_APP@orcl> COL ip FOR a16
D04_APP@orcl> SELECT UTL_INADDR.GET_HOST_ADDRESS('oel7v9') AS ip FROM dual;
SELECT UTL_INADDR.GET_HOST_ADDRESS('oel7v9') AS ip FROM dual
       *
ERROR at line 1:
ORA-24247: network access denied by access control list (ACL)
ORA-06512: at "SYS.UTL_INADDR", line 19
ORA-06512: at "SYS.UTL_INADDR", line 40
ORA-06512: at line 1


D04_APP@orcl> SELECT UTL_INADDR.GET_HOST_ADDRESS('localhost') AS ip FROM dual;

IP
----------------
127.0.0.1

1 row selected.
-- ★ oel7v9 는 구체적인 호스트의 DENY 로 판정이 끝난다. '*' 의 GRANT 까지 내려가지 않는다.
-- ★ localhost 는 구체적인 ACE가 없어 '*' 의 GRANT 를 따른다.
@END

@P [8] 판정 근거 조회
@CODE
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> COL host FOR a14
SYS@orcl> COL principal FOR a12
SYS@orcl> COL privilege FOR a8
SYS@orcl> SELECT host, lower_port lo, upper_port hi, ace_order ord, principal, privilege, grant_type
  2    FROM dba_host_aces WHERE principal LIKE 'D04%' ORDER BY host, lo, ord;

HOST                   LO         HI        ORD PRINCIPAL    PRIVILEG GRANT
-------------- ---------- ---------- ---------- ------------ -------- -----
*                                             3 D04_APP      RESOLVE  GRANT
172.16.225.50        8094       8094          1 D04_WEB_ROLE HTTP     GRANT
172.16.225.50        8094       8094          2 D04_APP      HTTP     GRANT
oel7v9                                        1 D04_APP      RESOLVE  DENY

4 rows selected.

SYS@orcl> COL domain FOR a16
SYS@orcl> SELECT COLUMN_VALUE AS domain FROM TABLE(DBMS_NETWORK_ACL_UTILITY.DOMAINS('172.16.225.50'));

DOMAIN
----------------
172.16.225.50
172.16.225.*
172.16.*
172.*
*

5 rows selected.
-- ★ DOMAINS 결과가 IP의 판정 순서다. 위에서부터 처음 판정이 나는 곳에서 멈춘다.
@END

@P [9] 원복
@CODE
-- ★ DBA_HOST_ACES 의 값을 그대로 REMOVE_HOST_ACE 에 넘겨 DENY 까지 지운다.
SQL> CONNECT / AS SYSDBA
Connected.
SYS@orcl> BEGIN
  2    FOR r IN (SELECT host, lower_port, upper_port, principal, privilege, grant_type
  3                FROM dba_host_aces WHERE principal LIKE 'D04%') LOOP
  4      DBMS_NETWORK_ACL_ADMIN.REMOVE_HOST_ACE(r.host, r.lower_port, r.upper_port,
  5        xs$ace_type(privilege_list => xs$name_list(r.privilege),
  6                    principal_name => r.principal,
  7                    principal_type => xs_acl.ptype_db,
  8                    granted        => (r.grant_type = 'GRANT')), TRUE);
  9    END LOOP;
 10  END;
 11  /

PL/SQL procedure successfully completed.

SYS@orcl> DROP USER d04_app CASCADE;

User dropped.

SYS@orcl> DROP ROLE d04_web_role;

Role dropped.

SYS@orcl> SELECT COUNT(*) AS d04_aces FROM dba_host_aces WHERE principal LIKE 'D04%';

  D04_ACES
----------
         0

1 row selected.

SYS@orcl> SELECT COUNT(*) AS all_aces FROM dba_host_aces;

  ALL_ACES
----------
         3

1 row selected.

SYS@orcl> SELECT COUNT(*) AS d04_users FROM dba_users WHERE username LIKE 'D04%';

 D04_USERS
----------
         0

1 row selected.
-- ★ ALL_ACES 3건은 실습 전 기본 상태다.
@END

@P [10] HTTP 서버 정리
@CODE
[root@oel7v9 ~]# pkill -f 'SimpleHTTPServer 8094'
[root@oel7v9 ~]# rm -rf /tmp/d04_www /tmp/d04_http.log
[root@oel7v9 ~]# ss -ltn | grep -c 8094
0
-- ★ 포트 8094 리스닝 0건으로 시험 서버 정리를 확인한다.
@END

@H3 04.4  정리와 확인 포인트
@B ORA-24247은 패키지 권한 문제가 아니라 ACL 판정 결과다. DBA_HOST_ACES에서 호스트·포트·권한·대상을 차례로 대조한다.
@B 같은 사용자라도 실행 문맥에 따라 결과가 갈린다. 정의자 권한 코드에는 사용자 ACE가 필요하다.
@B 넓은 와일드카드 허용과 구체적 호스트 거부를 조합하면, 대부분 허용하고 특정 대상만 막는 정책이 된다. 반대 조합(넓게 거부, 좁게 허용)도 같은 원리로 동작한다.
@B http와 resolve는 별개다. URL에 호스트 이름을 쓰는 코드에는 두 권한이 모두 필요하다.
@B ACE 정리는 GRANT/DENY 값까지 맞춰야 한다. 남은 DENY ACE는 다음 허용을 조용히 무력화한다.
