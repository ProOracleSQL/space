---------------------------------------------------------------------------
-- Comments
---------------------------------------------------------------------------

--Hint and comment example.
select /*+ cardinality(launch, 9999999) - I know this is a bad idea but...  */
* from launch;


--Don't use a comment after a line terminator.
SQL> select * from dual; --This doesn't work.
  2


--(This code may not fail in modern versions of SQL*Plus.)
SQL> --Example of bad comment.
SQL> select 1 from dual;

         1
----------
         1

SQL> /*a*/

         1
----------
         1


/***********************************************************
 *
 *  _______        _       +------------------+
 * |__   __|      | |      |doesn't have to be+-------+ 
 *    | | _____  _| |_     +------------------+       |
 *    | |/ _ \ \/ / __|                               |
 *    | |  __/>  <| |_     +------+                   |
 *    |_|\___/_/\_\\__|    |boring+<------------------+
 *                         +------+
 *
***********************************************************/
;



---------------------------------------------------------------------------
-- Choose Good Names
---------------------------------------------------------------------------

--Avoid case sensitive names.
select *
from
(
	select 1 "Good luck using this name!"
	from dual
)
where "Good luck using this name!" = 1;


--(NOT SHOWN IN BOOK.)
--Example of using values in the names.
select launch_id, launch_date
from
(
	select launch_id, launch_date,
		row_number() over
		(
			partition by to_char(launch_date, 'YYYY')
			order by launch_date
		) first_when_1
	from launch
	where launch_category in ('orbital', 'deep space')
)
where first_when_1 = 1;


--Change table and column names.
create table bad_table_name(bad_column_name number);

alter table bad_table_name
rename column bad_column_name to good_column_name;

rename bad_table_name to good_table_name;



---------------------------------------------------------------------------
-- Choose Good Names
---------------------------------------------------------------------------


--Give inline views lots of space.
select * from
(
	--Good comment here.
	select * from dual
) good_name;

--Don't cram everything together.
select * from (select * from dual);


--Typical way to format a procedure.
create or replace procedure proc1 is
begin
	null;
end;
/

--Weird way to format a procedure.
create or replace procedure proc1 is begin null; end;
/



---------------------------------------------------------------------------
-- Make Bugs Obvious
---------------------------------------------------------------------------

--Example of bad exception handling that ignores all errors.
begin
	--Do something here...
	null;
exception
	when others then null;
end;
/

--Example of potentially bad exception handling.
begin
	--Do something here...
	null;
exception
	when others then
		log_error;
end;
/


--Example of honest code:
--This works but I don't know why!
select date '9999-12-31' dangerous_last_date
from dual;


--We're all scared of the error "ORA-01427: single-row subquery returns 
-- more than one row", but sometimes we want to see that error.
-- "=" is better than "in" if there should only be one value.
select * from dual where 'X' in (select dummy from dual);
select * from dual where 'X' = (select dummy from dual);


--Don't hide NO_DATA_FOUND errors.
declare
	v_dummy varchar2(1);
begin
	--This generates "ORA-01403: no data found".
	select dummy into v_dummy from dual where 1=0;

	--We might be tempted to avoid errors with aggregation.
	select max(dummy) into v_dummy from dual where 1=0;

	--But we want an error if this code fails.
	select dummy into v_dummy from dual;
end;
/
