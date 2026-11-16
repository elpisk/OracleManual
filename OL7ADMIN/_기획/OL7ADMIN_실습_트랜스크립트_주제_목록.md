# Oracle Linux 7.9 시스템 관리 교안 — 실습 트랜스크립트 주제 목록 (v1)

**작성일** 2026-11-11
**상위 문서** `OL7ADMIN_PRD.md` v2 (형식·분량은 PRD 9.2) · `OL7ADMIN_챕터_목록.md`
**상태** 20장 124개 주제 확정. 오류 흐름은 설계안이며 실측 결과에 따라 바꾼다.

---

## 0. 공통 규칙

- 파일명: `{N}장_실습_{NN}_{주제}.txt`. 아래 표의 "파일명 주제"를 그대로 쓴다.
- 분량: 20~30KB, 450~700줄, 단계 10~15개, 해설 주석 40% 이상(PRD 9.2).
- 필수 단계: `[0] 시작 전 상태 기록` → 본 단계 → `[변형]` → `[정리] 관찰 요약` → `[더 해 보기]`.
- 오류 흐름: 파일마다 2곳 이상, 증상·원인·조치·재확인 네 줄 형식. 아래 표의 오류 ①은 실습 주제와 직접 관련된 것, ②는 그 과정에서 흔히 마주치는 것이다.
- 오류 메시지는 실측 원문만 쓴다. 표에는 상황만 적고 메시지는 적지 않았다. 설계한 오류가 7.9 에서 재현되지 않으면 재현되지 않았다는 사실을 남기고 다른 오류로 바꾼다.
- 프롬프트: `[root@ol7a ~]#`, `[oracle@ol7a ~]$`, `[root@ol7b ~]#` 등. 일반 사용자는 `[user1@ol7a ~]$`.
- 표시
  - ★ `ol7b` 가 필요
  - ⚠ 시작 전 스냅샷 필요(괄호 안은 되돌릴 스냅샷)
  - 수업 ◎ 수업 시간에 진행 / ○ 자습·과제
- 되돌리기: 각 실습은 끝에서 시작 전 상태로 돌아가고, `[정리]` 표의 "되돌린 뒤" 열로 그것을 보인다. ⚠ 실습은 되돌리기 대신 스냅샷 복귀를 적어도 된다.

### 합계

| 장 | 개수 | 수업 ◎ | 장 | 개수 | 수업 ◎ |
|---|---:|---:|---|---:|---:|
| 1 | 4 | 3 | 11 | 6 | 4 |
| 2 | 5 | 2 | 12 | 5 | 3 |
| 3 | 7 | 4 | 13 | 7 | 4 |
| 4 | 6 | 3 | 14 | 6 | 3 |
| 5 | 7 | 4 | 15 | 6 | 3 |
| 6 | 5 | 3 | 16 | 7 | 3 |
| 7 | 5 | 3 | 17 | 8 | 5 |
| 8 | 6 | 3 | 18 | 7 | 4 |
| 9 | 7 | 5 | 19 | 6 | 4 |
| 10 | 8 | 5 | 20 | 6 | 4 |
| | | | **합계** | **124** | **72** |

---

## 1장. Oracle Linux 개요와 UEK (4개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | 배포판과커널식별 | `/etc/*release`, `rpm -q oraclelinux-release`, `uname -a` 의 각 필드, UEK 와 RHCK 를 이름으로 구분 | ① `/etc/redhat-release` 만 보고 RHEL 로 오판 → `oracle-release` 대조 / ② `uname -r` 로 "설치된 커널"을 확인하려다 실행 중 커널만 보임 | ◎ |
| 02 | 설치된커널과기본커널 | `rpm -q kernel kernel-uek`, `/boot` 의 파일 짝(vmlinuz·initramfs·config·System.map), `grubby --default-kernel` | ① `/boot` 에 initramfs 가 없는 커널 항목 발견 시 판단 / ② 일반 사용자로 `grubby` 실행 | ◎ |
| 03 | 릴리스노트대조 | RN79 의 Shipped Kernels·패키지 변경 항목을 시스템에서 확인(`rpm -q --changelog`, Oracle 이 바꾼 패키지의 `.0.1` 접미사) | ① 릴리스 노트의 커널 버전과 설치본이 다른 이유(설치 후 업데이트 여부) / ② `--changelog` 출력이 길어 원하는 항목을 못 찾음 → `head`·`grep` | ○ |
| 04 | 랩접속과프롬프트규칙 | ol7a·ol7b 접속, 호스트 이름·IP·계정 확인, 스냅샷 목록(호스트 쪽 `vmrun listSnapshots`), 기준 상태 기록 | ① 호스트 키 변경 경고(스냅샷 되돌린 뒤 재설치한 경우) → `known_hosts` 정리 / ② 다른 노드에서 명령을 친 실수 → 프롬프트로 구분 | ◎ |

## 2장. Oracle Linux 7.9 설치 (5개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | ISO확인과VM준비 | ISO 체크섬, `.treeinfo` 로 버전 확인, VM 하드웨어(디스크 5개·NIC 2개) 구성 | ① ISO 이름만으로 7.9 라 단정 → `.treeinfo` 의 실제 값 확인 / ② VM 메모리를 너무 적게 잡아 그래픽 설치가 텍스트 모드로 떨어짐 | ⚠ (없음 → `os-installed` 생성) ○ |
| 02 | Anaconda설치과정 | 설치 화면 단계별 캡처와 각 선택의 의미(언어·시간대·소프트웨어·디스크·Kdump·네트워크·보안 정책·root) | ① 디스크 자동 분할을 그대로 두면 `/home` 이 커지는 문제 → 수동 분할로 재지정 / ② 네트워크를 켜지 않고 설치해 부팅 후 `ONBOOT=no` | ⚠ ◎ |
| 03 | 설치결과확인 | `/root/anaconda-ks.cfg`, `/var/log/anaconda/`, 파티션·LV 구성, 설치된 패키지 그룹, 첫 부팅 서비스 | ① 설치 로그에서 경고 찾기 / ② `ONBOOT=no` 로 네트워크가 안 올라온 상태 진단과 수정 | ◎ |
| 04 | kickstart로ol7b설치 | `anaconda-ks.cfg` 를 고쳐 ol7b 용 kickstart 작성, `ksvalidator`, 웹 서버로 제공, `inst.ks=` 부트 옵션 | ① 호스트 이름·IP 를 안 바꿔 ol7a 와 충돌할 뻔한 것을 검증 단계에서 발견 / ② `inst.ks` URL 오타로 대화형 설치로 떨어짐 | ★ ⚠ ○ |
| 05 | 오류재현_잘못된kickstart | 지시어 오타·`%end` 누락·존재하지 않는 패키지가 각각 언제(검증·설치 중) 드러나는지 비교 | ① `%end` 누락 / ② 없는 패키지 이름 — 설치가 멈추는지 넘어가는지 | ★ ⚠ ○ |

