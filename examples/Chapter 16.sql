---------------------------------------------------------------------------
-- O(1/N) - Batch size performance with sequences
---------------------------------------------------------------------------



--Test sequence size and if it matters.


--#1: Create tables to hold data.
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

--#2: Create initial sequence.
drop sequence cache_test;
create sequence cache_test nocache minvalue 1;

--#3: Run test on increasing cache sizes.
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

--#4: Look at results.
--Create a chart of the data and investigate curve.
select* from sequence_time_results order by cache_size;








