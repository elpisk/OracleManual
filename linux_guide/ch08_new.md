# Chapter 08 — 텍스트 처리 명령어

08   텍스트 처리 명령어 

### 8.1 파이프(|)와 리다이렉션 

파이프(|) 

한 명령의 출력을 다음 명령의 입력으로 전달합니다. 

```bash
$ ls -la | grep ".conf"    # ls 결과에서 .conf 필터링 
$ cat /etc/passwd | wc -l  # passwd 줄 수 세기 
$ ps aux | grep nginx      # nginx 프로세스 찾기 
```


리다이렉션 

기호 

설명 

> 

>> 

< 

2> 

표준 출력을 파일로 저장 (덮어쓰기) 

표준 출력을 파일에 추가 

파일을 표준 입력으로 사용 

표준 오류를 파일로 저장 

2>&1 

표준 오류를 표준 출력으로 합침 

```bash
$ ls -la > filelist.txt         # 목록 파일로 저장 
$ echo "Hello" >> log.txt       # 추가 
$ find / -name "*.conf" 2>/dev/null  # 에러 무시 
```


### 8.2 sort — 정렬 

```bash
$ sort /etc/passwd             # 알파벳 정렬 
$ sort -r /etc/passwd          # 역순 정렬 
$ sort -n numbers.txt          # 숫자 정렬 
$ sort -k3 /etc/passwd         # 3번째 필드로 정렬 
$ sort -u /etc/passwd          # 중복 제거 후 정렬
```


### 8.3 uniq — 중복 제거 

```bash
$ sort file.txt | uniq         # 정렬 후 중복 제거 
$ sort file.txt | uniq -c      # 중복 횟수 표시 
$ sort file.txt | uniq -d      # 중복된 줄만 출력 
```


### 8.4 cut — 필드 추출 

```bash
# /etc/passwd에서 사용자명(1번째)과 쉘(7번째) 추출 
$ cut -d: -f1,7 /etc/passwd 
```
root:/bin/bash 
student:/bin/bash 

```bash
# 문자 위치로 추출 
$ cut -c1-5 /etc/passwd        # 1~5번째 문자 
```


### 8.5 awk — 패턴 처리 

```bash
# 1번째 필드 출력 (기본 구분자: 공백) 
$ awk "{print $1}" file.txt 
```


```bash
# : 구분자로 1,3번째 필드 출력 
$ awk -F: "{print $1, $3}" /etc/passwd 
```


```bash
# 조건 필터링 
$ awk -F: "$3 >= 1000" /etc/passwd  # UID 1000 이상 
```


### 8.6 sed — 스트림 편집기 

```bash
# 치환: s/원본/대체/g 
$ sed "s/Hello/Hi/g" file.txt 
```


```bash
# 특정 줄 삭제 
$ sed "/^#/d" /etc/hosts       # 주석줄 삭제 
```


```bash
# 파일 직접 수정 (-i) 
$ sed -i "s/old/new/g" file.txt
```


📝 실습 

131. 

132. 

133. 

/etc/passwd 에서 사용자명만 추출: cut -d: -f1 /etc/passwd 

/etc/passwd 를 UID 기준 정렬: sort -t: -k3 -n /etc/passwd | head -10 

현재 실행 프로세스에서 bash 찾기: ps aux | grep bash