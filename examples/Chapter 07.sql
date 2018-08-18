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

