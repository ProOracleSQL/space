---------------------------------------------------------------------------
-- One Large SQL Statement versus Multiple Small SQL Statements
---------------------------------------------------------------------------

--SQL version of first 3 satellites.
select
	to_char(launch_date, 'YYYY-MM-DD') launch_date,
	official_name
from satellite
join launch
	on satellite.launch_id = launch.launch_id
order by launch_date, official_name
fetch first 3 rows only;


--Imperative version of first 3 satellites.
declare
	v_count number := 0;
begin
	for launches in
	(
		select *
		from launch
		order by launch_date
	) loop
		for satellites in
		(
			select *
			from satellite
			where satellite.launch_id = launches.launch_id
			order by official_name
		) loop
			v_count := v_count + 1;
			if v_count <= 3 then
				dbms_output.put_line(
					to_char(launches.launch_date, 'YYYY-MM-DD') ||
					'   ' || satellites.official_name);
			elsif v_count > 3 then
				return;
			end if;
		end loop;
	end loop;
end;
/



---------------------------------------------------------------------------
-- Performance Risks of Large SQL Statements
---------------------------------------------------------------------------

--An inline view that should be transformed.
select *
from
(
	select *
	from launch
)
where launch_id = 1;


--An inline view that cannot be transformed.
select *
from
(
	select *
	from launch
	--Prevent query transformations.
	where rownum >= 1
)
where launch_id = 1;



---------------------------------------------------------------------------
-- Optimizer opportunities
---------------------------------------------------------------------------

--Psuedo-query using inline views.
select *
from
(
	... a join b ...
) view1
join
(
	... c join d ...
) view2
	on view1.something = view2.something;


--Psuedo-query caused by view merging.
select *
from a
join b ...
join c ...
join d ...



---------------------------------------------------------------------------
-- Improved parallelism
---------------------------------------------------------------------------

--(THE CODE IN THIS SECTION IS NOT SHOWN IN THE BOOK)
--(But it did generate the screenshots shown in the book.)


--Find a large partitioned table for counting rows.
select owner, segment_name, count(*), sum(bytes)/1024/1024/1024 gb
from dba_segments
where segment_type = 'TABLE PARTITION'
group by owner, segment_name
order by gb desc;


--Insert the OWNER and SEGMENT_NAME into the two constants below.
--Count the number of rows, one-partition-at-a-time.
--Ran in 1050.44 seconds.
declare
	v_table_owner constant varchar2(128) := '&TABLE_OWNER';
	v_table_name constant varchar2(128) := '&TABLE_NAME';
	v_count number;
begin
	--Spend 10 seconds burning CPU so that this block is picked up by SQL monitoring.
	--Based on http://download.oracle.com/technology/products/manageability/database/active-reports/faq_plsql.html
	declare
		str varchar2(4000) := 'h';
		startDate date := sysdate;
	begin
		while ((sysdate - startDate)*3600*24 < 10) loop
			if (length(str) > 2000) then
				str := 'h';
			else
				str := str||'h';
			end if;
		end loop;
	end;

	--Loop through the partitions.
	for partitions in
	(
		select table_owner, table_name, partition_name
		from all_tab_partitions
		where table_owner = v_table_owner
			and table_name = v_table_name
			--and rownum <= 10
		order by partition_name
	) loop
		--Run a parallel COUNT(*) on every partition.
		execute immediate
		'
			select /*+ parallel(16) */ count(*)
			from '||partitions.table_owner||'.'||partitions.table_name||
			' partition('||partitions.partition_name||')
		'
		into v_count;
	end loop;
end;
/


--In another session, find the main SQL statement SQL_ID for the PL/SQL block.
select elapsed_time/1000000 seconds, executions, users_executing, child_number, parsing_schema_name, gv$sql.*
from gv$sql
where users_executing > 0
order by elapsed_time desc;

--When the PL/SQL block is done, add the SQL_ID here and generate
--a SQL Monitoring Active Report.
select dbms_sqltune.report_sql_monitor(sql_id => '365w0zghpp7vc', type => 'active')
from dual;


--Count the number of rows, one-table-at-a-time.
--Query on entire table.
--Ran in 832.093 seconds.
declare
	v_table_owner constant varchar2(128) := '&TABLE_OWNER';
	v_table_name constant varchar2(128) := '&TABLE_NAME';
	v_count number;
begin
	--Spend 10 seconds burning CPU so that this block is picked up by SQL monitoring.
	--Based on http://download.oracle.com/technology/products/manageability/database/active-reports/faq_plsql.html
	declare
		str varchar2(4000) := 'h';
		startDate date := sysdate;
	begin
		while ((sysdate - startDate)*3600*24 < 10) loop
			if (length(str) > 2000) then
				str := 'h';
			else
				str := str||'h';
			end if;
		end loop;
	end;

	--Run a parallel COUNT(*) on every partition.
	execute immediate
	'select /*+ parallel(16) */ count(*) from '||v_table_owner||'.'||v_table_name
	into v_count;
end;
/


--In another session, find the main SQL statement SQL_ID for the PL/SQL block.
select elapsed_time/1000000 seconds, executions, users_executing, child_number, parsing_schema_name, gv$sql.*
from gv$sql
where users_executing > 0
order by elapsed_time desc;

--When the PL/SQL block is done, add the SQL_ID here and generate
--a SQL Monitoring Active Report.
select dbms_sqltune.report_sql_monitor(sql_id => 'bmxx872hgmqjh', type => 'active')
from dual;
