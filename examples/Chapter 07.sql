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
--Count of launches per launch vehicle family, per month of 2017.
select
	launches.lv_family_code family,
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
select lv_family_code, lv_name, count(*)
from launch
join launch_vehicle
	on launch.lv_id = launch_vehicle.lv_id
where launch.launch_category in ('orbital', 'deep space')
group by lv_family_code, lv_name
order by 1,2,3;


--Rollup example.
--Count of launches per family and name, per family, and grand total.
select
	lv_family_code,
	lv_name,
	count(*),
	grouping(lv_family_code) is_family_grp,
	grouping(lv_name) is_name_grp
from launch
join launch_vehicle
	on launch.lv_id = launch_vehicle.lv_id
where launch_category in ('orbital', 'deep space')
group by rollup(lv_family_code, lv_name)
order by 1,2,3;


---------------------------------------------------------------------------
-- Analytic Functions
---------------------------------------------------------------------------

--Simple LISTAGG example.
--List of launch vehicles in the Ariane families.
select
	lv_family_code,
	listagg(lv_name, ',') within group (order by lv_name) lv_names
from launch_vehicle
where lower(lv_family_code) like 'ariane%'
group by lv_family_code
order by lv_family_code;


--FIRST and LAST mode of aggregate functions.
--For each launch vehicle family, find the first, min, and max apogee.
select
	lv_family_code,
	min(launch.apogee)
		keep (dense_rank first order by launch_date) first_apogee,
	min(launch.apogee) min_apogee,
	max(launch.apogee) max_apogee
from launch
join launch_vehicle
	on launch.lv_id = launch_vehicle.lv_id
where launch.apogee is not null
group by lv_family_code
order by lv_family_code;


--RANK and DENSE_RANK examples.
--Most popular launch vehicle families.
select
	launch_category category
	,lv_family_code family
	,count
	,rank() over (order by count desc) rank_total
	,rank() over (partition by launch_category
		order by count desc) rank_per_category
from
(
	--Launch counts per category and family.
	select launch_category, lv_family_code, count(*) count
	from launch
	join launch_vehicle
		on launch.lv_id = launch_vehicle.lv_id
	group by launch_category, lv_family_code
	order by count(*) desc
)
order by count desc, launch_category desc;


--LAG, LEAD, running total example.
--Deep space launches, with days between and running total for family.
select
	to_char(launch_date, 'YYYY-MM-DD') launch_date,
	flight_id2 spacecraft,
	lv_family_code family,
	trunc(launch_date) - lag(trunc(launch_date)) over
		(partition by lv_family_code
		order by launch_date) days_between,
	count(*) over
		(partition by lv_family_code order by launch_date) running_total
from launch
join launch_vehicle
	on launch.lv_id = launch_vehicle.lv_id
where launch_category = 'deep space'
order by launch.launch_date;



--Tabibitosan (Japanese counting method)
--Not shown in the book - it would take too long to describe.
--
--Find ranges of consecutive launches per family.
select
	lv_family_code,
	count(*) count_in_range,
	min(the_month) || ' - ' || max(the_month) range
from
(
	--Create groups of launches per family.
	select
		lv_family_code,
		the_month,
		the_month - row_number() over (partition by lv_family_code order by the_month) group_id
	from
	(
		--Distinct launch months per family.
		select distinct
			lv_family_code,
			to_number(to_char(launch_date, 'YYYYMM')) the_month
		from launch
		join launch_vehicle
			on launch.lv_id = launch_vehicle.lv_id
		order by lv_family_code, the_month
	)
)
group by group_id, lv_family_code
having count(*) >= 2
order by lv_family_code;



---------------------------------------------------------------------------
-- Regular Expressions
---------------------------------------------------------------------------

--Launch vehicle names with Roman numerals.
select lv_name
from launch_vehicle
where regexp_like(lv_name, '\W[IVX]+')
	and lv_name like 'Black Brant%'
order by lv_name;


--Replace some Roman numerals.
with function convert_roman_numeral(p_text varchar2) return varchar2 is
begin
	return case upper(p_text)
	when 'I' then '01'
	when 'II' then '02'
	when 'III' then '03'
	end;
