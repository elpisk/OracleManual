#!/bin/bash
# =============================================================================
#  rc_wallet_check.sh  —  TDE 지갑 상태 점검과 정기 백업
#  출처   : 고급 실습 09
#  실행   : rc_wallet_check.sh <SID>   (oracle 계정, 야간 백업 전 매일)
#  종료값 : 0 정상 / 1 지갑 닫힘·파일 없음(즉시 조치, 백업이 실패한다)
#
#  지갑 백업은 데이터베이스 백업과 다른 매체($WALLET_BK)에 둔다.
#  백업 매체에 지갑이 섞이면 암호화의 의미가 사라진다.
# =============================================================================
SID=$1
# ---- 환경에 맞게 수정할 값 ----
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
CATALOG="rcatowner/oracle_4U@rcat"
WALLET_BK=/backup_wallet/$SID
MAILTO="dba-team@example.com"
# --------------------------------
export ORACLE_SID=$SID
export PATH=$ORACLE_HOME/bin:$PATH
mkdir -p $WALLET_BK

STATUS=$(sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF HEADING OFF
SELECT status || '|' || wallet_type || '|' || wrl_parameter
FROM v$encryption_wallet WHERE ROWNUM = 1;
EXIT
EOF
)

WSTATUS=$(echo $STATUS | cut -d'|' -f1)
WTYPE=$(echo $STATUS | cut -d'|' -f2)
WPATH=$(echo $STATUS | cut -d'|' -f3)

echo "wallet: status=$WSTATUS type=$WTYPE path=$WPATH"

# --- 점검 1 : 백업 암호화가 켜져 있는데 지갑이 닫혀 있는가
ENC=$(rman target / catalog $CATALOG << 'EOF' 2>/dev/null | grep 'ENCRYPTION FOR DATABASE'
SHOW ENCRYPTION FOR DATABASE;
EXIT
EOF
)
if echo "$ENC" | grep -q 'ON' && [ "$WSTATUS" != "OPEN" ]; then
  MSG="[CRIT] encryption is ON but wallet is $WSTATUS - backup will fail"
  echo "$MSG"; echo "$MSG" | mailx -s "[CRIT] wallet closed ($SID)" $MAILTO
  exit 1
fi

# --- 점검 2 : 지갑 파일이 실제로 있는가
if [ ! -f "${WPATH}ewallet.p12" ]; then
  MSG="[CRIT] wallet file missing: ${WPATH}ewallet.p12"
  echo "$MSG"; echo "$MSG" | mailx -s "[CRIT] wallet file missing ($SID)" $MAILTO
  exit 1
fi

# --- 지갑 백업 (백업 매체와 다른 위치로)
D=$(date +%Y%m%d)
tar czf $WALLET_BK/wallet_${SID}_${D}.tar.gz -C "$(dirname ${WPATH%/})" \
  "$(basename ${WPATH%/})" 2>/dev/null
chmod 600 $WALLET_BK/wallet_${SID}_${D}.tar.gz

# --- 보관 세대 관리 (30세대)
ls -1t $WALLET_BK/wallet_${SID}_*.tar.gz | tail -n +31 | xargs -r rm -f

echo "[OK] wallet checked and backed up : $WALLET_BK/wallet_${SID}_${D}.tar.gz"
