-- 1일차 업무 데이터 (모듈 2 시작 때 sales 계정으로 SALESPDB 에서 실행)
create table customers (cust_id number primary key, cust_name varchar2(40), region varchar2(10), grade varchar2(2));
insert /*+ append */ into customers
select level, 'CUST'||level, case when mod(level,10)<6 then 'SEOUL' when mod(level,10)<8 then 'BUSAN' else 'DAEGU' end,
       case when mod(level,10)<6 then 'A' else 'B' end
from dual connect by level <= 20000;
commit;
create table orders (order_id number primary key, cust_id number references customers, order_date date, status varchar2(10), amount number(10,2));
insert /*+ append */ into orders
select level, mod(level*7919,20000)+1, date '2025-01-01' + mod(level,540),
       case when mod(level,500)=0 then 'PENDING' when mod(level,10)<4 then 'SHIPPED' else 'DONE' end,
       round(mod(level*31,100000)/100,2)
from dual connect by level <= 300000;
commit;
create index orders_cust_ix on orders(cust_id) tablespace sales_idx;
create index orders_date_ix on orders(order_date) tablespace sales_idx;
exec dbms_stats.gather_schema_stats(user)
select table_name, num_rows from user_tables order by 1;
exit