end;
select
	lv_name,
	regexp_replace(lv_name, '\W[IVX]+', 
		convert_roman_numeral(regexp_substr(lv_name, '\W([IVX]+)', 1, 1, null, 0))
	) new_name
from launch_vehicle
where regexp_like(lv_name, '\W[IVX]+')
	and lv_name like 'Black Brant%'
order by lv_name;
/


--Convert Roman numerals and re-assemble pieces into a name.
select
	part_1||part_2||
	--This hard-coding is clearly not the best way to do it.
	case part_3
		when 'I' then '01'
		when 'II' then '02'
		when 'III' then '03'
	end||
	part_4 new_lv_name
from
(
	--Launch vehicles with Roman numerals, broken into parts.
	select
		regexp_replace(lv_name, '(.*)(\W)([IVX]+)(.*)', '\1') part_1,
		regexp_replace(lv_name, '(.*)(\W)([IVX]+)(.*)', '\2') part_2,
		regexp_replace(lv_name, '(.*)(\W)([IVX]+)(.*)', '\3') part_3,
		regexp_replace(lv_name, '(.*)(\W)([IVX]+)(.*)', '\4') part_4
	from launch_vehicle
	where regexp_like(lv_name, '\W[IVX]+')
		and lv_name like 'Black Brant%'
	order by lv_name
);


--Split a comma-separated string into its elements.
select regexp_substr(csv, '[^,]', 1, level) element
from
(
	select 'a,b,c' csv
	from dual
)
connect by level <= regexp_count(csv, ',') + 1;



---------------------------------------------------------------------------
-- Row Limiting
---------------------------------------------------------------------------

--Row limiting clause.
--First 3 satellites.
select
	to_char(orbit_date, 'YYYY-MM-DD') orbit_date,
	official_name
from satellite
order by orbit_date, official_name
fetch first 3 rows only;


--Using the old ROWNUM method.
--First 3 satellites.
select orbit_date, official_name, rownum
from
(
	select
		to_char(orbit_date, 'YYYY-MM-DD') orbit_date,
		official_name
	from satellite
	order by orbit_date, official_name
)
where rownum <= 3;


--Using the ROW_NUMBER method.
--First 2 satellites of each year.
select orbit_date, official_name
from
(
	select
		to_char(orbit_date, 'YYYY-MM-DD') orbit_date,
		official_name,
		row_number() over
		(
			partition by trunc(orbit_date, 'year')
			order by orbit_date
		) first_n_per_year
	from satellite
	order by orbit_date, official_name
)
where first_n_per_year <= 2
order by orbit_date, official_name;



---------------------------------------------------------------------------
-- Pivoting and Unpivoting
---------------------------------------------------------------------------

--A typical grouping.
--Launch success and failure per year.
select
	to_char(launch_date, 'YYYY') launch_year,
	launch_status,
	count(*) status_count
from launch
where launch_category in ('orbital', 'deep space')
group by to_char(launch_date, 'YYYY'), launch_status
order by launch_year, launch_status desc;


--Old-fashioned pivoting method.
--Pivoted launch success and failure per year.
select
	to_char(launch_date, 'YYYY') launch_year,
	sum(case when launch_status = 'success' then 1 else 0 end) success,
	sum(case when launch_status = 'failure' then 1 else 0 end) failure
from launch
where launch_category in ('orbital', 'deep space')
group by to_char(launch_date, 'YYYY')
order by launch_year;


--New PIVOT syntax.
--Pivoted launch success and failure per year.
select *
from
(
	--Orbital and deep space launches.
	select to_char(launch_date, 'YYYY') launch_year, launch_status
	from launch
	where launch_category in ('orbital', 'deep space')
) launches
pivot
(
	count(*)
	for launch_status in
	(
		'success' as success,
		'failure' as failure
	)
)
order by launch_year;


--Data that should be unpivoted.
--Multiple FLIGHT_ID columns per launch.
select launch_id, flight_id1, flight_id2
from launch
where launch_category in ('orbital', 'deep space')
order by launch_id;


--Old unpivot method.
--Unpivot data using UNION ALL.
select launch_id, 1 flight_id, flight_id1 flight_name
from launch
where launch_category in ('orbital', 'deep space')
	and flight_id1 is not null
