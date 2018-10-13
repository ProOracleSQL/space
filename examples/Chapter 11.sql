---------------------------------------------------------------------------
-- Comments
---------------------------------------------------------------------------

--Hint and comment example.
select /*+ cardinality(launch, 9999999) - I know this is a bad idea but...  */
* from launch;


--Don't use a comment after a line terminator.
SQL> select * from dual; --This doesn't work.
  2


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


--Example of using values in the names.
--(NOT SHOWN IN BOOK.)
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





