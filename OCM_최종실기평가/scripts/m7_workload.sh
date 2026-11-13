#!/bin/bash
# 모듈 7 업무 부하 (oracle, rac1). 문제 SQL 을 1000번 실행한다. 약 2분.
cat > /tmp/m7_q1.sql <<'EOS'
set termout off
declare n number; s number;
begin
  for i in 1..1000 loop
    select count(*), sum(o.amount) into n, s
      from orders o join customers c on c.cust_id = o.cust_id
     where o.status = 'PENDING' and c.region = 'SEOUL';
  end loop;
end;
/
exit
EOS
echo "$(date '+%F %T') 업무 부하 시작" | tee -a /home/oracle/exam/m7_workload.log
sqlplus -s ocmadm/"Ocm_2026#"@OCM_OLTP @/tmp/m7_q1.sql
echo "$(date '+%F %T') 업무 부하 종료" | tee -a /home/oracle/exam/m7_workload.log
