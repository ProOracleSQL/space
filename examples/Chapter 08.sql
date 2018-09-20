---------------------------------------------------------------------------
-- INSERT
---------------------------------------------------------------------------

--Generate new PROPELLANT rows.
insert all
into propellant values (-1, 'antimatter')
into propellant values (-2, 'dilithium crystals')
select * from dual;



---------------------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------------------

--Updating a value to itself still uses a lot of resources.
update launch set launch_date = launch_date;


--UPDATE with multiple table references.
--Update SATELLITE.OFFICIAL_NAME to LAUNCH.FLIGHT_ID2.
update satellite
set satellite.official_name =
(
	select launch.flight_id2
	from launch
	where launch.launch_id = satellite.launch_id
)
where satellite.launch_id in
(
	select launch.launch_id
	from launch
	where launch.launch_category = 'deep space'
);



---------------------------------------------------------------------------
-- DELETE
---------------------------------------------------------------------------

--Example of trying to delete from parent table.
SQL> delete from launch;
delete from launch
*
ERROR at line 1:
ORA-02292: integrity constraint (JHELLER.LAUNCH_AGENCY_LAUNCH_FK) violated -
child record found
;



---------------------------------------------------------------------------
-- MERGE
---------------------------------------------------------------------------

--Example of MERGE to upsert data.
--Merge space elevator into PLATFORM.
merge into platform
using
(
	--New row:
	select
		'ELEVATOR1' platform_code,
		'Shizuoka Space Elevator' platform_name
	from dual
) elevator
on (platform.platform_code = elevator.platform_code)
when not matched then
	insert(platform_code, platform_name)
	values(elevator.platform_code, elevator.platform_name)
when matched then update set
	platform_name = elevator.platform_name;


--Use MERGE as a better version of UPDATE.
--Update SATELLITE.OFFICIAL_NAME to LAUNCH.FLIGHT_ID2.
merge into satellite
using
(
	select launch_id, flight_id2
	from launch
	where launch_category = 'deep space'
) launches
	on (satellite.launch_id = launches.launch_id)
when matched then update set
	satellite.official_name = launches.flight_id2;



---------------------------------------------------------------------------
-- Updatable Views
---------------------------------------------------------------------------

--Updateable view example.
--Update SATELLITE.OFFICIAL_NAME to LAUNCH.FLIGHT_ID2.
update
(
	select satellite.official_name, launch.flight_id2
	from satellite
	join launch
		on satellite.launch_id = launch.launch_id
	where launch_category = 'deep space'
)
set official_name = flight_id2;



---------------------------------------------------------------------------
-- Hints
---------------------------------------------------------------------------

--Example of unique constraint error from loading duplicate data.
SQL> insert into propellant values(-1, 'Ammonia');
insert into propellant values(-1, 'Ammonia')
*
ERROR at line 1:
ORA-00001: unique constraint (JHELLER.PROPELLANT_UQ) violated


--Example of using hint to avoid duplicate rows.
SQL> insert /*+ignore_row_on_dupkey_index(propellant,propellant_uq)*/
  2  into propellant values(-1, 'Ammonia');

0 rows created.


--Allow parallel DML.
alter session enable parallel dml;




---------------------------------------------------------------------------
-- Error Logging
---------------------------------------------------------------------------

--Example of statement that causes an error.
SQL> insert into launch(launch_id, launch_tag)
  2  values (-1, 'A value too large for this column');
values (-1, 'A value too large for this column')
            *
ERROR at line 2:
ORA-12899: value too large for column "JHELLER"."LAUNCH"."LAUNCH_TAG" (actual:
33, maximum: 15)


--Create error logging table.
begin
	dbms_errlog.create_error_log(dml_table_name => 'LAUNCH');
end;
/


SQL> --Insert into LAUNCH and log errors.
SQL> insert into launch(launch_id, launch_tag)
  2  values (-1, 'A value too large for this column')
  3  log errors into err$_launch
  4  reject limit unlimited;

0 rows created.


--Error logging table.
select ora_err_number$, ora_err_mesg$, launch_tag
from err$_launch;



---------------------------------------------------------------------------
-- Returning
---------------------------------------------------------------------------

--Insert a new row and display the new ID for the row.
declare
	v_launch_id number;
begin
	insert into launch(launch_id, launch_category)
	values(-1234, 'deep space')
	returning launch_id into v_launch_id;

	dbms_output.put_line('New Launch ID: '||v_launch_id);
	rollback;
end;
/

--Return multiple values into a collection variable.
--(Not shown in book.)
declare
	v_launch_ids sys.odcinumberlist;
