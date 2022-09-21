---------------------------------------------------------------------------
-- Create a PL/SQL Playground
---------------------------------------------------------------------------

--PL/SQL block with nested procedure and function.
declare
	v_declare_variables_first number;

	function some_function return number is
		procedure some_procedure is
		begin
			null;
		end some_procedure;
	begin
		some_procedure;
		return 1;
	end some_function;
begin
	v_declare_variables_first := some_function;
	dbms_output.put_line('Output: '||v_declare_variables_first);
end;
/


---------------------------------------------------------------------------
-- Session data
---------------------------------------------------------------------------

--Create a package with global public and private variables.
create or replace package test_package is
	g_public_global number;
	procedure set_private(a number);
	function get_private return number;
end;
/

--Create a package body that sets and gets private variables.
create or replace package body test_package is
	g_private_global number;

	procedure set_private(a number) is
	begin
		g_private_global := a;
	end;

	function get_private return number is
	begin
		return g_private_global;
	end;
end;
/

--Public variables can be get or set directly in PL/SQL.
begin
	test_package.g_public_global := 1;
end;
/

--Private variables cannot be set directly. This code raises:
--"PLS-00302: component 'G_PRIVATE_GLOBAL' must be declared"
begin
	test_package.g_private_global := 1;
end;
/

--Public variables still cannot be read directly in SQL.
--This code raises "ORA-06553: PLS-221: 'G_PUBLIC_GLOBAL' is
-- not a procedure or is undefined"
select test_package.g_public_global from dual;

--Setters and getters with private variables are preferred.
begin
	test_package.set_private(1);
end;
/

--This function can be used in SQL.
select test_package.get_private from dual;


--(NOT SHOWN IN BOOK.)
--Run in another session.
alter package test_package compile;

--Now our session fails with:
--ORA-04068: existing state of packages has been discarded
--ORA-04061: existing state of package "JHELLER.TEST_PACKAGE" has been invalidated
--ORA-04065: not executed, altered or dropped package "JHELLER.TEST_PACKAGE"
select test_package.get_private from dual;



---------------------------------------------------------------------------
-- Transaction control I – COMMIT and ROLLBACK
---------------------------------------------------------------------------

--Create a simple table for transaction tests.
create table transaction_test(a number);


--Insert one row:
insert into transaction_test values(1);

--Fails with: ORA-01722: invalid number
update transaction_test set a = 'B';

--The table still contains the original inserted value:
select * from transaction_test;


--Reset the scratch table.
truncate table transaction_test;

--Combine good INSERT and bad UPDATE in a PL/SQL block.
--Raises: "ORA-01722: invalid number"
begin
	insert into transaction_test values(1);
	update transaction_test set a = 'B';
end;
/

--The table is empty:
select * from transaction_test;


--Unnecessary exception handling.
begin
	insert into transaction_test values(1);
	update transaction_test set a = 'B';
exception when others then
	rollback;
	raise;
end;
/


--Correct: SQL%ROWCOUNT is before ROLLBACK.
begin
	insert into transaction_test values(1);
	dbms_output.put_line('Rows inserted: '||sql%rowcount);
	rollback;
end;
/

--Incorrect: SQL%ROWCOUNT is after ROLLBACK.
begin
	insert into transaction_test values(1);
	rollback;
	dbms_output.put_line('Rows inserted: '||sql%rowcount);
end;
/



---------------------------------------------------------------------------
-- Transaction control II – row-level locking
---------------------------------------------------------------------------

--Session #1: These commands all run normally.
insert into transaction_test values(0);
commit;
savepoint savepoint1;
update transaction_test set a = 1;

--Session #2: This command hangs, waiting for the locked row.
update transaction_test set a = 2;

--Session #1: Rollback to the previous savepoint.
--Notice that session #2 is still waiting.
rollback to savepoint1;

--Session #3: This command steals the lock and completes.
--Notice that session #2 is still waiting, on a row that is
-- no longer locked.
update transaction_test set a = 3;
commit;


