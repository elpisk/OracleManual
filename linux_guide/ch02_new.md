# Chapter 02 — Oracle Linux 설치

02   Oracle Linux 설치 — 다운로드부터 초기 설정까지 

Note:  이 챕터는 Oracle Linux 8/9를 VMware Workstation Pro 17에 설치하는 전 과정을 단계

별로 안내합니다. ISO 다운로드 → VM 생성 → 설치 → 초기 설정 → 시스템 업데이트까지 모

두 다룹니다. 

### 2.1 Oracle Linux ISO 다운로드 

Oracle Linux ISO는 두 가지 공식 경로에서 다운로드할 수 있습니다. 실습 목적에 맞는 경로를 선택

하세요. 

경로 1 — Oracle Software Delivery Cloud (edelivery) 

기업 환경·공식 릴리즈 전체 패키지가 필요할 때 사용합니다. Oracle 계정이 필요합니다. 

26.  https://edelivery.oracle.com 접속 후 Oracle 계정으로 로그인 

27.  검색창에 "Oracle Linux" 입력 → 원하는 버전 선택 

28.  "Oracle Linux 8" 또는 "Oracle Linux 9" 선택 → 플랫폼: x86 64-bit 

29.  Continue → 라이선스 동의 체크 → Download 클릭 

30.  ISO 파일 다운로드 (Oracle Linux 8: V1000019-01.iso 등) 

경로 2 — Oracle Linux 공식 사이트 (권장·간편) 

31.  https://www.oracle.com/linux 접속 (Oracle 계정 불필요) 

32.  Oracle Linux 8 또는 Oracle Linux 9 선택 

33.  x86_64 → DVD ISO 또는 Minimal ISO 선택 

34.  다운로드 시작 

ISO 종류 

크기 

특징 

DVD ISO 

약 8~9  

전체 패키지 포함. GUI·서버 환경 모두 설치 가능. 오프라인 설치 가

ISO 종류 

크기 

특징 

GB 

능 

Minimal  

약 1~2  

CLI 최소 구성. 설치 후 필요 패키지 개별 설치. 서버 실습 권장 

ISO 

GB 

Boot ISO 

약 600  

네트워크 설치용. 인터넷에서 패키지를 받아 설치 

MB 

```bash
# ISO 파일명 예시 
```
OracleLinux-R8-U9-x86_64-dvd.iso      ← Oracle Linux 8 DVD 
OracleLinux-R9-U3-x86_64-dvd.iso      ← Oracle Linux 9 DVD 
OracleLinux-R8-U9-x86_64-boot.iso     ← Oracle Linux 8 Boot 

버전 

출시·지원 종료 

주요 특징 

Oracle Linux 8 

2019~ / 지원 2029년 

Python 3.6·3.8, UEK R6, 안정적 LTS 환경 

Oracle Linux 9 

2022~ / 지원 2032년 

Python 3.9·3.11, UEK R7, 최신 표준 권장 

Note:  이 교안의 실습 예제는 Oracle Linux 8 기준으로 작성되었으며 Oracle Linux 9에서도 동

일하게 동작합니다. 

### 2.2 VMware Workstation Pro 17 설치 

다운로드 

35.  https://www.broadcom.com 접속 후 Broadcom 계정으로 로그인 

36.  상단 메뉴 Software → VMware Cloud Foundation → VMware Workstation Pro 

37.  버전 17.x.x (Windows 용) 선택 → 다운로드 

38.  VMware-workstation-full-17.x.x-xxxxx.exe 저장 

설치 절차

39.  다운로드한 .exe 파일 실행 (관리자 권한) 

40.  설치 마법사 시작 → Next 

41.  EULA 라이선스 동의 체크 → Next 

42.  설치 경로 확인 (기본값 권장) → Next 

43.  User Experience Settings: 체크 해제 권장 → Next 

44.  Shortcuts: 바탕화면 아이콘 생성 체크 → Next → Install 

45.  설치 완료 → Finish → 재부팅 

46.  첫 실행 시 라이선스 선택: "Use VMware Workstation 17 for free for non-commercial use" 

Note:  VMware Workstation Pro 17은 2024년부터 개인(비상업) 사용에 한해 무료입니다. 상

