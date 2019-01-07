---------------------------------------------------------------------------
-- MODEL
---------------------------------------------------------------------------

--Cellular automata with MODEL.  On is "#", off is " ".
--#3: Aggregate states to make a picture.
select listagg(state, '') within group (order by cell) line
from
(
	--#2: Apply cellular automata rules with MODEL.
	select generation, cell, state from
	(
		--#1: Initial, mostly empty array.
		select generation, cell,
			--Seed first generation with "#" in the center.
			case
				when generation=0 and cell=120 then '#'
				else ' '
			end state
		from
		(select level-1 generation from dual connect by level <= 120)
		,(select level-1 cell from dual connect by level <= 240)
	)
	model
	dimension by (generation, cell)
	measures (state)
	rules
	(
		--Comment out rules to set them to ' '.
		--Interesting patterns: 18 (00010010) 110 (01101110)
		state[generation >= 1, any] =
			case
				state[cv()-1, cv()-1] ||
				state[cv()-1, cv()  ] ||
				state[cv()-1, cv()+1]
			--when '###' then '#'
			when '## ' then '#'
			when '# #' then '#'
			--when '#  ' then '#'
			when ' ##' then '#'
			when ' # ' then '#'
			when '  #' then '#'
			--when '   ' then '#'
			else ' '
			end
	)
)
group by generation
order by generation;



---------------------------------------------------------------------------
-- Row Pattern Matching
---------------------------------------------------------------------------

--Years where launches decreased two years in a row or more.
select *
from
(
	--Count of launches per year.
	select
		to_char(launch_date, 'YYYY') the_year,
		count(*) launch_count
	from launch
	group by to_char(launch_date, 'YYYY')
	order by the_year
)
match_recognize
(
	order by the_year
	measures
		first(down.the_year) as decline_start,
		last(down.the_year) as decline_end
	one row per match
	after match skip to last down
	--Declined for two or more years.
	pattern (down down+)
	define
		down as down.launch_count < prev(down.launch_count)
)
order by decline_start;



---------------------------------------------------------------------------
-- Any Types
---------------------------------------------------------------------------

--Function that uses ANYDATA to process "anything".
create or replace function process_anything(p_anything anydata)
	return varchar2
is
	v_typecode pls_integer;
	v_anytype anytype;
	v_result pls_integer;
	v_number number;
	v_varchar2 varchar2(4000);
begin
	--Get ANYTYPE.
	v_typecode := p_anything.getType(v_anytype);

	--Inspect type and process accordingly.
	if v_typecode = dbms_types.typecode_number then
		v_result := p_anything.GetNumber(v_number);
		return('Number: '||v_number);
	elsif v_typecode = dbms_types.typecode_varchar2 then
		v_result := p_anything.GetVarchar2(v_varchar2);
		return('Varchar2: '||v_varchar2);
	else
		return('Unexpected type: '||v_typecode);
	end if;
end;
/

--Call PROCESS_ANYTHING from SQL.
select
	process_anything(anydata.ConvertNumber(1)) result1,
	process_anything(anydata.ConvertVarchar2('A')) result2,
	process_anything(anydata.ConvertClob('B')) result3
from dual;



---------------------------------------------------------------------------
-- APEX
---------------------------------------------------------------------------

--Script used to create tiny sample of SPACE data set for APEX example.
--(NOT SHOWN IN BOOK.)

-- Use the same date format to make file smaller:
alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';

drop table launch;

CREATE TABLE "LAUNCH" 
 (	"LAUNCH_ID" NUMBER, 
	"LAUNCH_TAG" VARCHAR2(15), 
	"LAUNCH_DATE" DATE, 
	"LAUNCH_CATEGORY" VARCHAR2(31), 
	"LAUNCH_STATUS" VARCHAR2(31), 
	"LV_ID" NUMBER, 
	"FLIGHT_ID1" VARCHAR2(21), 
	"FLIGHT_ID2" VARCHAR2(25), 
	"MISSION" VARCHAR2(25), 
	"FLIGHT_CODE" VARCHAR2(25), 
	"FLIGHT_TYPE" VARCHAR2(25), 
	"SITE_ID" NUMBER, 
	"PLATFORM_CODE" VARCHAR2(10), 
	"APOGEE" NUMBER, 
	 CONSTRAINT "LAUNCH_PK" PRIMARY KEY ("LAUNCH_ID")
USING INDEX  ENABLE--, 
	 --CONSTRAINT "LAUNCH_LV_FK" FOREIGN KEY ("LV_ID")
	 -- REFERENCES "LAUNCH_VEHICLE" ("LV_ID") ENABLE, 
	 --CONSTRAINT "LAUNCH_SITE_FK" FOREIGN KEY ("SITE_ID")
	 -- REFERENCES "SITE" ("SITE_ID") ENABLE, 
	 --CONSTRAINT "LAUNCH_PLATFORM_FK" FOREIGN KEY ("PLATFORM_CODE")
	 -- REFERENCES "PLATFORM" ("PLATFORM_CODE") ENABLE
 ) ;
 
 insert into LAUNCH
select 1,'1942-A01','1942-06-13 10:52:00','military missile','failure',8,'2','','','','Test',675,'',1 from dual union all
select 10,'1943-A03','1943-02-17 00:00:00','military missile','success',8,'12','','','','Test',675,'',30 from dual union all
select 100,'1944-M02','1944-09-13 16:47:00','military missile','success',8,'18181','M140','','','Test',676,'',64 from dual union all
select 1000,'1951-A11','1951-04-12 00:00:00','atmospheric rocket','success',869,'490-65','Nike 490A 60R','','','Test',1895,'',10 from dual union all
select 10000,'1963-S479','1963-10-05 00:00:00','military missile','success',1053,'CC-2005','ATBM-11 target','','','OT',437,'',90 from dual;



---------------------------------------------------------------------------
-- Oracle Text
---------------------------------------------------------------------------

--GPS launches.  Uses a full table scan.
select count(*) total
from launch
where lower(mission) like '%gps%';


--Create CONTEXT index on MISSION.
--(Text indexes need CREATE TABLE privileges on schema owner.)
grant create table to space;
create index launch_mission_text
	on launch(mission) indextype is ctxsys.context;


--GPS launches.  CONTAINS operator uses DOMAIN INDEX
explain plan for
select count(*) total
from launch
where contains(mission, 'gps', 1) > 0;

select * from table(dbms_xplan.display(format => 'basic'));


--Synchronize index after DML on the LAUNCH table.
begin
	ctx_ddl.sync_index(idx_name => 'space.launch_mission_text');
end;
/