---------------------------------------------------------------------------
-- Transaction control II – isolation and consistency
---------------------------------------------------------------------------

--These subqueries will always return the same number.
select
	(select count(*) from transaction_test) count1,
	(select count(*) from transaction_test) count2
from dual;


--These queries may return different numbers.
declare
	v_count1 number;
	v_count2 number;
begin
	select count(*) into v_count1 from transaction_test;
	dbms_output.put_line(v_count1);
	dbms_lock.sleep(5);
	select count(*) into v_count2 from transaction_test;
	dbms_output.put_line(v_count2);
end;
/


--These queries will always return the same number.
declare
	v_count1 number;
	v_count2 number;
begin
	set transaction isolation level serializable;
	select count(*) into v_count1 from transaction_test;
	dbms_output.put_line(v_count1);
	dbms_lock.sleep(5);
	select count(*) into v_count2 from transaction_test;
	dbms_output.put_line(v_count2);
end;
/


--(NOT SHOWN IN BOOK.)
--Use this in a separate transaction to test the above PL/SQL blocks.
insert into transaction_test values(2);
commit;

--Lock rows preemptively.
select * from transaction_test for update;



---------------------------------------------------------------------------
-- Simple types
---------------------------------------------------------------------------

alter session set current_schema=space;


--Demonstrate %TYPE.
declare
	v_launch_category launch.launch_category%type;
begin
	select launch_category
	into v_launch_category
	from launch
	where rownum = 1;
end;
/


--A table designed for Boolean data.
create table boolean_test
(
	is_true varchar2(3) not null,
	constraint boolean_test_ck
		check(is_true in ('Yes', 'No'))
);


--Convert PL/SQL Boolean to SQL Boolean.
declare
	v_boolean boolean := true;
	v_string varchar2(3);
begin
	v_string := case when v_boolean then 'Yes' else 'No' end;
	insert into boolean_test values(v_string);
	rollback;
end;
/



---------------------------------------------------------------------------
-- Cursors
---------------------------------------------------------------------------

--Simple example of a ref cursor.
-- (SECOND EDITION ONLY.)
create or replace function ref_cursor_test
return sys_refcursor is
	v_cursor sys_refcursor;
begin
	--Static ref cursor based on a query.
	open v_cursor for select * from launch;
	--Dynamic ref cursor based on a string.
	--(A more realistic example would include bind variables.)
	open v_cursor for 'select * from launch';
	return v_cursor;
end;
/


--Static and dynamic SELECT INTO for one row.
declare
	v_count number;
begin
	select count(*) into v_count from launch;
	execute immediate 'select count(*) from launch' into v_count;
end;
/


--(NOT SHOWN IN BOOK.)
--SELECT INTO that raises "ORA-01403: no data found" or
--"ORA-01422: exact fetch returns more than requested number of rows".
declare
	v_count number;
begin
	--select 1 into v_count from launch where 1 = 0;
	select 1 into v_count from launch;
end;
/


--This function fails yet does not raise an exception in SQL.
create or replace function test_function return number is
	v_dummy varchar2(1);
begin
	select dummy into v_dummy from dual where 1=0;
	return 999;
end;
/

select test_function from dual;


--This function re-raises NO_DATA_FOUND exceptions.
create or replace function test_function2 return number is
	v_dummy varchar2(1);
begin
	select dummy into v_dummy from dual where 1=0;
	return 999;
exception when no_data_found then
	raise_application_error(-20000, 'No data found detected.');
end;
/

--Raises: "ORA-20000: No data found detected.".
select test_function2 from dual;


--Simple cursor FOR loop example.
begin
	for launches in
	(
		--Put huge query here:
		select * from launch where rownum <= 5
	) loop
		--Do something with result set here:
		dbms_output.put_line(launches.launch_tag);
	end loop;
end;
/



---------------------------------------------------------------------------
-- Records
---------------------------------------------------------------------------

--Build user-defined type, which is similar to PL/SQL record.
create or replace type propellant_type is object
(
	propellant_id   number,
	propellant_name varchar2(4000)
);

