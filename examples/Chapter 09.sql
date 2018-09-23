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



---------------------------------------------------------------------------
-- Index
---------------------------------------------------------------------------

--Comparing linear and binary search.
select * from launch where launch_id = :n;


--Find index heights.
select blevel+1 height, dba_indexes.*
from dba_indexes;


--Create bitmap index on low-cardinality columns.
create bitmap index launch_category_idx
on launch(launch_category);


--Create another bitmap index and show BITMAP AND operation.
--(NOT SHOWN IN BOOK.)
create bitmap index launch_status_idx
on launch(launch_status);

explain plan for
select *
from launch
where launch_status = 'failure'
	and launch_category = 'orbital';

select * from table(dbms_xplan.display);


--Create function based index.
create index launch_date_idx
on launch(trunc(launch_date));

select *
from launch
where trunc(launch_date) = date '1957-10-04';


--Make indexes unusable or usable.
alter index launch_date_idx unusable;
alter index launch_date_idx rebuild;


--Rebuild online, quickly, and then reset properties.
alter index launch_date_idx rebuild online nologging parallel;
alter index launch_date_idx logging;
alter index launch_date_idx noparallel;



---------------------------------------------------------------------------
-- Partitioning
---------------------------------------------------------------------------

--Our target query to optimize.
select * from launch where launch_category = 'orbital';


--Crate poor man's partitioning on LAUNCH table.
--Create a table for each LAUNCH_CATEGORY.
--(Only partially shown in book.)
create table launch_suborbital_rocket      as select * from launch where launch_category = 'suborbital rocket';
create table launch_military_missile       as select * from launch where launch_category = 'military missile';
create table launch_orbital                as select * from launch where launch_category = 'orbital';
create table launch_atmospheric_rocket     as select * from launch where launch_category = 'atmospheric rocket';
create table launch_suborbital_spaceplane  as select * from launch where launch_category = 'suborbital spaceplane';
create table launch_test_rocket            as select * from launch where launch_category = 'test rocket';
create table launch_deep_space             as select * from launch where launch_category = 'deep space';
create table launch_ballistic_missile_test as select * from launch where launch_category = 'ballistic missile test';
create table launch_sounding_rocket        as select * from launch where launch_category = 'sounding rocket';
create table launch_lunar_return           as select * from launch where launch_category = 'lunar return';

--Create a view that combines per-category tables together.
create or replace view launch_all as
select * from launch_suborbital_rocket      where launch_category = 'suborbital rocket' union all
select * from launch_military_missile       where launch_category = 'military missile' union all
select * from launch_orbital                where launch_category = 'orbital' union all
select * from launch_atmospheric_rocket     where launch_category = 'atmospheric rocket' union all
select * from launch_suborbital_spaceplane  where launch_category = 'suborbital spaceplane' union all
select * from launch_test_rocket            where launch_category = 'test rocket' union all
select * from launch_deep_space             where launch_category = 'deep space' union all
select * from launch_ballistic_missile_test where launch_category = 'ballistic missile test' union all
select * from launch_sounding_rocket        where launch_category = 'sounding rocket' union all
select * from launch_lunar_return           where launch_category = 'lunar return';

--To quickly compare these, run with autotrace on and notice how the
--LAUNCH_ALL view uses significantly less "consistent gets", and has
--many "FILTER" operations in the execution plan.
--This means Oracle is only selecting from the relevant table.
set autotrace on;
select /*+ full(launch) */ count(*) from launch where launch_category = 'orbital';
select count(*) from launch_all where launch_category = 'orbital';


--These return the same results, but LAUNCH_ALL is faster.
select * from launch where launch_category = 'orbital';
select * from launch_all where launch_category = 'orbital';


--Create and query a partitioned launch table.
create table launch_partition
partition by list(launch_category)
(
	partition p_sub values('suborbital rocket'),
	partition p_mil values('military missile'),
	partition p_orb values('orbital'),
	partition p_atm values('atmospheric rocket'),
	partition p_pln values('suborbital spaceplane'),
	partition p_tst values('test rocket'),
	partition p_dep values('deep space'),
	partition p_bal values('ballistic missile test'),
	partition p_snd values('sounding rocket'),
	partition p_lun values('lunar return')
) as
select * from launch;

select * from launch_partition where launch_category = 'orbital';


--Partition administration examples.
delete from launch_partition partition (p_orb);
alter table launch_partition truncate partition p_orb;



---------------------------------------------------------------------------
-- View
---------------------------------------------------------------------------

--View with "OR REPLACE" and "FORCE".
create or replace force view bad_view as
select * from does_not_exist;

--The view exists but is broken and throws this error:
--ORA-04063: view "JHELLER.BAD_VIEW2" has errors
select * from bad_view2;


--Create nested views and expand them.
create or replace view view1 as select 1 a, 2 b from dual;
create or replace view view2 as select a from view1;

declare
    v_output clob;
begin
    dbms_utility.expand_sql_text('select * from view2', v_output);
    dbms_output.put_line(v_output);
end;
/

SELECT "A1"."A" "A" FROM  (SELECT "A2"."A" "A" FROM  (SELECT 1 "A",2 "B" FROM "SYS"."DUAL" "A3") "A2") "A1"



---------------------------------------------------------------------------
-- User
---------------------------------------------------------------------------

--Create an application user account.
create user application_user
identified by "ridiculouslyLongPW52733042#$%^"
--Schema account option:
--  account lock
--18c schema account option:
--  no authentication
profile application_profile
default tablespace my_application_tablespace
quota unlimited on my_application_tablespace;


--Drop user and all its objects and privileges.
--drop user application_user cascade;



---------------------------------------------------------------------------
-- Sequence
---------------------------------------------------------------------------


