# Oracle Linux 7.9 시스템 관리 교안 — 챕터 목록 (v1)

**작성일** 2026-11-11
**과정 코드명** OL7ADMIN (`OracleManual` 저장소)
**상위 문서** `OL7ADMIN_PRD.md` v2
**상태** 20장 확정, 장별 절 구성 초안. 실습 VM 구축 후 4.5 실측값이 나오면 버전 문자열이 들어가는 절을 고친다.

---

## 1. 소스 인벤토리

| 약어 | 문서 | 파일(`Downloads\OL7\`) | 쪽 | 용도 |
|---|---|---|---:|---|
| RN79 | Release Notes for Oracle Linux 7.9 | `OL7-RELNOTES7-9.pdf` | 97 | 7.9 의 커널·변경 사항·알려진 문제. 버전 문자열의 1순위 근거 |
| INS | Installation Guide | `OL7-INSTALL.pdf` | 61 | 2장 |
| OSM | Managing Core System Configuration | `OL7-OSMANAGE.pdf` | 52 | 3·4·7·17장 |
| YUM | Managing Software | `OL7-YUM.pdf` | 28 | 5장 |
| UAU | Setting Up System Accounts and Authentication | `OL7-USERAUTH.pdf` | 59 | 8장 |
| STO | Managing Storage and Storage Devices | `OL7-STORDEV.pdf` | 40 | 9·10장 |
| FS | Managing File Systems | `OL7-FSADMIN.pdf` | 79 | 9·11·12·14장 |
| NET | Setting Up Networking | `OL7-NETWORK.pdf` | 101 | 4·13장 |
| SSH | Connecting to Remote Systems With OpenSSH | `OL-OPENSSH.pdf` | 31 | 15장 |
| SEC | Security Guide | `OL7-SECURITY.pdf` | 78 | 16·19장 |
| ASML | Installing and Configuring Oracle ASMLIB v2 | `OL7-ASMLIB.pdf` | 12 | 17장 |
| MON | Monitoring and Tuning the System | `OL7-MONITORING.pdf` | 51 | 6·18·20장 |
| ADM | Administrator's Guide | `OL7-ADMIN.pdf` | 19 | 주제별 문서로 안내하는 색인 문서. 본문 근거로는 쓰지 않음 |
| ULN | ULN User's Guide for OL 6 and 7 | HTML 만 제공 (`/oracle-linux/uln-user/`) | — | 5장 ULN 절 |
| UEK | UEK R6 Release Notes | HTML (`/en/operating-systems/uek`) | — | 1·7·12장 |
| DBI | Oracle Database 19c Installation Guide for Linux | DB 문서 | — | 17장 권고값, 14장 NFS 마운트 옵션 |
| MAN | 7.9 에 설치된 man 페이지 | `ol7a` | — | 공식 문서가 다루지 않는 주제(journald, logrotate, vsftpd, TCP Wrappers 세부) |

- 2026-11-11 받은 판이다. Oracle 이 OL7 문서를 계속 고치므로 문서 번호(예: `E54669-80`)를 챕터 목록 착수 시점의 판으로 기록해 둔다.
- PDF 는 저장소에 커밋하지 않는다(PRD 5절).
- ADM 은 2020 년 이후 주제별 문서로 쪼개지고 색인만 남았다. OU 과정이 "Administrator's Guide 몇 장"으로 가리키던 내용은 지금 OSM·NET·FS·STO·SEC·MON 에 흩어져 있다.

### 1-1. 원본 문서의 장 구성 (근거 매핑용)

| 단위 | 원본 | 제목 | 쓰는 장 |
|---|---|---|---|
| RN79-3 | RN79 3장 | Shipped Kernels | 1 |
| RN79-4 | RN79 4장 | New Features and Changes | 1 |
| RN79-5 | RN79 5장 | Known Issues | 2·17 |
| RN79-6 | RN79 6장 | Installation and Availability (UEK 업그레이드 경로) | 1·5 |
| RN79-8 | RN79 8장 | Package Changes from the Upstream Release | 1 |
| INS-1 | INS 1장 | Pre-installation Configuration | 2 |
| INS-2 | INS 2장 | Installing Oracle Linux Manually | 2 |
| INS-3 | INS 3장 | Options for Installation (부트 옵션, kickstart, 텍스트 설치) | 2 |
| INS-4 | INS 4장 | Post-Installation Configuration | 2·5 |
| INS-5 | INS 5장 | Troubleshooting Oracle Linux 7 Installations | 2·20 |
| OSM-1 | OSM 1장 | GRUB 2 Bootloader and Boot Services | 3·20 |
| OSM-2 | OSM 2장 | Working With System Services (systemd) | 3 |
| OSM-3 | OSM 3장 | Configuring System Settings (sysconfig, /proc, /sys, 날짜·시간) | 4 |
| OSM-4 | OSM 4장 | Device Management (udev) | 17 |
| OSM-5 | OSM 5장 | Kernel Modules | 7 |
| YUM-1~9 | YUM 1~9장 | Yum, ULN, 저장소, 그룹, 보안 플러그인, 로컬 저장소, yum-cron | 5 |
| UAU-1 | UAU 1장 | Authentication Configuration (PAM 개요만) | 8 |
| UAU-2 | UAU 2장 | Local Account Configuration | 8 |
| STO-1 | STO 1장 | Disk Partitions, Swap | 9 |
| STO-2 | STO 2장 | Logical Volume Manager | 10 |
| STO-3 | STO 3장 | Software RAID | 10 |
| FS-1 | FS 1장 | About File System Management | 9 |
| FS-2 | FS 2장 | Creating and Managing File Systems (마운트, fstab, automounter, fsck, 할당량) | 9·11·14 |
| FS-3 | FS 3장 | Btrfs | 12 |
| FS-4 | FS 4장 | Ext File System (Btrfs 변환) | 12 |
| FS-5 | FS 5장 | XFS | 11 |
| FS-6 | FS 6장 | Shared File System (NFS) | 14 |
| NET-1 | NET 1장 | Configuring the System's Network | 13 |
| NET-2 | NET 2장 | Network Addressing (DHCP 클라이언트만) | 13 |
| NET-4 | NET 4장 | Configuring Network Time (chrony, ntpd) | 4 |
| SSH-1~5 | SSH 1~5장 | OpenSSH 서버·클라이언트·키·유틸리티 | 15 |
| SEC-2 | SEC 2장 | Security Guidelines | 16·19 |
| SEC-4 | SEC 4장 | Implementing Oracle Linux Security (firewalld, iptables, TCP Wrappers, chroot, logging) | 16·19 |
| ASML-1~3 | ASML 1~3장 | ASMLIB 설치·구성 | 17 |
| MON-1 | MON 1장 | Monitoring the System | 18 |
| MON-2 | MON 2장 | sosreport | 18·20 |
| MON-3 | MON 3장 | OSWatcher Black Box | 18 |
| MON-6 | MON 6장 | Automating System Tasks (cron, anacron, at, batch) | 6 |
| MON-7 | MON 7장 | Crash Dumps (Kdump) | 20 (Note 수준) |

### 1-2. 원본에서 쓰지 않는 장

| 원본 | 이유 |
|---|---|
| INS-1 의 네트워크 설치 서버(PXE·TFTP·Dnsmasq) | OU 목차 밖. 2장에 "대량 설치는 PXE + kickstart" 한 줄 |
| UAU-1 의 IPA·LDAP·NIS·Kerberos·SSSD | OU 목차 밖 |
| STO-4~6 (LUKS, iSCSI, multipath) | OU 목차 밖. multipath 는 RAC 과정의 공유 스토리지 주제 |
| FS-6 의 Samba, FS-7 OCFS2 | OU 목차 밖 |
| NET-3 DNS 서버, NET-5~9 (Apache, 메일, Pacemaker, HAProxy·Keepalived, VNC) | OU 목차 밖 |
| SEC-3·5~8 (보안 설치, OpenSCAP, FIPS, Common Criteria), SEC-4 의 SELinux·감사 | OU 목차 밖, SELinux 는 PRD v2 결정 4 로 제외 |
| MON-4 PCP, MON-5 Tuned | OU 목차 밖 |
| Ksplice User's Guide | PRD v2 결정 3 으로 제외 |

---

## 2. 다른 과정과의 관계

### 2-1. 전제로 삼는 것 (다시 가르치지 않는다)

| 주제 | 어디서 다뤘나 | 이 과정에서의 처리 |
|---|---|---|
| 파일·디렉터리, 권한, 텍스트 처리, vi, 프로세스 | `linux_guide` 3~11장(OL 8/9 기준) | 다루지 않는다. 명령이 7.9 에서 다르게 동작할 때만 `[OL8/9]` 주석 |
| 셸 스크립트 기초 | `linux_guide` 5장 | 다루지 않는다. 6장 cron 예제·18장 부하 스크립트는 완성본을 주고 읽는 법만 |
| 패키지 기초(`dnf`) | `linux_guide` 13장 | 5장은 `yum`·`rpm` 으로 처음부터. `dnf` 는 `[OL8/9]` 주석으로만 |

### 2-2. 이 과정이 원본이 되는 것

이 과정 뒤에 오는 DB 과정들이 OS 설정을 다시 설명하지 않도록 경계를 정한다.

| 주제 | 이 과정 | 다른 과정의 처리 |
|---|---|---|
| 커널 파라미터·셸 한도·HugePages | 17장 | RAC 3장은 Clusterware 추가 요건(사설 네트워크, 공유 디스크, `cluvfy`)만 |
| udev 로 디스크 이름 고정 | 17장 | RAC 3장은 공유 디스크 특유의 것(`scsi_id`, 양 노드 일치)만 |
| chrony | 4장 | RAC 2장은 CTSS 와의 관계만 |
| SSH 키 인증 | 15장 | RAC 설치 가이드는 노드 간 사용자 동등성 절차만 |
| NFS | 14장 | BACKUP&RECOVERY 과정은 RMAN 백업 대상 경로로만 |
| OS 자원 판별(`vmstat`·`iostat`·`sar`) | 18장 | Tuning 20장은 "DB 대기 이벤트와 OS 지표를 어떻게 맞춰 보는가"만 |

### 2-3. `linux_guide` 와의 경계

| 구분 | `linux_guide` | OL7ADMIN |
|---|---|---|
| 버전 | OL 8/9 | OL 7.9 |
| 수준 | 기초 명령 | 시스템 관리 |
| 형식 | Markdown 13장 | docx·pptx·문제·트랜스크립트 20장 |
| 겹치는 장 | 4 커널, 10 사용자, 12 네트워크, 13 패키지 | 7·8·13·5 장. 겹치는 명령은 7.9 기준으로 다시 실측 |

---

## 3. 챕터 목록 (20장)

| 장 | 제목 | 근거 | 일차 | 실습 |
|---|---|---|---|---:|
| 1 | Oracle Linux 개요와 UEK | RN79-3·4·6·8, UEK | 1 | 4 |
| 2 | Oracle Linux 7.9 설치 | INS-1~5, RN79-5 | 1 | 5 |
| 3 | 부트 프로세스와 systemd | OSM-1·2 | 1 | 7 |
| 4 | 시스템 구성 | OSM-3, NET-4 | 1 | 6 |
| 5 | 패키지 관리 | YUM-1~9, ULN, INS-4 | 2 | 7 |
| 6 | 작업 자동화 | MON-6 | 2 | 5 |
| 7 | 커널 모듈 구성 | OSM-5, UEK | 2 | 5 |
| 8 | 사용자와 그룹 관리 | UAU-2, UAU-1(PAM) | 2 | 6 |
| 9 | 파티션·파일 시스템·스왑 | STO-1, FS-1·2 | 2 | 7 |
| 10 | LVM 과 RAID | STO-2·3 | 3 | 8 |
| 11 | XFS 파일 시스템 | FS-5, FS-2(할당량) | 3 | 6 |
| 12 | Btrfs 파일 시스템 | FS-3·4, INS-3 | 3 | 5 |
| 13 | 네트워크 구성 | NET-1·2 | 3 | 7 |
| 14 | 파일 공유 | FS-6, FS-2(automounter), MAN | 4 | 6 |
| 15 | OpenSSH | SSH-1~5 | 4 | 6 |
| 16 | 보안 관리 | SEC-2·4 | 4 | 7 |
| 17 | Oracle on Oracle: DB 서버 준비 | DBI, OSM-4, ASML, RN79-5 | 4 | 8 |
| 18 | 시스템 모니터링 | MON-1·2·3 | 5 | 7 |
| 19 | 시스템 로깅 | SEC-2·4, MAN | 5 | 6 |
| 20 | 문제 해결 | INS-5, OSM-1, MON-2·7, FS-6 | 5 | 6 |
| | | | | **124** |

---

## 4. 장별 절 구성

절 번호는 본문 docx 의 Heading 2 가 된다. 괄호 안은 근거 단위. "경계"는 인접 장이나 다른 과정과 겹치지 않게 하려고 이 장에서 다루지 않는 것이다.

### 1장. Oracle Linux 개요와 UEK

| 절 | 내용 | 근거 |
|---|---|---|
| 1.1 | 리눅스 커널 개발 모델 — 메인라인·안정판·LTS, 배포판이 하는 일 | UEK |
| 1.2 | Oracle Linux 와 업스트림 호환 — RHCK, 바이너리 호환, Oracle 이 바꾼 패키지 | RN79-4·8 |
| 1.3 | UEK — R4·R5·R6, 7.9 의 기본 커널, UEK 를 쓰는 이유 | RN79-3, UEK |
| 1.4 | OL7 업데이트 릴리스와 지원 단계 — 7.0~7.9, 업데이트 릴리스가 롤링 스냅샷이라는 점, Extended Support | RN79-6, 문서 라이브러리 공지 |
| 1.5 | Oracle 과 리눅스 커뮤니티 — 커널 기여 | UEK |
| 1.6 | Oracle Cloud 개요 — IaaS, OCI 기본 용어(테넌시·구획·VCN·인스턴스·블록 볼륨) | OU 목차 (개념만) |
| 1.7 | 이 과정의 실습 환경 — `ol7a`·`ol7b`, 프롬프트, 스냅샷, 다루지 않는 기초 명령 | PRD 4절 |

경계: 커널 업데이트 절차는 5장, 기본 부팅 커널 변경은 3장.

### 2장. Oracle Linux 7.9 설치

| 절 | 내용 | 근거 |
|---|---|---|
| 2.1 | 설치 요건과 매체 — Oracle Software Delivery Cloud, yum.oracle.com ISO, 체크섬 확인 | INS-1 |
| 2.2 | Anaconda 수동 설치 — 날짜·언어, 소프트웨어 선택, 저장 장치, Kdump, 네트워크·호스트 이름, 보안 정책, root·사용자 | INS-2 |
| 2.3 | DB 서버를 위한 파티션 설계 — `/boot`, `/`, swap, `/u01`, LVM 사용 여부 | INS-2, DBI |
| 2.4 | 설치 부트 옵션과 텍스트 설치 | INS-3 |
| 2.5 | kickstart — 설치가 남긴 `anaconda-ks.cfg`, 세 구역(옵션·%packages·%pre/%post), 검증(`ksvalidator`), 적용 방법 | INS-3 |
| 2.6 | 설치 후 첫 구성 — 저장소, 첫 업데이트, 설치 매체 저장소 | INS-4 |
| 2.7 | 설치 문제 해결 — 설치 중 콘솔 전환, `/tmp/*.log`, 설치 후 `/var/log/anaconda/`, RN79 의 설치 관련 알려진 문제 | INS-5, RN79-5 |
| 2.8 | OL6 → OL7 업그레이드와 OCI 인스턴스 생성 — 개요와 비교 | OU 목차 (개념만) |

경계: 설치 매체 rescue 모드는 20장. 패키지 저장소 상세는 5장.
비고: 캡처 그림이 들어가는 유일한 장. 2.2 는 그림 위주로 쓰고 본문 글자 수 하한(26,000자)을 그림 설명으로 채우지 않는다. 하한에 못 미치면 2.3·2.5 를 늘린다.

### 3장. 부트 프로세스와 systemd

| 절 | 내용 | 근거 |
|---|---|---|
| 3.1 | 부팅 순서 — BIOS/UEFI → GRUB 2 → 커널 → initramfs → systemd | OSM-1 |
| 3.2 | GRUB 2 — `/etc/default/grub`, `grub2-mkconfig`, BIOS 와 UEFI 의 `grub.cfg` 위치 | OSM-1 |
| 3.3 | 기본 부팅 커널 — `grub2-set-default`, `grubby`, `GRUB_DEFAULT=saved` | OSM-1 |
| 3.4 | 커널 부트 파라미터 — 부팅 전 일회성 편집, 영구 반영, `/proc/cmdline` | OSM-1 |
| 3.5 | systemd 와 유닛 — 유닛 종류, 유닛 파일 위치 세 곳과 우선순위 | OSM-2 |
| 3.6 | 타깃 — 런레벨 대응, 기본·현재 타깃 변경 | OSM-2 |
| 3.7 | 서비스 제어 — start/enable 의 차이, 상태 읽기, mask | OSM-2 |
| 3.8 | 유닛 파일 수정과 자원 제어 — drop-in(`systemctl edit`), cgroup 한도, 원격 `systemctl -H` | OSM-2 |
| 3.9 | 종료·절전·재부팅 명령 | OSM-2 |

경계: rescue·emergency 타깃으로 장애를 살리는 절차는 20장. 여기서는 타깃 개념과 전환까지.

### 4장. 시스템 구성

| 절 | 내용 | 근거 |
|---|---|---|
| 4.1 | `/etc/sysconfig` — 주요 파일과 어느 서비스가 읽는가 | OSM-3 |
| 4.2 | 날짜·시간대 — `timedatectl`, RTC 와 시스템 시계 | OSM-3 |
| 4.3 | chrony — `chrony.conf`, `chronyc sources/tracking`, 서버로 쓰기 | NET-4 |
| 4.4 | ntpd — 구성, chrony 와 동시에 쓰지 않는 이유, 선택 기준 | NET-4 |
| 4.5 | `/proc` — 프로세스·시스템 정보 파일 | OSM-3 |
| 4.6 | `sysctl` — 런타임 변경과 영구 설정, 설정 파일 적용 순서, 성능·패닉 관련 파라미터 | OSM-3 |
| 4.7 | `/sys` — sysfs 구조와 `/proc` 와의 역할 차이 | OSM-3 |

경계: DB 용 커널 파라미터 값은 17장. 여기서는 바꾸는 방법만 다룬다. PTP 는 제외.

### 5장. 패키지 관리

| 절 | 내용 | 근거 |
|---|---|---|
| 5.1 | RPM 패키지 — 이름 규칙, 의존성, 데이터베이스 위치 | YUM-1 |
| 5.2 | `rpm` — 질의·검증·서명 확인·설치·제거 | YUM-1, MAN |
| 5.3 | yum 구성 — `yum.conf`, `.repo`, `yum.oracle.com`, 릴리스 패키지, `yum-config-manager`, 프록시 | YUM-2 |
| 5.4 | `yum` 명령 — 검색·설치·업데이트·제거, `history`·`undo` | YUM-3 |
| 5.5 | 그룹과 보안 플러그인 — `yum group`, `yum updateinfo` | YUM-4·5 |
| 5.6 | 로컬 저장소 — ISO 로 저장소 만들기, 로컬 yum 서버 | YUM-7·8 |
| 5.7 | 자동 업데이트 — `yum-cron` | YUM-9 |
| 5.8 | ULN — 채널, 등록 절차, RHN·CentOS 에서 전환 | YUM-1·6, ULN |
| 5.9 | 커널 업데이트 — UEK·RHCK 동시 업데이트, `installonly_limit`, UEK 업그레이드 경로, 재부팅 없는 패치 제품(Note) | RN79-6, YUM-2 |

경계: cron 문법은 6장. `yum-cron` 은 설정 파일만.

### 6장. 작업 자동화

| 절 | 내용 | 근거 |
|---|---|---|
| 6.1 | 자동화 도구 비교 — cron, anacron, at, batch, systemd 타이머 | MON-6 |
| 6.2 | cron — `/etc/crontab`, `/etc/cron.d`, `cron.hourly` 등 디렉터리 | MON-6 |
| 6.3 | `crontab` — 사용자 작업, 시간 필드, cron 실행 환경 | MON-6 |
| 6.4 | 접근 제어 — `cron.allow`·`cron.deny` | MON-6 |
| 6.5 | anacron — `/etc/anacrontab`, 지연·실행 시간대, `0anacron` 의 역할 | MON-6 |
| 6.6 | `at`·`batch` — 일회성 작업, 부하 임계값으로 batch 동작 바꾸기 | MON-6 |
| 6.7 | systemd 타이머 — 기존 타이머 읽기, cron 과의 비교 | MAN |

### 7장. 커널 모듈 구성

| 절 | 내용 | 근거 |
|---|---|---|
| 7.1 | 적재 가능 모듈 — `/lib/modules/$(uname -r)`, 커널마다 따로 있는 이유 | OSM-5 |
| 7.2 | 조회 — `lsmod`, `modinfo` | OSM-5 |
| 7.3 | 적재·해제 — `modprobe`, `insmod`·`rmmod`, `depmod` 와 의존성 | OSM-5 |
| 7.4 | 모듈 파라미터 — `/sys/module/*/parameters`, `/etc/modprobe.d` | OSM-5 |
| 7.5 | 부팅 시 적재와 블랙리스트 — `/etc/modules-load.d`, `blacklist`, initramfs 재생성 | OSM-5 |
| 7.6 | weak update 모듈과 UEK·RHCK 의 모듈 차이 | OSM-5, UEK |
| 7.7 | ACFS·ADVM 드라이버 — Oracle 이 커널 밖에서 제공하는 모듈의 예 | OU 목차 (개념만) |

경계: udev 규칙은 17장. ACFS·ADVM 실습은 RAC 과정.

### 8장. 사용자와 그룹 관리

| 절 | 내용 | 근거 |
|---|---|---|
| 8.1 | 계정 파일 — `passwd`·`shadow`·`group`·`gshadow` 필드 | UAU-2 |
| 8.2 | 기본값 — `useradd -D`, `/etc/default/useradd`, `/etc/login.defs`, `/etc/skel` | UAU-2 |
| 8.3 | 생성·변경·삭제·잠금 | UAU-2 |
| 8.4 | 그룹과 UPG — 사용자 전용 그룹, umask, setgid 디렉터리, 삭제 제한 비트 | UAU-2 |
| 8.5 | 암호 정책 — `chage`, `pwquality.conf`, 해시 알고리즘 | UAU-2 |
| 8.6 | PAM 개요 — `/etc/pam.d`, `pam_pwquality`, `pam_faillock` | UAU-1 |
| 8.7 | `su` 와 `sudo` — `sudoers` 문법, `visudo`, 최소 권한, `sudo` 로그 | UAU-2 |
| 8.8 | User Manager(GUI) | OU 목차 (언급만) |

경계: Oracle 소프트웨어 사용자·그룹은 17장. LDAP·NIS·Kerberos 제외.

### 9장. 파티션·파일 시스템·스왑

| 절 | 내용 | 근거 |
|---|---|---|
| 9.1 | 디스크 장치 확인 — `lsblk`, `blkid`, `/dev/disk/by-*` | STO-1 |
| 9.2 | 파티션 테이블 — MBR 과 GPT | STO-1 |
| 9.3 | 파티션 도구 — `fdisk`, `gdisk`, `parted`, 커널에 알리기(`partprobe`), `kpartx` | STO-1 |
| 9.4 | 파일 시스템 종류 — Ext4·XFS·Btrfs 선택 기준 | FS-1 |
| 9.5 | Ext4 — `mkfs.ext4`, `tune2fs`, `dumpe2fs`, 예약 블록 | FS-2 |
| 9.6 | 마운트 — 옵션, `/etc/fstab` 여섯 필드, UUID 와 레이블, 이미지 파일 루프 마운트 | FS-2 |
| 9.7 | 검사와 복구 — `fsck`, 검사 주기 | FS-2 |
| 9.8 | 스왑 — 파티션과 파일, 우선순위, 제거 | STO-1 |

경계: Ext 할당량은 11장에서 XFS 할당량과 비교로. 자동 마운트(autofs)는 14장.

### 10장. LVM 과 RAID

| 절 | 내용 | 근거 |
|---|---|---|
| 10.1 | LVM 구조 — PV·VG·LV·PE, 장치 매퍼 | STO-2 |
| 10.2 | 물리 볼륨과 볼륨 그룹 — 생성·확장·축소, `pvmove` | STO-2 |
| 10.3 | 논리 볼륨 — 생성, 파일 시스템과 함께 늘리기(`-r`), 줄이기 | STO-2 |
| 10.4 | 메타데이터 백업과 복원 — `/etc/lvm/backup`·`archive`, `vgcfgrestore` | STO-2 |
| 10.5 | 스냅샷 — 기존 방식(COW) 스냅샷, 병합으로 되돌리기 | STO-2 |
| 10.6 | thin provisioning — thin pool, 초과 할당, 풀 고갈 | STO-2 |
| 10.7 | `snapper` — thin LV 와 함께 쓰기 | STO-2 |
| 10.8 | 소프트웨어 RAID — `mdadm`, RAID 0·1·5·10, `/proc/mdstat`, `mdadm.conf` | STO-3 |
| 10.9 | RAID 장애와 재구축 — fail·remove·add, 재동기화 관찰 | STO-3 |

경계: LUKS·iSCSI·multipath 제외. XFS 확장 명령의 세부는 11장.

### 11장. XFS 파일 시스템

| 절 | 내용 | 근거 |
|---|---|---|
| 11.1 | XFS 구조 — 할당 그룹, 저널(내부·외부), 쓰기 장벽, lazy counter | FS-5 |
| 11.2 | 생성과 정보 — `mkfs.xfs`, `xfs_info` | FS-5 |
| 11.3 | 수정 — `xfs_admin` 레이블·UUID | FS-5 |
| 11.4 | 확장 — `xfs_growfs`, 축소가 안 되는 이유와 대안 | FS-5 |
| 11.5 | 동결 — `xfs_freeze` 와 스냅샷 | FS-5 |
| 11.6 | 할당량 — 사용자·그룹·프로젝트, `xfs_quota`, Ext 의 `quota` 명령과 비교 | FS-5, FS-2 |
| 11.7 | 백업·복원 — `xfsdump` 레벨, `xfsrestore`, 인벤토리 | FS-5 |
| 11.8 | 조각 모음·검사·복구 — `xfs_fsr`, `xfs_repair`, `xfs_repair -L` 의 위험 | FS-5 |

### 12장. Btrfs 파일 시스템

| 절 | 내용 | 근거 |
|---|---|---|
| 12.1 | Btrfs 와 지원 범위 — UEK 에서만 지원, OL8 이후 상황 | FS-3, UEK |
| 12.2 | 생성 — 단일·다중 장치, 데이터·메타데이터 프로파일 | FS-3 |
| 12.3 | 수정 — 장치 추가·제거·교체, `balance` | FS-3 |
| 12.4 | 압축·조각 모음·크기 조정 | FS-3 |
| 12.5 | 서브볼륨과 스냅샷 — 생성, 기본 서브볼륨, 서브볼륨 마운트 | FS-3 |
| 12.6 | `snapper` 와 Btrfs | FS-3 |
| 12.7 | send/receive — 증분 백업 | FS-3 |
| 12.8 | quota group | FS-3 |
| 12.9 | Ext 에서 변환 — `btrfs-convert`, 되돌리기 | FS-4 |
| 12.10 | Btrfs 루트 파일 시스템 — 설치 옵션, 루트 스냅샷 | FS-3, INS-3 (개념) |

### 13장. 네트워크 구성

| 절 | 내용 | 근거 |
|---|---|---|
| 13.1 | 인터페이스 이름 규칙 — 예측 가능한 이름, `biosdevname`, `net.ifnames` | NET-1 |
| 13.2 | 구성 파일 — `ifcfg-*`, `/etc/hosts`, `nsswitch.conf`, `resolv.conf`, `/etc/sysconfig/network` | NET-1 |
| 13.3 | NetworkManager 와 `network` 서비스 — 누가 파일을 읽고 쓰는가, `NM_CONTROLLED` | NET-1 |
| 13.4 | `nmcli` — 연결과 장치, 고정 IP, 보조 IP | NET-1 |
| 13.5 | `ip` 와 `ethtool` — 런타임 구성과 링크 정보, `ifconfig` 와의 대응 | NET-1 |
| 13.6 | 본딩과 팀 — 모드, 구성, 장애 전환 확인 | NET-1 |
| 13.7 | VLAN | NET-1 (개념) |
| 13.8 | DHCP 클라이언트와 이름 해석 확인 | NET-2 |

경계: DNS 서버, OCI 네트워킹 제외. 방화벽은 16장.

### 14장. 파일 공유

| 절 | 내용 | 근거 |
|---|---|---|
| 14.1 | NFS 개념 — v3·v4 차이, 사용 포트와 서비스 | FS-6 |
| 14.2 | NFS 서버 — `/etc/exports` 옵션, `exportfs`, `nfs-server` | FS-6 |
| 14.3 | NFS 클라이언트 — `mount` 옵션, `fstab`, `showmount` | FS-6 |
| 14.4 | 자동 마운트 — autofs 마스터 맵·간접 맵 | FS-2 |
| 14.5 | vsftpd — 설치, `vsftpd.conf` 주요 지시어, 익명·로컬 사용자 | MAN |
| 14.6 | DB 파일·RMAN 백업을 NFS 에 둘 때의 마운트 옵션 | DBI |

경계: 방화벽 개방 원리는 16장. 여기서는 NFS·FTP 가 필요로 하는 서비스만 연다. Samba 제외.

### 15장. OpenSSH

| 절 | 내용 | 근거 |
|---|---|---|
| 15.1 | OpenSSH 구성 — 패키지, 서버·클라이언트 파일 | SSH-1 |
| 15.2 | 서버 구성 — `sshd_config`, 접근 제한, 권장 설정 | SSH-2 |
| 15.3 | 클라이언트 구성 — `ssh_config`, `~/.ssh/config`, 권한 검사 | SSH-3 |
| 15.4 | 키 쌍 — `ssh-keygen`, 공개 키 배포, `known_hosts` | SSH-4 |
| 15.5 | `ssh`·`scp`·`sftp` | SSH-5 |
| 15.6 | `ssh-agent`·`ssh-add`, 에이전트 포워딩, ProxyJump | SSH-5 |
| 15.7 | 포트 포워딩 | SSH-5 |
| 15.8 | OCI 인스턴스 키 페어 | OU 목차 (Note) |

### 16장. 보안 관리

| 절 | 내용 | 근거 |
|---|---|---|
| 16.1 | 보안 기본 원칙 — 최소 설치·최소 서비스·최소 권한 | SEC-1·2 |
| 16.2 | chroot 와 chroot jail | SEC-4 |
| 16.3 | 패킷 필터링과 netfilter — 테이블·체인 | SEC-4 |
| 16.4 | firewalld — 영역, 서비스, 포트, runtime 과 permanent, rich rule | SEC-4 |
| 16.5 | `firewall-cmd` 와 `firewall-config` | SEC-4 |
| 16.6 | iptables 서비스 — 규칙 조회·삽입·삭제·저장, firewalld 와 함께 쓰지 않는 이유 | SEC-4 |
| 16.7 | TCP Wrappers — `hosts.allow`·`hosts.deny`, 적용되는 서비스 확인 | SEC-2·4 |
| 16.8 | 그 밖의 기본 조치 — 코어 덤프 비활성화, 마운트 옵션(`nodev`·`nosuid`·`noexec`), 불필요한 서비스 정리 | SEC-2 |

경계: SELinux·감사·OpenSCAP 제외. SSH 접근 제한은 15장.

### 17장. Oracle on Oracle: DB 서버 준비

| 절 | 내용 | 근거 |
|---|---|---|
| 17.1 | DB 서버 OS 요건 개관 — 메모리·스왑·`/tmp`·패키지 | DBI |
| 17.2 | Oracle 소프트웨어 사용자와 그룹 — `oinstall`, `dba`, `oper`, `backupdba`, `dgdba`, `kmdba`, `racdba` | DBI |
| 17.3 | `oracle-database-preinstall-19c` — 바꾸는 파일과 값 | DBI, 실측 |
| 17.4 | 공유 메모리 — `shmmax`·`shmall`·`shmmni` 계산 | DBI |
| 17.5 | 세마포어 — `kernel.sem` 네 값 | DBI |
| 17.6 | 파일 핸들·AIO·네트워크 — `fs.file-max`, `fs.aio-max-nr`, 포트 범위, 소켓 버퍼 | DBI |
| 17.7 | 셸 한도 — `limits.d`, `nofile`·`nproc`·`stack`·`memlock` | DBI |
| 17.8 | HugePages 와 THP — 계산, 설정, 확인, THP 끄기 | DBI |
| 17.9 | systemd `RemoveIPC` — 7.9 알려진 문제 | RN79-5 |
| 17.10 | 디스크 준비 — udev 규칙과 ASMLib v2 | OSM-4, ASML |

경계: Clusterware 요건은 RAC 3장. DB 설치 자체는 ADMIN 과정.

### 18장. 시스템 모니터링

| 절 | 내용 | 근거 |
|---|---|---|
| 18.1 | 성능 문제 접근 — 자원별 도구 지도 | MON-1 |
| 18.2 | CPU — `top`, `mpstat`, `vmstat` 의 `r`·`us`·`sy`·`wa` | MON-1 |
| 18.3 | 메모리 — `free`, `/proc/meminfo`, `vmstat` 의 `si`·`so` | MON-1 |
| 18.4 | 블록 I/O — `iostat -x` 열, `iotop` | MON-1 |
| 18.5 | 파일 시스템과 네트워크 — `df`, `netstat`·`ss`, `tcpdump` | MON-1 |
| 18.6 | `sar` — sysstat 수집 주기와 이력 조회 | MON-1 |
| 18.7 | `strace` — 시스템 호출 추적 | MAN |
| 18.8 | `sosreport` — 생성, 구성, 지원 요청 | MON-2 |
| 18.9 | OSWatcher Black Box — 설치, 실행, 보관 파일 | MON-3 |
| 18.10 | Spacewalk 와 Oracle Linux Manager | OU 목차 (개요) |

경계: DB 대기 이벤트와의 대응은 Tuning 20장. PCP·Tuned 제외.

### 19장. 시스템 로깅

| 절 | 내용 | 근거 |
|---|---|---|
| 19.1 | 로깅 체계 — 커널·journald·rsyslog 의 흐름 | SEC-2, MAN |
| 19.2 | rsyslog 구성 — `rsyslog.conf`, `rsyslog.d`, facility·priority 셀렉터 | SEC-4 |
| 19.3 | 액션과 템플릿 | SEC-4, MAN |
| 19.4 | 원격 로그 — 수신 서버와 전송 클라이언트, TCP 와 UDP | SEC-4, MAN |
| 19.5 | journald 와 `journalctl` — 필터(유닛·우선순위·시간·부팅) | MAN |
| 19.6 | journald 영구 저장과 용량 제한 | MAN |
| 19.7 | `logrotate` | MAN |
| 19.8 | Logwatch | SEC-4 |

### 20장. 문제 해결

| 절 | 내용 | 근거 |
|---|---|---|
| 20.1 | 두 단계 접근 — 정보 수집과 원인 좁히기 | OU 목차 |
| 20.2 | OS 로그와 `dmesg` | MON-1, MAN |
| 20.3 | 지원 자료 — My Oracle Support, 문서, `sosreport` 제출 | MON-2 |
| 20.4 | 원인 분류 — 하드웨어·커널·구성·자원·사용자 | OU 목차 |
| 20.5 | 부팅 장애 — 단계별 증상 구분, `rd.break`, emergency·rescue 타깃, 설치 매체 rescue 모드 | OSM-1, INS-5 |
| 20.6 | NFS 장애 — 서버·네트워크·권한·방화벽 구분 | FS-6 |
| 20.7 | 커널 패닉과 Kdump | MON-7 (Note) |

---

## 5. 장별 분량 조정 원칙

- 본문 26,000~30,000자. 절이 9~10개인 장(5·10·12·17·18)은 절마다 분량을 줄이고, 절이 7개인 장(1·4·6·7·14·19·20)은 실무 시나리오 상자를 늘린다.
- 공식 문서의 절차를 옮길 때는 명령 순서만 따르고 문장은 새로 쓴다. 출력 예는 문서 것이 아니라 `ol7a` 실측값을 쓴다.
- "7.9 와 8/9 의 차이" 표를 두는 장: 3·4·5·12·13·16·19 (PRD 7.2).

---

## 6. 진행 순서

| 단계 | 내용 | 상태 |
|---|---|---|
| 1 | OL7 문서 PDF 13종 받기, 근거 매핑 | 완료 (2026-11-11) |
| 2 | 챕터 목록(이 문서), 트랜스크립트 주제 목록 | 완료 (2026-11-11) |
| 3 | ISO 확인(완료: 7.9, UEK 5.4.17-2102.201.3) → `ol7a` 설치(2장 캡처) → `ol7b` kickstart 설치 → 스냅샷, PRD 4.5 실측 | |
| 4 | `_ol7_scratch` 에 빌더 복사, 템플릿, `ol7lab.py` | |
| 5 | 트랜스크립트 파일럿 1장 01·9장 03 | |
| 6 | 1장 7종 산출물 파일럿 | |
| 7 | 2~20장 | |
| 8 | 최종실습시험 5세트, 과정 구성 문서 | |
