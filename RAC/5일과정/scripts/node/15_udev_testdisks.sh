#!/bin/bash
# ============================================================================
#  15_udev_testdisks.sh — ASM 실습용 test 디스크 이름 고정 (설치 가이드 v2 부록 E)
#  host/04_add_test_disks.ps1 로 붙인 4GB 디스크 6개에 /dev/asmdisk/test1~6 을 만든다.
#
#  test 디스크는 crs 디스크와 크기(4GB)가 같으므로 12_udev_asmdisk.sh 를 다시
#  돌리면 test 디스크가 crs4~crs9 로 잡힌다. 이 스크립트는 기존 규칙을 건드리지
#  않고, 규칙 파일에 없는 WWN 만 골라 뒤에 덧붙인다.
#  rac1 에서 만든 규칙 파일을 rac2 에 그대로 복사해 두 노드의 이름을 맞춘다.
#
#  사용법: rac1 에서 root 로  bash 15_udev_testdisks.sh
#          (rac2 root 암호를 두 번 묻는다 — scp, ssh)
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
. "$CFG"
[ "$(id -u)" -eq 0 ] || { echo "root 로 실행한다."; exit 1; }
[ "$(hostname -s)" = "$NODE1_NAME" ] || { echo "$NODE1_NAME 에서 실행한다."; exit 1; }

RULE=/etc/udev/rules.d/99-oracle-asmdisk.rules
[ -f $RULE ] || { echo "$RULE 이 없다. 12_udev_asmdisk.sh 가 먼저다."; exit 1; }

if grep -q 'asmdisk/test' $RULE; then
  echo "이미 test 규칙이 있다. 건너뛴다."
  grep -o 'asmdisk/test[0-9]*' $RULE
else
  cp -p $RULE /root/99-oracle-asmdisk.rules.before_test
  echo "########## [1] 규칙에 없는 4GB 디스크 ##########"
  n=1
  for d in /dev/sd?; do
    id=$(/lib/udev/scsi_id -g -u -d $d 2>/dev/null)
    [ -z "$id" ] && continue
    grep -q "$id" $RULE && continue
    gb=$(( $(lsblk -bdno SIZE $d) / 1073741824 ))
    [ $gb -eq 4 ] || continue
    printf 'KERNEL=="sd?", SUBSYSTEM=="block", PROGRAM=="/lib/udev/scsi_id -g -u -d $devnode", RESULT=="%s", SYMLINK+="asmdisk/test%d", OWNER="grid", GROUP="asmadmin", MODE="0660"\n' \
      "$id" "$n" >> $RULE
    printf "  test%-2d <- %s  (%s)\n" "$n" "$d" "$id"
    n=$((n+1))
  done
  if [ $n -ne 7 ]; then
    echo "!! test 디스크가 $((n-1))개다. 6개여야 한다. 규칙을 되돌린다."
    cp -p /root/99-oracle-asmdisk.rules.before_test $RULE
    exit 1
  fi
fi

echo "########## [2] rac1 적용 ##########"
udevadm control --reload-rules
udevadm trigger --type=devices --action=change
sleep 3

echo "########## [3] rac2 에 같은 규칙 복사·적용 ##########"
scp -p $RULE root@$NODE2_NAME:$RULE || exit 1
ssh root@$NODE2_NAME "udevadm control --reload-rules; udevadm trigger --type=devices --action=change; sleep 3" || exit 1

echo "########## [4] 확인 — 두 노드의 WWN 대조 ##########"
for i in 1 2 3 4 5 6; do
  a=$(/lib/udev/scsi_id -g -u -d /dev/asmdisk/test$i 2>/dev/null)
  b=$(ssh root@$NODE2_NAME "/lib/udev/scsi_id -g -u -d /dev/asmdisk/test$i 2>/dev/null")
  st=$([ -n "$a" ] && [ "$a" = "$b" ] && echo OK || echo "!! 불일치")
  printf "  test%d  %s  %s  %s\n" "$i" "${a:-없음}" "${b:-없음}" "$st"
done
ls -lL /dev/asmdisk/test* 2>/dev/null
echo
echo "다음: grid 로 v\$asm_disk 에서 test1~6 이 CANDIDATE 인지 확인하고 기준 스냅샷을 다시 뜬다."
