# Oracle Linux 7.9 시스템 관리 과정

## PRD (Product Requirements Document) — v2

**작성일** 2026-11-11 · **과정 코드명** OL7ADMIN · **저장소** `elpisk/OracleManual/OL7ADMIN`
**목차 기준** Oracle University *Oracle Linux 7: System Administration Ed 2* (D88168GC20, 5일)
**내용 근거** Oracle Linux 7 문서 라이브러리 `https://docs.oracle.com/en/operating-systems/oracle-linux/7/`
**동반 문서(작성 예정)** `OL7ADMIN_챕터_목록.md` · `OL7ADMIN_실습_트랜스크립트_주제_목록.md` · `OL7ADMIN_과정구성_5일.md`

### 개정 이력

| 판 | 날짜 | 내용 |
|---|---|---|
| v1 | 2026-11-11 | 초안. 착수 전 결정 사항 6개를 남김 |
| v2 | 2026-11-11 | 결정 반영 — VM 두 대 신규, 설치 ISO `Downloads\OEL7V9.iso`, Ksplice 장·SELinux 제외, 문제 4종 포함, 20장 확정. Ksplice 장이 빠진 자리는 모니터링과 로깅을 두 장으로 나눠 채움. 트랜스크립트 규격을 기존 과정보다 크게 보강(9.2) |

---

# 1. 제품 비전

## 1.1 제품명

Oracle Linux 7.9 시스템 관리 과정

## 1.2 무엇을 만드는가

- D88168GC20 의 22개 단원 목차를 뼈대로 하고, 내용은 OL7 공식 문서에서 7.9 기준으로 다시 확인해 쓴 한글 교안.
- 산출물은 저장소의 RAC 20장과 같은 일곱 종류: 장별 본문 docx, 강의 pptx, 실습문제·정답, 추가서술형·정답, 실측 세션 트랜스크립트. 과정 끝에 최종실습시험 5세트.
- 목차만 OU 과정에서 가져온다. `D88168GC20_14_US.pdf` 는 4쪽짜리 과정 소개서라 본문이 없다. 문장·예제·수치는 공식 문서와 실습 VM 실측에서 나온다.

## 1.3 이 과정이 노리는 사람

- Oracle DB 를 올릴 리눅스 서버를 직접 준비하고, 장애가 나면 OS 쪽부터 확인할 수 있는 DBA.
- 저장소의 RAC·ADG 과정이 모두 OL 7.9 위에서 돌아간다. 그 랩을 만들며 반복해서 쓴 OS 작업(udev, 커널 파라미터, HugePages, chrony, firewalld, NFS)이 이 과정의 실습 소재가 된다.

경계할 것 세 가지.

1. 7 과 8/9 의 혼동 — `linux_guide`(OL 8/9 기초)와 명령이 겹치지만 동작이 다른 곳이 많다. `ntpd`·TCP Wrappers·Btrfs·`network-scripts` 는 7 에는 있고 8 에서 빠지거나 폐기됐다. 7.9 에서 실측한 결과만 쓴다.
2. 클라우드 단원의 공허함 — OU 목차의 OCI 항목은 랩에서 재현할 수 없다. 개념 수준으로 줄이고 실습을 만들지 않는다(4.3).
3. 구독이 필요한 기능 — ULN 은 Oracle Linux Support 구독이 있어야 등록된다. 공개 저장소 `yum.oracle.com` 으로 실습하고 ULN 은 개념으로 다룬다(4.4).

---

# 2. 교육 대상

## 2.1 주 대상 — Oracle DB 운영 DBA

사전 지식(OU 과정의 Required Prerequisites 와 같음)

- 파일·디렉터리 다루기, `tar`·`gzip` 으로 묶고 풀기
- `vi` 편집, 프로세스 확인과 종료
- 원격 접속(`ssh`)과 파일 전송
- 셸 기본 기능과 간단한 셸 스크립트

이 수준은 저장소의 `linux_guide`(OL 8/9 기초 13장)가 다룬다. 그 교안은 8/9 기준이라 선수 과정으로 지정하지는 않는다. 1장 도입부에 "기초 명령은 다루지 않는다"는 범위만 밝힌다.

## 2.2 부 대상 — 리눅스 서버 운영자

DB 를 다루지 않는 운영자도 17장(Oracle on Oracle)을 빼면 완결되게 쓴다. 17장은 앞 장의 지식(사용자·커널 파라미터·스토리지)을 DB 설치 준비로 묶는 장이다.

---

# 3. 최종 교육 목표

## Level 1. 설치와 부팅
- OL 7.9 를 Anaconda 로 설치하고 kickstart 로 같은 설치를 재현한다
- GRUB 2 → 커널 → initramfs → systemd 순서로 부팅을 설명하고, 부트 파라미터와 기본 타깃을 바꾼다
- 부팅이 멈춘 시스템을 rescue/emergency 모드로 살린다

## Level 2. 커널과 소프트웨어
- UEK R6 와 RHCK 를 구분하고 기본 부팅 커널을 바꾼다
- `rpm`·`yum` 으로 패키지를 설치·검증·되돌리고 저장소를 구성한다
- 커널 모듈을 올리고 내리며 모듈 파라미터를 영구 설정한다

## Level 3. 사용자와 작업
- 사용자·그룹·암호 정책을 구성하고 `sudo` 권한을 최소로 준다
- `cron`·`anacron`·`at` 중 상황에 맞는 것을 골라 작업을 예약한다

## Level 4. 스토리지
- 파티션·Ext4·XFS·Btrfs·스왑을 만들고 `/etc/fstab` 으로 영구 마운트한다
- LVM 으로 볼륨을 늘리고 줄이며, thin provisioning·스냅샷·RAID 를 구성한다
- XFS 할당량과 덤프/복원을 수행한다

## Level 5. 네트워크와 공유
- NetworkManager(`nmcli`)와 ifcfg 파일로 인터페이스를 구성한다
- NFS 서버·클라이언트, autofs, vsftpd 를 구성한다
- OpenSSH 키 인증과 `ssh-agent` 를 구성한다

## Level 6. 보안
- firewalld 영역·서비스·포트 규칙과 iptables 규칙을 구성하고 둘의 관계를 설명한다
- chroot jail, TCP Wrappers 로 서비스 접근을 제한한다