업적 용도는 유료 라이선스가 필요합니다. 

### 2.3 VMware 에서 가상머신(VM) 생성 

새 VM 생성 마법사 

47.  VMware Workstation Pro 17 실행 

48.  File → New Virtual Machine (단축키: Ctrl+N) 

49.  구성 유형: "Typical (recommended)" 선택 → Next 

50.  설치 미디어: "I will install the operating system later" 선택 → Next 

51.  게스트 OS: Linux 선택 → 버전: Red Hat Enterprise Linux 8 64-bit (OL8) 또는 9 64-bit (OL9) 

52.  VM 이름 입력 (예: OracleLinux8) 및 저장 경로 지정 → Next 

53.  디스크 용량 설정 (50GB 이상 권장) → "Store virtual disk as a single file" → Next → Finish 

VM 권장 사양 

항목 

설정값 

VM 이름 

OracleLinux8 (또는 원하는 이름)

항목 

설정값 

게스트 OS 

Red Hat Enterprise Linux 8 64-bit 

프로세서 

2 vCPU × 2 코어 이상 권장 

메모리(RAM) 

4096 MB 권장 (GUI 환경 / 최소 2048 MB) 

하드디스크 

50 GB 이상 (동적 프로비저닝) 

네트워크 

NAT (기본값) — 인터넷 연결 확인 필수 

CD/DVD 

다운로드한 OracleLinux ISO 파일 연결 

ISO 파일 연결 

54.  생성된 VM 선택 → "Edit virtual machine settings" (단축키: Ctrl+D) 

55.  Hardware 탭 → CD/DVD (SATA) 클릭 

56.  "Use ISO image file" 선택 → Browse → 다운로드한 ISO 파일 선택 

57.  OK 클릭 → VM 시작 준비 완료 

네트워크 모드 비교 

명령어 

설명 

사용 예 

NAT 

호스트 IP 공유, 외부→VM 직접 접속 

학습·실습 환경 (기본값 권장) 

불가 

Bridged 

호스트 네트워크에 직접 연결, 독립 IP 

서버 서비스 실습, SSH 직접 접속 

획득 

Host-only 

호스트-VM 내부 통신만, 인터넷 차단 

격리 테스트, 보안 실습 

Custom 

VMnet 직접 지정, 다중 VM 구성 

네트워크 구성 실습 

### 2.4 Oracle Linux 설치 시작

VM 전원을 켜면 Oracle Linux 설치 부팅 화면이 나타납니다. 설치 초기 단계에서 언어와 로케일(Loc

ale)을 먼저 설정합니다. 

58.  VMware 에서 해당 VM 선택 → "Power on this virtual machine" 클릭 

59.  부팅 메뉴: "Install Oracle Linux 8.x" 선택 → Enter 

60.  언어(Language) 선택 화면 

언어 선택 화면 
  왼쪽: 언어 목록 → "Korean" 또는 "English" 선택 
  오른쪽: 지역 선택 → "한국어" 또는 "English (United States)" 
  → 계속(Continue) 클릭 

Tip:  언어를 한국어로 설정하면 설치 화면이 한글로 표시됩니다. 이후 터미널 환경은 영어가 

권장됩니다. 

### 2.5 시스템 설정 — 허브 앤 스포크(Hub and Spoke) 모델 

언어 선택 후 나타나는 "설치 요약(Installation Summary)" 화면이 Oracle Linux 설치의 핵심입니다. 

이 화면은 허브 앤 스포크(Hub and Spoke) 모델 구조로, 중앙 허브(설치 요약)에서 각 설정 항목(스

포크)을 자유로운 순서로 구성합니다. 