## 3장. 부트 프로세스와 systemd (7개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | 부팅순서추적 | `systemd-analyze` (time·blame·critical-chain), `journalctl -b` 에서 단계별 메시지, `/proc/cmdline` | ① `blame` 상위 서비스를 병목으로 오판(병렬 기동) → `critical-chain` 으로 다시 판단 / ② 이전 부팅 로그가 없음(`-b -1`) → journald 비영구 저장 확인(19장 예고) | ◎ |
| 02 | 기본커널변경과복귀 | `grub2-set-default`, `grubby --set-default`, `GRUB_DEFAULT=saved`, RHCK 로 부팅 후 UEK 로 복귀 | ① `grub.cfg` 를 직접 고친 뒤 `grub2-mkconfig` 실행으로 사라짐 / ② 메뉴 항목 번호를 잘못 세서 엉뚱한 커널로 부팅 | ⚠ (`ol7-base`) ◎ |
| 03 | 부트파라미터적용 | GRUB 편집 화면에서 일회성 파라미터, `grubby --update-kernel --args`, `/etc/default/grub` + 재생성, 세 방법의 지속 범위 비교 | ① `/etc/default/grub` 만 고치고 재생성하지 않음 / ② `grubby` 로 한 커널에만 넣어 다른 커널로 부팅 시 빠짐 | ⚠ ◎ |
| 04 | 서비스시작과활성화 | `start` 와 `enable` 의 차이를 재부팅으로 확인, `is-enabled`·`is-active`, `mask` | ① enable 만 하고 start 하지 않아 지금은 안 돎 / ② mask 된 서비스를 start 하려다 실패 | ◎ |
| 05 | 타깃전환 | `get-default`·`set-default`, `isolate`, graphical ↔ multi-user, rescue 타깃 진입과 복귀 | ① 원격 세션에서 `isolate rescue.target` 으로 접속이 끊김 → 콘솔로 복구 / ② `set-default` 와 `isolate` 혼동 | ⚠ ○ |
| 06 | 서비스유닛작성 | 간단한 스크립트를 서비스로 등록, `Type`·`Restart`·`After`, drop-in 으로 설정 덮어쓰기, `daemon-reload` | ① `daemon-reload` 를 잊어 변경 미반영 / ② `Restart=always` 로 실패 루프 → `StartLimitBurst` 확인 | ○ |
| 07 | 오류재현_잘못된유닛파일 | 문법 오류·잘못된 경로·의존성 순환 유닛을 만들고 `systemd-analyze verify`, `status`, `journalctl -u` 로 각각 찾기 | ① `ExecStart` 상대 경로 / ② 존재하지 않는 `Requires=` | ○ |

## 4장. 시스템 구성 (6개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | chrony서버와클라이언트 | ol7a 를 시간 서버로, ol7b 를 클라이언트로. `chrony.conf`의 `server`·`allow`·`local stratum`, `chronyc sources -v`·`tracking` 열 해석 | ① `allow` 누락으로 ol7b 가 동기화 못 함 / ② 방화벽에 `ntp` 서비스 미개방 | ★ ◎ |
| 02 | ntpd전환과복귀 | chronyd 정지·비활성, ntpd 구성, `ntpq -p` 열 해석, 다시 chrony 로 | ① chronyd 와 ntpd 동시 활성 → 한쪽이 기동 실패 / ② ntpd 의 큰 시간 차이에서 동기화 거부(`-g` 의미) | ★ ○ |
| 03 | 시간어긋남재현과보정 | 시계를 일부러 수 분 틀어 놓고 chrony 의 점진 보정(slew)과 즉시 보정(`makestep`) 비교, 시간대 변경 | ① `date -s` 로 바꿨는데 곧바로 되돌아가는 이유 / ② 시간대만 바꾸고 RTC 설정(`timedatectl` 의 `RTC in local TZ`) 혼동 | ★ ◎ |
| 04 | proc로시스템읽기 | `/proc/cpuinfo`·`meminfo`·`loadavg`·`mounts`·`[pid]/status`·`fd`, `/proc/sys` 와 `sysctl -a` 의 대응 | ① `/proc/sys` 파일에 `echo` 로 쓴 값이 재부팅 뒤 사라짐 / ② 프로세스가 끝난 뒤 `/proc/[pid]` 접근 | ○ |
| 05 | sysctl영구설정과적용순서 | `sysctl -w`, `/etc/sysctl.d/*.conf`, `sysctl --system` 의 읽기 순서, 같은 키를 두 파일에 넣었을 때 이기는 쪽 | ① `/etc/sysctl.conf` 에 넣었는데 `sysctl.d` 의 다른 값이 이김 / ② `sysctl -p` 가 `sysctl.d` 를 읽지 않음 | ◎ |
| 06 | 오류재현_sysctl과sysfs | 없는 키, 범위 밖 값, 읽기 전용 키를 넣어 각각의 반응 확인. `/sys/block/sdb/queue/scheduler` 런타임 변경 | ① 없는 키 이름(오타) / ② 런타임에만 바꾼 sysfs 값이 재부팅 뒤 사라짐 → udev 규칙·tuned 로 영구화하는 방법 언급 | ○ |

