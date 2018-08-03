---------------------------------------------------------------------------
-- 1.4.2
---------------------------------------------------------------------------

--Query:
select
	norad_id,
	satellite.launch_id,
	launch_date
from satellite
join launch
	on satellite.launch_id = launch.launch_id
where trunc(launch_date) = date '1957-10-04'
order by norad_id;



select count(*) from v$reserved_words;
select * from v$reserved_words;



---------------------------------------------------------------------------
-- 1.6.1
---------------------------------------------------------------------------

--SQL*Plus formatting:
set sqlprompt "SQL> ";
alter session set current_schema = space;

--Queries:

--Incorrect null comparisons:
select count(*) from launch where apogee = null;
select count(*) from launch where apogee <> null;

--Correct null comparisons:
select count(*) from launch where apogee is null;
select count(*) from launch where apogee is not null;

--Incorrect null "not in" usage:
select count(*)
from launch
where launch_id not in
(
	select launch_id
	from satellite
);



---------------------------------------------------------------------------
-- 1.6.1
---------------------------------------------------------------------------

--Inner join with "inner join" keyword:
select *
from launch
inner join satellite
	on launch.launch_id = satellite.launch_id;

--Inner join with "join" keyword:
select *
from launch
join satellite
	on launch.launch_id = satellite.launch_id;

--Inner join with Cartesian product method:
select *
from launch, satellite
where launch.launch_id = satellite.launch_id;



--Left join with "left outer join" keyword:
select *
from launch
left outer join satellite
	on launch.launch_id = satellite.launch_id;

--Left join with "left join" keyword:
select *
from launch
left join satellite
	on launch.launch_id = satellite.launch_id;

--Left join with "(+)" syntax:
select *
from launch, satellite
where launch.launch_id = satellite.launch_id(+);



--Right joins.  Not shown in the book to save space.
select *
from launch
right outer join satellite
	on launch.launch_id = satellite.launch_id;

select *
from launch
right join satellite
	on launch.launch_id = satellite.launch_id;

select *
from launch, satellite
where launch.launch_id(+) = satellite.launch_id;



--Full outer join with optional "outer" keyword.
select *
from launch
full outer join satellite
	on launch.launch_id = satellite.launch_id;

--Without optional "outer" keyword.
select *
from launch
full join satellite
	on launch.launch_id = satellite.launch_id;

--This does not work, it raise the exception:
--ORA-01468: a predicate may reference only one outer-joined table
select *
from launch, satellite
where launch.launch_id(+) = satellite.launch_id(+);



--Cross joins:
--(These will run for a long time and return 3,040,975,455 rows)

--ANSI join syntax:
select *
from launch
cross join satellite;
--Old-fashioned syntax:
select *
from launch, satellite;


