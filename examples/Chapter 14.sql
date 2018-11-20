---------------------------------------------------------------------------
-- When to Use Dynamic SQL
---------------------------------------------------------------------------

--Working PL/SQL block that compresses table with dynamic SQL.
begin
	execute immediate 'alter table launch move nocompress';
end;
/

--Broken PL/SQL block that compresses table using static SQL.
--This block raises a PL/SQL compilation error.
begin
	alter table launch move compress;
end;
/


--Use dynamic SQL to count the number of rows in a table.
create or replace function get_count(p_table_name varchar2)
return number authid current_user is
	v_count number;
begin
	execute immediate
	'select count(*) from '||p_table_name
	into v_count;

	return v_count;
end;
/

select get_count('LAUNCH') row_count from dual;


--(NOT SHOWN IN BOOK):
--Hard-coded references must be directly granted to the user.
--Unless you are running this as SYS, or have already been
--directly granted access to DBA_USERS, it will fail.
create or replace function static_ref_needs_direct_grant
return number authid current_user is
	v_count number;
begin
	select count(*) into v_count from dba_objects;

	return v_count;
end;
/


--Use dynamic SQL to access DBA views.
select get_count('DBA_TABLES') row_count from dual;



---------------------------------------------------------------------------
-- Basic Features
---------------------------------------------------------------------------

--Simple INTO example.
declare
	v_dummy varchar2(1);
begin
	execute immediate 'select dummy from dual'
	into v_dummy;

	dbms_output.put_line('Dummy: '||v_dummy);
end;
/







--Count either LAUNCH or SATELLITE rows for a LAUNCH_ID.
declare
	--(Pretend these are parameters):
	p_launch_or_satellite varchar2(100) := 'LAUNCH';
	p_launch_id number := 4305;

	v_count number;
begin
	execute immediate
	'
		select count(*)
		from '||p_launch_or_satellite||'
		where launch_id = :launch_id
	'
	into v_count
	using p_launch_id;

	dbms_output.put_line('Row count: '||v_count);
end;
/


--Single quotation mark examples.
select
	'A'    no_quote,
	'A''B' quote_in_middle,
	'''A'  quote_at_beginning,
	''''   only_a_quote
from dual;


--Alternative quoting mechanism examples.
select
	q'[A]'   no_quote,
	q'<A'B>' quote_in_middle,
	q'('A)'  quote_at_beginning,
	q'!'!'   only_a_quote
from dual;


--'--Extra single quote, for IDEs that don't understand the alternative
--quoting mechanism and break the syntax highlighting.


--Escape character.
begin
	execute immediate
	'
		select ''A'' a from dual
	';
end;
/

--Custom delimiter.
begin
	execute immediate
	q'[
		select 'A' a from dual
	]';
end;
/
