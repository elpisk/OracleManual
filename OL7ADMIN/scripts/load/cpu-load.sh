#!/bin/bash
# CPU 부하: 아무 일도 하지 않고 CPU 만 쓰는 셸 루프 N 개를 SEC 초 동안 돌린다(18장 실습 01·04).
# stress 같은 별도 패키지 없이 기본 설치만으로 재현된다.
#
#   bash cpu-load.sh [개수=nproc] [초=300]
#   보는 법: top -b -n1 -o %CPU | head -12 ; mpstat -P ALL 2 1 ; vmstat 2 3
#   멈추기 : bash stop-load.sh   (또는 시간이 지나면 timeout 이 끝낸다)
n=${1:-$(nproc)}
sec=${2:-300}
for i in $(seq 1 "$n"); do
  # nohup ... & 를 한 줄에 단독으로 둔다. 원격 실행기에서 앞에 cd 를 붙이면 출력 채널을 잡고 멈춘다.
  nohup timeout "$sec" sh -c 'while :; do :; done' >/dev/null 2>&1 </dev/null &
done
sleep 1
echo "CPU 루프 $(pgrep -fc 'while :; do :; done')개, ${sec}초 뒤 자동 종료 (nproc=$(nproc))"
