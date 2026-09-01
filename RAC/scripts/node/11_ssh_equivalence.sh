#!/bin/bash
# ============================================================================
#  11_ssh_equivalence.sh — grid / oracle 계정의 노드 간 SSH 등가성
#  두 노드 모두에서 순서대로 실행한다.
#    1단계) 양쪽에서  sudo bash 11_ssh_equivalence.sh keygen
#    2단계) 한쪽에서  sudo bash 11_ssh_equivalence.sh distribute   (상대 노드 root 암호 필요)
#    3단계) 양쪽에서  sudo bash 11_ssh_equivalence.sh verify
# ============================================================================
set -u
CFG="$(cd "$(dirname "$0")/.." && pwd)/config.env"
. "$CFG"
[ "$(id -u)" -eq 0 ] || { echo "root 로 실행한다."; exit 1; }

USERS="grid oracle"
HOSTS="$NODE1_NAME $NODE2_NAME"
ALL="$NODE1_NAME $NODE2_NAME ${NODE1_NAME}-priv ${NODE2_NAME}-priv"

keygen() {
  for u in $USERS; do
    su - $u -c "mkdir -p ~/.ssh; chmod 700 ~/.ssh"
    su - $u -c "[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa -q"
    echo "  $u 키 준비 완료: $(su - $u -c 'cat ~/.ssh/id_rsa.pub' | cut -c1-40)..."
  done
}

distribute() {
  # 두 노드의 공개키를 모아 양쪽 authorized_keys 에 같은 내용으로 넣는다.
  local peer
  for u in $USERS; do
    local tmp=/tmp/.ak_$u
    : > $tmp
    su - $u -c "cat ~/.ssh/id_rsa.pub" >> $tmp
    for h in $HOSTS; do
      [ "$h" = "$(hostname -s)" ] && continue
      peer=$h
      echo "  $u : $peer 의 공개키 수집 (암호 입력이 필요할 수 있다)"
      ssh -o StrictHostKeyChecking=no root@$peer "cat ~$u/.ssh/id_rsa.pub" >> $tmp
    done
    for h in $HOSTS; do
      if [ "$h" = "$(hostname -s)" ]; then
        cp $tmp ~$u/.ssh/authorized_keys
        chown $u:$INST_GROUP ~$u/.ssh/authorized_keys
        chmod 600 ~$u/.ssh/authorized_keys
      else
        scp -o StrictHostKeyChecking=no $tmp root@$h:~$u/.ssh/authorized_keys >/dev/null
        ssh -o StrictHostKeyChecking=no root@$h \
            "chown $u:$INST_GROUP ~$u/.ssh/authorized_keys; chmod 600 ~$u/.ssh/authorized_keys"
      fi
    done
    rm -f $tmp
    echo "  $u 배포 완료"
  done
  # 첫 접속의 확인 질문을 없앤다
  for h in $HOSTS; do
    ssh -o StrictHostKeyChecking=no root@$h "
      for u in $USERS; do
        su - \$u -c 'ssh-keyscan -H $ALL >> ~/.ssh/known_hosts 2>/dev/null; chmod 600 ~/.ssh/known_hosts'
      done" 2>/dev/null
  done
}

verify() {
  # BatchMode 로 검증한다. 암호를 물어봐야 하는 상황이면 즉시 실패하므로
  # 사람이 무심코 암호를 넣어 통과시키는 일이 없다.
  local fail=0
  for u in $USERS; do
    for h in $ALL; do
      r=$(su - $u -c "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 $h hostname" 2>&1)
      case "$r" in
        *${NODE1_NAME}*|*${NODE2_NAME}*) printf "  OK   %-7s -> %-14s %s\n" "$u" "$h" "$r" ;;
        *) printf "  FAIL %-7s -> %-14s %s\n" "$u" "$h" "$r"; fail=1 ;;
      esac
    done
  done
  [ $fail -eq 0 ] && echo "  등가성 정상" || { echo "  등가성 실패 — 위 항목을 해소한다."; exit 1; }
}

case "${1:-}" in
  keygen)     keygen ;;
  distribute) distribute ;;
  verify)     verify ;;
  *) echo "사용법: sudo bash 11_ssh_equivalence.sh {keygen|distribute|verify}"; exit 1 ;;
esac