--Example of %ROWTYPE, IS RECORD, and user-defined type.
declare
	--Create variables and types.
	v_propellant1 propellant%rowtype;

	type propellant_rec is record
	(
		propellant_id   number,
		propellant_name varchar2(4000)
	);
	v_propellant2 propellant_rec;

	v_propellant3 propellant_type := propellant_type(null,null);
begin
	--Populating data can work the same for all three options:
	v_propellant1.propellant_id := 1;
	v_propellant1.propellant_name := 'test1';

	v_propellant2.propellant_id := 2;
	v_propellant2.propellant_name := 'test2';

	v_propellant3.propellant_id := 3;
	v_propellant3.propellant_name := 'test3';

	--Since 18c, records can use qualified expressions:
	v_propellant2 := propellant_rec(2, 'test2');

	--User-defined types can also use constructors:
	v_propellant3 := propellant_type(3, 'test3');
end;
/



---------------------------------------------------------------------------
-- Collections
---------------------------------------------------------------------------

--Define, populate, and iterate nested tables using %ROWTYPE.
declare
	type launch_nt is table of launch%rowtype;
	v_launches launch_nt;
begin
	--Static example:
	select *
	bulk collect into v_launches
	from launch;

	--Dynamic example:
	execute immediate 'select * from launch'
	bulk collect into v_launches;

	--Iterating the nested table:
	for i in 1 .. v_launches.count loop
		dbms_output.put_line(v_launches(i).launch_id);
		--Only print one value.
		exit;
	end loop;
end;
/


--Define, populate, and iterate an associative array.
declare
	type string_aat is table of number index by varchar2(4000);
	v_category_counts string_aat;
	v_category varchar2(4000);
begin
	--Load categories.
	for categories in
	(
		select launch_category, count(*) the_count
		from launch
		group by launch_category
	) loop
		v_category_counts(categories.launch_category) :=
			categories.the_count;
	end loop;

	--Loop through and print categories and values.
	v_category := v_category_counts.first;
	while v_category is not null loop
		dbms_output.put_line(v_category||': '||
			v_category_counts(v_category));
		v_category := v_category_counts.next(v_category);
	end loop;
end;
/



---------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------

--Calculate orbital period in minutes, based on apogee
--and perigee in kilometers.  (Only works for Earth orbits.)
create or replace function get_orbit_period
(
	p_apogee number,
	p_perigee number
) return number is
	c_earth_radius constant number := 6378;
	v_radius_apogee number := p_apogee + c_earth_radius;
	v_radius_perigee number := p_perigee + c_earth_radius;
	v_semi_major_axis number :=
		(v_radius_apogee+v_radius_perigee)/2;
	v_standard_grav_param constant number := 398600.4;
	v_orbital_period number := 2*3.14159*sqrt(
		power(v_semi_major_axis,3)/v_standard_grav_param)/60;
	--pragma udf;
begin
	return v_orbital_period;
end;
/

--Orbital periods for satellites.
select
	norad_id,
	orbit_period,
	round(get_orbit_period(apogee,perigee),2) my_orbit_period
from satellite
where orbit_period is not null
order by norad_id;



---------------------------------------------------------------------------
-- Table functions
---------------------------------------------------------------------------

--Common uses of TABLE functions.
select * from table(dbms_xplan.display);


--Simple nested table and table function that uses it.
create or replace type number_nt is table of number;

create or replace function get_distinct(p_numbers number_nt)
return number_nt is
begin
	return set(p_numbers);
end;
/


--Distinct launch apogees from a custom PL/SQL function.
select *
from table(get_distinct
((
	select cast(collect(apogee) as number_nt)
	from launch
)))
order by 1;


--Simpler, faster SQL version.
select distinct apogee from launch;



---------------------------------------------------------------------------
-- Pipelined functions
---------------------------------------------------------------------------

--Simple pipelined function.
create or replace function simple_pipe
return sys.odcinumberlist pipelined is
begin
	for i in 1 .. 3 loop
		pipe row(i);
	end loop;
end;
/

