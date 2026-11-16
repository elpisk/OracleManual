#!/bin/bash
# "멈춘 것처럼 보이는 프로세스" 만들기 (18장 실습 05, 최종실습시험 05).
# 한 프로세스가 /tmp/app.lock 을 잡고 SEC 초 동안 놓지 않고, 다른 프로세스는 같은 잠금을 기다린다.
#
#   bash lock-wait.sh [초=300]
#   보는 법: ps -eo pid,stat,wchan:20,args | grep '[f]lock'
#            timeout 3 strace -p <기다리는 PID>      → flock(3, LOCK_EX 에서 멈춰 있음
#            ls -l /proc/<PID>/fd ; cat /proc/locks ; fuser -v /tmp/app.lock
#   풀기   : pkill -f 'flock /tmp/app.lock sleep'  → 기다리던 쪽이 got-lock 을 남기고 끝난다
sec=${1:-300}
nohup flock /tmp/app.lock sleep "$sec" >/dev/null 2>&1 </dev/null &
sleep 1
nohup flock /tmp/app.lock echo got-lock >/tmp/waiter.out 2>&1 </dev/null &
sleep 1
ps -eo pid,stat,wchan:20,args | grep '[f]lock /tmp/app.lock'
