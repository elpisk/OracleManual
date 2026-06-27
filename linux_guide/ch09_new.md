# Chapter 09 — 파일 권한과 소유권

09   파일 권한과 소유권 

### 9.1 파일 권한 체계 

리눅스는 파일마다 읽기(r), 쓰기(w), 실행(x) 권한을 소유자/그룹/기타 3가지 대상에 부여합니다. 

-  rwx  r-x  r-- 
|   |    |    | 
|   |    |    └── 기타(others): 읽기만 
|   |    └─────── 그룹(group): 읽기+실행 
|   └──────────── 소유자(user): 읽기+쓰기+실행 
└──────────────── 파일 종류 (- 일반, d 디렉터리, l 링크) 

### 9.2 chmod — 권한 변경 

기호 모드 

```bash
$ chmod u+x file.sh      # 소유자에게 실행 권한 추가 
$ chmod g-w file.txt     # 그룹에서 쓰기 권한 제거 
$ chmod o=r file.txt     # 기타를 읽기만으로 설정 
$ chmod a+r file.txt     # 모든 대상에 읽기 추가 
```


숫자 모드 (8 진수) 

숫자 

기호 

의미 

7 

6 

5 

4 

0 

rwx 

rw- 

r-x 

r-- 

--- 

읽기+쓰기+실행 

읽기+쓰기 

읽기+실행 

읽기만 

권한 없음 

```bash
$ chmod 755 script.sh    # rwxr-xr-x (실행 스크립트) 
$ chmod 644 file.txt     # rw-r--r-- (일반 파일) 
$ chmod 700 private.sh   # rwx------ (소유자만) 
$ chmod -R 755 /var/www/ # 디렉터리 재귀 적용
```


### 9.3 chown / chgrp — 소유자/그룹 변경 

```bash
# 소유자 변경 
$ sudo chown student file.txt 
```


```bash
# 소유자와 그룹 동시 변경 
$ sudo chown student:devteam file.txt 
```


```bash
# 그룹만 변경 
$ sudo chgrp devteam file.txt 
```


```bash
# 재귀적 변경 
$ sudo chown -R student:student /home/student/ 
```


### 9.4 umask — 기본 권한 마스크 

파일/디렉터리 생성 시 기본 권한에서 umask 값을 뺀 권한이 적용됩니다. 

```bash
$ umask                  # 현재 umask 확인 (기본: 0022) 
```
0022 

```bash
# 파일 기본권한: 666 - 022 = 644 (rw-r--r--) 
# 디렉터리 기본권한: 777 - 022 = 755 (rwxr-xr-x) 
```


📝 실습 

134. 

135. 

136. 

137. 

test.sh 파일 생성 후 권한 755 설정: touch test.sh && chmod 755 test.sh 

권한 확인: ls -la test.sh 

권한을 644 로 변경: chmod 644 test.sh 

현재 umask 값 확인: umask