## 5장. 패키지 관리 (7개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | rpm질의와검증 | `rpm -qa/-qi/-ql/-qf/-qc/-qd/-qR`, `rpm -V` 출력 여덟 문자 해석, 설정 파일을 바꾼 뒤 검증 | ① `rpm -V` 의 `c` 표시 파일을 손상으로 오판 / ② 파일 이름으로 `-qf` 를 칠 때 심볼릭 링크 | ◎ |
| 02 | 저장소구성확인 | `/etc/yum.repos.d/*.repo`, `yum repolist all`, `yum-config-manager --enable`, `oraclelinux-release-el7` 의 역할, `$releasever`·`$basearch` | ① `enabled=0` 저장소의 패키지가 안 보임 / ② GPG 키 미가져오기로 설치 거부 | ◎ |
| 03 | 설치와이력되돌리기 | 패키지 설치 → `yum history info` → `history undo`, 의존성으로 함께 들어온 패키지까지 되돌아가는지 | ① `undo` 할 때 이후에 다른 트랜잭션이 같은 패키지를 건드려 실패 / ② `yum remove` 가 의존 패키지를 함께 지우려는 것을 보고 중단 | ◎ |
| 04 | 오류재현_의존성충돌 | 의존성이 깨진 RPM 을 `rpm -ivh` 로 설치 시도 → `yum localinstall` 로 해소, `--nodeps` 의 결과 확인 후 정리 | ① `rpm -ivh` 의존성 실패 / ② `--nodeps` 로 설치한 뒤 `rpm -Va`·`yum check` 로 드러남 | ⚠ (`ol7-base`) ○ |
| 05 | 로컬ISO저장소 | ISO 루프 마운트, `.repo` 작성, `yum --disablerepo=* --enablerepo=local`, `createrepo` 로 직접 만든 저장소 | ① `baseurl` 에 `file://` 슬래시 개수 오류 / ② 메타데이터 캐시 때문에 새 패키지가 안 보임 → `yum clean` | ○ |
| 06 | 커널업데이트와보존개수 | UEK 업데이트, `installonly_limit` 와 오래된 커널 자동 제거, 업데이트 후 기본 부팅 커널, `package-cleanup --oldkernels` | ① 실행 중인 커널을 지우려는 시도가 거부됨 / ② 업데이트 후 기본 커널이 RHCK 로 바뀌었는지 확인(`DEFAULTKERNEL`) | ⚠ (`os-installed`) ◎ |
| 07 | 그룹과보안업데이트 | `yum group list/info/install`, `yum updateinfo list security`, `--security` 업데이트 범위, `yum-cron` 설정 파일 | ① 그룹의 mandatory·default·optional 차이를 몰라 원하는 패키지 누락 / ② `updateinfo` 가 비어 보임 → 저장소 메타데이터 | ○ |

## 6장. 작업 자동화 (5개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | 사용자crontab | `crontab -e/-l/-r`, 시간 필드 다섯 개, 매 분 실행으로 확인, `/var/spool/cron`, `/var/log/cron` | ① 스크립트가 터미널에선 되는데 cron 에선 실패(PATH·환경) / ② 출력이 메일로 가서 안 보임 → 리다이렉션 | ◎ |
| 02 | 시스템cron디렉터리 | `/etc/crontab`(사용자 필드), `/etc/cron.d`, `cron.hourly` 의 실행 주체, `run-parts` | ① `/etc/cron.d` 파일에 사용자 필드 누락 / ② `cron.daily` 에 넣은 스크립트가 실행 권한 없어 무시됨 | ◎ |
| 03 | anacron지연실행 | `/etc/anacrontab` 필드, `/var/spool/anacron` 타임스탬프, VM 을 꺼 둔 뒤 켜서 밀린 작업이 실행되는 것 관찰 | ① `START_HOURS_RANGE` 밖이라 실행 안 됨 / ② 타임스탬프 파일 때문에 "오늘 이미 실행" 판단 | ○ |
| 04 | at과batch | `at now + 1 minute`, `atq`·`atrm`, `batch` 와 부하 임계값(`atd -l`), 부하를 걸어 batch 가 미뤄지는 것 확인 | ① `atd` 미기동 / ② `at.deny` 에 있는 사용자 | ◎ |
| 05 | 오류재현_cron접근제어와타이머비교 | `cron.allow` 만들고 다른 사용자 거부 확인, 같은 작업을 systemd 타이머로 만들어 비교(`list-timers`) | ① `cron.allow` 를 만들자 root 외 모두 거부 / ② 타이머 유닛 이름과 서비스 유닛 이름 불일치 | ○ |

## 7장. 커널 모듈 구성 (5개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | 모듈조회 | `lsmod` 세 열, `modinfo` 필드(filename·depends·parm·vermagic), `/lib/modules/$(uname -r)` 구조, UEK 와 RHCK 의 모듈 경로 비교 | ① 다른 커널의 `.ko` 를 `modinfo` 로 봤을 때 vermagic 차이 / ② 내장(built-in) 모듈이 `lsmod` 에 안 나오는 이유 → `modules.builtin` | ◎ |
| 02 | 적재와해제 | `modprobe` 와 의존 모듈 동시 적재, `modprobe -r`, `insmod` 로 의존성 없이 적재 시도, `depmod` | ① `insmod` 가 의존 모듈 없어 실패 / ② 사용 중(`Used by`) 모듈 해제 거부 | ◎ |
| 03 | 모듈파라미터영구설정 | `/sys/module/<mod>/parameters`, `modprobe <mod> param=값`, `/etc/modprobe.d/*.conf` 의 `options`, 재적재로 확인 | ① 파라미터 이름 오타 → 적재 실패와 `dmesg` 메시지 / ② 이미 적재된 모듈엔 conf 가 적용 안 됨 | ◎ |
| 04 | 부팅시적재와블랙리스트 | `/etc/modules-load.d`, `blacklist` 와 `install ... /bin/false` 의 차이, initramfs 에 포함된 모듈(`lsinitrd`) | ① blacklist 했는데 다른 모듈의 의존성으로 적재됨 / ② initramfs 에 든 모듈이라 재생성(`dracut -f`) 전엔 계속 적재 | ⚠ ○ |
| 05 | 오류재현_커널별모듈차이 | UEK 와 RHCK 로 각각 부팅해 같은 모듈의 버전·존재 여부 비교, weak-updates 디렉터리 | ① RHCK 에만 있는(또는 UEK 에만 있는) 모듈 적재 실패 / ② weak-updates 링크가 가리키는 대상 | ⚠ ○ |

