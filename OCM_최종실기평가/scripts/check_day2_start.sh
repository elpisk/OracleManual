#!/bin/bash
# 2일차 시작 상태 점검 (root, rac1 에서 실행)
GH=/u01/app/19.3.0/grid
ok=0; ng=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  [OK] $1"; ok=$((ok+1)); else echo "  [NG] $1"; ng=$((ng+1)); fi; }
asg() { su - grid -c "$1"; }
aso() { su - oracle -c "$1"; }
echo "== 2일차 시작 상태 점검"
chk "두 노드 클러스터 서비스 online" "[ \$($GH/bin/crsctl check cluster -all | grep -c 'is online') -eq 6 ]"
chk "노드 rac1·rac2 Active" "[ \$($GH/bin/olsnodes -s | grep -c Active) -eq 2 ]"
chk "디스크그룹 CRS·DATA·FRA 마운트" "[ \$(asg 'asmcmd lsdg --suppressheader' | grep -cE 'CRS/|DATA/|FRA/') -eq 3 ]"
chk "OCMDG 없음" "! asg 'asmcmd lsdg --suppressheader' | grep -q OCMDG"
for d in ocm1 ocm2 ocm3 ocm4; do
  chk "/dev/asmdisk/$d 4GB, grid:asmadmin" "[ -b /dev/asmdisk/$d ] && [ \$(stat -L -c %U:%G /dev/asmdisk/$d) = grid:asmadmin ] && [ \$(( \$(lsblk -bdno SIZE /dev/asmdisk/$d)/1073741824 )) -eq 4 ]"
done
chk "후보 디스크 4개(ocm1~4)" "[ \$(asg 'asmcmd lsdsk --candidate' | grep -c '/dev/asmdisk/ocm') -eq 4 ]"
chk "racdb 두 인스턴스 Open" "[ \$(aso 'srvctl status database -db racdb' | grep -c 'is running') -eq 2 ]"
chk "racdb NOARCHIVELOG" "aso \"echo 'archive log list' | sqlplus -s / as sysdba\" | grep -q 'No Archive Mode'"
chk "OCMPDB 없음" "! aso \"echo 'show pdbs' | sqlplus -s / as sysdba\" | grep -q OCMPDB"
chk "OCR 위치 +CRS 하나" "[ \$($GH/bin/ocrcheck -config | grep -c 'Device/File Name') -eq 1 ]"
chk "보팅 파일 3개" "[ \$(asg 'crsctl query css votedisk' | grep -c ONLINE) -eq 3 ]"
echo "== OK $ok / NG $ng"