union all
select launch_id, 2 flight_id, flight_id2 flight_name
from launch
where launch_category in ('orbital', 'deep space')
	and flight_id2 is not null
order by launch_id, flight_id;


--UNPIVOT example.
--Unpivot data with UNPIVOT syntax.
select *
from
(
	select launch_id, flight_id1, flight_id2
	from launch
	where launch_category in ('orbital', 'deep space')
) launches
unpivot (flight_name for flight_id in (flight_id1 as 1, flight_id2 as 2))
order by launch_id;



---------------------------------------------------------------------------
-- Table References
---------------------------------------------------------------------------

--Flashback query.
select *
from launch as of timestamp systimestamp - interval '10' minute;


--Sample query that returns a slightly different number each time.
select count(*) from launch sample (1);
--Sample query that returns the same number each time.
select count(*) from launch sample (1) seed (1234);


--Reference partition name.
select *
from sys.wrh$_sqlstat partition (wrh$_sqlstat_mxdb_mxsn);

--Reference partition key values.
select *
from sys.wrh$_sqlstat partition for (1,1);



---------------------------------------------------------------------------
-- National Language Support
---------------------------------------------------------------------------

--Shows some of the N data types.
select
	cast('a' as nvarchar2(100)),
	cast('a' as nchar),
	to_nclob('a'),
	n'a'
from dual;


--Store unicode characters in a text file of any encoding.
select unistr('A\00e9ro-Club de France') org_utf8_name
from dual;


--Byte length semantics error.
create table byte_semantics_test(a varchar2(1));
insert into byte_semantics_test values('é');

--Character length semantics works.
create table character_semantics_test(a varchar2(1 char));
insert into character_semantics_test values('é');


--Use accent-independent linguistic comparision and sorting.
alter session set nls_comp=linguistic;
alter session set nls_sort=binary_ai;

select org_utf8_name
from organization
where org_utf8_name like 'Aero-Club de France%';


--Regular sort.
select org_utf8_name
from organization
order by org_utf8_name;


--Accent independent sort.
select org_utf8_name
from organization
order by nlssort(org_utf8_name, 'nls_sort=binary_ai');


--Dangerous NLS_DATE_FORMAT assumption.
select *
from launch
where trunc(launch_date) = '04-Oct-1957';

--Somewhat safe date format conversion.
select *
from launch
where to_char(launch_date, 'DD-Mon-YYYY') = '04-Oct-1957';



---------------------------------------------------------------------------
-- Common Table Expressions
---------------------------------------------------------------------------

--Delete and update a random row from a not-so-important table.
delete from engine_propellent where rownum <= 1;

update engine_propellent
set oxidizer_or_fuel =
	case when oxidizer_or_fuel = 'fuel' then 'oxidizer' else 'fuel' end
where rownum <= 1;


--Changes made to ENGINE_PROPELLENT in past 5 minutes.
with old as
(
	--Table as of 5 minutes ago.
	select *
	from engine_propellent
	as of timestamp systimestamp - interval '5' minute
),
new as
(
	--Table right now.
	select *
	from engine_propellent
)
--Both row differences put together.
select *
from
(
	--Rows in old table that aren't in new.
	select 'old' old_or_new, old.* from old
	minus
	select 'old' old_or_new, new.* from new
)
union all
(
	--Rows in new table that aren't in old.
	select 'new' old_or_new, new.* from new
	minus
	select 'new' old_or_new, old.* from old
)
order by 2, 3, 4, 1;


--PL/SQL WITH clause.
--Launches with a numeric FLIGHT_ID1.
with function is_number(p_string in varchar2) return varchar2 is
	v_number number;
begin
	v_number := to_number(p_string);
	return 'Y';
exception
	when value_error then return 'N';
end;
select to_char(launch_date, 'YYYY-MM-DD') launch_date, flight_id1
from launch
where flight_id1 is not null
	and is_number(flight_id1) = 'Y'
order by 1,2;
/

--Simplified version that uses TO_NUMBER conversion error, 12.2 or higher.
select to_char(launch_date, 'YYYY-MM-DD') launch_date, flight_id1
from launch
where to_number(flight_id1 default null on conversion error) is not null
order by 1,2;


