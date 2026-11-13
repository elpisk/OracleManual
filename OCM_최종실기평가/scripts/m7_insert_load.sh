#!/bin/bash
# 모듈 7 RAC 입력 부하. rac1·rac2 양쪽에서 동시에 실행한다 (oracle). 세션 4개 × 5000건.
cat > /tmp/m7_ins.sql <<'EOS'
set termout off
begin
  for i in 1..5000 loop
    insert into ocm_log values (ocm_seq.nextval, sys_context('userenv','instance'), systimestamp, 'load');
    commit;
  end loop;
end;
/
exit
EOS
start=$(date +%s.%N)
for i in 1 2 3 4; do
  sqlplus -s ocmadm/"Ocm_2026#"@OCM_AC @/tmp/m7_ins.sql &
done
wait
end=$(date +%s.%N)
echo "$(hostname -s) elapsed $(echo "$end - $start" | bc) s"