┌─────────────────── 설치 요약 (Hub) ─────────────────────┐ 
│                                                        │ 
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │ 
│  │  로케이션    │  │  소프트웨어    │  │   시스템       │  │ 
│  │             │  │              │  │               │  │ 
│  │ • 키보드     │  │ • 설치 소스   │  │ • 설치 목적지   │  │ 
│  │ • 언어 지원  │  │ • 소프트웨어   │  │ • KDUMP       │  │ 
│  │ • 시간/날짜  │  │   선택        │  │ • 네트워크     │  │ 
│  └─────────────┘  └──────────────┘  │ • 보안 정책    │  │ 
│                                      └───────────────┘  │ 
│  ┌────────────────────────────────────────────────────┐ │ 
│  │                   사용자 설정                        │ │ 
│  │        • 루트 암호     • 사용자 생성                  │ │ 
│  └────────────────────────────────────────────────────┘ │ 
│                                                         │ 
│              [설치 시작(Begin Installation)]              │ 
└─────────────────────────────────────────────────────────┘

① 키보드 및 언어 지원 

항목 

키보드 

설정 내용 

기본 English (US) 유지 권장. 필요 시 한국어 추가 가능 

언어 지원 

한국어 추가 시 한글 입력·폰트 자동 설치 

② 시간 및 날짜 

61.  "시간 및 날짜" 클릭 

62.  지역: 아시아 → 도시: 서울 선택 

63.  네트워크 시간(NTP) 활성화 권장 → 완료(Done) 

③ 소프트웨어 선택 

"소프트웨어 선택(Software Selection)" 에서 설치할 환경(기본 환경)을 선택합니다. 

기본 환경 

설명 

Server with GUI 

GNOME 데스크탑 포함 서버 환경. 학습자 및 GUI 실습 권장 ★ 

Server 

GUI 없는 서버 환경. 실무 서버 구성에 적합 

Minimal Install 

최소 구성. 가장 가볍고 빠름. CLI 숙련자용 

Workstation 

개발·데스크탑 용도. 개발 도구 포함 

Tip:  "Server with GUI"를 선택하면 GNOME 데스크탑과 기본 서버 도구가 함께 설치됩니다. 

처음 학습하는 경우 이 옵션을 권장합니다. 

④ 설치 대상 (디스크 파티션) 

64.  "설치 목적지(Installation Destination)" 클릭 

65.  VMware 가상 디스크가 자동 감지되어 표시됨 

66.  스토리지 구성: "자동(Automatic)" 선택 (입문자 권장)

67.  "완료(Done)" 클릭 

파티션 방식 

설명 

자동(Automatic) 

전체 디스크를 OS가 자동 파티션. 입문자·실습 환경 권장 

수동(Manual) 

파티션 크기·마운트 포인트 직접 지정. 운영 서버 환경 

⑤ 네트워크 및 호스트명 

68.  "네트워크 및 호스트 이름(Network & Host Name)" 클릭 

69.  이더넷(ens33 또는 ens160) 스위치 → ON 으로 전환 

70.  하단 호스트 이름 입력 (예: ol8.local) → 적용(Apply) 

71.  "완료(Done)" 클릭 

```bash
# 호스트명 예시 
```
ol8.local       ← Oracle Linux 8 학습 환경 
oracle-dev      ← Oracle DB 개발 환경 
db01.example.com ← 운영 서버 형식 

⑥ 보안 정책 (선택사항) 

"보안 정책(Security Policy)" 항목은 학습 환경에서는 기본값(No profile selected) 유지를 권장합니

다. 기업 환경에서는 CIS Benchmark 또는 STIG 프로파일을 적용합니다. 

⑦ 루트 암호 및 사용자 생성 

설치 시작 전 루트(root) 암호 설정과 일반 사용자 계정 생성이 필요합니다. 

항목 

설정 내용 

루트 암호 

영문 대소문자 + 숫자 + 특수문자 조합. 8자 이상 권장. 잊지 말 것 

사용자 생성 

사용자명·전체이름·암호 입력. "이 사용자를 관리자로 지정" 반드시 체크 ★ 

```bash
# 사용자 생성 예시 
```
이름(Full name): Oracle Student 
사용자명(Username): oracle

암호: ******** 
☑ 이 사용자를 관리자로 지정  ← 반드시 체크 (sudo 권한 자동 부여) 

### 2.6 설치 진행 및 완료 

모든 항목 설정 완료 후 "설치 시작(Begin Installation)" 버튼이 활성화됩니다. 

72.  "설치 시작(Begin Installation)" 클릭 → 파일 복사 및 패키지 설치 시작 

