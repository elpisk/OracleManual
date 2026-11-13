#!/bin/bash
# 1일차 업무 데이터 적재 (oracle, chicago-srv). 모듈 2 시작 때 한 번 실행한다.
export ORACLE_SID=chicago
D=$(dirname $0)
sqlplus -s sales/"Ocm#Pass2026"@SALESPDB @$D/load_day1_sales.sql
sqlplus -s / as sysdba <<'EOS'
alter session set container=HRPDB;
create user hr identified by "Hr#Pass2026x" quota unlimited on sales_data;
grant create session, create table to hr;
create table hr.employees as
  select level emp_id, 'EMP'||level ename, mod(level,10)+10 dept_id, 3000+mod(level*37,5000) sal
  from dual connect by level <= 5000;
select count(*), sum(sal) from hr.employees;
EOS
: > /home/oracle/exam/business.log
echo "적재 완료"
