#!/bin/bash
# ============================================================================
#  12_udev_asmdisk.sh — ASM 디스크 이름 고정
#  공유 SCSI 버스의 디스크는 노드마다 /dev/sdX 순서가 달라질 수 있다.
#  WWN(scsi_id) 으로 /dev/asmdisk/<이름> 을 만들어 고정한다.
#  두 노드 모두에서 실행하고, 결과 이름이 같은지 반드시 대조한다.
#
#  사용법: sudo bash 12_udev_asmdisk.sh
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
. "$CFG"
[ "$(id -u)" -eq 0 ] || { echo "root 로 실행한다."; exit 1; }

RULE=/etc/udev/rules.d/99-oracle-asmdisk.rules

echo "########## [1] 공유 디스크 식별 ##########"
found=0
for d in /dev/sd?; do
  n=$(basename $d)
  sz=$(lsblk -bdno SIZE $d 2>/dev/null) || continue
  gb=$((sz/1073741824))
  id=$(/lib/udev/scsi_id -g -u -d $d 2>/dev/null)
  printf "  %-5s %3dGB  %s\n" "$n" "$gb" "${id:-(WWN 없음)}"
  [ -n "$id" ] && found=$((found+1))
done
if [ $found -eq 0 ]; then
  echo
  echo "!! scsi_id 가 WWN 을 돌려주지 않는다."
  echo "   vmx 에 disk.EnableUUID = \"TRUE\" 가 있는지 확인하고 VM 을 재기동한다."
  exit 1
fi

echo "########## [2] 규칙 생성 ##########"
# 크기로 용도를 가른다
: > $RULE
ci=1; di=1; fi=1
for d in /dev/sd?; do
  sz=$(lsblk -bdno SIZE $d 2>/dev/null) || continue
  gb=$((sz/1073741824))
  id=$(/lib/udev/scsi_id -g -u -d $d 2>/dev/null)
  [ -z "$id" ] && continue
  case $gb in
    $DISK_GB_CRS)  name="crs${ci}";  ci=$((ci+1)) ;;
    $DISK_GB_DATA) name="data${di}"; di=$((di+1)) ;;
    $DISK_GB_FRA)  name="fra${fi}";  fi=$((fi+1)) ;;
    *) continue ;;
  esac
  printf 'KERNEL=="sd?", SUBSYSTEM=="block", PROGRAM=="/lib/udev/scsi_id -g -u -d $devnode", RESULT=="%s", SYMLINK+="asmdisk/%s", OWNER="grid", GROUP="asmadmin", MODE="0660"\n' \
    "$id" "$name" >> $RULE
  printf "  %-6s <- %s  (%s)\n" "$name" "$d" "$id"
done
echo "--- $RULE ---"
cat $RULE

echo "########## [3] 적용 ##########"
udevadm control --reload-rules
udevadm trigger --type=devices --action=change
sleep 3
ls -l /dev/asmdisk/ 2>&1
echo
echo "소유권 확인 (grid:asmadmin 0660 이어야 한다):"
ls -lL /dev/asmdisk/ 2>/dev/null | head -12
echo
echo "두 노드에서 이 출력의 이름과 WWN 이 같은지 대조하고 넘어간다."
