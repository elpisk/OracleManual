#!/bin/bash
# 1일차 시작 상태 점검 (root, chicago-srv 와 boston-srv 에서 각각 실행)
ok=0; ng=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  [OK] $1"; ok=$((ok+1)); else echo "  [NG] $1"; ng=$((ng+1)); fi; }
H=$(hostname -s)
echo "== $H 1일차 시작 상태 점검"
chk "호스트 이름이 chicago-srv 또는 boston-srv" "[ \"$H\" = chicago-srv -o \"$H\" = boston-srv ]"
chk "/etc/hosts 에 chicago-srv 172.16.225.60" "grep -qE '^172\.16\.225\.60[[:space:]]+chicago-srv' /etc/hosts"
chk "/etc/hosts 에 boston-srv 172.16.225.61" "grep -qE '^172\.16\.225\.61[[:space:]]+boston-srv' /etc/hosts"
chk "상대 서버 ping" "ping -c1 -W2 $([ \"$H\" = chicago-srv ] && echo boston-srv || echo chicago-srv)"
chk "방화벽 정지" "! systemctl is-active -q firewalld"
chk "DB 홈 19.3 설치" "[ -x /u01/app/oracle/product/19.3.0/dbhome_1/bin/oracle ]"
chk "/u03/app/oracle/oradata 디렉터리, oracle 소유" "[ \"$(stat -c %U /u03/app/oracle/oradata 2>/dev/null)\" = oracle ]"
chk "/u03/app/oracle/fast_recovery_area 디렉터리" "[ -d /u03/app/oracle/fast_recovery_area ]"
chk "실행 중인 데이터베이스 인스턴스 없음" "! pgrep -f ora_pmon_"
chk "oratab 에 등록된 데이터베이스 없음" "! grep -qE '^[A-Za-z]' /etc/oratab"
chk "listener.ora 없음 (시험에서 만든다)" "[ ! -f /u01/app/oracle/product/19.3.0/dbhome_1/network/admin/listener.ora ]"
chk "디스크 여유 25GB 이상" "[ $(df -BG --output=avail /u03 | tail -1 | tr -dc 0-9) -ge 25 ]"
echo "== OK $ok / NG $ng"
