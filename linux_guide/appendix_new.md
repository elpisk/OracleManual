# Appendix — 기초 명령어 50개 총정리

Appendix  기초 명령어 50 개 총정리 

리눅스 기초 학습의 핵심 명령어 50개를 카테고리별로 정리합니다. 

A. 시스템 정보 

명령어 

설명 

uname -r 

uname -a 

hostname 

whoami 

id 

uptime 

date 

cal 

free -h 

df -h 

커널 버전 

전체 시스템 정보 

호스트명 

현재 사용자 

UID/GID/그룹 

시스템 가동 시간 

날짜/시간 

달력 

메모리 사용량 

디스크 사용량 

B. 파일/디렉터리 관리 

명령어 

pwd 

```bash
ls -la 
```


cd 

설명 

현재 디렉터리 

목록 상세 

디렉터리 이동 

사용 예 

uname -r 

uname -a 

hostname 

whoami 

id 

uptime 

date "+%Y-%m-%d %H:%M" 

cal 2024 

free -h 

df -h 

사용 예 

pwd 

```bash
ls -la /etc 
```


```bash
cd /home
```


명령어 

설명 

사용 예 

```bash
mkdir -p 
```


디렉터리 생성 

```bash
mkdir -p a/b/c 
```


rmdir 

touch 

```bash
cp -r 
```


mv 

```bash
rm -rf 
```


ln -s 

빈 디렉터리 삭제 

rmdir emptydir 

파일 생성 

복사 

touch file.txt 

```bash
cp -r dir1/ dir2/ 
```


이동/이름변경 

```bash
mv old.txt new.txt 
```


삭제 

```bash
rm -rf tmpdir/ 
```


심볼릭 링크 

ln -s /etc/hosts /tmp/h 

C. 파일 내용 

명령어 

설명 

파일 출력 

페이지 출력 

앞 N줄 

뒤 N줄 

줄 수 

cat 

less 

head 

tail 

wc -l 

diff 

D. 검색 

명령어 

find 

grep 

사용 예 

```bash
cat -n file.txt 
```


less /var/log/messages 

head -10 file.txt 

tail -f /var/log/messages 

wc -l /etc/passwd 

파일 비교 

diff file1 file2 

설명 

파일 검색 

사용 예 

```bash
find /etc -name "*.conf" 
```


문자열 검색 

```bash
grep -rn "error" /var/log/
```


명령어 

locate 

which 

whereis 

E. 텍스트 처리 

명령어 

sort 

uniq 

cut 

awk 

sed 

tr 

F. 권한/소유권 

명령어 

chmod 

chown 

chgrp 

umask 

설명 

빠른 검색 

명령어 위치 

파일 위치 

설명 

정렬 

중복제거 

필드 추출 

패턴 처리 

스트림 편집 

문자 변환 

사용 예 

locate passwd 

which python3 

whereis nginx 

사용 예 

sort -n numbers.txt 

sort file | uniq -c 

cut -d: -f1 /etc/passwd 

awk -F: "{print $1}" /etc/passw

d 

sed "s/old/new/g" file 

echo "hello" | tr a-z A-Z 

설명 

권한 변경 

사용 예 

```bash
chmod 755 script.sh 
```


소유자 변경 

```bash
chown user:group file 
```


그룹 변경 

기본 권한 

chgrp devteam file 

umask 022

G. 사용자/그룹 

명령어 

useradd 

passwd 

userdel -r 

groupadd 

su - 

sudo 

who 

last 

H. 프로세스 

명령어 

```bash
ps aux 
```


top 

kill 

killall 

설명 

사용자 추가 

암호 변경 

사용자 삭제 

그룹 추가 

사용자 전환 

관리자 실행 

로그인 목록 

로그인 기록 

설명 

프로세스 목록 

실시간 모니터 

프로세스 종료 

이름으로 종료 

I. 네트워크 

명령어 

ip addr 

설명 

IP 정보 

사용 예 

```bash
useradd -m user1 
```


passwd user1 

userdel -r user1 

```bash
groupadd devteam 
```


su - root 

```bash
sudo systemctl restart sshd 
```


who 

last | head 

사용 예 

```bash
ps aux | grep nginx 
```


top 

```bash
kill -9 1234 
```


killall nginx 

사용 예 

ip addr show

명령어 

ping 

ss -tuln 

ssh 

curl 

wget 

설명 

사용 예 

연결 테스트 

ping -c 4 8.8.8.8 

포트 확인 

원격 접속 

웹 요청 

ss -tuln 

```bash
ssh user@192.168.1.10 
```


```bash
curl -O https://url/file 
```


파일 다운로드 

```bash
wget https://url/file 
```


J. 패키지/서비스 

명령어 

설명 

사용 예 

```bash
dnf install 
```


```bash
apt install 
```


systemctl 

패키지 설치 (RPM) 

```bash
dnf install nginx -y 
```


패키지 설치 (DEB) 

```bash
apt install nginx -y 
```


서비스 관리 

```bash
systemctl status sshd 
```


© Linux 기초 입문 교안 | Oracle DBA 트레이닝 교재