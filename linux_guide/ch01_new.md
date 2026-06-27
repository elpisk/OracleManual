# Chapter 01 — 리눅스 설치 환경 구성

01   리눅스 설치 환경 구성 

### 1.1 가상머신(VM)이란? 

가상머신은 소프트웨어로 구현된 컴퓨터입니다. 실제 PC 위에서 독립적인 OS를 실행할 수 있어 리

눅스 학습 환경을 안전하게 구성할 수 있습니다. 이 교안은 VMware Workstation Pro 17을 기준으

로 실습 환경을 구성합니다. 

주요 가상화 소프트웨어 비교 

소프트웨어 

특징 

비고 

VMware Workstation Pro  

기업·실무 표준, 고성능, 2024년부터 개

★ 이 교안 사용 

17 

인 무료 

VirtualBox 

Oracle 제공, 무료, 오픈소스 

대안 환경 

Hyper-V 

UTM 

Windows 10/11 Pro 내장, 무료 

대안 환경 

macOS Apple Silicon 전용 

대안 환경 

Note:  VMware Workstation Pro 17은 2024년부터 개인(비상업) 사용에 한해 무료로 제공됩니

다. Broadcom 계정 가입 후 다운로드할 수 있습니다. 

### 1.2 VMware Workstation Pro 17 설치 

다운로드 

1.  https://www.broadcom.com 접속 후 로그인 (Broadcom 계정 필요) 

2.  VMware > VMware Workstation Pro 메뉴 선택 

3.  버전 17.x (Windows 용) 다운로드 

4.  VMware-workstation-full-17.x.x-xxxxx.exe 실행

설치 절차 

5.  설치 마법사 시작 → Next 

6.  EULA(최종 사용자 라이선스 동의) 체크 → Next 

7.  설치 경로 확인 (기본값 권장): C:\Program Files (x86)\VMware 

8.  User Experience Settings: 체크 해제 권장 (사용 데이터 전송 옵션) 

9.  Shortcuts: 바탕화면 아이콘 생성 체크 → Next 

10.  Install 클릭 → 설치 완료 → Finish 

11.  라이선스 키 입력 화면: "Use VMware Workstation 17 for free for non-commercial use" 선택 

Tip:  설치 후 재부팅이 필요할 수 있습니다. VMware Tools 설치는 VM 생성 후 자동 제안됩니

다. 

### 1.3 Oracle Linux ISO 다운로드 

12.  https://www.oracle.com/linux 접속 

13.  Oracle Linux 9 → x86_64 → DVD ISO 선택 (약 8~9GB) 

14.  또는 Minimal ISO 선택 (약 1.5GB, CLI 서버 실습용 권장) 

```bash
# ISO 파일명 예시 
```
OracleLinux-R9-U3-x86_64-dvd.iso         ← DVD (전체 패키지) 
OracleLinux-R9-U3-x86_64-boot.iso        ← Boot (네트워크 설치) 

### 1.4 VMware 에서 가상머신 생성 

새 VM 생성 마법사 

15.  VMware Workstation Pro 17 실행 

16.  File → New Virtual Machine (또는 Ctrl+N) 

17.  구성 유형: "Typical (recommended)" 선택 → Next 

18.  설치 미디어: "I will install the operating system later" 선택 → Next

19.  게스트 OS: Linux → Red Hat Enterprise Linux 9 64-bit 선택 → Next 

20.  VM 이름 입력 (예: OracleLinux9) 및 저장 경로 지정 → Next 

21.  디스크 크기 설정 → Finish 

VM 권장 사양 

항목 

설정값 

VM 이름 

OracleLinux9 (또는 원하는 이름) 

게스트 OS 

Red Hat Enterprise Linux 9 64-bit 

프로세서 

2 CPU × 2 코어 이상 권장 

메모리(RAM) 

4096 MB (최소 2048 MB) 

하드디스크 

50 GB 이상 (동적 프로비저닝 권장) 

네트워크 

NAT (기본값) 또는 Bridged 

디스플레이 

자동 감지 (VMware Tools 설치 후 자동 조정) 

ISO 파일 연결 

22.  생성된 VM 선택 → "Edit virtual machine settings" 

23.  CD/DVD (SATA) → "Use ISO image file" 선택 

24.  Browse → 다운로드한 OracleLinux ISO 파일 선택 

25.  OK 클릭 후 VM 시작 

### 1.5 VMware 네트워크 모드 비교 

명령어 

설명 

사용 예 

NAT 

VMware가 내부 네트워크 구성, 호스트

학습·실습 환경 (기본값 권장) 

 IP 공유, 외부→VM 직접 접속 불가

명령어 

설명 

사용 예 

Bridged 

호스트 네트워크에 직접 연결, VM이 

서버 서비스 실습, SSH 직접 접속 

독립 IP 획득 

Host-only 

호스트-VM 간 내부 통신만 가능, 외부 

격리 테스트, 보안 실습 

인터넷 차단 

Custom 

VMnet 번호 직접 지정, 다중 VM 구성  네트워크 구성 실습 

Note:  Oracle Linux 실습에서는 기본값인 NAT 모드를 사용합니다. SSH 원격 접속 실습이 필

요하면 Bridged 모드로 변경하세요. 

### 1.6 VMware Tools 설치 (권장) 

VMware Tools를 설치하면 화면 자동 크기 조정, 클립보드 공유, 드래그 앤 드롭 파일 전송 등의 기

능을 사용할 수 있습니다. 

```bash
# Oracle Linux 9에서 VMware Tools 설치 
$ sudo dnf install open-vm-tools -y 
$ sudo systemctl enable --now vmtoolsd 
```


```bash
# 설치 확인 
$ vmware-toolbox-cmd --version 
```
VMware Tools daemon version: 12.x.x 

📝 연습문제 

번호  문제 

정답 

Q1 

VMware Workstation Pro 17의 개인 사용 

2024년부터 개인(비상업) 무료 

비용은? 

Q2 

VM 생성 시 권장 메모리는? 

4096MB (최소 2048MB) 

Q3 

외부 인터넷은 되지만 외부에서 VM으로 직 NAT

번호  문제 

정답 

접 접속이 어려운 네트워크 모드? 

Q4 

Oracle Linux ISO 공식 다운로드 사이트? 

oracle.com/linux 

Q5 

VMware 화면 크기 자동 조정을 위해 설치

VMware Tools (open-vm-tools) 

해야 하는 것?