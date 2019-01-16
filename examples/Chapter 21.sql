---------------------------------------------------------------------------
-- Create a PL/SQL Playground
---------------------------------------------------------------------------

--PL/SQL block with nested procedure and functions.
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
	is_this_annoying varchar2(3) not null,
	constraint boolean_test_ck
		check(is_this_annoying in ('Yes', 'No'))
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


--This function fails yet does not raise an exception.
create or replace function test_function return number is
	v_dummy varchar2(1);
begin
	select dummy into v_dummy from dual where 1=0;
	return 999;
end;
/

select test_function from dual;


--This function catches and re-raises NO_DATA_FOUND exceptions.
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
-- Record and collection variables
---------------------------------------------------------------------------

--Build user-defined type, which acts similar to PL/SQL record.
create or replace type propellant_type is object
(
	propellant_id   number,
	propellant_name varchar2(4000)
);

--Record with %ROWTYPE and IS RECORD, and a user-defined type.
declare
	--Create variables and types.
	v_propellant1 propellant%rowtype;

	type propellant_rec is record
	(
		propellant_id   number,
		propellant_name varchar2(4000)
	);
	v_propellant2 propellant_rec;

	v_propellant3 propellant_type := propellant_type(null, null);
begin
	--Populate data.
	v_propellant1.propellant_id := 1;
	v_propellant1.propellant_name := 'test1';

	v_propellant2.propellant_id := 2;
	v_propellant2.propellant_name := 'test2';

	v_propellant3.propellant_id := 3;
	v_propellant3.propellant_name := 'test3';
end;
/





--Demonstrate %ROWTYPE.
declare
	type launch_nt is table of launch%rowtype;
	v_launches launch_nt;
begin
	execute immediate 'select * from launch'
	bulk collect into v_launches;

	select *
	bulk collect into v_launches
	from launch;

	for i in 1 .. v_launches.count loop
		null;
	end loop;
end;
/



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
select test_function from dual;



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
	$else
		dbms_output.put_line('Hello, time traveler');
	$end
end;
/



