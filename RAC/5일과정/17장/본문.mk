@H1 제17장  진단·성능·종합 운영

@H2 17.1  학습 목표

@P 마지막 장이다. 앞 장들에서 쌓은 지식을 진단과 성능의 관점으로 묶는다. 인터커넥트가 실제로 무엇을 쓰는지 확인하고, RAC에만 있는 gc 대기 이벤트를 읽고, 경합의 원인 객체를 특정하고, 로그를 모으고, 장마다 만든 점검 항목을 하나의 스크립트로 합친다. 마지막에 장애를 하나 내고 그 스크립트가 실제로 잡아내는지 확인한다.

@B `oifcfg getif`에 등록된 주소와 `GV$CLUSTER_INTERCONNECTS`의 주소가 다른 이유(HAIP)를 설명할 수 있다.
@B 인터커넥트를 네 단계로 진단할 수 있다.
@B gc 대기 이벤트 이름을 블록 종류·동작·결과로 나눠 읽고, 2-way와 busy의 차이를 설명할 수 있다.
@B `GV$SEGMENT_STATISTICS`와 `GV$INSTANCE_CACHE_TRANSFER`로 경합의 원인 객체와 블록 종류를 특정할 수 있다.
@B `tfactl diagcollect`로 컴포넌트와 시간 범위를 좁혀 로그를 모을 수 있다.
@B 계층별 점검 스크립트를 설계하고, "있어야 할 것의 목록"을 기준으로 조회하는 원칙을 적용할 수 있다.
@B 자동 재기동의 한계(RESTART_ATTEMPTS, CRS-2771)를 설명하고 RAC와 Data Guard의 역할을 구분할 수 있다.

@H2 17.2  인터커넥트 확인

@P 사설 인터커넥트는 설치 가이드 v2에서 ens160(172.16.119.0/24)으로 구성했다(2장). 데이터베이스도 그 주소를 쓸 것 같지만 실제로는 다르다.

@IMG 17_haip.png | 그림 17-1. 등록한 물리 주소 위에 HAIP 별칭이 얹히고, 데이터베이스는 별칭 주소를 쓴다

@H3 17.2.1  데이터베이스가 보고하는 주소

@CODE
SQL> select inst_id, name, ip_address, is_public from gv$cluster_interconnects order by 1;
   INST_ID NAME         IP_ADDRESS       IS_
---------- ------------ ---------------- ---
         1 ens160:1     169.254.27.118   NO
         2 ens160:1     169.254.26.245   NO
@END

@B 172.16.119.101이 아니라 169.254.27.118이고, 인터페이스 이름도 `ens160:1`이다. 콜론 뒤 번호는 가상 인터페이스라는 표시다.
@B 169.254.x.x는 링크 로컬 대역이다. 라우팅되지 않고 같은 링크 안에서만 쓰인다. Clusterware가 물리 인터페이스 위에 만드는 HAIP(Highly Available IP) 별칭이다.
@B `/sbin/ip -4 addr show ens160`을 보면 물리 주소 172.16.119.101/24와 별칭 169.254.27.118/19가 함께 있다. `oifcfg getif`는 관리자가 등록한 구성(ens160 172.16.119.0 cluster_interconnect,asm)이고, 데이터베이스는 그 위의 별칭을 쓴다.

@H3 17.2.2  HAIP를 쓰는 이유

@B 인터커넥트를 여러 개 둘 수 있게 하기 위해서다. 물리 인터페이스를 둘 등록하면 Clusterware가 그 위에 HAIP를 만들어 부하를 나누고, 하나가 죽으면 남은 쪽으로 HAIP를 옮긴다.
@B 데이터베이스는 HAIP 주소만 알면 되므로 물리 구성이 바뀌어도 영향을 받지 않는다. 서비스가 클라이언트와 인스턴스 사이의 이름표인 것처럼 HAIP는 데이터베이스와 물리 네트워크 사이의 이름표다.
@B HAIP는 하위 스택 자원 `ora.cluster_interconnect.haip`이다. `-init` 없이 조회하면 `CRS-2613: Could not find resource`가 나고, `-init`을 붙여야 보인다(11장).