## Level 7. DB 서버 준비
- `oracle-database-preinstall-19c` 가 바꾸는 항목을 전후 비교로 확인한다
- 공유 메모리·세마포어·파일 핸들·AIO 커널 파라미터와 셸 한도를 근거와 함께 설정한다
- HugePages 를 계산해 설정하고 Transparent HugePages 를 끈다

## Level 8. 모니터링·로깅·문제 해결
- `sar`·`vmstat`·`iostat`·`top` 등으로 병목 자원을 지목한다
- rsyslog·journald 로 로그를 모으고 보존 정책을 정한다
- `sosreport` 를 만들고, 부팅·NFS 장애를 절차대로 좁혀 들어간다

---

# 4. 교육 환경

## 4.1 실습 VM (확정)

| 항목 | `ol7a` (주 실습) | `ol7b` (상대편) |
|---|---|---|
| 용도 | 거의 모든 실습 | NFS·SSH·chrony·firewalld·rsyslog 원격 수신의 상대 노드 |
| IP (VMnet8 NAT) | `172.16.225.61` | `172.16.225.62` |
| 메모리 / CPU | 4GB / 2 vCPU | 2GB / 1 vCPU |
| OS 디스크 | 40GB | 30GB |
| 실습용 추가 디스크 | 10GB × 4 (`sdb`~`sde`) | — |
| 추가 NIC | 1개 (13장 본딩용, VMnet8) | — |
| OS | Oracle Linux 7.9 x86_64, 기본 커널 UEK R6 | 같음 |
| 위치 | `D:\OL7LAB\ol7a` | `D:\OL7LAB\ol7b` |
| 설치 매체 | `C:\Users\itwill\Downloads\OEL7V9.iso` (4.86GB) | 같음 |

- 추가 디스크 4개는 9~12장(파티션·LVM·RAID·XFS·Btrfs)이 나눠 쓴다. RAID 5 와 LVM 미러를 한 장 안에서 만들려면 최소 4개가 필요하다.
- IP 는 기존 랩과 겹치지 않게 골랐다. 현재 쓰는 주소는 `.50`(OEL7V9), `.101/.102/.111/.112/.120`(RACSVR)이다.
- `D:\OEL7V9` 는 DB 패치 가이드의 기준 서버라 실습에 쓰지 않는다. 17장에서 "19c 가 이미 올라간 서버의 OS 설정"을 대조 자료로 조회만 한다.
- 2장(설치) 실측은 빈 VM 에 ISO 로 처음부터 설치하며 캡처한다. 그 결과가 곧 `ol7a` 다. `ol7b` 는 `ol7a` 의 `anaconda-ks.cfg` 를 고쳐 kickstart 로 설치한다(2장 실습 소재).
- ISO 가 7.9 인지 착수 단계에서 `.treeinfo`·`isolinux/isolinux.cfg` 로 먼저 확인한다. 파일 이름만으로는 버전을 단정하지 않는다.

## 4.2 스냅샷 계획

| 스냅샷 | 시점 | 되돌리는 장 |
|---|---|---|
| `os-installed` | 2장 설치 직후, 업데이트 전 | 5장(패키지) 재실측 |
| `ol7-base` | 기준 상태 — 사용자, `ol7b` 와 통신 확인, 실측 기준 커널 고정 | 대부분의 장 |
| `storage-clean` | 추가 디스크 4개가 비어 있는 상태 | 9~12장 |
| `pre-break` | 장애 재현 직전 | 3·9·20장 부팅 장애 실습 |

스냅샷은 전원을 끈 상태로 뜬다(ADG·RAC 과정과 같은 규칙). 실측 중에는 RACSVR·OEL7V9 를 정상 종료해 둔다. suspend 는 쓰지 않는다.

## 4.3 랩에서 재현할 수 없는 것

| OU 목차 항목 | 처리 |
|---|---|
| Oracle Cloud Computing 단원 전체(IaaS, Private Cloud Appliance, OpenStack, OCI 개념·인스턴스·VCN·블록 볼륨) | 1장의 한 절로 줄여 개념만. 실습 없음 |
| Launching an OCI Instance(설치 단원) | 2장에 짧은 비교 상자 하나 |
| Networking in OCI, Key Pairs for OCI Instances | 해당 장에 Note 상자로만 |
| Oracle OpenStack | 제외. 문서 라이브러리에서도 Archived 다 |
| Spacewalk | 18장에서 개요만. 후속 제품인 Oracle Linux Manager 로 이어진다는 사실만 언급 |

## 4.4 이 과정에서 뺀 것

| 항목 | 결정 | 남기는 흔적 |
|---|---|---|
| Oracle Ksplice 단원 | 제외(v2 결정 3) | 5장 커널 업데이트 절에 "재부팅 없는 커널 패치 제품이 있다"는 Note 한 상자. 명령·구성은 다루지 않는다 |
| SELinux | 제외(v2 결정 4) | 없음. 실습 VM 은 설치 기본값(enforcing)을 그대로 두고, 실습이 SELinux 때문에 막히면 그 사실을 트랜스크립트 주석으로 남긴 뒤 원인만 짚는다 |
| ULN 실제 등록 | 구독 없음 | 5장에서 채널 개념과 등록 절차를 문서 기준으로 서술. 실습은 `yum.oracle.com` |
| OSWatcher | 1장 착수 전 `yum.oracle.com` 에 패키지가 있는지 조회 | 없으면 18장에서 `sar` 중심으로 대체하고 OSWatcher 는 개요만 |

수치·출력이 없는 실습은 만들지 않는다. 실측할 수 없는 항목은 트랜스크립트 대신 본문 Note 로 처리한다.

## 4.5 7.9 기준으로 고정하는 값

교안 전체가 같은 버전을 말하도록 착수 단계에서 실측해 채운다.

| 항목 | 예상값(문서 기준) | 실측값 |
|---|---|---|
| 배포판 | `Oracle Linux Server release 7.9` | 설치 매체 `.treeinfo`: `Oracle Linux 7.9`, Server, x86_64, timestamp 1622221243(2021-05-28 재빌드판) |
| UEK | UEK R6 `5.4.17-2011.*.el7uek` | 설치 매체 `5.4.17-2102.201.3.el7uek` → `ol7-base`(yum update 후) `5.4.17-2136.338.4.2.el7uek` |
| RHCK | `3.10.0-1160.*.el7` | 설치 매체 `3.10.0-1160.el7` → `ol7-base` `3.10.0-1160.119.1.0.5.el7` |
| 기본 파일 시스템 | XFS | XFS (`/dev/mapper/ol-root` 36G, `/boot` 1014M), autopart LVM, VG 이름 `ol`(ol7b 는 kickstart 설치라 `ol_ol7b`) |
| 시간 동기화 | chrony | chrony-3.4. 설치 시 Network Time OFF 라 `services --disabled="chronyd"` → `ol7-base` 에서 활성화 |
| 방화벽 | firewalld | firewalld-0.6.3, 활성 |
| 네트워크 이름 | 예측 가능한 이름(VMware 에서 `ens33` 등) | e1000 NIC 가 `ens32`·`ens33` 으로 잡힘 |