## 8장. 사용자와 그룹 관리 (6개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | 사용자생성과파일변화 | `useradd` 전후 `passwd`·`shadow`·`group`·`gshadow`·홈·메일 스풀 diff, 기본값(`useradd -D`, `login.defs`) | ① 이미 있는 UID 지정 / ② `-m` 없이 만들어 홈 디렉터리 없음(7.9 기본값 확인) | ◎ |
| 02 | 그룹과UPG와setgid | 보조 그룹, `newgrp`, UPG 와 umask 002, setgid 공유 디렉터리, 삭제 제한 비트 | ① 그룹에 추가했는데 현재 세션엔 반영 안 됨 / ② `usermod -G` 로 기존 보조 그룹이 날아감(`-a` 누락) | ◎ |
| 03 | 암호만료정책 | `chage -l` 필드, 만료·경고·비활성, `pwquality.conf` 로 강도 규칙, 해시 알고리즘(`authconfig --test`) | ① 강도 규칙 위반 암호 거부 / ② 만료된 계정 로그인 시 변경 강제 | ○ |
| 04 | sudo최소권한 | 특정 명령만 허용, 별칭, `NOPASSWD`, `sudo -l`, `/var/log/secure` 기록 | ① 허용하지 않은 명령 실행 기록 / ② 와일드카드로 허용 범위가 의도보다 넓어지는 예 | ◎ |
| 05 | 오류재현_sudoers문법 | `visudo` 가 문법 오류를 막는 과정, `visudo -c`, `sudoers.d` 파일 권한 | ① 문법 오류 저장 시도 / ② `sudoers.d` 파일 권한이 너무 넓어 무시됨 | ○ |
| 06 | 계정잠금과삭제 | `usermod -L`, `passwd -l`, `chage -E 0` 의 차이, `pam_faillock` 로그인 실패 잠금, `userdel -r` 과 남는 파일 찾기 | ① 잠근 계정이 SSH 키로는 들어와짐 / ② 삭제 뒤 남은 파일이 새 사용자 UID 를 물려받는 문제 | ○ |

## 9장. 파티션·파일 시스템·스왑 (7개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | 디스크확인과파티션생성 | `lsblk`·`blkid`·`by-id`, `fdisk` 로 MBR 파티션, `parted` 로 GPT, `partprobe` | ① 사용 중 디스크에서 파티션을 바꿔 커널이 새 테이블을 못 읽음 / ② MBR 주 파티션 네 개 한도 | ⚠ (`storage-clean`) ◎ |
| 02 | Ext4생성과튜닝 | `mkfs.ext4` 출력 해석, `dumpe2fs -h`, `tune2fs`(레이블·예약 블록·검사 주기) | ① 마운트된 장치에 `mkfs` 시도 / ② 예약 블록 5% 때문에 일반 사용자가 "공간 없음" | ◎ |
| 03 | fstab영구마운트 | 장치명·UUID·LABEL 세 방식, 여섯 필드, `mount -a` 로 검증, 옵션(`noatime`·`nofail`) | ① UUID 오타 → `mount -a` 실패 / ② 장치명으로 등록 후 디스크 순서가 바뀌는 상황 설명 | ⚠ ◎ |
| 04 | 오류재현_fstab오류와emergency | `fstab` 오류를 둔 채 재부팅 → emergency 모드 → `mount -o remount,rw /` → 수정 → 정상 부팅 | ① 없는 장치 항목으로 부팅 정지 / ② `nofail` 로 같은 상황이 부팅을 막지 않는 것 비교 | ⚠ (`pre-break`) ◎ |
| 05 | 파일시스템검사 | `fsck` 마운트 해제 후 실행, 강제 검사, 손상 흉내(`debugfs`) 후 복구 | ① 마운트된 상태에서 `fsck` 실행 경고 / ② `lost+found` 에 생긴 파일 해석 | ⚠ ○ |
| 06 | 스왑추가와제거 | 스왑 파티션과 스왑 파일, `mkswap`·`swapon -s`·`/proc/swaps`, 우선순위, `fstab` 반영과 제거 | ① 구멍 난 파일(`fallocate` 대신 `truncate`)로 만든 스왑 거부 / ② 사용 중 스왑 `swapoff` 시 메모리 부족 | ◎ |
| 07 | 파티션과Ext4확장 | 파티션 끝을 늘리고(`parted resizepart`) `resize2fs` 로 온라인 확장, 이미지 파일 루프 마운트 | ① 파티션만 늘리고 파일 시스템은 그대로 / ② 뒤에 다른 파티션이 있어 늘릴 수 없음 | ⚠ ○ |

## 10장. LVM 과 RAID (8개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | LVM구성 | PV·VG·LV 생성, `pvs`·`vgs`·`lvs` 와 `-v`·`display` 출력, PE 크기, 장치 매퍼 이름 | ① 파티션 테이블 흔적이 남은 디스크에 `pvcreate` 거부 / ② VG 에 남은 PE 보다 큰 LV 요청 | ⚠ (`storage-clean`) ◎ |
| 02 | 온라인확장 | 마운트된 XFS·Ext4 LV 를 `lvextend -r` 로 확장, VG 에 PV 추가 | ① `lvextend` 만 하고 파일 시스템은 그대로 / ② VG 공간 부족 → `vgextend` | ◎ |
| 03 | 축소와pvmove | Ext4 LV 축소(언마운트·검사·`resize2fs`·`lvreduce` 순서), XFS 는 축소 불가 확인, `pvmove` 로 디스크 비우기 | ① 순서를 틀린 축소로 파일 시스템 손상(스냅샷으로 복구) / ② XFS 축소 시도 | ⚠ ◎ |
| 04 | 메타데이터백업과복원 | `/etc/lvm/backup`·`archive` 읽기, LV 를 지운 뒤 `vgcfgrestore` 로 복원 | ① 복원 대상 아카이브를 잘못 고름 / ② 복원 후 LV 가 비활성 → `lvchange -ay` | ⚠ ○ |
| 05 | 스냅샷과병합 | COW 스냅샷 생성, 원본 변경 후 스냅샷 사용률, `lvconvert --merge` 로 되돌리기 | ① 스냅샷 크기 부족으로 무효화 / ② 마운트된 원본에 병합 → 다음 활성화 때 수행 | ⚠ ◎ |
| 06 | thin풀과초과할당 | thin pool, 풀보다 큰 thin LV, 데이터·메타데이터 사용률, 풀 고갈 상황 | ① 풀이 가득 차 쓰기 멈춤 / ② `thin_pool_autoextend_threshold` 로 자동 확장 | ⚠ ○ |
| 07 | snapper와thinLV | `snapper create-config`, 스냅샷 생성·비교(`status`·`diff`)·되돌리기(`undochange`) | ① thin LV 가 아닌 볼륨에 구성 시도 / ② 설정 파일의 `ALLOW_USERS` | ⚠ ○ |
| 08 | RAID5구성과재구축 | `mdadm --create` RAID 5, `/proc/mdstat`·`--detail`, 디스크 fail·remove·add, 재동기화 진행 관찰, `mdadm.conf` | ① `mdadm.conf` 없이 재부팅해 이름이 `md127` 로 바뀜 / ② 같은 디스크를 다시 넣을 때 기존 슈퍼블록 | ⚠ ◎ |

