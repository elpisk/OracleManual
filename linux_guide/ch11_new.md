# Chapter 11 — 프로세스 관리

11   프로세스 관리 

### 11.1 프로세스 개념 

프로세스는 실행 중인 프로그램을 말합니다. 각 프로세스는 고유한 PID(Process ID)를 가집니다. 

용어 

PID 

PPID 

TTY 

설명 

프로세스 고유 번호 

부모 프로세스 번호 

프로세스가 연결된 터미널 

STAT 

프로세스 상태 (R:실행 S:슬립 Z:좀비 D:I/O대기) 

### 11.2 ps — 프로세스 조회 

```bash
$ ps                      # 현재 터미널 프로세스 
$ ps aux                  # 모든 프로세스 상세 (가장 많이 사용) 
$ ps -ef                  # 전체 프로세스 (풀 포맷) 
$ ps aux | grep nginx     # nginx 프로세스 찾기 
$ ps --sort=-%cpu | head  # CPU 사용 순 정렬 
```


### 11.3 top / htop — 실시간 모니터링 

```bash
$ top          # 실시간 프로세스 모니터링 
```


  top 내에서 단축키: 
  q   : 종료 
  k   : 프로세스 종료 (PID 입력) 
  P   : CPU 사용률 기준 정렬 
  M   : 메모리 사용률 기준 정렬 
  1   : CPU 코어별 표시

### 11.4 kill — 프로세스 종료 

명령어 

설명 

```bash
kill -15 PID 
```


```bash
kill -9 PID 
```


```bash
kill -1 PID 
```


SIGTERM - 정상 종료 (기본값) 

SIGKILL - 강제 종료 (즉시) 

SIGHUP  - 재시작 (설정 재로드) 

killall nginx 

프로세스명으로 종료 

pkill nginx 

패턴으로 종료 

### 11.5 jobs / bg / fg — 백그라운드 실행 

```bash
$ sleep 100 &             # 백그라운드로 실행 (&) 
```
[1] 12345 

```bash
$ jobs                    # 백그라운드 작업 목록 
```
[1]+  Running    sleep 100 & 

```bash
$ fg %1                   # 1번 작업을 포그라운드로 
$ bg %1                   # 1번 작업을 백그라운드로 
```


```bash
$ Ctrl+Z                  # 현재 작업 일시 중지 
```


📝 실습 

143. 

144. 

145. 

146. 

모든 프로세스 목록 확인: ps aux | head -20 

bash 프로세스 찾기: ps aux | grep bash 

sleep 300 & 백그라운드 실행 후 kill 

top 실행 후 CPU 정렬(P), 1 분 뒤 종료(q)