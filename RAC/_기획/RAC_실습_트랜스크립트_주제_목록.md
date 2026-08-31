# Oracle Database 19c Real Application Clusters 교안 — 실습 트랜스크립트 주제 목록 (v1)

**작성일**: 2026-08-31
**상태**: 챕터 20장 확정. 실습 환경 구축 후 착수.

- **형식**: SQL\*Plus / `srvctl` / `crsctl` / `asmcmd` / 셸 세션 트랜스크립트. 프롬프트로 노드와 계정을 구분한다 — `[grid@rac1 ~]$`, `[oracle@rac1 ~]$`, `[root@rac1 ~]#`, `SYS@racdb1>`, `SYS@+ASM1>`, `ASMCMD>`
- **파일명**: `{N}장_실습_{NN}_{주제}.txt`
- **총 20장 / 132개**
- 각 파일 최소 1곳에 **"오류·이상 징후 발생 → 원인 파악 → 조치 → 재확인"** 흐름을 넣는다
- **★** = 두 노드가 모두 살아 있어야 성립하는 실습
- **⚠** = 되돌릴 수 없거나 클러스터를 멈추는 실습. **시작 전 양쪽 전원을 끄고 스냅샷을 뜬다**
- **공통 전제**: 개인 실습 환경 전용. 노드 강제 종료·자원 정지·디스크 제거가 포함된다
- **되돌리기 원칙**: 각 실습은 끝에서 클러스터를 `CRS-4537: Cluster Ready Services is online` 과 두 인스턴스 `OPEN` 상태로 되돌린다

---

## 1장. RAC 개요와 아키텍처 (6개)
1. 클러스터 전체 상태 파악 — `crsctl status resource -t` 한 화면으로 무엇을 알 수 있는지 읽는 법
2. 두 인스턴스가 하나의 DB 를 공유한다는 것 확인 — `GV$INSTANCE`, `V$INSTANCE` 의 차이, `INST_ID` 열의 의미
3. **Cache Fusion 실측 ★** — 한 노드에서 갱신한 블록을 다른 노드에서 읽고 `GV$SYSSTAT` 의 `gc` 통계 변화 관찰
4. 단일 인스턴스와의 구조 차이 — 스레드별 리두, 인스턴스별 UNDO, 공유 컨트롤 파일을 조회로 확인
5. **라이선스 경계 확인** — RAC 옵션과 EE 기본 기능의 구분, `DBA_FEATURE_USAGE_STATISTICS` 조회
6. 노드 하나를 정지했을 때 무엇이 계속되는가 ★ — 정지 전후 접속과 조회 비교

## 2장. Clusterware 구조와 프로세스 (7개)
1. Clusterware 프로세스 식별 — `ps -ef` 에서 `ohasd`·`crsd`·`ocssd`·`evmd` 찾기, 각각의 역할
2. 두 스택의 구분 — `crsctl check has` 와 `crsctl check crs` 가 다른 것을 보여 준다
3. 자원(resource) 개념 — `crsctl status resource` 로 자원 유형별 목록, `ora.` 접두어의 의미
4. 시작 순서 추적 ⚠ — Clusterware 를 정지했다 켜며 로그에서 기동 순서 확인
5. **오류 재현** — 스택이 내려간 상태에서 `srvctl` 명령 실행 → `CRS-4639`·`CRS-4535` 구분
6. 로그 위치 확인 — `$ORACLE_BASE/diag/crs/<node>/crs/trace/`, `alert.log` 와 각 프로세스 로그
7. 자동 기동 설정 — `crsctl enable/disable crs` 와 재기동 후 동작 확인

## 3장. 클러스터 설치 준비 (7개)
1. 네트워크 요건 확인 — 공용·사설 인터페이스 식별, `oifcfg getif`, 두 네트워크가 분리된 것 확인
2. **이름 해석 검증** — `/etc/hosts` 에 public·VIP·private·SCAN 을 등록하고 양방향 `ping`·`nslookup`
3. **오류 재현** — SCAN 이름이 없을 때 `cluvfy` 가 무엇이라고 하는지
4. 공유 디스크 인식 확인 ★ — 양쪽 노드에서 같은 디스크가 같은 크기로 보이는지, `/dev/sd*` 와 `scsi_id`
5. udev 규칙으로 디스크 이름 고정 — 규칙 작성, `udevadm` 로 적용, 권한 확인
6. 커널 파라미터와 사용자 — `oracle-database-preinstall-19c` 가 무엇을 바꾸는지 전후 대조
7. **`cluvfy stage -pre crsinst` 전체 실행** — 실패 항목을 하나씩 해소하는 과정

