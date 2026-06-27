# Chapter 12 — 네트워크 기초 명령어

12   네트워크 기초 명령어 

### 12.1 네트워크 설정 확인 

명령어 

ip addr 

ip route 

hostname 

설명 

사용 예 

IP 주소, 네트워크 인터페이스 정보 

ip addr show 

라우팅 테이블 확인 

ip route show 

호스트명 확인 

hostname -I 

```bash
cat /etc/hosts 
```


정적 호스트 매핑 

```bash
grep -v "^#" /etc/hosts 
```


nmcli 

NetworkManager CLI 

nmcli con show 

```bash
$ ip addr show 
```
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> 
    inet 192.168.1.100/24 brd 192.168.1.255 scope global 

### 12.2 연결 테스트 

```bash
$ ping google.com           # 연결 테스트 (Ctrl+C로 종료) 
$ ping -c 4 8.8.8.8         # 4번만 ping 
```


```bash
$ traceroute google.com     # 경로 추적 
$ tracepath google.com      # traceroute 대안 
```


### 12.3 포트 및 연결 확인 

```bash
$ ss -tuln                  # 열린 포트 확인 (권장) 
$ ss -tulnp                 # 프로세스명 포함 
```


```bash
$ netstat -tuln             # 구버전 (net-tools 설치 필요) 
```


```bash
# 특정 포트 리스닝 확인 
$ ss -tuln | grep :22       # SSH 22번 포트
```


```bash
$ ss -tuln | grep :80       # HTTP 80번 포트 
```


### 12.4 원격 연결 — SSH 

```bash
# SSH 접속 
$ ssh user@192.168.1.10 
$ ssh -p 2222 user@server   # 포트 지정 
```


```bash
# 파일 전송 
$ scp file.txt user@server:/tmp/ 
$ scp -r /local/dir user@server:/remote/ 
```


```bash
# SSH 서비스 상태 확인 
$ sudo systemctl status sshd 
```


### 12.5 curl / wget — 데이터 다운로드 

```bash
$ curl https://example.com           # 웹 내용 출력 
$ curl -O https://example.com/file   # 파일 다운로드 
$ curl -I https://example.com        # HTTP 헤더만 
```


```bash
$ wget https://example.com/file.tar.gz  # 파일 다운로드 
$ wget -r https://example.com/          # 재귀 다운로드 
```


📝 실습 

147. 

148. 

149. 

150. 

내 IP 주소 확인: ip addr show 

인터넷 연결 테스트: ping -c 4 8.8.8.8 

SSH 포트 열림 확인: ss -tuln | grep :22 

```bash
curl 로 웹 테스트: curl -I https://www.google.com
```