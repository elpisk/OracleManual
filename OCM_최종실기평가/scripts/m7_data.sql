-- 2일차 성능 모듈 데이터 (OCMPDB, ocmadm)
create table customers (cust_id number primary key, cust_name varchar2(40), region varchar2(10), grade varchar2(2), city varchar2(20));
insert /*+ append */ into customers
select level, 'CUST'||level,
       case when mod(level,100) < 60 then 'SEOUL' when mod(level,100) < 80 then 'BUSAN' else 'ETC'||mod(level,7) end,
       case when mod(level,100) < 60 then 'A' else 'B' end,
       case when mod(level,100) < 60 then 'GANGNAM' else 'CITY'||mod(level,50) end
from dual connect by level <= 50000;
commit;
create table orders (order_id number, cust_id number, order_date date, status varchar2(10), amount number(10,2), pad varchar2(100));
insert /*+ append */ into orders
select level, mod(level*7919, 50000)+1, date '2025-01-01' + mod(level, 600),
       case when mod(level,1000)=0 then 'PENDING' when mod(level,10)<3 then 'SHIPPED' when mod(level,10)<6 then 'CLOSED' else 'DONE' end,
       round(mod(level*31,100000)/100,2), rpad('x',100,'x')
from dual connect by level <= 1000000;
commit;
alter table orders add constraint orders_pk primary key (order_id);
create index orders_status_ix on orders(status);
create index orders_cust_ix on orders(cust_id);
exec dbms_stats.gather_table_stats(user,'CUSTOMERS',method_opt=>'for all columns size 1')
exec dbms_stats.gather_table_stats(user,'ORDERS',method_opt=>'for all columns size 1')
create sequence ocm_seq;
create table ocm_log (id number primary key, inst number, ts timestamp, msg varchar2(50));
select table_name, num_rows from user_tables order by 1;
