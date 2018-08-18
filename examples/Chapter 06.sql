---------------------------------------------------------------------------
-- Hard to debug
---------------------------------------------------------------------------

--Simple example of old fashioned join that is hard to debug.
--Note that "stage_no" should be "stage_name" to work.
select launch.launch_tag, stage.stage_name, stage.engine_count
from launch, launch_vehicle_stage, stage
where launch.lv_id = launch_vehicle_stage.lv_id
	and launch_vehicle_stage.stage_no /*!*/ = stage.stage_name
order by 1,2,3;


--ANSI syntax equivalant.
--With such a small size it's still not obvious how this would be
--easier to read and debug.
select launch.launch_tag, stage.stage_name, stage.engine_count
from launch
join launch_vehicle_stage
	on launch.lv_id = launch_vehicle_stage.lv_id
join stage
	on launch_vehicle_stage.stage_no /*stage_name!*/ = stage.stage_name
order by 1,2,3;



---------------------------------------------------------------------------
-- Problem: Too Much Context
---------------------------------------------------------------------------


--Re-writing the above query using a correlated subquery.
select launch.launch_tag, launch_vehicle_stage.stage_name,
	(
		select stage.engine_count
		from stage
		where stage.stage_name = launch_vehicle_stage.stage_name
	) engine_count
from launch
join launch_vehicle_stage
	on launch.lv_id = launch_vehicle_stage.lv_id
order by 1,2;


--Common table expression.
--Let's find some recent planetary exploration and deep space missions.
with launches as
(
	select *
	from launch
	where launch_category in ('deep space')
		and launch_date >= date '2000-01-01'
)
select *
from launches
join satellite
	on launches.launch_id = satellite.launch_id;



---------------------------------------------------------------------------
-- Inline Views
---------------------------------------------------------------------------

--Both of these are subqueries.
--
--Correlated subquery:
select (select * from dual a where a.dummy = b.dummy) from dual b
--Inline view:
select * from (select * from dual);


--#1: Join everything at once: 
select ...
from table1,table2,table3,table4,table5,table6,table7,table8
where ...;

--#2: Use inline views:
select *
from
(
	select ...
	from table1,table2,table3,table4
	where ...
)
join
(
	select ...
	from table5,table6,table7,table8
	where ...
)
where ...;



---------------------------------------------------------------------------
-- Example
---------------------------------------------------------------------------

set pagesize 1000;
column launch_year format a11;
column fuel format a13;
column launch_count format 999,999;

--Top 3 fuels used per year using ANSI join syntax.
--
--#6: Select only the top N.
select launch_year, fuel, launch_count
from
(
	--#5: Rank the fuel counts.
	select launch_year, launch_count, fuel,
		row_number() over
			(partition by launch_year order by launch_count desc) rownumber
	from
	(
		--#4: Count of fuel used per year.
		select
			to_char(launch_date, 'YYYY') launch_year,
			count(*) launch_count,
			fuel
		from
		(
			--#1: Orbital and deep space launches.
			select *
			from launch
			where launch_category in ('orbital', 'deep space')
		) launches
		left join
		(
			--#2: Launch Vehicle Engine
			select launch_vehicle_stage.lv_id, stage.engine_id
			from launch_vehicle_stage
			left join stage
				on launch_vehicle_stage.stage_name = stage.stage_name
		) lv_engine
			on launches.lv_id = lv_engine.lv_id
		left join
		(
			--#3: Engine Fuel
			select engine.engine_id, propellent_name fuel
			from engine
			left join engine_propellent
				on engine.engine_id = engine_propellent.engine_id
			left join propellent
				on engine_propellent.propellent_id = propellent.propellent_id
			where oxidizer_or_fuel = 'fuel'
		) engine_fuel
			on lv_engine.engine_id = engine_fuel.engine_id
		group by to_char(launch_date, 'YYYY'), fuel
		order by launch_year, launch_count desc, fuel
	)
)
where rownumber <= 3
order by launch_year, launch_count desc;


--Top 3 fuels used per year using old-fashioned join syntax.
--While this query is smaller, it's usually harder to read
--since it tries to do everything at once.
--
--Top 3 fuels used per year.
select launch_year, fuel, launch_count
from
(
	--Rank the fuel counts.
	select launch_year, launch_count, fuel,
		row_number() over (partition by launch_year order by launch_count desc) rownumber
	from
	(
		--Count of fuel used per year.
		select
			to_char(launch_date, 'YYYY') launch_year,
			count(*) launch_count,
			propellent_name fuel
		from launch, launch_vehicle_stage, stage, engine, engine_propellent, propellent
		where launch.lv_id = launch_vehicle_stage.lv_id(+)
			and launch_vehicle_stage.stage_name = stage.stage_name(+)
			and stage.engine_id = engine.engine_id(+)
			and engine.engine_id = engine_propellent.engine_id(+)
			and engine_propellent.propellent_id = propellent.propellent_id(+)
			and launch_category in ('orbital', 'deep space')
			and oxidizer_or_fuel = 'fuel'
		group by to_char(launch_date, 'YYYY'), propellent_name
		order by launch_year, launch_count desc, fuel
	)
)
where rownumber <= 3
order by launch_year, launch_count desc;