- 랩 설정으로 부트 파라미터에 `console=tty0 console=ttyS0,115200 scsi_mod.scan=sync` 를 넣었다(직렬 콘솔 캡처, UEK 비동기 SCSI 스캔으로 OS 디스크가 `sdb` 로 잡힌 실측 사례 때문에 장치 순서 고정). 상세는 `_ol7_scratch\BASE_FACTS.md`.
- `yum update` 를 하면 커널 버전이 바뀐다. 실측은 `ol7-base` 스냅샷에서만 하고, 교안의 버전 문자열은 그 스냅샷 값만 쓴다.
- OL7 은 2025-01 부터 Extended Support 다. 1장에 지원 단계와 OL8/9 이전 권고를 한 문단 넣는다.

---

# 5. 근거 문서

| 약어 | 문서 | 경로(`docs.oracle.com/en/operating-systems/oracle-linux/...`) | 주로 쓰는 장 |
|---|---|---|---|
| RN79 | Release Notes for Oracle Linux 7.9 | `7/relnotes7.9/` | 1·2, 7.9 고유 사항 전반 |
| INS | Installation Guide | `7/install/` | 2 |
| ADM | Administrator's Guide | `7/admin/` | 3·4·6·7·8·18·19·20 |
| OSM | Managing Core System Configuration | `7/osmanage/` | 3·4·6·7 |
| YUM | Managing Software | `7/yum/` | 5 |
| ULN | Unbreakable Linux Network User's Guide for OL 6 and 7 | `uln-user/` | 5 |
| UAU | Setting Up System Accounts and Authentication | `7/userauth/` | 8 |
| FS | Managing File Systems | `7/fsadmin/` | 9·11·12·14 |
| STO | Managing Storage and Storage Devices | `7/stordev/` | 9·10 |
| NET | Setting Up Networking | `7/network/` | 13 |
| SSH | Connecting to Remote Systems With OpenSSH | `openssh/` | 15 |
| SEC | Security Guide | `7/security/` | 16 |
| ASML | Installing and Configuring Oracle ASMLIB v2 | `7/asmlib/` | 17 |
| MON | Monitoring and Tuning the System | `7/monitoring/` | 18·20 |
| UEK | Unbreakable Enterprise Kernel Documentation (R6 릴리스 노트) | `/en/operating-systems/uek` | 1·7 |
| DBI | Oracle Database 19c Installation Guide for Linux | DB 문서 | 17 (커널 파라미터·한도 권고값) |

- 공식 문서 PDF 는 저장소에 커밋하지 않는다(RAC·Tuning 과정과 같은 취급). 받아 두는 위치는 `Downloads\OL7\`.
- 문서 간에 값이 다르면 RN79 → 해당 주제 문서 → ADM 순으로 우선한다. 그래도 애매하면 `ol7a` 실측값을 쓰고 본문에 출처를 밝힌다.

---

# 6. 전체 교육과정 (5일, 40시간)

OU 과정과 같은 5일 구성이다. 하루 8시간, 강의 40 : 실습 60. 일차 구분은 이 문서와 과정 구성 문서에만 두고 교안에는 장 번호만 쓴다(RAC 5일 과정과 같은 방식).

| Day | 장 | 주제 | 시수 |
|---|---|---|---:|
| 1 | 1~4 | 개요, 설치, 부팅·systemd, 시스템 구성 | 8h |
| 2 | 5~9 | 패키지, 작업 자동화, 커널 모듈, 사용자·그룹, 파티션·파일 시스템 | 8h |
| 3 | 10~13 | LVM·RAID, XFS, Btrfs, 네트워크 | 8h |
| 4 | 14~17 | 파일 공유, OpenSSH, 보안, Oracle on Oracle | 8h |
| 5 | 18~20 + 평가 | 모니터링, 로깅, 문제 해결, 최종실습시험 | 8h |

- 트랜스크립트가 길어진 만큼(9.2) 수업 시간에 모든 실습을 돌리지는 않는다. 장마다 수업용 실습과 자습용 실습을 과정 구성 문서에서 나눈다.
- 장별 시수와 시간표는 챕터 목록 확정 뒤 `OL7ADMIN_과정구성_5일.md` 로 만든다.

---

# 7. 챕터 구성

## 7.1 OU 단원 → 이 과정의 장 (20장 확정)

| OU 단원 | 이 과정 | 처리 |
|---|---|---|
| Course Introduction | 1장 | 실습 환경 소개 절로 |
| Introduction to Oracle Linux | 1장 | 그대로 |
| Oracle Cloud Computing | 1장 한 절 | 개념만(4.3) |
| Installing Oracle Linux 7 | 2장 | OL6 업그레이드는 개요만 |
| Oracle Linux 7 Boot Process | 3장 | |
| System Configuration | 4장 | |
| Package Management | 5장 | ULN 은 개념 위주(4.4) |
| Oracle Ksplice | — | 제외(4.4). 5장 Note 한 상자 |
| Automating Tasks | 6장 | |
| Kernel Module Configuration | 7장 | ACFS·ADVM 드라이버는 RAC 과정 참조 |
| User and Group Administration | 8장 | |
| Partitions, File Systems, and Swap | 9장 | |
| Storage Administration | 10장 | |
| XFS File System | 11장 | |
| Btrfs File System | 12장 | UEK 에서만 지원됨을 명시 |
| Network Configuration | 13장 | OCI 네트워킹 제외 |
| File Sharing | 14장 | |
| OpenSSH | 15장 | OCI 키 페어는 Note |
| Security Administration | 16장 | SELinux 제외(4.4) |
| Oracle on Oracle | 17장 | |
| System Monitoring & System Logging | 18장 · 19장 | 두 장으로 나눔. OU 목차도 sosreport~Spacewalk 와 rsyslog~journald 가 별도 묶음이다 |
| Troubleshooting | 20장 | |

모니터링과 로깅을 나눈 이유

- Ksplice 장이 빠진 자리를 채우면서도 OU 목차 밖의 주제를 끌어오지 않는다.
- 원래 단원이 두 묶음을 한 장에 담고 있어 분량이 다른 장의 두 배에 가깝다. 도구 10여 개와 로깅 체계 두 가지를 한 장 26,000~30,000자에 넣으면 각 도구가 출력 한 화면 수준으로 줄어든다.
- 로깅을 독립시키면 rsyslog 원격 수집·journald 영구 저장·로그 회전을 실측할 자리가 생긴다. 20장 문제 해결이 그 로그를 읽는 데서 출발하므로 순서도 자연스럽다.

## 7.2 장 내부 구조

기존 과정 본문 docx 의 골격을 그대로 쓴다.

```text
제N장  제목                    (Heading 1)
  학습 목표
  N.1 ~ N.k 절                 (Heading 2/3) — 개념 → 구성 파일·명령 → 확인 방법
  Note / Best Practice / 실무 시나리오 상자
  7.9 와 8/9 의 차이            (해당하는 장만, 표 하나)
  요약
  퀴즈 6문항
  실습 개요                     (그 장 트랜스크립트 목록과 각 목표)