## 4장. Grid Infrastructure 설치 ⚠ (7개)
1. 응답 파일 작성 — `gridsetup.rsp` 의 필수 항목과 각각의 의미
2. `gridSetup.sh -silent` 실행과 진행 관찰
3. **`root.sh` 실행 ★** — 노드 순서가 중요한 이유, 출력 단계별 읽기
4. **오류 재현** — `root.sh` 를 두 노드에서 동시에 실행했을 때
5. 설치 후 검증 — `crsctl check cluster -all`, `crsctl status resource -t`, `cluvfy stage -post crsinst`
6. 설치 실패 시 되돌리기 — `deinstall` 과 수동 정리 항목
7. Grid 홈 구조 파악 — 주요 디렉터리와 실행 파일, `$ORACLE_HOME` 두 개를 구분하는 법

## 5장. OCR·Voting File 관리 ⚠ (7개)
1. 현재 구성 확인 — `ocrcheck`, `crsctl query css votedisk`, 몇 개이고 어디에 있는가
2. OCR 자동 백업 확인 — `ocrconfig -showbackup`, 주기와 보관 위치
3. **OCR 수동 백업과 복원** — `ocrconfig -export` / `-import`, 클러스터 정지가 필요한 시점
4. OCR 다중화 — `ocrconfig -add`, 두 벌이 된 것 확인, 하나 제거
5. **Voting File 다중화 실측** — `+CRS` 가 Normal 이라 3개인 이유, `crsctl replace votedisk`
6. **오류 재현 ⚠** — Voting File 을 담은 디스크를 강제로 내리고 클러스터의 반응 관찰
7. 손실 시 복구 절차 — 시나리오별 절차 정리와 실제 복원

## 6장. ASM 인스턴스와 디스크그룹 (7개)
1. ASM 인스턴스 파악 — `+ASM1`/`+ASM2`, `V$ASM_*` 첫 조회, DB 인스턴스와의 차이
2. ASM 파라미터 — `ASM_DISKSTRING`·`ASM_POWER_LIMIT`·`INSTANCE_TYPE` 확인과 변경
3. 디스크 발견 — `V$ASM_DISK` 의 `HEADER_STATUS`, `CANDIDATE`/`MEMBER`/`PROVISIONED` 구분
4. **디스크그룹 생성** — `+DATA` 를 만들고 양쪽 노드에서 마운트 확인 ★
5. **오류 재현** — 이미 쓰이는 디스크로 디스크그룹을 만들려 하면
6. 마운트·언마운트 — `ALTER DISKGROUP ... DISMOUNT`, 쓰이는 중이면 어떻게 되는가
7. 이중화 수준 세 가지 — External·Normal·High 의 요건과 실제 용량 차이 실측

## 7장. ASM 파일·디렉터리·템플릿 (6개)
1. OMF 이름 규칙 해부 — `+DATA/RACDB/DATAFILE/...` 경로가 만들어지는 규칙
2. 별칭(alias) 만들기 — `ALTER DISKGROUP ... ADD ALIAS`, 실제 파일과의 관계
3. 디렉터리 구조 — `asmcmd ls -l` 로 계층 확인, 시스템 디렉터리와 사용자 디렉터리
4. **템플릿** — 기본 템플릿 목록, 사용자 템플릿 생성, 이중화·스트라이프 지정
5. **오류 재현** — 별칭만 지우면 실제 파일은 어떻게 되는가
6. 파일 접근 — `asmcmd cp` 로 ASM 안팎으로 복사

## 8장. ASM 리밸런스와 이중화 ⚠ (7개)
1. 현재 디스크 배치 확인 — `V$ASM_DISK` 의 `TOTAL_MB`·`FREE_MB` 분포
2. **디스크 추가와 리밸런스 관찰 ★** — `ADD DISK` 후 `V$ASM_OPERATION` 을 반복 조회
3. 리밸런스 속도 조절 — `REBALANCE POWER` 변경, 소요 시간 비교
4. **디스크 제거** — `DROP DISK`, `HEADER_STATUS` 변화, 언제 실제로 빠지는가
5. **장애 그룹(failure group)** — Normal 이중화에서 미러가 어디 놓이는지 `V$ASM_DISK` 로 확인
6. **디스크 강제 손실 재현 ⚠** — 디스크 하나를 offline 시키고 `DISK_REPAIR_TIME` 동작 관찰
7. 복구 — `ONLINE DISK` 로 되살리기, 재동기화 관찰

