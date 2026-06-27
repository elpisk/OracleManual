# Chapter 05 — 셸(Shell) · CLI · Bash 스크립트

05   셸(Shell) · CLI · Bash 스크립트 

Note:  이 챕터는 셸의 개념과 CLI 기초(명령어 구조·도움말·단축키), 환경변수, bash 설정 파일,

 Bash 스크립트 작성까지 통합하여 다룹니다. 

### 5.1 셸(Shell)과 프롬프트 

셸(Shell)은 사용자와 운영체제 커널 사이에서 명령어를 해석·실행하는 인터프리터 프로그램입니다. 

사용자가 입력한 명령을 커널에 전달하고 결과를 화면에 출력합니다. 

  [사용자] 
     │  명령어 입력 
     ▼ 
  ┌──────────────────────┐ 
  │   Shell (bash)       │  ← 해석 
  └──────────┬───────────┘ 
             │  System Call 
             ▼ 
  ┌──────────────────────┐ 
  │   Kernel (커널)      │  ← 실행 
  └──────────┬───────────┘ 
             ▼ 
  ┌──────────────────────┐ 
  │   Hardware           │ 
  └──────────────────────┘ 

주요 셸 종류 

셸 종류 

특징 

bash 

sh 

zsh 

csh 

ksh 

Bourne Again SHell — Oracle Linux / RHEL 기본 셸, 가장 널리 사용 

Bourne Shell — 최초 유닉스 셸, POSIX 표준 

Z Shell — 강력한 자동완성, macOS 기본 셸 

C Shell — C 언어 문법과 유사 

Korn Shell — 상용 유닉스 환경에서 사용

프롬프트(Prompt) 기호 

[student@ol9 ~]$      ← 일반 사용자 ($) 
[root@ol9 ~]#         ← root 관리자  (#) 

 사용자명 @ 호스트명  현재디렉터리  기호 
  student  @ ol9         ~           $ 

기호  의미 

$ 

# 

일반 사용자 프롬프트 

root (관리자) 프롬프트 — 권한에 주의 

사용자 전환 

```bash
$ su -                  # root로 전환 (환경변수 포함) 
$ su - student          # 특정 사용자로 전환 
$ sudo 명령어           # root 권한으로 단일 명령 실행 (권장) 
$ exit                  # 이전 사용자로 복귀 
```


주의:  실무에서는 보안상 root 직접 로그인 대신 일반 계정에서 sudo를 사용하는 것이 표준입

니다. 

### 5.2 명령어 구조와 도움말 

리눅스 명령어는 명령어(Command), 옵션(Options), 인수(Arguments) 세 요소로 구성됩니다. 

command  [options]  [arguments] 
  명령어    옵션        인수(대상) 

```bash
ls       -la        /home/student 
```
│         │          │ 
│         │          └── 인수: 대상 디렉터리 
│         └──────────── 옵션: -l(상세) + -a(숨김파일) 
└──────────────────────명령어: ls

요소 

설명 

예시 

명령어 (Com

실행할 프로그램 이름. 소문자·대소

ls, cp, grep, find 

mand) 

문자 구분 필수 

옵션 (Options

동작 방식 변경. - 단일 대시(축약) / 

-l, -a, --help, --all 

) 

-- 이중 대시(완전) 

인수 (Argume

명령어가 처리할 대상. 파일·디렉터

/etc, file.txt 

nts) 

리·문자열 등 

```bash
# 단일 대시 (축약형) — 여러 옵션 합산 가능 
$ ls -l -a -h          # 각각 분리 
$ ls -lah              # 합쳐서 사용 
```


```bash
# 이중 대시 (완전형) — 합산 불가 
$ ls --all             # --all = -a 와 동일 
$ ls --human-readable  # --human-readable = -h 와 동일 
```


man 페이지 — 공식 도움말 

man(Manual) 페이지는 모든 명령어의 공식 레퍼런스입니다. 옵션·예시·관련 파일 등이 상세히 수록

되어 있습니다. 

```bash
$ man ls               # ls 도움말 
$ man 5 passwd         # /etc/passwd 파일 형식 (섹션 5) 
$ man -k "disk"        # 키워드로 관련 man 페이지 검색 
```


man 내 단축키  기능 

Space / f 

다음 페이지 

b 

/ 검색어 

g / G 

q 

이전 페이지 

검색 (n: 다음, N: 이전) 

문서 처음 / 끝 

man 종료

기타 도움말 

방법 

설명 

예시 

