---------------------------------------------------------------------------
-- Operators, Expressions, Conditions, and Functions
---------------------------------------------------------------------------

--Bad query with too many dangerous type conversion.
select *
from launch
where to_char(to_date(launch_date), 'YYYY-Mon-DD') = '1957-Oct-04';

--Simple query that uses native type functions.
select *
from launch
where trunc(launch_date) = date '1957-Oct-04';


--Confusing query that depends on precedence rules not everybody knows.
select * from dual where 1=1 or 1=0 and 1=2;

--Simply query that everybody can understand.
select * from dual where 1=1 or (1=0 and 1=2);



---------------------------------------------------------------------------
-- CASE and DECODE
---------------------------------------------------------------------------

set pagesize 9999;
column case_result format a11;
column decode_result format a13;
set colsep "  ";

--fizz buzz
select
	rownum line_number,
	case
		when mod(rownum, 5) = 0 and mod(rownum, 3) = 0 then 'fizz buzz'
		when mod(rownum, 3) = 0 then 'fizz'
		when mod(rownum, 5) = 0 then 'buzz'
		else to_char(rownum)
	end case_result,
	decode(mod(rownum, 15), 0, 'fizz buzz',
		decode(mod(rownum, 3), 0, 'fizz',
		decode(mod(rownum, 5), 0, 'buzz', rownum)
		)
	) decode_result
from dual
connect by level <= 100;


--Fizz buzz as a simple case expression, with similar decode style.
--This is a bad way to program it, but this syntax is useful sometimes.
select
	rownum line_number,
	case rownum
		when 1 then '1'
		when 2 then '2'
		when 3 then 'fizz'
		else 'etc.'
	end case_result,
	decode(rownum, 1, '1', 2, '2', 3, 'fizz', 'etc.') decode_result
from dual
connect by level <= 100;


--Null comparison.
--This function breaks the rule of "null never equals null", it returns "Equal".
select decode(null, null, 'Equal', 'Not Equal') null_decode from dual;



---------------------------------------------------------------------------
-- Set Operators
---------------------------------------------------------------------------

--Example of creating data with set operators and DUAL.
select '1' a from dual union all
select '2' a from dual union all
select '3' a from dual union all
...;


--Compare CASE and DECODE fizz buzz.
--This query returns zero rows.
select
	rownum line_number,
	case
		when mod(rownum, 5) = 0 and mod(rownum, 3) = 0 then 'fizz buzz'
		when mod(rownum, 3) = 0 then 'fizz'
		when mod(rownum, 5) = 0 then 'buzz'
		else to_char(rownum)
	end case_result
from dual connect by level <= 100
minus
select
	rownum line_number,
	decode(mod(rownum, 15), 0, 'fizz buzz',
		decode(mod(rownum, 3), 0, 'fizz',
		decode(mod(rownum, 5), 0, 'buzz', rownum)
		)
	) decode_result
from dual connect by level <= 100;


--Oracle considers the NULLs to be equal and only returns one row.
select null from dual
union
select null from dual;


---------------------------------------------------------------------------
-- Sorting
---------------------------------------------------------------------------

set pagesize 9999;
set colsep "  ";
column orbit_date format a10;
column official_name format a23;

--Sort, using almost all of the options.
select to_char(orbit_date, 'YYYY-MM-DD') orbit_date, official_name
from satellite
order by orbit_date desc nulls last, 2;


---------------------------------------------------------------------------
-- Joins
---------------------------------------------------------------------------

--Partitioned outer join example.
--Count of launches per orbital family, per month of 2017.
select
	launches.lv_family_code,
	months.launch_month,
	nvl(launch_count, 0) launch_count	
from
(
	--Every month in 2017.
	select '2017-'||lpad(level, 2, 0) launch_month
	from dual
	connect by level <= 12
) months
left join
(
	--2017 orbital and deep space launches.
	select
		to_char(launch_date, 'YYYY-MM') launch_month,
		lv_family_code,
		count(*) launch_count
	from launch
	join launch_vehicle
		on launch.lv_id = launch_vehicle.lv_id
	where launch_category in ('orbital', 'deep space')
		and launch_date between
			date '2017-01-01' and timestamp '2017-12-31 23:59:50'
	group by to_char(launch_date, 'YYYY-MM'), lv_family_code
) launches
	partition by (lv_family_code)
	on months.launch_month = launches.launch_month
order by 1,2,3;


--Semi-join.
--Satellites with a launch.
select count(*)
from satellite
where exists
(
	select 1/0
	from launch
	where launch.launch_id = satellite.launch_id
);


--Anti-join
--Satellites without a launch.
select official_name
from satellite
where not exists
(
	select 1/0
	from launch
	where launch.launch_id = satellite.launch_id
);


--Self-join.
--Organizations and parent organizations.
select
	organization.org_name,
	parent_organization.org_name parent_org_name
from space.organization
left join space.organization parent_organization
	on organization.parent_org_code = parent_organization.org_code
order by organization.org_name desc;


--Natural join between LAUNCH and SATELLITE.
select *
from launch
natural join satellite;


--USING syntax:
select *
from launch
join satellite using (launch_id);


--Invalid USING syntax examples, both raise the exception:
--ORA-25154: column part of USING clause cannot have qualifier
select launch.*
from launch
join satellite using (launch_id);

select launch.launch_id
from launch
join satellite using (launch_id);



---------------------------------------------------------------------------
-- Advanced Grouping
---------------------------------------------------------------------------

--Simple grouping example.
--Count of launches per family and name.
select lv_family_code, lv_name, count(*) launch_count
from launch
join launch_vehicle
	on launch.lv_id = launch_vehicle.lv_id
where launch.launch_category in ('orbital', 'deep space')
group by lv_class, lv_family_code, lv_name
order by 1,2,3;


--Rollup example.
--Count of launches per family and name, per family, and grand total.
select
	lv_family_code,
	lv_name,
	count(*) launch_count,
	grouping(lv_family_code) is_family_group,
	grouping(lv_name) is_name_group
from launch
join launch_vehicle
	on launch.lv_id = launch_vehicle.lv_id
where launch_category in ('orbital', 'deep space')
group by rollup(lv_family_code, lv_name)
order by 1,2,3;


--Simple LISTAGG example.
--List of launch vehicles in the Ariane families.
select
	lv_family_code,
	listagg(lv_name, ',') within group (order by lv_name) lv_names
from launch_vehicle
where lower(lv_family_code) like 'ariane%'
group by lv_family_code
order by lv_family_code;


LV_FAMILY_CODE  LV_NAMES
--------------  --------
Ariane          Ariane 1,Ariane 2,Ariane 3,Ariane 40,Ariane 40,...
Ariane5         Ariane 5ECA,Ariane 5ES,Ariane 5ES/ATV,Ariane 5G,...