begin
	update launch
	set launch_category = 'deep space exploration'
	where launch_category = 'deep space'
	returning launch_id bulk collect into v_launch_ids;

	dbms_output.put_line('Updated Launch ID #1: '||v_launch_ids(1));
	rollback;
end;
/



---------------------------------------------------------------------------
-- TRUNCATE
---------------------------------------------------------------------------

--Create a table and insert some rows.
create table truncate_test(a varchar2(4000));

insert into truncate_test
select lpad('A', 4000, 'A') from dual
connect by level <= 10000;

--Segment size and object IDs.
select megabytes, object_id, data_object_id
from
(
	select bytes/1024/1024 megabytes
	from user_segments
	where segment_name = 'TRUNCATE_TEST'
) segments
cross join
(
	select object_id, data_object_id
	from user_objects
	where object_name = 'TRUNCATE_TEST'
) objects;


--Truncate the table.
--truncate table truncate_test;

--(Re-run the above segments and objects query)



---------------------------------------------------------------------------
-- COMMIT, ROLLBACK, SAVEPOINT
---------------------------------------------------------------------------


--Insert temporary data to measure transactions.
insert into launch(launch_id, launch_tag) values (-999, 'test');

select used_urec from v$transaction;


--Now get rid of the data.
rollback;

select used_urec from v$transaction;

USED_UREC
---------




---------------------------------------------------------------------------
-- ALTER SYSTEM
---------------------------------------------------------------------------

--Commonly used ALTER SYSTEM commands.
alter system flush shared_pool;
alter system flush buffer_cache;
--This syntax is "SID,SERIAL#,INST_ID".
alter system kill session '123,12345,@1' immediate;


--Let users run a few specifc ALTER SYSTEM commands.
create procedure sys.flush_shared_pool is
begin
	execute immediate 'alter system flush shared_pool';
end;
/

grant execute on sys.flush_shared_pool to DEVELOPER_USERNAME;


--How to run the command from that user.
--(Not in book.)
begin
	sys.flush_shared_pool;
end;
/


--Example of procedure to kill one specific user's sessions.
--(Not shown in book.)
create procedure sys.kill_app_user_sessions is
begin
	for sessions_to_kill in
	(
		select 'alter system kill session '''||sid||','||
			serial#||',@'||inst_id||''' immediate' v_sql
		from gv$session
		where username = 'APPLICATION_USER'
		order by 1
	) loop
		execute immediate sessions_to_kill.v_sql;
	end loop;
end;
/



---------------------------------------------------------------------------
-- ALTER SESSION
---------------------------------------------------------------------------

--Change OPTIMIZER_INDEX_COST_ADJ at the session level.
alter session set optimizer_index_cost_adj = 100;

--Example of ALTER SESSION.
--Use the SPACE schema by default.
alter session set current_schema=space;
--Allow parallel DML.
alter session enable parallel dml;
--Wait for adding space.
alter session enable resumable;
--Enable debugging in newly compiled programs.
alter session set plsql_optimize_level = 1;



---------------------------------------------------------------------------
-- PL/SQL
---------------------------------------------------------------------------

--The most boring anonymous block.
begin
	null;
end;
/


--Anonymous block that does something.
declare
	v_number number := 1;
begin
	dbms_output.put_line('Output: ' || to_char(v_number + 1));
end;
/

Output: 2


--SQL*Plus example:
SQL> set serveroutput on
SQL> exec dbms_output.put_line('test');
test

PL/SQL procedure successfully completed.


--Not-so-randomly generate a number, since the seed is static.
begin
	dbms_random.seed(1234);
	dbms_output.put_line(dbms_random.value);
end;
/

.42789904690591504247349673921052414639


--Gather stats for a table.
begin
	dbms_stats.gather_table_stats('SPACE', 'LAUNCH');
end;
/

--Gather stats for a schema.
begin
	dbms_stats.gather_schema_stats('SPACE');
end;
/


--Create and run a job that does nothing.
begin
	dbms_scheduler.create_job(
		job_name   => 'test_job',
		job_type   => 'plsql_block',
		job_action => 'begin null; end;',
		enabled    => true
	);
end;
/

--Job details.
--(The first two rows may be empty because one-time jobs
-- automatically drop themselves when they finish.)
select * from dba_scheduler_jobs where job_name = 'TEST_JOB';
select * from dba_scheduler_running_jobs where job_name = 'TEST_JOB';
select * from dba_scheduler_job_run_details where job_name = 'TEST_JOB';


     
