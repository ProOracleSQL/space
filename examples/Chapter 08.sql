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








select * from propellant;

IGNORE_ROW_ON_DUPKEY_INDEX
;

insert into propellant values(-1, 'Ammonia');



