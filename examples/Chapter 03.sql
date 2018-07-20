---------------------------------------------------------------------------
-- 3.1.3
---------------------------------------------------------------------------

/*
	First, download the latest .zip file from here: https://github.com/utPLSQL/utPLSQL/releases

	Follow the steps on this page: http://utplsql.org/utPLSQL/latest/userguide/install.html

	You probably only need these steps:
	cd source
	sqlplus sys/sys_pass@db as sysdba @install_headless.sql

	Then grant your user some SELECT privileges on the space schema.  For example:

	SQL> grant select on space.launch to jheller;

	Grant succeeded.

	SQL> grant select on space.satellite to jheller;

	Grant succeeded.
*/


--Create package specification:
create or replace package space_test as
	-- %suite(Space)

	-- %test(Check number of rows in launch)
	procedure test_launch_count;

	-- %test(Check number of rows in satellite)
	procedure test_satellite_count;
end;
/


--Create package body:
create or replace package body space_test as
	procedure test_launch_count is
		v_count number;
	begin
		select count(*) into v_count from space.launch;
		ut.expect(v_count).to_(equal(70535));
	end;

	procedure test_satellite_count is
		v_count number;
	begin
		select count(*) into v_count from space.satellite;
		ut.expect(v_count).to_(equal(9999));
	end;
end;
/


--Run unit tests:
begin
  ut3.ut.run();
end;
/




---------------------------------------------------------------------------
-- 3.2.3
---------------------------------------------------------------------------

--Create the table.
create table simple_table(simple_column number);

--Add sample data.
insert into simple_table select 1 from dual;

--Gather statistics, if it's a performance problem.
begin
	dbms_stats.gather_table_stats(user, 'simple_table');
end;
/

--This is the query that fails, or is slow.
select *
from simple_table;



--Nondefault parameters.
select name, value
from v$parameter
where isdefault = 'FALSE'
order by name;



---------------------------------------------------------------------------
-- 3.2.4
---------------------------------------------------------------------------

SQL> set sqlprompt "_user'@'_connect_identifier> "
JHELLER@orcl9> set timing on
JHELLER@orcl9> select count(*) from dba_objects;

  COUNT(*)
----------
     74766

Elapsed: 00:00:00.21
JHELLER@orcl9>



---------------------------------------------------------------------------
-- 3.3.1
---------------------------------------------------------------------------

--How many data dictionary objects are there?
select distinct regexp_replace(regexp_replace(regexp_replace(regexp_replace(table_name, '^CDB_'), '^DBA_'), '^USER_'), '^ALL_')
from dictionary
where table_name not like '%V$%'
	and table_name not like '%X$%'
order by 1;


set linesize 120;
set pagesize 1000;
column table_name format a20;
column column_name format a11;
column data_default format a12;



--Querying LONG in the data dictionary does not work.
--This throws 
select table_name, column_name, data_type, data_default
from dba_tab_columns
where to_char(data_default) = '0'
order by 1,2,3;


--This simple operation still requires an extra step.
create table convert_tab_columns as
select table_name, column_name, to_lob(data_default) data_default
from dba_tab_columns
where data_default is not null;

select table_name, column_name, to_char(data_default) data_default
from convert_tab_columns
where to_char(data_default) = '0'
	and rownum = 1
order by 1,2,3;



---------------------------------------------------------------------------
-- 3.3.2
---------------------------------------------------------------------------

--How many data dictionary objects are there?
select distinct regexp_replace(table_name, '^G')
from dictionary
where regexp_like(table_name, '^G?V\$')
order by 1;