@BP 인터커넥트를 진단하는 순서
노드가 클러스터에 못 붙거나 gc 대기가 비정상으로 크면 네 단계로 본다. ① `oifcfg getif`로 어떤 인터페이스가 인터커넥트로 등록되어 있는지 본다. ② `/sbin/ip -4 addr show <인터페이스>`로 물리 주소와 169.254 별칭이 함께 있는지 본다. ③ `crsctl status res ora.cluster_interconnect.haip -init`가 ONLINE인지 노드마다 본다. ④ `GV$CLUSTER_INTERCONNECTS`에서 IS_PUBLIC이 NO인지 본다. YES면 공용망을 쓰는 심각한 오구성이다.
사설망 ping만 확인하면 물리 주소는 살아 있고 HAIP만 OFFLINE인 경우를 놓친다.
@END

@H3 17.2.3  인터커넥트 통계

@CODE
SQL> select inst_id, name, value from gv$sysstat
  2   where name in ('gc current blocks received','gc current blocks served',
  3                  'gc local grants','gc remote grants') order by name, inst_id;
@END

@B received와 served가 짝을 이룬다. 한 인스턴스가 받은 것은 다른 인스턴스가 보낸 것이다.
@B `gc local grants`와 `gc remote grants`의 비율을 본다. local이 많을수록 자기 노드에서 권한을 받아 인터커넥트를 덜 탄 것이다.
@B 값은 인스턴스 기동 이후 누적이다. 작업 전후로 두 번 읽어 증가분을 비교한다(1장).

@H2 17.3  클러스터 대기 이벤트

@P RAC에만 있는 대기 이벤트는 대부분 gc(Global Cache)로 시작한다. 1장의 Cache Fusion이 만드는 대기로, 다른 인스턴스가 가진 블록을 받아 오기까지 기다린 시간이다. WAIT_CLASS가 모두 Cluster라 이 클래스만 걸러 보면 RAC 특유의 대기를 한 번에 볼 수 있다.

@IMG 17_gcname.png | 그림 17-2. gc 대기 이벤트 이름의 세 부분 — 블록 종류, 동작, 결과

@H3 17.3.1  이름 읽기

@TBL
부분 | 값 | 뜻
블록 종류 | cr / current | 읽기 일관성 사본인가, 수정용 현재 블록인가
동작 | block / grant / multi block | 블록 자체를 받았나, 권한만 받았나
결과 | 2-way / 3-way / busy / congested | 어떻게 끝났나
@END

@B `gc cr block 2-way`는 읽기 일관성 블록을 보유 인스턴스에서 한 번에 받았다는 뜻이다. 정상이며 빠르다.
@B 3-way는 자원 마스터가 제3의 인스턴스여서 한 번 더 거친 경우다. 노드가 셋 이상일 때만 나오므로 실습 환경에는 없다.
@B busy는 상대가 그 블록을 쓰고 있어 기다렸다는 뜻이다. 경합의 신호다.
@B grant는 블록을 보내 줄 인스턴스가 없어 권한만 받고 디스크에서 읽는 경우다.

@TBL
대기 이벤트 | 뜻 | 먼저 의심할 것
gc cr block 2-way / gc current block 2-way | 블록을 보유 노드에서 바로 받음 | 정상. 양이 많으면 인터커넥트 대역폭·지연
gc cr grant 2-way / gc current grant 2-way | 권한만 받고 디스크에서 읽음 | 버퍼 캐시 크기, 물리 읽기
gc current block busy / gc cr block busy | 보유 노드가 그 블록을 쓰는 중이라 지연 | 같은 블록을 다투는 핫 블록
gc buffer busy acquire / release | 같은 블록을 다른 세션이 이미 요청·전송 중 | 핫 블록, 경합 세그먼트
gc current block congested / gc cr block congested | 보내는 쪽 LMS가 과부하 | 보내는 노드의 CPU, LMS 프로세스 수
@END

@H3 17.3.2  경합을 직접 만든다

@P 평소 숫자는 그동안의 작업이 쌓인 것이라 무엇이 무엇을 만드는지 알 수 없다. 실습 02는 두 인스턴스가 같은 블록을 동시에 수정하는 통제된 부하를 건다.

