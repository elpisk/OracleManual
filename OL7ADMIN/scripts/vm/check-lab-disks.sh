#!/bin/bash
# 디스크 실습(9~12·20장) 시작 전 점검. ol7a 에서 root 로 실행.
#   1) OS 디스크가 sda(HCTL 2:0:0:0)이고 /boot 가 sda1 인지
#   2) 실습 디스크 sdb~sde 가 10GB 이고 서명·파티션·마운트가 없는지
# 하나라도 어긋나면 종료 코드 1. 그대로 wipefs·mkfs 를 치면 OS 디스크를 지울 수 있다.
# (실측 중 UEK 비동기 스캔으로 OS 디스크가 sdb 로 잡힌 일이 있다 — prepare-base.sh 4번 참고)
set -u
rc=0
osdisk=$(lsblk -dno NAME,HCTL | awk '$2=="2:0:0:0"{print $1}')
boot=$(findmnt -no SOURCE /boot)
echo "OS 디스크(HCTL 2:0:0:0) = ${osdisk:-없음}, /boot = $boot"
if [ "$osdisk" != sda ] || [ "$boot" != /dev/sda1 ]; then
  echo "FAIL  OS 디스크가 sda 가 아니다. 재부팅해서 다시 확인하고, 그래도 다르면 디스크 실습을 하지 말 것"
  rc=1
fi
for d in sdb sdc sdd sde; do
  dev=/dev/$d
  if [ ! -b $dev ]; then echo "FAIL  $dev 없음"; rc=1; continue; fi
  size=$(lsblk -dno SIZE $dev | tr -d ' ')
  hctl=$(lsblk -dno HCTL $dev | tr -d ' ')
  sigs=$(wipefs -n $dev 2>/dev/null | tail -n +2 | wc -l)
  parts=$(lsblk -nro NAME $dev | tail -n +2 | wc -l)
  mnt=$(lsblk -nro MOUNTPOINT $dev | grep -c .)
  md=$(grep -c "$d" /proc/mdstat)
  pv=$(pvs --noheadings -o pv_name 2>/dev/null | grep -c "$dev")
  st="OK  "
  if [ "$sigs" -ne 0 ] || [ "$parts" -ne 0 ] || [ "$mnt" -ne 0 ] || [ "$md" -ne 0 ] || [ "$pv" -ne 0 ]; then st="DIRTY"; rc=1; fi
  printf '%-5s %s  %-5s %-8s 서명 %d  파티션 %d  마운트 %d  md %d  pv %d\n' "$st" $dev "$size" "$hctl" $sigs $parts $mnt $md $pv
done
[ $rc -eq 0 ] && echo "실습 디스크 4개 모두 비어 있음" || echo "DIRTY 디스크는 vm/wipe-lab-disks.sh 로 비우거나 storage-clean 스냅샷으로 되돌릴 것"
exit $rc
