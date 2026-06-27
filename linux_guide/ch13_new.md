# Chapter 13 — 패키지 관리

13   패키지 관리 

### 13.1 패키지 관리란? 

리눅스 소프트웨어는 패키지 형태로 배포됩니다. 패키지 관리자를 통해 설치, 업데이트, 삭제를 자동

으로 처리합니다. 

계열 

배포판 

명령어 

RPM 계열 

RHEL/Rocky/CentOS 

dnf, yum, rpm 

DEB 계열 

Ubuntu/Debian 

apt, apt-get, dpkg 

### 13.2 dnf — Oracle Linux / RHEL 

명령어 

설명 

사용 예 

```bash
dnf install 
```


```bash
dnf remove 
```


```bash
dnf update 
```


```bash
dnf search 
```


```bash
dnf info 
```


```bash
dnf list 
```


패키지 설치 

패키지 삭제 

```bash
dnf install nginx -y 
```


```bash
dnf remove nginx 
```


시스템 전체 업데이트 

```bash
dnf update -y 
```


패키지 검색 

패키지 정보 

```bash
dnf search "web server" 
```


```bash
dnf info nginx 
```


설치된 패키지 목록 

```bash
dnf list installed 
```


```bash
dnf repolist 
```


```bash
dnf clean all 
```


저장소 목록 

캐시 초기화 

```bash
dnf repolist 
```


```bash
dnf clean all 
```


### 13.3 apt — Ubuntu / Debian

명령어 

설명 

사용 예 

```bash
apt update 
```


```bash
apt install 
```


```bash
apt remove 
```


```bash
apt upgrade 
```


```bash
apt search 
```


```bash
apt show 
```


패키지 목록 업데이트 

```bash
apt update 
```


패키지 설치 

패키지 삭제 

```bash
apt install nginx -y 
```


```bash
apt remove nginx 
```


설치된 패키지 업그레이드 

```bash
apt upgrade -y 
```


패키지 검색 

패키지 정보 

```bash
apt search nginx 
```


```bash
apt show nginx 
```


```bash
apt autoremove 
```


불필요 패키지 자동 삭제 

```bash
apt autoremove 
```


### 13.4 systemctl — 서비스 관리 

systemd 기반 서비스를 관리합니다. 

명령어 

설명 

사용 예 

```bash
systemctl start  서비스 시작 
```


```bash
systemctl stop 
```


서비스 중지 

```bash
systemctl start nginx 
```


```bash
systemctl stop nginx 
```


```bash
systemctl resta
```
rt 

```bash
systemctl statu
```
s 

```bash
systemctl enabl
```
e 

```bash
systemctl disab
```
le 

서비스 재시작 

```bash
systemctl restart nginx 
```


서비스 상태 확인 

```bash
systemctl status sshd 
```


부팅 시 자동 시작 

```bash
systemctl enable nginx 
```


자동 시작 해제 

```bash
systemctl disable nginx 
```


📝 실습 

151. 

시스템 패키지 목록 업데이트: sudo dnf update (또는 sudo apt update)

152. 

153. 

154. 

tree 패키지 설치: sudo dnf install tree (또는 sudo apt install tree) 

설치 확인: tree --version 

sshd 서비스 상태 확인: sudo systemctl status sshd