## 9장. ASM 뷰와 asmcmd (6개)
1. `V$ASM_*` 계열 지도 — `DISKGROUP`·`DISK`·`FILE`·`CLIENT`·`OPERATION` 각각이 답하는 질문
2. **`GV$` 로 두 ASM 인스턴스 함께 보기 ★**
3. `asmcmd` 명령 체계 — `ls`·`du`·`lsdg`·`lsdsk`·`lsof`·`iostat`
4. **오류 재현** — `asmcmd` 를 `oracle` 계정으로 실행하면
5. ASMCA 무인 모드 — `asmca -silent` 로 디스크그룹 생성
6. 용량 산정 — `USABLE_FILE_MB` 가 음수가 될 수 있는 이유

## 10장. ASM 마이그레이션 — RMAN 활용 (6개)
1. 마이그레이션 전 점검 — 현재 파일 위치 목록, 필요 공간 계산
2. **데이터 파일 하나를 ASM 으로 옮기기** — RMAN `BACKUP AS COPY` + `SWITCH`
3. **오류 재현** — 파일이 사용 중일 때 `SWITCH` 를 시도하면
4. 디스크그룹 간 이동 — `+DATA` → `+FRA` 로 옮기고 되돌리기
5. SPFILE·컨트롤 파일 이동 — 나머지 파일과 절차가 다른 이유
6. 되돌리기 — ASM → 파일 시스템 역방향과 그때의 제약

## 11장. RAC 데이터베이스 생성 ⚠ (7개)
1. 생성 전 점검 — 디스크그룹 여유, 클러스터 상태, `cluvfy stage -pre dbinst`
2. DBCA 응답 파일 작성 — RAC 전용 항목(`nodelist`, `storageType`, `diskGroupName`)
3. **`dbca -silent` 실행과 진행 관찰**
4. **오류 재현** — 노드 목록에 없는 노드를 넣으면
5. 생성 결과 검증 — 인스턴스 2개, 스레드 2개, UNDO 2개, `srvctl config database`
6. PDB 확인 — 양쪽 노드에서 `V$PDBS`, 열림 상태 차이 ★
7. 생성 실패 시 정리 — `dbca -deleteDatabase` 와 수동 정리 항목

## 12장. 인스턴스와 클러스터 DB 관리 ★ (7개)
1. 기동·정지 — `srvctl start/stop database` 와 `instance` 의 차이, 옵션별 동작
2. **`crsctl` 로 전체 정지** — `srvctl` 과 무엇이 다른가
3. SQL\*Plus 로 개별 인스턴스 제어 — 언제 쓰고 언제 쓰면 안 되는가
4. **SPFILE 의 `sid.parameter` 표기** — `*.` 과 `racdb1.` 의 차이를 실측으로
5. **세 분류 실습** — 반드시 같아야 하는 것 / 달라야 하는 것 / 같은 것이 권장되는 것
6. **오류 재현** — 반드시 같아야 하는 파라미터를 한쪽만 바꾸면
7. PDB 를 노드별로 열고 닫기 — `srvctl` 로 PDB 서비스 관리

## 13장. RAC 스토리지 관리 ★ (6개)
1. 스레드별 리두 확인 — `V$LOG` 의 `THREAD#`, 노드와의 대응
2. **리두 그룹 추가** — 새 스레드용 그룹 생성, 활성화
3. UNDO 테이블스페이스 — 인스턴스별로 나뉜 이유, `UNDO_TABLESPACE` 파라미터
4. **오류 재현** — 다른 인스턴스의 UNDO 를 쓰려 하면
5. 임시 테이블스페이스 — 공유되는 이유와 노드별 사용량 조회
6. 데이터 파일 추가 — 어느 노드에서 하든 양쪽에 반영되는 것 확인

## 14장. srvctl·crsctl 명령 체계 (7개)
1. 두 명령의 역할 분담 — 무엇을 `srvctl` 로 하고 무엇을 `crsctl` 로 하는가
2. `srvctl` 자원별 문법 — `database`·`instance`·`service`·`listener`·`scan`·`asm`·`vip`
3. `crsctl` 자원 조회 — `status resource -t -init`, `-init` 이 보여 주는 다른 세계
4. **오류 재현** — `crsctl` 로 DB 자원을 직접 정지하면 무슨 일이 일어나는가
5. **자원 등록 실습** — `crsctl add resource` 로 사용자 스크립트를 클러스터 자원으로
6. 자원 속성 — `crsctl status resource ... -p`, `AUTO_START`·`RESTART_ATTEMPTS`
7. 오류 번호 체계 — `CRS-`·`PRCR-`·`PRCD-` 접두어가 알려 주는 계층

