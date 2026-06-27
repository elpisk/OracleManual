# Chapter 07 — 파일과 디렉터리 관리

07   파일과 디렉터리 관리 

Note:  이 챕터는 Oracle Linux에서 파일·디렉터리를 탐색·생성·복사·이동·삭제·검색하는 핵심 

명령어를 다룹니다. 더 자세한 내용은 각 명령어의 man 페이지를 참조하세요. 

### 7.1 작업 디렉터리 확인 — pwd 

Print Working Directory. 현재 위치한 디렉터리의 절대경로를 출력합니다. 디렉터리 이동 전후 위치

를 확인할 때 기본적으로 사용합니다. 

```bash
$ pwd 
```
/home/student 

```bash
$ cd /etc && pwd 
```
/etc 

### 7.2 목록 출력 — ls 

List. 디렉터리 내 파일과 하위 디렉터리 목록을 출력합니다. 옵션 조합에 따라 상세 정보, 숨김파일, 

파일 유형 등을 표시합니다. 

옵션 

설명 

-l 

-a 

-la 

-h 

-F 

-R 

상세 정보 출력 (권한·소유자·크기·날짜) 

숨김파일(. 으로 시작) 포함 출력 

-l + -a 동시 적용 (가장 자주 사용) 

파일 크기를 사람이 읽기 쉬운 단위로 (KB·MB) 

파일 종류 구분 기호 추가 (/ 디렉터리, * 실행파일, @ 심볼릭링크) 

하위 디렉터리 재귀적으로 표시

옵션 

설명 

-t 

-S 

-i 

수정 시간 기준 정렬 

파일 크기 기준 정렬 

inode 번호 표시 

```bash
$ ls -la /home/student 
```
total 32 
drwx------. 4 student student  98 Jun 15 09:00 . 
drwxr-xr-x. 3 root    root     22 Jun 10 08:00 .. 
-rw-r--r--. 1 student student  18 Jun 10 .bash_profile 
drwxr-xr-x. 2 student student   6 Jun 15 documents 

① ②   ③  ④       ⑤        ⑥    ⑦       ⑧ 
권한 링크수 소유자 그룹    크기  날짜    파일명 

```bash
ls -l 출력 형식 해석 
```


표시 

해석 

d rwx r-x r-x 

- rw- r-- r-- 

l rwx rwx rwx 

디렉터리 | 소유자=rwx | 그룹=r-x | 기타=r-x 

일반파일 | 소유자=rw- | 그룹=r-- | 기타=r-- 

심볼릭링크 | 모두 허용 

-F 옵션으로 파일 유형 구분 

```bash
$ ls -F /etc 
```
adjtime         ← 일반 파일 (기호 없음) 
alternatives/   ← 디렉터리 (/ 추가) 
bashrc*         ← 실행 파일 (* 추가) 
localtime@      ← 심볼릭 링크 (@ 추가) 

### 7.3 파일 유형 확인 — file 

file 명령어는 확장자에 상관없이 파일의 실제 유형(텍스트·바이너리·이미지·스크립트 등)을 분석하여

 출력합니다.

```bash
$ file /etc/hosts 
```
/etc/hosts: ASCII text 

```bash
$ file /bin/ls 
```
/bin/ls: ELF 64-bit LSB shared object, x86-64 

```bash
$ file /usr/bin/python3 
```
/usr/bin/python3: symbolic link to python3.9 

```bash
$ file /var/log/messages 
```
/var/log/messages: ASCII text 

```bash
# 여러 파일 동시 확인 
$ file /etc/* 
```


### 7.4 디렉터리 이동 — cd 

Change Directory. 현재 작업 디렉터리를 변경합니다. 절대경로와 상대경로를 모두 사용할 수 있습

니다. 

절대경로 vs 상대경로 

종류 

설명 

예시 

절대경로 

루트(/)에서 시작하는 전체 

```bash
cd /home/student/documents 
```


경로 

상대경로 

현재 디렉터리 기준 경로 

```bash
cd documents  (현재 위치 기준) 
```


```bash
$ cd /etc              # 절대경로로 이동 
$ cd documents         # 상대경로로 이동 
$ cd ..                # 상위(부모) 디렉터리로 이동 
$ cd ~                 # 내 홈 디렉터리로 이동 (/home/student) 
$ cd -                 # 바로 이전 디렉터리로 이동 
$ cd /                 # 루트 디렉터리로 이동 
$ cd ../..             # 두 단계 위로 이동 
```


경로 기호 정리

기호 

의미 

.  (점 하
나) 

.. (점 두
 개) 

현재 디렉터리 

상위(부모) 디렉터리 

~ 

/ 

- 

현재 사용자의 홈 디렉터리 