@CODE
SQL> create tablespace ts_ch20 datafile '+DATA' size 100M;
SQL> create table sys.ch20_t (id number primary key, pad varchar2(200)) tablespace ts_ch20;
SQL> insert into sys.ch20_t select level, rpad('x',200,'x') from dual connect by level<=20000;
-- 양 노드에서 동시에: 같은 50 행을 40 초 동안 반복 갱신
begin
  while sysdate < v_end loop
    update sys.ch20_t set pad = rpad('a',200,'a') where id between 1 and 50;
    commit;
  end loop;
end;
@END

@TBL
통계 | 인스턴스 1 증가분 | 인스턴스 2 증가분
gc current blocks received | +3987 | +3996
gc current blocks served | +3996 | +3987
gc local grants | +7428 | +4703
gc remote grants | +205 | +198
@END

@B 인스턴스 1이 받은 3987과 인스턴스 2가 보낸 3987이 같고, 반대 방향도 3996으로 같다. 같은 50행을 두고 40초 동안 블록이 8000번 가까이 인터커넥트를 오갔다.
@B 상위 대기의 순위가 바뀌었다. 부하 전에는 `gc current block 2-way`가 1위였고, 부하 뒤에는 `gc current block busy`가 양 노드에서 1위다.
@B 평균 대기가 2-way의 0.19센티초에서 busy는 0.42~0.44센티초로 두 배 넘게 길다. `gc buffer busy release`도 늘었다. 다른 세션이 그 블록을 보내는 중이라 기다린 것으로, 같은 경합의 다른 얼굴이다.

@H2 17.4  원인 객체 특정

@P 대기 이벤트만으로는 어디를 고쳐야 할지 모른다. 세그먼트 단위와 블록 종류 단위로 좁힌다. 실습 03이 이 단계다.

@IMG 17_contention.png | 그림 17-3. 경합 재현 — 받은 수와 보낸 수가 짝을 이루고, 세그먼트 통계가 원인 테이블을 가리킨다

@H3 17.4.1  GV$SEGMENT_STATISTICS

@CODE
SQL> select inst_id, object_name, statistic_name, value from gv$segment_statistics
  2   where owner='SYS' and object_name='CH20_T' and value > 0
  3     and statistic_name like 'gc%' order by statistic_name, inst_id;
   INST_ID OBJECT_NAME  STATISTIC_NAME                VALUE
---------- ------------ ---------------------------- ------
         1 CH20_T       gc current blocks received      3786
         2 CH20_T       gc current blocks received      3787
@END

@B CH20_T 하나가 양 노드에서 3786과 3787을 받았다. 시스템 전체 증가분과 거의 같다.
@B 시스템 전체 대기가 크다는 것을 알아도 어느 테이블이 원인인지 모르면 손을 댈 수 없다. 실무에서는 `object_name` 조건 없이 `statistic_name`별 상위 세그먼트를 정렬해 본다.

@H3 17.4.2  GV$INSTANCE_CACHE_TRANSFER

@B 이 뷰는 어떤 종류의 블록(data block, segment header, undo header 등)이 오갔는지 보여 준다.
@B data block의 `CURRENT_BUSY`가 4407과 4452로 가장 컸다. 실제 데이터 블록을 두고 다툰 것이다.
@B undo header의 `CR_BLOCK`도 컸다. 읽기 일관성 사본을 만들려면 상대 인스턴스의 UNDO 헤더를 봐야 하기 때문이다. 10장에서 UNDO를 인스턴스별로 나눈 구조의 비용이다.
@B `CR_2HOP`이 `CR_BLOCK`과 항상 같다. 2노드 클러스터에서는 모든 전송이 2-way라서다.

@CASE RAC로 옮긴 뒤 느려졌다는 보고
AWR 상위 대기가 `gc current block busy`였다. 첫째, gc 대기가 전체 DB 시간에서 차지하는 비율로 정말 문제인지 판단한다. 둘째, 2-way 위주면 블록 이동량과 인터커넥트를, busy 위주면 같은 블록을 다투는 설계를 의심한다. 셋째, `GV$SEGMENT_STATISTICS`로 세그먼트를 특정한다. 시퀀스로 채우는 인덱스의 오른쪽 끝, 상태 플래그를 계속 갱신하는 좁은 테이블, 카운터 한 행이 전형적인 원인이다.
고치는 방법은 서비스를 나눠 그 업무를 한 인스턴스로 모으는 것(12장), 시퀀스에 CACHE·NOORDER를 주고 인덱스를 해시 파티션으로 바꾸는 것, 갱신 빈도를 줄이는 것이다. 서비스 분리가 가장 빠르다. 그 업무를 한 인스턴스에 모으면 그 블록의 Cache Fusion이 필요 없어지고, 다른 업무가 반대 노드를 쓰면 전체로는 잘 나뉜 것이다.
@END

