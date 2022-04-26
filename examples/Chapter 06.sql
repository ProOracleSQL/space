---------------------------------------------------------------------------
-- Common SQL Problem: Spaghetti Code from Non-Standard Syntax
---------------------------------------------------------------------------

--Old join syntax we should avoid.
select *
from launch, satellite
where launch.launch_id = satellite.launch_id(+);

--ANSI join syntax we should embrace.
select *
from launch
left join satellite
	on launch.launch_id = satellite.launch_id;



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
--(But for small queries, ANSI syntax is not clearly easier to debug.)
select launch.launch_tag, stage.stage_name, stage.engine_count
from launch
join launch_vehicle_stage
	on launch.lv_id = launch_vehicle_stage.lv_id
join stage
	on launch_vehicle_stage.stage_no /*stage_name!*/ = stage.stage_name
order by 1,2,3;



---------------------------------------------------------------------------
-- Too Much Context
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
--Recent planetary exploration and deep space missions.
with launches as
(
	select *
	from launch
	where launch_category = 'deep space'
		and launch_date >= date '2000-01-01'
)
select *
from launches
join satellite
	on launches.launch_id = satellite.launch_id;



---------------------------------------------------------------------------
-- Inline Views
---------------------------------------------------------------------------

--Both of these are subqueries:

--Correlated subquery:
select (select * from dual a where a.dummy = b.dummy) from dual b;

--Inline view:
select * from (select * from dual);


--#1: Join everything at once: 
select ...
from table1,table2,table3,table4,table5,table6,table7,table8,table9,table10
where ...;

--#2: Use inline views:
select *
from
(
	select ...
	from table1,table2,table3,table4,table5
	where ...
),
(
	select ...
	from table6,table7,table8,table9,table10
	where ...
)
where ...;



---------------------------------------------------------------------------
-- Example
---------------------------------------------------------------------------

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
			to_char(launches.launch_date, 'YYYY') launch_year,
			count(*) launch_count,
			engine_fuels.fuel
		from
		(
			--#1: Orbital and deep space launches.
			select *
			from launch
			where launch_category in ('orbital', 'deep space')
		) launches
		left join
		(
			--#2: Launch Vehicle Engines
			select launch_vehicle_stage.lv_id, stage.engine_id
			from launch_vehicle_stage
			left join stage
				on launch_vehicle_stage.stage_name = stage.stage_name
		) lv_engines
			on launches.lv_id = lv_engines.lv_id
		left join
		(
			--#3: Engine Fuels
			select engine.engine_id, propellant_name fuel
			from engine
			left join engine_propellant
				on engine.engine_id = engine_propellant.engine_id
			left join propellant
				on engine_propellant.propellant_id = propellant.propellant_id
			where oxidizer_or_fuel = 'fuel'
		) engine_fuels
			on lv_engines.engine_id = engine_fuels.engine_id
		group by to_char(launch_date, 'YYYY'), fuel
		order by launch_year, launch_count desc, fuel
	)
)
where rownumber <= 3
order by launch_year, launch_count desc;


--(NOT SHOWN IN BOOK)
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
			to_char(launch.launch_date, 'YYYY') launch_year,
			count(*) launch_count,
			propellant.propellant_name fuel
		from launch, launch_vehicle_stage, stage, engine, engine_propellant, propellant
		where launch.lv_id = launch_vehicle_stage.lv_id(+)
			and launch_vehicle_stage.stage_name = stage.stage_name(+)
			and stage.engine_id = engine.engine_id(+)
			and engine.engine_id = engine_propellant.engine_id(+)
			and engine_propellant.propellant_id = propellant.propellant_id(+)
			and launch_category in ('orbital', 'deep space')
			and oxidizer_or_fuel = 'fuel'
		group by to_char(launch_date, 'YYYY'), propellant_name
		order by launch_year, launch_count desc, fuel
	)
)
where rownumber <= 3
order by launch_year, launch_count desc;