루트 디렉터리 (최상위) 

```bash
cd 명령 전 위치 (이전 디렉터리) 
```


### 7.5 디렉터리 생성/삭제 — mkdir / rmdir 

```bash
# 디렉터리 생성 
$ mkdir mydir                  # 단일 디렉터리 생성 
$ mkdir dir1 dir2 dir3         # 여러 개 동시 생성 
$ mkdir -p /opt/oracle/db      # 중간 경로 포함 생성 (-p) 
$ mkdir -m 755 /opt/scripts    # 권한 지정하여 생성 
```


```bash
# 빈 디렉터리 삭제 
$ rmdir mydir                  # 빈 디렉터리만 삭제 가능 
$ rmdir -p a/b/c               # 빈 부모 디렉터리도 함께 삭제 
```


주의:  rmdir는 빈 디렉터리만 삭제합니다. 내용이 있는 디렉터리는 rm -rf 를 사용하세요 (주의

!). 

### 7.6 파일 생성 — touch 

빈 파일을 생성하거나, 기존 파일의 타임스탬프를 현재 시각으로 갱신합니다. 

```bash
$ touch file1.txt              # 빈 파일 생성 
$ touch file1 file2 file3      # 여러 파일 동시 생성 
$ touch -t 202406150900 file1  # 타임스탬프 지정 변경 
```


```bash
# 활용: 스크립트에서 빈 로그 파일 사전 생성 
$ touch /var/log/myapp.log
```


### 7.7 파일/디렉터리 복사 — cp 

Copy. 파일 또는 디렉터리를 복사합니다. 디렉터리 복사 시 -r 옵션이 반드시 필요합니다. 

옵션 

설명 

-r / -R 

디렉터리를 재귀적으로 복사 (디렉터리 복사 시 필수) 

-p 

-i 

-v 

-u 

-a 

원본의 권한·소유자·타임스탬프 유지 

덮어쓰기 전 확인 메시지 출력 

복사 과정 화면 출력 (verbose) 

원본이 더 최신일 때만 복사 

-rp 와 동일, 아카이브 모드 (백업에 유용) 

```bash
$ cp file1.txt file2.txt               # 파일 복사 
$ cp -r dir1/ dir2/                    # 디렉터리 복사 (-r 필수) 
$ cp -rp /etc/sysconfig/ ~/backup/     # 속성 유지 복사 
$ cp -v *.conf /tmp/                   # 복사 과정 출력 
```


```bash
# 여러 파일을 디렉터리로 복사 
$ cp file1.txt file2.txt /tmp/ 
```


### 7.8 파일/디렉터리 이동 및 이름 변경 — mv 

Move. 파일이나 디렉터리를 이동하거나 이름을 변경합니다. cp와 달리 원본 파일이 삭제됩니다. 

```bash
$ mv file1.txt renamed.txt             # 파일 이름 변경 
$ mv file1.txt /tmp/                   # 파일 이동 
$ mv dir1/ /opt/                       # 디렉터리 이동 
$ mv -i old.txt new.txt                # 덮어쓰기 전 확인 
$ mv -v *.log /var/log/archive/        # 이동 과정 출력 
```


```bash
# 여러 파일을 디렉터리로 이동 
$ mv file1.txt file2.txt /tmp/ 
```


### 7.9 파일/디렉터리 삭제 — rm

옵션 

설명 

-f 

-r 

-i 

-v 

확인 없이 강제 삭제 (force) 

디렉터리 재귀 삭제 (하위 포함) 

삭제 전 확인 메시지 

삭제 과정 출력 

```bash
$ rm file1.txt                 # 파일 삭제 
$ rm -i file1.txt              # 확인 후 삭제 
$ rm -rf mydir/                # 디렉터리 강제 삭제 
$ rm -rf /tmp/*.tmp            # 패턴으로 일괄 삭제 
```


주의:  rm -rf / 는 절대 실행하지 마세요! 루트 파일시스템 전체를 삭제합니다. Oracle Linux에

는 --no-preserve-root 보호 기능이 있습니다. 

### 7.10 링크 생성 — ln 

링크는 파일을 가리키는 포인터입니다. 하드 링크와 심볼릭 링크 두 종류가 있습니다. 

종류 

명령어 

특징 

하드 링크 

ln 원본 링크명 

동일 inode 공유. 원본 삭제 후에도 데이터 유지 

심볼릭 링크 

ln -s 원본 링크명 

원본을 가리키는 포인터. 원본 삭제 시 링크 깨짐 

```bash
$ ln file1.txt hardlink.txt             # 하드 링크 
$ ln -s /etc/hosts /tmp/hosts_link      # 심볼릭 링크 
```


