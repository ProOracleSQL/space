/*******************************************************************************
This file in an example of an interactive worksheet for performance tuning and troubleshooting.
Some of these commands are discussed in Chapter 18 of Pro Oracle SQL Development.

Copyright (C) 2018 Jon Heller.  This file is licensed under the LGPLv3.
*******************************************************************************/


--------------------------------------------------------------------------------
-- Find currently running SQL on one database.
--------------------------------------------------------------------------------

select elapsed_time/1000000 seconds, executions, users_executing, child_number, parsing_schema_name, gv$sql.* from gv$sql where users_executing > 0 order by elapsed_time desc;
select elapsed_time/1000000 seconds, executions, users_executing, child_number, gv$sql.* from gv$sql order by elapsed_time desc;
select elapsed_time/1000000 seconds, executions, users_executing, child_number, gv$sql.* from gv$sql where sql_id = '9z6r76q75uqap';
select * from dba_hist_sqltext where sql_id = '9z6r76q75uqap';


--Who's running the sql
select * from v$session where sql_id = '9z6r76q75uqap';


--Find recent activity for a specific user.
select username, event, sql_id, temp_space_allocated/1024/1024/1024 gb, gv$active_session_history.*
from gv$active_session_history
join dba_users on gv$active_session_history.user_id = dba_users.user_id
where sample_time between systimestamp - interval '10' hour and systimestamp + interval '5' hour
	--Find queries that used a lot of temporary tablespace.
	--and temp_space_allocated > 1024*1024*1024*1
order by sample_time desc;


--------------------------------------------------------------------------------
-- Find slow SQL on multiple databases.  (Requires Method5.)
--------------------------------------------------------------------------------

--Active SQL statements on multiple databases.
select * from (select 'db1' database_name, elapsed_time/1000000 seconds, users_executing, executions,sql_text, sql_id, inst_id, parsing_schema_name from gv$sql@m5_db1 where users_executing > 0 order by seconds desc) where rownum <= 10 union all
...
select * from (select 'db2' database_name, elapsed_time/1000000 seconds, users_executing, executions,sql_text, sql_id, inst_id, parsing_schema_name from gv$sql@m5_db2 where users_executing > 0 order by seconds desc) where rownum <= 10
order by 1, 2 desc;


--Historical events on multiple databases at once.
select 'db1' database_name, username, count(*) over (partition by to_char(sample_time, 'YYYY-MM-DD HH24:MI')) count_per_minute, event, dba_hist_active_sess_history.* from dba_hist_active_sess_history@m5_db1 join dba_users@m5_db1 on dba_hist_active_sess_history.user_id = dba_users.user_id where sample_time between timestamp '2018-01-29 20:30:00' and timestamp '2018-01-29 20:50:00' union all
...
select 'db2' database_name, username, count(*) over (partition by to_char(sample_time, 'YYYY-MM-DD HH24:MI')) count_per_minute, event, dba_hist_active_sess_history.* from dba_hist_active_sess_history@m5_db2 join dba_users@m5_db2 on dba_hist_active_sess_history.user_id = dba_users.user_id where sample_time between timestamp '2018-01-29 20:30:00' and timestamp '2018-01-29 20:50:00'
order by 1, 9 desc;


--Redo generated per second for each database on a host.
begin
	m5_proc(
		p_table_name          => 'redo_generated_per_host',
		p_table_exists_action => 'drop',
		--p_asynchronous      => false,
		p_targets             => '&targets',
		p_code                =>
		q'<
			select snap_id, begin_time, end_time, round(value/1024/1024, 1) mb
			from dba_hist_sysmetric_history
			where metric_name = 'Redo Generated Per Sec'
			order by begin_time desc
		>'
	);
end;
/



--------------------------------------------------------------------------------
-- Monitor statements
--------------------------------------------------------------------------------