select * from table(simple_pipe);



---------------------------------------------------------------------------
-- Parallel pipelined functions
---------------------------------------------------------------------------

--Parallel pipelined function.
create or replace function parallel_pipe(p_cursor sys_refcursor)
return sys.odcinumberlist pipelined
parallel_enable(partition p_cursor by any) is
	v_launch launch%rowtype;
begin
	loop
		fetch p_cursor into v_launch;
		exit when p_cursor%notfound;
		pipe row(v_launch.launch_id);
	end loop;
end;
/


--Call parallel pipelined function.
select *
from table(parallel_pipe(cursor(
	select /*+ parallel(2) */ * from launch
)));



---------------------------------------------------------------------------
-- Autonomous transactions
---------------------------------------------------------------------------

--Function that changes the database.
create or replace function test_function
return number authid current_user is
	pragma autonomous_transaction;
begin
	execute immediate 'create table new_table(a number)';
	return 1;
end;
/

--Call the function to create the table.
select /*+ no_result_cache */ test_function from dual;


--Autonomous transaction for logging
--Create simple table to hold application messages.
create table application_log
(
	message  varchar2(4000),
	the_date date
);

--Autonomous logging procedure.
create or replace procedure log_it
(
	p_message varchar2,
	p_the_date date
) is
	pragma autonomous_transaction;
begin
	insert into application_log
	values(p_message, p_the_date);

	commit;
end;
/

--Reset the scratch table.
truncate table transaction_test;

--Autonomous transaction works despite rollback.
begin
	insert into transaction_test values(1);
	log_it('Inserting...', sysdate);
	rollback;
end;
/

--The main transaction was rolled back.
select count(*) from transaction_test;

--But the logging table has the original log message.
select count(*) from application_log;



---------------------------------------------------------------------------
-- Triggers
---------------------------------------------------------------------------


--Clear the table.  (NOT SHOWN IN BOOK.)
delete from transaction_test;

--Create a trigger to track every row change.
create or replace trigger transaction_test_trg
after insert or update of a or delete on transaction_test
for each row
begin
	case
		when inserting then
			dbms_output.put_line('inserting '||:new.a);
		when updating('a') then
			dbms_output.put_line('updating from '||
				:old.a||' to '||:new.a);
		when deleting then
			dbms_output.put_line('deleting '||:old.a);
	end case;
end;
/

--Test the trigger.
begin
	insert into transaction_test values(1);
	update transaction_test set a = 2;
	delete from transaction_test;
end;
/


--Create logon trigger that sets a custom NLS_DATE_FORMAT.
create or replace trigger jheller.custom_nls_date_format_trg
after logon on jheller.schema
begin
	execute immediate
		q'[alter session set nls_date_format = 'J']';
end;
/

--Logout and logon again and run this to see the new format.
select to_char(sysdate) julian_day from dual;

JULIAN_DAY
----------
   2458530




--Imitation on-commit trigger.
declare
	v_job number;
begin
	--Create a job, but it won't take effect yet.
	dbms_job.submit
	(
		job  => v_job,
		what => 'insert into transaction_test values(1);'
	);

	--A rollback would ignore the job.
	--rollback;

	--Only a commit will truly create the job.
	commit;
end;
/



---------------------------------------------------------------------------
-- Conditional compilation
---------------------------------------------------------------------------

--Conditional compilation example.
begin
	$if dbms_db_version.ver_le_9 $then
		This line is invalid but the block still works.
	$elsif dbms_db_version.ver_le_11 $then
		dbms_output.put_line('Version 11 or lower');
	$elsif dbms_db_version.ver_le_12 $then
		dbms_output.put_line('Version 12');
	$elsif dbms_db_version.ver_le_18 $then
		dbms_output.put_line('Version 18');
	$elsif dbms_db_version.ver_le_19 $then
		dbms_output.put_line('Version 19');
	$elsif dbms_db_version.ver_le_21 $then
		dbms_output.put_line('Version 21');
	$else
		dbms_output.put_line('Future version');
	$end
end;
/