## 11장. XFS 파일 시스템 (6개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | XFS생성과정보 | `mkfs.xfs` 출력 각 줄(agcount·agsize·bsize·log), `xfs_info`, `xfs_admin` 레이블·UUID | ① 기존 파일 시스템이 있어 `-f` 요구 / ② LVM 스냅샷을 원본과 같이 마운트할 때 UUID 충돌 → `nouuid` | ⚠ (`storage-clean`) ◎ |
| 02 | 온라인확장과동결 | `xfs_growfs` 로 확장(마운트 지점을 인자로), `xfs_freeze` 중 쓰기 대기 관찰 | ① `xfs_growfs` 에 장치 이름을 넣음 / ② freeze 해제를 잊어 쓰기 멈춤 | ◎ |
| 03 | 사용자와프로젝트할당량 | `uquota`·`pquota` 마운트 옵션, `xfs_quota -x` 의 `limit`·`report`, `/etc/projects`·`projid` | ① 마운트 옵션 없이 할당량 설정 / ② 루트 파일 시스템은 `remount` 로 할당량을 켤 수 없음 → 부트 파라미터 | ◎ |
| 04 | 오류재현_할당량초과 | soft·hard 한도와 유예 기간, 초과 쓰기의 실패 시점, Ext4 의 `quota`·`edquota` 와 비교 | ① hard 한도 초과 쓰기 실패 / ② 유예 기간이 지난 뒤 soft 한도가 hard 처럼 동작 | ○ |
| 05 | xfsdump와xfsrestore | 레벨 0·1 덤프, 인벤토리(`xfsdump -I`), 전체·누적 복원, 대화형 복원 | ① 덤프 레이블 없이 실행해 대화형 질문에 멈춤 / ② 레벨 1 만으로 복원 시도 | ⚠ ○ |
| 06 | 손상복구 | 언마운트 상태 `xfs_repair -n`, 메타데이터 손상 흉내(`xfs_db`), 복구, `-L` 이 필요한 상황과 데이터 손실 | ① 마운트된 상태에서 `xfs_repair` / ② 더러운 로그가 있어 `-L` 요구 | ⚠ ◎ |

## 12장. Btrfs 파일 시스템 (5개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | Btrfs생성과장치관리 | 두 장치로 RAID1 Btrfs, `btrfs filesystem show/df/usage`, 장치 추가·제거·`balance` | ① `df` 와 `btrfs filesystem usage` 의 용량 차이 / ② 장치 제거 시 RAID1 최소 장치 수 위반 | ⚠ (`storage-clean`) ◎ |
| 02 | 서브볼륨과스냅샷 | 서브볼륨 생성·목록·기본 서브볼륨 변경, 읽기 전용 스냅샷, `subvol=` 마운트 | ① 서브볼륨이 아닌 디렉터리 스냅샷 시도 / ② 기본 서브볼륨을 바꾼 뒤 기존 마운트 결과가 달라짐 | ⚠ ◎ |
| 03 | 스냅샷되돌리기와sendreceive | 스냅샷으로 파일 되살리기, `send`·`receive` 전체·증분 전송 | ① 읽기 전용이 아닌 스냅샷을 `send` / ② 증분 전송의 부모 스냅샷이 받는 쪽에 없음 | ⚠ ○ |
| 04 | Ext4변환과되돌리기 | `btrfs-convert` 로 Ext4 변환, `ext2_saved` 서브볼륨, `-r` 로 되돌리기 | ① 마운트된 상태로 변환 시도 / ② `ext2_saved` 를 지운 뒤 되돌리기 불가 | ⚠ ○ |
| 05 | 오류재현_RHCK에서의Btrfs | RHCK 로 부팅해 Btrfs 를 마운트할 때의 동작과 지원 범위 확인, quota group | ① RHCK 에서의 결과(실측 후 확정) / ② qgroup 한도 초과 | ⚠ ◎ |

## 13장. 네트워크 구성 (7개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | 현재구성읽기 | `ip addr/link/route`, `nmcli device/connection` 표, `ifcfg-ens33` 각 키, `resolv.conf`·`nsswitch.conf`·`hosts` | ① `ifconfig` 가 없음(net-tools 미설치) → `ip` 대응표 / ② NetworkManager 가 `resolv.conf` 를 덮어씀 | ◎ |
| 02 | nmcli고정IP변경 | `nmcli connection modify`·`up`, ifcfg 파일이 어떻게 바뀌는지 diff, 보조 IP 추가 | ① 수정 후 `up` 하지 않아 미반영 / ② SSH 로 붙은 인터페이스를 바꿔 접속 끊김 → 콘솔 | ◎ |
| 03 | ifcfg직접편집과반영 | ifcfg 파일 편집 → `nmcli connection reload` vs `systemctl restart network`, `NM_CONTROLLED=no` 의 영향 | ① 편집 후 reload 하지 않음 / ② NM 과 network 서비스가 같은 장치를 서로 관리 | ○ |
| 04 | 본딩구성과장애전환 | 두 번째 NIC 로 active-backup 본딩, `/proc/net/bonding/bond0`, 링크 끊기로 전환 관찰 | ① 슬레이브 연결을 활성화하지 않아 본드에 장치 없음 / ② 본드 모드 이름 오타 | ⚠ ◎ |
| 05 | 오류재현_게이트웨이와이름해석 | 게이트웨이 누락·잘못된 DNS 로 각각 무엇이 안 되는지(ping IP 와 ping 이름), `ip route`·`getent hosts`·`dig` 로 구분 | ① 기본 경로 없음 / ② `nsswitch.conf` 의 `hosts` 순서 | ★ ◎ |
| 06 | ethtool과링크정보 | `ethtool` 속도·듀플렉스·드라이버(`-i`)·통계(`-S`)·오프로드(`-k`), 가상 NIC 의 한계 | ① 가상 NIC 에서 일부 값이 Unknown / ② 오프로드 설정 런타임 변경이 재부팅 후 사라짐 | ○ |
| 07 | 인터페이스이름규칙 | `ens33` 이름이 정해지는 과정, `biosdevname`·`net.ifnames=0` 효과, MAC 기준 고정 | ① 이름을 바꾼 뒤 ifcfg 파일 이름·`DEVICE` 불일치로 연결 안 됨 / ② VM 복제로 MAC 이 바뀐 경우 | ⚠ ○ |

