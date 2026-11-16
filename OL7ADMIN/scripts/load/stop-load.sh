#!/bin/bash
# load/ 스크립트가 띄운 부하를 모두 멈추고 남은 파일을 지운다.
pkill -f 'while :; do' 2>/dev/null
pkill -x dd 2>/dev/null
pkill -x dbsim 2>/dev/null; pkill -x batch 2>/dev/null; pkill -x runaway 2>/dev/null
pkill -f 'flock /tmp/app.lock' 2>/dev/null
sleep 1
rm -f /var/tmp/io.dat /tmp/io-load.log /tmp/waiter.out /tmp/app.lock
echo "남은 부하 프로세스: $(pgrep -fc 'while :|memhog.py|flock /tmp/app.lock|^dd ')"
uptime
free -m | head -2