--help 

info 

whatis 

빠른 옵션 요약 (man보다 간결) 

```bash
ls --help 
```


GNU 확장 문서 (더 상세) 

info ls 

명령어 한 줄 설명 

whatis ls 

apropos  키워드로 관련 명령어 검색 

apropos "copy file" 

type 

명령어 종류 확인 (내장/외부/alias) 

type ls 

### 5.3 CLI 효율 단축키 

CLI 환경에서 단축키를 익히면 작업 속도가 크게 향상됩니다. 

단축키 

기능 

Tab 

명령어/파일명 자동완성 (두 번 누르면 후보 목록) 

↑ / ↓ 

이전 / 다음 명령어 히스토리 

Ctrl + C 

실행 중인 명령 강제 취소 (SIGINT) 

Ctrl + Z 

명령 일시 중지 (백그라운드) 

Ctrl + D 

EOF 전송 / 로그아웃 

Ctrl + L 

화면 지우기 (clear 동일) 

Ctrl + A 

커서를 줄 맨 앞으로 

Ctrl + E 

커서를 줄 맨 끝으로 

Ctrl + U 

커서 앞 내용 모두 삭제 

Ctrl + K 

커서 뒤 내용 모두 삭제 

Ctrl + R 

역방향 히스토리 검색

단축키 

Alt + . 

기능 

이전 명령어의 마지막 인수 삽입 

히스토리 활용 

```bash
$ history              # 전체 명령어 히스토리 목록 
$ history | tail -20   # 최근 20개 
$ !499                 # 499번 명령어 재실행 
$ !!                   # 바로 이전 명령어 재실행 
```
  (Ctrl+R) grep        # "grep" 포함 명령어 역방향 검색 

### 5.4 환경변수와 bash 설정 파일 

환경변수는 셸 동작과 프로그램 실행에 영향을 주는 전역 값입니다. $ 기호로 참조합니다. 

주요 환경변수 

```bash
$ echo $HOME       # 홈 디렉터리 경로: /home/student 
$ echo $PATH       # 명령어 검색 경로 
$ echo $USER       # 현재 사용자명 
$ echo $SHELL      # 현재 셸: /bin/bash 
$ echo $PS1        # 프롬프트 형식 
$ echo $LANG       # 언어/로케일 설정 
$ env              # 모든 환경변수 목록 
$ export VAR=value # 환경변수 설정 및 내보내기 
```


bash 시작(설정) 파일 

파일 

역할 

/etc/profile 

/etc/bashrc 

시스템 전체 (모든 사용자, 로그인 셸) 

시스템 전체 (모든 사용자, 대화형 셸) 

~/.bash_profile 

개인 설정 — PATH, 환경변수 (로그인 셸) 

~/.bashrc 

개인 설정 — alias, 함수 (대화형 셸)

파일 

역할 

~/.bash_history 

명령어 히스토리 저장 

~/.bash_logout 

로그아웃 시 실행 

```bash
# alias 등록 예시 (~/.bashrc 에 추가) 
```
alias ll="ls -la" 
alias ..="cd .." 
alias grep="grep --color=auto" 

```bash
# 설정 즉시 반영 
$ source ~/.bashrc   # 또는  . ~/.bashrc 
```


### 5.5 Bash 스크립트 — 기초와 실행 

셸 스크립트는 bash 명령어들을 파일로 저장해 자동 실행하는 방법입니다. 시스템 관리·Oracle DB 

운영·반복 작업 자동화에 폭넓게 활용됩니다. 

스크립트 작성·실행 3 단계 

97.  파일 작성: vim hello.sh (첫 줄에 반드시 Shebang 선언) 

98.  실행 권한 부여: chmod +x hello.sh 

99.  실행: ./hello.sh  또는  bash hello.sh 