```

- 본문 문체는 개조식 + 평서체(`~다`/`~함`/`~됨`)로 쓴다. 독자를 직접 부르지 않는다. 규칙은 `oracle-practice-set/references/lecture-plan-format.md`.
- "7.9 와 8/9 의 차이" 표는 버전을 오가며 실수하기 쉬운 장(3·4·5·12·13·16·19)에만 둔다.

---

# 8. 챕터 상세

실습 수는 잠정치다. 트랜스크립트 주제 목록을 쓰면서 확정한다. ★ = `ol7b` 가 필요한 실습, ⚠ = 시작 전 스냅샷이 필요한 실습.

### 1장 — Oracle Linux 개요와 UEK
- 주요 내용: 리눅스 커널 개발 모델과 배포판 / Oracle 의 커널 기여 / UEK 와 RHCK / OL 7 업데이트 릴리스와 7.9 의 위치 / 지원 단계(Extended Support) / Oracle Cloud(IaaS·OCI) 개념 / 실습 환경 구성
- 실습 4개: 배포판·커널 식별, 설치된 커널 목록과 기본 커널, 7.9 릴리스 노트 항목을 시스템에서 대조, 랩 접속과 프롬프트 규칙
- 근거: RN79, UEK, ADM

### 2장 — Oracle Linux 7.9 설치
- 주요 내용: 설치 매체 구하기(Oracle Software Delivery Cloud, yum.oracle.com ISO) / Anaconda 단계별 설정 / 파티션 설계 / kickstart(`anaconda-ks.cfg` 재사용) / 설치 후 첫 설정 / OL6 → OL7 업그레이드 개요
- 실습 5개 ⚠: GUI 설치 과정, 설치 결과 확인, kickstart 파일 읽기, kickstart 로 `ol7b` 설치, 오류 재현(잘못된 kickstart 지시어)
- 설치 장은 화면 캡처가 핵심이라 docx 에 그림이 들어간다. RAC GUI 설치 가이드의 캡처 방식(VNC → PNG)을 쓴다.

### 3장 — 부트 프로세스와 systemd
- 주요 내용: 펌웨어 → GRUB 2 → 커널 → initramfs → systemd / `grub2-mkconfig`, `grubby`, 기본 커널 변경 / 커널 부트 파라미터 / 서비스 유닛·타깃 유닛 / `systemctl` / 종료·재부팅·절전
- 실습 7개 ⚠: 부팅 순서 추적(`systemd-analyze`), 기본 커널을 RHCK 로 바꿨다 되돌리기, 부트 파라미터 일회성·영구 적용, 서비스 enable/start 차이, 타깃 전환, 서비스 유닛 작성, 오류 재현(잘못된 유닛 파일)
- Common Error: `grub.cfg` 를 직접 고쳤다가 다음 커널 업데이트에서 사라짐

### 4장 — 시스템 구성
- 주요 내용: 날짜·시간대(`timedatectl`) / chrony 와 ntpd / `/etc/sysconfig` 주요 파일 / `/proc` / `sysctl` 과 `/etc/sysctl.d` / `/sys`
- 실습 6개 ★: chrony 서버·클라이언트(ol7a ↔ ol7b), ntpd 로 바꿨다 되돌리기, 시간 어긋남 재현과 보정, `/proc` 로 시스템 정보 읽기, `sysctl` 영구 설정과 적용 순서, 오류 재현(잘못된 sysctl 키)
- RAC 과정 연결: Clusterware 의 CTSS 가 chrony 와 어떻게 공존하는지 Note 한 상자

### 5장 — 패키지 관리
- 주요 내용: RPM 구조와 `rpm` 질의·검증 / `yum.oracle.com` 과 `.repo` 파일 / `yum` 설치·업데이트·이력·되돌리기 / 그룹 설치 / 로컬 저장소 / ULN 과 채널(개념) / RHN 에서 ULN 으로 전환(개념) / 재부팅 없는 커널 패치 제품(Note)
- 실습 7개 ⚠: `rpm -qi/-ql/-qf/-V`, 저장소 구성 확인, 설치와 `yum history undo`, 오류 재현(의존성 충돌), 로컬 ISO 저장소, 커널 업데이트와 이전 커널 보존 개수(`installonly_limit`), 패키지 서명 확인
- Common Error: `rpm -ivh --nodeps` 로 의존성 문제를 덮음

### 6장 — 작업 자동화
- 주요 내용: `cron` / `/etc/cron.*` / `crontab` / `anacron` / `at`·`batch` / 접근 제어 파일(`cron.allow` 등) / systemd 타이머(OU 목차 밖이지만 7.9 에서 실제로 쓰이는 방식이라 짧게 비교)
- 실습 5개: 사용자 crontab, 시스템 cron 디렉터리, anacron 지연 실행 관찰, `at`·`batch`, 오류 재현(환경 변수 없는 cron 실행 실패)

### 7장 — 커널 모듈 구성
- 주요 내용: 적재 가능 모듈 / `lsmod`·`modinfo`·`modprobe` / `insmod`·`rmmod`·`depmod` / 모듈 파라미터와 `/etc/modprobe.d` / 블랙리스트 / UEK·RHCK 간 모듈 차이 / ACFS·ADVM 드라이버(개념)
- 실습 5개 ⚠: 모듈 조회, 적재·해제, 파라미터 영구 설정, 블랙리스트, 오류 재현(사용 중인 모듈 해제 시도)
- ACFS·ADVM 은 Grid Infrastructure 가 있어야 보이므로 RAC 과정 해당 장을 참조만 한다

### 8장 — 사용자와 그룹 관리
- 주요 내용: `/etc/passwd`·`shadow`·`group`·`gshadow` / `useradd` 기본값(`/etc/default/useradd`, `/etc/login.defs`) / 변경·삭제 / UPG / 암호 정책(`chage`, `pwquality`) / `su` 와 `sudo`
- 실습 6개: 사용자 생성과 파일 변화, 그룹과 UPG, 암호 만료 정책, `sudo` 최소 권한, 오류 재현(`/etc/sudoers` 문법 오류를 `visudo` 가 막는 이유), 계정 잠금과 해제
- User Manager(GUI)는 언급만 한다

### 9장 — 파티션·파일 시스템·스왑
- 주요 내용: MBR·GPT / `fdisk`·`gdisk`·`parted` / 파일 시스템 종류 / Ext4 만들기와 튜닝(`tune2fs`) / 마운트와 `/etc/fstab`(UUID, 옵션) / `fsck` / 스왑 파티션·스왑 파일
- 실습 7개 ⚠: 파티션 생성, Ext4 생성·마운트, `fstab` 영구 마운트, 오류 재현(`fstab` 오타로 emergency 모드 진입 → 복구), `fsck`, 스왑 추가, 파일 시스템 확장

### 10장 — LVM 과 RAID
- 주요 내용: PV·VG·LV / 확장·축소·이동(`pvmove`) / VG 메타데이터 백업·복원 / thin provisioning / LVM 스냅샷과 `snapper` / `mdadm` RAID 0·1·5 / 디스크 장애 시 RAID 재구성
- 실습 8개 ⚠: LVM 구성, 온라인 확장, 축소(XFS 는 축소 불가 확인), `vgcfgrestore`, thin pool, 스냅샷과 되돌리기, RAID 5 구성, 오류 재현(RAID 디스크 장애와 재구축)

### 11장 — XFS 파일 시스템
- 주요 내용: XFS 구조 / `mkfs.xfs` / `xfs_growfs` / `xfs_admin` / 할당량(`xfs_quota`) / `xfsdump`·`xfsrestore` / `xfs_repair`
- 실습 6개 ⚠: 생성과 정보 조회, 온라인 확장, 사용자·프로젝트 할당량, 오류 재현(할당량 초과 쓰기), 덤프·복원, 손상 복구

### 12장 — Btrfs 파일 시스템
- 주요 내용: Btrfs 구조 / 여러 디스크로 생성 / `btrfs` 명령 / 서브볼륨·스냅샷 / 서브볼륨 마운트 / 유지 보수(scrub, balance) / Ext 에서 변환(`btrfs-convert`) / 지원 범위(UEK 전용, OL8 에서 RHCK 미지원)
- 실습 5개 ⚠: 생성, 서브볼륨·스냅샷, 스냅샷으로 되돌리기, Ext4 변환, 오류 재현(RHCK 로 부팅했을 때의 동작) — 마지막은 실측 확인 후 확정

### 13장 — 네트워크 구성
- 주요 내용: 인터페이스 이름 규칙 / `/etc/sysconfig/network-scripts/ifcfg-*` / `network` 서비스와 NetworkManager / `nmcli` / `ip` / `ethtool` / 호스트 이름·이름 해석
- 실습 7개 ★⚠: 현재 구성 읽기, `nmcli` 로 고정 IP 변경, ifcfg 파일 직접 편집과 반영, 보조 IP, 본딩(추가 NIC), 오류 재현(게이트웨이 누락 → 외부 통신 불가), `ethtool` 확인

### 14장 — 파일 공유
- 주요 내용: NFS 서버(`/etc/exports`, `exportfs`, `nfs-server`) / NFS 클라이언트 / autofs / vsftpd 설정
- 실습 6개 ★: NFS 공유와 마운트(ol7a → ol7b), 내보내기 옵션 비교(`root_squash`), autofs, vsftpd 익명·로컬 사용자, 오류 재현(방화벽 미개방으로 NFS 마운트 실패), RMAN 백업 대상 NFS 마운트 옵션(DB 과정 연결)

### 15장 — OpenSSH
- 주요 내용: 서버·클라이언트 설정 파일 / `ssh`·`scp`·`sftp` / `ssh-keygen` / 무암호 접속 / `ssh-agent`·`ssh-add` / OCI 키 페어(Note)
- 실습 6개 ★: 접속과 호스트 키, 키 생성·배포, 오류 재현(`authorized_keys` 권한 오류로 키 인증 실패), `ssh-agent`, `sshd_config` 강화(root 로그인 제한), 포트 포워딩
- RAC 설치 가이드의 노드 간 SSH 동등성 구성과 같은 절차라 그 가이드를 참조로 연결한다

### 16장 — 보안 관리
- 주요 내용: chroot 와 chroot jail / 패킷 필터링 방화벽 개념 / firewalld 영역·서비스·rich rule / `firewall-cmd`·`firewall-config` / iptables 서비스 / TCP Wrappers
- 실습 7개 ★⚠: chroot jail 구성, firewalld 서비스·포트 개방과 영구 반영, rich rule, firewalld → iptables 전환과 원복, TCP Wrappers, 오류 재현(`--permanent` 만 쓰고 reload 하지 않아 적용 안 됨), 리스너 포트 1521 개방

### 17장 — Oracle on Oracle: DB 서버 준비
- 주요 내용: Oracle 소프트웨어 사용자·그룹(`oinstall`, `dba`, `oper`, `backupdba` 등) / `oracle-database-preinstall-19c` / 공유 메모리(`shmmax`·`shmall`·`shmmni`) / 세마포어 / 파일 핸들·AIO / 셸 한도(`limits.d`) / HugePages 계산과 THP 비활성화 / ASMLib v2 와 udev 비교
- 실습 8개 ⚠: preinstall 적용 전후 비교, 수동 설정, 셸 한도 확인, HugePages 계산과 적용, THP 비활성화(부트 파라미터), ASMLib 디스크 표시, udev 규칙, 오류 재현(HugePages 부족으로 SGA 가 일반 페이지에 올라감 — `D:\OEL7V9` 의 DB 경고 로그 대조)
- 권고값은 DB 19c 설치 가이드 기준. RAC 과정 3장과 겹치는 부분은 이 장이 원본이 되고, RAC 쪽은 "Clusterware 가 추가로 요구하는 것"만 남는다

### 18장 — 시스템 모니터링
- 주요 내용: 모니터링 도구 지도(무엇을 볼 때 무엇을 쓰는가) / `vmstat`·`mpstat`·`iostat`·`sar`(sysstat) / `top`·`iotop` / `strace` / `netstat`·`ss`·`tcpdump` / `sosreport` / OSWatcher / Spacewalk(개요)
- 실습 7개 ★: CPU 부하를 걸고 지목, 메모리 압박과 스왑 관찰, I/O 부하와 `iostat` 열 읽기, `sar` 이력으로 지난 시간대 재구성, `strace` 로 멈춘 프로세스 추적, `tcpdump` 로 ol7a ↔ ol7b 통신 확인, `sosreport` 생성과 내용 구조
- 부하 생성은 `stress` 대신 `dd`·셸 루프로 만든다(별도 저장소 의존 없이 재현 가능하게). 스크립트는 `scripts/load/` 에 둔다

### 19장 — 시스템 로깅
- 주요 내용: 로깅 체계 개요(journald → rsyslog 흐름) / rsyslog 구성 파일·셀렉터·액션 / 템플릿 / 원격 전송(TCP/UDP) / journald 와 `journalctl` 필터 / journald 영구 저장 / `logrotate` / `logger` 로 시험 메시지 남기기
- 실습 6개 ★: 로그 흐름 추적(`logger` → journal → `/var/log/messages`), 셀렉터로 로그 분리, 원격 전송(ol7a → ol7b), 템플릿으로 호스트별 파일, journald 영구 저장 전환과 부팅 간 조회, 오류 재현(rsyslog 설정 문법 오류 → `rsyslogd -N1` 로 찾기)
- `logrotate` 는 OU 목차 밖이지만 원격 수집을 켜면 바로 마주치는 문제라 한 절로 넣는다

### 20장 — 문제 해결
- 주요 내용: 2단계 접근(정보 수집 → 원인 좁히기) / OS 로그 / `dmesg` / 지원 자료(MOS, 문서) / 원인 분류 / 부팅 장애 / NFS 장애
- 실습 6개 ⚠: root 암호 분실 복구(`rd.break`), 손상된 `fstab`, 잘못된 기본 타깃, GRUB 설정 손상과 rescue 모드, NFS 서버 정지·권한·방화벽 장애 셋 구분, `dmesg` 로 디스크 오류 읽기

합계 실습 124개(장별 주제와 수업·자습 구분은 `OL7ADMIN_실습_트랜스크립트_주제_목록.md`).

---

# 9. 산출물 규격

## 9.1 장별 파일 (문제 4종 포함, 확정)

기존 과정 규격(`제작_가이드.md` 3장)을 그대로 따른다.

| 파일 | 규격 |
|---|---|
| `{N}장_{제목}.docx` | 본문 26,000~30,000자. Heading 1 "제N장  제목". 맑은 고딕 / 코드 Consolas. Note·Best Practice·실무 시나리오·Quiz 색상 상자 |
| `{N}장_{제목}.pptx` | 35~55장. 다크 타이틀·섹션, 붉은 헤더 콘텐츠. 예외 슬라이드를 뺀 모든 슬라이드에 발표자 노트 200~500자 |
| `{N}장_실습문제.docx` | 객관식 50문항(하20/중20/상10), `[하-01]`, 보기 `①②③④`, 정답 고르게 분산 |
| `{N}장_실습문제_정답.docx` | 정답 + 해설 |
| `{N}장_실습문제_추가서술형.docx` | 20문항(서술형 8 + 문제해결형 6 + 명령어진행형 6), 객관식 금지 |
| `{N}장_실습문제_추가서술형_정답.docx` | 모범답안 + 채점 포인트 |
| `{N}장_실습_{NN}_{주제}.txt` | 실측 세션 트랜스크립트(9.2) |

## 9.2 트랜스크립트 규격 — 기존 과정보다 보강

### 무엇이 빈약했나

RAC 과정 트랜스크립트(1·5·12·18·19장 표본 39개)를 재 보니 다음과 같았다.

| 지표 | RAC 평균 | 문제 |
|---|---:|---|
| 크기 | 약 12KB | |
| 줄 수 | 약 260줄 | |
| 단계(`[N]`) | 약 7개 | 단계마다 명령 한두 개와 결과 한 화면으로 끝나는 경우가 많다 |
| 해설 주석 | 약 100줄 | 출력의 일부 열만 짚고 나머지는 지나간다 |

명령과 출력은 충실하지만, 혼자 따라 하는 학습자가 "왜 이 명령을 치는가", "이 출력의 나머지 열은 무엇인가", "다르게 나오면 무엇을 의심하는가"를 알 수 없는 곳이 많았다. 이 과정은 리눅스 관리가 처음인 DBA 도 대상이라 그 공백이 더 크게 드러난다.

### 분량 기준

| 지표 | 이 과정 기준 | RAC 대비 |
|---|---:|---:|
| 크기 | 20~30KB | 약 2배 |
| 줄 수 | 450~700줄 | 약 2배 |
| 단계 | 10~15개 | 약 1.5~2배 |
| 해설 주석 | 전체 줄 수의 40% 이상 | |
| 오류 흐름 | 2곳 이상(그중 1곳은 실습 주제와 직접 관련된 오류) | RAC 는 1곳 이상 |

분량을 채우려고 같은 명령을 반복하거나 의미 없는 출력을 늘리지 않는다. 늘어나는 몫은 아래 필수 요소에서 나와야 한다.

### 필수 요소

1. 머리 상자 — 기존 항목(대상·목표·소요·선행·계정·주의)에 두 줄을 더한다.
   - `배경   :` 이 실습이 다루는 개념을 3~5줄로 요약. 본문 몇 절에 해당하는지 표시
   - `되돌림 :` 끝났을 때 돌아가는 상태와 확인 명령
2. `[0] 시작 전 상태 기록` — 바꿀 대상의 현재 값을 먼저 남긴다. 마지막 단계에서 이 값과 비교한다.
3. 명령마다 "왜 이 명령인가" 한두 줄을 명령 앞에 둔다. 옵션이 붙으면 옵션마다 뜻을 적는다.
4. 출력 해설은 열·필드 단위로 한다. 예를 들어 `df -hT` 를 보였으면 일곱 열을 모두 짚고, 이 실습에서 볼 열을 표시한다. 같은 출력이 같은 파일에서 다시 나오면 바뀐 열만 짚는다.
5. 구성 파일은 고치기 전후를 모두 보인다. 변경은 `diff` 로 다시 보여 준다. 긴 파일은 `grep -v '^#'`·`sed -n` 으로 범위를 밝혀 자르고, 무엇을 잘랐는지 적는다. 출력 중간을 `...` 로 말없이 생략하지 않는다.
6. 변경 직후 "즉시 반영되는가, 재시작·재부팅이 필요한가"를 실제로 확인한다. 재부팅이 필요한 변경은 재부팅 전후 출력을 모두 남긴다.
7. 오류 흐름은 다음 네 줄 형식을 지킨다(RAC 18장 05 의 형식).
   ```text
   -- 증상   : 무엇이 보였나 (실측 메시지 원문 인용)
   -- 원인   : 왜 그런가, 어디를 보고 알았나
   -- 조치   : 고친 명령
   -- 재확인 : 고쳐졌음을 보이는 명령과 기대 결과
   ```
8. `[변형]` 단계 — 같은 작업을 다른 도구나 다른 옵션으로 한 번 더 해 본다(예: `nmcli` 로 한 것을 ifcfg 파일로, `fdisk` 로 한 것을 `parted` 로). 결과가 같은지, 어디가 다른지 비교한다.
9. `[정리] 관찰 요약` — 끝에 표 하나로 정리한다.
   ```text
   --  항목              시작 전           변경 후           되돌린 뒤
   --  vm.swappiness     30                10                30
   ```
10. `[더 해 보기]` — 수업 밖에서 혼자 시도할 과제 2~3개. 정답은 쓰지 않지만 확인 방법은 적는다.
11. 8/9 와 동작이 다른 명령을 썼으면 그 자리에 `-- [OL8/9]` 한 줄로 차이를 적는다.

### 형식

```text
================================================================================
 제N장 실습 NN — 주제
 대상   : ol7a (필요하면 ol7b)
 목표   : 이 실습에서 확인하는 것
 배경   : 개념 요약 3~5줄 (본문 N.k 절)
 소요   : 약 N분
 선행   : 필요한 상태와 스냅샷
 계정   : root, oracle 등
 주의   : 되돌릴 수 없는 작업 여부
 되돌림 : 끝났을 때의 상태와 확인 명령
