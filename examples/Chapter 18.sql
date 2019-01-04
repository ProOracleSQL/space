---------------------------------------------------------------------------
-- Profiling
---------------------------------------------------------------------------

--Create a test procedure that runs many COUNT operations.
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


--Alternate ways to generate numbers and other values.
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
--Sessions that generated the most redo.
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

--Repeatedly count a large table using a non-indexed column.
--Takes about 5 minutes to run.
declare
	v_count number;
begin
	dbms_workload_repository.create_snapshot;
	for i in 1 .. 100000 loop
		select count(*)
		into v_count
		from satellite
		where orbit_class = 'Polar';
	end loop;
	dbms_workload_repository.create_snapshot;
end;
/


--Find snapshots, for generating AWR reports.
select *
from dba_hist_snapshot
order by begin_interval_time desc;


--Generate AWR report.
select *
from table(dbms_workload_repository.awr_report_html(
	l_dbid     => (select dbid from v$database),
	l_inst_num => 1,
	l_bid      => 6709,
	l_eid      => 6709
));


--Generate ADDM task.
declare
	v_task_name varchar2(100) := 'Test Task';
begin
	dbms_addm.analyze_db
	(
		task_name      => v_task_name,
		begin_snapshot => 6709,
		end_snapshot   => 6710
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
-- Find currently-running slow SQL
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



---------------------------------------------------------------------------
-- SQL Tuning – Finding Execution Plans
---------------------------------------------------------------------------

--All satellites and their launch.
explain plan for
select *
from satellite
left join launch
	on satellite.launch_id = launch.launch_id;

select * from table(dbms_xplan.display);


--View all inactive rows of an adaptive plan.
select * from table(dbms_xplan.display(format => '+adaptive'));



---------------------------------------------------------------------------
-- DBMS_XPLAN functions
---------------------------------------------------------------------------

--FORMAT options.
select * from table(dbms_xplan.display(format => 'basic +rows'));
select * from table(dbms_xplan.display(format => 'typical -rows'));


--Display the Outline Data.
select * from table(dbms_xplan.display(format => '+outline'));


--(NOT SHOWN IN BOOK)
--Find all possible Note values.
select sql_id, other_xml
from gv$sql_plan
where
	replace(replace(replace(
		other_xml
		, '<info type="adaptive_plan" note="y">yes</info>', '') --adaptive plans
		, '<info type="dynamic_sampling" note="y">', '') --dynamic sampling (always a number)
		, '<info type="cardinality_feedback" note="y">yes</info>', '') --cardinality feedback
	like '%note="y"%'
and rownum <= 5;



---------------------------------------------------------------------------
-- Find actual values - GATHER_PLAN_STATISTICS
---------------------------------------------------------------------------

--Create LAUNCH2 table but gather stats at wrong time.
create table launch2 as select * from launch where 1=2;

begin
	dbms_stats.gather_table_stats(user, 'launch2');
end;
/

insert into launch2 select * from launch;

commit;


--Distinct dates a satellite was launched.
select /*+ gather_plan_statistics */ count(distinct launch_date)
from launch2 join satellite using (launch_id);


--Find the SQL_ID.
select * from gv$sql where sql_fulltext like '%select%launch2%';

--First execution has NESTED LOOPS SEMI and bad cardinalities.
select * from table(dbms_xplan.display_cursor(
	sql_id => '2wusnw2fbpdrq',
	format => 'iostats last'));


--Re-gather stats, flush shared pool, re-run query.
begin
	dbms_stats.gather_table_stats(user, 'launch2',
		no_invalidate => false);
end;
/

--Distinct dates a satellite was launched.
select /*+ gather_plan_statistics */ count(distinct launch_date)
from launch2 join satellite using (launch_id);

--Second execution has HASH JOIN, better cardinalities, faster.
select * from table(dbms_xplan.display_cursor(
	sql_id => '2wusnw2fbpdrq',
	format => 'iostats last'));



---------------------------------------------------------------------------
-- Find actual values - Real-Time SQL Monitor Report
---------------------------------------------------------------------------

--Ridiculously bad cross join.  (Run in separate session.)
select /*+ parallel(64) */ count(*) from launch,launch;

--Find the SQL_ID, while the previous statement is running.
select *
from gv$sql where sql_fulltext like '%launch,launch%'
	and users_executing > 0;

--Generate report.
select dbms_sqltune.report_sql_monitor('242q2tafkqamm') from dual;


--Generate Active report.
select dbms_sqltune.report_sql_monitor('242q2tafkqamm',
	type => 'active')
from dual;



---------------------------------------------------------------------------
-- SQL Profile example
---------------------------------------------------------------------------

--Query that shouldn't run in parallel.
explain plan for select /*+parallel*/ * from satellite;

select * from table(dbms_xplan.display(format => 'basic +note'));


--Create SQL Profile to stop parallelism in one query.
begin
	dbms_sqltune.import_sql_profile
	(
		sql_text    => 'select /*+parallel*/ * from satellite',
		name        => 'STOP_PARALLELISM',
		force_match => true,
		profile     => sqlprof_attr('no_parallel')
	);
end;
/



---------------------------------------------------------------------------
-- Automatic statistics
---------------------------------------------------------------------------

--Gather optimizer statistics in parallel, for this one table.
begin
	dbms_stats.set_table_prefs(user, 'TEST1', 'DEGREE', 8);
end;
/


--Dynamic sampling to estimate object types.
explain plan for
select /*+dynamic_sampling(2) */ column_value
from table(sys.odcinumberlist(1,2,3));

select * from table(dbms_xplan.display(format => 'basic +rows +note'));


--Extended statistics on ENGINE_PROPELLANT.
select dbms_stats.create_extended_stats(
	ownname => 'SPACE',
	tabname => 'ENGINE_PROPELLANT',
	extension => '(PROPELLANT_ID,OXIDIZER_OR_FUEL)')
from dual;


--Demonstrate extended statistics.
--(NOT SHOWN IN BOOK.)
--Original estimate with one predicate: 41 rows.  Actual cadinality: 41.
explain plan for select * from engine_propellant where propellant_id = 1;
select * from table(dbms_xplan.display);

--Original estimate with two predicates: 30 rows.  Actual cardinality: 41.
explain plan for select * from space.engine_propellant where propellant_id = 1 and oxidizer_or_fuel = 'fuel';
select * from table(dbms_xplan.display);

--Gather stats.
begin
	dbms_stats.gather_table_stats('SPACE', 'ENGINE_PROPELLANT', no_invalidate => false);
end;
/

--Now the estimate is correct at 41.
--(This require multiple runs before it works correctly.)
explain plan for select * from engine_propellant where propellant_id = 1 and oxidizer_or_fuel = 'fuel';
select * from table(dbms_xplan.display);

--View the extended statistics.
select * from dba_tab_col_statistics where table_name = 'ENGINE_PROPELLANT';

--Drop extended statistics.
begin
	dbms_stats.drop_extended_stats('SPACE', 'ENGINE_PROPELLANT', '(propellant_id,oxidizer_or_fuel)');
end;
/
