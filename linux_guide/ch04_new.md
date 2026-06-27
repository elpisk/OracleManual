# Chapter 04 — 리눅스 아키텍처와 커널(Kernel) 관리

04   리눅스 아키텍처와 커널(Kernel) 관리 

Note:  이 챕터는 Oracle Linux 시스템을 기준으로 커널 구조와 실무 관리 방법을 다룹니다. 

### 4.1 리눅스 아키텍처 기본 구조   

리눅스 시스템은 하드웨어 위에 커널 공간(Kernel Space)과 사용자 공간(User Space)의 두 계층으로

 분리된 구조를 가집니다. 이 분리를 통해 커널은 하드웨어를 독점적으로 제어하면서도 사용자 프로

그램의 오류나 악성 동작으로부터 시스템 안정성을 보장합니다. 

┌─────────────────────────────────────────────┐ 
│            User Space (사용자 공간)           │ 
│  ┌─────────┐  ┌──────────┐  ┌───────────┐   │ 
│  │  Shell  │  │  Apps    │  │  Utilities│   │ 
│  │  (bash) │  │ (Oracle) │  │ (ls, ps)  │   │ 
│  └────┬────┘  └────┬─────┘  └─────┬─────┘   │ 
│       │             │               │       │ 
│       └─────────────┴───────────────┘       │ 
│                     │ System Call           │ 
├─────────────────────┼────────────────────── ┤ 
│            Kernel Space (커널 공간            │ 
│  ┌──────────┐  ┌──────────┐  ┌────────────┐ │ 
│  │ Process  │  │  Memory  │  │ File System│ │ 
│  │ Manager  │  │ Manager  │  │  Manager   │  
│  └──────────┘  └──────────┘  └────────────┘ │ 
│  ┌────────────────────────────────────────┐ │ 
│  │          Device Drivers (장치 드라이버   │ │ 
│  └────────────────────────────────────────┘ │ 
├─────────────────────────────────────────────┤ 
│      Hardware (CPU · Memory · Disk · NIC)   │ 
└─────────────────────────────────────────────┘ 

커널 공간 (Kernel Space) 

운영체제 핵심 코드가 실행되는 특권(Privileged) 영역입니다. 하드웨어 자원을 직접 제어하며, 잘못

된 접근으로부터 보호됩니다. 

커널 기능 

설명 

프로세스 관리 

프로세스 생성·종료·스케줄링, CPU 시간 배분

커널 기능 

설명 

메모리 관리 

가상 메모리, 페이지 할당, 스왑 관리 

파일 시스템 

VFS(가상 파일시스템), ext4/xfs/nfs 지원 

장치 드라이버 

하드웨어(디스크, NIC, GPU) 제어 모듈 

네트워크 스택 

TCP/IP 프로토콜 처리 

보안/IPC 

SELinux, 프로세스 간 통신(소켓·파이프·신호) 

사용자 공간 (User Space) 

일반 프로세스가 실행되는 제한된 영역입니다. 하드웨어에 직접 접근할 수 없으며, 커널의 허가된 

인터페이스(System Call)를 통해서만 하드웨어 자원을 사용할 수 있습니다. 

• 

Shell (bash, zsh) — 명령어 해석 및 실행 

•  Application — Oracle DB, 웹 서버, 사용자 프로그램 

•  Utilities — ls, ps, top 등 시스템 유틸리티 

•  라이브러리(glibc) — System Call 래퍼 제공 

### 4.2 상호작용 방식 — 시스템 호출(System Call)   

사용자 공간의 프로그램이 하드웨어(파일 읽기, 네트워크 전송 등)에 접근해야 할 때, 직접 접근이 

아닌 커널에 서비스를 요청하는 시스템 호출(System Call)을 사용합니다. 

사용자 프로그램          커널                    하드웨어 

```bash
  cat file.txt   ──→  sys_open()   ──→   디스크 I/O 
```
                       sys_read()           
                       sys_close()          

```bash
  ls -la         ──→  sys_getdents()──→  디렉터리 읽기 
```


  ping 8.8.8.8   ──→  sys_socket()  ──→  NIC 전송 
                       sys_sendto()

주요 시스템 호출 분류 

분류 

주요 System Call 

파일 관련 

open, read, write, close, stat, lseek 

프로세스 관련 

fork, exec, exit, wait, getpid 

메모리 관련 

mmap, brk, munmap 

네트워크 관련 

socket, bind, listen, connect, send, recv 

신호(Signal) 

kill, signal, sigaction 

Tip:  strace 명령어로 프로그램이 실행 중 어떤 System Call을 호출하는지 추적할 수 있습니다:

 strace ls -la 

### 4.3 커널 관리 실습 1 — 현재 커널 버전 확인  

uname 명령어로 현재 부팅된 커널 버전을 확인합니다. 

```bash
$ uname -r 
```
5.15.0-206.153.7.1.el9uek.x86_64 

```bash
$ uname -a 
```
Linux ol9 5.15.0-206.153.7.1.el9uek.x86_64 #2 SMP ... 
       |       |__________________________________| 
   호스트명              커널 버전 

커널 버전 번호 해석 

구성요소 

의미 

5 

15 

0 

메이저 버전 (Major Version) 

마이너 버전 (Minor Version) — 짝수: 안정, 홀수: 개발 

패치 레벨 (Patch Level) 

206 

빌드 번호

구성요소 

의미 

el9uek 

x86_64 

배포판 태그 — el9: RHEL9계열, uek: Oracle UEK 커널 

아키텍처 (64비트 Intel/AMD) 

uname 주요 옵션 

명령어 

설명 

uname -r 

uname -a 

uname -s 

uname -m 

uname -n 

uname -v 

커널 버전만 출력 (가장 자주 사용) 

시스템 전체 정보 (커널·호스트명·아키텍처) 

커널 이름 (Linux) 

하드웨어 아키텍처 (x86_64) 

네트워크 호스트명 

커널 빌드 날짜 

### 4.4 커널 관리 실습 2 — 설치된 커널 목록 확인 

/boot 디렉터리에는 시스템에 설치된 모든 커널 이미지가 저장됩니다. vmlinuz* 파일이 커널 이미지

입니다. 

```bash
# /boot 디렉터리 커널 파일 확인 
$ ls -la /boot/vmlinuz* 
```
-rwxr-xr-x. 1 root root 12524176 Feb  3 vmlinuz-5.15.0-200.el9uek.x86_64 
-rwxr-xr-x. 1 root root 12698432 Apr 15 vmlinuz-5.15.0-206.el9uek.x86_64 

```bash
# 관련 파일 전체 확인 (initramfs, System.map 포함) 
$ ls /boot/ 
```
config-5.15.0-200.el9uek.x86_64 
initramfs-5.15.0-200.el9uek.x86_64.img 
initramfs-5.15.0-206.el9uek.x86_64.img 
System.map-5.15.0-206.el9uek.x86_64 
vmlinuz-5.15.0-200.el9uek.x86_64 
vmlinuz-5.15.0-206.el9uek.x86_64

/boot 주요 파일 역할 

파일 

역할 

vmlinuz-* 

압축된 커널 이미지 (부팅 시 메모리에 로드) 

initramfs-*.img 

초기 RAM 디스크 — 부팅 초기 단계 드라이버 포함 

System.map-* 

커널 심볼 주소 테이블 (디버깅용) 

config-* 

grub2/ 

커널 컴파일 설정 파일 

GRUB2 부트로더 설정 디렉터리 

```bash
dnf 으로 커널 목록 확인 
```


```bash
# 설치된 커널 패키지 목록 
$ rpm -qa kernel* | sort 
```
kernel-5.15.0-200.153.5.3.el9uek.x86_64 
kernel-5.15.0-206.153.7.1.el9uek.x86_64 
kernel-uek-5.15.0-206.153.7.1.el9uek.x86_64 

```bash
# dnf 방식 
$ dnf list installed kernel* 
```


### 4.5 커널 관리 실습 3 — 기본 부팅 커널 변경  

여러 커널이 설치된 경우, grubby 명령어를 사용하여 다음 부팅 시 사용할 기본 커널을 지정할 수 

있습니다. 

현재 기본 커널 확인 

```bash
$ sudo grubby --default-kernel 
```
/boot/vmlinuz-5.15.0-206.153.7.1.el9uek.x86_64 

```bash
# 또는 grub 인덱스로 확인 
$ sudo grubby --default-index 
```
0 

모든 부팅 엔트리 목록 확인

```bash
$ sudo grubby --info=ALL 
```
index=0 
kernel="/boot/vmlinuz-5.15.0-206.153.7.1.el9uek.x86_64" 
args="ro crashkernel=512M-:256M rd.lvm.lv=ol/root ..." 
root="/dev/mapper/ol-root" 
title="Oracle Linux Server (5.15.0-206) UEK" 

index=1 
kernel="/boot/vmlinuz-5.15.0-200.153.5.3.el9uek.x86_64" 
title="Oracle Linux Server (5.15.0-200) UEK" 

기본 커널 변경 

```bash
# 커널 파일 경로로 지정 
$ sudo grubby --set-default=/boot/vmlinuz-5.15.0-200.153.5.3.el9uek.x86_64 
```


```bash
# 인덱스 번호로 지정 
$ sudo grubby --set-default-index=1 
```


```bash
# 변경 확인 
$ sudo grubby --default-kernel 
```
/boot/vmlinuz-5.15.0-200.153.5.3.el9uek.x86_64 

```bash
# 변경 적용을 위해 재부팅 
$ sudo reboot 
```


주의:  커널 변경 후 반드시 재부팅해야 적용됩니다. Oracle RAC·Data Guard 환경에서는 노드

별 순차 재부팅을 권장합니다. 

Oracle UEK vs RHCK 커널 

커널 종류 

특징 

UEK 

Oracle 자체 개발 커널 

(Unbreakable Enterprise Ke

Oracle DB 최적화, 최신 기능 포함 

rnel) 

RHCK 

권장 커널 

RHEL 호환 커널 

(Red Hat Compatible Kern

Red Hat 인증 소프트웨어 호환성 

el) 

필요 시 사용

### 4.6 커널 모듈 관리 

커널 모듈은 필요에 따라 동적으로 로드/언로드할 수 있는 커널 확장 코드입니다. 

```bash
# 현재 로드된 모듈 목록 
$ lsmod 
```
Module                  Size  Used by 
nf_conntrack          180224  2 nf_nat,nf_conntrack_netlink 
xfs                  1896448  3 

```bash
# 특정 모듈 로드 
$ sudo modprobe <모듈명> 
$ sudo modprobe bonding     # 본딩(NIC 이중화) 모듈 로드 
```


```bash
# 모듈 정보 확인 
$ modinfo xfs 
```


```bash
# 모듈 언로드 
$ sudo rmmod bonding 
```


📝 연습문제 

번호  문제 

정답 

Q1 

현재 실행 중인 커널 버전 확인 명령어? 

uname -r 

Q2 

커널 이미지 파일이 저장되는 디렉터리? 

/boot 

Q3 

커널 파일명 앞에 붙는 prefix는? 

vmlinuz- 

Q4 

Oracle 권장 커널의 이름은? 

UEK (Unbreakable Enterprise Kernel) 

Q5 

기본 부팅 커널을 변경하는 명령어? 

grubby --set-default=<커널경로> 

Q6 

사용자 공간의 프로그램이 하드웨어에 접

System Call (시스템 호출) 

근하는 방법? 

Q7 

현재 로드된 커널 모듈 목록을 확인하는 명

lsmod 

령어?

📝 실습 

90.  현재 커널 버전 확인: uname -r 

91.  전체 시스템 정보 출력: uname -a 

92.  설치된 커널 이미지 목록: ls -la /boot/vmlinuz* 

93.  현재 기본 부팅 커널 확인: sudo grubby --default-kernel 

94.  모든 부팅 엔트리 조회: sudo grubby --info=ALL 

95.  로드된 커널 모듈 목록: lsmod | head -20 

96.  strace 로 ls 명령의 시스템 호출 추적: strace ls /tmp 2>&1 | head -20