--SQL Monitoring Report.  Text version is usually the fastest and most convenient.
select dbms_sqltune.report_sql_monitor(sql_id => '9z6r76q75uqap', type => 'text') from dual;
--SQL Monitoring Report.  Active version requires saving and loading an .html file.
--It's less convenient than text, but occasionally necessary for some problems.
select dbms_sqltune.report_sql_monitor(sql_id => '9z6r76q75uqap', type => 'active') from dual;
--Historical SQL Monitoring, for when SQL Monitoring Reports aren't working.
--Code is from https://github.com/jonheller1/hist_sql_mon.
select hist_sql_mon.hist_sql_mon(p_sql_id => '9z6r76q75uqap', p_start_time_filter => sysdate - interval '1' day, p_end_time_filter => sysdate) from dual;
--Display a normal execution plan.  Even if we're using SQL Monitoring this is still useful,
--because SQL Monitoring reports don't include the Notes and Predicates sections.
select * from table(dbms_xplan.display_cursor(sql_id => '9z6r76q75uqap'));
--Display execution plan history through AWR.
select * from table(dbms_xplan.display_awr(sql_id =>    '9z6r76q75uqap'));


--What are sessions doing right now.
select status, event, username, gv$session.* from gv$session where username = 'SOME_USER' order by gv$session.status, gv$session.event;
select status, event, username, gv$session.* from gv$session where sql_id in ('9z6r76q75uqap') order by gv$session.status, gv$session.event;


--Latest time the SQL was used, and what it was waiting on.
select sample_time, session_id, sql_plan_line_id, sql_plan_operation, event, dba_hist_active_sess_history.*
from dba_hist_active_sess_history
where sql_id = '9z6r76q75uqap'
order by dba_hist_active_sess_history.sample_time desc;


--Use V$SESSION_LONGOPS to estimate.
--Be careful - operations can repeat, these estimates are frequently worthless.
select * from v$session_longops where sql_id = '9z6r76q75uqap' order by last_update_time desc;


--Is anybody waiting on anybody else?
select
	blocked_sql.sql_id blocked_sql_id
	,blocked_sql.sql_text blocked_sql_text
	,blocked_session.username blocked_username
	,blocking_sql.sql_id blocking_sql_id
	,blocking_sql.sql_text blocking_sql_text
	,blocking_session.username blocking_username
from gv$sql blocked_sql
join gv$session blocked_session
	on blocked_sql.sql_id = blocked_session.sql_id
	and blocked_sql.users_executing > 0
join gv$session blocking_session
	on blocked_session.final_blocking_session = blocking_session.sid
	and blocked_session.final_blocking_instance = blocking_session.inst_id
left join gv$sql blocking_sql
	on blocking_session.sql_id = blocking_sql.sql_id;


--Find root blocker - if there is a chain of blocks.
with blockers(inst_id, sid, blocking_sid, root_sid) as
(
	select inst_id, sid, null blocking_sid, sid root_sid
	from gv$session
	where blocking_session is null
	union all
	select gv$session.inst_id, gv$session.sid, blocking_session blocking_sid, blockers.root_sid
	from gv$session
	join blockers
		on gv$session.blocking_instance = blockers.inst_id
		and gv$session.blocking_session = blockers.sid
	where blocking_session is not null
)
select *
from blockers
where blocking_sid is not null;


--Find blockers.
select sid, blocking_session, gv$session.*
from gv$session
where blocking_session is not null;



--------------------------------------------------------------------------------
-- Kill sessions running a specific SQL statement.
--------------------------------------------------------------------------------
select 'alter system kill session '''||sid||','||serial#||',@'||inst_id||''' immediate;' sql, gv$session.*
from gv$session
where sql_id in ('9z6r76q75uqap');



--------------------------------------------------------------------------------
-- Query time and executions in ASH.
--------------------------------------------------------------------------------

--Most activie queries with sample count and execution count.
select username, top_n_queries.sql_id, sample_count, total_executions
from
(
	--Top N active queries
	select username, sql_id, sample_count
	from
	(
		--Rank active queries.
		select username, sql_id, sample_count, row_number() over (order by sample_count desc) rownumber
		from
		(
			--Query activity between 12 and 1330.
			select username, sql_id, count(*) sample_count
			from gv$active_session_history
			join dba_users
				on gv$active_session_history.user_id = dba_users.user_id
			where sample_time between timestamp '2018-03-09 12:00:00' and timestamp '2018-03-09 13:30:00'
				and username not in ('SOME_USER')
				and sql_id is not null
			group by username, sql_id
			order by count(*) desc
		)
	)
	where rownumber <= 25
) top_n_queries
left join
(
	--Executions per time period.
	select sql_id, sum(executions_delta) total_executions
	from dba_hist_sqlstat
	join dba_hist_snapshot
		on dba_hist_sqlstat.snap_id = dba_hist_snapshot.snap_id
		and dba_hist_sqlstat.instance_number = dba_hist_snapshot.instance_number
	where
		(
			begin_interval_time between timestamp '2018-03-09 12:00:00' and timestamp '2018-03-09 13:30:00'
			or
			end_interval_time between timestamp '2018-03-09 12:00:00' and timestamp '2018-03-09 13:30:00'
		)
	group by sql_id
) query_executions
	on top_n_queries.sql_id = query_executions.sql_id
