#!/bin/bash
# 모듈 3 시작 준비 (oracle, chicago-srv)
D=$(cd $(dirname $0); pwd)
mkdir -p /u03/app/oracle/ext /u03/app/oracle/dpdump
cp $D/orders_202607.csv /u03/app/oracle/ext/
sqlplus -s sales/"Ocm#Pass2026"@SALESPDB <<'EOS'
create table docs (doc_id number primary key, title varchar2(50), body clob)
  lob(body) store as basicfile (tablespace sales_data);
insert into docs
  select level, 'DOC'||level, to_clob(rpad('x',4000,'x'))||to_clob(rpad('y',4000,'y'))||level
  from dual connect by level <= 3000;
commit;
select count(*), sum(dbms_lob.getlength(body)) from docs;
EOS
echo "모듈 3 준비 완료"