---------------------------------------------------------------------------
-- Recursive Queries
---------------------------------------------------------------------------

--Organization hierarchy with CONNECT BY.
select
	lpad('  ', 2*(level-1)) || org_code org_code,
	parent_org_code parent,
	org_name
from organization
connect by prior org_code = parent_org_code
start with parent_org_code is null
order siblings by organization.org_code;


--Organization hierarchy from recursive CTE.
with orgs(org_code, org_name, parent_org_code, n, hierarchy) as
(
	--Start with parent rows:
	select org_code, org_name, parent_org_code, 1, org_code
	from organization
	where parent_org_code is null
	union all
	--Add child rows by joining to parent rows:
	select
		organization.org_code,
		organization.org_name,
		organization.parent_org_code,
		n+1,
		hierarchy || '-' || organization.org_code
	from orgs
	join organization
		on orgs.org_code = organization.parent_org_code
)
select
	lpad('  ', 2*(n-1)) || org_code org_code,
	parent_org_code parent,
	org_name
from orgs
order by hierarchy;



---------------------------------------------------------------------------
-- XML
---------------------------------------------------------------------------

--Convert text to XML.
select xmltype('<a></a>') from dual;

--Convert to XMLType and convert back to CLOB.
select table_reference.xml_column.getClobVal()
from
(
	select xmltype('<a></a>') xml_column
	from dual
) table_reference;

--Invalid XML:
SQL> select xmltype('<a></a') from dual;
ERROR:
ORA-31011: XML parsing failed
ORA-19202: Error occurred in XML processing
LPX-00007: unexpected end-of-file encountered
ORA-06512: at "SYS.XMLTYPE", line 310
ORA-06512: at line 1
;


--The simplest way to create an XML file.
--Create XML file for launch data.
select dbms_xmlgen.getxml('
	select launch_id, launch_date, launch_category
	from launch
	where launch_id = 4305
	')
from dual;


--Precisely create an XML file for a launch.
--(Not shown in book.)
select TO_CHAR(LAUNCH_DATE, 'YYYY-MM-DD') LAUNCH_DATE from launch;
select
	xmlelement(
		"Launch",
		xmlattributes(launch_id),
		xmlforest(launch_date, launch_category)
	)
from launch
where launch_id = 4305;


--Create a single XML file for launch data.
create table launch_xml as
select xmltype(dbms_xmlgen.getxml('select * from launch')) xml
from dual;


--Count launches per category using LAUNCH_XML table.
select launch_category, count(*)
from launch_xml
cross join xmltable(
	'/ROWSET/ROW'
	passing launch_xml.xml
	columns
		launch_id  number path 'LAUNCH_ID',
		launch_category varchar2(31) path 'LAUNCH_CATEGORY'
)
group by launch_category
order by count(*) desc;


--There's a whole other query language available with XQuery.
--XQuery FLWOR row generator.
select *
from xmltable
(
	'for $i in xs:integer($i) to xs:integer($j) return $i'
	passing 1 as "i", 3 as "j"
	columns val number path '.'
);



---------------------------------------------------------------------------
-- JSON
---------------------------------------------------------------------------

--Simple JSON example.
select json_object('string' value 'a', 'array' value json_array(1,2))
from dual;


--Create table to hold JSON launch data.
create table launch_json
(
	launch_id number,
	json clob,
	constraint launch_json_pk primary key(launch_id),
	constraint launch_json_ck check (json is json)
);


--Populate LAUNCH_JSON with some of the LAUNCH data.
insert into launch_json
select
	launch_id,
	json_object
	(
		'launch_date' value to_char(launch_date, 'YYYY-MM-DD'),
		'flight_ids' value json_array(flight_id1, flight_id2)
	) json
from launch
where launch_category in ('orbital', 'deep space');
commit;


--View JSON data in LAUNCH_JSON.
select to_char(json) launch_data
from launch_json
order by launch_id;


--Simple JSON query on table LAUNCH_JSON.
select
	launch_id,
	substr(launch_json.json.launch_date, 1, 10) launch_date,
	launch_json.json.flight_ids[0] flight_id1,
	launch_json.json.flight_ids[1] flight_id2,
	launch_json.json.flight_ids[2] flight_id3
from launch_json launch_json
order by launch_date;