order by sample_count desc, username, top_n_queries.sql_id;



--------------------------------------------------------------------------------
-- Optimizer Statistics
--------------------------------------------------------------------------------

--Check if automatic job is enabled.
--(There are many ways to that auto-tasks can break.)
select * from dba_autotask_client;
select * from dba_autotask_operation;
select * from dba_autotask_window_clients;
select window_group_name, enabled, number_of_windows, next_start_date, comments from dba_scheduler_window_groups;
select window_name,active from dba_scheduler_windows;
select * from dba_scheduler_windows;


--Check if statistics job actually ran.
select * from dba_optstat_operations order by start_time desc;


/*
--This may be enough to re-enable automatic stats job.
begin
	dbms_auto_task_admin.enable('auto optimizer stats collection', null, null);
end;
/
*/

--Largest tables missing statistics.
select dba_tables.owner, table_name, sum(bytes)/1024/1024/1024 gb
from dba_tables
join dba_segments
	on dba_tables.owner = dba_segments.owner
	and dba_tables.table_name = dba_segments.segment_name
where dba_tables.owner = 'SOME_USER'
	and last_analyzed is null
group by dba_tables.owner, table_name
order by gb desc;


--Example of gathering statistics.
/*
begin
	dbms_stats.gather_schema_stats('MSR_APP', degree => 4, options => 'GATHER EMPTY');
end;
/
*/



--------------------------------------------------------------------------------
-- Monitor temporary tablespace.
--------------------------------------------------------------------------------

--Check if anything is out of resources and waiting for more.
select * from dba_resumable;

--Check temp files, and temp usage.  (Not necessarily the same thing.)
select bytes/1024/1024/1024 GB, gv$tempfile.* from gv$tempfile order by gb desc;
select blocks*8*1024 /1024/1024/1024 gb, gv$tempseg_usage.* from gv$tempseg_usage order by gb desc;



--------------------------------------------------------------------------------
-- Monitor CPU and I/O.
--------------------------------------------------------------------------------

--Is the CPU being used?
select *
from v$sysmetric
where lower(metric_name) like '%cpu%';


--Important server I/O stats.
select value/1024/1024 MB, gv$sysmetric.*
from gv$sysmetric
where metric_name in ('Physical Read Total Bytes Per Sec', 'Physical Write Total Bytes Per Sec')
order by inst_id, begin_time, end_time, metric_name;



--------------------------------------------------------------------------------
-- Check Space/Storage
--------------------------------------------------------------------------------

--Largest objects.
select bytes/1024/1024/1024 gb, dba_segments.* from dba_segments order by bytes desc;

--Total size:
select sum(bytes)/1024/1024/1024 gb from dba_segments;


--Size of tables being created
select bytes/1024/1024/1024 gb, dba_segments.* from dba_segments where segment_type = 'TEMPORARY';



--------------------------------------------------------------------------------
--Generate AWR reports
--------------------------------------------------------------------------------
--Find relevant snapshot.
select * from dba_hist_snapshot order by begin_interval_time desc;


--One-node AWR report:
select * from table(dbms_workload_repository.awr_report_html(l_dbid => 329631350, l_inst_num => 1, l_bid => 8450, l_eid => 8461));


--Global AWR reports:
grant execute on awrrpt_instance_list_type to dba;
select * from table(dbms_workload_repository.awr_global_report_html(l_dbid => 1484088992, l_inst_num => sys.awrrpt_instance_list_type(1,2,3), l_bid => 3317, l_eid => 3320));


--AWR configuration.
select * from dba_hist_wr_control;
select * from v$database;


--Set retention to 180 days.
/*
select 180*24*60 from dual;
begin
	dbms_workload_repository.modify_snapshot_settings(retention => 259200);
end;
/
*/

--Find Top-5 statements in each hour, for a period of time, in AWR.
select /*+ parallel(4) */ sample_hour, 
	listagg(sql_id||'('||sample_count||')', ',') within group (order by sample_count desc) top_sql