## 15장. 동적 데이터베이스 서비스 ★ (7개)
1. 기본 서비스 확인 — DB 이름 서비스와 PDB 서비스, `lsnrctl status` 에서 읽기
2. **서비스 생성** — `srvctl add service` 로 선호/가용 인스턴스 지정
3. 서비스 기동과 배치 확인 — 어느 노드에서 도는지, `GV$ACTIVE_SERVICES`
4. **서비스 이동** — `srvctl relocate service`, 접속 중인 세션은 어떻게 되는가
5. **장애 시 자동 이동 ⚠** — 선호 인스턴스를 죽이고 서비스가 옮겨 가는 것 관찰
6. **오류 재현** — 없는 인스턴스를 선호로 지정하면
7. 접속 부하 분산 — SCAN 을 통한 접속을 반복해 분산 확인

## 16장. 부하 관리와 Application Continuity (6개)
1. FAN 이벤트 확인 — ONS 상태, `srvctl config nodeapps -onsonly`
2. **부하 분산 권고** — 서비스에 `-clbgoal`·`-rlbgoal` 지정, `V$SERVICEMETRIC` 관찰
3. **접속 부하 분산 실측 ★** — 세션을 여러 개 열어 분산 결과 집계
4. Application Continuity 설정 — `-failovertype TRANSACTION`, 서비스 속성 확인
5. **오류 재현** — 필수 속성 없이 AC 를 켜려 하면
6. 재생(replay) 조건 — 무엇이 재생되고 무엇이 안 되는지 정리

## 17장. RAC 백업과 복구 ⚠ (7개)
1. 아카이브 구성 확인 — 모든 노드가 접근 가능해야 하는 이유, ASM 에 두는 구성
2. **오류 재현** — 아카이브를 로컬 경로에 두면 다른 노드에서 무슨 일이 생기는가
3. **노드 분산 백업 ★** — 채널을 두 노드에 나눠 할당해 병렬 백업
4. 백업 검증 — `RESTORE ... VALIDATE`, 어느 노드에서 하든 되는지
5. **인스턴스 복구 관찰 ⚠** — 노드 하나를 강제 종료하고 다른 노드가 복구하는 과정
6. 미디어 복구 — 데이터 파일 하나를 손상시키고 복구
7. 컨트롤 파일·SPFILE 복구 — ASM 에 있을 때의 절차

## 18장. 노드 추가와 삭제 ⚠ (7개)
1. 추가 전 점검 — `cluvfy stage -pre nodeadd`
2. **노드 삭제 실습 ⚠** — `rac2` 를 클러스터에서 제거하는 전체 절차
3. 삭제 후 검증 — 남은 노드에서 무엇이 달라졌는지
4. **노드 재추가 ⚠** — `addnode.sh` 로 다시 넣기
5. **오류 재현** — 정리가 덜 된 상태에서 재추가를 시도하면
6. DB 인스턴스 추가 — `dbca -addInstance`
7. 원복 검증 — 두 노드·두 인스턴스 구성으로 완전 복귀

## 19장. RAC One Node (5개)
1. 개념과 구성 확인 — 일반 RAC 와 무엇이 다른가
2. **변환 실습** — `srvctl convert database -dbtype RACONENODE`
3. **온라인 재배치** — `srvctl relocate database`, 소요 시간 측정
4. **오류 재현** — 재배치 중에 다른 명령을 내면
5. 되돌리기 — RAC 로 다시 변환하고 검증

## 20장. 진단·성능·종합 운영 ★ (6개)
1. 클러스터 대기 이벤트 — `gc` 계열 상위 조회, 단일 인스턴스와 다른 점
2. **인터커넥트 확인** — `GV$CLUSTER_INTERCONNECTS`, 실제로 사설망을 쓰는지
3. 로그 수집 — `diagcollection.pl`, 무엇이 모이는가
4. **종합 점검 스크립트** — 이 과정의 지표를 한 번에 수집하고 판정
5. **장애 시나리오 종합 ⚠** — 노드 장애·디스크 장애·서비스 장애를 순서대로 겪고 복구
6. RAC + Data Guard 개요 — 두 기술의 조합, ADG 과정 참조 지점

---

## 장별 개수 요약

| 장 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 계 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 개수 | 6 | 7 | 7 | 7 | 7 | 7 | 6 | 7 | 6 | 6 | 7 | 7 | 6 | 7 | 7 | 6 | 7 | 7 | 5 | 6 | **132** |

## 최종실습시험 (6종 예정)

| # | 주제 | 대상 장 |
|---|---|---|
| 01 | 클러스터 구조와 설치 | 1~4 |
| 02 | OCR·Voting File 과 ASM 기초 | 5~7 |
| 03 | ASM 운영과 마이그레이션 | 8~10 |
| 04 | RAC 데이터베이스 관리 | 11~14 |
| 05 | 서비스와 부하 관리 | 15~16 |
| 06 | 백업·노드 관리·종합 운영 | 17~20 |