================================================================================

--------------------------------------------------------------------------------
 [0] 시작 전 상태 기록
--------------------------------------------------------------------------------

-- 왜 이 명령인가
[root@ol7a ~]# 명령
실측 출력

-- 열·필드 단위 해설

 ... [1] ~ [N], [변형], 오류 흐름 ...

--------------------------------------------------------------------------------
 [정리] 관찰 요약
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
 [더 해 보기]
--------------------------------------------------------------------------------

================================================================================
 실습 NN 종료 — 한 줄 결과
================================================================================
```

- 프롬프트로 노드와 계정을 구분한다: `[root@ol7a ~]#`, `[oracle@ol7a ~]$`, `[root@ol7b ~]#`. 작업 디렉터리가 바뀌면 프롬프트에 반영한다.
- 출력과 오류 메시지는 실측한 원문만 쓴다. 해설 주석은 한국어 평서체로 쓰고, 출력 안의 영문은 번역하지 않고 인용한다.
- 주석 문체도 본문과 같은 규칙을 따른다. "~것이 핵심이다" 식의 재진술로 단계를 끝맺지 않는다.

### 파일럿

1장 실습 01 과 9장 실습 03 을 먼저 이 규격으로 만들어 분량과 밀도를 확인받은 뒤 나머지에 적용한다. 1장은 조회 위주, 9장은 변경·되돌림이 있는 실습이라 두 유형을 함께 볼 수 있다.