Shebang(#!) — 인터프리터 선언 

```bash
#!/bin/bash 
# 파일명: hello.sh 
# 설명  : 첫 번째 셸 스크립트 
```


echo "Hello, Oracle Linux!" 
echo "현재 날짜: $(date)" 
echo "현재 사용자: $USER" 
echo "커널 버전: $(uname -r)" 
```bash
$ chmod +x hello.sh 
$ ./hello.sh 
```
Hello, Oracle Linux! 
현재 날짜: Sat Jun 15 09:00:00 KST 2024 
현재 사용자: student 
커널 버전: 5.15.0-206.153.7.1.el9uek.x86_64

Tip:  디버깅 시 bash -x script.sh 로 실행하면 각 명령어 실행 전 내용을 출력해 오류를 찾기 

쉽습니다. 

### 5.6 셸 변수 

변수는 데이터를 저장하는 공간입니다. = 로 대입하고 $ 기호로 호출합니다. = 앞뒤에 공백이 없어

야 합니다. 

```bash
#!/bin/bash 
```


```bash
# 변수 선언 (= 앞뒤 공백 금지) 
```
NAME="Oracle Linux" 
VERSION=8 
DB_HOME="/u01/app/oracle" 

```bash
# 변수 호출 
```
echo "OS: $NAME" 
echo "버전: $VERSION" 
echo "DB 홈: ${DB_HOME}/product"   # {} 로 경계 명확히 

```bash
# 명령어 결과를 변수에 저장 
```
TODAY=$(date +%Y%m%d) 
KERNEL=$(uname -r) 
echo "날짜: $TODAY  커널: $KERNEL" 

특수 변수 

변수 

$0 

$1~$9 

$# 

$@ 

$? 

의미 

스크립트 파일명 자신 

위치 매개변수 (첫~아홉 번째 인수) 

전달된 인수 개수 

모든 인수 목록 (각각 별도 문자열) 

직전 명령어 종료 상태 (0=성공, 1이상=실패)

변수 

$$ 

의미 

현재 스크립트의 PID 

### 5.7 스크립트 함수 

함수는 반복 사용되는 코드 블록을 이름으로 묶는 구조입니다. 

```bash
#!/bin/bash 
```


```bash
# 함수 정의 
```
print_info() { 
    local LABEL=$1     # local: 함수 내 지역 변수 
    local VALUE=$2 
    echo "[INFO] $LABEL : $VALUE" 
} 

log() { 
    echo "[$(date +%H:%M:%S)] $1" | tee -a /tmp/script.log 
} 

```bash
# 함수 호출 (인수 전달) 
```
print_info "OS" "$(cat /etc/oracle-release)" 
print_info "커널" "$(uname -r)" 
log "스크립트 시작" 

### 5.8 흐름 제어 — if-else 

if 문은 조건이 참(0)이면 해당 블록을 실행합니다. 조건식은 [ ] 또는 [[ ]] 로 감쌉니다. 

조건식 주요 연산자 

분류 

연산자 

의미 

문자열 

=  /  !=  /  -z  /  -n 

같다 / 다르다 / 비어있다 / 비어있지않다 

숫자 

-eq / -ne / -lt / -le / -gt / 

같다 / 다르다 / 작다 / 작거나같다 / 크다 / 크거나같

-ge 

다

분류 

연산자 

의미 

파일 

-f / -d / -e / -r / -w / -x 

파일 / 디렉터리 / 존재 / 읽기 / 쓰기 / 실행 가능 

논리 

&& / || / ! 

AND / OR / NOT 

```bash
#!/bin/bash 
```


```bash
# root 권한 확인 
```
if [ "$EUID" -ne 0 ]; then 
    echo "[ERROR] root 권한이 필요합니다." 
    exit 1 
fi 

```bash
# 파일 존재 여부 확인 
```
FILE="/etc/oracle-release" 
if [ -f "$FILE" ]; then 
    echo "Oracle Linux 확인:" 
```bash
    cat "$FILE" 
```
elif [ -f "/etc/redhat-release" ]; then 
    echo "RHEL 계열 OS" 
else 
    echo "알 수 없는 OS" 
fi 

### 5.9 반복문 — for / while 

for 루프 

```bash
#!/bin/bash 
```


```bash
# 목록 순회 
```
for SVC in sshd firewalld chronyd; do 
    STATUS=$(systemctl is-active "$SVC" 2>/dev/null) 
    echo "$SVC : $STATUS" 
done 

```bash
# 숫자 범위 순회 
```
for i in $(seq 1 5); do 
    echo "번호: $i" 
done 

```bash
# 파일 목록 순회
```


for FILE in /etc/*.conf; do 
    [ -f "$FILE" ] && echo "$(du -sh $FILE)" 
done 

while 루프 

```bash
#!/bin/bash 
```


COUNT=5 
while [ $COUNT -gt 0 ]; do 
    echo "카운트다운: $COUNT" 
    COUNT=$(( COUNT - 1 )) 
    sleep 1 
done 
echo "완료!" 

### 5.10 케이스문 — case 

case 문은 변수 값에 따라 다중 분기를 처리합니다. if-elif가 많아질 때 가독성을 높입니다. 

```bash
#!/bin/bash 
# 서비스 관리 스크립트  (사용법: ./svc.sh <서비스명> <동작>) 
```


SERVICE=$1 
ACTION=$2 

case "$ACTION" in 
    start)   sudo systemctl start   "$SERVICE" ;; 
    stop)    sudo systemctl stop    "$SERVICE" ;; 
    restart) sudo systemctl restart "$SERVICE" ;; 
    status)  sudo systemctl status  "$SERVICE" ;; 
    *) 
        echo "사용법: $0 <서비스명> {start|stop|restart|status}" 
        exit 1 ;; 
esac 

### 5.11 종합 예제 — 시스템 점검 스크립트 

변수·함수·if·for·case를 모두 활용한 Oracle Linux 시스템 점검 스크립트입니다. 

```bash
#!/bin/bash 
# 파일명: system_check.sh
```


readonly LOGFILE="/tmp/syscheck_$(date +%Y%m%d_%H%M%S).log" 
readonly THRESHOLD=80 

log() { echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOGFILE"; } 

check_os() { 
    log "OS     : $(cat /etc/oracle-release 2>/dev/null)" 
    log "커널   : $(uname -r)" 
    log "가동시간: $(uptime -p)" 
} 

check_disk() { 
    for MOUNT in / /u01 /tmp; do 
        [ -d "$MOUNT" ] || continue 
        USAGE=$(df "$MOUNT" | tail -1 | awk "{print $5}" | tr -d %) 
        log "디스크 $MOUNT : ${USAGE}%" 
        [ "$USAGE" -ge "$THRESHOLD" ] && log "[WARN] $MOUNT 임계값 초과!" 
    done 
} 

check_services() { 
    for SVC in sshd firewalld chronyd; do 
        log "$SVC : $(systemctl is-active $SVC 2>/dev/null)" 
    done 
} 

log "점검 시작" 
check_os; check_disk; check_services 
log "완료 — 로그: $LOGFILE" 

📝 연습문제 

번호  문제 

정답 

Q1 

리눅스 기본 셸의 이름? 

bash (Bourne Again Shell) 

Q2 

root 사용자 프롬프트 기호? 

```bash
# (샵) 
```


Q3 

명령어의 3가지 구성 요소? 

명령어 · 옵션 · 인수 

Q4 

축약형 옵션과 완전형 옵션 대시 차이? 

축약: - (단일) / 완전: -- (이중) 

Q5 

자동완성 단축키? 

Tab (두 번: 후보 목록)

번호  문제 

정답 

Q6 

실행 중인 명령 강제 취소 단축키? 

Ctrl + C 

Q7 

역방향 히스토리 검색 단축키? 

Ctrl + R 

Q8 

man 페이지 종료 단축키? 

q 

Q9 

개인 alias를 저장하는 파일? 

~/.bashrc 

Q10 

Shebang 표기 방법? 

```bash
#!/bin/bash (첫 번째 줄) 
```


Q11  스크립트 실행 권한 부여 명령어? 

```bash
chmod +x 스크립트명 
```


Q12  변수 대입 시 = 앞뒤 공백은? 

공백 없음 필수 (NAME="값") 

Q13  전달된 인수 개수를 담는 특수 변수? 

$# 

Q14  직전 명령어 성공/실패 확인 변수? 

$? (0=성공) 

Q15 

if 문 종료 키워드? 

Q16 

for 루프 종료 키워드? 

Q17 

case 문 종료 키워드? 

fi 

done 

esac 

Q18 

case 각 케이스 종료 기호? 

;; (세미콜론 두 개) 

📝 실습 

100. 

101. 

102. 

103. 

104. 

105. 

106. 

107. 

108. 

셸 확인: echo $SHELL, cat /etc/shells 

단축키 연습: Ctrl+R 로 이전 명령어 검색, Tab 자동완성 3 회 

alias 등록: alias ll="ls -la" → ll 테스트 → ~/.bashrc 에 영구 저장 

hello.sh 작성 (Shebang + 이름·날짜·OS 출력) → chmod +x → 실행 

변수 스크립트: 이름·나이·직책 변수 선언 후 출력 

if 스크립트: 인수로 받은 파일이 존재하는지 확인 

for 스크립트: /etc/h 로 시작하는 파일 목록 출력 

case 스크립트: 인수 start/stop/status 에 따라 다른 메시지 출력 

system_check.sh 작성 후 bash -x 로 디버깅