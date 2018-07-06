--SQL*Plus formatting:
alter session set current_schema = space;
column norad_id format a8;
column launch_id format 9999999;
column launch_date format a11;

--Query:
select
	norad_id,
	satellite.launch_id,
	to_char(launch_date, 'YYYY-MM-DD') launch_date
from satellite
join launch
	on satellite.launch_id = launch.launch_id
where trunc(launch_date) = date '1957-10-04'
order by launch_date;
