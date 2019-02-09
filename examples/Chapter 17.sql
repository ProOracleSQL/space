---------------------------------------------------------------------------
-- Execution Plans and Declarative Coding
---------------------------------------------------------------------------

--In declarative SQL, these SYSDATEs generate the same value.
select sysdate date1, sysdate date2 from dual;


--In imperative PL/SQL, the two calls to SYSDATE on the same line will
--occassionally return different values.
--This code will usually stop running in a few seconds.
--(NOT SHOWN IN BOOK.)
declare
	v_date1 date;
	v_date2 date;

	function is_equal(p_date1 date, p_date2 date) return boolean is
	begin
		if p_date1 = p_date2 then return true else return false end if;
	end;
begin
	while is_equal(sysdate, sysdate) loop null;
	end loop;
end;
/


--Expression is ignored, no divide-by-zero error is raised.
select * from dual where exists (select 1/0 from dual);


--Generate execution plan.
explain plan for
select * from launch where launch_id = 1;

--Display execution plan.
select *
from table(dbms_xplan.display(format => 'basic +rows +cost'));


---------------------------------------------------------------------------
-- Available Operations (What Execution Plan Decisions Oracle Can Make)
---------------------------------------------------------------------------

--Recently used combinations of operations and options.
select operation, options, count(*)
from gv$sql_plan
group by operation, options
order by operation, options;

--All available Operation names and options.  (Run as SYS.)
select * from sys.x$xplton;
select * from sys.x$xpltoo;



---------------------------------------------------------------------------
-- Parallel
---------------------------------------------------------------------------

--Fully parallel SQL statement.
alter session enable parallel dml;

explain plan for
insert into engine
select /*+ parallel(8) */ * from engine;

select * from table(dbms_xplan.display);


--Partially parallel SQL statement.
alter session enable parallel dml;

explain plan for
insert into engine
select /*+ parallel(engine, 8) */ * from engine;

select * from table(dbms_xplan.display);



---------------------------------------------------------------------------
-- Partition
---------------------------------------------------------------------------

--Partition execution plan example.
explain plan for select * from sys.wri$_optstat_synopsis$;

select * from table(dbms_xplan.display);



---------------------------------------------------------------------------
-- Other
---------------------------------------------------------------------------

--Filter example.
explain plan for
select *
from launch
where launch_id = nvl(:p_launch_id, launch_id);

select * from table(dbms_xplan.display(format => 'basic'));



---------------------------------------------------------------------------
-- Cardinality
---------------------------------------------------------------------------

--Full table scan example.
explain plan for select * from launch where site_id = 1895;

select * from table(dbms_xplan.display(format => 'basic +rows'));


--Index range scan example.
explain plan for select * from launch where site_id = 780;

select * from table(dbms_xplan.display(format => 'basic +rows'));



---------------------------------------------------------------------------
-- Optimizer Statistics
---------------------------------------------------------------------------

--Generate an optimizer trace file.
alter session set events='10053 trace name context forever, level 1';
select * from space.launch where site_id = 1895;
alter session set events '10053 trace name context off';

--Find the latest .trc file in this directory:
select value from v$diag_info where name = 'Diag Trace';


--Column statistics for SPACE.LAUNCH.SITE_ID.
select histogram, sample_size
from dba_tab_columns
where owner = 'SPACE'
	and table_name = 'LAUNCH'
	and column_name = 'SITE_ID';


--Histogram bucket for 1895.
select endpoint_repeat_count
from dba_histograms
where owner = 'SPACE'
	and table_name = 'LAUNCH'
	and column_name = 'SITE_ID'
	and endpoint_value = 1895;



---------------------------------------------------------------------------
-- Transformations
---------------------------------------------------------------------------

--Trivial example of predicate pushing.
select * from (select * from launch) where launch_id = 1;


--Simple view merging example.
select *
from
(
	select *
	from satellite
	join launch using (launch_id)
) launch_satellites
join site
	on launch_satellites.site_id = site.site_id
where site.site_id = 1;


--Simple unnesting example.  (Launches with a satelite.)
select *
from launch
where launch_id in (select launch_id from satellite);



---------------------------------------------------------------------------
-- Transformations and Dynamic Optimizations
---------------------------------------------------------------------------

--Launches in a popular and unpopular year.
select * from launch join satellite using (launch_id)
where to_char(launch.launch_date, 'YYYY') = '1970';

select * from launch join satellite using (launch_id)
where to_char(launch.launch_date, 'YYYY') = '2050';


--Find actual execution plan of either 1970 or 2050 query.
select * from table(dbms_xplan.display_cursor(
	sql_id =>
	(
		select distinct sql_id from v$sql
		where sql_fulltext like '%1970%'
		--where sql_fulltext like '%2050%'
			and sql_fulltext not like '%quine%'
	),
	format => 'adaptive')
);
