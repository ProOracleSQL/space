---------------------------------------------------------------------------
-- Create useful test data
---------------------------------------------------------------------------

--Generate three rows.
select level a from dual connect by level <= 3;


--Generate specific data.
select 1 a, 2 b from dual union all
select 0 a, 0 b from dual;



---------------------------------------------------------------------------
-- Create large test data
---------------------------------------------------------------------------

--Raises: ORA-30009: Not enough memory for CONNECT BY operation
select count(*) from
(
	select level from dual connect by level <= 999999999
);


--Generate large amounts of data.
create table test1(a number);
insert into test1 select level from dual connect by level <= 100000;
insert into test1 select * from test1;
insert into test1 select * from test1;
insert into test1 select * from test1;
...


---------------------------------------------------------------------------
-- How to build automated tests
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
-- Complete
---------------------------------------------------------------------------

--Create the table.
create table simple_table(simple_column number);

--Add sample data.
insert into simple_table select 1 from dual;

--Gather statistics if it's a performance problem.
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
-- Verifiable
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
-- Data dictionary views
---------------------------------------------------------------------------

--How many data dictionary objects are there?
--(I think older versions of the database used to include dynamic performance views in DICTIONARY.)
select distinct regexp_replace(regexp_replace(regexp_replace(regexp_replace(table_name, '^CDB_'), '^DBA_'), '^USER_'), '^ALL_')
from dictionary
where table_name not like '%V$%'
	and table_name not like '%X$%'
order by 1;


--Querying LONG in the data dictionary does not work.
--This query raises the exception "ORA-00932: inconsistent datatypes: expected CHAR got LONG".
select table_name, column_name, data_default
from dba_tab_columns
where to_char(data_default) = '0'
order by 1,2,3;


--The preceding query requires an extra step to work.
--First, Create a table with converted LONGs.
create table convert_tab_columns as
select table_name, column_name, to_lob(data_default) data_default
from dba_tab_columns
where data_default is not null;


--SQL*Plus settings to format the large results.
set linesize 120;
set pagesize 1000;
column table_name format a20;
column column_name format a11;
column data_default format a12;


--Use the new table instead.
select table_name, column_name, to_char(data_default) data_default
from convert_tab_columns
where to_char(data_default) = '0'
	and rownum = 1
order by 1,2,3;



---------------------------------------------------------------------------
-- Dynamic performance views
---------------------------------------------------------------------------

--How many dynamic performance views are there?
--(Note that the SYNONYMS are named "V$%", but the actual objects are named "V_$%".)
select object_name
from dba_objects
where owner = 'SYS'
	and object_name like 'V\_$%' escape '\'
order by object_name;



---------------------------------------------------------------------------
-- Other Oracle tools for inspecting databases
---------------------------------------------------------------------------

--Byte size of values:
select
	vsize(0) zero_size,
	vsize(1) one_size,
	vsize(10) ten_size,
	vsize(date '2000-01-01') date_size,
	vsize(cast('a' as varchar2(4000))) string_size
from dual;


--Create suspicious data.
create table random_links(url varchar2(15));
insert into random_links values('go' || unistr('\00f6') || 'gle.com');
commit;

--Query data. Depending on your IDE, it may look like a regular google.com.
select * from random_links;

--Look at the details.
select dump(url,16) from random_links;


--Setup for getting metadata.
set long 1000
set pagesize 1000

--Query for getting metadata.
select dbms_metadata.get_ddl(
	object_type => 'TABLE',
	name        => 'LAUNCH',
	schema      => 'SPACE') ddl
from dual;


--Get the name of the machine used to connect to the database.
select sys_context('userenv', 'host') from dual;