73.  설치 진행 중 루트 암호·사용자 계정을 아직 설정하지 않았다면 이 화면에서 설정 

74.  Server with GUI 기준 약 10~20 분 소요 (VM 성능에 따라 다름) 

75.  "설치 완료(Complete!)" 메시지 → "시스템 재시작(Reboot System)" 클릭 

76.  재부팅 후 Oracle Linux 부팅 화면 표시 

주의:  설치 중 VMware 창을 닫거나 VM을 강제 종료하지 마세요. 파일시스템이 손상될 수 있

습니다. 

### 2.7 최초 부팅 및 초기 설정 (GNOME) 

Server with GUI 설치 시 최초 부팅 후 GNOME 초기 설정 마법사(Initial Setup)가 실행됩니다. 

77.  "라이선스 정보(License Information)" 클릭 → Oracle Linux 라이선스 동의 체크 → 완료 

78.  "사용자 설정(User Settings)" → 앞서 생성한 사용자로 로그인 

79.  GNOME 초기 환경 설정 마법사 

GNOME 초기 설정 마법사 순서: 
  1. Privacy (개인 정보 보호) — 위치 공유 OFF 권장 
  2. Online Accounts (온라인 계정) — 건너뜀(Skip) 가능 
  3. 준비 완료 → "Start Using Oracle Linux" 클릭 

터미널 열기 

```bash
# GNOME 데스크탑에서 터미널 열기
```


방법 1: 바탕화면 우클릭 → "터미널 열기(Open Terminal)" 
방법 2: 활동(Activities) → 터미널 검색 
방법 3: 단축키 Ctrl + Alt + T (설정 필요) 

### 2.8 설치 확인 명령어 

```bash
# OS 버전 확인 
$ cat /etc/oracle-release 
```
Oracle Linux Server release 8.9 

```bash
# 커널 버전 확인 
$ uname -r 
```
5.15.0-206.153.7.1.el8uek.x86_64 

```bash
# 현재 사용자 확인 
$ whoami 
```
oracle 

```bash
# 호스트명 확인 
$ hostname 
```
ol8.local 

```bash
# 네트워크 인터페이스 및 IP 확인 
$ ip addr show ens33 
```
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> 
    inet 192.168.xxx.xxx/24 

```bash
# 디스크 사용량 확인 
$ df -h / 
```
Filesystem      Size  Used Avail Use% Mounted on 
/dev/sda3        45G  6.2G   39G  14% / 

### 2.9 시스템 업데이트 — sudo dnf upgrade 

설치 직후 반드시 시스템을 최신 상태로 업데이트합니다. 보안 패치와 버그 수정이 포함됩니다. 

```bash
# 시스템 전체 업데이트 (권장) 
$ sudo dnf upgrade -y 
```


마지막 메타데이터 만료 확인: ... 
종속성 해결 중... 
패키지 설치/업그레이드 중... 
완료되었습니다!

```bash
# 업데이트 내용만 확인 (실제 설치 없음) 
$ sudo dnf check-update 
```


```bash
# 보안 업데이트만 설치 
$ sudo dnf upgrade --security -y 
```


```bash
# 업데이트 후 재부팅 (커널 업데이트 시 필요) 
$ sudo reboot 
```


명령어 

설명 

```bash
dnf upgrade 
```


```bash
dnf update 
```


설치된 모든 패키지를 최신 버전으로 업그레이드 

upgrade 와 동일 (하위 호환 명령어) 

```bash
dnf check-update 
```


업데이트 가능한 패키지 목록만 조회 (실제 설치 안 함) 

```bash
dnf upgrade --securi
```
ty 

보안 패치만 선택적으로 설치 

Tip:  dnf upgrade 는 설치 직후 1회, 이후 월 1회 이상 정기적으로 실행하는 것을 권장합니다. 

### 2.10 VMware Tools 설치 

VMware Tools(open-vm-tools)를 설치하면 화면 자동 크기 조정, 클립보드 공유, 드래그 앤 드롭 파

일 전송 기능을 사용할 수 있습니다. 

```bash
$ sudo dnf install open-vm-tools -y 
$ sudo systemctl enable --now vmtoolsd 
```