## 9.3 과정 단위 파일

| 파일 | 내용 |
|---|---|
| `_기획/OL7ADMIN_PRD.md` | 이 문서 |
| `_기획/OL7ADMIN_챕터_목록.md` | 장별 절 구성, 근거 문서 절 번호, 인접 장과의 경계 |
| `_기획/OL7ADMIN_실습_트랜스크립트_주제_목록.md` | 장별 실습 제목·목표·★⚠ 표시·수업/자습 구분 |
| `_기획/OL7ADMIN_과정구성_5일.md` | 일자별 시간표 |
| `최종실습시험/0N_주제/` | 5세트(하루 하나), 문제지·모범답안 docx |
| `scripts/` | VM 준비·디스크 추가·부하 생성 스크립트 |

## 9.4 폴더와 빌드

- 저장소: `OracleManual/OL7ADMIN/01장` … `20장`, `_기획`, `최종실습시험`, `scripts`.
- 작업 폴더: `Downloads\_ol7_scratch`. 장별 마크업(`_cNN_body.mk`, `_cNN_ppt.mk`, `_cNN_q1/a1/e1/ea1.mk`)을 빌드해 산출물을 만든다.
- 빌더는 `_rac_scratch` 의 `docbuild2.py`·`pptbuild.py`·`shuffle_quiz.py`·`exambuild2.py`·`verify_ch.py` 를 복사해 쓴다. 템플릿 docx 는 RAC 18장 파일을 열어 본문을 비운 것(다른 장 파일을 복사해 이름만 바꾸지 않는다 — 제작 가이드 5장 규칙 11).
- 실측 캡처는 paramiko 로 `ol7a`·`ol7b` 에 접속해 로그를 남기는 헬퍼(`ol7lab.py`, `raclab.py` 기반)를 만든다. 캡처 로그(`capNNx.log`)가 트랜스크립트·문항 수치의 유일한 근거다. 2장 설치 화면은 VNC 캡처.
- 트랜스크립트는 캡처 로그에 해설을 덧붙여 만든다. 로그에 없는 출력을 해설 단계에서 끼워 넣지 않는다.
- 수정은 마크업을 고쳐 재빌드한다. 빌드 후 docx 를 직접 손보지 않는다.

