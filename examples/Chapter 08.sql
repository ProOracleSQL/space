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



