---------------------------------------------------------------------------
-- Avoid Stringly Typed Entity Attribute Value Model
---------------------------------------------------------------------------

--Simple and safe EAV.
create table good_eav
(
	id            number primary key,
	name          varchar2(4000),
	string_value  varchar2(4000),
	number_value  number,
	date_value    date
);

insert into good_eav(id, name, string_value)
values (1, 'Name', 'Eliver');

insert into good_eav(id, name, number_value)
values (2, 'High Score', 11);

insert into good_eav(id, name, date_value)
values (3, 'Date of Birth', date '2011-04-28');


--Never create a table like this:
create table bad_eav
(
	id     number primary key,
	name   varchar2(4000),
	value  varchar2(4000)
);

insert into bad_eav values (2, 'Name'         , 'Eliver');
insert into bad_eav values (1, 'High Score'   , 11);
insert into bad_eav values (3, 'Date of Birth', '2011-04-28');


--Simple query against stringly-typed EAV that will likely fail.
select *
from bad_eav
where name = 'Date of Birth'
	and value = date '2011-04-28';


--Insidiously wrong way to query a bad EAV table.
select *
from bad_eav
where name = 'Date of Birth'
	and to_date(value, 'YYYY-MM-DD') = date '2011-04-28';


--Type- safe way to query a stringly-typed EAV.
select *
from
(
	select *
	from bad_eav
	where name = 'Date of Birth'
		and rownum >= 1
)
where to_date(value, 'YYYY-MM-DD') = date '2011-04-28';



---------------------------------------------------------------------------
-- Avoid Object-Relational
---------------------------------------------------------------------------

--Object relational example.
--Object type to hold a record of satellite data.
create or replace type satellite_type is object
(
	satellite_id number,
	norad_id     varchar2(28)
	---Add more columns here.
);

--Nested table to hold multiple records.
create or replace type satellite_nt is table of satellite_type;

--Use the nested table type in a table.
--(NOT SHOWN IN BOOK.)
create table object_relational_launch
(
	launch_id  number,
	satellites satellite_nt
)
nested table satellites store as satellites_tab;

--Example of inserting data.
--(This is complex enough - how do we handle constraints?)
insert into object_relational_launch
values(1, satellite_nt
	(
		satellite_type(1, '000001'),
		satellite_type(2, '000002')
	)
);

--Example of displaying the data by joining to itself.
select launch_id, satellite_id, norad_id
from object_relational_launch or_launch
cross join table(or_launch.satellites);



---------------------------------------------------------------------------
-- Avoid TO_DATE
---------------------------------------------------------------------------

--(Incorrectly) remove the time from a date.
select to_date(sysdate) the_date from dual;


--Change default date format display.
alter session set nls_date_format = 'DD-MON-RR HH24:MI:SS';


--(Correctly) remove the time from a date.
select trunc(sysdate) the_date from dual;


--DATE literal versus TO_DATE.
select
	date '2000-01-01' date_literal,
	to_date('01-JAN-00', 'DD-MON-RR') date_from_string
from dual;



---------------------------------------------------------------------------
-- Avoid CURSOR
---------------------------------------------------------------------------

--Explicit cursor processing: complex and slow.
declare
	cursor launches is
		select * from launch order by launch_date;

	v_launch launch%rowtype;
begin
	open launches;

	loop
		fetch launches into v_launch;
		exit when launches%notfound;

		dbms_output.put_line(v_launch.launch_date);
	end loop;

	close launches;
end;
/


--Cursor FOR loop processing: simple and fast.
begin
	for launches in
	(
		select * from launch order by launch_date
	) loop
		dbms_output.put_line(launches.launch_date);
	end loop;
end;
/



---------------------------------------------------------------------------
-- Avoid Simplistic Explanations for Generic Errors 
---------------------------------------------------------------------------

--Find the location of the alert log.
--For some reason the log.xml is in the "Diag Alert", and "alert.log" is in "Diag Trace".
--(NOT SHOWN IN BOOK.)
select * from v$diag_info;