@H2 17.5  로그 수집

@P 11g·12c 자료에는 `diagcollection.pl`로 클러스터 로그를 모으라고 되어 있다. 19c 그리드 홈에는 이 파일이 없고 `tfactl`(Trace File Analyzer)이 그 역할을 넘겨받았다.

@B `tfactl print status`로 보면 TFA가 두 노드에서 데몬으로 돌고 있다. 한 노드에서 명령하면 다른 노드의 로그까지 모을 수 있다.
@B `diagcollection.pl`은 노드마다 따로 실행해야 했다.

@CODE
[grid@rac1 ~]$ tfactl diagcollect -crs -last 1h -node local -tag ch20
| rac1 | Completed | 63MB | 289s |
Logs are being collected to: /u01/app/grid/tfa/repository/ch20
[grid@rac1 ~]$ tfactl diagcollect -last 5m -node local
The time entered is invalid: 5m
Some examples of valid time entries for -since flag : 2h, 10d
@END

@B `-crs`는 컴포넌트 지정이다. `-database`, `-asm`, `-tns` 등이 있고, 지정하지 않으면 전부 모아 훨씬 커진다.
@B `-node local`은 이 노드만, `-node all`은 모든 노드에서 모아 한곳으로 가져온다. `-tag`는 저장소 안의 디렉터리 이름이다.
@B 시간 단위는 h와 d다. `5m`은 거부되며, 오류 메시지가 유효한 예를 알려 준다.

@BP 언제 무엇을 모으는가
지원 요청(SR)을 열 때는 `-srdc`로 증상별 정의된 묶음을 쓴다. 노드 축출이면 `-srdc dbrac_evictions`다. 스스로 분석할 때는 컴포넌트를 좁히고 시간 범위를 반드시 준다.
장애 직후에 모은다. 로그는 회전하므로 며칠 지나면 사라진다. 수집 자체가 I/O와 CPU를 쓰므로 급한 불을 끈 뒤에 모으는 편이 낫다.
@END

@H2 17.6  종합 점검 스크립트

@P 앞 장들에서 점검 항목을 만들었다. 실습 05는 그것을 계층 순서로 묶은 `rac_check.sh`를 만들고 돌린다.

@TBL
계층 | 출처 | 핵심 항목
1 클러스터 | 2·11장 | 스택 online 6/6, 자원 개수 17, TARGET·STATE 불일치
2 알림 | 13장 | ONS 데몬 응답
3 서비스 | 12장 | 서비스 기동 여부, 선호 인스턴스 배치
4 인스턴스 | 9장 | Open 인스턴스 수, SPFILE 위치
5 스토리지 | 10장 | 스레드별 CURRENT, UNDO 크기
6 백업 | 14장 | 아카이브 대상 상태, 스레드별 아카이브, FRA 사용률
@END

@CODE
ok()   { printf "  [ OK ] %s\n" "$1"; }
bad()  { printf "  [FAIL] %s\n" "$1"; FAIL=$((FAIL+1)); }
warn() { printf "  [WARN] %s\n" "$1"; }
n=$($GRID_HOME/bin/crsctl check cluster -all 2>/dev/null | grep -c "is online")
[ "$n" -eq 6 ] && ok "스택 online 6/6" || bad "스택 online $n/6"
opened=$($DB_HOME/bin/srvctl status database -d $DB -v 2>/dev/null | grep -c "Open")
[ "$opened" -eq 2 ] && ok "인스턴스 $opened 개 Open" || bad "Open 인스턴스 $opened 개"
printf "\n== 결과: 실패 %d 건 ==\n" "$FAIL"; exit $FAIL
@END

