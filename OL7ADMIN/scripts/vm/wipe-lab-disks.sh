#!/bin/bash
# 실습 디스크(sdb~sde)를 비운다. 스냅샷 없이 다음 실습을 이어 갈 때 쓴다. ol7a 에서 root 로 실행.
# 순서: 마운트 해제 → 스왑 해제 → md 정지·슈퍼블록 삭제 → LVM 제거 → 서명 삭제.
# OS 디스크 확인을 통과하지 못하면 아무것도 지우지 않는다.
#
#   bash wipe-lab-disks.sh            # sdb sdc sdd sde
#   bash wipe-lab-disks.sh sdc sdd    # 지정한 것만
set -u
here=$(dirname "$0")
osdisk=$(lsblk -dno NAME,HCTL | awk '$2=="2:0:0:0"{print $1}')
[ "$osdisk" = sda ] && [ "$(findmnt -no SOURCE /boot)" = /dev/sda1 ] || { echo "OS 디스크가 sda 가 아님 - 중단"; exit 1; }

disks=${*:-sdb sdc sdd sde}
for d in $disks; do
  case $d in sda*) echo "sda 는 지우지 않는다"; exit 1;; esac
  hctl=$(lsblk -dno HCTL /dev/$d | tr -d ' ')
  case $hctl in 2:0:[1-4]:0) ;; *) echo "/dev/$d HCTL=$hctl - 실습 디스크 자리(2:0:1:0~2:0:4:0)가 아님, 중단"; exit 1;; esac
done

for d in $disks; do
  # 이 디스크 위의 마운트(파티션·LV·md 포함)를 깊은 것부터 해제
  for m in $(lsblk -nro MOUNTPOINT /dev/$d | grep '^/' | sort -r); do umount -l "$m" && echo "umount $m"; done
  for s in $(lsblk -nro NAME,TYPE /dev/$d | awk '{print "/dev/"$1}'); do swapoff "$s" 2>/dev/null; done
done
# md 배열: 구성원 중 하나라도 대상이면 정지
for md in $(awk '/^md/{print $1}' /proc/mdstat); do
  for d in $disks; do grep -q "^$md .*$d" /proc/mdstat && { mdadm --stop /dev/$md; break; }; done
done
for d in $disks; do
  for vg in $(pvs --noheadings -o vg_name /dev/$d* 2>/dev/null | sort -u); do vgremove -f "$vg"; done
  pvremove -ff -y /dev/$d* 2>/dev/null
  mdadm --zero-superblock /dev/$d* 2>/dev/null
  wipefs -a /dev/$d?* 2>/dev/null >/dev/null
  wipefs -a /dev/$d >/dev/null
  partprobe /dev/$d 2>/dev/null
done
sed -n '1,5p' /proc/mdstat
bash "$here/check-lab-disks.sh"
