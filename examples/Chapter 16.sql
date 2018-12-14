---------------------------------------------------------------------------
-- O(1/N) - Batch size performance with sequences
---------------------------------------------------------------------------

--(NOT SHOWN IN BOOK).

--Test sequence size and if it matters.

--#1A: Create tables to hold data.
--drop table sequence_source_data purge;
--drop table sequence_target purge;
--drop table sequence_time_results purge;

create table sequence_source_data(a number) nologging;
begin
	for i in 1 .. 10 loop
		insert into sequence_source_data
		select level from dual connect by level <= 100000;
	end loop;
	commit;
end;
/

create table sequence_target(
	a1 number, a2 number, a3 number, a4 number, a5 number,
	a6 number, a7 number, a8 number, a9 number, a10 number
) nologging;

create table sequence_time_results(cache_size number, seconds number);

--#2A: Create initial sequence.
drop sequence cache_test;
create sequence cache_test nocache minvalue 1;

--#3A: Run test on increasing cache sizes.
--This will probably take hours to run.
declare
	v_start_time number;
	v_end_time   number;
	v_seconds    number;
begin
	for i in 1 .. 1000 loop
		--Drop and recreate sequence with the cache size.
		execute immediate 'drop sequence cache_test';
		if i = 1 then
			execute immediate 'create sequence cache_test nocache minvalue 1';
		else
			execute immediate 'create sequence cache_test cache '||i||' minvalue 1';
		end if;

		--Start the test.
		v_start_time := dbms_utility.get_time;

		insert /*+ append */ into sequence_target
		select cache_test.nextval, cache_test.nextval, cache_test.nextval, cache_test.nextval, cache_test.nextval,
			cache_test.nextval, cache_test.nextval, cache_test.nextval, cache_test.nextval, cache_test.nextval
		from sequence_source_data;

		--Record time and rollback.
		v_end_time := dbms_utility.get_time;
		v_seconds := (v_end_time - v_start_time) / 100;
		rollback;

		insert into sequence_time_results values(i, v_seconds);
		commit;
	end loop;
end;
/

--#4A: Look at results.
--Create a chart of the data and investigate curve.
select* from sequence_time_results order by cache_size;


--#1B: Test Limit Size and see if it matters.
--Create schema: tyhpe to hold rows, table to hold data, and insert data.
--Takes about 20 seconds to generate 102,400,000 rows.
create or replace type number_nt is table of number;
create table limit_test(a number) nologging;
insert into limit_test select level from dual connect by level <= 100000;
begin
	for i in 1 .. 7 loop
		insert /*+ append */ into limit_test select * from limit_test;
		commit;
	end loop;
end;
/
create table limit_time_results(limit_size number, seconds number);

--#2B: Run test and generate results with different LIMIT sizes.
declare
	v_rows number_nt;
	cursor v_cursor is select * from limit_test;

	v_start_time number;
	v_end_time   number;
	v_seconds    number;
begin
	--Try for numbers 1 to 1000.
	for v_limit in 1 .. 1000 loop
		--Start the test.
		v_start_time := dbms_utility.get_time;

		open v_cursor;
		loop
			fetch v_cursor
			bulk collect into v_rows
			limit v_limit;

			exit when v_cursor%notfound;
		end loop;

		--Record time and rollback.
		v_end_time := dbms_utility.get_time;
		v_seconds := (v_end_time - v_start_time) / 100;
		rollback;

		insert into limit_time_results values(v_limit, v_seconds);
		commit;

		close v_cursor;	
	end loop;
end;
/

--#2C: Create a chart of the data and investigate curve.
select * from limit_time_results order by limit_size;



---------------------------------------------------------------------------
-- Sorting
---------------------------------------------------------------------------

--Create a table and query for min and max values.
create table min_max(a number primary key);

--Full table scan or index fast full scan - O(N).
select min(a), max(a) from min_max;

--Two min/max index accesses - O(2*LOG(N)).
select
	(select min(a) from min_max) min,
	(select max(a) from min_max) max
from dual;



---------------------------------------------------------------------------
-- Gathering Statistics
---------------------------------------------------------------------------

--Compare APPROX_COUNT_DISTINCT with a regular COUNT.
select
	approx_count_distinct(launch_date) approx_distinct,
	count(distinct launch_date)        exact_distinct
from launch;



---------------------------------------------------------------------------
-- O(N^2) – Cross Join, Nested Loops, Other
---------------------------------------------------------------------------

--(NOT SHOWN IN BOOK)

--This seems to run in N^2, or something similar.
--Find the time to parse many UNION ALL statements.
--From: https://stackoverflow.com/q/38465651/409172
create table union_time_results(union_size number, seconds number);

--Find time to execute simple statements.
declare
	v_sql clob := 'select 1 a from dual';
	v_count number;
	v_time_before number;
	v_time_after number;
begin
	for i in 1 .. 50000 loop
		v_sql := v_sql || ' union all select 1 a from dual';
		--Only execute every 100th iteration.
		if mod(i, 100) = 0 then
			v_time_before := dbms_utility.get_time;
			execute immediate 'select count(*) from ('||v_sql||')' into v_count;
			v_time_after := dbms_utility.get_time;
			insert into union_time_results values(i, (v_time_after-v_time_before)/100);
			commit;
			--dbms_output.put_line(i||':'||to_char(v_time_after-v_time_before));
		end if;
	end loop;
end;
/

select * from union_time_results order by union_size desc;


--Time to parse nested CTEs.
--This seems to run in N!, or something similar.
--From: https://stackoverflow.com/q/19797675/409172
with t0 as (select 0 as k from dual)
,t1 as (select k from t0 where k >= (select avg(k) from t0))
,t2 as (select k from t1 where k >= (select avg(k) from t1))
,t3 as (select k from t2 where k >= (select avg(k) from t2))
,t4 as (select k from t3 where k >= (select avg(k) from t3))
,t5 as (select k from t4 where k >= (select avg(k) from t4))
,t6 as (select k from t5 where k >= (select avg(k) from t5))
,t7 as (select k from t6 where k >= (select avg(k) from t6))
,t8 as (select k from t7 where k >= (select avg(k) from t7))
,t9 as (select k from t8 where k >= (select avg(k) from t8))
,t10 as (select k from t9 where k >= (select avg(k) from t9))
,t11 as (select k from t10 where k >= (select avg(k) from t10))
,t12 as (select k from t11 where k >= (select avg(k) from t11)) -- 0.5 sec
,t13 as (select k from t12 where k >= (select avg(k) from t12)) -- 1.3 sec
,t14 as (select k from t13 where k >= (select avg(k) from t13)) -- 4.5 sec
,t15 as (select k from t14 where k >= (select avg(k) from t14)) -- 30 sec
,t16 as (select k from t15 where k >= (select avg(k) from t15)) -- 4 min
select k from t16

