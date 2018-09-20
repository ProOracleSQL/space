---------------------------------------------------------------------------
-- ALTER
---------------------------------------------------------------------------

--Counting number of ALTER commands.
select * from v$sqlcommand where lower(command_name) like '%alter%'



---------------------------------------------------------------------------
-- Table
---------------------------------------------------------------------------

--Create a simple table and see some of its metadata.
create table simple_table(a number, b varchar2(100), c date);
select dbms_metadata.get_ddl('TABLE', 'SIMPLE_TABLE') from dual;
select * from user_tables where table_name = 'SIMPLE_TABLE';
select * from user_tab_columns where table_name = 'SIMPLE_TABLE';


--Temporary table example.

--Create a temporary table that hold data until next commit.
create global temporary table temp_table(a number)
on commit delete rows;

--Insert data and it shows up ONLY in your session.
insert into temp_table values(1);
select count(*) from temp_table;

--But once you commit, the data is gone.
commit;
select count(*) from temp_table;


--Enable temporary undo in the session.
--This will only work if the session has not already used the temporary
--tablespace.  Only works in 12.1+.
alter session set temp_undo_enabled = true;


--Private temporary table example, only works in 18c+.
--Create a private temporary table. 
create private temporary table ora$ptt_private_table(a number)
on commit drop definition;


--Object table example.
--(Not shown in book.)
create or replace type simple_object_test is object (a number, b number);
create table simple_object_table_test of simple_object_test;
select * from simple_object_table_test;


--Table with XMLType.
--(Not shown in book.)
create table xml_table1(a xmltype) xmltype a store as binary xml;
create table xml_table2(a xmltype) xmltype a store as clob;


--Column properties.
--Default, virtual, inline check, and invisible.
create table weird_columns
(
	a number default 1,
	b number as (a+1),
	c number check (c >= 0),
	d number invisible
);

insert into weird_columns(c,d) values (3,4);

select * from weird_columns;


--Identity column and sequence default.
create sequence test_sequence;

create table identity_table
(
	a number generated as identity,
	b number default test_sequence.nextval,
	c number
);

insert into identity_table(c) values(1);
select * from identity_table;


--Create index organized table.
create table iot_table
(
	a number,
	b number,
	constraint iot_table_pk primary key(a)
)
organization index;


--Create a table without deferred segment creation.
create table deferred_segment_table(a number)
segment creation immediate;

--Force Oracle to create a segment.
alter table deferred_segment_table allocate extent;


--Compression.
--Create a compressed table.
create table compressed_table(a number) compress;

--Compression will only happen for direct-path inserts.
--Periodically MOVE the table if we can't use direct-path inserts.
alter table compressed_table move compress;


--Create table with parallelism enabled by default.
create table parallel_table(a number) parallel;



---------------------------------------------------------------------------
-- Constraint
---------------------------------------------------------------------------

--This statement on a NOT NULL column can use an index.
select count(distinct satellite_id) from satellite;
--This statement on a nullable column cannot use an index.
select count(distinct launch_id) from satellite;


--Create separate table for organization data.
create table organization_temp nologging as
select * from organization
where 1=2;

--Create a unique constraint.
alter table organization_temp
add constraint organization_temp_uq
unique(org_name, org_start_date, org_location);

--Disable the constraint.
alter table organization_temp
disable constraint organization_temp_uq;

--Load data.
insert into organization_temp
select * from organization;


--Try to enable constraint that isn't valid.
alter table organization_temp
enable constraint organization_temp_uq
exceptions into exceptions;


--Rows that blocked the constraint.
select *
from organization_temp
where rowid in (select row_id from exceptions);


--Create a non-unique index for the constraint.
create index organization_temp_idx1
on organization_temp(org_name, org_start_date, org_location)
compress 2;

--Enable NOVALIDATE the constraint, with a non-unique index.
alter table organization_temp
enable novalidate constraint organization_temp_uq
using index organization_temp_idx1;


--Create new table to demonstration parallel constraint enabling.
--(NOT SHOWN IN BOOK)
create table organization_parallel nologging as
select * from organization;

alter table organization_parallel modify org_code varchar2(20);

--Increase rows to about 10 million.
--(NOT SHOWN IN BOOK)
begin
	for i in 1 .. 3674 loop
		insert /*+ append */ into organization_parallel
		select org_code||'|'||i, org_name, org_class,
			parent_org_code, org_state_code, org_location, org_start_date,
			org_stop_date, org_utf8_name
		from organization;
		commit;
	end loop;
end;
/

--Create primary key constraint.
--(NOT SHOWN IN BOOK)
alter table organization_parallel
add constraint organization_parallel_pk primary key(org_code);


--Set the table to run in parallel.
alter table organization_parallel parallel;

--Create constraint, but have it initially disabled.
alter table organization_parallel
add constraint organization_parallel_fk foreign key (parent_org_code)
references organization_parallel(org_code) disable;

--Validate it, which makes it run in parallel.
alter table organization_parallel
modify constraint organization_parallel_fk validate;

--Change the table back to NOPARALLEL when done.
alter table organization_parallel noparallel;


--Run this concurrent with above statement to see parallelism.
--(NOT SHOWN IN BOOK)
select * from v$px_process;
