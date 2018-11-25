---------------------------------------------------------------------------
-- Execution Plans and Declarative Coding
---------------------------------------------------------------------------

--In declarative SQL, these SYSDATEs will always generate the same value.
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


--Generate execution plan.
explain plan for
select * from launch where launch_id = 1;

--Display execution plan.
select *
from table(dbms_xplan.display(format => 'basic +rows +cost'));





alter session set current_schema=space;

--Generate execution plan.
explain plan for
select /*+ full(launch) */ * from launch where launch_id = 1;

--Display execution plan.
select *
from table(dbms_xplan.display(format => 'basic +rows +cost'));