## 14장. 파일 공유 (6개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | NFS서버와클라이언트 | ol7a 내보내기, ol7b 마운트, `exportfs -v` 옵션 해석, `showmount -e`, `nfsstat -m`, `fstab` 반영 | ① 방화벽 미개방(nfs·mountd·rpc-bind) / ② `exports` 수정 후 `exportfs -r` 누락 | ★ ◎ |
| 02 | 내보내기옵션비교 | `root_squash`·`no_root_squash`·`all_squash`, `ro`·`rw`, `sync`·`async`, 클라이언트 지정 방식 | ① root 로 쓰기가 거부되는 이유(`nfsnobody`) / ② 클라이언트 지정 공백 실수(`host (rw)`) | ★ ◎ |
| 03 | autofs자동마운트 | `auto.master`·간접 맵, 접근 시 마운트·유휴 시 해제(timeout) 관찰, 와일드카드 맵 | ① 맵 파일 문법 오류 / ② 마운트 지점 디렉터리를 직접 만들어 autofs 와 충돌 | ★ ○ |
| 04 | vsftpd구성 | 설치, `vsftpd.conf` 의 익명·로컬 사용자·chroot 지시어, `ftp` 클라이언트로 확인, 방화벽 | ① chroot 된 홈에 쓰기 권한이 있어 로그인 거부 / ② 수동 모드 포트 미개방 | ★ ○ |
| 05 | 오류재현_NFS권한과버전 | UID 불일치로 파일 소유자가 숫자로 보이는 문제, v3·v4 강제 마운트 비교, 서버 정지 중 `hard` 마운트 대기 | ① 클라이언트·서버 UID 불일치 / ② 서버 정지 시 `hard`·`soft` 동작 차이 | ★ ◎ |
| 06 | DB용NFS마운트옵션 | DB 설치 가이드의 NFS 옵션을 ol7b 에 적용하고 `nfsstat -m` 으로 실제 적용값 확인, RMAN 백업 대상 경로 준비 | ① 옵션 오타가 조용히 무시되는지 확인 / ② `oracle` 사용자 UID·GID 를 두 노드에서 맞추지 않음 | ★ ○ |

## 15장. OpenSSH (6개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | 접속과호스트키 | 첫 접속의 지문 확인, `known_hosts` 형식, `ssh-keyscan`, `ssh -v` 출력 단계 읽기 | ① 호스트 키 변경 경고 → 원인 확인 후 `ssh-keygen -R` / ② `StrictHostKeyChecking` 으로 비대화형 접속 실패 | ★ ◎ |
| 02 | 키생성과배포 | `ssh-keygen -t rsa/ecdsa`, 암호문, `ssh-copy-id`, `authorized_keys` 와 무암호 접속, `oracle` 사용자 간 동등성 | ① 개인 키 권한이 넓어 무시됨 / ② `ssh-copy-id` 없이 수동 복사하다 줄바꿈이 들어감 | ★ ◎ |
| 03 | 오류재현_authorized_keys권한 | 홈·`.ssh`·`authorized_keys` 권한을 하나씩 넓혀 키 인증이 언제 거부되는지, 서버 쪽 `/var/log/secure` 에서 원인 읽기 | ① `.ssh` 가 그룹 쓰기 가능 / ② 홈 디렉터리 권한 | ★ ◎ |
| 04 | sshagent와점프호스트 | `ssh-agent`·`ssh-add -l`, 에이전트 포워딩, ProxyJump, `~/.ssh/config` 호스트 블록 | ① 에이전트 소켓 변수 없는 셸 / ② config 파일 권한 오류 | ★ ○ |
| 05 | sshd구성강화 | `PermitRootLogin`·`PasswordAuthentication`·`AllowUsers`, `sshd -t` 로 검증, 재시작 전 세션 유지 | ① `sshd -t` 없이 재시작해 문법 오류로 sshd 기동 실패(콘솔 복구) / ② `AllowUsers` 에서 자기 계정을 빼 버림 | ★ ⚠ ○ |
| 06 | scp_sftp와포트포워딩 | `scp -r`·`sftp` 배치 모드, 로컬 포트 포워딩으로 ol7b 의 서비스 접근, 원격 포워딩 | ① 이미 쓰는 로컬 포트로 포워딩 / ② `AllowTcpForwarding no` 서버 | ★ ○ |

