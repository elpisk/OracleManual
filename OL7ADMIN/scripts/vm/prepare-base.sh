#!/bin/bash
# os-installed 상태의 ol7a·ol7b 를 기준 상태(ol7-base / ol7b-base)로 만든다. 두 노드에서 각각 root 로 실행.
# 실측 랩에서 한 일(_ol7_scratch/labs/base/base1~3.lab)을 순서대로 모은 것이다.
#
#   bash prepare-base.sh            # 전부
#   bash prepare-base.sh --no-update   # yum update 를 건너뜀(커널 버전이 PRD 4.5 와 달라짐)
#
# 끝나면 재부팅해 확인하고, 전원을 끈 뒤 호스트에서 스냅샷을 뜬다(host/lab-snapshot.ps1 take).
# 계정(student, wheel)은 설치 때 만든 것을 그대로 쓴다. 암호는 이 스크립트가 다루지 않는다.
set -u
UPDATE=1
[ "${1:-}" = "--no-update" ] && UPDATE=0

[ "$(id -u)" -eq 0 ] || { echo "root 로 실행"; exit 1; }
grep -q 'release 7.9' /etc/oracle-release || { echo "Oracle Linux 7.9 가 아님: $(cat /etc/oracle-release)"; exit 1; }

echo "== 1. /etc/hosts — 두 노드를 서로 이름으로 찾게 한다"
grep -q 'ol7a.example.com' /etc/hosts || cat >> /etc/hosts <<'X'
172.16.225.61   ol7a.example.com   ol7a
172.16.225.62   ol7b.example.com   ol7b
X
grep ol7 /etc/hosts

echo "== 2. chrony — 설치 때 Network Time OFF 라 꺼져 있다"
systemctl enable --now chronyd
sleep 5; chronyc -a makestep; date
hwclock --systohc

if [ $UPDATE -eq 1 ]; then
  echo "== 3. yum update — 커널이 UEK 5.4.17-2136.*, RHCK 3.10.0-1160.119.* 로 올라간다"
  yum update -y 2>&1 | tail -15
fi

echo "== 4. 직렬 콘솔과 장치 순서 고정"
# console=tty0 console=ttyS0,115200 : 부팅 메시지를 직렬 포트로도 낸다(부팅 장애 실습 캡처용)
# scsi_mod.scan=sync : UEK 의 비동기 SCSI 스캔 때문에 OS 디스크가 sdb 로 잡힌 일이 있어 순서를 고정
if ! grep -q 'console=ttyS0' /etc/default/grub; then
  sed -i 's/^GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 console=tty0 console=ttyS0,115200 scsi_mod.scan=sync"/' /etc/default/grub
fi
grep -q GRUB_SERIAL_COMMAND /etc/default/grub || \
  printf 'GRUB_TERMINAL="console serial"\nGRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"\n' >> /etc/default/grub
sed -i '/^GRUB_TERMINAL_OUTPUT/d' /etc/default/grub
grep -E '^GRUB_(CMDLINE_LINUX|TERMINAL|SERIAL)' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
grubby --default-kernel
grubby --info=DEFAULT | grep ^args

echo "== 5. root 의 known_hosts 비우기 — 실습 15장이 첫 접속부터 보이게"
rm -f /root/.ssh/known_hosts; rmdir /root/.ssh 2>/dev/null

echo "== 6. 확인"
cat /etc/oracle-release
rpm -q kernel-uek kernel chrony firewalld | sort
rpm -qa | wc -l
getenforce
systemctl is-enabled chronyd firewalld
echo "재부팅 후 uname -r 과 cat /proc/cmdline, lsblk -o NAME,SIZE,HCTL 로 확인할 것"
