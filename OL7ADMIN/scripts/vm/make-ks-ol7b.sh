#!/bin/bash
# ol7a 의 anaconda-ks.cfg 를 고쳐 ol7b 용 kickstart 를 만들고 HTTP 로 내보낸다(2장 실습 04 의 준비).
# ol7a 에서 root 로 실행. ol7b VM 은 설치 ISO 로 부팅해 GRUB 화면에서 다음을 덧붙인다.
#     inst.ks=http://172.16.225.61:8000/ks-ol7b.cfg
# 바꾸는 것: graphical→text, firstboot 끔, IP .61→.62, 호스트 이름, ens33 줄 삭제,
#            clearpart --all + zerombr + reboot (빈 디스크 전체 사용, 끝나면 재부팅)
# 암호 줄(rootpw/user)은 ol7a 의 해시를 그대로 물려받는다. 다른 암호를 쓰려면
#   python -c 'import crypt; print(crypt.crypt("새암호", crypt.mksalt(crypt.METHOD_SHA512)))'
# 로 해시를 만들어 rootpw --iscrypted 뒤를 바꾼다.
set -eu
src=/root/anaconda-ks.cfg
out=/root/ks-ol7b.cfg
port=${1:-8000}
cp $src $out
sed -i -e 's/^graphical/text/' \
       -e 's/^firstboot --enable/firstboot --disable/' \
       -e 's/--ip=172.16.225.61/--ip=172.16.225.62/' \
       -e 's/ol7a.example.com/ol7b.example.com/' \
       -e '/--device=ens33/d' \
       -e 's/^clearpart --none --initlabel/clearpart --all --initlabel\nzerombr\nreboot/' $out
diff $src $out || true

rpm -q pykickstart >/dev/null || yum install -y -q pykickstart
ksvalidator -v RHEL7 $out && echo "ksvalidator 통과"

mkdir -p /var/www/ks
install -m 644 $out /var/www/ks/
firewall-cmd --add-port=${port}/tcp            # runtime 만. 끝나면 firewall-cmd --reload 로 닫힌다
cd /var/www/ks
nohup python -m SimpleHTTPServer $port >/tmp/ks-http.log 2>&1 </dev/null &
sleep 2
curl -s http://172.16.225.61:${port}/ks-ol7b.cfg | head -3
echo "설치가 끝나면: pkill -f 'SimpleHTTPServer $port'; firewall-cmd --reload"