```bash
$ ls -la /tmp/hosts_link 
```
lrwxrwxrwx. 1 root root 10 Jun 15 hosts_link -> /etc/hosts 

```bash
# Oracle DB 환경 심볼릭 링크 예시 
$ ln -s /u01/app/oracle/product/19c/dbhome_1 /home/oracle/db_home 
```


### 7.11 파일 내용 보기 — cat / less / head / tail

```bash
cat — 파일 전체 출력 
```


```bash
$ cat /etc/hosts                       # 파일 내용 출력 
$ cat -n /etc/passwd                   # 줄 번호 표시 
$ cat file1 file2 > merged.txt         # 여러 파일 합치기 
$ cat /dev/null > logfile.txt          # 파일 내용 비우기 
```


less — 페이지 단위 보기 (권장) 

```bash
$ less /var/log/messages               # 파일 열기 
```
  Space / f  다음 페이지 
  b          이전 페이지 
  /검색어    검색 (n: 다음, N: 이전) 
  g / G      파일 처음 / 끝 
  q          종료 

```bash
$ less -N /etc/passwd                  # 줄 번호 표시 
```


Tip:  less는 대용량 파일도 메모리 부담 없이 빠르게 열 수 있습니다. more 대신 less를 사용하

세요. 

head / tail — 앞/뒤 일부 출력 

```bash
$ head /etc/passwd                     # 앞 10줄 (기본) 
$ head -5 /etc/passwd                  # 앞 5줄 
```


```bash
$ tail /var/log/messages               # 마지막 10줄 
$ tail -20 /var/log/messages           # 마지막 20줄 
$ tail -f /var/log/messages            # 실시간 로그 감시 
```


Tip:  tail -f 는 Oracle alert log (/u01/app/.../alert_SID.log) 실시간 감시에 필수 명령어입니다. 

wc / diff — 통계·비교 

```bash
# wc: 줄·단어·바이트 수 출력 
$ wc /etc/passwd 
```
 48  93 2594 /etc/passwd     ← 줄수 단어수 바이트 
```bash
$ wc -l /etc/passwd          # 줄 수만 출력 
```


```bash
# diff: 두 파일 차이 비교 
$ diff file1.txt file2.txt 
```
2c2 
< Hello World 
--- 
> Hello Linux

```bash
$ diff -u file1.txt file2.txt          # unified 형식 (패치용) 
```


### 7.12 파일 시스템 검색 — find 

find는 파일 시스템을 직접 재귀적으로 탐색하여 조건에 맞는 파일·디렉터리를 찾습니다. 가장 강력

한 파일 검색 명령어입니다. 

```bash
find [검색경로] [조건...] [동작] 
```


조건/옵션 

설명 

-name "패턴" 

파일명으로 검색 (와일드카드 * ? 사용 가능) 

-iname "패턴" 

대소문자 무시 파일명 검색 

-type f 

-type d 

-type l 

-size +10M 

-mtime -7 

일반 파일만 

디렉터리만 

심볼릭 링크만 

10MB 초과 파일 (+크다 -작다) 

7일 이내 수정된 파일 (-이내 +이전) 

-user 사용자 

특정 사용자 소유 파일 

-perm 644 

-empty 

권한이 644인 파일 

빈 파일 또는 빈 디렉터리 

-exec 명령 {} \;  찾은 각 파일에 명령 실행 

-exec 명령 {} + 

찾은 파일 묶어서 명령 실행 (효율적) 

```bash
# 이름으로 검색 
$ find /etc -name "*.conf" 
$ find / -name "passwd" 2>/dev/null    # 오류 억제 
```


```bash
# 타입과 이름 조합 
$ find /home -type f -name "*.txt" 
$ find /var -type d -name "log*"
```


```bash
# 크기와 시간 조건 
$ find /var -size +100M               # 100MB 초과 
$ find /tmp -mtime +7                 # 7일 이전 파일 
```


```bash
# 검색 후 동작 실행 
$ find /tmp -name "*.tmp" -exec rm {} \;    # 삭제 
$ find /etc -name "*.conf" -exec cp {} /backup/ \;  # 복사 
```


```bash
# 논리 연산자 조합 
$ find /home -type f -name "*.log" -size +10M 
```


### 7.13 파일 내용 문자열 검색 — grep 

파일 내용에서 패턴(문자열 또는 정규표현식)을 검색합니다. find가 파일 이름을 찾는다면, grep은 

파일 안의 내용을 검색합니다. 

옵션 

설명 

-i 

-n 

-v 

대소문자 구분 없이 검색 

줄 번호 표시 

패턴이 없는 줄 출력 (반전) 

-r / -R 

디렉터리 재귀 검색 

-l 

-c 

-A N 

-B N 

-E 

패턴이 있는 파일명만 출력 

