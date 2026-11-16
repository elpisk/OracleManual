#!/bin/bash
# 메모리 압박 (18장 실습 02). memhog.py 를 이름이 다른 세 프로세스로 띄운다.
#   dbsim   : 크게 잡고 가만히 있는 프로세스(SGA 흉내)
#   batch   : 잡은 페이지를 계속 건드리는 프로세스 → 스왑 입출력(si·so)을 만든다
#   runaway : 조금씩 늘어나는 프로세스 → OOM 킬러가 누구를 고르는지 본다
#
#   bash mem-load.sh hold  1500 600     # dbsim 1.5GB 600초
#   bash mem-load.sh swap  2100 80      # batch 2.1GB, 페이지 건드림 → si·so
#   bash mem-load.sh oom   2400 60      # runaway 2.4GB. 스왑을 끄고(swapoff -a) 하면 바로 OOM
#   보는 법: free -m ; vmstat 3 5 ; grep VmSwap /proc/PID/status ; dmesg -T | grep -i 'killed process'
#   ol7a(메모리 3.6GB, 스왑 3.9GB) 기준 값이다. ol7b(1.7GB)에서는 수치를 절반 이하로.
set -u
here=$(cd "$(dirname "$0")" && pwd)
dir=/root/load
mkdir -p $dir
cp -f "$here/memhog.py" $dir/
py=$(command -v python2.7 || command -v python)
for n in dbsim batch runaway; do ln -sf "$py" $dir/$n; done

mode=${1:-hold}; mb=${2:-1500}; sec=${3:-600}
case $mode in
  hold)  nohup $dir/dbsim   $dir/memhog.py "$mb" "$sec"   >/dev/null 2>&1 </dev/null & ;;
  swap)  nohup timeout $((sec + 20)) $dir/batch $dir/memhog.py "$mb" "$sec" 1 >/dev/null 2>&1 </dev/null & ;;
  oom)   nohup timeout $((sec + 60)) $dir/runaway $dir/memhog.py "$mb" "$sec" >/dev/null 2>&1 </dev/null & ;;
  *) echo "hold|swap|oom"; exit 1;;
esac
sleep 3
ps -o pid,rss,vsz,pmem,comm -C dbsim,batch,runaway
free -m