## 16장. 보안 관리 (7개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | chrootjail구성 | 최소 jail 디렉터리 구성(`ldd` 로 라이브러리 복사), `chroot` 로 셸 실행, jail 밖이 안 보이는 것 확인 | ① 라이브러리 누락으로 셸 실행 실패 / ② `/dev` 장치 파일 없어 명령 실패 | ○ |
| 02 | firewalld영역과서비스 | `--get-active-zones`, `--list-all` 출력 해석, 서비스·포트 추가, runtime 과 permanent | ① `--permanent` 만 쓰고 reload 안 함 / ② runtime 에만 넣고 reload 해서 사라짐 | ★ ◎ |
| 03 | richrule과출발지제한 | 출발지 IP 별 허용·거부, 로그 남기기, 인터페이스·출발지로 영역 지정 | ① 규칙 순서·우선순위 오해로 거부가 안 됨 / ② 출발지를 다른 영역에 넣어 기존 규칙 미적용 | ★ ◎ |
| 04 | iptables전환과원복 | firewalld 정지·mask, `iptables-services` 설치, 규칙 조회·삽입·삭제·저장, firewalld 로 복귀 | ① 두 서비스를 동시에 켬 / ② `service iptables save` 없이 재시작해 규칙 소실 | ★ ⚠ ○ |
| 05 | TCPWrappers | `libwrap` 링크 여부 확인(`ldd`), `hosts.allow`·`hosts.deny` 로 sshd·vsftpd 제한, 평가 순서 | ① libwrap 을 쓰지 않는 서비스에 규칙을 넣고 효과 없음 / ② `hosts.deny` 에 ALL 을 넣어 자신까지 차단 | ★ ○ |
| 06 | 리스너포트개방 | 1521 포트 개방과 `ss -ltn`, ol7b 에서 `nc`·`telnet` 으로 확인, 서비스 정의 파일 만들기 | ① 포트는 열렸는데 리스너가 없음(연결 거부와 타임아웃 구분) / ② 다른 영역에 열어 적용 안 됨 | ★ ◎ |
| 07 | 오류재현_기본보안조치 | 코어 덤프 비활성화(`limits`·`sysctl`), `/tmp` 에 `noexec` 마운트, 불필요 서비스 목록 정리 | ① `noexec` 로 설치 스크립트 실행 실패 / ② 코어 덤프 설정이 systemd 서비스에는 적용 안 됨 | ⚠ ○ |

## 17장. Oracle on Oracle: DB 서버 준비 (8개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | preinstall전후비교 | 설치 전 상태 저장 → `oracle-database-preinstall-19c` → sysctl·limits·사용자·그룹·부트 파라미터 diff | ① 저장소가 비활성이라 패키지 없음 / ② 설치 후 값이 바로 적용됐는지(재부팅 필요 항목) 확인 | ⚠ (`ol7-base`) ◎ |
| 02 | 수동설정_사용자와커널파라미터 | ol7b 에서 preinstall 없이 사용자·그룹·sysctl 을 손수 설정해 ol7a 와 같게 만들기, 공유 메모리 값 계산 근거 | ① `shmall` 단위(페이지)를 바이트로 착각 / ② GID 를 두 노드에서 다르게 만듦 | ★ ⚠ ◎ |
| 03 | 셸한도확인 | `limits.d` 파일, `ulimit -a` soft·hard, `su -` 와 `su` 의 차이, SSH 로그인과 systemd 서비스의 한도 차이 | ① `su` (하이픈 없음)로 전환해 한도 미적용 / ② systemd 서비스로 기동한 프로세스엔 `limits.conf` 미적용 | ◎ |
| 04 | HugePages계산과적용 | SGA 크기로 페이지 수 계산, `vm.nr_hugepages`, `/proc/meminfo` 의 HugePages 줄 해석, `memlock` | ① 메모리 단편화로 요청한 만큼 확보 안 됨 → 부팅 시 확보 / ② `memlock` 한도 부족 | ⚠ ◎ |
| 05 | THP비활성화 | `/sys/kernel/mm/transparent_hugepage/enabled`·`defrag`, 부트 파라미터로 영구화, 재부팅 후 확인 | ① sysfs 에만 써서 재부팅 후 복귀 / ② `grubby` 로 한 커널에만 넣음 | ⚠ ○ |
| 06 | RemoveIPC와공유메모리 | `logind.conf` 의 `RemoveIPC`, 사용자 로그아웃 시 IPC 자원 삭제 재현(`ipcmk`·`ipcs`) | ① `RemoveIPC=yes` 상태에서 일반 사용자 세그먼트가 사라짐 / ② 설정 변경 후 `systemd-logind` 재시작 누락 | ○ |
| 07 | udev규칙으로디스크고정 | `scsi_id` 로 디스크 식별자, 규칙 작성(이름·소유자·권한), `udevadm test`·`trigger`, 재부팅 후 유지 | ① VMware 에서 `disk.EnableUUID` 없어 `scsi_id` 가 비어 있음 / ② 규칙 문법 오류(`==` 와 `=`) | ⚠ ◎ |
| 08 | ASMLib디스크표시와비교 | `oracleasm` 설치·구성·`createdisk`·`listdisks`·`scandisks`, udev 방식과 장단점 비교, `D:\OEL7V9` 의 실제 설정 대조(조회만) | ① 커널 드라이버와 지원 패키지 구성 불일치 / ② 파티션 없이 디스크 전체를 지정 | ⚠ ○ |

## 18장. 시스템 모니터링 (7개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | CPU부하와지목 | 셸 루프로 CPU 부하, `top` 헤더 다섯 줄·`%CPU` 열, `mpstat -P ALL`, `vmstat` 의 `r`·`us`·`sy`·`id`·`wa` | ① 부하 평균을 CPU 사용률로 오해 / ② `top` 의 `%CPU` 가 100 을 넘는 이유(다중 CPU) | ◎ |
| 02 | 메모리압박과스왑 | 메모리 소비 프로그램으로 압박, `free` 의 `available`, `/proc/meminfo`, `vmstat` 의 `si`·`so`, OOM 킬러 기록 | ① `free` 의 `free` 열만 보고 메모리 부족 판단 / ② OOM 킬러가 다른 프로세스를 죽임 → `dmesg` | ⚠ ◎ |
| 03 | IO부하와iostat | `dd` 로 쓰기·읽기 부하, `iostat -x` 열(r/s·w/s·await·%util), `iotop` 으로 프로세스 지목 | ① 캐시 때문에 읽기 부하가 안 보임 → `oflag=direct`·캐시 비우기 / ② `%util` 100% 를 디스크 한계로 단정 | ◎ |
| 04 | sar이력재구성 | sysstat 수집 주기(`sysstat` cron), `/var/log/sa`, `sar -u/-r/-b/-n DEV`, 특정 시간대 지정 | ① sysstat 이 설치만 되고 수집 안 됨 / ② 날짜 파일을 잘못 지정 | ◎ |
| 05 | strace로프로세스추적 | 실행 중 프로세스에 `strace -p`, `-c` 요약, `-e trace=file`, 멈춘 프로세스가 무엇을 기다리는지 | ① 다른 사용자 프로세스에 붙기 거부 / ② 출력 폭주 → 필터와 `-o` | ○ |
| 06 | 네트워크와tcpdump | `ss -tanp`·`netstat -s`, ol7a ↔ ol7b 통신을 `tcpdump` 로 캡처(포트·호스트 필터), 3-way handshake 읽기 | ① 인터페이스를 지정하지 않아 엉뚱한 장치 캡처 / ② 이름 해석 때문에 출력이 느림 → `-n` | ★ ○ |
| 07 | sosreport와OSWatcher | `sosreport` 생성·압축 해제·구조, OSWatcher 설치·실행·보관 파일(4.4 조회 결과에 따라 범위 확정) | ① `/var/tmp` 공간 부족 / ② OSWatcher 보관 주기·용량 설정 | ○ |

