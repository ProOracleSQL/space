---------------------------------------------------------------------------
-- Profiling
---------------------------------------------------------------------------

--Create test procedure.
create or replace procedure test_procedure is
	v_count number;    
begin
	for i in 1 .. 10000 loop
		select count(*) into v_count from launch order by 1;
	end loop;

	for i in 1 .. 10000 loop
		select count(*) into v_count from engine order by 1;
	end loop;
end;
/

--Run the procedure for profiling.  (Takes about 15 seconds.)
begin
	test_procedure;
end;
/


--(NOT SHOWN IN BOOK).
--Profiling the manual way on SQL Developer and other IDEs.
--Run the procedures.  Takes 17 seconds on my machine.
declare
	v_result binary_integer;
begin
	v_result := dbms_profiler.start_profiler('test run');
	test_procedure;
	v_result := dbms_profiler.stop_profiler;
end;
/

select * from plsql_profiler_data;
select * from plsql_profiler_runs;
select * from plsql_profiler_units;



---------------------------------------------------------------------------
-- Installation and patch scripts
---------------------------------------------------------------------------

--Typical slow and wordy install script.
create table install_test1(a number);

alter table install_test1 modify a not null;

alter table install_test1
	add constraint install_test1_pk primary key(a);

insert into install_test1(a) values(1);
commit;
insert into install_test1(a) values(2);
commit;
insert into install_test1(a) values(3);
commit;


--Faster and more compact install script.
create table install_test2
(
	a not null,
	constraint install_test2_pk primary key(a)
) as
select 1 a from dual union all
select 2 a from dual union all
select 3 a from dual;


--Alternative ways to generate numbers and other values.
select level a from dual connect by level <= 3;
select column_value a from table(sys.odcinumberlist(1,2,3));
select column_value a from table(sys.odcivarchar2list('A','B','C'));



---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------



select *
from dba_hist_snapshot
order by begin_interval_time desc;

--One-node AWR report:
select *
from table(dbms_workload_repository.awr_report_html(
	l_dbid     => 3483962617,
	l_inst_num => 1,
	l_bid      => 6352,
	l_eid      => 6353
));


select * from V$SYS_TIME_MODEL;








---------------------------------------------------------------------------
-- SQL Tuning – Finding Slow SQL
---------------------------------------------------------------------------


--All queries that are currently running.
select elapsed_time/1000000 seconds, executions, users_executing, parsing_schema_name, gv$sql.*
from gv$sql
where users_executing > 0
order by elapsed_time desc;


select *
from dba_hist_sqltext;



--Estimate: 1%, 705
select *
from space.launch
where to_char(launch_date, 'YYYY') = '1970';

select count(*) from space.launch;

select dbms_stats.create_extended_stats('SPACE', 'LAUNCH', '(to_char(launch_date, ''YYYY''))')
from dual;

begin
	dbms_stats.gather_table_stats('SPACE', 'LAUNCH');
end;
/
