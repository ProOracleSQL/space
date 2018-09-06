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

select *
from propellant;

select * from launch;
select * from satellite;

update satellite
;

select * from launch_agency;


select * from organization;

select * from satellite;
select * from launch;




--Two joins:
update satellite
set secondary_name =
(
	select flight_id2
	from launch
	where launch.launch_id = satellite.launch_id
)
where satellite.launch_id in
(
	select launch_id
	from launch
	where launch_category = 'deep space'
);


--Updateable view:
update
(
	select satellite.secondary_name, launch.flight_id2
	from satellite
	join launch
		on satellite.launch_id = launch.launch_id
	where launch_category = 'deep space'
)
set secondary_name = flight_id2;


--Merge:
merge into satellite
using
(
	select launch_id, flight_id2
	from launch
	where launch_category = 'deep space'
) launches
	on (satellite.launch_id = launches.launch_id)
when matched then update set satellite.secondary_name = launches.flight_id2;





update launch_agency
set agency_org_code = (select 



select * from dba_tables where owner = 'SPACE';

select * from platform;

select * from propellent;

insert all
	into propellent(propellent_id, propellent_name) values (-1, 'antimatter')
	into propellent values (-2, 'dilithium crystals')
select * from dual;

rollback;

create sequence test_sequence minvalue -99999 start with -99999;

insert all
	into propellent(propellent_id, propellent_name) values (test_sequence.nextval, 'antimatter')
	into propellent values (test_sequence.nextval, 'dilithium crystals')
select * from dual;

rollback;
select * from propellent order by propellent_id;