## 19장. 시스템 로깅 (6개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | 로그흐름추적 | `logger` 로 메시지를 남겨 journal → rsyslog → `/var/log/messages` 경로 확인, facility·priority 지정 | ① `authpriv` 메시지가 `messages` 에 없는 이유 / ② rsyslog 정지 시 journal 에만 남음 | ◎ |
| 02 | 셀렉터로로그분리 | `rsyslog.d` 에 규칙 추가해 특정 facility 를 별도 파일로, `stop`·`~` 로 중복 방지 | ① 새 규칙을 넣었는데 `messages` 에도 계속 기록 / ② 파일 경로 권한 | ◎ |
| 03 | 원격로그전송 | ol7b 를 수신 서버(`imtcp`·`imudp`)로, ol7a 에서 전송(`@@`·`@`), 방화벽, 수신 쪽 확인 | ① 수신 포트 미개방 / ② 수신 서버 정지 중 메시지 유실(큐 설정 언급) | ★ ◎ |
| 04 | 템플릿으로호스트별파일 | 템플릿 정의로 `/var/log/remote/<host>/` 아래 저장, 형식 템플릿 | ① 템플릿 이름 오타 / ② 디렉터리 자동 생성 옵션 | ★ ○ |
| 05 | journald영구저장 | `/var/log/journal` 생성 또는 `Storage=persistent`, `journalctl --list-boots`, `-b -1`, 용량 한도(`SystemMaxUse`), `--vacuum-size` | ① 디렉터리만 만들고 권한·재시작 누락 / ② 용량 한도 초과로 오래된 로그 삭제 확인 | ⚠ ○ |
| 06 | 오류재현_rsyslog설정오류와logrotate | 설정 문법 오류를 `rsyslogd -N1` 로 찾기, 새 로그 파일에 `logrotate` 규칙 추가와 `-d`·`-f` 시험 | ① 문법 오류로 일부 규칙 무시 / ② 회전 후 rsyslog 가 옛 파일에 계속 기록(`postrotate` 누락) | ◎ |

## 20장. 문제 해결 (6개)

| # | 파일명 주제 | 목표 | 오류 ① / ② | 표시 |
|---|---|---|---|---|
| 01 | root암호분실복구 | `rd.break` 로 initramfs 셸 진입, `/sysroot` 재마운트·`chroot`·암호 변경, `.autorelabel` 의 의미(SELinux 를 끄지 않은 기본 상태라 필요) | ① `/sysroot` 를 읽기 전용인 채로 `passwd` / ② `.autorelabel` 누락 시 로그인 실패 | ⚠ (`pre-break`) ◎ |
| 02 | 부팅장애_fstab과타깃 | 손상된 `fstab`, 기본 타깃을 없는 타깃으로 바꾼 상태에서 각각 어디서 멈추는지 구분하고 복구 | ① emergency 와 rescue 의 차이 / ② 루트가 읽기 전용이라 수정 불가 → remount | ⚠ ◎ |
| 03 | GRUB손상과rescue모드 | `grub.cfg` 손상·`/boot` 파일 이름 변경 상태에서 GRUB 셸로 수동 부팅, 설치 ISO rescue 모드로 `grub2-mkconfig` 재생성 | ① GRUB 셸에서 `linux`·`initrd` 경로 오류 / ② rescue 모드에서 `chroot /mnt/sysimage` 를 빠뜨림 | ⚠ ◎ |
| 04 | NFS장애세가지구분 | 서버 서비스 정지·내보내기 권한 제거·방화벽 차단을 하나씩 걸고, 클라이언트 증상과 확인 명령으로 원인 구분 | ① 세 장애의 클라이언트 증상이 비슷해 보이는 것 / ② `hard` 마운트가 걸린 채 `umount` 안 됨 → `-f`·`-l` | ★ ◎ |
| 05 | dmesg로디스크오류읽기 | 실습 디스크를 VM 에서 떼어 내거나 I/O 오류를 흉내 내 `dmesg -T` 메시지, `journalctl -k`, 파일 시스템 반응 읽기 | ① 오류 메시지의 장치 이름과 마운트 지점 연결 / ② 읽기 전용으로 재마운트된 파일 시스템 | ⚠ ○ |
| 06 | 종합진단_정보수집 | 증상 하나("서버가 느리고 일부 마운트가 안 됨")를 받아 두 단계 접근으로 정보 수집 → `sosreport` → 원인 좁히기 → 보고서 형식으로 정리 | ① 첫 가설이 틀린 경우 되돌아가는 과정 / ② 조치 전 근거를 남기지 않은 경우의 문제 | ⚠ ○ |

---

## 부록. 실측 순서

장 번호 순서와 실측 순서를 다르게 잡는다. VM 상태가 앞 실습의 결과에 의존하는 것끼리 묶는다.

| 순서 | 실측 묶음 | 시작 스냅샷 |
|---|---|---|
| 1 | 2장 01~03 (ol7a 설치) | 빈 VM |
| 2 | 2장 04·05 (ol7b kickstart) | 빈 VM |
| 3 | 1장 전체, 5장 06 (업데이트 전 상태 필요) | `os-installed` |
| 4 | 업데이트·사용자·기준 설정 후 `ol7-base`, `storage-clean`, `pre-break` 생성 | — |
| 5 | 3·4·5·6·7·8장 | `ol7-base` |
| 6 | 9·10·11·12장 | `storage-clean` |
| 7 | 13·14·15·16장 | `ol7-base` |
| 8 | 17장 | `ol7-base` |
| 9 | 18·19장 | `ol7-base` |
| 10 | 20장 | `pre-break` |

`os-installed` 이후 `yum update` 를 하면 커널이 바뀐다. 1장과 5장 06 을 업데이트 전에 먼저 실측하는 이유다. PRD 4.5 의 버전 표는 3번 묶음에서 채운다.