---

# 10. 문제 제작 표준

- 기존 과정과 같다(`제작_가이드.md` 3·5장).
- 명령어진행형 문항은 "어떤 명령을 어떤 순서로" 묻되, 답안의 명령은 트랜스크립트에서 실측한 것만 쓴다.
- 7.9 와 8/9 가 다르게 동작하는 항목은 문항에 버전을 명시한다. "리눅스에서는" 같은 버전 없는 질문을 만들지 않는다.
- 객관식은 정답을 ①에 두고 쓴 뒤 `shuffle_quiz.py` 로 섞는다.
- 상 난이도 문항의 절반 이상은 트랜스크립트의 출력 일부를 보여 주고 판단하게 하는 판독형으로 만든다. 보강된 트랜스크립트의 열·필드 해설이 그 근거가 된다.
- 최종실습시험은 하루 범위를 묶어 VM 위에서 수행하는 실기형으로 만든다. 채점 기준은 "결과를 확인하는 명령과 그 출력"으로 적는다.

---

# 11. 검증 기준

`verify_ch.py` 21항목에 이 과정 고유 항목을 더한다.

- [ ] 본문 26,000~30,000자, 첫 Heading 1 의 장 번호 = 폴더 장 번호
- [ ] PPT 35~55장, 노트 없는 슬라이드가 전부 예외 슬라이드
- [ ] 하/중/상 20/20/10, 추가서술형 20, 문제 파일에 객관식 기호 없음
- [ ] 객관식 정답 ①~④ 분포 고름
- [ ] 다른 장과 해시가 같은 파일 없음
- [ ] 마크다운 기호(`**`, 백틱)가 글자로 남지 않음
- [ ] 트랜스크립트 크기 20~30KB, 450~700줄, 단계 10개 이상, 주석 비율 40% 이상
- [ ] 트랜스크립트에 `배경`·`되돌림` 머리 항목, `[0]`·`[정리]`·`[더 해 보기]` 단계, 오류 흐름 네 줄 형식 2곳 이상
- [ ] 트랜스크립트 프롬프트가 `ol7a`/`ol7b` 뿐이고 `rac1`·`oel7v9` 등 다른 랩 이름이 섞이지 않음
- [ ] 트랜스크립트 출력이 캡처 로그에 있는 것과 일치(무작위 표본 대조)
- [ ] 버전 문자열(커널·배포판)이 4.5 실측값과 일치
- [ ] OL 8/9 전용 명령·옵션(`dnf`, `authselect` 등)이 `[OL8/9]` 표시 없이 7.9 설명에 섞이지 않음
- [ ] Ksplice·SELinux 를 다루는 절이 생기지 않음(5장 Note 한 상자는 예외)
- [ ] 문체: 본문에 "여러분", "~합니다", "~해보자" 없음, 문단 끝 재진술 반복 없음

