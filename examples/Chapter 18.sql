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
-- Measure database performance
---------------------------------------------------------------------------

--(NOT SHOWN IN BOOK).
--Time models.
select * from v$sys_time_model;
select * from v$sess_time_model;


--Wait events.
select nvl(event, 'CPU') event, gv$active_session_history.*
from gv$active_session_history;


--(NOT SHOWN IN BOOK).
--Other examples of using the EVENT column.
select nvl(event, 'CPU') event, dba_hist_active_sess_history.* from dba_hist_active_sess_history;
select event, gv$session.* from gv$session;


--Statistics.
--Session that generated the most redo.
select round(value/1024/1024) redo_mb, sid, name
from v$sesstat
join v$statname
	on v$sesstat.statistic# = v$statname.statistic#
where v$statname.display_name = 'redo size'
order by value desc;


--Metrics.
--Current I/O usage in megabytes per second.
select begin_time, end_time, round(value) mb_per_second
from gv$sysmetric
where metric_name = 'I/O Megabytes per Second';



---------------------------------------------------------------------------
-- Automatic Workload Repository (AWR) and Active Session History (ASH)
---------------------------------------------------------------------------

--Repeatedly count a large(ish) table using a non-indexed column.
declare
	v_count number;
begin
	for i in 1 .. 100000 loop
		select count(*)
		into v_count
		from satellite
		where orbit_class = 'Polar';
	end loop;
	dbms_workload_repository.create_snapshot;
end;
/


--Find snapshot for generating AWR report.
select *
from dba_hist_snapshot
order by begin_interval_time desc;


--Generate AWR report.
select *
from table(dbms_workload_repository.awr_report_html(
	l_dbid     => 3483962617,
	l_inst_num => 1,
	l_bid      => 6395,
	l_eid      => 6396
));


--Generate ADDM task.
declare
	v_task_name varchar2(100) := 'Test Task';
begin
	dbms_addm.analyze_db
	(
		task_name      => v_task_name,
		begin_snapshot => 6395,
		end_snapshot   => 6396
	);
end;
/


--Create and execute SQL Tuning Advisor task
declare
	v_task varchar2(64);
begin
	v_task := dbms_sqltune.create_tuning_task(
		sql_id => '5115f2tc6809t');
	dbms_sqltune.execute_tuning_task(task_name => v_task);
	dbms_output.put_line('Task name: '||v_task);
end;
/


--View tuning task report.
select dbms_sqltune.report_tuning_task('TASK_18972') from dual;



---------------------------------------------------------------------------
-- SQL Tuning – Finding Slow SQL
---------------------------------------------------------------------------

--All SQL statements that are currenty running.
select
	elapsed_time/1000000 seconds,
	executions,
	users_executing,
	parsing_schema_name,
	sql_fulltext,
	sql_id,
	gv$sql.*
from gv$sql
where users_executing > 0
order by elapsed_time desc;





select *
from dba_hist_sqltext;


select * from v$active_session_history;


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
