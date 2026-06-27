# Chapter 10 — 사용자 및 그룹 관리

10   사용자 및 그룹 관리 

### 10.1 주요 파일 

파일 

내용 

/etc/passwd 

/etc/shadow 

/etc/group 

사용자 계정 정보 (이름:암호:UID:GID:설명:홈:쉘) 

암호화된 비밀번호 (root만 읽기) 

그룹 정보 (이름:암호:GID:멤버) 

/etc/sudoers 

```bash
sudo 권한 설정 (visudo로 편집) 
```


```bash
# /etc/passwd 형식 
```
student:x:1000:1000:Student User:/home/student:/bin/bash 
이름  : x : UID : GID :  설명     :  홈 디렉터리 :  쉘 

### 10.2 사용자 관리 명령어 

명령어 

useradd 

userdel 

usermod 

passwd 

id 

who 

w 

last 

설명 

사용 예 

새 사용자 추가 

```bash
useradd -m -s /bin/bash user1 
```


사용자 삭제 

userdel -r user1 

사용자 정보 수정 

usermod -aG wheel user1 

비밀번호 변경 

UID/GID 확인 

로그인 사용자 

로그인 + 활동 

로그인 기록 

passwd user1 

id user1 

who 

w 

last | head -20

### 10.3 그룹 관리 명령어 

명령어 

설명 

사용 예 

groupadd 

groupdel 

groupmod 

gpasswd 

groups 

그룹 생성 

그룹 삭제 

그룹 수정 

```bash
groupadd devteam 
```


groupdel devteam 

groupmod -n newname devte

am 

그룹 암호/멤버 

gpasswd -a user1 devteam 

소속 그룹 확인 

groups student 

### 10.4 sudo 설정 

```bash
# visudo 명령으로 /etc/sudoers 안전 편집 
$ sudo visudo 
```


```bash
# 특정 사용자에게 모든 권한 
```
student ALL=(ALL) ALL 

```bash
# 암호 없이 sudo 
```
student ALL=(ALL) NOPASSWD: ALL 

📝 실습 

138. 

139. 

140. 

141. 

142. 

testuser 계정 생성: sudo useradd -m -s /bin/bash testuser 

비밀번호 설정: sudo passwd testuser 

계정 정보 확인: id testuser 

testuser 를 wheel 그룹에 추가: sudo usermod -aG wheel testuser 

testuser 삭제: sudo userdel -r testuser