@B 실패와 경고를 나눈다. 인스턴스가 안 떠 있는 것은 FAIL, 자원 개수가 기준선과 다른 것은 WARN이다. 개수는 정당한 이유로 달라질 수 있다.
@B 종료 코드로 실패 건수를 돌려준다. 스케줄러나 감시 도구가 그것으로 판단한다.
@B 기준선(17, 6)을 숫자로 박아 둔다. 환경이 바뀌면 이 숫자를 고치는데, 고칠 때가 구성 변경을 인지하는 때다.
@B 실행 결과는 실패 0건이었다. WARN으로 잡힌 넷은 Flex ASM의 빈 칸(`ora.asmgroup` 3번)과 rac2의 `ora.chad`로, 이 환경에서 의도된 OFFLINE이다. 매일 같은 WARN이 나오면 사람이 무시하게 되므로 알려진 예외는 스크립트에서 걸러 낸다.

@CODE
[oracle@rac1 ~]$ ./rac_check.sh racdb
== 1. 클러스터 계층 ==
  [ OK ] 스택 online 6/6
  [ OK ] 일반 자원 17 개
  [WARN] 불일치: ora.asmnet1.asmnetwork(ora.asmgroup) ... ora.chad
== 4. 인스턴스 계층 ==
  [ OK ] 인스턴스 2 개 Open
       inst 1 dest1=VALID
       inst 2 dest1=VALID
== 결과: 실패 0 건 ==
@END

@B 전체 점검은 10여 초에 끝났다. 매일 돌려도 부담이 없으므로 cron이나 운영 스케줄러에 걸고 종료 코드가 0이 아니면 알림을 보내게 한다.
@B 스토리지·백업 계층은 SQL 한 번으로 스레드별 CURRENT, UNDO 크기, 아카이브 대상 상태, FRA 사용률, SPFILE 위치, 인터커넥트 주소를 함께 출력한다. 이 값들은 판정 없이 보여 주기만 하므로 사람이 읽어야 한다.
@B 점검 결과는 날짜별 파일로 남긴다. 장애가 났을 때 마지막 정상 시점의 출력과 비교하면 무엇이 바뀌었는지 바로 보인다.

@H3 17.6.1  없는 것은 보이지 않는다

@B 처음 만든 아카이브 점검은 `v$archived_log`를 `group by thread#`로 묶었는데 thread 1만 나왔다. thread 2는 정리 이후 아직 아카이브를 만들지 않아 행 자체가 없었다.
@B thread 2가 30분째 아카이브를 못 만들고 있어도 화면에는 아무것도 나오지 않는 구조다.