매칭된 줄 수 출력 

매칭 줄 아래 N줄 함께 출력 (After) 

매칭 줄 위 N줄 함께 출력 (Before) 

확장 정규표현식 사용 (egrep과 동일) 

--color 

매칭 부분 색상 표시 

```bash
$ grep "root" /etc/passwd              # root 포함 줄 
$ grep -i "error" /var/log/messages    # 대소문자 무시 
$ grep -n "ssh" /etc/services          # 줄번호 포함 
$ grep -r "oracle" /etc/              # 디렉터리 재귀
```


```bash
$ grep -v "^#" /etc/hosts             # 주석줄 제외 
$ grep -l "oracle" /etc/*.conf         # 파일명만 출력 
$ grep -E "^(root|oracle)" /etc/passwd # 정규표현식 
$ grep -A2 "error" /var/log/messages   # 매칭 + 아래 2줄 
```


### 7.14 빠른 검색 — locate / which / whereis 

locate — DB 기반 빠른 파일 검색 

```bash
$ sudo updatedb                        # DB 업데이트 (먼저 실행) 
$ locate passwd                        # 파일명 검색 (매우 빠름) 
$ locate -i PASSWD                    # 대소문자 무시 
$ locate "*.conf" | head -10          # 확장자로 검색 
```


```bash
# find vs locate 비교 
# find: 실시간·정확 / 느림 
# locate: DB 기반·빠름 / 최근 생성 파일 미반영 
```


which / whereis — 명령어 위치 확인 

```bash
$ which python3                        # 명령어 실행 파일 경로 
```
/usr/bin/python3 

```bash
$ whereis nginx                        # 실행파일·소스·man 위치 
```
nginx: /usr/sbin/nginx /etc/nginx /usr/share/man/man8/nginx.8.gz 

```bash
$ type ls                              # 명령어 종류 확인 (내장/외부/alias) 
ls is aliased to "ls --color=auto" 
```


📝 연습문제 

번호  문제 

Q1 

현재 작업 디렉터리 확인 명령어? 

Q2 

ls에서 숨김파일 포함 상세 출력 옵션? 

정답 

pwd 

-la

번호  문제 

정답 

Q3 

```bash
ls -F 에서 디렉터리에 붙는 기호? 
```


/ (슬래시) 

Q4 

파일의 실제 유형을 확인하는 명령어? 

file 

Q5 

홈 디렉터리로 이동하는 단축 명령? 

```bash
cd ~ (또는 cd) 
```


Q6 

이전 디렉터리로 돌아가는 명령? 

```bash
cd - 
```


Q7 

중간 경로 포함 디렉터리 생성 옵션? 

```bash
mkdir -p 
```


Q8 

디렉터리 복사 시 반드시 필요한 cp 옵션? 

-r (재귀) 

Q9 

```bash
rm -rf / 실행하면? 
```


루트 파일시스템 전체 삭제 — 절대 금

지 

Q10  하드 링크와 심볼릭 링크의 차이? 

하드: 동일 inode / 심볼릭: 포인터 

Q11  대용량 파일을 페이지 단위로 보는 권장 명령

less 

어? 

Q12  로그 파일을 실시간으로 감시하는 명령어? 

tail -f 

Q13 

find에서 검색 후 파일을 삭제하는 패턴? 

```bash
find ... -exec rm {} \; 
```


Q14 

grep에서 디렉터리를 재귀 검색하는 옵션? 

-r 

Q15 

locate와 find의 가장 큰 차이? 

locate: DB 기반·빠름 / find: 실시간·정

확 

📝 실습 

119. 

120. 

121. 

122. 

123. 

현재 위치 확인 후 /etc 이동: pwd → cd /etc → pwd 

```bash
ls -la /etc | head -20 으로 숨김파일 포함 목록 확인 
```


```bash
ls -F /etc 로 파일 유형 기호 확인 
```


file /bin/ls /etc/hosts /usr/bin/python3 로 파일 유형 비교 

~/practice 생성 후 test1~5.txt 생성: mkdir -p ~/practice && cd ~/practice && touch 

test{1..5}.txt

124. 

125. 

126. 

127. 

128. 

129. 

130. 

test1.txt 복사, test2.txt 이름변경, test3.txt 삭제 

```bash
cat -n /etc/passwd | head -5 로 줄 번호 확인 
```


less /var/log/messages → /error 검색 → q 종료 

tail -f /var/log/messages 실행 → 10 초 후 Ctrl+C 

```bash
find /etc -name "*.conf" -size +1k 로 1KB 초과 설정파일 검색 
```


```bash
grep -rn "oracle" /etc/ 2>/dev/null 로 oracle 문자열 검색 
```


which vim; whereis vim; locate vim | head -5