from
(
	select sample_hour, sql_id, sample_count
		,row_number() over (partition by sample_hour order by sample_count desc) sample_rank
	from
	(
		select trunc(sample_time, 'HH') sample_hour, sql_id, count(*) sample_count
		from dba_hist_active_sess_history
		where sample_time between timestamp '2018-04-05 00:00:00' and sysdate
			and sql_id is not null
		group by trunc(sample_time, 'HH'), sql_id
	)
)
where sample_rank <= 5
group by sample_hour
order by sample_hour desc;



--------------------------------------------------------------------------------
--Historical system metrics.
--------------------------------------------------------------------------------

--Pivoted system metrics for past few hours.
select *
from (select snap_id, begin_time, end_time, metric_name, value from dba_hist_sysmetric_history) dba_hist_sysmetric_history
pivot
(
	max(trim(to_char(value, '999,999,999.00'))) for metric_name
	in ('Average Active Sessions','Average Synchronous Single-Block Read Latency','Current Open Cursors Count',
		'DB Block Changes Per Txn','Enqueue Requests Per Txn','Executions Per Sec','I/O Megabytes per Second','I/O Requests per Second',
		'Logical Reads Per Txn','Logons Per Sec','Network Traffic Volume Per Sec','Physical Reads Per Sec','Physical Reads Per Txn',
		'Physical Writes Per Sec','Redo Generated Per Sec','Redo Generated Per Txn','Response Time Per Txn','SQL Service Response Time',
		'Total Parse Count Per Txn','User Calls Per Sec','User Transaction Per Sec'
	)
)
where begin_time between systimestamp - interval '2' hour and systimestamp
--where begin_time between timestamp '2014-08-06 20:00:00' and timestamp '2014-08-06 21:00:00'
order by begin_time desc;


--Count of samples per time period, to find when system was historically busy.
with configurable_values as
(
	select
		cast(timestamp '2014-01-17 21:50:00' as date) begin_time,
		cast(timestamp '2014-01-17 22:20:00' as date) end_time,
		5 minutes_per_interval
	from dual
),
periods as
(
	--Time periods with snap_id
	select begin_time, end_time, snap_id
	from
	(
		--Time periods
		select /*+ cardinality(100) [oracle does not accurately estimate connect by]*/
			minutes_per_interval,
			(end_time - begin_time) * 24 * 60 minutes_diff,
			begin_time + (numToDSInterval(minutes_per_interval * (level-1), 'minute')) begin_time,
			begin_time + (numToDSInterval(minutes_per_interval * (level), 'minute')) end_time
		from configurable_values
		connect by level <= ((end_time - begin_time) * 24 * 60) / minutes_per_interval
	) periods
	join dba_hist_snapshot
		on periods.begin_time between dba_hist_snapshot.begin_interval_time and dba_hist_snapshot.end_interval_time
),
snap_ids as
(
	select
		(
			select
				min(snap_id) keep (dense_rank first order by begin_interval_time)
			from dba_hist_snapshot
			where begin_interval_time >= (select begin_time from configurable_values)
		) min_snap_id,
		(
			select
				max(snap_id) keep (dense_rank last order by begin_interval_time)
			from dba_hist_snapshot
			where begin_interval_time <= (select end_time from configurable_values)
		) max_snap_id
	from dual
)
--Sample periods with counts.
select periods.snap_id, periods.begin_time, periods.end_time, sum(sample_counts.sample_count) sample_count
from periods
left join
(
	--Count per minute.
	--Common table expressions in correlated subquery are necessary to use partitioning.
	select trunc(sample_time, 'mi') sample_time, count(*) sample_count
	from dba_hist_active_sess_history
	where snap_id between (select min_snap_id from snap_ids) and (select max_snap_id from snap_ids)
	group by trunc(sample_time, 'mi')
) sample_counts
	on sample_counts.sample_time between periods.begin_time and periods.end_time
group by periods.snap_id, periods.begin_time, periods.end_time
order by periods.begin_time;

--May want to check that AWR has data.
select min(begin_interval_time) from dba_hist_snapshot;


--Most common types of waits.
select sql_id, sql_plan_line_id, sql_plan_operation, event, count(*)
from dba_hist_active_sess_history
where snap_id >= 39804
	and sql_id is not null