@CODE
SQL> select t.thread#, nvl(a.cnt,0) archived, a.mx max_seq
  2    from v$thread t
  3    left join (select thread#, count(*) cnt, max(sequence#) mx
  4                 from v$archived_log where deleted='NO' group by thread#) a
  5      on t.thread# = a.thread# order by t.thread#;
   THREAD#   ARCHIVED    MAX_SEQ
---------- ---------- ----------
         1          1         31
         2          0
@END

@NOTE 점검 스크립트의 원칙
"있어야 할 것의 목록"을 기준으로 조회하고 실제 값을 붙인다. "실제 있는 것"을 기준으로 조회하면 없는 것이 안 보인다. 스레드는 `V$THREAD`, 인스턴스는 `GV$INSTANCE`, 자원은 기준선 개수가 그 목록이다. 스레드별 CURRENT 조회와 서비스 점검에도 같은 함정이 있다.
@END

@H2 17.7  장애 시나리오와 자동 복구의 한계

@P 점검 스크립트를 장애로 검증한다. 14장과 같은 방식으로 racdb2의 pmon을 강제 종료하고 세 시점에서 스크립트를 돌린다(실습 06, 자습).

@IMG 17_trace.png | 그림 17-4. 인스턴스 하나가 죽은 20초 뒤 점검 스크립트에 남은 계층별 흔적

@B 약 20초 뒤 실패 1건이 나왔다. 인스턴스 계층이 FAIL로 잡혔고, 클러스터 계층의 불일치 목록에 `ora.racdb.db`가 추가되었다.
@B 스토리지와 백업 계층에서는 인스턴스 2 관련 행이 조용히 사라졌다. 17.6.1의 결함이 실제 장애에서 그대로 나타났다. 백업 계층만 보는 사람은 "아카이브 대상이 하나로 줄었다"를 설정 문제로 오진할 수 있다.
@B 약 100초 뒤 CRS가 racdb2를 자동으로 다시 올려 실패 0건으로 돌아왔다.

@TBL
시점 | 클러스터 계층 | 인스턴스 계층 | 스토리지·백업 계층 | 결과
장애 전 | WARN(알려진 4건) | OK, Open 2개 | thread 1·2, dest1 2행 | 실패 0건
약 20초 뒤 | WARN에 ora.racdb.db 추가 | FAIL, Open 1개 | thread 2·inst 2 행 사라짐 | 실패 1건
약 100초 뒤 | WARN(알려진 4건) | OK, Open 2개 | thread 1·2, dest1 2행 | 실패 0건
@END
@B 하나의 사건이 여러 계층에 흔적을 남긴다. 계층 순서로 보면 시작점을 추적할 수 있고, 한 계층만 보면 오진한다.

@H3 17.7.1  자동 재기동은 무한하지 않다

@CODE
[grid@rac1 ~]$ crsctl stat res ora.racdb.db -p | grep -E '^RESTART_ATTEMPTS|^UPTIME_THRESHOLD'
RESTART_ATTEMPTS=2
UPTIME_THRESHOLD=1h
CRS-2771: Maximum restart attempts reached for resource 'ora.racdb.db'; will not restart.
@END

@B 같은 장애를 한 시간 안에 두 번 내자 두 번째에는 CRS가 인스턴스를 살리지 않았다. 자원이 `UPTIME_THRESHOLD`(1시간) 넘게 살아 있어야 재시도 횟수가 초기화된다.
@B TARGET은 여전히 ONLINE이다. CRS는 떠 있어야 한다고 알지만 더 시도하지 않는다. `srvctl start instance -d racdb -i racdb2`로 사람이 올리면 정상으로 돌아오고 횟수도 초기화된다.
@B 점검이 FAIL을 계속 보고하면 CRS를 기다리지 말고 `crsctl stat res <자원> -t`와 CRS 알럿 로그의 CRS-2771을 확인한다. 한 시간에 두 번 죽었다는 것 자체가 원인이 남아 있다는 신호다.

@H2 17.8  RAC와 Data Guard

@TBL
구분 | RAC | Data Guard
막는 장애 | 인스턴스·서버 장애 | 스토리지·사이트 장애
데이터 사본 | 하나(공유 스토리지) | 둘 이상(독립 스토리지)
전환 | 남은 노드가 계속 서비스 | 스탠바이로 Failover
논리 오류(잘못된 DROP) | 막지 못함 | 막지 못함 → 백업·플래시백
@END

@B RAC는 데이터베이스가 하나다. 14장에서 데이터 파일 하나를 지우자 두 노드에서 똑같이 ORA-00376이 났다. 공유 스토리지이므로 장애도 공유된다.
@B 실무의 표준은 주 사이트에 RAC, 재해 복구 사이트에 스탠바이를 두고 백업을 함께 운영하는 것이다. 세 가지는 서로를 대신하지 않는다(1장).
@TBL
사건 | 누가 막는가 | 결과
rac2 인스턴스 다운·서버 고장 | RAC | rac1이 계속 서비스
공유 스토리지 어레이 고장 | Data Guard | 스탠바이로 Failover
데이터센터 정전 | Data Guard | 스탠바이로 Failover
실수로 테이블 DROP | 둘 다 못 막음 | 플래시백 또는 시점 복구(14장)
@END

@B Data Guard를 얹으려면 ARCHIVELOG(14장), 스레드별 리두(10장), 공유 위치의 아카이브(14장)가 필요하며 실습 환경은 이미 갖췄다. FORCE LOGGING, `log_archive_config`, 스탠바이 리두 로그는 스탠바이를 만들 때 하고, RAC에서는 `sid='*'`로 모든 인스턴스에 같은 설정을 준다.

@H2 17.9  과정을 마치며

@P 1장부터 16장까지 다룬 내용을 장애가 났을 때 보는 순서로 다시 묶는다. 아래 계층이 무너지면 위 계층에 단서가 남지 않으므로 Clusterware에서 시작해 SQL로 올라간다.

@IMG 17_order.png | 그림 17-5. 진단 순서 — Clusterware, 노드 멤버십, 디스크그룹, 인스턴스, 서비스·리스너, SQL

@TBL
순서 | 계층 | 다룬 장 | 먼저 보는 것
1 | Clusterware | 2 · 3 · 11장 | `crsctl check cluster -all`, `crsctl stat res -t`와 `-init`, OCR·보팅 파일(`ocrcheck`, `crsctl query css votedisk`), TARGET·STATE 불일치
2 | 노드 멤버십 | 2 · 3 · 15 · 17장 | `olsnodes -n -s -t`, `oifcfg getif`, HAIP, 보팅 파일 과반, 인벤토리 노드 목록
3 | 디스크그룹 | 4 ~ 8 · 10장 | `asmcmd lsdg`, `V$ASM_DISKGROUP`의 MOUNTED·여유 공간, `V$ASM_OPERATION` 리밸런스, 오프라인 디스크
4 | 인스턴스 | 1 · 9 · 10 · 14 · 16장 | `srvctl status database -v`, `gv$instance`, `sid.parameter`, 스레드·UNDO, 아카이브 대상, 인스턴스 이름
5 | 서비스·리스너 | 1 · 12 · 13장 | `srvctl status service`, `lsnrctl services`, SCAN·VIP, ORA-12514/12541, FAN·TAF·AC
6 | SQL | 1 · 17장 | `gv$system_event`의 gc 대기, `gv$segment_statistics`, 서비스 분리
@END

@B Clusterware: 자원이 TARGET과 STATE로 관리된다는 것, `srvctl`은 Oracle 자원을, `crsctl`은 Clusterware 자체를 다룬다는 경계가 출발점이다. OCR과 보팅 파일이 +CRS에 있고 수동 백업으로 시점을 남긴다.
@B 노드 멤버십: 하트비트는 사설망과 보팅 파일로 판정된다. 인터커넥트는 HAIP 별칭으로 쓰이고, 노드를 빼고 넣을 때는 OCR·인벤토리·DB 구성 세 곳을 맞춘다.
@B 디스크그룹: 이중화 수준과 장애 그룹이 무엇을 견디는지 정하고, 디스크 추가·제거는 리밸런스로 이어진다. 데이터 파일과 아카이브는 모든 노드가 보는 디스크그룹에 둔다.
@B 인스턴스: 데이터베이스는 하나, 인스턴스는 여럿이며 리두 스레드와 UNDO는 인스턴스마다 따로다. 인스턴스가 죽으면 다른 인스턴스가 1초 안팎에 복구하고, RAC One Node에서는 인스턴스 이름이 바뀐다.
@B 서비스·리스너: 클라이언트는 인스턴스가 아니라 SCAN과 서비스로 붙는다. 서비스 배치가 부하와 장애 시 이동을 정하고, FAN·TAF·AC가 그 위에서 끊긴 연결을 이어 준다.
@B SQL: 같은 블록을 여러 노드가 다투면 gc busy 대기로 나타난다. 원인 세그먼트를 특정해 서비스 분리나 설계 변경으로 해소한다.

@B 이 과정에서 가장 자주 반복한 것은 직접 확인하는 습관이다. `restore spfile to`가 CRS 등록을 바꾼 것, `log_archive_dest_1=''`이 비활성화였던 것, 인터커넥트 주소가 등록한 것과 달랐던 것, `addnode.sh`가 성공을 보고했는데 인벤토리가 늘지 않은 것이 그런 예다.
@B 되돌리기를 습관으로 삼는다. 모든 실습은 기준선(두 노드, 두 인스턴스, CRS 자원 17개)으로 돌아오게 설계되었다. 무엇을 바꿨는지 알고 있어야 되돌릴 수 있다.

@H2 17.10  요약

@B 데이터베이스는 등록된 물리 주소가 아니라 HAIP 별칭(169.254.x.x, ens160:1)으로 인터커넥트를 쓴다. 진단은 `oifcfg getif` → `ip addr` → HAIP `-init` → `GV$CLUSTER_INTERCONNECTS` 순이다.
@B gc 대기는 블록 종류·동작·결과로 읽는다. 2-way는 이동량, busy는 같은 블록을 다투는 경합의 신호다.
@B 같은 50행을 두 노드가 갱신하자 받은 수와 보낸 수가 짝을 이루며 늘었고, 상위 대기가 `gc current block busy`로 바뀌었다.
@B 원인 객체는 `GV$SEGMENT_STATISTICS`, 블록 종류는 `GV$INSTANCE_CACHE_TRANSFER`로 특정한다.
@B 19c는 `tfactl diagcollect`로 로그를 모으며 컴포넌트와 시간 범위(h, d)를 지정한다.
@B 점검 스크립트는 계층 순으로 짜고 FAIL과 WARN을 나누며, "있어야 할 것의 목록"을 기준으로 조회한다.
@B 자동 재기동은 RESTART_ATTEMPTS·UPTIME_THRESHOLD 안에서만 돈다. CRS-2771이면 사람이 올리고 원인을 찾는다.

@H2 17.11  퀴즈

@QUIZ 퀴즈
1. `oifcfg getif`의 주소와 `GV$CLUSTER_INTERCONNECTS`의 주소가 다른 이유는?
2. 인터커넥트 진단 네 단계를 쓰고, 사설망 ping만으로 부족한 이유를 설명하시오.
3. `gc cr block 2-way`와 `gc current block busy`를 이름의 세 부분으로 나눠 해석하시오.
4. 시스템 대기만으로 부족해 `GV$SEGMENT_STATISTICS`를 봐야 하는 이유는?
5. `group by thread#`만 쓴 아카이브 점검의 결함과 고치는 방법은?
6. 인스턴스가 한 시간 안에 두 번 죽었을 때 CRS가 다시 올리지 않은 이유와 조치는?
@END

@NOTE 정답과 해설
1. Clusterware가 등록된 물리 인터페이스(ens160) 위에 HAIP 링크 로컬 별칭(169.254.x.x, ens160:1)을 만들고 데이터베이스는 그 별칭을 쓰기 때문이다.
2. oifcfg getif → /sbin/ip -4 addr show → crsctl status res ora.cluster_interconnect.haip -init → GV$CLUSTER_INTERCONNECTS. 물리 주소는 살아 있고 HAIP만 OFFLINE이면 ping은 성공한다.
3. cr(읽기 일관성)·block(블록 수신)·2-way(보유 노드와 바로 끝남), current(수정용)·block·busy(상대가 쓰는 중이라 대기, 경합).
4. 전체 대기가 크다는 것만으로는 어느 테이블·인덱스가 원인인지 알 수 없어 손을 댈 수 없다.
5. 아카이브가 없는 스레드는 행이 없어 결과에서 사라진다. V$THREAD를 기준으로 아우터 조인해 archived=0으로 드러낸다.
6. RESTART_ATTEMPTS=2, UPTIME_THRESHOLD=1h라 재시도 한도를 넘었다(CRS-2771). srvctl start instance로 올리고 반복 장애의 원인을 찾는다.
@END

@H2 17.12  실습 개요

@P 이 장의 실습은 확인과 성능 분석, 점검 스크립트 작성이다. 실습 02는 양 노드에서 40초 동안 부하를 만들므로 호스트 부하가 낮을 때 진행한다.

@TBL
실습 | 파일 | 목적
01 | RAC/20장/20장_실습_01_인터커넥트와HAIP확인.txt | oifcfg·ip addr·HAIP 자원·GV$CLUSTER_INTERCONNECTS를 대조한다
02 ★ | RAC/20장/20장_실습_02_gc경합만들기.txt | 두 노드에서 같은 행을 갱신해 gc 통계와 대기 순위 변화를 본다
03 ★ | RAC/20장/20장_실습_03_경합원인객체특정.txt | GV$SEGMENT_STATISTICS와 GV$INSTANCE_CACHE_TRANSFER로 원인 객체를 특정한다
05 | RAC/20장/20장_실습_05_종합점검스크립트.txt | rac_check.sh를 만들어 돌리고 아카이브 점검의 결함을 고친다
@END

@B ★는 두 노드가 모두 살아 있어야 하는 실습이다.
@B 실습 03을 마치면 `drop tablespace ts_ch20 including contents and datafiles`로 실습 객체를 지운다. 점검 스크립트는 남겨 두고 이후 운영에 쓴다.
@B 수료 후 자습: 20장_실습_04_TFA로그수집, 20장_실습_06_장애시나리오와정리. 실습 06은 racdb2를 강제 종료하므로 한 시간 안에 두 번 하지 않는다.
