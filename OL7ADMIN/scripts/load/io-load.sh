#!/bin/bash
# 블록 I/O 부하 (18장 실습 03, 최종실습시험 05). dd 로 페이지 캐시를 거치지 않는 쓰기·읽기를 만든다.
#
#   bash io-load.sh write [MB=750] [경로=/var/tmp/io.dat]   # 64KB 직접 쓰기
#   bash io-load.sh read  [초=60]  [경로=/var/tmp/io.dat]   # 64KB 직접 읽기를 반복
#   bash io-load.sh clean [경로]
#   보는 법: iostat -dxm sda dm-0 2 3 ; pidstat -d 2 1 ; cat /proc/PID/io
#
# oflag=direct / iflag=direct 를 빼면 쓰기는 페이지 캐시에 쌓였다가 나중에 한꺼번에 나가고,
# 읽기는 두 번째부터 캐시에서 나와 iostat 에 거의 안 보인다(18장 실습 03 오류 ①).
# 실습 VM 의 델타 디스크가 커지지 않도록 크기는 1~2GB 이내로 둔다.
set -u
mode=${1:-write}
case $mode in
  write)
    mb=${2:-750}; f=${3:-/var/tmp/io.dat}
    nohup dd if=/dev/zero of="$f" bs=64k count=$((mb * 16)) oflag=direct >/tmp/io-load.log 2>&1 </dev/null &
    echo "쓰기 시작: $f ${mb}MB (pid $!) — 끝나면 /tmp/io-load.log 에 속도가 남는다" ;;
  read)
    sec=${2:-60}; f=${3:-/var/tmp/io.dat}
    [ -f "$f" ] || dd if=/dev/zero of="$f" bs=1M count=500 conv=fdatasync status=none
    nohup timeout "$sec" sh -c "while :; do dd if=$f of=/dev/null bs=64k iflag=direct; done" >/dev/null 2>&1 </dev/null &
    echo "읽기 반복 ${sec}초: $f" ;;
  clean)
    pkill -x dd; rm -f "${2:-/var/tmp/io.dat}"; echo "정리함" ;;
  *) echo "write|read|clean"; exit 1;;
esac