group by sql_id, sql_plan_line_id, sql_plan_operation, event
order by count(*) desc;

--Historical downgrades
select *
from
(
	select dba_hist_snapshot.snap_id, begin_interval_time, end_interval_time, stat_name, value
	from dba_hist_sysstat
	join dba_hist_snapshot on dba_hist_sysstat.snap_id = dba_hist_snapshot.snap_id
	where lower(stat_name) like 'parallel operations downgraded%'
		and dba_hist_snapshot.snap_id >= 29750
	--order by snap_id desc
)
pivot
(
	max(value)
	for stat_name in
	(
		'Parallel operations downgraded 1 to 25 pct' as downgraded_1_25,
		'Parallel operations downgraded 25 to 50 pct' as downgraded_25_50,
		'Parallel operations downgraded 75 to 99 pct' as downgraded_75_99,
		'Parallel operations downgraded 50 to 75 pct' as downgraded_50_75,
		'Parallel operations downgraded to serial' as downgraded_serial
	)
)
order by begin_interval_time;



--------------------------------------------------------------------------------
-- Tuning advisor example.
--------------------------------------------------------------------------------

--Tuning advisor
declare
	v_task varchar2(64);
begin
	--v_task := dbms_sqltune.create_tuning_task(sql_text => 'select owner, segment_name, sum(bytes)/1024/1024/1024 GB from dba_segments group by owner, segment_name');
	--42gt4tf9n600v: 
	v_task := dbms_sqltune.create_tuning_task(sql_id => '9z6r76q75uqap');
	dbms_output.put_line('Task name: '||v_task);
end;
/

begin
	dbms_sqltune.execute_tuning_task(task_name => 'TASK_62359');
end;
/

select dbms_sqltune.report_tuning_task('TASK_62359') from dual;

/*
begin
    dbms_sqltune.accept_sql_profile(task_name => 'TASK_68051', task_owner => 'JHELLER_DBA', replace => TRUE);
end;
/
*/



--------------------------------------------------------------------------------
-- Manually create a SQL Profile.
--------------------------------------------------------------------------------

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

begin
	dbms_sqltune.drop_sql_profile('STOP_PARALLELISM');
end;
/


--Large SQL statements are better loaded from SQL_ID.
declare
	v_sql_id constant varchar2(128) := '9z6r76q75uqap';
	v_sql    clob;
begin
	--Find the SQL, it should be in one of these.
	begin
		select sql_fulltext into v_sql from gv$sql where sql_id = v_sql_id and rownum = 1;
	exception when no_data_found then null;
	end;

	if v_sql is null then
		begin
			select sql_text into v_sql from dba_hist_sqltext where sql_id = v_sql_id and rownum = 1;
		exception when no_data_found then
			raise_application_error(-20000, 'Could not find this SQL_ID in GV$SQL or DBA_HIST_SQLTEXT.');
		end;
	end if;

	--Create profile.
	dbms_sqltune.import_sql_profile
	(
		sql_text    => v_sql,
		name        => 'STOP_PARALLELISM',
		description => 'Add useful description here.',
		force_match => true,
		profile     => sqlprof_attr('no_parallel')
	);
end;
/



--------------------------------------------------------------------------------
--IO per user per snapshot.
--------------------------------------------------------------------------------

select to_char(dba_hist_snapshot.begin_interval_time, 'YYYY-MM-DD HH24:MI') begin_time, io_summary.snap_id, name, read_gb, write_gb
from
(
	select snap_id, name, round(sum(delta_read_io_bytes)/1024/1024/1024, 1) read_gb, round(sum(delta_write_io_bytes)/1024/1024/1024, 1) write_gb
	from dba_hist_active_sess_history
	join sys.user$ on dba_hist_active_sess_history.user_id = user$.user#
	group by snap_id, name
	having round(sum(delta_read_io_bytes)/1024/1024/1024, 1) > 0 or round(sum(delta_write_io_bytes)/1024/1024/1024, 1) > 0
) io_summary
join dba_hist_snapshot
	on io_summary.snap_id = dba_hist_snapshot.snap_id
order by dba_hist_snapshot.begin_interval_time desc, name;



--------------------------------------------------------------------------------
-- Monitor transaction rollback progress.
--------------------------------------------------------------------------------

select sysdate, used_urec, v$transaction.* from v$transaction;