```bash
# 설치 확인 
$ systemctl status vmtoolsd 
```
● vmtoolsd.service - Service for virtual machines hosted on VMware 
     Active: active (running) 

```bash
$ vmware-toolbox-cmd --version 
```
VMware Tools daemon version: 12.x.x 

### 2.11 스냅샷 생성 — 복구 지점 확보

설치와 초기 설정이 완료된 상태에서 스냅샷을 생성해 둡니다. 이후 실습 중 문제가 발생하면 이 시

점으로 즉시 복구할 수 있습니다. 

VMware 메뉴: VM → Snapshot → Take Snapshot 

  스냅샷 이름: "Clean Install + Updated" 
  설명: "Oracle Linux 8 설치 완료, dnf upgrade 적용, VMware Tools 설치" 

  → Take Snapshot 클릭 

```bash
# 스냅샷 복구 방법 
```
VM → Snapshot → Snapshot Manager 
  → 원하는 스냅샷 선택 → Go To 

Tip:  실습 단계마다 스냅샷을 남겨두면 실수 없이 안전하게 학습할 수 있습니다. 

### 2.12 sudo 설정 확인 

설치 시 "관리자로 지정" 체크를 한 경우 자동으로 wheel 그룹에 포함됩니다. 설치 후 다음 명령으로

 확인합니다. 

```bash
# 현재 사용자의 그룹 확인 
$ id 
```
uid=1000(oracle) gid=1000(oracle) groups=1000(oracle),10(wheel) 
                                                          ↑ wheel 포함 확인 

```bash
# sudo 동작 확인 
$ sudo whoami 
```
root 

```bash
# wheel 그룹에 없는 경우 — root에서 추가 
$ su - 
# usermod -aG wheel oracle 
# exit 
```


📝 연습문제

번호  문제 

정답 

Q1 

Oracle Linux ISO를 다운로드할 수 있는 두 가

edelivery.oracle.com, oracle.com/linux 

지 공식 경로는? 

Q2 

오프라인 설치가 가능하고 전체 패키지가 포

DVD ISO 

함된 ISO 종류는? 

Q3 

설치 화면에서 허브 앤 스포크 모델을 사용하

설치 요약(Installation Summary) 

는 화면의 이름은? 

Q4 

GUI 학습 환경 구성 시 소프트웨어 선택에서 

Server with GUI 

고르는 옵션은? 

Q5 

설치 시 사용자를 관리자로 지정하면 어떤 그

wheel 그룹 

룹에 추가되는가? 

Q6 

OS 버전을 확인하는 파일 경로는? 

/etc/oracle-release 

Q7 

시스템 전체 패키지를 최신으로 업데이트하

```bash
sudo dnf upgrade -y 
```


는 명령어는? 

Q8 

VMware 화면 자동 크기 조정을 위해 설치하

open-vm-tools 

는 패키지는? 

Q9 

설치 직후 복구 지점을 만드는 VMware 기능

Snapshot (스냅샷) 

은? 

Q10  현재 사용자가 wheel 그룹에 포함되어 있는지

id 

 확인하는 명령어? 

📝 실습 

80.  edelivery.oracle.com 또는 oracle.com/linux 에서 Oracle Linux 8 Minimal ISO 다운로드 

81.  VMware Workstation Pro 17 에서 새 VM 생성 (4GB RAM, 50GB 디스크) 

82.  ISO 연결 후 VM 시작 → 언어 선택 → 설치 요약 화면 진입 

83.  허브 앤 스포크 모델로 순서대로 설정: 키보드 → 시간 → 소프트웨어(Server with GUI) → 

디스크 → 네트워크(호스트명: ol8.local) → 사용자

84.  설치 시작 → 완료 후 재부팅 

85.  GNOME 초기 설정 마법사 완료 → 라이선스 동의 

86.  터미널 열기 → cat /etc/oracle-release 로 설치 확인 

87.  sudo dnf upgrade -y 실행 → 시스템 업데이트 

88.  sudo dnf install open-vm-tools -y → VMware Tools 설치 

89.  VM → Snapshot → Take Snapshot → "Clean Install" 스냅샷 생성