---

# 12. 결정 기록

| # | 질문 | 결정(2026-11-11) |
|---|---|---|
| 1 | 실습 VM 두 대 신규 | 가능. `ol7a`·`ol7b` 로 만든다 |
| 2 | 설치 ISO | `C:\Users\itwill\Downloads\OEL7V9.iso` |
| 3 | Ksplice 범위 | 제외. 장을 두지 않는다 |
| 4 | SELinux | 제외 |
| 5 | 산출물 범위 | 문제 4종까지 만든다 |
| 6 | 장 수 | 20장. Ksplice 자리는 모니터링·로깅 분리로 채운다 |
| 7 | 트랜스크립트 | 기존보다 보강한다. 규격은 9.2 |

---

# 13. 리스크와 대응

| 리스크 | 대응 |
|---|---|
| 공식 문서가 OL7 최신 업데이트 기준으로 갱신돼 7.9 이전 내용과 섞여 있음 | 4.5 실측값을 기준으로 삼고, 문서 문장을 옮기기 전에 `ol7a` 에서 확인한다 |
| `yum update` 로 커널이 바뀌어 장마다 버전 문자열이 달라짐 | `ol7-base` 스냅샷에서만 실측하고, 업데이트가 필요한 5장은 끝에 스냅샷으로 되돌린다 |
| 부팅·`fstab` 장애 실습에서 VM 이 복구 불가 상태가 됨 | ⚠ 실습은 `pre-break` 스냅샷에서 시작한다 |
| 호스트 메모리 부족(RAC 랩 기동 시 여유 3~4GB였던 전례) | OL7 랩 실측 중에는 다른 랩을 정상 종료한다 |
| 트랜스크립트 분량을 늘리다 해설이 같은 말을 반복함 | 9.2 의 필수 요소에서 분량이 나오게 하고, 파일럿 두 개로 밀도를 먼저 확인받는다 |
| 트랜스크립트 제작 시간이 RAC 의 두 배 가까이 듦 | 캡처 스크립트를 장 단위로 한 번에 돌리고(`_capNNx.py`), 해설은 로그를 받은 뒤 붙인다. 장당 일정에 반영 |
| SELinux 를 다루지 않는데 실습이 SELinux 때문에 막힘(vsftpd·NFS 홈 디렉터리 등) | 막힌 사실과 원인만 주석으로 남기고 `setenforce` 로 우회하지 않는다. 그 실습은 SELinux 영향이 없는 경로로 설계를 바꾼다 |
| `linux_guide`(OL 8/9)와 내용이 겹쳐 학습자가 혼동 | 해당 장에 "7.9 와 8/9 의 차이" 표, 트랜스크립트에 `[OL8/9]` 주석 |
| RAC 과정 3장·설치 가이드와 OS 준비 내용 중복 | 17장을 원본으로 삼고, RAC 쪽은 Clusterware 추가 요건만 다룬다는 경계를 챕터 목록에 적는다 |

---

# 14. 다음 단계

| 단계 | 내용 |
|---|---|
| 1 | OL7 공식 문서 PDF 받기(`Downloads\OL7\`), 장별 근거 절 번호 매핑 |
| 2 | `OL7ADMIN_챕터_목록.md`, `OL7ADMIN_실습_트랜스크립트_주제_목록.md` 작성 |
| 3 | ISO 버전 확인 → `ol7a` 설치(2장 캡처 겸) → `ol7b` kickstart 설치 → 기준 스냅샷, 4.5 표 채우기 |
| 4 | 빌더 복사와 템플릿 준비, `ol7lab.py` 헬퍼 |
| 5 | 트랜스크립트 파일럿 2개(1장 01, 9장 03) — 9.2 규격 확인받기 |
| 6 | 1장 파일럿 — 7종 산출물, 검증 후 형식 확정 |
| 7 | 2~20장, 장마다 실측 → 마크업 → 빌드 → 검증 |
| 8 | 최종실습시험 5세트, 과정 구성 문서, README·제작 가이드 현황표 갱신 |
